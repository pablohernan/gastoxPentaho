------------------------------------------------------------------------------------------------------------------------------------------------------
-- 10.0.1 --------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE SPDM_DB_FILTRO_SEGMENTACAO
(
	pCOD_CONTEXTO VARCHAR,
	pCOD_EMPREENDIMENTO VARCHAR,
	pNME_LOGIN VARCHAR,
	RESULTSET OUT SYS_REFCURSOR
)
AS
/*
-- COMBO DE SEGMENTACAO CLIENTES
variable vCUR refcursor
EXEC SPDM_DB_FILTRO_SEGMENTACAO ('1', '1', 'WAGNER.JUNIOR', :vCUR);
print vCUR
*/
BEGIN
	DECLARE vQUERY VARCHAR2(4000);
	BEGIN
		vQUERY :=
			'SELECT TO_NUMBER(S.COD_SEGMENTACAO) AS COD, LOWER(S.NME_SEGMENTACAO) AS SEGMENTACAO'||
			' FROM SEGMENTACAO S'||
			' WHERE S.COD_CONTEXTO = '||pCOD_CONTEXTO||' AND S.FLG_AUTOMATICA = 0 AND S.COD_USUARIOCADASTRO <> - 77 '||
			' AND (S.COD_EMPREENDIMENTO IS NULL OR S.COD_EMPREENDIMENTO IN ('||pCOD_EMPREENDIMENTO||'))'||
			' ORDER BY 2';
		OPEN RESULTSET FOR vQUERY;
		--Dbms_Output.Put_Line(vQUERY);
	END;
END;
/

EXEC SPDM_CONTROLEVERSAO ('BD_VERSAO_DASHBOARD_COMMONS', '10.0.1');
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
DECLARE QTD_REGISTROS INTEGER;
BEGIN
SELECT Count(*) INTO QTD_REGISTROS FROM USER_TABLES WHERE TABLE_NAME = 'CAMPANHAMKT_ACAOMKT';
IF QTD_REGISTROS = 0 THEN
  EXECUTE IMMEDIATE 'CREATE TABLE CAMPANHAMKT_ACAOMKT(COD_CAMPANHAMARKETING INT NOT NULL,COD_ACAOMARKETING INT NOT NULL)';
  EXECUTE IMMEDIATE 'ALTER TABLE CAMPANHAMKT_ACAOMKT ADD CONSTRAINT PK_CAMPANHAMKT_ACAOMKT PRIMARY KEY(COD_CAMPANHAMARKETING,COD_ACAOMARKETING)';
  EXECUTE IMMEDIATE 'ALTER TABLE CAMPANHAMKT_ACAOMKT ADD CONSTRAINT FK_CAMKT_CAMPANHA FOREIGN KEY(COD_CAMPANHAMARKETING) REFERENCES CAMPANHAMARKETING';
  EXECUTE IMMEDIATE 'ALTER TABLE CAMPANHAMKT_ACAOMKT ADD CONSTRAINT FK_CAMKT_ACAOMKT FOREIGN KEY(COD_ACAOMARKETING) REFERENCES ACAOMARKETING';
END IF;
END;
/

CREATE OR REPLACE FUNCTION func_retornames (pNUM_MES IN INTEGER) RETURN VARCHAR2
IS
  vMES VARCHAR2(10);
BEGIN
	SELECT
		CASE
			WHEN pNUM_MES = 1 THEN 'Janeiro'
			WHEN pNUM_MES = 2 THEN 'Fevereiro'
			WHEN pNUM_MES = 3 THEN 'Março'
			WHEN pNUM_MES = 4 THEN 'Abril'
			WHEN pNUM_MES = 5 THEN 'Maio'
			WHEN pNUM_MES = 6 THEN 'Junho'
			WHEN pNUM_MES = 7 THEN 'Julho'
			WHEN pNUM_MES = 8 THEN 'Agosto'
			WHEN pNUM_MES = 9 THEN 'Setembro'
			WHEN pNUM_MES = 10 THEN 'Outubro'
			WHEN pNUM_MES = 11 THEN 'Novembro'
			WHEN pNUM_MES = 12 THEN 'Dezembro'
		END
  INTO
    vMES
  FROM
    DUAL;
	RETURN vMES;
END;
/

CREATE OR REPLACE FUNCTION func_retornadiasemana2 (pNUM_DIASEMANA IN INTEGER, pTIPO IN INTEGER) RETURN VARCHAR2
IS
  vDIASEMANA VARCHAR2(10);
BEGIN
	SELECT
		CASE
			WHEN pNUM_DIASEMANA = 1 AND pTIPO = 1 THEN 'DOM'
			WHEN pNUM_DIASEMANA = 1 AND pTIPO = 2 THEN 'Domingo'
			WHEN pNUM_DIASEMANA = 2 AND pTIPO = 1 THEN 'SEG'
			WHEN pNUM_DIASEMANA = 2 AND pTIPO = 2 THEN 'Segunda'
			WHEN pNUM_DIASEMANA = 3 AND pTIPO = 1 THEN 'TER'
			WHEN pNUM_DIASEMANA = 3 AND pTIPO = 2 THEN 'Terça'
			WHEN pNUM_DIASEMANA = 4 AND pTIPO = 1 THEN 'QUA'
			WHEN pNUM_DIASEMANA = 4 AND pTIPO = 2 THEN 'Quarta'
			WHEN pNUM_DIASEMANA = 5 AND pTIPO = 1 THEN 'QUI'
			WHEN pNUM_DIASEMANA = 5 AND pTIPO = 2 THEN 'Quinta'
			WHEN pNUM_DIASEMANA = 6 AND pTIPO = 1 THEN 'SEX'
			WHEN pNUM_DIASEMANA = 6 AND pTIPO = 2 THEN 'Sexta'
			WHEN pNUM_DIASEMANA = 7 AND pTIPO = 1 THEN 'SAB'
			WHEN pNUM_DIASEMANA = 7 AND pTIPO = 2 THEN 'Sábado'
		END
  INTO
    vDIASEMANA
  FROM
    DUAL;
	RETURN vDIASEMANA;
END;
/

CREATE OR REPLACE VIEW VW_HORAS
AS
	SELECT 0 AS "HORA" FROM DUAL UNION ALL
	SELECT 1 AS "HORA" FROM DUAL UNION ALL
	SELECT 2 AS "HORA" FROM DUAL UNION ALL
	SELECT 3 AS "HORA" FROM DUAL UNION ALL
	SELECT 4 AS "HORA" FROM DUAL UNION ALL
	SELECT 5 AS "HORA" FROM DUAL UNION ALL
	SELECT 6 AS "HORA" FROM DUAL UNION ALL
	SELECT 7 AS "HORA" FROM DUAL UNION ALL
	SELECT 8 AS "HORA" FROM DUAL UNION ALL
	SELECT 9 AS "HORA" FROM DUAL UNION ALL
	SELECT 10 AS "HORA" FROM DUAL UNION ALL
	SELECT 11 AS "HORA" FROM DUAL UNION ALL
	SELECT 12 AS "HORA" FROM DUAL UNION ALL
	SELECT 13 AS "HORA" FROM DUAL UNION ALL
	SELECT 14 AS "HORA" FROM DUAL UNION ALL
	SELECT 15 AS "HORA" FROM DUAL UNION ALL
	SELECT 16 AS "HORA" FROM DUAL UNION ALL
	SELECT 17 AS "HORA" FROM DUAL UNION ALL
	SELECT 18 AS "HORA" FROM DUAL UNION ALL
	SELECT 19 AS "HORA" FROM DUAL UNION ALL
	SELECT 20 AS "HORA" FROM DUAL UNION ALL
	SELECT 21 AS "HORA" FROM DUAL UNION ALL
	SELECT 22 AS "HORA" FROM DUAL UNION ALL
	SELECT 23 AS "HORA" FROM DUAL;

--------------------------------------------------------------------------------------------------------------
-- FIM - 138177, Fabricio Machado (Principal: 138076) - Dashboard - E-mail recorrente
-- FIM - WISEIT-37 - Banco - Dashboards - E-mails recorrentes
--------------------------------------------------------------------------------------------------------------

EXEC SPDM_CONTROLEVERSAO ('BD_VERSAO_DASHBOARD_COMMONS', '10.0.2');

------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------
-- 10.0.3 --------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------------------------------------------------------
-- INICIO - Fabricio - WISEIT-4320 Dashboard SAC - exibir média por dia da semanaWISEIT-4355 Dashboard SAC - exibir média por dia da semana
-----------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION func_qtd_dia_semana_periodo (pDIA_SEMANA IN INTEGER, pDTA_INICIO DATE, pDTA_FIM DATE) RETURN INT
IS
  vDTA_INICIO DATE; vDIA_SEMANA INT; vCOUNT INT;
BEGIN
  vDTA_INICIO := pDTA_INICIO;
  vCOUNT := 0;
  WHILE vDTA_INICIO <= pDTA_FIM
  LOOP
    IF To_Char(vDTA_INICIO,'D') = pDIA_SEMANA  THEN
      vCOUNT := vCOUNT + 1;
    END IF;
    vDTA_INICIO := vDTA_INICIO + 1;
  END LOOP;
  RETURN vCOUNT;
END;
/
-----------------------------------------------------------------------------------------------------------------------------------------------
-- FIM - Fabricio - WISEIT-4320 Dashboard SAC - exibir média por dia da semanaWISEIT-4355 Dashboard SAC - exibir média por dia da semana
-----------------------------------------------------------------------------------------------------------------------------------------------

EXEC SPDM_CONTROLEVERSAO ('BD_VERSAO_DASHBOARD_COMMONS', '10.0.3');


------------------------------------------------------------------------------------------------------------------------------------------------------
-- 10.0.4 --------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------
-- INICIO - Fabricio - WISEIT-1468/WISEIT-5048 Erro ao utilizar segmentação no contexto de clientes e atributo consumo no dashboard de RFV
------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE vCOUNT INT;
BEGIN
  SELECT Count(*) INTO vCOUNT FROM APAGA_TAB_TEMPORARIA WHERE NME_TABELA = 'TMP_DB_SE';
  IF vCOUNT = 0 THEN
	  INSERT INTO APAGA_TAB_TEMPORARIA VALUES('TMP_DB_SE');
  END IF;
END;
/

CREATE OR REPLACE PROCEDURE SPDM_DB_FILTROSEGMENTACAO
(
	pID VARCHAR,
	pCOD_SEGMENTACAO INT,
	pNME_CONTEXTO VARCHAR
)
AS
/*
SELECT * FROM SEGMENTACAO WHERE FLG_AUTOMATICA = 0 ORDER BY 1 DESC

EXEC SPDM_DB_FILTROSEGMENTACAO ('1',26727,'CLIENTE')
EXEC SPDM_DB_FILTROSEGMENTACAO ('1',26754,'CLIENTE')

SELECT * FROM TMP_DB_SEG1234
*/
BEGIN
	DECLARE
		vQUERY VARCHAR2(8000); vCOD_SEGMENTACAO INT; vSQL_SEGMENTACAO VARCHAR2(8000); vSQL_SEGMENTACAO2 VARCHAR2(8000); vCOUNT INT;
BEGIN
  -- Apaga a tabela caso exista.
  EXECUTE IMMEDIATE('SELECT COUNT(*) FROM USER_TABLES WHERE TABLE_NAME = ''TMP_DB_SEG'||pID||'''') INTO vCOUNT;
  IF vCOUNT > 0 THEN
    EXECUTE IMMEDIATE('DROP TABLE TMP_DB_SEG'||pID);
  END IF;

	-- Cria a tabela com os codigos dos clientes.
	EXECUTE IMMEDIATE('CREATE TABLE TMP_DB_SEG'||pID||'(CODIGO INT PRIMARY KEY)');

	-- Pega a query da segmentação. Caso tenha resultado gravado , pega os clientes.
	SELECT DISTINCT
		SR.COD_SEGMENTACAO,
		To_Char(S.SQL_SEGMENTACAO),
		To_Char(S.SQL_SEGMENTACAODADOS)
  INTO
    vCOD_SEGMENTACAO, vSQL_SEGMENTACAO, vSQL_SEGMENTACAO2
	FROM
		SEGMENTACAO S
		LEFT OUTER JOIN SEGMENTACAORESULTADO SR ON (SR.COD_SEGMENTACAO = S.COD_SEGMENTACAO)
	WHERE
		S.COD_SEGMENTACAO = pCOD_SEGMENTACAO;

	vQUERY := 'INSERT INTO TMP_DB_SEG'||pID;

	IF vCOD_SEGMENTACAO > 0 THEN
		vQUERY := vQUERY||' SELECT COD_RESULTADO FROM SEGMENTACAORESULTADO WHERE COD_SEGMENTACAO ='||To_Char(vCOD_SEGMENTACAO);
	ELSE
		IF nvl(vSQL_SEGMENTACAO2,' ') <> ' ' THEN
			vQUERY := vQUERY ||' '|| vSQL_SEGMENTACAO2;
		ELSE
			IF pNME_CONTEXTO = 'CLIENTE' THEN
				vQUERY := vQUERY ||' '|| replace(vSQL_SEGMENTACAO,'COUNT( DISTINCT PESSOAFISICA.COD_PESSOA ) 	 AS "QTD_ROWS"',' DISTINCT PESSOAFISICA.COD_PESSOA');
      END IF;
		END IF;
  END IF;

  --Dbms_Output.Put_Line(vQUERY);
  EXECUTE IMMEDIATE(vQUERY);
END;
END;
/
------------------------------------------------------------------------------------------------------------------------------------------------------
-- FIM - Fabricio - WISEIT-1468/WISEIT-5048 Erro ao utilizar segmentação no contexto de clientes e atributo consumo no dashboard de RFV
------------------------------------------------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------------------------------------------------
-- INICIO - WISEIT-4840 / WISEIT-4934 Dashboards - visão por dia da semana e horário deve considerar a média como opção padrão, ordenar de segunda a domingo, e exibir as 24h do dia com possibilidade de rolagem lateral
------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE VIEW VW_HORAS
AS

SELECT 0 AS "HORA",'00:00' AS "HORA_TIME" FROM DUAL UNION ALL
SELECT 1,'01:00' FROM DUAL UNION ALL
SELECT 2,'02:00' FROM DUAL UNION ALL
SELECT 3,'03:00' FROM DUAL UNION ALL
SELECT 4,'04:00'FROM DUAL UNION ALL
SELECT 5,'05:00'FROM DUAL UNION ALL
SELECT 6,'06:00'FROM DUAL UNION ALL
SELECT 7,'07:00'FROM DUAL UNION ALL
SELECT 8,'08:00'FROM DUAL UNION ALL
SELECT 9,'09:00'FROM DUAL UNION ALL
SELECT 10,'10:00'FROM DUAL UNION ALL
SELECT 11,'11:00'FROM DUAL UNION ALL
SELECT 12,'12:00'FROM DUAL UNION ALL
SELECT 13,'13:00'FROM DUAL UNION ALL
SELECT 14,'14:00'FROM DUAL UNION ALL
SELECT 15,'15:00'FROM DUAL UNION ALL
SELECT 16,'16:00'FROM DUAL UNION ALL
SELECT 17,'17:00'FROM DUAL UNION ALL
SELECT 18,'18:00'FROM DUAL UNION ALL
SELECT 19,'19:00'FROM DUAL UNION ALL
SELECT 20,'20:00'FROM DUAL UNION ALL
SELECT 21,'21:00'FROM DUAL UNION ALL
SELECT 22,'22:00'FROM DUAL UNION ALL
SELECT 23,'23:00' FROM DUAL
/
------------------------------------------------------------------------------------------------------------------------------------------------------
-- FIM - WISEIT-4840 / WISEIT-4934 Dashboards - visão por dia da semana e horário deve considerar a média como opção padrão, ordenar de segunda a domingo, e exibir as 24h do dia com possibilidade de rolagem lateral
------------------------------------------------------------------------------------------------------------------------------------------------------

EXEC SPDM_CONTROLEVERSAO ('BD_VERSAO_DASHBOARD_COMMONS', '10.0.4');


------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------

