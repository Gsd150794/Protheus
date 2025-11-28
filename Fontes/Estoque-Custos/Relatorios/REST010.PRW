/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |13/07/2023| Chamado 44351. Correção de error.log da variavel nPosC.
Julio Paz     |20/08/2024| Chamado 48228. Incluir uma nova coluna para informar o grupo de produtos.
Lucas Borges  |08/10/2024| Chamado 48465. Retirada manipulação do SX1
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include 'TOPCONN.CH'

/*
===============================================================================================================================
Programa----------: REST010
Autor-------------: Alex Wallauer
Data da Criacao---: 23/05/2017
Descrição---------: Relatório de baixas consolidadas do almoxarifado - CHAMADO 20155
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function REST010()
Local oReport	:= nil
	Private _cPerg	:= "REST010"
Private aOrd	:= {} 

While .T.

   If !Pergunte(_cPerg,.T.)
      Return .F.
   EndIf

   If MV_PAR01 > MV_PAR02
      MSGSTOP("Periodo de datas invalido.")
      Loop
   EndIf
   
   If MV_PAR04 > MV_PAR05
      MSGSTOP("Periodo de produtos invalido.")
      Loop
   EndIf
   
   If MV_PAR06 > 12
      MSGSTOP("Media retroativa maior que 12 meses.")
      Loop
   EndIf
   
   Exit
   
EndDo

oReport := RptDef(_cPerg)
oReport:PrintDialog()  

//========================================================================
// Grava log de Relatório de Relatório Clientes com Contrato.
//======================================================================== 
U_ITLOGACS('REST010')

Return

/*
===============================================================================================================================
Programa----------: RptDef
Autor-------------: Alex Wallauer
Data da Criacao---: 23/05/2017
Descrição---------: Função que faz a montagem do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RptDef(cNome)
Local oReport	:= Nil
Local oSection1	:= Nil
//Local bReport :={|oReport| FWMsgRun( , {|oProc|  ReportPrint(oReport,oProc)}, "Aguarde!" , 'Lendo Dados...' ) }
Local bReport   :={|oReport| ReportPrint(oReport,) }
	
oReport:= TReport():New("REST010","Relatório de baixas consolidadas do almoxarifado.","REST010", bReport ,"Baixas consolidadas do almoxarifado.")

oReport:SetLandscape()

oSection1 := TRSection():New(oReport, "Movimentações por Produto", {"TRB"},aOrd , .F., .T.)

	TRCell():New(oSection1,"PRODUTO"	,"TRB","Produto"  		    ,"@!",50) // 100
	TRCell():New(oSection1,"GRUPO"	    ,"TRB","Grupo"  		    ,"@!",25)
	TRCell():New(oSection1,"DESCR"	    ,"TRB","Descrição " 	    ,"@!",100)
	TRCell():New(oSection1,"DESCR_DET" 	,"TRB","Descrição Detalhada","@!",100)
	TRCell():New(oSection1,"TOTSAIDA"   ,"TRB","Total Saida"   		,"@E 99999,999,999.9999",20) // 25
	TRCell():New(oSection1,"MEDIA"  	,"TRB","Media "+AllTrim(Str(MV_PAR06))+" Meses","@E 99999,999,999.9999",20) // 25
	TRCell():New(oSection1,"LOCAL"      ,"TRB","Localização"		,"@!",50)
	TRCell():New(oSection1,"ESTSEG"     ,"TRB","Est. Mínimo"		,PesqPict( "SBZ", "BZ_ESTSEG" ),50)
	TRCell():New(oSection1,"EMAX"       ,"TRB","Est. Máximo"		,PesqPict( "SBZ", "BZ_EMAX"   ),50)
	If MV_PAR08 = 1
		TRCell():New(oSection1, "BZ_PE"     ,"TRB","Lead Time"          ,PesqPict( "SBZ", "BZ_PE     "),50)//VALIDAR SOMENTE SE O MV_PAR08 == 1 - SIM
	EndIf
	TRCell():New(oSection1,"PRCUNIT"	,"TRB","Custo Unit."		,PesqPict( "SB2", "B2_CM1" ),20) //25
	TRCell():New(oSection1,"VLRTOTAL"	,"TRB","Saldo atual"		,"@E 99999,999,999.9999",20) // 25
	TRCell():New(oSection1,"QTDE_TOT"	,"TRB","Qtde em PC" 		,"@E 99999,999,999.9999",20) // 25
	TRCell():New(oSection1,"QTDE_ABE"	,"TRB","Qtde Aberta SC" 	,"@E 99999,999,999.9999",20) // 25
	TRCell():New(oSection1,"CENTROC"    ,"TRB","Centro de Custo"	,"@!",50)
	TRCell():New(oSection1,"ULT_DATA"   ,"TRB","Ultima Data"	    ,"@D",10)
	If MV_PAR08 = 1
		TRCell():New(oSection1,"STATUS"     ,"TRB","Status"         ,"@!",100)
		TRCell():New(oSection1,"QTDSUG"     ,"TRB","Qtde Sugerida"  ,"@E 99,999,999.999",25)
	EndIf


oSection2 := TRSection():New(oReport, "Movimentações por CC", {"TRB"},aOrd , .F., .T.)

	TRCell():New(oSection2,"COD_CC"     ,"TRB","Codigo CC"			,"@!",50)
	TRCell():New(oSection2,"CENTROC"    ,"TRB","Centro de Custo"	,"@!",50)
	TRCell():New(oSection2,"TOTSAIDA"   ,"TRB","Total Saida"   		,"@E 9,9999,999,999.9999",50)
	TRCell():New(oSection2,"CUSTOTOT"   ,"TRB","Custo Total"   		,"@E 9,9999,999,999.9999",50)


Return(oReport)

/*
===============================================================================================================================
Programa----------: RptDef
Autor-------------: Alex Wallauer
Data da Criacao---: 23/05/2017
Descrição---------: Função que imprime o relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ReportPrint(oReport,oProc)

Local oSection1 := oReport:Section(1)
Local oSection2 := oReport:Section(2)
Local cQryMedia := ""//MEDIA
Local cQryData  := ""//SOMATORIA
Local cQryRec   := ""
Local cQryUDT   := ""
Local cQry		:= ""//=
Local cQryM		:= ""//MEDIA
Local cQryS		:= ""//SOMATORIA
Local cQryOrdem := ""//=
Local S2
Local nResult := 0
Local nQtdSug := 0

oSection1:Init()
oReport:SetMeter(0)

Begin Sequence
	
    oReport:IncMeter()

 	cQry += " FROM " + RetSqlName("SD3") + " D3 "
	cQry += "WHERE D3.D_E_L_E_T_ = ' ' AND D3.D3_TM = '560' AND D3_ESTORNO <> 'S' AND D3.D3_FILIAL = '"+xFilial("SD3")+"' "

  	If !Empty(MV_PAR04)
	   cQry += "  AND D3_COD >= '" + AllTrim(MV_PAR04) + "' "
    EndIf

  	If !Empty(MV_PAR05)
	   cQry += "  AND D3_COD <= '" + AllTrim(MV_PAR05) + "' "
    EndIf

	If !Empty(MV_PAR07)
		cQry += "  AND D3.D3_LOCAL IN " + FormatIn( AllTrim(MV_PAR07) , ";" )
	EndIf

	If !Empty(MV_PAR03)
		cQry += "  AND D3.D3_GRUPO IN " + FormatIn( AllTrim(MV_PAR03) , ";" )
 	EndIf

    oReport:SetMsgPrint("1/9-Lendo dados da SD3...")
//******************  MEDIA
	If Select("TRB") <> 0
	   TRB->(DBCloseArea())
	EndIf

	cQryMedia  := "SELECT D3.D3_FILIAL , D3.D3_COD , D3.D3_LOCAL, D3.D3_GRUPO , SUM(D3_QUANT) MEDIA "//MEDIA  
    //_dDAtaIncio:=(MV_PAR01 - (MV_PAR06*30))
    _dDAtaIncio:= Date() - (MV_PAR06*30) //Alteração solicitada pelo Coordenador geral dos almoxarifados 32048.
	cQryM      := " AND D3.D3_EMISSAO BETWEEN '" + DToS(_dDAtaIncio) + "' AND '" + DToS(DATE()) + "' "//MEDIA
  	cQryOrdem  := " GROUP BY D3.D3_FILIAL , D3.D3_COD , D3.D3_LOCAL, D3.D3_GRUPO  " 
  	cQryOrdem  += " ORDER BY D3.D3_FILIAL , D3.D3_COD , D3.D3_LOCAL "
	
	TCQUERY cQryMedia + cQry + cQryM + cQryOrdem  NEW ALIAS "TRB"//MEDIA

    oReport:SetMsgPrint("2/9-Lendo dados da Media...")
    _nTot:=0
    COUNT TO _nTot
  	oReport:SetMeter(_nTot)
    _cTot:=AllTrim(Str(_nTot))
    _nTam:=Len(_cTot)+1
    _nConta:=0
    TRB->(DBGoTop())
    _aMedia:={}
   	While !TRB->(Eof())
       _nConta++
       oReport:IncMeter()
       oReport:SetMsgPrint("3/9-Acumulando Media: "+AllTrim(Str(_nConta,_nTam)) +" de "+ _cTot)
   	   aAdd(_aMedia,{TRB->D3_FILIAL+TRB->D3_COD+TRB->D3_LOCAL,;//1
   	                                    (TRB->MEDIA/MV_PAR06),;//2
   	                                               TRB->MEDIA,;//3
   	                                                      " ",;//4
   	                                                      " "})//5
	   TRB->(DBSkip())
	EndDo
		
//******************  MAIOR DATA
    oReport:SetMsgPrint("4/9-Lendo dados da SD3 para Media...")

	If Select("TRB") <> 0
	   TRB->(DBCloseArea())
	EndIf
	
	cQryData:= "SELECT D3.D3_FILIAL , D3.D3_COD , D3.D3_LOCAL, D3.D3_GRUPO, MAX(D3.D3_EMISSAO) ULTDATA "//ULTIMA DATA  
	cQryS   := "  AND D3.D3_EMISSAO BETWEEN '" + DToS(MV_PAR01) + "' AND '" + DToS(MV_PAR02) + "' "//UTILIZADO A SOMATORIA E MAIOR DATA

	TCQUERY cQryData + cQry + cQryS + cQryOrdem  NEW ALIAS "TRB"//MAIOR DATA

	_nTot:=0
    COUNT TO _nTot
  	oReport:SetMeter(_nTot)

    cQryRec := "SELECT D3.D3_FILIAL , D3.D3_COD , D3.D3_LOCAL, D3.D3_GRUPO, MAX(D3.R_E_C_N_O_) REC_SD3 "//ULTIMO CC DENTRO DA MAIOR DATA

    _cTot:=AllTrim(Str(_nTot))
    _nTam:=Len(_cTot)+1
    _nConta:=0

    TRB->(DBGoTop())
   	While !TRB->(Eof())

       _nConta++
  	   oReport:IncMeter()
       oReport:SetMsgPrint("5/9-Lendo Media, Registro: "+AllTrim(Str(_nConta,_nTam)) +" de "+ _cTot)
     //******************  MAIOR REC
	   cQryUDT := " AND D3.D3_EMISSAO = '" + TRB->ULTDATA + "' "
	   cQryUDT += " AND D3.D3_FILIAL||D3.D3_COD||D3.D3_LOCAL = '"+TRB->D3_FILIAL+TRB->D3_COD+TRB->D3_LOCAL+"' "
	   TCQUERY cQryRec + cQry + cQryUDT + cQryOrdem  NEW ALIAS "TRB_REC"//MAIOR RECNO  TRAZ  O ULTIMO CC UTILIZADO

	   If TRB_REC->REC_SD3 # 0 .And. (nPosC := nPos:=aScan(_aMedia, {|M| M[1] == TRB->D3_FILIAL+TRB->D3_COD+TRB->D3_LOCAL } )) # 0 
	       SD3->(DBGoTo(TRB_REC->REC_SD3))
	      _aMedia[nPos,4]:=SD3->D3_CC
	      _aMedia[nPos,5]:=SD3->D3_EMISSAO
	   EndIf

	   TRB_REC->(DBCloseArea())
    //******************  MAIOR REC

	   DBSelectArea("TRB")

	   TRB->(DBSkip())
	EndDo
		
//******************  SOMATORIA
	If Select("TRB") <> 0
	   TRB->(DBCloseArea())
	EndIf
    oReport:SetMsgPrint("6/9-Lendo dados da SD3 de Custo...")

	cQrySoma:= "SELECT D3.D3_FILIAL , D3.D3_COD , D3.D3_LOCAL, D3.D3_GRUPO, SUM(D3_QUANT) TOTSAIDA, SUM(D3_CUSTO1) CUSSAIDA "//SOMATORIA

	TCQUERY cQrySoma+cQry+cQryS+cQryOrdem NEW ALIAS "TRB"//SOMATORIA

	SBZ->( DBSetOrder(6) )
	SB2->( DBSetOrder(1) )

	cQry1 := "SELECT SUM(C7_QUANT) - SUM(C7_QUJE) QTD_TOT "
	cQry1 += "FROM " + RetSqlName("SC7") + " C7 "
	cQry1 += "WHERE C7.D_E_L_E_T_ = ' ' "
	cQry1 += "  AND C7_RESIDUO = ' ' "
	cQry1 += "  AND C7_ENCER = ' ' "
	cQry1 += "  AND C7.C7_FILIAL = '"+xFilial("SC7")+"' "
	If !Empty(MV_PAR07)
		cQry1 += "  AND C7.C7_LOCAL IN " + FormatIn( AllTrim(MV_PAR07) , ";" )
	EndIf

    _cQuerySC := " SELECT SUM(C1_QUANT) QTD_TOT  "
    _cQuerySC += "        FROM " + RETSQLNAME("SC1") + " C1 "
    _cQuerySC += "        WHERE C1_FILIAL= '"+xFilial("SC1")+"' AND  C1_PEDIDO = ' ' AND D_E_L_E_T_ = ' ' AND C1_RESIDUO <> 'S' AND C1_QUANT > C1_QUJE "
	If !Empty(MV_PAR07)
		_cQuerySC += "  AND C1.C1_LOCAL IN " + FormatIn( AllTrim(MV_PAR07) , ";" )
	EndIf

	_nTot:=0
    COUNT TO _nTot
  	oReport:SetMeter(_nTot)
    _cTot:=AllTrim(Str(_nTot))
    _nTam:=Len(_cTot)+1
    _nConta:=0

	TRB->(DBGoTop())
	_aCustos:={}
    aAbertosSC:={}
    aAbertosPC:={}
		
	While !TRB->(Eof())
       _nConta++
  	   oReport:IncMeter()
       oReport:SetMsgPrint("7/9-Imprimindo Produto "+AllTrim(Str(_nConta,_nTam)) +" de "+ _cTot)

	    SBZ->( DBSeek( TRB->D3_FILIAL + TRB->D3_COD + TRB->D3_LOCAL) )
	    SB2->( DBSeek( TRB->D3_FILIAL + TRB->D3_COD + TRB->D3_LOCAL) )

		oSection1:Cell("PRODUTO")  :SetValue(TRB->D3_COD)
		oSection1:Cell("GRUPO")    :SetValue(TRB->D3_GRUPO)      
		oSection1:Cell("DESCR")    :SetValue(SBZ->BZ_I_DESCR)		
		oSection1:Cell("DESCR_DET"):SetValue(SBZ->BZ_I_DETPR)
		oSection1:Cell("LOCAL")    :SetValue(SBZ->BZ_I_LOCAL)
		oSection1:Cell("ESTSEG")   :SetValue(SBZ->BZ_ESTSEG)
		oSection1:Cell("EMAX")     :SetValue(SBZ->BZ_EMAX)
		oSection1:Cell("TOTSAIDA") :SetValue(TRB->TOTSAIDA)
		If MV_PAR08 = 1
			oSection1:Cell("BZ_PE"):SetValue(SBZ->BZ_PE)
		EndIf
		If (nPosD := nPos:=aScan(_aMedia, {|M| M[1] == TRB->D3_FILIAL+TRB->D3_COD+TRB->D3_LOCAL } )) # 0 
		   oSection1:Cell("MEDIA")   :SetValue( _aMedia[nPos,2] )	   
//		   oSection1:Cell("TOTMEDIA"):SetValue( _aMedia[nPos,3] )//PARA TESTES
		   oSection1:Cell("CENTROC") :SetValue( Posicione("CTT",1,xFilial("CTT")+_aMedia[nPos,4],"CTT_DESC01") )
		   oSection1:Cell("ULT_DATA"):SetValue( _aMedia[nPos,5] )
		EndIf
		oSection1:Cell("PRCUNIT") :SetValue(SB2->B2_CM1)
		oSection1:Cell("VLRTOTAL"):SetValue(SB2->B2_QATU)

        If (nPosA := nPos:=aScan(aAbertosPC,{|A| A[1]==TRB->D3_COD } )) > 0
		   oSection1:Cell("QTDE_TOT"):SetValue(aAbertosPC[nPos,2])
		Else
		   nPosA := nPos:=MTLista(TRB->D3_COD,.T.)
		   oSection1:Cell("QTDE_TOT"):SetValue(aAbertosPC[nPos,2])
		EndIf   

        If (nPosB := nPos:=aScan(aAbertosSC,{|A| A[1]==TRB->D3_COD } )) > 0
		   oSection1:Cell("QTDE_ABE"):SetValue(aAbertosSC[nPos,2])
		Else
		   nPosB := nPos:=MTLista(TRB->D3_COD,.F.)
		   oSection1:Cell("QTDE_ABE"):SetValue(aAbertosSC[nPos,2])
		EndIf

		If MV_PAR08 = 1 
		
		    If (nPosC:=aScan(_aMedia, {|M| M[1] == TRB->D3_FILIAL+TRB->D3_COD+TRB->D3_LOCAL } ) ) > 0
			    nResult := (TRB->TOTSAIDA/_aMedia[nPosC,2])*SBZ->BZ_PE //(MED CONSUMO/PERIODO)*LEADTIME			
			Else
			    nResult := 0
			EndIf
			If (nResult > 0 .And. SBZ->BZ_ESTSEG = 0 ) 
				oSection1:Cell("QTDSUG")    :SetValue(nQtdSug)
				oSection1:Cell("STATUS")   :SetValue("REVALIDAR ESTOQUE MINIMO")
			ElseIf SB2->B2_QATU > SBZ->BZ_EMAX //ESTOQUE ATUAL > ESTOQUE MAXIMO
				oSection1:Cell("QTDSUG")    :SetValue(nQtdSug)
				oSection1:Cell("STATUS")  :SetValue("REVALIDAR ESTOQUE MAXIMO")
			ElseIf (SB2->B2_QATU < (IIf(nPosA <> 0,aAbertosPC[nPosA,2],0) + IIf(nPosB <> 0,aAbertosSC[nPosB,2],0) +  SBZ->BZ_ESTSEG)) ;
			  .Or. (SB2->B2_QATU = (SBZ->BZ_ESTSEG + IIf(nPosA <> 0, aAbertosPC[nPosA,2],0) + IIf(nPosB <> 0, aAbertosSC[nPosB,2],0)) ;
			  .And. SBZ->BZ_PE > 45)//(ESTOQUE ATUAL < (ESTOQUE MIN E SOMA DE PC E SC EM ABERTO), ESTOQUE ATUAL = ESTOQUE MIN E PC+SC = 0 E LEADTIME > 45
				//.AND. (Date() - CTOD(_aMedia[nPosD,5])) >= SBZ->BZ_PE
				oSection1:Cell("STATUS")   :SetValue("REPOR ESTOQUE")
				nQtdSug := SBZ->BZ_ESTSEG - (IIf(nPosA <> 0,aAbertosPC[nPosA,2],0) + IIf(nPosB <> 0,aAbertosSC[nPosB,2],0) + SB2->B2_QATU)
				If nQtdSug > 0
					oSection1:Cell("QTDSUG")    :SetValue(nQtdSug)
				ElseIf nQtdSug <= 0
					If (IIf(nPosA <> 0,aAbertosPC[nPosA,2],0) + IIf(nPosB <> 0,aAbertosSC[nPosB,2],0) + SB2->B2_QATU) >= SBZ->BZ_ESTSEG .And. (IIf(nPosA <> 0,aAbertosPC[nPosA,2],0) + IIf(nPosB <> 0,aAbertosSC[nPosB,2],0) + SB2->B2_QATU) <= SBZ->BZ_EMAX
						oSection1:Cell("QTDSUG")    :SetValue(0)
						oSection1:Cell("STATUS")   :SetValue("OK")
					ElseIf (IIf(nPosA <> 0,aAbertosPC[nPosA,2],0) + IIf(nPosB <> 0,aAbertosSC[nPosB,2],0) + SB2->B2_QATU) >= SBZ->BZ_EMAX
						oSection1:Cell("QTDSUG")    :SetValue(0)
						oSection1:Cell("STATUS")  :SetValue("REVALIDAR ESTOQUE MAXIMO")
					Else
						nQtdSug := Round(_aMedia[nPosC,2],0)
						If nQtdSug < _aMedia[nPosC,2]
							nQtdSug += 1
						EndIf
						oSection1:Cell("QTDSUG")    :SetValue(nQtdSug)
					EndIf
				EndIf
				
				
				nQtdSug := 0
			ElseIf SB2->B2_QATU = SBZ->BZ_ESTSEG .And. IIf(nPosA <> 0, aAbertosPC[nPosA,2],0) <> 0 ;
			.And. SB2->B2_QATU < (SBZ->BZ_ESTSEG +	IIf(nPosA <> 0, aAbertosPC[nPosA,2],0) + IIf(nPosB <> 0, aAbertosSC[nPosB,2],0))//Avaliar com o André -- (ESTOQUE ATUAL = ESTOQUE MIN) E (PC <> 0),  ESTOQUE ATUAL < (ESTOQUE MIN E SOMA DE PC E SC EM ABERTO)
				oSection1:Cell("QTDSUG")    :SetValue(nQtdSug)
				oSection1:Cell("STATUS")   :SetValue("CONFERIR PC")
			ElseIf SB2->B2_QATU = SBZ->BZ_ESTSEG .And. IIf(nPosB <> 0,aAbertosSC[nPosB,2],0) <> 0 ;
			.And. SB2->B2_QATU < (SBZ->BZ_ESTSEG + IIf(nPosA <> 0, aAbertosPC[nPosA,2],0) + IIf(nPosB <> 0, aAbertosSC[nPosB,2],0))//Avaliar com o André -- (ESTOQUE ATUAL = ESTOQUE MIN) E (SC <> 0),  ESTOQUE ATUAL < (ESTOQUE MIN E SOMA DE PC E SC EM ABERTO)
				oSection1:Cell("QTDSUG")    :SetValue(nQtdSug)
				oSection1:Cell("STATUS")   :SetValue("CONFERIR SC")
			Else
				oSection1:Cell("QTDSUG")    :SetValue(nQtdSug)
				oSection1:Cell("STATUS")   :SetValue("OK")
			EndIf

		EndIf

		oSection1:PrintLine()

		TRB->(DBSkip())
	
	EndDo

	If Select("TRB") <> 0
	   TRB->(DBCloseArea())
	EndIf

//////////////////////// 3-Movimentações por CC ////////////////////////////////////////////////////////////////////

	cQryCC     := "SELECT D3.D3_FILIAL , D3.D3_CC, SUM(D3_QUANT) TOTSAIDA , SUM(D3_CUSTO1) CUSSAIDA "
	cQryM      := " AND D3.D3_EMISSAO BETWEEN '" + DToS(MV_PAR01) + "' AND '" + DToS(MV_PAR02) + "' "
  	cQryOrdem  := " GROUP BY D3.D3_FILIAL , D3.D3_CC "
  	cQryOrdem  += " ORDER BY D3.D3_FILIAL , D3.D3_CC "
	
	TCQUERY cQryCC + cQry + cQryM + cQryOrdem  NEW ALIAS "TRB"

	_nTot:=0
    COUNT TO _nTot
  	oReport:SetMeter(_nTot)

	TRB->(DBGoTop())
	_aCustos:={}
		
	While !TRB->(Eof())

  	   oReport:IncMeter()
       oReport:SetMsgPrint("8/9-Acumulando CC: "+TRB->D3_CC)
       If nPos # 0
		   If (nPosCC:=aScan(_aCustos, {|M| M[1] == TRB->D3_CC } )) = 0 
              aAdd(_aCustos,{TRB->D3_CC,TRB->TOTSAIDA,TRB->CUSSAIDA})
           Else    
              _aCustos[nPosCC,2]+=TRB->TOTSAIDA
              _aCustos[nPosCC,3]+=TRB->CUSSAIDA
		   EndIf		
		EndIf
		TRB->(DBSkip())
	
	EndDo

    oSection2:Init()
  	oReport:SetMeter(Len(_aCustos))
    For S2 := 1 TO Len(_aCustos)
  	    oReport:IncMeter()
        oReport:SetMsgPrint("9/9-Imprimindo CC: "+_aCustos[S2,1])
        oSection2:Cell("COD_CC")  :SetValue(_aCustos[S2,1] )
        oSection2:Cell("CENTROC") :SetValue(Posicione("CTT",1,xFilial("CTT")+_aCustos[S2,1],"CTT_DESC01")  )
	    oSection2:Cell("TOTSAIDA"):SetValue(_aCustos[S2,2] )
	    oSection2:Cell("CUSTOTOT"):SetValue(_aCustos[S2,3] )
		oSection2:PrintLine()
    Next

//////////////////////// 3-Movimentações por CC ////////////////////////////////////////////////////////////////////

    If Select("TRB_REC") <> 0
	   TRB_REC->(DBCloseArea())
	EndIf
    If Select("TRB_SC7") <> 0
	   TRB_SC7->(DBCloseArea())
	EndIf
	If Select("TRB") <> 0
	   TRB->(DBCloseArea())
	EndIf

End Sequence

SBZ->( DBSetOrder(1) )

oSection1:Finish()
oSection1:Enable()

Return .T.

/*
===============================================================================================================================
Programa----------: MTLista
Autor-------------: Alex Wallauer Ferreira
Data da Criacao---: 05/07/2019
Descrição---------: Seleciona e lista itens em aberto
Parametros--------:_cItem,lPC
Retorno-----------: Posicao
===============================================================================================================================
*/
Static Function  MTLista(_cItem,lPC)
Local _cQuery := " AND C1_PRODUTO = '"+_cItem+"'"
Local cQry2   := " AND C7_PRODUTO = '"+_cItem+"' "
Local _cAlias := "TRB2"

If lPC
	MPSysOpenQuery( cQry1+cQry2 ,_cAlias )

	If !((_cAlias)->(Eof()))
		aAdd(aAbertosPC,{ _cItem , (_cAlias)->QTD_TOT } )
	Else
		aAdd(aAbertosPC,{ _cItem, 0 } )
	EndIf
	nPos:=Len(aAbertosPC)
Else
	MPSysOpenQuery( _cQuerySC+_cQuery ,_cAlias )
	
	If  !((_cAlias)->(Eof()))
		aAdd(aAbertosSC,{ _cItem , (_cAlias)->QTD_TOT } )
	Else
		aAdd(aAbertosSC,{ _cItem, 0 } )
	EndIf
	nPos:=Len(aAbertosSC)
EndIf

(_cAlias)->(DBCloseArea())
DBSelectArea("TRB")

Return nPos
