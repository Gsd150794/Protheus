/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Igor Melgaço  |04/04/2023| Chamado 43327. Nova query e filtros.  
Lucas Borges  |02/09/2024| Chamado 48286. Incluído filtro para desconsiderar contas específicas
Lucas Borges  |06/09/2024| Chamado 48461. Relatório refeito, incluindo novas informações e versões analíticas e sintéticas
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: REST022
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 14/02/2023
Descrição---------: Relatório Centro de Custo Unificado. Chamado 42999
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function REST022()

Local oReport
Pergunte("REST022",.F.)
//Inferface de Impressão
oReport := ReportDef()
oReport:PrintDialog()

Return

/*
===============================================================================================================================
Programa----------: ReportDef
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 14/02/2023
Descrição---------: Definição do Componente
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ReportDef()

Local oReport
Local oSection
Local _aOrdem   := {"Filial+CC Unificado"}

//Criacao do componente de impressao
//TReport():New
//ExpC1 : Nome do relatorio
//ExpC2 : Titulo
//ExpC3 : Pergunte
//ExpB4 : Bloco de codigo que sera executado na confirmacao da impressao
//ExpC5 : Descricao

oReport := TReport():New("REST022","Centro de Custo Unificado","REST022",;
{|oReport| ReportPrint(oReport,_aOrdem)},"Totaliza os movimentos contábeis de acordo com o Centro de Custo Unificado.")
oSection := TRSection():New(oReport,"Movimentos"	,/*uTable {}*/, _aOrdem/*aOrder*/, .F./*lLoadCells*/, .T./*lLoadOrder*/,"Total das Filiais: "/*uTotalText*/)
oReport:SetLandscape()//Paisagem
oReport:cFontBody := "Calibri"
oReport:SetLineHeight(50)// altura da linha, necessário quando aumenta a fonte
oReport:nFontBody := 10
oSection:SetTotalInLine(.F.)

//TRCell():New(oParent,cName,cAlias,cTitle,cPicture,nSize,lPixel,bBlock,cAlign,lLineBreak,cHeaderAlign,lCellBreak,nColSpace,lAutoSize,nClrBack,nClrFore,lBold)
TRCell():New(oSection,"ANOMES",/*Table*/,"Ano e mes"/*cTitle*/,/*Picture*/,6/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"FILIAL",/*Table*/,"Fil"/*cTitle*/,/*Picture*/,2/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"DESC_FIL",/*Table*/,"Desc Fil"/*cTitle*/,/*Picture*/,30/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBac[k*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"GRUPO_DESPESA",/*Table*/,"Grupo "+CRLF+"Custo"/*cTitle*/,/*Picture*/,4/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"CODIGO",/*Table*/,"Código"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"CC_UNIFICADO",/*Table*/,"CC "+CRLF+"Unificado"/*cTitle*/,/*Picture*/,9/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"DESC_CC_UNIFICADO",/*Table*/,"Desc "+CRLF+"CC Unif"/*cTitle*/,/*Picture*/,30/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"CENTRO_CUSTO",/*Table*/,"Centro "+CRLF+"Custo"/*cTitle*/,/*Picture*/,9/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"DESC_CENTRO_CUSTO",/*Table*/,"Desc C Custo"/*cTitle*/,/*Picture*/,40/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"CONTA",/*Table*/,"Conta "+CRLF+"Contábil"/*cTitle*/,/*Picture*/,20/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"CT1_DESC01","CT1"/*Table*/,"Desc "+CRLF+"Conta"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"CT2_LOTE",/*Table*/,"Lote "+CRLF+"Contábil"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"CT2_LP","CT2"/*Table*/,"LP"/*cTitle*/,/*Picture*/,3/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"CT2_ORIGEM","CT2"/*Table*/,"Origem"/*cTitle*/,/*Picture*/,20/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"CT2_VALOR","CT2"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)

Return oReport

/*
===============================================================================================================================
Programa----------: ReportPrint
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 14/02/2022
Descrição---------: Processa impressão do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ReportPrint(oReport,_aOrdem)

Local _cFiltro	:= "%"
Local _cCampos  := "%%"
Local _cCamposD := "%%"
Local _cCamposC := "%%"
Local _cGroupD  := "%%"
Local _cGroupC  := "%%"
Local _cGroup   := "%%"
Local _cAlias	:= ""
Local _aSelFil	:= {}
Local _nOrdem	:= oReport:Section(1):GetOrder() 
Local _lPlanilha:= oReport:nDevice == 4
Local _cFilial	:= ""
Local _cGrpDesp := ""

//Chama função que permitirá a seleção das filiais
If MV_PAR01 == 1
	If Empty(_aSelFil)
		_aSelFil := AdmGetFil(.F.,.F.,"SF1")
	EndIf
Else
	aAdd(_aSelFil,cFilAnt)
EndIf

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
oQbrUnif:= TRBreak():New( oReport:Section(1)/*oParent*/, oReport:Section(1):Cell("GRUPO_DESPESA") /*uBreak*/, {||"Total: " + _cGrpDesp } /*uTitle*/, .F. /*lTotalInLine*/,/*cName*/,.F./*lPageBreak*/)
TRFunction():New(oReport:Section(1):Cell("VALOR")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrUnif/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)

oQbrFilial	:= TRBreak():New( oReport:Section(1)/*oParent*/, oReport:Section(1):Cell("FILIAL")/*uBreak*/, {||"Total da Filial: " + _cFilial}/*uTitle*/, .F. /*lTotalInLine*/,/*cName*/,.T./*lPageBreak*/)
TRFunction():New(oReport:Section(1):Cell("VALOR")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)


//==========================================================================
// Trata as células a serem exibidas de acordo com sessão e parâmetros
//==========================================================================
If MV_PAR10 = 2// 1-Analítico 2-Sintético
	oReport:Section(1):Cell("DESC_CENTRO_CUSTO"):Disable()
	oReport:Section(1):Cell("CENTRO_CUSTO"):Disable()
	oReport:Section(1):Cell("CONTA"):Disable()
  oReport:Section(1):Cell("CT1_DESC01"):Disable()
	oReport:Section(1):Cell("CT2_LOTE"):Disable()
	oReport:Section(1):Cell("CT2_LP"):Disable()
	oReport:Section(1):Cell("CT2_ORIGEM"):Disable()
EndIf

If !_lPlanilha
	oReport:Section(1):Cell("DESC_FIL"):Disable()
  oReport:Section(1):Cell("CT2_LP"):Disable()
  oReport:Section(1):Cell("CT1_DESC01"):Disable()
  oReport:Section(1):Cell("CODIGO"):Disable()
EndIf

//====================================================================================================
// Monta filtro de acordo com a tabela de origem
//====================================================================================================
_cFiltro += " AND CT2.CT2_FILORI "+ GetRngFil( _aSelFil, "SF1", .T.,)
_cFiltro += " %"
If MV_PAR10 = 1// 1-Analítico 2-Sintético
  _cCamposD := "%, CT2_DEBITO CONTA, CT2_LP, CT2_ORIGEM, CT2_LOTE, CT1_DESC01 %"
  _cGroupD := "%, CT2_DEBITO, CT2_LP, CT2_ORIGEM, CT2_LOTE, CT1_DESC01 %"
  _cCamposC := "%, CT2_CREDIT CONTA, CT2_LP, CT2_ORIGEM, CT2_LOTE, CT1_DESC01 %"
  _cGroupC := "%, CT2_CREDIT, CT2_LP, CT2_ORIGEM,  CT2_LOTE, CT1_DESC01 %"
  _cCampos := "%, CTT.CTT_CUSTO CENTRO_CUSTO, CTT.CTT_DESC01 DESC_CENTRO_CUSTO, CONTA, CT1_DESC01, CT2_LOTE, CT2_LP, CT2_ORIGEM  %"
  _cGroup := "%, CTT.CTT_CUSTO, CTT.CTT_DESC01, CONTA, CT1_DESC01, CT2_LP, CT2_LOTE, CT2_ORIGEM %"
EndIf
//==========================================================================
// Query do relatório da secao 1                                            
//==========================================================================
oReport:Section(1):BeginQuery()
_cAlias := GetNextAliasints()

oReport:SetMsgPrint("Consultando registros no Banco de Dados")
oReport:SetMeter(0)

BeginSql alias _cAlias
SELECT ANOMES, CT2_FILORI FILIAL, FIL.M0_FILIAL DESC_FIL, CT1_I_UNIF GRUPO_DESPESA, RTRIM(CT1_I_UNIF)||S.CTT_CUSTO CODIGO, S.CTT_CUSTO CC_UNIFICADO, S.CTT_DESC01 DESC_CC_UNIFICADO, SUM(CT2_VALOR) CT2_VALOR %exp:_cCampos%
  FROM %Table:CTT% CTT, SYS_COMPANY FIL, %Table:CTT% S,
       (SELECT SubStr(CT2_DATA,1,6) ANOMES, CT2_FILORI, CT1_I_UNIF, CT2_CCD CCUSTO, SUM(CT2_VALOR) * -1 CT2_VALOR %exp:_cCamposD%
          FROM %Table:CT2% CT2, %Table:CT1% CT1
         WHERE CT2.D_E_L_E_T_ = ' '
           AND CT1.D_E_L_E_T_ = ' '
           AND CT1_CONTA = CT2_DEBITO
           AND CT1_I_UNIF <> 'NAO'
           %exp:_cFiltro%
           AND CT2_DATA BETWEEN %exp:MV_PAR02% AND %exp:MV_PAR03%
           AND CT2_DEBITO BETWEEN '3299' AND '3299ZZZZZZ'
           AND CT2_DEBITO BETWEEN %exp:MV_PAR04% AND %exp:MV_PAR05%
           AND CT1_I_UNIF BETWEEN %exp:MV_PAR08% AND %exp:MV_PAR09%
         GROUP BY SubStr(CT2_DATA,1,6), CT2_FILORI, CT1_I_UNIF, CT2_CCD %exp:_cGroupD%
        UNION
        SELECT SubStr(CT2_DATA,1,6) ANOMES, CT2_FILORI, CT1_I_UNIF, CT2_CCC CCUSTO, SUM(CT2_VALOR) CT2_VALOR %exp:_cCamposC%
          FROM %Table:CT2% CT2, %Table:CT1% CT1
         WHERE CT2.D_E_L_E_T_ = ' '
           AND CT1.D_E_L_E_T_ = ' '
           AND CT1_CONTA = CT2_CREDIT
           AND CT1_I_UNIF <> 'NAO'
           %exp:_cFiltro%
           AND CT2_DATA BETWEEN %exp:MV_PAR02% AND %exp:MV_PAR03%
           AND CT2_CREDIT BETWEEN '3299' AND '3299ZZZZZZ'
           AND CT2_CREDIT BETWEEN %exp:MV_PAR04% AND %exp:MV_PAR05%
           AND CT1_I_UNIF BETWEEN %exp:MV_PAR08% AND %exp:MV_PAR09%
         GROUP BY SubStr(CT2_DATA,1,6), CT2_FILORI, CT1_I_UNIF, CT2_CCC %exp:_cGroupC%
       ) MOV
 WHERE CTT.D_E_L_E_T_(+) = ' '
   AND S.D_E_L_E_T_(+) = ' '
   AND FIL.D_E_L_E_T_ = ' '
   AND FIL.M0_CODFIL = CT2_FILORI
   AND S.CTT_DESC01(+) = CT1_I_UNIF || CTT.CTT_I_UNIF
   AND MOV.CCUSTO = CTT.CTT_CUSTO(+)
   AND CTT.CTT_CUSTO (+) BETWEEN %exp:MV_PAR06% AND %exp:MV_PAR07%
 GROUP BY ANOMES, CT2_FILORI, FIL.M0_FILIAL, CT1_I_UNIF, S.CTT_CUSTO, S.CTT_DESC01 %exp:_cGroup%
 ORDER BY ANOMES, CT2_FILORI, CT1_I_UNIF, S.CTT_CUSTO
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
oReport:SetMsgPrint("Imprimindo")
oReport:SetMeter(0)

While !oReport:Cancel() .And. (_cAlias)->(!Eof())
	oReport:Section(1):PrintLine()
	oReport:IncMeter()
	_cFilial := (_cAlias)->FILIAL+' - '+(_cAlias)->DESC_FIL
	_cGrpDesp := (_cAlias)->GRUPO_DESPESA
	(_cAlias)->(DBSkip())
EndDo

oReport:Section(1):Finish()
(_cAlias)->(DBCloseArea())

Return
