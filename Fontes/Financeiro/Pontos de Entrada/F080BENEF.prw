/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Darcio Sporl	|14/12/2016| Chamado 17677. Ponto de entrada desenvolvido para trazer o nome do beneficiário na baixa do título.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: F080BENEF
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 14/12/2016
Descrição---------: Ponto de entrada para trazer o nome do beneficiário na baixa do título
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function F080BENEF()
Local _cBenef := PadR(SA2->A2_NOME,TamSX3("EF_BENEF")[1])

Return(_cBenef)
