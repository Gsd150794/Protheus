/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |19/06/2025| Chamado 50617. Revisões diversas visando padronizar os fontes
Lucas Borges  |12/03/2025| Chamado 49303. Incluída validação se o vendedor não está bloqueado. Caso ele esteja, o execauto da 
			  |			 | MGeraNDC será desarmado mas o título da devolução permanece no financeiro.
Alex Wallauer |03/09/2025| Chamado 51670. Ajuste da Validação das diferenças entre os preços do PC X NF de entrada.
===============================================================================================================================
*/
                                                                                                                      
#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: MT100TOK
Autor-----------: Wodson Reis
Data da Criacao-: 14/04/2009
Descrição-------: Validação de documento de entrada. Em que Ponto: Este P.E. é chamado na função A103Tudok() Pode ser usado 
				para validar a inclusao da NF. Esse Ponto de Entrada é chamado 2 vezes dentro da rotina A103Tudok(). Para o 
				controle do número de vezes em que ele é chamado foi criada a variável lógica lMT100TOK, que quando For definida
				como (.F.) o ponto de entrada será chamado somente uma vez.
Caminhos--------: Compras->Atualizações->Movimentações->Documento de Entrada->Incluir
Parametros------: ParamIXB[1] - 3 Inclusão, 4 Alteração, 5 Exclusão
Retorno---------: ( .T. ) Dados validos para inclusao. / ( .F. ) Dados não validados. 
===============================================================================================================================
*/
User Function MT100TOK

Local _aArea	:= FWGetArea() As Array
Local _cAlias	:= '' As Character
Local _cAlias2	:= '' As Character
Local _cQuery	:= '' As Character
Local _cQry		:= '' As Character
Local _cQryP	:= '' As Character
Local _nQT2UM	:= 0 As Numeric
Local _cItens	:= "" As Character
Local _cItens1	:= "" As Character
Local _cItens2	:= "" As Character
Local _cFunNam	:= AllTrim( Upper( FUNNAME() ) ) As Character
Local _cFilTpc	:= SuperGetMV("IT_FILTPC",.F.,"01") As Character
Local _cGrpNob	:= SuperGetMV("IT_GRPNOBR",.F.,"1000") As Character
Local _nPtolP2	:= 0 As Numeric
Local _nPtolPU	:= SuperGetMV("IT_PTOLP2",.F.,10) As Numeric // Percentual de tolerância valor unitário PC.
Local _nPtolPC	:= SuperGetMV("IT_PTOLPC",.F.,10) As Numeric // Percentual de tolerância quantidade PC.
Local _nValToT	:= SuperGetMV("IT_VTOLPC",.F.,10) As Numeric // Tolerância valor total PC.
Local _nPerToQ	:= _nPtolPC As Numeric
Local _nVlrnObr	:= SuperGetMV("IT_VLRNOBR",.F.,200) As Numeric
Local _nValToQ	:= 0 As Numeric
Local _nPosPed	:= 0 As Numeric
Local _nPosIte	:= 0 As Numeric
Local _nPosItn	:= 0 As Numeric
Local _nTotNfs	:= 0 As Numeric
Local _nTotPed	:= 0 As Numeric
Local _nTotVuP	:= 0 As Numeric
Local _nTotVuN	:= 0 As Numeric
Local _nTotDsP 	:= 0 As Numeric
Local _nTotDsN	:= 0 As Numeric
Local _nTotIcN	:= 0 As Numeric
Local _aLogTxt	:= {} As Array
Local _aLogVld	:= {} As Array
Local _aLogVld2	:= {} As Array
Local _aLogAux	:= {} As Array
Local _aLogAu1	:= {} As Array
Local _aPedidos	:= {} As Array
Local _aColsAux	:= {} As Array
Local aCampo	:= {'Item','Produto','Ocorrências'} As Array
Local aCampVld	:= {'Índice','Pedido/Nota/Série','Dt Emissão','Item','Produto','Quantidade','Qtd Entregue','Vlr. Unit.','Desconto','Vlr Total Liq.','Ocorrência'} As Array
Local aCampVld2	:= {'Índice','Pedido/Nota/Série','Dt Emissão','Item','Produto','Quantidade','Qtd Entregue','Vlr. Unit.','Desconto','Vlr Total Liq.','TES','Ocorrência'} As Array
Local _nCont	:= 0 As Numeric
Local _nVlTotal	:= 0 As Numeric
Local _lDifPreco:= .F. As Logical
Local _lDifPC	:= .F. As Logical
Local _lDifTES	:= .F. As Logical
Local _nDifCM	:= GetMV( "IT_DIFCM"  ,, 15 ) As Numeric //Percentual minimo de diferenca de CM para bloquear processo. (16%)
Local _nDifCM2	:= GetMV( "IT_DIFCM2" ,, 10 ) As Numeric //Percentual minimo de diferenca de CM para exibir mensagem se continua ou nao. (11%)
Local _nCMorig	:= 0 As Numeric 
Local _nCMdest	:= 0 As Numeric 
Local _nDifPrd	:= 0 As Numeric 
Local _aErro1	:= {} As Array
Local _aErro2	:= {} As Array
Local _cAmzDev	:= '' As Character
Local _cAmzLog	:= '' As Character
Local _apederro := {} As Array
Local _nPosDel	:= Len(aHeader) + 1 As Numeric
Local _nI		:= 0 As Numeric
Local _nX		:= 0 As Numeric
Local _nQtdVen	:= 0 As Numeric
Local _nTotIpP	:= 0 As Numeric
Local _nTotIpN	:= 0 As Numeric
Local _ForNaoVld:= SuperGetMV("IT_FORSEMV",.F.,"F00001") As Character
Local _cAux		:= '' As Character
//====================================================================================================
// Variáveis para controle de validações e processamentos
//====================================================================================================
Local _lQtZero	:= .F. As Logical
Local _lRet		:= .T. As Logical
Local _lDifPes	:= .F. As Logical
Local _lErro	:= .T. As Logical
Local _lAtuArm	:= .F. As Logical
Local _lConFrt	:= _cFunNam == 'MATA116' As Logical
Local _lRLeite	:= AllTrim( Upper( FUNNAME() ) ) $"U_MGLT009/MGLT010" As Logical
Local _lChkXML	:= .F. As Logical
Local _lErro1	:= .F. As Logical
Local _lErro2	:= .F. As Logical

//====================================================================================================
// Guarda posicionamento do aCols para verificações e atualizações de conteúdos
//====================================================================================================
Local _nPosTes 	:= 0 As Numeric
Local _nPosCod 	:= 0 As Numeric
Local _nPosArm 	:= 0 As Numeric
Local _nPosQtd 	:= 0 As Numeric
Local _nPosQ2U 	:= 0 As Numeric
Local _nPosD2U 	:= 0 As Numeric
Local _nPosDPE 	:= 0 As Numeric
Local _nPosUsr 	:= 0 As Numeric
Local _nPosDsc 	:= 0 As Numeric
Local _nPosIcm 	:= 0 As Numeric
Local _nPosPIt 	:= 0 As Numeric
Local _nPosGrupo:= 0 As Numeric
Local _npostotal:= 0 As Numeric
Local _nPosbasen:= 0 As Numeric
Local _nposvalicm	:= 0 As Numeric
Local _nPosaliqn	:= 0 As Numeric
Local _aLogSaldos	:={} As Array
Local _alogTES		:= {} As Array
Local _nTxMoeda		:= 1 As Numeric
Local _lValidFrac1UM:=.T. As Logical
Local _cProds		:= "" As Character
Local _lRet2 		:= .T. As Logical
Local _aItensPrev	:={} As Array
Local _nMoePedido	:=1 As Numeric
Local _nPosNOri		:= GDFieldPos( "D1_NFORI"	) As Numeric
Local _nPosSOri		:= GDFieldPos( "D1_SERIORI"	) As Numeric
Local _cDtRef		:= "" As Character
Local _cMovEstSD1 	:= "" As Character
Local _cCGC 		:= "" As Character
Local _cCodCli 		:= "" As Character
Local _cLojaCli 	:= "" As Character
Local _cEmissao 	:= "" As Character
Local _cCodigo  	:= "" As Character
Local _cItem    	:= "" As Character
Local _cAliasSD2 	:= "" As Character
Local _cFilTrFil 	:= SuperGetMV("IT_FILTRAN",.F.,"20;23;24;25")
Local _cCliTrFil 	:= SuperGetMV("IT_CLITRAN",.F.,"F00001")
Local _cProTrFil 	:= SuperGetMV("IT_PROTRAN",.F.,"08130000002    ")
Local _cCodFil 		:= "" As Character
Local _aSM0 		:= {} As Array
Local _aLogSD2 		:= {} As Array
Local _nXY 			:= 0 As Numeric
Local _lGeraNDC 	:= SuperGetMV("IT_XMLCTEF",.F.,"S") == "S" As Logical
Local _lTosAlte		:= SuperGetMV("IT_TOSALTE",.F.,.T.) As Logical
Local _cValCMP		:= SuperGetMV("IT_VALCMP",.F.,"") As Character
Local _cValCMT		:= SuperGetMV("IT_VALCMT",.F.,"N") As Character

//================================================================================
// Lucas Borges Ferreira - 23/07/2012 - Incluida tratativa para que as validações 
// sejam executadas somente no TOK do Documento de Entrada. Sem isso, na rotina de
// Retorno, antes da montagem da tela, as validações também seriam executadas
// descecessariamente ou com regras incorretas, uma vez que a tela não teve os 
// dados ajustados. HELP 871 - TUDOOK e Chamdo TEPUN5
//================================================================================
If !FWIsInCallStack("SPEDNFE") .And. !FWIsInCallStack("MATA920") .And. !_lRLeite

    //Validacoes de validação do Projeto de unificação de pedidos de troca nota //AWF-TN
    Private _aLogItens  :={} As Array
    Private _lDiferente :=.F. As Logical
    Private _cPedFaturamento :="" As Character//Preenchida na funcao U_PosPedFaT()
    Private _cFilCarregamento:="" As Character//Preenchida na funcao U_PosPedFaT()
    Private _cPedCarregamento:="" As Character//Preenchida na funcao U_PosPedFaT()
    Private _cRet_TN := U_PosPedFaT(  cA100For+cLoja  ,  CNFISCAL+CSERIE  ) As Character//Essa funcao deve ser executa quando vc tá na filial de faturmento mesmo
    //Validacoes de validação do Projeto de unificação de pedidos de troca nota //AWF-TN

	_cAlias		:= GetNextAlias()
	_cAlias2	:= GetNextAlias()
	
	_cAmzDev	:= AllTrim( GetMV( "IT_AMZDEV" ) ) //Armazens nao permitidos para Devolucao
	_cAmzLog	:= AllTrim( GetMV( "IT_AMZLOG" ) ) //Armazens permitidos para logistica
	_lChkXML	:= IIf(FWIsInCallStack("COMXCOL"),.F.,GetMV( 'IT_FISBXML' ,, .F. ))
	_nPosItn    := aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "D1_ITEM"		} ) // Item do Documento
	_nPosTes    := aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "D1_TES"		} ) // Código da TES
	_nPosIT     := aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "D1_ITEMORI"	} ) // Código do item
	_nPosCod    := aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "D1_COD"		} ) // Código do Produto
	_nPosArm    := aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "D1_LOCAL"		} ) // Código do Armazém
	_nPosQtd    := aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "D1_QUANT"		} ) // Quantidade na 1ª U.M.
	_nPosQ2U    := aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "D1_QTSEGUM"	} ) // Quantidade na 2ª U.M.
	_nPosD2U    := aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "D1_SEGUM"		} ) // Segunda U.M.
	_nPosDPE    := aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == 'D1_I_DIFPE'	} ) // Diferenca de Pesagem.
	_nPosUsr    := aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "D1_I_USER"	} ) // Nome do usuário
  	_nPosPrc    := aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "D1_VUNIT"		} ) // Preço Unitário
  	_nPosItB6   := aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "D1_IDENTB6"	} )
	_nPosGrupo	:= aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "D1_GRUPO"		} )
	_nPostotal	:= aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "D1_TOTAL"		} )
	_nPosbasen	:= aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "D1_BASNDES"	} )
	_nPosvalicm	:= aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "D1_VALICM"	} )
	_nPosaliqn	:= aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "D1_ALQNDES"	} )
	_nPosPICM  	:= aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "D1_PICM"   	} )
	_nPosPedC	:= aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "D1_PEDIDO"	} ) // Numero do Pedido de Compras
	_nPosItemP	:= aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "D1_ITEMPC"	} ) // Item do Pedido de Compras

	//====================================================================================================
	// Início das validações de responsabilidade do analista Lucas - Não alterar
	//====================================================================================================
	cNFiscal := StrZero( Val( cNFiscal ) , TamSX3('F1_DOC')[01] )
	
	If cFormul == 'S' .And. !( AllTrim( cEspecie ) == 'SPED' )
		_cAux:="Documento gerado como Formulário Próprio deve ter a espécie configurada como SPED!"
		If l103Auto
			AutoGRLog("MT100TOK001"+CRLF+_cAux)
		Else
			FWAlertError(_cAux,"MT100TOK001")
		EndIf
		_lRet := .F.
	EndIf
	If _lRet .And. Empty(cSerie) .And. cFormul <> 'S'
		_cAux := "Não foi informada a Série do Documento."
		If l103Auto
			AutoGRLog("MT100TOK002"+CRLF+_cAux)
		Else
			FWAlertError(_cAux,"MT100TOK002")
		EndIf
		_lRet := .F.
	EndIf
    If _lRet .And. Type("_cFUNDFIX") = "C" 
        If Empty(AllTrim(_cFUNDFIX))
			_cAux:="Não foi informado o Fundo Fixo na Aba Italac."
    		If l103Auto
				AutoGRLog("MT100TOK003"+CRLF+_cAux)
			Else
				FWAlertError(_cAux,"MT100TOK003")
			EndIf
    		_lRet := .F.  
        EndIf
	EndIf

	//====================================================================================================
	// Validações sobre permissões de alteração de DataBase para Notas Formulário Próprio
	//====================================================================================================
	If _lRet .And. cFormul == "S" .And. Posicione("ZZL",3,xFilial("ZZL")+RetCodUsr(),"ZZL_ALDTEM") <> 'S'
		If dDataBase <> Date() .Or. dDEmissao <> Date()
			_cAux:="Para emissão de nota própria (Formulário = SIM) a Data Base do Sistema e a Data de Emissão tem que ser igual à Data Atual do Servidor"
    		If l103Auto
				AutoGRLog("MT100TOK004"+CRLF+_cAux)
			Else
				FWAlertError(_cAux,"MT100TOK004")
			EndIf
			_lRet := .F.
		EndIf
	EndIf

	//====================================================================================================
	// Caso esteja parametrizado para verificar o processamento do XML para autorizar a gravação [8459]
	//====================================================================================================
	If _lRet .And. _lChkXML .And. Upper(AllTrim(cEspecie)) $ 'SPED/CTE/CTEOS' .And. cFormul <> 'S' .And. !Empty(aNfeDanfe[13])
		SDS->(DBSetOrder(2))
		If SDS->(DBSeek(xFilial("SDS") + aNfeDanfe[13])) 
			If !SDS->DS_STATUS == 'P'
				_cAux:="Documento não foi gerado via Totvs Colaboração. Documento ainda pendente no Monitor."
				If l103Auto
					AutoGRLog("MT100TOK005"+CRLF+_cAux)
				Else
					FWAlertError(_cAux,"MT100TOK005")
				EndIf
				_lRet := .F.
			EndIf
		Else
			_lRet := .F.
			If Upper(AllTrim(cEspecie)) == 'CTE'
				_cNomArq := '214'+ aNfeDanfe[13] +'.xml'
			ElseIf Upper(AllTrim(cEspecie)) == 'SPED'
				_cNomArq := '109'+ aNfeDanfe[13] +'.xml'
			ElseIf Upper(AllTrim(cEspecie)) == 'CTEOS'
				_cNomArq := '273'+ aNfeDanfe[13] +'.xml'
			EndIf

			DBSelectArea('CKO')
			CKO->( DBSetOrder(1) )
			If CKO->( DBSeek( PadR( _cNomArq , TamSX3('CKO_ARQUIV')[01] ) ) )
				If CKO->CKO_FLAG == '1'
					_cAux:="Documento consta na fila de Excluídos no Monitor."
				//Documentos do tipo complemento. Não são tratados pelo Colaboração e tem que eser incluídos manualmente
				ElseIf CKO->CKO_CODERR $ "COM003/COM004/COM047"
						_lRet := .T.
				ElseIf CKO->CKO_FLAG == '2'
					_cAux:="Documento consta na fila de Erros no Monitor. Cód erro: "+CKO->CKO_CODERR + " - " + Rtrim(U_ColErro(CKO->CKO_CODERR))

				//Os códigos de erro abaixo realmente devem ser incluídos manualmente
				ElseIf CKO->CKO_FLAG == '9' 
					_cAux:="Documento excluído para não ser escriturado. Cód erro: "+CKO->CKO_CODERR+" - " + Rtrim(U_ColErro(CKO->CKO_CODERR))
				EndIf
			Else
				_cAux:="XML não foi recebido pelo Protheus ou ainda não foi processado."
			EndIf
			If !_lRet
				If l103Auto
					AutoGRLog("MT100TOK006"+CRLF+_cAux)
				Else
					FWAlertError(_cAux,"MT100TOK006")
				EndIf
			EndIf
		EndIf
	EndIf
    
	//====================================================================================================
    // Faz a conversão das quantidades, quando a nota fiscal For de um produto do tipo serviço e
	// e o item do pedido de compras estiver com o campo "Controla Entregas Parciais" igual a Sim.
    //====================================================================================================
    If _lRet 
       SC7->(DBSetOrder(1)) // C7_FILIAL+C7_NUM+C7_ITEM+C7_SEQUEN 
       
       _lCrtlParc := .F. // Controla quantidades parciais. 
	   //=========================================================================
	   // Array com as quantidades disponíveis e valores do pedido de compras,
	   // antes das alterações do usuário, na digitação da nota fiscal de entrada.
	   //=========================================================================	
       _aQtdProd := U_MT103RTQ()  // Col 1 = Código Produto
	                              // Col 2 = Item da Nota
								  // Col 3 = Quantidade
								  // Col 4 = Pedido de Compra
								  // Col 5 = Item Pedido de Compra
								  // Col 6 = Preço Unitário
	   
	   _nValTotDig := 0
	   _nValTotPC  := 0

	   For _nI := 1 To Len(aCols)                                                                                                                            
		   If !aCols[_nI][Len(aHeader)+1] //Não verifica linhas deletadas
		      _cPedidoC := aCols[_nI][_nPosPedC]
			  _cItemPC  := aCols[_nI][_nPosItemP]
		      If SC7->(MsSeek(xFilial("SC7")+_cPedidoC+_cItemPC)) // SC7->(MsSeek(xFilial("SC7")+aCols[_nI][_nPosPedC]+aCols[_nI][_nPosItemP]))
			     
				 _lCrtlParc := .T. // Valida as entregas parciais.

			     If SC7->C7_I_SVPAR == "S" // Controla Entregas Parciais. Faturamento parcial para produtos do tipo Serviço.
                    If SC7->C7_QUANT == 1 .And. aCols[_nI][_nPosPrc] < SC7->C7_PRECO
                       _nQtdParc := aCols[_nI][_nPosPrc] / SC7->C7_PRECO
		   		       _nPrcTot  := Round(_nQtdParc * SC7->C7_PRECO,2)
                       _nValTotDig += _nPrcTot
					   _nJ := aScan(_aQtdProd,{|x| x[4] == _cPedidoC .And. x[5] == _cItemPC})
					   If _nJ > 0 
                          _nValTotPC += (_aQtdProd[_nJ,3] * _aQtdProd[_nJ,6])
					   EndIf 
					EndIf
				 EndIf
			  EndIf 	 
           EndIf 
	   Next 
       
	   If _lCrtlParc // Valida as entregas parciais.
          _nValMax := _nValTotPC  +  _nValToT

	      If _nValTotDig > _nValMax 
             _lRet := .F.

             _cTextoMsg := "O valor total da nota ultrapassa o máximo permitido para a nota fiscal de entrada. " + CRLF
             _cTextoMsg += "Valor total permitido: " + AllTrim( Transform(_nValMax,"@E 999,999,999,999.99")) + ". " + CRLF 
		     _cTextoMsg += "Valor total informado: " + AllTrim( Transform(_nValTotDig,"@E 999,999,999,999.99")) + "."

		     If l103Auto
			 	AutoGRLog("MT100TOK06B"+CRLF+_cTextoMsg)
			 Else
				FWAlertError(_cTextoMsg,"MT100TOK06B")
			 EndIf
	      EndIf  
       EndIf 
    EndIf 

	If _lRet 
       SC7->(DBSetOrder(1)) // C7_FILIAL+C7_NUM+C7_ITEM+C7_SEQUEN  

	   For _nI := 1 To Len(aCols)                                                                                                                            
		   If !aCols[_nI][Len(aHeader)+1] //Não verifica linhas deletadas
		      If SC7->(MsSeek(xFilial("SC7")+aCols[_nI][_nPosPedC]+aCols[_nI][_nPosItemP]))
			     If SC7->C7_I_SVPAR == "S" // Controla Entregas Parciais. Faturamento parcial para produtos do tipo Serviço.
                    If SC7->C7_QUANT == 1 .And. aCols[_nI][_nPosPrc] < SC7->C7_PRECO
                       _nQtdParc := aCols[_nI][_nPosPrc] / SC7->C7_PRECO
				       _nPrcTot  := Round(_nQtdParc * SC7->C7_PRECO,2) 
                
				       aCols[_nI][_nPostotal] := _nPrcTot  // Novo preço total
					   M->D1_TOTAL := _nPrcTot 
				
				       aCols[_nI][_nPosPrc] := SC7->C7_PRECO   // Novo preço unitário. 
					   M->D1_VUNIT := SC7->C7_PRECO
					   M->D1_QUANT := _nQtdParc
                
				       aCols[_nI][_nPosQtd]   := _nQtdParc  // Nova quantidade do item na nota. 
	                   
					   If aCols[_nI][_nPosQ2U] > 0
					      _nQtd2UnPa           := aCols[_nI][_nPosQ2U] * _nQtdParc
					      aCols[_nI][_nPosQ2U] := _nQtd2UnPa 
			           EndIf 

					   //=======================================================================================
					   // Quando o item da nota For do tipo serviço e possuir controle de entregas parciais,
					   // o usuário informa no campo valor unitário o valor pago parcialmente.
					   // Este trecho calcula o percentual pago e converte as quantidade e o valor total pago.
					   // Para preencher os demais campos da tela com os valores corretos, como valor total do
					   // título, temos que simular o usuário digitando as quantidades e o valor unitário.
					   // Para isso temos que chamar algumas funções padrões da Totvs.
					   // Estas funções da Totvs alteram os valores calculados, e para cada chamada temos 
					   // que gravar nos campos os valores calculados.
					   //=======================================================================================
					   // Função padrão da Totvs para simular a digitação das quantidades 
					   //=====================================================================
                       A103Trigger("D1_QUANT") // Função padrão Totvs

                       //==============================================================
					   // A função da Totvs acima altera os valores calculados.
					   // Temos que gravar novamente nos campos os valores calculados.
					   //============================================================== 
                       aCols[_nI][_nPostotal] := _nPrcTot  
					   M->D1_TOTAL := _nPrcTot 
				
				       aCols[_nI][_nPosPrc] := SC7->C7_PRECO 
					   M->D1_VUNIT := SC7->C7_PRECO
					   M->D1_QUANT := _nQtdParc
                
				       aCols[_nI][_nPosQtd]   := _nQtdParc  
	                   
					   If aCols[_nI][_nPosQ2U] > 0
					      _nQtd2UnPa           := aCols[_nI][_nPosQ2U] * _nQtdParc
					      aCols[_nI][_nPosQ2U] := _nQtd2UnPa 
			           EndIf 
 					   
					   //===================================================================
					   // Função padrão da Totvs para simular a digitação do valor unitário.   
                       //===================================================================
                       A103Trigger("D1_VUNIT") // Função padrão Totvs
					   
					   //==============================================================
					   // A função da Totvs acima altera os valores calculados.
					   // Temos que gravar novamente nos campos os valores calculados.
					   //============================================================== 
					   aCols[_nI][_nPostotal] := _nPrcTot
					   M->D1_TOTAL := _nPrcTot 
				
				       aCols[_nI][_nPosPrc] := SC7->C7_PRECO 
					   M->D1_VUNIT := SC7->C7_PRECO
					   M->D1_QUANT := _nQtdParc
                
				       aCols[_nI][_nPosQtd]   := _nQtdParc 
	                   
					   If aCols[_nI][_nPosQ2U] > 0
					      _nQtd2UnPa           := aCols[_nI][_nPosQ2U] * _nQtdParc
					      aCols[_nI][_nPosQ2U] := _nQtd2UnPa 
			           EndIf 
 					   
					   //=====================================================================================
					   // Função padrão da Totvs para simular a digitação da quantidade, do valor unitário  
					   // e calculo do valor total. 
                       //=====================================================================================
                       A103Trigger("D1_TOTAL") // Função padrão Totvs  
                       
					   //==============================================================
					   // A função da Totvs acima altera os valores calculados.
					   // Temos que gravar novamente nos campos os valores calculados.
					   //============================================================== 
                       aCols[_nI][_nPostotal] := _nPrcTot  
					   M->D1_TOTAL := _nPrcTot 
				
				       aCols[_nI][_nPosPrc] := SC7->C7_PRECO  
					   M->D1_VUNIT := SC7->C7_PRECO
					   M->D1_QUANT := _nQtdParc
                
				       aCols[_nI][_nPosQtd]   := _nQtdParc  
	                   
					   If aCols[_nI][_nPosQ2U] > 0
					      _nQtd2UnPa           := aCols[_nI][_nPosQ2U] * _nQtdParc
					      aCols[_nI][_nPosQ2U] := _nQtd2UnPa 
			           EndIf 
 					   
					   //============================================================
					   // Função padrão da Totvs para atualização dos valores totais.
					   //============================================================
					   A103Total(M->D1_TOTAL) // Função padrão Totvs
                       
					   //==============================================================
					   // A função da Totvs acima altera os valores calculados.
					   // Temos que gravar novamente nos campos os valores calculados.
					   //============================================================== 
                       aCols[_nI][_nPostotal] := _nPrcTot  
					   M->D1_TOTAL := _nPrcTot 
				
				       aCols[_nI][_nPosPrc] := SC7->C7_PRECO   
					   M->D1_VUNIT := SC7->C7_PRECO
					   M->D1_QUANT := _nQtdParc
                
				       aCols[_nI][_nPosQtd]   := _nQtdParc  
	                   
					   If aCols[_nI][_nPosQ2U] > 0
					      _nQtd2UnPa           := aCols[_nI][_nPosQ2U] * _nQtdParc
					      aCols[_nI][_nPosQ2U] := _nQtd2UnPa 
			           EndIf 
					EndIf 
                 EndIf 
	          EndIf 
		   EndIf 
       Next 
	EndIf 

	//====================================================================================================
	// Valida se a nota de origem não foi emitida depois da devolução, pois isso seria impossível [31123]
	//====================================================================================================
	If _lRet .And. cTipo == "D"
		BeginSql Alias _cAlias
			SELECT COUNT(1) QTD
			FROM %Table:SD2% SD2, %Table:SD1% SD1
			WHERE SD2.D_E_L_E_T_ = ' '
			AND SD1.D_E_L_E_T_ = ' '
			AND D2_FILIAL = D1_FILIAL
			AND D2_DOC = D1_NFORI
			AND D2_SERIE = D1_SERIORI
			AND D2_ITEM = D1_ITEMORI
			AND D2_CLIENTE = D1_FORNECE
			AND D2_LOJA = D1_LOJA
			AND D1_FILIAL = %xFilial:SD1%
			AND D1_DOC = %exp:cNFiscal%
			AND D1_SERIE = %exp:cSerie%
			AND D1_FORNECE = %exp:cA100For%
			AND D1_LOJA = %exp:cLoja%
			AND D1_EMISSAO < D2_EMISSAO
		EndSql
		If (_cAlias)->QTD > 0
			_cAux:="O Documento de origem vinculado é inválido pois sua emissão é posterior à devolução."
			If l103Auto
				AutoGRLog("MT100TOK007"+CRLF+_cAux)
			Else
				FWAlertError(_cAux,"MT100TOK007")
			EndIf
			_lRet := .F.
		EndIf
		(_cAlias)->( DBCloseArea() )
	EndIf

	//====================================================================================================
	// Valida se a chave da nota já consta em outro documento, mesmo que de outra filial
	//====================================================================================================
	If _lRet .And. cFormul <> 'S'
		If !Empty( aNfeDanfe[13] )
			BeginSql Alias _cAlias
		      SELECT SF1.F1_FILIAL, SF1.F1_DOC, SF1.F1_SERIE, SF1.F1_FORNECE, SF1.F1_LOJA, SF1.F1_ESPECIE
		        FROM %Table:SF1% SF1
		       WHERE SF1.D_E_L_E_T_ = ' '
		         AND SF1.F1_CHVNFE = %exp:aNfeDanfe[13]%
		         AND SF1.F1_STATUS <> ' '
		 	EndSql
			
			If (_cAlias)->( !Eof() )
				_cAux:="A chave: "+ aNfeDanfe[13] +" já existe em outro documento: "+ CRLF
				_cAux+=" Filial: "+ (_cAlias)->F1_FILIAL +"/ Documento: "+ (_cAlias)->F1_DOC +"/ Série: "+ (_cAlias)->F1_SERIE
				If l103Auto
					AutoGRLog("MT100TOK008"+CRLF+_cAux)
				Else
					FWAlertError(_cAux,"MT100TOK008")
				EndIf
				_lRet := .F.
			EndIf
			(_cAlias)->( DBCloseArea() )
		EndIf
	EndIf

	If _lRet .And. cTipo == "N" .And. cFormul <> 'S'
		//====================================================================================================
		//Valido se o período do Leite de terceiros existe e está aberto
		//====================================================================================================
		_cDtRef:= DToS(IIf(l103Auto,aAutoCab[aScan( aAutoCab , {|X| Upper( AllTrim( X[1] ) ) == "F1_DTDIGIT"} )][2],dDataBase))//DToS( dDataBase )
		_lRet:= U_ValLT3(aCols,_cDtRef,_nPosCod,_nPosNOri,_nPosSOri)
	EndIf
	If cTipo == "D" .And. _lRet .And. _lGeraNDC
		_cAlias := GetNextAlias()
		BeginSql alias _cAlias      
			SELECT 1 ACHOU FROM %Table:SA1%
			WHERE D_E_L_E_T_ = ' '
			AND A1_COD = %exp:cA100FOR%
			AND A1_LOJA = %exp:cLOJA%
			AND (EXISTS (SELECT 1 FROM %Table:SA3% WHERE D_E_L_E_T_ = ' ' AND A3_COD = A1_VEND AND A3_MSBLQL = '1')
			OR EXISTS (SELECT 1 FROM %Table:SA3% WHERE D_E_L_E_T_ = ' ' AND A3_COD = A1_I_VEND2 AND A3_MSBLQL = '1')
			OR EXISTS (SELECT 1 FROM %Table:SA3% WHERE D_E_L_E_T_ = ' ' AND A3_COD = A1_I_VEND3 AND A3_MSBLQL = '1')
			OR EXISTS (SELECT 1 FROM %Table:SA3% WHERE D_E_L_E_T_ = ' ' AND A3_COD = A1_I_VEND4 AND A3_MSBLQL = '1')
			)
		EndSql

		If (_cAlias)->ACHOU == 1
			_cAux := "Cliente com o vendedor vinculado ao cadastro, bloqueado. Documento não gerado."
			_lRet := .F.
			If l103Auto
				AutoGRLog("MT100TOK025"+CRLF+_cAux)
			Else
				FWAlertError(_cAux,"MT100TOK025")
			EndIf
		EndIf
		(_cAlias)->(DBCloseArea())
	EndIf
	//====================================================================================================
	// Fim das validações de responsabilidade do analista Lucas - Não alterar
	//====================================================================================================

	//====================================================================================================
	// Feito comparacao verificando se rotina é proveniente de retorno
	//====================================================================================================
	If _lRet
		ZZL->( DBSetOrder(3) )
		If ZZL->( DBSeek( xFilial("ZZL") + RetCodUsr() ) )
			If ZZL->(FIELDPOS("ZZL_PEFRPA")) = 0 .Or. ZZL->ZZL_PEFRPA == "S"
				_lValidFrac1UM:=.F.
			EndIf
		EndIf
		ZZL->( DBSetOrder(1) )
		SB1->( DBSetOrder(1) )
    
		For _nI := 1 To Len(aCols)
		    If aCols[_nI][_nPosDel]//Se deletado
		       Loop
		    EndIf
	
			//============================================================================================================
			//Verifica se TES do documento vinculado é compatível quanto a movimentação de estoque com o CTE sendo incluso
			//=============================================================================================================
			If Upper(AllTrim(cEspecie)) $ 'CTE' .And. !Empty(aCols[_nI][_nPosTes]) .And. !Empty(aCols[_nI][_nPosIT])
	
				//guarda posição do SD1 e do SF1
				_nposor1 := SD1->(Recno())
				_asd1    := SD1->(GetArea())
				_nposor2 := SF1->(Recno())
				_asf1    := SF1->(GetArea())
					
				//Procura referência na SDT para achar chave da nota fiscal de origem
				SDT->(DBSetOrder(8)) //DT_FILIAL+DT_FORNEC+DT_LOJA+DT_DOC+DT_SERIE+DT_ITEM
				If SDT->(DBSeek(xFilial("SDT")+cA100For+cLoja+cnfiscal+cserie+aCols[_nI][_nPosItn]))
				
					SF1->(DBSetOrder(8)) //F1_FILIAL+F1_CHVNFE
					If SF1->(DBSeek(xFilial("SF1")+SDT->DT_CHVNFO))
						//Procura tes de origem na SD1
						SD1->(DBSetOrder(1))
						If SD1->(DBSeek(SF1->F1_FILIAL+SF1->F1_DOC+SF1->F1_SERIE+SF1->F1_FORNECE+SF1->F1_LOJA+SDT->DT_COD+ aCols[_nI][_nPosIT] ))
							While SD1->(!Eof()) .And. SF1->F1_FILIAL == SD1->D1_FILIAL .And. SF1->F1_DOC == SD1->D1_DOC .AND.;
							 		  SF1->F1_DOC == SD1->D1_DOC .And. SF1->F1_FORNECE == SD1->D1_FORNECE .AND.;
							 		  SF1->F1_LOJA == SD1->D1_LOJA .And. SDT->DT_COD == SD1->D1_COD .And. aCols[_nI][_nPosIT] == SD1->D1_ITEM
						
								_cmvestnf := Posicione("SF4",1,xFilial("SF4")+aCols[_nI][_nPosTes],"F4_ESTOQUE")
								_cmvestct := Posicione("SF4",1,xFilial("SF4")+SD1->D1_TES,"F4_ESTOQUE")
		 	 		
								If !(AllTrim(_cmvestct) == AllTrim(_cmvestnf)) .And. _cmvestct == "N"
						 			aAdd(_alogTES,{SD1->D1_FILIAL,SD1->D1_DOC+" / "+SD1->D1_SERIE+" / "+SD1->D1_ITEM,aCols[_nI][_nPosItn],SD1->D1_FORNECE+"/"+SD1->D1_LOJA,;
						 	 					SD1->D1_TES + " - Estoque  " + _cmvestnf, aCols[_nI][_nPosTes] + " - Estoque " + _cmvestct })
						 	 	EndIf
						 	 	SD1->(DBSkip())
						 	 EndDo
						EndIf	
					EndIf
				EndIf
				
				//Reposiciona SD1 e SF1
				SD1->(FWRestArea(_asd1))
				SF1->(FWRestArea(_asf1))
				SD1->(DBGoTo(_nposor1))
				SF1->(DBGoTo(_nposor2))	
			EndIf 			
			
			//====================================================================================================
			// Verifica se a TES é Quantidade Zerada. Se sim, não valida fator de conversão. Chamado 7374
			//====================================================================================================
			_lQtZero := ( "1" == Posicione( "SF4" , 1 , xFilial("SF4") + aCols[_nI][_nPosTes] , "F4_QTDZERO" ))
			_cCod := aCols[_nI][_nPosCod]
			
			SB1->( DBSeek( xFilial("SB1") + _cCod ) )

			If _cRet_TN = "ACHOU_PF"//AWF - 29/11/2016 - Projeto Unificação
			   SC6->( DBSetOrder(2) )//C6_FILIAL+C6_PRODUTO+C6_NUM+C6_ITEM
			   _cQtdeOri:=""
			   _cPrUnOri:=""
			   _cMensagem:=""
			   _lOK:=.F.
               If SC6->( DBSeek( _cFilCarregamento + aCols[_nI][_nPosCod] + _cPedCarregamento ) )
                  _cQtdeOri:=TRANS(SC6->C6_QTDVEN ,AVSX3('C6_QTDVEN',6))
                  _cPrUnOri:=TRANS(SC6->C6_PRCVEN ,AVSX3('C6_PRCVEN',6))

                  If SC6->C6_QTDVEN = aCols[_nI][_nPosQtd] .And. ((SC6->C6_PRCVEN - aCols[_nI][_nPosPrc]) < 0.01 .And. (SC6->C6_PRCVEN - aCols[_nI][_nPosPrc]) > -0.01)
			         _lOK:=.T.
			      Else
			         If SC6->C6_QTDVEN # aCols[_nI][_nPosQtd]
			           _cMensagem:="Quantidade diferente  "
			         EndIf
			         If (SC6->C6_PRCVEN - aCols[_nI][_nPosPrc]) > 0.01 .Or. (SC6->C6_PRCVEN - aCols[_nI][_nPosPrc]) < -0.01
			           _cMensagem+="Preço diferente"
			         EndIf
			         _lDiferente:=.T.
			      EndIf
		       Else
			      _cMensagem+="Item não encontrado no Pedido de Carregamento"
			      _lDiferente:=.T.
               EndIf

               aAdd(_aLogItens,{ _lOK , StrZero(_nI,4), aCols[_nI][_nPosCod] , _cQtdeOri , _cPrUnOri ,;
                                 TRANS(aCols[_nI][_nPosQtd],AVSX3('D1_QUANT',6)),;
                                 TRANS(aCols[_nI][_nPosPrc],AVSX3('D1_VUNIT',6)),_cMensagem } )
			EndIf

			If _lTosAlte
				_nTolera:= Posicione("SBZ",1,xFilial("SBZ")+AllTrim(aCols[_nI][_nPosCod]),"BZ_I_TOLER")
				If _nTolera # 0
					_aSldSB6:= CalcTerc(aCols[_nI][_nPosCod],cA100For,cLoja,aCols[_nI][_nPosItB6],aCols[_nI][_nPosTes],cTipo)
					_nDif   := _aSldSB6[1] - aCols[_nI][_nPosQtd]  // 2 - 1,5 = 0,5
					
					If _aSldSB6[1] # 0 .And. _nDif # 0 .And. _nDif < _nTolera // 0,5 < 1
						aAdd(_aLogSaldos,{ .F. ,;
						aCols[_nI][_nPosCod],;
						TRANS(aCols[_nI][_nPosQtd],;
						AVSX3('C6_QTDVEN',6)) ,;
						TRANS(_aSldSB6[1],;
						AVSX3('C6_QTDVEN',6)) ,;
						TRANS(_nDif               ,AVSX3('C6_QTDVEN',6)) ,;
						"Favor verifcar com o depto. Fiscal e fornecedor as quantidades a retornar." } )
					EndIf
				EndIf
			EndIf

			//====================================================================================================
			// Inicio Modificacao Inlcuido tratativa para verificar o fator de conversao das unidades de medida  - Chamado 7182
			//====================================================================================================
			If _lRet .And. CTIPO $ "N/D" .And. !_lQtZero //Tipo Normal ou Devolução e Quantidade não pode ser igual a zero
				_cVldCon	:= SB1->B1_I_SFCON
				_nFatCon	:= SB1->B1_CONV
				If !Empty( aCols[_nI][_nPosD2U] ) .And. _nFatCon == 0//B1_CONV
					_nQtdProd 	:= Acols[_nI][_nPosQtd]
					_nQtd2UM 	:= Acols[_nI][_nPosQ2U]
					_nFtMin		:= SB1->B1_I_FTMIN
					_nFtMax		:= SB1->B1_I_FTMAX
					If _cVldCon == "1"//B1_I_SFCON // QUEIJOS
						_lDifPes := .F.
						If aCols[_nI][_nPosDPE] == "S" .And. ;
						  FWAlertYesNo("A nota atual é referente à diferença de pesagem entre a Italac e o Cliente?","MT100TOK009")
							_lDifPes := .T.
						Else
							aCols[_nI][_nPosDPE] := "N"	 
						EndIf

						If _lDifPes .And. aCols[_nI][_nPosDPE] == "S"
							aCols[_nI][_nPosUsr] := cUserName
						Else
							_nVlrPeca := _nQtdProd / _nQtd2UM
							If _nVlrPeca < _nFtMin .Or. _nVlrPeca > _nFtMax //Fora dos limites: menor que o Minimo ou maior que o Maximo
								_cItens += Acols[_nI][1] +" "+ AllTrim( Acols[_nI][3] ) +" - "+ cValToChar( _nQtdProd ) +" / "+ cValToChar( _nQtd2UM ) +" = "+ cValToChar( _nVlrPeca ) + CRLF
							EndIf
						
						EndIf
					
					ElseIf aCols[_nI][_nPosQ2U] == 0 .And. !(_lDifPes)
						_cAux:="Para o produto "+ aCols[_nI][_nPosCod] +" é obrigatorio o preenchimento da segunda unidade de medida. Favor preencher a segunda unidade de medida!"
						If l103Auto
							AutoGRLog("MT100TOK010"+CRLF+_cAux)
						Else
							FWAlertError(_cAux,"MT100TOK010")
						EndIf
						_lRet := .F.
					EndIf
				
				ElseIf aCols[_nI][_nPosQ2U] == 0 .And. _nFatCon <> 0//B1_CONV
					_cItens2 += Acols[_nI][1] +" / "+ AllTrim( Acols[_nI][3] ) +" - "+ cValToChar( _nFatCon ) +" / "+SB1->B1_SEGUM + CRLF
				EndIf
				
			EndIf
			
			//====================================================================================================
			//  Validação da diferença entre o custo médio e o custo de entrada somente se movimenta estoque
			//  se For nota do tipo que conste no parâmetro IT_VALCMT e se tipo do produto não constar do 
			//  parâmetro IT_VALCMP
			//====================================================================================================
			If 	Posicione("SF4",1,xFilial("SF4")+AllTrim(acols[_nI][_nPosTes]),"F4_ESTOQUE") = "S" .and.;
				!(Posicione("SB1",1,xFilial("SB1")+AllTrim(aCols[_nI][_nPosCod]),"B1_TIPO") $ _cValCMP) .and.;
				AllTrim(CTIPO) $ _cValCMT .and.;
				!aCols[_nI][_nPosDel]

				Private aDupl := {}

				_nQtdProd 	:= Acols[_nI][_nPosQtd]
				_aCustoEnt := A103Custo(_nI)  // rotina padrão de cálculo de custo para D1_CUSTO
				_nVlrCus	:= _aCustoEnt[1]
				_nCMorig 	:= _nVlrCus / _nQtdProd
				_nCMdest  	:= Posicione( "SB2" , 1 , xFilial("SB2") + aCols[_nI][_nPosCod] + aCols[_nI][_nPosArm] , "B2_CM1" )
			
				If _nCMdest > 0
					_nDifPrd := (_nCMdest - _nCMorig) / _nCMorig
					If _nDifPrd < 0
			   			_nDifPrd := (_nDifPrd * (-1))
		   			EndIf
			
					_nDifPrd := _nDifPrd * 100
			
					If _nDifPrd > _nDifCM2 .And. _nDifPrd <= _nDifCM
						aAdd( _aErro1 , { _nI , AllTrim( aCols[_nI][02] ) , _nDifPrd } )
						_lErro1 := .T.
					ElseIf _nDifPrd > _nDifCM
						aAdd( _aErro2 , { _nI , AllTrim( aCols[_nI][02] ) , _nDifPrd } )
						_lErro2 := .T.
					EndIf	 
				EndIf		
			EndIf
			
			//================================================================================
	        // Verifica se há contradição entre a TES que diz para não movimentar estoques
	        // e a configuração do produto que diz para movimentar estoque.
			// Somente valida para documento tipo Normal
	        //================================================================================    
			If CTIPO == "N" .And. AllTrim(Posicione("SF4",1,xFilial("SF4")+AllTrim(acols[_nI][_nPosTes]),"F4_ESTOQUE")) == "N" .And. ;
				AllTrim(Posicione("SB5",1,xFilial("SB5")+AllTrim(aCols[_nI][_nPosCod]),"B5_I_ESTOB")) == "S"
				_cAux:="O Produto " + AllTrim(aCols[_nI][_nPosCod]) + " exige movimento de estoque e a TES " + AllTrim(acols[_nI][_nPosTes]) + " não movimenta estoque!"
				If l103Auto
					AutoGRLog("MT100TOK011"+CRLF+_cAux)
				Else
					FWAlertError(_cAux,"MT100TOK011")
				EndIf
			   _lRet := .F.
			EndIf
			
		  //====================================================================================================
			// Verifica o armazem e se altera para 31 de acordo com a opção do usuario                          
		 	//====================================================================================================
			If _lRet .And. CTIPO == "D" // Somente NFs de devolucao
				If SB1->B1_TIPO == "PA" .And. !aCols[_nI][_nPosArm] $ _cAmzLog//Armazens permitidos para Devolucao
			 		If _lErro						
						_cAux:="Não é possível confirmar o Documento com Armazém ["+ aCols[_nI][_nPosArm] +"] inválido para o produto ["+ _cCod +"]. "
						_cAux+="Para NFs de Devolução de Produto Acabado, informe um dos Armazéns Permitidos: "+ _cAmzLog
						If l103Auto
							AutoGRLog("MT100TOK012"+CRLF+_cAux)
						Else
							FWAlertError(_cAux,"MT100TOK012")
						EndIf
			    		_lRet := .F.
					    _lErro:= .F.
					EndIf
				EndIf
			EndIf
			
			If _lRet .And. !_lConFrt .And. CTIPO $ ("ND") //Controle para não validar no Conhecimento de Frete
				If !_lQtZero .And. !_lDifPes .And. SubStr(_cCod,1,4) = "0006"
					_nQT2UM := aCols[_nI][_nPosQ2U]
					If _nQT2UM == 0
						_cAux:="Para o produto "+ aCols[_nI][_nPosCod] +" é obrigatorio informar a segunda unidade de medida. Favor preencher a segunda unidade de medida!"
						If l103Auto
							AutoGRLog("MT100TOK013"+CRLF+_cAux)
						Else
							FWAlertError(_cAux,"MT100TOK013")
						EndIf
						_lRet := .F.
					EndIf
					
				EndIf
				//AWF - 01/11/2016 - Projeto Unificação
				If  _cRet_TN # "ACHOU_PF" .And. SB1->B1_TIPO <> "PA" .And. SB1->B1_LOCPAD <> aCols[_nI][_nPosArm] .And. _lRet
					_lRet := FWAlertYesNo("O Armazém selecionado ["+ aCols[_nI][_nPosArm] +"] não é o Armazém Padrão cadastrado para o Produto ["+ _cCod +"]. Deseja confirmar o produto com esse Armazém?","MT100TOK014")
					If !_lRet .And. l103Auto
						AutoGRLog("MT100TOK014"+CRLF+"O Armazém selecionado ["+ aCols[_nI][_nPosArm] +"] não é o Armazém Padrão cadastrado para o Produto ["+ _cCod +"].")
					EndIf
				EndIf
			EndIf
			
			//Correção de bases para  PORTARIA CAT 42/2018 - Chamado 28559
			_nPosTes := aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "D1_TES"     } ) // Código da TES
			_nPosPROD:= aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "D1_COD"     } ) // Código do produto
			_cgrupo := Posicione("SB1",1,xFilial("SB1")+acols[_nI][_nPosPROD],"B1_GRUPO")
			
			If acols[_nI][_nPosTes] $ SuperGetMV("IT_CAT42TE",.F.,"491")
				_nbasest := Posicione("SBM",1,xFilial("SBM")+_cgrupo,"BM_I_BASEN")
				_naliqn  := SuperGetMV("IT_CAT42AL",.F.,18)
				If _nbasest > 0
					acols[_nI][_nPosbasen] := acols[_nI][_npostotal] * _nbasest
					acols[_nI][_nPosbasen] := (acols[_nI][_nPosbasen] * (_naliqn/100)) - acols[_nI][_nposvalicm]
					acols[_nI][_nPosaliqn] := _naliqn
				EndIf
			EndIf

			If _lValidFrac1UM
				SB1->(DBSeek(xFilial("SB1") + AllTrim(aCols[_nI][_nPosPROD])))
				If SB1->B1_TIPO == "PA" .And. SB1->B1_UM == "UN"
					If aCols[_nI,_nPosQtd] <> Int(aCols[_nI,_nPosQtd])
						_lRet2 := .F.
						_cProds+="Item: " + aCols[_nI,_nPosItn]+" Prod.: " + AllTrim(aCols[_nI][_nPosPROD])+" - UM: "+SB1->B1_UM+ " - " + LEFT(SB1->B1_DESC,25) + CHR(13)+CHR(10)
					EndIf
				EndIf
			EndIf

			_cCGC      := AllTrim(Posicione("SA2",1,xFilial("SA2")+cA100For+cLoja,"A2_CGC"))

			If _lRet .And. !AllTrim(SM0->M0_CGC) == _cCGC .And. ;
			                         cFilAnt $ _cFilTrFil .And. ;
				                    cA100For $ _cCliTrFil .And. ;
				              !Empty(AllTrim(_cProTrFil)) .And. !(AllTrim(aCols[_nI][_nPosProd]) $ _cProTrFil)

				If Posicione("SF4",1,xFilial("SF4")+aCols[_nI][_nPosTes],"F4_TRANFIL") == "1"
					_cMovEstSD1 := Posicione("SF4",1,xFilial("SF4")+aCols[_nI][_nPosTes],"F4_ESTOQUE")
					_aSM0 := FwLoadSM0(.T.)
					_cCodFil := ""
					For _nXY := 1 To Len( _aSM0 )
						If     _aSM0[_nXY][SM0_CGC] ==  AllTrim(_cCGC) .And. _aSM0[_nXY][SM0_CODFIL] <>"22"
								_cCodFil := _aSM0[_nXY, SM0_CODFIL]
							Exit
						EndIf
					Next

					If !Empty(AllTrim(_cCodFil))
						_cCodCli := SA1->A1_COD
						_cLojaCli :=  SA1->A1_LOJA
						_cEmissao := DToS(dDEmissao)
						_cCodigo  := aCols[_nI][_nPosCod]
						_cItem    := StrZero(Val(aCols[_nI][_nPosItn]),TamSX3("D2_ITEM")[1])
						_cAliasSD2	:= GetNextAlias()

						BeginSql Alias _cAliasSD2
							SELECT D2_FILIAL, D2_DOC, D2_SERIE, D2_ITEM, D2_TES, F4_ESTOQUE, D2_CLIENTE, D2_LOJA, A1_CGC
							FROM %Table:SD2% SD2
								JOIN %Table:SF4% SF4 ON SD2.D2_FILIAL = SF4.F4_FILIAL AND SD2.D2_TES = SF4.F4_CODIGO AND SF4.D_E_L_E_T_ = ' '
								JOIN %Table:SA1% SA1 ON D2_CLIENTE = A1_COD AND D2_LOJA = A1_LOJA AND SA1.D_E_L_E_T_ = ' '
							WHERE SD2.D_E_L_E_T_ = ' '
								AND D2_FILIAL = %exp:_cCodFil%
								AND D2_DOC = %exp:cNFiscal%
								AND D2_SERIE = %exp:cSerie%
								AND D2_EMISSAO = %exp:_cEmissao%
								AND D2_ITEM = %exp:_cItem%
								AND D2_COD = %exp:_cCodigo%
						EndSql

						If (_cAliasSD2)->( !Eof() )
							_cCodFil := ""
							For _nXY := 1 To Len( _aSM0 )
								If     _aSM0[_nXY][SM0_CGC] ==  AllTrim((_cAliasSD2)->A1_CGC) .And. _aSM0[_nXY][SM0_CODFIL] <>"22"
										_cCodFil := _aSM0[_nXY, SM0_CODFIL]
									Exit
								EndIf
							Next
	
							If _nX > 0
								_cCodFil := _aSM0[_nX, SM0_CODFIL]
							EndIf

							If _cCodFil <> cFilAnt
								_cAux:="Para o item " + AllTrim(aCols[_nI][_nPosItn]) + " Produto " + AllTrim(aCols[_nI][_nPosCod]) + ", há divergência entre a Filial da Nota de Origem e a Filial do Documento."
								_cAux+="Documento não será gravado, verifique a TES preenchida."
								If l103Auto
									AutoGRLog("MT100TOK015"+CRLF+_cAux)
								Else
									FWAlertError(_cAux,"MT100TOK015")
								EndIf
								_lRet := .F. 
							EndIf

							If _lRet .And. (_cAliasSD2)->F4_ESTOQUE <> _cMovEstSD1
								_lRet := .F. 
								_aLogSD2 := {}
								aAdd(_alogSD2,{(_cAliasSD2)->D2_FILIAL,(_cAliasSD2)->D2_DOC+" / "+(_cAliasSD2)->D2_SERIE+" / "+(_cAliasSD2)->D2_ITEM,aCols[_nI][_nPosItn],(_cAliasSD2)->D2_CLIENTE+"/"+(_cAliasSD2)->D2_LOJA,;
											(_cAliasSD2)->D2_TES + " - Estoque  " + (_cAliasSD2)->F4_ESTOQUE, aCols[_nI][_nPosTes] + " - Estoque " + _cMovEstSD1 })

								_ahead := {"Filial","Nota origem","Item","Cliente","TES NF Origem","TES NF"}

								U_ITMsg("Divergência entre as TES da NF de origem e a TES da entrada quanto ao campo que atualiza as movimentações de estoque para o item " + AllTrim(aCols[_nI][_nPosItn]) + " Produto " + AllTrim(aCols[_nI][_nPosCod]) + ".  Clique no botão 'Mais detalhes' para mais informações. ",;//,_ntipo,_nbotao,_nmenbot,_lHelpMvc,_cbt1,_cbt2,_bMaisDetalhes
										"Atenção","Documento não será gravado até as TES estejam iguais referente a informação de estoque."+Chr(13)+Chr(10)+Chr(13)+Chr(10)+"Procure o responsável no departamento fiscal pelos cadastros das TES."         ,1     ,       ,        ,         ,     ,     ,;
										{|| U_ITListBox( 'Existem divergências de TES' , _ahead , _alogSD2 , .T. , 1 )} )

							EndIf 
						Else
							_cAux:="Para o item " + AllTrim(aCols[_nI][_nPosItn]) + " Produto " + AllTrim(aCols[_nI][_nPosCod]) + " não foi encontrado na filial de origem ou a ordem do Item está divergente da informada no Documento de Saí­da! "
							If l103Auto
								AutoGRLog("MT100TOK016"+CRLF+_cAux)
							Else
								FWAlertError(_cAux,"MT100TOK016")
							EndIf
							_lRet := .F.
						EndIf

						(_cAliasSD2)->(DBCloseArea())
					Else
						_cAux:="Não encontrado Filial com este CPNJ "+_cCGC+", consequentemente não há Documento de Saí­da para tranferencia referente ao Fornecedor preenchido! "
						If l103Auto
							AutoGRLog("MT100TOK017"+CRLF+_cAux)
						Else
							FWAlertError(_cAux,"MT100TOK017")
						EndIf
						_lRet := .F.
					EndIf
			
				Else
					_cAux:="Para NFs de transferencia entre filiais é necessário que o campo 'Transf. Filial' na TES "+aCols[_nI][_nPosTes]+" esteja como 'Sim'. Entre em contato com o coordenador fiscal da sua unidade."
					If l103Auto
						AutoGRLog("MT100TOK018"+CRLF+_cAux)
					Else
						FWAlertError(_cAux,"MT100TOK018")
					EndIf
					_lRet := .F.
				EndIf
			EndIf	

			If !_lRet
				Exit
			EndIf
			
		Next _nI

		If _lValidFrac1UM .And. !_lRet2
			U_ITMsg("Não é permitido fracionar a quantidade da 1a. UM de produto onde a UM For UN. Clique em mais detalhes",;//,_ntipo,_nbotao,_nmenbot,_lHelpMvc,_cbt1,_cbt2,_bMaisDetalhes
			        "Validação Fracionado","Favor informar apenas quantidades inteiras na Primeira Unidade de Medida."         ,1     ,       ,        ,         ,     ,     ,;
			        {|| Aviso("Validação Fracionado",_cProds,{"Fechar"}) } )
			_lRet:=.F.
		EndIf		
		
		If Len(_alogTES) > 0
			U_ITMsg("Divergência entre a TES do conhecimento e a utilizada na Nota Fiscal de Origem quanto a movimentação de estoque.",;
					"Atenção","Documento não será gravado, verifique a TES na próxima tela.",1)
			_ahead := {"Filial","Nota origem","Item","Fornecedor","TES NF","TES CTE"}
			U_ITListBox( 'Existem divergências de TES' , _ahead , _alogTES , .T. , 1 )
			_lRet := .F.
		EndIf

		If !Empty(_cItens2) .And. _lRet
			_cItens2 := "Produto - Conversao da 2 UM"+CRLF+_cItens2 
      		bBloco:={||  AVISO("ATENCA",_cItens2,{"Fechar"},3) }
			U_ITMsg(	"Existe produto(s) que é obrigatorio o preenchimento da segunda unidade de medida." ,;
								"Atenção","Favor preencher a segunda unidade de medida, VER MAIS DETALHES",1,,,,,,bBloco )
			_lRet := .F.				
		EndIf
		
		If _lErro2
			For _nI := 1 to Len(_aErro2)
				_cItens1 += CVALTOCHAR(_aErro2[_nI][1])+" - "
				_cItens1 += CVALTOCHAR(_aErro2[_nI][2])+": "
				_cItens1 += TRANSFORM(_aErro2[_nI][3], "@E 999.9999")+"% "+CHR(13)+CHR(10)		                  
			Next _nI
			_cAux:="Diferença entre valor de Custo Medio da entrada e estoque no(s) item(ns):"+CHR(13)+CHR(10)+_cItens1 + "Favor analisar o Kardex! Se necessário, entre em contato com o Depto. de TI."
			If l103Auto
				AutoGRLog("MT100TOK019"+CRLF+_cAux)
			Else
				FWAlertError(_cAux,"MT100TOK019")
			EndIf
			_lRet := .F.	
		ElseIf _lErro1
	
			For _nI := 1 to Len(_aErro1)
				_cItens1 += CVALTOCHAR(_aErro1[_nI][1] ) +" - "
				_cItens1 += CVALTOCHAR(_aErro1[_nI][2] ) +": "
				_cItens1 += TRANSFORM(_aErro1[_nI][3] , "@E 999.9999" ) +"% "+ CHR(13) + CHR(10)
			Next _nI
		
			_cAux:="Diferença entre valor de Custo Medio da entrada e estoque no(s) item(ns):"+CRLF+_cItens1
			If !FWAlertYesNo(_cAux+" Deseja prosseguir?","MT100TOK020")
				If l103Auto
					AutoGRLog("MT100TOK020"+CRLF+_cAux)
				EndIf
				_lRet := .F.		
			EndIf
		EndIf
		
		If _lAtuArm
			_cAux:="Armazem alterado para 31 em todos os Produtos classificados como 'Produto Acabado' deste documento."
			If l103Auto
				AutoGRLog("MT100TOK021"+CRLF+_cAux)
			Else
				FWAlertError(_cAux,"MT100TOK021")
			EndIf
			_lRet := .F.
		EndIf
		
		//====================================================================================================
		// Monta tela para exibir mensagem de erro com base nos produtos que deram problema, dentro de aItens
		//====================================================================================================
		If _lRet .And. !_lDifPes .And. !Empty( _cItens )
			_cAux:="As quantidades informadas ( Quantidade x Qtd. 2ª UM ) não correspondem aos limites do Fator de Conversão!"
			_cAux+= " Verifique as quantidades informadas para o(s) produto(s):"+ CRLF + _cItens
			If l103Auto
				AutoGRLog("MT100TOK022"+CRLF+_cAux)
			Else
				FWAlertError(_cAux,"MT100TOK022")
			EndIf
			_lRet := .F.
		EndIf
		
	EndIf
    
	If cFilAnt $ _cFilTpc
		//============================================================================================================================
		// Se o formulário não For próprio e o tipo For igual a Normal, o sistema irá fazer todas as validações do vínculo do PC x NF
		//============================================================================================================================
		If cFormul == "N" .And. cTipo == "N"
			If _lRet
				_nPosPed	:= aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == 'D1_PEDIDO'	} ) // No do Pedido
				_nPosIte	:= aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "D1_ITEMPC"	} ) // Item do Pedido
				_nPosCod	:= aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "D1_COD"		} ) // Código do Produto
				_nPosItn	:= aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "D1_ITEM"		} ) // Item do Documento
				_nPosTes	:= aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "D1_TES"		} ) // TES do Documento
				_nPosVlr := aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "D1_TOTAL"	} ) // Valor Total
				_nPosDsc := aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "D1_VALDESC"	} ) // Valor do Desconto
				_nPosIcm := aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "D1_ICMSRET"	} ) // ICMS Retido
				_nVlTotal := 0

				//===================================================================================
				// Valida se o valor total da nota é menor ou igual ao valor do parâmetro IT_VLRNOBR
				//===================================================================================
				For _nI := 1 To Len(aCols)
					_nVlTotal += aCols[_nI][_nPosVlr] - aCols[_nI][_nPosDsc] - aCols[_nI][_nPosIcm]
				Next _nI
				
				If (_nVlTotal > _nVlrnObr) .And. !(AllTrim(cA100For) $ _ForNaoVld)
					//========================================
					// São validadas todas as linhas do aCols
					//========================================
					For _nI := 1 To Len(aCols)
						//===============================================
						// Somente são validadas as linhas não deletadas
						//===============================================
						If !aCols[_nI][Len(aHeader)+1]
							//======================================================
							// Posiciono na TES para validar se esta gera duplicata
							//======================================================
							SF4->(DBSetOrder(1))
							If SF4->(DBSeek(xFilial("SF4") + aCols[_nI][_nPosTes]))
								If SF4->F4_DUPLIC == "S"
									//====================================================================
									// Se a TES gerar duplicata, a próxima validação é o grupo do produto
									//====================================================================
									SB1->(DBSetOrder(1))
									If SB1->(DBSeek(xFilial("SB1") + aCols[_nI][_nPosCod]))
										If !( SB1->B1_GRUPO $ _cGrpNob )
											If SB1->B1_I_PEDCO != "N"
												//============================================================================================================================================
												// Se o grupo não estiver no parâmtro o sistema irá gerar uma mensagem e irá obrigar o vínculo da NF x PC
												//============================================================================================================================================
												If Empty(aCols[_nI][_nPosPed]) 
													aAdd( _aLogTxt , { aCols[_nI][_nPosItn] , aCols[_nI][_nPosCod]	,"Documento de entrada sem pedido de compras." } )
													aAdd( _aLogTxt , { "" 					, "" 					,"Favor verificar o vínculo com o pedido de compras ou cadastro de produto para não usar pedido de compras" } )
												EndIf
											EndIf
										EndIf
									EndIf
								EndIf
							EndIf
						EndIf
					Next _nI
				EndIf
				//==================================================================================================
				// Se tiver mensagem a ser exibida, o sistema irá emitir a mensagem e obrigará o vínculo da NF x PC
				//==================================================================================================
				If Len(_aLogTxt) > 0
					U_ITListBox( 'Log de Validação (MT100TOK)' , aCampo , _aLogTxt , .F. , 1 )
					_lRet := .F.
				EndIf
			EndIf
			
			If _lRet
				_aLogVld := {}
				_aLogVld2 := {}
				_nPosPed := aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == 'D1_PEDIDO'	} ) // No do Pedido
				_nPosIte := aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "D1_ITEMPC"	} ) // Item do Pedido
				_nPosCod := aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "D1_COD"		} ) // Código do Produto
				_nPosItn := aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "D1_ITEM"		} ) // Item do Documento
				_nPosQtd := aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "D1_QUANT"	} ) // Quantidade na 1ª U.M.
				_nPosPrc := aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "D1_VUNIT"	} ) // Preço Unitário
				_nPosVlr := aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "D1_TOTAL"	} ) // Valor Total
				_nPosIPI := aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "D1_VALIPI"	} ) // Valor do IPI
				_nPosDsc := aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "D1_VALDESC"	} ) // Valor do Desconto
				_nPosIcm := aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "D1_ICMSRET"	} ) // ICMS Retido
				_nPosPIt := aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "D1_ITEMPC"	} ) // Item do Pedido
				_nPosTes := aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "D1_TES"	    } ) // Tes
				_nTotNfs := 0
				_nTotPed := 0
				_nTotVuP := 0
				_nTotVuN := 0
				_aItensNFAtual:={}

				_aColsAux := aClone(aCols)
				_apederro := {}
				_aItensPrev:={}

				For _nI := 1 To Len(aCols)
					If !aCols[_nI][Len(aHeader) + 1]
						If !Empty(aCols[_nI][_nPosPed])
							_cQryP := "SELECT C7_NUM, C7_EMISSAO, C7_ITEM, C7_PRODUTO, C7_QUANT, C7_QUJE, C7_PRECO, C7_TOTAL, C7_VLDESC, C7_COND, C7_I_USOD, C7_MOEDA, C7_TXMOEDA, C7_PICM "
							_cQryP += "FROM " + RetSqlName("SC7") + " "
							_cQryP += "WHERE C7_FILIAL = '" + xFilial("SC7") + "' "
							_cQryP += "  AND C7_NUM = '" + aCols[_nI][_nPosPed] + "' "
							_cQryP += "  AND C7_ITEM = '" + aCols[_nI][_nPosPIt] + "' "
							_cQryP += "  AND C7_FORNECE = '" + cA100For + "' "
							_cQryP += "  AND C7_PRODUTO = '" + aCols[_nI][_nPosCod] + "' "
							_cQryP += "  AND D_E_L_E_T_ = ' ' "
							_cQryP := ChangeQuery(_cQryP)
							MPSysOpenQuery(_cQryP,"TMPPED")
						
							TMPPED->(DBGoTop())
	
                            If TMPPED->C7_MOEDA <> 1
	                           _nTxMoeda := RecMoeda(dDEmissao,TMPPED->C7_MOEDA)
	                        EndIf   

							If !TMPPED->(Eof())
                                _nPrecoRS:=TMPPED->C7_PRECO
                                If TMPPED->C7_MOEDA <> 1
                                   _nPrecoRS:=TMPPED->C7_PRECO*_nTxMoeda
                                EndIf
								//============================================
								// Valida se é uso direto com TES sem estoque
								//============================================
								If  TMPPED->C7_I_USOD = 'S' .And. Posicione("SF4",1,xFilial("SF4")+aCols[_nI][_nPosTes],"F4_ESTOQUE") != "S"  
									_lDifTES := .T.
									aAdd( _aLogVld2 , {StrZero(_nCont++,4),"Pedido: " + TMPPED->C7_NUM,SToD(TMPPED->C7_EMISSAO),TMPPED->C7_ITEM,TMPPED->C7_PRODUTO,AllTrim(Transform(TMPPED->C7_QUANT,PesqPict("SC7","C7_QUANT"))),AllTrim(Transform(TMPPED->C7_QUJE,PesqPict("SC7","C7_QUJE"))),AllTrim(Transform(_nPrecoRS,PesqPict("SC7","C7_PRECO"))),AllTrim(Transform(TMPPED->C7_VLDESC,PesqPict("SC7","C7_VLDESC"))),AllTrim(Transform(TMPPED->C7_TOTAL,PesqPict("SC7","C7_TOTAL"))),aCols[_nI][_nPosTes],"Pedido de uso direto com TES que não movimenta estoque! "} )
								EndIf
                                
								//----------------------------------------------------------------------
								//Verifica se condição de pagamento da nota é a mesma do pedido
								//----------------------------------------------------------------------
								If !Empty(CCONDICAO) .And. AllTrim(TMPPED->C7_COND) <> AllTrim(CCONDICAO)
									If aScan(_apederro, TMPPED->C7_NUM) == 0
										_lDifPC := .T.
										aAdd(_apederro, TMPPED->C7_NUM)
										aAdd( _aLogVld , {StrZero(_nCont++,4),"Pedido: " + TMPPED->C7_NUM,SToD(TMPPED->C7_EMISSAO),TMPPED->C7_ITEM,TMPPED->C7_PRODUTO,AllTrim(Transform(TMPPED->C7_QUANT,PesqPict("SC7","C7_QUANT"))),AllTrim(Transform(TMPPED->C7_QUJE,PesqPict("SC7","C7_QUJE"))),AllTrim(Transform(_nPrecoRS,PesqPict("SC7","C7_PRECO"))),AllTrim(Transform(TMPPED->C7_VLDESC,PesqPict("SC7","C7_VLDESC"))),AllTrim(Transform(TMPPED->C7_TOTAL,PesqPict("SC7","C7_TOTAL"))),;
										                                      "Pedido com condição de pagamento ( " + AllTrim(TMPPED->C7_COND) + ") diferente da escolhida no documento de entrada: " + AllTrim(CCONDICAO)} )
										aAdd( _aLogVld , {StrZero(_nCont++,4),"",SToD(""),"","","","","","","",""} )
									EndIf
								EndIf					
								
								_nTotVuN += aCols[_nI][_nPosPrc]
								_nTotDsN += aCols[_nI][_nPosDsc]
								_nTotIcN += aCols[_nI][_nPosIcm]
								_nTotNF  := aCols[_nI][_nPosVlr] - aCols[_nI][_nPosDsc] - aCols[_nI][_nPosIcm] + aCols[_nI][_nPosIPI]
								_nTotNfs += _nTotNF   // 1 = Roda uma query no SC7 e soma o Total NF 
                                
							    If (_nPos:=aScan(_aItensNFAtual,{|P| P[1] == aCols[_nI][_nPosPed] + aCols[_nI][_nPosIte] })) <> 0
                                   _aItensNFAtual[_nPos,2] += aCols[_nI][_nPosQtd]
                                Else
								   aAdd(_aItensNFAtual, {aCols[_nI][_nPosPed] + aCols[_nI][_nPosIte] ,;//01
								                                                aCols[_nI][_nPosQtd] })//02					   
						        EndIf
					            aAdd(_aItensPrev,{          aCols[_nI][_nPosPed],; //01
					            	                        aCols[_nI][_nPosCod],; //02
					            	                        aCols[_nI][_nPosIte],; //03
										                                cNFiscal,; //04 - NF
										                    aCols[_nI][_nPosQtd],; //05 - QTDE DAS NFS anteriores
					                                                           0,; //06 - Saldo para usar ainda / Qtde não usada
										                    aCols[_nI][_nPosPrc],; //07
										                                 _nTotNF,; //08
					            (aCols[_nI][_nPosIPI]-aCols[_nI][_nPosDsc]-aCols[_nI][_nPosIcm]),; //09-Valor sem converter para a taxa do pedido // TMPNFE->D1_VALIPI-TMPNFE->D1_VALDESC-TMPNFE->D1_ICMSRET
								                                                       _nTxMoeda,; //10-Taxa NF
												                          "2-ITEM DA NOTA ATUAL"}) //11

								
								aAdd( _aLogAux , {StrZero(_nCont++,4),"Nota: " + CNFISCAL + "/" + CSERIE,dDataBase,aCols[_nI][_nPosItn],aCols[_nI][_nPosCod],AllTrim(Transform(aCols[_nI][_nPosQtd],PesqPict("SD1","D1_QUANT"))),"",AllTrim(Transform(aCols[_nI][_nPosPrc],PesqPict("SD1","D1_VUNIT"))),AllTrim(Transform(aCols[_nI][_nPosDsc],PesqPict("SD1","D1_VALDESC"))),AllTrim(Transform(aCols[_nI][_nPosVlr] - aCols[_nI][_nPosDsc] - aCols[_nI][_nPosIcm],PesqPict("SD1","D1_TOTAL"))), "" } )
								
								_nPtolPC := ( (TMPPED->C7_QUANT - TMPPED->C7_QUJE) * _nPtolPC ) / 100	// Percentual de tolerância quantidade PC.
								_nValToQ := ( (TMPPED->C7_QUANT - TMPPED->C7_QUJE) * _nPerToQ ) / 100	// Percentual de tolerância quantidade PC.
								_nPtolP2 := ( _nPrecoRS * _nPtolPU ) / 100	// Percentual de tolerância valor unitário PC.
								_nQtdVen := 0

								For _nX := 1 To Len(_aColsAux)
									If _nX <> _nI
										If aCols[_nI][_nPosPed] == _aColsAux[_nX][_nPosPed] .And. aCols[_nI][_nPosPIt] == _aColsAux[_nX][_nPosPIt]
											_nQtdVen += _aColsAux[_nX][_nPosQtd]
										EndIf
									EndIf
								Next _nX

								//===================================================================
								// Valida diferença entre as alíquotas de ICMS da Nota x Pedido
								//===================================================================
								If  !Empty(TMPPED->C7_PICM) .And. aCols[_nI][_nPosPICM] <> TMPPED->C7_PICM
									_lDifPC := .T.
									aAdd( _aLogVld , {StrZero(_nCont++,4),"Pedido: " + TMPPED->C7_NUM     ,SToD(TMPPED->C7_EMISSAO),TMPPED->C7_ITEM     ,TMPPED->C7_PRODUTO  ,AllTrim(Transform(TMPPED->C7_QUANT    ,PesqPict("SC7","C7_QUANT"))),AllTrim(Transform(TMPPED->C7_QUJE,PesqPict("SC7","C7_QUJE"))),AllTrim(Transform(_nPrecoRS,PesqPict("SC7","C7_PRECO")))           ,AllTrim(Transform(TMPPED->C7_VLDESC,PesqPict("SC7","C7_VLDESC")))    ,AllTrim(Transform(TMPPED->C7_TOTAL,PesqPict("SC7","C7_TOTAL")))    ,;
									                                      "Aliquota de ICMS divergente PC: " + AllTrim(Transform(TMPPED->C7_PICM      ,PesqPict("SC7","C7_PICM"))) + "%"} )
									aAdd( _aLogVld , {StrZero(_nCont++,4),"Nota: "   + CNFISCAL+"/"+CSERIE,dDataBase               ,aCols[_nI][_nPosItn],aCols[_nI][_nPosCod],AllTrim(Transform(aCols[_nI][_nPosQtd],PesqPict("SD1","D1_QUANT"))),""                                                           ,AllTrim(Transform(aCols[_nI][_nPosPrc],PesqPict("SD1","D1_VUNIT"))),AllTrim(Transform(aCols[_nI][_nPosDsc],PesqPict("SD1","D1_VALDESC"))),AllTrim(Transform(aCols[_nI][_nPosVlr],PesqPict("SD1","D1_TOTAL"))),;
									                                      "Aliquota de ICMS divergente NF: " + AllTrim(Transform(aCols[_nI][_nPosPICM],PesqPict("SC7","C7_PICM"))) + "%"} )
									aAdd( _aLogVld , {StrZero(_nCont++,4),"",SToD(""),"","","","","","","",""} )
								EndIf

								//====================================
								// Valida quantidade da Nota x Pedido
								//====================================
								If IIf(_nQtdVen > 0, _nQtdVen, aCols[_nI][_nPosQtd]) > ((TMPPED->C7_QUANT - TMPPED->C7_QUJE) + _nPtolPC)
									_lDifPC := .T.
									aAdd( _aLogVld , {StrZero(_nCont++,4),"Pedido: " + TMPPED->C7_NUM,SToD(TMPPED->C7_EMISSAO),TMPPED->C7_ITEM,TMPPED->C7_PRODUTO,AllTrim(Transform(TMPPED->C7_QUANT,PesqPict("SC7","C7_QUANT"))),AllTrim(Transform(TMPPED->C7_QUJE,PesqPict("SC7","C7_QUJE"))),AllTrim(Transform(_nPrecoRS,PesqPict("SC7","C7_PRECO"))),AllTrim(Transform(TMPPED->C7_VLDESC,PesqPict("SC7","C7_VLDESC"))),AllTrim(Transform(TMPPED->C7_TOTAL,PesqPict("SC7","C7_TOTAL"))),"Quantidade divergente e fora da tolerância de " + AllTrim(Str(_nPerToQ)) + "% Qtde: " + AllTrim(Str(_nValToQ))} )
									aAdd( _aLogVld , {StrZero(_nCont++,4),"Nota: " + CNFISCAL + "/" + CSERIE,dDataBase,aCols[_nI][_nPosItn],aCols[_nI][_nPosCod],AllTrim(Transform(aCols[_nI][_nPosQtd],PesqPict("SD1","D1_QUANT"))),"",AllTrim(Transform(aCols[_nI][_nPosPrc],PesqPict("SD1","D1_VUNIT"))),AllTrim(Transform(aCols[_nI][_nPosDsc],PesqPict("SD1","D1_VALDESC"))),AllTrim(Transform(aCols[_nI][_nPosVlr],PesqPict("SD1","D1_TOTAL"))),"Quantidade divergente e fora da tolerância."} )
									aAdd( _aLogVld , {StrZero(_nCont++,4),"",SToD(""),"","","","","","","",""} )
								EndIf

								//=======================================
								// Valida preço unitário da Nota x Pedido
								//=======================================
								_nDifPU:= ((aCols[_nI][_nPosPrc]/_nTxMoeda) - (_nPrecoRS/_nTxMoeda))
								If _nDifPU <> 0 .AND. (_nDifPU > (_nPtolP2/_nTxMoeda) .OR.;//SE MAIOR 
                                                       _nDifPU < (_nPtolP2/_nTxMoeda) ) //OU SE MENOR
									_lDifPreco := .T.
									aAdd( _aLogVld , {StrZero(_nCont++,4),"Pedido: " + TMPPED->C7_NUM,SToD(TMPPED->C7_EMISSAO),TMPPED->C7_ITEM,TMPPED->C7_PRODUTO,AllTrim(Transform(TMPPED->C7_QUANT,PesqPict("SC7","C7_QUANT"))),AllTrim(Transform(TMPPED->C7_QUJE,PesqPict("SC7","C7_QUJE"))),AllTrim(Transform(_nPrecoRS,PesqPict("SC7","C7_PRECO"))),AllTrim(Transform(TMPPED->C7_VLDESC,PesqPict("SC7","C7_VLDESC"))),AllTrim(Transform(TMPPED->C7_TOTAL,PesqPict("SC7","C7_TOTAL"))),;
									                  "Preço Unitário divergente e fora da tolerância de " + AllTrim(Str(_nPtolPU)) + "% Valor: " + AllTrim(Str(_nPtolP2))} )
									aAdd( _aLogVld , {StrZero(_nCont++,4),"Nota: " + CNFISCAL + "/" + CSERIE,dDataBase,aCols[_nI][_nPosItn],aCols[_nI][_nPosCod],AllTrim(Transform(aCols[_nI][_nPosQtd],PesqPict("SD1","D1_QUANT"))),"",AllTrim(Transform(aCols[_nI][_nPosPrc],PesqPict("SD1","D1_VUNIT"))),AllTrim(Transform(aCols[_nI][_nPosDsc],PesqPict("SD1","D1_VALDESC"))),AllTrim(Transform(aCols[_nI][_nPosVlr],PesqPict("SD1","D1_TOTAL"))),;
									                  "Preço Unitário divergente e fora da tolerância."} )
									aAdd( _aLogVld , {StrZero(_nCont++,4),"",SToD(""),"","","","","","","",""} )
								EndIf
								
								If aScan(_aPedidos, aCols[_nI][_nPosPed]) = 0//_cPedAnt <> aCols[_nI][_nPosPed]
									aAdd(_aPedidos, aCols[_nI][_nPosPed])
									//_cPedAnt := aCols[_nI][_nPosPed]
								EndIf
							Else//If TMPPED->(Eof())
								//'Índice','Nota/Pedido','Série','Dt Emissão','Item','Produto','Quantidade','Qtd Entregue','Vlr. Unit.','Desconto','Vlr Total','Ocorrência'
								aAdd( _aLogVld , {StrZero(_nCont++,4),"Nota: " + CNFISCAL + "/" + CSERIE,dDataBase,aCols[_nI][_nPosItn],aCols[_nI][_nPosCod],AllTrim(Transform(aCols[_nI][_nPosQtd],PesqPict("SD1","D1_QUANT"))),"",AllTrim(Transform(aCols[_nI][_nPosPrc],PesqPict("SD1","D1_VUNIT"))),AllTrim(Transform(aCols[_nI][_nPosDsc],PesqPict("SD1","D1_VALDESC"))),AllTrim(Transform(aCols[_nI][_nPosVlr],PesqPict("SD1","D1_TOTAL"))), "Não foi encontrado pedido relacionado a este registro." } )
							EndIf
							TMPPED->(DBCloseArea())
						EndIf
					EndIf			
                Next _nI
				
				aAdd( _aLogAux , {StrZero(_nCont++,4),"",SToD(""),"","","","","","","",""} )
                _nQtdeSaldo:=0//SALDO TOTAL DE TODOS OS ITENS DO PC DISPONIVEL PARA FAZER NOTAS
				For _nI := 1 To Len(_aPedidos)
					//========================================================
					// Totais de preço, desconto e total do pedido de compras
					//========================================================
					_cQryP := "SELECT C7_NUM, C7_EMISSAO, C7_ITEM, C7_PRODUTO, C7_QUANT, C7_QUJE, C7_PRECO, C7_TOTAL, C7_VLDESC, C7_VALIPI, C7_MOEDA "
					_cQryP += "FROM " + RetSqlName("SC7") + " "
					_cQryP += "WHERE C7_FILIAL = '" + xFilial("SC7") + "' "
					_cQryP += "  AND C7_NUM = '" + _aPedidos[_nI] + "' "
					_cQryP += "  AND C7_FORNECE = '" + cA100For + "' "
					_cQryP += "  AND D_E_L_E_T_ = ' ' "
					_cQryP := ChangeQuery(_cQryP)
					MPSysOpenQuery(_cQryP,"TMPTPD")
					
					TMPTPD->(DBGoTop())

					_nMoePedido:=TMPTPD->C7_MOEDA
                    If _nMoePedido <> 1
                       _nTxMoeda := RecMoeda(dDEmissao,_nMoePedido)
                    EndIf   
	                
					While !TMPTPD->(Eof())

                       If TMPTPD->C7_MOEDA <> 1
						  _nTotVuP += (TMPTPD->C7_PRECO*_nTxMoeda)
						  _nTotDsP += (TMPTPD->C7_VLDESC*_nTxMoeda)
						  _nTotIpP += (TMPTPD->C7_VALIPI*_nTxMoeda)
						  _nTotPed += ((TMPTPD->C7_TOTAL - TMPTPD->C7_VLDESC + TMPTPD->C7_VALIPI)*_nTxMoeda)
                          _nPrecoRS:= TMPTPD->C7_PRECO*_nTxMoeda
                          _nTotalRS:= ((TMPTPD->C7_TOTAL - TMPTPD->C7_VLDESC + TMPTPD->C7_VALIPI)*_nTxMoeda)
					   Else
                          _nPrecoRS:= TMPTPD->C7_PRECO
                          _nTotalRS:= (TMPTPD->C7_TOTAL - TMPTPD->C7_VLDESC + TMPTPD->C7_VALIPI)
						  _nTotVuP += TMPTPD->C7_PRECO
						  _nTotDsP += TMPTPD->C7_VLDESC
						  _nTotIpP += TMPTPD->C7_VALIPI
						  _nTotPed += TMPTPD->C7_TOTAL - TMPTPD->C7_VLDESC + TMPTPD->C7_VALIPI
                       EndIf
					   aAdd( _aLogAu1 , {StrZero(_nCont++,4),"Pedido: " + TMPTPD->C7_NUM,SToD(TMPTPD->C7_EMISSAO),TMPTPD->C7_ITEM,TMPTPD->C7_PRODUTO,AllTrim(Transform(TMPTPD->C7_QUANT,PesqPict("SC7","C7_QUANT"))),AllTrim(Transform(TMPTPD->C7_QUJE,PesqPict("SC7","C7_QUJE"))),AllTrim(Transform(TMPTPD->C7_PRECO,PesqPict("SC7","C7_PRECO"))),AllTrim(Transform(TMPTPD->C7_VLDESC,PesqPict("SC7","C7_VLDESC"))),AllTrim(Transform(TMPTPD->C7_TOTAL - TMPTPD->C7_VLDESC + TMPTPD->C7_VALIPI,PesqPict("SC7","C7_TOTAL"))),""} )

                       _nQtde:=TMPTPD->C7_QUANT-TMPTPD->C7_QUJE
					    If (_nPos:=aScan(_aItensNFAtual,{|P| P[1]== TMPTPD->C7_NUM+TMPTPD->C7_ITEM })) <> 0
                            _nQtdeNFAtual:= _aItensNFAtual[_nPos,2] 
							_nQtde := (_nQtde-_nQtdeNFAtual)//tira a qtde da NF atual
						EndIf
						_nQtde:=If(_nQtde<0,0,_nQtde)

						_nQtdeSaldo+=_nQtde
					   aAdd(_aItensPrev,{         TMPTPD->C7_NUM,;//01
					            	          TMPTPD->C7_PRODUTO,;//02
					            	             TMPTPD->C7_ITEM,;//03
										     	        "PEDIDO",;//04  //NF
										        TMPTPD->C7_QUANT,;//05 
					                                      _nQtde,;//06 //Saldo para usar ainda / Qtde não usada em nehuma NF , nem na atual
										               _nPrecoRS,;//07
										               _nTotalRS,;//08
					       (TMPTPD->C7_VALIPI-TMPTPD->C7_VLDESC),;//09
								                       _nTxMoeda,;//10  USAR A TAXA DA DATA DE EMISSAO DA NOTA ATUAL RecMoeda(dDEmissao,_nMoePedido)
											  "1-ITEM DO PEDIDO"})//11

					   TMPTPD->(DBSkip())
					EndDo
					TMPTPD->(DBCloseArea())

					//========================================================================
					// Soma o valor total de todas as notas emitidas para o pedido em questão
					//========================================================================
					_cQry := "SELECT D1_DOC, D1_SERIE, D1_ITEM, D1_COD, D1_QUANT, D1_TOTAL, D1_VUNIT, D1_VALDESC, D1_ICMSRET, D1_VALIPI , D1_EMISSAO , D1_PEDIDO , D1_ITEMPC "
					_cQry += "FROM " + RetSqlName("SD1") + " SD1 "
					_cQry += "INNER JOIN " + RetSqlName("SF1") + " SF1 ON F1_FILIAL = D1_FILIAL AND F1_DOC = D1_DOC AND F1_SERIE = D1_SERIE AND F1_FORNECE = D1_FORNECE AND F1_LOJA = D1_LOJA AND F1_FORMUL = D1_FORMUL AND F1_STATUS <> ' ' AND SF1.D_E_L_E_T_ = ' ' "
					_cQry += "WHERE D1_FILIAL = '" + xFilial("SD1") + "' "
					_cQry += "  AND D1_PEDIDO = '" + _aPedidos[_nI] + "' "
					_cQry += "  AND D1_FORNECE = '" + cA100For + "' "
					_cQry += "  AND SD1.D_E_L_E_T_ = ' ' "
					_cQry := ChangeQuery(_cQry)
					MPSysOpenQuery(_cQry,"TMPNFE")
												
					TMPNFE->(DBGoTop())
					
					While !TMPNFE->(Eof())
					
						_nTotDsN += TMPNFE->D1_VALDESC
						_nTotIcN += TMPNFE->D1_ICMSRET
						_nTotIpN += TMPNFE->D1_VALIPI 
					    _nTaxaNF := RecMoeda(TMPNFE->D1_EMISSAO ,_nMoePedido)
                        
						_nTotalNF := TMPNFE->D1_TOTAL - TMPNFE->D1_VALDESC - TMPNFE->D1_ICMSRET + TMPNFE->D1_VALIPI
                        If _nMoePedido <> 1
						   _nTotalNF := _nTotalNF / _nTaxaNF
                           _nTotalNF := _nTotalNF *_nTxMoeda 
                        EndIf   
                        
						_nTotNfs += _nTotalNF  // 2 = Roda uma query no SD1 e soma no total na nota 
						
						aAdd( _aLogAux , {StrZero(_nCont++,4),"Nota: " + TMPNFE->D1_DOC + "/" + TMPNFE->D1_SERIE, dDataBase, TMPNFE->D1_ITEM, TMPNFE->D1_COD, AllTrim(Transform(TMPNFE->D1_QUANT,PesqPict("SD1","D1_QUANT"))),"",AllTrim(Transform(TMPNFE->D1_VUNIT,PesqPict("SD1","D1_VUNIT"))),AllTrim(Transform(TMPNFE->D1_VALDESC,PesqPict("SD1","D1_VALDESC"))),AllTrim(Transform(TMPNFE->D1_TOTAL - TMPNFE->D1_VALDESC - TMPNFE->D1_ICMSRET + TMPNFE->D1_VALIPI,PesqPict("SD1","D1_TOTAL"))),""} )

					   aAdd(_aItensPrev,{                      TMPNFE->D1_PEDIDO,;//01
					            	                              TMPNFE->D1_COD,;//02
					            	                           TMPNFE->D1_ITEMPC,;//03
										                     	  TMPNFE->D1_DOC,;//04 //NF
										                        TMPNFE->D1_QUANT,;//05 //QTDE DAS NFS anteriores
					                                                           0,;//06 //Saldo para usar ainda / Qtde não usada
										                        TMPNFE->D1_VUNIT,;//07
										                               _nTotalNF,;//08
					   (TMPNFE->D1_VALIPI-TMPNFE->D1_VALDESC-TMPNFE->D1_ICMSRET),;//09//Valor sem converter para a taxa do pedido
								                                        _nTaxaNF,;//10//Taxa NF
												              "2-ITEM DA NOTA  "})//11

					    TMPNFE->(DBSkip())

					EndDo
					TMPNFE->(DBCloseArea())
				Next _nI

				If Len(_aLogAu1) > 0
					For _nI := 1 To Len(_aLogAu1)
						aAdd(_aLogVld, _aLogAu1[_nI])
					Next _nI
					aAdd( _aLogVld , {StrZero(_nCont++,4),"",SToD(""),"","","","","","","",""} )
				EndIf
				
				If Len(_aLogAux) > 0
					For _nI := 1 To Len(_aLogAux)
						aAdd(_aLogVld, _aLogAux[_nI])
					Next _nI
					aAdd( _aLogVld , {StrZero(_nCont++,4),"",SToD(""),"","","","","","","",""} )
				EndIf

                nTotSemPrevisto:=_nTotNfs
				aProdPrevisto:={}
				For _nI := 1 To Len(_aItensPrev)
				    If LEFT(_aItensPrev[_nI,11],1) = "2" 
					   Loop
					EndIf
				    _nSoma:=_nPreco:=_nImps:=0
				    _nQtde :=_aItensPrev[_nI,05]
				    _nSaldo:=_aItensPrev[_nI,06]
					_nTaxa :=_aItensPrev[_nI,10]//Usou A TAXA DA DATA DE EMISSAO DA NOTA ATUAL RecMoeda(dDEmissao,_nMoePedido)
				    If _nSaldo > 0 .And. _nSaldo <> _nQtde//Se o produto tem nota já, usa a quantidade que não foi usada ainda
					   _nPreco:=_aItensPrev[_nI,7]
					   _nImps :=((_aItensPrev[_nI,9]/_nQtde)*_nSaldo)
					   _nSoma :=((_nSaldo * _nPreco) + _nImps) 
					ElseIf _nSaldo = _nQtde //Se o item não tiver em nenhuma nota ainda usa o campo C7_TOTAL para calcular
					   _nPreco:=_aItensPrev[_nI,7] 
					   _nSoma :=_aItensPrev[_nI,8] 
					   _nImps :=_aItensPrev[_nI,9]
					EndIf
					aAdd(aProdPrevisto,ACLONE(_aItensPrev[_nI]))
					_nPosPre:=Len(aProdPrevisto)
					aProdPrevisto[_nPosPre,04]:="PREVISTO"
					aProdPrevisto[_nPosPre,05]:=_nSaldo
					aProdPrevisto[_nPosPre,06]:=0
					aProdPrevisto[_nPosPre,07]:=_nPreco
					aProdPrevisto[_nPosPre,08]:=_nSoma
					aProdPrevisto[_nPosPre,09]:=_nImps
					aProdPrevisto[_nPosPre,11]:="3-SOMA PREVISTA"
				    //_nTotNfs+=_nSoma // 3 = Soma o saldo no total da nota. 
				Next

				For _nI := 1 To Len(aProdPrevisto)
				    aAdd(_aItensPrev,ACLONE(aProdPrevisto[_nI]))
				Next                

				aSort(_aItensPrev,,,{ |x,y| x[1]+x[3]+x[11]+x[4] < y[1]+y[3]+y[11]+y[4] })

				_nSoma:=0
				_nTotItem:=0
				For _nI := 1 To Len(_aItensPrev)
				    If LEFT(_aItensPrev[_nI,11],1) = "1" 
				       _nTotItem:=_aItensPrev[_nI,08]
					   Loop
					EndIf
				    If LEFT(_aItensPrev[_nI,11],1) = "2" 
	                   _nSoma+=	_aItensPrev[_nI,08]			
					   Loop
					EndIf
				    If LEFT(_aItensPrev[_nI,11],1) = "3" 
					   _nSoma+=	_aItensPrev[_nI,08]		
					   _aItensPrev[_nI,11]:="3-SOMA PREVISTA, Total Item: "+AllTrim(TRANS(_nSoma,"@E 999,999,999,999.99"))+If(_nTotItem<>_nSoma," divergente do Pedido, Diferenca: "+AllTrim(TRANS(_nSoma-_nTotItem,"@E 999,999,999.999999999")),"")
					   _nSoma:=0
					EndIf
				Next                

	            For _nI := 1 To Len(_aItensPrev)
		            _aItensPrev[_nI,03]:="'"+_aItensPrev[_nI,03]
		            _aItensPrev[_nI,04]:="'"+_aItensPrev[_nI,04]
		            _aItensPrev[_nI,05]:=TRANS(_aItensPrev[_nI,05],"@E 999,999,999,999")
		            _aItensPrev[_nI,06]:=TRANS(_aItensPrev[_nI,06],"@E 999,999,999,999")
		            _aItensPrev[_nI,07]:=TRANS(_aItensPrev[_nI,07],"@E 999,999,999,999.999999999")
		            _aItensPrev[_nI,08]:=TRANS(_aItensPrev[_nI,08],"@E 999,999,999,999.99")
		            _aItensPrev[_nI,09]:=TRANS(_aItensPrev[_nI,09],"@E 999,999,999,999.99")
		            _aItensPrev[_nI,10]:=TRANS(_aItensPrev[_nI,10],"@E 9999.999999999")
		        Next _nI
                _aAuxItensPrev:={}
				_cItem:=""
	            For _nI := 1 To Len(_aItensPrev)
					If Empty(_cItem)
					   _cItem:=_aItensPrev[_nI,03]
					ElseIf _cItem <> _aItensPrev[_nI,03]
					   _cItem:=_aItensPrev[_nI,03]
				       aAdd(_aAuxItensPrev,{   "",;//01
					            	           "",;//02
					            	           "",;//03
										       "",;//04 
										       "",;//05 
				                               "",;//06 
										       "",;//07
                                               "",;//08
					                           "",;//09
								               "",;//10
			                                   ""})//11
					EndIf
				    aAdd(_aAuxItensPrev,ACLONE(_aItensPrev[_nI]))
				Next _nI
				_aItensPrev:=ACLONE(_aAuxItensPrev)
                
				_nTxMoeda:=1
                If _nMoePedido <> 1
                   _nTxMoeda := RecMoeda(dDEmissao,_nMoePedido)
                EndIf   

				aAdd(_aItensPrev,{	"",;//01
					              	"",;//02
					              	"",;//03
								  	"",;//04 
									"",;//05 
				                    "",;//06 
									"",;//07
   									TRANS((nTotSemPrevisto/_nTxMoeda),"@E 999,999,999,999.99"),;//08
					                "",;//09
 			 						TRANS(_nTxMoeda,"@E 9999.999999999"),;//10
			                		"SOMA SEM O PREVISTO"})//11

				aAdd(_aItensPrev,{  "",;//01
					            	"",;//02
					            	"",;//03
									"",;//04 
									"",;//05 
				                    "",;//06 
									"",;//07
									TRANS((_nTotPed/_nTxMoeda),"@E 999,999,999,999.99"),;//08
					                "",;//09
						 			TRANS(_nTxMoeda,"@E 9999.999999999"),;//10
			                 		"TOTAL DOS PEDIDOS" })//11

				aAdd(_aItensPrev,{  "",;//01
					            	"",;//02
					            	"",;//03
									"",;//04 
									"",;//05 
				                    "",;//06 
									"",;//07
									TRANS((_nTotNfs/_nTxMoeda),"@E 999,999,999,999.99"),;//08
					                "",;//09
 			 						TRANS(_nTxMoeda,"@E 9999.999999999"),;//10
			                     	"TOTAL PREVISTO"})//11

				aAdd(_aItensPrev,{  "",;//01
									"",;//02
									"",;//03
									"",;//04 
									"",;//05 
									"",;//06 
									"",;//07
									TRANS(((_nTotNfs-_nTotPed)/_nTxMoeda),"@E 99,999,999,999.99"),;//08
					                "",;//09
 			 						TRANS(_nTxMoeda,"@E 9999.999999999"),;//10
			                 		"PREVISTO - PEDIDOS"})//11
               				
                _lAviso := .F.
                If ( _nTotNfs /_nTxMoeda) >  (_nTotPed + _nValToT )//TESTA SE A SOMATORIA DE TODAS AS NOTAS É MAIOR QUE 20 REIAS 
                   _lDifPreco := .T.
					aAdd( _aLogVld , {StrZero(_nCont++,4),"",dDataBase,"","","","","","",_nTotNfs,"Divergência no valor total da Nota"} )
				Else
                   IF !_lDifPC .AND. _lDifPreco .AND. _nQtdeSaldo > 0 //SE TEM SALDO AINDA PARA FAZER NOTA DO PEDIDO SÓ AVISA SOBRE O ERRO DO PREÇO UNITARIO
                      _lAviso := .T.//Só VIRA aviso quando não tem erro _lDifPC (_lDifPC=.F.) e tem erro do preço unitario (_lDifPC=.T.) 
                                    //e o saldo de qq item do PC é maior que zero (_nQtdeSaldo > 0)
				EndIf
                   _lDifPreco := .F. //Se não estourar o 20 reias no total da nota , não valida o preço unitario
                EndIf

				For _nI := 1 To Len(_aLogVld)
					_aLogVld[_nI][1] := StrZero(_nI,4)
				Next _nI

				If _lDifTES 
                   U_ITListBox( 'TES escolhida inválida para compra de uso direto (MT100TOK)' , aCampVld2 , _aLogVld2 , .T. , 1 )
                   _lRet := .F.
				EndIf
                If _lRet .And. (_lDifPC .OR. _lDifPreco .OR. _lAviso)
                   IF _lAviso .AND. !_lDifPC//O aviso é só para estouro de preço unitario em notas de pedido parccial
						_aCabItensPrev:={"PEDIDO","PRODUTO","ITEM","NOTA","Quantidade","Qtde não usada","Vlr. Unit.","Vlr Total Liq.","'IPI-Desc-ICM Ret.","*Tx Moeda","Ocorrencia"}
						_aButtons:={}
						aAdd(_aButtons,{"BUDGET",{||  U_ITListBox( 'Log do TOTAL PREVISTO Pedido x NF, Filial: '+cFilAnt , _aCabItensPrev , _aItensPrev , .T.      , 1 )  },"Detalhar Previsto", "Detalhar Previsto" }) 
                      //                  _cTitAux                                              , _aHeader , _aCols   , _lMaxSiz , _nTipo , _cMsgTop , _lSelUnc , _aSizes , _nCampo , bOk , bCancel,_aButtons
                      bBloco:={||  U_ITListBox( 'Log de Comparação Pedido x NF, Filial: '+cFilAnt , aCampVld , _aLogVld , .T.      , 1      ,          ,          ,         ,         ,     ,        ,_aButtons) }
                      _cProblema:='Foram encontradas divergências entre o pedido e o documento, clique em "mais detalhes" para verificar, CONFIRMA GRAVAÇÃO?'
                      _cSolucao:="Entre em contato com o departamento compras para verificar."
                      If !U_ITMSG(_cProblema,'Atenção!',_cSolucao,3,2,3,,"GRAVAR","VOLTAR",bBloco)
				   _lRet := .F.
				EndIf
                   Else
                      If FWAlertYesNo("Foram encontradas divergências entre o pedido e o documento e foi gerado um log, deseja visualizar o log?","MT100TOK023")
                         _aCabItensPrev:={"PEDIDO","PRODUTO","ITEM","NOTA","Quantidade","Qtde não usada","Vlr. Unit.","Vlr Total Liq.","'IPI-Desc-ICM Ret.","*Tx Moeda","Ocorrencia"}
                         _aButtons:={}
                         AADD(_aButtons,{"BUDGET",{||  U_ITListBox( 'Log do TOTAL PREVISTO Pedido x NF, Filial: '+cFilAnt , _aCabItensPrev , _aItensPrev , .T.      , 1 )  },"Detalhar Previsto", "Detalhar Previsto" }) 
                         //                  _cTitAux                                              , _aHeader , _aCols   , _lMaxSiz , _nTipo , _cMsgTop , _lSelUnc , _aSizes , _nCampo , bOk , bCancel,_aButtons
                         U_ITListBox( 'Log de Comparação Pedido x NF, Filial: '+cFilAnt , aCampVld , _aLogVld , .T.      , 1      ,          ,          ,         ,         ,     ,        ,_aButtons)
                      EndIf
					_lRet := .F.
                   Endif
				EndIf
	
			EndIf
		EndIf
	EndIf

	//=======================================================================
	//Valida nota/série/item origem para notas que tem esses itens prenchidos
	//e são notas normais sem formulário próprio
	//=======================================================================
	If _lRet .And. cFormul <> "S" .And. CTIPO == "N"

   		_aLogNfO	:=	{} 
		_nPosNfO 	:= 	aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "D1_NFORI"   	  	} ) // Nota fiscal de Origem
		_nPosSeO 	:= 	aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "D1_SERIORI"  		} ) // Série de Origem
		_nPosItO 	:= 	aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "D1_ITEMORI"     	} ) // Item Nota fiscal de Origem
		_nPosCod 	:= 	aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "D1_COD"     		} ) // Código do Produto
		_nPosItn 	:= 	aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "D1_ITEM"			} ) // Item do Documento
	
		For _nI := 1 to Len(acols)
			If !aCols[_nI][Len(aHeader)+1] //Não verifica linhas deletadas
				//verifica se série/nota/item origem estão preenchidos
				If 	Empty(acols[_nI][_nPosNfO]) .And. ( !(Empty(acols[_nI][_nPosSeO])) .Or. !(Empty(acols[_nI][_nPosItO]))) .Or. ;
					Empty(acols[_nI][_nPosSeO]) .And. ( !(Empty(acols[_nI][_nPosNfO])) .Or. !(Empty(acols[_nI][_nPosItO]))) .Or. ;
					Empty(acols[_nI][_nPosItO]) .And. ( !(Empty(acols[_nI][_nPosNfO])) .Or. !(Empty(acols[_nI][_nPosSeO]))) 
	
						aAdd(_aLogNfO, {	acols[_nI][_nPosItn], acols[_nI][_nPosCod], 1, "", "", "" } )						
				
				//se estão preenchidos verifica se os dados são consistentes com pelo menos uma nota de entrada ou saída
				ElseIf !(	Empty(acols[_nI][_nPosNfO]))
					_cQuery := " SELECT SD2.D2_DOC "
					_cQuery += " FROM  "+ RetSQLName('SD2') +" SD2 "
					_cQuery += " WHERE SD2.D2_FILIAL = '" + xFilial("SD2") + "'"
					_cQuery += " AND SD2.D2_CLIENTE = '"+ AllTrim(cA100For) +"' "
					_cQuery += " AND SD2.D2_LOJA = '"+ AllTrim(cLoja) +"' "
					_cQuery += " AND SD2.D2_DOC = '"+ AllTrim(acols[_nI][_nPosNfO]) +"' "
					_cQuery += " AND SD2.D2_ITEM = '"+ AllTrim(acols[_nI][_nPosItO]) +"' "
					_cQuery += " AND SD2.D2_SERIE = '"+ AllTrim(acols[_nI][_nPosSeO]) +"' "
					_cQuery += " AND SD2.D2_COD = '"+ AllTrim(acols[_nI][_nPosCod]) +"' "
					_cQuery += " AND (SELECT SF2.F2_DOC FROM "+ RetSQLName('SF2') +" SF2 " 
					_cQuery += " WHERE SF2.D_E_L_E_T_ = ' ' AND  SF2.F2_FILIAL = '" +xFilial("SF2") + "'"
					_cQuery += " AND SF2.F2_DOC = '" + AllTrim(acols[_nI][_nPosNfO]) +"' "
					_cQuery += " AND SF2.F2_CLIENTE 	= '" + AllTrim(cA100For) +"' "
					_cQuery += " AND SF2.F2_LOJA 		= '" + AllTrim(cLoja) +"' "
					_cQuery += " AND SF2.F2_EMISSAO = SD2.D2_EMISSAO"
					_cQuery += " AND SF2.F2_SERIE = '" + AllTrim(acols[_nI][_nPosSeO]) +"' AND ROWNUM = 1) = '" +AllTrim(acols[_nI][_nPosNfO]) + "'" 
					_cQuery += " AND (SD2.D2_TIPO = 'B' OR SD2.D2_TIPO = 'D')" 
					_cQuery += " AND SD2.D_E_L_E_T_ = ' '
					
					If Select(_cAlias) > 0
						(_cAlias)->(DBCloseArea())
					EndIf
					_cQuery := ChangeQuery(_cQuery)
					MPSysOpenQuery(_cQuery,_cAlias)
				
					//se não encontrar procura no d1
					If  (_cAlias)->( Eof() )
    	 		
						_cQuery := " SELECT SD1.D1_DOC "
						_cQuery += " FROM  "+ RetSQLName('SD1') +" SD1 "
						_cQuery += " WHERE SD1.D1_FILIAL = '" + xFilial("SD1") + "'"
						_cQuery += " AND SD1.D1_FORNECE = '"+ AllTrim(cA100For) +"' "
						_cQuery += " AND SD1.D1_LOJA = '"+ AllTrim(cLoja) +"' "
						_cQuery += " AND SD1.D1_DOC = '"+ AllTrim(acols[_nI][_nPosNfO]) +"' "
						_cQuery += " AND SD1.D1_ITEM = '"+ AllTrim(acols[_nI][_nPosItO]) +"' "
						_cQuery += " AND SD1.D1_SERIE = '"+ AllTrim(acols[_nI][_nPosSeO]) +"' "
						_cQuery += " AND SD1.D1_COD = '"+ AllTrim(acols[_nI][_nPosCod]) +"' "
						_cQuery += " AND (SELECT SF1.F1_STATUS FROM "+ RetSQLName('SF1') +" SF1 " 
						_cQuery += " WHERE SF1.D_E_L_E_T_ = ' ' AND  SF1.F1_FILIAL = '" +xFilial("SF1") + "'"
						_cQuery += " AND SF1.F1_DOC = '" + AllTrim(acols[_nI][_nPosNfO]) +"' "
						_cQuery += " AND SF1.F1_FORNECE 	= '" + AllTrim(cA100For) +"' "
						_cQuery += " AND SF1.F1_LOJA 		= '" + AllTrim(cLoja) +"' "
						_cQuery += " AND SF1.F1_FORMUL  <> 'S'"
						_cQuery += " AND SF1.F1_DTDIGIT = SD1.D1_DTDIGIT"
						_cQuery += " AND SF1.F1_SERIE = '" + AllTrim(acols[_nI][_nPosSeO]) +"' AND ROWNUM = 1) = 'A' "
						_cQuery += " AND SD1.D1_FORMUL  <> 'S'"
						_cQuery += " AND SD1.D_E_L_E_T_ = ' '
					
						If Select(_cAlias) > 0
							(_cAlias)->(DBCloseArea())
						EndIf
					
						_cQuery := ChangeQuery(_cQuery)
						MPSysOpenQuery(_cQuery,_cAlias)
     	
    	 				If (_cAlias)->(Eof())
    	 					//se não encontrou nota com os dados 
    	 					aAdd(_aLogNfO, {	acols[_nI][_nPosItn], acols[_nI][_nPosCod], 2, AllTrim(acols[_nI][_nPosNfO]),;
    	 														 AllTrim(acols[_nI][_nPosSeO]), AllTrim(acols[_nI][_nPosItO])   } )	
    	 				EndIf
    	 			EndIf	
    	 			
    	 			If Select(_cAlias) > 0
						(_cAlias)->( DBCloseArea() )
					EndIf	
				EndIf 
			EndIf
		Next _nI

		//se teve problemas haverá registros no array _aLogNfO
		If Len(_aLogNfO) > 0
			_cmens 	:= ""
			For _nI := 1 To Len(_aLogNfo)
				If _aLogNfo[_nI][3] == 1
					_cmens += " Para o produto "+ _aLogNfo[_nI][2] +", item " + _aLogNfo[_nI][1] 
					_cmens += " não foram preenchidos todos os dados da nota de origem." + CHR(13)
				Else
					_cmens += " Para o produto "+ _aLogNfo[_nI][2] +", item " + _aLogNfo[_nI][1] 
					_cmens += " não foi encontrada a nota de origem referenciada.  "  + _aLogNfo[_nI][4] + "/" + _aLogNfo[_nI][5]+ "/" + _aLogNfo[_nI][6] + CHR(13)
				EndIf
			Next _nI
	
			_nRet := aviso('Atenção! (MT100TOK)' , _cmens  + CHR(13) + "Deseja continuar mesmo assim?",{"Confirma","Cancela"},3 )
										
			If _nRet == 2
				_lRet := .F.
			EndIf
		EndIf
	EndIf

    //Validacoes do Projeto de unificação de pedidos de troca nota //AWF-TN
	If _lRet
		If _cRet_TN == "NAO_ACHOU_PF"
  			_cAux:= "Pedido de Faturamento "+xFilial("SC5")+" "+_cPedFaturamento+" não encontrado ou Pedido de Carregamento "+_cFilCarregamento+" "+_cPedCarregamento
			_cAux+= " não vinculado a esse Pedido de Faturamento. Favor entrar em contato com area de TI."
			If l103Auto
				AutoGRLog("MT100TOK024"+CRLF+_cAux)
			Else
				FWAlertError(_cAux,"MT100TOK024")
			EndIf
			_lRet := .F.
    	ElseIf _cRet_TN = "ACHOU_PF"
			_lOK:=.F.
         
	     	SC6->(DBSetOrder(1))//C6_FILIALC6_NUM
         	If SC6->(DBSeek(_cFilCarregamento + _cPedCarregamento))
	            While SC6->( !Eof() ) .And. SC6->C6_FILIAL + SC6->C6_NUM == _cFilCarregamento  + _cPedCarregamento 
	            	If aScan(_aLogItens, {|L| L[3] == SC6->C6_PRODUTO }) = 0
						_lDiferente:=.T.
		                aAdd(_aLogItens,{ .F. ,SC6->C6_ITEM, SC6->C6_PRODUTO , TRANS(SC6->C6_QTDVEN ,AVSX3('C6_QTDVEN',6)) ,;
                                                           TRANS(SC6->C6_PRCVEN ,AVSX3('C6_PRCVEN',6)) ,"","","Item nao encontrado na NF" } )
		            EndIf
		            SC6->( DBSkip() )
            	EndDo
         	EndIf

         	If Len(_aLogItens) > 0 .And. _lDiferente
				For _nI := 1 To Len(_aLogItens)
					_aLogItens[_nI,3] := AllTrim(_aLogItens[_nI,3])+" - "+AllTrim(Posicione("SB1",1,xFilial("SB1")+_aLogItens[_nI,2],"B1_DESC"))
				Next _nI
				_lRet:=!_lDiferente//Se tiver diferente = .T. retorna .F.
            
				//Ordena _alogitens trazendo itens com problema primeiro
				_alogitens := aSort(_alogitens, , , {|x,y|x[7] < y[7]})

				_cProblema:="Ocorreram divergencias entre os itens do Pedidos de Carregamento e da NF, para maiores detalhes veja a Coluna Observação."
				_cSolucao :="Para fechar a tela de Log clique no Botão FECHAR."
				_bOK:={|| xMagHelpFis("Atenção! (MT100TOK)",_cProblema,_cSolucao) , .F. }

				U_ITListBox( 'Log de Itens de Pedidos de Carregamento X NF (MT100TOK)' ,;
						{" ","Item","Código e Descricao do Item",'Qtde Ped.','Pr. Unit Ped.','Qtde NF.','Pr. Unit NF','Observação'},_aLogItens,.T.,4,"Pedido de Carregamento: "+_cFilCarregamento+" "+_cPedCarregamento+" X NF: "+CNFISCAL+" "+CSERIE,,;
						{ 10, 30,                     110,         30,             30,        30,           30,         90},, _bOK  , )
         	EndIf
    	EndIf

	    If Len(_aLogSaldos) > 0 
	        For _nI := 1 To Len(_aLogSaldos)
                _aLogSaldos[_nI,2] := AllTrim(_aLogSaldos[_nI,2])+" - "+AllTrim(Posicione("SB1",1,xFilial("SB1")+_aLogSaldos[_nI,2],"B1_DESC"))
            Next _nI
            _lRet:=.F.

			//"Após o lançamento dessa NF o saldo em poder de terceiros ficará apenas com a qtde de "+AllTrim(Str(_nDif))+", e isso deixará o saldo em aberto." ,;
			//"Favor verifcar com o depto. Fiscal e fornecedor as quantidades a retornar." )
            _cProblema:="Após o lançamento dessa NF o saldo dos produtos em poder de terceiros listados nesse Log ficará apenas com a qtde em aberta listada e isso deixará o saldo em aberto."
            _cSolucao :="Para fechar a tela de Log clique no Botão FECHAR."
            _bOK:={|| xMagHelpFis("Atenção! (MT100TOK)",_cProblema,_cSolucao) , .F. }

            U_ITListBox( 'Log de Saldos de retorno de Estoque (MT100TOK-'+AllTrim(Str(ProcLine()))+')' ,;
	                   {" ","Código e Descricao do Item",'Quantidade','Saldo Atual','Qtde em aberto','Observação'},_aLogSaldos,.T.,4,_cProblema,,;
 	                   { 10,                         130,          30,           40,              50,         100},, _bOK  , )
       	EndIf
	EndIf
EndIf//If IsInCallStack('TUDOOK')

FWRestArea(_aArea)

Return( _lRet )

/*
===============================================================================================================================
Programa----------: PosPedFaT(cChaveSA2,cChaveSF2)
Autor-------------: Alex Wallauer
Data da Criacao---: 25/08/2016
Descrição---------: Funcao utilizada para Posicionar no Pedido de Faturamento quando é TROCA NOTA
Parametros--------: cChaveSA2: Codigo do Fornecedor + Loja 
                    cChaveSF2: Nota Fiscal + Serie
Retorno-----------: cRet: "ACHOUPF" / "NAOACHOUPF" / "NAOTROCANF"    
===============================================================================================================================
*/
User Function PosPedFaT(cChaveSA2 As Character, cChaveSF2 As Character)

Local cRet    :="NAO_TROCA_NF" As Character
Local _cCNPJ  :="" As Character
Local _nRecSM0:=SM0->(RECNO()) As Logical
Local _lPed_Troca_NF   :=.F. As Logical
_cPedFaturamento :=""
_cFilCarregamento:=""
_cPedCarregamento:=""

SA2->(DBSetOrder(1))
If SA2->(DBSeek(xFilial("SA2")+cChaveSA2))
   _cCNPJ:=SA2->A2_CGC
EndIf

SM0->(DBSetOrder(1))
SM0->(DBGoTop())
While SM0->(!Eof())
   If SM0->M0_CGC == _cCNPJ
	  _cFilCarregamento:=AllTrim(SM0->M0_CODFIL)
	  Exit
   EndIf
   SM0->(DBSkip())
EndDo
SM0->(DBGoTo(_nRecSM0))

SF2->( DBSetOrder(1) )
If !Empty(_cFilCarregamento) .And. SF2->(DBSeek(_cFilCarregamento+cChaveSF2))
	_cPedCarregamento:=SF2->F2_I_PEDID
EndIf

SC5->( DBSetOrder(1) )
If !Empty(_cPedCarregamento) .And. SC5->(DBSeek(_cFilCarregamento+_cPedCarregamento))
	_lPed_Troca_NF  :=(SC5->C5_I_TRCNF = "S")
	_cPedFaturamento:= SC5->C5_I_PDFT
EndIf

cRet:="NAO_TROCA_NF"//Inicia com "NAOTROCANF" pq pode ser que o Pedido não é troca nota
If _lPed_Troca_NF
	cRet:="NAO_ACHOU_PF"
	If SC5->(DBSeek(xFilial("SC5")+_cPedFaturamento)) .And. _cPedCarregamento == SC5->C5_I_PDPR
       cRet:="ACHOU_PF"
	EndIf
EndIf

Return cRet
