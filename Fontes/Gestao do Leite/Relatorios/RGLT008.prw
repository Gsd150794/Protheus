/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |27/07/2022| Chamado 40778. Tratamento para Extrato Seco Total (EST)
Lucas Borges  |24/01/2023| Chamado 42685. Corrigida coluna de médias
Lucas Borges  |31/01/2025| Chamado 49642. Implementada faixa de início e fim para pagamento do excedente de matéria gorda
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RGLT008
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 27/07/2022
Descrição---------: Análises de gordura/ Extrato Seco Total - Leite de Terceiros
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RGLT008()

Local oReport
Pergunte("RGLT008",.F.)
//Inferface de Impressão
oReport := ReportDef()
oReport:PrintDialog()

Return

/*
===============================================================================================================================
Programa----------: ReportDef
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 27/07/2022
Descrição---------: Definição do Componente
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ReportDef()

Local oReport
Local oSection
Local _aOrdem   := {"Filial+Produto"}

//Criacao do componente de impressao
//TReport():New
//ExpC1 : Nome do relatorio
//ExpC2 : Titulo
//ExpC3 : Pergunte
//ExpB4 : Bloco de codigo que sera executado na confirmacao da impressao
//ExpC5 : Descricao

oReport := TReport():New("RGLT008","Análise Matéria Gorda/ Extrato Seco Total","RGLT008",;
{|oReport| ReportPrint(oReport,_aOrdem)},"Apresenta informações referente aos movimentos do Leite de terceiros para Matéria Gorda e Extrato Seco Total.")
oSection := TRSection():New(oReport,"Movimentos"	,/*uTable {}*/, _aOrdem/*aOrder*/, .F./*lLoadCells*/, .T./*lLoadOrder*/,"Total das Filiais: "/*uTotalText*/)
oReport:SetLandscape()//Paisagem
oSection:SetTotalInLine(.F.)

//TRCell():New(oParent,cName,cAlias,cTitle,cPicture,nSize,lPixel,bBlock,cAlign,lLineBreak,cHeaderAlign,lCellBreak,nColSpace,lAutoSize,nClrBack,nClrFore,lBold)
TRCell():New(oSection,"ZZX_FILIAL","ZZX","Fil"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZZX_CODPRD","ZZX",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"X5_DESCRI",/*Table*/,"Produto"/*cTitle*/,/*Picture*/,20/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLX_TIPOLT",/*Table*/,"Procedência"/*cTitle*/,/*Picture*/,15/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_NREDUZ",/*Table*/,"Fornecedor"/*cTitle*/,/*Picture*/,35/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLX_DTENTR","ZLX"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZZX_HORA","ZZX"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"TRANSP",/*Table*/,"Transp."/*cTitle*/,/*Picture*/,35/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLD_RETIRO","ZLD"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLD_RETILJ",/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"PRODUTOR",/*Table*/,"Produtor"/*cTitle*/,/*Picture*/,35/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZZX_PLACA","ZZX"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZZV_CAPACI","ZZV"/*Table*/,"Capacid."/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,"RIGHT"/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZZX_DENSID","ZZX"/*Tabela*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"X01_GORD",/*Tabela*/,"Gordura"+CRLF+" 01"/*cTitle*/, "@E 99.99"/*Picture*/,5/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"X02_GORD",/*Tabela*/,"Gordura"+CRLF+" 02"/*cTitle*/, "@E 99.99"/*Picture*/,5/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"X03_GORD",/*Tabela*/,"Gordura"+CRLF+" 03"/*cTitle*/, "@E 99.99"/*Picture*/,5/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"X04_GORD",/*Tabela*/,"Gordura"+CRLF+" 04"/*cTitle*/, "@E 99.99"/*Picture*/,5/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"X05_GORD",/*Tabela*/,"Gordura"+CRLF+" 05"/*cTitle*/, "@E 99.99"/*Picture*/,5/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"X06_GORD",/*Tabela*/,"Gordura"+CRLF+" 06"/*cTitle*/, "@E 99.99"/*Picture*/,5/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"MEDIA_MG",/*Tabela*/,"Média"+CRLF+" MG"/*cTitle*/, "@E 99.99"/*Picture*/,5/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"X01_EST",/*Tabela*/,"Extrato"+CRLF+" 01"/*cTitle*/, "@E 99.99"/*Picture*/,5/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"X02_EST",/*Tabela*/,"Extrato"+CRLF+" 02"/*cTitle*/, "@E 99.99"/*Picture*/,5/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"X03_EST",/*Tabela*/,"Extrato"+CRLF+" 03"/*cTitle*/, "@E 99.99"/*Picture*/,5/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"X04_EST",/*Tabela*/,"Extrato"+CRLF+" 04"/*cTitle*/, "@E 99.99"/*Picture*/,5/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"X05_EST",/*Tabela*/,"Extrato"+CRLF+" 05"/*cTitle*/, "@E 99.99"/*Picture*/,5/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"X06_EST",/*Tabela*/,"Extrato"+CRLF+" 06"/*cTitle*/, "@E 99.99"/*Picture*/,5/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"MEDIA_EST",/*Tabela*/,"Média"+CRLF+" Extrato"/*cTitle*/, "@E 99.99"/*Picture*/,5/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZAP_CODIGO","ZAP"/*Tabela*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLX_CODIGO","ZLX"/*Tabela*/,"Recepção"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLD_QTDBOM","ZLD"/*Tabela*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLA_FXINI","ZLA"/*Tabela*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLA_FXFIM","ZLA"/*Tabela*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLA_VALOR","ZLA"/*Tabela*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"DESCARTE",/*Tabela*/,"Descarte"/*cTitle*/,"@E 99.99"/*Picture*/,5/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"EXCEDENTE",/*Tabela*/,"Excedente"/*cTitle*/,"@E 999,999.9999"/*Picture*/,12/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)

Return oReport

/*
===============================================================================================================================
Programa----------: ReportPrint
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 27/07/2022
Descrição---------: Processa impressão do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ReportPrint(oReport,_aOrdem)

Local _cFiltro	:= "%"
Local _cTabela  := "%%"
Local _cCampos1 := "%%"
Local _cCampos2 := "%%"
Local _cAlias	:= ""
Local _aSelFil	:= {}
Local _nOrdem	:= oReport:Section(1):GetOrder() 
Local _lPlanilha:= oReport:nDevice == 4
Local _cFilial	:= ""
Local _cFornece := ""

//Chama função que permitirá a seleção das filiais
If MV_PAR13 == 1
	If Empty(_aSelFil)
		_aSelFil := AdmGetFil(.F.,.F.,"ZZX")
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

//==========================================================================
// Transforma parametros Range em expressao SQL                             	
//==========================================================================
MakeSqlExpr(oReport:uParam)

//================================================================================
//| Configuração das quebras do relatório                                        |
//================================================================================
oQbrFor	:= TRBreak():New( oReport:Section(1)/*oParent*/, oReport:Section(1):Cell("A2_NREDUZ") /*uBreak*/, {||"Total do Fornecedor: " + _cFornece } /*uTitle*/, .F. /*lTotalInLine*/,/*cName*/,.F./*lPageBreak*/)
TRFunction():New(oReport:Section(1):Cell("ZZX_DENSID")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrFor/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("X01_GORD")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrFor/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("X02_GORD")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrFor/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("X03_GORD")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrFor/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("X04_GORD")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrFor/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("X05_GORD")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrFor/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("X05_GORD")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrFor/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("MEDIA_MG")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrFor/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("X01_EST")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrFor/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("X02_EST")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrFor/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("X03_EST")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrFor/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("X04_EST")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrFor/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("X05_EST")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrFor/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("X05_EST")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrFor/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("MEDIA_EST")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrFor/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("ZLD_QTDBOM")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFor/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("EXCEDENTE")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFor/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)

oQbrFilial	:= TRBreak():New( oReport:Section(1)/*oParent*/, oReport:Section(1):Cell("ZZX_FILIAL")/*uBreak*/, {||"Total da Filial: " + _cFilial + ' - '+ FWFilialName(cEmpAnt,_cFilial,1 )}/*uTitle*/, .F. /*lTotalInLine*/,/*cName*/,.T./*lPageBreak*/)
TRFunction():New(oReport:Section(1):Cell("ZZX_DENSID")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("X01_GORD")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("X02_GORD")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("X03_GORD")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("X04_GORD")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("X05_GORD")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("X05_GORD")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("MEDIA_MG")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("X01_EST")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("X02_EST")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("X03_EST")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("X04_EST")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("X05_EST")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("X05_EST")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("MEDIA_EST")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("ZLD_QTDBOM")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("EXCEDENTE")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)


//==========================================================================
// Trata as células a serem exibidas de acordo com sessão e parâmetros
//==========================================================================
If !_lPlanilha
	oReport:Section(1):Cell("ZLD_RETIRO"):Disable()
  oReport:Section(1):Cell("ZLD_RETILJ"):Disable()
  oReport:Section(1):Cell("ZZX_CODPRD"):Disable()
	oReport:Section(1):Cell("X04_GORD"):Disable()
	oReport:Section(1):Cell("X05_GORD"):Disable()
	oReport:Section(1):Cell("X06_GORD"):Disable()
	oReport:Section(1):Cell("X04_EST"):Disable()
	oReport:Section(1):Cell("X05_EST"):Disable()
	oReport:Section(1):Cell("X06_EST"):Disable()
  oReport:Section(1):Cell("PRODUTOR"):Disable()
  oReport:Section(1):Cell("ZLD_QTDBOM"):Disable()
  oReport:Section(1):Cell("ZLA_FXINI"):Disable()
  oReport:Section(1):Cell("ZLA_FXFIM"):Disable()
  oReport:Section(1):Cell("ZLA_VALOR"):Disable()
  oReport:Section(1):Cell("DESCARTE"):Disable()
  oReport:Section(1):Cell("EXCEDENTE"):Disable()
EndIf

//====================================================================================================
// Monta filtro de acordo com a tabela de origem
//====================================================================================================
_cFiltro += " AND ZZX.ZZX_FILIAL "+ GetRngFil( _aSelFil, "ZZX", .T.,)
If !Empty(MV_PAR04)
	_cFiltro += " AND ZZX.ZZX_CODPRD IN "+ FormatIn( MV_PAR04 , ';' )
EndIf

If MV_PAR03 == 3
  _cTabela:= "% , "+RetSqlName("ZLD")+" ZLD, "+RetSqlName("ZLA")+" ZLA %"
  _cCampos1 := "%, ZLD_RETIRO, ZLD_RETILJ, ZLD_QTDBOM, ZLA_VALOR "
  _cCampos2 := _cCampos1+ ",(SELECT A2_NREDUZ FROM "+RetSqlName("SA2")+" WHERE D_E_L_E_T_ = ' ' AND ZLD.ZLD_RETIRO = A2_COD AND ZLD.ZLD_RETILJ = A2_LOJA) PRODUTOR, "
  _cCampos2 += " (SELECT MIN(ZLAA.ZLA_FXFIM) FROM "+RetSqlName("ZLA")+" ZLAA
  _cCampos2 += "    WHERE  ZLAA.ZLA_FILIAL = ZLX.ZLX_FILIAL
  _cCampos2 += "    AND ZLAA.ZLA_SETOR = ZLD_SETOR
  _cCampos2 += "    AND ZLX.ZLX_DTENTR BETWEEN ZLAA.ZLA_DTINI AND ZLAA.ZLA_DTFIM
  _cCampos2 += "    AND ZLAA.ZLA_MATGOR = '1'
  _cCampos2 += "    AND ZLAA.D_E_L_E_T_ = ' '
  _cCampos2 += " ) DESCARTE, ZLA_FXINI, ZLA_FXFIM %"
  _cCampos1 += ", PRODUTOR, DESCARTE, (MEDIA_MG-DESCARTE)*ZLD_QTDBOM/100*ZLA_VALOR EXCEDENTE %"
  
  _cFiltro += " AND ZLX.ZLX_TIPOLT = 'P' "
  _cFiltro += " AND ZLD.D_E_L_E_T_ = ' ' "
  _cFiltro += " AND ZLD.ZLD_FILIAL = ZLX.ZLX_FILIAL "
  _cFiltro += " AND ZLD.ZLD_TICKET = ZLX.ZLX_TICKET "
  _cFiltro += " AND ZLD.ZLD_SETOR = ZLX.ZLX_SETOR "
  _cFiltro += " AND ZLD.ZLD_RETIRO <> ' ' "
  _cFiltro += " AND ZLD.ZLD_RETIRO BETWEEN '"+MV_PAR14+"' AND '"+MV_PAR16+"'"
  _cFiltro += " AND ZLD.ZLD_RETILJ BETWEEN '"+MV_PAR15+"' AND '"+MV_PAR17+"'"
  _cFiltro += " AND ZLA.ZLA_FILIAL = ZLX.ZLX_FILIAL "
  _cFiltro += " AND ZLA.ZLA_SETOR = ZLX.ZLX_SETOR"
  _cFiltro += " AND NVL(Round((SELECT SUM(ZAP_GORD) / COUNT(1) "
  _cFiltro += "                            FROM "+RetSqlName("ZAP")+" AP2 "
  _cFiltro += "                           WHERE AP2.D_E_L_E_T_ = ' ' "
  _cFiltro += "                             AND AP2.ZAP_FILIAL = ZZX.ZZX_FILIAL "
  _cFiltro += "                             AND ZZX.ZZX_CODIGO = AP2.ZAP_CODIGO), "
  _cFiltro += "                          2), "
  _cFiltro += "                    0) BETWEEN ZLA_FXINI AND ZLA_FXFIM "
  _cFiltro += "            AND ZLX.ZLX_DTENTR BETWEEN ZLA.ZLA_DTINI AND ZLA.ZLA_DTFIM "
  _cFiltro += "            AND ZLA.ZLA_MATGOR = '1' "
  _cFiltro += "            AND ZLA.D_E_L_E_T_ = ' ' "
Else
  _cTabela:= "% , "+RetSqlName("SF1")+" SF1, "+RetSqlName("SD1")+" SD1, "+RetSqlName("SC7")+" SC7 %"
  
  _cCampos1 := "%, '' ZLD_RETIRO, '' ZLD_RETILJ, 0 ZLD_QTDBOM, "
  _cCampos1 += " NVL(Round(Case WHEN NVL(Round(MEDIA_MG, 2), 0) > C7_L_PMGB AND NVL(Round(MEDIA_MG, 2), 0) <= C7_L_PMGB2 THEN C7_L_EXEMG
  _cCampos1 += " WHEN NVL(Round(MEDIA_MG, 2), 0) > C7_L_PMGB2 THEN C7_L_EXEM2 Else 0 END, 2), 0) ZLA_VALOR, '' PRODUTOR, "
  _cCampos1 += " MEDIA_MG-ZLA_FXINI DESCARTE, "
  _cCampos1 += "NVL(Round(((((NVL(Round(MEDIA_MG,2),0) - C7_L_PMGB) * ZLX_VOLREC) / 100) * "
  _cCampos1 += "     Case WHEN NVL(Round(MEDIA_MG, 2),0) > C7_L_PMGB AND NVL(Round(MEDIA_MG, 2),0) <= C7_L_PMGB2 THEN C7_L_EXEMG "
  _cCampos1 += "          WHEN NVL(Round(MEDIA_MG, 2),0) > C7_L_PMGB2 THEN C7_L_EXEM2 Else 0 END),2),0) EXCEDENTE %"
  _cCampos2 := "%, ZLX_VOLREC, C7_PRECO, C7_L_PMGB, C7_L_PMGB2, C7_L_EXEMG,C7_L_EXEM2, C7_L_PMGB ZLA_FXINI, C7_L_PMGB2 ZLA_FXFIM %"
  
  _cFiltro += " AND SF1.D_E_L_E_T_ = ' ' "
  _cFiltro += " AND SC7.D_E_L_E_T_ = ' ' "
  _cFiltro += " AND SD1.D_E_L_E_T_ = ' ' "
  _cFiltro += " AND SF1.F1_FILIAL = SD1.D1_FILIAL "
  _cFiltro += " AND SF1.F1_DOC = SD1.D1_DOC "
  _cFiltro += " AND SF1.F1_SERIE = SD1.D1_SERIE "
  _cFiltro += " AND SF1.F1_FORNECE = SD1.D1_FORNECE "
  _cFiltro += " AND SF1.F1_LOJA = SD1.D1_LOJA "
  _cFiltro += " AND ZLX.ZLX_FILIAL = SD1.D1_FILIAL "
  _cFiltro += " AND ZLX.ZLX_NRONF = SD1.D1_DOC "
  _cFiltro += " AND ZLX.ZLX_SERINF = SD1.D1_SERIE "
  _cFiltro += " AND ZLX.ZLX_FORNEC = SD1.D1_FORNECE "
  _cFiltro += " AND ZLX.ZLX_LJFORN = SD1.D1_LOJA "
  _cFiltro += " AND SD1.D1_FILIAL = SC7.C7_FILIAL "
  _cFiltro += " AND SD1.D1_PEDIDO = SC7.C7_NUM "
  _cFiltro += " AND SD1.D1_ITEMPC = SC7.C7_ITEM "
  _cFiltro += " AND SC7.C7_FILIAL = ZZX.ZZX_FILIAL "
  _cFiltro += " AND ZZX.ZZX_FILIAL = SD1.D1_FILIAL "
  _cFiltro += " AND SD1.D1_FORMUL <> 'S' "
  _cFiltro += " AND SF1.F1_STATUS = 'A' "

  If MV_PAR03 == 1 
    _cFiltro += " AND ZLX.ZLX_TIPOLT = 'F' "
  ElseIf MV_PAR03 == 2 
    _cFiltro += " AND ZLX.ZLX_TIPOLT = 'T' "
  Else
    _cFiltro += " AND ZLX.ZLX_TIPOLT IN ('F','T') "
  EndIf
EndIf

_cFiltro += " %"

//==========================================================================
// Query do relatório da secao 1                                            
//==========================================================================
oReport:Section(1):BeginQuery()
_cAlias := GetNextAlias()

oReport:SetMsgPrint("Consultando registros no Banco de Dados")
oReport:SetMeter(0)

BeginSql alias _cAlias
SELECT ZZX_FILIAL, ZZX_CODPRD, X5_DESCRI, ZLX_TIPOLT, A2_NREDUZ, ZLX_DTENTR, ZZX_HORA, TRANSP, ZZX_PLACA, ZZV_CAPACI, ZZX_DENSID,
       NVL(X01_GORD,0) X01_GORD, NVL(X02_GORD,0) X02_GORD, NVL(X03_GORD,0) X03_GORD, NVL(X04_GORD,0) X04_GORD, NVL(X05_GORD,0) X05_GORD, NVL(X06_GORD,0) X06_GORD, MEDIA_MG,
       NVL(X01_EST,0) X01_EST, NVL(X02_EST,0) X02_EST, NVL(X03_EST,0) X03_EST, NVL(X04_EST,0) X04_EST, NVL(X05_EST,0) X05_EST, NVL(X06_EST,0) X06_EST, MEDIA_EST,
       ZAP_CODIGO, ZLX_CODIGO, ZLA_FXINI, ZLA_FXFIM %exp:_cCampos1%
  FROM (SELECT ZZX.ZZX_FILIAL, ZZX.ZZX_CODPRD, SX5.X5_DESCRI, ZAP.ZAP_CODIGO, ZAP.ZAP_ITEM, ZLX.ZLX_TIPOLT,
               A2F.A2_NREDUZ, ZLX.ZLX_DTENTR, ZZX.ZZX_HORA, A2T.A2_NREDUZ TRANSP, ZZX.ZZX_PLACA, ZZV.ZZV_CAPACI, ZZX.ZZX_DENSID, ZAP.ZAP_GORD, ZAP.ZAP_EST, ZLX_CODIGO,
               NVL(Round((SELECT SUM(ZAP_GORD) / COUNT(1)
                           FROM %Table:ZAP% AP2
                          WHERE AP2.D_E_L_E_T_ = ' '
                            AND AP2.ZAP_FILIAL = ZZX.ZZX_FILIAL
                            AND ZZX.ZZX_CODIGO = AP2.ZAP_CODIGO),2),0) MEDIA_MG,
               NVL(Round((SELECT SUM(ZAP_EST) / COUNT(1)
                           FROM %Table:ZAP% AP2
                          WHERE AP2.D_E_L_E_T_ = ' '
                            AND AP2.ZAP_FILIAL = ZZX.ZZX_FILIAL
                            AND ZZX.ZZX_CODIGO = AP2.ZAP_CODIGO),2),0) MEDIA_EST
                            %exp:_cCampos2%
          FROM %Table:SA2% A2T, %Table:SA2% A2F, %Table:ZZX% ZZX, %Table:ZZV% ZZV, %Table:ZAP% ZAP, %Table:SX5% SX5, %Table:ZLX% ZLX %exp:_cTabela%
         WHERE ZZV.D_E_L_E_T_ = ' '
           AND ZZX.D_E_L_E_T_ = ' '
           AND ZAP.D_E_L_E_T_ = ' '
           AND A2T.D_E_L_E_T_ = ' '
           AND A2F.D_E_L_E_T_ = ' '
           AND SX5.D_E_L_E_T_ = ' '
           AND ZLX.D_E_L_E_T_ = ' '
           AND ZZV.ZZV_FILIAL = %xFilial:ZZV%
           AND ZZV.ZZV_FILIAL = ZZX.ZZX_FILIAL
           AND ZAP.ZAP_FILIAL = ZZX.ZZX_FILIAL
           AND ZZV.ZZV_FILIAL = ZZX.ZZX_FILIAL
           AND ZZX.ZZX_FILIAL = ZAP.ZAP_FILIAL
           AND ZZX.ZZX_FORNEC = A2F.A2_COD
           AND ZZX.ZZX_LJFORN = A2F.A2_LOJA
           AND ZZX.ZZX_TRANSP = A2T.A2_COD
           AND ZZX.ZZX_LJTRAN = A2T.A2_LOJA
           AND ZZX.ZZX_PLACA = ZZV.ZZV_PLACA
           AND ZZX.ZZX_TRANSP = ZZV.ZZV_TRANSP
           AND ZZX.ZZX_LJTRAN = ZZV.ZZV_LJTRAN
           AND ZZX.ZZX_CODIGO = ZAP.ZAP_CODIGO
           AND ZZX_CODPRD = SX5.X5_CHAVE
           AND SX5.X5_TABELA = 'Z7'
           AND ZLX.ZLX_FILIAL = ZZX.ZZX_FILIAL
           AND ZZX.ZZX_CODIGO = ZLX.ZLX_CODANA
		       %exp:_cFiltro%
           AND ZLX.ZLX_DTENTR BETWEEN %exp:MV_PAR01% AND %exp:MV_PAR02%
           AND ZZX.ZZX_FORNEC BETWEEN %exp:MV_PAR05% AND %exp:MV_PAR07%
           AND ZZX.ZZX_LJFORN BETWEEN %exp:MV_PAR06% AND %exp:MV_PAR08%
           AND ZZX.ZZX_TRANSP BETWEEN %exp:MV_PAR09% AND %exp:MV_PAR11%
           AND ZZX.ZZX_LJTRAN BETWEEN %exp:MV_PAR10% AND %exp:MV_PAR12%
        ) PIVOT(MAX(ZAP_GORD) GORD, MAX(ZAP_EST) EST
   For ZAP_ITEM IN('01' AS X01, '02' AS X02, '03' AS X03, '04' AS X04, '05' AS X05, '06' AS X06))
 ORDER BY ZZX_FILIAL, ZZX_CODPRD, ZLX_TIPOLT, A2_NREDUZ, ZLX_DTENTR, ZZX_HORA, ZAP_CODIGO
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
	_cFilial := (_cAlias)->ZZX_FILIAL
	_cFornece := (_cAlias)->A2_NREDUZ
	(_cAlias)->(DBSkip())
EndDo

oReport:Section(1):Finish()
(_cAlias)->(DBCloseArea())

Return
