------------------------------------------------------------------------------------------------------------------------------------------------------
-- 10.0.1 --------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE SPDM_DB_FREQ_ESTACIONAMENTO
(
	pSESSAO VARCHAR2,
	pCOD_EMPREENDIMENTO INT,
	pDTA_INI VARCHAR2,
	pDTA_FIM VARCHAR2,
	pDIASEMANA VARCHAR2,
	pHORA VARCHAR2,
	pTEMPOPERMANENCIA VARCHAR2,
  RESULTSET OUT SYS_REFCURSOR
)
AS
/*
--> Para filtar o Dia das semana passar no 5º parâmetro os valores: 1 = DOM , 2 = SEG, 3 = TER, 4 = QUAR, 5 = QUI, 6 = SEX, 7 = SAB
--> Para filtrar poo tempo de permanência, passar os valor: ATE_1H, 1H_2H, 2H_3H, 3H_4H, ACIMA_4H

--> Gráfico para cada dia da semana
EXEC SPDM_DB_FREQ_ESTACIONAMENTO ('DIASEMANA', 6, '2000-01-01 00:00:00','2016-12-31 23:59:59','','','');

--> Grafico para Hora do dia, às segundas.
EXEC SPDM_DB_FREQ_ESTACIONAMENTO ('HORA', 6, '2000-01-01 00:00:00','2016-12-31 23:59:59','2','','');

--> Média de permanência, aos sábados, às 15hs, com tempo de permanência de 2 a 3 horas.
EXEC SPDM_DB_FREQ_ESTACIONAMENTO ('MEDIA_PERMANENCIA', 6, '2000-01-01 00:00:00','2016-12-31 23:59:59','7','15:00','2H_3H');

--> Clientes por tempo de permanência, às quintas, ao meio dia.
EXEC SPDM_DB_FREQ_ESTACIONAMENTO ('TEMPO_PERMANENCIA', 6, '2011-01-01 00:00:00','2016-12-31 23:59:59','5','12:00','');
*/
BEGIN
DECLARE
	vQUERY VARCHAR2(8000); vWHERE VARCHAR2(1000); vFROM VARCHAR(1000);
BEGIN
vQUERY := '';

vFROM := '
FROM
	CARTAOESTACIONAMENTO CE
	INNER JOIN TIPOCARTAOESTACIONAMENTO TCE ON (TCE.COD_TIPOCARTAO = CE.COD_TIPOCARTAO)
	INNER JOIN PESSOA_CARTAOESTACIONAMENTO PCE ON (PCE.COD_CARTAO = CE.COD_CARTAO)
	INNER JOIN FREQUENCIAESTACIONAMENTO FE ON (FE.COD_CARTAO = CE.COD_CARTAO AND FE.TMP_PERMANENCIA >= 0)';

-- Filtro por empreendimento (obrigatório).
vWHERE := ' AND TCE.COD_EMPREENDIMENTO = '||pCOD_EMPREENDIMENTO;

-- Filtro por data na frequencia (data de entrada no estacionamento)
vWHERE := vWHERE||' AND FE.DTA_ENTRADA >= to_date('''||pDTA_INI||''',''YYYY-MM-DD HH24:MI:SS'') AND FE.DTA_ENTRADA <= to_date('''||pDTA_FIM||''',''YYYY-MM-DD HH24:MI:SS'')';

-- Filtro por dia da semana
IF pDIASEMANA <> ' ' THEN
	vWHERE := vWHERE||' AND TO_CHAR(FE.DTA_ENTRADA,''D'') = '||pDIASEMANA;
END IF;

-- Filtro por hora.
IF pHORA <> ' ' THEN
	vWHERE := vWHERE||' AND to_char(FE.DTA_ENTRADA,''HH24'') = '||substr(pHORA,1,2);
END IF;

-- Filtro por tempo de permanência.
IF pTEMPOPERMANENCIA = 'ATE_1H' THEN
	vWHERE := vWHERE||' AND FE.TMP_PERMANENCIA = 0';
ELSIF pTEMPOPERMANENCIA = '1H_2H' THEN
	vWHERE := vWHERE||' AND FE.TMP_PERMANENCIA = 1';
ELSIF pTEMPOPERMANENCIA = '2H_3H' THEN
	vWHERE := vWHERE||' AND FE.TMP_PERMANENCIA = 2';
ELSIF pTEMPOPERMANENCIA = '3H_4H' THEN
	vWHERE := vWHERE||' AND FE.TMP_PERMANENCIA = 3';
ELSIF pTEMPOPERMANENCIA = 'ACIMA_4H' THEN
	vWHERE := vWHERE||' AND FE.TMP_PERMANENCIA >= 4';
END IF;


-- Gráfico em pizza ou barras, para cada dia da semana qual a média de frequência
IF pSESSAO = 'DIASEMANA' THEN
vQUERY := 'SELECT
	CASE TO_NUMBER(TO_CHAR(A.DIA,''D'')) WHEN 1 THEN ''DOMINGO'' WHEN 2 THEN ''SEGUNDA'' WHEN 3 THEN ''TERÇA'' WHEN 4 THEN ''QUARTA'' WHEN 5 THEN ''QUINTA''
	WHEN 6 THEN ''SEXTA'' WHEN 7 THEN ''SÁBADO'' END AS "DIA_SEMANA", COUNT(A.DIA) AS "QTDE"
FROM
	(
	SELECT DISTINCT
		COD_PESSOA,to_date(to_char(DTA_ENTRADA,''YYYMMDD''),''YYYMMDD'') AS DIA'||
	vFROM||vWHERE||
	') A
GROUP BY
	TO_CHAR(A.DIA,''D'')
ORDER BY
	2 DESC';
END IF;

-- GRÁFICO MÉDIA DE FREQUENCIA POR HORA
IF pSESSAO = 'HORA' THEN
vQUERY := 'SELECT
	CASE To_Number(A.HORA) WHEN 0 THEN ''00:00'' WHEN 1 THEN ''01:00'' WHEN 2 THEN ''02:00'' WHEN 3 THEN ''03:00'' WHEN 4 THEN ''04:00'' WHEN 5 THEN ''05:00'' WHEN 6 THEN ''06:00''
	WHEN 7 THEN ''07:00'' WHEN 8 THEN ''08:00'' WHEN 9 THEN ''09:00'' WHEN 10 THEN ''10:00'' WHEN 11 THEN ''11:00'' WHEN 12 THEN ''12:00'' WHEN 13 THEN ''13:00''
	WHEN 14 THEN ''14:00'' WHEN 15 THEN ''15:00'' WHEN 16 THEN ''16:00'' WHEN 17 THEN ''17:00'' WHEN 18 THEN ''18:00'' WHEN 19 THEN ''19:00'' WHEN 20 THEN ''20:00''
	WHEN 21 THEN ''21:00'' WHEN 22 THEN ''22:00'' WHEN 23 THEN ''23:00'' END AS "HORA",COUNT(A.HORA)
FROM
	(
	SELECT DISTINCT
		COD_PESSOA,to_char(DTA_ENTRADA,''HH24'') AS HORA'||
	vFROM||vWHERE||
	') A
GROUP BY
	A.HORA
ORDER BY
	2 DESC';
END IF;

-- MÉDIA DE PERMANÊNCIA
IF pSESSAO = 'MEDIA_PERMANENCIA' THEN
	vQUERY := 'SELECT AVG(FE.TMP_PERMANENCIA) '||vFROM||vWHERE;
END IF;

-- CLIENTES POR TEMPO DE PERMANÊNCIA
IF pSESSAO = 'TEMPO_PERMANENCIA' THEN
vQUERY := 'SELECT
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
	FE.TMP_PERMANENCIA, COUNT(*) AS "QTDE"'||
	vFROM||vWHERE||
' GROUP BY
	TMP_PERMANENCIA
) A
GROUP BY A.TMP_PERMANENCIA
) B';
END IF;

--Dbms_Output.Put_Line(vQUERY);
OPEN RESULTSET FOR vQUERY;
END;
END;
/

EXEC SPDM_CONTROLEVERSAO ('BD_VERSAO_DASHBOARD_FREQUENCIAESTACIONAMENTO', '10.0.1');
------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------
-- 10.0.2 --------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE SPDM_DB_FREQ_ESTACIONAMENTO
(
	pSESSAO VARCHAR2,
	pCOD_EMPREENDIMENTO INT,
	pDTA_INI VARCHAR2,
	pDTA_FIM VARCHAR2,
	pDIASEMANA VARCHAR2,
	pHORA VARCHAR2,
	pTEMPOPERMANENCIA VARCHAR2,
  RESULTSET OUT SYS_REFCURSOR
)
AS
/*
--> Para filtar o Dia das semana passar no 5º parâmetro os valores: 1 = DOM , 2 = SEG, 3 = TER, 4 = QUAR, 5 = QUI, 6 = SEX, 7 = SAB
--> Para filtrar poo tempo de permanência, passar os valor: ATE_1H, 1H_2H, 2H_3H, 3H_4H, ACIMA_4H

--> Gráfico para cada dia da semana
variable vCUR refcursor
EXEC SPDM_DB_FREQ_ESTACIONAMENTO ('DIASEMANA', '6', '2000-01-01 00:00:00', '2016-12-31 23:59:59', '', '', '', :vCUR);
print vCUR

--> Grafico para Hora do dia, às segundas.
variable vCUR refcursor
EXEC SPDM_DB_FREQ_ESTACIONAMENTO ('HORA', '6', '2000-01-01 00:00:00', '2016-12-31 23:59:59', '2', '', '', :vCUR);
print vCUR

--> Média de permanência, aos sábados, às 15hs, com tempo de permanência de 2 a 3 horas.
variable vCUR refcursor
EXEC SPDM_DB_FREQ_ESTACIONAMENTO ('MEDIA_PERMANENCIA', '6', '2000-01-01 00:00:00', '2016-12-31 23:59:59', '7', '15:00', '2H_3H', :vCUR);
print vCUR


--> Clientes por tempo de permanência, às quintas, ao meio dia.
variable vCUR refcursor
EXEC SPDM_DB_FREQ_ESTACIONAMENTO ('TEMPO_PERMANENCIA', '6', '2000-01-01 00:00:00', '2016-12-31 23:59:59', '5', '12:00', '', :vCUR);
print vCUR
*/
BEGIN
DECLARE
	vQUERY VARCHAR2(8000); vWHERE VARCHAR2(1000); vFROM VARCHAR(1000);
BEGIN
vQUERY := '';

vFROM := '
FROM
	CARTAOESTACIONAMENTO CE
	INNER JOIN TIPOCARTAOESTACIONAMENTO TCE ON (TCE.COD_TIPOCARTAO = CE.COD_TIPOCARTAO)
	INNER JOIN PESSOA_CARTAOESTACIONAMENTO PCE ON (PCE.COD_CARTAO = CE.COD_CARTAO)
	INNER JOIN FREQUENCIAESTACIONAMENTO FE ON (FE.COD_CARTAO = CE.COD_CARTAO AND FE.TMP_PERMANENCIA >= 0)';

-- Filtro por empreendimento (obrigatório).
vWHERE := ' AND TCE.COD_EMPREENDIMENTO = '||pCOD_EMPREENDIMENTO;

-- Filtro por data na frequencia (data de entrada no estacionamento)
vWHERE := vWHERE||' AND FE.DTA_ENTRADA >= to_date('''||pDTA_INI||''',''YYYY-MM-DD HH24:MI:SS'') AND FE.DTA_ENTRADA <= to_date('''||pDTA_FIM||''',''YYYY-MM-DD HH24:MI:SS'')';

-- Filtro por dia da semana
IF pDIASEMANA <> ' ' THEN
	vWHERE := vWHERE||' AND TO_CHAR(FE.DTA_ENTRADA,''D'') = '||pDIASEMANA;
END IF;

-- Filtro por hora.
IF pHORA <> ' ' THEN
	vWHERE := vWHERE||' AND to_char(FE.DTA_ENTRADA,''HH24'') = '||substr(pHORA,1,2);
END IF;

-- Filtro por tempo de permanência.
IF pTEMPOPERMANENCIA = 'ATE_1H' THEN
	vWHERE := vWHERE||' AND trunc(FE.TMP_PERMANENCIA/3600000) = 0';
ELSIF pTEMPOPERMANENCIA = '1H_2H' THEN
	vWHERE := vWHERE||' AND trunc(FE.TMP_PERMANENCIA/3600000) = 1';
ELSIF pTEMPOPERMANENCIA = '2H_3H' THEN
	vWHERE := vWHERE||' AND trunc(FE.TMP_PERMANENCIA/3600000) = 2';
ELSIF pTEMPOPERMANENCIA = '3H_4H' THEN
	vWHERE := vWHERE||' AND trunc(FE.TMP_PERMANENCIA/3600000) = 3';
ELSIF pTEMPOPERMANENCIA = 'ACIMA_4H' THEN
	vWHERE := vWHERE||' AND trunc(FE.TMP_PERMANENCIA/3600000) >= 4';
END IF;


-- Gráfico em pizza ou barras, para cada dia da semana qual a média de frequência
IF pSESSAO = 'DIASEMANA' THEN
vQUERY := 'SELECT
	CASE TO_NUMBER(TO_CHAR(A.DIA,''D'')) WHEN 1 THEN ''Domingo'' WHEN 2 THEN ''Segunda'' WHEN 3 THEN ''Terça'' WHEN 4 THEN ''Quarta'' WHEN 5 THEN ''Quinta''
	WHEN 6 THEN ''Sexta'' WHEN 7 THEN ''Sábado'' END AS "DIA_SEMANA", COUNT(A.DIA) AS "QTDE"
FROM
	(
	SELECT DISTINCT
		COD_PESSOA,to_date(to_char(DTA_ENTRADA,''YYYMMDD''),''YYYMMDD'') AS DIA'||
	vFROM||vWHERE||
	') A
GROUP BY
	TO_CHAR(A.DIA,''D'')
ORDER BY
	TO_NUMBER(TO_CHAR(A.DIA,''D''))';
END IF;

-- GRÁFICO MÉDIA DE FREQUENCIA POR HORA
IF pSESSAO = 'HORA' THEN
vQUERY := 'SELECT
	CASE TO_NUMBER(A.HORA) WHEN 0 THEN ''00:00'' WHEN 1 THEN ''01:00'' WHEN 2 THEN ''02:00'' WHEN 3 THEN ''03:00'' WHEN 4 THEN ''04:00'' WHEN 5 THEN ''05:00'' WHEN 6 THEN ''06:00''
	WHEN 7 THEN ''07:00'' WHEN 8 THEN ''08:00'' WHEN 9 THEN ''09:00'' WHEN 10 THEN ''10:00'' WHEN 11 THEN ''11:00'' WHEN 12 THEN ''12:00'' WHEN 13 THEN ''13:00''
	WHEN 14 THEN ''14:00'' WHEN 15 THEN ''15:00'' WHEN 16 THEN ''16:00'' WHEN 17 THEN ''17:00'' WHEN 18 THEN ''18:00'' WHEN 19 THEN ''19:00'' WHEN 20 THEN ''20:00''
	WHEN 21 THEN ''21:00'' WHEN 22 THEN ''22:00'' WHEN 23 THEN ''23:00'' END AS "HORA", TO_NUMBER(COUNT(A.HORA)) AS "QTDE"
FROM
	(
	SELECT DISTINCT
		COD_PESSOA,to_char(DTA_ENTRADA,''HH24'') AS HORA'||
	vFROM||vWHERE||
	') A
GROUP BY
	A.HORA
ORDER BY
	A.HORA';
END IF;

-- MÉDIA DE PERMANÊNCIA
IF pSESSAO = 'MEDIA_PERMANENCIA' THEN
	vQUERY := 'SELECT TRUNC(AVG(FE.TMP_PERMANENCIA/3600000)) '||vFROM||vWHERE;
END IF;

-- CLIENTES POR TEMPO DE PERMANÊNCIA
IF pSESSAO = 'TEMPO_PERMANENCIA' THEN
vQUERY := 'SELECT 
	CASE
		WHEN trunc(FE.TMP_PERMANENCIA/3600000) = 0 THEN ''ATE_1H''
	    WHEN trunc(FE.TMP_PERMANENCIA/3600000) = 1 THEN ''1H_2H''
		WHEN trunc(FE.TMP_PERMANENCIA/3600000) = 2 THEN ''2H_3H''
		WHEN trunc(FE.TMP_PERMANENCIA/3600000) = 3 THEN ''3H_4H''
		WHEN trunc(FE.TMP_PERMANENCIA/3600000) >= 4 THEN ''ACIMA_4H''
	END AS "TEMPO",
	TO_NUMBER(COUNT(*)) AS "QTDE"'||
	vFROM||vWHERE||
'GROUP BY
	CASE
		WHEN trunc(FE.TMP_PERMANENCIA/3600000) = 0 THEN ''ATE_1H''
	    WHEN trunc(FE.TMP_PERMANENCIA/3600000) = 1 THEN ''1H_2H''
		WHEN trunc(FE.TMP_PERMANENCIA/3600000) = 2 THEN ''2H_3H''
		WHEN trunc(FE.TMP_PERMANENCIA/3600000) = 3 THEN ''3H_4H''
		WHEN trunc(FE.TMP_PERMANENCIA/3600000) >= 4 THEN ''ACIMA_4H''
	END
ORDER BY 2 DESC';
END IF;

--Dbms_Output.Put_Line(vQUERY);
OPEN RESULTSET FOR vQUERY;
END;
END;
/

EXEC SPDM_CONTROLEVERSAO ('BD_VERSAO_DASHBOARD_FREQUENCIAESTACIONAMENTO', '10.0.2');

------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------
-- 10.0.3 --------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------
-- INÍCIO 136195, Ricardo Vale (Principal: 135362) - Criar Item de Menu para o dashboard Frequência e Permanência
--------------------------------------------------------------------------------------------------------------------------------------------
DECLARE
vNME_MODULO VARCHAR(100);vNME_ITEMMENU VARCHAR(100);vSLG_ITEMMENU VARCHAR(100);vDSC_ITEMMENU VARCHAR(4000);vNME_ITEMMENUPAI VARCHAR(200);vURL_ICONE VARCHAR(1000);
vNME_RECURSO VARCHAR(100);vNME_CONTEUDO VARCHAR(100);vURL_CONTEUDO VARCHAR(200);vPARAM1_CODVARIAVEL INT;vPARAM1_NMEPARAMETRO VARCHAR(100);vPARAM1_VLRPARAMETRO VARCHAR(1000);
vPARAM2_CODVARIAVEL INT;vPARAM2_NMEPARAMETRO VARCHAR(100);vPARAM2_VLRPARAMETRO VARCHAR(1000);vPARAM3_CODVARIAVEL INT;vPARAM3_NMEPARAMETRO VARCHAR(100);
vPARAM3_VLRPARAMETRO VARCHAR(1000);vDSC_PERMISSAORECURSOCONSULTAR VARCHAR(200);vDSC_PERMISSAORECURSOEXCLUIR VARCHAR(200);vDSC_PERMISSAORECURSOCADASTRAR VARCHAR(200);
vDSC_PERMISSAORECURSOEXPORTAR VARCHAR(200);vDSC_PERMISSAORECURSOEXECUTAR VARCHAR(200);vDSC_PERMISSAORECURSOPERMITIR VARCHAR(200);vRETORNO VARCHAR(100);
vFLG_NOVA_JANELA SMALLINT;vFLG_RECARREGA SMALLINT;vFLG_PORTAL SMALLINT;vFLG_ATENDIMENTO SMALLINT;vFLG_MULTITELA SMALLINT;vFLG_WORKFLOW SMALLINT;vFLG_IE8 SMALLINT;vNME_CONTROLLER VARCHAR(100);
vPRT_PERMISSAORECURSOCONSULTAR VARCHAR(200);vPRT_PERMISSAORECURSOEXCLUIR VARCHAR(200);vPRT_PERMISSAORECURSOPERMITIR VARCHAR(200);vPRT_PERMISSAORECURSOCADASTRAR VARCHAR(200);
vPRT_PERMISSAORECURSOEXPORTAR VARCHAR(200);vPRT_PERMISSAORECURSOEXECUTAR VARCHAR(200);
BEGIN
  -- Nome do menu.
  vNME_ITEMMENU := 'DASHBOARD FREQUÊNCIA E PERMANÊNCIA';
  -- Sigla do menu.
  vSLG_ITEMMENU := NULL;
  -- Descrição do menu.
  vDSC_ITEMMENU := 'Analisar comparativos de dias de semana a frequência usada do estacionamento e também o tempo de permanência dos clientes no estacionamento.';
  -- Caminho do ícone do menu.
  vURL_ICONE := '/CCenterWeb/images/portal/icones/gd/ico_dashboard_frequenciapermanencia.gif';
  -- Nome do Menu Pai (caminho completo separado por "/", até 3 níveis), se for menu principal deixar nulo.
  vNME_ITEMMENUPAI := 'Relatórios/Estacionamento';
  -- Nome do Recurso
  vNME_RECURSO := 'DASHBOARD FREQUÊNCIA E PERMANÊNCIA';
  -- Módulo pertecente ao menu. Preencher somente se tiver RECURSO.
  vNME_MODULO := 'ESTACIONAMENTO';
  -- Entrar com as descrições das permissões. Preencher somente se tiver RECURSO.
  vDSC_PERMISSAORECURSOCONSULTAR := 'Disponibiliza o ícone Dashboard Frequência e Permanência.';
  vDSC_PERMISSAORECURSOPERMITIR := 'Permite mexer nas permissões deste recurso para outros usuários.';
  -- Nome do Conteudo
  vNME_CONTEUDO := 'DASHBOARD FREQUÊNCIA E PERMANÊNCIA';
  vURL_CONTEUDO := '/CCenterWeb/pentaho/api/repos/%3Apublic%3AFREQUENCIA%3AFREQUENCIA.wcdf/generatedContent';
  vFLG_NOVA_JANELA := 0;
  vFLG_RECARREGA := 0;
  vFLG_PORTAL := 0;
  vFLG_ATENDIMENTO := 0;
  vFLG_MULTITELA := 0;
  vFLG_WORKFLOW := 0;
  vFLG_IE8 := 0;
  vNME_CONTROLLER :=	NULL;
  -- Parâmetros do conteudo.
  vPARAM1_NMEPARAMETRO := 'codUsuario';
  vPARAM1_CODVARIAVEL := 3;
  vPARAM2_NMEPARAMETRO := 'codEmpreendimento';
  vPARAM2_CODVARIAVEL := 15;

  SPDM_POPULA_ITEMMENU_NEW(vNME_MODULO,vNME_ITEMMENU,vSLG_ITEMMENU,vDSC_ITEMMENU,vNME_ITEMMENUPAI,vURL_ICONE,vNME_RECURSO,vNME_CONTEUDO,vURL_CONTEUDO,
	vFLG_NOVA_JANELA,vFLG_RECARREGA,vFLG_PORTAL,vFLG_ATENDIMENTO,vFLG_MULTITELA,vFLG_WORKFLOW,vFLG_IE8,vNME_CONTROLLER,vPARAM1_CODVARIAVEL,vPARAM1_NMEPARAMETRO,
	vPARAM1_VLRPARAMETRO,vPARAM2_CODVARIAVEL,vPARAM2_NMEPARAMETRO,vPARAM2_VLRPARAMETRO,vPARAM3_CODVARIAVEL,vPARAM3_NMEPARAMETRO,vPARAM3_VLRPARAMETRO,
	vDSC_PERMISSAORECURSOCONSULTAR,vPRT_PERMISSAORECURSOCONSULTAR,vDSC_PERMISSAORECURSOEXCLUIR,vPRT_PERMISSAORECURSOEXCLUIR,
	vDSC_PERMISSAORECURSOCADASTRAR,vPRT_PERMISSAORECURSOCADASTRAR,vDSC_PERMISSAORECURSOEXPORTAR,vPRT_PERMISSAORECURSOEXPORTAR,
	vDSC_PERMISSAORECURSOEXECUTAR,vPRT_PERMISSAORECURSOEXECUTAR,vDSC_PERMISSAORECURSOPERMITIR,vPRT_PERMISSAORECURSOPERMITIR,vRETORNO);
  Dbms_Output.Put_Line(vRETORNO);
END;
/
--------------------------------------------------------------------------------------------------------------------------------------------
-- FIM 136195, Ricardo Vale (Principal: 135362) - Criar Item de Menu para o dashboard Frequência e Permanência
--------------------------------------------------------------------------------------------------------------------------------------------

EXEC SPDM_CONTROLEVERSAO ('BD_VERSAO_DASHBOARD_FREQUENCIAESTACIONAMENTO', '10.0.3');

------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------
-- 10.0.4 --------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------------------
--> MENU "Relatórios >> Estacionamento"
-----------------------------------------------------------------------------------------------------------
DECLARE
vNME_MODULO VARCHAR(100);vNME_ITEMMENU VARCHAR(100);vSLG_ITEMMENU VARCHAR(100);vDSC_ITEMMENU VARCHAR(4000);vNME_ITEMMENUPAI VARCHAR(200);vURL_ICONE VARCHAR(1000);
vNME_RECURSO VARCHAR(100);vNME_CONTEUDO VARCHAR(100);vURL_CONTEUDO VARCHAR(200);vPARAM1_CODVARIAVEL INT;vPARAM1_NMEPARAMETRO VARCHAR(100);vPARAM1_VLRPARAMETRO VARCHAR(1000);
vPARAM2_CODVARIAVEL INT;vPARAM2_NMEPARAMETRO VARCHAR(100);vPARAM2_VLRPARAMETRO VARCHAR(1000);vPARAM3_CODVARIAVEL INT;vPARAM3_NMEPARAMETRO VARCHAR(100);
vPARAM3_VLRPARAMETRO VARCHAR(1000);vDSC_PERMISSAORECURSOCONSULTAR VARCHAR(200);vDSC_PERMISSAORECURSOEXCLUIR VARCHAR(200);vDSC_PERMISSAORECURSOCADASTRAR VARCHAR(200);
vDSC_PERMISSAORECURSOEXPORTAR VARCHAR(200);vDSC_PERMISSAORECURSOEXECUTAR VARCHAR(200);vDSC_PERMISSAORECURSOPERMITIR VARCHAR(200);vRETORNO VARCHAR(100);
vFLG_NOVA_JANELA SMALLINT;vFLG_RECARREGA SMALLINT;vFLG_PORTAL SMALLINT;vFLG_ATENDIMENTO SMALLINT;vFLG_MULTITELA SMALLINT;vFLG_WORKFLOW SMALLINT;vFLG_IE8 SMALLINT;vNME_CONTROLLER VARCHAR(100);
vPRT_PERMISSAORECURSOCONSULTAR VARCHAR(200);vPRT_PERMISSAORECURSOEXCLUIR VARCHAR(200);vPRT_PERMISSAORECURSOPERMITIR VARCHAR(200);vPRT_PERMISSAORECURSOCADASTRAR VARCHAR(200);
vPRT_PERMISSAORECURSOEXPORTAR VARCHAR(200);vPRT_PERMISSAORECURSOEXECUTAR VARCHAR(200);
BEGIN
  -- Nome do menu.
  vNME_ITEMMENU := 'Estacionamento';
  -- Sigla do menu.
  vSLG_ITEMMENU := 'ESTACIONAMENTO';
  -- DescriÃ§Ã£o do menu.
  vDSC_ITEMMENU := 'Relatórios e dashboards de estacionamento';
  -- Caminho do ícone do menu.
  vURL_ICONE := NULL;
  -- Nome do Menu Pai
  vNME_ITEMMENUPAI := 'Relatórios';
  -- Nome do Recurso
  vNME_RECURSO := NULL;
  -- Módulo pertecente ao menu. Preencher somente se tiver RECURSO.
  vNME_MODULO := 'CADASTROS';
  -- Nome do Conteudo
  vNME_CONTEUDO := NULL;
  vURL_CONTEUDO := NULL;
  vFLG_NOVA_JANELA := 0;
  vFLG_RECARREGA := 0;
  vFLG_PORTAL := 1;
  vFLG_ATENDIMENTO := 0;
  vFLG_MULTITELA := 0;
  vFLG_WORKFLOW := 0;
  vFLG_IE8 := 0;
  vNME_CONTROLLER := NULL;
  -- Entrar com as descrições das permissÃµes.
  vDSC_PERMISSAORECURSOCONSULTAR := NULL;
  vDSC_PERMISSAORECURSOEXCLUIR := NULL;
  vDSC_PERMISSAORECURSOCADASTRAR := NULL;
  vDSC_PERMISSAORECURSOEXPORTAR := NULL;
  vDSC_PERMISSAORECURSOEXECUTAR := NULL;
  vDSC_PERMISSAORECURSOPERMITIR := NULL;

  SPDM_POPULA_ITEMMENU_NEW(vNME_MODULO,vNME_ITEMMENU,vSLG_ITEMMENU,vDSC_ITEMMENU,vNME_ITEMMENUPAI,vURL_ICONE,vNME_RECURSO,vNME_CONTEUDO,vURL_CONTEUDO,
	vFLG_NOVA_JANELA,vFLG_RECARREGA,vFLG_PORTAL,vFLG_ATENDIMENTO,vFLG_MULTITELA,vFLG_WORKFLOW,vFLG_IE8,vNME_CONTROLLER,vPARAM1_CODVARIAVEL,vPARAM1_NMEPARAMETRO,
	vPARAM1_VLRPARAMETRO,vPARAM2_CODVARIAVEL,vPARAM2_NMEPARAMETRO,vPARAM2_VLRPARAMETRO,vPARAM3_CODVARIAVEL,vPARAM3_NMEPARAMETRO,vPARAM3_VLRPARAMETRO,
	vDSC_PERMISSAORECURSOCONSULTAR,vPRT_PERMISSAORECURSOCONSULTAR,vDSC_PERMISSAORECURSOEXCLUIR,vPRT_PERMISSAORECURSOEXCLUIR,
	vDSC_PERMISSAORECURSOCADASTRAR,vPRT_PERMISSAORECURSOCADASTRAR,vDSC_PERMISSAORECURSOEXPORTAR,vPRT_PERMISSAORECURSOEXPORTAR,
	vDSC_PERMISSAORECURSOEXECUTAR,vPRT_PERMISSAORECURSOEXECUTAR,vDSC_PERMISSAORECURSOPERMITIR,vPRT_PERMISSAORECURSOPERMITIR,vRETORNO);
  Dbms_Output.Put_Line(vRETORNO);
END;
/

UPDATE MENU SET COD_ITEMMENUPAI = (SELECT COD_ITEMMENU FROM ITEMMENU WHERE upper(NME_ITEMMENU) = 'ESTACIONAMENTO' AND COD_ITEMMENU IN (SELECT COD_ITEMMENU FROM MENU WHERE FLG_NOVAINTERFACE = 1))
WHERE COD_ITEMMENU IN (SELECT COD_ITEMMENU FROM ITEMMENU WHERE upper(NME_ITEMMENU) = 'DASHBOARD FREQUÊNCIA E PERMANÊNCIA');

EXEC SPDM_CONTROLEVERSAO ('BD_VERSAO_DASHBOARD_FREQUENCIAESTACIONAMENTO', '10.0.4');

------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------
-- 10.0.5 --------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------------------------------------------
-- INICIO 136871, Fabricio Machado (Principal: 136871) - Dashboard Frequência e Permanência - Calcular total de clientes
----------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE spdm_db_freq_estacionamento
(
	pSESSAO VARCHAR2,
	pCOD_EMPREENDIMENTO INT,
	pDTA_INI VARCHAR2,
	pDTA_FIM VARCHAR2,
	pDIASEMANA VARCHAR2,
	pHORA VARCHAR2,
	pTEMPOPERMANENCIA VARCHAR2,
  RESULTSET OUT SYS_REFCURSOR
)
AS
/*
--> Para filtar o Dia das semana passar no 5º parâmetro os valores: 1 = DOM , 2 = SEG, 3 = TER, 4 = QUAR, 5 = QUI, 6 = SEX, 7 = SAB
--> Para filtrar poo tempo de permanência, passar os valor: ATE_1H, 1H_2H, 2H_3H, 3H_4H, ACIMA_4H

--> Gráfico para cada dia da semana
variable vCUR refcursor
EXEC SPDM_DB_FREQ_ESTACIONAMENTO ('DIASEMANA', '6', '2000-01-01 00:00:00', '2016-12-31 23:59:59', '', '', '', :vCUR);
print vCUR

--> Grafico para Hora do dia, às segundas.
variable vCUR refcursor
EXEC SPDM_DB_FREQ_ESTACIONAMENTO ('HORA', '6', '2000-01-01 00:00:00', '2016-12-31 23:59:59', '2', '', '', :vCUR);
print vCUR

--> Média de permanência, aos sábados, às 15hs, com tempo de permanência de 2 a 3 horas.
variable vCUR refcursor
EXEC SPDM_DB_FREQ_ESTACIONAMENTO ('MEDIA_PERMANENCIA', '6', '2000-01-01 00:00:00', '2016-12-31 23:59:59', '7', '15:00', '2H_3H', :vCUR);
print vCUR


--> Clientes por tempo de permanência, às quintas, ao meio dia.
variable vCUR refcursor
EXEC SPDM_DB_FREQ_ESTACIONAMENTO ('TEMPO_PERMANENCIA', '6', '2000-01-01 00:00:00', '2016-12-31 23:59:59', '5', '12:00', '', :vCUR);
print vCUR
*/
BEGIN
DECLARE
	vQUERY VARCHAR2(8000); vWHERE VARCHAR2(1000); vFROM VARCHAR(1000);
BEGIN
vQUERY := '';

vFROM := '
FROM
	CARTAOESTACIONAMENTO CE
	INNER JOIN TIPOCARTAOESTACIONAMENTO TCE ON (TCE.COD_TIPOCARTAO = CE.COD_TIPOCARTAO)
	INNER JOIN PESSOA_CARTAOESTACIONAMENTO PCE ON (PCE.COD_CARTAO = CE.COD_CARTAO)
	INNER JOIN FREQUENCIAESTACIONAMENTO FE ON (FE.COD_CARTAO = CE.COD_CARTAO AND FE.TMP_PERMANENCIA >= 0)';

-- Filtro por empreendimento (obrigatório).
vWHERE := ' AND TCE.COD_EMPREENDIMENTO = '||pCOD_EMPREENDIMENTO;

-- Filtro por data na frequencia (data de entrada no estacionamento)
vWHERE := vWHERE||' AND FE.DTA_ENTRADA >= to_date('''||pDTA_INI||''',''YYYY-MM-DD HH24:MI:SS'') AND FE.DTA_ENTRADA <= to_date('''||pDTA_FIM||''',''YYYY-MM-DD HH24:MI:SS'')';

-- Filtro por dia da semana
IF pDIASEMANA <> ' ' THEN
	vWHERE := vWHERE||' AND TO_CHAR(FE.DTA_ENTRADA,''D'') = '||pDIASEMANA;
END IF;

-- Filtro por hora.
IF pHORA <> ' ' THEN
	vWHERE := vWHERE||' AND to_char(FE.DTA_ENTRADA,''HH24'') = '||substr(pHORA,1,2);
END IF;

-- Filtro por tempo de permanência.
IF pTEMPOPERMANENCIA = 'ATE_1H' THEN
	vWHERE := vWHERE||' AND trunc(FE.TMP_PERMANENCIA/3600000) = 0';
ELSIF pTEMPOPERMANENCIA = '1H_2H' THEN
	vWHERE := vWHERE||' AND trunc(FE.TMP_PERMANENCIA/3600000) = 1';
ELSIF pTEMPOPERMANENCIA = '2H_3H' THEN
	vWHERE := vWHERE||' AND trunc(FE.TMP_PERMANENCIA/3600000) = 2';
ELSIF pTEMPOPERMANENCIA = '3H_4H' THEN
	vWHERE := vWHERE||' AND trunc(FE.TMP_PERMANENCIA/3600000) = 3';
ELSIF pTEMPOPERMANENCIA = 'ACIMA_4H' THEN
	vWHERE := vWHERE||' AND trunc(FE.TMP_PERMANENCIA/3600000) >= 4';
END IF;


-- Gráfico em pizza ou barras, para cada dia da semana qual a média de frequência
IF pSESSAO = 'DIASEMANA' THEN
vQUERY := 'SELECT
	CASE TO_NUMBER(TO_CHAR(A.DIA,''D'')) WHEN 1 THEN ''Domingo'' WHEN 2 THEN ''Segunda'' WHEN 3 THEN ''Terça'' WHEN 4 THEN ''Quarta'' WHEN 5 THEN ''Quinta''
	WHEN 6 THEN ''Sexta'' WHEN 7 THEN ''Sábado'' END AS "DIA_SEMANA", COUNT(A.DIA) AS "QTDE"
FROM
	(
	SELECT DISTINCT
		COD_PESSOA,to_date(to_char(DTA_ENTRADA,''YYYMMDD''),''YYYMMDD'') AS DIA'||
	vFROM||vWHERE||
	') A
GROUP BY
	TO_CHAR(A.DIA,''D'')
ORDER BY
	TO_NUMBER(TO_CHAR(A.DIA,''D''))';
END IF;

-- GRÁFICO MÉDIA DE FREQUENCIA POR HORA
IF pSESSAO = 'HORA' THEN
vQUERY := 'SELECT
	CASE TO_NUMBER(A.HORA) WHEN 0 THEN ''00:00'' WHEN 1 THEN ''01:00'' WHEN 2 THEN ''02:00'' WHEN 3 THEN ''03:00'' WHEN 4 THEN ''04:00'' WHEN 5 THEN ''05:00'' WHEN 6 THEN ''06:00''
	WHEN 7 THEN ''07:00'' WHEN 8 THEN ''08:00'' WHEN 9 THEN ''09:00'' WHEN 10 THEN ''10:00'' WHEN 11 THEN ''11:00'' WHEN 12 THEN ''12:00'' WHEN 13 THEN ''13:00''
	WHEN 14 THEN ''14:00'' WHEN 15 THEN ''15:00'' WHEN 16 THEN ''16:00'' WHEN 17 THEN ''17:00'' WHEN 18 THEN ''18:00'' WHEN 19 THEN ''19:00'' WHEN 20 THEN ''20:00''
	WHEN 21 THEN ''21:00'' WHEN 22 THEN ''22:00'' WHEN 23 THEN ''23:00'' END AS "HORA", TO_NUMBER(COUNT(*)) AS "QTDE"
FROM
	(
	SELECT DISTINCT
		COD_PESSOA,to_char(DTA_ENTRADA,''YYYYMMDD'') AS "DIA",to_char(DTA_ENTRADA,''HH24'') AS "HORA"'||
	vFROM||vWHERE||
	') A
GROUP BY
	TO_NUMBER(A.HORA)
ORDER BY
	TO_NUMBER(A.HORA)';
END IF;

-- MÉDIA DE PERMANÊNCIA
IF pSESSAO = 'MEDIA_PERMANENCIA' THEN
	vQUERY := 'SELECT TRUNC(AVG(FE.TMP_PERMANENCIA/3600000)),Count(DISTINCT PCE.COD_PESSOA) AS "TOTAL_CLIENTES" '||vFROM||vWHERE;
END IF;

-- CLIENTES POR TEMPO DE PERMANÊNCIA
IF pSESSAO = 'TEMPO_PERMANENCIA' THEN
vQUERY := 'SELECT
	CASE
		WHEN trunc(FE.TMP_PERMANENCIA/3600000) = 0 THEN ''ATE_1H''
	    WHEN trunc(FE.TMP_PERMANENCIA/3600000) = 1 THEN ''1H_2H''
		WHEN trunc(FE.TMP_PERMANENCIA/3600000) = 2 THEN ''2H_3H''
		WHEN trunc(FE.TMP_PERMANENCIA/3600000) = 3 THEN ''3H_4H''
		WHEN trunc(FE.TMP_PERMANENCIA/3600000) >= 4 THEN ''ACIMA_4H''
	END AS "TEMPO",
	TO_NUMBER(COUNT(*)) AS "QTDE"'||
	vFROM||vWHERE||
'GROUP BY
	CASE
		WHEN trunc(FE.TMP_PERMANENCIA/3600000) = 0 THEN ''ATE_1H''
	    WHEN trunc(FE.TMP_PERMANENCIA/3600000) = 1 THEN ''1H_2H''
		WHEN trunc(FE.TMP_PERMANENCIA/3600000) = 2 THEN ''2H_3H''
		WHEN trunc(FE.TMP_PERMANENCIA/3600000) = 3 THEN ''3H_4H''
		WHEN trunc(FE.TMP_PERMANENCIA/3600000) >= 4 THEN ''ACIMA_4H''
	END
ORDER BY 2 DESC';
END IF;

--Dbms_Output.Put_Line(vQUERY);
OPEN RESULTSET FOR vQUERY;
END;
END;
/
----------------------------------------------------------------------------------------------------------------------------------------
-- FIM 136871, Fabricio Machado (Principal: 136871) - Dashboard Frequência e Permanência - Calcular total de clientes
----------------------------------------------------------------------------------------------------------------------------------------

EXEC SPDM_CONTROLEVERSAO ('BD_VERSAO_DASHBOARD_FREQUENCIAESTACIONAMENTO', '10.0.5');

--10.0.6----------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------


--------------------------------------------------------------------------------------------
-- INICIO paulo.casaes, NEWWISEIT-1471, NEWWISEIT-887 Segmentação - poder abrir dashboard
--------------------------------------------------------------------------------------------

DECLARE
  vCOD_VARIVAEL INT;
  BEGIN
  SELECT Count(*) INTO vCOD_VARIVAEL FROM VARIAVEL WHERE NME_VARIAVEL = 'SEGMENTACAO.ID';
  IF vCOD_VARIVAEL = 0 THEN
    INSERT INTO VARIAVEL (COD_VARIAVEL, NME_VARIAVEL, DSC_VARIAVEL, PRT_VARIAVEL) VALUES (21, 'SEGMENTACAO.ID', 'CÓDIGO DA SEGMENTACAO', 'labels.conteudo.parametro.combo.variavel.valor.segmentacao.id');
  END IF;
END;
/


DECLARE
  vCOUNT INT;
BEGIN
SELECT Count(*) INTO vCOUNT FROM USER_TABLES WHERE TABLE_NAME = 'CONTEXTO_CONTEUDO';
IF vCOUNT = 0 THEN
  EXECUTE IMMEDIATE 'CREATE TABLE CONTEXTO_CONTEUDO (  COD_CONTEXTO INTEGER NOT NULL,  COD_CONTEUDO INTEGER NOT NULL,  COD_RECURSO INTEGER NOT NULL,  PRIMARY KEY (COD_CONTEXTO, COD_CONTEUDO))';
  EXECUTE IMMEDIATE 'ALTER TABLE CONTEXTO_CONTEUDO ADD FOREIGN KEY (COD_CONTEXTO) REFERENCES CONTEXTO';
  EXECUTE IMMEDIATE 'ALTER TABLE CONTEXTO_CONTEUDO ADD FOREIGN KEY (COD_CONTEUDO) REFERENCES CONTEUDO';
  EXECUTE IMMEDIATE 'ALTER TABLE CONTEXTO_CONTEUDO ADD FOREIGN KEY (COD_RECURSO) REFERENCES RECURSO';
END IF;
END;
/




DECLARE
  vCOD_CONTEXTO INT;
  vCOD_CONTEUDO INT;
  vCOD_VARIAVEL INT;
  vCOD_PARAMETRO INT;
  vCOD_RECURSO INT;
BEGIN
  SELECT COD_CONTEUDO INTO vCOD_CONTEUDO FROM CONTEUDO WHERE NME_CONTEUDO like  'DASHBOARD FREQUÊNCIA E PERMANÊNCIA';
  SELECT COD_VARIAVEL INTO vCOD_VARIAVEL FROM VARIAVEL WHERE NME_VARIAVEL like  'SEGMENTACAO.ID';
  SELECT COD_RECURSO INTO vCOD_RECURSO FROM ITEMMENU WHERE COD_CONTEUDO = vCOD_CONTEUDO;
  SELECT COD_CONTEXTO INTO vCOD_CONTEXTO FROM CONTEXTO WHERE NME_CONTEXTO like 'CLIENTE';
  spdm_getnextid ('PARAMETRO', 'COD_PARAMETRO', vCOD_PARAMETRO);
  INSERT INTO PARAMETRO (COD_PARAMETRO, COD_CONTEUDO, COD_VARIAVEL, NME_PARAMETRO) VALUES (vCOD_PARAMETRO, vCOD_CONTEUDO, vCOD_VARIAVEL, 'codSegmentacao');
  INSERT INTO CONTEXTO_CONTEUDO (COD_CONTEXTO, COD_CONTEUDO, COD_RECURSO) values (vCOD_CONTEXTO, vCOD_CONTEUDO, vCOD_RECURSO);
END;
/

--------------------------------------------------------------------------------------------
-- FIM paulo.casaes, NEWWISEIT-1471, NEWWISEIT-887 Segmentação - poder abrir dashboard
--------------------------------------------------------------------------------------------


EXEC SPDM_CONTROLEVERSAO ('BD_VERSAO_DASHBOARD_FREQUENCIAESTACIONAMENTO', '10.0.6');

------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------


--10.0.7----------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- INICIO - 137401, Fabricio Machado (Principal: 137400) - Novo filtro de segmentação no dashboard de FREQUENCIA ESTACIONAMENTO (procedure)
-- INICIO - 137905, Fabricio Machado (Principal: 137872) - Dashboard Frequência Estacionamento - exibir segmentação, está exibidno a média errada e contando cliente onde seria frequencia
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE spdm_db_freq_estacionamento
(
	pSESSAO VARCHAR2,
	pCOD_EMPREENDIMENTO INT,
	pDTA_INI VARCHAR2,
	pDTA_FIM VARCHAR2,
	pDIASEMANA VARCHAR2,
	pHORA VARCHAR2,
	pTEMPOPERMANENCIA VARCHAR2,
  pCOD_SEGMENTACAO VARCHAR2,
  RESULTSET OUT SYS_REFCURSOR
)
AS
/*
--> Para filtar o Dia das semana passar no 5º parâmetro os valores: 1 = DOM , 2 = SEG, 3 = TER, 4 = QUAR, 5 = QUI, 6 = SEX, 7 = SAB
--> Para filtrar poo tempo de permanência, passar os valor: ATE_1H, 1H_2H, 2H_3H, 3H_4H, ACIMA_4H

--> Gráfico para cada dia da semana
EXEC SPDM_DB_FREQ_ESTACIONAMENTO ('DIASEMANA','2','2017-01-01','2017-02-23','','','','');

--> Grafico para Hora do dia, às segundas.
EXEC SPDM_DB_FREQ_ESTACIONAMENTO ('HORA','2','2017-01-01','2017-02-23','','','','');

--> Média de permanência, aos sábados, às 15hs, com tempo de permanência de 2 a 3 horas.
EXEC SPDM_DB_FREQ_ESTACIONAMENTO ('MEDIA_PERMANENCIA', '6', '2000-01-01 00:00:00', '2016-12-31 23:59:59', '7', '15:00', '2H_3H', :vCUR);

--> Clientes por tempo de permanência, às quintas, ao meio dia.
variable vCUR refcursor
EXEC SPDM_DB_FREQ_ESTACIONAMENTO ('TEMPO_PERMANENCIA', '6', '2000-01-01 00:00:00', '2016-12-31 23:59:59', '5', '12:00', '', :vCUR);
print vCUR
*/
BEGIN
DECLARE
	vQUERY VARCHAR2(8000); vWHERE VARCHAR2(4000); vFROM VARCHAR(1000); vSQL_SEGMENTACAO VARCHAR2(4000);
BEGIN
vQUERY := '';

vFROM := '
FROM
	CARTAOESTACIONAMENTO CE
	INNER JOIN TIPOCARTAOESTACIONAMENTO TCE ON (TCE.COD_TIPOCARTAO = CE.COD_TIPOCARTAO)
	INNER JOIN PESSOA_CARTAOESTACIONAMENTO PCE ON (PCE.COD_CARTAO = CE.COD_CARTAO)
	INNER JOIN FREQUENCIAESTACIONAMENTO FE ON (FE.COD_CARTAO = CE.COD_CARTAO AND FE.TMP_PERMANENCIA >= 0)';

-- Filtro por empreendimento (obrigatório).
vWHERE := ' AND TCE.COD_EMPREENDIMENTO = '||pCOD_EMPREENDIMENTO;

-- Filtro por data na frequencia (data de entrada no estacionamento)
vWHERE := vWHERE||' AND FE.DTA_ENTRADA >= to_date('''||pDTA_INI||''',''YYYY-MM-DD HH24:MI:SS'') AND FE.DTA_ENTRADA <= to_date('''||pDTA_FIM||''',''YYYY-MM-DD HH24:MI:SS'')';

-- Filtro por dia da semana
IF pDIASEMANA <> ' ' THEN
	vWHERE := vWHERE||' AND TO_CHAR(FE.DTA_ENTRADA,''D'') = '||pDIASEMANA;
END IF;

-- Filtro por hora.
IF pHORA <> ' ' THEN
	vWHERE := vWHERE||' AND to_char(FE.DTA_ENTRADA,''HH24'') = '||substr(pHORA,1,2);
END IF;

-- Filtro por tempo de permanência.
IF pTEMPOPERMANENCIA = 'ATE_1H' THEN
	vWHERE := vWHERE||' AND trunc(FE.TMP_PERMANENCIA/3600000) = 0';
ELSIF pTEMPOPERMANENCIA = '1H_2H' THEN
	vWHERE := vWHERE||' AND trunc(FE.TMP_PERMANENCIA/3600000) = 1';
ELSIF pTEMPOPERMANENCIA = '2H_3H' THEN
	vWHERE := vWHERE||' AND trunc(FE.TMP_PERMANENCIA/3600000) = 2';
ELSIF pTEMPOPERMANENCIA = '3H_4H' THEN
	vWHERE := vWHERE||' AND trunc(FE.TMP_PERMANENCIA/3600000) = 3';
ELSIF pTEMPOPERMANENCIA = 'ACIMA_4H' THEN
	vWHERE := vWHERE||' AND trunc(FE.TMP_PERMANENCIA/3600000) >= 4';
END IF;

-- Filtro por segmentação
IF pCOD_SEGMENTACAO <> ' ' THEN
  SELECT SubStr(REPLACE(SQL_SEGMENTACAO,'COUNT( DISTINCT PESSOAFISICA.COD_PESSOA ) 	 AS "QTD_ROWS"','DISTINCT PESSOAFISICA.COD_PESSOA'),1,4000)
  INTO vSQL_SEGMENTACAO
  FROM SEGMENTACAO WHERE COD_SEGMENTACAO = pCOD_SEGMENTACAO;
	vWHERE := vWHERE||' AND PCE.COD_PESSOA IN ('||vSQL_SEGMENTACAO||')';
END IF;

-- Gráfico em pizza ou barras, para cada dia da semana qual a média de frequência
IF pSESSAO = 'DIASEMANA' THEN
vQUERY := 'SELECT
	CASE TO_NUMBER(TO_CHAR(FE.DTA_ENTRADA,''D'')) WHEN 1 THEN ''Domingo'' WHEN 2 THEN ''Segunda'' WHEN 3 THEN ''Terça'' WHEN 4 THEN ''Quarta'' WHEN 5 THEN ''Quinta''
	WHEN 6 THEN ''Sexta'' WHEN 7 THEN ''Sábado'' END AS "DIA_SEMANA", COUNT(PCE.COD_PESSOA) AS "QTDE"'||
	vFROM||vWHERE||
  ' GROUP BY
    to_char(DTA_ENTRADA,''D'')
  ORDER BY
	  to_char(DTA_ENTRADA,''D'')';
END IF;

-- GRÁFICO MÉDIA DE FREQUENCIA POR HORA
IF pSESSAO = 'HORA' THEN
vQUERY := 'SELECT
	CASE TO_NUMBER(to_char(DTA_ENTRADA,''HH24'')) WHEN 0 THEN ''00:00'' WHEN 1 THEN ''01:00'' WHEN 2 THEN ''02:00'' WHEN 3 THEN ''03:00'' WHEN 4 THEN ''04:00'' WHEN 5 THEN ''05:00'' WHEN 6 THEN ''06:00''
	WHEN 7 THEN ''07:00'' WHEN 8 THEN ''08:00'' WHEN 9 THEN ''09:00'' WHEN 10 THEN ''10:00'' WHEN 11 THEN ''11:00'' WHEN 12 THEN ''12:00'' WHEN 13 THEN ''13:00''
	WHEN 14 THEN ''14:00'' WHEN 15 THEN ''15:00'' WHEN 16 THEN ''16:00'' WHEN 17 THEN ''17:00'' WHEN 18 THEN ''18:00'' WHEN 19 THEN ''19:00'' WHEN 20 THEN ''20:00''
	WHEN 21 THEN ''21:00'' WHEN 22 THEN ''22:00'' WHEN 23 THEN ''23:00'' END AS "HORA", TO_NUMBER(Count(PCE.COD_PESSOA)) AS "QTDE"'||
	vFROM||vWHERE||
  ' GROUP BY
    to_char(DTA_ENTRADA,''HH24'')
  ORDER BY
    TO_NUMBER(to_char(DTA_ENTRADA,''HH24''))';
END IF;

-- MÉDIA DE PERMANÊNCIA
IF pSESSAO = 'MEDIA_PERMANENCIA' THEN
	vQUERY := 'SELECT SubStr(func_RETORNATEMPO(trunc(sum(trunc((((DTA_SAIDA) - (DTA_ENTRADA)) * 24 * 60 * 60)))/Count(*))),1,5), Count(DISTINCT PCE.COD_PESSOA) AS "TOTAL_CLIENTES" '||vFROM||vWHERE;
END IF;

-- CLIENTES POR TEMPO DE PERMANÊNCIA
IF pSESSAO = 'TEMPO_PERMANENCIA' THEN
vQUERY := 'SELECT
	CASE
		WHEN trunc(FE.TMP_PERMANENCIA/3600000) = 0 THEN ''ATE_1H''
	    WHEN trunc(FE.TMP_PERMANENCIA/3600000) = 1 THEN ''1H_2H''
		WHEN trunc(FE.TMP_PERMANENCIA/3600000) = 2 THEN ''2H_3H''
		WHEN trunc(FE.TMP_PERMANENCIA/3600000) = 3 THEN ''3H_4H''
		WHEN trunc(FE.TMP_PERMANENCIA/3600000) >= 4 THEN ''ACIMA_4H''
	END AS "TEMPO",
	TO_NUMBER(COUNT(*)) AS "QTDE"'||
	vFROM||vWHERE||
'GROUP BY
	CASE
		WHEN trunc(FE.TMP_PERMANENCIA/3600000) = 0 THEN ''ATE_1H''
	    WHEN trunc(FE.TMP_PERMANENCIA/3600000) = 1 THEN ''1H_2H''
		WHEN trunc(FE.TMP_PERMANENCIA/3600000) = 2 THEN ''2H_3H''
		WHEN trunc(FE.TMP_PERMANENCIA/3600000) = 3 THEN ''3H_4H''
		WHEN trunc(FE.TMP_PERMANENCIA/3600000) >= 4 THEN ''ACIMA_4H''
	END
ORDER BY 2 DESC';
END IF;

--Dbms_Output.Put_Line(vQUERY);
OPEN RESULTSET FOR vQUERY;
END;
END;
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FIM - 137401, Fabricio Machado (Principal: 137400) - Novo filtro de segmentação no dashboard de FREQUENCIA ESTACIONAMENTO (procedure)
-- FIM - 137905, Fabricio Machado (Principal: 137872) - Dashboard Frequência Estacionamento - exibir segmentação, está exibidno a média errada e contando cliente onde seria frequencia
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

EXEC SPDM_CONTROLEVERSAO ('BD_VERSAO_DASHBOARD_FREQUENCIAESTACIONAMENTO', '10.0.7');

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
------------------------------------------------------------------------------------------------------------------------------------------------
-- FIM - WISEIT-1559 - Fabricio - Dashboard de Estacionamento - corrigir nomenclaturas
------------------------------------------------------------------------------------------------------------------------------------------------

EXEC SPDM_CONTROLEVERSAO ('BD_VERSAO_DASHBOARD_FREQUENCIAESTACIONAMENTO', '10.0.8');

------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------

--10.0.9----------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------------------
-- INICIO - Fabricio - WISEIT-3798 Dashboard Estacionamento - não está incluindo a data "até"
----------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE spdm_db_freq_estacionamento
(
	pSECAO VARCHAR2,
	pCOD_EMPREENDIMENTO INT,
	pDTA_INI VARCHAR2,
	pDTA_FIM VARCHAR2,
	pDIASEMANA VARCHAR2,
	pHORA VARCHAR2,
	pTEMPOPERMANENCIA VARCHAR2,
  pCOD_SEGMENTACAO VARCHAR2,
  RESULTSET OUT SYS_REFCURSOR
)
AS
/*
--> Para filtar o Dia das semana passar no 5º parâmetro os valores: 1 = DOM , 2 = SEG, 3 = TER, 4 = QUAR, 5 = QUI, 6 = SEX, 7 = SAB
--> Para filtrar poo tempo de permanência, passar os valor: ATE_1H, 1H_2H, 2H_3H, 3H_4H, ACIMA_4H

--> Gráfico para cada dia da semana
EXEC SPDM_DB_FREQ_ESTACIONAMENTO ('DIASEMANA','2','2017-01-01','2017-02-23','','','','');

--> Grafico para Hora do dia, às segundas.
EXEC SPDM_DB_FREQ_ESTACIONAMENTO ('HORA','2','2017-01-01','2017-02-23','','','','');

--> Média de permanência, aos sábados, às 15hs, com tempo de permanência de 2 a 3 horas.
EXEC SPDM_DB_FREQ_ESTACIONAMENTO ('MEDIA_PERMANENCIA', '6', '2000-01-01 00:00:00', '2016-12-31 23:59:59', '7', '15:00', '2H_3H', :vCUR);

--> Clientes por tempo de permanência, às quintas, ao meio dia.
variable vCUR refcursor
EXEC SPDM_DB_FREQ_ESTACIONAMENTO ('TEMPO_PERMANENCIA','6','2000-01-01','2016-12-31','','', '','',:vCUR);
print vCUR
*/
BEGIN
DECLARE
	vQUERY VARCHAR2(8000); vWHERE VARCHAR2(4000); vFROM VARCHAR(1000); vSQL_SEGMENTACAO VARCHAR2(4000);
BEGIN
vQUERY := '';

vFROM := '
FROM
	CARTAOESTACIONAMENTO CE
	INNER JOIN TIPOCARTAOESTACIONAMENTO TCE ON (TCE.COD_TIPOCARTAO = CE.COD_TIPOCARTAO)
	INNER JOIN PESSOA_CARTAOESTACIONAMENTO PCE ON (PCE.COD_CARTAO = CE.COD_CARTAO)
	INNER JOIN FREQUENCIAESTACIONAMENTO FE ON (FE.COD_CARTAO = CE.COD_CARTAO AND FE.TMP_PERMANENCIA >= 0)';

-- Filtro por empreendimento (obrigatório).
vWHERE := ' AND TCE.COD_EMPREENDIMENTO = '||pCOD_EMPREENDIMENTO;

-- Filtro por data na frequencia (data de entrada no estacionamento)
vWHERE := vWHERE||' AND FE.DTA_ENTRADA >= to_date('''||pDTA_INI||' 00:00:00'',''YYYY-MM-DD HH24:MI:SS'') AND FE.DTA_ENTRADA <= to_date('''||pDTA_FIM||' 23:59:59'',''YYYY-MM-DD HH24:MI:SS'')';

-- Filtro por dia da semana
IF pDIASEMANA <> ' ' THEN
	vWHERE := vWHERE||' AND TO_CHAR(FE.DTA_ENTRADA,''D'') = '||pDIASEMANA;
END IF;

-- Filtro por hora.
IF pHORA <> ' ' THEN
	vWHERE := vWHERE||' AND to_char(FE.DTA_ENTRADA,''HH24'') = '||substr(pHORA,1,2);
END IF;

-- Filtro por tempo de permanência.
IF pTEMPOPERMANENCIA = 'ATE_1H' THEN
	vWHERE := vWHERE||' AND trunc(FE.TMP_PERMANENCIA/3600000) = 0';
ELSIF pTEMPOPERMANENCIA = '1H_2H' THEN
	vWHERE := vWHERE||' AND trunc(FE.TMP_PERMANENCIA/3600000) = 1';
ELSIF pTEMPOPERMANENCIA = '2H_3H' THEN
	vWHERE := vWHERE||' AND trunc(FE.TMP_PERMANENCIA/3600000) = 2';
ELSIF pTEMPOPERMANENCIA = '3H_4H' THEN
	vWHERE := vWHERE||' AND trunc(FE.TMP_PERMANENCIA/3600000) = 3';
ELSIF pTEMPOPERMANENCIA = 'ACIMA_4H' THEN
	vWHERE := vWHERE||' AND trunc(FE.TMP_PERMANENCIA/3600000) >= 4';
END IF;

-- Filtro por segmentação
IF pCOD_SEGMENTACAO <> ' ' THEN
  SELECT SubStr(REPLACE(SQL_SEGMENTACAO,'COUNT( DISTINCT PESSOAFISICA.COD_PESSOA ) 	 AS "QTD_ROWS"','DISTINCT PESSOAFISICA.COD_PESSOA'),1,4000)
  INTO vSQL_SEGMENTACAO
  FROM SEGMENTACAO WHERE COD_SEGMENTACAO = pCOD_SEGMENTACAO;
	vWHERE := vWHERE||' AND PCE.COD_PESSOA IN ('||vSQL_SEGMENTACAO||')';
END IF;

-- Gráfico em pizza ou barras, para cada dia da semana qual a média de frequência
IF pSECAO = 'DIASEMANA' THEN
vQUERY := 'SELECT
	CASE TO_NUMBER(TO_CHAR(FE.DTA_ENTRADA,''D'')) WHEN 1 THEN ''Domingo'' WHEN 2 THEN ''Segunda'' WHEN 3 THEN ''Terça'' WHEN 4 THEN ''Quarta'' WHEN 5 THEN ''Quinta''
	WHEN 6 THEN ''Sexta'' WHEN 7 THEN ''Sábado'' END AS "DIA_SEMANA", COUNT(PCE.COD_PESSOA) AS "QTDE"'||
	vFROM||vWHERE||
  ' GROUP BY
    to_char(DTA_ENTRADA,''D'')
  ORDER BY
	  to_char(DTA_ENTRADA,''D'')';
END IF;

-- GRÁFICO MÉDIA DE FREQUENCIA POR HORA
IF pSECAO = 'HORA' THEN
vQUERY := 'SELECT
	CASE TO_NUMBER(to_char(DTA_ENTRADA,''HH24'')) WHEN 0 THEN ''00:00'' WHEN 1 THEN ''01:00'' WHEN 2 THEN ''02:00'' WHEN 3 THEN ''03:00'' WHEN 4 THEN ''04:00'' WHEN 5 THEN ''05:00'' WHEN 6 THEN ''06:00''
	WHEN 7 THEN ''07:00'' WHEN 8 THEN ''08:00'' WHEN 9 THEN ''09:00'' WHEN 10 THEN ''10:00'' WHEN 11 THEN ''11:00'' WHEN 12 THEN ''12:00'' WHEN 13 THEN ''13:00''
	WHEN 14 THEN ''14:00'' WHEN 15 THEN ''15:00'' WHEN 16 THEN ''16:00'' WHEN 17 THEN ''17:00'' WHEN 18 THEN ''18:00'' WHEN 19 THEN ''19:00'' WHEN 20 THEN ''20:00''
	WHEN 21 THEN ''21:00'' WHEN 22 THEN ''22:00'' WHEN 23 THEN ''23:00'' END AS "HORA", TO_NUMBER(Count(PCE.COD_PESSOA)) AS "QTDE"'||
	vFROM||vWHERE||
  ' GROUP BY
    to_char(DTA_ENTRADA,''HH24'')
  ORDER BY
    TO_NUMBER(to_char(DTA_ENTRADA,''HH24''))';
END IF;

-- MÉDIA DE PERMANÊNCIA
IF pSECAO = 'MEDIA_PERMANENCIA' THEN
	vQUERY := 'SELECT SubStr(func_RETORNATEMPO(trunc(sum(trunc((((DTA_SAIDA) - (DTA_ENTRADA)) * 24 * 60 * 60)))/Count(*))),1,5), Count(DISTINCT PCE.COD_PESSOA) AS "TOTAL_CLIENTES" '||vFROM||vWHERE;
END IF;

-- CLIENTES POR TEMPO DE PERMANÊNCIA
IF pSECAO = 'TEMPO_PERMANENCIA' THEN
vQUERY := 'SELECT
	CASE
		WHEN trunc(FE.TMP_PERMANENCIA/3600000) = 0 THEN ''ATE_1H''
	    WHEN trunc(FE.TMP_PERMANENCIA/3600000) = 1 THEN ''1H_2H''
		WHEN trunc(FE.TMP_PERMANENCIA/3600000) = 2 THEN ''2H_3H''
		WHEN trunc(FE.TMP_PERMANENCIA/3600000) = 3 THEN ''3H_4H''
		WHEN trunc(FE.TMP_PERMANENCIA/3600000) >= 4 THEN ''ACIMA_4H''
	END AS "TEMPO",
	TO_NUMBER(COUNT(*)) AS "QTDE"'||
	vFROM||vWHERE||
'GROUP BY
	CASE
		WHEN trunc(FE.TMP_PERMANENCIA/3600000) = 0 THEN ''ATE_1H''
	    WHEN trunc(FE.TMP_PERMANENCIA/3600000) = 1 THEN ''1H_2H''
		WHEN trunc(FE.TMP_PERMANENCIA/3600000) = 2 THEN ''2H_3H''
		WHEN trunc(FE.TMP_PERMANENCIA/3600000) = 3 THEN ''3H_4H''
		WHEN trunc(FE.TMP_PERMANENCIA/3600000) >= 4 THEN ''ACIMA_4H''
	END
ORDER BY 2 DESC';
END IF;

--Dbms_Output.Put_Line(vQUERY);
OPEN RESULTSET FOR vQUERY;
END;
END;
/
----------------------------------------------------------------------------------------------------------------
-- FIM - Fabricio - WISEIT-3798 Dashboard Estacionamento - não está incluindo a data "até"
----------------------------------------------------------------------------------------------------------------

EXEC SPDM_CONTROLEVERSAO ('BD_VERSAO_DASHBOARD_FREQUENCIAESTACIONAMENTO', '10.0.9');

------------------------------------------------------------------------------------------------------------------------------------------------------
-- 10.0.10 --------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------------------------------------------
-- INICIO - Fabricio - WISEIT-3889 Dashboards - acrescentar botão de segmentação
-- INICIO - Fabricio - WISEIT-3954 Dashboards - botão de salvar segmentação não tem opção de salvar o ranking e a segmentação não mostra o total
-- INICIO - FABRICIO - WISEIT-4367 - Banco - Estacionamento - API para receber frequência
----------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE spdm_db_freq_estacionamento
(
	pSECAO VARCHAR2,
	pCOD_EMPREENDIMENTO INT,
	pDTA_INI VARCHAR2,
	pDTA_FIM VARCHAR2,
	pDIASEMANA VARCHAR2,
	pHORA VARCHAR2,
	pTEMPOPERMANENCIA VARCHAR2,
  pCOD_SEGMENTACAO VARCHAR2,
	pNME_SEGMENTACAO VARCHAR2,
	pCOD_VISIBILIDADE VARCHAR2, -- 'PA', 'PC', 'PR'
	pCOD_USUARIO VARCHAR2,
  RESULTSET OUT SYS_REFCURSOR

)
AS
/*
--> Para filtar o Dia das semana passar no 5º parâmetro os valores: 1 = DOM , 2 = SEG, 3 = TER, 4 = QUAR, 5 = QUI, 6 = SEX, 7 = SAB
--> Para filtrar poo tempo de permanência, passar os valor: ATE_1H, 1H_2H, 2H_3H, 3H_4H, ACIMA_4H

--> Gravar segmentação
variable vCUR refcursor
EXEC SPDM_DB_FREQ_ESTACIONAMENTO ('SEGMENTACAO','4','2015-01-01','2015-02-23','','','','','SEG TESTE','PA','1',:vCUR);
print vCUR

--> Gráfico para cada dia da semana
variable vCUR refcursor
EXEC SPDM_DB_FREQ_ESTACIONAMENTO ('DIASEMANA','2','2015-01-01','2018-10-23','','','','','','','',:vCUR);
print vCUR

--> Grafico para Hora do dia, às segundas.
variable vCUR refcursor
EXEC SPDM_DB_FREQ_ESTACIONAMENTO ('HORA','2','2015-01-01','2018-10-23','','','','','','','',:vCUR);
print vCUR

--> Média de permanência, aos sábados, às 15hs, com tempo de permanência de 2 a 3 horas.
variable vCUR refcursor
EXEC SPDM_DB_FREQ_ESTACIONAMENTO ('MEDIA_PERMANENCIA','2','2015-01-01','2018-10-23','','','','','','','',:vCUR);
print vCUR

--> Clientes por tempo de permanência
variable vCUR refcursor
EXEC SPDM_DB_FREQ_ESTACIONAMENTO ('TEMPO_PERMANENCIA','2','2000-01-01','2018-12-31','','','','','','','',:vCUR);
print vCUR
*/
BEGIN
DECLARE
	vQUERY VARCHAR2(8000); vWHERE VARCHAR2(4000); vFROM VARCHAR(1000); vSQL_SEGMENTACAO VARCHAR2(4000);
  vDSC_SEGMENTACAO VARCHAR2(8000); vCOD_SEGMENTACAO INT; vCOD_CONTEXTO INT; vCOD_VISIBILIDADE VARCHAR2(2);
BEGIN

vQUERY := ' ';

vFROM := '
FROM
	FREQUENCIAESTACIONAMENTO FE';
   
vWHERE := '
WHERE
  FE.TMP_PERMANENCIA >= 0 AND FE.COD_PESSOA > 0 AND FE.COD_EMPREENDIMENTO = '||pCOD_EMPREENDIMENTO;

-- Filtro por data na frequencia (data de entrada no estacionamento)
vWHERE := vWHERE||' AND FE.DTA_ENTRADA >= to_date('''||pDTA_INI||' 00:00:00'',''YYYY-MM-DD HH24:MI:SS'') AND FE.DTA_ENTRADA <= to_date('''||pDTA_FIM||' 23:59:59'',''YYYY-MM-DD HH24:MI:SS'')';

-- Filtro por dia da semana
IF pDIASEMANA <> ' ' THEN
	vWHERE := vWHERE||' AND TO_CHAR(FE.DTA_ENTRADA,''D'') = '||pDIASEMANA;
END IF;

-- Filtro por hora.
IF pHORA <> ' ' THEN
	vWHERE := vWHERE||' AND to_char(FE.DTA_ENTRADA,''HH24'') = '||substr(pHORA,1,2);
END IF;

-- Filtro por tempo de permanência.
IF pTEMPOPERMANENCIA = 'ATE_1H' THEN
	vWHERE := vWHERE||' AND trunc(FE.TMP_PERMANENCIA/3600000) = 0';
ELSIF pTEMPOPERMANENCIA = '1H_2H' THEN
	vWHERE := vWHERE||' AND trunc(FE.TMP_PERMANENCIA/3600000) = 1';
ELSIF pTEMPOPERMANENCIA = '2H_3H' THEN
	vWHERE := vWHERE||' AND trunc(FE.TMP_PERMANENCIA/3600000) = 2';
ELSIF pTEMPOPERMANENCIA = '3H_4H' THEN
	vWHERE := vWHERE||' AND trunc(FE.TMP_PERMANENCIA/3600000) = 3';
ELSIF pTEMPOPERMANENCIA = 'ACIMA_4H' THEN
	vWHERE := vWHERE||' AND trunc(FE.TMP_PERMANENCIA/3600000) >= 4';
END IF;

-- Filtro por segmentação
IF pCOD_SEGMENTACAO <> ' ' THEN
  SELECT SubStr(REPLACE(SQL_SEGMENTACAO,'COUNT( DISTINCT PESSOAFISICA.COD_PESSOA ) 	 AS "QTD_ROWS"','DISTINCT PESSOAFISICA.COD_PESSOA'),1,4000)
  INTO vSQL_SEGMENTACAO
  FROM SEGMENTACAO WHERE COD_SEGMENTACAO = pCOD_SEGMENTACAO;
	vWHERE := vWHERE||' AND FE.COD_PESSOA IN ('||vSQL_SEGMENTACAO||')';
END IF;

-- Gráfico em pizza ou barras, para cada dia da semana qual a média de frequência
IF pSECAO = 'DIASEMANA' THEN
vQUERY := 'SELECT
	CASE TO_NUMBER(TO_CHAR(FE.DTA_ENTRADA,''D'')) WHEN 1 THEN ''Domingo'' WHEN 2 THEN ''Segunda'' WHEN 3 THEN ''Terça'' WHEN 4 THEN ''Quarta'' WHEN 5 THEN ''Quinta''
	WHEN 6 THEN ''Sexta'' WHEN 7 THEN ''Sábado'' END AS "DIA_SEMANA", COUNT(FE.COD_PESSOA) AS "QTDE"'||
	vFROM||vWHERE||
  ' GROUP BY
    to_char(DTA_ENTRADA,''D'')
  ORDER BY
	  to_char(DTA_ENTRADA,''D'')';
END IF;

-- GRÁFICO MÉDIA DE FREQUENCIA POR HORA
IF pSECAO = 'HORA' THEN
vQUERY := 'SELECT
	CASE TO_NUMBER(to_char(DTA_ENTRADA,''HH24'')) WHEN 0 THEN ''00:00'' WHEN 1 THEN ''01:00'' WHEN 2 THEN ''02:00'' WHEN 3 THEN ''03:00'' WHEN 4 THEN ''04:00'' WHEN 5 THEN ''05:00'' WHEN 6 THEN ''06:00''
	WHEN 7 THEN ''07:00'' WHEN 8 THEN ''08:00'' WHEN 9 THEN ''09:00'' WHEN 10 THEN ''10:00'' WHEN 11 THEN ''11:00'' WHEN 12 THEN ''12:00'' WHEN 13 THEN ''13:00''
	WHEN 14 THEN ''14:00'' WHEN 15 THEN ''15:00'' WHEN 16 THEN ''16:00'' WHEN 17 THEN ''17:00'' WHEN 18 THEN ''18:00'' WHEN 19 THEN ''19:00'' WHEN 20 THEN ''20:00''
	WHEN 21 THEN ''21:00'' WHEN 22 THEN ''22:00'' WHEN 23 THEN ''23:00'' END AS "HORA", TO_NUMBER(Count(FE.COD_PESSOA)) AS "QTDE"'||
	vFROM||vWHERE||
  ' GROUP BY
    to_char(DTA_ENTRADA,''HH24'')
  ORDER BY
    TO_NUMBER(to_char(DTA_ENTRADA,''HH24''))';
END IF;

-- MÉDIA DE PERMANÊNCIA
IF pSECAO = 'MEDIA_PERMANENCIA' THEN
	vQUERY := 'SELECT SubStr(func_RETORNATEMPO(trunc(sum(trunc((((DTA_SAIDA) - (DTA_ENTRADA)) * 24 * 60 * 60)))/Count(*))),1,5), Count(DISTINCT FE.COD_PESSOA) AS "TOTAL_CLIENTES" '||vFROM||vWHERE;
END IF;

-- CLIENTES POR TEMPO DE PERMANÊNCIA
IF pSECAO = 'TEMPO_PERMANENCIA' THEN
vQUERY := 'SELECT
	CASE
		WHEN trunc(FE.TMP_PERMANENCIA/3600000) = 0 THEN ''ATE_1H''
	    WHEN trunc(FE.TMP_PERMANENCIA/3600000) = 1 THEN ''1H_2H''
		WHEN trunc(FE.TMP_PERMANENCIA/3600000) = 2 THEN ''2H_3H''
		WHEN trunc(FE.TMP_PERMANENCIA/3600000) = 3 THEN ''3H_4H''
		WHEN trunc(FE.TMP_PERMANENCIA/3600000) >= 4 THEN ''ACIMA_4H''
	END AS "TEMPO",
	TO_NUMBER(COUNT(*)) AS "QTDE"'||
	vFROM||vWHERE||
'GROUP BY
	CASE
		WHEN trunc(FE.TMP_PERMANENCIA/3600000) = 0 THEN ''ATE_1H''
	    WHEN trunc(FE.TMP_PERMANENCIA/3600000) = 1 THEN ''1H_2H''
		WHEN trunc(FE.TMP_PERMANENCIA/3600000) = 2 THEN ''2H_3H''
		WHEN trunc(FE.TMP_PERMANENCIA/3600000) = 3 THEN ''3H_4H''
		WHEN trunc(FE.TMP_PERMANENCIA/3600000) >= 4 THEN ''ACIMA_4H''
	END
ORDER BY 2 DESC';
END IF;

-- Segmentação
SELECT COD_CONTEXTO INTO vCOD_CONTEXTO FROM CONTEXTO WHERE NME_CONTEXTO = 'CLIENTE' AND FLG_ATIVO = 1;
IF pSECAO = 'SEGMENTACAO' AND nvl(pNME_SEGMENTACAO,' ') <> ' ' AND vCOD_CONTEXTO > 0 THEN
	IF nvl(pCOD_VISIBILIDADE,' ') = ' ' THEN
		vCOD_VISIBILIDADE := 'PA';
	ELSE
		vCOD_VISIBILIDADE := pCOD_VISIBILIDADE;
  END IF;

	vQUERY := 'SELECT DISTINCT FE.COD_PESSOA';

	SPDM_GETNEXTID ('SEGMENTACAO','COD_SEGMENTACAO',vCOD_SEGMENTACAO);
	INSERT INTO SEGMENTACAO(COD_SEGMENTACAO,COD_CONTEXTO,NME_SEGMENTACAO,DSC_SEGMENTACAO,SQL_SEGMENTACAO,COD_USUARIOCADASTRO,
    DTA_CADASTRO,FLG_AUTOMATICA,COD_EMPREENDIMENTO,COD_VISIBILIDADE,FLG_WIZARD)
	VALUES(vCOD_SEGMENTACAO, vCOD_CONTEXTO, PNME_SEGMENTACAO, vDSC_SEGMENTACAO, vQUERY||' '||vFROM||' '||vWHERE, pCOD_USUARIO,
    SYSDATE, 0, pCOD_EMPREENDIMENTO, vCOD_VISIBILIDADE, 0);

	EXECUTE IMMEDIATE ('INSERT INTO SEGMENTACAORESULTADO(COD_RESULTADO,COD_SEGMENTACAO) '||vQUERY||','||vCOD_SEGMENTACAO||' '||vFROM||' '||vWHERE);

	-- Grava a quantidade de clientes na segmentação salva
	UPDATE
		SEGMENTACAO
	SET
		NUM_QUANTIDADE = (SELECT COUNT(*) FROM SEGMENTACAORESULTADO WHERE COD_SEGMENTACAO = vCOD_SEGMENTACAO)
	WHERE
		COD_SEGMENTACAO = vCOD_SEGMENTACAO;

	vQUERY := 'SELECT TO_NUMBER('||vCOD_SEGMENTACAO||') AS "COD_SEGMENTACAO" FROM DUAL';
END IF;

Dbms_Output.Put_Line(vQUERY);
OPEN RESULTSET FOR vQUERY;
END;
END;
/
---------------------------------------------------------------------------------------------------------------------------------------
-- FIM - Fabricio - WISEIT-3889 Dashboards - acrescentar botão de segmentação
-- FIM - Fabricio - WISEIT-3954 Dashboards - botão de salvar segmentação não tem opção de salvar o ranking e a segmentação não mostra o total
-- FIM - FABRICIO - WISEIT-4367 - Banco - Estacionamento - API para receber frequência
----------------------------------------------------------------------------------------------------------------------------------------

EXEC SPDM_CONTROLEVERSAO ('BD_VERSAO_DASHBOARD_FREQUENCIAESTACIONAMENTO', '10.0.10');
/

------------------------------------------------------------------------------------------------------------------------------------------------------
-- 10.0.11 --------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- INICIO - JOELSON - WISEIT-4805 / WISEIT-4864 Dashboard Estacionamento - padronizar dia de semana e hora, colocar mapa de dia x hora, tabela de clientes
-- INICIO - Fabricio - WISEIT-4826 Dashboard Clientes - poder analisar sem filtro de datas e abrir a partir de outros dashboards - WISEIT-5029 Dashboar Clientes - Procedure
-- INICIO - Fabricio - WISEIT-1468/WISEIT-5048 Erro ao utilizar segmentação no contexto de clientes e atributo consumo no dashboard de RFV
-- INICIO - Fabricio - WISEIT-1468/WISEIT-5339 Dashboards - gravar segmentação pelo dashboard em caixa alta
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE VIEW VWDM_NUM_DIASEMANA
AS
	SELECT 1 AS NUM_DIASEMANA FROM DUAL UNION ALL
	SELECT 2 FROM DUAL UNION ALL
	SELECT 3 FROM DUAL UNION ALL
	SELECT 4 FROM DUAL UNION ALL
	SELECT 5 FROM DUAL UNION ALL
	SELECT 6 FROM DUAL UNION ALL
	SELECT 7 FROM DUAL

/

CREATE OR REPLACE PROCEDURE SPDM_DB_FREQ_ESTACIONAMENTO
(
	pSECAO VARCHAR2,
	pCOD_EMPREENDIMENTO INT,
	pDTA_INI VARCHAR2,
	pDTA_FIM VARCHAR2,
	pNUM_DIASEMANA VARCHAR2,
	pHORA VARCHAR2,
	pTEMPOPERMANENCIA VARCHAR2,
	pCOD_SEGMENTACAO VARCHAR2,
	pNME_SEGMENTACAO VARCHAR2,
	pCOD_VISIBILIDADE VARCHAR2, -- 'PA', 'PC', 'PR'
	pCOD_USUARIO VARCHAR2,
	pTOP_CLIENTE VARCHAR2,
	pCOD_PESSOA VARCHAR2,
	RESULTSET OUT SYS_REFCURSOR
 )
AS

/*
--> Para filtar o Dia das semana passar no 5º parâmetro os valores: 1 = DOM , 2 = SEG, 3 = TER, 4 = QUAR, 5 = QUI, 6 = SEX, 7 = SAB
--> Para filtrar poo tempo de permanência, passar os valor: ATE_1H, 1H_2H, 2H_3H, 3H_4H, ACIMA_4H

--> Gravar segmentação
variable vCUR refcursor
EXEC SPDM_DB_FREQ_ESTACIONAMENTO ('SEGMENTACAO','4','2015-01-01','2015-02-23','','','','','SEG TESTE','PA','1',:vCUR);
print vCUR

--> Gráfico para cada dia da semana
variable vCUR refcursor
EXEC SPDM_DB_FREQ_ESTACIONAMENTO ('DIASEMANA','2','2015-01-01','2018-10-23','','','','','','','',:vCUR);
print vCUR

--> Grafico para Hora do dia, às segundas.
variable vCUR refcursor
EXEC SPDM_DB_FREQ_ESTACIONAMENTO ('HORA','2','2015-01-01','2018-10-23','','','','','','','',:vCUR);
print vCUR

--> Média de permanência, aos sábados, às 15hs, com tempo de permanência de 2 a 3 horas.
variable vCUR refcursor
EXEC SPDM_DB_FREQ_ESTACIONAMENTO ('MEDIA_PERMANENCIA','2','2015-01-01','2018-10-23','','','','','','','',:vCUR);
print vCUR

--> Clientes por tempo de permanência
variable vCUR refcursor
EXEC SPDM_DB_FREQ_ESTACIONAMENTO ('TEMPO_PERMANENCIA','2','2000-01-01','2018-12-31','','','','','','','',:vCUR);
print vCUR



-->Acrescentar um gráfico (deve ser o primeiro) mostrando a quantidade de clientes/dia (barra)
variable vCUR refcursor
EXEC SPDM_DB_FREQ_ESTACIONAMENTO ('GRAFICO','2','2016-01-01','2016-08-02','','','','','','','','','',:vCUR);
print vCUR


-->Acrescentar uma tabela com a quantidade de clientes/frequência (x clientes vieram 1 vez, y clientes vieram 2, etc), deve ser clicável.
variable vCUR refcursor
EXEC SPDM_DB_FREQ_ESTACIONAMENTO ('CLIENTES_FREQUENCIA','2','2010-01-01','2018-01-01','','','','','','','','','',:vCUR);
print vCUR


-->Acrescentar tabela com os top 100 clientes por frequência/data último acesso. Deve listar link para dashboard, nome, cpf, bairro/cidade, quantidade frequências, data última frequência, tempo médio permanência desse cliente no período. Ao clicar abrir o detalhe de cada frequência com data e hora da entrada, cancela, data e hora da saída, cancela, tempo permanência, valor pago.
variable vCUR refcursor
EXEC SPDM_DB_FREQ_ESTACIONAMENTO ('CLIENTES','2','2015-05-01','2018-09-01','','','','','','','','100','',:vCUR);
print vCUR


variable vCUR refcursor
EXEC SPDM_DB_FREQ_ESTACIONAMENTO ('TAB_CLIENTE_FREQUENCIA','2','2015-05-01','2016-05-02','','','','','','','','','1882318',:vCUR);
print vCUR




*/
BEGIN
DECLARE
	vQUERY VARCHAR2(8000); vWHERE VARCHAR2(4000); vFROM VARCHAR(1000); vSQL_SEGMENTACAO VARCHAR2(4000);
  vDSC_SEGMENTACAO VARCHAR2(8000); vCOD_SEGMENTACAO INT; vCOD_CONTEXTO INT; vCOD_VISIBILIDADE VARCHAR2(2);
  vDATA1 DATE; vDATA2 DATE;vID VARCHAR(100);vCOUNT INT;vTOP_CLIENTE VARCHAR2(30);

BEGIN

vQUERY := ' ';

vFROM := '
FROM
	FREQUENCIAESTACIONAMENTO FE';

vWHERE := '
WHERE
  FE.TMP_PERMANENCIA >= 0 AND FE.COD_PESSOA > 0 AND FE.COD_EMPREENDIMENTO = '||pCOD_EMPREENDIMENTO;

-- Filtro por data na frequencia (data de entrada no estacionamento)
vWHERE := vWHERE||' AND FE.DTA_ENTRADA >= to_date('''||pDTA_INI||' 00:00:00'',''YYYY-MM-DD HH24:MI:SS'') AND FE.DTA_ENTRADA <= to_date('''||pDTA_FIM||' 23:59:59'',''YYYY-MM-DD HH24:MI:SS'')';

-- Filtro por dia da semana
IF pNUM_DIASEMANA <> ' ' THEN
	vWHERE := vWHERE||' AND TO_CHAR(FE.DTA_ENTRADA,''D'') = '||pNUM_DIASEMANA;
END IF;

-- Filtro por hora.
IF pHORA <> ' ' THEN
	vWHERE := vWHERE||' AND to_char(FE.DTA_ENTRADA,''HH24'') = '||substr(pHORA,1,2);
END IF;

-- Filtro por tempo de permanência.
IF pTEMPOPERMANENCIA = 'ATE_1H' THEN
	vWHERE := vWHERE||' AND trunc(FE.TMP_PERMANENCIA/3600000) = 0';
ELSIF pTEMPOPERMANENCIA = '1H_2H' THEN
	vWHERE := vWHERE||' AND trunc(FE.TMP_PERMANENCIA/3600000) = 1';
ELSIF pTEMPOPERMANENCIA = '2H_3H' THEN
	vWHERE := vWHERE||' AND trunc(FE.TMP_PERMANENCIA/3600000) = 2';
ELSIF pTEMPOPERMANENCIA = '3H_4H' THEN
	vWHERE := vWHERE||' AND trunc(FE.TMP_PERMANENCIA/3600000) = 3';
ELSIF pTEMPOPERMANENCIA = 'ACIMA_4H' THEN
	vWHERE := vWHERE||' AND trunc(FE.TMP_PERMANENCIA/3600000) >= 4';
END IF;

-- Filtro por segmentação
IF Nvl(pCOD_SEGMENTACAO,' ') <> ' ' THEN
	vWHERE := vWHERE||' AND FE.COD_PESSOA IN (SELECT CODIGO FROM TMP_DB_SEG'||pCOD_SEGMENTACAO||')';
END IF;

-- Gráfico em pizza ou barras, para cada dia da semana qual a média de frequência
IF pSECAO = 'DIASEMANA' THEN
vQUERY := 'SELECT
    XX.NUM_DIASEMANA,
    FUNC_RETORNADIASEMANA2(XX.NUM_DIASEMANA,2) AS "DIA_SEMANA",
    Nvl(XX.QUANTIDADE,0) AS "TOTAL",
    Nvl(XX.QUANTIDADE,0) AS "TOTAL_BARRA",
    NVL(XX.MEDIA,0) AS "MEDIA",
    NVL(XX.MEDIA,0) AS "BARRA_MEDIA",
    NVL(XX.PORCENTAGEM,0) AS "PORCENTAGEM"
   FROM
  (
 SELECT
    V.NUM_DIASEMANA,
    Nvl(Z.QUANTIDADE,0) AS "QUANTIDADE",
    NVL(Z.MEDIA,0) AS "MEDIA",
    NVL(Z.PORCENTAGEM,0) AS "PORCENTAGEM"
  FROM
    VWDM_NUM_DIASEMANA V
    LEFT OUTER JOIN
    (
      SELECT
      X.NUM_DIASEMANA, X.DIA_SEMANA, X.QUANTIDADE,
      CASE
      WHEN FUNC_QTD_DIA_SEMANA_PERIODO(X.NUM_DIASEMANA,to_date('''||pDTA_INI||' 00:00:00'',''YYYY-MM-DD HH24:MI:SS''),to_date('''||pDTA_FIM||' 23:59:59'',''YYYY-MM-DD HH24:MI:SS'')) > 0
      THEN CAST(CAST(X.QUANTIDADE AS NUMERIC(10,2))/FUNC_QTD_DIA_SEMANA_PERIODO(X.NUM_DIASEMANA,to_date('''||pDTA_INI||' 00:00:00'',''YYYY-MM-DD HH24:MI:SS''),to_date('''||pDTA_FIM||' 23:59:59'',''YYYY-MM-DD HH24:MI:SS'')) AS NUMERIC(10,2))
      ELSE 0 END AS "MEDIA",
      CAST ((X.QUANTIDADE*1.0/Y.QUANTIDADE)*100 AS NUMERIC(10,2)) AS "PORCENTAGEM"

      FROM
       (
         SELECT
		    TO_CHAR(FE.DTA_ENTRADA,''D'') AS "NUM_DIASEMANA",
		    FUNC_RETORNADIASEMANA(FE.DTA_ENTRADA,2) AS "DIA_SEMANA",
		    COUNT(DISTINCT FE.COD_PESSOA) AS "QUANTIDADE"'
        ||vFROM||vWHERE||
        'GROUP BY
        TO_CHAR(FE.DTA_ENTRADA,''D''),FUNC_RETORNADIASEMANA(FE.DTA_ENTRADA,2)

  ) X

  CROSS JOIN (

         SELECT
		     COUNT(DISTINCT FE.COD_PESSOA) AS "QUANTIDADE"'
         ||vFROM||vWHERE||
  ')Y
 )Z ON Z.NUM_DIASEMANA = V.NUM_DIASEMANA
) XX
  ORDER BY
  CASE XX.NUM_DIASEMANA WHEN 2 THEN 1 WHEN 1 THEN 8 ELSE XX.NUM_DIASEMANA END';

END IF;

-- GRÁFICO MÉDIA DE FREQUENCIA POR HORA
IF pSECAO = 'HORA' THEN
vQUERY := 'SELECT
   HORA_PERIODO.HORA, nvl(XX.QUANTIDADE,0) AS "QUANTIDADE", nvl(XX.MEDIA,0) AS "MEDIA"
  FROM
  (
  SELECT 0 AS "NUM_HORA",''00:00'' AS "HORA" FROM DUAL UNION ALL
  SELECT 1,''01:00'' FROM DUAL UNION ALL
  SELECT 2,''02:00'' FROM DUAL UNION ALL
  SELECT 3,''03:00'' FROM DUAL UNION ALL
  SELECT 4,''04:00''FROM DUAL UNION ALL
  SELECT 5,''05:00''FROM DUAL UNION ALL
  SELECT 6,''06:00''FROM DUAL UNION ALL
  SELECT 7,''07:00''FROM DUAL UNION ALL
  SELECT 8,''08:00''FROM DUAL UNION ALL
  SELECT 9,''09:00''FROM DUAL UNION ALL
  SELECT 10,''10:00''FROM DUAL UNION ALL
  SELECT 11,''11:00''FROM DUAL UNION ALL
  SELECT 12,''12:00''FROM DUAL UNION ALL
  SELECT 13,''13:00''FROM DUAL UNION ALL
  SELECT 14,''14:00''FROM DUAL UNION ALL
  SELECT 15,''15:00''FROM DUAL UNION ALL
  SELECT 16,''16:00''FROM DUAL UNION ALL
  SELECT 17,''17:00''FROM DUAL UNION ALL
  SELECT 18,''18:00''FROM DUAL UNION ALL
  SELECT 19,''19:00''FROM DUAL UNION ALL
  SELECT 20,''20:00''FROM DUAL UNION ALL
  SELECT 21,''21:00''FROM DUAL UNION ALL
  SELECT 22,''22:00''FROM DUAL UNION ALL
  SELECT 23,''23:00'' FROM DUAL
) HORA_PERIODO
  LEFT OUTER JOIN
  (
 SELECT
    X.HORA, X.QUANTIDADE,
    CASE
    WHEN to_date('''||pDTA_FIM||' 23:59:59'',''YYYY-MM-DD HH24:MI:SS'') - to_date('''||pDTA_INI||' 00:00:00'',''YYYY-MM-DD HH24:MI:SS'') > 0
    THEN CAST(CAST(X.QUANTIDADE*1.0 AS NUMERIC(10,2))/(to_date('''||pDTA_FIM||' 23:59:59'',''YYYY-MM-DD HH24:MI:SS'') - to_date('''||pDTA_INI||' 00:00:00'',''YYYY-MM-DD HH24:MI:SS'')) AS NUMERIC(10,2))
    WHEN to_date('''||pDTA_FIM||' 23:59:59'',''YYYY-MM-DD HH24:MI:SS'') - to_date('''||pDTA_INI||' 00:00:00'',''YYYY-MM-DD HH24:MI:SS'') = 0
    THEN CAST(CAST(X.QUANTIDADE*1.0 AS NUMERIC(10,2))/(to_date('''||pDTA_FIM||' 23:59:59'',''YYYY-MM-DD HH24:MI:SS'') - to_date('''||pDTA_INI||' 00:00:00'',''YYYY-MM-DD HH24:MI:SS'')+1) AS NUMERIC(10,2))

    ELSE 0 END AS "MEDIA"
   FROM
  (
        SELECT
		CASE WHEN length(to_char(FE.DTA_ENTRADA,''HH24'')) = 1 THEN ''0'' ELSE '''' END || to_char(FE.DTA_ENTRADA,''HH24'')||'':00'' AS "HORA",
		COUNT(FE.COD_PESSOA) AS "QUANTIDADE"'||
	vFROM||vWHERE||
  'GROUP BY
    to_char(FE.DTA_ENTRADA,''HH24'')
  ORDER BY
    TO_NUMBER(to_char(FE.DTA_ENTRADA,''HH24''))
  ) X
  ) XX ON (XX.HORA = HORA_PERIODO.HORA)
  ORDER BY
  HORA_PERIODO.HORA';
END IF;

-- MÉDIA DE PERMANÊNCIA
IF pSECAO = 'MEDIA_PERMANENCIA' THEN
	vQUERY := 'SELECT SubStr(func_RETORNATEMPO(trunc(sum(trunc((((DTA_SAIDA) - (DTA_ENTRADA)) * 24 * 60 * 60)))/Count(*))),1,5), Count(DISTINCT FE.COD_PESSOA) AS "TOTAL_CLIENTES" '||vFROM||vWHERE;
END IF;

-- CLIENTES POR TEMPO DE PERMANÊNCIA
IF pSECAO = 'TEMPO_PERMANENCIA' THEN
vQUERY := 'SELECT
	CASE
		WHEN trunc(FE.TMP_PERMANENCIA/3600000) = 0 THEN ''ATE_1H''
	    WHEN trunc(FE.TMP_PERMANENCIA/3600000) = 1 THEN ''1H_2H''
		WHEN trunc(FE.TMP_PERMANENCIA/3600000) = 2 THEN ''2H_3H''
		WHEN trunc(FE.TMP_PERMANENCIA/3600000) = 3 THEN ''3H_4H''
		WHEN trunc(FE.TMP_PERMANENCIA/3600000) >= 4 THEN ''ACIMA_4H''
	END AS "TEMPO",
	TO_NUMBER(COUNT(*)) AS "QTDE"'||
	vFROM||vWHERE||
'GROUP BY
	CASE
		WHEN trunc(FE.TMP_PERMANENCIA/3600000) = 0 THEN ''ATE_1H''
	    WHEN trunc(FE.TMP_PERMANENCIA/3600000) = 1 THEN ''1H_2H''
		WHEN trunc(FE.TMP_PERMANENCIA/3600000) = 2 THEN ''2H_3H''
		WHEN trunc(FE.TMP_PERMANENCIA/3600000) = 3 THEN ''3H_4H''
		WHEN trunc(FE.TMP_PERMANENCIA/3600000) >= 4 THEN ''ACIMA_4H''
	END
ORDER BY 2 DESC';
END IF;



IF pSECAO = 'CLIENTES' THEN
    IF pTOP_CLIENTE <> ' ' THEN
      vTOP_CLIENTE := ' WHERE ROWNUM <= '||pTOP_CLIENTE;
    ELSE
      vTOP_CLIENTE := '';
    END IF;

	vQUERY :=	'SELECT A.* FROM (SELECT '''' AS "COL_RESPONSIVE",
PF.COD_PESSOA,
PF.NME_PESSOA,
PF.NUM_CPF,
CASE WHEN nvl(E.NME_BAIRRO,'' '') <> '' '' THEN E.NME_BAIRRO||'' - '' ELSE '''' END||nvl(E.NME_CIDADE,'' '') AS "CIDADE_BAIRRO",
COUNT(DISTINCT FE.COD_FREQUENCIA) AS "QUANTIDADE_FREQUENCIA",
Max(FE.DTA_ENTRADA) AS "DATA_ULTIMA_FREQUENCIA",
FUNC_RETORNATEMPO(SUM(FE.TMP_PERMANENCIA/1000)) AS "TEMPO_TOTAL",
FUNC_RETORNATEMPO(AVG(FE.TMP_PERMANENCIA/1000)) AS "MEDIA_TEMPO"'
||vFROM||
' INNER JOIN PESSOAFISICA PF ON (PF.COD_PESSOA = FE.COD_PESSOA)
  LEFT OUTER JOIN PESSOA_PREFERENCIA PP ON (PP.COD_PESSOA = FE.COD_PESSOA AND PP.NUM_PREFERENCIATIPOCONTATO = 1 AND PP.COD_TIPOCONTATO = 1 AND PP.COD_EMPREENDIMENTO = '||pCOD_EMPREENDIMENTO||')
  LEFT OUTER JOIN ENDERECO E ON E.COD_CONTATO = PP.COD_CONTATO
  AND nvl(E.NME_BAIRRO,'' '') <> '' ''
  AND nvl(E.NME_CIDADE,'' '') <> '' ''
'||vWHERE||
'  GROUP BY
PF.COD_PESSOA,
PF.NME_PESSOA,
PF.NUM_CPF,
E.NME_BAIRRO,
E.NME_CIDADE
ORDER BY COUNT(FE.COD_PESSOA) DESC )
 A'||vTOP_CLIENTE;

END IF;

IF pSECAO = 'TAB_CLIENTE_FREQUENCIA' THEN
	vQUERY :=	'SELECT
FE.DTA_ENTRADA,
NVL(CT.NME_CANCELA, '' '') AS "CANCELA_ENTRADA",
FE.DTA_SAIDA,
NVL(CT2.NME_CANCELA,'' '') AS "CANCELA_SAIDA",
FUNC_RETORNATEMPO(FE.TMP_PERMANENCIA/1000) AS "TEMPO_PERMANENCIA",
NVL(FE.VLR_PAGO,''0'') AS "VALOR_PAGO"'
||vFROM||
' INNER JOIN PESSOAFISICA PF ON (PF.COD_PESSOA = FE.COD_PESSOA)
  LEFT OUTER JOIN CANCELAESTACIONAMENTO CT ON (CT.COD_CANCELA = FE.COD_CANCELAENTRADA)
  LEFT OUTER JOIN CANCELAESTACIONAMENTO CT2 ON (CT2.COD_CANCELA = FE.COD_CANCELASAIDA)'
||vWHERE||'
 AND FE.COD_PESSOA = '||pCOD_PESSOA||'
 ORDER BY FE.DTA_ENTRADA DESC';

 END IF;


-- CLIENTES / FREQUENCIA
IF pSECAO = 'CLIENTES_FREQUENCIA' THEN
vQUERY := '
   SELECT
   VEZES_CLIENTE.NUMERO_VEZES,
   VEZES_CLIENTE.VEZES,nvl(XX.QUANTIDADE,0) AS "CLIENTES",
   nvl(XX.QUANTIDADE,0) AS "CLIENTES_BARRA"
  FROM
  (
  SELECT 1 AS "NUMERO_VEZES",''1 VEZ''AS "VEZES" FROM DUAL UNION ALL
  SELECT 2,''2 VEZES'' FROM DUAL UNION ALL
  SELECT 3,''3 VEZES'' FROM DUAL UNION ALL
  SELECT 4,''4 VEZES''FROM DUAL UNION ALL
  SELECT 5,''5 VEZES''FROM DUAL UNION ALL
  SELECT 6,''6 VEZES''FROM DUAL UNION ALL
  SELECT 7,''7 VEZES''FROM DUAL UNION ALL
  SELECT 8,''8 VEZES''FROM DUAL UNION ALL
  SELECT 9,''9 VEZES''FROM DUAL UNION ALL
  SELECT 10,''ACIMA DE 10 VEZES''FROM DUAL
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
  TO_NUMBER(COUNT(*)) AS "QUANTIDADE"
  FROM
  (

SELECT FE.COD_PESSOA , Count(*) AS "QUANTIDADE"
'||vFROM||vWHERE||
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
END IF;


IF pSECAO = 'GRAFICO' THEN
  vDATA1 := To_Date(pDTA_INI||' 00:00:00','YYYY-MM-DD HH24:MI:SS');
  vDATA2 := To_Date(pDTA_FIM||' 23:59:59','YYYY-MM-DD HH24:MI:SS');
  SELECT SYS_CONTEXT('USERENV','SESSIONID') INTO vID FROM DUAL;

  -- Apaga a tabela caso exista.
  EXECUTE IMMEDIATE('SELECT COUNT(*) FROM USER_TABLES WHERE TABLE_NAME = ''TMP_PERIODO_'||vID||'''') INTO vCOUNT;
  IF vCOUNT > 0 THEN
      EXECUTE IMMEDIATE('DROP TABLE TMP_PERIODO_'||vID);
  END IF;

  vQUERY := 'CREATE TABLE TMP_PERIODO_'||vID||'(DATA DATE)';
  EXECUTE IMMEDIATE(vQUERY);

  WHILE vDATA1 <= vDATA2
  LOOP
    IF To_Char(vDATA1,'YYYY-MM') <= To_Char(vDATA2,'YYYY-MM') THEN
      vQUERY := 'INSERT INTO TMP_PERIODO_'||vID||' VALUES(To_Date('''||To_Char(vDATA1,'YYYYMMDD HH24:MI:SS')||''',''YYYYMMDD HH24:MI:SS''))';
      EXECUTE IMMEDIATE(vQUERY);
    END IF;
      vDATA1 := vDATA1 + 1;
  END LOOP;

  vQUERY := '
  SELECT
    T.DATA, Nvl(A.TOTAL_CLIENTES,0) AS "TOTAL_CLIENTES"
  FROM
    TMP_PERIODO_'||vID||' T
    LEFT OUTER JOIN
    (
    SELECT
      To_Date(To_Char(FE.DTA_ENTRADA,''YYYYMMDD''),''YYYYMMDD'') AS "DATA",COUNT(DISTINCT FE.COD_PESSOA) AS "TOTAL_CLIENTES"'
      ||vFROM||vWHERE||'
  GROUP BY
    To_Date(To_Char(FE.DTA_ENTRADA,''YYYYMMDD''),''YYYYMMDD'')) A ON (A.DATA = T.DATA)  
  ORDER BY
    T.DATA';
END IF;

-- Segmentação
SELECT COD_CONTEXTO INTO vCOD_CONTEXTO FROM CONTEXTO WHERE NME_CONTEXTO = 'CLIENTE' AND FLG_ATIVO = 1;
IF pSECAO = 'SEGMENTACAO' AND nvl(pNME_SEGMENTACAO,' ') <> ' ' AND vCOD_CONTEXTO > 0 THEN
	IF nvl(pCOD_VISIBILIDADE,' ') = ' ' THEN
		vCOD_VISIBILIDADE := 'PA';
	ELSE
		vCOD_VISIBILIDADE := pCOD_VISIBILIDADE;
  END IF;

	vQUERY := 'SELECT DISTINCT FE.COD_PESSOA';

	SPDM_GETNEXTID ('SEGMENTACAO','COD_SEGMENTACAO',vCOD_SEGMENTACAO);
	INSERT INTO SEGMENTACAO(COD_SEGMENTACAO,COD_CONTEXTO,NME_SEGMENTACAO,DSC_SEGMENTACAO,SQL_SEGMENTACAO,COD_USUARIOCADASTRO,
    DTA_CADASTRO,FLG_AUTOMATICA,COD_EMPREENDIMENTO,COD_VISIBILIDADE,FLG_WIZARD)
	VALUES(vCOD_SEGMENTACAO, vCOD_CONTEXTO, Upper(pNME_SEGMENTACAO), vDSC_SEGMENTACAO, vQUERY||' '||vFROM||' '||vWHERE, pCOD_USUARIO,
    SYSDATE, CASE WHEN pCOD_USUARIO = -77 THEN 1 ELSE 0 END, pCOD_EMPREENDIMENTO, vCOD_VISIBILIDADE, 0);

	EXECUTE IMMEDIATE ('INSERT INTO SEGMENTACAORESULTADO(COD_RESULTADO,COD_SEGMENTACAO) '||vQUERY||','||vCOD_SEGMENTACAO||' '||vFROM||' '||vWHERE);

	-- Grava a quantidade de clientes na segmentação salva
	UPDATE
		SEGMENTACAO
	SET
		NUM_QUANTIDADE = (SELECT COUNT(*) FROM SEGMENTACAORESULTADO WHERE COD_SEGMENTACAO = vCOD_SEGMENTACAO)
	WHERE
		COD_SEGMENTACAO = vCOD_SEGMENTACAO;

	vQUERY := 'SELECT TO_NUMBER('||vCOD_SEGMENTACAO||') AS "COD_SEGMENTACAO" FROM DUAL';
END IF;

--Dbms_Output.Put_Line(vQUERY);
OPEN RESULTSET FOR vQUERY;

-- Apaga a temporária.
  IF pSECAO = 'GRAFICO' THEN
  EXECUTE IMMEDIATE('SELECT COUNT(*) FROM USER_TABLES WHERE TABLE_NAME = ''TMP_PERIODO_'||vID||'''') INTO vCOUNT;
  IF vCOUNT > 0 THEN
      EXECUTE IMMEDIATE('DROP TABLE TMP_PERIODO_'||vID);
  END IF;
  END IF;
END;
END;
/
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FIM - JOELSON - WISEIT-4805 / WISEIT-4864 Dashboard Estacionamento - padronizar dia de semana e hora, colocar mapa de dia x hora, tabela de clientes
-- FIM - Fabricio - WISEIT-4826 Dashboard Clientes - poder analisar sem filtro de datas e abrir a partir de outros dashboards - WISEIT-5029 Dashboar Clientes - Procedure
-- FIM - Fabricio - WISEIT-1468/WISEIT-5048 Erro ao utilizar segmentação no contexto de clientes e atributo consumo no dashboard de RFV
-- FIM - Fabricio - WISEIT-1468/WISEIT-5339 Dashboards - gravar segmentação pelo dashboard em caixa alta
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

EXEC SPDM_CONTROLEVERSAO ('BD_VERSAO_DASHBOARD_FREQUENCIAESTACIONAMENTO', '10.0.11');
/
------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------

