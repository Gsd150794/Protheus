/*
==============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
==============================================================================================================================
Josué Danich      | 31/07/2018 | Eliminada opção de senha para permitir continuar sem regra de comissão - Chamado 25555  
------------------------------------------------------------------------------------------------------------------------------
Josué Danich      | 04/01/2018 | Universalização da rotina para ser chamada pelo webservice - Chamado 27138                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges      | 15/10/2019 | Removidos os Warning na compilação da release 12.1.25. Chamado 28346
-------------------------------------------------------------------------------------------------------------------------------
Jerry             | 21/12/2020 | Ajustar regra que busca Comissão Válida por Prod x Vend. Chamado 34931
-------------------------------------------------------------------------------------------------------------------------------
 Alex Wallauer    | 29/12/2020 | Retirada da chamada da função PswRet(1)[1][1] - Chamado 35108
-------------------------------------------------------------------------------------------------------------------------------------
 Alex Wallauer    | 24/03/2022 | Alteracao da função U_ITMsg() para a função U_MT_ITMSG(). Chamado 38883
==============================================================================================================================
*/

//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================
#Include "RwMake.ch"
#Include "TopConn.ch"
#Include "TOTVS.ch"    

/*
================================================================================================================================
Programa----------: AOMS049
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 15/03/2011
================================================================================================================================
Descrição---------: Validação de regra de comissão e contrato de cliente chamada pelos PE´s M410TOK/AOMS074
================================================================================================================================
Parametros--------: _cVendedor - vendedor do pedido
					_lshow - mostra mensagens
					_ccliente - cliente do pedido
					_clojacli - loja do pedido
================================================================================================================================
Retorno-----------: _lRet - Se tem contrato e regra válida ou não
================================================================================================================================
*/
User Function AOMS049(_cVendedor, _lshow, _ccliente,_clojacli,_cRede)

Local _nPosProd		:= aScan(aHeader,{|x| AllTrim(Upper(x[2])) == "C6_PRODUTO" })
Local _nPosTES		:= aScan(aHeader,{|x| AllTrim(Upper(x[2])) == "C6_TES"     })  
Local _nPosLibPe	:= aScan(aHeader,{|x| AllTrim(Upper(x[2])) == 'C6_I_LIBPR' })

Local _cTes			:= ""
Local _cFiltro		:= "%" 	
Local _cAlias		:= ""
Local _lRet			:= .T.    
Local _lPosRegra	:= .F.

Local _aArea		:= FWGetArea()	  

Default _cVendedor	:= M->C5_VEND1
Default _lshow 	    := .T.
Default _ccliente   := M->C5_CLIENTE
Default _clojacli   := M->C5_LOJACLI 
Default _cRede      := M->C5_I_GRPVE

//Private _cMatUsu	:= PswRet(1)[1][1] //Retorna o codigo do usuario logado

If !aCols[n,Len(aHeader)+1]    
                        	 
	/*
	//==================================================================
	//O produto citado abaixo nao entrara nas condicoes para averiguar
	//se um produto esta sem regra de comissao.                       
	//==================================================================
	*/
	If AllTrim(aCols[n,_nPosProd]) <> '1003     16'  .And.   Posicione("SB1",1,xFilial("SB1")+AllTrim(aCols[n,_nPosProd]),"B1_GRUPO") <> '0813' //Não verifica pallets                                                                  

		_cTes     := Posicione("SF4",1,xFilial("SF4") + aCols[n,_nPosTES],"F4_DUPLIC")     
		
		/* 
		//===============================================================
		//Verifica se o usuario informou o cliente e se a TES informada
		//para a linha corrente do pedido de venda gera financeiro.    
		//===============================================================
		*/
		If Len(AllTrim(_cVendedor)) > 0 .And. _cTes == 'S' .And. Len(AllTrim(aCols[n,_nPosLibPe])) == 0 
		
			_cAlias:= GetNextAlias()
			
			/*
			//==============================================================================
			//Verifica se existe uma regra de comissao para o vendedor e produto informado
			//==============================================================================
			*/
 	
			_cFiltro += " AND ZAE_VEND = '" + _cVendedor         + "'"
			_cFiltro += "%"

			BeginSql alias _cAlias 
				SELECT
			          ZAE_PROD
				FROM
				      %Table:ZAE%
				WHERE
				      D_E_L_E_T_ = ' '  
					  
					  %exp:_cFiltro%	
		    EndSql  
		    
		    DBSelectArea(_cAlias) 
		    (_cAlias)->(DBGoTop())      
		    
		    If (_cAlias)->(!Eof())    
		    
		    	While (_cAlias)->(!Eof())
		    	     
		    		If AllTrim((_cAlias)->ZAE_PROD) == AllTrim(aCols[n,_nPosProd])
		    		 
		    			_lPosRegra:= .T.
		    			Exit
		    		
		    		EndIf
		    	
		    	(_cAlias)->(DBSkip())
		    	EndDo
		    
				If !_lPosRegra 
				    	
				    	_cMens := "O produto localizado no item: " + AllTrim(cValToChar(N)) + " ("+AllTrim(cValToChar(aCols[N,_nPosProd]))
				    	_cMens += ") esta sem regra de comissão amarrada para o vendedor: " + _cVendedor +Chr(13)+Chr(10)
				    	
				    	If _lshow
				    		U_MT_ITMSG(_cMens,"Atenção", "Contate o depto responsável pelo cadastro de regras de comissão",1)
						Else
						   If Type("_cAOMS074Vld") = "C" 
                              _cAOMS074Vld += _cMens
                           EndIf
				    	EndIf
				    	 
						_lRet := .F.
				    	   
				Else
				
					//Validação de contrato do cliente
					_lRet := AOMS049C(_lshow,_ccliente,_clojacli)
		    
				EndIf	
				
		    
		    EndIf
		     
		    DBSelectArea(_cAlias) 
		    (_cAlias)->(DBCloseArea())
		
		EndIf   
	
	EndIf


EndIf

FWRestArea(_aArea)	

Return _lRet

/*
===============================================================================================================================
Programa----------: AOMS049C
Autor-------------: Josué Danich Prestes
Data da Criacao---: 31/07/2018
===============================================================================================================================
Descrição---------: Validação de contrato do cliente
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: _lRet - Se tem contrato válido ou não
===============================================================================================================================
*/
Static Function AOMS049C(_lshow,_ccliente,_clojacli)

Local _lRet := .T.
Local _lAchou := .F.
Local _ccontrato := ""
Local _nPosProd		:= aScan(aHeader,{|x| AllTrim(Upper(x[2])) == "C6_PRODUTO" })
Local _lCliente		:= .F.
Local _cQuery		:= ""
Local _cQry			:= ""

Default _lshow := .T.
Default _ccliente := M->C5_CLIENTE
Default _clojacli := M->C5_LOJACLI
				
SA1->(DBSetOrder(1))
SA1->(DBSeek(xFilial("SA1") + _ccliente + _clojacli ))

//=======================================================//
// Procuro no cabeçalho se há contrato no cliente e loja //
//=======================================================//
_cQry := "SELECT ZAZ_COD AS CODIGO "
_cQry += "FROM " + RetSqlName("ZAZ") + " ZAZ "
_cQry += "WHERE ZAZ_FILIAL = '" + xFilial("ZAZ") + "' "
_cQry += "  AND ZAZ_CLIENT = '" + SA1->A1_COD + "' "
_cQry += "  AND ZAZ_LOJA = '" + SA1->A1_LOJA + "' "
_cQry += "  AND ZAZ_STATUS = 'S' "
_cQry += "  AND ZAZ_MSBLQL = '2' "
_cQry += "  AND ZAZ_DTINI <= '" + DToS(dDataBase) + "' AND ZAZ_DTFIM >= '" + DToS(dDataBase) + "' "
_cQry += "  AND D_E_L_E_T_ = ' ' "

dbUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQry ) , "TRBCLI" , .T., .F. )

DBSelectArea("TRBCLI")
TRBCLI->(DBGoTop())

If !TRBCLI->(Eof())
	
	_lCliente	:= .T.
	_cContrato	:= TRBCLI->CODIGO

	_cQuery := "SELECT ZB0_COD AS CODIGO "
	_cQuery += "FROM " + RetSqlName("ZB0") + " ZB0 "
	_cQuery += "WHERE ZB0_FILIAL = '" + xFilial("ZB0") + "' "
	_cQuery += "  AND ZB0_COD = '" + _cContrato + "' "
	_cQuery += "  AND ZB0_CLIENT = ' ' "
	_cQuery += "  AND ZB0_LOJA = ' ' "
	_cQuery += "  AND ZB0_SB1COD = '" + AllTrim(aCols[n,_nPosProd]) + "' "
	_cQuery += "  AND ZB0_EST = '" + SA1->A1_EST + "' "
	_cQuery += "  AND D_E_L_E_T_ = ' ' "

	dbUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQuery ) , "TRBPRO" , .T., .F. )

	DBSelectArea("TRBPRO")
	TRBPRO->(DBGoTop())

	If TRBPRO->(Eof())
	
		_cQryAux := "SELECT ZB0_COD AS CODIGO "
		_cQryAux += "FROM " + RetSqlName("ZB0") + " ZB0 "
		_cQryAux += "WHERE ZB0_FILIAL = '" + xFilial("ZB0") + "' "
		_cQryAux += "  AND ZB0_COD = '" + _cContrato + "' "
		_cQryAux += "  AND ZB0_SB1COD = '" + AllTrim(aCols[n,_nPosProd]) + "' "
		_cQryAux += "  AND ZB0_CLIENT = ' ' "
		_cQryAux += "  AND ZB0_LOJA = ' ' "
		_cQryAux += "  AND D_E_L_E_T_ = ' ' "

		dbUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQryAux ) , "TMPPRO" , .T., .F. )

		DBSelectArea("TMPPRO")
		TMPPRO->(DBGoTop())

		If !TMPPRO->(Eof())
			_lAchou := .T.
		EndIf

		DBSelectArea("TMPPRO")
		TMPPRO->(DBCloseArea())
	
	Else
		
		_lAchou := .T.
	
	EndIf

	DBSelectArea("TRBPRO")
	TRBPRO->(DBCloseArea())

EndIf

DBSelectArea("TRBCLI")
TRBCLI->(DBCloseArea())

If !_lAchou

	//=============================================//
	// Procuro no cabeçalho se há contrato na rede //
	//=============================================//
	_cQry := "SELECT ZAZ_COD AS CODIGO "
	_cQry += "FROM " + RetSqlName("ZAZ") + " ZAZ "
	_cQry += "WHERE ZAZ_FILIAL = '" + xFilial("ZAZ") + "' "
	_cQry += "  AND ZAZ_GRPVEN = '" + SA1->A1_GRPVEN + "' "
	_cQry += "  AND ZAZ_CLIENT = ' ' "
	_cQry += "  AND ZAZ_LOJA = ' ' "
	_cQry += "  AND ZAZ_STATUS = 'S' "
	_cQry += "  AND ZAZ_MSBLQL = '2' "
	_cQry += "  AND ZAZ_DTINI <= '" + DToS(dDataBase) + "' AND ZAZ_DTFIM >= '" + DToS(dDataBase) + "' "
	_cQry += "  AND D_E_L_E_T_ = ' ' "

	dbUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQry ) , "TRBCLI" , .T., .F. )

	DBSelectArea("TRBCLI")
	TRBCLI->(DBGoTop())

	If !TRBCLI->(Eof())

		_lCliente	:= .T.
		_cContrato	:= TRBCLI->CODIGO
		
		_cQuery := "SELECT ZB0_COD AS CODIGO "
		_cQuery += "FROM " + RetSqlName("ZB0") + " ZB0 "
		_cQuery += "WHERE ZB0_FILIAL = '" + xFilial("ZB0") + "' "
		_cQuery += "  AND ZB0_COD = '" + _cContrato + "' "
		_cQuery += "  AND ZB0_SB1COD = '" + AllTrim(aCols[n,_nPosProd]) + "' "
		_cQuery += "  AND ZB0_CLIENT = '" + SA1->A1_COD + "' "
		_cQuery += "  AND ZB0_LOJA = '" + SA1->A1_LOJA + "' "
		_cQuery += "  AND ZB0_EST = '" + SA1->A1_EST + "' "
		_cQuery += "  AND D_E_L_E_T_ = ' ' "

		dbUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQuery ) , "TRBPRO" , .T., .F. )
	
		DBSelectArea("TRBPRO")
		TRBPRO->(DBGoTop())

		If TRBPRO->(Eof())
					
			_cQryAux := "SELECT ZB0_COD AS CODIGO "
			_cQryAux += "FROM " + RetSqlName("ZB0") + " ZB0 "
			_cQryAux += "WHERE ZB0_FILIAL = '" + xFilial("ZB0") + "' "
			_cQryAux += "  AND ZB0_COD = '" + _cContrato + "' "
			_cQryAux += "  AND ZB0_SB1COD = '" + AllTrim(aCols[n,_nPosProd]) + "' "
			_cQryAux += "  AND ZB0_CLIENT = '" + SA1->A1_COD + "' "
			_cQryAux += "  AND ZB0_LOJA = '" + SA1->A1_LOJA + "' "
			_cQryAux += "  AND ZB0_EST = ' ' "
			_cQryAux += "  AND D_E_L_E_T_ = ' ' "

			dbUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQryAux ) , "TMPPRO" , .T., .F. )

			DBSelectArea("TMPPRO")
			TMPPRO->(DBGoTop())

			If TMPPRO->(Eof())
		
				_cQryAu1 := "SELECT ZB0_COD AS CODIGO "
				_cQryAu1 += "FROM " + RetSqlName("ZB0") + " ZB0 "
				_cQryAu1 += "WHERE ZB0_FILIAL = '" + xFilial("ZB0") + "' "
				_cQryAu1 += "  AND ZB0_COD = '" + _cContrato + "' "
				_cQryAu1 += "  AND ZB0_SB1COD = '" + AllTrim(aCols[n,_nPosProd]) + "' "
				_cQryAu1 += "  AND ZB0_CLIENT = '" + SA1->A1_COD + "' "
				_cQryAu1 += "  AND ZB0_LOJA = ' ' "
				_cQryAu1 += "  AND ZB0_EST = '" + SA1->A1_EST + "' "
				_cQryAu1 += "  AND D_E_L_E_T_ = ' ' "

				dbUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQryAu1 ) , "TMPPR1" , .T., .F. )

				DBSelectArea("TMPPR1")
				TMPPR1->(DBGoTop())

				If TMPPR1->(Eof())
			
					_cQryAu2 := "SELECT ZB0_COD AS CODIGO "
					_cQryAu2 += "FROM " + RetSqlName("ZB0") + " ZB0 "
					_cQryAu2 += "WHERE ZB0_FILIAL = '" + xFilial("ZB0") + "' "
					_cQryAu2 += "  AND ZB0_COD = '" + _cContrato + "' "
					_cQryAu2 += "  AND ZB0_SB1COD = '" + AllTrim(aCols[n,_nPosProd]) + "' "
					_cQryAu2 += "  AND ZB0_CLIENT = '" + SA1->A1_COD + "' "
					_cQryAu2 += "  AND ZB0_LOJA = ' ' "
					_cQryAu2 += "  AND ZB0_EST = ' ' "
					_cQryAu2 += "  AND D_E_L_E_T_ = ' ' "

					dbUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQryAu2 ) , "TMPPR2" , .T., .F. )

					DBSelectArea("TMPPR2")
					TMPPR2->(DBGoTop())

					If TMPPR2->(Eof())
				
						_cQryAu3 := "SELECT ZB0_COD AS CODIGO "
						_cQryAu3 += "FROM " + RetSqlName("ZB0") + " ZB0 "
						_cQryAu3 += "WHERE ZB0_FILIAL = '" + xFilial("ZB0") + "' "
						_cQryAu3 += "  AND ZB0_COD = '" + _cContrato + "' "
						_cQryAu3 += "  AND ZB0_SB1COD = '" + AllTrim(aCols[n,_nPosProd]) + "' "
						_cQryAu3 += "  AND ZB0_CLIENT = ' ' "
						_cQryAu3 += "  AND ZB0_LOJA = ' ' "
						_cQryAu3 += "  AND ZB0_EST = '" + SA1->A1_EST + "' "
						_cQryAu3 += "  AND D_E_L_E_T_ = ' ' "
	
						dbUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQryAu3 ) , "TMPPR3" , .T., .F. )
	
						DBSelectArea("TMPPR3")
						TMPPR3->(DBGoTop())
	
						If TMPPR3->(Eof())
					
							_cQryAu4 := "SELECT ZB0_COD AS CODIGO "
							_cQryAu4 += "FROM " + RetSqlName("ZB0") + " ZB0 "
							_cQryAu4 += "WHERE ZB0_FILIAL = '" + xFilial("ZB0") + "' "
							_cQryAu4 += "  AND ZB0_COD = '" + _cContrato + "' "
							_cQryAu4 += "  AND ZB0_SB1COD = '" + AllTrim(aCols[n,_nPosProd]) + "' "
							_cQryAu4 += "  AND ZB0_CLIENT = ' ' "
							_cQryAu4 += "  AND ZB0_LOJA = ' ' "
							_cQryAu4 += "  AND ZB0_EST = ' ' "
							_cQryAu4 += "  AND D_E_L_E_T_ = ' ' "
		
							dbUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQryAu4 ) , "TMPPR4" , .T., .F. )
		
							DBSelectArea("TMPPR4")
							TMPPR4->(DBGoTop())

							If !TMPPR4->(Eof())
			
								_lAchou := .T.
			
							EndIf
		
							DBSelectArea("TMPPR4")
							TMPPR4->(DBCloseArea())
					
						Else
			
							_lAchou := .T.
					
						EndIf
	
						DBSelectArea("TMPPR3")
						TMPPR3->(DBCloseArea())
					
					Else
				
						_lAchou := .T.
					
					EndIf

					DBSelectArea("TMPPR2")
					TMPPR2->(DBCloseArea())
			
				Else
			
					_lAchou := .T.
			
				EndIf

				DBSelectArea("TMPPR1")
				TMPPR1->(DBCloseArea())
		
			Else
		
				_lAchou := .T.
		
			EndIf

			DBSelectArea("TMPPRO")
			TMPPRO->(DBCloseArea())
		
		Else
		
			_lAchou := .T.
	
		EndIf

		DBSelectArea("TRBPRO")
		TRBPRO->(DBCloseArea())

	EndIf

	DBSelectArea("TRBCLI")
	TRBCLI->(DBCloseArea())
					
EndIf
				
				
If !_lAchou .And. !Empty(_cContrato) .And.  Posicione("SB1",1,xFilial("SB1")+AllTrim(aCols[n,_nPosProd]),"B1_TIPO") = 'PA' //Só para produtos acabados
				
	U_MT_ITMSG( "O produto informado [" + AllTrim(aCols[n,_nPosProd]) + "] não existe na regra de contrato do cliente."	,"Atenção",;
	"Contrato No. [" + _cContrato + "]. Por favor contactar o departamento financeiro.",1	 					)
	_lRet := .F.
				
EndIf
				
Return _lRet
