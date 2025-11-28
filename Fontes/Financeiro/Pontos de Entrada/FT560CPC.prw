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
Programa----------: FT560CPC
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 17/05/2017
Descrição---------: Ponto de Entrada que habilita outros campos na tela de Prestação de Contas, na rotina Movimentos (FINA560)
					O Ponto de Entrada é chamado ao carregar a tela de inclusão de Prestação de Contas. Chamado 20036
Parametros--------: aRotina
Retorno-----------: aRotina
===============================================================================================================================
*/
User Function FT560CPC

Local aRotina := {}

aAdd(aRotina,"EU_I_NATUR")

Return (aRotina)
