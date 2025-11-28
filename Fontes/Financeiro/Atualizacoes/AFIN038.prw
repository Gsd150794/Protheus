/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: AFIN038
Autor-------------: Antonio Neves
Data da Criacao---: 05/08/2010
Descrição---------: Faz controle sequencial dentro do arquivo cnab dos bancos Itau e Bradesco Modelo 2 - Chamado 49049
Parametros--------: cTipo = Tipo de Incremento.
Retorno-----------: _nRetNum = Numero CNAB atualizado.
===============================================================================================================================
*/
User Function AFIN038(cTipo)
Local _nRetNum:= 0

//===========================================
// Efetua o incremento do valor do Titulo
//===========================================
If cTipo == 1 // ITAU
	
	_nRetNum:=++(GetMv("IT_SEQITC2"))
	PutMV("IT_SEQITC2",_nRetNum)
	_nRetNum:= StrZero(_nRetNum,5)
	
ElseIf cTipo == 2 // Bradesco
	
	_nRetNum:=++(GetMv("IT_SEQBDC2"))
	PutMV("IT_SEQBDC2",_nRetNum)
	_nRetNum:= StrZero(_nRetNum,5)
	
ElseIf cTipo == 3 //Itau

	PutMV("IT_SEQITC2",0)
	_nRetNum:= ""
	
ElseIf cTipo == 4 // Bradesco

	PutMV("IT_SEQBDC2",0)
	_nRetNum:= ""

EndIf

Return _nRetNum
