/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |19/09/2023| Chamado 33887. Preenchimento da 2 UM do produto quando PA e sem conversão.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
=============================================================================================================================================================
Programa----------: PNEU002
Autor-------------: Alex Wallauer
Data da Criacao---: 19/09/2023
Descrição---------: P.E. no final da tela da função A103NFORI() do Fonte MATA103.PRW. Botões F7 e "Origem".
Parametros--------: Nenhum
Retorno-----------: Nenhum
=============================================================================================================================================================
*/
User Function PNEU002

Local _aArea    := FWGetArea()
Local _aArea2   := SD2->(GetArea())
Local nPosD1COD	:= aScan(aHeader,{|x| AllTrim(x[2])=='D1_COD'    })
Local nPosD1LOC := aScan(aHeader,{|x| AllTrim(x[2])=='D1_LOCAL'  })
Local nPosD1NFO := aScan(aHeader,{|X| AllTrim(X[2])=="D1_NFORI"  })
Local nPosD1SRO := aScan(aHeader,{|X| AllTrim(X[2])=="D1_SERIORI"})
Local nPosD1FOR := aScan(aHeader,{|X| AllTrim(X[2])=="D1_FORNECE"})
Local nPosD1LOJ := aScan(aHeader,{|X| AllTrim(X[2])=="D1_LOJA"   })
Local nPosD1ITO := aScan(aHeader,{|X| AllTrim(X[2])=="D1_ITEMORI"})
Local nPosD1QTS := aScan(aHeader,{|x| AllTrim(x[2])=='D1_QTSEGUM'})

If nPosD1LOC > 0 .And. nPosD1COD > 0 .And. !Empty(aCols[N][nPosD1COD]) .And. cTipo = 'D' .And. Posicione("SB1",1,xFilial("SB1")+aCols[N][nPosD1COD],"B1_TIPO") = 'PA'
   aCols[N][nPosD1LOC] := '31'
   If SB1->B1_CONV = 0 .And. !Empty(SB1->B1_SEGUM) .And. nPosD1QTS > 0 .And. nPosD1NFO > 0  .And. nPosD1SRO > 0  .And. nPosD1FOR > 0  .And. nPosD1LOJ > 0  .And. nPosD1ITO > 0  
       SD2->(DBSetOrder(3))  // D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM
       If SD2->(DBSeek(xFilial("SD2")+aCols[N][nPosD1NFO]+;
	                                  aCols[N][nPosD1SRO]+;
									  CA100FOR+;
									  CLOJA+;
									  aCols[N][nPosD1COD]+;
									  aCols[N][nPosD1ITO]))
          aCols[N][nPosD1QTS] := SD2->D2_QTSEGUM
	   EndIf
	EndIf
EndIf

FWRestArea( _aArea )
FWRestArea( _aArea2)

Return .T.
