/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
===============================================================================================================================
Lucas Borges  |17/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25
Lucas Borges  |22/06/2025| Chamado 50617. Revisões diversas visando padronizar os fontes
Alex Wallauer |25/09/2025| Chamado 51698. Nova Validacao do campo C1_I_USOD contra C7_I_USOD para não deixar diferente.
===============================================================================================================================
*/

#Include "TOTVS.ch"

#define	MB_OK			0
#define MB_ICONASTERISK	64

/*
===============================================================================================================================
Programa----------: ACOM035
Autor-------------: Jerry
Data da Criacao---: 26/07/2017
Descrição---------: Rotina para alteração Aplicação Direta 
Parametros--------: _nopc - igual a 1 se For chamado do MT120FIM
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ACOM035(_nopc)

Local aArea			:= FWGetArea() As Array
Local nX			:= 0 As Numeric
Local cQry			:= "" As Character
Local cAliasQry		:= GetNextAlias() As Character
Local aHeader		:= {} As Array
Local aCols			:= {} As Array
Local aFields		:= {"C7_I_USOD","C7_NUM","C7_TIPO","C7_ITEM","C7_NUMSC","C7_ITEMSC","C1_I_USOD","C7_PRODUTO","C7_DESCRI","C7_I_DTFAT","A2_NOME"} As Array
Local nOpc			:= 0 As Numeric
Local oSButton1		:= Nil As Object
Local oSButton2		:= Nil as Object

Default _nopc       := 0

Private oDlg		:= Nil As Object
Private oMSNewSC7	:= Nil As Object

//===============================================================
// Grava log da montagem de menu customizados Pedidos de Compras
//=============================================================== 
U_ITLOGACS('ACOM035')


DBSelectArea("SY1")
SY1->(DBSetOrder(3)) //Y1_FILIAL + Y1_USER

If SY1->(DBSeek(xFilial("SY1") + __cUserId))
   //=============================================================================
   //Montagem do aheader                                                        
   //=============================================================================
   aHeader := {}
   aCols   := {}
   For nX := 1 To Len(aFields)
       _cCampoSX3 := aFields[nX]
       aAdd( aHeader , {   Getsx3cache(_cCampoSX3,"X3_TITULO")  ,;
                           Getsx3cache(_cCampoSX3,"X3_CAMPO")   ,;
                           Getsx3cache(_cCampoSX3,"X3_PICTURE") ,;
                           Getsx3cache(_cCampoSX3,"X3_TAMANHO") ,;
                           Getsx3cache(_cCampoSX3,"X3_DECIMAL") ,;
                           Getsx3cache(_cCampoSX3,"X3_VALID")   ,;
                           Getsx3cache(_cCampoSX3,"X3_USADO")   ,;
                           Getsx3cache(_cCampoSX3,"X3_TIPO")    ,;
                           Getsx3cache(_cCampoSX3,"X3_F3")      ,;
                           Getsx3cache(_cCampoSX3,"X3_CONTEXT")  })
   Next nX
        	
	// Somente sao selecionados itens que nao possuem restricoes
	cQry := "SELECT C7_NUM,C7_TIPO,C7_ITEM,C7_PRODUTO,C7_DESCRI,C7_I_DTFAT,C7_FORNECE,C7_LOJA, "
	cQry += " SC7.R_E_C_N_O_ AS RECSC7,A2_NOME,C7_NUMSC, C7_ITEMSC, C7_I_USOD, C7_NUMSC,C7_ITEMSC "
	cQry += "FROM " + RetSqlName("SC7") + " SC7 "
	cQry += "INNER JOIN " + RetSqlName("SA2") + " SA2 ON A2_FILIAL = '" + xFilial("SA2") + "' AND A2_COD = C7_FORNECE AND A2_LOJA = C7_LOJA AND SA2.D_E_L_E_T_ = ' ' "
	cQry += "WHERE C7_FILIAL = '" + xFilial("SC7") + "' "
	cQry += "  AND C7_NUM = '" + SC7->C7_NUM + "' "
	
	If _nopc == 0
		cQry += "  AND C7_QUJE = 0 "   
		cQry += "  AND C7_RESIDUO <> 'S' " 
		cQry += "  AND NOT EXISTS (SELECT 'Y' FROM " +  RetSqlName("SC7") + " SC7B WHERE SC7B.C7_FILIAL = SC7.C7_FILIAL AND SC7B.C7_NUM = SC7.C7_NUM AND SC7.C7_QUJE <> 0 AND SC7.D_E_L_E_T_ = ' ') "
	EndIf
    cQry += "  AND C7_NUMSC = ' ' " //Só traz itens sem SC pq não pode mais deixar diferente o campo Aplicação Direta da SC

	cQry += "  AND SC7.D_E_L_E_T_ = ' ' "
	cQry := ChangeQuery(cQry)
	MPSysOpenQuery(cQry,cAliasQry)

	(cAliasQry)->( DBGoTop() )

	If !(cAliasQry)->(Eof())
		
		_aStructQry := {}
		aAdd(_aStructQry, {"C7_I_USOD"   ,"C" ,1  ,0})
		aAdd(_aStructQry, {"C7_NUM"   ,"C" ,6  ,0})
		aAdd(_aStructQry, {"C7_TIPO"   ,"N" ,1  ,0})
		aAdd(_aStructQry, {"C7_NUMSC"   ,"C" ,6  ,0})
		aAdd(_aStructQry, {"C7_ITEMSC"   ,"C" ,4  ,0})
		aAdd(_aStructQry, {"C1_I_USOD"   ,"C" ,1  ,0})
		aAdd(_aStructQry, {"C7_PRODUTO"   ,"C" ,20  ,0})
		aAdd(_aStructQry, {"C7_ITEM"   ,"C" ,4  ,0})
		aAdd(_aStructQry, {"C7_DESCRI"   ,"C" ,30  ,0})
		aAdd(_aStructQry, {"C7_I_DTFAT"   ,"C" ,15  ,0})
		aAdd(_aStructQry, {"A2_NOME"   ,"C" ,30  ,0})
		aAdd(_aStructQry, {"RECNO"   ,"N" ,18  ,0})

		//Cria tabela temporária a partir da query
		_oTemp := FWTemporaryTable():New( "TEMP",  _aStructQry )
		_oTemp:Create()
		
		While (cAliasQry)->(!Eof())
	
			RecLock("TEMP",.T.)
			TEMP->C7_I_USOD := (cAliasQry)->C7_I_USOD
			TEMP->C7_NUM := (cAliasQry)->C7_NUM
			TEMP->C7_NUMSC := (cAliasQry)->C7_NUMSC
			TEMP->C7_ITEMSC := (cAliasQry)->C7_ITEMSC
			TEMP->C1_I_USOD := Posicione("SC1",1,xFilial("SC1")+(cAliasQry)->C7_NUMSC+(cAliasQry)->C7_ITEMSC,"C1_I_USOD")
			TEMP->C7_TIPO := (cAliasQry)->C7_TIPO
			TEMP->C7_PRODUTO := (cAliasQry)->C7_PRODUTO
			TEMP->C7_ITEM := (cAliasQry)->C7_ITEM
			TEMP->C7_DESCRI := (cAliasQry)->C7_DESCRI
			TEMP->C7_I_DTFAT := (cAliasQry)->C7_I_DTFAT
			TEMP->A2_NOME := (cAliasQry)->A2_NOME
			TEMP->RECNO := (cAliasQry)->RECSC7

			(cAliasQry)->(DBSkip())
		End

		aCpoBrw := {}
		aAdd(aCpoBrw,{{||IIf(TEMP->C7_I_USOD=="S","Sim","Não")},,"Ap Direta?"})
		aAdd(aCpoBrw,{"C7_NUM",,"Pedido"})
		aAdd(aCpoBrw,{"C7_TIPO",,"Tipo"})
		aAdd(aCpoBrw,{"C7_ITEM",,"Item"})
		aAdd(aCpoBrw,{"C7_NUMSC",,"SC"})
		aAdd(aCpoBrw,{"C7_ITEMSC",,"Item SC"})
		aAdd(aCpoBrw,{{||IIf(TEMP->C1_I_USOD=="S","Sim",IIf(TEMP->C1_I_USOD=="N","Não","   "))},,"Ap Direta SC?"})
		aAdd(aCpoBrw,{"C7_PRODUTO",,"Produto"})
		aAdd(aCpoBrw,{"C7_DESCRI",,"Descrição"})
		aAdd(aCpoBrw,{{|| SToD(TEMP->C7_I_DTFAT)},,"Dt Faturamento"})
		aAdd(aCpoBrw,{"A2_NOME",,"Fornecedor"})

		TEMP->(DBGoTop())
		
		If _nopc == 1 //Se foi chamado do mt120fim a opção de salvar é default no fechamento da tela pelo x
			nopc := 1
		EndIf

		DEFINE MSDIALOG oDlg TITLE "Alterar Aplicação Direta" FROM 000, 000  TO 300, 700 COLORS 0, 16777215 PIXEL
			
			oMSNewSC7:=MsSelect():New("TEMP",,,aCpoBrw,.F.,,{001,002,101, 348},,,oDlg)
         	oMSNewSC7:bAval:= {|| U_ACOM035M() } 
	     	oMSNewSC7:oBrowse:lhasMark    := .T.
	     	oMSNewSC7:oBrowse:lCanAllmark := .T.
	
			DEFINE SBUTTON oSButton1 FROM 129, 142 Type 01 OF oDlg ENABLE ACTION (nOpc := 1, oDlg:End())
		
			If _nopc == 0 //Só pode cancelar se não veio do mt120fim
				DEFINE SBUTTON oSButton2 FROM 129, 175 Type 02 OF oDlg ENABLE ACTION (nOpc := 2, oDlg:End())
			EndIf
		
			@ 129,208 BUTTON "Inverte todos" SIZE 35,10 PIXEL OF oDlg ACTION (U_ACOM035T())
	
		ACTIVATE MSDIALOG oDlg CENTERED
		
		If nOpc == 1

			TEMP->(DBGoTop())
			While !(TEMP->(Eof()))

				BEGIN TRANSACTION

				DBSelectArea("SC7")
				SC7->(DBGoTo(TEMP->RECNO))
   				RecLock("SC7",.F.)
    				Replace SC7->C7_I_USOD With TEMP->C7_I_USOD
				SC7->(MSUnLock())
				
				If !Empty(SC7->C7_NUMSC)
				    DBSelectArea("SC1")
					SC1->(DBSetOrder(1))
					If SC1->(DBSeek(xFilial("SC1") + SC7->C7_NUMSC + SC7->C7_ITEMSC ))
   			   			RecLock("SC1",.F.)
    					Replace SC1->C1_I_USOD With TEMP->C7_I_USOD
			   			SC1->(MSUnLock())
					EndIf                    
				EndIf

				END TRANSACTION

				TEMP->(DBSkip())
			EndDo
			FWAlertSuccess("Aplicação Direta Alterada com sucesso para todos os itens.","ACOM03501")
		EndIf
	Else
	    If _nopc == 0
		  FWAlertInfo('Não tem produto que possa ser alterada o campo "aplicação direta" para esse Pedido. Favor selecionar um pedido com produtos com saldo e sem SC',"ACOM03503")
		EndIf
	EndIf
	
	(cAliasQry)->( DBCloseArea() )
	
	If Select("TEMP")
		TEMP->( DBCloseArea() )
	EndIf
Else
    If _nopc == 0
	FWAlertWarning("O usuário: " + cUserName + " não possui acesso para utilizar esta rotina. "+;
				"Verifique o cadastro deste usuário como comprador.","ACOM03504")
    EndIf
EndIf

FWRestArea(aArea)
Return    

/*
===============================================================================================================================
Programa----------: ACOM035M
Autor-------------: Josué Danich
Data da Criacao---: 01/03/2019
Descrição---------: Altera linha de aplicação direta
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ACOM035M

Local _copc := "" As Character

If TEMP->C7_I_USOD == "S"
	_copc := "N"
Else
	_copc := "S"
EndIf

RecLock("TEMP",.F.)
TEMP->C7_I_USOD := _copc
TEMP->(MSUnLock())

oMSNewSC7:oBrowse:Refresh()

Return

/*
===============================================================================================================================
Programa----------: ACOM035T
Autor-------------: Josué Danich
Data da Criacao---: 01/03/2019
Descrição---------: Altera todas as linhas de aplicação direta
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ACOM035T

Local _copc := "" As Character

TEMP->(DBGoTop())

While !(TEMP->(Eof()))
	If TEMP->C7_I_USOD == "S"
		_copc := "N"
	Else
		_copc := "S"
	EndIf

	RecLock("TEMP",.F.)
	TEMP->C7_I_USOD := _copc
	TEMP->(MSUnLock())

	TEMP->(DBSkip())
EndDo

TEMP->(DBGoTop())
oMSNewSC7:oBrowse:Refresh()

Return
