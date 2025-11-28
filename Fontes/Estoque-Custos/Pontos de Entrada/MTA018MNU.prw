/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |10/04/2018| Chamado 24306. Inclusao do botão Altera Preco
Alex Wallauer |12/02/2019| Chamado 28064. Ajustes nas chamadas DE MENIDEF
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MTA018MNU
Autor-------------: Erich Buttne
Data da Criacao---: 04/04/2013 
Descrição---------: Rotina desenvolvida para inclusão de botão na rotina de indicadores de produtos
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MTA018MNU()

aAdd(aRotina,{'Manutencao'  ,'U_AEST027(.F.)',0,4,0,NIL})//"SBZ",SBZ->(Recno()),4,.F.
aAdd(aRotina,{'Altera Preco','U_AEST027(.T.)',0,4,0,NIL})//"SBZ",SBZ->(Recno()),4,.T.

Return(aRotina)
