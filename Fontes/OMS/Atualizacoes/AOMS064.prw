/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Igor Melgaço  |22/07/2025| Chamado 51487. Ajuste para correção de error.log invalid field name in Alias TMPVS->OPER 
Lucas Borges  |18/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
Lucas Borges  |02/10/2025| Chamado 51526. Modificada forma para recuperar a matrícula do usuário.
===============================================================================================================================
*/

#Include	"Protheus.Ch"
#Include	"FWMVCDef.Ch"
#Include 	"RWMAKE.CH"
#Include 	"vKey.ch"

#Define _ASALDOS	24
#Define _LIMCREDM	01
#Define _LIMCRED	02
#Define _SALDUPM	03
#Define _SALDUP		04
#Define _SALPEDLM	05
#Define _SALPEDL	06
#Define _MCOMPRAM	07
#Define _MCOMPRA	08
#Define _SALDOLCM	09
#Define _SALDOLC	10
#Define _MAIDUPLM	11
#Define _MAIDUPL	12
#Define _ITATUM		13
#Define _ITATU		14
#Define _PEDATUM	15
#Define _PEDATU		16
#Define _VALATRM	19
#Define _VALATR		20
#Define _LCFINM		21
#Define _LCFIN		22
#Define _SALFINM	23
#Define _SALFIN		24
#DEFINE QTDETITULOS	1
#DEFINE MOEDATIT	2
#DEFINE VALORTIT	3
#DEFINE VALORREAIS	4

/*
===============================================================================================================================
Programa----------: AOMS064
Autor-------------: Alexandre Villar
Data da Criacao---: 17/02/2014
Descrição---------: Tela de liberação de crédito para pedido de vendas
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS064

Private _cPerg 	:= "AOMS064M"
Private _aCores	:= {}
Private bped		:= nil
Public cChama 	:= ""

Private _nAltCombo:=10
Private _nLB      :=20
Private _nMSS     :=24
Private _nmvpar02
Private _cUsrFullName:=UsrFullName(__cUserId)
Private cObsAva			:= Space(200)
Private dlimite			:= dDataBase + 7

AOMS064TT() //Ajusta variaveis de tamanho de tela

If Pergunte(_cPerg,.T.)
   //===============================================================
   // Grava log da rotina de liberação de créditos para  
   // o pedido de vendas.
   //=============================================================== 
	_nSelOrigem:=MV_PAR01
	_nmvpar02 := MV_PAR02

    _cTittulo:= IIf(_nSelOrigem == 1," Liberação Credito para  Pedidos Venda " ," Liberação Pedidos de Venda Portal - Análise de Crédito ")

	U_AOMS064Y() //Libera pedidos de venda 
	
EndIf

Return

/*
===============================================================================================================================
Programa----------: AOMS064Y
Autor-------------: Josué Danich Prestes
Data da Criacao---: 17/02/2016
Descrição---------: Avaliação de Pedidos Bloqueados por Limite de Crédito de pedidos de vendas
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS064Y

Local oproc

Private _aCpoBrw                          
Private _aCpoTMP64
Private _oTemp
Private lInverte := .F.
Private cMarkado	:= GetMark()
Private oMark
Private cPesq,lCheck1,lCheck2,lCheck3
Private aOrdem	:= {"PEDIDO","CLIENTE","DATA EMISSAO"}
Private cOrdem	:= aOrdem[3]
Private cPESQUISA:= Space(200), oPesquisa
Private _aMarcados:={}
Private oValor
Private _nValor := 0
Private oQtda
Private nQtdTit := 0

cPesq     := Space(50)
lCheck1   := .T.
lCheck2   := .T.
lCheck3   := .T.

cChama := "1"

While cChama != "5"

	FWMsgRun( ,{|oproc| AOMS064PP(oproc) }				, 'Aguarde!' , 'Verificando os dados...'  )
    cChama := "5"

	@ aSize[7],000 To aSize[6],aSize[5] DIALOG oDlg64Lib TITLE _cTittulo

  oMark:=MsSelect():New("TMP64","OK2"     ,    ,_aCpoBrw ,@lInverte  , @cMarkado , {040,005 ,aSize[4]-_nMSS,aSize[3]},,,,,_aCores)
	  
	oMark:oBrowse:lHasMark := .T.
	oMark:oBrowse:lCanAllMark:=.F.
	oMark:bMark := {|| U_AOMS064I()}
	

	@ 003,006 To 034,315 Title " Pesquisa "
	@ 017,008 Say "Ordem: "  Object oOrdem
	@ 016,030 ComboBox cOrdem ITEMS aOrdem SIZE	070,_nAltCombo Object oOrdem
	@ 016,110 Get cPESQUISA Size 180,10 Object oPesquisa WHEN (cOrdem <> "DATA EMISSAO" )
	oOrdem:bChange := {|| AOMS064FO(cOrdem),oMark:oBrowse:Refresh(.T.)}
    nCol1:=055
    nCol2:=075
    nLin1:=001
    nLin2:=001
	@ nLin1,nCol1 Say ("Valor Total:") SIZE 20,20 OF oDlg64Lib 
	@ nLin2,0060  Say oValor VAR _nValor Picture "@E 999,999,999.99"  OF oDlg64Lib 
	@ nLin1,nCol2 Say ("Quantidade:") SIZE 20,20 OF oDlg64Lib
	@ nLin2,0080  Say oQtda VAR nQtdTit Picture "@E 99999" OF oDlg64Lib  


	@ 015,330 Button "Pesquisar"       	 Size 40,13	Action AOMS064P(cOrdem)	Object oBtnRet

	@ aSize[4]-_nLB,330 Button "Liberar Marcados" Size 80,13	Action eval( {|| AOMS064K() ,oMark:oBrowse:Refresh()} 	)			Object oBtnRet
	
	@ aSize[4]-_nLB,440 Button "Atualizar" Size 40,13	Action eval( {|| AOMS064H() ,oMark:oBrowse:Refresh()} 	)			Object oBtnRet
	
	@ aSize[4]-_nLB,495 Button "Legenda" Size 40,13	Action eval( {|| AOMS064C() ,oMark:oBrowse:Refresh()} 	)			Object oBtnRet

    @ aSize[4]-_nLB,540 Button "Avaliar" Size 40,13	Action ( U_AOMS64PAV() ,oMark:oBrowse:Refresh() , .F. ) 	Object oBtnRet

	@ aSize[4]-_nLB,595 Button "Sair"	 Size 40,13	Action eval( {|| AOMS0648(oDlg64Lib) ,oMark:oBrowse:Refresh()}) 	Object oBtnRet

	DBSelectArea("TMP64")
	TMP64->( DBGoTop() )

	While !TMP64->(Eof())

		RecLock("TMP64",.F.)
		TMP64->OK    := ThisMark()
		TMP64->(MSUnLock())
		TMP64->(DBSkip())

	End

	TMP64->( DBGoTop() )
	TMP64->( DBSetOrder(3))//inicia com a ordem de DT emissao

	oMark:oBrowse:Refresh()

	ACTIVATE DIALOG oDlg64Lib CENTERED

    _oTemp:Delete()

EndDo

Return

/*
===============================================================================================================================
Programa----------: AOMS64H()
Autor-------------: Josué Danich Prestes
Data da Criacao---: 07/08/2018
Descrição---------: Atualiza Browse de pedidos de vendas do Protheus
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS064H

Local oproc

FWMsgRun( ,{|oproc| AOMS064PP(oproc) }				, 'Aguarde!' , 'Verificando os dados...'  )

AOMS064FO(cOrdem)
TMP64->( DBGoTop() )
oMark:oBrowse:Refresh()

Return

/*
===============================================================================================================================
Programa----------: AOMS64PAV()
Autor-------------: Alexandre Villar
Data da Criacao---: 17/02/2014
Descrição---------: Realiza a Avaliação do Pedido de Venda Selecionado.
Parametros--------: oproc - objeto da barra de processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS64PAV

Local aArea:=FWGetArea()

Private aRotina		:= {}

aAdd(aRotina,{"Pesquisar"		,""	, 0, 1  }) //"Pesquisar"
aAdd(aRotina,{"Visualizar"		,""	, 0, 2  }) //"Visualizar"
aAdd(aRotina,{"Incluir"			,""	, 0, 3  }) //"Incluir"
aAdd(aRotina,{"Alterar"			,""	, 0, 4  }) //"Alterar"

While .T.
	
    _lLoopAltCleinte:=.F.

	If _nSelOrigem == 1
		
		FWMsgRun( ,{|oproc| AOMS0649(TMP64->NUMPED,SubStr(TMP64->FILIAL,1,2),oproc) },"Avalia Cliente","Carregando dados...",.F.)
		
	Else
		
		SZW->(DBGoTo(TMP64->RECSZW))
		
		FWMsgRun(,{|oproc| U_AOMS64AV(oproc) }, "Avalia Cliente", "Carregando dados...")
		
	EndIf
	
	If  !_lLoopAltCleinte
		Exit
	EndIf
	
EndDo

FWRestArea(aArea)

Return .T.

/*
===============================================================================================================================
Programa----------: AOMS64AV()
Autor-------------: Alexandre Villar
Data da Criacao---: 17/02/2014
Descrição---------: Realiza a Avaliação do Pedido de Venda Selecionado.
Parametros--------: oproc - objeto da barra de processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS64AV(oProc As Object)

Local aArea			:= FWGetArea() As Array
Local nValPed		:= 0 As Numeric
Local nLimCred		:= 0 As Numeric
Local nMoeda		:= 0 As Numeric
Local nSalPedL		:= 0 As Numeric
Local nSalPed		:= 0 As Numeric
Local nSalDup		:= 0 As Numeric
Local nOpca			:= 0 As Numeric
Local nOpcCnf		:= 0 As Numeric
Local cDescBloq		:= "" As Char
Local cDescri		:= "" As Char
Local cTitAux		:= "Liberação de Crédito" As Char
Local oDlg			:= Nil As Object
Local nMCusto		:= 0 As Numeric
Local nDecs			:= 0 As Numeric
Local aSaldos		:= {} As Array
Local lAvaAux		:= .T. As Logic
Local nSalFin		:= 0 As Numeric
Local nSalFinM		:= 0 As Numeric
Local nLcFin		:= 0 As Numeric
Local aCols			:= {} As Array
Local aHeader		:= {} As Array
Local cMoeda		:= "" As Char
Local cAlias		:= GetNextAlias() As Char
Local _nValzwBL 	:= 0 As Numeric
Local _nValpedb 	:= 0 As Numeric
Local nvalatr		:= 0 As Numeric
Local nQTDAtr		:= 0 As Numeric
Local nvalmar		:= 0 As Numeric
Local nQTDmar		:= 0 As Numeric
Local nvalatu		:= 0 As Numeric
Local nValncc		:= 0 As Numeric
Local cMatUsr		:= FWSFAllUsers({__cUserID},{"USR_FILIAL"})[1][3]+FWSFAllUsers({__cUserID},{"USR_CODFUNC"})[1][3] As Char
Local cAutoriz		:= GetAdvFVal( "ZZL" , "ZZL_LIBCRE" , xFilial("ZZL") + cMatUsr , 1 , "N" ) As Char
Local _nOpcFin  	:= 0 As Numeric
Local _cUFVerIf     := SuperGetMv("MV_AOMS64E",.F.,"RJ") As Char
Local _cEstado	    := "" As Char

Private cCadastro 	:= "Análise de Crédito de Clientes" As Char
Private aRotAuto  	:= Nil As Array
Private inclui 		:= .F. As Logical
Private altera		:= .T. As Logical

//-- Controle de acesso por usuario conforme parametrizacao no Gerenciador (Gestao de Usuarios) --//
If !( cAutoriz == "S" )
	U_ITMsg("Usuário sem acesso à rotina de avaliação dos Pedidos bloqueados para análise de Crédito.","Atenção!",,1)
	Return
EndIf

//-- Posiciona no Cliente --//
DBSelectArea("SA1")
SA1->( DBSetOrder(1) )
SA1->( DBSeek( xFilial("SA1") + SZW->( ZW_CLIENTE + ZW_LOJACLI ) ) )
_cEstado := SA1->A1_EST

nMCusto := IIf( SA1->A1_MOEDALC > 0 , SA1->A1_MOEDALC , Val( SuperGetMv("MV_MCUSTO") ) )
cMoeda	:= " "+ Pad( SuperGetMv( "MV_SIMB" + AllTrim(Str(nMCusto))) , 4 )
nDecs	:= MsDecimais( nMcusto )

oproc:cCaption := "Carregando dados cliente..."
	
//-- Soma-se Todos os Limites de Credito do Cliente --//
DBSelectArea("SA1")
SA1->( DBSetOrder(1) )
SA1->( DBSeek( xFilial("SA1") + SZW->ZW_CLIENTE ) )

While SA1->(!Eof()) .And. SA1->A1_COD == SZW->ZW_CLIENTE
		
	nSalPed 	+= SA1->A1_SALPED + SA1->A1_SALPEDB	
	nSalPedL	+= SA1->A1_SALPEDL					
	nLcFin		+= SA1->A1_LCFIN					
	nSalFinM	+= SA1->A1_SALFINM					
	nSalDup		+= SA1->A1_SALDUP
	nSalFin		+= SA1->A1_SALFIN
	nLimCred	+= SA1->A1_LC
	
SA1->( DBSkip() )
EndDo

oproc:cCaption := "Carregando dados limites de crédito..."

u_VeriSal( SZW->ZW_CLIENTE , SZW->ZW_LOJACLI , 1 )

//-- Reposiciona no Cliente --//
DBSelectArea("SA1")
SA1->( DBSetOrder(1) )
SA1->( DBSeek( xFilial("SA1") + SZW->( ZW_CLIENTE + ZW_LOJACLI ) ) )

nMoeda		:= 1
nValPed		:= AOMS064VTP( SZW->ZW_IDPED , SZW->ZW_FILIAL ,, 1) 
cDescBloq	:= IIf(SZW->ZW_BLQLCR=="B","Bloqueado",IIf(SZW->ZW_BLQLCR=="R","Rejeitado",IIf(SZW->ZW_BLQLCR=="Z","Cliente Bloq","Outros")))
cDescri		:= SubStr(SA1->A1_NOME,1,35)

oproc:cCaption :=  "Carregando dados titulos em atraso..."

//-- Verifica o saldo atual em atraso do Cliente --//
_cQuery := " SELECT "
_cQuery += "     SUM( SE1.E1_SALDO + SE1.E1_SDACRES - SE1.E1_SDDECRE ) AS VALUSO, count(*) as totuso "
_cQuery += " FROM "+ RetSqlName("SE1") +" SE1 "
_cQuery += " WHERE "
_cQuery += "     (SE1.E1_CLIENTE	= '"+ SZW->ZW_CLIENTE +"'  OR SE1.E1_I_CLIEN	= '"+ SZW->ZW_CLIENTE +"' ) "
_cQuery += " AND SE1.D_E_L_E_T_	= ' ' "
_cQuery += " AND SE1.E1_TIPO		NOT IN ('RA','NCC') "
_cQuery += " AND SE1.E1_SALDO + SE1.E1_SDACRES - SE1.E1_SDDECRE > 0 "
_cQuery += " AND SE1.E1_VENCREA < '" + DToS(Date()) + "'"
_cQuery += " AND SE1.E1_I_AVACC <> 'N'"

MPSysOpenQuery( _cQuery , cAlias)

DBSelectArea(cAlias)
(cAlias)->( DBGoTop() )
If (cAlias)->(!Eof()) .And. (cAlias)->VALUSO > 0
	nValatr := (cAlias)->VALUSO
	nqtdatr := (cAlias)->TOTUSO
EndIf

(cAlias)->( DBCloseArea() )

oproc:cCaption :=  "Carregando dados titulos nao marcados..."

//-- Verifica o saldo atual MARCADO para não avaliar no crédito--//
_cQuery := " SELECT "
_cQuery += "     SUM( SE1.E1_SALDO + SE1.E1_SDACRES - SE1.E1_SDDECRE ) AS VALUSO, count(*) as totuso "
_cQuery += " FROM "+ RetSqlName("SE1") +" SE1 "
_cQuery += "   LEFT JOIN "+ RetSqlName("ZAR") +" ZAR ON ZAR.ZAR_FILIAL = SE1.E1_FILIAL AND ZAR.ZAR_COD = SE1.E1_I_CART AND ZAR.D_E_L_E_T_	= ' ' "
_cQuery += " WHERE "
_cQuery += "     (SE1.E1_CLIENTE	= '"+ SZW->ZW_CLIENTE +"'  OR SE1.E1_I_CLIEN	= '"+ SZW->ZW_CLIENTE +"' ) "
_cQuery += " AND SE1.D_E_L_E_T_	= ' ' "
_cQuery += " AND SE1.E1_TIPO		NOT IN ('RA','NCC') "
_cQuery += " AND SE1.E1_SALDO + SE1.E1_SDACRES - SE1.E1_SDDECRE > 0 "
_cQuery += " AND (SE1.E1_I_AVACC = 'N' OR ZAR.ZAR_AVACC  = 'N') " 

MPSysOpenQuery( _cQuery , cAlias)

DBSelectArea(cAlias)
(cAlias)->( DBGoTop() )
If (cAlias)->(!Eof()) .And. (cAlias)->VALUSO > 0
	nValmar := (cAlias)->VALUSO
	nqtdmar := (cAlias)->TOTUSO
EndIf

(cAlias)->( DBCloseArea() )

oproc:cCaption :=  "Carregando dados titulos NCC/RA..."

//-- Verifica o saldo atual MARCADO para não avaliar no crédito--//
_cQuery := " SELECT "
_cQuery += "     SUM( SE1.E1_SALDO + SE1.E1_SDACRES - SE1.E1_SDDECRE ) AS VALUSO "
_cQuery += " FROM "+ RetSqlName("SE1") +" SE1 "
_cQuery += "   LEFT JOIN "+ RetSqlName("ZAR") +" ZAR ON ZAR.ZAR_FILIAL = SE1.E1_FILIAL AND ZAR.ZAR_COD = SE1.E1_I_CART AND ZAR.D_E_L_E_T_	= ' ' "
_cQuery += " WHERE "
_cQuery += "     (SE1.E1_CLIENTE	= '"+ SZW->ZW_CLIENTE +"'  OR SE1.E1_I_CLIEN	= '"+ SZW->ZW_CLIENTE +"' ) "
_cQuery += " AND SE1.D_E_L_E_T_	= ' ' "
_cQuery += " AND SE1.E1_TIPO	 IN ('RA','NCC') "
_cQuery += " AND SE1.E1_SALDO + SE1.E1_SDACRES - SE1.E1_SDDECRE > 0 "
_cQuery += " AND SE1.E1_I_AVACC <> 'N'"
_cQuery += " AND (ZAR.ZAR_AVACC  <> 'N' OR ZAR.ZAR_AVACC  = ' ') "

MPSysOpenQuery( _cQuery , cAlias)

DBSelectArea(cAlias)
(cAlias)->( DBGoTop() )
If (cAlias)->(!Eof()) .And. (cAlias)->VALUSO > 0
	nValncc := (cAlias)->VALUSO
EndIf

(cAlias)->( DBCloseArea() )

oproc:cCaption :=  "Carregando dados pedidos portal em carteira..."

//-- Verifica o saldo de pedidos BLOQUEADOS em carteira do cliente bloqueados --//
_cQuery := " SELECT "
_cQuery += "     SUM( SZW.ZW_QTDVEN * SZW.ZW_PRCVEN ) AS VALPED "
_cQuery += " FROM "+ RetSqlName("SZW") +" SZW" 
_cQuery += " WHERE "
_cQuery += "     SZW.ZW_CLIENTE	= '"+ SZW->ZW_CLIENTE +"' " 
_cQuery += " AND SZW.D_E_L_E_T_	= ' ' "
_cQuery += " AND (SZW.ZW_STATUS = 'L' OR SZW.ZW_STATUS = 'D') "
_cQuery += " AND SZW.ZW_TIPO <> '10' "//Diferente de Bonificação
_cQuery += " AND SZW.ZW_NUMPED = ' ' "
_cQuery += " AND (SZW.ZW_BLQLCR = 'B' OR SZW.ZW_BLQLCR = 'R' OR SZW.ZW_BLQLCR = 'Z')"

MPSysOpenQuery( _cQuery , cAlias)

DBSelectArea(cAlias)
(cAlias)->( DBGoTop() )
If (cAlias)->(!Eof()) .And. (cAlias)->VALPED > 0
	_nValzwBL := (cAlias)->VALPED
EndIf

(cAlias)->( DBCloseArea() )

oproc:cCaption :=  "Carregando dados pedidos venda em carteira..."

//-- Verifica o saldo de pedidos bloqueados em carteira do cliente --//

If !Empty(AllTrim(SZW->ZW_CLIREM)) .And. _cEstado $ _cUFVerif
	_cQuery := " SELECT "
	_cQuery += "     SUM( ((SC6.C6_QTDVEN - SC6.C6_QTDENT)/SC6.C6_QTDVEN) * SC6.C6_VALOR ) AS VALPED "
	_cQuery += " FROM "+ RetSqlName("SC6") +" SC6 "
	_cQuery += " JOIN "+ RetSqlName("SC5") +" SC5 ON SC5.C5_FILIAL = SC6.C6_FILIAL AND SC5.C5_NUM = SC6.C6_NUM  AND SC5.D_E_L_E_T_	= ' ' "
	_cQuery += " JOIN "+ RetSqlName("SC5") +" SC5R ON SC5R.C5_FILIAL = SC6.C6_FILIAL AND SC5R.C5_I_PVREM = SC6.C6_NUM  AND SC5R.D_E_L_E_T_	= ' ' "
	_cQuery += " WHERE "
	_cQuery += "     SC5R.C5_CLIENTE	= '"+  SZW->ZW_CLIENTE  +"' " 
	_cQuery += " AND SC6.D_E_L_E_T_	= ' ' "
	_cQuery += " AND SC5.C5_TIPO = 'N' "
	_cQuery += " AND (SC5.C5_I_BLCRE = 'B' OR SC5.C5_I_BLCRE = 'R')"
	_cQuery += " AND SC6.C6_BLQ <> 'R' "
Else
	_cQuery := " SELECT "
	_cQuery += "     SUM( ((SC6.C6_QTDVEN - SC6.C6_QTDENT)/SC6.C6_QTDVEN) * SC6.C6_VALOR ) AS VALPED "
	_cQuery += " FROM "+ RetSqlName("SC6") +" SC6,  "+ RetSqlName("SC5") +" SC5"
	_cQuery += " WHERE "
	_cQuery += "     SC6.C6_CLI	= '"+ SZW->ZW_CLIENTE +"' " 
	_cQuery += " AND SC6.D_E_L_E_T_	= ' ' "
	_cQuery += " AND SC5.D_E_L_E_T_	= ' ' "
	_cQuery += " AND SC5.C5_FILIAL = SC6.C6_FILIAL "
	_cQuery += " AND SC5.C5_NUM = SC6.C6_NUM "
	_cQuery += " AND SC5.C5_TIPO = 'N' "
	_cQuery += " AND (SC5.C5_I_BLCRE = 'B' OR SC5.C5_I_BLCRE = 'R')"
	_cQuery += " AND SC6.C6_BLQ <> 'R' "
EndIf

MPSysOpenQuery( _cQuery , cAlias)

DBSelectArea(cAlias)
(cAlias)->( DBGoTop() )
If (cAlias)->(!Eof()) .And. (cAlias)->VALPED > 0
	_nValpedb := (cAlias)->VALPED
EndIf

(cAlias)->( DBCloseArea() )

oproc:cCaption :=  "Carregando titulo atual..."

//-- Verifica o saldo do pedido atual --//
_cQuery := " SELECT "
_cQuery += "     SUM( SZW.ZW_QTDVEN * SZW.ZW_PRCVEN ) AS VALPED "
_cQuery += " FROM "+ RetSqlName("SZW") +" SZW" 
_cQuery += " WHERE "
_cQuery += "     SZW.ZW_IDPED	= '"+ SZW->ZW_IDPED +"' " 
_cQuery += " AND SZW.D_E_L_E_T_	= ' ' "

If Select(cAlias) > 0
	(cAlias)->( DBCloseArea() )
EndIf

MPSysOpenQuery( _cQuery , cAlias)

(cAlias)->( DBGoTop() )
If (cAlias)->(!Eof()) .And. (cAlias)->VALPED > 0
	nvalatu := (cAlias)->VALPED
EndIf

(cAlias)->( DBCloseArea() )

aSaldos				:= Array(_ASALDOS)
aSaldos[_LIMCREDM]	:= nLimCred
aSaldos[_LIMCRED ]	:= nLimCred
aSaldos[_SALDUPM ]	:= nValUso //Variavel Public no ITLACXFUN.PRW
aSaldos[_SALDUP  ]	:= nValUso //Variavel Public no ITLACXFUN.PRW //*
aSaldos[_SALPEDLM]	:= _nValpedb
aSaldos[_SALPEDL ]	:= _nValped//Variavel Public no ITLACXFUN.PRW//*
aSaldos[_MCOMPRAM]	:= SA1->A1_MCOMPRA
aSaldos[_MCOMPRA ]	:= SA1->A1_MCOMPRA 
aSaldos[_SALDOLCM]	:= nLimCred-nValUso-_nValped-_nValzw//Variavel Public no ITLACXFUN.PRW
aSaldos[_SALDOLC ]	:= nLimCred-nValUso-_nValped-_nValzw//Variavel Public no ITLACXFUN.PRW
aSaldos[_MAIDUPLM]	:= SA1->A1_MAIDUPL
aSaldos[_MAIDUPL ]	:= SA1->A1_MAIDUPL
aSaldos[_PEDATUM ]	:= nValPed
aSaldos[_PEDATU  ]	:= nvalatu
aSaldos[_VALATRM ]	:= nValAtr
aSaldos[_VALATR  ]	:= nQTDAtr
aSaldos[_LCFINM  ]	:= nLcFin
aSaldos[_LCFIN   ]	:= nLCFin
aSaldos[_SALFINM ]	:= nSalFinM
aSaldos[_SALFIN  ]	:= nSalFin

aHeader := {"  ","   ","  "," ","  "}

//Limite de Credito / Vencto.Lim.Credito
aAdd( aCols , {	"Limite de Credito",TRansform(aSaldos[_LIMCRED],PesqPict("SA1","A1_LC",17,1))," ",	;
				"Vencto.Lim.Credito",Space(10)+DToC(SA1->A1_VENCLC) } )

// Saldo Titulos / Maior Duplicata		
aAdd( aCols , {	"Saldo Titulos",TRansform(aSaldos[_SALDUP],PesqPict("SA1","A1_SALDUP",17,1))," ",	;
				"Maior Duplicata",Transform(aSaldos[_MAIDUPLM],PesqPict("SA1","A1_MAIDUPL",17,nMCusto)) } )

// Valor Tit atrasado / Qtde Tit Atrasado		
aAdd( aCols , {	"Valor Tit Atr",TRansform(aSaldos[_VALATRM],PesqPict("SA1","A1_SALDUP",17,1))," ",	;
				"Qtde Tit Atr",Transform(aSaldos[_VALATR],PesqPict("SA1","A1_MAIDUPL",17,nMCusto)) } )				

				
// Pedidos Portal / Pedidos Portal bloqueados		
aAdd( aCols , {	"Pedidos Portal",TRansform(_nValzw,PesqPict("SA1","A1_SALDUP",17,1))," ",	;//Variavel Public no ITLACXFUN.PRW
				"Ped Portal Bloq",Transform(_nValzwBL,PesqPict("SA1","A1_MAIDUPL",17,nMCusto)) } )				

// Pedidos Aprovados / Pedidos bloqueados
aAdd( aCols , {	"Pedidos Aprovados",TRansform(aSaldos[_SALPEDL],PesqPict("SA1","A1_SALPEDL",17,1))," ",;
				"Pedidos Bloqueados",TRansform(aSaldos[_SALPEDLM],PesqPict("SA1","A1_SALPEDL",17,1)) } )

// Saldo Lim Credito / Total marcado para não avaliar
aAdd( aCols , {	"Saldo Lim Credito",TRansform(aSaldos[_SALDOLC],PesqPict("SA1","A1_SALDUP",17,1))," ",	;
				" "," "} )

// Pedido Atual / Media de Atraso	
aAdd( aCols , {	"Pedido Atual",TRansform(aSaldos[_PEDATU],PesqPict("SA1","A1_SALDUP",17,1))," ", ;
					"Media de Atraso",Space(14)+Transform(SA1->A1_METR,PesqPict("SA1","A1_METR",7))+Space(04)+"" } )

// Saldo de Pedidos / Maior Compra
//aAdd( aCols , {	"Saldo não Faturado",TRansform(aSaldos[_SALPEDL]+aSaldos[_SALPEDLM],PesqPict("SA1","A1_SALPED",17,1))," ",	;
aAdd( aCols , {	"Saldo não Faturado",TRansform(aSaldos[_SALPEDL]+_nValzw,PesqPict("SA1","A1_SALPED",17,1))," ",	;
				 "Maior Compra",Transform(aSaldos[_MCOMPRAM],PesqPict("SA1","A1_MCOMPRA",17,nMCusto))} )

// Total NCC/RA / Total NDC/PA
aAdd( aCols , {	"Total NCC/RA",TRansform(nValncc,PesqPict("SA1","A1_SALPED",17,1))," ",	;
				  "Total sem aval",TRansform(nValmar,PesqPict("SA1","A1_SALPED",17,1))} )

//=======================================================================
// Determina a posição do opção para exibição da posição de clientes.
// De acordo com a versão do Protheus P11 ou P12.
//=======================================================================
_nOpcFin := 2

oproc:cCaption := "Carregando dados para interface..."

DEFINE MSDIALOG oDlg FROM 125,003 To 520,608 TITLE "Liberação de Crédito" PIXEL

@ 002, 004  To 054, 299 LABEL "Dados do Pedido"		OF oDlg PIXEL COLOR CLR_HBLUE 
@ 160, 004  To 195, 133 LABEL "Consultas"			OF oDlg PIXEL COLOR CLR_HBLUE
@ 160, 140  To 195, 270 LABEL "Avaliação"			OF oDlg PIXEL COLOR CLR_HBLUE

//-- Botoes de Consulta Auxiliar --//
@ 169,009 BUTTON "Pedidos"		SIZE 040,011 FONT oDlg:oFont ACTION ( AOMS064VY()	, cCadastro:=cTitAux )   										OF oDlg PIXEL
@ 169,050 BUTTON "Cliente"		SIZE 040,011 FONT oDlg:oFont ACTION ( _npos:=SA1->(RecNo()),cCadastro:="Clientes",A030Altera("SA1",SA1->(RecNo()),4),(_lLoopAltCleinte:=.T.,nOpca:=0,oDlg:End()))	OF oDlg PIXEL
@ 169,091 BUTTON "Pos. Cliente"	SIZE 040,011 FONT oDlg:oFont ACTION ( If(Pergunte("FIC010",.T.),FINC010(_nOpcFin),),cCadastro:=cTitAux )   							OF oDlg PIXEL
@ 182,009 BUTTON "Tit Abertos "	SIZE 040,011 FONT oDlg:oFont ACTION ( If(Pergunte("FIC010",.T.),U_AOMS064L()     ,),cCadastro:=cTitAux )   				  						OF oDlg PIXEL
@ 182,050 BUTTON "Av Credito "	SIZE 040,011 FONT oDlg:oFont ACTION (  U_AOMS064W() )   				  						OF oDlg PIXEL

//-- Verifica se o Pedido Atual ja foi avaliado anteriormente --//
lAvaAux := AOMS064VOK( SZW->ZW_IDPED , SZW->ZW_FILIAL )

//-- Botoes de Acao da Rotina --//
oButtonA := TButton():New( 169 , 145 , "Aprovar"	, oDlg , {|| (nOpca := 1,oDlg:End()) } , 40 , 10 ,,,.F.,.T.,.F.,,.F.,{|| lAvaAux},,.F. )
oButtonA := TButton():New( 169 , 186 , "Apr Comp"	, oDlg , {|| (nOpca := 3,oDlg:End()) } , 40 , 10 ,,,.F.,.T.,.F.,,.F.,{|| lAvaAux},,.F. )
oButtonR := TButton():New( 169 , 227 , "Rejeitar"	, oDlg , {|| (nOpca := 2,oDlg:End()) } , 40 , 10 ,,,.F.,.T.,.F.,,.F.,{|| lAvaAux},,.F. )
oButtonR := TButton():New( 183 , 227 , "Env E-Mail"	, oDlg , {|| (nOpca := 4,oDlg:End()) } , 40 , 10 ,,,.F.,.T.,.F.,,.F.,{|| lAvaAux},,.F. ) 

//-- Fechar --//
@ 169,272 BUTTON "Fechar"	SIZE 030,011 PIXEL OF oDlg ACTION (nOpca := 0, oDlg:End())

@ 010	, 008 Say "Pedido :"				SIZE 023,007 OF oDlg PIXEL
@ 010	, 032 Say AllTrim(SZW->ZW_IDPED)	SIZE 030,007 OF oDlg PIXEL
@ 010	, 065 Say "Cond.Pagto. :"			SIZE 035,007 OF oDlg PIXEL
@ 010	, 100 Say SZW->ZW_CONDPAG + " - " + Posicione("SE4",1,"  "+SZW->ZW_CONDPAG,"E4_DESCRI")			SIZE 070,007 OF oDlg PIXEL
@ 010	, 165 Say "Risco :"					SIZE 021,007 OF oDlg PIXEL
@ 010	, 188 Say SA1->A1_RISCO				SIZE 011,007 OF oDlg PIXEL
@ 010	, 230 Say "Status :"				SIZE 027,007 OF oDlg PIXEL
@ 010	, 260 Say cDescBloq					SIZE 083,007 OF oDlg PIXEL

If !Empty(SZW->ZW_FILPRO) .And. SZW->ZW_FILPRO != SZW->ZW_FILIAL

	@ 021	, 008 Say "Pedido Troca Nota para faturar na filial " + SZW->ZW_FILIAL OF oDlg PIXEL

Else

	@ 021	, 008 Say "Pedido venda direta"		 OF oDlg PIXEL
	
EndIf

@ 032	, 008 Say "Cliente :"				SIZE 023,007 OF oDlg PIXEL
@ 032	, 032 Say AllTrim(SA1->A1_NOME)		SIZE 096,007 OF oDlg PIXEL
@ 021, 188 Say "Data entrega :"			SIZE 064,007 OF oDlg PIXEL
@ 017	, 230 MSGET SZW->ZW_FECENT			SIZE 052,007 OF oDlg PIXEL	HASBUTTON
@ 032	, 188 Say "Data Bloqueio :"			SIZE 064,007 OF oDlg PIXEL
@ 031	, 230 MSGET SZW->ZW_DTAVAC			SIZE 052,007 OF oDlg PIXEL	HASBUTTON

@ 043	, 008 Say "Obs. Avaliação :"		SIZE 083,007 OF oDlg PIXEL
@ 043	, 050 Say AllTrim(SZW->ZW_OBSAVAC)	SIZE 150,007 OF oDlg PIXEL

oLbx := RDListBox( 3.98 , 0.5 , 290 , 103 , aCols , aHeader , {55,50,50,55,50} )

ACTIVATE MSDIALOG oDlg

FWRestArea(aArea)

If nOpca == 1 .Or. nOpca == 2 .Or. nOpca == 3
	
	nOpcCnf := 0 //Variavel para tratar o [X] da janela como "Cancelar"
	If nOpca == 3
       _nLinDlg:=180
	Else
       _nLinDlg:=140
	EndIf
	
	dLimite := Date() + 7
	cObsAva := Space(200)

	DEFINE MSDIALOG oDlg TITLE "Confirmar Avaliação: "+IIf(nOpca == 1,"Liberar",IIf(nOpca == 3, "Liberar Completo","Rejeitar"));
					 FROM 000,000 To _nLinDlg,600 OF oDlg PIXEL
		
		@ 004,004 To 026,296 LABEL "Motivo: (Obrigatório)" OF oDlg PIXEL
		@ 011,008 MSGET cObsAva PICTURE "@x"	SIZE 220,010 PIXEL OF oDlg
		
		If nOpca == 3
		
			@ 034,004 To 056,296 LABEL "Validade da liberação completa: " OF oDlg PIXEL
			@ 041,008 MSGET dLimite 	SIZE 220,010 PIXEL OF oDlg
            nLin:=60
		Else
            nLin:=30
		EndIf

    nPula:=10
		
		@nLin,008 Say "Cliente: "+ AllTrim(SA1->A1_NOME) OF oDlg PIXEL
		nLin+=nPula
		@nLin,008 Say "Valor: "+ AllTrim( Transform(nValPed,"@E 999,999,999,999.99") ) OF oDlg PIXEL
		nLin+=nPula
		@nLin,008 Say "Data Pedido: "+ DToC(SZW->ZW_EMISSAO) OF oDlg PIXEL
		
		@ 040,230 BUTTON "&Ok"		 SIZE 030,014 PIXEL ACTION ( IIf( Empty(cObsAva) , U_ITMsg("Obrigatório informar o motivo.","Atenção") , ( nOpcCnf:=nOpca , oDlg:End() ) ) )
		@ 040,261 BUTTON "&Cancelar" SIZE 030,014 PIXEL ACTION ( nOpcCnf:=0 , oDlg:End() )
	
	ACTIVATE MSDIALOG oDlg CENTER
	
	FWMsgRun(,{|| AOMS064LW(nopccnf)}, "Aguarde...", "Atualizando pedido...")  //Faz liberação do pedido do portal

EndIf

//=========================================================================
// Faz o envio de e-mail   
//=========================================================================
If nOpca == 4  
   //Envia email de liberação
   _cEmail := Posicione("SA3",1,xFilial("SA3")+SZW->ZW_VEND1,"A3_EMAIL") //Email do representante responsável pelo pedido
   _cCC := " "
   cMailcom := " " 
   _cAssunto := "Aviso de rejeição de crédito do pedido " + AllTrim(SZW->ZW_IDPED) 
   _cAssunto += " do cliente " + SZW->ZW_CLIENTE + "/" + SZW->ZW_LOJACLI + " - " + Posicione("SA1",1,xFilial("SA1")+SZW->ZW_CLIENTE+SZW->ZW_LOJACLI,"A1_NREDUZ")
			
   If AOMS064D(,_cEmail,_cCC,_cAssunto,,cMailcom)
      TMP64->(RecLock("TMP64",.F.))
	  TMP64->ENVMAIL := "S"
	  TMP64->(MSUnLock())

	  SZW->(RecLock("SZW",.F.))
	  SZW->ZW_ENVMAIL := "S"
	  SZW->(MSUnLock())
	  U_ITMsg("Envio de e E-mail concluído.","Atenção!",,2)
   EndIf

EndIf

Return(nOpca)

/*
===============================================================================================================================
Programa----------: AOMS064VT2
Autor-------------: Alexandre Villar
Data da Criacao---: 17/02/2014
Descrição---------: Recupera valor total do pedido de vendas.
Parametros--------: cNumPed =  Numero do pedido de vendas.
                    cFilAux =  Código da filial
                    cCodCli =  Codigo do cliente
                    nOpc = numero da operação: 3=Inclusão;4=Alteração; 5=Exclusão.
Retorno-----------: nValUso := valor em aberto do cliente.  
===============================================================================================================================
*/
Static Function AOMS064VT2( cNumPed , cFilAux , cCodCli , nOpc )

Local aArea		:= FWGetArea()
Local cAlias	:= GetNextAlias()
Local cQuery	:= ""
Local nValPed	:= 0
Local _ntolporc := SuperGetMV("IT_TOLPC",.F.,10) //Percentual Tolerância para Produto PA do Tipo Queijo.

Default cNumPed	:= ""
Default cFilAux	:= ""
Default cCodCli	:= ""
Default nOpc	:= 0                                   

//-- Verifica o valor total do pedido --//
cQuery := " SELECT "
cQuery += " SC6.C6_PRODUTO, SB1.B1_I_QQUEI, (SC6.C6_QTDVEN * SC6.C6_PRCVEN ) AS VALPED
cQuery += " FROM "+ RetSqlName("SC6") +" SC6, " + RetSqlName("SB1") +" SB1 "
cQuery += " WHERE "
cQuery += "     SC6.C6_NUM	= '"+ cNumPed +"' "
cQuery += " AND	SC6.C6_FILIAL	= '"+ cFilAux +"' "
cQuery += " AND SC6.D_E_L_E_T_	= ' ' "  
cQuery += " AND SB1.B1_FILIAL = ' ' "
cQuery += " AND SB1.B1_COD = SC6.C6_PRODUTO " 
cQuery += " AND SB1.D_E_L_E_T_	= ' ' "


If Select(cAlias) > 0
	(cAlias)->( DBCloseArea() )
EndIf

DBUseArea( .T. , "TOPCONN" , TcGenQry(,,cQuery) , cAlias , .T. , .F. )

DBSelectArea(cAlias)
(cAlias)->( DBGoTop() )            
While (cAlias)->(!Eof())  
	
	If nOpc == 3 
		If (cAlias)->( B1_I_QQUEI = "S" )
			nValPed +=  (  (cAlias)->VALPED + (( (cAlias)->VALPED * _ntolporc) / 100 ) )  
		Else
			nValPed +=  (cAlias)->VALPED			
		EndIf 
	Else
		nValPed +=  (cAlias)->VALPED		
	EndIf
	
	(cAlias)->( DBSkip())
EndDo

(cAlias)->( DBCloseArea() )

FWRestArea(aArea)

Return(nValPed)

/*
===============================================================================================================================
Programa----------: AOMS064VTP
Autor-------------: Alexandre Villar
Data da Criacao---: 17/02/2014
Descrição---------: Recupera valor total do pedido.
Parametros--------: cCodCli := codigo do cliente. 
                  : nOpc    := 1 - 
Retorno-----------: nValUso := valor em aberto do cliente.
===============================================================================================================================
*/
Static Function AOMS064VTP( cNumPed , cFilAux , cCodCli , nOpc )

Local aArea		:= FWGetArea()
Local cAlias	:= GetNextAlias()
Local cQuery	:= ""
Local nValPed	:= 0    
Local _ntolporc := SuperGetMV("IT_TOLPC",.F.,10) //Percentual Tolerância para Produto PA do Tipo Queijo.

Default cNumPed	:= ""
Default cFilAux	:= ""
Default cCodCli	:= ""
Default nOpc	:= 0

//-- Verifica o valor total do pedido --//

cQuery := "SELECT "
cQuery += " SZW.ZW_PRODUTO, SB1.B1_I_QQUEI, (SZW.ZW_QTDVEN * SZW.ZW_PRCVEN ) AS VALPED
cQuery += " FROM "+ RetSqlName("SZW") +" SZW, " + RetSqlName("SB1") +" SB1 "
cQuery += " WHERE "

If nOpc == 2

	cQuery += "		SZW.ZW_CLIENTE	= '"+ _cCodCli +"' "
	cQuery += " AND	SZW.ZW_STATUS   = 'L'
	cQuery += " AND	SZW.ZW_BLQLCR   = 'L'

Else

	cQuery += "     SZW.ZW_IDPED	= '"+ cNumPed +"' "
	cQuery += " AND	SZW.ZW_FILIAL	= '"+ cFilAux +"' "

EndIf

cQuery += " AND SZW.D_E_L_E_T_	= ' ' "
cQuery += " AND SB1.B1_FILIAL = ' ' "
cQuery += " AND SB1.B1_COD = SZW.ZW_PRODUTO " 
cQuery += " AND SB1.D_E_L_E_T_	= ' ' "

If Select(cAlias) > 0
	(cAlias)->( DBCloseArea() )
EndIf

DBUseArea( .T. , "TOPCONN" , TcGenQry(,,cQuery) , cAlias , .T. , .F. )

DBSelectArea(cAlias)
(cAlias)->( DBGoTop() )
While (cAlias)->(!Eof())
	If nOpc == 3
		If (cAlias)->( B1_I_QQUEI = "S" )
			nValPed +=  (  (cAlias)->VALPED + (( (cAlias)->VALPED * _ntolporc) / 100 ) )  
		Else
			nValPed +=  (cAlias)->VALPED
		EndIf
	Else
		nValPed +=  (cAlias)->VALPED			
	EndIf 
	(cAlias)->( DBSkip())
EndDo

(cAlias)->( DBCloseArea() )

FWRestArea(aArea)

Return(nValPed)

/*
===============================================================================================================================
Programa----------: AOMS064VOK
Autor-------------: Alexandre Villar
Data da Criacao---: 17/02/2014
Descrição---------: Tudo Ok da tela de avaliacao de pedidos do Portal.
Parametros--------: cNumPed = Numero do Pedido de Vendas 
                    cFilAux = código da Filial
Retorno-----------: lRet := identifica se a operacao pode ser concluida.
===============================================================================================================================
*/
Static Function AOMS064VOK( cNumPed , cFilAux )

Local cAlias	:= GetNextAlias()
Local lRet		:= .F. //Se retornar falso o pedido ja foi avaliado anteriormente
Local cQuery	:= ""

Default cNumPed	:= ""
Default cFilAux	:= ""

//-- Verifica se o pedido ja foi avaliado anteriormente --//
cQuery := " SELECT "
cQuery += "     COUNT(SZW.ZW_ITEM) AS IT_PEND "
cQuery += " FROM "+ RetSqlName("SZW") +" SZW "
cQuery += " WHERE "
cQuery += "    	SZW.ZW_IDPED	= '"+ cNumPed +"' "
cQuery += " AND	SZW.ZW_FILIAL	= '"+ cFilAux +"' "
cQuery += " AND	SZW.ZW_BLQLCR   IN ('B','R','Z')
cQuery += " AND SZW.D_E_L_E_T_	= ' ' "

If Select(cAlias) > 0
	(cAlias)->( DBCloseArea() )
EndIf

DBUseArea( .T. , "TOPCONN" , TcGenQry(,,cQuery) , cAlias , .T. , .F. )

DBSelectArea(cAlias)
(cAlias)->( DBGoTop() )
If (cAlias)->(!Eof()) .And. (cAlias)->IT_PEND > 0
	lRet := .T.
EndIf

(cAlias)->( DBCloseArea() )

Return(lRet)

/*
===============================================================================================================================
Programa----------: AOMS064O
Autor-------------: Erich Buttner
Data da Criacao---: 18/03/2013
Descrição---------: Funcao que avalia os Pedido de Venda para classifica-lo corretamente na legenda.
Parametros--------: Nenhum 
Retorno-----------: _cRet = Codigo referente a classificação para a legenda.
===============================================================================================================================
*/
Static Function AOMS064O()

Local _cRet := ""
Local _aArea  := FWGetArea()

Begin Sequence
   If TMP64->( Eof() )
      Break	
   EndIf
   
   If TMP64->ENVMAIL == "S" 
	  _cRet := "4"
   ElseIf TMP64->BLCRE == 'B'
	  _cRet := "1"
   ElseIf TMP64->BLCRE == 'L'
	  _cRet := ""
   ElseIf TMP64->BLCRE== 'R'
	  _cRet := "2"
   ElseIf TMP64->BLCRE== 'Z'
	  _cRet := "3"
   EndIf

End Sequence

FWRestArea(_aArea)

Return(_cRet)

/*
===============================================================================================================================
Programa----------: AOMS064TT
Autor-------------: Erich Buttner
Data da Criacao---: 18/03/2013
Descrição---------: Função utilizada para mostrar as configurações de tela do usuário.
Parametros--------: Nenhum 
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS064TT()

Public aSize           := {}
Public aObjects        := {}
Public aInfo           := {}
Public aPosObj		   := {}

// Obtém a a área de trabalho e tamanho da dialog
aSize := MsAdvSize()

aAdd( aObjects, { 000, 000, .T., .T. } ) // Dados da Enchoice
aAdd( aObjects, { 000, 000, .T., .T. } ) // Dados da getdados

// Dados da área de trabalho e separação
aInfo 	:= { aSize[ 1 ], aSize[ 2 ], aSize[ 3 ], aSize[ 4 ], 3, 3 } // Chama MsObjSize e recebe array e tamanhos

aPosObj := MsObjSize( aInfo, aObjects,.T.)

Return aPosObj

/*
===============================================================================================================================
Programa----------: AOMS064FO
Autor-------------: Erich Buttner
Data da Criacao---: 18/03/2013
Descrição---------: Funcao executada na saida do campo Ordem, para ordenar o browse.
Parametros--------: cORDEM = Ordenação do Browser "PEDIDO" / "CLIENTE".
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS064FO(cOrdem)

_nReg:=Recno()
cPesquisa:=Space(200)
oPesquisa:Refresh()

_aMarcados:={}

DBSelectArea("TMP64")
TMP64->(DBGoTop())

If CORDEM == 'PEDIDO'
	While TMP64->(!Eof())
		aAdd(_aMarcados,{TMP64->NUMPED,TMP64->OK})
		TMP64->(DBSkip())
	EndDo
ElseIf CORDEM == 'CLIENTE'
	While TMP64->(!Eof())
		aAdd(_aMarcados,{TMP64->CODCLI,TMP64->OK})
		TMP64->(DBSkip())
	EndDo
EndIf

DBSelectArea("TMP64")
TMP64->( DBSetOrder(aScan(aOrdem,cOrdem)) )
TMP64->( DBGoTo(_nReg) )    //Mantendo no mesmo registro que estava posicionado anteriormente
oMark:oBrowse:Refresh(.T.)

Return

/*
===============================================================================================================================
Programa----------: AOMS064P
Autor-------------: Erich Buttner
Data da Criacao---: 18/03/2013
Descrição---------: Pesquisa Informações no Browse de acordo com a Ordem selecionada.
Parametros--------: cOrdem = Ordem de pesquisa.
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS064P(cOrdem)

DBSelectArea("TMP64")
TMP64->( DBSetOrder(aScan(aOrdem,cOrdem)) )
TMP64->( DBGoTop() )
TMP64->( Msseek(AllTrim(cPesquisa),.T.) )
oMark:oBrowse:Refresh(.T.)

Return

/*
===============================================================================================================================
Programa----------: AOMS064C
Autor-------------: Erich Buttner
Data da Criacao---: 18/03/2013
Descrição---------: Função utilizada no botão de legenda mostrar o significado de cada cor.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS064C()

Local cCadastro:=OemToAnsi("Pedido")

BrwLegenda(cCadastro,"Legenda",{	{"BR_VERMELHO","Pedido Com Credito Bloqueado"},;
									{"BR_CINZA","Pedido Com Rejeição Credito"},;
									{"BR_AMARELO","Pedido Com Cliente Bloqueado"}})

Return(.T.)

/*
===============================================================================================================================
Programa----------: AOMS0649
Autor-------------: Erich Buttner
Data da Criacao---: 18/03/2013
Descrição---------: Função que chama autorização ou bloqueio do pedido.
Parametros--------: cpedido - Numero do pedido
                    _cfilial - Codigo da filial
                    oproc - objeto da barra de procesamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS0649(cpedido As Char,_cfilial As Char, oproc As Object)

Local aArea			:= FWGetArea() As Array
Local nValPed		:= 0 As Numeric
Local nLimCred		:= 0 As Numeric
Local nMoeda		:= 0 As Numeric
Local nSalPedL		:= 0 As Numeric
Local nSalPed		:= 0 As Numeric
Local nSalDup		:= 0 As Numeric
Local nOpca			:= 0 As Numeric
Local nOpcCnf		:= 0 As Numeric
Local cDescBloq		:= "" As Char
Local cDescri		:= "" As Char
Local cTitAux		:= "Liberação de Crédito" As Char
Local oDlg			:= Nil As Object
Local nMCusto		:= 0 As Numeric
Local nDecs			:= 0 As Numeric
Local aSaldos		:= {} As Array
Local lAvaAux		:= .T. As Logic
Local nSalFin		:= 0 As Numeric
Local nSalFinM		:= 0 As Numeric
Local nLcFin		:= 0 As Numeric
Local aCols			:={} As Array
Local aHeader		:={} As Array
Local cMoeda		:= "" As Char
Local cAlias	:= GetNextAlias() As Char
Local _nValzwBL := 0 As Numeric
Local _nValpedb := 0 As Numeric
Local nvalatr	:= 0 As Numeric
Local nQTDAtr	:= 0 As Numeric
Local nvalmar	:= 0 As Numeric
Local nQTDmar	:= 0 As Numeric
Local nValncc	:= 0 As Numeric
Local _aSC5     := {} As Array
Local cMatUsr	:= FWSFAllUsers({__cUserID},{"USR_FILIAL"})[1][3]+FWSFAllUsers({__cUserID},{"USR_CODFUNC"})[1][3] As Char
Local cAutoriz	:= GetAdvFVal( "ZZL" , "ZZL_LIBCRE" , xFilial("ZZL") + cMatUsr , 1 , "N" ) As Char
Local _nOpcFin  := 0 As Numeric
Local _cUFVerIf := SuperGetMv("MV_AOMS64E",.F.,"RJ") As Char
Local _cCodCli	  := "" As Char
Local _cLojaCli	  := "" As Char

Private cCadastro 	:= "Análise de Crédito de Clientes" As Char
Private aRotAuto  	:= Nil As Array
Private inclui 		:= .F. As Logic
Private altera		:= .T. As Logic

//-- Controle de acesso por usuario conforme parametrizacao no Gerenciador (Gestao de Usuarios) --//
If !( cAutoriz == "S" )
	U_ITMsg("Usuário sem acesso à rotina de avaliação dos Pedidos bloqueados para análise de Crédito.","Atenção!",,1)
	Return
EndIf

//-- Posiciona no pedido
SC5->( DBSetOrder(1) )
SC5->( DBSeek( _cfilial + cpedido ) ) 

oproc:cCaption := "Carregando dados..."

//-- Posiciona no Cliente e Verifica o Estado--//
DBSelectArea("SA1")
SA1->( DBSetOrder(1) )
SA1->( DBSeek( xFilial("SA1") + SC5->C5_CLIENTE + SC5->C5_LOJACLI ) )
cEstado := SA1->A1_EST

If !Empty(SC5->C5_I_PVREM) .And. cEstado $ _cUFVerif
	_aSC5 := GetArea("SC5")

	SC5->( DBSetOrder(1) )
	SC5->( DBSeek( _cfilial + SC5->C5_I_PVREM ) ) 
	_cCodCli := SC5->C5_CLIENTE
	_cLojaCli := SC5->C5_LOJACLI
	
	FWRestArea(_aSC5)
Else
	_cCodCli := SC5->C5_CLIENTE
	_cLojaCli := SC5->C5_LOJACLI
EndIf


//-- Posiciona no Cliente --//
DBSelectArea("SA1")
SA1->( DBSetOrder(1) )
SA1->( DBSeek( xFilial("SA1") + _cCodCli + _cLojaCli ) )

nMCusto := IIf( SA1->A1_MOEDALC > 0 , SA1->A1_MOEDALC , Val( SuperGetMv("MV_MCUSTO") ) )
cMoeda	:= " "+ Pad( SuperGetMv( "MV_SIMB" + AllTrim(Str(nMCusto))) , 4 )
nDecs	:= MsDecimais( nMcusto )

oproc:cCaption := "Carregando dados cliente..."

//-- Soma-se Todos os Limites de Credito do Cliente --//
DBSelectArea("SA1")
SA1->( DBSetOrder(1) )
SA1->( DBSeek( xFilial("SA1") + _cCodCli ) )


While SA1->(!Eof()) .And. SA1->A1_COD == _cCodCli
		
	nSalPed 	+= SA1->A1_SALPED + SA1->A1_SALPEDB	
	nSalPedL	+= SA1->A1_SALPEDL					
	nLcFin		+= SA1->A1_LCFIN					                 
	nSalFinM	+= SA1->A1_SALFINM					
	nSalDup		+= SA1->A1_SALDUP
	nSalFin		+= SA1->A1_SALFIN
	nLimCred	+= SA1->A1_LC
		
	SA1->( DBSkip() )
EndDo

oproc:cCaption := "Carregando dados limites de crédito..."

u_VeriSal( _cCodCli , _cLojaCli , 1 )

//-- Reposiciona no Cliente --//
DBSelectArea("SA1")
SA1->( DBSetOrder(1) )
SA1->( DBSeek( xFilial("SA1") + _cCodCli + _cLojaCli ) )

nMoeda		:= 1
nValPed		:= AOMS064VT2( SC5->C5_NUM , SC5->C5_FILIAL ,, 1 )
cDescBloq	:= IIf(SC5->C5_I_BLCRE = 'B',"Bloqueado",IIf(SC5->C5_I_BLCRE = 'R', "Rejeitado", ""))
cDescri		:= SubStr(SA1->A1_NOME,1,35)


oproc:cCaption := "Carregando dados titulos em atraso..."

//-- Verifica o saldo atual em atraso do Cliente --//
_cQuery := " SELECT "
_cQuery += "     SUM( SE1.E1_SALDO + SE1.E1_SDACRES - SE1.E1_SDDECRE ) AS VALUSO, count(*) as totuso "
_cQuery += " FROM "+ RetSqlName("SE1") +" SE1 "
_cQuery += " WHERE "
_cQuery += "     (SE1.E1_CLIENTE	= '"+ _cCodCli +"'  OR SE1.E1_I_CLIEN	= '"+ _cCodCli +"' ) " 
_cQuery += " AND SE1.D_E_L_E_T_	= ' ' "
_cQuery += " AND SE1.E1_TIPO		NOT IN ('RA','NCC') "
_cQuery += " AND SE1.E1_SALDO + SE1.E1_SDACRES - SE1.E1_SDDECRE > 0 "
_cQuery += " AND SE1.E1_I_AVACC <> 'N'"

MPSysOpenQuery( _cQuery , cAlias)

(cAlias)->( DBGoTop() )
If (cAlias)->(!Eof()) .And. (cAlias)->VALUSO > 0
	nValatr := (cAlias)->VALUSO
	nqtdatr := (cAlias)->TOTUSO
EndIf

(cAlias)->( DBCloseArea() )

oproc:cCaption := "Carregando dados titulos nao marcados..."

//-- Verifica o saldo atual MARCADO para não avaliar no crédito--//
_cQuery := " SELECT "
_cQuery += "     SUM( SE1.E1_SALDO + SE1.E1_SDACRES - SE1.E1_SDDECRE ) AS VALUSO, count(*) as totuso "
_cQuery += " FROM "+ RetSqlName("SE1") +" SE1 "
_cQuery += " WHERE "
_cQuery += "     (SE1.E1_CLIENTE	= '"+ _cCodCli +"'  OR SE1.E1_I_CLIEN	= '"+ _cCodCli +"' ) "
_cQuery += " AND SE1.D_E_L_E_T_	= ' ' "
_cQuery += " AND SE1.E1_TIPO		NOT IN ('RA','NCC') "
_cQuery += " AND SE1.E1_SALDO + SE1.E1_SDACRES - SE1.E1_SDDECRE > 0 "
_cQuery += " AND SE1.E1_VENCREA < '" + DToS(Date()) + "'"
_cQuery += " AND SE1.E1_I_AVACC = 'N'"

MPSysOpenQuery( _cQuery , cAlias)

(cAlias)->( DBGoTop() )
If (cAlias)->(!Eof()) .And. (cAlias)->VALUSO > 0
	nValmar := (cAlias)->VALUSO
	nqtdmar := (cAlias)->TOTUSO
EndIf

(cAlias)->( DBCloseArea() )

oproc:cCaption := "Carregando dados titulos NCC/RA..."

//-- Verifica o saldo atual MARCADO para não avaliar no crédito--//
_cQuery := " SELECT "
_cQuery += "     SUM( SE1.E1_SALDO + SE1.E1_SDACRES - SE1.E1_SDDECRE ) AS VALUSO "
_cQuery += " FROM "+ RetSqlName("SE1") +" SE1 "
_cQuery += " WHERE "
_cQuery += "     (SE1.E1_CLIENTE	= '"+ _cCodCli +"'  OR SE1.E1_I_CLIEN	= '"+ _cCodCli +"' ) "
_cQuery += " AND SE1.D_E_L_E_T_	= ' ' "
_cQuery += " AND SE1.E1_TIPO	 IN ('RA','NCC') "
_cQuery += " AND SE1.E1_SALDO + SE1.E1_SDACRES - SE1.E1_SDDECRE > 0 "
_cQuery += " AND SE1.E1_I_AVACC <> 'N'"

MPSysOpenQuery( _cQuery , cAlias)

(cAlias)->( DBGoTop() )
If (cAlias)->(!Eof()) .And. (cAlias)->VALUSO > 0
	nValncc := (cAlias)->VALUSO
EndIf

(cAlias)->( DBCloseArea() )


oproc:cCaption := "Carregando dados pedidos portal em carteira..."

//-- Verifica o saldo de pedidos em carteira do cliente bloqueados --//
_cQuery := " SELECT "
_cQuery += "     SUM( SZW.ZW_QTDVEN * SZW.ZW_PRCVEN ) AS VALPED "
_cQuery += " FROM "+ RetSqlName("SZW") +" SZW" 
_cQuery += " WHERE "
_cQuery += "     SZW.ZW_CLIENTE	= '"+ _cCodCli +"' " 
_cQuery += " AND SZW.D_E_L_E_T_	= ' ' "
_cQuery += " AND (SZW.ZW_STATUS = 'L' OR SZW.ZW_STATUS = 'D') "
_cQuery += " AND SZW.ZW_NUMPED = ' ' "
_cQuery += " AND SZW.ZW_TIPO <> '10' "//AWF-07/02/17 - Diferente de Bonificação
_cQuery += " AND (SZW.ZW_BLQLCR = 'B' OR SZW.ZW_BLQLCR = 'R')"

MPSysOpenQuery( _cQuery , cAlias)

(cAlias)->( DBGoTop() )
If (cAlias)->(!Eof()) .And. (cAlias)->VALPED > 0
	_nValzwBL := (cAlias)->VALPED
EndIf

(cAlias)->( DBCloseArea() )

oproc:cCaption := "Carregando dados pedidos venda em carteira..."

//-- Verifica o saldo de pedidos BLOQUEADOS do cliente--//
If !Empty(SC5->C5_I_PVREM) .And. cEstado $ _cUFVerif
	_cQuery := " SELECT "
	_cQuery += "     SUM( ((SC6.C6_QTDVEN - SC6.C6_QTDENT)/SC6.C6_QTDVEN) * SC6.C6_VALOR ) AS VALPED "
	_cQuery += " FROM "+ RetSqlName("SC6") +" SC6 "
	_cQuery += " JOIN "+ RetSqlName("SC5") +" SC5 ON SC5.C5_FILIAL = SC6.C6_FILIAL AND SC5.C5_NUM = SC6.C6_NUM  AND SC5.D_E_L_E_T_	= ' ' "
	_cQuery += " JOIN "+ RetSqlName("SC5") +" SC5R ON SC5R.C5_FILIAL = SC6.C6_FILIAL AND SC5R.C5_I_PVREM = SC6.C6_NUM  AND SC5R.D_E_L_E_T_	= ' ' "
	_cQuery += " WHERE "
	_cQuery += "     SC5R.C5_CLIENTE	= '"+ _cCodCli +"' " 
	_cQuery += " AND SC6.D_E_L_E_T_	= ' ' "
	_cQuery += " AND SC5.C5_TIPO = 'N' "
	_cQuery += " AND (SC5.C5_I_BLCRE = 'B' OR SC5.C5_I_BLCRE = 'R')"
	_cQuery += " AND SC6.C6_BLQ <> 'R' "
Else
	_cQuery := " SELECT "
	_cQuery += "     SUM( ((SC6.C6_QTDVEN - SC6.C6_QTDENT)/SC6.C6_QTDVEN) * SC6.C6_VALOR ) AS VALPED "
	_cQuery += " FROM "+ RetSqlName("SC6") +" SC6,  "+ RetSqlName("SC5") +" SC5"
	_cQuery += " WHERE "
	_cQuery += "     SC6.C6_CLI	= '"+ _cCodCli +"' " 
	_cQuery += " AND SC6.D_E_L_E_T_	= ' ' "
	_cQuery += " AND SC5.D_E_L_E_T_	= ' ' "
	_cQuery += " AND SC5.C5_FILIAL = SC6.C6_FILIAL "
	_cQuery += " AND SC5.C5_NUM = SC6.C6_NUM "
	_cQuery += " AND SC5.C5_TIPO = 'N' "
	_cQuery += " AND (SC5.C5_I_BLCRE = 'B' OR SC5.C5_I_BLCRE = 'R')"
	_cQuery += " AND SC6.C6_BLQ <> 'R' "
EndIf

MPSysOpenQuery( _cQuery , cAlias)

(cAlias)->( DBGoTop() )
If (cAlias)->(!Eof()) .And. (cAlias)->VALPED > 0
	_nValpedb := (cAlias)->VALPED
EndIf

(cAlias)->( DBCloseArea() )

_nOpcFin := 2

aSaldos				:= Array(_ASALDOS)
aSaldos[_LIMCREDM]	:= nLimCred
aSaldos[_LIMCRED ]	:= nLimCred
aSaldos[_SALDUPM ]	:= nValUso //Variavel Public no ITLACXFUN.PRW
aSaldos[_SALDUP  ]	:= nValUso //Variavel Public no ITLACXFUN.PRW
aSaldos[_SALPEDLM]	:= _nValpedb
aSaldos[_SALPEDL ]	:= _nValped//Variavel Public no ITLACXFUN.PRW
aSaldos[_MCOMPRAM]	:= SA1->A1_MCOMPRA
aSaldos[_MCOMPRA ]	:= SA1->A1_MCOMPRA 
aSaldos[_SALDOLCM]	:= nLimCred-nValUso-_nValped-_nValzw//Variavel Public no ITLACXFUN.PRW
aSaldos[_SALDOLC ]	:= nLimCred-nValUso-_nValped-_nValzw//Variavel Public no ITLACXFUN.PRW
aSaldos[_MAIDUPLM]	:= SA1->A1_MAIDUPL
aSaldos[_MAIDUPL ]	:= SA1->A1_MAIDUPL
aSaldos[_PEDATUM ]	:= nValPed
aSaldos[_PEDATU  ]	:= nValPed
aSaldos[_VALATRM ]	:= nValAtr
aSaldos[_VALATR  ]	:= nQTDAtr
aSaldos[_LCFINM  ]	:= nLcFin
aSaldos[_LCFIN   ]	:= nLCFin
aSaldos[_SALFINM ]	:= nSalFinM
aSaldos[_SALFIN  ]	:= nSalFin

aHeader := {"  ","   ","  "," ","  "}

//Limite de Credito / Vencto.Lim.Credito
aAdd( aCols , {	"Limite de Credito",TRansform(aSaldos[_LIMCRED],PesqPict("SA1","A1_LC",17,1))," ",	;
				"Vencto.Lim.Credito",Space(10)+DToC(SA1->A1_VENCLC) } )

// Saldo Titulos / Maior Duplicata		
aAdd( aCols , {	"Saldo Titulos",TRansform(aSaldos[_SALDUP],PesqPict("SA1","A1_SALDUP",17,1))," ",	;
				"Maior Duplicata",Transform(aSaldos[_MAIDUPLM],PesqPict("SA1","A1_MAIDUPL",17,nMCusto)) } )

// Valor Tit atrasado / Qtde Tit Atrasado		
aAdd( aCols , {	"Valor Tit Atr",TRansform(aSaldos[_VALATRM],PesqPict("SA1","A1_SALDUP",17,1))," ",	;
				"Qtde Tit Atr",Transform(aSaldos[_VALATR],PesqPict("SA1","A1_MAIDUPL",17,nMCusto)) } )				

				
// Pedidos Portal / Pedidos Portal bloqueados		
aAdd( aCols , {	"Pedidos Portal",TRansform(_nValzw,PesqPict("SA1","A1_SALDUP",17,1))," ",	;//Variavel Public no ITLACXFUN.PRW
				"Ped Portal Bloq",Transform(_nValzwBL,PesqPict("SA1","A1_MAIDUPL",17,nMCusto)) } )				

// Pedidos Aprovados / Pedidos bloqueados
aAdd( aCols , {	"Pedidos Aprovados",TRansform(aSaldos[_SALPEDL],PesqPict("SA1","A1_SALPEDL",17,1))," ",;
				"Pedidos Bloqueados",TRansform(aSaldos[_SALPEDLM],PesqPict("SA1","A1_SALPEDL",17,1)) } )

// Saldo Lim Credito / Total marcado para não avaliar
aAdd( aCols , {	"Saldo Lim Credito",TRansform(aSaldos[_SALDOLC],PesqPict("SA1","A1_SALDUP",17,1))," ",	;
				" "," "} )

// Pedido Atual / Media de Atraso	
aAdd( aCols , {	"Pedido Atual",TRansform(aSaldos[_PEDATU],PesqPict("SA1","A1_SALDUP",17,1))," ", ;
					"Media de Atraso",Space(14)+Transform(SA1->A1_METR,PesqPict("SA1","A1_METR",7))+Space(04)+"" } )

// Saldo de Pedidos / Maior Compra
aAdd( aCols , {	"Saldo não Faturado",TRansform(aSaldos[_SALPEDL]+_nValzw,PesqPict("SA1","A1_SALPED",17,1))," ",	;
				 "Maior Compra",Transform(aSaldos[_MCOMPRAM],PesqPict("SA1","A1_MCOMPRA",17,nMCusto))} )

// Total NCC/RA / Total NDC/PA
aAdd( aCols , {	"Total NCC/RA",TRansform(nValncc,PesqPict("SA1","A1_SALPED",17,1))," ",	;
				  "Total sem aval",TRansform(nValmar,PesqPict("SA1","A1_SALPED",17,1))} )


oproc:cCaption := "Carregando dados para interface..."

DEFINE MSDIALOG oDlg FROM 125,003 To 520,689 TITLE "Liberação de Crédito" PIXEL

@ 002, 004  To 054, 340 LABEL "Dados do Pedido"		OF oDlg PIXEL COLOR CLR_HBLUE
@ 160, 004  To 195, 174 LABEL "Consultas"			OF oDlg PIXEL COLOR CLR_HBLUE
@ 160, 181  To 195, 311 LABEL "Avaliação"			OF oDlg PIXEL COLOR CLR_HBLUE

//-- Botoes de Consulta Auxiliar --//  
@ 169,009 BUTTON "Pedidos"		SIZE 040,011 FONT oDlg:oFont ACTION ( AOMS064VY()  	, cCadastro:=cTitAux )   										OF oDlg PIXEL
@ 169,050 BUTTON "Cliente"		SIZE 040,011 FONT oDlg:oFont ACTION ( _npos:=SA1->(RecNo()),cCadastro:="Clientes",A030Altera("SA1",SA1->(RecNo()),4),(_lLoopAltCleinte:=.T.,nOpca:=0,oDlg:End()))	OF oDlg PIXEL
@ 169,091 BUTTON "Pos. Cliente"	SIZE 040,011 FONT oDlg:oFont ACTION ( If(Pergunte("FIC010",.T.),FINC010(_nOpcFin),),cCadastro:=cTitAux )   										OF oDlg PIXEL
@ 182,009 BUTTON "Tit Abertos "	SIZE 040,011 FONT oDlg:oFont ACTION ( If(Pergunte("FIC010",.T.),U_AOMS064L()     ,),cCadastro:=cTitAux )   				  						OF oDlg PIXEL
@ 182,050 BUTTON "Av Credito  "	SIZE 040,011 FONT oDlg:oFont ACTION ( U_AOMS064Q() )   				  						OF oDlg PIXEL


//-- Verifica se o Pedido Atual ja foi avaliado anteriormente --//
lAvaAux := AOMS064VOK( SZW->ZW_IDPED , SZW->ZW_FILIAL )

//-- Botoes de Acao da Rotina --//
oButtonA := TButton():New( 169 , 186 , "Aprovar"	, oDlg , {|| (nOpca := 1,oDlg:End()) } , 40 , 10 ,,,.F.,.T.,.F.,,.F.,{|| .T.},,.F. )
oButtonA := TButton():New( 169 , 227 , "Apr Comp"	, oDlg , {|| (nOpca := 3,oDlg:End()) } , 40 , 10 ,,,.F.,.T.,.F.,,.F.,{|| .T.},,.F. )
oButtonR := TButton():New( 169 , 268 , "Rejeitar"	, oDlg , {|| (nOpca := 2,oDlg:End()) } , 40 , 10 ,,,.F.,.T.,.F.,,.F.,{|| .T.},,.F. )
oButtonR := TButton():New( 183 , 268 , "Env E-Mail"	, oDlg , {|| (nOpca := 4,oDlg:End()) } , 40 , 10 ,,,.F.,.T.,.F.,,.F.,{|| .T.},,.F. )

//-- Fechar --//
@ 169,313 BUTTON "Fechar"	SIZE 030,011 PIXEL OF oDlg ACTION (nOpca := 0, oDlg:End())

@ 010	, 008 Say "Pedido :"				SIZE 023,007 OF oDlg PIXEL
@ 010	, 032 Say AllTrim(SC5->C5_NUM)	SIZE 026,007 OF oDlg PIXEL
@ 010	, 060 Say "Cond.Pagto. :"			SIZE 035,007 OF oDlg PIXEL
@ 010	, 095 Say SC5->C5_CONDPAG + " - " + Posicione("SE4",1,"  "+SC5->C5_CONDPAG,"E4_DESCRI")			SIZE 070,007 OF oDlg PIXEL
@ 010	, 165 Say "Risco :"					SIZE 021,007 OF oDlg PIXEL
@ 010	, 188 Say SA1->A1_RISCO				SIZE 011,007 OF oDlg PIXEL
@ 010	, 230 Say "Status :"				SIZE 027,007 OF oDlg PIXEL
@ 010	, 260 Say cDescBloq					SIZE 083,007 OF oDlg PIXEL

If SC5->C5_I_TRCNF == "S"

	If SC5->C5_FILIAL == SC5->C5_I_FILFT 

		@ 021, 008 Say "Pedido de Faturamento Troca Nota, Ped Carregamento: " + SC5->C5_I_FLFNC + "/ " + SC5->C5_I_PDPR OF oDlg PIXEL
	
	Else
	
		@ 021, 008 Say "Pedido de Troca Nota, Filial de Faturamento: " + SC5->C5_I_FILFT  OF oDlg PIXEL
		
	EndIf

Else

	@ 021	, 008 Say "Pedido venda direta"		 OF oDlg PIXEL
	
EndIf

@ 032	, 008 Say "Cliente :"				SIZE 023,007 OF oDlg PIXEL
@ 032	, 032 Say AllTrim(SA1->A1_NOME)		SIZE 096,007 OF oDlg PIXEL
@ 032	, 188 Say "Data Bloqueio :"			SIZE 064,007 OF oDlg PIXEL
@ 031.4	, 230 MSGET SC5->C5_I_DTAVA			SIZE 052,007 OF oDlg PIXEL	HASBUTTON

@ 021	, 188 Say "Data Entrega :"			SIZE 064,007 OF oDlg PIXEL
@ 019.4	, 230 MSGET SC5->C5_I_DTENT			SIZE 052,007 OF oDlg PIXEL	HASBUTTON
@ 043	, 008 Say "Obs. Avaliação :"		SIZE 083,007 OF oDlg PIXEL
@ 043	, 050 Say SC5->C5_I_MOTBL			SIZE 150,007 OF oDlg PIXEL

oLbx := RDListBox( 3.98 , 0.5 , 331 , 103 , aCols , aHeader , {55,50,50,55,50} )

ACTIVATE MSDIALOG oDlg

FWRestArea(aArea)

If nOpca == 1 .Or. nOpca == 2 .Or. nOpca == 3
	
	nOpcCnf := 0 //Variavel para tratar o [X] da janela como "Cancelar"
	If nOpca == 3
       _nLinDlg:=180
	Else
       _nLinDlg:=140
	EndIf

	
	dLimite := Date() + 7
	cObsAva := Space(200)
	
	DEFINE MSDIALOG oDlg TITLE "Confirmar Avaliação: "+IIf(nOpca == 1,"Liberar",IIf(nOpca == 3, "Liberar Completo","Rejeitar"));
					 FROM 000,000 To _nLinDlg,600 OF oDlg PIXEL
		
		@ 004,004 To 026,296 LABEL "Motivo: (Obrigatório)" OF oDlg PIXEL
		@ 011,008 MSGET cObsAva PICTURE "@x"	SIZE 220,010 PIXEL OF oDlg
		
		If nOpca == 3
		
			@ 034,004 To 056,296 LABEL "Validade da liberação completa: " OF oDlg PIXEL
			@ 041,008 MSGET dLimite 	SIZE 220,010 PIXEL OF oDlg VALID dLimite >= Date()
            nLin:=60
		Else
            nLin:=30
		EndIf
                                                       
    nPula:=10
		
		@nLin,008 Say "Cliente: "+ AllTrim(SA1->A1_NOME) OF oDlg PIXEL
		nLin+=nPula
		@nLin,008 Say "Valor: "+ AllTrim( Transform(nValPed,"@E 999,999,999,999.99") ) OF oDlg PIXEL
		nLin+=nPula
		@nLin,008 Say "Data Pedido: "+ DToC(SC5->C5_EMISSAO) OF oDlg PIXEL
		
		@ 040,230 BUTTON "&Ok"					SIZE 030,014 PIXEL ACTION ( IIf( Empty(cObsAva) , U_ITMsg("Obrigatório informar o motivo.","Atenção",,1) , ( nOpcCnf:=nOpca , oDlg:End() ) ) )
		@ 040,261 BUTTON "&Cancelar"			SIZE 030,014 PIXEL ACTION ( nOpcCnf:=0 , oDlg:End() )
	
	ACTIVATE MSDIALOG oDlg CENTER
	
	FWMsgRun(,{|| AOMS064L5(nopccnf)}, "Aguarde...", "Atualizando pedido...") //Faz liberação do pedido de vendas do protheus

EndIf

//=========================================================================
// Faz o envio de e-mail   
//=========================================================================
If nOpca == 4  
   //Envia email de liberação
   _cEmail := Posicione("SA3",1,xFilial("SA3")+SC5->C5_VEND1,"A3_EMAIL") //Email do representante responsável pelo pedido
   _cCC := Space(250)
   cMailcom := " " 
   _cAssunto := "Aviso de rejeição de crédito do pedido " + AllTrim(SC5->C5_NUM) 
   _cAssunto += " do cliente " + SC5->C5_CLIENTE + "/" + SC5->C5_LOJACLI + " - " + Posicione("SA1",1,xFilial("SA1")+SC5->C5_CLIENTE + SC5->C5_LOJACLI,"A1_NREDUZ")
			
   If AOMS064D(,_cEmail,_cCC,_cAssunto,,cMailcom)
      TMP64->(RecLock("TMP64",.F.))
	  TMP64->ENVMAIL := "S"
	  TMP64->(MSUnLock())

	  SC5->(RecLock("SC5",.F.))
	  SC5->C5_I_ENVML := "S"
	  SC5->(MSUnLock())
	  U_ITMsg("Envio de e E-mail concluído.","Atenção!",,2)
   EndIf

EndIf

cChama := "1" //Volta sem fechar o browse

Return

/*
===============================================================================================================================
Programa----------: AOMS0648
Autor-------------: Erich Buttner
Data da Criacao---: 18/03/2013
Descrição---------: Funcao que fecha a rotina
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS0648(oDLg)

oDlg:End()
cChama := "5"

Return

/*
===============================================================================================================================
Programa----------: AOMS064PP
Autor-------------: Josué Danich Prestes
Data da Criacao---: 08/04/2016
Descrição---------: Monta dados para tela de pedidos do protheus.
Parametros--------: oproc - objeto da barra de procesamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS064PP(oproc)

Local cQuery := "" As Char
Local cAliasTRB := GetNextAlias() As Char //Alias de trabalho para a query
//==========================================
// Monta Query 
//==========================================
If _nSelOrigem == 1
	
	cQuery := " SELECT 	C5_FILIAL FILIAL,"
	cQuery += " 			C5_CLIENTE CODCLI,"
	cQuery += " 			C5_LOJACLI LOJA,"
	cQuery += " 			C5_I_NOME NOME,"
	cQuery += " 			C5_EMISSAO EMISSAO,"
	cQuery += " 			C5_I_DTENT ENTREGA,"
	cQuery += " 			C5_I_DTAVA DTAVA,"
	cQuery += " 			C5_I_HRAVA HRAVA,"
	cQuery += " 			C5_I_USRAV USRAVA,"
	cQuery += " 			C5_I_OPER OPER,"
	cQuery += " 			C5_NUM NUMPED,"
	cquery += "          (SELECT SUM(C6_VALOR) FROM " + RETSQLNAME("SC6") + " SC6 "
	cquery += "          			WHERE D_E_L_E_T_ = ' ' AND SC6.C6_FILIAL = SC5.C5_FILIAL AND SC6.C6_NUM = SC5.C5_NUM) VALOR,"
	cQuery += " 			C5_I_MOTBL MOTBL,"
	cQuery += " 			C5_I_BLCRE BLCRE,"
	cQuery += " 			C5_I_ENVML ENVMAIL"
	cQuery += " FROM " + RETSQLNAME("SC5") +  " SC5 "
	
	cQuery += " WHERE " 
   
   If _nmvpar02 == 1
      cQuery += "C5_I_BLCRE = 'R' AND C5_CONDPAG <> '001'"
   ElseIf _nmvpar02 == 2
      cQuery += "C5_I_BLCRE = 'B' AND C5_CONDPAG <> '001' "
   ElseIf _nmvpar02 == 4
      cQuery += "C5_CONDPAG = '001' AND (C5_I_BLCRE = 'R' OR C5_I_BLCRE = 'B') "
   Else
      cQuery += "(C5_I_BLCRE = 'R' OR C5_I_BLCRE = 'B') "
	EndIf

	cQuery += " 			AND D_E_L_E_T_ = ' '
	
	cQuery += " ORDER BY C5_FILIAL,C5_NUM
	
Else
	
	If _nmvpar02 = 1 //Rejeitados
	
		_cFiltro := "ZW_BLQLCR = 'R'  AND ZW_CONDPAG <> '001'  " 
		
	ElseIf _nmvpar02 = 2 //Bloqueados
	
		_cFiltro := "(ZW_BLQLCR = 'B' OR ZW_BLQLCR = 'Z') AND ZW_CONDPAG <> '001' "

	ElseIf _nmvpar02 = 4 //A vista
	
		_cFiltro := "ZW_CONDPAG = '001' AND (ZW_BLQLCR = 'B' OR ZW_BLQLCR = 'Z') "

	Else//Todos
	
		_cFiltro := "(ZW_BLQLCR = 'B' OR ZW_BLQLCR = 'R' OR ZW_BLQLCR = 'Z') "
		
	EndIf
	
	cQuery := " SELECT 	ZW_FILIAL FILIAL,"
	cQuery += " 		ZW_CLIENTE CODCLI,"
	cQuery += " 		ZW_LOJACLI LOJA,"
	cQuery += " 		ZW_EMISSAO EMISSAO,"
	cQuery += " 		ZW_FECENT ENTREGA,"
	cQuery += " 		ZW_DTAVAC DTAVA,"
	cQuery += " 		ZW_HRAVAC HRAVA,"
	cQuery += " 		ZW_USRAVAC USRAVA,"
	cQuery += " 		ZW_IDPED NUMPED,"
	cQuery += " 		ZW_I_MOTBL MOTBL,"
	cQuery += " 		ZW_BLQLCR BLCRE,"
	cQuery += " 		ZW_TIPO OPER,"
	cQuery += " 		R_E_C_N_O_ RECSZW,"
	cQuery += " 		ZW_ENVMAIL ENVMAIL"  
	
	cQuery += " FROM " + RETSQLNAME("SZW") +  " SZW "
	cQuery += " WHERE " + _cFiltro
		
	cQuery += " AND D_E_L_E_T_ = ' ' "
	cQuery += " AND ZW_ITEM = '1' "
	cQuery += " AND SZW.ZW_STATUS IN ('L','D','E') "
	cQuery += " ORDER BY ZW_FILIAL,ZW_IDPED "
		
EndIf

cQuery := ChangeQuery(cQuery)

If Select(cAliasTRB) >0
	DBSelectArea(cAliasTRB)
	(cAliasTRB)->( DBCloseArea() )
EndIf

If Select("TMP64") >0
	DBSelectArea("TMP64")
	TMP64->( DBCloseArea() )
EndIf

//==========================================
// Monta Area de Trabalho executando a Query 
//==========================================
MPSysOpenQuery( cQuery,cAliasTRB )
DBSelectArea(cAliasTRB)

(cAliasTRB)->( DBGoTop() )

//==========================================
// Monta arquivo temporario 
//==========================================

_aCpoTMP64:={}
aAdd(_aCpoTMP64,{"OK"			,"C",001,0})
aAdd(_aCpoTMP64,{"OK2"			,"C",002,0})
aAdd(_aCpoTMP64,{"FILIAL"		,"C",020,0})
If _nSelOrigem == 1
   aAdd(_aCpoTMP64,{"NUMPED"	,"C",006,0})
Else
   aAdd(_aCpoTMP64,{"NUMPED"	,"C",Len(SZW->ZW_IDPED),0})
EndIf
aAdd(_aCpoTMP64,{"CODCLI"		,"C",020,0})
aAdd(_aCpoTMP64,{"NOME"			,"C",050,0})
aAdd(_aCpoTMP64,{"VALOR"		,"C",020,0})
aAdd(_aCpoTMP64,{"DATAPED"		,"C",010,0})
aAdd(_aCpoTMP64,{"DATAENT"		,"C",010,0})
aAdd(_aCpoTMP64,{"DTAVAL"	 	,"C",010,0})
aAdd(_aCpoTMP64,{"HRAVAL"      	,"C",010,0})
aAdd(_aCpoTMP64,{"BLCRE"      	,"C",001,0})
aAdd(_aCpoTMP64,{"MOTIVO"      	,"C",050,0})
aAdd(_aCpoTMP64,{"RECSZW"      	,"N",010,0})
aAdd(_aCpoTMP64,{"ORDEMDTE"    	,"N",010,0})
aAdd(_aCpoTMP64,{"ENVMAIL"    	,"C",001,0}) 
aAdd(_aCpoTMP64,{"OPER"    	    ,"C",003,0}) 

_oTemp:=FWTemporaryTable():New( "TMP64", _aCpoTMP64 )
_oTemp:AddIndex( "01", {"NUMPED"} )
_oTemp:AddIndex( "02", {"CODCLI"} )
_oTemp:AddIndex( "03", {"ORDEMDTE"} )
_oTemp:Create()

//==========================================
// Alimenta arquivo temporario 
//==========================================
DBSelectArea("TMP64")

While !(cAliasTRB)->(Eof())

	RecLock("TMP64",.T.)
	TMP64->OK			:= ""
	TMP64->OK2			:= "  "
	TMP64->FILIAL 	:= (cAliasTRB)->FILIAL + " - " + AllTrim(FWFilialName(cEmpAnt,(cAliasTRB)->FILIAL))
	TMP64->NUMPED 	:= (cAliasTRB)->NUMPED
	TMP64->CODCLI 	:= AllTrim((cAliasTRB)->CODCLI) + "/" + AllTrim((cAliasTRB)->LOJA)
	TMP64->OPER 	:= (cAliasTRB)->OPER
    If _nSelOrigem == 1
	   TMP64->NOME	:= (cAliasTRB)->NOME
	   TMP64->VALOR	:= Space(20 - Len(AllTrim(TRANSFORM((cAliasTRB)->VALOR,"@E 999,999,999.99")) ))  + AllTrim(TRANSFORM((cAliasTRB)->VALOR,"@E 999,999,999.99"))
	Else
	   TMP64->NOME	:= Posicione("SA1",1,xFilial("SA1")+(cAliasTRB)->CODCLI+(cAliasTRB)->LOJA,"A1_NOME")
	   nValor:=AOMS064VTP( TMP64->NUMPED , SubStr(TMP64->FILIAL,1,2) ,, 1 )
	   TMP64->VALOR	:= Space(20 - Len(AllTrim(TRANSFORM(nValor,"@E 999,999,999.99")) ))  + AllTrim(TRANSFORM(nValor,"@E 999,999,999.99"))
	   TMP64->RECSZW  := (cAliasTRB)->RECSZW
	EndIf
	TMP64->DATAPED	:= DToC(SToD((cAliasTRB)->EMISSAO))
	TMP64->ORDEMDTE := SToD((cAliasTRB)->EMISSAO) - CTOD("01/01/2000")//campo para indexar a data de emissao ao contrario
	TMP64->DATAENT	:= DToC(SToD((cAliasTRB)->ENTREGA))
	TMP64->DTAVAL		:= DToC(SToD((cAliasTRB)->DTAVA))
	TMP64->HRAVAL		:= (cAliasTRB)->HRAVA
	TMP64->BLCRE		:= (cAliasTRB)->BLCRE
	TMP64->MOTIVO		:= (cAliasTRB)->MOTBL 
    TMP64->ENVMAIL      := (cAliasTRB)->ENVMAIL 
		
	TMP64->(MSUnLock())
	DBSelectArea(cAliasTRB)
	(cAliasTRB)->( DBSkip() )
	
End

(cAliasTRB)->(DBCloseArea())

_aCores:={}
bped := {|| AOMS064O()} //Função que carrega váriavel com cores da legenda
aAdd(_aCores,{'Eval(bped)==""' ,"BR_VERDE"})
aAdd(_aCores,{'Eval(bped)=="1"',"BR_VERMELHO"})
aAdd(_aCores,{'Eval(bped)=="2"',"BR_CINZA"})
aAdd(_aCores,{'Eval(bped)=="3"',"BR_AMARELO"})
aAdd(_aCores,{'Eval(bped)=="4"',"BR_AZUL"})

//==========================================
// Array com definicoes dos campos do browse 
//==========================================

_aCpoBrw:={}
aAdd(_aCpoBrw,{"OK2"		,"" ," "			," "						      })
aAdd(_aCpoBrw,{"FILIAL"		,"" ,"Filial"			,"@!"						      })
aAdd(_aCpoBrw,{"NUMPED"    	,""	,"Pedido"     		,"@!"               		,"25" ,"0"})
aAdd(_aCpoBrw,{"OPER"    	,""	,"Operação"     	,"@!"               		,"03" ,"0"})
aAdd(_aCpoBrw,{"CODCLI"    	,""	,"Cliente/Loja"    	,"@!"               		,"01" ,"0"})
aAdd(_aCpoBrw,{"NOME"  		,""	,"Nome Cliente"   	,"@!"               		,"06" ,"0"})
aAdd(_aCpoBrw,{"VALOR"		,""	,"Valor Pedido"    	,"@!"	            		,"04" ,"0"})
aAdd(_aCpoBrw,{"MOTIVO"  	,""	,"Motivo Bloqueio"  ,"@!"               		,"20" ,"0"})
aAdd(_aCpoBrw,{"DATAPED"  	,""	,"Data Pedido"    	,"@!"               		,"01" ,"0"})
aAdd(_aCpoBrw,{"DATAENT"  	,""	,"Data Entrega"    	,"@!"               		,"01" ,"0"})
aAdd(_aCpoBrw,{"DTAVAL" 	,""	,"Dt Avaliacao"     ,"@!"						,"06" ,"0"})
aAdd(_aCpoBrw,{"HRAVAL" 	,""	,"Hr Avaliacao"     ,"@!"						,"06" ,"0"})
aAdd(_aCpoBrw,{"ORDEMDTE"	,""	,"Ordem 3"     ,"@E 999,999"						,"10" ,"0"})

Return

/*
===============================================================================================================================
Programa----------: AOMS64GA() 
Autor-------------: Alex Wallauer
Data da Criacao---: 09/09/2016
Descrição---------: Atualiza status da avaliação da análise de Crédito do Pedido.
Parametros--------: cNumPed := Código do Pedido
                    cFilAux := Filial do Pedido
                    cStsAva := Status da Avaliação do Pedido
                    cMotAva := Motivo da Avaliação do Pedido
Retorno-----------: lRet := Informa se a gravação da avaliação foi efetivada com sucesso ( .T. = Sim / .F. = Não )
===============================================================================================================================
*/
Static Function AOMS64GA( _cNumPed , _cFilAux , _cStsAva , _cMotAva , _nvalor, _cVend1 )

Local lRet		:= .T.
Local _aarea	:= FWGetArea()
Local _cCoord   := "" 
Local _cWF      := "" //Aprovador WF 1-Sim 2-Nao
Default _cNumPed	:= ""
Default _cFilAux	:= ""
Default _cStsAva	:= ""
Default _cMotAva	:= ""
Default _nvalor 	:= 0

If Empty(_cNumPed) .Or. Empty(_cFilAux) .Or. Empty(_cStsAva) .Or. Empty(_cMotAva)
	lRet := .F.
Else

	_cCoord:= Posicione("SA3",1,xFilial("SA3")+_cVend1,"A3_SUPER") 
	_cWF   := Posicione("SA3",1,xFilial("SA3")+_cCoord,"A3_I_WF") 

	SZW->( DBSetOrder(1) )
	If SZW->( DBSeek( _cFilAux + _cNumPed ) )
	
		While SZW->(!Eof()) .And. SZW->( ZW_FILIAL + ZW_IDPED ) == _cFilAux + _cNumPed

			SZW->( RecLock( "SZW" , .F. ) )
	
			SZW->ZW_BLQLCR	:= _cStsAva               // C5_I_BLCRE
			SZW->ZW_LIBL	:= dLimite                // C5_I_DTLIC
			SZW->ZW_LIBV	:= _nvalor                // C5_I_LIBCV
			SZW->ZW_I_LIBCD:= Date()                  // C5_I_LIBCD
			SZW->ZW_I_LIBCT:= Time()                  // C5_I_LIBCT
			SZW->ZW_I_LIBCA:= _cUsrFullName 	  	  // C5_I_LIBCA
			SZW->ZW_I_MOTBL:= cObsAva                // C5_I_MOTBL
			SZW->ZW_OBSAVAC:= cObsAva
 
			If _cStsAva == "R"       
	 	       SZW->ZW_STATUS := "R"   //SZW->ZW_STATUS := "E"    // JPP TESTE
				
			   SZW->ZW_MOTREP := SZW->ZW_I_MOTBL  // JPP TESTE - Gravação dos novos campos.
               SZW->ZW_MOTREC := SZW->ZW_I_MOTBL
               SZW->ZW_USRREC := FWSFAllUsers({__cUserID},{"USR_FILIAL"})[1][3]+FWSFAllUsers({__cUserID},{"USR_CODFUNC"})[1][3]
               SZW->ZW_DTREC  := Date()
               SZW->ZW_HRREC  := Time()
			Else
			   SZW->ZW_STATUS := "L"
			EndIf

			SZW->( MSUnLock() )
			SZW->( DBSkip() )
		EndDo

		//Se o cliente do pedido está bloqueado já faz o desbloqueio
		SA1->(DBSetOrder(1))
		SZW->( DBSetOrder(1) )
		
		If _cStsAva != "R" .And. _cStsAva != "B" .And. SZW->( DBSeek( _cFilAux + _cNumPed ) ) .And. SA1->(DBSeek(xFilial("SA1")+SZW->ZW_CLIENTE+SZW->ZW_LOJACLI))
		
			If SA1->A1_MSBLQL = '1'
				RecLock("SA1",.F.)
				SA1->A1_MSBLQL := '2'
				SA1->A1_I_ACRED := SA1->A1_I_ACRED +  CHR(13)+CHR(10) + "Desbloqueado via liberação de crédito do pedido " +  AllTrim(SZW->ZW_IDPED) + " em " + DToC(Date())
				SA1->A1_I_ACRED := SA1->A1_I_ACRED + " por " + cUserName
				SA1->(MSUnLock())
			EndIf          
			
			If !Empty(SZW->ZW_LIBL) .And. SZW->ZW_LIBL > SA1->A1_VENCLC 
				U_ITMsg("A Data de Liberação Completa esta Maior que a Data de Validade do Crédito, por favor validar.","Atenção! o Pedido Foi liberado !!!",,1)
			EndIf
		EndIf
	Else
		lRet := .F.
	EndIf

EndIf

FWRestArea(_aarea)

Return(lRet)

/*
===============================================================================================================================
Programa----------: AOMS64L
Autor-------------: Josué Danich Prestes
Data da Criacao---: 23/05/2018
Descrição---------: Prepara tela de títulos em aberto
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS064L()

Local aParam := {}
Private aSelFil	:= {}
Private aTmpFil	:= {}

MV_PAR01:=MV_PAR01
MV_PAR02:=MV_PAR02
MV_PAR03:=MV_PAR03
MV_PAR04:=MV_PAR04
MV_PAR05:=MV_PAR05
MV_PAR06:=MV_PAR06
MV_PAR07:=MV_PAR07
MV_PAR08:=MV_PAR08
MV_PAR09:=MV_PAR09
MV_PAR10:=MV_PAR10
MV_PAR11:=MV_PAR11
MV_PAR12:=MV_PAR12
MV_PAR13:=MV_PAR13
MV_PAR14:=MV_PAR14
MV_PAR15:=MV_PAR15
MV_PAR16:=MV_PAR16
MV_PAR17:=MV_PAR17

Pergunte("FIC010",.F.)

aAdd(aParam,MV_PAR01)
aAdd(aParam,MV_PAR02)
aAdd(aParam,MV_PAR03)
aAdd(aParam,MV_PAR04)
aAdd(aParam,MV_PAR05)
aAdd(aParam,MV_PAR06)
aAdd(aParam,MV_PAR07)
aAdd(aParam,MV_PAR08)
aAdd(aParam,MV_PAR09)
aAdd(aParam,MV_PAR10)
aAdd(aParam,MV_PAR11)
aAdd(aParam,MV_PAR12)
aAdd(aParam,MV_PAR13)
aAdd(aParam,MV_PAR14)
aAdd(aParam,MV_PAR15)
aAdd(aParam,MV_PAR16)
aAdd(aParam,MV_PAR17)

FWMsgRun(,{ || AOMS064B(1,,aParam) }, "Aguarde...", "Carregando títulos em aberto...")
	
Return

/*
===============================================================================================================================
Programa----------: AOMS64B
Autor-------------: Josué Danich Prestes
Data da Criacao---: 23/05/2018
Descrição---------: Carrega tela de títulos em aberto
Parametros--------: nbrowse - fixo em 1
					aAlias - alias de query pre executada ( não usado)
					aparam - parâmetros de query do financeiro
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS064B(nBrowse,aAlias,aParam)

Local aArea		:= FWGetArea()
Local aAreaSC5	:= SC5->(GetArea())
Local aAreaSC6	:= SC6->(GetArea())
Local aAreaSC9	:= SC9->(GetArea())
Local aAreaSF4	:= SF4->(GetArea())
Local aStru		:= {}
Local aQuery	:= {}
Local aSay		:= {"","","","","","","",""}
Local oGetDb
Local oScrPanel
Local oBold
Local oDlg
Local bVisual
Local bWhile
Local bFiltro
Local cAlias	:= ""
Local cArquivo	:= ""
Local cCadastro	:= ""
Local cQuery	:= ""
Local cQry		:= ""
Local cChave	:= ""
Local lQuery	:= .F.
Local nCntFor	:= 0
Local nTotAbat	:= 0
Local nTaxaM	:= 0	
Local aTotRec	:= {{0,1,0,0}} // Totalizador de titulos a receber por por moeda
Local naScan
Local nTotalRec	:=0
Local aSize		:= MsAdvSize( .F. )
Local aPosObj1	:= {}                 
Local aObjects	:= {}                       
Local nMulta		:= 0                              //Valor da Multa
Local cMVJurTipo 	:= SuperGetMv("MV_JURTIPO",,"")   //Tipo de Calculo de Juros do Financeiro	
Local lLojxRMul  	:= FindFunction("LojxRMul")       //Funcao que calcula a Multa do Financeiro
Local lMvLjIntFS    := SuperGetMv("MV_LJINTFS", ,.F.) //Habilita Integração com o Financial Services
Local nPosAlias	:= 0  ,C   , H

Default aalias := {}
Private aHeader	:= {}
Private lRelat	:= .F.

Private nCasas       := 2

aGet := {"","","","","","","",""}

cCadastro := "TITULOS EM ABERTO"
cAlias    := GetNextAlias()
aSay[1]   := "Qtd.Tit."
aSay[2]   := "Principal"
aSay[3]   := "Saldo a Receber"
aSay[4]   := "Juros"
aSay[5]   := "Acresc."
aSay[6]   := "Decresc."
aSay[7]   := "Abatimentos"
aSay[8]   := "Tot.Geral"
bVisual   := {|| Fc010Visua((cAlias)->XX_RECNO,nBrowse) }


aHeaderAux:={}
aCols:={}
_aCampos:={"E1_LOJA","E1_FILORIG","E1_PREFIXO","E1_NUM","E1_PARCELA","E1_TIPO","E1_CLIENTE","E1_EMISSAO","E1_VENCTO","E1_BAIXA","E1_VENCREA",;
           "E1_MOEDA","E1_VALOR","E1_VLCRUZ","E1_SDACRES","E1_SDDECRE","E1_VALJUR","E1_VLMULTA","E1_MULTA","E1_ACRESC","E1_JUROS",;
           "E1_SALDO","E1_NATUREZ","E1_PORTADO","E1_NUMBCO","E1_NUMLIQ","E1_HIST","E1_CHQDEV"}

//Carrega aheader
//          (nOpc,cAlias,nOrder,cSeekKey,bSeekWhile,uSeekFor,aNoFields,aYesFields,lOnlyYes,cQuery,bMontCols,lEmpty,aHeaderAux,aColsAux,bAfterCols,bBeforeCols,bAfterHeader,cAliasQry,bCriaVar,lUserFields,aYesUsado)
FillGetDados(2   ,"SE1" ,1     ,        ,          ,        ,         ,_aCampos  ,        ,      ,         ,.T.   ,aHeaderAux,        ,          ,           ,            ,         ,        ,           ,_aCampos)
	
//Limpa dois ultimos campos do aheader
ASIZE(aHeaderAux,Len(aHeaderAux)-2)

SX3->(DBSetOrder(2))

aHeader:={}

If !lRelat
	aAdd(aHeader,{"",	"XX_LEGEND","@BMP",10,0,"","","C","",""})
	aAdd(aStru,{"XX_LEGEND","C",12,0})
EndIf

For C := 1 To Len(_aCampos)  

    If (H:=aScan(aHeaderAux,{|H| AllTrim(H[2]) == _aCampos[C] } )) = 0
       Loop
    EndIf

    If !AllTrim(aHeaderAux[H,2]) $ "E1_VLMULTA,E1_MULTA,E1_ACRESC,E1_CHQDEV,E1_JUROS" 
       If (aParam[13] = 2 .Or. AllTrim(aHeaderAux[H,2]) <> "E1_LOJA") .And. AllTrim(aHeaderAux[H,2]) <> "E1_CLIENTE
           aAdd(aHeader,  aHeaderAux[H] )
       EndIf    
	   aAdd(aStru  , {aHeaderAux[H,2],aHeaderAux[H,8],aHeaderAux[H,4],aHeaderAux[H,5]})
    EndIf   

	aAdd(aQuery , {aHeaderAux[H,2],aHeaderAux[H,8],aHeaderAux[H,4],aHeaderAux[H,5]})

    If AllTrim(aHeaderAux[H,2]) == "E1_SALDO"

	   aHeader[Len(aHeader),1]:="Saldo a Receber"

       aAdd(aHeader,  aClone(aHeaderAux[H]) )
	   aHeader[Len(aHeader),1]:="Saldo na moeda tit"
	   aHeader[Len(aHeader),2]:="E1_SALDO2"

       aAdd(aStru ,{"E1_SALDO2",aHeaderAux[H,8],aHeaderAux[H,4],aHeaderAux[H,5]})

    ElseIf AllTrim(aHeaderAux[H,2]) == "E1_HIST"

		aAdd(aHeader,{"Atraso","E1_ATR","9999999999",10,0,"","","N","","V" } )
		aAdd(aStru ,{"E1_ATR","N",10,0})

    ElseIf AllTrim(aHeaderAux[H,2]) == "E1_VLCRUZ"
		aAdd(aHeader,{"Abatimentos","E1_ABT","@E 999,999,999.99",14,2,"","","N","","V" } ) //
		aAdd(aStru ,{"E1_ABT","N",14,2})
    EndIf
Next

	aAdd(aStru,{"TPDESCRI","C",25,0})
	aAdd(aStru,{"XX_RECNO","N",12,0})

	aAdd(aQuery,{"E1_PORCJUR","N",12,4})
	aAdd(aQuery,{"E1_I_AVACC","C",1,0})
	
	aAdd(aQuery,{"E1_TXMOEDA","N",17,4})
	aAdd(aHeader,{"Situacao","TPDESCRI","@!",25,0,"","","C","SX5","" } ) //
	
	SX3->(DBSetOrder(1))

	If ( Select(cAlias) ==	0 )

		_oTemp1:=FWTemporaryTable():New( cAlias, aStru )
		_oTemp1:AddIndex( "01", {"E1_FILORIG","E1_CLIENTE","E1_LOJA","E1_PREFIXO","E1_NUM","E1_PARCELA","E1_TIPO"} )
		_oTemp1:AddIndex( "02", {"E1_VENCREA"} )
		_oTemp1:Create()
		cArquivo:=_oTemp1:GetRealName()
		aAdd(aAlias,{ cAlias , cArquivo })

		lQuery := .T.
		cQuery := ""
		aEval(aQuery,{|x| cQuery += ","+AllTrim(x[1])})
		cQuery := "SELECT "+SubStr(cQuery,2)
		cQuery +=         ",SE1.R_E_C_N_O_ SE1RECNO"
		cQuery += ",SX5.X5_DESCRI TPDESCRI "								
		cQuery += "FROM "+RetSqlName("SE1")+" SE1,"
		cQuery +=         RetSqlName("SX5")+" SX5 "
		nPosAlias := AOMS064N(1,"SE1")
		cQuery += "WHERE SE1.E1_CLIENTE='"+SA1->A1_COD+"' AND "
		If aParam[13] == 1  //Considera loja
			cQuery +=       "SE1.E1_LOJA='"+SA1->A1_LOJA+"' AND "
		EndIf
		cQuery +=       "SE1.E1_EMISSAO>='"+DToS(aParam[1])+"' AND "
		cQuery +=       "SE1.E1_EMISSAO<='"+DToS(aParam[2])+"' AND "
		cQuery +=       "SE1.E1_VENCREA>='"+DToS(aParam[3])+"' AND "
		cQuery +=       "SE1.E1_VENCREA<='"+DToS(aParam[4])+"' AND "
		If ( aParam[5] == 2 )
			cQuery +=   "SE1.E1_TIPO<>'PR ' AND "
		EndIf					
		If ( aParam[15] == 2 )
			cQuery +=   "SE1.E1_TIPO<>'RA ' AND "	
		EndIf
		cQuery += "SE1.E1_PREFIXO>='"+aParam[6]+"' AND "
		cQuery += "SE1.E1_PREFIXO<='"+aParam[7]+"' AND " 
		cQuery += "SE1.E1_SALDO > 0 AND "

		If aParam[11] == 2 // Se nao considera titulos gerados pela liquidacao
			If aParam[09] == 1 
				cQuery += "SE1.E1_NUMLIQ ='"+Space(Len(SE1->E1_NUMLIQ))+"' AND "
			Else
				cQuery += "SE1.E1_TIPOLIQ='"+Space(Len(SE1->E1_TIPOLIQ))+"' AND "						
				cQuery += "SE1.E1_NUMLIQ ='"+Space(Len(SE1->E1_NUMLIQ))+"' AND "
			EndIf	
		Else
			If aParam[09] == 2
				cQuery += "SE1.E1_TIPOLIQ='"+Space(Len(SE1->E1_TIPOLIQ))+"' AND "						
			EndIf	
		EndIf


		cQuery +=		"SE1.D_E_L_E_T_ = ' ' AND "
		cQuery +=      "SX5.X5_FILIAL='"+xFilial("SX5")+"' AND "
		cQuery +=		"SX5.X5_TABELA='07' AND "
		cQuery +=		"SX5.X5_CHAVE=SE1.E1_SITUACA AND "
		cQuery +=		"SX5.D_E_L_E_T_ = ' ' "
		cQuery   += " ORDER BY  " + SqlOrder("E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+SE1RECNO")
		cQry   := cArquivo+"A"

		dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cQry,.T.,.T.)

		aEval(aQuery,{|x| If(x[2]!="C",TCSetField(cQry,x[1],x[2],x[3],x[4]),Nil)})

		DBSelectArea(cQry)

		bWhile := {|| !Eof() }
		bFiltro:= {|| .T. }

		While ( Eval(bWhile) )				

			If ( Eval(bFiltro) )

				DBSelectArea(cAlias)
				DBSetOrder(1)
				cChave := (cQry)->E1_FILORIG+(cQry)->(E1_CLIENTE)+(cQry)->(E1_LOJA) +;
								(cQry)->(E1_PREFIXO)+(cQry)->(E1_NUM)+;
								(cQry)->(E1_PARCELA)
				cChave += If((cQry)->(E1_TIPO)	$ MVABATIM, "",;
								(cQry)->(E1_TIPO))
				If ( !DBSeek(cChave) )
					RecLock(cAlias,.T.)						
				Else
					RecLock(cAlias,.F.)
				EndIf
				DBSetOrder(1)
				nTotAbat := 0
				
				nMulta := 0 
				If (cMVJurTipo == "L" .Or. lMvLjIntFS) .And. lLojxRMul .And. aParam[12] == 2
					nMulta := LojxRMul( , , ,(cQry)->E1_SALDO, (cQry)->E1_ACRESC, (cQry)->E1_VENCREA,  , , (cQry)->E1_MULTA, ,;
												(cQry)->E1_PREFIXO, (cQry)->E1_NUM, (cQry)->E1_PARCELA, (cQry)->E1_TIPO, (cQry)->E1_CLIENTE, (cQry)->E1_LOJA,  ) 
				EndIf
					
				For nCntFor := 1 To Len(aStru)
					Do Case
					
					Case ( AllTrim(aStru[nCntFor][1])=="TPDESCRI" )
					
						If !( (cQry)->(E1_TIPO)	$ MVABATIM )
							(cAlias)->TPDESCRI := (cQry)->TPDESCRI
						EndIf	
						
					Case ( AllTrim(aStru[nCntFor][1])=="E1_VALJUR" )
					Case ( AllTrim(aStru[nCntFor][1])=="E1_ABT" )
						If cPaisLoc == "BRA"
							nTaxaM := (cQry)->E1_TXMOEDA
						Else
							nTaxaM:=Round((cQry)->E1_VLCRUZ / (cQry)->E1_VALOR,4)  // Pegar a taxa da moeda usada qdo da inclusão do titulo
						EndIf
						If ( (cQry)->(E1_TIPO)	$ MVABATIM )
							(cAlias)->E1_ABT += (nTotAbat := xMoeda((cQry)->(E1_SALDO),(cQry)->(E1_MOEDA),1,(cQry)->(E1_EMISSAO),,nTaxaM))
						EndIf
					
					Case ( AllTrim(aStru[nCntFor][1])=="E1_SALDO" )
						If cPaisLoc == "BRA"
							nTaxaM := (cQry)->E1_TXMOEDA
						Else
							nTaxaM:=Round((cQry)->E1_VLCRUZ / (cQry)->E1_VALOR,4)  // Pegar a taxa da moeda usada qdo da inclusão do titulo
						EndIf	
						If ( (cQry)->(E1_TIPO)	$ MVABATIM )
							If aParam[12] == 2	 // MV_PAR12 = 2 : Considera juros e taxa de pernamencia na visualizacao de titulos em aberto.
								(cAlias)->E1_SALDO -= nTotAbat
							EndIf
						Else
							(cAlias)->E1_SALDO += xMoeda((cQry)->(E1_SALDO),(cQry)->(E1_MOEDA),1,dDataBase,,ntaxaM)
							If aParam[12] == 2   // MV_PAR12 = 2 : Considera juros e taxa de pernamencia na visualizacao de titulos em aberto.
								(cAlias)->E1_SALDO += xMoeda((cQry)->(E1_SDACRES) - (cQry)->(E1_SDDECRE),(cQry)->(E1_MOEDA),1,dDataBase,,ntaxaM)
								(cAlias)->E1_SALDO += xMoeda(FaJuros((cQry)->E1_VALOR,(cQry)->E1_SALDO,(cQry)->E1_VENCTO,(cQry)->E1_VALJUR,(cQry)->E1_PORCJUR,(cQry)->E1_MOEDA,(cQry)->E1_EMISSAO,,If(cPaisLoc=="BRA",(cQry)->E1_TXMOEDA,0),(cQry)->E1_BAIXA,(cQry)->E1_VENCREA,,(cQry)->E1_PREFIXO, (cQry)->E1_NUM, (cQry)->E1_PARCELA,(cQry)->E1_TIPO),(cQry)->E1_MOEDA,1,,,If(cPaisLoc=="BRA",(cQry)->E1_TXMOEDA,0)) 	//REQ020-Calculo de Juros e Multas: SIGALOJA x SIGAFIN 
								(cAlias)->E1_SALDO += xMoeda(nMulta,(cQry)->E1_MOEDA,1,,,If(cPaisLoc=="BRA",(cQry)->E1_TXMOEDA,0))

								If GetNewPar( "MV_ACATIVO", .F. )									
										(cAlias)->E1_SALDO += xMoeda(If(Empty((cQry)->(E1_BAIXA)) .And. dDataBase > (cQry)->(E1_VENCREA), (cQry)->(E1_VLMULTA), (cQry)->(E1_MULTA)),(cQry)->(E1_MOEDA),1,dDataBase,,ntaxaM)
								EndIf
							EndIf
						EndIf

					Case ( AllTrim(aStru[nCntFor][1])=="E1_SALDO2" )
						If ( (cQry)->(E1_TIPO)	$ MVABATIM )
							If aParam[12] == 2   // MV_PAR12 = 2 : Considera juros e taxa de pernamencia na visualizacao de titulos em aberto.	
								(cAlias)->E1_SALDO2 -= nTotAbat
							EndIf
						Else
							(cAlias)->E1_SALDO2 += (cQry)->(E1_SALDO)
								//Calculo de Juros e Multas: SIGALOJA x SIGAFIN   -Inicio
							(cAlias)->E1_VALJUR := xMoeda(FaJuros((cQry)->E1_VALOR,(cAlias)->E1_SALDO2,(cQry)->E1_VENCTO,(cQry)->E1_VALJUR,(cQry)->E1_PORCJUR,(cQry)->E1_MOEDA,(cQry)->E1_EMISSAO,,If(cPaisLoc=="BRA",(cQry)->E1_TXMOEDA,0),(cQry)->E1_BAIXA,(cQry)->E1_VENCREA,,(cQry)->E1_PREFIXO, (cQry)->E1_NUM, (cQry)->E1_PARCELA,(cQry)->E1_TIPO),(cQry)->E1_MOEDA,1,,,If(cPaisLoc=="BRA",(cQry)->E1_TXMOEDA,0))										    

							If (cMVJurTipo == "L" .Or. lMvLjIntFS)  .And. lLojxRMul							    
								(cAlias)->E1_MULTA := nMulta 
							EndIf 
							//Calculo de Juros e Multas: SIGALOJA x SIGAFIN  - Final							   								
							If aParam[12] == 2   // MV_PAR12 = 2 : Considera juros e taxa de pernamencia na visualizacao de titulos em aberto.	
								(cAlias)->E1_SALDO2 += (cAlias)->E1_SDACRES - (cAlias)->E1_SDDECRE
								(cAlias)->E1_SALDO2 += xMoeda((cAlias)->E1_VALJUR,1,(cQry)->(E1_MOEDA),dDataBase,,ntaxaM) 
								If (cMVJurTipo == "L" .Or. lMvLjIntFS) .And. lLojxRMul
									(cAlias)->E1_SALDO2 += xMoeda((cAlias)->E1_MULTA,1,(cQry)->(E1_MOEDA),dDataBase,,ntaxaM) 
								EndIf
								
								If GetNewPar( "MV_ACATIVO", .F. )									
										(cAlias)->E1_SALDO2 += xMoeda(If(Empty((cQry)->(E1_BAIXA)) .And. dDataBase > (cQry)->(E1_VENCREA), (cQry)->(E1_VLMULTA), (cQry)->(E1_MULTA)),(cQry)->(E1_MOEDA),1,dDataBase,,ntaxaM)
								EndIf								
							EndIf
						EndIf
					Case ( AllTrim(aStru[nCntFor][1])=="XX_RECNO" )
						If !( (cQry)->(E1_TIPO)	$ MVABATIM )
							(cAlias)->XX_RECNO := (cQry)->SE1RECNO
						EndIf
					Case ( !lRelat .And. AllTrim(aStru[nCntFor][1])=="XX_LEGEND" )
						If !((cQry)->E1_TIPO $ MVABATIM)
								(cAlias)->XX_LEGEND := If((cQry)->E1_VENCREA > Date(),"BR_VERDE","BR_VERMELHO")
						EndIf
						If (cQry)->E1_I_AVACC == "N" //Titulos marcados para nao serem considerados
						
							(cAlias)->XX_LEGEND := "BR_AMARELO"
						
						EndIf
					Case ( AllTrim(aStru[nCntFor][1])=="E1_TIPO" )
						If ( Empty((cAlias)->E1_TIPO) )
							(cAlias)->E1_TIPO := (cQry)->E1_TIPO
						EndIf
					Case ( AllTrim(aStru[nCntFor][1])=="E1_ATR" )
						//Se o título estiver atrasado, faz o calculo dos dias de atraso
						If dDataBase > (cQry)->E1_VENCREA
							If (((cAlias)->E1_TIPO) $ MVRECANT+"/"+MV_CRNEG)
								(cAlias)->E1_ATR := 0
							Else	
								(cAlias)->E1_ATR := dDataBase - (cAlias)->E1_VENCTO
							EndIf	
						Else
							If MV_PAR16 == 2 //Se o título NÃO estiver atrasado, então tem ATRASO = 0
								(cAlias)->E1_ATR := 0
							Else
								(cAlias)->E1_ATR := dDataBase - DataValida((cAlias)->E1_VENCREA,.T.)
							EndIf
						EndIf
					Case ( AllTrim(aStru[nCntFor][1])=="FLAG" )
					
					Case ( AllTrim(aStru[nCntFor][1])=="E1_VLCRUZ" )
						If !((cQry)->(E1_TIPO)	$ MVABATIM)
							(cAlias)->E1_VLCRUZ := xMoeda((cQry)->(E1_VALOR),(cQry)->(E1_MOEDA),1,dDataBase,,If(cPaisLoc=="BRA",(cQry)->E1_TXMOEDA,0))
						EndIf
					Case ( AllTrim(aStru[nCntFor][1])=="E1_VLMULTA" )
							(cAlias)->E1_VLMULTA := xMoeda(If(Empty((cQry)->(E1_BAIXA)) .And. dDataBase > (cQry)->(E1_VENCREA), (cQry)->(E1_VLMULTA), (cQry)->(E1_MULTA)),(cQry)->(E1_MOEDA),1,dDataBase,,ntaxaM)						
					OtherWise							
						If !( (cQry)->(E1_TIPO)	$ MVABATIM )
							(cAlias)->(FieldPut(nCntFor,(cQry)->(FieldGet(FieldPos(aStru[nCntFor][1])))))
						EndIf	
					EndCase
				Next nCntFor
				DBSelectArea(cAlias)
				If nTotAbat = 0
					If ( (cAlias)->E1_SALDO <= 0 )
						DBDelete()
					EndIf
				EndIf						
				MSUnLock()
			EndIf
			DBSelectArea(cQry)
			DBSkip()				
		EndDo

		DBSelectArea(cQry)
		DBCloseArea()

		DBSelectArea(cAlias)
		DBSetOrder(2)

	EndIf

	aGet[1] := 0
	aGet[2] := 0
	aGet[3] := 0
	aGet[4] := 0
	aGet[5] := 0
	aGet[6] := 0
	aGet[7] := 0
	aGet[8] := 0
	aTotRec := {{0,1,0,0}} // Totalizador de titulos a receber por moeda
	DBSelectArea(cAlias)
	DBGoTop()
	While !Eof()		 			 	
		aGet[1]++
		If !lRelat
			SE1->(DBGoTo((cAlias)->XX_RECNO))	// Posiciona no arquivo original para obter os valores
															// em outras moedas e em R$
			naScan := aScan(aTotRec,{|e| e[MOEDATIT] == E1_MOEDA})
		EndIf
		
		//Calcular o abatimento para visualização em tela
		If (cAlias)->E1_ABT > 0
			(cAlias)->E1_SALDO2 := xMoeda((cAlias)->E1_SALDO,E1_MOEDA,1,dDataBase,,ntaxaM)
		EndIf		 	
			
		If E1_TIPO $ "RA #"+MV_CRNEG
			aGet[2] -= E1_VLCRUZ
			aGet[3] -= E1_SALDO
			aGet[4] -= E1_VALJUR

			nAcresc := nDecres := 0
			If !lRelat
				nAcresc := xMoeda(E1_SDACRES,E1_MOEDA,1,dDataBase,,ntaxaM)
				nDecres := xMoeda(E1_SDDECRE,E1_MOEDA,1,dDataBase,,ntaxaM)
				aGet[5] -= nAcresc
				aGet[6] -= nDecres
				If naScan = 0
					aAdd(aTotRec,{1,E1_MOEDA,SE1->E1_SALDO*(-1),If(E1_MOEDA>1,xMoeda(SE1->E1_SALDO,E1_MOEDA,1,,,If(cPaisLoc=="BRA",SE1->E1_TXMOEDA,0)),SE1->E1_SALDO)*(-1)})
				Else
					aTotRec[naScan][QTDETITULOS]--
					aTotRec[naScan][VALORTIT]		-= SE1->E1_SALDO
					aTotRec[naScan][VALORREAIS]	-= If(E1_MOEDA>1,xMoeda(SE1->E1_SALDO,E1_MOEDA,1,,,If(cPaisLoc=="BRA",SE1->E1_TXMOEDA,0)),SE1->E1_SALDO)
				EndIf
			EndIf	
			If aParam[12] == 1 //Saldo sem correcao
				aGet[8] -= E1_SALDO-E1_ABT+E1_VALJUR+nAcresc-nDecres
			Else
				aGet[8] -= E1_SALDO
			EndIf
		Else	
			aGet[2] += E1_VLCRUZ
			aGet[3] += E1_SALDO
			aGet[4] += E1_VALJUR
			aGet[7] += E1_ABT
			nAcresc := nDecres := 0
			If !lRelat
				nAcresc := xMoeda(E1_SDACRES,E1_MOEDA,1,dDataBase,,ntaxaM)
				nDecres := xMoeda(E1_SDDECRE,E1_MOEDA,1,dDataBase,,ntaxaM)
				aGet[5] += nAcresc
				aGet[6] += nDecres
				If naScan = 0
					aAdd(aTotRec,{1,E1_MOEDA,SE1->E1_SALDO,If(E1_MOEDA>1,xMoeda(SE1->E1_SALDO,E1_MOEDA,1,,,If(cPaisLoc=="BRA",SE1->E1_TXMOEDA,0)),SE1->E1_SALDO)})
				Else
					aTotRec[naScan][QTDETITULOS]++
					aTotRec[naScan][VALORTIT]		+= SE1->E1_SALDO
					aTotRec[naScan][VALORREAIS]	+= If(E1_MOEDA>1,xMoeda(SE1->E1_SALDO,E1_MOEDA,1,,,If(cPaisLoc=="BRA",SE1->E1_TXMOEDA,0)),SE1->E1_SALDO)
				EndIf
			EndIf
			If aParam[12] == 1 //Saldo sem correcao
				aGet[8] += E1_SALDO-E1_ABT+E1_VALJUR+nAcresc-nDecres
			Else
				aGet[8] += E1_SALDO
			EndIf
		EndIf
		DBSkip()
	EndDo
	If !lRelat
		nTotalRec:=0
		aEval(aTotRec,{|e| nTotalRec+=e[VALORREAIS]})
		aAdd(aTotRec,{"","","Total ====>>",nTotalRec}) //
		// Formata as colunas
		aEval(aTotRec,{|e|	If(ValType(e[VALORTIT]) == "N"	, e[VALORTIT]		:= Transform(e[VALORTIT],Tm(e[VALORTIT],16,nCasas)),Nil),;
									If(ValType(e[VALORREAIS]) == "N"	, e[VALORREAIS]	:= Transform(e[VALORREAIS],Tm(e[VALORREAIS],16,nCasas)),Nil)})
	EndIf										

	aGet[1] := TransForm(aGet[1],Tm(aGet[1],16,0))
	aGet[2] := TransForm(aGet[2],Tm(aGet[2],16,nCasas))
	aGet[3] := TransForm(aGet[3],Tm(aGet[3],16,nCasas))
	aGet[4] := TransForm(aGet[4],Tm(aGet[4],16,nCasas))
	aGet[5] := TransForm(aGet[5],Tm(aGet[5],16,nCasas))
	aGet[6] := TransForm(aGet[6],Tm(aGet[6],16,nCasas))
	aGet[7] := TransForm(aGet[7],Tm(aGet[7],16,nCasas))		
	aGet[8] := TransForm(aGet[8],Tm(aGet[8],16,nCasas))		

DBSelectArea(cAlias)
DBGoTop()
If ( !Eof() )
	
	aObjects := {} 
	aAdd( aObjects, { 100, 35,  .T., .F., .T. } )
	aAdd( aObjects, { 100, 100 , .T., .T. } )
	aAdd( aObjects, { 100, 50 , .T., .F. } )
	
	aInfo    := { aSize[ 1 ], aSize[ 2 ], aSize[ 3 ], aSize[ 4 ], 3, 3 } 
	aPosObj1 := MsObjSize( aInfo, aObjects) 
	
	DEFINE FONT oBold    NAME "Arial" SIZE 0, -12 BOLD

	DEFINE MSDIALOG oDlg FROM	aSize[7],0 To aSize[6],aSize[5] TITLE cCadastro PIXEL//OF oMainWnd 
	@ aPosObj1[1,1], aPosObj1[1,2] MSPANEL oScrPanel PROMPT "" SIZE aPosObj1[1,3],aPosObj1[1,4] OF oDlg LOWERED

	@ 04,004 Say "Codigo" SIZE 025,07          OF oScrPanel PIXEL //
	@ 12,004 Say SA1->A1_COD  SIZE 060,09  OF oScrPanel PIXEL FONT oBold
	
	If aParam[13] == 1  //Considera loja		
		@ 04,067 Say "Loja" SIZE 020,07          OF oScrPanel PIXEL //
		@ 12,067 Say SA1->A1_LOJA SIZE 021,09 OF oScrPanel PIXEL FONT oBold
	EndIf

	@ 04,090 Say "Nome" SIZE 025,07 OF oScrPanel PIXEL //
	@ 12,090 Say SA1->A1_NOME SIZE 165,09 OF oScrPanel PIXEL FONT oBold

	oGetDb:=MsGetDB():New(aPosObj1[2,1],aPosObj1[2,2],aPosObj1[2,3],aPosObj1[2,4],2,"",,,.F.,,,.F.,,cAlias,,,,,,.T.)
	oGetDb:lDeleta:=NIL
	oGetDb:obrowse:bldblclick := { || U_AOMS064H(calias) }
	DBSelectArea(cAlias)
	DBGoTop()

	@ aPosObj1[3,1]+04,005 Say aSay[1] SIZE 045,07 OF oDlg PIXEL
	@ aPosObj1[3,1]+04,175 Say aSay[2] SIZE 045,07 OF oDlg PIXEL
	@ aPosObj1[3,1]+15,005 Say aSay[3] SIZE 045,07 OF oDlg PIXEL
	@ aPosObj1[3,1]+15,175 Say aSay[4] SIZE 045,07 OF oDlg PIXEL
	@ aPosObj1[3,1]+26,005 Say aSay[5] SIZE 045,07 OF oDlg PIXEL
	@ aPosObj1[3,1]+26,175 Say aSay[6] SIZE 045,07 OF oDlg PIXEL

	@ aPosObj1[3,1]+04,060 Say aGet[1] SIZE 060,07 OF oDlg PIXEL
	@ aPosObj1[3,1]+04,215 Say aGet[2] SIZE 060,07 OF oDlg PIXEL
	@ aPosObj1[3,1]+15,060 Say aGet[3] SIZE 060,07 OF oDlg PIXEL
	@ aPosObj1[3,1]+15,215 Say aGet[4] SIZE 060,07 OF oDlg PIXEL
	@ aPosObj1[3,1]+26,060 Say aGet[5] SIZE 060,07 OF oDlg PIXEL
	@ aPosObj1[3,1]+26,215 Say aGet[6] SIZE 060,07 OF oDlg PIXEL

	
	aoms064s(oDlg,aPosObj1,aSay,aGet)
	

	ACTIVATE MSDIALOG oDlg
Else
	U_ITMsg("Não foram localizados títulos em aberto para o cliente","Atenção",,3)	
EndIf

If Select(cAlias) <> 0
   _oTemp1:Delete()
EndIf   

FWRestArea(aAreaSC5)
FWRestArea(aAreaSC6)
FWRestArea(aAreaSC9)
FWRestArea(aAreaSF4)
FWRestArea(aArea)

Return

/*
===============================================================================================================================
Programa----------: AOMS64N
Autor-------------: Josué Danich Prestes
Data da Criacao---: 23/05/2018
Descrição---------: Prepara tabelas de consulta
Parametros--------: nacao - execucao por alias ou por array
					caliasfil - alias de leitura
Retorno-----------: nposalias - posição do registro
===============================================================================================================================
*/
Static Function AOMS064N(nAcao,cAliasFil)

Local nPosAlias		:= 0
Local cTmpFil		:= ""

Default cAliasFil	:= ""
Default nAcao		:= 2

If nAcao == 1
	If !Empty(cAliasFil)
		nPosAlias := aScan(aTmpFil,{|carq| carq[1] == cAliasFil})
		If nPosAlias == 0
			aAdd(aTmpFil,{"","",""})
			nPosAlias := Len(aTmpFil)
			aTmpFil[nPosAlias,1] := cAliasFil
			FWMsgRun(,{|| aTmpFil[nPosAlias,2] := GetRngFil(aSelFil,cAliasFil,.T.,@cTmpFil)},"Favor Aguardar.....","Consulta Posição Clientes" ) //###
			aTmpFil[nPosAlias,3] := cTmpFil
		EndIf
	EndIf
Else
	If nAcao == 2
		If !Empty(aTmpFil) 
			FWMsgRun(,{|| aEval(aTmpFil,{|T| CtbTmpErase(T[3])})},"Favor Aguardar.....","Consulta Posição Clientes" ) //###
			nPosAlias := Len(aTmpFil)
			aTmpFil := {}
			aSelFil := {}
		EndIf
	EndIf
EndIf

Return(nPosAlias)

/*
===============================================================================================================================
Programa----------: AOMS64S
Autor-------------: Josué Danich Prestes
Data da Criacao---: 23/05/2018
Descrição---------: Prepara tabelas de consulta
Parametros--------: odlg - objeto da msdialog
					aposobj1 - array com posições da msdialog
					asay - array com posições de labels
					aget - array com posições de campos
Retorno-----------: nenhum
===============================================================================================================================
*/
Static Function aoms064s(oDlg,aPosObj1,aSay,aGet)

@ aPosObj1[3,1]+37,005 Say aSay[7] SIZE 035,07 OF oDlg PIXEL  
@ aPosObj1[3,1]+37,060 Say aGet[7] SIZE 060,07 OF oDlg PIXEL

@ aPosObj1[3,1]+4, 300 BITMAP oBmp1 RESNAME "BR_VERDE" SIZE 16,16 NOBORDER OF oDlg PIXEL
@ aPosObj1[3,1]+4, 310 Say "Por vencer" OF oDlg PIXEL  
		
@ aPosObj1[3,1]+20.5, 300 BITMAP oBmp1 RESNAME "BR_VERMELHO" SIZE 16,16 NOBORDER OF oDlg PIXEL
@ aPosObj1[3,1]+20.5, 310 Say "Vencido" OF oDlg PIXEL  

@ aPosObj1[3,1]+37, 300 BITMAP oBmp1 RESNAME "BR_AMARELO" SIZE 16,16 NOBORDER OF oDlg PIXEL
@ aPosObj1[3,1]+37, 310 Say "Não considerado" OF oDlg PIXEL  

Return

/*
===============================================================================================================================
Programa----------: AOMS64H
Autor-------------: Josué Danich Prestes
Data da Criacao---: 23/05/2018
Descrição---------: Marca/Desmarca título para crédito
Parametros--------: Nenhum
Retorno-----------: nenhum
===============================================================================================================================
*/
User Function AOMS064H(calias)

If AllTrim((cAlias)->XX_LEGEND) == "BR_AMARELO"
	If U_ITMsg("Deseja que titulo seja considerado na análise de crédito?","Atenção",,2,2,2)
		SE1->(DBGoTo((cAlias)->XX_RECNO))
		If RecLock("SE1",.F.)
		
			SE1->E1_I_AVACC := " "
			SE1->(MSUnLock())
				
			RecLock(cAlias,.F.)
			(cAlias)->XX_LEGEND := If((cAlias)->E1_VENCREA > Date(),"BR_VERDE","BR_VERMELHO")
			(cAlias)->(MSUnLock())
		Else
			U_ITMsg("Registro em uso","Atenção","Aguarde alguns momentos e tente novamente",1)
		EndIf
	EndIf
Else
	If U_ITMsg("Deseja que titulo seja ignorado na análise de crédito?","Atenção",,2,2,2)
			SE1->(DBGoTo((cAlias)->XX_RECNO))
		If RecLock("SE1",.F.)
			SE1->E1_I_AVACC := "N"
			SE1->(MSUnLock())
				
			RecLock(cAlias,.F.)
			(cAlias)->XX_LEGEND := "BR_AMARELO"
			(cAlias)->(MSUnLock())
		Else
			U_ITMsg("Registro em uso","Atenção","Aguarde alguns momentos e tente novamente",1)
		EndIf
	EndIf
EndIf

Return

/*
===============================================================================================================================
Programa----------: AOMS64Q
Autor-------------: Josué Danich Prestes
Data da Criacao---: 24/08/2018
Descrição---------: Chama consulta cisp para pedido de vendas
Parametros--------: Nenhum
Retorno-----------: nenhum
===============================================================================================================================
*/
User Function AOMS064Q()

FWMsgRun(,{ || U_TelCred(2)}, "Aguarde...","Realizando consulta Cisp...")

Return

/*
===============================================================================================================================
Programa----------: AOMS64W
Autor-------------: Josué Danich Prestes
Data da Criacao---: 24/08/2018
Descrição---------: Chama consulta cisp para pedido do portal
Parametros--------: Nenhum
Retorno-----------: nenhum
===============================================================================================================================
*/
User Function AOMS064W()

//-- Posiciona no Cliente --//
SA1->( DBSetOrder(1) )
SA1->( DBSeek( xFilial("SA1") + SZW->( ZW_CLIENTE + ZW_LOJACLI ) ) )

FWMsgRun(,{ || U_TelCred(2)}, "Aguarde...","Realizando consulta Cisp...")

Return

/*
===============================================================================================================================
Programa----------: AOMS064D
Autor-------------: Josué Danich Prestes
Data da Criacao---: 04/02/2018
Descrição---------: Função responsável por exibir a janela para a digitação dos endereços de email, assunto, mensagem
Parametros--------: _cAnexo		- Endereço do arquivo anexo
------------------: _cEmail		- Endereço de E-mail para qual será enviado a mensagem
------------------: _cCc		- Endereço de E-mail que está no campo Com Cópia
------------------: _cAssunto	- Assunto do E-mail
------------------: _cMens		- Mensagem de texto para o corpo do E-mail
------------------: cMailCom    - Email de remetente
Retorno-----------: _lRet == .T. = E-mail enviado
                             .F. = Envio de E-mail cancelado.
===============================================================================================================================
*/
Static Function AOMS064D(_cAnexo,_cEmail,_cCc,_cAssunto,_cMens,cMailCom)

Local oAssunto
Local oButCan
Local oButEnv
Local oCc
Local oGetAssun
Local oGetCc
Local oGetPara
Local oMens
Local oPara
Local _csetor := ""
Local _aConfig	:= U_ITCFGEML('')
Local _cEmlLog	:= ""
Local cHtml		:= ""
Local nOpcA		:= 2
Local cGetAssun	:= _cAssunto
Local cGetCc	:= _cCc
Local cGetMens	:= ""
Local cGetPara	:= _cEmail + Space(80)
Local _lRet     := .F.

Private oDlgMail , _oFont


If (Len(PswRet()) # 0) // Quando nao For rotina automatica do configurador
	_csetor	:= AllTrim(PswRet()[1][12])		// Pega departamento do usuario
EndIf

If Empty(AllTrim(_csetor))
 	_csetor := "Crédito"
EndIf

_ccliente := SZW->ZW_CLIENTE + "/" + SZW->ZW_LOJACLI + " - " + Posicione("SA1",1,xFilial("SA1")+SZW->ZW_CLIENTE+SZW->ZW_LOJACLI,"A1_NREDUZ")

cHtml := 'À '+ Posicione("SA3",1,xFilial("SA3")+SZW->ZW_VEND1,"A3_NREDUZ") +','
cHtml += '<br><br>'
cHtml += '&nbsp;&nbsp;&nbsp;Segue aviso de rejeição de crédito do pedido  ' + SZW->ZW_IDPED + ' - ' +  ' do cliente ' + _ccliente + '.<br>'
cHtml += '<br><br>'
cHtml += '<font color="#FF0000"><b><u>Pedido: ' + SZW->ZW_IDPED + ' rejeitado por análise de crédito:  ' + SZW->ZW_I_MOTBL +' em ' + DToC(SZW->ZW_I_LIBCD) 
cHtml += ' - ' + SZW->ZW_I_LIBCT + ' por ' + SZW->ZW_I_LIBCA + '. </u></b><br><br></font>'
cHtml += '<br><br>'

cHtml += '&nbsp;&nbsp;&nbsp;A disposição!'
cHtml += '<br><br>'

cHtml += '<table class=MsoNormalTable border=0 cellpadding=0>'
cHtml += '<tr>'
cHtml +=     '<td style="padding:.75pt .75pt .75pt .75pt">'
cHtml +=         '<p class=MsoNormal align=center style="text-align:center">'
cHtml +=             '<b><span style="font-size:18.0pt;font-family:'+"'"+'Arial'+"'"+','+"'"+'sans-serif'+"'"+';color:#1D2668;mso-fareast-language:PT-BR">'+ Capital( AllTrim( UsrFullName( RetCodUsr() ) ) ) +'</span></b>'
cHtml +=             '<span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR"></span></p>
cHtml +=     '</td>'
cHtml +=     '<td style="background:#A2CFF0;padding:.75pt .75pt .75pt .75pt">&nbsp;</td>'
cHtml +=     '<td style="padding:.75pt .75pt .75pt .75pt">
cHtml +=         '<table class=MsoNormalTable border=0 cellpadding=0>'
cHtml +=              '<tr>'
cHtml +=                  '<td style="padding:.75pt .75pt .75pt .75pt">'
cHtml +=                      '<p class=MsoNormal><b><span style="font-size:13.5pt;font-family:'+"'"+'Arial'+"'"+','+"'"+'sans-serif'+"'"+';color:#6FB4E3;mso-fareast-language:PT-BR">' + _cSetor + '</span></b>'
cHtml +=                      '<b><span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR"></span></b>
cHtml +=                      '<span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR"><br></span>
cHtml +=                      '<span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR"></span></p>
cHtml +=                  '</td>'
cHtml +=              '</tr>'
cHtml +=              '<tr>'
cHtml +=                  '<td style="padding:.75pt .75pt .75pt .75pt">
cHtml +=                      '<p class=MsoNormal><span style="font-size:12.0pt;font-family:'+"'"+'Arial'+"'"+','+"'"+'sans-serif'+"'"+';color:#1D2668;mso-fareast-language:PT-BR">Tel: ' + Posicione("SY1",3,xFilial("SY1") + RetCodUsr(),"Y1_TEL") + '</span>'
cHtml +=                      '<span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR"></span></p>
cHtml +=                  '</td>'
cHtml +=              '</tr>'
cHtml +=         '</table>'
cHtml +=     '</td>'
cHtml += '</tr>'
cHtml += '</table>'
cHtml += '<table class=MsoNormalTable border=0 cellpadding=0 width=437 style="width:327.75pt">'
cHtml +=     '<tr>'
cHtml +=         '<td style="padding:.75pt .75pt .75pt .75pt">'
cHtml +=             '<p class=MsoNormal align=center style="text-align:center">'
cHtml +=             '<span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR">'
cHtml +=                 '<img width=400 height=51 src="http://www.italac.com.br/assinatura-italac/images/marcas-goiasminas-industria-de-laticinios-ltda.jpg">'
cHtml +=             '</span>
cHtml +=             '</p>'
cHtml +=         '</td>'
cHtml +=     '</tr>'
cHtml += '</table>'
cHtml += '<p class=MsoNormal><span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';display:none;mso-fareast-language:PT-BR">&nbsp;</span></p>'
cHtml += '<table class=MsoNormalTable border=0 cellpadding=0>'
cHtml +=     '<tr>'
cHtml +=         '<td style="padding:.75pt .75pt .75pt .75pt">'
cHtml +=             '<p class=MsoNormal align=center style="text-align:center">'
cHtml +=             '<b><span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';color:#1D2668;mso-fareast-language:PT-BR">Política de Privacidade </span></b>'
cHtml +=             '<span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR"></span></p>
cHtml +=             '<p class=MsoNormal style="mso-margin-top-alt:auto;mso-margin-bottom-alt:auto;text-align:justify">'
cHtml +=             '<span style="font-size:7.5pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';color:#1D2668;mso-fareast-language:PT-BR">
cHtml +=                 'Esta mensagem é destinada exclusivamente para fins profissionais, para a(s) pessoa(s) a quem For dirigida, podendo conter informação confidencial e legalmente privilegiada. '
cHtml +=                 'Ao recebê-la, se você não For destinatário desta mensagem, fica automaticamente notificado de abster-se a divulgar, copiar, distribuir, examinar ou, de qualquer forma, utilizar '
cHtml +=                 'sua informação, por configurar ato ilegal. Caso você tenha recebido esta mensagem indevidamente, solicitamos que nos retorne este e-mail, promovendo, concomitantemente sua '
cHtml +=                 'eliminação de sua base de dados, registros ou qualquer outro sistema de controle. Fica desprovida de eficácia e validade a mensagem que contiver vínculos obrigacionais, expedida '
cHtml +=                 'por quem não detenha poderes de representação, bem como não esteja legalmente habilitado para utilizar o referido endereço eletrônico, configurando falta grave conforme nossa '
cHtml +=                 'política de privacidade corporativa. As informações nela contidas são de propriedade da Italac, podendo ser divulgadas apenas a quem de direito e devidamente reconhecido pela empresa.'
cHtml +=             '</span>'
cHtml +=             '<span style="font-size:7.5pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR"></span></p>'
cHtml +=         '</td>'
cHtml +=     '</tr>
cHtml += '</table>'

DEFINE MSDIALOG oDlgMail TITLE "E-Mail" FROM 000, 000  To 415, 584 COLORS 0, 16777215 PIXEL

	//======
	// Para:
	//======
	@ 005, 006 Say oPara PROMPT "Para:" SIZE 015, 007 OF oDlgMail COLORS 0, 16777215 PIXEL
	@ 005, 030 MSGET oGetPara VAR cGetPara SIZE 256, 010 OF oDlgMail PICTURE "@x" COLORS 0, 16777215 PIXEL

	//===========
	// Com cópia:
	//===========
	@ 021, 006 Say oCc PROMPT "Cc:" SIZE 015, 007 OF oDlgMail COLORS 0, 16777215 PIXEL
	@ 021, 030 MSGET oGetCc VAR cGetCc SIZE 256, 010 OF oDlgMail PICTURE "@x" COLORS 0, 16777215 PIXEL

	//=========
	// Assunto:
	//=========
	@ 037, 006 Say oAssunto PROMPT "Assunto:" SIZE 022, 007 OF oDlgMail COLORS 0, 16777215 PIXEL
	@ 037, 030 MSGET oGetAssun VAR cGetAssun SIZE 256, 010 OF oDlgMail PICTURE "@x" COLORS 0, 16777215 PIXEL

	//==========
	// Mensagem:
	//==========
	@ 069, 006 Say oMens PROMPT "Mensagem:" SIZE 030, 007 OF oDlgMail COLORS 0, 16777215 PIXEL
	_oFont		:= TFont():New( 'Courier new' ,, 12 , .F. )
	_oScrAux	:= TSimpleEditor():New( 080 , 006 , oDlgMail , 285 , 105 ,,,,, .T. )
	
	_oScrAux:Load( cHtml )
	
	@ 189, 201 BUTTON oButEnv PROMPT "&Enviar"		SIZE 037, 012 OF oDlgMail ACTION ( nOpcA := 1 , cHtml := _oScrAux:RetText() , oDlgMail:End() ) PIXEL
	@ 189, 245 BUTTON oButCan PROMPT "&Cancelar"	SIZE 037, 012 OF oDlgMail ACTION ( nOpcA := 2 , oDlgMail:End() ) PIXEL

ACTIVATE MSDIALOG oDlgMail CENTERED

If nOpcA == 1
	cGetMens := AOMS064Z(cGetMens)
	//====================================
	// Chama a função para envio do e-mail
	//====================================
	U_ITENVMAIL( Lower(AllTrim(UsrRetMail(RetCodUsr()))), cGetPara, cGetCc, cMailCom, cGetAssun, cHtml, , _aConfig[01], _aConfig[02], _aConfig[03], _aConfig[04], _aConfig[05], _aConfig[06], _aConfig[07], @_cEmlLog )
    
	_lRet := .T.

Else
	U_ITMsg( 'Envio de e-mail cancelado pelo usuário.' , 'Atenção!' , ,1 )
EndIf

Return _lRet

/*
===============================================================================================================================
Programa----------: AOMS064Z
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 12/02/2018
Descrição---------: Função criada para fazer a quebra de linha na mensagem digitada pelo usuário
Parametros--------: ExpC1	- Texto da mensagem
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS064Z(cGetMens)
Local aTexto	:= StrTokArr( cGetMens, chr(10)+chr(13) )
Local cRet		:= ""
Local nI		:= 0

For nI := 1 To Len(aTexto)
	cRet += aTexto[nI] + "<br>"
Next

Return(cRet)

/*
===============================================================================================================================
Programa----------: AOMS064VP
Autor-------------: Erich Buttner
Data da Criacao---: 12/03/2013
Descrição---------: Rotina para visualização dos pedidos do portal
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS064VP()

Local cTitulo	:= "Visualização de Pedido Portal"
Local lRetMod2 	:= .F. // Retorno da função Modelo2 - .T. Confirmou / .F. Cancelou
Local nLinha	:= 0,nColuna
Public nOpcx	:= 7
Private nUsado , _csuper

nUsado		:= 0
aHeader		:= {}
aCols		:= {}
cDescr		:= ""
nQtd2UM		:= 0
c2UM		:= ""
nVlrTot		:= 0
nVTot		:= 0

//====================================================================================================
// Montagem do aHeader
//====================================================================================================

	aHeader := {	{ "Item"				, "ZW_ITEM"		, "@!"						,010,0,"AllwaysTrue()","","C","","R"},;
				{ "Produto"			, "ZW_PRODUTO"	, "@!"						,015,0,"AllwaysTrue()","","C","","R"},;
				{ "Descrição"			, "cDescr"			, "@!"						,020,0,"AllwaysTrue()","","C","","R"},;
				{ "Qtd Ven 2 UM"		, "nQtd2UM"		, "@e 999,999,999.99"	,014,2,"AllwaysTrue()","","C","","R"},;
				{ "Segunda UM"		, "c2UM"			, "@!"						,002,0,"AllwaysTrue()","","C","","R"},;
				{ "Quantidade"		, "ZW_QTDVEN"		, "@e 999,999,999.99"	,014,2,"AllwaysTrue()","","C","","R"},;
				{ "Unidade"			, "ZW_UM"			, "@!"						,002,0,"AllwaysTrue()","","C","","R"},;
				{ "Prc Unitario"		, "ZW_PRCVEN"		, "@e 9,999,999.9999"	,014,4,"AllwaysTrue()","","C","","R"},;
				{ "Vlr.Total "		, "nVlrTot"		, "@e 999,999,999.99"	,014,2,"AllwaysTrue()","","C","","R"},;
				{ "Blq. Preço "		, "ZW_BLOPRC"		, "@!"						,001,0,"AllwaysTrue()","","C","","R"},;
				{ "Local "		    , "ZW_LOCAL"	, "@!"						, 002 , 0 , "AllwaysTrue()" , "" , "C" , "" , "R" } }

_cpritab := ""

DBSelectArea("SZW")
SZW->( DBSetOrder(1) )
SZW->( DBSeek( SubStr(TMPVS->FILIAL,1,2)+TMPVS->NUMPED ) )  //Posiciona no primeiro registro do pedido
_nposi := SZW->(Recno())
_cchave := SZW->( ZW_FILIAL + ZW_IDPED )

While SZW->( !Eof() ) .And. SZW->( ZW_FILIAL + ZW_IDPED ) == _cchave
	
	//====================================================================================================
	// Montagem do Acols
	//====================================================================================================
	aAdd( aCols , Array( Len(aHeader) + 1 ) )
	nLinha++
	
	cDescr		:= GetAdvFVal( "SB1" , "B1_I_DESCD"		, xFilial("SB1") + AllTrim(SZW->ZW_PRODUTO)	, 1 , "" )
	nFatConv	:= GetAdvFVal( "SB1" , "B1_CONV"		, xFilial("SB1") + SZW->ZW_PRODUTO				, 1 , "" )
	cTpConv		:= GetAdvFVal( "SB1" , "B1_TIPCONV"		, xFilial("SB1") + SZW->ZW_PRODUTO				, 1 , "" )
	nNewFat		:= GetAdvFVal( "SB1" , "B1_I_FATCO"		, xFilial("SB1") + SZW->ZW_PRODUTO				, 1 , "" )
	c2UM		:= GetAdvFVal( "SB1" , "B1_SEGUM"		, xFilial("SB1")+AllTrim(SZW->ZW_PRODUTO)		, 1 , "" )
	
	If SZW->ZW_FILPRO != '0 ' .And. !Empty(SZW->ZW_FILPRO) .And. SZW->ZW_FILPRO != SZW->ZW_FILIAL 
		
		_cfilpro := SZW->ZW_FILPRO
		
	Else
		
		_cfilpro := SZW->ZW_FILIAL
			
	EndIf
	
	_csuper   := Posicione("SA3",1,xFilial("SA3")+SZW->ZW_VEND1,"A3_I_SUPE")
	_ccoord   := SA3->A3_SUPER
	_cgeren   := SA3->A3_GEREN
	_cvend4   := SA3->A3_I_SUPE
    _cRede    := Posicione("SA1",1,xFilial("SA1")+SZW->ZW_CLIENTE,"A1_GRPVEN")
    _cLocalEmb:= U_BuscaLocalEmbarque(_cfilpro,SZW->ZW_LOCAL,SZW->ZW_VEND1)//Função no Programa AOMS136.PRW
    _cCliAdqu := SZW->ZW_CLIREM
    _cLojadqu := SZW->ZW_LOJEN 

	                //ittabprc(_c5filgct,_c5filft       ,_cvend3,_cvend2,_cvend       ,_ccliente      ,_clojacli      ,_lusanovo,_cTab         ,_cVend4, _cRede, _cGrupoPrd,_cTipoOper  ,_cLocalEmb,_cCliAdqu,_cLojadqu)
	ctabela      := u_ittabprc( _cfilpro, SZW->ZW_FILIAL,_cgeren,_ccoord,SZW->ZW_VEND1,SZW->ZW_CLIENTE,SZW->ZW_LOJACLI,.T.      ,SZW->ZW_TABELA,_cvend4,_cRede ,           ,SZW->ZW_TIPO,_cLocalEmb,_cCliAdqu,_cLojadqu)
	
	//Se é primeiro item carrega tabela para comparação
	If Empty(_cpritab)
	
		_cpritab := ctabela[1]
		
	EndIf
	
	If  _cpritab != ctabela[1]  //Se a tabela é diferente da tabela do primeiro item grava como divergência
	
		csituaca    := "Tabela de preço divergente"
	
	Else
		
		//Posiciona a tabela de preço e verifica se preço está ok
		DA1->(DBSetOrder(1))
		If !DA1->(DBSeek(SZW->ZW_FILIAL+ctabela[1]+SZW->ZW_PRODUTO))
			csituaca := "Produto não consta na tabela de preço"
		ElseIf SZW->ZW_PRCVEN > DA1->DA1_I_PRCA
			csituaca    := "Preço acima do máximo: " + transform(DA1->DA1_I_PRCA,"@E 999,999,999.99")
		ElseIf SZW->ZW_PRCVEN < DA1->DA1_PRCVEN
			csituaca    := "Preço abaixo do mínimo: " + transform(DA1->DA1_PRCVEN,"@E 999,999,999.99")	
		Else
			csituaca    := "Pré Aprovado"
		EndIf
	EndIf
	
	If cTpConv == "M"
		nQtd2UM	:= IIf( nFatConv == 0 , nNewFat * SZW->ZW_QTDVEN	, nFatConv * SZW->ZW_QTDVEN	)
	Else
		nQtd2UM	:= IIf( nFatConv == 0 , SZW->ZW_QTDVEN / nNewFat	, SZW->ZW_QTDVEN / nFatConv	)
	EndIf
	
	nVlrTot		:= SZW->ZW_QTDVEN * SZW->ZW_PRCVEN
	nVtot		+= nVlrTot
	
	For nColuna := 1 To Len(aHeader)
		aCols[nLinha][nColuna] := &( aHeader[nColuna][2] )
	Next nColuna
	
	aCols[nLinha][Len(aHeader)+1] := .F. // Linha não deletada
	
SZW->( DBSkip() ) 

EndDo

cFli		:= Space(20)
cFilPro		:= Space(40)
cTipPed		:= Space(15)
cNumPed		:= Space(25)
cCliente	:= Space(06)
cNomCli		:= Space(60)
cLojaCli	:= Space(04)
cGrpCli		:= Space(30)
ccond		:= Space(50)
cVend1		:= Space(06)
cNmVend1	:= Space(40)
cVend2		:= Space(06)
cNmVend2	:= Space(40)
cPedCli		:= Space(09)
dDtEnt		:= CtoD("")
cTipoAg		:= Space(10)
cHrEnt		:= Space(05)
cSha		:= Space(14)
cTipFre		:= Space(10)
cTipCar		:= Space(15)
cQtdCha		:= Space(03)
cHrDes		:= Space(05)
nCusDes		:= 0
cObsCom		:= Space(120)
cObsNF		:= Space(120)
cObsALC		:= Space(120)

DBSelectArea("SZW")
SZW->( DBSetOrder(1) )
SZW->( DBSeek(  _cchave ) )

dDtEnt		:= SZW->ZW_FECENT
_laltera := .T.

If SZW->ZW_I_AGEND == 'P'
	If month(Date()) != 12
		dDtEnt := SToD(AllTrim(Str((YEAR(Date())+1)))+"0101")-1
	Else
		dDtEnt := SToD(AllTrim(Str((YEAR(Date())+2)))+"0101")-1
	EndIf
	
	_laltera := .F.
EndIf
	
If SZW->ZW_I_AGEND $ 'I/O'
   dDtEnt := Date()+u_omsvldent(Date(),SZW->ZW_CLIENTE,SZW->ZW_LOJACLI,SZW->ZW_FILIAL,SZW->ZW_IDPED,1,.F.)+1
   _laltera := .F.
EndIf
	
cTipoAg:=SZW->ZW_I_AGEND+" - "+U_TipoEntrega(SZW->ZW_I_AGEND)

//====================================================================================================
// Configuracao dos Campos
// aC[n,1] = Nome da Variavel Ex.:"cCliente"
// aC[n,2] = Array com coordenadas do Get [x,y], em Windows estao em PIXEL
// aC[n,3] = Titulo do Campo
// aC[n,4] = Picture
// aC[n,5] = Validacao
// aC[n,6] = F3
// aC[n,7] = Se campo e' editavel .T. se nao .F.
//====================================================================================================
aC := {	{ "cFli"	, {015,003}	, "Filial                   " 	  	,"@!"   				,	,		,.F.	},;
		{ "cFilPro" , {015,203} ,"Filial Carregamento   "          	,"@!"   				,   ,       ,.F.	},; 
		{ "cTipPed"	, {030,003}	, "Tipo Pedido       " 				,"@!"   				,	,		,.F.	},;
		{ "cNumPed"	, {030,203}	, "Num. Pedido " 						,"@!"   				,	,		,.F.	},;
		{ "cCliente"  , {045,003}	, "Cliente               " 			,"@!"   				,	,		,.F.	},;
		{ "cLojaCli"	, {045,085}	, "Loja   "							,"@!"   				,	,		,.F.	},;
		{ "cNomCli"	, {045,140}	, "Nome Cliente         "			,"@!"   				,	,		,.F.	},;
		{ "cGrpCli"	, {060,003}	, "Grupo Cliente    "				,"@!"   				,	,		,.F.	},;
		{ "cCond"		, {060,285}	, "Cond. Pagto" 						,"@!"   				,	,		,.F.	},;
		{ "cVend1"		, {075,003}	, "Vendedor 1       "  				,"@!"   				,	,		,.F.	},;
		{ "cNmVend1"	, {075,140}	, "Nome Vendedor 1" 					,"@!"   				,	,		,.F.	},;
		{ "nVTot"		, {075,500}	, "Valor Total   " 					,"@e 999,999,999.99"	,	,		,.F.	},;
		{ "cVend2"		, {090,003}	, "Vendedor 2       "  				,"@!"   				,	,		,.F.	},;
		{ "cNmVend2"	, {090,140}	, "Nome Vendedor 2" 					,"@!"   				,	,		,.F.	},;
		{ "cPedCli"	, {105,003}	, "Pedido Cliente    "				,"@!"   				,	,		,.F.	},;
		{ "dDtEnt"		, {015,500}	, "Data Entrega          "				,"@!"   				,	,		,_laltera	},;
		{ "cTipoAg"		,{030,500}	,"Tipo de Entrega"				,"@!"   				,	,		,.F.	},;
		{ "cHrEnt"		, {105,245}	, "Hora Entrega   "					,"@!"   				,	,		,.F.	},;
		{ "cSha"		, {105,325}	, "Senha                "			,"@!"   				,	,		,.F.	},;
		{ "cTipFre"	, {105,500}	, "Tipo Frete    "					,"@!"   				,	,		,.F.	},;
		{ "cTipCar"	, {120,003}	, "Tipo Entrega      "			,"@!"   				,	,		,.F.	},;
		{ "cQtdCha"	, {120,140}	, "Qtd. Chapa           "			,"@!"   				,	,		,.F.	},;
		{ "cHrDes"		, {120,245}	, "Hora Descarga"						,"@!"   				,	,		,.F.	},;
		{ "nCusDes"	, {120,325}	, "Custo Descarga"					,"@e 999,999,999.99"	,	,		,.F.	},;
		{ "cObsCom"	, {135,003}	, "Obs. Comercial  "					,"@!"					,	,		,.F.	},;
		{ "cObsNf"		, {150,003}	, "Mensagem NF    "					,"@!"					,	,		,.F.	},;
		{ "cObsALC"	, {165,003}	, "Análise Lim. Cr. "				,"@!"					,	,		,.F.	} }

//====================================================================================================
// Conteudo dos Campos
// aR[n,1] = Nome da Variavel Ex.:"cCliente"
// aR[n,2] = Array com coordenadas do Get [x,y], em Windows estao em PIXEL
// aR[n,3] = Titulo do Campo
// aR[n,4] = Picture
// aR[n,5] = Validacao
// aR[n,6] = F3
// aR[n,7] = Se campo e' editavel .T. se nao .F.
//====================================================================================================
aR := {}
DBSelectArea("SZW")
SZW->( DBSetOrder (1) )
If SZW->( DBSeek( _cchave ) )

	cFli		:= LEFT(SubStr(SZW->ZW_FILIAL,1,2)+" - "+GetAdvFVal("ZZM","ZZM_DESCRI",xFilial("ZZM")+SubStr(SZW->ZW_FILIAL,1,2),1,""),25)
	cFilPro		:= SubStr(SZW->ZW_FILPRO,1,2)+" - "+GetAdvFVal("ZZM","ZZM_DESCRI",xFilial("ZZM")+SubStr(SZW->ZW_FILPRO,1,2),1,"")
	cTipPed		:= SubStr(SZW->ZW_TIPO+" - "+GetAdvFVal("ZB4","ZB4_DESCRI",xFilial("ZB4")+SZW->ZW_TIPO,1,""),1,25)
	cNumPed  	:= SZW->ZW_IDPED
	cCliente 	:= SZW->ZW_CLIENTE
	cLojaCli 	:= SZW->ZW_LOJACLI
	cNomCli 	:= GetAdvFVal("SA1","A1_NOME",xFilial("SA1")+SZW->ZW_CLIENTE+SZW->ZW_LOJACLI,1,"")
	cGrpCli		:= GetAdvFVal("SA1","A1_GRPVEN",xFilial("SA1")+SZW->ZW_CLIENTE+SZW->ZW_LOJACLI,1,"")+" - "+GetAdvFVal("SA1","A1_I_NGRPC",xFilial("SA1")+SZW->ZW_CLIENTE+SZW->ZW_LOJACLI,1,"")
	cVend1	 	:= SZW->ZW_VEND1
	cNmVend1 	:= GetAdvFVal("SA3","A3_NOME",xFilial("SA3")+SZW->ZW_VEND1,1,"")
	cVend2   	:= SZW->ZW_VEND2
	cNmVend2 	:= GetAdvFVal("SA3","A3_NOME",xFilial("SA3")+SZW->ZW_VEND2,1,"")
	nVTot 		:= nVTot
	cPedCli		:= SZW->ZW_PEDCLI
	ccond      := AOMS0645()
	cHrEnt		:= SZW->ZW_HOREN
	cSha		:= SZW->ZW_SENHA
	cTipFre		:= If(SZW->ZW_TPFRETE == 'C',SZW->ZW_TPFRETE+" - CIF",SZW->ZW_TPFRETE+" - FOB")
	_cchep 		:= Posicione("SA1",1,xFilial("SA1")+ccliente+cLojaCli,"A1_I_CCHEP") 
	cTipCar		:= If( !Empty(_cchep) , "1 - Paletizada" , "2 - Batida" ) 
	cQtdCha		:= SZW->ZW_CHAPA
	cHrDes		:= SZW->ZW_HORDES
	nCusDes		:= SZW->ZW_CUSDES
	cObsCom		:= SZW->ZW_OBSCOM
	cObsNF		:= SZW->ZW_MENNOTA
	cObsALC		:= SZW->ZW_OBSAVAC
	
	//====================================================================================================
	// Array com as Coordenadas da Tela para o GetDados
	//====================================================================================================
	aCGD:={350,06,26,74}
	
	//====================================================================================================
	// Chamada da Modelo2
	//====================================================================================================
	lRetMod2 := Modelo2( cTitulo , aC , aR , aCGD , nOpcx ,,,,,, 9999 ,,, .T. )

Else
	U_ITMsg(  'Não foi possível posicionar no pedido!' , 'Atenção!',,1)
EndIf

Return

/*
===============================================================================================================================
Programa--------: AOMS0645
Autor-----------: Josué Danich Prestes
Data da Criacao-: 28/03/2018
Descrição-------: Retorna condição de pagamento do pedido de vendas
                  
Parametros------: Nenhum
Retorno---------: _ccond - Condição de pagamento do pedido de vendas
===============================================================================================================================
*/
Static Function AOMS0645()

Local _ccond := ""
		
_ccond := u_IT_conpg(AllTrim(SZW->ZW_CLIENTE),AllTrim(SZW->ZW_LOJACLI),AllTrim(SZW->ZW_PRODUTO),.F.)
		
//Se achou regra de condição de pagamento usa a regra, senão achou regra pega do szw
If !Empty(_ccond)
	_cCond		:= _ccond+" - "+GetAdvFVal("SE4","E4_DESCRI",xFilial("SE4")+_ccond,1,"")
Else
	_cCond		:= SZW->ZW_CONDPAG+" - "+GetAdvFVal("SE4","E4_DESCRI",xFilial("SE4")+SZW->ZW_CONDPAG,1,"")
EndIf

Return _ccond

/*
===============================================================================================================================
Programa----------: AOMS064I
Autor-------------: Josué Danich Prestes
Data da Criacao---: 24/05/2019
Descrição---------: Rotina para inverter a marcacao do registro posicionado.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS064I()

If Empty(TMP64->OK2)
	_nValor -= Val(TMP64->VALOR)
	nQtdTit--
Else
	_nValor += Val(TMP64->VALOR)
	nQtdTit++
EndIf

oValor:Refresh()
oQtda:Refresh()

Return

/*
===============================================================================================================================
Programa----------: AOMS064K
Autor-------------: Josué Danich Prestes
Data da Criacao---: 24/05/2019
Descrição---------: Liberação Multipla de pedidos
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS064K()

Local oDlg2
Local nOpca := 0
Local lAvaAux := .T.
Local _nposi := TMP64->(Recno())
Local cMatUsr	:= FWSFAllUsers({__cUserID},{"USR_FILIAL"})[1][3]+FWSFAllUsers({__cUserID},{"USR_CODFUNC"})[1][3]
Local cAutoriz	:= GetAdvFVal( "ZZL" , "ZZL_LIBCRE" , xFilial("ZZL") + cMatUsr , 1 , "N" )
Local _nI := 0

//-- Controle de acesso por usuario conforme parametrizacao no Gerenciador (Gestao de Usuarios) --//
If !( cAutoriz == "S" )
	U_ITMsg("Usuário sem acesso à rotina de avaliação dos Pedidos bloqueados para análise de Crédito.","Atenção!",,1)
	Return
EndIf

//Valida marcados
If nQtdTit == 0

	U_ITMsg("Selecione ao menos um título para liberação múltipla","Atenção",,1)
	Return

EndIf

DEFINE MSDIALOG oDlg2 FROM 125,003 To 200,500 TITLE "Liberação Multipla de Crédito" PIXEL

@ 002, 004  To 035, 140 LABEL "Ação a realizar"		OF oDlg2 PIXEL COLOR CLR_HBLUE 

//-- Botoes de Acao da Rotina --//
oButtonA := TButton():New( 010 , 010 , "Aprovar"	, oDlg2 , {|| (nOpca := 1,oDlg2:End()) } , 40 , 10 ,,,.F.,.T.,.F.,,.F.,{|| lAvaAux},,.F. )
oButtonA := TButton():New( 010 , 051 , "Apr Comp"	, oDlg2 , {|| (nOpca := 3,oDlg2:End()) } , 40 , 10 ,,,.F.,.T.,.F.,,.F.,{|| lAvaAux},,.F. )
oButtonR := TButton():New( 010 , 092 , "Rejeitar"	, oDlg2 , {|| (nOpca := 2,oDlg2:End()) } , 40 , 10 ,,,.F.,.T.,.F.,,.F.,{|| lAvaAux},,.F. )

//-- Fechar --//
@ 010,150 BUTTON "Cancelar"	SIZE 030,011 PIXEL OF oDlg2 ACTION (nOpca := 0, oDlg2:End())

ACTIVATE MSDIALOG oDlg2

If nOpca > 0

	//Solicita motivo de aprovação completa ou rejeição
	nOpcCnf := 0 //Variavel para tratar o [X] da janela como "Cancelar"
	If nOpca == 3
       _nLinDlg:=180
	Else
       _nLinDlg:=140
	EndIf
	
	dLimite := Date() + 7
	cObsAva := Space(200)

	DEFINE MSDIALOG oDlg2 TITLE "Confirmar Avaliação: "+IIf(nOpca == 1,"Liberar",IIf(nOpca == 3, "Liberar Completo","Rejeitar"));
					 FROM 000,000 To _nLinDlg,600 OF oDlg2 PIXEL
		
		@ 004,004 To 026,296 LABEL "Motivo: (Obrigatório)" OF oDlg2 PIXEL
		@ 011,008 MSGET cObsAva PICTURE "@x"	SIZE 220,010 PIXEL OF oDlg2
		
		If nOpca == 3
		
			@ 034,004 To 056,296 LABEL "Validade da liberação completa: " OF oDlg2 PIXEL
			@ 041,008 MSGET dLimite 	SIZE 220,010 PIXEL OF oDlg2
            nLin:=60
		Else
            nLin:=30
		EndIf
		
		@ 040,230 BUTTON "&Ok"		 SIZE 030,014 PIXEL ACTION ( IIf( Empty(cObsAva) , U_ITMsg("Obrigatório informar o motivo.","Atenção",,1) , ( nOpcCnf:=nOpca , oDlg2:End() ) ) )
		@ 040,261 BUTTON "&Cancelar" SIZE 030,014 PIXEL ACTION ( nOpcCnf:=0 , oDlg2:End() )
	
	ACTIVATE MSDIALOG oDlg2 CENTER

	TMP64->(DBGoTop())
	If nOpcCnf == nOpca
		While !(TMP64->(Eof()))
			If !Empty(TMP64->OK2)
				If _nSelOrigem == 1 //Liberação de pedido de vendas protheus
					//Posiciona SC5 para rotina de liberação
					SC5->(DBSetOrder(1))
					If SC5->(DBSeek(SubStr(TMP64->FILIAL,1,2)+AllTrim(TMP64->NUMPED)))
						//Realiza liberação do pedido de vendas do protheus
						_nI++
						FWMsgRun(,{|| AOMS064L5(nOpcCnf)},"Aguarde...","Atualizando pedido " + StrZero(_nI,6) + " de " + StrZero(nQtdTit,6) + "...")
					EndIf
				Else// Liberação de pedido de vendas do portal
					//Posiciona SZW para rotina de liberação
					SZW->(DBSetOrder(1))
					If SZW->(DBSeek(SubStr(TMP64->FILIAL,1,2)+AllTrim(TMP64->NUMPED)))
						_nI++
						FWMsgRun(,{|| AOMS064LW(nOpcCnf)},"Aguarde...","Atualizando pedido " + StrZero(_nI,6) + " de " + StrZero(nQtdTit,6) + "...")
					EndIf
				EndIf
			EndIf

			TMP64->(DBSkip())
		EndDo
	Else
		U_ITMsg("Processo cancelado","Atenção",,1)
	EndIf
Else
	U_ITMsg("Processo cancelado","Atenção",,1)
EndIf

TMP64->(DBGoTo(_nposi))

Return

/*
===============================================================================================================================
Programa----------: AOMS064L5
Autor-------------: Josué Danich Prestes
Data da Criacao---: 24/05/2019
Descrição---------: Liberação de pedido da SC5 posicionado
Parametros--------: nopccnf - tipo de liberação - 1 Normal, 2 Rejeição, 3 Completa
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS064L5(nopccnf)

Local _aDadosHist := {}
Local _StatusPV
Local _cMsg  
Local _cCodOper
Local _dDataOper
Local _cEncer 

//-- Reposiciona no Cliente --//
DBSelectArea("SA1")
SA1->( DBSetOrder(1) )
SA1->( DBSeek( xFilial("SA1") + SC5->( C5_CLIENTE + C5_LOJACLI ) ) )

nMoeda		:= 1
nValPed		:= AOMS064VT2( SC5->C5_NUM , SC5->C5_FILIAL ,, 3 )
cDescBloq	:= IIf(SC5->C5_I_BLCRE = 'B',"Bloqueado",IIf(SC5->C5_I_BLCRE = 'R', "Rejeitado", ""))
cDescri		:= SubStr(SA1->A1_NOME,1,35)

BEGIN TRANSACTION
Begin Sequence
	If nOpcCnf == 1 .Or. nOpcCnf == 3
		If nOpcCnf == 1
			//==============================================================
			// Monta array com os dados de alteração
			//==============================================================		
			aAdd(_aDadosHist,{"C5_I_BLCRE",SC5->C5_I_BLCRE,"L"})
			aAdd(_aDadosHist,{"C5_I_LIBCD",SC5->C5_I_LIBCD,Date()})
			aAdd(_aDadosHist,{"C5_I_LIBCT",SC5->C5_I_LIBCT,time()})
			aAdd(_aDadosHist,{"C5_I_LIBC",SC5->C5_I_LIBC,0})
			aAdd(_aDadosHist,{"C5_I_LIBCA",SC5->C5_I_LIBCA,_cUsrFullName})
			aAdd(_aDadosHist,{"C5_I_DTLIC",SC5->C5_I_DTLIC,Date()})
			aAdd(_aDadosHist,{"C5_I_MOTBL",SC5->C5_I_MOTBL,cObsAva})
			_StatusPV :=  SC5->C5_I_STATU

			SC5->(RecLock("SC5",.F.))
			
			SC5->C5_I_BLCRE := "L"
			SC5->C5_I_LIBCD := Date()
			SC5->C5_I_LIBCT := Time()
			SC5->C5_I_LIBC  := 0
			SC5->C5_I_LIBCA := _cUsrFullName
			SC5->C5_I_DTLIC := Date()
			SC5->C5_I_MOTBL := cObsAva
			
			SC5->( MSUnLock() )
			SC5->(RecLock("SC5",.F.))
			SC5->C5_I_STATU := U_STPEDIDO() //Função de análise do pedido de vendas no xfunoms
			SC5->(MSUnLock())
			
			aAdd(_aDadosHist,{"C5_I_STATU",_StatusPV,SC5->C5_I_MOTBL})

			//==============================================================
			// Gravação do Monitor
			//==============================================================
			_cMsg      := "Avaliado pelo Credito - Aprovado."
		
			_cCodOper  := "019"
			_dDataOper := Date()
			_cEncer    := "N"
				
			U_GrvMonitor(SC5->C5_FILIAL,SC5->C5_NUM,_cCodOper,_cMsg,_cEncer,_dDataOper,_dDataOper,_dDataOper) 

			//==============================================================
			// Gravação do Histórico / Log
			//==============================================================
			U_ITGrvLog( _aDadosHist , 'SC5' , 1 , SC5->C5_FILIAL+SC5->C5_NUM, "A" , RetCodUsr() )

			//==============================================================
			//Envia interface para o rdc com status do pedido
			//==============================================================
			If  SC5->C5_I_ENVRD == "S"

				U_ENVSITPV()   //Envia interface de alteração de situação do pedido atual

			EndIf
			
			If !Empty(TMP64->OK2)
			
				_nValor -= Val(TMP64->VALOR)
				nQtdTit--
				oValor:Refresh()
				oQtda:Refresh()

			EndIf
			
			TMP64->(RecLock("TMP64",.F.))
			
			TMP64->( DBDelete() )
			
			TMP64->(  MSUnLock() )
			
			
		ElseIf	nOpcCnf == 3
			//==============================================================
			// Monta array com os dados de alteração
			//==============================================================		
			aAdd(_aDadosHist,{"C5_I_BLCRE",SC5->C5_I_BLCRE,"L"})
			aAdd(_aDadosHist,{"C5_I_LIBCD",SC5->C5_I_LIBCD,Date()})
			aAdd(_aDadosHist,{"C5_I_LIBCT",SC5->C5_I_LIBCT,time()})
			aAdd(_aDadosHist,{"C5_I_LIBCV",SC5->C5_I_LIBCV,nValPed})
			aAdd(_aDadosHist,{"C5_I_LIBL" ,SC5->C5_I_LIBL,dlimite})
			aAdd(_aDadosHist,{"C5_I_LIBC" ,SC5->C5_I_LIBC,2})
			aAdd(_aDadosHist,{"C5_I_LIBCA",SC5->C5_I_LIBCA,_cUsrFullName})
			aAdd(_aDadosHist,{"C5_I_DTLIC",SC5->C5_I_DTLIC,Date()})
			aAdd(_aDadosHist,{"C5_I_MOTBL",SC5->C5_I_MOTBL,cObsAva})
			_StatusPV :=  SC5->C5_I_STATU

			SC5->(RecLock("SC5",.F.))
			
			SC5->C5_I_BLCRE := "L"
			SC5->C5_I_LIBCD := Date()
			SC5->C5_I_LIBCT := Time()
			SC5->C5_I_LIBCV := nValPed
			SC5->C5_I_LIBL  := dlimite
			SC5->C5_I_LIBC  := 2
			SC5->C5_I_LIBCA := _cUsrFullName
			SC5->C5_I_DTLIC := Date()
			SC5->C5_I_MOTBL := cObsAva
			
			SC5->( MSUnLock() )

			SC5->(RecLock("SC5",.F.))
			SC5->C5_I_STATU := U_STPEDIDO() //Função de análise do pedido de vendas no xfunoms
			SC5->(MSUnLock())
			
			aAdd(_aDadosHist,{"C5_I_STATU",_StatusPV,SC5->C5_I_MOTBL})

			//==============================================================
			// Gravação do Monitor
			//==============================================================
			_cMsg      := "Avaliado pelo Credito - Aprovado."
		
			_cCodOper  := "019"
			_dDataOper := Date()
			_cEncer    := "N"
				
			U_GrvMonitor(SC5->C5_FILIAL,SC5->C5_NUM,_cCodOper,_cMsg,_cEncer,_dDataOper,_dDataOper,_dDataOper) 

			//==============================================================
			// Gravação do Histórico / Log
			//==============================================================
			U_ITGrvLog( _aDadosHist , 'SC5' , 1 , SC5->C5_FILIAL+SC5->C5_NUM, "A" , RetCodUsr() )
			
			//==============================================================
			//Envia interface para o rdc com status do pedido
			//==============================================================
			If  SC5->C5_I_ENVRD == "S"

				U_ENVSITPV()   //Envia interface de alteração de situação do pedido atual

			EndIf
			
			If !Empty(TMP64->OK2)
			
				_nValor -= Val(TMP64->VALOR)
				nQtdTit--
				oValor:Refresh()
				oQtda:Refresh()

			EndIf
			
			TMP64->(RecLock("TMP64",.F.))
			
			TMP64->( DBDelete() )
			
			TMP64->(  MSUnLock() )
		
		EndIf
	    
		//Faz liberação da SC9 se existir 
		DBSelectArea("SC9")
		SC9->( DBSetOrder(1) )
		
		If SC9->( DBSeek(xFilial("SC9") + SC5->C5_NUM ) ) .And.  SC5->C5_LIBEROK = "S"
			While SC9->C9_FILIAL = xFilial("SC9") .And. SC9->C9_PEDIDO = SC5->C5_NUM
				If !(Empty(SC9->C9_BLCRED))
					RecLock("SC9",.F.)
					SC9->C9_BLCRED := " "
					MSUnLock("SC9")
		
					//Faz análise e liberação de estoque pois o padrão não analisa estoque se o crédito está bloqueado
					//Posiciona SC6 pois a função A440VerSb2 depende do SC6 posicionado para analisar o estoque
					DBSelectArea("SC6")
					SC6->(DBSetOrder(1))
								
					If SC6->(DBSeek(SC9->C9_FILIAL+SC9->C9_PEDIDO+SC9->C9_ITEM)) .And. A440VerSB2(SC9->C9_QTDLIB)
						If !(Empty(SC9->C9_BLEST))
							If !(RecLock("SC6",.F.))
								U_ITMsg("Pedido não pode ser liberado pois está aberto para outro usuário!", "Atenção!" , ,1 )
								DisarmTransaction()
								Break
							EndIf
							
							RecLock("SC9",.F.)

							SC9->C9_BLEST := ""
							If !(MaAvalSC9("SC9",5,{{ "","","","",SC9->C9_QTDLIB,SC9->C9_QTDLIB2,Ctod(""),"","","",SC9->C9_LOCAL}}))
								SC9->C9_BLEST := "02"
							EndIf	
							MSUnLock("SC9")
						EndIf
					EndIf	
				EndIf
				SC9->( DBSkip() )
			EndDo
		EndIf
	ElseIf nOpcCnf == 2
		//==============================================================
		// Monta array com os dados de alteração
		//==============================================================		
		aAdd(_aDadosHist,{"C5_I_BLCRE",SC5->C5_I_BLCRE,"L"})
		aAdd(_aDadosHist,{"C5_I_LIBCD",SC5->C5_I_LIBCD,Date()})
		aAdd(_aDadosHist,{"C5_I_LIBCT",SC5->C5_I_LIBCT,time()})
		aAdd(_aDadosHist,{"C5_I_LIBCA",SC5->C5_I_LIBCA,_cUsrFullName})
		aAdd(_aDadosHist,{"C5_I_DTLIC",SC5->C5_I_DTLIC,Date()})
		aAdd(_aDadosHist,{"C5_I_MOTBL",SC5->C5_I_MOTBL,If(!Empty(cObsAva),cObsAva,"Rejeitado")})
		_StatusPV :=  SC5->C5_I_STATU


		SC5->(RecLock("SC5",.F.))
		
		SC5->C5_I_BLCRE := "R"
		SC5->C5_I_LIBCD := Date()
		SC5->C5_I_LIBCT := Time()
		SC5->C5_I_LIBCA := _cUsrFullName
		SC5->C5_I_DTLIC := Date()
		SC5->C5_I_MOTBL := If(!Empty(cObsAva),cObsAva,"Rejeitado")
		
		SC5->( MSUnLock() )

		SC5->(RecLock("SC5",.F.))
		SC5->C5_I_STATU := U_STPEDIDO() //Função de análise do pedido de vendas no xfunoms
		SC5->(MSUnLock())
		
		aAdd(_aDadosHist,{"C5_I_STATU",_StatusPV,SC5->C5_I_MOTBL})

		//==============================================================
		// Gravação do Monitor
		//==============================================================
		_cMsg      := "Avaliado pelo Credito - Rejeitado."
	
		_cCodOper  := "020"
		_dDataOper := Date()
		_cEncer    := "N"
			
		U_GrvMonitor(SC5->C5_FILIAL,SC5->C5_NUM,_cCodOper,_cMsg,_cEncer,_dDataOper,_dDataOper,_dDataOper) 

		//==============================================================
		// Gravação do Histórico / Log
		//==============================================================
		U_ITGrvLog( _aDadosHist , 'SC5' , 1 , SC5->C5_FILIAL+SC5->C5_NUM, "A" , RetCodUsr() )
		
		//==============================================================
		//Envia interface para o rdc com status do pedido
		//==============================================================
		If  SC5->C5_I_ENVRD == "S"
			U_ENVSITPV()   //Envia interface de alteração de situação do pedido atual
		EndIf
		
		TMP64->(RecLock("TMP64",.F.))
		
		TMP64->MOTIVO := "Rejeitado"
		TMP64->BLCRE	  := "R"
		
		TMP64->(  MSUnLock() )

		If !Empty(TMP64->OK2)
			_nValor -= Val(TMP64->VALOR)
			nQtdTit--
			oValor:Refresh()
			oQtda:Refresh()
		EndIf
		
		TMP64->(RecLock("TMP64",.F.))
		
		TMP64->( DBDelete() )
		
		TMP64->(  MSUnLock() )
	Else
		DisarmTransaction()
		Break
	EndIf
	
End Sequence
END TRANSACTION

Return

/*
===============================================================================================================================
Programa----------: AOMS064LW
Autor-------------: Josué Danich Prestes
Data da Criacao---: 24/05/2019
Descrição---------: Liberação de pedido da SZW posicionado
Parametros--------: nopccnf - tipo de liberação, 1 - Normal, 2- Rejeição, - 3 Completa
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS064LW(nopccnf)

nMoeda		:= 1
nValPed		:= AOMS064VTP( SZW->ZW_IDPED , SZW->ZW_FILIAL ,, 3) 

If nOpcCnf == 1 .Or. nOpcCnf == 3
	If nOpcCnf == 1 //Normal
		AOMS64GA( SZW->ZW_IDPED , SZW->ZW_FILIAL , "L"     , cObsAva , nValPed,SZW->ZW_VEND1)
	ElseIf	nOpcCnf == 3  //Completa
		AOMS64GA( SZW->ZW_IDPED , SZW->ZW_FILIAL , "C" , cObsAva, nValPed,SZW->ZW_VEND1)
	EndIf

	If !Empty(TMP64->OK2)
		_nValor -= Val(TMP64->VALOR)
		nQtdTit--
		oValor:Refresh()
		oQtda:Refresh()
	EndIf

	TMP64->( DBDelete() )
			
ElseIf nOpcCnf == 2  //Rejeitado 
	
	_npos := SZW->(Recno())
			
	AOMS64GA( SZW->ZW_IDPED , SZW->ZW_FILIAL , "R" , cObsAva, nValPed,SZW->ZW_VEND1 )
			
	//Reposiciona o SZW
	SZW->(DBGoTo(_npos))
	
	//Envia email de liberação
	_cEmail := Posicione("SA3",1,xFilial("SA3")+SZW->ZW_VEND1,"A3_EMAIL") //Email do representante responsável pelo pedido
	_cCC := " "
	cMailcom := " " 
	_cAssunto := "Aviso de rejeição de crédito do pedido " + AllTrim(SZW->ZW_IDPED) 
	_cAssunto += " do cliente " + SZW->ZW_CLIENTE + "/" + SZW->ZW_LOJACLI + " - " + Posicione("SA1",1,xFilial("SA1")+SZW->ZW_CLIENTE+SZW->ZW_LOJACLI,"A1_NREDUZ")
			
	AOMS064D(,_cEmail,_cCC,_cAssunto,,cMailcom)
			
	TMP64->MOTIVO := "Rejeitado"
	TMP64->BLCRE	:= "R"

	If !Empty(TMP64->OK2)
		_nValor -= Val(TMP64->VALOR)
		nQtdTit--
		oValor:Refresh()
		oQtda:Refresh()
	EndIf

	TMP64->(DBDelete())
EndIf

Return

/*
===============================================================================================================================
Programa----------: AOMS064V5
Autor-------------: Josué Danich Prestes
Data da Criacao---: 24/05/2019
Descrição---------: Visualização de pedido protheus
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS064V5()

Local _cfil := cfilant

//Posiciona SC5 e SC6
SC5->(DBSetOrder(1))
SC6->(DBSetOrder(1))

If SC5->(DBSeek(SubStr(TMPVS->FILIAL,1,2)+TMPVS->NUMPED)) .And. SC6->(DBSeek(SubStr(TMPVS->FILIAL,1,2)+TMPVS->NUMPED))
	//Abre tela de visualização
	cfilant := SubStr(TMPVS->FILIAL,1,2)
	Mata410(Nil, Nil, Nil, Nil, "A410Visual")
Else
	U_ITMsg("Falha em localizar o pedido","Atenção",,1)
EndIf

cfilant := _cfil

Return

/*
===============================================================================================================================
Programa----------: AOMS064VY
Autor-------------: Josué Danich Prestes
Data da Criacao---: 17/02/2016
Descrição---------: Seleção de pedido para visualização
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS064VY()

Local oDLGvp

FWMsgRun( ,{|oproc| AOMS064P2() }				, 'Aguarde!' , 'Verificando os dados...'  )

@ 010,010 To 600,1400 DIALOG oDLGvp TITLE "Seleção de pedido para visualização"

/*oMarkv:=*/MsSelect():New("TMPVS",   ,    ,_aCpoBrw ,  ,  , {001,001 ,270,660},,,,,_aCores)

If _nSelOrigem == 1
	@ 280,500 Button "Visualizar" Size 40,13	Action  FWMsgRun(,{|| AOMS064V5()}, "Aguarde...","Abrindo visualização...") Object oBtnRet
Else
	@ 280,500 Button "Visualizar" Size 40,13	Action  FWMsgRun(,{|| AOMS064VP()}, "Aguarde...","Abrindo visualização...") Object oBtnRet
EndIf

@ 280,570 Button "Sair"	 Size 40,13	Action  oDlGVp:End()  	Object oBtnRet

ACTIVATE DIALOG oDlGVp CENTERED

Return

/*
===============================================================================================================================
Programa----------: AOMS064P2
Autor-------------: Josué Danich Prestes
Data da Criacao---: 08/04/2016
Descrição---------: Monta dados para tela de seleção de pedidos para visualização.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS064P2()

Local cQuery := "" As Char
Local cAliasTRB := GetNextAlias() As Char
//==========================================
// Monta Query 
//==========================================
If _nSelOrigem == 1
	
	cQuery := " SELECT 	C5_FILIAL FILIAL,"
	cQuery += " 			C5_CLIENTE CODCLI,"
	cQuery += " 			C5_LOJACLI LOJA,"
	cQuery += " 			C5_I_NOME NOME,"
	cQuery += " 			C5_EMISSAO EMISSAO,"
	cQuery += " 			C5_I_DTENT ENTREGA,"
	cQuery += " 			C5_I_DTAVA DTAVA,"
	cQuery += " 			C5_I_HRAVA HRAVA,"
	cQuery += " 			C5_I_USRAV USRAVA,"
	cQuery += " 			C5_NUM NUMPED,"
	cQuery += " 			C5_I_OPER OPER,"
	cquery += "          (SELECT SUM(C6_VALOR) FROM " + RETSQLNAME("SC6") + " SC6 "
	cquery += "          			WHERE D_E_L_E_T_ = ' ' AND SC6.C6_FILIAL = SC5.C5_FILIAL AND SC6.C6_NUM = SC5.C5_NUM) VALOR,"
	cQuery += " 			C5_I_MOTBL MOTBL,"
	cQuery += " 			C5_I_BLCRE BLCRE,"
	cQuery += " 			C5_I_ENVML ENVMAIL"
	
	cQuery += " FROM " + RETSQLNAME("SC5") +  " SC5 "

	cQuery += " WHERE " + IIf (_nmvpar02 == 1,"C5_I_BLCRE = 'R' ", IIf(_nmvpar02 == 2,"C5_I_BLCRE = 'B'", "(C5_I_BLCRE = 'R' OR C5_I_BLCRE = 'B')"))
			
	cQuery += " AND C5_CLIENTE = '" + AllTrim(SubStr(TMP64->CODCLI,1,6)) + "' "
	
	cQuery += " 			AND D_E_L_E_T_ = ' '
	
	cQuery += " ORDER BY C5_FILIAL,C5_NUM
	
Else
	
		If _nmvpar02 == 1 //Rejeitados
	
		_cFiltro := "ZW_BLQLCR = 'R' AND ZW_ITEM = '1'   AND SZW.ZW_STATUS IN ('L','P','D','B','E','Q','C') " 
		
	ElseIf _nmvpar02 == 2 //Bloqueados
	
		_cFiltro := "(ZW_BLQLCR = 'B' OR ZW_BLQLCR = 'Z') AND ZW_ITEM = '1'   AND SZW.ZW_STATUS IN ('L','P','D','B','E','Q','C') " 
				
	Else//Todos
	
		_cFiltro := "(ZW_BLQLCR = 'B' OR ZW_BLQLCR = 'R' OR ZW_BLQLCR = 'Z') AND ZW_ITEM = '1' AND SZW.ZW_STATUS IN ('L','P','D','B','E','Q','C') "
		
	EndIf
	
	cQuery := " SELECT 	ZW_FILIAL FILIAL,"
	cQuery += " 		ZW_CLIENTE CODCLI,"
	cQuery += " 		ZW_LOJACLI LOJA,"
	cQuery += " 		ZW_EMISSAO EMISSAO,"
	cQuery += " 		ZW_FECENT ENTREGA,"
	cQuery += " 		ZW_DTAVAC DTAVA,"
	cQuery += " 		ZW_HRAVAC HRAVA,"
	cQuery += " 		ZW_USRAVAC USRAVA,"
	cQuery += " 		ZW_IDPED NUMPED,"
	cQuery += " 		ZW_I_MOTBL MOTBL,"
	cQuery += " 		ZW_TIPO OPER,"
	cQuery += " 		ZW_BLQLCR BLCRE,"
	cQuery += " 		R_E_C_N_O_ RECSZW,"
	cQuery += " 		ZW_ENVMAIL ENVMAIL"  
	
	cQuery += " FROM " + RETSQLNAME("SZW") +  " SZW "
	cQuery += " WHERE " + _cFiltro
		
	cQuery += " AND ZW_CLIENTE = '" + AllTrim(SubStr(TMP64->CODCLI,1,6)) + "' "		
	cQuery += " 			AND D_E_L_E_T_ = ' '
	cQuery += " ORDER BY ZW_FILIAL,ZW_IDPED
		
		
EndIf

cQuery := ChangeQuery(cQuery)

//==========================================
// Fecha Alias se estiver em Uso 
//==========================================
If Select(cAliasTRB) >0

	DBSelectArea(cAliasTRB)
	(cAliasTRB)->( DBCloseArea() )

EndIf

If Select("TMPVS") >0

	DBSelectArea("TMPVS")
	TMPVS->( DBCloseArea() )

EndIf


//==========================================
// Monta Area de Trabalho executando a Query 
//==========================================
MPSysOpenQuery( cQuery,cAliasTRB )
DBSelectArea(cAliasTRB)

(cAliasTRB)->( DBGoTop() )

//==========================================
// Monta arquivo temporario 
//==========================================

_aCpoTMPVS:={}
aAdd(_aCpoTMPVS,{"OK"			,"C",001,0})
aAdd(_aCpoTMPVS,{"OK2"			,"C",002,0})
aAdd(_aCpoTMPVS,{"FILIAL"		,"C",020,0})
If _nSelOrigem == 1
   aAdd(_aCpoTMPVS,{"NUMPED"	,"C",006,0})
Else
   aAdd(_aCpoTMPVS,{"NUMPED"	,"C",Len(SZW->ZW_IDPED),0})
EndIf
aAdd(_aCpoTMPVS,{"CODCLI"		,"C",020,0})
aAdd(_aCpoTMPVS,{"NOME"			,"C",050,0})
aAdd(_aCpoTMPVS,{"VALOR"		,"C",020,0})
aAdd(_aCpoTMPVS,{"DATAPED"		,"C",010,0})
aAdd(_aCpoTMPVS,{"DATAENT"		,"C",010,0})
aAdd(_aCpoTMPVS,{"DTAVAL"	 	,"C",010,0})
aAdd(_aCpoTMPVS,{"HRAVAL"      	,"C",010,0})
aAdd(_aCpoTMPVS,{"BLCRE"      	,"C",001,0})
aAdd(_aCpoTMPVS,{"MOTIVO"      	,"C",050,0})
aAdd(_aCpoTMPVS,{"RECSZW"      	,"N",010,0})
aAdd(_aCpoTMPVS,{"ORDEMDTE"    	,"N",010,0})
aAdd(_aCpoTMPVS,{"ENVMAIL"    	,"C",001,0}) 
aAdd(_aCpoTMPVS,{"OPER"    	    ,"C",003,0}) 

_oTemp:=FWTemporaryTable():New( "TMPVS", _aCpoTMPVS )
_oTemp:AddIndex( "01", {"NUMPED"} )
_oTemp:AddIndex( "02", {"CODCLI"} )
_oTemp:AddIndex( "03", {"ORDEMDTE"} )
_oTemp:Create()

//==========================================
// Alimenta arquivo temporario 
//==========================================
DBSelectArea("TMPVS")

While !(cAliasTRB)->(Eof())

	RecLock("TMPVS",.T.)
	TMPVS->OK			:= ""
	TMPVS->OK2			:= "  "
	TMPVS->FILIAL 	:= (cAliasTRB)->FILIAL + " - " + AllTrim(FWFilialName(cEmpAnt,(cAliasTRB)->FILIAL))
	TMPVS->NUMPED 	:= (cAliasTRB)->NUMPED
	TMPVS->CODCLI 	:= AllTrim((cAliasTRB)->CODCLI) + "/" + AllTrim((cAliasTRB)->LOJA)
	TMPVS->OPER 	:= (cAliasTRB)->OPER

	If _nSelOrigem == 1
	   TMPVS->NOME	:= (cAliasTRB)->NOME
	   TMPVS->VALOR	:= Space(20 - Len(AllTrim(TRANSFORM((cAliasTRB)->VALOR,"@E 999,999,999.99")) ))  + AllTrim(TRANSFORM((cAliasTRB)->VALOR,"@E 999,999,999.99"))
	Else
	   TMPVS->NOME	:= Posicione("SA1",1,xFilial("SA1")+(cAliasTRB)->CODCLI+(cAliasTRB)->LOJA,"A1_NOME")
	   nValor:=AOMS064VTP( TMPVS->NUMPED , SubStr(TMPVS->FILIAL,1,2) ,, 1 )
	   TMPVS->VALOR	:= Space(20 - Len(AllTrim(TRANSFORM(nValor,"@E 999,999,999.99")) ))  + AllTrim(TRANSFORM(nValor,"@E 999,999,999.99"))
	   TMPVS->RECSZW  := (cAliasTRB)->RECSZW
	EndIf
	
	TMPVS->DATAPED	:= DToC(SToD((cAliasTRB)->EMISSAO))
	TMPVS->ORDEMDTE := SToD((cAliasTRB)->EMISSAO) - CTOD("01/01/2000")//campo para indexar a data de emissao ao contrario
	TMPVS->DATAENT	:= DToC(SToD((cAliasTRB)->ENTREGA))
	TMPVS->DTAVAL		:= DToC(SToD((cAliasTRB)->DTAVA))
	TMPVS->HRAVAL		:= (cAliasTRB)->HRAVA
	TMPVS->BLCRE		:= (cAliasTRB)->BLCRE
	TMPVS->MOTIVO		:= (cAliasTRB)->MOTBL 
	TMPVS->ENVMAIL		:= (cAliasTRB)->ENVMAIL 
		
	TMPVS->(MSUnLock())
	
	(cAliasTRB)->( DBSkip() )
	
End

(cAliasTRB)->(DBCloseArea())
TMPVS->(DBGoTop())
_aCores2:={}
bped2 := {||.T.}
bped2 := {|| AOMS064U()} //Função que carrega váriavel com cores da legenda
aAdd(_aCores2,{'Eval(bped2)==""' ,"BR_VERDE"})
aAdd(_aCores2,{'Eval(bped2)=="1"',"BR_VERMELHO"})
aAdd(_aCores2,{'Eval(bped2)=="2"',"BR_CINZA"})
aAdd(_aCores2,{'Eval(bped2)=="3"',"BR_AMARELO"})
aAdd(_aCores2,{'Eval(bped2)=="4"',"BR_AZUL"})

Return

/*
===============================================================================================================================
Programa----------: AOMS064U
Autor-------------: Erich Buttner
Data da Criacao---: 18/03/2013
Descrição---------: Funcao que avalia os Pedido de Venda para classifica-lo corretamente na legenda.
Parametros--------: Nenhum 
Retorno-----------: _cRet = Codigo referente a classificação para a legenda.
===============================================================================================================================
*/
Static Function AOMS064U()

Local _cRet := ""
Local _aArea  := FWGetArea()

Begin Sequence
   If TMPVS->( Eof() )
	  Break
   EndIf

   If TMPVS->ENVMAIL == "S" 
	  _cRet := "4" 
   ElseIf TMPVS->BLCRE == 'B'
	  _cRet := "1"
   ElseIf TMPVS->BLCRE == 'L'
	  _cRet := ""
   ElseIf TMPVS->BLCRE== 'R'
	  _cRet := "2"
   ElseIf TMPVS->BLCRE== 'Z'
	  _cRet := "3"
   EndIf

End Sequence

FWRestArea(_aArea)

Return(_cRet)
