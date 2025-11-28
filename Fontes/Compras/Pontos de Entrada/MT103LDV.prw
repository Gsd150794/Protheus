/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |09/01/2018| Chamado 23154, 23145, 23147, 23142. PE reescrito pq toda a lógica não fazia sentido e dava erro. 
Alex Wallauer |18/09/2023| Chamado 33887. Preenchimento da 2 UM do produto quando PA e sem conversão.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
=============================================================================================================================================================
Programa----------: MT103LDV
Autor-------------: Talita
Data da Criacao---: 01/03/2013
Descrição---------: Verifica no retorno do documento de saída se o produto é do Tipo PA para utilizar o armazém 31.
					Este ponto de entrada é executado durante o preenchimento da linhas a serem enviadas para a rotina automatica
Parametros--------: ParamIXB[1] - Vetor - Recebe um array na seguinte estrutura: [n][1] Campo ; [n][2] Conteudo ; [n][3] Nil
					ParamIXB[2]	- Caracter - Alias da tabela SD2
Retorno-----------: Retorno- Vetor - Retorna um array na seguinte estrutura: [n][1] Campo ; [n][2] Conteudo ; [n][3] Nil
=============================================================================================================================================================
*/
User Function MT103LDV

Local _aArea    := FWGetArea()
Local _aArea2   := SD2->(GetArea())
Local _aRet	    := {}
Local _nI	    := 0
Local aLinha    := ParamIXB[1]//Vetor - Recebe um array na seguinte estrutura: [n][1] Campo ; [n][2] Conteudo ; [n][3] Nil
Local cAliasSD2 := ParamIXB[2]//Caracter - Alias da tabela SD2
Local nPosD1COD := aScan( aLinha , { |X| AllTrim( X[01] ) == "D1_COD"    } )
Local nPosD1LOC := aScan( aLinha , { |X| AllTrim( X[01] ) == "D1_LOCAL"  } )
Local nPosD1VUN := aScan( aLinha , { |X| AllTrim( X[01] ) == "D1_VUNIT"  } )
Local nPosD1QTS := aScan( aLinha , { |X| AllTrim( X[01] ) == "D1_QTSEGUM"} )

If nPosD1LOC > 0 .And. nPosD1COD > 0 .And. Posicione("SB1",1,xFilial("SB1")+aLinha[nPosD1COD][02],"B1_TIPO") = 'PA'
	aLinha[nPosD1LOC][02] := '31'
	If IsinCallStack("M103FILDV") .And. IsinCallStack("A103DEVOL") .And. SB1->B1_CONV = 0 .And. !Empty(SB1->B1_SEGUM) 
	   If nPosD1QTS > 0  
	      aLinha[nPosD1QTS][02] := (cAliasSD2)->D2_QTSEGUM
	   Else
		  aAdd( aLinha, { "D1_SEGUM"    , (cAliasSD2)->D2_SEGUM   , Nil } )
		  aAdd( aLinha, { "D1_QTSEGUM"  , (cAliasSD2)->D2_QTSEGUM , Nil } )
		  aAdd( aLinha, { "D1_VUNIT"    , aLinha[nPosD1VUN][02]   , Nil } )

	   EndIf
	EndIf
EndIf

For _nI := 1 To Len( aLinha )
	aAdd( _aRet , { aLinha[_nI][01] , aLinha[_nI][2] , aLinha[_nI][3] } )
Next

FWRestArea( _aArea )
FWRestArea( _aArea2)

Return( _aRet )
