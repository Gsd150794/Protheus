/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |27/12/2021| Chamado 38737. Nova opcao no parametro 7: "6-Parcialmente Atendidos"
Alex Wallauer |03/01/2022| Chamado 38797. Alterado o pergunte de "MATR120" para "RCOM010"
Lucas Borges  |09/10/2024| Chamado 48465. Retirada manipulação do SX1
===============================================================================================================================
*/

#Include "Matr120.ch"
#Include "TOTVS.ch"    

/*
===============================================================================================================================
Programa--------: RCOM010
Autor-----------: Talita
Data da Criacao-: 18/09/2014
Descrição-------: Versão customizada do relatório padrão MATR120.
                  Relação de Pedidos de Compras em Aberto.
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/

User Function RCOM010()
Local oReport
Private Inclui := .F. 
Private Altera := .F. 
Private Exclui := .F. 

//If FindFunction("TRepInUse") .And. TRepInUse()
	//==========================================================================
	//Interface de impressao                                                  
	//==========================================================================
	oReport := RCOM010R()
	oReport:PrintDialog()
//Else
//	RCOM010A()
//EndIf

Return

/*
===============================================================================================================================
Programa--------: RCOM010R
Autor-----------: Talita
Data da Criacao-: 18/09/2014
Descrição-------: Monta relatório
Parametros------: Nenhum 
Retorno---------: ExpO1: Objeto do relatório  
===============================================================================================================================
*/

Static Function RCOM010R()

Local oReport 
Local oSection1
Local oSection2 
//Local oSection3 
//Local oSection4
//Local oSection5
//Local oCell         
Local aOrdem	:= {}
Local cAliasSC7 := GetNextAlias()
//Local cAliasSB1 := GetNextAlias()
Private cPerg := "RCOM010"

If !FWSX1Util():ExistPergunte(cPerg)
   cPerg := "MTR120"
EndIf

oReport:= TReport():New(cPerg,"Relacao de Pedidos de Compras",cPerg,;
 				{|oReport| RCOM010P(oReport,cAliasSC7)},;
 				"Emissao da Relacao de  Pedidos de Compras. Sera solicitado em qual Ordem, qual o Intervalo para a emissao dos pedidos de compras.") 
oReport:SetLandscape()    
oReport:SetTotalInLine(.F.)
Pergunte(cPerg,.F.)
aAdd( aOrdem, "Por Numero")  
aAdd( aOrdem, "Por Produto" )  
aAdd( aOrdem, "Por Fornecedor" )  
aAdd( aOrdem, "Por Previsao de Entrega " )  

oSection1 := TRSection():New(oReport,"Relacao de Pedidos de Compras",{"SC7","SA2","SB1"},aOrdem) 
oSection1 :SetTotalInLine(.F.)

TRCell():New(oSection1,"C7_NUM","SC7","Num.PC"/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/) 
TRCell():New(oSection1,"C7_NUMSC","SC7",/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"C7_FORNECE","SC7",/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"C7_LOJA","SC7",/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"A2_NOME","SA2",/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"A2_TEL","SA2",/*Titulo*/,/*Picture*/,15,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"A2_FAX","SA2",/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"A2_CONTATO","SA2",/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"C7_PRODUTO","SC7",/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/,,,,,,.F.)
TRCell():New(oSection1,"cDescri","   ",/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| RCOM010D(cAliasSC7) })
TRCell():New(oSection1,"C7_DATPRF","SC7","ENTREGA PREVISTA :  ",/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/) 
oSection1:Cell("cDescri"):GetFieldInfo("B1_DESC")             

oSection2 := TRSection():New(oSection1,"Pedido de Compras / Autorizac. de Entrega (Productos)",{"SC7","SA2","SB1"}) 
oSection2 :SetTotalInLine(.F.)
oSection2 :SetHeaderPage()
oSection2 :SetTotalText("Total Geral ") 

TRCell():New(oSection2,"C7_NUM","SC7","Num.PC"/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection2,"C7_ITEM","SC7",/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection2,"C7_PRODUTO","SC7",/*Titulo*/,/*Picture*/,,/*lPixel*/,/*{|| code-block de impressao }*/,,,,,,.F.)
TRCell():New(oSection2,"cDescri","   ",/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| RCOM010D(cAliasSC7) })
oSection2:Cell("cDescri"):GetFieldInfo("B1_DESC")
TRCell():New(oSection2,"B1_GRUPO","SB1",/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection2,"C7_EMISSAO","SC7","Emissao"/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection2,"C7_FORNECE","SC7",/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection2,"C7_LOJA","SC7",STR0067/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)//"Lj"
TRCell():New(oSection2,"A2_NOME","SA2",/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection2,"A2_TEL","SA2",/*Titulo*/,/*Picture*/,15,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection2,"C7_DATPRF","SC7",STR0066/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/) //"Entrega"
TRCell():New(oSection2,"C7_QUANT"  ,"SC7","Qtde. UM",/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection2,"C7_UM"     ,"SC7","UM"/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)//"UM"
TRCell():New(oSection2,"C7_QTSEGUM","SC7","Qtde. 2aUM"/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)//Talita Teixeira - 18/09/14 - Feito a alteração para que as quantidades sejam mostradas em caixa e não em unidades conforme chamado 6206
TRCell():New(oSection2,"C7_SEGUM"  ,"SC7","2aUM"/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)//"UM"
TRCell():New(oSection2,"nVlrUnit","   ",/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| RCOM010U(cAliasSC7) }) 
oSection2:Cell("nVlrUnit"):GetFieldInfo("C7_PRECO")
TRCell():New(oSection2,"C7_VLDESC","   ",/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| RCOM010E(cAliasSC7) }) 
TRCell():New(oSection2,"nVlrIPI","   ",/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| RCOM010M(cAliasSC7) })
oSection2:Cell("nVlrIPI"):GetFieldInfo("C7_VALIPI")
TRCell():New(oSection2,"C7_TOTAL","SC7",/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| RCOM010T(cAliasSC7) })
TRCell():New(oSection2,"nQtdEnt1","   ","Qtd.Entreg UM" ,PesqPict('SC7','C7_QUJE') ,,,{||  (cAliasSC7)->C7_QUJE  })
TRCell():New(oSection2,"nQtdEnt","    ","Qtd.Entr 2aUM" ,PesqPict('SC7','C7_QUJE') ,,,{|| If(Empty((cAliasSC7)->C7_RESIDUO),IIf((cAliasSC7)->C7_QUJE<0,0,(cAliasSC7)->C7_QUJE)/SB1->B1_CONV,0) })
TRCell():New(oSection2,"nQtdRec1","   ","Qtd.Receber UM",PesqPict('SC7','C7_QUANT'),,,{|| (cAliasSC7)->C7_QUANT-(cAliasSC7)->C7_QUJE }) //Quant.Receber 1 um
TRCell():New(oSection2,"nQtdRec","    ","Qtd.Receb 2aUM",PesqPict('SC7','C7_QUANT'),,,{|| If(Empty((cAliasSC7)->C7_RESIDUO),IIf((cAliasSC7)->C7_QUANT-(cAliasSC7)->C7_QUJE<0,0,(cAliasSC7)->C7_QUANT-(cAliasSC7)->C7_QUJE)/SB1->B1_CONV,0) }) 
TRCell():New(oSection2,"nSalRec","    ",STR0061,PesqPict('SC7','C7_TOTAL'),TamSX3("C7_TOTAL")[1],/*lPixel*/,{|| RCOM010S(cAliasSC7) }) //Saldo Receber
//TRCell():New(oSection2,"C7_RESIDUO","   ",STR0070+CRLF+STR0071/*Titulo*/,/*Picture*/,3,/*lPixel*/,{|| If(Empty((cAliasSC7)->C7_RESIDUO),STR0031,STR0032) }) //"Res."##"Elim."

//TRFunction():New(oSection2:Cell("C7_QUANT"),NIL,"SUM",/*oBreak*/,/*Titulo*/,/*cPicture*/,/*uFormula*/,.T.,.T.,,oSection1) 
//TRFunction():New(oSection2:Cell("C7_QTSEGUM"),NIL,"SUM",/*oBreak*/,/*Titulo*/,/*cPicture*/,/*uFormula*/,.T.,.T.,,oSection1) 
TRFunction():New(oSection2:Cell("nVlrIPI"),NIL,"SUM",/*oBreak*/,/*Titulo*/,/*cPicture*/,/*uFormula*/,.T.,.T.,,oSection1) 
TRFunction():New(oSection2:Cell("C7_TOTAL"),NIL,"SUM",/*oBreak*/,/*Titulo*/,/*cPicture*/,/*uFormula*/,.T.,.T.,,oSection1)
//TRFunction():New(oSection2:Cell("nQtdEnt1"),NIL,"SUM",/*oBreak*/,/*Titulo*/,/*cPicture*/,/*uFormula*/,.T.,.T.,,oSection1) 
//TRFunction():New(oSection2:Cell("nQtdEnt"),NIL,"SUM",/*oBreak*/,/*Titulo*/,/*cPicture*/,/*uFormula*/,.T.,.T.,,oSection1) 
//TRFunction():New(oSection2:Cell("nQtdRec1"),NIL,"SUM",/*oBreak*/,/*Titulo*/,/*cPicture*/,/*uFormula*/,.T.,.T.,,oSection1) 
//TRFunction():New(oSection2:Cell("nQtdRec"),NIL,"SUM",/*oBreak*/,/*Titulo*/,/*cPicture*/,/*uFormula*/,.T.,.T.,,oSection1) 
TRFunction():New(oSection2:Cell("nSalRec"),NIL,"SUM",/*oBreak*/,/*Titulo*/,/*cPicture*/,/*uFormula*/,.T.,.T.,,oSection1) 

Return(oReport)

/*
===============================================================================================================================
Programa--------: RCOM010P
Autor-----------: Talita
Data da Criacao-: 18/09/2014
Descrição-------: Monta dados do relatório
Parametros------: oReport - objeto do relatório
				  cAliasSC7	- alias a ser usado para ler os dados
Retorno---------: Nenhum
===============================================================================================================================
*/

Static Function RCOM010P(oReport,cAliasSC7)

Local oSection1 := oReport:Section(1) 
Local oSection2 := oReport:Section(1):Section(1)  
Local nOrdem    := oReport:Section(1):GetOrder() 
Local nTamDPro	:= If( TamSX3("C7_PRODUTO")[1] > 15, 20, 30 )
Local nFilters 	:= 0
Local nI
Local cWhere := ""
Local cFrom := "%%"

Local lFilUsr	:= oSection1:GetAdvplExp() <> ""

//GRAVA LOG DE USO
U_ITLOGACS("U_RCOM010")

DBSelectArea("SC7")
If nOrdem == 4
	DBSetOrder(16) 
Else
	DBSetOrder(nOrdem)
EndIf

If nOrdem == 1
	If ( cPaisLoc$"ARG|POR|EUA" )	//Ordena los pedidos de compra y luego la AE.
		DBSetOrder(10)
	EndIf	
	oReport:SetTitle( oReport:Title()+STR0014) // " - POR NUMERO"
	oSection1 :SetTotalText(STR0034) //"Total dos Itens: " 
ElseIf nOrdem == 2
	oReport:SetTitle( oReport:Title()+STR0018) //" - POR PRODUTO"
	oSection1 :SetTotalText(STR0035) //"Total do Produto"
ElseIf nOrdem == 3
	oReport:SetTitle( oReport:Title()+STR0022) //" - POR FORNECEDOR"
	oSection1 :SetTotalText(STR0036) //"Total do Fornecedor"
ElseIf nOrdem == 4
	oReport:SetTitle( oReport:Title()+STR0053) //" - POR PREVISAO DE ENTREGA"
	oSection1 :SetTotalText(STR0043) //"Total da Previsao de Entrega"
EndIf

If ValType(MV_PAR07) = "C"
   MV_PAR07:=Val(MV_PAR07)
EndIf

If MV_PAR07==1
	oReport:SetTitle( oReport:Title()+STR0025) //", Todos"
ElseIf MV_PAR07==2
	oReport:SetTitle( oReport:Title()+STR0026) //", Em Abertos"
ElseIf MV_PAR07==3
	oReport:SetTitle( oReport:Title()+STR0027) //", Residuos"
ElseIf MV_PAR07==4
	oReport:SetTitle( oReport:Title()+STR0028) //", Atendidos"
ElseIf MV_PAR07==5
	oReport:SetTitle( oReport:Title()+STR0059) //", Atendidos + Parcial entregue"
ElseIf MV_PAR07==6
	oReport:SetTitle( oReport:Title()+"Parcialmente Atendidos") 
EndIf
oReport:SetTitle( oReport:Title()+" - " + GetMv("MV_MOEDA"+Str(MV_PAR13,1))) //" MOEDA "
//==========================================================================
//Filtragem do relatório                                                  
//==========================================================================
	//==========================================================================
	//Transforma parametros Range em expressao SQL                            	
	//==========================================================================
	MakeSqlExpr(oReport:uParam)
	//==========================================================================
	//Query do relatório da secao 1                                           
	//==========================================================================
	oReport:Section(1):BeginQuery()	

	cWhere :="%"

	If MV_PAR11 == 1 
		cWhere += "AND C7_CONAPRO <> 'B' "	
	ElseIf MV_PAR11 == 2
		cWhere += "AND C7_CONAPRO = 'B' "	
	EndIf

	If MV_PAR07 == 2 
		cWhere += "AND ( (C7_QUANT-C7_QUJE) > 0 ) "	
		cWhere += "AND C7_RESIDUO = ' ' "
	ElseIf MV_PAR07 == 3
		cWhere += "AND C7_RESIDUO <> ' ' "
	ElseIf MV_PAR07 == 4
		cWhere += "AND C7_QUANT <= C7_QUJE "	
	ElseIf MV_PAR07 == 5
		cWhere += "AND C7_QUJE > 0 "		
	ElseIf MV_PAR07 == 6
		cWhere += "AND C7_QUJE > 0 AND C7_QUANT > C7_QUJE AND C7_RESIDUO <> 'S' AND C7_ENCER <> 'E' "		
	EndIf
	
	If MV_PAR10 == 1 
		cWhere += "AND C7_TIPO = 1 "	
	ElseIf MV_PAR10 == 2
		cWhere += "AND C7_TIPO = 2 "	
	EndIf
	
	If MV_PAR12 == 1 //Firmes
		cWhere += "AND (C7_TPOP = 'F' OR C7_TPOP = ' ') "	
	ElseIf MV_PAR12 == 2 //Previstas
		cWhere += "AND C7_TPOP = 'P' "	
	EndIf
	
	If lFilUsr
		nFilters := Len(oSection1:aUserFilter)
		
		cFrom := "%"
		
		For nI := 1 to nFilters
			If oSection1:aUserFilter[nI][1] == "SA2" .And. oSection1:aUserFilter[nI][2] <> ""
				cFrom += "," + RetSqlName("SA2") + " SA2 "
				cWhere += "AND C7_FORNECE = A2_COD "
				
			ElseIf	oSection1:aUserFilter[nI][1] == "SB1" .And. oSection1:aUserFilter[nI][2] <> ""
				cFrom += "," + RetSqlName("SB1") + " SB1 "
				cWhere += "AND C7_PRODUTO = B1_COD "
			EndIf	
		Next nI
		
		cFrom += "%" 
	EndIf

	cWhere +="%"	

	BeginSql Alias cAliasSC7

	SELECT C7_NUM,C7_PRODUTO,C7_FORNECE,C7_LOJA,C7_DATPRF,C7_DESCRI,C7_TXMOEDA,C7_EMISSAO,
           C7_REAJUST,C7_MOEDA,C7_PRECO,C7_NUMSC,C7_UM,C7_SEGUM,C7_QUANT,C7_ITEM,C7_SEQUEN,
           C7_DESC1,C7_DESC2,C7_DESC3,C7_IPIBRUT,C7_IPI,C7_RESIDUO,C7_QUJE,C7_VLDESC
	
	FROM %Table:SC7% SC7 %Exp:cFrom%
	
	WHERE C7_FILIAL = %xFilial:SC7% AND 
		  C7_NUM >= %Exp:MV_PAR08% AND 
		  C7_NUM <= %Exp:MV_PAR09% AND 	 	  
		  C7_PRODUTO >= %Exp:MV_PAR01% AND 
		  C7_PRODUTO <= %Exp:MV_PAR02% AND 
  		  C7_EMISSAO >= %Exp:DToS(MV_PAR03)% AND 
		  C7_EMISSAO <= %Exp:DToS(MV_PAR04)% AND 
  		  C7_DATPRF >= %Exp:DToS(MV_PAR05)% AND 
		  C7_DATPRF <= %Exp:DToS(MV_PAR06)% AND 		  
	 	  C7_FORNECE >= %Exp:MV_PAR15% AND 
		  C7_FORNECE <= %Exp:MV_PAR16% AND 
		  SC7.%NotDel% 
		  %Exp:cWhere%
		  
	ORDER BY %Order:SC7% 
			
	EndSql 

	oReport:Section(1):EndQuery(/*Array com os parametros do tipo Range*/)

oSection2:SetParentQuery()

Do Case
	Case nOrdem == 1
		oSection2:SetParentFilter( { |cParam| (cAliasSC7)->C7_NUM == cParam },{ || (cAliasSC7)->C7_NUM })
	Case nOrdem == 2
		oSection2:SetParentFilter( { |cParam| (cAliasSC7)->C7_PRODUTO == cParam },{ || (cAliasSC7)->C7_PRODUTO })
	Case nOrdem == 3
		oSection2:SetParentFilter( { |cParam| (cAliasSC7)->C7_FORNECE+(cAliasSC7)->C7_LOJA == cParam },{ || (cAliasSC7)->C7_FORNECE+(cAliasSC7)->C7_LOJA })
	Case nOrdem == 4
		oSection2:SetParentFilter( { |cParam| (cAliasSC7)->C7_DATPRF == cParam },{ || (cAliasSC7)->C7_DATPRF })
EndCase

TRPosition():New(oSection1,"SA2",1,{|| xFilial("SA2") + (cAliasSC7)->C7_FORNECE+(cAliasSC7)->C7_LOJA})
TRPosition():New(oSection1,"SB1",1,{|| xFilial("SB1") + (cAliasSC7)->C7_PRODUTO})
TRPosition():New(oSection2,"SA2",1,{|| xFilial("SA2") + (cAliasSC7)->C7_FORNECE+(cAliasSC7)->C7_LOJA})
TRPosition():New(oSection2,"SB1",1,{|| xFilial("SB1") + (cAliasSC7)->C7_PRODUTO})
//==========================================================================
//Inicio da impressao do fluxo do relatório                               
//==========================================================================
DBSelectArea(cAliasSC7)
(cAliasSC7)->(DBGoTop())
nConta:=0
COUNT TO nConta
(cAliasSC7)->(DBGoTop())

oReport:SetMeter(nConta)

If nOrdem <> 2
	oSection1:Cell("cDescri"):SetSize(nTamDPro)
	oSection2:Cell("cDescri"):SetSize(nTamDPro)
EndIf

Do Case
		Case nOrdem == 1

			oSection1:Cell("C7_PRODUTO"):Disable()
			oSection1:Cell("cDescri"):Disable()
			oSection1:Cell("A2_FAX"):Disable()
			oSection1:Cell("A2_CONTATO"):Disable()
			oSection1:Cell("C7_DATPRF"):Disable()

			oSection2:Cell("C7_NUM"):Disable()
			oSection2:Cell("C7_FORNECE"):Disable()
			oSection2:Cell("A2_NOME"):Disable()
			oSection2:Cell("A2_TEL"):Disable()
			
			oSection1:Print()
		
		Case nOrdem == 2

			oSection1:Cell("C7_NUM"):Disable()
			oSection1:Cell("C7_NUMSC"):Disable()
			oSection1:Cell("C7_FORNECE"):Disable()
			oSection1:Cell("A2_NOME"):Disable()
			oSection1:Cell("A2_TEL"):Disable()
			oSection1:Cell("A2_FAX"):Disable()
			oSection1:Cell("A2_CONTATO"):Disable()
			oSection1:Cell("C7_DATPRF"):Disable()
			
			oSection2:Cell("C7_PRODUTO"):Disable()
			oSection2:Cell("cDescri"):Disable()
			oSection2:Cell("B1_GRUPO"):Disable()
			//oSection2:Cell("C7_SEGUM"):Disable() //Talita Teixeira - 26/09/14 - Corrigido erro log apresentado com a ordem 2 e 3 (Alterado a variavel de C7_UM para C7_SEGUM). CHamado 7547
			oSection2:Cell("A2_TEL"):Disable()
			
			oSection1:Print()
	
		Case nOrdem == 3

			oSection1:Cell("C7_NUM"):Disable()
			oSection1:Cell("C7_NUMSC"):Disable()
			oSection1:Cell("C7_PRODUTO"):Disable()
			oSection1:Cell("cDescri"):Disable()
			oSection1:Cell("C7_DATPRF"):Disable()
			
			oSection2:Cell("C7_FORNECE"):Disable()
			oSection2:Cell("A2_NOME"):Disable()
			oSection2:Cell("A2_TEL"):Disable()
			//oSection2:Cell("C7_SEGUM"):Disable()//Talita Teixeira - 26/09/14 - Corrigido erro log apresentado com a ordem 2 e 3(Alterado a variavel de C7_UM para C7_SEGUM). CHamado 7547

			oSection1:Print()
			
		Case nOrdem == 4
		
			oSection1:Cell("C7_NUM"):Disable()
			oSection1:Cell("C7_NUMSC"):Disable()
			oSection1:Cell("C7_FORNECE"):Disable()
			oSection1:Cell("A2_NOME"):Disable()
			oSection1:Cell("A2_TEL"):Disable()
			oSection1:Cell("A2_FAX"):Disable()
			oSection1:Cell("A2_CONTATO"):Disable()
			oSection1:Cell("C7_PRODUTO"):Disable()
			oSection1:Cell("cDescri"):Disable()
			
			oSection2:Cell("B1_GRUPO"):Disable()
			oSection2:Cell("C7_DATPRF"):Disable()
			oSection2:Cell("C7_SEGUM"):Disable()
			oSection2:Cell("C7_FORNECE"):SetTitle(STR0064) //"Fornec."
			oSection2:Cell("cDescri"):SetSize(15)            

			If TamSX3("C7_PRODUTO")[1] > 15
				oSection2:Cell("A2_NOME"):Disable()
				oSection1:Cell("cDescri"):SetSize(14)
				oSection2:Cell("cDescri"):SetSize(14)
			Else
				oSection1:Cell("A2_NOME"):SetSize(15)
				oSection2:Cell("A2_NOME"):SetSize(15)
			EndIf
		
			oSection1:Print()			
EndCase			

Return

/*
===============================================================================================================================
Programa--------: RCOM010D
Autor-----------: Talita
Data da Criacao-: 18/09/2014
Descrição-------: Retorna descrição do produto do pedido
Parametros------: cAliasSC7	- alias a ser usado para ler os dados
Retorno---------: CDESCRI - Descrição do produto
===============================================================================================================================
*/

Static Function RCOM010D(cAliasSC7)

Local aArea   := FWGetArea()
Local cDescri := ""

If Empty(MV_PAR14)
	MV_PAR14 := "B1_DESC"
EndIf

//================================================================
// Impressao da descricao generica do Produto.                  
//================================================================
If AllTrim(MV_PAR14) == "B1_DESC"
	DBSelectArea("SB1")
	DBSetOrder(1)
	DBSeek( xFilial("SB1")+(cAliasSC7)->C7_PRODUTO )
	cDescri := AllTrim(SB1->B1_DESC)
EndIf
//================================================================
// Impressao da descricao cientifica do Produto.                
//================================================================
If AllTrim(MV_PAR14) == "B5_CEME"
	DBSelectArea("SB5")
	DBSetOrder(1)
	If DBSeek( xFilial("SB5")+(cAliasSC7)->C7_PRODUTO )
		cDescri := AllTrim(B5_CEME)
	EndIf
EndIf

DBSelectArea("SC7")
If AllTrim(MV_PAR14) == "C7_DESCRI"
	cDescri := AllTrim((cAliasSC7)->C7_DESCRI)
EndIf

FWRestArea(aArea)

Return(cDescri)

/*
===============================================================================================================================
Programa--------: RCOM010U
Autor-----------: Talita
Data da Criacao-: 18/09/2014
Descrição-------: Retorna valor unitário do pedido
Parametros------: cAliasSC7	- alias a ser usado para ler os dados
Retorno---------: nVlrUnit - valor unitário do produto
===============================================================================================================================
*/

Static Function RCOM010U(cAliasSC7)

Local aArea    := FWGetArea()
Local nVlrUnit := 0
Local aTam	   := TamSX3("C7_PRECO")
Local nTxMoeda := IIf((cAliasSC7)->C7_TXMOEDA > 0,(cAliasSC7)->C7_TXMOEDA,Nil)

If !Empty((cAliasSC7)->C7_REAJUST)
	nVlrUnit := xMoeda(RCOM001F((cAliasSC7)->C7_REAJUST),(cAliasSC7)->C7_MOEDA,MV_PAR13,(cAliasSC7)->C7_DATPRF,aTam[2],nTxMoeda) 
Else
	nVlrUnit := xMoeda((cAliasSC7)->C7_PRECO,(cAliasSC7)->C7_MOEDA,MV_PAR13,(cAliasSC7)->C7_DATPRF,aTam[2],nTxMoeda) 
EndIf

FWRestArea(aArea)

Return(nVlrUnit)

/*
===============================================================================================================================
Programa--------: RCOM010M
Autor-----------: Talita
Data da Criacao-: 18/09/2014
Descrição-------: Retorna valor IPI do pedido
Parametros------: cAliasSC7	- alias a ser usado para ler os dados
Retorno---------: nVlrIPI - valor IPI do produto
===============================================================================================================================
*/

Static Function RCOM010M(cAliasSC7)

Local aArea    := FWGetArea()
Local nVlrIPI  := 0
Local nToTIPI  := 0
Local nTotal   := 0
Local nItemIVA := 0 
Local nValor   := ((cAliasSC7)->C7_QUANT) * IIf(Empty((cAliasSC7)->C7_REAJUST),(cAliasSC7)->C7_PRECO,Formula((cAliasSC7)->C7_REAJUST))
Local nTotDesc := (cAliasSC7)->C7_VLDESC
Local nTxMoeda := IIf((cAliasSC7)->C7_TXMOEDA > 0,(cAliasSC7)->C7_TXMOEDA,Nil)
Local nI 

If cPaisLoc <> "BRA"
	RCOM010W((cAliasSC7)->C7_NUM,(cAliasSC7)->C7_ITEM,(cAliasSC7)->C7_SEQUEN)
	aValIVA := MaFisRet(,"NF_VALIMP")
	If !Empty( aValIVA )
		For nI := 1 To Len( aValIVA )
			nItemIVA += aValIVA[nI]
		Next
	EndIf
	nVlrIPI := xMoeda(nItemIVA,(cAliasSC7)->C7_MOEDA,MV_PAR13,(cAliasSC7)->C7_DATPRF,,nTxMoeda)  
Else
	If nTotDesc == 0
		nTotDesc := CalcDesc(nValor,(cAliasSC7)->C7_DESC1,(cAliasSC7)->C7_DESC2,(cAliasSC7)->C7_DESC3)
	EndIf
	nTotal := nValor - nTotDesc
	nTotIPI := IIf((cAliasSC7)->C7_IPIBRUT == "L",nTotal, nValor) * ( (cAliasSC7)->C7_IPI / 100 )
	nVlrIPI := xMoeda(nTotIPI,(cAliasSC7)->C7_MOEDA,MV_PAR13,(cAliasSC7)->C7_DATPRF,,nTxMoeda)  
EndIf

FWRestArea(aArea)

Return(nVlrIPI)

/*
===============================================================================================================================
Programa--------: RCOM010M
Autor-----------: Talita
Data da Criacao-: 18/09/2014
Descrição-------: Retorna saldo do pedido
Parametros------: cAliasSC7	- alias a ser usado para ler os dados
Retorno---------: nSalRec - saldo do pedido
===============================================================================================================================
*/

Static Function RCOM010S(cAliasSC7)

Local aArea    := FWGetArea()
Local nSalRec  := 0
//Local nItemIVA := 0 
Local nQuant   := If(Empty((cAliasSC7)->C7_RESIDUO),IIf((cAliasSC7)->C7_QUANT-(cAliasSC7)->C7_QUJE<0,0,(cAliasSC7)->C7_QUANT-(cAliasSC7)->C7_QUJE),0)
Local nTotal   := 0
Local nSalIPI  := 0
Local nValor   := ((cAliasSC7)->C7_QUANT) * IIf(Empty((cAliasSC7)->C7_REAJUST),(cAliasSC7)->C7_PRECO,Formula((cAliasSC7)->C7_REAJUST))
Local nSaldo   := ((cAliasSC7)->C7_QUANT-(cAliasSC7)->C7_QUJE) * IIf(Empty((cAliasSC7)->C7_REAJUST),(cAliasSC7)->C7_PRECO,Formula((cAliasSC7)->C7_REAJUST))
Local nTotDesc := (cAliasSC7)->C7_VLDESC
Local nTxMoeda := IIf((cAliasSC7)->C7_TXMOEDA > 0,(cAliasSC7)->C7_TXMOEDA,Nil)
//Local nI 

	If nTotDesc == 0
		nTotDesc := CalcDesc(nValor,(cAliasSC7)->C7_DESC1,(cAliasSC7)->C7_DESC2,(cAliasSC7)->C7_DESC3)
	EndIf
	nTotal := nValor - nTotDesc
	If Empty((cAliasSC7)->C7_RESIDUO)
		nTotal := nSaldo - nTotDesc
		nSalIPI := IIf((cAliasSC7)->C7_IPIBRUT == "L",nTotal, nSaldo) * ( (cAliasSC7)->C7_IPI / 100 )
	EndIf

If Empty((cAliasSC7)->C7_REAJUST)
	nSalRec := (nQuant * xMoeda((cAliasSC7)->C7_PRECO,(cAliasSC7)->C7_MOEDA,MV_PAR13,(cAliasSC7)->C7_DATPRF,,nTxMoeda)-xMoeda((cAliasSC7)->C7_VLDESC,(cAliasSC7)->C7_MOEDA,MV_PAR13,(cAliasSC7)->C7_DATPRF,,nTxMoeda)) + xMoeda(nSalIPI,(cAliasSC7)->C7_MOEDA,MV_PAR13,(cAliasSC7)->C7_DATPRF,,nTxMoeda)
Else
	nSalRec  := (nQuant * xMoeda(Formula((cAliasSC7)->C7_REAJUST),(cAliasSC7)->C7_MOEDA,MV_PAR13,(cAliasSC7)->C7_DATPRF,,nTxMoeda)) + ;
		xMoeda(nSalIPI,(cAliasSC7)->C7_MOEDA,MV_PAR13,(cAliasSC7)->C7_DATPRF,,nTxMoeda)
EndIf   

FWRestArea(aArea)

Return(nSalRec)

/*
===============================================================================================================================
Programa--------: RCOM010T
Autor-----------: Talita
Data da Criacao-: 18/09/2014
Descrição-------: Retorna total do pedido
Parametros------: cAliasSC7	- alias a ser usado para ler os dados
Retorno---------: nVlrTot - total do pedido
===============================================================================================================================
*/

Static Function RCOM010T(cAliasSC7)

Local aArea    := FWGetArea()
Local nVlrTot  := 0
Local nTxMoeda := IIf((cAliasSC7)->C7_TXMOEDA > 0,(cAliasSC7)->C7_TXMOEDA,Nil)

RCOM010W((cAliasSC7)->C7_NUM,(cAliasSC7)->C7_ITEM,(cAliasSC7)->C7_SEQUEN)
nTotal  := MaFisRet(,'NF_TOTAL')
nVlrTot := xMoeda(nTotal,(cAliasSC7)->C7_MOEDA,MV_PAR13,(cAliasSC7)->C7_DATPRF,,nTxMoeda)		  		

FWRestArea(aArea)

Return(nVlrTot)

/*
===============================================================================================================================
Programa--------: RCOM010T
Autor-----------: Talita
Data da Criacao-: 18/09/2014
Descrição-------: Retorna desconto do pedido
Parametros------: cAliasSC7	- alias a ser usado para ler os dados
Retorno---------: nVlrDesc - desconto do pedido
===============================================================================================================================
*/

Static Function RCOM010E(cAliasSC7)

Local aArea    := FWGetArea()
Local nVlrDesc := 0
Local nTxMoeda := IIf((cAliasSC7)->C7_TXMOEDA > 0,(cAliasSC7)->C7_TXMOEDA,Nil)

nVlrDesc := xMoeda((cAliasSC7)->C7_VLDESC,(cAliasSC7)->C7_MOEDA,MV_PAR13,(cAliasSC7)->C7_DATPRF,,nTxMoeda)

FWRestArea(aArea)

Return(nVlrDesc)

/*
===============================================================================================================================
Programa--------: RCOM001F
Autor-----------: Talita
Data da Criacao-: 18/09/2014
Descrição-------: Interpreta formula cadastrada trocando o Alias  
Parametros------: xExp1:= Retorna formula iterpretada                        
                  cExp1:= Codigo da formula previamente cadastrada em SM4  
Retorno---------: xalor - valor da formula	
===============================================================================================================================
*/
Static Function RCOM001F(cFormula)
Local xAlias 
Local cForm		:= "" , xValor
Local cString 	:= "SC7->"
Local cNewAlias := "" 
Local cNewForm	:= ""
//========================================================================
//Salva a integridade dos dados                                         
//========================================================================
xAlias := Alias()

DBSelectArea("SM4")
If DBSeek(cFilial+cFormula)
	cForm := AllTrim(M4_FORMULA)
	cNewAlias := xAlias + "->"
	cNewForm := StrTran(cForm,cString,cNewAlias)
	DBSelectArea(xAlias)      
	xValor := &cNewForm
Else
	xValor := NIL
EndIf
DBSelectArea(xAlias)
Return xValor

/*
===============================================================================================================================
Programa--------: RCOM010W
Autor-----------: Talita
Data da Criacao-: 18/09/2014
Descrição-------: Inicializa as funcoes Fiscais com o Pedido de Compras
Parametros------: ExpC1 := Numero do Pedido                                  
                  ExpC2 := Item do Pedido   
Retorno---------: Nenhum	
===============================================================================================================================
*/

Static Function RCOM010W(cPedido,cItem,cSequen,cFiltro)

Local aArea		:= FWGetArea()
Local aAreaSC7	:= SC7->(GetArea())
Local cValid		:= ""
Local nPosRef		:= 0
Local nItem		:= 0
Local cItemDe		:= IIf(cItem==Nil,'',cItem)
Local cItemAte	:= IIf(cItem==Nil,Repl('Z',Len(SC7->C7_ITEM)),cItem)
Local cRefCols	:= ''
Local _nX, _cX3Valid, _cCampo

Private aHeader := {}, aCols := {}  

Default cSequen	:= ""
Default cFiltro	:= ""

//                          1                    2               3              4               5                6           7        8              9                 10 
// aAdd(aHeader, {AllTrim(SX3->X3_TITULO), SX3->X3_CAMPO, SX3->X3_PICTURE, SX3->X3_TAMANHO, SX3->X3_DECIMAL,SX3->X3_VALID, USADO, SX3->X3_TIPO, SX3->X3_ARQUIVO, SX3->X3_CONTEXT})
FillGetDados(1,"SC7",1,,,{||.T.},,,,,,.T.) 

DBSelectArea("SC7")
DBSetOrder(1)
If DBSeek(xFilial("SC7")+cPedido+cItemDe+AllTrim(cSequen))
	MaFisEnd()
	MaFisIni(SC7->C7_FORNECE,SC7->C7_LOJA,"F","N","R",{})
	While !Eof() .And. SC7->C7_FILIAL+SC7->C7_NUM == xFilial("SC7")+cPedido .And. ;
			SC7->C7_ITEM <= cItemAte .And. (Empty(cSequen) .Or. cSequen == SC7->C7_SEQUEN)

		// Nao processar os Impostos se o item possuir residuo eliminado  
		If &cFiltro
			DBSelectArea('SC7')
			DBSkip()
			Loop
		EndIf
            
		// Inicia a Carga do item nas funcoes MATXFIS  
		nItem++
		MaFisIniLoad(nItem)
		
		For _nX := 1 To Len(aHeader)
		    _cX3Valid := aHeader[_nX,6]
		    _cCampo := AllTrim(aHeader[_nX,2])
		    If _cCampo == "C7_FILIAL" .Or. AllTrim(aHeader[_nX,10]) == "V"
		       Loop
		    EndIf
		    
			cValid	:= StrTran(Upper(_cX3Valid)," ","") 
			cValid	:= StrTran(cValid,"'",'"')
			If "MAFISREF" $ cValid
				nPosRef  := AT('MAFISREF("',cValid) + 10
				cRefCols := SubStr(cValid,nPosRef,AT('","MT120",',cValid)-nPosRef )
				// Carrega os valores direto do SC7.           
				MaFisLoad(cRefCols,&("SC7->"+ _cCampo),nItem)
			EndIf
		Next	

		MaFisEndLoad(nItem,2)
		DBSelectArea('SC7')
		DBSkip()
	End
EndIf

FWRestArea(aAreaSC7)
FWRestArea(aArea)

Return .T.

Static Function SchedDef()

Local aParam  := {}
Local aOrd := {}
aAdd( aOrd, STR0004 ) // "Por Numero"
aAdd( aOrd, STR0005 ) // "Por Produto"
aAdd( aOrd, STR0006 ) // "Por Fornecedor"
aAdd( aOrd, STR0049 ) // "Por Previsao de Entrega "

aParam := { "R",;			//Tipo R para relatorio P para processo
            "RCOM010",;	//Pergunte do relatorio, caso nao use passar ParamDef
            "SC7",;				//Alias
            aOrd,;				//Array de ordens
            STR0007}				//Titulo

Return aParam
