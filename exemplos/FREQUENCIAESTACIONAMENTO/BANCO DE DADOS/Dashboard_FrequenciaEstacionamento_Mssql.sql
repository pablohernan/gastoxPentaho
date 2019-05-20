------------------------------------------------------------------------------------------------------------------------------------------------------
-- 10.0.1 --------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
IF EXISTS(SELECT '' FROM SYSOBJECTS WHERE XTYPE = 'P' AND NAME = 'SPDM_DB_FREQ_ESTACIONAMENTO')
  DROP PROCEDURE SPDM_DB_FREQ_ESTACIONAMENTO
GO

CREATE PROCEDURE SPDM_DB_FREQ_ESTACIONAMENTO
(
	@pSESSAO VARCHAR(20),
	@pCOD_EMPREENDIMENTO INT, 
	@pDTA_INI VARCHAR(30),
	@pDTA_FIM VARCHAR(30),
	@pDIASEMANA VARCHAR(1),
	@pHORA VARCHAR(5),
	@pTEMPOPERMANENCIA VARCHAR(9)
)
AS
/*
--> Para filtar o Dia das semana passar no 5º parâmetro os valores: 1 = DOM , 2 = SEG, 3 = TER, 4 = QUAR, 5 = QUI, 6 = SEX, 7 = SAB
--> Para filtrar poo tempo de permanência, passar os valor: ATE_1H, 1H_2H, 2H_3H, 3H_4H, ACIMA_4H

--> Gráfico para cada dia da semana
EXEC SPDM_DB_FREQ_ESTACIONAMENTO 'DIASEMANA', 1, '2000-01-01 00:00:00','2016-12-31 23:59:59','','',''

--> Grafico para Hora do dia, às segundas.
EXEC SPDM_DB_FREQ_ESTACIONAMENTO 'HORA', 1, '2000-01-01 00:00:00','2016-12-31 23:59:59','2','',''

--> Média de permanência, aos sábados, às 15hs, com tempo de permanência de 2 a 3 horas.
EXEC SPDM_DB_FREQ_ESTACIONAMENTO 'MEDIA_PERMANENCIA', 1, '2000-01-01 00:00:00','2016-12-31 23:59:59','7','15:00','2H_3H'

--> Clientes por tempo de permanência, às quintas, ao meio dia.
EXEC SPDM_DB_FREQ_ESTACIONAMENTO 'TEMPO_PERMANENCIA', 1, '2011-01-01 00:00:00','2016-12-31 23:59:59','5','12:00',''
*/
BEGIN
DECLARE
	@vQUERY VARCHAR(8000), @vWHERE VARCHAR(1000), @vFROM VARCHAR(1000)

SELECT @vQUERY = ''

SELECT @vFROM = '
FROM
	CARTAOESTACIONAMENTO CE
	INNER JOIN TIPOCARTAOESTACIONAMENTO TCE ON (TCE.COD_TIPOCARTAO = CE.COD_TIPOCARTAO)
	INNER JOIN PESSOA_CARTAOESTACIONAMENTO PCE ON (PCE.COD_CARTAO = CE.COD_CARTAO)
	INNER JOIN FREQUENCIAESTACIONAMENTO FE ON (FE.COD_CARTAO = CE.COD_CARTAO AND FE.TMP_PERMANENCIA >= 0)'

-- Filtro por empreendimento (obrigatório).
SELECT @vWHERE = ' AND TCE.COD_EMPREENDIMENTO = '+CONVERT(VARCHAR,@pCOD_EMPREENDIMENTO)

-- Filtro por data na frequencia (data de entrada no estacionamento)
SELECT @vWHERE = @vWHERE+' AND FE.DTA_ENTRADA >= CONVERT(DATETIME,'''+@pDTA_INI+''',121) AND FE.DTA_ENTRADA <= CONVERT(DATETIME,'''+@pDTA_FIM+''',121)'

-- Filtro por dia da semana
IF @pDIASEMANA <> ''
	SELECT @vWHERE = @vWHERE+' AND DATEPART(DW,FE.DTA_ENTRADA) = '+@pDIASEMANA

-- Filtro por hora.
IF @pHORA <> ''
	SELECT @vWHERE = @vWHERE+' AND DATEPART(HH,FE.DTA_ENTRADA) = '+substring(@pHORA,1,2)

-- Filtro por tempo de permanência.
IF @pTEMPOPERMANENCIA = 'ATE_1H'
	SELECT @vWHERE = @vWHERE+' AND FE.TMP_PERMANENCIA = 0'
ELSE IF @pTEMPOPERMANENCIA = '1H_2H'
	SELECT @vWHERE = @vWHERE+' AND FE.TMP_PERMANENCIA = 1'
ELSE IF @pTEMPOPERMANENCIA = '2H_3H'
	SELECT @vWHERE = @vWHERE+' AND FE.TMP_PERMANENCIA = 2'
ELSE IF @pTEMPOPERMANENCIA = '3H_4H'
	SELECT @vWHERE = @vWHERE+' AND FE.TMP_PERMANENCIA = 3'
ELSE IF @pTEMPOPERMANENCIA = 'ACIMA_4H'
	SELECT @vWHERE = @vWHERE+' AND FE.TMP_PERMANENCIA >= 4'


-- Gráfico em pizza ou barras, para cada dia da semana qual a média de frequência
IF @pSESSAO = 'DIASEMANA'
SELECT @vQUERY = 'SELECT
	CASE DATEPART(DW,A.DIA) WHEN 1 THEN ''DOMINGO'' WHEN 2 THEN ''SEGUNDA'' WHEN 3 THEN ''TERÇA'' WHEN 4 THEN ''QUARTA'' WHEN 5 THEN ''QUINTA''
	WHEN 6 THEN ''SEXTA'' WHEN 7 THEN ''SÁBADO'' END AS "DIA_SEMANA", COUNT(A.DIA) AS "QTDE"
FROM
	(
	SELECT DISTINCT
		COD_PESSOA,CONVERT(DATETIME,CONVERT(VARCHAR,DTA_ENTRADA,112)) AS DIA'+
	@vFROM+@vWHERE+
	') A
GROUP BY
	DATEPART(DW,A.DIA)
ORDER BY
	2 DESC';

-- GRÁFICO MÉDIA DE FREQUENCIA POR HORA
IF @pSESSAO = 'HORA'
SELECT @vQUERY = 'SELECT
	CASE A.HORA WHEN 0 THEN ''00:00'' WHEN 1 THEN ''01:00'' WHEN 2 THEN ''02:00'' WHEN 3 THEN ''03:00'' WHEN 4 THEN ''04:00'' WHEN 5 THEN ''05:00'' WHEN 6 THEN ''06:00''
	WHEN 7 THEN ''07:00'' WHEN 8 THEN ''08:00'' WHEN 9 THEN ''09:00'' WHEN 10 THEN ''10:00'' WHEN 11 THEN ''11:00'' WHEN 12 THEN ''12:00'' WHEN 13 THEN ''13:00'' 
	WHEN 14 THEN ''14:00'' WHEN 15 THEN ''15:00'' WHEN 16 THEN ''16:00'' WHEN 17 THEN ''17:00'' WHEN 18 THEN ''18:00'' WHEN 19 THEN ''19:00'' WHEN 20 THEN ''20:00'' 
	WHEN 21 THEN ''21:00'' WHEN 22 THEN ''22:00'' WHEN 23 THEN ''23:00'' END AS "HORA",COUNT(A.HORA)
FROM
	(
	SELECT DISTINCT
		COD_PESSOA,DATEPART(HH,DTA_ENTRADA) AS HORA'+
	@vFROM+@vWHERE+
	') A
GROUP BY
	A.HORA
ORDER BY
	2 DESC'

-- MÉDIA DE PERMANÊNCIA
IF @pSESSAO = 'MEDIA_PERMANENCIA'
	SELECT @vQUERY = 'SELECT AVG(FE.TMP_PERMANENCIA) '+@vFROM+@vWHERE

-- CLIENTES POR TEMPO DE PERMANÊNCIA
IF @pSESSAO = 'TEMPO_PERMANENCIA'
SELECT @vQUERY = 'SELECT
	SUM(Q1) AS "ATE_1H", SUM(Q2) AS "1H_2H", SUM(Q3) AS "2H_3H", SUM(Q4) AS "3H_4H", SUM(Q5) AS "ACIMA_4H" 
FROM
(
SELECT
	CASE WHEN A.TMP_PERMANENCIA = 0 THEN SUM(A.QTDE) END AS "Q1",
	CASE WHEN A.TMP_PERMANENCIA = 1 THEN SUM(A.QTDE) END AS "Q2",
	CASE WHEN A.TMP_PERMANENCIA = 2 THEN SUM(A.QTDE) END AS "Q3",
	CASE WHEN A.TMP_PERMANENCIA = 3 THEN SUM(A.QTDE) END AS "Q4",
	CASE WHEN A.TMP_PERMANENCIA >= 4 THEN SUM(A.QTDE) END AS "Q5"
FROM
(
SELECT 
	FE.TMP_PERMANENCIA, COUNT(*) AS "QTDE"'+
	@vFROM+@vWHERE+
' GROUP BY
	TMP_PERMANENCIA
) A
GROUP BY A.TMP_PERMANENCIA
) B'

EXEC(@vQUERY)
PRINT(@VQUERY)
END
GO

EXEC SPDM_CONTROLEVERSAO 'BD_VERSAO_DASHBOARD_FREQUENCIAESTACIONAMENTO', '10.0.1';
GO
------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------
-- 10.0.2 --------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
IF EXISTS(SELECT '' FROM SYSOBJECTS WHERE XTYPE = 'P' AND NAME = 'SPDM_DB_FREQ_ESTACIONAMENTO')
  DROP PROCEDURE SPDM_DB_FREQ_ESTACIONAMENTO
GO

CREATE PROCEDURE SPDM_DB_FREQ_ESTACIONAMENTO
(
	@pSESSAO VARCHAR(20),
	@pCOD_EMPREENDIMENTO INT, 
	@pDTA_INI VARCHAR(30),
	@pDTA_FIM VARCHAR(30),
	@pDIASEMANA VARCHAR(1),
	@pHORA VARCHAR(5),
	@pTEMPOPERMANENCIA VARCHAR(9)
)
AS
/*
--> Para filtar o Dia das semana passar no 5º parâmetro os valores: 1 = DOM , 2 = SEG, 3 = TER, 4 = QUAR, 5 = QUI, 6 = SEX, 7 = SAB
--> Para filtrar poo tempo de permanência, passar os valor: ATE_1H, 1H_2H, 2H_3H, 3H_4H, ACIMA_4H

--> Gráfico para cada dia da semana
EXEC SPDM_DB_FREQ_ESTACIONAMENTO 'DIASEMANA', 1, '2000-01-01 00:00:00','2016-12-31 23:59:59','','',''

--> Grafico para Hora do dia, às segundas.
EXEC SPDM_DB_FREQ_ESTACIONAMENTO 'HORA', 1, '2000-01-01 00:00:00','2016-12-31 23:59:59','2','',''

--> Média de permanência, aos sábados, às 15hs, com tempo de permanência de 2 a 3 horas.
EXEC SPDM_DB_FREQ_ESTACIONAMENTO 'MEDIA_PERMANENCIA', 1, '2000-01-01 00:00:00','2016-12-31 23:59:59','7','15:00','2H_3H'

--> Clientes por tempo de permanência, às quintas, ao meio dia.
EXEC SPDM_DB_FREQ_ESTACIONAMENTO 'TEMPO_PERMANENCIA', 1, '2011-01-01 00:00:00','2016-12-31 23:59:59','5','12:00',''
*/
BEGIN
DECLARE
	@vQUERY VARCHAR(8000), @vWHERE VARCHAR(1000), @vFROM VARCHAR(1000)

SELECT @vQUERY = ''

SELECT @vFROM = '
FROM
	CARTAOESTACIONAMENTO CE
	INNER JOIN TIPOCARTAOESTACIONAMENTO TCE ON (TCE.COD_TIPOCARTAO = CE.COD_TIPOCARTAO)
	INNER JOIN PESSOA_CARTAOESTACIONAMENTO PCE ON (PCE.COD_CARTAO = CE.COD_CARTAO)
	INNER JOIN FREQUENCIAESTACIONAMENTO FE ON (FE.COD_CARTAO = CE.COD_CARTAO AND FE.TMP_PERMANENCIA >= 0)'

-- Filtro por empreendimento (obrigatório).
SELECT @vWHERE = ' AND TCE.COD_EMPREENDIMENTO = '+CONVERT(VARCHAR,@pCOD_EMPREENDIMENTO)

-- Filtro por data na frequencia (data de entrada no estacionamento)
SELECT @vWHERE = @vWHERE+' AND FE.DTA_ENTRADA >= CONVERT(DATETIME,'''+@pDTA_INI+''',121) AND FE.DTA_ENTRADA <= CONVERT(DATETIME,'''+@pDTA_FIM+''',121)'

-- Filtro por dia da semana
IF @pDIASEMANA <> ''
	SELECT @vWHERE = @vWHERE+' AND DATEPART(DW,FE.DTA_ENTRADA) = '+@pDIASEMANA

-- Filtro por hora.
IF @pHORA <> ''
	SELECT @vWHERE = @vWHERE+' AND DATEPART(HH,FE.DTA_ENTRADA) = '+substring(@pHORA,1,2)

-- Filtro por tempo de permanência.
IF @pTEMPOPERMANENCIA = 'ATE_1H'
	SELECT @vWHERE = @vWHERE+' AND FE.TMP_PERMANENCIA/3600000 = 0'
ELSE IF @pTEMPOPERMANENCIA = '1H_2H'
	SELECT @vWHERE = @vWHERE+' AND FE.TMP_PERMANENCIA/3600000 = 1'
ELSE IF @pTEMPOPERMANENCIA = '2H_3H'
	SELECT @vWHERE = @vWHERE+' AND FE.TMP_PERMANENCIA/3600000 = 2'
ELSE IF @pTEMPOPERMANENCIA = '3H_4H'
	SELECT @vWHERE = @vWHERE+' AND FE.TMP_PERMANENCIA/3600000 = 3'
ELSE IF @pTEMPOPERMANENCIA = 'ACIMA_4H'
	SELECT @vWHERE = @vWHERE+' AND FE.TMP_PERMANENCIA/3600000 >= 4'


-- Gráfico em pizza ou barras, para cada dia da semana qual a média de frequência
IF @pSESSAO = 'DIASEMANA'
SELECT @vQUERY = 'SELECT
	CASE DATEPART(DW,A.DIA) WHEN 1 THEN ''Domingo'' WHEN 2 THEN ''Segunda'' WHEN 3 THEN ''Terça'' WHEN 4 THEN ''Quarta'' WHEN 5 THEN ''Quinta''
	WHEN 6 THEN ''Sexta'' WHEN 7 THEN ''Sábado'' END AS "DIA_SEMANA", COUNT(A.DIA) AS "QTDE"
FROM
	(
	SELECT DISTINCT
		COD_PESSOA,CONVERT(DATETIME,CONVERT(VARCHAR,DTA_ENTRADA,112)) AS DIA'+
	@vFROM+@vWHERE+
	') A
GROUP BY
	DATEPART(DW,A.DIA)
ORDER BY
	DATEPART(DW,A.DIA)';

-- GRÁFICO MÉDIA DE FREQUENCIA POR HORA
IF @pSESSAO = 'HORA'
SELECT @vQUERY = 'SELECT
	CASE A.HORA WHEN 0 THEN ''00:00'' WHEN 1 THEN ''01:00'' WHEN 2 THEN ''02:00'' WHEN 3 THEN ''03:00'' WHEN 4 THEN ''04:00'' WHEN 5 THEN ''05:00'' WHEN 6 THEN ''06:00''
	WHEN 7 THEN ''07:00'' WHEN 8 THEN ''08:00'' WHEN 9 THEN ''09:00'' WHEN 10 THEN ''10:00'' WHEN 11 THEN ''11:00'' WHEN 12 THEN ''12:00'' WHEN 13 THEN ''13:00'' 
	WHEN 14 THEN ''14:00'' WHEN 15 THEN ''15:00'' WHEN 16 THEN ''16:00'' WHEN 17 THEN ''17:00'' WHEN 18 THEN ''18:00'' WHEN 19 THEN ''19:00'' WHEN 20 THEN ''20:00'' 
	WHEN 21 THEN ''21:00'' WHEN 22 THEN ''22:00'' WHEN 23 THEN ''23:00'' END AS "HORA",COUNT(A.HORA)
FROM
	(
	SELECT DISTINCT
		COD_PESSOA,DATEPART(HH,DTA_ENTRADA) AS HORA'+
	@vFROM+@vWHERE+
	') A
GROUP BY
	A.HORA
ORDER BY
	HORA'

-- MÉDIA DE PERMANÊNCIA
IF @pSESSAO = 'MEDIA_PERMANENCIA'
	SELECT @vQUERY = 'SELECT AVG(CONVERT(NUMERIC, FE.TMP_PERMANENCIA)) '+@vFROM+@vWHERE

-- CLIENTES POR TEMPO DE PERMANÊNCIA
IF @pSESSAO = 'TEMPO_PERMANENCIA'
SELECT @vQUERY = 'SELECT 
	CASE
		WHEN FE.TMP_PERMANENCIA/3600000 = 0 THEN ''ATE_1H''
	    WHEN FE.TMP_PERMANENCIA/3600000 = 1 THEN ''1H_2H''
		WHEN FE.TMP_PERMANENCIA/3600000 = 2 THEN ''2H_3H''
		WHEN FE.TMP_PERMANENCIA/3600000 = 3 THEN ''3H_4H''
		WHEN FE.TMP_PERMANENCIA/3600000 >= 4 THEN ''ACIMA_4H''
	END AS "TEMPO",
	COUNT(*) AS "QTDE"'+
	@vFROM+@vWHERE+
'GROUP BY
	CASE
		WHEN FE.TMP_PERMANENCIA/3600000 = 0 THEN ''ATE_1H''
	    WHEN FE.TMP_PERMANENCIA/3600000 = 1 THEN ''1H_2H''
		WHEN FE.TMP_PERMANENCIA/3600000 = 2 THEN ''2H_3H''
		WHEN FE.TMP_PERMANENCIA/3600000 = 3 THEN ''3H_4H''
		WHEN FE.TMP_PERMANENCIA/3600000 >= 4 THEN ''ACIMA_4H''
	END
ORDER BY 2 DESC'

EXEC(@vQUERY)
PRINT(@VQUERY)
END
GO

EXEC SPDM_CONTROLEVERSAO 'BD_VERSAO_DASHBOARD_FREQUENCIAESTACIONAMENTO', '10.0.2';
GO
------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------
-- 10.0.3 --------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------
-- INÍCIO 136195, Ricardo Vale (Principal: 135362) - Criar Item de Menu para o dashboard Frequência e Permanência
--------------------------------------------------------------------------------------------------------------------------------------------
DECLARE
@vNME_MODULO VARCHAR(100),@vNME_ITEMMENU VARCHAR(100),@vSLG_ITEMMENU VARCHAR(100),@vDSC_ITEMMENU VARCHAR(4000),@vNME_ITEMMENUPAI VARCHAR(200),@vURL_ICONE VARCHAR(1000),
@vNME_RECURSO VARCHAR(100),@vNME_CONTEUDO VARCHAR(100),@vURL_CONTEUDO VARCHAR(200),@vPARAM1_CODVARIAVEL INT,@vPARAM1_NMEPARAMETRO VARCHAR(100),@vPARAM1_VLRPARAMETRO VARCHAR(1000),
@vPARAM2_CODVARIAVEL INT,@vPARAM2_NMEPARAMETRO VARCHAR(100),@vPARAM2_VLRPARAMETRO VARCHAR(1000),@vPARAM3_CODVARIAVEL INT,@vPARAM3_NMEPARAMETRO VARCHAR(100),
@vPARAM3_VLRPARAMETRO VARCHAR(1000),@vDSC_PERMISSAORECURSOCONSULTAR VARCHAR(200),@vDSC_PERMISSAORECURSOEXCLUIR VARCHAR(200),@vDSC_PERMISSAORECURSOCADASTRAR VARCHAR(200),
@vDSC_PERMISSAORECURSOEXPORTAR VARCHAR(200),@vDSC_PERMISSAORECURSOEXECUTAR VARCHAR(200),@vDSC_PERMISSAORECURSOPERMITIR VARCHAR(200),@vRETORNO VARCHAR(100),
@vFLG_NOVA_JANELA BIT,@vFLG_RECARREGA BIT,@vFLG_PORTAL BIT,@vFLG_ATENDIMENTO BIT,@vFLG_MULTITELA BIT,@vFLG_WORKFLOW BIT,@vFLG_IE8 BIT,@vNME_CONTROLLER VARCHAR(100),
@vPRT_PERMISSAORECURSOCONSULTAR VARCHAR(200),@vPRT_PERMISSAORECURSOEXCLUIR VARCHAR(200),@vPRT_PERMISSAORECURSOPERMITIR VARCHAR(200),@vPRT_PERMISSAORECURSOCADASTRAR VARCHAR(200),
@vPRT_PERMISSAORECURSOEXPORTAR VARCHAR(200),@vPRT_PERMISSAORECURSOEXECUTAR VARCHAR(200)
BEGIN
  -- Nome do menu.
  SELECT @vNME_ITEMMENU = 'DASHBOARD FREQUÊNCIA E PERMANÊNCIA'
  -- Sigla do menu.
  SELECT @vSLG_ITEMMENU = NULL
  -- Descrição do menu.
  SELECT @vDSC_ITEMMENU = 'Analisar comparativos de dias de semana a frequência usada do estacionamento e também o tempo de permanência dos clientes no estacionamento.'
  -- Caminho do ícone do menu.
  SELECT @vURL_ICONE = '/CCenterWeb/images/portal/icones/gd/ico_dashboard_frequenciapermanencia.gif'
  -- Nome do Menu Pai (caminho completo separado por "/", até 3 níveis), se for menu principal deixar nulo.
  SELECT @vNME_ITEMMENUPAI = 'Relatórios/Estacionamento'
  -- Nome do Recurso
  SELECT @vNME_RECURSO = 'DASHBOARD FREQUÊNCIA E PERMANÊNCIA'
  -- Módulo pertecente ao menu. Preencher somente se tiver RECURSO.
  SELECT @vNME_MODULO = 'ESTACIONAMENTO'
  -- Entrar com as descrições das permissões. Preencher somente se tiver RECURSO.
  SELECT @vDSC_PERMISSAORECURSOCONSULTAR = 'Disponibiliza o ícone Dashboard Frequência e Permanência.'
  SELECT @vDSC_PERMISSAORECURSOPERMITIR = 'Permite mexer nas permissões deste recurso para outros usuários.'
  -- Nome do Conteudo
  SELECT @vNME_CONTEUDO = 'DASHBOARD FREQUÊNCIA E PERMANÊNCIA'
  SELECT @vURL_CONTEUDO = '/CCenterWeb/pentaho/api/repos/%3Apublic%3AFREQUENCIA%3AFREQUENCIA.wcdf/generatedContent'
  SELECT @vFLG_NOVA_JANELA = 0
  SELECT @vFLG_RECARREGA = 0
  SELECT @vFLG_PORTAL = 0
  SELECT @vFLG_ATENDIMENTO = 0
  SELECT @vFLG_MULTITELA = 0
  SELECT @vFLG_WORKFLOW = 0
  SELECT @vFLG_IE8 = 0
  SELECT @vNME_CONTROLLER =	NULL
  -- Parâmetros do conteudo.
  SELECT @vPARAM1_NMEPARAMETRO = 'codUsuario'
  SELECT @vPARAM1_CODVARIAVEL = 3
  SELECT @vPARAM2_NMEPARAMETRO = 'codEmpreendimento'
  SELECT @vPARAM2_CODVARIAVEL = 15

  EXEC SPDM_POPULA_ITEMMENU_NEW	@vNME_MODULO,@vNME_ITEMMENU,@vSLG_ITEMMENU,@vDSC_ITEMMENU,@vNME_ITEMMENUPAI,@vURL_ICONE,@vNME_RECURSO,@vNME_CONTEUDO,@vURL_CONTEUDO,
	@vFLG_NOVA_JANELA,@vFLG_RECARREGA,@vFLG_PORTAL,@vFLG_ATENDIMENTO,@vFLG_MULTITELA,@vFLG_WORKFLOW,@vFLG_IE8,@vNME_CONTROLLER,@vPARAM1_CODVARIAVEL,@vPARAM1_NMEPARAMETRO,
	@vPARAM1_VLRPARAMETRO,@vPARAM2_CODVARIAVEL,@vPARAM2_NMEPARAMETRO,@vPARAM2_VLRPARAMETRO,@vPARAM3_CODVARIAVEL,@vPARAM3_NMEPARAMETRO,@vPARAM3_VLRPARAMETRO,
	@vDSC_PERMISSAORECURSOCONSULTAR,@vPRT_PERMISSAORECURSOCONSULTAR,@vDSC_PERMISSAORECURSOEXCLUIR,@vPRT_PERMISSAORECURSOEXCLUIR,
	@vDSC_PERMISSAORECURSOCADASTRAR,@vPRT_PERMISSAORECURSOCADASTRAR,@vDSC_PERMISSAORECURSOEXPORTAR,@vPRT_PERMISSAORECURSOEXPORTAR,
	@vDSC_PERMISSAORECURSOEXECUTAR,@vPRT_PERMISSAORECURSOEXECUTAR,@vDSC_PERMISSAORECURSOPERMITIR,@vPRT_PERMISSAORECURSOPERMITIR,@vRETORNO OUTPUT
  PRINT (@vRETORNO)
END
GO
--------------------------------------------------------------------------------------------------------------------------------------------
-- FIM 136195, Ricardo Vale (Principal: 135362) - Criar Item de Menu para o dashboard Frequência e Permanência
--------------------------------------------------------------------------------------------------------------------------------------------

EXEC SPDM_CONTROLEVERSAO 'BD_VERSAO_DASHBOARD_FREQUENCIAESTACIONAMENTO', '10.0.3';
GO
------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------
-- 10.0.4 --------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------

-- Alteração para criar o menu "Estacionamento" dentro de "Marketing", sem tarefa a pedido do Rafael pois o Ricardo não criou o menu pai.
-----------------------------------------------------------------------------------------------------------
--> MENU "Relatórios >> Estacionamento"
-----------------------------------------------------------------------------------------------------------
DECLARE
@vNME_MODULO VARCHAR(100),@vNME_ITEMMENU VARCHAR(100),@vSLG_ITEMMENU VARCHAR(100),@vDSC_ITEMMENU VARCHAR(4000),@vNME_ITEMMENUPAI VARCHAR(200),@vURL_ICONE VARCHAR(1000),
@vNME_RECURSO VARCHAR(100),@vNME_CONTEUDO VARCHAR(100),@vURL_CONTEUDO VARCHAR(200),@vPARAM1_CODVARIAVEL INT,@vPARAM1_NMEPARAMETRO VARCHAR(100),@vPARAM1_VLRPARAMETRO VARCHAR(1000),
@vPARAM2_CODVARIAVEL INT,@vPARAM2_NMEPARAMETRO VARCHAR(100),@vPARAM2_VLRPARAMETRO VARCHAR(1000),@vPARAM3_CODVARIAVEL INT,@vPARAM3_NMEPARAMETRO VARCHAR(100),
@vPARAM3_VLRPARAMETRO VARCHAR(1000),@vDSC_PERMISSAORECURSOCONSULTAR VARCHAR(200),@vDSC_PERMISSAORECURSOEXCLUIR VARCHAR(200),@vDSC_PERMISSAORECURSOCADASTRAR VARCHAR(200),
@vDSC_PERMISSAORECURSOEXPORTAR VARCHAR(200),@vDSC_PERMISSAORECURSOEXECUTAR VARCHAR(200),@vDSC_PERMISSAORECURSOPERMITIR VARCHAR(200),@vRETORNO VARCHAR(100),
@vFLG_NOVA_JANELA BIT,@vFLG_RECARREGA BIT,@vFLG_PORTAL BIT,@vFLG_ATENDIMENTO BIT,@vFLG_MULTITELA BIT,@vFLG_WORKFLOW BIT,@vFLG_IE8 BIT,@vNME_CONTROLLER VARCHAR(100),
@vPRT_PERMISSAORECURSOCONSULTAR VARCHAR(200),@vPRT_PERMISSAORECURSOEXCLUIR VARCHAR(200),@vPRT_PERMISSAORECURSOPERMITIR VARCHAR(200),@vPRT_PERMISSAORECURSOCADASTRAR VARCHAR(200),
@vPRT_PERMISSAORECURSOEXPORTAR VARCHAR(200),@vPRT_PERMISSAORECURSOEXECUTAR VARCHAR(200)
BEGIN
  -- Nome do menu.
  SELECT @vNME_ITEMMENU = 'Estacionamento'
  -- Sigla do menu.
  SELECT @vSLG_ITEMMENU = 'ESTACIONAMENTO'
  -- Descrição do menu.
  SELECT @vDSC_ITEMMENU = 'Relatórios e dashboards de estacionamento'
  -- Caminho do ícone do menu.
  SELECT @vURL_ICONE = NULL
  -- Nome do Menu Pai (caminho completo separado por "/", até 3 níveis), se for menu principal deixar nulo.
  SELECT @vNME_ITEMMENUPAI = 'Relatórios'
  -- Nome do Recurso
  SELECT @vNME_RECURSO = NULL
  -- Módulo pertecente ao menu. Preencher somente se tiver RECURSO.
  SELECT @vNME_MODULO = 'CADASTROS'
  -- Nome do Conteudo
  SELECT @vNME_CONTEUDO = NULL
  SELECT @vURL_CONTEUDO = NULL
  SELECT @vFLG_NOVA_JANELA = 0
  SELECT @vFLG_RECARREGA = 0
  SELECT @vFLG_PORTAL = 1
  SELECT @vFLG_ATENDIMENTO = 0
  SELECT @vFLG_MULTITELA = 0
  SELECT @vFLG_WORKFLOW = 0
  SELECT @vFLG_IE8 = 0
  SELECT @vNME_CONTROLLER = NULL
  -- Entrar com as descrições das permissões.
  SELECT @vDSC_PERMISSAORECURSOCONSULTAR = NULL
  SELECT @vDSC_PERMISSAORECURSOEXCLUIR = NULL
  SELECT @vDSC_PERMISSAORECURSOCADASTRAR = NULL
  SELECT @vDSC_PERMISSAORECURSOEXPORTAR = NULL
  SELECT @vDSC_PERMISSAORECURSOEXECUTAR = NULL
  SELECT @vDSC_PERMISSAORECURSOPERMITIR = NULL

  EXEC SPDM_POPULA_ITEMMENU_NEW	@vNME_MODULO,@vNME_ITEMMENU,@vSLG_ITEMMENU,@vDSC_ITEMMENU,@vNME_ITEMMENUPAI,@vURL_ICONE,@vNME_RECURSO,@vNME_CONTEUDO,@vURL_CONTEUDO,
	@vFLG_NOVA_JANELA,@vFLG_RECARREGA,@vFLG_PORTAL,@vFLG_ATENDIMENTO,@vFLG_MULTITELA,@vFLG_WORKFLOW,@vFLG_IE8,@vNME_CONTROLLER,@vPARAM1_CODVARIAVEL,@vPARAM1_NMEPARAMETRO,
	@vPARAM1_VLRPARAMETRO,@vPARAM2_CODVARIAVEL,@vPARAM2_NMEPARAMETRO,@vPARAM2_VLRPARAMETRO,@vPARAM3_CODVARIAVEL,@vPARAM3_NMEPARAMETRO,@vPARAM3_VLRPARAMETRO,
	@vDSC_PERMISSAORECURSOCONSULTAR,@vPRT_PERMISSAORECURSOCONSULTAR,@vDSC_PERMISSAORECURSOEXCLUIR,@vPRT_PERMISSAORECURSOEXCLUIR,
	@vDSC_PERMISSAORECURSOCADASTRAR,@vPRT_PERMISSAORECURSOCADASTRAR,@vDSC_PERMISSAORECURSOEXPORTAR,@vPRT_PERMISSAORECURSOEXPORTAR,
	@vDSC_PERMISSAORECURSOEXECUTAR,@vPRT_PERMISSAORECURSOEXECUTAR,@vDSC_PERMISSAORECURSOPERMITIR,@vPRT_PERMISSAORECURSOPERMITIR,@vRETORNO OUTPUT
  PRINT (@vRETORNO)
END
GO

UPDATE MENU SET COD_ITEMMENUPAI = (SELECT COD_ITEMMENU FROM ITEMMENU WHERE NME_ITEMMENU = 'ESTACIONAMENTO' AND COD_ITEMMENU IN (SELECT COD_ITEMMENU FROM MENU WHERE FLG_NOVAINTERFACE = 1))
WHERE COD_ITEMMENU IN (SELECT COD_ITEMMENU FROM ITEMMENU WHERE NME_ITEMMENU = 'DASHBOARD FREQUÊNCIA E PERMANÊNCIA');
GO

EXEC SPDM_CONTROLEVERSAO 'BD_VERSAO_DASHBOARD_FREQUENCIAESTACIONAMENTO', '10.0.4';
GO
------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------
-- 10.0.5 --------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------------------------------------------
-- INICIO 136871, Fabricio Machado (Principal: 136871) - Dashboard Frequência e Permanência - Calcular total de clientes
----------------------------------------------------------------------------------------------------------------------------------------
IF EXISTS(SELECT '' FROM SYSOBJECTS WHERE XTYPE = 'P' AND NAME = 'SPDM_DB_FREQ_ESTACIONAMENTO')
  DROP PROCEDURE SPDM_DB_FREQ_ESTACIONAMENTO
GO

CREATE PROCEDURE SPDM_DB_FREQ_ESTACIONAMENTO
(
	@pSESSAO VARCHAR(20),
	@pCOD_EMPREENDIMENTO INT, 
	@pDTA_INI VARCHAR(30),
	@pDTA_FIM VARCHAR(30),
	@pDIASEMANA VARCHAR(1),
	@pHORA VARCHAR(5),
	@pTEMPOPERMANENCIA VARCHAR(9)
)
AS
/*
--> Para filtar o Dia das semana passar no 5º parâmetro os valores: 1 = DOM , 2 = SEG, 3 = TER, 4 = QUAR, 5 = QUI, 6 = SEX, 7 = SAB
--> Para filtrar poo tempo de permanência, passar os valor: ATE_1H, 1H_2H, 2H_3H, 3H_4H, ACIMA_4H

--> Gráfico para cada dia da semana
EXEC SPDM_DB_FREQ_ESTACIONAMENTO 'DIASEMANA', 1, '2000-01-01 00:00:00','2016-12-31 23:59:59','','',''

--> Grafico para Hora do dia, às segundas.
EXEC SPDM_DB_FREQ_ESTACIONAMENTO 'HORA', 1, '2000-01-01 00:00:00','2016-12-31 23:59:59','2','',''

--> Média de permanência, aos sábados, às 15hs, com tempo de permanência de 2 a 3 horas.
EXEC SPDM_DB_FREQ_ESTACIONAMENTO 'MEDIA_PERMANENCIA', 1, '2000-01-01 00:00:00','2016-12-31 23:59:59','7','15:00','2H_3H'

--> Clientes por tempo de permanência, às quintas, ao meio dia.
EXEC SPDM_DB_FREQ_ESTACIONAMENTO 'TEMPO_PERMANENCIA', 1, '2011-01-01 00:00:00','2016-12-31 23:59:59','5','12:00',''
*/
BEGIN
DECLARE
	@vQUERY VARCHAR(8000), @vWHERE VARCHAR(1000), @vFROM VARCHAR(1000)

SELECT @vQUERY = ''

SELECT @vFROM = '
FROM
	CARTAOESTACIONAMENTO CE
	INNER JOIN TIPOCARTAOESTACIONAMENTO TCE ON (TCE.COD_TIPOCARTAO = CE.COD_TIPOCARTAO)
	INNER JOIN PESSOA_CARTAOESTACIONAMENTO PCE ON (PCE.COD_CARTAO = CE.COD_CARTAO)
	INNER JOIN FREQUENCIAESTACIONAMENTO FE ON (FE.COD_CARTAO = CE.COD_CARTAO AND FE.TMP_PERMANENCIA >= 0)'

-- Filtro por empreendimento (obrigatório).
SELECT @vWHERE = ' AND TCE.COD_EMPREENDIMENTO = '+CONVERT(VARCHAR,@pCOD_EMPREENDIMENTO)

-- Filtro por data na frequencia (data de entrada no estacionamento)
SELECT @vWHERE = @vWHERE+' AND FE.DTA_ENTRADA >= CONVERT(DATETIME,'''+@pDTA_INI+''',121) AND FE.DTA_ENTRADA <= CONVERT(DATETIME,'''+@pDTA_FIM+''',121)'

-- Filtro por dia da semana
IF @pDIASEMANA <> ''
	SELECT @vWHERE = @vWHERE+' AND DATEPART(DW,FE.DTA_ENTRADA) = '+@pDIASEMANA

-- Filtro por hora.
IF @pHORA <> ''
	SELECT @vWHERE = @vWHERE+' AND DATEPART(HH,FE.DTA_ENTRADA) = '+substring(@pHORA,1,2)

-- Filtro por tempo de permanência.
IF @pTEMPOPERMANENCIA = 'ATE_1H'
	SELECT @vWHERE = @vWHERE+' AND FE.TMP_PERMANENCIA/3600000 = 0'
ELSE IF @pTEMPOPERMANENCIA = '1H_2H'
	SELECT @vWHERE = @vWHERE+' AND FE.TMP_PERMANENCIA/3600000 = 1'
ELSE IF @pTEMPOPERMANENCIA = '2H_3H'
	SELECT @vWHERE = @vWHERE+' AND FE.TMP_PERMANENCIA/3600000 = 2'
ELSE IF @pTEMPOPERMANENCIA = '3H_4H'
	SELECT @vWHERE = @vWHERE+' AND FE.TMP_PERMANENCIA/3600000 = 3'
ELSE IF @pTEMPOPERMANENCIA = 'ACIMA_4H'
	SELECT @vWHERE = @vWHERE+' AND FE.TMP_PERMANENCIA/3600000 >= 4'


-- Gráfico em pizza ou barras, para cada dia da semana qual a média de frequência
IF @pSESSAO = 'DIASEMANA'
SELECT @vQUERY = 'SELECT
	CASE DATEPART(DW,A.DIA) WHEN 1 THEN ''Domingo'' WHEN 2 THEN ''Segunda'' WHEN 3 THEN ''Terça'' WHEN 4 THEN ''Quarta'' WHEN 5 THEN ''Quinta''
	WHEN 6 THEN ''Sexta'' WHEN 7 THEN ''Sábado'' END AS "DIA_SEMANA", COUNT(A.DIA) AS "QTDE"
FROM
	(
	SELECT DISTINCT
		COD_PESSOA,CONVERT(DATETIME,CONVERT(VARCHAR,DTA_ENTRADA,112)) AS DIA'+
	@vFROM+@vWHERE+
	') A
GROUP BY
	DATEPART(DW,A.DIA)
ORDER BY
	DATEPART(DW,A.DIA)';

-- GRÁFICO MÉDIA DE FREQUENCIA POR HORA
IF @pSESSAO = 'HORA'
SELECT @vQUERY = 'SELECT
	CASE A.HORA WHEN 0 THEN ''00:00'' WHEN 1 THEN ''01:00'' WHEN 2 THEN ''02:00'' WHEN 3 THEN ''03:00'' WHEN 4 THEN ''04:00'' WHEN 5 THEN ''05:00'' WHEN 6 THEN ''06:00''
	WHEN 7 THEN ''07:00'' WHEN 8 THEN ''08:00'' WHEN 9 THEN ''09:00'' WHEN 10 THEN ''10:00'' WHEN 11 THEN ''11:00'' WHEN 12 THEN ''12:00'' WHEN 13 THEN ''13:00'' 
	WHEN 14 THEN ''14:00'' WHEN 15 THEN ''15:00'' WHEN 16 THEN ''16:00'' WHEN 17 THEN ''17:00'' WHEN 18 THEN ''18:00'' WHEN 19 THEN ''19:00'' WHEN 20 THEN ''20:00'' 
	WHEN 21 THEN ''21:00'' WHEN 22 THEN ''22:00'' WHEN 23 THEN ''23:00'' END AS "HORA",COUNT(*)
FROM
	(
	SELECT DISTINCT
		COD_PESSOA,CONVERT(VARCHAR,DTA_ENTRADA,112) AS "DIA", DATEPART(HH,DTA_ENTRADA) AS "HORA"'+
	@vFROM+@vWHERE+
	') A
GROUP BY
	A.HORA
ORDER BY
	HORA'

-- MÉDIA DE PERMANÊNCIA
IF @pSESSAO = 'MEDIA_PERMANENCIA'
	SELECT @vQUERY = 'SELECT AVG(CONVERT(NUMERIC, FE.TMP_PERMANENCIA)),Count(DISTINCT PCE.COD_PESSOA) AS "TOTAL_CLIENTES" '+@vFROM+@vWHERE

-- CLIENTES POR TEMPO DE PERMANÊNCIA
IF @pSESSAO = 'TEMPO_PERMANENCIA'
SELECT @vQUERY = 'SELECT 
	CASE
		WHEN FE.TMP_PERMANENCIA/3600000 = 0 THEN ''ATE_1H''
	    WHEN FE.TMP_PERMANENCIA/3600000 = 1 THEN ''1H_2H''
		WHEN FE.TMP_PERMANENCIA/3600000 = 2 THEN ''2H_3H''
		WHEN FE.TMP_PERMANENCIA/3600000 = 3 THEN ''3H_4H''
		WHEN FE.TMP_PERMANENCIA/3600000 >= 4 THEN ''ACIMA_4H''
	END AS "TEMPO",
	COUNT(*) AS "QTDE"'+
	@vFROM+@vWHERE+
'GROUP BY
	CASE
		WHEN FE.TMP_PERMANENCIA/3600000 = 0 THEN ''ATE_1H''
	    WHEN FE.TMP_PERMANENCIA/3600000 = 1 THEN ''1H_2H''
		WHEN FE.TMP_PERMANENCIA/3600000 = 2 THEN ''2H_3H''
		WHEN FE.TMP_PERMANENCIA/3600000 = 3 THEN ''3H_4H''
		WHEN FE.TMP_PERMANENCIA/3600000 >= 4 THEN ''ACIMA_4H''
	END
ORDER BY 2 DESC'

EXEC(@vQUERY)
PRINT(@VQUERY)
END
GO
----------------------------------------------------------------------------------------------------------------------------------------
-- FIM 136871, Fabricio Machado (Principal: 136871) - Dashboard Frequência e Permanência - Calcular total de clientes
----------------------------------------------------------------------------------------------------------------------------------------

EXEC SPDM_CONTROLEVERSAO 'BD_VERSAO_DASHBOARD_FREQUENCIAESTACIONAMENTO', '10.0.5';
GO
--10.0.6----------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------


--------------------------------------------------------------------------------------------
-- INICIO paulo.casaes, NEWWISEIT-1471, NEWWISEIT-887 Segmentação - poder abrir dashboard
--------------------------------------------------------------------------------------------


DECLARE @COD_VARIAVEL INT;
SELECT @COD_VARIAVEL = Count(*) FROM VARIAVEL WHERE NME_VARIAVEL = 'SEGMENTACAO.ID';
IF @COD_VARIAVEL = 0
BEGIN
	INSERT INTO VARIAVEL (COD_VARIAVEL, NME_VARIAVEL, DSC_VARIAVEL, PRT_VARIAVEL) VALUES (21, 'SEGMENTACAO.ID', 'CÓDIGO DA SEGMENTAÇÃO', 'labels.conteudo.parametro.combo.variavel.valor.segmentacao.id');
END
go



IF not EXISTS (SELECT * FROM SYSOBJECTS WHERE TYPE = 'U' AND NAME = 'CONTEXTO_CONTEUDO')
BEGIN
--associação de conteudo (dashboard) ao um contexto de segmentação com recurso que dá permissão ao conteudo
CREATE TABLE CONTEXTO_CONTEUDO (
  COD_CONTEXTO INTEGER NOT NULL,
  COD_CONTEUDO INTEGER NOT NULL,
  COD_RECURSO INTEGER NOT NULL,
  PRIMARY KEY (COD_CONTEXTO, COD_CONTEUDO)
);


ALTER TABLE CONTEXTO_CONTEUDO ADD FOREIGN KEY (COD_CONTEXTO) REFERENCES CONTEXTO;
ALTER TABLE CONTEXTO_CONTEUDO ADD FOREIGN KEY (COD_CONTEUDO) REFERENCES CONTEUDO;
ALTER TABLE CONTEXTO_CONTEUDO ADD FOREIGN KEY (COD_RECURSO) REFERENCES RECURSO;

END;
go




DECLARE @vCOD_CONTEXTO INT;
DECLARE @vCOD_CONTEUDO INT;
DECLARE @vCOD_VARIAVEL INT;
DECLARE @vCOD_PARAMETRO INT;
DECLARE @vCOD_RECURSO INT;


  SELECT @vCOD_CONTEUDO = COD_CONTEUDO FROM CONTEUDO WHERE NME_CONTEUDO like  'DASHBOARD FREQUÊNCIA E PERMANÊNCIA'
  SELECT @vCOD_VARIAVEL = COD_VARIAVEL FROM VARIAVEL WHERE NME_VARIAVEL like  'SEGMENTACAO.ID'
  SELECT @vCOD_RECURSO = COD_RECURSO FROM ITEMMENU WHERE COD_CONTEUDO = @vCOD_CONTEUDO
  SELECT @vCOD_CONTEXTO = COD_CONTEXTO FROM CONTEXTO WHERE NME_CONTEXTO like 'CLIENTE'

EXEC spdm_getnextid 'PARAMETRO','COD_PARAMETRO',@vCOD_PARAMETRO OUTPUT
  INSERT INTO PARAMETRO (COD_PARAMETRO, COD_CONTEUDO, COD_VARIAVEL, NME_PARAMETRO) VALUES (@vCOD_PARAMETRO, @vCOD_CONTEUDO, @vCOD_VARIAVEL, 'codSegmentacao')
  INSERT INTO CONTEXTO_CONTEUDO (COD_CONTEXTO, COD_CONTEUDO, COD_RECURSO) values (@vCOD_CONTEXTO, @vCOD_CONTEUDO, @vCOD_RECURSO)
go
--------------------------------------------------------------------------------------------
-- FIM paulo.casaes, NEWWISEIT-1471, NEWWISEIT-887 Segmentação - poder abrir dashboard
--------------------------------------------------------------------------------------------

EXEC SPDM_CONTROLEVERSAO 'BD_VERSAO_DASHBOARD_FREQUENCIAESTACIONAMENTO', '10.0.6';
GO
------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------

--10.0.7----------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- INICIO - 137401, Fabricio Machado (Principal: 137400) - Novo filtro de segmentação no dashboard de FREQUENCIA ESTACIONAMENTO (procedure)
-- INICIO - 137905, Fabricio Machado (Principal: 137872) - Dashboard Frequência Estacionamento - exibir segmentação, está exibidno a média errada e contando cliente onde seria frequencia
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
IF EXISTS(SELECT '' FROM SYSOBJECTS WHERE XTYPE = 'P' AND NAME = 'SPDM_DB_FREQ_ESTACIONAMENTO')
  DROP PROCEDURE SPDM_DB_FREQ_ESTACIONAMENTO
GO

CREATE PROCEDURE SPDM_DB_FREQ_ESTACIONAMENTO
(
	@pSESSAO VARCHAR(20),
	@pCOD_EMPREENDIMENTO INT, 
	@pDTA_INI VARCHAR(30),
	@pDTA_FIM VARCHAR(30),
	@pDIASEMANA VARCHAR(1),
	@pHORA VARCHAR(5),
	@pTEMPOPERMANENCIA VARCHAR(9),
	@pCOD_SEGMENTACAO VARCHAR(20)
)
AS
/*
--> Para filtar o Dia das semana passar no 5º parâmetro os valores: 1 = DOM , 2 = SEG, 3 = TER, 4 = QUAR, 5 = QUI, 6 = SEX, 7 = SAB
--> Para filtrar poo tempo de permanência, passar os valor: ATE_1H, 1H_2H, 2H_3H, 3H_4H, ACIMA_4H

--> Gráfico para cada dia da semana
EXEC SPDM_DB_FREQ_ESTACIONAMENTO 'DIASEMANA', 1, '2000-01-01 00:00:00','2016-12-31 23:59:59','','','',''

--> Grafico para Hora do dia, às segundas.
EXEC SPDM_DB_FREQ_ESTACIONAMENTO 'HORA', 1, '2000-01-01 00:00:00','2016-12-31 23:59:59','2','','',''

--> Média de permanência, aos sábados, às 15hs, com tempo de permanência de 2 a 3 horas.
EXEC SPDM_DB_FREQ_ESTACIONAMENTO 'MEDIA_PERMANENCIA', 1, '2000-01-01 00:00:00','2016-12-31 23:59:59','','','',''

--> Clientes por tempo de permanência, às quintas, ao meio dia.
EXEC SPDM_DB_FREQ_ESTACIONAMENTO 'TEMPO_PERMANENCIA', 1, '2011-01-01 00:00:00','2016-12-31 23:59:59','5','12:00','',''
*/
BEGIN
DECLARE
	@vQUERY VARCHAR(8000), @vWHERE VARCHAR(4000), @vFROM VARCHAR(1000), @vSQL_SEGMENTACAO VARCHAR(8000)

SELECT @vQUERY = ''

SELECT @vFROM = '
FROM
	CARTAOESTACIONAMENTO CE
	INNER JOIN TIPOCARTAOESTACIONAMENTO TCE ON (TCE.COD_TIPOCARTAO = CE.COD_TIPOCARTAO)
	INNER JOIN PESSOA_CARTAOESTACIONAMENTO PCE ON (PCE.COD_CARTAO = CE.COD_CARTAO)
	INNER JOIN FREQUENCIAESTACIONAMENTO FE ON (FE.COD_CARTAO = CE.COD_CARTAO AND FE.TMP_PERMANENCIA >= 0)'

-- Filtro por empreendimento (obrigatório).
SELECT @vWHERE = ' AND TCE.COD_EMPREENDIMENTO = '+CONVERT(VARCHAR,@pCOD_EMPREENDIMENTO)

-- Filtro por data na frequencia (data de entrada no estacionamento)
SELECT @vWHERE = @vWHERE+' AND FE.DTA_ENTRADA >= CONVERT(DATETIME,'''+@pDTA_INI+''',121) AND FE.DTA_ENTRADA <= CONVERT(DATETIME,'''+@pDTA_FIM+''',121)'

-- Filtro por dia da semana
IF @pDIASEMANA <> ''
	SELECT @vWHERE = @vWHERE+' AND DATEPART(DW,FE.DTA_ENTRADA) = '+@pDIASEMANA

-- Filtro por hora.
IF @pHORA <> ''
	SELECT @vWHERE = @vWHERE+' AND DATEPART(HH,FE.DTA_ENTRADA) = '+substring(@pHORA,1,2)

-- Filtro por tempo de permanência.
IF @pTEMPOPERMANENCIA = 'ATE_1H'
	SELECT @vWHERE = @vWHERE+' AND FE.TMP_PERMANENCIA/3600000 = 0'
ELSE IF @pTEMPOPERMANENCIA = '1H_2H'
	SELECT @vWHERE = @vWHERE+' AND FE.TMP_PERMANENCIA/3600000 = 1'
ELSE IF @pTEMPOPERMANENCIA = '2H_3H'
	SELECT @vWHERE = @vWHERE+' AND FE.TMP_PERMANENCIA/3600000 = 2'
ELSE IF @pTEMPOPERMANENCIA = '3H_4H'
	SELECT @vWHERE = @vWHERE+' AND FE.TMP_PERMANENCIA/3600000 = 3'
ELSE IF @pTEMPOPERMANENCIA = 'ACIMA_4H'
	SELECT @vWHERE = @vWHERE+' AND FE.TMP_PERMANENCIA/3600000 >= 4'

-- Filtro por segmentação
IF @pCOD_SEGMENTACAO <> ''
BEGIN
	SELECT @vSQL_SEGMENTACAO = REPLACE(CONVERT(VARCHAR(8000),SQL_SEGMENTACAO),'COUNT( DISTINCT PESSOAFISICA.COD_PESSOA ) 	 AS "QTD_ROWS"','DISTINCT PESSOAFISICA.COD_PESSOA')
	FROM SEGMENTACAO 
	WHERE COD_SEGMENTACAO = @pCOD_SEGMENTACAO;
	SELECT @vWHERE = @vWHERE+' AND PCE.COD_PESSOA IN ('+@vSQL_SEGMENTACAO+')';
END

-- Gráfico em pizza ou barras, para cada dia da semana qual a média de frequência
IF @pSESSAO = 'DIASEMANA'
SELECT @vQUERY = 'SELECT
	CASE DATEPART(DW,DTA_ENTRADA) WHEN 1 THEN ''Domingo'' WHEN 2 THEN ''Segunda'' WHEN 3 THEN ''Terça'' WHEN 4 THEN ''Quarta'' WHEN 5 THEN ''Quinta''
	WHEN 6 THEN ''Sexta'' WHEN 7 THEN ''Sábado'' END AS "DIA_SEMANA", COUNT(PCE.COD_PESSOA) AS "QTDE"'+
	@vFROM+@vWHERE+
' GROUP BY
	DATEPART(DW,DTA_ENTRADA)
ORDER BY
	DATEPART(DW,DTA_ENTRADA)';

-- GRÁFICO MÉDIA DE FREQUENCIA POR HORA
IF @pSESSAO = 'HORA'
SELECT @vQUERY = 'SELECT
	CASE DTA_ENTRADA WHEN 0 THEN ''00:00'' WHEN 1 THEN ''01:00'' WHEN 2 THEN ''02:00'' WHEN 3 THEN ''03:00'' WHEN 4 THEN ''04:00'' WHEN 5 THEN ''05:00'' WHEN 6 THEN ''06:00''
	WHEN 7 THEN ''07:00'' WHEN 8 THEN ''08:00'' WHEN 9 THEN ''09:00'' WHEN 10 THEN ''10:00'' WHEN 11 THEN ''11:00'' WHEN 12 THEN ''12:00'' WHEN 13 THEN ''13:00'' 
	WHEN 14 THEN ''14:00'' WHEN 15 THEN ''15:00'' WHEN 16 THEN ''16:00'' WHEN 17 THEN ''17:00'' WHEN 18 THEN ''18:00'' WHEN 19 THEN ''19:00'' WHEN 20 THEN ''20:00'' 
	WHEN 21 THEN ''21:00'' WHEN 22 THEN ''22:00'' WHEN 23 THEN ''23:00'' END AS "HORA",COUNT(*)'+
	@vFROM+@vWHERE+
' GROUP BY
	DTA_ENTRADA
ORDER BY
	DTA_ENTRADA'

-- MÉDIA DE PERMANÊNCIA
IF @pSESSAO = 'MEDIA_PERMANENCIA'
	SELECT @vQUERY = 'SELECT left(dbo.func_RETORNATEMPO(SUM(CONVERT(NUMERIC,DATEDIFF(SECOND,DTA_ENTRADA,DTA_SAIDA)))/count(*)),5),
		Count(DISTINCT PCE.COD_PESSOA) AS "TOTAL_CLIENTES" '+@vFROM+@vWHERE

-- CLIENTES POR TEMPO DE PERMANÊNCIA
IF @pSESSAO = 'TEMPO_PERMANENCIA'
SELECT @vQUERY = 'SELECT 
	CASE
		WHEN FE.TMP_PERMANENCIA/3600000 = 0 THEN ''ATE_1H''
	    WHEN FE.TMP_PERMANENCIA/3600000 = 1 THEN ''1H_2H''
		WHEN FE.TMP_PERMANENCIA/3600000 = 2 THEN ''2H_3H''
		WHEN FE.TMP_PERMANENCIA/3600000 = 3 THEN ''3H_4H''
		WHEN FE.TMP_PERMANENCIA/3600000 >= 4 THEN ''ACIMA_4H''
	END AS "TEMPO",
	COUNT(*) AS "QTDE"'+
	@vFROM+@vWHERE+
'GROUP BY
	CASE
		WHEN FE.TMP_PERMANENCIA/3600000 = 0 THEN ''ATE_1H''
	    WHEN FE.TMP_PERMANENCIA/3600000 = 1 THEN ''1H_2H''
		WHEN FE.TMP_PERMANENCIA/3600000 = 2 THEN ''2H_3H''
		WHEN FE.TMP_PERMANENCIA/3600000 = 3 THEN ''3H_4H''
		WHEN FE.TMP_PERMANENCIA/3600000 >= 4 THEN ''ACIMA_4H''
	END
ORDER BY 2 DESC'

EXEC(@vQUERY)
PRINT(@VQUERY)
END
GO
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FIM - 137401, Fabricio Machado (Principal: 137400) - Novo filtro de segmentação no dashboard de FREQUENCIA ESTACIONAMENTO (procedure)
-- FIM - 137905, Fabricio Machado (Principal: 137872) - Dashboard Frequência Estacionamento - exibir segmentação, está exibidno a média errada e contando cliente onde seria frequencia
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

EXEC SPDM_CONTROLEVERSAO 'BD_VERSAO_DASHBOARD_FREQUENCIAESTACIONAMENTO', '10.0.7';
GO
------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------

--10.0.8----------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------
-- INICIO - WISEIT-1559 - Fabricio - Dashboard de Estacionamento - corrigir nomenclaturas
------------------------------------------------------------------------------------------------------------------------------------------------
UPDATE ITEMMENU SET NME_ITEMMENU = 'DASHBOARD DE ESTACIONAMENTO' WHERE NME_ITEMMENU = 'DASHBOARD FREQUÊNCIA E PERMANÊNCIA';
UPDATE RECURSO SET NME_RECURSO = 'DASHBOARD DE ESTACIONAMENTO' WHERE NME_RECURSO = 'DASHBOARD FREQUÊNCIA E PERMANÊNCIA';
UPDATE CONTEUDO SET NME_CONTEUDO = 'DASHBOARD DE ESTACIONAMENTO' WHERE NME_CONTEUDO = 'DASHBOARD FREQUÊNCIA E PERMANÊNCIA';
GO
------------------------------------------------------------------------------------------------------------------------------------------------
-- FIM - WISEIT-1559 - Fabricio - Dashboard de Estacionamento - corrigir nomenclaturas
------------------------------------------------------------------------------------------------------------------------------------------------

EXEC SPDM_CONTROLEVERSAO 'BD_VERSAO_DASHBOARD_FREQUENCIAESTACIONAMENTO', '10.0.8';
GO
------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------

--10.0.9----------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------------------
-- INICIO - Fabricio - WISEIT-3798 Dashboard Estacionamento - não está incluindo a data "até"
----------------------------------------------------------------------------------------------------------------
IF EXISTS(SELECT '' FROM SYSOBJECTS WHERE XTYPE = 'P' AND NAME = 'SPDM_DB_FREQ_ESTACIONAMENTO')
  DROP PROCEDURE SPDM_DB_FREQ_ESTACIONAMENTO
GO

CREATE PROCEDURE SPDM_DB_FREQ_ESTACIONAMENTO
(
	@pSECAO VARCHAR(20),
	@pCOD_EMPREENDIMENTO INT, 
	@pDTA_INI VARCHAR(30),
	@pDTA_FIM VARCHAR(30),
	@pDIASEMANA VARCHAR(1),
	@pHORA VARCHAR(5),
	@pTEMPOPERMANENCIA VARCHAR(9),
	@pCOD_SEGMENTACAO VARCHAR(20)
)
AS
/*
--> Para filtar o Dia das semana passar no 5º parâmetro os valores: 1 = DOM , 2 = SEG, 3 = TER, 4 = QUAR, 5 = QUI, 6 = SEX, 7 = SAB
--> Para filtrar poo tempo de permanência, passar os valor: ATE_1H, 1H_2H, 2H_3H, 3H_4H, ACIMA_4H

--> Gráfico para cada dia da semana
EXEC SPDM_DB_FREQ_ESTACIONAMENTO 'DIASEMANA', 1, '2000-01-01','2016-12-31','','','',''

--> Grafico para Hora do dia, às segundas.
EXEC SPDM_DB_FREQ_ESTACIONAMENTO 'HORA', 1, '2000-01-01','2016-12-31','2','','',''

--> Média de permanência, aos sábados, às 15hs, com tempo de permanência de 2 a 3 horas.
EXEC SPDM_DB_FREQ_ESTACIONAMENTO 'MEDIA_PERMANENCIA', 1, '2000-01-01','2016-12-31','','','',''

--> Clientes por tempo de permanência, às quintas, ao meio dia.
EXEC SPDM_DB_FREQ_ESTACIONAMENTO 'TEMPO_PERMANENCIA', 1, '2011-01-01','2016-12-31','5','12:00','',''
*/
BEGIN
DECLARE
	@vQUERY VARCHAR(8000), @vWHERE VARCHAR(4000), @vFROM VARCHAR(1000), @vSQL_SEGMENTACAO VARCHAR(8000)

SELECT @vQUERY = ''

SELECT @vFROM = '
FROM
	CARTAOESTACIONAMENTO CE
	INNER JOIN TIPOCARTAOESTACIONAMENTO TCE ON (TCE.COD_TIPOCARTAO = CE.COD_TIPOCARTAO)
	INNER JOIN PESSOA_CARTAOESTACIONAMENTO PCE ON (PCE.COD_CARTAO = CE.COD_CARTAO)
	INNER JOIN FREQUENCIAESTACIONAMENTO FE ON (FE.COD_CARTAO = CE.COD_CARTAO AND FE.TMP_PERMANENCIA >= 0)'

-- Filtro por empreendimento (obrigatório).
SELECT @vWHERE = ' AND TCE.COD_EMPREENDIMENTO = '+CONVERT(VARCHAR,@pCOD_EMPREENDIMENTO)

-- Filtro por data na frequencia (data de entrada no estacionamento)
SELECT @vWHERE = @vWHERE+' AND FE.DTA_ENTRADA >= CONVERT(DATETIME,'''+@pDTA_INI+' 00:00:00'',121) AND FE.DTA_ENTRADA <= CONVERT(DATETIME,'''+@pDTA_FIM+' 23:59:59'',121)';

-- Filtro por dia da semana
IF @pDIASEMANA <> ''
	SELECT @vWHERE = @vWHERE+' AND DATEPART(DW,FE.DTA_ENTRADA) = '+@pDIASEMANA

-- Filtro por hora.
IF @pHORA <> ''
	SELECT @vWHERE = @vWHERE+' AND DATEPART(HH,FE.DTA_ENTRADA) = '+substring(@pHORA,1,2)

-- Filtro por tempo de permanência.
IF @pTEMPOPERMANENCIA = 'ATE_1H'
	SELECT @vWHERE = @vWHERE+' AND FE.TMP_PERMANENCIA/3600000 = 0'
ELSE IF @pTEMPOPERMANENCIA = '1H_2H'
	SELECT @vWHERE = @vWHERE+' AND FE.TMP_PERMANENCIA/3600000 = 1'
ELSE IF @pTEMPOPERMANENCIA = '2H_3H'
	SELECT @vWHERE = @vWHERE+' AND FE.TMP_PERMANENCIA/3600000 = 2'
ELSE IF @pTEMPOPERMANENCIA = '3H_4H'
	SELECT @vWHERE = @vWHERE+' AND FE.TMP_PERMANENCIA/3600000 = 3'
ELSE IF @pTEMPOPERMANENCIA = 'ACIMA_4H'
	SELECT @vWHERE = @vWHERE+' AND FE.TMP_PERMANENCIA/3600000 >= 4'

-- Filtro por segmentação
IF @pCOD_SEGMENTACAO <> ''
BEGIN
	SELECT @vSQL_SEGMENTACAO = REPLACE(CONVERT(VARCHAR(8000),SQL_SEGMENTACAO),'COUNT( DISTINCT PESSOAFISICA.COD_PESSOA ) 	 AS "QTD_ROWS"','DISTINCT PESSOAFISICA.COD_PESSOA')
	FROM SEGMENTACAO 
	WHERE COD_SEGMENTACAO = @pCOD_SEGMENTACAO;
	SELECT @vWHERE = @vWHERE+' AND PCE.COD_PESSOA IN ('+@vSQL_SEGMENTACAO+')';
END

-- Gráfico em pizza ou barras, para cada dia da semana qual a média de frequência
IF @pSECAO = 'DIASEMANA'
SELECT @vQUERY = 'SELECT
	CASE DATEPART(DW,DTA_ENTRADA) WHEN 1 THEN ''Domingo'' WHEN 2 THEN ''Segunda'' WHEN 3 THEN ''Terça'' WHEN 4 THEN ''Quarta'' WHEN 5 THEN ''Quinta''
	WHEN 6 THEN ''Sexta'' WHEN 7 THEN ''Sábado'' END AS "DIA_SEMANA", COUNT(PCE.COD_PESSOA) AS "QTDE"'+
	@vFROM+@vWHERE+
' GROUP BY
	DATEPART(DW,DTA_ENTRADA)
ORDER BY
	DATEPART(DW,DTA_ENTRADA)';

-- GRÁFICO MÉDIA DE FREQUENCIA POR HORA
IF @pSECAO = 'HORA'
SELECT @vQUERY = 'SELECT
	CASE DTA_ENTRADA WHEN 0 THEN ''00:00'' WHEN 1 THEN ''01:00'' WHEN 2 THEN ''02:00'' WHEN 3 THEN ''03:00'' WHEN 4 THEN ''04:00'' WHEN 5 THEN ''05:00'' WHEN 6 THEN ''06:00''
	WHEN 7 THEN ''07:00'' WHEN 8 THEN ''08:00'' WHEN 9 THEN ''09:00'' WHEN 10 THEN ''10:00'' WHEN 11 THEN ''11:00'' WHEN 12 THEN ''12:00'' WHEN 13 THEN ''13:00'' 
	WHEN 14 THEN ''14:00'' WHEN 15 THEN ''15:00'' WHEN 16 THEN ''16:00'' WHEN 17 THEN ''17:00'' WHEN 18 THEN ''18:00'' WHEN 19 THEN ''19:00'' WHEN 20 THEN ''20:00'' 
	WHEN 21 THEN ''21:00'' WHEN 22 THEN ''22:00'' WHEN 23 THEN ''23:00'' END AS "HORA",COUNT(*)'+
	@vFROM+@vWHERE+
' GROUP BY
	DTA_ENTRADA
ORDER BY
	DTA_ENTRADA'

-- MÉDIA DE PERMANÊNCIA
IF @pSECAO = 'MEDIA_PERMANENCIA'
	SELECT @vQUERY = 'SELECT left(dbo.func_RETORNATEMPO(SUM(CONVERT(NUMERIC,DATEDIFF(SECOND,DTA_ENTRADA,DTA_SAIDA)))/count(*)),5),
		Count(DISTINCT PCE.COD_PESSOA) AS "TOTAL_CLIENTES" '+@vFROM+@vWHERE

-- CLIENTES POR TEMPO DE PERMANÊNCIA
IF @pSECAO = 'TEMPO_PERMANENCIA'
SELECT @vQUERY = 'SELECT 
	CASE
		WHEN FE.TMP_PERMANENCIA/3600000 = 0 THEN ''ATE_1H''
	    WHEN FE.TMP_PERMANENCIA/3600000 = 1 THEN ''1H_2H''
		WHEN FE.TMP_PERMANENCIA/3600000 = 2 THEN ''2H_3H''
		WHEN FE.TMP_PERMANENCIA/3600000 = 3 THEN ''3H_4H''
		WHEN FE.TMP_PERMANENCIA/3600000 >= 4 THEN ''ACIMA_4H''
	END AS "TEMPO",
	COUNT(*) AS "QTDE"'+
	@vFROM+@vWHERE+
'GROUP BY
	CASE
		WHEN FE.TMP_PERMANENCIA/3600000 = 0 THEN ''ATE_1H''
	    WHEN FE.TMP_PERMANENCIA/3600000 = 1 THEN ''1H_2H''
		WHEN FE.TMP_PERMANENCIA/3600000 = 2 THEN ''2H_3H''
		WHEN FE.TMP_PERMANENCIA/3600000 = 3 THEN ''3H_4H''
		WHEN FE.TMP_PERMANENCIA/3600000 >= 4 THEN ''ACIMA_4H''
	END
ORDER BY 2 DESC'

EXEC(@vQUERY)
PRINT(@vQUERY)
END
GO
----------------------------------------------------------------------------------------------------------------
-- FIM - Fabricio - WISEIT-3798 Dashboard Estacionamento - não está incluindo a data "até"
----------------------------------------------------------------------------------------------------------------

EXEC SPDM_CONTROLEVERSAO 'BD_VERSAO_DASHBOARD_FREQUENCIAESTACIONAMENTO', '10.0.9';
GO


------------------------------------------------------------------------------------------------------------------------------------------------------
-- 10.0.10 --------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------------------------------------------
-- INICIO - Fabricio - WISEIT-3889 Dashboards - acrescentar botão de segmentação
-- INICIO - Fabricio - WISEIT-3954 Dashboards - botão de salvar segmentação não tem opção de salvar o ranking e a segmentação não mostra o total
-- INICIO - FABRICIO - WISEIT-4367 - Banco - Estacionamento - API para receber frequência
----------------------------------------------------------------------------------------------------------------------------------------
IF EXISTS(SELECT '' FROM SYSOBJECTS WHERE XTYPE = 'P' AND NAME = 'SPDM_DB_FREQ_ESTACIONAMENTO')
  DROP PROCEDURE SPDM_DB_FREQ_ESTACIONAMENTO
GO
CREATE PROCEDURE SPDM_DB_FREQ_ESTACIONAMENTO
(
	@pSECAO VARCHAR(20),
	@pCOD_EMPREENDIMENTO INT, 
	@pDTA_INI VARCHAR(30),
	@pDTA_FIM VARCHAR(30),
	@pDIASEMANA VARCHAR(1),
	@pHORA VARCHAR(5),
	@pTEMPOPERMANENCIA VARCHAR(9),
	@pCOD_SEGMENTACAO VARCHAR(20),
	@pNME_SEGMENTACAO VARCHAR(100),
	@pCOD_VISIBILIDADE VARCHAR(2), -- 'PA', 'PC', 'PR'
	@pCOD_USUARIO VARCHAR(20)
)
AS
/*
--> Para filtar o Dia das semana passar no 5º parâmetro os valores: 1 = DOM , 2 = SEG, 3 = TER, 4 = QUAR, 5 = QUI, 6 = SEX, 7 = SAB
--> Para filtrar poo tempo de permanência, passar os valor: ATE_1H, 1H_2H, 2H_3H, 3H_4H, ACIMA_4H

--> Gravar segmentação
EXEC SPDM_DB_FREQ_ESTACIONAMENTO 'SEGMENTACAO', 1, '2011-01-01','2011-01-31','','','','','SEG TESTE','PA','1'

--> Gráfico para cada dia da semana
EXEC SPDM_DB_FREQ_ESTACIONAMENTO 'DIASEMANA', 1, '2011-01-01','2018-12-31','','','','','','',''

--> Grafico para Hora do dia, às segundas.
EXEC SPDM_DB_FREQ_ESTACIONAMENTO 'HORA', 1, '2000-01-01','2016-12-31','2','','',''

--> Média de permanência, aos sábados, às 15hs, com tempo de permanência de 2 a 3 horas.
EXEC SPDM_DB_FREQ_ESTACIONAMENTO 'MEDIA_PERMANENCIA', 1, '2000-01-01','2016-12-31','','','',''

--> Clientes por tempo de permanência, às quintas, ao meio dia.
EXEC SPDM_DB_FREQ_ESTACIONAMENTO 'TEMPO_PERMANENCIA', 1, '2011-01-01','2016-12-31','5','12:00','',''
*/
BEGIN
DECLARE
	@vQUERY VARCHAR(8000), @vWHERE VARCHAR(4000), @vFROM VARCHAR(1000), @vSQL_SEGMENTACAO VARCHAR(8000),
	@vCOD_CONTEXTO INT, @vCOD_VISIBILIDADE VARCHAR(2), @vDSC_SEGMENTACAO VARCHAR(8000), @vCOD_SEGMENTACAO INT

SELECT @vQUERY = '';

SELECT @vFROM = '
FROM
	FREQUENCIAESTACIONAMENTO FE'; 

SELECT @vWHERE = '
WHERE
	FE.TMP_PERMANENCIA >= 0 AND FE.COD_PESSOA > 0 AND FE.COD_EMPREENDIMENTO = '+CONVERT(VARCHAR,@pCOD_EMPREENDIMENTO)

-- Filtro por data na frequencia (data de entrada no estacionamento)
SELECT @vWHERE = @vWHERE+' AND FE.DTA_ENTRADA >= CONVERT(DATETIME,'''+@pDTA_INI+' 00:00:00'',121) AND FE.DTA_ENTRADA <= CONVERT(DATETIME,'''+@pDTA_FIM+' 23:59:59'',121)';

-- Filtro por dia da semana
IF @pDIASEMANA <> ''
	SELECT @vWHERE = @vWHERE+' AND DATEPART(DW,FE.DTA_ENTRADA) = '+@pDIASEMANA

-- Filtro por hora.
IF @pHORA <> ''
	SELECT @vWHERE = @vWHERE+' AND DATEPART(HH,FE.DTA_ENTRADA) = '+substring(@pHORA,1,2)

-- Filtro por tempo de permanência.
IF @pTEMPOPERMANENCIA = 'ATE_1H'
	SELECT @vWHERE = @vWHERE+' AND FE.TMP_PERMANENCIA/3600000 = 0'
ELSE IF @pTEMPOPERMANENCIA = '1H_2H'
	SELECT @vWHERE = @vWHERE+' AND FE.TMP_PERMANENCIA/3600000 = 1'
ELSE IF @pTEMPOPERMANENCIA = '2H_3H'
	SELECT @vWHERE = @vWHERE+' AND FE.TMP_PERMANENCIA/3600000 = 2'
ELSE IF @pTEMPOPERMANENCIA = '3H_4H'
	SELECT @vWHERE = @vWHERE+' AND FE.TMP_PERMANENCIA/3600000 = 3'
ELSE IF @pTEMPOPERMANENCIA = 'ACIMA_4H'
	SELECT @vWHERE = @vWHERE+' AND FE.TMP_PERMANENCIA/3600000 >= 4'

-- Filtro por segmentação
IF @pCOD_SEGMENTACAO <> ''
BEGIN
	SELECT @vSQL_SEGMENTACAO = REPLACE(CONVERT(VARCHAR(8000),SQL_SEGMENTACAO),'COUNT( DISTINCT PESSOAFISICA.COD_PESSOA ) 	 AS "QTD_ROWS"','DISTINCT PESSOAFISICA.COD_PESSOA')
	FROM SEGMENTACAO 
	WHERE COD_SEGMENTACAO = @pCOD_SEGMENTACAO;
	SELECT @vWHERE = @vWHERE+' AND FE.COD_PESSOA IN ('+@vSQL_SEGMENTACAO+')';
END

-- Gráfico em pizza ou barras, para cada dia da semana qual a média de frequência
IF @pSECAO = 'DIASEMANA'
SELECT @vQUERY = 'SELECT
	CASE DATEPART(DW,DTA_ENTRADA) WHEN 1 THEN ''Domingo'' WHEN 2 THEN ''Segunda'' WHEN 3 THEN ''Terça'' WHEN 4 THEN ''Quarta'' WHEN 5 THEN ''Quinta''
	WHEN 6 THEN ''Sexta'' WHEN 7 THEN ''Sábado'' END AS "DIA_SEMANA", COUNT(FE.COD_PESSOA) AS "QTDE"'+
	@vFROM+@vWHERE+
' GROUP BY
	DATEPART(DW,DTA_ENTRADA)
ORDER BY
	DATEPART(DW,DTA_ENTRADA)';

-- GRÁFICO MÉDIA DE FREQUENCIA POR HORA
IF @pSECAO = 'HORA'
SELECT @vQUERY = 'SELECT
	CASE DTA_ENTRADA WHEN 0 THEN ''00:00'' WHEN 1 THEN ''01:00'' WHEN 2 THEN ''02:00'' WHEN 3 THEN ''03:00'' WHEN 4 THEN ''04:00'' WHEN 5 THEN ''05:00'' WHEN 6 THEN ''06:00''
	WHEN 7 THEN ''07:00'' WHEN 8 THEN ''08:00'' WHEN 9 THEN ''09:00'' WHEN 10 THEN ''10:00'' WHEN 11 THEN ''11:00'' WHEN 12 THEN ''12:00'' WHEN 13 THEN ''13:00'' 
	WHEN 14 THEN ''14:00'' WHEN 15 THEN ''15:00'' WHEN 16 THEN ''16:00'' WHEN 17 THEN ''17:00'' WHEN 18 THEN ''18:00'' WHEN 19 THEN ''19:00'' WHEN 20 THEN ''20:00'' 
	WHEN 21 THEN ''21:00'' WHEN 22 THEN ''22:00'' WHEN 23 THEN ''23:00'' END AS "HORA",COUNT(*)'+
	@vFROM+@vWHERE+
' GROUP BY
	DTA_ENTRADA
ORDER BY
	DTA_ENTRADA'

-- MÉDIA DE PERMANÊNCIA
IF @pSECAO = 'MEDIA_PERMANENCIA'
	SELECT @vQUERY = 'SELECT left(dbo.func_RETORNATEMPO(SUM(CONVERT(NUMERIC,DATEDIFF(SECOND,DTA_ENTRADA,DTA_SAIDA)))/count(*)),5),
		Count(DISTINCT FE.COD_PESSOA) AS "TOTAL_CLIENTES" '+@vFROM+@vWHERE

-- CLIENTES POR TEMPO DE PERMANÊNCIA
IF @pSECAO = 'TEMPO_PERMANENCIA'
SELECT @vQUERY = 'SELECT 
	CASE
		WHEN FE.TMP_PERMANENCIA/3600000 = 0 THEN ''ATE_1H''
	    WHEN FE.TMP_PERMANENCIA/3600000 = 1 THEN ''1H_2H''
		WHEN FE.TMP_PERMANENCIA/3600000 = 2 THEN ''2H_3H''
		WHEN FE.TMP_PERMANENCIA/3600000 = 3 THEN ''3H_4H''
		WHEN FE.TMP_PERMANENCIA/3600000 >= 4 THEN ''ACIMA_4H''
	END AS "TEMPO",
	COUNT(*) AS "QTDE"'+
	@vFROM+@vWHERE+
'GROUP BY
	CASE
		WHEN FE.TMP_PERMANENCIA/3600000 = 0 THEN ''ATE_1H''
	    WHEN FE.TMP_PERMANENCIA/3600000 = 1 THEN ''1H_2H''
		WHEN FE.TMP_PERMANENCIA/3600000 = 2 THEN ''2H_3H''
		WHEN FE.TMP_PERMANENCIA/3600000 = 3 THEN ''3H_4H''
		WHEN FE.TMP_PERMANENCIA/3600000 >= 4 THEN ''ACIMA_4H''
	END
ORDER BY 2 DESC'

-- Segmentação
SELECT @vCOD_CONTEXTO = COD_CONTEXTO FROM CONTEXTO WHERE NME_CONTEXTO = 'CLIENTE' AND FLG_ATIVO = 1;
IF @pSECAO = 'SEGMENTACAO' AND ISNULL(@pNME_SEGMENTACAO,'') <> '' AND @vCOD_CONTEXTO > 0
BEGIN
	IF ISNULL(@pCOD_VISIBILIDADE,' ') = ' '
		SELECT @vCOD_VISIBILIDADE = 'PA'
	ELSE
		SELECT @vCOD_VISIBILIDADE = @pCOD_VISIBILIDADE

	SELECT @vQUERY = 'SELECT DISTINCT FE.COD_PESSOA'

	EXEC SPDM_GETNEXTID 'SEGMENTACAO','COD_SEGMENTACAO',@vCOD_SEGMENTACAO OUTPUT
	INSERT INTO SEGMENTACAO(COD_SEGMENTACAO,COD_CONTEXTO,NME_SEGMENTACAO,DSC_SEGMENTACAO,SQL_SEGMENTACAO,COD_USUARIOCADASTRO,DTA_CADASTRO,
		FLG_AUTOMATICA,COD_EMPREENDIMENTO,COD_VISIBILIDADE,FLG_WIZARD)
	VALUES(@vCOD_SEGMENTACAO, @vCOD_CONTEXTO, @pNME_SEGMENTACAO, @vDSC_SEGMENTACAO, @vQUERY+' '+@vFROM+' '+@vWHERE, @pCOD_USUARIO, GETDATE(), 
		0, @pCOD_EMPREENDIMENTO, @vCOD_VISIBILIDADE, 0)	;

	EXEC ('INSERT INTO SEGMENTACAORESULTADO(COD_RESULTADO,COD_SEGMENTACAO) '+@vQUERY+','+@vCOD_SEGMENTACAO+' '+@vFROM+' '+@vWHERE)

	-- Grava a quantidade de clientes na segmentação salva
	UPDATE
		SEGMENTACAO 
	SET
		NUM_QUANTIDADE = (SELECT COUNT(*) FROM SEGMENTACAORESULTADO WHERE COD_SEGMENTACAO = @vCOD_SEGMENTACAO) 
	WHERE
		COD_SEGMENTACAO = @vCOD_SEGMENTACAO;

	SELECT @vQUERY = 'SELECT '+CONVERT(VARCHAR,@vCOD_SEGMENTACAO)+' AS "COD_SEGMENTACAO"'
END

PRINT(@vQUERY)
EXEC(@vQUERY)

END
GO
---------------------------------------------------------------------------------------------------------------------------------------
-- FIM - Fabricio - WISEIT-3889 Dashboards - acrescentar botão de segmentação
-- FIM - Fabricio - WISEIT-3954 Dashboards - botão de salvar segmentação não tem opção de salvar o ranking e a segmentação não mostra o total
-- FIM - FABRICIO - WISEIT-4367 - Banco - Estacionamento - API para receber frequência
----------------------------------------------------------------------------------------------------------------------------------------

EXEC SPDM_CONTROLEVERSAO 'BD_VERSAO_DASHBOARD_FREQUENCIAESTACIONAMENTO', '10.0.10';
GO


------------------------------------------------------------------------------------------------------------------------------------------------------
-- 10.0.11 --------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- INICIO - JOELSON - WISEIT-4805 / WISEIT-4864 Dashboard Estacionamento - padronizar dia de semana e hora, colocar mapa de dia x hora, tabela de clientes
-- INICIO - Fabricio - WISEIT-4826 Dashboard Clientes - poder analisar sem filtro de datas e abrir a partir de outros dashboards - WISEIT-5029 Dashboar Clientes - Procedure
-- INICIO - Fabricio - WISEIT-1468/WISEIT-5048 Erro ao utilizar segmentação no contexto de clientes e atributo consumo no dashboard de RFV
-- INICIO - Fabricio - WISEIT-1468/WISEIT-5339 Dashboards - gravar segmentação pelo dashboard em caixa alta
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
IF EXISTS(SELECT '' FROM SYSOBJECTS WHERE XTYPE = 'V' AND NAME = 'VWDM_NUM_DIASEMANA')
	DROP VIEW VWDM_NUM_DIASEMANA
GO

CREATE VIEW VWDM_NUM_DIASEMANA
AS
	SELECT 1 AS NUM_DIASEMANA UNION ALL
	SELECT 2 UNION ALL
	SELECT 3 UNION ALL
	SELECT 4 UNION ALL
	SELECT 5 UNION ALL
	SELECT 6 UNION ALL
	SELECT 7;
GO

IF EXISTS(SELECT '' FROM SYSOBJECTS WHERE XTYPE = 'P' AND NAME = 'SPDM_DB_FREQ_ESTACIONAMENTO')
  DROP PROCEDURE SPDM_DB_FREQ_ESTACIONAMENTO
GO
CREATE PROCEDURE SPDM_DB_FREQ_ESTACIONAMENTO
(
	@pSECAO VARCHAR(100),
	@pCOD_EMPREENDIMENTO VARCHAR(20), 
	@pDTA_INI VARCHAR(30),
	@pDTA_FIM VARCHAR(30),
	@pNUM_DIASEMANA VARCHAR(1),
	@pHORA VARCHAR(5),
	@pTEMPOPERMANENCIA VARCHAR(9),
	@pCOD_SEGMENTACAO VARCHAR(20),
	@pNME_SEGMENTACAO VARCHAR(100),
	@pCOD_VISIBILIDADE VARCHAR(2), -- 'PA', 'PC', 'PR'
	@pCOD_USUARIO VARCHAR(20),
	@pTOP_CLIENTE VARCHAR (100),
	@pCOD_PESSOA VARCHAR(100)
)
AS
/*
--> Para filtar o Dia das semana passar no 5º parâmetro os valores: 1 = DOM , 2 = SEG, 3 = TER, 4 = QUAR, 5 = QUI, 6 = SEX, 7 = SAB
--> Para filtrar poo tempo de permanência, passar os valor: ATE_1H, 1H_2H, 2H_3H, 3H_4H, ACIMA_4H

--> Gravar segmentação
EXEC SPDM_DB_FREQ_ESTACIONAMENTO 'SEGMENTACAO', 1, '2011-01-01','2011-01-31','','','','','SEG TESTE','PA','1'

--> Gráfico para cada dia da semana
EXEC SPDM_DB_FREQ_ESTACIONAMENTO 'DIASEMANA', 30, '2018-01-01','2018-02-10','','','','','','','','',''

-->Quantidade de clientes/frequência 
EXEC SPDM_DB_FREQ_ESTACIONAMENTO 'CLIENTES_FREQUENCIA', 30, '2018-01-15','2018-02-19','','','','','','','','',''

-->Grafico para a quantidade de clientes/frequencia
EXEC SPDM_DB_FREQ_ESTACIONAMENTO 'GRAFICO', 30, '2018-01-01','2018-01-10','','','','','','','','',''

--> Tabela com os top 100 clientes por frequência/data último acesso.
Basta passar no 12° parametro a quantidade que deve ser retornada.
EXEC SPDM_DB_FREQ_ESTACIONAMENTO 'CLIENTES', 30, '2018-01-01','2018-01-10','','','','','','','','100',''

--> Subtabela de clientes - detalhe de cada frequência com data e hora da entrada, cancela, data e hora da saída, cancela, tempo permanência, valor pago. 
EXEC SPDM_DB_FREQ_ESTACIONAMENTO 'TAB_CLIENTE_FREQUENCIA', 30, '2018-01-15','2018-02-19','','','','','','','','','37957'

SELECT * FROM EMPREENDIMENTO
--> Grafico para Hora do dia, às segundas.
EXEC SPDM_DB_FREQ_ESTACIONAMENTO 'HORA', 1, '2000-01-01','2016-12-31','2','','',''

--> Média de permanência, aos sábados, às 15hs, com tempo de permanência de 2 a 3 horas.
EXEC SPDM_DB_FREQ_ESTACIONAMENTO 'MEDIA_PERMANENCIA', 1, '2000-01-01','2016-12-31','','','',''

--> Clientes por tempo de permanência, às quintas, ao meio dia.
EXEC SPDM_DB_FREQ_ESTACIONAMENTO 'TEMPO_PERMANENCIA', 30, '2018-01-15','2018-02-19','','','','','','','','',''
*/
BEGIN
DECLARE
	@vQUERY VARCHAR(8000), @vWHERE VARCHAR(4000), @vFROM VARCHAR(1000), @vSQL_SEGMENTACAO VARCHAR(8000),
	@vCOD_CONTEXTO INT, @vCOD_VISIBILIDADE VARCHAR(2), @vDSC_SEGMENTACAO VARCHAR(8000), @vCOD_SEGMENTACAO INT,
	@vTOP_CLIENTE VARCHAR (100),@vID VARCHAR(1000),@vDATA1 DATETIME, @vDATA2 DATETIME

SELECT @vQUERY = '';

SELECT @vFROM = '
FROM
	FREQUENCIAESTACIONAMENTO FE'; 

SELECT @vWHERE = '
WHERE
	FE.TMP_PERMANENCIA >= 0 AND FE.COD_PESSOA > 0 AND FE.COD_EMPREENDIMENTO = '+@pCOD_EMPREENDIMENTO

-- Filtro por data na frequencia (data de entrada no estacionamento)
SELECT @vWHERE = @vWHERE+' AND FE.DTA_ENTRADA >= CONVERT(DATETIME,'''+@pDTA_INI+' 00:00:00'',121) AND FE.DTA_ENTRADA <= CONVERT(DATETIME,'''+@pDTA_FIM+' 23:59:59'',121)';

-- Filtro por dia da semana
IF @pNUM_DIASEMANA <> ''
	SELECT @vWHERE = @vWHERE+' AND DATEPART(DW,FE.DTA_ENTRADA) = '+@pNUM_DIASEMANA

-- Filtro por hora.
IF @pHORA <> ''
	SELECT @vWHERE = @vWHERE+' AND DATEPART(HH,FE.DTA_ENTRADA) = '+substring(@pHORA,1,2)

-- Filtro por tempo de permanência.
IF @pTEMPOPERMANENCIA = 'ATE_1H'
	SELECT @vWHERE = @vWHERE+' AND FE.TMP_PERMANENCIA/3600000 = 0'
ELSE IF @pTEMPOPERMANENCIA = '1H_2H'
	SELECT @vWHERE = @vWHERE+' AND FE.TMP_PERMANENCIA/3600000 = 1'
ELSE IF @pTEMPOPERMANENCIA = '2H_3H'
	SELECT @vWHERE = @vWHERE+' AND FE.TMP_PERMANENCIA/3600000 = 2'
ELSE IF @pTEMPOPERMANENCIA = '3H_4H'
	SELECT @vWHERE = @vWHERE+' AND FE.TMP_PERMANENCIA/3600000 = 3'
ELSE IF @pTEMPOPERMANENCIA = 'ACIMA_4H'
	SELECT @vWHERE = @vWHERE+' AND FE.TMP_PERMANENCIA/3600000 >= 4'

-- Filtro por segmentação
IF @pCOD_SEGMENTACAO <> ''
BEGIN
	SELECT @vSQL_SEGMENTACAO = REPLACE(CONVERT(VARCHAR(8000),SQL_SEGMENTACAO),'COUNT( DISTINCT PESSOAFISICA.COD_PESSOA ) 	 AS "QTD_ROWS"','DISTINCT PESSOAFISICA.COD_PESSOA')
	FROM SEGMENTACAO 
	WHERE COD_SEGMENTACAO = @pCOD_SEGMENTACAO;
	SELECT @vWHERE = @vWHERE+' AND FE.COD_PESSOA IN ('+@vSQL_SEGMENTACAO+')';
END

-- Gráfico em pizza ou barras, para cada dia da semana qual a média de frequência
IF @pSECAO = 'DIASEMANA'
SELECT @vQUERY = '
	SELECT
    XX.NUM_DIASEMANA,
    DBO.FUNC_RETORNADIASEMANA2(XX.NUM_DIASEMANA,2) AS "DIA_SEMANA", 
    ISNULL(XX.QUANTIDADE,0) AS "TOTAL", 
	ISNULL(XX.QUANTIDADE,0) AS "TOTAL_BARRA",
    ISNULL(XX.MEDIA,0) AS "MEDIA", 
	ISNULL(XX.MEDIA,0) AS "BARRA_MEDIA", 
    ISNULL(XX.PORCENTAGEM,0) AS "PORCENTAGEM" 
  FROM
  (
  SELECT
    V.NUM_DIASEMANA,   
    ISNULL(Z.QUANTIDADE,0) AS "QUANTIDADE", 
    ISNULL(Z.MEDIA,0) AS "MEDIA",  
    ISNULL(Z.PORCENTAGEM,0) AS "PORCENTAGEM" 
  FROM
    VWDM_NUM_DIASEMANA V
    LEFT OUTER JOIN
    (
  SELECT
    X.NUM_DIASEMANA,X.QUANTIDADE,
    CASE
      WHEN dbo.FUNC_QTD_DIA_SEMANA_PERIODO(X.NUM_DIASEMANA,CONVERT(DATETIME,'''+@pDTA_INI+' 00:00:00'',121),CONVERT(DATETIME,'''+@pDTA_FIM+' 00:00:00'',121)) > 0
      THEN CAST(CAST(X.QUANTIDADE*1.0 AS NUMERIC(10,2))/dbo.FUNC_QTD_DIA_SEMANA_PERIODO(X.NUM_DIASEMANA,CONVERT(DATETIME,'''+@pDTA_INI+' 00:00:00'',121),CONVERT(DATETIME,'''+@pDTA_FIM+' 00:00:00'',121)) AS NUMERIC(10,2))
     ELSE 0 END AS "MEDIA",
	 CAST((X.QUANTIDADE*1.0/Y.QUANTIDADE)*100 AS NUMERIC(10,2)) AS "PORCENTAGEM"

    FROM
       (   
	       SELECT
		    DATEPART(DW,FE.DTA_ENTRADA) AS "NUM_DIASEMANA",
		    DBO.FUNC_RETORNADIASEMANA(FE.DTA_ENTRADA,2) AS "DIA_SEMANA",
			COUNT(DISTINCT FE.COD_PESSOA) AS "QUANTIDADE"'+
			@vFROM+@vWHERE+
			
			'GROUP BY
			DATEPART(DW,FE.DTA_ENTRADA), DBO.FUNC_RETORNADIASEMANA(FE.DTA_ENTRADA,2)
  ) X
  CROSS JOIN
	(
	SELECT
	COUNT(DISTINCT FE.COD_PESSOA) AS "QUANTIDADE"'+
	@vFROM+@vWHERE+
    ')Y
    ) Z ON Z.NUM_DIASEMANA = V.NUM_DIASEMANA
  ) XX    
  ORDER BY
    CASE XX.NUM_DIASEMANA WHEN 2 THEN 1 WHEN 1 THEN 8 ELSE XX.NUM_DIASEMANA END';

	

-- GRÁFICO MÉDIA DE FREQUENCIA POR HORA
IF @pSECAO = 'HORA'
SELECT @vQUERY = 'SELECT
   HORA_PERIODO.HORA, isnull(XX.QUANTIDADE,0) AS "QUANTIDADE", isnull(XX.MEDIA,0) AS "MEDIA"
  FROM
  (
  SELECT 0 AS "NUM_HORA",
  ''00:00'' AS "HORA" UNION ALL
  SELECT 1,''01:00'' UNION ALL
  SELECT 2,''02:00'' UNION ALL
  SELECT 3,''03:00'' UNION ALL
  SELECT 4,''04:00''UNION ALL
  SELECT 5,''05:00'' UNION ALL
  SELECT 6,''06:00'' UNION ALL
  SELECT 7,''07:00'' UNION ALL
  SELECT 8,''08:00'' UNION ALL
  SELECT 9,''09:00'' UNION ALL
  SELECT 10,''10:00''UNION ALL
  SELECT 11,''11:00''UNION ALL
  SELECT 12,''12:00''UNION ALL
  SELECT 13,''13:00''UNION ALL
  SELECT 14,''14:00''UNION ALL
  SELECT 15,''15:00''UNION ALL
  SELECT 16,''16:00''UNION ALL
  SELECT 17,''17:00''UNION ALL
  SELECT 18,''18:00''UNION ALL
  SELECT 19,''19:00''UNION ALL
  SELECT 20,''20:00''UNION ALL
  SELECT 21,''21:00''UNION ALL
  SELECT 22,''22:00''UNION ALL
  SELECT 23,''23:00'' 
  ) HORA_PERIODO
  LEFT OUTER JOIN
  (
  SELECT
    X.HORA, X.QUANTIDADE,
    CASE
      WHEN DATEDIFF(DAY,CONVERT(DATETIME,'''+@pDTA_INI+' 00:00:00'',121),CONVERT(DATETIME,'''+@pDTA_FIM+' 00:00:00'',121)) > 0 
      THEN CAST(CAST(X.QUANTIDADE*1.0 AS NUMERIC(10,2))/DATEDIFF(DAY,CONVERT(DATETIME,'''+@pDTA_INI+' 00:00:00'',121),CONVERT(DATETIME,'''+@pDTA_FIM+' 00:00:00'',121)) AS NUMERIC(10,2))
	  WHEN DATEDIFF(DAY,CONVERT(DATETIME,'''+@pDTA_INI+' 00:00:00'',121),CONVERT(DATETIME,'''+@pDTA_FIM+' 00:00:00'',121)) = 0 
      THEN CAST(CAST(X.QUANTIDADE*1.0 AS NUMERIC(10,2))/DATEDIFF(DAY,CONVERT(DATETIME,'''+@pDTA_INI+' 00:00:00'',121),CONVERT(DATETIME,'''+@pDTA_FIM+' 00:00:00'',121)+1) AS NUMERIC(10,2))
      ELSE 0 END AS "MEDIA"

  FROM
  (

	SELECT
		CASE WHEN LEN(DATEPART(HOUR,FE.DTA_ENTRADA)) = 1 THEN ''0'' ELSE '''' END + CONVERT(VARCHAR(2),DATEPART(HOUR,FE.DTA_ENTRADA))+'':00'' AS "HORA",
		COUNT(FE.COD_PESSOA) AS "QUANTIDADE"'+
	@vFROM+@vWHERE+
'GROUP BY DATEPART(HOUR,FE.DTA_ENTRADA) 
) X
) XX ON (XX.HORA = HORA_PERIODO.HORA)
  ORDER BY
  HORA_PERIODO.HORA'

-- MÉDIA DE PERMANÊNCIA
IF @pSECAO = 'MEDIA_PERMANENCIA'
	SELECT @vQUERY = 'SELECT left(dbo.func_RETORNATEMPO(SUM(CONVERT(NUMERIC,DATEDIFF(SECOND,DTA_ENTRADA,DTA_SAIDA)))/count(*)),5),
		Count(DISTINCT FE.COD_PESSOA) AS "TOTAL_CLIENTES" '+@vFROM+@vWHERE

-- CLIENTES POR TEMPO DE PERMANÊNCIA
IF @pSECAO = 'TEMPO_PERMANENCIA'
SELECT @vQUERY = 'SELECT 
	CASE
		WHEN FE.TMP_PERMANENCIA/3600000 = 0 THEN ''ATE_1H''
	    WHEN FE.TMP_PERMANENCIA/3600000 = 1 THEN ''1H_2H''
		WHEN FE.TMP_PERMANENCIA/3600000 = 2 THEN ''2H_3H''
		WHEN FE.TMP_PERMANENCIA/3600000 = 3 THEN ''3H_4H''
		WHEN FE.TMP_PERMANENCIA/3600000 >= 4 THEN ''ACIMA_4H''
	END AS "TEMPO",
	COUNT(*) AS "QTDE"'+
	@vFROM+@vWHERE+
'GROUP BY
	CASE
		WHEN FE.TMP_PERMANENCIA/3600000 = 0 THEN ''ATE_1H''
	    WHEN FE.TMP_PERMANENCIA/3600000 = 1 THEN ''1H_2H''
		WHEN FE.TMP_PERMANENCIA/3600000 = 2 THEN ''2H_3H''
		WHEN FE.TMP_PERMANENCIA/3600000 = 3 THEN ''3H_4H''
		WHEN FE.TMP_PERMANENCIA/3600000 >= 4 THEN ''ACIMA_4H''
	END
ORDER BY 2 DESC'


IF @pSECAO = 'CLIENTES' 
	
SELECT @vQUERY = 'SELECT A.* FROM (  SELECT TOP '+@pTOP_CLIENTE+'
'''' AS RESPONSIVE,
PF.COD_PESSOA,
PF.NME_PESSOA,
PF.NUM_CPF,
CASE WHEN ISNULL(E.NME_BAIRRO,'' '') <> '' '' THEN E.NME_BAIRRO+'' - '' ELSE '''' END+ISNULL(E.NME_CIDADE,'' '') AS "CIDADE_BAIRRO",
COUNT(DISTINCT FE.COD_FREQUENCIA) AS "QUANTIDADE_FREQUENCIA",
Max(FE.DTA_ENTRADA) AS "DATA_ULTIMA_FREQUENCIA",
DBO.FUNC_RETORNATEMPO(SUM(FE.TMP_PERMANENCIA/1000)) AS "TEMPO_TOTAL",
DBO.FUNC_RETORNATEMPO(AVG(FE.TMP_PERMANENCIA/1000)) AS "MEDIA_TEMPO"'
+@vFROM+
' INNER JOIN PESSOAFISICA PF ON (PF.COD_PESSOA = FE.COD_PESSOA)
  LEFT OUTER JOIN PESSOA_PREFERENCIA PP ON (PP.COD_PESSOA = FE.COD_PESSOA AND PP.NUM_PREFERENCIATIPOCONTATO = 1 AND PP.COD_TIPOCONTATO = 1 AND PP.COD_EMPREENDIMENTO = '+@pCOD_EMPREENDIMENTO+')
  LEFT OUTER JOIN ENDERECO E ON E.COD_CONTATO = PP.COD_CONTATO
  AND ISNULL(E.NME_BAIRRO,'' '') <> '' ''
  AND ISNULL(E.NME_CIDADE,'' '') <> '' ''
'+@vWHERE+
'  GROUP BY
PF.COD_PESSOA,
PF.NME_PESSOA,
PF.NUM_CPF,
E.NME_BAIRRO,
E.NME_CIDADE
ORDER BY COUNT(FE.COD_PESSOA) DESC )
 A';

IF @pSECAO = 'TAB_CLIENTE_FREQUENCIA' 
SELECT @vQUERY ='SELECT
FE.DTA_ENTRADA,
ISNULL(CT.NME_CANCELA, '' '') AS "CANCELA_ENTRADA",
FE.DTA_SAIDA,
ISNULL(CT2.NME_CANCELA,'' '') AS "CANCELA_SAIDA",
DBO.FUNC_RETORNATEMPO(FE.TMP_PERMANENCIA/1000) AS "TEMPO_PERMANENCIA",
ISNULL(FE.VLR_PAGO,''0'') AS "VALOR_PAGO"'
+@vFROM+ 
' INNER JOIN PESSOAFISICA PF ON (PF.COD_PESSOA = FE.COD_PESSOA)
 LEFT OUTER JOIN CANCELAESTACIONAMENTO CT ON (CT.COD_CANCELA = FE.COD_CANCELAENTRADA)
 LEFT OUTER JOIN CANCELAESTACIONAMENTO CT2 ON (CT2.COD_CANCELA = FE.COD_CANCELASAIDA)'
+@vWHERE+'
AND FE.COD_PESSOA = '+@pCOD_PESSOA+'
ORDER BY FE.DTA_ENTRADA DESC';




-- CLIENTES / FREQUENCIA
IF @pSECAO = 'CLIENTES_FREQUENCIA'
SELECT @vQUERY = '
   SELECT
   VEZES_CLIENTE.NUMERO_VEZES, VEZES_CLIENTE.VEZES,ISNULL(XX.QUANTIDADE,0) AS "CLIENTES",ISNULL(XX.QUANTIDADE,0) AS "CLIENTES_BARRA"
  FROM
  (
  SELECT 1 AS "NUMERO_VEZES",''1 VEZ''AS "VEZES" FROM DUAL UNION ALL
  SELECT 2,''2 VEZES''UNION ALL
  SELECT 3,''3 VEZES''UNION ALL
  SELECT 4,''4 VEZES''UNION ALL
  SELECT 5,''5 VEZES''UNION ALL
  SELECT 6,''6 VEZES''UNION ALL
  SELECT 7,''7 VEZES''UNION ALL
  SELECT 8,''8 VEZES''UNION ALL
  SELECT 9,''9 VEZES''UNION ALL
  SELECT 10,''ACIMA DE 10 VEZES''
) VEZES_CLIENTE
  LEFT OUTER JOIN
  (
   SELECT
  CASE
  WHEN (X.QUANTIDADE) = 1 THEN ''1 VEZ''
  WHEN (X.QUANTIDADE) = 2 THEN ''2 VEZES''
  WHEN (X.QUANTIDADE) = 3 THEN ''3 VEZES''
  WHEN (X.QUANTIDADE) = 4 THEN ''4 VEZES''
  WHEN (X.QUANTIDADE) = 5 THEN ''5 VEZES''
  WHEN (X.QUANTIDADE) = 6 THEN ''6 VEZES''
  WHEN (X.QUANTIDADE) = 7 THEN ''7 VEZES''
  WHEN (X.QUANTIDADE) = 8 THEN ''8 VEZES''
  WHEN (X.QUANTIDADE) = 9 THEN ''9 VEZES''
  WHEN (X.QUANTIDADE) >= 10 THEN ''ACIMA DE 10 VEZES''
  END AS "VEZES",
  COUNT(*) AS "QUANTIDADE"
  FROM
  (

SELECT FE.COD_PESSOA , Count(*) AS "QUANTIDADE"
'+@vFROM+@vWHERE+
'GROUP BY FE.COD_PESSOA
) X
  GROUP BY
    CASE

WHEN (X.QUANTIDADE) = 1 THEN ''1 VEZ''
    WHEN (X.QUANTIDADE) = 2 THEN ''2 VEZES''
    WHEN (X.QUANTIDADE) = 3 THEN ''3 VEZES''
    WHEN (X.QUANTIDADE) = 4 THEN ''4 VEZES''
    WHEN (X.QUANTIDADE) = 5 THEN ''5 VEZES''
    WHEN (X.QUANTIDADE) = 6 THEN ''6 VEZES''
    WHEN (X.QUANTIDADE) = 7 THEN ''7 VEZES''
    WHEN (X.QUANTIDADE) = 8 THEN ''8 VEZES''
    WHEN (X.QUANTIDADE) = 9 THEN ''9 VEZES''
    WHEN (X.QUANTIDADE) >= 10 THEN''ACIMA DE 10 VEZES''
    END

 )  XX ON (XX.VEZES = VEZES_CLIENTE.VEZES)
   ORDER BY 1';
   
IF @pSECAO = 'GRAFICO'
BEGIN	
	SELECT @vID = @@SPID		
	SELECT @vDATA1 = CONVERT(DATETIME,@pDTA_INI+' 00:00:00',121);
	SELECT @vDATA2 = CONVERT(DATETIME,@pDTA_FIM+' 23:59:59',121);
	
	-- Apaga a tabela temporária, caso exista.
	IF EXISTS (SELECT * FROM SYSOBJECTS WHERE TYPE = 'U' AND NAME = 'TMP_PERIODO_'+@vID)
	BEGIN
		SELECT @vQUERY = 'DROP TABLE TMP_PERIODO_'+@vID;
		EXEC(@vQUERY)
	END
	SELECT @vQUERY = 'CREATE TABLE TMP_PERIODO_'+@vID+'(DATA DATETIME)';
	EXEC(@vQUERY);
	WHILE @vDATA1 <= @vDATA2
	BEGIN
		IF CONVERT(VARCHAR(6),@vDATA1,112) <= CONVERT(VARCHAR(6),@vDATA2,112)
		BEGIN
			SELECT @vQUERY = 'INSERT INTO TMP_PERIODO_'+@vID+' VALUES(CONVERT(DATETIME,'''+convert(varchar,@vDATA1,121)+''',121))';
			EXEC(@vQUERY);
		END;
		SELECT @vDATA1 = @vDATA1 + 1;
	END;

	SELECT @vQUERY = '
	 SELECT
    T.DATA, ISNULL(A.TOTAL_CLIENTES,0) AS "TOTAL_CLIENTES"
    FROM
    TMP_PERIODO_'+@vID+' T
    LEFT OUTER JOIN
    (
    SELECT
      CONVERT(DATE,FE.DTA_ENTRADA) AS "DATA",
	  COUNT(DISTINCT FE.COD_PESSOA) AS "TOTAL_CLIENTES"'
      +@vFROM+

      ' WHERE 1=1'+
      ' GROUP BY CONVERT(DATE,FE.DTA_ENTRADA)) A ON (A.DATA = T.DATA)  ORDER BY T.DATA';
	
END


-- Segmentação
SELECT @vCOD_CONTEXTO = COD_CONTEXTO FROM CONTEXTO WHERE NME_CONTEXTO = 'CLIENTE' AND FLG_ATIVO = 1;
IF @pSECAO = 'SEGMENTACAO' AND ISNULL(@pNME_SEGMENTACAO,'') <> '' AND @vCOD_CONTEXTO > 0
BEGIN
	IF ISNULL(@pCOD_VISIBILIDADE,' ') = ' '
		SELECT @vCOD_VISIBILIDADE = 'PA'
	ELSE
		SELECT @vCOD_VISIBILIDADE = @pCOD_VISIBILIDADE

	SELECT @vQUERY = 'SELECT DISTINCT FE.COD_PESSOA'

	EXEC SPDM_GETNEXTID 'SEGMENTACAO','COD_SEGMENTACAO',@vCOD_SEGMENTACAO OUTPUT
	INSERT INTO SEGMENTACAO(COD_SEGMENTACAO,COD_CONTEXTO,NME_SEGMENTACAO,DSC_SEGMENTACAO,SQL_SEGMENTACAO,COD_USUARIOCADASTRO,DTA_CADASTRO,
		FLG_AUTOMATICA,COD_EMPREENDIMENTO,COD_VISIBILIDADE,FLG_WIZARD)
	VALUES(@vCOD_SEGMENTACAO, @vCOD_CONTEXTO, UPPER(@pNME_SEGMENTACAO), @vDSC_SEGMENTACAO, @vQUERY+' '+@vFROM+' '+@vWHERE, @pCOD_USUARIO, GETDATE(), 
		CASE WHEN @pCOD_USUARIO = -77 THEN 1 ELSE 0 END, @pCOD_EMPREENDIMENTO, @vCOD_VISIBILIDADE, 0);

	EXEC ('INSERT INTO SEGMENTACAORESULTADO(COD_RESULTADO,COD_SEGMENTACAO) '+@vQUERY+','+@vCOD_SEGMENTACAO+' '+@vFROM+' '+@vWHERE)

	-- Grava a quantidade de clientes na segmentação salva
	UPDATE
		SEGMENTACAO 
	SET
		NUM_QUANTIDADE = (SELECT COUNT(*) FROM SEGMENTACAORESULTADO WHERE COD_SEGMENTACAO = @vCOD_SEGMENTACAO) 
	WHERE
		COD_SEGMENTACAO = @vCOD_SEGMENTACAO;

	SELECT @vQUERY = 'SELECT '+CONVERT(VARCHAR,@vCOD_SEGMENTACAO)+' AS "COD_SEGMENTACAO"'
END

PRINT(@vQUERY)
EXEC(@vQUERY)

-- Apaga a tabela temporária, caso exista.
	IF EXISTS (SELECT * FROM SYSOBJECTS WHERE TYPE = 'U' AND NAME = 'TMP_PERIODO_'+@vID)
	BEGIN
		SELECT @vQUERY = 'DROP TABLE TMP_PERIODO_'+@vID;
		EXEC(@vQUERY)
	END

END
GO
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FIM - JOELSON - WISEIT-4805 / WISEIT-4864 Dashboard Estacionamento - padronizar dia de semana e hora, colocar mapa de dia x hora, tabela de clientes
-- FIM - Fabricio - WISEIT-4826 Dashboard Clientes - poder analisar sem filtro de datas e abrir a partir de outros dashboards - WISEIT-5029 Dashboar Clientes - Procedure
-- FIM - Fabricio - WISEIT-1468/WISEIT-5048 Erro ao utilizar segmentação no contexto de clientes e atributo consumo no dashboard de RFV
-- FIM - Fabricio - WISEIT-1468/WISEIT-5339 Dashboards - gravar segmentação pelo dashboard em caixa alta
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

EXEC SPDM_CONTROLEVERSAO 'BD_VERSAO_DASHBOARD_FREQUENCIAESTACIONAMENTO', '10.0.11';
GO
------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------
-- 10.0.11 --------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- INICIO - JOELSON - WISEIT-4805 / WISEIT-4864 Dashboard Estacionamento - padronizar dia de semana e hora, colocar mapa de dia x hora, tabela de clientes
-- INICIO - Fabricio - WISEIT-4826 Dashboard Clientes - poder analisar sem filtro de datas e abrir a partir de outros dashboards - WISEIT-5029 Dashboar Clientes - Procedure
-- INICIO - Fabricio - WISEIT-1468/WISEIT-5048 Erro ao utilizar segmentação no contexto de clientes e atributo consumo no dashboard de RFV
-- INICIO - Fabricio - WISEIT-1468/WISEIT-5339 Dashboards - gravar segmentação pelo dashboard em caixa alta
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
IF EXISTS(SELECT '' FROM SYSOBJECTS WHERE XTYPE = 'V' AND NAME = 'VWDM_NUM_DIASEMANA')
	DROP VIEW VWDM_NUM_DIASEMANA
GO

CREATE VIEW VWDM_NUM_DIASEMANA
AS
	SELECT 1 AS NUM_DIASEMANA UNION ALL
	SELECT 2 UNION ALL
	SELECT 3 UNION ALL
	SELECT 4 UNION ALL
	SELECT 5 UNION ALL
	SELECT 6 UNION ALL
	SELECT 7;
GO

IF EXISTS(SELECT '' FROM SYSOBJECTS WHERE XTYPE = 'P' AND NAME = 'SPDM_DB_FREQ_ESTACIONAMENTO')
  DROP PROCEDURE SPDM_DB_FREQ_ESTACIONAMENTO
GO
CREATE PROCEDURE SPDM_DB_FREQ_ESTACIONAMENTO
(
	@pSECAO VARCHAR(100),
	@pCOD_EMPREENDIMENTO VARCHAR(20), 
	@pDTA_INI VARCHAR(30),
	@pDTA_FIM VARCHAR(30),
	@pNUM_DIASEMANA VARCHAR(1),
	@pHORA VARCHAR(5),
	@pTEMPOPERMANENCIA VARCHAR(9),
	@pCOD_SEGMENTACAO VARCHAR(20),
	@pNME_SEGMENTACAO VARCHAR(100),
	@pCOD_VISIBILIDADE VARCHAR(2), -- 'PA', 'PC', 'PR'
	@pCOD_USUARIO VARCHAR(20),
	@pTOP_CLIENTE VARCHAR (100),
	@pCOD_PESSOA VARCHAR(100)
)
AS
/*
select * from empreendimento

--> Para filtar o Dia das semana passar no 5º parâmetro os valores: 1 = DOM , 2 = SEG, 3 = TER, 4 = QUAR, 5 = QUI, 6 = SEX, 7 = SAB
--> Para filtrar poo tempo de permanência, passar os valor: ATE_1H, 1H_2H, 2H_3H, 3H_4H, ACIMA_4H

--> Gravar segmentação
EXEC SPDM_DB_FREQ_ESTACIONAMENTO 'SEGMENTACAO', 1, '2011-01-01','2011-01-31','','','','','SEG TESTE','PA','1'

--> Gráfico para cada dia da semana
EXEC SPDM_DB_FREQ_ESTACIONAMENTO 'DIASEMANA', 30, '2016-01-01','2019-02-10','','','','','','','','',''

-->Quantidade de clientes/frequência 
EXEC SPDM_DB_FREQ_ESTACIONAMENTO 'CLIENTES_FREQUENCIA', 30, '2018-01-15','2018-02-19','','','','1234','','','','',''

-->Grafico para a quantidade de clientes/frequencia
EXEC SPDM_DB_FREQ_ESTACIONAMENTO 'GRAFICO', 30, '2018-01-01','2019-01-10','','','','1234','','','','',''

-->Grafico para a quantidade de clientes/frequencia
EXEC SPDM_DB_FREQ_ESTACIONAMENTO 'GRAFICO', 30, '2018-01-01','2019-01-10','','','','','','','','',''


--> Tabela com os top 100 clientes por frequência/data último acesso.
Basta passar no 12° parametro a quantidade que deve ser retornada.
EXEC SPDM_DB_FREQ_ESTACIONAMENTO 'CLIENTES', 30, '2018-01-01','2018-01-10','','','','','','','','100',''

--> Subtabela de clientes - detalhe de cada frequência com data e hora da entrada, cancela, data e hora da saída, cancela, tempo permanência, valor pago. 
EXEC SPDM_DB_FREQ_ESTACIONAMENTO 'TAB_CLIENTE_FREQUENCIA', 30, '2018-01-15','2018-02-19','','','','','','','','','37957'

SELECT * FROM EMPREENDIMENTO
--> Grafico para Hora do dia, às segundas.
EXEC SPDM_DB_FREQ_ESTACIONAMENTO 'HORA', 1, '2000-01-01','2016-12-31','2','','',''

--> Média de permanência, aos sábados, às 15hs, com tempo de permanência de 2 a 3 horas.
EXEC SPDM_DB_FREQ_ESTACIONAMENTO 'MEDIA_PERMANENCIA', 1, '2000-01-01','2016-12-31','','','',''

--> Clientes por tempo de permanência, às quintas, ao meio dia.
EXEC SPDM_DB_FREQ_ESTACIONAMENTO 'TEMPO_PERMANENCIA', 30, '2018-01-15','2018-02-19','','','','','','','','',''
*/
BEGIN
DECLARE
	@vQUERY VARCHAR(8000), @vWHERE VARCHAR(4000), @vFROM VARCHAR(1000), @vSQL_SEGMENTACAO VARCHAR(8000),
	@vCOD_CONTEXTO INT, @vCOD_VISIBILIDADE VARCHAR(2), @vDSC_SEGMENTACAO VARCHAR(8000), @vCOD_SEGMENTACAO INT,
	@vTOP_CLIENTE VARCHAR (100),@vID VARCHAR(1000),@vDATA1 DATETIME, @vDATA2 DATETIME

SELECT @vQUERY = '';

SELECT @vFROM = '
FROM
	FREQUENCIAESTACIONAMENTO FE'; 

SELECT @vWHERE = '
WHERE
	FE.TMP_PERMANENCIA >= 0 AND FE.COD_PESSOA > 0 AND FE.COD_EMPREENDIMENTO = '+@pCOD_EMPREENDIMENTO

-- Filtro por data na frequencia (data de entrada no estacionamento)
SELECT @vWHERE = @vWHERE+' AND FE.DTA_ENTRADA >= CONVERT(DATETIME,'''+@pDTA_INI+' 00:00:00'',121) AND FE.DTA_ENTRADA <= CONVERT(DATETIME,'''+@pDTA_FIM+' 23:59:59'',121)';

-- Filtro por dia da semana
IF @pNUM_DIASEMANA <> ''
	SELECT @vWHERE = @vWHERE+' AND DATEPART(DW,FE.DTA_ENTRADA) = '+@pNUM_DIASEMANA

-- Filtro por hora.
IF @pHORA <> ''
	SELECT @vWHERE = @vWHERE+' AND DATEPART(HH,FE.DTA_ENTRADA) = '+substring(@pHORA,1,2)

-- Filtro por tempo de permanência.
IF @pTEMPOPERMANENCIA = 'ATE_1H'
	SELECT @vWHERE = @vWHERE+' AND FE.TMP_PERMANENCIA/3600000 = 0'
ELSE IF @pTEMPOPERMANENCIA = '1H_2H'
	SELECT @vWHERE = @vWHERE+' AND FE.TMP_PERMANENCIA/3600000 = 1'
ELSE IF @pTEMPOPERMANENCIA = '2H_3H'
	SELECT @vWHERE = @vWHERE+' AND FE.TMP_PERMANENCIA/3600000 = 2'
ELSE IF @pTEMPOPERMANENCIA = '3H_4H'
	SELECT @vWHERE = @vWHERE+' AND FE.TMP_PERMANENCIA/3600000 = 3'
ELSE IF @pTEMPOPERMANENCIA = 'ACIMA_4H'
	SELECT @vWHERE = @vWHERE+' AND FE.TMP_PERMANENCIA/3600000 >= 4'

-- Filtro por segmentação.
IF @pCOD_SEGMENTACAO <> ''
BEGIN
	SELECT @vWHERE = @vWHERE+' AND FE.COD_PESSOA IN (SELECT CODIGO FROM TMP_DB_SEG'+@pCOD_SEGMENTACAO+')';
END

-- Gráfico em pizza ou barras, para cada dia da semana qual a média de frequência
IF @pSECAO = 'DIASEMANA'
SELECT @vQUERY = '
	SELECT
    XX.NUM_DIASEMANA,
    DBO.FUNC_RETORNADIASEMANA2(XX.NUM_DIASEMANA,2) AS "DIA_SEMANA", 
    ISNULL(XX.QUANTIDADE,0) AS "TOTAL", 
	ISNULL(XX.QUANTIDADE,0) AS "TOTAL_BARRA",
    ISNULL(XX.MEDIA,0) AS "MEDIA", 
	ISNULL(XX.MEDIA,0) AS "BARRA_MEDIA", 
    ISNULL(XX.PORCENTAGEM,0) AS "PORCENTAGEM" 
  FROM
  (
  SELECT
    V.NUM_DIASEMANA,   
    ISNULL(Z.QUANTIDADE,0) AS "QUANTIDADE", 
    ISNULL(Z.MEDIA,0) AS "MEDIA",  
    ISNULL(Z.PORCENTAGEM,0) AS "PORCENTAGEM" 
  FROM
    VWDM_NUM_DIASEMANA V
    LEFT OUTER JOIN
    (
  SELECT
    X.NUM_DIASEMANA,X.QUANTIDADE,
    CASE
      WHEN dbo.FUNC_QTD_DIA_SEMANA_PERIODO(X.NUM_DIASEMANA,CONVERT(DATETIME,'''+@pDTA_INI+' 00:00:00'',121),CONVERT(DATETIME,'''+@pDTA_FIM+' 00:00:00'',121)) > 0
      THEN CAST(CAST(X.QUANTIDADE*1.0 AS NUMERIC(10,2))/dbo.FUNC_QTD_DIA_SEMANA_PERIODO(X.NUM_DIASEMANA,CONVERT(DATETIME,'''+@pDTA_INI+' 00:00:00'',121),CONVERT(DATETIME,'''+@pDTA_FIM+' 00:00:00'',121)) AS NUMERIC(10,2))
     ELSE 0 END AS "MEDIA",
	 CAST((X.QUANTIDADE*1.0/Y.QUANTIDADE)*100 AS NUMERIC(10,2)) AS "PORCENTAGEM"

    FROM
       (   
	       SELECT
		    DATEPART(DW,FE.DTA_ENTRADA) AS "NUM_DIASEMANA",
		    DBO.FUNC_RETORNADIASEMANA(FE.DTA_ENTRADA,2) AS "DIA_SEMANA",
			COUNT(DISTINCT FE.COD_PESSOA) AS "QUANTIDADE"'+
			@vFROM+@vWHERE+
			
			'GROUP BY
			DATEPART(DW,FE.DTA_ENTRADA), DBO.FUNC_RETORNADIASEMANA(FE.DTA_ENTRADA,2)
  ) X
  CROSS JOIN
	(
	SELECT
	COUNT(DISTINCT FE.COD_PESSOA) AS "QUANTIDADE"'+
	@vFROM+@vWHERE+
    ')Y
    ) Z ON Z.NUM_DIASEMANA = V.NUM_DIASEMANA
  ) XX    
  ORDER BY
    CASE XX.NUM_DIASEMANA WHEN 2 THEN 1 WHEN 1 THEN 8 ELSE XX.NUM_DIASEMANA END';

	

-- GRÁFICO MÉDIA DE FREQUENCIA POR HORA
IF @pSECAO = 'HORA'
SELECT @vQUERY = 'SELECT
   HORA_PERIODO.HORA, isnull(XX.QUANTIDADE,0) AS "QUANTIDADE", isnull(XX.MEDIA,0) AS "MEDIA"
  FROM
  (
  SELECT 0 AS "NUM_HORA",
  ''00:00'' AS "HORA" UNION ALL
  SELECT 1,''01:00'' UNION ALL
  SELECT 2,''02:00'' UNION ALL
  SELECT 3,''03:00'' UNION ALL
  SELECT 4,''04:00''UNION ALL
  SELECT 5,''05:00'' UNION ALL
  SELECT 6,''06:00'' UNION ALL
  SELECT 7,''07:00'' UNION ALL
  SELECT 8,''08:00'' UNION ALL
  SELECT 9,''09:00'' UNION ALL
  SELECT 10,''10:00''UNION ALL
  SELECT 11,''11:00''UNION ALL
  SELECT 12,''12:00''UNION ALL
  SELECT 13,''13:00''UNION ALL
  SELECT 14,''14:00''UNION ALL
  SELECT 15,''15:00''UNION ALL
  SELECT 16,''16:00''UNION ALL
  SELECT 17,''17:00''UNION ALL
  SELECT 18,''18:00''UNION ALL
  SELECT 19,''19:00''UNION ALL
  SELECT 20,''20:00''UNION ALL
  SELECT 21,''21:00''UNION ALL
  SELECT 22,''22:00''UNION ALL
  SELECT 23,''23:00'' 
  ) HORA_PERIODO
  LEFT OUTER JOIN
  (
  SELECT
    X.HORA, X.QUANTIDADE,
    CASE
      WHEN DATEDIFF(DAY,CONVERT(DATETIME,'''+@pDTA_INI+' 00:00:00'',121),CONVERT(DATETIME,'''+@pDTA_FIM+' 00:00:00'',121)) > 0 
      THEN CAST(CAST(X.QUANTIDADE*1.0 AS NUMERIC(10,2))/DATEDIFF(DAY,CONVERT(DATETIME,'''+@pDTA_INI+' 00:00:00'',121),CONVERT(DATETIME,'''+@pDTA_FIM+' 00:00:00'',121)) AS NUMERIC(10,2))
	  WHEN DATEDIFF(DAY,CONVERT(DATETIME,'''+@pDTA_INI+' 00:00:00'',121),CONVERT(DATETIME,'''+@pDTA_FIM+' 00:00:00'',121)) = 0 
      THEN CAST(CAST(X.QUANTIDADE*1.0 AS NUMERIC(10,2))/DATEDIFF(DAY,CONVERT(DATETIME,'''+@pDTA_INI+' 00:00:00'',121),CONVERT(DATETIME,'''+@pDTA_FIM+' 00:00:00'',121)+1) AS NUMERIC(10,2))
      ELSE 0 END AS "MEDIA"

  FROM
  (

	SELECT
		CASE WHEN LEN(DATEPART(HOUR,FE.DTA_ENTRADA)) = 1 THEN ''0'' ELSE '''' END + CONVERT(VARCHAR(2),DATEPART(HOUR,FE.DTA_ENTRADA))+'':00'' AS "HORA",
		COUNT(FE.COD_PESSOA) AS "QUANTIDADE"'+
	@vFROM+@vWHERE+
'GROUP BY DATEPART(HOUR,FE.DTA_ENTRADA) 
) X
) XX ON (XX.HORA = HORA_PERIODO.HORA)
  ORDER BY
  HORA_PERIODO.HORA'

-- MÉDIA DE PERMANÊNCIA
IF @pSECAO = 'MEDIA_PERMANENCIA'
	SELECT @vQUERY = 'SELECT left(dbo.func_RETORNATEMPO(SUM(CONVERT(NUMERIC,DATEDIFF(SECOND,DTA_ENTRADA,DTA_SAIDA)))/count(*)),5),
		Count(DISTINCT FE.COD_PESSOA) AS "TOTAL_CLIENTES" '+@vFROM+@vWHERE

-- CLIENTES POR TEMPO DE PERMANÊNCIA
IF @pSECAO = 'TEMPO_PERMANENCIA'
SELECT @vQUERY = 'SELECT 
	CASE
		WHEN FE.TMP_PERMANENCIA/3600000 = 0 THEN ''ATE_1H''
	    WHEN FE.TMP_PERMANENCIA/3600000 = 1 THEN ''1H_2H''
		WHEN FE.TMP_PERMANENCIA/3600000 = 2 THEN ''2H_3H''
		WHEN FE.TMP_PERMANENCIA/3600000 = 3 THEN ''3H_4H''
		WHEN FE.TMP_PERMANENCIA/3600000 >= 4 THEN ''ACIMA_4H''
	END AS "TEMPO",
	COUNT(*) AS "QTDE"'+
	@vFROM+@vWHERE+
'GROUP BY
	CASE
		WHEN FE.TMP_PERMANENCIA/3600000 = 0 THEN ''ATE_1H''
	    WHEN FE.TMP_PERMANENCIA/3600000 = 1 THEN ''1H_2H''
		WHEN FE.TMP_PERMANENCIA/3600000 = 2 THEN ''2H_3H''
		WHEN FE.TMP_PERMANENCIA/3600000 = 3 THEN ''3H_4H''
		WHEN FE.TMP_PERMANENCIA/3600000 >= 4 THEN ''ACIMA_4H''
	END
ORDER BY 2 DESC'


IF @pSECAO = 'CLIENTES' 
	
SELECT @vQUERY = 'SELECT A.* FROM (  SELECT TOP '+@pTOP_CLIENTE+'
'''' AS RESPONSIVE,
PF.COD_PESSOA,
PF.NME_PESSOA,
PF.NUM_CPF,
CASE WHEN ISNULL(E.NME_BAIRRO,'' '') <> '' '' THEN E.NME_BAIRRO+'' - '' ELSE '''' END+ISNULL(E.NME_CIDADE,'' '') AS "CIDADE_BAIRRO",
COUNT(DISTINCT FE.COD_FREQUENCIA) AS "QUANTIDADE_FREQUENCIA",
Max(FE.DTA_ENTRADA) AS "DATA_ULTIMA_FREQUENCIA",
DBO.FUNC_RETORNATEMPO(SUM(FE.TMP_PERMANENCIA/1000)) AS "TEMPO_TOTAL",
DBO.FUNC_RETORNATEMPO(AVG(FE.TMP_PERMANENCIA/1000)) AS "MEDIA_TEMPO"'
+@vFROM+
' INNER JOIN PESSOAFISICA PF ON (PF.COD_PESSOA = FE.COD_PESSOA)
  LEFT OUTER JOIN PESSOA_PREFERENCIA PP ON (PP.COD_PESSOA = FE.COD_PESSOA AND PP.NUM_PREFERENCIATIPOCONTATO = 1 AND PP.COD_TIPOCONTATO = 1 AND PP.COD_EMPREENDIMENTO = '+@pCOD_EMPREENDIMENTO+')
  LEFT OUTER JOIN ENDERECO E ON E.COD_CONTATO = PP.COD_CONTATO
  AND ISNULL(E.NME_BAIRRO,'' '') <> '' ''
  AND ISNULL(E.NME_CIDADE,'' '') <> '' ''
'+@vWHERE+
'  GROUP BY
PF.COD_PESSOA,
PF.NME_PESSOA,
PF.NUM_CPF,
E.NME_BAIRRO,
E.NME_CIDADE
ORDER BY COUNT(FE.COD_PESSOA) DESC )
 A';

IF @pSECAO = 'TAB_CLIENTE_FREQUENCIA' 
SELECT @vQUERY ='SELECT
FE.DTA_ENTRADA,
ISNULL(CT.NME_CANCELA, '' '') AS "CANCELA_ENTRADA",
FE.DTA_SAIDA,
ISNULL(CT2.NME_CANCELA,'' '') AS "CANCELA_SAIDA",
DBO.FUNC_RETORNATEMPO(FE.TMP_PERMANENCIA/1000) AS "TEMPO_PERMANENCIA",
ISNULL(FE.VLR_PAGO,''0'') AS "VALOR_PAGO"'
+@vFROM+ 
' INNER JOIN PESSOAFISICA PF ON (PF.COD_PESSOA = FE.COD_PESSOA)
 LEFT OUTER JOIN CANCELAESTACIONAMENTO CT ON (CT.COD_CANCELA = FE.COD_CANCELAENTRADA)
 LEFT OUTER JOIN CANCELAESTACIONAMENTO CT2 ON (CT2.COD_CANCELA = FE.COD_CANCELASAIDA)'
+@vWHERE+'
AND FE.COD_PESSOA = '+@pCOD_PESSOA+'
ORDER BY FE.DTA_ENTRADA DESC';




-- CLIENTES / FREQUENCIA
IF @pSECAO = 'CLIENTES_FREQUENCIA'
SELECT @vQUERY = '
   SELECT
   VEZES_CLIENTE.NUMERO_VEZES, VEZES_CLIENTE.VEZES,ISNULL(XX.QUANTIDADE,0) AS "CLIENTES",ISNULL(XX.QUANTIDADE,0) AS "CLIENTES_BARRA"
  FROM
  (
  SELECT 1 AS "NUMERO_VEZES",''1 VEZ''AS "VEZES" FROM DUAL UNION ALL
  SELECT 2,''2 VEZES''UNION ALL
  SELECT 3,''3 VEZES''UNION ALL
  SELECT 4,''4 VEZES''UNION ALL
  SELECT 5,''5 VEZES''UNION ALL
  SELECT 6,''6 VEZES''UNION ALL
  SELECT 7,''7 VEZES''UNION ALL
  SELECT 8,''8 VEZES''UNION ALL
  SELECT 9,''9 VEZES''UNION ALL
  SELECT 10,''ACIMA DE 10 VEZES''
) VEZES_CLIENTE
  LEFT OUTER JOIN
  (
   SELECT
  CASE
  WHEN (X.QUANTIDADE) = 1 THEN ''1 VEZ''
  WHEN (X.QUANTIDADE) = 2 THEN ''2 VEZES''
  WHEN (X.QUANTIDADE) = 3 THEN ''3 VEZES''
  WHEN (X.QUANTIDADE) = 4 THEN ''4 VEZES''
  WHEN (X.QUANTIDADE) = 5 THEN ''5 VEZES''
  WHEN (X.QUANTIDADE) = 6 THEN ''6 VEZES''
  WHEN (X.QUANTIDADE) = 7 THEN ''7 VEZES''
  WHEN (X.QUANTIDADE) = 8 THEN ''8 VEZES''
  WHEN (X.QUANTIDADE) = 9 THEN ''9 VEZES''
  WHEN (X.QUANTIDADE) >= 10 THEN ''ACIMA DE 10 VEZES''
  END AS "VEZES",
  COUNT(*) AS "QUANTIDADE"
  FROM
  (

SELECT FE.COD_PESSOA , Count(*) AS "QUANTIDADE"
'+@vFROM+@vWHERE+'
	GROUP BY FE.COD_PESSOA
) X
  GROUP BY
    CASE

WHEN (X.QUANTIDADE) = 1 THEN ''1 VEZ''
    WHEN (X.QUANTIDADE) = 2 THEN ''2 VEZES''
    WHEN (X.QUANTIDADE) = 3 THEN ''3 VEZES''
    WHEN (X.QUANTIDADE) = 4 THEN ''4 VEZES''
    WHEN (X.QUANTIDADE) = 5 THEN ''5 VEZES''
    WHEN (X.QUANTIDADE) = 6 THEN ''6 VEZES''
    WHEN (X.QUANTIDADE) = 7 THEN ''7 VEZES''
    WHEN (X.QUANTIDADE) = 8 THEN ''8 VEZES''
    WHEN (X.QUANTIDADE) = 9 THEN ''9 VEZES''
    WHEN (X.QUANTIDADE) >= 10 THEN''ACIMA DE 10 VEZES''
    END

 )  XX ON (XX.VEZES = VEZES_CLIENTE.VEZES)
   ORDER BY 1';
   
IF @pSECAO = 'GRAFICO'
BEGIN	
	SELECT @vID = @@SPID		
	SELECT @vDATA1 = CONVERT(DATETIME,@pDTA_INI+' 00:00:00',121);
	SELECT @vDATA2 = CONVERT(DATETIME,@pDTA_FIM+' 23:59:59',121);
	
	-- Apaga a tabela temporária, caso exista.
	IF EXISTS (SELECT * FROM SYSOBJECTS WHERE TYPE = 'U' AND NAME = 'TMP_PERIODO_'+@vID)
	BEGIN
		SELECT @vQUERY = 'DROP TABLE TMP_PERIODO_'+@vID;
		EXEC(@vQUERY)
	END
	SELECT @vQUERY = 'CREATE TABLE TMP_PERIODO_'+@vID+'(DATA DATETIME)';
	EXEC(@vQUERY);
	WHILE @vDATA1 <= @vDATA2
	BEGIN
		IF CONVERT(VARCHAR(6),@vDATA1,112) <= CONVERT(VARCHAR(6),@vDATA2,112)
		BEGIN
			SELECT @vQUERY = 'INSERT INTO TMP_PERIODO_'+@vID+' VALUES(CONVERT(DATETIME,'''+convert(varchar,@vDATA1,121)+''',121))';
			EXEC(@vQUERY);
		END;
		SELECT @vDATA1 = @vDATA1 + 1;
	END;

	SELECT @vQUERY = '
	 SELECT
    T.DATA, ISNULL(A.TOTAL_CLIENTES,0) AS "TOTAL_CLIENTES"
    FROM
    TMP_PERIODO_'+@vID+' T
    LEFT OUTER JOIN
    (
    SELECT
      CONVERT(DATE,FE.DTA_ENTRADA) AS "DATA",
	  COUNT(DISTINCT FE.COD_PESSOA) AS "TOTAL_CLIENTES"'
      +@vFROM+@vWHERE+
      ' GROUP BY CONVERT(DATE,FE.DTA_ENTRADA)) A ON (A.DATA = T.DATA)  ORDER BY T.DATA';
	
END


-- Segmentação
SELECT @vCOD_CONTEXTO = COD_CONTEXTO FROM CONTEXTO WHERE NME_CONTEXTO = 'CLIENTE' AND FLG_ATIVO = 1;
IF @pSECAO = 'SEGMENTACAO' AND ISNULL(@pNME_SEGMENTACAO,'') <> '' AND @vCOD_CONTEXTO > 0
BEGIN
	IF ISNULL(@pCOD_VISIBILIDADE,' ') = ' '
		SELECT @vCOD_VISIBILIDADE = 'PA'
	ELSE
		SELECT @vCOD_VISIBILIDADE = @pCOD_VISIBILIDADE

	SELECT @vQUERY = 'SELECT DISTINCT FE.COD_PESSOA'

	EXEC SPDM_GETNEXTID 'SEGMENTACAO','COD_SEGMENTACAO',@vCOD_SEGMENTACAO OUTPUT
	INSERT INTO SEGMENTACAO(COD_SEGMENTACAO,COD_CONTEXTO,NME_SEGMENTACAO,DSC_SEGMENTACAO,SQL_SEGMENTACAO,COD_USUARIOCADASTRO,DTA_CADASTRO,
		FLG_AUTOMATICA,COD_EMPREENDIMENTO,COD_VISIBILIDADE,FLG_WIZARD)
	VALUES(@vCOD_SEGMENTACAO, @vCOD_CONTEXTO, UPPER(@pNME_SEGMENTACAO), @vDSC_SEGMENTACAO, @vQUERY+' '+@vFROM+' '+@vWHERE, @pCOD_USUARIO, GETDATE(), 
		CASE WHEN @pCOD_USUARIO = -77 THEN 1 ELSE 0 END, @pCOD_EMPREENDIMENTO, @vCOD_VISIBILIDADE, 0);

	EXEC ('INSERT INTO SEGMENTACAORESULTADO(COD_RESULTADO,COD_SEGMENTACAO) '+@vQUERY+','+@vCOD_SEGMENTACAO+' '+@vFROM+' '+@vWHERE)

	-- Grava a quantidade de clientes na segmentação salva
	UPDATE
		SEGMENTACAO 
	SET
		NUM_QUANTIDADE = (SELECT COUNT(*) FROM SEGMENTACAORESULTADO WHERE COD_SEGMENTACAO = @vCOD_SEGMENTACAO) 
	WHERE
		COD_SEGMENTACAO = @vCOD_SEGMENTACAO;

	SELECT @vQUERY = 'SELECT '+CONVERT(VARCHAR,@vCOD_SEGMENTACAO)+' AS "COD_SEGMENTACAO"'
END

PRINT(@vQUERY)
EXEC(@vQUERY)

-- Apaga a tabela temporária, caso exista.
	IF EXISTS (SELECT * FROM SYSOBJECTS WHERE TYPE = 'U' AND NAME = 'TMP_PERIODO_'+@vID)
	BEGIN
		SELECT @vQUERY = 'DROP TABLE TMP_PERIODO_'+@vID;
		EXEC(@vQUERY)
	END

END
GO
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FIM - JOELSON - WISEIT-4805 / WISEIT-4864 Dashboard Estacionamento - padronizar dia de semana e hora, colocar mapa de dia x hora, tabela de clientes
-- FIM - Fabricio - WISEIT-4826 Dashboard Clientes - poder analisar sem filtro de datas e abrir a partir de outros dashboards - WISEIT-5029 Dashboar Clientes - Procedure
-- FIM - Fabricio - WISEIT-1468/WISEIT-5048 Erro ao utilizar segmentação no contexto de clientes e atributo consumo no dashboard de RFV
-- FIM - Fabricio - WISEIT-1468/WISEIT-5339 Dashboards - gravar segmentação pelo dashboard em caixa alta
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

EXEC SPDM_CONTROLEVERSAO 'BD_VERSAO_DASHBOARD_FREQUENCIAESTACIONAMENTO', '10.0.11';
GO
------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------


