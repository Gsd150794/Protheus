/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Andre Lisboa  |07/07/2014| Chamado 6538. Incluída a tratativa para novo tipo "PP"
Alexandre V.  |06/08/2015| Chamado 11137. Atualização da rotina
Lucas Borges  |10/09/2024| Chamado 48465. Removendo warning de compilação.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: AEST036
Autor-----------: Andre Lisboa
Data da Criacao-: 03/04/2014
Descrição-------: Rotina para preencher armazem do produto destino na perda através do produto origem de acordo com parâmetro
                  IT_GRPSUCA. Gatilho do campo SB6->B6_PRODUTO (003)
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function AEST036

Local _aArea	:= FWGetArea()
Local cPrdOriP	:= aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "BC_PRODUTO" } )
Local cPrdOri	:= AllTrim( aCols[N][cPrdOriP] )
Local cGrpPrd	:= AllTrim( GETMV( "IT_GRPSUCA" ) )
Local cPrdSuc	:= AllTrim( GETMV( "IT_PRDSUCA" ) )
Local cLocal	:= ""
Local cMotivo	:= aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "BC_MOTIVO" } )
Local cMot		:= aCols[N][cMotivo]

If cPrdOri $ cGrpPrd .And. cMot <> "PP"
	cLocal := Posicione( "SB1" , 1 , xFilial("SB1") + cPrdSuc , "B1_LOCPAD" )
EndIf

If cMot == "PP"
   cLocal := ""
EndIf

FWRestArea(_aArea)

Return(cLocal)
