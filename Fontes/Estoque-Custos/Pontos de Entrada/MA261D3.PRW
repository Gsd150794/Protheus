/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz     |31/05/2024| Chamado 46558. Desenvolvimento de melhorias rotina Transf.Produto.Gravação de campos novos. 
Alex Wallauer |12/08/2024| Chamado 48060. Andre. Acerto das gravações dos campos D3_I_MOTTR/D3_I_DSCMT/D3_I_DESTI/ de Transf
			  |			 | Produto Gravação.
Lucas Borges  |13/10/2024| Chamado 48465. Retirada da função de conout
==============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MA261D3
Autor-------------: Wodson Reis Silva
Data da Criacao---: 25/03/2009
Descrição---------: PE executado após gravação da transferência multipla de estoque
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MA261D3()

Local nRecSD3   := SD3->(Recno())
Local nIndSD3   := SD3->(IndexOrd())
Local cSeekSD3  := SD3->D3_FILIAL+SD3->D3_NUMSEQ+"E0"+SD3->D3_COD
Local _cObs     := SD3->D3_I_OBS
Local _cSetor	:= SD3->D3_I_SETOR
Local _cDescTM	:= SD3->D3_I_DSCTM
Local _cTpTRS 	:= SD3->D3_I_TPTRS
Local _cMotTrRef := SD3->D3_I_MOTTR
Local _cDscMTrRf := SD3->D3_I_DSCMT
Local _cDestino  := SD3->D3_I_DESTI

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
	If AllTrim(FUNNAME()) == "AEST011"

		SD3->D3_I_DOC := _cD3IDOC

	EndIf
    If !Empty(_cObs) .And. Empty(SD3->D3_I_OBS)
	   SD3->D3_I_OBS:=_cObs
    EndIf
	If !Empty(_cSetor) .And. Empty(SD3->D3_I_SETOR)
	   SD3->D3_I_SETOR:=_cSetor
    EndIf

	If !Empty(_cTpTRS) .And. Empty(SD3->D3_I_TPTRS)
	   SD3->D3_I_TPTRS:=_cTpTRS
    EndIf

	If !Empty(_cDescTM) .And. Empty(SD3->D3_I_DSCTM)
	   SD3->D3_I_DSCTM:=_cDescTM
    EndIf

	If ! Empty(_cMotTrRef)  .And. Empty(SD3->D3_I_MOTTR)
       SD3->D3_I_MOTTR := _cMotTrRef
	EndIf  
	
	If ! Empty(_cDscMTrRf) .And. Empty(SD3->D3_I_DSCMT) 
       SD3->D3_I_DSCMT := _cDscMTrRf
	EndIf 

	If ! Empty(_cDestino) .And. Empty(SD3->D3_I_DESTI)
       SD3->D3_I_DESTI := _cDestino
	EndIf 

	SD3->D3_I_DTAP := Date()
	SD3->D3_I_HRAP := Time()
	MSUnLock()

    _cTpTRS   := SD3->D3_I_TPTRS
    _cDescTM  := SD3->D3_I_DSCTM
    _cMotTrRef:= SD3->D3_I_MOTTR
    _cDscMTrRf:= SD3->D3_I_DSCMT
    _cDestino := SD3->D3_I_DESTI
	_cObs     := SD3->D3_I_OBS
	_cSetor   := SD3->D3_I_SETOR
	SD3->D3_I_ORIGE	:= FUNNAME()

	
EndIf
	
SD3->(DBSetOrder(nIndSD3))
SD3->(DBGoTo(nRecSD3))

//==============================================================
// Grava o Nro do Documento no SD3 de Entrada - 499.          
//==============================================================
SD3->(RecLock("SD3",.F.))

If AllTrim(FUNNAME()) == "AEST011"
	SD3->D3_I_DOC := _cD3IDOC
EndIf

SD3->D3_I_DTAP := Date()
SD3->D3_I_HRAP := Time()
If !Empty(_cObs) .And. Empty(SD3->D3_I_OBS)
   SD3->D3_I_OBS:=_cObs
EndIf
If !Empty(_cSetor) .And. Empty(SD3->D3_I_SETOR)
   SD3->D3_I_SETOR:=_cSetor
EndIf
If !Empty(_cTpTRS) .And. Empty(SD3->D3_I_TPTRS)
   SD3->D3_I_TPTRS:=_cTpTRS
EndIf
If !Empty(_cDescTM) .And. Empty(SD3->D3_I_DSCTM)
   SD3->D3_I_DSCTM:=_cDescTM
EndIf

If ! Empty(_cMotTrRef)  .And. Empty(SD3->D3_I_MOTTR)
   SD3->D3_I_MOTTR := _cMotTrRef
EndIf  
If ! Empty(_cDscMTrRf) .And. Empty(SD3->D3_I_DSCMT) 
   SD3->D3_I_DSCMT := _cDscMTrRf
EndIf 
If ! Empty(_cDestino) .And. Empty(SD3->D3_I_DESTI)
   SD3->D3_I_DESTI := _cDestino
EndIf 

SD3->D3_I_ORIGE	:= FUNNAME()

SD3->(MSUnLock())
	

If isincallstack("U_AGLT003G")

    cSeekSD3:= SD3->D3_FILIAL+SD3->D3_NUMSEQ+"E0"
	RecLock("SD3",.F.)
	SD3->D3_CHAVEF1 := "AGLT003" + _eccod+cSetor
	SD3->(MSUnLock())
	SD3->(DBSetOrder(4))//D3_FILIAL+D3_NUMSEQ+D3_CHAVE+D3_COD
	If SD3->(DBSeek(cSeekSD3))
	
		RecLock("SD3",.F.)
		SD3->D3_CHAVEF1 := "AGLT003" + _eccod+cSetor
		SD3->(MSUnLock())
		
	EndIf
	
	SD3->(DBSetOrder(nIndSD3))
	SD3->(DBGoTo(nRecSD3))
	
EndIf			

If isincallstack("MT103TRANC") .Or. isincallstack("MT103TRANS")

	RecLock("SD3",.F.)
	SD3->D3_CHAVEF1 := SF1->F1_DOC+SF1->F1_SERIE+SF1->F1_FORNECE+SF1->F1_LOJA+SF1->F1_TIPO 
	SD3->(MSUnLock())
	SD3->(DBSetOrder(4))//D3_FILIAL+D3_NUMSEQ+D3_CHAVE+D3_COD
	If SD3->(DBSeek(cSeekSD3))
	
		RecLock("SD3",.F.)
		SD3->D3_CHAVEF1 := SF1->F1_DOC+SF1->F1_SERIE+SF1->F1_FORNECE+SF1->F1_LOJA+SF1->F1_TIPO 
		SD3->(MSUnLock())
		
	EndIf
	
	SD3->(DBSetOrder(nIndSD3))
	SD3->(DBGoTo(nRecSD3))

EndIf

If isincallstack("MCOM4Trans") .Or. isincallstack("MCOM4DesTrans")
    cSeekSD3:= SD3->D3_FILIAL+SD3->D3_NUMSEQ+"E0"
	RecLock("SD3",.F.)
	SD3->D3_CHAVEF1 := "MCOM004" + _cChavePC + SF1->F1_DOC+SF1->F1_SERIE
	SD3->(MSUnLock())
	SD3->(DBSetOrder(4))//D3_FILIAL+D3_NUMSEQ+D3_CHAVE+D3_COD
	
	If SD3->(DBSeek(cSeekSD3))
	
		RecLock("SD3",.F.)
		SD3->D3_CHAVEF1 := "MCOM004" + _cChavePC + SF1->F1_DOC+SF1->F1_SERIE
		SD3->(MSUnLock())
		
	EndIf
	
	SD3->(DBSetOrder(nIndSD3))
	SD3->(DBGoTo(nRecSD3))
	
EndIf			

Return
