 /*
===============================================================================================================================
                                    ATUALIZACOES SOFRIDAS DESDE A CONSTRUÇAO INICIAL
===============================================================================================================================
     Autor      |    Data    |                                             Motivo                                            
------------------------------------------------------------------------------------------------------------------------------- 
 Alex Wallauer  | 02/06/2023 | Chamado 44435. Tratamento para a Nova pergunta "Imprimir etiqueta com o produto?".
==============================================================================================================================================================
Analista - Programador   - Inicio   - Envio    - Chamado - Motivo da Alteração
==============================================================================================================================================================
Alex     - Igor Melgaço  - 02/05/25 - 06/05/25 -  50525  - Ajuste para remoção de diretório Local C:\SMARTCLIENT\.
==============================================================================================================================================================
*/

#Include "RWMAKE.CH"
#Include "TOTVS.ch"
#Include "RPTDEF.CH"
#Include "FWPrintSetup.ch"

/*
===============================================================================================================================
Programa----------: ROMS066
Autor-------------: Alex Wallauer
Data da Criacao---: 29/11/2021
===============================================================================================================================
Descrição---------: Emissão de etiquetas de produtos PARA AMAZON, CHAMADO 38440
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/  

User Function ROMS066()

Local   nI
Local _aParAux:={}
Local _aParRet:={}
Local _bOK:=NIL
Private _aItensNF:= {}
Private _cDifVal:=""

_aItalac_F3:={}

_cSelectSA1:="SELECT DISTINCT A1_COD, A1_NOME, A1_LOJA   FROM "+RETSQLNAME("SA1")+" SA1 WHERE A1_MSBLQL <> '1' AND A1_NOME LIKE '%AMAZON S%' AND D_E_L_E_T_ = ' ' ORDER BY A1_COD, A1_LOJA " 
_bCondSA1  :=NIL//{|| If(MV_PAR07="2",(A1_MSBLQL = "1"),(A1_MSBLQL <> "1")) }
//aAdd(_aItalac_F3,{"MV_PAR01","SA1",SA1->(FIELDPOS("A1_COD")),{|| SA1->A1_LOJA+"-"+SA1->A1_NOME } ,_bCondSA1 ,"Clientes",,,} )
aAdd(_aItalac_F3,{"MV_PAR02",_cSelectSA1,{|Tab| (Tab)->A1_COD }, {|Tab| (Tab)->A1_LOJA+" "+(Tab)->A1_NOME } ,_bCondSA1 ,"Clientes",,,,.F.        ,       , } )

// D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM 
_BSelectSF2:={|| "SELECT DISTINCT D2_FILIAL, D2_DOC, D2_SERIE, D2_CLIENTE, D2_LOJA FROM "+RETSQLNAME("SD2")+" SD2 WHERE"+;
                 " D2_FILIAL  IN "+FormatIn(AllTrim(MV_PAR01),";")+" AND"+;
                 " D2_TP = 'PA' AND "+;
				 If(!Empty(MV_PAR02)," D2_CLIENTE IN "+FormatIn(AllTrim(MV_PAR02),";")+" AND","")+;
				 If(!Empty(MV_PAR03)," D2_SERIE   IN "+FormatIn(AllTrim(MV_PAR03),";")+" AND","")+;
                 If(!Empty(MV_PAR06)," D2_EMISSAO >= '"+DToS(MV_PAR06) + "' AND"             ,"")+;
                 If(!Empty(MV_PAR07)," D2_EMISSAO <= '"+DToS(MV_PAR07) + "' AND"             ,"")+;
				 " D_E_L_E_T_ = ' ' ORDER BY D2_FILIAL, D2_DOC, D2_SERIE " }
aAdd(_aItalac_F3,{"MV_PAR04",_BSelectSF2,{|Tab| (Tab)->D2_DOC }, {|Tab| (Tab)->D2_FILIAL+" "+AllTrim((Tab)->D2_SERIE)+" "+(Tab)->D2_CLIENTE+" "+(Tab)->D2_LOJA } , ,"NOTAS",,,,.F.        ,       ,{|L,D| U_ROM66VAL(L,D) } } )

_BSelectDAI:={|| "SELECT DISTINCT DAI_FILIAL, DAI_COD, DAI_CLIENT, DAI_NFISCA, DAI_SERIE FROM "+RETSQLNAME("DAI")+" DAI "+;
	             " 		INNER JOIN "+ RetSqlName("SD2") +" SD2 "+;
	             " 		ON	SD2.D2_FILIAL				= DAI.DAI_FILIAL "+;
	             " 		AND	SD2.D2_DOC					= DAI.DAI_NFISCA "+;
                 " 		AND SD2.D2_SERIE				= DAI.DAI_SERIE "+;
                 " 		AND SD2.D2_CLIENTE				= DAI.DAI_CLIENT "+;
                 " 		AND SD2.D2_LOJA					= DAI.DAI_LOJA "+;
                 "      AND SD2.D2_TP = 'PA' AND "+;
                 If(!Empty(MV_PAR06)," SD2.D2_EMISSAO >= '"+DToS(MV_PAR06) + "' AND"          ,"")+;
                 If(!Empty(MV_PAR07)," SD2.D2_EMISSAO <= '"+DToS(MV_PAR07) + "' AND"          ,"")+;
				 " SD2.D_E_L_E_T_ = ' ' "+;
                 " WHERE DAI_FILIAL IN "+FormatIn(AllTrim(MV_PAR01),";")+" AND "+;
                 If(!Empty(MV_PAR02)," DAI.DAI_CLIENT IN "+FormatIn(AllTrim(MV_PAR02),";")+" AND","")+;
				 If(!Empty(MV_PAR03)," DAI.DAI_SERIE  IN "+FormatIn(AllTrim(MV_PAR03),";")+" AND","")+;
                 If(!Empty(MV_PAR04)," DAI.DAI_NFISCA IN "+FormatIn(AllTrim(MV_PAR04),";")+" AND","")+;
                 " DAI.D_E_L_E_T_ = ' ' ORDER BY DAI_FILIAL, DAI_COD, DAI_CLIENT, DAI_NFISCA " }
aAdd(_aItalac_F3,{"MV_PAR05",_BSelectDAI,{|Tab| (Tab)->DAI_COD }, {|Tab| (Tab)->DAI_FILIAL+" "+AllTrim((Tab)->DAI_CLIENT)+" "+(Tab)->DAI_NFISCA+" "+(Tab)->DAI_SERIE } , ,"CARGAS",,,,.F.  ,       ,{|L,D| U_ROM66VAL(L,D) } } )

MV_PAR01:=Space(100)
MV_PAR02:=Space(100)
MV_PAR03:=Space(050)
MV_PAR04:=Space(100)
MV_PAR05:=Space(100)
MV_PAR06:=CTOD("")
MV_PAR07:=CTOD("")
MV_PAR08:=1
//MV_PAR09:="5"
aAdd( _aParAux , { 1 , "Filiais"         , MV_PAR01, "@!"   , ""  ,"LSTFIL"  , "" , 100 , .T. } )
aAdd( _aParAux , { 1 , "Clientes"        , MV_PAR02, "@!"   , ""  , "F3ITLC" , "" , 100 , .T. } )
aAdd( _aParAux , { 1 , "Series"          , MV_PAR03, "@!"	, ""  ,          , "" , 050 , .F. } )
aAdd( _aParAux , { 1 , "Notas"           , MV_PAR04, "@!"	, ""  , "F3ITLC" , "" , 100 , .F. } )
aAdd( _aParAux , { 1 , "Cargas"	         , MV_PAR05, "@!" 	, ""  , "F3ITLC" , "" , 100 , .F. } )
aAdd( _aParAux , { 1 , "Data Emissao de" , MV_PAR06, "@D"	, ""  , ""		 , "" , 050 , .F. } )
aAdd( _aParAux , { 1 , "Data Emissao ate", MV_PAR07, "@D"	, ""  , ""		 , "" , 050 , .F. } )
aAdd( _aParAux , { 3 , "Tipo Etiqueta"   , MV_PAR08, {"Etiqueta da Caixa","Etiqueta do Pallet"}, 99, "", .T., .T. , .T. } )
//aAdd( _aParAux , { 1 , "Tamanho"	     , MV_PAR09, "99" 	, ""  ,          , "" , 15 , .F. } )

For nI := 1 To Len( _aParAux )
	aAdd( _aParRet , _aParAux[nI][03] )
Next 

aTitCol:={}
aAdd(aTitCol,"Nota Fiscal / Carga")                       //01
aAdd(aTitCol,"Chave")                                     //02
aAdd(aTitCol,"Cliente")                                   //03
aAdd(aTitCol,"Fornecedor")                                //04
aAdd(aTitCol,"Pedido Cliente") ;_nPosColPC :=Len(aTitCol) //05
aAdd(aTitCol,"Produto")        ;_nPosColPR :=Len(aTitCol) //06
aAdd(aTitCol,"Lote")           ;_nPosColLO :=Len(aTitCol) //07
aAdd(aTitCol,"Data Fabricacao");_nPosColDF :=Len(aTitCol) //08
aAdd(aTitCol,"Data Validade")  ;_nPosColDV :=Len(aTitCol) //09
aAdd(aTitCol,"Imprimir De")    ;_nPosColDE :=Len(aTitCol) //10
aAdd(aTitCol,"Ate")            ;_nPosColAte:=Len(aTitCol) //11
aAdd(aTitCol,"Qtde Etiquetas") ;_nPosColQE :=Len(aTitCol) //12
aAdd(aTitCol,"Caixas Sobra")   ;_nPosColCS :=Len(aTitCol) //13
aAdd(aTitCol,"Registro")                                  //14

While .T.
	
	If !ParamBox( _aParAux , "GERACAO DE ETIQUETAS PARA AMAZON" , @_aParRet, _bOK  ,, .T. , , , , , .T. , .T.)
		Exit
	EndIf
	//_nTam:=Val(MV_PAR09)
    U_ITLOGACS()
	lEtiqporitem:=.T.
	lPallporitem:=.T.
	If MV_PAR08 = 1
	   lEtiqporitem:=U_ITMsg("Imprimir etiqueta com o produto?",'Atenção!',,2,2,2)
	ElseIf MV_PAR08 = 2
	   lPallporitem:=U_ITMsg("Imprimir Etiquetas de Pallet por Item?",'Atenção!',,2,2,2)
	EndIf
	lTemSobra:=.F.
	_aItensSobra:={}
	_aBrowseT:={}

    FWMsgRun( ,{|oproc| ROMS066Ler(oproc) } ,'Aguarde!','lendo itens da NF...'  )

    If Len(_aItensNF) > 0
       
       aSize:=NIL
       cTit1:="Lista dos itens para imprimir as etiquetas"
       cTit2:=cTit1
       bDblClk:={|| ROMS066GET(@oLbxAux,.F.)}
       While .T.    
    //            ITListBox(_cTitAux , _aHeader , _aCols    , _lMaxSiz ,  nTipo , _cMsgTop , _lSelUnc , _aSizes , _nCampo , bOk , bCancel, _abuttons, _aCab ,bDblClk , _aColXML , bCondMarca,_bLegenda)
          lRet:=U_ITLISTBOX(cTit1    , aTitCol  , _aItensNF , .T.      , 1      , cTit2    ,          , aSize   ,         ,     ,        ,          ,       ,bDblClk )//, _aColXML , bCondMarca,_bLegenda)
    
          If lRet
             If !ROMS066B()
		        Loop
		     EndIf
          EndIf
	      Exit
	   EndDo
    Else
       
       //U_ITMsg("Nao foi possivel ler os itens da NF","Atenção","Verifique se o Cliente é AMAZON",3)
    
       Loop
    EndIf
   
EndDo

Return 
/*
===============================================================================================================================
Programa----------: ROMS066Ler
Autor-------------: Alex Wallauer
Data da Criacao---: 29/11/2021
===============================================================================================================================
Descrição---------: LER OS ITENS DA NF
===============================================================================================================================
Parametros--------: oProc
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================*/  

Static Function ROMS066Ler(oProc)
Local _cAlias := GetNextAlias()
Local _nConta :=0
Local _cQrySD2:= " SELECT R_E_C_N_O_  RECSD2 "
_cQrySD2 += " FROM " + RetSqlName("SD2") + " SD2 "
_cQrySD2 += " WHERE SD2.D_E_L_E_T_ = ' ' "
_cQrySD2 += " AND D2_FILIAL IN " +FormatIn(AllTrim(MV_PAR01),";")
_cQrySD2 += " AND D2_CLIENTE IN "+FormatIn(AllTrim(MV_PAR02),";")
_cQrySD2 += " AND D2_TP = 'PA' "
If !Empty(MV_PAR03)
   _cQrySD2 += " AND D2_SERIE IN "+FormatIn(AllTrim(MV_PAR03),";")
EndIf
If !Empty(MV_PAR04)
   _cQrySD2 += " AND D2_DOC IN "+FormatIn(AllTrim(MV_PAR04),";")
EndIf
If !Empty(MV_PAR06)
   _cQrySD2 += " AND D2_EMISSAO >= '"+DToS(MV_PAR06) + "' "
EndIf
If !Empty(MV_PAR07)
   _cQrySD2 += " AND D2_EMISSAO <= '"+DToS(MV_PAR07) + "' "
EndIf
_cQrySD2 += " ORDER BY D2_DOC,D2_SERIE "

DBUSEAREA( .T. , "TOPCONN" , TcGenQry(,, _cQrySD2 ) , _cAlias , .T., .F. )

COUNT TO _nQtdReg
DBGoTop()
_cTotal:=AllTrim(Str(_nQtdReg))

If Empty( _nQtdReg )
   U_ITMsg("Nao tem dados para consultar com os filtros selecionados","Atenção","Verifique / altere o filtros selecionados",3)
   Return .F.
ElseIf _nQtdReg > 500 .And. !U_ITMsg( "Serão processados "+_cTotal+" registros. Deseja Continuar?",'ATENCAO!',,3,2,2)
   Return .F.
EndIf

SC6->(DBSetOrder(2))
SF2->(DBSetOrder(1))
SB1->(DBSetOrder(1))
_aItensNF:= {}

//SD2->(DBSetOrder(3)) // ITENS DA NOTA FISCAL DE SAÍDA   // D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM
//SD2->(DBSeek(SF2->F2_FILIAL+SF2->F2_DOC+SF2->F2_SERIE+SF2->F2_CLIENTE+SF2->F2_LOJA)) // D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM 
While ! (_cAlias)->(Eof()) //.And. SD2->D2_FILIAL+SD2->D2_DOC+SD2->D2_SERIE+SD2->D2_CLIENTE+SD2->D2_LOJA == ;
                          //    SF2->F2_FILIAL+SF2->F2_DOC+SF2->F2_SERIE+SF2->F2_CLIENTE+SF2->F2_LOJA
  
   SD2->(DBGoTo((_cAlias)->RECSD2))
   SF2->(DBSeek(SD2->D2_FILIAL+SD2->D2_DOC+SD2->D2_SERIE ))

   _nConta++
   oProc:cCaption := "Lendo NF: "+SD2->D2_DOC+" - "+AllTrim(Str(_nConta))+" / "+_cTotal
   ProcessMessages()
   
   If !Empty(MV_PAR05) .And. !Empty( SF2->F2_CARGA ) .And. !AllTrim(SF2->F2_CARGA) $ AllTrim(MV_PAR05)
      (_cAlias)->(DBSkip())
      Loop
   EndIf

   SC6->(DBSeek(SD2->D2_FILIAL+SD2->D2_COD+SD2->D2_PEDIDO+SD2->D2_ITEMPV)) 
   SB1->(DBSeek(xFilial("SB1")+SD2->D2_COD))

   _cChaveNF:=SF2->F2_DOC+"-"+SF2->F2_SERIE+If(!Empty(SF2->F2_CARGA),"/ "+SF2->F2_CARGA,"")
   _nQtdeEtiqueta:= 0
   _nQtSobra := 0
   _cProduto:=SD2->D2_COD
   If MV_PAR08 = 1
      _nQtdeEtiqueta:=SD2->D2_QTSEGUM
      If Posicione("SBZ",1,SD2->D2_FILIAL+SD2->D2_COD,"BZ_I_PR3UM") = "S"
	     _nQtdeEtiqueta:=(SD2->D2_QUANT / SB1->B1_I_QT3UM)//CONVERTER DA 1A UM PARA A 3AUM (C6_QTDVEN / SB1->B1_I_QT3UM), PARA ESSES PRODUTOS ESSE SERÁ O VALOR DAS "CAIXAS".
	  EndIf

      If !lEtiqporitem
         _cProduto:=""	  
	  EndIf

      If !lEtiqporitem .And. (_nPos:=aScan(_aItensNF, {|A| A[1] == _cChaveNF  })) <> 0
         _aItensNF[_nPos,_nPosColAte]+=_nQtdeEtiqueta
         _aItensNF[_nPos,_nPosColQE ]+=_nQtdeEtiqueta
		 If !AllTrim(SC6->C6_PEDCLI) $ _aItensNF[_nPos,_nPosColPC ]
             _aItensNF[_nPos,_nPosColPC ]+=";"+AllTrim(SC6->C6_PEDCLI)
		 EndIf 
		 (_cAlias)->(DBSkip())
		 Loop//******************************** Loop DO PALLET ************************************
	  EndIf

   ElseIf MV_PAR08 = 2
      _cProduto:=""
      If SB1->B1_I_UMPAL == '1'		
      	 _nQtdeEtiqueta:= Int( SD2->D2_QUANT / SB1->B1_I_CXPAL )
		 _nQtNoPl	   := ( _nQtdeEtiqueta * SB1->B1_I_CXPAL )
		_nQtSobra	   := SD2->D2_QUANT - _nQtNoPl
      	
      ElseIf SB1->B1_I_UMPAL == '2'		
      	 _nQtdeEtiqueta:= Int(  SD2->D2_QTSEGUM  / SB1->B1_I_CXPAL )
		 _nQtNoPl	   := ( _nQtdeEtiqueta * SB1->B1_I_CXPAL )
		 _nQtSobra	   := SD2->D2_QTSEGUM - _nQtNoPl
      	
      ElseIf SB1->B1_I_UMPAL == '3'		
         _nQtde3UM     := SD2->D2_QUANT / SB1->B1_I_QT3UM
      	 _nQtdeEtiqueta:= Int( _nQtde3UM / SB1->B1_I_CXPAL )
		 _nQtNoPl	   := ( _nQtdeEtiqueta * SB1->B1_I_CXPAL )
		 _nQtSobra	   := _nQtde3UM - _nQtNoPl
      EndIf
	  If _nQtSobra > 0
	     lTemSobra:=.T.
	  EndIf
   
      If !lPallporitem .And. (_nPos:=aScan(_aItensNF, {|A| A[1] == _cChaveNF  })) <> 0
         _aItensNF[_nPos,_nPosColPR ]:="Múltiplos SKUs"
         _aItensNF[_nPos,_nPosColAte]+=_nQtdeEtiqueta
         _aItensNF[_nPos,_nPosColQE ]+=_nQtdeEtiqueta
		 If !AllTrim(SC6->C6_PEDCLI) $ _aItensNF[_nPos,_nPosColPC ]
            _aItensNF[_nPos,_nPosColPC ]+=";"+AllTrim(SC6->C6_PEDCLI)
		 EndIf
		 (_cAlias)->(DBSkip())
		 Loop//******************************** Loop DO PALLET ************************************
      ElseIf lPallporitem 
	  	 _cProduto:= cValToChar(SB1->B1_I_CXPAL)+" cx(s) de "+AllTrim(Posicione("SB1",1,xFilial("SB1")+SD2->D2_COD,"B1_DESC"))//ex.: 90 CX(s) de BEBIDA LACTEA UHT CHOCOLATE 200 ML ITALAC
      ElseIf !lPallporitem 
	     _nQtSobra:=0
	  EndIf
    EndIf
      
    _aItem:={}
	aAdd(_aItem,_cChaveNF)//01
    aAdd(_aItem,SF2->F2_CHVNFE)                                  //02
    aAdd(_aItem,SF2->F2_CLIENTE+SF2->F2_LOJA)                    //03
    aAdd(_aItem,FWSM0Util():GetSM0FullName("01",SF2->F2_FILIAL)) //04
    aAdd(_aItem,AllTrim(SC6->C6_PEDCLI))                         //05
    aAdd(_aItem,_cProduto)                                       //06
    aAdd(_aItem,Space(20))                                       //07
    aAdd(_aItem,CTOD(""))                                        //08
    aAdd(_aItem,CTOD(""))                                        //09
    aAdd(_aItem,If(_nQtdeEtiqueta>0,1,0))                        //10
    aAdd(_aItem,_nQtdeEtiqueta)                                  //11
    aAdd(_aItem,_nQtdeEtiqueta)                                  //12
    aAdd(_aItem,_nQtSobra)                                       //13
    aAdd(_aItem,SD2->(RECNO()))                                  //14

    aAdd(_aItensNF,_aItem)

    If _nQtSobra > 0
	   _aItem:={}
       aAdd(_aItem,.F.)
       aAdd(_aItem,AllTrim(Posicione("SB1",1,xFilial("SB1")+SD2->D2_COD,"B1_DESC")))
       aAdd(_aItem,0)
       aAdd(_aItem,_nQtSobra)
       aAdd(_aItem,AllTrim(SC6->C6_PEDCLI)) 
       aAdd(_aItem,SF2->F2_CHVNFE)               
       aAdd(_aItem,SF2->F2_CLIENTE+SF2->F2_LOJA) 
       aAdd(_aItem,SD2->(RECNO())) 
   
       aAdd(_aItensSobra,_aItem)
       
	   _aItem:={}
       aAdd(_aItem,_nQtSobra)
       aAdd(_aItem,AllTrim(Posicione("SB1",1,xFilial("SB1")+SD2->D2_COD,"B1_DESC")))
	   
	   aAdd(_aBrowseT,_aItem)

    EndIf

    (_cAlias)->(DBSkip())
EndDo   

SC6->(DBSetOrder(1))
SD2->(DBSetOrder(1)) 

If lTemSobra .And. lPallporitem
   ROMS066S()
EndIf

Return .T.

/*
===============================================================================================================================
Programa----------: ROMS066S()
Autor-------------: Alex Wallauer
Data da Criacao---: 29/11/2021
===============================================================================================================================
Descrição---------: Ler os dados do listbox
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/  
Static Function ROMS066S()
Local _nQtdeP:=0
Local _bOK , P , S
Local _nlin:=05
Local _nPula:=15
Local _nCol1:=160
Local _nAlt :=120
Local _nLag :=200
lOK:=.F.

_bOK:={|| If(_nQtdeP > 0 ,.T.,(U_ITMsg("Quantidade INVALIDA",'Atenção!',"Deve ter pelo menos 1 etiqueta para prosseguir senão cancele",3),.F.) ) }

@ 00,00 To 350,410 Dialog oDlgDes Title "Dados da Etiquetas de Sobra"

@ _nlin,05 Say "Existem Produtos com sobra que podem formar outro Pallet" Pixel of oDlgDes
_nlin += _nPula
@ _nlin,05 Say "Se deseja imprmir etiquetas de pallet de sobra digite quantas:" Pixel of oDlgDes
@ (_nlin-2),_nCol1 MsGet _nQtdeP Picture "@E 9,999"  Pixel Of oDlgDes
_nlin += _nPula

@ _nlin,005 LISTBOX _oVencto FIELDS TITLE "Caixas","Descricao do Produto" SIZE _nLag,_nAlt PIXEL
_oVencto:SetArray(_aBrowseT)
_oVencto:bLine := {|| _aBrowseT[_oVencto:nAt] }
_nlin += _nAlt+5

@ _nlin,70 BMPBUTTON Type 1 ACTION (If(EVAL(_bOK),(lOK:=.T.,Close(oDlgDes)),))
@ _nlin,99 BMPBUTTON Type 2 ACTION Close(oDlgDes)

Activate Dialog oDlgDes Center

If !lOK
   Return .F.
EndIf

cTit1:="Lista dos itens para selecionar"
bDblClk:={|| ROMS066GET(@oLbxAux,.T.)}
aTitCol2:={}
aAdd(aTitCol2,"")                //01
aAdd(aTitCol2,"Produto")         //02
aAdd(aTitCol2,"Qtde Pallet")     //03
aAdd(aTitCol2,"Qtde Total")      //04
aAdd(aTitCol2,"Pedido Cliente")  //05
aAdd(aTitCol2,"Chave")           //06
aAdd(aTitCol2,"Cliente")         //07
aAdd(aTitCol2,"Registro")        //08

For  P := 1 TO  _nQtdeP
     _cDifVal:=""
     cTit2:="Selecione os itens do Etiqueta de Pallet "+cValToChar(P)+" de "+cValToChar(_nQtdeP)
    //      ITListBox(_cTitAux , _aHeader , _aCols    , _lMaxSiz ,  nTipo , _cMsgTop , _lSelUnc , _aSizes , _nCampo , bOk , bCancel, _abuttons, _aCab ,bDblClk , _aColXML , bCondMarca,_bLegenda)
    lRet:=U_ITLISTBOX(cTit1    , aTitCol2 , _aItensSobra , .F.   , 4      , cTit2    ,          ,         ,         ,     ,        ,          ,       ,bDblClk )//, _aColXML , bCondMarca,_bLegenda)
    
	If lRet
	    _aItem:={}
	    _cPedCli:=""
		_cProduto:=""
		_nContaItem:=0
	    For S := 1 TO Len(_aItensSobra)
	       If _aItensSobra[S,1]
			  _aItensSobra[S,4]:=_aItensSobra[S,4]-_aItensSobra[S,3]
			  _cPedCli+=AllTrim(_aItensSobra[S,5])+";"
              _cProduto+=CValToChar(_aItensSobra[S,3])+" CX(s) de "+_aItensSobra[S,2]+";"
		  	  SD2->(DBGoTo(_aItensSobra[S,Len(_aItensSobra[S])]))
			  _aItensSobra[S,3]:=0
			  _aItensSobra[S,1]:=.F.
			  _nContaItem++
		   EndIf
	    Next
	    _cPedCli :=LEFT( _cPedCli , Len(_cPedCli )-1 )
		_cProduto:=LEFT( _cProduto, Len(_cProduto)-1 )

	    aAdd(_aItem,"Etiqueta de sobra")                             //01
        aAdd(_aItem,SF2->F2_CHVNFE)                                  //02
        aAdd(_aItem,SF2->F2_CLIENTE+SF2->F2_LOJA)                    //03
        aAdd(_aItem,FWSM0Util():GetSM0FullName("01",SF2->F2_FILIAL)) //04
        aAdd(_aItem,_cPedCli)                                        //05
        aAdd(_aItem,_cProduto)                                       //06
        aAdd(_aItem,_cDifVal)                                        //07
        aAdd(_aItem,CTOD(""))                                        //08
        aAdd(_aItem,CTOD(""))                                        //09
        aAdd(_aItem,1)					                             //10
        aAdd(_aItem,1)                  		                     //11
        aAdd(_aItem,1)                           		             //12
        aAdd(_aItem,_nContaItem)                                     //13
        aAdd(_aItem,SD2->(RECNO()))                                  //14
    
        aAdd(_aItensNF,_aItem)
	EndIf

Next
Return .T.
/*
===============================================================================================================================
Programa----------: ROMS066B
Autor-------------: Alex Wallauer
Data da Criacao---: 29/11/2021
===============================================================================================================================
Descrição---------: Ler os dados do listbox
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/  

Static Function ROMS066B()
Local NF
Local cLocal:=GetTempPath()

cFileName:="ROM046_"
cFileName+=DToS( Date() ) + "_"
cFileName+=StrTran(TIME(), ":" , "" )
cFileName:=cFileName+".pdf"
//CB5SetImp("ZEBRA")//chama MSCBPRINTER()
       //FWMsPrinter():New(cFilePrintert,nDevice],lAdjustToLegacy], [ cPathInServer], [ lDisabeSetup ], [ lTReport], [ @oPrintSetup], [ cPrinter], [ lServer], [ lPDFAsPNG], [ lRaw], [ lViewPDF], [ nQtdCopy] )
oPrint:= FwMsPrinter():New(cFileName    , IMP_PDF, .T.            , cLocal          , .T.          )//, .T.        ,  NIL           , NIL        , NIL       , NIL         , NIL    , .F.        , NIL         )
oPrint:SetPortrait()            // Fixa a Impressao em Retrato //oPrint:SetLandScape()
oPrint:cPathPDF := cLocal	// Caso seja utilizada impressão em IMP_PDF
oPrint:Setup()
If Upper(oPrint:cPathPDF) == "C:\" .Or. Empty(oPrint:cPathPDF)
   oPrint:cPathPDF := cLocal
EndIf

If oPrint:nModalResult = 2//APERTOU O CANCELA
   Return .F.
EndIf

//CB5SetImp("ZEBRA")//chama MSCBPRINTER()

For NF:= 1 to Len(_aItensNF)

	SD2->(DBGoTo(_aItensNF[NF,Len(_aItensNF[NF])]))

     _nDe   := _aItensNF[NF,_nPosColDE]
	 If _nDe = 0
	    Loop
	 EndIf
     _nTotEtiq:= _aItensNF[NF,_nPosColQE]
     _nAte    := _aItensNF[NF,_nPosColAte]
	 _cLote   := _aItensNF[NF,_nPosColLO]
	 _dValid  := _aItensNF[NF,_nPosColDV]
	 _cPedCli := _aItensNF[NF,_nPosColPC]
	 _cChave  := _aItensNF[NF,2]
	 _aProduto:={}

     lSair:=.F.
	 If MV_PAR08 = 1
       If lEtiqporitem
          _cProduto:= SD2->D2_COD
	      _nQuant  := SD2->D2_QUANT
	      _c1Unid  := SD2->D2_UM   
	   EndIf
        Processa( {||  lSair:=ROMS066C(_nTotEtiq) }, "Aguarde...", "Gerando Etiquetas de Caixa...",.F.)
	 ElseIf MV_PAR08 = 2
	    //_lMaisde1:=.F.
        _cProduto:= _aItensNF[NF,_nPosColPR]
		If lPallporitem 
		   If  "Etiqueta de sobra" $ _aItensNF[NF,1]
	           If _aItensNF[NF,_nPosColCS] > 1		   
	              _cProduto:= "Múltiplos SKUs"
                  _aProduto:= StrToArray(_aItensNF[NF,_nPosColPR],";") //Ex.: 52 CX(s) de LEITE UHT INTEGRAL C/TAMPA 1 L EDGE ITALAC
			   EndIf
		   EndIf	   
		EndIf
        Processa( {||  lSair:=ROMS066P(_nTotEtiq) }, "Aguarde...", "Gerando Etiquetas de Pallet...",.F.)
	 EndIf
	 If lSair
	    Return .F.
	 EndIf

Next

//CB5SetImp("ZEBRA")//chama MSCBPRINTER()

LjMsgRun( "Gerando a visualização..." , "Aguarde!" , {|| oPrint:Preview() } )//Visualiza antes de imprimir

Return .T.
/*
===============================================================================================================================
Programa----------: ROMS066C
Autor-------------: Alex Wallauer
Data da Criacao---: 29/11/2021
===============================================================================================================================
Descrição---------: Impressão de multiplas etiquetas DE CAIXAS
===============================================================================================================================
Parametros--------: _nTotEtiq
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/  

Static Function ROMS066C(_nTotEtiq)

Local  ni , P
Local ncoluna  :=15
Local nTamFonte:=03
Local nlinhaIni:=35
Local nLinhAux1:=35
Local nLinhAux2:=15
Local _nEsqu1  :=010  //COLUNA INICIAL ESQUERDA
Local nLinMeio :=610  //COLUNA DO MEIO
Local _nEsqu2  :=nLinMeio+15//DADOS DA COLUNA DO MEIO
Local ntamh    :=1080 //COLUNA DA DIREITA / LARGURA DA ETIQUETA

//                       Fonte      Tamanho         Negrito
oFont10  := TFont():New("Arial", , (10+nTamFonte-1), .T., .F., 5,,, .T., .F.,,,,,, oPrint)
oFont10n := TFont():New("Arial", , (10+nTamFonte  ), .T., .T., 5,,, .T., .F.,,,,,, oPrint)
oFont12n := TFont():New("Arial", , (10+nTamFonte+1), .T., .T., 5,,, .T., .F.,,,,,, oPrint)//TITULO
oFont20  := TFont():New("Arial", , (28+nTamFonte  ), .T., .F., 5,,, .T., .F.,,,,,, oPrint)//CAIXAS

cerros := ""
ProcRegua(_nTotEtiq)
SA1->(DBSetOrder(1))
//_cTypeBar:="EAN128"//"GS1128"//CODE128

For ni := _nDe TO  _nAte
	
	nlinha := nlinhaIni
	
	IncProc("Imprimindo etiqueta CAIXAS: " + StrZero(ni,5) + " de " + StrZero(_nAte,5))

	
	oPrint:StartPage()              // Inicializa a Pagina de Impressao

	oPrint:Line(nlinha,ncoluna - 5 , nlinha , ncoluna + ntamh)//LINHA INICIAL
	
	nLinha += 010
//=======================================	
	oPrint:Say(nLinha+nLinhAux1, nColuna + _nEsqu1,"Endereço de destino:"   , oFont12n,,,,2)
//	oPrint:Say(nLinha+nLinhAux1, nColuna + _nEsqu2,"Endereço do fornecedor:", oFont12n,,,,2)
	nLinha += 050
	oPrint:Line(nlinha,ncoluna - 5,nlinha,ncoluna + ntamh)
	
	nPula:=040	
	oPrint:Say(nLinha+nLinhAux1, nColuna + _nEsqu1, "AMAZON CD: "+AllTrim(SA1->A1_COMPENT), oFont10)//200
	nLinhaSalva:=nLinha
	nLinha += nPula
    SA1->(DBSeek(xFilial("SA1")+SF2->F2_CLIENTE+SF2->F2_LOJA))
		
	oPrint:Say(nLinha+nLinhAux1, nColuna + _nEsqu1, SA1->A1_NOME , oFont10)
	nLinha += nPula

	oPrint:Say(nLinha+nLinhAux1, nColuna + _nEsqu1, "CNPJ: "+SA1->A1_CGC+"  IE: "+SA1->A1_INSCR+" CEP:"+Transform(SA1->A1_CEP,"@R 99999-999"), oFont10)
	nLinha += nPula

//	oPrint:Say(nLinha+nLinhAux1, nColuna + _nEsqu1, "IE: "+SA1->A1_INSCR+" CEP:"+Transform(SA1->A1_CEP,"@R 99999-999"), oFont10)
//	nLinha += nPula

	oPrint:Say(nLinha+nLinhAux1, nColuna + _nEsqu1, AllTrim(SA1->A1_END), oFont10)
	nLinha += nPula

	oPrint:Say(nLinha+nLinhAux1, nColuna + _nEsqu1, AllTrim(SA1->A1_BAIRRO)+"-"+AllTrim(SA1->A1_MUN)+"-"+AllTrim(SA1->A1_EST), oFont10)
	nLinha += 060

//Endereço do fornecedor 
	aEmp := FWSM0Util():GetSM0Data("01",SF2->F2_FILIAL,{"M0_ENDCOB","M0_CEPCOB","M0_CIDCOB","M0_ESTCOB","M0_BAIRCOB","M0_NOMECOM","M0_NOME"})

	cEndFil	:= AllTrim(aEmp[1,2])+" "
	cCepFil	:= "CEP: "+SubStr(AllTrim(aEmp[2,2]),1,2) + "." + SubStr(AllTrim(aEmp[2,2]),3,3) + "-" + SubStr(AllTrim(aEmp[2,2]),6,3)
	cCidFil	:= AllTrim(aEmp[3,2])+" - "
	cEstFil	:= AllTrim(aEmp[4,2])
	cBaiFil	:= AllTrim(aEmp[5,2])
	cNomeEmp:= AllTrim(aEmp[6,2])

	oPrint:Line(nlinha,ncoluna - 5,nlinha,ncoluna + ntamh)
	nLinha += 010

	oPrint:Say(nLinha+nLinhAux1, nColuna + _nEsqu1,"Endereço do fornecedor:", oFont12n,,,,2)
	nLinha += 050
	oPrint:Line(nlinha,ncoluna - 5,nlinha,ncoluna + ntamh)
	nLinha += 020    

	oPrint:Say(nlinha+nLinhAux1, nColuna + _nEsqu1, cNomeEmp       , oFont10)
	nlinha +=nPula

	oPrint:Say(nlinha+nLinhAux1, nColuna + _nEsqu1, cEndFil        , oFont10)
	nlinha +=nPula

	oPrint:Say(nlinha+nLinhAux1, nColuna + _nEsqu1, cCepFil+"  "+cBaiFil        , oFont10)
	nlinha +=nPula

	oPrint:Say(nlinha+nLinhAux1, nColuna + _nEsqu1, cCidFil+cEstFil, oFont10)
	nLinha += 050
//Endereço do fornecedor ****************************
		
	nLinhaSalva:=nLinha
	oPrint:Line(nlinha,ncoluna - 5,nlinha,ncoluna + ntamh)
	nLinha += 020
//==============================================================================================	
    aPedidos:=StrToArray(_cPedCli,";")
    If Len(aPedidos) > 1
	   oPrint:Say(nLinha+nLinhAux1, nColuna + _nEsqu1, "Pedidos de compra abaixo", oFont10n)//70
       ccodbar1:=""
    Else
	   oPrint:Say(nLinha+nLinhAux1, nColuna + _nEsqu1, "Pedido de compra", oFont10n)//70
       ccodbar1:=AllTrim(_cPedCli)
	EndIf
	oPrint:Say(nLinha+nLinhAux1, nColuna + _nEsqu2, "Número de caixas", oFont10n)//610
	nLinha += 010
	
	nLinha += 060-nLinhAux2
	nLinBar:=nLinha
	nColBar:=nColuna + _nEsqu1+10
	nLagBar:=1//0.0167
	nAltBar:=25//0.7
	If Len(AllTrim(_cPedCli)) > 15
	   nLagBar2:=150
	Else
	   nLagBar2:=NIL
	EndIf
    //_cTypeBar:="CODE128"
	
               
//  oPrint:FWMsBar(_cTypeBar,nRow   ,nCol,cCode   ,oPrint,lCheck,Color,lHorz, LARGUR,nALTERA,lBanner,cFont  ,cMode,lPrint,nPFWidth,nPFHeigth,lCmtr2Pix)
//	oPrint:FWMSBAR(_cTypeBar,nLinBar,0.4 ,ccodbar1,oPrint,.T.   ,     ,.T.  ,nLagBar,nAltBar,.F.    ,"Arial","C"  ,.F.   ,1       ,1        ,.F.)
//  oPrint:Code128(/*nRow*/,/*nCol*/,*cCode*/,nWidth*,nHeigth,.T./*lSay*/,,100)
    If !Empty(ccodbar1)
       oPrint:Code128(nLinBar ,nColBar ,ccodbar1,nLagBar,nAltBar,.F./*lSay*/,,nLagBar2)//CODIGO DE BARRA DO PEDIDO DE COMPRA
	EndIf
 	
	//oPrint:Say(nLinha+nLinhAux1, nColuna + _nEsqu1, DToC(dvalid), oFont10)//210
    
	_cCaixa := CValToChar(ni)+" / "+CValToChar(_nAte)
	nCentral:=20
	oPrint:Say(nLinha+nLinhAux1+nCentral+20, nColuna + _nEsqu2+nCentral, _cCaixa , oFont20)//"Número de caixas"

	nLinha += 100
    If !Empty(ccodbar1)
	   oPrint:Say(nLinha+nLinhAux1, nColuna + _nEsqu1, ccodbar1 , oFont10)//NUMERO DO PEDIDO DO CODIGO DE BARA ACIMA
	EndIf

	nLinha += 090
	oPrint:Line(nlinha   ,ncoluna - 5       , nlinha+1 ,ncoluna + ntamh)//FECHA A LINHA
	oPrint:Line(nLinhaSalva,ncoluna + nLinMeio, nlinha ,ncoluna + nLinMeio)//LINHA DA COLUNA DO MEIO
	nLinha += 015
	
	oPrint:Say(nLinha+nLinhAux1, nColuna + _nEsqu1, "Nota fiscal:", oFont10n)//170
	nLinha += 055
	//oPrint:Line(nlinha,ncoluna - 5,nlinha,ncoluna + ntamh)//FECHA A LINHA
	nLinha += 030
	
	ccodbar2:=AllTrim(_cChave)
	nLinBar:=19//nLinha+5//
	nLagBar:=0.0166//01//
	//nAltBar:=25//0.7
	//nLagBar2:=270
	_cTypeBar:="CODE128"
	
//  oPrint:FWMsBar(_cTypeBar,nRow   ,nCol,cCode   ,oPrint,lCheck,Color,lHorz, nWidth,nHeigth,lBanner,cFont  ,cMode,lPrint,nPFWidth,nPFHeigth,lCmtr2Pix)
  	oPrint:FWMSBAR(_cTypeBar,nLinBar,0.8 ,ccodbar2,oPrint,.T.    ,    ,.T.  ,nLagBar,0.7    ,.F.    ,"Arial","C"  ,.F.   ,1       ,1        ,.F.)
//  oPrint:Code128(/*nRow*/,/*nCol*/,*cCode*/,nWidth*,nHeigth,.T./*lSay*/,,100)
//  oPrint:Code128(nLinBar ,nColBar ,ccodbar2,nLagBar,nAltBar,.F./*lSay*/,,nLagBar2)
    
	nLinha += 080-nLinhAux2
	oPrint:Say(nLinha+nLinhAux1, nColuna + _nEsqu1+200, ccodbar2 , oFont10)//NUMERO DA NF NO CODIGO DE BARRA
	nLinha += 070

  	oPrint:Line(nlinha   ,ncoluna - 5     , nlinha , ncoluna + ntamh )//LINHA FINAL
	nLinha += 030

 If lEtiqporitem
// BLOCO EXTRA DO PRODUTO :	
	SB1->(DBSeek(xFilial("SB1") + _cProduto))
	oPrint:Say(nLinha+nLinhAux1, nColuna + _nEsqu1, "PRODUTO : "+AllTrim(SB1->B1_DESC), oFont10)//170

	nLinha += 050
	//oPrint:Line(nlinha,ncoluna - 5,nlinha,ncoluna + ntamh)//FECHA A LINHA
	//nLinha += 030

	nLinBar:=nLinha
	nColBar:=nColuna + _nEsqu1+10
	nLagBar:=1
	nAltBar:=25
	nLagBar2:=nil//250
    //_cTypeBar:="CODE128"
	
    ccodbar3:=AllTrim(SB1->B1_CODBAR)
               
//  oPrint:Code128(/*nRow*/,/*nCol*/,*cCode*/,nWidth*,nHeigth,.T./*lSay*/,,100)
    oPrint:Code128(nLinBar ,nColBar ,ccodbar3,nLagBar,nAltBar,.F./*lSay*/,,nLagBar2)//CODIGO DE BARRA DO SB1->B1_CODBAR 

	nLinha += 090
	oPrint:Say(nLinha+nLinhAux1, nColuna + _nEsqu1+150, ccodbar3 , oFont10)//CODIGO DO SB1->B1_CODBAR                

	nLinha += 085
	oPrint:Line(nlinha,ncoluna - 5,nlinha,ncoluna + ntamh)//FECHA A LINHA
	nLinha += 035

	If !Empty(_nQuant)
	   oPrint:Say(nLinha+nLinhAux1, nColuna + _nEsqu1, "Número de unidades do itens: "+AllTrim(TRANS(_nQuant,"@E 999,999,999,999.99"))+" "+_c1Unid, oFont10)
	   nLinha += nPula
    EndIf
	If !Empty(_cLote)
	   oPrint:Say(nLinha+nLinhAux1, nColuna + _nEsqu1, "Número do Lote: "+AllTrim(_cLote), oFont10)
	   nLinha += nPula
	EndIf
	If !Empty(_dValid)
	   oPrint:Say(nLinha+nLinhAux1, nColuna + _nEsqu1, "Data de Validade: "+DToC(_dValid), oFont10)
	   nLinha += 085
	EndIf
//	oPrint:Line(nlinhaIni,ncoluna - 5     , nlinha , ncoluna - 5     )//LINHA LATERAL ESQUERDA 
//	oPrint:Line(nlinhaIni,ncoluna + ntamh , nlinha , ncoluna + ntamh )//LINHA LATERAL DIRETA
  	oPrint:Line(nlinha   ,ncoluna - 5     , nlinha , ncoluna + ntamh )//LINHA FINAL
  
  ElseIf Len(aPedidos) > 1 // !lEtiqporitem

//PEDIDOS DO PALLET
    //aPedidos:=StrToArray(_cPedCli,";")
    If Len(aPedidos) > 1
	   oPrint:Say(nLinha+nLinhAux1, nColuna + _nEsqu1, "Pedidos de compra" , oFont10n)
	Else
	   oPrint:Say(nLinha+nLinhAux1, nColuna + _nEsqu1, "Pedido de compra" , oFont10n)
	EndIf
	nLinha += 010
    nLinha += 060-nLinhAux2

    For P := 1 TO Len(aPedidos)

        _lPar:=MOD(P,2)=0
        ccodbar1:=aPedidos[P]
		If _lPar
	       nColBar:=nColuna + _nEsqu2+06//LADO DIREITO 
		Else
	       nColBar:=nColuna + _nEsqu1+10//LADO ESQUERDO
		EndIf  
	    nLinBar:=nLinha
		
	    nLagBar:=1
	    nAltBar:=23
	    If Len(AllTrim(_cPedCli)) > 15
	       nLagBar2:=125
	    Else
	       nLagBar2:=NIL
	    EndIf
        If !Empty(ccodbar1)
//         oPrint:Code128(/*nRow*/,/*nCol*/,*cCode*/,nWidth*,nHeigth,.T./*lSay*/,,100)
           oPrint:Code128(nLinBar ,nColBar ,ccodbar1,nLagBar,nAltBar,.F./*lSay*/,,nLagBar2)
		   nLinBar+=120
	       oPrint:Say(nLinBar, nColBar , ccodbar1 , oFont10)
		   If Len(_aProduto) >= P
		      nLinBar+=030
	          oPrint:Say(nLinBar, nColBar , MEMOLINE(_aProduto[P],55,1) , oFontCX)
		   EndIf	   
	    EndIf
		If _lPar
	       nLinha += 170
		EndIf

	Next
	If !_lPar
	   nLinha += 170
	EndIf

  	oPrint:Line(nlinha   ,ncoluna - 5     , nlinha , ncoluna + ntamh )//LINHA FINAL

  EndIf //If lEtiqporitem

	oPrint:EndPage()                // Finaliza a Pagina de Impressao

Next
Return .F. //NAO SAIR 

/*
===============================================================================================================================
Programa----------: ROMS066P
Autor-------------: Alex Wallauer
Data da Criacao---: 29/11/2021
===============================================================================================================================
Descrição---------: Impressão de multiplas etiquetas DE PALLET
===============================================================================================================================
Parametros--------: _nTotEtiq
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/  

Static Function ROMS066P(_nTotEtiq)

Local  ni , p
Local ncoluna  :=15
Local nTamFonte:=04
Local nTamFont2:=00
Local nlinhaIni:=35
Local nLinhAux1:=35
Local nLinhAux2:=15
Local _nEsqu1  :=010  //COLUNA INICIAL ESQUERDA
Local nLinMeio :=610  //COLUNA DO MEIO
Local _nEsqu2  :=nLinMeio+17//DADOS DA COLUNA DO MEIO
Local ntamh    :=1150 //COLUNA DA DIREITA / LARGURA DA ETIQUETA

//                       Fonte      Tamanho  Negrito
//oFont8   := TFont():New("Arial",, 08, .T., .F., 5,,, .T., .F.,,,,,, oPrint)
oFontCX  := TFont():New("Arial", , (08+nTamFont2  ), .T., .F., 5,,, .T., .F.,,,,,, oPrint)
oFontEX  := TFont():New("Arial", , (10+nTamFont2  ), .T., .F., 5,,, .T., .F.,,,,,, oPrint)
oFont10  := TFont():New("Arial", , (10+nTamFonte-1), .T., .F., 5,,, .T., .F.,,,,,, oPrint)
oFont10n := TFont():New("Arial", , (10+nTamFonte  ), .T., .T., 5,,, .T., .F.,,,,,, oPrint)
oFont12n := TFont():New("Arial", , (10+nTamFonte+1), .T., .T., 5,,, .T., .F.,,,,,, oPrint)//TITULO
oFont20  := TFont():New("Arial", , (28+nTamFont2  ), .T., .F., 5,,, .T., .F.,,,,,, oPrint)//CAIXAS
cerros := ""
ProcRegua(_nTotEtiq)
SA1->(DBSetOrder(1))
//_cTypeBar:="EAN128"//"GS1128"//CODE128

For ni := _nDe TO  _nAte
	
	nlinha := nlinhaIni
	
	IncProc("Imprimindo etiqueta PALLET: " + StrZero(ni,5) + " de " + StrZero(_nAte,5))

	
	oPrint:StartPage()              // Inicializa a Pagina de Impressao

	oPrint:Line(nlinha,ncoluna - 5 , nlinha , ncoluna + ntamh)//LINHA INICIAL
	
	nLinha += 010
	
	oPrint:Say(nLinha+nLinhAux1, nColuna + _nEsqu1,"Endereço de destino:"   , oFont12n,,,,2)

    nLinha+=050
	oPrint:Line(nlinha,ncoluna - 5,nlinha,ncoluna + ntamh)
	nPula:=040	

    SA1->(DBSeek(xFilial()+SF2->F2_CLIENTE+SF2->F2_LOJA))
	oPrint:Say(nLinha+nLinhAux1, nColuna + _nEsqu1, "AMAZON CD: "+AllTrim(SA1->A1_COMPENT), oFont10)//200
	nLinhaSalva:=nLinha
	nLinha += nPula
		
	oPrint:Say(nLinha+nLinhAux1, nColuna + _nEsqu1, SA1->A1_NOME , oFont10)
	nLinha += nPula

	//oPrint:Say(nLinha+nLinhAux1, nColuna + _nEsqu1, "CNPJ: "+SA1->A1_CGC, oFont10)
	//nLinha += nPula

	oPrint:Say(nLinha+nLinhAux1, nColuna + _nEsqu1, "CNPJ: "+SA1->A1_CGC+"  IE: "+SA1->A1_INSCR+" CEP:"+Transform(SA1->A1_CEP,"@R 99999-999"), oFont10)
	nLinha += nPula

	oPrint:Say(nLinha+nLinhAux1, nColuna + _nEsqu1, AllTrim(SA1->A1_END), oFont10)
	nLinha += nPula

	oPrint:Say(nLinha+nLinhAux1, nColuna + _nEsqu1, AllTrim(SA1->A1_BAIRRO)+"-"+AllTrim(SA1->A1_MUN)+"-"+AllTrim(SA1->A1_EST), oFont10)
	nLinha += 060

//Endereço do fornecedor LADO DIREITO VOLTA NA LINHA SALVA ****************
	aEmp := FWSM0Util():GetSM0Data("01",SF2->F2_FILIAL,{"M0_ENDCOB","M0_CEPCOB","M0_CIDCOB","M0_ESTCOB","M0_BAIRCOB","M0_NOMECOM","M0_NOME"})

	cEndFil	:= AllTrim(aEmp[1,2])+" "
	cCepFil	:= "CEP: "+SubStr(AllTrim(aEmp[2,2]),1,2) + "." + SubStr(AllTrim(aEmp[2,2]),3,3) + "-" + SubStr(AllTrim(aEmp[2,2]),6,3)
	cCidFil	:= AllTrim(aEmp[3,2])+" - "
	cEstFil	:= AllTrim(aEmp[4,2])
	cBaiFil	:= AllTrim(aEmp[5,2])
	cNomeEmp:= AllTrim(aEmp[6,2])

	oPrint:Line(nlinha,ncoluna - 5,nlinha+1,ncoluna + ntamh)
	nLinha += 010

	oPrint:Say(nLinha+nLinhAux1, nColuna + _nEsqu1,"Endereço do fornecedor:", oFont12n,,,,2)

    nLinha+=050
	oPrint:Line(nlinha,ncoluna - 5,nlinha,ncoluna + ntamh)
	nPula:=040	

	oPrint:Say(nlinha+nLinhAux1, nColuna + _nEsqu1, cNomeEmp       , oFont10)
	nlinha +=nPula

	oPrint:Say(nlinha+nLinhAux1, nColuna + _nEsqu1, cEndFil        , oFont10)
	nlinha +=nPula

	oPrint:Say(nlinha+nLinhAux1, nColuna + _nEsqu1, cCepFil+"  "+cBaiFil        , oFont10)
	nlinha +=nPula

	//oPrint:Say(nlinha+nLinhAux1, nColuna + _nEsqu1, cBaiFil        , oFont10)
	//nlinha +=nPula

	oPrint:Say(nlinha+nLinhAux1, nColuna + _nEsqu1, cCidFil+cEstFil, oFont10)
	nLinha += 050
//Endereço do fornecedor ****************************
		
	nLinhaSalva:=nLinha
	oPrint:Line(nlinha,ncoluna - 5,nlinha,ncoluna + ntamh)
	nLinha += 030

// BLOCO EXTRA DO PRODUTO :	
	oPrint:Say(nLinha+nLinhAux1, nColuna + _nEsqu1, AllTrim(_cLote)   , oFontEX)
	oPrint:Say(nLinha+nLinhAux1, nColuna + _nEsqu2, "Número de pallets", oFont10n)

	nLinha += nPula
	oPrint:Say(nLinha+nLinhAux1      , nColuna + _nEsqu1, AllTrim(MEMOLINE(_cProduto,35,1)), oFontEX)
	oPrint:Say(nLinha+nLinhAux1+nPula, nColuna + _nEsqu1, AllTrim(MEMOLINE(_cProduto,35,2)), oFontEX)
// BLOCO EXTRA DO PRODUTO :	

	nLinha += 010

	_cCaixa := CValToChar(ni)+" / "+CValToChar(_nAte)
	nCentral:=14
	oPrint:Say(nLinha+nLinhAux1+nCentral+20, nColuna + _nEsqu2+nCentral, _cCaixa , oFont20)//9999 / 9999
	nLinha += 090

	oPrint:Line(nlinha   ,ncoluna - 5       , nlinha+1 ,ncoluna + ntamh)//FECHA A LINHA
	oPrint:Line(nLinhaSalva,ncoluna + nLinMeio, nlinha ,ncoluna + nLinMeio)//LINHA DA COLUNA DO MEIO
	nLinha += 015
	
	oPrint:Say(nLinha+nLinhAux1, nColuna + _nEsqu1, "Nota fiscal:", oFont10n)//170

	nLinha += 050
	oPrint:Line(nlinha,ncoluna - 5,nlinha,ncoluna + ntamh)//FECHA A LINHA
	nLinha += 030
	
	ccodbar2:=AllTrim(_cChave)
	nLinBar:=18//nLinha+5//
	nLagBar:=0.0165//01//
	nAltBar:=0.7//25//
	nLagBar2:=255
	nColBar:=0.8//nColuna + _nEsqu1-10//
	
//  oPrint:FWMsBar(_cTypeBar,nRow   ,nCol   ,cCode   ,oPrint,lCheck,Color,lHorz, nWidth,nHeigth,lBanner,cFont  ,cMode,lPrint,nPFWidth,nPFHeigth,lCmtr2Pix)
              ///*cTypeBar*/,/*nRow*/,/*nCol*,*cCode*/,oPrint,lCheck/,Color,lHorz,nWidth ,nHeigth,lBanner,cFont*/,cMode,lPrint,nPFWidth,nPFHeigth,lCmtr2Pix)
  	oPrint:FWMSBAR("CODE128",nLinBar ,nColBar,ccodbar2,oPrint,.T.    ,     ,.T.  ,nLagBar,0.7    ,.F.    ,"Arial","C"  ,.F.   ,1       ,1        ,.T.      )

	nLinha += 120-nLinhAux2
	oPrint:Say(nLinha+nLinhAux1, nColuna + _nEsqu1+200, ccodbar2 , oFont10)//NUMERO DA NF DO CODIGO DE BARRA	
	
	nLinha += 055
  	oPrint:Line(nlinha   ,ncoluna - 5     , nlinha , ncoluna + ntamh )//LINHA FINAL
	nLinha += 025

//PEDIDOS DO PALLET
    aPedidos:=StrToArray(_cPedCli,";")
    If Len(aPedidos) > 1
	   oPrint:Say(nLinha+nLinhAux1, nColuna + _nEsqu1, "Pedidos de compra" , oFont10n)
	Else
	   oPrint:Say(nLinha+nLinhAux1, nColuna + _nEsqu1, "Pedido de compra" , oFont10n)
	EndIf
	nLinha += 010
    nLinha += 060-nLinhAux2

    For P := 1 TO Len(aPedidos)

        _lPar:=MOD(P,2)=0
        ccodbar1:=aPedidos[P]
		If _lPar
	       nColBar:=nColuna + _nEsqu2+06//LADO DIREITO 
		Else
	       nColBar:=nColuna + _nEsqu1+10//LADO ESQUERDO
		EndIf  
	    nLinBar:=nLinha
		
	    nLagBar:=1
	    nAltBar:=23
	    If Len(AllTrim(_cPedCli)) > 15
	       nLagBar2:=125
	    Else
	       nLagBar2:=NIL
	    EndIf
        If !Empty(ccodbar1)
//         oPrint:Code128(/*nRow*/,/*nCol*/,*cCode*/,nWidth*,nHeigth,.T./*lSay*/,,100)
           oPrint:Code128(nLinBar ,nColBar ,ccodbar1,nLagBar,nAltBar,.F./*lSay*/,,nLagBar2)
		   nLinBar+=120
	       oPrint:Say(nLinBar, nColBar , ccodbar1 , oFont10)
		   If Len(_aProduto) >= P
		      nLinBar+=030
	          oPrint:Say(nLinBar, nColBar , MEMOLINE(_aProduto[P],55,1) , oFontCX)
		   EndIf	   
	    EndIf
		If _lPar
	       nLinha += 170
		EndIf

	Next
	If !_lPar
	   nLinha += 170
	EndIf

//	nLinha += 055
  	//oPrint:Line(nlinhaIni,ncoluna - 5     , nlinha , ncoluna - 5     )//LINHA LATERAL ESQUERDA 
  	//oPrint:Line(nlinhaIni,ncoluna + ntamh , nlinha , ncoluna + ntamh )//LINHA LATERAL DIRETA
  	oPrint:Line(nlinha   ,ncoluna - 5     , nlinha , ncoluna + ntamh )//LINHA FINAL

	oPrint:EndPage()                // Finaliza a Pagina de Impressao pallet

Next
Return .F. //NAO SAIR 

/*
===============================================================================================================================
Programa----------: ROMS066GET
Autor-------------: Alex Wallauer
Data da Criacao---: 20/07/2019
===============================================================================================================================
Descrição---------: Rotina de duplo clique na linha do browse
===============================================================================================================================
Parametros--------: oLbxAux,lTelaItens
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS066GET(oLbxAux,lTelaItens)
Local _nLinPos  := oLbxAux:nAt
Local _bOK
Local _nlin:=10
Local _nPula:=20
If lTelaItens
    If _aItensSobra[_nLinPos,3] = 0
	   _nQtde :=_aItensSobra[_nLinPos,4]
	Else
	   _nQtde :=_aItensSobra[_nLinPos,3]
	EndIf
    _nQtdeT:=_aItensSobra[_nLinPos,4]
    _bOK:={|| If(_nQtde >= 0 .And. _nQtde <=_nQtdeT ,.T.,(U_ITMsg("Quantidade INVALIDA",'Atenção!',"A quantidade não pode ser maior que a qtde total e deve ser maior igual a zero",3),.F.) ) }

Else
    _bOK:={|| If(_nQtde >= 0 .And. _nQtdeAte > 0,.T.,(U_ITMsg("Quantidades INVALIDA",'Atenção!',"Tente novamente com valor maior que zero",3),.F.) ) }
	_nQtde    :=_aItensNF[_nLinPos,_nPosColDE]
	_nQtdeAte :=_aItensNF[_nLinPos,_nPosColAte]
	_cLote    :=_aItensNF[_nLinPos,_nPosColLO]
	If _nQtdeAte = 0
	   U_ITMsg("Nao tem quantidade desse produto suficiente para montar um Pallet",'Atenção!',"Gere etiquetas por caixa",3) // ALERT
	   Return .F.
	EndIf
	If Empty(_aItensNF[_nLinPos,_nPosColDF])
	   _dDtFabr:=Date() 
	Else
	   _dDtFabr:=_aItensNF[_nLinPos,_nPosColDF]
    EndIf
	SD2->(DBGoTo(_aItensNF[_nLinPos,Len(_aItensNF[_nLinPos])]))
	If Empty(_aItensNF[_nLinPos,_nPosColDV])
	   _nDtVali:=_dDtFabr + Posicione("SBZ", 1, SD2->D2_FILIAL + SD2->D2_COD, "BZ_I_DIVLD")
	Else
	   _nDtVali:=_aItensNF[_nLinPos,_nPosColDV]
    EndIf
EndIf

lOK:=.F.	
@ 00,00 To 280,280 Dialog oDlgDes Title "Dados da Etiqueta"
    
	If lTelaItens
	   @ _nlin,10 Say "Qtde nesse Pallet:" Pixel of oDlgDes
	   @ _nlin,75 MsGet _nQtde Picture "@E 999,999"  Pixel Of oDlgDes
	Else
	   @ _nlin,10 Say "Quantidade de:" Pixel of oDlgDes
	   @ _nlin,50 MsGet _nQtde Picture "@E 999,999"  Pixel Of oDlgDes
	EndIf
	_nlin += _nPula

	If !lTelaItens
	   @ _nlin,10 Say "Quantidade Ate:" Pixel of oDlgDes
	   @ _nlin,50 MsGet _nQtdeAte Picture "@E 999,999,999"  Pixel Of oDlgDes
	   _nlin += _nPula
	EndIf
	
    If MV_PAR08 = 1

	   @ _nlin,10 Say "Lote:" Pixel of oDlgDes
	   @ _nlin,50 MsGet _cLote Picture "@!"  Pixel Of oDlgDes SIZE 50,10
	   _nlin += _nPula
   
	   @ _nlin,10 Say "Dt Fabricacao:" Pixel of oDlgDes
	   @ _nlin,50 MsGet _dDtFabr Picture "@D"  Pixel Of oDlgDes VALID {|| If(!Empty(_dDtFabr),_nDtVali:=_dDtFabr + Posicione("SBZ", 1, xFilial("SBZ") + SD2->D2_COD, "BZ_I_DIVLD"),) , .T. }
	   _nlin += _nPula
   
	   @ _nlin,10 Say "Dt Validade:" Pixel of oDlgDes
	   @ _nlin,50 MsGet _nDtVali Picture "@D"  Pixel Of oDlgDes
	   _nlin += _nPula
	
	Else

	   @ _nlin,10 Say "Diferentes Validades ?" Pixel of oDlgDes
	   @ _nlin,75 MSCOMBOBOX _cDifVal ITEMS {"1=Sim","2=Não"} SIZE 040, 010 OF oDlgDes PIXEL Valid {|| Pertence('12')} 
	   _nlin += _nPula
	
	EndIf   

	@ _nlin,50 BMPBUTTON Type 1 ACTION (If(EVAL(_bOK),(lOK:=.T.,Close(oDlgDes)),))
	@ _nlin,82 BMPBUTTON Type 2 ACTION Close(oDlgDes)

Activate Dialog oDlgDes Center

If lOK

   If lTelaItens
	  _aItensSobra[_nLinPos,1]:=(_nQtde > 0)
      _aItensSobra[_nLinPos,3]:=_nQtde
	  If _cDifVal = "1"
	     _cDifVal:="Diferentes validades" 
	  Else
	     _cDifVal:="" 
	  EndIf
   Else
      _aItensNF[_nLinPos,_nPosColDE ]:=_nQtde
      _aItensNF[_nLinPos,_nPosColAte]:=_nQtdeAte
      If MV_PAR08 = 1
	     _aItensNF[_nLinPos,_nPosColLO ]:=_cLote
	     _aItensNF[_nLinPos,_nPosColDF ]:=_dDtFabr  
	     _aItensNF[_nLinPos,_nPosColDV ]:=_nDtVali  
	  Else
	     If _cDifVal = "1"
	        _aItensNF[_nLinPos,_nPosColLO ]:="Diferentes validades" 
	     Else
	        _aItensNF[_nLinPos,_nPosColLO ]:="" 
	     EndIf
	  EndIf
/*	  If Empty(_aItensNF[_nLinPos,5 ])
	     _aItensNF[_nLinPos,5 ]:=_aItensNF[_nLinPos,_nPosColLO ]    //TESTE
	  EndIf*/
   EndIf
EndIf

oLbxAux:Refresh()
ProcessMessages()
Return .T.
/*
===============================================================================================================================
Programa----------: ROM66VAL
Autor-------------: Alex Wallauer
Data da Criacao---: 20/07/2019
===============================================================================================================================
Descrição---------: VALIDA F3 SEM DADOS
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ROM66VAL(cChamada,_aDados)
_cRetorno:=.T.

If cChamada = "D"
  If Len(_aDados) =0 
       U_ITMsg("Nao tem dados para Consultar com os filtros selecionados","Atenção","Verifique / altere o filtros selecionados",3)
      _cRetorno:=.F.
  EndIf
EndIf
Return _cRetorno
