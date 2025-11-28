/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Igor Melgaco  |04/04/2024| Chamado 45466. Ajustes para compensação qdo executado na Filial 01 e titulo referente ao arcordo em outra filial.
Igor Melgaco  |04/04/2024| Chamado 45466. Ajustes para compensação qdo executado na Filial 01 e titulo referente ao arcordo em outra filial.
Igor Melgaço  |16/12/2024| Chamado 49255. Ajustes para mudança na exibição de campos dos registros a compensar.
===============================================================================================================================
*/

#Include "MFIN023.CH"
#Include "TOTVS.ch"

Static __PesqList
Static aRLocks
Static l330Auto  	:= .F.
Static lFWCodFil 	:= .T.
Static lRatFields
Static dLastPcc  	:= CTOD("22/06/2015")
Static nReg330 		:= 20
Static _oFina3301

Static __nTamPref	:= TamSX3("E1_PREFIXO")[1]
Static __nTamNum	:= TamSX3("E1_NUM")[1]
Static __nTamParc	:= TamSX3("E1_PARCELA")[1]
Static __nTamTipo	:= TamSX3("E1_TIPO")[1]
Static __nTamLoja	:= TamSX3("E1_LOJA")[1]
Static __nTamSeq	:= TamSX3("E5_SEQ")[1]
Static __nTamFil	:= TamSX3("E2_FILIAL")[1]
Static __nTamPrf	:= TamSX3("E5_PREFIXO")[1] //O campo E5_PREFIXO não está no mesmo grupo de campos do campo E1_PREFIXO, por isso mantive esse esse campo no TamSX3
Static __nTamSOri	:= TamSX3("FQ_SEQORI")[1]
Static __nTamE2Pr	:= TamSX3("E2_PREFIXO")[1] //O campo E2_PREFIXO não está no mesmo grupo de campos do campo E1_PREFIXO, por isso mantive esse esse campo no TamSX3
Static __nTamValM	:= TamSX3("FK6_VALMOV")[2]

Static __nTxMoedP 	:= 0 //Taxa de partida da compensação - Deve conter a taxa do título que partiu a compensação
Static __nTxMoedD	:= 0 //Taxa do título destino
Static __lTxConP	:= .F. // Indica se o título de partida possui taxa contratada
Static __nTxTiBrw 	:= 0
Static __nTxContr 	:= 0
Static __lCmTxCon 	:= .T.
Static __lCalcCM  	:= .T.
Static __nCasDec  	:= 2
Static __nPosTit  	:= 0
Static __lTxMoed  	:= .F.
Static __lNoTxMov 	:= .F.
Static __oMovRA   	:= Nil
Static __oMovCnb  	:= Nil
Static __aTxMoed0 	:= Nil
Static __cFk1IdOri 	:= ""
Static __nProp		:= 0
Static __cPiE1Sld   := ""
//Motor de retenções
//=====================
Static __lMotRet 	:= .F.
Static __lImpMR 	:= .F.
Static __lImpBxMR
Static __lPccMR 	:= .F.
Static __lPccBxMR 	:= .F.
Static __lRaRtPcc 	:= .F.
Static __lIrfMR 	:= .F.
Static __lIrfBxMR 	:= .F.
Static __lRaRtIrf 	:= .F.
Static __lIssMR 	:= .F.
Static __lIssBxMR 	:= .F.
Static __lRaRtIss 	:= .F.
Static __aImpos 	:= {}
Static __aOutImp 	:= {}
Static __nPisCaMR 	:= 0
Static __nCofCaMR 	:= 0
Static __nCslCaMR 	:= 0
Static __nIrfCaMR 	:= 0
Static __nIssCaMR 	:= 0
Static __nImpMR		:= 0
Static __cOldMRCf 	:= ""
Static __cOldMRCl 	:= ""
Static __nBaseMR	:= 0
Static __lImpEmis	:= .F.
Static __nImpEst	:= 0
Static __oHshTMrk
Static __aHshTMrk
Static __lTCnfgMR	:= .F.
Static __l330Va		:= .F.
Static __nPosVrTit := 0
Static __nPosRecn := 0

Static _lMOMS68 := IsInCallStack("U_MOMS068")

/*
===============================================================================================================================
Programa----------: MFIN023
Autor-------------: Igor Melgaço
Data da Criacao---: 28/08/2023
Descrição---------: Compensação de titulos a Receber. Chamado: 44750  
Parametros--------: 
Retorno-----------:  
===============================================================================================================================
*/ 
User Function MFIN023(nPosaRotina,lExecAuto)
	Local nSavRec	:= Recno()
	Local cMoedaTx  := ""
	Local nA        := 0
	Local nVlMoeda  := 0
	Local cDescMoed := "" 
	Local nI        := 0
	Local _bOK      := {||.T.  }
	Local _lContinua := .F.

	Private aRotina 	:= MenuDef()
	Private cCadastro 	:= "Compensação de Titulos a Receber"  //Compensação de Titulos a Receber
	Private cLote		:= ""		//Utilizado para Contabilizacao
	Private VALOR 		:= 0 		//Utilizada para Contabilizacao - Valor em Real
	Private VALORMF		:= 0	 	//Utilizada para Contabilizacao - Valor na moeda do título
	Private VALOR7 		:= 0 		//Utilizada para Contabilizacao
	Private VALOR8 		:= 0 		//Utilizada para Contabilizacao
	Private REGVALOR	:= 0	    //Utilizada para Contabilizacao
	Private lOracle		:= "ORACLE" $ Upper(TCGetDB())
	Private nTamTit		:= __nTamPref + __nTamNum + __nTamParc
	Private nTamTip		:= __nTamTipo
	Private nTamLoj		:= __nTamLoja
	Private aTxMoedas	:=	{}
	Private cCodDiario	:= ""

	Private _dDtCompDe  := CTOD("")
	Private _dDtCompAte := CTOD("")
	Private _nLayout    := ""

	Default nPosaRotina := 0
	Default lExecAuto	:= .F.
	Default lRatFields 	:= cPaisLoc == "BRA"

	__cPiE1Sld  := PesqPict("SE1","E1_SALDO")
	
	l330Auto := lExecAuto

	SetKey (VK_F12,{|a,b| NIL})

	__lMotRet	:= ExistFunc("FTemMotor") .And. FTemMotor()
	__l330Va	:= ExistFunc("F23VACAL") .And. TableInDic("FKD") .And. TableInDic("FKC") 
	//Estrutura aTxMoedas [1] = Nome Moeda, [2] = Taxa a Ser Utilizada, [3] = Picture, [4] = Taxa do dia atual
	aAdd(aTxMoedas, {"", 1, PesqPict("SM2","M2_MOEDA1"), 1})
	
	For nA := 2	To MoedFin()
		cMoedaTx  :=	Str(nA, IIf(nA <= 9, 1, 2))
		cDescMoed := GetMv("MV_MOEDA" + cMoedaTx) 
		
		If Empty(cDescMoed)
			Exit
		Else
			nVlMoeda := RecMoeda(dDataBase, nA)
			aAdd(aTxMoedas, {cDescMoed, nVlMoeda, PesqPict("SM2","M2_MOEDA" + cMoedaTx), nVlMoeda} )
		EndIf
	Next nA
	
	__lTxMoed := Len(aTxMoedas) > 0
	DBSelectArea('SFQ')
	DBSelectArea('SE1')
	
	If nPosaRotina > 0
		bBlock := &( "{ |a,b,c,d,e,f,g,h| " + aRotina[ nPosaRotina,2 ] + "(a,b,c,d,e,f,g,h) }" )
		Eval( bBlock, Alias(), (Alias())->(Recno()),nPosaRotina,/*oDlgPae*/,/*cLoteFat*/,/*cOrigem*/,/*aNumLay*/,l330Auto)
	Else
		_aParAux    := {}
		_aItalac_F3 := {}
		_aParRet    := {}

		MV_PAR01 := CTOD("")
		MV_PAR02 := CTOD("")
		MV_PAR03 := Space(6)
		MV_PAR04 := Space(4)
		MV_PAR05 := Space(6)
		MV_PAR06 := Space(4)
		MV_PAR07 := Space(99)
		MV_PAR08 := Space(99)
		MV_PAR09 := Space(999)
		MV_PAR10 := CTOD("")
		MV_PAR11 := CTOD("")

		_lMOMS68 := IsInCallStack("U_MOMS068")
		
		If _lMOMS68

			//_cFiltro := " SE1->E1_FILIAL = '92' "
			//_cFiltro += " .And. SE1->E1_PREFIXO = 'VRB' "
			//_cFiltro += " .And. (SE1->E1_NUM + SE1->E1_PARCELA + SE1->E1_CLIENTE + SE1->E1_LOJA) $ '" + __cNumTit + "' "		
			
			_cFiltro := " SE1->E1_HIST = 'Ref. Acordo: " + __cNumCont +"' " 
			
			_lContinua := .T.
			
		Else
			_bSelectSX5:={|| "SELECT DISTINCT X5_CHAVE, X5_DESCRI FROM "+RETSQLNAME("SX5")+" SX5 WHERE D_E_L_E_T_ = ' ' AND X5_TABELA = '05' ORDER BY X5_CHAVE "  }
			aAdd(_aItalac_F3,{"MV_PAR07",_bSelectSX5,{|Tab| (Tab)->X5_CHAVE }, {|Tab|(Tab)->X5_DESCRI } ,/*_bCondSA1*/ ,"Tipos de Título",,,,.F.        ,       , } )

			_bSelectZAB:={|| "SELECT DISTINCT ZAB_PREFIX, ZAB_DESCRI FROM "+RETSQLNAME("ZAB")+" ZAB WHERE D_E_L_E_T_ = ' ' ORDER BY ZAB_PREFIX "  }
			aAdd(_aItalac_F3,{"MV_PAR08",_bSelectZAB,{|Tab| (Tab)->ZAB_PREFIX },{|Tab| (Tab)->ZAB_DESCRI }  ,/*_bCondSA1*/ ,"Prefixos",,,,.F.        ,       , } )

			_bSelectSA1:={|| "SELECT A1_COD, A1_LOJA, A1_NREDUZ FROM SA1010 WHERE D_E_L_E_T_ = ' ' "}
			aAdd(_aItalac_F3,{"MV_PAR09",_bSelectSA1,{|Tab|(Tab)->A1_COD},{|Tab| (Tab)->A1_NREDUZ}, ,"Clientes" ,          ,          ,100        ,.F.        ,       , } )

			aAdd( _aParAux , { 1 , "Emissão de"	 		, MV_PAR01, "@D"	  , ""  , ""	     , "" , 50  , .T. } )
			aAdd( _aParAux , { 1 , "Emissão ate" 		, MV_PAR02, "@D"	  , ""  , ""	     , "" , 50  , .T. } )
			aAdd( _aParAux , { 1 , "Cliente de"  		, MV_PAR03, "@!"    , ""  , "SA1"     , "" , 06 , .F. } )
			aAdd( _aParAux , { 1 , "Loja de"     		, MV_PAR04, "@!"    , ""  , ""        , "" , 04  , .F. } )
			aAdd( _aParAux , { 1 , "Cliente até" 		, MV_PAR05, "@!"    , ""  , "SA1"     , "" , 06 , .F. } )
			aAdd( _aParAux , { 1 , "Loja até"    		, MV_PAR06, "@!"    , ""  , ""        , "" , 04  , .F. } )
			aAdd( _aParAux , { 1 , "Tipos"       		, MV_PAR07, "@!"    , ""  , "F3ITLC"  , "" , 100 , .F. } )
			aAdd( _aParAux , { 1 , "Prefixos"    		, MV_PAR08, "@!"    , ""  , "F3ITLC"  , "" , 100 , .F. } )
			aAdd( _aParAux , { 1 , "Excluir Clientes" , MV_PAR09, "@!"    , ""  , "F3ITLC"  , "" , 999 , .F. } )
			aAdd( _aParAux , { 1 , "A Compensar de"	, MV_PAR10, "@D"	  , ""  , ""	     , "" , 50  , .T. } )
			aAdd( _aParAux , { 1 , "A Compensar ate" 	, MV_PAR11, "@D"	  , ""  , ""	     , "" , 50  , .T. } )
			aAdd( _aParAux , { 3 , "Novo Layout de Comp."	, MV_PAR12, { "Sim" , "Nao"  }		, 50 , ""	, .F. } )

			For nI := 1 To Len( _aParAux )
				aAdd( _aParRet , _aParAux[nI][03] )
			Next nI
				//aParametros, cTitle                          , @aRet   ,[bOk]  , [ aButtons ] [ lCentered ] [ nPosX ] [ nPosy ] [ oDlgWizard ] [ cLoad ] [ lCanSave ] [ lUserSave ] 
			If !ParamBox( _aParAux , "Selecione os filtros" , @_aParRet,  _bOK , /*aButtons*/,/*lCentered*/,/*nPosX*/,/*nPosy*/,/*oDlgWizard*/,/*cLoad*/,.T.         ,.T.          )
				//Return .F.
				_lContinua := .F.
			Else

				_lContinua := .T.

				_dDtCompDe  := MV_PAR10
				_dDtCompAte := MV_PAR11
				_nLayout    := MV_PAR12

				_cFiltro := 'E1_SALDO > 0 '

				If !Empty(MV_PAR01)
					_cFiltro += " .And. DToS(SE1->E1_EMISSAO) >= '" + DToS(MV_PAR01) +"' "
				EndIf

				If !Empty(MV_PAR02)
					_cFiltro += " .And. DToS(SE1->E1_EMISSAO) <= '" + DToS(MV_PAR02) +"' "
				EndIf

				If !Empty(AllTrim(MV_PAR03))
					_cFiltro += " .And. SE1->E1_CLIENTE >= '" + AllTrim(MV_PAR03) + "' "
				EndIf

				If !Empty(AllTrim(MV_PAR04))
					_cFiltro += " .And. SE1->E1_LOJA >= '" + AllTrim(MV_PAR04) + "' "
				EndIf
				
				If !Empty(AllTrim(MV_PAR05))
					_cFiltro += " .And. SE1->E1_CLIENTE <= '" + AllTrim(MV_PAR05) + "' "
				EndIf

				If !Empty(AllTrim(MV_PAR06))
					_cFiltro += " .And. SE1->E1_LOJA <= '" + AllTrim(MV_PAR06) + "' "
				EndIf

				If !Empty(AllTrim(MV_PAR07))
					_cFiltro += " .And. AllTrim(SE1->E1_TIPO) $ '"+AllTrim(MV_PAR07)+"' "
				EndIf

				If !Empty(AllTrim(MV_PAR08))
					_cFiltro += " .And. AllTrim(SE1->E1_PREFIXO) $ '"+AllTrim(MV_PAR08)+"' "
				EndIf

				If !Empty(AllTrim(MV_PAR09))
					_cFiltro += " .And. !(AllTrim(SE1->E1_CLIENTE) $ '"+AllTrim(MV_PAR09)+"') "
				EndIf
				
			EndIf
		EndIf

		If _lContinua

			LoteCont( "FIN" )
			SetKey (VK_F12,{|a,b| AcessaPerg("FIN330",.T.)})

			Pergunte("FIN330",.F.)

			//MV_PAR01 : Considera Loja  Sim/Nao          	 
			//MV_PAR02 : Considera Cliente     Original/Outros 
			//MV_PAR03 : Do Cliente                            
			//MV_PAR04 : Ate Cliente                           
			//MV_PAR05 : Compensa Titulos Transferidos S/[N]   
			//MV_PAR06 : Calcula Comissao sobre valores de NCC 
			//MV_PAR07 : Mostra Lancto Contabil                
			//MV_PAR08 : Considera abatimentos para compensar  
			//MV_PAR09 : Contabiliza On-Line                   
			//MV_PAR10 : Considera Filiais abaixo              
			//MV_PAR11 : Filial De                             
			//MV_PAR12 : Filial Ate                            
			//MV_PAR13 : Calcula Comissao sobre valores de RA  
			//MV_PAR14 : Reutiliza taxas informadas

			DBSetOrder(1)
			DBSeek(xFilial("SE1"))
			
			_oBrowse := FWMBrowse():New()
			_oBrowse:SetAlias("SE1")
			_oBrowse:SetMenuDef( 'MFIN024' )
			_oBrowse:SetDescription("Compensação de Título")
			_oBrowse:AddLegend( "E1_SALDO =  E1_VALOR", "GREEN" ,"Titulo nao Compensado")
			_oBrowse:AddLegend( "E1_SALDO =  0"       , "RED"   ,"Titulo Compensado Totalmente")
			_oBrowse:AddLegend( "E1_SALDO <> 0"       , "BLUE"  ,"Titulo Compensado Parcialmente")
			_oBrowse:SetFilterDefault( _cFiltro )
			_oBrowse:Activate()
		EndIf

	EndIf

	//Restaura o ambiente
	SetKey (VK_F12)
	DBSelectArea("SE1")
	DBSetOrder(1)
	DBGoTo( nSavRec )
	
	//Limpa as variáveis estáticas utilizadas para o motor de retenções
	LimpaVarMR()
	SetKey (VK_F12,{|a,b| NIL})
Return(.T.)


/*
===============================================================================================================================
Programa----------: MFIN023
Autor-------------: Igor Melgaço
Data da Criacao---: 28/08/2023
Descrição---------: Marcação dos titulos para compensação.  
Parametros--------: 
Retorno-----------:  
===============================================================================================================================
*/ 
User Function fA23Comp(cAlias,cCampo,nOpcE,oDlgPae,cLoteFat,cOrigem,aNumLay, lAutomato,lFast)
Local lPanelFin	:= IsPanelFin()
Local nX
Local nI
Local cDadosTitulo
Local cPadrao		:= "596"
Local lPadrao
Local lDigita
Local dEmissao		:= SE1->E1_EMISSAO
Local lMarcado		:= .F.
Local nTotAbtIni	:= 0		//Abatimento do titulo de Partida
Local nTitIni		:= SE1->(Recno())
Local oOk			:= LoadBitmap( GetResources(), "LBOK" )
Local oNo			:= LoadBitmap( GetResources(), "LBNO" )
Local cVarQ			:= "  "
Local oTitulo
Local oDlg
Local lFa330Cmp		:= ExistBlock( "FA330CMP" )
Local oGet01
//Local nLinha		:= 0
Local nTit			:= 0
Local nA				:= 0
Local nAcresc		:= 0
Local nDecres		:= 0
Local nValVa		:= 0
Local nIndexAtu	:= SE1->(IndexOrd())
Local nVlrCompe 	// Criada para exibir o conteudo do Help correto quando o usuario pressionar F1 sobre o campo
Local aSize			:= {}
Local oPanel
Local oChkBox
Local aArea			:={}
Local lVldDtFin	:= .T.

//Controla o Pis Cofins e Csll na baixa  (1-Retem PCC na Baixa ou 2-Retem PCC na Emissão(default) )
Local lPccBxCr		:= FPccBxCr()
//Controla IRPJ na baixa
Local lIrPjBxCr	:= FIrPjBxCr()
Local nTotIrAbt	:= 0
Local nLoop			:= 0
Local nSalvRec		:= SE1->(Recno())
Local lAplVlMin 	:= .T.
Local nVlMinImp 	:= GetNewPar("MV_VL10925",5000)
Local nTotCsAbt		:= 0
Local nTotPisAbt	:= 0
Local nTotCofAbt	:= 0
Local aImpPcc		:= {0,0,0}

//Retencao do ISS pela emissao (1) ou baixa (2)
Local nTotIssAbt	:= 0
Local lCalcIssBx 	:= !Empty( SE5->( FieldPos( "E5_VRETISS" ) ) ) .And. !Empty( SE1->( FieldPos( "E1_SEQBX"   ) ) ) .And. ;
						!Empty( SE1->( FieldPos( "E1_TRETISS" ) ) ) .And. GetNewPar("MV_MRETISS","1") == "2"

Local nTotAdto		:= 0
Local lBaixaAbat	:= .F.
Local nVlrBaixa	:= 0
Local lBxCec		:= .F.
Local lBxLiq		:= .F.
Local nTamSeq		:= __nTamSeq
Local lF330BOTON 	:= ExistBlock("F330BOTON")
Local lF330ATLIS	:= ExistBlock("F330ATLIS")
Local lOkTitAb		:= .F.
Local nPropPcc		:= 0

Local nPos			:= 0
Local lPropRA 		:= SuperGetMv("MV_COMPCR",,.F.) //Verifica se vai proporcionalizar quando RA para NF.

Local lTipBxCP  	:= .F.
Local lSigaLoja 	:= .F.

//Controle de abatimento
Local nRecOri		:= SE1->(Recno())

//Impostos gerados pela rotina de Borderô de Recebimento de Imposto (FINA061).
Local nPisFina061	:= 0
Local nCofFina061	:= 0
Local nCslFina061	:= 0
Local nIrfFina061	:= 0  
Local nRegSE5		:= 0
Local nPropImp		:= 0
Local nProp			:= 0
Local lPropBx  		:= SuperGetMv("MV_PROPBX",.F.,"2") == "1"
Local nValTit		:= 0
Local nOldVal		:= 0
Local nTotComp  	:= 0 // variavel para controle do total compensado	
Local nPosVa		:= 0
/* GESTAO - inicio */
Local oBtFilial	:= Nil
Local lSE1Comp 	:= If(Empty(FWxFilial("SE1")), .T., .F.)
/* GESTAO - fim */
Local aPcc			:= Array(4)
Local nValIrf		:= 0
Local lBq10925		:= SuperGetMV("MV_BQ10925",,"2") == "1"
Local nVTit			:= 0
Local nBasePcc 		:= 0
Local lMata460		:= .F.
Local lRet			:= .T.
Local lJuros		:= .T.
Local lIntPFS       := SuperGetMV("MV_JURXFIN",,.F.) // Habilita a integracao entre os módulos SIGAFIN - Financeiro e SIGAPFS - Juridico

Local lRaRtImpMR 	:= .F.
Local lRetMinAux 	:= .F.
Local lIrfBxAux 	:= lIrPjBxCr
Local lPccBxAux 	:= lPccBxCr
Local lIssBxAux	 	:= lCalcIssBx
Local aAuxTitMR 	:= {}
Local dDtEmis		:= CTOD("  /  /  ")
Local lFinTp01		:= FindFunction("FINTP01")
Local lSelAuto		:= .F. 
Local lCheck		:= .T. // Check para pre-seleção dos títulos
Local nPosMarca		:= 8
Local nOdlgLen	 	as Numeric
Local nFrameLen 	as Numeric
Local nFilialPos 	as Numeric
Local nOkPos	 	as Numeric
Local nCancelPos 	as Numeric
Local nMoedaHght 	as Numeric
Local nN			as Numeric
Local oModelVA		as Object

Local	cNfOrig     := ""
Local cNfOriginal := ""
Local cHist       := ""
Local nHi         := 0
Local cAliasSD1   := ""
Local cTitulo     := ""
Local nSaldoTit   := ""
Local cTpTit      := ""
Local cFomulP     := ""
Local cFormular   := ""
Local lAglutina    := .F.
Local lContabiliza := .F.
Local aTxMoeda     := {}
Local nTaxaCM      := 0
Local nSaldoComp   := 0
Local lRA          := .F.

Default cOrigem 	:= ""
DEFAULT aNumLay 	:= {}
Default lAutomato := .F.
Default lFast     := .T.

Private nPosPis	:= 14		//Posicao Pis na Tela
Private nPosCof	:= 15		//Posicao Cofins na Tela
Private nPosCsl	:= 16		//Posicao Csll na Tela
Private nPosIrf	:= 17		//Posicao IRRF na Tela
Private cTipoOr	:= SE1->E1_TIPO
Private nPosBPCC 	:= 24
Private nPosBPCR 	:= 25
Private nPosBIRF 	:= 26
Private aTitulos	:= {}
Private aRecNo 	:= {}
Private aRegSE1 	:= {}
Private aBaixaSE5 := {}
PRIVATE	cFILFIN023 := SE1->E1_FILIAL
PRIVATE	cPrefixo := SE1->E1_PREFIXO
PRIVATE	cNum		:= SE1->E1_NUM
PRIVATE	cTipoTit := SE1->E1_TIPO
PRIVATE	cCliente := SE1->E1_CLIENTE
PRIVATE	cLoja 	:= SE1->E1_LOJA
PRIVATE	cSaldo	:= CriaVar("E1_SALDO")
PRIVATE	nValor	:= CriaVar("E1_SALDO")
PRIVATE	cParcela := SE1->E1_PARCELA
PRIVATE	nMoeda	:= SE1->E1_MOEDA
PRIVATE	dBaixa	:= dDataBase
PRIVATE	nTxMoeda	:= SE1->E1_TXMOEDA
PRIVATE	nValTot		:= 0
PRIVATE	nSeqBx 		:= 0
PRIVATE	nPosSaldo	:= 0
PRIVATE	nPosValor	:= 0
PRIVATE	cBanco		:= Criavar("E1_PORTADO")
Private lCredito 	:= .F.
Private nPosATit 	:= 0
Private aFlagCTB 	:= {}
Private lUsaFlag 	:= SuperGetMV( "MV_CTBFLAG" , .T. /*lHelp*/, .F. /*cPadrao*/)
Private aImpIR		:= {}     //array que armazena o IR na baixa
//PCC Baixa CR
Private nPis 		:= 0
Private nCofins   := 0
Private nCsll		:= 0
Private nIss		:= 0
Private nInss		:= 0
Private aDadosRef := {0,0,0,0,0,0,0} //Array(7)
Private aDadosRet := {0,0,0,0,0,0,0} //Array(7)
Private nVlRetPis	:= 0
Private nVlRetCof	:= 0
Private nVlRetCsl	:= 0
Private nDiferImp	:= 0
Private nValRec		:= 0
Private nOldValRec	:= 0
Private lRetParc  	:= .T.
Private nIrrf 	  		:= 0
Private ntotIrbx  	:= 0
Private nIndVld   	:= 0
Private nRecVld   	:= 0
Private nValCorCM 	:= 0
Private nTotImpbx  	:= 0 //Total de impostos calculados na baixa, quando posiciona !lCredito
Private aDadosRA1 	:= {{},{},{},{},{},{},{},{},{},{},{},{}}
Private lRaRtImp  	:= FRaRtImp()       //Define se ha retencao de impostos PCC/IRPJ no R.A
Private nValAbat		:= 0
Private lNcc			:= SE1->E1_TIPO $ MV_CRNEG
Private lF330SE5    	:= Existblock("F330SE5")
Private aRecSe5     	:= {}
Private nValPis		:= 0
Private nValCofins	:= 0
Private nValCsll	:= 0
Private nAbatRa	:= 0
Private nSldNF		:= 0
Private nAbatNf	:= 0
Private nValorNf	:= 0
Private lF330DESC	:= ExistBlock("F330DESC")
Private lDESC		:= .F.
Private nDesFin 	:= 0
Private nDescP		:= 0
Private nDescD		:= 0
Private nValorRa	:= 0
Private nSldRa		:= 0
Private nParciais	:= 0
Private nPisBaseR := 0
Private nCofBaseR	:= 0
Private nCslBaseR := 0
Private nPisBaseC := 0
Private nCofBaseC := 0
Private nCslBaseC := 0
Private nIrfBase	:= 0
Private aSelFil	:= {}
Private lVldSEQ	:= .F.
Private lFilterMark	:= .F.	//Filter mark For function FINA330Filt
Private cTitFilt	as Character
Private cPayType  	as Character
Private cSortField	as Character
Private cSortType	as Character
Private nSel		as Numeric
Private nRadio		as Numeric
Private cNumCont	as Character

nA			    := 0
nTotIrAbt		:= 0
nLoop			:= 0
nSalvRec		:= SE1->(Recno())
lAplVlMin 	    := .T.
lOkTitAb		:= .F.
lPropRA 		:= SuperGetMv("MV_COMPCR",,.F.) //Verifica se vai proporcionalizar quando RA para NF.
nRecOri		:= SE1->(Recno())
nValTit		:= 0
nTotComp  	:= 0 
nPosMarca		:= 8
nTamSeq		:= __nTamSeq	

nRecno := SE1->(Recno())
lRA := IIf(SE1->E1_TIPO $ "RA |NCC",.T.,.F.)

If Empty(__cPiE1Sld) 
	__cPiE1Sld := PesqPict("SE1","E1_SALDO")
EndIf 

If SE1->E1_MOEDA <> 1 .And. dDataBase < CTOD("29/11/2018")
	Help(" ",1, "FA330MOED",, STR0111 + AllTrim(Str(SE1->E1_MOEDA,2)) +"," + STR0112 +CRLF+CRLF+STR0113 ,1,0)
	Return
EndIf

If cOrigem == "LOJA800"
   nValor   :=  nVlrComp
EndIf

nVlrCompe	:= nValor

If dDataBase > dLastPcc
	nVlMinImp	:= 0
EndIf
aPcc[1]	:= .F.

If SE1->E1_TIPO $ MVRECANT+"/"+MV_CRNEG .Or. cOrigem =="MATA465"
	lCredito := .T.
EndIf

If !FA330Lock(,SE1->(Recno()))
	Return
EndIf

aArea := FWGetArea()

aPcc[1]	:= .F.

//Se vier do mata465 ou da LOCXNF, forca os valores dos parametros
If cOrigem == "MATA465"
	MV_PAR07 := MV_PAR03		// Mostra Lancto Contabil
	MV_PAR09 := MV_PAR05		// Contabiliza On-Line
	MV_PAR01 := 1 				// Considera Loja  Sim/Nao
	MV_PAR02 := 1 				// Considera Cliente Original/Outros
	MV_PAR03 :=	SE1->E1_CLIENTE // Do Cliente
	MV_PAR04 :=	SE1->E1_CLIENTE // Ate Cliente
	MV_PAR05 := 2				// Compensa Titulos Transferidos S/[N]
	MV_PAR06 := 2				// Calcula Comissao sobre valores de NCC
	MV_PAR08 := 2				//Considera abatimentos para compensar
	MV_PAR10 := 2				//Considera Filiais abaixo
	MV_PAR11 := Space( __nTamFil )	    //Filial De
	MV_PAR12 := Replicate("Z",__nTamFil)  //Filial Ate
	MV_PAR13 := 1				// Calcula Comissao sobre valores de RA
	MV_PAR14 := 2				// Reutiliza taxas informadas
    // obs.: nao eh necessario voltar aos valores originais no final, pois a
    // propria MATA465 recompoe os valores dos MV_PARxx depois da chamada U_fa23comp()
ElseIf cOrigem == "COMPENSANCC"
	Pergunte("FIN330",.F.)
	MV_PAR03 := SE1->E1_CLIENTE  		// Do Cliente
	MV_PAR04 := SE1->E1_CLIENTE 		// Ate Cliente

	DBSelectArea("SE1")
EndIf

If Type("MV_PAR02")<>'N'
	MV_PAR02 := 1 				// Considera Cliente Original/Outros
EndIf

//Caso considere diferentes clientes
If MV_PAR02 == 2
	nPosPis		:= 17
	nPosCof		:= 18
	nPosCsl		:= 19
	nPosIrf		:= 20
	nPosBPCC	:= 27
	nPosBPCR	:= 28
	nPosBIRF	:= 29
	nPosVa		:= If(__lMotRet,31,30)
Else
	nPosVa		:= If(__lMotRet,28,27)
EndIf

FWRestArea(aArea)

If ExistBlock("F330DTFIN")
	lVldDtFin := ExecBlock("F330DTFIN",.F.,.F.)
EndIf
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Verifica se data do movimento n„o ‚ menor que data limite de ³
//³ movimentacao no financeiro    										  ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If lVldDtFin .And. !DtMovFin(,,"2")
	Return
EndIf
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ N„o permite que t¡tulos j  baixados possam ser acessados. ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If SE1->E1_SALDO <= 0
	Help(" ",1,"FA330JABAI")
	Return (.T.)
EndIf
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Caso titulos originados pelo SIGALOJA estejam nas carteiras :  ³
//³I = Carteira Caixa Loja                                        ³
//³J = Carteira Caixa Geral                                       ³
//³Nao permitir esta operacao, pois ele precisa ser transferido   ³
//³antes pelas rotinas do SIGALOJA.                               ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If Upper(AllTrim(SE1->E1_SITUACA)) $ "I|J" .And. Upper(AllTrim(SE1->E1_ORIGEM)) $ "LOJA010|LOJA701|FATA701"
	Help(" ",1,"NOUSACLJ")
	Return
EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Titulos provisorios nao sao compensaveis como titulo principal.        ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If cTipoTit $ MVPROVIS
	Help(" ",1,"NOCMPPROV",,STR0042+chr(13)+STR0043,1,0 )   //"Nao é permitida a compensacao a partir de"###"um titulo provisorio"
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Recupera a Integridade dos dados     ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	DBSelectArea("SE1")
	DBSetOrder(nIndexAtu)
	DeleteObject(oOk)
	DeleteObject(oNo)
	FA330aUnlock()
	Return (.T.)
EndIf

//ANGOLA|BRASIL - Nao permitir compensar titulos de adiantamento relacionados a pedido
If cPaisLoc $ "ANG|BRA"
	If FinAdtSld( "R", SE1->( E1_CLIENTE + E1_LOJA + E1_PREFIXO + E1_NUM + E1_PARCELA + E1_TIPO ) )
		Help(" ",1,"ADTXPED",,STR0062,1,0)		//"Adiantamento relacionado a um pedido somente poderá ser utilizado no relacionamento com pedidos"
		Return (.T.)
	EndIf
EndIf

//PCREQ-3782 - Bloqueio por situação de cobrança
If !(F023VerBlq("1","0007",SE1->E1_SITUACA,.T.))
	Return (.T.)
EndIf

// SIGAPFS - Valida se o RA que foi gerado a partir de um adiantamento do SIGAPFS pode ser compensado.
// Caso tenha sido gerado a partir de um adiantamento exclusivo não poderá ser compensado.
If lIntPFS .And. AllTrim(SE1->E1_ORIGEM) == 'JURA069'
	If FindFunction("JVldCompAd") .And. !JVldCompAd()
		Return (.T.)
	EndIf
EndIf

If Type("MV_PAR15") == 'N' .And. MV_PAR15 == 2
	lJuros := .F.
EndIf

//Motor de retenções
If __lMotRet
	//Verifica as configurações de impostos pelo motor de retenção
	__lTCnfgMR	:= F330VldImp()		
	
	lRaRtImpMR 	:= ( __lPccMR .And. __lRaRtPcc ) .Or. ( __lIrfMR .And. __lRaRtIrf ) .Or. ( __lIssMR .And. __lRaRtIss )
	lPccBxCr 	:= ( __lPccMR .And. __lPccBxMR ) .Or. ( !__lPccMR .And. lPccBxAux )
	lIrPjBxCr 	:= ( __lIrfMR .And. __lIrfBxMR ) .Or. ( !__lIrfMR .And. lIrfBxAux )
	lCalcIssBx 	:= ( __lIssMR .And. __lIssBxMR ) .Or. ( !__lIssMR .And. lIssBxAux )
	
	//Calcula os impostos pelo motor de retenções
	If __lTCnfgMR
		F330CalImp( SE1->E1_NATUREZ, SE1->E1_CLIENTE, SE1->E1_LOJA, SE1->E1_FILORIG, SE1->E1_SALDO, dDataBase, SE1->E1_TIPO )
		__lTCnfgMR	:= .F.
	EndIf
EndIf

//Inicializa a gravacao dos lancamentos do SIGAPCO
PcoIniLan("000016")

//Inicializa as variáveis estáticas
F330Static()

While .T.

	If lFinTp01 .And. FINTP01(.T.)	// Restringe o uso do programa Financeiro Quando a origem do titulo For de origem Totvs Incorporação RM
		Exit
	EndIf

	nOpca  :=0
	
	If SE1->E1_MOEDA != 1 .And. __nTxMoedP == 0
		__nTxMoedP := RecMoeda(If(SE1->E1_TIPO $ MVRECANT, U_F23MovRA(Nil, "SE1", .T.)[2], dDatabase), SE1->E1_MOEDA)
	EndIf

	__lNoTxMov := Empty(__nTxMoedP)
	If SE1->E1_MOEDA > 1
		aTxMoedas[SE1->E1_MOEDA,2] := __nTxMoedP
	EndIf
	
	// DESCONTO FINANCEIRO do Título a ser compensado (NF/DP)
	If !lCredito .And. lF330DESC
		lDESC:= ExecBlock("F330DESC",.F.,.F.)
		If lDESC
			nDesFin:= IIf(SE1->E1_DESCFIN > 0 .And. SE1->E1_VENCREA-dBaixa >= SE1->E1_DIADESC .And. SE1->E1_DESCONT == 0,SE1->E1_VALOR * (SE1->E1_DESCFIN/100),0)
			nDescP := nDesFin
		EndIf
	EndIf

	//VA: Calcula o valor acessório
	If __l330Va .And. !lCredito
		oModelVA	:= FWLoadModel("FINA070VA")
		nValVa		:= FA330VACAL(oModelVA)
		oModelVa:Destroy()
		oModelVa 	:= NIL
	EndIf

	If MV_PAR08 == 1 .Or. lRaRtImp .Or. lRaRtImpMR
		nTotAbtIni 	:= SumAbatRec( cPrefixo, cNum, cParcela, SE1->E1_MOEDA, "S", dBaixa,,, @nTotCsAbt, @nTotPisAbt, @nTotCofAbt,,,, @nTotIssAbt )
		
		If !lCredito
			If __lIrfMR
				If __lIrfBxMR .And. !__lRaRtIrf 
					nIrrf := __nIrfCaMR
				EndIf
			Else
				If lIrPjBxCr .And. !lRaRtImp
					nIrrf := FCaIrBxCR( nValRec )
				EndIf
			EndIf
	
			If !lCalcIssBx
				If lPropBx
					If SE1->(E1_SALDO != E1_VALOR)  // Sofreu baixa parcial 
						nTotIssAbt := (SE1->E1_SALDO/SE1->E1_VALOR) * nTotIssAbt
					Else
						nTotIssAbt := 0
					EndIf
				EndIf
			EndIf
		EndIf
				
		nSaldo := SE1->E1_SALDO + SE1->E1_SDACRES - SE1->E1_SDDECRE - nDesFin + nValVa
		If ( !lRaRtImp .And. !lRaRtImpMR ) .Or. ( !lNcc .And. MV_PAR08 == 1 )
			nSaldo := nSaldo - nTotAbtIni
		EndIf
		If lPropBx
			nSaldo := nSaldo + nTotIssAbt
		EndIf
		
	Else
		nSaldo := SE1->E1_SALDO + SE1->E1_SDACRES - SE1->E1_SDDECRE - nDesFin + nValVa
	EndIf

	//Verifica se o titulo já possui impostos gerados pela rotina de Borderô de Recebimento de Imposto (FINA061).
	nPisFina061	:= 0
	nCofFina061	:= 0
	nCslFina061	:= 0
	nIrfFina061	:= 0
	VALOR7 		:= 0
	VALOR8 		:= 0
	nRegSE5	:=	SE5->(Recno())
		
	If lPccBxCr .And. lIrPjBxCr
		DBSelectArea("SE5")
		SE5->( DBSetOrder( 2 ) ) //FILIAL + TIPODOC + PREFIXO + NUMERO + PARCELA + TIPO
		If SE5->( DBSeek( xFilial("SE5") + "BA" + SE1->E1_PREFIXO + SE1->E1_NUM + SE1->E1_PARCELA + SE1->E1_TIPO ) )
			While !SE5->( Eof() ) .And. SE5->E5_FILIAL == xFilial("SE5") ;
			.And. SE5->E5_TIPODOC + SE5->E5_PREFIXO + SE5->E5_NUMERO + SE5->E5_PARCELA + SE5->E5_TIPO == "BA" + SE1->E1_PREFIXO + SE1->E1_NUM + SE1->E1_PARCELA + SE1->E1_TIPO
			
				If ( "FINA061" $ Subst( SE5->E5_HISTOR, 1, 7 ) ) .And. SE5->E5_MOTBX $ "PCC_IRF"						
					If AllTrim(SE5->E5_MOTBX) == "PCC"
					   nPisFina061	+= SE5->E5_VRETPIS
					   nCofFina061	+= SE5->E5_VRETCOF
					   nCslFina061	+= SE5->E5_VRETCSL
					ElseIf AllTrim(SE5->E5_MOTBX) == "IRF"
					   nIrfFina061	+= SE5->E5_VRETIRF
					EndIf
				EndIf					
				SE5->( DBSkip() )
		   EndDo
		EndIf
	EndIf
	SE5->( DBGoTo( nRegSE5 ) )

	If ( nPisFina061 + nCofFina061 + nCslFina061 + nIrfFina061 ) > 0 .And. MV_PAR08 == 2
   		nSaldo	+= nPisFina061 + nCofFina061 + nCslFina061 + nIrfFina061
	EndIf
	
	If !lCredito
		nAcresc := SE1->E1_SDACRES
		nDecres := SE1->E1_SDDECRE
		VALOR7  += nDecres
		VALOR8  += nAcresc
	EndIf



	cDadostitulo := SE1->E1_PREFIXO + SE1->E1_NUM + SE1->E1_PARCELA + SE1->E1_TIPO
	
	If (lPccBxCR .Or. lIRPJBxCr) .And. ( lRaRtImp .Or. lRaRtImpMR ) .And. !lNcc
		If lCredito
			aAdd(aDadosRA1[1],SE1->(recno()))
		Else
			aAdd(aDadosRA1[2],SE1->(recno()))
		EndIf
	EndIf
   	
   If __lMotRet
		aAdd(aDadosRA1, {__nImpMR})
	EndIf
	//PCC Baixa CR
	//Se PCC Baixa CR e nao houver abatimento de impostos
	If cPaisLoc == "BRA" .And. (lPccBxCr .Or. lIrPjBxCr) .And. ( nTotCsAbt + nTotPisAbt + nTotCofAbt == 0 )
		If (SE1->E1_VALOR > SE1->E1_SALDO) .And. Empty(SE1->E1_TIPOLIQ)
			//Procura pelas baixas deste titulo
			lTipBxCP := lRaRtImp .Or. lRaRtImpMR
			aBaixa := Sel070Baixa( "VL /V2 /BA /RA /CP /LJ /" + MV_CRNEG, SE1->E1_PREFIXO, SE1->E1_NUM, SE1->E1_PARCELA, SE1->E1_TIPO, ;
				                   @nTotAdto, @lBaixaAbat, SE1->E1_CLIENTE, SE1->E1_LOJA, @nVlrBaixa,, @lBxCec, @lBxLiq, @lSigaLoja, @lTipBxCP )

			For nX := 1 To Len(aBaixaSE5)
				nParciais += aBaixaSE5[nX][8]				
				If lPccBxCR .And. ( lRaRtImp .Or. lRaRtImpMR ) //somar impostos PCC
					nParciais += aBaixaSE5[nX][18] + aBaixaSE5[nX][19] + aBaixaSE5[nX][20] + aBaixaSE5[nX][30] + aBaixaSE5[nX][32] + aBaixaSE5[nX][33]
				EndIf
				nIss += aBaixaSE5[nX][32]
				nInss += aBaixaSE5[nX][33]
			Next
			nParciais += nTotAdto
		Else
			nParciais := SE1->E1_VALOR - SE1->E1_SALDO
		EndIf

		If MVRECANT $ SE1->E1_TIPO
			nParciais := SE1->E1_VALOR - SE1->E1_SALDO
		EndIf
		
		If ( !lRartImp .And. !lRaRtImpMR .And. MV_PAR08 == 1 .And. SE1->E1_TIPO == MVNOTAFIS .And. !lBq10925 ) .Or. ( lPropBx .And. ( ( ( !lRartImp .And. !lRaRtImpMR ) .And. MV_PAR08 == 2) .Or. ( lRartImp .Or. lRaRtImpMR ) ) .And. !lCredito)
			nParciais := SE1->E1_VALOR - SE1->E1_SALDO
		EndIf
		
		If SE1->E1_SDDECRE <> SE1->E1_DECRESC
			nParciais += ( SE1->E1_DECRESC - SE1->E1_SDDECRE )
		EndIf
		
		nValRec := SE1->E1_VALOR - nParciais
		nOldVal	:= nValrec
		
		If __lPccMR
			nPis 	:= __nPisCaMR
			nCofins := __nCofCaMR
			nCsll	:= __nCslCaMR
		Else
			If dDataBase <= dLastPcc				
				//chama a f070TotMes para preencher o array aDadosRet
				f070TotMes(dBaixa,.T.)
			Else
				If SE1->E1_TIPO <> MVRECANT 
					If "MATA" $ SE1->E1_ORIGEM
				 		nBasePcc 	:= FBaseRPCC(nValRec)
				 		nBasePcc 	:= IIf(ValType(nBasePcc) != "N", nValRec, nBasePcc)
				 		lMata460	:= .T.
				 	EndIf
					aPcc		:= newMinPcc(dBaixa,IIf(lMata460, nBasePcc, nValRec),SE1->E1_NATUREZ,"R",SE1->E1_CLIENTE+SE1->E1_LOJA)
					nPis		:= aPcc[2]
					nCofins		:= aPcc[3]
					nCsll		:= aPcc[4]
					nPisCalc	:= nPis
					nPisBaseC	:= SE1->E1_SALDO	
					nPisBaseR 	:= SE1->E1_SALDO
					nCofCalc	:= nCofins	
					nCofBaseC	:= SE1->E1_SALDO
					nCofBaseR 	:= SE1->E1_SALDO
					nCslCalc	:= nCsll	
					nCslBaseC	:= SE1->E1_SALDO
					nCslBaseR 	:= SE1->E1_SALDO
				EndIf
				aPcc[1]		:= .T.
			EndIf			
		EndIf
		
		If lRartImp .Or. lRaRtImpMR
			//Se lRartImp, retoma o valor de nValRec, alterado pela TotMes
			nValRec := SE1->E1_VALOR - nParciais
		ElseIf !__lPccMR .And. aDadosRet[1] < nVlMinImp .And. ( aDadosRet[1] + nSaldo > nVlMinImp ) .And. lPccBxCr
			nValRec := nSaldo
		EndIf
		
		If !__lPccMR			
			If lRartImp .And. lPccBxCr .And. SE1->E1_TIPO <> MVRECANT
				nPropPCC	:= SE1->E1_SALDO/SE1->E1_BASEPIS
				If dDataBase <= dLastPcc
					nPis		:= SE1->E1_PIS * nPropPCC
					nCofins		:= SE1->E1_COFINS * nPropPCC
					nCsll		:= SE1->E1_CSLL * nPropPCC
				EndIf
				If MV_PAR08==1
		 			nIss		:= SE1->E1_ISS - nIss
					nInss		:= SE1->E1_INSS - nInss
				Else
					nIss		:= SE1->E1_ISS * nPropPCC
					nInss		:= SE1->E1_INSS * nPropPCC
				EndIf
			EndIf
		EndIf
		
		If !lCredito
			If __lIrfMR
				nIrrf := __nIrfCaMR
			Else
				nIrrf := FCaIrBxCR( nValRec + IIf( lRaRtImp .And. SE1->E1_TIPO $ MVRECANT, nPis + nCofins + nCsll + nIrrf, 0 ),, lRaRtImp )
			EndIf
		EndIf
				
		If ( nPosIr := aScan( aImpIR, {|x| x[2] = SE1->(REcno())} ) ) = 0
			aAdd(aImpIR,{nIrrf,SE1->(Recno())})
			nPosIr := Len( aImpIR )
		Else
			aImpIR[nPosIr][1] := nIrrf
		EndIf
		
		If !__lIrfMR .And. ( lIrPjBxCr .And. lCredito )
			nIrrf := nIrrf * (nValRec / SE1->E1_BASEIRF)
		EndIf
		
		If !__lPccMR .And. !aPcc[1]
			If aDadosRet[1] <= nVlMinImp .And. ( aDadosRet[1] + nSaldo > nVlMinImp ) .And. !lRaRtImp .And. lPccBxCr .And. SE1->E1_TIPO <> MVRECANT
				nValPis		:= SE1->E1_PIS
				nValCofins 	:= SE1->E1_COFINS
				nValCsll	:= SE1->E1_CSLL
				nValorNf	:= SE1->E1_VALOR
			ElseIf aDadosRet[1] <= nVlMinImp .And. ( aDadosRet[1] + nSaldo <= nVlMinImp ) .And. !lRaRtImp .And. lPccBxCr .And. SE1->E1_TIPO <> MVRECANT
				nProp	:= (aDadosRet[1] + SE1->E1_SALDO) / SE1->E1_VALOR
				nValPis	:= SE1->E1_PIS * nProp
				nValCofins := SE1->E1_COFINS * nProp
				nValCsll	:= SE1->E1_CSLL * nProp
				nValorNf	:= SE1->E1_VALOR
			ElseIf aDadosRet[1] > nVlMinImp .And. ( aDadosRet[1] + nSaldo > nVlMinImp ) .And. !lRaRtImp .And. lPccBxCr .And. SE1->E1_TIPO <> MVRECANT
				nValPis	:= SE1->E1_PIS
				nValCofins := SE1->E1_COFINS
				nValCsll	:= SE1->E1_CSLL
				nValorNf	:= SE1->E1_VALOR
				nSldNF		:= SE1->E1_SALDO
			EndIf
		EndIf
		
		If SE1->E1_TIPO == MVRECANT
			nValorRa	:= SE1->E1_VALOR
			nSldRa		:= SE1->E1_SALDO
		EndIf
				
		//Caso o titulo de partida possua PCC, diminuo do saldo a compensar
		If nPis + nCofins + nCsll + nIrrf > 0  .And. SE1->E1_TIPO <> MV_CRNEG .And. SE1->E1_TIPO <> MVRECANT
			aImpPcc [1] := nPis
			aImpPcc [2] := nCofins
			aImpPcc [3] := nCsll
						
			//Somente abate o imposto se teve retenção minima
			lRetMinAux := ( ( __nPisCaMR + __nCofCaMR + __nCslCaMR + __nIrfCaMR > 0 ) .Or. ( aDadosRet[1] + nSaldo > nVlMinImp ) )
			If MV_PAR08 == 1 .And. lRetMinAux
				If lRaRtImp .Or. lRaRtImpMR
					nSaldo -= ( nPis + nCofins + nCsll + nIrrf )
				Else
					If lPccBxCr
						nSaldo -= nPis + nCofins + nCsll
					EndIf
					If lIrPjBxCr
						nSaldo -= nIrrf
					EndIf
				EndIf
			ElseIf MV_PAR08 == 2 .And. ( ( lRaRtImp .And. ( !__lPccMR .And. aPcc[1] ) ) .Or. ( lRaRtImpMR .And. __lPccMR ) )
				nSaldo -= ( nPis + nCofins + nCsll + nIrrf )
			EndIf
						
			If !__lIrfMR .And. nIrrf > 0
			 	If ( nPosIr := aScan( aImpIR, {|x| x[2] = SE1->(Recno())} ) ) = 0
					aAdd( aImpIR, {nIrrf,SE1->(Recno())} )
					nPosIr := Len( aImpIR )
				Else
					aImpIR[nPosIr][1] := nIrrf
				EndIf
			EndIf
			
		EndIf	
	ElseIf lIrPjBxCr .And. ( !lRaRtImp .And. !lRaRtImpMR )
		nSaldo -= nIrrf
	EndIf

	If nPis + nCofins + nCsll + nIrrf > 0 .And. SE1->E1_TIPO <> MV_CRNEG .And. SE1->E1_TIPO <> MVRECANT
		lRetMinAux := ( ( lRaRtImpMR .And. __nPisCaMR + __nCofCaMR + __nCslCaMR + __nIrfCaMR > 0 ) .Or. ( lRaRtImp .And. aDadosRet[1] > nVlMinImp ) )
		If ( !lRartImp .And. !lRaRtImpMR ) .Or. lRetMinAux .And. MV_PAR08 == 2
			nValRec -= ( nPis + nCofins + nCsll + nIrrf + nIss + nInss )  
		    nTotImpbx += ( nPis + nCofins + nCsll + nIrrf + nIss + nInss )
		EndIf
	EndIf

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Se For chamada da mata465 , nao mostrar a janela de parametros   ³
	//³ e Forçar o valor de nOpca con valor 1. (Loc. Arg.).              ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If cOrigem != "MATA465"
		If lPanelFin  //Chamado pelo Painel Financeiro
			oPanelDados := FinWindow:GetVisPanel()
			oPanelDados:FreeChildren()
			aDim := DLGinPANEL(oPanelDados)
			DEFINE MSDIALOG oDlg OF oPanelDados:oWnd FROM 0,0 To 0,0 PIXEL STYLE nOR( WS_VISIBLE, WS_POPUP )
			oDlg:Move(aDim[1],aDim[2],aDim[4]-aDim[2], aDim[3]-aDim[1])
			nEspLarg := ((DlgWidthPanel(oPanelDados)/2) - 225) /2
			nEspLin  := 0

		Else
			nEspLarg := 0
			nEspLin  := 0

				nOdlgLen	:= 525
				nFrameLen 	:= 245
			
			
			If !lAutomato .And. !lFast
				DEFINE MSDIALOG oDlg FROM	88,	31 TO 275,nOdlgLen TITLE STR0036 PIXEL //"Compensaçäo de Adiantamentos"
			EndIf
	   EndIf
	   
	   If !lAutomato .And. !lFast
		   oDlg:lMaximized := .F.
		   oPanel := TPanel():New(0,0,'',oDlg,, .T., .T.,, ,20,20)
		   oPanel:Align := CONTROL_ALIGN_ALLCLIENT
	
		   @ 000+nEspLin, 002+nEspLarg TO 030+nEspLin, 245+nEspLarg OF oPanel	PIXEL
		   @ 031+nEspLin, 002+nEspLarg TO 062+nEspLin, 245+nEspLarg OF oPanel	PIXEL
	
		   @ 015+nEspLin, 006+nEspLarg MSGET cPrefixo                SIZE 19, 10 OF oPanel PIXEL
		   @ 015+nEspLin, 032+nEspLarg MSGET cNum VALID !Empty(cNum) SIZE 70, 10 OF oPanel PIXEL
		   @ 015+nEspLin, 105+nEspLarg MSGET cParcela                SIZE 20, 10 OF oPanel PIXEL
	
		   If !lCredito
		   		@ 015+nEspLin, 129+nEspLarg MSGET cTipoTit PICTURE "@!" VALID !Empty(cTipoTit) .AND.;
		   		  !cTipoTit $ MVABATIM .And. ;
		   		  !(cTipoTit $ MVRECANT+"/"+MV_CRNEG) SIZE 12, 10 OF oPanel PIXEL
		   Else
		   		@ 015+nEspLin, 129+nEspLarg MSGET cTipoTit PICTURE "@!" VALID !Empty(cTipoTit) .AND.;
		   		  !cTipoTit $ MVABATIM .And. ;
		   		  (cTipoTit $ MVRECANT+"/"+MV_CRNEG) SIZE 12, 10 OF oPanel PIXEL
		   EndIf
			
		   	@ 015+nEspLin, 155+nEspLarg MSGET cCliente F3 "SA1" Valid fa330Cli()	SIZE 70, 10 OF oPanel PIXEL HASBUTTON
		   	@ 015+nEspLin, 226+nEspLarg MSGET cLoja	 Valid Fa330Loja() SIZE 16, 10 OF oPanel PIXEL
	
		   	@ 047+nEspLin, 006+nEspLarg MSGET nSaldo When .F. 	Picture "@E 9999,999,999.99" SIZE 50, 10 OF oPanel PIXEL
		   	@ 047+nEspLin, 060+nEspLarg MSGET nMoeda when .F.	SIZE 18, 10 OF oPanel PIXEL
		   	@ 047+nEspLin, 085+nEspLarg MSGET nVlrCompe			Picture "@E 9999,999,999.99";
				Valid nVlrCompe >= 0 .And. Str(nVlrCompe,17,2) <= Str(nSaldo,17,2) ;
				SIZE 52, 10 OF oPanel PIXEL HASBUTTON
			@ 047+nEspLin, 142+nEspLarg MSGET dBaixa Valid dBaixa >= SE1->E1_EMISSAO  .And. (If( lVldDtFin, DtMovFin(dBaixa,,"2"), .T.)) ;
				SIZE 48, 10 OF oPanel PIXEL HASBUTTON
			@ 047+nEspLin, 194+nEspLarg CHECKBOX oChkBox VAR lCheck PROMPT STR0117 ; // "Tit. Marcados"
				SIZE 60,15 OF oPanel PIXEL

			@ 007+nEspLin, 006+nEspLarg Say STR0006  SIZE 21, 7 OF oPanel PIXEL  //"Prefixo"
		   	@ 007+nEspLin, 032+nEspLarg Say STR0007  SIZE 22, 7 OF oPanel PIXEL  //"N£mero"
		   	@ 006+nEspLin, 105+nEspLarg Say STR0008  SIZE 23, 7 OF oPanel PIXEL  //"Parcela"
		   	@ 006+nEspLin, 129+nEspLarg Say STR0009  SIZE 14, 7 OF oPanel PIXEL  //"Tipo"
		   	@ 006+nEspLin, 155+nEspLarg Say STR0010  SIZE 34, 7 OF oPanel PIXEL  //"Cliente   "
		   	@ 006+nEspLin, 226+nEspLarg Say STR0011  SIZE 14, 7 OF oPanel PIXEL  //"Loja"
		   	@ 038+nEspLin, 006+nEspLarg Say STR0012  SIZE 34, 7 OF oPanel PIXEL  //"Saldo"
		   	@ 038+nEspLin, 060+nEspLarg Say STR0013  SIZE 21, 7 OF oPanel PIXEL  //"Moeda"
		   	@ 038+nEspLin, 085+nEspLarg Say STR0014  SIZE 55, 7 OF oPanel PIXEL  //"Valor a compensar"
		   	@ 038+nEspLin, 142+nEspLarg Say STR0015  SIZE 45, 7 OF oPanel PIXEL  //"Data da Baixa"
	   
			If UsaSeqCor()
		   		SX3->(DBSetOrder(2))
				SX3->(DBSeek("E5_DIACTB"))
				cCodDiario  := Criavar("E5_DIACTB",.T.)
				cTitDiar :=  AllTrim(X3TITULO())
				@ 038+nEspLin, 195+nEspLarg Say cTitDiar SIZE 45, 7 OF oPanel PIXEL
				@ 047+nEspLin, 195+nEspLarg MSGET cCodDiario F3 "CVL" SIZE 20, 10 OF oPanel Valid VldCodSeq( cCodDiario ) When CtbWdia() PIXEL HASBUTTON
				SX3->(DBSetOrder(1))
			EndIf
		EndIf
		
		If lPanelFin  //Chamado pelo Painel Financeiro
			aButtonTxt := {}
			aAdd(aButtonTxt,{STR0037,STR0037, {||U_Fa330SetMo()}})

			ACTIVATE MSDIALOG oDlg ON INIT FaMyBar(oDlg,;
			{|| If(Fa330TudOk(nVlrCompe),(nOpca:=1,oDLg:End()),)},;
			{|| oDlg:End()},,aButtonTxt)

		Else

				nFilialPos		:= 162
				nOkPos			:= 190
				nCancelPos		:= 218
				nMoedaHght		:= 18
			
			If !lAutomato
				If !lFast 
					@ 068+nEspLin, 005+nEspLarg BUTTON STR0037 SIZE 50,nMoedaHght ACTION (U_Fa330SetMo()) OF oPanel PIXEL //Taxas Moedas
	
					/* GESTAO - inicio */
					//Se o SE1 For Compartilhado entre todas as Empresas não exibe o Botao para Selecao das Filiais
					If !lSE1Comp
						DEFINE SBUTTON Var oBtFilial FROM 68,162 Type 05 ACTION { || aSelFil := U_Fa330Fil() } ENABLE OF oPanel
						oBtFilial:cCaption := STR0070		//"Filiais"
						oBtFilial:cToolTip := STR0071		//"Seleciona filiais"
					EndIf
					/* GESTAO - fim */
				
					DEFINE SBUTTON FROM 68, 190 Type 1 ENABLE ACTION (If(Fa330TudOk(nVlrCompe),(nOpca:=1,oDLg:End()),)) OF oPanel
					DEFINE SBUTTON FROM 68, 218 Type 2 ENABLE ACTION oDlg:End() OF oPanel
				
					ACTIVATE MSDIALOG oDlg CENTERED
				Else
					If Fa330TudOk(nVlrCompe)
						nOpca:=1
					EndIf
				EndIf
			Else
				If FindFunction("GetParAuto")
					
					aRetAuto := GetParAuto("U_FINA330TestCase")

					If ValType(aRetAuto) != "A" .Or. Len(aRetAuto) == 0
						aRetAuto := GetParAuto("JURBXRTestCase") // Casos de testes - Módulo SIGAPFS
					EndIf
					
					If aRetAuto[1,1,2]
						cPrefixo   := aRetAuto[1,1,1]
					EndIf
					
					If aRetAuto[1,2,2]
						cNum       := aRetAuto[1,2,1]
					EndIf
					
					If aRetAuto[1,3,2]
						cParcela   := aRetAuto[1,3,1]
					EndIf
					
					If aRetAuto[1,4,2]
						cTipoTit   := aRetAuto[1,4,1]
					EndIf
					
					If aRetAuto[1,5,2]
						cCliente   := aRetAuto[1,5,1]
					EndIf
					
					If aRetAuto[1,6,2]
						cLoja      := aRetAuto[1,6,1]
					EndIf
					
					If aRetAuto[1,7,2]
						nVlrCompe  := aRetAuto[1,7,1]
					EndIf
					
					If aRetAuto[1,8,2]
						dBaixa     := aRetAuto[1,8,1] 
					EndIf
					If Len(aRetAuto[1]) > 8 //array com as taxas das moedas {nMoeda, nTaxa} (Simulando a alteração pelo botão de taxas)
						For nN := 1 to Len(aRetAuto[1,9])
							aTxMoedas[aRetAuto[1,9,1,nN][1], 2] := aRetAuto[1,9,1,nN][2]
						Next
						U_Fa330SetMo(lAutomato)
					EndIf
					If Fa330TudOk(nVlrCompe)
						nOpca := 1
					EndIf	
				EndIf
			EndIf

		EndIf
	Else
		nOpca	:=	1
	EndIf
	
	If nOpca == 0
		DBSelectArea(cAlias)
		DBSetOrder(nIndexAtu)
		deleteObject(oOk)
		deleteObject(oNo)
		FA330aUnlock()
		Return
	EndIf
	
	DBSelectArea("SE1")
	
	//Os valores exibidos em tela o serao na Moeda 1	
	If lPccBxCr
		If !__lPccMR
			nPropImp := nVlrCompe / SE1->E1_BASEPIS
			If dDataBase <= dLastPcc
				nPis		:= SE1->E1_PIS * nPropImp
				nCofins		:= SE1->E1_COFINS * nPropImp
				nCsll		:= SE1->E1_CSLL * nPropImp
				nIrrf		:= SE1->E1_IRRF * nPropImp
			Else
				If nVlrCompe > 0
					aPcc	:= newMinPcc(dBaixa,nVlrCompe,SE1->E1_NATUREZ,"R",SE1->E1_CLIENTE+SE1->E1_LOJA)
				Else
					If dBaixa <> dDatabase .And. SE1->E1_TIPO <> MVRECANT //Alterou a data de baixa e nao alterou o valor
						aPcc := newMinPcc(dBaixa,IIf(lMata460, nBasePcc, nOldVal),SE1->E1_NATUREZ,"R",SE1->E1_CLIENTE+SE1->E1_LOJA)
					EndIf
				EndIf
				
				If Len(aPcc) > 2	
					nPis		:= 	aPcc[2]
					nCofins		:=	aPcc[3]
					nCsll		:=  aPcc[4]
					nPisCalc	:= nPis
					nPisBaseC	:= IIf(nVlrCompe	> 0,nVlrCompe ,nOldVal)
					nPisBaseR 	:= IIf(nVlrCompe	> 0,nVlrCompe ,nOldVal)
					nCofCalc	:= nCofins	
					nCofBaseC	:= IIf(nVlrCompe	> 0,nVlrCompe ,nOldVal)
					nCofBaseR 	:= IIf(nVlrCompe	> 0,nVlrCompe ,nOldVal)
					nCslCalc	:= nCsll	
					nCslBaseC	:= IIf(nVlrCompe	> 0,nVlrCompe ,nOldVal)
					nCslBaseR 	:= IIf(nVlrCompe	> 0,nVlrCompe ,nOldVal)								
				EndIf
				
				
				If SE1->E1_BASEIRF < SE1->E1_VALOR
					nIrrf := IIf(nVlrCompe	> 0,nVlrCompe ,nOldVal)*(nIrrf/SE1->E1_VALOR)
				Else
					nIrrf := nIrrf * (IIf(nVlrCompe	> 0,nVlrCompe ,nOldVal) / SE1->E1_BASEIRF)
				EndIf
				
			EndIf
		EndIf
		
		If dBaixa <> dDatabase .And. SE1->E1_TIPO <> MVRECANT //Alterou a data de baixa e nao alterou o valor
			If nPis + nCofins + nCsll + nIrrf > 0  .And. SE1->E1_TIPO <> MV_CRNEG .And. SE1->E1_TIPO <> MVRECANT
				lRetMinAux := ( ( lRaRtImpMR .And. __nPisCaMR + __nCofCaMR + __nCslCaMR + __nIrfCaMR > 0 ) .Or. ( lRaRtImp .And. aDadosRet[1] > nVlMinImp ) )
				If ( !lRartImp .And. !lRaRtImpMR ) .Or. lRetMinAux .And. MV_PAR08 == 2
					nValRec	:= nOldVal
					nValRec -= ( nPis + nCofins + nCsll + nIrrf + nIss + nInss )
					nTotImpbx := ( nPis + nCofins + nCsll + nIrrf + nIss + nInss )
					nSaldo := SE1->E1_SALDO - nPis - nCofins - nCsll
					If nVlrCompe == 0 .And. !lIrPjBxCr
						nSaldo := nSaldo - SE1->E1_IRRF
					EndIf
				EndIf
			EndIf
		EndIf

		nValor := nVlrCompe
		If nVlrCompe > 0 .And. nVlrCompe - nPis - nCofins - nCsll - nIrrf > 0 
			If !( ( !lRartimp .And. !lRaRtImpMR ) .And. MV_PAR08 == 2 )  .And. !lBq10925
				nValor := nValor - nPis - nCofins - nCsll - nIrrf
			EndIf
		EndIf
	Else
		nValor := nVlrCompe
	EndIf

	nValComp := nValor
	nValIrf		:= nIrrf
	Processa({ || Fa330Tit(dEmissao,cOrigem,lCredito,aNumLay,lAutomato)})  // Monta a Matriz com as compensacoes validas

	If Len(aTitulos) == 0
		Help(" ",1,"NOTITSEL")
		DeleteObject(oOk)
		DeleteObject(oNo)
		FA330aUnlock()
		Exit
	EndIf

	nQtdTit := 0
	nOpca := 0
	If cOrigem $ "MATA465#COMPENSANCC"
		cLote	:=	cLoteFat
	EndIf
	aSize := MsAdvSize(,.F.,400)
	If !lAutomato
		cNfOrig     := ""
		cNfOriginal := ""
		cHist       := ""
		cAliasSD1   := "QRYSD1"
		cAliasSE1   := "QRYSE1"
		cTitulo     := SE1->E1_NUM
		nSaldoTit   := SE1->E1_SALDO
		cHist       := SE1->E1_HIST
		cTpTit      := AllTrim(SE1->E1_TIPO)

		cQuery := " SELECT D1_FILIAL, D1_FORNECE, D1_LOJA, D1_SERIE, MAX(D1_NFORI) D1_NFORI, MAX(D1_SERIORI) D1_SERIORI,F1_FORMUL  "
		cQuery += " FROM " + RetSqlName("SD1") + " SD1 "
		cQuery += "    LEFT JOIN  " + RetSqlName("SF1") + " SF1 ON  SF1.F1_DOC = D1_DOC AND F1_SERIE = D1_SERIE AND F1_FORNECE = D1_FORNECE AND F1_LOJA = D1_LOJA AND SF1.D_E_L_E_T_ = ' '"
		cQuery += " WHERE D1_TIPO='D' "
		cQuery += " AND SD1.D_E_L_E_T_ = ' ' "
		cQuery += " AND D1_FILIAL = '"+SE1->E1_FILIAL+"' "  
		cQuery += " AND D1_FORNECE = '"+SE1->E1_CLIENTE+"' "  		
		cQuery += " AND D1_LOJA = '"+SE1->E1_LOJA+"' " 
		cQuery += " AND D1_SERIE = '"+SE1->E1_PREFIXO+"' " 
		cQuery += " GROUP BY D1_FILIAL, D1_FORNECE, D1_LOJA, D1_SERIE,F1_FORMUL "

		cQuery := ChangeQuery(cQuery)

		If Select(cAliasSD1) > 0
			(cAliasSD1)->(DBCloseArea())
		EndIf
		
		dbUseArea(.T.,"TOPCONN",TCGENQRY(,,cQuery), cAliasSD1,.F.,.T.)

		If (cAliasSD1)->(!Eof())
			(cAliasSD1)->(DBGoTop())
			cNfOriginal := (cAliasSD1)->(D1_NFORI)
			cNfOrig   := (cAliasSD1)->(D1_NFORI) + " / " +(cAliasSD1)->(D1_SERIORI)
			cFomulP   := AllTrim((cAliasSD1)->(F1_FORMUL) )
			cFormular :=  IIf(cFomulP=="S","Sim","Nao")
		EndIf

		(cAliasSD1)->(DBCloseArea())
		
		cNFChave := ""

		If AllTrim(cTpTit) <> "NDC"
			If cFomulP == "S"
				cNFChave := cNfOriginal
			Else
				cNFChave := ""

				cQuery := " SELECT E1_NUM "
				cQuery += " FROM " + RetSqlName("SE1") + " SE1 "
				cQuery += " WHERE SE1.D_E_L_E_T_ = ' ' "
				cQuery += " AND E1_HIST LIKE '%"+SE1->E1_NUM+"%' "  

				cQuery := ChangeQuery(cQuery)

				If Select(cAliasSE1) > 0
					(cAliasSE1)->(DBCloseArea())
				EndIf
				
				dbUseArea(.T.,"TOPCONN",TCGENQRY(,,cQuery), cAliasSE1,.F.,.T.)

				If (cAliasSE1)->(!Eof())
					(cAliasSE1)->(DBGoTop())
					cNFChave := (cAliasSE1)->E1_NUM //Subs((cAliasSE1)->(E1_HIST),13,9) 
					cHist := (cAliasSE1)->E1_NUM 
				EndIf

				(cAliasSE1)->(DBCloseArea())			
			EndIf
		Else
			For nHi := 1 to Len(cHist)
				If Subs(cHist,nHi,1) $ "0123456789"
					cNFChave += Subs(cHist,nHi,1)
				EndIf
			Next
		EndIf

		DEFINE MSDIALOG oDlg TITLE cCadastro From aSize[7],0 to aSize[6],aSize[5] of oMainWnd PIXEL
		oDLg:lMaximized := .T.
		oPanel := TPanel():New(0,0,'',oDlg,, .T., .T.,, ,20,20,.T.,.T. )
		oPanel:Align := CONTROL_ALIGN_TOP
		
		@003,005 Say STR0073 + Pad(Getmv("MV_SIMB"+AllTrim(Str(nMoeda))),4)  PIXEL Of oPanel  // "Compensaçäo de Titulos - Valores expressos em "
		
		//Montando cabecalho do list box³
		If _nLayout = 1
			If MV_PAR02 == 2 // Considera Cliente == Não
				nPosPis 	:= 17
				nPosCof 	:= 18
				nPosCsl 	:= 19
				nPosIrf 	:= 20
				nPosBPCC 	:= 27
				nPosBPCR 	:= 28
				nPosBIRF 	:= 29
				nPosxRet	:= 30
				If __lMotRet
					@ 1.0,1.0 LISTBOX oTitulo	VAR cVarQ Fields;
						HEADER "",;						//01
						STR0006,;						//02"Prefixo"
						STR0007,;						//03"Número"
						STR0008,;						//04"Parcela"
						STR0009,;						//05"Tipo"
						"Emissão",;
						"Vencto. Real",;
						"Valor Tit.",;
						STR0016,;						//07"Saldo do t¡tulo"
						STR0017,;						//08"Valor compensado"
						STR0064,;						//09"Limite de compensação"
						RetTitle("E1_FILIAL"),; 		//17"FILIAL"
						Rtrim(RetTitle("E1_HIST")),;	//16"Historico"
						STR0049,;						//10"Acréscimos"
						STR0050,;						//11"Decréscimos"
						STR0125,;						//12"Valores Acessórios"
						RetTitle("E1_PIS"),;			//18
						RetTitle("E1_COFINS"),;			//19
						RetTitle("E1_CSLL"),; 			//20
						RetTitle("E1_IRRF"),;			//21
						STR0126,;						//22"Retenções"
						STR0046,;						//13"Cliente/Loja"
						STR0041,;						//14"Nome do Cliente"
						Rtrim(RetTitle("A1_CGC")),;		//15"CGC do Cliente"
						"Cod Vendedor",;
						"Vendedor",;						
						COLSIZES 12,;															//01
						GetTextWidth(0,"BBBBB"),;												//02
						GetTextWidth(0,"BBBBBBB"),;												//03
						GetTextWidth(0,"BBBB"),;												//04
						GetTextWidth(0,"BBB"),;													//05
						GetTextWidth(0,"BBB"),;													//06
						GetTextWidth(0,"BBBBBBBBB"),;											
						GetTextWidth(0,"BBBBBBBBB"),;											//07
						GetTextWidth(0,"BBBBBBBBB"),;											//08
						GetTextWidth(0,"BBBBBBBBBB"),;											//09
						GetTextWidth(0,"BBBBBBBBB"),;											//10
						GetTextWidth(0,"BBBBBBBBB"),;											//11
						GetTextWidth(0,"BBBBBBBBB"),;											//12
						GetTextWidth(0,"BBBBBBBBB"),;	
						GetTextWidth(0,"BBBBBBBBB"),;											//13
						GetTextWidth(0,"BBBBBBBBBBB"),;											//14
						GetTextWidth(0,"BBBBBBBBBBBBBBBBBB"),;									//15
						GetTextWidth(0,"BBBBBBBBB"),;	
						GetTextWidth(0,"BBBBBB"),;												//16
						GetTextWidth(0,REPLICATE("B",IIf( lFWCodFil, FWGETTAMFILIAL, 2 ))),;	//17
						GetTextWidth(0,"BBBBBB"),;												//18
						GetTextWidth(0,"BBBBBB"),;												//19
						GetTextWidth(0,"BBBBBB"),;												//20
						GetTextWidth(0,"BBBBBB"),;												//21
						GetTextWidth(0,"BBBBBB");												//22
						SIZE 293,54.5 ON DBLCLICK (aTitulos:=FA330Troca(oTitulo:nAt,aTitulos,oGet01,,@oTitulo),oTitulo:Refresh()) NOSCROLL
				Else
					@ 1.0,1.0 LISTBOX oTitulo	VAR cVarQ Fields;
						HEADER "",;					//01
						STR0006,;					//02"Prefixo"
						STR0007,;					//03"N£mero"
						STR0008,;					//04"Parcela"
						STR0009,;					//05"Tipo"
						STR0011,;					//06"Loja"
						"Valor Tit.",;
						STR0016,;					//07"Saldo do t¡tulo"
						STR0017,;					//08"Valor compensado"
						STR0064,;					//09"Limite de compensação"
						STR0049,;					//10"Acréscimos"
						STR0050,;					//11"Decréscimos"
						STR0125,;					//12"Valores Acessórios"
						"Vencto. Real",;
						STR0046,;					//13"Cliente/Loja"
						STR0041,;					//14"Nome do Cliente"
						Rtrim(RetTitle("A1_CGC")),; //15"CGC do Cliente"
						"Cod Vendedor",;
						"Vendedor",;
						Rtrim(RetTitle("E1_HIST")),;//16Historico
						RetTitle("E1_FILIAL"),;		//17FILIAL
						RetTitle("E1_PIS"),;		//18
						RetTitle("E1_COFINS"),;		//19
						RetTitle("E1_CSLL"),;		//20
						RetTitle("E1_IRRF");		//21
						COLSIZES 12,;															//01
						GetTextWidth(0,"BBBBB"),;												//02
						GetTextWidth(0,"BBBBBBB"),;												//03
						GetTextWidth(0,"BBBB"),;												//04
						GetTextWidth(0,"BBB"),;													//05
						GetTextWidth(0,"BBB"),;													//06
						GetTextWidth(0,"BBBBBBBBB"),;
						GetTextWidth(0,"BBBBBBBBB"),;											//07
						GetTextWidth(0,"BBBBBBBBB"),;											//08
						GetTextWidth(0,"BBBBBBBBBB"),;											//09
						GetTextWidth(0,"BBBBBBBBB"),;											//10
						GetTextWidth(0,"BBBBBBBBB"),;											//11
						GetTextWidth(0,"BBBBBBBBB"),;											//12
						GetTextWidth(0,"BBBBBBBBB"),;	
						GetTextWidth(0,"BBBBBBBBB"),;											//13
						GetTextWidth(0,"BBBBBBBBBBB"),;											//14
						GetTextWidth(0,"BBBBBBBBBBBBBBBBBB"),;									//15
						GetTextWidth(0,"BBBBBB"),;												//16
						GetTextWidth(0,"BBBBBBBBB"),;	
						GetTextWidth(0,REPLICATE("B",IIf( lFWCodFil, FWGETTAMFILIAL, 2 ))),;	//17
						GetTextWidth(0,"BBBBBB"),;												//18
						GetTextWidth(0,"BBBBBB"),;												//19
						GetTextWidth(0,"BBBBBB"),;												//20
						GetTextWidth(0,"BBBBBB");												//21
						SIZE 293,54.5 ON DBLCLICK (aTitulos:=FA330Troca(oTitulo:nAt,aTitulos,oGet01,,@oTitulo),oTitulo:Refresh()) NOSCROLL
				EndIf
				If GetFinLGPD()
					oTitulo:aObfuscatedCols := {	.F., ;
													.F., ;
													.F., ;
													.F., ;
													.F., ; // 5
													.F., ;
													.F., ;
													.F., ;
													.F., ;
													.F., ; // 10
													.F., ;
													.F., ;
													.F., ;
													RetGlbLGPD('E1_NOMCLI') , ;
													RetGlbLGPD('A1_CGC') , ; // 15
													RetGlbLGPD('E1_HIST'), ;
													.F., ;
													.F., ;
													.F., ;
													.F., ; // 20
													.F., ;
													.F., }
				EndIf													

				oTitulo:SetArray(aTitulos)
				oTitulo:bLine := { || {If(aTitulos[oTitulo:nAt,8],oOk,oNo),;
					aTitulos[oTitulo:nAt,1],;//Prefixo
					aTitulos[oTitulo:nAt,2],;//Numero
					aTitulos[oTitulo:nAt,3],;//Parcela
					aTitulos[oTitulo:nAt,4],;//Tipo
					aTitulos[oTitulo:nAt,36],;//Emissão
					aTitulos[oTitulo:nAt,33],;//Vencimento
					Transform(aTitulos[oTitulo:nAt,__nPosVrTit],__cPiE1Sld) ,;//valor do Titulo
					aTitulos[oTitulo:nAt,6],;//Saldo do Titulo
					If(aTitulos[oTitulo:nAt,8],aTitulos[oTitulo:nAt,7],Transform(0,__cPiE1Sld)),;//Saldo Compensar
					aTitulos[oTitulo:nAt,25],;//Limite de Compensacao
					aTitulos[oTitulo:nAt,15],;//Historico
					aTitulos[oTitulo:nAt,16],;//Filial
					aTitulos[oTitulo:nAt,13],;//Acréscimos
					aTitulos[oTitulo:nAt,14],;//Decréscimos
					aTitulos[oTitulo:nAt,nPosVa],;//Valores Acessórios
					aTitulos[oTitulo:nAt,17],;//Pis
					aTitulos[oTitulo:nAt,18],;//Cofins
					aTitulos[oTitulo:nAt,19],;//Csll
					aTitulos[oTitulo:nAt,20],;//Irrf
					If(__lMotRet,aTitulos[oTitulo:nAt,30],Nil),;//Motor de Retenções
					aTitulos[oTitulo:nAt,10],;//CLiente+Loja
					aTitulos[oTitulo:nAt,11],;//Nome CLiente
					aTitulos[oTitulo:nAt,12],;//CGC
					aTitulos[oTitulo:nAt,34],;//Cod Vendedor
					aTitulos[oTitulo:nAt,35]}}//Nome Vendedor

			Else // Considera Cliente == Sim
				nPosPis		:= 14
				nPosCof		:= 15
				nPosCsl		:= 16
				nPosIrf		:= 17
				nPosBPCC 	:= 24
				nPosBPCR 	:= 25
				nPosBIRF 	:= 26
				nPosxRet	:= 27
				If __lMotRet
					@ 1.0,1.0 LISTBOX oTitulo	VAR cVarQ Fields;
						HEADER "",;					//01
						STR0006,;					//02"Prefixo"
						STR0007,;					//03"N£mero"
						STR0008,;					//04"Parcela"
						STR0009,;					//05"Tipo"
						"Emissão",;
						"Vencto. Real",;
						"Valor Tit.",;
						STR0016,;					//07"Saldo do t¡tulo"
						STR0017,;					//08"Valor compensado"
						STR0064,;					//09"Limite de compensação"
						Rtrim(RetTitle("E1_HIST")),;//13Historico
						RetTitle("E1_FILIAL"),; 	//14FILIAL
						STR0049,;					//10"Acréscimos"
						STR0050,;					//11"Decréscimos"
						STR0125,;					//12"Valores Acessórios"
						RetTitle("E1_PIS"),; 		//15
						RetTitle("E1_COFINS"),; 	//16
						RetTitle("E1_CSLL"),; 		//17
						RetTitle("E1_IRRF"),; 		//18
						STR0126,;					//19"Retenções"
						"Cod Vendedor",;
						"Vendedor";
						COLSIZES 12,;															//01
						GetTextWidth(0,"BBBBB"),;												//02
						GetTextWidth(0,"BBBBBBB"),;												//03
						GetTextWidth(0,"BBBB"),;												//04
						GetTextWidth(0,"BBB"),;													//05
						GetTextWidth(0,"BBB"),;													//06
						GetTextWidth(0,"BBBBBBBBB"),;	
						GetTextWidth(0,"BBBBBBBBB"),;											//07
						GetTextWidth(0,"BBBBBBBBB"),;											//08
						GetTextWidth(0,"BBBBBBBBBB"),;											//09
						GetTextWidth(0,"BBBBBBBBB"),;											//10
						GetTextWidth(0,"BBBBBBBBB"),;											//11
						GetTextWidth(0,"BBBBBBBBB"),;											//12
						GetTextWidth(0,"BBBBBBBBB"),;	
						GetTextWidth(0,"BBBBBBBBB"),;	
						GetTextWidth(0,"BBBBBBBBBBBBBBBBBBBB"),;								//13
						GetTextWidth(0,REPLICATE("B",IIf( lFWCodFil, FWGETTAMFILIAL, 2 ))),;	//14
						GetTextWidth(0,"BBBBBB"),;												//15
						GetTextWidth(0,"BBBBBB"),;												//16
						GetTextWidth(0,"BBBBBB"),;												//17
						GetTextWidth(0,"BBBBBB"),;												//18
						GetTextWidth(0,"BBBBBB");												//19
						SIZE 293,54.5 ON DBLCLICK (aTitulos:=FA330Troca(oTitulo:nAt,@aTitulos,oGet01,,@oTitulo),oTitulo:Refresh()) NOSCROLL
				Else
					@ 1.0,1.0 LISTBOX oTitulo	VAR cVarQ Fields;
						HEADER "",;					//01
						STR0006,;					//02"Prefixo"
						STR0007,;					//03"N£mero"
						STR0008,;					//04"Parcela"
						STR0009,;					//05"Tipo"
						"Emissão",;
						"Vencto. Real",;
						"Valor Tit.",;
						STR0016,;					//07"Saldo do t¡tulo"
						STR0017,;					//08"Valor compensado"
						STR0064,;					//09"Limite de compensação"
						Rtrim(RetTitle("E1_HIST")),;//13Historico
						STR0049,;					//10"Acréscimos"
						STR0050,;					//11"Decréscimos"
						STR0125,;					//12"Valores Acessórios"
						RetTitle("E1_FILIAL"),; 	//14FILIAL
						RetTitle("E1_PIS"),; 		//15
						RetTitle("E1_COFINS"),; 	//16
						RetTitle("E1_CSLL"),; 		//17
						RetTitle("E1_IRRF"),; 		//18
						"Cod Vendedor",;
						"Vendedor";
						COLSIZES 12,;															//01
						GetTextWidth(0,"BBBBB"),;												//02
						GetTextWidth(0,"BBBBBBB"),;												//03
						GetTextWidth(0,"BBBB"),;												//04
						GetTextWidth(0,"BBB"),;													//05
						GetTextWidth(0,"BBB"),;													//06
						GetTextWidth(0,"BBBBBBBBB"),;
						GetTextWidth(0,"BBBBBBBBB"),;											//07
						GetTextWidth(0,"BBBBBBBBB"),;											//08
						GetTextWidth(0,"BBBBBBBBBB"),;											//09
						GetTextWidth(0,"BBBBBBBBB"),;											//10
						GetTextWidth(0,"BBBBBBBBB"),;											//11
						GetTextWidth(0,"BBBBBBBBB"),;											//12
						GetTextWidth(0,"BBBBBBBBB"),;
						GetTextWidth(0,"BBBBBBBBB"),;	
						GetTextWidth(0,"BBBBBBBBBBBBBBBBBBBB"),;								//13
						GetTextWidth(0,REPLICATE("B",IIf( lFWCodFil, FWGETTAMFILIAL, 2 ))),;	//14
						GetTextWidth(0,"BBBBBB"),;												//15
						GetTextWidth(0,"BBBBBB"),;												//16
						GetTextWidth(0,"BBBBBB"),;												//17
						GetTextWidth(0,"BBBBBB");												//18
						SIZE 293,54.5 ON DBLCLICK (aTitulos:=FA330Troca(oTitulo:nAt,@aTitulos,oGet01,,@oTitulo),oTitulo:Refresh()) NOSCROLL
				EndIf
				
				oTitulo:SetArray(aTitulos)
				oTitulo:bLine := { || {If(aTitulos[oTitulo:nAt,8],oOk,oNo),;//Flag
					aTitulos[oTitulo:nAt,1],;//Prefixo
					aTitulos[oTitulo:nAt,2],;//Numero
					aTitulos[oTitulo:nAt,3],;//Parcela
					aTitulos[oTitulo:nAt,4],;//Tipo
					aTitulos[oTitulo:nAt,33],;//Emissão
					aTitulos[oTitulo:nAt,30],;//Venc Real
					Transform(aTitulos[oTitulo:nAt,__nPosVrTit],__cPiE1Sld) ,;//valor do Titulo
					aTitulos[oTitulo:nAt,6],;//Saldo do Titulo
					If(aTitulos[oTitulo:nAt,8],aTitulos[oTitulo:nAt,7],Transform(0,__cPiE1Sld)),;//Valor Compensado
					aTitulos[oTitulo:nAt,22],;//Limite de Compensacao
					aTitulos[oTitulo:nAt,12],;//Historico
					aTitulos[oTitulo:nAt,13],;//Filial
					aTitulos[oTitulo:nAt,10],;//Acrescimos
					aTitulos[oTitulo:nAt,11],;//Decréscimos
					aTitulos[oTitulo:nAt,nPosVa],;//Valores Acessórios
					aTitulos[oTitulo:nAt,14],;//Pis
					aTitulos[oTitulo:nAt,15],;//Cofins
					aTitulos[oTitulo:nAt,16],;//Csll
					aTitulos[oTitulo:nAt,17],;//Irrf
					If(__lMotRet,aTitulos[oTitulo:nAt,27],Nil),; //Motor de Retenções
					aTitulos[oTitulo:nAt,31],;//Cod Vendedor
					aTitulos[oTitulo:nAt,32]}}//Vendedor
			EndIf
		Else
			If MV_PAR02 == 2 // Considera Cliente == Não
				nPosPis 	:= 17
				nPosCof 	:= 18
				nPosCsl 	:= 19
				nPosIrf 	:= 20
				nPosBPCC 	:= 27
				nPosBPCR 	:= 28
				nPosBIRF 	:= 29
				nPosxRet	:= 30
				If __lMotRet
					@ 1.0,1.0 LISTBOX oTitulo	VAR cVarQ Fields;
						HEADER "",;						//01
						STR0006,;						//02"Prefixo"
						STR0007,;						//03"Número"
						STR0008,;						//04"Parcela"
						STR0009,;						//05"Tipo"
						STR0011,;						//06"Loja"
						"Valor Tit.",;
						STR0016,;						//07"Saldo do t¡tulo"
						STR0017,;						//08"Valor compensado"
						STR0064,;						//09"Limite de compensação"
						STR0049,;						//10"Acréscimos"
						STR0050,;						//11"Decréscimos"
						STR0125,;						//12"Valores Acessórios"
						"Vencto. Real",;
						STR0046,;						//13"Cliente/Loja"
						STR0041,;						//14"Nome do Cliente"
						Rtrim(RetTitle("A1_CGC")),;		//15"CGC do Cliente"
						"Cod Vendedor",;
						"Vendedor",;
						Rtrim(RetTitle("E1_HIST")),;	//16"Historico"
						RetTitle("E1_FILIAL"),; 		//17"FILIAL"
						RetTitle("E1_PIS"),;			//18
						RetTitle("E1_COFINS"),;			//19
						RetTitle("E1_CSLL"),; 			//20
						RetTitle("E1_IRRF"),;			//21
						STR0126;						//22"Retenções"
						COLSIZES 12,;															//01
						GetTextWidth(0,"BBBBB"),;												//02
						GetTextWidth(0,"BBBBBBB"),;												//03
						GetTextWidth(0,"BBBB"),;												//04
						GetTextWidth(0,"BBB"),;													//05
						GetTextWidth(0,"BBB"),;													//06
						GetTextWidth(0,"BBBBBBBBB"),;											
						GetTextWidth(0,"BBBBBBBBB"),;											//07
						GetTextWidth(0,"BBBBBBBBB"),;											//08
						GetTextWidth(0,"BBBBBBBBBB"),;											//09
						GetTextWidth(0,"BBBBBBBBB"),;											//10
						GetTextWidth(0,"BBBBBBBBB"),;											//11
						GetTextWidth(0,"BBBBBBBBB"),;											//12
						GetTextWidth(0,"BBBBBBBBB"),;	
						GetTextWidth(0,"BBBBBBBBB"),;											//13
						GetTextWidth(0,"BBBBBBBBBBB"),;											//14
						GetTextWidth(0,"BBBBBBBBBBBBBBBBBB"),;									//15
						GetTextWidth(0,"BBBBBBBBB"),;	
						GetTextWidth(0,"BBBBBB"),;												//16
						GetTextWidth(0,REPLICATE("B",IIf( lFWCodFil, FWGETTAMFILIAL, 2 ))),;	//17
						GetTextWidth(0,"BBBBBB"),;												//18
						GetTextWidth(0,"BBBBBB"),;												//19
						GetTextWidth(0,"BBBBBB"),;												//20
						GetTextWidth(0,"BBBBBB"),;												//21
						GetTextWidth(0,"BBBBBB");												//22
						SIZE 293,54.5 ON DBLCLICK (aTitulos:=FA330Troca(oTitulo:nAt,aTitulos,oGet01,,@oTitulo),oTitulo:Refresh()) NOSCROLL
				Else
					@ 1.0,1.0 LISTBOX oTitulo	VAR cVarQ Fields;
						HEADER "",;					//01
						STR0006,;					//02"Prefixo"
						STR0007,;					//03"N£mero"
						STR0008,;					//04"Parcela"
						STR0009,;					//05"Tipo"
						STR0011,;					//06"Loja"
						"Valor Tit.",;
						STR0016,;					//07"Saldo do t¡tulo"
						STR0017,;					//08"Valor compensado"
						STR0064,;					//09"Limite de compensação"
						STR0049,;					//10"Acréscimos"
						STR0050,;					//11"Decréscimos"
						STR0125,;					//12"Valores Acessórios"
						"Vencto. Real",;
						STR0046,;					//13"Cliente/Loja"
						STR0041,;					//14"Nome do Cliente"
						Rtrim(RetTitle("A1_CGC")),; //15"CGC do Cliente"
						"Cod Vendedor",;
						"Vendedor",;
						Rtrim(RetTitle("E1_HIST")),;//16Historico
						RetTitle("E1_FILIAL"),;		//17FILIAL
						RetTitle("E1_PIS"),;		//18
						RetTitle("E1_COFINS"),;		//19
						RetTitle("E1_CSLL"),;		//20
						RetTitle("E1_IRRF");		//21
						COLSIZES 12,;															//01
						GetTextWidth(0,"BBBBB"),;												//02
						GetTextWidth(0,"BBBBBBB"),;												//03
						GetTextWidth(0,"BBBB"),;												//04
						GetTextWidth(0,"BBB"),;													//05
						GetTextWidth(0,"BBB"),;													//06
						GetTextWidth(0,"BBBBBBBBB"),;
						GetTextWidth(0,"BBBBBBBBB"),;											//07
						GetTextWidth(0,"BBBBBBBBB"),;											//08
						GetTextWidth(0,"BBBBBBBBBB"),;											//09
						GetTextWidth(0,"BBBBBBBBB"),;											//10
						GetTextWidth(0,"BBBBBBBBB"),;											//11
						GetTextWidth(0,"BBBBBBBBB"),;											//12
						GetTextWidth(0,"BBBBBBBBB"),;	
						GetTextWidth(0,"BBBBBBBBB"),;											//13
						GetTextWidth(0,"BBBBBBBBBBB"),;											//14
						GetTextWidth(0,"BBBBBBBBBBBBBBBBBB"),;									//15
						GetTextWidth(0,"BBBBBB"),;												//16
						GetTextWidth(0,"BBBBBBBBB"),;	
						GetTextWidth(0,REPLICATE("B",IIf( lFWCodFil, FWGETTAMFILIAL, 2 ))),;	//17
						GetTextWidth(0,"BBBBBB"),;												//18
						GetTextWidth(0,"BBBBBB"),;												//19
						GetTextWidth(0,"BBBBBB"),;												//20
						GetTextWidth(0,"BBBBBB");												//21
						SIZE 293,54.5 ON DBLCLICK (aTitulos:=FA330Troca(oTitulo:nAt,aTitulos,oGet01,,@oTitulo),oTitulo:Refresh()) NOSCROLL
				EndIf
				If GetFinLGPD()
					oTitulo:aObfuscatedCols := {	.F., ;
													.F., ;
													.F., ;
													.F., ;
													.F., ; // 5
													.F., ;
													.F., ;
													.F., ;
													.F., ;
													.F., ; // 10
													.F., ;
													.F., ;
													.F., ;
													RetGlbLGPD('E1_NOMCLI') , ;
													RetGlbLGPD('A1_CGC') , ; // 15
													RetGlbLGPD('E1_HIST'), ;
													.F., ;
													.F., ;
													.F., ;
													.F., ; // 20
													.F., ;
													.F., }
				EndIf													

				oTitulo:SetArray(aTitulos)
				oTitulo:bLine := { || {If(aTitulos[oTitulo:nAt,8],oOk,oNo),;
					aTitulos[oTitulo:nAt,1],;//Prefixo
					aTitulos[oTitulo:nAt,2],;//Numero
					aTitulos[oTitulo:nAt,3],;//Parcela
					aTitulos[oTitulo:nAt,4],;//Tipo
					aTitulos[oTitulo:nAt,5],;//Loja
					Transform(aTitulos[oTitulo:nAt,__nPosVrTit],__cPiE1Sld) ,;//valor do Titulo
					aTitulos[oTitulo:nAt,6],;//Saldo do Titulo
					If(aTitulos[oTitulo:nAt,8],aTitulos[oTitulo:nAt,7],Transform(0,__cPiE1Sld)),;//Saldo Compensar
					aTitulos[oTitulo:nAt,25],;//Limite de Compensacao
					aTitulos[oTitulo:nAt,13],;//Acréscimos
					aTitulos[oTitulo:nAt,14],;//Decréscimos
					aTitulos[oTitulo:nAt,nPosVa],;//Valores Acessórios
					aTitulos[oTitulo:nAt,33],;//Vencimento
					aTitulos[oTitulo:nAt,10],;//CLiente+Loja
					aTitulos[oTitulo:nAt,11],;//Nome CLiente
					aTitulos[oTitulo:nAt,12],;//CGC
					aTitulos[oTitulo:nAt,34],;//Cod Vendedor
					aTitulos[oTitulo:nAt,35],;//Nome Vendedor
					aTitulos[oTitulo:nAt,15],;//Historico
					aTitulos[oTitulo:nAt,16],;//Filial
					aTitulos[oTitulo:nAt,17],;//Pis
					aTitulos[oTitulo:nAt,18],;//Cofins
					aTitulos[oTitulo:nAt,19],;//Csll
					aTitulos[oTitulo:nAt,20],;//Irrf
					If(__lMotRet,aTitulos[oTitulo:nAt,30],Nil)}}//Motor de Retenções
	
			Else // Considera Cliente == Sim
				nPosPis		:= 14
				nPosCof		:= 15
				nPosCsl		:= 16
				nPosIrf		:= 17
				nPosBPCC 	:= 24
				nPosBPCR 	:= 25
				nPosBIRF 	:= 26
				nPosxRet	:= 27
				If __lMotRet
					@ 1.0,1.0 LISTBOX oTitulo	VAR cVarQ Fields;
						HEADER "",;					//01
						STR0006,;					//02"Prefixo"
						STR0007,;					//03"N£mero"
						STR0008,;					//04"Parcela"
						STR0009,;					//05"Tipo"
						STR0011,;					//06"Loja"
						"Valor Tit.",;
						STR0016,;					//07"Saldo do t¡tulo"
						STR0017,;					//08"Valor compensado"
						STR0064,;					//09"Limite de compensação"
						STR0049,;					//10"Acréscimos"
						STR0050,;					//11"Decréscimos"
						STR0125,;					//12"Valores Acessórios"
						"Vencto. Real",;
						"Cod Vendedor",;
						"Vendedor",;
						Rtrim(RetTitle("E1_HIST")),;//13Historico
						RetTitle("E1_FILIAL"),; 	//14FILIAL
						RetTitle("E1_PIS"),; 		//15
						RetTitle("E1_COFINS"),; 	//16
						RetTitle("E1_CSLL"),; 		//17
						RetTitle("E1_IRRF"),; 		//18
						STR0126;					//19"Retenções"
						COLSIZES 12,;															//01
						GetTextWidth(0,"BBBBB"),;												//02
						GetTextWidth(0,"BBBBBBB"),;												//03
						GetTextWidth(0,"BBBB"),;												//04
						GetTextWidth(0,"BBB"),;													//05
						GetTextWidth(0,"BBB"),;													//06
						GetTextWidth(0,"BBBBBBBBB"),;	
						GetTextWidth(0,"BBBBBBBBB"),;											//07
						GetTextWidth(0,"BBBBBBBBB"),;											//08
						GetTextWidth(0,"BBBBBBBBBB"),;											//09
						GetTextWidth(0,"BBBBBBBBB"),;											//10
						GetTextWidth(0,"BBBBBBBBB"),;											//11
						GetTextWidth(0,"BBBBBBBBB"),;											//12
						GetTextWidth(0,"BBBBBBBBB"),;	
						GetTextWidth(0,"BBBBBBBBB"),;	
						GetTextWidth(0,"BBBBBBBBBBBBBBBBBBBB"),;								//13
						GetTextWidth(0,REPLICATE("B",IIf( lFWCodFil, FWGETTAMFILIAL, 2 ))),;	//14
						GetTextWidth(0,"BBBBBB"),;												//15
						GetTextWidth(0,"BBBBBB"),;												//16
						GetTextWidth(0,"BBBBBB"),;												//17
						GetTextWidth(0,"BBBBBB"),;												//18
						GetTextWidth(0,"BBBBBB");												//19
						SIZE 293,54.5 ON DBLCLICK (aTitulos:=FA330Troca(oTitulo:nAt,@aTitulos,oGet01,,@oTitulo),oTitulo:Refresh()) NOSCROLL
				Else
					@ 1.0,1.0 LISTBOX oTitulo	VAR cVarQ Fields;
						HEADER "",;					//01
						STR0006,;					//02"Prefixo"
						STR0007,;					//03"N£mero"
						STR0008,;					//04"Parcela"
						STR0009,;					//05"Tipo"
						STR0011,;					//06"Loja"
						"Valor Tit.",;
						STR0016,;					//07"Saldo do t¡tulo"
						STR0017,;					//08"Valor compensado"
						STR0064,;					//09"Limite de compensação"
						STR0049,;					//10"Acréscimos"
						STR0050,;					//11"Decréscimos"
						STR0125,;					//12"Valores Acessórios"
						"Vencto. Real",;
						"Cod Vendedor",;
						"Vendedor",;
						Rtrim(RetTitle("E1_HIST")),;//13Historico
						RetTitle("E1_FILIAL"),; 	//14FILIAL
						RetTitle("E1_PIS"),; 		//15
						RetTitle("E1_COFINS"),; 	//16
						RetTitle("E1_CSLL"),; 		//17
						RetTitle("E1_IRRF"); 		//18
						COLSIZES 12,;															//01
						GetTextWidth(0,"BBBBB"),;												//02
						GetTextWidth(0,"BBBBBBB"),;												//03
						GetTextWidth(0,"BBBB"),;												//04
						GetTextWidth(0,"BBB"),;													//05
						GetTextWidth(0,"BBB"),;													//06
						GetTextWidth(0,"BBBBBBBBB"),;
						GetTextWidth(0,"BBBBBBBBB"),;											//07
						GetTextWidth(0,"BBBBBBBBB"),;											//08
						GetTextWidth(0,"BBBBBBBBBB"),;											//09
						GetTextWidth(0,"BBBBBBBBB"),;											//10
						GetTextWidth(0,"BBBBBBBBB"),;											//11
						GetTextWidth(0,"BBBBBBBBB"),;											//12
						GetTextWidth(0,"BBBBBBBBB"),;
						GetTextWidth(0,"BBBBBBBBB"),;	
						GetTextWidth(0,"BBBBBBBBBBBBBBBBBBBB"),;								//13
						GetTextWidth(0,REPLICATE("B",IIf( lFWCodFil, FWGETTAMFILIAL, 2 ))),;	//14
						GetTextWidth(0,"BBBBBB"),;												//15
						GetTextWidth(0,"BBBBBB"),;												//16
						GetTextWidth(0,"BBBBBB"),;												//17
						GetTextWidth(0,"BBBBBB");												//18
						SIZE 293,54.5 ON DBLCLICK (aTitulos:=FA330Troca(oTitulo:nAt,@aTitulos,oGet01,,@oTitulo),oTitulo:Refresh()) NOSCROLL
				EndIf
				
				oTitulo:SetArray(aTitulos)
				oTitulo:bLine := { || {If(aTitulos[oTitulo:nAt,8],oOk,oNo),;//Flag
					aTitulos[oTitulo:nAt,1],;//Prefixo
					aTitulos[oTitulo:nAt,2],;//Numero
					aTitulos[oTitulo:nAt,3],;//Parcela
					aTitulos[oTitulo:nAt,4],;//Tipo
					aTitulos[oTitulo:nAt,5],;//Loja
					Transform(aTitulos[oTitulo:nAt,__nPosVrTit],__cPiE1Sld) ,;//valor do Titulo
					aTitulos[oTitulo:nAt,6],;//Saldo do Titulo
					If(aTitulos[oTitulo:nAt,8],aTitulos[oTitulo:nAt,7],Transform(0,__cPiE1Sld)),;//Valor Compensado
					aTitulos[oTitulo:nAt,22],;//Limite de Compensacao
					aTitulos[oTitulo:nAt,10],;//Acrescimos
					aTitulos[oTitulo:nAt,11],;//Decréscimos
					aTitulos[oTitulo:nAt,nPosVa],;//Valores Acessórios
					aTitulos[oTitulo:nAt,30],;//Venc Real
					aTitulos[oTitulo:nAt,31],;//Cod Vendedor
					aTitulos[oTitulo:nAt,32],;//Vendedor
					aTitulos[oTitulo:nAt,12],;//Historico
					aTitulos[oTitulo:nAt,13],;//Filial
					aTitulos[oTitulo:nAt,14],;//Pis
					aTitulos[oTitulo:nAt,15],;//Cofins
					aTitulos[oTitulo:nAt,16],;//Csll
					aTitulos[oTitulo:nAt,17],;//Irrf
					If(__lMotRet,aTitulos[oTitulo:nAt,27],Nil)}}//Motor de Retenções
			EndIf
		EndIf
	EndIf
	
	If !lAutomato
		If !cPaisLoc $ "BRA|RUS"
			oTitulo:bHeaderClick := {|oObj,nCol| IIf( nCol == 1, fMarkAll( @aTitulos, @nValTot ), Nil ), oTitulo:Refresh(), oGet01:Refresh()}
		EndIf
		
		oTitulo:Align := CONTROL_ALIGN_ALLCLIENT
		//---

		@  1, 140 Say "Total seleccionado" PIXEL OF oPanel SIZE 70,7
		@  8, 140 MSGET oGet01 VAR nValTot PICTURE "@E 999,999,999.99" WHEN .F. PIXEL OF oPanel SIZE 70,7

		//@  4, 350 Say "Nota / Serie Orig" PIXEL OF oPanel SIZE 70,7
		//@  4, 400 MSGET oGet02 VAR cNfOrig  WHEN .F. PIXEL OF oPanel SIZE 70,7

		@  1, 220 Say "Nr. Título" PIXEL OF oPanel SIZE 70,7
		@  8, 220 MSGET oGet02 VAR cTitulo  WHEN .F. PIXEL OF oPanel SIZE 70,7

		@  1, 300 Say "Formulário Proprio" PIXEL OF oPanel SIZE 70,7
		@  8, 300 MSGET oGet02 VAR cFormular  WHEN .F. PIXEL OF oPanel SIZE 70,7

		@  1, 380 Say "Nota / Serie Orig" PIXEL OF oPanel SIZE 70,7
		@  8, 380 MSGET oGet03 VAR cNfOrig  WHEN .F. PIXEL OF oPanel SIZE 70,7

		@  1, 460 Say "Saldo do Titulo" PIXEL OF oPanel SIZE 70,7
		@  8, 460 MSGET oGet04 VAR nSaldoTit PICTURE "@E 999,999,999.99" WHEN .F. PIXEL OF oPanel SIZE 70,7

		@  1, 540 Say "Histórico" PIXEL OF oPanel SIZE 70,7
		@  8, 540 MSGET oGet05 VAR cHist  WHEN .F. PIXEL OF oPanel SIZE 120,7
		
		nLinhaMark := 0
		If _nLayout = 2
			For ni := 1 To Len(aTitulos)
				If AllTrim(aTitulos[ni,2]) == AllTrim(cNFChave)
					aTitulos:=FA330Troca(ni,@aTitulos,oGet01,,@oTitulo,,.T.)
					oTitulo:Refresh()
					nLinhaMark := ni
				EndIf
			Next
		EndIf

		If lF330ATLIS
			ExecBlock("F330ATLIS",.F.,.F., { @oPanel , 1, nValTot , nValor } )
		EndIf
	EndIf
	
	If !lPanelFin  //Chamado pelo Painel Financeiro
	  If !lAutomato
		oPanel2 := TPanel():New(0,0,'',oDlg, oDlg:oFont, .T., .T.,, ,20,20,.T.,.T. )
		oPanel2:Align := CONTROL_ALIGN_BOTTOM

		@  4, 08   BUTTON STR0124 SIZE 50,11 ACTION (U_F330Button(lPccBxCr,oTitulo,oGet01,.T.)) OF oPanel2 PIXEL //"Marcar todos"
		@  4, 65   BUTTON STR0044 SIZE 50,11 ACTION (U_F330Button(lPccBxCr,oTitulo,oGet01,.F.)) OF oPanel2 PIXEL //"Inverter seleção"
		@  4, 122  BUTTON STR0001 SIZE 50,11 ACTION U_PesqListBox(@oTitulo,aTitulos) OF oPanel2 PIXEL //"Buscar"
		//VA: Adiciona a consulta do VA
		If __l330Va
			@  4, 179  BUTTON STR0125 SIZE 50,11 ACTION FA330VACON(aTitulos[oTitulo:nAt]) OF oPanel2 PIXEL //"Valores accesorios"
		EndIf
		
		If cPaisLoc == "RUS"
			@  4, 179 BUTTON STR0098 SIZE 50,11 ACTION FINA330Filt(@oTitulo,@aTitulos,cNumCont,lAutomato,@oOk,@oNo,cVarQ,oPanel,dEmissao,cOrigem,lCredito,aNumLay,cNumCont) OF oPanel2 PIXEL
			@  4, 236 BUTTON STR0100 SIZE 50,11 ACTION FINA330Unfil(@oTitulo,@aTitulos,lAutomato,@oOk,@oNo,dEmissao,cOrigem,lCredito,aNumLay,cNumCont) OF oPanel2 PIXEL
			@  4, 293 BUTTON STR0091 SIZE 50,11 ACTION FA330AutoMark(@oTitulo,@aTitulos,lAutomato,@oOk,@oNo,dEmissao,cOrigem,lCredito,aNumLay,cNumCont) OF oPanel2 PIXEL
			@  4, 350 BUTTON STR0094 SIZE 50,11 ACTION FINA330Sort(@oTitulo,@aTitulos,cNumCont,lAutomato,@oOk,@oNo,@oPanel,@nValTot) OF oPanel2 PIXEL	
		EndIf

		If lF330BOTON
		   	ExecBlock("F330BOTON",.F.,.F.)
   		EndIf

		   DEFINE SBUTTON FROM 4,IIf(cPaisLoc != "RUS",325,425) Type 1 ACTION (nValor := nVlrCompe,nOpca := 1,If(Fa330OK(@nValTot,.F.,lPccBxCR),oDlg:End(),nOpca:=0)) ENABLE OF oPanel2 PIXEL
			If cOrigem != "LOJA800"
			   DEFINE SBUTTON FROM 4,IIf(cPaisLoc != "RUS",360,460) Type 2 ACTION oDlg:End() ENABLE OF oPanel2 PIXEL
			EndIf
		EndIf

   Else
   	If !lAutomato
			aButtonTxt := {}
			aAdd(aButtonTxt,{STR0124,STR0124, {||U_F330Button(lPccBxCr,oTitulo,oGet01,.T.)}})
			aAdd(aButtonTxt,{STR0061,STR0044, {||U_F330Button(lPccBxCr,oTitulo,oGet01,.F.)}})
			aAdd(aButtonTxt,{STR0001,STR0001, {||U_PesqListBox(@oTitulo,aTitulos)}})
		EndIf
   EndIf

	If lPanelFin  //Chamado pelo Painel Financeiro
	   If cOrigem != "LOJA800"
		   ACTIVATE MSDIALOG oDlg ON INIT (oTitulo:Refresh(), FaMyBar(oDlg,;
		   	{||nValor := nVlrCompe,nOpca := 1,If(Fa330OK(@nValTot,.F.,lPccBxCR),oDlg:End(),nOpca:=0)},;
				{||oDlg:End()},,aButtonTxt))
		Else
		   ACTIVATE MSDIALOG oDlg ON INIT (oTitulo:Refresh(), FaMyBar(oDlg,;
		   	{||nValor := nVlrCompe,nOpca := 1,If(Fa330OK(@nValTot,.F.,lPccBxCR),oDlg:End(),nOpca:=0)},;
				,,aButtonTxt))
		EndIf
	Else
		If !lAutomato
			If nLinhaMark > 0
				oTitulo:nAt := nLinhaMark
			EndIf
			If !lCheck
				fDsMarkAll(@aTitulos, @nValTot)
			EndIf

			ACTIVATE MSDIALOG oDlg CENTERED ON INIT (oTitulo:Refresh())
		Else
			If FindFunction("GetParAuto")

				aRetAuto := GetParAuto("U_FINA330TestCase")

				If ValType(aRetAuto) != "A" .Or. Len(aRetAuto) == 0
					aRetAuto := GetParAuto("JURBXRTestCase") // Casos de testes - Módulo SIGAPFS
				EndIf

				AEval(aTitulos,{|x| x[8] := .F.})

				For nX := 1 to Len(aTitulos)
					For nI := 1 to Len (aRetAuto[2])
						If aTitulos[nX,1] == PadR(aRetAuto[2,nI,1],Len(aTitulos[nX,1])) .And. ;//Prefixo
							aTitulos[nX,2] == PadR(aRetAuto[2,nI,2],Len(aTitulos[nX,2])) .And. ;//Titulo
							aTitulos[nX,3] == PadR(aRetAuto[2,nI,3],Len(aTitulos[nX,3])) .And. ;//Parcela
							aTitulos[nX,4] == PadR(aRetAuto[2,nI,4],Len(aTitulos[nX,4]))        //Tipo
				
							aTitulos[nX,8] := .T.
							If !lSelAuto
								lSelAuto := aTitulos[nX,8]
							EndIf
						EndIf
					Next nI
				Next nX
			
				If lSelAuto
					If Fa330OK(@nValTot,lAutomato,lPccBxCR) 
						nOpcA 		:= 1
						lSelAuto	:= .F.
					EndIf
				EndIf
			EndIf
		EndIf    
	EndIf

	If nOpcA == 1
	
		If __lMotRet .And. ( ( nValTot < nSaldo ) .Or. ( lCredito .And. MV_PAR08 == 1 ) )
			aSize( aAuxTitMR, 5 ) 
			aAuxTitMR[1] := SE1->E1_NATUREZ
			aAuxTitMR[2] := SE1->E1_CLIENTE
			aAuxTitMR[3] := SE1->E1_LOJA
			aAuxTitMR[4] := SE1->E1_FILORIG
			aAuxTitMR[5] := SE1->E1_TIPO
		EndIf
		
		If lFa330Cmp
			ExecBlock("FA330Cmp",.F.,.F.)
		EndIf
		
		dDtEmis	:= SE1->E1_EMISSAO
		
		DBSelectArea("SE1")
		nOrdSE1		:= IndexOrd()
		DBGoTop()
		lPadrao		:= VerPadrao(cPadrao)
		VALOR 		:= 0
		ABATIMENTO 	:= 0
		VARIACAO	:= 0
		aRegSE1 	:= {}
		aBaixaSE5 	:= {}
		
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Inicio da prote‡„o via TTS							³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ		
		If cPaisLoc == "BRA"
			For nX := 1 To Len( aTitulos )
				If	aTitulos[nX,8] 
					nVTit += U_Fa330VTit( aTitulos[ nX , 7 ] )
				EndIf
			Next nX
		EndIf
		
		_aMarc := {}

		Begin Transaction	
			For nTit := 1 to Len(aTitulos)
				__nTxMoedD := 0
				__nPosTit := nTit
				nPos      := 22
										
				If MV_PAR02 == 2
					nPos := 25
				EndIf
				If aTitulos[nTit,8]
					lMarcado := .T.
				EndIf

					//Caso o titulo esteja selecionado para compensação
				If lMarcado	
					lContabiliza    := (MV_PAR09 == 1) // Contabiliza On Line ?
					lDigita         := (MV_PAR07 == 1) // Mostra Lanc Contab ?
					lAglutina       := .F.
					aTxMoeda        := {}
					nTaxaCM         := RecMoeda(dDataBase,SE1->E1_MOEDA)
					nSaldoComp      := aTitulos[nTit][9]
					aAdd(aTxMoeda, {1, 1} )
					aAdd(aTxMoeda, {2, nTaxaCM} )

					If lRA
						aRecSE1 := { aTitulos[nTit][__nPosRecn] }
						aRecRA := { nRecno }
					Else
						aRecRA := { aTitulos[nTit][__nPosRecn] }
						aRecSE1 := { nRecno }
					EndIf

					

					If !MaIntBxCR(3, aRecSE1,,aRecRA,,{lContabiliza,lAglutina,lDigita,.F.,.F.,.F.},,,,,nSaldoComp,,,, nTaxaCM, aTxMoeda)
						Help("XAFCMPAD",1,"HELP","XAFCMPAD","Não foi possível a compensação"+CRLF+" do titulo de adiantamento",1,0)
						lRet := .F.
					Else
						If _lMOMS68
							aAdd(__aContrat,{ nRecno,aTitulos[nTit][__nPosRecn],nSaldoComp})
						EndIf

						aAdd(_aMarc, aTitulos[nTit][__nPosRecn] )

					EndIf

					lMarcado := .F.

				EndIf
			Next

			SE1->(DBGoTo(nRecno))

			DBSelectArea("SE5")
			DBSetOrder(7) //	E5_FILIAL+E5_PREFIXO+E5_NUMERO+E5_PARCELA+E5_TIPO+E5_CLIFOR+E5_LOJA+E5_SEQ
			If DBSeek(SE1->(E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO))
				While SE1->(E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO) == SE5->(E5_FILIAL+E5_PREFIXO+E5_NUMERO+E5_PARCELA+E5_TIPO) .And. SE5->(!Eof())
					aAdd(aRecSe5,SE5->(Recno()))
					SE5->(DBSkip())
				EndDo
			EndIf

			For nTit := 1 to Len(_aMarc)
				SE1->(DBGoTo(_aMarc[nTit]))

				DBSelectArea("SE5")
				DBSetOrder(7) //	E5_FILIAL+E5_PREFIXO+E5_NUMERO+E5_PARCELA+E5_TIPO+E5_CLIFOR+E5_LOJA+E5_SEQ
				If DBSeek(SE1->(E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO))
					While SE1->(E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO) == SE5->(E5_FILIAL+E5_PREFIXO+E5_NUMERO+E5_PARCELA+E5_TIPO) .And. SE5->(!Eof())
						aAdd(aRecSe5,SE5->(Recno()))
						SE5->(DBSkip())
					EndDo
				EndIf
			Next

			SE1->(DBGoTo(nRecno))

			If lF330SE5 
				ExecBlock("F330SE5",.F.,.F.,{aRecSe5})
			EndIf   
			
		//Final  da protecao via TTS
		End Transaction
	EndIf
	Exit
EndDo
cFILFIN023 := CriaVar("E1_FILIAL")
cPrefixo := CriaVar("E1_PREFIXO")
cNum	 := CriaVar("E1_NUM")
cTipoTit := CriaVar("E1_TIPO")
cCliente := CriaVar("E1_CLIENTE")
cLoja 	 := CriaVar("E1_LOJA")
cSaldo	 := CriaVar("E1_SALDO")
nValor	 := CriaVar("E1_SALDO")
cParcela := CriaVar("E1_PARCELA")
nMoeda	 := 1
nValor	 := 0
nValTot	 := 0

// Finaliza a gravacao dos lancamentos do SIGAPCO
PcoFinLan("000016")

// Recupera a Integridade dos dados
DBSelectArea("SE1")
DBSetOrder(nIndexAtu)
DBGoTo(nTitIni)

DeleteObject(oOk)
DeleteObject(oNo)
FA330aUnlock()
Return (.T.)

/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡„o	 ³ fa330Cli ³ Autor ³ Mauricio Pequim Jr.   ³ Data ³ 21/03/94 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡„o ³ Verifica validade do Cliente								  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe	 ³ fa330Cli()												  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ FINA330													  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function fa330Cli( )
Local cAlias := Alias( )
DBSelectArea("SA1")
DBSeek(xFilial("SA1")+cCliente)
If !Found()
	Help(" ",1,"A330CLI")
	Return .F.
Else
	cLoja:=IIf(Empty(cLoja),SA1->A1_LOJA,cLoja)
EndIf
DBSelectArea(cAlias)
Return .T.

/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡„o	 ³ fa330Loja³ Autor ³ Mauricio Pequim Jr.   ³ Data ³ 21/03/94 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡„o ³ Verifica validade da Loja do Cliente						  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe	 ³ fa330Loja() 												  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ FINA330													  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function fa330Loja()
Local cAlias:=Alias()
Local nOrdSe1 := 0
Local lRet := .T.

//PCREQ-3782 - Bloqueio por situação de cobrança
Local cLstCart := FN022LSTCB(1,'0007')	//Lista das situacoes de cobranca (Carteira)
Local cLstNoBlq := FN022LSTCB(6,'0007')	//Lista das situacoes de cobranca (Não bloqueadas para determinado processo)

If Funname() == "FINA740"
	SetKey (VK_F12)
EndIf

DBSelectArea("SA1")
DBSeek(xFilial("SA1")+cCliente+cLoja)
If !Found()
	Help(" ",1,"A330LOJA")
	lRet := .F.
EndIf
If lRet
	DBSelectArea("SE1")
	nOrdSe1 := IndexOrd()
	SE1->(DBSetOrder(2))
	//If DBSeek(xFilial("SE1")+cCliente+cLoja+cPrefixo+cNum+cParcela+cTipoTit)
	If DBSeek(cFILFIN023+cCliente+cLoja+cPrefixo+cNum+cParcela+cTipoTit)
		If MV_PAR05 == 2 .And. !(E1_SITUACA $ cLstCart)
			Help(" ",1,"F330CARTE")
			lRet := .F.

		//PCREQ-3782 - Bloqueio por situação de cobrança
		ElseIf !(E1_SITUACA $ cLstNoBlq)
			Help(" ",1,"F330BLOQD",,STR0079,1,0)	//"Não é possível realizar a operação pois o título se encontra em situação de cobrança que não permite manutenção ou movimento financeiro do titulo."
			lRet := .F.
		EndIf
	Else
		Help(" ",1,"NOTIT")
		lRet := .F.
	EndIf
	DBSetOrder(nOrdSe1)
EndIf

DBSelectArea(cAlias)

Return lRet

/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡„o	 ³Fa330Tit	³ Autor ³ Mauricio Pequim Jr.   ³ Data ³ 22/09/97 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡„o ³ Gera Tabela com os titulos 								  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ Fina330													  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Static Function Fa330Tit(dEmissao,cOrigem,lCredito,aNumLay,lAutomato)

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Salva a Integridade dos dados de Entrada 						  ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
Local cSavArea 	:= alias()
Local cAliasSE1	:= "SE1"
Local lMarca	:= .T.
Local lF330RIO  := ExistBlock("F330RIO")
Local lF330CMP  := ExistBlock("F330CMP")
Local lFI330ALT	:= ExistBlock("FI330ALT")
Local nSavOrd	:= IndexOrd()
Local nRecNo	:= Recno()
Local nTotComp	:= 0
Local nVlBasico := 0
Local nDecs     := MsDecimais(nMoeda)
Local bWhile    := {|| .T.}
Local nRecEmp  	:= SM0->(RecNo())
Local cEmpAnt  	:= SM0->M0_CODIGO
Local cFilDe
Local cFilAte
Local cCgcClie
Local cNomClie
Local nX 		:= 0
Local nPosNumLay:= 0
Local lFa330Qry := Existblock("FA330QRY")
Local cOrdemSE1
Local lTitRAMex	:= cPaisLoc == "MEX" .And. X3Usado("ED_OPERADT") //Define se o titulo de RA esta disponivel - Manejo de Anticipo
Local lPropRA 	:= SuperGetMv("MV_COMPCR",,.F.)                     //Verifica se vai proporcionalizar quando RA para NF.
Local lPccBxCr	:= FPccBxCr()								    	//Controla o Pis Cofins e Csll na baixa  (1-Retem PCC na Baixa ou 2-Retem PCC na Emissão(default) )
Local lIrPjBxCr	:= FIrPjBxCr()									   //Controla IRPJ na baixa
Local aOldBaixaSE5
Local aBxSE5		:= {}
Local nTotAdto		:= 0
Local lBaixaAbat	:= .F.
Local nVlrBaixa		:= 0
Local lBxCec		:= .F.
Local lBxLiq		:= .F.
Local x				:= 0
Local aImpPccIr		:= { SE5->E5_VRETPIS, SE5->E5_VRETCOF, SE5->E5_VRETCSL, SE5->E5_VRETIRF }
Local nSaldoNF		:= 0
Local nTotIrAbt		:= 0
Local nVlMinImp		:= GetNewPar("MV_VL10925",5000)
Local nTotCsAbt		:= 0
Local nTotPisAbt	:= 0
Local nTotCofAbt	:= 0
Local lAplVlMin		:= .T.
Local nValorPcc		:= 0
Local aCamposKey	:= {}
Local nValLim 		:= 0 //Limite de Compensacao
Local nImp          := 0 //Valor dos Imposto (proporcao)
Local nProp         := 0 //proporcao da baixa
Local nValVa		:= 0 //valor acessório

//--- Tratamento Gestao Corporativa
Local lGestao   	:= IIf( lFWCodFil, FWSizeFilial() > 2, .F. )	// Indica se usa Gestao Corporativa
//
Local cFilFwSE1 	:= IIf( lGestao, FwFilial("SE1") , xFilial("SE1") )
Local lSE1Exclusivo := .F.
Local nMoedaP		:= 1
Local nMoedaD		:= 1
Local nTaxaP		:= 0
Local nTaxaD		:= 0
Local cSep			:= IIf("|"$MV_CRNEG,"|",",")
Local lNcc			:= SE1->E1_TIPO $ MV_CRNEG 
Local lNcc2			:= .F.
//Impostos gerados pela rotina de Borderô de Recebimento de Imposto (FINA061).
Local nPisFina061	:= 0
Local nCofFina061	:= 0
Local nCslFina061	:= 0
Local nIrfFina061	:= 0     
Local nOrdSE5		:= 0
Local nRegSE5		:= 0
Local nOrdSE1		:=  0
Local aDadRetAux	:= {}
/* GESTAO - inicio */
Local nR			:= 0
Local cSE1Fil		:= ""
Local cTmpSE1Fil	:= ""
Local aTmpSE1Fil	:= {}
Local aAreaSIX		:= {}
Local aIndexPE		:= {}
Local lSE1Comp 		:= If(Empty(FWxFilial("SE1")), .T., .F.)
/* GESTAO - fim */
Local aPcc			:= Array(4)
Local nValRec2		:= 0
Local nNumAT1		:= 0
Local nNumAT2		:= 0
Local nNumAT3		:= 0
Local nNumAT4		:= 0

//PCREQ-3782 - Bloqueio por situação de cobrança
Local cLstCart 		:= FN022LSTCB(1,'0007')	//Lista das situacoes de cobranca (Carteira)
Local cLstNoBlq 	:= FN022LSTCB(6,'0007')	//Lista das situacoes de cobranca (Não bloqueadas para determinado processo)

Local cQuery   		:= ""
Local cAliasSA1		:= "SA1"
Local aStruQry 		:= {}
Local cUserKey		:= SE1->(IndexKey())
Local cSelect		:= " E1_FILIAL, E1_PREFIXO, E1_NUM, E1_PARCELA, E1_IRRF, E1_MOEDA, E1_TIPO, E1_SALDO, E1_EMISSAO AS E1_EMIS2, " 
Local cSelect		+= " E1_CLIENTE, E1_LOJA, E1_NOMCLI, E1_SDACRES, E1_SDDECRE, E1_HIST, E1_PIS, E1_COFINS, E1_CSLL, "
Local cSelect		+= " E1_TXMOEDA, E1_VLCRUZ, E1_BASEPIS, E1_BASECOF, E1_BASECSL, E1_VALOR, E1_FILORIG, E1_TXMDCOR, E1_VENCREA, E1_VEND1  "
Local lExclus       := NWF->(ColumnPos("NWF_EXCLUS")) > 0 .And. SuperGetMV("MV_JURXFIN",,.F.) // Integração SIGAPFS x SIGAFIN
Local lRaRtImpMR 	:= .F.
Local aImpMRBrw 	:= PegaVarMR()
Local lIrfBxAux 	:= lIrPjBxCr
Local lPccBxAux 	:= lPccBxCr
Local lRetMinAux 	:= .F.
Local nPosxRet		:= 0
Local nTaxaMov      := 0
Local dDtMov		:= dDataBase
Local oModelVA		:= Nil

Default lAutomato   := .F.

lPropRA 	:= SuperGetMv("MV_COMPCR",,.F.)                     //Verifica se vai proporcionalizar quando RA para NF.

If cPaisLoc == "RUS"
	cSelect += ",E1_F5QCODE,E1_CONUNI"
EndIf 
aCamposKey 	:= StrTokArr(cUserKey,"+")

cEmpAnt  	:= SM0->M0_CODIGO
lRaRtImpMR 	:= ( __lPccMR .And. __lRaRtPcc ) .Or. ( __lIrfMR .And. __lRaRtIrf ) .Or. ( __lIssMR .And. __lRaRtIss )
lPccBxCr 	:= ( __lPccMR .And. __lPccBxMR ) .Or. ( !__lPccMR .And. lPccBxCr )
lIrPjBxCr 	:= ( __lIrfMR .And. __lIrfBxMR ) .Or. ( !__lIrfMR .And. lIrPjBxCr )

aPcc[1]	:= .F.

If ValType(nPis) <> "N"
	nPis	:= 0
EndIf

If ValType(nCofins) <> "N"
	nCofins	:= 0
EndIf

If ValType(nCsll) <> "N"
	nCsll	:= 0
EndIf

If ValType(nIrrf) <> "N"
	nIrrf	:= 0
EndIf
	
//Se o SE1 não For Compartilhado entre todas as Empresas
If !lSE1Comp
	If lGestao
		If !Empty(cFilFwSE1)
			lSE1Exclusivo := .T.
	    EndIf
	Else
		If !Empty(xFilial("SE1"))
			lSE1Exclusivo := .T.
		EndIf
	EndIf
EndIf

aPcc[1]	:= .F.
If dDataBase >= dLastPcc
	nVlMinImp	:= 0
EndIf

If MV_PAR08 == 1 .Or. ( lRaRtImp .Or. lRaRtImpMR )
	nTotAbat := If(Type("nTotAbat") != "N",SumAbatRec( SE1->E1_PREFIXO,SE1->E1_NUM,SE1->E1_PARCELA,SE1->E1_MOEDA, "S"  ,dBaixa,,@nTotIrAbt,@nTotCsAbt,@nTotPisAbt,@nTotCofAbt,),nTotAbat)
Else
	nTotAbat :=If(Type("nTotAbat") != "N",0,nTotAbat)
EndIf
nValComp := If(Type("nValComp") != "N",0,nValComp)

For nX := 1 to Len(aCamposKey)
	If AT("Str(",Upper(aCamposKey[nX])) > 0
		aCamposKey[nX] := SubStr(aCamposKey[nX], AT("(",aCamposKey[nX])+1, AT(",",aCamposKey[nX])-AT("(",aCamposKey[nX])-1)
	ElseIf AT("(",aCamposKey[nX]) > 0 .Or. AT(")",aCamposKey[nX]) > 0 //Removo da String potenciais chamadas de funcao
		aCamposKey[nX] := SubStr(aCamposKey[nX], AT("(",aCamposKey[nX])+1, AT(")",aCamposKey[nX])-AT("(",aCamposKey[nX])-1)
	EndIf
	If !(aCamposKey[nX] $ cSelect)
		cSelect += ","+aCamposKey[nX]
	EndIf
Next

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Ponto de Entrada permite alterar o indice que sera aplicado no Markbrowse ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If ExistBlock("FA330ORD")
	nOrdSE1 := ExecBlock("FA330ORD",.F.,.F.)
	If ValType(nOrdSE1) == "N"
		aAreaSIX := SIX->(GetArea())
		If SIX->(DBSeek("SE1" + RetAsc(nOrdSE1,1,.T.))) 
			SE1->(DBSetOrder(nOrdSE1))
			aIndexPE := StrToKarr2(SE1->(IndexKey()),"+",.T.)
			If Len(aIndexPE) > 0
				For nX := 1 to Len(aIndexPE)
				
					nNumAT1	:= AT("Str(",Upper(aIndexPE[nX]))
					nNumAT2	:= AT("(",aIndexPE[nX])
					nNumAT3 := AT(",",aIndexPE[nX])
					nNumAT4	:= AT(")",aIndexPE[nX])
				
					If nNumAT1 > 0
						aIndexPE[nX] := SubStr(aIndexPE[nX], nNumAT2 + 1, nNumAT3 - nNumAT2 - 1)
					ElseIf nNumAT2 > 0 .Or. nNumAT3 > 0 
						aIndexPE[nX] := SubStr(aIndexPE[nX], nNumAT2 + 1, nNumAT4 - nNumAT2 - 1)
					EndIf
					If !(aIndexPE[nX] $ cSelect)
						cSelect += "," + aIndexPE[nX]
					EndIf
				Next nX
			Else
				If !l330Auto
					Help(" ",1, "FA330ORD",,STR0090,1,0) //"O retorno do Ponto de Entrada 'FA330ORD' esta incorreto. O indice do P.E. não será utilizado."
				EndIf
			EndIf
		Else
			If !l330Auto
				Help(" ",1, "FA330ORD",,STR0090,1,0) //"O retorno do Ponto de Entrada 'FA330ORD' esta incorreto. O indice do P.E. não será utilizado."
			EndIf
		EndIf
		FWRestArea(aAreaSIX)
	Else
		If !l330Auto
			Help(" ",1, "FA330ORD",,STR0090,1,0) //"O retorno do Ponto de Entrada 'FA330ORD' esta incorreto. O indice do P.E. não será utilizado."
		EndIf
	EndIf
EndIf

dBaixa := If (Type("dBaixa") != "D",dDataBase,dBaixa)

//Verificar ou nao o limite de 5000 para Pis cofins Csll
// 1 = Verifica o valor minimo de retencao
// 2 = Nao verifica o valor minimo de retencao
If SE1->E1_APLVLMN == "2"
	lAplVlMin := .F.
EndIf

cOrdemSE1 := SE1->(IndexKey())
SE1->(DBSetOrder(1))

If cOrigem == "COMPENSANCC"
	MV_PAR10 := 2
EndIf
If MV_PAR10 == 2
	cFilDe := cFilAnt
	cFilAte:= cFilAnt
Else
	cFilDe := MV_PAR11
	cFilAte:= MV_PAR12
EndIf

DBSelectArea("SX3")
DBSetOrder(2)

MsSeek("E1_SALDO")
aAdd(aStruQry,{"E1_SALDO",SX3->X3_TIPO,SX3->X3_TAMANHO,SX3->X3_DECIMAL})

MsSeek("E1_EMISSAO")
aAdd(aStruQry,{"E1_EMISSAO",SX3->X3_TIPO,SX3->X3_TAMANHO,SX3->X3_DECIMAL})

MsSeek("E1_MOEDA")
aAdd(aStruQry,{"E1_MOEDA",SX3->X3_TIPO,SX3->X3_TAMANHO,SX3->X3_DECIMAL})

DBSelectArea("SE1")
DBSetOrder(2)

cAliasSE1 := "QRYSE1"
cAliasSA1 := "QRYSE1"

cQuery := "SELECT DISTINCT " + cSelect + ","
cQuery += "SE1.R_E_C_N_O_ RECSE1, A1_CGC "

If lCredito
	cQuery += ", SEDBRW.ED_CALCIRF, SEDBRW.ED_CALCPIS, SEDBRW.ED_CALCCOF, SEDBRW.ED_CALCCSL FROM "
Else
	cQuery += "FROM "
EndIf

cQuery += RetSqlName("SE1") + " SE1 LEFT JOIN "
cQuery += RetSqlName("SA1") + " SA1 ON (SE1.E1_LOJA = SA1.A1_LOJA) AND (SE1.E1_CLIENTE = SA1.A1_COD) "

If lTitRAMex //Manejo de Anticipo - Mexico
	cQuery += " LEFT JOIN " + RetSqlName("SED") + " SED ON SE1.E1_NATUREZ = SED.ED_CODIGO "
EndIf

If lCredito
	cQuery += " LEFT JOIN " + RetSqlName("SED") + " SEDBRW ON SE1.E1_NATUREZ = SEDBRW.ED_CODIGO AND SEDBRW.ED_FILIAL = '" + xFilial("SED") + "' AND SEDBRW.D_E_L_E_T_ = ' ' "
EndIf

If lExclus // Integração SIGAPFS x SIGAFIN
	cQuery += " LEFT JOIN " + RetSqlName("NWF") + " NWF ON NWF.NWF_TITULO = SE1.E1_NUM AND SE1.E1_ORIGEM = 'JURA069' "
EndIf

cQuery += " WHERE "
If dDatabase >= dLastPcc .And. ( lRaRtImp  .Or. lRaRtImpMR ) .And. lRatFields .And. !(SE1->E1_TIPO $ MV_CRNEG) .And. lPccBxCr
	cQuery += "EXISTS "
	cQuery += "(select ED_CODIGO, ED_DESCRIC ,ED_CALCCSL , ED_CALCCOF, "
	cQuery += " ED_CALCPIS, ED_PERCCSL, ED_PERCCOF, ED_PERCPIS FROM "+RetSqlName("SED")+ " "
	cQuery += " WHERE ED_CALCCSL = 'S' AND ED_PERCCSL > 0 AND ED_CALCCOF = 'S' AND ED_PERCCOF > 0 "
	cQuery += " AND ED_CALCPIS = 'S' AND ED_PERCPIS > 0 AND D_E_L_E_T_ = ' ' ) AND "
EndIf

If _lMOMS68 
	cQuery += " SE1.E1_TIPO = 'NF' AND "
	If  !Empty(AllTrim(SE1->E1_VEND1))
		cQuery += " SE1.E1_VEND1 = '"+SE1->E1_VEND1+"' AND "
	EndIf
EndIf

/* GESTAO - inicio */
//Se o SE1 For Compartilhado entre todas as Empresas
If lSE1Comp
	cQuery += "SE1.E1_FILIAL = '" + FWxFilial("SE1") + "' AND "
Else
	If lSE1Exclusivo
		If !Empty(aSelFil)
			cQuery += "SE1.E1_FILIAL " + GetRngFil( aSelFil, "SE1", .T., @cTmpSE1Fil) + " AND "
			aAdd(aTmpSE1Fil,cTmpSE1Fil)
		Else
			If MV_PAR10 == 2
				cQuery += "SE1.E1_FILIAL = '" + xFilial("SE1") + "' AND "  
			Else 
				cQuery += "SE1.E1_FILIAL >= '" + cFilDe + "' AND SE1.E1_FILIAL <= '" + cFilAte + "' AND "  
			EndIf	
		EndIf
	Else
		If !Empty(aSelFil)
			For nR := 1 to Len(aSelFil)
				cSE1Fil += "'" + aSelFil[nR]
				If nR == Len(aSelFil)
					cSE1Fil += "'"
				Else
				 	cSE1Fil += "',"
				EndIf
			Next
			cQuery += "SE1.E1_FILORIG IN (" + cSE1Fil + ") AND "
		Else
			If MV_PAR10 == 2
				cQuery += "SE1.E1_FILORIG = '" + cFilAnt + "' AND "  
			Else
				cQuery += "SE1.E1_FILORIG >= '" + cFilDe + "' AND  SE1.E1_FILORIG <= '" + cFilAte  + "' AND "  
			EndIf 
		EndIf
	EndIf
EndIf
/* GESTAO - fim */

If MV_PAR02 == 1
	cQuery += "SE1.E1_CLIENTE = '"+cCliente+"' AND "
Else
	cQuery += "SE1.E1_CLIENTE >= '"+MV_PAR03+"' AND "
	cQuery += "SE1.E1_CLIENTE <= '"+MV_PAR04+"' AND "
EndIf
If MV_PAR01 == 1 .And. MV_PAR02 == 1
	cQuery += "SE1.E1_LOJA = '"+cLoja+"' AND "
EndIf

If ( lRaRtImp .Or. lRaRtImpMR ) .And. lRatFields .And. !(SE1->E1_TIPO $ MV_CRNEG)
	If !lCredito
		cQuery +="( ( "
	EndIf
	
	If lPccBxCr
		If !__lPccMR .Or. ( !__lPccMR .And. __lRaRtPcc )
			If lCredito
				cQuery += " SEDBRW.ED_CALCPIS = 'S' AND "
			Else
				If SE1->E1_PIS > 0
					cQuery += " E1_PIS > 0 AND "
				Else
					cQuery += " E1_PIS = 0 AND "
				EndIf
			EndIf
			If lCredito
				cQuery += " SEDBRW.ED_CALCCOF = 'S' AND "
			Else
				If SE1->E1_COFINS > 0
					cQuery += " E1_COFINS > 0 AND "
				Else
					cQuery += " E1_COFINS = 0 AND "
				EndIf
			EndIf
			If lCredito
				cQuery += " SEDBRW.ED_CALCCSL = 'S' AND "
			Else
				If SE1->E1_CSLL > 0
					cQuery += " E1_CSLL > 0 AND "
				Else
					cQuery += " E1_CSLL = 0 AND "
				EndIf
			EndIf
		EndIf
	EndIf
	
	If lIrPjBxCr
		If !__lIrfMR .Or. ( !__lIrfMR .And. __lRaRtIrf )
			If lCredito
				cQuery += " SEDBRW.ED_CALCIRF = 'S' AND "
			Else
				If SE1->E1_IRRF > 0
					cQuery += " ( E1_IRRF > 0 OR A1_RECIRRF = '1' ) AND "
				Else
					cQuery +=" E1_IRRF = 0 AND "
				EndIf
			EndIf
		EndIf
	EndIf
	
	If !lCredito .And. cPaisLoc == "BRA"
		If !__lIssMR .Or. ( !__lIssMR .And. __lRaRtIss )
			If SE1->E1_ISS>0
				cQuery += " E1_PRISS > 0 AND "
			Else
				cQuery += " E1_PRISS = 0 AND "
			EndIf
		EndIf
		If SE1->E1_INSS>0
			cQuery += " E1_PRINSS > 0 AND "
		Else
			cQuery += " E1_PRINSS = 0 AND "
		EndIf
	ElseIf cPaisLoc == "BRA"
		If !__lIssMR .Or. ( !__lIssMR .And. __lRaRtIss )
			If SE1->E1_PRISS>0
				cQuery += " E1_ISS > 0 AND "
			Else
				cQuery += " E1_ISS = 0 AND "
			EndIf
		EndIf
		If SE1->E1_PRINSS>0
			cQuery += " E1_INSS > 0 AND "
		Else
			cQuery += " E1_INSS = 0 AND "
		EndIf
	EndIf
	
	If !lCredito
		cQuery +=  " E1_TIPO IN "+ FormatIn(MVRECANT,",") + ") OR "
		cQuery +=  " E1_TIPO IN "+ FormatIn(MV_CRNEG,",") + ") AND "
	EndIf

EndIf

If MV_PAR05 == 2
	cQuery += "(SE1.E1_SITUACA IN "+FormatIn(cLstCart,"|")+" OR "
Else
	//PCREQ-3782 - Bloqueio por situação de cobrança
	cQuery += "(SE1.E1_SITUACA IN "+FormatIn(cLstNoBlq,'|')+" OR "
EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Caso titulos originados pelo SIGALOJA estejam nas carteiras :  ³
//³I = Carteira Caixa Loja                                        ³
//³J = Carteira Caixa Geral                                       ³
//³Nao permitir a selecao destes titulos                          ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
cQuery += "SE1.E1_SITUACA NOT IN ('I','J')) AND "


	If lCredito
		cQuery += "SE1.E1_TIPO NOT IN " + FormatIn( MV_CRNEG+cSep+MVRECANT+cSep+MVPROVIS,cSep) + " AND "
	Else
		If (cTipoTit $ MVRECANT .And. cTipoTit $ MV_CRNEG )
			cQuery += " (SE1.E1_TIPO NOT IN " + FormatIn(MVRECANT,",") + " OR  "
			cQuery += "SE1.E1_TIPO NOT IN " + FormatIn( MV_CRNEG,cSep) + ") AND "
		ElseIf !(cTipoTit $ MVRECANT) .And. !(cTipoTit $ MV_CRNEG )
			cQuery += " ( SE1.E1_TIPO IN " + FormatIn(MVRECANT,",") + " OR  "
			cQuery += "SE1.E1_TIPO IN " + FormatIn( MV_CRNEG,cSep) + ") AND "
		EndIf
	EndIf


cQuery += "SE1.E1_TIPO NOT IN " + FormatIn(MVABATIM,"|") + " AND "
cQuery += "SE1.E1_SALDO > 0 AND "

If _lMOMS68
	cQuery += "SE1.E1_EMISSAO <= '"+DToS(dDatabase)+ "' AND "
Else
	cQuery += "SE1.E1_EMISSAO >= '"+DToS(_dDtCompDe)+ "' AND "
	cQuery += "SE1.E1_EMISSAO <= '"+DToS(_dDtCompAte)+ "' AND "
EndIf

cQuery += "SE1.D_E_L_E_T_ = ' ' AND "

/* GESTAO - inicio */
If !Empty(aSelFil)
	cQuery += "SA1.A1_FILIAL " + GetRngFil( aSelFil, "SA1", .T., @cTmpSE1Fil) + " AND "
	aAdd(aTmpSE1Fil,cTmpSE1Fil)
Else
	cQuery += "SA1.A1_FILIAL = '"+ xFilial("SA1")+"' AND "
EndIf
/* GESTAO - fim */

cQuery += "SA1.D_E_L_E_T_ = ' ' "

If lTitRAMex //Manejo de Anticipo - Mexico. Tratamento para nao exibir titulo de RA provenientes de notas de adiantamento.

	/* GESTAO - inicio */
	If !Empty(aSelFil)
		cQuery += " AND SED.ED_FILIAL " + GetRngFil( aSelFil, "SED", .T., @cTmpSE1Fil)
		aAdd(aTmpSE1Fil,cTmpSE1Fil)
	Else
		cQuery += "	AND SED.ED_FILIAL = '" + xFilial("SED") + "'"
	EndIf
	/* GESTAO - fim */
	cQuery += " AND SED.D_E_L_E_T_	= '' "
	cQuery += "	AND SE1.E1_TIPO		<> '" + SubStr(MVRECANT,1,3) + "'" //"RA" no Mexico
	cQuery += "	AND SE1.E1_ORIGEM	<> 'FINA087A' AND "
	cQuery += " SE1.D_E_L_E_T_ = ' ' "
	cQuery += "	AND SED.ED_OPERADT	<> '1' AND " //Operacao de adiantamento igual a SIM
	cQuery += " SE1.E1_SALDO > 0 AND "
	cQuery += " SE1.D_E_L_E_T_ = ' ' AND "
	If MV_PAR02 == 2
   		cQuery += "SE1.E1_CLIENTE = '"+cCliente+"'"
	Else
   		cQuery += "SE1.E1_CLIENTE >= '"+MV_PAR03+"' AND "
   		cQuery += "SE1.E1_CLIENTE <= '"+MV_PAR04+"'"
	EndIf
EndIf

If lExclus // Integração SIGAPFS x SIGAFIN
	cQuery += " AND ((NWF.NWF_EXCLUS = '2' AND NWF.D_E_L_E_T_ = ' ') OR NWF.NWF_EXCLUS IS NULL) "
EndIf

If FindFunction('FINTP02')
	cQuery += FINTP02() // retornar o filtro de bloqueio do titulo do TIN  AND E1_ORIGEM <> 'FINI055'
EndIf

	cQuery += "ORDER BY " + SqlOrder(cOrdemSE1)


If lFa330Qry
	cQuery := Execblock("FA330QRY",.F.,.F.,{ cQuery }  )			// permite manipualção das query
EndIf

cQuery := ChangeQuery(cQuery)
dbUseArea(.T.,"TOPCONN",TCGENQRY(,,cQuery),cAliasSE1,.F.,.T.)

For nX := 1 To Len(aStruQry)
	If ( aStruQry[nX][2] <> "C" )
		TCSetField(cAliasSE1,aStruQry[nX][1],aStruQry[nX][2],aStruQry[nX][3],aStruQry[nX][4])
	EndIf
Next nX

bWhile := {|| (cAliasSE1)->(!Eof()) }

ProcRegua((cAliasSE1)->(RecCount()),STR0032 )

aTitulos := {}
aRecNo := {}

While .T.

	DBSelectArea(cAliasSE1)
	cFilAnt := IIf( lFWCodFil, FWGETCODFILIAL, SM0->M0_CODFIL )

	nIndVld:=IndexOrd()
	nRecVld:=SE1->(Recno())
	If __l330Va
		oModelVA	:= FWLoadModel("FINA070VA")
	EndIf
	While Eval(bWhile)

	   	IncProc()

		If !Empty((cAliasSE1)->E1_FILORIG)
			cFilAnt := (cAliasSE1)->E1_FILORIG
		Else
			cFilAnt := (cAliasSE1)->E1_FILIAL
		EndIf

		//PONTO DE ENTRADA F330RIO Tratamento de "filtragem" de titulos de adiantamento a serem
		//considerados ou nÆo no array dos adiantamentos a serem compen sados. Retorno l¢gico
		If lF330RIO
			If !(ExecBlock("F330RIO",.F.,.F.))
				DBSkip()
				Loop
			EndIf
		EndIf

		DBSelectArea("SE1")

		SE1->( DBSetOrder( 1 ) ) //E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
		SE1->( DBSeek( (cAliasSE1)->(E1_FILIAL) + (cAliasSE1)->(E1_PREFIXO + E1_NUM + E1_PARCELA + E1_TIPO) ) )
				
		DBSelectArea(cAliasSE1)

		//Na finalizacao do Lay-Away, seleciona somente os titulos gerados pela emissao do mesmo - Loc. EUA|POR
		If cOrigem == "LOJA800"
		   nPosNumLay  := aScan(aNumLay,AllTrim((cAliasSE1)->E1_NUM))
		   If nPosNumLay == 0 .And. Len(aNumLay) > 0
		       DBSkip()
			   Loop
		   EndIf
		EndIf

		//ANGOLA|BRASIL - Nao permitir compensar titulos de adiantamento relacionado a pedido
		If cPaisLoc $ "ANG|BRA"
			FIE->(DBSetOrder(2))
			If FIE->(MsSeek(xFilial("FIE")+"R"+(cAliasSE1)->(E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO)))
				(cAliasSE1)->(DBSkip())
				Loop
			EndIf
		EndIf

		//Situacao de cobranca que impede movimentacao
		If lCredito
			If !(F023VerBlq("1","0007",SE1->E1_SITUACA,.F.))
				(cAliasSE1)->(DBSkip())
				Loop
			EndIf
		EndIf
		
		//Verifica RA se tem movimento no SE5 para obter a data do movimento
		If (cAliasSE1)->E1_TIPO $ MVRECANT .And. (cAliasSE1)->E1_MOEDA > 1
			aMovRA := U_F23MovRA(Nil, cAliasSE1, .T.)
					
			If aMovRA[1]
				dDtMov	:= aMovRA[2]
			EndIf
		Else
			dDtMov := dDatabase
		EndIf
		
		//Motor de retenções
		If __lMotRet
			//Verifica as configurações de impostos pelo motor de retenção
			__lTCnfgMR := F330VldImp()
	
			lRaRtImpMR 	:= ( __lPccMR .And. __lRaRtPcc ) .Or. ( __lIrfMR .And. __lRaRtIrf ) .Or. ( __lIssMR .And. __lRaRtIss )
			lPccBxCr 	:= ( __lPccMR .And. __lPccBxMR ) .Or. ( !__lPccMR .And. lPccBxAux )
			lIrPjBxCr 	:= ( __lIrfMR .And. __lIrfBxMR ) .Or. ( !__lIrfMR .And. lIrfBxAux )
			
			//Calcula os impostos pelo motor de retenções
			If __lTCnfgMR
				F330CalImp( SE1->E1_NATUREZ, SE1->E1_CLIENTE, SE1->E1_LOJA, SE1->E1_FILORIG, SE1->E1_SALDO, dDataBase, SE1->E1_TIPO, .T. )
				__lTCnfgMR	:= .F.
			EndIf
		EndIf 
		
		nDesFin := 0
		// Desconto FINANCEIRO - Compensação
		If lCredito .And. lF330DESC
			lDESC := ExecBlock("F330DESC",.F.,.F.)
			If lDESC
				nDesFin:= IIf(SE1->E1_DESCFIN > 0 .And. SE1->E1_VENCREA-dBaixa >= SE1->E1_DIADESC .And. SE1->E1_DESCONT == 0,SE1->E1_VALOR * (SE1->E1_DESCFIN/100),0)
				nDescD := nDesFin
			EndIf	
		EndIf

		nVlBasico 	:= IIf (nValor = 0 , nSaldo , nValor)
		nValRec		:= IIf (nValor = 0 , nSaldo , nValor)
		nOldValRec	:= nSaldo
		lMarca		:=	.F.
		
		//VA: Calcula o valor acessório
		If __l330Va
			nValVa		:= FA330VACAL(oModelVA)
		EndIf

		//Definição da taxa do movimento
		If cPaisLoc == "BRA"
			//Cenários com taxa contratada
			If (cAliasSE1)->E1_MOEDA != 1 
				If !Empty((cAliasSE1)->E1_TXMOEDA)	// Verifica se existe taxa contratada
					If __lTxConP .And. __lCmTxCon	//Verifica se o título da partida possui taxa contratada e se gera variação
						nTaxaMov := __nTxMoedP
					Else
						If!Empty((cAliasSE1)->E1_TXMDCOR) .And. !__lCmTxCon 	//Se já sofreu variação(FINA350) e nao gera vairiação a taxa utilizada é a da variação
							nTaxaMov := (cAliasSE1)->E1_TXMDCOR
						Else
							nTaxaMov := U_Fa330Tx2((cAliasSE1)->E1_MOEDA,(cAliasSE1)->E1_TXMOEDA)
						EndIf
					EndIf
				Else
					nTaxaMov := RecMoeda(dDtMov, (cAliasSE1)->E1_MOEDA)   //obs moeda diferente de 1 sem taxa contratada está pegando a taxa do dia
				EndIf
					
			ElseIf __lTxConP 	//Verifica se o título da partida possui taxa contratada
				nTaxaMov := __nTxMoedP
			Else
				nTaxaMov := RecMoeda(dDtMov, nMoeda) //obs pegando por PadRão a taxa do dia do movimento
				//nTaxaMov := __nTxMoedP 
			EndIf
		EndIf

		If ( nVlBasico > nTotComp .Or. nTotComp == 0 )  .And. Fa330Lock(Nil, (cAliasSE1)->RECSE1, .F.) .And.  !((cAliasSE1)->E1_TIPO $ MV_CRNEG) 
	    	lMarca := .T.		// marca para vers„o WIN
			nValPre := IIf (nTotComp == 0 , nVlBasico, nVlBasico - nTotComp)
			If cPaisLoc == "BRA"				
				If (MV_PAR08 == 1 .Or. ( ( lRaRtImp .Or. lRaRtImpMR ) .And. !lNcc)) .And. !((cAliasSE1)->E1_TIPO $ MVRECANT+"/"+MV_CRNEG )
					nTotCsAbt	:= 0
					nTotPisAbt	:= 0
					nTotCofAbt	:= 0
					nTotIrAbt	:= 0
					nTotAbat := SumAbatRec((cAliasSE1)->E1_PREFIXO,(cAliasSE1)->E1_NUM,(cAliasSE1)->E1_PARCELA,(cAliasSE1)->E1_MOEDA,"S",dBaixa,,@nTotIrAbt,@nTotCsAbt,@nTotPisAbt,@nTotCofAbt)

					If lIrPjBxCr
                    	If lCredito .And. (cAliasSE1)->E1_IRRF > 0 .And. !lNcc
							If __lIrfMR
								nIrrf := __nIrfCaMR
							Else
								nIrrf := FCaIrBxCR(SE1->E1_SALDO)
			  				EndIf
			  				
			  				If (nPosIr := aScan( aImpIR, {|x| x[2] = SE1->(REcno())} ) ) = 0
				  		 		aAdd(aImpIR,{nIrrf,SE1->(Recno())})
				  		 		nPosIr := Len( aImpIR )
			   				Else
				  				aImpIR[nPosIr][1] := nIrrf
			   				EndIf
						EndIf
					EndIf
										
					//Se PCC Baixa CR e nao houver abatimento de impostos
					If cPaisLoc == "BRA" .And. ( lPccBxCR .And. ( !lRartimp .And. !lRaRtImpMR ) .And. ( nTotCsAbt + nTotPisAbt + nTotCofAbt == 0 ) ) .Or. ;
					( ( lRartimp .Or. lRaRtImpMR ) .And. (cAliasSE1)->(E1_PIS + E1_CSLL + E1_COFINS) == 0 )
						//Se PCC Baixa CR e a compensação partiu de um adiantamento
						//Os titulos nao serao pre-selecionados.
						//Isto se da para que a cada titulo marcado, seja realizado o cálculo do PCC
						lMarca := .F.
					EndIf
				Else					
					If lIrPjBxCr .And. !((cAliasSE1)->E1_TIPO $ MVRECANT+"/"+MV_CRNEG )
                    	If lCredito .And. (cAliasSE1)->E1_IRRF > 0
							If __lIrfMR
								nIrrf := __nIrfCaMR
							Else
								nIrrf := FCaIrBxCR(SE1->E1_SALDO) 
							EndIf
							
							If ( nPosIr := aScan( aImpIR, {|x| x[2]=SE1->(REcno())} ) ) = 0
					  			aAdd(aImpIR,{nIrrf,SE1->(Recno())})
					  			nPosIr := Len( aImpIR )
				   			Else
					  			aImpIR[nPosIr][1] := nIrrf
			   				EndIf
						EndIf
	     			Else
	     		   		nTotAbat := 0
					EndIf
				EndIf
								
				//Se PCC Baixa CR e nao houver abatimento de impostos
				If cPaisLoc == "BRA" .And. lPccBxCR .And. ( nTotCsAbt + nTotPisAbt + nTotCofAbt == 0 ) .And. ( !lRartimp .And. !lRaRtImpMR ) .And. lCredito
					//Se PCC Baixa CR e a compensação partiu de um adiantamento
					//Os titulos nao serao pre-selecionados.
					//Isto se da para que a cada titulo marcado, seja realizado o cálculo do PCC
					lMarca := .F.
				ElseIf lAutomato .And. !lCredito
					If TitNMarca(cAliasSE1)
						lMarca	:= .F.
					EndIf
				EndIf
								
				If dDataBase < dLastPcc
					If nPis <> E1_PIS .And. nCofins <> E1_COFINS .And. nCsll <> E1_CSLL .And. nIrrf <> E1_IRRF  // Garantir a integridade do valor dos impostos 
						nPis    := aImpPccIr[1]
						nCofins := aImpPccIr[2]
						nCsll   := aImpPccIr[3]
						nIrrf   := aImpPccIr[4]
					EndIf
				EndIf
				
				nValComp := 0
				
				If lMarca
					nValComp := IIf (nValPre > Round(NoRound(xMoeda((cAliasSE1)->E1_SALDO - nTotAbat +(cAliasSE1)->E1_SDACRES-(cAliasSE1)->E1_SDDECRE+nValVa,(cAliasSE1)->E1_MOEDA,nMoeda,,3,nTaxaMov,U_Fa330Tx2(nMoeda,nTxMoeda)),3),2) , ;
										xMoeda((cAliasSE1)->E1_SALDO - nTotAbat+(cAliasSE1)->E1_SDACRES-(cAliasSE1)->E1_SDDECRE+nValVa,(cAliasSE1)->E1_MOEDA,nMoeda,,5,nTaxaMov,U_Fa330Tx2(nMoeda,nTxMoeda)), nVlBasico-nTotComp)
				EndIf
			EndIf
			
			//PONTO DE ENTRADA F330CMP
			//Tratamento de valor a ser compensado em determinado titulo permitindo que o usuario possa calcular o valor do titulo NDF ou PA a ser compensado
			If lF330CMP
				nValComp:= ExecBlock("F330CMP",.F.,.F.)
			EndIf
			
			nTotComp += nValComp
		Else
			If lAutomato
				nValPre := IIf (nTotComp == 0 , nVlBasico, nVlBasico - nTotComp)
				nValComp := IIf (nValPre > Round(NoRound(xMoeda((cAliasSE1)->E1_SALDO - nTotAbat +(cAliasSE1)->E1_SDACRES-(cAliasSE1)->E1_SDDECRE+nValVa,(cAliasSE1)->E1_MOEDA,nMoeda,,3,U_Fa330Tx2((cAliasSE1)->E1_MOEDA,(cAliasSE1)->E1_TXMOEDA),U_Fa330Tx2(nMoeda,nTxMoeda)),3),2) , ;
							xMoeda((cAliasSE1)->E1_SALDO - nTotAbat+(cAliasSE1)->E1_SDACRES-(cAliasSE1)->E1_SDDECRE+nValVa,(cAliasSE1)->E1_MOEDA,nMoeda,,5,U_Fa330Tx2((cAliasSE1)->E1_MOEDA,(cAliasSE1)->E1_TXMOEDA),U_Fa330Tx2(nMoeda,nTxMoeda)),;
							nVlBasico-nTotComp)
			EndIf
			If cPaisLoc == "BRA"
				If (MV_PAR08 == 1 .Or. ( lRaRtImp .Or. lRaRtImpMR ) ) .And. !((cAliasSE1)->E1_TIPO $ MVRECANT+"/"+MV_CRNEG )
					nTotCsAbt	:= 0
					nTotPisAbt	:= 0
					nTotCofAbt	:= 0
					nTotIrAbt   := 0
					nTotAbat := SumAbatRec((cAliasSE1)->E1_PREFIXO,(cAliasSE1)->E1_NUM,(cAliasSE1)->E1_PARCELA,(cAliasSE1)->E1_MOEDA,"S",dBaixa,,@nTotIrAbt,@nTotCsAbt,@nTotPisAbt,@nTotCofAbt)
					If lNcc .And. ( lRaRtImp .Or. lRaRtImpMR ) .And. ((cAliasSE1)->E1_VALOR > (cAliasSE1)->E1_SALDO)
						aOldBaixaSE5 := aClone(aBaixaSE5)
						aBaixaSE5:= {}
						//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
						//³Soma a proporcionalização de iss e inss ao nValrec ³
						//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
						aBxSE5 := Sel070Baixa( "VL /V2 /BA /RA /CP /LJ /"+MV_CRNEG,(cAliasSE1)->E1_PREFIXO,(cAliasSE1)->E1_NUM,(cAliasSE1)->E1_PARCELA,;
					   							(cAliasSE1)->E1_TIPO,@nTotAdto,@lBaixaAbat,(cAliasSE1)->E1_CLIENTE,;
												(cAliasSE1)->E1_LOJA,@nVlrBaixa,,@lBxCEC,@lBxLiq,,.T.)
						For x := 1 To Len(aBaixaSE5)
					 		nTotAbat -= aBaixaSE5[x][32]+aBaixaSE5[x][33]
						Next
						aBaixaSE5 := aClone(aOldBaixaSE5)
					EndIf
				Else
					nTotAbat := 0
				EndIf
			EndIf
			If !lAutomato
				lMarca 		:= .F.		// desmarca para vers„o WIN
				nValComp 	:= 0
				nValPre 	:= nVlBasico
			EndIf
		EndIf
		nValLim := 0
				
		If cPaisLoc == "BRA"
			
			If (nMoeda != 1 .Or. ( (cAliasSE1)->E1_MOEDA > 0 .And. (cAliasSE1)->E1_MOEDA != 1 ) )
				//Se um dos títulos não possui taxa, pega a taxa de mov da contra partida 
				If __lNoTxMov
					__nTxMoedP := nTaxaMov 
				ElseIf Empty(nTaxaMov) 
					nTaxaMov := __nTxMoedP 
				EndIf
				
				//Não compensa títulos moedas estrang s/ taxa de moeda
				If __lNoTxMov .And. Empty(nTaxaMov+__nTxMoedP) 
					(cAliasSE1)->(DBSkip())
					Loop
				EndIf			
			EndIf
			
			// Moeda de Partida
			nMoedaP := (cAliasSE1)->E1_MOEDA
			nTaxaP	:= (cAliasSE1)->E1_TXMOEDA
			
			// Moeda de Destino
			nMoedaD := nMoeda		
			nTaxaD	:= nTxMoeda
			
			nVAlSld:= (cAliasSE1)->(E1_SALDO+E1_SDACRES-E1_SDDECRE) - nDesFin + nValVa
			nValSld := FA330Valor(nValSld, (cAliasSE1)->E1_MOEDA, nMoeda, dDataBase, nTaxaMov, .F.)
			
			If (lPccBxCr .Or. lIRPJBxCr) .And. ( lRaRtImp .Or. lRaRtImpMR ) .And. !lNcc

				If lCredito
					aAdd(aDadosRA1[2],(cAliasSE1)->RecSe1)
				Else
					aAdd(aDadosRA1[1],(cAliasSE1)->RecSe1)
				EndIf
				
				aAdd(aDadosRA1[9],lMarca)
								
				If dDatabase >= dLastPcc 
					If !__lPccMR
						If lRartImp .And. lCredito												
							aPcc := newMinPcc(dBaixa,SE1->E1_SALDO,SE1->E1_NATUREZ,"R",SE1->E1_CLIENTE+SE1->E1_LOJA)
						EndIf
					EndIf
				EndIf
			
				If lAutomato .And. TitNMarca(cAliasSE1)
					lMarca := .F.
				EndIf
				
				If F330RaRtIm(@aDadosRA1)
					If !lAutomato .Or. ( lAutomato .And. lMarca )					
						nValLim 	:= If(aDadosRA1[7][Len(aDadosRA1[7])]>nVlBasico,nVlBasico,aDadosRA1[7][Len(aDadosRA1[7])])
						nTotComp	-= nValComp
						If !(nTotComp + If(aDadosRA1[8][Len(aDadosRA1[8])]>nVlBasico,nVlBasico,aDadosRA1[8][Len(aDadosRA1[8])]) > nVlBasico) 
							nValComp 	:= If(aDadosRA1[8][Len(aDadosRA1[8])]>nVlBasico,nVlBasico,aDadosRA1[8][Len(aDadosRA1[8])])
						EndIf
						
						If MV_PAR08 == 2 .And. !lCredito .And. lRartImp
							nValComp:= IIf( SE1->E1_SALDO > nValLim, nValComp, SE1->E1_SALDO)
						EndIf 
						
						nTotComp	+= nValComp
					ElseIf lAutomato
						nTotComp	:= 0
					EndIf
				EndIf
								
				If dDatabase >= dLastPcc .And. ( lRartImp .Or. lRaRtImpMR ) .And. lCredito
					If aDadosRA1[7][Len(aDadosRA1[7])] < nVlBasico 
						If nValLim + nPis + nCofins + nCsll <> SE1->E1_SALDO //somente deve descontar os impostos quando o valor estiver bruto
							nValLim		:= nValLim - nPis - nCofins - nCsll
							nValComp	:= nValLim
						EndIf
					EndIf
				EndIf
													
				If nMoedaP <> nMoedaD
					nValLim	:= IIf(nSaldo>nVAlSld,nVAlSld,nSaldo) 					    
					nTotComp	-= nValComp
					nValComp 	:= nValLim
					nTotComp	+= nValComp
				EndIf

			Else
				
				If __lPccMR
					nPis 	:= __nPisCaMR
					nCofins := __nCofCaMR
					nCsll 	:= __nCslCaMR
					
					If !lCredito .Or. ( lCredito .And. MV_PAR08 == 1 )
						If nSaldo > ( nVAlSld - IIf( lPccBxCr, ( nPis + nCofins + nCsll), 0) - nTotAbat )
							nValLim := nVAlSld - IIf( lPccBxCr, ( nPis + nCofins + nCsll), 0) - nTotAbat
						Else
							nValLim := nSaldo - IIf( lPccBxCr, ( nPis + nCofins + nCsll), 0) - nTotAbat
						EndIf
					Else
						nValLim := SE1->E1_SALDO /*nSaldo*/ - nTotAbat
					EndIf
					If !lRaRtImpMR .And. lPccBxCr .And. (cAliasSE1)->E1_TIPO <> MVRECANT .And. nPis + nCofins + nCsll + nIrrf > 0 .And. SE1->E1_SALDO <> SE1->E1_VALOR
						nAbatRa := nTotAbat
						nSldNF := SE1->E1_SALDO
					EndIf
				Else				
					If ( !lRaRtImp .And. MV_PAR08 == 1 .And. lPccBxCr .And. SE1->E1_TIPO <> MVRECANT )
						If dDataBase < dLastPcc
							f070TotMes( dBaixa , .T. )
						EndIf
					EndIf
								
					If dDataBase < dLastPcc
			  			If !lRaRtImp .And. lPccBxCr .And. (cAliasSE1)->E1_TIPO <> MVRECANT .And. nPis+nCofins+nCsll+nIrrf > 0 .And. aDadosret[1] <= nVlMinImp 
			  				If nSldRa > SE1->E1_SALDO 
			  					nProp		:= (SE1->E1_SALDO) / SE1->E1_VALOR
			  				Else
			  					nProp		:= nSldRa/SE1->E1_VALOR
			  				EndIf
			  				If nProp <> 0
								nValPis		:= SE1->E1_PIS * nProp
								nValCofins	:= SE1->E1_COFINS * nProp
								nValCsll	:= SE1->E1_CSLL * nProp
								If (nSldRa >= SE1->E1_SALDO .And. aDadosRet[1]+SE1->E1_SALDO > nVlMinImp) .Or. (nSldRa <= SE1->E1_SALDO .And. aDadosRet[1]+nSldRa > nVlMinImp)  
									nPis		:= aDadosRet[2] + nValPis 
									nCofins		:= aDadosRet[3] + nValCofins
									nCsll		:= aDadosRet[4] + nValCsll
								Else
									nPis		:= nValPis 
									nCofins		:= nValCofins
									nCsll		:= nValCsll
								EndIf
							EndIf 	
							nValLim 	:= IIf( nSaldo > (nVAlSld - nPis - nCofins - nCsll - nTotAbat), (nVAlSld - nPis - nCofins - nCsll - nTotAbat) , IIf (aDadosRet[1]+nSaldo <= nVlMinImp, nSaldo, (nSaldo - nPis - nCofins - nCsll - nTotAbat)) )
						ElseIf !lRaRtImp .And. lPccBxCr .And. (cAliasSE1)->E1_TIPO <> MVRECANT .And. nPis+nCofins+nCsll+nIrrf > 0 .And. aDadosret[1] > nVlMinImp .And. SE1->E1_SALDO <> SE1->E1_VALOR
							nValPis		:= nPis
							nValCofins	:= nCofins
							nValCsll	:= nCsll
							nPis		:= (nValPis * (SE1->E1_SALDO/ SE1->E1_VALOR))
							nCofins		:= (nValCofins * (SE1->E1_SALDO/ SE1->E1_VALOR))
							nCsll		:= (nValCsll * (SE1->E1_SALDO/ SE1->E1_VALOR))	
							nValLim 	:= IIf( nSaldo > (nVAlSld -nPis - nCofins - nCsll-nTotAbat) , (nVAlSld - nPis - nCofins - nCsll - nTotAbat) , (nSaldo - nPis - nCofins - nCsll - nTotAbat) )
							nAbatRa		:= nTotAbat
							nSldNF		:= SE1->E1_SALDO
						ElseIf !lRaRtImp .Or. (lRaRtImp .And. (cAliasSE1)->(E1_PIS + E1_CSLL + E1_COFINS) == 0)
							If nValComp > 0 .And. (nSaldo <> nValComp)
								nPis	:= aDadosRet[2] + ((nValComp * nValPis)/nValorNf) 
								nCofins	:= aDadosRet[3] + ((nValComp * nValCofins)/nValorNf)
								nCsll	:= aDadosRet[4] + ((nValComp * nValCsll)/nValorNf)
			  					nValLim := IIf(!lRartImp,Max(nVAlSld , nValComp),IIf( nValComp > nVAlSld , nVAlSld , nValComp ))
			  				Else
			  					If nValPis > 0 .And. aDadosret[1] <= nVlMinImp .And. aDadosRet[1]+nValComp <= nVlMinImp
			  						nPis	:= nValPis
			  						nCofins	:= nValCofins
			  						nCsll	:= nValCsll
			  					EndIf
			  					If lCredito
			  						nAbatNf	:= nTotAbat
			  					EndIf
			  					nValLim := IIf( nSaldo > nVAlSld , nVAlSld , nSaldo )
			  				EndIf
			  			EndIf
			  		Else
		  				If lCredito .And. MV_PAR08 == 2 .And. !lRartImp .And. nValSld+nPis+nCofins+nCsll <= SE1->E1_SALDO
		  					nValSld	+= nPis+nCofins+nCsll
		  				EndIf
		  				nValRec2 := IIf(nValRec < SE1->E1_SALDO,nValRec,SE1->E1_SALDO)
		  				If !(!lCredito .And. !lRartImp)
		  					aPcc		:= newMinPcc(dBaixa,nValRec2,SE1->E1_NATUREZ,"R",SE1->E1_CLIENTE+SE1->E1_LOJA)
			  				nPis		:= aPcc[2]
							nCofins		:= aPcc[3]
							nCsll		:= aPcc[4]
							nPisCalc	:= nPis
							nPisBaseC	:= nValRec2	
							nPisBaseR 	:= nValRec2
							nCofCalc	:= nCofins	
							nCofBaseC	:= nValRec2
							nCofBaseR 	:= nValRec2
							nCslCalc	:= nCsll	
							nCslBaseC	:= nValRec2
							nCslBaseR 	:= nValRec2
					
							If !lIrPjBxCr
								nIrrf	:= SE1->E1_IRRF
							ElseIf !__lIrfMR  
								nIrrf 	:= FCaIrBxCR(nValRec2)
							EndIf
		  				EndIf
		  				nValLim := IIf(nSaldo>nVAlSld,nVAlSld,nSaldo)
			  		EndIf
		  				  		
		  			If SE1->E1_TIPO <> MVRECANT .And. nValLim > SE1->E1_SALDO - nTotAbat .And. MV_PAR08 == 1
					    // Só faz a subtração do nValLim se o mesmo não ficar negativo
						If nValLim - nTotAbat >= 0
							nValLim -= nTotAbat
							If ( SE1->E1_SALDO - nTotAbat - IIf(lPccBxCr,nPis + nCofins + nCsll, 0 ) ) > nValLim
								nValLim := ( SE1->E1_SALDO - nTotAbat )
							EndIf
						// Se não subtrair o valor em nTotBat, verifica se o saldo atual do titulo esta inferior ao nValLim
						ElseIf ( SE1->E1_SALDO - nTotAbat ) < nValLim
							nValLim := ( SE1->E1_SALDO - nTotAbat )
						EndIf
	
						If !lRaRtImp
							If !aPcc[1]
								If ValType( aDadosRet ) == "A" 
									aDadRetAux := aClone( aDadosRet )
								EndIf
	
								f070TotMes( dBaixa , .T. )
								//Retorna os valores originais
								aDadosRet  := aClone( aDadRetAux )
			
								nPis       := aImpPccIr[1]
								nCofins    := aImpPccIr[2]
								nCsll      := aImpPccIr[3]
								nIrrf      := aImpPccIr[4]
													
								aDadRetAux := {}
							EndIf
	
						EndIf
					
					EndIf
			
				EndIf

			EndIf

			//Verifica se o titulo já possui impostos gerados pela rotina de Borderô de Recebimento de Imposto (FINA061).
			nPisFina061	:=	0
			nCofFina061	:=	0
			nCslFina061	:=	0
			nIrfFina061	:=	0
			nRegSE5		:=	SE5->(Recno())
			nOrdSE5		:=	SE5->(IndexOrd())		
			If lPccBxCr .Or. lIrPjBxCr                                                                                               			
				DBSelectArea("SE5")
				SE5->(DBSetOrder(2)) //FILIAL + TIPODOC + PREFIXO + NUMERO + PARCELA + TIPO
				If SE5->(DBSeek(xFilial("SE5")+"BA"+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+SE1->E1_TIPO))
					While !SE5->(Eof()) .And. SE5->E5_FILIAL==xFilial("SE5") .And. ;
						SE5->E5_TIPODOC+SE5->E5_PREFIXO+SE5->E5_NUMERO+SE5->E5_PARCELA+SE5->E5_TIPO=="BA"+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+SE1->E1_TIPO		
				
						If ("FINA061" $ Subst(SE5->E5_HISTOR,1,7)) .And. SE5->E5_MOTBX $ "PCC_IRF"						
							If AllTrim(SE5->E5_MOTBX) == "PCC"
							   nPisFina061	+= SE5->E5_VRETPIS
							   nCofFina061	+=	SE5->E5_VRETCOF
							   nCslFina061	+= SE5->E5_VRETCSL
							ElseIf AllTrim(SE5->E5_MOTBX) == "IRF"
							   nIrfFina061	+= SE5->E5_VRETIRF
							EndIf
						EndIf					
						SE5->(DBSkip())		
			   		EndDo
				EndIf
			EndIf
	   		SE5->(DBGoTo(nRegSE5))
			SE5->(DBSetOrder(nOrdSE5))													                  

			If ( nPisFina061 + nCofFina061 + nCslFina061 + nIrfFina061 ) > 0
				//Caso o titulo possua bordero de recebimento de imposto gerado na rotina FINA061 devo recompor base no caso de não abater os impostos
				//ou  abater os impostos e tiver compensando de RA para NF. Senão devo zerar as variaveis para não afetar o processamento. 
			  	If  MV_PAR08 == 1 
					nPisFina061	:=	0
					nCofFina061	:=	0
					nCslFina061	:=	0
					nIrfFina061	:=	0
				EndIf		
			EndIf					
			lNcc2 := (cAliasSE1)->E1_TIPO $ MV_CRNEG
      		
      		If ( lRaRtImp .Or. lRaRtImpMR ) .And. lPccBxCr .And. !lNcc .And. lCredito
               	nSaldoNF := (cAliasSE1)->E1_SALDO - aDadosRA1[3][Len(aDadosRA1[3])] - aDadosRA1[4][Len(aDadosRA1[4])] - aDadosRA1[5][Len(aDadosRA1[5])]
            Else
               	nSaldoNF := (cAliasSE1)->E1_SALDO
            EndIf
	        
			If MV_PAR02 == 2 // Considera Cliente == Não
				DBSelectArea("SA1")
				nIndexSA1 := IndexOrd()
				nPosSA1   := Recno()
				DBSetOrder(1)
				DBSeek(xFilial("SA1")+(cAliasSE1)->E1_CLIENTE+(cAliasSE1)->E1_LOJA)
				DBSelectArea(cAliasSE1)
				If lF330DESC
					lDESC := ExecBlock("F330DESC",.F.,.F.)
					If lDESC
						nDesFin:= IIf(SE1->E1_DESCFIN > 0 .And. SE1->E1_VENCREA-dBaixa >= SE1->E1_DIADESC .And. SE1->E1_DESCONT == 0,SE1->E1_VALOR * (SE1->E1_DESCFIN/100),0)
					EndIf
				EndIf
				
				If __lMotRet				
					aAdd(aTitulos,{;
					(cAliasSE1)->E1_PREFIXO,;  //1
					(cAliasSE1)->E1_NUM,;      //2
					(cAliasSE1)->E1_PARCELA,;  //3 
					(cAliasSE1)->E1_TIPO,;     //4
					(cAliasSE1)->E1_LOJA,;     //5
					Transform(xMoeda((nSaldoNF+ nPisFina061+nCofFina061+nCslFina061+nIrfFina06)+(cAliasSE1)->E1_SDACRES-IIf(nProp>0,(nImp*nProp),0)-(cAliasSE1)->E1_SDDECRE- IIf(  Type("nTotAbat") <> "N" .Or. MV_PAR08== 2 ,0,nTotAbat) - nDesFin + nValVa,(cAliasSE1)->E1_MOEDA,nMoeda,,5,U_Fa330Tx2(nMoedaP,nTaxaP),U_Fa330Tx2(nMoedaD,nTaxaD)),"@E 9999,999,999.99"),; //06
					Transform(nValComp + nPisFina061+nCofFina061+nCslFina061+nIrfFina061, "@E 9999,999,999.99"),; //07
					lMarca,; //8
					nValComp + nPisFina061+nCofFina061+nCslFina061+nIrfFina061,; //09
					(cAliasSE1)->(E1_CLIENTE)+"-"+(cAliasSE1)->(E1_LOJA),; //10
					(cAliasSE1)->E1_NOMCLI,;//11
					Transform(SA1->A1_CGC,SubStr(PicPes(SA1->A1_PESSOA),1,at("%",PicPes(SA1->A1_PESSOA))-1)),; //12
					Transform(xMoeda((cAliasSE1)->E1_SDACRES,(cAliasSE1)->E1_MOEDA,nMoeda,,5,U_Fa330TxMd((cAliasSE1)->E1_MOEDA,(cAliasSE1)->E1_TXMOEDA),U_Fa330Tx2(nMoeda,nTxMoeda)),"@E 9999,999,999.99"),; //13
					Transform(xMoeda((cAliasSE1)->E1_SDDECRE,(cAliasSE1)->E1_MOEDA,nMoeda,,5,U_Fa330TxMd((cAliasSE1)->E1_MOEDA,(cAliasSE1)->E1_TXMOEDA),U_Fa330Tx2(nMoeda,nTxMoeda)),"@E 9999,999,999.99"),; //14
					(cAliasSE1)->E1_HIST,; //15
					(cAliasSE1)->E1_FILIAL,; //16
					Transform(nValorPcc,"@E 9999,999,999.99"),; //17
					Transform(nValorPcc,"@E 9999,999,999.99"),; //18
					Transform(nValorPcc,"@E 9999,999,999.99"),; //19
					Transform(nValorPcc,"@E 9999,999,999.99"),; //20
					Transform(nValorPcc,"@E 9999,999,999.99"),; //21
					Transform(nValorPcc,"@E 9999,999,999.99"),; //22
					(cAliasSE1)->RECSE1,; //23
					(cAliasSE1)->E1_SALDO + nPisFina061 + nCofFina061 + nCslFina061 + nIrfFina061,; //24
					Transform(nValLim,"@E 9999,999,999.99"),; //25
					(cAliasSE1)->E1_VALOR,; //26
					Transform(nValorPcc,"@E 9999,999,999.99"),;//27 base calculo PCC
					Transform(nValorPcc,"@E 9999,999,999.99"),;//28 Base Retenção PCC
					Transform(nValorPcc,"@E 9999,999,999.99"),;//29 Base de calculo e retenção do IRF
					Transform(nValorPcc,"@E 9999,999,999.99"),; //30 Motor
					Transform(nValVa,"@E 9999,999,999.99"),;	//31 Valor acessório	
					nTaxaMov,;//32 Taxa do título
					DToC(SToD((cAliasSE1)->E1_VENCREA)),; // 33  Venc real
					(cAliasSE1)->E1_VEND1,; // 34 Vendedor
					Posicione("SA3",1,xFilial("SA3")+(cAliasSE1)->E1_VEND1,"A3_NOME"),;  // 35 Nome
					DToC(SToD((cAliasSE1)->E1_EMIS2)) }) 
					__nPosVrTit := 26
					__nPosRecn  := 23
				Else
				aAdd(aTitulos,{;
					(cAliasSE1)->E1_PREFIXO,;
					(cAliasSE1)->E1_NUM,;
					(cAliasSE1)->E1_PARCELA,;
					(cAliasSE1)->E1_TIPO,;
					(cAliasSE1)->E1_LOJA,;
					Transform(xMoeda((nSaldoNF+ nPisFina061+nCofFina061+nCslFina061+nIrfFina06)+(cAliasSE1)->E1_SDACRES-IIf(nProp>0,(nImp*nProp),0)-(cAliasSE1)->E1_SDDECRE- IIf(  Type("nTotAbat") <> "N" .Or. MV_PAR08== 2 ,0,nTotAbat) - nDesFin + nValVa,(cAliasSE1)->E1_MOEDA,nMoeda,,5,U_Fa330Tx2(nMoedaP,nTaxaP),U_Fa330Tx2(nMoedaD,nTaxaD)),"@E 9999,999,999.99"),; //06
					Transform(nValComp + nPisFina061+nCofFina061+nCslFina061+nIrfFina061, "@E 9999,999,999.99"),; //07
					lMarca,;
					nValComp + nPisFina061+nCofFina061+nCslFina061+nIrfFina061,; //09
					(cAliasSE1)->(E1_CLIENTE)+"-"+(cAliasSE1)->(E1_LOJA),;
					(cAliasSE1)->E1_NOMCLI,;
					Transform(SA1->A1_CGC,SubStr(PicPes(SA1->A1_PESSOA),1,at("%",PicPes(SA1->A1_PESSOA))-1)),;
					Transform(xMoeda((cAliasSE1)->E1_SDACRES,(cAliasSE1)->E1_MOEDA,nMoeda,,5,U_Fa330TxMd((cAliasSE1)->E1_MOEDA,(cAliasSE1)->E1_TXMOEDA),U_Fa330Tx2(nMoeda,nTxMoeda)),"@E 9999,999,999.99"),;
					Transform(xMoeda((cAliasSE1)->E1_SDDECRE,(cAliasSE1)->E1_MOEDA,nMoeda,,5,U_Fa330TxMd((cAliasSE1)->E1_MOEDA,(cAliasSE1)->E1_TXMOEDA),U_Fa330Tx2(nMoeda,nTxMoeda)),"@E 9999,999,999.99"),;
					(cAliasSE1)->E1_HIST,;
					(cAliasSE1)->E1_FILIAL,;//16
					Transform(nValorPcc,"@E 9999,999,999.99"),;
					Transform(nValorPcc,"@E 9999,999,999.99"),;
					Transform(nValorPcc,"@E 9999,999,999.99"),;
					Transform(nValorPcc,"@E 9999,999,999.99"),;
					Transform(nValorPcc,"@E 9999,999,999.99"),;
					Transform(nValorPcc,"@E 9999,999,999.99"),;
					(cAliasSE1)->RECSE1,;
					(cAliasSE1)->E1_SALDO + nPisFina061 + nCofFina061 + nCslFina061 + nIrfFina061,; 
					Transform(nValLim,"@E 9999,999,999.99"),;
					(cAliasSE1)->E1_VALOR,; //26
					Transform(nValorPcc,"@E 9999,999,999.99"),;//27 base calculo PCC
					Transform(nValorPcc,"@E 9999,999,999.99"),;//28 Base Retenção PCC
					Transform(nValorPcc,"@E 9999,999,999.99"),;//29 Base de calculo e retenção do IRF
					Transform(nValVa,"@E 9999,999,999.99"),;//30 Valor acessório	
					nTaxaMov,;//31 Taxa do título
					DToC(SToD((cAliasSE1)->E1_VENCREA)),; // 32  Venc real
					(cAliasSE1)->E1_VEND1,; // 33 Vendedor
					Posicione("SA3",1,xFilial("SA3")+(cAliasSE1)->E1_VEND1,"A3_NOME"),;
					DToC(SToD((cAliasSE1)->E1_EMIS2)) })   
					__nPosVrTit := 26
					__nPosRecn := 23
				EndIf

				nLin := Len(aTitulos)
				nPosxRet := 30
				nReg330 := 23 // Posição 23 do aTitulos				 
				If ( lRaRtImp .Or. lRaRtImpMR ) .And. ( lPccBxCr .Or. lIRPJBxCr ) .And. !lNcc
					lRetMinAux := ( ( !__lPccMR .And. (aDadosRet[1] > nVlMinImp) .Or. ((cAliasSE1)->E1_PIS > 0 .Or. (cAliasSE1)->E1_COFINS  > 0 .Or. (cAliasSE1)->E1_CSLL > 0 .Or. (cAliasSE1)->E1_IRRF > 0) ) .Or. ( __lPccMR .And. __nPisCaMR + __nCofCaMR + __nCslCaMR > 0 ) )
					If lRetMinAux
   						aTitulos[nLin][nPosPis]:= Transform(aDadosRA1[3][nLin]   ,X3Picture("E1_PIS"))
						aTitulos[nLin][nPosCof]:= Transform(aDadosRA1[4][nLin]   ,X3Picture("E1_COFINS"))
						aTitulos[nLin][nPosCsl]:= Transform(aDadosRA1[5][nLin]   ,X3Picture("E1_CSLL"))
						aTitulos[nLin][nPosIrf]:= Transform(aDadosRA1[6][nLin]   ,X3Picture("E1_IRRF"))
						If __lMotRet .And. !Empty(aDadosRA1[12])
							aTitulos[nLin][nPosxRet]:= Transform(aDadosRA1[12][nLin]   ,X3Picture("E1_IRRF"))
						EndIf
					EndIf
					aTitulos[nLin][nPosBPCC]:= Transform(aDadosRA1[7][nLin]   ,X3Picture("E1_VALOR"))
					aTitulos[nLin][nPosBPCR]:= Transform(aDadosRA1[8][nLin]   ,X3Picture("E1_VALOR"))
					
					If Type("oTitulo") == "O"
						oTitulo:aArray:=aTitulos
  						oTitulo:Refresh()
					EndIf
				EndIf

				SA1->(DBSetOrder(nIndexSA1))
				SA1->(DBGoTo(nPosSA1))
				
			Else	// MV_PAR02 <> 2 // Considera Cliente == Sim
				nPosxRet	:= 27

				If __lMotRet
			    	aAdd(aTitulos,{(cAliasSE1)->E1_PREFIXO,;		//01
					(cAliasSE1)->E1_NUM,;						//02
					(cAliasSE1)->E1_PARCELA,;					//03
					(cAliasSE1)->E1_TIPO,;						//04
					(cAliasSE1)->E1_LOJA,;						//05
					Transform(xMoeda(nSaldoNF+(cAliasSE1)->E1_SDACRES-IIf(nProp>0,(nImp*nProp),0)-(cAliasSE1)->E1_SDDECRE- IIf(  Type("nTotAbat") <> "N" .Or. MV_PAR08== 2,0,nTotAbat) - nDesFin + nValVa,(cAliasSE1)->E1_MOEDA,nMoeda,,5,U_Fa330Tx2(nMoedaP,nTaxaP),U_Fa330Tx2(nMoedaD,nTaxaD)),"@E 9999,999,999.99"),; //06
					Transform(nValComp,"@E 9999,999,999.99"),;//07
					lMarca,;										//08
					nValComp + nPisFina061+nCofFina061+nCslFina061+nIrfFina061,;										//09
					Transform(xMoeda((cAliasSE1)->E1_SDACRES,(cAliasSE1)->E1_MOEDA,nMoeda,,5,U_Fa330Tx2((cAliasSE1)->E1_MOEDA,(cAliasSE1)->E1_TXMOEDA),U_Fa330Tx2(nMoeda,nTxMoeda)),"@E 9999,999,999.99"),; //10
					Transform(xMoeda((cAliasSE1)->E1_SDDECRE,(cAliasSE1)->E1_MOEDA,nMoeda,,5,U_Fa330Tx2((cAliasSE1)->E1_MOEDA,(cAliasSE1)->E1_TXMOEDA),U_Fa330Tx2(nMoeda,nTxMoeda)),"@E 9999,999,999.99"),; //11
					(cAliasSE1)->E1_HIST,;						//12
					(cAliasSE1)->E1_FILIAL,;						//13
					Transform(nValorPcc,"@E 9999,999,999.99"),;//PCC Baixa CR - Pis 		//14	
					Transform(nValorPcc,"@E 9999,999,999.99"),;//PCC Baixa CR - Cofins	 	//15
					Transform(nValorPcc,"@E 9999,999,999.99"),;//PCC Baixa CR - Csll		//16
					Transform(nValorPcc,"@E 9999,999,999.99"),;//PCC Baixa CR - Irrf		//17	
					Transform(nValorPcc,"@E 9999,999,999.99"),;								//18
					Transform(nValorPcc,"@E 9999,999,999.99"),;								//19
					(cAliasSE1)->RECSE1,;													//20
					(cAliasSE1)->E1_SALDO + nPisFina061+nCofFina061+nCslFina061+nIrfFina061,;														//21
					Transform(nValLim  + nPisFina061+nCofFina061+nCslFina061+nIrfFina061,"@E 9999,999,999.99"),;//Limite de Compensacao  //22
					(cAliasSE1)->E1_VALOR,;//23
					Transform(nValorPcc,"@E 9999,999,999.99"),;//24 base calculo PCC
					Transform(nValorPcc,"@E 9999,999,999.99"),;//25 Base Retenção PCC
					Transform(nValorPcc,"@E 9999,999,999.99"),;//26 Base de calculo e retenção do IRF
					Transform(nValorPcc,"@E 9999,999,999.99"),; //27 PCC Baixa CR - Irrf		//18
					Transform(nValVa,"@E 9999,999,999.99"),;//28 Valor acessório	
					nTaxaMov,;//29 Taxa do título
					DToC(SToD((cAliasSE1)->E1_VENCREA)),; // 30  Venc real
					(cAliasSE1)->E1_VEND1,; // 31 Vendedor
					Posicione("SA3",1,xFilial("SA3")+(cAliasSE1)->E1_VEND1,"A3_NOME"),; // 32 Nome
					DToC(SToD((cAliasSE1)->E1_EMIS2)) })  //33 Emissão

					__nPosVrTit := 23
					__nPosRecn := 20
				Else
				aAdd(aTitulos,{(cAliasSE1)->E1_PREFIXO,;		//01
					(cAliasSE1)->E1_NUM,;						//02
					(cAliasSE1)->E1_PARCELA,;					//03
					(cAliasSE1)->E1_TIPO,;						//04
					(cAliasSE1)->E1_LOJA,;						//05
					Transform(xMoeda(nSaldoNF+(cAliasSE1)->E1_SDACRES-IIf(nProp>0,(nImp*nProp),0)-(cAliasSE1)->E1_SDDECRE- IIf(  Type("nTotAbat") <> "N" .Or. MV_PAR08== 2,0,nTotAbat) - nDesFin + nValVa,(cAliasSE1)->E1_MOEDA,nMoeda,,5,U_Fa330Tx2(nMoedaP,nTaxaP),U_Fa330Tx2(nMoedaD,nTaxaD)),"@E 9999,999,999.99"),; //06
					Transform(nValComp,"@E 9999,999,999.99"),;//07
					lMarca,;										//08
					nValComp + nPisFina061+nCofFina061+nCslFina061+nIrfFina061,;										//09
					Transform(xMoeda((cAliasSE1)->E1_SDACRES,(cAliasSE1)->E1_MOEDA,nMoeda,,5,U_Fa330Tx2((cAliasSE1)->E1_MOEDA,(cAliasSE1)->E1_TXMOEDA),U_Fa330Tx2(nMoeda,nTxMoeda)),"@E 9999,999,999.99"),; //10
					Transform(xMoeda((cAliasSE1)->E1_SDDECRE,(cAliasSE1)->E1_MOEDA,nMoeda,,5,U_Fa330Tx2((cAliasSE1)->E1_MOEDA,(cAliasSE1)->E1_TXMOEDA),U_Fa330Tx2(nMoeda,nTxMoeda)),"@E 9999,999,999.99"),; //11
					(cAliasSE1)->E1_HIST,;						//12
					(cAliasSE1)->E1_FILIAL,;						//13
					Transform(nValorPcc,"@E 9999,999,999.99"),;//PCC Baixa CR - Pis 		//14	
					Transform(nValorPcc,"@E 9999,999,999.99"),;//PCC Baixa CR - Cofins	 	//15
					Transform(nValorPcc,"@E 9999,999,999.99"),;//PCC Baixa CR - Csll		//16
					Transform(nValorPcc,"@E 9999,999,999.99"),;//PCC Baixa CR - Irrf		//17	
					Transform(nValorPcc,"@E 9999,999,999.99"),;								//18
					Transform(nValorPcc,"@E 9999,999,999.99"),;								//19
					(cAliasSE1)->RECSE1,;													//20
					(cAliasSE1)->E1_SALDO + nPisFina061+nCofFina061+nCslFina061+nIrfFina061,;														//21
					Transform(nValLim  + nPisFina061+nCofFina061+nCslFina061+nIrfFina061,"@E 9999,999,999.99"),;//Limite de Compensacao  //22
					(cAliasSE1)->E1_VALOR,;//23
					Transform(nValorPcc,"@E 9999,999,999.99"),;//24 base calculo PCC
					Transform(nValorPcc,"@E 9999,999,999.99"),;//25 Base Retenção PCC
					Transform(nValorPcc,"@E 9999,999,999.99"),;//26 Base de calculo e retenção do IRF
					Transform(nValVa,"@E 9999,999,999.99"),; //27 Valor acessório
					nTaxaMov,;//28 Taxa do título
					DToC(SToD((cAliasSE1)->E1_VENCREA)),; // 29  Venc real
					(cAliasSE1)->E1_VEND1,; // 30 Vendedor
					Posicione("SA3",1,xFilial("SA3")+(cAliasSE1)->E1_VEND1,"A3_NOME"),; //32 Nome
					DToC(SToD((cAliasSE1)->E1_EMIS2)) })  //33 Emissão 

					__nPosVrTit := 23
					__nPosRecn := 20
				EndIf

				nlin := Len(aTitulos)
				nReg330 := 20 // Posição 20 do aTitulos				
				If ( lRaRtImp .Or. lRaRtImpMR ) .And. (lPccBxCr .Or. lIRPJBxCr) .And. !lNcc .And. ((cAliasSE1)->E1_PIS > 0 .Or. (cAliasSE1)->E1_COFINS  > 0 .Or. (cAliasSE1)->E1_CSLL > 0 .Or. (cAliasSE1)->E1_IRRF > 0)
					aTitulos[nLin][nPosPis]:= Transform(aDadosRA1[3][nLin]   ,X3Picture("E1_PIS"))
					aTitulos[nLin][nPosCof]:= Transform(aDadosRA1[4][nLin]   ,X3Picture("E1_COFINS"))
					aTitulos[nLin][nPosCsl]:= Transform(aDadosRA1[5][nLin]   ,X3Picture("E1_CSLL"))
					aTitulos[nLin][nPosIrf]:= Transform(aDadosRA1[6][nLin]   ,X3Picture("E1_IRRF"))
					If __lMotRet .And. !Empty(aDadosRA1[12])
						aTitulos[nLin][nPosxRet]:= Transform(aDadosRA1[12][nLin]   ,X3Picture("E1_IRRF"))
					EndIf
					aTitulos[nLin][6] := Transform(xMoeda(aDadosRA1[7][nLin],(cAliasSE1)->E1_MOEDA,nMoeda,,5,U_Fa330Tx2(nMoedaP,nTaxaP),U_Fa330Tx2(nMoedaD,nTaxaD)),"@E 9999,999,999.99")
				EndIf
			    
			EndIf
			
			If __lMotRet .And. __lImpEmis
				aTitulos[nLin][nPosxRet]:= Transform(__nImpMR   ,X3Picture("E1_IRRF"))
			EndIf
					
			If lFI330ALT
				aTitulos:=ExecBlock("FI330ALT",.F.,.F.,{aTitulos})
			EndIf
			
			If __lNoTxMov
				__nTxMoedP := 0
			EndIf
		Else
	      	//Quando considerar o cliente original do titulo selecionado, mostra o cgc e o nome dos clientes refrentes a cada titulo (MV_PAR02==2)
	      	If MV_PAR02 == 2
	      		DBSelectArea("SA1")
	      		nIndexSA1 := IndexOrd()
	      		nPosSA1   := Recno()
	      		DBSetOrder(1)
	      		DBSeek(xFilial("SA1")+(cAliasSE1)->E1_CLIENTE+(cAliasSE1)->E1_LOJA)
	      		cCgcClie := SA1->A1_CGC
	      		cNomClie := SA1->A1_NOME

	      		DBSetOrder(nIndexSA1)
	      		DBGoTo(nPosSA1)
	     	   
	      		DBSelectArea(cAliasSE1)
	      		If nValLim==0
					If (cAliasSE1)->E1_SALDO>=nSaldo
						nValLim:= nSaldo
						If cPaisLoc != "RUS"
							nValComp:= If(lMarca,nSaldo,nValComp)
						Else
							nValComp:= If(lMarca,nValComp,nSaldo)
						EndIf
					Else
						nValLim:= (cAliasSE1)->E1_SALDO
						nValComp:= If(lMarca,nValComp,(cAliasSE1)->E1_SALDO)
					EndIf
				EndIf
				If cPaisLoc != "RUS"		
					aAdd(aTitulos,{(cAliasSE1)->E1_PREFIXO,;
										(cAliasSE1)->E1_NUM,;
										(cAliasSE1)->E1_PARCELA,;
										(cAliasSE1)->E1_TIPO,;
										(cAliasSE1)->E1_LOJA,;
										Transform(Round(xMoeda((cAliasSE1)->E1_SALDO+(cAliasSE1)->E1_SDACRES-(cAliasSE1)->E1_SDDECRE,(cAliasSE1)->E1_MOEDA,nMoeda,(cAliasSE1)->E1_EMISSAO,nDecs+1,aTxMoedas[(cAliasSE1)->E1_MOEDA][2],aTxMoedas[nMoeda][2]),nDecs),__cPiE1Sld),;
										Transform(nValComp,__cPiE1Sld),;
										lMarca,;
										(cAliasSE1)->E1_MOEDA,;
										(cAliasSE1)->E1_EMISSAO,;
										cNomClie,;
										Transform(cCgcClie,PesqPict("SA1","A1_CGC")),;
										Transform(xMoeda((cAliasSE1)->E1_SDACRES,(cAliasSE1)->E1_MOEDA,nMoeda,,5),"@E 9999,999,999.99"),;
										Transform(xMoeda((cAliasSE1)->E1_SDDECRE,(cAliasSE1)->E1_MOEDA,nMoeda,,5),"@E 9999,999,999.99"),;
										(cAliasSE1)->E1_HIST,;
										(cAliasSE1)->E1_FILIAL,;
										Transform(xMoeda(nValLim,nMoeda,nMoeda,,5,U_F23Tx2((cAliasSE1)->E1_MOEDA,(cAliasSE1)->E1_TXMOEDA),U_F23Tx2(nMoeda, nTxMoeda)),"@E 9999,999,999.99")})//Limite de Compensacao
				Else
						aAdd(aTitulos,{(cAliasSE1)->E1_PREFIXO,;
							(cAliasSE1)->E1_NUM,;
							(cAliasSE1)->E1_PARCELA,;
							(cAliasSE1)->E1_TIPO,;
							(cAliasSE1)->E1_LOJA,;
							Transform(Round(xMoeda((cAliasSE1)->E1_SALDO+(cAliasSE1)->E1_SDACRES-(cAliasSE1)->E1_SDDECRE,(cAliasSE1)->E1_MOEDA,nMoeda,(cAliasSE1)->E1_EMISSAO,nDecs+1,aTxMoedas[(cAliasSE1)->E1_MOEDA][2],aTxMoedas[nMoeda][2]),nDecs),PesqPict("SE1","E1_SALDO")),;
							Transform(nValComp,PesqPict("SE1","E1_SALDO")),;
							lMarca,;
							(cAliasSE1)->E1_MOEDA,;
							(cAliasSE1)->E1_EMISSAO,;
							cNomClie,;
							Transform(cCgcClie,PesqPict("SA1","A1_CGC")),;
							Transform(xMoeda((cAliasSE1)->E1_SDACRES,(cAliasSE1)->E1_MOEDA,nMoeda,,5),"@E 9999,999,999.99"),;
							Transform(xMoeda((cAliasSE1)->E1_SDDECRE,(cAliasSE1)->E1_MOEDA,nMoeda,,5),"@E 9999,999,999.99"),;
								(cAliasSE1)->E1_HIST,;
							(cAliasSE1)->E1_FILIAL,;
							Transform(xMoeda(nValLim,nMoeda,nMoeda,,5,U_Fa330Tx2((cAliasSE1)->E1_MOEDA,(cAliasSE1)->E1_TXMOEDA),U_Fa330Tx2(nMoeda, nTxMoeda)),"@E 9999,999,999.99"),;//Limite de Compensacao
							(cAliasSE1)->E1_CLIENTE,;
							(cAliasSE1)->E1_F5QCODE,;
							(cAliasSE1)->E1_VALOR,;
							(cAliasSE1)->E1_VLCRUZ,;
							(cAliasSE1)->E1_CONUNI,;
							AllTrim(Posicione("CTO",1,xFilial("CTO") + StrZero((cAliasSE1)->E1_MOEDA, GetSX3Cache("CTO_MOEDA", "X3_TAMANHO")), "CTO_SIMB"))})
				EndIf			
	       Else
	       
	       		// Moeda de Partida
				nMoedaP := (cAliasSE1)->E1_MOEDA
				// Moeda de Destino
				nMoedaD := nMoeda
				
   				If nValLim == 0
					If (cAliasSE1)->E1_SALDO>=nSaldo
						nValLim:= nSaldo
						nValComp:= If(lMarca,nValComp,nSaldo)

					Else
						nValLim:= (cAliasSE1)->E1_SALDO
						nValComp:= If(lMarca,nValComp,(cAliasSE1)->E1_SALDO)

					EndIf
				EndIf

				nVAlSld := (cAliasSE1)->(E1_SALDO+E1_SDACRES-E1_SDDECRE) - nDesFin  
				
				If cPaisLoc != "RUS"
					aAdd(aTitulos,{(cAliasSE1)->E1_PREFIXO,;
								(cAliasSE1)->E1_NUM,;
								(cAliasSE1)->E1_PARCELA,;
								(cAliasSE1)->E1_TIPO,;
								(cAliasSE1)->E1_LOJA,;
								Transform(Round(xMoeda((cAliasSE1)->E1_SALDO,(cAliasSE1)->E1_MOEDA,nMoeda,(cAliasSE1)->E1_EMISSAO,nDecs+1,aTxMoedas[(cAliasSE1)->E1_MOEDA][2],aTxMoedas[nMoeda][2]),nDecs),__cPiE1Sld),;
								Transform(nValComp,__cPiE1Sld),;
								lMarca,;
								(cAliasSE1)->E1_MOEDA,;
								(cAliasSE1)->E1_EMISSAO,;
								Transform(xMoeda((cAliasSE1)->E1_SDACRES,(cAliasSE1)->E1_MOEDA,nMoeda,,5),"@E 9999,999,999.99"),;
								Transform(xMoeda((cAliasSE1)->E1_SDDECRE,(cAliasSE1)->E1_MOEDA,nMoeda,,5),"@E 9999,999,999.99"),;
								(cAliasSE1)->E1_FILIAL,;
								Transform(xMoeda(nValLim,nMoeda,nMoeda,,5,U_F23Tx2((cAliasSE1)->E1_MOEDA,(cAliasSE1)->E1_TXMOEDA),U_F23Tx2(nMoeda, nTxMoeda)),"@E 9999,999,999.99")})//Limite de Compensacao
				Else
					aAdd(aTitulos,{(cAliasSE1)->E1_PREFIXO,;
									(cAliasSE1)->E1_NUM,;
									(cAliasSE1)->E1_PARCELA,;
									(cAliasSE1)->E1_TIPO,;
									(cAliasSE1)->E1_LOJA,;
									Transform(Round(xMoeda((cAliasSE1)->E1_SALDO,(cAliasSE1)->E1_MOEDA,nMoeda,(cAliasSE1)->E1_EMISSAO,nDecs+1,aTxMoedas[(cAliasSE1)->E1_MOEDA][2],aTxMoedas[nMoeda][2]),nDecs),__cPiE1Sld),;
									Transform(nValComp,__cPiE1Sld),;
									lMarca,;
									(cAliasSE1)->E1_MOEDA,;
									(cAliasSE1)->E1_EMISSAO,;
								Transform(xMoeda((cAliasSE1)->E1_SDACRES,(cAliasSE1)->E1_MOEDA,nMoeda,,5),"@E 9999,999,999.99"),;
								Transform(xMoeda((cAliasSE1)->E1_SDDECRE,(cAliasSE1)->E1_MOEDA,nMoeda,,5),"@E 9999,999,999.99"),;
										(cAliasSE1)->E1_FILIAL,;
									Transform(xMoeda(nValLim,nMoeda,nMoeda,,5,U_Fa330Tx2((cAliasSE1)->E1_MOEDA,(cAliasSE1)->E1_TXMOEDA),U_Fa330Tx2(nMoeda, nTxMoeda)),"@E 9999,999,999.99"),; //Limite de Compensacao
								(cAliasSE1)->E1_CLIENTE,;
								(cAliasSE1)->E1_F5QCODE,;
								(cAliasSE1)->E1_VALOR,;
								(cAliasSE1)->E1_VLCRUZ,;
								(cAliasSE1)->E1_CONUNI,;
								AllTrim(Posicione("CTO",1,xFilial("CTO") + StrZero((cAliasSE1)->E1_MOEDA, GetSX3Cache("CTO_MOEDA", "X3_TAMANHO")), "CTO_SIMB"))})
				EndIf

			EndIf

		EndIf

		aAdd( aRecNo, (cAliasSE1)->RECSE1 )
		
		(cAliasSE1)->(DBSkip())
	EndDo
	
	Exit
EndDo
If __lMotRet
	FMRGetArr(,.T.) // Destrói o Model do MR
EndIf
If __l330Va
	oModelVa:Destroy()
	oModelVa := NIL
EndIf
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Recupera a Integridade dos dados	  ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
DBSelectArea("SM0")
DBGoTo(nRecEmp)
cFilAnt := IIf( lFWCodFil, FWGETCODFILIAL, SM0->M0_CODFIL )

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Atualiza valor total dos t¡tulos - Windows	 ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
nValTot := 0
For nX := 1 to Len(aTitulos)
	If aTitulos[nX,8]
		nValtot += U_Fa330VTit(aTitulos[nX,7])
	EndIf
Next

/* GESTAO - inicio */
If !Empty(aTmpSE1Fil)
	For nX := 1 TO Len(aTmpSE1Fil)
		CtbTmpErase(aTmpSE1Fil[nX])
    Next
EndIf
/* GESTAO - fim */
DBSelectArea(cAliasSE1)
DBCloseArea()
DBSelectArea("SE1")

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Recupera a Integridade dos dados	  ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
DBSelectArea(cSavArea)
DBSetOrder(nSavOrd)
DBGoTo(nRecNo)
RestVarMR( aImpMRBrw )

Return( aTitulos )
/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡„o	 ³U_Fa330VTit ³ Autor ³ Mauricio Pequim Jr.   ³ Data ³ 22/09/97 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡„o ³ Retorna o saldo ou valor do titulo a ser compensado		  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ Fina330													  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
User Function Fa330VTit(aTitulo,cTipoTit,cValor)
Local nValor
cValor := IIf (cValor == NIL,aTitulo,cValor)
If ValType(cValor)=="N"
	nValor := cValor
Else
	nValor := DesTrans(cValor)
EndIf
Return nValor


/*
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡„o	 ³Fa330OK	³ Autor ³ Marcos Patricio		³ Data ³ 19/12/95 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡„o ³ Confirma a marcacao dos titulos para compensacao.		  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ Fa330OK													  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function FA330OK(nValTot As Numeric, lAutomato As Logical, lPccBxCR As Logical) As Logical
Local lMarcado 	As Logical 
Local nX	 	As Numeric
Local lRet		As Logical 
Local aAreaSE1 	As Array 

Default nValTot		 := 0 
Default lAutomato	 := .F.
Default lPccBxCR	 := FPccBxCr()

lMarcado	:= .T.
lRet		:=	.F.
aAreaSE1	:= {}

//Quando chamada da MATA465 se nao existe nada marcado da erro
If cPaisLoc <> "BRA"
	lMarcado	:=	.F.
	For nX	:=1 	To Len(aTitulos)
		If aTitulos[nX][8]
			//Forcar a saida do For
			lMarcado	:=	.T.
			nX	:=	Len(aTitulos)+1
		EndIf
	Next
EndIf

If !cPaisLoc $ "EUA|RUS"
	If !FA330SIT(aTitulos)
		Return(.F.)
	EndIf
EndIf

If !lAutomato
	If lMarcado
		lRet	:=	MsgYesNo(STR0024,STR0018)
	Else
		MsgAlert(STR0040,STR0018)
		lRet	:=	.F.
	EndIf
Else 
	lRet	:=	.T.
EndIf

If lRet  // Valida se o Saldo esta de acordo com o titulo. 
	nValTot := 0
	nValor  := IIf( nValor !=0 , 0 , nValor )

	For nX:=1 to Len(aTitulos)
		If aTitulos[nX,8]
			nValtot += U_Fa330VTit(aTitulos[nX,7])
			If lCredito .And. lRartImp .And. lPccBxCr 
				nValTot	-= U_Fa330VTit(aTitulos[nX,14])
				nValTot	-= U_Fa330VTit(aTitulos[nX,15])
				nValTot	-= U_Fa330VTit(aTitulos[nX,16])
			EndIf
		EndIf
	Next nX

	If nValTot == 0
		Help(" ",1,"NOTITSEL")
		lRet	:=	.F.
	EndIf

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Verifica se o Vlr. Informado e'igual ao calculado.      ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If Str(nValtot,17,2) != Str(nValor,17,2) .And. nValor != 0 .And. nOpca == 1
		Help(" ",1,"U_FA23COMP")
		lRet	:=	.F.
	EndIf

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Verifica se o Vlr. Informado e'compativel com o Saldo.  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	nValor := nValTot
	If Str(nValor,17,2) > Str(nSaldo,17,2)
		Help(" ",1,"FA330IVAL")
		lRet	:=	.F.
	EndIf

EndIf 

If ExistBlock("Fa330Vld") .And. lRet
	aAreaSE1 := SE1->(GetArea())
	SE1->(DBSetOrder(nIndVld))
	SE1->(DBGoTo(nRecVld))
	lRet := ExecBlock("Fa330Vld")
	FWRestArea(aAreaSE1)
EndIf

If UsaSeqCor()
	If !CTBvldDiario(cCodDiario,dDataBase)
		Return(.F.)
	EndIf
EndIf

Return lRet  //"Confirma marca‡„o de T¡tulos ?"###"Aten‡„o"

/*
===============================================================================================================================
Programa----------: FA330Troca
Autor-------------: Igor Melgaço
Data da Criacao---: 28/08/2023
Descrição---------: Troca o flag para marcado ou nao,aceitando valor. 
===============================================================================================================================
*/ 
Static Function FA330Troca(nIt,aArray,oGet,lTodos,oTitulo,lMarkAll,lAuto)

Local oDlg
Local nOpca   	:= 0
Local nX       	:= 0
Local nAcresc  	:= 0
Local nY	   	:= 0
Local xy       	:= 0
Local nVezes   	:= 1
Local nOldIt   	:= nIt
Local lIrPjBxCr	:= FIrPjBxCr()
Local lPccBxCr	:= FPccBxCr()
Local nPosIr	:= 0
Local cLimite  	:= ''
Local nValOld  	:= 0
Local nPos 	   	:= 0
Local nTotAbat 	:= 0
Local aAreaSE1 	:= SE1->(GetArea())
Local nItemRA	:= 0
Local nItemOu	:= 0
Local lNcc		:= SE1->E1_TIPO $ MV_CRNEG
Local nVlMinImp := GetNewPar("MV_VL10925",5000)
Local nAltVal	:= 0
Local lBq10925	:= SuperGetMV("MV_BQ10925",,"2") == "1"
Local nVTit		:= 0
Local aArrAux	:= {}
Local nVlAbt	:= 0
Local lMSal		:= .F.
Local cOldVl	:= 0
Local nVlrSldPcc := 0
Local lRaRtImpMR := .F.
Local lIrfBxAux := lIrPjBxCr
Local lPccBxAux := lPccBxCr
Local aImpMRBrw := PegaVarMR()
Local nPosRec	:= 20
Local bEval		:= {|| ValType(aArray[nIt,26]) == 'C' }
Local cPicE1IRRF	:= PesqPict("SE1","E1_IRRF")
Local cPicE1PIS		:= PesqPict("SE1","E1_PIS")
Local cPicE1COF		:= PesqPict("SE1","E1_COFINS")
Local cPicE1CSL		:= PesqPict("SE1","E1_CSLL")
Local nValVa		:= 0

DEFAULT lMarkAll 	:= .F.
DEFAULT lTodos  	:= .F.
DEFAULT lAuto       := .F.

//Motor de retenções
If __lMotRet
	//Verifica as configurações de impostos pelo motor de retenção
	F330VldImp()
	
	lRaRtImpMR 	:= ( __lPccMR .And. __lRaRtPcc ) .Or. ( __lIrfMR .And. __lRaRtIrf ) .Or. ( __lIssMR .And. __lRaRtIss )
	lPccBxCr 	:= ( __lPccMR .And. __lPccBxMR ) .Or. ( !__lPccMR .And. lPccBxAux )
	lIrPjBxCr 	:= ( __lIrfMR .And. __lIrfBxMR ) .Or. ( !__lIrfMR .And. lIrfBxAux )
EndIf

If dDataBase >= dLastPcc
	nVlMinImp	:= 0
EndIf

If MV_PAR02 == 2
	nPos := 25
    bEval := {|| ValType(aArray[nIt,29]) == 'C' }
Else
	nPos := 22
EndIf

If cPaisLoc == "BRA"
	cValor  := U_Fa330VTit(aTitulos[nIt,6 ])
	cSaldo  := U_Fa330VTit(aTitulos[nIt,nPos ])//Limite de Compensação
	cSalTit := U_Fa330VTit(aTitulos[nIt,6 ])
	cLimite := U_Fa330VTit(aTitulos[nIt,nPos]) //Limite de Compensação
	nVezes  := If(lTodos,Len(aArray),1)
	If MV_PAR02 == 1
		nAcresc := U_Fa330VTit(aTitulos[nIt,10])
		nValVa	:= U_Fa330VTit(aTitulos[nIt,If(__lMotRet,28,27)])
	Else
		nAcresc := U_Fa330VTit(aTitulos[nIt,13])
		nValVa	:= U_Fa330VTit(aTitulos[nIt,If(__lMotRet,31,30)])
	EndIf
	If ( lPccBxCr .Or. lIRPJBxCr ) .And. ( lRaRtImp .Or. lRaRtImpMR )
		cValor  := U_Fa330VTit(aTitulos[nIt,IIf(MV_PAR02== 2, 25,22)])
	EndIf
Else
	cValor  := U_Fa330VTit(aTitulos[nIt,6 ])
	If MV_PAR02 == 1
		cSaldo  := U_Fa330VTit(aTitulos[nIt,14])
	Else
		cSaldo  := U_Fa330VTit(aTitulos[nIt,17])
	EndIf
	cSalTit := U_Fa330VTit(aTitulos[nIt,6 ])
	nVezes  := If(lTodos,Len(aArray),1)
EndIf

nValtot := 0
nVlComp := 0

For xy := 1 to Len(aTitulos)
	If aTitulos[xy,8] .And. xy <> nIt
		nVlComp += U_Fa330VTit(aTitulos[xy,7])
	EndIf
Next

cSaldo := IIf(cSaldo > nSaldo - nVlComp,nSaldo - nVlComp,cSaldo)
nValOld	:= cSaldo

For nY := 1 to nVezes

	If nVezes > 1
		nIt := nY
		If cPaisLoc != "RUS"
			cValor  := U_Fa330VTit(aTitulos[nIt,6])
			cSaldo  := U_Fa330VTit(aTitulos[nIt, If( cPaisLoc == "BRA", nPos, 14 ) ])
			cLimite := U_Fa330VTit(aTitulos[nIt,nPos])
			If ( lPccBxCr .Or. lIRPJBxCr ) .And. ( lRaRtImp .Or. lRaRtImpMR )
				cValor  := U_Fa330VTit(aTitulos[nIt,22])
			EndIf
		Else
			cValor  := U_Fa330VTit(aTitulos[nIt, 6])
			cSaldo  := U_Fa330VTit(aTitulos[nIt, 14])
			cLimite := U_Fa330VTit(aTitulos[nIt, 14])
		EndIf
	EndIf

	If lMarkAll .And. lTodos
		aArray[nIt,8] := .T.
	Else
		aArray[nIt,8] := !aArray[nIt,8]
	EndIf

	If ( lPccBxCr .Or. lIRPJBxCr ) .And. ( lRaRtImp .Or. lRaRtImpMR ) .And. !lNcc
		aDadosRA1[9][nIt] := aArray[nIt,8]
	EndIf

	If aArray[nIt,8]

		If FA330Lock(aArray[nIt,1]+aArray[nIt,2]+aArray[nIt,3]+aArray[nIt,4],,,aArray[nIt,IIf(MV_PAR02== 2, 16,13)])

			If !lTodos
				If cPaisLoc == "BRA"
					If aArray[nIt,4] $ MV_CRNEG .And. (MV_PAR08 == 1 .Or. ( lRaRtImp .Or. lRaRtImpMR ) )
						F330VALNCC(@aArray,nIt, cValor < cLimite, .T.)
						cSaldo  := nSaldo - nVlComp
					EndIf
					If cSaldo >= aArray[nIt,(nPos-1)]
						cLimite := U_Fa330VTit(aArray[nIt,nPos]) //Limite de Compensação
						cValor	:= U_Fa330VTit(aArray[nIt,nPos]) //Limite de Compensação
					Else
						If !lNcc .Or. (lNCC .And. cValor > cSaldo)
							cLimite := cSaldo
							cValor	:= cSaldo
						EndIf
					EndIf
					If cLimite < cValor
						cValor	:= cLimite
					EndIf
					
					If __lMotRet
					
						If cPaisLoc == "BRA" .And. MV_PAR02 == 2
							nPosRec	:= 23
						EndIf
						SE1->( DBGoTo( aArray[nIt, nPosRec] ) )
						//Verifica as configurações de impostos pelo motor de retenção
						__lTCnfgMR := F330VldImp()
	
						lRaRtImpMR 	:= ( __lPccMR .And. __lRaRtPcc ) .Or. ( __lIrfMR .And. __lRaRtIrf ) .Or. ( __lIssMR .And. __lRaRtIss )
						lPccBxCr 	:= ( __lPccMR .And. __lPccBxMR ) .Or. ( !__lPccMR .And. lPccBxAux )
						lIrPjBxCr 	:= ( __lIrfMR .And. __lIrfBxMR ) .Or. ( !__lIrfMR .And. lIrfBxAux )
	
						//Calcula os impostos pelo motor de retenções
						If __lTCnfgMR
							F330CalImp( SE1->E1_NATUREZ, SE1->E1_CLIENTE, SE1->E1_LOJA, SE1->E1_FILORIG, SE1->E1_SALDO, dDataBase, SE1->E1_TIPO )
							__lTCnfgMR	:= .F.
						EndIf
					EndIf					
					If !__lPccMR
						If lPccBxCr .And. ( !lRartimp ) //  .And. SE1->E1_TIPO $ MVRECANT
							aArrAux 	:= aClone(aArray)
							nVlAbt 		:= SomaAbat(aArray[nIt][1],aArray[nIt][2],aArray[nIt][3],"R",,,SE1->E1_CLIENTE,,aArray[nIt][13])
							nVlrSldPcc  := DesTrans( aArrAux[nIt][nPos] ) 
							
							U_F330CalcPCC(nIt,aArrAux,@nVlrSldPcc,cValor < cLimite)
							
							If ( nVlAbt == 0 .Or. nVlAbt <> ( DesTrans(aArrAux[nIt][nPosPis]) + DesTrans(aArrAux[nIt][nPosCof]) + DesTrans(aArrAux[nIt][nPosCsl])) )
								If lBq10925 //Pcc Bruto
									If ( cValor + ( DesTrans(aArrAux[nIt][nPosPis]) + DesTrans(aArrAux[nIt][nPosCof]) + DesTrans(aArrAux[nIt][nPosCsl]) ) ) > Val(Replace(Replace(aArrAux[nIt][6],".", "" ), ",", ".")) //Verifica se é maior que Saldo do titulo							
										cValor     := ( nVlrSldPcc - ( DesTrans(aArrAux[nIt][nPosPis]) + DesTrans(aArrAux[nIt][nPosCof]) + DesTrans(aArrAux[nIt][nPosCsl]) ) )
										lMSal      := .T.
										nVlrSldPcc := DesTrans( aArray[nIt][nPos] )
									EndIf  
								Else //Pcc Liquido
									If cValor > ( nVlrSldPcc - ( DesTrans(aArrAux[nIt][nPosPis]) + DesTrans(aArrAux[nIt][nPosCof]) + DesTrans(aArrAux[nIt][nPosCsl]) ) )
										cValor     := ( nVlrSldPcc - ( DesTrans(aArrAux[nIt][nPosPis]) + DesTrans(aArrAux[nIt][nPosCof]) + DesTrans(aArrAux[nIt][nPosCsl]) ) )
										lMSal      := .T.
										nVlrSldPcc := DesTrans( aArray[nIt][nPos] )
									EndIf
								EndIf
							EndIf
						EndIf	
						If lIrPjBxCr
							If !__lIrfMR
								If MV_PAR02 == 1
									aArray[nIt,26] := IIf( Eval(bEval), Val(StrTran(Replace(aArray[nIt,26],".",""),",",".")), aArray[nIt,26])
									nIrrf := FCaIrBxCR(If(MV_PAR08 == 1 .And. aArray[nIt,26] > 0, aArray[nIt,26], nVlrSldPcc),,(SE1->E1_VALOR <> SE1->E1_SALDO .And. lRaRtImp ) )
								Else
									aArray[nIt,29] := IIf( Eval(bEval), Val(StrTran(Replace(aArray[nIt,29],".",""),",",".")), aArray[nIt,29])
									nIrrf := FCaIrBxCR(If(MV_PAR08 == 1 .And. aArray[nIt,29] > 0, aArray[nIt,29], nVlrSldPcc),,(SE1->E1_VALOR <> SE1->E1_SALDO .And. lRaRtImp ) )
								EndIf
								aArray[nIt,nPosIrf] := Transf(nIrrf,cPicE1IRRF)
								aTitulos[nIt,nPosIrf]:= Transf(nIrrf,cPicE1IRRF)
								If cValor + nPis + nCofins + nCsll + nIrrf >  Val(StrTran(Replace(aArray[nIt][6],".",""),",",".")) 
									cValor := cValor - Val(StrTran(Replace(aArray[nIt][nPosIrf],".",""),",","."))
								EndIf
							EndIf
							aArray[nIt,nPosBIRF] := Transform(nVlrSldPcc,"@E 99,999,999.99")
						EndIf
					ElseIf MV_PAR08 == 1
						If lPccBxCr .And. ( !lRaRtImpMR ) // .And. SE1->E1_TIPO $ MVRECANT
							aArrAux 	:= aClone(aArray)
							nVlAbt 		:= SomaAbat(aArray[nIt][1],aArray[nIt][2],aArray[nIt][3],"R",,,SE1->E1_CLIENTE,,aArray[nIt][13])
							nVlrSldPcc  := DesTrans( aArrAux[nIt][nPos] ) 
							
							U_F330CalcPCC(nIt,aArrAux,@nVlrSldPcc,cValor < cLimite)
								
							If lBq10925 //Pcc Bruto
								If ( cValor + ( DesTrans(aArrAux[nIt][nPosPis]) + DesTrans(aArrAux[nIt][nPosCof]) + DesTrans(aArrAux[nIt][nPosCsl]) ) ) > Val(Replace(Replace(aArrAux[nIt][6],".", "" ), ",", ".")) //Verifica se é maior que Saldo do titulo							
									cValor     := ( nVlrSldPcc - ( DesTrans(aArrAux[nIt][nPosPis]) + DesTrans(aArrAux[nIt][nPosCof]) + DesTrans(aArrAux[nIt][nPosCsl]) ) )
									lMSal      := .T.
									nVlrSldPcc := DesTrans( aArray[nIt][nPos] )
								EndIf  
							Else //Pcc Liquido
								If cValor > ( nVlrSldPcc - ( DesTrans(aArrAux[nIt][nPosPis]) + DesTrans(aArrAux[nIt][nPosCof]) + DesTrans(aArrAux[nIt][nPosCsl]) ) )
									cValor     := ( nVlrSldPcc - ( DesTrans(aArrAux[nIt][nPosPis]) + DesTrans(aArrAux[nIt][nPosCof]) + DesTrans(aArrAux[nIt][nPosCsl]) ) )
									lMSal      := .T.
									nVlrSldPcc := DesTrans( aArray[nIt][nPos] )
								EndIf
							EndIf
						EndIf
					EndIf
					
					If __lMotRet
						aArray	[nIt,nPosxRet] := Transf(__nImpMR,cPicE1IRRF)
						aTitulos[nIt,nPosxRet] := Transf(__nImpMR,cPicE1IRRF)
						If __lIrfMR .And. lIrPjBxCr .And. MV_PAR08 == 1
							nIrrf := __nIrfCaMR
							aArray[nIt,nPosIrf] := Transf(nIrrf,cPicE1IRRF)
							aTitulos[nIt,nPosIrf]:= Transf(nIrrf,cPicE1IRRF)
						EndIf
						If cValor + nPis + nCofins + nCsll + nIrrf + __nImpMR >  Val(StrTran(Replace(aArray[nIt][6],".",""),",",".")) 
							cValor := cValor - ( Val(StrTran(Replace(aArray[nIt][nPosIrf],".",""),",",".")) + __nImpMR )
						EndIf
					EndIf
				EndIf
				
				If !cPaisLoc $ "EUA|RUS"
					If !FA330SIT(aTitulos,IIf(MV_PAR02 == 2, aTitulos[nIt,23],aTitulos[nIt,20]))
						aTitulos[nIt][8] := .F.
						Return(aTitulos)
					EndIf
				EndIf
				
				If !lAuto
					DEFINE MSDIALOG oDlg FROM  80,100 TO 180,400 TITLE STR0048 PIXEL Style DS_MODALFRAME //"Compensa‡„o CR"

					@ -3, 2 TO 22, 128 OF oDlg	PIXEL
					@ 7, 68 MSGET cValor Picture "@E 9999,999,999.99" VALID cValor <= cSaldo  .And. cValor > 0 .And. ;
																			cValor >= (nAcresc + (If(nValVa > 0, nValVa, 0))) ;
																			SIZE 54, 10 OF oDlg PIXEL hasbutton
					@ 8, 9 Say STR0014  SIZE 54, 7 OF oDlg PIXEL  //"Valor a compensar"

					If aArray[nIt,4] $ MV_CRNEG .Or. lNcc

						@ 21, 2 Say STR0072  SIZE 120, 60 OF oDlg PIXEL //"Ao selecionar esse titulo os impostos calculados na baixa serão desconsiderados"

					EndIf

					DEFINE SBUTTON FROM 37, 71 Type 1 ENABLE ACTION (nOpca:=1,If((cValor <= cSaldo  .And. cValor > 0 .And. cValor >= nAcresc .And. If(cPaisLoc== "BRA", cValor<=cLimite, cValor <= cSalTit)),oDLg:End(),nOpca:=0)) OF oDlg
					DEFINE SBUTTON FROM 37, 99 Type 2 ENABLE ACTION oDlg:End() OF oDlg

					ACTIVATE MSDIALOG oDlg
				Else
					If cValor <= cSaldo  .And. cValor > 0 .And. cValor >= nAcresc .And. (cPaisLoc== "BRA", cValor<=cLimite, cValor <= cSalTit)
						nOpca := 1
					Else
						nOpca:=0
					EndIf
				EndIf
			Else
				nOpca := 1
			EndIf
			
			If lMSal
				cOldVl := cValor
				cValor := nVlrSldPcc
			EndIf
			
			If 	nOpca == 0
				aArray[nIt,8] := .F.
				If ( lRaRtImp .Or. lRaRtImpMR ) .And. !lNcc .And. Type("aDadosRA1[9][nIt]") == "A"
					aDadosRA1[9][nIt] := .F.
				EndIf
				If aArray[nIt,4] $ MV_CRNEG .And. (MV_PAR08 == 1 .Or. ( lRaRtImp .Or. lRaRtImpMR ) ) .And. !Empty( cLimite )
					F330VALNCC(@aArray,nIt, cValor < cLimite, .F.)
					cSaldo  := nSaldo - nVlComp
					cLimite := U_Fa330VTit(aTitulos[nIt,IIf(cPaisLoc != "RUS",nPos,14)]) //Limite de Compensação
				EndIf
			EndIf
			
			If nOpca == 1
			
				If lCredito .And. SE1->E1_TIPO == MV_CRNEG
					If !cPaisLoc $ "EUA|RUS"
						DBSelectArea("SE1")
						If MV_PAR02 == 2
							DBGoTo(aArray[nIt,23])
						Else
							DBGoTo(aArray[nIt,20])
					    EndIf
				    EndIf
					nValAbat := SomaAbat(SE1->E1_PREFIXO,SE1->E1_NUM,SE1->E1_PARCELA,"R",SE1->E1_MOEDA,,SE1->E1_CLIENTE,,SE1->E1_FILIAL)
					FWRestArea(aAreaSE1)
				EndIf
							
				//Pcc Baixa CR
				//Caso a compensacao tenha partido de um Adiantamento
				If lCredito .And. (SE1->E1_TIPO <> MV_CRNEG) .And. ( !lRaRtImp .And. !lRaRtImpMRt ) .And. cPaisLoc == "BRA"
					DBSelectArea("SE1")					 				
					If MV_PAR02 == 2
						DBGoTo(aArray[nIt,23])
					Else
				   		DBGoTo(aArray[nIt,20])
				    EndIf
				    
					If MV_PAR08 == 1 .Or. ( lRaRtImp .Or. lRaRtImpMR )
						nTotAbat := SomaAbat(SE1->E1_PREFIXO,SE1->E1_NUM,SE1->E1_PARCELA,"R",SE1->E1_MOEDA,,SE1->E1_CLIENTE,,SE1->E1_FILIAL)
						nValAbat := nTotAbat
					Else
						nTotAbat := 0
					EndIf
					
					nOldValRec	:= nValOld
					If cValor > cLimite
						cValor := cLimite
					EndIf
					
					//Motor de retenções
					If __lMotRet
						//Verifica as configurações de impostos pelo motor de retenção
						__lTCnfgMR	:= F330VldImp()

						lRaRtImpMR	:= ( __lPccMR .And. __lRaRtPcc ) .Or. ( __lIrfMR .And. __lRaRtIrf ) .Or. ( __lIssMR .And. __lRaRtIss )
						lPccBxCr 	:= ( __lPccMR .And. __lPccBxMR ) .Or. ( !__lPccMR .And. lPccBxAux )
						lIrPjBxCr 	:= ( __lIrfMR .And. __lIrfBxMR ) .Or. ( !__lIrfMR .And. lIrfBxAux )
						
						//Calcula os impostos pelo motor de retenções
						If __lTCnfgMR
							F330CalImp( SE1->E1_NATUREZ, SE1->E1_CLIENTE, SE1->E1_LOJA, SE1->E1_FILORIG, SE1->E1_SALDO /*nSaldo*/, dDataBase, SE1->E1_TIPO, .T. )
							__lTCnfgMR	:= .F.
						EndIf
						If nY == nVezes // Destrói o Model do MR
							FMRGetArr(,.T.)
						EndIf
						
						aArray	[nIt,nPosxRet] := Transf(__nImpMR,cPicE1IRRF)
						aTitulos[nIt,nPosxRet] := Transf(__nImpMR,cPicE1IRRF)
						If __lIrfMR .And. lIrPjBxCr
							nIrrf := __nIrfCaMR
							aArray[nIt,nPosIrf] := Transf(nIrrf,cPicE1IRRF)
							aTitulos[nIt,nPosIrf]:= Transf(nIrrf,cPicE1IRRF)
						EndIf								
					EndIf
															
					If ( lRartimp .Or. lRaRtImpMR ) .And. ( !( cValor + nPis + nCofins + nCsll == SE1->E1_SALDO ) )
						U_F330CalcPCC( nIt, aArray, @cValor + IIf( cValor == cSalTit, nTotAbat, 0 ), cValor < cLimite )
					EndIf

					If !__lPccMR .And. dDatabase <= dLastPcc
						If !lRaRtImp .And. MV_PAR08 == 1 .And. lPccBxCr .And. SE1->E1_TIPO <> MVRECANT .And. nPis+nCofins+nCsll+nIrrf > 0 .And. aDadosret[1] < nVlMinImp .And. aDadosRet[1]+nValRec > nVlMinImp
		  					nProp	:= (aDadosret[1]+ nValRec) / nSaldo
							nPis	:= SE1->E1_PIS * nProp
							nCofins := SE1->E1_COFINS * nProp
							nCsll	:= SE1->E1_CSLL * nProp
						EndIf
					EndIf
				EndIf
								
				If cPaisLoc == "BRA"
					If nMoeda <> SE1->E1_MOEDA .And. cValor == NoRound(xMoeda(SE1->E1_SALDO,SE1->E1_MOEDA,nMoeda,SE1->E1_EMISSAO,5,U_Fa330Tx2(nMoeda,nTxMoeda)),2) 
						aArray[nIt,9] := xMoeda(SE1->E1_SALDO,SE1->E1_MOEDA,nMoeda,SE1->E1_EMISSAO,5,U_Fa330Tx2(nMoeda,nTxMoeda))
					Else
						aArray[nIt,9] := IIf(lMSal .And. cValor > cOldVl,cOldVl,cValor)
					EndIf
					
					If lIrPjBxCr .And. lCredito .And. (SE1->E1_TIPO <> MV_CRNEG) 
						
						If MV_PAR02 == 2
							If !__lIrfMR
								nIrrf := Val(StrTran(Replace(aArray[nIt][nPosIrf],".",""),",",".")) //FCaIrBxCR(aArray[nIt,9],aArray[nIt,23])
							EndIf
							
							If ( nPosIr := aScan(aImpIR,{|x| x[2] == aArray[nIt,23]}) ) == 0
								aAdd( aImpIR, {nIrrf,aArray[nIt,23]} )
								nPosIr := Len( aImpIR )
							Else
								aImpIR[nPosIr][1] := nIrrf
							EndIf
						Else
							If !__lIrfMR
								nIrrf := Val(StrTran(Replace(aArray[nIt][nPosIrf],".",""),",","."))//FCaIrBxCR(aArray[nIt,9],aArray[nIt,20])
							EndIf
							
							If ( nPosIr := aScan(aImpIR,{|x| x[2] == aArray[nIt,20]}) ) == 0
								aAdd( aImpIR, {nIrrf,aArray[nIt,20]} )
								nPosIr := Len( aImpIR )
							Else
								aImpIR[nPosIr][1] := nIrrf
							EndIf
						EndIf
							
					EndIf

					If (lPccBxCr .Or. lIRPJBxCr) .And. ( lRaRtImp .Or. lRaRtImpMR ) .And. !lNcc
						DBSelectArea("SE1")
						If MV_PAR02 == 2
							DBGoTo(aArray[nIt,23])
						Else
				   			DBGoTo(aArray[nIt,20])
				    	EndIf
				    	
						If lCredito
							nItemOU := aScan(aDadosRA1[2],{|x| x==SE1->(Recno())})
						Else
							nItemRA := aScan(aDadosRA1[1],{|x| x==SE1->(Recno())})
						EndIf
												
				        If !__lPccMR .And. !(aArray[nIt,4] $ MV_CRNEG)
							If F330RaRtIm(@aDadosRA1,cValor,nItemRA,nItemOu, cValor < cLimite )
								If lCredito
									nAltVal	:= cValor
									If nAltVal+nPis+nCofins+nCsll == SE1->E1_SALDO 
										nAltVal	:= nAltVal+nPis+nCofins+nCsll
									ElseIf nAltVal+aDadosRA1[3][nItemOU]+aDadosRA1[4][nItemOU]+aDadosRA1[5][nItemOU] == SE1->E1_SALDO
										nAltVal	:= nAltVal+aDadosRA1[3][nItemOU]+aDadosRA1[4][nItemOU]+aDadosRA1[5][nItemOU]
									EndIf
									If dDataBase >= dLastPcc .And. (cValor <> cLimite )
										aPcc	:= newMinPcc(dbaixa,nAltVal,SE1->E1_NATUREZ,"R",SE1->E1_CLIENTE+SE1->E1_LOJA)
										nPis	:= 	aPcc[2]
										nCofins	:=	aPcc[3]
										nCsll	:=  aPcc[4]
										nPisCalc	:= nPis
										nPisBaseC	:= nAltVal
										nPisBaseR 	:= nAltVal
										nCofCalc	:= nCofins
										nCofBaseC	:= nAltVal
										nCofBaseR 	:= nAltVal
										nCslCalc	:= nCsll
										nCslBaseC	:= nAltVal
										nCslBaseR 	:= nAltVal
										
										If !__lIrfMR .And. lIrPjBxCr .And. cPaisLoc == "BRA"
											nIrrf	:= nIrrf * (nAltVal / SE1->E1_BASEIRF)
										EndIf
										
										aDadosRA1[3][nItemOu]	:= nPis
										aDadosRA1[4][nItemOu]	:= nCofins
										aDadosRA1[5][nItemOu]	:= nCsll
											
									EndIf
									aArray[nIt,nPosPis]:=Transf(aDadosRA1[3][nItemOu],cPicE1PIS)
									aArray[nIt,nPosCof]:=Transf(aDadosRA1[4][nItemOu],cPicE1COF)
									aArray[nIt,nPosCsl]:=Transf(aDadosRA1[5][nItemOu],cPicE1CSL)
									If !__lIrfMR
										aArray[nIt,nPosIrf] := Transf(aDadosRA1[6][nItemOu],cPicE1IRRF)
									Else
										aArray[nIt,nPosIrf] := Transf( nIrrf, cPicE1IRRF)
									EndIf
									If dDataBase < dLastPcc
										If cValor < cLimite
											cValor := cValor - (aDadosRA1[3][nItemOu]+aDadosRA1[4][nItemOu]+aDadosRA1[5][nItemOu]+aDadosRA1[6][nItemOu];
													  +aDadosRA1[10][nItemOu]+aDadosRA1[11][nItemOu])
										EndIf
									Else
										If cValor < cLimite
											cValor := cValor - (nPis+nCofins+nCsll)
											If !__lIrfMR .And. lIrPjBxCr
												cValor	:= cValor - nIrrf
											EndIf
										EndIf
									EndIf
								Else
									nAltVal	:= cValor
									If nAltVal+nPis+nCofins+nCsll == SE1->E1_SALDO 
										nAltVal	:= nAltVal+nPis+nCofins+nCsll
									ElseIf nAltVal+aDadosRA1[3][nItemRA]+aDadosRA1[4][nItemRA]+aDadosRA1[5][nItemRA] == SE1->E1_SALDO
										nAltVal	:= nAltVal+aDadosRA1[3][nItemRA]+aDadosRA1[4][nItemRA]+aDadosRA1[5][nItemRA]
									EndIf
									If dDataBase >= dLastPcc .And. (cValor <> cLimite)
										aPcc	:= newMinPcc(dbaixa,nAltVal,SE1->E1_NATUREZ,"R",SE1->E1_CLIENTE+SE1->E1_LOJA)
										nPis	:= 	aPcc[2]
										nCofins	:=	aPcc[3]
										nCsll	:=  aPcc[4]
										nPisCalc	:= nPis
										nPisBaseC	:= nAltVal
										nPisBaseR 	:= nAltVal
										nCofCalc	:= nCofins	
										nCofBaseC	:= nAltVal
										nCofBaseR 	:= nAltVal
										nCslCalc	:= nCsll	
										nCslBaseC	:= nAltVal
										nCslBaseR 	:= nAltVal
										
										If !__lIrfMR .And. lIrPjBxCr .And. cPaisLoc == "BRA"
											nIrrf	:= aDadosRA1[6][nItemRA]
											//nIrrf	:= nIrrf * (nAltVal / SE1->E1_BASEIRF)
										EndIf
											
										aDadosRA1[3][nItemRA]	:= nPis
										aDadosRA1[4][nItemRA]	:= nCofins
										aDadosRA1[5][nItemRA]	:= nCsll
												
									EndIf
									aArray[nIt,nPosPis]:=Transf(aDadosRA1[3][nItemRA],cPicE1PIS)
									aArray[nIt,nPosCof]:=Transf(aDadosRA1[4][nItemRA],cPicE1COF)
									aArray[nIt,nPosCsl]:=Transf(aDadosRA1[5][nItemRA],cPicE1CSL)
									If !__lIrfMR
										aArray[nIt,nPosIrf] := Transf(aDadosRA1[6][nItemRA],cPicE1IRRF)
									Else
										aArray[nIt,nPosIrf] := Transf( nIrrf, cPicE1IRRF)
									EndIf
									If dDataBase < dLastPcc
										If cValor < cLimite
									   		cValor := cValor - (aDadosRA1[3][nItemRA]+aDadosRA1[4][nItemRA]+aDadosRA1[5][nItemRA]+aDadosRA1[6][nItemRA];
																+aDadosRA1[10][nItemRA]+aDadosRA1[11][nItemRA])
										EndIf
									Else
										If cValor < cLimite
											cValor := cValor - (nPis+nCofins+nCsll)
											If !__lIrfMR .And. lIrPjBxCr
												cValor	:= cValor - nIrrf
											EndIf
										EndIf
									EndIf
								EndIf
								If !( nMoeda <> SE1->E1_MOEDA .And. cValor == NoRound(aArray[nIt,9], 2) )
									aArray[nIt,9]	 := cValor
								EndIf
							EndIf
						ElseIf !(aArray[nIt,4] $ MV_CRNEG) // Pcc pelo Motor
							aArray[nIt,nPosPis] := Transf(nPis,		cPicE1PIS)
							aArray[nIt,nPosCof] := Transf(nCofins,	cPicE1COF)
							aArray[nIt,nPosCsl] := Transf(nCsll,	cPicE1CSL)
							If __lIrfMR
								aArray[nIt,nPosIrf] := Transf( nIrrf, cPicE1IRRF)
							EndIf
						EndIf
					EndIf
				EndIf
								
				If cPaisLoc != "RUS" .And. lPccBxCr .And. ( !lRaRtImp .And. !lRaRtImpMR )
					nTotAbat := SomaAbat(SE1->E1_PREFIXO,SE1->E1_NUM,SE1->E1_PARCELA,"R",SE1->E1_MOEDA,,SE1->E1_CLIENTE,,SE1->E1_FILIAL)
					If ((cValor <= cLimite .And. SE1->E1_SALDO - nPis -nCofins - nCsll - nTotAbat <> cValor) .Or.;
					(SE1->(E1_PIS+E1_CSLL+E1_COFINS) > 0 .And. (nPis+nCofins+nCsll) == 0 .And. cValor <= cLimite .And. MV_PAR08 == 1)) //essa cond ocorre quando os tít são marca indiv, removido a seleç e depois selec todos.
						For nX:=1 to Len(aArray) // verifica todos os títulos ja marcados
							If	aArray[nX,8] 
								nVTit += U_Fa330VTit(aArray[nX,7])
							EndIf
						Next
						If lMSal
							cValor	:= cOldVl
						EndIf
						__nProp := Round((cValor + IIf(lIrPjBxCr, SE1->E1_IRRF, 0) + SE1->(E1_PIS + E1_COFINS + E1_CSLL) + SE1->E1_DECRESC + nTotAbat) / SE1->E1_SALDO, 2)
						If ( nVtit + cValor == SE1->E1_VALOR - SE1->E1_PIS - SE1->E1_COFINS - SE1->E1_CSLL - nTotAbat ) .Or. ( nVtit + cValor == SE1->E1_VALOR - nPis - nCofins - nCsll - nTotAbat )
							nAltVal := SE1->E1_SALDO - nVtit // se os titulos ja marcados + o titulo do momento For igual o liquido, deve calcular pelo restante do saldo.
						Else
							nAltVal := IIf(MV_PAR08==1 .Or. ( cPaisLoc == 'BRA' .And. __nProp == 1 ), (cValor + IIf(lIrPjBxCr, SE1->E1_IRRF, 0) + If(cPaisLoc == 'BRA' .And. __nProp == 1, SE1->(E1_PIS + E1_COFINS + E1_CSLL), IIf(lTodos, 0, SE1->(E1_PIS + E1_COFINS + E1_CSLL) ) ) + SE1->E1_DECRESC + nTotAbat), cValor)
						EndIf
						
						If (aArray[nIt,4] $ MV_CRNEG .And.  SE1->E1_SALDO - nTotAbat == cValor) .Or. (lNCC .And.  SE1->E1_SALDO - nValAbat == cValor ) .Or. ( nAltVal > SE1->E1_SALDO ) 
							//baixa total
							nAltVal := SE1->E1_SALDO
						EndIf
						
						If dDataBase >= dLastPcc
							If !__lPccMR
								aPcc	:= newMinPcc(dBaixa,nAltVal,SE1->E1_NATUREZ,"R",SE1->E1_CLIENTE+SE1->E1_LOJA)
								nPis	:= 	aPcc[2]
								nCofins	:=	aPcc[3]
								nCsll	:=  aPcc[4]
															
								nPisCalc	:= nPis
								nPisBaseC	:= nAltVal	
								nPisBaseR 	:= nAltVal
								nCofCalc	:= nCofins	
								nCofBaseC	:= nAltVal
								nCofBaseR 	:= nAltVal
								nCslCalc	:= nCsll
								nCslBaseC	:= nAltVal
								nCslBaseR 	:= nAltVal
							EndIf
														
							If !__lIrfMR .And. lIrPjBxCr .And. cPaisLoc == "BRA"
								nIrrf	:= nIrrf * (nAltVal / SE1->E1_BASEIRF)
								aArray[nIt,nPosIrf]	:= Transf(nIrrf,cPicE1IRRF)
							EndIf
						EndIf
						
						If !lBq10925
							If !__lPccMR
								cValor := cValor - nPis - nCofins - nCsll
							EndIf
							If !__lIrfMR
								cValor := cValor - IIf ( lIrPjBxCr, nIrrf, 0 )
							EndIf
						EndIf
					
						aArray[nIt,nPosPis]	:= Transf(nPis,cPicE1PIS)
						aArray[nIt,nPosCof]	:= Transf(nCofins,cPicE1COF)
						aArray[nIt,nPosCsl]	:= Transf(nCsll,cPicE1CSL)
					EndIf
				EndIf
				
				If lTodos .And. lPccBxCr .And. ( !lRaRtImp .And. !lRaRtImpMR ) .And. MV_PAR08 == 1
					aArray[nIt,7] := Transf((cValor-nPis-nCofins-nCsll),__cPiE1Sld)
					//Vld para ñ gerar mov.diferentes
					cValor := If(lBq10925, Val(StrTran(aArray[nIt,7], ".", "")), cValor) 
					If !( nMoeda <> SE1->E1_MOEDA .And. cValor == NoRound(aArray[nIt,9], 2) )
						aArray[nIt,9]	 := cValor
					EndIf					 
				Else				
					aArray[nIt,7] := Transf(cValor,__cPiE1Sld)
				EndIf
				
				If cPaisLoc != "RUS" .And. ( !lRaRtImp .Or. ( (__lIrfMR .Or. __lPccMR) .And. !lRaRtImpMR ) )
					If !( nMoeda <> SE1->E1_MOEDA .And. cValor == NoRound(aArray[nIt,9], 2) )
						aArray[nIt,9]	 := cValor
					EndIf
					If MV_PAR02 == 2
						aArray[nIt,nPosPis]	 := Transf(nPis,cPicE1PIS)
						If Len(aArray[nIt]) > 17
							aArray[nIt,nPosCof]	 := Transf(nCofins,cPicE1COF)
							aArray[nIt,nPosCsl]	 := Transf(nCsll,cPicE1CSL)
							aArray[nIt,nPosBPCC] := Transf(nAltVal,cPicE1CSL)
							aArray[nIt,nPosBPCR] := Transf(nAltVal,cPicE1CSL)
							If !lIrPjBxCr
								aArray[nIt,nPosIrf] := Transf( nIrrf, cPicE1IRRF)
							EndIf
						EndIf
					EndIf
				EndIf
				
				If cValor <> nValRec // cvalor é uma variavel numerica
					nValRec	:= cValor
				EndIf
			EndIf
	    Else
			aArray[nIt,8] := !aArray[nIt,8]
			If aArray[nIt,4] $ MV_CRNEG
				F330VALNCC(@aArray,nIt, cValor < cLimite, .F.)
			EndIf
		EndIf
	Else
		If  !aArray[nIt,8]
			aArray[nIt,7] := Transf(0,__cPiE1Sld)
			If cPaisLoc == "BRA"
				aArray[nIt,9] := 0
				If lCredito
					DBSelectArea("SE1")
					If MV_PAR02 == 2
						DBGoTo(aArray[nIt,23])
					Else
				   		DBGoTo(aArray[nIt,20])
				    EndIf
				    
				    //Motor de retenções
					If __lMotRet
						//Verifica as configurações de impostos pelo motor de retenção
						F330VldImp()
											
						lRaRtImpMR 	:= ( __lPccMR .And. __lRaRtPcc ) .Or. ( __lIrfMR .And. __lRaRtIrf ) .Or. ( __lIssMR .And. __lRaRtIss )
						lPccBxCr 	:= ( __lPccMR .And. __lPccBxMR ) .Or. ( !__lPccMR .And. lPccBxAux )
						lIrPjBxCr 	:= ( __lIrfMR .And. __lIrfBxMR ) .Or. ( !__lIrfMR .And. lIrfBxAux )
					EndIf
				    
					If MV_PAR08 == 1 .Or. ( lRaRtImp .Or. lRaRtImpMR )
						nTotAbat := SomaAbat(SE1->E1_PREFIXO,SE1->E1_NUM,SE1->E1_PARCELA,"R",SE1->E1_MOEDA,,SE1->E1_CLIENTE)
					Else
						nTotAbat := 0
					EndIf

					U_F330CalcPCC(nIt,aArray,@cValor+If(cValor==cSalTit,nTotAbat,0),cValor < cLimite)
				EndIf
				
				If lIrPjBxCr .And. lCredito
					If !__lIrfMR
						nIrrf := FCaIrBxCR(aArray[nIt,9])
					Else
						nIrrf := 0
					EndIf
					
					If ( nPosIr := aScan(aImpIR,{|x| x[2]=SE1->(REcno())}) ) = 0
						aAdd(aImpIR,{nIrrf,SE1->(Recno())})
						nPosIr := Len( aImpIR )
					Else
						aImpIR[nPosIr][1] := nIrrf
					EndIf
				EndIf
			EndIf
		EndIf

		FA330UnLock(aArray[nIt,1]+aArray[nIt,2]+aArray[nIt,3]+aArray[nIt,4],,aArray[nIt,IIf(MV_PAR02== 2, 16,13)])

	EndIf
	
Next

For nX:=1 to Len(aArray)
	If	aArray[nX,8]
		nValtot += U_Fa330VTit(aArray[nX,7])
	EndIf
Next

nIt := nOldIt

If oGet != Nil
	oGet:Refresh()
EndIf

If ExistBlock("F330ATLIS")
	ExecBlock("F330ATLIS",.F.,.F., {  , 2 , nValTot, nValor } )
EndIf  

FWRestArea(aAreaSE1)
RestVarMR( aImpMRBrw )

Return aArray

/*
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡„o	 ³U_Fa330SetMo³ Autor ³ Fernando Machima      ³ Data ³ 19/02/01 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡„o ³ Tela de taxas de moedas                                    ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ U_Fa330SetMo												  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
User Function Fa330SetMo(lAutomato)
Local oDlg
Local nLenMoedas	:= Len(aTxMoedas)
Local nI            := 1
Local nLinTelaF
Local nLinTelaD
Local nLinButton
Local aSay := {}
Local aGet := {}
Local cBlKMoeda
Local lExistM := Type("nMoeda") == "N" .And. nMoeda > 1
Default lAutomato := .F.

nLinTelaD	:=  05 + ((nLenMoedas-1) * 16)
nLinTelaF  	:= 200 + ((nLenMoedas-1) * 30.5) + 50
nLinButton  :=  03 + nLinTelaD

If nLenMoedas > 1
	If !lAutomato
		DEFINE MSDIALOG oDlg From 200,0 TO nLinTelaF,230 TITLE STR0037 PIXEL
			@ 005,005  To nLinTelaD,110 OF oDlg PIXEL

			For nI := 1 To nLenMoedas-1
				cBlKMoeda := "{|| aTxMoedas["+AllTrim(Str(ni+1))+",1]}"
				aAdd(aSay, TSay():New(1+(ni*12),010,&cBlKMoeda,oDlg,,, .F., .F., .T.,.T.,,,,, .F., .F., .F., .F.))
				aAdd(aGet, TGet():New((ni*12)-2,060,&("{|x| If(x <> NIL,aTxMoedas["+AllTrim(Str(ni+1))+",2] := x,aTxMoedas["+Str(ni+1)+",2])}"),oDlg,45,,aTxMoedas[nI+1,3],,,,,,,.T.,,,,.F.,.T.,,.F.,.F.,,,,.F.,,.T.))
			Next nI

		DEFINE  SButton FROM (nLinTelaD + 5),80 Type 1 Action (oDlg:End() ) ENABLE OF oDlg  PIXEL
		ACTIVATE MSDIALOG oDlg CENTERED
	EndIf
	If lExistM .And. nI >= nMoeda
		If  !(!__lCmTxCon .And. __lTxConP) //se possui taxa contratada e não gera variação, a taxa de partida não se altera
			__nTxMoedP := aTxMoedas[nMoeda, 2]
			__nTxContr := __nTxMoedP 
			nTxMoeda   := __nTxMoedP
			__lTxMoedP := !Empty(__nTxMoedP)
		EndIf
	EndIf
Else
	Help("",1,"NoMoneda")
EndIf

Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºRotina    ³Fa330TudOkºAutor  ³Claudio D. de Souza º Data ³  29/11/01   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Validar os campos informados na compensacao                º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Fina330                                                    º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function Fa330TudOk(nVlrCompe)

Local lRet := .T.
Default nVlrCompe := 0

Do Case
Case Empty(cNum)
	lRet := .F.
Case !fa330Cli()
	lRet := .F.
Case !Fa330Loja()
	lRet := .F.
Case !(nValor >= 0 .And. Str(nValor,17,2) <= Str(nSaldo,17,2))
	lRet := .F.
Case !(dBaixa >= SE1->E1_EMISSAO)
	lRet := .F.
Case !lCredito
	If Empty(cTipoTit) .Or.	!(!cTipoTit $ MVABATIM .And. 	!(cTipoTit $ MVRECANT+"/"+MV_CRNEG))
		lRet := .F.
	EndIf
Case lCredito
	If Empty(cTipoTit) .Or. !(!cTipoTit $ MVABATIM .And. (cTipoTit $ MVRECANT+"/"+MV_CRNEG))
		lRet := .F.
	EndIf

EndCase

//Possibilita novas validacoes
If ExistBlock("F300VALID")
	lRet := ExecBlock	("F300VALID",.F.,.F.,nVlrCompe)
EndIf

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc}fMarkAll

Marcar todos os títulos da tela

@author Totvs
@since  11/06/2019
@version 12
/*/
//-------------------------------------------------------------------

Static Function fMarkAll(aTit As Array, nValor As Numeric, lEstorno As Logical) As Logical

	Local nI 		As Numeric
	Local nPosMarca As Numeric
	Local lRet 		As Logical
	
	nI 			:= 0
	nPosMarca 	:= 8
	lRet 		:= .T.
	
	Default lEstorno := .F.

	nPosMarca := IIf( lEstorno, 11, nPosMarca )

	If Len(aTit) > 0
		For nI := 1 to Len(aTit)
			If !aTit[nI,nPosMarca]
				lRet := .F.
				If !lEstorno
					aTit[nI][7] := aTit[nI][22]
				EndIf
			EndIf
		Next
	EndIf
	
	If lEstorno
		aEval(@aTit, {|e| e[nPosMarca] := !lRet } )
	Else
		nValTot := 0
		aEval( @aTit, {|e| e[nPosMarca] := !lRet, ;
						   IIf( e[nPosMarca], ( IIf( U_Fa330VTit(e[7]) = 0, e[7] := e[6], Nil ), nValTot += U_Fa330VTit(e[7]),;
						   IIf( cPaisLoc=="BRA", e[9] := DesTrans(e[7]), IIf( MV_PAR02 == 02, e[12] := DesTrans(e[7]), .T. ) ) ),;
						   ( e[7] := Transf(0,"@E 9999,999,999.99"), IIf( cPaisloc=="BRA", e[9] := DesTrans(e[7]), IIf( MV_PAR02 == 02, e[12] := e[7], e[11] := e[7] ) ) ) ) } )
	EndIf

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc}fDsMarkAll

Desmarcar todos os títulos da tela

@author Rodrigo Oliveira
@since  26/06/2019
@version 12
/*/
//-------------------------------------------------------------------

Static Function fDsMarkAll(aTit As Array, nValor As Numeric) As Logical

	Local nI 		As Numeric
	Local nPosMarca As Numeric
	Local lRet 		As Logical
	
	nI 			:= 0
	nPosMarca 	:= 8
	lRet 		:= .T.
	
	nValTot := 0
	aEval( @aTit, {|e| e[nPosMarca] := .F., ;
					   IIf( e[nPosMarca], ( IIf( U_Fa330VTit(e[7]) = 0, e[7] := e[6], Nil ), nValTot += U_Fa330VTit(e[7]),;
					   IIf( cPaisLoc=="BRA", e[9] := DesTrans(e[7]), IIf( MV_PAR02 == 02, e[12] := DesTrans(e[7]), .T. ) ) ),;
					   ( e[7] := Transf(0,"@E 9999,999,999.99"), IIf( cPaisloc=="BRA", e[9] := DesTrans(e[7]), IIf( MV_PAR02 == 02, e[12] := e[7], e[11] := e[7] ) ) ) ) } )

Return lRet

/*
===============================================================================================================================
Programa----------: Fa23Leg
Autor-------------: Igor Melgaço
Data da Criacao---: 28/08/2023
Descrição---------: Cria uma janela contendo a legenda da mBrowse 
Parametros--------: 
Retorno-----------:  
===============================================================================================================================
*/ 
User Function Fa23Leg(nReg)
Local uRetorno := .T.
Local aLegenda := {	{"ENABLE"		, 	STR0051	},; //"Titulo nao Compensado"
				   	{"DISABLE"		, 	STR0052	},; //"Titulo Compensado Totalmente"
					{"BR_AZUL"		,  STR0053	}} //"Titulo Compensado Parcialmente"

If nReg = Nil	// Chamada direta da funcao onde nao passa, via menu Recno eh passado
	uRetorno := {}
	aAdd(uRetorno, {'E1_SALDO =  0', aLegenda[2][1]})			// Titulo Compensado Totalmente
	aAdd(uRetorno, {'E1_SALDO =  E1_VALOR', aLegenda[1][1]}) // Titulo nao Compensado
	aAdd(uRetorno, {'E1_SALDO <> 0', aLegenda[3][1]})			// Titulo Compensado Parcialmente
Else
	BrwLegenda(cCadastro,STR0047,aLegenda)  //"Legenda"
EndIf

Return uRetorno

/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³U_PesqListBox³ Autor ³ Edson Maricate       ³ Data ³ 09.02.06 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Monta uma pesquisa de texto em um listBox.                 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ Geral                                                      ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
User Function PesqListBox(oListBox,aListBox)

Local nFound
Local aParam	:= {}

Private MV_PAR01 // Declara as variaveis Private para não conflitar com as variaveis da pergunte
Private MV_PAR02
Private MV_PAR03

If ParamBox( { { 1,STR0001 ,PadR(__PesqList,200),"@" 	 ,""  ,""    ,"" ,120 ,.T. },;
				{5,STR0056,.F.,90,,.F.},;
				{5,STR0057,.F.,90,,.F.} }, STR0001 , aParam, , , , , , , , .F. )

	__PesqList := aParam[1]
	If aParam[2]
		If aParam[3]
			nFound := aScan(aListBox,{|x| aScan(x,{|x| AllTrim(aParam[1])$AllTrim(x) } )>0 },oListBox:nAt+1)
		Else
			nFound := aScan(aListBox,{|x| aScan(x,{|x| AllTrim(aParam[1])$AllTrim(x) } )>0 })
		EndIf
	Else
		If aParam[3]
			nFound := aScan(aListBox,{|x| aScan(x,{|x| Upper(AllTrim(aParam[1]))$Upper(AllTrim(x)) } )>0 },oListBox:nAt+1)
		Else
			nFound := aScan(aListBox,{|x| aScan(x,{|x| Upper(AllTrim(aParam[1]))$Upper(AllTrim(x)) } )>0 })
		EndIf
	EndIf
	If nFound <= 0
		Aviso(STR0058, STR0059,{"Ok"},2)
	Else
		oListBox:nAt := nFound
		oListBox:Refresh()
	EndIf

EndIf

Return

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Programa  ³MenuDef   ³ Autor ³ Ana Paula N. Silva     ³ Data ³23/11/06 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Utilizacao de menu Funcional                               ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³Array com opcoes da rotina.                                 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³Parametros do array a Rotina:                               ³±±
±±³          ³1. Nome a aparecer no cabecalho                             ³±±
±±³          ³2. Nome da Rotina associada                                 ³±±
±±³          ³3. Reservado                                                ³±±
±±³          ³4. Tipo de Transa‡„o a ser efetuada:                        ³±±
±±³          ³	  1 - Pesquisa e Posiciona em um Banco de Dados           ³±±
±±³          ³    2 - Simplesmente Mostra os Campos                       ³±±
±±³          ³    3 - Inclui registros no Bancos de Dados                 ³±±
±±³          ³    4 - Altera o registro corrente                          ³±±
±±³          ³    5 - Remove o registro corrente do Banco de Dados        ³±±
±±³          ³5. Nivel de acesso                                          ³±±
±±³          ³6. Habilita Menu Funcional                                  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³   DATA   ³ Programador   ³Manutencao efetuada                         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³          ³               ³                                            ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Static Function MenuDef()
Local lFA330LIB := Existblock("FA330LIB")
Local aRetorno  := {}
Local aRotina   := { {STR0001, "AxPesqui"    , 0, 1,, .F. },;  //"Pesquisar"
	                  {STR0002, "AxVisual"    , 0, 2 },;        //"Visualizar"
	                  {STR0003, "U_Fa23Comp"  , 0, 3 },;        //"Compensar"
 	                  {STR0004, "Fa330Desc" 	, 0, 4 },;        //"Excluir"
 	                  {STR0054, "Fa330Desc" 	, 0, 4 },;        //"Estornar"
 	                  {STR0047, "U_Fa23Leg"   , 0, 2,, .F.} }   //"Legenda"

If lFA330LIB
	aRetorno := ExecBlock("FA330LIB",.F.,.F.,{aRotina})
	aRotina := AClone(aRetorno)
EndIf

Return(aRotina)

//------------------------------------------------------------------------------------------------------------------------------------------------

Static Function FA330aUnlock()
Local aArea := FWGetArea()
If aRLocks == Nil
	aRLocks:={}
EndIf
//**********************************************
// Retirado para permitir utilizacao de rotina *
// automatica dentro de transacao no banco     *
//**********************************************
//AEval(aRLocks,{|x,y| SE1->(MsRUnlock(x))})
AEval(aRLocks,{|x,y| SE1->(DBGoTo(x)),MSUnLock() })
aRLocks:={}
FWRestArea(aArea)
Return

//------------------------------------------------------------------------------------------------------------------------------------------------

Static Function FA330Unlock(cChave,nRecno,cfilorig)
Local aArea
Local nPosRec

If aRLocks == Nil
	aRLocks:={}
EndIf
If nRecno <> Nil
	SE1->(MsGoto(nRecno))
Else
	aArea	:=	FWGetArea()
	SE1->(DBSetOrder(1))
	SE1->(MsSeek(cfilorig+cChave))
EndIf

//**********************************************
// Retirado para permitir utilizacao de rotina *
// automatica dentro de transacao no banco     *
// **********************************************
//SE1->(MsRUnlock(SE1->(Recno())))
SE1->(MSUnLock())

If (nPosRec:=aScan(aRLocks,SE1->(REcno()))) > 0
	Adel(aRlocks,nPosRec)
	aSize(aRlocks,Len(aRlocks)-1)
EndIf

If aArea <> Nil
	FWRestArea(aArea)
EndIf

Return

//------------------------------------------------------------------------------------------------------------------------------------------------

Static Function FA330Lock(cChave,nRecno,lHelp,cfilOrig)
Local aArea
Local lRet	:=	.F.
DEFAULT lHelp	:=	.T.

If aRLocks == Nil
	aRLocks:={}
EndIf

If nRecno <> Nil
	SE1->(MsGoto(nRecno))
Else
	aArea	:=	SE1->(getArea())
	SE1->(DBSetOrder(1))
	SE1->(MsSeek(cfilorig+cChave))
EndIf

If  SE1->(RecLock("SE1",.F.))
	aAdd(aRLocks, SE1->(Recno()))
	lRet	:=	.T.
ElseIf lHelp
	MsgAlert(STR0060)
EndIf

If aArea <> Nil
	FWRestArea(aArea)
EndIf

Return lRet


/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³U_FinA330T ³ Autor ³ Marcelo Celi Marques ³ Data ³ 27.03.08 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Chamada semi-automatica utilizado pelo gestor financeiro   ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ FINA330                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
User Function FinA330T(aParam)

	cRotinaExec := "FINA330"
	ReCreateBrow("SE1",FinWindow)
	FinA330(aParam[1])
	FinVisual(FinWindow:cAliasFile,FinWindow,(FinWindow:cAliasFile)->(Recno()),.T.)
	ReCreateBrow("SE1",FinWindow)
	DBSelectArea("SE1")

	INCLUI := .F.
	ALTERA := .F.

Return .T.

//------------------------------------------------------------------------------------------------------------------------------------------------

//------------------------------------------------------------------------------------------------------------------------------------------------

User Function F330CalcPCC( nIt, aArray, cValor, lAltValor )

Local nPosPis := 14		//Posicao Pis na Tela
Local nPosCof := 15		//Posicao Cofins na Tela
Local nPosCsl := 16		//Posicao Csll na Tela
Local nPVRPis := 17		//Posicao Valor Retido Pis na Tela
Local nPVRCof := 18		//Posicao Valor Retido Cofins na Tela
Local nPVRCsl := 19		//Posicao Valor Retido Csll na Tela
Local nPosRec := 20		//Posicao Recno na Tela
Local nPisJaRet := 0
Local nPisARet := 0
Local nCofJaRet := 0
Local nCofARet := 0
Local nCslJaRet := 0
Local nCslARet := 0
Local nX	:= 0
Local cRetCli := "1"
Local lPccBxCr	:= FPccBxCr()
Local nPropPcc	:= 0
Local nVlrTitSel	:= 0  
Local nValPcc	:= 0  
Local ni	:= 0    
Local nRecTit	:= 0
Local nTotAdto		:= 0
Local lBaixaAbat	:= .F.
Local nVlrBaixa		:= 0
Local lBxCec		:= .F.
Local lBxLiq		:= .F.
Local lSigaloja		:= .F.
Local lTipBxCP  	:= .F.
Local nTAbt			:= 0
Default lAltValor := .F.

lPccBxCr := ( __lPccMR .And. __lPccBxMR ) .Or. ( !__lPccMR .And. lPccBxCr )

If cPaisLoc == "BRA" .And. lPccBxCr
	//Caso considere diferentes clientes
	If MV_PAR02 == 2
		nPosPis := 17
		nPosCof := 18
		nPosCsl := 19
		nPVRPis := 20		//Posicao Valor Retido Pis na Tela
		nPVRCof := 21		//Posicao Valor Retido Cofins na Tela
		nPVRCsl := 22		//Posicao Valor Retido Csll na Tela
		nPosRec := 23
		nPosBPCC := 27
		nPosBPCR := 28
	EndIf

	SE1->( DBGoTo( aArray[nIt, nPosRec] ) )
	nValrec := cValor 	//Esta variavel esta numerica apesar da notacao.
	nOldValRec := nValRec

	If !__lPccMR
	
		cRetCli := IIf(Empty(SA1->A1_ABATIMP),"1",SA1->A1_ABATIMP)
	
		If aArray[nIt,8]
			If cRetCli == "1"  //Calculo do sistema
				nValRecAtu := nValRec
				For nX := nIt To Len(aArray)
					If	aArray[nX,8]
						nValRec   += U_Fa330VTit(aArray[nX,7])
						If MV_PAR08 == 2
							nValRec   += U_Fa330VTit(aArray[nX,nPosPis])
							nValRec   += U_Fa330VTit(aArray[nX,nPosCof])
							nValRec   += U_Fa330VTit(aArray[nX,nPosCsl])
							nPisJaRet += U_Fa330VTit(aArray[nX,nPosPis])
							nPisARet  += U_Fa330VTit(aArray[nX,nPVRPis])
							nCofJaRet += U_Fa330VTit(aArray[nX,nPosCof])
							nCofARet  += U_Fa330VTit(aArray[nX,nPVRCof])
							nCslJaRet += U_Fa330VTit(aArray[nX,nPosCsl])
							nCslARet  += U_Fa330VTit(aArray[nX,nPVRCsl])
						EndIf
					EndIf
				
					If (Len(aArray) > nX)
						If aArray[(nX+1),8]
							Exit
						EndIf
					EndIf			
				Next
	
				nVlrTitSel := nValRec
				If ( nPisJaRet + nCofJaRet + nCslJaRet ) > 0
					nValRec    := nOldValRec
				EndIf
				
				aBaixa := Sel070Baixa( "VL /V2 /BA /RA /CP /LJ /" + MV_CRNEG, SE1->E1_PREFIXO,SE1->E1_NUM, SE1->E1_PARCELA, SE1->E1_TIPO,;
					                   @nTotAdto, @lBaixaAbat, SE1->E1_CLIENTE, SE1->E1_LOJA, @nVlrBaixa, , @lBxCec, @lBxLiq ,@lSigaloja ,@lTipBxCP)
				
				nTAbt	:= SomaAbat(SE1->E1_PREFIXO,SE1->E1_NUM,SE1->E1_PARCELA,"R",SE1->E1_MOEDA,,SE1->E1_CLIENTE,,SE1->E1_FILIAL)
				
				If dDataBase < dLastPcc
					f070TotMes(dBaixa,.T.)
				Else
					If lAltValor
						nValPcc	:= nValRec
					Else
						nValPcc	:= SE1->E1_VALOR - nTotAdto
					EndIf	
					aPcc		:= newMinPcc(dBaixa,nValPcc,SE1->E1_NATUREZ,"R",SE1->E1_CLIENTE+SE1->E1_LOJA)
					nPis	:= aPcc[2]
					nCofins	:= aPcc[3]
					nCsll	:= aPcc[4]
					If !lAltValor .And. !lRartimp .And. MV_PAR08 == 1 .And. !lCredito /*SE1->E1_TIPO == MVNOTAFIS*/ .And. (SE1->E1_SALDO - IIf(lPccBxCr,0,nPis - nCofins - nCsll) - nTAbt <> nValRec )//.and. SE1->E1_SALDO - nPis - nCofins - nCsll - nTAbt == SE1->E1_SALDO) // compensado pelo valor liquido 
						nValPcc	:= nValRec
						aPcc	:= newMinPcc(dBaixa,nValPcc,SE1->E1_NATUREZ,"R",SE1->E1_CLIENTE+SE1->E1_LOJA)
						nPis	:= aPcc[2]
						nCofins	:= aPcc[3]
						nCsll	:= aPcc[4]
					EndIf
					//Reestruturacao SE5 - Para gravação das tabelas FK3 e FK4
					nPisCalc	:= nPis
					nPisBaseC	:= nValPcc	
					nPisBaseR 	:= nValPcc
					nCofCalc	:= nCofins	
					nCofBaseC	:= nValPcc
					nCofBaseR 	:= nValPcc
					nCslCalc	:= nCsll	
					nCslBaseC	:= nValPcc
					nCslBaseR 	:= nValPcc
				EndIf
				nValRec    	:= nVlrTitSel
				nOldvalRec	:= nVlrTitSel
	
				If dDataBase < dLastPcc
					If ( MV_PAR08 == 1 .Or. lRaRtImp ) .And. ( lAltValor .Or. nValRecAtu < SE1->E1_SALDO );
					.And. (!lRaRtImp .And. (nValRecAtu+(nCofins+nCsll+nPis+nIrrf+nTAbt))< SE1->E1_SALDO)
						
						nPropPcc 	:= (nValRecAtu*(nCofins+nCsll+nPis))/SE1->E1_VLCRUZ
						nPropPcc 	:= (nPropPcc/ (nCofins+nCsll+nPis) )
						nPis		:= Round(NoRound(SE1->E1_PIS * nPropPCC,3),2)
						nCofins		:= Round(NoRound(SE1->E1_COFINS * nPropPCC,3),2)
						nCsll		:= Round(NoRound(SE1->E1_CSLL * nPropPCC,3),2)
						nPisBaseR 	:= Round(NoRound(SE1->E1_BASEPIS * nPropPCC,3),2)
						nPisBaseC 	:= Round(NoRound(SE1->E1_BASEPIS * nPropPCC,3),2)
		
						nValRec := nValRecAtu
					Else
						nValRec := nValRecAtu
						nPis 	:= nPis + nPisARet - nPisJaRet
						nCofins := nCofins + nCofARet - nCofJaRet
						nCsll 	:= nCsll + nCslARet - nCslJaRet
					EndIf
				EndIf
	
			ElseIf cRetCli == "2"	//Sempre calcula
				nPropPcc 	:= nValrec/SE1->E1_VLCRUZ
				nPis		:= Round(NoRound(SE1->E1_PIS * nPropPCC,3),2)
				nCofins		:= Round(NoRound(SE1->E1_COFINS * nPropPCC,3),2)
				nCsll		:= Round(NoRound(SE1->E1_CSLL * nPropPCC,3),2)
				nPisBaseR 	:= Round(NoRound(SE1->E1_BASEPIS * nPropPCC,3),2)
				nPisBaseC 	:= Round(NoRound(SE1->E1_BASEPIS * nPropPCC,3),2)
				nVlRetPis	:= nPis
				nVlRetCof	:= nCofins
				nVlRetCsl	:= nCsll
				nValRec		-= (nPis+nCofins+nCsll)
			Else
				nPis		:= 0
				nCofins		:= 0
				nCsll		:= 0
				nVlRetPis	:= 0
				nVlRetCof	:= 0
				nVlRetCsl	:= 0
			EndIf
		Else
			nPis		:= 0
			nCofins		:= 0
			nCsll		:= 0
			nVlRetPis	:= 0
			nVlRetCof	:= 0
			nVlRetCsl	:= 0
		EndIf

		cValor	:= nValRec
	
	Else
		
		If !aArray[nIt,8]
			nPis 	:= 0
			nCofins	:= 0
			nCsll 	:= 0
		EndIf
		
	EndIf
	
	If MV_PAR08 == 1
		aArray[nIt,nPosPis] := Transform(nPis,"@E 99,999,999.99")
		aArray[nIt,nPosCof] := Transform(nCofins,"@E 99,999,999.99")
		aArray[nIt,nPosCsl] := Transform(nCsll,"@E 99,999,999.99")
	EndIf
	
	If !__lPccMR
		aArray[nIt,nPosBPCC] := Transform(nPisBaseC,"@E 99,999,999.99")
		aArray[nIt,nPosBPCR] := Transform(nPisBaseR,"@E 99,999,999.99")
	EndIf
	
	If MV_PAR02 == 2
		If !__lPccMR
			aArray[nIt,nPVRPis] := Transform(nVlRetPis,"@E 99,999,999.99")
			aArray[nIt,nPVRCof] := Transform(nVlRetCof,"@E 99,999,999.99")
			aArray[nIt,nPVRCsl] := Transform(nVlRetCsl,"@E 99,999,999.99")
		Else
			aArray[nIt,nPVRPis] := Transform(nPis,"@E 99,999,999.99")
			aArray[nIt,nPVRCof] := Transform(nCofins,"@E 99,999,999.99")
			aArray[nIt,nPVRCsl] := Transform(nCsll,"@E 99,999,999.99")
		EndIf
	EndIf
	
	For ni := 1 To Len(aTitulos)
		nRecTit	:= Recno()
		If ValType(aTitulos[ni,20]) <> "C"
			If nRecTit == aTitulos[ni][20]
				aTitulos[ni][14]	:= aArray[nIt,nPosPis]
				aTitulos[ni][15]	:= aArray[nIt,nPosCof]
				aTitulos[ni][16]	:= aArray[nIt,nPosCsl]
			EndIf
		EndIf
	Next		
EndIf

Return

//------------------------------------------------------------------------------------------------------------------------------------------------


//--------------------------------------------------------------------------------

User Function F330Button(lPccBxCr,oTitulo,oGet01,lMarkAll)

Default lMarkAll := .F. 
nValTot := 0

If (lPccBxCr .And. lCredito) 
	aTitulos := FA330Troca(oTitulo:nAt,aTitulos,oGet01,.T.,,lMarkAll)
Else
	If lMarkAll  // Marca Todos 
		//FA330Lock(cChave,nRecno,lHelp,cfilOrig)
	   //aEval(aTitulos, {|e| IIf(Fa330Lock(e[1]+e[2]+e[3]+e[4],,,IIf(MV_PAR02== 2, e[16],e[13]),.F.), (e[8] := .T.) , Nil ), If(e[8],(If(U_Fa330VTit(e[7])=0,e[7]:=e[6],Nil),nValTot += U_Fa330VTit(e[7]),e[9]:=DesTrans(e[7])),(e[7]:=Transf(0,"@E 9999,999,999.99"), e[9]:=DesTrans(e[7]) ))})
	   //aEval(aTitulos, {|e| IIf(Fa330Lock(e[1]+e[2]+e[3]+e[4],,,IIf(MV_PAR02== 2, e[16],e[13]),.F.), (e[8] := .T.) , Nil ), If(e[8],(If(U_Fa330VTit(e[7])=0,e[7]:=e[6],Nil),nValTot += U_Fa330VTit(e[7]),e[9]:=DesTrans(e[7])),(e[7]:=Transf(0,"@E 9999,999,999.99"), e[9]:=DesTrans(e[7]) ))})
		aEval(aTitulos, {|e| IIf(Fa330Lock(e[1]+e[2]+e[3]+e[4],,,IIf(MV_PAR02== 2, e[16],e[13])), (e[8] := .T.) , Nil ), If(e[8],(If(U_Fa330VTit(e[7])=0,e[7]:=e[6],Nil),nValTot += U_Fa330VTit(e[7]),e[9]:=DesTrans(e[7])),(e[7]:=Transf(0,"@E 9999,999,999.99"), e[9]:=DesTrans(e[7]) ))})
		aEval(aTitulos, {|e| IIf(Fa330Lock(e[1]+e[2]+e[3]+e[4],,,IIf(MV_PAR02== 2, e[16],e[13])), (e[8] := .T.) , Nil ), If(e[8],(If(U_Fa330VTit(e[7])=0,e[7]:=e[6],Nil),nValTot += U_Fa330VTit(e[7]),e[9]:=DesTrans(e[7])),(e[7]:=Transf(0,"@E 9999,999,999.99"), e[9]:=DesTrans(e[7]) ))})
	Else
	   //aEval(aTitulos, {|e| IIf(!e[8].And.Fa330Lock(e[1]+e[2]+e[3]+e[4],,,IIf(MV_PAR02== 2, e[16],e[13]),.F.), (e[8] := .T.) , If(e[8], (Fa330UnLock(e[1]+e[2]+e[3]+e[4],,IIf(MV_PAR02== 2, e[16],e[13]),.F.),e[8] := .F. ),Nil)       ), If(e[8],(If(U_Fa330VTit(e[7])=0,e[7]:=e[6],Nil),nValTot += U_Fa330VTit(e[7]),e[9]:=DesTrans(e[7])),(e[7]:=Transf(0,"@E 9999,999,999.99"), e[9]:=DesTrans(e[7]) ))})
		aEval(aTitulos, {|e| IIf(!e[8].And.Fa330Lock(e[1]+e[2]+e[3]+e[4],,,IIf(MV_PAR02== 2, e[16],e[13])), (e[8] := .T.) , If(e[8], (Fa330UnLock(e[1]+e[2]+e[3]+e[4],,IIf(MV_PAR02== 2, e[16],e[13])),e[8] := .F. ),Nil)       ), If(e[8],(If(U_Fa330VTit(e[7])=0,e[7]:=e[6],Nil),nValTot += U_Fa330VTit(e[7]),e[9]:=DesTrans(e[7])),(e[7]:=Transf(0,"@E 9999,999,999.99"), e[9]:=DesTrans(e[7]) ))})
	EndIf
EndIf

oTitulo:Refresh()
oGet01:Refresh()

Return


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³U_Fa330VldDtºAutor  ³ Clovis Magenta     º Data ³  13/01/11   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Consiste MV_DATAFIN antes de cancelar baixa/compensação    º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ AP                                                         º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
User Function Fa330VldDt(aArray, nOpc)
Local lRet := .T.
DEFAULT nOpc := 5

If lRet .And. SuperGetMv("MV_BXDTFIN",,"1") == "2"
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ A data da baixa deve ser passada como parametro, pois tanto ³
	//³ o cancelamento como a exclusao devem ser validados pela     ³
	//³ data de baixa e nao pela data base do sistema.              ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If nOpc == 4  //Exclusao
		lRet := DtMovFin(CtoD(aArray[06]),!l330Auto,"2")
	Else
		lRet := DtMovFin( ,!l330Auto,"2")
	EndIf

EndIf

Return lRet

/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³U_Fa330TxMd  ³ Autor ³ Cristiano Denardi    ³ Data ³ 05.04.05 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Busca Taxa em aTxMoedas e verifica se foi trocada          ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ FINA330                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
User Function Fa330TxMd( nMoeda2, nTx ,lAcrDes)

Local lExistTxMd	:= Type("aTxMoedas")#"U" .And. Len(aTxMoedas) > 0

Default nTx			:= 0
Default nMoeda2 	:= 0
Default lAcrDes		:= .F.

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Estrutura aTxMoedas         ³
//³ [1] -> Nome Moeda          	³
//³ [2] -> Taxa a Ser Utilizada	³
//³ [3] -> Picture          	³
//³ [4] -> Taxa do dia atual    ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

If nMoeda2 > 0 .And. lExistTxMd .And. (nMoeda2<>SE1->E1_MOEDA)
	If aTxMoedas[nMoeda2][2] <> aTxMoedas[nMoeda2][4] .And. (aTxMoedas[nMoeda2][2]<>0)
		nTx := aTxMoedas[nMoeda2][2]
	ElseIf (nTx <> aTxMoedas[nMoeda2][4]) .And. (aTxMoedas[nMoeda2][4]<>0)
		nTx := aTxMoedas[nMoeda2][4]
	EndIf
ElseIf (nMoeda2==SE1->E1_MOEDA)
	// se a moeda do titulo principal é 2 e a do titulo posicionado tb, nao convertemos pois os valores serao expressos em U$
	If !lAcrDes
		nTx := 1
	EndIf
EndIf

Return( nTx )

/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³U_Fa330Tx2  ³ Autor ³ Clovis Magenta       ³ Data ³ 31.08.11 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Busca Taxa em aTxMoedas e verifica se foi trocada          ³±±
±±³Descri‡…o ³ Funcao copiada da Fa340TxMd pois a U_Fa330TxMd() nao obtem   ³±±
±±³Descri‡…o ³ resultado satisfatorio para alguns casos de conversao      ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ FINXATU                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
User Function Fa330Tx2( nMoeda2, nTx )

Local lExistTxMd	:= Type("aTxMoedas")#"U" .And. Len(aTxMoedas) > 0
Default nTx			:= 0
Default nMoeda2 	:= 0

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Estrutura aTxMoedas         ³
//³ [1] -> Nome Moeda          	³
//³ [2] -> Taxa a Ser Utilizada	³
//³ [3] -> Picture          	³
//³ [4] -> Taxa do dia atual    ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ/

// Esta função só deve ser chamada pela rotina de compensação a pagar
If nMoeda2 > 0 .And. lExistTxMd .And. (__lCmTxCon .And. SE1->E1_TXMOEDA > 0)
	If aTxMoedas[nMoeda2][2] <> aTxMoedas[nMoeda2][4] .And. (aTxMoedas[nMoeda2][2]<>0)
		nTx := aTxMoedas[nMoeda2][2]
	ElseIf (nTx == 0)
		nTx := aTxMoedas[nMoeda2][4]
	EndIf
EndIf

If SE1->E1_TXMOEDA == 0 .And. nMoeda2 > 1
	If nTx <> __nTxMoedP .And. __nTxMoedP > 0
		nTx := __nTxMoedP
	EndIf
EndIf 

Return( nTx )




/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³FINA330   ºAutor  ³TOTVS          º Data ³  05/15/13  	 º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³  Acumula os impostos para compor o aTitulos                º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ FINA330                                                   º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

Static Function F330RaRtIm(aDadosRA1,cValDig,nItemRA,nItemOU, lAltValor)

Local aArea	  		:= FWGetArea()
Local lRet			:= .T.
Local nBaseRA  		:= 0
Local nSaldoRA 		:= 0
Local nPisRA		:= 0
Local nCofRA		:= 0
Local nCslRA		:= 0
Local nIrfRA		:= 0
Local nBasOUIr		:= 0
Local nBasOUPis 	:= 0
Local nBasOUCof 	:= 0
Local nBasOUCsl 	:= 0
Local nBasOUIns 	:= 0
Local nBasOUIss 	:= 0
Local nSaldoOU 		:= 0
Local nPisOU		:= 0
Local nCofOU		:= 0
Local nCslOU		:= 0
Local nIrfOU		:= 0
Local nPrIsRA		:= 0     // Provisionamento de ISS e INSS
Local nPrIsOU		:= 0     // Provisionamento de ISS e INSS
Local nPrInRA		:= 0     // Provisionamento de ISS e INSS
Local nPrInOU		:= 0     // Provisionamento de ISS e INSS
Local nTxIr 		:= 1
Local nTxPis 		:= 1
Local nTxCof		:= 1
Local nTxCsl		:= 1
Local nTxIns		:= 1
Local nTxIss		:= 1
Local nTxSaldo		:= 1
Local ni 			:= 0
Local nItLcRA		:= 0
Local nItLcOU		:= 0
Local nSaldoCMP		:= 0
Local nProp			:= 1
Local nPropPis		:= 1
Local nPropCof		:= 1
Local nPropCsl		:= 1
Local nPropIr		:= 1
Local nPropIss		:= 1
Local nPropIns		:= 1

Default cValDig	:= 0
Default nItemRA	:= 0
Default nItemOU	:= 0
Default lAltValor := .F.

If nItemRA <> 0
	nItLcRA := nItemRA
Else
	nItLcRA := Len(aDadosRA1[1])
EndIf

If aDadosRA1[1][nItLcRA] <> 0
	SE1->(DBGoTo(aDadosRA1[1][nItLcRA]))
	If SE1->E1_SALDO <> SE1->E1_VALOR //indica que houve baixa parcial
		nProp := SE1->E1_SALDO/SE1->E1_VALOR
	EndIf
	nBaseRA 	:= SE1->E1_BASEIRF * nProp
	nSaldoRA 	:= SE1->E1_SALDO
	If lRaRtImp 
		nSaldoRA += (SE1->E1_PRISS * nProp)+ (SE1->E1_PRINSS* nProp)
		nPrIsRA  := SE1->E1_PRISS * nProp
		nPrInRA	 := SE1->E1_PRINSS * nProp
	EndIf

	If lCredito
		nSaldoCMP := SE1->E1_SALDO
	EndIf

	If cValDig <> 0 .And. cValDig <> nSaldoRA .And. lAltValor
		nSaldoRA := cValdig
	EndIf

	SE5->(DBSetOrder(2))
	SE5->(DBSeek( xFilial("SE5")+"RA"+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+SE1->E1_TIPO))
	While (SE5->(!Eof()) .And. xFilial("SE5") == SE5->E5_FILIAL .And.	;
			SE5->E5_TIPODOC == "RA" .And. 				;
			SE5->E5_PREFIXO == SE1->E1_PREFIXO .And.				;
			SE5->E5_NUMERO == SE1->E1_NUM .And.					;
			SE5->E5_PARCELA == SE1->E1_PARCELA )

		If SE5->E5_RECPAG != "R"
			SE5->(DBSkip())
			Loop
		EndIf

		//Verifica se tem baixa cancelada
		If TemBxCanc(SE5->(E5_PREFIXO+E5_NUMERO+E5_PARCELA+E5_TIPO+E5_CLIFOR+E5_LOJA+E5_SEQ),.T.,SE5->E5_FILIAL)
			SE5->(DBSkip())
			Loop
		EndIf

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Verifica Cliente 	³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If SE5->E5_CLIFOR != SE1->E1_CLIENTE
			SE5->(DBSkip( ))
			Loop
		EndIf

		If SE5->E5_PRETPIS <> " "
			nPisRA		:= 0
		Else
			nPisRA		:= SE5->E5_VRETPIS * nProp
		EndIf
		If SE5->E5_PRETCSL <> " "
			nCslRA		:= 0
		Else
			nCslRA		:= SE5->E5_VRETCSL* nProp
		EndIf
		If SE5->E5_PRETCOF <> " "
			nCofRA		:= 0
		Else
			nCofRA		:= SE5->E5_VRETCOF* nProp
		EndIf
		If SE5->E5_PRETIRF <> " "
			nIrfRA		:= 0
		Else
			nIrfRA		:= SE5->E5_VRETIRF	* nProp
		EndIf

		Exit

	EndDo

	If Len(aDadosRA1[8]) > 0 .And. lCredito
		For ni := 1 to Len(aDadosRA1[8])
			nSaldoCMP -= aDadosRA1[8][ni]
		Next ni
	EndIf

	If Round(nSaldoRa+nPisRA+nCofRA+nCslRA+nIrfRA,2) <> Round(nBaseRA,2) .And. nBaseRA <> 0
		nTxSaldo	:= nSaldoRA/nBaseRA//-(nPisRA+nCofRA+nCslRA+nIrfRA)))
		nPisRA		:= Round(nPisRA*nTxSaldo,2)
		nCofRA		:= Round(nCofRA*nTxSaldo,2)
		nCslRA		:= Round(nCslRA*nTxSaldo,2)
		nIrfRA		:= Round(nIrfRA*nTxSaldo,2)
		nPrIsRA		:= Round(nPrIsRA*nTxSaldo,2)
		nPrInRA		:= Round(nPrInRA*nTxSaldo,2)
		nBaseRA		:= nSaldoRa//+nPisRA+nCofRA+nCslRA+nIrfRA+nPrIsRA+nPrInRA)
	EndIf

	If nItemOU <> 0
		nItLcOU := nItemOU
	Else
		nItLcOU := Len(aDadosRA1[2])
	EndIf

	If lRaRtImp .And. !lAltValor 
		nSaldoRA -= (SE1->E1_PRISS*nProp)+ (SE1->E1_PRINSS *nProp)
	EndIf
	nProp:=1
	If aDadosRA1[2][nItLcOU] <> 0 
		SE1->(DBGoTo(aDadosRA1[2][nItLcOU]))
		If SE1->E1_SALDO <> SE1->E1_VALOR //indica que houve baixa parcial			
			nPropPis	:= SE1->E1_SALDO/SE1->E1_BASEPIS
			nPropCof	:= SE1->E1_SALDO/SE1->E1_BASECOF
			nPropCsl	:= SE1->E1_SALDO/SE1->E1_BASECSL
			nPropIr		:= SE1->E1_SALDO/SE1->E1_BASEIRF
			nPropIss	:= SE1->E1_SALDO/SE1->E1_BASEISS
			nPropIns	:= SE1->E1_SALDO/SE1->E1_BASEINS
		EndIf

		nBasOUPis 	:= SE1->E1_BASEPIS * nPropPis
		nBasOUCof 	:= SE1->E1_BASECOF * nPropCof
		nBasOUCsl 	:= SE1->E1_BASECSL * nPropCsl
		nBasOUIr 	:= SE1->E1_BASEIRF * nPropIr		
		nBasOUIss 	:= SE1->E1_BASEISS * nPropIss
		nBasOUIns 	:= SE1->E1_BASEINS * nPropIns

		If MV_PAR08 == 1 .And. !lRaRtImp
			nSaldoOU	:= SE1->E1_SALDO-(SE1->(E1_PIS+E1_COFINS+E1_CSLL+E1_IRRF)*nProp)
		Else
			nSaldoOU	:= SE1->E1_SALDO
		EndIf
		nPisOU		:= SE1->E1_PIS * nProp
		nCofOU		:= SE1->E1_COFINS* nProp
		nCslOU		:= SE1->E1_CSLL* nProp
		nIrfOU		:= SE1->E1_IRRF* nProp
		
		If lRaRtImp
			nSaldoOU -= ((SE1->E1_ISS* nProp)+ (SE1->E1_INSS* nProp))
			nPrIsOU	 := SE1->E1_ISS * nProp
			nPrInOU	 := SE1->E1_INSS* nProp
		EndIf

		If !lCredito .And. !lRaRtImp .And. !IsInCallStack("FA330Troca")
			nSaldoCMP := SE1->E1_SALDO-SE1->(E1_PIS+E1_COFINS+E1_CSLL+E1_IRRF)
		ElseIf !lCredito
		 	nSaldoCMP := SE1->E1_SALDO
		EndIf


		If cValDig <> 0 .And. cValDig <> nSaldoOU
			nSaldoOU := cValdig
		EndIf

		If Len(aDadosRA1[8]) > 0 .And. !lCredito
			For ni := 1 to Len(aDadosRA1[8])
				If aDadosRA1[1][nItLcRA] <> aDadosRA1[1][ni] .And. aDadosRA1[9][ni]
					If aTitulos[ni][9] == aDadosRA1[8][ni]
						nSaldoCMP -= aDadosRA1[8][ni] + aDadosRA1[3][ni] + aDadosRA1[4][ni] + aDadosRA1[5][ni] + aDadosRA1[6][ni] + aDadosRA1[10][ni] + aDadosRA1[11][ni]
					Else
						nSaldoCMP -= aDadosRA1[8][ni]
					EndIf 	
				EndIf 		 
			Next ni
		EndIf
		
		If cValDig <> 0 .And. cValDig <> nSaldoRA .And. lRaRtImp .And. IsInCallStack("FA330Troca") .And. !lCredito
			nBaseRA:= nSaldoCMP 
		EndIf 	


		If lCredito
			nTxPis 		:= IIf( (nBasOUPis/nBaseRA) > 1 , 1 , (nBasOUPis/nBaseRA) )
			nTxCof		:= IIf( (nBasOUCof/nBaseRA) > 1 , 1 , (nBasOUCof/nBaseRA) )
			nTxCsl		:= IIf( (nBasOUCsl/nBaseRA) > 1 , 1 , (nBasOUCsl/nBaseRA) )
			nTxIr 		:= IIf( (nBasOUIr/nBaseRA)  > 1 , 1 , (nBasOUIr/nBaseRA)  )
			nTxIss		:= IIf( (nBasOUIss/nBaseRA) > 1 , 1 , (nBasOUIss/nBaseRA) )
			nTxIns		:= IIf( (nBasOUIns/nBaseRA) > 1 , 1 , (nBasOUIns/nBaseRA) )				
		Else
			nTxPis 		:= IIf( (nBaseRA/nBasOUPis) > 1 , 1 , (nBaseRA/nBasOUPis) )
			nTxCof		:= IIf( (nBaseRA/nBasOUCof) > 1 , 1 , (nBaseRA/nBasOUCof) )
			nTxCsl		:= IIf( (nBaseRA/nBasOUCsl) > 1 , 1 , (nBaseRA/nBasOUCsl) )
			nTxIr 		:= IIf( (nBaseRA/nBasOUIr)  > 1 , 1 , (nBaseRA/nBasOUIr)  )
			nTxIss		:= IIf( (nBaseRA/nBasOUIss) > 1 , 1 , (nBaseRA/nBasOUIss) )
			nTxIns		:= IIf( (nBaseRA/nBasOUIns) > 1 , 1 , (nBaseRA/nBasOUIns) )			
		EndIf

		If lCredito
			nPisOU		:= If(nPisRA<>0,Round(nPisRA*nTxPis,2),Round(nPisOU*nTxPis,2))
			nCofOU		:= If(nCofRA<>0,Round(nCofRA*nTxCof,2),Round(nCofOU*nTxCof,2))
			nCslOU		:= If(nCslRA<>0,Round(nCslRA*nTxCsl,2),Round(nCslOU*nTxCsl,2))
			nIrfOU		:= If(nIrfRa<>0 .Or. ( lCredito .And. nBaseRA <= SE1->E1_SALDO ),Round(nIrfRA*nTxIr,2),Round(nIrfOU*nTxIr,2))
			nPrIsOU		:= If(nPrIsRA<>0,Round(nPrIsRA*nTxIss,2),Round(nPrIsOU*nTxIss,2))
			nPrInOU		:= If(nPrInRA<>0,Round(nPrInRA*nTxIns,2),Round(nPrInOU*nTxIns,2))
			If (SA1->A1_MINIRF == "2" .And. (nIrfOU <= SuperGetMv("MV_VLRETIR",.T.,10)) ) .Or. nIrfOU < 0
				nIrfOU	:= 0
			EndIf
		Else
			nPisRA		:= If(nPisOU<>0,Round(nPisOU*nTxPis,2),Round(nPisRA*nTxPis,2)) 
			nCofRA		:= If(nCofOU<>0,Round(nCofOU*nTxCof,2),Round(nCofRA*nTxCof,2))
			nCslRA		:= If(nCslOU<>0,Round(nCslOU*nTxCsl,2),Round(nCslRA*nTxCsl,2))
			nIrfRA		:= If(nIrfOU<>0,Round(nIrfOU*nTxIr,2),Round(nIrfRA*nTxIr,2))
			nPrIsRA		:= If(nPrIsOU<>0,Round(nPrIsOU*nTxIss,2),Round(nPrIsRA*nTxIss,2))
			nPrInRA		:= If(nPrInOU<>0,Round(nPrInOU*nTxIns,2),Round(nPrInRA*nTxIns,2))
			If (SA1->A1_MINIRF == "2" .And. (nIrfRA <= SuperGetMv("MV_VLRETIR",.T.,10)) ) .Or. nIrfRA < 0
				nIrfRA	:= 0
			EndIf
		EndIf
	Else
		lRet := .F.
	EndIf
Else
	lRet := .F.
EndIf

If lCredito
	nSaldoOU -= (nPisOU+nCofOU+nCslOU+nIrfOU+nPrIsOU+nPrInOU) 
Else
	// nIrfRA:= FCaIrBxCR(nBaseRA)
	nSaldoOU -= (nPisRA+nCofRA+nCslRA+nIrfRA+nPrIsRA+nPrInRA) 
EndIf

If lRet

	If lCredito
		If nItemOU <> 0
			aDadosRA1[3][nItLcOU] := nPisOU
			aDadosRA1[4][nItLcOU] := nCofOU
			aDadosRA1[5][nItLcOU] := nCslOU
			aDadosRA1[6][nItLcOU] := nIrfOU
			aDadosRA1[7][nItLcOU] := nSaldoOU
			aDadosRA1[8][nItLcOU] := If(aDadosRA1[7][nItLcOU]>nSaldoRA,nSaldoRA,aDadosRA1[7][nItLcOU])
			aDadosRA1[10][nItLcOU]:= nPrIsRA
			aDadosRA1[11][nItLcOU]:= nPrInRA

		Else
			aAdd(aDadosRA1[3],nPisOU)
			aAdd(aDadosRA1[4],nCofOU)
			aAdd(aDadosRA1[5],nCslOU)
			aAdd(aDadosRA1[6],nIrfOU)
			aAdd(aDadosRA1[7],nSaldoOU)
			aAdd(aDadosRA1[8],If(aDadosRA1[7][Len(aDadosRA1[7])]>nSaldoRA,nSaldoRA,aDadosRA1[7][Len(aDadosRA1[7])]))
			aAdd(aDadosRA1[10],nPrIsRA)
			aAdd(aDadosRA1[11],nPrInRA)
		EndIf
	Else
		If nItemRA <> 0
			aDadosRA1[3][nItLcRA] := nPisRA
			aDadosRA1[4][nItLcRA] := nCofRA
			aDadosRA1[5][nItLcRA] := nCslRA
			aDadosRA1[6][nItLcRA] := nIrfRA
			aDadosRA1[7][nItLcRA] := nSaldoRA
			aDadosRA1[8][nItLcRA] := If(aDadosRA1[7][nItLcRA]>nSaldoOU,nSaldoOU,aDadosRA1[7][nItLcRA])
			aDadosRA1[10][nItLcRA]:= nPrIsRA
			aDadosRA1[11][nItLcRA]:= nPrInRA

		Else
			aAdd(aDadosRA1[3],nPisRA)
			aAdd(aDadosRA1[4],nCofRA)
			aAdd(aDadosRA1[5],nCslRA)
			aAdd(aDadosRA1[6],nIrfRA)
			aAdd(aDadosRA1[7],nSaldoRA)
			aAdd(aDadosRA1[8],If(aDadosRA1[7][Len(aDadosRA1[7])]>nSaldoOU,nSaldoOU,aDadosRA1[7][Len(aDadosRA1[7])]))
			aAdd(aDadosRA1[10],nPrIsRA)
			aAdd(aDadosRA1[11],nPrInRA)

		EndIf
	EndIf

EndIf

FWRestArea(aArea)

Return(lRet)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³U_FA330Fil  ºAutor  ³Microsiga           ºFecha ³ 08/07/2013  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³Permite determinar as filias para selecao dos titulos       º±±
±±º          ³para liquidacao.                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ AP                                                         º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
User Function Fa330Fil() As Array
	Local aRet	As Array
	
	aRet	:= {}

	If MsgYesNo(STR0066 + " " + STR0067 + CRLF + CRLF + STR0068 + CRLF + CRLF + STR0069,STR0018)
		//"Serão selecionados somente os títulos das filiais escolhidas." + " " + "Se nenhuma For escolhida serão considerados somente os da filial corrente." + CRLF + CRLF + "Importante: Algumas entidades, como clientes, bancos etc, podem possuir um código na filial A, porém na filial B, esse mesmo código não necessariamente representa a mesma entidade." + CRLF + CRLF + "Deseja continuar com a seleção de filiais?"
		aRet := AdmGetFil(.F.,.T.,"SE1")
	Else
		aRet := {}
	EndIf

Return(Aclone(aRet))

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³FINA330   ºAutor  TOTVS		         º Data ³  07/23/13   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Recompor Valor de compensação, nSaldo, limite de compensaçãoº±±
±±º          ³ quando marcado uma NCC para compensação                    º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ FINA330                                                    º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function F330VALNCC(aArray As Array, nX As Numeric, lAltValor As Logical, lSoma As Logical)

	Local nProp		As Numeric
	Local nLim 		As Numeric
	Local nPos 		As Numeric
	Local nImpBx 	As Numeric
	
	nProp	:= 0
	nLim 	:= 0
	nPos 	:= 0
	nImpBx 	:= 0
	
	nPis	:= 0
	nCofins	:= 0
	nCsll	:= 0
	nIrrf	:= 0

	DEFAULT nX 			:= 1
	DEFAULT lAltValor 	:= .F.
	DEFAULT aArray		:= {}
	DEFAULT lSoma		:= .F.
	
	If MV_PAR02 == 2
		nPos := 25
	Else
		nPos := 22
	EndIf
	If MV_PAR08 == 1
		nImpBx := nTotImpbx-nIss-nInss
	Else
		nImpBx := nTotImpbx
	EndIf
	
	If lAltValor
		nProp:=  aTitulos[nX,9]/SE1->E1_VALOR
	Else
	    If aArray[nX,(nPos+1)]< SE1->E1_VALOR
			nProp:= aTitulos[nX,(nPos+1)]/SE1->E1_VALOR
		Else
			nProp:=  1
		EndIf
	EndIf
	If lSoma
		nLim := U_Fa330VTit(aArray[nX,IIf(cPaisLoc != "RUS",nPos,6)])
		nSaldo+= nImpBx*nProp
		nLim += nImpBx *nProp
		If nLim <= aArray[nX,(nPos-1)]
			aArray[nX,nPos]:= Transf(nLim,__cPiE1Sld)
		EndIf
	
	Else
		nLim := U_Fa330VTit(aArray[nX,IIf(cPaisLoc != "RUS",nPos,6)])
		nSaldo-= nImpBx *nProp
		nLim -= nImpBx *nProp
		If nLim <= aArray[nX,(nPos-1)]
			aArray[nX,nPos]:= Transf(nLim,__cPiE1Sld)
		EndIf
	EndIf

Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±                                                                         ±±
±±            Funcoes retiradas do arquivo FINXATU.PRX                     ±±
±±                                                                         ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/


//-------------------------------------------------------------------
/*/{Protheus.doc} IntegDef

Funcao de integracao com o adapter EAI para o recebimento de compensacao
de titulos a receber.

@param   Caracter, cXML, Variavel com conteudo xml para envio/recebimento.
@param   Caracter, cTypeTrans, Tipo de transacao. (Envio/Recebimento)
@param   Caracter, cTypeMsg, Tipo de mensagem. (Business Type, WhoIs, etc)
@param   Caracter, cVersion, Versão da mensagem.

@author  TOTVS
@version P12
@since   03/02/2017
@Return  Array, Array contendo o resultado da execucao e a mensagem Xml de retorno.
         aRet[1] - (boolean) Indica o resultado da execução da função
         aRet[2] - (caracter) Mensagem Xml para envio

@obs
O método irá retornar um objeto do tipo TOTVSBusinessEvent caso
o tipo da mensagem seja EAI_BUSINESS_EVENT ou um tipo
TOTVSBusinessRequest caso a mensagem seja do tipo TOTVSBusinessRequest.
O tipo da classe pode ser definido com a função EAI_BUSINESS_REQUEST.
/*/
//-------------------------------------------------------------------
Static Function IntegDef( cXML, nTypeTrans, cTypeMessage, cVersion )
	Local aRet := {}

	aRet := FINI330( cXML, nTypeTrans, cTypeMessage, cVersion )

Return aRet

//-----------------------------------------------------------------------------------------------------
/*/{Protheus.doc} F330VldImp()
Função para retornar as configurações de impostos através do motor de retenções

@author Pedro Alencar
@since 08/01/2018
@version 12
/*/
//-----------------------------------------------------------------------------------------------------
Static Function F330VldImp()
	Local nZ As Numeric
	Local lPisMR As Logical
	Local lCofMR As Logical
	Local lCslMR As Logical
	Local lPisBxMR As Logical
	Local lCofBxMR As Logical
	Local lCslBxMR As Logical
	Local lRaRtPis As Logical
	Local lRaRtCof As Logical
	Local lRaRtCsl As Logical
	Local aImpConf As Array
	Local cTitPosic As Char
	//Local lCfgAdto	As Logical
	
	lPisMR := .F.
	lCofMR := .F.
	lCslMR := .F.
	lPisBxMR := .F.
	lCofBxMR := .F.
	lCslBxMR := .F.
	lRaRtPis := .F.
	lRaRtCof := .F.
	lRaRtCsl := .F.
	//lCfgAdto := .F.
	aImpConf := {}
	cTitPosic := SE1->E1_FILORIG + SE1->E1_PREFIXO + SE1->E1_NUM + SE1->E1_PARCELA + SE1->E1_TIPO + SE1->E1_CLIENTE + SE1->E1_LOJA
	
	/*---------------------------------------------------------------------------
	Estrutura do aImpConf
	[1] = Codigo do tipo de imposto (cCodFOO)
	[2] = Fato gerador ( 1=Competência; 2=Caixa ) 
	[3] = Código FOI
	[4] = Tipo de Movimento (FKM_TPMVEM)
	[5] = Valor da nota (FKM_VLNOTE)
	[6] = Ação para antecipações (FKM_ANTEBX: 1= Retém; 2=Provisiona; 3=Sem ação)
	----------------------------------------------------------------------------*/
	If __cOldMRCf <> cTitPosic //Chama a função para ver os impostos configurados pelo motor de retenções, caso já não tenha sido chamada para o título posicionado 
		ClrVarMRCf()
		__cOldMRCf := cTitPosic
		
		aImpConf 	:= FinImpConf( "2", SE1->E1_FILORIG, SE1->E1_CLIENTE, SE1->E1_LOJA, SE1->E1_NATUREZ, SE1->E1_TIPO )
		__lTCnfgMR	:= Len(aImpConf) > 0 
		For nZ := 1 To Len( aImpConf )
			Do Case
				
				Case aImpConf[nZ,1] == "PIS" //.And. ( !lCfgAdto .Or. ( lCfgAdto .And. aImpConf[nZ,6] == '1'))
					lPisMR 		:= .T.
					lPisBxMR 	:= ( aImpConf[nZ,2] == "2" )
					lRaRtPis 	:= ( aImpConf[nZ,6] == "1" )
				
				Case aImpConf[nZ,1] == "COF" //.And. ( !lCfgAdto .Or. ( lCfgAdto .And. aImpConf[nZ,6] == '1'))
					lCofMR 		:= .T.
					lCofBxMR 	:= ( aImpConf[nZ,2] == "2" )
					lRaRtCof 	:= ( aImpConf[nZ,6] == "1" )
				
				Case aImpConf[nZ,1] == "CSL" //.And. ( !lCfgAdto .Or. ( lCfgAdto .And. aImpConf[nZ,6] == '1'))
					lCslMR 		:= .T.
					lCslBxMR 	:= ( aImpConf[nZ,2] == "2" )
					lRaRtCsl 	:= ( aImpConf[nZ,6] == "1" )
				
				Case aImpConf[nZ,1] == "IRF" //.And. ( !lCfgAdto .Or. ( lCfgAdto .And. aImpConf[nZ,6] == '1'))
					__lIrfMR 	:= .T.
					__lIrfBxMR 	:= ( aImpConf[nZ,2] == "2" )
					__lRaRtIrf 	:= ( aImpConf[nZ,6] == "1" )
				
				Case aImpConf[nZ,1] == "ISS" //.And. ( !lCfgAdto .Or. ( lCfgAdto .And. aImpConf[nZ,6] == '1'))
					__lIssMR 	:= .T.
					__lIssBxMR 	:= ( aImpConf[nZ,2] == "2" )
					__lRaRtIss 	:= ( aImpConf[nZ,6] == "1" )
				OtherWise
					__lImpMR 	:= .T.
					__lImpBxMR	:= ( aImpConf[nZ,2] == "2" )
			EndCase
		Next nZ
		
		__lPccMR := lPisMR .Or. lCofMR .Or. lCslMR
		__lPccBxMR := lPisBxMR .Or. lCofBxMR .Or. lCslBxMR
		__lRaRtPcc := lRaRtPis .Or. lRaRtCof .Or. lRaRtCsl
	EndIf
	
	aSize ( aImpConf, 0 )
	aImpConf := {}
	
Return __lTCnfgMR

//-----------------------------------------------------------------------------------------------------
/*/{Protheus.doc} F330CalImp()
Função para realizar o cálculo de imposto através do motor de retenções

@param cNatMR, Natureza para cálculo do imposto pelo motor de retenções
@param cCliMR, Cliente para cálculo do imposto pelo motor de retenções
@param cLojaMR, Loja para cálculo do imposto pelo motor de retenções
@param cFilMR, Filial de origem para cálculo do imposto pelo motor de retenções
@param nBaseMR, Valor base para cálculo do imposto pelo motor de retenções
@param dDataMR, Data para cálculo do imposto pelo motor de retenções
@param cTipoTitMR, Tipo do tíutlo para cálculo do imposto pelo motor de retenções 

@author Pedro Alencar
@since 12/01/2018
@version 12
/*/
//-----------------------------------------------------------------------------------------------------
Static Function F330CalImp( cNatMR As Char, cCliMR As Char, cLojaMR As Char, cFilMR As Char, nBaseMR As Numeric, dDataMR As Date, cTipoTitMR As Char, lTroca As Logical )
	Local nZ 		As Numeric
	Local cTitPosic As Char
	Local nI 		As Numeric
	Local nX 		As Numeric
	Local cChaveAux As Char
	Local aImposE 	As Array
	Local nTotAdto	As Numeric
	Local lPccBxCr 	As Logical
	Local lMRVrTimp As Logical
	Local nVlParcl	As Numeric
	Local aArea     As Array
	
	Default cNatMR 		:= ""
	Default cCliMR 		:= ""
	Default cLojaMR 	:= ""
	Default cFilMR 		:= ""
	Default nBaseMR 	:= 0
	Default dDataMR		:= CtoD("//")
	Default cTipoTitMR 	:= ""
	Default lTroca		:= .F.
	
	lMRVrTimp	:= Type('lRarTimpMR') != "U"
	
	lPccBxCr := ( __lPccMR .And. __lPccBxMR ) .Or. ( !__lPccMR .And. FPccBxCr() )
	
	aImposE		:= {}
	nVlParcl	:= 0
	aArea 		:= FWGetArea()
	
	cTitPosic := SE1->E1_FILORIG + SE1->E1_PREFIXO + SE1->E1_NUM + SE1->E1_PARCELA + SE1->E1_TIPO + SE1->E1_CLIENTE + SE1->E1_LOJA
	cChaveAux := FWxFilial( "SE1", SE1->E1_FILIAL ) + "|" + SE1->E1_PREFIXO + "|" + SE1->E1_NUM + "|" + SE1->E1_PARCELA + "|" + SE1->E1_TIPO + "|" + SE1->E1_CLIENTE + "|" + SE1->E1_LOJA	
	
	If __lPccMR 
		nPis 	:= 0
		nCofins := 0
		nCsll 	:= 0
	EndIf
	If __lIrfMR																						
		nIrrf 	:= 0
	EndIf
	
	ClrVarMRCl()
	__cOldMRCl := cTitPosic

	/*-------------------------------------------
	Estrutura da aImpos
	[1] = Codigo do tipo de imposto (FKM_CODIGO)
	[2] = Base do imposto
	[3] = Valor calculado do imposto
	[4] = Base de retenção do imposto
	[5] = Valor a reter do imposto
	[6] = IDRET FK4
	[7] = Array contendo os Recnos FK3 das pendências de retenção	
	[8] = Tipo do Imposto (SX5 - 0C )
	[9] = Fato gerador ( 1=Competência; 2=Caixa )
	[10] = Natureza do imposto
	[11] = Tabela onde foi gerado o imposto
	[12] = Recno do titulo de imposto gerado
	[13] = Ação aplicada no valor da nota na emissão(1 = subtrai, 2 = soma, 3 = sem ação) 
	[14] = Carteira de movimento na emissão (1 = Pagar, 2 = Receber)
	[15] = Tipo de movimento na emissão (1 = Abtimento, 2 = Provisão, 3 = Retenção, 4 = Não Gerar)
	[16] = Ação aplicada no valor da nota na baixa(1 = subtrai, 2 = soma, 3 = sem ação)
	[17] = Carteira de movimento na baixa (1 = Pagar, 2 = Receber)
	[18] = Tipo de movimento na baixa (1 = Abtimento, 2 = Provisão, 3 = Retenção, 4 = Não Gerar) 
	[19] = Ação sobre títulos de antecipação pagamento/recebimento: 1 = Retém, 2 = Provisiona, 3 = sem ação
	--------------------------------------------*/
	
	If lTroca
		aImposE := FMRGetArr('2', .F.)
		For nI := 1 To Len( aImposE )
			Do Case
				Case aImposE[nI,8] == "PIS" .And. aImposE[nI,9] == '1'
					__nPisCaMR += aImposE[nI,5]
				Case aImposE[nI,8] == "COF" .And. aImposE[nI,9] == '1'
					__nCofCaMR += aImposE[nI,5]
				Case aImposE[nI,8] == "CSL" .And. aImposE[nI,9] == '1'
					__nCslCaMR += aImposE[nI,5]
				Case aImposE[nI,8] == "IRF" .And. aImposE[nI,9] == '1'
					__nIrfCaMR += aImposE[nI,5]
				Case aImposE[nI,8] == "ISS" .And. aImposE[nI,9] == '1'
					__nIssCaMR += aImposE[nI,5]
				OtherWise
					If aImposE[nI,9] == '1'
						// aAdd(__aOutImp, nI)
						__nImpMR	+= aImposE[nI,5]
						__lImpMR	:= .T.
						__lImpEmis	:= .T.
					EndIf			
			EndCase
		Next nI
	EndIf

	If SE1->E1_SALDO <> SE1->E1_VALOR
		If Len(aBaixaSE5) == 0
			If Empty(SE1->E1_TIPOLIQ)
				//Procura pelas baixas deste titulo
				Sel070Baixa( "VL /V2 /BA /RA /CP /LJ /" + MV_CRNEG, SE1->E1_PREFIXO, SE1->E1_NUM, SE1->E1_PARCELA, SE1->E1_TIPO, ;
					@nTotAdto, /*@lBaixaAbat*/, SE1->E1_CLIENTE, SE1->E1_LOJA) //, /*@nVlrBaixa*/,, @lBxCec, @lBxLiq, @lSigaLoja, @lTipBxCP )

				For nX := 1 To Len(aBaixaSE5)
					nVlParcl += aBaixaSE5[nX][8]				
					If lPccBxCR .And. ( lRaRtImp .Or. ( lMRVrTimp  .And. lRaRtImpMR ) ) //somar impostos PCC
						nVlParcl += aBaixaSE5[nX][18] + aBaixaSE5[nX][19] + aBaixaSE5[nX][20] + aBaixaSE5[nX][30] + aBaixaSE5[nX][32] + aBaixaSE5[nX][33]
					EndIf
					nIss += aBaixaSE5[nX][32]
					nInss += aBaixaSE5[nX][33]
				Next
				nVlParcl := nTotAdto
			Else
				nVlParcl := SE1->E1_VALOR - SE1->E1_SALDO
			EndIf
		EndIf
		
		__nBaseMR	:= SE1->E1_VALOR - nVlParcl
		nBaseMR 	:= IIf( nVlParcl > 0, __nBaseMR, nBaseMR )
	EndIf
	
	__aImpos := FINCalImp( "2", cNatMR, cCliMR, cLojaMR, cFilMR, nBaseMR, dDataMR, .T., {}, cTipoTitMR, cChaveAux)
	For nZ := 1 To Len( __aImpos )
		Do Case
			Case __aImpos[nZ,8] == "PIS"
				__nPisCaMR += __aImpos[nZ,5]
			Case __aImpos[nZ,8] == "COF"
				__nCofCaMR += __aImpos[nZ,5]
			Case __aImpos[nZ,8] == "CSL"
				__nCslCaMR += __aImpos[nZ,5]
			Case __aImpos[nZ,8] == "IRF"
				__nIrfCaMR += __aImpos[nZ,5]
			Case __aImpos[nZ,8] == "ISS"
				__nIssCaMR += __aImpos[nZ,5]
			OtherWise
				aAdd(__aOutImp, nZ)
				__nImpMR	+= __aImpos[nZ,5]
				__lImpMR	:= .T.
		EndCase
	Next nZ
	
	If __lPccMR
		nPis 	:= __nPisCaMR 
		nCofins := __nCofCaMR
		nCsll 	:= __nCslCaMR
	EndIf
	
	If __lIrfMR
		nIrrf := __nIrfCaMR
	EndIf
	FWRestArea(aArea)
Return

//-----------------------------------------------------------------------------------------------------
/*/{Protheus.doc} LimpaVarMR()
Função para limpar as variáveis estáticas utilizadas para o motor de retenções

@author Pedro Alencar
@since 08/01/2018
@version 12
/*/
//-----------------------------------------------------------------------------------------------------
Static Function LimpaVarMR()
	
	ClrVarMRCf() //Limpa as variáveis de configuração
	ClrVarMRCl() //Limpa as variáveis de cálculo	
	__cOldMRCf := ""
	__cOldMRCl := ""
	__lMotRet := .F.
	
	__aTxMoed0	:= Nil
	__nTxMoedP	:= 0
	
Return

//-----------------------------------------------------------------------------------------------------
/*/{Protheus.doc} ClrVarMRCf()
Função para limpar as variáveis estáticas utilizadas para AS CONFIGURAÇÔES do motor de retenções

@author Pedro Alencar
@since 08/01/2018
@version 12
/*/
//-----------------------------------------------------------------------------------------------------
Static Function ClrVarMRCf()

	__lPccMR 	:= .F.
	__lPccBxMR 	:= .F.
	__lRaRtPcc 	:= .F.
	__lIrfMR 	:= .F.
	__lIrfBxMR 	:= .F.
	__lRaRtIrf 	:= .F.
	__lIssMR 	:= .F.
	__lIssBxMR 	:= .F.
	__lRaRtIss 	:= .F.
	__lImpEmis	:= .F.
	__nImpEst	:= 0
	
Return

//-----------------------------------------------------------------------------------------------------
/*/{Protheus.doc} ClrVarMRCl()
Função para limpar as variáveis estáticas utilizadas para OS CÁLCULOS do motor de retenções

@author Pedro Alencar
@since 08/01/2018
@version 12
/*/
//-----------------------------------------------------------------------------------------------------
Static Function ClrVarMRCl()
	
	__nPisCaMR 	:= 0
	__nCofCaMR 	:= 0
	__nCslCaMR 	:= 0
	__nIrfCaMR 	:= 0
	__nIssCaMR 	:= 0
	__nImpMR	:= 0
	__nBaseMR	:= 0
	
	aSize ( __aImpos, 0 )
	__aImpos := {}
	
Return

//-----------------------------------------------------------------------------------------------------
/*/{Protheus.doc} PegaVarMR()
Função para guardar os valores das variáveis estáticas utilizadas para o motor de retenções, 
para poder restaurá-los sem precisar realizar o cáluclo do motor novamente.

@Return aRet, vetor com os dados das variáveis estáticas usadas para o motor de retenções.

@author Pedro Alencar
@since 26/01/2018
@version 12
/*/
//-----------------------------------------------------------------------------------------------------
Static Function PegaVarMR() As Array
	Local aRet As Array
	
	aRet := {}
	If __lMotRet
		aAdd( aRet, __lPccMR )
		aAdd( aRet, __lPccBxMR )
		aAdd( aRet, __lRaRtPcc )
		aAdd( aRet, __lIrfMR )
		aAdd( aRet, __lIrfBxMR )
		aAdd( aRet, __lRaRtIrf )
		aAdd( aRet, __lIssMR )
		aAdd( aRet, __lIssBxMR )
		aAdd( aRet, __lRaRtIss )
		aAdd( aRet, __nPisCaMR )
		aAdd( aRet, __nCofCaMR )
		aAdd( aRet, __nCslCaMR )
		aAdd( aRet, __nIrfCaMR )
		aAdd( aRet, __nIssCaMR )
		aAdd( aRet, aClone( __aImpos ) )
		aAdd( aRet, __cOldMRCf )
		aAdd( aRet, __cOldMRCl )
	EndIf
Return aRet

//-----------------------------------------------------------------------------------------------------
/*/{Protheus.doc} RestVarMR()
Função para restaurar os valores das variáveis estáticas utilizadas para o motor de retenções.

@param aVarMR, vetor com a estrutura retornada pela função PegaVarMR.

@author Pedro Alencar
@since 26/01/2018
@version 12
/*/
//-----------------------------------------------------------------------------------------------------
Static Function RestVarMR( aVarMR As Array )
	Default aVarMR := {}
	
	If __lMotRet .And. Len( aVarMR ) >= 17
		__lPccMR 	:= aVarMR[1]
		__lPccBxMR 	:= aVarMR[2]
		__lRaRtPcc 	:= aVarMR[3]
		__lIrfMR 	:= aVarMR[4]
		__lIrfBxMR 	:= aVarMR[5]
		__lRaRtIrf 	:= aVarMR[6]
		__lIssMR 	:= aVarMR[7]
		__lIssBxMR 	:= aVarMR[8]
		__lRaRtIss 	:= aVarMR[9]
		__nPisCaMR 	:= aVarMR[10]
		__nCofCaMR 	:= aVarMR[11]
		__nCslCaMR 	:= aVarMR[12]
		__nIrfCaMR 	:= aVarMR[13]
		__nIssCaMR 	:= aVarMR[14]
		__aImpos 	:= aClone( aVarMR[15] )
		__cOldMRCf 	:= aVarMR[16]
		__cOldMRCl 	:= aVarMR[17]
		
		If __lPccMR .And. ( __nCofCaMR > 0 .Or. !lCredito )
			nPis 	:= __nPisCaMR 
			nCofins := __nCofCaMR
			nCsll 	:= __nCslCaMR
		EndIf
		
		If __lIrfMR
			nIrrf := __nIrfCaMR
		EndIf
	EndIf
	
Return

//-----------------------------------------------------------------------------------------------------
/*/{Protheus.doc} FA330SIT

Função para verificação do campo E1_SITUACA do titulo

@author    Francisco Oliveira
@version   12
@since     02/02/2018

@Return cSituac - retorna a situação do titulo 
/*/
//-----------------------------------------------------------------------------------------------------

Static Function FA330SIT(aTitulos,nRecE1)
	Local nX
	Local aAreaE1		:= SE1->(GetArea())
	Local cLstCart		:= FN022LSTCB(1,'0007')	//Lista das situacoes de cobranca (Carteira)
	Local lRet			:= .T.
	
	Default nRecE1	:= 0
	
	If nRecE1 == 0
		For nX := 1  To Len(aTitulos)
			If MV_PAR02 == 2
				SE1->(DBGoTo(aTitulos[nX][23]))
			Else
				SE1->(DBGoTo(aTitulos[nX][20]))
			EndIf
			
			If MV_PAR05 == 2 .And. !(SE1->E1_SITUACA $ cLstCart) .And. aTitulos[nX][8]
				Help(" ",1,"F330CARTE")
				lRet := .F.
				Exit
			EndIf
		Next nX
	Else
		SE1->(DBGoTo(nRecE1))
		If MV_PAR05 == 2 .And. !(SE1->E1_SITUACA $ cLstCart)
			Help(" ",1,"F330CARTE")
			lRet := .F.
		EndIf
	EndIf
	
	FWRestArea(aAreaE1)
Return lRet

//------------------------------
/*/{Protheus.doc}FA330Valor
Define os valores a serem enviado para conversão da moeda

@author Sivaldo Oliveira
@since  23/11/2018
@version 12
/*/
//------------------------------
Static Function FA330Valor(nVlr, nMoedP, nMoedD, dDtMov, nTaxaMov, lRound)
	Default nVlr     := 0
	Default nMoedP   := 0
	Default nMoedD   := 0
	Default dDtMov   := dDataBase
	Default nTaxaMov := 0
	Default lRound   := .F.
	
	If nMoedP != nMoedD .And. nVlr != 0 .And. nMoedP != 0 .And. nMoedD != 0
		If (nMoedD == 1 .Or. nMoedP != 1)
			nVlr := xMoeda(nVlr, nMoedP, nMoedD, dDtMov, __nCasDec, nTaxaMov)
		Else
			nVlr := xMoeda(nVlr, nMoedP, nMoedD, dDtMov, __nCasDec, Nil, nTaxaMov)
		EndIf
	EndIf
	
	If lRound
		nVlr := Round(NoRound(nVlr, __nCasDec), 2)	
	EndIf
Return nVlr

//------------------------------
/*/{Protheus.doc}F330Static
Inicializa as variáveis estáticas.

@author Sivaldo Oliveira
@since  23/11/2018
@version 12
/*/
//------------------------------
Static Function F330Static() 
	If ValType(__aTxMoed0) != "A"
		__aTxMoed0 := {}
		__aTxMoed0 := aClone(aTxMoedas)
	EndIf
	__lTxConP := .F.
	If SE1->E1_MOEDA != 1
		If (SE1->E1_TXMOEDA > 0 .Or. MV_PAR14 == 2)
			If SE1->E1_TXMDCOR > 0
				__nTxMoedP := SE1->E1_TXMDCOR
				__lTxConP	:= .T.
			Else
				__nTxMoedP := SE1->E1_TXMOEDA
				__lTxConP	:= .T.
			EndIf
		ElseIf __lTxMoed
			aTxMoedas[SE1->E1_MOEDA,2] := __nTxMoedP
		EndIf
	ElseIf MV_PAR14 == 2
		aTxMoedas := __aTxMoed0
	EndIf
	__nTxMoedD := 0
	__nTxContr := 0
	__lCmTxCon := .T.
	__lCalcCM  := .T.
	__nPosTit  := 0
	__lNoTxMov := .F.
	__oMovRA    := Nil
	__oMovCnb	:= Nil
	If __oHshTMrk <> Nil
		__oHshTMrk:Clean()
		__oHshTMrk	:= Nil
	EndIf
	If __aHshTMrk <> Nil
		aSize(__aHshTMrk, 0)
		__aHshTMrk	:= Nil
	EndIf
	
	
	If cPaisLoc == "BRA"
		__lCmTxCon := SuperGetMv("MV_CMTXCON", .F., .F.) //Gera VM para TXCANTRATADA
		__lCalcCM  := SuperGetMv("MV_CALCCM", .F., "N") == "S"
	EndIf
	
	__nCasDec  := TamSX3("E1_TXMOEDA")[2]	
Return

/*
===============================================================================================================================
Programa----------: F23MovRA
Autor-------------: Igor Melgaço
Data da Criacao---: 28/08/2023
Descrição---------: Verifica se o RA possui movimento bancário  
===============================================================================================================================
*/ 
User Function F23MovRA(aMovRA As Array, cTbl As Character, lVerMov As Logical) As Array
Local cQry      As Character
Local cTblTmp   As Character
Local aArea     As Array
Local cCampoChq As Character
Local dDtMov	As Date 

Default aMovRA  := {.F., dDataBase, ""}
Default cTbl    := "SE2"
Default lVerMov := .T.

//Inicializa variáveis
cQry 	  := ""
cTblTmp   := ""
cCampoChq := PadR("", TamSX3("E5_NUMCHEQ")[1])
aArea     := FWGetArea()

If lVerMov
	If __oMovRA == Nil
		cQry := "SELECT E5_DATA, E5_TIPODOC FROM " + RetSqlName("SE5") + " "
		cQry += "WHERE E5_FILIAL = ? AND E5_PREFIXO = ? AND "
		cQry += "E5_NUMERO = ? AND E5_PARCELA = ? AND "
		cQry += "E5_TIPO = ? AND E5_CLIFOR = ? AND E5_LOJA = ? AND "
		cQry += "((E5_TIPODOC = 'RA' ) OR (E5_TIPODOC = 'BA' AND E5_NUMCHEQ <> '" + cCampoChq + "' ) OR "
		cQry += "(E5_TIPODOC = 'CH' AND E5_NUMCHEQ <> '" + cCampoChq + "')) AND "
		cQry += "E5_RECPAG = 'R' AND E5_SITUACA = ' ' AND D_E_L_E_T_ = ' ' "
		cQry := ChangeQuery(cQry)
		__oMovRA := FWPreparedStatement():New(cQry)
	EndIf

	__oMovRA:SetString(1, xFilial("SE5", (cTbl)->E1_FILORIG))
	__oMovRA:SetString(2, (cTbl)->E1_PREFIXO)
	__oMovRA:SetString(3, (cTbl)->E1_NUM)
	__oMovRA:SetString(4, (cTbl)->E1_PARCELA)
	__oMovRA:SetString(5, (cTbl)->E1_TIPO)
	__oMovRA:SetString(6, (cTbl)->E1_CLIENTE)
	__oMovRA:SetString(7, (cTbl)->E1_LOJA)

	cQry := __oMovRA:GetFixQuery()
	cTblTmp := MpSysOpenQuery(cQry)
Else
	If __oMovCnb == Nil
		cQry := "SELECT E5_DATA, E5_TIPODOC FROM " + RetSqlName("SE5") + " "
		cQry += "WHERE E5_FILIAL = ? AND E5_PREFIXO = ? AND "
		cQry += "E5_NUMERO = ? AND E5_PARCELA = ? AND "
		cQry += "E5_TIPO = ? AND E5_CLIFOR = ? AND E5_LOJA = ? AND "
		cQry += "E5_RECPAG = 'R' AND E5_SITUACA = ' ' AND D_E_L_E_T_ = ' ' "
		cQry := ChangeQuery(cQry)
		__oMovCnb := FWPreparedStatement():New(cQry)
	EndIf

	__oMovCnb:SetString(1, xFilial("SE5", (cTbl)->E1_FILORIG))
	__oMovCnb:SetString(2, (cTbl)->E1_PREFIXO)
	__oMovCnb:SetString(3, (cTbl)->E1_NUM)
	__oMovCnb:SetString(4, (cTbl)->E1_PARCELA)
	__oMovCnb:SetString(5, (cTbl)->E1_TIPO)
	__oMovCnb:SetString(6, (cTbl)->E1_CLIENTE)
	__oMovCnb:SetString(7, (cTbl)->E1_LOJA)

	cQry := __oMovCnb:GetFixQuery()
	cTblTmp := MpSysOpenQuery(cQry)
EndIf

(cTblTmp)->(DBGoTop())

If (cTblTmp)->(!Eof())
	dDtMov := If(Empty((cTblTmp)->E5_DATA), dDataBase, SToD((cTblTmp)->E5_DATA))
	aMovRA := {.T., dDtMov, (cTblTmp)->E5_TIPODOC}
EndIf

(cTblTmp)->(DBCloseArea())
FWRestArea(aArea)

Return aMovRA


//--------------------------------------------------------------------------
/*/{Protheus.doc}TitNMarc
Verificar se determinado título da rotina automática deve ser marcado ou
não.

@author Rodrigo Oliveira
@since  23/05/2019
@version 12
/*/
//--------------------------------------------------------------------------
Static Function TitNMarca(cAliasSE1 As Character) As Logical

	Local lTitNMarc As Logical
	Local nI		As Numeric
	Local nPos		As Numeric
	// Local lFlag		As Logical
	
	lTitNMarc	:= .F.
	nI			:= 0
	nPos		:= 0
	
	If ValType(aRetAuto) == 'A'
		If __aHshTMrk == Nil // __oHshTMrk == Nil
			// __oHshTMrk := tHashMap():New() //Cria o Objeto do Hash Map
			__aHshTMrk := {}
			For nI := 1 To Len(aRetAuto[2])
				// __oHshTMrk:Set(aRetAuto[2][nI][1] + aRetAuto[2][nI][2] + aRetAuto[2][nI][3] + aRetAuto[2][nI][4], .T.)
				aAdd(__aHshTMrk, aRetAuto[2][nI][1] + aRetAuto[2][nI][2] + aRetAuto[2][nI][3] + aRetAuto[2][nI][4])
			Next nI
			/*If !__oHshTMrk:Get((cAliasSE1)->E1_PREFIXO + (cAliasSE1)->E1_NUM + (cAliasSE1)->E1_PARCELA + (cAliasSE1)->E1_TIPO, lFlag)
				lTitNMarc := .T.
			EndIf*/
			If ( nPos	:= aScan(__aHshTMrk, (cAliasSE1)->E1_PREFIXO + (cAliasSE1)->E1_NUM + (cAliasSE1)->E1_PARCELA + (cAliasSE1)->E1_TIPO) ) == 0
				lTitNMarc := .T.
			EndIf
		Else
			If ( nPos	:= aScan(__aHshTMrk, (cAliasSE1)->E1_PREFIXO + (cAliasSE1)->E1_NUM + (cAliasSE1)->E1_PARCELA + (cAliasSE1)->E1_TIPO) ) == 0
				lTitNMarc := .T.
			EndIf
		EndIf
	EndIf

Return lTitNMarc

//-------------------------------------------------------------------
/*/{Protheus.doc}FBaseRPCC
Consiste valor base de calculo do PCC.
@author Rodrigo Oliveira
@since  28/05/2019
@version 12
/*/
//-------------------------------------------------------------------
Static Function FBaseRPCC(nValorRec As Numeric, lCalcPCC As Logical) As Numeric
	Local nValBase	As Numeric
	Local nBaseRet	As Numeric
	Local aBase 	As Array
	Local nX 		As Numeric
	Local cChaveAux As Character
	Local nBase	 	As Numeric
	Local nParc		As Numeric
	
	nValBase	:= 0
	nBaseRet	:= 0
	aBase 		:= {}
	nX 			:= 0
	cChaveAux 	:= ""
	nBase	 	:= If(SE1->E1_BASEPIS > 0, SE1->E1_BASEPIS, If(SE1->E1_BASECOF > 0, SE1->E1_BASECOF, If(SE1->E1_BASECSL > 0, SE1->E1_BASECSL, 0)))
	nParc		:= 0
	
	DEFAULT nValorRec	:= nBase
	DEFAULT lCalcPcc	:= .T.
	
	If __lMotRet .And. __lPccMR .And. nBase == 0
		cChaveAux := FWxFilial( "SE1", SE1->E1_FILORIG ) + "|" + SE1->E1_PREFIXO + "|" + SE1->E1_NUM + "|" + SE1->E1_PARCELA + "|" + SE1->E1_TIPO + "|" + SE1->E1_CLIENTE + "|" + SE1->E1_LOJA
	
		aBase := FinImpFis(cChaveAux,SE1->E1_FILORIG,"SE1")
		For nX := 1 to Len(aBase)
			nBase := aBase[nX][2]
		Next
	EndIf
	
	nParc := If(Type("nParciais") != "N", 0, nParciais)// real
	nValorRec := IIf(ReadVar() == "NVALREC" .Or. ReadVar() == "NVALESTRANG", nValorRec, nBase)
	nValBase := nBase
	
	If SE1->E1_MOEDA > 1
		nParc	:= xMoeda(nParc,nMoeda,SE1->E1_MOEDA,dDatabase,3,,nTxMoeda)
	EndIf
	
	If nParc < nValBase // Se o valor das baixas parciais nao atingiram o valor da base.
		nValBase := nValBase - nParc
		If nValorRec < nValBase
			nValBase := nValorRec
		EndIf
	Else // Se ja alcançou a base de calculo.
		nBaseRet	:= 0
		lCalcPcc	:= .F.
	EndIf
	
	nBaseRet := nValBase

Return nBaseRet

