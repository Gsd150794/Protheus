/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |17/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25.
Julio Paz     |03/12/2021| Chamado 38364. Incluir no relatório 2 novas colunas p/exibir grupo,descrição do grupo produtos.
Lucas Borges  |09/10/2024| Chamado 48465. Retirada manipulação do SX1
===============================================================================================================================
*/
//====================================================================================================
// Definicoes de Includes e Defines da Rotina.
//====================================================================================================
#Include "TOTVS.ch"
#Include 'TOPCONN.CH'

/*
===============================================================================================================================
Programa----------: ROMS044
Autor-------------: Darcio R Sporl
Data da Criacao---: 08/07/2016
Descrição---------: Relatório Clientes com Contrato
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ROMS044()

Local oReport	:= nil
Private cPerg	:= "ROMS044"
Private aOrd	:= {"Filial","Cliente","Estado","Rede","Contrato"} 

If !Pergunte(cPerg,.T.)
     Return
EndIf

oReport := RptDef(cPerg)
oReport:PrintDialog()

Return

/*
===============================================================================================================================
Programa----------: RptDef
Autor-------------: Darcio R Sporl
Data da Criacao---: 08/07/2016
Descrição---------: Função que faz a montagem do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RptDef(cNome)
Local oReport	:= Nil
Local oSection1	:= Nil
Local oSection2	:= Nil
	
oReport:= TReport():New("ROMS044","Relatório Clientes com Contrato.","ROMS044", {|oReport| ReportPrint(oReport)},"Emissao da Relacao de Pedidos de Compras.")
oReport:SetLandscape()
oReport:SetTotalInLine(.F.)

If MV_PAR10 == 1
	oSection1:= TRSection():New(oReport, "Desconto Contratual", {"TRBPED"},aOrd , .F., .T.)

	TRCell():New(oSection1,"ZAZ_FILIAL"	,"TRBPED","Filial"  		,"@!",5)
	TRCell():New(oSection1,"ZAZ_COD"  	,"TRBPED","Contrato"		,"@!",10)
	TRCell():New(oSection1,"ZAZ_GRPVEN"	,"TRBPED","Rede"	  		,"@!",10)
	TRCell():New(oSection1,"ZAZ_CLIENT"	,"TRBPED","Cliente"			,"@D",10)
	TRCell():New(oSection1,"ZAZ_LOJA"	,"TRBPED","Loja"			,"@D",10)
	TRCell():New(oSection1,"ZAZ_NOME"	,"TRBPED","Nome"			,"@D",50)
	TRCell():New(oSection1,"ZAZ_DTINI"	,"TRBPED","Dt.Ini" 			,"@D",10)
	TRCell():New(oSection1,"ZAZ_DTFIM" 	,"TRBPED","Dt.Fim"			,"@D",10)
	TRCell():New(oSection1,"ZAZ_MSBLQL"	,"TRBPED","Bloqueado?"		,"@!",14)
	TRCell():New(oSection1,"ZAZ_ABATIM"	,"TRBPED","Abatimento"		,"@!",10)
	TRCell():New(oSection1,"ZAZ_MATAPR"	,"TRBPED","Mat.Aprov."		,"@!",10)
	TRCell():New(oSection1,"ZAZ_DTAPRO"	,"TRBPED","Dt.Aprov."		,"@D",10)
	TRCell():New(oSection1,"ZAZ_HRAPRO"	,"TRBPED","Hr.Aprov."		,"@!",10)
	TRCell():New(oSection1,"ZAZ_STATUS"	,"TRBPED","Status"			,"@!",10)
	TRCell():New(oSection1,"ZAZ_STBAS"	,"TRBPED","ST Base Desc"	,"@!",10)
	TRCell():New(oSection1,"A1_EST"		,"TRBPED","Estado"			,"@!",10)
	
	oSection2:= TRSection():New(oSection1, "Desconto Contratual - Itens", {"TRBDAD"}, NIL, .F., .T.)

	TRCell():New(oSection2,"ZB0_ITEM"	,"TRBDAD","Item"			,"@!",8)
	TRCell():New(oSection2,"B1_GRUPO"	,"TRBDAD","Grupo Prod"		,"@!",10)
	TRCell():New(oSection2,"BM_DESC"	,"TRBDAD","Desc.Grupo"		,"@!",10)
	TRCell():New(oSection2,"ZB0_SB1COD"	,"TRBDAD","Produto"			,"@!",15)
	TRCell():New(oSection2,"ZB0_DCRSB1"	,"TRBDAD","Descrição"		,"@!",50)
	TRCell():New(oSection2,"ZB0_DESCTO"	,"TRBDAD","% Desconto"		,"@E 999.99",10)
	TRCell():New(oSection2,"ZB0_CONTR"	,"TRBDAD","Contr.Italac"	,"@!",16)
	TRCell():New(oSection2,"ZB0_CLIENT"	,"TRBDAD","Cliente"			,"@!",10)
	TRCell():New(oSection2,"ZB0_LOJA"	,"TRBDAD","Loja"			,"@!",08)
	TRCell():New(oSection2,"ZB0_NOME"	,"TRBDAD","Nome"			,"@!",40)
	TRCell():New(oSection2,"ZB0_ABATIM"	,"TRBDAD","Abatimento"		,"@!",10)
	TRCell():New(oSection2,"ZB0_DESCPA"	,"TRBDAD","%Desc.Parc."		,"@E 999.99",10)
	TRCell():New(oSection2,"ZB0_EST"	,"TRBDAD","Estado"			,"@!",10)

	oSection2:SetTotalInLine(.F.)

Else
	oSection1:= TRSection():New(oReport, "Desconto Contratual", {"SC7"},aOrd , .F., .T.)
	
	TRCell():New(oSection1,"ZAZ_FILIAL"	,"TRBPED","Filial"  		,"@!",5)
	TRCell():New(oSection1,"ZAZ_COD"  	,"TRBPED","Contrato"		,"@!",10)
	TRCell():New(oSection1,"ZAZ_GRPVEN"	,"TRBPED","Rede"	  		,"@!",10)
	TRCell():New(oSection1,"ZAZ_CLIENT"	,"TRBPED","Cliente"			,"@D",10)
	TRCell():New(oSection1,"ZAZ_LOJA"	,"TRBPED","Loja"			,"@D",10)
	TRCell():New(oSection1,"ZAZ_NOME"	,"TRBPED","Nome"			,"@D",50)
	TRCell():New(oSection1,"ZAZ_DTINI"	,"TRBPED","Dt.Ini" 			,"@D",10)
	TRCell():New(oSection1,"ZAZ_DTFIM" 	,"TRBPED","Dt.Fim"			,"@D",10)
	TRCell():New(oSection1,"ZAZ_MSBLQL"	,"TRBPED","Bloqueado?"		,"@!",14)
	TRCell():New(oSection1,"ZAZ_ABATIM"	,"TRBPED","Abatimento"		,"@!",10)
	TRCell():New(oSection1,"ZAZ_MATAPR"	,"TRBPED","Mat.Aprov."		,"@!",10)
	TRCell():New(oSection1,"ZAZ_DTAPRO"	,"TRBPED","Dt.Aprov."		,"@D",10)
	TRCell():New(oSection1,"ZAZ_HRAPRO"	,"TRBPED","Hr.Aprov."		,"@!",10)
	TRCell():New(oSection1,"ZAZ_STATUS"	,"TRBPED","Status"			,"@!",10)
	TRCell():New(oSection1,"ZAZ_STBAS"	,"TRBPED","ST Base Desc"	,"@!",10)
	TRCell():New(oSection1,"A1_EST"		,"TRBPED","Estado"			,"@!",10)

EndIf
	
oReport:SetTotalInLine(.F.)

//=================================
//Aqui, farei uma quebra  por seção
//=================================
oSection1:SetPageBreak(.T.)

Return(oReport)

/*
===============================================================================================================================
Programa----------: RptDef
Autor-------------: Darcio R Sporl
Data da Criacao---: 08/07/2016
Descrição---------: Função que imprime o relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ReportPrint(oReport)

Local oSection1 := oReport:Section(1)
Local oSection2 := oReport:Section(1):Section(1)
Local cQry1		:= ""
Local cQry2		:= ""

If MV_PAR10 == 1

	cQry1 := "SELECT ZAZ_FILIAL, ZAZ_COD, ZAZ_GRPVEN, ZAZ_CLIENT, ZAZ_LOJA, ZAZ_NOME, ZAZ_DTINI, ZAZ_DTFIM, ZAZ_MSBLQL, ZAZ_ABATIM, ZAZ_MATAPR, ZAZ_DTAPRO, ZAZ_HRAPRO, ZAZ_STATUS, ZAZ_STBAS, A1_EST "
	cQry1 += "FROM " + RetSqlName("ZAZ") + " ZAZ "
	cQry1 += "JOIN " + RetSqlName("SA1") + " SA1 ON A1_FILIAL = '" + xFilial("SA1") + "' "
	cQry1 += "				AND (( A1_COD = ZAZ_CLIENT AND A1_LOJA = ZAZ_LOJA) OR A1_GRPVEN = ZAZ_GRPVEN)  "
	
	If !Empty(MV_PAR01)	
	
		cQry1 += "				AND A1_EST IN " + FormatIn(MV_PAR01,";") + " "
		
	EndIf
	
	cQry1 += "				AND SA1.D_E_L_E_T_ = ' ' "
	cQry1 += "WHERE "
	If MV_PAR02 == MV_PAR03
		cQry1 += "		ZAZ_FILIAL = '" + MV_PAR02 + "' "
	Else 
		cQry1 += "		ZAZ_FILIAL BETWEEN '" + MV_PAR02 + "' AND '" + MV_PAR03 + "' "
	EndIf
	If MV_PAR04 == MV_PAR06
		cQry1 += "	AND	ZAZ_CLIENT = '" + MV_PAR04 + "' "
	Else
		cQry1 += "	AND	ZAZ_CLIENT BETWEEN '" + MV_PAR04 + "' AND '" + MV_PAR06 + "' "
	EndIf
	If MV_PAR05 == MV_PAR07
		cQry1 += "	AND	ZAZ_LOJA = '" + MV_PAR05 + "' "
	Else
		cQry1 += "	AND	ZAZ_LOJA BETWEEN '" + MV_PAR05 + "' AND '" + MV_PAR07 + "' "
	EndIf
	If MV_PAR08 == MV_PAR09
		cQry1 += "	AND	ZAZ_GRPVEN = '" + MV_PAR08 + "' "
	Else
		cQry1 += "	AND	ZAZ_GRPVEN BETWEEN '" + MV_PAR08 + "' AND '" + MV_PAR09 + "' "
	EndIf
	If MV_PAR11 == 1
		cQry1 += "  AND ZAZ_MSBLQL = '1' "
	ElseIf MV_PAR11 == 2
		cQry1 += "  AND ZAZ_MSBLQL = '2' "
	EndIf
	cQry1 += "	AND	ZAZ.D_E_L_E_T_ = ' ' "

	If oReport:nOrder == 1
		cQry1 += "	ORDER BY ZAZ_FILIAL "
	ElseIf oReport:nOrder == 2
		cQry1 += "	ORDER BY ZAZ_CLIENT, ZAZ_LOJA "
	ElseIf oReport:nOrder == 3
		cQry1 += "	ORDER BY A1_EST "
	ElseIf oReport:nOrder == 4
		cQry1 += "	ORDER BY ZAZ_GRPVEN "
	Else
		cQry1 += "	ORDER BY ZAZ_COD "
	EndIf

	//=================================================================
	//Se o alias estiver aberto, irei fechar, isso ajuda a evitar erros
	//=================================================================
	If Select("TRBPED") <> 0
		DBSelectArea("TRBPED")
		DBCloseArea()
	EndIf

	//=================
	//crio o novo alias
	//=================
	TCQUERY cQry1 NEW ALIAS "TRBPED"
		
	DBSelectArea("TRBPED")
	TRBPED->(DBGoTop())
		
	oReport:SetMeter(TRBPED->(LastRec()))

	//=================================
	//Irei percorrer todos os registros
	//=================================
	While !TRBPED->(Eof())
	
		If oReport:Cancel()
			Exit
		EndIf

		//===========================
		//inicializo a primeira seção
		//===========================
		oSection1:Init()
	
		oReport:IncMeter()
	
		IncProc("Imprimindo Filial " + AllTrim(TRBPED->ZAZ_FILIAL) + " - " + AllTrim(FWFilialName(cEmpAnt,TRBPED->ZAZ_FILIAL)))

		//========================
		//imprimo a primeira seção
		//========================
		oSection1:Cell("ZAZ_FILIAL")	:SetValue(TRBPED->ZAZ_FILIAL)
		oSection1:Cell("ZAZ_COD")		:SetValue(TRBPED->ZAZ_COD)
		oSection1:Cell("ZAZ_GRPVEN")	:SetValue(TRBPED->ZAZ_GRPVEN)
		oSection1:Cell("ZAZ_CLIENT")	:SetValue(TRBPED->ZAZ_CLIENT)
		oSection1:Cell("ZAZ_LOJA")		:SetValue(TRBPED->ZAZ_LOJA)
		oSection1:Cell("ZAZ_NOME")		:SetValue(TRBPED->ZAZ_NOME)
		oSection1:Cell("ZAZ_DTINI")		:SetValue(SToD(TRBPED->ZAZ_DTINI))
		oSection1:Cell("ZAZ_DTFIM")		:SetValue(SToD(TRBPED->ZAZ_DTFIM))
		oSection1:Cell("ZAZ_MSBLQL")	:SetValue(IIf(TRBPED->ZAZ_MSBLQL == "1", "SIM", "NAO"))
		oSection1:Cell("ZAZ_ABATIM")	:SetValue(TRBPED->ZAZ_ABATIM)
		oSection1:Cell("ZAZ_MATAPR")	:SetValue(TRBPED->ZAZ_MATAPR)
		oSection1:Cell("ZAZ_DTAPRO")	:SetValue(SToD(TRBPED->ZAZ_DTAPRO))
		oSection1:Cell("ZAZ_HRAPRO")	:SetValue(TRBPED->ZAZ_HRAPRO)
		oSection1:Cell("ZAZ_STATUS")	:SetValue(TRBPED->ZAZ_STATUS)
		oSection1:Cell("ZAZ_STBAS")		:SetValue(TRBPED->ZAZ_STBAS)
		oSection1:Cell("A1_EST")		:SetValue(TRBPED->A1_EST)
		oSection1:PrintLine()

		//==========================
		//inicializo a segunda seção
		//==========================
		oSection2:init()
	
		cQry2 := "SELECT ZB0_ITEM, ZB0_SB1COD, ZB0_DCRSB1, ZB0_DESCTO, ZB0_CONTR, ZB0_CLIENT, ZB0_LOJA, ZB0_NOME, ZB0_ABATIM, ZB0_DESCPA, ZB0_EST, B1_GRUPO, BM_DESC "
		cQry2 += "FROM " + RetSqlName("ZB0") + " ZB0, " + RetSqlName("SB1") + " SB1, " + RetSqlName("SBM") + " SBM "
		cQry2 += "WHERE ZB0_FILIAL = '" + TRBPED->ZAZ_FILIAL + "' "
		cQry2 += "  AND ZB0_COD = '" + TRBPED->ZAZ_COD + "' "
		cQry2 += "  AND ZB0.D_E_L_E_T_ = ' ' AND SB1.D_E_L_E_T_ = ' ' AND SBM.D_E_L_E_T_ = ' '"
		cQry2 += "  AND SB1.B1_COD = ZB0.ZB0_SB1COD "
		cQry2 += "  AND SB1.B1_GRUPO = SBM.BM_GRUPO "
		cQry2 += "ORDER BY ZB0_FILIAL, ZB0_COD, ZB0_ITEM "
	
		If Select("TRBDAD") <> 0
			DBSelectArea("TRBDAD")
			DBCloseArea()
		EndIf
	
		TCQUERY cQry2 NEW ALIAS "TRBDAD"
		
		DBSelectArea("TRBDAD")
		TRBDAD->(DBGoTop())
		
		oReport:SetMeter(TRBDAD->(LastRec()))
	
		While !TRBDAD->(Eof())
			oReport:IncMeter()

			//=======================
			//Imprime a segunda seção
			//=======================
			IncProc("Imprimindo produto "+AllTrim(TRBDAD->ZB0_SB1COD))
			oSection2:Cell("ZB0_ITEM")		:SetValue(TRBDAD->ZB0_ITEM)
			oSection2:Cell("B1_GRUPO")	    :SetValue(TRBDAD->B1_GRUPO)
			oSection2:Cell("BM_DESC")	    :SetValue(TRBDAD->BM_DESC)
			oSection2:Cell("ZB0_SB1COD")	:SetValue(TRBDAD->ZB0_SB1COD)
			oSection2:Cell("ZB0_DCRSB1")	:SetValue(TRBDAD->ZB0_DCRSB1)
			oSection2:Cell("ZB0_DESCTO")	:SetValue(TRBDAD->ZB0_DESCTO)
			oSection2:Cell("ZB0_CONTR")		:SetValue(TRBDAD->ZB0_CONTR)
			oSection2:Cell("ZB0_CLIENT")	:SetValue(TRBDAD->ZB0_CLIENT)
			oSection2:Cell("ZB0_LOJA")		:SetValue(TRBDAD->ZB0_LOJA)
			oSection2:Cell("ZB0_NOME")		:SetValue(TRBDAD->ZB0_NOME)
			oSection2:Cell("ZB0_ABATIM")	:SetValue(TRBDAD->ZB0_ABATIM)
			oSection2:Cell("ZB0_DESCPA")	:SetValue(TRBDAD->ZB0_DESCPA)
			oSection2:Cell("ZB0_EST")		:SetValue(TRBDAD->ZB0_EST)
			oSection2:PrintLine()
	
			TRBDAD->(DBSkip())
		End
		oReport:ThinLine()
		oSection2:Finish()
		TRBPED->(DBSkip())
	End
	oSection1:Finish()
	oSection1:Enable()
	oSection2:Enable()
Else

	cQry1 := "SELECT ZAZ_FILIAL, ZAZ_COD, ZAZ_GRPVEN, ZAZ_CLIENT, ZAZ_LOJA, ZAZ_NOME, ZAZ_DTINI, ZAZ_DTFIM, ZAZ_MSBLQL, ZAZ_ABATIM, ZAZ_MATAPR, ZAZ_DTAPRO, ZAZ_HRAPRO, ZAZ_STATUS, ZAZ_STBAS, A1_EST "
	cQry1 += "FROM " + RetSqlName("ZAZ") + " ZAZ "
	cQry1 += "JOIN " + RetSqlName("SA1") + " SA1 ON A1_FILIAL = '" + xFilial("SA1") + "' "
	cQry1 += "				AND (( A1_COD = ZAZ_CLIENT AND A1_LOJA = ZAZ_LOJA) OR A1_GRPVEN = ZAZ_GRPVEN)  "
	
	If !Empty(MV_PAR01)
	
	  cQry1 += "				AND A1_EST IN " + FormatIn(MV_PAR01,";") + " "
	
	EndIf
	
	cQry1 += "				AND SA1.D_E_L_E_T_ = ' ' "
	cQry1 += "WHERE "
	If MV_PAR02 == MV_PAR03
		cQry1 += "		ZAZ_FILIAL = '" + MV_PAR02 + "' "
	Else 
		cQry1 += "		ZAZ_FILIAL BETWEEN '" + MV_PAR02 + "' AND '" + MV_PAR03 + "' "
	EndIf
	If MV_PAR04 == MV_PAR06
		cQry1 += "	AND	ZAZ_CLIENT = '" + MV_PAR04 + "' "
	Else
		cQry1 += "	AND	ZAZ_CLIENT BETWEEN '" + MV_PAR04 + "' AND '" + MV_PAR06 + "' "
	EndIf
	If MV_PAR05 == MV_PAR07
		cQry1 += "	AND	ZAZ_LOJA = '" + MV_PAR05 + "' "
	Else
		cQry1 += "	AND	ZAZ_LOJA BETWEEN '" + MV_PAR05 + "' AND '" + MV_PAR07 + "' "
	EndIf
	If MV_PAR08 == MV_PAR09
		cQry1 += "	AND	ZAZ_GRPVEN = '" + MV_PAR09 + "' "
	Else
		cQry1 += "	AND	ZAZ_GRPVEN BETWEEN '" + MV_PAR08 + "' AND '" + MV_PAR09 + "' "
	EndIf
	If MV_PAR11 == 1
		cQry1 += "  AND ZAZ_MSBLQL = '1' "
	ElseIf MV_PAR11 == 2
		cQry1 += "  AND ZAZ_MSBLQL = '2' "
	EndIf
	cQry1 += "	AND	ZAZ.D_E_L_E_T_ = ' ' "
	
	cQry1 += " GROUP BY ZAZ_FILIAL, ZAZ_COD, ZAZ_GRPVEN, ZAZ_CLIENT, ZAZ_LOJA, ZAZ_NOME, ZAZ_DTINI, ZAZ_DTFIM, ZAZ_MSBLQL, ZAZ_ABATIM, ZAZ_MATAPR, ZAZ_DTAPRO, ZAZ_HRAPRO, ZAZ_STATUS, ZAZ_STBAS, A1_EST"


	If oReport:nOrder == 1
		cQry1 += "	ORDER BY ZAZ_FILIAL "
	ElseIf oReport:nOrder == 2
		cQry1 += "	ORDER BY ZAZ_CLIENT, ZAZ_LOJA "
	ElseIf oReport:nOrder == 3
		cQry1 += "	ORDER BY A1_EST "
	ElseIf oReport:nOrder == 4
		cQry1 += "	ORDER BY ZAZ_GRPVEN "
	Else
		cQry1 += "	ORDER BY ZAZ_COD "
	EndIf
	

	//Se o alias estiver aberto, irei fechar, isso ajuda a evitar erros
	If Select("TRBPED") <> 0
		DBSelectArea("TRBPED")
		DBCloseArea()
	EndIf
		
	//crio o novo alias
	TCQUERY cQry1 NEW ALIAS "TRBPED"
		
	DBSelectArea("TRBPED")
	TRBPED->(DBGoTop())
		
	oReport:SetMeter(TRBPED->(LastRec()))
	
	//Irei percorrer todos os meus registros
	While !TRBPED->(Eof())
	
		If oReport:Cancel()
			Exit
		EndIf
	
		//inicializo a primeira seção
		oSection1:Init()
	
		oReport:IncMeter()
	
		IncProc("Imprimindo Filial " + AllTrim(TRBPED->ZAZ_FILIAL) + " - " + AllTrim(FWFilialName(cEmpAnt,TRBPED->ZAZ_FILIAL)))

		//imprimo a primeira seção
		oSection1:Cell("ZAZ_FILIAL")	:SetValue(TRBPED->ZAZ_FILIAL)
		oSection1:Cell("ZAZ_COD")		:SetValue(TRBPED->ZAZ_COD)
		oSection1:Cell("ZAZ_GRPVEN")	:SetValue(TRBPED->ZAZ_GRPVEN)
		oSection1:Cell("ZAZ_CLIENT")	:SetValue(TRBPED->ZAZ_CLIENT)
		oSection1:Cell("ZAZ_LOJA")		:SetValue(TRBPED->ZAZ_LOJA)
		oSection1:Cell("ZAZ_NOME")		:SetValue(TRBPED->ZAZ_NOME)
		oSection1:Cell("ZAZ_DTINI")		:SetValue(SToD(TRBPED->ZAZ_DTINI))
		oSection1:Cell("ZAZ_DTFIM")		:SetValue(SToD(TRBPED->ZAZ_DTFIM))
		oSection1:Cell("ZAZ_MSBLQL")	:SetValue(IIf(TRBPED->ZAZ_MSBLQL == "1", "SIM", "NAO"))
		oSection1:Cell("ZAZ_ABATIM")	:SetValue(TRBPED->ZAZ_ABATIM)
		oSection1:Cell("ZAZ_MATAPR")	:SetValue(TRBPED->ZAZ_MATAPR)
		oSection1:Cell("ZAZ_DTAPRO")	:SetValue(SToD(TRBPED->ZAZ_DTAPRO))
		oSection1:Cell("ZAZ_HRAPRO")	:SetValue(TRBPED->ZAZ_HRAPRO)
		oSection1:Cell("ZAZ_STATUS")	:SetValue(TRBPED->ZAZ_STATUS)
		oSection1:Cell("ZAZ_STBAS")		:SetValue(TRBPED->ZAZ_STBAS)
		oSection1:Cell("A1_EST")		:SetValue(TRBPED->A1_EST)
		oSection1:PrintLine()

		TRBPED->(DBSkip())
	End
	oSection1:Finish()
	oSection1:Enable()
EndIf

Return
