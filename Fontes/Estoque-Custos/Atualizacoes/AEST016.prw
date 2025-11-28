/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |01/10/2021| Chamado 37893. Ajuste para não permitir executar p/ as filiais inclusas no parâmetro IT_FILIWFSA
Alex Wallauer |06/12/2021| Chamado 38533. Nova Validacao de acesso como o campo ZZL_PEFROU
Lucas Borges  |19/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: AEST016
Autor-------------: André Lisboa
Data da Criacao---: 11/09/2017
Descricao---------: Chamado menu: Validar permissão de acesso a rotina de liberação de SAs conforme cadastro na tabela ZZL 
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AEST016

Local _lRet  := .T.
Local _lFunc := .T.
Local cFils  := AllTrim(SuperGetMV("IT_FILIWFS",.T.,"01;40;10;20;23"))

If cFilAnt $  cFils .And.  ! U_ITVACESS( 'ZZL' , 3 , 'ZZL_PEFROU' , 'S' )
	U_ITMsg("Rotina desativada para as Filiais [ "+cFils+" ]","AVISO","Aprovar via e-mail do Workflow ou atraves da Rotina: Estoque/Custos -> Atualizacoes -> Liberacao de Dctos",1)
	Return .F.
EndIf

DBSelectArea("ZZL")
ZZL->(DBSetOrder(3))
If !ZZL->(DBSeek(xFilial("ZZL")+__cUserId))
	_lRet := .F.
	_lFunc := .F.
	U_ITMsg("Usuário não cadastrado","Erro","Favor abrir chamado solicitado cadastro",1)
Else
	If ZZL->ZZL_LIBSAS <> "S" .Or. Empty(ZZL->ZZL_GRPAPR)
		_lRet := .F.
		_lFunc := .F.
		U_ITMsg("Usuário não cadastrado como Aprovador","Erro","Favor abrir chamado solicitado cadastro vinculando a um grupo de aprovação",1)
	EndIf
EndIf

If _lFunc
	MATA107()
EndIf
	
Return
