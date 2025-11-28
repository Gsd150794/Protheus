/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Darcio Sporl  |13/06/2016| Chamado 15589. Ponto de entrada criado para disponibilizar a funcionalidade de devolução de EPI's.
Julio Paz     |26/10/2017| Chamado 22134. Inclusão de chamadas de funções que tem o objetivo de inicializar conteúdos devarStatic
              |          | estaticas.
Julio Paz     |10/04/2018| Chamado 23960. Realização de ajustes nas rotinas de entrega e devolução de EPI, para impressão correta
              |          | dos comprovantes.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MDTA6951
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 13/06/2016
Descrição---------: Ponto de Entrada para incluir botões na Ações Relacionadas na seleção de EPI's
Parametros--------: Nenhum
Retorno-----------: _aRot -> Array contendo o botão
===============================================================================================================================
*/
User Function MDTA6951()

Local _aArea	:= FWGetArea()
Local _aButtons	:= {}

aAdd(_aButtons,{"ESTOMOVI" ,{|| U_AMD003C()},"Devolução EPI's","Dev.Almox"})
aAdd(_aButtons,{"ESTOMOVI" ,{|| U_MDT6957I()},"Imprime Recibos Dev.Almox","Imp.Recib.Dev.Almox"})

U_MDT6954G(.F.) 

U_MDT6954H("INICIALIZA")  // Zera o conteúdo da variável estática do fonte MDTA6954.

FWRestArea(_aArea)

Return(_aButtons)
