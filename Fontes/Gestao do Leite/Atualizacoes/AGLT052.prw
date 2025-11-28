/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |26/12/2019| Chamado 31528. Correção do erro da deleção da linha/A totvs esta forçando 1 parametro nSource no oGet:CDELOK
Lucas Borges  |21/05/2021| Chamado 36589. Retirada a gravação de campos nunca utilizados.
Lucas Borges  |08/10/2024| Chamado 48465. Retirada manipulação do SX1
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: AGLT052
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 15/09/2008
Descrição---------: Rotina para possibilitar o cadastro da Recepção do Leite Cooperativas - Terceiros
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT052()

Local _cFilter		:= ""

Private cCadastro	:= "Recepção de Leite - Terceiros"
Private aRotina		:= MenuDef()
Private cAlias		:= "ZLW"

Private lMsErroAuto := .F.
Private nSalvRec 	:= 0
Private bVisual 	:= {|| AGLT052U('ZLW',Recno(),2)  }
Private bInclui 	:= {|| AGLT052U('ZLW',Recno(),3)  }
Private bAltera 	:= {|| AGLT052U('ZLW',Recno(),4)  }
Private bExclui 	:= {|| AGLT052U('ZLW',Recno(),5)  }
Private bLegenda	:= {|| AGLT052P()  }
Private aCores		:= {{ 'ZLW->ZLW_STATUS==" "'	, 'BR_VERDE'		} ,;
						 { 'ZLW->ZLW_STATUS=="F"'	, 'BR_VERMELHO'		}  }

//=====================================================================================
//Obtem Setores que podem ser acessados - 114 - "MBrowse - Visualiza outras filiais"
//Se o usuário visualiza toda as filiais no browse, filtro todos os setores. Do contra-
//ário, filtro só a filial corrente
//=====================================================================================
If Posicione("ZLU",1,xFilial("ZLU")+RetCodUsr(),"ZLU_SETALL") <> 'S'
	_cFilter :="ZLW_SETOR IN "+FormatIn(U_LisSetor(IIf(SubStr(cAcesso,114,1)=='S',.F.,.T.)),";")
EndIf

ZLW->(DBSetOrder(3))
MBrowse(,,,,cAlias,,,,,,aCores,,,,,,,,_cFilter)

DBSelectArea("ZLW")
DBGoTo(nSalvRec)

Return

/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 28/09/2018
Descrição---------: Utilizacao de Menu Funcional
Parametros--------: aRotina
					1. Nome a aparecer no cabecalho
					2. Nome da Rotina associada
					3. Reservado
					4. Tipo de Transa‡„o a ser efetuada:
						1 - Pesquisa e Posiciona em um Banco de Dados
						2 - Simplesmente Mostra os Campos
						3 - Inclui registros no Bancos de Dados
						4 - Altera o registro corrente
						5 - Remove o registro corrente do Banco de Dados
						6 - Altera determinados campos sem incluir novos Regs
					5. Nivel de acesso
					6. Habilita Menu Funcional
Retorno-----------: Array com opcoes da rotina
===============================================================================================================================
*/
Static Function MenuDef()

Local aRotina := {	{ "Pesquisar"		, "AxPesqui" 			, 0 , 1 } ,;
					{ "Visualizar"		, "Eval(bVisual)" 		, 0 , 2 } ,;
					{ "Incluir"			, "Eval(bInclui)" 		, 0 , 3 } ,;
					{ "Alterar"			, "Eval(bAltera)" 		, 0 , 4 } ,;
					{ "Excluir"			, "Eval(bExclui)"		, 0 , 5 } ,;
					{ "Legenda"			, "Eval(bLegenda)"		, 0 , 2 }  }

Return( aRotina )

/*
===============================================================================================================================
Programa----------: AGLT052U
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 15/09/2008
Descrição---------: Funcao usada para dar manutencao - Inclusao/Alteracao/Exclusao da tabela ZLW - Recepcao de Leite terceiros.
Parametros--------: cAlias: Tebela , nReg: Registro , nOpc: Opção
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT052U( cAlias , nReg , nOpc )

Local _cTitulo		:= "RECEPÇÃO DE LEITE - TERCEIROS"
Local _aObjects 	:= {}
Local _aPosObj		:= {}
Local _aSize		:= MsAdvSize()
Local _aInfo		:= { _aSize[1] , _aSize[2] , _aSize[3] , _aSize[4] , 3 , 3 }
Local _aNoFields	:= {"ZLW_TICKET","ZLW_DTLANC","ZLW_SETOR","ZLW_LINROT","ZLW_FRETIS","ZLW_LJFRET","ZLW_VEICUL","ZLW_MOTOR","ZLW_KM","ZLW_CODREC","ZLW_TOTBOM","ZLW_DTCOLE"}//campos que não devem ir para o grid pois estão no cabeçalho
Local _aYesFields	:= {"ZLW_RETIRO","ZLW_RETILJ","ZLW_DCRRET","ZLW_QTDBOM","ZLD_TQ_LT"} //Lista todos os campos para o grid de inclusão

Private oDlg		:= Nil
Private cUser		:= CriaVar("ZLW_USER")
Private oLteBom		:= Nil
Private oSetor		:= Nil
Private oLinRota	:= Nil
Private nDif		:= 0
Private cCodRec 	:= If(nOpc==3,Space(TamSX3("ZLW_CODREC")[1]),ZLW->ZLW_CODREC) //Codigo Recebimento
Private cTicket		:= If(nOpc==3,Space(Len(ZLW->ZLW_TICKET)),ZLW->ZLW_TICKET) //Codigo Entrada
Private dData		:= If(nOpc==3,date(),ZLW->ZLW_DTLANC) //Data Entrada
Private cSetor		:= If(nOpc==3,criaVar("ZLW_SETOR"),ZLW->ZLW_SETOR)  //Space(TamSX3("ZLW_SETOR")[1])
Private cDescSet	:= If(nOpc==3,Space(20),SubStr(Posicione("ZL2",1,xFilial("ZL2")+cSetor,"ZL2_DESCRI"),1,20))
Private cLinRot		:= If(nOpc==3,Criavar("ZLW_LINROT"),ZLW->ZLW_LINROT)  //Space(TamSX3("ZLW_LINROT")[1])
Private cDescLin	:= If(nOpc==3,Space(TamSX3("ZL3_DESCRI")[1]-20),LEFT(Posicione("ZL3",1,xFilial("ZL3")+cLinRot,"ZL3_DESCRI"),20))
Private cFretist	:= If(nOpc==3,Space(TamSX3("ZLW_FRETIS")[1]),ZLW->ZLW_FRETIS)
Private cLjFret		:= If(nOpc==3,Space(TamSX3("ZLW_LJFRET")[1]),ZLW->ZLW_LJFRET)
Private cDescFret	:= If(nOpc==3,Space(TamSX3("A2_NOME")[1]-4),SubStr(Posicione("SA2",1,xFilial("SA2")+cFretist+cLjFret,"A2_NOME"),1,TamSX3("A2_NOME")[1]-4))
Private cVeicul		:= If(nOpc==3,Space(TamSX3("ZLW_VEICUL")[1]),ZLW->ZLW_VEICUL)
Private cMotor		:= If(nOpc==3,Space(TamSX3("ZLW_MOTOR")[1]),ZLW->ZLW_MOTOR)
Private cDescMot	:= If(nOpc==3,Space(TamSX3("ZL0_NOME")[1]-20),LEFT(Posicione("ZL0",1,xFilial("ZL0")+cMotor,"ZL0_NOME"),20))
Private cPlacaVeic	:= If(nOpc==3,Space(TamSX3("ZL1_PLACA")[1]),Posicione("ZL1",1,xFilial("ZL1")+ZLW->ZLW_VEICUL,"ZL1_PLACA"))
Private nTotKM		:= If(nOpc==3,0,ZLW->ZLW_KM)                                                
Private _cCodRecep  := If(nOpc==3,Space(TamSX3("ZLW_CODIGO")[1]),ZLW->ZLW_CODIGO)                                                
Private _oCodRecep	:= Nil
Private nLeiteBom 	:= 0
Private dDtcoleta	:= If(nOpc==3,dDatabase,ZLW->ZLW_DTCOLE) //Data DA COLETA
Private nTotBom		:= If(nOpc==3,0,ZLW->ZLW_TOTBOM)
Private nLtDif 		:= 0
Private bVldLin		:= {|| AGLT052L(.F.)}
Private bVldTela	:= {|| AGLT052T()	 }
Private lConfirmou 	:= .F.
Private nPosRetiro 	:= 0
Private nPosLoja 	:= 0
Private nPosQtdBom 	:= 0
Private nPosNomRet 	:= 0
Private nPosTqLt 	:= 0
Private cSeek	    := xFilial("ZLW")+ZLW->ZLW_CODREC
Private bSeekFor	:= {|| ZLW->ZLW_CODREC == cCodRec  }
Private bSeekWhile	:= {|| ZLW->ZLW_FILIAL + ZLW->ZLW_CODREC } //Condicao While para montar o aCols
Private aColsAux 	:= {} //Armazena aCols para Controle de Alteracao/Exclusao
Private nVolAnt		:= IIf( nOpc == 3 , 0 , AGLT052W( cCodRec , cTicket , cSetor ) ) // Volume do ticket lancado (anteriores)
Private lAbleTicket	:= .T.
Private nTotCodRec	:= 0
Private oTotCodRec	:= Nil

//================================================================================
// Validação - o ticket nao pode sofrer alterações caso ja tenha sido fechado
//================================================================================
If nOpc == 4 .Or. nOpc == 5
	If ZLW->ZLW_STATUS == "F"
		MsgStop("Ticket não pode ser alterado/excluído por já estar fechado! Esse Ticket somente pode ser alterado/excluído se o Fechamento do Leite For cancelado.","AGLT05201")
		Return
	EndIf

    If nOpc == 5 .And. !Empty(ZLW->ZLW_ATENDI)
		MsgStop("Ticket não pode ser excluído por ser integrado do SmartQuestion! Tickets somente podem ser excluídos se a inclusão For manual.","AGLT05202")
		Return
	EndIf
EndIf

aButtons := IIf( Type("aButtons") == "U" , {} , aButtons )

//================================================================================
// Esta rotina de inclusao dos produtores de um outro ticket em um ticket que esta
// sendo incluido no momento somente podera ser realizada nas unidades de JARU e 
// quando a opcao For de inclusao.
//================================================================================
If SubStr( cFilAnt , 1 , 1 ) == '1' .And. nOpc == 3
	aAdd( aButtons , { "RESPONSA" , {|| MsgRun( "Aguarde...Selecionando Produtores..." ,, {|| CursorWait() , AGLT052Z() , CursorArrow() } ) } , "Inserir Produtores de um ticket..." , "Produtores" } )
EndIf

//================================================================================
// Monta a entrada de dados do arquivo
//================================================================================
cSeek := xFilial("ZLW")+cCodRec

//================================================================================
// Monta aHeader e aCols utilizando a funcao FillGetDados
//================================================================================
Private aHeader[0]
Private aCols[0]

//================================================================================
// Variaveis privadas para montagem da tela
//================================================================================
SetPrvt("aRotina,CCADASTRO,CALIAS")
SetPrvt("NOPCE,NOPCG,NUSADO")
SetPrvt("_cTitulo,CALIASENCHOICE,CLINOK,CTUDOK,CFIELDOK")
SetPrvt("NREG,NOPC")

//================================================================================
// Inclusao
//================================================================================
If nOpc == 3
	FillGetDados( nOpc , cAlias , 1 ,,,,, _aYesFields ,,,, .T. )

//================================================================================
// Alteracao,Visualizacao,Exclusao
//================================================================================
Else
	FillGetDados( nOpc , cAlias , 1 , cSeek , bSeekWhile , bSeekFor , _aNoFields )
EndIf

aAdd( _aObjects , { 100 , 055 , .T. , .F. , .T. })
aAdd( _aObjects , { 100 , 100 , .T. , .T.       })
aAdd( _aObjects , { 100 , 002 , .T. , .F.       })

//================================================================================
// Obtem posicao dos campos no cabecalho os itens
//================================================================================
nPosRetiro		:= aScan( aHeader , {|x| AllTrim(x[2]) == "ZLW_RETIRO"	} )
nPosLoja		:= aScan( aHeader , {|x| AllTrim(x[2]) == "ZLW_RETILJ"	} )
nPosQtdBom 		:= aScan( aHeader , {|x| AllTrim(x[2]) == "ZLW_QTDBOM"	} )
nPosTqLt 		:= aScan( aHeader , {|x| AllTrim(x[2]) == "ZLW_TQ_LT"	} )
nPosNomRet		:= aScan( aHeader , {|x| AllTrim(x[2]) == "ZLW_DCRRET"	} )
nPosAtendi		:= aScan( aHeader , {|x| AllTrim(x[2]) == "ZLW_ATENDI" 	} )

_aPosObj := MsObjSize( _aInfo , _aObjects )

nLeiteBom	:= nVolAnt + U_AGLT052S()
nTotCodRec	:= U_AGLT052S()
nLtDif		:= nTotBom - nLeiteBom
_lacols := Type( "aCols" ) <> "U"

While .T.
	//================================================================================
	// Tela do model 2 - Rececpcao de Leite
	//================================================================================
	DEFINE MSDIALOG oDlg TITLE _cTitulo OF oMainWnd PIXEL FROM _aSize[7],0 TO _aSize[6],_aSize[5]
	
    oPanel := TPanel():New(0,0,'',oDlg,,.F.,.F.,,,300,100,.T.,.T. )
	
	@ 1.3 , 0.3 TO 2.3 , 43.0 OF oPanel
	@ 5.9 , 0.3 TO 7.0 , 43.0 OF oPanel
	
	@ 1.6 , 00.7 Say	"Data Coleta" OF oPanel
	@ 1.5 , 04.7 MSGET	dDtColeta		Valid CheckSX3("ZLW_DTLANC") WHEN (nOpc==3) OF oPanel
	@ 1.6 , 12.2 Say	"Data Lanc." OF oPanel
	@ 1.5 , 16.0 MSGET	dData			Valid CheckSX3("ZLW_DTLANC") WHEN .F. OF oPanel
	
	@ 2.6 , 00.7 Say	"Transport." OF oPanel
	@ 2.5 , 04.7 MSGET	cFretist		Valid CheckSX3("ZLW_FRETIS") .And. IIf( Empty(cFretist)	, .T. , AGLT052C() .And. AGLT052F() ) WHEN ((nOpc==3)) F3 GetSX3Cache("ZLW_FRETIS","X3_F3") OF oPanel
	@ 2.5 , 09.5 MSGET	cLjFret			Valid CheckSX3("ZLW_LJFRET") .And. IIf( Empty(cLjFret)	, .T. , AGLT052C() .And. AGLT052F() ) WHEN ((nOpc==3)) OF oPanel
	@ 2.5 , 12.8 MSGET	cDescFret		WHEN .F. OF oPanel
	
	@ 3.6 , 00.5 Say	"Setor" OF oPanel
	@ 3.5 , 04.7 MSGET	oSetor			VAR cSetor Valid CheckSX3("ZLW_SETOR") .And. Eval({||cDescSet:= Posicione("ZL2",1,xFilial("ZL2")+cSetor,"ZL2_DESCRI"),.T.});
														.And. U_getNwTicket(.T.) WHEN (nOpc==3) F3 GetSX3Cache("ZLW_SETOR","X3_F3") OF oPanel
	@ 3.5 , 09.5 MSGET	cDescSet		WHEN .F. OF oPanel
	
	@ 4.6 , 00.7 Say	"Linha/Rota" OF oPanel
	@ 4.5 , 04.7 MSGET	oLinRota		VAR cLinRot  Valid CheckSX3("ZLW_LINROT") .And. IIf(Empty(cLinRot),.T., AGLT052N(cLinRot,nOpc)) WHEN (nOpc==3) F3 GetSX3Cache("ZLW_LINROT","X3_F3") OF oPanel
	@ 4.5 , 09.5 MSGET	cDescLin		WHEN .F. OF oPanel
	
	@ 4.6 , 25.5 Say	"Cod.Recep." OF oPanel
	@ 4.5 , 29.3 MSGET	_oCodRecep		VAR _cCodRecep Valid (IIf(Len(AllTrim(_cCodRecep)) == 0,.T.,AGLT052G())) WHEN (nOpc==3.Or.nOpc==4)  OF oPanel
	
	@ 5.6 , 00.7 Say	"Motorista" OF oPanel
	@ 5.5 , 04.7 MSGET	cMotor			Valid CheckSX3("ZLW_MOTOR") .And. IIf(Empty(cMotor),.T., AGLT052M(cMotor) ) WHEN (nOpc==3.Or.nOpc==4) F3 GetSX3Cache("ZLW_MOTOR","X3_F3") OF oPanel
	@ 5.5 , 09.5 MSGET	cDescMot		WHEN .F. OF oPanel
	
	@ 5.6 , 26.7 Say	"Veiculo" OF oPanel
	@ 5.5 , 29.2 MSGET	cVeicul		Picture GetSX3Cache("ZLW_VEICUL","X3_PICTURE") Valid CheckSX3("ZLW_VEICUL") .And. IIf(Empty(cVeicul),Eval({||cPlacaVeic:="" ,.T.}), Eval({||cPlacaVeic:= Posicione("ZL1",1,xFilial("ZL1")+cVeicul,"ZL1_PLACA"),.T.}));
									WHEN (nOpc==3.Or.nOpc==4)  F3 GetSX3Cache("ZLW_VEICUL","X3_F3") OF oPanel
	@ 5.5 , 34.2 MSGET	cPlacaVeic	WHEN .F. OF oPanel

	DEFINE FONT oFont1 NAME "Tahoma" BOLD
	
	@ 6.6 , 00.7 Say	"Ticket"			FONT oFont1 OF oPanel
	@ 6.5 , 04.7 MSGET	cTicket							Valid CheckSX3("ZLW_TICKET") .And. !AGLT052B(cTicket) WHEN (nOpc==3) FONT oFont1 SIZE 50,7 OF oPanel
	@ 6.5 , 12.0 Say	"Vol. Veiculo" OF oPanel
	@ 6.5 , 15.7 MSGET	nTotBom							Picture "@E 999,999,999" WHEN ((nOpc==3).and.lAbleTicket) SIZE 50,7 OF oPanel
	
	@ 6.5 , 22.6 Say	"Vol. Coletado" OF oPanel
	@ 6.5 , 27.1 MSGET	oLteBom			var nLeiteBom	Picture GetSX3Cache("ZLW_QTDBOM","X3_PICTURE")  WHEN .F. SIZE 50,7 OF oPanel
	@ 6.5 , 33.5 Say	"Diferenca" OF oPanel
	@ 6.5 , 36.8 MSGET	nDif			var nLtDif		Picture GetSX3Cache("ZLW_TOTBOM","X3_PICTURE")  WHEN .F.  SIZE 50,7 OF oPanel
	
	_lDeleta:=((nOpc == 3) .Or. (nOpc == 4))
	_nLINHAS:=999
	If nOpc = 4 .And. !Empty(ZLW->ZLW_ATENDI)
		_lDeleta:=.F.
		_nLINHAS:=Len(aCols)
	EndIf
	//         MsGetDados(): New( < nTop>        , < nLeft>    , < nBottom>     , < nRight>,< nOpc>,[ cLinhaOk]    , [ cTudoOk],[ cIniCpos],[ lDeleta],[ aAlter], [ nFreeze], [ lEmpty], [ nMax], [ cFieldOk], [ cSuperDel], [ uPar], [ cDelOk], [ oWnd], [ lUseFreeze], [ cTela] )
	oGet := MSGetDados():New(_aPosObj[2,1]+40,_aPosObj[2,2],_aPosObj[2,3]-10,_aPosObj[2,4],nOpc,"Eval(bVldLin)","Eval(bVldTela)",""    ,_lDeleta   ,NIL      ,NIL        ,NIL       ,_nLINHAS,            ,             ,        ,"U_AGLT052L",        ,              ,         )
	
	//================================================================================
	// RODAPE DA TELA
	//================================================================================
    oPanelRoda := TPanel():New(_aPosObj[2,3],0,'',oDlg,, .F., .F.,,,300,20,.F.,.F. )
	@ 4,005 Say		"Total de Volume do Lancamento:"  Pixel of oPanelRoda
	@ 2,090 MSGET	oTotCodRec var nTotCodRec Picture GetSX3Cache("ZLW_TOTBOM","X3_PICTURE")  WHEN .F. Pixel of oPanelRoda
	
	If _lacols
		aColsAux := aClone( aCols )
	EndIf
	
	ACTIVATE MSDIALOG oDlg ON INIT (EnchoiceBar(oDlg,{|| lConfirmou := AGLT052T(nOpc) ,If(lConfirmou,oDlg:End(),)},{||oDlg:End()},,aButtons),;
	                                oPanel:Align:=CONTROL_ALIGN_TOP,oPanelRoda:Align:=CONTROL_ALIGN_BOTTOM,;
	                                oGet:oBrowse:Align:=CONTROL_ALIGN_ALLCLIENT,oGet:oBrowse:Refresh())
	
	//================================================================================
	// Grava dados da ZLW
	//================================================================================
	If lConfirmou
		
		DBSelectArea("ZLW")
		
		Begin Transaction
		
		If nOpc == 3
			AGLT052I(aCols)
		ElseIf nOpc == 4
			//================================================================================
			// Apaga Itens Anteriores sem Apagar estoque
			//================================================================================
			AGLT052D(aColsAux,.F.)
			//================================================================================
			// Grava Novos Itens
			//================================================================================
			AGLT052I(aCols)
		ElseIf nOpc == 5
			//================================================================================
			// Apaga Itens
			//================================================================================
			AGLT052D(aColsAux,.T.)
		EndIf
		
		ConfirmSx8()
		
		End Transaction
		
	Else
		If (nOpc == 3 .Or. nOpc == 4) .And. !MsgYesNo("Confirma saída sem salvar?","AGLT05203")
			Loop
		EndIf
	EndIf
    Exit
EndDo

Return

/*
===============================================================================================================================
Programa----------: AGLT052L
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 15/09/2008
Descrição---------: Funcao usada para validar linha da getDados na tela de Recepcao de leite
Parametros--------: lDel: .T. OU .F.
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT052L(nSource)//A totvs resolveu forçar um parametros deles U_AGLT052L(nSource) no oGet:CDELOK
Return AGLT052L(.T.)
Static Function AGLT052L(lApaga)

Local _lRet		:= .T.
Local aAux		:= aCols[n] //Pega Linha Atual
Local aAux1		:= {}
Local nIndex	:= 0
Local _nX		:= 0

If lApaga
   If Altera .And. !Empty(ZLW->ZLW_ATENDI)
	  MsgStop("Atendimento nao pode ser excluido por ser integrado do SmartQuestion! Esse Atendimento somente pode ser excluido se a inclusao For manual.","AGLT05204")
	  Return .F.		
    EndIf
	Return .T.		
EndIf
//================================================================================
// Atualiza Variaveis de Totais
//================================================================================
nLeiteBom	:= nVolAnt + U_AGLT052S()
nTotCodRec	:= U_AGLT052S()
nLtDif		:= nTotBom - nLeiteBom

oLteBom:Refresh()  

If ValType(nDif) == 'O'
	nDif:Refresh()        
EndIf

oTotCodRec:Refresh()
oDlg:Refresh()

//================================================================================
// Verifica se a linha foi excluida
//================================================================================
If aTail( aCols[n] )
	Return( .T. )
EndIf

If Len(aCols) > 1 .And. !(Altera .And. !Empty(ZLW->ZLW_ATENDI))
	For _nX := 1 To Len(aCols)
		If _nX != n .And. !aTail( aCols[_nX] )
			aAdd( aAux1 , aCols[_nX] )
		EndIf
	Next _nX
	
	nIndex	:= aScan(aAux1,{|x| x[nPosRetiro] == aAux[nPosRetiro] .And. x[nPosLoja] == aAux[nPosLoja] })
	_lRet	:= nIndex == 0
	
	If !_lRet
		MsgStop("Produtor já incluído neste recebimento. Não pode haver dois produtores na mesma coleta! Lance todos os volumes num só Produtor!","AGLT05205")
		Return _lRet
	EndIf
	
EndIf

//================================================================================
// Verifica se o retiro esta dentro da linha informada
//================================================================================
If !aTail( aCols[n] )
	
	If !Empty( aAux[nPosRetiro] ) .And. !Empty( aAux[nPosLoja] )
	
		cLinhaRota	:= Posicione("SA2",1,xFilial("SA2")+aAux[nPosRetiro]+aAux[nPosLoja],"A2_L_LI_RO")
		
		If SA2->A2_MSBLQL == '1' .Or. SA2->A2_L_ATIVO == 'N'
			MsgStop('O produtor ['+ aAux[nPosRetiro] +'/'+ aAux[nPosLoja] +'] não está ativo no cadastro de Fornecedores! '+;
				   'Verifique o cadastro ou informe outro código de produtor.',"AGLT05206")
			_lRet := .F.
			Return( _lRet )
		EndIf
		
		If _lRet .And. cLinhaRota <> cLinRot
			MsgStop("Produtor informado não pertence a linha/rota informada, linha/rota do Produtor: "+cLinhaRota+ ". Selecione um Produtor que seja da linha informada.","AGLT05207")
			_lRet := .F.		
			Return( _lRet )
		EndIf
	
	EndIf
	
	If Len( AllTrim( aAux[nPosRetiro] ) ) > 0 .And. aAux[nPosQtdBom] == 0 .And. !(Altera .And. !Empty(ZLW->ZLW_ATENDI))
		MsgStop("Ao informar um código de produtor deverá ser fornecida a sua litragem de coleta. Favor informa a litragem do produtor corrente.","AGLT05208")
		Return( .F. )
	EndIf
	
EndIf

Return( _lRet )

/*
===============================================================================================================================
Programa----------: AGLT052T
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 15/09/2008
Descrição---------: Funcao usada para validar todos os dados da tela na confirmação
Parametros--------: nOpcao: Opcao
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT052T( nOpcao )

Local _lRet		:= .T.
Local _lRetLitr	:= .T.
Local _nX		:= 0
Local _nI		:= 0

DBSelectArea("SA2")
SA2->( DBSetOrder(1) )
If SA2->( DBSeek( xFilial("SA2") + cFretist + cLjFret ) )
	If SA2->A2_MSBLQL == '1' .Or. SA2->A2_L_ATIVO == 'N'
		MsgStop("Cadastro do Produtor/Fretista ["+ SA2->A2_COD +"/"+ SA2->A2_LOJA +"] está Bloqueado ou Inativo no cadastro de fornecedores.","AGLT05209")
		_lRet := .F.
	EndIf
	If _lRet
		cDescFret := SA2->A2_NOME
	EndIf
Else
	MsgStop("Código do Produtor/Fretista não foi encontrado no cadastro de fornecedores.","AGLT05210")
	_lRet := .F.
EndIf

//================================================================================
// Valida se nao foi lancado nenhum evento e se o mix nao esta fechado
//================================================================================
If _lRet

	For _nX := 1 To Len(aCols)
	
		If !aTail( aCols[_nX] ) .And. !(Len( aCols ) == 1 .And. Empty( aCols[1][nPosRetiro] ) .And. Empty( aCols[1][nPosQtdBom] ))
			SA2->( DBSetOrder(1) )
			If SA2->( DBSeek( xFilial("SA2") + aCols[_nX][nPosRetiro] + aCols[_nX][nPosLoja] ) )
				If SA2->A2_MSBLQL == '1' .Or. SA2->A2_L_ATIVO == 'N'
					MsgStop("Cadastro do Produtor/Fretista ["+ SA2->A2_COD +"/"+ SA2->A2_LOJA +"] está Bloqueado ou Inativo no cadastro de fornecedores.","AGLT05211")
					_lRet := .F.
					Exit
				Else
					If Len( AllTrim( aCols[_nX][nPosRetiro] ) ) > 0 .And. aCols[_nX][nPosQtdBom] == 0
						_lRetLitr := .F.
						Exit
					EndIf
				EndIf
			Else
				MsgStop("Código do Produtor/Fretista ["+ aCols[_nX][nPosRetiro] +"/"+ aCols[_nX][nPosLoja] +"]não foi encontrado no cadastro de fornecedores.","AGLT05212")
				_lRet := .F.
				Exit
			EndIf
		EndIf
		
	Next _nX
	
EndIf
	
If !_lRetLitr .And. !(Altera .And. !Empty(ZLW->ZLW_ATENDI))
	_lRet := .F.
	MsgStop("Ao informar um código de produtor deverá ser fornecida a sua litragem de coleta. Existe(m) produtor(es) sem litragem informada, favor verificar os registros de dados da recepção.","AGLT05213")
EndIf

If _lRet

	If nOpcao == 5 
		Return( .T. )
	EndIf
	                   
	_lRet := ( AGLT003Q() .And. !Empty(cFretist)  .And. !Empty(cMotor)  .And. !Empty(cLjFret) .And. !Empty(dDtColeta) .And. !Empty(cLinRot) .And. !Empty(cSetor) )
	
	If !_lRet
		If nOpcao == 3 .Or. nOpcao == 4
			MsgStop("Existem campos obrigatórios não preenchidos, ou produtores de linhas/rotas diferentes!"+;
					"Preencha os campos obrigatorios e verifique se nao existe nenhum produtor de outra linha/rota!","AGLT05214")
		Else
			_lRet := .T.
		EndIf
	EndIf
	
	If _lRet .And. !(Altera .And. !Empty(ZLW->ZLW_ATENDI))
	
		//================================================================================
		// Valida a insercao do mesmo produtor/loja na mesma recepcao de leite
		//================================================================================
		For _nX := 1 To Len(aCols)
			If !aTail( aCols[_nX] )
				For _nI := 1 To Len(aCols)
					If !aTail( aCols[_nI] ) .And. _nX <> _nI
						If aCols[_nX][nPosRetiro] == aCols[_nI][nPosRetiro] .And. aCols[_nX][nPosLoja] == aCols[_nI][nPosLoja]
							MsgStop("Produtor já incluído neste recebimento. Na linha: " + AllTrim(Str(_nX,3)) + " e " + AllTrim(Str(_nI,3))	+;
									". Nao pode haver dois produtores na mesma coleta! Lance todos os volumes num só Produtor!","AGLT05215")
							_lRet := .F.
							Return( _lRet )
						EndIf
					EndIf
				Next _nI
			EndIf
		Next _nX
		
	EndIf
	
	//================================================================================
	// Funcao para validar o codigo de recepcao fornecido
	//================================================================================
	If !Empty(_cCodRecep)
		_lRet := AGLT052G()
	EndIf

EndIf

//=============================================
//Chamado 5095 - Não permitir o campo data da | 
//coleta maior que a database. LUCASC         |
//=============================================
If _lRet .And. dDtcoleta > dDataBase
	_lRet := .F.
	MSgStop("A Data de Coleta informada, é maior que "+DToC(dDataBase)+". Verificar o conteúdo informado na Data de Coleta.","AGLT05216")
EndIf

Return( _lRet )

/*
===============================================================================================================================
Programa----------: AGLT052N
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 15/09/2008
Descrição---------: Funcao usada para validar linha rota digitado na tela de Recepcao de leite
Parametros--------: cLinRot: cosigo da rota , nOpcao: opcao
Retorno-----------: lRet
===============================================================================================================================
*/
Static Function AGLT052N( cLinRot , nOpcao )

Local _lRet	:= .T.
Local _aArea	:= FWGetArea()

If !Empty( cLinRot )
	DBSelectArea("ZL3")
	ZL3->( DBSetOrder(1) )
	If ZL3->( DBSeek( xFilial("ZL3") + cLinRot ) )
		If nOpcao==3
			cVeicul		:= ZL3->ZL3_VEICUL
			If !Empty( cVeicul )
				DBSelectArea("ZL1")
				ZL1->( DBSetOrder(1) )
				If ZL1->( DBSeek( xFilial("ZL1") + cVeicul ) )
					cPlacaVeic := ZL1->ZL1_PLACA
				Else
					MsgStop("O Veiculo selecionado não foi localizado! Selecione um veiculo relacionado ao Transportador!","AGLT05217")
					_lRet := .F.
				EndIf
			EndIf
			cMotor		:= Posicione( "ZL1" , 1 , xFilial("ZL1") + cVeicul	, "ZL1_MOTORI"	)
			cDescMot	:= Posicione( "ZL0" , 1 , xFilial("ZL0") + cMotor	, "ZL0_NOME"	)
		EndIf
		cDescLin := ZL3->ZL3_DESCRI
		If nOpcao == 3
			nTotKM := ZL3->ZL3_KM
		EndIf
	Else
		_lRet := .F.
	EndIf
	
	If _lRet
		_lRet := ZL3->ZL3_SETOR == cSetor
		If !_lRet
			MsgStop("A Linha selecionada nao pertence ao Setor Atual, Linha/Rota pertence ao Setor: "+ZL3->ZL3_SETOR+". Selecione uma linha/rota que pertence ao setor informado!","AGLT05218")
			oLinRota:SetFocus()
		EndIf
	EndIf
	
EndIf

FWRestArea(_aArea)

Return( _lRet )

/*
===============================================================================================================================
Programa----------: AGLT052F
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 15/09/2008
Descrição---------: Funcao usada para validar Fretista digitado na tela de Recepcao de leite
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT052F()

Local _lRet			:= .T.
Local _aArea		:= FWGetArea()

If !Empty( cFretist ) .And. Empty(cLjFret)
	cLjFret := Posicione( 'SA2' , 1 , xFilial('SA2') + cFretist , 'A2_LOJA' )
EndIf

If !Empty( cFretist ) .And. !Empty(cLjFret)
	cDescFret := Posicione( 'SA2' , 1 , xFilial('SA2') + cFretist + cLjFret , 'A2_NOME' )
EndIf

FWRestArea(_aArea)

Return( _lRet )

/*
===============================================================================================================================
Programa----------: AGLT052M
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 15/09/2008
Descrição---------: Funcao usada para validar motorista digitado na tela de Recepcao de leite
Parametros--------: cMotor: codigo do motor
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT052M(cMotor)

Local _lRet	:= .T.
Local _aArea	:= FWGetArea()

If Altera
	Return( .T. )
EndIf

If !Empty(cMotor)

	DBSelectArea("ZL0")
	ZL0->( DBSetOrder(1) )
	ZL0->( DBGoTop() )
	If ZL0->( DBSeek( xFilial("ZL0") + cMotor ) )
		cDescMot := ZL0->ZL0_NOME
		ZL1->( DBSetOrder(3) )
		If ZL1->( DBSeek( xFilial("ZL1") + cMotor ) )
			cPlacaVeic	:= ZL1->ZL1_PLACA
			cVeicul		:= ZL1->ZL1_COD
		EndIf
		If ZL0->ZL0_FRETIS != cFretist
			MsgStop("O Motorista selecionado nao pertence ao Transportador! Selecione um motorista relacionado ao Transportador!","AGLT05219")
			_lRet := .F.
		EndIf
	
	Else
		MsgStop("O Motorista selecionado nao foi localizado! Selecione um motorista relacionado ao Transportador!","AGLT05220")
		_lRet := .F.
	EndIf
	
EndIf

FWRestArea(_aArea)

Return( _lRet )

/*
===============================================================================================================================
Programa----------: AGLT052P
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 15/09/2008
Descrição---------: Funcao usada para criar legenda na tela de Recepcao de leite
Parametros--------: aCores: array
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT052P(aCores)

Local aLegenda := {	{ "BR_VERDE"	, "Aberto"		} ,; //Sem Status
					{ "BR_VERMELHO"	, "Faturado"	}  } //Sem Status

BrwLegenda( cCadastro , "Legenda" , aLegenda )

Return

/*
===============================================================================================================================
Programa----------: AGLT052S
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 15/09/2008
Descrição---------: Funcao usada para calcular total de uma coluna da getDados
Parametros--------: _lgat - chamada como gatilho
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT052S(_lgat)

Local _nRet	:= 0
Local _nI	:= 0
Local _nCol	:= 0

Default _lgat := .F.

//================================================================================
// Obtem posicao da coluna de quantidade de leite
//================================================================================
_nCol := aScan( aHeader , {|x| AllTrim(x[2]) == "ZLW_QTDBOM" } )

//================================================================================
// Se exist aCols e Linha nao deletada soma qtd
//================================================================================
If Type("aCols") <> "U"
	For _nI := 1 To Len( aCols )
		If !aTail( aCols[_nI] )
			If ValType( aCols[_nI][_nCol] ) == "N"
				If _lgat
					If _nI == n
						_nRet += M->ZLW_QTDBOM
					Else
						_nRet += aCols[_nI][_nCol]					
					EndIf
				Else
					_nRet += aCols[_nI][_nCol]
				EndIf
			EndIf
		EndIf
	Next _nI
EndIf

Return( _nRet )

/*
===============================================================================================================================
Programa----------: AGLT052I
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 15/09/2008
Descrição---------: Funcao usada para inserir registros na ZLW
Parametros--------: aregs - arrays com dados a incluir
Retorno-----------: _lRet - se completou o processamento
===============================================================================================================================
*/
Static Function AGLT052I( aRegs )

Local bOk			:= .T.
Local _nI			:= 0

DBSelectArea("ZL3")
ZL3->( DBSetOrder(1) )
ZL3->( DBSeek( xFilial("ZL3") + cLinRot ) )

//================================================================================
// Grava  Mov.Interno caso For inclusao
//================================================================================
If bOk .Or. Altera

	If Inclui
		cCodRec := u_getNumRww()
	EndIf

	//================================================================================
    // Se nao houver nenhum item grava o registro em branco apenas para gerar estoque
	//================================================================================
	If Len(aRegs) == 1 .And. Empty( aRegs[1][nPosRetiro] ) .And. Empty( aRegs[1][nPosQtdBom] )
	
		ZLW->( RecLock( "ZLW" , .T. ) )
		
		ZLW->ZLW_FILIAL	:= xFilial("ZLW")
		ZLW->ZLW_CODREC	:= cCodRec
		ZLW->ZLW_TICKET	:= cTicket
		ZLW->ZLW_DTLANC	:= dData
		ZLW->ZLW_DTCOLE	:= dDtColeta
		ZLW->ZLW_SETOR 	:= cSetor
		ZLW->ZLW_LINROT	:= cLinRot
		ZLW->ZLW_FRETIS	:= cFretist
		ZLW->ZLW_LJFRET	:= cLjFret
		ZLW->ZLW_VEICUL	:= cVeicul
		ZLW->ZLW_MOTOR	:= cMotor
		ZLW->ZLW_KM		:= nTotKM   
		ZLW->ZLW_CODIGO	:= _cCodRecep
		ZLW->ZLW_STATUS	:= " "
		ZLW->ZLW_USER 	:= cUser
		ZLW->ZLW_TOTBOM	:= nTotBom
		
		ZLW->( MSUnLock() )
		ZLW->( DBCommit() )
		
	EndIf
	
	For _nI := 1 To Len( aRegs )
	
		If !aTail( aRegs[_nI] ) //Verifica se item esta deletado
		
			If  !Empty( aRegs[_nI][nPosRetiro] ) .And. !Empty( aRegs[_nI][nPosLoja] )//aRegs[i][nPosQtdBom] <> 0 .And.
			
				ZLW->( RecLock( "ZLW" , .T. ) )
				
				ZLW->ZLW_FILIAL	:= xFilial("ZLW")
				ZLW->ZLW_CODREC	:= cCodRec
				ZLW->ZLW_TICKET	:= cTicket
				ZLW->ZLW_DTLANC	:= dData
				ZLW->ZLW_DTCOLE	:= dDtColeta
				ZLW->ZLW_SETOR 	:= cSetor
				ZLW->ZLW_LINROT	:= cLinRot
				ZLW->ZLW_RETIRO	:= aRegs[_nI][nPosRetiro]
				ZLW->ZLW_RETILJ	:= aRegs[_nI][nPosLoja]
				ZLW->ZLW_FRETIS	:= cFretist
				ZLW->ZLW_LJFRET	:= cLjFret
				ZLW->ZLW_VEICUL	:= cVeicul
				ZLW->ZLW_MOTOR	:= cMotor
				ZLW->ZLW_QTDBOM	:= aRegs[_nI][nPosQtdBom]
				ZLW->ZLW_TQ_LT	:= aRegs[_nI][nPosTqLt]
				ZLW->ZLW_KM		:= nTotKM 
				ZLW->ZLW_CODIGO	:= _cCodRecep
				ZLW->ZLW_STATUS	:= " "
				ZLW->ZLW_USER 	:= cUser
				ZLW->ZLW_TOTBOM	:= nTotBom
		        If nPosAtendi # 0
		           ZLW->ZLW_ATENDI:=aRegs[_nI][nPosAtendi]
		        EndIf
				
				ZLW->( MSUnLock() )
				ZLW->( DBCommit() )
			
			EndIf
			
		EndIf
		
	Next _nI
	
EndIf

Return

/*
===============================================================================================================================
Programa----------: AGLT052D
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 15/09/2008
Descrição---------: Funcao usada para apagar registros na ZLW
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT052D( aRegs , lDelEstoque )

Local _aArea	:= FWGetArea()
Local _nI		:= 0

//================================================================================
// Se nao houver lancamentos com o ticket, Deleta o Movimento Interno e Exclui
//================================================================================
DBSelectArea("ZLW")
ZLW->( DBSetOrder(2) ) //ZLW_FILIAL+ZLW_CODREC+ZLW_RETIRO+ZLW_RETILJ
For _nI := 1 To Len( aRegs )
	
	ZLW->( DBGoTop() )
	If ZLW->( DBSeek( xFilial("ZLW") + cCodRec + aRegs[_nI][nPosRetiro] + aRegs[_nI][nPosLoja] ) )
	
		ZLW->( RecLock( "ZLW" , .F. ) )
		ZLW->( DBDelete() )
		ZLW->( MSUnLock() )
		ZLW->( DBCommit() )
		
	EndIf
	
Next _nI

FWRestArea( _aArea )

Return

/*
===============================================================================================================================
Programa----------: AGLT052C
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 15/09/2008
Descrição---------: Funcao que busca setor,linha,veiculo padroes do Fretista e lanca nas variaveis
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT052C()

Local _aArea	:= FWGetArea()
Local _lRet		:= .F.
Local _cAlias	:= GetNextAlias()

If Empty( cLjFret )
	Return( .T. )
EndIf

If nOpc == 4
     Return(_lRet)
EndIf

BeginSql alias _cAlias
	SELECT ZL3_COD, ZL3_DESCRI, ZL3_SETOR, ZL3_VEICUL, ZL3_KM, ZL2_DESCRI
	FROM %Table:ZL3% ZL3, %Table:ZL2% ZL2
	WHERE ZL3.D_E_L_E_T_ = ' '
	AND ZL2.D_E_L_E_T_ = ' '
	AND ZL3.ZL3_FILIAL = %xFilial:ZL3%
	AND ZL2.ZL2_FILIAL = %xFilial:ZL2%
	AND ZL2.ZL2_COD = ZL3.ZL3_SETOR
	AND ZL3.ZL3_FRETIS = %exp:cFretist%
	AND ZL3.ZL3_FRETLJ = %exp:cLjFret%
EndSql

If (_cAlias)->( !Eof() )

	cLinRot		:= (_cAlias)->ZL3_COD
	cDescLin	:= (_cAlias)->ZL3_DESCRI
	cSetor		:= (_cAlias)->ZL3_SETOR
	cDescSet	:= (_cAlias)->ZL2_DESCRI
	cVeicul		:= (_cAlias)->ZL3_VEICUL
	cMotor		:= Posicione( "ZL1" , 1 , xFilial("ZL1") + cVeicul	, "ZL1_MOTORI"	)
	cPlacaVeic	:= Posicione( "ZL1" , 1 , xFilial("ZL1") + cVeicul	, "ZL1_PLACA"	)
	cDescMot	:= Posicione( "ZL0" , 1 , xFilial("ZL0") + cMotor	, "ZL0_NOME"	)
	nTotKM		:= (_cAlias)->ZL3_KM
	
	U_getNwTicket(.T.)
	
	_lRet := .T.
	
EndIf

(_cAlias)->( DBCloseArea() )

If !_lRet

	If MsgYesNo("Esse Transportador não está vinculado a nenhuma linha! Continuar assim mesmo?","AGLT05221")
		_lRet := .T.
	EndIf
	
EndIf

FWRestArea( _aArea )

Return( _lRet )

/*
===============================================================================================================================
Programa----------: AGLT052B
Autor-------------: Abrahao
Data da Criacao---: 24/12/2008
Descrição---------: Funcao que verifica se existe um determinado valor em um determinado campo de uma tabela
Parametros--------: cpVlr - ticket a ser verificado
Retorno-----------: cret - Se existe o ticket ou não
===============================================================================================================================
*/
Static Function AGLT052B( cpVlr )

Local _lRet		:= .F.
Local _aArea	:= FWGetArea()
Local _nT1		:= 0
Local _nT2		:= 0
Local _cAlias	:= GetNextAlias()

If Empty(cpVlr)
	u_getNwTicket(.T.)
	cpVlr := cTicket
Else
   If Inclui .And. ISALPHA(cpVlr)//LEFT(cpVlr,1) = "S"
      MsgStop("Ticket nao pode começar com letras, reservado para o SmartQuestion","AGLT05222")
      Return .T.//.T. BLOQUEIA
	EndIf
EndIf

If !Empty(cpVlr)
   cTicket:=cpVlr:=StrZero(Val(cpVlr),Len(ZLW->ZLW_TICKET))
EndIf

BeginSql alias _cAlias
	SELECT ZLW_QTDBOM, ZLW_TOTBOM
	FROM %Table:ZLW% ZLW
	WHERE ZLW.D_E_L_E_T_ = ' '
	AND ZLW_FILIAL = %xFilial:ZLW%
	AND ZLW_TICKET = %exp:cpVlr%
	AND ZLW_SETOR  = %exp:cSetor%
EndSql

While (_cAlias)->( !Eof() )
	_nT1	+= (_cAlias)->ZLW_QTDBOM
	_nT2	:= (_cAlias)->ZLW_TOTBOM
	_lRet	:= .T.
	(_cAlias)->( DBSkip() )
EndDo

//================================================================================
// Zera variaveis - Caso mude o num. do ticket
//================================================================================
nVolAnt		:= 0
nLeiteBom	:= 0
nTotBom		:= 0

If _lRet

	If MsgYesNo("O Ticket digitado já existe! Deseja complementar os lancamentos desse Ticket?","AGLT05223")
    	nVolAnt 	:= _nT1
		nLeiteBom 	:= _nT1
    	nTotBom 	:= _nT2
		nLtDif 		:= nTotBom - nLeiteBom
		_lRet		:= .F.
	    lAbleTicket := .F.
	
	Else
		lAbleTicket := .T.
	EndIf
	
EndIf

(_cAlias)->( DBCloseArea() )

FWRestArea( _aArea )

Return( _lRet )

/*
===============================================================================================================================
Programa----------: AGLT052W
Autor-------------: Abrahao
Data da Criacao---: 09/01/2009
Descrição---------: Obtem volume fisico dos ticket lancados anteriormente
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT052W( cpCodRec , cpTicket , cpSetor )

Local _aArea	:= FWGetArea()
Local _nRet		:= 0
Local _cAlias	:= GetNextAlias()

BeginSql alias _cAlias
	SELECT SUM(ZLW_QTDBOM) QTDVOL
	FROM %Table:ZLW% ZLW
	WHERE ZLW.D_E_L_E_T_ = ' '
	AND ZLW_FILIAL = %xFilial:ZLW%
	AND ZLW_CODREC <> %exp:cpCodRec%
	AND ZLW_TICKET = %exp:cpTicket%
	AND ZLW_SETOR  = %exp:cpSetor%
EndSql

If (_cAlias)->( !Eof() )
	_nRet := (_cAlias)->QTDVOL
EndIf

(_cAlias)->( DBCloseArea() )

FWRestArea(_aArea)

Return( _nRet )

/*
===============================================================================================================================
Programa----------: AGLT003Q
Autor-------------: Abrahao
Data da Criacao---: 09/01/2009
Descrição---------: Verifica se os produtos informados pertencem à linha da recepção
Parametros--------: Nenhum
Retorno-----------: _lRet - Se produtores pertecem a linha da recepção
===============================================================================================================================
*/
Static Function AGLT003Q()

Local _lRet := .T.
Local _nI	:= 0
Local _cAux	:= ''

For _nI := 1 To Len(aCols)

	If !aTail( aCols[_nI] ).AND. !(Len( aCols ) == 1 .And. Empty( aCols[1][nPosRetiro] ) .And. Empty( aCols[1][nPosQtdBom] ))
	
		_cAux := Posicione( "SA2" , 1 , xFilial("SA2") + aCols[_nI][nPosRetiro] + aCols[_nI][nPosLoja] , "A2_L_LI_RO" )
		
		If _cAux != cLinRot
		     _lRet := .F.
		EndIf
		
	EndIf

Next _nI

Return( _lRet )

/*
===============================================================================================================================
Programa----------: AGLT052Z
Autor-------------: Fabiano Dias
Data da Criacao---: 15/07/2011
Descrição---------: Funcao usada para realizar a insercao dos produtores de um determinado ticket
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT052Z() 

Local _sDtInic   := ""
Local _sDtFina   := ""
Local _cAlias    := ""
Local _aAreaZLM  := ZLM->(GetArea())                              

Local _nPosCodig := aScan( aHeader , {|x| AllTrim( Upper(x[2]) ) == "ZLW_RETIRO"	})
Local _nPosLoja  := aScan( aHeader , {|x| AllTrim( Upper(x[2]) ) == "ZLW_RETILJ"	})
Local _nPosNome  := aScan( aHeader , {|x| AllTrim( Upper(x[2]) ) == "ZLW_DCRRET"	})
Local _nqtdeLeit := aScan( aHeader , {|x| AllTrim( Upper(x[2]) ) == "ZLW_QTDBOM"	})
Local _cTipTanq  := aScan( aHeader , {|x| AllTrim( Upper(x[2]) ) == "ZLW_TQ_LT"		})
Local _cAliasWT  := aScan( aHeader , {|x| AllTrim( Upper(x[2]) ) == "ZLW_ALI_WT"	})

Private _cPerg:= "AGLT052"

//================================================================================
// Verifica campos obrigatorios para a realizacao desta rotina.
//================================================================================
If Empty(cSetor) .Or. Empty(cLinRot)
	MsgStop("Para realizar a execução desta rotina é necessário o preenchimento dos campos Setor e Linha situados no cabeçalho da recepção de leite.","AGLT05224")
	Return	            
EndIf

//================================================================================
// Somente serao aceitos tickets que estejam compreendidos dentro do intervalo de
// dia inicial e final do mes corrente
//================================================================================
_sDtInic := DToS( firstDay(	Date() ) )
_sDtFina := DToS( lastday(	Date() ) )

If !Pergunte( _cPerg , .T. )
     Return
EndIf          

_cAlias:= GetNextAlias()

BeginSql alias _cAlias
	SELECT SA2.A2_COD CODIGO, SA2.A2_LOJA LOJA, SubStr(SA2.A2_NOME,1,40) NOME, SA2.A2_L_CLASS
	FROM %Table:ZLW% ZLW, %Table:SA2% SA2
	WHERE ZLW.D_E_L_E_T_ = ' '
	AND SA2.D_E_L_E_T_ = ' '
	AND ZLW.ZLW_FILIAL =  %exp:cFilAnt%
	AND ZLW.ZLW_SETOR  =  %exp:cSetor%
	AND ZLW.ZLW_LINROT =  %exp:cLinRot%
	AND SA2.A2_L_LI_RO =  %exp:cLinRot%
	AND ZLW.ZLW_DTLANC >= %exp:_sDtInic% AND ZLW.ZLW_DTLANC <= %exp:_sDtFina%
	AND ZLW.ZLW_TICKET =  %exp:MV_PAR01%
	AND SA2.A2_COD = ZLW.ZLW_RETIRO 
	AND SA2.A2_LOJA = ZLW.ZLW_RETILJ
	ORDER BY ZLW.R_E_C_N_O_
EndSql                   

If (_cAlias)->( !Eof() )

	//================================================================================
	// Seta o acols, para nao inserir varias vezes os mesmos produtores.
	//================================================================================
	aCols := {}
	
	While (_cAlias)->( !Eof() )
	
	    //================================================================================
		// Inicializa o Acols com uma linha em Branco
		//================================================================================
		aAdd(aCols,Array(Len(aHeader)+1))                             		                                       		
		
		//================================================================================
		// Seta a linha corrente como nao deletada
		//================================================================================
		aCols[Len(aCols),Len(aHeader)+1]:= .F.   		
		
		//================================================================================
		// Insere os dados selecionados em banco
		//================================================================================
		aCols[Len(aCols)][_nPosCodig]	:= (_cAlias)->CODIGO
		aCols[Len(aCols)][_nPosLoja]	:= (_cAlias)->LOJA
		aCols[Len(aCols)][_nPosNome]	:= (_cAlias)->NOME
		aCols[Len(aCols)][_nqtdeLeit]	:= 0                      		
		aCols[Len(aCols)][_cTipTanq]	:= IIf( (_cAlias)->A2_L_CLASS <> "N" , "T" , "L" )
		aCols[Len(aCols)][_cAliasWT]	:= "ZLW"
	
		(_cAlias)->( DBSkip() )
	EndDo
	
Else
	MsgStop("Não foram encontrados os produtores do ticket informado. Favor checar se os dados do ticket atual estao corretos "+;
			"e se a data de coleta do ticket informado para realizar a pesquisa esta compreendida entre a data inicial e final do mes corrente.","AGLT05225")
EndIf

//================================================================================
// Finaliza a area criada anteriormente
//================================================================================
(_cAlias)->( DBCloseArea() )

FWRestArea( _aAreaZLM )

Return

/*
===============================================================================================================================
Programa----------: AGLT052G
Autor-------------: Fabiano Dias
Data da Criacao---: 04/06/2014
Descrição---------: Funcao usada para validar o código de recepção fornecido
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT052G()

Local _aArea	:= FWGetArea()
Local _lRet		:= .T.
Local _cAlias	:= GetNextAlias()

_cCodRecep := PadL( AllTrim( _cCodRecep ) , 8 , "0" )

BeginSql alias _cAlias
	SELECT COUNT(1) NUMREG
	FROM %Table:ZLW%
	WHERE D_E_L_E_T_ = ' '
	AND ZLW_CODIGO = %exp:_cCodRecep%
EndSql

If (_cAlias)->NUMREG > 0
	_lRet := .F.
	MsgStop("O código de Recepção fornecido: "+ _cCodRecep +" já foi inserido anteriormente!"+;
			"Favor desta forma informar um código de Recepção válido!","AGLT05226")
EndIf               

(_cAlias)->( DBCloseArea() )

_oCodRecep:Refresh()
oDlg:Refresh()

FWRestArea(_aArea)

Return( _lRet )

/*
===============================================================================================================================
Programa----------: AGLT003K
Autor-------------: Fabiano Dias
Data da Criacao---: 15/07/2011
Descrição---------: Atualiza campos de volume do cabeçalho
Parametros--------: _lgat - Chamado como gatilho
Retorno-----------: .T.
===============================================================================================================================
*/
User Function AGLT052K(_lgat)

Default _lgat := .F.

//================================================================================
// Atualiza Variaveis de Totais
//================================================================================
//nleiteant   := nLeiteBom
nLeiteBom	:= nVolAnt + U_AGLT052S(_lgat)
nTotCodRec	:= U_AGLT052S(_lgat)
nLtDif		:= nTotBom - nLeiteBom

If ValType(oLteBom) == 'O'
	oLteBom:Refresh()  
EndIf

If ValType(nDif) == 'O'
	nDif:Refresh()
EndIf

If ValType(oTotCodRec) == 'O'
	oTotCodRec:Refresh()
EndIf

If ValType(oDlg) == 'O'
	oDlg:Refresh()
EndIf

Return .T.
