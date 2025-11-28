/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Darcio		  |17/12/2015| Chamado 13268. Foi complementada o filtro, para não carregar SC's sem grupo, eliminada resíduos, 
			  |			 | liberadas e com o grupo o mesmo do usuário logado.
=====================================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: A120PIDF
Autor-------------: Darcio Ribeiro Sporl
Data da Criacao---: 30/11/2015
Descrição---------: Ponto de Entrada responsável por filtrar a tabela SC1 por solicitações completas
Parametros--------: Nenhum
Retorno-----------: aRet[1] - Expressão xBase contendo o filtro da tabela SC1
===============================================================================================================================
*/
User Function A120PIDF

Local aArea	:= FWGetArea()
Local aRet	:= {}

DBSelectArea("SY1")
SY1->(DBSetOrder(3))
SY1->(DBSeek(xFilial("SY1") + __cUserId))

aRet	:= {"C1_CODCOMP <> ' ' .And. C1_QUJE < C1_QUANT .And. C1_RESIDUO <> 'S' .And. !Empty(C1_GRUPCOM) .And. C1_GRUPCOM == '" + SY1->Y1_GRUPCOM + "' .And. C1_APROV == 'L'",}

FWRestArea(aArea)

Return(aRet)
