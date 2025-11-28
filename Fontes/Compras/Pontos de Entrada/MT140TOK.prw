/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |05/06/2020| Chamado 33166. Modificada a leitura da DataBase até TOTVS corrigir o problema.
Lucas Borges  |08/06/2020| Chamado 33180, 33189 e 33191. Corrigido error.log.
Lucas Borges  |29/12/2020| Chamado 34986. Ajuste para gravar o movimento do Leite de Terceiros e Contra Nota no Leite Próprio.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: MT140TOK
Autor-----------: Alexandre Villar
Data da Criacao-: 02/06/2014
Descrição-------: P.E. na rotina de cadastro de Pré-Nota de Entrada. Responsável por validar todos os itens do pré-documento  
				Finalidade: Este ponto é executado após verificar se existem itens a serem gravados e tem como objetivo validar
				todos os itens do pré-documento.
Parametros------: ParamIXB[1] -> .T. dados válidos / .F. dados inválidos
Retorno---------: lRet -> L -> .T. dados válidos/ .F. dados inválidos
===============================================================================================================================
*/
User Function MT140TOK

Local _cAlias	:= GetNextAlias()
Local _cDtRef	:= DToS(IIf(l103Auto,aAutoCab[aScan( aAutoCab , {|X| Upper( AllTrim( X[1] ) ) == "F1_DTDIGIT"} )][2],dDataBase))//DToS( dDataBase )
Local _lRet		:= .T.
Local _nPosPrd	:= GDFieldPos( "D1_COD"		)
Local _nPosNOri	:= GDFieldPos( "D1_NFORI"	)
Local _nPosSOri	:= GDFieldPos( "D1_SERIORI"	)
Local _nPosCod 	:= 0
Local _nPosNfO	:= 0
Local _nPosSeO 	:= 0
Local _nPosItO	:= 0
Local _aLogNfO	:= 0
Local _nPosItn	:= 0
Local _nI		:= 0
Local _cMens	:= ""
Local _nRet		:= 0

If INCLUI 
	If Type( "cNFiscal" ) == "C"
		cNFiscal := PadL( AllTrim(cNFiscal) , TamSX3("F1_DOC")[01] , "0" )
	EndIf
EndIf

//Valido se o período do Leite de terceiros existe e está aberto
If cTipo == "N"
	_lRet:= U_ValLT3(aCols,_cDtRef,_nPosPrd,_nPosNOri,_nPosSOri)
EndIf
//---------------------------------------------------------------------------
//Valida nota/série/item origem para notas que tem esses itens prenchidos
//e são notas normais sem formulário próprio
//---------------------------------------------------------------------------
If _lRet .And. CFORMUL <> "S" .And. CTIPO == "N"

   	_aLogNfO	:=	{} 
	_nPosNfO 	:= 	aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "D1_NFORI"   	  	} ) // Nota fiscal de Origem
	_nPosSeO 	:= 	aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "D1_SERIORI"  		} ) // Série de Origem
	_nPosItO 	:= 	aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "D1_ITEMORI"     	} ) // Item Nota fiscal de Origem
	_nPosCod 	:= 	aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "D1_COD"     		} ) // Código do Produto
	_nPosItn 	:= 	aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "D1_ITEM"			} ) // Item do Documento
	_nI			:= 1
	
	For _nI := 1 to Len(acols)
		If !aCols[_nI][Len(aHeader)+1] //Não verifica linhas deletadas	
			//verifica se série/nota/item origem estão preenchidos
			If 	Empty(acols[_nI][_nPosNfO]) .And. ( !(Empty(acols[_nI][_nPosSeO])) .Or. !(Empty(acols[_nI][_nPosItO]))) .Or. ;
				Empty(acols[_nI][_nPosSeO]) .And. ( !(Empty(acols[_nI][_nPosNfO])) .Or. !(Empty(acols[_nI][_nPosItO]))) .Or. ;
				Empty(acols[_nI][_nPosItO]) .And. ( !(Empty(acols[_nI][_nPosNfO])) .Or. !(Empty(acols[_nI][_nPosSeO]))) 
				
					aAdd( _aLogNfO , { acols[_nI][_nPosItn] , acols[_nI][_nPosCod] , 1 , "" , "" , "" } )
				
			//se estão preenchidos verifica se os dados são consistentes
			ElseIf !( Empty( acols[_nI][_nPosNfO] ) )
			
				BeginSql Alias _cAlias
					SELECT COUNT(1) QTDREG
					  FROM %Table:SD2% SD2
					 WHERE SD2.D_E_L_E_T_ = ' '
					   AND SD2.D2_FILIAL = %xFilial:SD2%
					   AND SD2.D2_CLIENTE = %exp:AllTrim(CA100FOR)%
					   AND SD2.D2_LOJA = %exp:AllTrim(CLOJA)%
					   AND SD2.D2_DOC = %exp:AllTrim(acols[_nI][_nPosNfO])%
					   AND SD2.D2_ITEM = %exp:AllTrim(acols[_nI][_nPosItO])%
					   AND SD2.D2_SERIE = %exp:AllTrim(acols[_nI][_nPosSeO])%
					   AND SD2.D2_COD = %exp:AllTrim(acols[_nI][_nPosCod])%
					   AND (SELECT SF2.F2_DOC
					          FROM %Table:SF2% SF2
					         WHERE SF2.D_E_L_E_T_ = ' '
					           AND SF2.F2_FILIAL = %xFilial:SF2%
					           AND SF2.F2_DOC = %exp:AllTrim(acols[_nI][_nPosNfO])%
					           AND SF2.F2_CLIENTE = %exp:AllTrim(CA100FOR)%
					           AND SF2.F2_LOJA = %exp:AllTrim(CLOJA)%
					           AND SF2.F2_EMISSAO = SD2.D2_EMISSAO
					           AND SF2.F2_SERIE = %exp:AllTrim(acols[_nI][_nPosSeO])%
					           AND ROWNUM = 1) = %exp:AllTrim(acols[_nI][_nPosNfO])%
					   AND (SD2.D2_TIPO = 'B' OR SD2.D2_TIPO = 'D')
				EndSql
				
				If (_cAlias)->QTDREG = 0
    	 			(_cAlias)->( DBCloseArea() )
    	 			
					//Se não encontrou procura na SD1
					BeginSql Alias _cAlias
						SELECT COUNT(1) QTDREG
						  FROM %Table:SD1% SD1
						 WHERE SD1.D_E_L_E_T_ = ' '
						   AND SD1.D1_FILIAL = %xFilial:SD1%
						   AND SD1.D1_FORNECE = %exp:AllTrim(CA100FOR)%
						   AND SD1.D1_LOJA = %exp:AllTrim(CLOJA)%
						   AND SD1.D1_DOC = %exp:AllTrim(acols[_nI][_nPosNfO])%
						   AND SD1.D1_ITEM = %exp:AllTrim(acols[_nI][_nPosItO])%
						   AND SD1.D1_SERIE = %exp:AllTrim(acols[_nI][_nPosSeO])%
						   AND SD1.D1_COD = %exp:AllTrim(acols[_nI][_nPosCod])%
						   AND (SELECT SF1.F1_STATUS
						          FROM %Table:SF1% SF1
						         WHERE SF1.D_E_L_E_T_ = ' '
						           AND SF1.F1_FILIAL = %xFilial:SF1%
						           AND SF1.F1_DOC = %exp:AllTrim(acols[_nI][_nPosNfO])%
						           AND SF1.F1_FORNECE = %exp:AllTrim(CA100FOR)%
						           AND SF1.F1_LOJA = %exp:AllTrim(CLOJA)%
						           AND SF1.F1_FORMUL <> 'S'
						           AND SF1.F1_DTDIGIT = SD1.D1_DTDIGIT
						           AND SF1.F1_SERIE = %exp:AllTrim(acols[_nI][_nPosSeO])%
						           AND ROWNUM = 1) = 'A'
						   AND SD1.D1_FORMUL <> 'S'
						   AND SD1.D_E_L_E_T_ = ' '
					EndSql
					
    	 			If (_cAlias)->QTDREG = 0
    	 				//se não encontrou nota com os dados 
    	 				aAdd(_aLogNfO, {	acols[_nI][_nPosItn], acols[_nI][_nPosCod], 2, AllTrim(acols[_nI][_nPosNfO]),;
											 AllTrim(acols[_nI][_nPosSeO]), AllTrim(acols[_nI][_nPosItO])   } )	
    	 			EndIf
    	 		EndIf	
				(_cAlias)->(DBCloseArea())
			EndIf
		EndIf
	Next _nI

	//se teve problemas haverá registros no array _aLogNfO
	If Len(_aLogNfO) > 0
		_cMens 	:= ""
		_nI 	:= 1
		
		For _nI := 1 to Len(_aLogNfo)
			If _aLogNfo[_nI][3] == 1
				_cMens += " Para o produto "+ _aLogNfo[_nI][2] +", item " + _aLogNfo[_nI][1] 
				_cMens += " não foram preenchidos todos os dados da nota de origem." + CHR(13)
			Else
				_cMens += " Para o produto "+ _aLogNfo[_nI][2] +", item " + _aLogNfo[_nI][1] 
				_cMens += " não foi encontrada a nota de origem referenciada.  "  + _aLogNfo[_nI][4] + "/" + _aLogNfo[_nI][5]+ "/" + _aLogNfo[_nI][6] + CHR(13) 
			EndIf
		Next _nI
	
		_nRet := aviso(	"Problema nos dados de nota de origem" , _cMens  + CHR(13) + "Deseja continuar mesmo assim?",{"Confirma","Cancela"},3 )
				
		If _nRet == 2
			_lRet := .F.
		EndIf
	EndIf
EndIf

Return( _lRet )
