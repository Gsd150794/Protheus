/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |17/09/2019| Chamado 28346. Retirada chamada da função itputx1. 
Lucas Borges  |02/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25.
Alex Wallauer |23/10/2023| Chamado 45297. Ajuste da integração p/ inclusão de dependentes e agregados no plano odontológico.
===============================================================================================================================
*/

#Include "TOTVS.ch"

#Define		TITULO	"Gestão de Pessoal - Integração Plano de Saúde"

/*
===============================================================================================================================
Programa----------: MGPE009
Autor-------------: Alexandre Villar
Data da Criacao---: 21/02/2014
Descrição---------: Rotina de Integracao de Funcionarios x Plano de Saude. Chamado 5518
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MGPE009()

Local aInfoCustom 	:= {}
Local bProcess 		:= {|oSelf| MGPE009INI(oSelf) }
Local cNomeSema		:= "MGPE009SMF"
Local cPerg 		:= "MGPE009"
Local cHistRot		:= ""
Local lSemaforo		:= .F.
Local oProcess		:= Nil

Private lProcOk		:= .T.

cHistRot	:= "Essa rotina tem o objetivo de gerar/atualizar informações de Planos para os Funcionários cadastrados "
cHistRot	+= "no Sistema. Para continuar é recomendado verificar os Parâmetros clicando em 'Perguntas' no menu."

//===========================================================================
//| Inicia o Controle de Semaforo.                                          |
//===========================================================================
lSemaforo := MayIUseCode( cNomeSema , cUserName )

//===========================================================================
//| Verifica se a Rotina ja esta em uso.                                    |
//===========================================================================
If !lSemaforo
	MessageBox( "Essa rotina exige execução em modo exclusivo e nesse momento já está sendo utilizada por outro usuário." , TITULO , 0 )
	Return
EndIf

Pergunte(cPerg,.F.)
	
While lProcOk

	//===========================================================================
	//| Inicializa como .F. para nao reiniciar automaticamente.                 |
	//===========================================================================
	lProcOk := .F.
	
	oProcess := tNewProcess():New("MGPE009","Integração Funcionários x PLS",bProcess,cHistRot,cPerg,aInfoCustom,.T.,10,"Aguarde, fazendo a leitura dos dados...",.T.)
	
EndDo

Return

/*
===============================================================================================================================
Programa----------: MGPE009INI
Autor-------------: Alexandre Villar
Data da Criacao---: 21/02/2014
Descrição---------: Rotina de Controle do Processamento
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGPE009INI( oProcess )

Local aParAux		:= {} //Variavel que vai carregar a parametrizacao inicial

Private lGravaLog	:= GetMV( "IT_GRVLOG" ,, .F. ) //Caso necessario ativar o LOG de performance de processamento

//===========================================================================
//| Carrega os dados da Parametrizacao Inicial.                             |
//===========================================================================
aParAux := {	MV_PAR01								,; //01 - Filiais consideradas
				MGPE009FIL( MV_PAR02 , 2 )				,; //02 - Categorias Funcionais consideradas
				MGPE009FIL( MV_PAR03 , 3 )				,; //03 - Situacoes na Folha consideradas
				AllTrim( Str( MV_PAR10 ) )				,; //04 - Tipo de Pessoas consideradas (Funcionarios/Dependentes/Ambos)
				MV_PAR04								,; //05 - Centro de Custo Inicial
				MV_PAR05								,; //06 - Centro de Custo Final
				MV_PAR06								,; //07 - Matricula Inicial
				MV_PAR07								,; //08 - Matricula Final
				AllTrim( Str(MV_PAR11) )				,; //09 - Tipo de Servico
				MV_PAR12								,; //10 - Fornecedor do Servico
				AllTrim( Str(MV_PAR13) )				,; //11 - Tipo do Plano
				MV_PAR14								,; //12 - Codigo do Plano
				MV_PAR15								,; //13 - Verba para o Titular
				MV_PAR16								,; //14 - Verba para os Dependentes
				MV_PAR08								,; //15 - Data Admissao Inicial
				MV_PAR09								 } //16 - Data Admissao Final

//===========================================================================
//| Gravacao do Log - se estiver ativo.                                     |
//===========================================================================
If	lGravaLog

	PlsLogFil(""															,cDvArqLog)
	PlsLogFil("------- I N I C I O  D O  P R O C E S S A M E N T O -------"	,cDvArqLog)
	PlsLogFil("DATABASE...........: " + DToC( dDataBase ) 					,cDvArqLog)
	PlsLogFil("DATA...............: " + DToC( Date() ) 						,cDvArqLog)
	PlsLogFil("HORA...............: " + Time() 								,cDvArqLog)
	PlsLogFil("ENVIRONMENT........: " + GetEnvServer() 						,cDvArqLog)
	PlsLogFil("PATCH..............: " + GetSrvProfString( 'StartPath', '' )	,cDvArqLog)
	PlsLogFil("ROOT...............: " + GetSrvProfString( 'RootPath', '' )	,cDvArqLog)
	PlsLogFil("VERSÃO.............: " + GetVersao() 						,cDvArqLog)
	PlsLogFil("MÓDULO.............: " + 'SIGA' + cModulo 					,cDvArqLog)
	PlsLogFil("EMPRESA / FILIAL...: " + SM0->M0_CODIGO+"/"+AllTrim(SM0->M0_CODFIL)	,cDvArqLog)
	PlsLogFil("NOME EMPRESA.......: " + Capital( Trim( SM0->M0_NOME ) ) 	,cDvArqLog)
	PlsLogFil("NOME FILIAL........: " + Capital( Trim( SM0->M0_FILIAL ) ) 	,cDvArqLog)
	PlsLogFil("USUÁRIO............: " + SubStr( cUsuario, 7, 15 ) 			,cDvArqLog)
	PlsLogFil("ARQUIVO DE LOG.....: " + cDvArqLog							,cDvArqLog)
	PlsLogFil("-----------------------------------------------------------"	,cDvArqLog)
	
EndIf

//===========================================================================
//| Inicia a Rotina de controle de processamento.                           |
//===========================================================================
MGPE009DLG( aParAux , oProcess )

//===========================================================================
//| Marca como .F. para nao reiniciar automaticamente.                      |
//===========================================================================
lProcOk := .F.

Return

/*
===============================================================================================================================
Programa----------: MGPE009DLG
Autor-------------: Alexandre Villar
Data da Criacao---: 21/02/2014
Descrição---------: Monta a DIALOG para o processamento quando a rotina For executada do Menu
Parametros--------: aParAux - Parametrização inical da Rotina
------------------: oProcess - Controle do processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGPE009DLG( aParAux , oProcess )

Local oDlg			:= Nil
Local oFolder01		:= Nil
Local aPagesRes 	:= {}
Local aTitFol		:= { "Funcionários" , "Dependentes" }
Local nRegAtu		:= 0
Local nRegTot		:= Len( aTitFol )
Local oLbxDados		:= Array( nRegTot )
Local nI			:= 0
Local aCoord01		:= {}

Local nTempoX		:= 0
Local nAux			:= 0

Local aPosObj   	:= {}
Local aObjects  	:= {}
Local aSize     	:= MsAdvSize()
Local bDados		:= {|| MGPE009SEL( @oLbxDados[oFolder01:nOption] , oFolder01:nOption , aParAux , oProcess ) }
Local oTotFun		:= { Nil , Nil , Nil }
Local aTotFun		:= { Nil , Nil , Nil }
Local oTotDep		:= { Nil , Nil , Nil }
Local aTotDep		:= { Nil , Nil , Nil }

Local aColTot		:= {}

Local bOk			:= {|x| ( Processa( {|lEnd| MGPE009PRO( oLbxDados , aParAux ) } ) , oDlg:End() ) }
Local bCancel		:= {|x| oDlg:End() }
Local bExpExcel 	:= {|| DlgToExcel( { { "ARRAY" , "" , oLbxDados[oFolder01:nOption]:AHeaders , oLbxDados[oFolder01:nOption]:aArray } } ) }
Local aButtons		:= {}
Local bCountTot 	:= {|| Processa( {|| MGPE009CON( oLbxDados[oFolder01:nOption] , @aTotFun , @aTotDep , @oTotFun , @oTotDep ) }			, "Processando..." , , .F. ) }
Local bCountIte 	:= {|| Processa( {|| MGPE009CIT( oLbxDados[oFolder01:nOption] , @aTotFun , @aTotDep , @oTotFun , @oTotDep , nAux ) }	, "Processando..." , , .F. ) }

Local aCabecLbx		:= {	"Sel."				,; //01
                          	"Filial"			,; //02
                         	"Matrícula"			,; //03
                         	"Sequência"			,; //04
                         	"Tipo"				,; //05
	                        "Nome"	 			,; //06
	                        "Data Admis."		,; //07
	                        "Data Nasc."		,; //08
	                        "Grau Parentesco"	,; //09
	                        "Nome Titular"		 } //10

Private	cCadastro	:= "Execução da Integração - Funcionários x PLS"
Private oOk			:= LoadBitmap( Nil , "ngcheckok"	)
Private oNo			:= LoadBitmap( Nil , "ngcheckno"	)

aAdd( aObjects, { 100, 052, .T., .T. } )
aAdd( aObjects, { 100, 048, .T., .F. } )

aInfo   := { aSize[ 1 ] , aSize[ 2 ] , aSize[ 3 ] , aSize[ 4 ] , 3 , 2 }
aPosObj := MsObjSize( aInfo , aObjects )

//===========================================================================
//| Definicoes de fontes da Rotina.                                         |
//===========================================================================
DEFINE FONT oBold NAME "Arial" 			SIZE 0,-12 BOLD

//===========================================================================
//| Inclui chamada de Exportacao para Excel no aRotina.                     |
//===========================================================================
aAdd(aButtons,{PmsBExcel()[1],bExpExcel,"Exportar dados para Excel...",PmsBExcel()[3]})

//===========================================================================
//| Montagem do Dialog principal.                                           |
//===========================================================================
DEFINE MSDIALOG oDlg TITLE cCadastro From aSize[7],00 to aSize[6],aSize[5] Of oMainWnd Pixel

	//===========================================================================
	//| Inicia o Objeto dos Folders.                                            |
	//===========================================================================
	oFolder01 := TFolder():New( aPosObj[1,1] , aPosObj[1,2] , aTitFol , aPagesRes , oDlg ,,,, .T. , .F. , aPosObj[1,4]-aPosObj[1,2] , aPosObj[1,3]-aPosObj[1,1] , )

	//===========================================================================
	//| Identifica as Coordenadas de posicionamento da tela.                    |
	//===========================================================================
	aCoord01 := MGPE009COB( oFolder01:aDialogs[oFolder01:nOption] )
	
	//===========================================================================
	//| Inicializa a Regua de Processamento.                                    |
	//===========================================================================
	oProcess:SetRegua1(nRegTot)
			
	//===========================================================================
	//| Processa a inicializacao e o carregamento dos Folders.                  |
	//===========================================================================
	For	nI := 1 To nRegTot
		
		nRegAtu++

		oProcess:IncRegua1( AllTrim(aTitFol[nI]) + " [ " + StrZero(nRegAtu,2) + " de " + StrZero(nRegTot,2) + " ] " + Space(10) + "Inicio: " + Time() )
		oProcess:IncRegua2( "Iniciando o processamento, aguarde..." )
		
		//===========================================================================
		//| Inicializa o Folder para a montagem do ListBox.                         |
		//===========================================================================
		oFolder01:nOption := nI
	
		@aCoord01[01] , aCoord01[02]	Listbox oLbxDados[oFolder01:nOption] Fields		;
										HEADER	AllTrim( aTitFol[nI] )					;
										On		DbLCLICK( MGPE009DBC( @oLbxDados , oFolder01:nOption , @nAux ) , Eval(bCountIte) ) ;
										Size	aCoord01[04],(( aCoord01[03] - aCoord01[01] ) - 30)  Of oFolder01:aDialogs[oFolder01:nOption] Pixel
						
		oLbxDados[oFolder01:nOption]:AHeaders		:= aClone(aCabecLbx)
		oLbxDados[oFolder01:nOption]:bChange		:= {|| Nil }
		oLbxDados[oFolder01:nOption]:nFreeze		:= 2
		
		//===========================================================================
		//| Inicia a gravacao do Log de Processamento se estiver ativo.             |
		//===========================================================================
		If lGravaLog
		
			nTempoX := Seconds()
			PlsLogFil("",cDvArqLog)
			PlsLogFil("-> Inicio Folder...: " + AllTrim( aTitFol[nI] ) , cDvArqLog )
			PlsLogFil("...................: Iniciado......................................................................: "+ ;
						"Data : " + DToC(Date()) + " Hora : " + Time() , cDvArqLog )
			
		EndIf
		
		//===========================================================================
		//| Processa a leitura dos dados e a montagem do Objeto.                    |
		//===========================================================================
		Eval(bDados)
		
		//===========================================================================
		//| Fecha a gravacao do Log do processamento atual.                         |
		//===========================================================================
		If	lGravaLog
			PlsLogFil("-> Fim Folder......: " + AllTrim( aTitFol[nI] ) , cDvArqLog )
			PlsLogFil("...................: Rotina Executada em...........................................................: "+ ;
						Str((Seconds()-nTempoX),10,0) + " segundos." , cDvArqLog )
		EndIf
		
	Next nI
	
	//===========================================================================
	//| Identifica o posicionamento para o rodape do Folder Atual.              |
	//===========================================================================
	aColTot := { aPosObj[2,2] , aPosObj[2,4]*0.25 , aPosObj[2,4]*0.50 , aPosObj[2,4]*0.75 , aPosObj[2,4] } 

	//===========================================================================
	//| Insere a legenda do Folder.                                             |
	//===========================================================================
	@aPosObj[2,1] , aColTot[01] Say AllTrim( aTitFol[oFolder01:nOption] ) SIZE 600,09 COLOR CLR_HBLUE OF oDlg PIXEL

	//===========================================================================
	//| Inclusao dos Controles/Totalizadores.                                   |
	//===========================================================================
	@aPosObj[2,1]+010 , aColTot[01]+0 To aPosObj[2,3],aColTot[02] LABEL "Seleção"   		COLOR CLR_HBLUE OF oDlg PIXEL
	@aPosObj[2,1]+010 , aColTot[02]+5 To aPosObj[2,3],aColTot[03] LABEL "Desmarcado(s)"		COLOR CLR_HBLUE OF oDlg PIXEL
	@aPosObj[2,1]+010 , aColTot[03]+5 To aPosObj[2,3],aColTot[04] LABEL "Marcado(s)"		COLOR CLR_HBLUE OF oDlg PIXEL
	@aPosObj[2,1]+010 , aColTot[04]+5 To aPosObj[2,3],aColTot[05] LABEL "Totais" 			COLOR CLR_HBLUE OF oDlg PIXEL
	
	//===========================================================================
	//| Botoes de Acoes de Selecao.                                             |
	//===========================================================================
	oTButton1 := TButton():New( aPosObj[2,1]+017 , 010 , "Marca Titulares"			, oDlg , ;
	{|| LjMsgRun( "Atualizando as marcações..." , "Aguarde!" , {|| U_MGPEMOK( 1 , @oLbxDados[oFolder01:nOption] , .T. ) , Eval(bCountTot) } ) } , ;
	070,010,,,.F.,.T.,.F.,,.F.,,,.F. )
	
	oTButton2 := TButton():New( aPosObj[2,1]+017 , 085 , "Desmarca Titulares"		, oDlg , ;
	{|| LjMsgRun( "Atualizando as marcações..." , "Aguarde!" , {|| U_MGPEMOK( 1 , @oLbxDados[oFolder01:nOption] , .F. ) , Eval(bCountTot) } ) } , ;
	070,010,,,.F.,.T.,.F.,,.F.,,,.F. )
	
	oTButton3 := TButton():New( aPosObj[2,1]+027 , 010 , "Marca Dependentes"		, oDlg , ;
	{|| LjMsgRun( "Atualizando as marcações..." , "Aguarde!" , {|| U_MGPEMOK( 2 , @oLbxDados[oFolder01:nOption] , .T. ) , Eval(bCountTot) } ) } , ;
	070,010,,,.F.,.T.,.F.,,.F.,,,.F. )
	
	oTButton4 := TButton():New( aPosObj[2,1]+027 , 085 , "Desmarca Dependentes"	, oDlg , ;
	{|| LjMsgRun( "Atualizando as marcações..." , "Aguarde!" , {|| U_MGPEMOK( 2 , @oLbxDados[oFolder01:nOption] , .F. ) , Eval(bCountTot) } ) } , ;
	070,010,,,.F.,.T.,.F.,,.F.,,,.F. )

	oTButton5 := TButton():New( aPosObj[2,1]+037 , 010 , "Marca Todos"				, oDlg , ;
	{|| LjMsgRun( "Atualizando as marcações..." , "Aguarde!" , {|| U_MGPEMOK( 3 , @oLbxDados[oFolder01:nOption] , .T. ) , Eval(bCountTot) } ) } , ;
	070,010,,,.F.,.T.,.F.,,.F.,,,.F. )
	
	oTButton6 := TButton():New( aPosObj[2,1]+037 , 085 , "Desmarca Todos"			, oDlg , ;
	{|| LjMsgRun( "Atualizando as marcações..." , "Aguarde!" , {|| U_MGPEMOK( 3 , @oLbxDados[oFolder01:nOption] , .F. ) , Eval(bCountTot) } ) } , ;
	070,010,,,.F.,.T.,.F.,,.F.,,,.F. )

	//===========================================================================
	//| Objetos dos Totalizadores.                                              |
	//===========================================================================
	//-- Desmarcados --//
	@aPosObj[2,1]+20,aColTot[02]+010	Say "Funcionários:"												SIZE 040,009 COLOR CLR_HRED 	OF oDlg PIXEL
	@aPosObj[2,1]+20,aColTot[02]+052	Say oTotFun[1] VAR Transform( aTotFun[1] , "@E 999,999,999" )	SIZE 100,009  FONT oBold 		OF oDlg PIXEL
	
	@aPosObj[2,1]+33,aColTot[02]+010	Say "Dependentes:"												SIZE 040,009 COLOR CLR_HRED 	OF oDlg PIXEL
	@aPosObj[2,1]+33,aColTot[02]+052	Say oTotDep[1] VAR Transform( aTotDep[1] , "@E 999,999,999" )	SIZE 100,009  FONT oBold 		OF oDlg PIXEL

	//-- Marcados --//
	@aPosObj[2,1]+20,aColTot[03]+010	Say "Funcionários:"												SIZE 040,009 COLOR CLR_HRED 	OF oDlg PIXEL
	@aPosObj[2,1]+20,aColTot[03]+052	Say oTotFun[2] VAR Transform( aTotFun[2] , "@E 999,999,999" )	SIZE 100,009  FONT oBold 		OF oDlg PIXEL
	
	@aPosObj[2,1]+33,aColTot[03]+010	Say "Dependentes:"												SIZE 040,009 COLOR CLR_HRED 	OF oDlg PIXEL
	@aPosObj[2,1]+33,aColTot[03]+052	Say oTotDep[2] VAR Transform( aTotDep[2] , "@E 999,999,999" )	SIZE 100,009  FONT oBold  		OF oDlg PIXEL
	
	//-- Totais --//
	@aPosObj[2,1]+20,aColTot[04]+010	Say "Funcionários:"											 	SIZE 040,009 COLOR CLR_HRED 	OF oDlg PIXEL
	@aPosObj[2,1]+20,aColTot[04]+052	Say oTotFun[3] VAR Transform( aTotFun[3] , "@E 999,999,999" )	SIZE 100,009  FONT oBold 		OF oDlg PIXEL
	
	@aPosObj[2,1]+33,aColTot[04]+010	Say "Dependentes:"												SIZE 040,009 COLOR CLR_HRED 	OF oDlg PIXEL
	@aPosObj[2,1]+33,aColTot[04]+052	Say oTotDep[3] VAR Transform( aTotDep[3] , "@E 999,999,999" )	SIZE 100,009  FONT oBold	 	OF oDlg PIXEL
	
	//===========================================================================
	//| Define acao da mudanca de Folder e inicaliza os contadores.             |
	//===========================================================================
	Eval(bCountTot)
	oFolder01:bChange	:= ( { |nFolder| Eval(bCountTot) } )
	oFolder01:nOption	:= 1
	oDlg:lMaximized		:= .T.
	
//===========================================================================
//| Ativa o Dialog.                                                         |
//===========================================================================
ACTIVATE MSDIALOG oDlg	ON INIT EnchoiceBar(oDlg,bOk,bCancel,,aButtons) CENTERED
	
Return

/*
===============================================================================================================================
Programa----------: MGPE009DLG
Autor-------------: Alexandre Villar
Data da Criacao---: 21/02/2014
Descrição---------: Monta a DIALOG para o processamento quando a rotina For executada do Menu
Parametros--------: oLbxAux := Objeto de dados que sera carregado no Dialog.
------------------: aParAux := Ordem da execução atual.
------------------: aParAux := Parametrização do Wizard.
------------------: oProcess:= Controle do Processamento.
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGPE009SEL( oLbxAux , nOrdExe , aParAux , oProcess )

Local nRegAtu		:= 0
Local nDiasCad		:= GetMV( "IT_DIASPLA" ,, 90 )
Local aLbxAux		:= {}
Local cQuery 		:= ""
Local cAlias		:= GetNextAlias()

//===========================================================================
//| Inicializa o Log do Processamento.                                      |
//===========================================================================
If	lGravaLog
	PlsLogFil("...................: Iniciando Montagem do Select..................................................: "+;
				DToC(Date())+" - "+Time(),cDvArqLog)
	nTempoX := Seconds()
EndIf

//===========================================================================
//| Verifica o Controle da Rotina de Selecao (Funcionario/Dependente/Ambos) |
//===========================================================================
If nOrdExe == 1 .And. ( aParAux[04] == "1" .Or. aParAux[04] == "3" ) // Verifica se Considera Funcionarios ou Ambos

	//===========================================================================
	//| Monta a Consulta dos Funcionarios que nao tem o Plano atual.            |
	//===========================================================================
	cQuery := " SELECT "
	cQuery += " 	SRA.RA_FILIAL	AS FILIAL, " 
	cQuery += " 	SRA.RA_MAT		AS MATRICULA, " 
	cQuery += " 	'00'			AS SEQ, " 
	cQuery += " 	'TITULAR'		AS TIPO, " 
	cQuery += " 	SRA.RA_NOME		AS NOME, " 
	cQuery += " 	SRA.RA_ADMISSA	AS DT_ADM, " 
	cQuery += " 	SRA.RA_NASC		AS DT_NASC, "
	cQuery += "		''				AS GRAUPAR, " 
	cQuery += " 	''				AS NOME_TIT, " 
	cQuery += " 	SRA.R_E_C_N_O_	AS REGTAB " 
	cQuery += " FROM "+RetSqlName("SRA")+" SRA "
	cQuery += " WHERE "
	cQuery += " 		SRA.D_E_L_E_T_	= ' ' "
	cQuery += " AND		SRA.RA_FILIAL	IN "+ FormatIn( aParAux[01] , ";" )										//Filtra por Filiais
	cQuery += " AND		SRA.RA_CATFUNC	IN "+ FormatIn( aParAux[02] , ";" )										//Filtra por Categorias Funcionais
	cQuery += " AND		SRA.RA_SITFOLH	IN "+ FormatIn( aParAux[03] , ";" )										//Filtra por Situacoes na Folha
	cQuery += " AND		SRA.RA_CC		BETWEEN '"+ aParAux[05]			+"' AND '"+ aParAux[06] +"' "			//Filtra por Centro de Custo
	cQuery += " AND		SRA.RA_MAT		BETWEEN '"+ aParAux[07]			+"' AND '"+ aParAux[08] +"' "  			//Filtra por Matricula
	cQuery += " AND		SRA.RA_ADMISSA	BETWEEN '"+ DToS( aParAux[15] )	+"' AND '"+ DToS( aParAux[16] ) +"' "	//Filtra por Data de Admissao
	cQuery += " AND		SRA.RA_ADMISSA	<= '"+ DToS( dDataBase - nDiasCad ) +"' "					  			//Filtra Funcionarios em Periodo de Experiencia
	cQuery += " AND		NOT EXISTS	( 	SELECT	RHK.RHK_MAT FROM "+ RetSqlName("RHK") +" RHK "
	cQuery += "							WHERE	RHK.D_E_L_E_T_	= ' ' "
	cQuery += "							AND		RHK.RHK_FILIAL	= SRA.RA_FILIAL "
	cQuery += "							AND		RHK.RHK_MAT		= SRA.RA_MAT "
	cQuery += "							AND		RHK.RHK_TPFORN	= '"+ aParAux[09] +"' "
	cQuery += "							AND		RHK.RHK_CODFOR	= '"+ aParAux[10] +"' "
	cQuery += "							AND		RHK.RHK_TPPLAN	= '"+ aParAux[11] +"' "
	cQuery += "							AND		RHK.RHK_PLANO	= '"+ aParAux[12] +"' ) "
	
	If aParAux[04] == "3"
		
		//===========================================================================
		//| Caso deva considerar os Dependentes adiciona a consulta principal.      |
		//===========================================================================
		cQuery += " UNION ALL "
		
		cQuery += " SELECT "
		cQuery += " 	SRB.RB_FILIAL   AS FILIAL, "
		cQuery += " 	SRB.RB_MAT      AS MATRICULA, "
		cQuery += " 	SRB.RB_COD      AS SEQ, "
		cQuery += " 	'DEPENDENTE'    AS TIPO, "
		cQuery += " 	SRB.RB_NOME     AS NOME, "
		cQuery += "		''				AS DT_ADM, " 
		cQuery += " 	SRB.RB_DTNASC   AS DT_NASC, "
		cQuery += "		SRB.RB_GRAUPAR	AS GRAUPAR, "
		cQuery += " 	SRA.RA_NOME     AS NOME_TIT, "
		cQuery += " 	SRB.R_E_C_N_O_  AS REGTAB "
		cQuery += " FROM "+RetSqlName("SRB")+" SRB "
		
		cQuery += " INNER JOIN "+RetSqlName("SRA")+" SRA "
		cQuery += " ON "
		cQuery += "			SRB.RB_FILIAL	= SRA.RA_FILIAL "
		cQuery += " AND		SRB.RB_MAT		= SRA.RA_MAT "
		cQuery += " AND		SRA.RA_FILIAL	IN "+ FormatIn( aParAux[01] , ";" )										//Filtra por Filiais
		cQuery += " AND		SRA.RA_CATFUNC	IN "+ FormatIn( aParAux[02] , ";" )										//Filtra por Categorias Funcionais
		cQuery += " AND		SRA.RA_SITFOLH	IN "+ FormatIn( aParAux[03] , ";" )										//Filtra por Situacoes na Folha
		cQuery += " AND		SRA.RA_CC		BETWEEN '"+ aParAux[05]			+"' AND '"+ aParAux[06] +"' "			//Filtra por Centro de Custo
		cQuery += " AND		SRA.RA_MAT		BETWEEN '"+ aParAux[07]			+"' AND '"+ aParAux[08] +"' "			//Filtra por Matricula
		cQuery += " AND		SRA.RA_ADMISSA	BETWEEN '"+ DToS( aParAux[15] )	+"' AND '"+ DToS( aParAux[16] ) +"' "	//Filtra por Data de Admissao
		cQuery += " AND		SRA.RA_ADMISSA	<= '"+ DToS( dDataBase - nDiasCad ) +"' "								//Filtra Funcionarios em Periodo de Experiencia
		
		cQuery += " WHERE	SRB.D_E_L_E_T_	= ' ' "
		cQuery += " AND		SRA.D_E_L_E_T_	= ' ' "
		
		cQuery += " AND		NOT EXISTS	(	SELECT RHK.RHK_MAT FROM "+ RetSqlName("RHK") +" RHK "
		cQuery += " 						WHERE	RHK.D_E_L_E_T_	= ' '  "
		cQuery += " 						AND		RHK.RHK_FILIAL	= SRA.RA_FILIAL  "
		cQuery += " 						AND		RHK.RHK_MAT		  = SRA.RA_MAT  "
		cQuery += " 						AND		RHK.RHK_TPFORN	= '"+ aParAux[09] +"'  "
		cQuery += " 						AND		RHK.RHK_CODFOR	= '"+ aParAux[10] +"'  "
		cQuery += " 						AND		RHK.RHK_TPPLAN	= '"+ aParAux[11] +"'  "
		cQuery += " 						AND		RHK.RHK_PLANO   = '"+ aParAux[12] +"' ) "
		
		cQuery += " AND		NOT EXISTS	(	SELECT RHL.RHL_MAT FROM "+ RetSqlName("RHL") +" RHL "
		cQuery += " 						WHERE	RHL.D_E_L_E_T_	= ' '  "
		cQuery += " 						AND		RHL.RHL_FILIAL	= SRB.RB_FILIAL  "
		cQuery += " 						AND		RHL.RHL_MAT		  = SRB.RB_MAT  "
		cQuery += " 						AND   	RHL.RHL_CODIGO  = SRB.RB_COD "
		cQuery += " 						AND		RHL.RHL_TPFORN	= '"+ aParAux[09] +"'  "
		cQuery += " 						AND		RHL.RHL_CODFOR	= '"+ aParAux[10] +"'  "
		cQuery += " 						AND		RHL.RHL_TPPLAN	= '"+ aParAux[11] +"'  "
		cQuery += " 						AND		RHL.RHL_PLANO   = '"+ aParAux[12] +"' )  "
	 	
	EndIf
	
	cQuery += " ORDER BY FILIAL, MATRICULA, SEQ "
	
	//===========================================================================
	//| Gravacao do Log.                                                        |
	//===========================================================================
	If	lGravaLog
		PlsLogFil("...................: Finalizou Montagem do Select em...............................................: "+;
					AllTrim(Str((Seconds()-nTempoX),10,0))+" Segundo(s)",cDvArqLog)
		PlsLogFil("...................: Iniciando Criação do TRB......................................................: "+;
					DToC(Date())+" - "+Time(),cDvArqLog)
		nTempoX := Seconds()
	EndIf

//===========================================================================
//| Verifica o Controle da Rotina de Selecao (Funcionario/Dependente/Ambos) |
//===========================================================================
ElseIf nOrdExe == 2 .And. ( aParAux[04] == "2" .Or. aParAux[04] == "3" )
	
	//===========================================================================
	//| Monta a Consulta dos Dependentes de Funcionarios que ja tem o plano.    |
	//===========================================================================
	cQuery := " SELECT "
	cQuery += " 	SRB.RB_FILIAL   AS FILIAL, "
	cQuery += " 	SRB.RB_MAT      AS MATRICULA, "
	cQuery += " 	SRB.RB_COD      AS SEQ, "
	cQuery += " 	'DEPENDENTE'    AS TIPO, "
	cQuery += " 	SRB.RB_NOME     AS NOME, "
	cQuery += "		''				AS DT_ADM, "
	cQuery += " 	SRB.RB_DTNASC   AS DT_NASC, "
	cQuery += "		SRB.RB_GRAUPAR	AS GRAUPAR, "
	cQuery += " 	SRA.RA_NOME     AS NOME_TIT, "
	cQuery += " 	SRB.R_E_C_N_O_  AS REGTAB "
	cQuery += " FROM		"+ RetSqlName("SRB") +" SRB "
	
	cQuery += " INNER JOIN	"+ RetSqlName("SRA") +" SRA "
	cQuery += " ON "
	cQuery += " 		SRB.RB_FILIAL	= SRA.RA_FILIAL "
	cQuery += " AND		SRB.RB_MAT		= SRA.RA_MAT "
	cQuery += " AND		SRA.RA_CATFUNC	IN "+ FormatIn( aParAux[02] , ";" )										//Filtra por Categorias Funcionais
	cQuery += " AND		SRA.RA_SITFOLH	IN "+ FormatIn( aParAux[03] , ";" )										//Filtra por Situacoes na Folha
	cQuery += " AND		SRA.RA_CC		BETWEEN '"+ aParAux[05]			+"' AND '"+ aParAux[06] +"' "			//Filtra por Centro de Custo
	cQuery += " AND		SRA.RA_ADMISSA	BETWEEN '"+ DToS( aParAux[15] )	+"' AND '"+ DToS( aParAux[16] ) +"' "	//Filtra por Data de Admissao
	cQuery += " AND		SRA.RA_ADMISSA	<= '"+ DToS( dDataBase - nDiasCad ) +"' "								//Filtra Funcionarios em Periodo de Experiencia
	
	cQuery += " INNER JOIN	"+ RetSqlName("RHK") +" RHK "
	cQuery += " ON "
	cQuery += " 		SRA.RA_FILIAL	= RHK.RHK_FILIAL "
	cQuery += " AND		SRA.RA_MAT		= RHK.RHK_MAT "
	cQuery += " AND		RHK.RHK_TPFORN	= '"+ aParAux[09] +"' "		//Valida o Tipo de Fornecedor do Titular
	cQuery += " AND		RHK.RHK_CODFOR	= '"+ aParAux[10] +"' "		//Valida o Fornecedor do Titular
	cQuery += " AND		RHK.RHK_TPPLAN	= '"+ aParAux[11] +"' "		//Valida o Tipo de Plano do Titular
	cQuery += " AND		RHK.RHK_PLANO	= '"+ aParAux[12] +"' "		//Valida o Plano do Titular
	
	cQuery += " WHERE	SRB.D_E_L_E_T_	= ' ' "
	cQuery += " AND		SRA.D_E_L_E_T_	= ' ' "
	cQuery += " AND		RHK.D_E_L_E_T_	= ' ' "
	cQuery += " AND		SRB.RB_FILIAL	IN "+ FormatIn( aParAux[01] , ";" )								//Filtra por Filial
	cQuery += " AND		SRB.RB_MAT		BETWEEN '"+ aParAux[07]		+"' AND '"+ aParAux[08] +"' "		//Filtra por Matricula
	cQuery += " AND		NOT EXISTS (	SELECT	RHL.RHL_MAT "
	cQuery += " 						FROM	"+ RetSqlName("RHL") +" RHL "
	cQuery += " 						WHERE	RHL.D_E_L_E_T_	= ' ' "
	cQuery += " 						AND		RHL.RHL_FILIAL	= SRB.RB_FILIAL "
	cQuery += " 						AND		RHL.RHL_MAT		= SRB.RB_MAT "
	cQuery += " 						AND		RHL.RHL_CODIGO	= SRB.RB_COD "
	cQuery += "							AND		RHL.RHL_TPFORN	= '"+ aParAux[09] +"' "		//Valida o Tipo de Fornecedor do Dependente
	cQuery += " 						AND		RHL.RHL_CODFOR	= '"+ aParAux[10] +"' "		//Valida o Fornecedor do Dependente
	cQuery += " 						AND		RHL.RHL_TPPLAN	= '"+ aParAux[11] +"' "		//Valida o Tipo de Plano do Dependente
	cQuery += " 						AND		RHL.RHL_PLANO	= '"+ aParAux[12] +"' ) "	//Valida o Plano do Dependente
	
	cQuery += " ORDER BY FILIAL, MATRICULA, SEQ "
	
	//===========================================================================
	//| Gravacao do Log.                                                        |
	//===========================================================================
	If	lGravaLog
		PlsLogFil("...................: Finalizou Montagem do Select em...............................................: "+ AllTrim(Str((Seconds()-nTempoX),10,0))+" Segundo(s)",cDvArqLog)
		PlsLogFil("...................: Iniciando Criação do TRB......................................................: "+ DToC(Date())+" - "+Time(),cDvArqLog)
		nTempoX := Seconds()
	EndIf

EndIf

If Empty(cQuery)
	Return
EndIf

//===========================================================================
// Verifica o Alias temporario e inicializa a consulta.
//===========================================================================
If Select(cAlias) > 0
	(cAlias)->( DBCloseArea() )
EndIf

DBUseArea( .T. , "TOPCONN" , TCGenQry(,,cQuery) , cAlias , .F. , .T. )

//===========================================================================
// Gravacao do Log.
//===========================================================================
If	lGravaLog
	PlsLogFil("...................: Finalizou Criação do TRB em...................................................: "+;
				AllTrim(Str((Seconds()-nTempoX),10,0))+" Segundo(s)",cDvArqLog)
	PlsLogFil("...................: Ativando TRB para leitura dos dados...........................................: "+;
				DToC(Date())+" - "+Time(),cDvArqLog)
	nTempoX := Seconds()
EndIf

//===========================================================================
// Inicializa os contadores.
//===========================================================================
nTotReg	:= 0
nRegAtu	:= 0

//===========================================================================
// Conta os Registros do Alias.
//===========================================================================
DBSelectArea(cAlias)
(cAlias)->( DBGoTop() )

//===========================================================================
// Gravacao do Log.
//===========================================================================
If	lGravaLog
	PlsLogFil("...................: Ativou e Selecionou TRB no Primeiro Arquivo em................................: "+;
				AllTrim(Str((Seconds()-nTempoX),10,0))+" Segundo(s)",cDvArqLog)
	PlsLogFil("...................: Iniciando Contagem dos Registros..............................................: "+;
				DToC(Date())+" - "+Time(),cDvArqLog)
	nTempoX := Seconds()
EndIf

(cAlias)->( DBEval( {|| nTotReg++ } ))
(cAlias)->( DBGoTop() )

//===========================================================================
// Define o processo da Regua.
//===========================================================================
oProcess:SetRegua2(nTotReg)

//===========================================================================
// Gravacao do Log.
//===========================================================================
If	lGravaLog
	PlsLogFil("...................: Finalizou Contagem dos Registros em...........................................: "+;
				AllTrim(Str((Seconds()-nTempoX),10,0))+" Segundo(s)",cDvArqLog)
	PlsLogFil("...................: Iniciando Processamento dos Dados.............................................: "+;
				DToC(Date())+" - "+Time(),cDvArqLog)
	nTempoX := Seconds()
EndIf

//===========================================================================
// Processamento dos dados selecionados.
//===========================================================================
While (cAlias)->(!Eof())
	
	nRegAtu++
	oProcess:IncRegua2( "Analisando Registros: ["+StrZero(nRegAtu,6)+"] de ["+StrZero(nTotReg,6)+"]." )
	
	//===========================================================================
	// Gravacao dos dados em Array para inicializacao do Objeto ListBox.
	//===========================================================================
   	aAdd( aLbxAux , {	.F. 																													,; //"Selecionado		|01
						AllTrim( (cAlias)->FILIAL )																								,; //"Filial"			|02
						AllTrim( (cAlias)->MATRICULA )																							,; //"Matricula"		|03
					   	AllTrim( (cAlias)->SEQ )																								,; //"Sequencia"	 	|04
						AllTrim( (cAlias)->TIPO )															 									,; //"Tipo"			 	|05
						AllTrim( (cAlias)->NOME ) 		  																						,; //"Nome"				|06
						DToC( SToD( (cAlias)->DT_ADM  ) ) 	 																					,; //"Dt. Admissao"		|07
						DToC( SToD( (cAlias)->DT_NASC ) )							 															,; //"Dt. Nascimento"	|08
						AllTrim( IIf( Empty( (cAlias)->GRAUPAR ) , "Titular" , U_ITRetBox( AllTrim( (cAlias)->GRAUPAR ) , "RB_GRAUPAR" ) ) )	,; //"Grau Parentesco"	|09
						AllTrim( (cAlias)->NOME_TIT )			 																				,; //"Nome Titular"		|10
						AllTrim( (cAlias)->REGTAB )																								}) //"Recno"			|11
    
(cAlias)->( DBSkip() )
EndDo
                       
//===========================================================================
// Encerra o Alias temporario.
//===========================================================================
(cAlias)->(DBCloseArea())

//===========================================================================
// Gravacao do Log.
//===========================================================================
If	lGravaLog
	PlsLogFil("...................: Finalizou Processamento dos Dados em..........................................: "+;
				AllTrim(Str((Seconds()-nTempoX),10,0))+" Segundo(s)",cDvArqLog)
	PlsLogFil("...................: Iniciando Carregamento dos Dados no Objeto oLbx...............................: "+;
				DToC(Date())+" - "+Time(),cDvArqLog)
	nTempoX := Seconds()
EndIf

//===========================================================================
// Inicializa o Objeto ListBox e carrega os dados.
//===========================================================================
If	Len(aLbxAux) > 0 .And. ValType(oLbxAux) == "O"

	oLbxAux:SetArray(aLbxAux)
	
	oLbxAux:bLine:={||{		IIf(	aLbxAux[oLbxAux:nAt][01] , oOk , oNo )				,; //Selecao
									aLbxAux[oLbxAux:nAt][02] 							,; //Filial
									aLbxAux[oLbxAux:nAt][03] 							,; //Matricula
									aLbxAux[oLbxAux:nAt][04] 							,; //Sequencia
									aLbxAux[oLbxAux:nAt][05] 							,; //Tipo
									aLbxAux[oLbxAux:nAt][06] 							,; //Nome
									aLbxAux[oLbxAux:nAt][07] 							,; //Dt.Adm
									aLbxAux[oLbxAux:nAt][08] 							,; //Dt.Nasc
									aLbxAux[oLbxAux:nAt][09] 							,; //Grau Parentesco
									aLbxAux[oLbxAux:nAt][10] 							,; //Nome Titular
									aLbxAux[oLbxAux:nAt][11] 							}} //Recno

	oLbxAux:Refresh()

EndIf

//===========================================================================
// Gravacao do Log.
//===========================================================================
If	lGravaLog
	PlsLogFil("...................: Finalizou Carregamento dos Dados no Objeto oLbx em............................: "+;
	AllTrim(Str((Seconds()-nTempoX),10,0))+" Segundo(s)",cDvArqLog)
EndIf

Return

/*
===============================================================================================================================
Programa----------: MGPE009COB
Autor-------------: Alexandre Villar
Data da Criacao---: 21/02/2014
Descrição---------: Retorna as coordenadas do objeto para exibição na tela
Parametros--------: oLbxAux := Objeto de dados.
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGPE009COB(oObjAux)

Local aCoordAux := FWGetDialogSize(oObjAux)

aCoordAux[03] := ( aCoordAux[03] / 2 ) - 50
aCoordAux[04] := ( aCoordAux[04] / 2 ) - 10

Return(aCoordAux)

/*
===============================================================================================================================
Programa----------: MGPE009CIT
Autor-------------: Alexandre Villar
Data da Criacao---: 21/02/2014
Descrição---------: Realiza a Contagem dos Itens
Parametros--------: oLbxAux := Objeto de dados para a atualização.
------------------: aTotFun := Array que receberá as contagens de Titulares.
------------------: aTotDep := Array que receberá as contagens de Dependentes.
------------------: oTotFun := Objeto de dados da contagem de Titulares.
------------------: oTotDep := Objeto de dados da contagem de Dependentes.
------------------: nAux    := Identificação para controle de marcação.
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGPE009CIT( oLbxDados , aTotFun , aTotDep , oTotFun , oTotDep , nAux )

Local nX		:= 0

//===========================================================================
//| Caso o item tenha sido marcado manualmente.                             |
//===========================================================================
If oLbxDados:aArray[oLbxDados:nAt][01]
	
	If oLbxDados:aArray[oLbxDados:nAt][04] == "00"
	
		aTotFun[02]++
		aTotFun[01]--
		
	Else
	
		aTotDep[02]++
		aTotDep[01]--
		
		If nAux == 1
			aTotFun[02]++
			aTotFun[01]--
		EndIf
		
	EndIf

//===========================================================================
//| Caso o item tenha sido desmarcado manualmente.                          |
//===========================================================================
Else
	
	If oLbxDados:aArray[oLbxDados:nAt][04] == "00"
	
		aTotFun[02]--
		aTotFun[01]++
		
		For nX := 1 To nAux
			
			aTotDep[02]--
			aTotDep[01]++
			
		Next nX
		
	Else
		aTotDep[02]--
		aTotDep[01]++
	EndIf

EndIf

oTotFun[01]:Refresh()
oTotFun[02]:Refresh()

oTotDep[01]:Refresh()
oTotDep[02]:Refresh()

Return

/*
===============================================================================================================================
Programa----------: MGPE009CON
Autor-------------: Alexandre Villar
Data da Criacao---: 21/02/2014
Descrição---------: Realiza a Contagem Inicial dos Itens
Parametros--------: oLbxAux := Objeto de dados para a atualização.
------------------: aTotFun := Array que receberá as contagens de Titulares.
------------------: aTotDep := Array que receberá as contagens de Dependentes.
------------------: oTotFun := Objeto de dados da contagem de Titulares.
------------------: oTotDep := Objeto de dados da contagem de Dependentes.
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGPE009CON( oLbxDados , aTotFun , aTotDep , oTotFun , oTotDep )

Local 	nI		:= 0
Local 	nTotReg	:= Len(oLbxDados:aArray)

aTotFun[01]	:= 0
aTotFun[02]	:= 0
aTotFun[03]	:= 0

aTotDep[01]	:= 0
aTotDep[02]	:= 0
aTotDep[03]	:= 0

//===========================================================================
//| Contabiliza todos os registros.                                         |
//===========================================================================
For	nI := 1 To nTotReg
	
	If oLbxDados:aArray[nI][01]
		If oLbxDados:aArray[nI][04] == "00"
			aTotFun[02] ++
		Else
			aTotDep[02] ++
		EndIf
	Else
		If oLbxDados:aArray[nI][04] == "00"
			aTotFun[01] ++
		Else
			aTotDep[01] ++
		EndIf
	EndIf

	IncProc("Verificando dados ( "+StrZero(nI,8)+" de "+StrZero(nTotReg,8)+" ) " )
	
Next nI

//===========================================================================
//| Atualiza os Objetos de Dados.                                           |
//===========================================================================
aTotFun[03]	:= aTotFun[01] + aTotFun[02]
aTotDep[03]	:= aTotDep[01] + aTotDep[02]

oTotFun[01]:Refresh()
oTotFun[02]:Refresh()
oTotFun[03]:Refresh()

oTotDep[01]:Refresh()
oTotDep[02]:Refresh()
oTotDep[03]:Refresh()

Return

/*
===============================================================================================================================
Programa----------: MGPE009PRO
Autor-------------: Alexandre Villar
Data da Criacao---: 21/02/2014
Descrição---------: Realiza o Processamento das Integrações
Parametros--------: oLbxDados := Objeto de dados para a atualização.
------------------: aParAux   := Parametrização inicial do ambiente.
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGPE009PRO( oLbxDados , aParAux )

Local aDadAux	:= {}
Local aDadObj	:= {}
Local cNumLote	:= ""
Local nI		:= 0

//===========================================================================
//| Abre o controle de transacoes.                                          |
//===========================================================================
Begin Transaction

//===========================================================================
//| Verifica e Processa os dados do primeiro folder.                        |
//===========================================================================
aDadObj := oLbxDados[01]:aArray

If !Empty(aDadObj)
	
	For nI := 1 To Len( aDadObj )
		
		//===========================================================================
		//| Recupera somente os registros selecionados.                             |
		//===========================================================================
		If aDadObj[nI][01]
		
			aAdd( aDadAux , {	aDadObj[nI][02]		,; //FILIAL
								aDadObj[nI][03]		,; //MATRICULA
								aDadObj[nI][04]		,; //SEQ_USUARIO
								aDadObj[nI][05]		,; //TIPO
								aDadObj[nI][06]		,; //NOME
								aDadObj[nI][07]		,; //DT_ADM-NSC
								aDadObj[nI][08]		,; //NOME_TITULAR
								aDadObj[nI][09]		}) //RECNO_
			
		EndIf
		
	Next nI
	
	//===========================================================================
	//| Inicializa rotina de controle do ExecAuto.                              |
	//===========================================================================
	Processa( {|lEnd| MGPE009MVC( aDadAux , aParAux , 01 , cNumLote ) } , "Inclusão de Titulares/Dependentes"	, "Iniciando, aguarde..." , .F. )
	
EndIf

//===========================================================================
//| Verifica e Processa os dados do segundo folder.                         |
//===========================================================================
aDadObj := oLbxDados[02]:aArray
aDadAux	:= {}

If !Empty(aDadObj)
	
	For nI := 1 To Len( aDadObj )
		
		//===========================================================================
		//| Recupera somente os registros selecionados.                             |
		//===========================================================================
		If aDadObj[nI][01]
		
			aAdd( aDadAux , {	aDadObj[nI][02]		,; //FILIAL
								aDadObj[nI][03]		,; //MATRICULA
								aDadObj[nI][04]		,; //SEQ_USUARIO
								aDadObj[nI][05]		,; //TIPO
								aDadObj[nI][06]		,; //NOME
								aDadObj[nI][07]		,; //DT_ADM-NSC
								aDadObj[nI][08]		,; //NOME_TITULAR
								aDadObj[nI][09]		}) //RECNO_
			
		EndIf
		
	Next nI
	
	//===========================================================================
	//| Inicializa rotina de controle do ExecAuto.                              |
	//===========================================================================
	Processa( {|lEnd| MGPE009MVC( aDadAux , aParAux , 02 , cNumLote ) } , "Inclusão de Dependentes"				, "Iniciando, aguarde..." , .F. )

EndIf

//===========================================================================
//| Fecha o controle de transacoes.                                         |
//===========================================================================
End Transaction

Return

/*
===============================================================================================================================
Programa----------: MGPEF3GN
Autor-------------: Alexandre Villar
Data da Criacao---: 21/02/2014
Descrição---------: Processamento genérico para o F3 do Wizard
Parametros--------: cTpFor := Tipo do Fornecedor.
------------------: cTpPla := Tipo do Plano.
------------------: nOpc   := Define o campo que esta chamando.
------------------: lValid := Define se a rotina foi chamada para efeito de validação.
------------------: cCodAux:= Código que deverá ser validado.
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MGPEF3GN( cTpFor , cTpPla , nOpc , lValid , cCodAux )

Local lRet 	   		:= .F.
Local nRetorno 		:= 0
Local cQuery   		:= ""
Local cCodTab	 	:= ""
Local cAliasAux		:= GetNextAlias()

Default cTpFor		:= 0
Default cTpPla		:= 0
Default nOpc		:= 0
Default lValid		:= .F.
Default cCodAux		:= ""

If nOpc == 1
	
	If cTpFor == 1
		cCodTab	:= "S016"
	ElseIf cTpFor == 2
		cCodTab	:= "S017"
	Else
		Aviso( "Atenção!" , "Informar Tipo de Fornecedor!" , {"Fechar"} )
	EndIf
	
ElseIf nOpc == 2

	If cTpFor == 1
	
		If cTpPla == 1
			cCodTab := "S008"
		ElseIf cTpPla == 2
			cCodTab := "S009"
		ElseIf cTpPla == 3
			cCodTab := "S028" 
		ElseIf cTpPla == 4
			cCodTab := "S029"
		EndIf
	
	ElseIf cTpFor == 2
	
		If cTpPla == 1
			cCodTab := "S013"
		ElseIf cTpPla == 2
			cCodTab := "S014"
		ElseIf cTpPla == 3
			cCodTab := "S030" 
		ElseIf cTpPla == 4
			cCodTab := "S031"
		EndIf
	
	Else
		Aviso( "Atenção!" , "Informar Tipo de Fornecedor e Tipo de Plano!" , {"Fechar"} )
	EndIf

EndIf

If !Empty( cCodTab )

	cQuery := " SELECT DISTINCT "
	cQuery += "     SubStr( RCC.RCC_CONTEU , 1 , 2 )	AS CODIGO, "
	cQuery += "     SubStr( RCC.RCC_CONTEU , 3 , 20 )	AS DESCRI, "
	cQuery += "     RCC.R_E_C_N_O_						AS REGRCC "
	cQuery += " FROM "+ RetSqlName("RCC") +" RCC "
	cQuery += " WHERE "
	cQuery += "       D_E_L_E_T_		= ' ' "
	cQuery += " AND   RCC.RCC_CODIGO	= '"+ cCodTab +"' "
	cQuery += " ORDER BY CODIGO "
	
	//===========================================================================
	//| Se For chamado pela validacao verifica se o codigo existe               |
	//===========================================================================
	If lValid
		
		If Select(cAliasAux) > 0
			(cAliasAux)->( DBCloseArea() )
		EndIf
		
		DBUseArea( .T. , "TOPCONN" , TCGenQry(,,cQuery) , cAliasAux , .F. , .T. )
		
		lRet := .F.
		
		DBSelectArea(cAliasAux)
		(cAliasAux)->( DBGoTop() )
		While (cAliasAux)->(!Eof())
			
			If AllTrim( (cAliasAux)->CODIGO ) == AllTrim( cCodAux )
				
				lRet := .T.
				Exit
				
			EndIf
			
		(cAliasAux)->( DBSkip() )
		EndDo
		
	Else
	
		//===========================================================================
		//| Monta tela de consulta para escolha das opcoes                          |
		//===========================================================================
		If 	Tk510F3Qry( cQuery /*cQuery*/,IIf(nOpc==1,"RCC001","RCC002")/*cCodCon*/,"REGRCC"/*cCpoRecno*/,@nRetorno/*nRetorno*/,/*aCoord*/,/*aSearch*/,"RCC"/*cAlias*/)
			RCC->( DBGoTo( nRetorno ) )
			lRet := .T.
		EndIf
	
	EndIf

EndIf

Return(lRet)

/*
===============================================================================================================================
Programa----------: MGPEMOK
Autor-------------: Alexandre Villar
Data da Criacao---: 21/02/2014
Descrição---------: Controle de Marcação do ListBox
Parametros--------: nTipo := Tipo de acao a executar.
------------------: oGetAux := objeto do ListBox.
------------------: lCheck := Define se deve marcar ou desmarcar os itens
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MGPEMOK( nTipo , oGetAux , lCheck )

Local nI			:= 0
Local nX			:= 0
Local nTotReg		:= 0
Local nColMarka		:= 1

nTotReg := Len(oGetAux:aArray) //Tamanho total do ListBox

For nI := 1 To nTotReg
	
	If nTipo == 1 .And. oGetAux:aArray[nI][04] == "00" //Quando For para marcar/desmarcar Titulares
	
		oGetAux:aArray[nI][nColMarka] := lCheck
		
		If !lCheck //Caso desmarcar o Titular, desmarcar todos os Dependentes
			
			nX := nI+1
			
			While nX <= nTotReg .And. oGetAux:aArray[nI][02] + oGetAux:aArray[nI][03] == oGetAux:aArray[nX][02] + oGetAux:aArray[nX][03]
				oGetAux:aArray[nX][nColMarka] := lCheck
			nX++
			EndDo
			
		EndIf
		
	ElseIf nTipo == 2 .And. oGetAux:aArray[nI][04] <> "00" //Quando For para marcar/desmarcar Dependentes
	
		oGetAux:aArray[nI][nColMarka] := lCheck
		
		If lCheck //Caso marcar Dependentes, verificar a marcacao do Titular
		
			nX := nI
			
			While nX > 0 .And. oGetAux:aArray[nX][04] <> "00"
				nX--
			EndDo
			
			If nX > 0 .And. !oGetAux:aArray[nX][nColMarka]
				oGetAux:aArray[nX][nColMarka] := .T.
			EndIf
		
		EndIf
	
	ElseIf nTipo == 3
		
		oGetAux:aArray[nI][nColMarka] := lCheck
	
	EndIf
	
Next nI

oGetAux:Refresh()

Return(.T.)

/*
===============================================================================================================================
Programa----------: MGPE009DBC
Autor-------------: Alexandre Villar
Data da Criacao---: 21/02/2014
Descrição---------: Controle de Marcação do ListBox para quando um Dependente For selecionado marcar também o Titular
Parametros--------: oLbxDados := Objeto do ListBox.
------------------: nOpc      := Define se a ação ocorreu sobre Titular/Dependente
------------------: nAux      := Controle para contabilizar as marcações
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGPE009DBC( oLbxDados , nOpc , nAux )

Local nI		:= 0
Local nX		:= 0
Local nTotReg	:= Len( oLbxDados[nOpc]:aArray )
Local nAtAux	:= oLbxDados[nOpc]:nAt
Local cMatAux	:= ""

nAux := 0

oLbxDados[nOpc]:aArray[oLbxDados[nOpc]:nAt,01] := !oLbxDados[nOpc]:aArray[oLbxDados[nOpc]:nAt,01]

//===========================================================================
//| Caso tenha desmarcado um Titular, verifica os Dependentes               |
//===========================================================================
If nOpc == 1 .And. !oLbxDados[nOpc]:aArray[oLbxDados[nOpc]:nAt,01] .And. oLbxDados[nOpc]:aArray[oLbxDados[nOpc]:nAt,04] == "00"

	nX		:= oLbxDados[nOpc]:nAt + 1
	cMatAux	:= oLbxDados[nOpc]:aArray[oLbxDados[nOpc]:nAt,02] + oLbxDados[nOpc]:aArray[oLbxDados[nOpc]:nAt,03]
	
	While nX <= nTotReg .And. cMatAux == oLbxDados[nOpc]:aArray[nX,02] + oLbxDados[nOpc]:aArray[nX,03]
		
		If oLbxDados[nOpc]:aArray[nX,01]
			oLbxDados[nOpc]:aArray[nX,01] := .F.
			nAux++
		EndIf
		
	nX++
	EndDo
	
EndIf

//===========================================================================
//| Caso tenha marcado um Dependente, verifica o Titular                    |
//===========================================================================
If nOpc == 1 .And. oLbxDados[nOpc]:aArray[oLbxDados[nOpc]:nAt,01] .And. !( AllTrim( oLbxDados[nOpc]:aArray[oLbxDados[nOpc]:nAt,04] ) == "00" )

	nI := oLbxDados[nOpc]:nAt
	cMatAux := oLbxDados[nOpc]:aArray[oLbxDados[nOpc]:nAt,02] + oLbxDados[nOpc]:aArray[oLbxDados[nOpc]:nAt,03]
	
	While !( AllTrim( oLbxDados[nOpc]:aArray[nI,04] ) == "00" ) .And. cMatAux == oLbxDados[nOpc]:aArray[nI,02] + oLbxDados[nOpc]:aArray[nI,03]
		nI--
	EndDo
	
	If !oLbxDados[nOpc]:aArray[nI,01]
		oLbxDados[nOpc]:aArray[nI,01] := .T.
		nAux := 1
	EndIf

EndIf

oLbxDados[nOpc]:Refresh()
oLbxDados[nOpc]:nAt := nAtAux

Return

/*
===============================================================================================================================
Programa----------: MGPE009MVC
Autor-------------: Alexandre Villar
Data da Criacao---: 21/02/2014
Descrição---------: Rotina de processamento do ExecAuto utilizando o MVC da Rotina Padrão
Parametros--------: aDadosAux := Objeto de Dados do Listbox
------------------: aParAux   := Parametrizacao Inicial da Rotina
------------------: nOpc      := Numero da Opcao de Processamento (Titulares/Dependentes)
------------------: cNumLote  := Numero do lote de Processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGPE009MVC( aDadosAux , aParAux , nOpc , cNumLote )

Local aSay	   		:= {}
Local aButton  		:= {}
//					   |....:....|....:....|....:....|....:....|....:....|....:....|....:....|....:....|....:....|....:....|
Local cDesc1   		:= "Esta rotina fará a importação da Integração conforme parâmetros definidos."
Local cDesc2   		:= "Nesse processamento serão importados dados de: [ "+IIf( nOpc==1 , "Titulares e Dependentes" , "Dependentes" ) +" ]"
Local cDesc3   		:= ""
Local cTitBat		:= "Integração Funcionários x Plano de Saúde"
Local lOk	   		:= .T.
Local nAux			:= 0

Default aDadosAux	:= {}
Default nOpc		:= 0
Default cNumLote	:= ""

If !Empty(aDadosAux)

	aAdd( aSay , cDesc1 )
	aAdd( aSay , cDesc2 )
	aAdd( aSay , cDesc3 )
	
	aAdd( aButton , { 1 , .T. , {|| nAux := 1 , FechaBatch()	} } )
	aAdd( aButton , { 2 , .T. , {|| FechaBatch()				} } )
	
	FormBatch( cTitBat , aSay , aButton )
	
	If nAux == 1
	
		//-- Abre Lote de Processamento --//
		cNumLote := U_ITInLote( "Z00" , StrZero(nOpc,3) )
		
		Processa( { || lOk := MGPE009GRV( aDadosAux , aParAux , nOpc , cNumLote ) } , 'Aguarde' , 'Processando...' , .F. )
		
		//-- Fecha Lote de Processamento --//
		U_ITFnLote( "Z00" , cNumLote )
		
		If lOk
			ApMsgInfo( "Processamento do Folder ["+ StrZero(nOpc,2) +"] concluído com sucesso."+ CRLF +"Lote: ["+ cNumLote +"]"	, "Atenção!" )
		Else
			ApMsgStop( "Processamento do Folder ["+ StrZero(nOpc,2) +"] concluído com falhas."+ CRLF +"Lote: ["+ cNumLote +"]"		, "Atenção!" )
		EndIf
	
	EndIf

EndIf

Return

/*
===============================================================================================================================
Programa----------: MGPE009GRV
Autor-------------: Alexandre Villar
Data da Criacao---: 21/02/2014
Descrição---------: Rotina que chama a gravação do ExecAuto utilizando o MVC da Rotina Padrão
Parametros--------: aDadosAux := Objeto de Dados do Listbox
------------------: aParAux   := Parametrizacao Inicial da Rotina
------------------: nOpc      := Numero da Opcao de Processamento (Titulares/Dependentes)
------------------: cNumLote  := Numero do lote de Processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGPE009GRV( aDadosAux , aParAux , nOpc , cNumLote )

Local lRet			:= .T.
Local aLoteIn		:= {}
Local aCposCab		:= {}
Local aCposDet		:= {}
Local cDtAux		:= ""
Local cMatAux		:= ""
Local nI			:= 0
Default nOpc   		:= 0
Default cNumLote	:= ""

//-- Corrige desvio do mes/ano --//
If MV_PAR11 = 1 //Tipo do Plano: SAUDE
   cDtAux := StrZero( Month(dDataBase) + 1 , 2 )
ElseIf MV_PAR11 = 2 //Tipo do Plano: ONDONTOLOGICO
   cDtAux := StrZero( Month(dDataBase)     , 2 )
EndIf
If Val(cDtAux) > 12
	cDtAux := StrZero( Val(cDtAux) - 12 , 2 ) + AllTrim( Str( Year(dDataBase)+1 ) )
Else
	cDtAux += AllTrim(Str(Year(dDataBase)))
EndIf

For nI := 1 To Len(aDadosAux)
	
	If nOpc == 1
		
		//-- Recupera dados do Titular --//
		If aDadosAux[nI][03] == "00"
		
			aAdd( aCposCab	, { 'RHK_FILIAL'	, aDadosAux[nI][01]	} )
			aAdd( aCposCab	, { 'RHK_MAT'		, aDadosAux[nI][02]	} )
			aAdd( aCposCab	, { 'RHK_TPFORN'	, aParAux[09]		} )
			aAdd( aCposCab	, { 'RHK_CODFOR'	, aParAux[10]		} )
			aAdd( aCposCab	, { 'RHK_TPPLAN'	, aParAux[11]		} )
			aAdd( aCposCab	, { 'RHK_PLANO'		, aParAux[12]		} )
			aAdd( aCposCab	, { 'RHK_PD'		, aParAux[13]		} )
			aAdd( aCposCab	, { 'RHK_PDDAGR'	, aParAux[14]		} )
			aAdd( aCposCab	, { 'RHK_PERINI'	, cDtAux			} )
			
			aAdd( aLoteIn	, {	aDadosAux[nI][01] + aDadosAux[nI][02] + "00"	,; // Z01_CHAVE
								"1"												,; // Z01_TIPO (1=Titular/2=Dependente)
								aParAux[09]										,; // Z01_TPFORN
								aParAux[10]										,; // Z01_CODFOR
								aParAux[11]										,; // Z01_TPPLAN
								aParAux[12]										,; // Z01_PLANO
								aParAux[13]										,; // Z01_VERTIT
								aParAux[14]		  								,; // Z01_VERDEP
								cDtAux											}) // Z01_PERINI
			
			cMatAux := aDadosAux[nI][01]+aDadosAux[nI][02]
			nI++
			
		EndIf
		
		If nI <= Len(aDadosAux)
			
			//-- Recupera dados dos Dependentes --//
			While nI <= Len(aDadosAux) .And. !( aDadosAux[nI][03] == "00" ) .And. aDadosAux[nI][01]+aDadosAux[nI][02] == cMatAux
				
				aAdd( aCposDet	, {	{ 'RHL_FILIAL'	, aDadosAux[nI][01]	} ,;
									{ 'RHL_MAT'		, aDadosAux[nI][02]	} ,;
									{ 'RHL_TPFORN'	, aParAux[09]		} ,;
									{ 'RHL_CODFOR'	, aParAux[10]		} ,;
									{ 'RHL_CODIGO'	, aDadosAux[nI][03]	} ,;
									{ 'RHL_TPPLAN'	, aParAux[11]		} ,;
									{ 'RHL_PLANO'	, aParAux[12]		} ,;
									{ 'RHL_PERINI'	, cDtAux			} ,;
									{ 'RHL_PD'  	, aParAux[14]		} })

				aAdd( aLoteIn	, {	aDadosAux[nI][01] + aDadosAux[nI][02] + aDadosAux[nI][03]	,; // Z01_CHAVE
									"2"															,; // Z01_TIPO (1=Titular/2=Dependente)
									aParAux[09]													,; // Z01_TPFORN
									aParAux[10]													,; // Z01_CODFOR
									aParAux[11]													,; // Z01_TPPLAN
									aParAux[12]													,; // Z01_PLANO
									aParAux[13]													,; // Z01_VERTIT
									aParAux[14]		  											,; // Z01_VERDEP
									cDtAux														}) // Z01_PERINI
			
			nI++
			EndDo
		
		EndIf
		nI--
				
	ElseIf nOpc == 2
		
		aAdd( aCposDet	,	{	{ 'RHL_FILIAL'	, aDadosAux[nI][01]	} ,;
								{ 'RHL_MAT'		, aDadosAux[nI][02]	} ,;
								{ 'RHL_TPFORN'	, aParAux[09]		} ,;
								{ 'RHL_CODFOR'	, aParAux[10]		} ,;
								{ 'RHL_CODIGO'	, aDadosAux[nI][03]	} ,;
								{ 'RHL_TPPLAN'	, aParAux[11]		} ,;
								{ 'RHL_PLANO'	, aParAux[12] 		} ,;
								{ 'RHL_PERINI'	, cDtAux			} ,;
								{ 'RHL_PD'   	, aParAux[14]		} })
		
		aAdd( aLoteIn	, {	aDadosAux[nI][01] + aDadosAux[nI][02] + aDadosAux[nI][03]		,; // Z01_CHAVE
							"2"																,; // Z01_TIPO (1=Titular/2=Dependente)
							aParAux[09]														,; // Z01_TPFORN
							aParAux[10]														,; // Z01_CODFOR
							aParAux[11]														,; // Z01_TPPLAN
							aParAux[12]														,; // Z01_PLANO
							aParAux[13]														,; // Z01_VERTIT
							aParAux[14]														,; // Z01_VERDEP
							cDtAux															}) // Z01_PERINI
			
	EndIf
	
	If ( Empty(aCposCab) .And. Empty(aCposDet) ) .Or. !MGPE009IMP( nOpc , 'RHK' , 'RHL' , aCposCab , aCposDet , cNumLote , aLoteIn )
		lRet := .F.
	EndIf
	
	aCposCab	:= {}
	aCposDet	:= {}
	aLoteIn		:= {}

Next nI

Return( lRet )

/*
===============================================================================================================================
Programa----------: MGPE009IMP
Autor-------------: Alexandre Villar
Data da Criacao---: 21/02/2014
Descrição---------: Rotina de importação do ExecAuto utilizando o MVC da Rotina Padrão
Parametros--------: nOpc       := Identifica se o processamento e de Titular/Dependentes.
------------------: cMaster    := Nome do Alias para o Objeto de planos dos Titulares.
------------------: cDetail    := Nome do Alias para o Objeto de planos dos Dependentes.
------------------: aCpoMaster := Array com os campos/dados dos Titulares.
------------------: aCpoDetail := Array com os campos/dados dos Dependentes.
------------------: cNumLote   := Numero do Lote de Processamento.
------------------: aLoteIn    := Array com os dados para alimentar o Log de Processamento.
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGPE009IMP( nOpc , cMaster , cDetail , aCpoMaster , aCpoDetail , cNumLote , aLoteIn )

Local oModel	:= Nil
Local oAux		:= Nil
Local oStruct	:= Nil
Local cEmpAux	:= cEmpAnt
Local cFilAux	:= cFilAnt
Local nI		:= 0
Local nJ		:= 0
Local nX		:= 0
Local nPos		:= 0
Local nLinAux	:= 0
Local lRet		:= .T.
Local aAux		:= {}
Local nItErro	:= 0
Local cMatAux	:= ""

//-- Posiciona nas Tabelas para a Inicialização dos Modelos --//
DBSelectArea("SRA")
SRA->( DBSetOrder(1) )

DBSelectArea(cMaster)
(cMaster)->( DBSetOrder(1) )

DBSelectArea(cDetail)
(cDetail)->( DBSetOrder(1) )

//-- Instancia o Modelo da Rotina --//
oModel := FWLoadModel( 'GPEA001' )

//-- Processa a Inclusão dos Dados do Titular --//
If nOpc == 1

	//-- Verifica Filial para Iniciar o modelo --//
	If cFilAnt <> aCpoMaster[01][02]
	
		DBSelectArea("SM0")
		SM0->( DBSetOrder(1) )
		SM0->( DBGoTop() )
		If SM0->( DBSeek( cEmpAnt + aCpoMaster[01][02] ) )
			cFilAnt := AllTrim(SM0->M0_CODFIL)
		Else
			lRet := .F.
		EndIf
	
	EndIf
	
	If lRet
	
		//-- Ativa o Modelo --//
		SRA->( DBGoTop() )
		SRA->( DBSeek( aCpoMaster[01][02] + aCpoMaster[02][02] ) )	// Posiciona no cadastro do funcionário
		cMatAux := aCpoMaster[01][02] +"-"+ aCpoMaster[02][02]
		
		//-- Posiciona no Cadastro do Plano do Funcionario e Inicializa o Modelo --//
		oModel:SetOperation( 4 )				   		// Operação: 3 – Inclusão / 4 – Alteração / 5 - Exclusão
		oModel:Activate()
		
		//-- Instancia o Modelo de Dados Do Titular --//
		oAux	:= oModel:GetModel( "GPEA001_M" + cMaster ) // Instancia o modelo de dados
		oStruct	:= oAux:GetStruct()							// Obtem a estrutura de dados
		aAux 	:= oStruct:GetFields()						// Obtem a estrutura de campos
		
		//-- Trata a inclusao de nova linha somente após a primeira (GRID) --//
		If !Empty( oAux:GetValue( "RHK_CODFOR" ) )
		
			nLinAux := oAux:Length()
			If ( nItErro := oAux:AddLine() ) == nLinAux // Se For igual e porque nao conseguiu incluir mais uma linha
				lRet := .F.
			EndIf
			
		EndIf
	
	EndIf
	
	If lRet
	
		For nI := 1 To Len( aCpoMaster )
		
			//-- Verifica se os campos passados existem na estrutura de dados --//
			If  ( nPos  :=  aScan( aAux , {|x| AllTrim(x[3]) == AllTrim( aCpoMaster[nI][01] ) } ) ) > 0
			
				//-- Faz a atribuição dos dados aos campos do Modelo --//
				If !( oAux:LoadValue( aAux[nPos][03] , aCpoMaster[nI][02] ) )
				
					lRet := .F. //Caso a atribuição falhe, aborta o processamento do registro atual.
					Exit
					
				EndIf
				
			EndIf
			
		Next nI
	
	EndIf

	//================================================================================
	//| Verifica a inclusão dos dependentes para o funcionario atual                 |
	//================================================================================
	If lRet .And. !Empty( aCpoDetail )
	
		oAux	:= oModel:GetModel( "GPEA001_M" + cDetail )	// Instancia o modelo de dados do item
		oStruct	:= oAux:GetStruct()							// Obtem a estrutura de dados do item
		aAux	:= oStruct:GetFields()						// Obtem a estrutura de campos do item
		
		nItErro := 0
		
		For nI := 1 To Len( aCpoDetail )
		
			//================================================================================
			//| Tratativa para a inclusão de linhas no Grid                                  |
			//================================================================================
			If nI > 1
			
				If ( nItErro := oAux:AddLine() ) <> nI
					lRet := .F.
					Exit
				EndIf
				
			EndIf
			
			For nJ := 1 To Len( aCpoDetail[nI] )
			
				//================================================================================
				//| Verificação e gravação dos campos na estrutura                               |
				//================================================================================
				If ( nPos := aScan( aAux, { |x| AllTrim( x[3] ) == AllTrim( aCpoDetail[nI][nJ][1] ) } ) ) > 0
					
					If !( oAux:LoadValue( aCpoDetail[nI][nJ][1] , aCpoDetail[nI][nJ][2] ) )
					
						lRet	:= .F.
						nItErro	:= nI
						Exit
						
					EndIf
					
				EndIf
				
			Next nJ
			
			If !lRet
				Exit
			EndIf
			
		Next nI
	
	EndIf

//================================================================================
//| Inclusão de dependentes dos funcionários já cadastrados no Plano de Saúde    |
//================================================================================
ElseIf nOpc == 2
	
	For nI := 1 To Len( aCpoDetail )
		
		//================================================================================
		//| Verifica o posicionamento para evitar erros no ExecAuto                      |
		//================================================================================
		If nI == 1 .And. cFilAnt <> aCpoDetail[nI][01][02]
		
			DBSelectArea("SM0")
			SM0->( DBSetOrder(1) )
			SM0->( DBGoTop() )
			If SM0->( DBSeek( cEmpAnt + aCpoDetail[nI][01][02] ) )
				cFilAnt := AllTrim(SM0->M0_CODFIL)
			Else
				nI++
				Loop
			EndIf
		
		EndIf
		
		//================================================================================
		//| Posiciona o cadastro de Funcionários                                         |
		//================================================================================
		SRA->( DBGoTop() )
		SRA->( DBSeek( aCpoDetail[nI][01][02] + aCpoDetail[nI][02][02] ) )
		cMatAux := aCpoDetail[nI][01][02] +"-"+ aCpoDetail[nI][02][02]
		
		//================================================================================
		//| Posiciona o cadastro do plano do Funcionário                                 |
		//================================================================================
		(cMaster)->( DBGoTop() )
		If (cMaster)->( DBSeek( aCpoDetail[nI][01][02] + aCpoDetail[nI][02][02] + aCpoDetail[nI][03][02] + aCpoDetail[nI][04][02] ) )
			
			oModel:SetOperation( 4 ) // Operação: 3 – Inclusão / 4 – Alteração / 5 - Exclusão
			oModel:Activate()
			
			oAux := oModel:GetModel( "GPEA001_M" + cMaster ) // Instancia o modelo de dados do Funcionário
			
			lRet := .F.
			
			For nX := 1 To oAux:Length()
			
				oAux:GoLine( nX )
				
				//================================================================================
				//| Verifica o plano do funcionário para gravação dos Dependentes                |
				//================================================================================
				If	oAux:GetValue( "RHK_FILIAL"	) == aCpoDetail[nI][01][02] .And.;
					oAux:GetValue( "RHK_MAT"	) == aCpoDetail[nI][02][02] .And.;
					oAux:GetValue( "RHK_TPFORN"	) == aCpoDetail[nI][03][02] .And.;
					oAux:GetValue( "RHK_CODFOR"	) == aCpoDetail[nI][04][02] .And.;
					oAux:GetValue( "RHK_TPPLAN"	) == aCpoDetail[nI][06][02] .And.;
					oAux:GetValue( "RHK_PLANO"	) == aCpoDetail[nI][07][02]
					
					oAux:LoadValue( "RHK_PDDAGR" , aCpoDetail[nI][09][02] ) //Atualiza o Campo de Verba para os Dependentes
					
					lRet := .T.
					
					Exit
				
				EndIf
				
			Next nX
			
		Else
		
			nOpc	:= 0
			lRet	:= .F.
			
		EndIf
		
		//================================================================================
		//| Processa a gravação dos dependentes para o funcionário verificado            |
		//================================================================================
		If lRet
			
			oAux	:= oModel:GetModel( "GPEA001_M" + cDetail )	// Instancia o modelo de dados do item
			oStruct	:= oAux:GetStruct()							// Obtem a estrutura de dados do item
			aAux	:= oStruct:GetFields()						// Obtem a estrutura de campos do item
			nLinAux := oAux:Length()							// Recupera a quantidade de linhas do Objeto Grid
			
			//================================================================================
			//| Trata a inclusão de linhas no Grid                                           |
			//================================================================================
			If nLinAux > 1 .Or. !Empty( oAux:GetValue( "RHL_CODIGO" ) )
			
				If ( nItErro := oAux:AddLine() ) == nLinAux // Se For igual e porque nao conseguiu incluir mais uma linha
					lRet := .F.
					Exit
				EndIf
				
			EndIf
			
			//================================================================================
			//| Verifica e Processa a gravação dos campos                                    |
			//================================================================================
			For nJ := 1 To Len( aCpoDetail[nI] )
			
				// Verifica se os campos passados existem na estrutura de item
				If ( nPos := aScan( aAux , { |x| AllTrim( x[3] ) == AllTrim( aCpoDetail[nI][nJ][1] ) } ) ) > 0
					
					If !( oAux:LoadValue( aCpoDetail[nI][nJ][1] , aCpoDetail[nI][nJ][2] ) )
						lRet	:= .F. // Se nao conseguir atribuir algum valor aborta a execução atual
						nItErro	:= nI
						Exit
					EndIf
					
				EndIf
				
			Next nJ
			
		EndIf
	
	Next nI

EndIf

If lRet
	cFilOld:=cFilAux //incluído para evitar variable does not exist CFILOLD on GP001COMMIT(GPEA001.PRW)
	//================================================================================
	//| Validação dos dados do Modelo                                                |
	//================================================================================
	lRet := oModel:VldData()

	If lRet
	
		//================================================================================
		//| Processa a gravação dos dados do Modelo                                      |
		//================================================================================
		oModel:CommitData()
		U_ITGrLote( "Z01" , cNumLote , aLoteIn , "1" )
		
	Else
	
		U_ITGrLote( "Z01" , cNumLote , aLoteIn , "2" )
		
	EndIf

Else

	U_ITGrLote( "Z01" , cNumLote , aLoteIn , "2" )
	
EndIf

//================================================================================
//| Verifica e exibe o LOG em caso de falhas                                     |
//================================================================================
If !lRet

	aErro := oModel:GetErrorMessage()
	
	AutoGrLog( "Filial + Matrícula..........: " + ' [' + cMatAux				+ ']' )
	AutoGrLog( "Id do formulário de origem..: " + ' [' + AllToChar( aErro[1] )	+ ']' )
	AutoGrLog( "Id do campo de origem.......: " + ' [' + AllToChar( aErro[2] )	+ ']' )
	AutoGrLog( "Id do formulário de erro....: " + ' [' + AllToChar( aErro[3] )	+ ']' )
	AutoGrLog( "Id do campo de erro.........: " + ' [' + AllToChar( aErro[4] )	+ ']' )
	AutoGrLog( "Id do erro..................: " + ' [' + AllToChar( aErro[5] )	+ ']' )
	AutoGrLog( "Mensagem do erro............: " + ' [' + AllToChar( aErro[6] )	+ ']' )
	AutoGrLog( "Mensagem da solução.........: " + ' [' + AllToChar( aErro[7] )	+ ']' )
	AutoGrLog( "Valor atribuído.............: " + ' [' + AllToChar( aErro[8] )	+ ']' )
	AutoGrLog( "Valor anterior..............: " + ' [' + AllToChar( aErro[9] )	+ ']' )
	
	If nItErro > 0
		AutoGrLog( "Erro no Item................: " + ' [' + AllTrim( AllToChar(nItErro) ) + ']' )
		MostraErro()
	Else
		MostraErro()
	EndIf
	
EndIf

//================================================================================
//| Desativa o modelo de dados após o processamento                              |
//================================================================================
oModel:DeActivate()

//================================================================================
//| Restaura o posicionamento da Empresa/Filial                                  |
//================================================================================
DBSelectArea("SM0")
SM0->( DBSetOrder(1) )
SM0->( DBSeek( cEmpAux + cFilAux ) )
cFilAnt := AllTrim(SM0->M0_CODFIL)

Return(lRet)

/*
===============================================================================================================================
Programa----------: MGPE009P
Autor-------------: Alexandre Villar
Data da Criacao---: 21/02/2014
Descrição---------: Rotina de validação da parametrização do Sistema
Parametros--------: nOpc := Identifica a Pergunta que deve ser validada.
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MGPE009P( nOpc )

Local lRet		:= .T. //Se retornar .F. nao deixa sair do campo
Local cNomeVar	:= ReadVar()
Local xVarAux	:= &(cNomeVar)
Local aArea		:= FWGetArea()
Local cEmpAux	:= cEmpAnt
Local aAcesso	:= FWEmpLoad(.F.)
Local aDadAux	:= {}
Local nI,nX		:= 0

Do Case

	Case nOpc == 1 //Filiais Consideradas ?
		
		//-- Verifica se o campo esta vazio --//
		If Empty(xVarAux)
		
			Aviso( "Atenção!" , "É obrigatório informar o filtro de Filiais, clique em 'selecionar todas' para utilizar todas as Filiais." , {"Fechar"} )
			lRet := .F.
		
		//-- Verifica se o campo foi preenchido com conteudo valido --//
		Else
			
			aDadAux := U_ITLinDel( AllTrim(xVarAux) )
			
			For nI := 1 To Len(aDadAux)
				
				lRet := .F.
				
				For nX := 1 To Len(aAcesso)
					
					If aDadAux[nI] == aAcesso[nX][03]
						lRet := .T.
					EndIf
					
				Next nX
				
				If !lRet
					Aviso( "Atenção!" , "O usuário não tem acesso às 'Filiais' informadas! Verifique os dados digitados." , {"Fechar"} )
					Exit
				EndIf
				
				lRet := .F.
				
				DBSelectArea("SM0")
				SM0->( DBGoTop() )
				While SM0->(!Eof())
					
					If SM0->M0_CODIGO == cEmpAux .And. AllTrim(SM0->M0_CODFIL) == aDadAux[nI]
						lRet := .T.
						Exit
					EndIf
					
				SM0->( DBSkip() )
				EndDo
				
				If !lRet
					Aviso( "Atenção!" , "As 'Filiais' informadas não são válidas! Verifique os dados digitados." , {"Fechar"} )
					Exit
				EndIf
			
			Next nI
			
		EndIf
	
	Case nOpc == 2 //Categorias a Imp. ?
	
		If Empty(xVarAux)
		
			Aviso( "Atenção!" , "É obrigatório informar o filtro de Categorias Funcionais, clique em 'selecionar todas' para utilizar todas as Categorias." , {"Fechar"} )
			lRet := .F.
		
		Else
			
			aDadAux := U_ITLinDel( AllTrim(xVarAux) )
			
			For nI := 1 To Len(aDadAux)
				
				DBSelectArea("SX5")
				SX5->( DBSetOrder(1) )
				SX5->( DBGoTop() )
				If !SX5->( DBSeek( xFilial("SX5") + "28" + aDadAux[nI] ) )
					
					Aviso( "Atenção!" , "As 'Categorias Funcionais' informadas não são válidas! Verifique os dados digitados." , {"Fechar"} )
					lRet := .F.
					Exit
					
				EndIf
				
			Next nI
		
		EndIf

	Case nOpc == 3 //Situações ?

		If Empty(xVarAux)
		
			&(cNomeVar) := " ;"
		
		Else
			
			aDadAux := U_ITLinDel( xVarAux )
			
			For nI := 1 To Len(aDadAux)
				
				DBSelectArea("SX5")
				SX5->( DBSetOrder(1) )
				SX5->( DBGoTop() )
				If !SX5->( DBSeek( xFilial("SX5") + "31" + aDadAux[nI] ) )
					
					Aviso( "Atenção!" , "As 'Situações na Folha' informadas não são válidas! Verifique os dados digitados." , {"Fechar"} )
					lRet := .F.
					Exit
					
				EndIf
				
			Next nI
		
		EndIf

	Case nOpc == 4 //C Custo De ?

		If !Empty(xVarAux)
		
			DBSelectArea("CTT")
			CTT->( DBSetOrder(1) )
			CTT->( DBGoTop() )
			If !CTT->( DBSeek( xFilial("CTT") + xVarAux ) )
			
				Aviso( "Atenção!" , "O 'Centro de Custo' inicial informado não é válido! Verifique os dados digitados." , {"Fechar"} )
				lRet := .F.
				
			EndIf
			
		EndIf

	Case nOpc == 5 //C Custo Ate ?

		If Empty(xVarAux)
			
			Aviso( "Atenção!" , "O 'Centro de Custo' final é obrigatório! Verifique os dados digitados." , {"Fechar"} )
			lRet := .F.
			
		Else
			
			If !( Upper(AllTrim(xVarAux)) == "ZZZZZZZZ" )
			
				DBSelectArea("CTT")
				CTT->( DBSetOrder(1) )
				CTT->( DBGoTop() )
				If !CTT->( DBSeek( xFilial("CTT") + xVarAux ) )
				
					Aviso( "Atenção!" , "O 'Centro de Custo' final informado não é válido! Verifique os dados digitados." , {"Fechar"} )
					lRet := .F.
					
				EndIf
			
			EndIf
			
		EndIf

	Case nOpc == 7 //Matricula Ate ?

		If Empty(xVarAux)
			
			Aviso( "Atenção!" , "A 'Matrícula' final é obrigatória! Verifique os dados digitados." , {"Fechar"} )
			lRet := .F.
			
		EndIf

	Case nOpc == 8 //Admissão De ?

		If ( xVarAux == SToD("") )
			
			Aviso( "Atenção!" , "A 'Data de Admissão' inicial é obrigatória! Verifique os dados digitados." , {"Fechar"} )
			lRet := .F.
			
		ElseIf !( MV_PAR09 == SToD("") ) .And. xVarAux > MV_PAR09
		
			Aviso( "Atenção!" , "A 'Data de Admissão' inicial deve ser menor ou igual a final! Verifique os dados digitados." , {"Fechar"} )
			lRet := .F.
			
		EndIf

	Case nOpc == 9 //Admissão Até ?

		If ( xVarAux == SToD("") )
			
			Aviso( "Atenção!" , "A 'Data de Admissão' final é obrigatória! Verifique os dados digitados." , {"Fechar"} )
			lRet := .F.
			
		ElseIf !( MV_PAR08 == SToD("") ) .And. xVarAux < MV_PAR08
		
			Aviso( "Atenção!" , "A 'Data de Admissão' final deve ser maior ou igual a inicial! Verifique os dados digitados." , {"Fechar"} )
			lRet := .F.
				
		EndIf

	Case nOpc == 12 //Fornecedor ?
	
		If Empty(xVarAux)
		
			Aviso( "Atenção!" , "É obrigatório informar o 'Código do Fornecedor'!" , {"Fechar"} )
			lRet := .F.
			
		ElseIf !U_MGPEF3GN( MV_PAR11 ,, 1 , .T. , xVarAux )
		
			Aviso( "Atenção!" , "O 'Código do Fornecedor' informado não é válido! Verifique os dados digitados." , {"Fechar"} )
			lRet := .F.
			
		EndIf

	Case nOpc == 14 //Plano ?

		If Empty(xVarAux)
		
			Aviso( "Atenção!" , "É obrigatório informar o 'Código do Plano'!" , {"Fechar"} )
			lRet := .F.
			
		ElseIf !U_ITMedOdo( MV_PAR11 , MV_PAR12 , MV_PAR13 , .T. , xVarAux )
		
			Aviso( "Atenção!" , "O 'Código do Plano' informado não é válido! Verifique os dados digitados." , {"Fechar"} )
			lRet := .F.
			
		EndIf

	Case nOpc == 15 //Verba Tit. ?

		If Empty(xVarAux)
			
			Aviso( "Atenção!" , "A 'Verba do Titular' é obrigatória! Verifique os dados digitados." , {"Fechar"} )
			lRet := .F.
			
		Else
			
			DBSelectArea("SRV")
			SRV->( DBSetOrder(1) )
			SRV->( DBGoTop() )
			If !SRV->( DBSeek( xFilial("SRV") + xVarAux ) )
			
				Aviso( "Atenção!" , "A 'Verba do Titular' informada não é válida! Verifique os dados digitados." , {"Fechar"} )
				lRet := .F.
				
			EndIf
			
		EndIf

	Case nOpc == 16 //Verba Dep. ?

		If Empty(xVarAux)
			
			Aviso( "Atenção!" , "A 'Verba do Dependente' é obrigatória! Verifique os dados digitados." , {"Fechar"} )
			lRet := .F.
			
		Else
			
			DBSelectArea("SRV")
			SRV->( DBSetOrder(1) )
			SRV->( DBGoTop() )
			If !SRV->( DBSeek( xFilial("SRV") + xVarAux ) )
			
				Aviso( "Atenção!" , "A 'Verba do Dependente' informada não é válida! Verifique os dados digitados." , {"Fechar"} )
				lRet := .F.
				
			EndIf
			
		EndIf

EndCase

FWRestArea(aArea)

Return(lRet)

/*
===============================================================================================================================
Programa----------: MGPE009FIL
Autor-------------: Alexandre Villar
Data da Criacao---: 21/02/2014
Descrição---------: Trata o conteúdo das respostas da parametrização para ser usado na query.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGPE009FIL( cParAux , nParAux )

Local cRet	:= ""
Local nI	:= 0

If nParAux == 2

	For nI := 1 To Len(cParAux)
	
		If !Empty( SubStr( cParAux , nI , 1 ) )
			cRet += SubStr( cParAux , nI , 1 ) + ";"
		EndIf
		
	Next nI

ElseIf nParAux == 3

	For nI := 1 To Len(cParAux)
	
		If !( SubStr( cParAux , nI , 1 ) + ";" $ cRet )
			cRet += SubStr( cParAux , nI , 1 ) + ";"
		EndIf
		
	Next nI

EndIf

Return( cRet )
