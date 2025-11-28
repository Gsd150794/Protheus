/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Jonathan      |17/08/2020| Chamado 33777. Novas colunas, Código CC, Sugunda unidade de medida e Qtde. Segum
Lucas Borges  |09/09/2024| Chamado 48465. Removendo warning de compilação.
Jose Gavetti  |08/10/2025| Chamado 52167. Novas colunas Vlr Total/ Desconto e Observação.
Jose Gavetti  |05/11/2025| Chamado 52539. Incluída clausula de Left join nas query nas validações das tabelas SC7 e CTT.
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "TOPCONN.CH"

/*
===============================================================================================================================
Programa----------: RCOM009 
Autor-------------: Lucas Crevilari
Data da Criacao---: 10/09/2014
Descrição---------: Relatório Relacoes NFs Entrada por Custo
Parametros--------:
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RCOM009()

	Local oReport

	oReport:= RCOM009D()
	oReport:PrintDialog()

Return

/*
===============================================================================================================================
Programa----------: RCOM009D
Autor-------------: Lucas Crevilari
Data da Criacao---: 10/09/2014
Descrição---------: Emissao da relacao de Compras
Parametros--------:
Retorno-----------: oExpO1: Objeto do relatorio
===============================================================================================================================
*/

Static Function RCOM009D()

	Local aOrdem   := {"Fornecedor","Data De Digitacao","Tipo+Grupo+Codigo"," Grupo+Codigo"}
	Local lVeiculo := Upper(GetMV("MV_VEICULO")) == "S"
	Local nTamCli  := Max(TamSX3("A1_NOME")[1],TamSX3("A2_NOME")[1])-15
	Local cTitle   := "Conferencia NFs de Entrada"
	Local oReport
	Local oSection1
	Local oSection2
	Local cAliasSD1 := GetNextAlias()

	//===========================================================
	// Variaveis utilizadas para parametros                     |
	// MV_PAR01			Produto De                              |
	// MV_PAR02         Produto Ate                             |
	// MV_PAR03			Grupo Produto De						|
	// MV_PAR04			Grupo Produto Ate						|
	// MV_PAR05         Data Emissao De		                    |
	// MV_PAR06         Data Emissao Ate    		            |
	// MV_PAR07			Data Digitacao De						|
	// MV_PAR08			Data Digitacao Ate						|
	// MV_PAR09         Fornecedor de                           |
	// MV_PAR10         Fornecedor Ate                          |
	// MV_PAR11         Imprime Devolucao Compra ?              |
	// MV_PAR12         Filtra Dt Devolucao ?                   |
	// MV_PAR13         Moeda                                   |
	// MV_PAR14         Outras moedas                           |
	// MV_PAR15         Somente NFE com TES                     |
	// MV_PAR16         Imprime Devolucao Venda  ?              |
	// MV_PAR17       	CFOPs	                                |
	// MV_PAR18       	Centro de Custo De                      |
	// MV_PAR19       	Centro de Custo Ate                     |
	// MV_PAR20       	Natureza De                             |
	// MV_PAR21       	Natureza Ate                            |
	// MV_PAR22       	TES Atualiza estoque ? (Sim/Nao/Ambas)	|
	// MV_PAR23			Campos Novos ? (Sim/Nao)				|
	// MV_PAR24			Considera Descontos Vlr Total ? 		|
	//===========================================================
	Pergunte("RCOM009",.T.)

	oReport:= TReport():New("RCOM009",cTitle,"RCOM009", {|oReport| RCOM009R(oReport,aOrdem,cAliasSD1)},"Este relatorio ira imprimir a relacao de itens"+" "+"referentes a compras efetuadas.")
	oReport:SetTotalInLine(.F.)
	oReport:SetLandscape()

	oSection1:= TRSection():New(oReport,"Itens de Notas Fiscais",{"SD1","SF1","SD2","SF2","SB1","SA1","SA2","SF4"},aOrdem)
	oSection1:SetTotalInLine(.F.)
	oSection1:SetHeaderPage()
	oSection1:SetLineStyle(.F.)
	oSection1:SetReadOnly() //NAO RETIRAR

	oSection1:SetNoFilter("SA1")
	oSection1:SetNoFilter("SA2")
	oSection1:SetNoFilter("SF1")
	oSection1:SetNoFilter("SF2")
	oSection1:SetNoFilter("SD2")
	oSection1:SetNoFilter("SF4")
	oSection1:SetNoFilter("SD2")
	oSection1:SetNoFilter("SB1")

	TRCell():New(oSection1,"D1_FORNECE","SD1","For/Cli"	    ,/*Picture*/,TamSX3("D1_FORNECE")[1],/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection1,"RAZAOSOC"  ,"   ","Rz.Social"	,/*Picture*/,nTamCli-10	,/*lPixel*/,{|| cRazao })
	TRCell():New(oSection1,"D1_COD"    ,"SD1",/*Titulo*/	,/*Picture*/,TamSX3("D1_COD")[1],/*lPixel*/,/*{|| code-block de impressao }*/,/**/,/**/, /**/, /**/, /**/,.F.)
	TRCell():New(oSection1,"B1_DESC"   ,"SB1",/*Titulo*/	,/*Picture*/,25,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection1,"D1_TP"     ,"SD1","TP"			,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection1,"D1_GRUPO"  ,"SD1",/*Titulo*/	,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection1,"D1_UM"     ,"SD1","UM"			,/*Picture*/,3,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection1,"D1_QUANT"  ,"SD1","Qtd."		,/*Picture*/,13,/*lPixel*/,/*{|| code-block de impressao }*/)
	If MV_PAR23 == 1
		TRCell():New(oSection1,"D1_SEGUM"  ,"SD1","Seg. UM"		,/*Picture*/,3,/*lPixel*/,/*{|| code-block de impressao }*/)
		TRCell():New(oSection1,"D1_QTSEGUM","SD1","Qtd. Segum"	,/*Picture*/,13,/*lPixel*/,/*{|| code-block de impressao }*/)
	EndIf
	If lVeiculo
		TRCell():New(oSection1,"D1_CODITE" ,"SD1",RetTitle("B1_CODITE"),/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
	EndIf
	TRCell():New(oSection1,"D1_DOC"    ,"SD1",/*Titulo*/	,/*Picture*/, TamSX3("D1_DOC")[1]+1,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection1,"COD"       ,"SD1",/*Titulo*/	,/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| cCod })  // Célula para controle do código do produto, não será impressa
	oSection1:Cell("COD"):Disable()
	TRCell():New(oSection1,"D1_TIPO"   ,"SD1","T.Doc"		,/*Picture*/,2,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection1,"D1_DTDIGIT","SD1","Dt.Dig."		,/*Picture*/,9,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection1,"D1_LOCAL"  ,"SD1","Amz"			,/*Picture*/,3,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection1,"D1_TES"    ,"SD1","TES"			,/*Picture*/,4,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection1,"D1_CF"     ,"SD1","CFOP"		,/*Picture*/,TamSX3("D1_CF")[1],/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection1,"VALUNIT"   ,"SD1","Vlr. Unit."	,"@E 999,999,999.99999999",15,/*lPixel*/,{|| nValUnit },"RIGHT",,"RIGHT")
	TRCell():New(oSection1,"VALMERC"   ,"SD1","Vlr. Merc"	,"@E 999,999,999.99",13,/*lPixel*/,{|| nValMer  },"RIGHT",,"RIGHT")
	TRCell():New(oSection1,"VALTOTAL"  ,"SD1","Vlr. Total"	,"@E 999,999,999.99",13,/*lPixel*/,{|| nValTot  },"RIGHT",,"RIGHT")
	TRCell():New(oSection1,"VALDESC"   ,"SD1","Vlr. Desc"	,"@E 999,999,999.99",13,/*lPixel*/,{|| nValDesc  },"RIGHT",,"RIGHT")
	TRCell():New(oSection1,"VALCUSTO"  ,"SD1","Custo"		,"@E 999,999,999.99",13,/*lPixel*/,{|| nValCusto },"RIGHT",,"RIGHT")
	If MV_PAR23 == 1
		TRCell():New(oSection1,"D1_CC"	   ,"SD1","CC"		,/*Picture*/,10,/*lPixel*/,/*{|| code-block de impressao }*/)
		TRCell():New(oSection1,"DescCC" ,"","Desc CC"			,,17,/*lPixel*/,{|| (cAliasSD1)->CTT_DESC01 })
	EndIf
	TRCell():New(oSection1,"CodNat" ,"","Cod. Nat."			,,10/*Tamanho*/,/*lPixel*/,{|| RCOM009N((cAliasSD1)->D1_DOC,(cAliasSD1)->D1_SERIE,(cAliasSD1)->D1_FORNECE,(cAliasSD1)->D1_LOJA,1) })
	TRCell():New(oSection1,"DescNat","","Natureza"			,,25/*Tamanho*/,/*lPixel*/,{|| RCOM009N((cAliasSD1)->D1_DOC,(cAliasSD1)->D1_SERIE,(cAliasSD1)->D1_FORNECE,(cAliasSD1)->D1_LOJA,2) })
	TRCell():New(oSection1,"OBSERV" ,"","Observacao"		,,40,/*lPixel*/,{|| (cAliasSD1)->C7_OBS })

	oSection2:= TRSection():New(oSection1,"Itens de Notas Fiscais",{"SD2","SF2","SD1","SF1","SB1","SA1","SA2","SF4"})
	oSection2:SetHeaderPage()
	oSection2:SetTotalInLine(.F.)
	oSection2:SetLineStyle()
	oSection2:SetReadOnly() //NAO RETIRAR

	oSection2:SetNoFilter("SA1")
	oSection2:SetNoFilter("SA2")
	oSection2:SetNoFilter("SF1")
	oSection2:SetNoFilter("SF2")
	oSection2:SetNoFilter("SD2")
	oSection2:SetNoFilter("SF4")
	oSection2:SetNoFilter("SD1")
	oSection2:SetNoFilter("SB1")
	oSection2:SetNoFilter("SC7")

	TRCell():New(oSection2,"D2_DOC"    	,"SD2",/*Titulo*/,/*Picture*/,6			 ,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection2,"D2_COD"    	,"SD2",/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection2,"B1_DESC"   	,"SB1",/*Titulo*/,/*Picture*/,15/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection2,"D2_QUANT"  	,"SD2",/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| SD2->D2_QUANT * -1 })
	TRCell():New(oSection2,"D2_UM"     	,"SD2",/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection2,"PRCVEN"    	,"   ","Vlr. Unit."	 ,/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| nValUnit })
	TRCell():New(oSection2,"D2_IPI"		,"SD2",/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection2,"VALMERC"  	,"SD2","Vlr. Merc","@E 999,999,999.99",12,/*lPixel*/,{|| nValMer * -1 })
	TRCell():New(oSection2,"VALTOTAL"  	,"SD2","Vlr. Total","@E 999,999,999.99",12,/*lPixel*/,{||nValTot * -1 })
	TRCell():New(oSection2,"VALDESC"  	,"SD2","Vlr. Desc","@E 999,999,999.99",12,/*lPixel*/,{|| nValDesc * -1 })
	TRCell():New(oSection2,"D2_PICM"	,"SD2",/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection2,"D2_CLIENTE"	,"SD2",/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection2,"RAZAOSOC"  	,"   ","Rz.Social",/*Picture*/,nTamCli-10 ,/*lPixel*/,{|| cRazao })
	TRCell():New(oSection2,"D2_TIPO"   	,"SD2",/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection2,"D2_TES"    	,"SD2",/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection2,"D2_CF"     	,"SD2",/*Titulo*/,/*Picture*/,TamSX3("D2_CF")[1]+1,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection2,"D2_TP"     	,"SD2",/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection2,"D2_GRUPO"  	,"SD2",/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection2,"D2_EMISSAO"	,"SD2",/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection2,"VALCUSTO"  	,"   ","Custo"	,/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| nValCusto * -1 })
	TRCell():New(oSection2,"D2_LOCAL"  	,"SD2",/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection2,"OBSERV"  	,"SC7",/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)

	oSection2:Cell("PRCVEN"  	):GetFieldInfo("D2_PRCVEN"	)
	oSection2:Cell("VALMERC"	):GetFieldInfo("D2_TOTAL"	)
	oSection2:Cell("VALTOTAL"	):GetFieldInfo("D2_TOTAL"	)
	oSection2:Cell("VALDESC"	):GetFieldInfo("D1_VALDESC"	)
	oSection2:Cell("VALCUSTO"	):GetFieldInfo("D2_CUSTO"	)
	oSection2:Cell("D2_DOC"		):GetFieldInfo("D1_DOC"		)
	oSection2:Cell("D2_CLIENTE"	):GetFieldInfo("D1_FORNECE"	)
	oSection2:Cell("D2_TIPO"	):GetFieldInfo("D1_TIPO"	)
	oSection2:Cell("D2_TES"		):GetFieldInfo("D1_TES"		)
	oSection2:Cell("D2_CF"		):GetFieldInfo("D1_CF"		)
	oSection2:Cell("D2_TP"		):GetFieldInfo("D1_TP"		)
	oSection2:Cell("D2_GRUPO"	):GetFieldInfo("D1_GRUPO"	)
	oSection2:Cell("D2_EMISSAO"	):GetFieldInfo("D1_DTDIGIT"	)
	oSection2:Cell("OBSERV"	    ):GetFieldInfo("C7_OBS"	)

	oSection2:Cell("D2_DOC"		):HideHeader()
	oSection2:Cell("D2_COD"		):HideHeader()
	oSection2:Cell("B1_DESC"	):HideHeader()
	oSection2:Cell("D2_QUANT"	):HideHeader()
	oSection2:Cell("D2_UM"		):HideHeader()
	oSection2:Cell("PRCVEN"		):HideHeader()
	oSection2:Cell("D2_IPI"		):HideHeader()
	oSection2:Cell("VALMERC"	):HideHeader()
	oSection2:Cell("VALTOTAL"	):HideHeader()
	oSection2:Cell("VALDESC"	):HideHeader()
	oSection2:Cell("D2_PICM"	):HideHeader()
	oSection2:Cell("D2_CLIENTE"	):HideHeader()
	oSection2:Cell("RAZAOSOC"	):HideHeader()
	oSection2:Cell("D2_TIPO"	):HideHeader()
	oSection2:Cell("D2_TES"		):HideHeader()
	oSection2:Cell("D2_CF"		):HideHeader()
	oSection2:Cell("D2_TP"		):HideHeader()
	oSection2:Cell("D2_GRUPO"	):HideHeader()
	oSection2:Cell("D2_EMISSAO"	):HideHeader()
	oSection2:Cell("VALCUSTO"	):HideHeader()
	oSection2:Cell("D2_LOCAL"	):HideHeader()
	oSection2:Cell("OBSERV" 	):HideHeader()

Return(oReport)

/*
===============================================================================================================================
Programa----------: RCOM009R
Autor-------------: Lucas Crevilari
Data da Criacao---: 10/09/2014
Descrição---------: Emissao da relacao de Compras
Parametros--------: ExpO1: Objeto Report do Relatório
Retorno-----------:
===============================================================================================================================
*/
Static Function RCOM009R(oReport,aOrdem,cAliasSD1)

	Local oSection1  := oReport:Section(1)
	Local oSection2  := oReport:Section(1):Section(1)
	Local nOrdem     := oReport:Section(1):GetOrder()
	Local aRecno     := {}
	Local cTipo1	 := ""
	Local cTipo2	 := ""
	Local cFilUsrSD1 := ""
	Local cCondSD2   := ""
	Local cArqTrbSD2 := ""
	Local nNewIndSD2 := 0
	Local nDecs      := Msdecimais(MV_PAR13) //casas decimais utilizadas na moeda da impressao
	Local oBreak
	Local oBreak1
	Local oBreak2
	Local oBreak3
	Local lQuery     := .F.
	Local lMoeda     := .T.
	Local lPar15	 := .F.
	Local cSelect   := ""
	Local cSelect1  := ""
	Local cOrder    := ""
	Local cWhereSB1 := ""
	Local cWhereSF1 := ""
	Local cWhereSF4 := "%%"
	Local cWhereCF	:= "%%"
	Local cWhereEST := "%%"
	Local cFrom     := "%%"
	Local cAliasSF4 := cAliasSD1
	Local aStrucSD1 := SD1->(dbStruct())
	Local cName		:= ""
	Local nX        := 0

	Private cRazao   := ""
	Private lVeiculo := Upper(GetMV("MV_VEICULO")) == "S"
	Private nValUnit := 0
	Private nValMer  := 0
	Private nValTot  := 0
	Private nValCusto:= 0
	Private	nImpInc  :=	0
	Private	nImpNoInc:=	0
	Private	nValDesc:=	0
	Private cCod	 := ""

	If oReport:nDevice == 1
		oSection1:Cell("OBSERV"):Disable()
		oSection1:Cell("VALTOTAL"):Disable()
		oSection1:Cell("VALDESC"):Disable()
	EndIf	

	//=====================================================
	// Adiciona a ordem escolhida ao titulo do relatorio  |
	//=====================================================
	oReport:SetTitle(oReport:Title() + " ("+AllTrim(aOrdem[nOrdem])+") ")

	DBSelectArea("SD1")
	//=====================================================
	// Filtragem do relatório                             |
	//=====================================================

	MakeSqlExpr(oReport:uParam)

	oReport:Section(1):BeginQuery()

	lQuery := .T.

	cSelect := "%"
	cSelect += ", " + "D1_VALIMP1,D1_VALIMP2,D1_VALIMP3,D1_VALIMP4"

	If lVeiculo
		cSelect   += ",B1_CODITE "
		cWhereSB1 := "%"
		cWhereSB1 += " B1_CODITE >= '" + MV_PAR01 + "'"
		cWhereSB1 += " AND B1_CODITE <= '" + MV_PAR02 + "'"
		cWhereSB1 += "%"
	Else
		cWhereSB1 := "%"
		cWhereSB1 += " SD1.D1_COD >= '" + MV_PAR01 + "'"
		cWhereSB1 += " AND SD1.D1_COD <= '" + MV_PAR02 + "'"
		cWhereSB1 += " AND SD1.D1_GRUPO >= '" + MV_PAR03 + "'"
		cWhereSB1 += " AND SD1.D1_GRUPO <= '" + MV_PAR04 + "'"
		cWhereSB1 += "%"
	EndIf

	//=====================================================================
	// Esta rotina foi escrita para adicionar no select os campos         |
	// usados no filtro do usuario quando houver. A rotina acrescenta     |
	// somente os campos que forem adicionados ao filtro testando         |
	// se os mesmo já existem no select ou se forem definidos novamente   |
	// pelo o usuario no filtro. Esta rotina acrescenta o minimo possivel |
	// de campos no select pois pelo fato da tabela SD1 ter muitos campos |
	// e a query ter UNION, ao adicionar todos os campos do SD1 podera    |
	// derrubar o TOP CONNECT e abortar o sistema.                        |
	//=====================================================================
	cSelect1 := "D1_FILIAL, D1_CC, D1_DOC, D1_SERIE, D1_FORNECE, D1_LOJA, D1_DTDIGIT, D1_COD,   D1_QUANT, D1_VUNIT, D1_VALDESC,"
	cSelect1 += "D1_TOTAL,  D1_TES, D1_CF, D1_IPI,   D1_PICM,    D1_TIPO, D1_TP,      D1_GRUPO, D1_CUSTO, D1_LOCAL, D1_QTDEDEV, D1_ITEM, D1_UM,"
	cFilUsrSD1:= oSection1:GetAdvplExp()
	If !Empty(cFilUsrSD1)
		For nX := 1 To SD1->(FCount())
			cName := SD1->(FieldName(nX))
			If AllTrim( cName ) $ cFilUsrSD1
				If aStrucSD1[nX,2] <> "M"
					If !cName $ cSelect .And. !cName $ cSelect1
						cSelect += ","+cName
					EndIf
				EndIf
			EndIf
		Next
	EndIf

	If MV_PAR15 == 1
		cSelect += ", F4_AGREG "
		cFrom := "%"
		cFrom += "," + RetSqlName("SF4") + " SF4 "
		cFrom += "%"
		
		cWhereSF4 := "%"
		cWhereSF4 += " SF4.F4_FILIAL ='" + xFilial("SF4") + "'"
		cWhereSF4 += " AND SF4.F4_CODIGO = SD1.D1_TES"
		cWhereSF4 += " AND SF4.D_E_L_E_T_ = ' ' AND "
		cWhereSF4 += "%"
		
		lPar15 := .T.
	EndIf

	//busca CFOPS de acordo com parametro definido por usuario	
	MV_PAR17 := AllTrim(MV_PAR17)
	If RIGHT(MV_PAR17,1) == ";"                       
		MV_PAR17 := SubStr(MV_PAR17,1,Len(MV_PAR17)-1) //retira ultimo ';' caso tenha
	EndIf
	If !Empty(MV_PAR17)
		cWhereCF   := "%"
		cWhereCF   += " SD1.D1_CF IN " + FormatIn(MV_PAR17,";")+" AND "
		cWhereCF   += "%"
	EndIf


	If MV_PAR22 == 1 .And. lPar15
		cWhereEST := "% SF4.F4_ESTOQUE = 'S' AND %"
	ElseIf MV_PAR22 == 2 .And. !lPar15
		cFrom := "%"
		cFrom += "," + RetSqlName("SF4") + " SF4 "
		cFrom += "%"
		
		cWhereEST := "%"
		cWhereEST += " SF4.F4_FILIAL ='" + xFilial("SF4") + "'"
		cWhereEST += " AND SF4.F4_CODIGO = SD1.D1_TES"
		cWhereEST += " AND SF4.F4_ESTOQUE = 'N' "
		cWhereEST += " AND SF4.D_E_L_E_T_ = ' ' AND "
		cWhereEST += "%"
	EndIf

	If (MV_PAR16 == 1)
		cTipo1 := "D','B"
		cTipo2 := cTipo1
	Else
		cTipo1 := "B"
		cTipo2 := "D','B"
	EndIf

	cSelect += "%"

	cWhereSF1 := "%"
	cWhereSF1 += "NOT ("+IsRemito(3,'SF1.F1_TIPODOC')+ ") AND "
	cWhereSF1 += "%"

	If nOrdem == 1
		cOrder := "% D1_FILIAL, D1_FORNECE, D1_LOJA,    D1_DOC,   D1_SERIE,  D1_ITEM %"
	ElseIf nOrdem == 2
		cOrder := "% D1_FILIAL, D1_DTDIGIT, D1_FORNECE, D1_LOJA,   D1_DOC,   D1_SERIE, D1_ITEM %"
	ElseIf nOrdem == 3 .And. lVeiculo
		cOrder := "% D1_FILIAL, D1_TP,	    D1_GRUPO,   B1_CODITE, D1_DTDIGIT %"
	ElseIf nOrdem == 3 .And. !lVeiculo
		cOrder := "% D1_FILIAL, D1_TP,		D1_GRUPO,   D1_COD,    D1_DTDIGIT %"
	ElseIf nOrdem == 4 .And. lVeiculo
		cOrder := "% D1_FILIAL, D1_GRUPO,   D1_CODITE,  D1_DTDIGIT %"
	ElseIf nOrdem == 4 .And. !lVeiculo
		cOrder := "% D1_FILIAL, D1_GRUPO,   D1_COD,     D1_DTDIGIT %"
	EndIf

	BeginSql Alias cAliasSD1

		SELECT D1_FILIAL, D1_DOC, D1_CC, D1_SERIE, D1_FORNECE, D1_LOJA, D1_EMISSAO, D1_DTDIGIT, D1_COD, D1_QUANT, D1_VUNIT,
		D1_TOTAL, D1_TES, D1_CF, D1_IPI, D1_PICM, D1_TIPO, D1_TP, D1_GRUPO, D1_CUSTO, D1_LOCAL, D1_QTDEDEV, D1_ITEM, D1_UM,
		F1_MOEDA, F1_TXMOEDA, F1_DTDIGIT, B1_DESC, B1_UM, A1_NOME RAZAO, A1_NREDUZ RAZAORED, SD1.R_E_C_N_O_ SD1RECNO,
		B1_CODITE D1_CODITE,  'C' TIPO, D1_SEGUM, D1_QTSEGUM, D1_VALDESC , CTT_DESC01 , C7_OBS
		%Exp:cSelect%
		
		FROM %Table:SF1% SF1 , %Table:SD1% SD1 , %Table:SB1% SB1 , %Table:SA1% SA1, %Table:CTT% CTT, %Table:SC7% SC7  %Exp:cFrom%
		
		WHERE SF1.F1_FILIAL   = %xFilial:SF1%   AND
		%Exp:cWhereSF1%
		SF1.%NotDel%                      AND
		SD1.D1_FILIAL   =  %xFilial:SD1%  AND
		SD1.D1_DOC      =  SF1.F1_DOC     AND
		SD1.D1_SERIE    =  SF1.F1_SERIE   AND
		SD1.D1_FORNECE  =  SF1.F1_FORNECE AND
		SD1.D1_LOJA     =  SF1.F1_LOJA    AND
		SD1.D1_TIPO  IN (%Exp:cTipo1%)    AND
		CTT.CTT_FILIAL (+) = %xFilial:CTT%  AND
		CTT.CTT_CUSTO  (+) = SD1.D1_CC 	    AND
		SC7.C7_FILIAL (+)  =  %xFilial:SC7% AND
		SC7.C7_NUM    (+)  = SD1.D1_PEDIDO  AND    
		SC7.C7_ITEM   (+)  = SD1.D1_ITEMPC  AND
		SD1.%NotDel%                      AND
		SB1.B1_FILIAL   =  %xFilial:SB1%  AND
		SB1.B1_COD      =  SD1.D1_COD     AND
		SB1.%NotDel%                      AND
		SA1.A1_FILIAL   =  %xFilial:SA1%  AND
		SA1.A1_COD      =  SD1.D1_FORNECE AND
		SA1.A1_LOJA     =  SD1.D1_LOJA    AND
		SA1.%NotDel%                      AND
		%Exp:cWhereSF4%
		SD1.D1_EMISSAO >= %Exp:DToS(MV_PAR05)% AND
		SD1.D1_EMISSAO <= %Exp:DToS(MV_PAR06)% AND
		SD1.D1_DTDIGIT >= %Exp:DToS(MV_PAR07)% AND
		SD1.D1_DTDIGIT <= %Exp:DToS(MV_PAR08)% AND	
		%Exp:cWhereEST%
		SD1.D1_FORNECE >= %Exp:MV_PAR09% AND
		SD1.D1_FORNECE <= %Exp:MV_PAR10% AND
		%Exp:cWhereCF%	
		SD1.D1_CC 	 >= %Exp:MV_PAR18% AND  	
		SD1.D1_CC 	 <= %Exp:MV_PAR19% AND  
		%Exp:cWhereSB1%
		
		UNION
		
		SELECT D1_FILIAL, D1_DOC, D1_CC, D1_SERIE, D1_FORNECE, D1_LOJA, D1_EMISSAO, D1_DTDIGIT, D1_COD, D1_QUANT, D1_VUNIT,
		D1_TOTAL, D1_TES, D1_CF, D1_IPI, D1_PICM, D1_TIPO, D1_TP, D1_GRUPO, D1_CUSTO, D1_LOCAL, D1_QTDEDEV, D1_ITEM, D1_UM,
		F1_MOEDA, F1_TXMOEDA, F1_DTDIGIT, B1_DESC, B1_UM, A2_NOME RAZAO, A2_NREDUZ RAZAORED, SD1.R_E_C_N_O_ SD1RECNO,
		B1_CODITE  D1_CODITE,  'F' TIPO, D1_SEGUM, D1_QTSEGUM, D1_VALDESC , CTT_DESC01, C7_OBS
		%Exp:cSelect%
		
		FROM %Table:SF1% SF1 , %Table:SD1% SD1 , %Table:SB1% SB1 , %Table:SA2% SA2,  %Table:SE2% SE2, %Table:CTT% CTT, %Table:SC7% SC7%Exp:cFrom%
		
		WHERE SF1.F1_FILIAL   = %xFilial:SF1%   AND
		%Exp:cWhereSF1%
		SF1.%NotDel%                      AND
		SD1.D1_FILIAL   =  %xFilial:SD1%  AND
		SD1.D1_DOC      =  SF1.F1_DOC     AND
		SD1.D1_SERIE    =  SF1.F1_SERIE   AND
		SD1.D1_FORNECE  =  SF1.F1_FORNECE AND
		SD1.D1_LOJA     =  SF1.F1_LOJA    AND
		SD1.D1_TIPO NOT IN (%Exp:cTipo2%) AND
		CTT.CTT_FILIAL (+) = %xFilial:CTT%  AND
		CTT.CTT_CUSTO  (+) = SD1.D1_CC 	    AND
		SC7.C7_FILIAL (+)  =  %xFilial:SC7% AND
		SC7.C7_NUM    (+)  = SD1.D1_PEDIDO  AND    
		SC7.C7_ITEM   (+)  = SD1.D1_ITEMPC  AND
		SD1.%NotDel%                      AND
		SB1.B1_FILIAL   =  %xFilial:SB1%  AND
		SB1.B1_COD      =  SD1.D1_COD     AND
		SB1.%NotDel%                      AND
		SA2.A2_FILIAL   =  %xFilial:SA2%  AND
		SA2.A2_COD      =  SD1.D1_FORNECE AND
		SA2.A2_LOJA     =  SD1.D1_LOJA    AND
		SA2.%NotDel%                      AND
		SE2.E2_FILIAL (+)  = SD1.D1_FILIAL  AND
		SE2.E2_NUM    (+)  = SD1.D1_DOC     AND
		SE2.E2_PREFIXO (+) = SD1.D1_SERIE   AND
		SE2.E2_FORNECE (+) = SD1.D1_FORNECE AND
		SE2.E2_LOJA   (+)  = SD1.D1_LOJA    AND
		SE2.D_E_L_E_T_ (+) <> '*'           AND	
		%Exp:cWhereSF4%
		SD1.D1_EMISSAO >= %Exp:DToS(MV_PAR05)% AND
		SD1.D1_EMISSAO <= %Exp:DToS(MV_PAR06)% AND   
		SD1.D1_DTDIGIT >= %Exp:DToS(MV_PAR07)% AND
		SD1.D1_DTDIGIT <= %Exp:DToS(MV_PAR08)% AND	
		SD1.D1_FORNECE >= %Exp:MV_PAR09% AND
		SD1.D1_FORNECE <= %Exp:MV_PAR10% AND
		%Exp:cWhereEST%
		SD1.D1_CC 	 >= %Exp:MV_PAR18% AND
		SD1.D1_CC 	 <= %Exp:MV_PAR19% AND
		%Exp:cWhereCF%
		SE2.E2_NATUREZ (+)  >= %Exp:MV_PAR20% AND
		SE2.E2_NATUREZ (+) <= %Exp:MV_PAR21% AND                                                   
		%Exp:cWhereSB1%  
		
		ORDER BY %Exp:cOrder%
		
	EndSql

	oReport:Section(1):EndQuery(/*Array com os parametros do tipo Range*/)

	//====================================================
	// Monta IndRegua caso liste NFs de devolucao        |
	//====================================================
	If MV_PAR11 == 1
		cArqTrbSD2:= CriaTrab("",.F.)
		//==============================================================
		// Verifica data caso FILTRE NFs de devolucao fora do periodo  |
		//==============================================================
		If MV_PAR12 == 1
			cCondSD2	:=	( "D2_FILIAL == '" + xFilial("SD2") + "'" )
			cCondSD2	+=	( " .And. DToS(D2_EMISSAO)>='" + DToS(MV_PAR05) + "'" )
			cCondSD2	+=	( " .And. DToS(D2_EMISSAO)<='" + DToS(MV_PAR06) + "'" )
		Else
			cCondSD2	:=	( "D2_FILIAL == '" + xFilial("SD2") + "'")
		EndIf
		cCondSD2 +=	( ".And. !(" + IsRemito(2,'SD2->D2_TIPODOC') + ")" )
		
		DBSelectArea("SD2")
		IndRegua("SD2",cArqTrbSD2,"D2_FILIAL+D2_COD+D2_NFORI+D2_ITEMORI+D2_SERIORI+D2_CLIENTE+D2_LOJA",,cCondSD2,"Selecionando Registros...")
		nNewIndSD2 := RetIndex("SD2")
		DBSelectArea("SD2")
		#IFNDEF TOP
			dbSetIndex(cArqTrbSD2+OrdBagExt())
		#EndIf
		DBSetOrder(nNewIndSD2+1)
		DBGoTop()
	EndIf

	cFilUsrSD1:= oSection1:GetAdvplExp()

	If nOrdem == 1
		//==============================================================
		// Definicao das quebras e totalizadores que serao Impressos.  |
		//==============================================================
		oBreak1 := TRBreak():New(oSection1,oSection1:Cell("D1_DOC")    ,"TOTAL NOTA FISCAL --> ",.F.,"NFE")
		oBreak2 := TRBreak():New(oSection1,oSection1:Cell("D1_FORNECE"),"TOTAL FORNECEDOR  --> ",.F.)
		
		//============================================================================================================================
		// A ordem de chamada de cada TRFunction nao deve ser alterada, pois representa a ordem da celula gerada para planilha XML   |
		//============================================================================================================================
		TRFunction():New(oSection1:Cell("D1_QUANT"),NIL,"SUM",oBreak1,,/*cPicture*/,/*uFormula*/,.F.,.F. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		TRFunction():New(oSection1:Cell("VALMERC"),NIL,"SUM",oBreak1,,/*cPicture*/,/*uFormula*/,.F.,.F. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		TRFunction():New(oSection1:Cell("VALTOTAL"),NIL,"SUM",oBreak1,,/*cPicture*/,/*uFormula*/,.F.,.F. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		TRFunction():New(oSection1:Cell("VALDESC"),NIL,"SUM",oBreak1,,/*cPicture*/,/*uFormula*/,.F.,.F. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		TRFunction():New(oSection1:Cell("VALCUSTO"),NIL,"SUM",oBreak1,,/*cPicture*/,/*uFormula*/,.F.,.F. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		
		//================================================================
		// Dispara a funcao RCOM009P() para a impressao da oSection2   |
		// apartir do Break NFE abaixo apos a impressao do totalizador.  |
		//================================================================
		oBreak:= oReport:Section(1):GetBreak("NFE")
		oBreak:OnPrintTotal({|| RCOM009P(aRecno,lQuery,oReport,oSection1,oSection2,cAliasSD1,(cAliasSD1)->SD1RECNO) })
		
		//================================================================
		// Impressao dos totalizadores SD1 (-) SD2 Devolucoes.           |
		//================================================================
		TRFunction():New(oSection1:Cell("D1_QUANT"),NIL,"ONPRINT",oBreak2,,/*cPicture*/,{|lSection,lReport,lPage| If( !lReport, oSection1:GetFunction("SD1QTD2"):GetValue() + oSection2:GetFunction("SD2QTD2"):GetValue() , oSection1:GetFunction("SD1QTD2"):ReportValue() + oSection2:GetFunction("SD2QTD2"):ReportValue() ) },.F.,.T. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		TRFunction():New(oSection1:Cell("VALMERC"),NIL,"ONPRINT",oBreak2,,/*cPicture*/,{|lSection,lReport,lPage| If( !lReport, oSection1:GetFunction("SD1TOT2"):GetValue() + oSection2:GetFunction("SD2TOT2"):GetValue() , oSection1:GetFunction("SD1TOT2"):ReportValue() + oSection2:GetFunction("SD2TOT2"):ReportValue() ) },.F.,.T. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		TRFunction():New(oSection1:Cell("VALTOTAL"),NIL,"ONPRINT",oBreak2,,/*cPicture*/,{|lSection,lReport,lPage| If( !lReport, oSection1:GetFunction("SD1TOT2"):GetValue() + oSection2:GetFunction("SD2TOT2"):GetValue() , oSection1:GetFunction("SD1TOT2"):ReportValue() + oSection2:GetFunction("SD2TOT2"):ReportValue() ) },.F.,.T. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		TRFunction():New(oSection1:Cell("VALDESC"),NIL,"ONPRINT",oBreak2,,/*cPicture*/,{|lSection,lReport,lPage| If( !lReport, oSection1:GetFunction("SD1TOT2"):GetValue() + oSection2:GetFunction("SD2TOT2"):GetValue() , oSection1:GetFunction("SD1TOT2"):ReportValue() + oSection2:GetFunction("SD2TOT2"):ReportValue() ) },.F.,.T. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		TRFunction():New(oSection1:Cell("VALCUSTO"),NIL,"ONPRINT",oBreak2,,/*cPicture*/,{|lSection,lReport,lPage| If( !lReport, oSection1:GetFunction("SD1CUS2"):GetValue() + oSection2:GetFunction("SD2CUS2"):GetValue() , oSection1:GetFunction("SD1CUS2"):ReportValue() + oSection2:GetFunction("SD2CUS2"):ReportValue() ) },.F.,.T. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		
	ElseIf nOrdem == 2
		//================================================================
		// Definicao das quebras e totalizadores que serao Impressos.    |
		//================================================================
		oBreak1 := TRBreak():New(oSection1,oSection1:Cell("D1_DOC")    ,"TOTAL NOTA FISCAL --> ",.F.,"NFE")
		oBreak2 := TRBreak():New(oSection1,oSection1:Cell("D1_FORNECE"),"TOTAL FORNECEDOR  --> ",.F.)
		oBreak3 := TRBreak():New(oSection1,oSection1:Cell("D1_DTDIGIT"),"TOT. NA DATA ",.F.)
		
		//===========================================================================================================================
		// A ordem de chamada de cada TRFunction nao deve ser alterada, pois representa a ordem da celula gerada para planilha XML  |
		//===========================================================================================================================
		TRFunction():New(oSection1:Cell("D1_QUANT"),NIL,"SUM",oBreak1,,/*cPicture*/,/*uFormula*/,.F.,.F. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		TRFunction():New(oSection1:Cell("VALMERC"),NIL,"SUM",oBreak1,,/*cPicture*/,/*uFormula*/,.F.,.F. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		TRFunction():New(oSection1:Cell("VALTOTAL"),NIL,"SUM",oBreak1,,/*cPicture*/,/*uFormula*/,.F.,.F. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		TRFunction():New(oSection1:Cell("VALDESC"),NIL,"SUM",oBreak1,,/*cPicture*/,/*uFormula*/,.F.,.F. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		TRFunction():New(oSection1:Cell("VALCUSTO"),NIL,"SUM",oBreak1,,/*cPicture*/,/*uFormula*/,.F.,.F. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		
		//===============================================================
		// Dispara a funcao RCOM009P() para a impressao da oSection2  |
		// apartir do Break NFE abaixo apos a impressao do totalizador. |
		//===============================================================
		oBreak:= oReport:Section(1):GetBreak("NFE")
		oBreak:OnPrintTotal({|| RCOM009P(aRecno,lQuery,oReport,oSection1,oSection2,cAliasSD1,(cAliasSD1)->SD1RECNO) })
		
		//===============================================================
		// Impressao dos totalizadores SD1 (-) SD2 Devolucoes.          |
		//===============================================================
		TRFunction():New(oSection1:Cell("D1_QUANT"),NIL,"ONPRINT",oBreak2,,/*cPicture*/,{|| oSection1:GetFunction("SD1QTD2"):GetValue() + oSection2:GetFunction("SD2QTD2"):GetValue() },.F.,.F. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		TRFunction():New(oSection1:Cell("VALMERC"),NIL,"ONPRINT",oBreak2,,/*cPicture*/,{|| oSection1:GetFunction("SD1TOT2"):GetValue() + oSection2:GetFunction("SD2TOT2"):GetValue() },.F.,.F. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		TRFunction():New(oSection1:Cell("VALTOTAL"),NIL,"ONPRINT",oBreak2,,/*cPicture*/,{|| oSection1:GetFunction("SD1TOT2"):GetValue() + oSection2:GetFunction("SD2TOT2"):GetValue() },.F.,.F. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		TRFunction():New(oSection1:Cell("VALDESC"),NIL,"ONPRINT",oBreak2,,/*cPicture*/,{|| oSection1:GetFunction("SD1TOT2"):GetValue() + oSection2:GetFunction("SD2TOT2"):GetValue() },.F.,.F. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		TRFunction():New(oSection1:Cell("VALCUSTO"),NIL,"ONPRINT",oBreak2,,/*cPicture*/,{|| oSection1:GetFunction("SD1CUS2"):GetValue() + oSection2:GetFunction("SD2CUS2"):GetValue() },.F.,.F. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		TRFunction():New(oSection1:Cell("D1_QUANT"),NIL,"ONPRINT",oBreak3,,/*cPicture*/,{|lSection,lReport,lPage| If( !lReport, oSection1:GetFunction("SD1QTD3"):GetValue() + oSection2:GetFunction("SD2QTD3"):GetValue() , oSection1:GetFunction("SD1QTD3"):ReportValue() + oSection2:GetFunction("SD2QTD3"):ReportValue() ) },.F.,.T. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		TRFunction():New(oSection1:Cell("VALMERC"),NIL,"ONPRINT",oBreak3,,/*cPicture*/,{|lSection,lReport,lPage| If( !lReport, oSection1:GetFunction("SD1TOT3"):GetValue() + oSection2:GetFunction("SD2TOT3"):GetValue() , oSection1:GetFunction("SD1TOT3"):ReportValue() + oSection2:GetFunction("SD2TOT3"):ReportValue() ) },.F.,.T. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		TRFunction():New(oSection1:Cell("VALTOTAL"),NIL,"ONPRINT",oBreak3,,/*cPicture*/,{|lSection,lReport,lPage| If( !lReport, oSection1:GetFunction("SD1TOT3"):GetValue() + oSection2:GetFunction("SD2TOT3"):GetValue() , oSection1:GetFunction("SD1TOT3"):ReportValue() + oSection2:GetFunction("SD2TOT3"):ReportValue() ) },.F.,.T. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		TRFunction():New(oSection1:Cell("VALDESC"),NIL,"ONPRINT",oBreak3,,/*cPicture*/,{|lSection,lReport,lPage| If( !lReport, oSection1:GetFunction("SD1TOT3"):GetValue() + oSection2:GetFunction("SD2TOT3"):GetValue() , oSection1:GetFunction("SD1TOT3"):ReportValue() + oSection2:GetFunction("SD2TOT3"):ReportValue() ) },.F.,.T. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		TRFunction():New(oSection1:Cell("VALCUSTO"),NIL,"ONPRINT",oBreak3,,/*cPicture*/,{|lSection,lReport,lPage| If( !lReport, oSection1:GetFunction("SD1CUS3"):GetValue() + oSection2:GetFunction("SD2CUS3"):GetValue() , oSection1:GetFunction("SD1CUS3"):ReportValue() + oSection2:GetFunction("SD2CUS3"):ReportValue() ) },.F.,.T. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		
	ElseIf nOrdem == 3
		//===============================================================
		// Definicao das quebras e totalizadores que serao Impressos.   |
		//===============================================================
		oBreak1 := TRBreak():New(oSection1,oSection1:Cell("COD"),"TOTAL PRODUTO     --> ",.F.,"PROD")
		oBreak2 := TRBreak():New(oSection1,oSection1:Cell("D1_GRUPO")  ,"TOTAL GRUPO ",.F.)
		oBreak3 := TRBreak():New(oSection1,oSection1:Cell("D1_TP")     ,"TOTAL TIPO  ",.F.)
		
		//==============================================================
		// Dispara a funcao RCOM009P() para a impressao da oSection2 |
		// apartir do Break NFE abaixo apos a impressao do totalizador.|
		//==============================================================
		oBreak:= oReport:Section(1):GetBreak("PROD")
		oBreak:OnBreak({|| RCOM009P(aRecno,lQuery,oReport,oSection1,oSection2,cAliasSD1,(cAliasSD1)->SD1RECNO) })
		
		//===============================================================
		// Impressao dos totalizadores SD1 (-) SD2 Devolucoes.          |
		//===============================================================
		//===========================================================================================================================
		// A ordem de chamada de cada TRFunction nao deve ser alterada, pois representa a ordem da celula gerada para planilha XML  |
		//===========================================================================================================================
		TRFunction():New(oSection1:Cell("D1_QUANT"),NIL,"ONPRINT",oBreak1,,/*cPicture*/,{|| oSection1:GetFunction("SD1QTD1"):GetValue() + oSection2:GetFunction("SD2QTD1"):GetValue() },.F.,.F. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		TRFunction():New(oSection1:Cell("VALMERC"),NIL,"ONPRINT",oBreak1,,/*cPicture*/,{|| oSection1:GetFunction("SD1TOT1"):GetValue() + oSection2:GetFunction("SD2TOT1"):GetValue() },.F.,.F. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		TRFunction():New(oSection1:Cell("VALTOTAL"),NIL,"ONPRINT",oBreak1,,/*cPicture*/,{|| oSection1:GetFunction("SD1TOT1"):GetValue() + oSection2:GetFunction("SD2TOT1"):GetValue() },.F.,.F. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		TRFunction():New(oSection1:Cell("VALDESC"),NIL,"ONPRINT",oBreak1,,/*cPicture*/,{|| oSection1:GetFunction("SD1TOT1"):GetValue() + oSection2:GetFunction("SD2TOT1"):GetValue() },.F.,.F. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		TRFunction():New(oSection1:Cell("VALCUSTO"),NIL,"ONPRINT",oBreak1,,/*cPicture*/,{|| oSection1:GetFunction("SD1CUS1"):GetValue() + oSection2:GetFunction("SD2CUS1"):GetValue() },.F.,.F. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		TRFunction():New(oSection1:Cell("D1_QUANT"),NIL,"ONPRINT",oBreak2,,/*cPicture*/,{|| oSection1:GetFunction("SD1QTD2"):GetValue() + oSection2:GetFunction("SD2QTD2"):GetValue() },.F.,.F. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		TRFunction():New(oSection1:Cell("VALMERC"),NIL,"ONPRINT",oBreak2,,/*cPicture*/,{|| oSection1:GetFunction("SD1TOT2"):GetValue() + oSection2:GetFunction("SD2TOT2"):GetValue() },.F.,.F. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		TRFunction():New(oSection1:Cell("VALTOTAL"),NIL,"ONPRINT",oBreak2,,/*cPicture*/,{|| oSection1:GetFunction("SD1TOT2"):GetValue() + oSection2:GetFunction("SD2TOT2"):GetValue() },.F.,.F. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		TRFunction():New(oSection1:Cell("VALDESC"),NIL,"ONPRINT",oBreak2,,/*cPicture*/,{|| oSection1:GetFunction("SD1TOT2"):GetValue() + oSection2:GetFunction("SD2TOT2"):GetValue() },.F.,.F. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		TRFunction():New(oSection1:Cell("VALCUSTO"),NIL,"ONPRINT",oBreak2,,/*cPicture*/,{|| oSection1:GetFunction("SD1CUS2"):GetValue() + oSection2:GetFunction("SD2CUS2"):GetValue() },.F.,.F. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		TRFunction():New(oSection1:Cell("D1_QUANT"),NIL,"ONPRINT",oBreak3,,/*cPicture*/,{|lSection,lReport,lPage| If( !lReport, oSection1:GetFunction("SD1QTD3"):GetValue() + oSection2:GetFunction("SD2QTD3"):GetValue() , oSection1:GetFunction("SD1QTD3"):ReportValue() + oSection2:GetFunction("SD2QTD3"):ReportValue() ) },.F.,.T. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		TRFunction():New(oSection1:Cell("VALMERC"),NIL,"ONPRINT",oBreak3,,/*cPicture*/,{|lSection,lReport,lPage| If( !lReport, oSection1:GetFunction("SD1TOT3"):GetValue() + oSection2:GetFunction("SD2TOT3"):GetValue() , oSection1:GetFunction("SD1TOT3"):ReportValue() + oSection2:GetFunction("SD2TOT3"):ReportValue() ) },.F.,.T. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		TRFunction():New(oSection1:Cell("VALTOTAL"),NIL,"ONPRINT",oBreak3,,/*cPicture*/,{|lSection,lReport,lPage| If( !lReport, oSection1:GetFunction("SD1TOT3"):GetValue() + oSection2:GetFunction("SD2TOT3"):GetValue() , oSection1:GetFunction("SD1TOT3"):ReportValue() + oSection2:GetFunction("SD2TOT3"):ReportValue() ) },.F.,.T. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		TRFunction():New(oSection1:Cell("VALDESC"),NIL,"ONPRINT",oBreak3,,/*cPicture*/,{|lSection,lReport,lPage| If( !lReport, oSection1:GetFunction("SD1TOT3"):GetValue() + oSection2:GetFunction("SD2TOT3"):GetValue() , oSection1:GetFunction("SD1TOT3"):ReportValue() + oSection2:GetFunction("SD2TOT3"):ReportValue() ) },.F.,.T. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		TRFunction():New(oSection1:Cell("VALCUSTO"),NIL,"ONPRINT",oBreak3,,/*cPicture*/,{|lSection,lReport,lPage| If( !lReport, oSection1:GetFunction("SD1CUS3"):GetValue() + oSection2:GetFunction("SD2CUS3"):GetValue() , oSection1:GetFunction("SD1CUS3"):ReportValue() + oSection2:GetFunction("SD2CUS3"):ReportValue() ) },.F.,.T. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		
	ElseIf nOrdem == 4
		//==============================================================
		// Definicao das quebras e totalizadores que serao Impressos.  |
		//==============================================================
		oBreak1 := TRBreak():New(oSection1,oSection1:Cell("COD"),"TOTAL PRODUTO     --> ",.F.,"PROD")
		oBreak2 := TRBreak():New(oSection1,oSection1:Cell("D1_GRUPO")  ,"TOTAL GRUPO ",.F.)
		
		//===============================================================
		// Dispara a funcao RCOM009P() para a impressao da oSection2  |
		// apartir do Break NFE abaixo apos a impressao do totalizador. |
		//===============================================================
		oBreak:= oReport:Section(1):GetBreak("PROD")
		oBreak:OnBreak({|| RCOM009P(aRecno,lQuery,oReport,oSection1,oSection2,cAliasSD1,(cAliasSD1)->SD1RECNO) })
		
		//===============================================================
		// Impressao dos totalizadores SD1 (-) SD2 Devolucoes.          |
		//===============================================================
		//===========================================================================================================================
		// A ordem de chamada de cada TRFunction nao deve ser alterada, pois representa a ordem da celula gerada para planilha XML  |
		//===========================================================================================================================
		TRFunction():New(oSection1:Cell("D1_QUANT"),NIL,"ONPRINT",oBreak1,,/*cPicture*/,{|| oSection1:GetFunction("SD1QTD1"):GetValue() + oSection2:GetFunction("SD2QTD1"):GetValue() },.F.,.F. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		TRFunction():New(oSection1:Cell("VALMERC"),NIL,"ONPRINT",oBreak1,,/*cPicture*/,{|| oSection1:GetFunction("SD1TOT1"):GetValue() + oSection2:GetFunction("SD2TOT1"):GetValue() },.F.,.F. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		TRFunction():New(oSection1:Cell("VALTOTAL"),NIL,"ONPRINT",oBreak1,,/*cPicture*/,{|| oSection1:GetFunction("SD1TOT1"):GetValue() + oSection2:GetFunction("SD2TOT1"):GetValue() },.F.,.F. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		TRFunction():New(oSection1:Cell("VALDESC"),NIL,"ONPRINT",oBreak1,,/*cPicture*/,{|| oSection1:GetFunction("SD1TOT1"):GetValue() + oSection2:GetFunction("SD2TOT1"):GetValue() },.F.,.F. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		TRFunction():New(oSection1:Cell("VALCUSTO"),NIL,"ONPRINT",oBreak1,,/*cPicture*/,{|| oSection1:GetFunction("SD1CUS1"):GetValue() + oSection2:GetFunction("SD2CUS1"):GetValue() },.F.,.F. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		TRFunction():New(oSection1:Cell("D1_QUANT"),NIL,"ONPRINT",oBreak2,,/*cPicture*/,{|lSection,lReport,lPage| If( !lReport, oSection1:GetFunction("SD1QTD2"):GetValue() + oSection2:GetFunction("SD2QTD2"):GetValue() , oSection1:GetFunction("SD1QTD2"):ReportValue() + oSection2:GetFunction("SD2QTD2"):ReportValue() ) },.F.,.T. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		TRFunction():New(oSection1:Cell("VALMERC"),NIL,"ONPRINT",oBreak2,,/*cPicture*/,{|lSection,lReport,lPage| If( !lReport, oSection1:GetFunction("SD1TOT2"):GetValue() + oSection2:GetFunction("SD2TOT2"):GetValue() , oSection1:GetFunction("SD1TOT2"):ReportValue() + oSection2:GetFunction("SD2TOT2"):ReportValue() ) },.F.,.T. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		TRFunction():New(oSection1:Cell("VALTOTAL"),NIL,"ONPRINT",oBreak2,,/*cPicture*/,{|lSection,lReport,lPage| If( !lReport, oSection1:GetFunction("SD1TOT2"):GetValue() + oSection2:GetFunction("SD2TOT2"):GetValue() , oSection1:GetFunction("SD1TOT2"):ReportValue() + oSection2:GetFunction("SD2TOT2"):ReportValue() ) },.F.,.T. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		TRFunction():New(oSection1:Cell("VALDESC"),NIL,"ONPRINT",oBreak2,,/*cPicture*/,{|lSection,lReport,lPage| If( !lReport, oSection1:GetFunction("SD1TOT2"):GetValue() + oSection2:GetFunction("SD2TOT2"):GetValue() , oSection1:GetFunction("SD1TOT2"):ReportValue() + oSection2:GetFunction("SD2TOT2"):ReportValue() ) },.F.,.T. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		TRFunction():New(oSection1:Cell("VALCUSTO"),NIL,"ONPRINT",oBreak2,,/*cPicture*/,{|lSection,lReport,lPage| If( !lReport, oSection1:GetFunction("SD1CUS2"):GetValue() + oSection2:GetFunction("SD2CUS2"):GetValue() , oSection1:GetFunction("SD1CUS2"):ReportValue() + oSection2:GetFunction("SD2CUS2"):ReportValue() ) },.F.,.T. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		
	EndIf

	//==============================================================
	// Os TRFunctions abaixo nao sao impressos, servem apenas para |
	// acumular os valores das oSection1 e oSection2 para serem    |
	// utilizados na impressao do totalizador geral da oSection1   |
	// acima ONPRINT que subtrai as devolucoes SD1 - SD2.          |
	//==============================================================
	If nOrdem == 3 .Or. nOrdem == 4
		
		TRFunction():New(oSection1:Cell("D1_QUANT"),"SD1QTD1","SUM",oBreak1,,/*cPicture*/,/*uFormula*/,.F.,.T. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		TRFunction():New(oSection1:Cell("VALMERC"),"SD1TOT1","SUM",oBreak1,,/*cPicture*/,/*uFormula*/,.F.,.T. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		TRFunction():New(oSection1:Cell("VALTOTAL"),"SD1TOT1","SUM",oBreak1,,/*cPicture*/,/*uFormula*/,.F.,.T. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		TRFunction():New(oSection1:Cell("VALDESC"),"SD1TOT1","SUM",oBreak1,,/*cPicture*/,/*uFormula*/,.F.,.T. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		TRFunction():New(oSection1:Cell("VALCUSTO"),"SD1CUS1","SUM",oBreak1,,/*cPicture*/,/*uFormula*/,.F.,.T. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		oSection1:GetFunction("SD1QTD1"):Disable()
		oSection1:GetFunction("SD1TOT1"):Disable()
		oSection1:GetFunction("SD1CUS1"):Disable()
		
		TRFunction():New(oSection2:Cell("D2_QUANT"),"SD2QTD1","SUM",oBreak1,,/*cPicture*/,/*uFormula*/,.F.,.T. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		TRFunction():New(oSection2:Cell("VALMERC"),"SD2TOT1","SUM",oBreak1,,/*cPicture*/,/*uFormula*/,.F.,.T. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		TRFunction():New(oSection2:Cell("VALTOTAL"),"SD2TOT1","SUM",oBreak1,,/*cPicture*/,/*uFormula*/,.F.,.T. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		TRFunction():New(oSection2:Cell("VALDESC"),"SD2TOT1","SUM",oBreak1,,/*cPicture*/,/*uFormula*/,.F.,.T. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		TRFunction():New(oSection2:Cell("VALCUSTO"),"SD2CUS1","SUM",oBreak1,,/*cPicture*/,/*uFormula*/,.F.,.T. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		oSection2:GetFunction("SD2QTD1"):Disable()
		oSection2:GetFunction("SD2TOT1"):Disable()
		oSection2:GetFunction("SD2CUS1"):Disable()
		
	EndIf

	TRFunction():New(oSection1:Cell("D1_QUANT"),"SD1QTD2","SUM",oBreak2,,/*cPicture*/,/*uFormula*/,.F.,.T. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
	TRFunction():New(oSection1:Cell("VALMERC"),"SD1TOT2","SUM",oBreak2,,/*cPicture*/,/*uFormula*/,.F.,.T. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
	TRFunction():New(oSection1:Cell("VALTOTAL"),"SD1TOT2","SUM",oBreak2,,/*cPicture*/,/*uFormula*/,.F.,.T. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
	TRFunction():New(oSection1:Cell("VALDESC"),"SD1TOT2","SUM",oBreak2,,/*cPicture*/,/*uFormula*/,.F.,.T. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
	TRFunction():New(oSection1:Cell("VALCUSTO"),"SD1CUS2","SUM",oBreak2,,/*cPicture*/,/*uFormula*/,.F.,.T. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
	oSection1:GetFunction("SD1QTD2"):Disable()
	oSection1:GetFunction("SD1TOT2"):Disable()
	oSection1:GetFunction("SD1CUS2"):Disable()

	TRFunction():New(oSection2:Cell("D2_QUANT"),"SD2QTD2","SUM",oBreak2,,/*cPicture*/,/*uFormula*/,.F.,.T. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
	TRFunction():New(oSection2:Cell("VALMERC"),"SD2TOT2","SUM",oBreak2,,/*cPicture*/,/*uFormula*/,.F.,.T. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
	TRFunction():New(oSection2:Cell("VALTOTAL"),"SD2TOT2","SUM",oBreak2,,/*cPicture*/,/*uFormula*/,.F.,.T. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
	TRFunction():New(oSection2:Cell("VALDESC"),"SD2TOT2","SUM",oBreak2,,/*cPicture*/,/*uFormula*/,.F.,.T. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
	TRFunction():New(oSection2:Cell("VALCUSTO"),"SD2CUS2","SUM",oBreak2,,/*cPicture*/,/*uFormula*/,.F.,.T. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
	oSection2:GetFunction("SD2QTD2"):Disable()                                                                                 
	oSection2:GetFunction("SD2TOT2"):Disable()
	oSection2:GetFunction("SD2CUS2"):Disable()

	If nOrdem == 2 .Or. nOrdem == 3
		
		TRFunction():New(oSection1:Cell("D1_QUANT"),"SD1QTD3","SUM",oBreak3,,/*cPicture*/,/*uFormula*/,.F.,.T. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		TRFunction():New(oSection1:Cell("VALMERC"),"SD1TOT3","SUM",oBreak3,,/*cPicture*/,/*uFormula*/,.F.,.T. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		TRFunction():New(oSection1:Cell("VALTOTAL"),"SD1TOT3","SUM",oBreak3,,/*cPicture*/,/*uFormula*/,.F.,.T. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		TRFunction():New(oSection1:Cell("VALDESC"),"SD1TOT3","SUM",oBreak3,,/*cPicture*/,/*uFormula*/,.F.,.T. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		TRFunction():New(oSection1:Cell("VALCUSTO"),"SD1CUS3","SUM",oBreak3,,/*cPicture*/,/*uFormula*/,.F.,.T. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		oSection1:GetFunction("SD1QTD3"):Disable()
		oSection1:GetFunction("SD1TOT3"):Disable()
		oSection1:GetFunction("SD1CUS3"):Disable()
		
		TRFunction():New(oSection2:Cell("D2_QUANT"),"SD2QTD3","SUM",oBreak3,,/*cPicture*/,/*uFormula*/,.F.,.T. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		TRFunction():New(oSection2:Cell("VALMERC"),"SD2TOT3","SUM",oBreak3,,/*cPicture*/,/*uFormula*/,.F.,.T. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		TRFunction():New(oSection2:Cell("VALTOTAL"),"SD2TOT3","SUM",oBreak3,,/*cPicture*/,/*uFormula*/,.F.,.T. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		TRFunction():New(oSection2:Cell("VALDESC"),"SD2TOT3","SUM",oBreak3,,/*cPicture*/,/*uFormula*/,.F.,.T. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		TRFunction():New(oSection2:Cell("VALCUSTO"),"SD2CUS3","SUM",oBreak3,,/*cPicture*/,/*uFormula*/,.F.,.T. ,,, {|| IIf( MV_PAR15 == 1 ,(cAliasSF4)->F4_AGREG <> "N" , .T. ) } )
		oSection2:GetFunction("SD2QTD3"):Disable()
		oSection2:GetFunction("SD2TOT3"):Disable()
		oSection2:GetFunction("SD2CUS3"):Disable()
		
	EndIf

	oReport:SetMeter((cAliasSD1)->(RecCount()))
	DBSelectArea(cAliasSD1)

	oSection1:Init()

	While !oReport:Cancel() .And. !(cAliasSD1)->(Eof())
		
		lMoeda := .T.
		
		If oReport:Cancel()
			Exit
		EndIf
		
		//=================================
		// Considera filtro escolhido     |
		//=================================
		DBSelectArea(cAliasSD1)
		If !Empty(cFilUsrSD1)
			If !(&(cFilUsrSD1))
				DBSkip()
				Loop
			EndIf
		EndIf
		
		If lQuery
			//===============================================================================
			// Desconsidera quando For Cliente e Tipo da NF <> Devolucao ou Beneficiamento  |
			// Em situações onde o Código do Cliente e Código do Fornecedor são iguais      |
			// e necessário este critério para não imprimir o relatório incorretamente.     |
			//===============================================================================
			If (cAliasSD1)->TIPO == "C"
				If !(cAliasSD1)->D1_TIPO $ "DB"
					DBSkip()
					Loop
				EndIf
			EndIf
			
			//==============================================================
			// Nao imprimir notas com moeda diferente da escolhida.        |
			//==============================================================
			If MV_PAR14==2
				If If((cAliasSD1)->F1_MOEDA==0,1,(cAliasSD1)->F1_MOEDA) != MV_PAR13
					lMoeda := .F.
				EndIf
			EndIf
			
			cRazao   := (cAliasSD1)->RAZAO
			nValUnit := xmoeda((cAliasSD1)->D1_VUNIT,(cAliasSD1)->F1_MOEDA,MV_PAR13,(cAliasSD1)->F1_DTDIGIT,nDecs+1,(cAliasSD1)->F1_TXMOEDA)
			nValMer  := xmoeda((cAliasSD1)->D1_TOTAL,(cAliasSD1)->F1_MOEDA,MV_PAR13,(cAliasSD1)->F1_DTDIGIT,nDecs+1,(cAliasSD1)->F1_TXMOEDA)
			nValCusto:= xmoeda((cAliasSD1)->D1_CUSTO,1,MV_PAR13,(cAliasSD1)->F1_DTDIGIT,nDecs+1,(cAliasSD1)->F1_TXMOEDA)
			nValDesc := xmoeda((cAliasSD1)->D1_VALDESC)
			If MV_PAR24 == 1
				nValTot  := nValMer - nValDesc
			Else	
				nValTot := 	nValMer
			EndIf		
			// Variável para atualizar o Código quando For estiver usando veículo ou não
			If lVeiculo
				cCod:=(cAliasSD1)->D1_CODITE
			Else
				cCod:= (cAliasSD1)->D1_COD
			EndIf
			
		Else
			//==============================================================
			// Nao imprimir notas com moeda diferente da escolhida.        |
			//==============================================================
			If MV_PAR14==2
				If If(SF1->F1_MOEDA==0,1,SF1->F1_MOEDA) != MV_PAR13
					lMoeda := .F.
				EndIf
			EndIf
			
			//=================================================================
			// Posiciona o Fornecedor SA2 ou Cliente SA1 conf. o tipo da Nota |
			//=================================================================
			If (cAliasSD1)->D1_TIPO $ "DB"
				SA1->(DBSetOrder(1))
				SA1->(MsSeek( xFilial("SA1") + (cAliasSD1)->D1_FORNECE + (cAliasSD1)->D1_LOJA ))
				cRazao := SA1->A1_NOME
			Else
				SA2->(DBSetOrder(1))
				SA2->(MsSeek( xFilial("SA2") + (cAliasSD1)->D1_FORNECE + (cAliasSD1)->D1_LOJA ))
				cRazao := SA2->A2_NOME
			EndIf
			
			//=====================
			// Posiciona o SF1    |
			//=====================
			SF1->(MsSeek((cAliasSD1)->D1_FILIAL+(cAliasSD1)->D1_DOC+(cAliasSD1)->D1_SERIE+(cAliasSD1)->D1_FORNECE+(cAliasSD1)->D1_LOJA))
			
			//=====================
			// Posiciona o SF4    |
			//=====================
			If MV_PAR15 == 1
				SF4->(MsSeek( xFilial("SF4") + (cAliasSD1)->D1_TES ))
			EndIf
			
			nValUnit := xmoeda((cAliasSD1)->D1_VUNIT,SF1->F1_MOEDA,MV_PAR13,SF1->F1_DTDIGIT,nDecs+1,SF1->F1_TXMOEDA)
			nValMer  := xmoeda((cAliasSD1)->D1_TOTAL,SF1->F1_MOEDA,MV_PAR13,SF1->F1_DTDIGIT,nDecs+1,SF1->F1_TXMOEDA)
			nValCusto:= xmoeda((cAliasSD1)->D1_CUSTO,1,MV_PAR13,SF1->F1_DTDIGIT,nDecs+1,SF1->F1_TXMOEDA)
			nValDesc := xmoeda((cAliasSD1)->D1_VALDESC)
			If MV_PAR24 == 1
				nValTot  := nValMer - nValDesc
			Else	
				nValTot := 	nValMer
			EndIf		
			
		EndIf
		
		If lMoeda
			
			oReport:IncMeter()
			oSection1:PrintLine()
			
			//================================================================
			// Verificar a existencia de Devolucoes de Compras.              |
			//================================================================
			If (cAliasSD1)->D1_QTDEDEV <> 0 .And. MV_PAR11 == 1
				aAdd(aRecno,IIf(lQuery,(cAliasSD1)->SD1RECNO,Recno()))
			EndIf
			
		EndIf
		
		DBSelectArea(cAliasSD1)
		DBSkip()
		
	EndDo

	oSection1:Finish()

	//================================================================
	// Exclui o Arquivo Trabalho SD2 quando imprime NFs de devolucao |
	//================================================================
	If MV_PAR11 == 1
		
		RetIndex("SD2")
		DBSelectArea("SD2")
		dbClearFilter()
		DBSetOrder(1)
		
		If File(cArqTrbSD2+OrdBagExt())
			Ferase(cArqTrbSD2+OrdBagExt())
		EndIf
		
	EndIf

Return

/*
===============================================================================================================================
Programa----------: RCOM009P
Autor-------------: Lucas Crevilari
Data da Criacao---: 10/09/2014
Descrição---------: Imprime as devolucoes de compras SD2
Parametros--------:
Retorno-----------:
===============================================================================================================================
*/
Static Function RCOM009P(aRecno,lQuery,oReport,oSection1,oSection2,cAliasSD1,nRecno)

	Local nDecs    := Msdecimais(MV_PAR13) //casas decimais utilizadas na moeda da impressao
	Local nX       := 0
	Local nSaveRec := If( lQuery, nRecno, Recno() )

	oSection2:Init()

	TRPosition():New(oSection2,"SB1",1,{|| xFilial("SB1")+SD2->D2_COD })

	For nX :=1 to Len(aRecno)
		
		DBSelectArea("SD1")
		DBGoTo(aRecno[nX])
		DBSelectArea("SD2")
		MsSeek(SD1->D1_FILIAL+SD1->D1_COD+SD1->D1_DOC+SD1->D1_ITEM+SD1->D1_SERIE+SD1->D1_FORNECE+SD1->D1_LOJA)
		SF2->(MsSeek(SD2->D2_FILIAL+SD2->D2_DOC+SD2->D2_SERIE+SD2->D2_CLIENTE+SD2->D2_LOJA))
		
		While !Eof() .And. SD1->D1_FILIAL+SD1->D1_COD+SD1->D1_DOC+SD1->D1_ITEM+SD1->D1_SERIE+SD1->D1_FORNECE+SD1->D1_LOJA ==;
			SD2->D2_FILIAL+SD2->D2_COD+SD2->D2_NFORI+SD2->D2_ITEMORI+SD2->D2_SERIORI+SD2->D2_CLIENTE+SD2->D2_LOJA
			
			If nX == 1
				oReport:PrintText('-Devolucoes:',,oSection2:Cell("D2_DOC"):ColPos())
			EndIf
			
			If lVeiculo
				oReport:PrintText("[ " + SD2->D2_CODITE + " ]",,oSection2:Cell("D2_COD"):ColPos())
			EndIf
			
			nValUnit := xmoeda(SD2->D2_PRCVEN,SF2->F2_MOEDA,MV_PAR13,SF2->F2_EMISSAO,nDecs+1,SF2->F2_TXMOEDA)
			nValMer  := xmoeda(SD2->D2_TOTAL,SF2->F2_MOEDA,MV_PAR13,SF2->F2_EMISSAO,nDecs+1,SF2->F2_TXMOEDA)
			nValCusto:= xmoeda(SD2->D2_CUSTO1,1,MV_PAR13,SF2->F2_EMISSAO,nDecs+1,SF2->F2_TXMOEDA)
			nValDesc := xmoeda((cAliasSD1)->D1_VALDESC)

			If MV_PAR24 == 1
				nValTot  := nValMer - nValDesc
			Else	
				nValTot := 	nValMer
			EndIf	
			
			SA2->(DBSetOrder(1))
			SA2->(MsSeek( xFilial("SA2") + SD2->D2_CLIENTE + SD2->D2_LOJA ))
			cRazao := SA2->A2_NOME
			
			oSection2:PrintLine()
			
			DBSelectArea("SD2")
			DBSkip()
			
		EndDo
		
		If nX == Len(aRecno)
			oReport:ThinLine()
			oReport:SkipLine()
		EndIf
		
	Next nX

	oSection2:Finish()

	DBSelectArea(cAliasSD1)
	DBGoTo(nSaveRec)
	aRecno := {}

Return

/*
===============================================================================================================================
Programa----------: RCOM009N
Autor-------------: Lucas Crevilari
Data da Criacao---: 10/09/2014
Descrição---------: Busca a Natureza e Descricao
Parametros--------:
Retorno-----------:
===============================================================================================================================
*/
Static Function RCOM009N(_DOC,_SERIE,_FORNECE,_LOJA,nNum)

	Local cNatureza 	:= ""
	Local cQuery		:= ""
	Local cQuery2		:= ""

	cQuery := " SELECT E2_NATUREZ FROM " + RetSqlName("SE2")+" SE2 "
	cQuery += " WHERE E2_NUM 	= '"+_DOC+"' "
	cQuery += " AND E2_FORNECE 	= '"+_FORNECE+"'"
	cQuery += " AND E2_LOJA		= '"+_LOJA+"'"
	cQuery += " AND E2_FILIAL 	= '"+xFilial("SE2")+"' "
	cQuery += " AND SE2.D_E_L_E_T_ <> '*'"
	cQuery += " AND E2_PREFIXO = '"+_SERIE+"'"
	TcQuery cQuery New Alias "cQuery"

	cNatureza := AllTrim(cQuery->E2_NATUREZ)

	If !Empty(cQuery->E2_NATUREZ) .And. nNum == 2
		cQuery2 := " SELECT ED_DESCRIC FROM " + RetSqlName("SED")+" SED "
		cQuery2 += " WHERE ED_CODIGO = '"+cQuery->E2_NATUREZ+"' "
		cQuery2 += " AND ED_FILIAL = '"+xFilial("SED")+"' "
		cQuery2 += " AND SED.D_E_L_E_T_ <> '*'"
		TcQuery cQuery2 New Alias "cQuery2"
		
		cNatureza := AllTrim(cQuery2->ED_DESCRIC)
		
		cQuery2->(DBCloseArea())
	EndIf

	cQuery->(DBCloseArea())

Return(cNatureza)
