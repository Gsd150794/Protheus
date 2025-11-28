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
Programa----------: M650CONSES
Autor-------------: Alex Wallauer
Data da Criacao---: 09/03/2022
Descrição---------: Ponto de entrada para liberação de escolha de lotes/endereços - Chamado 34943
                     Deve retornar se será liberado ao usuário informar lote e endereço (.T.) ou não (.F.).
                     Identificador se irá permitir informar Lote/SubLote/Endereço/Número de Série nos empenhos, quando o 
                     parâmetro MV_CONSEST estiver como N.
Parametros--------: ParamIXB = nSldDisp
Retorno-----------: Zero para o saldo disponivel
===============================================================================================================================
*/
User Function M650CONSES
Return .T.
