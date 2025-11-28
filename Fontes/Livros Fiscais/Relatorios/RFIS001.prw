/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  | 16/08/2022 | Chamado 41037. Corrigida query para não considerar pre-notas
Lucas Borges  | 09/07/2024 | Chamado 47804. Modificado mecanismo de busca do volume
Lucas Borges  | 22/04/2025 | Chamado 50505. Alterada a picture do CNPJ para contemplar campo alfanumérico
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RFIS001
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 29/01/2019
Descrição---------: Relatório de Contribuição Seguridade Social Lenha/Leite
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RFIS001()

Local oReport
Pergunte("RFIS001",.F.)
//Inferface de Impressão
oReport := ReportDef()
oReport:PrintDialog()

Return

/*
===============================================================================================================================
Programa----------: ReportDef
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 29/01/2019
Descrição---------: Definição do Componente
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ReportDef()

Local oReport
Local oSection
Local _aOrdem   := {"Documento e Serie","Por Município","Por Produtor"}

//Criacao do componente de impressao
//TReport():New
//ExpC1 : Nome do relatorio
//ExpC2 : Titulo
//ExpC3 : Pergunte
//ExpB4 : Bloco de codigo que sera executado na confirmacao da impressao
//ExpC5 : Descricao

oReport := TReport():New("RFIS001","Contribuição Seguridade Social Lenha/Leite","RFIS001",;
{|oReport| ReportPrint(oReport,_aOrdem)},"Imprime todos os documentos que tiveram INSS, Senar e/ou Gilrat")
oSection := TRSection():New(oReport,"Documentos",/*uTable {}*/, _aOrdem/*aOrder*/, .F./*lLoadCells*/, .T./*lLoadOrder*/,"Total das Filiais: "/*uTotalText*/)
oReport:SetLandscape()//Paisagem
oSection:SetTotalInLine(.F.)

//TRCell():New(oParent,cName,cAlias,cTitle,cPicture,nSize,lPixel,bBlock,cAlign,lLineBreak,cHeaderAlign,lCellBreak,nColSpace,lAutoSize,nClrBack,nClrFore,lBold)
TRCell():New(oSection,"F1_FILIAL","SF1",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"F1_EMISSAO","SF1",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"F1_DTDIGIT","SF1",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"F1_DOC","SF1",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"F1_SERIE","SF1",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_COD","SF1",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_LOJA","SF1",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_NOME","SF1",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_CGC","SF1"/*Tabela*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_TIPO","SF1"/*Tabela*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"F1_L_MIX","SF1",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"MES_ANO",/*cTable*/,"Período"/*cTitle*/,/*Picture*/,7/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"F1_L_SETOR","SF1",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"F1_L_LINHA","SF1",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"F1_VALBRUT","SF1",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"F1_BASEFUN","SF1",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"F1_CONTSOC","SF1",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"F1_INSS","SF1",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"F1_VLSENAR","SF1",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"VOLUME",/*cTable*/,"Volume", "@E 9,999,999,999" ,12,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"CC2_EST","CC2","Est"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"CC2_CODMUN","CC2",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"CC2_MUN","CC2",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)


Return oReport

/*
===============================================================================================================================
Programa----------: ReportPrint
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 29/01/2019
Descrição---------: Processa dados do relatório
Parametros--------: oReport, _aOrdem
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ReportPrint(oReport,_aOrdem)

Local _cFiltro		:= "%"
Local _cOrder		:= "%"
Local _cAlias		:= ""
Local _aSelFil		:= {}
Local _nOrdem		:= oReport:Section(1):GetOrder() //1-Agrupa por filial 2-Agrupa também por Setor
Local _cFilial		:= ""
Local _cMun			:= ""
Local _lPlanilha 	:= oReport:nDevice == 4

//Chama função que permitirá a seleção das filiais
If MV_PAR09 == 1
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
If _nOrdem == 2 .Or. _nOrdem == 3 //2-Por Município 3-Por Pordutor
	If _nOrdem == 2
		oQbrMun	:= TRBreak():New( oReport:Section(1)/*oParent*/, oReport:Section(1):Cell("CC2_CODMUN")/*uBreak*/, {||"Total do Município: " + _cMun}/*uTitle*/, .F. /*lTotalInLine*/,/*cName*/,.T./*lPageBreak*/)
	Else
		oQbrMun	:= TRBreak():New( oReport:Section(1)/*oParent*/, {||oReport:Section(1):Cell("A2_COD"):uPrint+oReport:Section(1):Cell("A2_LOJA"):uPrint}/*uBreak*/, {||"Total do Produtor: "}/*uTitle*/, .F. /*lTotalInLine*/,/*cName*/,.T./*lPageBreak*/)
	EndIf
	TRFunction():New(oReport:Section(1):Cell("F1_VALBRUT")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrMun/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
	TRFunction():New(oReport:Section(1):Cell("F1_BASEFUN")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrMun/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
	TRFunction():New(oReport:Section(1):Cell("F1_CONTSOC")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrMun/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
	TRFunction():New(oReport:Section(1):Cell("F1_INSS")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrMun/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
	TRFunction():New(oReport:Section(1):Cell("F1_VLSENAR")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrMun/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
	TRFunction():New(oReport:Section(1):Cell("VOLUME")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrMun/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
EndIf
oQbrFilial	:= TRBreak():New( oReport:Section(1)/*oParent*/, oReport:Section(1):Cell("F1_FILIAL")/*uBreak*/, {||"Total da Filial: " + _cFilial + ' - '+ FWFilialName(cEmpAnt,_cFilial,1 )}/*uTitle*/, .F. /*lTotalInLine*/,/*cName*/,.T./*lPageBreak*/)
TRFunction():New(oReport:Section(1):Cell("F1_VALBRUT")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("F1_BASEFUN")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("F1_CONTSOC")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("F1_INSS")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("F1_VLSENAR")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("VOLUME")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)

//==========================================================================
// Trata as células a serem exibidas de acordo com sessão e parâmetros
//==========================================================================
If !_lPlanilha
	oReport:Section(1):Cell("CC2_EST"):Disable()
	oReport:Section(1):Cell("CC2_CODMUN"):Disable()
	oReport:Section(1):Cell("CC2_MUN"):Disable()
	oReport:Section(1):Cell("A2_TIPO"):Disable()
EndIf

//====================================================================================================
// Monta filtro de acordo com a tabela de origem
//====================================================================================================
_cFiltro += " AND F1_FILIAL "+ GetRngFil( _aSelFil, "SF1", .T.,)
//Verifica se foi fornecido o Estado
If !Empty(MV_PAR10)
	_cFiltro += " AND CC2_EST = '" + MV_PAR10 + "'
EndIf

//Verifica se foi fornecido o Município
If !Empty(MV_PAR11)
	_cFiltro += " AND CC2_CODMUN = '" + MV_PAR11 + "'
EndIf
_cFiltro += " %"

If _nOrdem == 2
	_cOrder += " CC2_EST, CC2_CODMUN, "
ElseIf _nOrdem == 3
	_cOrder += " A2_COD, A2_LOJA, "
EndIf

_cOrder += " %"
//==========================================================================
// Query do relatório da secao 1                                            
//==========================================================================
oReport:Section(1):BeginQuery()	

_cAlias := GetNextAlias()

BeginSql alias _cAlias
	SELECT F1_FILIAL, F1_EMISSAO, F1_DTDIGIT, F1_DOC, F1_SERIE, A2_COD, A2_LOJA,A2_NOME, A2_CGC, A2_TIPO, F1_VALBRUT,
		   SUM(Case WHEN F1_BASEFUN = 0 THEN D1_BSSENAR Else D1_BASEFUN END) F1_BASEFUN, F1_CONTSOC, F1_INSS, F1_VLSENAR,
		   F1_L_MIX, SubStr(ZLE_DTINI,5,2)||'/'||SubStr(ZLE_DTINI,1,4) MES_ANO,F1_L_SETOR, F1_L_LINHA, 
		   NVL((SELECT SUM(ZLD_QTDBOM) FROM %Table:ZLD%
			WHERE D_E_L_E_T_ = ' '
			AND ZLD_DTCOLE BETWEEN ZLE_DTINI AND ZLE_DTFIM
			AND ZLD_FILIAL = F1_FILIAL
			AND ZLD_RETIRO = A2_COD
			AND ZLD_RETILJ = A2_LOJA
			AND ZLD_SETOR = F1_L_SETOR
			AND ZLD_LINROT = F1_L_LINHA),0) VOLUME, CC2_EST, CC2_CODMUN, CC2_MUN
	  FROM %Table:SA2% SA2, %Table:SF1% SF1, %Table:SD1% SD1, %Table:CC2% CC2, %Table:ZLE% ZLE
	 WHERE SA2.D_E_L_E_T_ = ' '
	   AND SF1.D_E_L_E_T_ = ' '
	   AND SD1.D_E_L_E_T_ = ' '
	   AND CC2.D_E_L_E_T_ = ' '
	   AND ZLE.D_E_L_E_T_ (+) = ' '
	   AND F1_FILIAL = D1_FILIAL 
	   AND CC2_EST = A2_EST
	   AND CC2_CODMUN = A2_COD_MUN
	   AND F1_FORNECE = A2_COD
	   AND F1_LOJA = A2_LOJA
	   AND F1_DOC = D1_DOC
	   AND F1_SERIE = D1_SERIE
	   AND F1_FORNECE = D1_FORNECE
	   AND F1_STATUS = 'A'
	   AND ZLE_COD (+) = F1_L_MIX
	   %Exp:_cFiltro%
	   AND F1_EMISSAO BETWEEN %exp:MV_PAR01% AND %exp:MV_PAR02%
	   AND F1_DTDIGIT BETWEEN %exp:MV_PAR03% AND %exp:MV_PAR04%
	   AND A2_COD BETWEEN %exp:MV_PAR05% AND %exp:MV_PAR06%
	   AND A2_LOJA BETWEEN %exp:MV_PAR07% AND %exp:MV_PAR08%
	   AND (F1_BASEFUN > 0 OR F1_VLSENAR > 0)
	 GROUP BY F1_FILIAL, F1_EMISSAO, F1_DTDIGIT, F1_DOC, F1_SERIE, A2_COD,A2_LOJA, A2_NOME, A2_CGC, 
	   A2_TIPO, F1_VALBRUT, F1_CONTSOC, F1_INSS, F1_VLSENAR, F1_L_MIX, ZLE_DTINI, ZLE_DTFIM, F1_L_SETOR, F1_L_LINHA, CC2_EST, CC2_CODMUN, CC2_MUN
	  ORDER BY F1_FILIAL, %exp:_cOrder% F1_DOC, F1_SERIE
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
nInc	:= RecCount()
oReport:SetMeter(nInc)

While !oReport:Cancel() .And. (_cAlias)->(!Eof())

	//Mascara para impressao - CNPJ/CPF
	If RetPessoa((_cAlias)->A2_CGC) == "J"
		oReport:Section(1):Cell("A2_CGC"):SetPicture("@R! NN.NNN.NNN/NNNN-99")
	Else
		oReport:Section(1):Cell("A2_CGC"):SetPicture("@R 999.999.999-99")
	EndIf
	
	oReport:Section(1):PrintLine()
	//Alimentar essas variáveis depois da impressão da linha
	//para carregar o valor correto.
	_cFilial:= (_cAlias)->F1_FILIAL
	_cMun	:= (_cAlias)->CC2_CODMUN + ' - ' + (_cAlias)->CC2_MUN
	(_cAlias)->(DBSkip())
EndDo

oReport:Section(1):Finish()
(_cAlias)->(DBCloseArea())

Return
