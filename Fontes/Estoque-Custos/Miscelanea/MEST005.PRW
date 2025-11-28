/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |06/11/2019| Chamado 28346. Revisão de fonte para novo appserver
Lucas Borges  |08/10/2024| Chamado 48465. Retirada manipulação do SX1
Lucas Borges  |09/05/2025| Chamado 50617. Corrigir chamada estática no nome das tabelas do sistema
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MEST005
Autor-------------: Erich Buttner
Data da Criacao---: 09/08/2013  
Descrição---------: Rotina de Execução de eventos de custo do leite 
Parametros--------: Nenhum
Retorno-----------: .T. = Permite confirmar estorno / .F. = Nao Permite confirmar estorno   
===============================================================================================================================
*/
User Function MEST005() 
Local I
Private cPerg := "MEST005"
Private TRB := CriaTrab(Nil,.F.)
Public cPerDE, cPerAte

If !Pergunte(cPerg,.T.)
	Return ()
EndIf

cTpAcao	:= MV_PAR01
cTpCust	:= MV_PAR03
cGrpCus	:= MV_PAR04
cEvent	:= MV_PAR05
cSubEve	:= MV_PAR06
cPerDE	:= MV_PAR07
cPerAte	:= MV_PAR08
cRecalc	:= MV_PAR09
cFlExc	:= AllTrim(MV_PAR02)

aSM0 := FWLoadSM0()
cMvFil := ""

For I:=1 To Len(aSM0)
	cMvFil += aSM0[I][2]+If(I == Len(aSM0),"",";")
Next I

cExc := " SELECT * FROM " + RetSqlName("ZL6") + ""
cExc += " WHERE D_E_L_E_T_ = ' '"

If Empty(AllTrim(cFlExc))
	cExc += " AND ZL6_FILIAL IN "+FormatIn(cMvFil,";")
Else
	cExc += " AND ZL6_FILIAL IN "+FormatIn(cFlExc,";")
EndIf
If !Empty(AllTrim(cEvent))
	cExc += " AND ZL6_CODEVE IN "+FormatIn(cEvent,";")
EndIf

If !Empty(AllTrim(cGrpCus))
	cExc += " AND ZL6_GRPCUS IN "+FormatIn(cGrpCus,";")
EndIf

If !Empty(AllTrim(cTpCust))
	cExc += " AND ZL6_TPCUS IN "+FormatIn(cTpCust,";")
EndIf
cExc += " AND ZL6_MSBLQL = '2' "
cExc += " ORDER BY ZL6_FILIAL, ZL6_TPCUS, ZL6_GRPCUS, ZL6_CODEVE"


cExc := ChangeQuery(cExc)

If Select("TRB") >0
	TRB->(DBCloseArea())
EndIf

MPSysOpenQuery(cExc,"TRB")
DBSelectArea("TRB")

lVld:= .F.

While TRB->(!Eof())

	lVld := If( Empty(TRB->ZL6_CONDIC), .T.,&(AllTrim(TRB->ZL6_CONDIC)))
	If lVld
		aVlrCust := If(Empty(AllTrim(TRB->ZL6_REGRA)),QRYCUST(TRB->ZL6_OBSERV),&(AllTrim(TRB->ZL6_REGRA)))
	
		For I:= 1 To Len(aVlrCust)
			DBSelectArea("ZLG")
			ZLG->(DBSetOrder(6))
			If ZLG->(DBSeek(TRB->ZL6_FILIAL+SubStr(aVlrCust[I][3],1,6)+aVlrCust[I][4]+aVlrCust[I][5]+aVlrCust[I][10]+aVlrCust[I][11]))
				RecLock ("ZLG",.F.)
				RollBackSX8()
			Else
				RecLock ("ZLG",.T.)
				ZLG->ZLG_CODAPU	:= aVlrCust[I][2]
				ConfirmSX8()
			EndIf		
				ZLG->ZLG_FILIAL	:= aVlrCust[I][1]
				ZLG->ZLG_DATA		:= aVlrCust[I][3]
				ZLG->ZLG_TPCUS	:= aVlrCust[I][4]
				ZLG->ZLG_GRPCUS	:= aVlrCust[I][5]
				ZLG->ZLG_QTD		:= If(TRB->ZL6_QTD == '1',aVlrCust[I][6], 0)
				ZLG->ZLG_VLREVE	:= aVlrCust[I][8]
				ZLG->ZLG_CODEVE := aVlrCust[I][10]
				ZLG->ZLG_SUBEVE := aVlrCust[I][11]
				ZLG->(MSUnLock())
			Next I
	EndIf
	TRB->(DBSkip())
EndDo
//===============================================================
// Grava log da Rotina de eventos do custo do leite.
//=============================================================== 
U_ITLOGACS("MEST005")

Alert("Finalizado")

Return

/*
===============================================================================================================================
Programa----------: QRYCUST
Autor-------------: Erich Buttner
Data da Criacao---: 09/08/2013  
Descrição---------: Rotina de Execução de eventos de custo do leite    
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function QRYCUST(cFun)

Local nQtd := 0
Local nPrcEve := 0
Local nPrcIcm := 0
Local	nPrcLt  := 0
Local nTot := 0
Local aVlrs := {}

If cFun == '1'

	If !Empty(AllTrim(TRB->ZL6_CENTRO)) .Or. !Empty(AllTrim(TRB->ZL6_CFOP)) .Or. !Empty(AllTrim(TRB->ZL6_CODPRO))
	
		cTst := " SELECT D1.D1_COD AS CODIGO_PRODUTO, D1.D1_CC AS CENTRO_CUSTO, D1.D1_QUANT AS QUANTIDADE, "
		cTst += " D1.D1_TOTAL AS TOTAL_NF, D1.D1_CUSTO AS CUSTO, D1_VALICM AS ICMS "
		cTst += " FROM " + RetSqlName("SD1") + " D1, " + RetSqlName("SB1") + " B1 "
		cTst += " WHERE D1.D_E_L_E_T_ = ' ' " 
		cTst += " AND D1.D1_FILIAL = '"+TRB->ZL6_FILIAL+"' "
		cTst += " AND D1.D1_DTDIGIT BETWEEN '"+DToS(cPerDE)+"' AND '"+DToS(cPerAte)+"' "
		If !Empty(AllTrim(TRB->ZL6_CENTRO))
			cTst += " AND D1.D1_CC = '"+TRB->ZL6_CENTRO+"' "
		EndIf
	
		If !Empty(AllTrim(TRB->ZL6_CFOP))
			cTst += " AND D1.D1_CF IN "+FormatIn(TRB->ZL6_CFOP,";")+" "
		EndIf
	
		If !Empty(AllTrim(TRB->ZL6_CODPRO))
			cTst += " AND D1.D1_COD = '"+TRB->ZL6_CODPRO+"' " 
		EndIf
		
		If !Empty(AllTrim(TRB->ZL6_GRPPRO))
			cTst += " AND D1.D1_COD = B1.B1_COD "
			cTst += " AND B1.B1_GRUPO = '"+AllTrim(TRB->ZL6_GRPPRO)+"' "
			cTst += " AND B1.D_E_L_E_T_ = ' ' "
		EndIf
	
		cTst := ChangeQuery(cTst)

		If Select("TRB1") >0
			TRB1->(DBCloseArea())
		EndIf

		MPSysOpenQuery(cTst,"TRB1")
		DBSelectArea("TRB1")

		cFlUsa  	:= TRB->ZL6_FILIAL
		cCodApu 	:= GetSxeNum("ZLG","ZLG_CODAPU")
		dDtApu	 	:= DToS(cPerDE)
		cTpCust 	:= TRB->ZL6_TPCUS
		cGrpCus	:= TRB->ZL6_GRPCUS
		cEvent		:= TRB->ZL6_CODEVE
		cSubEve 	:= TRB->ZL6_SUBEVE

		While TRB1->(!Eof())

			nQtd	 += TRB1->QUANTIDADE
			nPrcLt  := 0
			nPrcEve += TRB1->TOTAL_NF
			nPrcIcm	+= TRB1->ICMS
			nTot	 += TRB1->CUSTO
			TRB1->(DBSkip())
		EndDo

		aVlrs := {}

		aAdd(aVlrs,{cFlUsa,cCodApu,dDtApu,cTpCust,cGrpCus,nQtd,nPrcLt,nPrcEve,nTot,cEvent,cSubEve})
	EndIf
ElseIf cFun = '2'

	If !Empty(AllTrim(TRB->ZL6_TPMOV)) .Or. !Empty(AllTrim(TRB->ZL6_CENTRO)) .Or. !Empty(AllTrim(TRB->ZL6_CODPRO))
		cTst := " SELECT D3.D3_COD AS CODIGO_PRODUTO, D3.D3_CC AS CENTRO_CUSTO,D3.D3_QUANT AS QUANTIDADE, "
		cTst += " D3.D3_CUSTO1 AS TOTAL "
		cTst += " FROM " + RetSqlName("SD3") + " D3 "
		cTst += " WHERE D_E_L_E_T_ = ' ' "
		cTst += " AND D3_FILIAL = '"+TRB->ZL6_FILIAL+"' "
		cTst += " AND D3_ESTORNO <> 'S' "
	
		If !Empty(AllTrim(TRB->ZL6_TPMOV))
			cTst += " AND D3_TM = '"+TRB->ZL6_TPMOV+"'  "
		EndIf
	
		If !Empty(AllTrim(TRB->ZL6_CENTRO))
			cTst += " AND D3_CC = '"+TRB->ZL6_CENTRO+"' "
		EndIf
	
		If !Empty(AllTrim(TRB->ZL6_CODPRO))
			cTst += " AND D3_COD = '"+TRB->ZL6_CODPRO+"' "
		EndIf

		If !Empty(AllTrim(TRB->ZL6_GRPPRO))
			cTst += " AND D3.D3_COD = B1.B1_COD "
			cTst += " AND B1.B1_GRUPO = '"+AllTrim(TRB->ZL6_GRPPRO)+"' "
			cTst += " AND B1.D_E_L_E_T_ = ' ' "
		EndIf

		cTst := ChangeQuery(cTst)

		If Select("TRB1") >0
			TRB->(DBCloseArea())
		EndIf

		MPSysOpenQuery(cTst,"TRB1")
		DBSelectArea("TRB1")

		cFlUsa  	:= TRB->ZL6_FILIAL
		cCodApu 	:= GetSxeNum("ZLG","ZLG_CODAPU")
		dDtApu	 	:= DToS(cPerDE)
		cTpCust 	:= TRB->ZL6_TPCUS
		cGrpCus	:= TRB->ZL6_GRPCUS
		cEvent		:= TRB->ZL6_CODEVE
		cSubEve 	:= TRB->ZL6_SUBEVE

		While TRB1->(!Eof())

			nQtd	 += TRB1->QUANTIDADE
			nPrcLt  := 0
			nPrcEve += TRB1->TOTAL
			TRB1->(DBSkip())
		EndDo
	
		aVlrs := {}

		aAdd(aVlrs,{cFlUsa,cCodApu,dDtApu,cTpCust,cGrpCus,nQtd,nPrcLt,nPrcEve,nTot,cEvent,cSubEve})
	EndIf

ElseIf cFun == '3'

	If !Empty(AllTrim(TRB->ZL6_NATURE))
		cTst := " SELECT E2_VALOR FROM " + RetSqlName("SE2") + " E2
		cTst += " WHERE E2.D_E_L_E_T_ = ' ' "
		cTst += " AND E2.E2_FILIAL = '"+TRB->ZL6_FILIAL+"' "
		cTst += " AND E2.E2_NATUREZ = '"+TRB->ZL6_NATURE+"' " 
	
		cTst := ChangeQuery(cTst)

		If Select("TRB1") >0
			TRB1->(DBCloseArea())
		EndIf

		MPSysOpenQuery(cTst,"TRB1")
		DBSelectArea("TRB1")

		cFlUsa  	:= TRB->ZL6_FILIAL
		cCodApu 	:= GetSxeNum("ZLG","ZLG_CODAPU")
		dDtApu	 	:= DToS(cPerDE)
		cTpCust 	:= TRB->ZL6_TPCUS
		cGrpCus	:= TRB->ZL6_GRPCUS
		cEvent		:= TRB->ZL6_CODEVE
		cSubEve 	:= TRB->ZL6_SUBEVE

		While TRB1->(!Eof())

			nQtd	 += 0
			nPrcLt  := 0
			nPrcEve += TRB1->E2_VALOR
			TRB1->(DBSkip())
		EndDo
	
		aVlrs := {}

		aAdd(aVlrs,{cFlUsa,cCodApu,dDtApu,cTpCust,cGrpCus,nQtd,nPrcLt,nPrcEve,nTot,cEvent,cSubEve})
	EndIf
EndIf

Return aVlrs
