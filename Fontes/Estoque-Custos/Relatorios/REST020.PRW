/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |17/04/2023| Chamado 43586. Inclusao da frase "ESTOQUE LIBERADO".
Lucas Borges  |09/05/2025| Chamado 50617. Corrigir chamada estática no nome das tabelas do sistema
Alex Wallauer |06/05/2025| Chamado 50525. Ajuste para remoção de diretório Local C:\SMARTCLIENT\.
===============================================================================================================================
*/

#Include "RWMAKE.CH"
#Include "TOTVS.ch"
#INCLUDE "RPTDEF.CH"
#INCLUDE "FWPrintSetup.ch"

#DEFINE ALIGN_H_LEFT   	0
#DEFINE ALIGN_H_RIGHT  	1
#DEFINE ALIGN_H_CENTER 	2
#DEFINE ALIGN_V_CENTER 	0
#DEFINE ALIGN_V_TOP	   	1
#DEFINE ALIGN_V_BOTTON 	2

/*
===============================================================================================================================
Programa----------: REST020
Autor-------------: Alex Wallauer
Data da Criacao---: 08/08/2022
Descrição---------: Emissão de etiquetas de produtos, CHAMADO 40573
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function REST020

Local nI
Local _bOK:=NIL
Private _aParAux:={}
Private _aParRet:={}
Private _aItensLote:= {}
Private _cDifVal:=""

_aItalac_F3:={}


_BSelectSB8:={|| "SELECT DISTINCT B8_LOCAL, NNR_DESCRI  FROM "+RETSQLNAME("SB8")+" SB8, "+RETSQLNAME("NNR")+" NNR WHERE"+;
                 " B8_FILIAL = '"+cFilAnt+"' AND"+;
                 " B8_LOCAL = NNR_CODIGO AND"+;
				 If(!Empty(MV_PAR02)," B8_LOTECTL IN "+FormatIn(AllTrim(MV_PAR02),";")+" AND","")+;
				 If(!Empty(MV_PAR03)," B8_PRODUTO IN "+FormatIn(AllTrim(MV_PAR03),";")+" AND","")+;
				 " SB8.D_E_L_E_T_ = ' ' AND NNR.D_E_L_E_T_ = ' ' ORDER BY B8_LOCAL " }

//Italac_F3:={}         1           2         3                          4                       5            6             7         8             9         10         11        12
//AD(_aItalac_F3,{"1CPO_CAMPO1",_cTabela,_nCpoChave               , _nCpoDesc               ,_bCondTab , _cTitAux      , _nTamChv , _aDados  , _nMaxSel , _lFilAtual,_cMVRET,_bValida})
aAdd(_aItalac_F3,{"MV_PAR01"   ,_BSelectSB8,{|Tab|(Tab)->B8_LOCAL},{|Tab| (Tab)->NNR_DESCRI},          ,"Locais"       ,          ,          ,        ,.F.        ,       , } )

_BSelectSB8:={|| "SELECT DISTINCT B8_LOTECTL, B8_DFABRIC, B8_DTVALID FROM "+RETSQLNAME("SB8")+" SB8 WHERE"+;
                 " B8_FILIAL = '"+cFilAnt+"' AND"+;
                 " SubStr(B8_LOTECTL,1,1) <> '#' AND"+;
                 " B8_SALDO > 0 AND"+;
				 If(!Empty(MV_PAR01)," B8_LOCAL   IN "+FormatIn(AllTrim(MV_PAR01),";")+" AND","")+;
				 If(!Empty(MV_PAR03)," B8_PRODUTO IN "+FormatIn(AllTrim(MV_PAR03),";")+" AND","")+;
				 " D_E_L_E_T_ = ' ' ORDER BY B8_LOTECTL " }

//Italac_F3:={}         1           2         3                                   4                                                                                        5            6             7             8             9         10         11        12
//AD(_aItalac_F3,{"1CPO_CAMPO1",_cTabela,_nCpoChave                         , _nCpoDesc                                                                              ,_bCondTab , _cTitAux, _nTamChv            , _aDados  , _nMaxSel , _lFilAtual,_cMVRET,_bValida})
aAdd(_aItalac_F3,{"MV_PAR02"   ,_BSelectSB8,{|Tab| (Tab)->B8_LOTECTL },{|Tab| "Dt Fab.: "+DToC(SToD((Tab)->B8_DFABRIC))+", Dt Val.: "+DToC(SToD((Tab)->B8_DTVALID)) },          ,"Lotes"  , Len(SB8->B8_LOTECTL),          ,           ,.F.       ,       , } )


_bSelItemSB8:={|| "SELECT DISTINCT B8_PRODUTO, B1_DESC  FROM "+RETSQLNAME("SB8")+" SB8,"+RETSQLNAME("SB1")+" SB1 WHERE"+;
                 " B8_FILIAL = '"+cFilAnt+"' AND"+;
                 " B8_PRODUTO = B1_COD AND"+;
                 " B8_PRODUTO <> '   ' AND"+;
				 If(!Empty(MV_PAR01)," B8_LOCAL   IN "+FormatIn(AllTrim(MV_PAR01),";")+" AND","")+;
				 If(!Empty(MV_PAR02)," B8_LOTECTL IN "+FormatIn(AllTrim(MV_PAR02),";")+" AND","")+;
				 " SB8.D_E_L_E_T_ = ' ' AND SB1.D_E_L_E_T_ = ' '  ORDER BY B8_PRODUTO " }

//Italac_F3:={}         1           2         3                                   4                 5            6             7             8             9         10         11        12
//AD(_aItalac_F3,{"1CPO_CAMPO1",_cTabela,_nCpoChave                         , _nCpoDesc       ,_bCondTab , _cTitAux, _nTamChv  , _aDados  , _nMaxSel , _lFilAtual,_cMVRET,_bValida})
aAdd(_aItalac_F3,{"MV_PAR03"   ,_bSelItemSB8,{|Tab|AllTrim((Tab)->B8_PRODUTO)},{|Tab|(Tab)->B1_DESC}   , ,"Produtos", 11       ,          ,        ,.F.        ,       , } )

aTitCol:={}
aAdd(aTitCol,"Local")          //01
aAdd(aTitCol,"Lote")           //02
aAdd(aTitCol,"Data Fabricacao")//03
aAdd(aTitCol,"Data Validade")  //04
aAdd(aTitCol,"Produto")        //05
aAdd(aTitCol,"Descricao")      //06
nPosDes:=Len(aTitCol)
aAdd(aTitCol,"Saldo")          //07
aAdd(aTitCol,"Qtde Etiquetas") //08
aAdd(aTitCol,"Registro")       //09


_lNovo:=U_ITMsg( "IMPRESSAO: É Referente a lote Novo ou Existente ? ",'IMPRESSAO',,2,2,3,,"NOVO","EXISTENTE")

While .T.

    If !_lNovo
    
       MV_PAR01:=Space(100)
       MV_PAR02:=Space(350)
       MV_PAR03:=Space(100)
	   _aParAux:={}
       aAdd( _aParAux , { 1 , "Local"    , MV_PAR01, "@!"  , ""  ,"F3ITLC", "" , 100 , .T. } ) 
       aAdd( _aParAux , { 1 , "Lotes"    , MV_PAR02, "@!"  , ""  ,"F3ITLC", "" , 100 , .T. } ) 
       aAdd( _aParAux , { 1 , "Produtos" , MV_PAR03, "@!"  , ""  ,"F3ITLC", "" , 100 , .T. } ) 
	   _aParRet:={}
       For nI := 1 To Len( _aParAux )
           aAdd( _aParRet , _aParAux[nI][03] )
       Next nI
    
                                                      //        aParametros,cTitle,aRet      ,bOk  ,aButtons,lCentered,nPosX,nPosY,oDlgWizard,cLoad,lCanSave,lUserSave
    	If !ParamBox( _aParAux , "GERACAO DE ETIQUETAS DE ITENS - LOTE Existente" , @_aParRet, _bOK,        ,         ,     ,     ,          ,     ,.F.     ,.F. )
    		Exit
    	EndIf
    
    Else // NOVO LOTE
    
       MV_PAR01:=Space(11)
       MV_PAR02:=Date()
       MV_PAR03:=Space(Len(SA2->A2_COD))
       MV_PAR04:=Space(Len(SA2->A2_LOJA))
       MV_PAR05:=Space(Len(SB8->B8_PRODUTO))
       
	   _aParAux:={}
       aAdd( _aParAux , { 1 , "Lote"          , MV_PAR01, "@!"  , ""  ,"   ", "" , 050 , .T. } ) 
       aAdd( _aParAux , { 1 , "Data Validade" , MV_PAR02, "@D"  , ""  ,"   ", "" , 050 , .T. } ) 
       aAdd( _aParAux , { 1 , "Fornecedor"    , MV_PAR03, "@!"  , ""  ,"SA2", "" , 050 , .T. } ) 
       aAdd( _aParAux , { 1 , "Loja"          , MV_PAR04, "@!"  , ""  ,"   ", "" , 050 , .T. } ) 
       aAdd( _aParAux , { 1 , "Produto"       , MV_PAR05, "@!"  , ""  ,"SB1", "" , 050 , .T. } ) 
    
	   _aParRet:={}
       For nI := 1 To Len( _aParAux )
           aAdd( _aParRet , _aParAux[nI][03] )
       Next nI
                                                      //        aParametros,cTitle,aRet      ,bOk  ,aButtons,lCentered,nPosX,nPosY,oDlgWizard,cLoad,lCanSave,lUserSave
    	If !ParamBox( _aParAux , "GERACAO DE ETIQUETAS DE ITENS - LOTE Novo"      , @_aParRet, _bOK,        ,         ,     ,     ,          ,     ,.F.     ,.F. )
    		Exit
    	EndIf
    
    EndIf
	
    U_ITLOGACS()

	lTemSobra:=.F.
	_aItensLote:={}
	_aBrowseT:={}

    FWMsgRun( ,{|oproc| REST020Ler(oproc,_lNovo) } ,'Aguarde!','lendo itens/Lotes...'  )

    If Len(_aItensLote) > 0
       
       aSize:=NIL
       cTit1:="Lista dos Lotes / itens para imprimir as etiquetas"
       cTit2:=cTit1
       bDblClk:={|| REST020GET(@oLbxAux)}

       _abuttons:={}
      If _lNovo
	     aAdd(_abuttons,{"",{|| REST020Ler(,.T.) },"","Incluir Etiquetas"} )
	  EndIf

       While .T.    

    //            ITListBox(_cTitAux , _aHeader , _aCols     , _lMaxSiz ,  nTipo , _cMsgTop , _lSelUnc , _aSizes , _nCampo , bOk , bCancel, _abuttons, _aCab ,bDblClk , _aColXML , bCondMarca,_bLegenda)
          lRet:=U_ITLISTBOX(cTit1    , aTitCol  , _aItensLote, .T.      , 1      , cTit2    ,          , aSize   ,         ,     ,        , _abuttons,       ,bDblClk )//, _aColXML , bCondMarca,_bLegenda)
    
          If lRet
	         lSair:=.F.
             
			 Processa( {||  lSair:=REST020B() }, "Aguarde...", "Gerando Etiquetas...",.F.)

             If !lSair
		        Loop
		     EndIf
          EndIf
	      Exit
	   EndDo
    Else
       Loop
    EndIf
   
EndDo

Return 
/*
===============================================================================================================================
Programa----------: REST020Ler
Autor-------------: Alex Wallauer
Data da Criacao---: 08/08/2022
Descrição---------: LER OS ITENS DA NF
Parametros--------: oProc
Retorno-----------: Nenhum
===============================================================================================================================*/  

Static Function REST020Ler(oProc,_lNovo)
Local _cAlias := GetNextAlias()
Local _nConta :=0
Local _cQrySB8:= " SELECT R_E_C_N_O_  RECSB8 "
SB1->(DBSetOrder(1))

If _lNovo

   If oProc = NIL
	  If !ParamBox( _aParAux , "GERACAO DE ETIQUETAS NOVAS" , @_aParRet,   ,, .T. , , , , , .T. , .T.)
	  	 Return .F.
	  EndIf
   EndIf


   SB1->(DBSeek(xFilial("SB1")+MV_PAR05))
   _aItem:={}
   aAdd(_aItem,"")      //01
   aAdd(_aItem,AllTrim(MV_PAR01)+AllTrim(MV_PAR03)+AllTrim(MV_PAR04))//02
   aAdd(_aItem,"")                   //03
   aAdd(_aItem,DToC(MV_PAR02))       //04
   aAdd(_aItem,MV_PAR05)             //05
   aAdd(_aItem,SB1->B1_DESC)         //06
   aAdd(_aItem,0)                    //07
   aAdd(_aItem,1)                    //08
   aAdd(_aItem,0)                    //09   
   aAdd(_aItensLote,_aItem)
   If oProc = NIL
      oLbxAux:Refresh()
      ProcessMessages()
   EndIf

   Return .T./////////////////////////// SAIDA QUANDO É NOVO
EndIf

_cQrySB8 += " FROM " + RetSqlName("SB8") + " SB8 "
_cQrySB8 += " WHERE SB8.D_E_L_E_T_ = ' ' "
_cQrySB8 += " AND B8_FILIAL = '"+cFilAnt+"' "
_cQrySB8 += " AND SubStr(B8_LOTECTL,1,1) <> '#' "
_cQrySB8 += " AND B8_SALDO > 0 "
If !Empty(MV_PAR01)
   _cQrySB8 += " AND B8_LOCAL IN "+FormatIn(AllTrim(MV_PAR01),";")
EndIf
If !Empty(MV_PAR02)
   _cQrySB8 += " AND B8_LOTECTL IN "+FormatIn(AllTrim(MV_PAR02),";")
EndIf
If !Empty(MV_PAR03)
   _cQrySB8 += " AND B8_PRODUTO IN "+FormatIn(AllTrim(MV_PAR03),";")
EndIf
_cQrySB8 += " ORDER BY B8_LOCAL, B8_LOTECTL, B8_PRODUTO"
_cQrySB8 := ChangeQuery(_cQrySB8)

MPSysOpenQuery(_cQrySB8,_cAlias)

DBSelectArea(_cAlias)
COUNT TO _nQtdReg
(_cAlias)->(DBGoTop())
_cTotal:=AllTrim(Str(_nQtdReg))

If Empty( _nQtdReg )
   U_ITMsg("Nao tem dados para consultar com os filtros selecionados","Atenção","Verifique / altere o filtros selecionados",3)
   Return .F.
ElseIf _nQtdReg > 500 .And. !U_ITMsg( "Serão processados "+_cTotal+" registros. Deseja Continuar?",'ATENCAO!',,3,2,2)
   Return .F.
EndIf

_aItensLote:= {}

While ! (_cAlias)->(Eof())                           
  
   SB8->(DBGoTo((_cAlias)->RECSB8))

   _nConta++
   oProc:cCaption := "Lendo Item: "+SB8->B8_PRODUTO+" - "+AllTrim(Str(_nConta))+" / "+_cTotal
   ProcessMessages()
   
   SB1->(DBSeek(xFilial("SB1")+SB8->B8_PRODUTO))
      
    _aItem:={}
	aAdd(_aItem,SB8->B8_LOCAL  )      //01
	aAdd(_aItem,SB8->B8_LOTECTL)      //02
	aAdd(_aItem,DToC(SB8->B8_DFABRIC))//03
	aAdd(_aItem,DToC(SB8->B8_DTVALID))//04
	aAdd(_aItem,SB8->B8_PRODUTO)      //05
	aAdd(_aItem,SB1->B1_DESC   )      //06
	aAdd(_aItem,SB8->B8_SALDO  )      //07
	aAdd(_aItem,1  )                  //08
	aAdd(_aItem,SB8->(RECNO()) )      //09

    aAdd(_aItensLote,_aItem)

   
    (_cAlias)->(DBSkip())
EndDo   

Return .T.

/*
===============================================================================================================================
Programa----------: REST020B
Autor-------------: Alex Wallauer
Data da Criacao---: 08/08/2022
Descrição---------: Ler os dados do listbox
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
Static Function REST020B()
Local NF
Local cLocal:=GetTempPath()

lImpDataVal:=!U_ITMsg( "IMPRESSAO: É Embalagem Tetra ? ",'IMPRESSAO',,2,2,2)

cFileName:="REST020_"
cFileName+=DToS( Date() ) + "_"
cFileName+=StrTran(TIME(), ":" , "" )
cFileName:=cFileName+".pdf"
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

For NF:= 1 to Len(_aItensLote)

    _nAte:= _aItensLote[NF,  Len(_aItensLote[NF])-1 ]
	If _nAte = 0
	   Loop
	EndIf
	If _lNovo
	   _cLote     :=_aItensLote[NF,2] 
	   _cDtVal    :=CTOD(_aItensLote[NF,4])
       _cProduto  :=_aItensLote[NF,5]
       _cDescricao:=_aItensLote[NF,6] 
    Else
	   SB8->(DBGoTo(_aItensLote[NF, Len(_aItensLote[NF]) ]))
       _cProduto  := SB8->B8_PRODUTO
       _cDescricao:= Posicione('SB1',1,xFilial("SB1")+SB8->B8_PRODUTO,"B1_DESC")//_aItensLote[NF,  nPosDes ]
	   _cLote     := SB8->B8_LOTECTL
	   _cDtVal    := SB8->B8_DTVALID//SB8->B8_LOCAL
    EndIf

    lSair:=REST020C(NF) 

	If lSair
	   Return .F.
	EndIf

Next NF

LjMsgRun( "Gerando a visualização..." , "Aguarde!" , {|| oPrint:Preview() } )//Visualiza antes de imprimir

Return .T.
/*
===============================================================================================================================
Programa----------: REST020C
Autor-------------: Alex Wallauer
Data da Criacao---: 08/08/2022
Descrição---------: Impressão de multiplas etiquetas
Parametros--------: _nTotEtiq
Retorno-----------: Nenhum
===============================================================================================================================
*/  
Static Function REST020C(_nTotEtiq)
Local  ni
Local ncoluna  :=15
Local nTamFonte:=05
Local nlinhaIni:=35
Local nLinhAux1:=10//35
Local _nEsqu1  :=010  //COLUNA INICIAL ESQUERDA
Local ntamh    :=1080 //COLUNA DA DIREITA / LARGURA DA ETIQUETA
Local nMeio    :=100//(ncoluna+ntamh)/2 //COLUNA do MEIO

//                       Fonte      Tamanho         Negrito
oFont15  := TFont():New("Arial", , (15+nTamFonte  ), .T., .F., 5,,, .T., .F.,,,,,, oPrint)
oFont10n := TFont():New("Arial", , (10+nTamFonte  ), .T., .T., 5,,, .T., .F.,,,,,, oPrint)
oFont12n := TFont():New("Arial", , (10+nTamFonte+1), .T., .T., 5,,, .T., .F.,,,,,, oPrint)
oFont20  := TFont():New("Arial", , (20+nTamFonte  ), .T., .F., 5,,, .T., .F.,,,,,, oPrint)

cerros := ""
ProcRegua(Len(_aItensLote))
SA1->(DBSetOrder(1))

For ni := 1 TO  _nAte
	
	nlinha := nlinhaIni
	
	IncProc("Imprimindo etiqueta: " + StrZero(_nTotEtiq,5) + " de " + StrZero(Len(_aItensLote),5))

	
	oPrint:StartPage()              // Inicializa a Pagina de Impressao

	oPrint:Line(nlinha+nLinhAux1,ncoluna - 5 , nlinha+nLinhAux1 , ncoluna + ntamh, 0 , "-6")//LINHA INICIAL
	nLinha += 001
//======================================= EMPRESA =========================================================

	nColTot	:= oPrint:nPageWidth / oPrint:nFactorHor //Largura da página em cm dividido pelo fator horizontal, retorna tamanho da página em pixels
	nMeio    := int(nColTot / 4)
	nColCab2 := ( nColTot / 3 ) * 2
	nLargura := 800
	nAltura  := 100

   //SayAlign ( < nRow>, < nCol>                   , < cText>                          , oFont   ,nWidth ,nHeigth,nClrText,nAlignHorz,nAlignVert)
	oPrint:SayAlign(nLinha+nLinhAux1, nMeio,"Goiasminas Indústria de Laticínios Ltda"  , oFont12n,nLargura,nAltura,       ,ALIGN_H_CENTER)
	nLinha += 050
	oPrint:Line(nlinha+nLinhAux1,ncoluna - 5,nlinha+nLinhAux1,ncoluna + ntamh, 0 , "-6")
	nLinha += 010
		
	oPrint:SayAlign(nLinha+nLinhAux1, nMeio, cFilAnt + "  -  " + AllTrim(FWFilialName(cEmpAnt,cFilAnt,1)) , oFont12n,nLargura,nAltura,        ,ALIGN_H_CENTER)
	nLinha += 050
	oPrint:Line(nlinha+nLinhAux1,ncoluna - 5,nlinha+nLinhAux1,ncoluna + ntamh, 0 , "-6")
	nLinha += 075

//======================================= PRODUTO =========================================================
    _cDescricao:=AllTrim(_cDescricao)
    nColAux:=40
    nTam:=30
	If Len(_CDESCRICAO) > nTam
	   oPrint:Say(nLinha+nLinhAux1, nColuna+nColAux,+MEMOLINE(_CDESCRICAO,nTam,1),oFont20)
	   nLinha += 075
	   oPrint:Say(nLinha+nLinhAux1, nColuna+nColAux,+MEMOLINE(_CDESCRICAO,nTam,2),oFont20)
	Else
	   oPrint:Say(nLinha+nLinhAux1, nColuna+nColAux,_CDESCRICAO,oFont20)
	EndIf
	nLinha += 025

	oPrint:Line(nlinha+nLinhAux1,ncoluna - 5,nlinha+nLinhAux1,ncoluna + ntamh, 0 , "-6")
	
	nLinha   += 030
	nLinBar  :=nLinha+nLinhAux1
	nColBar  :=nColuna + _nEsqu1+20
	nLagBar  :=1//0.0167
	nAltBar  :=50//0.7
    nLagBar2 :=270
	
    ccodbar1:=AllTrim(_cProduto)
               
    oPrint:Code128(nLinBar ,nColBar ,ccodbar1,nLagBar,nAltBar,.F./*lSay*/,,nLagBar2)//CODIGO DE BARRA DO PEDIDO DE COMPRA
	nLinha += 210

    oPrint:SayAlign(nLinha+nLinhAux1, nMeio , ccodbar1 , oFont12n,nLargura,nAltura,,ALIGN_H_CENTER)//NUMERO DO PRODUTO DO CODIGO DE BARA ACIMA

//***************************************** LOTE ****************************************************************//
	nLinha += 075
	oPrint:Line(nlinha+nLinhAux1   ,ncoluna - 5       , nlinha+nLinhAux1 ,ncoluna + ntamh, 0 , "-6")//FECHA A LINHA
	nLinha += 075
	
	oPrint:Say(nLinha+nLinhAux1, nColuna+nColAux , "LOTE: "+_cLote , oFont20)
	nLinha += 025
	
	oPrint:Line(nlinha+nLinhAux1,ncoluna - 5,nlinha+nLinhAux1,ncoluna + ntamh, 0 , "-6")
	nLinha +=030
	
	ccodbar2 := AllTrim(_cLote)
	nLinBar  := nLinha +nLinhAux1
	nLagBar  := 1//0.0166//01//
	
    oPrint:Code128(nLinBar ,nColBar    ,ccodbar2,nLagBar,nAltBar,.F./*lSay*/,,nLagBar2)//CODIGO DE BARRA
    
	nLinha += 210
	_lColAux:=48
	oPrint:SayAlign(nLinha+nLinhAux1, (nMeio-_lColAux) , ccodbar2 , oFont12n,(nLargura+200),nAltura,,ALIGN_H_CENTER)//NUMERO DO LOTE DO CODIGO DE BARRA
	nLinha += 050

//**************************************** DATA DE VALIDADE **************************************************//
	If lImpDataVal
  	   oPrint:Line(nlinha+nLinhAux1   ,ncoluna - 5       , nlinha+nLinhAux1 ,ncoluna + ntamh, 0 , "-6")//FECHA A LINHA
  	   nLinha += 075
       oPrint:Say(nLinha+nLinhAux1, nColuna+nColAux , "DATA DE VALIDADE: "+DToC(_cDtVal) , oFont20)
   	   nLinha += 025
    EndIf
	
	oPrint:Line(nlinha+nLinhAux1,ncoluna - 5,nlinha+nLinhAux1,ncoluna + ntamh, 0 , "-6")
	nLinha +=030
	
	ccodbar2 := DToS(_cDtVal)
	nLinBar  := nLinha+nLinhAux1 
	nLagBar  := 1//0.0166//01//
	nLagBar2 := 100
    oPrint:Code128(nLinBar ,nColBar+340 ,ccodbar2,nLagBar,nAltBar,.F./*lSay*/,,nLagBar2)//CODIGO DE BARRAS
    
	nLinha += 250
	_lColAux:=475
	oPrint:Say(nLinha+nLinhAux1, nColuna + _nEsqu1+_lColAux, ccodbar2 , oFont12n)//DATA DO CODIGO DE BARRA

	nLinha += 025
	
	oPrint:Line(nlinha+nLinhAux1,ncoluna - 5,nlinha+nLinhAux1,ncoluna + ntamh, 0 , "-6")
    
	nLinha += 075
    
	_lColAux:=180
	oPrint:Say(nLinha+nLinhAux1, nColuna+nColAux+_lColAux , "ESTOQUE LIBERADO" , oFont20)

	oPrint:EndPage()                // Finaliza a Pagina de Impressao

Next ni
Return .F. //NAO SAIR 

/*
===============================================================================================================================
Programa----------: REST020GET
Autor-------------: Alex Wallauer
Data da Criacao---: 08/08/2022
Descrição---------: Rotina de duplo clique na linha do browse
Parametros--------: oLbxAux
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function REST020GET(oLbxAux)
Local _nLinPos  := oLbxAux:nAt
Local _bOK
Local _nlin:=10
Local _nPula:=20
Local _nColQtde:=Len(_aItensLote[_nLinPos])-1

_nQtde :=_aItensLote[_nLinPos,_nColQtde]

_bOK:={|| If(_nQtde >= 0 ,.T.,(U_ITMsg("Quantidade INVALIDA",'Atenção!',"A quantidade deve ser maior que zero",3),.F.) ) }

lOK:=.F.	
@ 00,00 To 145,280 Dialog oDlgDes Title "Quantidade de copias de Etiqueta"
    
    @ _nlin,10 Say "Quantidade:" Pixel of oDlgDes
    @ _nlin,50 MsGet _nQtde Picture "@E 999,999"  Pixel Of oDlgDes

    _nlin += _nPula
	@ _nlin,50 BMPBUTTON Type 1 ACTION (If(EVAL(_bOK),(lOK:=.T.,Close(oDlgDes)),))
	@ _nlin,82 BMPBUTTON Type 2 ACTION Close(oDlgDes)

Activate Dialog oDlgDes Center

If lOK
   _aItensLote[_nLinPos,_nColQtde]:=_nQtde
EndIf

oLbxAux:Refresh()
ProcessMessages()

Return .T.

/*
===============================================================================================================================
Programa----------: REST020GET
Autor-------------: Alex Wallauer
Data da Criacao---: 08/08/2022
Descrição---------: ROTINA PARA CHAMAR A IMPRESSAO DIRETO DE UMA ETIQUETA
Parametros--------: nRecSB8
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function REST20Etiq(nRecSB8)//U_REST20Etiq( SB8->(RECNO()) )
Private  _aItensLote:={}

SB8->(DBGoTo(nRecSB8))

_aItem:={}
aAdd(_aItem,SB8->B8_LOCAL  )      //01
aAdd(_aItem,SB8->B8_LOTECTL)      //02
aAdd(_aItem,DToC(SB8->B8_DFABRIC))//03
aAdd(_aItem,DToC(SB8->B8_DTVALID))//04
aAdd(_aItem,SB8->B8_PRODUTO)      //05
aAdd(_aItem,""             )      //06
aAdd(_aItem,SB8->B8_SALDO  )      //07
aAdd(_aItem,1  )                  //08
aAdd(_aItem,SB8->(RECNO()) )      //09

aAdd(_aItensLote,_aItem)

MV_PAR01:=SB8->B8_LOCAL 
MV_PAR02:=SB8->B8_LOTECTL
MV_PAR03:=SB8->B8_PRODUTO

Processa( {|| REST020B() }, "Aguarde...", "Gerando Etiqueta...",.F.)

Return .T.
