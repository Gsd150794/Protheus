/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Igor Melgaço  |14/03/2022| Chamado 39463. Ajustes para nova conexão sftp "edis.chep.com"
Lucas Borges  |23/07/2025| Chamado 51340. Ajustar função para validação de ambiente de teste
Lucas Borges  |14/09/2025| Chamado 51799. Implementada função para validar ambiente de teste totvs.framework.environment.Type.get()
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "Fileio.ch"   
#Include "TBICONN.CH"
#Include "TBICODE.CH"

Static cPathOk	:= ""
Static cPathNo	:= ""
Static lViaJob	:= GetRemoteType() == -1

/*
===============================================================================================================================
Programa----------: MOMS022
Autor-------------: Frederico O. C. Jr
Data da Criacao---: 24/06/2009
Descrição---------: EDI com CHEP - Controle de localizacao dos Pallet's CHEP
Parametros--------: aParam
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS022( aParam )

Local cPerg			:= "MOMS022"
Local nDiasAux		:= 0

Private aLogErro	:= {}

Default aParam		:= {"01","01"}

// Verifica a chamada da Rotina para as tratativas do JOB
If lViaJob .Or. SELECT("SX3") = 0
   lViaJob:=.T.
	If Empty(aParam)
		u_itconout( "Falha na inicialização dos parâmetros de processamento." )
		u_itconout( "==============================================================================================================="	)
		Return
	EndIf
	// Prepara o ambiente pra processamento do JOB
	u_itconout( "==================================================[ MOMS022 ]=================================================="	)
	u_itconout( "[MOMS022]["+ DToC(Date()) +" - "+ Time() +"]: Preparando o ambiente para o processamento..."						)
	u_itconout( "Empresa: "+ aParam[01]																					)
	u_itconout( "Filial: "+ aParam[02]																					)
    _lAbriunoRdm:=.F.
	If Select("SX3") = 0
	   _lAbriunoRdm:=.T.
	   PREPARE ENVIRONMENT EMPRESA aParam[01] FILIAL aParam[02] TABLES "SB1","SB2","SC5","SC6","SD1","SD2","SD3","SF4"
	   Sleep( 5000 )
	EndIf
	u_itconout( "Ambiente inicializado com sucesso!"																	)
	u_itconout( "==============================================================================================================="	)
	
	
	// Inicializa a parametrização das Perguntas
	nDiasAux := GetMV( "IT_CHEPDIA" ,, 1 )					//Dias anteriores para a busca das NF - Somente via Schedule
	
	MV_PAR01 := Space( TamSX3("A1_COD")[01] )				//Cód. do Cliente Inicial
	MV_PAR02 := Space( TamSX3("A1_LOJA")[01] )				//Cód. da Loja Inicial
	MV_PAR03 := Space( TamSX3("A1_COD")[01] )		//Cód. do Cliente Final
	MV_PAR04 := Space( TamSX3("A1_LOJA")[01] )	//Cód. da Loja Final
	MV_PAR05 := DaySub( Date() , nDiasAux )					//Data De para busca das NF
	MV_PAR06 := DaySub( Date() , nDiasAux )					//Data Até para busca das NF
	MV_PAR07 := GetMV( "IT_CHEPABA" ,, 1 )					//Considera Abatimento ? 1=Sim;2=Não
	MV_PAR08 := ""//Diretorio esta na Static
	MV_PAR09 := Space( TamSX3("A1_COD")[01] )				//Cód. do Cliente Inicial
	MV_PAR10 := Space( TamSX3("A1_LOJA")[01] )				//Cód. da Loja Inicial
	MV_PAR11 := Space( TamSX3("A1_COD")[01] )		//Cód. do Cliente Final
	MV_PAR12 := Space( TamSX3("A1_LOJA")[01] )	//Cód. da Loja Final
	
	// Grava no Log do Console
	u_itconout( "Definição de Parâmetros:" )
	u_itconout( "MV_PAR01: "+ MV_PAR01 )
	u_itconout( "MV_PAR02: "+ MV_PAR02 )
	u_itconout( "MV_PAR03: "+ MV_PAR03 )
	u_itconout( "MV_PAR04: "+ MV_PAR04 )
	u_itconout( "MV_PAR05: "+ DToC( MV_PAR05 ) )
	u_itconout( "MV_PAR06: "+ DToC( MV_PAR06 ) )
	u_itconout( "MV_PAR07: "+ cValToChar( MV_PAR07 ) )
	u_itconout( "Dias Ant: "+ cValToChar( nDiasAux ) )
	u_itconout( "==============================================================================================================="	)
	u_itconout( "Iniciando o processamento..." )
	
	// Chama a rotina de processamento
	cPathOk:=AllTrim( GetMV( "IT_CHPENV" ,, "\data\italac\moms022\enviado\" ) )
    cPathNo:=AllTrim( GetMV( "IT_CHPNEV" ,, "\data\italac\moms022\nao_enviado\" ) )
	MOMS022PRC()
	
	If !Empty( aLogErro )
		MOMS022Mail()
	EndIf
	
	// Finaliza o ambiente e encerra a rotina
	If _lAbriunoRdm
	   RESET ENVIRONMENT
	EndIf
	
	u_itconout( "Fim da Rotina - Data: "+ DToC(Date()) +" / Hora: "+ Time()												)
	u_itconout( "==============================================================================================================="	)
	
Else
	// Verifica o cadastro das perguntas
    cPathOk:=AllTrim( GetMV( "IT_CHPENV" ,, "\data\italac\moms022\enviado\" ) )
    cPathNo:=AllTrim( GetMV( "IT_CHPNEV" ,, "\data\italac\moms022\nao_enviado\" ) )
	
	// Confirmação das Perguntas e processamento.
	While Pergunte(cPerg,.T.)
         
        If  (!Empty(MV_PAR01+MV_PAR02) .Or. !Empty(MV_PAR03+MV_PAR04)) .And. (!Empty(MV_PAR09+MV_PAR10) .Or. !Empty(MV_PAR11+MV_PAR12))
            U_ITMsg("Informe somente o filtro inicial e final do Cliente / Loja ou somente do Fornecedor / Loja, ou deixe todos os campos em branco do Fornecedor / Loja e do Cliente / Loja para trazer todos.","Atenção",,1)
            Loop
        EndIf  
	
	
		Processa( {|| MOMS022PRC() } , "Montando relação de notas:" , "Iniciando a rotina..." )
	    
	EndDo
	

EndIf
   	
Return

/*
===============================================================================================================================
Programa----------: MOMS022PRC
Autor-------------: Alexandre Villar
Data da Criacao---: 15/05/2014
Descrição---------: Controle do processamento de geração e transmissão dos arquivos
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
 */
Static Function MOMS022PRC()

Local cQry			:= ""
Local cAlias		:= GetNextAlias()
Local cCodProd		:= AllTrim( GetMV( "IT_CCHEP" ,, "" ) )
Local nAtuReg		:= 0

Private cCodOrig	:= AllTrim( GetMV("IT_CODCHEP") )
Private cCodEmp		:= AllTrim( GetMV("IT_EMPCHEP") )
Private aNotas		:= {}
Private cChave		:= ""
Private nTotReg		:= 0
Private aNotMark	:= {}
Private nQtPalet	:= 0
Private nQtMov		:= 0 
Private cArqTxt 	:= 	""

U_ITLOGACS()
// Monta a consulta das notas
cQry := " SELECT "
cQry += " 	SD2.D2_SERIE	, "
cQry += " 	SD2.D2_DOC		, "
cQry += " 	SD2.D2_EMISSAO	, "
cQry += " 	SD2.D2_CLIENTE	, "
cQry += " 	SD2.D2_LOJA  	, "
cQry += " 	SD2.D2_TIPO  	, "
cQry += " 	SB1.B1_I_CPCHE	, "
cQry += " 	SD2.D2_QUANT	  "

// Verifica o abatimento de devoluções
If MV_PAR07 == 1

cQry += " - (	SELECT COALESCE( SUM(SD1.D1_QUANT) , 0 ) FROM "+ RetSQLName("SD1") +" SD1 "
cQry += "		WHERE "
cQry += "			SD1.D_E_L_E_T_	= ' ' "
cQry += "		AND SD1.D1_FILIAL	= SD2.D2_FILIAL "
cQry += "		AND SD1.D1_NFORI	= SD2.D2_DOC "
cQry += "		AND SD1.D1_SERIORI	= SD2.D2_SERIE "
cQry += "		AND SD1.D1_FORNECE  = SD2.D2_CLIENTE "
cQry += "		AND SD1.D1_LOJA     = SD2.D2_LOJA ) AS D2_QUANT "

EndIf

cQry += " FROM "+ RetSQLName("SD2") +" SD2 "

cQry += " INNER JOIN "+ RetSQLName("SB1") +" SB1 ON "
cQry += " 		SB1.B1_COD		= SD2.D2_COD "
cQry += " AND	SB1.B1_I_CPCHE	<> ' ' "
cQry += " WHERE "
cQry += " 		SD2.D_E_L_E_T_	= ' ' "
cQry += " AND	SB1.D_E_L_E_T_	= ' ' "
cQry += " AND	SD2.D2_FILIAL	= '"+ xFilial("SD2") +"' "
cQry += " AND	SD2.D2_COD		= '"+ AllTrim(cCodProd) +"' "

If !Empty(MV_PAR01+MV_PAR02) .Or. !Empty(MV_PAR03+MV_PAR04)
   cQry += " AND (D2_CLIENTE BETWEEN '" + MV_PAR01 + "' AND '" + MV_PAR03 + "')"
   cQry += " AND (D2_LOJA BETWEEN '" + MV_PAR02 + "' AND '" + MV_PAR04 + "')"

ElseIf !Empty(MV_PAR09+MV_PAR10) .Or. !Empty(MV_PAR11+MV_PAR12)
   cQry += " AND (D2_CLIENTE BETWEEN '" + MV_PAR09 + "' AND '" + MV_PAR11 + "')"
   cQry += " AND (D2_LOJA BETWEEN '" + MV_PAR10 + "' AND '" + MV_PAR12 + "')"

EndIf
cQry += " AND	SD2.D2_EMISSAO	BETWEEN '"+ DToS( MV_PAR05 )	+"' AND '"+ DToS( MV_PAR06 )	+"' "

If MV_PAR07 == 1

cQry += " AND	SD2.D2_QUANT	- (	SELECT COALESCE(SUM(SD1.D1_QUANT),0) FROM " + RetSQLName("SD1") + " SD1 "
cQry += " 							WHERE "
cQry += " 								SD1.D_E_L_E_T_	= ' ' "
cQry += " 							AND	SD1.D1_FILIAL	= SD2.D2_FILIAL "
cQry += " 							AND SD1.D1_NFORI	= SD2.D2_DOC "
cQry += " 							AND SD1.D1_SERIORI	= SD2.D2_SERIE "
cQry += " 							AND SD1.D1_FORNECE  = SD2.D2_CLIENTE "
cQry += " 							AND SD1.D1_LOJA     = SD2.D2_LOJA ) > 0 "

EndIf
    
// Verifica e inicializa a tabela temporária
If Select(cAlias) > 0
	(cAlias)->( DBCloseArea() )
EndIf

If lViaJob
	
	u_itconout( "Preparando a tabela temporária..." )
	
	DBUseArea( .T. , "TOPCONN" , TcGenQry( ,, cQry ) , cAlias , .T. , .F. )
	DBSelectArea(cAlias)
	(cAlias)->( DBGoTop() )
	(cAlias)->( DBEval( {|| nTotReg++ } ) )
	(cAlias)->( DBGoTop() )
	
	u_itconout( "Iniciando a leitura dos registros..." )
	
Else

	LJMsgRun( "Verificando as Notas..."			, "Aguarde!" , {|| DBUseArea( .T. , "TOPCONN" , TcGenQry( ,, cQry ) , cAlias , .T. , .F. )	} )
	LJMsgRun( "Iniciando a área temporária..."	, "Aguarde!" , {|| DBSelectArea(cAlias)														} )
	LJMsgRun( "Posicionando os registros..."	, "Aguarde!" , {|| (cAlias)->( DBGoTop() )													} )
	LJMsgRun( "Verificando os registros..." 	, "Aguarde!" , {|| (cAlias)->( DBEval( {|| nTotReg++ } ) )									} )
	LJMsgRun( "Inicializando..."				, "Aguarde!" , {|| (cAlias)->( DBGoTop() )													} )
	
	ProcRegua( nTotReg )
	
EndIf

If nTotReg > 0

	While (cAlias)->(!Eof())
		
		If !lViaJob
			nAtuReg++
			IncProc( "["+ StrZero( nAtuReg , 9 ) +"] de ["+ StrZero( nTotReg , 9 ) +"]" )
		EndIf

        If (cAlias)->D2_TIPO # "D"
           _cAliasBusca:="SA1"
           _cCampoBusca:="A1_NREDUZ"
           _CCHEP:=AllTrim(Posicione(_cAliasBusca,1,xFilial(_cAliasBusca)+(cAlias)->D2_CLIENTE+(cAlias)->D2_LOJA,"A1_I_CCHEP"))
           _cNome:=""
        Else
           _cAliasBusca:="SA2"
           _cCampoBusca:="A2_NREDUZ"
           _CCHEP:=Space(10)
           _cNome:=" [D]"
        EndIf
        _cNome:=AllTrim(Posicione(_cAliasBusca,1,xFilial(_cAliasBusca)+(cAlias)->D2_CLIENTE+(cAlias)->D2_LOJA,_cCampoBusca))+_cNome
		
		aAdd( aNotas , {	lViaJob					,;//01
							(cAlias)->D2_DOC		,;//02
							(cAlias)->D2_SERIE		,;//03
							(cAlias)->D2_EMISSAO	,;//04
							(cAlias)->D2_CLIENTE	,;//05
							(cAlias)->D2_LOJA		,;//06
							_cNome                  ,;//07
							_CCHEP               	,;//08
							(cAlias)->B1_I_CPCHE	,;//09
							(cAlias)->D2_QUANT		})//10
	
		cChave += (cAlias)->D2_DOC
		
		aAdd( aNotMark ,	(cAlias)->D2_SERIE	+ " - " + DToC( SToD( (cAlias)->D2_EMISSAO ) )		+ " - " +;
							(cAlias)->D2_CLIENTE+ " - " + (cAlias)->D2_LOJA							+ " - " +;
							_cNome            	+ " - " + AllTrim( Transform( (cAlias)->D2_QUANT	, "@E 9,999" ) ) )
		
	(cAlias)->(DBSkip())
	EndDo
	
	(cAlias)->(DBCloseArea())
	
	If lViaJob
	
		u_itconout( "Total de Registros selecionados: "+ StrZero( nTotReg , 9 ) )
		MOMS022G()
		
	Else
		
		If MOMS022S() .And. MOMS022T()
		
			Processa({|| MOMS022G() },"Processando...")
			
		EndIf
	
	EndIf

Else

	// Caso o processamento atual não encontre movimentação verifica se existem
	// arquivos pendentes de envio para transmitir via FTP
	If lViaJob
		
		u_itconout( "Não foram encontrados dados para gerar novos arquivos!" )
		u_itconout( "Verificando para enviar arquivos pendentes..." )
		
		aAdd( aLogErro , "Não foram encontrados registros de movimentação para enviar." )
		
		MOMS022FTP()
		
	Else
		
		If U_ITMsg( "Não foram encontrados dados para a geração de novos arquivos! Deseja verificar o envio de arquivos pendentes ?" , "Atenção!" , ,3,2,2 ) 
			
			Processa( {|| MOMS022FTP() } , "Verificando arquivos para enviar..." )
			
		EndIf
	
	EndIf
	
EndIf

Return

/*
===============================================================================================================================
Programa----------: MOMS022T
Autor-------------: Rafael Ramos Lavinas
Data da Criacao---: 24/07/2009
Descrição---------: Tela para apresentacao das notas fiscais baseadas nas perguntas "MOMS002"
Parametros--------: Nenhum
Retorno-----------: .T. ou .F.
===============================================================================================================================
*/
Static Function MOMS022T()

Local lRet			:= .F.
Local aNFImp		:= {}
Local nI			:= 0

Private _oDlg		:= Nil
Private olbNotas	:= Nil

DEFINE MSDIALOG _oDlg TITLE "[ Geração - EDI CHEP ]" FROM 000,000 TO 270,600 PIXEL

	@ 005,005 TO 114,297 LABEL " Notas selecionadas: "		PIXEL OF _oDlg

	@ 118,225 BUTTON "OK"		SIZE 035,012 PIXEL OF _oDlg ACTION ( lRet := .T. , _oDlg:End() )
	@ 118,262 BUTTON "Cancelar"	SIZE 035,012 PIXEL OF _oDlg ACTION ( _oDlg:End() )

	@ 015,010 LISTBOX olbNotas	Fields HEADER "Num. NF","Serie","Emissão","Cod./Loja Cliente","Nome Fantasia","Cod. Origem","Cod. Destino","Quantidade" ;
								SIZE 282,095 PIXEL OF _oDlg ColSizes 35,25,30,50,100,40,40,40
	
	olbNotas:SetArray( aNFImp )
	
	// Carrega o Array para exibir a lista na tela
	For nI := 1 To Len( aNotas )
	
		If ( aNotas[nI][01] )
		
			aAdd( aNFImp , {	aNotas[nI][02]								,;
								aNotas[nI][03]								,;
								DToC( SToD( aNotas[nI][04] ) )				,;
								aNotas[nI][5] +"/"+ aNotas[nI][06]			,;
								AllTrim( aNotas[nI][07] )					,;
								cCodOrig						 			,;
								aNotas[nI][05] + aNotas[nI][06]	 			,;
								TransForm( aNotas[nI][10] , "@E 9,999" ) 	})
			
			nQtPalet += aNotas[nI][10]
			nQtMov++
		
		EndIf
		
	Next nI
	
	If Empty( aNFImp )
		aNFImp := { { "" , "" , "" , "" , "" , "" , "" , "" } }
	EndIf
	
	// Carrega o Objeto do ListBox com os dados do Array
	olbNotas:bLine := {|| {	aNFImp[olbNotas:nAT,01]	,;
							aNFImp[olbNotas:nAT,02]	,;
							aNFImp[olbNotas:nAT,03]	,;
							aNFImp[olbNotas:nAT,04]	,;
							aNFImp[olbNotas:nAT,05]	,;
							aNFImp[olbNotas:nAT,06]	,;
							aNFImp[olbNotas:nAT,07]	,;
							aNFImp[olbNotas:nAT,08]	}}

ACTIVATE MSDIALOG _oDlg CENTERED 

Return( lRet )

/*
===============================================================================================================================
Programa----------: MOMS022G
Autor-------------: Frederico O. C. Jr
Data da Criacao---: 25/06/2009
Descrição---------: Função de processamento da geração do arquivo TXT
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS022G()

Local cEOL    		:= CHR(13) + CHR(10)
Local nRegImp		:= 0
Local nI			:= 0
Local nHdl			:= 0
Local nTotReg		:= 0
Local nQuanti		:= 0
Local cLin			:= ""
Local cEmpChep		:= GetMv("IT_EMPCHEP")
Local cDataAux		:= DToS(dDataBase) 
Local cSeqNum		:= GetMv("IT_SEQCHEP")
Local cCodRem		:= GetMv("IT_CODCHEP")    
Local cCodDest		:= ""
Local cNomeCli		:= ""
Local cEndCli		:= ""
Local cCidCli		:= ""
Local cCepCli		:= ""
Local cEstCli		:= ""
Local cCodEquip		:= ""
Local cData			:= ""
Local _cPthFil		:= cPathNo + cFilAnt +'\'

Private cNome		:= ""

cSeqNum	:= Soma1( StrZero( Val( cSeqNum ) , 10 ) )
cCodRem	:= StrZero( Val( cCodRem ) , 10 )
cData	:= SubStr( cDataAux , 7 , 2 ) +"_"+ SubStr( cDataAux , 5 , 2 ) +"_"+ SubStr( cDataAux , 1 , 4 )
cNome	:= "BR"+ StrZero( Val( cCodEmp ) , 10 ) +"_"+ cSeqNum +"_"+ cData

If !lViaJob .And. !Empty(MV_PAR08)
    cPathOk:=AllTrim(MV_PAR08)
EndIf    
// Verifica a criação dos Diretórios
If !ExistDIR( cPathOk )

	If MAKEDIR( cPathOk ) <> 0
		
		If lViaJob
			u_itconout( "Não foi possível utilizar o diretório: "+ cEOL + cPathOk )
			aAdd( aLogErro , "Não foi possível utilizar o diretório: "+ cPathOk )
		Else
			U_ITMsg( "Não foi possível utilizar o diretório: "+ cEOL + cPathOk , "Atenção!" , ,1 )
		EndIf
		
		Return
		
	EndIf
	
EndIf

If !ExistDIR( _cPthFil )

	If MAKEDIR( _cPthFil ) <> 0
	
		If lViaJob
			u_itconout( "Não foi possível utilizar o diretório: "+ cEOL + _cPthFil )
			aAdd( aLogErro , "Não foi possível utilizar o diretório: "+ _cPthFil )
		Else
			U_ITMsg( "Não foi possível utilizar o diretório: "+ cEOL + _cPthFil , "Atenção!" , ,1 )
		EndIf
		
		Return
		
	EndIf
	
EndIf

// Verifica a criação do arquivo
cArqTxt := _cPthFil + cNome + ".txt"
nHdl	:= FCreate( cArqTxt , FC_NORMAL ,, .T. )

If nHdl == -1
	
	If lViaJob
		u_itconout( "Falha ao criar o arquivo ["+ cArqTxt +"]. Verifique com a área de TI/ERP." )
		aAdd( aLogErro , "Falha ao criar o arquivo: "+ cArqTxt )
	Else
		U_ITMsg( "Falha ao criar o arquivo ["+ cArqTxt +"]. Verifique com a área de TI/ERP." , "Atenção!" , ,1 )
	EndIf
	
Else
	
	nTotReg := Len(aNotas)
	
	If !lViaJob
		ProcRegua( nTotReg + 2 )
	EndIf
	
	// Monta o cabeçalho do arquivo
	cLin := "*****+"							// | 001 - 006 | Início da Linha
	cLin += "FROM+CHEP-"						// | 007 - 016 | Campo FROM
	cLin += "BR"								// | 017 - 018 | Campo Código do País
	cLin += StrZero( Val( cEmpChep ) , 10 )		// | 019 - 028 | Codigo da Localidade CHEP
	cLin += "+"									// | 029 - 029 | Seperador Chep
	cLin += "RCVD+"								// | 030 - 034 | Qualificador para data do arquivo
	cLin += PadR( cDataAux , 08 )				// | 035 - 042 | Data do Arquivo
	cLin += "+"									// | 043 - 043 | Separador Chep
	cLin += "FREF+"								// | 044 - 048 | Qualificador para referencia do arquivo
	cLin += PadR( cSeqNum , 10 )				// | 049 - 058 | Sequencia numérica do arquivo
	cLin += "+"									// | 059 - 059 | Separador Chep
	cLin += "NORC+"								// | 060 - 064 | Campo NORC
	cLin += StrZero( nQtMov , 09 )				// | 065 - 073 | Quantidade de Notas
	cLin += "+"									// | 074 - 074 | Separador Chep
	cLin += "SEPR+"								// | 075 - 079 | Campo SEPR
	cLin += "~+"								// | 080 - 081 | Separador Chep
	cLin += "VERS+"								// | 082 - 086 | Campo Versão
	cLin += "1.04"								// | 087 - 090 | Identificação do Layout do Arquivo
	cLin += "+*****"							// | 091 - 096 | Fim da Linha
	cLin += cEOL								// Encerra a linha do cabeçalho
	
	FWrite( nHdl , cLin , Len(cLin) )
	
	// Monta os Itens do arquivo
	SA1->( DBSetOrder(1) )
    SA2->( DBSetOrder(1) )
	For nI := 1 To nTotReg
	
		If aNotas[nI][01]
		
			DBSelectArea("SD2")
			SD2->( DBSetOrder(3) )
			If SD2->( DBSeek( xFilial("SD2") + aNotas[nI][02] + aNotas[nI][03] ) )
			
				nQuanti		:= SD2->D2_QUANT
			
			Else
				u_itconout( "Não conseguiu posicionar na SD2: ["+ xFilial("SD2") + aNotas[nI][02] + aNotas[nI][03] +"]" )
				Loop
			EndIf

        If SD2->D2_TIPO # "D"
			If SA1->( DBSeek( xFilial("SA1") + aNotas[nI][05] + aNotas[nI][06] ) )
				cCodDest	:= SA1->A1_CGC //05/11/14 - ALEX WALLAUER- Alterado em vez de usar o Codigo do Cliente + Loja usar o CNPJ. Chamado: 38203
				cNomeCli	:= SA1->A1_NOME
				cEndCli		:= SA1->A1_END
				cCidCli		:= SA1->A1_MUN
				cCepCli		:= SA1->A1_CEP
				cEstCli		:= SA1->A1_EST
			Else
				u_itconout( "Não conseguiu posicionar na SA1: ["+ xFilial("SA1") + aNotas[nI][05] + aNotas[nI][06] +"]" )
				Loop
			EndIf
	   Else
			If SA2->( DBSeek( xFilial("SA2") + aNotas[nI][05] + aNotas[nI][06] ) )
				cCodDest	:= SA2->A2_CGC //05/11/14 - ALEX WALLAUER- Alterado em vez de usar o Codigo do Cliente + Loja usar o CNPJ. Chamado: 38203
				cNomeCli	:= SA2->A2_NOME
				cEndCli		:= SA2->A2_END
				cCidCli		:= SA2->A2_MUN
				cCepCli		:= SA2->A2_CEP
				cEstCli		:= SA2->A2_EST
			Else
				u_itconout( "Não conseguiu posicionar na SA2: ["+ xFilial("SA2") + aNotas[nI][05] + aNotas[nI][06] +"]" )
				Loop
			EndIf
	   EndIf		
			
			DBSelectArea("SB1")
			SB1->( DBSetOrder(1) )
			If SB1->( DBSeek( xFilial("SB1") + SD2->D2_COD ) )
			
				cCodEquip	:= SB1->B1_I_CPCHE
				
			Else
				u_itconout( "Não conseguiu posicionar na SB1: ["+ xFilial("SB1") + SD2->D2_COD +"]" )
				Loop
			EndIf
			
			// Atualiza o contador e imprime a linha do arquivo
			nRegImp++
			
			cLin := "LI="									// | 001 - 003 | Início da Linha
			cLin += "~"										// | 004 - 004 | Separador CHEP
			cLin += StrZero( nI , 06 )						// | 005 - 010 | Número do Item
			cLin += "~"										// | 011 - 011 | Separador CHEP
			cLin += "1"										// | 012 - 012 | Flag de Local: 1 = Remetente/Origem ; 2 = Destinatário/Destino
			cLin += "~"										// | 013 - 013 | Separador CHEP
			cLin += "BR"									// | 014 - 015 | Código do País
			cLin += "~"										// | 016 - 016 | Separador CHEP
			cLin += "SA"									// | 017 - 018 | Tipo de Código do Remetente
			cLin += "~"										// | 019 - 019 | Separador CHEP
			cLin += PadR( cCodRem , 10 )					// | 020 - 029 | Código do Remetente
			cLin += "~"										// | 030 - 030 | Separador CHEP
			cLin += "IN"									// | 031 - 032 | Tipo de Código do Destinatário
			cLin += "~"										// | 033 - 033 | Separador CHEP
			cLin += PadR( cCodDest , 14 )					// | 034 - 043 | Código do Destinatário
			cLin += "~"										// | 044 - 044 | Separador CHEP
			cLin += "90"									// | 045 - 046 | Código do Tipo de Equipamento
			cLin += "~"										// | 047 - 047 | Separador CHEP
			cLin += PadR( AllTrim( cCodEquip ) , 04 )		// | 048 - 051 | Código de Identificação do Equipamento
			cLin += "~"										// | 052 - 052 | Separador CHEP
			cLin += PadR( aNotas[nI][04] , 08 )				// | 053 - 060 | Data de Emissão
			cLin += "~"										// | 061 - 061 | Separador CHEP
			cLin += "~"										// | 062 - 062 | Separador CHEP
			cLin += StrZero( nQuanti , 5 )					// | 063 - 067 | Quantidade
			cLin += "~"										// | 068 - 068 | Separador CHEP
			cLin += StrZero( Val( aNotas[nI][02] ) , 09 )	// | 069 - 077 | Número da Nota
			cLin += "~"										// | 078 - 078 | Separador CHEP
			cLin += StrZero( Val( aNotas[nI][03] ) , 03 )	// | 079 - 081 | Série da Nota
			cLin += "~"										// | 082 - 082 | Separador CHEP
			cLin += "~"										// | 083 - 083 | Separador CHEP
			cLin += "~"										// | 084 - 084 | Separador CHEP
			cLin += "~"										// | 085 - 085 | Separador CHEP
			cLin += "~"										// | 086 - 086 | Separador CHEP
			cLin += "~"										// | 087 - 087 | Separador CHEP
			cLin += "~"										// | 088 - 088 | Separador CHEP
			cLin += "~"										// | 089 - 089 | Separador CHEP
			cLin += PadR( cNomeCli , 40 )					// | 090 - 129 | Nome do Cliente
			cLin += "~"										// | 130 - 130 | Separador CHEP
			cLin += PadR( cEndCli , 60 )					// | 131 - 190 | Endereço do Cliente
			cLin += "~"										// | 191 - 191 | Separador CHEP
			cLin += PadR( cCidCli , 40 )					// | 192 - 231 | Cidade do Cliente
			cLin += "~"										// | 232 - 232 | Separador CHEP
			cLin += PadR( cCepCli , 08 )					// | 233 - 240 | Cep do Cliente
			cLin += "~"										// | 241 - 241 | Separador CHEP
			cLin += PadR( cEstCli , 02 )					// | 242 - 243 | UF do Cliente
			cLin += "~"										// | 244 - 244 | Separador CHEP
			cLin += "BR"									// | 245 - 246 | Código do País do Cliente
			cLin += "~"										// | 247 - 247 | Separador CHEP
			cLin += "~"										// | 248 - 248 | Separador CHEP
			cLin += "~<"									// | 249 - 250 | Fim da linha
			cLin += cEOL									// Encerra a linha do item
			
			FWrite(nHdl,cLin,Len(cLin))
		
		EndIf
		
		If !lViaJob
			IncProc( "["+ StrZero( nI , 9 ) +"] de ["+ StrZero( nTotReg , 9 ) +"]")
		EndIf
	
	Next nI
	
	If !lViaJob
		IncProc( "["+ StrZero( nI , 9 ) +"] de ["+ StrZero( nTotReg , 9 ) +"]")
	EndIf
	
	If nRegImp > 0
	
		// Monta o Rodapé do arquivo
		cLin := "*****+"							// | 001 - 006 | Início da Linha
		cLin += "NORC+"								// | 007 - 011 | Identificador do número de registro
		cLin += StrZero( nQtMov , 09 )				// | 012 - 020 | Quantidade de Notas
		cLin += "+"									// | 021 - 021 | Separador CHEP
		cLin += "SQTY+"				 				// | 022 - 026 | Tipo de Totalizador
		cLin += StrZero( nQtPalet , 05 )			// | 027 - 031 | Quantidade de Palets
		cLin += "+Eof"								// | 032 - 035 | Fim da Linha
		
		FWrite( nHdl , cLin , Len(cLin) )
		FClose( nHdl )
		
		//Atualiza o Sequencial do CHEP no parâmetro de Controle
		PutMV( "IT_SEQCHEP" , cSeqNum )
		
		// Chama rotina de processamento do envio dos arquivos para o FTP
		MOMS022FTP()
		
	Else
		// Fecha e apaga o arquivo se o mesmo For gerado vazio                     |
		FClose( nHdl )
		FErase( cArqTxt )
		
		If lViaJob
			u_itconout( "Não foram impressos registros no arquivo e o mesmo foi excluído!" )
			aAdd( aLogErro , "Não foram encontrados registros de movimentação para enviar." )
		Else
			U_ITMsg( "Não foram impressos registros no arquivo e o mesmo foi excluído!" , "Atenção!" , ,1 )
		EndIf
	
	EndIf

EndIf

Return

/*
===============================================================================================================================
Programa----------: MOMS022S
Autor-------------: Frederico O. C. Jr
Data da Criacao---: 12/06/2009
Descrição---------: Programa para selecao das notas a serem geradas no EDI do Carrefour
Parametros--------: Nenhum
Retorno-----------: .T.
===============================================================================================================================
*/
Static Function MOMS022S()

Local nI			:= 0
Local nPos			:= 0
Local nTotSel		:= 0

Private nTam		:= 9
Private nMaxSelect	:= nTotReg
Private cRet		:= ""
Private cTitulo		:= "Seleção de Notas - EDI CHEP"

#IFDEF WINDOWS
	oWnd := GetWndDefault()
#EndIf

// Chama a função padrão do sistema para exibição das opções
f_Opcoes( @cRet , cTitulo , aNotMark , cChave , 12 , 49 , .F. , nTam , nMaxSelect )

// Tratamento do retorno para remover os "*" dos não selecionados
cRet	:= AllTrim( StrTran( cRet , "*" , "" ) )
nTotSel	:= Int( Len( cRet ) / 9 )

// Processa a marcação dos dados do ListBox
For nI := 1 To nTotSel
	
	nPos := aScan( aNotas , {|x| AllTrim( x[02] ) == SubStr( cRet , 1 + ( 9 * ( nI - 1 ) ) , 9 ) } )
	
	If nPos <> 0
		aNotas[nPos][01] := .T.
	EndIf

Next nI

Return !Empty(cRet)

/*
===============================================================================================================================
Programa----------: MOMS022FTP
Autor-------------: Talita Teixeira
Data da Criacao---: 18/03/2013
Descrição---------: Funcao responsavel por enviar o arquivo para o ftp
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS022FTP()

Local _cPthFil	:= cPathNo + cFilAnt +'\'
Local aArqDir	:= DIRECTORY( _cPthFil +"*.txt" )
Local aArqEnv	:= {}
Local aLogEnv	:= {}
Local aRetEnv 	:= {}
Local cServer 	:= GetMV( "IT_CHEPFTP" ,, "edi.chep.com" )//"ftpedi.chep.com"
Local nPorta    := GetMV( "IT_CHEPPTA" ,, 21 )
Local cUser  	:= GetMV( "IT_CHEPUSR" ,, "BR116780" )
Local cPass    	:= GetMV( "IT_CHEPFTP" ,, "15030924" )
Local nI		:= 0
Local nArqFlh	:= 0
Local _nAux		:= 0
Local _lRename	:= .T.
Local lSftp     := SuperGetMV("IT_SFTPCHE",.T.,.T.) //Tranferencia para Sftp

If lSftp
	cServer := SuperGetMV("IT_CHEPFTP",.T., "edis.chep.com")//"ftpedi.chep.com"
EndIf

If Empty( aArqDir )
	
	If lViaJob
		u_itconout( "Não foram encontrados arquivos para enviar no diretório ["+ _cPthFil +"]." )
	Else
		U_ITMsg( "Não foram encontrados arquivos para enviar no diretório ["+ _cPthFil +"]." , "Atenção!" , ,1 )
	EndIf
	
	Return
	
Else
	
	For nI := 1 To Len( aArqDir )
	
		If File( _cPthFil + aArqDir[nI][01] )
			aAdd( aArqEnv , aArqDir[nI][01] )
		EndIf
	
	Next nI

EndIf

If Empty( aArqEnv )
	
	If lViaJob
		u_itconout( "Os arquivos selecionados não existem ou foram excluídos do diretório ["+ _cPthFil +"]." )
		aAdd( aLogErro , "Os arquivos selecionados não existem ou foram excluídos do diretório: "+ _cPthFil )
	Else
		U_ITMsg( "Os arquivos selecionados não existem ou foram excluídos do diretório ["+ _cPthFil +"]." , "Atenção!" , ,1)
	EndIf
	
	Return
	
Else
	
	If lSftp
		_cPasta:="/incoming/"
	Else
		_cPasta:="\incoming"
	EndIf

	If lViaJob
		aRetEnv := ITENVFTP( cServer , nPorta , cUser , cPass , _cPthFil , aArqEnv , .T. , _cPasta , lViaJob,lSftp )
	Else
		LjMsgRun( "Enviando arquivos ao servidor..." , "Aguarde!" , {|| aRetEnv := ITENVFTP( cServer , nPorta , cUser , cPass , _cPthFil , aArqEnv , .T. , _cPasta,,lSftp ) } )
	EndIf

	If Empty( aRetEnv )
		
		If lViaJob
			u_itconout( "Falhou ao enviar os arquivos para o FTP e os mesmos serão mantidos no diretório ["+ _cPthFil +"]" )
			aAdd( aLogErro , "Falhou ao enviar os arquivos para o FTP e os mesmos serão mantidos no diretório: "+ _cPthFil )
		Else
			U_ITMsg( "Os arquivos não foram enviados e serão mantidos no diretório ["+ _cPthFil +"]" , "Atenção!" , ,1 )
		EndIf
		
	Else
		
		For nI := 1 To Len( aRetEnv )
		
			If FRename( _cPthFil + aRetEnv[nI] , cPathOk + aRetEnv[nI] ) == -1
				
				_nAux		:= 1
				_lRename	:= .T.
				
				While _nAux <= 5 .And. _lRename
				
					If FRename( _cPthFil + aRetEnv[nI] , cPathOk + SubStr( aRetEnv[nI] , 1 , Len(aRetEnv[nI]) - 4 ) + '_'+ cValToChar(_nAux) +'.txt' ) == -1
						_nAux++
					Else
						_lRename := .F.
					EndIf
				
				EndDo
				
				If _lRename
				
					If lViaJob
						u_itconout( "Falhou ao copiar os arquivos para o diretório 'Enviados' e os mesmos serão mantidos no diretório ["+ _cPthFil +"]" )
						aAdd( aLogErro , "Falhou ao copiar os arquivos para o diretório 'Enviados' e os mesmos serão mantidos no diretório: "+ _cPthFil )
					Else
						U_ITMsg( "Falhou ao copiar os arquivos para o diretório 'Enviados' e os mesmos serão mantidos no diretório ["+ _cPthFil +"]" , "Atenção!" , ,1 )
					EndIf
					
				EndIf
				
			EndIf
			
		Next nI
		
		For nI := 1 To Len( aArqEnv )
		
			If aScan( aRetEnv , aArqEnv[01] ) > 0
			
				aAdd( aLogEnv , { aArqEnv[nI] , "Enviado"		} )
				
			Else
			
				aAdd( aLogEnv , { aArqEnv[nI] , "Não enviado"	} )
				nArqFlh++
				
			EndIf
			
		Next nI
		
	EndIf

EndIf

If nArqFlh > 0

	If lViaJob
		u_itconout( "Falhou ao enviar alguns arquivos para o FTP e os mesmos serão mantidos no diretório ["+ _cPthFil +"]." )
		aAdd( aLogErro , "Falhou ao enviar alguns arquivos para o FTP e os mesmos serão mantidos no diretório: "+ _cPthFil )
	Else
		MessageBox( "Não foram enviados todos os arquivos para o servidor FTP. Verifique os diretórios dos arquivos [\data\italac\moms022\]." , "Atenção!" , 0 )
		U_ITListBox( "Arquivos enviados para o FTP:" , { "Arquivo" , "Status" } , aLogEnv , .F. )
	EndIf

ElseIf !Empty( aRetEnv )

	If lViaJob
	
		u_itconout( "Todos os arquivos foram enviados para o servidor FTP. Verifique o diretório ["+ cPathOk +"]." )
		
	Else
	
		U_ITMsg( "Todos os arquivos foram enviados para o servidor FTP. Verifique o diretório ["+ cPathOk +"]." , "Concluído!" , ,2 )
		U_ITListBox( "Arquivos enviados para o FTP:" , { "Arquivo" , "Status" } , aLogEnv , .F. )
		
	EndIf
	
EndIf

Return

/*
===============================================================================================================================
Programa----------: MOMS022Mail
Autor-------------: Alexandre Villar
Data da Criacao---: 19/05/2014
Descrição---------: Processa o envio de e-mail caso tenha ocorrido alguma inconsistência durante o processamento
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS022Mail()

Local cConfig	:= GetMV( "IT_CMWFNF" ,, "001" )
Local aConfig	:= U_ITCFGEML( cConfig )
Local cLog		:= ""
Local cMsgAux	:= ""
Local cMailDes	:= GetMV( "IT_CHEPEDE" ,, "sistema@italac.com.br" )
Local nI		:= 0 

cMsgAux := '<HMTL>'
cMsgAux += '<HEAD>'
cMsgAux += '<META http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />'
cMsgAux += '<TITLE>Notificação de Falha</TITLE>'
cMsgAux += '</HEAD>'
cMsgAux += '<BODY><br>'
cMsgAux += '<FONT FACE="Courier New" Style="font-size:12px">'
cMsgAux	+= 'Relatório de processamento do envio de Arquivos "EDI Chep" para o servidor FTP:<br>'
cMsgAux += '-------------------------------------------------------------------------------------------------------<br>'
cMsgAux += ' Ambiente.........: '+ GetEnvServer() +'<br>'
cMsgAux += ' Empresa/Filial...: '+ cEmpAnt +"/"+ cFilAnt + '<br>'
cMsgAux += ' Data Proc........: '+ DToC( Date() ) +'<br>'
cMsgAux += ' Hora.............: '+ Time() +'<br>'
cMsgAux += '-------------------------------------------------------------------------------------------------------<br>'

For nI := 1 To Len( aLogErro )
	cMsgAux += aLogErro[nI] + '<br>'
Next nI

cMsgAux += '<br>'
cMsgAux += '=======================================================================================================<br>'
cMsgAux += '<i><b> Atenção: essa é uma mensagem automática, favor não responder. </b></i>                          <br>'
cMsgAux += '=======================================================================================================<br>'
cMsgAux += '</FONT>'
cMsgAux += '</BODY>'
cMsgAux += '</HMTL>'

U_ITENVMAIL( aConfig[01] , cMailDes ,,, "EDI Chep - Workflow - Processamento agendado (Schedule)" , cMsgAux ,, aConfig[01] , aConfig[02] , aConfig[03] , aConfig[04] , aConfig[05] , aConfig[06] , aConfig[07] , @cLog )

u_itconout( "Envio de e-mail: "+ cLog )

Return

/*
===============================================================================================================================
Programa----------: SchedDef
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 25/05/2017
Descrição---------: DefiniçStaticStatic Function SchedDef para o novo Schedule
Uso---------------: No novo Schedule existe uma forma para a definição dos Perguntes para o botão Parâmetros, além do cadastro 
					das funções no SXD. Ao definir em sua rotinStaticatic Function SchedDef(), no cadastro da rotina no Agenda-
					mento do Schedule será verificado se existe estStaticic Function e irá executá-la habilitando o botão Parâ-
					metros com as informações do retorno da SchedDef(), deixando de verificar assim as informações na SXD. O 
					retorno da SchedDef deverá ser um array.
					Válido para Function e User Function, lembrando que uma vez definido a SchedDef, ao chamar a rotina o ambi-
					ente já está inicializado.
					Uma vez definido a Static Function SchedDef(), a rotina deixa de ser uma execução como processo especial, 
					ou seja, não se deve cadastrá-la no Agendamento passando parâmetros de linha. Ex: Funcao("A","B") ou 
					U_Funcao("A","B").
Parametros--------: aReturn[1] - Tipo: "P" - para Processo, "R" -  para Relatórios
					aReturn[2] - Nome do Pergunte, caso nao use passar ParamDef
					aReturn[3] - Alias  (para Relatório)
					aReturn[4] - Array de ordem  (para Relatório)
					aReturn[5] - Título (para Relatório)
Retorno-----------: aParam
===============================================================================================================================
*/
Static Function SchedDef()

Local aParam  := {}
Local aOrd := {}

aParam := { "P",;
            "PARAMDEFF",;
            "",;
            aOrd,;
            }

Return aParam




Static Function ITENVFTP( cServer , nPorta , cUser , cPass , cPath , aArqEnv , lChgDir , cDirFtp , lViaJob, lSFTP )

Local aRetOk	:= {}
Local aLogErro	:= {}
Local lEnvia	:= .T.
Local nI
Local i         := 0
Local cError    := ""

Default cServer	:= ""
Default nPorta	:= 21
Default cUser	:= ""
Default cPass	:= ""
Default cPath	:= ""
Default aArqEnv	:= {}
Default lChgDir	:= .F.
Default cDirFtp	:= ""
Default lViaJob	:= .F.

Default lSFTP := .T.


If !lSFTP
	If Empty(cServer) .Or. Empty(cUser) .Or. Empty(cPass)
		
		If lViaJob
			U_ITCONOUT( "Falha ao identificar os dados para Login no Servidor de FTP." )
		Else
			U_ITMsg("Falha ao identificar os dados para Login no Servidor de FTP","Alerta",,1)
		EndIf
		
		Return( aRetOk )
		
	EndIf

	If Empty(cPath) .Or. Empty(aArqEnv)
		
		If lViaJob
			U_ITCONOUT( "Falha ao identificar o diretório de origem e os arquivos a enviar." )
		Else
			U_ITMsg("Falha ao identificar o diretório de origem e os arquivos a enviar.","Alerta",,1)
		EndIf
		
		Return( aRetOk )
		
	EndIf

	If !totvs.framework.environment.Type.get() == '1' //1-Produção, 2-Homologação,3-Desenvolvimento
		
		If lViaJob
			U_ITCONOUT( "Rotina foi executada em Ambiente de Testes: ["+ GetEnvServer() +"]" )
			U_ITCONOUT( "Não será processada a integração com o FTP!" )
		Else
		
			U_ITMsg("A Rotina foi executada em Ambiente de Testes:   "+ GetEnvServer() +  Chr(13) + Chr(10) + Chr(13) + Chr(10)	+;
					"Não será processada a integração com o FTP!"				 			, "Atenção!" ,,3)
					
		EndIf
		
		Return( aRetOk )

	EndIf

	If FTPConnect( cServer , nPorta , cUser , cPass )

		If lChgDir .And. !Empty( cDirFtp )
		
			If !FTPDirChange( cDirFtp )
			
				If lViaJob
					U_ITCONOUT( "Não foi possível acessar o diretório no FTP: "+ cDirFtp +CRLF+ "Informe a área de TI/ERP." )
				Else

					U_ITMsg("Não foi possível acessar o diretório no FTP: "+ cDirFtp +CRLF+ "Informe a área de TI/ERP." +  Chr(13) + Chr(10) + Chr(13) + Chr(10)	+;
							"Informe a área de TI/ERP"				 			, "Atenção!" ,,3)
		
				EndIf
				
				lEnvia := .F.
				
			EndIf
			
		EndIf
		
		If lEnvia
		
			FTPSetPasv( .T. )
			
			For nI := 1 to Len( aArqEnv )
			
				If FTPUpLoad( cPath + aArqEnv[nI] , aArqEnv[nI] )
				
					aAdd( aRetOk , aArqEnv[nI] )
					
				Else
				
					aAdd( aLogErro , 'Falha no UpLoad do arquivo: '+ aArqEnv[nI] )
					
				EndIf
				
			Next nI
		
		EndIf
		
		FTPDISCONNECT()
	Else
		Conout("Falha ao transferir : "+cError)

		If lViaJob
		U_ITCONOUT( "Não foi possivel onectar no FTP: FTPConnect( Sever: "+cServer+" , Porta: "+AllTrim(Str(nPorta))+" , User: "+cUser+" , Senha: "+cPass+" )" )
		Else
		U_ITMsg("Não foi possivel onectar no FTP: FTPConnect( Sever: "+cServer+" , Porta: "+AllTrim(Str(nPorta))+" , User "+cUser+" , Senha: "+cPass+" )","Atenção!",;
				"Entre em contato com a Area de TI",1)
		EndIf
		Return( aRetOk )
		
	EndIf
Else
	For nI := 1 to Len( aArqEnv )
		nStatus := SFTPUpld1(cPath+aArqEnv[nI],cDirFtp+aArqEnv[nI], cServer, cUser, cPass,@cError)
		If (nStatus != 0)
			aAdd( aLogErro , 'Falha no UpLoad do arquivo: '+ aArqEnv[nI] + " Erro: "+cError)
		Else
			aAdd( aRetOk , aArqEnv[nI] )
		EndIf
	Next

	If Len( aLogErro ) > 0 .And. !lViaJob
		ITListBox( "Falhas de UpLoad" , { "Não Enviados" } , aLogErro , .F. )
	ElseIf Len( aLogErro ) > 0 .And. lViaJob
		For i := 1 to Len(aLogErro)
			U_ITCONOUT( aLogErro[i])
		Next
	EndIf
EndIf

Return( aRetOk )
