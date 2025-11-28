/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
André Carvalho|07/07/2014| Chamado 6538. Incluida tratativa para novo tipo "PP"
André Carvalho|31/07/2014| Chamado 6538. Correção no calculo para preenchimento do campo
Lucas Borges  |10/09/2024| Chamado 48465. Removendo warning de compilação.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: AEST035
Autor-------------: Andre Lisboa
Data da Criacao---: 02/04/2014
Descrição---------: Rotina para acertar quantidade do produto destino de acordo com a unidade de medida do produto origem nos 
                  apontamentos de perda. Gatilho SB6->B6_QUANT
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AEST035

Local _aArea     	:= FWGetArea()
Local cUMOrig    	:= ""
Local cUMDest    	:= ""
Local nQtdOriP	 	:= aScan(aHeader,{|X| Upper(AllTrim(X[2]))=="BC_QUANT"})    
Local nQtdDstP   	:= aScan(aHeader,{|X| Upper(AllTrim(X[2]))=="BC_QTDDEST"})    
Local nPesoL	 	:= 0
Local cPdOriP 	 	:= aScan(aHeader,{|X| Upper(AllTrim(X[2]))=="BC_PRODUTO"})
Local cPrdDstP	 	:= aScan(aHeader,{|X| Upper(AllTrim(X[2]))=="BC_CODDEST"}) 
Local cFatorO	 	:= ""
Local nConv		 	:= 0
Local nQtdOri 	 	:= aCols[N][nQtdOriP]
Local nQtdDst	 	:= aCols[N][nQtdDstP]
Local cPrdOri	 	:= aCols[N][cPdOriP]
Local cPrdDst 	 	:= aCols[N][cPrdDstP] 
Local cMotivo		:= aScan(aHeader,{|X| Upper(AllTrim(X[2]))=="BC_MOTIVO"})
Local cMot		 	:= aCols[N][cMotivo]

cUMOrig  := Posicione("SB1",1,xFilial("SB1")+cPrdOri,"B1_UM")
cUMDest  := Posicione("SB1",1,xFilial("SB1")+cPrdDst,"B1_UM")
nPesoL   := Posicione("SB1",1,xFilial("SB1")+cPrdOri,"B1_PESO")
cFatorO  := Posicione("SB1",1,xFilial("SB1")+cPrdOri,"B1_TIPCONV")
nConv    := Posicione("SB1",1,xFilial("SB1")+cPrdOri,"B1_CONV")

If cMot<>"PP"
   If cUMDest == cUMOrig
      nQtdDst := nQtdOri
      FWRestArea(_aArea)
      Return(nQtdDst)
   Else
      If cFatorO = "M"
	      nQtdDst := nQtdOri*nConv 
	      FWRestArea(_aArea)
         Return(nQtdDst)
	   Else
	      nQtdDst := nQtdOri/nConv
	      FWRestArea(_aArea)
         Return(nQtdDst)
	   EndIf
   EndIf
Else
   FWRestArea(_aArea)
   Return
EndIf
