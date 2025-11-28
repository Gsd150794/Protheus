/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Andre Lisboa  |07/07/2014| Chamado 6538. Incluida a tratativa para novo tipo "PP".
Andre Lisboa  |31/07/2014| Correção do cálculo de preenchimento do campo
Alexandre V.  |06/08/2015| Atualização da rotina conforme chamado 11137
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: AEST033
Autor-----------: Andre Lisboa
Data da Criacao-: 03/04/2014
Descrição-------: Rotina para acertar quantidade de produto destino de acordo com a unidade de medida do produto de origem nos
                  apontamentes de perdas. Gatilho do campo SBC->BC_QUANT (002)
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function AEST033()

Local _aArea	:= FWGetArea()
Local nQtdDstP	:= aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "BC_QTDDEST" } )
Local nQtdDst	:= aCols[N][nQtdDstP]
Local cPrdDstP	:= aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "BC_CODDEST" } )
Local cPrdDst	:= aCols[N][cPrdDstP]
Local nQtSegDP	:= aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "BC_QTDDES2" } )
Local nQtSegD	:= aCols[N][nQtSegDP]
Local cFatorD	:= ""
Local nPesoLD	:= 0
Local nConv		:= 0
Local cMotivo	:= aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "BC_MOTIVO" } )
Local cMot		:= aCols[N][cMotivo]

nPesoLD	:= Posicione( "SB1" , 1 , xFilial("SB1") + cPrdDst , "B1_PESO"		)
cFatorD	:= Posicione( "SB1" , 1 , xFilial("SB1") + cPrdDst , "B1_TIPCONV"	)
nConv	:= Posicione( "SB1" , 1 , xFilial("SB1") + cPrdDst , "B1_CONV"		)

If cMot == "PP"
	
	nQtSegD := 0
	
Else

   If nQtdDstP > 0
   
      If cFatorD = "M"
      
	     nQtSegD := nQtdDst * nConv
	     
	  Else
	  
	     nQtSegD := nQtdDst / nConv
	     
	  EndIf
	  
   EndIf

EndIf

FWRestArea(_aArea)

Return( nQtSegD )
