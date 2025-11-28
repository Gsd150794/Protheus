/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MA260D3
Autor-------------: Josué Danich Prestes
Data da Criacao---: 23/07/2018
Descrição---------: PE executado após gravação da transferência simples de estoque
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MA260D3()

Local nRecSD3   := SD3->(Recno())
Local nIndSD3   := SD3->(IndexOrd())
Local cSeekSD3  := SD3->D3_FILIAL+SD3->D3_NUMSEQ+"E0"+SD3->D3_COD

//==============================================================
// Grava o Nro do Documento no SD3 de Entrada - 499.          
//==============================================================
RecLock("SD3",.F.)
SD3->D3_I_DTAP := Date()
SD3->D3_I_HRAP := Time()
MSUnLock()
	
//==============================================================
// Posiciona no proximo SD3 para encontrar o armazem destino. 
//==============================================================
DBSelectArea("SD3")
DBSetOrder(4)//D3_FILIAL+D3_NUMSEQ+D3_CHAVE+D3_COD

If SD3->(DBSeek(cSeekSD3))

	//==============================================================
	// Grava o Nro do Documento no SD3 de Saida - 999.            
	//==============================================================
	RecLock("SD3",.F.)
	SD3->D3_I_DTAP := Date()
	SD3->D3_I_HRAP := Time()
	MSUnLock()

EndIf
	
SD3->(DBSetOrder(nIndSD3))
SD3->(DBGoTo(nRecSD3))

Return
