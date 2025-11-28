/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Josué Danich  |24/08/2018| Chamado 25960. Inclusão de botão de análise de crédito
Lucas Borges  |02/10/2025| Chamado 51526. Modificada forma para recuperar a matrícula do usuário.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MA030BUT
Autor-------------: Alexandre Villar
Data da Criacao---: 17/06/2014
Descrição---------: Ponto de entrada para guardar os dados do cadastro do Cliente antes da alteração.
Parametros--------: Nenhum
Retorno-----------: aBtnUsr - Array para inclusão de botões na tela de manutenção do cadastro de Clientes
===============================================================================================================================
*/
User Function MA030BUT

Local nOpcA		:= ParamIXB[01] As Numeric
Local aBtnUsr	:= {} As Array
Local cMatUsr	:= FWSFAllUsers({__cUserID},{"USR_FILIAL"})[1][3]+FWSFAllUsers({__cUserID},{"USR_CODFUNC"})[1][3] As Character

//Inclui botoes na tela do cadastro de clientes se não For inclusão
If	nOpcA != 3
	aAdd( aBtnUsr , { "Alteracoes" , {|| U_COMS004() } , "Historico de Alteracoes" , "Alteracoes" } )
	//Se é usuário do crédito inclui botão de análise de crédito
	If GetAdvFVal( "ZZL" , "ZZL_LIBCRE" , xFilial("ZZL") + cMatUsr , 1 , "N" ) == "S"
		aAdd( aBtnUsr , { "An Credito" , {|| U_Ctelcred() } , "Analise de Credito" , "An Credito" } )
	EndIf
EndIf

//Caso a chamada seja de alteração, guarda os valores originais dos campos
If nOpcA == 4
	Public _aITASA1 := U_ITINILOG( "SA1" )
EndIf

Return(aBtnUsr)

/*
===============================================================================================================================
Programa----------: Ctelcred
Autor-------------: Josué Danich Prestes
Data da Criacao---: 24/08/2018
Descrição---------: Chama consulta cisp para pedido de vendas
Parametros--------: Nenhum
Retorno-----------: nenhum
===============================================================================================================================
*/
User Function Ctelcred

FWMsgRun(,{ || U_TelCred(2)}, "Aguarde...","Realizando consulta Cisp...")

Return
