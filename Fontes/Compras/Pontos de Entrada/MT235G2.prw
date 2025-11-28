/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Darcio		  |15/10/2015| Chamado 12316. Criada validação na eliminação de resíduo, onde o usuário corrente somente poderá 
			  |			 | eliminar resíduo caso este seja o aprovador, solicitante ou administrador da SC
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MT235G2
Autor-------------: Darcio Ribeiro Sporl
Data da Criacao---: 15/10/2015
Descrição---------: LOCALIZAÇÃO : Funções MA235PC(), MA235CP(), MA235SC()
                  : EM QUE PONTO : Antes de processar a eliminação de cada Pedido de Compra, por residuo.
Parametros--------: ParamIXB[1] - Alias do arq. em verificação: "SC7", "SC3" ou "SC1"
------------------: ParamIXB[2] - Número indicativo do arq. em verificação: 1 para "SC7", 2 para "SC3", 3 para "SC1"
Retorno-----------: lRet - .T. permite eliminar os resíduos e .F. não elimina os resíduos.
===============================================================================================================================
*/
User Function MT235G2

Local _aArea	:= FWGetArea()  
Local _lRet		:= .T.
Local _cAlias	:= ParamIXB[1]
Local _nIndex	:= ParamIXB[2]
Local _xValid	:= U_ITACSUSR( 'ZZL_ADMSC' , 'S' )

If _nIndex == 3		//Validação apenas para solicitação de compras
	DBSelectArea("SC1")
	SC1->(DBGoTo((_cAlias)->SC1RECNO))
	
	If ValType(_xValid) == 'L' .And. !_xValid
		If SC1->C1_I_CODAP <> __cUserId
			If SC1->C1_I_CDSOL <> __cUserId
				_lRet := .F.
			EndIf
		EndIf
	EndIf
EndIf

FWRestArea(_aArea)

Return(_lRet)
