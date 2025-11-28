/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Darcio Sporl  |07/12/2015| Chamado 11737, 11831. Foi incluído o ponto de entrada para inclusão de novas legendas.
Jerry         |01/04/2016| Chamado 14908. Foi incluído legenda para PC Rejeitado.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: ACOM011
Autor-----------: Darcio Sporl
Data da Criacao-: 07/12/2015
Descrição-------: Ponto de Entrada criado para alterar/incluir novas legendas.
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function MT120LEG

Local aArea			:= FWGetArea()
Local aNewLegenda	:= aClone(ParamIXB[1]) //--aCores
Local nPosLib		:= aScan(aNewLegenda,{|x| x[1] == 'ENABLE'	})
Local nPosBlq		:= aScan(aNewLegenda,{|x| x[1] == 'BR_AZUL'	})

aNewLegenda[nPosLib][2] := "Liberado"
aNewLegenda[nPosBlq][2] := "Pendente Aprovação"

aAdd(aNewLegenda,{'BR_MARROM'	, 'Pendente Liberação por Compras'	})
aAdd(aNewLegenda,{'F12_VERM'	, 'Pedidos Rejeitados'	})

FWRestArea(aArea)

Return(aNewLegenda)
