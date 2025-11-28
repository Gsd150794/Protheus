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
Programa----------: MA275ALTER
Autor-------------: Igor Melgaço
Data da Criacao---: 20/05/2021
Descrição---------: Ponto de Entrada que permite incluir campos para edição na Liberação do Lote. Chamado: 34943
Parametros--------: 
Retorno-----------: aAlter = Campos para permitir alteração na Liberação do Lote  
===============================================================================================================================
*/ 
User Function MA275ALTER()
Local aAlter := ParamIXB[1] // Vetor original contendo os campos do sistema// -- Adiciona campos criados por usuário no vetor aAlter

aAdd(aAlter, 'DD_LOTEFOR')

Return(aAlter)
