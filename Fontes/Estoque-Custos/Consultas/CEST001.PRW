/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Josué Danich  |25/09/2015| Chamado 11949. Modificado browse para permitir pesquisa
Josué Danich  |12/06/2019| Chamado 29593. Ajustes para loboguara.
Lucas Borges  |10/09/2024| Chamado 48465. Removendo warning de compilação.
==============================================================================================================================
*/

#Include "FWMVCDEF.CH"
#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: CEST001
Autor-------------: Xavier
Data da Criacao---: 15/04/2015
Descrição---------: Consultar saldos e valores de produtos por filiais
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function CEST001

Local _aStru	:= {}
Local _cQry		:= ''
Local _cPerg	:= "CEST001"
Local _cProd1	:= _cProd2 := _cGrupo1 := _cGrupo2 := _cDesc1 := _cDesc2 := ""
Local _aAreaSM0 := SM0->(FWGetArea())

Private cAlias:= GetNextAlias()
Private _aCpos := {}

If ! Pergunte(_cPerg,.T.)
	Return
EndIf

_cProd1  := MV_PAR01
_cProd2  := MV_PAR02
_cGrupo1 := MV_PAR03
_cGrupo2 := MV_PAR04
_cDesc1  := MV_PAR05
_cDesc2  := MV_PAR06
_lSldZero := (MV_PAR07 = 1) //SIM

//criar estrutura de arquivo temporario
aAdd(_aStru,{"PRODUTO","C",TamSX3("B1_COD")[1],TamSX3("B1_COD")[2]})
aAdd(_aStru,{"DESCR"   ,"C",TamSX3("B1_DESC")[1],TamSX3("B1_DESC")[2]})
aAdd(_aStru,{"GRUPO"  ,"C",TamSX3("B1_GRUPO")[1],TamSX3("B1_GRUPO")[2]})
aAdd(_aStru,{"UM"     ,"C",TamSX3("B1_UM")[1],TamSX3("B1_UM")[2]})
aAdd(_aStru,{"DESCD"   ,"C",TamSX3("B1_DESC")[1],TamSX3("B1_I_DESCD")[2]})

_aAreaSM0 := SM0->(GetArea())

SM0->(DBSeek(cEmpAnt))

While SM0->(!Eof()) .And. SM0->M0_CODIGO = cEmpAnt
	
	aAdd(_aStru,{"QTD"+AllTrim(SM0->M0_CODFIL),"N",TamSX3("B2_QATU")[1]+2,TamSX3("B2_QATU")[2]})
	aAdd(_aStru,{"VLR"+AllTrim(SM0->M0_CODFIL),"N",TamSX3("B2_VATU1")[1]+2,TamSX3("B2_VATU1")[2]})
	
	SM0->(DBSkip())

EndDo

FWRestArea(_aAreaSM0)

aAdd(_aStru,{"TOTQTD","N",( TamSX3("B2_QATU")[1] )+2,TamSX3("B2_QATU")[2]})
aAdd(_aStru,{"TOTVLR","N",( TamSX3("B2_VATU1")[1] )+2,TamSX3("B2_VATU1")[2]})

_otemp := FWTemporaryTable():New( "ZTRB", _aStru )

_otemp:AddIndex( "01", {"PRODUTO"} )
_otemp:AddIndex( "02", {"DESCR"} )
_otemp:AddIndex( "03", {"DESCD"} )

_otemp:Create()

//consultar os dados de estoque atual
_cQry += " SELECT B2_COD, B2_FILIAL, SUM(B2_QATU) B2_QATU, SUM(B2_VATU1) B2_VATU1, B1_UM, B1_DESC, B1_GRUPO "
_cQry += " FROM "+RetSqlname("SB2")+" B2 "
_cQry += " INNER JOIN "+RetSqlname("SB1")+" B1 "
_cQry += " ON B2_COD = B1_COD "
_cQry += " WHERE B2.D_E_L_E_T_ = ' ' AND B1.D_E_L_E_T_ = ' '"
_cQry += " AND B2_COD BETWEEN '"+_cProd1+"' AND '"+_cProd2+"' "
_cQry += " AND B1_GRUPO BETWEEN '"+_cGrupo1+" ' AND '"+_cGrupo2+"' "
_cQry += " AND B1_DESC BETWEEN '"+_cDesc1+"' AND '"+_cDesc2+"' "
_cQry += " AND B2_STATUS <> '2' "
_cQry += " AND B2_QATU > 0 "
_cQry += " GROUP BY B2_COD , B2_FILIAL , B1_UM, B1_DESC, B1_GRUPO "
_cQry += " ORDER BY B2_COD, B2_FILIAL "

_cQry := ChangeQuery(_cQry)
DbUseArea(.T.,"TOPCONN",TcGenQry(,,_cQry),cAlias,.T.,.T.)

MsAguarde({|| CEST001A() },"Filtrando registros...")

Return

/*
===============================================================================================================================
Programa----------: CEST001A
Autor-------------: Xavier
Data da Criacao---: 15-04-2015
Descrição---------: Filtrando dados para apresentação da planilha
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function CEST001A()

Local _nx := 0
Local _aFil := {}
Local _aCpos := {}
Local _aAreaSM0 := SM0->(FWGetArea())
Local _lInc := .T.
Local _cQTD := ""
Local _cVLR := ""
Private aRotina := {}

//atualizar arquivo de trabalho
(cAlias)->(DBGoTop())
DBSelectArea("ZTRB")
ZTRB->(DBSetOrder(2))

While (cAlias)->(!Eof())
	
	MsProcTxt("Processando produto "+AllTrim((cAlias)->B2_COD))
	
	_lInc := .T.
	If ZTRB->(DBSeek((cAlias)->B2_COD))
		_lInc := .F.
	EndIf
	
	RecLock("ZTRB",_lInc)
	If _lInc
		ZTRB->PRODUTO := AllTrim((cAlias)->B2_COD)
		ZTRB->DESCR    := AllTrim((cAlias)->B1_DESC)
		ZTRB->DESCD    := AllTrim(Posicione("SB1",1,xFilial("SB1")+AllTrim((cAlias)->B2_COD),"B1_I_DESCD"))
		ZTRB->GRUPO   := AllTrim((cAlias)->B1_GRUPO)
		ZTRB->UM      := AllTrim((cAlias)->B1_UM)
	EndIf
	
	//gravar o conteudo referente a filial
	_cQTD := "QTD"+(cAlias)->B2_FILIAL
	_cVLR := "VLR"+(cAlias)->B2_FILIAL
	
	ZTRB->&(_cQTD) := (cAlias)->B2_QATU
	ZTRB->&(_cVLR) := (cAlias)->B2_VATU1
	ZTRB->TOTQTD  := ZTRB->TOTQTD + (cAlias)->B2_QATU
	ZTRB->TOTVLR  := ZTRB->TOTVLR + (cAlias)->B2_VATU1
	ZTRB->(MSUnLock())
	
	//identificar as filiais que possuem quantidades
	If aScan(_aFil, { |x| x = (cAlias)->B2_FILIAL }) <= 0
		aAdd(_aFil, (cAlias)->B2_FILIAL )
	EndIf
	
	(cAlias)->(DBSkip())
	
EndDo

(cAlias)->(DBCloseArea())

//refazer os campos que apareceram no browse
_aCpos := {;
{"Produto" ,"PRODUTO" ,"C",PesqPict("SB1","B1_COD"),2,TamSX3("B1_COD")[1],TamSX3("B1_COD")[2]},;
{"Descricao" ,"DESCR" ,"C",PesqPict("SB1","B1_DESC"),1,TamSX3("B1_DESC")[1],TamSX3("B1_DESC")[2]},;
{"Desc Detalhada" ,"DESCD" ,"C",PesqPict("SB1","B1_DESC"),1,TamSX3("B1_DESC")[1],TamSX3("B1_DESC")[2]},;
{"Grupo" ,"GRUPO" ,"C",PesqPict("SB1","B1_GRUPO"),2,TamSX3("B1_GRUPO")[1],TamSX3("B1_GRUPO")[2]},;
{"UM" ,"UM" ,"C",PesqPict("SB1","B1_UM"),2,TamSX3("B1_UM")[1],TamSX3("B1_UM")[2]}}

If ! _lSldZero //apresentar somente filiais com quantidades
	For _nx := 1 To Len(_aFil)
		SM0->(DBSeek(cEmpAnt+_aFil[_nx]))
		aAdd(_aCpos,{"Qt."+AllTrim(SM0->M0_FILIAL),"QTD"+_aFil[_nx],"N",PesqPict("SB2","B2_QATU"),2,TamSX3("B2_QATU")[1]+2,TamSX3("B2_QATU")[2]})
		aAdd(_aCpos,{"Vl."+AllTrim(SM0->M0_FILIAL),"VLR"+_aFil[_nx],"N",PesqPict("SB2","B2_VATU1"),2,TamSX3("B2_VATU1")[1]+2,TamSX3("B2_VATU1")[2]})
	Next _nx
Else  //apresentar todas as filiais
	SM0->(DBSeek(cEmpAnt))
	While SM0->(!Eof()) .And. SM0->M0_CODIGO = cEmpAnt
		aAdd(_aCpos,{"Qt."+AllTrim(SM0->M0_FILIAL),"QTD"+AllTrim(SM0->M0_CODFIL),"N",PesqPict("SB2","B2_QATU"),2,TamSX3("B2_QATU")[1]+2,TamSX3("B2_QATU")[2]})
		aAdd(_aCpos,{"Vl."+AllTrim(SM0->M0_FILIAL),"VLR"+AllTrim(SM0->M0_CODFIL),"N",PesqPict("SB2","B2_VATU1"),2,TamSX3("B2_VATU1")[1]+2,TamSX3("B2_VATU1")[2]})
		SM0->(DBSkip())
	EndDo
EndIf

aAdd(_aCpos,{"Qtd.Total","TOTQTD","N",PesqPict("SB2","B2_QATU"),2,TamSX3("B2_QATU")[1]+2,TamSX3("B2_QATU")[2]})
aAdd(_aCpos,{"Vlr.Total","TOTVLR","N",PesqPict("SB2","B2_VATU1"),2,TamSX3("B2_VATU1")[1]+2,TamSX3("B2_VATU1")[2]})
       
FWRestArea(_aAreaSM0)

//apresentar a planilha de registros
ZTRB->(DBGoTop())

//Instaciamento
oBrw := FWMBrowse():New()

//tabela que será utilizada
oBrw:SetAlias( "ZTRB" )

//Titulo
oBrw:SetDescription( "Saldos de Produtos" )

//seta as colunas para o browse
oBrw:SetFields(_aCpos)

_apesq  := {}
_apesq2 := {}

aAdd(_apesq,"Descricao")
aAdd(_apesq,{{"     " ,"C",TamSX3("B1_DESC")[1],TamSX3("B1_DESC")[2],"Descrição",PesqPict("SB1","B1_DESC"),"DESCR"}})
aAdd(_apesq,4)
aAdd(_apesq,.T.)

aAdd(_apesq2,_apesq)
_apesq := {}

aAdd(_apesq,"Codigo")
aAdd(_apesq,{{"     " ,"C",TamSX3("B1_COD")[1],TamSX3("B1_COD")[2],"Código Produto",PesqPict("SB1","B1_COD"),"PRODUTO"}})
aAdd(_apesq,2)
aAdd(_apesq,.T.)

aAdd(_apesq2,_apesq)
_apesq := {}

aAdd(_apesq,"Desc Detalhada")
aAdd(_apesq,{{"     " ,"C",TamSX3("B1_DESC")[1],TamSX3("B1_DESC")[2],"Desc Detalhada",PesqPict("SB1","B1_DESC"),"DESCD"}})
aAdd(_apesq,5)
aAdd(_apesq,.T.)

aAdd(_apesq2,_apesq)

oBrw:SetSeek(.T.,_apesq2)

//define as legendas
oBrw:AddLegend('TOTVLR > 0 ',"BR_VERDE" ,"Valor Total Positivo")
oBrw:AddLegend('TOTVLR <= 0 ',"BR_VERMELHO","Valor total zerado ou negativo")

//Desabilita tela de detalhes e walthru e ambiente
OBrw:SetWalkThru(.F.)
OBrw:SetAmbiente(.F.)
oBrw:DisableDetails()

//botão sair
ADD OPTION aRotina Title ''	Action ''				OPERATION 1 ACCESS 0

//ativa
oBrw:Activate()

ZTRB->(DBCloseArea())

Return
