/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alexandre V.  |22/12/2015| Chamado 13062. Tratativa na cláusula "ORDER BY" para remover a referência numérica.
Lucas Borges  |19/09/2019| Chamado 28346. Revisão do fonte.
Lucas Borges  |02/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25.
===============================================================================================================================
*/

#Include "TOTVS.ch"

#Define TITULO "Integração - Unimed"

/*
===============================================================================================================================
Programa----------: CGPE002
Autor-------------: Alexandre Villar
Data da Criacao---: 23/04/2014
Descrição---------: Rotina de consulta dos lotes de processamento da integração com a Unimed
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function CGPE002

Private cCadastro 	:= OemToAnsi(TITULO)
Private aRotina 	:= MenuDef()

SET DATE FORMAT TO "DD/MM/YYYY"

//============================================================================
//| Valida os Lotes gerados para excluir os vazios.                          |
//============================================================================
LjMsgRun( "Analisando os registros dos Lotes..." , "Aguarde!" , {|| CGPE002VLD() } )

//============================================================================
//| Endereca a funcao do BROWSE.                                             |
//============================================================================
DBSelectArea("Z04")
Z04->( DBSetOrder(1) )
Z04->( mBrowse(,,,,"Z04") )

Return(.T.)

/*
===============================================================================================================================
Programa----------: CGPE002MNT
Autor-------------: Alexandre Villar
Data da Criacao---: 23/04/2014
Descrição---------: Monta a estrutura da tela principal de consulta do Lote
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function CGPE002MNT

Local oDlg			:= Nil
Local oLbxDados		:= Nil
Local aPosObj   	:= {}
Local aObjects  	:= {}
Local aSize     	:= MsAdvSize()
Local cTotReg		:= ""
Local bMntDados		:= {|| Processa({|lEnd| CGPE002SEL( @oLbxDados , Z04->Z04_LOTE , @cTotReg) }) } 
Local bConCliReg	:= {|| IIf( Empty( oLbxDados:aArray ) , MessageBox( "Não existem registros no histórico." , TITULO , 0 ) , LjMsgRun( "Verificando o histórico de Integrações..." , TITULO , {|| U_CGPE002D( oLbxDados:aArray[oLbxDados:nAt][01] + oLbxDados:aArray[oLbxDados:nAt][02] ) } ) ) }
Local oBar			:= Nil
Local aBtn 	    	:= Array(05)

Local aCabecLbx		:= {	"Filial"				,; //01
							"Matrícula"				,; //02
							"Código"				,; //03
							"Nome"					,; //04
							"Nome do Titular"		,; //05
							"Tipo Int."				,; //06
							"Ação no Lote"			,; //07
							"Status no Lote"		,; //08
							"Data"					,; //09
							"Hora"					 } //10

Private	nDvPosAnt	:= 0
Private	cCadastro	:= "Consulta do Lote ["+Z04->Z04_LOTE+"] - " + TITULO

aAdd( aObjects, { 100, 100, .T., .T. } )

aInfo   := { aSize[ 1 ], aSize[ 2 ], aSize[ 3 ], aSize[ 4 ], 3, 2 }
aPosObj := MsObjSize( aInfo, aObjects )

DEFINE FONT oBold NAME "Arial" SIZE 0, -12 BOLD

DEFINE MSDIALOG oDlg TITLE cCadastro From aSize[7],000 to aSize[6],aSize[5] Of oMainWnd Pixel

	//===========================================================================
	//ListBox com os dados
	//===========================================================================
	@aPosObj[01][01]+18,aPosObj[01][02]+4 	Listbox oLbxDados Fields;
											HEADER 	""		 		;
											On DbLCLICK ( Nil )		;
											Size aPosObj[01][04]-10,( aPosObj[01][03] - aPosObj[01][01] ) - 10 Of oDlg Pixel

	oLbxDados:AHeaders		:= aClone(aCabecLbx)
	
	Eval(bMntDados)
    
	@aPosObj[01][01]+10,aPosObj[01][02] To aPosObj[01][03]+10,aPosObj[01][04] LABEL "Titulos Processados no Lote ["+ cTotReg +"]" COLOR CLR_HBLUE OF oDlg PIXEL

	//===========================================================================
	//Monta os Botoes da Barra Superior
	//===========================================================================
	DEFINE BUTTONBAR oBar SIZE 25,25 3D OF oDlg

	DEFINE BUTTON aBtn[01] RESOURCE PmsBExcel()[1] OF oBar GROUP ACTION DlgToExcel({{"ARRAY","",oLbxDados:AHeaders,oLbxDados:aArray}})	TOOLTIP "Exportar Para Planilha..."
	aBtn[01]:cTitle := ""
	
	DEFINE BUTTON aBtn[02] RESOURCE "VERNOTA_MDI"	OF oBar GROUP ACTION Eval(bConCliReg) 													TOOLTIP "Exibir Histórico Detalhado..."
	aBtn[02]:cTitle := ""

	DEFINE BUTTON aBtn[03] RESOURCE "FINAL" 		OF oBar GROUP ACTION oDlg:End() 														TOOLTIP "Sair da Tela..."
	aBtn[03]:cTitle := ""
	
	oDlg:lMaximized := .T.
	
ACTIVATE MSDIALOG oDlg CENTERED

Return

/*
===============================================================================================================================
Programa----------: CGPE002SEL
Autor-------------: Alexandre Villar
Data da Criacao---: 23/04/2014
Descrição---------: Monta a estrutura de dados da tela principal de consulta do Lote
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function CGPE002SEL( oLbxAux , cNumLote , cTotReg )

Local aLbxAux		:= {}
Local cAlias		:= GetNextAlias()
Local nTotReg   	:= 0
Local nCont			:= 0

//===========================================================================
//Selecao dos Campos Principais utilizados na Rotina Atual
//===========================================================================
BeginSql alias cAlias
	SELECT Z05.Z05_FILMAT, Z05.Z05_MATRIC, Z05.Z05_SEQ, SRA.RA_NOME, SRB.RB_NOME, 
	       Z05.Z05_TIPO, Z05.Z05_ACAO, Z05.Z05_STATUS, Z05.Z05_DATA, Z05.Z05_HORA
	  FROM %Table:Z05% Z05
	 INNER JOIN %Table:SRA% SRA
	    ON SRA.RA_FILIAL = Z05.Z05_FILMAT
	   AND SRA.RA_MAT = Z05.Z05_MATRIC
	   AND SRA.D_E_L_E_T_ = ' '
	 INNER JOIN %Table:Z06% Z06
	    ON Z06.Z06_FILIAL = Z05.Z05_FILIAL
	   AND Z06.Z06_CHAVE = Z05.Z05_FILMAT || Z05.Z05_MATRIC || Z05.Z05_SEQ
	   AND Z06.Z06_LOTE = %exp:cNumLote%
	  LEFT OUTER JOIN %Table:SRB% SRB
	    ON SRB.RB_FILIAL = Z05.Z05_FILMAT
	   AND SRB.RB_MAT = Z05.Z05_MATRIC
	   AND SRB.RB_COD = Z05.Z05_SEQ
	   AND SRB.D_E_L_E_T_ = ' '
	 WHERE Z05.D_E_L_E_T_ = ' '
	 ORDER BY Z05.Z05_FILMAT, Z05.Z05_MATRIC, Z05.Z05_SEQ
EndSql

(cAlias)->( DBEval( { || nTotReg++ } ) )
ProcRegua(nTotReg)
cTotReg := StrZero( nTotReg , 6 )
(cAlias)->(DBGoTop())

While !(cAlias)->(Eof())

	aAdd( aLbxAux , {	(cAlias)->( Z05_FILMAT	)		,; //01
						(cAlias)->( Z05_MATRIC	)		,; //02
						(cAlias)->( Z05_SEQ		)		,; //03
						(cAlias)->( RB_NOME		)		,; //04
						(cAlias)->( RA_NOME		)		,; //05
						(cAlias)->( Z05_TIPO	)		,; //06
						(cAlias)->( Z05_ACAO	)		,; //07
						(cAlias)->( Z05_STATUS	)		,; //08
						(cAlias)->( Z05_DATA	)		,; //09
						(cAlias)->( Z05_HORA	)		}) //10

	nCont++
	IncProc("Montando estrutura "+StrZero(nCont,6)+" de "+StrZero(nTotReg,6)  )
	
	(cAlias)->(DBSkip())
EndDo

(cAlias)->(DBCloseArea())

If	Len(aLbxAux) > 0 .And. ValType(oLbxAux) == "O"
                     
	oLbxAux:SetArray(aLbxAux)
	oLbxAux:bLine := {||	{			aLbxAux[oLbxAux:nAt][01]									,; // 01 
										aLbxAux[oLbxAux:nAt][02] 									,; // 02
										aLbxAux[oLbxAux:nAt][03] 									,; // 03
					Capital( AllTrim(	aLbxAux[oLbxAux:nAt][04] ) )								,; // 04
					Capital( AllTrim(	aLbxAux[oLbxAux:nAt][05] ) )		 						,; // 05
							U_ITRetBox(	aLbxAux[oLbxAux:nAt][06] , "Z05_TIPO" )						,; // 06
							U_ITRetBox(	aLbxAux[oLbxAux:nAt][07] , "Z05_ACAO" )						,; // 07
							U_ITRetBox(	aLbxAux[oLbxAux:nAt][08] , "Z05_STATUS" )					,; // 08
						DToC( SToD (	aLbxAux[oLbxAux:nAt][09] ) )								,; // 09
										aLbxAux[oLbxAux:nAt][10] 									}} // 10

	oLbxAux:Refresh()

EndIf

Return

/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Alexandre Villar
Data da Criacao---: 23/04/2014
Descrição---------: Definição do Menu da Rotina Principal
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MenuDef()

Private aRotina := { 	{ "Pesquisar"	,"AxPesqui"		,0,1}		,;
						{ "Consultar"	,"U_CGPE002MNT"	,0,2}		 }

Return(aRotina)

/*
===============================================================================================================================
Programa----------: CGPE002VLD
Autor-------------: Alexandre Villar
Data da Criacao---: 23/04/2014
Descrição---------: Validação para excluir da base os lotes vazios
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function CGPE002VLD()

Local cAlias	:= GetNextAlias()

//===========================================================================
//| Verifica os lotes que foram gerados vazios                              |
//===========================================================================
BeginSql alias cAlias
	SELECT Z04_FILIAL || Z04_LOTE CHAVE
	  FROM %Table:Z04% Z04
	 WHERE Z04.D_E_L_E_T_ = ' '
	   AND NOT EXISTS (SELECT 1
	          FROM %Table:Z06% Z06
	         WHERE Z06.D_E_L_E_T_ = ' '
	           AND Z06.Z06_FILIAL = Z04.Z04_FILIAL
	           AND Z06.Z06_LOTE = Z04.Z04_LOTE)
EndSql

//===========================================================================
//| Exlui os lotes que foram gerados vazios                                 |
//===========================================================================
While (cAlias)->( !Eof() )
	
	DBSelectArea("Z04")
	Z04->( DBSetOrder(1) )
	If Z04->( DBSeek( (cAlias)->CHAVE ) )
		Z04->( RecLock( "Z04" , .F. ) )
		Z04->( DBDelete() )
		Z04->( MSUnLock() )
	EndIf
	
	(cAlias)->( DBSkip() )
EndDo
(cAlias)->( DBCloseArea() )

Return

/*
===============================================================================================================================
Programa----------: CGPE002
Autor-------------: Alexandre Villar
Data da Criacao---: 23/04/2014
Descrição---------: Rotina de consulta detalhada dos dados de integração dos funcionários
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function CGPE002C()

Local _cChave		:= Space( TamSX3("RA_FILIAL")[01] + TamSX3("RA_MAT")[01] )
Local aParRet		:= { _cChave }
Local aParamBox 	:= {}

Private cCadastro	:= "Consulta detalhada de Funcionários"

aAdd( aParamBox	, { 1 , "Digite Filial+Matrícula: " , _cChave , "@!" , "" , "SRA001" , "" , 50 , .T. } )

If ParamBox( aParamBox , "Informar os dados para a Consulta..." , @aParRet , {|| .T. } , , .F. , , , , , .F. , .F. )
	
	_cChave := AllTrim( aParRet[01] )
	
	If Empty( _cChave )
		MsgAlert("Não foi informada uma chave válida para a consulta!","CGPE00201")
	Else
		U_CGPE002D( _cChave )
	EndIf

EndIf

Return

/*
===============================================================================================================================
Programa----------: CGPE002D
Autor-------------: Alexandre Villar
Data da Criacao---: 23/04/2014
Descrição---------: Monta tela para consulta do histórico detalhado
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function CGPE002D( cChave )

Local oDlg			:= Nil
Local oLbxZ05		:= Nil
Local oLbxZ06		:= Nil
Local aPosObj   	:= {}
Local aObjects  	:= {}
Local aSize     	:= MsAdvSize()
Local bTitCliSer	:= { || Processa({|lEnd| CGPE002HIS( @oLbxZ05 , cChave ) } ) }
Local bMontaZ06		:= { || CGPE002ITH( @oLbxZ06 , oLbxZ05:aArray[oLbxZ05:nAt][01] ) }
Local oBar			:= Nil
Local aBtn 	    	:= Array(02)
Local oBold			:= Nil
Local oScrPanel		:= Nil

Local aCabLbxZ05	:= {	"Chave Matric."			,; //01
							"Nome"					,; //02
							"Tipo de Pessoa"		,; //04
							"Ação Atual"			,; //05
							"Status Atual"			,; //06
							"Data"					,; //07
							"Hora"					 } //08

Local aCabLbxZ06	:= {	"Lote"					,; //01
	                        "Chave"					,; //02
	                        "Ação no Lote"			,; //03
	                        "Status no Lote"		,; //05
	                        "Observação"			,; //06
	                        "Data do Lote"			,; //07
	                        "Hora do Lote"			 } //08

Private	nDvPosAnt	:= 0
Private	cCadastro	:= "Consulta Histórico ["+ cChave +"] - "+ TITULO

If Empty(cChave)
	Return
EndIf

//===========================================================================
//Posiciona no Cliente
//===========================================================================
DBSelectArea("SRA")
SRA->( DBSetOrder(1) )
If !SRA->( DBSeek( cChave ) )
	MessageBox( "O Funcionário referente à chave ["+ cChave +"] não foi encontrado." , TITULO , 0 )
	Return(.F.)
EndIf

aAdd( aObjects, { 100, 025, .T. , .F. , .T. } )
aAdd( aObjects, { 100, 100, .T. , .F. } )
aAdd( aObjects, { 100, 050, .T. , .T. } )

aInfo   := { aSize[ 1 ], aSize[ 2 ], aSize[ 3 ], aSize[ 4 ], 3, 2 }
aPosObj := MsObjSize( aInfo, aObjects )

DEFINE FONT oBold NAME "Arial" SIZE 0, -12 BOLD		

DEFINE MSDIALOG oDlg TITLE cCadastro From aSize[7],00 to aSize[6],aSize[5] Of oMainWnd Pixel

	aPosObj[01][01] += 12
	aPosObj[02][01] += 10
	aPosObj[02][03] += 10
	aPosObj[03][01] += 10
	aPosObj[03][03] += 10
	//===========================================================================
	//Parte 01 - Cliente
	//===========================================================================
	@ aPosObj[01][01],aPosObj[01][02] MSPANEL oScrPanel PROMPT "" SIZE aPosObj[01][03],aPosObj[01][04] OF oDlg LOWERED

	@ 004 , 004 Say "Filial:"					SIZE 025,07 OF oScrPanel PIXEL
	@ 012 , 004 Say SRA->RA_FILIAL			 	SIZE 060,09 OF oScrPanel PIXEL FONT oBold COLOR CLR_BLUE

	@ 004 , 020 Say "Matrícula:"				SIZE 035,07 OF oScrPanel PIXEL
	@ 012 , 020 Say SRA->RA_MAT				 	SIZE 035,09	OF oScrPanel PIXEL FONT oBold COLOR CLR_BLUE

	@ 004 , 055 Say "Funcionário:"				SIZE 165,07 OF oScrPanel PIXEL
	@ 012 , 055 Say AllTrim( SRA->RA_NOMECMP )	SIZE 165,09 OF oScrPanel PIXEL FONT oBold COLOR CLR_BLUE

	//===========================================================================
	//Parte 02 - Titulos Processados
	//===========================================================================
	@aPosObj[02][01],aPosObj[02][02] To aPosObj[02][03],aPosObj[02][04] LABEL "Registros processados:" COLOR CLR_HBLUE OF oDlg PIXEL

	//===========================================================================
	//ListBox com Cabecalho do Historico do Titulo
	//===========================================================================
	@aPosObj[02][01]+7,aPosObj[02][02]+4 	Listbox oLbxZ05 Fields;
											HEADER 	""		 		;
											On DbLCLICK ( Nil )		;
											Size aPosObj[02][04]-10,( aPosObj[02][03] - aPosObj[02][01] ) - 10 Of oDlg Pixel
					
	oLbxZ05:AHeaders	:= aClone(aCabLbxZ05)
	oLbxZ05:bChange		:= { || Eval(bMontaZ06) }
	                 
	Eval(bTitCliSer)

	If	Len(oLbxZ05:aArray) <= 0
		MessageBox( "O Funcionário ["+ SRA->RA_FILIAL+"/"+SRA->RA_MAT+"/"+AllTrim( SRA->RA_NOMECMP )+"] não possui histórico de integrações." , TITULO , 0 )
		Return(.F.)
	EndIf

	//===========================================================================
	//Parte 03 - Historico dos Titulos
	//===========================================================================
	@aPosObj[03][01],aPosObj[03][02] To aPosObj[03][03],aPosObj[03][04] LABEL "Histórico das integrações:"	COLOR CLR_HBLUE OF oDlg PIXEL
      
	//===========================================================================
	//ListBox com Itens do Historico do Titulo
	//===========================================================================
	@aPosObj[03][01]+7,aPosObj[03][02]+4 	Listbox oLbxZ06 Fields;
											HEADER 	""		 		;
											On DbLCLICK ( Nil )		;
											Size aPosObj[03][04]-10,( aPosObj[03][03] - aPosObj[03][01] ) - 10 Of oDlg Pixel
					
	oLbxZ06:AHeaders		:= aClone(aCabLbxZ06)
	                 
	//===========================================================================
	//Monta os Botoes da Barra Superior
	//===========================================================================
	DEFINE BUTTONBAR oBar SIZE 25,25 3D OF oDlg
	
	DEFINE BUTTON aBtn[01] RESOURCE PmsBExcel()[1] OF oBar GROUP ACTION DlgToExcel({{"ARRAY","",oLbxZ05:AHeaders,oLbxZ05:aArray}})	TOOLTIP "Exportar para Planilha..."
	aBtn[01]:cTitle := ""

	DEFINE BUTTON aBtn[02] RESOURCE "FINAL" 		OF oBar GROUP ACTION oDlg:End() 												TOOLTIP "Sair da Tela..."
	aBtn[02]:cTitle := ""
	
	oDlg:lMaximized := .T.
	      
ACTIVATE MSDIALOG oDlg CENTERED

Return

/*
===============================================================================================================================
Programa----------: CGPE002HIS
Autor-------------: Alexandre Villar
Data da Criacao---: 23/04/2014
Descrição---------: Monta a estrutura de dados da consulta detalhada do histórico
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function CGPE002HIS( oLbxAux , cChave )

Local _cAlias 	:= GetNextAlias()
Local aLbxAux	:= {}
Local nTotReg   := 0

BeginSql alias _cAlias
	SELECT Z05.Z05_FILMAT, Z05.Z05_MATRIC, Z05.Z05_SEQ, SRA.RA_NOME, SRB.RB_NOME,
	       Z05.Z05_TIPO, Z05.Z05_ACAO, Z05.Z05_STATUS, Z05.Z05_DATA, Z05.Z05_HORA
	  FROM %Table:Z05% Z05
	 INNER JOIN %Table:SRA% SRA
	    ON SRA.RA_FILIAL = Z05.Z05_FILMAT
	   AND SRA.RA_MAT = Z05.Z05_MATRIC
	   AND SRA.D_E_L_E_T_ = ' '
	  LEFT OUTER JOIN %Table:SRB% SRB
	    ON SRB.RB_FILIAL = Z05.Z05_FILMAT
	   AND SRB.RB_MAT = Z05.Z05_MATRIC
	   AND SRB.RB_COD = Z05.Z05_SEQ
	   AND SRB.D_E_L_E_T_ = ' '
	 WHERE Z05.D_E_L_E_T_ = ' '
	   AND Z05.Z05_FILMAT || Z05.Z05_MATRIC = %Table:cChave%
	 ORDER BY Z05.Z05_ACAO, Z05.Z05_STATUS
EndSql

(_cAlias)->( DBEval( { || nTotReg++ } ) )

ProcRegua(nTotReg)

(_cAlias)->(DBGoTop())                                                                                   

While !(_cAlias)->( Eof() )
	
	If SubStr( (_cAlias)->( Z05_SEQ ) , 9 , 2 ) == "00"
		cNome := (_cAlias)->( RA_NOME )
	Else
		cNome := (_cAlias)->( RB_NOME )
	EndIf
	
	aAdd( aLbxAux ,	{	(_cAlias)->( Z05_FILMAT + Z05_MATRIC + Z05_SEQ	)	,; //01
						cNome											,; //02
						(_cAlias)->( Z05_TIPO							)	,; //03
						(_cAlias)->( Z05_ACAO							)	,; //04
						(_cAlias)->( Z05_STATUS						)	,; //05
						(_cAlias)->( Z05_DATA							)	,; //06
						(_cAlias)->( Z05_HORA							)	}) //07

	(_cAlias)->(DBSkip())
EndDo

(_cAlias)->(DBCloseArea())

If	Len(aLbxAux) > 0 .And. ValType(oLbxAux) == "O"
                     
	oLbxAux:SetArray(aLbxAux)
	oLbxAux:bLine:={||{		aLbxAux[oLbxAux:nAt][01]									,; // 01
		Capital( AllTrim(	aLbxAux[oLbxAux:nAt][02] ) )								,; // 02
				U_ITRetBox(	aLbxAux[oLbxAux:nAt][03] , "Z05_TIPO" )						,; // 03
				U_ITRetBox(	aLbxAux[oLbxAux:nAt][04] , "Z05_ACAO" )						,; // 04
				U_ITRetBox(	aLbxAux[oLbxAux:nAt][05] , "Z05_STATUS" )					,; // 05
			DToC( SToD (	aLbxAux[oLbxAux:nAt][06] ) )								,; // 06
							aLbxAux[oLbxAux:nAt][07] 									}} // 07

	oLbxAux:Refresh()

EndIf

Return

/*
===============================================================================================================================
Programa----------: CGPE002ITH
Autor-------------: Alexandre Villar
Data da Criacao---: 23/04/2014
Descrição---------: Recupera os dados dos itens do histórico
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function CGPE002ITH( oLbxAux , cChave )

Local _cAlias 	:= GetNextAlias()
Local aLbxAux	:= {}
Local nTotReg   := 0
Local nCont		:= 0

BeginSql alias _cAlias
	SELECT Z06.Z06_LOTE, Z06.Z06_CHAVE, Z06.Z06_ACAO, Z06.Z06_STATUS, Z06.Z06_OBS, Z06.Z06_DATA, Z06.Z06_HORA
	  FROM %Table:Z06% Z06
	 WHERE Z06.D_E_L_E_T_ = ' '
	   AND Z06.Z06_CHAVE = %exp:cChave%
	 ORDER BY Z06.Z06_DATA, Z06.Z06_HORA
EndSql

(_cAlias)->( DBEval( { || nTotReg++ } ) )
(_cAlias)->( DBGoTop() )
ProcRegua(nTotReg) // Regua

While !(_cAlias)->( Eof() )

		aAdd( aLbxAux , {(_cAlias)->Z06_LOTE					,; //01
  							(_cAlias)->Z06_CHAVE				,; //02
  				U_ITRetBox(	(_cAlias)->Z06_ACAO,"Z06_ACAO" )	,; //03
      			U_ITRetBox(	(_cAlias)->Z06_STATUS,"Z06_STATUS" ),; //04
				AllTrim(	(_cAlias)->Z06_OBS )				,; //05
    		DToC( SToD (	(_cAlias)->Z06_DATA ) )				,; //06
                         	(_cAlias)->Z06_HORA					}) //07

	nCont++
	IncProc("Montando estrutura "+StrZero(nCont,6)+" de "+StrZero(nTotReg,6)  )
	(_cAlias)->(DBSkip())
EndDo

(_cAlias)->(DBCloseArea())

If	Len(aLbxAux) > 0 .And. ValType(oLbxAux) == "O"
                     
	oLbxAux:SetArray(aLbxAux)
	oLbxAux:bLine:={||{	aLbxAux[oLbxAux:nAt][01] ,; //01
						aLbxAux[oLbxAux:nAt][02] ,; //02
						aLbxAux[oLbxAux:nAt][03] ,; //03
						aLbxAux[oLbxAux:nAt][04] ,; //04
						aLbxAux[oLbxAux:nAt][05] ,; //05
						aLbxAux[oLbxAux:nAt][06] ,; //06
						aLbxAux[oLbxAux:nAt][07] }} //07

	oLbxAux:Refresh()

EndIf

Return
