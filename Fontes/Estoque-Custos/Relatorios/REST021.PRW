/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |29/11/2022| Chamado 41968. Prametro novo MV_PAR05 e aumentado o tamanho da fonte do codigo do produto.
Lucas Borges  |09/05/2025| Chamado 50617. Corrigir chamada estática no nome das tabelas do sistema
Alex Wallauer |06/05/2025| Chamado 50525. Ajuste para remoção de diretório Local C:\SMARTCLIENT\.
===============================================================================================================================
*/

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
Programa----------: REST021
Autor-------------: Alex Wallauer
Data da Criacao---: 19/09/2022
Descrição---------: Emissão de etiquetas Almoxarifado para Endereçamento de Produtos, CHAMADO 41354 
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function REST021()

Local   nI
Local _aParAux:={}
Local _aParRet:={}
Local _bOK:=NIL
Private _aItensSB1:= {}
Private _cDifVal:=""

_aItalac_F3:={}
DBSelectArea("SBZ")
DBSelectArea("SB1")

_BSelectSBZ:={|| "SELECT DISTINCT BZ_I_LOCAL , BZ_COD FROM "+RETSQLNAME("SBZ")+" SBZ WHERE"+;
                 " SBZ.BZ_FILIAL = '"+cFilAnt+"' AND"+;
				 If(!Empty(MV_PAR02)," SubStr(SBZ.BZ_COD,1,4) IN "+FormatIn(AllTrim(MV_PAR02),";")+" AND","")+;
				 If(!Empty(MV_PAR04)," BZ_COD IN "+FormatIn(AllTrim(MV_PAR04),";")+" AND","")+;
				 " SBZ.BZ_I_LOCAL <> ' '  AND "+;	
				 " SBZ.BZ_TIPO  NOT IN ('SV', 'PA', 'MP', 'MO', 'BN', 'PP', 'PI') AND "+;				 
				 " SubStr(SBZ.BZ_COD,1,4) NOT IN ('1000', '0800' ) AND "+;	
				 " SubStr(SBZ.BZ_COD,1,4) NOT BETWEEN '0001' AND '0100'  AND "+;	
				 " SubStr(SBZ.BZ_COD,1,4) NOT BETWEEN '0300' AND '0399'  AND "+;	
				 " SBZ.D_E_L_E_T_ = ' ' ORDER BY SBZ.BZ_I_LOCAL " }

//Italac_F3:={}         1           2         3                          4                       5            6             7         8             9         10         11        12
//AD(_aItalac_F3,{"1CPO_CAMPO1",_cTabela,_nCpoChave               , _nCpoDesc               ,_bCondTab , _cTitAux      , _nTamChv , _aDados  , _nMaxSel , _lFilAtual,_cMVRET,_bValida})
aAdd(_aItalac_F3,{"MV_PAR01"   ,_BSelectSBZ,{|Tab|(Tab)->BZ_I_LOCAL},{|Tab| (Tab)->BZ_COD},          ,"Enderecos"  ,Len(SBZ->BZ_I_LOCAL),          ,        ,.F.        ,       , } )

_BSelectSB1:={|| "SELECT DISTINCT B1_GRUPO FROM "+RETSQLNAME("SB1")+" SB1 WHERE"+;
				 If(!Empty(MV_PAR03)," B1_TIPO IN "+FormatIn(AllTrim(MV_PAR03),";")+" AND","")+;
				 If(!Empty(MV_PAR04)," B1_COD  IN "+FormatIn(AllTrim(MV_PAR04),";")+" AND","")+;
				 " SB1.B1_TIPO  NOT IN ('SV', 'PA', 'MP', 'MO', 'BN', 'PP', 'PI','AD','AJ','BO','GG','IM') AND "+;				 
				 " SB1.B1_GRUPO NOT IN ('1000', '0800' ) AND "+;	
				 " SB1.B1_GRUPO NOT BETWEEN '0001' AND '0100'  AND "+;	
				 " SB1.B1_GRUPO NOT BETWEEN '0300' AND '0399'  AND "+;	
				 " SB1.B1_GRUPO  <> ' '  AND "+;	
				 " D_E_L_E_T_ = ' ' ORDER BY B1_GRUPO " }

//Italac_F3:={}         1           2         3                                   4                                                                                        5            6             7             8             9         10         11        12
//AD(_aItalac_F3,{"1CPO_CAMPO1",_cTabela,_nCpoChave                         , _nCpoDesc                                                                              ,_bCondTab , _cTitAux, _nTamChv            , _aDados  , _nMaxSel , _lFilAtual,_cMVRET,_bValida})
aAdd(_aItalac_F3,{"MV_PAR02"   ,_BSelectSB1,{|Tab| (Tab)->B1_GRUPO },{|Tab| AllTrim(Posicione("SBM",1,xFilial("SBM")+(Tab)->B1_GRUPO,"BM_DESC")) },          ,"Grupos"  , Len(SB1->B1_GRUPO),          ,           ,.F.       ,       , } )


_BSelectSB1:={|| "SELECT DISTINCT B1_TIPO FROM "+RETSQLNAME("SB1")+" SB1 WHERE"+;
				 If(!Empty(MV_PAR02)," B1_GRUPO IN "+FormatIn(AllTrim(MV_PAR02),";")+" AND","")+;
				 If(!Empty(MV_PAR04)," B1_COD   IN "+FormatIn(AllTrim(MV_PAR04),";")+" AND","")+;
				 " SB1.B1_TIPO  <>  ' ' AND "+;	
				 " SB1.B1_TIPO  NOT IN ('SV', 'PA', 'MP', 'MO', 'BN', 'PP', 'PI','AD','AJ','BO','GG','IM') AND "+;				 
				 " SB1.B1_GRUPO NOT IN ('1000', '0800' ) AND "+;	
				 " SB1.B1_GRUPO NOT BETWEEN '0001' AND '0100'  AND "+;	
				 " SB1.B1_GRUPO NOT BETWEEN '0300' AND '0399'  AND "+;	
				 " D_E_L_E_T_ = ' ' ORDER BY B1_TIPO " }

//Italac_F3:={}         1           2         3                                   4                                                                                        5            6             7             8             9         10         11        12
//AD(_aItalac_F3,{"1CPO_CAMPO1",_cTabela,_nCpoChave                         , _nCpoDesc                                                                              ,_bCondTab , _cTitAux, _nTamChv            , _aDados  , _nMaxSel , _lFilAtual,_cMVRET,_bValida})
aAdd(_aItalac_F3,{"MV_PAR03"   ,_BSelectSB1,{|Tab| (Tab)->B1_TIPO },{|Tab| AllTrim(Posicione("SX5",1,xFilial("SX5")+"02"+AllTrim((Tab)->B1_TIPO),"X5_DESCRI")) },          ,"Grupos"  , Len(SB1->B1_TIPO),          ,           ,.F.       ,       , } )

_bSelSB1:={|| "SELECT DISTINCT B1_COD , B1_DESC FROM "+RETSQLNAME("SB1")+" SB1 WHERE"+;
                 " B1_FILIAL = '  ' AND"+;
				 If(!Empty(MV_PAR01)," EXISTS (SELECT 'Y' FROM " +RetSqlName("SBZ")+" BZ WHERE BZ.D_E_L_E_T_ = ' '  AND BZ.BZ_FILIAL = '"+cFilAnt+"' AND SB1.B1_COD = BZ.BZ_COD  AND BZ_I_LOCAL IN "+FormatIn(AllTrim(MV_PAR01),";")+") AND","")+;
				 If(!Empty(MV_PAR02)," B1_GRUPO   IN "+FormatIn(AllTrim(MV_PAR02),";")+" AND","")+;
				 If(!Empty(MV_PAR03)," B1_TIPO    IN "+FormatIn(AllTrim(MV_PAR03),";")+" AND","")+;
				 " SB1.B1_TIPO  NOT IN ('SV', 'PA', 'MP', 'MO', 'BN', 'PP', 'PI','AD','AJ','BO','GG','IM') AND "+;				 
				 " SB1.B1_GRUPO NOT IN ('1000', '0800' ) AND "+;	
				 " SB1.B1_GRUPO NOT BETWEEN '0001' AND '0100'  AND "+;	
				 " SB1.B1_GRUPO NOT BETWEEN '0300' AND '0399'  AND "+;	
				 " SB1.D_E_L_E_T_ = ' ' AND SB1.B1_MSBLQL = '2'  ORDER BY B1_COD " }

//Italac_F3:={}         1           2         3                             4                 5            6             7             8             9         10         11        12
//AD(_aItalac_F3,{"1CPO_CAMPO1",_cTabela,_nCpoChave                   , _nCpoDesc       ,_bCondTab , _cTitAux, _nTamChv  , _aDados  , _nMaxSel , _lFilAtual,_cMVRET,_bValida})
aAdd(_aItalac_F3,{"MV_PAR04"   ,_bSelSB1,{|Tab|AllTrim((Tab)->B1_COD)},{|Tab|(Tab)->B1_DESC}   , ,"Produtos", Len(SB1->B1_COD),          ,        ,.F.        ,       , } )

MV_PAR01:=Space(200)
MV_PAR02:=Space(200)
MV_PAR03:=Space(200)
MV_PAR04:=Space(300)
MV_PAR05:="1"

aAdd( _aParAux , { 1 , "Endereco"          , MV_PAR01, "@!"  , ""  ,"F3ITLC", "" , 100 , .F. } ) 
aAdd( _aParAux , { 1 , "Grupo de Produto"  , MV_PAR02, "@!"  , ""  ,"F3ITLC", "" , 100 , .F. } ) 
aAdd( _aParAux , { 1 , "Tipo de Produto"   , MV_PAR03, "@!"  , ""  ,"F3ITLC", "" , 100 , .F. } ) 
aAdd( _aParAux , { 1 , "Produtos"          , MV_PAR04, "@!"  , ""  ,"F3ITLC", "" , 100 , .F. } ) 
aAdd( _aParAux , { 2 , "Imprimir Descricao", MV_PAR05,{"1-Detalhada","2-Item ","3-Ambas "}, 070 ,".T.",.T.,".T."}) 
   
For nI := 1 To Len( _aParAux )
	aAdd( _aParRet , _aParAux[nI][03] )
Next 

aTitCol:={}
aAdd(aTitCol,"")                   //01
aAdd(aTitCol,"Produto")            //02
aAdd(aTitCol,"Descricao")          //03
aAdd(aTitCol,"Descricao Detalhada")//04
aAdd(aTitCol,"Localizacao")        //05
aAdd(aTitCol,"Tipo")               //06
aAdd(aTitCol,"Grupo")              //07
aAdd(aTitCol,"Registro")           //08

While .T.
	
	If !ParamBox( _aParAux , "GERACAO DE ETIQUETAS ALMOXARIFADO" , @_aParRet, _bOK  ,, .T. , , , , , .T. , .T.)
		Exit
	EndIf

    U_ITLOGACS()

	_aItensSB1:={}

    FWMsgRun( ,{|oproc| REST021Ler(oproc) } ,'Aguarde!','Lendo produtos...'  )

    If Len(_aItensSB1) > 0
       
       aSize:=NIL
       cTit1:="Lista dos produtos para imprimir as etiquetas"
       cTit2:=cTit1
       While .T.    
    //            ITListBox(_cTitAux , _aHeader , _aCols     , _lMaxSiz ,  nTipo , _cMsgTop , _lSelUnc , _aSizes , _nCampo , bOk , bCancel, _abuttons, _aCab ,bDblClk , _aColXML , bCondMarca,_bLegenda)
          lRet:=U_ITLISTBOX(cTit1    , aTitCol  , _aItensSB1, .T.      , 2      , cTit2    ,          , aSize   ,         ,     ,        ,          ,       ,        )
    
          If lRet
	         lSair:=.F.
             
			 Processa( {||  lSair:=REST021B() }, "Aguarde...", "Gerando Etiquetas...",.F.)

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
Programa----------: REST021Ler
Autor-------------: Alex Wallauer
Data da Criacao---: 19/09/2022
Descrição---------: LER OS ITENS DA NF
Parametros--------: oProc
Retorno-----------: Nenhum
===============================================================================================================================*/  

Static Function REST021Ler(oProc)
Local _cAlias := GetNextAlias()
Local _nConta :=0
Local _cQrySB1:= " SELECT R_E_C_N_O_  RECSB1 "

_cQrySB1 += " FROM " + RetSqlName("SB1") + " SB1 "
_cQrySB1 += " WHERE SB1.D_E_L_E_T_ = ' ' AND "
_cQrySB1 += " B1_TIPO  NOT IN ('SV', 'PA', 'MP', 'MO', 'BN', 'PP', 'PI','AD','AJ','BO','GG','IM') AND "
_cQrySB1 += " B1_GRUPO NOT IN ('1000', '0800' ) AND "
_cQrySB1 += " B1_GRUPO NOT BETWEEN '0001' AND '0100'  AND "	
_cQrySB1 += " B1_GRUPO NOT BETWEEN '0300' AND '0399' "
If !Empty(MV_PAR01)
   _cQrySB1 += " AND EXISTS (SELECT 'Y' FROM " +RetSqlName("SBZ")+" BZ WHERE BZ.D_E_L_E_T_ = ' '  AND BZ.BZ_FILIAL = '"+cFilAnt+"' AND SB1.B1_COD = BZ.BZ_COD AND BZ_I_LOCAL IN "+FormatIn(AllTrim(MV_PAR01),";")+" ) "
EndIf
If !Empty(MV_PAR02)
   _cQrySB1 += " AND B1_GRUPO IN "+FormatIn(AllTrim(MV_PAR02),";")
EndIf
If !Empty(MV_PAR03)
   _cQrySB1 += " AND B1_TIPO    IN "+FormatIn(AllTrim(MV_PAR03),";")
EndIf
If !Empty(MV_PAR04)
   _cQrySB1 += " AND B1_COD IN "+FormatIn(AllTrim(MV_PAR04),";")
EndIf
_cQrySB1 += " ORDER BY B1_COD"
_cQrySB1 := ChangeQuery(_cQrySB1)

MPSysOpenQuery(_cQrySB1,_cAlias)
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

SB1->(DBSetOrder(1))
_aItensSB1:= {}

While ! (_cAlias)->(Eof())                           
  
   SB1->(DBGoTo((_cAlias)->RECSB1))

   _nConta++
   oProc:cCaption := "Lendo Item: "+SB1->B1_COD+" - "+AllTrim(Str(_nConta))+" / "+_cTotal
   ProcessMessages()
   
    _aItem:={}
	aAdd(_aItem,.T.)                  //01
	aAdd(_aItem,SB1->B1_COD)          //02
	aAdd(_aItem,SB1->B1_DESC   )      //03 - ITEM
	aAdd(_aItem,SB1->B1_I_DESCD)      //04 - Detalhada
	aAdd(_aItem,Posicione("SBZ",1,xFilial("SBZ")+SB1->B1_COD,"BZ_I_LOCAL"))    //05
	aAdd(_aItem,SB1->B1_TIPO)         //06
	aAdd(_aItem,SB1->B1_GRUPO)        //07
	aAdd(_aItem,SB1->(RECNO()) )      //08

    aAdd(_aItensSB1,_aItem)

   
    (_cAlias)->(DBSkip())
EndDo   

Return .T.

/*
===============================================================================================================================
Programa----------: REST021B
Autor-------------: Alex Wallauer
Data da Criacao---: 19/09/2022
Descrição---------: Ler os dados do listbox
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  

Static Function REST021B()
Local NF
Local cLocal:=GetTempPath()

cFileName:="REST021_"
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

ProcRegua(Len(_aItensSB1))

For NF:= 1 to Len(_aItensSB1)

	IncProc("Imprimindo etiqueta: " + StrZero(NF,5) + " de " + StrZero(Len(_aItensSB1),5))
	
    If !_aItensSB1[NF,1]
	   Loop
	EndIf

	SB1->(DBGoTo(_aItensSB1[NF, Len(_aItensSB1[NF]) ]))

    _cProduto  := AllTrim(_aItensSB1[NF,2])
    _cDescricao:= AllTrim(_aItensSB1[NF,3])
	_cDetalhada:= AllTrim(_aItensSB1[NF,4])
	_cLocal    := AllTrim(_aItensSB1[NF,5])

    lSair:=REST021C() 

	If lSair
	   Return .F.
	EndIf

Next

LjMsgRun( "Gerando a visualização..." , "Aguarde!" , {|| oPrint:Preview() } )//Visualiza antes de imprimir

Return .F.
/*
===============================================================================================================================
Programa----------: REST021C
Autor-------------: Alex Wallauer
Data da Criacao---: 19/09/2022
Descrição---------: Impressão de multiplas etiquetas
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  

Static Function REST021C()
Local nColini  :=50
Local nLinhaIni:=1
Local nLinhaux1:=0
Local ntamh    :=600 //COLUNA DA DIREITA / LARGURA DA ETIQUETsA

//                       Fonte      Tamanho         Negrito
oFont05  := TFont():New("Courier new", , 08 , .T., .F., 5,,, .T., .F.,,,,,, oPrint)
oFont10n := TFont():New("Courier new", , 10 , .T., .T., 5,,, .T., .F.,,,,,, oPrint)
                                  // AJUSTAR AQUI
oFontG   := TFont():New("Courier new", , 12 , .T., .T., 5,,, .T., .F.,,,,,, oPrint)

SA1->(DBSetOrder(1))

	nLinha := nLinhaIni
	
	oPrint:StartPage()              // Inicializa a Pagina de Impressao

	nLargura := 999
	nAltura  := 100
	nLinBar  := 001
	nColBar  := nColini
	nLagBar  := 001
	nAltBar  := 025
    nLagBar2 := 150
	
//======================================= PRODUTO =========================================================
	
    ccodbar1:=AllTrim(_cProduto)
               
    oPrint:Code128(nLinBar ,nColBar ,ccodbar1,nLagBar,nAltBar,.F./*lSay*/,,nLagBar2)//CODIGO DE BARRA 
	nLinha += 099

    If MV_PAR05 = "3" // TAMANHO ANTIGO
   	   oFontAux:=oFont10n
	Else// TAMANHO COM UMA DAS DESCRICAO
   	   oFontAux:=oFontG
    EndIf
    oPrint:SayAlign(nLinha+nLinhaux1, nColini , ccodbar1 , oFontAux,nLargura,nAltura,,/*ALIGN_H_CENTER*/)//CODIGO DO PRODUTO DO CODIGO DE BARA ACIMA
    
	If MV_PAR05 = "3" // TAMANHO ANTIGO
	   nLinha += 030
	Else// TAMANHO COM UMA DAS DESCRICAO
	   nLinha += 040 // AJUSTAR AQUI
    EndIf


//***************************************** Descricao ****************************************************************//
 
 If MV_PAR05 = "1"

    If Len(_cDetalhada) > 40
	   oFontAux:=oFont05
	   nLinha +=005
	Else
	   oFontAux:=oFont10n
	EndIf
	oPrint:SayAlign(nLinha+nLinhaux1, nColini ,_cDetalhada, oFontAux,nLargura,nAltura,        ,)
	nLinha +=040

 ElseIf MV_PAR05 = "2"

    If Len(_cDescricao) > 72//dobro do 36, manter essa proporcao
	   nTamM:=60
	   oFontAux:=oFont05
	   nLinha +=005
	Else
	   nTamM:=36
	   oFontAux:=oFont10n
	EndIf
	oPrint:SayAlign(nLinha+nLinhaux1, nColini ,MEMOLINE(_cDescricao,nTamM,1), oFontAux,nLargura,nAltura,        ,)
	nLinha +=030
	oPrint:SayAlign(nLinha+nLinhaux1, nColini ,MEMOLINE(_cDescricao,nTamM,2), oFontAux,nLargura,nAltura,        ,)
	nLinha +=040

 ElseIf MV_PAR05 = "3"
    If Len(_cDetalhada) > 40
	   oFontAux:=oFont05
	   nLinha +=005
	Else
	   oFontAux:=oFont10n
	EndIf
	oPrint:SayAlign(nLinha+nLinhaux1, nColini ,_cDetalhada, oFontAux,nLargura,nAltura,        ,)
	nLinha +=030

    If Len(_cDescricao) > 72//dobro do 36, manter essa proporcao
	   nTamM:=60
	   oFontAux:=oFont05
	   nLinha +=005
	Else
	   nTamM:=36
	   oFontAux:=oFont10n
	EndIf
	oPrint:SayAlign(nLinha+nLinhaux1, nColini ,MEMOLINE(_cDescricao,nTamM,1), oFontAux,nLargura,nAltura,        ,)
	nLinha +=030
	oPrint:SayAlign(nLinha+nLinhaux1, nColini ,MEMOLINE(_cDescricao,nTamM,2), oFontAux,nLargura,nAltura,        ,)
	nLinha +=040
EndIf
//**************************************** Local *****************************************************************//
	oPrint:Line(nLinha+nLinhaux1   ,nColini - 5       , nLinha+nLinhaux1 ,nColini + ntamh, 0 , "-6")//FECHA A LINHA
	nLinha += 000
	
	oPrint:SayAlign(nLinha+nLinhaux1, nColini, "LOCALIZAÇÃO | "+_cLocal, oFont10n,nLargura,nAltura,        ,)//170
	nLinha += 050
	
	oPrint:Line(nLinha+nLinhaux1,nColini - 5,nLinha+nLinhaux1,nColini + ntamh, 0 , "-6")

	oPrint:EndPage()                // Finaliza a Pagina de Impressao

Return .F. //NAO SAIR 
