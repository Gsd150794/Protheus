/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |24/01/2023| Chamado 42685. Retirada referencia à SX5.
Lucas Borges  |22/01/2025| Chamado 49641. Implementada faixa de início e fim para pagamento do excedente de matéria gorda
Lucas Borges  |01/10/2025| Chamado 52143. Incluido filtro para fornecedore Centro Leite
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RGLT017
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 28/07/2022
Descrição---------: Diferença de programação - Leite de Terceiros
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RGLT017

Local oReport := Nil As Object

Pergunte("RGLT017",.F.)
//Inferface de Impressão
oReport := ReportDef()
oReport:PrintDialog()

Return

/*
===============================================================================================================================
Programa----------: ReportDef
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 28/07/2022
Descrição---------: Definição do Componente
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ReportDef() As Object

Local oReport 	:= Nil As Object
Local oSection	:= Nil As Object
Local _aOrdem	:= {"Filial+Produto"} As Array

//Criacao do componente de impressao
//TReport():New
//ExpC1 : Nome do relatorio
//ExpC2 : Titulo
//ExpC3 : Pergunte
//ExpB4 : Bloco de codigo que sera executado na confirmacao da impressao
//ExpC5 : Descricao

oReport := TReport():New("RGLT017","Diferença de Programação","RGLT017",;
{|oReport| ReportPrint(oReport,_aOrdem)},"Apresenta informações referente à diferença entre o programado e realizado para Matéria Gorda e Extrato Seco Total.")
oSection := TRSection():New(oReport,"Movimentos"	,/*uTable {}*/, _aOrdem/*aOrder*/, .F./*lLoadCells*/, .T./*lLoadOrder*/,"Total das Filiais: "/*uTotalText*/)
oReport:SetLandscape()//Paisagem
oSection:SetTotalInLine(.F.)

//TRCell():New(oParent,cName,cAlias,cTitle,cPicture,nSize,lPixel,bBlock,cAlign,lLineBreak,cHeaderAlign,lCellBreak,nColSpace,lAutoSize,nClrBack,nClrFore,lBold)
TRCell():New(oSection,"ZZX_FILIAL","ZZX","Fil"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZZX_CODPRD","ZZX",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"PRODUTO",/*Table*/,"Produto"/*cTitle*/,/*Picture*/,20/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLX_TIPOLT",/*Table*/,"Procedência"/*cTitle*/,/*Picture*/,15/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_COD","SA2",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_LOJA","SA2",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_NREDUZ",/*Table*/,"Fornecedor"/*cTitle*/,/*Picture*/,35/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLX_NRONF","ZLX"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"C7_NUM","SC7"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"C7_EMISSAO","SC7"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"C7_L_EXEMG","SC7"/*Table*/,"Pg. Exc."+CRLF+" MG"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZAP_GORD","ZAP"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"C7_L_PMEST","SC7"/*Table*/,"% Mín."+CRLF+"EST"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"C7_L_EXEST","SC7"/*Table*/,"Pg. Exc."+CRLF+"EST"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"C7_QUANT","SC7"/*Table*/,"Volume"+CRLF+"Programado"/*cTitle*/,'@E 999,999,999'/*Picture*/,11/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,"RIGHT"/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLX_VOLREC",/*Tabela*/,"Volume "+CRLF+"Recebido"/*cTitle*/,'@E 999,999,999'/*Picture*/,11/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"VOL_DIF",/*Tabela*/,"Diferença"+CRLF+"Volume"/*cTitle*/,'@E 999,999,999'/*Picture*/,11/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"C7_PRECO",/*Tabela*/,"Preço"+CRLF+"Programado"/*cTitle*/,'@E 999,999.9999'/*Picture*/,12/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLX_PRCNF",/*Tabela*/,"Preço"+CRLF+"Faturado"/*cTitle*/,'@E 999,999.9999'/*Picture*/,12/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"PRC_DIF",/*Tabela*/,"Dif. de"+CRLF+"Preço"/*cTitle*/,'@E 999,999.9999'/*Picture*/,12/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"QUANT",/*Table*/,/*cTitle*/,'@E 999,999,999'/*Picture*/,11/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,"RIGHT"/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"DIF",/*Tabela*/,/*cTitle*/,'@E 999,999,999'/*Picture*/,11/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)

Return oReport

/*
===============================================================================================================================
Programa----------: ReportPrint
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 28/07/2022
Descrição---------: Processa impressão do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ReportPrint(oReport As Object,_aOrdem As Array)

Local _cFiltro	:= "%" As Character
Local _cAlias	:= "" As Character
Local _aSelFil	:= {} As Array
Local _nOrdem	:= oReport:Section(1):GetOrder()  As Numeric
Local _lPlanilha:= oReport:nDevice == 4 As Logical
Local _cFilial	:= "" As Character
Local _cProduto := "" As Character
Local _cPedido	:= "" As Character
Local _cBreak01	:= "" As Character

//Chama função que permitirá a seleção das filiais
If MV_PAR09 == 1
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

oQbrPed:= TRBreak():New( oReport:Section(1)/*oParent*/, {||oReport:Section(1):Cell("ZZX_FILIAL"):uPrint+oReport:Section(1):Cell("ZZX_CODPRD"):uPrint+oReport:Section(1):Cell("C7_NUM"):uPrint} /*uBreak*/, {||"Produto: "+ _cProduto + " Total Pedido: " + _cPedido } /*uTitle*/, .F. /*lTotalInLine*/,/*cName*/,.F./*lPageBreak*/)
oTotQtd 	:= TRFunction():New(oReport:Section(1):Cell("C7_QUANT")/*oCell*/,"TESTE"/*cName*/,"AVERAGE"/*cFunction*/,oQbrPed/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
oTotRec 	:= TRFunction():New(oReport:Section(1):Cell("ZLX_VOLREC")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrPed/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("VOL_DIF")/*oCell*/,/*cName*/,"ONPRINT"/*cFunction*/,oQbrPed/*oBreak*/,/*cTitle*/,/*cPicture*/,{||oTotQtd:GetValue()-oTotRec:GetValue()}/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)

oQbrProd:= TRBreak():New( oReport:Section(1)/*oParent*/, {||oReport:Section(1):Cell("ZZX_FILIAL"):uPrint+oReport:Section(1):Cell("ZZX_CODPRD"):uPrint} /*uBreak*/, {||"Total Produto: " + _cProduto } /*uTitle*/, .F. /*lTotalInLine*/,/*cName*/,.F./*lPageBreak*/)
oTotPQtd := TRFunction():New(oReport:Section(1):Cell("QUANT")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrProd/*oBreak*/,/*cTitle*/,/*cPicture*/,{||oReport:Section(1):Cell("QUANT"):uPrint}/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
oTotPDif := TRFunction():New(oReport:Section(1):Cell("DIF")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrProd/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("C7_QUANT")/*oCell*/,/*cName*/,"ONPRINT"/*cFunction*/,oQbrProd/*oBreak*/,/*cTitle*/,/*cPicture*/,{||oTotPQtd:GetValue()}/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("ZLX_VOLREC")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrProd/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("VOL_DIF")/*oCell*/,/*cName*/,"ONPRINT"/*cFunction*/,oQbrProd/*oBreak*/,/*cTitle*/,/*cPicture*/,{||oTotPDif:GetValue()}/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)

oQbrFilial	:= TRBreak():New( oReport:Section(1)/*oParent*/, oReport:Section(1):Cell("ZZX_FILIAL")/*uBreak*/, {||"Total da Filial: " + _cFilial + ' - '+ FWFilialName(cEmpAnt,_cFilial,1 )}/*uTitle*/, .F. /*lTotalInLine*/,/*cName*/,.T./*lPageBreak*/)
oTotFQtd 	:= TRFunction():New(oReport:Section(1):Cell("QUANT")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
oTotFDif 	:= TRFunction():New(oReport:Section(1):Cell("DIF")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("C7_QUANT")/*oCell*/,/*cName*/,"ONPRINT"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,{||oTotFQtd:GetValue()}/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("ZLX_VOLREC")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("VOL_DIF")/*oCell*/,/*cName*/,"ONPRINT"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,{||oTotFDif:GetValue()}/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)



//==========================================================================
// Trata as células a serem exibidas de acordo com sessão e parâmetros
//==========================================================================
If !_lPlanilha
	oReport:Section(1):Cell("ZZX_CODPRD"):Disable()
EndIf
//Colunas criadas apenas para totalização
oReport:Section(1):Cell("QUANT"):Disable()
oReport:Section(1):Cell("DIF"):Disable()

//====================================================================================================
// Monta filtro de acordo com a tabela de origem
//====================================================================================================
_cFiltro += " AND ZZX.ZZX_FILIAL "+ GetRngFil( _aSelFil, "ZZX", .T.,)
If !Empty(MV_PAR04)
	_cFiltro += " AND ZZX.ZZX_CODPRD IN "+ FormatIn( MV_PAR04 , ';' )
EndIf

If MV_PAR03 == 1 
	_cFiltro += " AND ZLX.ZLX_TIPOLT = 'F' "
ElseIf MV_PAR03 == 2 
	_cFiltro += " AND ZLX.ZLX_TIPOLT = 'T' "
ElseIf MV_PAR03 == 3 
 _cFiltro += " AND ZLX.ZLX_TIPOLT = 'P' "
EndIf

//Centro Leite
If MV_PAR10 == 1
	_cFiltro += " AND A2_L_CENTR = '1' "
ElseIf MV_PAR10 == 2
	_cFiltro += " AND A2_L_CENTR = '2' "
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
SELECT ZZX_FILIAL, ZZX_CODPRD, X5_DESCRI PRODUTO, ZLX_TIPOLT, A2_COD, A2_LOJA, A2_NREDUZ, ZLX_NRONF, C7_NUM, C7_EMISSAO,
       C7_L_PMEST, C7_L_EXEST, C7_QUANT, ZLX_VOLREC, C7_PRECO, ZLX_PRCNF, ZAP_GORD,
       C7_QUANT - SUM(ZLX_VOLREC) OVER (PARTITION BY C7_NUM ORDER BY ZLX_NRONF) VOL_DIF, C7_PRECO - ZLX_PRCNF PRC_DIF,
	   Case WHEN ROW_NUMBER() OVER (PARTITION BY C7_NUM ORDER BY ZLX_NRONF DESC) = 1 
         THEN C7_QUANT - SUM(ZLX_VOLREC) OVER (PARTITION BY C7_NUM ORDER BY ZLX_NRONF)
         Else 0 END AS DIF,
       NVL(Round(Case
                   WHEN NVL(Round(ZAP_GORD, 2), 0) > C7_L_PMGB AND NVL(Round(ZAP_GORD, 2), 0) <= C7_L_PMGB2 
				   THEN C7_L_EXEMG
                   WHEN NVL(Round(ZAP_GORD, 2), 0) > C7_L_PMGB2 THEN
                    C7_L_EXEM2
                   Else 0 END, 2), 0) C7_L_EXEMG
	  FROM %Table:ZLX% ZLX, %Table:SA2% SA2, %Table:ZZX% ZZX, %Table:SD1% SD1, %Table:SF1% SF1, %Table:SC7% SC7, %Table:SX5% SX5,
       (SELECT ZAP.ZAP_FILIAL, ZAP.ZAP_CODIGO, AVG(ZAP.ZAP_GORD) ZAP_GORD
          FROM %Table:ZAP% ZAP
         WHERE ZAP.D_E_L_E_T_ = ' '
         GROUP BY ZAP.ZAP_FILIAL, ZAP.ZAP_CODIGO) ZAP
	 WHERE SC7.D_E_L_E_T_ = ' '
	   AND SA2.D_E_L_E_T_ = ' '
	   AND ZZX.D_E_L_E_T_ = ' '
	   AND SD1.D_E_L_E_T_ = ' '
	   AND SF1.D_E_L_E_T_ = ' '
	   AND ZLX.D_E_L_E_T_ = ' '
	   AND SX5.D_E_L_E_T_ = ' '
	   AND SC7.C7_FILIAL = %xFilial:SC7%
	   AND SC7.C7_FILIAL = ZZX.ZZX_FILIAL
	   AND ZZX.ZZX_FILIAL = SD1.D1_FILIAL
	   AND SD1.D1_FILIAL = ZLX.ZLX_FILIAL
	   AND SF1.F1_FILIAL = SD1.D1_FILIAL
	   AND SF1.F1_DOC = SD1.D1_DOC
	   AND SF1.F1_SERIE = SD1.D1_SERIE
	   AND SF1.F1_FORNECE = SD1.D1_FORNECE
	   AND SF1.F1_LOJA = SD1.D1_LOJA
	   AND ZLX.ZLX_FORNEC = SA2.A2_COD
	   AND ZLX.ZLX_LJFORN = SA2.A2_LOJA
	   AND ZZX.ZZX_CODIGO = ZLX.ZLX_CODANA
	   AND SD1.D1_PEDIDO = SC7.C7_NUM
	   AND SD1.D1_ITEMPC = SC7.C7_ITEM
	   AND ZLX.ZLX_NRONF = SD1.D1_DOC
	   AND ZLX.ZLX_SERINF = SD1.D1_SERIE
	   AND ZLX.ZLX_FORNEC = SD1.D1_FORNECE
	   AND ZLX.ZLX_LJFORN = SD1.D1_LOJA
	   AND ZLX.ZLX_FILIAL = ZAP.ZAP_FILIAL(+)
   	   AND ZLX.ZLX_CODANA = ZAP.ZAP_CODIGO(+)
	   AND SD1.D1_FORMUL <> 'S'
	   AND SF1.F1_STATUS = 'A'
	   AND ZZX_CODPRD = SX5.X5_CHAVE
	   AND SX5.X5_TABELA = 'Z7'
	   %exp:_cFiltro%
	   AND ZLX.ZLX_DTENTR BETWEEN %exp:MV_PAR01% AND %exp:MV_PAR02%
	   AND ZZX.ZZX_FORNEC BETWEEN %exp:MV_PAR05% AND %exp:MV_PAR07%
	   AND ZZX.ZZX_LJFORN BETWEEN %exp:MV_PAR06% AND %exp:MV_PAR08%
	 ORDER BY ZZX_FILIAL, ZZX_CODPRD, ZLX_TIPOLT, A2_NREDUZ, C7_NUM, ZLX_NRONF
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
	If (_cAlias)->(ZZX_FILIAL+ZZX_CODPRD+C7_NUM) <> _cBreak01
		oReport:Section(1):Cell("QUANT" ):SetBlock({||(_cAlias)->C7_QUANT})
		_cBreak01 := (_cAlias)->(ZZX_FILIAL+ZZX_CODPRD+C7_NUM)
	Else
		oReport:Section(1):Cell("QUANT" ):SetBlock({||0})
	EndIf
	oReport:Section(1):PrintLine()
	oReport:IncMeter()
	_cFilial := (_cAlias)->ZZX_FILIAL
	_cPedido := (_cAlias)->C7_NUM
	_cProduto := (_cAlias)->ZZX_CODPRD+' - '+(_cAlias)->PRODUTO
	(_cAlias)->(DBSkip())
EndDo

oReport:Section(1):Finish()
(_cAlias)->(DBCloseArea())

Return
