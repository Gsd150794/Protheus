/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Igor Melgaço  |19/02/2025| Chamado 49839. Ajuste na compensação do AVI
Igor Melgaço  |21/02/2025| Chamado 49839. Ajustes na compensação e envio de workflow
Igor Melgaço  |26/02/2025| Chamado 50028. Ajustes para leitura do Valor excedido
===============================================================================================================================
*/

#Include "RESTFUL.Ch"
#Include "TOTVS.ch"
#Include "TOPCONN.CH"

Static _nRecnoZ26 := 0
Static _nRecnoZ29 := 0

/*
===============================================================================================================================
Programa----------: MFIN021
Autor-------------: Igor Melgaço
Data da Criacao---: 21/11/2022
Descrição---------: Rotinas de Integração REST Paytrack. Chamado: 42331 
Parametros--------: 
Retorno-----------: 
===============================================================================================================================
*/ 

//*************
// POST
//*************
WsRestFul PostTitulo Description "Metodo Responsavel por gravar dados do Título na temporaria"

	WsData cCgcEmp	As Char

	WsMethod Post Description "Gravar dados do Título na tabela temporaria" WsSyntax "/PostTitulo"

End WsRestFul

WsMethod Post WsReceive cCgcEmp WsService PostTitulo
	Local cBody     := ::GetContent() As Char
	Local _cJson    := "" As Char
	Local _lRetorno := .F. As Logical

	If DecodeUtf8(cBody) <> Nil
		cBody := DecodeUtf8(cBody)
	EndIf

	_lRetorno := U_MFIN021I(cBody,,.T.,@_cJson,"I")
	
	If !_lRetorno
		//SetRestFault(400,'Ops')
		::setStatus(500) 
	EndIf

	::SetResponse( _cJson )

Return(.T.)

/*
===============================================================================================================================
Programa----------: MFIN021I
Autor-------------: Igor Melgaço
Data da Criacao---: 28/12/2022
Descrição---------: Realiza de Integração
Parametros--------: cBody
Retorno-----------:   
===============================================================================================================================
*/ 
User Function MFIN021I(cBody As Char,_cErro As Char,_lRest As Logical,_cJson As Char,_cOper As Char) As Logical
	Local lContinua     := .T. As Logical
	Local _nI           := 0 As Numeric
	Local _nZ           := 0 As Numeric
	Local _nY           := 0 As Numeric
	Local _nW           := 0 As Numeric
	Local _cIDInte      := "" As Char
	Local aVetSE2       := {} As Array
	Local _aAuxSEV      := {} As Array
	Local _aRatSEV      := {} As Array
	Local _aAuxSEZ      := {} As Array
	Local _aRatSEZ      := {} As Array
	Local _FilialHab    := .F. As Logical
	Local _cFilialJso   := "" As Char
	Local _cPrefixo     := "" As Char
	Local _cNumero      := "" As Char
	Local _cParcela     := "" As Char
	Local _cFornec 		:= "" As Char
	Local _cLoja   		:= "" As Char
	Local _cNomFor 		:= "" As Char
	Local _nValor       := 0 As Numeric
	Local _cContCont    := "" As Char	
	Local _cHist        := "" As Char
	Local _cNatureza    := "" As Char	
	Local _cCentCus     := "" As Char
	Local _dDate        := CTOD("") As Date	
	Local _dVencto      := CTOD("") As Date
	Local _cTime        := "" As Char
	Local _aAuxZ26      := {} As Array
	Local _aAuxZ27      := {} As Array
	Local _aAuxZ28      := {} As Array
	Local _aAuxZ29      := {} As Array
	Local _aVetZ27      := {} As Array
	Local _aVetZ28      := {} As Array
	Local _aParam       := {} As Array
	Local _cPNat        := "" As Char
	Local _cPContaCtb   := "" As Char
	Local _cPCentro     := "" As Char
	Local _cPHistorico  := "" As Char
	Local _cSEV_Nat     := "" As Char
	Local _cCentro  	:= "" As Char
	Local _cPreOri      := "" As Char

	//Variáveis usadas na Compensacao
	Local lRet      	:= .F. As Logical
	Local aPA_NDF   	:= {} As Array
	Local aContabil 	:= {} As Array
	Local aNF       	:= {} As Array
	Local bBlock    	:= Nil As Block
	Local aEstorno  	:= {} As Array
	Local nSldComp  	:= 0 As Numeric
	Local nTaxaPA   	:= 0 As Numeric
	Local nTaxaNF   	:= 0 As Numeric
	Local nHdl      	:= 0 As Numeric
	Local nOperacao 	:= 0 As Numeric
	Local aRecSE5   	:= {} As Array
	Local aNDFDados		:= {} As Array
	Local lHelp     	:= .T. As Logical

	Local _nRecnoZ29 	:= 0 As Numeric
	Local _cChave 		:= "" As Char
	Local _cBanco 		:= "" As Char
	Local _cAgencia 	:= "" As Char
	Local _cConta 		:= "" As Char
	Local _nValorRat 	:= 0 As Numeric

	Local _nVrRatCC 	:= 0 As Numeric
	Local _nPerRatCC 	:= 0 As Numeric
	Local _nPerRat   	:= 0 As Numeric
	Local _nRecnoAVI 	:= 0 As Numeric
	Local _nRecnoCVI 	:= 0 As Numeric
	
	Local _nValorCVI 	:= 0 As Numeric
	Local _nValorDev 	:= 0 As Numeric
	Local _cNatDevol 	:= U_ITGetMV("IT_PNATDEV","341006") As Char
	Local _cFilVencto   := U_ITGetMV("IT_PTFILVE","92") As Char
	//Local _aBaixa    	:= {}
	Local _nRatSEZ      := 0 As Numeric
	Local _cCentroRat   := "" As Char
	Local _lPNaorateia  := .F. As Logical
	Local _lPNaoIntFin  := .F. As Logical
	Local _lAFIN036     := FWIsInCallStack("U_AFIN031G") As Logical
	Local _cEmaiFin	    := "" As Char
	Local _cPEmailWork  := "" As Char
	Local _aSizes       := {} As Array
	Local _aCab         := {} As Array
	Local _aDados 	    := {} As Array
	Local _nValExc      := 0 As Numeric
	Local _nTotExc      := 0 As Numeric
	Local _cCPFCNPJ     := ""

	Default _cErro  	:= "" 
	Default _lRest  	:= .T. 
	Default _cJson  	:= "" 
	Default _cOper  	:= "I" 

	Private oJsoAux   	:= Nil As Object
	Private lMsErroAuto := .F. As Logical

	If _cOper == "I" .Or. _cOper == "R" 
		FWJsonDeserialize(cBody, @oJsoAux)

		If _cOper == "R"
			_cFilialJso := xFilial("Z29")
		Else
			_cFilialJso := oJsoAux:FILIAL
		EndIf
		
		If _lRest
			RpcClearEnv()
			RpcSetEnv("01",_cFilialJso)
		EndIf

		_FilialHab    := GetMv("MV_MULNATP",.F.)

		For _nI := 1 to Len(oJsoAux:TITULOS)

			_cIDInte   := MFIN021GNU()
			_cPrefixo  := oJsoAux:TITULOS[_nI]:PREFIXO
			_cNumero   := oJsoAux:TITULOS[_nI]:NUMERO
			_cParcela  := Space(2)
			_cTipo     := Subs(oJsoAux:TITULOS[_nI]:TIPO + Space(3),1,3)
			_nValor    := oJsoAux:TITULOS[_nI]:VALOR
			_cCPFCNPJ  := oJsoAux:TITULOS[_nI]:CGC
			_cContCont := IIf(AttIsMemberOf(oJsoAux:TITULOS[_nI], "CONTACONTABIL"),oJsoAux:TITULOS[_nI]:CONTACONTABIL,"")
			_cHist     := U_ITSUBCHR(IIf(AttIsMemberOf(oJsoAux:TITULOS[_nI], "HISTORICO"),oJsoAux:TITULOS[_nI]:HISTORICO,"")	)
			_cNatureza := IIf(AttIsMemberOf(oJsoAux:TITULOS[_nI], "NATUREZA"),oJsoAux:TITULOS[_nI]:NATUREZA,"")	
			_cCentCus  := IIf(AttIsMemberOf(oJsoAux:TITULOS[_nI], "CENTROCUSTO"),oJsoAux:TITULOS[_nI]:CENTROCUSTO,"")
			_cMultiNat := IIf(AttIsMemberOf(oJsoAux:TITULOS[_nI], "MULTINAT"),oJsoAux:TITULOS[_nI]:MULTINAT,"1")
			_dDate     := Date()
			_cTime     := Time()
			_cPreOri   := "" //IIf(_cPrefixo == "CVI" .Or. (_cPrefixo <> "AVI" .And. _cPrefixo <> "RVI" .And. AllTrim(_cTipo) == 'NF') , "AVI","   ")			
			_aParam    := MFIN021GP(_cFilialJso,_cPrefixo)
			
			If _lAFIN036
				_dVencto := MV_PAR01
			Else
				_dVencto   := IIf(_cFilialJso $ _cFilVencto,U_MFIN021VEN(_dDate),SToD(oJsoAux:TITULOS[_nI]:VENCIMENTO))
			EndIf
			
			If _cPrefixo == "CVI" 
				_cPreOri := "AVI"
			EndIf

			lContinua := .F.

			//Valida Fornecedor
			DBSelectArea("SA2")
			DBSetOrder(3)
			If DBSeek(xFilial("SA2")+_cCPFCNPJ)
				While oJsoAux:TITULOS[_nI]:CGC == AllTrim(SA2->A2_CGC) .And. SA2->(!Eof())
					If SA2->A2_MSBLQL <> '1' .And. SA2->A2_I_CLASS $ "FVJ"
						
						If SA2->A2_I_CLASS == "J"
							_cFornec := SA2->A2_COD
							_cLoja   := SA2->A2_LOJA
							_cNomFor := SA2->A2_NREDUZ

							lContinua := .T.
							Exit
						ElseIf SA2->A2_I_CLASS == "V"
							_cFornec := SA2->A2_COD
							_cLoja   := SA2->A2_LOJA
							_cNomFor := SA2->A2_NREDUZ

							lContinua := .T.
						ElseIf SA2->A2_I_CLASS == "F" .And. Empty(AllTrim(_cFornec)) 
							_cFornec := SA2->A2_COD
							_cLoja   := SA2->A2_LOJA
							_cNomFor := SA2->A2_NREDUZ

							lContinua := .T.
						EndIf
					EndIf
					SA2->(DBSkip())
				EndDo
				If !lContinua
					_cErro += " Para o Lançamento numero "+oJsoAux:TITULOS[_nI]:NUMERO+" o Fornecedor "+oJsoAux:TITULOS[_nI]:CGC+" não esta ativo ou não é Classificado como F - Fornecedor, V - Vendedor ou J - Funcionário."
				EndIf
			Else
				//Valida Fornecedor
				DBSelectArea("SA2")
				DBSetOrder(17) //A2_FILIAL+A2_I_CPF
				If DBSeek(xFilial("SA2")+_cCPFCNPJ)
					While oJsoAux:TITULOS[_nI]:CGC == AllTrim(SA2->A2_I_CPF) .And. SA2->(!Eof())
						If SA2->A2_MSBLQL <> '1' .And. SA2->A2_I_CLASS $ "FVJ"
							If SA2->A2_I_CLASS == "J"
								_cFornec := SA2->A2_COD
								_cLoja   := SA2->A2_LOJA
								_cNomFor := SA2->A2_NREDUZ

								lContinua := .T.
								Exit
							ElseIf SA2->A2_I_CLASS == "V"
								_cFornec := SA2->A2_COD
								_cLoja   := SA2->A2_LOJA
								_cNomFor := SA2->A2_NREDUZ

								lContinua := .T.
							ElseIf SA2->A2_I_CLASS == "F" .And. Empty(AllTrim(_cFornec)) 
								_cFornec := SA2->A2_COD
								_cLoja   := SA2->A2_LOJA
								_cNomFor := SA2->A2_NREDUZ

								lContinua := .T.
							EndIf
						EndIf

						SA2->(DBSkip())
					EndDo
					If !lContinua
						_cErro += " Para o Lançamento numero "+oJsoAux:TITULOS[_nI]:NUMERO+" o Fornecedor "+oJsoAux:TITULOS[_nI]:CGC+" não esta ativo ou não é Classificado como F - Fornecedor, V - Vendedor ou J - Funcionário."
					EndIf
				Else
					lContinua := .F.
					_cErro += " Para o Lançamento numero "+oJsoAux:TITULOS[_nI]:NUMERO+" o Fornecedor não foi encontrado."
				EndIf
			EndIf
			If lContinua
				If Len(_aParam) > 0
					_cBanco      := _aParam[1]
					_cAgencia    := _aParam[2]
					_cConta      := _aParam[3]
					_cPNat       := _aParam[4]
					_cPContaCtb  := _aParam[5]
					_cPCentro    := _aParam[6]
					_cPHistorico := _aParam[7]
					_cPEmailWork := _aParam[8]
					_lPNaoRateia := _aParam[9] 
					_lPNaoIntFin := _aParam[10] 
					_cEmaiFin	 := _aParam[11]
				Else
					_cBanco      := ""
					_cAgencia    := ""
					_cConta      := ""
					_cPNat       := ""
					_cPContaCtb  := ""
					_cPCentro    := ""
					_cPHistorico := ""
					_cPEmailWork := ""
					_lPNaoRateia := .F.
					_lPNaoIntFin := .F.
					_cEmaiFin	 := ""

					lContinua := .F.
					_cErro += " Parametros nao incluídos para filial "+_cFilialJso+"."
				EndIf

				If !Empty(AllTrim(_cPNat))
					_cNatureza := _cPNat
				EndIf

				If !Empty(AllTrim(_cPContaCtb))
					_cContCont := _cPContaCtb
				EndIf

				If !Empty(AllTrim(_cPCentro))
					_cCentCus := _cPCentro
				EndIf

				If !Empty(AllTrim(_cPHistorico))
					_cHist := _cPHistorico
				EndIf
			EndIf
			
			If _lAFIN036
				_lPNaoIntFin := .F.
			EndIf

			//Monta array de Dados da tabela Z26
			aAdd(_aAuxZ26, {"Z26_IDINTE", _cIDInte								, Nil})
			aAdd(_aAuxZ26, {"Z26_FILIAL", _cFilialJso							, Nil})
			aAdd(_aAuxZ26, {"Z26_NUM"	, _cNumero								, Nil})
			aAdd(_aAuxZ26, {"Z26_PREFIX", _cPrefixo							, Nil})
			aAdd(_aAuxZ26, {"Z26_TIPO"	, _cTipo									, Nil})
			aAdd(_aAuxZ26, {"Z26_EMISSA", SToD(oJsoAux:TITULOS[_nI]:EMISSAO)	, Nil})
			aAdd(_aAuxZ26, {"Z26_VENCTO", _dVencto	, Nil})
			aAdd(_aAuxZ26, {"Z26_CGC"	, oJsoAux:TITULOS[_nI]:CGC			, Nil})
			aAdd(_aAuxZ26, {"Z26_FORNEC", _cFornec								, Nil})
			aAdd(_aAuxZ26, {"Z26_LOJA"  , _cLoja								, Nil})
			aAdd(_aAuxZ26, {"Z26_NOMFOR", _cNomFor								, Nil})			
			aAdd(_aAuxZ26, {"Z26_VALOR"	, _nValor							, Nil})
			aAdd(_aAuxZ26, {"Z26_PAYLOA", cBody									, Nil})
			aAdd(_aAuxZ26, {"Z26_DATA"	, _dDate									, Nil})
			aAdd(_aAuxZ26, {"Z26_HORA"	, _cTime									, Nil})
			aAdd(_aAuxZ26, {"Z26_NATURE", _cNatureza							, Nil})
			aAdd(_aAuxZ26, {"Z26_CENTCU", _cCentCus							, Nil})
			aAdd(_aAuxZ26, {"Z26_CONTAC", _cContCont							, Nil})
			aAdd(_aAuxZ26, {"Z26_MULTIN", _cMultiNat							, Nil})
			aAdd(_aAuxZ26, {"Z26_ORIGEM", IIf(_lRest,"P","T")				, Nil})
			aAdd(_aAuxZ26, {"Z26_STATUS", "N"									, Nil})
			aAdd(_aAuxZ26, {"Z26_PREORI", _cPreOri								, Nil})

			_aVetZ27 := {}
			_aVetZ28 := {}
			_aRatSEV := {}
			
			If oJsoAux:TITULOS[_nI]:MULTINAT == "1" .And. !_lPNaorateia

				For _nZ := 1 to Len(oJsoAux:TITULOS[_nI]:RATNAT)
					
					_nValorRat := 0
					_nPerRat   := 0
					_nValExc   := 0
					_aAuxSEV   := {}
					_aAuxZ27   := {}

					_cSEV_Nat  := IIf(AttIsMemberOf(oJsoAux:TITULOS[_nI]:RATNAT[_nZ], "NATUREZA"),oJsoAux:TITULOS[_nI]:RATNAT[_nZ]:NATUREZA,"")
					_nValorRat := IIf(AttIsMemberOf(oJsoAux:TITULOS[_nI]:RATNAT[_nZ], "VALORRAT"),oJsoAux:TITULOS[_nI]:RATNAT[_nZ]:VALORRAT,0)
					//_nValorRat := IIf(_nValorRat = 0,0,_nValorRat/1000)
					_nPerRat   := IIf(AttIsMemberOf(oJsoAux:TITULOS[_nI]:RATNAT[_nZ], "PERRAT"), oJsoAux:TITULOS[_nI]:RATNAT[_nZ]:PERRAT,0)
					_nPerRat   := IIf(_nPerRat = 0,0,_nPerRat/1000)
					_cRatCC    := IIf(AttIsMemberOf(oJsoAux:TITULOS[_nI]:RATNAT[_nZ], "RATCC"),oJsoAux:TITULOS[_nI]:RATNAT[_nZ]:RATCC,"")
					_nValExc   := IIf(AttIsMemberOf(oJsoAux:TITULOS[_nI]:RATNAT[_nZ], "VALEXC"),oJsoAux:TITULOS[_nI]:RATNAT[_nZ]:VALEXC,0)
					_nTotExc   += _nValExc

					aAdd(_aAuxZ27, {"Z27_IDINTE", _cIDINTE		, Nil})
					aAdd(_aAuxZ27, {"Z27_FILIAL", _cFilialJso	, Nil})
					aAdd(_aAuxZ27, {"Z27_NUM"	, _cNumero		, Nil})
					aAdd(_aAuxZ27, {"Z27_PREFIX", _cPrefixo		, Nil})
					aAdd(_aAuxZ27, {"Z27_TIPO"	, _cTipo		, Nil})
					aAdd(_aAuxZ27, {"Z27_NATURE", _cSEV_Nat		, Nil})
					aAdd(_aAuxZ27, {"Z27_VALORR", _nValorRat	, Nil})
					aAdd(_aAuxZ27, {"Z27_PERRAT", _nPerRat		, Nil})
					aAdd(_aAuxZ27, {"Z27_RATCC" , _cRatCC		, Nil})
					aAdd(_aAuxZ27, {"Z27_VALEXC", _nValExc		, Nil})

					If _cPrefixo == "CVI" .And. _cSEV_Nat $ _cNatDevol
						_nValorDev += _nValorRat
					Else
						_nValorCVI += _nValorRat
						aAdd(_aAuxSEV, {"EV_NATUREZ", _cSEV_Nat		, Nil})
						aAdd(_aAuxSEV, {"EV_VALOR" 	, _nValorRat 	, Nil})//valor do rateio na natureza
						aAdd(_aAuxSEV, {"EV_PERC" 	, _nPerRat		, Nil})//percentual do rateio na natureza				
						aAdd(_aAuxSEV, {"EV_RATEICC", _cRatCC		, Nil})//indicando que há rateio por centro de custo
					EndIf

					_aRatSEZ := {}
					_aAuxSEZ := {}

					If _cRatCC == "1"
						_cCentroRat := ""
						For _nY := 1 to Len(oJsoAux:TITULOS[_nI]:RATNAT[_nZ]:ARATCC)

							_aAuxSEZ := {}
							_aAuxZ28 := {}

							_cCentro   := IIf(AttIsMemberOf(oJsoAux:TITULOS[_nI]:RATNAT[_nZ]:ARATCC[_nY], "CC"),oJsoAux:TITULOS[_nI]:RATNAT[_nZ]:ARATCC[_nY]:CC,"")	
							_nPerRatCC := IIf(AttIsMemberOf(oJsoAux:TITULOS[_nI]:RATNAT[_nZ]:ARATCC[_nY], "PERRAT"),oJsoAux:TITULOS[_nI]:RATNAT[_nZ]:ARATCC[_nY]:PERRAT,0)
							_nPerRatCC := IIf(ValType(_nPerRatCC)=="N",_nPerRatCC,0)
							_nPerRatCC := IIf(_nPerRatCC = 0,0,_nPerRatCC/1000)
							_nVrRatCC  := IIf(AttIsMemberOf(oJsoAux:TITULOS[_nI]:RATNAT[_nZ]:ARATCC[_nY], "VALORRAT"),oJsoAux:TITULOS[_nI]:RATNAT[_nZ]:ARATCC[_nY]:VALORRAT,0)
							//_nVrRatCC := IIf(_nVrRatCC = 0,0,_nVrRatCC/1000)

							aAdd(_aAuxZ28, {"Z28_IDINTE", _cIDINTE										, Nil})
							aAdd(_aAuxZ28, {"Z28_FILIAL", _cFilialJso									, Nil})
							aAdd(_aAuxZ28, {"Z28_NUM"	, _cNumero										, Nil})
							aAdd(_aAuxZ28, {"Z28_PREFIX", _cPrefixo										, Nil})
							aAdd(_aAuxZ28, {"Z28_TIPO"	, _cTipo										, Nil})
							aAdd(_aAuxZ28, {"Z28_NATURE", IIf(Empty(AllTrim(_cPNat)),_cSEV_Nat,_cPNat)	, Nil})
							aAdd(_aAuxZ28, {"Z28_CC"	, _cCentro										, Nil})
							aAdd(_aAuxZ28, {"Z28_PERRAT", _nPerRatCC									, Nil})
							aAdd(_aAuxZ28, {"Z28_VALORR", _nVrRatCC										, Nil})
							
							If !(_cPrefixo == "CVI" .And. _cSEV_Nat $ _cNatDevol)
								If _cCentro $ _cCentroRat
									If Len(_aRatSEZ) > 0
										For _nRatSEZ := 1 To Len(_aRatSEZ)
											If _aRatSEZ[_nRatSEZ][2][2] == _cCentro
												_aRatSEZ[_nRatSEZ][4][2] += _nVrRatCC
												_aRatSEZ[_nRatSEZ][3][2] := _aRatSEZ[_nRatSEZ][4][2] * 100 / _nValorRat
												Exit
											EndIf
										Next
									EndIf
								Else
									aAdd(_aAuxSEZ ,{"EZ_CONTA"	, _cContCont , Nil})//conta contábil na natureza                
									aAdd(_aAuxSEZ, {"EZ_CCUSTO" , _cCentro   , Nil})	//centro de custo na natureza                
									aAdd(_aAuxSEZ, {"EZ_PERC"	, _nPerRatCC , Nil})
									aAdd(_aAuxSEZ, {"EZ_VALOR"	, _nVrRatCC	 , Nil})
								EndIf
								_cCentroRat += IIf(Empty(AllTrim(_cCentroRat)),"",";") + _cCentro
							EndIf
							
							aAdd(_aVetZ28,_aAuxZ28)

							If Len(_aAuxSEZ) > 0
								aAdd(_aRatSEZ,_aAuxSEZ)
							EndIf
						Next

						If Len(_aRatSEZ) > 0
							aAdd(_aAuxSEV,{"AUTRATEICC" , _aRatSEZ, Nil })
							aAdd(_aRatSEV,_aAuxSEV)
						EndIf

					EndIf

					aAdd(_aVetZ27,_aAuxZ27)

					If Len(_aAuxSEV) > 0 
						//aAdd(_aRatSEV,_aAuxSEV)
					EndIf
					
				Next


			EndIf
			
			If _nTotExc > 0
				lContinua := .F.
				//Valida Funcionário
				DBSelectArea("SRA")
				DBSetOrder(20)
				If DBSeek(_cCPFCNPJ)
					While SRA->RA_CIC == _cCPFCNPJ .And. SRA->(!Eof())
						If SRA->RA_DEMISSA == ' '
							lContinua := .T.
							Exit
						EndIf
						SRA->(DBSkip())
					EndDo

					If lContinua
						_cCCusto := SRA->RA_CC
						_cMatric := SRA->RA_MAT
					Else
						_cErro += " Não encontrado o cadastro do funcionário " +_cNomFor+" CPF:"+_cCPFCNPJ
					EndIf
				Else
					_cErro += " Não encontrado o cadastro do funcionário " +_cNomFor+" CPF:"+_cCPFCNPJ
				EndIf
			EndIf

			//Grava Tabelas Z26,Z27 e Z28
			MFIN021GPL(_aAuxZ26,_aVetZ27,_aVetZ28)

			//Valida Filial habilitada para Rateio
			If lContinua
				If _cMultiNat == "2" .And. !_FilialHab
					lContinua := .F.
					_cErro    += " Para o Lançamento numero "+oJsoAux:TITULOS[_nI]:NUMERO+" a Filial não esta habilitada para Rateio por Natureza. Parâmetro MV_MULNATP."
				Else
					lContinua := .T.
				EndIf
			EndIf

			//Valida Prefixo
			If lContinua .And. !(_cPrefixo == "CVI" .Or. _cPrefixo == "RVI" .Or. _cPrefixo == "AVI")
				lContinua := .F.
				_cErro += " Prefixo "+_cPrefixo+" invalido para inclusao."
			EndIf

			//Monta array de Dados da tabela Z29
			aAdd(_aAuxZ29, {"Z29_FILIAL"  , _cFilialJso								, Nil})
			aAdd(_aAuxZ29, {"Z29_PREFIX"  , _cPrefixo        						, Nil})
			aAdd(_aAuxZ29, {"Z29_NUM"	  , _cNumero								, Nil})
			aAdd(_aAuxZ29, {"Z29_PARCEL"  , _cParcela								, Nil})
			aAdd(_aAuxZ29, {"Z29_TIPO"	  , _cTipo									, Nil})
			aAdd(_aAuxZ29, {"Z29_CGC"	  , oJsoAux:TITULOS[_nI]:CGC				, Nil})
			aAdd(_aAuxZ29, {"Z29_FORNEC"  , _cFornec								, Nil})
			aAdd(_aAuxZ29, {"Z29_LOJA"    , _cLoja									, Nil})
			aAdd(_aAuxZ29, {"Z29_NOMFOR"  , _cNomFor								, Nil})
			aAdd(_aAuxZ29, {"Z29_EMISSA"  , SToD(oJsoAux:TITULOS[_nI]:EMISSAO)		, Nil})
			aAdd(_aAuxZ29, {"Z29_VENCTO"  , _dVencto                     			, Nil})
			aAdd(_aAuxZ29, {"Z29_VALOR"   , _nValor   								, Nil})
			aAdd(_aAuxZ29, {"Z29_CONTAD"  , _cContCont                        		, Nil})
			aAdd(_aAuxZ29, {"Z29_HISTOR"  , _cHist                        			, Nil})
			aAdd(_aAuxZ29, {"Z29_MULTIN"  , _cMultiNat								, Nil})
			aAdd(_aAuxZ29, {"Z29_NATURE"  , _cNatureza								, Nil})
			aAdd(_aAuxZ29, {"Z29_IDINTE"  , _cIDInte								, Nil})
			aAdd(_aAuxZ29, {"Z29_STATUS"  , "N"										, Nil})
			aAdd(_aAuxZ29, {"Z29_VALEXC"  , _nTotExc  								, Nil})

			If lContinua .And. !_lPNaoIntFin

				If _cPrefixo == "CVI"
					If _nValorDev > 0
						_nValor := _nValorCVI
					EndIf
				EndIf

				//Monta array de Dados da tabela SE2
				aAdd(aVetSE2, {"E2_FILIAL"	, _cFilialJso							, Nil})
				aAdd(aVetSE2, {"E2_NUM"		, _cNumero								, Nil})
				aAdd(aVetSE2, {"E2_PREFIXO"	, _cPrefixo        						, Nil})
				aAdd(aVetSE2, {"E2_PARCELA"	, _cParcela								, Nil})
				aAdd(aVetSE2, {"E2_TIPO"	, _cTipo								, Nil})
				aAdd(aVetSE2, {"E2_FORNECE" , _cFornec								, Nil})
				aAdd(aVetSE2, {"E2_LOJA"    , _cLoja								, Nil})
				aAdd(aVetSE2, {"E2_NOMFOR"  , _cNomFor								, Nil})
				aAdd(aVetSE2, {"E2_EMISSAO" , SToD(oJsoAux:TITULOS[_nI]:EMISSAO)	, Nil})
				aAdd(aVetSE2, {"E2_VENCTO"  , _dVencto	, Nil})
				aAdd(aVetSE2, {"E2_VENCREA" , _dVencto	, Nil})
				aAdd(aVetSE2, {"E2_VALOR"   , _nValor   							, Nil})
				aAdd(aVetSE2, {"E2_CONTAD"  , _cContCont                        	, Nil})
				aAdd(aVetSE2, {"E2_HIST"    , _cHist                        		, Nil})
				aAdd(aVetSE2, {"E2_MOEDA"   , 1      								, Nil})
				aAdd(aVetSE2, {"E2_MULTNAT" , _cMultiNat							, Nil})
				aAdd(aVetSE2, {"E2_ORIGEM"  , "MFIN021"								, Nil})
				aAdd(aVetSE2, {"E2_NATUREZ" , _cNatureza							, Nil})
				aAdd(aVetSE2, {"E2_CCUSTO"  , _cCentCus								, Nil})

				If oJsoAux:TITULOS[_nI]:PREFIXO == "AVI"
					aAdd(aVetSE2, {"AUTBANCO"   , _cBanco								, Nil})
					aAdd(aVetSE2, {"AUTAGENCIA" , _cAgencia								, Nil})
					aAdd(aVetSE2, {"AUTCONTA"   , _cConta        						, Nil})
				EndIf

				If _nValorDEV > 0
					For _nW := 1 To Len(_aRatSEV)
						_aRatSEV[_nW][3][2]:= _aRatSEV[_nW][3][2] * 100 / _nValor 
					Next
				EndIf
 
				If !_lPNaorateia
					If Len(_aRatSEV) > 0
						aAdd(aVetSE2,{"AUTRATEEV", _aRatSEV, Nil})
					EndIf
				EndIf

				If _cPrefixo == "CVI"
					Begin Transaction
						DBSelectArea("SE2")
						DBSetOrder(1)
						If DBSeek(_cFilialJso+"AVI"+_cNumero+_cParcela+"PA "+_cFornec+_cLoja)
							If (_nValor + _nValorDEV) >= SE2->E2_SALDO
								
								If _nValor < SE2->E2_SALDO  
									nSldComp := _nValor
								ElseIf _nValor > SE2->E2_SALDO  
									nSldComp := SE2->E2_SALDO
								Else
									nSldComp := 0
								EndIf
								
								aAdd(aPA_NDF, SE2->(Recno()))
								
								lMsErroAuto := .F.

								MFIN021SE2(aVetSE2,@_cErro,.F.,_aAuxZ29)
								
								If lMsErroAuto
									lContinua := .F.
									DisarmTransaction()
								Else
									_nRecnoCVI    := SE2->(Recno())

									aAdd(aNF, _nRecnoCVI)

									Pergunte("AFI340", .F.)
									lContabiliza := MV_PAR11 == 1
									lAglutina 	 := MV_PAR08 == 1
									lDigita 	 := MV_PAR09 == 1
									aContabil    := {lContabiliza,lAglutina,lDigita}

									lRet := FinCmpAut(aNF, aPA_NDF, aContabil, bBlock, aEstorno, nSldComp, dDatabase, nTaxaPA ,nTaxaNF, nHdl, nOperacao, aRecSE5, aNDFDados, lHelp)

									If !lRet
										lContinua := .F.
										_cErro += "Ocorreu um erro no processo de compensacao"
										DisarmTransaction()
									Else
										lContinua := .T.
									EndIf
								EndIf

							Else
								lContinua := .F.
								_cErro += "Valor da Compensacao menor que o Saldo do Adiantamento."
							EndIf
						Else
							lContinua := .F.
							_cErro += "Registro de Compensacao sem Adiantamento."
						EndIf
						
						/*
						//Inicia o Processo de Devolucao do AVI se Houver
						If lContinua .And. _nValorDEV > 0 
							
							//Monta array de Dados da tabela SE2
							_aBaixa := {}
							
							aAdd(_aBaixa, {"E2_FILIAL"	, _cFilialJso							, Nil})
							aAdd(_aBaixa, {"E2_NUM"		, _cNumero								, Nil})
							aAdd(_aBaixa, {"E2_PREFIXO"	, "AVI"        						    , Nil})
							aAdd(_aBaixa, {"E2_PARCELA"	, _cParcela								, Nil})
							aAdd(_aBaixa, {"E2_TIPO"	, "PA "								    , Nil})
							aAdd(_aBaixa, {"E2_FORNECE" , _cFornec								, Nil})
							aAdd(_aBaixa, {"E2_LOJA"    , _cLoja								, Nil})
							
							aAdd(_aBaixa, {"AUTMOTBX" 		, "NOR" 	, Nil})
							aAdd(_aBaixa, {"AUTBANCO" 		, _cBanco 	, Nil})
							aAdd(_aBaixa, {"AUTAGENCIA" 	, _cAgencia , Nil})
							aAdd(_aBaixa, {"AUTCONTA" 		, _cConta 	, Nil})
							aAdd(_aBaixa, {"AUTDTBAIXA" 	, dDataBase , Nil})
							aAdd(_aBaixa, {"AUTDTCREDITO"	, dDataBase , Nil})
							aAdd(_aBaixa, {"AUTHIST" 		, "Baixa resultante de devolucao via Paytrack" , Nil})
							aAdd(_aBaixa, {"AUTVLRPG" 		, _nValorDev , Nil})
							
							lMsErroAuto := .F.

							//ACESSAPERG("FIN080", .F.)
							Pergunte("FIN080", .F.)
										
							MSEXECAUTO({|x,y| FINA080(x,y)}, _aBaixa, 3)

							If lMsErroAuto
								lContinua := .F.
								//MOSTRAERRO()
								_cErro += "Falha na Baixa de Devolucao do Titulo " + _cNumero
								_cErro += " MSExecAuto: [ "+MostraErro(Upper(GetSrvProfString("STARTPATH","")),"MFIN021.LOG")+" ]"
								DisarmTransaction()
							EndIf
						EndIf
						*/
						If lContinua
							MFIN021ST(lContinua,_cOper) //Atualiza Status Z26 e Z29
						EndIf
						
					End Transaction
				Else
					lContinua := MFIN021SE2(aVetSE2,@_cErro,.T.,_aAuxZ29)
					MFIN021ST(lContinua,_cOper)
				EndIf
			
			Else

				MFIN021Z29(_aAuxZ29,@_cErro,.T.)
				If !_lPNaoIntFin
					MFIN021ST(lContinua,_cOper)
				EndIf

			EndIf

			If lContinua
				_cJson += IIf(Empty(AllTrim(_cJson)),"", ",")+"{"
				_cJson += '"retorno":"200",'
				_cJson += '"mensagem":"dados incluidos com sucesso"'
				_cJson += "}"
			Else
				_cJson += IIf(Empty(AllTrim(_cJson)),"", ",")+"{"
				_cJson += '"retorno":"500",'
				_cJson += '"mensagem":"Falha da inclusao dos dados.",'
				_cJson += '"erro":"'+_cErro+'"'
				_cJson += "}"
			EndIf 

			Z26->(DBGoTo(_nRecnoZ26))
			Z26->(RecLock("Z26",.F.))
			Z26->Z26_RETORN := _cJson
			Z26->(MSUnLock())


			aAdd(_aSizes,"05")
			aAdd(_aCab,"Filial")
			aAdd(_aDados,_cFilialJso)

			aAdd(_aSizes,"10")
			aAdd(_aCab,"Prefixo")
			aAdd(_aDados,_cPrefixo)

			aAdd(_aSizes,"10")
			aAdd(_aCab,"Titulo")
			aAdd(_aDados,_cNumero)

			aAdd(_aSizes,"10")
			aAdd(_aCab,"Emissão")
			aAdd(_aDados,DToC(SToD(oJsoAux:TITULOS[_nI]:EMISSAO)))

			aAdd(_aSizes,"10")
			aAdd(_aCab,"Fornecedor")
			aAdd(_aDados,_cFornec + " - " + _cLoja)

			aAdd(_aSizes,"20")
			aAdd(_aCab,"Nome Fornecedor")
			aAdd(_aDados,_cNomFor)

			aAdd(_aSizes,"10")
			aAdd(_aCab,"Vencimento")
			aAdd(_aDados,DToC(SToD(oJsoAux:TITULOS[_nI]:VENCIMENTO)))

			aAdd(_aSizes,IIf(_nValorDEV > 0,"13","25"))
			aAdd(_aCab,"Valor")
			aAdd(_aDados,AllTrim(Transform( _nValor ,"@E 999,999,999,999,999.99")))

			If _nValorDEV > 0 
				aAdd(_aSizes,"12")
				aAdd(_aCab,"Valor de Devolução")
				aAdd(_aDados,AllTrim(Transform( _nValorDEV ,"@E 999,999,999,999,999.99")))
			EndIf

			If lContinua .And. !Empty(AllTrim(_cPEmailWork))
				MFIN021E(_cPEmailWork,_aDados,_aCab,_aSizes,_cOper)
			EndIf

			If ( _cPrefixo == "CVI" .Or. _cPrefixo == "AVI" ) .And. !Empty(AllTrim(_cEmaiFin))
				MFIN021E(_cEmaiFin,_aDados,_aCab,_aSizes,_cOper)
			EndIf
		Next
	ElseIf _cOper == "E" .Or. _cOper == "X" //_cOper == "E" => Operação de Exclusão da Tabela 29 e _cOper == "X" e
		If !_lRest

			lContinua := .F.

			If _cOper == "E"

				If Z29->Z29_STATUS $ "I;R" 
					DBSelectArea("Z26")
					DBSetOrder(1)
					If DBSeek(Z29->Z29_IDINTE)
						lContinua := .T.
						_nRecnoZ29 := Z29->(Recno())
						_cChave    := Z29->Z29_FILIAL+Z29->Z29_PREFIX+Z29->Z29_NUM+Z29->Z29_PARCEL+Z29->Z29_TIPO+Z29->Z29_FORNEC+Z29->Z29_LOJA
					Else
						_cErro := "Não encontrado registro de integração."
						lContinua := .F.
					EndIf
				Else
					_cErro := "Com este status não será permitida a sua exclusão."
					lContinua := .F.
				EndIf

			ElseIf _cOper == "X"
				If !Z26->Z26_EXCLUI .And. (Z26->Z26_STATUS == 'I' .Or. Z26->Z26_STATUS == 'R')
					lContinua := .T.
					_cChave    := Z26->Z26_FILIAL+Z26->Z26_PREFIX+Z26->Z26_NUM+Z26->Z26_PARCEL+Z26->Z26_TIPO+Z26->Z26_FORNEC+Z26->Z26_LOJA
				Else
					If Z26_EXCLUI
						_cErro := "Registro já excluido anteriormente!."
					Else
						_cErro := "Com este status não será permitida a sua exclusão."
					EndIf
					lContinua := .F.
				EndIf
			EndIf

			If lContinua 
				_nRecnoZ26 := Z26->(Recno())

				DBSelectArea("SE2")
				DBSetOrder(1)
				If DBSeek(_cChave)

					aAdd(aVetSE2, {"E2_FILIAL"  ,SE2->E2_FILIAL         , Nil})
					aAdd(aVetSE2, {"E2_PREFIXO" ,SE2->E2_PREFIXO        , Nil})
					aAdd(aVetSE2, {"E2_NUM"	    ,SE2->E2_NUM     	    , Nil})
					aAdd(aVetSE2, {"E2_TIPO"	,SE2->E2_TIPO    	    , Nil})
					aAdd(aVetSE2, {"E2_FORNECE" ,SE2->E2_FORNECE       	, Nil})
					aAdd(aVetSE2, {"E2_LOJA"	,SE2->E2_LOJA           , Nil})
					aAdd(aVetSE2, {"E2_ORIGEM"  ,SE2->E2_ORIGEM       	, Nil}) 
					aAdd(aVetSE2, {"E2_NATUREZ" ,SE2->E2_NATUREZ       	, Nil}) 

					//====================================================================================================
					// Altera o modulo para Financeiro, senao o SigaAuto nao executa.
					//====================================================================================================
					nModulo := 6
					cModulo := "FIN"
											
					Begin Transaction
						
						lMsErroAuto := .F.
						MSExecAuto({|x,y,z| FINA050(x,y,z)}, aVetSE2,,5)  //Exclusão

						If lMsErroAuto
							lContinua := .F. 
							//MostraErro()
							_cErro += "MSExecAuto: [ "+MostraErro(Upper(GetSrvProfString("STARTPATH","")),"MFIN021.LOG")+" ]"
							DisarmTransaction()
						Else
							lContinua := .T.

							DBSelectArea("Z26")
							Z26->(DBGoTo(_nRecnoZ26))
							If RecLock("Z26", .F.)
								Z26->Z26_EXCLUI := .T.
								Z26->(MSUnLock())
							Else
								lContinua := .F. 
								_cErro += "Registro "+AllTrim(Str(_nRecnoZ26))+ " Locado"
								DisarmTransaction()
							EndIf

							_cIDInte   := MFIN021GNU()
							
							_dDate     := Date()
							_cTime     := Time()
							
							//Monta array de Dados da tabela Z26
							aAdd(_aAuxZ26, {"Z26_IDINTE", _cIDInte				, Nil})
							aAdd(_aAuxZ26, {"Z26_FILIAL", Z26->Z26_FILIAL       , Nil})
							aAdd(_aAuxZ26, {"Z26_NUM"	, Z26->Z26_NUM			, Nil})
							aAdd(_aAuxZ26, {"Z26_PREFIX", Z26->Z26_PREFIX		, Nil})
							aAdd(_aAuxZ26, {"Z26_TIPO"	, Z26->Z26_TIPO			, Nil})
							aAdd(_aAuxZ26, {"Z26_EMISSA", Z26->Z26_EMISSAO		, Nil})
							aAdd(_aAuxZ26, {"Z26_VENCTO", Z26->Z26_VENCTO      	, Nil})
							aAdd(_aAuxZ26, {"Z26_VALOR"	, Z26->Z26_VALOR		, Nil})
							aAdd(_aAuxZ26, {"Z26_CGC"	, Z26->Z26_CGC			, Nil})
							aAdd(_aAuxZ26, {"Z26_FORNEC", Z26->Z26_FORNEC		, Nil})
							aAdd(_aAuxZ26, {"Z26_LOJA"  , Z26->Z26_LOJA			, Nil})
							aAdd(_aAuxZ26, {"Z26_NOMFOR", Z26->Z26_NOMFOR		, Nil})	
							aAdd(_aAuxZ26, {"Z26_DATA"	, _dDate				, Nil})
							aAdd(_aAuxZ26, {"Z26_HORA"	, _cTime				, Nil})
							aAdd(_aAuxZ26, {"Z26_NATURE", Z26->Z26_NATURE		, Nil})
							aAdd(_aAuxZ26, {"Z26_MULTIN", Z26->Z26_MULTIN       , Nil})
							aAdd(_aAuxZ26, {"Z26_ORIGEM", "T" /* Totvs Protheus */   , Nil})
							aAdd(_aAuxZ26, {"Z26_STATUS", "E" /* Exclusão */    , Nil})
							aAdd(_aAuxZ26, {"Z26_PROCES", .T.           		, Nil})
							aAdd(_aAuxZ26, {"Z26_PREORI", Z26->Z26_PREFIX		, Nil})
							aAdd(_aAuxZ26, {"Z26_IDORIG", Z26->Z26_IDINTE		, Nil})
							aAdd(_aAuxZ26, {"Z26_PAYLOA", Z26->Z26_PAYLOA		, Nil})

							MFIN021GPL(_aAuxZ26)

							If _cOper == "E"
								DBSelectArea("Z29")
								Z29->(DBGoTo(_nRecnoZ29))
								RecLock("Z29", .F.)
								Z29->Z29_IDINTE := _cIDInte
								Z29->Z29_STATUS := "E"
								Z29->(MSUnLock())
							EndIf

						EndIf

					End Transaction
				Else
					lContinua := .F.
					_cErro += " Titulo não encontrado no Contas a Pagar para exclusão!"
				EndIf
			Else
				_cErro += " Não encontrado registro de payload para exclusão na tabela Z26!"
			EndIf
		EndIf
	ElseIf _cOper == "Z"  //Tratamento para Exclusão da Compensação
			
			_nRecnoZ26 := Z26->(Recno())
			_cChave    := Z26->Z26_FILIAL+Z26->Z26_PREFIX+Z26->Z26_NUM+Z26->Z26_PARCEL+Z26->Z26_TIPO+Z26->Z26_FORNEC+Z26->Z26_LOJA

			DBSelectArea("SE2")
			DBSetOrder(1)
			If DBSeek(_cChave)
				_nRecnoCVI    := SE2->(Recno())
			EndIf

			_nRecnoZ29 := Z29->(Recno())
			_cChave    := Z29->Z29_FILIAL+Z29->Z29_PREFIX+Z29->Z29_NUM+Z29->Z29_PARCEL+Z29->Z29_TIPO+Z29->Z29_FORNEC+Z29->Z29_LOJA
			_cPreOri   := Z29->Z29_PREFIX

			DBSelectArea("SE2")
			DBSetOrder(1)
			If DBSeek(_cChave)
				_nRecnoAVI    := SE2->(Recno())
			EndIf

			//====================================================================================================
			// Altera o modulo para Financeiro, senao o SigaAuto nao executa.
			//====================================================================================================
			nModulo := 6
			cModulo := "FIN"
			//====================================================================================================

			nOperacao := 3 //Exclusao
									
			Begin Transaction

				aAdd(aPA_NDF, _nRecnoAVI)
				aAdd(aNF, _nRecnoCVI)

				Pergunte("AFI340", .F.)
				lContabiliza := MV_PAR11 == 1
				lAglutina 	 := MV_PAR08 == 1
				lDigita 	 := MV_PAR09 == 1
				aContabil    := {lContabiliza,lAglutina,lDigita}

				lRet := FinCmpAut(aNF, aPA_NDF, aContabil, bBlock, {{_nRecnoAVI}}/*aEstorno*/, nSldComp, dDatabase, nTaxaPA ,nTaxaNF, nHdl, nOperacao, aRecSE5, aNDFDados, lHelp)

				If !lRet
					lContinua := .F.
					_cErro += "Ocorreu um erro no processo de exclusão da compensação"
					DisarmTransaction()
				Else
					lContinua := .T.
					//MFIN021ST(lContinua,_cOper) //Atualiza Status Z26 e Z29
				EndIf
			
				If lContinua

					_cIDInte   := MFIN021GNU()
					
					_dDate     := Date()
					_cTime     := Time()
					
					//Monta array de Dados da tabela Z26
					aAdd(_aAuxZ26, {"Z26_IDINTE", _cIDInte								, Nil})
					aAdd(_aAuxZ26, {"Z26_FILIAL", Z26->Z26_FILIAL   					, Nil})
					aAdd(_aAuxZ26, {"Z26_NUM"	, Z26->Z26_NUM							, Nil})
					aAdd(_aAuxZ26, {"Z26_PREFIX", Z26->Z26_PREFIX						, Nil})
					aAdd(_aAuxZ26, {"Z26_TIPO"	, Z26->Z26_TIPO							, Nil})
					aAdd(_aAuxZ26, {"Z26_EMISSA", Z26->Z26_EMISSAO                  	, Nil})
					aAdd(_aAuxZ26, {"Z26_VENCTO", Z26->Z26_VENCTO                   	, Nil})
					aAdd(_aAuxZ26, {"Z26_VALOR"	, Z26->Z26_VALOR					    , Nil})
					aAdd(_aAuxZ26, {"Z26_CGC"	, Z26->Z26_CGC				            , Nil})
					aAdd(_aAuxZ26, {"Z26_FORNEC", Z26->Z26_FORNEC						, Nil})
					aAdd(_aAuxZ26, {"Z26_LOJA"  , Z26->Z26_LOJA							, Nil})
					aAdd(_aAuxZ26, {"Z26_NOMFOR", Z26->Z26_NOMFOR						, Nil})	
					aAdd(_aAuxZ26, {"Z26_DATA"	, _dDate								, Nil})
					aAdd(_aAuxZ26, {"Z26_HORA"	, _cTime								, Nil})
					aAdd(_aAuxZ26, {"Z26_NATURE", Z26->Z26_NATURE						, Nil})
					aAdd(_aAuxZ26, {"Z26_MULTIN", Z26->Z26_MULTIN		                , Nil})
					aAdd(_aAuxZ26, {"Z26_ORIGEM", "T"           		                , Nil})
					aAdd(_aAuxZ26, {"Z26_STATUS", "E"           		                , Nil})
					aAdd(_aAuxZ26, {"Z26_PROCES", .T.           		                , Nil})
					aAdd(_aAuxZ26, {"Z26_PREORI", _cPreOri								, Nil})

					MFIN021GPL(_aAuxZ26)

				EndIf

			End Transaction
			

	EndIf

Return(lContinua)

/*
===============================================================================================================================
Programa----------: MFIN021E
Autor-------------: Igor Melgaço
Data da Criacao---: 28/12/2022
Descrição---------: Envia de Email de integração
Parametros--------: 
Retorno-----------:   
===============================================================================================================================
*/ 
Static Function MFIN021E(_cEmail As Char,_aDados As Array,_aCab As Array,_aSizes As Array,_cOper As Char) As Logical
	Local _cMsgEml   := "" As Char
	Local _cTit      := "INTEGRAÇÃO DE PAGAMENTOS PAYTRACK" As Char
	Local _cTit2     := "Foi "+Iif(_cOper == "E","excluído",Iif(_cOper == "R","reintegrado","incluído"))+" no Protheus o "+Iif(_aDados[2]="AVI","Adiantamento",Iif(_aDados[2]="CVI","Compensação","Reembolso"))+" de Viagem abaixo" As Char
	Local _cGetAssun := Iif(_cOper == "E","Exclusão",Iif(_cOper == "R","Reintegração","Inclusão"))+" de "+Iif(_aDados[2]="AVI","Adiantamento",Iif(_aDados[2]="CVI","Compensação","Reembolso"))+" de Viagem via Paytrack" As Char
	Local _aConfig   := {} As Array
	Local _cTo 	     := "" As Char
	Local _cCC 	     := "" As Char
	Local _cGetAnx   := "" As Char
	Local _cCCO      := "" As Char
	Local _cGetLista := "" As Char
	Local _cEmlLog   := "" As Char
	Local _lReturn   := .F. As Logical
	Local _nI        := 0 As Numeric

	//Logo Italac
	_cMsgEml := '<html>'
	_cMsgEml += '<head><title>'+_cTit+'</title></head>'
	_cMsgEml += '<body>'
	_cMsgEml += '<style Type="text/css"><!--'
	_cMsgEml += 'table.bordasimples { border-collapse: collapse; }'
	_cMsgEml += 'table.bordasimples tr td { border:1px solid #777777; }'
	_cMsgEml += 'td.titulos	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #C6E2FF; }'
	_cMsgEml += 'td.grupos	{ font-family:VERDANA; font-size:10px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #E5E5E5; }'
	_cMsgEml += 'td.itens	{ font-family:VERDANA; font-size:10px; V-align:middle; margin-right: 13px; margin-left: 15px; background-color: #FFFFFF; }'
	_cMsgEml += '--></style>'
	_cMsgEml += '<center>'
	_cMsgEml += '<img src="http://www.italac.com.br/wf/italac-wf.jpg" width="600" height="50"><br>'
	_cMsgEml += '<br>'

	//Celula Azul para Título
	_cMsgEml += '<table class="bordasimples" width="800">'
	_cMsgEml += '    <tr>'
	_cMsgEml += '	     <td class="titulos"><center>'+_cTit2+'</center></td>'
	_cMsgEml += '	 </tr>'
	_cMsgEml += '</table>'
	_cMsgEml += '<br>'

	//Tabela de Dados
	_cMsgEml += '<br>'
	_cMsgEml += '<table class="bordasimples" width="1000">'
	_cMsgEml += '    <tr>'
	_cMsgEml += '		<td align="left" colspan="'+AllTrim(Str(Len(_aSizes)))+'" class="grupos"><b>'+_cGetAssun+'</b></td>'
	_cMsgEml += '    </tr>'
	_cMsgEml += '    <tr>'

	For _nI := 1 To Len(_aCab)
		_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[_nI]+'%"><b>'+_aCab[_nI]+'</b></td>'
	Next
	_cMsgEml += '    </tr>'
	_cMsgEml += '    #LISTA#'
	_cMsgEml += '</table>'

	_cGetLista := ""
	
	_cGetLista += '    <tr>'
	For _nI := 1 To Len(_aCab)
		_cGetLista += '      <td class="itens" align="center" width="'+_aSizes[_nI]+'%">'+_aDados[_nI]+'</td>'
	Next
	_cGetLista += '    </tr>'			

	_cMsgEml := StrTran(_cMsgEml,"#LISTA#",_cGetLista)

	//Rodapé
	_cMsgEml += '</center>'
	_cMsgEml += '<br>'
	_cMsgEml += '<br>'
	_cMsgEml += '    <tr>'
	_cMsgEml += '      <td class="itens" align="center" ><b>Ambiente:</b></td>'
	_cMsgEml += '      <td class="itens" align="left" > ['+ GETENVSERVER() +'] / <b>Fonte:</b> [MFIN021]</td>'
	_cMsgEml += '    </tr>'
	_cMsgEml += '</body>'
	_cMsgEml += '</html>'

	
	_aConfig := U_ITCFGEML('')
	_cTo 	 := AllTrim(_cEmail)
	_cCC 	 := ""
	_cGetAnx := ""
	_cCCO    := ""
	
	_lReturn := U_ITENVMAIL( ""  , _cTo    , _cCC, _cCCO, _cGetAssun, _cMsgEml  , _cGetAnx, _aConfig[01], _aConfig[02], _aConfig[03], _aConfig[04], _aConfig[05], _aConfig[06], _aConfig[07], @_cEmlLog )
	
Return(_lReturn)

/*
===============================================================================================================================
Programa----------: MFIN021GPL
Autor-------------: Igor Melgaço
Data da Criacao---: 28/12/2022
Descrição---------: Gravação das informaÇões de Integracão (Tabela Z26,Z27 e Z28)
Parametros--------: 
Retorno-----------:   
===============================================================================================================================
*/ 
Static Function MFIN021GPL(_aAuxZ26 As Array,_aVetZ27 As Array,_aVetZ28 As Array) As Logical
	Local _nI := 0 As Numeric
	Local _nz := 0 As Numeric
	Local _lContinua := .F. As Logical

	Default _aAuxZ26 := {}
	Default _aVetZ27 := {} 
	Default _aVetZ28 := {} 


	Z26->(RecLock("Z26",.T.))
	For _nI := 1 To Len(_aAuxZ26)
		Z26->&(_aAuxZ26[_nI,1]) := _aAuxZ26[_nI,2]
	Next
	Z26->(MSUnLock())

	_nRecnoZ26 := Z26->(Recno())

	For _nz := 1 To Len(_aVetZ27)
		_aAuxZ27 := aClone(_aVetZ27[_nz])
		Z27->(RecLock("Z27",.T.))
		For _nI := 1 To Len(_aAuxZ27)
			Z27->&(_aAuxZ27[_nI,1]) := _aAuxZ27[_nI,2]
		Next
		Z27->(MSUnLock())
	Next

	For _nz := 1 To Len(_aVetZ28)
		_aAuxZ28 := aClone(_aVetZ28[_nz])
		Z28->(RecLock("Z28",.T.))
		For _nI := 1 To Len(_aAuxZ28)
			Z28->&(_aAuxZ28[_nI,1]) := _aAuxZ28[_nI,2]
		Next
		Z28->(MSUnLock())
	Next

	_lContinua := .T.

Return

/*
===============================================================================================================================
Programa----------: MFIN021Z29
Autor-------------: Igor Melgaço
Data da Criacao---: 28/12/2022
Descrição---------: Gravação do registro de Integracão (Tabela Z29)
Parametros--------: 
Retorno-----------:   
===============================================================================================================================
*/ 
Static Function MFIN021Z29(_aAuxZ29 As Array,_cErro As Char,_lBeginTra As Logical) As Logical
	Local _nI := 0 As Numeric
	Local _nPos := 0 As Numeric
	Local _cFilial := "" As Char
	Local _cPrefixo := "" As Char
	Local _cNumero := "" As Char
	Local _cParcela := "" As Char
	Local _cTipo := "" As Char
	Local _cCodFor := "" As Char
	Local _cLoja := "" As Char
	Local _lContinua := .F. As Logical
	Local _lInclui := .F. As Logical

	If !(Len(_aAuxZ29) > 0)
		Return .F.
	EndIf

	If (_nPos := aScan(_aAuxZ29,{|A|A[1]=="Z29_FILIAL"})) <> 0
		_cFilial := _aAuxZ29[_nPos,2]
	Else
		Return .F.
	EndIf

	If (_nPos := aScan(_aAuxZ29,{|A|A[1]=="Z29_PREFIX"})) <> 0
		_cPrefixo := _aAuxZ29[_nPos,2]
	Else
		Return .F.
	EndIf

	If (_nPos := aScan(_aAuxZ29,{|A|A[1]=="Z29_NUM"})) <> 0
		_cNumero := _aAuxZ29[_nPos,2]
	Else
		Return .F.
	EndIf

	If (_nPos := aScan(_aAuxZ29,{|A|A[1]=="Z29_PARCEL"})) <> 0
		_cParcela := _aAuxZ29[_nPos,2]
	Else
		Return .F.
	EndIf

	If (_nPos := aScan(_aAuxZ29,{|A|A[1]=="Z29_TIPO"})) <> 0
		_cTipo := _aAuxZ29[_nPos,2]
	Else
		Return .F.
	EndIf

	If (_nPos := aScan(_aAuxZ29,{|A|A[1]=="Z29_FORNEC"})) <> 0
		_cCodFor := _aAuxZ29[_nPos,2]
	Else
		Return .F.
	EndIf

	If (_nPos := aScan(_aAuxZ29,{|A|A[1]=="Z29_LOJA"})) <> 0
		_cLoja := _aAuxZ29[_nPos,2]
	Else
		Return .F.
	EndIf

	If _cPrefixo <> "CVI"
		DBSelectArea("Z29")
		DBSetOrder(1)
		If DBSeek(_cFilial+_cPrefixo+_cNumero+_cParcela+_cTipo)
			If Z29->Z29_STATUS <> "N" .And. Z29->Z29_STATUS <> "E"
				_lContinua := .F.
				_cErro += "Registro ja incluido anteriormente"
			Else
				_lContinua := .T.
			EndIf
			_lInclui := .F.
		Else
			_lContinua := .T.
			_lInclui := .T.
		EndIf

		If _lContinua
			If _lBeginTra
				Begin Transaction
					Z29->(RecLock("Z29",_lInclui))
					For _nI := 1 To Len(_aAuxZ29)
						Z29->&(_aAuxZ29[_nI,1]) := _aAuxZ29[_nI,2]
					Next
					Z29->(MSUnLock())
				End Transaction
			Else
				Z29->(RecLock("Z29",_lInclui))
				For _nI := 1 To Len(_aAuxZ29)
					Z29->&(_aAuxZ29[_nI,1]) := _aAuxZ29[_nI,2]
				Next
				Z29->(MSUnLock())
			EndIf
			_nRecnoZ29 := Z29->(Recno())
		EndIf
	Else
		_lContinua := .T.
		_nRecnoZ29 := 0
	EndIf

Return _lContinua

/*
===============================================================================================================================
Programa----------: MFIN021SE2
Autor-------------: Igor Melgaço
Data da Criacao---: 28/12/2022
Descrição---------: Inclusão de Titulo no Contas a Pagar
Parametros--------: 
Retorno-----------: _lContinua  
===============================================================================================================================
*/ 
Static Function MFIN021SE2(aVetSE2 As Array,_cErro As Char,_lBeginTra As Logical,_aAuxZ29 As Array) As Logical
	Local _lContinua := .T. As Logical

	Default _lBeginTra := .T.

	_lContinua := MFIN021Z29(_aAuxZ29,@_cErro,_lBeginTra)

	If _lContinua
		If _lBeginTra
			Begin Transaction
				
				lMsErroAuto := .F.
				MSExecAuto({|x,y,z| FINA050(x,y,z)}, aVetSE2,,3)  // Inclusão

				If lMsErroAuto
					_cErro += "MSExecAuto: [ "+MostraErro(Upper(GetSrvProfString("STARTPATH","")),"MFIN021.LOG")+" ]"
					_lContinua := .F.
					DisarmTransaction()
				Else
					_lContinua := .T.
				EndIf

			End Transaction
		Else
			lMsErroAuto := .F.
			MSExecAuto({|x,y,z| FINA050(x,y,z)}, aVetSE2,,3)

			If lMsErroAuto
				_cErro += "MSExecAuto: [ "+MostraErro(Upper(GetSrvProfString("STARTPATH","")),"MFIN021.LOG")+" ]"
				_lContinua := .F.
			Else
				_lContinua := .T.
			EndIf
		EndIf
	EndIf

Return _lContinua

/*
===============================================================================================================================
Programa----------: MFIN021ST
Autor-------------: Igor Melgaço
Data da Criacao---: 28/12/2022
Descrição---------: Inclusão de Titulo no Contas a Pagar
Parametros--------: _lContinua,_cOper
Retorno-----------: 
===============================================================================================================================
*/ 
Static Function MFIN021ST(_lContinua,_cOper)

If _nRecnoZ26 <> 0 
	If _nRecnoZ26 <> Z26->(Recno())
		Z26->(DBGoTo(_nRecnoZ26))
	EndIf
	If _nRecnoZ26 = Z26->(Recno())
		Z26->(RecLock("Z26",.F.))
		Z26->Z26_PROCES := _lContinua
		Z26->Z26_STATUS := IIf(_cOper== "I",IIf(_lContinua,"I","N"),_cOper)
		Z26->(MSUnLock())
	EndIf 
EndIf
If _lContinua
	If _nRecnoZ29 <> 0
		If _nRecnoZ29 <> Z29->(Recno())
			Z29->(DBGoTo(_nRecnoZ29))
		EndIf
		If _nRecnoZ29 = Z29->(Recno())
			Z29->(DBGoTo(_nRecnoZ29))
			Z29->(RecLock("Z29",.F.))
			Z29->Z29_STATUS := IIf(_cOper $ "I;R;E",IIf(_lContinua,_cOper,IIf(Z29->Z29_STATUS $ "I;R;E",Z29->Z29_STATUS,"N")),_cOper)
			Z29->(MSUnLock())
		EndIf
	EndIf
EndIf

Return 

/*
===============================================================================================================================
Programa----------: MFIN021GP
Autor-------------: Igor Melgaço
Data da Criacao---: 28/12/2022
Descrição---------: Retorna os Parametros da Filial
Parametros--------: 
Retorno-----------: _aDados  
===============================================================================================================================
*/
Static Function MFIN021GP(_cFilial As Char,_cPrefixo As Char) As Array
	Local _aDados := {} As Array
	DBSelectArea("Z30")
	DBSetOrder(1)
	If DBSeek(_cFilial)
		If _cPrefixo == "RVI"
			aAdd(_aDados, "")
			aAdd(_aDados, "")
			aAdd(_aDados, "")
			aAdd(_aDados, Z30->Z30_RNAT)
			aAdd(_aDados, Z30->Z30_RCCON)
			aAdd(_aDados, Z30->Z30_RCCUS)
			aAdd(_aDados, Z30->Z30_RHIST)
			aAdd(_aDados, Z30->Z30_EMAILW)
			aAdd(_aDados, Z30->Z30_NRATCC)
			aAdd(_aDados, Z30->Z30_NINTFI)
			aAdd(_aDados, Z30->Z30_EMAILF)
		ElseIf _cPrefixo == "AVI" .Or. _cPrefixo == "CVI"
			aAdd(_aDados, Z30->Z30_ABANCO)
			aAdd(_aDados, Z30->Z30_AAGENC)
			aAdd(_aDados, Z30->Z30_ACONTA)
			aAdd(_aDados, Z30->Z30_ANAT)
			aAdd(_aDados, Z30->Z30_ACCON)
			aAdd(_aDados, Z30->Z30_ACCUS)
			aAdd(_aDados, Z30->Z30_AHIST)
			aAdd(_aDados, Z30->Z30_EMAILW)
			aAdd(_aDados, Z30->Z30_NRATCC)
			aAdd(_aDados, Z30->Z30_NINTFI)
			aAdd(_aDados, Z30->Z30_EMAILF)
		Else
			aAdd(_aDados, "" )
			aAdd(_aDados, "" )
			aAdd(_aDados, "" )
			aAdd(_aDados, "" )
			aAdd(_aDados, "" )
			aAdd(_aDados, "" )
			aAdd(_aDados, "" )
			aAdd(_aDados, "" )
			aAdd(_aDados, .F. )
			aAdd(_aDados, .F. )
			aAdd(_aDados, "" )
		EndIf
	EndIf
Return _aDados

/*
===============================================================================================================================
Programa----------: MFIN021GNU
Autor-------------: Igor Melgaço
Data da Criacao---: 28/12/2022
Descrição---------: Retorna proximo numero de integração
Parametros--------: 
Retorno-----------: _cRetorno   
===============================================================================================================================
*/
Static Function MFIN021GNU() As Char
	Local _cRetorno := "" As Char
	Local _cQuery   := "" As Char

	//////////////////////////////////////////////////////
	//Resgata ID de integração
	//////////////////////////////////////////////////////		
	_cQuery := " SELECT MAX(Z26_IDINTE) AS ID "
	_cQuery += " FROM " + RetSqlName("Z26")
	_cQuery += " WHERE D_E_L_E_T_ <> '*'"

	TcQuery _cQuery New Alias "QRY"

	DBSelectArea("QRY")
	DBGoTop()

	_cRetorno := StrZero(Val(Right(AllTrim(QRY->ID),10))+1,10)

	While !MayIUseCode( "Z26_IDINTE"+xFilial("Z26")+_cRetorno)  //verifica se esta na memoria, sendo usado
		_cRetorno := Soma1(_cRetorno)						 // busca o proximo numero disponivel
	EndDo

	DBSelectArea("QRY")
	DBCloseArea()

Return _cRetorno

//*************
// GET 
//*************
WsRestFul GetConsultaNF Description "Metodo Responsável por Verificar e existencia de uma NF"

	WsData cCgcEmp	As Char

	WsMethod Get Description "Verifica a existencia de uma NF " WsSyntax "/GetConsultaNF"

End WsRestFul

WsMethod Get WsReceive cCgcEmp WsService GetConsultaNF

	Local cBody     	:= ::GetContent() As Char
	Local lContinua     := .F. As Logical
	Local _cFilialJso   := "" As Char
	Local _cNotaFiscal  := "" As Char
	Local _cSerie       := "" As Char
	Local _cTipo        := "" As Char
	Local _cFornec      := "" As Char
	Local _cLoja        := "" As Char
	Local _cCNPJ        := "" As Char
	Local _cJson        := "" As Char
	Local _cMsg         := "" As Char
	Local _nOrderSF1    := 0 As Numeric
	Local _cChaveSF1    := "" As Char

	Private oJsoAux   	:= Nil

	If DecodeUtf8(cBody) <> Nil
		cBody := DecodeUtf8(cBody)
	EndIf
	
	FWJsonDeserialize(cBody, @oJsoAux)

	_cFilialJso  := oJsoAux:FILIAL

	RpcClearEnv()
	RpcSetEnv("01",_cFilialJso)

	_cNotaFiscal := oJsoAux:NUMERO_NF
	_cSerie 	 := oJsoAux:SERIE_NF
	_cCNPJ       := oJsoAux:CNPJ_NF
	_cTipo       := "NF "

	DBSelectArea("SA2")
	DBSetOrder(3)
	If DBSeek(xFilial("SA2")+_cCNPJ)
		_cFornec := SA2->A2_COD
		_cLoja   := SA2->A2_LOJA
		lContinua := .T.
	Else
		lContinua := .F.
		_cMsg := " CNPJ não encontrado"
	EndIf

	If lContinua

		If AttIsMemberOf(oJsoAux, "SERIE")
			_cSerie := oJsoAux:SERIE
			_nOrderSF1 := 1 //F1_FILIAL + F1_DOC + F1_SERIE + F1_FORNECE + F1_LOJA + F1_TIPO
			_cChaveSF1 := _cFilialJso+_cNotaFiscal+_cSerie+_cFornec+_cLoja+_cTipo
		Else
			_cSerie := Space(Len(SF1->F1_SERIE))
			_nOrderSF1 := 12 //F1_FILIAL + F1_DOC + F1_FORNECE + F1_LOJA + F1_TIPO
			_cChaveSF1 := _cFilialJso+_cNotaFiscal+_cFornec+_cLoja+_cTipo
		EndIf

		DBSelectArea("SF1")
		SF1->(DBSetOrder(_nOrderSF1))
		If DBSeek(_cChaveSF1)
			lContinua := .T.
		Else
			lContinua := .F.
			_cMsg := " Nota não encontrada"
		EndIf

	EndIf
	
	_cJson := "{" 
	_cJson += '"retorno":' + IIf(lContinua,'"200"','"400"')
	_cJson += '"mensagem":' + IIf(lContinua,'"encontrou"','"não encontrou '+_cMsg+'"')
	_cJson += "}"

	If !lContinua
		::setStatus(500)
	EndIf 

	::SetResponse( _cJson )

Return(.T.)



//*************
// GET 
//*************
WsRestFul GetControleFinanceiro Description "Metodo Responsável por Verificar a situação de um Titulo"

	WsData cCgcEmp	As Char

	WsMethod Get Description "Verifica a situação de um Titulo " WsSyntax "/GetControleFinanceiro"

End WsRestFul

WsMethod Get WsReceive cCgcEmp WsService GetControleFinanceiro

	Local cBody     	:= ::GetContent() As Char
	Local lContinua     := .F. As Logical
	Local _cFilial      := "" As Char
	Local _cPrefixo     := "" As Char
	Local _cID          := "" As Char
	Local _cTipo        := "" As Char
	Local _cDtEmiss     := "" As Char
	Local _cDtVencto    := "" As Char
	Local _cDtVencRe    := "" As Char
	Local _cDtBaixa     := "" As Char
	Local _cVrLiq       := "" As Char
	Local _cVrSaldo     := "" As Char
	Local _cStatus      := "" As Char
	Local _cFornec      := "" As Char
	Local _cLoja        := "" As Char
	Local _cCNPJ        := "" As Char

	Local _cJson        := "" As Char
	Private oJsoAux   	:= Nil As Object

	If DecodeUtf8(cBody) <> Nil
		cBody := DecodeUtf8(cBody)
	EndIf
	
	FWJsonDeserialize(cBody, @oJsoAux)

	_cFilial     := oJsoAux:FILIAL

	RpcClearEnv()
	RpcSetEnv("01",_cFilial)

	_cID         := oJsoAux:ID
	_cCNPJ       := oJsoAux:CNPJ
	_cTipo       := IIf(AttIsMemberOf(oJsoAux, "TIPO"),oJsoAux:TIPO,"RC ")
	_cPrefixo    := IIf(_cTipo="PA","AVI",IIf(_cTipo="RC ","RVI",""))

	DBSelectArea("SA2")
	DBSetOrder(3)
	If DBSeek(xFilial("SA2")+_cCNPJ)
		_cFornec := SA2->A2_COD
		_cLoja   := SA2->A2_LOJA
		lContinua := .T.
	Else
		lContinua := .F.
		_cMsg := " CNPJ não encontrado"
	EndIf

	If lContinua
		DBSelectArea("SE2")
		SE2->(DBSetOrder(1))
		If DBSeek(_cFilial+_cPrefixo+_cID+_cTipo+_cFornec+_cLoja)
			_cDtEmiss  := DToC(SE2->E2_EMISSAO)
			_cDtVencto := DToC(SE2->E2_VENCTO)
			_cDtVencRe := DToC(SE2->E2_VENCREA)
			_cDtBaixa  := DToC(SE2->E2_BAIXA)
			_cTipo     := SE2->E2_TIPO
			_cVrLiq    := AllTrim(Transform(SE2->E2_VALOR-SE2->E2_SALDO,"@E 999.999,999,999.99"))
			_cVrSaldo  := AllTrim(Transform(SE2->E2_SALDO,"@E 999.999,999,999.99"))

			If SE2->E2_SALDO <= SE2->E2_VALOR .And. SE2->E2_SALDO > 0
				_cStatus := "BAIXADO PARCIAL"
			ElseIf SE2->E2_SALDO = SE2->E2_VALOR .And. SE2->E2_SALDO > 0
				_cStatus := "EM ABERTO"
			ElseIf SE2->E2_SALDO <= 0
				_cStatus := "BAIXADO"
			EndIf
			lContinua := .T.
		Else
			lContinua := .F.
			_cMsg := " Título não encontrado"
		EndIf
	EndIf

	If lContinua
		_cJson := "{" 
		_cJson += '"retorno":"200",'
		_cJson += '"mensagem":"encontrou",'
		_cJson += '"FILIAL":"'+_cFilial+'",'
		_cJson += '"ID_PAYTRACK":"'+_cID+'",'
		_cJson += '"TIPO":"'+_cTipo+'",'
		_cJson += '"VALOR_LIQUIDADO":"'+_cVrLiq+'",'
		_cJson += '"VALOR_SALDO":"'+_cVrSaldo+'",'
		_cJson += '"DATA_EMISSAO":"'+_cDtEmiss+'",'
		_cJson += '"DATA_VENCTO":"'+_cDtVencto+'",'
		_cJson += '"DATA_VENCREA":"'+_cDtVencRe+'",'
		_cJson += '"DATA_BAIXA":"'+_cDtBaixa+'",'
		_cJson += '"STATUS":"'+_cStatus+'" '
		_cJson += "}"
	Else
		_cJson := "{" 
		_cJson += '"retorno":"500",'
		_cJson += '"mensagem":"não encontrou '+_cMsg+'"'
		_cJson += "}"

		::setStatus(500) 
	EndIf

	::SetResponse( _cJson )

Return(.T.)


/*
===============================================================================================================================
Programa----------: MFIN021VEN
Autor-------------: Igor Melgaço
Data da Criacao---: 15/09/2023
Descrição---------: Retorna a data de vencimento do título
Parametros--------: dData
Retorno-----------: dData   
===============================================================================================================================
*/
User Function MFIN021VEN(dData As Date) As Date
Local cDTVenc    := U_ITGETMV("IT_MFIN21V","14;29") As Char
Local cRegVenc   := U_ITGETMV("IT_MFIN21R","13;27") As Char
Local aReg       := StrTokArr(cRegVenc,";") As Array
Local aVenc      := StrTokArr(cDTVenc,";") As Array

If Len(aVenc) <> 2 
	aVenc := StrTokArr("14;29",";")
EndIf

If Len(aReg) <> 2
	aReg := StrTokArr("13;27",";")
EndIf

If Day(dData) < Val(aReg[1]) .Or. Day(dData) > Val(aReg[2])
	If Day(dData) < Val(aReg[1])
		dData := CTOD(AllTrim(aVenc[1])+"/"+StrZero(Month(dData),2)+"/"+AllTrim(Str(Year(dData))))
	Else
		dData := CTOD(AllTrim(aVenc[1])+"/"+StrZero(Month(dData)+1,2)+"/"+AllTrim(Str(Year(dData))))
	EndIf
Else
	dData := CTOD(AllTrim(aVenc[2])+"/"+StrZero(Month(dData),2)+"/"+AllTrim(Str(Year(dData))))
EndIf

dData := MFIN021DTU(dData,.F.,.T.,.T.)

Return(dData)

/*
===============================================================================================================================
Programa----------: IT_DTVALIDA()
Autor-------------: Igor Melgaço
Data da Criacao---: 09/10/2023
Descrição---------: Valida a Data util de acordo com os feriados
Parametros--------: dDataRef,lSoma,lConsFerEs,lConsFerMu,_cFil_SP3
Retorno-----------: dDataRef
===============================================================================================================================
*/
Static Function MFIN021DTU(dDataRef As Date,lSoma As Logical,lConsFerEs As Logical,lConsFerMu As Logical,cFil_SP3 As Char) As Date
Default lSoma      := .T.
Default lConsFerEs := .F.
Default cFil_SP3   := xFilial("SP3")

Static aFeriados  := {}

If Len(aFeriados) = 0
	aFeriados := MFIN021BF(lConsFerEs,lConsFerMu,cFil_SP3)
EndIf

dDataRef := MFIN021PDT(dDataRef,aFeriados,lSoma)

If dDataRef < Date() // se a data calculada For menor que a atual traz o Proximo dia util
	dDataRef := MFIN021PDT(dDataRef,aFeriados,.T.)
EndIf

Return dDataRef

/*
===============================================================================================================================
Programa----------: IT_DTVALIDA()
Autor-------------: Igor Melgaço
Data da Criacao---: 09/05/2023
Descrição---------: Valida a Data util de acordo com os feriados
Parametros--------: dDataRef,nDiasUteis,lSoma,lConsFerEs,_cFil_SP3
Retorno-----------: dDataRef
===============================================================================================================================
*/
Static Function MFIN021PDT(dDataRef As Date,aFeriados As Array,lSoma As Logical) As Date
Local nIncrement := 0 As Numeric

If lSoma
	nIncrement := 1
Else
	nIncrement := -1
EndIf

If Dow(dDataRef) == 1 .Or. Dow(dDataRef) == 7//Se For domingo
	dDataRef := dDataRef + IIf(Dow(dDataRef) == 1,nIncrement*IIf(lSoma,1,2),nIncrement*IIf(lSoma,2,1))
EndIf

While aScan(aFeriados, DToS(dDataRef)  ) <> 0
	dDataRef := dDataRef + nIncrement
	If Dow(dDataRef) = 1 .Or. Dow(dDataRef) == 7
		dDataRef := dDataRef + nIncrement
	EndIf
EndDo

Return dDataRef


/*
===============================================================================================================================
Programa----------: MFIN021BF()
Autor-------------: Igor Melgaço
Data da Criacao---: 09/10/2023
Descrição---------: Busca feriados
Parametros--------: lConsFerEs,lConsFerMu,_cFil_SP3
Retorno-----------: aFeriados
===============================================================================================================================
*/
Static Function MFIN021BF(lConsFerEs As Logical, lConsFerMu As Logical, cFil_SP3 As Char) As Array
Local aFeriados := {} as Array
Default cFil_SP3 := xFilial("SP3") 

DBSelectArea("SP3")
SP3->(DBSetOrder(1))
SP3->(DBGoTop())
While SP3->(!Eof())
	If SP3->P3_I_TPFER == "N" // Nacional 
		If aScan(aFeriados,DToS(SP3->P3_DATA) ) = 0
			aAdd(aFeriados,DToS(SP3->P3_DATA) )
		EndIf
	ElseIf SP3->P3_I_TPFER == "E" .And. lConsFerEs
		If cFil_SP3 == SP3->P3_FILIAL //.AND. aScan(aFeriados, DToS(SP3->P3_DATA) ) = 0
			aAdd(aFeriados, DToS(SP3->P3_DATA) )
		EndIf				
	ElseIf SP3->P3_I_TPFER == "M" .And. lConsFerMu
		If cFil_SP3 == SP3->P3_FILIAL //.AND. aScan(aFeriados, DToS(SP3->P3_DATA) ) = 0
			aAdd(aFeriados, DToS(SP3->P3_DATA) )
		EndIf			
	EndIf
	SP3->(DBSkip())
EndDo

Return aFeriados

