/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz     |27/04/2017| Chamado 19813. Inclusão da função de Log ITLOGACS().
Lucas Borges  |11/09/2024| Chamado 48465. Removendo warning de compilação.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MEST006
Autor-------------: André Lisboa
Data da Criacao---: 07/07/2014
Descrição---------: Rotina para gerar registros de inventário zerado
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MEST006

Local cPerg    := "MEST006" 
Local oSay1    := Nil
Local oSay3    := Nil
Local oSay4    := Nil
Local oSBTOK   := Nil
Local oSBTPARAM:= Nil
Local sBTCANCEL:= Nil
Static oDlg01  := Nil

Define MsDialog oDlg01 Title "Gera inventário zerado" From 000, 000  TO 300, 600 COLORS 0, 16777215 Pixel

    Define SBUTTON oSBTPARAM From 133, 187 Type 05 Of oDlg01 Enable Action Pergunte(cPerg)
    Define SBUTTON sBTCANCEL From 133, 219 Type 02 Of oDlg01 Enable Action oDLG01:End()
    Define SBUTTON oSBTOK From 133, 253 Type 01 Of oDlg01 Enable Action (OkProc(cPerg),oDLG01:End())
    @ 014, 009 Say oSay1 PROMPT "Esta rotina irá gerar registros no inventário(SB7) com quantidade inventariada = 0(zero)" Size 237, 010 Of oDlg01 COLORS 0, 16777215 Pixel
    @ 031, 008 Say oSay3 PROMPT "Conforme parâmetros, para que os itens não encontrados fisicamente sejam zerados no acerto do inventário." Size 276, 010 Of oDlg01 COLORS 0, 16777215 Pixel
    @ 052, 008 Say oSay8 PROMPT "Caso já exista registro no SB7 para a chave abaixo não será incluído o registro" Size 272, 007 Of oDlg01 COLORS 0, 16777215 Pixel
    @ 062, 008 Say oSay9 PROMPT "B7_FILIAL+B7_COD+B7_LOCAL+B7_DOC+DToS(B7_DATA)" Size 187, 007 Of oDlg01 COLORS 0, 16777215 Pixel
    
    @ 088, 009 Say oSay4 PROMPT "ATENÇÃO ESSE PROCESSO NÃO PODERÁ SER DESFEITO CONFIRA OS PARÂMETROS ATENTAMENTE !!!" Size 276, 010 Of oDlg01 COLORS 0, 16777215 Pixel


  Activate MSDialog oDlg01 Centered
   
Return

/*
===============================================================================================================================
Programa----------: OkProc
Autor-------------: André Lisboa
Data da Criacao---: 07/07/2014
Descrição---------: 
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function OkProc(cPerg)

If Pergunte(cPerg)
   Processa( {|| AjusRun() } )
EndIf

Return

/*
===============================================================================================================================
Programa----------: AjusRun
Autor-------------: André Lisboa
Data da Criacao---: 07/07/2014
Descrição---------: 
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AjusRun()

Local _cTipo := ""

DBSelectArea("SB2")
ProcRegua(RecCount())
SB2->(DBGoTop())
DBSelectArea("SB7")
SB7->(DBSetOrder(4))

While SB2->(!Eof())
   IncProc("Inventariando Produto ... " + SB2->B2_COD)
   _cTipo  := Posicione("SB1",1,xFilial("SB1") + SB2->B2_COD,"B1_TIPO")

   If !(SB2->B2_COD >= MV_PAR07 .And. SB2->B2_COD <= MV_PAR08 .And. _cTipo >= MV_PAR04 .And. _cTipo <= MV_PAR05 .And. SB2->B2_LOCAL >= MV_PAR02 .And. SB2->B2_LOCAL <= MV_PAR03)
      SB2->(DBSkip())
      Loop
   EndIf
      
   If !(SB7->(DBSeek(xFilial("SB2")+SB2->(B2_COD+B2_LOCAL)+MV_PAR06+DToS(MV_PAR01))))
      RecLock("SB7",.T.)
      SB7->B7_FILIAL		:= xFilial("SB2")
      SB7->B7_COD   		:= SB2->B2_COD
      SB7->B7_LOCAL 		:= SB2->B2_LOCAL
      SB7->B7_TIPO  		:= _cTipo
      SB7->B7_DOC   		:= MV_PAR06
      SB7->B7_QUANT 		:= 0
      SB7->B7_QTSEGUM	:= 0
      SB7->B7_DATA   	:= MV_PAR01
      SB7->B7_DTVALID	:= dDataBase
      SB7->B7_STATUS	   := "1"
      SB7->(MSUnLock())
   EndIf
   SB2->(DBSkip())
EndDo

//===============================================================
// Grava log de Inventário Zero.
//=============================================================== 
U_ITLOGACS('MEST006')

FWAlertInfo("Processo finalizado","MEST00601")

Return
