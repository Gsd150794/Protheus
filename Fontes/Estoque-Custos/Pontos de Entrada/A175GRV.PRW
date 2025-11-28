/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Josué Danich  |29/03/2019| Chamado 28765. Correção de leitura de aheader dinâmico
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: A175GRV
Autor-------------: Josué Danich Prestes
Data da Criacao---: 23/07/2018
Descrição---------: PE chamado após a gravação de todos os dados após liberacao/Rejeicao do Material no CQ.- Chamado 25600
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function A175GRV()

Local nRecSD3   := SD3->(Recno())
Local nIndSD3   := SD3->(IndexOrd())
Local cSeekSD3  := xFilial("SD3") + PadR(CA175NUM,9)+cA175Prod
Local _nposnum  := aScan(aheader,{|x| x[2] = "D7_NUMSEQ"})

SD3->(DBSetOrder(2))//D3_FILIAL+D3_DOC+D3_COD
_arecs := {}

If SD3->(DBSeek(cSeekSD3))

	//==============================================================
	// Grava data em todos os movimentos do d3 com mesmo doc mas 
	// que o numseq não conste do acols      
	//==============================================================
	While !SD3->(Eof()) .And. SD3->D3_FILIAL+SD3->D3_DOC+SD3->D3_COD == cSeekSD3
	
		If aScan(acols,{ |_vaux| _vaux[_nposnum] == SD3->D3_NUMSEQ}) == 0
		
			RecLock("SD3",.F.)
			SD3->D3_I_DTAP := Date()
			SD3->D3_I_HRAP := Time()
			MSUnLock()
				
		EndIf

		SD3->(DBSkip())
		
	EndDo
	
EndIf
	
SD3->(DBSetOrder(nIndSD3))
SD3->(DBGoTo(nRecSD3))

Return
