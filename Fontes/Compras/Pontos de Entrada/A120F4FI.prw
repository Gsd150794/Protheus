/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Darcio		  |17/12/2015| Chamado 13268. Foi complementada o filtro, para não carregar SC's sem grupo, eliminada resíduos, 
			  |			 | liberadas e com o grupo	o mesmo do usuário logado.
=====================================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: A120F4FI
Autor-------------: Darcio Ribeiro Sporl
Data da Criacao---: 30/11/2015
Descrição---------: Ponto de Entrada responsável por filtrar a tabela SC1 por itens da solicitação
Parametros--------: Nenhum
Retorno-----------: aRet[1] - 	1 - String - Filtro no SC1 para ISAM ( Sintaxe xBase )
------------------:				2 - String - Filtro no SC1 para SQL ( Sintaxe SQL )
------------------:				3 - String - Filtro no SC3 para ISAM ( Sintaxe xBase )
------------------:				4 - String - Filtro no SC3 para SQL ( Sintaxe SQL )
------------------:				Não é necessário definir todos os elementos do array.
===============================================================================================================================
*/
User Function A120F4FI

Local aArea	:= FWGetArea()
Local aRet	:= {}

DBSelectArea("SY1")
SY1->(DBSetOrder(3))
SY1->(DBSeek(xFilial("SY1") + __cUserId))

aRet	:= {"C1_CODCOMP <> ' ' .And. C1_QUJE < C1_QUANT .And. C1_RESIDUO <> 'S' .And. !Empty(C1_GRUPCOM) .And. C1_GRUPCOM == '" + SY1->Y1_GRUPCOM + "' .And. C1_APROV == 'L'",,,}

FWRestArea(aArea)

Return(aRet)
