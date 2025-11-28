/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |09/10/2024| Chamado 48465. Retirada da função de conout
Lucas Borges  |21/05/2025| Chamado 50617. Corrigir chamada estática no nome das tabelas do sistema
Lucas Borges  |17/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "RPTDEF.CH"
#Include "FONT.CH"

#define	MB_OK				0
#define MB_ICONASTERISK		64

/*
===============================================================================================================================
Programa----------: ACOM017
Autor-------------: Darcio Ribeiro Sporl
Data da Criacao---: 25/04/2016
Descrição---------: Rotina responsavel pelo Monitor de Compras
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ACOM017()

Local cAlias		:= "ZY1"
Local aCores 		:=	{	{'ZY1_DTFAT - Date() >= 15 .And. ZY1_ENCMON <> "S"'									, 'BR_VERDE'	},;
							{'ZY1_DTFAT - Date() >= 10 .And. ZY1_DTFAT - Date() <= 14 .And. ZY1_ENCMON <> "S"'	, 'BR_AMARELO'	},;
							{'ZY1_DTFAT - Date() <= 9 .And. ZY1_ENCMON <> "S"' 									, 'BR_VERMELHO'	},;
							{'ZY1_ENCMON == "S"', 'BR_BRANCO'	} }

Private _cFiltro	:= ""

Private cCadastro	:= ""
Private aRotina		:= MenuDef()
Private nMaxGravado := 0

If !Pergunte('ACOM017A',.T.)
     Return
EndIf

//======================================================================
// Grava log de acesso ao cadastro de monitoramento de Pedido de Compras 
//====================================================================== 
U_ITLOGACS('ACOM017')

//======================================================================
// Exibe o Browser principal da rotina.
//======================================================================
If MV_PAR01 == 2
	_cFiltro := " ZY1_ENCMON <> 'S' "
EndIf

cCadastro	:= "Monitoramento Pedido de Compras"
DBSelectArea(cAlias)
(cAlias)->(DBSetOrder(1))
mBrowse( 6, 1,22,75,cAlias,,,,,,aCores,,,,,,,,_cFiltro)

Return

/*
===============================================================================================================================
Programa----------: ACOM017
Autor-------------: Darcio Ribeiro Sporl
Data da Criacao---: 25/04/2016
Descrição---------: Rotina responsavel pela criação das opções de menu
Parametros--------: Nenhum
Retorno-----------: aRotina = Array com as opções de menu.
===============================================================================================================================
*/
Static Function MenuDef()

Private aRotina	:=  {	{"Pesquisar"		,"AxPesqui"		, 0, 1, 0, .F.},;
						{"Visualizar"		,"U_ACOM017Z()"	, 0, 2, 0, nil},;
						{"Incluir"			,"U_ACOM017I()" , 0, 3, 0, nil},;
						{"Alterar"			,"U_ACOM017A()"	, 0, 4, 0, .F.},;
						{"Notas"			,"U_A017PLA()"	, 0, 2, 0, .F.},;
						{"E-mail"			,"U_ACOM017E()"	, 0, 2, 0, .F.},;
						{"Encerra Monit."	,"U_A017ENC()"	, 0, 2, 0, .F.},;
						{"Alt.Dt.Fat.PC"	,"U_A017DTFT(,ZY1->ZY1_NUMPC)", 0, 2, 0, .F.},;
						{"Legenda"			,"U_A017LEG"	, 0, 2, 0, .F.} }

Return (aRotina)

/*
===============================================================================================================================
Programa----------: ACOM017Z
Autor-------------: Darcio Ribeiro Sporl
Data da Criacao---: 25/04/2016
Descrição---------: Função de Visualização de registros
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ACOM017Z()
Local _oSayFO
Local _oGetFO
Local _cGetFO := Space(60)

Local _oSayFR
Local _oGetFR
Local _cGetFR := Space(9)

Local _oSayNE
Local _oGetNE
Local _dGetNE := SToD("")

Local _oSayNF
Local _oGetNF
Local _cGetNF := Space(60)

Local _oSayOR
Local _oGetOR
Local _cGetOR := Space(40)

Local _oSayPC
Local _oGetPC

Local _oSaySC
Local _oGetSC
Local _cGetSC := Space(TamSX3("C1_NUM")[1])

Local _oSaySP
Local _oGetSP
Local _cGetSP := Space(60)

Local _oSayVL
Local _oGetVL
Local _nGetVL := 0

Local _aPosObj	:= {}
Local _aObjects	:= {}
Local _aSize	:= {}
Local _aPosGet	:= {}
Local _aInfo	:= {}

Local _nX		:= 0
Local _nOpca	:= 0

Private _oSayEE
Private _oGetEE
Private _dGetEE := SToD("")

Private _cGetPC := ZY1->ZY1_NUMPC

Private _aTELA[0][0]
Private _aGETS[0]

Private _aHeader		:= {}
Private _aCols			:= {}
Private _aFieldFill		:= {}
Private _aFields		:= {"ZY1_SEQUEN","ZY1_DTMONI","ZY1_HRMONI","ZY1_COMENT","ZY1_CODUSR","ZY1_NOMUSR"}
Private _aAlterFields	:= {"ZY1_COMENT"}

Private _oMSNewGeZY1
Private _oDlg

//popula aheader
aAdd(_aHeader,   {"Sequencia"    ,"ZY1_SEQUEN"," ",4,0," "," ","C"," "," "})
aAdd(_aHeader,   {"Dt Monitoram" ,"ZY1_DTMONI"," ",8,0," "," ","D"," "," "})
aAdd(_aHeader,   {"Hr Monitoram" ,"ZY1_HRMONI"," ",5,0," "," ","C"," "," "})
aAdd(_aHeader,   {"Comentario"   ,"ZY1_COMENT"," ",200,0," "," ","C"," "," "})
aAdd(_aHeader,   {"Cod Usuario"  ,"ZY1_CODUSR"," ",6,0," "," ","C"," "," "})
aAdd(_aHeader,   {"Nome Usuario" ,"ZY1_NOMUSR"," ",40,0," "," ","C"," "," "})

U_ACOM017V(_cGetPC,@_cGetSC,@_cGetNF,@_dGetNE,@_cGetFR,@_nGetVL,@_cGetFO,@_cGetOR,@_cGetSP,@_dGetEE)

_cQryZY1 := "SELECT ZY1_SEQUEN, ZY1_DTMONI, ZY1_HRMONI, ZY1_COMENT, ZY1_CODUSR, ZY1_NOMUSR "
_cQryZY1 += "FROM " + RetSqlName("ZY1") + " "
_cQryZY1 += "WHERE ZY1_FILIAL = '" + xFilial("ZY1") + "' "
_cQryZY1 += "  AND ZY1_NUMPC = '" + _cGetPC + "' "
_cQryZY1 += "  AND D_E_L_E_T_ = ' ' "
_cQryZY1 := ChangeQuery(_cQryZY1)

MPSysOpenQuery(_cQryZY1,"TRBZY1")

DBSelectArea("TRBZY1")
TRBZY1->(DBGoTop())

If !TRBZY1->(Eof())

   A017GrvaCols()

Else
	For _nX := 1 To Len(_aFields)
		If _aFields[_nX] == "ZY1_SEQUEN"
			aAdd(_aFieldFill, "0001")
		Else
			aAdd(_aFieldFill, CriaVar(_aFields[_nX]))
		EndIf
	Next _nX
	aAdd(_aFieldFill, .F.)
	aAdd(_aCols, _aFieldFill)
EndIf

TRBZY1->(DBCloseArea())

_aSize    := MsAdvSize()
_aObjects := {}

aAdd( _aObjects, { 100, 100, .T., .T. } )
aAdd( _aObjects, { 100, 100, .T., .T. } )
aAdd( _aObjects, { 100, 015, .T., .F. } )

_aInfo   := { _aSize[ 1 ],_aSize[ 2 ],_aSize[ 3 ],_aSize[ 4 ],03,03 }
_aPosObj := MsObjSize( _aInfo, _aObjects )
_aPosGet := MsObjGetPos(_aSize[3]-_aSize[1],315,{{003,157,189,236,268}})

DEFINE MSDIALOG _oDlg TITLE "Monitoramento Pedido de Compras" FROM _aSize[7],0 To _aSize[6],_aSize[5] of oMainWnd PIXEL

	@ 035, 002 Say _oSayPC PROMPT "Número PC:" SIZE 031, 007 OF _oDlg COLORS 16711680, 16777215 PIXEL
	@ 047, 002 MSGET _oGetPC VAR _cGetPC SIZE 039, 010 OF _oDlg COLORS 0, 16777215 F3 "SC7" READONLY PIXEL

	@ 035, 066 Say _oSaySC PROMPT "Número Solicitação:" SIZE 050, 007 OF _oDlg COLORS 0, 16777215 PIXEL
	@ 047, 066 MSGET _oGetSC VAR _cGetSC SIZE 039, 010 OF _oDlg COLORS 0, 16777215 READONLY PIXEL

	@ 035, 122 Say _oSayNF PROMPT "Número NF / Vencimento:" SIZE 080, 007 OF _oDlg COLORS 0, 16777215 PIXEL
	@ 047, 122 MSGET _oGetNF VAR _cGetNF SIZE 213, 010 OF _oDlg COLORS 0, 16777215 READONLY PIXEL

	@ 035, 394 Say _oSayNE PROMPT "Dt. Necessidade: " SIZE 055, 007 OF _oDlg COLORS 0, 16777215 PIXEL
	@ 047, 394 MSGET _oGetNE VAR _dGetNE SIZE 040, 010 OF _oDlg COLORS 0, 16777215 PICTURE READONLY PIXEL

	
	@ 035, 450 Say _oSayEE PROMPT "Dt. Faturamento: " SIZE 055, 007 OF _oDlg COLORS 0, 16777215 PIXEL
	@ 047, 450 MSGET _oGetEE VAR _dGetEE SIZE 040, 010 OF _oDlg COLORS 0, 16777215 PICTURE READONLY PIXEL

	@ 035, 500 Say _oSayFR PROMPT "Tp Frete:" SIZE 025, 007 OF _oDlg COLORS 0, 16777215 PIXEL
	@ 047, 500 MSGET _oGetFR VAR _cGetFR SIZE 030, 010 OF _oDlg COLORS 0, 16777215 READONLY PIXEL

	@ 035, 590 Say _oSayVL PROMPT "Valor: " SIZE 017, 007 OF _oDlg COLORS 0, 16777215 PIXEL
	@ 047, 590 MSGET _oGetVL VAR _nGetVL SIZE 060, 010 OF _oDlg COLORS 0, 16777215 PICTURE PesqPict("SC7","C7_TOTAL") READONLY PIXEL

	@ 063, 002 Say _oSayFO PROMPT "Fornecedor:" SIZE 031, 007 OF _oDlg COLORS 0, 16777215 PIXEL
	@ 075, 002 MSGET _oGetFO VAR _cGetFO SIZE 213, 010 OF _oDlg COLORS 0, 16777215 READONLY PIXEL

	@ 063, 222 Say _oSaySP PROMPT "Obs Pedido de Compras: " SIZE 040, 007 OF _oDlg COLORS 0, 16777215 PIXEL
	@ 075, 222 MSGET _oGetSP VAR _cGetSP SIZE 336, 010 OF _oDlg COLORS 0, 16777215 READONLY PIXEL

	@ 091, 002 Say _oSayOR PROMPT "Origem: " SIZE 020, 007 OF _oDlg COLORS 0, 16777215 PIXEL
	@ 103, 002 MSGET _oGetOR VAR _cGetOR SIZE 118, 010 OF _oDlg COLORS 0, 16777215 READONLY PIXEL

	_oMSNewGeZY1 := MsNewGetDados():New( _aPosGet[1,1] + 115, _aPosGet[1,1] - 5, _aPosGet[1,2] - 15, _aPosGet[1,4] + _aPosGet[1,2] - _aPosObj[2,1] - 10, 0, "AllwaysTrue", "AllwaysTrue", "+ZY1_SEQUEN", _aAlterFields,, 999, "AllwaysTrue", "", "AllwaysTrue", _oDlg, _aHeader, _aCols)

ACTIVATE MSDIALOG _oDlg CENTERED ON INIT EnchoiceBar(_oDlg,{||_nOpca := 1, _oDlg:End()},{||_nOpca := 0, _oDlg:End() })

Return

/*
===============================================================================================================================
Programa----------: ACOM017I
Autor-------------: Darcio Ribeiro Sporl
Data da Criacao---: 25/04/2016
Descrição---------: Função de Inclusão de registros
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ACOM017I()

Local _oSayFO
Local _oGetFO
Local _cGetFO := Space(60)

Local _oSayFR
Local _oGetFR
Local _cGetFR := Space(9)

Local _oSayNE
Local _oGetNE
Local _dGetNE := SToD("")

Local _oSayNF
Local _oGetNF
Local _cGetNF := Space(60)

Local _oSayOR
Local _oGetOR
Local _cGetOR := Space(40)

Local _oSayPC
Local _oGetPC

Local _oSaySC
Local _oGetSC
Local _cGetSC := Space(TamSX3("C1_NUM")[1])

Local _oSaySP
Local _oGetSP
Local _cGetSP := Space(60)

Local _oSayVL
Local _oGetVL
Local _nGetVL := 0

Local _aPosObj	:= {}
Local _aObjects	:= {}
Local _aSize	:= {}
Local _aPosGet	:= {}
Local _aInfo	:= {}

Local _nX		:= 0
Local _nOpca	:= 0

Private _oSayEE
Private _oGetEE
Private _dGetEE := SToD("")

Private _cGetPC := Space(TamSX3("ZY1_NUMPC")[1])

Private _aTELA[0][0]
Private _aGETS[0]

Private _aHeader		:= {}
Private _aCols			:= {}
Private _aFieldFill		:= {}
Private _aFields		:= {"ZY1_SEQUEN","ZY1_DTMONI","ZY1_HRMONI","ZY1_COMENT","ZY1_CODUSR","ZY1_NOMUSR"}
Private _aAlterFields	:= {"ZY1_COMENT"}

Private _oMSNewGeZY1
Private _oDlg

//popula aheader
aAdd(_aHeader,   {"Sequencia"    ,"ZY1_SEQUEN"," ",4,0," "," ","C"," "," "})
aAdd(_aHeader,   {"Dt Monitoram" ,"ZY1_DTMONI"," ",8,0," "," ","D"," "," "})
aAdd(_aHeader,   {"Hr Monitoram" ,"ZY1_HRMONI"," ",5,0," "," ","C"," "," "})
aAdd(_aHeader,   {"Comentario"   ,"ZY1_COMENT"," ",200,0," "," ","C"," "," "})
aAdd(_aHeader,   {"Cod Usuario"  ,"ZY1_CODUSR"," ",6,0," "," ","C"," "," "})
aAdd(_aHeader,   {"Nome Usuario" ,"ZY1_NOMUSR"," ",40,0," "," ","C"," "," "})

// Define field values
For _nX := 1 To Len(_aFields)
	If _aFields[_nX] == "ZY1_SEQUEN"
		aAdd(_aFieldFill, "0001")
	Else
		aAdd(_aFieldFill, CriaVar(_aFields[_nX]))
	EndIf
Next _nX
aAdd(_aFieldFill, .F.)
aAdd(_aCols, _aFieldFill)

_aSize    := MsAdvSize()
_aObjects := {}

aAdd( _aObjects, { 100, 100, .T., .T. } )
aAdd( _aObjects, { 100, 100, .T., .T. } )
aAdd( _aObjects, { 100, 015, .T., .F. } )

_aInfo   := { _aSize[ 1 ],_aSize[ 2 ],_aSize[ 3 ],_aSize[ 4 ],03,03 }
_aPosObj := MsObjSize( _aInfo, _aObjects )
_aPosGet := MsObjGetPos(_aSize[3]-_aSize[1],315,{{003,157,189,236,268}})

DEFINE MSDIALOG _oDlg TITLE "Monitoramento Pedido de Compras" FROM _aSize[7],0 To _aSize[6],_aSize[5] of oMainWnd PIXEL

	@ 035, 002 Say _oSayPC PROMPT "Número PC:" SIZE 031, 007 OF _oDlg COLORS 16711680, 16777215 PIXEL
	@ 047, 002 MSGET _oGetPC VAR _cGetPC SIZE 039, 010 OF _oDlg COLORS 0, 16777215 F3 "SC7" VALID U_ACOM017V(_cGetPC,@_cGetSC,@_cGetNF,@_dGetNE,@_cGetFR,@_nGetVL,@_cGetFO,@_cGetOR,@_cGetSP,@_dGetEE) PIXEL

	@ 035, 066 Say _oSaySC PROMPT "Número Solicitação:" SIZE 050, 007 OF _oDlg COLORS 0, 16777215 PIXEL
	@ 047, 066 MSGET _oGetSC VAR _cGetSC SIZE 039, 010 OF _oDlg COLORS 0, 16777215 READONLY PIXEL

	@ 035, 122 Say _oSayNF PROMPT "Número NF / Vencimento:" SIZE 080, 007 OF _oDlg COLORS 0, 16777215 PIXEL
	@ 047, 122 MSGET _oGetNF VAR _cGetNF SIZE 213, 010 OF _oDlg COLORS 0, 16777215 READONLY PIXEL

	@ 035, 394 Say _oSayNE PROMPT "Dt. Necessidade: " SIZE 055, 007 OF _oDlg COLORS 0, 16777215 PIXEL
	@ 047, 394 MSGET _oGetNE VAR _dGetNE SIZE 040, 010 OF _oDlg COLORS 0, 16777215 PICTURE READONLY PIXEL
	
	@ 035, 450 Say _oSayEE PROMPT "Dt. Faturamento: " SIZE 055, 007 OF _oDlg COLORS 0, 16777215 PIXEL
	@ 047, 450 MSGET _oGetEE VAR _dGetEE SIZE 040, 010 OF _oDlg COLORS 0, 16777215 PICTURE READONLY PIXEL

	@ 035, 500 Say _oSayFR PROMPT "Tp Frete:" SIZE 025, 007 OF _oDlg COLORS 0, 16777215 PIXEL
	@ 047, 500 MSGET _oGetFR VAR _cGetFR SIZE 030, 010 OF _oDlg COLORS 0, 16777215 READONLY PIXEL

	@ 035, 590 Say _oSayVL PROMPT "Valor: " SIZE 017, 007 OF _oDlg COLORS 0, 16777215 PIXEL
	@ 047, 590 MSGET _oGetVL VAR _nGetVL SIZE 060, 010 OF _oDlg COLORS 0, 16777215 PICTURE PesqPict("SC7","C7_TOTAL") READONLY PIXEL

	@ 063, 002 Say _oSayFO PROMPT "Fornecedor:" SIZE 031, 007 OF _oDlg COLORS 0, 16777215 PIXEL
	@ 075, 002 MSGET _oGetFO VAR _cGetFO SIZE 213, 010 OF _oDlg COLORS 0, 16777215 READONLY PIXEL

	@ 063, 222 Say _oSaySP PROMPT "Obs Pedido de Compras: " SIZE 040, 007 OF _oDlg COLORS 0, 16777215 PIXEL
	@ 075, 222 MSGET _oGetSP VAR _cGetSP SIZE 336, 010 OF _oDlg COLORS 0, 16777215 READONLY PIXEL

	@ 091, 002 Say _oSayOR PROMPT "Origem: " SIZE 020, 007 OF _oDlg COLORS 0, 16777215 PIXEL
	@ 103, 002 MSGET _oGetOR VAR _cGetOR SIZE 118, 010 OF _oDlg COLORS 0, 16777215 READONLY PIXEL

	_oMSNewGeZY1 := MsNewGetDados():New( _aPosGet[1,1] + 115, _aPosGet[1,1] - 5, _aPosGet[1,2] - 15, _aPosGet[1,4] + _aPosGet[1,2] - _aPosObj[2,1] - 10, GD_INSERT+GD_UPDATE, "U_A017LOK()", "U_A017TOK()", "+ZY1_SEQUEN", _aAlterFields,, 999, "AllwaysTrue", "", "AllwaysTrue", _oDlg, _aHeader, _aCols)

ACTIVATE MSDIALOG _oDlg CENTERED ON INIT EnchoiceBar(_oDlg,{||_nOpca := 1, _oDlg:End()},{||_nOpca := 0, _oDlg:End() }) VALID U_A017TOK()

If _nOpca == 1
	Begin Transaction
		For _nX := 1 To Len(_oMSNewGeZY1:aCols)
			If !_oMSNewGeZY1:aCols[_nX, Len(_oMSNewGeZY1:aHeader) + 1]
				RecLock("ZY1", .T.)
					Replace ZY1->ZY1_FILIAL	With xFilial("ZY1")
					Replace ZY1->ZY1_NUMPC	With _cGetPC
					Replace ZY1->ZY1_SEQUEN	With _oMSNewGeZY1:aCols[_nX, aScan(_oMSNewGeZY1:aHeader,{|x| AllTrim(x[2]) == "ZY1_SEQUEN"})]
					Replace ZY1->ZY1_DTMONI	With _oMSNewGeZY1:aCols[_nX, aScan(_oMSNewGeZY1:aHeader,{|x| AllTrim(x[2]) == "ZY1_DTMONI"})]
					Replace ZY1->ZY1_HRMONI	With _oMSNewGeZY1:aCols[_nX, aScan(_oMSNewGeZY1:aHeader,{|x| AllTrim(x[2]) == "ZY1_HRMONI"})]
					Replace ZY1->ZY1_COMENT	With _oMSNewGeZY1:aCols[_nX, aScan(_oMSNewGeZY1:aHeader,{|x| AllTrim(x[2]) == "ZY1_COMENT"})]
					Replace ZY1->ZY1_CODUSR	With _oMSNewGeZY1:aCols[_nX, aScan(_oMSNewGeZY1:aHeader,{|x| AllTrim(x[2]) == "ZY1_CODUSR"})]
					Replace ZY1->ZY1_NOMUSR	With _oMSNewGeZY1:aCols[_nX, aScan(_oMSNewGeZY1:aHeader,{|x| AllTrim(x[2]) == "ZY1_NOMUSR"})]
					Replace ZY1->ZY1_DTNECE With _dGetNE
					Replace ZY1->ZY1_DTFAT With _dGetEE
				MSUnLock()
			EndIf
		Next
	End Transaction
EndIf

Return

/*
===============================================================================================================================
Programa----------: ACOM017A
Autor-------------: Darcio Ribeiro Sporl
Data da Criacao---: 25/04/2016 
Descrição---------: Função de Alteração de registros
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ACOM017A()

Local _oSayFO
Local _oGetFO
Local _cGetFO := Space(60)

Local _oSayFR
Local _oGetFR
Local _cGetFR := Space(9)

Local _oSayNE
Local _oGetNE
Local _dGetNE := SToD("")

Local _oSayNF
Local _oGetNF
Local _cGetNF := Space(60)

Local _oSayOR
Local _oGetOR
Local _cGetOR := Space(40)

Local _oSayPC
Local _oGetPC

Local _oSaySC
Local _oGetSC
Local _cGetSC := Space(TamSX3("C1_NUM")[1])

Local _oSaySP
Local _oGetSP
Local _cGetSP := Space(60)

Local _oSayVL
Local _oGetVL
Local _nGetVL := 0

Local _aPosObj	:= {}
Local _aObjects	:= {}
Local _aSize	:= {}
Local _aPosGet	:= {}
Local _aInfo	:= {}

Local _nX		:= 0
Local _nOpca	:= 0

Private _oSayEE
Private _oGetEE
Private _dGetEE := SToD("")

Private _cGetPC := ZY1->ZY1_NUMPC

Private _aTELA[0][0]
Private _aGETS[0]

Private _aHeader		:= {}
Private _aCols			:= {}
Private _aFieldFill		:= {}
Private _aFields		:= {"ZY1_SEQUEN","ZY1_DTMONI","ZY1_HRMONI","ZY1_COMENT","ZY1_CODUSR","ZY1_NOMUSR"}
Private _aAlterFields	:= {"ZY1_COMENT"}

Private _oMSNewGeZY1
Private _oDlg

If ZY1->ZY1_ENCMON == "S"
	U_ITMsg('Foi encerrado o monitoramento deste pedido, sendo assim este não pode ser alterado.',"Atenção",,1)
	Return
EndIf

//popula aheader
aAdd(_aHeader,   {"Sequencia"    ,"ZY1_SEQUEN"," ",4,0," "," ","C"," "," "})
aAdd(_aHeader,   {"Dt Monitoram" ,"ZY1_DTMONI"," ",8,0," "," ","D"," "," "})
aAdd(_aHeader,   {"Hr Monitoram" ,"ZY1_HRMONI"," ",5,0," "," ","C"," "," "})
aAdd(_aHeader,   {"Comentario"   ,"ZY1_COMENT"," ",200,0," "," ","C"," "," "})
aAdd(_aHeader,   {"Cod Usuario"  ,"ZY1_CODUSR"," ",6,0," "," ","C"," "," "})
aAdd(_aHeader,   {"Nome Usuario" ,"ZY1_NOMUSR"," ",40,0," "," ","C"," "," "})

U_ACOM017V(_cGetPC,@_cGetSC,@_cGetNF,@_dGetNE,@_cGetFR,@_nGetVL,@_cGetFO,@_cGetOR,@_cGetSP,@_dGetEE)

_cQryZY1 := "SELECT ZY1_SEQUEN, ZY1_DTMONI, ZY1_HRMONI, ZY1_COMENT, ZY1_CODUSR, ZY1_NOMUSR "
_cQryZY1 += "FROM " + RetSqlName("ZY1") + " "
_cQryZY1 += "WHERE ZY1_FILIAL = '" + xFilial("ZY1") + "' "
_cQryZY1 += "  AND ZY1_NUMPC = '" + _cGetPC + "' "
_cQryZY1 += "  AND D_E_L_E_T_ = ' ' "
_cQryZY1 := ChangeQuery(_cQryZY1)

MPSysOpenQuery(_cQryZY1,"TRBZY1")

DBSelectArea("TRBZY1")
TRBZY1->(DBGoTop())

If !TRBZY1->(Eof())

   A017GrvaCols()

Else
	// Define field values
	For _nX := 1 To Len(_aFields)
		If _aFields[_nX] == "ZY1_SEQUEN"
			aAdd(_aFieldFill, "0001")
		Else
			aAdd(_aFieldFill, CriaVar(_aFields[_nX]))
		EndIf
	Next _nX
	aAdd(_aFieldFill, .F.)
	aAdd(_aCols, _aFieldFill)
EndIf

TRBZY1->(DBCloseArea())

_aSize    := MsAdvSize()
_aObjects := {}

aAdd( _aObjects, { 100, 100, .T., .T. } )
aAdd( _aObjects, { 100, 100, .T., .T. } )
aAdd( _aObjects, { 100, 015, .T., .F. } )

_aInfo   := { _aSize[ 1 ],_aSize[ 2 ],_aSize[ 3 ],_aSize[ 4 ],03,03 }
_aPosObj := MsObjSize( _aInfo, _aObjects )
_aPosGet := MsObjGetPos(_aSize[3]-_aSize[1],315,{{003,157,189,236,268}})
_dGetOri := _dGetEE

DEFINE MSDIALOG _oDlg TITLE "Monitoramento Pedido de Compras" FROM _aSize[7],0 To _aSize[6],_aSize[5] of oMainWnd PIXEL

	@ 035, 002 Say _oSayPC PROMPT "Número PC:" SIZE 031, 007 OF _oDlg COLORS 16711680, 16777215 PIXEL
	@ 047, 002 MSGET _oGetPC VAR _cGetPC SIZE 039, 010 OF _oDlg COLORS 0, 16777215 F3 "SC7" READONLY PIXEL

	@ 035, 066 Say _oSaySC PROMPT "Número Solicitação:" SIZE 050, 007 OF _oDlg COLORS 0, 16777215 PIXEL
	@ 047, 066 MSGET _oGetSC VAR _cGetSC SIZE 039, 010 OF _oDlg COLORS 0, 16777215 READONLY PIXEL

	@ 035, 122 Say _oSayNF PROMPT "Número NF / Vencimento:" SIZE 080, 007 OF _oDlg COLORS 0, 16777215 PIXEL
	@ 047, 122 MSGET _oGetNF VAR _cGetNF SIZE 213, 010 OF _oDlg COLORS 0, 16777215 READONLY PIXEL

	@ 035, 394 Say _oSayNE PROMPT "Dt. Necessidade: " SIZE 055, 007 OF _oDlg COLORS 0, 16777215 PIXEL
	@ 047, 394 MSGET _oGetNE VAR _dGetNE SIZE 040, 010 OF _oDlg COLORS 0, 16777215 PICTURE READONLY PIXEL
	
	@ 035, 450 Say _oSayEE PROMPT "Dt. Faturamento: " SIZE 055, 007 OF _oDlg COLORS 0, 16777215 PIXEL
	@ 047, 450 MSGET _oGetEE VAR _dGetEE SIZE 040, 010 OF _oDlg COLORS 0, 16777215 PIXEL

	@ 035, 500 Say _oSayFR PROMPT "Tp Frete:" SIZE 025, 007 OF _oDlg COLORS 0, 16777215 PIXEL
	@ 047, 500 MSGET _oGetFR VAR _cGetFR SIZE 030, 010 OF _oDlg COLORS 0, 16777215 READONLY PIXEL

	@ 035, 590 Say _oSayVL PROMPT "Valor: " SIZE 017, 007 OF _oDlg COLORS 0, 16777215 PIXEL
	@ 047, 590 MSGET _oGetVL VAR _nGetVL SIZE 060, 010 OF _oDlg COLORS 0, 16777215 PICTURE PesqPict("SC7","C7_TOTAL") READONLY PIXEL

	@ 063, 002 Say _oSayFO PROMPT "Fornecedor:" SIZE 031, 007 OF _oDlg COLORS 0, 16777215 PIXEL
	@ 075, 002 MSGET _oGetFO VAR _cGetFO SIZE 213, 010 OF _oDlg COLORS 0, 16777215 READONLY PIXEL

	@ 063, 222 Say _oSaySP PROMPT "Obs Pedido de Compras: " SIZE 040, 007 OF _oDlg COLORS 0, 16777215 PIXEL
	@ 075, 222 MSGET _oGetSP VAR _cGetSP SIZE 336, 010 OF _oDlg COLORS 0, 16777215 READONLY PIXEL

	@ 091, 002 Say _oSayOR PROMPT "Origem: " SIZE 020, 007 OF _oDlg COLORS 0, 16777215 PIXEL
	@ 103, 002 MSGET _oGetOR VAR _cGetOR SIZE 118, 010 OF _oDlg COLORS 0, 16777215 READONLY PIXEL

	_oMSNewGeZY1 := MsNewGetDados():New( _aPosGet[1,1] + 115, _aPosGet[1,1] - 5, _aPosGet[1,2] - 15, _aPosGet[1,4] + _aPosGet[1,2] - _aPosObj[2,1] - 10, GD_INSERT+GD_UPDATE, "U_A017LOK()", "AllwaysTrue", /*"+ZY1_SEQUEN"*/, _aAlterFields,, 999, "AllwaysTrue", "", "AllwaysTrue", _oDlg, _aHeader, _aCols)

ACTIVATE MSDIALOG _oDlg CENTERED ON INIT EnchoiceBar(_oDlg,{||_nOpca := 1, _oDlg:End()},{||_nOpca := 0, _oDlg:End() }) VALID U_A017TOK()

If _nOpca == 1
	Begin Transaction
	
		//Atualiza a data de faturamento
		If _dGetEE != _dGetOri 
		
			U_A017DTFT(_dGetEE,_cGetPC)
			
			//Se só tem uma linha no acols com descrição em branco preenche descrição para registrar mudança de data
			If Len(_oMSNewGeZY1:aCols) == 1 .And. Empty(_oMSNewGeZY1:aCols[1, aScan(_oMSNewGeZY1:aHeader,{|x| AllTrim(x[2]) == "ZY1_COMENT"})])
			
				_oMSNewGeZY1:aCols[1, aScan(_oMSNewGeZY1:aHeader,{|x| AllTrim(x[2]) == "ZY1_COMENT"})] := "Data de faturamento alterada de " + DToC(_dGetOri) + " para " + DToC(_dGetEE)
			
			Else
			   
				aAdd(_oMSNewGeZY1:aCols,{	"",;//StrZero(nMaxGravado,4),;
										Date()			,;
										Time()			,;
										"Data de faturamento alterada de " + DToC(_dGetOri) + " para " + DToC(_dGetEE)				,;
										__cUserId 		,;
										USRFULLNAME(__cUserId),;
										.F. })
															
		
			EndIf
			
		EndIf
	
		DBSelectArea("ZY1")
		ZY1->(DBSetOrder(1))

		For _nX := 1 To Len(_oMSNewGeZY1:aCols)

			If !_oMSNewGeZY1:aCols[_nX, Len(_oMSNewGeZY1:aHeader) + 1]
			
				_cSequen:=_oMSNewGeZY1:aCols[_nX, aScan(_oMSNewGeZY1:aHeader,{|x| AllTrim(x[2]) == "ZY1_SEQUEN"})]
				If !Empty(_cSequen) .And. ZY1->(DBSeek(xFilial("ZY1") + _cGetPC + _cSequen ))
					RecLock("ZY1", .F.)
						Replace ZY1->ZY1_FILIAL	With xFilial("ZY1")
						Replace ZY1->ZY1_NUMPC	With _cGetPC
						Replace ZY1->ZY1_SEQUEN	With _cSequen
						Replace ZY1->ZY1_DTMONI	With _oMSNewGeZY1:aCols[_nX, aScan(_oMSNewGeZY1:aHeader,{|x| AllTrim(x[2]) == "ZY1_DTMONI"})]
						Replace ZY1->ZY1_HRMONI	With _oMSNewGeZY1:aCols[_nX, aScan(_oMSNewGeZY1:aHeader,{|x| AllTrim(x[2]) == "ZY1_HRMONI"})]
						Replace ZY1->ZY1_COMENT	With _oMSNewGeZY1:aCols[_nX, aScan(_oMSNewGeZY1:aHeader,{|x| AllTrim(x[2]) == "ZY1_COMENT"})]
						Replace ZY1->ZY1_CODUSR	With _oMSNewGeZY1:aCols[_nX, aScan(_oMSNewGeZY1:aHeader,{|x| AllTrim(x[2]) == "ZY1_CODUSR"})]
						Replace ZY1->ZY1_NOMUSR	With _oMSNewGeZY1:aCols[_nX, aScan(_oMSNewGeZY1:aHeader,{|x| AllTrim(x[2]) == "ZY1_NOMUSR"})]
					MSUnLock()
				Else
  				    nMaxGravado++
					RecLock("ZY1", .T.)
						Replace ZY1->ZY1_FILIAL	With xFilial("ZY1")
						Replace ZY1->ZY1_NUMPC	With _cGetPC
						Replace ZY1->ZY1_SEQUEN	With StrZero(nMaxGravado,4)
						Replace ZY1->ZY1_DTMONI	With _oMSNewGeZY1:aCols[_nX, aScan(_oMSNewGeZY1:aHeader,{|x| AllTrim(x[2]) == "ZY1_DTMONI"})]
						Replace ZY1->ZY1_HRMONI	With _oMSNewGeZY1:aCols[_nX, aScan(_oMSNewGeZY1:aHeader,{|x| AllTrim(x[2]) == "ZY1_HRMONI"})]
						Replace ZY1->ZY1_COMENT	With _oMSNewGeZY1:aCols[_nX, aScan(_oMSNewGeZY1:aHeader,{|x| AllTrim(x[2]) == "ZY1_COMENT"})]
						Replace ZY1->ZY1_CODUSR	With _oMSNewGeZY1:aCols[_nX, aScan(_oMSNewGeZY1:aHeader,{|x| AllTrim(x[2]) == "ZY1_CODUSR"})]
						Replace ZY1->ZY1_NOMUSR	With _oMSNewGeZY1:aCols[_nX, aScan(_oMSNewGeZY1:aHeader,{|x| AllTrim(x[2]) == "ZY1_NOMUSR"})]
						Replace ZY1->ZY1_DTNECE With _dGetNE
						Replace ZY1->ZY1_DTFAT With _dGetEE
					MSUnLock()
				EndIf
			EndIf
		Next
	End Transaction

    If _dGetEE = _dGetOri 
	   U_ITMsg("Gravação completada com sucesso", "Atenção",,2)
  	Else
       U_ITMsg("Data de Faturamento alterada de " + DToC(_dGetOri) + " para " + DToC(_dGetEE) +" e Gravação completada com sucesso.","Atenção",,2)
	EndIf
EndIf

Return

/*
===============================================================================================================================
Programa----------: ACOM017V
Autor-------------: Darcio Ribeiro Sporl
Data da Criacao---: 25/04/2016 
Descrição---------: Função criada para validação das informações digitadas e carregamentos dos campos do cabeçalho
Parametros--------: _cGetPC - Número do Pedido de Compras
------------------: _cGetSC - Campo que receberá a informação da Solicitação de Compras
------------------: _cGetNF - Campo que receberá a informação da Nota Fiscal de Entrada + Vencimento
------------------: _dGetNE - Campo que receberá a informação da Data de Necessidade
------------------: _dGetEE - Campo que receberá a informação da Data de Faturamento
------------------: _cGetFR - Campo que receberá a informação de Tipo de Frete
------------------: _nGetVL - Campo que receberá a informação de Valor Total do Pedido de Compras
------------------: _cGetFO - Campo que receberá a informação dos dados do Fornecedor
------------------: _cGetOR - Campo que receberá a informação dos dados de Origem (Filial de Origem)
------------------: _cGetSP - Campo que receberá a informação da Observação do Pedido de Compras
------------------: _lCriaAmb	- Indica se foi criado ambiente para JOB ou não
------------------: _cFilial	- Contém a filial do registro
Retorno-----------: _lRet - .T. Contina processo cabeçalho / .F. Não continua processo
===============================================================================================================================
*/
User Function ACOM017V(_cGetPC,_cGetSC,_cGetNF,_dGetNE,_cGetFR,_nGetVL,_cGetFO,_cGetOR,_cGetSP,_dGetEE,_lCriaAmb,_cFilial)

Local _aArea	:= FWGetArea()
Local _lRet		:= .T.
Local _cQrySC7	:= ""
Local _cQrySC1	:= ""
Local _cQrySE2	:= ""

Local _nTotPed	:= 0
Local _dDtNece	:= SToD("")
Local _cTpFret	:= ""
Local _cFornec	:= ""
Local _cLoja	:= ""
Local _dDtFat 	:= SToD("")
Local _cNome	:= ""
Local _cNumSC	:= ""
Local _cNumNF	:= ""
Local _cObsSC	:= ""
Local _nApoio	:= 0
Local _cFilPed	:= ""
Local _nI		:= 0

Default _cGetPC		:= ""
Default _cGetSC		:= ""
Default _cGetNF		:= ""
Default _dGetEE		:= SToD("")
Default _dGetNE		:= SToD("")
Default _cGetFR		:= ""
Default _nGetVL		:= 0
Default _cGetFO		:= ""
Default _cGetOR		:= ""
Default _cGetSP		:= ""
Default _lCriaAmb	:= .F.
Default _cFilial	:= "01"

If Empty(_cGetPC)
	U_ITMsg("Um pedido de compras deve ser selecionado.","Atenção!",,1)
	_lRet := .F.
Else

	_cQrySC7 := "SELECT C7_FILIAL, C7_FORNECE, C7_LOJA, C7_TPFRETE, C7_DATPRF, C7_TOTAL, C7_OBS, A2_NREDUZ, A2_MUN, A2_EST, C7_I_DTFAT "
	_cQrySC7 += "FROM " + RetSqlName("SC7") + " SC7 "
	_cQrySC7 += "JOIN " + RetSqlName("SA2") + " SA2 ON A2_FILIAL = '" + xFilial("SA2") + "' AND A2_COD = C7_FORNECE AND A2_LOJA = C7_LOJA AND SA2.D_E_L_E_T_ = ' ' "
	_cQrySC7 += "WHERE C7_NUM = '" + _cGetPC + "' "
	If _lCriaAmb
		_cQrySC7 += "  AND C7_FILIAL = '" + _cFilial + "' "
	Else
		_cQrySC7 += "  AND C7_FILIAL = '" + xFilial("SC7") + "' "
	EndIf
	_cQrySC7 += "  AND SC7.D_E_L_E_T_ = ' ' "
	_cQrySC7 := ChangeQuery(_cQrySC7)
	
	MPSysOpenQuery(_cQrySC7,"TRBSC7")
	
	TRBSC7->(DBGoTop())
	
	While !TRBSC7->(Eof())
		_nI++
		_nTotPed	+= TRBSC7->C7_TOTAL
			
		//Grava maior data de faturamento e necessidade
		
		If SToD(TRBSC7->C7_I_DTFAT) > _dDtFat
		
			_dDtFat	:= SToD(TRBSC7->C7_I_DTFAT)
			
		EndIf
		
		If SToD(TRBSC7->C7_DATPRF) > _dDtNece
		
			_dDtNece	:= SToD(TRBSC7->C7_DATPRF)
			
		EndIf
		
		_cTpFret	:= TRBSC7->C7_TPFRETE
		_cFornec	:= TRBSC7->C7_FORNECE
		_cLoja		:= TRBSC7->C7_LOJA
		_cNome		:= AllTrim(TRBSC7->A2_NREDUZ)
		_cFilPed	:= TRBSC7->C7_FILIAL
		_cGetOR		:= AllTrim(TRBSC7->A2_MUN) + " - " + AllTrim(TRBSC7->A2_EST)

		If _nI == 1
			_cGetSP		:= TRBSC7->C7_OBS
		EndIf

		_cQrySD1 := "SELECT D1_DOC, D1_LOJA "
		_cQrySD1 += "FROM " + RetSqlName("SD1") + " "
		_cQrySD1 += "WHERE D1_PEDIDO = '" + _cGetPC + "' "
		If _lCriaAmb
			_cQrySD1 += "  AND D1_FILIAL = '" + _cFilial + "' "
		Else
			_cQrySD1 += "  AND D1_FILIAL = '" + xFilial("SD1") + "' "
		EndIf
		_cQrySD1 += "  AND D_E_L_E_T_ = ' ' "
		_cQrySD1 := ChangeQuery(_cQrySD1)
		
		MPSysOpenQuery(_cQrySD1,"TRBSD1")
			
		TRBSD1->(DBGoTop())
			
		While !TRBSD1->(Eof())
	
			_cQrySE2 := "SELECT E2_PARCELA, E2_VENCREA "
			_cQrySE2 += "FROM " + RetSqlName("SE2") + " "
			_cQrySE2 += "WHERE E2_NUM = '" + TRBSD1->D1_DOC + "' "
			If _lCriaAmb
				_cQrySE2 += "  AND E2_FILIAL = '" + _cFilial + "' "
			Else
				_cQrySE2 += "  AND E2_FILIAL = '" + xFilial("SE2") + "' "
			EndIf
			_cQrySE2 += "  AND E2_FORNECE = '" + _cFornec + "' "
			_cQrySE2 += "  AND E2_LOJA = '" + TRBSD1->D1_LOJA + "' "
			_cQrySE2 += "  AND D_E_L_E_T_ = ' ' "
			_cQrySE2 := ChangeQuery(_cQrySE2)
			
			MPSysOpenQuery(_cQrySE2,"TRBSE2")

			TRBSE2->(DBGoTop())

			While !TRBSE2->(Eof())

				If !(TRBSD1->D1_DOC + " - " + DToC(SToD(TRBSE2->E2_VENCREA)) + " | " $ _cNumNF) 
					If !(TRBSD1->D1_DOC + " - " + TRBSE2->E2_PARCELA + " - " + DToC(SToD(TRBSE2->E2_VENCREA)) + " | " $ _cNumNF)
						If Empty(TRBSE2->E2_PARCELA)
							_cNumNF	+= TRBSD1->D1_DOC + " - " + DToC(SToD(TRBSE2->E2_VENCREA)) + " | "
						Else
							_cNumNF	+= TRBSD1->D1_DOC + " - " + TRBSE2->E2_PARCELA + " - " + DToC(SToD(TRBSE2->E2_VENCREA)) + " | "
						EndIf
					EndIf
				EndIf

				TRBSE2->(DBSkip())
			End

			TRBSE2->(DBCloseArea())
	
			TRBSD1->(DBSkip())
		End
		
		_cGetNF := _cNumNF
		
		TRBSD1->(DBCloseArea())

		TRBSC7->(DBSkip())
	End
	
	_dGetEE := _dDtFat
	_nGetVL := _nTotPed
	_dGetNE := _dDtNece
	_cGetFO	:= _cFornec + "/" + _cLoja + " - " + _cNome
	
	If _cTpFret == "C"
		_cGetFR := "CIF"
	ElseIf _cTpFret == "F"
		_cGetFR := "FOB"
	ElseIf _cTpFret == "T"
		_cGetFR := "TERCEIROS"
	ElseIf _cTpFret == "S"
		_cGetFR := "SEM FRETE"
	EndIf

	TRBSC7->(DBCloseArea())
	
	_cQrySC1 := "SELECT C1_NUM, C1_OBS "
	_cQrySC1 += "FROM " + RetSqlName("SC1") + " "
	_cQrySC1 += "WHERE C1_PEDIDO = '" + _cGetPC + "' "
	If _lCriaAmb
		_cQrySC1 += "  AND C1_FILIAL = '" + _cFilial + "' "
	Else
		_cQrySC1 += "  AND C1_FILIAL = '" + xFilial("SC1") + "' "
	EndIf
	_cQrySC1 += "  AND D_E_L_E_T_ = ' ' "
	_cQrySC1 := ChangeQuery(_cQrySC1)
	MPSysOpenQuery(_cQrySC1,"TRBSC1")

	TRBSC1->(DBGoTop())
	
	While !TRBSC1->(Eof())
		_nApoio++

		_cNumSC	:= TRBSC1->C1_NUM
		If _nApoio == 1
			_cObsSC	:= AllTrim(TRBSC1->C1_OBS)
		EndIf

		TRBSC1->(DBSkip())
	End

	_cGetSC := _cNumSC

	TRBSC1->(DBCloseArea())

EndIf

FWRestArea(_aArea)

Return(_lRet)

/*
===============================================================================================================================
Programa----------: A017LOK
Autor-------------: Darcio Ribeiro Sporl
Data da Criacao---: 25/04/2016 
Descrição---------: Função de validação da linha digitada
Parametros--------: Nenhum
Retorno-----------: _lRet - .T. Continua o processo / .F. Fica na linha do _aCols posicionado, não continua o processo
===============================================================================================================================
*/
User Function A017LOK()

Local _lRet	:= .T.

If Empty(_oMSNewGeZY1:aCols[_oMSNewGeZY1:nAt, aScan(_oMSNewGeZY1:aHeader,{|x| AllTrim(x[2]) == "ZY1_COMENT"})])
	U_ITMsg("É necessário o preenchimento do campo comentário.","Atenção",,1)
	_lRet := .F.
EndIf

Return(_lRet)

/*
===============================================================================================================================
Programa----------: ACOM017
Autor-------------: Darcio Ribeiro Sporl
Data da Criacao---: 25/04/2016 
Descrição---------: Função de validação após confirmação tudook.
Parametros--------: Nenhum
Retorno-----------: _lRet - .T. Continua gravação / .F. Não continua com a gravação
===============================================================================================================================
*/
User Function A017TOK()

Local _lRet	:= .T.
Local _nX	:= 0

If Empty(_cGetPC)
	U_ITMsg("Deverá ser informado um Pedido de Compras.","Atenção",,1)
	_lRet := .F.
EndIf

If _lRet 
	For _nX := 1 To Len(_oMSNewGeZY1:aCols)
		If Empty(_oMSNewGeZY1:aCols[_nX, aScan(_oMSNewGeZY1:aHeader,{|x| AllTrim(x[2]) == "ZY1_COMENT"})]) .And. ;
			!(_oGetEE:ctext != _dGetOri .And. _nX == 1)
			U_ITMsg("O campo comentário da linha " + AllTrim(Str(_nX)) + " não está preenchido.","Atenção","Favor preencher o campo corretamente.",1)
			_lRet := .F.
		EndIf
	Next _nX
EndIf

Return(_lRet)

/*
===============================================================================================================================
Programa----------: A017PLA
Autor-------------: Darcio Ribeiro Sporl
Data da Criacao---: 27/04/2016 
Descrição---------: Função criada para gerar tela para exportação dos dados para planilha
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function A017PLA()

Local _aArea	:= FWGetArea()
Local _aCampPla	:= {	'Índice',;
						'Nota',;
						'Série',;
						'Dt. Emissão',;
						'Dt. Digitação',;
						'Fornecedor',;
						'Item',;
						'Produto',;
						'Descrição',;
						'Quantidade',;
						'Preço Unitário',;
						'Valor Total'}
Local _aLogPla	:= {}
Local _cQrySD1	:= ""
Local _nCont	:= 1

_cQrySD1 := "SELECT D1_DOC, D1_EMISSAO, D1_SERIE, D1_EMISSAO, D1_DTDIGIT, D1_FORNECE, D1_LOJA, D1_ITEM, D1_COD, D1_QUANT, D1_VUNIT, D1_TOTAL, A2_NREDUZ, B1_DESC "
_cQrySD1 += "FROM " + RetSqlName("SD1") + " SD1 "
_cQrySD1 += "JOIN " + RetSqlName("SA2") + " SA2 ON A2_FILIAL = '" + xFilial("SA2") + "' AND A2_COD = D1_FORNECE AND A2_LOJA = D1_LOJA AND SA2.D_E_L_E_T_ = ' '"
_cQrySD1 += "JOIN " + RetSqlName("SB1") + " SB1 ON B1_FILIAL = '" + xFilial("SB1") + "' AND B1_COD = D1_COD AND SB1.D_E_L_E_T_ = ' ' "
_cQrySD1 += "WHERE D1_FILIAL = '" + xFilial("SD1") + "' "
_cQrySD1 += "  AND D1_PEDIDO = '" + ZY1->ZY1_NUMPC + "' "
_cQrySD1 += "  AND SD1.D_E_L_E_T_ = ' ' "
_cQrySD1 := ChangeQuery(_cQrySD1)

MPSysOpenQuery(_cQrySD1,"TRBSD1")

TRBSD1->(DBGoTop())

If !TRBSD1->(Eof())
	While !TRBSD1->(Eof())
		aAdd( _aLogPla , {	StrZero(_nCont++,4),;																//[1]Índice
							TRBSD1->D1_DOC,;																	//[2]Nota
							TRBSD1->D1_SERIE,;																	//[3]Série
							SToD(TRBSD1->D1_EMISSAO),;											 				//[4]Dt. Emissão
							SToD(TRBSD1->D1_DTDIGIT),;										   					//[5]Dt. Digitação
							TRBSD1->D1_FORNECE + "/" + TRBSD1->D1_LOJA + " - " + AllTrim(TRBSD1->A2_NREDUZ),;	//[6]Fornecedor
							TRBSD1->D1_ITEM,;														  			//[7]Item
							TRBSD1->D1_COD,;														   			//[8]Produto
							TRBSD1->B1_DESC,;																	//[9]Descrição
							AllTrim(Transform(TRBSD1->D1_QUANT,PesqPict("SD1","D1_QUANT"))),;					//[10]Quantidade
							AllTrim(Transform(TRBSD1->D1_VUNIT,PesqPict("SD1","D1_VUNIT"))),;					//[11]Preço Unitário
							AllTrim(Transform(TRBSD1->D1_TOTAL,PesqPict("SD1","D1_TOTAL"))) })					//[12]Valor Total
							
		TRBSD1->(DBSkip())
	End

	U_ITListBox( 'Geração Planilha' , _aCampPla , _aLogPla , .T. , 1 )

Else
	U_ITMsg("Não existem dados a serem mostrados para o Pedido selecionado.","Atenção","Favor selecionar outro pedido.",1)
EndIf

TRBSD1->(DBCloseArea())

FWRestArea(_aArea)
Return

/*
===============================================================================================================================
Programa----------: ACOM017P
Autor-------------: Darcio Ribeiro Sporl
Data da Criacao---: 25/04/2016 
Descrição---------: Função de Inclusão/Alteração de registros da tabela ZY1, chamado através do menu o PC
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ACOM017P()

Local _oSayFO
Local _oGetFO
Local _cGetFO := Space(60)

Local _oSayFR
Local _oGetFR
Local _cGetFR := Space(9)

Local _oSayNE
Local _oGetNE
Local _dGetNE := SToD("")
Local _dGetEE := SToD("")

Local _oSayNF
Local _oGetNF
Local _cGetNF := Space(60)

Local _oSayOR
Local _oGetOR
Local _cGetOR := Space(40)

Local _oSayPC
Local _oGetPC

Local _oSaySC
Local _oGetSC
Local _cGetSC := Space(TamSX3("C1_NUM")[1])

Local _oSaySP
Local _oGetSP
Local _cGetSP := Space(60)

Local _oSayVL
Local _oGetVL
Local _nGetVL := 0

Local _aPosObj	:= {}
Local _aObjects	:= {}
Local _aSize	:= {}
Local _aPosGet	:= {}
Local _aInfo	:= {}

Local _nX		:= 0
Local _nOpca	:= 0

Private _cGetPC := SC7->C7_NUM

Private _aTELA[0][0]
Private _aGETS[0]

Private _aHeader		:= {}
Private _aCols			:= {}
Private _aFieldFill		:= {}
Private _aFields		:= {"ZY1_SEQUEN","ZY1_DTMONI","ZY1_HRMONI","ZY1_COMENT","ZY1_CODUSR","ZY1_NOMUSR"}
Private _aAlterFields	:= {"ZY1_COMENT"}
Private nMaxGravado     := 0
Private _oMSNewGeZY1
Private _oDlg

//popula aheader
aAdd(_aHeader,   {"Sequencia"    ,"ZY1_SEQUEN"," ",4,0," "," ","C"," "," "})
aAdd(_aHeader,   {"Dt Monitoram" ,"ZY1_DTMONI"," ",8,0," "," ","D"," "," "})
aAdd(_aHeader,   {"Hr Monitoram" ,"ZY1_HRMONI"," ",5,0," "," ","C"," "," "})
aAdd(_aHeader,   {"Comentario"   ,"ZY1_COMENT"," ",200,0," "," ","C"," "," "})
aAdd(_aHeader,   {"Cod Usuario"  ,"ZY1_CODUSR"," ",6,0," "," ","C"," "," "})
aAdd(_aHeader,   {"Nome Usuario" ,"ZY1_NOMUSR"," ",40,0," "," ","C"," "," "})

U_ACOM017V(_cGetPC,@_cGetSC,@_cGetNF,@_dGetNE,@_cGetFR,@_nGetVL,@_cGetFO,@_cGetOR,@_cGetSP,@_dGetEE)

_cQryZY1 := "SELECT ZY1_SEQUEN, ZY1_DTMONI, ZY1_HRMONI, ZY1_COMENT, ZY1_CODUSR, ZY1_NOMUSR, ZY1_ENCMON "
_cQryZY1 += "FROM " + RetSqlName("ZY1") + " "
_cQryZY1 += "WHERE ZY1_FILIAL = '" + xFilial("ZY1") + "' "
_cQryZY1 += "  AND ZY1_NUMPC = '" + _cGetPC + "' "
_cQryZY1 += "  AND D_E_L_E_T_ = ' ' "
_cQryZY1 := ChangeQuery(_cQryZY1)

MPSysOpenQuery(_cQryZY1,"TRBZY1")

TRBZY1->(DBGoTop())

If !TRBZY1->(Eof())
	If TRBZY1->ZY1_ENCMON == "S"
		U_ITMsg("Foi encerrado o monitoramento deste pedido.","Atenção","Favor consultar o monitoramento através da rotina de monitoramento.",1)
		DBSelectArea("TRBZY1")
		TRBZY1->(DBCloseArea())
		Return
	EndIf

    A017GrvaCols()

Else
	// Define field values
	For _nX := 1 To Len(_aFields)
		If _aFields[_nX] == "ZY1_SEQUEN"
			aAdd(_aFieldFill, "0001")
		Else
			aAdd(_aFieldFill, CriaVar(_aFields[_nX]))
		EndIf
	Next _nX
	aAdd(_aFieldFill, .F.)
	aAdd(_aCols, _aFieldFill)
EndIf

TRBZY1->(DBCloseArea())

_aSize    := MsAdvSize()
_aObjects := {}

aAdd( _aObjects, { 100, 100, .T., .T. } )
aAdd( _aObjects, { 100, 100, .T., .T. } )
aAdd( _aObjects, { 100, 015, .T., .F. } )

_aInfo   := { _aSize[ 1 ],_aSize[ 2 ],_aSize[ 3 ],_aSize[ 4 ],03,03 }
_aPosObj := MsObjSize( _aInfo, _aObjects )
_aPosGet := MsObjGetPos(_aSize[3]-_aSize[1],315,{{003,157,189,236,268}})
_dGetOri := _dGetEE

DEFINE MSDIALOG _oDlg TITLE "Monitoramento Pedido de Compras" FROM _aSize[7],0 To _aSize[6],_aSize[5] of oMainWnd PIXEL

	@ 035, 002 Say _oSayPC PROMPT "Número PC:" SIZE 031, 007 OF _oDlg COLORS 16711680, 16777215 PIXEL
	@ 047, 002 MSGET _oGetPC VAR _cGetPC SIZE 039, 010 OF _oDlg COLORS 0, 16777215 F3 "SC7" READONLY PIXEL

	@ 035, 066 Say _oSaySC PROMPT "Número Solicitação:" SIZE 050, 007 OF _oDlg COLORS 0, 16777215 PIXEL
	@ 047, 066 MSGET _oGetSC VAR _cGetSC SIZE 039, 010 OF _oDlg COLORS 0, 16777215 READONLY PIXEL

	@ 035, 122 Say _oSayNF PROMPT "Número NF / Vencimento:" SIZE 080, 007 OF _oDlg COLORS 0, 16777215 PIXEL
	@ 047, 122 MSGET _oGetNF VAR _cGetNF SIZE 213, 010 OF _oDlg COLORS 0, 16777215 READONLY PIXEL
	
	@ 035, 450 Say _oSayEE PROMPT "Dt. Faturamento: " SIZE 055, 007 OF _oDlg COLORS 0, 16777215 PIXEL
	@ 047, 450 MSGET _oGetEE VAR _dGetEE SIZE 040, 010 OF _oDlg COLORS 0, 16777215 PIXEL
	
	@ 035, 394 Say _oSayNE PROMPT "Dt. Necessidade: " SIZE 055, 007 OF _oDlg COLORS 0, 16777215 PIXEL
	@ 047, 394 MSGET _oGetNE VAR _dGetNE SIZE 040, 010 OF _oDlg COLORS 0, 16777215 PICTURE READONLY PIXEL

	@ 035, 500 Say _oSayFR PROMPT "Tp Frete:" SIZE 025, 007 OF _oDlg COLORS 0, 16777215 PIXEL
	@ 047, 500 MSGET _oGetFR VAR _cGetFR SIZE 030, 010 OF _oDlg COLORS 0, 16777215 READONLY PIXEL

	@ 035, 590 Say _oSayVL PROMPT "Valor: " SIZE 017, 007 OF _oDlg COLORS 0, 16777215 PIXEL
	@ 047, 590 MSGET _oGetVL VAR _nGetVL SIZE 060, 010 OF _oDlg COLORS 0, 16777215 PICTURE PesqPict("SC7","C7_TOTAL") READONLY PIXEL

	@ 063, 002 Say _oSayFO PROMPT "Fornecedor:" SIZE 031, 007 OF _oDlg COLORS 0, 16777215 PIXEL
	@ 075, 002 MSGET _oGetFO VAR _cGetFO SIZE 213, 010 OF _oDlg COLORS 0, 16777215 READONLY PIXEL

	@ 063, 222 Say _oSaySP PROMPT "Obs Pedido de Compras: " SIZE 040, 007 OF _oDlg COLORS 0, 16777215 PIXEL
	@ 075, 222 MSGET _oGetSP VAR _cGetSP SIZE 336, 010 OF _oDlg COLORS 0, 16777215 READONLY PIXEL

	@ 091, 002 Say _oSayOR PROMPT "Origem: " SIZE 020, 007 OF _oDlg COLORS 0, 16777215 PIXEL
	@ 103, 002 MSGET _oGetOR VAR _cGetOR SIZE 118, 010 OF _oDlg COLORS 0, 16777215 READONLY PIXEL

	_oMSNewGeZY1 := MsNewGetDados():New( _aPosGet[1,1] + 115, _aPosGet[1,1] - 5, _aPosGet[1,2] - 15, _aPosGet[1,4] + _aPosGet[1,2] - _aPosObj[2,1] - 10, GD_INSERT+GD_UPDATE, "U_A017LOK()", "AllwaysTrue", /*"+ZY1_SEQUEN"*/, _aAlterFields,, 999, "AllwaysTrue", "", "AllwaysTrue", _oDlg, _aHeader, _aCols)

ACTIVATE MSDIALOG _oDlg CENTERED ON INIT EnchoiceBar(_oDlg,{||_nOpca := 1, _oDlg:End()},{||_nOpca := 0, _oDlg:End() }) VALID U_A017TOK()

If _nOpca == 1

	//Atualiza a data de faturamento
	If _dGetEE != _dGetOri 
		
		U_A017DTFT(_dGetEE,_cGetPC)
		
		//Se só tem uma linha no acols com descrição em branco preenche descrição para registrar mudança de data
		If Len(_oMSNewGeZY1:aCols) == 1 .And. Empty(_oMSNewGeZY1:aCols[1, aScan(_oMSNewGeZY1:aHeader,{|x| AllTrim(x[2]) == "ZY1_COMENT"})])
			
			_oMSNewGeZY1:aCols[1, aScan(_oMSNewGeZY1:aHeader,{|x| AllTrim(x[2]) == "ZY1_COMENT"})] := "Data de faturamento alterada de " + DToC(_dGetOri) + " para " + DToC(_dGetEE)
			
		Else
						
			aAdd(_oMSNewGeZY1:aCols,{	"",;//StrZero(Len(_oMSNewGeZY1:aCols)+1,4),;
										Date()			,;
										Time()			,;
										"Data de faturamento alterada de " + DToC(_dGetOri) + " para " + DToC(_dGetEE)				,;
										__cUserId 		,;
										USRFULLNAME(__cUserId),;
										.F. })
															
				
		EndIf
		
			
	EndIf
	

	Begin Transaction
		For _nX := 1 To Len(_oMSNewGeZY1:aCols)
			If !_oMSNewGeZY1:aCols[_nX, Len(_oMSNewGeZY1:aHeader) + 1]
				DBSelectArea("ZY1")
				ZY1->(DBSetOrder(1))
				_cSequen:=_oMSNewGeZY1:aCols[_nX, aScan(_oMSNewGeZY1:aHeader,{|x| AllTrim(x[2]) == "ZY1_SEQUEN"})]
				If !Empty(_cSequen) .And. ZY1->(DBSeek(xFilial("ZY1") + _cGetPC + _cSequen ))
					RecLock("ZY1", .F.)
						Replace ZY1->ZY1_FILIAL	With xFilial("ZY1")
						Replace ZY1->ZY1_NUMPC	With _cGetPC
						Replace ZY1->ZY1_SEQUEN	With _oMSNewGeZY1:aCols[_nX, aScan(_oMSNewGeZY1:aHeader,{|x| AllTrim(x[2]) == "ZY1_SEQUEN"})]
						Replace ZY1->ZY1_DTMONI	With _oMSNewGeZY1:aCols[_nX, aScan(_oMSNewGeZY1:aHeader,{|x| AllTrim(x[2]) == "ZY1_DTMONI"})]
						Replace ZY1->ZY1_HRMONI	With _oMSNewGeZY1:aCols[_nX, aScan(_oMSNewGeZY1:aHeader,{|x| AllTrim(x[2]) == "ZY1_HRMONI"})]
						Replace ZY1->ZY1_COMENT	With _oMSNewGeZY1:aCols[_nX, aScan(_oMSNewGeZY1:aHeader,{|x| AllTrim(x[2]) == "ZY1_COMENT"})]
						Replace ZY1->ZY1_CODUSR	With _oMSNewGeZY1:aCols[_nX, aScan(_oMSNewGeZY1:aHeader,{|x| AllTrim(x[2]) == "ZY1_CODUSR"})]
						Replace ZY1->ZY1_NOMUSR	With _oMSNewGeZY1:aCols[_nX, aScan(_oMSNewGeZY1:aHeader,{|x| AllTrim(x[2]) == "ZY1_NOMUSR"})]
					ZY1->(MSUnLock())
				Else
  				    nMaxGravado++
					RecLock("ZY1", .T.)
						Replace ZY1->ZY1_FILIAL	With xFilial("ZY1")
						Replace ZY1->ZY1_NUMPC	With _cGetPC
						Replace ZY1->ZY1_SEQUEN	With StrZero(nMaxGravado,4)
						Replace ZY1->ZY1_DTMONI	With _oMSNewGeZY1:aCols[_nX, aScan(_oMSNewGeZY1:aHeader,{|x| AllTrim(x[2]) == "ZY1_DTMONI"})]
						Replace ZY1->ZY1_HRMONI	With _oMSNewGeZY1:aCols[_nX, aScan(_oMSNewGeZY1:aHeader,{|x| AllTrim(x[2]) == "ZY1_HRMONI"})]
						Replace ZY1->ZY1_COMENT	With _oMSNewGeZY1:aCols[_nX, aScan(_oMSNewGeZY1:aHeader,{|x| AllTrim(x[2]) == "ZY1_COMENT"})]
						Replace ZY1->ZY1_CODUSR	With _oMSNewGeZY1:aCols[_nX, aScan(_oMSNewGeZY1:aHeader,{|x| AllTrim(x[2]) == "ZY1_CODUSR"})]
						Replace ZY1->ZY1_NOMUSR	With _oMSNewGeZY1:aCols[_nX, aScan(_oMSNewGeZY1:aHeader,{|x| AllTrim(x[2]) == "ZY1_NOMUSR"})]
						Replace ZY1->ZY1_DTNECE With _dGetNE
						Replace ZY1->ZY1_DTFAT With _dGetEE
					ZY1->(MSUnLock())
				EndIf
			EndIf
		Next
	End Transaction

    If _dGetEE = _dGetOri 
	   U_ITMsg("Gravação completada com sucesso", "Atenção",,2)
  	Else
       U_ITMsg("Data de Faturamento alterada de " + DToC(_dGetOri) + " para " + DToC(_dGetEE)+" e Gravação completada com sucesso.","Atenção",,2)
	EndIf

EndIf

Return

/*
===============================================================================================================================
Programa----------: ACOM017E
Autor-------------: Darcio Ribeiro Sporl
Data da Criacao---: 28/04/2016 
Descrição---------: Função criada enviar e-mail dos monitoramentos do dia atual
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ACOM017E()

Local _aTables		:= {"ZY1","SC7","SA2","SD1","SC1"}
Local _lCriaAmb		:= .F.
Local _aAlias		:= {}
Local _cAlias		:= ""
Local _aColumns 	:= {}
Local _cFilial		:= ""
Local _cFilBKP		:= ""
Local _cHtml		:= ""
Local _cHead		:= ""
Local _cItem		:= ""
Local _cTail		:= ""

Local _cTo			:= ""
Local _cGetCc		:= ""
Local _cMailCom		:= ""
Local _cGetAssun	:= ""
Local _cGetAnx		:= ""
Local _cQryZY1		:= ""

Local _cGetSC		:= ""
Local _cGetNF		:= ""
Local _dGetNE		:= ""
Local _cGetFR		:= ""
Local _nGetVL		:= ""
Local _cGetFO		:= ""
Local _cGetOR		:= ""
Local _cGetSP		:= ""

Local _cEmailWFC 	:= ""
Local _cEmailWFG 	:= ""
Local _dGetEE := SToD("")

Local _aConfig		:= {}
Local _cEmlLog		:= ""

Private _cPerg		:= "ACOM017"
Private _cHostWF	:= ""
Private _dDtIni		:= ""
Private _cNumPCd	:= ""
Private _cNumPCa	:= ""
Private _dDtMond	:= CtoD("//")
Private _dDtMona	:= CtoD("//")

//=============================================================
// Verifica a necessidade de criar um ambiente, caso nao esteja
// criado anteriormente um ambiente, pois ocorrera erro
//=============================================================
If Select("SX3") <= 0
	_lCriaAmb:= .T.
EndIf

If _lCriaAmb

	//=====================
	// Nao consome licensas
	//=====================
	RPCSetType(3)

	//===========================================
	// Seta o ambiente com a empresa 01 filial 01
	//===========================================
	RpcSetEnv("01","01",,,,"SCHEDULE_WF_MONITORAMENTO",_aTables)

	//========================================================================================
	// Mensagem que ficara armazenada no arquivo totvsconsole.log para posterior monitoramento
	//======================================================================================== 
	FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "ACOM017"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "ACOM01701"/*cMsgId*/, "ACOM01701 - Gerando envio de e-mail do monitoramento dos pedidos de compras na data: " + DToC(Date()) + " - " + Time()/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

EndIf

_aConfig	:= U_ITCFGEML('')
_cHostWF 	:= SuperGetMV("IT_WFHOSTS",.F.,"http://wfteste.italac.com.br:4034/")
_dDtIni		:= DToS(SuperGetMV("IT_WFDTINI",.F.,"26/11/2025"))

If _lCriaAmb
	FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "ACOM017"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "ACOM01702"/*cMsgId*/, "ACOM01702 - Carregando filiais..."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	_aAlias := ACOM017M(_lCriaAmb, .T.)
Else
	If !Pergunte(_cPerg,.T.)
	     Return
	EndIf

	FWMsgRun(,{|| _aAlias := ACOM017M(_lCriaAmb, .T.)},,"Aguarde, gerando e processando e-mail...")
	
    _cAlias:= _aAlias[1]
	If (_cAlias)->(Eof()) .And. (_cAlias)->(Bof())
	   U_ITMsg( "Não tem registros para esses filtros",'ATENÇÃO',"Selecione outros filtros e tente novamente",2 )
	   Return .F.
	EndIf

	_dDtMond	:= DToS(MV_PAR03)
	_dDtMona	:= DToS(MV_PAR04)
EndIf

_cAlias		:= _aAlias[1]
_aColumns 	:= _aAlias[2]

(_cAlias)->(DBGoTop())

While !(_cAlias)->(Eof())

	_cFilial	:= (_cAlias)->ZY1_FILIAL
	FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "ACOM017"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "ACOM01703"/*cMsgId*/, "ACOM01703 - Montando dados da filial " + _cfilial + "..."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

	_cHead := '<html>'
	_cHead += '<head>'
	_cHead += '<meta charset="UTF-8">'
	_cHead += '<meta name="description" content="Monitoramento Pedidos de Compras">'
	_cHead += '<meta name="keywords" content="HTML,CSS,XML,JavaScript">'
	_cHead += '<meta name="author" content="Darcio Ribeiro Sporl">'
	_cHead += '<title>Pedido de Compras</title>'
	_cHead += '</head>'
	
	_cHead += '<style Type="text/css"><!--'
	_cHead += 'table.bordasimples { border-collapse: collapse; }'
	_cHead += 'table.bordasimples tr td { border:1px solid #777777; }'
	_cHead += 'td.grupos	{ font-family:VERDANA; font-size:20px; V-align:middle; background-color: #C6E2FF; color:#000080; }'
	_cHead += 'td.titulos	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #EEDD82; }'
	_cHead += 'td.mensagem	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #C6E2FF; }'
	_cHead += 'td.texto	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; }'
	_cHead += 'td.itens	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #DDDDDD; }'
	_cHead += 'td.totais	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #7f99b2; color:#FFFFFF; }'
	_cHead += '--></style>'
	
	_cHead += '<body bgcolor="#FFFFFF">'
	_cHead += '<center>'
	_cHead += '<table width="100%" cellspacing="0" cellpadding="2" border="0">'
	_cHead += '  <tr>'
	_cHead += '    <td width="02%" class="grupos">'
	_cHead += '      <center><img src="http://www.italac.com.br/wp-content/themes/italac/assets/images/logo.svg" width="100px" height="030px"></center>'
	_cHead += '	</td>'
	_cHead += '    <td width="98%" class="grupos"><center>Lista de Monitoramento de Pedidos de Compras</center></td>'
	_cHead += '  </tr>'
	_cHead += '</table>'
	_cHead += '<table border="0" width="100%">'
	_cHead += '	<tr>'
	_cHead += '		<td valign="top" class="texto">'
	_cHead += '			<br><br>Existe(m) Pedido(s) de Compra(s) Monitorados.'
	_cHead += '		</td>'
	_cHead += '	</tr>'
	_cHead += '</table>'
	_cHead += '<br>'
	
	_cHead += '<table width="100%" border="0" CellSpacing="2" CellPadding="0">'

	_cTail := '<tr>'
	_cTail +=     '<td valign="top" align="left" colspan="13">&nbsp;</td>'
	_cTail += '</tr>'

	_cTail += '</table>'
	_cTail += '</center>'
	
	_cTail += '<br>'
	_cTail += '<br>'
	
	_cTail += '<table width="38%" border="0" CellSpacing="2" CellPadding="0">'
	_cTail += '	<tr>'
	_cTail += '		<td valign="top" align="center" class="mensagem"><font color="red">Mensagem enviada automática, favor não responder este e-mail.</fonte></td>'
	_cTail += '	</tr>'
	_cTail += '</table>'
	
	_cTail += '</body>'
	_cTail += '</html>'

	If !(_cAlias)->(Eof())
		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "ACOM017"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "ACOM01704"/*cMsgId*/, "ACOM01704 - Carregando monitoramentos da filial " + _cfilial + "..."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

		_cQryZY1 := "SELECT ZY1_FILIAL, ZY1_NUMPC, ZY1_SEQUEN, ZY1_DTMONI, ZY1_HRMONI, ZY1_COMENT, ZY1_CODUSR, ZY1_NOMUSR "
		_cQryZY1 += "FROM " + RetSqlName("ZY1") + " ZY1 "
		_cQryZY1 += "WHERE ZY1.ZY1_FILIAL = '" + (_cAlias)->ZY1_FILIAL + "'"  
		 		
		If !_lCriaAmb
			_cQryZY1 += "  AND ZY1.ZY1_DTMONI BETWEEN '" + DToS(MV_PAR03) + "' AND '" + DToS(MV_PAR04) + "' "
			_cQryZY1 += "  AND ZY1.ZY1_NUMPC BETWEEN '" + MV_PAR01 + "' AND '" + MV_PAR02 + "' "
		EndIf
		
		_cQryZY1 += "  AND ZY1.ZY1_ENCMON <> 'S' "
		_cQryZY1 += "  AND ZY1.R_E_C_N_O_ = (SELECT MAX(ZY1A.R_E_C_N_O_) ZY1A_RECNO FROM " + RetSqlName("ZY1") + " ZY1A 
		_cQryZY1 += "                              WHERE ZY1A.ZY1_FILIAL = ZY1.ZY1_FILIAL AND ZY1A.ZY1_NUMPC = ZY1.ZY1_NUMPC AND ZY1A.D_E_L_E_T_ = ' ' "
		_cQryZY1 += "                                    AND NOT Upper(ZY1A.ZY1_COMENT) LIKE 'DATA DE FATURAMENTO ALTERADA DE%' ) "

		_cQryZY1 += "  AND ZY1.D_E_L_E_T_ = ' ' "

		_cQryZY1 += "ORDER BY ZY1_FILIAL, ZY1_NUMPC "
		_cQryZY1 := ChangeQuery(_cQryZY1)

		MPSysOpenQuery(_cQryZY1,"TRBZY1")
		
		_ntot := 0
		_nni := 0
		
		TRBZY1->(DBGoTop())
		COUNT To _nTot
		TRBZY1->(DBGoTop())

		_cItem := ""
		
		If !TRBZY1->(Eof())
		
			While !TRBZY1->(Eof())

				_nni++
				FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "ACOM017"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "ACOM01705"/*cMsgId*/, "ACOM01705 - Carregando monitoramentos da filial " + _cfilial + " - " + StrZero(_nni,6) + " de " + StrZero(_ntot,6) + "..."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

				_cItem += '<tr>'
				_cItem += 	  '<td align="center" class="totais">Filial</td>
				_cItem +=     '<td align="center" class="totais">Solicitação</td>'
				_cItem +=     '<td align="center" class="totais">Pedido</td>'
				_cItem +=     '<td align="center" class="totais">Nº da NF</td>'
				_cItem +=     '<td align="center" class="totais">Fornecedor</td>'
				_cItem +=     '<td align="center" class="totais">Origem</td>'
				_cItem +=     '<td align="center" class="totais">Dt. Necessidade</td>'
				_cItem +=     '<td align="center" class="totais">Dt. Faturamento</td>'
				_cItem +=     '<td align="center" class="totais">Frete</td>'
				_cItem +=     '<td align="center" class="totais">Valor</td>'
				_cItem +=     '<td align="center" class="totais">Obs Pedido de Compras</td>'
				_cItem += '</tr>'

				U_ACOM017V(TRBZY1->ZY1_NUMPC,@_cGetSC,@_cGetNF,@_dGetNE,@_cGetFR,@_nGetVL,@_cGetFO,@_cGetOR,@_cGetSP,@_dGetEE,_lCriaAmb,TRBZY1->ZY1_FILIAL)

				_cItem += '<tr>'
				_cItem += 	  '<td valign="top" align="left"	class="itens">' + (_cAlias)->ZY1_FILIAL + " - " + AllTrim(FwFilialName(cEmpAnt,(_cAlias)->ZY1_FILIAL)) + '</td>'
				_cItem +=     '<td valign="top" align="center"	class="itens">' + _cGetSC + '</td>'
				_cItem +=     '<td valign="top" align="center"	class="itens">' + TRBZY1->ZY1_NUMPC + '</td>'
				_cItem +=     '<td valign="top" align="left"	class="itens">' + _cGetNF + '</td>'
				_cItem +=     '<td valign="top" align="left"	class="itens">' + AllTrim(_cGetFO) + '</td>'
				_cItem +=     '<td valign="top" align="center"	class="itens">' + _cGetOR + '</td>'
				_cItem +=     '<td valign="top" align="left"	class="itens">' + DToC(_dGetNE) + '</td>'
				_cItem +=     '<td valign="top" align="left"	class="itens">' + DToC(_dGetEE) + '</td>'
				_cItem +=     '<td valign="top" align="center"	class="itens">' + _cGetFR + '</td>'
				_cItem +=     '<td valign="top" align="center"	class="itens">' + Transform(_nGetVL,PesqPict("SC7","C7_TOTAL")) + '</td>'
				_cItem +=     '<td valign="top" align="center"	class="itens">' + _cGetSP + '</td>'
				_cItem += '</tr>'

				_cItem += '<tr>'
				_cItem +=     '<td valign="top" align="left" colspan="13" class="itens">Status: ' + TRBZY1->ZY1_SEQUEN + " - " + DToC(SToD(TRBZY1->ZY1_DTMONI)) + " - " + TRBZY1->ZY1_HRMONI + " - " + AllTrim(TRBZY1->ZY1_COMENT) + " ( " + TRBZY1->ZY1_CODUSR + "-" + AllTrim(TRBZY1->ZY1_NOMUSR) + " ) </td>'
				_cItem += '</tr>'

				ZY1->(DBSetOrder(1))
				ZY1->(DBSeek(TRBZY1->ZY1_FILIAL + TRBZY1->ZY1_NUMPC + TRBZY1->ZY1_SEQUEN))

				RecLock("ZY1", .F.)
					Replace ZY1->ZY1_ENVIAD With "S"
				MSUnLock()
				TRBZY1->(DBSkip())
			
			EndDo
			
		EndIf

		TRBZY1->(DBCloseArea())

		_cHtml := _cHead
		_cHtml += _cItem
		_cHtml += _cTail

		If _lCriaAmb
		 
			_cFilBKP := cFilAnt
			
 			 cFilAnt := (_cAlias)->ZY1_FILIAL

			_cEmailWFC 	:= AllTrim(SuperGetMV("IT_MAILWFC",.F.,""))
			_cEmailWFG 	:= AllTrim(SuperGetMV("IT_MAILWFG",.F.,""))

			_cTo := _cEmailWFG + ";" + _cEmailWFC

			cFilAnt := _cFilBKP

		Else

			_cEmailWFC 	:= AllTrim(SuperGetMV("IT_MAILWFC",.F.,""))
			_cEmailWFG 	:= AllTrim(SuperGetMV("IT_MAILWFG",.F.,""))

			_cTo := _cEmailWFG + ";" + _cEmailWFC
			

		EndIf

		//=================================================================
		//Chama a função para criação do arquivo em PDF para envio em anexo
		//=================================================================
		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "ACOM017"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "ACOM01706"/*cMsgId*/, "ACOM01706 - Montando da filial " + _cfilial + "..."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		A017PDF((_cAlias)->ZY1_FILIAL, @_cGetAnx, _lCriaAmb)

		_cGetAssun	:= "Lista de Monitoramento de Pedidos de Compras Filial: " + (_cAlias)->ZY1_FILIAL + " - " + AllTrim(FwFilialName(cEmpAnt,(_cAlias)->ZY1_FILIAL))

		//====================================
		// Chama a função para envio do e-mail
		//====================================

		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "ACOM017"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "ACOM01707"/*cMsgId*/, "ACOM01707 - Enviando email da filial " + _cfilial + "..."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		If _cItem != ""
//          ITEnvMail(cFrom,cEmailTo,cEmailCo,cEmailBcc,cAssunto  ,cMensagem,cAttach  ,cAccount     ,cPassword    ,cServer      ,cPortCon     ,lRelauth     ,cUserAut     ,cPassAut     ,cLogErro  ,lExibeAmb)		
		  U_ITENVMAIL( ""  , _cTo   , _cGetCc,_cMailCom,_cGetAssun, _cHtml  , _cGetAnx, _aConfig[01], _aConfig[02], _aConfig[03], _aConfig[04], _aConfig[05], _aConfig[06], _aConfig[07], @_cEmlLog )
		  
		EndIf
	
		If  !_lCriaAmb
			U_ITMsg( _cEmlLog , 'Término do processamento!' ,"Enviado para "+_cTo ,2 )
		Else
			FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "ACOM017"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "ACOM01708"/*cMsgId*/, "ACOM01708 - Email monitoramento da filial " + _cfilial +  " enviado com log:  " + _cEmlLog/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		EndIf

		_cHtml := ""
		_cItem := ""

		//========================================================
		// Chama a função para exclusão do arquivo PDF do servidor
		//========================================================
		A017DEL(_cGetAnx)

	EndIf
	
	(_cAlias)->( DBSkip() )

EndDo

If _lCriaAmb

	//=============================================================
	// Limpa o ambiente, liberando a licença e fechando as conexoes
	//=============================================================
	RpcClearEnv()

	FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "ACOM017"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "ACOM01709"/*cMsgId*/, "ACOM01709 - Termino do envio do envio de monitoramento de pedidos de compras na data: " + DToC(Date()) + " - " + Time()/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

EndIf

Return

/*
===============================================================================================================================
Programa----------: ACOM017M
Autor-------------: Darcio Ribeiro Sporl
Data da Criacao---: 28/04/2016 
Descrição---------: Função utilizada para montar a query e arquivo temporário
Parametros--------: Nenhum
Retorno-----------: Array [1] - Tabela temporária / [2] - Colunas do browse
===============================================================================================================================
*/
Static Function ACOM017M(_lCriaAmb, _lfiliais)

Local _cAliasTrb	:= GetNextAlias()		
Local _aFields		:= {'ZY1_NUMPC','ZY1_FILIAL'}
Local _cSelect		:= ""
Local _aStructZY1	:= ZY1->(DBSTRUCT())
Local _aColumns		:= {}
Local _nX			:= 0					
Local _cTempTab		:= "" , nX

//Variaveis utilizadas para montar o where da query, referente aos filtros preenchidos pelo usuario.
Local _cWNumPC		:= ""
Local _cWDtMon		:= ""

Default _lfiliais := .F.

ProcRegua(0)
IncProc('Inicializando a rotina...')

If !_lCriaAmb

	_cNumPCd	:= MV_PAR01
	_cNumPCa	:= MV_PAR02
	_dDtMond	:= DToS(MV_PAR03)
	_dDtMona	:= DToS(MV_PAR04)

EndIf

For _nX := 1 To Len(_aFields)
	_cSelect += _aFields[_nX] + ", "
Next _nX

If _lCriaAmb

	
	If _lfiliais
	
		
		BeginSql alias _cAliasTrb

			SELECT DISTINCT(ZY1_FILIAL) ZY1_FILIAL
			FROM %Table:ZY1% ZY1
			WHERE ZY1.%notDel%
			GROUP BY ZY1_FILIAL
			ORDER BY ZY1_FILIAL
		EndSql
	Else
		BeginSql alias _cAliasTrb
			SELECT DISTINCT(ZY1_FILIAL) ZY1_FILIAL, ZY1_NUMPC
			FROM %Table:ZY1% ZY1
			WHERE ZY1.%notDel%
			ORDER BY ZY1_FILIAL
		EndSql
	EndIf
Else

	//===========================================================
	//Tratamento da clausula where do Número do Pedido de Compras
	//===========================================================
	_cWNumPC := "%"
	_cWNumPC += " ZY1_NUMPC BETWEEN '" + _cNumPCd + "' AND '" + _cNumPCa + "' "
	_cWNumPC += "%"
	
	//=====================================================
	//Tratamento da clausula where da Data de Monitoramento
	//=====================================================
	_cWDtMon := "%"
	_cWDtMon += " ZY1_DTMONI BETWEEN '" + _dDtMond + "' AND '" + _dDtMona + "' "
	_cWDtMon += "%"
	
	If _lfiliais
	
			BeginSql alias _cAliasTrb

			SELECT DISTINCT(ZY1_FILIAL) ZY1_FILIAL
			FROM %Table:ZY1% ZY1
			WHERE ZY1_FILIAL = %xFilial:ZY1%
			  AND %Exp:_cWNumPC%
			  AND %Exp:_cWDtMon%	
		 	  AND ZY1.%notDel%
		 	GROUP BY ZY1_FILIAL
			ORDER BY ZY1_FILIAL
		EndSql	
	Else
		BeginSql alias _cAliasTrb
			SELECT DISTINCT(ZY1_FILIAL) ZY1_FILIAL, ZY1_NUMPC
			FROM %Table:ZY1% ZY1
			WHERE ZY1_FILIAL = %xFilial:ZY1%
			  AND %Exp:_cWNumPC%
			  AND %Exp:_cWDtMon%	
		 	  AND ZY1.%notDel%
			ORDER BY ZY1_FILIAL
		EndSql
	EndIf
EndIf

//----------------------------------------------------------------------
// Cria arquivo de dados temporário
//----------------------------------------------------------------------
_cTempTab := GetNextAlias()
_otemp := FWTemporaryTable():New( _cTempTab, _aStructZY1 )
_otemp:Create()

(_cAliasTrb)->(DBGoTop())

While !(_cAliasTrb)->(Eof())

	RecLock(_cTempTab,.T.)
	If _lfiliais
		(_cTempTab)->ZY1_FILIAL := (_cAliasTrb)->ZY1_FILIAL
	Else
		(_cTempTab)->ZY1_FILIAL := (_cAliasTrb)->ZY1_FILIAL
		(_cTempTab)->ZY1_NUMPC := (_cAliasTrb)->ZY1_NUMPC
	EndIf
	
	(_cAliasTrb)->(DBSkip())
	
EndDo

If ( Select( _cAliasTrb ) > 0 )
	(_cAliasTrb)->(DBCloseArea())
EndIf

IncProc('Lendo os dados...')

(_cTempTab)->( DBGoTop() )

For nX := 1 To Len(_aFields)
	If _aFields[nX] $ _cSelect 
		aAdd(_aColumns,FWBrwColumn():New())

		_aColumns[Len(_aColumns)]:SetData( &("{||" + _aFields[nX] + "}") )
		_aColumns[Len(_aColumns)]:SetTitle(RetTitle(_aFields[nX])) 
		_aColumns[Len(_aColumns)]:SetSize(TamSX3(_aFields[nX])[1]) 
		_aColumns[Len(_aColumns)]:SetDecimal(TamSX3(_aFields[nX])[2])
		_aColumns[Len(_aColumns)]:SetPicture(PesqPict("ZY1",_aFields[nX]))
	EndIf
Next nX

Return( { _cTempTab , _aColumns } )

/*
===============================================================================================================================
Programa----------: A017ENC
Autor-------------: Darcio Ribeiro Sporl
Data da Criacao---: 28/04/2016 
Descrição---------: Função utilizada para fazer o encerramento do monitoramento.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function A017ENC()

Local _aArea	:= FWGetArea()
Local _cNumPC	:= ZY1->ZY1_NUMPC
Local _cQryZY1	:= ""
Local _nSeq		:= 0

If ZY1->ZY1_ENCMON == "S"
	U_ITMsg('O monitoramento deste pedido já foi encerrado.','Atenção','Favor verificar o pedido selecionado.',1)
Else
	If U_ITMsg('Deseja realmente encerrar o monitoramento do pedido selecionado?',"Atenção",,3,2,2)
		ZY1->(DBSetOrder(1))
		ZY1->(DBSeek(ZY1->ZY1_FILIAL + ZY1->ZY1_NUMPC))
	
		While !ZY1->(Eof()) .And. ZY1->ZY1_NUMPC == _cNumPC
			RecLock("ZY1", .F.)
				Replace ZY1->ZY1_ENCMON With "S"
			ZY1->(MSUnLock())
			ZY1->(DBSkip())
		EndDo

		_cQryZY1 := "SELECT ZY1_FILIAL, ZY1_NUMPC, ZY1_SEQUEN, ZY1_DTMONI, ZY1_HRMONI, ZY1_COMENT, ZY1_CODUSR, ZY1_NOMUSR "
		_cQryZY1 += "FROM " + RetSqlName("ZY1") + " "
		_cQryZY1 += "WHERE ZY1_FILIAL = '" + xFilial("ZY1") + "' "
		_cQryZY1 += "  AND ZY1_NUMPC = '" + _cNumPC + "' "
		_cQryZY1 += "  AND D_E_L_E_T_ = ' ' "
		_cQryZY1 := ChangeQuery(_cQryZY1)

		MPSysOpenQuery(_cQryZY1,"TRBZY1")

		TRBZY1->(DBGoTop())

		If !TRBZY1->(Eof())
			While !TRBZY1->(Eof())
				_nSeq++
				TRBZY1->(DBSkip())
			End

			_nSeq++

			DBSelectArea("ZY1")
			ZY1->(DBSetOrder(1))
			RecLock("ZY1",.T.)
				Replace ZY1->ZY1_FILIAL	With xFilial("ZY1")
				Replace ZY1->ZY1_NUMPC	With _cNumPC
				Replace ZY1->ZY1_SEQUEN	With StrZero(_nSeq++,4)
				Replace ZY1->ZY1_DTMONI	With dDataBase
				Replace ZY1->ZY1_HRMONI	With Time()
				Replace ZY1->ZY1_COMENT	With "********** O pedido " + _cNumPC + " foi encerrado o monitoramento. **********"
				Replace ZY1->ZY1_CODUSR	With __cUserId
				Replace ZY1->ZY1_NOMUSR	With AllTrim(UsrFullName(__cUserId))
				Replace ZY1->ZY1_ENCMON With "S"
			ZY1->(MSUnLock())
		Else
			ZY1->(DBSetOrder(1))
			RecLock("ZY1",.T.)
				Replace ZY1->ZY1_FILIAL	With xFilial("ZY1")
				Replace ZY1->ZY1_NUMPC	With _cNumPC
				Replace ZY1->ZY1_SEQUEN	With StrZero("0001",4)
				Replace ZY1->ZY1_DTMONI	With dDataBase
				Replace ZY1->ZY1_HRMONI	With Time()
				Replace ZY1->ZY1_COMENT	With "********** O pedido " + _cNumPC + " foi encerrado o monitoramento. **********"
				Replace ZY1->ZY1_CODUSR	With __cUserId
				Replace ZY1->ZY1_NOMUSR	With AllTrim(UsrFullName(__cUserId))
				Replace ZY1->ZY1_ENCMON With "S"
			ZY1->(MSUnLock())
		EndIf

	TRBZY1->(DBCloseArea())

	Else
		U_ITMsg('Processo cancelado pelo usuário.',"Atenção",,1)
	EndIf
EndIf

FWRestArea(_aArea)
Return

/*
===============================================================================================================================
Programa----------: A017LEG
Autor-------------: Darcio Ribeiro Sporl
Data da Criacao---: 28/04/2016 
Descrição---------: Função utilizada para montar a legenda
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function A017LEG()

aLegenda :=	{	{"BR_VERDE"		, "Acima 15 Dias"		},;
				{"BR_AMARELO"	, "Entre 10 e 14 Dias"	},;
				{"BR_VERMELHO"	, "Abaixo 9 Dias"		},;
				{"BR_BRANCO"	, "Monit Encerrado"		} }

BrwLegenda("Situação da previsão de faturamento","Legenda",aLegenda)

Return

/*
===============================================================================================================================
Programa----------: A017PDF
Autor-------------: Darcio Ribeiro Sporl
Data da Criacao---: 24/05/2016 
Descrição---------: Rotina responsável por emitir monitoramento em PDF
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function A017PDF(_cFilAtu, _cGetAnx, _lCriaAmb)

Local _aArea		:= FWGetArea()
Local _cFilial		:= SC7->C7_FILIAL
Local _cPathSrvJ	:= GETMV("MV_RELT")
Local _cQryZY1A		:= ""
Local _cFileName	:= ""

Local nLinIni		:= 90		// Linha Lateral (inicial) Esquerda
Local nColIni		:= 10		// Coluna Lateral (inicial) Esquerda
Local nColMax		:= 0835		// Para implementar layout A4
Local nLinAux		:= 0
Local nCont			:= 0

Local _cGetSC		:= ""
Local _cGetNF		:= ""
Local _dGetNE		:= SToD("")
Local _dGetEE     := SToD("")
Local _cGetFR		:= ""
Local _nGetVL		:= 0
Local _cGetFO		:= ""
Local _cGetOR		:= ""
Local _cGetSP		:= ""

Local lPagina		:= .T.

Local _nTam			:= 0
Local _nI			:= 0
Local _nIni			:= 0
Local _nIni2		:= 0
Local _nTam2		:= 0
Local _nTam3		:= 0

Private oPrint		:= Nil

//============================
// Define fontes do Relatorio
//============================
Private oFont14		:= TFont():New("Arial",,14,,.F.,,,,,.F.,.F.)
Private oFont08		:= TFont():New("Arial",,08,,.F.,,,,,.F.,.F.)


		_cFileName := "Monitoramento_" + _cfilatu + "_" + AllTrim(FwFilialName(cEmpAnt,_cfilatu)) + ".pdf"

		_cQryZY1A := "SELECT ZY1_FILIAL, ZY1_NUMPC, ZY1_SEQUEN, ZY1_DTMONI, ZY1_HRMONI, ZY1_COMENT, ZY1_CODUSR, ZY1_NOMUSR "
		_cQryZY1A += "FROM " + RetSqlName("ZY1") + " ZY1 "
		_cQryZY1A += "WHERE ZY1.ZY1_FILIAL = '" + _cfilatu + "' "
		If !_lCriaAmb
			_cQryZY1A += "  AND ZY1.ZY1_DTMONI BETWEEN '" + DToS(MV_PAR03) + "' AND '" + DToS(MV_PAR04) + "' "
			_cQryZY1A += "  AND ZY1.ZY1_NUMPC BETWEEN '" + MV_PAR01 + "' AND '" + MV_PAR02 + "' "
		EndIf
		_cQryZY1A += "  AND ZY1.ZY1_ENCMON <> 'S' "
		_cQryZY1A += "  AND ZY1.R_E_C_N_O_ = (SELECT MAX(ZY1A.R_E_C_N_O_) ZY1A_RECNO FROM " + RetSqlName("ZY1") + " ZY1A 
		_cQryZY1A += "                              WHERE ZY1A.ZY1_FILIAL = ZY1.ZY1_FILIAL AND ZY1A.ZY1_NUMPC = ZY1.ZY1_NUMPC AND ZY1A.D_E_L_E_T_ = ' ' "
		_cQryZY1A += "                                    AND NOT Upper(ZY1A.ZY1_COMENT) LIKE 'DATA DE FATURAMENTO ALTERADA DE%' ) "
		_cQryZY1A += "  AND ZY1.D_E_L_E_T_ = ' ' "

		_cQryZY1A += "ORDER BY ZY1_FILIAL, ZY1_NUMPC "
		_cQryZY1A := ChangeQuery(_cQryZY1A)

		MPSysOpenQuery(_cQryZY1A,"TRBZY1A")
		
		TRBZY1A->(DBGoTop())

		If !TRBZY1A->(Eof())

			nLinIni	:= 005
			nColIni	:= 000
			nCont++

			_cFilial	:= _cfilatu

			//==========================
			// Cria Arquivo do Relatorio
			//==========================
			oPrint := FWMSPrinter():New( _cFileName , IMP_PDF , .F. , _cPathSrvJ , .T. ,,,, .T. )

			//=====================================
			// Configura modo Paisagem de Impressao
			//=====================================
			oPrint:SetLandscape()

			//=============================
			// Define impressao em papel A4
			//=============================
			oPrint:SetPaperSize(9)
			oPrint:SetMargin(0,0,0,0)	// nEsquerda, nSuperior, nDireita, nInferior
	
			//=========================================================
			// Se enviar por e-mail nao abre o arquivo apos a impressao
			//=========================================================
			oPrint:SetViewPDF(.F.)
			oPrint:cPathPDF := _cPathSrvJ	// Caso seja utilizada impressão em IMP_PDF

			oPrint:StartPage()

			//==================================
			// Chama função para desenhar o grid
			//==================================
			A017GRID(_cFilial)

			nLinAux := nLinIni + 095
			
			_nnii := 0
			_ntoti := 0
			TRBZY1A->(DBGoTop())
			Count To _ntoti
			TRBZY1A->(DBGoTop())

			While !TRBZY1A->(Eof())
			
				_nnii++
				FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "ACOM017"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "ACOM01710"/*cMsgId*/, "ACOM01710 - Montando pdf da filial " + _cfilatu + " - Linha " + StrZero(_nnii,6) + " de " + StrZero(_ntoti,6) + "..."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

				If nLinAux > (nLinIni+590)
					lPagina := .T.
					oPrint:EndPage()
					oPrint:StartPage()
					A017GRID(_cFilial)
			
					nLinIni	:= 095
					nLinAux := nLinIni
					nColIni	:= 000
					nCont++
				EndIf
             
				U_ACOM017V(TRBZY1A->ZY1_NUMPC,@_cGetSC,@_cGetNF,@_dGetNE,@_cGetFR,@_nGetVL,@_cGetFO,@_cGetOR,@_cGetSP,@_dGetEE,_lCriaAmb,_cfilatu)

				oPrint:Say( (nLinAux) , (nColIni+015) , "Solicitação"			, oFont08 )
				oPrint:Say( (nLinAux) , (nColIni+060) , "Pedido"				, oFont08 )
				oPrint:Say( (nLinAux) , (nColIni+100) , "Fornecedor"			, oFont08 )
				oPrint:Say( (nLinAux) , (nColIni+250) , "Origem"				, oFont08 )
				oPrint:Say( (nLinAux) , (nColIni+370) , "Dt. Nec"		     , oFont08 )
				oPrint:Say( (nLinAux) , (nColIni+410) , "Dt. Fat"		     , oFont08 )
				oPrint:Say( (nLinAux) , (nColIni+465) , "Frete"					, oFont08 )
				oPrint:Say( (nLinAux) , (nColIni+500) , "Valor"					, oFont08 )
				oPrint:Say( (nLinAux) , (nColIni+560) , "Obs Pedido de Compras"	, oFont08 )

				nLinAux := nLinAux + 05

				If nLinAux > (nLinIni+590)
					lPagina := .T.
					oPrint:EndPage()
					oPrint:StartPage()
					A017GRID(_cFilial)
			
					nLinIni	:= 095
					nLinAux := nLinIni
					nColIni	:= 000
					nCont++
				EndIf

				oPrint:Line( nLinAux , nColIni + 10 , nLinAux , nColMax	)

				nLinAux := nLinAux + 10

				If nLinAux > (nLinIni+590)
					lPagina := .T.
					oPrint:EndPage()
					oPrint:StartPage()
					A017GRID(_cFilial)
			
					nLinIni	:= 095
					nLinAux := nLinIni
					nColIni	:= 000
					nCont++
				EndIf
                     	
				oPrint:Say( (nLinAux) , (nColIni+015) , _cGetSC											, oFont08 )
				oPrint:Say( (nLinAux) , (nColIni+060) , TRBZY1A->ZY1_NUMPC								, oFont08 )
				oPrint:Say( (nLinAux) , (nColIni+100) , AllTrim(_cGetFO)								, oFont08 )
				oPrint:Say( (nLinAux) , (nColIni+250) , _cGetOR											, oFont08 )
				oPrint:Say( (nLinAux) , (nColIni+370) , DToC(_dGetNE)									, oFont08 )
				oPrint:Say( (nLinAux) , (nColIni+410) , DToC(_dGetEE)									, oFont08 )
				oPrint:Say( (nLinAux) , (nColIni+465) , _cGetFR											, oFont08 )
				oPrint:Say( (nLinAux) , (nColIni+500) , Transform(_nGetVL,PesqPict("SC7","C7_TOTAL"))	, oFont08 )
				If Len(AllTrim(_cGetSP)) > 60
					_nTam := Len(AllTrim(_cGetSP)) / 60
					_nTam := NoRound(_nTam,0) + 1
					_nIni := 1
					For _nI := 1 To _nTam
						oPrint:Say( (nLinAux) , (nColIni+560) , SubStr(AllTrim(_cGetSP), _nIni , 60)			, oFont08 )
						_nIni := _nIni + 60
						nLinAux := nLinAux + 08
						If nLinAux > (nLinIni+590)
							lPagina := .T.
							oPrint:EndPage()
							oPrint:StartPage()
							A017GRID(_cFilial)
					
							nLinIni	:= 095
							nLinAux := nLinIni
							nColIni	:= 000
							nCont++
						EndIf
					Next _nI
				Else
					oPrint:Say( (nLinAux) , (nColIni+560) , AllTrim(_cGetSP)			, oFont08 )
					_nIni := _nIni + 60
					nLinAux := nLinAux + 08
					If nLinAux > (nLinIni+590)
						lPagina := .T.
						oPrint:EndPage()
						oPrint:StartPage()
						A017GRID(_cFilial)
					
						nLinIni	:= 095
						nLinAux := nLinIni
						nColIni	:= 000
						nCont++
					EndIf
				EndIf

				nLinAux := nLinAux + 05

				If nLinAux > (nLinIni+590)
					lPagina := .T.
					oPrint:EndPage()
					oPrint:StartPage()
					A017GRID(_cFilial)
					
					nLinIni	:= 095
					nLinAux := nLinIni
					nColIni	:= 000
					nCont++
				EndIf

				oPrint:Line( nLinAux , nColIni + 10 , nLinAux , nColMax	)

				nLinAux	:= nLinAux + 10

				If nLinAux > (nLinIni+590)
					lPagina := .T.
					oPrint:EndPage()
					oPrint:StartPage()
					A017GRID(_cFilial)
					
					nLinIni	:= 095
					nLinAux := nLinIni
					nColIni	:= 000
					nCont++
				EndIf

				_cGetNF := "NF/Título: " + _cGetNF

				If Len(AllTrim(_cGetNF)) > 182
					_nTam3 := Len(AllTrim(_cGetNF)) / 182
					_nTam3 := NoRound(_nTam3,0) + 1
					_nIni := 1
					For _nI := 1 To _nTam3
						oPrint:Say( (nLinAux) , (nColIni + 015) , SubStr(AllTrim(_cGetNF),_nIni,12)				, oFont08 )
						_nIni := _nIni + 12
						nLinAux := nLinAux + 08
						
						If nLinAux > (nLinIni+590)
							lPagina := .T.
							oPrint:EndPage()
							oPrint:StartPage()
							A017GRID(_cFilial)
					
							nLinIni	:= 095
							nLinAux := nLinIni
							nColIni	:= 000
							nCont++
						EndIf
					Next _nI
					
				Else
					oPrint:Say( (nLinAux) , (nColIni + 015) , AllTrim(_cGetNF)									, oFont08 )
					_nIni := _nIni + 182
					nLinAux := nLinAux + 08
					
					If nLinAux > (nLinIni+590)
						lPagina := .T.
						oPrint:EndPage()
						oPrint:StartPage()
						nLinIni	:= 095
						nLinAux := nLinIni
						nColIni	:= 000
						nCont++
					EndIf
				EndIf

				nLinAux := nLinAux + 05

				If nLinAux > (nLinIni+590)
					lPagina := .T.
					oPrint:EndPage()
					oPrint:StartPage()
					A017GRID(_cFilial)
					nLinIni	:= 095
					nLinAux := nLinIni
					nColIni	:= 000
					nCont++
				EndIf

				oPrint:Line( nLinAux , nColIni + 10 , nLinAux , nColMax	)

				nLinAux	:= nLinAux + 10

				If nLinAux > (nLinIni+590)
					lPagina := .T.
					oPrint:EndPage()
					oPrint:StartPage()
					A017GRID(_cFilial)
				
					nLinIni	:= 095
					nLinAux := nLinIni
					nColIni	:= 000
					nCont++
				EndIf

				_cStatus := AllTrim("Status: " + TRBZY1A->ZY1_SEQUEN + " - " + DToC(SToD(TRBZY1A->ZY1_DTMONI)) + " - " + TRBZY1A->ZY1_HRMONI + " - " + AllTrim(TRBZY1A->ZY1_COMENT) + " ( " + TRBZY1A->ZY1_CODUSR + "-" + AllTrim(TRBZY1A->ZY1_NOMUSR) + " )")

				If Len(_cStatus) > 182
					_nTam2 := Len(_cStatus) / 182
					_nTam2 := NoRound(_nTam2,0) + 1
					_nIni2 := 1
					For _nI := 1 To _nTam2
						oPrint:Say( (nLinAux) , (nColIni + 015) , SubStr(_cStatus, _nIni2, 182)	, oFont08 )
						_nIni2 := _nIni2 + 182
						nLinAux := nLinAux + 08
						If nLinAux > (nLinIni+590)
							lPagina := .T.
							oPrint:EndPage()
							oPrint:StartPage()
							A017GRID(_cFilial)
					
							nLinIni	:= 095
							nLinAux := nLinIni
							nColIni	:= 000
							nCont++
						EndIf
					Next _nI
				Else
					oPrint:Say( (nLinAux) , (nColIni+015) , _cStatus	, oFont08 )
					_nIni2 := _nIni2 + 182
					nLinAux := nLinAux + 08
					If nLinAux > (nLinIni+590)
						lPagina := .T.
						oPrint:EndPage()
						oPrint:StartPage()
						A017GRID(_cFilial)
				
						nLinIni	:= 095
						nLinAux := nLinIni
						nColIni	:= 000
						nCont++
					EndIf
				EndIf

				nLinAux := nLinAux + 05

				If nLinAux > (nLinIni+590)
					lPagina := .T.
					oPrint:EndPage()
					oPrint:StartPage()
					A017GRID(_cFilial)
			
					nLinIni	:= 095
					nLinAux := nLinIni
					nColIni	:= 000
					nCont++
				EndIf

				oPrint:Line( nLinAux , nColIni + 10 , nLinAux , nColMax	)

				nLinAux := nLinAux + 20

				If nLinAux > (nLinIni+590)
					lPagina := .T.
					oPrint:EndPage()
					oPrint:StartPage()
					A017GRID(_cFilial)
			
					nLinIni	:= 095
					nLinAux := nLinIni
					nColIni	:= 000
					nCont++
				EndIf

				TRBZY1A->(DBSkip())
			End
			
			oPrint:EndPage()
			oPrint:lViewPDF := .F.
			oPrint:Preview()
			FreeObj(oPrint)
			
		EndIf

		TRBZY1A->(DBCloseArea())

If File(_cPathSrvJ + _cFileName)
	_cGetAnx := _cPathSrvJ + _cFileName
EndIf

FWRestArea(_aArea)

Return

/*
===============================================================================================================================
Programa----------: A017GRID
Autor-------------: Darcio Ribeiro Sporl
Data da Criacao---: 25/05/2016 
Descrição---------: Rotina responsável por criar o layout de impressão
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function A017GRID(_cFilial)

Local nLinIni		:= 0		// Linha Lateral (inicial) Esquerda
Local nColIni		:= 0		// Coluna Lateral (inicial) Esquerda
Local nLinMax		:= 0600		// Para implementar layout A4
Local nColMax		:= 0835		// Para implementar layout A4
Local cPathImg		:= GetSrvProfString("Startpath","")
Local cFileImg		:= ""

nLinIni	:= 013
nColIni	:= 000

cFileImg := cPathImg + "LGRL01.BMP"

//==============
// Box Principal
//==============
oPrint:Box( nLinIni, nColIni + 010, nLinMax, nColMax, "-4")

nLinIni := nLinIni + 10

//=========
// Logotipo
//=========
oPrint:SayBitmap( nLinIni, nColIni + 018 , cFileImg , 170 , 058 )

oPrint:Say( (nLinIni+025) , (nColIni+350) , "LISTA DE MONITORAMENTO DE PEDIDOS DE COMPRAS" , oFont14 )

oPrint:Say( (nLinIni+045) , (nColIni+450) , _cFilial + " - " + AllTrim(FwFilialName(cEmpAnt,_cFilial)) , oFont14 )

nLinIni := nLinIni + 60

//=================
// Linha Horizontal
//=================
oPrint:Line( nLinIni, nColIni + 10 , nLinIni , nColMax	)

Return

/*
===============================================================================================================================
Programa----------: A017DEL
Autor-------------: Darcio Ribeiro Sporl
Data da Criacao---: 25/05/2016 
Descrição---------: Função responsável pela exclusão do arquivo pdf gerado no servidor.
Parametros--------: cFile - Caminho + nome do arquivo pdf
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function A017DEL(cFile)

Local nRet := 0

If File(cFile)
	nRet := fErase(cFile)
	If nRet <> 0
		FWLogMsg("ERROR"/*cSeverity*/, /*cTransactionId*/, "ACOM017"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "ACOM01711"/*cMsgId*/, "ACOM01711 - Erro ao excluir o arquivo: " + cFile + " - Erro: " + Str(FError())/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	Else
		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "ACOM017"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "ACOM01712"/*cMsgId*/, "ACOM01712 - Arquivo: " + cFile + " foi excluído com sucesso."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	EndIf
EndIf

Return

/*
===============================================================================================================================
Programa----------: A017DTFT
Autor-------------: Darcio Ribeiro Sporl
Data da Criacao---: 06/06/2016 
Descrição---------: Rotina para alteração de data de faturamento por pedido de compras.
Parametros--------: _ddtfat - data para gravação automática
					_cGetPC - pedido de compras
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function A017DTFT(_ddtfat,_cGetPC)

Local aArea			:= FWGetArea()
Local cGet1			:= SToD("//")
Local nX			:= 0
Local cQry			:= ""
Local cAliasQry		:= GetNextAlias()
Local aHeader		:= {}
Local aCols			:= {}
Local aRecnos		:= {}
Local aAlterFields	:= {}
Local nOpc			:= 0
Local aRecnos2	    := {}
Local _cMotivo   	:= Space(Len(ZY1->ZY1_COMENT))

Local oGet1
Local oSayNDF
Local oSButton1
Local oSButton2

Default _ddtfat := SToD("20010101")//Controle quando vem direto do menu do monitor e do PC
Default _cGetPC := SC7->C7_NUM

Private oDlg
Private oMSNewSC7

DBSelectArea("SY1")
SY1->(DBSetOrder(3)) //Y1_FILIAL + Y1_USER
If SY1->(DBSeek(xFilial("SY1") + __cUserId))
	
	//popula aheader
	aAdd(aHeader,   {"Numero PC   "    	,"C7_NUM"		," ",6	,0," "," ","C"," "," "})
	aAdd(aHeader,   {"Tipo" 				,"C7_TIPO"		," ",1	,0," "," ","N"," "," "})
	aAdd(aHeader,   {"Hr Monitoram" 		,"C7_ITEM"		," ",4	,0," "," ","C"," "," "})
	aAdd(aHeader,   {"Produto     "   		,"C7_PRODUTO"	," ",15	,0," "," ","C"," "," "})
	aAdd(aHeader,   {"Descricao   "  		,"C7_DESCRI"	," ",100,0," "," ","C"," "," "})
	aAdd(aHeader,   {"Dt Faturado " 		,"C7_I_DTFAT"	," ",8	,0," "," ","D"," "," "})
	aAdd(aHeader,   {"Razão Social" 		,"A2_NOME"		," ",40	,0," "," ","C"," "," "})
	
	
	// Somente sao selecionados itens que nao possuem restricoes
	cQry := "SELECT C7_NUM,C7_TIPO,C7_ITEM,C7_PRODUTO,C7_DESCRI,C7_I_DTFAT,C7_FORNECE,C7_LOJA,SC7.R_E_C_N_O_ AS RECSC7,A2_NOME "
	cQry += "FROM " + RetSqlName("SC7") + " SC7 "
	cQry += "INNER JOIN " + RetSqlName("SA2") + " SA2 ON A2_FILIAL = '" + xFilial("SA2") + "' AND A2_COD = C7_FORNECE AND A2_LOJA = C7_LOJA AND SA2.D_E_L_E_T_ = ' ' "
	cQry += "WHERE C7_FILIAL = '" + xFilial("SC7") + "' "
	cQry += "  AND C7_NUM = '" + _cGetPC + "' "
	cQry += "  AND ((C7_QUJE < C7_QUANT "
	cQry += "  OR C7_QTDACLA > 0 ) "
	cQry += "  AND C7_RESIDUO <> 'S') "
	cQry += "  AND SC7.D_E_L_E_T_ = ' ' "
	cQry := ChangeQuery(cQry)

	MPSysOpenQuery(cQry,cAliasQry)

	(cAliasQry)->( DBGoTop() )
	
	If !(cAliasQry)->(Eof())
	
		While (cAliasQry)->(!Eof())
			aAdd(aCols,		{(cAliasQry)->C7_NUM, (cAliasQry)->C7_TIPO, (cAliasQry)->C7_ITEM, (cAliasQry)->C7_PRODUTO, (cAliasQry)->C7_DESCRI, SToD((cAliasQry)->C7_I_DTFAT), (cAliasQry)->A2_NOME,.F.})
			aAdd(aRecnos,	(cAliasQry)->RECSC7)
			(cAliasQry)->(DBSkip())
		End
		
		_npos := ZY1->( Recno() )
		
		_cfilial := xFilial("SC7")
		_cnumpc := _cGetPC

		ZY1->( DBGoTop() )
		ZY1->( DBSeek( _cfilial + _cnumpc) )
		
		
		While ZY1->(!Eof()) .And. _cfilial == ZY1->ZY1_FILIAL .And. _cnumpc == ZY1->ZY1_NUMPC
		
			aAdd(aRecnos2, ZY1->( Recno() ) )
			
			ZY1->( DBSkip() )
			
		EndDo
		
		ZY1->( DBGoTo(_npos) )
		
		cGet1 :=  ZY1->ZY1_DTFAT  
		
		If _ddtfat == SToD("20010101")
		
			DEFINE MSDIALOG oDlg TITLE "Pedido de Compra - Alt.Dt.Fat.PC" FROM 000, 000  To 300, 700 COLORS 0, 16777215 PIXEL
	
				oMSNewSC7 := MsNewGetDados():New( 001, 002, 101, 348, , "AllwaysTrue", "AllwaysTrue", "", aAlterFields,, 999, "AllwaysTrue", "", "AllwaysTrue", oDlg, aHeader, aCols)

			    @ 109, 002 Say oSayNDF PROMPT "Nova Data Faturamento: " SIZE 060, 007 OF oDlg COLORS 0, 16777215 PIXEL
			    @ 107, 064 MSGET oGet1 VAR cGet1 SIZE 055, 010 OF oDlg VALID U_VLDDTFAT(cGet1,2,aRecnos) COLORS 0, 16777215 PIXEL

			    @ 109, 125 Say "Comentario:" SIZE 060, 007 OF oDlg COLORS 0, 16777215 PIXEL
			    @ 107, 155 MSGET _cMotivo    SIZE 190, 010 OF oDlg COLORS 0, 16777215 PIXEL			

				DEFINE SBUTTON oSButton1 FROM 129, 142 Type 01 OF oDlg ENABLE ACTION (nOpc := 1, oDlg:End())
				DEFINE SBUTTON oSButton2 FROM 129, 175 Type 02 OF oDlg ENABLE ACTION (nOpc := 2, oDlg:End())
	
			ACTIVATE MSDIALOG oDlg CENTERED
			
		Else
		
			nOpc := 1
			cGet1 := _ddtfat
			
		EndIf
		
		If nOpc == 1
			If U_VLDDTFAT(cGet1,2,aRecnos)

		        _dDataOld:=CTOD("")
				DBSelectArea("SC7")
				For nX := 1 To Len(aRecnos)
					SC7->(DBGoTo(aRecnos[nX]))
			        _dDataOld:=SC7->C7_I_DTFAT
					RecLock("SC7",.F.)
					SC7->C7_I_DTFAT := cGet1
					SC7->(MSUnLock() )
				Next nX
				
				_nmax := 1
				DBSelectArea("ZY1")
				For nX := 1 To Len(aRecnos2)
					ZY1->(DBGoTo(aRecnos2[nX]))
					If Val(ZY1->ZY1_SEQUEN) > _nmax
						_nmax := Val(ZY1->ZY1_SEQUEN)
					EndIf
					RecLock("ZY1",.F.)
					ZY1->ZY1_DTFAT :=cGet1
					ZY1->(MSUnLock())
				Next nX
				
  	            If _ddtfat == SToD("20010101")
	            
	            	//Cria registro de mudança da data de faturamento
	            	ZY1->(RecLock("ZY1",.T.))
	            	ZY1->ZY1_FILIAL := xFilial("ZY1")
	            	ZY1->ZY1_SEQUEN := StrZero(_nmax,4)
	            	ZY1->ZY1_NUMPC  := SC7->C7_NUM
	            	ZY1->ZY1_DTMONI := Date()
	            	ZY1->ZY1_HRMONI := Time()
                    If Empty(_cMotivo)
                       ZY1->ZY1_COMENT:="Data de faturamento alterada de " + DToC(_dDataOld) + " para " + DToC(SC7->C7_I_DTFAT)
                    Else
                       ZY1->ZY1_COMENT:=_cMotivo
                    EndIf   	            	
	            	ZY1->ZY1_CODUSR := __cUserId                                                                                                                       
	            	ZY1->ZY1_NOMUSR := USRFULLNAME(__cUserId)
	            	ZY1->ZY1_DTFAT  := SC7->C7_I_DTFAT
	            	ZY1->ZY1_DTNECE := SC7->C7_DATPRF  
	            	ZY1->(MSUnLock())

	            	
  	            EndIf

                //Atualiza tabela ZZH de indicaores de pagamentos para pedidos de compra
                U_ACOM008ZZH(AllTrim(SC7->C7_FILIAL), AllTrim(SC7->C7_NUM))	//Fica depois pq desposiciona o SC7

  	            If _ddtfat == SToD("20010101")
	            	U_ITMsg("Data de Faturamento alterada de " + DToC(_dDataOld) + " para " + DToC(cGet1) +" com sucesso.","Atenção",,2)
	            EndIf	
	            
			Else
				U_ITMsg("Processo não pôde ser finalizado.","Atenção",,1)
			EndIf
		EndIf
		
	Else
	
		U_ITMsg("Pedido não pode sofrer alteração de data de faturamento." , "Atenção","Pedido já recebeu movimento de faturamento",1)
	
	EndIf
	
	(cAliasQry)->( DBCloseArea() )
Else
				
	U_ITMsg("Usuário Inválido, O usuário: " + USRFULLNAME(__cUserId) + " não possui acesso para alterar data de faturamento.", "Atenção", "Verifique o cadastro deste usuário como comprador.",1)
	
EndIf

FWRestArea(aArea)

Return

/*
===============================================================================================================================
Programa----------: A017GrvaCols()
Autor-------------: Alex Wallauer
Data da Criacao---: 20/09/2018 
Descrição---------: Rotina para carregar acols
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function A017GrvaCols()

nMaxGravado:=0
While !TRBZY1->(Eof())
    
    If ! "DATA DE FATURAMENTO ALTERADA DE" $ Upper(TRBZY1->ZY1_COMENT)
	   aAdd(_aCols,{TRBZY1->ZY1_SEQUEN, SToD(TRBZY1->ZY1_DTMONI), TRBZY1->ZY1_HRMONI, TRBZY1->ZY1_COMENT, TRBZY1->ZY1_CODUSR, TRBZY1->ZY1_NOMUSR, .F.})
	EndIf   
    If Val(TRBZY1->ZY1_SEQUEN) > nMaxGravado
       nMaxGravado:=Val(TRBZY1->ZY1_SEQUEN)
    EndIf   

    TRBZY1->(DBSkip())
EndDo                 

Return Len(_aCols)
