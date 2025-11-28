/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz     |07/05/2018| Chamado 24726. Padronização dos cabeçalhos dos fontes e funções do módulo financeiro.
Josué Danich  |26/06/2019| Chamado 28886. Revisão para loboguara
Lucas Borges  |09/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: AFIN015
Autor-------------: Wodson Reis Silva
Data da Criacao---: 28/07/2009
Descrição---------: Consulta F3 personalizada.
                    Lista os Descontos Contratuais que poderao ser utilizados de acordo com o produto + rede ou produto + 
                    cliente escolhido.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AFIN015()

Local aAreaZAE   := ZAE->(GetArea())
Local aStruct    := {}
Local aBrowse1	 := {}
Local aBrowse2	 := {}
Local aBrowse3	 := {}
Local aTitulo1	 := {}
Local aTitulo2	 := {}
Local aTitulo3	 := {}
Local aOrdem	 := {}
Local oMainWnd
Local oDlg
Local oSeek
Local oCol1
Local oCol2
Local oCol3
Local oBrowse1
Local oBrowse2
Local oBrowse3
Local oOrdem
Local cOrd
Local oBtn1
Local oBtn2
Local cRede      := ""
Local cSeek		 := Space(40)
Local cQuery	 := ""
Local cAliasZAZ  := "ZAZ"
Local lExport	 := .F.
Local i			 := 0
Local nSvRecBrw  := 0

//=============================================================================
// Posiciona no cadastro de clientes para pegar a rede. 
//=============================================================================
If !Empty(AllTrim(GdFieldGet("ZAE_CLI",n)))
	DBSelectArea("SA1")
	DBSetOrder(1)
	DBSeek(xFilial("SA1")+GdFieldGet("ZAE_CLI",n)+GdFieldGet("ZAE_LOJA",n))
	cRede := SA1->A1_GRPVEN
EndIf

DBSelectArea("ZAZ")
DBSetOrder(1)

cAliasZAZ:=	GetNextAlias()

//=============================================================================
// Filtra os dados da ZAZ. 
//=============================================================================
cQuery := "SELECT ZAZ_COD,ZAZ_GRPVEN,ZAZ_CLIENT,ZAZ_LOJA,ZAZ_NOME,ZAZ_DTINI,ZB0_SB1COD,ZAZ.R_E_C_N_O_ FROM "
cQuery += RetSqlName("ZAZ")+" ZAZ, "+RetSqlName("ZB0")+" ZB0"
cQuery += " WHERE ZAZ.ZAZ_FILIAL  = '" + xFilial("ZAZ") + "'"
cQuery += " AND ZB0.ZB0_FILIAL  = ZAZ.ZAZ_FILIAL 
cQuery += " AND ZAZ.D_E_L_E_T_  = ' ' AND ZB0.D_E_L_E_T_  = ' '"
cQuery += " AND ZAZ.ZAZ_COD = ZB0.ZB0_COD"
cQuery += " AND ZAZ.ZAZ_MSBLQL  <> '1'"
cQuery += " AND ZAZ.ZAZ_DTINI <= '" + DToS(dDataBase) + "'"
cQuery += " AND ZAZ.ZAZ_DTFIM >= '" + DToS(dDataBase) + "'"
cQuery += " AND ZB0.ZB0_SB1COD  = '" + GdFieldGet("ZAE_PROD",n) + "'"

//=========================================================================================
// Primeiramente verifica se a Rede foi informada, caso tenha sido, filtra pela mesma, 
// caso contrario, filtra pela Rede informada no cadastro do cliente.                  
//=========================================================================================
If !Empty(AllTrim(GdFieldGet("ZAE_GRPVEN",n)))
	cQuery += " AND ZAZ.ZAZ_GRPVEN  = '" + GdFieldGet("ZAE_GRPVEN",n) + "'"
Else
	//=============================================================================
	// Se a rede no cadastro do cliente esta preenchida. 
	//=============================================================================
	If !Empty(AllTrim(cRede))
		//======================================================================================
		// Se a loja foi preenchida, entao faz o filtro pelo codigo de cliente/loja ou rede. 
		//======================================================================================
		If !Empty(AllTrim(GdFieldGet("ZAE_LOJA",n)))
            cQuery += " AND ((ZAZ.ZAZ_CLIENT = '" + GdFieldGet("ZAE_CLI",n) + "' AND ZAZ.ZAZ_LOJA = '" + GdFieldGet("ZAE_LOJA",n) + "') OR  ZAZ.ZAZ_GRPVEN  = '" + cRede + "')"
		Else
			//============================================================================================
			// Se a loja nao foi preenchida, entao desconsidera a mesma no filtro, pega qualquer loja. 
			//============================================================================================
			cQuery += " AND (ZAZ.ZAZ_CLIENT  = '" + GdFieldGet("ZAE_CLI",n) + "' OR ZAZ.ZAZ_GRPVEN  = '" + cRede + "')"
		EndIf
	Else
		//=================================================================================================
		// Se a rede no cadasto do cliente nao foi preenchida, entao faz o filtro pelo codigo de cliente. 
		// Se a loja foi preenchida, entao faz o filtro pelo codigo de cliente e loja.                    
		//=================================================================================================
		If !Empty(AllTrim(GdFieldGet("ZAE_LOJA",n)))
			cQuery += " AND ZAZ.ZAZ_CLIENT  = '" + GdFieldGet("ZAE_CLI",n) + "'"
			cQuery += " AND ZAZ.ZAZ_LOJA    = '" + GdFieldGet("ZAE_LOJA",n) + "'"
		Else
			//============================================================================================
			// Se a loja nao foi preenchida, entao desconsidera a mesma no filtro, pega qualquer loja. 
			//============================================================================================
			cQuery += " AND ZAZ.ZAZ_CLIENT  = '" + GdFieldGet("ZAE_CLI",n) + "'"
		EndIf
	EndIf
EndIf

cQuery += " ORDER BY ZAZ_GRPVEN,ZAZ_CLIENT"
dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasZAZ,.T.,.T.)

//=============================================================================
// Monta arquivo de trabalho para armazenar os registros da ZAZ.          
//=============================================================================
aAdd(aStruct,{"TRB_COD"   ,"C",TamSX3("ZAZ_COD")[1]   ,0})
aAdd(aStruct,{"TRB_GRPVEN","C",TamSX3("ZAZ_GRPVEN")[1],0})
aAdd(aStruct,{"TRB_CLIENT","C",TamSX3("ZAZ_CLIENT")[1],0})
aAdd(aStruct,{"TRB_LOJA"  ,"C",TamSX3("ZAZ_LOJA")[1]  ,0})
aAdd(aStruct,{"TRB_NOME"  ,"C",TamSX3("ZAZ_NOME")[1]  ,0})
aAdd(aStruct,{"TRB_DTINI" ,"D",8                      ,0})
aAdd(aStruct,{"TRB_RECNO" ,"N",14                     ,0})

//================================================================================
// Verifica se ja existe um arquivo com mesmo nome, se sim deleta.
//================================================================================
If Select("TRB") > 0
	TRB->( DBCloseArea() )
EndIf

//================================================================================
// Permite o uso do arquivo criado dentro do protheus.
//================================================================================
_otemp := FWTemporaryTable():New( "TRB", aStruct )

_otemp:AddIndex( "01",{"TRB_COD"} )
_otemp:AddIndex( "02",{"TRB_NOME"} )
_otemp:AddIndex( "03",{"TRB_DTINI"} )

_otemp:Create()

DBSelectArea("TRB")
DBSetOrder(1)

DBSelectArea(cAliasZAZ)
While !Eof()
	
	RecLock("TRB",.T.)
	Replace TRB->TRB_COD    With (cAliasZAZ)->ZAZ_COD
    Replace TRB->TRB_GRPVEN With (cAliasZAZ)->ZAZ_GRPVEN
    Replace TRB->TRB_CLIENT With (cAliasZAZ)->ZAZ_CLIENT
    Replace TRB->TRB_LOJA   With (cAliasZAZ)->ZAZ_LOJA
	Replace TRB->TRB_NOME   With (cAliasZAZ)->ZAZ_NOME
    Replace TRB->TRB_DTINI  With SToD((cAliasZAZ)->ZAZ_DTINI)
	Replace TRB->TRB_RECNO  With (cAliasZAZ)->R_E_C_N_O_    
	TRB->(MSUnLock())
	
	DBSelectArea(cAliasZAZ)
	DBSkip()
EndDo

DBSelectArea("TRB")
TRB->(DBGoTop())

aAdd(aBrowse1,{"TRB_COD"})
aAdd(aBrowse1,{"TRB_GRPVEN"})
aAdd(aBrowse1,{"TRB_CLIENT"})
aAdd(aBrowse1,{"TRB_LOJA"})
aAdd(aBrowse1,{"TRB_NOME"})
aAdd(aBrowse1,{"TRB_DTINI"})

aAdd(aBrowse2,{"TRB_NOME"})
aAdd(aBrowse2,{"TRB_GRPVEN"})
aAdd(aBrowse2,{"TRB_CLIENT"})
aAdd(aBrowse2,{"TRB_LOJA"})
aAdd(aBrowse2,{"TRB_COD"})
aAdd(aBrowse2,{"TRB_DTINI"})

aAdd(aBrowse3,{"TRB_DTINI"})
aAdd(aBrowse3,{"TRB_COD"})
aAdd(aBrowse3,{"TRB_GRPVEN"})
aAdd(aBrowse3,{"TRB_CLIENT"})
aAdd(aBrowse3,{"TRB_LOJA"})
aAdd(aBrowse3,{"TRB_NOME"})

aAdd(aTitulo1,{"Contrato"})
aAdd(aTitulo1,{"Rede"})
aAdd(aTitulo1,{"Cliente"})
aAdd(aTitulo1,{"Loja"})
aAdd(aTitulo1,{"Nome"})
aAdd(aTitulo1,{"Data"})

aAdd(aTitulo2,{"Nome"})
aAdd(aTitulo2,{"Rede"})
aAdd(aTitulo2,{"Cliente"})
aAdd(aTitulo2,{"Loja"})
aAdd(aTitulo2,{"Contrato"})
aAdd(aTitulo2,{"Data"})

aAdd(aTitulo3,{"Data"})
aAdd(aTitulo3,{"Contrato"})
aAdd(aTitulo3,{"Rede"})
aAdd(aTitulo3,{"Cliente"})
aAdd(aTitulo3,{"Loja"})
aAdd(aTitulo3,{"Nome"})

aAdd(aOrdem,"Contrato")
aAdd(aOrdem,"Nome")
aAdd(aOrdem,"Data")

DEFINE MSDIALOG oDlg TITLE OemToAnsi("Descontos Contratuais") OF oMainWnd PIXEL FROM 62,15 TO 455,533

oBrowse1 := VCBrowse():New(31,1,259,152,,,,oDlg,,,,{|| (cSeek := Space(40),oSeek:Refresh())},{ || lExport := .T., nSvRecBrw := Recno(), oDlg:End() }, , , , , , , , ,.T.)
oBrowse1 := oBrowse1:GetBrowse()
oBrowse1:lLineDrag	:= .T.

oBrowse2 := VCBrowse():New(31,1,259,152,,,,oDlg,,,,{|| (cSeek := Space(40),oSeek:Refresh())},{ || lExport := .T., nSvRecBrw := Recno(), oDlg:End() }, , , , , , , , ,.T.)
oBrowse2 := oBrowse2:GetBrowse()
oBrowse2:lLineDrag	:= .T.
oBrowse2:Hide()

oBrowse3 := VCBrowse():New(31,1,259,152,,,,oDlg,,,,{|| (cSeek := Space(40),oSeek:Refresh())},{ || lExport := .T., nSvRecBrw := Recno(), oDlg:End() }, , , , , , , , ,.T.)
oBrowse3 := oBrowse3:GetBrowse()
oBrowse3:lLineDrag	:= .T.
oBrowse3:Hide()

For i:=1 To Len(aBrowse1)
	oCol1 := TCColumn():New( OemToAnsi(aTitulo1[i,1]), &("{ || "+aBrowse1[i,1]+"}"),,,, "LEFT",, .F., .F.,,,, .F., )
	oBrowse1:AddColumn(oCol1)
Next i

For i:=1 To Len(aBrowse2)
	oCol2 := TCColumn():New( OemToAnsi(aTitulo2[i,1]), &("{ || "+aBrowse2[i,1]+"}"),,,, "LEFT",, .F., .F.,,,, .F., )
	oBrowse2:AddColumn(oCol2)
Next i

For i:=1 To Len(aBrowse3)
	oCol3 := TCColumn():New( OemToAnsi(aTitulo3[i,1]), &("{ || "+aBrowse3[i,1]+"}"),,,, "LEFT",, .F., .F.,,,, .F., )
	oBrowse3:AddColumn(oCol3)
Next i

@ 003, 003 COMBOBOX oOrdem VAR cOrd ITEMS aOrdem ON CHANGE ;
(If(oOrdem:nAt==1,(DBSetOrder(1),oBrowse2:Hide()),;
If(oOrdem:nAt==2,(DBSetOrder(2),oBrowse2:Show()),(DBSetOrder(3),oBrowse3:Show()))),;
DBGoTop(),;
oBrowse1:Refresh(),;
oBrowse2:Refresh(),;
oBrowse3:Refresh(),;
cSeek:=Space(40),;
oSeek:Refresh()) SIZE 213, 42 OF oDlg PIXEL                   
                                                       
@ 017,003 MSGET oSeek VAR cSeek SIZE 213, 10 OF oDlg PIXEL
@ 003,220 BUTTON "&Pesquisar" SIZE 037,010 PIXEL OF oDlg ACTION ( ((DBSeek(AllTrim(cSeek)),oBrowse1:Refresh(),oBrowse2:Refresh(),oBrowse3:Refresh()),) )

DEFINE SBUTTON oBtn1 FROM 185,003 Type 1 ENABLE OF oDlg ACTION (lExport := .T., nSvRecBrw := Recno(), oDlg:End())
oBtn1:lAutDisable := .F.
DEFINE SBUTTON oBtn2 FROM 185,033 Type 2 ENABLE OF oDlg ACTION oDlg:End()

ACTIVATE MSDIALOG oDlg CENTERED

//=========================================================
// Posiciona no registro escolhido pelo usuario. 
//=========================================================
If lExport
	ZAZ->(DBGoTo(TRB->TRB_RECNO))
EndIf

//========================================
// Deleta os arquivos temporarios. 
//========================================
DBSelectArea("TRB")
DBCloseArea()

DBSelectArea(cAliasZAZ)
DBCloseArea()

//=====================================
// Restaura a area do sistema. 
//=====================================
FWRestArea(aAreaZAE)
DBSelectArea("ZAZ")
DBSetOrder(1)

Return(lExport)
