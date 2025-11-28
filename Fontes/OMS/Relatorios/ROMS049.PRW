/*
===============================================================================================================================
               ULTIMAS ATUALIZACOES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
       Autor      |    Data    |                                             Motivo                                           
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  	  | 17/10/2019 | Removidos os Warning na compilação da release 12.1.25. Chamado 28346
===============================================================================================================================
*/
//====================================================================================================
// Definicoes de Includes e Defines da Rotina.
//====================================================================================================
#Include "TOTVS.ch"
#Include 'TOPCONN.CH'

/*
===============================================================================================================================
Programa----------: ROMS049
Autor-------------: Josué Danich Prestes
Data da Criacao---: 03/07/2017
===============================================================================================================================
Descrição---------: Relatório Monitor de Pedidos x Entrega - Chamado 19350
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ROMS049()
Local oReport	:= nil
Private cPerg	:= "ROMS049"
Private aOrd	:= {"Filial","Pedido","Cliente","Rede","Estado"} 

If !Pergunte(cPerg,.T.)
     Return
EndIf

oReport := ROMS049P(cPerg)
oReport:PrintDialog()

Return

/*
===============================================================================================================================
Programa----------: ROMS049P
Autor-------------: Josué Danich Prestes
Data da Criacao---: 08/07/2016
===============================================================================================================================
Descrição---------: Função que faz a montagem do relatório
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS049P(cNome)
Local oReport	:= Nil
Local oSection1	:= Nil
	
oReport:= TReport():New("ROMS049","Relatório Monitor de Pedidos x Entrega","ROMS049", {|oReport| ROMS049R(oReport)},"Relatório Monitor de Pedidos x Entrega")
oReport:SetLandscape()
oReport:SetTotalInLine(.F.)

oSection1:= TRSection():New(oReport, "Monitor de Pedidos x Entrega", {"TRBPED"},aOrd , .F., .T.)

TRCell():New(oSection1,"C5_FILIAL"	,"TRBPED","Filial"  		,"@!",5)
TRCell():New(oSection1,"C5_NUM"  	,"TRBPED","Pedido"		    ,"@!",10)
TRCell():New(oSection1,"C5_CLIENTE"	,"TRBPED","Cliente"		    ,"@!",60)
TRCell():New(oSection1,"C5_I_GRPVE"	,"TRBPED","Grupo"		    ,"@!",40)
TRCell():New(oSection1,"C5_I_DTENT" ,"TRBPED","Data Ent."		,"@!",10)
TRCell():New(oSection1,"DAK_DATA"  	,"TRBPED","Data OC"	  	    ,"@!",10)
TRCell():New(oSection1,"F2_EMISSAO"	,"TRBPED","Data Fat."		,"@!",10)
TRCell():New(oSection1,"TRANSIT"  	,"TRBPED","Trans Time"		,"@!",10)
TRCell():New(oSection1,"PREVISAO"  	,"TRBPED","Prev Ent"		,"@!",10)
TRCell():New(oSection1,"STATUS"  	,"TRBPED","Status"		    ,"@!",50)


Return(oReport)

/*
===============================================================================================================================
Programa----------: ROMS049P
Autor-------------: Darcio R Sporl
Data da Criacao---: 08/07/2016
===============================================================================================================================
Descrição---------: Função que imprime o relatório
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS049R(oReport)
Local oSection1 := oReport:Section(1)
Local cQry1		:= ""

Private aheader := {}
Private acols := {}

cQry1 := "SELECT C5_FILIAL, C5_NUM,C5_CLIENTE,C5_LOJACLI,C5_EMISSAO,C5_I_EST,C5_I_GRPVE,C5_I_DTENT,C5_I_NOME,C5_I_NOMRD, "
cQry1 += "NVL((SELECT F2_EMISSAO FROM " + RetSqlName("SF2") + " F2 WHERE F2.D_E_L_E_T_ = ' ' AND F2.F2_FILIAL = SC5.C5_FILIAL AND F2.F2_I_PEDID = SC5.C5_NUM ),'N/C') AS F2_EMISSAO, "
cQry1 += "NVL((SELECT DAI_DATA FROM " + RetSqlName("DAI") + " DAI WHERE DAI.D_E_L_E_T_ = ' ' AND DAI.DAI_FILIAL = SC5.C5_FILIAL AND DAI.DAI_PEDIDO = SC5.C5_NUM),'N/C') AS DAK_DATA "
cQry1 += "FROM " + RetSqlName("SC5") + " SC5 "
	
cQry1 += "WHERE SC5.D_E_L_E_T_ = ' ' "

If !Empty(MV_PAR01)

	cQry1 += "  AND C5_I_EST IN " +  FormatIn(MV_PAR01,";")  + " "

EndIf

If !Empty(MV_PAR02) .And. !Empty(MV_PAR03)

	cQry1 += " AND C5_FILIAL >= '" + MV_PAR02 + "' AND C5_FILIAL <= '" + MV_PAR03 + "' "
	
EndIf

If !Empty(MV_PAR04) .And. !Empty(MV_PAR06)

	cQry1 += " AND C5_CLIENTE >= '" + MV_PAR04 + "' AND C5_CLIENTE <= '" + MV_PAR06 + "' "
	
EndIf

If !Empty(MV_PAR05) .And. !Empty(MV_PAR07)

	cQry1 += " AND C5_LOJACLI >= '" + MV_PAR05 + "' AND C5_LOJACLI <= '" + MV_PAR07 + "' "
	
EndIf

If !Empty(MV_PAR08) .And. !Empty(MV_PAR09)

	cQry1 += " AND C5_I_GRPVE >= '" + MV_PAR08 + "' AND C5_I_GRPVE <= '" + MV_PAR09 + "' "
	
EndIf

If !Empty(MV_PAR10) .And. !Empty(MV_PAR11)

	cQry1 += " AND C5_EMISSAO >= '" + DToS(MV_PAR10) + "' AND C5_EMISSAO <= '" + DToS(MV_PAR11) + "' "
	
EndIf

If !Empty(MV_PAR12) .And. !Empty(MV_PAR13)

	cQry1 += " AND C5_NUM >= '" + MV_PAR12 + "' AND C5_NUM <= '" + MV_PAR13 + "' "
	
EndIf

If oReport:nOrder == 1
	cQry1 += "	ORDER BY C5_FILIAL,C5_NUM "
ElseIf oReport:nOrder == 2
	cQry1 += "	ORDER BY C5_NUM "
ElseIf oReport:nOrder == 3
	cQry1 += "	ORDER BY C5_CLIENTE,C5_LOJA,C5_NUM "
ElseIf oReport:nOrder == 3
	cQry1 += "	ORDER BY C5_I_GRPVE,C5_CLIENTE,C5_LOJA,C5_NUM "
ElseIf oReport:nOrder == 3
	cQry1 += "	ORDER BY C5_I_EST,C5_NUM "
EndIf

If Select("TRBPED") <> 0
	DBSelectArea("TRBPED")
	DBCloseArea()
EndIf

TCQUERY cQry1 NEW ALIAS "TRBPED"
	
DBSelectArea("TRBPED")
TRBPED->(DBGoTop())
		
oReport:SetMeter(TRBPED->(LastRec()))

While !TRBPED->(Eof())
	
	If oReport:Cancel()
		Exit
	EndIf

	oSection1:Init()

	oReport:IncMeter()
	
	IncProc("Imprimindo Filial " + AllTrim(TRBPED->C5_FILIAL) + " - " + AllTrim(FWFilialName(cEmpAnt,TRBPED->C5_FILIAL)))
	
	//Análise de transit time
	//Calcula data de faturamento necessária para atender a entrega com base no transit time
	//Prepara aheader e acols para a função omsvldent
	aheader := {}
	aAdd(aheader,{1,"C6_ITEM"})
	aAdd(aheader,{2,"C6_PRODUTO"})
	aAdd(aheader,{3,"C6_LOCAL"})

	SC6->(DBSetOrder(1))
	SC6->(DBGoTop())
	SC6->(DBSeek(TRBPED->C5_FILIAL+TRBPED->C5_NUM))
	
	acols := {}
		
	While SC6->(!Eof()) .And. TRBPED->C5_FILIAL == SC6->C6_FILIAL .And. TRBPED->C5_NUM == SC6->C6_NUM
		
			aAdd(acols,{SC6->C6_ITEM,SC6->C6_PRODUTO,SC6->C6_LOCAL})
		
			SC6->(DBSkip())
			
	EndDo
		
	
	_ndias :=  u_omsvldent(SToD(TRBPED->C5_I_DTENT), TRBPED->C5_CLIENTE, TRBPED->C5_LOJACLI, TRBPED->C5_FILIAL, TRBPED->C5_NUM,1) //Carrega dias de transit time
	
	If _ndias == -1
	
		_cprz := "N/C"
		
	Else
	
		_cprz := StrZero(_ndias,3)
	
	EndIf
	
	If AllTrim(TRBPED->F2_EMISSAO) == "N/C"
		_cemissao := "N/C"
		_dprevisao := "N/C"
		
		If _ndias > -1  
			
			If SToD(TRBPED->C5_I_DTENT) - _ndias > Date()
			
				_cstatus := "AGUARDANDO FATURAMENTO NO PRAZO"
				
			Else
			
				_cstatus := "AGUARDANDO FATURAMENTO ATRASADO"
				
			EndIf
			
		Else
		
			_cstatus := "AGUARDANDO FATURAMENTO"
			
		EndIf
		
	Else
		_cemissao := DToC(SToD(TRBPED->F2_EMISSAO))

		If _ndias > 0
		
			_dprevisao := DToC(SToD(TRBPED->F2_EMISSAO)+_ndias)
			
			If SToD(TRBPED->C5_I_DTENT)  > SToD(TRBPED->F2_EMISSAO)+_ndias
			
				_cstatus := "FATURADO NO PRAZO"
				
			Else
			
				_cstatus := "FATURADO ATRASADO"
				
			EndIf
			
			
		Else
		
			_dprevisao := "N/C"
			_cstatus := "FATURADO"
		
		EndIf
		
	EndIf
	
	If AllTrim(TRBPED->DAK_DATA) == "N/C"
		_ccarga := "N/C"
	Else
		_ccarga := DToC(SToD(TRBPED->DAK_DATA))
	EndIf
	
	
	

	oSection1:Cell("C5_FILIAL")		:SetValue(TRBPED->C5_FILIAL)
	oSection1:Cell("C5_NUM")		:SetValue(TRBPED->C5_NUM)
	oSection1:Cell("C5_CLIENTE")	:SetValue(TRBPED->C5_CLIENTE + "/" + TRBPED->C5_LOJACLI + " - " + TRBPED->C5_I_NOME)
	oSection1:Cell("C5_I_GRPVE")    :SetValue(TRBPED->C5_I_GRPVE + " - " + TRBPED->C5_I_NOMRD)
	oSection1:Cell("C5_I_DTENT")	:SetValue(SToD(TRBPED->C5_I_DTENT))
	oSection1:Cell("DAK_DATA")		:SetValue(_ccarga)
	oSection1:Cell("F2_EMISSAO")	:SetValue(_cemissao)
	oSection1:Cell("TRANSIT")		:SetValue(_cprz)
	oSection1:Cell("PREVISAO")		:SetValue(_dprevisao)
	oSection1:Cell("STATUS")		:SetValue(_cstatus)
	oSection1:PrintLine()

	TRBPED->(DBSkip())
End
oSection1:Finish()
oSection1:Enable()

Return
