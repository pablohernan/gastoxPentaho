------------------------------------------------------------------------------------------------------------------------------------------------------
-- 10.0.1 --------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------

IF EXISTS(SELECT '' FROM SYSOBJECTS WHERE XTYPE = 'P' AND NAME = 'SPDM_DB_FILTRO_SEGMENTACAO')
	DROP PROCEDURE SPDM_DB_FILTRO_SEGMENTACAO
GO
CREATE PROCEDURE SPDM_DB_FILTRO_SEGMENTACAO
(
	@pCOD_CONTEXTO VARCHAR(20),
	@pCOD_EMPREENDIMENTO VARCHAR(200),
	@pNME_LOGIN VARCHAR(50)
)
AS
/*
EXEC SPDM_DB_FILTRO_SEGMENTACAO 9, 3, 'WAGNER.JUNIOR'
*/
BEGIN
	DECLARE @vQUERY VARCHAR(8000)

	SELECT @vQUERY = 'SELECT
		S.COD_SEGMENTACAO AS COD, S.NME_SEGMENTACAO AS SEGMENTACAO
	FROM
		SEGMENTACAO S 
	WHERE
		S.COD_CONTEXTO = ' + @pCOD_CONTEXTO + ' AND S.FLG_AUTOMATICA = 0 AND S.COD_USUARIOCADASTRO <> - 77
		AND (S.COD_EMPREENDIMENTO IS NULL OR S.COD_EMPREENDIMENTO IN (' + @pCOD_EMPREENDIMENTO + ')) 
	ORDER BY 2';

	EXEC(@vQUERY)
END
GO

EXEC SPDM_CONTROLEVERSAO 'BD_VERSAO_DASHBOARD_COMMONS', '10.0.1';
GO
------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------
-- 10.0.2 --------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------------------
-- INICIO - 138177, Fabricio Machado (Principal: 138076) - Dashboard - E-mail recorrente
-- INICIO - WISEIT-37 - Banco - Dashboards - E-mails recorrentes
--------------------------------------------------------------------------------------------------------------
-- Tabela para definir quais ações de marketing são usadas como medição de conversão da campanha.
IF NOT EXISTS (SELECT * FROM SYSOBJECTS WHERE TYPE = 'U' AND NAME = 'CAMPANHAMKT_ACAOMKT')
BEGIN
CREATE TABLE CAMPANHAMKT_ACAOMKT
(
	COD_CAMPANHAMARKETING INT NOT NULL,
	COD_ACAOMARKETING INT NOT NULL
)
ALTER TABLE CAMPANHAMKT_ACAOMKT ADD CONSTRAINT PK_CAMPANHAMKT_ACAOMKT PRIMARY KEY(COD_CAMPANHAMARKETING,COD_ACAOMARKETING)
ALTER TABLE CAMPANHAMKT_ACAOMKT ADD CONSTRAINT FK_CAMKT_CAMPANHA FOREIGN KEY(COD_CAMPANHAMARKETING) REFERENCES CAMPANHAMARKETING
ALTER TABLE CAMPANHAMKT_ACAOMKT ADD CONSTRAINT FK_CAMKT_ACAOMKT FOREIGN KEY(COD_ACAOMARKETING) REFERENCES ACAOMARKETING
END
GO

IF EXISTS(SELECT '' FROM SYSOBJECTS WHERE XTYPE = 'FN' AND NAME = 'FUNC_RETORNAMES')
BEGIN
  DROP FUNCTION DBO.FUNC_RETORNAMES
END
GO
CREATE FUNCTION FUNC_RETORNAMES (@pNUM_MES INT)
RETURNS VARCHAR(10)
AS
BEGIN
	DECLARE @vMES VARCHAR(10) 
	SELECT @vMES = 
		CASE
			WHEN @pNUM_MES = 1 THEN 'Janeiro'
			WHEN @pNUM_MES = 2 THEN 'Fevereiro'
			WHEN @pNUM_MES = 3 THEN 'Março'
			WHEN @pNUM_MES = 4 THEN 'Abril'
			WHEN @pNUM_MES = 5 THEN 'Maio'
			WHEN @pNUM_MES = 6 THEN 'Junho'
			WHEN @pNUM_MES = 7 THEN 'Julho'
			WHEN @pNUM_MES = 8 THEN 'Agosto'
			WHEN @pNUM_MES = 9 THEN 'Setembro'
			WHEN @pNUM_MES = 10 THEN 'Outubro'
			WHEN @pNUM_MES = 11 THEN 'Novembro'
			WHEN @pNUM_MES = 12 THEN 'Dezembro'
		END
	RETURN @vMES
END
GO

IF EXISTS(SELECT '' FROM SYSOBJECTS WHERE XTYPE = 'FN' AND NAME = 'FUNC_RETORNADIASEMANA2')
BEGIN
  DROP FUNCTION DBO.FUNC_RETORNADIASEMANA2
END
GO
CREATE FUNCTION FUNC_RETORNADIASEMANA2(@pNUM_DIASEMANA INT, @pTIPO INT)
RETURNS VARCHAR(10)
AS
BEGIN
	DECLARE @vDIASEMANA VARCHAR(10) 
	SELECT @vDIASEMANA = 
		CASE
			WHEN @pNUM_DIASEMANA = 1 AND @pTIPO = 1 THEN 'DOM'
			WHEN @pNUM_DIASEMANA = 1 AND @pTIPO = 2 THEN 'Domingo'
			WHEN @pNUM_DIASEMANA = 2 AND @pTIPO = 1 THEN 'SEG'
			WHEN @pNUM_DIASEMANA = 2 AND @pTIPO = 2 THEN 'Segunda'
			WHEN @pNUM_DIASEMANA = 3 AND @pTIPO = 1 THEN 'TER'
			WHEN @pNUM_DIASEMANA = 3 AND @pTIPO = 2 THEN 'Terça'
			WHEN @pNUM_DIASEMANA = 4 AND @pTIPO = 1 THEN 'QUA'
			WHEN @pNUM_DIASEMANA = 4 AND @pTIPO = 2 THEN 'Quarta'
			WHEN @pNUM_DIASEMANA = 5 AND @pTIPO = 1 THEN 'QUI'
			WHEN @pNUM_DIASEMANA = 5 AND @pTIPO = 2 THEN 'Quinta'
			WHEN @pNUM_DIASEMANA = 6 AND @pTIPO = 1 THEN 'SEX'
			WHEN @pNUM_DIASEMANA = 6 AND @pTIPO = 2 THEN 'Sexta'
			WHEN @pNUM_DIASEMANA = 7 AND @pTIPO = 1 THEN 'SAB'
			WHEN @pNUM_DIASEMANA = 7 AND @pTIPO = 2 THEN 'Sábado'
		END
	RETURN @vDIASEMANA
END
GO

IF EXISTS(SELECT '' FROM SYSOBJECTS WHERE XTYPE = 'V' AND NAME = 'VW_HORAS')
BEGIN
  DROP VIEW VW_HORAS
END
GO
CREATE VIEW VW_HORAS
AS
	SELECT 0 AS "HORA" UNION ALL
	SELECT 1 AS "HORA" UNION ALL
	SELECT 2 AS "HORA" UNION ALL
	SELECT 3 AS "HORA" UNION ALL
	SELECT 4 AS "HORA" UNION ALL
	SELECT 5 AS "HORA" UNION ALL
	SELECT 6 AS "HORA" UNION ALL
	SELECT 7 AS "HORA" UNION ALL
	SELECT 8 AS "HORA" UNION ALL
	SELECT 9 AS "HORA" UNION ALL
	SELECT 10 AS "HORA" UNION ALL
	SELECT 11 AS "HORA" UNION ALL
	SELECT 12 AS "HORA" UNION ALL
	SELECT 13 AS "HORA" UNION ALL
	SELECT 14 AS "HORA" UNION ALL
	SELECT 15 AS "HORA" UNION ALL
	SELECT 16 AS "HORA" UNION ALL
	SELECT 17 AS "HORA" UNION ALL
	SELECT 18 AS "HORA" UNION ALL
	SELECT 19 AS "HORA" UNION ALL
	SELECT 20 AS "HORA" UNION ALL
	SELECT 21 AS "HORA" UNION ALL
	SELECT 22 AS "HORA" UNION ALL
	SELECT 23 AS "HORA"
GO
--------------------------------------------------------------------------------------------------------------
-- FIM - 138177, Fabricio Machado (Principal: 138076) - Dashboard - E-mail recorrente
-- FIM - WISEIT-37 - Banco - Dashboards - E-mails recorrentes
--------------------------------------------------------------------------------------------------------------

EXEC SPDM_CONTROLEVERSAO 'BD_VERSAO_DASHBOARD_COMMONS', '10.0.2';
GO
------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------
-- 10.0.3 --------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------------------------------------------------------
-- INICIO - Fabricio - WISEIT-4320 Dashboard SAC - exibir média por dia da semanaWISEIT-4355 Dashboard SAC - exibir média por dia da semana
-----------------------------------------------------------------------------------------------------------------------------------------------
CREATE FUNCTION func_qtd_dia_semana_periodo (@pDIA_SEMANA INTEGER, @pDTA_INICIO DATETIME, @pDTA_FIM DATETIME) RETURNS INT
AS  
BEGIN
DECLARE
	@vDTA_INICIO DATETIME, @vDIA_SEMANA INT, @vCOUNT INT

	SELECT @vDTA_INICIO = @pDTA_INICIO;
	SELECT @vCOUNT = 0;
	WHILE @vDTA_INICIO <= @pDTA_FIM
	BEGIN
		IF DATEPART(DW,@vDTA_INICIO) = @pDIA_SEMANA
			SELECT @vCOUNT = @vCOUNT + 1;
	    SELECT @vDTA_INICIO = @vDTA_INICIO + 1;
	END
  RETURN @vCOUNT;
END
GO
-----------------------------------------------------------------------------------------------------------------------------------------------
-- FIM - Fabricio - WISEIT-4320 Dashboard SAC - exibir média por dia da semanaWISEIT-4355 Dashboard SAC - exibir média por dia da semana
-----------------------------------------------------------------------------------------------------------------------------------------------

EXEC SPDM_CONTROLEVERSAO 'BD_VERSAO_DASHBOARD_COMMONS', '10.0.3';
GO


------------------------------------------------------------------------------------------------------------------------------------------------------
-- 10.0.4 --------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------
-- INICIO - Fabricio - WISEIT-1468/WISEIT-5048 Erro ao utilizar segmentação no contexto de clientes e atributo consumo no dashboard de RFV
------------------------------------------------------------------------------------------------------------------------------------------------------
IF NOT EXISTS (SELECT '' FROM APAGA_TAB_TEMPORARIA WHERE NME_TABELA = 'TMP_DB_SE')
	INSERT INTO APAGA_TAB_TEMPORARIA VALUES('TMP_DB_SE')
GO

IF EXISTS(SELECT '' FROM SYSOBJECTS WHERE XTYPE = 'P' AND NAME = 'SPDM_DB_FILTROSEGMENTACAO')
	DROP PROCEDURE SPDM_DB_FILTROSEGMENTACAO
GO

CREATE PROCEDURE SPDM_DB_FILTROSEGMENTACAO
(
	@pID VARCHAR(100),
	@pCOD_SEGMENTACAO INT,
	@pNME_CONTEXTO VARCHAR(100)
)
AS
/*
SELECT * FROM SEGMENTACAO WHERE FLG_AUTOMATICA = 0 ORDER BY 1 DESC

EXEC SPDM_DB_FILTROSEGMENTACAO '1234',21,'CLIENTE'

SELECT * FROM TMP_DB_SEG1234
*/
BEGIN
	DECLARE 
		@vQUERY VARCHAR(8000), @vCOD_SEGMENTACAO INT, @vSQL_SEGMENTACAO VARCHAR(8000), @vSQL_SEGMENTACAO2 VARCHAR(8000)

	-- Apaga a tabela caso exista.
	SELECT @vQUERY = 'IF EXISTS (SELECT * FROM SYSOBJECTS WHERE TYPE = ''U'' AND NAME = ''TMP_DB_SEG'+@pID+''') DROP TABLE TMP_DB_SEG'+@pID
	EXEC(@vQUERY);

	-- Cria a tabela com os codigos dos clientes.
	SELECT @vQUERY = 'CREATE TABLE TMP_DB_SEG'+@pID+'(CODIGO INT PRIMARY KEY)'
	EXEC(@vQUERY);

	-- Pega a query da segmentação. Caso tenha resultado gravado , pega os clientes.
	SELECT DISTINCT
		@vCOD_SEGMENTACAO = SR.COD_SEGMENTACAO,
		@vSQL_SEGMENTACAO = CONVERT(VARCHAR(8000),S.SQL_SEGMENTACAO), 
		@vSQL_SEGMENTACAO2 = CONVERT(VARCHAR(8000),S.SQL_SEGMENTACAODADOS)
	FROM
		SEGMENTACAO S
		LEFT OUTER JOIN SEGMENTACAORESULTADO SR ON (SR.COD_SEGMENTACAO = S.COD_SEGMENTACAO)
	WHERE
		S.COD_SEGMENTACAO = @pCOD_SEGMENTACAO;

	SELECT @vQUERY = 'INSERT INTO TMP_DB_SEG'+@pID;

	IF @vCOD_SEGMENTACAO > 0
		SELECT @vQUERY = @vQUERY+' SELECT COD_RESULTADO FROM SEGMENTACAORESULTADO WHERE COD_SEGMENTACAO ='+CONVERT(VARCHAR,@vCOD_SEGMENTACAO);
	ELSE
	BEGIN
		IF ISNULL(@vSQL_SEGMENTACAO2,' ') <> ' '
			SELECT @vQUERY = @vQUERY +' '+ @vSQL_SEGMENTACAO2;
		ELSE
		BEGIN			
			IF @pNME_CONTEXTO = 'CLIENTE'
				SELECT @vQUERY = @vQUERY +' '+ replace(@vSQL_SEGMENTACAO,'COUNT( DISTINCT PESSOAFISICA.COD_PESSOA ) 	 AS "QTD_ROWS"',' DISTINCT PESSOAFISICA.COD_PESSOA');
		END
	END

	PRINT @vQUERY
	EXEC(@vQUERY)
END
GO
------------------------------------------------------------------------------------------------------------------------------------------------------
-- FIM - Fabricio - WISEIT-1468/WISEIT-5048 Erro ao utilizar segmentação no contexto de clientes e atributo consumo no dashboard de RFV
------------------------------------------------------------------------------------------------------------------------------------------------------

EXEC SPDM_CONTROLEVERSAO 'BD_VERSAO_DASHBOARD_COMMONS', '10.0.4';
GO


------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------

