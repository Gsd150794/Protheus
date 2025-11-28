/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |30/03/2023| Chamado 43439. Posicionado no recno do sc7 - penultima COLUNA do acols (Len(aCols[n])-1).
Julio Paz     |26/02/2025| Chamado 49465. Validar a data de faturamento apenas para itens com saldo: (C7_QUANT-C7_QUJE) > 0. (MT120LOK002)
Lucas Borges  |19/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MT120LOK
Autor-------------: Renato de Morcerf
Data da Criacao---: 03/02/2009
Descrição---------: Ponto de entrada na validação de LINHA dos pedidos de compras
Parametros--------: _lVldDIf (.T./.F.)
Retorno-----------: _lRet (.T./.F.): define se pode confirmar a validação de linha dos pedidos de compras
===============================================================================================================================
*/
User Function MT120LOK(_lVldDif)
                                                                                         
Local _aArea		:= FWGetArea()
Local _nPa			:= 0
Local _cPl 			:= ""
Local _nPa2  		:= 0
Local _nPl2 		:= 0
Local _lRet 		:= .T.   
Local _nPosNomFo	:= 0
Local _nPosDtFat	:= 0
Local _nPosdescd	:= 0
Local _nDtLimFt		:= SuperGetMV("IT_DTLIMFT",.F.,180)	// Limite de dias para data de Faturamento
Local _dLimFt		:= Date() + _nDtLimFt					// Data limite maximo para data de Faturamento
Local _dLimAnt		:= Date() - _nDtLimFt					// Data limite minimo para data de Faturamento
Local _cQuery		:= ""
Local _cNwAlia		:= GetNextAlias()
Local _nPerc		:= IIf(_lVldDif, SuperGetMV("IT_PERCAVS",.F.,10),0)
Local _nDif			:= 0
Local _nPosAP		:= 0

Default _lVldDif	:= .F.

If cAplic == "S"
	_nPosAP := aScan( aHeader, {|x| AllTrim(x[2]) == "C7_I_USOD"})
	aCols[N][_nPosAp] := "N"
EndIf

If !_lVldDif
	_nPa      := aScan( aHeader, { |x| AllTrim(x[2])== "C7_PRODUTO" } )  
	_nPosNomFo:= aScan( aHeader, { |x| AllTrim(x[2])== "C7_I_NFORN" } ) 
	_nPosDtFat:= aScan( aHeader, { |x| AllTrim(x[2])== "C7_I_DTFAT" } ) 
	_cPl 	:= 	acols[n,_nPa]
		
	If aCols[n][Len(aHeader)+1] == .F. //Linha nao Deletada
		If SubStr(_cPl,1,4) = "0006"
			_nPa2  :=  aScan( aHeader, { |x| AllTrim(x[2])== "C7_QTSEGUM" } )
			_nPl2 := acols[n,_nPa2]
			If _nPl2 = 0
				U_ITMsg("Segunda Unidade de Medida Vazio, Para esse produto e obrigatorio o preenchimento da segunda unidade de medida (Peças) ", "MT120LOK001",; 
							"Favor preencher a segunda unidade de medida (Peças)!!",1 )
				_lRet := .F.
			EndIf
		EndIf
	EndIf
			
	//=========================================================================
	//Caso nao encontre nenhum problema na validacao acima         
	//eh inserida a descricao do fornecedor fornecido no pedido de 
	//compra.                                                      
	//=========================================================================
	
	If _lRet

		_nPosDtFat         := aScan( aHeader, { |x| AllTrim(x[2])== "C7_I_DTFAT" } )
		_nPosdescd         := aScan( aHeader, { |x| AllTrim(x[2])== "C7_I_DESCD" } )
		aCols[n,_nPosNomFo]:= AllTrim(Posicione("SA2",1,xFilial("SA2") + CA120FORN + CA120LOJ,"SA2->A2_NOME") )  
		aCols[n,_nPosdescd]:= Posicione("SB1",1,xFilial("SB1")+AllTrim(acols[n,_nPa]),"B1_I_DESCD")                                                                       
          
		If !Empty(aCols[n,_nPosDtFat])

			If Altera .And. aCols[n, Len(aCols[n])-1  ] > 0 //RECNO DO SC7 

	           SC7->(DBGoTo(aCols[n, Len(aCols[n])-1  ]))//POSICIONA NO RECNO DO SC7 - PENULTIMA COLUNA DO ACOLS (Len(aCols[n])-1)
		
				If _lRet 							   
					If (SC7->C7_QUJE >= SC7->C7_QUANT) .And. SC7->C7_I_DTFAT <> acols[n,_nPosDtFat]
						Help(" ",1,"A120ALTPC")
						aCols[n,_nPosDtFat]:= SC7->C7_I_DTFAT
						_lRet := .F.
					EndIf
			
					If SC7->C7_RESIDUO == "S" .And. SC7->C7_I_DTFAT <> acols[n,_nPosDtFat]
						Help(" ",1,"A120RESID")
						aCols[n,_nPosDtFat]:= SC7->C7_I_DTFAT
						_lRet := .F.
					EndIf
					If (SC7->C7_QTDACLA + SC7->C7_QUJE) > SC7->C7_QUANT .And. SC7->C7_I_DTFAT <> acols[n,_nPosDtFat]
						Help(" ",1,"A120ALT")
						aCols[n,_nPosDtFat]:= SC7->C7_I_DTFAT
						_lRet := .F.
					EndIf				
				EndIf
			EndIf
			
			If _lRet .And. Inclui
    		   If aCols[n,_nPosDtFat] > _dLimFt .Or. aCols[n,_nPosDtFat] < _dLimAnt
				  U_ITMsg("Data de Faturamento Informada Invalida! (" + DToC(aCols[n,_nPosDtFat]) + ").", "MT120LOK002",; 
				          "Favor informar uma data maior ou igual a: " + DToC(_dLimAnt) + " ou menor ou igual a " + DToC(_dLimFt) + ".",1 )
				  
				  _lRet := .F.
			   EndIf
    		EndIf
			
            If _lRet .And. Altera .And. aCols[n, Len(aCols[n])-1  ] > 0 //RECNO DO SC7 

	           SC7->(DBGoTo(aCols[n, Len(aCols[n])-1  ]))//POSICIONA NO RECNO DO SC7 - PENULTIMA COLUNA DO ACOLS (Len(aCols[n])-1)
		
			   If (SC7->C7_QUANT - SC7->C7_QUJE) > 0 
      		      If aCols[n,_nPosDtFat] > _dLimFt .Or. aCols[n,_nPosDtFat] < _dLimAnt
				     U_ITMsg("Data de Faturamento Informada Invalida! (" + DToC(aCols[n,_nPosDtFat]) + ").", "MT120LOK003",; 
				          "Favor informar uma data maior ou igual a: " + DToC(_dLimAnt) + " ou menor ou igual a " + DToC(_dLimFt) + ".",1 )
				  
				     _lRet := .F.
			      EndIf
    		   EndIf
            EndIf
		EndIf	 
	EndIf
			
	FWRestArea(_aArea)
Else
	_cQuery += "SELECT C7_PRODUTO, C7_NUM, C7_QUANT, C7_PRECO, C7_EMISSAO, C7_FORNECE, C7_LOJA FROM " + RetSqlName("SC7") + " C7 "
	_cQuery += " WHERE D_E_L_E_T_ = ' ' "
	_cQuery += " AND C7_PRODUTO = '" + AllTrim(aCols[n][2]) + "' "
	_cQuery += " AND C7_FILIAL = '" + cFilant +  "' "
	_cQuery += " AND R_E_C_N_O_ = (SELECT MAX(R_E_C_N_O_) FROM " + RetSqlName("SC7") + " WHERE D_E_L_E_T_ = ' ' AND C7_FILIAL = '" +cFilAnt+ "' "
	_cQuery += " AND C7_PRODUTO = '" + AllTrim(aCols[n][2]) + "') "
	_cQuery := ChangeQuery(_cQuery)
	MPSysOpenQuery(_cQuery,_cNwAlia)

	_nDIf := Round(((aCols[n][7]/(_cNwAlia)->C7_PRECO)-1)*100,2) 

	If _nDIf >= _nPerc .Or. _nDIf <= (_nPerc * -1)
		U_ITMsg("Atenção! O último preço de compra para este produto teve uma variação de " + cValToChar(_nDif) + "% "+CRLF+;
				"Data da última compra: " +CVALTOCHAR(DAY(SToD((_cNwAlia)->C7_EMISSAO)))+"/"+StrZero(MONTH(SToD((_cNwAlia)->C7_EMISSAO)),2)+ "/" + CVALTOCHAR(Year(SToD((_cNwAlia)->C7_EMISSAO))) +CRLF+;
				"Último valor praticado: R$ " +cValToChar((_cNwAlia)->C7_PRECO)+CRLF+;
				"PC - "+ (_cNwAlia)->C7_NUM + CRLF+;
				Posicione("SA2",1,xFilial("SA2")+AllTrim((_cNwAlia)->C7_FORNECE)+AllTrim((_cNwAlia)->C7_LOJA), "A2_NOME"), "Atenção!",,3)
	EndIf

EndIf

Return _lRet
