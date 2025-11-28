/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Xavier        |12/05/2015| Chamado 9551. Exclusão de linha ou todos registros da filial.
Jonathan      |04/05/2020| Chamado 32763. Alterar chamada "MsgBox" para "U_ITMsg".
Lucas Borges  |10/09/2024| Chamado 48465. Removendo warning de compilação.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: AEST026
Autor-------------: Josué Danich Prestes
Data da Criacao---: 25/10/2012
Descrição---------: Cadastro de produtos na tabela do almoxarifado (ZZR)
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AEST026

Local 	_cAlias		:= "ZZR"
Private cCadastro	:= "Cadastro Tabela Almoxarifado"
Private aRotina		:= {}
Private _aCores    	:= { 	{ "ZZR_STATUS == '1'", 'BR_VERMELHO' },;
							{ "ZZR_STATUS == '3'", 'BR_AZUL' },;
                    	  	{ "ZZR_STATUS == '2'", 'BR_VERDE' } }

aAdd(aRotina,{"Pesquisar"	,"AxPesqui",0,1})
aAdd(aRotina,{"Visualizar"	,"AxVisual",0,2})
aAdd(aRotina,{"Incluir"		,"AxInclui",0,3})
aAdd(aRotina,{"Alterar"		,"AxAltera",0,4})
aAdd(aRotina,{"Excluir"		,"U_AEST026A()",0,5})
aAdd(aRotina,{"Legenda"		,"U_AEST026L()",0,6})

mBrowse(6,1,22,75,_cAlias,,,,,, _aCores)

Return

/*
===============================================================================================================================
Programa----------: AEST026
Autor-------------: Josué Danich Prestes
Data da Criacao---: 25/10/2012
Descrição---------: Excluir a linha ou todos os registros da filial do registro posicionado
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AEST026A()

Local _oDlg		:= Nil
Local oButton1	:= Nil
Local oButton2	:= Nil
Local oComboBox1:= Nil
Local cComboBox1:= "1"
Local oSay1		:= Nil
Local nOpca 	:= 0

DEFINE MSDIALOG _oDlg TITLE "Forma de excluir" FROM 000, 000  TO 100, 300 COLORS 0, 16777215 PIXEL
@ 012, 015 Say oSay1 PROMPT "Excluir ?" SIZE 025, 007 OF _oDlg COLORS 0, 16777215 PIXEL
@ 010, 045 MSCOMBOBOX oComboBox1 VAR cComboBox1 ITEMS {"1=Registro atual","2=Registros da filial","3=Documento"} SIZE 072, 010 OF _oDlg COLORS 0, 16777215 PIXEL
DEFINE SBUTTON oButton1 FROM 028, 036 Type 01 OF _oDlg ENABLE ACTION {|| nOpca := 1 , _oDlg:End() }
DEFINE SBUTTON oButton2 FROM 027, 087 Type 02 OF _oDlg ENABLE ACTION { || nOpca := 2 , _oDlg:End() }
ACTIVATE MSDIALOG _oDlg

//Processar rotina
If nOpca = 1 //confirmar
	If cComboBox1 = "2" //excluir todos
		If U_ITMsg("Todos os registros da filial "+ZZR->ZZR_FILIAL+" serão excluidos.","AEST026","Todos os registros da filial "+ZZR->ZZR_FILIAL+" serão excluidos.",3,2,2)
			If U_ITMsg( UsrRetName( RetCodUsr() )+", confirma a exclusão de todos os registros da filial "+ZZR->ZZR_FILIAL+" ?","AEST026",UsrRetName( RetCodUsr() )+", confirma a exclusão de todos os registros da filial "+ZZR->ZZR_FILIAL+" ?",3,2,2)
				MsAguarde({|| sExcluir() },"Excluir registros...")
				
			EndIf
		EndIf
	ElseIf cComboBox1 = "3" //todo o documento
		If U_ITMsg("Todos os registros do documento "+ZZR->ZZR_DOC+" serão excluidos.","AEST026","Todos os registros do documento "+ZZR->ZZR_DOC+" serão excluidos.",3,2,2)
			If U_ITMsg( UsrRetName( RetCodUsr() )+", confirma a exclusão de todos os registros do documento "+ZZR->ZZR_DOC+" ?","AEST026",UsrRetName( RetCodUsr() )+", confirma a exclusão de todos os registros do documento "+ZZR->ZZR_DOC+" ?",3,2,2)
				MsAguarde({|| AEST0026D() },"Excluir registros...")
			EndIf
		EndIf
	Else	
		If U_ITMsg("Apenas o registro posicionado sera excluido.","AEST026","Apenas o registro posicionado sera excluido.",3,2,2)
			RecLock("ZZR",.F.)
			ZZR->(DbDelete())
			ZZR->(MSUnLock())
		EndIf
	EndIf
EndIf
Return .T.

/*
===============================================================================================================================
Programa----------: AEST026
Autor-------------: Josué Danich Prestes
Data da Criacao---: 25/10/2012
Descrição---------: Excluir registros da filial
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function sExcluir()

Local _cFil := ZZR->ZZR_FILIAL

ZZR->(DBSeek(_cFil))
While ZZR->(!Eof()) .And. ZZR->ZZR_FILIAL = _cFil
	MsProcTxt("Processando linha "+ZZR->ZZR_LINHA+" da filial "+_cFil)
	RecLock("ZZR",.F.)
	ZZR->(DbDelete())
	ZZR->(MSUnLock())
	ZZR->(DBSkip())
EndDo

Return .T.

/*
===============================================================================================================================
Programa----------: AEST0026D
Autor-------------: Josué Danich Prestes
Data da Criacao---: 25/10/2012
Descrição---------: 
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AEST0026D

Local _cDoc := ZZR->ZZR_DOC

ZZR->(DBGoTop())

While ZZR->(!Eof()) 
	MsProcTxt("Processando linha "+ZZR->ZZR_LINHA+" da filial "+ZZR->ZZR_DOC)
	
	If _cDoc == ZZR->ZZR_DOC
		RecLock("ZZR",.F.)
		ZZR->(DbDelete())
		ZZR->(MSUnLock())
	EndIf
	ZZR->(DBSkip())
EndDo

Return .T.

/*
===============================================================================================================================
Programa----------: AEST0026L
Autor-------------: Josué Danich Prestes
Data da Criacao---: 25/10/2012
Descrição---------: Legenda
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AEST0026L

Local _aLegenda := {{ "BR_VERMELHO", "Pendente"  },;
   					{ "BR_AZUL",     "Cancelado" },;
                 	{ "BR_VERDE",    "Processado"} }

BRWLEGENDA( "Planilha de Inventario", "Legenda", _aLegenda )

Return .T.
