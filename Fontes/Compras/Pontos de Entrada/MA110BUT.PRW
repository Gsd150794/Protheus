/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |03/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MA110BUT
Autor-------------: Xavier
Data da Criacao---: 15/04/2015
Descrição---------: Ponto de entrada criação de botões na solicitação de compras
					Este ponto de entrada tem o objetivo de permitir ao usuário manipular a barra de botões nasrotinas de 
					visualização, inclusão, Alteração e exclusão de solcitação de compras.
					Localização: Rotina de Solicitação de Compras MATA110()
					Em que Ponto: Antes de montar a tela de Solicitação de Compras  para cada operação selecionada (Visualização
					, Inclusão, Alteração e Exclusão).
Parametros--------: ParamIXB[1] -> N -> Parâmetro numérico contendo a opção de operação da rotina selecionada nOpc:
										2 - Visualização/ 3 - Inclusão/ 4 - Alteração/ 5 - Exclusão
					ParamIXB[2] -> A -> Vetor contendo os botões carregados pela rotina.
Retorno-----------: aBut -> A -> Retorno contendo os botões que deverão ser utilizados pelo programa de Solicitação de Compras.
					ParamIXB[1] -> Opção selecionada pelo usuário, sendo: 2-Visulizar / 3-Incluir / 4-Alterar / 5-Excluir
					ParamIXB[2] -> Vetor contendo os botões originais da rotina.
===============================================================================================================================
*/
User Function MA110BUT

Local aUsrBt := ParamIXB[2]

aAdd(aUsrBt,{'CLIPS',{|| U_GDTotSB2(GdFieldGet("C1_PRODUTO")) },"Consultar saldo atual","Cons.Saldos"}) 

Return aUsrBt
