/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |17/12/2021| Chamado 38660. Corrigido o pergunte informado no relatório.
Lucas Borges  |06/01/2022| Chamado 38846. Criada mais duas ordens no relatório.
Lucas Borges  |08/08/2022| Chamado 40951. Corrigido Filtro de Município.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RGLT031
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 03/11/2021
Descrição---------: Relação de Produtor por Classificação de Tanque
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RGLT031

Local oReport
Pergunte("RGLT031",.F.)
//Inferface de Impressão
oReport := ReportDef()
oReport:PrintDialog()

Return

/*
===============================================================================================================================
Programa----------: ReportDef
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 03/11/2021
Descrição---------: Definição do Componente
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ReportDef()

Local oReport
Local oSection
Local _aOrdem   := {"Por Filial + Município + Nome Produtor","Por Filial + Nome Produtor","Por Filial + Município + Cod Produtor","Por Filial + Cod Produtor"}

//Criacao do componente de impressao
//TReport():New
//ExpC1 : Nome do relatorio
//ExpC2 : Titulo
//ExpC3 : Pergunte
//ExpB4 : Bloco de codigo que sera executado na confirmacao da impressao
//ExpC5 : Descricao

oReport := TReport():New("RGLT031","Relação de Produtor por Classificação de Tanque","RGLT031",;
{|oReport| ReportPrint(oReport,_aOrdem)},"Relatório Produtor por Classificação de Tanque")
oSection := TRSection():New(oReport,"Custo Frete"	,/*uTable {}*/, _aOrdem/*aOrder*/, .F./*lLoadCells*/, .T./*lLoadOrder*/,"Total das Filiais: "/*uTotalText*/,.T./*lTotalInLine*/)
oReport:SetLandscape()//Paisagem
oSection:SetTotalInLine(.F.)

//TRCell():New(oParent,cName,cAlias,cTitle,cPicture,nSize,lPixel,bBlock,cAlign,lLineBreak,cHeaderAlign,lCellBreak,nColSpace,lAutoSize,nClrBack,nClrFore,lBold)
TRCell():New(oSection,"ZL2_FILIAL","ZL2","Fil"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_COD","SA2",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_LOJA","SA2",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,0/*nColSpace*/,.F./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_NOME","SA2","Fretista"/*cTitle*/,/*Picture*/,35/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_END","SA2",/*cTitle*/,/*Picture*/,40/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_EST","SA2",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_COD_MUN","SA2",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"CC2_MUN","CC2",/*cTitle*/,/*Picture*/,32/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_CGC","SA2",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_INSCR","SA2",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_L_SIGSI","SA2",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"VOLUME",/*cAlias*/,"Vol.Mensal"/*cTitle*/,"@E 9,999,999,999"/*Picture*/,14/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"MEDIA",/*cAlias*/,"Med.Dia"/*cTitle*/,"@E 999,999"/*Picture*/,7/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_L_MARTQ","SA2",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_L_CAPTQ","SA2","Tanque"/*cTitle*/,"@E 99,999"/*Picture*/,6/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_L_FREQU","SA2","Freq."/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_L_CLASS","SA2",/*cTitle*/,/*Picture*/,10/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_L_TXRES","SA2","Tx.Resf."/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_L_TANQ","SA2",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_L_TANLJ","SA2",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZL2_COD","ZL2","Setor"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZL2_DESCRI","ZL2",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZL3_COD","ZL3","Linha"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZL3_DESCRI","ZL3",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)

Return oReport

/*
===============================================================================================================================
Programa----------: ReportPrint
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 03/11/2021
Descrição---------: Processa impressão do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ReportPrint(oReport,_aOrdem)

Local _cFiltro		:= "%"
Local _cOrder		:= "%"
Local _cAlias		:= ""
Local _cDias		:="% " + cValToChar(DateDiffDay(MV_PAR04,MV_PAR05)+1) + "%"
Local _aSelFil		:= {}
Local _nOrdem		:= oReport:Section(1):GetOrder() //1-"Por Filial + Município",2-"Por Filial + Produtor"
Local _cFilial		:= ""
Local _lPlanilha 	:= oReport:nDevice == 4
Local _nCountRec	:= 0
Local _cMunic		:= ""
Local _cNomFor		:= ""
Local _cAux			:= ""
//Chama função que permitirá a seleção das filiais
If MV_PAR01 == 1
	If Empty(_aSelFil)
		_aSelFil := AdmGetFil(.F.,.F.,"ZL2")
	EndIf
Else
	aAdd(_aSelFil,cFilAnt)
EndIf

//=====================================================
//Adiciona a ordem escolhida ao titulo do relatorio
//=====================================================
oReport:SetTitle(oReport:Title() + " ("+AllTrim(_aOrdem[_nOrdem])+") ")

//==========================================================================
//Transforma parametros Range em expressao SQL                             	
//==========================================================================
MakeSqlExpr(oReport:uParam)

//================================================================================
//Configuração das quebras do relatório
//================================================================================
If _nOrdem == 1 .Or. _nOrdem == 3
	oQbrMun	:= TRBreak():New( oReport:Section(1)/*oParent*/, oReport:Section(1):Cell("A2_COD_MUN") /*uBreak*/, {||"Município: " + _cMunic}/*uTitle*/, .F. /*lTotalInLine*/,/*cName*/,.T./*lPageBreak*/)
	TRFunction():New(oReport:Section(1):Cell("A2_COD")/*oCell*/,/*cName*/,"COUNT"/*cFunction*/,oQbrMun/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
	TRFunction():New(oReport:Section(1):Cell("VOLUME")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrMun/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
	TRFunction():New(oReport:Section(1):Cell("MEDIA")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrMun/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
ElseIf _nOrdem == 2 .Or. _nOrdem == 4
	oQbrMun	:= TRBreak():New( oReport:Section(1)/*oParent*/, oReport:Section(1):Cell("A2_L_TANQ") /*uBreak*/, {||"Resposnsável: " + _cNomFor}/*uTitle*/, .F. /*lTotalInLine*/,/*cName*/,.T./*lPageBreak*/)
	//oQbrMun	:= TRBreak():New( oReport:Section(1)/*oParent*/, oReport:Section(1):Cell("A2_L_TANQ") /*uBreak*/, {||"Produtores: " + _cNomFor}/*uTitle*/, .F. /*lTotalInLine*/,/*cName*/,.T./*lPageBreak*/)
	TRFunction():New(oReport:Section(1):Cell("A2_COD")/*oCell*/,/*cName*/,"COUNT"/*cFunction*/,oQbrMun/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
	TRFunction():New(oReport:Section(1):Cell("VOLUME")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrMun/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
	TRFunction():New(oReport:Section(1):Cell("MEDIA")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrMun/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
EndIf


oQbrFil		:= TRBreak():New( oReport:Section(1)/*oParent*/, oReport:Section(1):Cell("ZL2_FILIAL") /*uBreak*/, {||"Total da Filial: " + _cFilial + ' - '+ FWFilialName(cEmpAnt,_cFilial,1 )}/*uTitle*/, .T. /*lTotalInLine*/,/*cName*/,.T./*lPageBreak*/)
TRFunction():New(oReport:Section(1):Cell("A2_COD")/*oCell*/,/*cName*/,"COUNT"/*cFunction*/,oQbrFil/*oBreak*/,"Total de Produtores"/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.T./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("VOLUME")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFil/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.T./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("MEDIA")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrFil/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.T./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)

//==========================================================================
// Trata as células a serem exibidas de acordo com sessão e parâmetros
//==========================================================================
If !_lPlanilha
	oReport:Section(1):Cell("A2_EST"):Disable()
	oReport:Section(1):Cell("A2_COD_MUN"):Disable()
	oReport:Section(1):Cell("A2_L_TANQ"):Disable()
	oReport:Section(1):Cell("A2_L_TANLJ"):Disable()
	oReport:Section(1):Cell("ZL2_COD"):Disable()
	oReport:Section(1):Cell("ZL2_DESCRI"):Disable()
	oReport:Section(1):Cell("ZL3_COD"):Disable()
	oReport:Section(1):Cell("ZL3_DESCRI"):Disable()
EndIf

//====================================================================================================
// Monta filtro de acordo com a tabela de origem
//====================================================================================================
_cFiltro += " AND ZL2.ZL2_FILIAL "+ GetRngFil( _aSelFil, "ZL2", .T.,)

//Se preencheu os setores, já fiz a validação de acesso no SX1
//Se não preencheu e não tem acesso a todos, filtra de forma que não retorme registros
If !Empty(MV_PAR02) .Or. Empty(MV_PAR02) .And. Posicione("ZLU",1,xFilial("ZLU")+RetCodUsr(),"ZLU_SETALL") <> 'S'
	_cFiltro += " AND ZL2_COD IN "+ FormatIn( AllTrim(MV_PAR02) , ';' )
EndIf

//Verifica se foi fornecido o filtro de linha
If !Empty(MV_PAR03)
	_cFiltro += " AND ZL3_COD IN " + FormatIn(MV_PAR03,";")
EndIf
//Verifica se foi fornecido o filtro de município
If !Empty(MV_PAR10)
	_cFiltro += " AND A2_COD_MUN = '"+MV_PAR10+"' "
EndIf
//Verifica se foi fornecido o filtro de Classifiação de taque
If !Empty(MV_PAR11)
	_cFiltro += " AND A2_L_CLASS IN " + FormatIn(MV_PAR11,";")
EndIf

If _nOrdem == 1
	_cOrder += " A2_EST,A2_COD_MUN, A2_L_TANQ, A2_L_TANLJ, A2_L_CLASS, A2_NOME"
ElseIf _nOrdem == 2
	_cOrder += " A2_L_TANQ, A2_L_TANLJ, A2_L_CLASS, A2_NOME"
ElseIf _nOrdem == 3
	_cOrder += " A2_EST,A2_COD_MUN, A2_L_TANQ, A2_L_TANLJ, A2_L_CLASS, A2_COD, A2_LOJA"
ElseIf _nOrdem == 4
	_cOrder += " A2_L_TANQ, A2_L_TANLJ, A2_L_CLASS, A2_COD, A2_LOJA"
EndIf

_cFiltro += "%"
_cOrder += "%"

//==========================================================================
// Query do relatório da secao 1                                            
//==========================================================================
oReport:Section(1):BeginQuery()	
_cAlias := GetNextAlias()

oReport:SetMsgPrint("Consultando registros no Banco de Dados")
oReport:SetMeter(0)

BeginSql alias _cAlias
	SELECT ZL2_FILIAL, A2_COD, A2_LOJA, A2_NOME, A2_END, A2_EST, A2_COD_MUN, CC2_MUN, A2_CGC, A2_INSCR, A2_L_SIGSI, A2_L_MARTQ, A2_L_CAPTQ, A2_L_FREQU, ZL2_COD, ZL2_DESCRI, ZL3_COD, ZL3_DESCRI,
		A2_L_TXRES, A2_L_CLASS,	A2_L_TANQ, A2_L_TANLJ, NVL(SUM(ZLD.ZLD_QTDBOM),0) VOLUME, Round(NVL(SUM(ZLD.ZLD_QTDBOM),0)/%exp:_cDias%,2) MEDIA
		FROM %Table:SA2% SA2, %Table:ZL3% ZL3, %Table:ZL2% ZL2, %Table:ZLD% ZLD, %Table:CC2% CC2
		WHERE SA2.D_E_L_E_T_ = ' '
		AND ZL3.D_E_L_E_T_ = ' '
		AND ZL2.D_E_L_E_T_ = ' '
		AND ZLD.D_E_L_E_T_ = ' '
		AND CC2.D_E_L_E_T_ = ' '
		AND ZLD.ZLD_SETOR = ZL2.ZL2_COD
		AND ZLD.ZLD_LINROT = ZL3.ZL3_COD
		AND ZL3.ZL3_FILIAL = ZL2.ZL2_FILIAL
		AND ZLD.ZLD_FILIAL = ZL2.ZL2_FILIAL
		AND ZLD.ZLD_RETIRO = SA2.A2_COD
		AND ZLD.ZLD_RETILJ = SA2.A2_LOJA
		AND CC2_EST = A2_EST
		AND CC2_CODMUN = A2_COD_MUN 
	    %exp:_cFiltro%
		AND ZLD.ZLD_DTCOLE BETWEEN %exp:MV_PAR04% AND %exp:MV_PAR05%
		AND A2_L_TANQ BETWEEN %exp:MV_PAR06% AND %exp:MV_PAR07%
		AND A2_L_TANLJ BETWEEN %exp:MV_PAR08% AND %exp:MV_PAR09%
	GROUP BY ZL2_FILIAL, A2_COD, A2_LOJA, A2_NOME, A2_END, A2_EST, A2_COD_MUN, CC2_MUN, A2_CGC, A2_INSCR, A2_L_SIGSI, A2_L_MARTQ, 
			A2_L_CAPTQ, A2_L_FREQU, ZL2_COD, ZL2_DESCRI, ZL3_COD, ZL3_DESCRI, A2_L_TXRES, A2_L_CLASS, A2_L_TANQ, A2_L_TANLJ
	ORDER BY ZL2_FILIAL, %exp:_cOrder%
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
	_cFilial := (_cAlias)->ZL2_FILIAL
	If _nOrdem == 1 .Or. _nOrdem == 3
		_cMunic	:= (_cAlias)->CC2_MUN
	ElseIf _nOrdem == 2 .Or. _nOrdem == 4
		If _cAux <> (_cAlias)->(A2_L_TANQ+A2_L_TANLJ)
			_cNomFor := (_cAlias)->A2_NOME
			_cAux := (_cAlias)->(A2_L_TANQ+A2_L_TANLJ)
		EndIf
	EndIf
	(_cAlias)->(DBSkip())
EndDo

oReport:Section(1):Finish()
(_cAlias)->(DBCloseArea())

Return
