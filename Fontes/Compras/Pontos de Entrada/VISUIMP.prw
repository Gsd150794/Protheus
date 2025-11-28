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
Programa----------: VISUIMP
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 11/02/2022
Descrição---------: Ponto de entrada que indica se permite a digitação manual dos impostos no rodapé dos documentos de entrada.
					Chamado 39180
Parametros--------: ParamIXB[1]	-> L -> .F. -> indica se está em modo de visualização dos impostos
Retorno-----------: .T. permite apenas visualizar os impostos, ou .F. para permitir alterar os impostos
===============================================================================================================================
*/
User Function VISUIMP
 
Local _lRet := .T.

If Posicione("ZZL",3,xFilial("ZZL")+RetCodUsr(),"ZZL_ALTIMP") == 'S' .Or. FwIsAdmin()
    _lRet := .F.
EndIf
 
Return _lRet
