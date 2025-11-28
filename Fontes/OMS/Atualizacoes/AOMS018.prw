/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
       Autor      |    Data    |                                             Motivo                                           
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz         | 03/11/2016 | Alterações na Query da rotina para aceitar o tipo de veículo RodoTrem. Chamado 16681.
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges      | 15/10/2019 | Removidos os Warning na compilação da release 12.1.25. Chamado 28346
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer     | 31/10/2022 | Chamado 41714. Acerto da numeracao do campo DA3_COD com a funcao Soma1()
===============================================================================================================================
*/

//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================
#Include "TOTVS.ch"
#Include "topconn.ch"
#Include "rwmake.ch"

/*
===============================================================================================================================
Programa--------: AOMS018
Autor-----------: Tiago Correa Castro
Data da Criacao-: 26/10/2008
===============================================================================================================================
Descrição-------: Codificacao Automatica do cadastro de Veiculos
					Gerar o campo DA3_COD de forma automatica, como base no campo DA3_I_TPVC
					Gatilho = DA3_I_TPVC SEQ: 001
					Forma da Codificacao: CAR + Sequencial --> Para Tipo de Veiculo: Carreta
					CAM + Sequencial --> Para Tipo de Veiculo: Caminhao
					BIT + Sequencial --> Para Tipo de Veiculo: Bi-Trem
					UTI + Sequencial --> Para Tipo de Veiculo: Veiculos Utilitarios
===============================================================================================================================
Parametros------: _pcTipo = Devera ser passado o conteudo do campo DA3_I_TPVC
===============================================================================================================================
Retorno---------: _cRetorno = Retorna codigo para cadastro de Veiculo
===============================================================================================================================
*/
User Function AOMS018(_pcTipo)

	Local _aArea    := FWGetArea()
	Local _cQuery   := ""
	Local _cRetorno := ""
	Local _cCodigo  := ""

   
	_cQuery := " SELECT MAX(DA3_COD) AS CODIGO"
	_cQuery += " FROM " + RetSqlName("DA3")
	If AllTrim(_pcTipo) == "1"
		_cQuery += " WHERE SubStr(DA3_COD,1,3) = 'CAR' "
	ElseIf AllTrim(_pcTipo) == "2"
		_cQuery += " WHERE SubStr(DA3_COD,1,3) = 'CAM' "
	ElseIf AllTrim(_pcTipo) == "3"
		_cQuery += " WHERE SubStr(DA3_COD,1,3) = 'BIT' "
	ElseIf AllTrim(_pcTipo) == "4"
		_cQuery += " WHERE SubStr(DA3_COD,1,3) = 'UTI' "   
	ElseIf AllTrim(_pcTipo) == "5"
		_cQuery += " WHERE SubStr(DA3_COD,1,3) = 'ROD' "	
	EndIf
	_cQuery += " AND DA3_FILIAL = '"+xFilial("DA3")+"' AND "+  RetSqlName("DA3")+".D_E_L_E_T_ = ' '"
	
	TcQuery _cQuery New Alias "QRY"
	
	DBSelectArea("QRY")
	DBGoTop()
	
	_cCodigo := QRY->CODIGO
	
	DBSelectArea("QRY")
	QRY->(DBCloseArea())
	
	// Se _cCodigo For vazio, entao devera ser gerado um codigo sequencial para retorno.
	If AllTrim(_cCodigo) == ""
		If AllTrim(_pcTipo) == "1"
			_cCodigo := "CAR00001"
			While !MayIUseCode("DA3_COD"+xFilial("DA3")+_cCodigo)  //verifica se esta na memoria, sendo usado
				_cCodigo := "CAR" + StrZero((Val(Right(_cCodigo,5))+1),5)// busca o proximo numero disponivel 
			EndDo                                           
		ElseIf AllTrim(_pcTipo) == "2"
			_cCodigo := "CAM00001"
			While !MayIUseCode("DA3_COD"+xFilial("DA3")+_cCodigo)  //verifica se esta na memoria, sendo usado
				_cCodigo := "CAM" + StrZero((Val(Right(_cCodigo,5))+1),5)// busca o proximo numero disponivel 
			EndDo                                           
		ElseIf AllTrim(_pcTipo) == "3"
			_cCodigo := "BIT00001"
			While !MayIUseCode("DA3_COD"+xFilial("DA3")+_cCodigo)  //verifica se esta na memoria, sendo usado
				_cCodigo := "BIT" + StrZero((Val(Right(_cCodigo,5))+1),5)// busca o proximo numero disponivel 
			EndDo                                           
		ElseIf AllTrim(_pcTipo) == "4"
			_cCodigo := "UTI00001"	    
			While !MayIUseCode("DA3_COD"+xFilial("DA3")+_cCodigo)  //verifica se esta na memoria, sendo usado
				_cCodigo := "UTI" + StrZero((Val(Right(_cCodigo,5))+1),5)// busca o proximo numero disponivel 
			EndDo                                           
		ElseIf AllTrim(_pcTipo) == "5"
			_cCodigo := "ROD00001"	    
			While !MayIUseCode("DA3_COD"+xFilial("DA3")+_cCodigo)  //verifica se esta na memoria, sendo usado
				_cCodigo := "ROD" + StrZero((Val(Right(_cCodigo,5))+1),5)// busca o proximo numero disponivel 
			EndDo                                           			
   	    EndIf
	Else
	    _cCodigo:=LEFT(_cCodigo,3)+Soma1(Right(_cCodigo,5))
		While !MayIUseCode("DA3_COD"+xFilial("DA3")+_cCodigo)  //verifica se esta na memoria, sendo usado
		   _cCodigo:=LEFT(_cCodigo,3)+Soma1(Right(_cCodigo,5))// busca o proximo numero disponivel 
		EndDo                                           
	EndIf
/*		
	ElseIf AllTrim(_cCodigo) <> "" .And. AllTrim(_pcTipo) == "1"
		_cCodigo := "CAR" + StrZero((Val(Right(_cCodigo,5))+1),5)
		While !MayIUseCode("DA3_COD"+xFilial("DA3")+_cCodigo)  //verifica se esta na memoria, sendo usado
			_cCodigo := "CAR" + StrZero((Val(Right(_cCodigo,5))+1),5)// busca o proximo numero disponivel 
		EndDo                                           
	ElseIf AllTrim(_cCodigo) <> "" .And. AllTrim(_pcTipo) == "2"
		_cCodigo := "CAM" + StrZero((Val(Right(_cCodigo,5))+1),5)
		While !MayIUseCode("DA3_COD"+xFilial("DA3")+_cCodigo)  //verifica se esta na memoria, sendo usado
			_cCodigo := "CAM" + StrZero((Val(Right(_cCodigo,5))+1),5)// busca o proximo numero disponivel 
		EndDo                                           
	ElseIf AllTrim(_cCodigo) <> "" .And. AllTrim(_pcTipo) == "3"
		_cCodigo := "BIT" + StrZero((Val(Right(_cCodigo,5))+1),5)
		While !MayIUseCode("DA3_COD"+xFilial("DA3")+_cCodigo)  //verifica se esta na memoria, sendo usado
			_cCodigo := "BIT" + StrZero((Val(Right(_cCodigo,5))+1),5)// busca o proximo numero disponivel 
		EndDo                                           
	ElseIf AllTrim(_cCodigo) <> "" .And. AllTrim(_pcTipo) == "4"
		_cCodigo := "UTI" + StrZero((Val(Right(_cCodigo,5))+1),5)
		While !MayIUseCode("DA3_COD"+xFilial("DA3")+_cCodigo)  //verifica se esta na memoria, sendo usado
			_cCodigo := "UTI" + StrZero((Val(Right(_cCodigo,5))+1),5)// busca o proximo numero disponivel 
		EndDo                                           
    ElseIf AllTrim(_cCodigo) <> "" .And. AllTrim(_pcTipo) == "5"
		_cCodigo := "ROD" + StrZero((Val(Right(_cCodigo,5))+1),5)
		While !MayIUseCode("DA3_COD"+xFilial("DA3")+_cCodigo)  //verifica se esta na memoria, sendo usado
			_cCodigo := "ROD" + StrZero((Val(Right(_cCodigo,5))+1),5)// busca o proximo numero disponivel 
		EndDo                                           
	EndIf*/
	
	_cRetorno := _cCodigo    

	FWRestArea(_aArea)
Return(_cRetorno)
