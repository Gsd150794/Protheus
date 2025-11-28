/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |25/04/2023| Chamado 43284. Incluidas 8 novas colunas para impressao.
Alex Wallauer |08/02/2024| Chamado 44782. Jerry. Ajustes para a nova opcao de tipo de entrega: O = Agendado pelo Op.Log.
Lucas Borges  |02/10/2025| Chamado 51526. Modificada forma para recuperar a matrícula do usuário.
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include 'TOPCONN.CH'

/*
===============================================================================================================================
Programa----------: ROMS050
Autor-------------: Julio de Paula Paz
Data da Criacao---: 02/01/2018
Descrição---------: Relatório Relatório Lista de Pedidos Liberados. Chamado 22940.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ROMS050()

Local oReport := Nil
Private cPerg := "ROMS050"
Private aOrd  := {"Filial","Pedido","Entrega","Cliente","Estado"} 

Pergunte(cPerg,.T.)

oReport := ROMS050P(cPerg)
oReport:PrintDialog()

Return

/*
===============================================================================================================================
Programa----------: ROMS050P
Autor-------------: Julio de Paula PAz
Data da Criacao---: 02/01/2018
Descrição---------: Função que faz a montagem do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS050P(cNome)

Local oReport	:= Nil
Local oSection1	:= Nil
	
oReport:= TReport():New("ROMS050","Relatório Lista de Pedidos Liberados.","ROMS050", {|oReport| ROMS050R(oReport)},"Emissao do Relatório Lista de Pedidos Liberados.")
oReport:SetLandscape()
oReport:SetTotalInLine(.F.)

oSection1:= TRSection():New(oReport, "Pedidos Liberados", {"TRBSC9"},aOrd , .F., .T.)

TRCell():New(oSection1,"C9_FILIAL"	,"TRBSC9","Filial"  	      ,"@!",06)
TRCell():New(oSection1,"C9_PEDIDO"  ,"TRBSC9","Pedido"	      ,"@!",10)
TRCell():New(oSection1,"C5_I_OPER"	,"TRBSC9","Oper."	         ,"@!",05)
TRCell():New(oSection1,"C5_I_DTENT"	,"TRBSC9","Dt.Entrega"	   ,"@!",10)
TRCell():New(oSection1,"C5_I_AGEND"	,"TRBSC9","Tp.Entrega"	   ,"@!",10)//NOVO
TRCell():New(oSection1,"C5_I_LIBL"	,"TRBSC9","Dt.Venc.Credito","@!",10)
TRCell():New(oSection1,"C9_CLIENTE"	,"TRBSC9","Cod.Cli"	      ,"@!",06)
TRCell():New(oSection1,"C9_LOJA"    ,"TRBSC9","Loja"	         ,"@!",04)
TRCell():New(oSection1,"C5_I_NOME"  ,"TRBSC9","Cliente"	      ,"@!",40)
TRCell():New(oSection1,"A1_NREDUZ"  ,"TRBSC9","Nome Fantasia"  ,"@!",40)//NOVO
TRCell():New(oSection1,"C9_PRODUTO" ,"TRBSC9","Cód.Produto"	   ,"@!",10)
TRCell():New(oSection1,"B1_DESC"    ,"TRBSC9","Desc. Produto"	,"@!",40)
TRCell():New(oSection1,"C9_LOCAL"   ,"TRBSC9","Local"	         ,"@!",05)
TRCell():New(oSection1,"C9_QTDLIB"  ,"TRBSC9","Qtd 1a UM"      ,"@E 999,999,999,999.99",17)
TRCell():New(oSection1,"C6_UM"      ,"TRBSC9","1a UM"          ,"@!",05)//NOVO
TRCell():New(oSection1,"C9_QTDLIB2" ,"TRBSC9","Qtd 2a UM"      ,"@E 999,999,999,999.99",17)
TRCell():New(oSection1,"C6_SEGUM"   ,"TRBSC9","2a UM"          ,"@!",05)//NOVO
TRCell():New(oSection1,"TOTAL_ITEM" ,"TRBSC9","Total do Item"  ,"@E 999,999,999,999.99",17)//NOVO
TRCell():New(oSection1,"QTD_PALLET" ,"TRBSC9","Qtd Pallet"     ,"@E 999,999,999,999"   ,17)//NOVO
TRCell():New(oSection1,"PESO_BRUTO" ,"TRBSC9","Peso Bruto"     ,"@E 999,999,999,999.99",17)//NOVO
TRCell():New(oSection1,"C5_I_EST"  	,"TRBSC9","Estado"		   ,"@!",10)    
TRCell():New(oSection1,"C5_I_MUN"  	,"TRBSC9","Cidade"		   ,"@!",10)    
TRCell():New(oSection1,"C5_VEND3"  	,"TRBSC9","Nome Gerente"   ,"@!",40)//NOMO
TRCell():New(oSection1,"SITUACAO"  	,"TRBSC9","Situação"	      ,"@!",10)
TRCell():New(oSection1,"ZZL_NOME"   ,"TRBSC9","Liberado Por "  ,"@!",30)  
TRCell():New(oSection1,"C9_I_DTLIB" ,"TRBSC9","Dt Liberação"   ,"@!",10)
TRCell():New(oSection1,"C9_I_HRLIB" ,"TRBSC9","Hr Liberação"   ,"@!",10)
TRCell():New(oSection1,"C9_CARGA"   ,"TRBSC9","Ordem de Carga"	,"@!",10)
TRCell():New(oSection1,"C9_NFISCAL" ,"TRBSC9","Nota Fiscal"  	,"@!",10)
TRCell():New(oSection1,"C9_SERIENF" ,"TRBSC9","Série"	         ,"@!",10)


Return(oReport)

/*
===============================================================================================================================
Programa----------: ROMS050P
Autor-------------: Julio de Paula PAz
Data da Criacao---: 02/01/2018
Descrição---------: Função que imprime o relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS050R(oReport)

Local oSection1 := oReport:Section(1)
Local cQry1		:= ""
Local _cSituacao
Local _nTotRegs

Private aheader := {}
Private acols := {}

cQry1 := " SELECT C9_FILIAL, C5_I_TRCNF, C5_I_FLFNC, C5_I_FILFT, C9_PEDIDO,C5_I_OPER,C5_I_LIBL, C5_I_DTENT, C5_I_EST, C5_I_MUN,"
cQry1 += " C9_NFISCAL, C9_CLIENTE, C9_I_DTLIB, C9_I_HRLIB, C9_BLEST, C9_CARGA, C9_PRODUTO, C9_LOCAL, C9_QTDLIB, C9_QTDLIB2, "
cQry1 += " C9_LOJA, C5_I_NOME, C5_EMISSAO, C9_I_USLIB, C9_SERIENF,  "
cQry1 += " C5_I_AGEND, C9_ITEM , C5_VEND3 "
cQry1 += " FROM " + RetSqlName("SC9") + " SC9, "  + RetSqlName("SC5") + " SC5 " //, "
cQry1 += " WHERE SC5.D_E_L_E_T_ = ' ' "
cQry1 += "   AND SC9.D_E_L_E_T_ = ' ' "
cQry1 += "   AND SC5.C5_FILIAL  = SC9.C9_FILIAL "
cQry1 += "   AND SC5.C5_NUM     = SC9.C9_PEDIDO "   
 
If !Empty(AllTrim(MV_PAR01))	
	If Len(AllTrim(MV_PAR01)) <= 2
	   cQry1 += " AND C9_FILIAL = '" + AllTrim(MV_PAR01) + "' "
	Else
	   cQry1 += " AND C9_FILIAL IN " +  FormatIn(MV_PAR01,";") + " "
	EndIf	  
EndIf        

// Dt Liberacao de -- MV_PAR09
If !Empty(MV_PAR09) 
   cQry1 += " AND C9_DATALIB  >= '" + DToS(MV_PAR09) + "' "
EndIf

// Dt Liberacao ate -- MV_PAR10
If !Empty(MV_PAR10)
   cQry1 += " AND C9_DATALIB  <= '" + DToS(MV_PAR10) + "' "
EndIf

	
// Estado -- MV_PAR02
If !Empty(AllTrim(MV_PAR02))
	If Len(AllTrim(MV_PAR02)) <= 2
	   cQry1 += "  AND C5_I_EST = '" + AllTrim(MV_PAR02)  + "' "
	Else
	   cQry1 += "  AND C5_I_EST IN " +  FormatIn(MV_PAR02,";")  + " "
	EndIf
EndIf	

// Pedido de -- MV_PAR03
If !Empty(MV_PAR03)
	cQry1 += " AND C9_PEDIDO >= '" + MV_PAR03 + "' "
EndIf

// Pedido ate -- MV_PAR04
If !Empty(MV_PAR04)
	cQry1 += " AND C9_PEDIDO <= '" + MV_PAR04 + "' "
EndIf

// Cliente de -- MV_PAR05
If !Empty(MV_PAR05) 
   cQry1 += " AND C9_CLIENTE >= '" + MV_PAR05 + "' "
EndIf

// Loja de -- MV_PAR06
If !Empty(MV_PAR06)
   cQry1 += " AND C9_LOJA >= '" + MV_PAR06 + "' "
EndIf

// Cliente ate -- MV_PAR07
If !Empty(MV_PAR07)
   cQry1 += " AND C9_CLIENTE <= '" + MV_PAR07 + "' "
EndIf

// Loja ate -- MV_PAR08
If !Empty(MV_PAR08) 
   cQry1 += " AND C9_LOJA <= '" + MV_PAR08 + "' "
EndIf

// Situação Pedido -- MV_PAR11
If !Empty(MV_PAR11) 
	If MV_PAR11 == 1 // Faturado
		cQry1 += " AND C9_NFISCAL <> ' ' "       
	EndIf
	If MV_PAR11 == 2 // Nao Faturado      
		cQry1 += " AND C9_NFISCAL = ' ' "       
	EndIf      
EndIf

//================================================================================
// Filtra Produto
//================================================================================
If !Empty( MV_PAR12 )         
	If Len(AllTrim(MV_PAR12)) <= 11
		cQry1 += " AND C9_PRODUTO = '" + AllTrim(MV_PAR12) + "' " 		
	Else
		cQry1 += " AND C9_PRODUTO IN   "  + FormatIn( MV_PAR12 , ";" )
	EndIf
EndIf

If oReport:nOrder == 1
	cQry1 += "	ORDER BY C9_FILIAL,C9_PEDIDO "
ElseIf oReport:nOrder == 2
	cQry1 += "	ORDER BY C9_PEDIDO "
ElseIf oReport:nOrder == 3
	cQry1 += "	ORDER BY C9_DATALIB,C9_PEDIDO "
ElseIf oReport:nOrder == 4
	cQry1 += "	ORDER BY C9_CLIENTE,C9_LOJA,C9_PEDIDO "
ElseIf oReport:nOrder == 5
	cQry1 += "	ORDER BY C5_I_EST,C5_NUM "
EndIf

If Select("TRBSC9") <> 0
	DBSelectArea("TRBSC9")
	DBCloseArea()
EndIf

TCQUERY cQry1 NEW ALIAS "TRBSC9"
	
DBSelectArea("TRBSC9")
TRBSC9->(DBGoTop())

DAI->(DBSetOrder(4)) // ORDEM 4 - DAI_FILIAL+DAI_PEDIDO+DAI_COD+DAI_SEQCAR          
SC9->(DBSetOrder(1)) // ORDEM 1 - C9_FILIAL+C9_PEDIDO+C9_ITEM+C9_SEQUEN+C9_PRODUTO+C9_BLEST+C9_BLCRED                                                            
SC6->(DBSetOrder(1)) // ORDEM 1 - C6_FILIAL+C6_NUM+C6_ITEM+C6_PRODUTO  
SB1->(DBSetOrder(1)) // ORDEM 1 - B1_FILIAL  + B1_COD


Count To _nTotRegs
_cTot:=AllTrim(Str(_nTotRegs))		
_nConta:=0
oReport:SetMeter(_nTotRegs)
TRBSC9->(DBGoTop())

While !TRBSC9->(Eof())

   oReport:IncMeter()
   _nConta++
   oReport:SetMsgPrint("Imprimindo Registro : "+AllTrim(Str(_nConta)) +" de "+ _cTot)
   //IncProc("Imprimindo Filial " + AllTrim(TRBSC9->C9_FILIAL) + " - " + AllTrim(FWFilialName(cEmpAnt,TRBSC9->C9_FILIAL)))

   If oReport:Cancel()
      Exit
   EndIf
   
   _cSituacao := "LIBERADO"
   If !Empty(TRBSC9->C9_NFISCAL)
      _cSituacao := "FATURADO"
   ElseIf !Empty(TRBSC9->C9_CARGA)
      _cSituacao := "EM OC"    
   ElseIf !Empty(TRBSC9->C9_BLEST) .And. TRBSC9->C9_BLEST <> '10'
	  _cSituacao := "BLQ.ESTQ"
   EndIf

	_cTipoEntrega := U_TipoEntrega(TRBSC9->C5_I_AGEND)
	//If AllTrim(TRBSC9->C5_I_ AGEND) == "A"
	//	_cTipoEntrega := "A=AGENDADA"
	//ElseIf AllTrim(TRBSC9->C5_I_ AGEND) == "I"
	//	_cTipoEntrega := "I=IMEDIATA"
	//ElseIf AllTrim(TRBSC9->C5_I_ AGEND) == "M"
	//	_cTipoEntrega := "M=AGENDADA C/MULTA"
	//ElseIf AllTrim(TRBSC9->C5_I_ GEND) == "P"
	//	_cTipoEntrega := "P=AGUARD. AGENDA"
	//EndIf

   //=========================================================
   // Filtro por Situação Pedido -- MV_PAR11
   //=========================================================

   oSection1:Init()
   

   SC6->(DBSeek(TRBSC9->C9_FILIAL+TRBSC9->C9_PEDIDO+TRBSC9->C9_ITEM+TRBSC9->C9_PRODUTO ))
   SB1->(DBSeek(xFilial("SB1")+TRBSC9->C9_PRODUTO ))

   oSection1:Cell("C9_FILIAL") :SetValue(TRBSC9->C9_FILIAL)
   oSection1:Cell("C9_PEDIDO") :SetValue(TRBSC9->C9_PEDIDO)   
   oSection1:Cell("C5_I_OPER") :SetValue(TRBSC9->C5_I_OPER)   
   oSection1:Cell("C5_I_DTENT"):SetValue(SToD(TRBSC9->C5_I_DTENT))
   oSection1:Cell("C5_I_LIBL") :SetValue(SToD(TRBSC9->C5_I_LIBL))
   oSection1:Cell("C9_CLIENTE"):SetValue(TRBSC9->C9_CLIENTE)
   oSection1:Cell("C9_LOJA")	 :SetValue(TRBSC9->C9_LOJA)
   oSection1:Cell("C5_I_NOME") :SetValue(TRBSC9->C5_I_NOME)    

   oSection1:Cell("C5_I_AGEND"):SetValue(_cTipoEntrega)                                                                   //NOVO
   oSection1:Cell("A1_NREDUZ") :SetValue(Posicione("SA1",1,xFilial("SA1")+TRBSC9->C9_CLIENTE+TRBSC9->C9_LOJA,"A1_NREDUZ"))//NOVO
   oSection1:Cell("C6_UM")     :SetValue(SC6->C6_UM)                                                                      //NOVO
   oSection1:Cell("C6_SEGUM")  :SetValue(SC6->C6_SEGUM)                                                                   //NOVO
   oSection1:Cell("TOTAL_ITEM"):SetValue(SC6->C6_QTDVEN * SC6->C6_PRCVEN)                                                 //NOVO
   oSection1:Cell("QTD_PALLET"):SetValue(SC6->C6_I_QPALT)                                                                 //NOVO
   oSection1:Cell("PESO_BRUTO"):SetValue(SC6->C6_QTDVEN * SB1->B1_PESBRU)                                                 //NOVO
   oSection1:Cell("C5_VEND3")	 :SetValue(Posicione("SA3",1,xFilial("SA3")+TRBSC9->C5_VEND3,"A3_NOME"))                    //NOVO

   oSection1:Cell("C5_I_EST")	 :SetValue(TRBSC9->C5_I_EST)
   oSection1:Cell("C5_I_MUN")	 :SetValue(TRBSC9->C5_I_MUN)   
   oSection1:Cell("SITUACAO")	 :SetValue(_cSituacao)
   oSection1:Cell("ZZL_NOME")	 :SetValue(Posicione("ZZL",1,xFilial("ZZL")+AllTrim(TRBSC9->C9_I_USLIB),"ZZL_NOME"))
   oSection1:Cell("C9_I_DTLIB"):SetValue(SToD(TRBSC9->C9_I_DTLIB))
   oSection1:Cell("C9_I_HRLIB"):SetValue(TRBSC9->C9_I_HRLIB)
   oSection1:Cell("C9_CARGA")	 :SetValue(TRBSC9->C9_CARGA)   
   oSection1:Cell("C9_NFISCAL"):SetValue(TRBSC9->C9_NFISCAL)   
   oSection1:Cell("C9_SERIENF"):SetValue(TRBSC9->C9_SERIENF)   
   oSection1:Cell("C9_PRODUTO"):SetValue(TRBSC9->C9_PRODUTO)      
   oSection1:Cell("B1_DESC")	 :SetValue(SB1->B1_DESC)      
   oSection1:Cell("C9_LOCAL")	 :SetValue(TRBSC9->C9_LOCAL)   
   oSection1:Cell("C9_QTDLIB") :SetValue(TRBSC9->C9_QTDLIB)
   oSection1:Cell("C9_QTDLIB2"):SetValue(TRBSC9->C9_QTDLIB2)
 
   oSection1:PrintLine()

   TRBSC9->(DBSkip())

End
oSection1:Finish()
oSection1:Enable()

Return
