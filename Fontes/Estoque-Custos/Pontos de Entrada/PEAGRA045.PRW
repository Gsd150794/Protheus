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
Programa----------: PEAGRA045
Autor-------------: Abrahao P. Santos
Data da Criacao---: 28/06/2016
Descrição---------: PE de validação do acesso a alterações na rotina de cadastro de locais de estoque - Chamado 15955
Parametros--------: Nenhum
Retorno-----------: Verdadeiro ou Falso
===============================================================================================================================
*/
User Function AGRA045

Local xRet   := .T.
Local _xAcesso	:= U_ITACSUSR( "ZZL_ADMLO" , "S" )

If (Type("ParamIXB[1]:NOPERATION") == "N" .And. ParamIXB[1]:NOPERATION == 1) .Or. (Type("ParamIXB[1]:NOPERATION") != "N")  //Visualização
	Return .T.
Else
	// Verifica se o usuário tem permissão para rodar a rotina
	If ValType( _xAcesso ) == 'N' .And. _xAcesso == 0
		Help( ,, 'Atenção!',, 'Usuário não está cadastrado na Gestão de Usuários do Configurador Italac!', 1, 0 )
		Return .F.
	ElseIf !_xAcesso
		Help( ,, 'Atenção!',, 'Usuário sem acesso à alterações  na rotina de cadastro de locais de estoque!', 1, 0 )
		Return .F.
	EndIf
EndIf

Return xRet
