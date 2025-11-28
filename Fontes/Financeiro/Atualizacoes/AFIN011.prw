/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz     |07/05/2018| Chamado 24726. Padronização dos cabeçalhos dos fontes e funções do módulo financeiro.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: AFIN011
Autor-------------: Emerson Dias 
Data da Criacao---: 15/01/2009
Descrição---------: Filtra no momento da montagem do bordero de titulos a pagar com o objetivo de filtrar apenas titulos de 
                    acordo com Tipo de Pagamento escolhido pelo usuario (DOC, TED, Credito em Conta Corrente, etc.).	
                    Funcao chamada pelo ponto de Entrada FIN150_1.
Parametros--------: Nenhum
Retorno-----------: cSeq = instrucao do filtro a ser realizado.
===============================================================================================================================
*/
User Function AFIN011()

Local nSeq := 0

nSeq := nSeq + 1

Return(nSeq)
