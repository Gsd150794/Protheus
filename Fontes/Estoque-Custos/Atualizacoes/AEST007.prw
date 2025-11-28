/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alexandre V.  |30/09/2014| Chamado 7248. Atualização da rotina retirando comentários e referências ao parâmetro que não está 
			  |			 | mais em  uso. 
Alexandre V.  |06/10/2014| Chamado 7664. Correção do nome da variável de controle do ambiente para não dar erro durante a validação. 
Alex Wallauer |22/03/2018| Ajustes no tratamento dos niveis para o grupo "0599". Chamado 24257
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: AEST007
Autor-------------: Frederico O. C. Jr
Data da Criacao---: 17/07/2008
Descrição---------: Validacao do usuario para inclusao/alteracao de PA e EM e  
                    "Modo Edicao" no SX3 dos campos: B1_I_NIV2, B1_I_NIV3 e B1_I_NIV4
Parametros--------: Nenhum
Retorno-----------: Lógico - define se o usuário tem ou não acesso à alterar o campo
===============================================================================================================================
*/
User Function AEST007()

Local _aArea 	:= FWGetArea()
Local _cUsuario	:= RetCodUsr()
Local _lRet		:= .F.

If !( M->B1_TIPO $ "PA/EM" )

	_lRet := .T.

ElseIf  M->B1_TIPO = "EM" .And. M->B1_GRUPO = "0599"

	ZZL->( DBSetOrder(3) )
	If ZZL->( DBSeek( xFilial("ZZL") + _cUsuario ) ) .And. (ZZL->(FIELDPOS("ZZL_EMBGNR")) = 0 .Or. ZZL->ZZL_EMBGNR == 'S')//Se o usuario pode digitar itens genericos (sem precisara de niveis)
		_lRet := .F.
    Else//Se o usuario não pode digitar itens genericos (tem que digitar os niveis)
		_lRet := .T.
	EndIf

Else
	
	//================================================================================
	// Talita - 15/07/13 - Alterada a validação para alteração dos produtos do tipo 
	// PA/EM que era feito pelo parametro IT_CADPA e agora será feita na tela de 
	// gestão de usuarios campo ZZL_CADPA. Chamado:3747
	//================================================================================
	ZZL->( DBSetOrder(3) )
	If ZZL->( DBSeek( xFilial("ZZL") + _cUsuario ) ) .And. ZZL->ZZL_CADPA == 'S'
		_lRet := .T.
	EndIf
	
EndIf

FWRestArea(_aArea)

Return( _lRet )
