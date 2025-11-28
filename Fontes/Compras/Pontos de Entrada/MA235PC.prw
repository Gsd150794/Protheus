/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
=====================================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MA235PC
Autor-------------: Darcio Ribeiro Sporl
Data da Criacao---: 23/02/2016
Descrição---------: Ponto de entrada para seguir ou não com a eliminação de resíduos
Parametros--------: Nenhum
Retorno-----------: .F. - Retorno falso para não continuar com o processo de eliminação de resíduos
===============================================================================================================================
*/
User Function MA235PC

Local aArea			:= FWGetArea()
Local aMensagem		:= {}
Local aProbl		:= {}
Local aSoluc		:= {}

aProbl := {}
aAdd(aProbl, "Rotina padrão não pode ser utilizada.")
	
aSoluc := {}
aAdd(aSoluc, "Favor utilizar a rotina (Compras --> Atualizações --> Especifico Italac --> Elimina Residuos Sc/PC).")
	
aMensagem := {"Eliminação de Resíduo", aProbl, aSoluc}
	
U_ITMsHTML(aMensagem)

FWRestArea(aArea)

Return(.F.)
