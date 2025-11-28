/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |22/04/2025| Chamado 50505. Alterada a picture do CNPJ para contemplar campo alfanumérico
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RGLT063
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 04/03/2020
Descrição---------: Relação de Vendas - Chamado 32194
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RGLT063()

Local oReport
Pergunte("RGLT063",.F.)
//Inferface de Impressão
oReport := ReportDef()
oReport:PrintDialog()

Return

/*
===============================================================================================================================
Programa----------: ReportDef
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 04/03/2020
Descrição---------: Definição do Componente
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ReportDef()

Local oReport
Local oSection
Local _aOrdem   := {"Por Filial"}

//Criacao do componente de impressao
//TReport():New
//ExpC1 : Nome do relatorio
//ExpC2 : Titulo
//ExpC3 : Pergunte
//ExpB4 : Bloco de codigo que sera executado na confirmacao da impressao
//ExpC5 : Descricao

oReport := TReport():New("RGLT063","Relação de Vendas","RGLT063",;
{|oReport| ReportPrint(oReport,_aOrdem)},"Exibe a relação das notas de vendas os produtos do Leite.")
oSection := TRSection():New(oReport,"Dados"	,/*uTable {}*/, _aOrdem/*aOrder*/, .F./*lLoadCells*/, .T./*lLoadOrder*/,"Total das Filiais: "/*uTotalText*/)
oReport:SetLandscape()//Paisagem

oSection:SetTotalInLine(.F.)

//TRCell():New(oParent,cName,cAlias,cTitle,cPicture,nSize,lPixel,bBlock,cAlign,lLineBreak,cHeaderAlign,lCellBreak,nColSpace,lAutoSize,nClrBack,nClrFore,lBold)
TRCell():New(oSection,"D2_FILIAL","SD2"/*Table*/,"Fil"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"D2_EMISSAO","SD2"/*Table*/,"Emissão"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"D2_DOC","SD2"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"D2_SERIE","SD2"/*Table*/,"Ser"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"CLIENTE",/*Table*/,"Cliente"/*cTitle*/,/*Picture*/,11/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A1_CGC","SA1"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A1_NOME","SA1"/*Table*/,/*cTitle*/,/*Picture*/,40/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"D2_COD","SD2"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"B1_DESC","SB1"/*Table*/,/*cTitle*/,/*Picture*/,40/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"D2_QUANT","SD2"/*Table*/,/*cTitle*/,"@E 999,999,999"/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"D2_QTDEDEV","SD2"/*Table*/,/*cTitle*/,"@E 999,999,999"/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"QTD_LIQ",/*Table*/,"Qtd. Líquida"/*cTitle*/,GetSX3Cache("D2_QUANT","X3_PICTURE")/*Picture*/,GetSX3Cache("D2_QUANT","X3_TAMANHO")/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"D2_PRCVEN","SD2"/*Table*/,/*cTitle*/,"@E 999.9999"/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"D2_TOTAL","SD2"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"D2_VALDEV","SD2"/*Table*/,"Vlr. Dev."/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"TOTAL_LIQ",/*Table*/,"Total Líquido"/*cTitle*/,GetSX3Cache("D2_QUANT","X3_PICTURE")/*Picture*/,GetSX3Cache("D2_QUANT","X3_TAMANHO")/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"STATUS",/*Table*/,"Status"/*cTitle*/,/*Picture*/,7/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"F2_I_PLACA","SF2"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"TRANSP","SF2"/*Table*/,"Transp."/*cTitle*/,/*Picture*/,11/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"F2_I_NTRAN","SF2"/*Table*/,/*cTitle*/,/*Picture*/,40/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
Return oReport

/*
===============================================================================================================================
Programa----------: ReportPrint
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 04/03/2020
Descrição---------: Processa impressão do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ReportPrint(oReport,_aOrdem)

Local _cFiltro		:= "%"
Local _cAlias		:= ""
Local _aSelFil		:= {}
Local _nOrdem		:= oReport:Section(1):GetOrder()
Local _cFilial		:= ""
Local _nCountRec	:= 0
Local _lPlanilha 	:= oReport:nDevice == 4

//Chama função que permitirá a seleção das filiais
If MV_PAR01 == 1
    If Empty(_aSelFil)
        _aSelFil := AdmGetFil(.F.,.F.,"SD2")
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
oQbrFilial	:= TRBreak():New( oReport:Section(1)/*oParent*/, oReport:Section(1):Cell("D2_FILIAL")/*uBreak*/, {||"Total da Filial: " + _cFilial + ' - '+ FWFilialName(cEmpAnt,_cFilial,1 )}/*uTitle*/, .F. /*lTotalInLine*/,/*cName*/,.T./*lPageBreak*/)
TRFunction():New(oReport:Section(1):Cell("D2_FILIAL")/*oCell*/,/*cName*/,"COUNT"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("D2_QUANT")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("D2_QTDEDEV")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("QTD_LIQ")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("D2_TOTAL")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("D2_VALDEV")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("TOTAL_LIQ")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("D2_QTDEDEV")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)

//==========================================================================
// Trata as células a serem exibidas de acordo com sessão e parâmetros
//==========================================================================
If !_lPlanilha
	oReport:Section(1):Cell("A1_CGC"):Disable()
	oReport:Section(1):Cell("QTD_LIQ"):Disable()
	oReport:Section(1):Cell("TOTAL_LIQ"):Disable()
EndIf
//====================================================================================================
// Monta filtro de acordo com a tabela de origem
//====================================================================================================
_cFiltro += " AND D2_FILIAL "+ GetRngFil( _aSelFil, "SD2", .T.,)
If !Empty(MV_PAR12)
     _cFiltro += " AND B1_COD IN " + FormatIn( AllTrim(MV_PAR12) , ';' )
EndIf
If MV_PAR13 == 2
     _cFiltro += " AND E1_SALDO = E1_VALOR "
ElseIf MV_PAR13 == 3
     _cFiltro += " AND E1_SALDO = 0 "
ElseIf MV_PAR13 == 4
     _cFiltro += " AND E1_VALOR <> E1_SALDO "
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
	column DT_INC as Date
     SELECT D2_FILIAL, D2_EMISSAO, D2_DOC, D2_SERIE, D2_CLIENTE||'-'|| D2_LOJA CLIENTE, A1_CGC, A1_NOME, D2_COD,B1_DESC,
          D2_QUANT, D2_QTDEDEV, D2_QUANT - D2_QTDEDEV QTD_LIQ, Round(D2_PRCVEN, 4) D2_PRCVEN, D2_TOTAL, D2_VALDEV,
          D2_TOTAL - D2_VALDEV TOTAL_LIQ, F2_I_CTRA||'-'||F2_I_LTRA TRANSP, F2_I_NTRAN, F2_I_PLACA,
          Case WHEN E1_VALOR IS NULL THEN '-'
          WHEN E1_SALDO = 0 THEN 'Baixado'
          WHEN E1_SALDO = E1_VALOR THEN 'Aberto'
          WHEN E1_VALOR <> E1_SALDO THEN 'Parc.' END STATUS
     FROM %Table:SD2% SD2, %Table:SF20% SF2, %Table:SA1% SA1, %Table:ZA7% ZA7, %Table:SB1% SB1, %Table:SE1% SE1
     WHERE SD2.D_E_L_E_T_ = ' '
     AND SF2.D_E_L_E_T_ = ' '
     AND SA1.D_E_L_E_T_ = ' '
     AND ZA7.D_E_L_E_T_ = ' '
     AND SB1.D_E_L_E_T_ = ' '
     AND SE1.D_E_L_E_T_ (+) = ' '
     AND D2_CLIENTE = A1_COD
     AND D2_LOJA = A1_LOJA
     AND D2_FILIAL = F2_FILIAL
     AND D2_DOC = F2_DOC
     AND D2_SERIE = D2_SERIE
     AND D2_CLIENTE = F2_CLIENTE
     AND D2_LOJA = F2_LOJA
     AND ZA7_FILIAL = D2_FILIAL
     AND ZA7_CODPRD = D2_COD
     AND D2_COD = B1_COD
     AND E1_FILIAL (+) = D2_FILIAL
     AND E1_SERIE (+) = D2_SERIE
     AND E1_NUM (+) = D2_DOC
     AND E1_CLIENTE (+) = D2_CLIENTE
     AND E1_LOJA (+) = D2_LOJA
     AND E1_ORIGEM (+) = 'MATA460'
     AND E1_TIPO (+) = 'NF'
     %exp:_cFiltro%
     AND D2_CLIENTE BETWEEN %exp:MV_PAR02% AND %exp:MV_PAR03%
     AND D2_LOJA BETWEEN %exp:MV_PAR04% AND %exp:MV_PAR05%
     AND D2_EMISSAO BETWEEN %exp:MV_PAR06% AND %exp:MV_PAR07%
     AND F2_I_CTRA BETWEEN %exp:MV_PAR08% AND %exp:MV_PAR09%
     AND F2_I_LTRA BETWEEN %exp:MV_PAR10% AND %exp:MV_PAR11%
     AND D2_TIPO NOT IN ('B', 'D')
     ORDER BY D2_FILIAL, D2_CLIENTE, D2_LOJA, D2_EMISSAO, D2_DOC
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
oReport:SetMeter(_nCountRec)

While !oReport:Cancel() .And. (_cAlias)->(!Eof())
	//Mascara para impressao - CNPJ/CPF
	If RetPessoa((_cAlias)->A1_CGC) == "J"
		oReport:Section(1):Cell("A1_CGC"):SetPicture("@R! NN.NNN.NNN/NNNN-99")
	Else
		oReport:Section(1):Cell("A1_CGC"):SetPicture("@R 999.999.999-99")
	EndIf

	oReport:Section(1):PrintLine()
	oReport:IncMeter()
	_cFilial := (_cAlias)->D2_FILIAL
	(_cAlias)->(DBSkip())
EndDo

oReport:Section(1):Finish()
(_cAlias)->(DBCloseArea())

Return
