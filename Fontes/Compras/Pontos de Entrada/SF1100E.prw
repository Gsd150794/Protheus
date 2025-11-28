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
Programa--------: SF1100E
Autor-----------: Lucas Borges Ferreira
Data da Criacao-: 02/07/2018
Descrição-------: Executado antes de deletar o registro no SF1, na exclusao da Nota de Entrada. O registro ja se encontra 
					travado (Lock). Function A100Deleta() - Responsável pela exclusão de notas fiscai de entrada.
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function SF1100E

//Exclui os complementos de notas fiscais de entrada e de saida com as informacoes necessarias ao Sped.
Processa( {|| U_ECompFis("E",SF1->F1_DOC,SF1->F1_SERIE,SF1->F1_FORNECE,SF1->F1_LOJA) }, "Aguarde...", "Excluindo Complementos Fiscais...",.F.)

Return
