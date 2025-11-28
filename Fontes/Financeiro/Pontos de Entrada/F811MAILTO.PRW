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
Programa----------: F811MAILTO
Autor-------------: Alex Wallauer
Data da Criacao---: 22/02/2021
Descrição---------: PE no programa FINA811.PRW - Rotina para envio das cartas de cobranca - CHAMADO 35423
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function F811MAILTO()
Local cGetPara:= AllTrim(SA1->A1_EMAIL)
Local cGetCc  := AllTrim(UsrRetMail(__cUserId))
Local cGetNovo:= Space(1000)
Local nOpcA   := 0
Local nCol    := 50

DEFINE MSDIALOG oDlgMail TITLE "Configuracao do E-Mail do Cliente" FROM 000, 000  TO 200, 650   PIXEL

	//======
	// Para:
	//======
	@ 006, 006 Say oPara PROMPT "E-mail Cliente:" SIZE 045, 007 OF oDlgMail   PIXEL
	@ 005, nCol MSGET cGetPara SIZE 256, 010 OF oDlgMail  PIXEL WHEN .F.

	//===========
	// Com cópia:
	//===========
	@ 022, 006 Say oCc PROMPT "Com Copia:" SIZE 045, 007 OF oDlgMail   PIXEL
	@ 021, nCol MSGET cGetCc SIZE 256, 010 OF oDlgMail  PIXEL WHEN .F.

	//=========
	// E-mail Novo:
	//=========
	@ 038, 006 Say oAssunto PROMPT "E-Mail Novo:" SIZE 045, 007 OF oDlgMail   PIXEL
	@ 037, nCol MSGET cGetNovo SIZE 256, 010 OF oDlgMail  PIXEL VALID U_EEmail( cGetNovo ) 


	@ 055, nCol    BUTTON oButEnv PROMPT "&OK"		SIZE 037, 012 OF oDlgMail ACTION ( nOpcA := 1 , oDlgMail:End() ) PIXEL
	//@ 055, nCol+45 BUTTON oButCan PROMPT "&Manter"  	SIZE 037, 012 OF oDlgMail ACTION ( nOpcA := 0 , oDlgMail:End() ) PIXEL

ACTIVATE MSDIALOG oDlgMail CENTERED

If !Empty(cGetNovo)  .And. nOpcA = 1
   cGetNovo:=AllTrim(cGetNovo)+";"+cGetCc
Else
   cGetNovo:=cGetPara+";"+cGetCc
EndIf

Return cGetNovo

