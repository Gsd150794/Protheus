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
Programa----------: F4LOTIND
Autor-------------: Igor Melgaço
Data da Criacao---: 23/02/2022
Descrição---------: Ponto de Entrada que permite alterar o array F4 da janela de saldo por lote. Chamado: 34943
Parametros--------: 
Retorno-----------: Array
===============================================================================================================================
*/ 
User Function F4LOTIND

Local aArrayF4	:= ParamIXB[1]

aArrayF4 := aSort(aArrayF4,,,{|x,y| x[5] < y[5]})

U_ITMsg("Ao selecionar o lote o recomendado é priorizar o de menor validade. Clicando em Ok nesta mensagem a janela seguinte apresentará os lotes por ordem de validade."+Chr(13)+Chr(10)+Chr(13)+Chr(10)+"Certifique-se de fazer a escolha correta conforme esta orientação e a sua real necessidade!",,,3,,,,,, )

Return aArrayF4

