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
Programa----------: FA080SEF
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 07/07/2011
Descrição---------: Ponto de Entrada com o objetivo de armazenar a linha contida no titulo na tabela SEF no momento da baixa
                     automatica quando esta For utilizada para geracao automatica de cheque.
                     Isto devido a necessidade da unidade de Jaru em imprimir os cheques ordenados por Linha.
Parametros--------: Nenhum
Retorno-----------: .T. - Permite a geracao da comissao na baixa.
===============================================================================================================================
*/
User Function FA080SEF

SEF->EF_L_LINHA:= SE2->E2_L_LINRO
	
Return
