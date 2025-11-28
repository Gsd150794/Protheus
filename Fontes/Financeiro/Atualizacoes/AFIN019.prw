/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
 Julio Paz    |08/05/2018| Chamado 24726. Padronização dos cabeçalhos dos fontes e funções do módulo financeiro.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: AFIN019
Autor-------------: Fabiano
Data da Criacao---: 05/08/2010
Descrição---------: Faz controle sequencial dentro do arquivo cnab do banco do brasil bb_cob.2re.  
Parametros--------: cTipo = Tipo de Incremento.
Retorno-----------: _nRetNum = Numero CNAB atualizado.
===============================================================================================================================
*/
User Function AFIN019(cTipo)
Local _nRetNum:= 0

//===========================================
// Efetua o incremento do valor do Titulo
//===========================================
If cTipo == 1
	
	_nRetNum:=++(GetMv("IT_SEQCNB2"))
	PutMV("IT_SEQCNB2",_nRetNum)
	_nRetNum:= StrZero(_nRetNum,5)
	
Else
	
	PutMV("IT_SEQCNB2",0)
	_nRetNum:= ""
	
EndIf

Return _nRetNum
