/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Walauer  |21/11/2024| Chamado 48952. Copia do Programa de rastreamento dos Lotes da producao (MATC040.PRX)
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: CEST003
Autor-------------: Alex Wallauer
Data da Criacao---: 07/11/2024
Descricao---------: Copia do Programa de rastreamento dos Lotes da producao (MATC040.PRX) - Chamado: 48952
Caminho-----------: SIGAEST -> CONSULTAS -> ESPECIFICO ITALAC -> Rastreamento
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/ 
User Function CEST003()//U_CEST003

 Local cFiltraSB1 :="SB1->B1_RASTRO$'LS'"

 Private aRotina  := MenuDef()
 Private cCadastro:= "Rastreamento de Lotes - ITALAC"
 
 SB1->(DBSetOrder(1))
 SB1->(DBGoTop())
 _aCmp := {}
 aAdd(_aCmp,{ "Codigo Prod.", {|| SB1->B1_COD } ,"C",Len(SB1->B1_COD ),0,"" })
 aAdd(_aCmp,{ "Descri.Prod.", {|| SB1->B1_DESC} ,"C",Len(SB1->B1_DESC),0,"" })

  //rowse(,,,,cAli>,<aFixe, <cCpo>, <nPar>, <cCorFun>, <nClickDef>, <aColors>, <cTopFun>, <cBotFun>, <nPar14>, <bInitBloc>, <lNoMnuFilter>, <lSeeAll>, <lChgAll>, <cExprFilTop>, <nInterval>, <uPar22>, <uPar23> )
  mBrowse(,,,,"SB1",_aCmp,,,,,,,,,,,,,,,,,cFiltraSB1)

 SB1->(DBSetOrder(1))

Return
/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Alex Wallauer
Data da Criacao---: 13/11/2024
Descricao---------: Copia da Funcao Static Function MenuDef () do (MATC040.PRX)
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/ 
Static Function MenuDef()     
 Private aRotina:= {{"Pesquisar","PesqBrw"     ,0,1,0,.F.},;	
					{"Rastrear" ,"U_MTC040Rast",0,4,0,NIL}}
Return (aRotina)

/*
===============================================================================================================================
Programa----------: MTC040Rast
Autor-------------: Alex Wallauer
Data da Criacao---: 07/11/2024
Descricao---------: Tela principal do rastreamento dos Lotes ITALAC
Parametros--------: cAlias,nReg,nOpc
Retorno-----------: Nenhum
===============================================================================================================================
*/ 
User Function MTC040Rast(cAlias,nReg,nOpc)

 Local nOrder   :=IndexOrd()
 Local _cTimeIni:=Time()
 Local cTit1    :="Rastremento do Produto: "+SB1->B1_COD+" - "+AllTrim(SB1->B1_DESC)+". (MTC040MNU.PRW)"
 Local _aSize   :={}
 Local _aInfo   :={}
 Local aObjects :={}
 Local aPosObj  :={}
 Local aFoders1 :={}
 Local nLin01   :=05
 Local nLin03   :=25 
 Local nCol01   :=02
  
 Static nNivMax :=SuperGetMV("MV_C040NIV",.F.,30)
 Static lEmpPrev:=If(SuperGetMV("MV_QTDPREV")== "S",.T.,.F.)

 Private cLocCQ	   := GetMvNNR('MV_CQ','98')
 Private _oLbx1    as object
 Private _oLbx2    as object
 Private _oPanelA  as object   
 Private _oPanel1A as object    
 Private _oPanelB  as object   
 Private _oPanel1B as object    
 Private _oScrollA as object
 Private _oScrollB as object
 Private _oSay01   as object
 Private _oSay02   as object
 Private _oSay03   as object
 Private _oSay04   as object
 Private _oSay05   as object
 Private _oSay06   as object
 Private _oGet01   as object
 Private _oGet02   as object
 Private _oGet03   as object
 Private _oGet04   as object
 Private _oGet05   as object
 Private _oGet06   as object
 Private _oTree1   as object
 Private _oTree2   as object
 Private _aObjetos := {_oTree1,_oTree2}
 Private _aRegsA   := {}
 Private _aRegsB   := {}
 Private _aDadoTre1:= {} 
 Private _aDadoTre2:= {} 
 Private aLine	   := {}
 Private c040LotCtl:= ""
 Private cLoteFor  := ""
 Private cSaldoLt  := ""
 Private nPotencia := 0
 Private nSaldoLote:= 0
 Private _dDTValid := CTOD("")
 //      _aTotais  := { {nTotVenc,nTotZera,nTotUsad,nSaldo,nSaldoLote} , {nTotVenc,nTotZera,nTotUsad,nSaldo,nSaldoLote} }
 Private _aTotais  := { {0,0,0,0,0,0,0,0,} , {0,0,0,0,0,0,0,0,0,} }
 
 //  Variaveis utilizadas para parametros                                     
 //  MV_PAR01  // Tipo do Rastremento ? Onde e' usado/Composicao        
 //  MV_PAR02  // Exibir Lotes Zerados ? Sim/Nao                        
 //  MV_PAR03  // Cli / Forn. de ?                                      
 //  MV_PAR04  // Cli / Forn. ate ?                                     
 //  MV_PAR05  // Loja de ?                                             
 //  MV_PAR06  // Loja ate ?                                            
 //  MV_PAR07  // De Lote ?                                             
 //  MV_PAR08  // Ate Lote ?                                            
 //  MV_PAR09  // De Sub-Lote ?                                         
 //  MV_PAR10  // Ate Sub-Lote ?                                        
 //  MV_PAR11  // de Data de Validade ?                                 
 //  MV_PAR12  // Ate Data de Validade ?                                
           
 If !Pergunte("CEST003",.T.)//MTC040
    Return .F.
 EndIf
 
 SD3->(DBSetOrder(4))
 DBSelectArea(CALIAS)

 // PEGA TAMANHOS DAS TELAS
 _aSize := MsAdvSize()
 _aInfo := { _aSize[1] , _aSize[2] , _aSize[3] , _aSize[4] , 3 , 3 }
 aObjects := {}
 aAdd( aObjects , { 100 , 050 , .T. , .F. , .F. } )
 aAdd( aObjects , { 100 , 100 , .T. , .T. , .F. } )
 aPosObj  := MsObjSize( _aInfo , aObjects )
 
 aFoders1:={}
 aAdd(aFoders1,"Rastremento: Onde é usado")
 aAdd(aFoders1,"Rastremento: Composicao")
 
 _aLegenda := {{ "PMSEDT4", "Produto"        },;
  			   { "PMSEDT1", "Lotes Vencidos" },;
  			   { "PMSEDT2", "Lotes Zerados"  },;
               { "PMSEDT3", "Lotes Em Uso"   } }


 DEFINE MSDIALOG oDlg2 TITLE cTit1  PIXEL FROM _aSize[7],0 TO _aSize[6],_aSize[5] OF oMainWnd

       oPnlTopTop := TPanel():New( 1 , 0 , , oDlg2 , , , , , , 80 , 20 , .F. , .F. )   

	   @ nLin01, nCol01 BUTTON  "SAIR"                    SIZE 040, 14 OF oPnlTopTop ACTION (oDlg2:End()) PIXEL
	   nCol01+=50
	   @ nLin01, nCol01 BUTTON  "Legenda"                 SIZE 040, 14 OF oPnlTopTop ACTION (BRWLEGENDA( "LEGENDA", "Legenda", _aLegenda )) PIXEL
	   nCol01+=50
	   @ nLin01, nCol01 BUTTON  "Pesquisar"               SIZE 040, 14 OF oPnlTopTop ACTION (CEST3Pesq()) PIXEL
	   nCol01+=50
	   @ nLin01, nCol01 BUTTON  "Imprimir os Movimentos"  SIZE 080, 14 OF oPnlTopTop ACTION (A040Imp()) PIXEL
	   nCol01+=95
	   @ nLin01, nCol01 BUTTON  "Visualiza Lotes"         SIZE 080, 14 OF oPnlTopTop ACTION (C040Graph(_aTotais[(oTFolder01:nOption),1],;
	                                                                                                   _aTotais[(oTFolder01:nOption),2],;
	      																							   _aTotais[(oTFolder01:nOption),3] )) PIXEL

       //FOLDER PRINCIPAL COM 2 PASTAS **************************************************************************
	   _nColFolder:=aPosObj[2,4]-3
       _nLinFolder:=aPosObj[2,3]-34
       //                                                              LARGURA     ALTURA 
       oTFolder01:= TFolder():New( nLin03,1,aFoders1,,oDlg2,,,,.T., , _nColFolder,_nLinFolder )
	   oTFolder01:bChange:={|| CETS3Change()  }
       _nLinFolder-=5
	   _nColFolder-=5
         //       TScrollBox():New( [ oWnd ]             ,[ nTop ],[ nLeft],[ altura  ] , [ LARGURA],lVertical,lHorizontal,lBorder)
  	   oTela1 :=TScrollBox():New(oTFolder01:aDialogs[1], 1      ,1       ,_nLinFolder,_nColFolder,.T.      ,.T.        ,.T.)
         
	   _lSair:=.F.
	   _lPerguntou:=.F.
       MV_PAR01:=1//PASTA: "Rastremento: Onde é usado"
       FWMsgRun( ,{|oProc| oTela1:=U_MC040Con(@oTela1,oProc,@_oTree1,@_oLbx1,@_oPanelA,@_oPanel1A,@_oScrollA,_aRegsA,_aDadoTre1) } , "Aguarde!" , "Hor Inicial: "+_cTimeIni )

       If !_lSair
          //         TScrollBox():New( [ oWnd ]             ,[ nTop ],[ nLeft],[ nHeight ] , [ nWidth],lVertical,lHorizontal,lBorder)
  	      oTela2 :=TScrollBox():New(oTFolder01:aDialogs[2], 1      ,1       ,_nLinFolder,_nColFolder,.T.      ,.T.        ,.T.)
   
          MV_PAR01:=2//PASTA: "Rastremento: Composicao"
          FWMsgRun( ,{|oProc| oTela2:=U_MC040Con(@oTela2,oProc,@_oTree2,@_oLbx2,@_oPanelB,@_oPanel1B,@_oScrollB,_aRegsB,_aDadoTre2) } , "Aguarde!" , "Hor Inicial: "+_cTimeIni )
	   EndIf
  
 ACTIVATE MSDIALOG oDlg2 ON INIT (If(_lSair,oDlg2:End()                    ,;
	                             (oPnlTopTop:Align:= CONTROL_ALIGN_TOP     ,;
	                             oTFolder01:Align:= CONTROL_ALIGN_ALLCLIENT,;
								 oTela1:Align:= CONTROL_ALIGN_ALLCLIENT    ,;
	   							 oTela2:Align:= CONTROL_ALIGN_ALLCLIENT    )))
 
 (cAlias)->(DBSetOrder(nOrder))
 (cAlias)->(MSGOTO(nReg))
  
Return

/*
===============================================================================================================================
Programa----------: MC040Con
Autor-------------: Alex Wallauer
Data da Criacao---: 08/11/2024
Descricao---------: Copia da Funcao Static Function MC040Con () do (MATC040.PRX)
Parametros--------: oFolder,oProc,oTree,oLbx,oPanel,oPanel1,oScroll,aRegs,aDadosSB8
Retorno-----------: oFolder
===============================================================================================================================
*/ 
User Function MC040Con(oFolder,oProc,oTree,oLbx,oPanel,oPanel1,oScroll,aRegs,aDadosSB8)
 Local aDados     := {}
 Local aSVAlias   := {}
 Local aPos       := {}
 Local nTop       := oMainWnd:nTop+23
 Local nLeft      := oMainWnd:nLeft+5
 Local nBottom    := oMainWnd:nBottom-60
 Local nRight     := oMainWnd:nRight-10
 Local nTotVenc   := nTotZera := nTotUsad := 0
 Local dDtValid   := SToD("")
 Local cSeekSD5   := ''
 Local cQuery     := ''
 Local cAliasNew  := 'SB8'
 Local nSaldoSB8  := 0
 Local nRecSldAtu := 0
 Local cPictSaldo := PesqPictQt("B8_SALDO",15)
 Local lEmpPrev   := If(SuperGetMV("MV_QTDPREV")=="S",.T.,.F.)
 Local cNomeFolder:= ""
 Local lSoma      := .F.
 Local nPos       As Numeric
 
 Private nSaldo    := 0
 Private nLotes    := 0
 Private nSldTot   := 0
 Private lSubLote  := .F.
 
 nSaldoLote:= 0
 
 aRegs:={}// Cria uma linha na ListBox em Branco
 If Rastro(SB1->B1_COD,"L")
	aAdd(aRegs,{'','','','','',''   ,nil,'',''})//9
 Else
	aAdd(aRegs,{'','','','','','','',nil,'',''})//10
 EndIf
 
 // Carrega as variaveis de memoria do SB1                
 aAdd(aSVAlias,"SB1")
 RegToMemory("SB1",.F.)
 
 DBSelectArea(cAliasNew)
 DBSetOrder(3) //B8_FILIAL+B8_PRODUTO+ B8_LOCAL+B8_LOTECTL+B8_NUMLOTE+DToS(B8_DTVALID)
 
 cAliasNew := GetNextAlias()
 cQuery := " SELECT B8_FILIAL, B8_PRODUTO, B8_LOCAL, B8_LOTECTL, B8_NUMLOTE, B8_DTVALID, B8_DATA,"
 cQuery += " B8_SALDO, B8_SALDO2, B8_QACLASS, B8_QACLAS2, B8_EMPENHO, B8_EMPENH2, B8_QEMPPRE, B8_QEPRE2, R_E_C_N_O_ SB8RECNO"
 cQuery += " FROM "+RetSqlName('SB8')
 cQuery += " WHERE "
 cQuery += " B8_FILIAL      = '"+xFilial("SB8")+"'"
 cQuery += " AND B8_PRODUTO = '"+SB1->B1_COD+"'"
 cQuery += " AND B8_LOTECTL>= '"+MV_PAR07+"'"
 cQuery += " AND B8_LOTECTL<= '"+MV_PAR08+"'"
 If Rastro(SB1->B1_COD,"S")
	 cQuery += " AND B8_NUMLOTE>= '"+MV_PAR09+"'"
	 cQuery += " AND B8_NUMLOTE<= '"+MV_PAR10+"'"
 EndIf
 cQuery += " AND B8_DTVALID>= '"+DToS(MV_PAR11)+"'"
 cQuery += " AND B8_DTVALID<= '"+DToS(MV_PAR12)+"'"
 cQuery += " AND D_E_L_E_T_ = ' '"
 cQuery += " ORDER BY "+SqlOrder(SB8->(IndexKey()))
 cQuery := ChangeQuery(cQuery)
 
 MPSysOpenQuery( cQuery,cAliasNew )
 
 aEval(SB8->(dbStruct()), {|x| If(x[2] <> "C", TCSetField(cAliasNew,x[1],x[2],x[3],x[4]),Nil)})
 
 DBSelectArea(cAliasNew)
 
 _nTot:=nConta:=0
 COUNT TO _nTot
 _cTot:=AllTrim(Str(_nTot))
  DBGoTop()
 _lSair:=.F.
 If _nTot > 500 .And. !_lPerguntou
     _lPerguntou:=.T.
	 If !U_ITMsg("Serão processado "+_cTot+" registros, CONFIRMA?","Atenção",,3,2,2)
	     _lSair:=.T.
		 Return oFolder
	 EndIf
	 cTimeInicial:=Time()
 EndIf
 

 If (cAliasNew)->(!Eof())

	aAdd(aSVAlias,"SB8")

	While (cAliasNew)->(!Eof()) 

	    nConta++
	    oProc:cCaption := (If(MV_PAR01==1,"1/2 - ","2/2 -")+"Lendo Lotes "+If(MV_PAR01==1,"(Onde é Usado):","(Composicao):")+StrZero(nConta,5) +" de "+ _cTot )
	    ProcessMessages()

		cProd    := (cAliasNew)->B8_PRODUTO
		cLocal   := (cAliasNew)->B8_LOCAL
		cLote    := (cAliasNew)->B8_LOTECTL
		cSubL    := (cAliasNew)->B8_NUMLOTE
		lSubLote := Rastro(cProd,"S")
		nSaldoSB8:= 0
		
		nRecSldAtu := (cAliasNew)->SB8RECNO

		While (cAliasNew)->(!Eof() .And. cProd+cLocal+cLote+If(lSubLote,cSubL,"") == B8_PRODUTO+B8_LOCAL+B8_LOTECTL+If(lSubLote,B8_NUMLOTE,""))

			// Para Rastro = S, verificar se ha movimento no SD5     
			// com D5_ORIGLAN == 999                                |
			If lSubLote

				SD5->(DBSetOrder(2))
				If SD5->(DBSeek(xFilial("SD5")+(cAliasNew)->B8_PRODUTO+(cAliasNew)->B8_LOCAL+(cAliasNew)->B8_LOTECTL+(cAliasNew)->B8_NUMLOTE))
					cSeekSD5:= xFilial("SD5")+SD5->D5_NUMSEQ+(cAliasNew)->B8_PRODUTO+(cAliasNew)->B8_LOCAL+(cAliasNew)->B8_LOTECTL+(cAliasNew)->B8_NUMLOTE
					SD5->(DBSetOrder(3))
					If SD5->(DBSeek(cSeekSD5))
						While !SD5->(Eof()) .And. cSeekSD5 == SD5->D5_FILIAL+SD5->D5_NUMSEQ+SD5->D5_PRODUTO+SD5->D5_LOCAL+SD5->D5_LOTECTL+SD5->D5_NUMLOTE
							If SD5->D5_ORIGLAN == "999" .And. SD5->D5_ESTORNO # "S"
								lSoma := .F.
								Exit
							EndIf
							SD5->(DBSkip())
						EndDo
					EndIf
				EndIf
			EndIf

			//Recupera o Saldo por Lote                                   
			nSaldoSB8:=SB8SALDO(,,,,cAliasNew,lEmpPrev,,,.T.)

			//Nao considerar Lotes/SubLotes com saldo zerado na consulta. 
			If MV_PAR02 == 2 .And. nSaldoSB8 == 0
				(cAliasNew)->(DBSkip())
				Loop
			EndIf

			lSoma    := .T.
			dDtValid := (cAliasNew)->B8_DTVALID
			nSaldo   := nSaldoSB8
			nSldTot  += nSaldoSB8	// Saldo Total (saldo do lote)
			nPos     := aScan(aDadosSB8, { |x| x[1] == "Amz "+cLocal+" -> "+cLote+If(lSubLote," - "+cSubL,"") })
			If nSaldo <> 0
				// Captura RECNO do ultimo lote com Saldo   			  
				nRecSldAtu := (cAliasNew)->SB8RECNO
		    EndIf
			If nPos = 0
				// Cria Array com os Lotes/SubLotes para exibir no Tree  
				aAdd(aDadosSB8,{"Amz "+cLocal+" -> "+cLote+If(lSubLote," - "+cSubL,""),"SB8", StrZero((cAliasNew)->SB8RECNO,12) })  //"Amz "
				// Soma a quantidade de Lotes/SubLotes do Tree			  
				// nLotes ++  
			ElseIf nSldTot == 0 .And. nSaldo == 0
				// Lote com saldo Zerado                   			  
				aDadosSB8[nPos,3] := StrZero((cAliasNew)->SB8RECNO,12)
			Else	
				// Posiciona RECNO com ultimo saldo para exibicao correta de legenda  		  
				aDadosSB8[nPos,3] := StrZero((nRecSldAtu),12)
			EndIf
			(cAliasNew)->(DBSkip())
		EndDo
		
		nLotes:=Len(aDadosSB8)// Soma a quantidade de Lotes/SubLotes do Tree
        If lSoma
			// Total de quantidades dos Lotes/SubLotes do Produto 	  
			If dDtValid < dDataBase  .And. nSaldo > 0
				nTotVenc ++			// Total de Lotes Vencidos
			ElseIf nSaldo == 0 
				nTotZera ++			// Total de Lotes Zerados
			Else
				nTotUsad ++			// Total de Lotes Em Uso
			EndIf
		EndIf
	
	EndDo
    
	DBSelectArea(cAliasNew)
	DBCloseArea()

	// Posiciona para carregar variaveis de memoria do SD5   
	// Executa esse processo para agilizar na visualizacao   
	DBSelectArea("SD5")
	DBSetOrder(2)
	If DBSeek(xFilial("SD5")+SB1->B1_COD)
		aAdd(aSVAlias,"SD5")
	EndIf

	cNomeFolder := If(Rastro(SB1->B1_COD,"L"),"Lotes","Sub-Lotes")
	cNomeFolder += " -" + If(MV_PAR01==1," Onde é Usado "," Composicao ")

  	//****************** PANEL DAS INFORMACOES DO PRODUTO COM LOGO DA TOTVS ****************** 
	//                                                             LARGURA     ALTURA 
  	oPanel := TPanel():New(1,130,'',oFolder,,.T., .T.,, ,(nRight-nLeft)/2-130,(_nLinFolder-1),.T.,.T. )//(nRight-nLeft)/2-130,nBottom-nTop,.T.,.T. )
  	
  	aAdd(aDados,{"Codigo do Produto:"     ,+AllTrim(SB1->B1_COD)              })
  	aAdd(aDados,{"",""})
  	aAdd(aDados,{"Descricao do Produto:"  ,AllTrim(SB1->B1_DESC)              })
  	aAdd(aDados,{"",""})
  	aAdd(aDados,{"Saldo Total do Produto:",AllTrim(Trans(nSldTot ,cPictSaldo))})	
  	aAdd(aDados,{"",""})
  	aAdd(aDados,{"Quantidades de Lotes:"  ,AllTrim(Trans(nLotes  ,cPictSaldo))})	
  	aAdd(aDados,{"",""})
  	aAdd(aDados,{"Qtde. Lotes Vencidos:"  ,AllTrim(Trans(nTotVenc,cPictSaldo))})	
  	aAdd(aDados,{"",""})
  	aAdd(aDados,{"Qtde. Lotes Zerados:"   ,AllTrim(Trans(nTotZera,cPictSaldo))})	
  	aAdd(aDados,{"",""})
  	aAdd(aDados,{"Qtde. Lotes Em Uso:"    ,AllTrim(Trans(nTotUsad,cPictSaldo))})	
    
    _nMenos:=19
	aPos:= {0,0,;
	       ((nBottom-nTop)/2)-_nMenos,;//ALTURA
		   (nRight-nLeft)/2-130       }//LARGURA

   	MatScrDisp(aDados,@oScroll,@oPanel,aPos,{{1,CLR_BLUE}})

  	//****************** PANEL DAS MOVIMENTACOES DO LOTE/SUBLOTE LISTBOX ****************** 
	//                                                             LARGURA     ALTURA 
  	oPanel1:= TPanel():New(1,130,'',oFolder,,.T., .T.,, ,(nRight-nLeft)/2-130,(_nLinFolder-1),.T.,.T. )//(nRight-nLeft)/2-130,nBottom-nTop,.T.,.T. )
  
	nLargura:=((nRight-nLeft)/2)-130
	nAltura :=((nBottom-nTop)/2)-_nMenos-48

  	If Rastro(SB1->B1_COD,"L")		
       //aAdd(aRegs,{cLote,      cHist,cProd,cLocD,cQtde,cLoteForD5,nQtde,cEnde,cNroSerie})
  	   //              1           2     3     4     5       6        7     8       9
  	   @ 46,2 LISTBOX oLbx FIELDS HEADER "Lote"           ,"Historico",If(MV_PAR01==1,"Prod.Dest.","Prod.Orig."),"Amz. Dest","Endereço Requisitado","Num.Serie","Quantidade","Lote do Fornecedor:" SIZE nLargura,nAltura OF oPanel1 PIXEL  
  	Else		
       //aAdd(aRegs,{cLote,cSubL,cHist,cProd,cLocD,cQtde,cLoteForD5,nQtde,cEnde,cNroSerie})
  	   //              1      2    3     4     5     6       7        8     9      10    
  	   @ 46,2 LISTBOX oLbx FIELDS HEADER "Lote","Sub-Lote","Historico",If(MV_PAR01==1,"Prod.Dest.","Prod.Orig."),"Amz. Dest","Endereço Requisitado","Num.Serie","Quantidade","Lote do Fornecedor:",SIZE nLargura,nAltura OF oPanel1 PIXEL  
  	EndIf
  	oLbx:SetArray(aRegs)
  	
  	If Len(aRegs) > 0
  	   If Rastro(SB1->B1_COD,"L")					
  	      oLbx:bLine := {|| {aRegs[oLbx:nAT,1],                    aRegs[oLbx:nAT,2], aRegs[oLbx:nAT,3], aRegs[oLbx:nAT,4], aRegs[oLbx:nAT,8], aRegs[oLbx:nAT,09], aRegs[oLbx:nAT,5], aRegs[oLbx:nAT,6]} }
  	   Else			
  	   	  oLbx:bLine := {|| {aRegs[oLbx:nAT,1], aRegs[oLbx:nAT,2], aRegs[oLbx:nAT,3], aRegs[oLbx:nAT,4], aRegs[oLbx:nAT,5], aRegs[oLbx:nAT,9], aRegs[oLbx:nAT,10], aRegs[oLbx:nAT,6], aRegs[oLbx:nAT,7]} }
  	   EndIf
  	EndIf
  
  	oLbx:Hide()
  	oPanel1:Hide()

	//******************** INFORMACOES PARA MONTAGEM DO TREE  ****************************
	nAltura:=((nBottom-nTop)/2)-_nMenos
	nLargura:=129
	//                   nTop,nLeft,nBottom,nRight
	oTree:= dbTree():New(1   , 2   ,nAltura,nLargura   ,oFolder,,,.T.)
	
    oTree:bChange := {|| MC040View(@oTree,@oLbx,@oPanel,@oScroll,@oPanel1,aRegs,aLine) }
	
	oTree:lShowHint:= .F.

	MTC040Tree(@oTree,aDadosSB8,"SB8",.T.)

  	If MV_PAR01 == 1
	   _aTotais[1]:= {nTotVenc,nTotZera,nTotUsad,nSaldo,nSaldoLote}
	   _aObjetos[1]:=oTree
	ElseIf MV_PAR01 == 2
	   _aTotais[2]:= {nTotVenc,nTotZera,nTotUsad,nSaldo,nSaldoLote} 
	   _aObjetos[2]:=oTree
	EndIf

 Else

	Help("",1,"Recno")
    _lSair:=.T.

 EndIf

Return oFolder


/*
===============================================================================================================================
Programa----------: MC040View
Autor-------------: Alex Wallauer
Data da Criacao---: 07/11/2024
Descricao---------: Copia da Funcao Static Function MC040View () do (MATC040.PRX)
Parametros--------: oTree,oLbx,oPanel,oScroll,oPanel1,aRegs,aLine,nPasta,lImp
Retorno-----------: .T.
===============================================================================================================================
*/ 
Static Function MC040View(oTree,oLbx,oPanel,oScroll,oPanel1,aRegs,aLine,nPasta,lImp)
 Local cAlias	:= SubStr(oTree:GetCargo(),1,3)
 Local nRecView	:= Val(SubStr(oTree:GetCargo(),4,12))
 Local nX
 Local lEmpPrev  := If(SuperGetMV("MV_QTDPREV")== "S",.T.,.F.)
 
 DEFAULT nPasta:=(oTFolder01:nOption)
 DEFAULT lImp  :=.F.
 
 If lImp
    cAlias:="SB8"
 EndIf
 MV_PAR01:=nPasta//DEFINE O FILTRO PELO FOLDER
 
 Do Case
	
	Case cAlias == "SB1"
		// Exibe informacoes de saldo do Lote/SubLote do Produto 
		oScroll:Hide()
		oPanel1:Hide()
		oLbx:Hide()
		oScroll:Show()
	
	Case cAlias == "SB8"
		
		// Monta ListBox das movimentacoes                       
		aLine := {}
		aRegs := {}
		
		SB8->(MsGoTo(nRecView))
		c040Lote   := SB8->B8_NUMLOTE
		c040LotCtl := SB8->B8_LOTECTL
		c040Produt := SB8->B8_PRODUTO
		c040Local  := SB8->B8_LOCAL
		c040LoteFor:= SB8->B8_LOTEFOR
		nSaldo 	   := SB8SALDO(,,,,,lEmpPrev,,,.T.)
		_dDTValid  := SB8->B8_DTVALID
		nPotencia  := SB8->B8_POTENCI
		cLoteFor   := SB8->B8_LOTEFOR
		lSubLote   := Rastro(c040Produt,"S")
		dCriacao   := DToC(SB8->B8_DATA)
		aProd      := {}

		If !lSubLote
			nSaldoLote := SaldoLote(c040Produt,c040Local,c040LotCtl)
		Else
			nSaldoLote := SB8SALDO(,,,,,lEmpPrev,,,.T.)
		EndIf

		SB1->(DBSetOrder(1))
		SB1->(MsSeek(xFilial("SB1")+c040Produt))

		//Processa({|lEnd| MontaLine(aLine,NIL,c040LotCtl,c040Lote,c040Produt,c040Local,If(MV_PAR01 == 1,"U","C"),NIL,c040LoteFor,NIL,NIL,@lEnd)},"Rastreamento de Lotes","Aguarde... Rastreando o "+If(Rastro(SB1->B1_COD,"L"),AllTrim("Lote")+" "+c040LotCtl,"Sub-Lote"+" "+c040LotCtl+"/"+c040Lote),.F.)
		MontaLine(aLine,NIL,c040LotCtl,c040Lote,c040Produt,c040Local,If(MV_PAR01 == 1,"U","C"),NIL,c040LoteFor,NIL,NIL)

		If Len(aLine) == 0
			If !lSubLote
				aAdd(aRegs,{c040LotCtl         ,"SEM MOVIMENTACAO",'','','','',nil,'',''})
			Else
				aAdd(aRegs,{c040LotCtl,c040Lote,"SEM MOVIMENTACAO",'','','','',nil,'',''})
			EndIf
		Else
			cProd := CRIAVAR("B1_COD", .F.)
			For nX := 1 To Len(aLine)
				cLote     := AllTrim(aLine[nX,1])
				cSubL     := AllTrim(aLine[nX,2])
				cHist     := AllTrim(aLine[nX,3])
				cQtde     := AllTrim(aLine[nX,4])
				cProd     := AllTrim(aLine[nX,5])
				cLocD     := AllTrim(aLine[nX,6])
				cLoteForD5:= AllTrim(aLine[nX,7])
				nQtde     := aLine[nX,8]
				cEnde     := aLine[nX,11]
				cNroSerie := aLine[nX,12]
				
				// Produto Destino
				If !Empty(cProd) .And. MV_PAR01 == 1
					cProd := If(cProd==SB1->B1_COD.And.cLocd==RetFldProd(SB1->B1_COD,"B1_LOCPAD"),CRIAVAR("B1_COD", .F.),cProd)
					cLocD := If(cProd==SB1->B1_COD.And.cLocd==RetFldProd(SB1->B1_COD,"B1_LOCPAD"),CRIAVAR("B1_LOCPAD", .F.),cLocD)
				EndIf

				// Procura Produto Origem
				SD5->(DBSetOrder(1))
				SD5->(DBSeek(xFilial("SD5")+cSubL))
				If Rastro(SB1->B1_COD,"S") .And. SD5->D5_PRODUTO # SB1->B1_COD .And. MV_PAR01 == 2
					cProd := SD5->D5_PRODUTO
					cLocD := SD5->D5_LOCAL
				EndIf

				// Monta array aRegs conforme o rastro do produto
				If !lSubLote
					aAdd(aRegs,{cLote      ,cHist,cProd,cLocD,cQtde,cLoteForD5,nQtde,cEnde,cNroSerie})
				Else
					aAdd(aRegs,{cLote,cSubL,cHist,cProd,cLocD,cQtde,cLoteForD5,nQtde,cEnde,cNroSerie})
				EndIf
			Next nX
		EndIf
        
	    If !lImp//QUANDO NÃO CHAMADA DA IMPRESSÃO NÃO TEM TELA PAR ATUALIZAR
 
		    FreeObj(_oSay01)
		    FreeObj(_oSay02)
		    FreeObj(_oSay03)
		    FreeObj(_oSay04)
		    FreeObj(_oSay05)
		    FreeObj(_oSay06)

		    FreeObj(_oGet01)
		    FreeObj(_oGet02)
		    FreeObj(_oGet03)
		    FreeObj(_oGet04)
		    FreeObj(_oGet05)
		    FreeObj(_oGet06)
			
			cSaldoLt := Transform(nSaldoLote,PesqPictQT("B8_SALDO",14))
    
		    // Montagem da tela das informacoes e movimentacoes do   
		    // Lote/SubLote do Produto.                              
		    SB8->(MsGoTo(nRecView))
    
		    @ 04,005 Say _oSay01 PROMPT "Produto:"            Of oPanel1 Size  30,8 Pixel
		    @ 04,210 Say _oSay02 PROMPT "Lote:"               Of oPanel1 Size  30,8 Pixel
		    @ 17,005 Say _oSay03 PROMPT "Lote do Fornecedor:" Of oPanel1 Size  50,8 Pixel
		    @ 17,147 Say _oSay04 PROMPT "Potencia:"           Of oPanel1 Size  30,8 Pixel
		    @ 30,005 Say _oSay05 PROMPT "Saldo do Lote:"      Of oPanel1 Size  40,8 Pixel
		    @ 30,100 Say _oSay06 PROMPT "Validade do Lote:"   Of oPanel1 Size  50,8 Pixel
    
		    //@ 27,210 Button oBtnL Prompt "Visualiza Saldo" Size 48, 13 Of oPanel1 Pixel Action (CEST3ViSa())
    
		    @ 03,030 MsGet _oGet01 VAR SB1->B1_DESC		Of oPanel1 Size 158,8 Pixel READONLY
		    @ 03,230 MsGet _oGet02 VAR c040LotCtl		Of oPanel1 Size  70,8 Pixel READONLY
		    @ 16,060 MsGet _oGet03 VAR cLoteFor 	  	Of oPanel1 Size  70,8 Pixel READONLY
		    @ 16,173 MsGet _oGet04 VAR nPotencia 		Of oPanel1 Size  15,8 Pixel READONLY
		    @ 29,045 MsGet _oGet05 VAR cSaldoLt 	 	Of oPanel1 Size  40,8 Pixel READONLY Right
		    @ 29,148 MsGet _oGet06 VAR DToC(_dDTValid)	Of oPanel1 Size  40,8 Pixel READONLY Center
    
		    oLbx:SetArray(aRegs)
		    
		    If !lSubLote			
		    	oLbx:bLine := {|| {aRegs[oLbx:nAT,1], aRegs[oLbx:nAT,2], aRegs[oLbx:nAT,3], aRegs[oLbx:nAT,4], aRegs[oLbx:nAT,8], aRegs[oLbx:nAT,9], aRegs[oLbx:nAT,5], aRegs[oLbx:nAT,6]} }		
		    Else			
		    	oLbx:bLine := {|| {aRegs[oLbx:nAT,1], aRegs[oLbx:nAT,2], aRegs[oLbx:nAT,3], aRegs[oLbx:nAT,4], aRegs[oLbx:nAT,5], aRegs[oLbx:nAT,9], aRegs[oLbx:nAT,10], aRegs[oLbx:nAT,6], aRegs[oLbx:nAT,7]} }			
		    EndIf    		
		    oLbx:Show()
		    oLbx:Refresh()
		    oPanel1:Show()
	    EndIf
 EndCase

 If !lImp
    oPanel:Refresh()
    oPanel1:Refresh()
    oScroll:Refresh()
 EndIf
 
Return aRegs


/*
===============================================================================================================================
Programa----------: MTC040Rast
Autor-------------: Alex Wallauer
Data da Criacao---: 07/11/2024
Descricao---------: Copia da Funcao Static Function MontaLine () do (MATC040.PRX)
Parametros--------: aLine,nQuantOrig,c040LotCtl,c040Lote,c040Produt,c040Local,cTipo,aRecOrig,c040LoteFor,cUltSeq,cOP,lEnde,nChamad
Retorno-----------: Nenhum
===============================================================================================================================
*/ 
Static Function MontaLine(aLine,nQuantOrig,c040LotCtl,c040Lote,c040Produt,c040Local,cTipo,aRecOrig,c040LoteFor,cUltSeq,cOP,lEnde,nChamad)
 Local aArea    := FWGetArea()
 Local aAreaSD5 := {}
 Local aAreaSB1 := {}
 Local aAreaBack:= {}
 Local aVarAux  := {}
 Local cLine    := ""
 Local cOpAnt   := ""
 Local cTmSD3   := ""
 Local cNomeCli := ""
 Local cDadosPrd:= ""
 Local cQuery   := ""
 Local cCampos  := "D5_FILIAL+D5_PRODUTO+D5_LOCAL+D5_LOTECTL"
 Local cProduto := CriaVar("B1_COD", .F.)
 Local cLocal   := CriaVar("B1_LOCPAD", .F.)
 Local cNewProd := cProduto
 Local cNewLocal:= cLocal
 Local cCompara := xFilial('SD5')+c040Produt+c040Local+c040LotCtl
 Local lSubLote := Rastro(c040Produt,"S")
 Local nSeekChav:= 0 
 Local lRet     := .T.
 Local lNfiscal := .F.
 Local aTamSB1  := TamSX3('B1_COD')
 Local nLote    := TamSX3("D5_LOTECTL")[1]  
 Local nSubLote := TamSX3("D5_NUMLOTE")[1]  
 Local nArmazem := TamSX3("D1_LOCAL")[1] 
 Local nTamLabor:= TamSX3("QEL_LABOR")[1]
 Local cPictQtde:= PesqPictQt("D5_QUANT",15)
 Local cAliasSD5:= "SD5"
 Local cNumOp   := CriaVar("D5_OP", .F.) 
 Local aSDB     := {{"","",0}}
 Local nX := 1
 Local nI := 0
 Local aLotVolta := {}
 Local nD5LotCtl := TamSX3("D5_LOTECTL")[1]
 Local nQELLabor := TamSX3("QEL_LABOR")[1]
 Local cLotAnt   := ""
 Local cFuncSubst:= "SubStr"//SUBSTRING
 Local cNumSeri	 := ''
 Local cLocaliz	 := ''
 Local nRecSDB 	 := 0
 
 Default cUltSeq	:= ""
 Default cOP    	:= CriaVar("D5_OP", .F.)
 Default nChamad	:= 0
 Default lEnde		:= .F.
 Default aRecOrig	:= {}
 
 DBSelectArea("SD5")
 DBSetOrder(2)
 aAreaSD5:=FWGetArea()
 If !Empty(c040Lote).And.lSubLote
 	cCampos +="+D5_NUMLOTE"
 	cCompara+=c040Lote
 EndIf
 FWRestArea(aAreaSD5)
 
 DBSelectArea("SB1")
 aAreaSB1 := FWGetArea()
 SB1->(MsSeek(xFilial("SB1") + c040Produt))
 If RetFldProd(SB1->B1_COD,"B1_LOCALIZ") == "S"   
 	lEnde := .T.
 EndIf   
 
 FWRestArea(aAreaSB1)

	cAliasSD5 := GetNextAlias()
	If Select(cAliasSD5) > 0 
		DBSelectArea(cAliasSD5)
		DBCloseArea()
	EndIf
	cQuery := " SELECT D5_FILIAL,D5_PRODUTO,D5_LOCAL,D5_LOTECTL,D5_NUMLOTE,D5_NUMSEQ,D5_ESTORNO,D5_CLIFOR,D5_LOJA, "
	cQuery += " D5_ORIGLAN,D5_DOC,D5_SERIE,D5_QUANT,D5_OP,D5_LOTEPRD,D5_SLOTEPR,D5_LOTEFOR,SD5.R_E_C_N_O_ RECNOSD5 "
	If lEnde
		cQuery += ", DB_LOCALIZ, DB_NUMSERI, DB_QUANT, SDB.R_E_C_N_O_ RECNOSDB "
		cQuery += " FROM " +RetSqlName('SD5') + ' SD5 '
		cQuery += " LEFT JOIN " +RetSqlName('SDB') + ' SDB'
		cQuery += " ON SD5.D5_FILIAL = SDB.DB_FILIAL AND SD5.D5_PRODUTO = SDB.DB_PRODUTO AND SD5.D5_LOCAL = SDB.DB_LOCAL"
		cQuery += " AND SD5.D5_LOTECTL = SDB.DB_LOTECTL AND SD5.D5_NUMSEQ = SDB.DB_NUMSEQ AND SD5.D5_DOC = SDB.DB_DOC"
		cQuery += " AND SDB.DB_ESTORNO = ' '"
		cQuery += " AND SDB.D_E_L_E_T_ = ' '"
	Else
		cQuery += " FROM " +RetSqlName('SD5') + ' SD5 '
	EndIf

	cQuery += " WHERE "
	cQuery += " SD5.D5_FILIAL      = '"+xFilial("SD5")+"'"
	cQuery += " AND SD5.D5_PRODUTO = '"+c040Produt+"'"
	cQuery += " AND SD5.D5_LOCAL   = '"+c040Local+"'"
	cQuery += " AND SD5.D5_LOTECTL = '"+c040LotCtl+"'"
	If !Empty(c040Lote) .And. lSubLote	
		cQuery += " AND SD5.D5_NUMLOTE = '"+c040Lote+"'"
	EndIf	
	cQuery += " AND SD5.D5_ESTORNO = ' '"
	If Len(aRecOrig) > 0
		cQuery += " AND ("
		For nI:=1 to Len(aRecOrig)
			cQuery += " SD5.R_E_C_N_O_ <> "+ AllTrim(Str(aRecOrig[nI]))
			If Len(aRecOrig) # nI
				cQuery += " OR "
			EndIf
		Next nI	
		cQuery += " )"
	EndIf
	If !Empty(cUltSeq)
		cQuery += " AND SD5.D5_NUMSEQ > '"+cUltSeq+"'"
	EndIf
	cQuery += " AND (SD5.D5_CLIFOR BETWEEN '"+MV_PAR03+"' AND '"+MV_PAR04+"')"
	cQuery += " AND (SD5.D5_LOJA BETWEEN '"+MV_PAR05+"' AND '"+MV_PAR06+"')"
	
	If cTipo == "C"
		cQuery += " AND ((SD5.D5_ORIGLAN < '500') OR ("+cFuncSubst+"(SD5.D5_ORIGLAN,1,1) IN ('D','P','M'))) "
	ElseIf cTipo == "U"
		cQuery += " AND ((SD5.D5_ORIGLAN > '500') OR ("+cFuncSubst+"(SD5.D5_ORIGLAN,1,1) IN ('R'))) "
	EndIf
	cQuery += " AND SD5.D_E_L_E_T_ = ' '"
	cQuery += " ORDER BY "+SqlOrder(SD5->(IndexKey()))
	cQuery := ChangeQuery(cQuery)
	
	MPSysOpenQuery( cQuery , cAliasSD5 )
	
	aEval(SD5->(dbStruct()), {|x| If(x[2] <> "C", TCSetField(cAliasSD5,x[1],x[2],x[3],x[4]),Nil)})
	DBSelectArea(cAliasSD5)

 //ProcRegua(SD5->(LastRec()),23,4) 

 aLotVolta:={}
 While (cAliasSD5)->(!Eof()) .And. cCompara == (cAliasSD5)->(&cCampos)
	//IncProc()
	cLine   :=""
	cOpAnt  :=""
	cTmSD3  :=""   
	cProduto:=cNewProd
	cLocal  :=cNewLocal 
	lNfiscal:=.F.
	If lEnde .And. !Empty((cAliasSD5)->DB_NUMSERI)
		If aScan(aLine,{|x|x[5]==(cAliasSD5)->D5_PRODUTO .And. x[1]==(cAliasSD5)->D5_LOTECTL .And. x[12]==(cAliasSD5)->DB_NUMSERI}) <> 0
			(cAliasSD5)->(DBSkip())
			Loop
		EndIf
	Else
		If aScan(aLine,{|x| x[10]==(cAliasSD5)->RECNOSD5 .And. IIf(lEnde,x[13] ==(cAliasSD5)->RECNOSDB,.T.) }) <> 0
			(cAliasSD5)->(DBSkip())
			Loop
		EndIf
	EndIf	

	// Entrada de Material
	If cTipo == "C"
		DBSelectArea("SD1")
		SD1->(DBSetOrder(5))
		// Nota fiscal de Entrada
		If SD1->(MsSeek(xFilial("SD1")+(cAliasSD5)->D5_PRODUTO+(cAliasSD5)->D5_LOCAL+(cAliasSD5)->D5_NUMSEQ ))
			DBSelectArea("SF4")
			If SF4->(MsSeek(xFilial("SF4")+SD1->D1_TES))
				// Pesquisa pelo Nome Reduzido do Cliente OU FORNECEDOR
				DBSelectArea(If(SD1->D1_TIPO $ "DB","SA1","SA2"))
				DBSetOrder(1)
				If MsSeek(xFilial(If(SD1->D1_TIPO $ "DB","SA1","SA2"))+SD1->D1_FORNECE+SD1->D1_LOJA)
					cNomeCli := SubStr(AllTrim(If(SD1->D1_TIPO $ "DB",SA1->A1_NREDUZ,SA2->A2_NREDUZ)),1,15)
				EndIf
				DBSelectArea(cAliasSD5)
				// Remessa para beneficiamento
				If SF4->F4_PODER3 == "R"
					// XXXXXXXXXX XXXXXX NF. p/Benef. N.XXXXXX/XXX
					cLine := c040Produt+cLocal+(cAliasSD5)->D5_LOTECTL+" "+(cAliasSD5)->D5_NUMLOTE+"  NF. p/Benef. N."+(cAliasSD5)->D5_DOC+"/"+(cAliasSD5)->D5_SERIE+" "+SD1->D1_LOJA+"-"+AllTrim(SD1->D1_FORNECE)+"/"+cNomeCli	//"  NF. p/Benef. N."
					// Devolucao de beneficiamento
				ElseIf SF4->F4_PODER3 == "D"
					// XXXXXXXXXX XXXXXX Dev. Benef.  N.XXXXXX/XXX
					cLine := c040Produt+cLocal+(cAliasSD5)->D5_LOTECTL+" "+(cAliasSD5)->D5_NUMLOTE+"  Dev. Benef. N."+(cAliasSD5)->D5_DOC+"/"+(cAliasSD5)->D5_SERIE+" "+SD1->D1_LOJA+"-"+AllTrim(SD1->D1_FORNECE)+"/"+cNomeCli	//"  Dev. Benef. N."
				Else
					// Compra
					If SD1->D1_TIPO == "N"
						// XXXXXXXXXX XXXXXX NF. Compra   N.XXXXXX/XXX
						cLine := c040Produt+cLocal+(cAliasSD5)->D5_LOTECTL+" "+(cAliasSD5)->D5_NUMLOTE+"  NF. Compra N."+(cAliasSD5)->D5_DOC+"/"+(cAliasSD5)->D5_SERIE+" "+SD1->D1_FORNECE+"-"+SD1->D1_LOJA+"/"+cNomeCli	//"  NF. Compra N."
						// Devolucao
					ElseIf SD1->D1_TIPO == "D"
						// XXXXXXXXXX XXXXXX NF.Dev.Venda N.XXXXXX/XXX
						cLine := c040Produt+cLocal+(cAliasSD5)->D5_LOTECTL+" "+(cAliasSD5)->D5_NUMLOTE+"  NF.Dev.Venda N."+(cAliasSD5)->D5_DOC+"/"+(cAliasSD5)->D5_SERIE	//"  NF.Dev.Venda N."
					EndIf
				EndIf
			EndIf
			lNfiscal := .T.
			DBSelectArea(cAliasSD5)
			// Entrada por movimentos internos
		Else
			DBSelectArea(cAliasSD5)
			cTmSD3:=AC040TM((cAliasSD5)->D5_NUMSEQ,(cAliasSD5)->D5_ORIGLAN)
			If cTmSD3 $ "MAN"
				// XXXXXXXXXX XXXXXX Manutencao de Lote
				cLine := c040Produt+cLocal+(cAliasSD5)->D5_LOTECTL+" "+(cAliasSD5)->D5_NUMLOTE+"  Manutencao de Lote"	//
			ElseIf cTmSD3 $ "DE0"
				// XXXXXXXXXX XXXXXX Devolucao Manual
				cLine := c040Produt+cLocal+(cAliasSD5)->D5_LOTECTL+" "+(cAliasSD5)->D5_NUMLOTE+"  Devolucao Manual"	//
			ElseIf cTmSD3 $ "DE1"
				// XXXXXXXXXX XXXXXX Devolucao Automatica
				cLine := c040Produt+cLocal+(cAliasSD5)->D5_LOTECTL+" "+(cAliasSD5)->D5_NUMLOTE+"  Devolucao Automatica"	//
			ElseIf cTmSD3 $ "DE3/DE4/RE3"
				aLotePara := BuscaLoteRE4((cAliasSD5)->D5_NUMSEQ,(cAliasSD5)->RECNOSD5)
				// XXXXXXXXXX XXXXXX Trf. de  XXXXXXXXXX/XXXXXX
				If !Empty(aLotePara)
					cLine := aLotePara[3]+aLotePara[4]+(cAliasSD5)->D5_LOTECTL+" "+(cAliasSD5)->D5_NUMLOTE+If(cTmSD3=="RE3"," Transferido para processo de ",If(cTmSD3=="DE3"," Transferido de processo ","Transfer.  de   "))+aLotePara[1]+If(Rastro(SB1->B1_COD,"S"),"/"+aLotePara[2],"")
				EndIf
			ElseIf cTmSD3 == "DE6"
				aLotePara := BuscaLoteRE4( (cAliasSD5)->D5_NUMSEQ, (cAliasSD5)->RECNOSD5 )
				If Len(aLotePara) > 0   
					If (cAliasSD5)->D5_LOCAL == cLocCQ
						// XXXXXXXXXX XXXXXX Rejeitado de  XXXXXXXXXX/XXXXXX
						cLine := aLotePara[3]+aLotePara[4]+(cAliasSD5)->D5_LOTECTL+" "+(cAliasSD5)->D5_NUMLOTE+"  Rejeitado de  "+aLotePara[1]+If(Rastro(aLotePara[3],"S"),"/"+aLotePara[2],"")
					Else
						// XXXXXXXXXX XXXXXX Liberado de  XXXXXXXXXX/XXXXXX
						cLine := aLotePara[3]+aLotePara[4]+(cAliasSD5)->D5_LOTECTL+" "+(cAliasSD5)->D5_NUMLOTE+"  Liberado de  "+aLotePara[1]+If(Rastro(aLotePara[3],"S"),"/"+aLotePara[2],"")
					EndIf
					If aScan( aRecOrig, {|x| x == (cAliasSD5)->RECNOSD5 } ) == 0
						aAdd(aRecOrig,(cAliasSD5)->RECNOSD5)
					EndIf
					MontaLine(aLine,(cAliasSD5)->D5_QUANT,aLotePara[1],aLotePara[2],aLotePara[3],aLotePara[4],cTipo,aRecOrig,aLotePara[5],aLotePara[6],/*cOP*/,/*lEnd*/,@nChamad)
					nPos := aScan( aRecOrig, {|x| x == (cAliasSD5)->RECNOSD5 } )
			        If nPos > 0
			           aDel( aRecOrig, nPos )
					   aSize( aRecOrig, Len(aRecOrig)-1 )
					EndIf
				EndIf

			ElseIf cTmSD3 == "DE7"
				aLotePara := BuscaLtRE7( (cAliasSD5)->D5_NUMSEQ , cNumOp )
				// XXXXXXXXXX XXXXXX Desmontagem de XXXXXXXXXX/XXXXXX
				cLine := aLotePara[3]+aLotePara[4]+(cAliasSD5)->D5_LOTECTL+" "+(cAliasSD5)->D5_NUMLOTE+" Desmontagem de "+aLotePara[1]+If(Rastro(aLotePara[3],"S"),"/"+aLotePara[2],"")

			ElseIf SubStr(cTmSD3,1,2) == "PR"
				If Len(aLotePara:=BuscaOP(.T.,.T.,(cAliasSD5)->D5_LOTECTL,(cAliasSD5)->D5_NUMLOTE,(cAliasSD5)->D5_NUMSEQ,(cAliasSD5)->D5_OP,(cAliasSD5)->D5_LOTEPRD,(cAliasSD5)->D5_SLOTEPR, (cAliasSD5)->RECNOSD5) ) > 0
					cDadosPrd:= aLotePara[1]+If(lSubLote,aLotePara[2],"")
					cProduto := aLotePara[3]
					cLocal   := aLotePara[4]
				EndIf
				// XXXXXXXXXX XXXXXX Prod. p/OP No. XXXXXXXXXXX
				cLine    := cProduto+cLocal+(cAliasSD5)->D5_LOTECTL+" "+(cAliasSD5)->D5_NUMLOTE+" Prod. p/OP No. "+(cAliasSD5)->D5_OP	//" Prod. p/OP No. "
				aAreaBack:= FWGetArea()
				cOpAnt   := (cAliasSD5)->D5_OP
				
				If nNivMax > nChamad
					nChamad++
					DBSelectArea("SD5")
			   		SD5->(DBSetOrder(4))
			   		SD5->(MsSeek(xFilial("SD5")+cOPAnt))
			   		While SD5->(!Eof()) .And. xFilial("SD5")+cOpAnt == SD5->D5_FILIAL+SD5->D5_OP
				 		cTmSD3:=AC040TM(SD5->D5_NUMSEQ,SD5->D5_ORIGLAN)
				 		If SubStr(cTmSD3,1,2) == "RE" .And. If(!Empty(SD5->D5_LOTEPRD),cDadosPrd == SD5->D5_LOTEPRD+If(lSubLote,SD5->D5_SLOTEPR,""),.T.)
							If aScan( aRecOrig, {|x| x == SD5->(Recno()) } ) == 0
								aAdd(aRecOrig,SD5->(Recno()))
							EndIf
							MontaLine(aLine,SD5->D5_QUANT,SD5->D5_LOTECTL,SD5->D5_NUMLOTE,SD5->D5_PRODUTO,SD5->D5_LOCAL,cTipo,aRecOrig,SD5->D5_LOTEFOR,,,,@nChamad)
							nPos := aScan( aRecOrig, {|x| x == SD5->(Recno()) } )
							If nPos > 0
								aDel( aRecOrig, nPos )
								aSize( aRecOrig, Len(aRecOrig)-1 )
							EndIf
						EndIf					
						SD5->(DBSkip())
					EndDo   
					nChamad--
				EndIf
				FWRestArea(aAreaBack) 
				DBSelectArea(cAliasSD5)
			EndIf
		EndIf       
		
		// Saida de Material
	ElseIf cTipo == "U" 
		DBSelectArea("SD2")
		SD2->(DBSetOrder(1))
		// Saida atraves de NF
		If SD2->(MsSeek(xFilial("SD2")+(cAliasSD5)->D5_PRODUTO+(cAliasSD5)->D5_LOCAL+(cAliasSD5)->D5_NUMSEQ ))
			DBSelectArea("SF4")
			If SF4->(MsSeek(xFilial("SF4")+SD2->D2_TES))
				// Pesquisa pelo Nome Reduzido do Cliente OU FORNECEDOR
				DBSelectArea(If(SD2->D2_TIPO $ "DB","SA2","SA1"))
				DBSetOrder(1)
				If MsSeek(xFilial(If(SD2->D2_TIPO $ "DB","SA2","SA1"))+SD2->D2_CLIENTE+SD2->D2_LOJA)
					cNomeCli := SubStr(AllTrim(If(SD2->D2_TIPO $ "DB",SA2->A2_NREDUZ,SA1->A1_NREDUZ)),1,15)
				EndIf
				DBSelectArea(cAliasSD5)
				// Remessa para beneficiamento
				If SF4->F4_PODER3 == "R"
					// XXXXXXXXXX XXXXXX NF. p/Benef. N.XXXXXX/XXX
					cLine := c040Produt+cLocal+(cAliasSD5)->D5_LOTECTL+" "+(cAliasSD5)->D5_NUMLOTE+"  NF. p/Benef. N."+(cAliasSD5)->D5_DOC+"/"+SD5->D5_SERIE+" "+SD2->D2_LOJA+"-"+AllTrim(SD2->D2_CLIENTE)+"/"+cNomeCli	//"  NF. p/Benef. N."
					// Devolucao de beneficiamento
				ElseIf SF4->F4_PODER3 == "D"
					// XXXXXXXXXX XXXXXX Dev. Benef.  N.XXXXXX/XXX
					cLine := c040Produt+cLocal+(cAliasSD5)->D5_LOTECTL+" "+(cAliasSD5)->D5_NUMLOTE+"  Dev. Benef. N."+(cAliasSD5)->D5_DOC+"/"+(cAliasSD5)->D5_SERIE+" "+SD2->D2_LOJA+"-"+AllTrim(SD2->D2_CLIENTE)+"/"+cNomeCli	//"  Dev. Benef. N."
				Else
					// Venda
					If SD2->D2_TIPO == "N"
						// XXXXXXXXXX XXXXXX NF. Venda    N.XXXXXX/XXX XXXXXX-XX
						cLine := c040Produt+cLocal+(cAliasSD5)->D5_LOTECTL+" "+(cAliasSD5)->D5_NUMLOTE+"  NF. Venda N."+(cAliasSD5)->D5_DOC+"/"+(cAliasSD5)->D5_SERIE+" "+SD2->D2_CLIENTE+"-"+SD2->D2_LOJA+"/"+cNomeCli	//"  NF. Venda N."
						// Devolucao
					ElseIf SD2->D2_TIPO == "D"
						// XXXXXXXXXX XXXXXX NF.Dv.Compra N.XXXXXX/XXX
						cLine := c040Produt+cLocal+(cAliasSD5)->D5_LOTECTL+" "+(cAliasSD5)->D5_NUMLOTE+"  NF.Dv.Compra N."+(cAliasSD5)->D5_DOC+"/"+(cAliasSD5)->D5_SERIE	//"  NF.Dv.Compra N."
					EndIf
				EndIf
				nQuantOrig:=(cAliasSD5)->D5_QUANT
				lNfiscal := .T.
			EndIf
			DBSelectArea(cAliasSD5)
			// Saida por movimentos internos
		Else	
			DBSelectArea(cAliasSD5)
			cTmSD3:=AC040TM((cAliasSD5)->D5_NUMSEQ,(cAliasSD5)->D5_ORIGLAN)
			If cTmSD3 $ "RE3/RE4"
				aLotePara := BuscaLoteRE4((cAliasSD5)->D5_NUMSEQ,  (cAliasSD5)->RECNOSD5 )
				If Len(aLotePara) > 0
					// XXXXXXXXXX XXXXXX Trf. p/ XXXXXXXXXX/XXXXXX
					cLine := aLotePara[3]+aLotePara[4]+(cAliasSD5)->D5_LOTECTL+" "+(cAliasSD5)->D5_NUMLOTE+If(cTmSD3=="RE3"," Transferido para processo ","Transfer. para  ")+aLotePara[1]+If(Rastro(aLotePara[3],"S"),"/"+aLotePara[2],"")
					nQuantOrig:=(cAliasSD5)->D5_QUANT
					If lSubLote .Or. aLotePara[1] # (cAliasSD5)->D5_LOTECTL
						If aScan( aRecOrig, {|x| x == (cAliasSD5)->RECNOSD5 } ) == 0
							aAdd(aRecOrig,(cAliasSD5)->RECNOSD5)
						EndIf
						MontaLine(aLine,(cAliasSD5)->D5_QUANT,aLotePara[1],aLotePara[2],aLotePara[3],aLotePara[4],cTipo,aRecOrig,aLotePara[5],aLotePara[6],,,@nChamad)
						nPos := aScan( aRecOrig, {|x| x == (cAliasSD5)->RECNOSD5 } )
						If nPos > 0
							aDel( aRecOrig, nPos )
							aSize( aRecOrig, Len(aRecOrig)-1 )
						EndIf
					EndIf
				Else
					cProdD3 := ""
					cLocal  := ""
					SD3->(DBSetOrder(4))
					If SD3->(DBSeek(xFilial("SD3")+(cAliasSD5)->D5_NUMSEQ))
						SD3->(DBSkip())
						cProdD3 := SD3->D3_COD
						cLocal  := SD3->D3_LOCAL
					EndIf
					cLine := cProdD3+cLocal+(cAliasSD5)->D5_LOTECTL+" "+(cAliasSD5)->D5_NUMLOTE+"Transfer. para  "+"PRODUTO SEM RASTREABILIDADE"	//"  Trf. p/ "
					nQuantOrig:=(cAliasSD5)->D5_QUANT
				EndIf

			ElseIf cTmSD3 == "RE6"
				aLotePara := BuscaLoteRE4((cAliasSD5)->D5_NUMSEQ, (cAliasSD5)->RECNOSD5 )
				If (cAliasSD5)->D5_LOCAL == cLocCq
					If SB8->B8_LOCAL == cLocCQ
						// XXXXXXXXXX XXXXXX Rejeitado p/  XXXXXXXXXX/XXXXXX
						cLine := aLotePara[3]+aLotePara[4]+(cAliasSD5)->D5_LOTECTL+" "+(cAliasSD5)->D5_NUMLOTE+"  Rejeitado p/  "+aLotePara[1]+If(Rastro(aLotePara[3],"S"),"/"+aLotePara[2],"")	//"  Rejeitado p/  "
					Else
					// XXXXXXXXXX XXXXXX Liberado p/  XXXXXXXXXX/XXXXXX
						cLine := aLotePara[3]+aLotePara[4]+(cAliasSD5)->D5_LOTECTL+" "+(cAliasSD5)->D5_NUMLOTE+"  Liberado p/  "+aLotePara[1]+If(Rastro(aLotePara[3],"S"),"/"+aLotePara[2],"") //"  Liberado p/  "
					EndIf
					nQuantOrig:=(cAliasSD5)->D5_QUANT
					If lSubLote
						If aScan( aRecOrig, {|x| x == (cAliasSD5)->RECNOSD5 } ) == 0
							aAdd(aRecOrig,(cAliasSD5)->RECNOSD5)
						EndIf
						MontaLine(aLine,(cAliasSD5)->D5_QUANT,aLotePara[1],aLotePara[2],aLotePara[3],aLotePara[4],cTipo,aRecOrig,aLotePara[5],aLotePara[6],,,@nChamad)
						nPos := aScan( aRecOrig, {|x| x == (cAliasSD5)->RECNOSD5 } )
						If nPos > 0
							aDel( aRecOrig, nPos )
							aSize( aRecOrig, Len(aRecOrig)-1 )
						EndIf
					EndIf
				Else
					// XXXXXXXXXX XXXXXX Consumo Interno
					cLine := c040Produt+cLocal+(cAliasSD5)->D5_LOTECTL+" "+(cAliasSD5)->D5_NUMLOTE+"  Consumo Interno"	// "  Consumo Interno"
				EndIf

			ElseIf cTmSD3 $ "RE0/RE1/RE2/RE5/RE9"
				If !Empty((cAliasSD5)->D5_OP)
					If Len(aLotePara:=BuscaOP(.T.,.T.,(cAliasSD5)->D5_LOTECTL,(cAliasSD5)->D5_NUMLOTE,(cAliasSD5)->D5_NUMSEQ,(cAliasSD5)->D5_OP,(cAliasSD5)->D5_LOTEPRD,(cAliasSD5)->D5_SLOTEPR, (cAliasSD5)->RECNOSD5 ,aLotVolta)) > 0
						// XXXXXXXXXX XXXXXX Op N. XXXXXXXXXXX  XXXXXXXXXX/XXXXXX
						cLine := aLotePara[3]+aLotePara[4]+(cAliasSD5)->D5_LOTECTL+" "+(cAliasSD5)->D5_NUMLOTE+"  Op N. "+(cAliasSD5)->D5_OP+"  "+aLotePara[1]+If(Rastro(aLotePara[3],"S"),"/"+aLotePara[2],"")	//"  Op N. "
						If aScan( aRecOrig, {|x| x == (cAliasSD5)->RECNOSD5 } ) == 0
							aAdd(aRecOrig,(cAliasSD5)->RECNOSD5)
						EndIf
						MontaLine(aLine,(cAliasSD5)->D5_QUANT,aLotePara[1],aLotePara[2],aLotePara[3],aLotePara[4],cTipo,aRecOrig,aLotePara[5],(cAliasSD5)->D5_NUMSEQ,aLotePara[6],,@nChamad)
						nPos := aScan( aRecOrig, {|x| x == (cAliasSD5)->RECNOSD5 } )
						If nPos > 0
							aDel( aRecOrig, nPos )
							aSize( aRecOrig, Len(aRecOrig)-1 )
						EndIf
					Else
						// XXXXXXXXXX XXXXXX Op N. XXXXXXXXXXX  XXXXXXXXXX/XXXXXX
						cLine     := c040Produt+cLocal+(cAliasSD5)->D5_LOTECTL+" "+(cAliasSD5)->D5_NUMLOTE+"  Op N. "+(cAliasSD5)->D5_OP	//"  Op N. "
						nQuantOrig:=(cAliasSD5)->D5_QUANT
					EndIf	
				Else
					// XXXXXXXXXX XXXXXX Consumo Interno
					cLine     := c040Produt+cLocal+(cAliasSD5)->D5_LOTECTL+" "+(cAliasSD5)->D5_NUMLOTE+"  Consumo Interno"	//"  Consumo Interno"
					nQuantOrig:=(cAliasSD5)->D5_QUANT
				EndIf
			ElseIf cTmSD3 == "RE7" .And. Empty(cOP)
				// XXXXXXXXXXX XXXXXX Desmontagem p/
				cLine     := c040Produt+cLocal+(cAliasSD5)->D5_LOTECTL+" "+(cAliasSD5)->D5_NUMLOTE+" Desmontagem p/ "+(cAliasSD5)->D5_LOTECTL+If(lSubLote,"/"+(cAliasSD5)->D5_NUMLOTE,"")	   //" Desmontagem p/ "
				nQuantOrig:=(cAliasSD5)->D5_QUANT
			EndIf
		EndIf
	EndIf

	If !Empty(cLine)
		aTam := aTamSB1
		lOp  := .T.
		If Len(aLine) > 0
			// Verifica se o ultimo registro e a da mesma OP
			If SubStr(cLine,aTam[1]+20,6) == "  Op N. "
				If SubStr(cLine,aTam[1]+20,12) == SubStr(aLine[Len(aLine),3],1,12)
					lOp := .F.
				EndIf
			EndIf
		EndIf
		cProduto:= SubStr(cLine,1,aTam[1])
		
		cNumSeri:= If( lEnde ,(cAliasSD5)->DB_NUMSERI, aSDB[nX][2] )
		cLocaliz:= If( lEnde ,(cAliasSD5)->DB_LOCALIZ, aSDB[nX][1] )
		nRecSDB := If( lEnde ,(cAliasSD5)->RECNOSDB  , aSDB[nX][3] )
		
		aVarAux := {SubStr(cLine,aTam[1]+1+ nArmazem, nLote),;                     					    	  				//[01] Lote
					SubStr(cLine,aTam[1]+2+ nArmazem + nLote , nSubLote),;							   						//[02] SubLote
					SubStr(cLine,aTam[1]+2+ nArmazem + nLote + nSubLote,55),;												//[03] Historico
					Trans(IIf(lEnde,(cAliasSD5)->DB_QUANT,(cAliasSD5)->D5_QUANT),cPictQtde),;								//[04] Quantidade (c)
					cProduto,;																								//[05] Prod.Destino/Origem
					SubStr(cLine,aTam[1]+1,Len(cLocal)),;																	//[06] Amz Dest
					(cAliasSD5)->D5_LOTEFOR,;																				//[07] Lote do Fornecedor
					If(SubStr(cLine,aTam[1]+1,Len(cLocal))==cLocCQ.Or.!lOp,"0",Trans((cAliasSD5)->D5_QUANT,cPictQtde)),; 	//[08] Quantidade (n)
					If(lNfiscal,(cAliasSD5)->D5_NUMSEQ,""),; 																//[09] Se For nota fiscal grava o numero sequencial
					(cAliasSD5)->RECNOSD5,;                 																//[10] Nro registro SD5
					cLocaliz											,;													//[11] Endereço
					cNumSeri											,;													//[12] Nro Serie
					nRecSDB 											}													//[13] Nro Registro SBF
					 

		If !Empty(aLine)
			If lSubLote
				nSeekChav := aScan(aLine,{|x|x[1]+x[2]+x[3]+x[4]+x[9]==aVarAux[1]+aVarAux[2]+aVarAux[3]+aVarAux[4]+aVarAux[9] .And. x[5]==cProduto .And. x[ 12 ] == cNumSeri .And. x[ 13 ] == nRecSDB } )
 			Else
				nSeekChav := aScan(aLine,{|x|x[1]+x[3]+x[4]+x[9]==aVarAux[1]+aVarAux[3]+aVarAux[4]+aVarAux[9] .And. x[5]==cProduto .And. x[ 12 ] == cNumSeri .And. x[ 13 ] == nRecSDB } )
			EndIf
			If !Empty(nSeekChav)
				If !lSubLote .And. ( "PR" $ AC040TM((cAliasSD5)->D5_NUMSEQ,(cAliasSD5)->D5_ORIGLAN) )
					aLine[nSeekChav,4] := Trans(Val(aLine[nSeekChav,4])+(cAliasSD5)->D5_QUANT,cPictQtde)
					DBSelectArea(cAliasSD5)
					(cAliasSD5)->(DBSkip())
					Loop
				EndIf
			EndIf
			If lEnde
				nSeekChav := aScan(aLine,{|x|x[1]+x[3]+x[4]+x[9]+x[11]==aVarAux[1]+aVarAux[3]+aVarAux[4]+aVarAux[9]+aVarAux[11] .And. x[5]==cProduto .And. x[ 12 ] == cNumSeri .And. x[ 13 ] == nRecSDB } )
				If !Empty(nSeekChav)
					DBSelectArea(cAliasSD5)
					(cAliasSD5)->(DBSkip())
					Loop			
				EndIf
			EndIf
		EndIf
	        
		If lRet
			// Cria array com as informacoes das movimentacoes do Lote/SubLote
			aAdd(aLine,aVarAux)
		EndIf
		
	EndIf
	DBSelectArea(cAliasSD5)
	(cAliasSD5)->(DBSkip())
 EndDo
 
 (cAliasSD5)->(DBCloseArea())
 
 FWRestArea(aAreaSD5)
 FWRestArea(aArea)

Return

/*
===============================================================================================================================
Programa----------: BuscaLoteRE4
Autor-------------: Alex Wallauer
Data da Criacao---: 11/11/2024
Descricao---------: Copia da Funcao Static Function BuscaLoteRE4 () do (MATC040.PRX)
Parametros--------: cNumSeq,nRecno
Retorno-----------: aRetorno
===============================================================================================================================
*/ 
Static Function BuscaLoteRE4(cNumSeq,nRecno)
 Local aOldAlias:= FWGetArea()
 Local aVolta   := {}
 Default cNumSeq := ""
 Default nRecno  := 0
 
 SD5->(DBSetOrder(3))
 SD5->(DBSeek(xFilial("SD5")+cNumSeq))
 While SD5->(!Eof()) .And. xFilial("SD5")+cNumSeq == SD5->(D5_FILIAL+D5_NUMSEQ)
 	//-- Impede o Processamento de Movimenta‡oes Estornadas
 	If !Empty(SD5->D5_ESTORNO)
 		SD5->(DBSkip())
 		Loop
 	EndIf
 	If SD5->(Recno()) != nRecno
 	   aVolta:={SD5->D5_LOTECTL,SD5->D5_NUMLOTE,SD5->D5_PRODUTO,SD5->D5_LOCAL,SD5->D5_LOTEFOR,SD5->D5_NUMSEQ}//06 colunas
 	   Exit
 	EndIf
 	SD5->(DBSkip())
 End
 
 SB8->(DBSetOrder(3))
 SB8->(DBSeek(xFilial("SB8")+SD5->D5_PRODUTO+SD5->D5_LOCAL+SD5->D5_LOTECTL+SD5->D5_NUMLOTE))
 
 FWRestArea(aOldAlias)
Return (aVolta)

/*
===============================================================================================================================
Programa----------: BuscaLtRE7
Autor-------------: Alex Wallauer
Data da Criacao---: 11/11/2024
Descricao---------: Copia da Funcao Static Function BuscaLtRE7 () do (MATC040.PRX)
Parametros--------: cNumSeq,nRecno
Retorno-----------: aVolta
===============================================================================================================================
*/ 
Static Function BuscaLtRE7(cNumSeqSD5,cNumOp)
 Local aVolta:= {}
 Default cNumSeqSD5 := "" 
 SD5->(DBSetOrder(4))
 If SD5->(MsSeek(xFilial("SD5")+cNumOP+cNumSeqSD5))
 	aVolta:={SD5->D5_LOTECTL,SD5->D5_NUMLOTE,SD5->D5_PRODUTO,SD5->D5_LOCAL,SD5->D5_LOTEFOR,SD5->D5_NUMSEQ}//06 colunas
 EndIf
Return (aVolta)

/*
===============================================================================================================================
Programa----------: BuscaOP
Autor-------------: Alex Wallauer
Data da Criacao---: 11/11/2024
Descricao---------: Copia da Funcao Static Function BuscaOP () do (MATC040.PRX)
Parametros--------: lProducao,lDadosPrd,cLoteCtl,cNumLote,cNumSeq,cOp,cLotePrd,cSLotePr,nRecno,aLotVolta
Retorno-----------: aVolta
===============================================================================================================================
*/ 
Static Function BuscaOP(lProducao,lDadosPrd,cLoteCtl,cNumLote,cNumSeq,cOp,cLotePrd,cSLotePr,nRecno,aLotVolta)
 Local aAreaAnt   := FWGetArea()
 Local aAreaSD5   := SD5->(GetArea())
 Local cDadosPrd1 := If(lDadosPrd,cLotePrd,"")
 Local cDadosPrd2 := If(lDadosPrd .And. !Empty(cSLotePr),cSLotePR,"")
 Local aVolta     := {}
 Local cSeek     := ""
 Local lAchou     := .F.
 Local nScan		 := 0
 
 Default cLoteCtl := ""
 Default cNumlote := ""
 Default cNumSeq  := ""
 Default cOp      := ""
 Default nRecno   := 0
 Default aLotVolta:= {}
 
 //-- Realiza a Pesquisa nas Movimentacoes pelo Numero da OP
 //-- (Mesmo que as Requisicoes tenham sido Manuais pode-se achar a Producao)
 
 If !Empty(cOP)
	DBSelectArea("SD3")
	DBSetOrder(1)
	SD3->(DBSeek(cSeek := xFilial("SD3")+cOP, .F.))
	
	While !Eof() .And. cSeek == SD3->D3_FILIAL + SD3->D3_OP .And. !lAchou
		If !Empty(SD3->D3_ESTORNO) .And. Empty(SD3->D3_OP)
			SD3->(DBSkip())
			Loop
		EndIf
		If SD3->D3_TM < '500'
			//Se o protudo destino nao tiver rastro, buscar os dados na SD3
			If !Rastro(SD3->D3_COD)
				
				aVolta := {SD3->D3_LOTECTL, SD3->D3_NUMLOTE, SD3->D3_COD, SD3->D3_LOCAL,Posicione("SD5",4,xFilial("SD3")+cOp,"D5_LOTEFOR"),cOP}//06 colunas
			
			//Se tiver rastro, buscar os dados na SD5
			Else
				DBSelectArea("SD5")
				DBSetOrder(4)
				SD5->(DBSeek(cSeek := xFilial("SD5")+cOP, .F.))
	
				//-- Procura Inicialmente pelo Movimento de Producao
				While SD5->(!Eof()) .And. cSeek == SD5->D5_FILIAL+SD5->D5_OP .And. !lAchou
					If !Empty(SD5->D5_ESTORNO) .Or. Recno() == nRecno .And. Empty(SD5->D5_OP)
						SD5->(DBSkip())
						Loop
					EndIf
			        nScan := aScan(aLotVolta, SD5->D5_LOTECTL)
					If SD5->D5_ORIGLAN < '500' .And. If(lProducao,(cLoteCtl+cNumLote==SD5->D5_LOTECTL+SD5->D5_NUMLOTE),!(cLoteCtl+cNumLote==SD5->D5_LOTECTL+SD5->D5_NUMLOTE) .And. nScan=0)
						
						aVolta := {SD5->D5_LOTECTL, SD5->D5_NUMLOTE, SD5->D5_PRODUTO, SD5->D5_LOCAL, SD5->D5_LOTEFOR,cOP}//06 colunas
						
						aAdd(aLotVolta,SD5->D5_LOTECTL) 
						lAchou := .T.
						If SD5->D5_NUMSEQ == cNumSeq .Or. (!lProducao .And. lDadosPrd .And. cDadosPrd1 == SD5->D5_LOTECTL .And. If(Empty(cDadosPrd2),.T.,cDadosPrd2 == SD5->D5_NUMLOTE))
							lAchou := .T.
						EndIf  
						Loop
					EndIf
					SD5->(DBSkip())
				EndDo
			EndIf						
			If SD3->D3_NUMSEQ == cNumSeq
				lAchou := .T.
			EndIf
		EndIf	
		SD3->(DBSkip())
	End    
 EndIf

 FWRestArea(aAreaSD5)
 FWRestArea(aAreaAnt)

Return (aVolta)

/*
===============================================================================================================================
Programa----------: A040Imp
Autor-------------: Alex Wallauer
Data da Criacao---: 11/11/2024
Descricao---------: Copia da Funcao Static Function A040Imp () do (MATC040.PRX)
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/ 
Static Function A040Imp()
 Local cTitulo := "Rastreamento de Lotes"
 Local cDesc1  := "Este programa ira imprimir a Consulta do Produto selecionado"
 Local cDesc2  := "informando o Rastreamento do seu Lote"
 Local cString := "SB8"
 Local cTamanho:= "G"
 Local cPergRel:= "      "
 Local oTree   := _aObjetos[oTFolder01:nOption]//pega o tree da pasta selecionada
 If oTree = NIL 
 	U_ITMsg("Posicione sobre algum item da consulta do lote de uma das pastas !!!",'Atenção!',,3)
    Return .F.
 EndIf

 Private aReturn := {"Zebrado", 1,"Administracao", 1, 2, 1, "", 1 }   
 Private nLastKey:= 0
 Private wnrel 	:= "MATC040"

 If SubStr(oTree:GetCargo(),1,3) == "SB1"
 	U_ITMsg("Posicione sobre algum item da consulta do lote de uma das pastas !!!",'Atenção!',,3)
 Else
 	wnRel:= SetPrint(cString,wnrel,cPergRel,@cTitulo,cDesc1,cDesc2,"",.F.,"",.F.,cTamanho)
 	If !nLastKey == 27
 		SetDefault( aReturn, cString )
 		If !nLastKey == 27
           _aRegsA:=MC040View(oTree,,,,,_aRegsA,aLine,1,.T.)
           _aRegsB:=MC040View(oTree,,,,,_aRegsB,aLine,2,.T.)

 	       RptStatus({|lEnd| C040Imp(@lEnd,ctitulo,wnRel,0,0,cTamanho,{_aRegsA,_aRegsB})},ctitulo)

		   CETS3Change()

 		EndIf
 	EndIf
 EndIf

Return 


/*
===============================================================================================================================
Programa----------: C040Imp
Autor-------------: Alex Wallauer
Data da Criacao---: 11/11/2024
Descricao---------: Copia da Funcao Static Function C040Imp () do (MATC040.PRX)
Parametros--------: lEnd,ctitulo,wnRel,nSaldo,nSaldoLote,cTamanho,aRegs2
Retorno-----------: .T.
===============================================================================================================================
*/ 
Static Function C040Imp(lEnd,ctitulo,wnRel,nSaldo,nSaldoLote,cTamanho,aRegs2)
 Local cCabec1   := ""
 Local cCabec2   := ""
 Local cNomeProg := "MATC040"
 Local cbtxt     := Space( 10 )
 Local cbcont    := 0
 Local nI := R   := 0
 Local lCol      := .T.
 Local nDifTam   := TamSX3("B1_COD")[1]  // diferenca a ser acrescida as colunas 
 Local nLote	 := TamSX3("D5_LOTECTL")[1]
 Local nLocal    := TamSX3('B2_LOCAL')[1]    
 Local nEnd	     := TamSX3('DB_LOCALIZ')[1]
 Local nNumSeri  := TamSX3('DB_NUMSERI')[1] 
 Local nHistorico:= 0
 Local nEspaco   := 2                   
 Local nTot1 	
 Local nTot2 
 Local nTot3 
 Local nTot4 
 Local nTot5	
 Local nTot6
 Local cPicB8Sld:= PesqPictQT("B8_SALDO",14)
 Private li:= 80
 Private m_pag:= 1
 
 //  Posicao do inicio das colunas dos registros impressos         
 For R:=1 to Len(aRegs2)
     aRegsI:=ACLONE(aRegs2[R])
     For nI:=1 to Len(aRegsI) 
     	If (Len(aRegsI[nI,2]) > nHistorico)
     		nHistorico := Len(aRegsI[nI,2])
     	EndIf
     Next nI
 Next R
 If nHistorico < 24 
 	nHistorico := 55
 EndIf
 If nLote < 10 
 	nLote:=10
 EndIf
 
 If Rastro(SB8->B8_PRODUTO, "L")     
 
 	nTot1 	:= nLote+nEspaco+1 		    	//Historico
 	nTot2 	:= nTot1+nHistorico+nEspaco 	//Produto Origem/Dest.
 	nTot3 	:= nTot2+nDifTam+nEspaco     	//Amz Dest
 	nTot4 	:= nTot3+8+nEspaco 	   			//Endereco	
 	nTot5	:= nTot4+nEnd+nEspaco			//Nro Serie
 	nTot6	:= nTot5+nNumSeri+nEspaco		//Quantidade
 
 Else
 
 	nTot1 	:= nLote+nEspaco+1 		    	//Sublote
    nTot2	:= nTot1+8+nEspaco	   			//Historico
 	nTot3 	:= nTot2+nHistorico+nEspaco 	//Produto Origem/Dest.
 	nTot4 	:= nTot3+nDifTam+nEspaco    	//Amz Dest
 	nTot5 	:= nTot4+8+nEspaco 	   			//Endereco	
 	nTot6	:= nTot5+nEnd+nEspaco			//Nro Serie
 	nTot7	:= nTot6+nNumSeri+nEspaco		//Quantidad	     
 	
 EndIf
 
 //  Inicializa variaveis para controlar cursor de progressao      
 SetRegua( Len(aRegs2[1]) + Len(aRegs2[2]) )
 MV_PAR01=1
 For R:=1 to Len(aRegs2)// 1 e 2

     aRegsI:=ACLONE(aRegs2[R])
     li:=80
     nSaldo    :=_aTotais[R,4]
     nSaldoLote:=_aTotais[R,5]
     cCabec1   := "Rastreamento de Lotes/SubLotes"+" -"+If(R==1," Onde é Usado "," Composicao ")
 
     For nI:=1 to Len(aRegsI)
     
     	Incregua()
     
     	If li > 60
     		li := cabec( cTitulo, cCabec1, cCabec2, cNomeProg, cTamanho )
     		li++
     		@ li,  005 PSAY "Lote" + " " + SB8->B8_LOTECTL  						
     		If Rastro(SB1->B1_COD, "S")
     			@ li,030 PSAY "Sub-Lote" + " " + SB8->B8_NUMLOTE    				
     		EndIf
     		@ li++,050 PSAY "Validade: " + DToC(SB8->B8_DTVALID)
     		@ li++,005 PSAY "Produto: " + SB8->B8_PRODUTO + " - " + SB1->B1_DESC 
     		@ li++,005 PSAY "Armazem: " + SB8->B8_LOCAL
     		If Rastro(SB1->B1_COD, "S")
     			@ li,005 PSAY  "Lote do Fornecedor: " + SB8->B8_LOTEFOR
     		EndIf
     		li++
     		@ li,  005 PSAY "Saldo:"
     		@ li++,011 PSAY If(Rastro(SB1->B1_COD, "S"), nSaldo, nSaldoLote)  Picture cPicB8Sld 
     		If Rastro(SB1->B1_COD, "S")
     			@ li,005 PSAY "Criacao: " + DToC(SB8->B8_DATA)
     		EndIf
             li++
     		@ li++,000 PSAY __PrtThinLine()
     		If Rastro(SB8->B8_PRODUTO,"L")
     			@ li,001 PSAY "Lote"+Space(nLote-4+nEspaco)+"Historico dos Movimentos" +Space(nHistorico-24+nEspaco)+If(MV_PAR01=1,"Prod.Dest." ,"Prod.Orig.")+Space(nDifTam+nEspaco-10)+"Amz Dest"+Space(nEspaco)+"Endereço"+Space(nEnd+nEspaco-8)+"Num. de série"+Space(nNumSeri+nEspaco-13)+"Quantidade"
     			lCol := .F.
     		Else	
     			@ li,001 PSAY "Lote"+Space(nLote-4+nEspaco)+"Sub-Lote"+Space(nEspaco)+"Historico dos Movimentos" +Space(nHistorico-24+nEspaco)+If(MV_PAR01==1,"Prod.Dest." ,"Prod.Orig.")+Space(nDifTam+nEspaco-10)+"Amz Dest"+Space(nEspaco)+"Endereço"+Space(nEnd+nEspaco-8)+"Num. de série"+Space(nNumSeri+nEspaco-13)+"Quantidade"
     		EndIf
     		li ++
     		@ li,000 PSAY __PrtThinLine()
     		li ++
     	EndIf
     
     	@ li,001 	 PSAY  aRegsI[nI,1]		//Lote
     	If lCol
     		@ li,nTot1 PSAY  aRegsI[nI,2]		//SubLote
     		@ li,nTot2 PSAY  aRegsI[nI,3]		//Historico
     		@ li,nTot3 PSAY  aRegsI[nI,4]		//Produto Origem/Dest. 
     		If Len( aRegsI[nI,5]) >0
     	   		@ li,nTot4 PSAY  aRegsI[nI,5]	//Amz Dest
     	 	Else
     			@ li,nTot4 PSAY Space (8)
     		EndIf
     		If Len( aRegsI[nI,8]) >0
     			@ li,nTot5 PSAY  aRegsI[nI,9]		 //Endereco
     		Else     
     			@ li,nTot5 PSAY Space (nEnd)
     		EndIf
     	    If !lSubLote
     	   		@ li,nTot6 PSAY  aRegsI[nI,9]      //Nro Serie
     	   	Else
     			@ li,nTot6 PSAY  aRegsI[nI,10]      //Nro Serie
     			@ li,nTot7  PSAY  aRegsI[nI,6]    //Quantidade	   	
     	   	EndIf	
     	Else
     		@ li,nTot1 PSAY  aRegsI[nI,2]		//Historico
     		@ li,nTot2 PSAY  aRegsI[nI,3]		//Produto Origem/Dest.
     		If Len( aRegsI[nI,4]) >0
     	   		@ li,nTot3 PSAY  aRegsI[nI,4]	//Amz Dest
     		Else
     			@ li,nTot3 PSAY Space (nLocal)
     		EndIf
     		If Len( aRegsI[nI,8]) >0
     			@ li,nTot4 PSAY  aRegsI[nI,8]		//Endereco	
     		Else
     	    	@ li,nTot4 PSAY Space (nEnd)
     	 	EndIf
     		@ li,nTot5 PSAY  aRegsI[nI,9]    //Nro Serie
     		@ li,nTot6 PSAY  aRegsI[nI,5]		//Quantidade
     	EndIf
     	li++
     Next nI
     MV_PAR01=2
 Next T

 If li != 80
 	li++
 	roda(cbcont,cbtxt,cTamanho)
 EndIf
 
 If aReturn[5] = 1
 	Set Printer To
 	dbCommitAll()
 	ourspool(wnrel)
 EndIf
 
 MS_FLUSH()

Return( .T. )


/*
===============================================================================================================================
Programa----------: CETS3Change
Autor-------------: Alex Wallauer
Data da Criacao---: 11/11/2024
Descricao---------: Funcao Executa na troca de pasta, pesquisa e impressao
Parametros--------: Nenhum
Retorno-----------: .T.
===============================================================================================================================
*/ 
Static Function CETS3Change()

 If oTFolder01:nOption = 1
   If Len(_aRegsA) > 0
      MC040View(@_oTree1,@_oLbx1,@_oPanelA,@_oScrollA,@_oPanel1A,_aRegsA,aLine)
   EndIf
 Else
   If Len(_aRegsB) > 0
      MC040View(@_oTree2,@_oLbx2,@_oPanelB,@_oScrollB,@_oPanel1B,_aRegsB,aLine)
   EndIf
 EndIf

Return .T.

/*
===============================================================================================================================
Programa----------: MOMS66Pesq
Autor-------------: Alex Wallauer Ferreira
Data da Criacao---: 28/06/2022
Descrição---------: Pesquisa de Armazem + Lote ou somente Lote
Parametros--------: Nenhum
Retorno-----------: .T.
===============================================================================================================================
*/
Static Function CEST3Pesq()
 Local _oGet1  as object
 Local _oDlg	  as object
 Local _cGet1  := Space(25)
 Local _nOpca  := 0
 Local nPos	  := 0
 Local _lAchou := .F.
 Local oTree   := _aObjetos[oTFolder01:nOption]//pega o tree da pasta selecionada
  
 If oTree = NIL 
    U_ITMsg("Posicione sobre algum item da consulta do lote de uma das pastas !!!",'Atenção!',,3)
    Return .F.
 EndIf
 
 DEFINE MSDIALOG _oDlg TITLE "Pesquisa de Armazem + Lote ou somente Lote" FROM 178,181 TO 259,697 PIXEL 
 
 @005,003 Say "Digite Arm + -> + Lote, Ex.: 11 -> 123456789012345678 "Of _oDlg Size  330,8 Pixel	//cLocal+" -> "+cLote
 
 @020,003 MsGet _oGet1 Var _cGet1 Size 212,009 PIXEL OF _oDlg COLOR CLR_BLACK Picture "@!" 
 
 DEFINE SBUTTON FROM 004,227 Type 1 ENABLE ACTION ( _nOpca := 1 , _oDlg:End() ) OF _oDlg
 DEFINE SBUTTON FROM 021,227 Type 2 ENABLE ACTION ( _nOpca := 0 , _oDlg:End() ) OF _oDlg
 
 ACTIVATE MSDIALOG _oDlg CENTERED
 
 If _nOpca == 1
    _cGet1 := AllTrim( _cGet1 )
    If oTFolder01:nOption = 1 
       _aDadosTree:=_aDadoTre1
    Else
       _aDadosTree:=_aDadoTre2
    EndIf
    If (nPos := aScan(_aDadosTree,{|P| _cGet1 $ P[1]  }) ) <> 0 
       _cCargo:=AllTrim(_aDadosTree[nPos,2]+_aDadosTree[nPos,3])
    	  _lAchou:=oTree:TreeSeek(_cCargo)
    EndIf				
 Else
    Return .F.
 EndIf
 
 If _lAchou
    //U_ITMsg("O Lote "+_cGet1+" esta na linha "+AllTrim(Str(nPos)) ,'Atenção!',,2) 
    CETS3Change()
 Else
    U_ITMsg("O Lote "+_cGet1+" não foi encontrado." ,'Atenção!',,3) 
 EndIf

Return .T.


/*
===============================================================================================================================
Programa----------: MOMS66Pesq
Autor-------------: Alex Wallauer Ferreira
Data da Criacao---: 28/06/2022
Descrição---------: Visualiza Saldo
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
//Static Function CEST3ViSa()
// //Verifica quel é o folder atual FOLDER ATUAL
// If oTFolder01:nOption = 1
//    nSaldoLote:=_aTotais[1,5]
//    aRegs:=ACLONE(_aRegsA)
//	_oPanel1A:End()
// Else
//    nSaldoLote:=_aTotais[2,5]
//    aRegs:=ACLONE(_aRegsB)
//	_oPanel1B:End()
// EndIf 
// If Len(aRegs) > 0
//    C040SldLT(SB8->B8_LOTECTL,SB8->B8_NUMLOTE,nSaldoLote)
// EndIf
//Return
