/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Jerry         |01/04/2016| Chamado 14908. Foi incluído legenda para PC Rejeitado.
Jerry         |06/04/2016| Chamado 14970. Foi alterado a tratativa para legenda para PC Rejeitado.
Alex Walaleur |07/12/2020| Chamado 34914. Correção do erro do padrão pq colocaram 2 veses a cor verde na array aCores.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: MT120COR
Autor-----------: Darcio Sporl
Data da Criacao-: 07/12/2015
Descrição-------: Ponto de entrada para incluir/alterar as cores e condições da legenda.
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function MT120COR

Local aArea		:= FWGetArea()
Local aNewCores	:= aClone(ParamIXB[1])  //--aCores
Local nPosLib	:= aScan(aNewCores,{|x| x[2] == 'ENABLE'	})
Local nPosBlq	:= aScan(aNewCores,{|x| x[2] == 'BR_AZUL'	})

aNewCores[nPosLib][1] := 'C7_QUJE == 0 .And. C7_QTDACLA == 0 .And. C7_CONAPRO == "L"'									                            	//--Liberado
aNewCores[nPosBlq][1] := 'C7_ACCPROC <> "1" .And. C7_CONAPRO == "B" .And. C7_I_SITWF <> "3" .And. C7_QUJE < C7_QUANT .And. C7_APROV <> "PENLIB"'	//--Pendente Aprovação

aNewCores[nPosLib][2] := 'xxxxxxx'//Correção do erro do padrão pq colocaram 2 veses a cor verde na array aCores
If (nPosLib2:= aScan(aNewCores,{|x| x[2] == 'ENABLE'	})) <> 0
   aNewCores[nPosLib2][1] := 'C7_QUJE == 0 .And. C7_QTDACLA == 0 .And. C7_CONAPRO == "L"'									                            	//--Liberado
EndIf
aNewCores[nPosLib][2] := 'ENABLE'//Correção do erro do padrão pq colocara 2 veses a cor verde na array aCores

aAdd(aNewCores,{ 'C7_CONAPRO == "B" .And.C7_QUJE < C7_QUANT .And. C7_APROV == "PENLIB"'	, 'BR_MARROM'	 })	//--Pendente Liberação por Compras
aAdd(aNewCores,{ 'C7_CONAPRO == "B" .And. C7_APROV <> "PENLIB"','F12_VERM' })	//--PC Rejeitados

FWRestArea(aArea)

Return(aNewCores)
