/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |06/11/2019| Chamado 28346. Revisão de fonte para novo appserver
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "TopConn.ch"

/*
===============================================================================================================================
Programa----------: LSTCUSGRP
Autor-------------: Erich Buttner  
Data da Criacao---: 08/08/2013  
Descrição---------: Essa rotina tem por objetivo inserirmos as funções auxiliares a serem utilizadas por qualquer rotina  
Parametros--------: cTpCus
Retorno-----------: Nenhum   
===============================================================================================================================
*/
User Function LSTCUSGRP(cTpCus)

Local cQuery := ""
Local oLstZL5 := nil
Private oDlgZL5 := nil
Private _bRet := .F.
Private aDadosZL5 := {}
Public cCodigo    := AllTrim(&(ReadVar()))

//Query de marca x produto x referencia
cQuery := " SELECT ZL5_CODGRP, ZL5_DESGRP FROM ZL5010 "
cQuery += " WHERE ZL5_TPCUST = '"+cTpCus+"' "
cQuery += " AND D_E_L_E_T_ = ' ' "
cQuery += " AND ZL5_FILIAL = '"+xFilial("ZL5")+"' "

cAlias1:= CriaTrab(Nil,.F.)

DbUseArea(.T.,"TOPCONN", TCGENQRY(,,cQuery),cAlias1, .F., .T.)

(cAlias1)->(DBGoTop())
If (cAlias1)->(Eof())
	Aviso( "Grupo de Tipo de Custo", "Não existe dados a consultar", {"Ok"} )
	Return .F.
EndIf

While (cAlias1)->(!Eof())
	
	aAdd( aDadosZL5, { (cAlias1)->ZL5_CODGRP, (cAlias1)->ZL5_DESGRP} )
	
	(cAlias1)->(DBSkip())
	
EndDo

(cAlias1)->(DBCloseArea())

nList := 0//aScan(aDadosZL5, {|x| AllTrim(x[3]) == AllTrim(cCodigo)})

IIf(nList = 0,nList := 1,nList)

//--Montagem da Tela
Define MsDialog oDlgZL5 Title "Busca Grupo de Tipo de Custo" From 0,0 To 280, 500 Of oMainWnd Pixel

@ 5,5 LISTBOX oLstZL5 ;
VAR lVarMat ;
Fields HEADER "Cod. Grupo", "Descrição" SIZE 245,110 On DblClick ( ConfZL5(oLstZL5:nAt, @aDadosZL5, @_bRet) ) OF oDlgZL5 PIXEL

oLstZL5:SetArray(aDadosZL5)
oLstZL5:nAt := nList
oLstZL5:bLine := { || {aDadosZL5[oLstZL5:nAt,1], aDadosZL5[oLstZL5:nAt,2]}}

DEFINE SBUTTON FROM 122,5 Type 1 ACTION ConfZL5(oLstZL5:nAt, @aDadosZL5, @_bRet) ENABLE OF oDlgZL5
DEFINE SBUTTON FROM 122,40 Type 2 ACTION oDlgZL5:End() ENABLE OF oDlgZL5

Activate MSDialog oDlgZL5 Centered

Return _bRet


/*
===============================================================================================================================
Programa----------: ConfZL5
Autor-------------: Erich Buttner  
Data da Criacao---: 08/08/2013  
Descrição---------: Essa rotina tem por objetivo inserirmos as funções auxiliares a serem utilizadas por qualquer rotina  
Parametros--------: _nPos, aDadosZL5, _bRet
Retorno-----------: Nenhum   
===============================================================================================================================
*/
Static Function ConfZL5(_nPos, aDadosZL5, _bRet)

cCodigo := aDadosZL5[_nPos,1]

aCols[1,_nPos] := cCodigo

_bRet := .T.

oDlgZL5:End()

Return


/*
===============================================================================================================================
Programa----------: LSTEVECUS
Autor-------------: Erich Buttner  
Data da Criacao---: 08/08/2013  
Descrição---------: Essa rotina tem por objetivo inserirmos as funções auxiliares a serem utilizadas por qualquer rotina  
Parametros--------: _nPos, aDadosZL5, _bRet
Retorno-----------: .T.   
===============================================================================================================================
*/
User Function LSTEVECUS(cTpCus)

Local i := 0

//Local _cFilAnter  := cFilAnt

Private nTam      := 0
Private nMaxSelect:= 0
Private aCat      := {}
Private MvRet     := AllTrim(ReadVar())
Private MvPar     := ""
Private cTitulo   := ""
Private MvParDef  := ""
Private TRB := CriaTrab(Nil,.F.)

If !Empty(AllTrim(MV_PAR04)) .And. !Empty(AllTrim(MV_PAR02)) .And. !Empty(AllTrim(MV_PAR03))
	#IFDEF WINDOWS
		oWnd := GetWndDefault()
	#EndIf
	
	//Tratamento para carregar variaveis da lista de opcoes
	nTam:=6
	nMaxSelect := 14 //75 / 3
	cTitulo :="Evento Custo"
	
	
	cGrpCus:=" SELECT ZL6_FILIAL,ZL6_CODEVE,ZL6_DESEVE,ZL6_TPCUS,ZL6_DTPCUS,ZL6_GRPCUS,ZL6_DGRCUS FROM ZL6010 "
	cGrpCus+=" WHERE ZL6_TPCUS IN "+FormatIn(MV_PAR03,";")+" "
	cGrpCus+=" AND ZL6_GRPCUS IN "+FormatIn(MV_PAR04,";")+" "
	cGrpCus+=" AND D_E_L_E_T_ = ' ' "
	cGrpCus+=" AND ZL6_FILIAL IN "+FormatIn(MV_PAR02,";")+" "
	cGrpCus+=" GROUP BY ZL6_FILIAL,ZL6_CODEVE,ZL6_DESEVE,ZL6_TPCUS,ZL6_DTPCUS,ZL6_GRPCUS,ZL6_DGRCUS "
	
	If Select("TRB") >0
		DBSelectArea("TRB")
		DBCloseArea()
	EndIf
	
	TCQUERY cGrpCus New Alias "TRB"
	DBSelectArea("TRB")
	
	While TRB->(!Eof())
		MvParDef += AllTrim(TRB->ZL6_CODEVE)
		aAdd(aCat,AllTrim(TRB->ZL6_DESEVE)+" / Tipo Custo: "+AllTrim(TRB->ZL6_TPCUS)+" / "+AllTrim(TRB->ZL6_DTPCUS)+" / Grupo Custo: "+TRB->ZL6_GRPCUS;
		+" / "+AllTrim(TRB->ZL6_DGRCUS))
		TRB->(DBSkip())
	EndDo
	
	/*
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Trativa abaixo para no caso de uma alteracao do campo trazer todos³
	//³os dados que foram selecionados anteriormente.                    ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	*/
	If Len(AllTrim(&(MvRet))) == 0
		
		MvPar:= PadR(AllTrim(StrTran(&(MvRet),";","")),Len(aCat))
		&(MvRet):= PadR(AllTrim(StrTran(&(MvRet),";","")),Len(aCat))
		
	Else
		
		MvPar:= AllTrim(StrTran(&(MvRet),";","/"))
		
	EndIf
	
	/*
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Somente altera o conteudo caso o usuario clique no botao ok³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	*/
	
	//Executa funcao que monta tela de opcoes
	If f_Opcoes(@MvPar,cTitulo,aCat,MvParDef,12,49,.F.,nTam,nMaxSelect)
		
		//Tratamento para separar retorno com barra ";"
		&(MvRet) := ""
		For i:=1 to Len(MvPar) step nTam
			If !(SubStr(MvPar,i,1) $ " |*")
				&(MvRet)  += SubStr(MvPar,i,nTam) + ";"
			EndIf
		Next i
		
		//Trata para tirar o ultimo caracter
		&(MvRet) := SubStr(&(MvRet),1,Len(&(MvRet))-1)
		
	EndIf
	
Else
	
	Alert("Preencha o parametro de Tipo de Custo, Grupo Custo e Filial")
EndIf

Return (.T.)
/*
===============================================================================================================================
Programa----------: LSTTPCUS
Autor-------------: Erich Buttner  
Data da Criacao---: 08/08/2013  
Descrição---------: Essa rotina tem por objetivo inserirmos as funções auxiliares a serem utilizadas por qualquer rotina  
Parametros--------: cTpCus
Retorno-----------: Nenhum   
===============================================================================================================================
*/
User Function LSTTPCUS(cTpCus)

Local i := 0

//Local _cFilAnter  := cFilAnt

Private nTam      := 0
Private nMaxSelect:= 0
Private aCat      := {}
Private MvRet     := AllTrim(ReadVar())
Private MvPar     := ""
Private cTitulo   := ""
Private MvParDef  := ""
Private TRB := CriaTrab(Nil,.F.)

If !Empty(AllTrim(MV_PAR03))
	#IFDEF WINDOWS
		oWnd := GetWndDefault()
	#EndIf
	
	//Tratamento para carregar variaveis da lista de opcoes
	nTam:=6
	nMaxSelect := 14 //75 / 3
	cTitulo :="Grupo Custo"
	
	
	cGrpCus:=" SELECT ZL5_CODGRP, ZL5_DESGRP,ZL5_TPCUST, ZL5_DTPCUS FROM ZL5010 "
	cGrpCus+=" WHERE ZL5_TPCUST IN "+FormatIn(MV_PAR03,";")+" "
	cGrpCus+=" AND D_E_L_E_T_ = ' ' "
	cGrpCus+=" AND ZL5_FILIAL = ' ' "
	
	If Select("TRB") >0
		DBSelectArea("TRB")
		DBCloseArea()
	EndIf
	
	TCQUERY cGrpCus New Alias "TRB"
	DBSelectArea("TRB")
	
	While TRB->(!Eof())
		MvParDef += AllTrim(TRB->ZL5_CODGRP)
		aAdd(aCat,AllTrim(TRB->ZL5_DESGRP)+" / Tipo Custo: "+AllTrim(TRB->ZL5_TPCUST)+" / "+AllTrim(TRB->ZL5_DTPCUS)) //aAdd(aCat,AllTrim(TRB->ZL5_DESGRP)+" - Tipo Custo: "+AllTrim(TRB->ZL5_TPCUST)+" - "+AllTrim(TRB->ZL5_DTPCUS))
		TRB->(DBSkip())
	EndDo
	
	/*
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Trativa abaixo para no caso de uma alteracao do campo trazer todos³
	//³os dados que foram selecionados anteriormente.                    ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	*/
	If Len(AllTrim(&(MvRet))) == 0
		
		MvPar:= PadR(AllTrim(StrTran(&(MvRet),";","")),Len(aCat))
		&(MvRet):= PadR(AllTrim(StrTran(&(MvRet),";","")),Len(aCat))
		
	Else
		
		MvPar:= AllTrim(StrTran(&(MvRet),";","/"))
		
	EndIf
	
	/*
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Somente altera o conteudo caso o usuario clique no botao ok³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	*/
	
	//Executa funcao que monta tela de opcoes
	If f_Opcoes(@MvPar,cTitulo,aCat,MvParDef,12,49,.F.,nTam,nMaxSelect)
		
		//Tratamento para separar retorno com barra ";"
		&(MvRet) := ""
		For i:=1 to Len(MvPar) step nTam
			If !(SubStr(MvPar,i,1) $ " |*")
				&(MvRet)  += SubStr(MvPar,i,nTam) + ";"
			EndIf
		Next i
		
		//Trata para tirar o ultimo caracter
		&(MvRet) := SubStr(&(MvRet),1,Len(&(MvRet))-1)
		
	EndIf
	
Else
	
	Alert("Preencha o parametro de Tipo de Custo")
EndIf


Return(.T.)
/*
===============================================================================================================================
Programa----------: LSTSUBEVE
Autor-------------: Erich Buttner  
Data da Criacao---: 02/09/2013  
Descrição---------: Essa rotina tem por objetivo inserirmos as funções auxiliares a serem utilizadas por qualquer rotina  
Parametros--------: cTpCus
Retorno-----------: Nenhum   
===============================================================================================================================
*/
User Function LSTSUBEVE(cTpCus)

Local i := 0

//Local _cFilAnter  := cFilAnt

Private nTam      := 0
Private nMaxSelect:= 0
Private aCat      := {}
Private MvRet     := AllTrim(ReadVar())
Private MvPar     := ""
Private cTitulo   := ""
Private MvParDef  := ""
Private TRB := CriaTrab(Nil,.F.)

If !Empty(AllTrim(MV_PAR04)) .And. !Empty(AllTrim(MV_PAR02)) .And. !Empty(AllTrim(MV_PAR03)).And. !Empty(AllTrim(MV_PAR05))
	#IFDEF WINDOWS
		oWnd := GetWndDefault()
	#EndIf
	
	//Tratamento para carregar variaveis da lista de opcoes
	nTam:=5
	nMaxSelect := 18 //75 / 3
	cTitulo :="Sub-Evento Custo"
	
	
	cGrpCus:=" SELECT ZL6_FILIAL,ZL6_CODEVE,ZL6_DESEVE,ZL6_TPCUS,ZL6_DTPCUS,ZL6_GRPCUS,ZL6_DGRCUS,ZL6_SUBEVE,ZL6_DSUBEV "
	cGrpCus+=" WHERE ZL6_TPCUS IN "+FormatIn(MV_PAR03,";")+" "
	cGrpCus+=" AND ZL6_GRPCUS IN "+FormatIn(MV_PAR04,";")+" "
	cGrpCus+=" AND ZL6_CODEVE IN "+FormatIn(MV_PAR05,";")+" "
	cGrpCus+=" AND D_E_L_E_T_ = ' ' "
	cGrpCus+=" AND ZL6_FILIAL IN "+FormatIn(MV_PAR02,";")+" "
	cGrpCus+=" GROUP BY ZL6_FILIAL,ZL6_CODEVE,ZL6_DESEVE,ZL6_TPCUS,ZL6_DTPCUS,ZL6_GRPCUS,ZL6_DGRCUS,ZL6_SUBEVE,ZL6_DSUBEV "
	
	If Select("TRB") >0
		DBSelectArea("TRB")
		DBCloseArea()
	EndIf
	
	TCQUERY cGrpCus New Alias "TRB"
	DBSelectArea("TRB")
	
	While TRB->(!Eof())
		MvParDef += AllTrim(ZL6_SUBEVE)
		aAdd(aCat,AllTrim(ZL6_DSUBEV)+" / Tipo Custo: "+AllTrim(TRB->ZL6_TPCUS)+" / "+AllTrim(TRB->ZL6_DTPCUS)+" / Grupo Custo: "+TRB->ZL6_GRPCUS;
		+" / "+AllTrim(TRB->ZL6_DGRCUS)+" / Evento Custo: "+AllTrim(ZL6_CODEVE)+" / "+AllTrim(ZL6_DESEVE))
		TRB->(DBSkip())
	EndDo
	
	/*
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Trativa abaixo para no caso de uma alteracao do campo trazer todos³
	//³os dados que foram selecionados anteriormente.                    ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	*/
	If Len(AllTrim(&(MvRet))) == 0
		
		MvPar:= PadR(AllTrim(StrTran(&(MvRet),";","")),Len(aCat))
		&(MvRet):= PadR(AllTrim(StrTran(&(MvRet),";","")),Len(aCat))
		
	Else
		
		MvPar:= AllTrim(StrTran(&(MvRet),";","/"))
		
	EndIf
	
	/*
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Somente altera o conteudo caso o usuario clique no botao ok³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	*/
	
	//Executa funcao que monta tela de opcoes
	If f_Opcoes(@MvPar,cTitulo,aCat,MvParDef,12,49,.F.,nTam,nMaxSelect)
		
		//Tratamento para separar retorno com barra ";"
		&(MvRet) := ""
		For i:=1 to Len(MvPar) step nTam
			If !(SubStr(MvPar,i,1) $ " |*")
				&(MvRet)  += SubStr(MvPar,i,nTam) + ";"
			EndIf
		Next i
		
		//Trata para tirar o ultimo caracter
		&(MvRet) := SubStr(&(MvRet),1,Len(&(MvRet))-1)
		
	EndIf
	
Else
	
	Alert("Preencha o parametro de Tipo de Custo, Grupo Custo, Evento e Filial")
EndIf

Return (.T.)

/*
===============================================================================================================================
Programa----------: LSTTP
Autor-------------: Erich Buttner  
Data da Criacao---: 08/08/2013  
Descrição---------: Essa rotina tem por objetivo inserirmos as funções auxiliares a serem utilizadas por qualquer rotina  
Parametros--------: cTpCus
Retorno-----------: Nenhum   
===============================================================================================================================
*/User Function LSTTP(cTpCus)

Local i := 0

//Local _cFilAnter  := cFilAnt

Private nTam      := 0
Private nMaxSelect:= 0
Private aCat      := {}
Private MvRet     := AllTrim(ReadVar())
Private MvPar     := ""
Private cTitulo   := ""
Private MvParDef  := ""
Private TRB := CriaTrab(Nil,.F.)

#IFDEF WINDOWS
	oWnd := GetWndDefault()
#EndIf

//Tratamento para carregar variaveis da lista de opcoes
nTam:=6
nMaxSelect := 14 //75 / 3
cTitulo :="Tipo Custo"


cGrpCus:=" SELECT * FROM ZL4010 "
cGrpCus+=" WHERE D_E_L_E_T_ = ' ' "
cGrpCus+=" AND ZL4_FILIAL = '"+xFilial("ZL4")+"' "

If Select("TRB") >0
	DBSelectArea("TRB")
	DBCloseArea()
EndIf

TCQUERY cGrpCus New Alias "TRB"
DBSelectArea("TRB")

While TRB->(!Eof())
	MvParDef += AllTrim(TRB->ZL4_COD)
	aAdd(aCat,AllTrim(TRB->ZL4_DESCR))
	TRB->(DBSkip())
EndDo

/*
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Trativa abaixo para no caso de uma alteracao do campo trazer todos³
//³os dados que foram selecionados anteriormente.                    ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/
If Len(AllTrim(&(MvRet))) == 0
	
	MvPar:= PadR(AllTrim(StrTran(&(MvRet),";","")),Len(aCat))
	&(MvRet):= PadR(AllTrim(StrTran(&(MvRet),";","")),Len(aCat))
	
Else
	
	MvPar:= AllTrim(StrTran(&(MvRet),";","/"))
	
EndIf

/*
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Somente altera o conteudo caso o usuario clique no botao ok³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/

//Executa funcao que monta tela de opcoes
If f_Opcoes(@MvPar,cTitulo,aCat,MvParDef,12,49,.F.,nTam,nMaxSelect)
	
	//Tratamento para separar retorno com barra ";"
	&(MvRet) := ""
	For i:=1 to Len(MvPar) step nTam
		If !(SubStr(MvPar,i,1) $ " |*")
			&(MvRet)  += SubStr(MvPar,i,nTam) + ";"
		EndIf
	Next i
	
	//Trata para tirar o ultimo caracter
	&(MvRet) := SubStr(&(MvRet),1,Len(&(MvRet))-1)
	
EndIf

Return(.T.)

/*
===============================================================================================================================
Programa----------: ZA1CDGRP
Autor-------------: Alexandre Villar
Data da Criacao---: 06/11/2014
Descrição---------: Rotina que retorna o código do ítem do Grupo da Tabela ZA1
                    Rotina gerada a partir do fonte AEST008 para padronização - Chamado 6294
Parametros--------: _cGrupo == Código do Grupo Atual
Retorno-----------: _cRet   == Código do próximo item para o cadastro
===============================================================================================================================
*/
User Function ZA1CDGRP( _cGrupo )

Local _aArea	:= FWGetArea()
Local _cAlias	:= GetNextAlias()
Local _cRet		:= ""
Local _cQuery	:= ""

_cQuery := " SELECT MAX( ZA1_COD ) AS CODIGO "
_cQuery += " FROM "+ RetSqlName("ZA1")
_cQuery += " WHERE "
_cQuery += "     D_E_L_E_T_ = ' ' "
_cQuery += " AND ZA1_CDGRUP = '"+ AllTrim( _cGrupo ) +"' "

If Select(_cAlias) > 0
	(_cAlias)->( DBCloseArea() )
EndIf

DBUseArea( .T. , "TOPCONN" , TCGENQRY( ,, _cQuery ) , _cAlias , .F. , .T. )

DBSelectArea(_cAlias)
(_cAlias)->( DBGoTop() )
If (_cAlias)->(!Eof())
	_cRet := Soma1( (_cAlias)->CODIGO )
Else
	_cRet := '001'
EndIf

While !MayIUseCode( "ZA1_COD_"+ xFilial("ZA1") + _cRet )	// Verifica se esta sendo usado na memoria
	_cRet := Soma1( _cRet )									// Busca o próximo número disponivel
EndDo

(_cAlias)->( DBCloseArea() )

FWRestArea( _aArea )

Return( _cRet )

/*
===============================================================================================================================
Programa----------: VldZLH
Autor-------------: Xavier
Data da Criacao---: 07-04-2015
Descrição---------: Validar primeiro caracter nos campos de centro de custo com amarração para ZLH
Parametros--------: caracter (Filial de acesso)
Retorno-----------: Logico
===============================================================================================================================
*/
User Function VldZLH(cFil)
Local aArea := FWGetArea()
Local lOk := .T.
Local cCusto := AllTrim(ReadVar())

If !Empty(&(cCusto)) // Centro de custo informado
	DBSelectArea("ZLH")
	DBSetOrder(1)
	If ZLH->(DBSeek(xFilial("ZLH")+cFil))
		If ! ( SubStr( &(cCusto),1,1) $ AllTrim(ZLH->ZLH_CCUSTO) )
			lOk := .F.
			Aviso(FunName(), 'Centro de custo não configurado para essa filial',{'STOP'},1)
		EndIf
	EndIf
EndIf
FWRestArea(aArea)
Return(lOk)


/*
===============================================================================================================================
Programa----------: GDTotSB2
Autor-------------: Xavier
Data da Criacao---: 15-04-2015
Descrição---------: Apresentar os saldos totais do SB2 (quantidade e valor)
Parametros--------: caracter (codigo produto)
Retorno-----------: Objeto Grid
===============================================================================================================================
*/
User Function GDTotSB2(cProduto)

Local aAreaSb1 := SB1->(GetArea())
Local aSb2 := {}
Local cQry := ''
Local cAlias:= GetNextAlias()
Local oBrw,oDlg,oMainWnd, oSay, oGet, oButton
cProduto := If(ValType(cProduto)=='U',SB1->B1_COD,cProduto)

SB1->(DBSetOrder(1))
SB1->(DBSeek(xFilial("SB1")+cProduto))
cGet := AllTrim(SB1->B1_COD) + " - " + AllTrim(SB1->B1_DESC) + " - " + SB1->B1_UM

cQry += " SELECT B2_FILIAL, SUM(B2_QATU) B2_QATU, SUM(B2_VATU1) B2_VATU1 "
cQry += " FROM "+RetSqlname("SB2")
cQry += " WHERE D_E_L_E_T_ = ' ' "
cQry += " AND B2_COD = '"+SB1->B1_COD+"' "
cQry += " AND B2_STATUS <> '2' "
cQry += " GROUP BY B2_FILIAL "
cQry += " UNION ALL "
cQry += " SELECT 'TOTAIS' B2_FILIAL, SUM(B2_QATU) B2_QATU, SUM(B2_VATU1) B2_VATU1 "
cQry += " FROM "+RetSqlname("SB2")
cQry += " WHERE D_E_L_E_T_ = ' ' "
cQry += " AND B2_COD = '"+SB1->B1_COD+"' "
cQry += " AND B2_STATUS <> '2' "

cQry := ChangeQuery(cQry)

DbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),cAlias,.T.,.T.)

(cAlias)->(DBGoTop())

While (cAlias)->(!Eof())
	aAdd(aSb2, {(cAlias)->B2_FILIAL , ;
	Transform((cAlias)->B2_QATU,PesqPict("SB2","B2_QATU")), ;
	Transform((cAlias)->B2_VATU1,PesqPict("SB2","B2_VATU1")) } )
	(cAlias)->(DBSkip())
EndDo

(cAlias)->(DBCloseArea())

DEFINE MSDIALOG oDlg FROM 000,000  TO 300,430 TITLE "Totais em Estoque" Of oMainWnd PIXEL

@ 004, 007 Say   oSay PROMPT "Produto:" SIZE 025, 007 OF oDlg COLORS 0, 16777215 PIXEL
@ 013, 007 MSGET oGet VAR cGet SIZE 200, 010 OF oDlg COLORS 0, 16777215 READONLY PIXEL
DEFINE SBUTTON oButton FROM 129, 130 Type 01 OF oDlg ENABLE ACTION {|| odlg:End()}

oBrw := TWBrowse():New( 027,007,200,100,,{"Filial","Quantidade","Valor(R$)"},{20,50,50},oDlg,,,,,,,,,,,,.F.,,.T.,,.F.,,,.F.)
oBrw:SetArray(aSB2)
oBrw:bLine := {||{aSb2[oBrw:nAt,01],aSb2[oBrw:nAt,02],aSb2[oBrw:nAt,03] } }

ACTIVATE MSDIALOG oDlg CENTERED

FWRestArea(aAreaSb1)

Return
