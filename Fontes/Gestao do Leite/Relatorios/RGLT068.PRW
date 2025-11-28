/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |24/01/2023| Chamado 42685. Corrigida query
Lucas Borges  |13/06/2023| Chamado 44114. Corrigida query para forçar o ZL1_PLACA nas ordens 4 e 5
Lucas Borges  |13/06/2023| Chamado 49953. Corrigido filtro de placa
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RGLT068
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 10/06/2021
Descrição---------: Relatório Frete Primeiro Percurso com informações referente ao frete dos transportadores de leite para 
					análise de custos. Chamado 36783
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RGLT068

Local oReport
Pergunte("RGLT068",.F.)
//Inferface de Impressão
oReport := ReportDef()
oReport:PrintDialog()

Return

/*
===============================================================================================================================
Programa----------: ReportDef
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 05/06/2021
Descrição---------: Definição do Componente
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ReportDef()

Local oReport
Local oSection
Local _aOrdem   := {"Por Filial","Por Setor","Por Transportador","Por Placa","Por Transp+Placa"}

//Criacao do componente de impressao
//TReport():New
//ExpC1 : Nome do relatorio
//ExpC2 : Titulo
//ExpC3 : Pergunte
//ExpB4 : Bloco de codigo que sera executado na confirmacao da impressao
//ExpC5 : Descricao

oReport := TReport():New("RGLT068","Relatório Frete Primeiro Percurso","RGLT068",;
{|oReport| ReportPrint(oReport,_aOrdem)},"Relatório Frete Primeiro Percurso")
oSection := TRSection():New(oReport,"Custo Frete"	,/*uTable {}*/, _aOrdem/*aOrder*/, .F./*lLoadCells*/, .T./*lLoadOrder*/,"Total das Filiais: "/*uTotalText*/,.T./*lTotalInLine*/)
oReport:SetLandscape()//Paisagem
oSection:SetTotalInLine(.F.)

//TRCell():New(oParent,cName,cAlias,cTitle,cPicture,nSize,lPixel,bBlock,cAlign,lLineBreak,cHeaderAlign,lCellBreak,nColSpace,lAutoSize,nClrBack,nClrFore,lBold)
TRCell():New(oSection,"ZLD_FILIAL","ZLD","Fil"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZL2_COD","ZL2","Setor"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZL2_DESCRI","ZL2",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZL1_PLACA","ZL1",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZL1_CAPACI","ZL1",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLD_TICKET","ZLD",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLD_VFILHA","ZLD",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"TRANS",/*cAlias*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_COD","SA2",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_LOJA","SA2",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_NOME","SA2","Fretista"/*cTitle*/,/*Picture*/,35/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLD_MOTOR","ZLD",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZL0_NOME","ZL0",/*cTitle*/,/*Picture*/,35/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLD_DTCOLE","ZLD",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZFF_DESCRI","ZFF","Tipo Veículo"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"VCOL_FILHA",/*cAlias*/,"Vol.Col."+CRLF+"Filha"/*cTitle*/,"@E 9,999,999,999"/*Picture*/,14/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"VREC_FILHA",/*cAlias*/,"Vol.Rec."+CRLF+"Filha"/*cTitle*/,"@E 9,999,999,999"/*Picture*/,14/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"PRO_FILHA",/*cAlias*/,"Pró/Contra"+CRLF+"Filha"/*cTitle*/,"@E 999,999"/*Picture*/,7/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"VCOL_SET",/*cAlias*/,"Vol.Col."+CRLF+"Setor"/*cTitle*/,"@E 9,999,999,999"/*Picture*/,14/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"VREC_SET",/*cAlias*/,"Vol.Rec."+CRLF+"Setor"/*cTitle*/,"@E 9,999,999,999"/*Picture*/,14/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"PRO_SET",/*cAlias*/,"Pró/Contra"+CRLF+"Setor"/*cTitle*/,"@E 999,999"/*Picture*/,7/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"VREC_TICK",/*cAlias*/,"Vol.Rec."+CRLF+"Ticket"/*cTitle*/,"@E 9,999,999,999"/*Picture*/,14/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"KM",/*cAlias*/,"Km"/*cTitle*/,"@E 999,999,999"/*Picture*/,12/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"VTABFR",/*cAlias*/,"Tarifa/Km"/*cTitle*/,GetSX3Cache("ZLD_VTABFR","X3_PICTURE")/*Picture*/,GetSX3Cache("ZLD_VTABFR","X3_TAMANHO")/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"VLRFRE",/*cAlias*/,"Vlr.Base"/*cTitle*/,GetSX3Cache("ZLD_VTABFR","X3_PICTURE")/*Picture*/,GetSX3Cache("ZLD_VTABFR","X3_TAMANHO")/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"CREDFR",/*cAlias*/,"Créditos"/*cTitle*/,GetSX3Cache("ZLD_VTABFR","X3_PICTURE")/*Picture*/,GetSX3Cache("ZLD_VTABFR","X3_TAMANHO")/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"FRETE",/*cAlias*/,"Frete"/*cTitle*/,GetSX3Cache("ZLD_VTABFR","X3_PICTURE")/*Picture*/,GetSX3Cache("ZLD_VTABFR","X3_TAMANHO")/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"TOTFRE_ZLF",/*cAlias*/,"Frete ZLF"/*cTitle*/,GetSX3Cache("ZLF_TOTAL","X3_PICTURE")/*Picture*/,GetSX3Cache("ZLF_TOTAL","X3_TAMANHO")/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"CUS_LITRO",/*Table*/,"Custo/"+CRLF+"Litro"/*cTitle*/,GetSX3Cache("ZLD_VTABFR","X3_PICTURE")/*Picture*/,GetSX3Cache("ZLD_CREDFR","X3_TAMANHO")/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"TX_OCUP",/*Table*/,"Tx.Ocup.(%) "/*cTitle*/,"@E 999.99"/*Picture*/,6/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)

Return oReport

/*
===============================================================================================================================
Programa----------: ReportPrint
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 31/05/2019
Descrição---------: Processa impressão do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ReportPrint(oReport,_aOrdem)

Local _cFiltro		:= "%"
Local _cFiltro2		:= "%%"
Local _cCampos		:= "%"
Local _cOrder		:= "%"
Local _cAlias		:= ""
Local _aSelFil		:= {}
Local _nOrdem		:= oReport:Section(1):GetOrder() //1-"Por Filial",2-"Por Setor",3-"Por Transportador",4-"Por Placa",5-"Por Transp+Placa"
Local _cFilial		:= ""
Local _lPlanilha 	:= oReport:nDevice == 4
Local _nCountRec	:= 0
Local _cSetor		:= ""
Local _cTransp		:= ""
Local _cPlaca		:= ""

//Chama função que permitirá a seleção das filiais
If MV_PAR03 == 1
	If Empty(_aSelFil)
		_aSelFil := AdmGetFil(.F.,.F.,"ZLD")
	EndIf
Else
	aAdd(_aSelFil,cFilAnt)
EndIf

//=====================================================
// Adiciona a ordem escolhida ao titulo do relatorio
//=====================================================
oReport:SetTitle(oReport:Title() + " ("+AllTrim(_aOrdem[_nOrdem])+") ")

//==========================================================================
// Transforma parametros Range em expressao SQL                             	
//==========================================================================
MakeSqlExpr(oReport:uParam)

//================================================================================
// Configuração das quebras do relatório
//================================================================================
If _nOrdem <> 1  //Quebra por Setor ou Transportador
	If _nOrdem == 2
		oQbrSet	:= TRBreak():New( oReport:Section(1)/*oParent*/, oReport:Section(1):Cell("ZL2_COD") /*uBreak*/, {||"Setor: " + _cSetor}/*uTitle*/, .F. /*lTotalInLine*/,/*cName*/,.T./*lPageBreak*/)
	ElseIf _nOrdem == 3
		//oQbrSet	:= TRBreak():New( oReport:Section(1)/*oParent*/, oReport:Section(1):Cell("TRANS") /*uBreak*/, {||"Fretista: " + oReport:Section(1):Cell("A2_NOME"):GetText()}/*uTitle*/, .F. /*lTotalInLine*/,/*cName*/,.T./*lPageBreak*/)
		oQbrSet	:= TRBreak():New( oReport:Section(1)/*oParent*/, {||oReport:Section(1):Cell("A2_COD"):uPrint+oReport:Section(1):Cell("A2_LOJA"):uPrint} /*uBreak*/, {||"Fretista: " + _cTransp}/*uTitle*/, .F. /*lTotalInLine*/,/*cName*/,.T./*lPageBreak*/)
	ElseIf _nOrdem == 4
		oQbrSet	:= TRBreak():New( oReport:Section(1)/*oParent*/, oReport:Section(1):Cell("ZL1_PLACA") /*uBreak*/, {||"Placa: " + _cPlaca}/*uTitle*/, .F. /*lTotalInLine*/,/*cName*/,.T./*lPageBreak*/)
	ElseIf _nOrdem == 5
		oQbrSet	:= TRBreak():New( oReport:Section(1)/*oParent*/, {||oReport:Section(1):Cell("A2_COD"):uPrint+oReport:Section(1):Cell("A2_LOJA"):uPrint+oReport:Section(1):Cell("ZL1_PLACA"):uPrint} /*uBreak*/, {||"Placa: " + _cPlaca}/*uTitle*/, .F. /*lTotalInLine*/,/*cName*/,.T./*lPageBreak*/)
	EndIf
	oTotSVColF	:= TRFunction():New(oReport:Section(1):Cell("VCOL_FILHA")/*oCell*/,"TOTSVCOLF"/*cName*/,"SUM"/*cFunction*/,oQbrSet/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
	oTotSVRecF	:= TRFunction():New(oReport:Section(1):Cell("VREC_FILHA")/*oCell*/,"TOTSVRECF"/*cName*/,"SUM"/*cFunction*/,oQbrSet/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
	oTotSProFil := TRFunction():New(oReport:Section(1):Cell("PRO_FILHA")/*oCell*/,"TOTSPROFIL"/*cName*/,"SUM"/*cFunction*/,oQbrSet/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
	TRFunction():New(oReport:Section(1):Cell("VCOL_SET")/*oCell*/,/*cName*/,"ONPRINT"/*cFunction*/,oQbrSet/*oBreak*/,/*cTitle*/,/*cPicture*/,{|lSection,lReport,lPage| If( !lReport, oReport:Section(1):GetFunction("TOTSVCOLF"):GetValue() , oReport:Section(1):GetFunction("TOTSVCOLF"):ReportValue() ) }/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
	TRFunction():New(oReport:Section(1):Cell("VREC_SET")/*oCell*/,/*cName*/,"ONPRINT"/*cFunction*/,oQbrSet/*oBreak*/,/*cTitle*/,/*cPicture*/,{|lSection,lReport,lPage| If( !lReport, oReport:Section(1):GetFunction("TOTSVRECF"):GetValue() , oReport:Section(1):GetFunction("TOTSVRECF"):ReportValue() ) }/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
	TRFunction():New(oReport:Section(1):Cell("PRO_SET")/*oCell*/,/*cName*/,"ONPRINT"/*cFunction*/,oQbrSet/*oBreak*/,/*cTitle*/,/*cPicture*/,{|lSection,lReport,lPage| If( !lReport, oReport:Section(1):GetFunction("TOTSPROFIL"):GetValue() , oReport:Section(1):GetFunction("TOTSPROFIL"):ReportValue() ) }/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
	TRFunction():New(oReport:Section(1):Cell("VREC_TICK")/*oCell*/,/*cName*/,"ONPRINT"/*cFunction*/,oQbrSet/*oBreak*/,/*cTitle*/,/*cPicture*/,{|lSection,lReport,lPage| If( !lReport, oReport:Section(1):GetFunction("TOTSVRECF"):GetValue() , oReport:Section(1):GetFunction("TOTSVRECF"):ReportValue() ) }/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
	TRFunction():New(oReport:Section(1):Cell("KM")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrSet/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
	TRFunction():New(oReport:Section(1):Cell("VTABFR")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrSet/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,{|| Val(oReport:Section(1):Cell("VTABFR"):GetText()) > 0 }/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
	TRFunction():New(oReport:Section(1):Cell("VLRFRE")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrSet/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
	TRFunction():New(oReport:Section(1):Cell("CREDFR")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrSet/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
	oTotSFre 	:= TRFunction():New(oReport:Section(1):Cell("FRETE")/*oCell*/,"TOTSFRE"/*cName*/,"SUM"/*cFunction*/,oQbrSet/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
	TRFunction():New(oReport:Section(1):Cell("TOTFRE_ZLF")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrSet/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
	TRFunction():New(oReport:Section(1):Cell("CUS_LITRO")/*oCell*/,/*cName*/,"ONPRINT"/*cFunction*/,oQbrSet/*oBreak*/,/*cTitle*/,/*cPicture*/,{|lSection,lReport,lPage| If( !lReport, oReport:Section(1):GetFunction("TOTSFRE"):GetValue()/oReport:Section(1):GetFunction("TOTSVCOLF"):GetValue() , oReport:Section(1):GetFunction("TOTFFRE"):ReportValue()/oReport:Section(1):GetFunction("TOTFVCOLF"):ReportValue() ) }/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
	TRFunction():New(oReport:Section(1):Cell("TX_OCUP")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrSet/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
EndIf

oQbrFil		:= TRBreak():New( oReport:Section(1)/*oParent*/, oReport:Section(1):Cell("ZLD_FILIAL") /*uBreak*/, {||"Total da Filial: " + _cFilial + ' - '+ FWFilialName(cEmpAnt,_cFilial,1 )}/*uTitle*/, .F. /*lTotalInLine*/,/*cName*/,.T./*lPageBreak*/)
oTotFVColF	:= TRFunction():New(oReport:Section(1):Cell("VCOL_FILHA")/*oCell*/,"TOTFVCOLF"/*cName*/,"SUM"/*cFunction*/,oQbrFil/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.T./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
oTotFVRecF	:= TRFunction():New(oReport:Section(1):Cell("VREC_FILHA")/*oCell*/,"TOTFVRECF"/*cName*/,"SUM"/*cFunction*/,oQbrFil/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.T./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
oTotFProFil := TRFunction():New(oReport:Section(1):Cell("PRO_FILHA")/*oCell*/,"TOTFPROFIL"/*cName*/,"SUM"/*cFunction*/,oQbrFil/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.T./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("VCOL_SET")/*oCell*/,/*cName*/,"ONPRINT"/*cFunction*/,oQbrFil/*oBreak*/,/*cTitle*/,/*cPicture*/,{|lSection,lReport,lPage| If( !lReport, oReport:Section(1):GetFunction("TOTFVCOLF"):GetValue() , oReport:Section(1):GetFunction("TOTFVCOLF"):ReportValue() ) }/*uFormula*/,.F./*lEndSection*/,.T./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("VREC_SET")/*oCell*/,/*cName*/,"ONPRINT"/*cFunction*/,oQbrFil/*oBreak*/,/*cTitle*/,/*cPicture*/,{|lSection,lReport,lPage| If( !lReport, oReport:Section(1):GetFunction("TOTFVRECF"):GetValue() , oReport:Section(1):GetFunction("TOTFVRECF"):ReportValue() ) }/*uFormula*/,.F./*lEndSection*/,.T./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("PRO_SET")/*oCell*/,/*cName*/,"ONPRINT"/*cFunction*/,oQbrFil/*oBreak*/,/*cTitle*/,/*cPicture*/,{|lSection,lReport,lPage| If( !lReport, oReport:Section(1):GetFunction("TOTFPROFIL"):GetValue() , oReport:Section(1):GetFunction("TOTFPROFIL"):ReportValue() ) }/*uFormula*/,.F./*lEndSection*/,.T./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("VREC_TICK")/*oCell*/,/*cName*/,"ONPRINT"/*cFunction*/,oQbrFil/*oBreak*/,/*cTitle*/,/*cPicture*/,{|lSection,lReport,lPage| If( !lReport, oReport:Section(1):GetFunction("TOTFVRECF"):GetValue() , oReport:Section(1):GetFunction("TOTFVRECF"):ReportValue() ) }/*uFormula*/,.F./*lEndSection*/,.T./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("KM")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFil/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.T./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("VTABFR")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrFil/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.T./*lEndReport*/,/*lEndPage*/,/*oParent*/,{|| Val(oReport:Section(1):Cell("VTABFR"):GetText()) > 0 }/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("VLRFRE")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFil/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.T./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("CREDFR")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFil/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.T./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
oTotFFre 	:= TRFunction():New(oReport:Section(1):Cell("FRETE")/*oCell*/,"TOTFFRE"/*cName*/,"SUM"/*cFunction*/,oQbrFil/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.T./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("TOTFRE_ZLF")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFil/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.T./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("CUS_LITRO")/*oCell*/,/*cName*/,"ONPRINT"/*cFunction*/,oQbrFil/*oBreak*/,/*cTitle*/,/*cPicture*/,{|lSection,lReport,lPage| If( !lReport, oReport:Section(1):GetFunction("TOTFFRE"):GetValue()/oReport:Section(1):GetFunction("TOTFVCOLF"):GetValue() , oReport:Section(1):GetFunction("TOTFFRE"):ReportValue()/oReport:Section(1):GetFunction("TOTFVCOLF"):ReportValue() ) }/*uFormula*/,.F./*lEndSection*/,.T./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("TX_OCUP")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrFil/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.T./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)

//==========================================================================
// Trata as células a serem exibidas de acordo com sessão e parâmetros
//==========================================================================
oReport:Section(1):Cell("TRANS"):Disable()
If MV_PAR09 = 2// 1-Analítico 2-Sintético
	oReport:Section(1):Cell("ZL1_PLACA"):Disable()
	oReport:Section(1):Cell("ZL1_CAPACI"):Disable()
	oReport:Section(1):Cell("ZLD_TICKET"):Disable()
	oReport:Section(1):Cell("ZLD_MOTOR"):Disable()
	oReport:Section(1):Cell("ZL0_NOME"):Disable()
	oReport:Section(1):Cell("ZLD_DTCOLE"):Disable()
EndIf
If !_lPlanilha
	oReport:Section(1):Cell("ZLD_MOTOR"):Disable()
	oReport:Section(1):Cell("ZL1_CAPACI"):Disable()
	oReport:Section(1):Cell("ZL2_DESCRI"):Disable()
	oReport:Section(1):Cell("ZFF_DESCRI"):Disable()
	oReport:Section(1):Cell("VCOL_SET"):Disable()
	oReport:Section(1):Cell("VREC_SET"):Disable()
	oReport:Section(1):Cell("PRO_SET"):Disable()
	oReport:Section(1):Cell("VREC_TICK"):Disable()
	oReport:Section(1):Cell("VLRFRE"):Disable()
	oReport:Section(1):Cell("CREDFR"):Disable()
	oReport:Section(1):Cell("TOTFRE_ZLF"):Disable()
EndIf

//====================================================================================================
// Monta filtro de acordo com a tabela de origem
//====================================================================================================
_cFiltro += " AND ZLD.ZLD_FILIAL "+ GetRngFil( _aSelFil, "ZLD", .T.,)

//Se preencheu os setores, já fiz a validação de acesso no SX1
//Se não preencheu e não tem acesso a todos, filtra de forma que não retorme registros
If !Empty(MV_PAR01) .Or. Empty(MV_PAR01) .And. Posicione("ZLU",1,xFilial("ZLU")+RetCodUsr(),"ZLU_SETALL") <> 'S'
	_cFiltro += " AND ZLD.ZLD_SETOR IN "+ FormatIn( AllTrim(MV_PAR01) , ';' )
EndIf

//Verifica se foi fornecido o filtro de linha
If !Empty(MV_PAR08)
	_cFiltro += " AND ZLD.ZLD_LINROT IN " + FormatIn(AllTrim(MV_PAR08),";")
EndIf

//Verifica se foi fornecido o filtro de linha
If !Empty(MV_PAR10)
	_cFiltro2 := "% AND ZL1.ZL1_PLACA IN " + FormatIn(AllTrim(MV_PAR10),";") +" %"
EndIf

If _nOrdem == 3
	_cOrder	+= " SA2.A2_COD, SA2.A2_LOJA, ZL2.ZL2_COD "
ElseIf _nOrdem == 4
	_cOrder	+= " ZL1.ZL1_PLACA, ZL2.ZL2_COD, SA2.A2_COD, SA2.A2_LOJA "
ElseIf _nOrdem == 5
	_cOrder	+= " SA2.A2_COD, SA2.A2_LOJA, ZL1.ZL1_PLACA, ZL2.ZL2_COD "
Else
	_cOrder	+= " ZL2.ZL2_COD, SA2.A2_COD, SA2.A2_LOJA "
EndIf
If MV_PAR09 == 1// 1-Analítico 2-Sintético
	_cCampos += " RES.ZLD_TICKET, RES.ZLD_DTCOLE, RES.ZLD_VEICUL, ZL1.ZL1_CAPACI, RES.ZLD_MOTOR, ZL0.ZL0_NOME, ZL1.ZL1_NOME, ZL1.ZL1_PLACA, ZFF.ZFF_DESCRI, RES.ZLD_VFILHA, "
	_cOrder	+= " , RES.ZLD_TICKET, RES.ZLD_VFILHA"
// No analítico sempre exibir a placa. Se For ordem 4 ou 5, exibir a placa mesmo se For o sintético
ElseIf _nOrdem == 4 .Or. _nOrdem == 5
	_cCampos += " ZL1.ZL1_PLACA, "
EndIf
_cFiltro += "%"
_cCampos += "%"
_cOrder += "%"
//==========================================================================
// Query do relatório da secao 1                                            
//==========================================================================
oReport:Section(1):BeginQuery()	
_cAlias := GetNextAlias()

oReport:SetMsgPrint("Consultando registros no Banco de Dados")
oReport:SetMeter(0)

BeginSql alias _cAlias
	SELECT RES.ZLD_FILIAL, ZL2.ZL2_COD, ZL2.ZL2_DESCRI, %exp:_cCampos% 
		SA2.A2_COD || SA2.A2_LOJA TRANS, SA2.A2_COD, SA2.A2_LOJA, SA2.A2_NOME,
		SUM(RES.VCOL_FILHA) VCOL_FILHA,
		Case WHEN SUM(DISTINCT RES.VCOL_SET) * SUM(DISTINCT RES.VREC_SET) = 0 THEN 0 Else SUM(RES.VCOL_FILHA) / SUM(DISTINCT RES.VCOL_SET) * SUM(DISTINCT RES.VREC_SET) END VREC_FILHA,
		Case WHEN SUM(DISTINCT RES.VCOL_SET) * SUM(DISTINCT RES.VREC_SET) = 0 THEN 0 Else (SUM(RES.VCOL_FILHA) / SUM(DISTINCT RES.VCOL_SET) * SUM(DISTINCT RES.VREC_SET)) - SUM(RES.VCOL_FILHA) END PRO_FILHA,
		SUM(DISTINCT Case WHEN RES.VCOL_FILHA = 0 THEN 0 Else RES.VCOL_SET END) VCOL_SET,
		SUM(DISTINCT RES.VREC_SET) VREC_SET,
		SUM(DISTINCT RES.VREC_SET) - SUM(DISTINCT Case WHEN RES.VCOL_FILHA = 0 THEN 0 Else RES.VCOL_SET END) PRO_SET,
		SUM(DISTINCT RES.VREC_TICK) VREC_TICK,
		SUM(RES.KM) KM,
		NVL(AVG(NULLIF(RES.VTABFR,0)),0) VTABFR,
		SUM(RES.VLRFRE) VLRFRE,
		SUM(RES.CREDFR) CREDFR,
		SUM(RES.VLRFRE) + SUM(RES.CREDFR) FRETE,
		SUM(RES.TOTFRE_ZLF) TOTFRE_ZLF,
		Case WHEN SUM(RES.VCOL_FILHA) = 0 THEN 0 Else (SUM(RES.VLRFRE) + SUM(RES.CREDFR)) / SUM(RES.VCOL_FILHA) END CUS_LITRO,
		Case WHEN ZL1.ZL1_CAPACI = 0 THEN 0 
			 WHEN SUM(RES.VCOL_FILHA) = 0 THEN SUM(RES.VREC_TICK) / ZL1.ZL1_CAPACI * 100
		Else 
		(Case WHEN SUM(DISTINCT RES.VCOL_SET) * SUM(DISTINCT RES.VREC_SET) = 0 THEN 0 Else SUM(RES.VCOL_FILHA) / SUM(DISTINCT RES.VCOL_SET) * SUM(DISTINCT RES.VREC_SET) END) /*VREC_FILHA*/
		/ ZL1.ZL1_CAPACI * 100 END TX_OCUP
	FROM (SELECT ZLD.ZLD_FILIAL, ZLD.ZLD_TICKET, ZLD.ZLD_DTCOLE, ZLD.ZLD_VEICUL, ZLD.ZLD_MOTOR, ZLD.ZLD_SETOR, ZLD.ZLD_LINROT,
				ZLD.ZLD_FRETIS, ZLD.ZLD_LJFRET, ZLE.ZLE_COD, ZLE.ZLE_DTINI, ZLE.ZLE_DTFIM, ZLD.ZLD_VFILHA, 
               (SELECT NVL(SUM(ZLF_TOTAL), 0)
                  FROM %Table:ZLF% ZLF, %Table:ZL8% ZL8
                 WHERE ZLF.D_E_L_E_T_ = ' '
                   AND ZL8.D_E_L_E_T_ = ' '
                   AND ZLF.ZLF_FILIAL = ZLD.ZLD_FILIAL
                   AND ZL8.ZL8_FILIAL = ZLF_FILIAL
                   AND ZLF.ZLF_EVENTO = ZL8_COD
                   AND ZLF.ZLF_CODZLE = ZLE.ZLE_COD
                   AND ZLF.ZLF_A2COD = ZLD.ZLD_FRETIS
                   AND ZLF.ZLF_A2LOJA = ZLD.ZLD_LJFRET
                   /*AND ZLF.ZLF_LINROT = ZLD.ZLD_LINROT--Não filtrar linha*/
                   AND ZLF.ZLF_SETOR = ZLD.ZLD_SETOR
                   AND ZLF.ZLF_ENTMIX = 'S'
                   AND ZL8.ZL8_DEBCRE = 'C'
                   AND ZLF_TP_MIX = 'F') TOTFRE_ZLF,
				NVL((SELECT SUM(A.ZLD_QTDBOM)
						FROM (SELECT B.ZLD_TICKET, SUM(B.ZLD_QTDBOM) ZLD_QTDBOM
								FROM %Table:ZLD% B
								WHERE B.D_E_L_E_T_ = ' '
								AND B.ZLD_FILIAL = ZLD.ZLD_FILIAL
								AND B.ZLD_SETOR = ZLD.ZLD_SETOR
                                AND B.ZLD_LINROT = ZLD.ZLD_LINROT
								AND B.ZLD_FRETIS = ZLD.ZLD_FRETIS
								AND B.ZLD_LJFRET = ZLD.ZLD_LJFRET
								AND B.ZLD_TICKET = ZLD.ZLD_TICKET
								AND B.ZLD_VFILHA = ZLD.ZLD_VFILHA
								AND B.ZLD_DTCOLE BETWEEN ZLE.ZLE_DTINI AND ZLE.ZLE_DTFIM
								GROUP BY B.ZLD_TICKET, B.ZLD_QTDBOM) A), 0) VCOL_FILHA,
				NVL((SELECT SUM(A.ZLD_QTDBOM)
						FROM (SELECT B.ZLD_TICKET, SUM(B.ZLD_QTDBOM) ZLD_QTDBOM
								FROM %Table:ZLD% B
								WHERE B.D_E_L_E_T_ = ' '
								AND B.ZLD_FILIAL = ZLD.ZLD_FILIAL
								AND B.ZLD_SETOR = ZLD.ZLD_SETOR
								/*AND B.ZLD_LINROT = ZLD.ZLD_LINROT --Não filtrar linha*/
								AND B.ZLD_FRETIS = ZLD.ZLD_FRETIS
								AND B.ZLD_LJFRET = ZLD.ZLD_LJFRET
								AND B.ZLD_TICKET = ZLD.ZLD_TICKET
								AND B.ZLD_DTCOLE BETWEEN ZLE.ZLE_DTINI AND ZLE.ZLE_DTFIM
								GROUP BY B.ZLD_TICKET, B.ZLD_QTDBOM) A), 0) VCOL_SET,
				NVL((SELECT AVG(A.ZLD_TOTBOM)
						FROM (SELECT B.ZLD_TICKET, B.ZLD_TOTBOM
								FROM %Table:ZLD% B
								WHERE B.D_E_L_E_T_ = ' '
								AND B.ZLD_FILIAL = ZLD.ZLD_FILIAL
								AND B.ZLD_SETOR = ZLD.ZLD_SETOR
								AND B.ZLD_LINROT = ZLD.ZLD_LINROT
								AND B.ZLD_FRETIS = ZLD.ZLD_FRETIS
								AND B.ZLD_LJFRET = ZLD.ZLD_LJFRET
								AND B.ZLD_TICKET = ZLD.ZLD_TICKET
								AND B.ZLD_DTCOLE BETWEEN ZLE.ZLE_DTINI AND ZLE.ZLE_DTFIM
								GROUP BY B.ZLD_TICKET, B.ZLD_TOTBOM) A), 0) VREC_SET,
				NVL((SELECT SUM(A.ZLD_TOTBOM)
						FROM (SELECT B.ZLD_TICKET, B.ZLD_TOTBOM
								FROM %Table:ZLD% B
								WHERE B.D_E_L_E_T_ = ' '
								AND B.ZLD_FILIAL = ZLD.ZLD_FILIAL
								/*AND B.ZLD_SETOR = ZLD.ZLD_SETOR --Não filtrar setor*/
								/*AND B.ZLD_LINROT = ZLD.ZLD_LINROT --Não filtrar linha*/
								AND B.ZLD_FRETIS = ZLD.ZLD_FRETIS
								AND B.ZLD_LJFRET = ZLD.ZLD_LJFRET
								AND B.ZLD_TICKET = ZLD.ZLD_TICKET
								AND B.ZLD_DTCOLE BETWEEN ZLE.ZLE_DTINI AND  ZLE.ZLE_DTFIM
								GROUP BY B.ZLD_TICKET, B.ZLD_TOTBOM) A), 0) VREC_TICK,
				NVL((SELECT SUM(A.ZLD_KM)
						FROM (SELECT B.ZLD_TICKET, B.ZLD_KM
								FROM %Table:ZLD% B
								WHERE B.D_E_L_E_T_ = ' '
								AND B.ZLD_FILIAL = ZLD.ZLD_FILIAL
								AND B.ZLD_SETOR = ZLD.ZLD_SETOR
								AND B.ZLD_LINROT = ZLD.ZLD_LINROT
								AND B.ZLD_FRETIS = ZLD.ZLD_FRETIS
								AND B.ZLD_LJFRET = ZLD.ZLD_LJFRET
								AND B.ZLD_TICKET = ZLD.ZLD_TICKET
								AND B.ZLD_VFILHA = ZLD.ZLD_VFILHA
								AND B.ZLD_DTCOLE BETWEEN ZLE.ZLE_DTINI AND ZLE.ZLE_DTFIM
								GROUP BY B.ZLD_TICKET, B.ZLD_KM) A), 0) KM,
				NVL((SELECT SUM(A.ZLD_VLRFRE)
						FROM (SELECT B.ZLD_TICKET, B.ZLD_VLRFRE
								FROM %Table:ZLD% B
								WHERE B.D_E_L_E_T_ = ' '
								AND B.ZLD_FILIAL = ZLD.ZLD_FILIAL
								AND B.ZLD_SETOR = ZLD.ZLD_SETOR
								AND B.ZLD_LINROT = ZLD.ZLD_LINROT
								AND B.ZLD_FRETIS = ZLD.ZLD_FRETIS
								AND B.ZLD_LJFRET = ZLD.ZLD_LJFRET
								AND B.ZLD_TICKET = ZLD.ZLD_TICKET
								AND B.ZLD_VFILHA = ZLD.ZLD_VFILHA
								AND B.ZLD_DTCOLE BETWEEN ZLE.ZLE_DTINI AND ZLE.ZLE_DTFIM
								GROUP BY B.ZLD_TICKET, B.ZLD_VLRFRE) A), 0) VLRFRE,
				NVL((SELECT SUM(A.ZLD_CREDFR)
						FROM (SELECT B.ZLD_TICKET, B.ZLD_CREDFR
								FROM %Table:ZLD% B
								WHERE B.D_E_L_E_T_ = ' '
								AND B.ZLD_FILIAL = ZLD.ZLD_FILIAL
								AND B.ZLD_SETOR = ZLD.ZLD_SETOR
								AND B.ZLD_LINROT = ZLD.ZLD_LINROT
								AND B.ZLD_FRETIS = ZLD.ZLD_FRETIS
								AND B.ZLD_LJFRET = ZLD.ZLD_LJFRET
								AND B.ZLD_TICKET = ZLD.ZLD_TICKET
								AND B.ZLD_VFILHA = ZLD.ZLD_VFILHA
								AND B.ZLD_DTCOLE BETWEEN ZLE.ZLE_DTINI AND ZLE.ZLE_DTFIM
								GROUP BY B.ZLD_TICKET, B.ZLD_CREDFR) A), 0) CREDFR,
				NVL((SELECT AVG(A.ZLD_VTABFR)
						FROM (SELECT B.ZLD_TICKET, B.ZLD_VTABFR
								FROM %Table:ZLD% B
								WHERE B.D_E_L_E_T_ = ' '
								AND B.ZLD_FILIAL = ZLD.ZLD_FILIAL
								AND B.ZLD_SETOR = ZLD.ZLD_SETOR
								AND B.ZLD_LINROT = ZLD.ZLD_LINROT
								AND B.ZLD_FRETIS = ZLD.ZLD_FRETIS
								AND B.ZLD_LJFRET = ZLD.ZLD_LJFRET
								AND B.ZLD_TICKET = ZLD.ZLD_TICKET
								AND B.ZLD_VFILHA = ZLD.ZLD_VFILHA
								AND B.ZLD_DTCOLE BETWEEN ZLE.ZLE_DTINI AND ZLE.ZLE_DTFIM
								GROUP BY B.ZLD_TICKET, B.ZLD_VTABFR) A), 0) VTABFR
			FROM %Table:ZLD% ZLD, %Table:ZLE% ZLE
			WHERE ZLD.D_E_L_E_T_ = ' '
			AND ZLE.D_E_L_E_T_ = ' '
			%exp:_cFiltro%
			AND ZLD.ZLD_FRETIS BETWEEN %exp:MV_PAR04% AND %exp:MV_PAR05%
			AND ZLD.ZLD_LJFRET BETWEEN %exp:MV_PAR06% AND %exp:MV_PAR07%
			AND ZLE.ZLE_COD = %exp:MV_PAR02%
			AND ZLD.ZLD_DTCOLE BETWEEN ZLE.ZLE_DTINI AND ZLE.ZLE_DTFIM
			GROUP BY ZLD.ZLD_FILIAL, ZLD.ZLD_TICKET, ZLD.ZLD_DTCOLE, ZLD.ZLD_VEICUL, ZLD.ZLD_MOTOR, ZLD.ZLD_SETOR, ZLD.ZLD_LINROT,
					ZLD.ZLD_FRETIS, ZLD.ZLD_LJFRET, ZLE.ZLE_COD, ZLE.ZLE_DTINI, ZLE.ZLE_DTFIM, ZLD.ZLD_VFILHA) RES,
		%Table:ZL3% ZL3, %Table:SA2% SA2, %Table:ZL2% ZL2, %Table:ZL1% ZL1, %Table:ZL0% ZL0, %Table:ZFF% ZFF
	WHERE ZL3.D_E_L_E_T_ = ' '
	AND SA2.D_E_L_E_T_ = ' '
	AND ZL2.D_E_L_E_T_ = ' '
	AND ZL1.D_E_L_E_T_ = ' '
	AND ZL0.D_E_L_E_T_ = ' '
	AND ZFF.D_E_L_E_T_ (+) = ' '
	AND RES.ZLD_FILIAL = ZL2.ZL2_FILIAL
	AND RES.ZLD_FILIAL = ZL3.ZL3_FILIAL
	AND RES.ZLD_LINROT = ZL3.ZL3_COD
	AND RES.ZLD_SETOR = ZL2.ZL2_COD
	AND SA2.A2_COD = RES.ZLD_FRETIS
	AND SA2.A2_LOJA = RES.ZLD_LJFRET
	AND RES.ZLD_FILIAL = ZL1.ZL1_FILIAL
	AND RES.ZLD_VEICUL = ZL1.ZL1_COD
	AND RES.ZLD_FILIAL = ZL0.ZL0_FILIAL
	AND RES.ZLD_MOTOR = ZL0.ZL0_COD
	AND ZFF.ZFF_FILIAL (+) = ZL1.ZL1_FILIAL
	AND ZFF.ZFF_CODIGO (+) = ZL1.ZL1_TABFRE
	%exp:_cFiltro2%
	GROUP BY RES.ZLD_FILIAL, ZL2.ZL2_COD, ZL2.ZL2_DESCRI, %exp:_cCampos% SA2.A2_COD, SA2.A2_LOJA, SA2.A2_NOME, ZL1.ZL1_CAPACI
	ORDER BY RES.ZLD_FILIAL, %exp:_cOrder%
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
	_cFilial := (_cAlias)->ZLD_FILIAL
	_cSetor	:= (_cAlias)->ZL2_COD
	_cTransp := (_cAlias)->A2_NOME
	If _nOrdem == 4
		_cPlaca	:= (_cAlias)->ZL1_PLACA
	EndIf
	(_cAlias)->(DBSkip())
EndDo

oReport:Section(1):Finish()
(_cAlias)->(DBCloseArea())

Return
