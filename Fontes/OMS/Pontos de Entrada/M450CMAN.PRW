/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |02/10/2025| Chamado 51526. Modificada forma para recuperar a matrícula do usuário.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: M450CMAN
Autor-------------: Talita Teixeira
Data da Criacao---: 14/02/2014
Descrição---------: Validacao do usuario para liberação de credito manual através da rotina Analise Credito Cliente.
Parametros--------: Nenhum
Retorno-----------: .T. se usuario pode incluir/alterar - .F. se usuario nao tem permissao para incluir/alterar
===============================================================================================================================
*/
User Function M450CMAN

Local aArea 	:= FWGetArea() As Array
Local lRet		:= .F. As Logical

DBSelectArea("ZZL")
ZZL->(DBSetOrder(1))
If ZZL->(DBSeek(xFilial("ZZL")+FWSFAllUsers({__cUserID},{"USR_FILIAL"})[1][3]+FWSFAllUsers({__cUserID},{"USR_CODFUNC"})[1][3])) .And. ZZL->ZZL_LIBCRE == 'S'
	lRet := .T.		
Else
	xMagHelpFis("M450CMAN01","Usuário sem acesso para liberação de pedido por crédito ","Favor contactar o departamento de informática informando do erro ocorrido.")
EndIf
FWRestArea(aArea)

Return lRet
