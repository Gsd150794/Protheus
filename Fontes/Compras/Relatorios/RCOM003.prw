/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |27/11/2023| Chamado 45688. Incluída informação sobre prazo para manifestação
Lucas Borges  |22/05/2024| Chamado 47282. Melhoria no tratatamento da emissão na CKO
Lucas Borges  |29/05/2025| Chamado 50833. Inclusão de novos campos
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RCOM003
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 27/03/2018
Descrição---------: Análise XMLs recebidos. Chamado 24364
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RCOM003

Local oReport := Nil As Object
Pergunte("RCOM003",.F.)
//Inferface de Impressão
oReport := ReportDef()
oReport:PrintDialog()

Return

/*
===============================================================================================================================
Programa----------: ReportDef
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 27/03/2018
Descrição---------: Processa a montagem do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ReportDef

Local oReport := Nil As Object
Local oSection:= Nil As Object
Local _aOrdem := {"Filial x Emissao"} As Array

//Criacao do componente de impressao
//TReport():New
//ExpC1 : Nome do relatorio
//ExpC2 : Titulo
//ExpC3 : Pergunte
//ExpB4 : Bloco de codigo que sera executado na confirmacao da impressao
//ExpC5 : Descricao

oReport := TReport():New("RCOM003","Análise XMLs recebidos","RCOM003",;
{|oReport| ReportPrint(oReport,_aOrdem)},"Lista todos os documentos emitidos contra a empresa.")
oSection := TRSection():New(oReport,"Dados"	,/*uTable {}*/, _aOrdem/*aOrder*/, .F./*lLoadCells*/, .T./*lLoadOrder*/,"Total dos Bancos: "/*uTotalText*/)
oReport:SetLandscape()//Paisagem
oSection:SetTotalInLine(.F.)

//TRCell():New(oParent,cName,cAlias,cTitle,cPicture,nSize,lPixel,bBlock,cAlign,lLineBreak,cHeaderAlign,lCellBreak,nColSpace,lAutoSize,nClrBack,nClrFore,lBold)
TRCell():New(oSection,"F1_FILIAL","SF1"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"F1_DOC","SF1"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"F1_SERIE","SF1"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"F1_EMISSAO","SF1"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"F1_DTDIGIT","SF1"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"F1_EST","SF1"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"F1_FORNECE","SF1"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"F1_LOJA","SF1"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_NOME","SA2"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_CGC","SA2"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"F1_CHVNFE","SF1"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"F1_ESPECIE","SF1"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"TIPO",/*Table*/,"Tipo"/*cTitle*/,/*Picture*/,14/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"FINALIDADE",/*Table*/,"Finalidade"/*cTitle*/,/*Picture*/,25/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ENT_FOR",/*Table*/,"Ent.For."/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"F1_VALBRUT","SF1"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"STATUS_ESCRITURACAO",/*Table*/,"Status "+CRLF+"Escrit."/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"CONF_NREAL",/*Table*/,"Dias Rest. "+CRLF+"Confirmação/Não Realizado"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"REST_DESC",/*Table*/,"Dias Rest. "+CRLF+"Desacordo/Desconhecimento"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"STATUS_REPROCESSAMENTO",/*Table*/,"Status "+CRLF+"Reproc."/*cTitle*/,/*Picture*/,18/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"MANIFESTACAO",/*Table*/,"Manifestação"/*cTitle*/,/*Picture*/,17/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"DATA_EVENTO",/*Table*/,"Data Manif"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"STATUS_TRANS",/*Table*/,"Status "+CRLF+"Transmissão"/*cTitle*/,/*Picture*/,17/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"TP_TRANS",/*Table*/,"Tipo "+CRLF+"Transmissão"/*cTitle*/,/*Picture*/,17/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"STATUS_TRANS_TSS",/*Table*/,"Status "+CRLF+"Transmissão TSS"/*cTitle*/,/*Picture*/,17/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"CKO_CODERR",/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"CKO_MSGERR",/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	
Return( oReport )

/*
===============================================================================================================================
Programa----------: ReportPrint
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 27/03/2018
Descrição---------: Processa a impressão do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ReportPrint(oReport As Object,_aOrdem As Array)

Local _cQuery	:= "%" As Character
Local _cQryFil	:= " " As Character
Local _cFilSF1	:= "%" As Character
Local _cFilCKO	:= "%" As Character
Local _cFilC00	:= "%" As Character
Local _cAlias		:= "" As Character
Local _aSelFil	:= {} As Array
Local _nOrdem		:= oReport:Section(1):GetOrder() As Numeric
Local _lPlanilha := oReport:nDevice == 4 As Logical
Local _nCountRec:= 0 As Logical

//Chama função que permitirá a seleção das filiais
If MV_PAR01 == 1
	If Empty(_aSelFil)
		_aSelFil := AdmGetFil(.F.,.F.,"SF1")
	EndIf
Else
  aAdd(_aSelFil,cFilAnt)
EndIf
_cQryFil := GetRngFil( _aSelFil, "SF1", .T.,)

//=====================================================
// Adiciona a ordem escolhida ao titulo do relatorio  |
//=====================================================
oReport:SetTitle(oReport:Title() + " ("+AllTrim(_aOrdem[_nOrdem])+") ")

//==========================================================================
// Transforma parametros Range em expressao SQL                             	
//==========================================================================
MakeSqlExpr(oReport:uParam)

//================================================================================
//| Configuração das quebras do relatório                                        |
//================================================================================

//==========================================================================
// Trata as células a serem exibidas de acordo com sessão e parâmetros
//==========================================================================
If !_lPlanilha
    oReport:Section(1):Cell("F1_DOC"):Disable()
    oReport:Section(1):Cell("F1_SERIE"):Disable()
    oReport:Section(1):Cell("F1_FORNECE"):Disable()
    oReport:Section(1):Cell("F1_LOJA"):Disable()
    oReport:Section(1):Cell("A2_NOME"):Disable()
    oReport:Section(1):Cell("A2_CGC"):Disable()
    oReport:Section(1):Cell("FINALIDADE"):Disable()
    oReport:Section(1):Cell("CONF_NREAL"):Disable()
    oReport:Section(1):Cell("REST_DESC"):Disable()
    oReport:Section(1):Cell("STATUS_TRANS_TSS"):Disable()
    oReport:Section(1):Cell("DATA_EVENTO"):Disable()
    oReport:Section(1):Cell("CKO_MSGERR"):Disable()
EndIf

//====================================================================================================
// Monta filtro de acordo com a tabela de origem
//====================================================================================================
_cFilCKO+=" AND CKO.CKO_I_EMIS BETWEEN '"+ DToS(MV_PAR02) + "' AND '" + DToS(MV_PAR03) + "'"
_cFilSF1+=" AND SF1.F1_EMISSAO BETWEEN '"+ DToS(MV_PAR02) + "' AND '" + DToS(MV_PAR03) + "'"
If !Empty(MV_PAR05)
	_cFilSF1+=" AND SF1.F1_DTDIGIT BETWEEN '"+ DToS(MV_PAR04) + "' AND '" + DToS(MV_PAR05) + "'"
EndIf
_cFilC00+=" AND C00.C00_DTEMI BETWEEN '"+ DToS(MV_PAR02) + "' AND '" + DToS(MV_PAR03) + "'"
If !Empty(MV_PAR07)
	_cFilCKO+=" AND CKO.CKO_I_EMIT BETWEEN '"+ MV_PAR06 + "' AND '" + MV_PAR07 + "'"
	_cFilSF1+=" AND SubStr(SF1.F1_CHVNFE,7,14) BETWEEN '"+ MV_PAR06 + "' AND '" + MV_PAR07 + "'"
    _cFilC00+=" AND C00.C00_CNPJEM BETWEEN '"+ MV_PAR06 + "' AND '" + MV_PAR07 + "'"
EndIf
_cFilCKO+=" AND RTRIM(CKO.CKO_FILPRO) " +_cQryFil +"%"
_cFilSF1+=" AND SF1.F1_FILIAL " +_cQryFil +"%"
_cFilC00+=" AND C00.C00_FILIAL " +_cQryFil +"%"

If !Empty(MV_PAR08)
	_cQuery+=" AND TPEVENTO IN "+StrTran(FormatIn(AllTrim(MV_PAR08),";"),"'","")
EndIf
If !Empty(MV_PAR09)
	_cQuery+=" AND STATUS_154 IN "+StrTran(FormatIn(AllTrim(MV_PAR09),";"),"'","")
EndIf
_cQuery+=" %"

//==========================================================================
// Query do relatório da secao 1                                            
//==========================================================================
oReport:Section(1):BeginQuery()	
_cAlias := GetNextAlias()

oReport:SetMsgPrint("Consultando registros no Banco de Dados")
oReport:SetMeter(0)

BeginSql Alias _cAlias
SELECT F1_FILIAL, F1_DOC, F1_SERIE,
       Case
         WHEN F1_EMISSAO IS NOT NULL THEN F1_EMISSAO
         WHEN DS_EMISSA IS NOT NULL THEN DS_EMISSA
         WHEN C00_DTEMI IS NOT NULL THEN C00_DTEMI
         Else CKO_I_EMIS
       END F1_EMISSAO,
       F1_DTDIGIT, F1_EST, F1_FORNECE, F1_LOJA,
       Case WHEN A2_NOME IS NOT NULL THEN A2_NOME 
         WHEN A1_NOME IS NOT NULL THEN A1_NOME
         Else Upper(CKO_NOMFOR) END A2_NOME,
       Case WHEN A2_CGC IS NOT NULL THEN A2_CGC 
         WHEN A1_CGC IS NOT NULL THEN A1_CGC
          Else CKO_I_EMIT END A2_CGC,
       Case
         WHEN F1_ESPECIE = 'NFE' THEN
          Case
            WHEN EST_FIL = 'RO' AND F1_EST = 'RO' THEN 20
            WHEN EST_FIL = 'RO' AND F1_EST <> 'RO' THEN 35
            Else 180
          END - Round(SYSDATE - TO_DATE(Case
                                          WHEN F1_EMISSAO IS NOT NULL THEN F1_EMISSAO
                                          WHEN DS_EMISSA IS NOT NULL THEN DS_EMISSA
                                          WHEN C00_DTEMI IS NOT NULL THEN C00_DTEMI
                                          Else CKO_I_EMIS END,'YYYYMMDD'),
                      0)
       END CONF_NREAL,
       Case
         WHEN F1_ESPECIE = 'NFE' THEN
          Case
            WHEN EST_FIL = 'RO' AND F1_EST = 'RO' THEN 10
            WHEN EST_FIL = 'RO' AND F1_EST <> 'RO' THEN 15
            Else 180 END
         Else 45
       END - Round(SYSDATE - TO_DATE(Case
                                       WHEN F1_EMISSAO IS NOT NULL THEN F1_EMISSAO
                                       WHEN DS_EMISSA IS NOT NULL THEN DS_EMISSA
                                       WHEN C00_DTEMI IS NOT NULL THEN C00_DTEMI
                                       Else CKO_I_EMIS END, 'YYYYMMDD'),
                   0) REST_DESC,
       F1_CHVNFE,
       F1_ESPECIE,
       Case
         WHEN F1_TIPO IS NOT NULL THEN
          DECODE(F1_TIPO, 'N', 'Normal', 'D', 'Devolucao', 'I', 'Compl. ICMS', 'P', 'Compl. IPI', 'B', 'Beneficiamento', 'C', 'Compl. Preco')
         Else
          DECODE(DS_TIPO, 'N', 'Normal', 'O', 'Bonificacao', 'D', 'Devolucao', 'B', 'Beneficiamento', 'C', 'Compl. Preco', 'T', 'Transporte','')
       END TIPO,
       Case WHEN SubStr(F1_CHVNFE,21,2) = '55' THEN
         DECODE (CKO_I_FINA,1,'Normal',2,'Complementar',3,'Ajuste',4,'Devolucao')
         WHEN SubStr(F1_CHVNFE,21,2) = '57' OR SubStr(F1_CHVNFE,21,2) = '67' THEN
         DECODE (CKO_I_FINA,0,'Normal',1,'Complemento de Valores',2,'Anulacaoo de Valores',3,'Substituto',5,'Simplificado',6,'Substituto Simplificado','Acionar TI')
        Else 'Acionar a TI' END FINALIDADE,
       ENT_FOR,
       Case
         WHEN F1_VALBRUT IS NOT NULL THEN F1_VALBRUT
         WHEN DS_TOTAL IS NOT NULL THEN DS_TOTAL
         WHEN C00_VLDOC IS NOT NULL THEN C00_VLDOC
         Else 0
       END F1_VALBRUT,
       Case
         WHEN F1_STATUS = 'A' THEN 'Classificado'
         WHEN F1_STATUS = ' ' THEN 'Pre-nota'
         WHEN DS_TIPO IS NOT NULL THEN 'Monitor'
         WHEN CKO_I_EMIS IS NOT NULL THEN 'Reprocessamento'
         Else 'Manifestacao'
       END STATUS_ESCRITURACAO,
       DECODE(CKO_FLAG, '1', 'Processado', '2', 'Inconsistencia', '3','Documento duplicado, mesma chave porém em XMLs diferentes',
              '0', 'Pendente', '9','Excluido_Fiscal') STATUS_REPROCESSAMENTO,
       CKO_CODERR,
       Case
         WHEN F1_ESPECIE = 'CTE' THEN 'Inexistente p/CTe'
         WHEN F1_ESPECIE = 'CTEOS' THEN 'Inexistente p/CTeOS'
         WHEN C00_STATUS = '0' THEN 'Sem Manif.'
         WHEN C00_STATUS = '1' THEN 'Confirmada'
         WHEN C00_STATUS = '2' THEN 'Desconhecida'
         WHEN C00_STATUS = '3' THEN 'Nao realizada'
         WHEN C00_STATUS = '4' THEN 'Ciencia'
         WHEN C00_STATUS IS NULL THEN 'NF-e inexistente'
       End MANIFESTACAO,
       TO_DATE(DATA_EVENTO, 'YYYYMMDD') DATA_EVENTO,
       Case
         WHEN F1_ESPECIE = 'CTE' THEN 'Inexistente p/CTe'
         WHEN F1_ESPECIE = 'CTEOS' THEN 'Inexistente p/CTeOS'
         WHEN C00_CODEVE = '1' THEN 'Nao Transmit.'
         WHEN C00_CODEVE = '2' THEN 'Monit. Pendente'
         WHEN C00_CODEVE = '3' THEN 'Manif. Sucesso'
         WHEN C00_CODEVE = '4' THEN 'Manif. Problema'
         WHEN C00_CODEVE IS NULL THEN 'NF-e inexistente'
       END STATUS_TRANS,
       Case
         WHEN TPEVENTO = 999999 THEN 'Nao Transmitido'
         WHEN TPEVENTO = 610110 THEN 'Prest. Serv. Desac.'
         WHEN TPEVENTO = 610111 THEN 'Canc. Prest. Serv. Desac.'
         WHEN TPEVENTO = 210200 THEN 'Confirmada'
         WHEN TPEVENTO = 210220 THEN 'Desconhecida'
         WHEN TPEVENTO = 210240 THEN 'Nao Realizada'
         WHEN TPEVENTO = 210210 THEN 'Ciencia'
         WHEN TPEVENTO = 110111 THEN 'Cancelamento'
         WHEN TPEVENTO = 888888 THEN 'Nao Transmitido'
         Else 'Acionar TI'
       END TP_TRANS,
       Case
         WHEN STATUS_154 = 9 THEN 'Nao Transmitido'
         WHEN STATUS_154 = 6 THEN 'OK'
         WHEN STATUS_154 = 5 THEN 'Erro'
         WHEN STATUS_154 = 8 THEN 'Nao Transmitido'
         Else 'Acionar TI'
       END STATUS_TRANS_TSS,
       Case
         WHEN CKO_CODERR = 'MCOM01' THEN 'MD-e com 210220-Operação Desconhecida'
         WHEN CKO_CODERR = 'MCOM02' THEN 'MD-e com 21040-Operação Não realizada'
         WHEN CKO_CODERR = 'MCOM03' THEN 'CT-e com 610110-Prestação de Serviço em Desacordo'
         WHEN CKO_CODERR = 'MCOM04' THEN 'CT-e de Anulação'
         WHEN CKO_CODERR = 'MCOM05' THEN 'Excluído Fiscal Com validação'
         WHEN CKO_CODERR = 'MCOM06' THEN 'Excluído Fiscal Sem validação'
         WHEN CKO_CODERR = 'MCOM07' THEN 'Manutenção Automática XML'
         Else RTRIM(UTL_RAW.CAST_TO_VARCHAR2(DBMS_LOB.SubStr(CKO_MSGERR, 300, 1)))
       END CKO_MSGERR
  FROM (SELECT BASE.F1_FILIAL,
               SY.M0_ESTENT EST_FIL,
               Case WHEN SF11.F1_DOC IS NOT NULL THEN SF11.F1_DOC
                 WHEN SDS1.DS_DOC IS NOT NULL THEN SDS1.DS_DOC 
                 Else SubStr(CKO1.CKO_CHVDOC,26,9) END F1_DOC,
               Case WHEN SF11.F1_SERIE IS NOT NULL THEN SF11.F1_SERIE
                 WHEN SDS1.DS_FORNEC IS NOT NULL THEN SDS1.DS_FORNEC 
                 Else CKO1.CKO_SERIE END F1_SERIE,
               SF11.F1_EMISSAO,
               SF11.F1_DTDIGIT,
               C001.C00_DTEMI,
               SDS1.DS_EMISSA,
               CKO1.CKO_I_EMIS,
               CKO1.CKO_NOMFOR,
               Case WHEN SF11.F1_EST IS NOT NULL THEN SF11.F1_FORNECE
                 WHEN SDS1.DS_FORNEC IS NOT NULL THEN SDS1.DS_FORNEC END F1_FORNECE,
               Case WHEN SF11.F1_EST IS NOT NULL THEN SF11.F1_LOJA
                 WHEN SDS1.DS_LOJA IS NOT NULL THEN SDS1.DS_LOJA END F1_LOJA,
               CKO1.CKO_I_EMIT,
               Case
                 WHEN SF11.F1_EST IS NOT NULL THEN SF11.F1_EST
                 Else
                  DECODE(SubStr(BASE.F1_CHVNFE, 1, 2),
                         '11','RO','12','AC','13','AM','14','RR','15','PA','16','AP','17','TO','21','MA','22','PI','23','CE',
                         '24','RN','25','PB','26','PE','27','AL','31','MG','32','ES','33','RJ','35','SP','41','PR','42','SC',
                         '43','RS','50','MS','51','MT','52','GO','53','DF','28','SE','29','BA','99','EX')
               END F1_EST,
               Case WHEN SF11.F1_TIPO IS NOT NULL THEN SF11.F1_TIPO Else SDS1.DS_TIPO END F1_TIPO,
               SDS1.DS_TIPO,
               CKO1.CKO_I_FINA,
               Case
                 WHEN (SELECT COUNT(1)
                         FROM SPED156
                        WHERE SPED156.D_E_L_E_T_ = ' '
                          AND BASE.F1_CHVNFE = DOCCHV
                          AND DOCTPOP = '0') = 1 THEN 'Sim'
                 Else 'Nao' END ENT_FOR,
               BASE.F1_CHVNFE,
               DECODE(SubStr(BASE.F1_CHVNFE, 21, 2),'55','NFE','57','CTE','67','CTEOS') F1_ESPECIE,
               SF11.F1_STATUS,
               SF11.F1_VALBRUT,
               C001.C00_VLDOC,
               SDS1.DS_TOTAL,
               C001.C00_STATUS,
               CKO1.CKO_FLAG,
               Case
                 WHEN CKO1.CKO_CODERR IS NULL THEN DECODE(C001.C00_SITDOC, '3', 'COM040')
                 Else CKO1.CKO_CODERR
               END CKO_CODERR,
               CKO1.CKO_MSGERR,
               C001.C00_CODEVE,
               SF11.F1_IDDES,
               DECODE(SubStr(BASE.F1_CHVNFE, 21, 2),'55', NVL(SPED154T.TPEVENTO, 888888), NVL(SPED154T.TPEVENTO, 999999)) TPEVENTO,
               DECODE(SubStr(BASE.F1_CHVNFE, 21, 2),'55', NVL(SPED154T.STATUS_154, 8), NVL(SPED154T.STATUS_154, 9)) STATUS_154,
               SPED154T.DATA_EVENTO
          FROM (SELECT RTRIM(CKO.CKO_FILPRO) F1_FILIAL,
                       SubStr(CKO.CKO_ARQUIV, 4, 44) F1_CHVNFE
                  FROM %Table:CKO% CKO
                 WHERE CKO.D_E_L_E_T_ = ' '
                   %exp:_cFilCKO%
                   AND CKO.CKO_CODERR <> 'COM002'
                   AND NOT EXISTS
                 (SELECT 1 FROM %Table:SF1%
                         WHERE D_E_L_E_T_ = ' '
                           AND F1_FILIAL = RTRIM(CKO_FILPRO)
                           AND F1_CHVNFE = CKO_CHVDOC)
                UNION
                SELECT F1_FILIAL, F1_CHVNFE
                  FROM %Table:SF1% SF1
                 WHERE SF1.D_E_L_E_T_ = ' '
                   %exp:_cFilSF1%
                   AND F1_FORMUL <> 'S'
                   AND F1_CHVNFE <> ' '
                   AND F1_ESPECIE IN ('SPED', 'CTE', 'CTEOS')
                UNION
                SELECT C00.C00_FILIAL, C00.C00_CHVNFE
                  FROM %Table:C00% C00
                 WHERE C00.D_E_L_E_T_ = ' '
                   %exp:_cFilC00%
                   AND NOT EXISTS (SELECT 1 FROM %Table:SF1%
                         WHERE D_E_L_E_T_ = ' '
                           AND F1_FILIAL = C00_FILIAL
                           AND F1_CHVNFE = C00_CHVNFE)) BASE, SYS_COMPANY SY, %Table:CKO% CKO1, %Table:SF1% SF11, %Table:C00% C001, %Table:SDS% SDS1,
            (SELECT RTRIM(S.M0_CODFIL) F1_FILIAL,
                           SPED154.NFE_CHV F1_CHVNFE,
                           SPED154.TPEVENTO TPEVENTO,
                           SPED154.STATUS STATUS_154,
                           SPED154.DATE_EVEN DATA_EVENTO
                      FROM SPED154, SPED001, SYS_COMPANY S
                     WHERE SPED154.D_E_L_E_T_ = ' '
                       AND SPED001.D_E_L_E_T_ = ' '
                       AND S.D_E_L_E_T_ = ' '
                       AND SPED001.IE = S.M0_INSC
                       AND SPED001.ID_ENT = SPED154.ID_ENT
                       AND S.M0_CGC = SPED001.CNPJ
                       AND SPED154.TPEVENTO IN (210200, 210220, 210240, 210210, 610110, 610111)
                       AND SPED154.R_E_C_N_O_ =
                           (SELECT MAX(B.R_E_C_N_O_)
                              FROM SPED154 B
                             WHERE B.D_E_L_E_T_ = ' '
                               AND B.NFE_CHV = SPED154.NFE_CHV
                               AND B.ID_ENT = SPED154.ID_ENT)) SPED154T
            WHERE SY.D_E_L_E_T_ = ' ' 
            AND CKO1.D_E_L_E_T_ (+) = ' '
            AND SF11.D_E_L_E_T_ (+) = ' '
            AND C001.D_E_L_E_T_ (+) = ' '
            AND SDS1.D_E_L_E_T_ (+) = ' '
            AND BASE.F1_FILIAL = RTRIM(SY.M0_CODFIL)
            AND CKO1.CKO_FILPRO (+)= BASE.F1_FILIAL 
            AND CKO1.CKO_CHVDOC (+)= BASE.F1_CHVNFE
            AND SF11.F1_FILIAL (+)= BASE.F1_FILIAL 
            AND SF11.F1_CHVNFE (+)= BASE.F1_CHVNFE
            AND C001.C00_FILIAL (+)= BASE.F1_FILIAL 
            AND C001.C00_CHVNFE (+)= BASE.F1_CHVNFE
            AND SDS1.DS_FILIAL (+)= BASE.F1_FILIAL 
            AND SDS1.DS_CHAVENF (+)= BASE.F1_CHVNFE
            AND SPED154T.F1_FILIAL (+)= BASE.F1_FILIAL 
            AND SPED154T.F1_CHVNFE (+)= BASE.F1_CHVNFE)
            LEFT JOIN %Table:SA1% SA1 
                ON((F1_TIPO IN ('B', 'D')) OR 
                   (F1_TIPO IS NULL AND SubStr(F1_CHVNFE,21,2) = '55' AND CKO_I_FINA = 4))
                AND F1_FORNECE = SA1.A1_COD
                AND F1_LOJA = SA1.A1_LOJA
                AND SA1.D_E_L_E_T_ = ' '
            LEFT JOIN %Table:SA2% SA2
                 ON((F1_TIPO NOT IN ('B', 'D')) OR 
                   (F1_TIPO IS NULL AND NOT (SubStr(F1_CHVNFE,21,2) = '55' AND CKO_I_FINA = 4)))
                AND F1_FORNECE = SA2.A2_COD
                AND F1_LOJA = SA2.A2_LOJA
                AND SA2.D_E_L_E_T_ = ' '
 WHERE  F1_ESPECIE IN ('NFE', 'CTE', 'CTEOS')
 %exp:_cQuery%
 ORDER BY F1_FILIAL, F1_EMISSAO, F1_CHVNFE

EndSql
//==========================================================================
// Metodo EndQuery ( Classe TRSection )                                     
//                                                                          
// Prepara o relatório para executar o Embedded SQL.                        
//                                                                          
// ExpA1 : Array com os parametros do tipo Range                            
//                                                                          
//==========================================================================
oReport:Section(1):EndQuery(/*Array com os parametros do tipo Range*/)

//=======================================================================
//Impressao do Relatorio
//=======================================================================
oReport:Section(1):Init()
Count To _nCountRec
(_cAlias)->( DBGoTop() )
oReport:SetMsgPrint("Imprimindo")
oReport:SetMeter(_nCountRec)

While !oReport:Cancel() .And. (_cAlias)->(!Eof())
	oReport:Section(1):PrintLine()
	oReport:IncMeter()
	(_cAlias)->(DBSkip())
EndDo

Return
