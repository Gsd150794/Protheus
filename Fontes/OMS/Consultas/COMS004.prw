/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
       Autor      |    Data    |                                             Motivo                                           
-------------------------------------------------------------------------------------------------------------------------------
 Alexandre Villar | 22/12/2015 | Tratativa na cláusula "ORDER BY" para remover a referência numérica. Chamado 13062
-------------------------------------------------------------------------------------------------------------------------------
 Jerry            | 18/04/2018 | Ordenar a Lista por Data / Hora.  Chamado 24548
-------------------------------------------------------------------------------------------------------------------------------
 Lucas Borges     | 11/10/2019 | Removidos os Warning na compilação da release 12.1.25. Chamado 28346
==============================================================================================================================================================================================
Analista           - Programador   - Inicio   - Envio    - Chamado - Motivo da Alteração
==============================================================================================================================================================================================
Alexandro Wallauer - Julio Paz     - 10/09/25 - 10/09/25 - 50058   - Correção de Error log na rotina de exportação dos dados para Excel.
==============================================================================================================================================================================================
*/

//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================
#Include "TOTVS.ch"

#Define TITULO "Consulta Cliente - Log de Alterações"

/*
===============================================================================================================================
Programa----------: COMS004
Autor-------------: Alexandre Villar
Data da Criacao---: 17/07/2014
===============================================================================================================================
Descrição---------: Consulta Histórico de Alterações do Cadastro de Clientes
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: .T. - Permite seleção .F. - Não permite a seleção	
===============================================================================================================================
*/
User Function COMS004()

Local cCodCli		:= Space( TamSX3("A1_COD")[01] )
Local aParRet		:= { cCodCli }
Local aParamBox 	:= {}

Private cCadastro	:= "Consulta detalhada de Clientes - Log de Alterações"

//================================================================================
//| Verifica se a rotina foi chamada do menu ou do Cadastro de Clientes          |
//================================================================================
If FunName() <> "COMS004"
	
	COMS004HIS( SA1->( A1_COD + A1_LOJA ) )
	
Else

	aAdd( aParamBox	, { 1 , "Selecione o Cliente" , cCodCli , "@!" , "" , "SA1" , "" , 50 , .T. } )
	
	If ParamBox( aParamBox , "Informar os dados para a Consulta:" , @aParRet , {|| COMS004VLD( SA1->A1_COD ) } ,, .T. , , , , , .F. , .F. )
		
		If aParRet[01] != SA1->A1_COD
		
			DBSelectArea("SA1")
			SA1->(DBSetOrder(1))
			If !SA1->( DBSeek( xFilial("SA1") + aParRet[01] ) )
				MessageBox( "Usuário informado não foi encontrado." , TITULO , 0 )
				Return
			EndIf
			
		EndIf
		
		COMS004HIS( SA1->A1_COD )
	
	EndIf

EndIf

Return(.T.)

/*
===============================================================================================================================
Programa----------: COMS004VLD
Autor-------------: Alexandre Villar
Data da Criacao---: 17/07/2014
===============================================================================================================================
Descrição---------: Validação do Cliente selecionado/informado
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: .T. - Permite seleção .F. - Não permite a seleção	
===============================================================================================================================
*/
Static Function COMS004VLD( cChaveCli )

Local lRet := .F.

//================================================================================
//| Verifica se o Cliente informado/selecionado existe no Cadastro (SA1)         |
//================================================================================
DBSelectArea("SA1")
SA1->( DBSetOrder(1) )
If SA1->( MSSeek( xFilial("SA1") + cChaveCli ) )
	lRet := .T.
Else
	MessageBox( "Cliente informado ["+ cChaveCli +"] não é válido." , TITULO , 0 )
	lRet := .F.
EndIf

Return(lRet)

/*
===============================================================================================================================
Programa----------: COMS004HIS
Autor-------------: Alexandre Villar
Data da Criacao---: 17/07/2014
===============================================================================================================================
Descrição---------: Monta a tela detalhada do Histórico de Alterações do Cadastro do Cliente
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: .T. - Permite seleção .F. - Não permite a seleção	
===============================================================================================================================
*/
Static Function COMS004HIS( cCodCli )

Local oDlg			:= Nil
Local oLbxTOP		:= Nil
//Local oLbxDET		:= Nil
Local aPosObj   	:= {}
Local aObjects  	:= {}
Local aSize     	:= MsAdvSize()
Local bMontaTOP		:= { || Processa({|lEnd| COMS004LOG( @oLbxTOP , cCodCli ) }) }
Local bMontaDET		:= { || COMS004DET( @oLbxDET , oLbxTOP:aArray[oLbxTOP:nAt][05] , oLbxTOP:aArray[oLbxTOP:nAt][02] ) }

Local oBar			:= Nil
Local aBtn 	    	:= Array(02)
Local oBold			:= Nil
Local oScrPanel		:= Nil

Local aCabLbxTOP	:= { "Loja", "Campo" , "Descrição" , "Última Alt." } // 04

Local aCabLbxDET	:= { "Data"				,; // 01
                         "Hora"				,; // 02
                         "Usuário"			,; // 03
                         "Nome Usr."		,; // 04
                         "Cont. Orig."		,; // 05
                         "Cont. Alt."		 } // 06

Private	nDvPosAnt	:= 0
Private	cCadastro	:= "["+ cCodCli +"] - " + TITULO
Private oLbxDET		:= Nil


Default cCodCli		:= ""

If Empty(cCodCli)
	Return
EndIf

//================================================================================
//| Posiciona no Cadastro do Cliente                                             |
//================================================================================
DBSelectArea("SA1")
SA1->(DBSetOrder(1))
If !SA1->( DBSeek( xFilial("SA1") + cCodCli ) )
	MessageBox( "O cliente ["+ cCodCli +"] não foi encontrado." , TITULO , 0 )
	Return
EndIf

//================================================================================
//| Verifica se existe histórico de alterações                                   |
//================================================================================
DBSelectArea("Z07")
Z07->( DBSetOrder(1) )
If !Z07->( DBSeek( xFilial("Z07") + "SA1 1" + SA1->( A1_FILIAL + A1_COD + A1_LOJA ) ) )
	MessageBox( "O cliente ["+ cCodCli +"] não possui histórico de alterações." , TITULO , 0 )
	Return
EndIf

aAdd( aObjects, { 100 , 025 , .T. , .F. , .T. } )
aAdd( aObjects, { 100 , 070 , .T. , .F. } )
aAdd( aObjects, { 100 , 100 , .T. , .T. } )

aInfo   := { aSize[1] , aSize[2] , aSize[3] , aSize[4] , 3 , 2 }
aPosObj := MsObjSize( aInfo , aObjects )

DEFINE FONT oBold NAME "Arial" SIZE 0, -12 BOLD

DEFINE MSDIALOG oDlg TITLE cCadastro From aSize[7],00 to aSize[6],aSize[5] Of oMainWnd Pixel

	aPosObj[01][01] += 12
	aPosObj[02][01] += 10
	aPosObj[02][03] += 10
	aPosObj[03][01] += 10
	aPosObj[03][03] += 10
	
	//================================================================================
	//| Imprime o código e o nome do Cliente                                         |
	//================================================================================
	@ aPosObj[01][01],aPosObj[01][02] MSPANEL oScrPanel PROMPT "" SIZE aPosObj[01][03],aPosObj[01][04] OF oDlg LOWERED
	
	@ 004 , 004 Say "Código:" 		SIZE 025,07 OF oScrPanel PIXEL
	@ 012 , 004 Say SA1->A1_COD  	SIZE 060,09 OF oScrPanel PIXEL FONT oBold COLOR CLR_BLUE
	
	@ 004 , 030 Say "Nome:" 		SIZE 025,07 OF oScrPanel PIXEL
	@ 012 , 030 Say SA1->A1_NOME 	SIZE 165,09 OF oScrPanel PIXEL FONT oBold COLOR CLR_BLUE
	
	//================================================================================
	//| Monta o resumo das alterações do cadastro                                    |
	//================================================================================
	@aPosObj[02][01],aPosObj[02][02] To aPosObj[02][03],aPosObj[02][04] LABEL "Campos Alterados" COLOR CLR_HBLUE OF oDlg PIXEL
	
	@aPosObj[02][01]+7,aPosObj[02][02]+4 	Listbox oLbxTOP Fields	;
											HEADER 	""		 		;
											On DbLCLICK ( Nil )		;
											Size aPosObj[02][04]-10,( aPosObj[02][03] - aPosObj[02][01] ) - 10 Of oDlg Pixel
	
	oLbxTOP:AHeaders	:= aClone(aCabLbxTOP)
	oLbxTOP:bChange		:= { || Eval(bMontaDET) }
	
	Eval(bMontaTOP)
	
	//================================================================================
	//| Monta os detalhes das alterações do cadastro                                 |
	//================================================================================
	@aPosObj[03][01],aPosObj[03][02] To aPosObj[03][03],aPosObj[03][04] LABEL "Histórico dos Campos" COLOR CLR_HBLUE OF oDlg PIXEL
	
	@aPosObj[03][01]+7,aPosObj[03][02]+4 	Listbox oLbxDET Fields;
											HEADER 	""		 		;
											On DbLCLICK ( Nil )		;
											Size aPosObj[03][04]-10,( aPosObj[03][03] - aPosObj[03][01] ) - 10 Of oDlg Pixel
					
	oLbxDET:AHeaders := aClone(aCabLbxDET)
	
	Eval(bMontaDET)
	
	//================================================================================
	//| Monta a barra de botões da tela                                              |
	//================================================================================
	DEFINE BUTTONBAR oBar SIZE 25,25 3D OF oDlg
	
	//DEFINE BUTTON aBtn[01] RESOURCE PmsBExcel()[1] OF oBar GROUP ACTION DlgToExcel({{"ARRAY","",oLbxPM7:AHeaders,oLbxPM7:aArray}})	TOOLTIP "Exportar para Planilha..."
	DEFINE BUTTON aBtn[01] RESOURCE PmsBExcel()[1] OF oBar GROUP ACTION DlgToExcel({{"ARRAY","",oLbxDET:AHeaders,oLbxDET:aArray}})	TOOLTIP "Exportar para Planilha..."
	aBtn[01]:cTitle := ""
	
	DEFINE BUTTON aBtn[02] RESOURCE "FINAL" 		OF oBar GROUP ACTION oDlg:End() 													TOOLTIP "Sair da Tela..."
	aBtn[02]:cTitle := ""
	
	oDlg:lMaximized := .T.
	
ACTIVATE MSDIALOG oDlg CENTERED

Return

/*
===============================================================================================================================
Programa----------: COMS004LOG
Autor-------------: Alexandre Villar
Data da Criacao---: 17/07/2014
===============================================================================================================================
Descrição---------: Monta estrutura do Log de Alterações do Cliente
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: .T. - Permite seleção .F. - Não permite a seleção	
===============================================================================================================================
*/
Static Function COMS004LOG( oLbxAux , cCodCli )

Local _cQuery	:= ""
Local _cAlias	:= GetNextAlias()
Local _aLbxAux	:= {}
Local _nTotReg	:= 0
Local _nCont	:= 0

//================================================================================
//| Consulta para buscar o resumo das alterações do cadastro                     |
//================================================================================
_cQuery := " SELECT "
_cQuery += "	SA1.A1_LOJA			AS LOJA,	"
_cQuery += " 	Z07.Z07_CAMPO 		AS CAMPO,	"
_cQuery += " 	MAX( Z07.Z07_DATA )	AS DT_ULT,	"
_cQuery += "	SA1.R_E_C_N_O_		AS REGSA1	"
_cQuery += " FROM "+ RetSqlName("SA1") +" SA1	"
_cQuery += " INNER JOIN "+ RetSqlName("Z07") +" Z07 "
_cQuery += " ON "
_cQuery += " 		SA1.A1_FILIAL || SA1.A1_COD || SA1.A1_LOJA = Z07.Z07_CHAVE "
_cQuery += " WHERE "
_cQuery += " 		SA1.D_E_L_E_T_  = ' ' "
_cQuery += " AND	Z07.D_E_L_E_T_  = ' ' "
_cQuery += " AND	Z07.Z07_ALIAS	= 'SA1' "
If Len(cCodCli) == TamSX3("A1_COD")[01]
_cQuery += " AND	SA1.A1_COD      = '"+ cCodCli +"' "
Else
_cQuery += " AND	SA1.A1_COD || SA1.A1_LOJA = '"+ cCodCli +"' "
EndIf
_cQuery += " GROUP BY SA1.A1_LOJA,  Z07.Z07_DATA, Z07.Z07_HORA,  Z07.Z07_CAMPO, SA1.R_E_C_N_O_"
_cQuery += " ORDER BY SA1.A1_LOJA , Z07.Z07_DATA, Z07.Z07_HORA,  Z07.Z07_CAMPO  "    
 

_cQuery	:= ChangeQuery(_cQuery)
DBUseArea( .T. , "TOPCONN" , TCGenQry(,,_cQuery) , _cAlias , .F. , .T. )

TCSetField( _cAlias , "Z07.Z07_DATA" , "D" , 8 , 0 )

DBSelectArea(_cAlias)
(_cAlias)->(DBGoTop()) 

(_cAlias)->( DBEval( { || _nTotReg++ } ) )

ProcRegua(_nTotReg)

(_cAlias)->(DBGoTop())                                                                                   

//================================================================================
//| Grava os dados do Resumo                                                     |
//================================================================================
While (_cAlias)->(!Eof())
	
	aAdd( _aLbxAux , {	(_cAlias)->LOJA								   		,; // 01
						(_cAlias)->CAMPO							   		,; // 02
						Posicione("SX3",2,(_cAlias)->CAMPO,"X3_DESCRIC")	,; // 03
                       	(_cAlias)->DT_ULT									,; // 04
                       	(_cAlias)->REGSA1					   				}) // 05

_nCont++
IncProc("Montando estrutura "+StrZero(_nCont,6)+" de "+StrZero(_nTotReg,6)  )
(_cAlias)->( DBSkip() )
EndDo

(_cAlias)->( DBCloseArea() )

//================================================================================
//| Monta o objeto do ListBox                                                    |
//================================================================================
If	Len(_aLbxAux) > 0 .And. ValType(oLbxAux) == "O"
                     
	oLbxAux:SetArray(_aLbxAux)
	oLbxAux:bLine:={||{	_aLbxAux[oLbxAux:nAt][01]	,; // 01
						_aLbxAux[oLbxAux:nAt][02]	,; // 02
						_aLbxAux[oLbxAux:nAt][03]	,; // 03
						_aLbxAux[oLbxAux:nAt][04]	,; // 04
						_aLbxAux[oLbxAux:nAt][05]	}} // 05
	
	oLbxAux:Refresh()

EndIf

Return

/*
===============================================================================================================================
Programa----------: COMS004DET
Autor-------------: Alexandre Villar
Data da Criacao---: 17/07/2014
===============================================================================================================================
Descrição---------: Monta estrutura de Detalhes do Log de Alterações do Campo
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: .T. - Permite seleção .F. - Não permite a seleção	
===============================================================================================================================
*/
Static Function COMS004DET( oLbxAux , nRegSA1 , cCampo )

Local _cQuery	:= ""
Local _cAlias	:= GetNextAlias()
Local _aLbxAux	:= {}
Local _nTotReg	:= 0
Local _nCont	:= 0

//================================================================================
//| Consulta para buscar os detalhes das alterações dos campos                   |
//================================================================================
_cQuery := " SELECT "
_cQuery += " 	Z07.Z07_DATA	AS DT_ALT	, "
_cQuery += " 	Z07.Z07_HORA	AS HORA		, "
_cQuery += " 	Z07.Z07_CODUSU	AS CODUSU	, "
_cQuery += " 	Z07.Z07_CONORG	AS CONT_ORG	, "
_cQuery += " 	Z07.Z07_CONALT	AS CONT_ALT	  "
_cQuery += " FROM "+ RetSqlName("SA1") +" SA1 "
_cQuery += " INNER JOIN "+ RetSqlName("Z07") +" Z07 "
_cQuery += " ON "
_cQuery += " 	SA1.A1_FILIAL || SA1.A1_COD || SA1.A1_LOJA = Z07.Z07_CHAVE "
_cQuery += " WHERE "
_cQuery += " 	SA1.D_E_L_E_T_  = ' ' "
_cQuery += " AND	Z07.D_E_L_E_T_  = ' ' "
_cQuery += " AND	Z07.Z07_ALIAS	= 'SA1' "
_cQuery += " AND	Z07.Z07_CAMPO	= '"+ cCampo +"' "
_cQuery += " AND	SA1.R_E_C_N_O_	= '"+ CValToChar(nRegSA1) +"' "
_cQuery += " ORDER BY Z07.Z07_DATA , Z07.Z07_HORA , Z07.Z07_CODUSU , Z07.Z07_CONORG "

_cQuery	:= ChangeQuery(_cQuery)
DBUseArea( .T. , "TOPCONN" , TCGenQry(,,_cQuery) , _cAlias , .F. , .T. )

TCSetField( _cAlias , "Z07.Z07_DATA" , "D" , 8 , 0 )

DBSelectArea(_cAlias)
(_cAlias)->(DBGoTop()) 

(_cAlias)->( DBEval( { || _nTotReg++ } ) )

ProcRegua(_nTotReg) // Regua

(_cAlias)->(DBGoTop())                                                                                   

//================================================================================
//| Grava o resultado dos detalhes das alterações dos campos                     |
//================================================================================
While (_cAlias)->(!Eof())

		aAdd( _aLbxAux , {			(_cAlias)->DT_ALT		,; // 01
                         			(_cAlias)->HORA			,; // 02
                         			(_cAlias)->CODUSU		,; // 03
  AllTrim( Capital( UsrFullName(	(_cAlias)->CODUSU ) ) )	,; // 04
						AllTrim(	(_cAlias)->CONT_ORG )	,; // 05
						AllTrim(	(_cAlias)->CONT_ALT )	}) // 06

_nCont++
IncProc("Montando estrutura "+StrZero(_nCont,6)+" de "+StrZero(_nTotReg,6)  )
(_cAlias)->( DBSkip() )
EndDo

(_cAlias)->( DBCloseArea() )

//================================================================================
//| Monta o objeto do ListBox com os dados dos detalhes                          |
//================================================================================
If	Len(_aLbxAux) > 0 .And. ValType(oLbxAux) == "O"
                     
	oLbxAux:SetArray(_aLbxAux)
	oLbxAux:bLine:={||{	_aLbxAux[oLbxAux:nAt][01]	,; // 01
						_aLbxAux[oLbxAux:nAt][02]	,; // 02
						_aLbxAux[oLbxAux:nAt][03]	,; // 03
						_aLbxAux[oLbxAux:nAt][04]	,; // 04
						_aLbxAux[oLbxAux:nAt][05]	,; // 05
						_aLbxAux[oLbxAux:nAt][06]	}} // 06

	oLbxAux:Refresh()

EndIf

Return
