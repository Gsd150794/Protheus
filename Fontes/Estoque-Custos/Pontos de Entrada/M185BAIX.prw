/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |10/01/2018| Chamado 23039. Nova Validação referente ao paramenrto IT_ARMCPR
Alex Wallauer |04/09/2018| Chamado 26146. Retirada a Validação referente ao paramenrto IT_ARMCPR
Lucas Borges  |19/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: M185BAIX
Autor-----------: Talita Teixeira 
Data da Criacao-: 11/03/2013 
Descrição-------: Ponto de Entrada que valida a baixas Pre-requisicoes gerando as requisicoes
Parametros------: Nenhum
Retorno---------: Lógico
===============================================================================================================================
*/
User Function M185BAIX

Local lRet	:= .T.

Public cNumSA:= SCP->CP_NUM
  
If SD3->D3_COD = SCP->CP_PRODUTO .And. SD3->D3_I_NUMCP = ' '
	SD3->(RecLock("SD3",.F.))
	SD3->D3_I_NUMCP := cNumSA
	SD3->(MSUnLock())
EndIf

SCP->(MSUnLock())

Return lRet
