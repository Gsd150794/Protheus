/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
       Autor      |    Data    |                                             Motivo                                           
-------------------------------------------------------------------------------------------------------------------------------
 Alexandre Villar | 22/12/2015 | Tratativa na cláusula "ORDER BY" para remover a referência numérica. Chamado 13062
-------------------------------------------------------------------------------------------------------------------------------
 Lucas Borges     | 11/10/2019 | Removidos os Warning na compilação da release 12.1.25. Chamado 28346
===============================================================================================================================
*/

//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================
#Include "TOTVS.ch"

#Define TITULO "Bloqueio de Clientes Inativos"

/*
===============================================================================================================================
Programa--------: COMS002
Autor-----------: Alexandre Villar
Data da Criacao-: 21/02/2014
===============================================================================================================================
Descrição-------: Rotina de Consulta de Lotes de Processamento - Bloqueio de Clientes
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function COMS002()

Local cExpFil		:= " TRIM(Z00_ROTINA) = 'MOMS026' "

Private cCadastro 	:= OemToAnsi( "Lotes - " + TITULO )
Private aRotina 	:= fMenuDef()

//===========================================================================
//| Define formato de data para exibição nas telas da rotina                |
//===========================================================================
SET DATE FORMAT TO "DD/MM/YYYY"

//===========================================================================
//º Endereca a funcao de BROWSE.                                            º
//===========================================================================
DBSelectArea("Z00" )
Z00->( DBSetOrder(1) )
Z00->( MBrowse( ,,,, "Z00" ,,,,,, U_COMS002L() ,,,,,,,, cExpFil ) )

Return(.T.)

/*
===============================================================================================================================
Programa----------: COMS002M
Autor-------------: Alexandre Villar
Data da Criacao---: 21/02/2014
===============================================================================================================================
Descrição---------: Monta tela de Consulta dos itens dos Lotes de Processamento - Bloqueio de Clientes
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function COMS002M()

Local oDlg			:= Nil
Local oLbxDados		:= Nil
Local aPosObj   	:= {}
Local aObjects  	:= {}
Local aSize     	:= MsAdvSize()
Local cTotReg		:= ""
Local bMntDados		:= {|| Processa({|lEnd| COMS002SEL( @oLbxDados , Z00->Z00_LOTE , @cTotReg) }) } 
Local oBar			:= Nil
Local aBtn 	    	:= Array(05)
Local aCabecLbx		:= {	"Lote"				,; //01
							"Chave"				,; //02
							"Cliente"			,; //03
							"Data Inicial"		,; //04
							"Data Final"		,; //05
							"Execução"			,; //06
							"Ação"				,; //07
							"Status Lote"		 } //08

Private	nItPosAnt	:= 0
Private	cCadastro	:= "Consulta do Lote ["+ Z00->Z00_LOTE +"] - "+ TITULO

aAdd( aObjects, { 100, 100, .T., .T. } )

aInfo   := { aSize[ 1 ], aSize[ 2 ], aSize[ 3 ], aSize[ 4 ], 3, 2 }
aPosObj := MsObjSize( aInfo, aObjects )

DEFINE FONT oBold NAME "Arial" SIZE 0, -12 BOLD

DEFINE MSDIALOG oDlg TITLE cCadastro From aSize[7],000 to aSize[6],aSize[5] Of oMainWnd Pixel

	//===========================================================================
	//º ListBox com os dados.                                                   º
	//===========================================================================
	@aPosObj[01][01]+18,aPosObj[01][02]+4 	Listbox oLbxDados Fields;
											HEADER 	""		 		;
											On DbLCLICK ( Nil )		;
											Size aPosObj[01][04]-10,( aPosObj[01][03] - aPosObj[01][01] ) - 10 Of oDlg Pixel

	oLbxDados:AHeaders		:= aClone(aCabecLbx)
	oLbxDados:BHEADERCLICK	:= { |oObj,nCol| U_ITOrdLbx( oObj , nCol , oLbxDados ) }	
	Eval(bMntDados)
    
	@aPosObj[01][01]+10,aPosObj[01][02] To aPosObj[01][03]+10,aPosObj[01][04] LABEL "Registros Processados no Lote ["+ cTotReg +"]" COLOR CLR_HBLUE OF oDlg PIXEL

	//===========================================================================
	//º Monta os Botoes da Barra Superior.                                      º
	//===========================================================================
	DEFINE BUTTONBAR oBar SIZE 25,25 3D OF oDlg

	DEFINE BUTTON aBtn[01] RESOURCE PmsBExcel()[1] OF oBar GROUP ACTION DlgToExcel({{"ARRAY","",oLbxDados:AHeaders,oLbxDados:aArray}})	TOOLTIP "Exportar Para Planilha..."
	aBtn[01]:cTitle := ""
	
	DEFINE BUTTON aBtn[03] RESOURCE "FINAL" 		OF oBar GROUP ACTION oDlg:End() 													TOOLTIP "Sair da Tela..."
	aBtn[03]:cTitle := ""
	
	oDlg:lMaximized := .T.
	
ACTIVATE MSDIALOG oDlg CENTERED

Return

/*
===============================================================================================================================
Programa----------: COMS002SEL
Autor-------------: Alexandre Villar
Data da Criacao---: 21/02/2014
===============================================================================================================================
Descrição---------: Rotina de seleção dos ítens do Lote de Processamento - Bloqueio de Clientes
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function COMS002SEL( oLbxAux , cNumLote , cTotReg )

Local aLbxAux		:= {}
Local cQuery 		:= ""
Local cAlias		:= GetNextAlias()
Local nTotReg   	:= 0
Local nCont			:= 0

//===========================================================================
//º Selecao dos Campos Principais utilizados na Rotina Atual.				º
//===========================================================================
cQuery := " SELECT "
cQuery += " 	Z03.Z03_LOTE    AS LOTE, "
cQuery += " 	Z03.Z03_CHAVE   AS CHAVE, "
cQuery += " 	SA1.A1_NOME		AS CLIENTE, "
cQuery += " 	Z03.Z03_DATINI	AS DATINI, "
cQuery += " 	Z03.Z03_DATFIM	AS DATFIM, "
cQuery += " 	Z03.Z03_DATA	AS DT_PRO, "
cQuery += " 	Z03.Z03_HORA	AS HR_PRO, "
cQuery += " 	Z03.Z03_ACAO	AS ACAO, "
cQuery += " 	Z03.Z03_STATUS  AS STS_AUX "
cQuery += " FROM "+ RetSqlName("Z03") +" Z03 "
cQuery += " LEFT OUTER JOIN "+ RetSqlName("SA1") +" SA1 "
cQuery += " ON "
cQuery += " 		SA1.A1_FILIAL || SA1.A1_COD || SA1.A1_LOJA = Z03.Z03_CHAVE "
cQuery += " AND		SA1.D_E_L_E_T_ = ' ' "
cQuery += " WHERE "
cQuery += "     Z03.D_E_L_E_T_  = ' ' "
cQuery += " AND	Z03.Z03_LOTE	= '"+ cNumLote +"' "
cQuery += " ORDER BY Z03.Z03_CHAVE, Z03.Z03_DATINI, Z03.Z03_DATFIM "

If Select(cAlias) > 0
	(cAlias)->(DBCloseArea())
EndIf

DBUseArea( .T. , "TOPCONN" , TCGenQry(,,cQuery) , cAlias , .F. , .T. )

DBSelectArea(cAlias)
(cAlias)->(DBGoTop()) 
(cAlias)->( DBEval( { || nTotReg++ } ) )

ProcRegua(nTotReg)
cTotReg := StrZero( nTotReg , 6 )

(cAlias)->(DBGoTop())

While !(cAlias)->(Eof())

	aAdd( aLbxAux , {	(cAlias)->LOTE				 					,; //01
						(cAlias)->CHAVE				 					,; //02
						(cAlias)->CLIENTE			 					,; //03
		DToC(	SToD(	(cAlias)->DATINI ) )		 					,; //04
		DToC(	SToD(	(cAlias)->DATFIM ) )		 					,; //05
		DToC(	SToD(	(cAlias)->DT_PRO ) ) +" - "+ (cAlias)->HR_PRO	,; //06
			U_ITRetBox(	(cAlias)->ACAO		, "Z03_ACAO"	)			,; //07
			U_ITRetBox(	(cAlias)->STS_AUX	, "Z01_STATUS"	)			}) //08
	
	nCont++
	IncProc("Montando estrutura "+StrZero(nCont,6)+" de "+StrZero(nTotReg,6)  )
	
(cAlias)->(DBSkip())
EndDo

(cAlias)->(DBCloseArea())

If	Len(aLbxAux) > 0 .And. ValType(oLbxAux) == "O"
                     
	oLbxAux:SetArray(aLbxAux)
	oLbxAux:bLine := {||	{	aLbxAux[oLbxAux:nAt][01]	,; // 01 
								aLbxAux[oLbxAux:nAt][02]	,; // 02
								aLbxAux[oLbxAux:nAt][03]	,; // 03
								aLbxAux[oLbxAux:nAt][04]	,; // 04
								aLbxAux[oLbxAux:nAt][05]	,; // 05
								aLbxAux[oLbxAux:nAt][06]	,; // 06
								aLbxAux[oLbxAux:nAt][07]	,; // 07
								aLbxAux[oLbxAux:nAt][08] 	}} // 08

	oLbxAux:Refresh()

EndIf

Return

/*
===============================================================================================================================
Programa----------: FMenuDef
Autor-------------: Alexandre Villar
Data da Criacao---: 21/02/2014
===============================================================================================================================
Descrição---------: Rotina de definição do menu da tela principal - Bloqueio de Clientes
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function fMenuDef()

Private aRotina := { 	{ "Pesquisar"	,"AxPesqui"		,0,1}		,;
						{ "Visualizar"	,"AxVisual"		,0,2}		,;
						{ "Consultar"	,"U_COMS002M"	,0,4}		,; 
						{ "Legenda"		,"U_COMS002L"	,0,0}	 	}

Return(aRotina)

/*
===============================================================================================================================
Programa----------: COMS002L
Autor-------------: Alexandre Villar
Data da Criacao---: 21/02/2014
===============================================================================================================================
Descrição---------: Definição da legenda da tela principal - Bloqueio de Clientes
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function COMS002L( nReg )

Local uRetorno	:= .T.
Local aLegenda  := 	{ 	{ "BR_VERDE"  	, "Desbloqueio"	} ,;
                        { "BR_VERMELHO"	, "Bloqueio"	}  }

//===========================================================================
// Chamada direta da funcao, via menu Recno eh passado
//===========================================================================
If	nReg == Nil

	uRetorno := {}
	
	aAdd( uRetorno , { 'Z00->Z00_OPERAC == "002" '	, aLegenda[1][1] } )
	aAdd( uRetorno , { 'Z00->Z00_OPERAC == "001" '	, aLegenda[2][1] } )

Else
	BrwLegenda(cCadastro, "Legenda",aLegenda)
EndIf

Return( uRetorno )
