/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |21/03/2025| Chamado 50265. Corrigida a busca pelo registro com data de vigência correta
Lucas Borges  |17/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
Alex Wallauer |08/09/2025| Chamado 51670. Ajuste da Validação do cA100FOR == 'F00004', pq tava mudando o _lRet = .F. para .T.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MT100GRV
Autor-------------: Frederico O. C. Jr
Data da Criacao---: 07/10/2008
Descrição---------: PE chamado na validação da gravação do Documento de Entrada
					Localização: Função a103Grava responsável pela gravação da Nota Fiscal.  
					Em que Ponto: Executado antes de iniciar o processo de gravação / exclusão de Nota de Entrada.
Parametros--------: ParamIXB -> L -> Informa se é exclusão.
Retorno-----------: lExp02 -> L -> .T. - Permite exclusão / .F. - Não permite a exclusão
===============================================================================================================================
*/
User Function MT100GRV

Local _aArea	:= FWGetArea()
Local _aAreaSC5	:= SC5->(GetArea())
Local _aAreaSC6	:= SC6->(GetArea())
Local _aAreaSC7	:= SC7->(GetArea())
Local _aAreaSC9	:= SC9->(GetArea())
Local _aAreaSD3	:= SD3->(GetArea())
Local _lDel		:= ParamIXB[1]
Local _lRet		:= .T.
Local _cAlmox	:= ""
Local _cMovim	:= SuperGetMV("IT_MOVDIR",.F.,"560")
Local _lGeraNDC := SuperGetMV("IT_GERANDC",.F.,"S") = "S"
Local _cQrySD3	:= ""
Local _cQryD3A	:= ""
Local _nI		:= 0
Local _cArm40   := AllTrim(SuperGetMV("IT_ARMAZ40",.F.,"40"))
Local _nPosLoc  := aScan( aHeader , {|x| Upper( AllTrim( x[2] ) ) == "D1_LOCAL"   } )   
Local _nPosPROD := aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "D1_COD"     } ) // Código do produto
Local _nPosQtd  := aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "D1_QUANT"   } ) // Quantidade na 1ª U.M.
Local _nPosQ2U  := aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "D1_QTSEGUM" } ) // Quantidade na 2ª U.M.
Local _nPosItn  := aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "D1_ITEM"	  } ) // Item do Documento
Local _nRecSC5  := 0
Local _cRetorno := "NAO_TRATAR"
Local _aLog := {}
Local _lNaoehLeite	:= !AllTrim( Upper( FUNNAME() ) ) $"U_MGLT009/MGLT010"
Local _lValidFrac1UM:=.T.
Local _cUM_NO_Fracionada:=SuperGetMV("IT_UMNOFRAC",.F.,"PC,UN")
Local _cProds:=""
Local _lRet2 := .T.

Private _cPedFaturamento :=""//Variavel preenchida dentro da função U_PosPedFaT()
Private _cFilCarregamento:=""//Variavel preenchida dentro da função U_PosPedFaT()
Private _cPedCarregamento:=""//Variavel preenchida dentro da função U_PosPedFaT()

If _lNaoehLeite
	If Inclui
	   _cRetorno:=U_PosPedFaT( cA100FOR+cLoja , cNFiscal+cSerie )//Essa funcao (MT100TOK.PRW) deve ser executa quando vc tá na filial de faturmento SEMPRE
	Else
	   _cRetorno:=U_PosPedFaT( SF1->F1_FORNECE+SF1->F1_LOJA , SF1->F1_DOC+SF1->F1_SERIE )//Essa funcao (MT100TOK.PRW) deve ser executa quando vc tá na filial de faturmento SEMPRE
	EndIf
	If _cRetorno == "ACHOU_PF"
	   _nRecSC5:=SC5->(RECNO())//Guarda recno do pedido de faturamento que a funcação U_PosPedFaT() posicionou
	EndIf
	If Inclui
		CNFISCAL := StrZero( Val( CNFISCAL ) , TamSX3('F1_DOC')[01] )
	EndIf
	ZZL->( DBSetOrder(3) )
	If ZZL->( DBSeek( xFilial("ZZL") + RetCodUsr() ) )
		If ZZL->(FIELDPOS("ZZL_PEFROU")) = 0 .Or. ZZL->ZZL_PEFROU == "S"
			_lValidFrac1UM:=.F.
		EndIf
	EndIf
	ZZL->( DBSetOrder(1) )
	
	_aLog := {}
	
	For _nI := 1 To Len(aCols)
		_cAlmox := AllTrim(aCols[_nI][_nPosLoc])
		
	    If _lDel
			DBSelectArea("SF4")
			SF4->(DBSetOrder(1))
			If SF4->(DBSeek(xFilial("SF4") + aCols[_nI][aScan(aHeader,{|x| AllTrim(x[2]) == "D1_TES"})]))
				If SF4->F4_ESTOQUE == "S"
					DBSelectArea("SC7")
					SC7->(DBSetOrder(1))
					If SC7->(DBSeek(xFilial("SC7") + aCols[_nI][aScan(aHeader,{|x| AllTrim(x[2]) == "D1_PEDIDO"})] + aCols[_nI][aScan(aHeader,{|x| AllTrim(x[2]) == "D1_ITEMPC"})]))
						If SC7->C7_I_USOD == "S"
							_cQrySD3 := "SELECT COUNT(D3_TM) D3_QTDTM "
							_cQrySD3 += "FROM " + RetSqlName("SD3") + " "
							_cQrySD3 += "WHERE D3_FILIAL = '" + xFilial("SD3") + "' "
							_cQrySD3 += "  AND D3_NUMSEQ = '" + SC7->C7_I_SEQD3 + "' "
							_cQrySD3 += "  AND D3_COD = '" + SC7->C7_PRODUTO + "' "
							_cQrySD3 += "  AND D3_LOCAL = '" + _cAlmox + "' "
							_cQrySD3 += "  AND D3_TM >= '500' "
							_cQrySD3 += "  AND D3_ESTORNO <> 'S' "
							_cQrySD3 += "  AND D_E_L_E_T_ = ' ' "
				
							dbUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQrySD3 ) , "TRBSD3" , .T., .F. )
	
							DBSelectArea("TRBSD3")
							TRBSD3->(DBGoTop())
				
							If TRBSD3->D3_QTDTM > 0
								_cQryD3A := "SELECT D3_DOC "
								_cQryD3A += "FROM " + RetSqlName("SD3") + " "
								_cQryD3A += "WHERE D3_FILIAL = '" + xFilial("SD3") + "' "
								_cQryD3A += "  AND D3_NUMSEQ = '" + SC7->C7_I_SEQD3 + "' "
								_cQryD3A += "  AND D3_COD = '" + SC7->C7_PRODUTO + "' "
								_cQryD3A += "  AND D3_LOCAL = '" + _cAlmox + "' "
								_cQryD3A += "  AND D3_TM = '" + _cMovim + "' "
								_cQryD3A += "  AND D3_ESTORNO <> 'S' "
								_cQryD3A += "  AND D_E_L_E_T_ = ' ' "
				
								dbUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQryD3A ) , "TRBD3A" , .T., .F. )
			
								DBSelectArea("TRBD3A")
								TRBD3A->(DBGoTop())
	
								If !TRBD3A->(Eof())
									aAdd(_aLog, {"Este Documento não poderá ser excluído, pois o produto já foi consumido. Favor verificar com o almoxarifado. Movimento Doc/NumSeq: " +;
												IIf(Empty(SC7->C7_I_SEQD3), TRBD3A->D3_DOC, TRBD3A->D3_DOC + "/" + SC7->C7_I_SEQD3) + "."})
									_lRet := .F.
								EndIf
								TRBD3A->(DBCloseArea())
							EndIf
							TRBSD3->(DBCloseArea())
						EndIf
					EndIf
				EndIf
			EndIf
	     
	    Else//Inclusao manual e Classificação da Nota - AWF - Projeto de unificação de pedidos de troca nota - Chamado 16548
	        If _cRetorno == "ACHOU_PF"
	           aCols[_nI][_nPosLoc]:=_cArm40
	        EndIf
			
			If _lValidFrac1UM
				SB1->(DBSeek(xFilial("SB1") + AllTrim(aCols[_nI][_nPosPROD]) ) )
				If SB1->B1_TIPO == "PA" 
				   If SB1->B1_UM == "UN"
				   	  If aCols[_nI,_nPosQtd] <> Int(aCols[_nI,_nPosQtd])
				   	  	  _lRet2 := .F.
				   	  	  _cProds+="Item: " + aCols[_nI,_nPosItn]+" Prod.: " + AllTrim(aCols[_nI][_nPosPROD])+" - UM: "+SB1->B1_UM+ " - " + LEFT(SB1->B1_DESC,25) + CHR(13)+CHR(10)
				   	  EndIf
				   EndIf
			    ElseIf SB1->B1_TIPO <> "SV" //.Or. (SB1->B1_TIPO == "SV" .And. _cCrtlEntP <> "S") // Tipo de Produto tem que ser diferente de Prestação de Serviço para validar o fracionamento.
		           If  SB1->B1_UM $ _cUM_NO_Fracionada
		           	   If aCols[_nI,_nPosQtd] <> Int(aCols[_nI,_nPosQtd])
				   	  	  _lRet2 := .F.
				   	  	  _cProds+="Item: " + aCols[_nI,_nPosItn]+" Prod.: " + AllTrim(aCols[_nI][_nPosPROD])+" - UM: "+SB1->B1_UM+ " - " + LEFT(SB1->B1_DESC,25) + CHR(13)+CHR(10)
		           	   EndIf
		           EndIf
           
		           If  SB1->B1_SEGUM $ _cUM_NO_Fracionada
		           	   If aCols[_nI,_nPosQ2U] <> Int(aCols[_nI,_nPosQ2U])
				   	  	  _lRet2 := .F.
				   	  	  _cProds+="Item: " + aCols[_nI,_nPosItn]+" Prod.: " + AllTrim(aCols[_nI][_nPosPROD])+" - 2UM: "+SB1->B1_SEGUM+ " - " + LEFT(SB1->B1_DESC,25) + CHR(13)+CHR(10)
		           	   EndIf
		           EndIf
			   EndIf
			EndIf

	     EndIf
	     
	Next _nI
	
	If Len(_aLog) > 0
		U_ITListBox( 'Documentos de consumo não estornados (MT100GRV001)' ,{{"Descrição"}} , _aLog , .F. , 1)
	EndIf
		
	If _lValidFrac1UM .And. !_lRet2
		U_ITMsg("Não é permitido fracionar a quantidade da 1a. UM de produto onde a UM For UN. Clique em mais detalhes",;//,_ntipo,_nbotao,_nmenbot,_lHelpMvc,_cbt1,_cbt2,_bMaisDetalhes
		        "Validação Fracionado","Favor informar apenas quantidades inteiras na Primeira Unidade de Medida."         ,1     ,       ,        ,         ,     ,     ,;
		        {|| Aviso("Validação Fracionado",_cProds,{"Fechar"}) } )
		_lRet:=.F.
	EndIf	
	
	If cTipo == "D" .And. _lRet .And. _lGeraNDC//AWF - 17/11/2016
	   If _lDel 
	      _lRetorno:=.T.
	      Processa( { || _lRetorno := MExcluiNDC()  } )
	      _lRet := _lRetorno
	   ElseIf _lRet//Inclui e Classifica
	      _lRet := MGeraNDC()
	   EndIf
	EndIf
	If _lRet//Classificação e Estorno da Classificação da Nota - AWF - Projeto de unificação de pedidos de troca nota - Chamado 16548
	
	   If  _cRetorno == "ACHOU_PF"
	
	       SC9->( DBSetOrder(1) )
	       SC5->(DBGoTo(_nRecSC5))   
		   If SC9->( DBSeek( SC5->C5_FILIAL + SC5->C5_NUM ) )  
	          
	          If !Empty(SC9->C9_CARGA) 
	
	             xMagHelpFis( 'MT100GRV002',;
	                          "O Pedido "+SC5->C5_NUM+" de faturamento dessa Nota de transferencia já possui carga de faturamento: "+SC9->C9_CARGA,;
	                          "Por favor inclua ou classifique essa nota novamente." )
		      ElseIf !Inclui .And. !l103Class//Estorno da Classificação
		   
		         _lRet:=U_MT100PedAlt( SC5->(RECNO()) )//Estorna a liberação do pedido
	             
	             Pergunte("MTA103",.F.)//Restaura as variaveis MV_PAR?? do programa MTA103
		      
		      EndIf
		     
		   EndIf
	
	   ElseIf  _cRetorno == "NAO_ACHOU_PF" //.AND. l103Class//Classificação
	
	       xMagHelpFis( 'MT100GRV003',;
	           "Pedido de Faturamento "+xFilial("SC5")+" "+_cPedFaturamento+" não encontrado ou Pedido de Carregamento "+_cFilCarregamento+" "+_cPedCarregamento+" não vinculado a esse Pedido de Faturamento",;
	           "Favor entrar em contato com area de TI." )
	
	         _lRet := .F.
	
	   EndIf
	
	EndIf
	
	//Gera movimento interno para desconto Tetra Pak
	If _lRet .AND. cA100FOR == 'F00004' .And. cTipo == "N"
		_lRet := DescTetraE()
	EndIf
	
	//Gera um numero de lote da italac - DEIXE SEMPRE POR ULTIMO POIS NÃO É VALIDACAO
	If _lRet .And. (Inclui .Or. l103Class)//INCLUSAO E CLASSIFICACAO DA NOTA
	   GeraLote()
	EndIf

EndIf
If _lRet
   _lUsuConfirmou:=.T.//Variavel Private usada na função MA140EstCla() do rdmake MTA140MNU.PRW
EndIf

FWRestArea(_aAreaSC5)
FWRestArea(_aAreaSC6)
FWRestArea(_aAreaSC7)
FWRestArea(_aAreaSC9)
FWRestArea(_aAreaSD3)
FWRestArea(_aArea)

Return(_lRet)

/*
===============================================================================================================================
Programa--------: MGeraNDC()
Autor-----------: Alex Wallauer
Data da Criacao-: 16/11/2016
Descrição-------: Tratamento da geracao e deleção dos titulo de NDC
Parametros------: Nenhum
Retorno---------: Lógico (.F.) Tá com erro (.T.) Tá tudo OK
===============================================================================================================================
*/
Static Function MGeraNDC()

Local lOK		:= .T.
Local _nI		:= 0
Local _cNaturez	:= GetMv("IT_NATDCT",,"")
Local _nValor	:= 0
Local _nPos		:= 0
Local _nParcela := 0
Local _aArea   	:= FWGetArea()
Local _aAreaSD2	:= SD2->(GetArea())
Local _aAreaSE1	:= SE1->(GetArea())
Local _cItens   := ""
Local _cNum		:= ""
Local _aTitNDC  := {}
Local _nPosCod	:= aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "D1_COD"     } ) // Código do Produto
Local _nPosQtd	:= aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "D1_QUANT"   } ) // Quantidade na 1ª U.M.
Local _nPosNOri	:= aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "D1_NFORI"   } )
Local _nPosSOri	:= aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "D1_SERIORI" } )
Local _nPosIOri	:= aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "D1_ITEMORI" } )
Local _nCnt01  	:= 0
Local _lLockX5 	:= .F.
Local _cNumTit  := ""

Private lMsErroAuto := .F.

SD2->( DBSetOrder(3) )//D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM
SE1->( DBSetOrder(2) )//E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
	
For _nI := 1 To Len(aCols)

      If SD2->( DBSeek( xFilial("SD2")+aCols[_nI][_nPosNOri]+aCols[_nI][_nPosSOri]+cA100FOR+cLOJA+aCols[_nI][_nPosCod]+aCols[_nI][_nPosIOri] ) )

         _nValor:= (SD2->D2_I_VLRDC + SD2->D2_I_VLPAR) * (aCols[_nI][_nPosQtd] / SD2->D2_QUANT)
         If _nValor = 0
            Loop
         EndIf

         SE1->( DBSetOrder(2) )//E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM                               +E1_PARCELA+E1_TIPO
         If !SE1->(DBSeek(xFilial("SE1")+cA100FOR  +cLOJA    +"DCT"     +AVKEY(aCols[_nI][_nPosNOri],"E1_NUM")+"01"      +"NCC" )) .AND.;
            !SE1->(DBSeek(xFilial("SE1")+cA100FOR  +cLOJA    +"DCT"     +AVKEY(aCols[_nI][_nPosNOri],"E1_NUM")+"  "      +"NCC" ))
	        Loop
	     EndIf
         
         _cNum:=CNFISCAL//SD1->D1_DOC//aCols[_nI][_nPosNOri]//Caso tenha que gerar parcelas quebrado por nf origem

         If (_nPos:=aScan(_aTitNDC,{|T| T[1] == _cNum })) = 0
 
            _cItens:=""
            _nParcela:=1

            aAdd(_aTitNDC,{ _cNum ,;     //1
                            StrZero(_nParcela,Len(SE1->E1_PARCELA)) ,;//2
                            0  ,;        //3
                            "" ,;        //4
                            {} ,;        //5
                            SD1->D1_SERIE})//6
            _nPos:=Len(_aTitNDC)

         EndIf

         _aTitNDC[_nPos,3]+=_nValor
         _cItens+= aCols[_nI][_nPosNOri]+" / "+aCols[_nI][_nPosSOri]+" / "+aCols[_nI][_nPosCod]+" / "+aCols[_nI][_nPosIOri]+CHR(13)+CHR(10)//"NF Origem / Serie Origem / Cliente / Loja / Cód. Item / Item"
         _aTitNDC[_nPos,4]:=_cItens

      EndIf
  
Next _nI
   
_cItens:=CHR(13)+CHR(10)+"NF Origem / Serie Origem / Cód. Item / Item"+CHR(13)+CHR(10)

   For _nI := 1 To Len(_aTitNDC)
//Prefixo fixo novamente = DCI
//Numero = Controle de numeração próprio iniciando do 000000001
//Para facilitar a rastreabilidade e a vida do usuário nas compensações devem ser 
//  criado: 1 campos na tabela SE1 que devem ser preenchidos automaticamente na geração da DCI
//E1_I_SEEKDCI = Preencher a chave da SF1 (F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA+E1_FORMUL) correspondente a DCI gerada   
		//Obtem número do próximo título a ser gerado.
		DBSelectArea( "ZP1" )
        ZP1->( DBSetOrder(2) )
        If ZP1->( MsSeek( xFilial('ZP1') + '  ' + "IT_CHAVEDCI" ) )//ZP1_FILPAR em branco para todas as filiais
			While !_lLockX5 .And. (++_nCnt01 < 200)
				If InTransact()
					_lLockX5 := RecLock("ZP1")
				Else
					_lLockX5 := MsRLock()
				EndIf
				If !_lLockX5
					Inkey(1)
				EndIf
			EndDo
		Else
		    ZP1->(RecLock("ZP1",.T.))
		    ZP1->ZP1_FILIAL:=xFilial("ZP1")
		    ZP1->ZP1_MODULO:="02"
		    ZP1->ZP1_GRUPO :="P"
		    ZP1->ZP1_ROTINA:="MT100GRV"
		    ZP1->ZP1_DESROT:="Ponto de Entrada na gravacao do Documento de Entrada"
		    ZP1->ZP1_PARAM :="IT_CHAVEDCI"
		    ZP1->ZP1_DESCRI:="Numeracao NF no Contas a Receber (DCI)"
		    ZP1->ZP1_TIPO  :="C"
		    ZP1->ZP1_CONTEU:=GetDCINum()//inicia do ultimo
		    _lLockX5:=.T.
		EndIf
		If _lLockX5
			_cNumTit:= AllTrim(ZP1->ZP1_CONTEU)
			ZP1->ZP1_CONTEU  := Soma1( _cNumTit, Len(SE1->E1_NUM) ) 
			If !InTransact()
				ZP1->(MsRUnLock())
			EndIf
		Else
	        _cItens+= _aTitNDC[_nI,4]
	        _cItens+= "Problema na Numeracao NF no Contas a Receber (DCI) [Parametro IT_CHAVEDCI na ZP1] "+CHR(13)+CHR(10)
			MsgStop("Problema na Numeracao NF no Contas a Receber (DCI). Parametro IT_CHAVEDCI na ZP1. Entrar em contato com a area de TI","MT100GRV004")
			lOK := .F.
		EndIf

       lMsErroAuto:=.F.	
       
       SE1->( DBSetOrder(2) )//E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM                  +E1_PARCELA   +E1_TIPO
       If lOK .And. SE1->(DBSeek(xFilial("SE1")+cA100FOR  +cLOJA  +"DCI"     +AVKEY(_cNumTit,"E1_NUM")+_aTitNDC[_nI,2]+"NDC" ))
	   
	      _cItens+= _aTitNDC[_nI,4]
	      _cItens+= "Titulo já existe com a Chave: "+CHR(13)+CHR(10)+xFilial("SE1")+" "+cA100FOR +" "+cLOJA +" "+"DCI" +" "+_cNumTit+" "+_aTitNDC[_nI,2]+" "+"NDC"+CHR(13)+CHR(10)
	      lOK := .F.
	   
	   ElseIf lOK

	      aArray:= {	{ "E1_PREFIXO"	,"DCI"						, NIL },;
						{ "E1_NUM"		,_cNumTit  					, NIL },;
						{ "E1_PARCELA"	,_aTitNDC[_nI,2]            , NIL },;
						{ "E1_TIPO"		,"NDC"						, NIL },;
						{ "E1_NATUREZ"	,_cNaturez					, NIL },;
						{ "E1_CLIENTE"	,cA100FOR	      			, NIL },;
						{ "E1_LOJA"		,cLOJA			            , NIL },;
						{ "E1_NOMCLI"	,Posicione("SA1",1,xFilial("SA1")+cA100FOR+cLOJA,"A1_NREDUZ"),NIL},;
						{ "E1_EMISSAO"	,Date()  					, NIL },;
						{ "E1_VENCTO"	,Date()						, NIL },;
						{ "E1_VENCREA"	,datavalida(Date())			, NIL },;
						{ "E1_I_VCPOR"	,datavalida(Date())			, Nil },;
						{ "E1_VALOR"	,_aTitNDC[_nI,3]			, NIL },;
			            { "E1_HIST"     ,"Ref. a NCC: "+cNFiscal    , NIL },;
						{ "E1_I_CART"	,"22"       				, NIL } }
	      MsExecAuto( {|x,y| FINA040( x , y ) } , aArray , 3 )  // 3 - Inclusao, 4 - Alteração, 5 - Exclusão
	   
	   EndIf

	   If lMsErroAuto
		  If ( __lSX8 )
		 	 RollBackSX8()
		  EndIf
	      lOK := .F.
	      _cItens+= _aTitNDC[_nI,4]+CHR(13)+CHR(10)+AllTrim(MostraErro())+CHR(13)+CHR(10)

	   ElseIf lOK

	      ConfirmSX8()
	   	  SE1->(RecLock("SE1",.F.))
	   	  SE1->E1_PREFIXO:= "DCI"//cSerie//_aTitNDC[F,6] //Por causa da inclusao manual da nota
	   	  SE1->E1_TIPO   := 'NDC'
	   	  SE1->E1_I_CHDCI:= cNFiscal+cSerie+cA100FOR+cLOJA+cTipo+If(Empty(cFormul),"N",cFormul)//SF1->(F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA+F1_TIPO+E1_FORMUL)//Campo novo COM A CHAVE DO SF1 DA nf de devolucao
	   	  SE1->(MSUnLock())

	   EndIf
	   
	   If !lOK
	      Exit
	   EndIf

   Next _nI

   If !lOK
      bBloco:={||  AVISO("MostraErro()",_cItens,{"Fechar"},3) }
      U_ITMsg("Não foi possivel gerar as NDC clique em Ver Detalhes","MT100GRV005","Verifique a(s) mensagen(s) de erro e tente novamente.",1,,,,,,bBloco)
   EndIf

FWRestArea(_aArea)
FWRestArea(_aAreaSD2)
FWRestArea(_aAreaSE1)

Return lOK

/*
===============================================================================================================================
Programa----------: MExcluiNDC()
Autor-------------: Alex Wallauer
Data da Criacao---: 16/11/2016
Descrição---------: Tratamento da deleção dos titulo de NDC
Parametros--------: Nenhum
Retorno-----------: Lógico (.F.) Tá com erro (.T.) Tá tudo OK
===============================================================================================================================
*/
Static Function MExcluiNDC()

 Local lOK 		:= .T.
 Local _aArea   := FWGetArea()
 Local _aAreaSD1:= SD1->(GetArea())
 Local _aAreaSE1:= SE1->(GetArea())
 Local _cQuery	:= ""
 Local _nRecSE1 := 0
 
 Private lMsErroAuto := .F.
 ProcRegua(0)
 IncProc("Buscando Titulo para excluir, Aguarde...")
 IncProc("Buscando Titulo para excluir, Aguarde...")
 
 SE1->( DBSetOrder(2) )//E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
 If SE1->(DBSeek( SF1->F1_FILIAL+SF1->F1_FORNECE+SF1->F1_LOJA+SF1->F1_SERIE+SF1->F1_DOC+"01NDC" ))//Gravações antigas 

   _nRecSE1:=SE1->(RECNO())

 Else//Gravações Novas 

   _cQuery := " SELECT R_E_C_N_O_ RECSE1 FROM "+RetSqlName("SE1") +" 
   _cQuery += " WHERE D_E_L_E_T_ = ' ' AND E1_I_CHDCI =  '"+SF1->(F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA+SF1->F1_TIPO+If(Empty(F1_FORMUL),"N",F1_FORMUL))+"'"
   DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQuery) , "SE1T" , .T. , .F. )
   If !SE1T->(Eof())
      _nRecSE1:=SE1T->RECSE1
   EndIf
  
  SE1T->(DBCloseArea())	
  FWRestArea(_aArea)

 EndIf
 
 If _nRecSE1 # 0
    
   SE1->(DBGoTo(_nRecSE1))
   IncProc("Excluindo Titulo: "+SE1->E1_PREFIXO+" "+SE1->E1_NUM)
   IncProc("Excluindo Titulo: "+SE1->E1_PREFIXO+" "+SE1->E1_NUM)
   
   _cChave:=SE1->(E1_FILIAL+SE1->E1_CLIENTE+SE1->E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO)
   _cChavErro:="Nota: "+SE1->E1_NUM+" / Cliente+Loja: "+SE1->E1_CLIENTE+SE1->E1_LOJA+" / Pref.: "+SE1->E1_PREFIXO+" / Parc.: "+SE1->E1_PARCELA
   
   aArray	:= {{ "E1_FILIAL"	,SE1->E1_FILIAL	, NIL },;
				{ "E1_NUM"		,SE1->E1_NUM	, NIL },;
   				{ "E1_PREFIXO"	,SE1->E1_PREFIXO, NIL },;
				{ "E1_PARCELA"	,SE1->E1_PARCELA, NIL },;
				{ "E1_TIPO"		,"NDC"			, NIL }}

       lMsErroAuto := .F.	
	   MsExecAuto( {|x,y| FINA040( x , y ) } , aArray , 5 )  // 3 - Inclusao, 4 - Alteração, 5 - Exclusão
	
       SE1->( DBSetOrder(2) )//E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
	   If lMsErroAuto .Or. SE1->(DBSeek(_cChave))//SE1->(DBSeek( SF1->F1_FILIAL+SF1->F1_FORNECE+SF1->F1_LOJA+SF1->F1_SERIE+SF1->F1_DOC+"01NDC" ))
	      _cErro:=(MostraErro())
          bBloco:={||  AVISO("MostraErro()",_cErro,{"Fechar"},3) }
          U_ITMsg("Não foi possivel excluir o titulo Tipo NDC / "+_cChavErro,"MT100GRV006","Verifique a mensagen de erro [Mais Detalhes] e tente novamente: ",1,,,,,,bBloco)
          lOK:=.F.
       EndIf
 EndIf
 
 FWRestArea(_aArea)
 FWRestArea(_aAreaSD1)
 FWRestArea(_aAreaSE1)

Return lOK

/*
===============================================================================================================================
Programa----------: MT100PedAlt(_nRecPed)
Autor-------------: Alex Wallauer
Data da Criacao---: 11/08/2016
Descrição---------: Estorna a liberação do pedido executando uma alteração via MSExecAuto()
Parametros--------: _nRecPed no PV
Retorno-----------: ( .T. ) Estorno da liberação OK ( .F. ) não conseguiu estona a liberacao
===============================================================================================================================
*/
User Function MT100PedAlt(_nRecPed)////User Function usada na função MA140EstCla() do rdmake MTA140MNU.PRW e

Local _aCabPV  :={}
Local _aItemPV :={}
Local _aItensPV:={}
Local _dDtEnt

If _nRecPed # 0
   SC5->( DBGoTo( _nRecPed ))
Else
   Return .F.
EndIf

IncProc("Lendo Pedido: "+SC5->C5_NUM)

_dDtEnt	 := If(SC5->C5_I_DTENT < Date(),Date(),SC5->C5_I_DTENT)//Para nao travar a alteracao do Pedido de faturamento

// Monta o cabeçalho do pedido
aAdd( _aCabPV, { "C5_FILIAL"	,SC5->C5_FILIAL  , Nil})//filial
aAdd( _aCabPV, { "C5_NUM"    	,SC5->C5_NUM	 , Nil})
aAdd( _aCabPV, { "C5_TIPO"	    ,SC5->C5_TIPO    , Nil})//Tipo de pedido
aAdd( _aCabPV, { "C5_I_OPER"	,SC5->C5_I_OPER  , Nil})//Tipo da operacao
aAdd( _aCabPV, { "C5_CLIENTE"	,SC5->C5_CLIENTE , NiL})//Codigo do cliente
aAdd( _aCabPV, { "C5_CLIENT" 	,SC5->C5_CLIENT	 , Nil})
aAdd( _aCabPV, { "C5_LOJAENT"	,SC5->C5_LOJAENT , NiL})//Loja para entrada
aAdd( _aCabPV, { "C5_LOJACLI"	,SC5->C5_LOJACLI , NiL})//Loja do cliente
aAdd( _aCabPV, { "C5_EMISSAO"	,SC5->C5_EMISSAO , NiL})//Data de emissao
aAdd( _aCabPV, { "C5_TRANSP" 	,SC5->C5_TRANSP	 , Nil})
aAdd( _aCabPV, { "C5_CONDPAG"	,SC5->C5_CONDPAG , NiL})//Codigo da condicao de pagamanto*
aAdd( _aCabPV, { "C5_VEND1"  	,SC5->C5_VEND1	 , Nil})
aAdd( _aCabPV, { "C5_MOEDA"	    ,SC5->C5_MOEDA   , Nil})//Moeda
aAdd( _aCabPV, { "C5_MENPAD" 	,SC5->C5_MENPAD	 , Nil})
aAdd( _aCabPV, { "C5_LIBEROK"	,SC5->C5_LIBEROK , NiL})//Liberacao Total
aAdd( _aCabPV, { "C5_TIPLIB"  	,SC5->C5_TIPLIB  , Nil})//Tipo de Liberacao
aAdd( _aCabPV, { "C5_TIPOCLI"	,SC5->C5_TIPOCLI , NiL})//Tipo do Cliente
aAdd( _aCabPV, { "C5_I_NPALE"	,SC5->C5_I_NPALE , NiL})//Numero que originou a pedido de palete
aAdd( _aCabPV, { "C5_I_PEDPA"	,SC5->C5_I_PEDPA , NiL})//Pedido Refere a um pedido de Pallet
aAdd( _aCabPV, { "C5_I_DTENT"	,_dDtEnt         , Nil})//Dt de Entrega foi alterado para data do dia
aAdd( _aCabPV, { "C5_I_TRCNF"   ,SC5->C5_I_TRCNF , Nil})
aAdd( _aCabPV, { "C5_I_BLPRC"   ,SC5->C5_I_BLPRC , Nil})
aAdd( _aCabPV, { "C5_I_FILFT"   ,SC5->C5_I_FILFT , Nil})
aAdd( _aCabPV, { "C5_I_FLFNC"   ,SC5->C5_I_FLFNC , Nil})

// Monta o item do pedido
SC6->( DBSetOrder(1) )
SC6->( DBSeek( SC5->C5_FILIAL + SC5->C5_NUM ) )

While SC6->( !Eof() ) .And. SC6->( C6_FILIAL + C6_NUM ) == SC5->C5_FILIAL + SC5->C5_NUM
	
	_aItemPV:={}
	
	aAdd( _aItemPV , { "C6_FILIAL"  ,SC6->C6_FILIAL  , Nil }) // FILIAL
	aAdd( _aItemPV , { "C6_NUM"    	,SC6->C6_NUM	 , Nil })
	aAdd( _aItemPV , { "C6_ITEM"    ,SC6->C6_ITEM    , Nil }) // Numero do Item no Pedido
	aAdd( _aItemPV , { "C6_PRODUTO" ,SC6->C6_PRODUTO , Nil }) // Codigo do Produto
	aAdd( _aItemPV , { "C6_QTDVEN"  ,SC6->C6_QTDVEN  , Nil }) // Quantidade Vendida
	aAdd( _aItemPV , { "C6_PRCVEN"  ,SC6->C6_PRCVEN  , Nil }) // Preco Unitario Liquido
	aAdd( _aItemPV , { "C6_PRUNIT"  ,SC6->C6_PRUNIT  , Nil }) // Preco Unitario Liquido
	aAdd( _aItemPV , { "C6_ENTREG"  ,SC6->C6_ENTREG  , Nil }) // Data da Entrega
	aAdd( _aItemPV , { "C6_LOJA"   	,SC6->C6_LOJA	 , Nil })
	aAdd( _aItemPV , { "C6_SUGENTR" ,SC6->C6_SUGENTR , Nil }) // Data da Entrega
	aAdd( _aItemPV , { "C6_VALOR"   ,SC6->C6_VALOR   , Nil }) // valor total do item
	aAdd( _aItemPV , { "C6_UM"      ,SC6->C6_UM      , Nil }) // Unidade de Medida Primar.
	aAdd( _aItemPV , { "C6_TES"    	,SC6->C6_TES	 , Nil })
	aAdd( _aItemPV , { "C6_LOCAL"   ,SC6->C6_LOCAL   , Nil }) // Almoxarifado
	aAdd( _aItemPV , { "C6_CF"     	,SC6->C6_CF		 , Nil })
	aAdd( _aItemPV , { "C6_DESCRI"  ,SC6->C6_DESCRI  , Nil }) // Descricao
	aAdd( _aItemPV , { "C6_QTDLIB"  ,SC6->C6_QTDLIB  , Nil }) // Quantidade Liberada
	aAdd( _aItemPV , { "C6_PEDCLI" 	,SC6->C6_PEDCLI	 , Nil })
	aAdd( _aItemPV , { "C6_I_BLPRC"	,SC6->C6_I_BLPRC , Nil })
	
	aAdd( _aItensPV ,_aItemPV )
	
	SC6->( DBSkip() )
	
EndDo

// Alteração do pedido de faturamento para consegui estornar
lMsErroAuto:=.F.

MSExecAuto( {|x,y,z| Mata410(x,y,z) } , _aCabPV , _aItensPV , 4 )

lErroSC9:=.F.
SC9->( DBSetOrder(1) )

If lMsErroAuto .Or. ( lErroSC9:=SC9->( DBSeek( SC5->C5_FILIAL+SC5->C5_NUM ) )) //Se liberou o estoque nao pode achar no SC9, portanto se achar é um erro
	
	If lErroSC9
		_cMensagem := "Erro ao Estornar a liberação do pedido de faturamento, ainda tem dados de liberacao (SC9)."
		MessageBox(_cMensagem , 'MT100GRV007' , 48 )
	Else
		_cMensagem := " ["+MostraErro()+"] "
	EndIf
	Return .F.
EndIf

Return .T.

/*
===============================================================================================================================
Programa----------: GetDCINum
Autor-------------: Alex Wallauer
Data da Criacao---: 27/09/2017
Descrição---------: Gera o proximo numero do E1_NUM
Parametros--------: nenhum
Retorno-----------: _cnum -> próximo número do TITULO
===============================================================================================================================
*/
Static Function GetDCINum()

Local _cQuery:= ""
Local _aArea := FWGetArea()
Local _cNum  := StrZero(1,Len(SE1->E1_NUM))

_cQuery := " SELECT MAX(E1_NUM) MAXIMO FROM "+RetSqlName("SE1") +" 
_cQuery += " WHERE D_E_L_E_T_ = ' ' AND E1_PREFIXO = 'DCI' AND E1_TIPO = 'NDC' AND E1_I_CHDCI <> ' ' "

DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQuery) , "SE1T" , .T. , .F. )

If !SE1T->(Eof())
   If !Empty(SE1T->MAXIMO)
      _cNum:= Soma1( SE1T->MAXIMO, Len(SE1->E1_NUM) )//StrZero(Val(SE1T->MAXIMO)+1,Len(SE1->E1_NUM))
   EndIf
EndIf

SE1T->(DBCloseArea())
FWRestArea(_aArea)

Return _cNum

/*
===============================================================================================================================
Programa----------: DescTetraE
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 31/07/2024
Descrição---------: Gera movimento interno para retirar o valor do desconto TetraPak do produto
Parametros--------: nenhum
Retorno-----------: _lRet -> L > .T. - Prossegui com a inclusão - .F. - Aborta inclusão
===============================================================================================================================
*/
Static Function DescTetraE()

Local _lRet		:= .T.
Local _nX		:= 0
Local _nProd 	:= aScan(aHeader,{|X|Upper(AllTrim(X[2])) == "D1_COD"})// Código do produto
Local _nItem 	:= aScan(aHeader,{|X|Upper(AllTrim(X[2])) == "D1_ITEM"})// Item
Local _nLoc  	:= aScan(aHeader,{|x|AllTrim(x[2]) == "D1_LOCAL"})//Armazém
Local _nConta 	:= aScan(aHeader,{|X|Upper(AllTrim(X[2])) == "D1_CONTA"})// Conta Contábil
Local _nCFOP 	:= aScan(aHeader,{|X|Upper(AllTrim(X[2])) == "D1_CF"})// CFOP
Local _nTotal	:= aScan(aHeader,{|X|Upper(AllTrim(X[2])) == "D1_TOTAL"})// Total do Item
Local _nVDesc 	:= aScan(aHeader,{|X|Upper(AllTrim(X[2])) == "D1_VALDESC"})// Desconto
Local _nVSeg 	:= aScan(aHeader,{|X|Upper(AllTrim(X[2])) == "D1_SEGURO"})// Vlr. Seguro
Local _nVDesp 	:= aScan(aHeader,{|X|Upper(AllTrim(X[2])) == "D1_DESPESA"})// Vlr. Despesa
Local _nVIPI 	:= aScan(aHeader,{|X|Upper(AllTrim(X[2])) == "D1_VALIPI"})// Vlr.IPI
Local _nVICMS 	:= aScan(aHeader,{|X|Upper(AllTrim(X[2])) == "D1_VALICM"})// Vlr.ICMS
Local _nVCof 	:= 0
Local _nVPis 	:= 0
Local _aCab		:= {}
Local _aItem 	:= {}
Local _aTotItem	:={}
Local _cTM		:= SuperGetMV("IT_TMTETRS",.F.,"600")
Local _cCFOP	:= AllTrim(SuperGetMV("IT_CFTETRE",.F.,"1101/2101/1122/2122"))
Local _nValor 	:= 0
Local _cAlias	:= "" as String

Private lMsErroAuto := .F.
_aCab := {{"D3_TM" ,_cTM , NIL},;
          {"D3_EMISSAO" ,dDataBase, NIL}}
If !ParamIXB[1] // Não é exclusão

	For _nX := 1 To Len(aCols)
		_nValor := 0
		If AllTrim(aCols[_nx][_nCFOP]) $ _cCFOP
			_cAlias := GetNextAlias()
			BeginSql alias _cAlias
				SELECT (ZM5_AVD+ZM5_QSR+ZM5_SDESN+ZM5_LAD+ZM5_APD+ZM5_CTD) ALIQ
				FROM %Table:ZM5% ZM5
				WHERE ZM5.D_E_L_E_T_ = ' '
				AND ZM5_FILIAL = %xFilial:ZM5%
				AND ZM5_PRODUT = %exp:aCols[_nx][_nProd]%
				AND %exp:dDEmissao% BETWEEN ZM5_DTINI AND ZM5_DTFIM
			EndSql
			If (_cAlias)->ALIQ > 0
				_nVPis:= MaFisRet(_nx,"IT_VALPS2")
				_nVCof:= MaFisRet(_nx,"IT_VALCF2")
				_nValor := aCols[_nx][_nTotal]-aCols[_nx][_nVDesc]-aCols[_nx][_nVSeg]-aCols[_nx][_nVDesp]
				_nValor := _nValor-aCols[_nx][_nVICMS]-aCols[_nx][_nVIPI]-_nVCof-_nVPis
				_nValor := _nValor*((_cAlias)->ALIQ/100)
				If _nValor > 0 
					_aItem := {{"D3_COD",		aCols[_nx][_nProd]	, NIL },;
								{"D3_LOCAL",	aCols[_nx][_nLoc]	, NIL },;
								{"D3_CONTA",	aCols[_nx][_nConta]	, NIL },;
								{"D3_CUSTO1",	_nValor				, NIL },;
								{"D3_CHAVEF1",	cNFiscal+cSerie+cA100FOR+cLoja+aCols[_nx][_nProd]+aCols[_nx][_nItem], nil },;
								{"D3_I_ORIGE",	"DESCTETRAE", nil } }
					aAdd(_aTotItem,_aItem)
				EndIf
			EndIf
			(_cAlias)->(DBCloseArea())
		EndIf
	Next _nX

	If Len(_aTotItem ) > 0 
		MSExecAuto({|x,y,z| MATA241(x,y,z)},_aCab,_aTotItem,3)

		If lMsErroAuto
			_lRet := .F.
			Mostraerro()
		EndIf
	EndIf
Else
	SD3->(DBSetOrder(13)) //D3_FILIAL + D3_CHAVEF1
	If SD3->(DBSeek(SF1->F1_FILIAL+SF1->F1_DOC+SF1->F1_SERIE+SF1->F1_FORNECE+SF1->F1_LOJA))
		While !SD3->(Eof()) .And. SD3->D3_FILIAL+SubStr(SD3->D3_CHAVEF1,1,22) == SF1->(F1_FILIAL+F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA)
			If SD3->D3_ESTORNO # "S"
				MsExecAuto({|x,y,z| MatA241(x,y,z)},{},Nil,6)
				If lMsErroAuto
					_lRet := .F.
					Mostraerro()
				EndIf
			EndIf
			SD3->(DBSkip())
		EndDo
	EndIf
EndIf
Return(_lRet)

/*
===============================================================================================================================
Programa----------: GeraLote
Autor-------------: Alex Wallauer
Data da Criacao---: 29/10/2024
Descrição---------: Gera um numero de lote da italac quando o campo esta em branco
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function GeraLote()
Local _nI          AS Numeric
Local nPosCod      AS Numeric
Local nPosLot      AS Numeric
Local nPosLFo      AS Numeric
Local nPosPed      AS Numeric
Local nPosIPC      AS Numeric
Local nPosLoc      AS Numeric
Local _cLote       AS Char  
Local _cCodFor     AS Char    
Local _cCodigo     AS Char    
Local _cDD_LOTEFOR AS Char        
Local _aLote       AS Array

nPosCod:=aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "D1_COD"    } ) 
nPosLot:=aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "D1_LOTECTL"} ) 
nPosLFo:=aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "D1_LOTEFOR"} ) 
nPosPed:=aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "D1_PEDIDO" } ) 
nPosIPC:=aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "D1_ITEMPC" } )
nPosLoc:=aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "D1_LOCAL"  } ) 
_aLote:={}

For _nI := 1 To Len(aCols)
	M->D1_COD     := aCols[_nI][nPosCod]
	M->D1_LOTECTL := aCols[_nI][nPosLot]
	M->D1_LOTEFOR := aCols[_nI][nPosLFo]
	M->D1_PEDIDO  := aCols[_nI][nPosPed]
	M->D1_ITEMPC  := aCols[_nI][nPosIPC]
	M->D1_LOCAL   := aCols[_nI][nPosLoc]

   If Rastro(M->D1_COD)
   
      If ( Empty(AllTrim(M->D1_LOTECTL)) .Or. "AUTO" $ M->D1_LOTECTL ) .And.;
   	     ( Empty(AllTrim(M->D1_LOTEFOR)) .Or. "AUTO" $ M->D1_LOTEFOR )
   		
   		If !Empty(M->D1_PEDIDO) .And. !Empty(M->D1_ITEMPC)
   		   _cLote  := "#" + AllTrim(M->D1_FILIAL) + AllTrim(M->D1_PEDIDO) + AllTrim(M->D1_ITEMPC) 
   	    Else
   		   _cLote  := "#" + AllTrim(cNFiscal)+AllTrim(cA100FOR)
   		EndIf
   	  
      ElseIf (  ( Empty(AllTrim(M->D1_LOTECTL)) .Or. "AUTO" $ M->D1_LOTECTL ) .And. !Empty(AllTrim(M->D1_LOTEFOR))  )  .Or.;
   	            (!Empty(AllTrim(M->D1_LOTECTL)) .And. !Empty(AllTrim(M->D1_LOTEFOR))  )
   
   		 _cLote := M->D1_LOTEFOR
   
      Else
   
   		 _cLote := M->D1_LOTECTL
   
      EndIf
   
      _cDD_LOTEFOR := AllTrim(_cLote)
   		 
      _cCodFor:=""
      If !"#" $ _cDD_LOTEFOR //.AND. !AllTrim(cA100FOR) $ _cDD_LOTEFOR//SE NÃO TEM # ADICIONA O FORNECEDOR
   	     _cCodFor:= AllTrim(cA100FOR)
      EndIf
   
      _cDD_LOTEFOR := AllTrim(_cLote)+_cCodFor
      SB8->(DBSetOrder(3)) // FILIAL+PRODUTO+LOCAL+LOTECTL+NUMLOTE+B8_DTVALID 
      If SB8->(DBSeek(xFilial("SB8")+M->D1_COD + M->D1_LOCAL + _cDD_LOTEFOR )) .OR.;
	     aScan(_aLote,M->D1_COD + M->D1_LOCAL + _cDD_LOTEFOR) > 0 
   	        
   	     _cCodigo:="A"
   	     _cDD_LOTEFOR := AllTrim(_cLote)+_cCodigo+_cCodFor
        
   	     While (SB8->(!Eof()) .And. SB8->(DBSeek(xFilial("SB8")+M->D1_COD + M->D1_LOCAL + _cDD_LOTEFOR ))) .OR.;//SE ACHAR NO SEEK  //ERRO 1 : SEEK ERRADO ****
		           aScan(_aLote,M->D1_COD + M->D1_LOCAL + _cDD_LOTEFOR) > 0 // OU NA ARRAY _aLote
        
   	        If _cCodigo <> "Z"
   	           _cCodigo:=Soma1(_cCodigo)
   	        Else//SE For "Z"
   	             Exit
   	        EndIf
   	        _cDD_LOTEFOR := AllTrim(_cLote)+_cCodigo+_cCodFor
   	     EndDo
	  EndIf
      
	  aCols[_nI][nPosLot]:= _cDD_LOTEFOR//D1_LOTECTL
	  aCols[_nI][nPosLFo]:= _cDD_LOTEFOR//D1_LOTEFOR
	  
	  aAdd(_aLote,M->D1_COD + M->D1_LOCAL + _cDD_LOTEFOR)//Guarda o  COD+LOCAL+LOTE atual por garantia para o proximo não ser igual
   EndIf
Next _nI

Return
