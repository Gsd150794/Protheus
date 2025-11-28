/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |01/07/2020| Chamado 33409. Corrigida geração da Contra-nota de produtor. Retirado tratamento via job.
Lucas Borges  |29/12/2020| Chamado 34986. Ajuste para gravar o movimento do Leite de Terceiros e Contra Nota no Leite Próprio.
Lucas Borges  |17/02/2021| Chamado 35644. Ajuste para não gravar movimento do Leite de Terceiros e Contra Nota no Fechamento.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: SF1140I
Autor-------------: Alexandre Villar
Data da Criacao---: 26/11/2014
Descrição---------: Ponto de entrada após a gravação da pré-nota de entrada. Utilizado na atualização do cabeçalho do Pré-
					Documento de Entrada
Parametros--------: ParamIXB[1]: Informa se está sendo realizada a inclusão do pré-documento de entrada.
					ParamIXB[2]: informa se está sendo realizada alteração do pré-documento de entrada.
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function SF1140I

// Função para gravar o movimento do Leite de Terceiros e Contra Nota no Leite Próprio
If !FWIsInCallStack("U_MGLT009")
	U_GrvLT3()
EndIf

Return
