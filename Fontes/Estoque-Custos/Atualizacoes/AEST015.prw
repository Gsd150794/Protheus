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
Programa----------: AEST015
Autor-------------: André Lisboa
Data da Criacao---: 11/09/2017
Descricao---------: Validar permissão de acesso a rotina de solicitação ao armazém conforme cadastro na tabela ZZL
Parametros--------:
Retorno-----------: T/F
===============================================================================================================================
*/
User Function AEST015()

Local _lRet := .T.
Local _lFunc := .T.

DBSelectArea("ZZL")
DBSetOrder(3)
If !DBSeek(xFilial("ZZL")+__cUserId)
	_lRet := .F.
	_lFunc := .F.
	U_ITMsg("Usuário não cadastrado","Erro","Favor abrir chamado solicitado cadastro",1)
Else
	If Empty(ZZL->ZZL_GRPAPR)
		_lRet := .F.
		_lFunc := .F.
		U_ITMsg("Usuário não cadastrado como solicitante","Erro","Favor abrir chamado solicitado cadastro vinculando a um grupo de aprovação",1)
	EndIf
EndIf	

If _lFunc
	MATA105()
EndIf	
	
Return(_lRet)
