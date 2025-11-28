/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |17/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25
Lucas Borges  |27/05/2025| Chamado 50617. Revisões diversas visando padronizar os fontes
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: ACOM031
Autor-------------: Frederico O. C. Jr
Data da Criacao---: 11/04/2009
Descrição---------: Tela para amarrar Transportadora no Pedido de Compra
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ACOM031

Local aArea		:= FwGetArea() As Array
Local cCodigo	:= Space(6) As Character
Local cLoja	 	:= Space(4) As Character
Local cNome	 	:= Space(40) As Character
Local aItens	:= {"Entregar na Transportadora","Solicitar Coleta pela Transportadora"} As Array
Local oBtnCon	:= Nil As Object
Local oBtnOut	:= Nil As Object
Local oDlg 		:= Nil As Object
Local cSel	:= "Entregar na Transportadora" As Character

DEFINE MSDIALOG oDlg TITLE "Transportadora do Pedido de Compra" FROM C(249),C(313) TO C(390),C(680) PIXEL

	@ C(010),C(007) Say "Codigo:"							   						   		Size C(020),C(008) PIXEL OF oDlg
	@ C(008),C(030) MsGet cCodigo	F3 "SA2_03";
		Valid ((SubStr(cCodigo,1,1) == "T" .And. existCpo("SA2",cCodigo)) .Or. (cCodigo == Space(6) .And. cLoja == Space(4)) );
		When {|| cNome := Posicione("SA2",1,xFilial("SA2")+cCodigo,"SA2->A2_NOME") }		Size C(042),C(009) PIXEL OF oDlg

	@ C(010),C(092) Say "Loja:"								   			   			   		Size C(013),C(008) PIXEL OF oDlg
	@ C(008),C(105) MsGet cLoja;	
		Valid ((SubStr(cCodigo,1,1) == "T" .And. existCpo("SA2",cCodigo+cLoja)) .Or. (cCodigo == Space(6) .And. cLoja == Space(4)) );
		When {|| cNome := Posicione("SA2",1,xFilial("SA2")+cCodigo+cLoja,"SA2->A2_NOME") }	Size C(022),C(009) PIXEL OF oDlg

	@ C(025),C(007) Say "Razão Social:"									   			   		Size C(035),C(008) PIXEL OF oDlg
	@ C(023),C(042) MsGet cNome 					WHEN .F.			   			 		Size C(134),C(009) PIXEL OF oDlg

	@ C(040),C(007) Say "Obs. Frete:"									   			   		Size C(035),C(008) PIXEL OF oDlg
	@ C(038),C(042) Combobox cSel 					ITEMS aItens 							SIZE C(134),C(009) PIXEL OF oDlg
	
	@ C(055),C(105) BUTTON oBtnCon PROMPT "&Confirmar" SIZE 38,11 PIXEL ACTION (GrvTrans(cCodigo,cLoja,cSel), oDlg:End())
	@ C(055),C(050) BUTTON oBtnOut PROMPT "&Cancelar" SIZE 38,11 PIXEL ACTION oDlg:End()

ACTIVATE MSDIALOG oDlg CENTERED

FwRestArea(aArea)
	
Return

/*
===============================================================================================================================
Programa----------: C
Autor-------------: Frederico O. C. Jr
Data da Criacao---: 04/04/2009
Descrição---------: Funcao para o posicionamento de tela
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function C(nTam)                                                         

Local nHRes	:=	oMainWnd:nClientWidth As Numeric	// Resolucao horizontal do monitor

If nHRes == 640	// Resolucao 640x480 (soh o Ocean e o Classic aceitam 640)
	nTam *= 0.8
ElseIf (nHRes == 798).Or.(nHRes == 800)	// Resolucao 800x600
	nTam *= 1
Else	// Resolucao 1024x768 e acima
	nTam *= 1.28
EndIf
																			
//³Tratamento para tema "Flat"³
If "MP8" $ oApp:cVersion
	If (AllTrim(GetTheme()) == "FLAT") .Or. SetMdiChild()
		nTam *= 0.90
	EndIf
EndIf

Return Int(nTam)

/*
===============================================================================================================================
Programa----------: GrvTrans
Autor-------------: Frederico O. C. Jr
Data da Criacao---: 04/04/2009
Descrição---------: Funcao para gravar transportadora em todas as linhas do pedido de compra
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function GrvTrans(cCodigo As Character, cLoja As Character, cFrete As Character)

Local _cFilial := SC7->C7_FILIAL As Character
Local cPedido := SC7->C7_NUM As Character

SC7->(DBSetOrder(1))
SC7->(DBSeek(_cFilial+cPedido))

While SC7->(Eof()) .And. (SC7->C7_FILIAL == _cFilial) .And. (SC7->C7_NUM == cPedido)
	SC7->(RecLock("SC7",.F.))
		SC7->C7_I_CDTRA	:= cCodigo
		SC7->C7_I_LJTRA	:= cLoja
		If cFrete == "Entregar na Transportadora"
			SC7->C7_I_TPFRT	:= "1"
		Else
			SC7->C7_I_TPFRT	:= "2"
		EndIf
	SC7->(MSUnLock())
	SC7->(DBSkip())
EndDo

Return
