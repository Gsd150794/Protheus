/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |08/10/2024| Chamado 48465. Retirada manipulação do SX1
Lucas Borges  |22/04/2025| Chamado 50505. Alterada a picture do CNPJ para contemplar campo alfanumérico
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "FWPrintSetup.ch"
#Include "ap5mail.ch"
#Include "RPTDEF.CH"

Static nLimite_Dias_Epi
Static nDiaAntAdm
Static __cArqTab
Static cQryVlCC

/*
===============================================================================================================================
Programa--------------: RMDT006
Autores---------------: Denis Hyroshi de Souza / Gabriel Sokacheski (Totvs)
Conversão para Italac-: Julio de Paula Paz
Data da Criacao-------: 22/09/2023
Descrição-------------: Perfil Profissiografico Previdenciario  -  P.P.P. Conversão de fonte padrão Totvs para fonte Italac.
                        Chamado: 44200. 
Parametros------------: Nenhum
Retorno---------------: Nenhum
===============================================================================================================================
*/
User Function RMDT006()

	Local aNGBEGINPRM := NGBEGINPRM() // Armazena variaveis p/ devolucao (NGRIGHTCLICK)
	Local nTamMvPar09 := 0

	// Inicializa constante.
	nLimite_Dias_Epi := 0
	nDiaAntAdm       := MDT700MES() // Mes Antes Admissao (De 1 ate 12 meses)
	__cArqTab        := cArqTab

	Private titulo   := "Perfil Profissiografico Previdenciario" // STR0006 // 
	Private cPerg
	Private cabec1, cabec2
	Private cEmpPPP 	:= cEmpAnt
	Private nSizeSI3 	:= IIf( ( TamSX3( "I3_CUSTO" )[1] ) < 1, 9, ( TamSX3( "I3_CUSTO" )[1] ) )
	Private nSizeSRJ 	:= IIf( ( TamSX3( "RJ_FUNCAO" )[1] ) < 1, 5, ( TamSX3( "RJ_FUNCAO" )[1] ) )
	Private nSizeTN5 	:= IIf( ( TamSX3( "TN5_CODTAR" )[1] ) < 1, 6, ( TamSX3( "TN5_CODTAR" )[1] ) )
	Private nSizeSQB 	:= IIf( ( TamSX3( "QB_DEPTO" )[1] ) < 1, 6, ( TamSX3( "QB_DEPTO" )[1] ) )
	Private nSizeTD 	:= 6
	Private lNGMDTPS 	:= .F.
	Private lSigaMdtps 	:= .F.
	Private lEpiCompl  	:= .F.  // Indica se a empresa utiliza EPI em carater complementar, mesmo quando o EPC For eficaz.
	Private lMV_PPPRISC := .F.
	Private nTamanRES 	:= 6
	Private lNG2M400  	:= .F.
	Private lMudEmpr  	:= .F.
	Private lMudFilial 	:= .T.
	Private lTrocaDes  	:= .F.
	Private nTamTable  	:= Len( cArqTab )
	Private cSvFilAnt  	:= cFilAnt	// Salva a Filial Corrente
	Private cSvEmpAnt  	:= cEmpAnt	// Salva a Empresa Corrente
	Private aSM0Area   	:= SM0->(GetArea())
	Private cModo      	:= " "
	Private lCposTNX 	:= .T.
	Private lParEnd    	:= .T.
	Private lConsEPC   	:= .T.
	Private lConsEPI   	:= 2 // Consiste Automaticamente
	Private nOpca      	:= 0
	Private cCliMdtPs
	Private aRespLaudo 	:= {}
	Private cStartPath := AllTrim( GetSrvProfString( "StartPath", "\" ) ) // Caminho do logoppp.bmp

	// Variaveis utilizadas para envio de email do relatorio
	Private aUsuario  := "", cTitulo, oDlgMail, cDiretorio:="", x:=1, cBody:=""
	Private cServer   := AllTrim( GetMV( "MV_RELSERV", , " " ) )
	Private cAccount  := AllTrim( GetMV( "MV_RELACNT", , " " ) )
	Private cPassword := AllTrim( GetMV( "MV_RELPSW", , " " ) )
	Private cUserAut  := AllTrim( GetMV( "MV_RELAUSR", , cAccount ) )//Usuário para Autenticação no Servidor de Email
	Private cPassAut  := AllTrim( GetMV( "MV_RELAPSW", , cPassword ) )//Senha para Autenticação no Servidor de Email
	Private lSmtpAuth := GetMv( "MV_RELAUTH", , .F. )
	Private cFrom     := cAccount
	Private cAnexos   := ""
	Private cTo       := Space( 200 )
	Private cCC       := Space( 200 )
	Private cSubject  := Space( 250 )
	Private lOk       := .T.
	Private lAutOk    := .F.
	Private aFiles    := {} // Array que irá conter todas as páginas geradas
	Private cSRisc    := " "
	Private lRespFim  := .T.
	Private cAlias    := "CTT"
	Private cDescr    := "CTT->CTT_DESC01"
	Private cF3CC     := "CTT"
	Private nSizeCC   := IIf( ( TamSX3( "CTT_CUSTO" )[1] ) < 1, 9, ( TamSX3( "CTT_CUSTO" )[1] ) )

	//Variaveis relacionadas a pergunta Representante Empresa?
	Private cNumSX1 	:= IIf( lSigaMDTPs, "13", "09" )
	Private cAliasRES 	:= "SRA" //Representante Funcionario
	Private cCNomeRES 	:= "SRA->RA_NOME"
	Private cCpfRes 	:= 'SRA->RA_CIC'
	Private cValRES		:= "ExCpoMDT('SRA',MV_PAR" + cNumSX1 + ")" //Valid da Consulta
	Private cRetF3		:= ""
	Private cMdtGenFun	:= "MDT700SXB()"
	Private cMdtGenRet	:= "MDT700RSXB()"
	Private cFilRES     :=  xFilial( "SRA" )

	If AMiIn( 35 )

		SX6PPPRES() //Verifica conteudo do parametro MV_MDTRESP

		// Recolhimento informacoes sobre parametros que impactam o PPP

		//Texto a ser impresso no PPP, caso o funcionario nao esteja exposto a nenhum risco.
		cSRisc := SuperGetMv( "MV_NG2SRIS", .F., "" )

		//Indica se o cliente e um prestador de servico de medicina S-SIM N-NAO
		lNGMDTPS := SuperGetMv( "MV_NGMDTPS", .F., "N" ) == "S"

		//Indica se o cliente e um prestador de servico de medicina. S-SIM N-NAO
		lSigaMdtPS := SuperGetMv( "MV_MDTPS", .F., "N" ) == "S"

		//Indica se a empresa utiliza EPI em carater complementar, mesmo quando o EPC For eficaz. S=Sim ou N=Nao
		lEpiCompl  := SuperGetMv( "MV_NG2KEPI", .F., "N" ) == "S"

		//Indica se a descricao das atividades do cargo tera todo o seu conteudo impresso no PPP ou apenas sera impresso os 400 primeiros caracteres. S=Sim;N=Nao
		lNG2M400 := SuperGetMv( "MV_NG2M400", .F., "N" ) == "S"

		//Indica se deve ser exibido na impressao do PPP do funcionario, o historico em todas as empresas em que trabalhou.  S=Sim;N=Nao
		lMudEmpr := SuperGetMv( "MV_NG2MEMP", .F., "N" ) == "S"

		//Indica se deve ser exibido na impressao do PPP do funcionario, o historico em todas as filiais em que trabalhou.  S=Sim;N=Nao
		lMudFilial := SuperGetMv( "MV_NG2MFIL", .F., "N" ) == "S"

		//Indica se deve ser trocado na impressao do PPP o conteudo da coluna do Cargo com a coluna da Funcao S=Sim;N=Nao
		lTrocaDes := SuperGetMv( "MV_NG2INVE", .F., "N" ) == "S"

		//Nos relatorios de Folha de Pagto deseja imprimir Endereco de Cobranca ou Endereco Fiscal? C = Cobranca ou F = Fiscal
		lParEnd := SuperGetMv( "MV_PAREND", .F., "C" ) == "C"

		//Indica se a empresa consiste o EPC S=Sim, N=Nao
		lConsEPC := SuperGetMv( "MV_NG2CEPC", .F., "N" ) == "S"

		//Indica se a empresa consiste o EPI S=Sim, N=Nao
		lConsEPI := SuperGetMv( "MV_NG2CEPI", .F., "N" ) == "N"

		//Indica quais datas serao consideradas na impressao das secoes do P.P.P. 1 - Responsaveis; 2 - Funcionarios
		lRespFim  := SuperGetMv( "MV_MDTDTFI", .F., "1" ) == "1"

		//Indica se o relatorio PPP listara somente funcionarios expostos a riscos ambientais. S=SIM / N=NAO
		lMV_PPPRISC := SuperGetMv( "MV_PPPRISC", .F., "N" ) == "S"

		//Quantidade de dias de tolerancia que o funcionario podera ficar sem receber o EPI, a partir do inicio de exposicao a um agente de risco.
		nLimite_Dias_Epi := SuperGetMv( "MV_PPPDTRI", .F., 30 )

		If lNGMDTPS
			lCposTNX := .F.
		EndIf

		//cPerg := PadR( "MDT700", 10 )
		cPerg := PadR( "RMDT006", 10 )

		/* Perguntas
		MDT700    ¦01      ¦De Matricula ?
		MDT700    ¦02      ¦Ate Matricula ?
		MDT700    ¦03      ¦De Centro de Custo ?
		MDT700    ¦04      ¦Ate Centro de Custo ?
		MDT700    ¦05      ¦De Funcao ?
		MDT700    ¦06      ¦Ate Funcao ?
		MDT700    ¦07      ¦Considerar Risco ?
		MDT700    ¦08      ¦Desc. das Atividad.?
		MDT700    ¦09      ¦Representante Empresa ?
		MDT700    ¦10      ¦Comprovante de Entrega ?
		MDT700    ¦11      ¦Termo Responsab. ?
		MDT700    ¦12      ¦Somente a partir JAN/2004 ?
		MDT700    ¦13      ¦Tipo de Impressao ?
		MDT700    ¦14      ¦Observacao ?
		MDT700    ¦15      ¦Exames Complementares ?
		MDT700    ¦16      ¦Imprime Resultados de Exames ?
		MDT700    ¦17      ¦Exames NR7 ?
		MDT700    ¦18      ¦Situacao Funcionario ?
		MDT700    ¦19      ¦De Data Demissao ?
		MDT700    ¦20      ¦Ate Data Demissao ?
		MDT700    ¦21      ¦Data Emissao PPP ?
		MDT700    ¦22      ¦Informe a Data ?
		MDT700    ¦23      ¦Listar Observ. Epis ?
		MDT700    ¦24      ¦Observacao EPI \ EPC. ?
		MDT700    ¦25      ¦Imagem PPP enviada p. e-mail ?
		MDT700    ¦26      ¦Ordenar nomes por ?
		MDT700    ¦27      ¦Imp. Resp. Monit. Biologica ?
		MDT700    ¦28      ¦Funcao
		MDT700    ¦29      ¦Considerar SESMT?
		MDT700    ¦30      ¦Desagrupa datas ?
		MDT700    ¦31      ¦Responsável Ambiental ?
		MDT700    ¦32      ¦Filtrar SESMT?
		MDT700    ¦33      ¦Imp. Título Atividade ?
		MDT700    ¦34      ¦Desc. da Lotação ?
		*/

		If lSigaMdtps
			cCliMdtPs := "Z"

			/* Perguntas
			MDT700PS    ¦01      ¦De Cliente ?
			MDT700PS    ¦02      ¦Loja
			MDT700PS    ¦03      ¦Até Cliente ?
			MDT700PS    ¦04      ¦Loja
			MDT700PS    ¦05      ¦De Matricula ?
			MDT700PS    ¦06      ¦Ate Matricula ?
			MDT700PS    ¦07      ¦De Centro de Custo ?
			MDT700PS    ¦08      ¦Ate Centro de Custo ?
			MDT700PS    ¦09      ¦De Funcao ?
			MDT700PS    ¦10      ¦Ate Funcao ?
			MDT700PS    ¦11      ¦Considerar Risco ?
			MDT700PS    ¦12      ¦Desc. das Atividad.?
			MDT700PS    ¦13      ¦Representante Empresa ?
			MDT700PS    ¦14      ¦Comprovante de Entrega ?
			MDT700PS    ¦15      ¦Termo Responsab. ?
			MDT700PS    ¦16      ¦Somente a partir JAN/2004 ?
			MDT700PS    ¦17      ¦Tipo de Impressao ?
			MDT700PS    ¦18      ¦Observacao ?
			MDT700PS    ¦19      ¦Exames Complementares ?
			MDT700PS    ¦20      ¦Imprime Resultados de Exames ?
			MDT700PS    ¦21      ¦Exames NR7 ?
			MDT700PS    ¦22      ¦Situacao Funcionario ?
			MDT700PS    ¦23      ¦De Data Demissao ?
			MDT700PS    ¦24      ¦Ate Data Demissao ?
			MDT700PS    ¦25      ¦Data Emissao PPP ?
			MDT700PS    ¦26      ¦Informe a Data ?
			MDT700PS    ¦27      ¦Listar Observ. Epis ?
			MDT700PS    ¦28      ¦Observacao EPI \ EPC. ?
			MDT700PS    ¦29      ¦Imagem PPP enviada p. e-mail ?
			MDT700PS    ¦30      ¦Ordenar nomes por ?
			MDT700PS    ¦31      ¦Imp. Resp. Monit. Biologica ?
			MDT700PS    ¦32      ¦Funcao
			MDT700PS    ¦33      ¦Considerar SESMT?
			MDT700PS    ¦34      ¦Desagrupa datas ?
			MDT700PS    ¦35      ¦Responsável Ambiental ?
			MDT700PS    ¦36      ¦Filtrar SESMT?
			MDT700PS    ¦37      ¦Imp. Título Atividade ?
			*/

			cPerg    :=  PadR( "MDT700PS", 10 )
		EndIf

		nProcessa := 1

		If Pergunte( cPerg, .T. )

			// Mapeamento das perguntas comuns às empresas "Prestadoras de Serviço" e às empresas "Não-Prestadoras de Serviço"
			// As variáveis MV_PAR01 até MV_PAR04 só devem ser usadas em "Prestadoras de Serviço"
			If lSigaMdtps
				xm_par01 := MV_PAR05
				xm_par02 := MV_PAR06
				xm_par03 := MV_PAR07
				xm_par04 := MV_PAR08
				xm_par05 := MV_PAR09
				xm_par06 := MV_PAR10
				xm_par07 := MV_PAR11
				xm_par08 := MV_PAR12
				xm_par09 := MV_PAR13
				xm_par10 := MV_PAR14
				xm_par11 := MV_PAR15
				xm_par12 := MV_PAR16
				xm_par13 := MV_PAR17
				xm_par14 := MV_PAR18
				xm_par15 := MV_PAR19
				xm_par16 := MV_PAR20
				xm_par17 := MV_PAR21
				xm_par18 := MV_PAR22
				xm_par19 := MV_PAR23
				xm_par20 := MV_PAR24
				xm_par21 := MV_PAR25
				xm_par22 := MV_PAR26
				xm_par23 := MV_PAR27
				xm_par24 := MV_PAR28
				xm_par25 := MV_PAR29
				xm_par26 := MV_PAR30
				xm_par27 := MV_PAR31
				xm_par28 := MV_PAR32
				xm_par29 := MV_PAR33
				xm_par30 := MV_PAR34
				xm_par31 := MV_PAR35
				xm_par32 := MV_PAR36
				xm_par33 := MV_PAR37
				xm_par34 := 1
				xm_par35 := 2
			Else
				xm_par01 := MV_PAR01
				xm_par02 := MV_PAR02
				xm_par03 := MV_PAR03
				xm_par04 := MV_PAR04
				xm_par05 := MV_PAR05
				xm_par06 := MV_PAR06
				xm_par07 := MV_PAR07
				xm_par08 := MV_PAR08
				xm_par09 := MV_PAR09
				xm_par10 := MV_PAR10
				xm_par11 := MV_PAR11
				xm_par12 := MV_PAR12
				xm_par13 := MV_PAR13
				xm_par14 := MV_PAR14
				xm_par15 := MV_PAR15
				xm_par16 := MV_PAR16
				xm_par17 := MV_PAR17
				xm_par18 := MV_PAR18
				xm_par19 := MV_PAR19
				xm_par20 := MV_PAR20
				xm_par21 := MV_PAR21
				xm_par22 := MV_PAR22
				xm_par23 := MV_PAR23
				xm_par24 := MV_PAR24
				xm_par25 := MV_PAR25
				xm_par26 := MV_PAR26
				xm_par27 := MV_PAR27
				xm_par28 := MV_PAR28
				xm_par29 := MV_PAR29
				xm_par30 := MV_PAR30
				xm_par31 := MV_PAR31
				xm_par32 := MV_PAR32
				xm_par33 := MV_PAR33
				xm_par34 := MV_PAR34
				xm_par35 := MV_PAR35
				xm_par36 := MV_PAR36
			EndIf

			// Define o tamanho correto da informação de acordo com o tipo de representante, funcionario ou usuario
			If AllTrim( GetMV( "MV_MDTRESP" ) ) == "1"
				nTamMvPar09 := TamSX3( "RA_MAT" )[1]
			Else
				nTamMvPar09 := TamSX3( "TMK_CODUSU" )[1]
			EndIf

			xm_par09 := SubStr( xm_par09, 1, nTamMvPar09 )

			If xm_par13 != 1 // Impressão via e-mail
				nProcessa := PPPCONFMAIL()
			EndIf

			If nProcessa == 1
				Processa( { |lEnd| R700Imp() } ) // MONTE TELA PARA ACOMPANHAMENTO DO PROCESSO.
			EndIf

		EndIf

		cArqTab := __cArqTab    // Devolve o valor original por Variavel EStatica

		cEmpAnt := cSvEmpAnt
		cFilAnt := cSvFilAnt

		DBSelectArea( "SM0" )
		DBSeek( cSvEmpAnt + cSvFilAnt )

		NGRETURNPRM( aNGBEGINPRM ) // Devolve variaveis armazenadas (NGRIGHTCLICK)

	EndIf

Return

/*
===============================================================================================================================
Programa--------------: RMDT006()
Autores---------------: Denis Hyroshi de Souza / Gabriel Sokacheski (Totvs)
Conversão para Italac-: Julio de Paula Paz
Data da Criacao-------: 22/09/2023
Descrição-------------: Chamada do relatório.
Parametros------------: lEnd    , Logico   - Controle de Encerramento do Relatório
                        wnRel   , Caracter - Arquivo de saida do relatorio          
                        titulo  , Caracter - Titulo do relatorio
                        tamanho , Caracter - Tamanho do relatorio
Retorno---------------: @Return Logico, .F. se a geração do relatorio foi cancelada
===============================================================================================================================
*/
Static Function R700Imp( lEnd, wnRel, titulo, tamanho )

	Local nRecnoSRA

	Local aDBF := {}

	Local aTamCpo  := TamSX3( "TN0_QTAGEN" )
	Local nSizeCod := IIf( ( TamSX3( "B1_COD" )[1] ) < 1, 15, ( TamSX3( "B1_COD" )[1] ) )
	Local nTamExa  := IIf( TamSX3( "TM4_EXAME" )[1] < 1, 6, TamSX3( "TM4_EXAME" )[1] )
	Local oTempTN0, oTempPPP, oTempTMK, oTempTNF
	Local lRet := .T.
	Local cBarraRem := "\"

	Private cPathEst := AllTrim( GetMv( "MV_DIREST" ) ) // PATH DO ARQUIVO A SER ARMAZENADO NA ESTACAO DE TRABALHOZ
	Private nSizeFil := IIf( lMudEmpr, NGMTAMFIL(), FwSizeFilial() )

	Private aVETINR   := {} // Usado pela funcao que cria arq. temporario
	Private aTM5Combo := PPPMDTCbox( "TM5_NATEXA", " ", 1 )
	Private aTMBCombo := PPPMDTCbox( "TMB_MATBIO", " ", 1 )
	Private aTMACombo := PPPMDTCbox( "TMA_GRISCO", " ", 1 )
	Private aTN0Combo := PPPMDTCbox( "TN0_EPC", " ", 1 )

	Private dDtDemiss  := CToD( "//" )
	Private dDtAdmiss  := CToD( "//" )
	Private dDatacorte := SuperGetMv( "MV_NG2PPPD", .F., CtoD( "" ) )

	Private lDemitido

	Private lin := 0
	Private nLin2 := 0
	Private nPaginaPPP := 0
	Private cFonte := "Verdana"
	Private oPrintPPP

	Private oFont07_ := TFont():New( cFonte, , 10, , .F., , , , .F., .F. )
	Private oFont07  := TFont():New( cFonte, , 12, , .F., , , , .F., .F. )
	Private oFont08  := TFont():New( cFonte, , 12, , .F., , , , .F., .F. )
	Private oFont09  := TFont():New( cFonte, , 11, , .F., , , , .F., .F. )
	Private oFont09n := TFont():New( cFonte, , 12, , .T., , , , .F., .F. ) // Títulos das seções 1 ~ 11 e 13.1, 13.2, 14.1 ...
	Private oFont08_ := TFont():New( cFonte, , 11, , .T., , , , .F., .F. )
	Private oFont10  := TFont():New( cFonte, , 11, , .F., , , , .F., .F. )
	Private oFont11  := TFont():New( cFonte, , 12, , .F., , , , .F., .F. )
	Private oFont13  := TFont():New( cFonte, , 16, , .T., , , , .F., .F. )

	// Criação das alias de TRB
	Private cTRBPPP := GetNextAlias()
	Private cTRBTN0 := GetNextAlias()
	Private cTRBTMK := GetNextAlias()
	Private cTRBTNF := GetNextAlias()
	Private cTRBSRA := GetNextAlias()

	If xm_par13 != 1 // Impressão via e-mail

		If GetRemoteType() == 2  //estacao com sistema operacional unix
			cBarraRem := "/"
		EndIf

		cPathEst += IIf( SubStr( cPathEst, Len( cPathEst ), 1 ) != cBarraRem, cBarraRem, "" )
		//Cria diretorio se nao existir
		MontaDir( cPathEst )
		//Força a geração de PDF para envio no e-mail
		oPrintPPP := FwMsPrinter():New( OemToAnsi("Perfil Profissiografico Previdenciario"), IMP_PDF, , , .T. ) // STR0006
		oPrintPPP:cPathPDF := cPathEst //Salva o arquivo na Estação de Trabalho
		oPrintPPP:nModalResult := 1 //Garante a "confirmação da tela"
		oPrintPPP:lViewPDF := .F. //Indica que não visualizará o PDF após a impressão
	Else
		oPrintPPP := FwMsPrinter():New("Perfil Profissiografico Previdenciario"  ) // OemToAnsi( STR0006 )
	EndIf

	// Se a geração do relatorio For cancelada
	If oPrintPPP:nModalResult != PD_OK
		lRet := .F.
	ElseIf oPrintPPP:GetOrientation() == 1 //Caso o tipo de impressão For igual a 'Retrato'
		Help( ' ', 1, "ATENÇÃO", , "O tipo de impressão 'Retrato' não está disponível para o PPP", 2, 0, , , , , , { "Favor selecionar o tipo de impressão 'Paisagem'"} ) //"O tipo de impressão 'Retrato' não está disponível para o PPP"##"Favor selecionar o tipo de impressão 'Paisagem'" STR0322 / STR0323

		lRet := .F.
	Else
		oPrintPPP:SetLandscape() // Paisagem
		oPrintPPP:SetMargin( 30, 30, 30, 30 )
		oPrintPPP:setPaperSize( 9 ) // A4

		If aTamCpo[1] < 12
			nQTAGENt := 12
		Else
			nQTAGENt := aTamCpo[1]
		EndIf

		nQTAGENd := aTamCpo[2]
		cQTAGtra := "@E "+Replicate( "9", nQTAGENt - nQTAGENd - 1 ) + "." + Replicate( "9", nQTAGENd )

		// TRBTN0
		aAdd( aDBF, { "NUMRIS", "C", 09, 0 } )
		aAdd( aDBF, { "CODAGE", "C", 06, 0 } )
		aAdd( aDBF, { "AGENTE", "C", 40, 0 } )
		aAdd( aDBF, { "MAT", "C", TamSX3( 'RA_MAT' )[ 1 ], 0 } )
		aAdd( aDBF, { "DT_DE", "D", 08, 0 } )
		aAdd( aDBF, { "DT_ATE", "D", 08, 0 } )
		aAdd( aDBF, { "SETOR", "C", nSizeSI3, 0 } )
		aAdd( aDBF, { "FUNCAO", "C", nSizeSRJ, 0 } )
		aAdd( aDBF, { "TAREFA", "C", 06, 0 } )
		aAdd( aDBF, { "DEPTO", "C", nSizeSQB, 0 } )
		aAdd( aDBF, { "INTENS", "N", nQTAGENt, nQTAGENd } )
		aAdd( aDBF, { "UNIDAD", "C", 100, 0 } )
		aAdd( aDBF, { "TECNIC", "C", 40, 0 } )
		aAdd( aDBF, { "PROTEC", "C", 02, 0 } )
		aAdd( aDBF, { "EPC", "C", 01, 0 } )
		aAdd( aDBF, { "GRISCO", "C", 01, 0 } )
		aAdd( aDBF, { "NUMCAP", "C", 12, 0 } )
		aAdd( aDBF, { "INDEXP", "C", 01, 0 } )
		aAdd( aDBF, { "ATIVO", "C", 01, 0 } )
		aAdd( aDBF, { "OBSINT", "C", 20, 0 } )
		aAdd( aDBF, { "CODEPI", "C", nSizeCod, 0 } )
		aAdd( aDBF, { "AVALIA", "C", 01, 0 } )
		aAdd( aDBF, { "NECEPI", "C", 01, 0 } )
		aAdd( aDBF, { "MEDCON", "C", 06, 0 } )
		aAdd( aDBF, { "TIPCTR", "C", 01, 0 } )
		aAdd( aDBF, { "PRZTNF", "C", 01, 0 } )
		aAdd( aDBF, { "PRZDUR", "C", 01, 0 } )
		aAdd( aDBF, { "HIGIEN", "C", 01, 0 } )

		oTempTN0 := FWTemporaryTable():New( cTRBTN0, aDBF )
		oTempTN0:AddIndex( "1", { "DT_DE", "DT_ATE", "NUMRIS" } )
		oTempTN0:AddIndex( "2", { "GRISCO", "AGENTE", "INTENS", "TECNIC", "EPC", "PROTEC", "CODEPI", "NUMCAP" } )
		oTempTN0:AddIndex( "3", { "GRISCO", "AGENTE", "INTENS", "TECNIC", "DT_DE", "DT_ATE" } )
		oTempTN0:Create()

		// TRBPPP
		aDBF := {}
		aAdd( aDBF, { "DTDE", "D", 8, 0 } )
		aAdd( aDBF, { "DTATE", "D", 8, 0 } )
		aAdd( aDBF, { "CNPJ", "C", 20, 0 } )
		aAdd( aDBF, { "SEQ", "C", 01, 0 } )
		aAdd( aDBF, { "TIPINS", "N", 01, 0 } )
		aAdd( aDBF, { "CUSTO", "C", nSizeSI3, 0 } )
		aAdd( aDBF, { "DEPTO", "C", nSizeSQB, 0 } )
		aAdd( aDBF, { "FILIAL", "C", nSizeFil, 0 } )
		aAdd( aDBF, { "MAT", "C", TamSX3( 'RA_MAT' )[ 1 ], 0 } )
		aAdd( aDBF, { "CARGO", "C", 5, 0 } )
		aAdd( aDBF, { "CODFUN", "C", nSizeSRJ, 0 } )
		aAdd( aDBF, { "DESFUN", "C", 30, 0 } )
		aAdd( aDBF, { "DESCAR", "C", 30, 0 } )
		aAdd( aDBF, { "GFIP", "C", 2, 0 } )
		aAdd( aDBF, { "EMP", "C", 2, 0 } )

		oTempPPP := FWTemporaryTable():New( cTRBPPP, aDBF )
		oTempPPP:AddIndex( '1', { 'DTDE', 'DTATE', 'CNPJ' } )
		oTempPPP:Create()

		// TRBTMK
		aDBF := {}
		aAdd( aDBF, { "DTINI", "D", 08, 0 } )
		aAdd( aDBF, { "DTFIM", "D", 08, 0 } )
		aAdd( aDBF, { "FILIAL", "C", nSizeFil, 0 } )
		aAdd( aDBF, { "CODIGO", "C", 12, 0 } )
		aAdd( aDBF, { "NOME", "C", TamSX3( "TMK_NOMUSU" )[1], 0 } )
		aAdd( aDBF, { "NIT", "C", 11, 0 } )
		aAdd( aDBF, { "INDFUN", "C", 01, 0 } )
		aAdd( aDBF, { "REGNUM", "C", 12, 0 } )
		aAdd( aDBF, { "MAT", "C", TamSX3( 'RA_MAT' )[ 1 ], 0 } )
		aAdd( aDBF, { "RESAMB", "C", 01, 0 } )
		aAdd( aDBF, { "MONBIO", "C", 01, 0 } )
		aAdd( aDBF, { 'CIC', 'C', TamSX3( 'TMK_CIC' )[1], 0 } )

		oTempTMK := FWTemporaryTable():New( cTRBTMK, aDBF )
		oTempTMK:AddIndex( "1", { "INDFUN", "DTINI", "DTFIM", "REGNUM", "NOME" } )
		oTempTMK:AddIndex( "2", { "REGNUM", "NOME", "DTINI" } )
		oTempTMK:AddIndex( "3", { "INDFUN", "REGNUM", "NOME", "DTINI" } )
		oTempTMK:AddIndex( "4", { "FILIAL", "MAT", "CODIGO", "DTINI", "DTFIM" } )
		oTempTMK:Create()

		// TRBTM5
		aDBF := {}
		aAdd( aDBF, { "EXAME", "C", nTamExa, 0 } )
		aAdd( aDBF, { "NOMEXA", "C", 50, 0 } )
		aAdd( aDBF, { "DTPRO", "D", 08, 0 } )
		aAdd( aDBF, { "DTRES", "D", 08, 0 } )
		aAdd( aDBF, { "NATEXA", "C", 01, 0 } )
		aAdd( aDBF, { "RESULT", "C", 01, 0 } )
		aAdd( aDBF, { "REFERE", "C", 01, 0 } )
		aAdd( aDBF, { "ESTAVE", "C", 01, 0 } )
		aAdd( aDBF, { "AGRAVA", "C", 01, 0 } )
		aAdd( aDBF, { "AUDIO", "C", 01, 0 } )

		// TRBTNF
		aDBF := {}
		aAdd( aDBF, { "DTINI", "D", 08, 0 } )
		aAdd( aDBF, { "NUMCAP", "C", 12, 0 } )
		aAdd( aDBF, { "PROTEC", "C", 02, 0 } )
		aAdd( aDBF, { "DTREAL", "D", 08, 0 } )
		aAdd( aDBF, { "SITUAC", "C", 01, 0 } )
		aAdd( aDBF, { "DTDEVO", "D", 08, 0 } )
		aAdd( aDBF, { "CODEPI", "C", nSizeCod, 0 } )
		aAdd( aDBF, { "PRZTNF", "C", 01, 0 } )
		aAdd( aDBF, { "PRZDUR", "C", 01, 0 } )
		aAdd( aDBF, { "HIGIEN", "C", 01, 0 } )

		oTempTNF := FWTemporaryTable():New( cTRBTNF, aDBF )
		oTempTNF:AddIndex( "1", { "DTINI", "NUMCAP", "PROTEC", "DTREAL" } )
		oTempTNF:AddIndex( "2", { "SITUAC", "NUMCAP", "DTINI", "PROTEC", "DTREAL" } )
		oTempTNF:Create()

		// Inicio do Relatorio
		If xm_par26 = 1
			cOrdem := "%SRA.RA_FILIAL, SRA.RA_NOME, SRA.RA_MAT%"
		Else
			cOrdem := "%SRA.RA_FILIAL, SRA.RA_CC, SRA.RA_NOME, SRA.RA_MAT%"
		EndIf

		// Condição para Prestador
		cSQLPrest := "%%"
		If lSigaMdtps
			cSQLPrest := "%SUBSTRING( RA_CC, 1, " + ValToSQL( nSizeTD ) + " ) BETWEEN " + ;
							ValToSQL( MV_PAR01+MV_PAR02 ) + " AND " + ValToSQL( MV_PAR03+MV_PAR04 ) + " AND%"
		EndIf

		BeginSql Alias cTRBSRA
			SELECT SRA.RA_FILIAL, SRA.RA_MAT, SRA.RA_NOME, SRA.RA_CC
				FROM %Table:SRA% SRA
				WHERE
					RA_FILIAL = %xFilial:SRA% AND
					RA_MAT BETWEEN %exp:xm_par01% AND %exp:xm_par02% AND
					RA_CC BETWEEN %exp:xm_par03% AND %exp:xm_par04% AND
					RA_CODFUNC BETWEEN %exp:xm_par05% AND %exp:xm_par06% AND
					%exp:cSQLPrest%
					SRA.%notDel%
				ORDER BY %exp:cOrdem%
		EndSql

		ProcRegua( RecCount() ) // MONTA A REGUA DE ACOMPANHAMENTO

		While ( cTRBSRA )->( !Eof() )

			DBSelectArea( "SRA" )
			DBSetOrder( 1 )
			DBSeek( ( cTRBSRA )->RA_FILIAL + ( cTRBSRA )->RA_MAT )

			IncProc()  // INCREMENTO DA REGUA DE ACOMPAHAMENTO.
			dDtAdmiss := CToD( "//" )
			dDtDemiss := IIf( Empty( SRA->RA_DEMISSA ), PPPDTDEMIS(), SRA->RA_DEMISSA ) //Busca data demissao do SRG
			lDemitido := !Empty( dDtDemiss )

			If xm_par12 == 1 .And. Year( SRA->RA_ADMISSA ) < 2004 // Somente a partir JAN/2004 ?

				dDtAdmiss := CtoD( '01/01/2004' )

				If !Empty( dDatacorte ) .And. dDtAdmiss < dDatacorte
					dDtAdmiss := dDatacorte
				EndIf

			Else

				If !Empty( dDatacorte ) .And. SRA->RA_ADMISSA < dDatacorte
					dDtAdmiss := dDatacorte
				Else
					dDtAdmiss := SRA->RA_ADMISSA
				EndIf

			EndIf

			If xm_par01 != xm_par02 //De Matricula ? // Ate Matricula ?

				If xm_par18 == 1 //Situacao Funcionario ?

					If !Empty( SRA->RA_SITFOLH ) .Or. lDemitido
						DBSelectArea( cTRBSRA )
						DBSkip()
						Loop
					EndIf

				ElseIf xm_par18 == 2 //Situacao Funcionario ?

					If lDemitido .Or. SRA->RA_SITFOLH == "D"
						DBSelectArea( cTRBSRA )
						DBSkip()
						Loop
					EndIf

				ElseIf xm_par18 == 3 //Situacao Funcionario ?

					If !lDemitido .Or. SRA->RA_SITFOLH != "D"
						DBSelectArea( cTRBSRA )
						DBSkip()
						Loop
					EndIf

					If dDtDemiss < xm_par19 .Or. dDtDemiss > xm_par20 // De Data Demissao ? // Ate Data Demissao ?
						DBSelectArea( cTRBSRA )
						DBSkip()
						Loop
					EndIf

				ElseIf xm_par18 == 4 // Situacao Funcionario ?

					If lDemitido .And. SRA->RA_SITFOLH == "D"

						If dDtDemiss < xm_par19 .Or. dDtDemiss > xm_par20 // De Data Demissao ? // Ate Data Demissao ?
							DBSelectArea( cTRBSRA )
							DBSkip()
							Loop
						EndIf

					EndIf

				EndIf

			EndIf

			DBSelectArea( cTRBTN0 )
			Zap
			DBSelectArea( cTRBPPP )
			Zap
			DBSelectArea( cTRBTMK )
			Zap
			DBSelectArea( cTRBTNF )
			Zap

			nPaginaPPP := 1
			DBSelectArea( "SRA" )
			nRecnoSRA := Recno()

			NGMDT700() // Chamada da funcao que imprime o PPP

			If xm_par10 == 2 // Comprovante de Entrega ?
				MDTERMO700()
			EndIf

			DBSelectArea( "SRA" )
			DBGoTo( nRecnoSRA )

			( cTRBSRA )->( DBSkip() )
		End

		// Deleta o arquivo temporario fisicamente
		oTempTN0:Delete()
		oTempPPP:Delete()
		oTempTMK:Delete()
		oTempTNF:Delete()

		If xm_par13 == 1 // Impressora
			oPrintPPP:Print()
		Else // Via email
			oPrintPPP:Print()
			PPPSENDMAIL()
		EndIf

		DBSelectArea( "TM0" )
		DBSetOrder( 1 )
		DBSelectArea( "TM5" )
		DBSetOrder( 1 )
		DBSelectArea( "TMY" )
		DBSetOrder( 1 )
	EndIf

Return

/*
===============================================================================================================================
Programa--------------: RMDT006()
Autores---------------: Denis Hyroshi de Souza / Gabriel Sokacheski (Totvs)
Conversão para Italac-: Julio de Paula Paz
Data da Criacao-------: 22/09/2023
Descrição-------------: Imprime o Perfil Profissiografico Previdenciario
Parametros------------: Nenhum
Retorno---------------: Nenhum
===============================================================================================================================
*/

Static Function NGMDT700()
	Local aHist := {}, nx, i, nInd
	Local cCNAE := "NA"
	Local cEPCefic := ""
	Local dDataCat
	Local dDataIni
	Local dDataFim
	Local lRespAmb  := .T.
	Local lProtec 	:= .F.  // Indica se todos os campos 15.7-Epi Eficaz = NA
	Local lEPCprot 	:= .F.  // Indica se todos os campos 15.6-Epc Eficaz = NA
	Local cEficEPC 	:= "NA"
	Local cEPIefic 	:= "NA"
	Local cCondInd	:= ""   // Verifica a funcao do Responsavel Ambiental, item 16.4
	Local cCNPJ
	Local cCargoDesc
	Local cCBO
	Local cIntens   := ""

	Local nLinhasCC 	:= 0
	Local nLinhasCargo 	:= 0
	Local nLinhasFuncao := 0

	// Variaveis para controle de quebra de lina na secao 15
	Local nLinTec := 0
	Local nLinFat := 0
	Local nLinInt := 0

	Local nLinSalva	 := 0
	Local nLinAtu	 := 0
	Local nMaxLin	 := 0 // Maior numero de linhas secao 13
	Local lExist1001 := ExistBlock( "RMDT0061" )

	Private aNUMCAPS 	:= {}
	Private aFuncao 	:= {}
	Private aFichasUsa 	:= {}
	Private aCargoSv  	:= {}
	Private aCargo  	:= {}
	Private aMatriculas := {}
	Private aRiscos		:= {}
	Private aCat  		:= {}
	Private lEpcNec		:= .F.
	Private lEpiNec 	:= .F.
	Private aAREASRA 	:= SRA->(GetArea())
	Private cCliFun 	:= Space( 6 )

	lEpiEntregue:= .F.
	lPrazoTNF 	:= .F. // Indica se algum EPI foi entregue fora do prazo de validade
	lPrazoDur 	:= .F. // Indica se algum EPI foi utilizado mais do que o seu prazo de durabilidade
	lHigiene  	:= .F. // Indica se algum EPI não teve higienização

	aHist := aClone( fVerBusHis() ) // Histórico do funcionário

	If !lEpiEntregue      // Se nenhum EPI foi entregue
		lPrazoTNF := .T.  // Nao foi observado o prazo de validade pois nenhum EPI foi entregue
		lPrazoDur := .T.  // Nao foi observada a periodicidade de troca pois  nenhum EPI foi entregue
		lHigiene  := .T.  // Nao foi observada a higienizacao pois nenhum EPI foi entregue
	EndIf

	FWRestArea( aAREASRA )

	If lMV_PPPRISC
		DBSelectArea( cTRBTN0 )
		DBSetOrder( 1 )
		DBGoTop()

		If (cTRBTN0)->(RecCount()) == 0
			Return .F.
		EndIf

	EndIf

	DBSelectArea( "TM0" )
	DBSetOrder( 3 )
	DBSeek( xFilial( "SRA" ) + SRA->RA_MAT )

	DBSelectArea( "SR6" )
	DBSetOrder( 1 )
	DBSeek( xFilial( "SR6" ) + SRA->RA_TNOTRAB )

	NG700SESMT() // Busca os Usuarios do SESMT

	lin := 100
	oPrintPPP:StartPage()

	oPrintPPP:SayAlign( lin, 50, "ANEXO XVII", oFont13, 2940, lin + 30, CLR_BLACK, 2, 1 ) //"ANEXO I" + STR0146
	oPrintPPP:SayAlign( lin + 80, 50, "NSTRUÇÃO NORMATIVA PRES/INSS Nº 128, DE 28 DE MARÇO DE 2022", oFont13, 2940, lin + 110, CLR_BLACK, 2, 1 ) //"INSTRUÇÃO NORMATIVA Nº 85 INSS/PRES, DE 18 DE FEVEREIRO DE 2016" // STR0147

	lin += 100
	// Imprime logotipo da previdencia social
	cLogo := cStartPath + "LOGOPPP.BMP" // Empresa

	If File( cLogo )
		oPrintPPP:SayBitMap( lin + 40, 950, cLogo, 270, 135 )
	ElseIf File( "\SIGAADV\LOGOPPP.BMP" ) // Imprime logotipo da previdencia social
		oPrintPPP:SayBitMap( lin + 40, 950, "\SIGAADV\LOGOPPP.BMP", 270, 135 )
	EndIf

	lin += 80
	oPrintPPP:SayAlign( lin + 90, 50, "PERFIL PROFISSIOGRÁFICO PREVIDENCIÁRIO" , oFont13, 2940, lin + 110, CLR_BLACK, 2, 1 ) // "PERFIL PROFISSIOGRÁFICO PREVIDENCIÁRIO - PPP" STR0149
	oPrintPPP:Box( lin + 200, 50, lin + 580, 2940 )

	// PRIMEIRA PARTE
	SomaLinha( 260 )
	oPrintPPP:Say( lin, 70, "DADOS ADMINISTRATIVOS", oFont13 ) // "DADOS ADMINISTRATIVOS" // STR0150

	oPrintPPP:Line( lin + 20, 50, lin + 20, 2940 )
	oPrintPPP:Line( lin + 20, 1000, lin + 120, 1000 )

	// "1-CNPJ do Domicílio Tributário/CEI/CAEPF/CNO"
	oPrintPPP:Say( lin + 50, 60, Memoline( "1-CNPJ do Domicílio Tributário/CEI/CAEPF/CNO" , 41, 1 ), oFont09n ) // STR0151
	oPrintPPP:Say( lin + 80, 60, Memoline( "1-CNPJ do Domicílio Tributário/CEI/CAEPF/CNO" , 41, 2 ), oFont09n ) // STR0151

	oPrintPPP:Line( lin + 20, 2200, lin + 120, 2200 )

	// Ponto de entrada RMDT0063 para CNPJ
	If ExistBlock( "RMDT0063" )
		cCNPJ:= ExecBlock( "RMDT0063", .F., .F. )
	EndIf

	// Caso não teha ponto de entrada
	If ValType( cCNPJ ) <> "C" .Or. Empty( cCNPJ )

		If lNGMDTPS .Or. lSigaMdtps
			cCNPJ:= SA1->A1_CGC
		Else
			cCNPJ:= SM0->M0_CGC
		EndIf

	EndIf

	If !Empty( cCNPJ )

		If lNGMDTPS .Or. lSigaMdtps
			oPrintPPP:Say( lin + 110, 60, Transform( cCNPJ, "@R! NN.NNN.NNN/NNNN-99" ), oFont10 )
		Else

			If SM0->M0_TPINSC != 2
				oPrintPPP:Say( lin + 110, 60, Transform( cCNPJ, "@R 99.999.99999/99" ), oFont10 )
			Else
				oPrintPPP:Say( lin + 110, 60, Transform( cCNPJ, "@R! NN.NNN.NNN/NNNN-99" ), oFont10 )
			EndIf

		EndIf

	EndIf

	oPrintPPP:Say( lin + 50, 1010, "2-Nome Empresarial", oFont09n ) // STR0152 = "2-Nome Empresarial"	
	oPrintPPP:Say( lin + 110, 1010, SubStr( SM0->M0_NOMECOM, 1, 40 ), oFont10 )
	oPrintPPP:Say( lin + 50, 2210, "3-CNAE" , oFont09n ) // "3-CNAE" // STR0153
	
	If !Empty( SM0->M0_CNAE )
		nSizeCNAE := Len( AllTrim( SM0->M0_CNAE ) )

		If nSizeCNAE > 5
			cCNAE := Transform( SM0->M0_CNAE, "@R 99.99-9/99" )
		Else
			cCNAE := Transform( SM0->M0_CNAE, "@R 99.99-9" )
		EndIf

	EndIf
	oPrintPPP:Say( lin + 110, 2210, cCNAE, oFont10 )

	oPrintPPP:Line( lin + 120, 50, lin + 120, 2940 )
	oPrintPPP:Say( lin + 150, 60, "4-Nome do Trabalhador", oFont09n ) // "4-Nome do Trabalhador" STR0154

	If !Empty( SRA->RA_NOMECMP )
		oPrintPPP:Say( lin + 210, 60, SRA->RA_NOMECMP, oFont10 )
	Else
		oPrintPPP:Say( lin + 210, 60, SRA->RA_NOME, oFont10 )
	EndIf

	oPrintPPP:Line( lin + 120, 1525, lin + 220, 1525 )
	oPrintPPP:Say( lin + 150, 1535, "5-BR/PDH", oFont09n ) // "5-BR/PDH" STR0155
	cBRPDH := "NA"

	If SRA->RA_BRPDH == "1"
		cBRPDH := "BR"
	ElseIf SRA->RA_BRPDH == "2"
		cBRPDH := "PDH"
	EndIf

	oPrintPPP:Say( lin + 210, 1535, cBRPDH, oFont10 )

	oPrintPPP:Line( lin + 120, 1925, lin + 220, 1925 )
	oPrintPPP:Say( lin + 150, 1935, "6-CPF", oFont09n ) // "6-CPF" STR0156

	If !Empty( SRA->RA_CIC )
		oPrintPPP:Say( lin + 210, 1935, Transform( SRA->RA_CIC, '@R 999.999.999-99' ), oFont10 )
	EndIf

	oPrintPPP:Line( lin + 220, 50, lin + 220, 2940 )
	oPrintPPP:Line( lin + 220, 500, lin + 320, 500 )
	oPrintPPP:Line( lin + 220, 750, lin + 320, 750 )
	oPrintPPP:Line( lin + 220, 1370, lin + 320, 1370 )
	oPrintPPP:Line( lin + 220, 1760, lin + 320, 1760 )
	oPrintPPP:Say( lin + 250, 60, "7-Data do Nascimento", oFont09n ) //"7-Data do Nascimento" STR0157
	oPrintPPP:Say( lin + 310, 60, NGPPPDATE( SRA->RA_NASC ), oFont10 )
	oPrintPPP:Say( lin + 250, 510, "8-Sexo(F/M)" , oFont09n ) //"8-Sexo(F/M)" // STR0158
	oPrintPPP:Say( lin + 310, 510, Upper( SRA->RA_SEXO ), oFont10 )

	// "9 - Matrícula do Trabalhador no eSocial"
	oPrintPPP:Say( lin + 250, 760, Memoline( "9 - Matrícula do Trabalhador no eSocial" , 29, 1 ), oFont09n ) // STR0159
	oPrintPPP:Say( lin + 280, 760, Memoline( "9 - Matrícula do Trabalhador no eSocial" , 29, 2 ), oFont09n ) // STR0159
	oPrintPPP:Say( lin + 310, 760, AllTrim( SRA->RA_CODUNIC ), oFont10 )

	oPrintPPP:Say( lin + 250, 1380, "10-Data de Admissão", oFont09n ) //"10-Data de Admissão" // STR0160
	oPrintPPP:Say( lin + 310, 1380, NGPPPDATE( SRA->RA_ADMISSA ), oFont10 )
	oPrintPPP:Say( lin + 250, 1770, "11-Regime Revezamento", oFont09n ) //"11-Regime Revezamento" STR0161

	If !Empty( SubStr( SR6->R6_REVEZAM, 1, 20 ) )
		oPrintPPP:Say( lin + 310, 1770, SubStr( SR6->R6_REVEZAM, 1, 20 ), oFont09 )
	Else
		oPrintPPP:Say( lin + 310, 1770, "NA", oFont10 )
	EndIf

	lin += 320
	oPrintPPP:Line( lin, 50, lin + 60, 50 )
	oPrintPPP:Say( lin + 45, 70, "12", oFont11 )
	oPrintPPP:Line( lin, 150, lin + 60, 150 )
	oPrintPPP:Say( lin + 45, 160, "CAT REGISTRADA:", oFont11 ) //"CAT REGISTRADA:" // STR0162
	oPrintPPP:Line( lin, 2940, lin + 60, 2940 )
	oPrintPPP:Line( lin + 60, 50, lin + 60, 2940 )
	SomaLinha()
	oPrintPPP:Line( lin, 50, lin + 50, 50 )
	oPrintPPP:Say( lin + 40, 60, "12.1-Data do Registro" , oFont09n ) //"12.1-Data do Registro" STR0163
	oPrintPPP:Line( lin, 475, lin + 50, 475 )
	oPrintPPP:Say( lin + 40, 485, "12.2-Número da CAT", oFont09n ) //"12.2-Número da CAT" // STR0164
	oPrintPPP:Line( lin, 1400, lin + 50, 1400 )
	oPrintPPP:Say( lin + 40, 1410, "12.1-Data do Registro" , oFont09n ) //"12.1-Data do Registro" STR0163
	oPrintPPP:Line( lin, 1825, lin + 50, 1825 )
	oPrintPPP:Say( lin + 40, 1835, "12.2-Número da CAT" , oFont09n ) //"12.2-Número da CAT" STR0164
	oPrintPPP:Line( lin, 2940, lin + 50, 2940 )
	oPrintPPP:Line( lin + 50, 50, lin + 50, 2940 )

	lPosi := .F.
	lLen  := .F.

	If Len( aCat ) > 0

		For nX := 1 To Len( aCat )

			If Len( aCat ) == nx
				lLen := .T.
			EndIf

			nResto := Mod( nx, 2 )

			If nResto = 1 .And. lLen
				SomaLinha( 50 )
				oPrintPPP:Line( lin, 50, lin + 50, 50 )

				// Data do Registro
				If !Empty( dDataCat := NGPPPDATE( aCat[nx][1] ) )
					oPrintPPP:Say( lin + 35, 60, dDataCat, oFont10 )
				EndIf

				oPrintPPP:Line( lin, 475, lin + 50, 475 )

				// Numero da Cat
				If !Empty( aCat[ nx, 2 ] )

					If !Empty( aCat[ nx, 3 ] )
						oPrintPPP:Say( lin + 35, 485, aCat[ nx, 2 ], oFont10 ) // Formato eSocial
					Else
						//oPrintPPP:Say( lin + 35, 485, Transform( aCat[ nx, 2 ], '@R 9999999999-9/99' ), oFont10 ) // Formato comum
						oPrintPPP:Say( lin + 35, 485, aCat[ nx, 2 ], oFont10 ) // Formato comum
					EndIf

					oPrintPPP:Say( lin + 35, 1410, 'NA', oFont10 )
					oPrintPPP:Say( lin + 35, 1835, 'NA', oFont10 )

				EndIf

				oPrintPPP:Line( lin, 1400, lin + 50, 1400 )
				oPrintPPP:Line( lin, 1825, lin + 50, 1825 )
				oPrintPPP:Line( lin, 2940, lin + 50, 2940 )
				oPrintPPP:Line( lin + 50, 50, lin + 50, 2940 )

			ElseIf nResto = 0

				SomaLinha( 50 )
				oPrintPPP:Line( lin, 50, lin + 50, 50 )

				// Data do Registro
				If !Empty( dDataCat := NGPPPDATE( aCat[ nx - 1, 1 ] ) )
					oPrintPPP:Say( lin + 35, 60, dDataCat, oFont10 )
				EndIf

				oPrintPPP:Line( lin, 475, lin + 50, 475 )

				If !Empty( aCat[ nx - 1, 2 ] )

					If !Empty( aCat[ nx - 1, 3 ] )
						oPrintPPP:Say( lin + 35, 485, aCat[ nx - 1, 2 ], oFont10 ) // Formato eSocial
					Else
						//oPrintPPP:Say( lin + 35, 485, Transform( aCat[ nx - 1, 2 ], '@R 9999999999-9/99' ), oFont10 ) // Formato comum
						oPrintPPP:Say( lin + 35, 485, aCat[ nx - 1, 2 ] , oFont10 ) // Formato comum
					EndIf

				EndIf

				oPrintPPP:Line( lin, 1400, lin + 50, 1400 )

				// Data do Registro
				If !Empty( dDataCat := NGPPPDATE( aCat[nx][1] ) )
					oPrintPPP:Say( lin + 35, 1410, dDataCat, oFont10 )
				EndIf

				oPrintPPP:Line( lin, 1825, lin + 50, 1825 )

				// Numero da Cat
				If !Empty( aCat[ nx, 2 ] )

					If !Empty( aCat[ nx, 3 ] )
						oPrintPPP:Say( lin + 35, 1835, aCat[ nx, 2 ], oFont10 ) // Formato eSocial
					Else
						//oPrintPPP:Say( lin + 35, 1835, Transform( aCat[ nx, 2 ], '@R 9999999999-9/99' ), oFont10 ) // Formato comum
						oPrintPPP:Say( lin + 35, 1835, aCat[ nx, 2 ], oFont10 ) // Formato comum
					EndIf

				EndIf

				oPrintPPP:Line( lin, 2940, lin + 50, 2940 )
				oPrintPPP:Line( lin + 50, 50, lin + 50, 2940 )
			EndIf

		Next nX

	Else
		SomaLinha( 50 )
		oPrintPPP:Say( lin + 35, 60, "NA", oFont10 )
		oPrintPPP:Say( lin + 35, 485, "NA", oFont10 )
		oPrintPPP:Say( lin + 35, 1410, "NA", oFont10 )
		oPrintPPP:Say( lin + 35, 1835, "NA", oFont10 )
		oPrintPPP:Line( lin, 50, lin + 50, 50 )
		oPrintPPP:Line( lin, 475, lin + 50, 475 )
		oPrintPPP:Line( lin, 1400, lin + 50, 1400 )
		oPrintPPP:Line( lin, 1825, lin + 50, 1825 )
		oPrintPPP:Line( lin, 2940, lin + 50, 2940 )
		oPrintPPP:Line( lin + 50, 50, lin + 50, 2940 )
	EndIf

	SomaLinha( 50 )
	oPrintPPP:Line( lin, 50, lin + 60, 50 )
	oPrintPPP:Say( lin + 45, 70, "13", oFont11 )
	oPrintPPP:Line( lin, 150, lin + 60, 150 )
	oPrintPPP:Say( lin + 45, 160,"LOTAÇÃO E ATRIBUIÇÃO:" , oFont11 )   //"LOTAÇÃO E ATRIBUIÇÃO:" STR0165
	oPrintPPP:Line( lin, 2940, lin + 60, 2940 )
	oPrintPPP:Line( lin + 60, 50, lin + 60, 2940 )

	SomaLinha()

	oPrintPPP:Line( lin, 50, lin + 90, 50 )
	oPrintPPP:Say( lin + 30, 60, "13.1-Período", oFont08_ )   //"13.1-Período" STR0166

	// "13.2-CNPJ/CEI/CAEPF/CNO"
	oPrintPPP:Line( lin, 510, lin + 90, 510 )
	oPrintPPP:Say( lin + 30, 520, Memoline( "13.2-CNPJ/CEI/CAEPF/CNO" , 14, 1 ), oFont08_ ) // STR0167
	oPrintPPP:Say( lin + 60, 520, Memoline( "13.2-CNPJ/CEI/CAEPF/CNO" , 14, 2 ), oFont08_ ) // STR0167

	oPrintPPP:Line( lin, 870, lin + 90, 870 )
	oPrintPPP:Say( lin + 30, 880, "13.3-Setor" , oFont08_ )  //"13.3-Setor" STR0168

	oPrintPPP:Line( lin, 1200, lin + 90, 1200 )
	oPrintPPP:Say( lin + 30, 1210, "13.4-Cargo", oFont08_ ) //"13.4-Cargo" STR0169

	oPrintPPP:Line( lin, 1460, lin + 90, 1460 )
	oPrintPPP:Say( lin + 30, 1470, "13.5-Função", oFont08_ ) //"13.5-Função" STR0170

	oPrintPPP:Line( lin, 1710, lin + 90, 1710 )
	oPrintPPP:Say( lin + 30, 1720, "13.6-CBO", oFont08_ ) //"13.6-CBO" STR0171

	// "13.7-Código GFIP/eSocial"
	oPrintPPP:Line( lin, 1890, lin + 90, 1890 )
	oPrintPPP:Say( lin + 30, 1900, Memoline( "13.7-Código GFIP/eSocial" , 14, 1 ), oFont08_ ) // STR0172
	oPrintPPP:Say( lin + 60, 1900, Memoline( "13.7-Código GFIP/eSocial" , 14, 2 ), oFont08_ ) //STR0172

	oPrintPPP:Line( lin, 2940, lin + 90, 2940 )

	SomaLinha( 90 )

	If Len( aHist ) > 0

		For i := 1 To Len( aHist )

			// Conta o numero de linhas dos conteudos a serem impressos
			nLinhasCC 		:=  MLCount( aHist[i][5], 15 ) //Centro de Custo
			nLinhasCargo 	:=  MLCount( aHist[i][IIf( lTrocaDes, 7, 6 )], 15 )  //Cargo
			nLinhasFuncao 	:=  MLCount( aHist[i][IIf( !lTrocaDes, 7, 6 )], 15 ) //Funcao

			// Busca do maior numero de linhas
			nMaxLin := nLinhasCC
			nMaxLin := IIf( nLinhasCargo > nMaxLin, nLinhasCargo, nMaxLin )
			nMaxLin := IIf( nLinhasFuncao > nMaxLin, nLinhasFuncao, nMaxLin )
			nMaxLin := IIf( nMaxLin <= 0, 1, nMaxLin ) //Garante que irá passar ao menos por uma linha

			dDataIni := aHist[i][3]

			If !fVerAte()
				dDataFim := IIf( i == Len( aHist ) .And. !lDemitido, CToD( '//' ), aHist[ i, 4 ] )
			Else
				dDataFim := aHist[ i, 4 ]
			EndIf

			aDatasPPP := fDesagData( dDataIni, dDataFim )

			For nX := 1 To Len( aDatasPPP )

				// Se uma linha da seção 13 ficar dividida entre paginas, quebra a pagina
				If lin + nMaxLin > 1900
					SomaLinha( , , .T. )
				EndIf

				oPrintPPP:Line( lin, 50, lin + 50, 50 )
				nLinSalva := lin // Salva linha atual.

				// Salva os conteudos a serem impressos
				cCentroCusto:= aHist[i][5] //Centro de Custo
				cCargoDesc 	:= aHist[i][IIf( lTrocaDes, 7, 6 )] //Cargo
				cFuncaoDesc := aHist[i][IIf( !lTrocaDes, 7, 6 )] //Funcao

				For nLinAtu := 1 To nMaxLin

					If nLinAtu == 1
						oPrintPPP:Say( lin + 30, 60, aDatasPPP[nX], oFont10 ) // Período

						If aHist[i][11] == 2

							If Empty( aHist[i][10] )
								oPrintPPP:Say( lin + 30, 520, "NA", oFont10 ) // CNPJ
							Else
								oPrintPPP:Say( lin + 30, 520, Transform( aHist[i][10], "@R! NN.NNN.NNN/NNNN-99" ), oFont09 ) // CNPJ
							EndIf

						Else

							If Empty( aHist[i][10] )
								oPrintPPP:Say( lin + 30, 520, "NA", oFont10 ) // CEI
							Else
								oPrintPPP:Say( lin + 30, 520, Transform( aHist[i][10], "@R 99.999.99999/99" ), oFont10 ) // CEI
							EndIf

						EndIf

						// Imprime CBO
						cCBO := StrZero( Val( aHist[i][8] ), 6 )

						If Empty( cCBO )
							oPrintPPP:Say( nLinSalva + 30, 1720, "NA", oFont10 ) // CBO
						Else
							oPrintPPP:Say( nLinSalva + 30, 1720, cCBO, oFont10 )
						EndIf

						If lExist1001
							 ExecBlock('RMDT0061',.F.,.F., {@aHist[i]})
						EndIf

						// GFIP
						If !Empty( aHist[i][9] )
							oPrintPPP:Say( nLinSalva + 30, 1900, aHist[i][9], oFont09 )
						EndIf

					EndIf

					// Setor
					If !Empty( MemoLine( cCentroCusto, 16, nLinAtu ) )
						oPrintPPP:Say( lin + 30, 880, Memoline( cCentroCusto, 16, nLinAtu ), oFont10 )
					EndIf

					// Cargo
					If Empty( cCargoDesc ) .And. nLinAtu == 1
						oPrintPPP:Say( lin + 30, 1210, "NA", oFont10 )
					ElseIf !Empty( MemoLine( cCargoDesc, 13, nLinAtu ) )
						oPrintPPP:Say( lin + 30, 1210, Memoline( cCargoDesc, 13, nLinAtu ), oFont10 )
					EndIf

					// Funcao
					If Empty( cFuncaoDesc ) .And. nLinAtu == 1
						oPrintPPP:Say( lin + 30, 1470, "NA", oFont10 )
					ElseIf !Empty( MemoLine( cFuncaoDesc, 13, nLinAtu ) )
					   	oPrintPPP:Say( lin + 30, 1470, Memoline( cFuncaoDesc, 13, nLinAtu ), oFont10 )
					EndIf

					SomaLinha( 40 )

				Next nLinAtu

				// Imprime as linhas verticais
				oPrintPPP:Line( nLinSalva, 50, lin, 50 )
				oPrintPPP:Line( nLinSalva, 510, lin, 510 )
				oPrintPPP:Line( nLinSalva, 870, lin, 870 )
				oPrintPPP:Line( nLinSalva, 1200, lin, 1200 )
				oPrintPPP:Line( nLinSalva, 1460, lin, 1460 )
				oPrintPPP:Line( nLinSalva, 1710, lin, 1710 )
				oPrintPPP:Line( nLinSalva, 1890, lin, 1890 )
				oPrintPPP:Line( nLinSalva, 2940, lin, 2940 )

				oPrintPPP:Line( lin, 50, lin, 2940 )

			Next nx

		Next i

	Else
		oPrintPPP:Line( lin, 50, lin + 50, 50 )
		oPrintPPP:Say( lin + 30, 60, "__/__/____" + " a " + "__/__/____", oFont10 ) // STR0173
		oPrintPPP:Say( lin + 30, 560, "NA", oFont10 )  // CNPJ
		oPrintPPP:Say( lin + 30, 855, "NA", oFont10 )  // Setor
		oPrintPPP:Say( lin + 30, 1205, "NA", oFont10 ) // Cargo
		oPrintPPP:Say( lin + 30, 1555, "NA", oFont10 ) // Funcao
		oPrintPPP:Say( lin + 30, 1910, "NA", oFont10 ) // CBO
		oPrintPPP:Say( lin + 30, 2090, "", oFont10 )   // GFIP
		oPrintPPP:Line( lin, 550, lin + 50, 550 )
		oPrintPPP:Line( lin, 850, lin + 50, 850 )
		oPrintPPP:Line( lin, 1200, lin + 50, 1200 )
		oPrintPPP:Line( lin, 1550, lin + 50, 1550 )
		oPrintPPP:Line( lin, 1900, lin + 50, 1900 )
		oPrintPPP:Line( lin, 2080, lin + 50, 2080 )
		oPrintPPP:Line( lin, 2210, lin + 50, 2210 )
		oPrintPPP:Line( lin + 50, 50, lin + 50, 2210 )
		SomaLinha( 50 )
	EndIf

	oPrintPPP:Line( lin, 50, lin + 60, 50 )
	oPrintPPP:Say( lin + 45, 70, "14", oFont11 )
	oPrintPPP:Line( lin, 150, lin + 60, 150 )
	oPrintPPP:Say( lin + 45, 160, "PROFISSIOGRAFIA:" , oFont11 ) //"PROFISSIOGRAFIA:" STR0174
	oPrintPPP:Line( lin, 2940, lin + 60, 2940 )
	oPrintPPP:Line( lin + 60, 50, lin + 60, 2940 )
	SomaLinha()
	oPrintPPP:Line( lin, 50, lin + 50, 50 )
	oPrintPPP:Say( lin + 40, 60, "14.1-Período" , oFont09n ) //"14.1-Período" STR0175
	oPrintPPP:Line( lin, 550, lin + 50, 550 )
	oPrintPPP:Say( lin + 40, 560, "14.2-Descrição das Atividades" , oFont09n ) //"14.2-Descrição das Atividades" STR0176
	oPrintPPP:Line( lin, 2940, lin + 50, 2940 )
	oPrintPPP:Line( lin + 50, 50, lin + 50, 2940 )
	SomaLinha( 50 )

	If !ATIV700R()//IMPRIME DESCRICAO DAS ATIVIDADES
		oPrintPPP:Line( lin, 50, lin + 50, 50 )
		oPrintPPP:Line( lin, 550, lin + 50, 550 )
		oPrintPPP:Line( lin, 2940, lin + 50, 2940 )
		oPrintPPP:Line( lin + 50, 50, lin + 50, 2940 )
		oPrintPPP:Say( lin + 45, 60, "NA", oFont10 )
		oPrintPPP:Say( lin + 45, 560, "NA", oFont10 )
		SomaLinha( 50 )
	EndIf

	// SEGUNDA PARTE

	SomaLinha( 30 )

	// Quebra de pagina devido ao tamanho do cabecalho da secao 15
	If lin >= 1900
		SomaLinha( , .F., .T. )
	EndIf

	oPrintPPP:Line( lin, 50, lin, 2940 )
	oPrintPPP:Line( lin, 50, lin + 80, 50 )
	oPrintPPP:Line( lin, 2940, lin + 80, 2940 )
	oPrintPPP:Line( lin + 80, 50, lin + 80, 2940 )
	oPrintPPP:Say( lin + 60, 70, "REGISTROS AMBIENTAIS", oFont13 ) //"REGISTROS AMBIENTAIS" STR0177
	SomaLinha( 80 )
	oPrintPPP:Line( lin, 50, lin + 60, 50 )
	oPrintPPP:Say( lin + 45, 70, "15", oFont11 )
	oPrintPPP:Line( lin, 150, lin + 60, 150 )
	oPrintPPP:Say( lin + 45, 160, "EXPOSIÇÃO A FATORES DE RISCOS:", oFont11 ) //"EXPOSIÇÃO A FATORES DE RISCOS:" STR0178
	oPrintPPP:Line( lin, 2940, lin + 60, 2940 )
	oPrintPPP:Line( lin + 60, 50, lin + 60, 2940 )
	//IMPRIMIR RISCO
	SomaLinha()
	oPrintPPP:Line( lin, 50, lin + 115, 50 )
	oPrintPPP:Say( lin + 35, 60, "15.1-Período" , oFont09n ) //"15.1-Período" // STR0179
	oPrintPPP:Line( lin, 300, lin + 115, 300 )
	oPrintPPP:Say( lin + 35, 310, "15.2-", oFont09n ) //"15.2-" // STR0180
	oPrintPPP:Say( lin + 70, 310, "Tipo" , oFont09n ) //"Tipo"
	oPrintPPP:Line( lin, 410, lin + 115, 410 )
	oPrintPPP:Say( lin + 35, 420, "15.3-", oFont09n ) //"15.3-"
	oPrintPPP:Say( lin + 70, 420, "Fator de" , oFont09n ) //"Fator de" STR0181
	oPrintPPP:Say( lin + 105, 420, "Risco", oFont09n ) //"Risco" STR0182
	oPrintPPP:Line( lin, 600, lin + 115, 600 )
	oPrintPPP:Say( lin + 35, 610, "15.4-Intens.", oFont09n ) //"15.4-Intens." STR0183
	oPrintPPP:Say( lin + 70, 610, "/Conc.", oFont09n ) //"/Conc." STR0184
	oPrintPPP:Line( lin, 850, lin + 115, 850 )
	oPrintPPP:Say( lin + 35, 860, "15.5-", oFont09n ) //"15.5-"
	oPrintPPP:Say( lin + 70, 860, "Técnica", oFont09n ) //"Técnica" STR0185
	oPrintPPP:Say( lin + 105, 860, "Utilizada", oFont09n ) //"Utilizada" // STR0040
	oPrintPPP:Line( lin, 1030, lin + 115, 1030 )
	oPrintPPP:Say( lin + 35, 1040, "15.6-", oFont09n ) //"15.6-"
	oPrintPPP:Say( lin + 70, 1040, "EPC", oFont09n ) //"EPC" STR0186
	oPrintPPP:Say( lin + 105, 1040, "Eficaz", oFont09n ) //"Eficaz" STR0187
	oPrintPPP:Line( lin, 1160, lin + 115, 1160 )
	oPrintPPP:Say( lin + 35, 1170, "15.7-", oFont09n ) //"15.7-"
	oPrintPPP:Say( lin + 70, 1170, "EPI" , oFont09n ) //"EPI" STR0188
	oPrintPPP:Say( lin + 105, 1170, "Eficaz", oFont09n ) //"Eficaz" STR0187
	oPrintPPP:Line( lin, 1290, lin + 115, 1290 )
	oPrintPPP:Say( lin + 35, 1300, "15.8-", oFont09n ) //"15.8-"
	oPrintPPP:Say( lin + 70, 1300, "C.A" , oFont09n ) //"C.A." STR0189
	oPrintPPP:Say( lin + 105, 1300, "EPI", oFont09n ) //"EPI" STR0188
	oPrintPPP:Line( lin, 1490, lin + 115, 1490 )
	oPrintPPP:Say( lin + 35, 1500, "15.9-Atendimento aos requisitos das NR-06 e NR-01 do MTP", oFont09n ) //STR0101 "15.9-Atendimento aos requisitos das NR-06 e NR-01 do MTP" 
	oPrintPPP:Say( lin + 70, 1500, "pelos EPI's informados" + Space( 1 ) + '(*)', oFont09n ) //"pelos EPI's informados" STR0333
	oPrintPPP:Line( lin, 2940, lin + 115, 2940 )
	oPrintPPP:Line( lin + 115, 50, lin + 115, 2940 )
	
	SomaLinha( 115 )

	oPrintPPP:Line( lin, 50, lin + 115, 50 )
	oPrintPPP:Line( lin, 300, lin + 115, 300 )
	oPrintPPP:Line( lin, 410, lin + 115, 410 )
	oPrintPPP:Line( lin, 600, lin + 115, 600 )
	oPrintPPP:Line( lin, 850, lin + 115, 850 )
	oPrintPPP:Line( lin, 1030, lin + 115, 1030 )
	oPrintPPP:Line( lin, 1160, lin + 115, 1160 )
	oPrintPPP:Line( lin, 1290, lin + 115, 1290 )
	oPrintPPP:Line( lin, 1490, lin + 115, 1490 )

	oPrintPPP:Say( lin + 35, 1500, "Medida de ", oFont09n ) // "Medida de" STR0324
	oPrintPPP:Say( lin + 70, 1500, "Proteção" , oFont09n ) // "proteção" / STR0334
	
	oPrintPPP:Line( lin, 1710, lin + 115, 1710 )
	oPrintPPP:Say( lin + 35, 1720, "Condição de" , oFont09n )  // "Condição de" STR0325
	oPrintPPP:Say( lin + 70, 1720, "Funcionamento" , oFont09n )  // "Funcionamento" // STR0335
	oPrintPPP:Say( lin + 105, 1720,"do EPI" , oFont09n ) // "do EPI" STR0336

	oPrintPPP:Line( lin, 2020, lin + 115, 2020 )
	oPrintPPP:Say( lin + 35, 2030, "Prazo de", oFont09n ) // "Prazo de" STR0326
	oPrintPPP:Say( lin + 70, 2030, "Validade", oFont09n ) // "Validade" STR0337
	oPrintPPP:Say( lin + 105, 2030, "do EPI" , oFont09n ) // "do EPI" STR0336

	oPrintPPP:Line( lin, 2370, lin + 115, 2370 )
	oPrintPPP:Say( lin + 35, 2380, "Periodicidade" , oFont09n ) // "Periodicidade" STR0327
	oPrintPPP:Say( lin + 70, 2380, "da Troca" , oFont09n ) // "da Troca" / STR0338
	oPrintPPP:Say( lin + 105, 2380, "do EPI" , oFont09n ) // "EPI" STR0336

	oPrintPPP:Line( lin, 2690, lin + 115, 2690 )
	oPrintPPP:Say( lin + 35, 2700, "Higienização" , oFont09n ) // "Higienização" STR0328
	oPrintPPP:Say( lin + 70, 2700, "do EPI" , oFont09n ) // "do EPI" STR0336

	oPrintPPP:Line( lin, 2940, lin + 115, 2940 )
	oPrintPPP:Line( lin + 115, 50, lin + 115, 2940 )

	SomaLinha( 115 )

	RECLASS_RISCOS() // Reclassifica os riscos
	lNot := .T.
	lEPIefic := .F.  // Indica se há pelo menos um EPI necessario que nao foi entregue.
	DBSelectArea( cTRBTN0 )
	DBSetOrder( 1 )
	DBGoTop()

	While !Eof()

		If (cTRBTN0)->ATIVO != "S"
			DBSelectArea( cTRBTN0 )
			DBSkip()
			Loop
		EndIf

		dDataIni := (cTRBTN0)->DT_DE
		dDataFim := IIf( (cTRBTN0)->DT_ATE == dDataBase .And. !lDemitido, CToD( "//" ), (cTRBTN0)->DT_ATE )

		aDatasPPP := fDesagData( dDataIni, dDataFim )

		For nX := 1 To Len( aDatasPPP )

			cGrau_Risco := " "

			If Len( aTMACombo ) == 0
				Do Case
				Case (cTRBTN0)->GRISCO == "1" ; cGrau_Risco := "F"
				Case (cTRBTN0)->GRISCO == "2" ; cGrau_Risco := "Q"
				Case (cTRBTN0)->GRISCO == "3" ; cGrau_Risco := "B"
				Case (cTRBTN0)->GRISCO == "4" ; cGrau_Risco := "E"
				Case (cTRBTN0)->GRISCO == "5" ; cGrau_Risco := "A"
				Case (cTRBTN0)->GRISCO == "6" ; cGrau_Risco := "M"
				End Case
			ElseIf ( nIND := aScan( aTMAcombo, { |x| Upper( SubStr( x, 1, 1 ) ) == SubStr( (cTRBTN0)->GRISCO, 1, 1 ) } ) ) > 0
				cGrau_Risco := Upper( SubStr( aTMAcombo[nIND], 3, 1 ) )
			EndIf

			// EPC Eficaz
			If lConsEPC

				// Indica se esta condicao e satisfeita: 1-MV_NG2CEPC=S  2-TN0_EPC=2(Nao) 3-Medida de controle do risco é do tipo Proteção Coletiva
				// ou Medida de controle de riscos administrativas
				lEPCefic := .F.

				If ( nIND := aScan( aTN0combo, { |x| Upper( SubStr( x, 1, 1 ) ) == SubStr( (cTRBTN0)->EPC, 1, 1 ) } ) ) > 0
					cEPCefic := SubStr( aTN0combo[nIND], 1, 1 )

					If cEPCefic == "2"
						cEPCefic := "N"
						lEPCprot := .T.

						If lEpiCompl

							// Tipo da Medida de Controle = "2" (Protecao Coletiva) ou Medida de Controle = "4" ( Administrativas )
							If ( cTRBTN0 )->TIPCTR != " "
								lEPCefic := .T.
							EndIf

						EndIf

					ElseIf cEPCefic == "1"
						cEPCefic := "S"
						lEPCprot := .T.

						//Indica que empresa utiliza EPI em carater complementar mesmo quando o EPC For eficaz
						If lEpiCompl .And. !lEPCefic

							// Tipo da Medida de Controle = "2" (Protecao Coletiva) ou Medida de Controle = "4" ( Administrativas )
							If ( cTRBTN0 )->TIPCTR != " "
								lEPCefic := .T.
							EndIf

						EndIf

					Else
						cEPCefic := "NA"
					EndIf

				Else
					cEPCefic := "NA"
				EndIf

			EndIf

			If (cTRBTN0)->PROTEC == "N "

				If (cTRBTN0)->NECEPI != "2"
					lEPIefic := .T.
				EndIf

				lProtec := .T.

			ElseIf (cTRBTN0)->PROTEC == "S "
				lProtec := .T.
			EndIf

			// Trata a Intensidade para a impressao (Intensidade + Unidade de medida)
			If Empty( (cTRBTN0)->INTENS ) .And. (cTRBTN0)->AVALIA <> "1" .And. !Empty( (cTRBTN0)->OBSINT )
				cIntens := AllTrim( cValToChar( (cTRBTN0)->OBSINT ) )
			ElseIf !Empty( (cTRBTN0)->INTENS )
				cIntens := AllTrim( SubStr( Transform( (cTRBTN0)->INTENS, cQTAGtra ), 1, IIf( "," $ cQTAGtra, nQTAGENt + 1, nQTAGENt ) ) +;
								    " " + AllTrim( (cTRBTN0)->UNIDAD ) )
			Else
				cIntens := "NA"
			EndIf

			nLinTec := MlCount( AllTrim( (cTRBTN0)->TECNIC ), 11 )
			nLinFat := MlCount( AllTrim( (cTRBTN0)->AGENTE ), 11 )
			nLinInt := MlCount( cIntens, 13 )

			// Busca do maior numero de linhas
			nMaxLin := nLinFat
			nMaxLin := IIf( nLinInt > nMaxLin, nLinInt, nMaxLin )
			nMaxLin := IIf( nLinTec > nMaxLin, nLinTec, nMaxLin )
			nMaxLin := IIf( nMaxLin <= 0, 1, nMaxLin ) // Garante que irá passar ao menos por uma linha

			// Se uma linha da seção 15 ficar dividida entre paginas, quebra a pagina
			If lin + nMaxLin > 1900
				SomaLinha( , , .T. )
			EndIf

			If lConsEPC

				If lEPCprot
					cEficEPC := IIf( lEPCefic, "S", "N" )
				EndIf

			EndIf

			If !lConsEPI

				If lProtec .And. lEpiNec
					cEPIefic  := IIf( lEPIefic, "N", "S" )
				EndIf

			EndIf

			If !lConsEPC .And. lEpiCompl
				If cEPIefic == "S" .And. ( cTRBTN0 )->PRZTNF == "S" .And. ( cTRBTN0 )->PRZDUR == "S"
					lEPCefic := .T.
					cEficEPC := "S"
					cEPCefic := "N"
				EndIf
			EndIf

			For nLinAtu := 1 To nMaxLin

				If nLinAtu == 1
					oPrintPPP:Say( lin + 35, 60, SubStr( aDatasPPP[nX], 1, 12 ), oFont09 ) // Periodo de Exposicao
					oPrintPPP:Say( lin + 70, 60, SubStr( aDatasPPP[nX], 14, 24 ), oFont09 )    // Periodo de Exposicao
					
					oPrintPPP:Say( lin + 35, 310, cGrau_Risco, oFont11 ) // Tipo de Risco

					oPrintPPP:Say( lin + 35, 1040, cEPCefic, oFont09 ) // EPC Eficaz

					// EPI Eficaz
					If !lConsEPI
						oPrintPPP:Say( lin + 35, 1170, IIf( Empty( (cTRBTN0)->PROTEC ), "NA", (cTRBTN0)->PROTEC ), oFont10 )
					EndIf

					// N. Cert. Aprov. EPI
					oPrintPPP:Say( lin + 35, 1300, IIf( Empty( (cTRBTN0)->NUMCAP ), "NA", (cTRBTN0)->NUMCAP ), oFont10 )
	
					oPrintPPP:Say( lin + 35, 1500, cEficEPC, oFont09 )
					oPrintPPP:Say( lin + 35, 1720, cEPIefic, oFont09 )
					oPrintPPP:Say( lin + 35, 2030, IIf( Empty( (cTRBTN0)->PRZTNF ), "NA", (cTRBTN0)->PRZTNF ), oFont09 )
					oPrintPPP:Say( lin + 35, 2380, IIf( Empty( (cTRBTN0)->PRZDUR ), "NA", (cTRBTN0)->PRZDUR ), oFont09 )
					oPrintPPP:Say( lin + 35, 2700, IIf( Empty( (cTRBTN0)->HIGIEN ), "NA", (cTRBTN0)->HIGIEN ), oFont09 )

				EndIf
				
				// Impressao da linhas verticais
				oPrintPPP:Line( lin, 50, lin + 100, 50 )
				oPrintPPP:Line( lin, 300, lin + 100, 300 )
				oPrintPPP:Line( lin, 410, lin + 100, 410 )
				oPrintPPP:Line( lin, 600, lin + 100, 600 )
				oPrintPPP:Line( lin, 850, lin + 100, 850 )
				oPrintPPP:Line( lin, 1030, lin + 100, 1030 )
				oPrintPPP:Line( lin, 1160, lin + 100, 1160 )
				oPrintPPP:Line( lin, 1290, lin + 100, 1290 )
				oPrintPPP:Line( lin, 1490, lin + 100, 1490 )
				oPrintPPP:Line( lin, 1710, lin + 100, 1710 )
				oPrintPPP:Line( lin, 2020, lin + 100, 2020 )
				oPrintPPP:Line( lin, 2370, lin + 100, 2370 )
				oPrintPPP:Line( lin, 2690, lin + 100, 2690 )
				oPrintPPP:Line( lin, 2940, lin + 100, 2940 )

				If !Empty( MemoLine( (cTRBTN0)->AGENTE, 11, nLinAtu ) )
					oPrintPPP:Say( lin + 35, 420, MemoLine( (cTRBTN0)->AGENTE, 11, nLinAtu ), oFont07 ) // Fator de Risco
				EndIf

				// Intensidade / Concentracao
				If !Empty( MemoLine( cIntens, 13, nLinAtu ) )
					oPrintPPP:Say( lin + 35, 610, MemoLine( cIntens, 13, nLinAtu ), oFont07 )
				EndIf

				If !Empty( MemoLine( (cTRBTN0)->TECNIC, 11, nLinAtu ) )
					oPrintPPP:Say( lin + 35, 860, MemoLine( (cTRBTN0)->TECNIC, 11, nLinAtu ), oFont07 ) // Tecnica Utilizada
				ElseIf nLinAtu == 1
					oPrintPPP:Say( lin + 35, 860, "NA", oFont07 )
				EndIf

				SomaLinha( 100, .T. ) // Registro sera impresso em uma linha
			Next nLinAtu

			oPrintPPP:Line( lin, 50, lin, 2940 )

			lNot := .F.

		Next nX

		DBSelectArea( cTRBTN0 )
		DBSkip()

	End

	If lNot
		oPrintPPP:Line( lin, 50, lin + 115, 50 )
		oPrintPPP:Say( lin + 35, 60, "__/__/____" + " a " , oFont09 ) // STR0173
		oPrintPPP:Say( lin + 70, 60, "__/__/____", oFont09 )
		oPrintPPP:Line( lin, 300, lin + 115, 300 )
		oPrintPPP:Line( lin, 410, lin + 115, 410 )
		oPrintPPP:Line( lin, 600, lin + 115, 600 )
		oPrintPPP:Line( lin, 850, lin + 115, 850 )
		oPrintPPP:Line( lin, 1030, lin + 115, 1036 )
		oPrintPPP:Line( lin, 1160, lin + 115, 1160 )
		oPrintPPP:Line( lin, 1290, lin + 115, 1290 )
		oPrintPPP:Line( lin, 1490, lin + 115, 1490 )
		oPrintPPP:Say( lin + 35, 1500, "NA", oFont10 )
		oPrintPPP:Line( lin, 1710, lin + 115, 1710 )
		oPrintPPP:Say( lin + 35, 1720, "NA", oFont10 )
		oPrintPPP:Line( lin, 2020, lin + 115, 2020 )
		oPrintPPP:Say( lin + 35, 2030, "NA", oFont10 )
		oPrintPPP:Line( lin, 2370, lin + 115, 2370 )
		oPrintPPP:Say( lin + 35, 2380, "NA", oFont10 )
		oPrintPPP:Line( lin, 2690, lin + 115, 2690 )
		oPrintPPP:Say( lin + 35, 2710, "NA", oFont10 )
		oPrintPPP:Line( lin, 2940, lin + 115, 2940 )
		oPrintPPP:Line( lin + 115, 50, lin + 115, 2940 )

		If Empty( cSRisc )
			oPrintPPP:Say( lin + 35, 310, "NA", oFont10 )  // 15.2 - Tipo
			oPrintPPP:Say( lin + 35, 420, "NA", oFont10 )  // 15.3 - Fator de Risco
			oPrintPPP:Say( lin + 35, 610, "NA", oFont10 ) // 15.4 - Intensidade
			oPrintPPP:Say( lin + 35, 860, "NA", oFont10 ) // 15.5 - Tecnica Utilizada
			oPrintPPP:Say( lin + 35, 1040, "NA", oFont10 ) // 15.6 - EPC Eficaz
			oPrintPPP:Say( lin + 35, 1170, "NA", oFont10 ) // 15.7 - EPI Eficaz
			oPrintPPP:Say( lin + 35, 1300, "NA", oFont10 ) // 15.8 - C.A. EPI
		Else
			oPrintPPP:Say( lin + 35, 310, SubStr( cSRisc, 1, 4 ), oFont11 )
			oPrintPPP:Say( lin + 35, 420, SubStr( cSRisc, 1, 11 ), oFont11 )
			oPrintPPP:Say( lin + 35, 610, SubStr( cSRisc, 1, 15 ), oFont11 )
			oPrintPPP:Say( lin + 35, 860, SubStr( cSRisc, 1, 10 ), oFont11 )
			oPrintPPP:Say( lin + 35, 1040, SubStr( cSRisc, 1, 7 ), oFont11 )
			oPrintPPP:Say( lin + 35, 1170, SubStr( cSRisc, 1, 7 ), oFont11 )
			oPrintPPP:Say( lin + 35, 1300, SubStr( cSRisc, 1, 12 ), oFont11 )
		EndIf

		SomaLinha( 115 )

	EndIf

	oPrintPPP:Line( lin, 50, lin + 50, 50 ) // Linha da esquerda
	oPrintPPP:Say( lin + 40, 60, '*' + "Legenda do item"  + Space( 1 ) + '15.9:', oFont09 ) // "Legenda do item" STR0329
	oPrintPPP:Line( lin, 2940, lin + 50, 2940 ) // Linha da direita

	oPrintPPP:Line( lin + 50, 50, lin + 50, 2940 ) // Linha de baixo

	SomaLinha( 50, .T. )

	oPrintPPP:Line( lin, 50, lin + 50, 50 ) // Linha da esquerda
	oPrintPPP:Say( lin + 40, 90, MemoLine( "Medida de"  + Space( 1 ) + "Proteção" + ':' + Space( 1 ) + "Foi tentada a implementação de medidas de proteção coletiva, de caráter administrativo ou de organização do trabalho, optando-se pelo Equipamento de Proteção Individual - EPI por inviabilidade técnica, insuficiência ou interinidade, ou ainda em caráter complementar ou emergencial?", 150, 1 ), oFont09 ) // STR0324 // STR0330 / STR0334
	oPrintPPP:Line( lin, 2940, lin + 50, 2940 ) // Linha da direita

	SomaLinha( 50, .T. )

	oPrintPPP:Line( lin, 50, lin + 50, 50 ) // Linha da esquerda
	oPrintPPP:Say( lin + 40, 90, MemoLine( "Medida de" + ':' + Space( 1 ) + "Foi tentada a implementação de medidas de proteção coletiva, de caráter administrativo ou de organização do trabalho, optando-se pelo Equipamento de Proteção Individual - EPI por inviabilidade técnica, insuficiência ou interinidade, ou ainda em caráter complementar ou emergencial?" , 150, 2 ), oFont09 ) // STR0324 / STR0330
	oPrintPPP:Line( lin, 2940, lin + 50, 2940 ) // Linha da direita

	SomaLinha( 50, .T. )

	oPrintPPP:Line( lin, 50, lin + 50, 50 ) // Linha da esquerda
	oPrintPPP:Say( lin + 40, 90, MemoLine( "Medida de" + ':' + Space( 1 ) + "Foi tentada a implementação de medidas de proteção coletiva, de caráter administrativo ou de organização do trabalho, optando-se pelo Equipamento de Proteção Individual - EPI por inviabilidade técnica, insuficiência ou interinidade, ou ainda em caráter complementar ou emergencial?" , 150, 3 ), oFont09 ) // STR0324 / STR0330
	oPrintPPP:Line( lin, 2940, lin + 50, 2940 ) // Linha da direita

	SomaLinha( 50, .T. )

	oPrintPPP:Line( lin, 50, lin + 50, 50 ) // Linha da esquerda
	oPrintPPP:Say( lin + 40, 90, MemoLine( "Medida de" + ':' + Space( 1 ) + "Foi tentada a implementação de medidas de proteção coletiva, de caráter administrativo ou de organização do trabalho, optando-se pelo Equipamento de Proteção Individual - EPI por inviabilidade técnica, insuficiência ou interinidade, ou ainda em caráter complementar ou emergencial?" , 150, 4 ), oFont09 ) // STR0324 / STR0330
	oPrintPPP:Line( lin, 2940, lin + 50, 2940 ) // Linha da direita

	oPrintPPP:Line( lin + 50, 50, lin + 50, 2940 ) // Linha de baixo

	SomaLinha( 50, .T. )

	oPrintPPP:Line( lin, 50, lin + 50, 50 ) // Linha da esquerda
	oPrintPPP:Say( lin + 40, 90, MemoLine( "Condição de" + Space( 1 ) + "Funcionamento" + Space( 1 ) + "do EPI" +':' + Space( 1 ) + "Foram observadas as condições de funcionamento e do uso ininterrupto do EPI ao longo do tempo, conforme especificação técnica do fabricante, ajustada às condições?" , 150, 1 ), oFont09 ) // STR0325 / STR0331 / STR0335 / STR0336
	oPrintPPP:Line( lin, 2940, lin + 50, 2940 ) // Linha da direita

	SomaLinha( 50, .T. )

	oPrintPPP:Line( lin, 50, lin + 50, 50 ) // Linha da esquerda
	oPrintPPP:Say( lin + 40, 90, MemoLine( "Condição de"  + ':' + Space( 1 ) + "Foram observadas as condições de funcionamento e do uso ininterrupto do EPI ao longo do tempo, conforme especificação técnica do fabricante, ajustada às condições?" , 150, 2 ), oFont09 ) // STR0325 / STR0331
	oPrintPPP:Line( lin, 2940, lin + 50, 2940 ) // Linha da direita

	SomaLinha( 50, .T. )

	oPrintPPP:Line( lin, 50, lin + 50, 50 ) // Linha da esquerda
	oPrintPPP:Say( lin + 40, 90, MemoLine( "Condição de"  + ':' + Space( 1 ) + "Foram observadas as condições de funcionamento e do uso ininterrupto do EPI ao longo do tempo, conforme especificação técnica do fabricante, ajustada às condições?" , 150, 3 ), oFont09 ) // STR0325 / STR0331
	oPrintPPP:Line( lin, 2940, lin + 50, 2940 ) // Linha da direita

	oPrintPPP:Line( lin + 50, 50, lin + 50, 2940 ) // Linha de baixo

	SomaLinha( 50, .T. )

	oPrintPPP:Line( lin, 50, lin + 50, 50 ) // Linha da esquerda
	oPrintPPP:Say( lin + 40, 90, MemoLine( "Prazo de" + Space( 1 ) + "Validade" + Space( 1 ) + "do EPI" + ':' + Space( 1 ) + "Foi observado o prazo de validade, conforme Certificado de Aprovação - CA do MTP?", 150, 1 ), oFont09 ) // STR0107 / STR0326 / STR0336 / STR0337
	oPrintPPP:Line( lin, 2940, lin + 50, 2940 ) // Linha da direita

	SomaLinha( 50, .T. )

	oPrintPPP:Line( lin, 50, lin + 50, 50 ) // Linha da esquerda
	oPrintPPP:Say( lin + 40, 90, MemoLine( "Prazo de"  + ':' + Space( 1 ) + "Foi observado o prazo de validade, conforme Certificado de Aprovação - CA do MTP?", 150, 2 ), oFont09 ) // STR0326 / STR0107
	oPrintPPP:Line( lin, 2940, lin + 50, 2940 ) // Linha da direita

	oPrintPPP:Line( lin + 50, 50, lin + 50, 2940 ) // Linha de baixo

	SomaLinha( 50, .T. )

	oPrintPPP:Line( lin, 50, lin + 50, 50 ) // Linha da esquerda
	oPrintPPP:Say( lin + 40, 90, MemoLine( "Periodicidade" + Space( 1 ) + "da Troca" + Space( 1 ) + "do EPI" +':' + Space( 1 ) + "Foi observada a periodicidade de troca definida pelos programas ambientais, comprovada mediante recibo assinado pelo usuário em época própria?" , 150, 1 ), oFont09 ) // STR0327 / STR0332 / STR0336 / STR0338 
	oPrintPPP:Line( lin, 2940, lin + 50, 2940 ) // Linha da direita

	SomaLinha( 50, .T. )

	oPrintPPP:Line( lin, 50, lin + 50, 50 ) // Linha da esquerda
	oPrintPPP:Say( lin + 40, 90, MemoLine( "Periodicidade" + ':' + Space( 1 ) + "Foi observada a periodicidade de troca definida pelos programas ambientais, comprovada mediante recibo assinado pelo usuário em época própria?" , 150, 2 ), oFont09 ) // STR0327 / STR0332
	oPrintPPP:Line( lin, 2940, lin + 50, 2940 ) // Linha da direita

	oPrintPPP:Line( lin + 50, 50, lin + 50, 2940 ) // Linha de baixo

	SomaLinha( 50, .T. )

	oPrintPPP:Line( lin, 50, lin + 50, 50 ) // Linha da esquerda
	oPrintPPP:Say( lin + 40, 90, "Higienização" + Space( 1 ) + "do EPI" + ':' + Space( 1 ) + "Foi observada a higienização? ", oFont09 ) // STR0110 / STR0328 / STR0336
	oPrintPPP:Line( lin, 2940, lin + 50, 2940 ) // Linha da direita

	oPrintPPP:Line( lin + 50, 50, lin + 50, 2940 ) // Linha de baixo

	SomaLinha( 50, .T. )

	// FIM RISCO
	oPrintPPP:Line( lin, 50, lin + 60, 50 )
	oPrintPPP:Say( lin + 45, 70, "16", oFont11 )
	oPrintPPP:Line( lin, 150, lin + 60, 150 )
	oPrintPPP:Say( lin + 45, 160, "RESPONSÁVEL PELOS REGISTROS AMBIENTAIS:" , oFont11 ) //"RESPONSÁVEL PELOS REGISTROS AMBIENTAIS:" STR0191
	oPrintPPP:Line( lin, 2940, lin + 60, 2940 )
	oPrintPPP:Line( lin + 60, 50, lin + 60, 2940 )
	SomaLinha()
	oPrintPPP:Line( lin, 50, lin + 80, 50 )
	oPrintPPP:Say( lin + 35, 60, "16.1-Período", oFont09n ) //"16.1-Período" // STR0192
	oPrintPPP:Line( lin, 550, lin + 80, 550 )
	oPrintPPP:Say( lin + 35, 560, "16.2-CPF", oFont09n ) // "16.2-CPF" // STR0193
	oPrintPPP:Line( lin, 880, lin + 80, 880 )
	oPrintPPP:Say( lin + 35, 890, "16.3-Registro Conselho", oFont09n ) // "16.3-Registro Conselho" STR0194
	oPrintPPP:Say( lin + 70, 890, "de Classe" , oFont09n ) // "de Classe" STR0195
	oPrintPPP:Line( lin, 1350, lin + 80, 1350 )
	oPrintPPP:Say( lin + 35, 1360, "16.4-Nome do Profissional Legalmente", oFont09n ) //"16.4-Nome do Profissional Legalmente " STR0196
	oPrintPPP:Say( lin + 70, 1360, "Habilitado", oFont09n ) // "Habilitado" STR0320
	oPrintPPP:Line( lin, 2940, lin + 80, 2940 )
	oPrintPPP:Line( lin + 80, 50, lin + 80, 2940 )
	SomaLinha( 30 )

	lFirst := .T.

	DBSelectArea( cTRBTMK )
	DBSetOrder( 1 )
	DBGoTop()

	// Verifica o conteudo da pergunta "Reponsavel Ambiental ?"
	If xm_par31 == 1 // Somente Médicos
		cCondInd := "1"
	ElseIf xm_par31 == 2 // Somente Engenheiros
		cCondInd := "4"
	ElseIf xm_par31 == 3 // Ambos
		cCondInd := "1/4"
	EndIf

	While !Eof()

		If NGCADICBASE( "TMK_RESAMB", "A", "TMK", .F. ) // Existe o campo TMK_RESAMB
			lRespAmb := ( (cTRBTMK)->RESAMB == "1" ) // Verifica se e Responsavel Ambiental
		EndIf

		// Se nao For Responsavel Ambiental ou nao For da funcao definida pela pergunta MV_PAR31 pula o registro
		If (!Empty( cCondInd ) .And. !( (cTRBTMK)->INDFUN $ cCondInd )) .Or. !lRespAmb
			DBSelectArea( cTRBTMK )
			DBSkip()
			Loop
		EndIf

		If ((cTRBTMK)->DTINI > (IIf( !lDemitido, dDataBase, dDtDemiss ))) .Or. ;
			(!Empty( (cTRBTMK)->DTFIM ) .And. (cTRBTMK)->DTFIM < dDtAdmiss)

			DBSelectArea( cTRBTMK )
			DBSkip()
			Loop
		EndIf

		If lRespFim
			dDataIni := (cTRBTMK)->DTINI
			dDataFim := (cTRBTMK)->DTFIM
		Else
			dDataIni := IIf( (cTRBTMK)->DTINI < dDtAdmiss, dDtAdmiss, (cTRBTMK)->DTINI )

			If Empty( (cTRBTMK)->DTFIM )
				dDataFim := dDtDemiss
			Else

				If !lDemitido
					dDataFim := IIf( (cTRBTMK)->DTFIM >= dDataBase, dDtDemiss, (cTRBTMK)->DTFIM )
				Else
					dDataFim := IIf( (cTRBTMK)->DTFIM >= dDtDemiss, dDtDemiss, (cTRBTMK)->DTFIM )
				EndIf

			EndIf

		EndIf

		aDatasPPP := fDesagData( dDataIni, dDataFim )

		For nX := 1 To Len( aDatasPPP )

			If lin != 380 .Or. !lFirst
				SomaLinha( 50, lFirst )
			EndIf

			lFirst := .F.
			oPrintPPP:Line( lin, 50, lin + 50, 50 )
			oPrintPPP:Say( lin + 35, 60, aDatasPPP[nX], oFont09 )
			oPrintPPP:Line( lin, 550, lin + 50, 550 )

			If !Empty( ( cTRBTMK )->CIC )
				oPrintPPP:Say( lin + 35, 560, Transform( ( cTRBTMK )->CIC, '@R 999.999.999-99' ), oFont08 ) // CPF
			EndIf

			oPrintPPP:Line( lin, 880, lin + 50, 880 )

			If !Empty( (cTRBTMK)->REGNUM )
				oPrintPPP:Say( lin + 35, 890, (cTRBTMK)->REGNUM, oFont09 ) // Registro MTB
			Else
				oPrintPPP:Say( lin + 35, 890, "NA", oFont10 ) // Registro MTB
			EndIf

			oPrintPPP:Line( lin, 1350, lin + 50, 1350 )
			oPrintPPP:Say( lin + 35, 1360, SubStr( (cTRBTMK)->NOME, 1, 40 ), oFont09 ) // Nome
			oPrintPPP:Line( lin, 2940, lin + 50, 2940 )
			oPrintPPP:Line( lin + 50, 50, lin + 50, 2940 )
		Next nX

		DBSelectArea( cTRBTMK )
		DBSkip()
	End

	If lFirst

		If lin != 380
			SomaLinha( 50, .T. )
		EndIf

		oPrintPPP:Line( lin, 50, lin + 50, 50 )
		oPrintPPP:Say( lin + 35, 60, "__/__/____" + " a " + "__/__/____", oFont09 ) // STR0173
		oPrintPPP:Say( lin + 35, 890, "NA", oFont10 )   //16.3-Registro MTB
		oPrintPPP:Say( lin + 35, 1360, "NA", oFont10 ) //16.4-Nome
		oPrintPPP:Line( lin, 550, lin + 50, 550 )
		oPrintPPP:Line( lin, 880, lin + 50, 880 )
		oPrintPPP:Line( lin, 1350, lin + 50, 1350 )
		oPrintPPP:Line( lin, 2940, lin + 50, 2940 )
		oPrintPPP:Line( lin + 50, 50, lin + 50, 2940 )
	EndIf

	// QUARTA PARTE
	SomaLinha( 80 )

	If ( lin + 715 ) > 2000
		SomaLinha( , , .T. )
	EndIf

	If lin != 380
		oPrintPPP:Line( lin, 50, lin, 2940 )
	EndIf

	oPrintPPP:Line( lin, 50, lin + 80, 50 )
	oPrintPPP:Line( lin, 2940, lin + 80, 2940 )
	oPrintPPP:Line( lin + 80, 50, lin + 80, 2940 )
	oPrintPPP:Say( lin + 60, 70, "RESPONSÁVEIS PELAS INFORMAÇÕES", oFont13 ) //"RESPONSÁVEIS PELAS INFORMAÇÕES" STR0219
	SomaLinha( 80 )
	txtPPP := "Declaramos, para todos os fins de direito, que as informações prestadas neste documento são " //STR0220 //"Declaramos, para todos os fins de direito, que as informações prestadas neste documento são "
	txtPPP += "verídicas e foram transcritas fielmente dos registros administrativos, das demonstrações " // STR0221 //"verídicas e foram transcritas fielmente dos registros administrativos, das demonstrações "
	txtPPP += "ambientais e dos programas médicos de responsabilidade da empresa. É de nosso conhecimento que " // STR0222 //"ambientais e dos programas médicos de responsabilidade da empresa. É de nosso conhecimento que "
	txtPPP += "a prestação de informações falsas neste documento constitui crime de falsificação de documento" // STR0223 //"a prestação de informações falsas neste documento constitui crime de falsificação de documento "
	txtPPP += "público, nos termos do art. 297 do Código Penal e, também, que tais informações são de caráter" // STR0224 //"público, nos termos do art. 297 do Código Penal e, também, que tais informações são de caráter "
	txtPPP += "privativo do trabalhador, constituindo crime, nos termos da Lei nº 9.029 de 13 de Abril de 1995, práticas" // STR0225 //"privativo do trabalhador, constituindo crime, nos termos da Lei nº 9.029 de 13 de Abril de 1995, práticas "
	txtPPP += "discriminatórias decorrentes de sua exigibilidade por outrem, bem como se sua divulgação para" // STR0226 //"discriminatórias decorrentes de sua exigibilidade por outrem, bem como se sua divulgação para "
	txtPPP += "terceiros, ressalvado quando exigida pelos órgãos públicos competentes." // STR0227 //"terceiros, ressalvado quando exigida pelos órgãos públicos competentes."

	fImpMemo( txtPPP )

	DBSelectArea( cAliasRES )
	DBSetOrder( 1 )
	DBSeek( xFilial( cAliasRES, cFilRES ) + xm_par09 ) // Representante Empresa ?

	SomaLinha( 55 )
	oPrintPPP:Line( lin, 50, lin + 60, 50 )
	oPrintPPP:Say( lin + 50, 60, "17-Data Emissão PPP", oFont10 ) // "19-Data Emissão PPP" STR0228
	oPrintPPP:Line( lin, 500, lin + 60, 500 )
	oPrintPPP:Say( lin + 45, 520, '18', oFont11 )
	oPrintPPP:Line( lin, 580, lin + 60, 580 )
	oPrintPPP:Say( lin + 45, 590, "REPRESENTANTE LEGAL DA EMPRESA", oFont11 ) // "REPRESENTANTE LEGAL DA EMPRESA" STR0229
	oPrintPPP:Line( lin, 2940, lin + 60, 2940 )
	oPrintPPP:Line( lin + 60, 50, lin + 60, 2940 )
	SomaLinha()

	// Ponto de Entrada para adicionar um responsavel Legal
	If ExistBlock( "RMDT0062" )
		ExecBlock( "RMDT0062", .F., .F., { oPrintPPP, lin } )
	Else
		oPrintPPP:Line( lin, 50, lin + 500, 50 )
		oPrintPPP:Line( lin, 2940, lin + 500, 2940 )
		oPrintPPP:Line( lin + 500, 50, lin + 500, 2940 )
		oPrintPPP:Line( lin + 100, 500, lin + 100, 2940 )
		oPrintPPP:Line( lin, 500, lin + 500, 500 )
		oPrintPPP:Say( lin + 30, 510, "18.1-CPF do Representante Legal", oFont09 ) // "18.1-CPF do Representante Legal" STR0230

		If !Empty( &cCpfRes )
			oPrintPPP:Say( lin + 90, 510, Transform( &cCpfRes, '@R 999.999.999-99' ), oFont10 )
		Else
			oPrintPPP:Say( lin + 90, 510, "NA", oFont10 )
		EndIf

		oPrintPPP:Line( lin, 1300, lin + 500, 1300 )
		oPrintPPP:Say( lin + 30, 1310, "18.2-Nome do Representante Legal", oFont09 ) // "18.2-Nome do Representante Legal" STR0231


		If	( !Empty( SRA->RA_NOMECMP ) ) .And. ( AllTrim( GETMV( "MV_MDTRESP" ) ) == "1" )
			oPrintPPP:Say( lin + 90, 1310, AllTrim( SubStr( SRA->RA_NOMECMP, 1, 45 ) ), oFont10 )
		Else
			oPrintPPP:Say( lin + 90, 1310, SubStr( &cCNomeRES, 1, 40 ), oFont10 )
		EndIf

		oPrintPPP:Say( lin + 210, 150, NGPPPDATE( IIf( xm_par21 == 3, xm_par22, IIf( xm_par21 == 2, dDtDemiss, dDataBase ) ), .T. ), oFont10 ) //Data Emissao PPP ?//Informe a Data ?
		oPrintPPP:Say( lin + 480, 700, "(Carimbo da Empresa)", oFont09 ) // "(Carimbo da Empresa)" STR0232
		oPrintPPP:Line( lin + 430, 1400, lin + 430, 2110 )
		oPrintPPP:Say( lin + 480, 1450, "(Assinatura física ou eletrônica)", oFont09 ) // "(Assinatura física ou eletrônica)" STR0233
	EndIf

	SomaLinha( 520 )
	oPrintPPP:Line( lin, 50, lin, 2940 )
	oPrintPPP:Line( lin, 50, lin + 80, 50 )
	oPrintPPP:Line( lin, 2940, lin + 80, 2940 )
	oPrintPPP:Line( lin+ 80, 50, lin + 80, 2940 )
	oPrintPPP:Say( lin + 60, 60, "OBSERVAÇÕES", oFont13 ) // "OBSERVAÇÕES" STR0234
	SomaLinha( 80 )

	DBSelectArea( "TMZ" )
	DBSetOrder( 1 )
	DBSeek( xFilial( "TMZ" ) + xm_par14 ) // Observacao ?

	If !Empty( xm_par14 ) .And. !Empty( TMZ->TMZ_DESCRI ) // Se a pergunta de Observações está vazia não imprime
		fImpMemo( TMZ->TMZ_DESCRI )

		If xm_par23 == 1// .And. !Empty( xm_par24 )
			SomaLinha( 55, .F. )
		EndIf

	EndIf

	If xm_par23 == 1 // Listar Observ. Epis ?

		oPrintPPP:Line( lin, 50, lin + 60, 50 )
		oPrintPPP:Say( lin + 50, 70, "OBSERVAÇÕES REFERENTES AOS EPI'S", oFont11 ) // "OBSERVAÇÕES REFERENTES AOS EPI'S" STR0235
		oPrintPPP:Line( lin, 2940, lin + 60, 2940 )
		oPrintPPP:Line( lin + 60, 50, lin + 60, 2940 )
		SomaLinha( 60 )

		For nInd := 1 To Len( aNUMCAPS )
			oPrintPPP:Line( lin, 50, lin + 40, 50 )
			oPrintPPP:Line( lin, 2940, lin + 40, 2940 )
			oPrintPPP:Say( lin + 40, 60, SubStr( "C.A.:" + AllTrim( aNUMCAPS[nInd, 1] ) + " - " + aNUMCAPS[nInd, 2], 1, 105 ), oFont09 ) //"C.A.: " STR0236

			If nInd == Len( aNUMCAPS )
				oPrintPPP:Line( lin + 40, 50, lin + 55, 50 )
				oPrintPPP:Line( lin + 40, 2940, lin + 55, 2940 )
				oPrintPPP:Line( lin + 55, 50, lin + 55, 2940 )
				SomaLinha( 40, .F. )
			Else
				SomaLinha( 40, .T. )
			EndIf

		Next nInd

	EndIf

	If !Empty( xm_par24 ) .And. xm_par23 == 1 // Observacao EPI \ EPC. ? //Listar Observ. Epis ?
		oPrintPPP:Line( lin, 50, lin + 60, 50 )
		oPrintPPP:Say( lin + 50, 70, "OBSERVAÇÕES REFERENTES AOS EPI's / EPC's" , oFont11 ) // "OBSERVAÇÕES REFERENTES AOS EPI's / EPC's" STR0237
		oPrintPPP:Line( lin, 2940, lin + 60, 2940 )
		oPrintPPP:Line( lin + 60, 50, lin + 60, 2940 )
		SomaLinha( 60 )
		DBSelectArea( "TMZ" )
		DBSetOrder( 1 )
		DBSeek( xFilial( "TMZ" ) + xm_par24 ) // Observacao EPI \ EPC. ?

		fImpMemo( TMZ->TMZ_DESCRI )

	EndIf

	FWRestArea( aAreaSRA )
	FWRestArea( aSM0Area )

	oPrintPPP:SayAlign( 2200, 50, Str( nPaginaPPP, 3 ), oFont09n, 2940, 280, CLR_BLACK, 2, 1 )
	oPrintPPP:EndPage()
	nPaginaPPP++

Return

/*
===============================================================================================================================
Programa--------------: RMDT006()
Autores---------------: Denis Hyroshi de Souza / Gabriel Sokacheski (Totvs)
Conversão para Italac-: Julio de Paula Paz
Data da Criacao-------: 22/09/2023
Descrição-------------: Verifica se o funcionário é um atendente prestador de
                        serviço (SIGATEC)
Parametros------------: Nenhum
Retorno---------------: lAtendente, verdadeiro caso o funcionário seja um atendente
===============================================================================================================================
*/
Static Function fVerAte()

	Local aArea := GetArea( 'AA1' )

	Local lAtendente := .F.

	If SuperGetMv( 'MV_NG2GS', .F., .F. ) // Integração com o módulo prestador de serviço (SIGATEC)

		DBSelectArea( 'AA1' )
		DBSetOrder( 7 )

		If DBSeek( xFilial( 'AA1' ) + SRA->RA_MAT + SRA->RA_FILIAL ) // Caso o funcionário seja um atendente
			lAtendente := .T.
		EndIf

	EndIf

	FWRestArea( aArea )

Return lAtendente

/*
===============================================================================================================================
Programa--------------: RMDT006()
Autores---------------: Denis Hyroshi de Souza / Gabriel Sokacheski (Totvs)
Conversão para Italac-: Julio de Paula Paz
Data da Criacao-------: 22/09/2023
Descrição-------------: Verifica como deve ser e retorna o histórico correto do funcionário
Parametros------------: Nenhum
Retorno---------------: aHistorico, contém o histórico do funcionário.
===============================================================================================================================
*/
Static Function fVerBusHis()

	Local aArea := GetArea( 'AA1' )

	Local aHistorico := {}

	If SuperGetMv( 'MV_NG2GS', .F., .F. ) // Integração com o módulo prestador de serviço (SIGATEC)

		DBSelectArea( 'AA1' )
		DBSetOrder( 7 )

		If DBSeek( xFilial( 'AA1' ) + SRA->RA_MAT + SRA->RA_FILIAL ) // Caso o funcionário seja um atendente
			aHistorico := aClone( fHisPreSer( AA1->AA1_CODTEC ) )
		Else // Caso o funcionário não seja um atendente
			aHistorico := aClone( NG700HISTO() )
		EndIf

	Else

		aHistorico := aClone( NG700HISTO() )

	EndIf

	FWRestArea( aArea )

Return aHistorico

/*
===============================================================================================================================
Programa--------------: RMDT006()
Autores---------------: Denis Hyroshi de Souza / Gabriel Sokacheski (Totvs)
Conversão para Italac-: Julio de Paula Paz
Data da Criacao-------: 22/09/2023
Descrição-------------: Busca o histórico do funcionário atendente no módulo prestador de
                        serviço (SIGATEC)
Parametros------------: Nenhum
Retorno---------------: aHistorico, contém o histórico do funcionário
===============================================================================================================================
*/
Static Function fHisPreSer( cAtendente )

	Local aDados		:= { { cEmpAnt, cFilAnt, SRA->RA_MAT } } // Dados da empresa e filial atual do funcionário
	Local aTabelas		:= {;
		{ 'TGY', 01 },;
		{ 'TFF', 01 },;
		{ 'ABS', 01 },;
		{ 'SA1', 01 },;
		{ 'SRA', 01 },;
		{ 'CTT', 01 },;
		{ 'SR9', 01 },;
		{ 'SR7', 01 },;
		{ 'SRJ', 01 },;
		{ 'SQ3', 01 },;
		{ 'TM0', 01 };
	} // Tabelas utilizadas na query
	Local aHistorico	:= {}

	Local cGFIP 		:= ''
	Local cBusEmp		:= cEmpAnt
	Local cBusFil		:= cFilAnt
	Local cBusMat		:= SRA->RA_MAT
	Local cVerEmp		:= SuperGetMv( 'MV_NG2MEMP', .F., 'N' ) // Considera histórico em outras empresas
	Local cVerFil		:= SuperGetMv( 'MV_NG2MFIL', .F., 'N' ) // Considera histórico em outras filiais
	Local cAliasTGY		:= ''
	Local cAliasSRE 	:= ''
	Local cEmpBackup	:= cEmpAnt
	Local cFilBackup	:= cFilAnt
	Local cR7CARGO		:= Space( TamSX3( 'R7_CARGO' 	)[ 1 ] )
	Local cRJCARGO		:= Space( TamSX3( 'RJ_CARGO' 	)[ 1 ] )
	Local cR7FUNCAO		:= Space( TamSX3( 'R7_FUNCAO' 	)[ 1 ] )
	Local cTFFCARGO		:= Space( TamSX3( 'TFF_CARGO' 	)[ 1 ] )
	Local cABSCCUSTO	:= Space( TamSX3( 'ABS_CCUSTO' 	)[ 1 ] )
	Local cTFFFUNCAO	:= Space( TamSX3( 'TFF_FUNCAO' 	)[ 1 ] )

	Local dCorte 		:= fBusDatCor() // Data de corde do PPP
	Local dInicio		:= CtoD( '//' )
	Local dFim			:= CtoD( '//' )

	Local lCorta		:= .T.
	Local lVerTra		:= .T.

	Local nReg			:= 1
	Local nDado 		:= 0

	If MV_PAR37 == 2 .And. cVerFil == 'S' // Busca as empresas e filiais em que o funcionário trabalhou

		While lVerTra

			cAliasSRE := GetNextAlias()

			BeginSql Alias cAliasSRE
				SELECT
					RE_EMPD, RE_FILIALD, RE_MATD
				FROM
					%Table:SRE% SRE
				WHERE
					RE_EMPP = %exp:cBusEmp%
					AND RE_FILIALP = %exp:cBusFil%
					AND RE_MATP = %exp:cBusMat%
					AND %notDel%
			EndSql

			( cAliasSRE )->( DBGoTop() )

			If ( cAliasSRE )->( !Eof() )

				If ( cVerEmp == 'S' .Or. cEmpAnt == ( cAliasSRE )->RE_EMPD )

					aAdd( aDados, {;
						( cAliasSRE )->RE_EMPD,;
						( cAliasSRE )->RE_FILIALD,;
						( cAliasSRE )->RE_MATD;
					} )

					cBusEmp := ( cAliasSRE )->RE_EMPD
					cBusFil := ( cAliasSRE )->RE_FILIALD
					cBusMat := ( cAliasSRE )->RE_MATD

				EndIf

			Else

				lVerTra := .F.

			EndIf

			( cAliasSRE )->( DBCloseArea() )

		End

	EndIf

	For nDado := 1 To Len( aDados )

		cAliasTGY := GetNextAlias()

		If cEmpAnt != aDados[ nDado, 1 ] // Abre as tabelas e posiciona em outra empresa caso necessário
			fOpenSX( { 'SX3' }, aDados[ nDado, 1 ] )
			NGPrepTBL( aTabelas, aDados[ nDado, 1 ], aDados[ nDado, 2 ] )
			cEmpAnt 	:= aDados[ nDado, 1 ]
			cR7CARGO	:= Space( TamSX3( 'R7_CARGO' 	)[ 1 ] )
			cRJCARGO	:= Space( TamSX3( 'RJ_CARGO' 	)[ 1 ] )
			cABSCUSTO	:= Space( TamSX3( 'ABS_CCUSTO' 	)[ 1 ] )
			cR7FUNCAO	:= Space( TamSX3( 'R7_FUNCAO' 	)[ 1 ] )
			cTFFCARGO	:= Space( TamSX3( 'TFF_CARGO' 	)[ 1 ] )
			cTFFFUNCAO	:= Space( TamSX3( 'TFF_FUNCAO' 	)[ 1 ] )
		EndIf

		If cFilAnt != aDados[ nDado, 2 ] // Posiciona em outra filial caso necessário
			cFilAnt := aDados[ nDado, 2 ]
		EndIf

		BeginSql Alias cAliasTGY
			SELECT
				SRA.RA_FILIAL, SRA.RA_MAT, TGY.TGY_DTINI, TGY.TGY_DTFIM, SA1.A1_CGC, CTT.CTT_DESC01, SQ3.Q3_DESCSUM,
				SRJ.RJ_DESC, SRJ.RJ_CODCBO, SR9.R9_DESC, CTT.CTT_OCORRE, SRA.RA_OCORREN, CTT.CTT_CUSTO, SRA.RA_DEPTO,
				SQ3.Q3_CARGO, SRJ.RJ_FUNCAO, TM0.TM0_NUMFIC
			FROM
				%Table:SRA% SRA
				INNER JOIN
					%Table:AA1% AA1 ON
						AA1.AA1_FUNFIL = SRA.RA_FILIAL
						AND AA1.AA1_CDFUNC = SRA.RA_MAT
						AND AA1.%notDel%
				INNER JOIN
					%Table:TGY% TGY ON
						TGY.TGY_FILIAL = %xFilial:TGY%
						AND TGY.TGY_ATEND = AA1.AA1_CODTEC
						AND TGY.%notDel%
				INNER JOIN
					%Table:TFF% TFF ON
						TFF.TFF_FILIAL = %xFilial:TFF%
						AND TFF.TFF_COD = TGY.TGY_CODTFF
						AND TFF.%notDel%
				INNER JOIN
					%Table:ABS% ABS ON
						ABS.ABS_FILIAL = %xFilial:ABS%
						AND ABS.ABS_LOCAL = TFF.TFF_LOCAL
						AND ABS.%notDel%
				INNER JOIN
					%Table:SA1% SA1 ON
						SA1.A1_FILIAL = %xFilial:SA1%
						AND SA1.A1_COD = ABS.ABS_CODIGO
						AND SA1.A1_LOJA = ABS.ABS_LOJA
						AND SA1.%notDel%
				INNER JOIN
					%Table:CTT% CTT ON
						CTT.CTT_FILIAL = %xFilial:CTT%
						AND CTT.CTT_CUSTO = 
							Case
								WHEN ABS.ABS_CCUSTO != %exp:cABSCCUSTO% THEN
									ABS.ABS_CCUSTO
								Else
									SRA.RA_CC
							END
						AND CTT.%notDel%
				LEFT JOIN
					%Table:SR9% SR9 ON
						SR9.R9_FILIAL = SRA.RA_FILIAL
						AND SR9.R9_MAT = SRA.RA_MAT
						AND SR9.R9_CAMPO = "RA_OCORREN"
						AND SR9.R9_DATA >= TGY.TGY_DTINI
						AND SR9.R9_DATA <= TGY.TGY_DTFIM
						AND SR9.%notDel%
				LEFT JOIN
					%Table:SR7% SR7 ON
						SR7.R7_FILIAL = SRA.RA_FILIAL
						AND SR7.R7_MAT = SRA.RA_MAT
						AND SR7.R7_DATA >= TGY.TGY_DTINI
						AND SR7.R7_DATA <= TGY.TGY_DTFIM
						AND SR7.%notDel%
				LEFT JOIN
					%Table:SRJ% SRJ ON
						SRJ.RJ_FILIAL = %xFilial:SRJ%
						AND SRJ.RJ_FUNCAO = 
							Case 
								WHEN TFF.TFF_FUNCAO != %exp:cTFFCARGO% THEN
									TFF.TFF_FUNCAO
								WHEN SR7.R7_FUNCAO != %exp:cR7FUNCAO% THEN
									SR7.R7_FUNCAO
								Else
									SRA.RA_CODFUNC
							END
						AND SRJ.%notDel%
				LEFT JOIN
					%Table:SQ3% SQ3 ON
						SQ3.Q3_FILIAL = %xFilial:SQ3%
						AND SQ3.Q3_CARGO = 
							Case
								WHEN TFF.TFF_CARGO != %exp:cTFFFUNCAO% THEN
									TFF.TFF_CARGO
								WHEN SR7.R7_CARGO != %exp:cR7CARGO% THEN
									SR7.R7_CARGO
								WHEN SRJ.RJ_CARGO != %exp:cRJCARGO% THEN
									SRJ.RJ_CARGO
								Else
									SRA.RA_CARGO
							END
						AND SQ3.Q3_CC = CTT.CTT_CUSTO
						AND SQ3.%notDel%
				LEFT JOIN
					%Table:TM0% TM0 ON
						TM0.TM0_FILFUN = SRA.RA_FILIAL
						AND TM0.TM0_MAT = SRA.RA_MAT
						AND TM0.%notDel%
			WHERE
				SRA.RA_FILIAL = %exp:aDados[ nDado, 2 ]%
				AND SRA.RA_MAT = %exp:aDados[ nDado, 3 ]%
				AND SRA.%notDel%
			GROUP BY
				SRA.RA_FILIAL, SRA.RA_MAT, TGY.TGY_DTINI, TGY.TGY_DTFIM, SA1.A1_CGC, CTT.CTT_DESC01, SQ3.Q3_DESCSUM,
				SRJ.RJ_DESC, SRJ.RJ_CODCBO, SR9.R9_DESC, CTT.CTT_OCORRE, SRA.RA_OCORREN, CTT.CTT_CUSTO, SRA.RA_DEPTO,
				SQ3.Q3_CARGO, SRJ.RJ_FUNCAO, TM0.TM0_NUMFIC
			ORDER BY
				TGY.TGY_DTINI, TGY.TGY_DTFIM
		EndSql

		( cAliasTGY )->( DBGoTop() )

		While ( cAliasTGY )->( !Eof() )

			fRedDat( cAliasTGY, @dInicio, @dFim )

			// Se existir uma data de corte verifica quais registros devem ser impressos e qual é a data de início
			If !Empty( dCorte )

				While lCorta

					If dCorte > dInicio .And. !Empty( dInicio ) // Pula para o próximo registro

						nReg := ( cAliasTGY )->( Recno() )
						( cAliasTGY )->( DBSkip() )
						fRedDat( cAliasTGY, @dInicio, @dFim )

					Else

						If dCorte != dInicio // Volta para o registro anterior

							( cAliasTGY )->( DBGoTop() )
							( cAliasTGY )->( DBGoTo( nReg ) )
							fRedDat( cAliasTGY, @dInicio, @dFim )

							If dCorte > dInicio // Define a data de início com o valor da data de corte
								dInicio := dCorte
							EndIf

							lCorta := .F.

						EndIf

					EndIf

				End

			EndIf

			If dCorte <= dFim

				If !Empty( ( cAliasTGY )->CTT_OCORRE )
					cGFIP := ( cAliasTGY )->CTT_OCORRE
				ElseIf !Empty( ( cAliasTGY )->R9_DESC )
					cGFIP := ( cAliasTGY )->R9_DESC
				ElseIf !Empty( ( cAliasTGY )->RA_OCORREN )
					cGFIP := ( cAliasTGY )->RA_OCORREN
				EndIf

				aAdd( aHistorico, {;
					( cAliasTGY )->RA_FILIAL,; 			// [1]
					( cAliasTGY )->RA_MAT,; 			// [2]
					dInicio,;							// [3]
					dFim,; 								// [4]
					( cAliasTGY )->CTT_DESC01,; 		// [5]
					( cAliasTGY )->Q3_DESCSUM,; 		// [6]
					( cAliasTGY )->RJ_DESC,; 			// [7]
					( cAliasTGY )->RJ_CODCBO,; 			// [8]
					cGFIP,;								// [9]
					( cAliasTGY )->A1_CGC,; 			// [10]
					2,; 								// [11]
					aDados[ nDado, 1 ]; 				// [12]
				} )

				//-----------------------------
				// Utilizado nos itens 14 e 15
				//-----------------------------

				RecLock( cTrbPPP, .T. )

					( cTrbPPP )->DTDE   := dInicio
					( cTrbPPP )->DTATE  := dFim
					( cTrbPPP )->CNPJ   := ( cAliasTGY )->A1_CGC
					( cTrbPPP )->TIPINS := 2
					( cTrbPPP )->CUSTO  := ( cAliasTGY )->CTT_CUSTO
					( cTrbPPP )->DEPTO  := ( cAliasTGY )->RA_DEPTO
					( cTrbPPP )->FILIAL := ( cAliasTGY )->RA_FILIAL
					( cTrbPPP )->MAT    := ( cAliasTGY )->RA_MAT
					( cTrbPPP )->CARGO  := ( cAliasTGY )->Q3_CARGO
					( cTrbPPP )->CODFUN	:= ( cAliasTGY )->RJ_FUNCAO
					( cTrbPPP )->GFIP   := cGFIP
					( cTrbPPP )->EMP    := aDados[ nDado, 1 ]

				( cTrbPPP )->( MSUnLock() )

				aAdd( aMatriculas, {;
					( cAliasTGY )->RA_FILIAL,;
					( cAliasTGY )->RA_MAT,;
					aDados[ nDado, 1 ];
				} )

				NG700TAREF(;
					( cAliasTGY )->RA_FILIAL,;
					( cAliasTGY )->RA_MAT,;
					dInicio,;
					dFim,;
					( cAliasTGY )->CTT_CUSTO,;
					( cAliasTGY )->RA_DEPTO,;
					( cAliasTGY )->RJ_FUNCAO,;
					( cAliasTGY )->TM0_NUMFIC,;
					aDados[ nDado, 1 ];
				)

			EndIf

			nReg := ( cAliasTGY )->( Recno() )
			( cAliasTGY )->( DBSkip() )

		End

		( cAliasTGY )->( DBCloseArea() )

	Next nDado

	aSort( aHistorico, Nil, Nil, { | x, y | x[ 3 ] + x [ 4 ] < y[ 3 ] + y[ 4 ] } ) // Ordena de acordo com a data de início e fim

	If cEmpAnt != cEmpBackup // Volta a empresa logada caso necessário
		fOpenSX( { 'SX3' }, cEmpBackup )
		NGPrepTBL( aTabelas, cEmpBackup, cFilBackup )
		cEmpAnt := cEmpBackup
	EndIf

Return aHistorico

/*
===============================================================================================================================
Programa--------------: RMDT006()
Autores---------------: Denis Hyroshi de Souza / Gabriel Sokacheski (Totvs)
Conversão para Italac-: Julio de Paula Paz
Data da Criacao-------: 22/09/2023
Descrição-------------: Redefine as datas de início e fim.
Parametros------------: cAliasTGY, alias das informações
                        dInicio, data início
                        dFim, data fim
Retorno---------------: Nenhum
===============================================================================================================================
*/
Static Function fRedDat( cAliasTGY, dInicio, dFim )

	dInicio := SToD( ( cAliasTGY )->TGY_DTINI )
	dFim 	:= SToD( ( cAliasTGY )->TGY_DTFIM )

Return

/*
===============================================================================================================================
Programa--------------: RMDT006()
Autores---------------: Denis Hyroshi de Souza / Gabriel Sokacheski (Totvs)
Conversão para Italac-: Julio de Paula Paz
Data da Criacao-------: 22/09/2023
Descrição-------------: Retorna a data de corte do PPP caso exista
Parametros------------: Nenhum
Retorno---------------: aCorte, data de corte do PPP
===============================================================================================================================
*/
Static Function fBusDatCor()

	Local dCorte 	:= CtoD( '//' )
	Local dCorPar	:= SuperGetMv( 'MV_NG2PPPD', .F., CtoD( '//' ) )

	If xm_par12 == 1 // Somente a partir de janeiro de 2004
		dCorte := CtoD( '01/01/2004' )
	EndIf

	If !Empty( dCorPar ) // Data de corte informada
		If Empty( dCorte ) .Or. dCorPar > dCorte
			dCorte := dCorPar
		EndIf
	EndIf

Return dCorte

/*
===============================================================================================================================
Programa--------------: RMDT006()
Autores---------------: Denis Hyroshi de Souza / Gabriel Sokacheski (Totvs)
Conversão para Italac-: Julio de Paula Paz
Data da Criacao-------: 22/09/2023
Descrição-------------: Verifica se o Funcionario tem Cat impresso.
Parametros------------: cFilialTM0, Caracter, Filial da ficha medica do funcionario
                        nFicha, Numerico, Numero da ficha medica do funcionario
                        cEmpTM0, Caracter, Empresada ficha medica do funcionario

Retorno---------------: Nenhum
===============================================================================================================================
*/
Static Function NG700VECAT( cFilialTM0, nFicha, cEmpTM0 )

	Local cFilTNC := ""
	Local cModoCom := ""

	If lMudEmpr .And. cEmpTM0 != cEmpPPP
		cModo := FWModeAccess( "TNC" )
		EMP700OPEN( "TNC", "TNC", 1, cEmpTM0, @cModo, cFilialTM0 )
	EndIf

	cModoCom := f700RetCom( "TNC" )
	cFilTNC := FwxFilial( "TNC", cFilialTM0, SubStr( cModoCom, 1, 1 ), SubStr( cModoCom, 2, 1 ), SubStr( cModoCom, 3, 1 ) )
	DBSelectArea( "TNC" )
	DBSetOrder( 7 )
	DBSeek( cFilTNC + nFicha)

	While !Eof() .And. cFilTNC == TNC->TNC_FILIAL

		If nFicha == TNC->TNC_NUMFIC .And. !Empty( TNC->TNC_DTEMIS ) .And. TNC->TNC_DTEMIS >= dDtAdmiss

			cCat := TNC->TNC_ACIDEN

			If !Empty( TNC->TNC_CATINS )
				cCat := TNC->TNC_CATINS
			EndIf
				
			
			 // Busca o retorno do eSocial
			//If !Empty( TNC->TNC_RECIBO ) .Or. !Empty( TNC->TNC_RECORI ) .And.;
			//	aScan( aCat, { |x| DToS( x[1] ) == DToS( TNC->TNC_DTEMIS ) .And. AllTrim(x[2]) == AllTrim(TNC->TNC_RECIBO) } ) <= 0  // aScan( aCat, { |x| DToS( x[1] ) + x[2] == DToS( TNC->TNC_DTEMIS ) + TNC->TNC_RECIBO } ) <= 0
			//		aAdd( aCat, { TNC->TNC_DTEMIS, TNC->TNC_RECIBO, TNC->TNC_RECORI, .T. } )
			//Else // Busca da maneira antiga
					
			//	If aScan( aCat, { |x| DToS( x[1] ) + x[2] == DToS( TNC->TNC_DTEMIS ) + SubStr( cCat, 1, 13 ) } ) <= 0
			//		aAdd( aCat, { TNC->TNC_DTEMIS, SubStr( cCat, 1, 13 ), .F. } )
			//	EndIf

			//EndIf

			If !Empty( TNC->TNC_RECIBO ) .Or. !Empty( TNC->TNC_RECORI ) 
			   
			   _nI := aScan( aCat, { |x| DToS( x[1] ) == DToS( TNC->TNC_DTEMIS ) .And. AllTrim(x[2]) == AllTrim(TNC->TNC_RECIBO) } )
			   If _nI == 0
				  aAdd( aCat, { TNC->TNC_DTEMIS, TNC->TNC_RECIBO, TNC->TNC_RECORI, .T. } )
			   EndIf 
			
			EndIf

		EndIf

		DBSkip()

	End

	If lMudEmpr .And. cEmpTM0 != cEmpPPP
		EMP700OPEN( "TNC", "TNC", 1, cEmpPPP, @cModo )
	EndIf

Return

/*
===============================================================================================================================
Programa--------------: RMDT006()
Autores---------------: Denis Hyroshi de Souza / Gabriel Sokacheski (Totvs)
Conversão para Italac-: Julio de Paula Paz
Data da Criacao-------: 22/09/2023
Descrição-------------: Carrega os dados do historico do funcionario
Parametros------------: lMDTA102, Logico, Verifica se o funcionario executou alguma tarefa
Retorno---------------: Array, Informacoes sobre o historico do funcionario
===============================================================================================================================
*/
Static Function NG700HISTO( lMDTA102 )

	Local aHistory := {}
	Local nWWW
	Local nXYZ
	Local nBeg
	Local nSizeSRE    := IIf( TamSX3( "RE_FILIALD" )[1] > 0, TamSX3( "RE_FILIALD" )[1], Len( SRE->RE_FILIALD ) )
	Local cCBO        := " " // Guarda o CBO da Funcao
	Local lFimPPP     := .F. // Verifica se acabou o historico de setores
	Local dINITMP     := SRA->RA_ADMISSA //Data Admissao
	Local dINIPPP     := dINITMP //Data Inicio do PPP
	Local dFIMPPP     := IIf( !lDemitido, dDataBase, dDtDemiss ) // Data limite p/ uma transferencia
	Local dFINALPPP   := dFIMPPP //Data final do PPP
	Local aDadosPPP   := {} //Grava dados do historico de setores
	Local cDesFunPPP  := Space( 25 ) //Descricao da Funcao do periodo anterior
	Local cDesFunFOR  := Space( 25 ) //Descricao da Funcao do periodo anterior
	Local cFuncaoPPP  := Space( Len( SRA->RA_CODFUNC ) ) // Funcao do periodo anterior
	Local cFuncaoFOR  := Space( Len( SRA->RA_CODFUNC ) ) // Funcao do periodo anterior
	Local cCargoPPP   := Space( 5 )
	Local cDesCarPPP  := Space( 30 )
	Local cCargoFOR   := Space( 5 )
	Local cDesCarFOR  := Space( 30 )
	Local cGFIP       := "" //Variavel para receber o ultimo código da SR9, antes de 01/01/2004
	Local lAchou      := .T. //Variavel de Controle
	Local lInicio     := .T. //Variavel de Controle
	Local lEntra      := .T. //Variavel de Controle
	Local lTemSR7     := .F. //Variavel de Controle
	Local dDataFOR    := CToD( "  /  /  " )
	Local cKeyEmp     := SM0->M0_CODIGO // Empresa origem
	Local cKeyFil     := PadR( SRA->RA_FILIAL, nSizeSRE )// Filial origem
	Local cKeyMat     := SRA->RA_MAT // Matricula origem
	Local cKeyCus     := SRA->RA_CC // Centro Custo origem
	Local cKeyDep     := SRA->RA_DEPTO // Departamento origem
	Local cCondCus    := Space( Len( SRA->RA_CC ) )
	Local cCondDep    := Space( Len( SRA->RA_DEPTO ) )
	Local cCondALL    := Space( 10 )
	Local lFirstSRE   := .T. //Indica se eh o primeiro SRE
	Local lFirst      := .T.
	Local lAchouSRE   := .F.
	Local nTotRegPPP  := 0
	Local nRegPPP     := 0
	Local lPrimeiro   := .T.
	Local _dFimPPP    := ctod( "  /  /  " )
	Local cFunAnter   := Space( 5 ) //Funcao Anterior, para verificar se nao esta gravando funcao igual
	Local cCarAnter   := Space( 5 )
	Local cRA_CODFUNC := SRA->RA_CODFUNC //Se nao achar transf. de funcao o programa adota a funcao atual
	Local lCposSR7    := IIf( Empty( SRA->RA_CARGO ), .F., .T. )
	Local cRA_CARGO   := IIf( lCposSR7, SRA->RA_CARGO, Space( 5 ) ) //Se nao achar transf. de funcao o programa adota a funcao atual
	Local dDateAte    //Data final do funcionario em uma determinada funcao
	Local aDadosTmp   := {} //temporario
	Local lCNPJCC     := (SuperGetMv( "MV_NG2PPPC", .F., "2" ) == "1")
	Local dDataSRE    := CTOD( "" )
	Local aAreaSRE	  := {}
	Local dDataCorte  := SuperGetMv( "MV_NG2PPPD", .F., CtoD( "" ) )
	Local cModoTM0
	Local cXFilTM0
	Local cModoSRA
	Local cXFilSRA
	Local cModoCTT
	Local cXFilCTT
	Local cModoSRJ
	Local cXFilSRJ
	Local cModoSQ3
	Local cXFilSQ3
	Local cModoSR9
	Local cXFilSR9

	Local lVldMat	 := ValType( MV_PAR37 ) == "N" //Caso o parâmetro exista no Pergunte
	Local lUpdDates	 := .T.
	Local lReutMat	 := SuperGetMv( "MV_REUTMAT", .F., .F. )
	Local lCurrBrnch := IIf( lVldMat, MV_PAR37 == 1, .F. )

	Default lMDTA102 := .F.

	Private dDtTransf := CtoD( "  /  /  " ), cFilTNF := "  "

	// Busca se houve alguma transferencia do funcionario (MV_NG2MFIL e MV_NG2MEMP)
	If lMudEmpr .Or. lMudFilial
		lNaoAchou := .T.

		While !lFimPPP
			lPrimeiro := .T.
			_dFimPPP  := CToD( "  /  /  " )
			cCondCus  := cKeyCus
			cCondDep  := cKeyDep
			cCondALL  := cKeyEmp + cKeyFil + cKeyMat

			DBSelectArea( "SRE" )
			DBSetOrder( 1 )
			DBSeek( cCondALL )

			While !Eof() .And. cCondALL == SRE->RE_EMPD + SRE->RE_FILIALD + SRE->RE_MATD

				If SRE->RE_DATA < dDataSRE
					DBSelectArea( "SRE" )
					DBSkip()
					Loop
				EndIf

				If SRE->RE_EMPP == SRE->RE_EMPD .And. SRE->RE_FILIALP == SRE->RE_FILIALD .And. ;
				   SRE->RE_MATP == SRE->RE_MATD .And. SRE->RE_CCP == SRE->RE_CCD .And. SRE->RE_DEPTOP == SRE->RE_DEPTOD
					DBSelectArea( "SRE" )
					DBSkip()
					Loop
				EndIf

				If (IIf( lFirstSRE, SRE->RE_DATA > dDataBase, SRE->RE_DATA >= dDataBase )) .Or. ;
					SRE->RE_DATA < dINITMP
					DBSelectArea( "SRE" )
					DBSkip()
					Loop
				EndIf

				If SRE->RE_CCD <> cCondCus .Or. SRE->RE_DEPTOD <> cCondDep
					DBSelectArea( "SRE" )
					DBSkip()
					Loop
				EndIf

				lFirstSRE := .F.

				If lPrimeiro
					dDataSRE := SRE->RE_DATA


					If lMudEmpr
						cKeyEmp := SRE->RE_EMPP
					EndIf

					If lMudFilial
						cKeyFil := SRE->RE_FILIALP
					EndIf

					cKeyMat := SRE->RE_MATP
					cKeyCus := SRE->RE_CCP
					cKeyDep := SRE->RE_DEPTOP


					aAdd( aDadosTmp, { SRE->RE_DATA, dDataBase, SRE->RE_FILIALD, SRE->RE_MATD, SRE->RE_CCD, SRE->RE_EMPD, SRE->RE_DEPTOD } )
					_dFimPPP := SRE->RE_DATA


				ElseIf SRE->RE_DATA < aDadosTmp[Len( aDadosTmp )][1]

					dDataSRE := SRE->RE_DATA

					If lMudEmpr
						cKeyEmp := SRE->RE_EMPP
					EndIf

					If lMudFilial
						cKeyFil := SRE->RE_FILIALP
					EndIf

					cKeyMat := SRE->RE_MATP
					cKeyCus := SRE->RE_CCP
					cKeyDep := SRE->RE_DEPTOD
					aDadosTmp[Len( aDadosTmp )][1] := SRE->RE_DATA
					_dFimPPP := SRE->RE_DATA

				EndIf

				lPrimeiro := .F.

				// O funcionario esta mudando de Empresa/Filial, portanto, o processo para aqui
				lFimPPP := (SRE->RE_EMPP != cEmpPPP .And. !lMudEmpr ) .Or. (SRE->RE_EMPP+SRE->RE_FILIALP != cSvEmpAnt+cSvFilAnt .And. !lMudFilial)

				DBSelectArea( "SRE" )
				DBSkip()

			End

			If lPrimeiro
				lFimPPP := .T.

				If dINITMP < dFIMPPP
					aAdd( aDadosTmp, { dINITMP, dFIMPPP, cKeyFil, cKeyMat, cKeyCus, cKeyEmp, cKeyDep } )
				EndIf

			Else
				dFimPPP := _dFimPPP
			EndIf

		End

		If Len( aDadosTmp ) > 0
			aSRArea := SRA->(GetArea())
			cKeyEmp := aDadosTmp[Len( aDadosTmp ), 6] // Empresa origem
			cKeyFil := aDadosTmp[Len( aDadosTmp ), 3] // Filial origem
			cKeyMat := aDadosTmp[Len( aDadosTmp ), 4] // Matricula origem
			cKeyCus := aDadosTmp[Len( aDadosTmp ), 5] // Centro Custo origem
			cKeyDep := aDadosTmp[Len( aDadosTmp ), 7] // Departamento origem

			If lMudEmpr .And. cKeyEmp != cEmpPPP .And. !Empty( cKeyEmp )
				cModo := FWModeAccess( "SRA" )
				EMP700OPEN( "SRA", "SRA", 1, cKeyEmp, @cModo, SubStr( cKeyFil, 1, Len( SRA->RA_FILIAL ) ) )
			EndIf

			cModoSRA := f700RetCom( "SRA" )
			cFilSRA := FwxFilial( "SRA", SubStr( cKeyFil, 1, Len( SRA->RA_FILIAL ) ), SubStr( cModoSRA, 1, 1 ), SubStr( cModoSRA, 2, 1 ), SubStr( cModoSRA, 3, 1 ) )
			DBSelectArea( "SRA" )
			DBSetOrder( 1 )
			DBSeek( cFilSRA + cKeyMat )
			dFIMPPP   := IIf( Empty( SRA->RA_DEMISSA ), dDataBase, SRA->RA_DEMISSA ) // Data limite p/ uma transferencia
			dDtDemiss := IIf( Empty( SRA->RA_DEMISSA ), PPPDTDEMIS(), SRA->RA_DEMISSA ) //Busca data demissao do SRG
			lDemitido := !Empty( dDtDemiss )

			If lMudEmpr .And. cKeyEmp != cEmpPPP .And. !Empty( cKeyEmp )
				EMP700OPEN( "SRA", "SRA", 1, cEmpPPP, @cModo )
			EndIf

			FWRestArea( aSRArea )
		EndIf

	EndIf

	// Busca informações do funcionario quando transferido para outra empresa
	lFirstSRE := .T.
	lFimPPP   := .F.

	While !lFimPPP
		lPrimeiro := .T.
		_dFimPPP  := CToD( "  /  /  " )
		cCondCus  := cKeyCus
		cCondDep  := cKeyDep
		cCondALL  := cKeyEmp + cKeyFil + cKeyMat
		DBSelectArea( "SRE" )
		DBSetOrder( 2 )
		DBSeek( cCondALL )

		While !Eof() .And. cCondALL == SRE->RE_EMPP + SRE->RE_FILIALP + SRE->RE_MATP

			If SRE->RE_EMPP == SRE->RE_EMPD .And. SRE->RE_FILIALP == SRE->RE_FILIALD .And. ;
			   SRE->RE_MATP == SRE->RE_MATD .And. SRE->RE_CCP == SRE->RE_CCD .And. SRE->RE_DEPTOP == SRE->RE_DEPTOD
				DBSelectArea( "SRE" )
				DBSkip()
				Loop
			EndIf

			If (IIf( lFirstSRE, SRE->RE_DATA > dFIMPPP, SRE->RE_DATA >= dFIMPPP )) .Or. ;
				SRE->RE_DATA < dINITMP
				DBSelectArea( "SRE" )
				DBSkip()
				Loop
			EndIf

			If AllTrim( SRE->RE_CCP ) <> AllTrim( cCondCus ) .Or. ( AllTrim( SRE->RE_DEPTOP ) <> AllTrim( cCondDep ) )
				DBSelectArea( "SRE" )
				DBSkip()
				Loop
			EndIf

			lFirstSRE := .F.

			If lPrimeiro

				If lMudEmpr
					cKeyEmp := SRE->RE_EMPD
				EndIf

				If lMudFilial
					cKeyFil := SRE->RE_FILIALD
				EndIf

				cKeyMat := SRE->RE_MATD
				cKeyCus := SRE->RE_CCD
				cKeyDep := SRE->RE_DEPTOD

				If lVldMat //Caso o parâmetro exista no Pergunte
					If !lCurrBrnch .Or. AllTrim( xFilial( 'SRA' ) ) == AllTrim( SRE->RE_FILIALP )
						aAdd( aDadosPPP, { SRE->RE_DATA, dFimPPP, SRE->RE_FILIALP, SRE->RE_MATP, SRE->RE_CCP, SRE->RE_EMPP, SRE->RE_DEPTOP } )
					ElseIf lReutMat
						lUpdDates := .F.
					EndIf
				Else
					aAdd( aDadosPPP, { SRE->RE_DATA, dFimPPP, SRE->RE_FILIALP, SRE->RE_MATP, SRE->RE_CCP, SRE->RE_EMPP, SRE->RE_DEPTOP } )
				EndIf

				_dFimPPP := SRE->RE_DATA

			ElseIf SRE->RE_DATA > aDadosPPP[Len( aDadosPPP )][1]

				If lMudEmpr
					cKeyEmp := SRE->RE_EMPD
				EndIf

				If lMudFilial
					cKeyFil := SRE->RE_FILIALD
				EndIf

				cKeyMat := SRE->RE_MATD
				cKeyCus := SRE->RE_CCD
				cKeyDep := SRE->RE_DEPTOD
				aDadosPPP[Len( aDadosPPP )][1] := SRE->RE_DATA
				_dFimPPP := SRE->RE_DATA

			EndIf

			lPrimeiro := .F.

			// O funcionario esta mudando de Empresa/Filial, portanto, o processo para aqui
			lFimPPP := (SRE->RE_EMPD != cEmpPPP .And. !lMudEmpr) .Or. ;
					(SRE->RE_EMPD+SRE->RE_FILIALD != cSvEmpAnt+cSvFilAnt .And. !lMudFilial)
			DBSelectArea( "SRE" )
			DBSkip()

		End

		If lPrimeiro
			lFimPPP := .T.

			If dINITMP < dFimPPP
				aAdd( aDadosPPP, { dINITMP, dFimPPP, cKeyFil, cKeyMat, cKeyCus, cKeyEmp, cKeyDep } )
			EndIf

		Else
			dFimPPP := _dFimPPP
		EndIf

	End

	If Len( aDadosPPP ) == 0
		aAdd( aDadosPPP, { dINITMP, dFINALPPP, SRA->RA_FILIAL, SRA->RA_MAT, SRA->RA_CC, SM0->M0_CODIGO, SRA->RA_DEPTO } )
	EndIf

	// Busca pelas informações de função e cargo (SRA ou SR7) que serão utilizadas como referência na construção da TRB
	For nWWW := 1 To Len( aDadosPPP )
		cFilSR7 := SubStr( aDadosPPP[nWWW][3], 1, FwSizeFilial( aDadosPPP[nWWW][6] ) )

		If lMudEmpr .And. aDadosPPP[nWWW][6] != cEmpPPP
			cModo := FWModeAccess( "SR7" )
			EMP700OPEN( "SR7", "SR7", 1, aDadosPPP[nWWW][6], @cModo, cFilSR7 )
		EndIf

		cModoSR7 := f700RetCom( "SR7" )
		cXFilSR7 := FwxFilial( "SR7", cFilSR7, SubStr( cModoSR7, 1, 1 ), SubStr( cModoSR7, 2, 1 ), SubStr( cModoSR7, 3, 1 ) )
		lTemSR7 := .F.
		cSeqSR7 := "Z"
		DBSelectArea( "SR7" )
		DBSetOrder( 1 ) // R7_FILIAL + R7_MAT + DToS(R7_DATA) + R7_TIPO

		// Se não encontrar, pode ser devido a uma restrição criada na busca por transferências de filial/empresa
		If !DBSeek( cXFilSR7 + aDadosPPP[nWWW][4] + DToS( aDadosPPP[nWWW][1] ), .T. ) .And. (!lMudEmpr .Or. !lMudFilial)
			DBSkip( -1 ) // Volta um registro e verifica se ainda é do funcionário em questão

			If SR7->R7_MAT == aDadosPPP[nWWW][4]
				cFuncaoPPP := SR7->R7_FUNCAO
				cDesFunPPP := SR7->R7_DESCFUN

				If lCposSR7
					cCargoPPP  := SR7->R7_CARGO
					cDesCarPPP := SR7->R7_DESCCAR
				EndIf

				lTemSR7 := .T.
			EndIf

		Else

			While !Eof() .And. SR7->R7_FILIAL == cXFilSR7     .And. ;
							SR7->R7_MAT == aDadosPPP[nWWW][4] .And. ;
							SR7->R7_DATA <= aDadosPPP[nWWW][2]

				If SR7->R7_SEQ <= cSeqSR7
					cFuncaoPPP := SR7->R7_FUNCAO
					cDesFunPPP := SR7->R7_DESCFUN
					cSeqSR7    := SR7->R7_SEQ

					If lCposSR7
						cCargoPPP  := SR7->R7_CARGO
						cDesCarPPP := SR7->R7_DESCCAR
					EndIf

					lTemSR7 := .T.
				EndIf

				DBSelectArea( "SR7" )
				DBSkip()
			End

		EndIf

		If !lTemSR7 // Caso não ocorreu mudança de função (SR7) busca informações na função atual.
			DBSelectArea( "SRA" )
			DBSetOrder( 1 ) // RA_FILIAL + RA_MAT

			If DBSeek( xFilial( "SRA", SubStr( aDadosPPP[nWWW][3], 1, FwSizeFilial() ) )  + aDadosPPP[nWWW, 4] )
				cFuncaoPPP	:= SRA->RA_CODFUNC
				cDesFunPPP	:= Posicione( "SRJ", 1, xFilial( "SRJ" ) + cFuncaoPPP, "RJ_DESC" )

				If lCposSR7 // Caso tenha Cargo na SRA
					cCargoPPP := SRA->RA_CARGO
				Else // Caso contrário busca o cargo da Função
					cCargoPPP := Posicione( "SRJ", 1, xFilial( "SRJ" ) + cFuncaoPPP, "RJ_CARGO" )
				EndIf

				cDesCarPPP	:= Posicione( "SQ3", 1, xFilial( "SQ3" ) + cCargoPPP, "Q3_DESCSUM" )
			EndIf

		EndIf

		If lMudEmpr .And. aDadosPPP[nWWW][6] != cEmpPPP
			EMP700OPEN( "SR7", "SR7", 1, cEmpPPP, @cModo )
		EndIf

	Next nWWW

	lAchouSRE := .F.
	aSRArea := SRA->(GetArea())

	For nXYZ := Len( aDadosPPP ) To 1 Step -1

		If nXYZ != Len( aDadosPPP )
			cFunAnter := cFuncaoPPP

			If lCposSR7
				cCarAnter := cCargoPPP
			EndIf

		Else
			cFunAnter := Space( 5 )

			If lCposSR7
				cCarAnter := Space( 5 )
			EndIf

		EndIf

		cFilMat := SubStr( aDadosPPP[nXYZ][3], 1, FwSizeFilial( aDadosPPP[nXYZ][6] ) )

		If (aScan( aMatriculas, { |x| x[1] + x[2] + x[3] == cFilMat+aDadosPPP[nXYZ][4] + aDadosPPP[nXYZ][6] } )) <= 0
			aAdd( aMatriculas, { cFilMat, aDadosPPP[nXYZ][4], aDadosPPP[nXYZ][6] } ) // MAtriculas Utilizadas pelo funcionario na empresa
		EndIf

		aAreaAtual := {}
		aAreaVelha := {}
		dDtTermino := CtoD( "  /  /    " )
		lAchou     := .T.
		lInicio    := .T.
		lFirst     := .T.

		If lMudEmpr .And. aDadosPPP[nXYZ][6] != cEmpPPP
			cModo := FWModeAccess( "SR7" )
			EMP700OPEN( "SR7", "SR7", 1, aDadosPPP[nXYZ][6], @cModo, cFilMat )
			cModo := FWModeAccess( "SRJ" )
			EMP700OPEN( "SRJ", "SRJ", 1, aDadosPPP[nXYZ][6], @cModo, cFilMat )
			cModo := FWModeAccess( "SQ3" )
			EMP700OPEN( "SQ3", "SQ3", 1, aDadosPPP[nXYZ][6], @cModo, cFilMat )
		EndIf

		cModoSR7 := f700RetCom( "SR7" )
		cXFilSR7 := FwxFilial( "SR7", cFilMat, SubStr( cModoSR7, 1, 1 ), SubStr( cModoSR7, 2, 1 ), SubStr( cModoSR7, 3, 1 ) )

		cModoSRJ := f700RetCom( "SRJ" )
		cXFilSRJ := FwxFilial( "SRJ", cFilMat, SubStr( cModoSRJ, 1, 1 ), SubStr( cModoSRJ, 2, 1 ), SubStr( cModoSRJ, 3, 1 ) )

		cModoSQ3 := f700RetCom( "SQ3" )
		cXFilSQ3 := FwxFilial( "SQ3", cFilMat, SubStr( cModoSQ3, 1, 1 ), SubStr( cModoSQ3, 2, 1 ), SubStr( cModoSQ3, 3, 1 ) )

		DBSelectArea( "SR7" )
		DBSetOrder( 1 )
		DBSeek( cFilMat + aDadosPPP[nXYZ][4] + DToS( aDadosPPP[nXYZ][1] ), .T. )

		While !Eof() .And. cFilMat+aDadosPPP[nXYZ][4] == SR7->R7_FILIAL+SR7->R7_MAT .And.;
			  (IIf( nXYZ != 1, SR7->R7_DATA < aDadosPPP[nXYZ][2], SR7->R7_DATA <= aDadosPPP[nXYZ][2] ))

			cCNPJ := Space( 10 )
			nTIPINS := 2
			aAreaEMP := SM0->( FWGetArea() )

			If lNGMDTPS .Or. lSigaMdtps

				If lMudEmpr .And. aDadosPPP[nXYZ][6] != cEmpPPP
					cModo := FWModeAccess( "SA1" )
					EMP700OPEN( "SA1", "SA1", 1, aDadosPPP[nXYZ][6], @cModo, cFilMat )
				EndIf

				cModoSA1 := f700RetCom( "SA1" )
				cXFilSA1 := FwxFilial( "SA1", cFilMat, SubStr( cModoSA1, 1, 1 ), SubStr( cModoSA1, 2, 1 ), SubStr( cModoSA1, 3, 1 ) )

				DBSelectArea( "SA1" )
				DBSetOrder( 1 )
				DBSeek( cXFilSA1 + SubStr( aDadosPPP[nXYZ][5], 1, nSizeTD ) )
				cCNPJ := SA1->A1_CGC

				If lMudEmpr .And. aDadosPPP[nXYZ][6] != cEmpPPP
					EMP700OPEN( "SA1", "SA1", 1, cEmpPPP, @cModo )
				EndIf
			Else
				DBSelectArea( "SM0" )
				DBSeek( aDadosPPP[nXYZ][6] + cFilMat )
				cCNPJ := SM0->M0_CGC
				nTIPINS := SM0->M0_TPINSC
			EndIf

			FWRestArea( aAreaEMP )

			DBSelectArea( "SRJ" )
			DBSetOrder( 1 )
			DBSeek( cXFilSRJ + SR7->R7_FUNCAO )

			DBSelectArea( "SQ3" )
			DBSetOrder( 1 )
			DBSeek( cXFilSQ3 + IIf( lCposSR7, SR7->R7_CARGO, SRJ->RJ_CARGO ) )

			DBSelectArea( cTRBPPP )
			DBSetOrder( 1 )

			If (SR7->R7_FUNCAO != cFunAnter .Or. IIf( lCposSR7, SR7->R7_CARGO != cCarAnter, .F. ))
				lAchouSRE := .T.
				RecLock( cTRBPPP, .T. )
					(cTRBPPP)->DTDE   := SR7->R7_DATA
					(cTRBPPP)->DTATE  := aDadosPPP[nXYZ][2]
					(cTRBPPP)->CNPJ   := cCNPJ
					(cTRBPPP)->TIPINS := nTIPINS
					(cTRBPPP)->SEQ    := SR7->R7_SEQ
					(cTRBPPP)->FILIAL := cFilMat
					(cTRBPPP)->MAT    := aDadosPPP[nXYZ][4]
					(cTRBPPP)->CUSTO  := aDadosPPP[nXYZ][5]
					(cTRBPPP)->DEPTO  := aDadosPPP[nXYZ][7]
					(cTRBPPP)->EMP    := aDadosPPP[nXYZ][6]
					(cTRBPPP)->CARGO  := IIf( lCposSR7, SR7->R7_CARGO, SRJ->RJ_CARGO )
					(cTRBPPP)->CODFUN := SR7->R7_FUNCAO

					If !Empty( SR7->R7_DESCFUN ) .And. (Len( AllTrim( SRJ->RJ_DESC ) ) <= 25 .Or. Len( AllTrim( SR7->R7_DESCFUN ) ) > 25)
						(cTRBPPP)->DESFUN := SR7->R7_DESCFUN
					Else
						(cTRBPPP)->DESFUN := SRJ->RJ_DESC
					EndIf

					If lCposSR7

						If !Empty( SR7->R7_DESCCAR ) .And. (Len( AllTrim( SQ3->Q3_DESCSUM ) ) <= 25 .Or. Len( AllTrim( SR7->R7_DESCCAR ) ) > 25)
							(cTRBPPP)->DESCAR := SR7->R7_DESCCAR
						Else
							(cTRBPPP)->DESCAR := SQ3->Q3_DESCSUM
						EndIf

					EndIf

				(cTRBPPP)->( MSUnLock())
				cFunAnter := SR7->R7_FUNCAO

				If lCposSR7
					cCarAnter := SR7->R7_CARGO
				EndIf

			Else
				DBSelectArea( "SR7" )
				DBSkip()
				Loop
			EndIf

			//Guarda ultimo registro do arquivo de trabalho cTRBPPP. Para alterar a data fim no proximo laco.
			aAreaAtual := (cTRBPPP)->(GetArea())
			cFuncaoFOR := SR7->R7_FUNCAO
			cDesFunFOR := SR7->R7_DESCFUN

			If lCposSR7
				cCargoFOR  := SR7->R7_CARGO
				cDesCarFOR := SR7->R7_DESCCAR
			EndIf

			dDtTermino := SR7->R7_DATA // Variavel para alterar a data fim do registro anterior
			cSeqTabR7  := (cTRBPPP)->SEQ

			lVelha := .T.

			If lFirst // Se For a primeira vez que entrou no laco
				dDataFOR := SR7->R7_DATA
				lFirst := .F.
			Else
				FWRestArea( aAreaVelha )

				If !Eof() .And. !Bof()

					If dDtTermino == (cTRBPPP)->DTDE .And. (cTRBPPP)->SEQ > cSeqTabR7
						cFunAnter := (cTRBPPP)->CODFUN

						If lCposSR7
							cCarAnter := (cTRBPPP)->CARGO
						EndIf

						FWRestArea( aAreaAtual )
						lVelha := .F.
					EndIf

					RecLock( cTRBPPP, .F. )
						(cTRBPPP)->DTATE  := dDtTermino //Altera a data fim do registro anterior
					(cTRBPPP)->( MSUnLock())
				EndIf

				FWRestArea( aAreaAtual )
			EndIf

			If lVelha
				aAreaVelha := (cTRBPPP)->(GetArea())
			EndIf

			// Variavel de controle. Para saber se existe mudanca de funcao no comeco da transferencia
			If aDadosPPP[nXYZ][1] == SR7->R7_DATA
				lInicio := .F.
			EndIf

			// Variavel de controle. Para saber se houve mudanca de funcao
			lAchou := .F.

			DBSelectArea( "SR7" )
			DBSkip()
		End

		// Verifica se existe registro do funcionário na SRE
		aAreaSRE := SRE->(GetArea())
		DBSelectArea( "SRE" )
		DBSetOrder( 2 )

		If DBSeek( cCondAll )
			lAchouSRE := .T.
		EndIf

		FWRestArea( aAreaSRE )

		If lMudEmpr .And. aDadosPPP[nXYZ][6] != cEmpPPP
			EMP700OPEN( "SR7", "SR7", 1, cEmpPPP, @cModo )
			EMP700OPEN( "SQ3", "SQ3", 1, cEmpPPP, @cModo )
		EndIf

		If lAchou // Se nao achou nenhuma mudanca de funcao
			cCNPJ := Space( 10 )
			nTIPINS := 2
			aAreaEMP := SM0->(GetArea())

			If lNGMDTPS .Or. lSigaMdtps

				If lMudEmpr .And. aDadosPPP[nXYZ][6] != cEmpPPP
					cModo := FWModeAccess( "SA1" )
					EMP700OPEN( "SA1", "SA1", 1, aDadosPPP[nXYZ][6], @cModo, cFilMat )
				EndIf

				cModoSA1 := f700RetCom( "SA1" )
				cXFilSA1 := FwxFilial( "SA1", cFilMat, SubStr( cModoSA1, 1, 1 ), SubStr( cModoSA1, 2, 1 ), SubStr( cModoSA1, 3, 1 ) )

				DBSelectArea( "SA1" )
				DBSetOrder( 1 )
				DBSeek( cXFilSA1 + SubStr( aDadosPPP[nXYZ][5], 1, nSizeTD ) )
				cCNPJ := SA1->A1_CGC

				If lMudEmpr .And. aDadosPPP[nXYZ][6] != cEmpPPP
					EMP700OPEN( "SA1", "SA1", 1, cEmpPPP, @cModo )
				EndIf

			Else
				DBSelectArea( "SM0" )
				DBSeek( aDadosPPP[nXYZ][6] + cFilMat )
				cCNPJ := SM0->M0_CGC
				nTIPINS := SM0->M0_TPINSC
			EndIf

			FWRestArea( aAreaEMP )

			DBSelectArea( "SRJ" )
			DBSetOrder( 1 )
			DBSeek( cXFilSRJ + cFuncaoPPP )

			DBSelectArea( "SQ3" )
			DBSetOrder( 1 )
			DBSeek( cXFilSQ3 + IIf( lCposSR7, cCargoPPP, SRJ->RJ_CARGO ) )

			DBSelectArea( cTRBPPP )
			DBSetOrder( 1 )

			If !DBSeek( DToS( aDadosPPP[nXYZ][1] ) )
				RecLock( cTRBPPP, .T. )
					(cTRBPPP)->DTDE   := aDadosPPP[nXYZ][1]
					(cTRBPPP)->DTATE  := aDadosPPP[nXYZ][2]
					(cTRBPPP)->CNPJ   := cCNPJ
					(cTRBPPP)->TIPINS := nTIPINS
					(cTRBPPP)->CUSTO  := aDadosPPP[nXYZ][5]
					(cTRBPPP)->DEPTO  := aDadosPPP[nXYZ][7]
					(cTRBPPP)->FILIAL := cFilMat
					(cTRBPPP)->EMP    := aDadosPPP[nXYZ][6]
					(cTRBPPP)->MAT    := aDadosPPP[nXYZ][4]
					(cTRBPPP)->CARGO  := IIf( lCposSR7, cCargoPPP, SRJ->RJ_CARGO )
					(cTRBPPP)->CODFUN := cFuncaoPPP

					If !Empty( SRJ->RJ_DESC )
						(cTRBPPP)->DESFUN := SRJ->RJ_DESC
					Else
						(cTRBPPP)->DESFUN := cDesFunPPP
					EndIf

					If lCposSR7

						If !Empty( SQ3->Q3_DESCSUM )
							(cTRBPPP)->DESCAR := SQ3->Q3_DESCSUM
						Else
							(cTRBPPP)->DESCAR := cDesCarPPP
						EndIf

					EndIf

					cFuncaoFOR := cFuncaoPPP
					cDesFunFOR := cDesFunPPP

					If lCposSR7
						cCargoFOR  := IIf( lCposSR7, cCargoPPP, SRJ->RJ_CARGO )
						cDesCarFOR := (cTRBPPP)->DESCAR
					EndIf

				(cTRBPPP)->( MSUnLock())
			EndIf

		ElseIf lInicio // Se nao achou nenhuma mudanca de funcao no inicio da mudanca de setor
			cCNPJ := Space( 10 )
			nTIPINS := 2
			aAreaEMP := SM0->(GetArea())

			If lNGMDTPS .Or. lSigaMdtps

				If lMudEmpr .And. aDadosPPP[nXYZ][6] != cEmpPPP
					cModo := FWModeAccess( "SA1" )
					EMP700OPEN( "SA1", "SA1", 1, aDadosPPP[nXYZ][6], @cModo, cFilMat )
				EndIf

				cModoSA1 := f700RetCom( "SA1" )
				cXFilSA1 := FwxFilial( "SA1", cFilMat, SubStr( cModoSA1, 1, 1 ), SubStr( cModoSA1, 2, 1 ), SubStr( cModoSA1, 3, 1 ) )

				DBSelectArea( "SA1" )
				DBSetOrder( 1 )
				DBSeek( cXFilSA1 + SubStr( aDadosPPP[nXYZ][5], 1, nSizeTD ) )
				cCNPJ := SA1->A1_CGC

				If lMudEmpr .And. aDadosPPP[nXYZ][6] != cEmpPPP
					EMP700OPEN( "SA1", "SA1", 1, cEmpPPP, @cModo )
				EndIf

			Else
				DBSelectArea( "SM0" )
				DBSeek( aDadosPPP[nXYZ][6] + cFilMat )
				cCNPJ := SM0->M0_CGC
				nTIPINS := SM0->M0_TPINSC
			EndIf

			FWRestArea( aAreaEMP )

			DBSelectArea( "SRJ" )
			DBSetOrder( 1 )
			DBSeek( cXFilSRJ + cFuncaoPPP )

			DBSelectArea( "SQ3" )
			DBSetOrder( 1 )
			DBSeek( cXFilSQ3 + IIf( lCposSR7, cCargoPPP, SRJ->RJ_CARGO ) )

			DBSelectArea( cTRBPPP )
			DBSetOrder( 1 )

			If !DBSeek( DToS( aDadosPPP[nXYZ][1] ) )
				RecLock( cTRBPPP, .T. )
					(cTRBPPP)->DTDE   := aDadosPPP[nXYZ][1]
					(cTRBPPP)->DTATE  := dDataFOR
					(cTRBPPP)->CNPJ   := cCNPJ
					(cTRBPPP)->TIPINS := nTIPINS
					(cTRBPPP)->CUSTO  := aDadosPPP[nXYZ][5]
					(cTRBPPP)->DEPTO  := aDadosPPP[nXYZ][7]
					(cTRBPPP)->FILIAL := cFilMat
					(cTRBPPP)->EMP    := aDadosPPP[nXYZ][6]
					(cTRBPPP)->MAT    := aDadosPPP[nXYZ][4]
					(cTRBPPP)->CARGO  := IIf( lCposSR7, cCargoPPP, SRJ->RJ_CARGO )
					(cTRBPPP)->CODFUN := cFuncaoPPP

					If !Empty( SRJ->RJ_DESC )
						(cTRBPPP)->DESFUN := SRJ->RJ_DESC
					Else
						(cTRBPPP)->DESFUN := cDesFunPPP
					EndIf

					If lCposSR7

						If !Empty( SQ3->Q3_DESCSUM )
							(cTRBPPP)->DESCAR := SQ3->Q3_DESCSUM
						Else
							(cTRBPPP)->DESCAR := cDesCarPPP
						EndIf

					EndIf

				(cTRBPPP)->( MSUnLock())
			EndIf

		EndIf

		cFuncaoPPP := cFuncaoFOR
		cDesFunPPP := cDesFunFOR

		If lCposSR7
			cCargoPPP  := cCargoFOR
			cDesCarPPP := cDesCarFOR
		EndIf

		If lMudEmpr .And. aDadosPPP[nXYZ][6] != cEmpPPP
			EMP700OPEN( "SRJ", "SRJ", 1, cEmpPPP, @cModo )
		EndIf

	Next

	FWRestArea( aSRArea )

	If !lAchouSRE

		Begin Sequence
			DBSelectArea( "SRJ" )
			DBSetOrder( 1 )

			If DBSeek( xFilial( "SRJ" ) + cRA_CODFUNC )

				If lCposSR7
					DBSelectArea( "SQ3" )
					DBSetOrder( 1 )
					DBSeek( xFilial( "SQ3" ) + cRA_CARGO )
				EndIf

				DBSelectArea( cTRBPPP )
				DBGoTop()

				While !Eof()
					RecLock( cTRBPPP, .F. )
						(cTRBPPP)->CODFUN := cRA_CODFUNC
						(cTRBPPP)->DESFUN := SRJ->RJ_DESC
						(cTRBPPP)->CARGO  := SRJ->RJ_CARGO

						If lCposSR7
							(cTRBPPP)->CARGO  := cRA_CARGO
							(cTRBPPP)->DESCAR := SQ3->Q3_DESCSUM
						EndIf

					(cTRBPPP)->( MSUnLock())
					DBSkip()
				End

				Break
			EndIf

			For nBeg := Len( aMatriculas ) To 1 step -1

				If lMudEmpr .And. aMatriculas[nBeg][3] != cEmpPPP
					cModo := FWModeAccess( "SRJ" )
					EMP700OPEN( "SRJ", "SRJ", 1, aMatriculas[nBeg][3], @cModo, aMatriculas[nBeg][1] )
				EndIf

				DBSelectArea( "SRJ" )
				DBSetOrder( 1 )

				If DBSeek( xFilial( "SRJ", aMatriculas[nBeg, 1] ) + cRA_CODFUNC )
					DBSelectArea( cTRBPPP )
					DBGoTop()

					While !Eof()
						RecLock( cTRBPPP, .F. )
							(cTRBPPP)->CODFUN := cRA_CODFUNC
							(cTRBPPP)->DESFUN := SRJ->RJ_DESC
							(cTRBPPP)->CARGO  := SRJ->RJ_CARGO
						(cTRBPPP)->( MSUnLock())
						DBSkip()
					End

					Break
				EndIf

				If lMudEmpr .And. aMatriculas[nBeg][3] != cEmpPPP
					EMP700OPEN( "SRJ", "SRJ", 1, cEmpPPP, @cModo )
				EndIf

			Next nBeg

		End Sequence

	EndIf

	If xm_par12 == 1 .Or. (xm_par12 == 2 .And. !Empty( dDatacorte ))//Somente a partir JAN/2004 ?
		lDelBK := .F.
		DBSelectArea( cTRBPPP )
		DBSetOrder( 1 )
		DBSeek( DToS( dINIPPP ), .T. )

		If dINIPPP == (cTRBPPP)->DTDE
			lDelBK := .T.
		Else
			DBSkip( -1 )

			If !Eof() .And. !Bof() .And. dINIPPP > (cTRBPPP)->DTDE
				lDelBK := .T.
				RecLock( cTRBPPP, .F. )
					(cTRBPPP)->DTDE := dINIPPP
				(cTRBPPP)->( MSUnLock())
			EndIf

		EndIf

		If lDelBK
			DBSelectArea( cTRBPPP )
			DBGoTop()

			While !Eof()

				If (cTRBPPP)->DTDE < dINIPPP
					RecLock( cTRBPPP, .F. )
						dbDelete()
					(cTRBPPP)->( MSUnLock())
				EndIf

				DBSkip()
			End

		EndIf

	EndIf

	nRegPPP  := 0
	cGFIPant := "  "
	lGfipAll := .F. // Se achou alguma alteracao de GFIP

	DBSelectArea( cTRBPPP )
	nTotRegPPP := (cTRBPPP)->(RecCount())
	DBSetOrder( 1 )
	DBGoTop()

	While !Eof()

		If !Empty( (cTRBPPP)->GFIP )
			DBSelectArea( cTRBPPP )
			DBSkip()
			Loop
		EndIf

		aAreaSv := (cTRBPPP)->(GetArea())
		aAreaAnt := {}
		lAchou := .F.
		nRegPPP++
		cFilSR9 := SubStr( (cTRBPPP)->FILIAL, 1, FwSizeFilial( (cTRBPPP)->EMP ) )

		If lMudEmpr .And. (cTRBPPP)->EMP != cEmpPPP
			cModo := FWModeAccess( "SR9" )
			EMP700OPEN( "SR9", "SR9", 1, (cTRBPPP)->EMP, @cModo, cFilSR9 )
		EndIf

		cModoSR9 := f700RetCom( "SR9" )
		cXFilSR9 := FwxFilial( "SR9", cFilSR9, SubStr( cModoSR9, 1, 1 ), SubStr( cModoSR9, 2, 1 ), SubStr( cModoSR9, 3, 1 ) )

		cChavePPP := cXFilSR9+(cTRBPPP)->MAT
		svDTDE    := (cTRBPPP)->DTDE
		svDTATE   := (cTRBPPP)->DTATE

		DBSelectArea( "SR9" )
		DBSetOrder( 1 )
		DBSeek( cXFilSR9 + (cTRBPPP)->MAT + "RA_OCORREN" )

		While !Eof() .And. cChavePPP == SR9->R9_FILIAL+SR9->R9_MAT .And.;
			"RA_OCORREN" == SR9->R9_CAMPO

			aAreaSR9 := ( "SR9" )->(GetArea())

				// Validação para pegar o ultimo código antes de 01/01/2004
				// e adicionar no TRB do GFIP
				If xm_par12 == 1 .And. lEntra
					DBSelectArea( "SR9" ) // Feito posicionamento para trazer as datas corretas
					DBSetOrder( 2 ) // R9_FILIAL + R9_MAT + DToS(R9_DATA) + R9_CAMPO
					DBSeek( xFilial( "SR9" ) + SRA->RA_MAT )
					lEntra := .F.

					While !Eof() .And. xFilial( "SR9" ) == SR9->R9_FILIAL

						If SR9->R9_DATA < CTOD( "01/01/2004" )
							cGFIP := AllTrim( SR9->R9_DESC ) // Ultimo código recebido antes de 01/01/2004
							DBSelectArea( "SR9" )
							DBSkip()
						Else
							Exit
						EndIf

					End

				EndIf

			FWRestArea( aAreaSR9 )

			If svDTDE > SR9->R9_DATA .Or. svDTATE <= SR9->R9_DATA
				DBSelectArea( "SR9" )
				DBSkip()
				Loop
			EndIf

			tmpDTDE   := (cTRBPPP)->DTDE
			tmpDTATE  := (cTRBPPP)->DTATE
			tmpCNPJ   := (cTRBPPP)->CNPJ
			tmpTIPINS := (cTRBPPP)->TIPINS
			tmpCUSTO  := (cTRBPPP)->CUSTO
			tmpDEPTO  := (cTRBPPP)->DEPTO
			tmpFILIAL := (cTRBPPP)->FILIAL
			tmpMAT    := (cTRBPPP)->MAT
			tmpCARGO  := (cTRBPPP)->CARGO
			tmpCODFUN := (cTRBPPP)->CODFUN
			tmpDESFUN := (cTRBPPP)->DESFUN
			tmpEMP    := (cTRBPPP)->EMP

			lInsertTRB := .F.
			DBSelectArea( cTRBPPP )

			If !lAchou

				If (cTRBPPP)->DTDE >= SR9->R9_DATA-5
					RecLock( cTRBPPP, .F. )
						(cTRBPPP)->GFIP  := AllTrim( SR9->R9_DESC )
					(cTRBPPP)->( MSUnLock())
				Else
					RecLock( cTRBPPP, .F. )
						(cTRBPPP)->DTATE := SR9->R9_DATA
						(cTRBPPP)->GFIP  := IIf( !Empty( cGFIP ), cGFIP, cGFIPant )
					(cTRBPPP)->( MSUnLock())
					lInsertTRB := .T.
				EndIf

			Else
				lInsertTRB := .T.
				FWRestArea( aAreaAnt )
				RecLock( cTRBPPP, .F. )
					(cTRBPPP)->DTATE := SR9->R9_DATA
				(cTRBPPP)->( MSUnLock())
			EndIf

			If lInsertTRB
				RecLock( cTRBPPP, .T. )
					(cTRBPPP)->DTDE   := SR9->R9_DATA
					(cTRBPPP)->DTATE  := tmpDTATE
					(cTRBPPP)->CNPJ   := tmpCNPJ
					(cTRBPPP)->TIPINS := tmpTIPINS
					(cTRBPPP)->CUSTO  := tmpCUSTO
					(cTRBPPP)->DEPTO  := tmpDEPTO
					(cTRBPPP)->FILIAL := tmpFILIAL
					(cTRBPPP)->MAT    := tmpMAT
					(cTRBPPP)->CARGO  := tmpCARGO
					(cTRBPPP)->CODFUN := tmpCODFUN
					(cTRBPPP)->DESFUN := tmpDESFUN
					(cTRBPPP)->EMP    := tmpEMP
					(cTRBPPP)->GFIP   := AllTrim( SR9->R9_DESC )
				(cTRBPPP)->( MSUnLock())
			EndIf

			aAreaAnt := (cTRBPPP)->(GetArea())

			lAchou     := .T. //Controle p/ ver se houve alguma alteracao de GFIP em cada periodo de trabalho
			lGfipAll   := .T.
			cGFIPant   := AllTrim( SR9->R9_DESC )

			DBSelectArea( "SR9" )
			DBSkip()
		End

		FWRestArea( aAreaSv )

		If lMudEmpr .And. (cTRBPPP)->EMP != cEmpPPP
			EMP700OPEN( "SR9", "SR9", 1, cEmpPPP, @cModo )
		EndIf

		DBSelectArea( cTRBPPP )

		If !lAchou
			RecLock( cTRBPPP, .F. )
				(cTRBPPP)->GFIP := cGFIPant
			(cTRBPPP)->( MSUnLock())
		EndIf

		FWRestArea( aAreaSv )
		DBSelectArea( cTRBPPP )
		DBSkip()
	End

	DBSelectArea( cTRBPPP )
	DBSetOrder( 1 )
	DBGoTop()

	While !Eof()

		If Empty( (cTRBPPP)->GFIP ) .Or. (cTRBPPP)->GFIP == "00"

			If lMudEmpr .And. (cTRBPPP)->EMP != cEmpPPP
				cModo := FWModeAccess( cAlias )
				EMP700OPEN( cAlias, cAlias, 1, (cTRBPPP)->EMP, @cModo, SubStr( (cTRBPPP)->FILIAL, 1, FwSizeFilial( (cTRBPPP)->EMP ) ) )
			EndIf

			cModoCTT := f700RetCom( cAlias )
			cXFilCTT := FwxFilial( cAlias, SubStr( (cTRBPPP)->FILIAL, 1, FwSizeFilial( (cTRBPPP)->EMP ) ), SubStr( cModoCTT, 1, 1 ),;
				 SubStr( cModoCTT, 2, 1 ), SubStr( cModoCTT, 3, 1 ) )

			DBSelectArea( cAlias )
			DBSetOrder( 1 )

			If DBSeek( cXFilCTT + (cTRBPPP)->CUSTO )

				If cAlias == "SI3"

					If !Empty( SI3->I3_OCORREN )
						DBSelectArea( cTRBPPP )
						RecLock( cTRBPPP, .F. )
							(cTRBPPP)->GFIP := SI3->I3_OCORREN
						(cTRBPPP)->( MSUnLock())
					EndIf

				ElseIf !Empty( CTT->CTT_OCORRE )
					DBSelectArea( cTRBPPP )
					RecLock( cTRBPPP, .F. )
						(cTRBPPP)->GFIP := CTT->CTT_OCORRE
					(cTRBPPP)->( MSUnLock())
				EndIf

			EndIf

			If lMudEmpr .And. ( cTRBPPP )->EMP != cEmpPPP
				EMP700OPEN( cAlias, cAlias, 1, cEmpPPP, @cModo )
			EndIf

			If !Empty( SRA->RA_OCORREN ) .And. (Empty( (cTRBPPP)->GFIP ) .Or. (cTRBPPP)->GFIP == "00" ) .And. !lGfipAll
				RecLock( cTRBPPP, .F. )
					(cTRBPPP)->GFIP := SRA->RA_OCORREN
				(cTRBPPP)->( MSUnLock())
			EndIf

		EndIf

		DBSelectArea( cTRBPPP )
		DBSkip()
	End

	DBSelectArea( cTRBPPP )
	DBSetOrder( 1 )
	DBGoTop()

	While !Eof() .And. lUpdDates
		aAreaTmp := (cTRBPPP)->(GetArea())
		dDtFimsv := CTOD( "  /  /  " )
		svPPPchv := (cTRBPPP)->CNPJ+Str( (cTRBPPP)->TIPINS, 1 ) + (cTRBPPP)->CUSTO + (cTRBPPP)->DEPTO + (cTRBPPP)->FILIAL + (cTRBPPP)->MAT+;
					(cTRBPPP)->CARGO + (cTRBPPP)->CODFUN + (cTRBPPP)->DESFUN + (cTRBPPP)->EMP + (cTRBPPP)->GFIP
		DBSkip()

		If !Eof()
			DBSelectArea( cTRBPPP )
			While !Eof() .And.;
				svPPPchv == (cTRBPPP)->CNPJ+Str( (cTRBPPP)->TIPINS, 1 )+(cTRBPPP)->CUSTO+(cTRBPPP)->DEPTO+(cTRBPPP)->FILIAL+;
				(cTRBPPP)->MAT+(cTRBPPP)->CARGO+(cTRBPPP)->CODFUN+(cTRBPPP)->DESFUN+(cTRBPPP)->EMP+(cTRBPPP)->GFIP

				If dDtFimsv < (cTRBPPP)->DTATE
					dDtFimsv := (cTRBPPP)->DTATE
				EndIf

				RecLock( cTRBPPP, .F. )
					dbDelete()
				(cTRBPPP)->( MSUnLock())
				DBSelectArea( cTRBPPP )
				DBSkip()
			End

			If !Empty( dDtFimsv )
				FWRestArea( aAreaTmp )
				RecLock( cTRBPPP, .F. )
					(cTRBPPP)->DTATE := dDtFimsv
				(cTRBPPP)->( MSUnLock())
			EndIf

		EndIf

		FWRestArea( aAreaTmp )
		DBSelectArea( cTRBPPP )
		DBSkip()
	End

	lTroca    := .T.
	cTrocaFun := " "
	// Executa os historicos
	DBSelectArea( cTRBPPP )
	Pack

	nRegTRB := (cTRBPPP)->(RecCount())
	nConTRB := 0
	DBGoTop()

	While !Eof()
		nConTRB++

		If nConTRB > 1

			If cFilTNF != (cTRBPPP)->EMP+(cTRBPPP)->FILIAL
				dDtTransf := (cTRBPPP)->DTDE
				cFilTNF   := (cTRBPPP)->EMP+(cTRBPPP)->FILIAL
			EndIf

		Else
			cFilTNF := (cTRBPPP)->EMP+(cTRBPPP)->FILIAL
		EndIf

		cFilFichas := SubStr( (cTRBPPP)->FILIAL, 1, FwSizeFilial( (cTRBPPP)->EMP ) )

		If lMudEmpr .And. (cTRBPPP)->EMP != cEmpPPP
			cModo := FWModeAccess( "TM0" )
			EMP700OPEN( "TM0", "TM0", 1, (cTRBPPP)->EMP, @cModo, cFilFichas )
			cModo := FWModeAccess( "SRJ" )
			EMP700OPEN( "SRJ", "SRJ", 1, ( cTRBPPP )->EMP, @cModo, cFilFichas )
			cModo := FWModeAccess( "SQ3" )
			EMP700OPEN( "SQ3", "SQ3", 1, ( cTRBPPP )->EMP, @cModo, cFilFichas )
			cModo := FWModeAccess( cAlias )
			EMP700OPEN( cAlias, cAlias, 1, ( cTRBPPP )->EMP, @cModo, cFilFichas )
		EndIf

		cModoTM0 := f700RetCom( "TM0" )
		cXFilTM0 := FwxFilial( "TM0", cFilFichas, SubStr( cModoTM0, 1, 1 ), SubStr( cModoTM0, 2, 1 ), SubStr( cModoTM0, 3, 1 ) )

		cModoSRA := f700RetCom( "SRA" )
		cXFilSRA := FwxFilial( "SRA", cFilFichas, SubStr( cModoSRA, 1, 1 ), SubStr( cModoSRA, 2, 1 ), SubStr( cModoSRA, 3, 1 ) )

		cModoSRJ := f700RetCom( "SRJ" )
		cXFilSRJ := FwxFilial( "SRJ", cFilFichas, SubStr( cModoSRJ, 1, 1 ), SubStr( cModoSRJ, 2, 1 ), SubStr( cModoSRJ, 3, 1 ) )

		cModoSQ3 := f700RetCom( "SQ3" )
		cXFilSQ3 := FwxFilial( "SQ3", cFilFichas, SubStr( cModoSQ3, 1, 1 ), SubStr( cModoSQ3, 2, 1 ), SubStr( cModoSQ3, 3, 1 ) )

		cModoCTT := f700RetCom( cAlias )
		cXFilCTT := FwxFilial( cAlias, cFilFichas, SubStr( cModoCTT, 1, 1 ), SubStr( cModoCTT, 2, 1 ), SubStr( cModoCTT, 3, 1 ) )

		If (cTRBPPP)->DTDE == (cTRBPPP)->DTATE
			dDateAte := (cTRBPPP)->DTATE
		Else
            // No caso de demissão real, deve-se utilizar a mesma data, do contrário, subtrair um dia 
			dDateAte := ( cTRBPPP )->DTATE - IIf( nRegTRB == nConTRB, 0, 1 )
		EndIf

		DBSelectArea( "TM0" )
		DBSetOrder( 3 )

		If DBSeek( cXFilSRA + (cTRBPPP)->MAT )

			If (aScan( aFichasUsa, { |x| x[5] + x[1] + x[2] + DToS( x[3] ) + DToS( x[4] ) == (cTRBPPP)->EMP + cFilFichas +;
				 TM0->TM0_NUMFIC + DToS( (cTRBPPP)->DTDE ) + DToS( dDateAte ) } ) ) <= 0
				aAdd( aFichasUsa, { cFilFichas, TM0->TM0_NUMFIC, (cTRBPPP)->DTDE, dDateAte, (cTRBPPP)->EMP } )//Fichas Utilizadas pelo funcionario na empresa
				NG700VECAT( cFilFichas, TM0->TM0_NUMFIC, (cTRBPPP)->EMP ) //Verifica se existe CAT para a Ficha Medica do Funcionario
			EndIf

		EndIf

		strFuncao := (cTRBPPP)->DESFUN
		DBSelectArea( "SRJ" )
		DBSetOrder( 1 )

		// Determina se a descricao da funcao sera impressa no PPP verificando
		// os campos "Impr. no PPP?" e "Func. Lider" no registro da função (SRJ)
		If DBSeek( cXFilSRJ + (cTRBPPP)->CODFUN )
			nRJ_IMP := -1
			nRJ_IMP := Val( SRJ->RJ_PPPIMP )

			If nRJ_IMP <> 1
				nRJ_IMP := Val( SRJ->RJ_LIDER )

				If nRJ_IMP == 0
					nRJ_IMP := 2
				EndIf

			EndIf

			If nRJ_IMP == 2
				strFuncao := Space( 25 )
			EndIf

		EndIf

		If Empty( strFuncao )
			strFuncao := "NA"
		EndIf

		cCBO  := SRJ->RJ_CBO

		If Year( (cTRBPPP)->DTATE-1 ) >= 2003
			lTroca := .F.

			If !Empty( SRJ->RJ_CODCBO )
				cCBO := SRJ->RJ_CODCBO
			EndIf

		EndIf

		cTrocaFun := (cTRBPPP)->CODFUN

		DBSelectArea( "SQ3" )
		DBSetOrder( 1 )

		If  !DBSeek( cXFilSQ3+(cTRBPPP)->CARGO + (cTRBPPP)->CUSTO )
			DBSelectArea( "SQ3" )
			DBSetOrder( 1 )
			DBSeek( cXFilSQ3 + (cTRBPPP)->CARGO )

			If aScan( aCargoSv, { |x| x[1] + x[2] + x[4] == cFilFichas + (cTRBPPP)->CARGO + (cTRBPPP)->EMP } ) <= 0
				aAdd( aCargoSv, { cFilFichas, (cTRBPPP)->CARGO, "", (cTRBPPP)->EMP } )
			EndIf
		Else

			If aScan( aCargoSv, { |x| x[1] + x[2] + x[3] + x[4] == cFilFichas + (cTRBPPP)->CARGO + (cTRBPPP)->CUSTO + (cTRBPPP)->EMP } ) <= 0
				aAdd( aCargoSv, { cFilFichas, (cTRBPPP)->CARGO, (cTRBPPP)->CUSTO, (cTRBPPP)->EMP } )
			EndIf

		EndIf

		strCargo := SQ3->Q3_DESCSUM

		If Empty( strCargo )
			strCargo := (cTRBPPP)->DESCAR
		EndIf

		cCNPJtrb := (cTRBPPP)->CNPJ
		cTIPOtrb := (cTRBPPP)->TIPINS
		DBSelectArea( cAlias )
		DBSetOrder( 1 )

		If DBSeek( cXFilCTT + (cTRBPPP)->CUSTO ) .And. lCNPJCC

			If cAlias == "SI3" .And. !Empty( SI3->I3_CEI )
				cTIPOtrb := IIf( SI3->I3_TIPO == "1", 2, 1 )
				cCNPJtrb := SI3->I3_CEI
			ElseIf !Empty( CTT->CTT_CEI )
				cTIPOtrb := IIf( CTT->CTT_TIPO == "1", 2, 1 )
				cCNPJtrb := CTT->CTT_CEI
			EndIf

		EndIf

		If xm_par34 == 1 // Desc. da Lotação ?
			strCCusto := IIf( xm_par35 == 1, AllTrim( (cTRBPPP)->CUSTO ) + " - ", "" ) + &cDescr
		Else
			DBSelectArea( "SQB" )
			DBSetOrder( 1 )
			DBSeek( xFilial( "SQB", (cTRBPPP)->FILIAL ) + (cTRBPPP)->DEPTO )
			strCCusto := IIf( xm_par35 == 1, (cTRBPPP)->DEPTO + " - ", "" ) + SQB->QB_DESCRIC
		EndIf


		// Adiciona dados para o Historico do Funcionario
		nPosHist := aScan( aHistory, { | x | x[10] == cCNPJtrb                                 .And.;
											 x[5] == AllTrim( strCCusto )                      .And.;
											 x[IIf( lTrocaDes, 7, 6 )] == AllTrim( strCargo )  .And.;
											 x[IIf( !lTrocaDes, 7, 6 )] == AllTrim( strFuncao ).And.;
											 x[8] == cCBO                                      .And.;
											 x[9] == (cTRBPPP)->GFIP                           .And.;
											 x[1] == cFilFichas                                .And.;
											 x[2] == (cTRBPPP)->MAT                            .And.;
											 x[3] == (cTRBPPP)->DTDE                           .And.;
											 x[4] == dDateAte } )

		If nPosHist == 0

			If lSigaMdtps
				aAdd( aHistory,{ cFilFichas             ,;
								(cTRBPPP)->MAT          ,;
								(cTRBPPP)->DTDE         ,;
								dDateAte                ,;
								AllTrim( strCCusto )    ,;
								AllTrim( strCargo )     ,;
								AllTrim( strFuncao )    ,;
								cCBO                    ,;
								(cTRBPPP)->GFIP         ,;
								cCNPJtrb                ,;
								cTIPOtrb                ,;
								(cTRBPPP)->EMP          ,;
								(cTRBPPP)->CUSTO        ,;
								(cTRBPPP)->CODFUN       ,;
								(cTRBPPP)->CARGO } )	//Usado no MDTA102
			Else
				aAdd( aHistory, { cFilFichas         ,;
					            (cTRBPPP)->MAT     ,;
					            (cTRBPPP)->DTDE    ,;
					            dDateAte           ,;
					            AllTrim( strCCusto ) ,;
					            AllTrim( strCargo )  ,;
					            AllTrim( strFuncao ) ,;
					            cCBO               ,;
					            (cTRBPPP)->GFIP    ,;
					            cCNPJtrb           ,;
					            cTIPOtrb           ,;
								(cTRBPPP)->EMP } )
			EndIf

		Else
			aHistory[ nPosHist, 4 ] := dDateAte
		EndIf

		// Verifica se o funcionario executou alguma tarefa
		If !lMDTA102
			NG700TAREF( cFilFichas, (cTRBPPP)->MAT, (cTRBPPP)->DTDE, dDateAte,;
						 (cTRBPPP)->CUSTO, (cTRBPPP)->DEPTO, (cTRBPPP)->CODFUN, TM0->TM0_NUMFIC,;
						 (cTRBPPP)->EMP )
		EndIf

		If lMudEmpr .And. (cTRBPPP)->EMP != cEmpPPP
			EMP700OPEN( "TM0", "TM0", 1, cEmpPPP, @cModo )
			EMP700OPEN( "SRJ", "SRJ", 1, cEmpPPP, @cModo )
			EMP700OPEN( "SQ3", "SQ3", 1, cEmpPPP, @cModo )
			EMP700OPEN( cAlias, cAlias, 1, cEmpPPP, @cModo )
		EndIf

		DBSelectArea( cTRBPPP )
		DBSkip()
	End

Return aHistory

/*
===============================================================================================================================
Programa--------------: RMDT006()
Autores---------------: Denis Hyroshi de Souza / Gabriel Sokacheski (Totvs)
Conversão para Italac-: Julio de Paula Paz
Data da Criacao-------: 22/09/2023
Descrição-------------: Verifica os riscos que o funcionario esteve exposto
Parametros------------: cFilFun, Caracter, Filial do funcionario
                        cFichaM, Caracter, Numero da ficha medica do funcionario
                        cTarefa, Caracter, Codigo da tarefa do funcionario, "*" representa todas
                        cCusto, Caracter, Codigo do centro de custo do funcionario, "*" representa todos
                        cDepto, Caracter, Codigo do departamento do funcionario, "*" representa todos
                        cFuncc, Caracter, Codigo da funcao do funcionario, "*" representa todas
                        Mat, Caracter, Matricula do funcioario
                        dIniRisco, Date, Data inicio da exposicao
                        dFinRisco, Date, Data funal da exposicao
                        nParam, Numerico, Quantidade de vezes que sarao executadas as operacoes da funcao
                        cEmpFun, Caracter, Codigo da empresa no sistema
Retorno---------------: Nenhum
===============================================================================================================================
*/
Static Function NG700RISCO( cFilFun, cFichaM, cTarefa, cCusto, cDepto, cFuncc, Mat, dIniRisco, dFinRisco, nParam, cEmpFun )

	Local xEpis
	Local nx
	Local ny
	Local nFor1
	Local nFor2
	Local nTam := 8
	Local cModoTN0
	Local cModoTNX
	Local cModoTNF
	Local cXFilTNF
	Local cModoTN3
	Local cXFilTN3
	Local aAfasTip := ""
	Local nW

	Local cPrazoTNF
	Local cPrazoDur
	Local cHigiene
	Local nQtdeAfast


	Private cXFilTNX, cXFilTN0, cXFilTJF, cXFilTO4

	Default dDtTransf := CtoD( '//' )

	_cTarefa     := cTarefa
	_centrCusto  := cCusto
	_cFunccRis   := cFuncc
	_cDeptoRis   := cDepto
	cMatric      := Mat
	nRisco       := Space( 9 )

	If lMudEmpr .And. cEmpFun != cEmpPPP
		cModo := FWModeAccess( "TN0" )
		EMP700OPEN( "TN0", "TN0", 1, cEmpFun, @cModo, cFilFun )
		cModo := FWModeAccess( "TNX" )
		EMP700OPEN( "TNX", "TNX", 1, cEmpFun, @cModo, cFilFun )
		cModo := FWModeAccess( "TNF" )
		EMP700OPEN( "TNF", "TNF", 1, cEmpFun, @cModo, cFilFun )
		cModo := FWModeAccess( "TN3" )
		EMP700OPEN( "TN3", "TN3", 1, cEmpFun, @cModo, cFilFun )
		cModo := FWModeAccess( "TMA" )
		EMP700OPEN( "TMA", "TMA", 1, cEmpFun, @cModo, cFilFun )
		cModo := FWModeAccess( "SR8" )
		EMP700OPEN( "SR8", "SR8", 1, cEmpFun, @cModo, cFilFun )
		cModo := FWModeAccess( "TJF" )
		EMP700OPEN( "TJF", "TJF", 1, cEmpFun, @cModo, cFilFun )
		cModo := FWModeAccess( "TO4" )
		EMP700OPEN( "TO4", "TO4", 1, cEmpFun, @cModo, cFilFun )
	EndIf

	cModoTN0 := f700RetCom( "TN0" )
	cXFilTN0 := FwxFilial( "TN0", cFilFun, SubStr( cModoTN0, 1, 1 ), SubStr( cModoTN0, 2, 1 ), SubStr( cModoTN0, 3, 1 ) )

	cModoTNX := f700RetCom( "TNX" )
	cXFilTNX := FwxFilial( "TNX", cFilFun, SubStr( cModoTNX, 1, 1 ), SubStr( cModoTNX, 2, 1 ), SubStr( cModoTNX, 3, 1 ) )

	cModoTNF := f700RetCom( "TNF" )
	cXFilTNF := FwxFilial( "TNF", cFilFun, SubStr( cModoTNF, 1, 1 ), SubStr( cModoTNF, 2, 1 ), SubStr( cModoTNF, 3, 1 ) )

	cModoTN3 := f700RetCom( "TN3" )
	cXFilTN3 := FwxFilial( "TN3", cFilFun, SubStr( cModoTN3, 1, 1 ), SubStr( cModoTN3, 2, 1 ), SubStr( cModoTN3, 3, 1 ) )

	cModoTL0 := f700RetCom( "TL0" )
	cXFilTL0 := FwxFilial( "TL0", cFilFun, SubStr( cModoTL0, 1, 1 ), SubStr( cModoTL0, 2, 1 ), SubStr( cModoTL0, 3, 1 ) )

	cModoTJF := f700RetCom( "TJF" )
	cXFilTJF := FwxFilial( "TJF", cFilFun, SubStr( cModoTJF, 1, 1 ), SubStr( cModoTJF, 2, 1 ), SubStr( cModoTJF, 3, 1 ) )

	cModoTO4 := f700RetCom( "TO4" )
	cXFilTO4 := FwxFilial( "TO4", cFilFun, SubStr( cModoTO4, 1, 1 ), SubStr( cModoTO4, 2, 1 ), SubStr( cModoTO4, 3, 1 ) )


	If nParam > 0

		For nx := 1 to nTam

			For nY := 1 To nParam

				If nx == 1
					_centrCusto := cCusto
					_cFunccRis  := cFuncc
					_cDeptoRis  := cDepto
				ElseIf nx == 2
					_centrCusto:= PadR( "*", nSizeSI3 )
					_cFunccRis := cFuncc
					_cDeptoRis := cDepto
				ElseIf nx == 3
					_centrCusto := cCusto
					_cFunccRis := PadR( "*", nSizeSRJ )
					_cDeptoRis := cDepto
				ElseIf nx == 4
					_centrCusto:= PadR( "*", nSizeSI3 )
					_cFunccRis := PadR( "*", nSizeSRJ )
					_cDeptoRis := cDepto
				ElseIf nx == 5
					_centrCusto := cCusto
					_cFunccRis  := cFuncc
					_cDeptoRis  := PadR( "*", nSizeSQB )
				ElseIf nx == 6
					_centrCusto:= PadR( "*", nSizeSI3 )
					_cFunccRis := cFuncc
					_cDeptoRis := PadR( "*", nSizeSQB )
				ElseIf nx == 7
					_centrCusto := cCusto
					_cFunccRis := PadR( "*", nSizeSRJ )
					_cDeptoRis := PadR( "*", nSizeSQB )
				ElseIf nx == 8
					_centrCusto:= PadR( "*", nSizeSI3 )
					_cFunccRis := PadR( "*", nSizeSRJ )
					_cDeptoRis := PadR( "*", nSizeSQB )
				EndIf

				DBSelectArea( "TN0" )
				DBSetOrder( 5 )

				If DBSeek( cXFilTN0 + _centrCusto + _cFunccRis + _cTarefa + _cDeptoRis )

					While !Eof() .And.AllTrim( TN0->TN0_CC ) == AllTrim( _centrCusto ) .And.;
						AllTrim( TN0->TN0_CODFUN ) == AllTrim( _cFunccRis ) .And.;
						AllTrim( TN0->TN0_CODTAR ) == AllTrim( _cTarefa ) .And.;
						AllTrim( TN0->TN0_DEPTO  ) == AllTrim( _cDeptoRis ) .And.;
						TN0->TN0_FILIAL == cXFilTN0 .And.;
						IIf( lSigaMdtps, TN0->(TN0_CODCLI+TN0_LOJACL) == SubStr( SRA->RA_CC, 1, nSizeTD ), .T. )


						If xm_par07 == 2 .And. TN0->TN0_LISASO $ "12" //Considerar Risco ?
							TN0->( DBSkip() )
							Loop
						EndIf

						aAfasTip := MDT700AFAS( Mat, dIniRisco, dFinRisco )//Verifica afastamentos durante período do risco.

						For nW := 1 To Len( aAfasTip )
							lStart     := .F.
							dInicioRis := aAfasTip[nW, 1] //dIniRisco
							dFimRis    := aAfasTip[nW, 2]//dFinRisco
							dtAval     := TN0->TN0_DTRECO

							If dtAval > dFimRis .Or. Empty( TN0->TN0_DTAVAL )
								Loop
							EndIf

							If !Empty( TN0->TN0_DTELIM ) .And. TN0->TN0_DTELIM <  dInicioRis
								Loop
							EndIf

							If dtAval >= dInicioRis  .And. dtAval <= dFimRis
								lStart  := .T.

								If !Empty( TN0->TN0_DTELIM ) .And. TN0->TN0_DTELIM < dFimRis
									dFimRis := TN0->TN0_DTELIM
								EndIf

								dInicioRis := dtAval
							ElseIf dtAval < dInicioRis .And. (Empty( TN0->TN0_DTELIM ) .Or. TN0->TN0_DTELIM >= dInicioRis )
								lStart  := .T.

								If !Empty( TN0->TN0_DTELIM ) .And. TN0->TN0_DTELIM < dFimRis
									dFimRis := TN0->TN0_DTELIM
								EndIf

							EndIf

							If lStart .And. lConsEPI // Se não consiste EPI
								NGGRAVA700( cFilFun, cFichaM, cCusto, cDepto, cFuncc, Mat, dInicioRis, dFimRis, Space( 12 ), "NA", cEmpFun, Space( 15 ) )
							ElseIf lStart .And. !lConsEPI // Se consiste EPI

								//Apaga todos os registros do arquivo temporario onde estao os EPI's entregues
								aTNFobr := {}
								aTNFalt := {}
								aTNFfam := {}
								DBSelectArea( cTRBTNF )
								ZAP
								lFirst     := .T.

								DBSelectArea( "TNX" )
								DBSetOrder( 1 )
								DBSeek( cXFilTNX + TN0->TN0_NUMRIS )

								While !Eof() .And. cXFilTNX == TNX->TNX_FILIAL .And. TN0->TN0_NUMRIS == TNX->TNX_NUMRIS

									If TNX->TNX_TIPO == "1"
										aAdd( aTNFobr, TNX->TNX_EPI )
									Else

										If (nPosi := aScan( aTNFfam, {|x| x == TNX->TNX_FAMIL } )) > 0
											aAdd( aTNFalt[nPosi], TNX->TNX_EPI )
										Else
											aAdd( aTNFfam, TNX->TNX_FAMIL )
											aAdd( aTNFalt, { TNX->TNX_EPI } )
										EndIf

									EndIf

									DBSelectArea( "TNX" )
									DBSkip()
								End

								// Epi nao esta previsto p/ funcionario
								If Len( aTNFobr ) == 0 .And. Len( aTNFalt ) == 0
									NGGRAVA700( cFilFun, cFichaM, cCusto, cDepto, cFuncc, Mat, dInicioRis, dFimRis, Space( 12 ), "NA", cEmpFun, Space( 15 ) )
								Else  // Epi esta previsto p/ funcionario
									lEpiObr   := .T. //Verifica se houve utilizacao de todos os EPIs necessarios
									dDtEficaz := CTOD( "//" ) //Data inicio Eficaz dos EPIs

									For nFor1 := 1 To Len( aTNFobr )
										dDtEfica2 := dFimRis
										lEpiSub := .F.
										DBSelectArea( "TNF" )
										DBSetOrder( 3 ) // TNF_FILIAL+TNF_MAT+TNF_CODEPI+DToS(TNF_DTENTR)+TNF_HRENTR

										If DBSeek( cXFilTNF + Mat + aTNFobr[nFor1] )

											While !Eof() .And. cXFilTNF+Mat+aTNFobr[nFor1] == TNF->(TNF_FILIAL+TNF_MAT+TNF_CODEPI)

												cNUMCAP := Space( 12 )

												If TNF->TNF_INDDEV == "3" .Or. TNF->TNF_DTENTR > dFimRis .Or. TNF->TNF_DTENTR < dDtTransf
													DBSelectArea( "TNF" )
													DBSkip()
													Loop
												EndIf

												If TNF->TNF_DTDEVO < dInicioRis .And. !Empty( TNF->TNF_DTDEVO )
													DBSelectArea( "TNF" )
													DBSkip()
													Loop
												EndIf

												cNUMCAP := TNF->TNF_NUMCAP
												DBSelectArea( "TN3" )
												DBSetOrder( 1 )
												If DBSeek( cXFilTN3 + TNF->TNF_FORNEC + TNF->TNF_LOJA + TNF->TNF_CODEPI + TNF->TNF_NUMCAP )

													If aScan( aNUMCAPS, { |x| x[1] == TNF->TNF_NUMCAP } ) == 0 .And. !Empty( TN3->TN3_OBSAVA )
														aAdd( aNUMCAPS, { TNF->TNF_NUMCAP, TN3->TN3_OBSAVA } )
													EndIf

												EndIf

												lEpiSub := .T.
												lFirst  := .F.
												dDtEfica2 := IIf( TNF->TNF_DTENTR > dDtEfica2, dDtEfica2, TNF->TNF_DTENTR )
												dDtEntr   := IIf( TNF->TNF_DTENTR < dInicioRis, dInicioRis, TNF->TNF_DTENTR )
												cPROTEC := "S "

												If TNF->TNF_EPIEFI == "2"
													cPROTEC := "N "
												ElseIf TNF->TNF_EPIEFI == "3"
													cPROTEC := "  "
												EndIf

												dDtDevo := dFimRis

												If !Empty( TNF->TNF_DTDEVO ) .And. TNF->TNF_DTDEVO >= dInicioRis .And. TNF->TNF_DTDEVO < dFimRis
													dDtDevo := TNF->TNF_DTDEVO
												ElseIf Empty( TNF->TNF_DTDEVO )
													DBSelectArea( "TNF" )  //TNF_FILIAL+TNF_MAT+TNF_CODEPI+DToS(TNF_DTENTR)+TNF_HRENTR
													DBSkip()

													If cXFilTNF+Mat+aTNFobr[nFor1] == TNF->(TNF_FILIAL+TNF_MAT+TNF_CODEPI);
															.And. TNF->(!Eof()) .And. TNF->TNF_INDDEV != "3"

														If dDtEntr < TNF->TNF_DTENTR .And. (TNF->TNF_DTENTR-1) >= dInicioRis .And. (TNF->TNF_DTENTR-1) < dFimRis
															dDtDevo := TNF->TNF_DTENTR-1
														ElseIf dDtEntr == TNF->TNF_DTENTR .And. TNF->TNF_DTENTR >= dInicioRis .And. TNF->TNF_DTENTR < dFimRis
															dDtDevo := TNF->TNF_DTENTR
														EndIf

													EndIf

													DBSkip( -1 )
												EndIf

												If !( TNF->TNF_DTENTR <= TN3->TN3_DTVENC .And. dDtDevo <= TN3->TN3_DTVENC )
													cPrazoTNF := "N"
												Else
													cPrazoTNF := "S"
												EndIf

												// Verifica se funcionario ficou afastado
												nQtdeAfast := 0

												If TN3->TN3_TPDURA == "U"
													nQtdeAfast := fQtdeAfast( cFilFun, cMatric, TNF->TNF_DTENTR, dDtDevo )
												EndIf

												// Verifica se pelo menos um EPI foi utilizado mais do que o seu prazo de durabilidade
												If TN3->TN3_INDEVO == "2"
													cPrazoDur := 'S'
												Else
													nDiasUtilizados := ( dDtDevo - TNF->TNF_DTENTR ) - nQtdeAfast
													If nDiasUtilizados > TN3->TN3_DURABI
														cPrazoDur := 'N'
													Else 
														cPrazoDur := 'S'
													EndIf
												EndIf

												If TN3->TN3_PERMAN > 0 .And. Empty( TNF->TNF_DTMANU )
													cHigiene := 'N'
												Else 
													cHigiene := 'S'
												EndIf

												lIncEpi := .F.
												DBSelectArea( cTRBTNF )
												DBSetOrder( 1 )

												If !DBSeek( DToS( dDtEntr ) + cNUMCAP + cPROTEC + DToS( TNF->TNF_DTENTR ) )
													lIncEpi := .T.
													RecLock( cTRBTNF, .T. )
														(cTRBTNF)->DTINI  := dDtEntr
														(cTRBTNF)->NUMCAP := cNUMCAP
														(cTRBTNF)->PROTEC := cPROTEC
														(cTRBTNF)->DTREAL := TNF->TNF_DTENTR
														(cTRBTNF)->DTDEVO := dDtDevo
														(cTRBTNF)->CODEPI := TNF->TNF_CODEPI
														(cTRBTNF)->PRZTNF := cPrazoTNF
														(cTRBTNF)->PRZDUR := cPrazoDur
														(cTRBTNF)->HIGIEN := cHigiene
													MSUnLock()
												ElseIf (cTRBTNF)->CODEPI == TNF->TNF_CODEPI .And. dDtDevo > (cTRBTNF)->DTDEVO
													lIncEpi := .T.
													RecLock( cTRBTNF, .F. )
														(cTRBTNF)->DTDEVO := dDtDevo
													MSUnLock()
												EndIf

												If lIncEpi
													lEpiEntregue := .T.
												EndIf

												DBSelectArea( "TNF" )
												DBSkip()
											End

										ElseIf NGCADICBASE( "TN3_GENERI", "D", "TN3", .F. )
											DBSelectArea( "TN3" )
											DBSetOrder( 2 )
											DBSeek( cXFilTN3 + aTNFobr[nFor1] )

											While TN3->(!Eof()) .And. TN3->TN3_CODEPI == aTNFobr[nFor1]

												If TN3->TN3_GENERI == '2'
													DBSelectArea( "TL0" )
													DBSetOrder( 1 )
													DBSeek( cXFilTL0 + aTNFobr[nFor1] + TN3->TN3_FORNEC + TN3->TN3_LOJA )

													While TL0->(!Eof()) .And. TL0->TL0_EPIGEN == aTNFobr[nFor1] .And. ;
														TL0->TL0_FORNEC = TN3->TN3_FORNEC .And. TL0->TL0_LOJA == TN3->TN3_LOJA
														DBSelectArea( "TNF" )
														DBSetOrder( 1 )

														If DBSeek( cXFilTNF+TL0->TL0_FORNEC+TL0->TL0_LOJA+TL0->TL0_EPIFIL+TL0->TL0_NUMCAP+Mat )

															While TNF->(!Eof()) .And. cXFilTNF+Mat+TL0->TL0_EPIFIL == TNF->(TNF_FILIAL+TNF_MAT+TNF_CODEPI)

																cNUMCAP := Space( 12 )

																If TNF->TNF_INDDEV == "3" .Or. TNF->TNF_DTENTR > dFimRis .Or. TNF->TNF_DTENTR < dDtTransf
																	DBSelectArea( "TNF" )
																	DBSkip()
																	Loop
																EndIf

																If TNF->TNF_DTDEVO < dInicioRis .And. !Empty( TNF->TNF_DTDEVO )
																	DBSelectArea( "TNF" )
																	DBSkip()
																	Loop
																EndIf

																cNUMCAP := TNF->TNF_NUMCAP

																If aScan( aNUMCAPS, {|x| x[1] == TNF->TNF_NUMCAP } ) == 0 //.and. !Empty(TN3->TN3_OBSAVA)
																	aAdd( aNUMCAPS, {TNF->TNF_NUMCAP, "" } )
																EndIf

																lEpiSub := .T.
																lFirst  := .F.
																dDtEfica2 := IIf (TNF->TNF_DTENTR > dDtEfica2, dDtEfica2, TNF->TNF_DTENTR )
																dDtEntr   := IIf (TNF->TNF_DTENTR < dInicioRis, dInicioRis, TNF->TNF_DTENTR )
																cPROTEC := "S "

																If TNF->TNF_EPIEFI == "2"
																	cPROTEC := "N "
																ElseIf TNF->TNF_EPIEFI == "3"
																	cPROTEC := "  "
																EndIf

																dDtDevo := dFimRis

																If !Empty( TNF->TNF_DTDEVO ) .And. TNF->TNF_DTDEVO >= dInicioRis .And. TNF->TNF_DTDEVO < dFimRis
																	dDtDevo := TNF->TNF_DTDEVO
																ElseIf Empty( TNF->TNF_DTDEVO )
																	DBSelectArea( "TNF" )  //TNF_FILIAL+TNF_MAT+TNF_CODEPI+DToS(TNF_DTENTR)+TNF_HRENTR
																	DBSkip()

																	If cXFilTNF+Mat+TL0->TL0_EPIFIL == TNF->(TNF_FILIAL+TNF_MAT+TNF_CODEPI) .And.;
																	   TNF->(!Eof()) .And. TNF->TNF_INDDEV != "3"

																		If dDtEntr < TNF->TNF_DTENTR .And. (TNF->TNF_DTENTR-1) >= dInicioRis .And. (TNF->TNF_DTENTR-1) < dFimRis
																			dDtDevo := TNF->TNF_DTENTR-1
																		ElseIf dDtEntr == TNF->TNF_DTENTR .And. TNF->TNF_DTENTR >= dInicioRis .And. TNF->TNF_DTENTR < dFimRis
																			dDtDevo := TNF->TNF_DTENTR
																		EndIf

																	EndIf

																	DBSkip( -1 )
																EndIf

																// Verifica se pelo menos um EPI foi entregue fora do prazo de validade
																	If !( TNF->TNF_DTENTR <= TL0->TL0_DTVENC .And. dDtDevo <= TL0->TL0_DTVENC )
																	cPrazoTNF := "N"
																Else
																	cPrazoTNF := "S"
																EndIf

																// Verifica se funcionario ficou afastado
																nQtdeAfast := 0

																If NGSEEK( 'TN3', TL0->TL0_FORNEC + TL0->TL0_LOJA + TL0->TL0_EPIGEN, 1, 'TN3->TN3_TPDURA' ) == "U"
																	nQtdeAfast := fQtdeAfast( cFilFun, cMatric, TNF->TNF_DTENTR, dDtDevo )
																EndIf

																// Verifica se pelo menos um EPI foi utilizado mais do que o seu prazo de durabilidade
																If NGSEEK( 'TN3', TL0->TL0_FORNEC + TL0->TL0_LOJA + TL0->TL0_EPIGEN, 1, 'TN3->TN3_INDEVO' ) == "2"
																	cPrazoDur := 'S'
																Else
																	nDiasUtilizados := ((cTRBTNF)->DTDEVO - (cTRBTNF)->DTREAL) - nQtdeAfast

																	If nDiasUtilizados > NGSEEK( 'TN3', TL0->TL0_FORNEC + TL0->TL0_LOJA + TL0->TL0_EPIGEN, 1, 'TN3->TN3_DURABI' )
																		cPrazoDur := 'N'
																	Else 
																		cPrazoDur := 'S'
																	EndIf

																EndIf

																// Verifica se pelo menos um EPI nao teve higienização
																If TN3->TN3_PERMAN > 0 .And. Empty( TNF->TNF_DTMANU )
																	cHigiene := 'N'
																Else 
																	cHigiene := 'S'
																EndIf

																lIncEpi := .F.
																DBSelectArea( cTRBTNF )
																DBSetOrder( 1 )

																If !DBSeek( DToS( dDtEntr ) + cNUMCAP + cPROTEC + DToS( TNF->TNF_DTENTR ) )
																	lIncEpi := .T.
																	RecLock( cTRBTNF, .T. )
																		(cTRBTNF)->DTINI  := dDtEntr
																		(cTRBTNF)->NUMCAP := cNUMCAP
																		(cTRBTNF)->PROTEC := cPROTEC
																		(cTRBTNF)->DTREAL := TNF->TNF_DTENTR
																		(cTRBTNF)->DTDEVO := dDtDevo
																		(cTRBTNF)->CODEPI := TNF->TNF_CODEPI
																		(cTRBTNF)->PRZTNF := cPrazoTNF
																		(cTRBTNF)->PRZDUR := cPrazoDur
																		(cTRBTNF)->HIGIEN := cHigiene
																	MSUnLock()
																ElseIf (cTRBTNF)->CODEPI == TNF->TNF_CODEPI .And. dDtDevo > (cTRBTNF)->DTDEVO
																	lIncEpi := .T.
																	RecLock( cTRBTNF, .F. )
																		(cTRBTNF)->DTDEVO := dDtDevo
																		/*(cTRBTNF)->PRZTNF := cPrazoTNF
																		(cTRBTNF)->PRZDUR := cPrazoDur
																		(cTRBTNF)->HIGIEN := cHigiene ****Condição não atendida no ADVPR*/
																	MSUnLock()
																EndIf

																If lIncEpi
																	lEpiEntregue := .T.
																EndIf

																DBSelectArea( "TNF" )
																DBSkip()
															End

														EndIf

														DBSelectArea( "TL0" )
														TL0->(DBSkip())
													End

												EndIf

												DBSelectArea( "TN3" )
												TN3->(DBSkip())
											End

										EndIf

										If !lEpiSub
											lEpiObr := .F.
										EndIf

										If dDtEfica2 > dDtEficaz
											dDtEficaz := dDtEfica2
										EndIf

									Next nFor1

									For nFor1 := 1 To Len( aTNFalt )
										lEpiAltOK := .F.
										dDtEfica2 := dFimRis

										For nFor2 := 1 To Len( aTNFalt[nFor1] )
											DBSelectArea( "TNF" )
											DBSetOrder( 3 )  //TNF_FILIAL+TNF_MAT+TNF_CODEPI+DToS(TNF_DTENTR)+TNF_HRENTR

											If DBSeek( cXFilTNF+Mat+aTNFalt[nFor1, nFor2] )

												While !Eof() .And. cXFilTNF+Mat+aTNFalt[nFor1, nFor2] == TNF->(TNF_FILIAL+TNF_MAT+TNF_CODEPI)

													cNUMCAP := Space( 12 )

													If TNF->TNF_INDDEV == "3" .Or. TNF->TNF_DTENTR > dFimRis .Or. TNF->TNF_DTENTR < dDtTransf
														DBSelectArea( "TNF" )
														DBSkip()
														Loop
													EndIf

													If TNF->TNF_DTDEVO < dInicioRis .And. !Empty( TNF->TNF_DTDEVO )
														DBSelectArea( "TNF" )
														DBSkip()
														Loop
													EndIf

													cNUMCAP := TNF->TNF_NUMCAP
													DBSelectArea( "TN3" )
													DBSetOrder( 1 )

													If DBSeek( xFilial( "TN3", cFilFun ) + TNF->TNF_FORNEC + TNF->TNF_LOJA + TNF->TNF_CODEPI + TNF->TNF_NUMCAP ) .And.;
													   aScan( aNUMCAPS, { |x| x[1] == TNF->TNF_NUMCAP } ) == 0 .And. !Empty( TN3->TN3_OBSAVA )

														aAdd( aNUMCAPS, { TNF->TNF_NUMCAP, TN3->TN3_OBSAVA } )
													EndIf

													lEpiAltOK := .T.
													lFirst    := .F.
													dDtEfica2 := IIf( TNF->TNF_DTENTR > dDtEfica2, dDtEfica2, TNF->TNF_DTENTR )
													dDtEntr := IIf( TNF->TNF_DTENTR < dInicioRis, dInicioRis, TNF->TNF_DTENTR )
													cPROTEC := "S "

													If TNF->TNF_EPIEFI == "2"
														cPROTEC := "N "
													ElseIf TNF->TNF_EPIEFI == "3"
														cPROTEC := "  "
													EndIf

													dDtDevo := dFimRis

													If !Empty( TNF->TNF_DTDEVO ) .And. TNF->TNF_DTDEVO >= dInicioRis .And. TNF->TNF_DTDEVO < dFimRis
														dDtDevo := TNF->TNF_DTDEVO
													ElseIf Empty( TNF->TNF_DTDEVO )
														DBSelectArea( "TNF" )  //TNF_FILIAL+TNF_MAT+TNF_CODEPI+DToS(TNF_DTENTR)+TNF_HRENTR
														DBSkip()

														If cXFilTNF + Mat + aTNFalt[nFor1, nFor2] == TNF->(TNF_FILIAL+TNF_MAT+TNF_CODEPI);
																.And. TNF->(!Eof()) .And. TNF->TNF_INDDEV != "3"

															If dDtEntr < TNF->TNF_DTENTR

																If (TNF->TNF_DTENTR-1) >= dInicioRis .And. (TNF->TNF_DTENTR-1) < dFimRis
																	dDtDevo := TNF->TNF_DTENTR-1
																EndIf

															ElseIf dDtEntr == TNF->TNF_DTENTR

																If TNF->TNF_DTENTR >= dInicioRis .And. TNF->TNF_DTENTR < dFimRis
																	dDtDevo := TNF->TNF_DTENTR
																EndIf

															EndIf

														EndIf

														DBSkip( -1 )
													EndIf

													// Verifica se pelo menos um EPI foi entregue fora do prazo de validade
													If !( TNF->TNF_DTENTR <= TN3->TN3_DTVENC .And. dDtDevo <= TN3->TN3_DTVENC )
														cPrazoTNF := "N"
													Else
														cPrazoTNF := "S"
													EndIf

													// Verifica se funcionario ficou afastado
													nQtdeAfast := 0

													If TN3->TN3_TPDURA == "U"
														nQtdeAfast := fQtdeAfast( cFilFun, cMatric, TNF->TNF_DTENTR, dDtDevo )
													EndIf

													// Verifica se pelo menos um EPI foi utilizado mais do que o seu prazo de durabilidade
													If TN3->TN3_INDEVO == "2"
														cPrazoDur := 'S'
													Else
														nDiasUtilizados := ( dDtDevo - TNF->TNF_DTENTR ) - nQtdeAfast

														If nDiasUtilizados > TN3->TN3_DURABI
															cPrazoDur := 'N'
														Else 
															cPrazoDur := 'S'
														EndIf

													EndIf

													// Verifica se pelo menos um EPI nao teve higienização
													If TN3->TN3_PERMAN > 0 .And. Empty( TNF->TNF_DTMANU )
														cHigiene := 'N'
													Else 
														cHigiene := 'S'
													EndIf

													lIncEpi := .F.
													DBSelectArea( cTRBTNF )
													DBSetOrder( 1 )

													If !DBSeek( DToS( dDtEntr ) + cNUMCAP + cPROTEC + DToS( TNF->TNF_DTENTR ) )
														lIncEpi := .T.
														RecLock( cTRBTNF, .T. )
															(cTRBTNF)->DTINI  := dDtEntr
															(cTRBTNF)->NUMCAP := cNUMCAP
															(cTRBTNF)->PROTEC := cPROTEC
															(cTRBTNF)->DTREAL := TNF->TNF_DTENTR
															(cTRBTNF)->DTDEVO := dDtDevo
															(cTRBTNF)->CODEPI := TNF->TNF_CODEPI
															(cTRBTNF)->PRZTNF := cPrazoTNF
															(cTRBTNF)->PRZDUR := cPrazoDur
															(cTRBTNF)->HIGIEN := cHigiene
														MSUnLock()
													ElseIf (cTRBTNF)->CODEPI == TNF->TNF_CODEPI .And. dDtDevo > (cTRBTNF)->DTDEVO
														lIncEpi := .T.
														RecLock( cTRBTNF, .F. )
															(cTRBTNF)->DTDEVO := dDtDevo
														/*	(cTRBTNF)->PRZTNF := cPrazoTNF
															(cTRBTNF)->PRZDUR := cPrazoDur
															(cTRBTNF)->HIGIEN := cHigiene*/
														MSUnLock()
													EndIf

													If lIncEpi
														lEpiEntregue := .T.
													EndIf

													DBSelectArea( "TNF" )
													DBSkip()
												End

											ElseIf NGCADICBASE( "TN3_GENERI", "D", "TN3", .F. )
												DBSelectArea( "TN3" )
												DBSetOrder( 2 )
												DBSeek( cXFilTN3 + aTNFalt[nFor1, nFor2] )

												While TN3->(!Eof()) .And. TN3->TN3_CODEPI == aTNFalt[nFor1, nFor2]

													If TN3->TN3_GENERI == '2'
														DBSelectArea( "TL0" )
														DBSetOrder( 1 )
														DBSeek( cXFilTL0 + aTNFalt[nFor1, nFor2] + TN3->TN3_FORNEC + TN3->TN3_LOJA )

														While TL0->(!Eof()) .And. TL0->TL0_EPIGEN == aTNFalt[nFor1, nFor2] .And. ;
															TL0->TL0_FORNEC = TN3->TN3_FORNEC .And. TL0->TL0_LOJA == TN3->TN3_LOJA
															DBSelectArea( "TNF" )
															DBSetOrder( 1 )

															If DBSeek( cXFilTNF+TL0->TL0_FORNEC+TL0->TL0_LOJA+TL0->TL0_EPIFIL+TL0->TL0_NUMCAP+Mat )

																While TNF->(!Eof()) .And. cXFilTNF+Mat+TL0->TL0_EPIFIL == TNF->(TNF_FILIAL+TNF_MAT+TNF_CODEPI)

																	cNUMCAP := Space( 12 )

																	If TNF->TNF_INDDEV == "3" .Or. TNF->TNF_DTENTR > dFimRis .Or. TNF->TNF_DTENTR < dDtTransf
																		DBSelectArea( "TNF" )
																		DBSkip()
																		Loop
																	EndIf

																	If TNF->TNF_DTDEVO < dInicioRis .And. !Empty( TNF->TNF_DTDEVO )
																		DBSelectArea( "TNF" )
																		DBSkip()
																		Loop
																	EndIf

																	cNUMCAP := TNF->TNF_NUMCAP

																	If aScan( aNUMCAPS, { |x| x[1] == TNF->TNF_NUMCAP } ) == 0
																		aAdd( aNUMCAPS, { TNF->TNF_NUMCAP, "" } )
																	EndIf

																	lEpiAltOK := .T.
																	lFirst    := .F.
																	dDtEfica2 := IIf( TNF->TNF_DTENTR > dDtEfica2, dDtEfica2, TNF->TNF_DTENTR )
																	dDtEntr := IIf( TNF->TNF_DTENTR < dInicioRis, dInicioRis, TNF->TNF_DTENTR )
																	cPROTEC := "S "

																	If TNF->TNF_EPIEFI == "2"
																		cPROTEC := "N "
																	ElseIf TNF->TNF_EPIEFI == "3"
																		cPROTEC := "  "
																	EndIf

																	dDtDevo := dFimRis

																	If !Empty( TNF->TNF_DTDEVO ) .And. TNF->TNF_DTDEVO >= dInicioRis .And. TNF->TNF_DTDEVO < dFimRis
																		dDtDevo := TNF->TNF_DTDEVO
																	ElseIf Empty( TNF->TNF_DTDEVO )
																		DBSelectArea( "TNF" )  //TNF_FILIAL+TNF_MAT+TNF_CODEPI+DToS(TNF_DTENTR)+TNF_HRENTR
																		DBSkip()

																		If cXFilTNF+Mat+TL0->TL0_EPIFIL == TNF->(TNF_FILIAL+TNF_MAT+TNF_CODEPI);
																				.And. TNF->(!Eof()) .And. TNF->TNF_INDDEV != "3"

																			If dDtEntr < TNF->TNF_DTENTR

																				If (TNF->TNF_DTENTR-1) >= dInicioRis .And. (TNF->TNF_DTENTR-1) < dFimRis
																					dDtDevo := TNF->TNF_DTENTR-1
																				EndIf

																			ElseIf dDtEntr == TNF->TNF_DTENTR

																				If TNF->TNF_DTENTR >= dInicioRis .And. TNF->TNF_DTENTR < dFimRis
																					dDtDevo := TNF->TNF_DTENTR
																				EndIf

																			EndIf

																		EndIf

																		DBSkip( -1 )
																	EndIf

																	lIncEpi := .F.
	
																	If !( TNF->TNF_DTENTR <= TL0->TL0_DTVENC .And. dDtDevo <= TL0->TL0_DTVENC )
																		cPrazoTNF := "N"
																	Else
																		cPrazoTNF := "S"
																	EndIf

																	// Verifica se funcionario ficou afastado
																	nQtdeAfast := 0

																	If TN3->TN3_TPDURA == "U"
																		nQtdeAfast := fQtdeAfast( cFilFun, cMatric, TNF->TNF_DTENTR, dDtDevo )
																	EndIf

																	If NGSEEK( 'TN3', TL0->TL0_FORNEC+TL0->TL0_LOJA+TL0->TL0_EPIGEN, 1, 'TN3->TN3_INDEVO' ) == "2"
																		cPrazoDur := 'S'
																	Else
																		nDiasUtilizados := ( dDtDevo - TNF->TNF_DTENTR ) - nQtdeAfast
																		If nDiasUtilizados > NGSEEK( 'TN3', TL0->TL0_FORNEC+TL0->TL0_LOJA+TL0->TL0_EPIGEN, 1, 'TN3->TN3_DURABI' )
																			cPrazoDur := 'N'
																		Else 
																			cPrazoDur := 'S'
																		EndIf
																	EndIf

																	If TN3->TN3_PERMAN > 0 .And. Empty( TNF->TNF_DTMANU )
																		cHigiene := 'N'
																	Else 
																		cHigiene := 'S'
																	EndIf

																	DBSelectArea( cTRBTNF )
																	DBSetOrder( 1 )

																	If !DBSeek( DToS( dDtEntr )+cNUMCAP+cPROTEC+DToS( TNF->TNF_DTENTR ) )
																		lIncEpi := .T.
	
																		RecLock( cTRBTNF, .T. )
																			(cTRBTNF)->DTINI  := dDtEntr
																			(cTRBTNF)->NUMCAP := cNUMCAP
																			(cTRBTNF)->PROTEC := cPROTEC
																			(cTRBTNF)->DTREAL := TNF->TNF_DTENTR
																			(cTRBTNF)->DTDEVO := dDtDevo
																			(cTRBTNF)->CODEPI := TNF->TNF_CODEPI
																			(cTRBTNF)->PRZTNF := cPrazoTNF
																			(cTRBTNF)->PRZDUR := cPrazoDur
																			(cTRBTNF)->HIGIEN := cHigiene
																		MSUnLock()

																	ElseIf (cTRBTNF)->CODEPI == TNF->TNF_CODEPI .And. dDtDevo > (cTRBTNF)->DTDEVO
																		lIncEpi := .T.

																		RecLock( cTRBTNF, .F. )
																			(cTRBTNF)->DTDEVO := dDtDevo
																		MSUnLock()
																		
																	EndIf

																	If lIncEpi
																		lEpiEntregue := .T.
																	EndIf

																	DBSelectArea( "TNF" )
																	DBSkip()
																End

															EndIf

															DBSelectArea( "TL0" )
															TL0->(DBSkip())
														End

													EndIf

													DBSelectArea( "TN3" )
													TN3->(DBSkip())
												End

											EndIf

										Next nFor2

										If dDtEfica2 > dDtEficaz
											dDtEficaz := dDtEfica2
										EndIf

										If !lEpiAltOK
											lEpiObr := .F.
										EndIf

									Next nFor1

									dDtEficaz := IIf( dInicioRis+nLimite_Dias_Epi >= dDtEficaz, dInicioRis, dDtEficaz )

									//Cria historico de epi's entregues
									If !lFirst  //Epi esta previsto p/ funcionario e foi entregue

										If dDtEficaz != dInicioRis
											NGGRAVA700( cFilFun, cFichaM, cCusto, cDepto, cFuncc, Mat, dInicioRis, dDtEficaz-1, Space( 12 ), "N ", cEmpFun, Space( 15 ) )
										EndIf

										fPPP_EPI( dInicioRis )
										aEPIS := {}

										DBSelectArea( cTRBTNF )
										DBSetOrder( 1 )
										DBGoTop()
										dDtTNFfi2 := (cTRBTNF)->DTDEVO

										While !Eof()
											dDtTNFini := (cTRBTNF)->DTINI

											If (cTRBTNF)->DTDEVO > dDtTNFfi2
												dDtTNFfi2 := (cTRBTNF)->DTDEVO
											EndIf

											DBSkip()

											If !Eof()

												If (cTRBTNF)->DTINI > dDtTNFfi2+nLimite_Dias_Epi .And. (dDtTNFfi2+1) <= ((cTRBTNF)->DTINI-1)
													aAdd( aEPIS, { dDtTNFfi2 + 1, (cTRBTNF)->DTINI - 1, Space( 12 ), "N ", Space( 15 ) } )
													dDtTNFfi2 := (cTRBTNF)->DTDEVO
												EndIf

											Else

												If dFimRis > dDtTNFfi2+nLimite_Dias_Epi
													aAdd( aEPIS, { dDtTNFfi2+1, dFimRis, Space( 12 ), "N ", Space( 15 ) } )
												EndIf

											EndIf
										End

										DBSelectArea( cTRBTNF )
										DBSetOrder( 2 )
										DBSeek( " " )

										While !Eof() .And. (cTRBTNF)->SITUAC == " "

											If lEpiObr

												If (cTRBTNF)->DTINI >= dDtEficaz
													aAdd( aEPIS, { (cTRBTNF)->DTINI, (cTRBTNF)->DTDEVO, (cTRBTNF)->NUMCAP, (cTRBTNF)->PROTEC,;
														(cTRBTNF)->CODEPI, (cTRBTNF)->PRZTNF, (cTRBTNF)->PRZDUR, (cTRBTNF)->HIGIEN } )
												ElseIf dDtEficaz <= (cTRBTNF)->DTDEVO
													aAdd( aEPIS, { dDtEficaz, (cTRBTNF)->DTDEVO, (cTRBTNF)->NUMCAP, (cTRBTNF)->PROTEC,;
														(cTRBTNF)->CODEPI, (cTRBTNF)->PRZTNF, (cTRBTNF)->PRZDUR, (cTRBTNF)->HIGIEN } )
												EndIf

											Else
												aAdd( aEpis, { ( cTRBTNF )->DTINI, ( cTRBTNF )->DTDEVO, ( cTRBTNF )->NUMCAP, 'N ',;
													( cTRBTNF )->CODEPI, (cTRBTNF)->PRZTNF, (cTRBTNF)->PRZDUR, (cTRBTNF)->HIGIEN } )
											EndIf

											DBSelectArea( cTRBTNF )
											DBSkip()
										End

										For xEpis := 1 to Len( aEPIS )

											// Adiciona no array as posições faltantes
											If Len( aEpis[ xEpis ] ) == 5
												aAdd( aEpis[ xEpis ], aEpis[ xEpis, 4 ] )
												aAdd( aEpis[ xEpis ], aEpis[ xEpis, 4 ] )
												aAdd( aEpis[ xEpis ], aEpis[ xEpis, 4 ] )
											EndIf

											NGGRAVA700( cFilFun, cFichaM, cCusto, cDepto, cFuncc, Mat, aEPIS[xEpis, 1], aEPIS[xEpis, 2],;
												 aEPIS[xEpis, 3], aEPIS[xEpis, 4], cEmpFun, aEPIS[xEpis, 5], aEPIS[xEpis, 6], aEPIS[xEpis, 7], aEPIS[xEpis, 8] )

										Next xEpis

									Else //Epi esta previsto p/ funcionario e nao foi entregue
										NGGRAVA700( cFilFun, cFichaM, cCusto, cDepto, cFuncc, Mat, dInicioRis, dFimRis, Space( 12 ), "N ", cEmpFun, Space( 15 ) )
									EndIf

								EndIf //Fim - Tem EPI previsto

							EndIf //Fim - Consiste EPI

						Next nW

						DBSelectArea( "TN0" )
						DBSkip()
					EndDo

				EndIf

			Next ny

		Next nx

	EndIf

	If lMudEmpr .And. cEmpFun != cEmpPPP
		EMP700OPEN( "TN0", "TN0", 1, cEmpPPP, @cModo )
		EMP700OPEN( "TNX", "TNX", 1, cEmpPPP, @cModo )
		EMP700OPEN( "TNF", "TNF", 1, cEmpPPP, @cModo )
		EMP700OPEN( "TN3", "TN3", 1, cEmpPPP, @cModo )
		EMP700OPEN( "TMA", "TMA", 1, cEmpPPP, @cModo )
		EMP700OPEN( "SR8", "SR8", 1, cEmpPPP, @cModo )
	EndIf

Return

/*
===============================================================================================================================
Programa--------------: RMDT006()
Autores---------------: Denis Hyroshi de Souza / Gabriel Sokacheski (Totvs)
Conversão para Italac-: Julio de Paula Paz
Data da Criacao-------: 22/09/2023
Descrição-------------: Busca as tarefas do funcionario no periodo
Parametros------------: Fil, Caracter, Filial do funcionario
                        Mat, Caracter, Matricula do funcionario
                        dDTde, Date, Data inicio do periodo das tarefas
                        dDTate, Date, Data fim do periodo das tarefas
                        cCusto, Caracter, Codigo do centro de custo do funcionario
                        cDepto, Caracter, Codigo do departamento do funcionario
                        cFuncc, Caracter, Codigo da funcao do funcionario
                        cFicha, Caracter, Numero da ficha medica do funcionario
                        cEmpNG, Caracter, Empresa no sistema
Retorno---------------: Nenhum
===============================================================================================================================
*/

Static Function NG700TAREF( Fil, Mat, dDTde, dDTate, cCusto, cDepto, cFuncc, cFicha, cEmpNG )

	Local cTarefa := "*"
	Local cModoTN6
	Local cXFilTN6

	_cEmpNG := cEmpNG
	_Fil    := Fil
	_cFicha := cFicha
	_cCusto := cCusto
	_cDepto := cDepto
	_cFuncc := cFuncc
	_Mat := Mat
	_dDTinicio  := dDTde
	_dDTfim := dDTate
	lStart  := .F.

	If lMudEmpr .And. _cEmpNG != cEmpPPP
		cModo := FWModeAccess( "TN6" )
		EMP700OPEN( "TN6", "TN6", 1, _cEmpNG, @cModo, Fil )
	EndIf

	cModoTN6 := f700RetCom( "TN6" )
	cXFilTN6 := FwxFilial( "TN6", _Fil, SubStr( cModoTN6, 1, 1 ), SubStr( cModoTN6, 2, 1 ), SubStr( cModoTN6, 3, 1 ) )

	// Busca os riscos que o funcinario esta exposto nessas condicoes
	DBSelectArea( "TN6" )
	DBSetOrder( 2 )
	DBSeek( cXFilTN6 + _Mat )

	While !Eof() .And. cXFilTN6 == TN6->TN6_FILIAL .And. _Mat == TN6->TN6_MAT

		_dDTinicio  := dDTde
		_dDTfim := dDTate

		If TN6->TN6_DTINIC > _dDTfim .Or. (TN6->TN6_DTTERM < _dDTinicio  .And. !Empty( TN6->TN6_DTTERM ))
			DBSelectArea( "TN6" )
			DBSkip()
			Loop
		EndIf

		If TN6->TN6_DTINIC >= _dDTinicio  .And. TN6->TN6_DTINIC <= _dDTfim
			lStart  := .T.

			If TN6->TN6_DTTERM < _dDTfim .And. !Empty( TN6->TN6_DTTERM )
				_dDTfim := TN6->TN6_DTTERM
			EndIf

			_dDTinicio := TN6->TN6_DTINIC

		ElseIf TN6->TN6_DTINIC < _dDTinicio .And. (TN6->TN6_DTTERM >= _dDTinicio .Or. Empty( TN6->TN6_DTTERM ))
			lStart  := .T.

			If TN6->TN6_DTTERM < _dDTfim .And. !Empty( TN6->TN6_DTTERM )
				_dDTfim := TN6->TN6_DTTERM
			EndIf

		EndIf

		cTarefa := TN6->TN6_CODTAR

		If lStart
			NG700RISCO( _Fil, _cFicha, cTarefa, _cCusto, _cDepto, _cFuncc, _Mat, _dDTinicio, _dDTfim, 1, _cEmpNG )
		EndIf

		DBSelectArea( "TN6" )
		DBSkip()
	EndDo

	If lMudEmpr .And. _cEmpNG != cEmpPPP
		EMP700OPEN( "TN6", "TN6", 1, cEmpPPP, @cModo )
	EndIf

	cTarefa := PadR( "*", nSizeTN5 )
	NG700RISCO( _Fil, _cFicha, cTarefa, _cCusto, _cDepto, _cFuncc, _Mat, _dDTinicio, _dDTfim, 1, _cEmpNG )

Return

/*
===============================================================================================================================
Programa--------------: RMDT006()
Autores---------------: Denis Hyroshi de Souza / Gabriel Sokacheski (Totvs)
Conversão para Italac-: Julio de Paula Paz
Data da Criacao-------: 22/09/2023
Descrição-------------: Grava arquivo de trabalho contendo os riscos do funcionario
Parametros------------: cFilFun, Caracter, Filial do funcionario
                        cFichaM, Caracter, Numero da ficha medica do funcionario
                        cCusto, Caracter, Codigo do centro de custo do funcionario 
                        cDepto, Caracter, Codigo do departamento do funcionario
                        cFuncc, Caracter, Codigo da funcao do funcionario
                        Mat, Caracter, Matricula do funcionario
                        dInicioRis, Date, Inicio do periodo de exposicao aos riscos que serao gravados
                        dFimRis, Date, Fim do periodo de exposicao aos riscos que serao gravados
                        cNUMCAP, Caracter, Numero do certificado de aprovacao do epi relacionado ao risco
                        cEpiFunc, Caracter, Indica se há EPI eficaz
                        cEmpFun, Caracter, Empresa do sistema
                        cCodEPI, Caracter, Codigo do Epi relacionado ao risco
                        cPrazoTNF, Caracter, Prazo de validade do EPI
                        cPrazoDur, Caracter, Durabilidade do EPI
                        cHigiene, Caracter, Indica se EPI teve higienização
                        cFilRis, Caracter, Filial do funcionario

Retorno---------------: Nenhum
===============================================================================================================================
*/
Static Function NGGRAVA700( cFilFun, cFichaM, cCusto, cDepto, cFuncc, Mat, dInicioRis, dFimRis, cNUMCAP, cEpiFunc, cEmpFun, cCodEPI, cPrazoTNF, cPrazoDur, cHigiene, cFilRis )

	Local lSave  := .F.
	Local lAchouRisco := .F.
	Local cEXPOSICAO := " "
	Local cModoTMA, cXFilTMA
	Local nAtual := 0
	Local nTotalFch := 0
	Local nTotalAbr := 0
	Local cUnidade := ""

	Private lEpiFunc := SubStr( cEpiFunc, 1, Len( cEpiFunc ) )
	Private lEpcFunc := TN0->TN0_EPC
	Private _cNUMCAP := cNUMCAP
	Private cTECNICA := Space( 40 )
	Default cCodEpi := ""
	Private _cCodEpi := cCodEPI

	cCondRis := cFilFun+TN0->TN0_NUMRIS+DToS( dInicioRis )+DToS( dFimRis )+cFichaM+cEmpFun

	If aScan( aRiscos, { |x| x[1]+x[2]+DToS( x[3] )+DToS( x[4] )+x[5]+x[7] == cCondRis } ) <= 0
		aAdd( aRiscos, { cFilFun, TN0->TN0_NUMRIS, dInicioRis, dFimRis, cFichaM, TN0->TN0_AGENTE, cEmpFun } ) // Adiciona o numero do risco na array aRISCOS
	EndIf

	cEXPOSICAO := TN0->TN0_INDEXP
	cTECNICA := TN0->TN0_TECUTI+Space( 40 - Len( TN0->TN0_TECUTI ) )
	cEpiant := " "
	cModoTMA := f700RetCom( "TMA" )
	cXFilTMA := FwxFilial( "TMA", cFilFun, SubStr( cModoTMA, 1, 1 ), SubStr( cModoTMA, 2, 1 ), SubStr( cModoTMA, 3, 1 ) )

	DBSelectArea( "TMA" )
	DBSetOrder( 1 )

	If !DBSeek( cXFilTMA+TN0->TN0_AGENTE )
		Return .T.
	EndIf

	cNOME_AGENTE := 'TMA->TMA_NOMAGE'

	// Se For agente quimico, pegar a substancia ativa como descricao.
	If TMA->TMA_GRISCO == "2" .And. !Empty( TMA->TMA_SUBATI )
		cNOME_AGENTE := 'SubStr(TMA->TMA_SUBATI,1,40)'
	EndIf

	cKeyRisco := 'TMA->TMA_GRISCO+'+cNOME_AGENTE+'+Str(TN0->TN0_QTAGEN,nQTAGENt,nQTAGENd)+'
	cKeyRisco += 'cTECNICA+lEpcFunc+lEpiFunc+_cCodEpi+_cNUMCAP'

	DBSelectArea( cTRBTN0 )
	DBSetOrder( 2 )  // GRISCO + AGENTE + Str(INTENS,9,3) + TECNIC + EPC + PROTEC + CODEPI + NUMCAP

	If !DBSeek( &cKeyRisco )
		lSave  := .T.
	Else
		dtstart := dInicioRis
		dtstop  := dFimRis
		nRecOld := Nil
		DBSelectArea( cTRBTN0 )
		DBSetOrder( 2 )
		DBSeek( &cKeyRisco )
		While !Eof() .And. &cKeyRisco == (cTRBTN0)->(GRISCO+AGENTE+Str( INTENS, nQTAGENt, nQTAGENd )+TECNIC+EPC+PROTEC+CODEPI+NUMCAP)


			If (cTRBTN0)->DT_DE <= dtstart .And. (cTRBTN0)->DT_ATE >= dtstart-1

				If dtStop > (cTRBTN0)->DT_ATE
					RecLock( cTRBTN0, .F. )
						(cTRBTN0)->DT_ATE := dtstop
						dtstart := (cTRBTN0)->DT_DE
					MSUnLock()
					aAreaTRB := (cTRBTN0)->(GetArea())

					If nRecOld != nil
						DBSelectArea( cTRBTN0 )
						DBGoTo( nRecOld )
						(cTRBTN0)->(Dbdelete())
					EndIf

					FWRestArea( aAreaTRB )
				EndIf

				lAchouRisco := .T.
				nRecOld := Recno()

			ElseIf (cTRBTN0)->DT_DE <= dtstop + 1 .And. (cTRBTN0)->DT_ATE >= dtstop

				If dtstart < (cTRBTN0)->DT_DE
					RecLock( cTRBTN0, .F. )
						(cTRBTN0)->DT_DE := dtstart
						dtstop := (cTRBTN0)->DT_ATE
					MSUnLock()
					aAreaTRB := (cTRBTN0)->(GetArea())

					If nRecOld != Nil
						DBSelectArea( cTRBTN0 )
						DBGoTo( nRecOld )
						(cTRBTN0)->(Dbdelete())
					EndIf

					FWRestArea( aAreaTRB )
				EndIf

				lAchouRisco := .T.
				nRecOld := Recno()

			ElseIf (cTRBTN0)->DT_DE > dtstart .And. (cTRBTN0)->DT_ATE < dtstop
				RecLock( cTRBTN0, .F. )
					(cTRBTN0)->DT_DE := dtstart
					(cTRBTN0)->DT_ATE := dtstop
				MSUnLock()
				aAreaTRB := (cTRBTN0)->(GetArea())

				If nRecOld != nil
					DBSelectArea( cTRBTN0 )
					DBGoTo( nRecOld )
					(cTRBTN0)->(dbDelete())
				EndIf

				FWRestArea( aAreaTRB )
				lAchouRisco := .T.
				nRecOld := Recno()
			EndIf

			DBSkip()
		End

		If !lAchouRisco
			lSave := .T.
		EndIf

	EndIf

	If lSave

		// Procura pela sigla da Unidade de Medida (TN0 / V3F)
		DBSelectArea( "V3F" )
		DBSetOrder( 2 ) // V3F_FILIAL + V3F_CODIGO + DToS(V3F_VALIDA)
		DBSeek( xFilial( "V3F" ) + TN0->TN0_UNIMED )
		cUnidade := AllTrim( SubStr( V3F->V3F_DESCRI, At( "-", V3F->V3F_DESCRI ) + 1, Len( V3F->V3F_DESCRI ) ) ) // Eliminacao do codigo na descricao

		// Percorre todas as letras da palavra de tras pra frente a partir do ultimo ")"
		For nAtual := RAt( ")", cUnidade ) To 1 Step -1

			If SubStr( cUnidade, nAtual, 1 ) == ")"
				nTotalFch++
			EndIf

			If SubStr( cUnidade, nAtual, 1 ) == "("
				nTotalAbr++

				If nTotalAbr == nTotalFch // Quando encontrar a sigla completa
					cUnidade := SubStr( cUnidade, nAtual + 1, (RAt( ")", cUnidade ) - 1 ) - (nAtual) )
					Exit
				EndIf

			EndIf

		Next

		DBSelectArea( cTRBTN0 )
		(cTRBTN0)->(dbAppend())
		(cTRBTN0)->NUMRIS := TN0->TN0_NUMRIS
		(cTRBTN0)->CODAGE := TN0->TN0_AGENTE

		If !Empty( TMA->TMA_SUBATI ) .And. TMA->TMA_GRISCO == "2"
			(cTRBTN0)->AGENTE := SubStr( TMA->TMA_SUBATI, 1, 40 )
		Else
			(cTRBTN0)->AGENTE := TMA->TMA_NOMAGE
		EndIf

		(cTRBTN0)->GRISCO := TMA->TMA_GRISCO
		(cTRBTN0)->NUMCAP := _cNUMCAP
		(cTRBTN0)->MAT    := cMatric
		(cTRBTN0)->DT_DE  := dInicioRis
		(cTRBTN0)->DT_ATE := dFimRis
		(cTRBTN0)->SETOR  := _centrCusto
		(cTRBTN0)->DEPTO  := _cDepto
		(cTRBTN0)->FUNCAO := _cFuncc
		(cTRBTN0)->TAREFA := _cTarefa
		(cTRBTN0)->INTENS := TN0->TN0_QTAGEN   //Transform(TN0->TN0_QTAGEN,cQTAGtra)
		(cTRBTN0)->UNIDAD := IIf( !Empty( cUnidade ), cUnidade, TN0->TN0_UNIMED )
		(cTRBTN0)->TECNIC := SubStr( cTECNICA, 1, 40 )
		(cTRBTN0)->PROTEC := lEpiFunc
		(cTRBTN0)->EPC    := lEpcFunc
		(cTRBTN0)->INDEXP := cEXPOSICAO
		(cTRBTN0)->ATIVO  := "S"

		If TN0->(FieldPos( "TN0_OBSINT" )) > 0//Campo especifico
			(cTRBTN0)->OBSINT := TN0->TN0_OBSINT
		EndIf

		(cTRBTN0)->CODEPI := _cCodEpi
		(cTRBTN0)->AVALIA := TMA->TMA_AVALIA
		(cTRBTN0)->MEDCON := TN0->TN0_MEDCON
		( cTRBTN0 )->TIPCTR := fVlMedCon( cFilRis )
		(cTRBTN0)->NECEPI := TN0->TN0_NECEPI
		(cTRBTN0)->PRZTNF := cPrazoTNF
		(cTRBTN0)->PRZDUR := cPrazoDur
		(cTRBTN0)->HIGIEN := cHigiene


		// Verifica se existe algum EPI necessário
		DBSelectArea( "TNX" )
		DBSetOrder( 2 ) // TNX_FILIAL+TNX_NUMRIS

		If DBSeek( xFilial( "TNX", cXFilTNX )+(cTRBTN0)->NUMRIS )
			lEpiNec := .T.
		EndIf

		DBSelectArea( "TJF" )
		DBSetOrder( 1 )
		DBSeek( xFilial( "TJF", cXFilTJF ) + (cTRBTN0)->NUMRIS )
		While TJF->( !Eof() ) .And. TJF->TJF_FILIAL == xFilial( "TJF", cXFilTJF ) .And. TJF->TJF_NUMRIS == (cTRBTN0)->NUMRIS

			If NgSeek( "TO4", TJF->TJF_MEDCON, 1, "TO4_TIPCTR", cXFilTO4 ) == "2" .Or. NgSeek( "TO4", TJF->TJF_MEDCON, 1, "TO4_TIPCTR", cXFilTO4 ) == "1" 
				lEpcNec := .T.
				Exit
			EndIf

			TJF->( DBSkip() )
		End

		If xm_par29 == 2 // Somente quem gerou o laudo para o risco
			aRespLaudo := {}
			DBSelectArea( "TO1" )
			DBSetOrder( 2 ) // TO1->TO1_FILIAL+TO1->TO1_NUMRIS+TO1->TO1_LAUDO
			DBSeek( xFilial( "TO1" ) + TN0->TN0_NUMRIS )

			While !Eof() .And. xFilial( "TO1" ) == TO1->TO1_FILIAL .And. TN0->TN0_NUMRIS == TO1->TO1_NUMRIS//Laudos X Risco
				DBSelectArea( "TO0" )
				DBSetOrder( 1 )
				DBSeek( xFilial( "TO0" ) + TO1->TO1_LAUDO )

				If aScan( aRespLaudo, { | x | x == TO0->TO0_CODUSU } ) == 0 // Se o código For diferente add no array
					aAdd( aRespLaudo, TO0->TO0_CODUSU )
				EndIf

				DBSelectArea( "TO1" )
				DBSkip()
			End

		EndIf

	EndIf

Return

/*
===============================================================================================================================
Programa--------------: RMDT006()
Autores---------------: Denis Hyroshi de Souza / Gabriel Sokacheski (Totvs)
Conversão para Italac-: Julio de Paula Paz
Data da Criacao-------: 22/09/2023
Descrição-------------: Imprime a descricao das Atividades.
Parametros------------: Nenhum
Retorno---------------: Nenhum
===============================================================================================================================
*/
Static Function ATIV700R()

	Private cCodCustoCar := ""
	Private lCusto := .F.

	If xm_par08 == 1 //Desc. das Atividad.? //"Tarefa"

		If !IMPTAR700()

			If IMPCGO700()
				Return .T.
			EndIf

		Else
			Return .T.
		EndIf

	ElseIf xm_par08 == 2 //Desc. das Atividad.?//"Cargo"

		If !IMPCGO700()

			If IMPTAR700()
				Return .T.
			EndIf

		Else
			Return .T.
		EndIf

	ElseIf xm_par08 == 4 //Desc. das Atividad.?//"Funcao"

		If !IMPFUN700()

			If !IMPCGO700()

				If IMPTAR700()
					Return .T.
				EndIf

			Else
				Return .T.
			EndIf

		Else
			Return .T.
		EndIf

	Else //"Cargo e Tarefa"

		If IMPTAR700()
			IMPCGO700()
			Return .T.
		ElseIf IMPCGO700()
			Return .T.
		EndIf

	EndIf

Return .F.

/*
===============================================================================================================================
Programa--------------: RMDT006()
Autores---------------: Denis Hyroshi de Souza / Gabriel Sokacheski (Totvs)
Conversão para Italac-: Julio de Paula Paz
Data da Criacao-------: 22/09/2023
Descrição-------------: Executa a impressao da secao de tarefas
Parametros------------: Nenhum
Retorno---------------: Nenhum
===============================================================================================================================
*/
Static Function IMPTAR700()
	Local aTarFunc := {}
	Local aImpDesc	:= {}
	Local aDatasPPP := {}
	Local lRetorno := .F.
	Local cModoTN5
	Local cModoTN6
	Local cFilTN5
	Local cFilTN6
	Local lDescriTN5:= "!Empty(TN5->TN5_DESCRI)"
	Local nTar
	Local nTary
	Local nDesc
	Local LinhaCorrente

	nLinTar := 3

	For nTar := 1 to Len( aMatriculas )

		If lMudEmpr .And. aMatriculas[nTar, 3] != cEmpPPP
			cModo := FWModeAccess( "TN6" )
			EMP700OPEN( "TN6", "TN6", 1, aMatriculas[nTar, 3], @cModo, aMatriculas[nTar, 1] )
			cModo := FWModeAccess( "TN5" )
			EMP700OPEN( "TN5", "TN5", 1, aMatriculas[nTar, 3], @cModo, aMatriculas[nTar, 1] )
		EndIf

		cModoTN5 := f700RetCom( "TN5" )
		cModoTN6 := f700RetCom( "TN6" )

		cFilTN5 := FwxFilial( "TN5", aMatriculas[nTar, 1], SubStr( cModoTN5, 1, 1 ), SubStr( cModoTN5, 2, 1 ), SubStr( cModoTN5, 3, 1 ) )
		cFilTN6 := FwxFilial( "TN6", aMatriculas[nTar, 1], SubStr( cModoTN6, 1, 1 ), SubStr( cModoTN6, 2, 1 ), SubStr( cModoTN6, 3, 1 ) )

		DBSelectArea( "TN6" )
		DBSetOrder( 2 )// TN6_FILIAL+TN6_MAT
		DBSeek( cFilTN6+aMatriculas[nTar, 2] )

		While !Eof() .And. cFilTN6 == TN6->TN6_FILIAL .And. aMatriculas[nTar, 2] == TN6->TN6_MAT

			If TN6->TN6_DTINIC > dDataBase .Or. (TN6->TN6_DTTERM < dDtAdmiss  .And. !Empty( TN6->TN6_DTTERM ))
				DBSelectArea( "TN6" )
				DBSkip()
				Loop
			EndIf

			DBSelectArea( "TN5" )
			DBSetOrder( 1 )

			If DBSeek( cFilTN5+TN6->TN6_CODTAR )

				If &lDescriTN5
					_dDTfim    := TN6->TN6_DTTERM
					_dDTinicio := TN6->TN6_DTINIC

					If TN6->TN6_DTINIC < dDtAdmiss
						_dDTinicio := dDtAdmiss
					EndIf

					If TN6->TN6_DTTERM > dDataBase
						_dDTfim := dDataBase
					EndIf

					aAdd( aTarFunc, { SubStr( TN5->TN5_NOMTAR, 1, 40 ), TN6->TN6_CODTAR, aMatriculas[nTar, 1], _dDTinicio, _dDTfim, aMatriculas[nTar, 3] } )
				EndIf

			EndIf

			DBSelectArea( "TN6" )
			DBSkip()
		End

		If lMudEmpr .And. aMatriculas[nTar, 3] != cEmpPPP
			EMP700OPEN( "TN6", "TN6", 1, cEmpPPP, @cModo )
			EMP700OPEN( "TN5", "TN5", 1, cEmpPPP, @cModo )
		EndIf

	Next nTar

	// Ordenando tarefas por ordem cronologica
	For nTar := 1 to Len( aTarFunc )-1

		For nTary := nTar+1 To Len( aTarFunc )

			If aTarFunc[nTar, 4] > aTarFunc[nTary, 4]
				aTemp           := aClone( aTarFunc[nTar] )
				aTarFunc[nTar]  := aClone( aTarFunc[nTary] )
				aTarFunc[nTary] := aClone( aTemp )
			EndIf

		Next nTary

	Next nTar

	// Se existir no dicionario TN5_DESCRI, imprimira o campo memo
	aAdd( aImpDesc, { 'TN5_DESCRI' } )

	For nTar := 1 to Len( aTarFunc )

		If lMudEmpr .And. aTarFunc[nTar, 6] != cEmpPPP
			cModo := FWModeAccess( "TN5" )
			EMP700OPEN( "TN5", "TN5", 1, aTarFunc[nTar, 6], @cModo, aTarFunc[nTar, 3] )
		EndIf

		cModoTN5 := f700RetCom( "TN5" )
		cFilTN5 := FwxFilial( "SQ3", aTarFunc[nTar, 3], SubStr( cModoTN5, 1, 1 ), SubStr( cModoTN5, 2, 1 ), SubStr( cModoTN5, 3, 1 ) )

		DBSelectArea( "TN5" )
		DBSetOrder( 1 )

		If !DBSeek( cFilTN5+aTarFunc[nTar, 2] )

			If lMudEmpr .And. aTarFunc[nTar, 6] != cEmpPPP
				EMP700OPEN( "TN5", "TN5", 1, cEmpPPP, @cModo )
			EndIf

			Loop
		EndIf

		aDatasPPP := fDesagData( aTarFunc[nTar, 4], IIf( Empty( aTarFunc[nTar, 5] ), dDtDemiss, aTarFunc[nTar, 5] ) )
		lTemDesc := .F.

		For nTary := 1 To Len( aDatasPPP )

			For nDesc := 1 To Len( aImpDesc[1] )
				nLinhasMemo := MlCount( TN5->&(aImpDesc[1][nDesc]), 140 )

				For LinhaCorrente := 1 To nLinhasMemo

					If nDesc == 1 .And. LinhaCorrente == 1
						lTemDesc := .T.
						oPrintPPP:Line( lin, 50, lin + 50, 50 )
						oPrintPPP:Say( lin + 30, 60, aDatasPPP[nTary], oFont09 )
						oPrintPPP:Line( lin, 550, lin + 50, 550 )

						If xm_par33 == 1 // Titulo da tarefa
							oPrintPPP:Say( lin + 30, 560, SubStr( TN5->TN5_NOMTAR, 1, 40 ), oFont08 )
							oPrintPPP:Line( lin, 2940, lin + 50, 2940 )
							SomaLinha( 50, .T. )
						EndIf

					EndIf

					If nDesc > 1 .And. !lTemDesc
						Exit
					EndIf

					If !Empty( MemoLine( TN5->&( aImpDesc[1][nDesc]), 140, LinhaCorrente ) )
						lRetorno := .T.
						oPrintPPP:Line( lin, 50, lin + 40, 50 )
						oPrintPPP:Line( lin, 550, lin + 40, 550 )
						oPrintPPP:Line( lin, 2940, lin + 40, 2940 )
						oPrintPPP:Say( lin + 30, 560, Transform( MemoLine( TN5->&(aImpDesc[1][nDesc] ), 140, LinhaCorrente ), "@!" ), oFont07_ )
						SomaLinha( 40, .T. )
					EndIf

				Next LinhaCorrente

			Next nDesc

			If lRetorno .And. lin != 380
				oPrintPPP:Line( lin, 50, lin, 2940 )
			EndIf

		Next nTary

		If lMudEmpr .And. aTarFunc[nTar, 6] != cEmpPPP
			EMP700OPEN( "TN5", "TN5", 1, cEmpPPP, @cModo )
		EndIf

	Next nTar

Return lRetorno

/*
===============================================================================================================================
Programa--------------: RMDT006()
Autores---------------: Denis Hyroshi de Souza / Gabriel Sokacheski (Totvs)
Conversão para Italac-: Julio de Paula Paz
Data da Criacao-------: 22/09/2023
Descrição-------------: Executa a impressao da secao de cargos
Parametros------------: Nenhum
Retorno---------------: Logico, .T. se houve a impressao de algum cargo
===============================================================================================================================
*/
Static Function IMPCGO700()

	Local LinhaCorrente
	Local nFx
	Local nX
	Local lRetorno := .F.
	Local lFirst := .T.
	Local dIniCar
	Local dFimCar
	Local cFilialCar
	Local dDataIni
	Local dDataFim
	Local aDatasPPP := {}
	Local cModoSQ3
	Local cFilSQ3

	DBSelectArea( cTRBPPP )
	DBGoTop()

	While !Eof()

		Store CtoD( "  /  /    " ) to dIniCar, dFimCar
		cCodCargo := (cTRBPPP)->CARGO
		cEmpCargo := (cTRBPPP)->EMP
		cFilialCar:= SubStr( (cTRBPPP)->FILIAL, 1, FwSizeFilial( (cTRBPPP)->EMP ) )

		If lMudEmpr .And. (cTRBPPP)->EMP != cEmpPPP
			cModo := FWModeAccess( "SQ3" )
			EMP700OPEN( "SQ3", "SQ3", 1, (cTRBPPP)->EMP, @cModo, cFilialCar )
		EndIf

		cModoSQ3 := f700RetCom( "SQ3" )
		cFilCargo := FwxFilial( "SQ3", cFilialCar, SubStr( cModoSQ3, 1, 1 ), SubStr( cModoSQ3, 2, 1 ), SubStr( cModoSQ3, 3, 1 ) )

		If lMudEmpr .And. (cTRBPPP)->EMP != cEmpPPP
			EMP700OPEN( "SQ3", "SQ3", 1, cEmpPPP, @cModo )
		EndIf

		cCusCargo := CARGOCC700( (cTRBPPP)->EMP, cFilialCar, (cTRBPPP)->CARGO, (cTRBPPP)->CUSTO )
		lFirst := .T.

		While !Eof() .And. cCusCargo == CARGOCC700( (cTRBPPP)->EMP, cFilialCar, (cTRBPPP)->CARGO, (cTRBPPP)->CUSTO )

			If lFirst
				dIniCar := (cTRBPPP)->DTDE
				dFimCar := (cTRBPPP)->DTATE
				lFirst  := .F.
			Else

				If dFimCar < (cTRBPPP)->DTATE
					dFimCar := (cTRBPPP)->DTATE
				EndIf

			EndIf

			DBSelectArea( cTRBPPP )
			DBSkip()
		End

		aAdd( aCargo, { dIniCar, dFimCar, cFilCargo, cCodCargo, cCusCargo, cEmpCargo, cCodCustoCar } )
		lCusto := .F.
	End

	For nFx := 1 To Len( aCargo )

		If lMudEmpr .And. aCargo[nFx, 6] != cEmpPPP
			cModo := FWModeAccess( "SQ3" )
			EMP700OPEN( "SQ3", "SQ3", 1, aCargo[nFx, 6], @cModo, aCargo[nFx][3] )
			cModo := FWModeAccess( "SYP" )
			EMP700OPEN( "SYP", "SYP", 1, aCargo[nFx, 6], @cModo, aCargo[nFx][3] )
		EndIf

		cModoSQ3 := f700RetCom( "SQ3" )
		cFilSQ3 := FwxFilial( "SQ3", aCargo[nFx][3], SubStr( cModoSQ3, 1, 1 ), SubStr( cModoSQ3, 2, 1 ), SubStr( cModoSQ3, 3, 1 ) )

		DBSelectArea( "SQ3" )
		DBSetOrder( 1 )

		If DBSeek( cFilSQ3+aCargo[nFx][4]+aCargo[nFx][7] )

			dDataIni := aCargo[nFx][1]

			If aCargo[nFx][1] == aCargo[nFx][2]
				dDataFim := aCargo[nFx][2]
			Else
				dDataFim := aCargo[nFx][2] - 1
			EndIf

			If !fVerAte()
				dDataFim := IIf( nFx == Len( aCargo ), IIf( !lDemitido, CToD( '//' ), aCargo[ nFx, 2 ] ), dDataFim )
			Else
				dDataFim := aCargo[ nFx, 2 ]
			EndIf

			aDatasPPP := fDesagData( dDataIni, dDataFim )
			cMemo := MSMM( SQ3->Q3_DESCDET, , , , , , , , , "RDY" )
			nLinhasMemo := IIf( Empty( cMemo ), 1, MLCOUNT( cMemo, 100 ) )

			If !lNG2M400
				nLinhasMemo := IIf( nLinhasMemo > 5, 5, nLinhasMemo )
			EndIf

			For nX := 1 To Len( aDatasPPP )

				For linhaCorrente := 1 To nLinhasMemo
					lRetorno := .T.

					If linhaCorrente == 1
						oPrintPPP:Line( lin, 50, lin + 50, 50 )
						oPrintPPP:Say( lin + 30, 60, aDatasPPP[ nX ], oFont09 )
						oPrintPPP:Line( lin, 550, lin + 50, 550 )

						If xm_par33 == 1 // Titulo do cargo
							oPrintPPP:Say( lin + 30, 560, Transform( SQ3->Q3_DESCSUM, "@!" ), oFont08 )
							oPrintPPP:Line( lin, 2940, lin + 50, 2940 )
							SomaLinha( 50, .T. )
						EndIf

					EndIf

					oPrintPPP:Line( lin, 50, lin + 40, 50 )
					oPrintPPP:Line( lin, 550, lin + 40, 550 )
					oPrintPPP:Line( lin, 2940, lin + 40, 2940 )
					oPrintPPP:Say( lin + 30, 560, Transform( MemoLine( cMemo, 140, LinhaCorrente ), "@!" ), oFont07_ )

					If LinhaCorrente == nLinhasMemo
						oPrintPPP:Line( lin + 40, 50, lin + 40, 2940 )
					EndIf

					SomaLinha( 40, linhaCorrente != nLinhasMemo )

				Next LinhaCorrente

			Next nX

		EndIf

		If lMudEmpr .And. aCargo[nFx, 6] != cEmpPPP
			EMP700OPEN( "SQ3", "SQ3", 1, cEmpPPP, @cModo )
			EMP700OPEN( "SYP", "SYP", 1, cEmpPPP, @cModo )
		EndIf

	Next nFx

Return lRetorno

/*
===============================================================================================================================
Programa--------------: RMDT006()
Autores---------------: Denis Hyroshi de Souza / Gabriel Sokacheski (Totvs)
Conversão para Italac-: Julio de Paula Paz
Data da Criacao-------: 22/09/2023
Descrição-------------: Retorna a descricao de um cargo na SQ3
Parametros------------: cEmpresa, Caracter, Codigo da empresa para abrir o arquivo pela EmpOpenFile
                        cFilPar, Caracter, Filial usada para a busca do cargo  
                        cCargo, Caracter, Codigo do cargo
                        cCusto, Caracter, Centro de custo usado para a busca do cargo
Retorno---------------: Caracter, Descricao do cargo pesquisado
===============================================================================================================================
*/
Static Function CARGOCC700(cEmpresa, cFilPar, cCargo, cCusto)

	Local cRet := Space( nSizeSI3 )
	Local aAreaTRBE := (cTRBPPP)->(GetArea())
	Local aAreaSIX  := SIX->(GetArea())
	Local aArea     := FWGetArea()
	Local lTemQ3CC  := .F.
	Local cModoSQ3, cFilSQ3

	lFlagEmp1 := .F.

	If lMudEmpr .And. cEmpresa != cEmpPPP
		lFlagEmp1 := .T.
		cModo := FwModeAccess( "SQ3" )
		EMP700OPEN( "SQ3", "SQ3", 1, cEmpresa, @cModo, cFilPar )
		cModo := FWModeAccess( "SYP" )
		EMP700OPEN( "SYP", "SYP", 1, cEmpresa, @cModo, cFilPar )
	EndIf

	cModoSQ3 := f700RetCom( "SQ3" )
	cFilSQ3  := FwxFilial( "SQ3", cFilPar, SubStr( cModoSQ3, 1, 1 ), SubStr( cModoSQ3, 2, 1 ), SubStr( cModoSQ3, 3, 1 ) )

	DBSelectArea( "SIX" )
	DBSetOrder( 1 )

	If DBSeek( "SQ31" )

		If "Q3_CARGO" $ SIX->CHAVE .And. "Q3_CC" $ SIX->CHAVE
			DBSelectArea( "SQ3" )
			DBSetOrder( 1 )

			If DBSeek( cFilSQ3 + cCargo + cCusto )
				cRet := cCusto + AllTrim( SQ3->Q3_DESCSUM )+SubStr( AllTrim( MSMM( SQ3->Q3_DESCDET, , , , , , , , , "RDY" ) ), 1, 100 )

				If !lCusto
					cCodCustoCar := SQ3->Q3_CC
					lCusto := .T.
				EndIf

				lTemQ3CC := .T.
			EndIf

		EndIf

	EndIf

	If !lTemQ3CC
		DBSelectArea( "SQ3" )
		DBSetOrder( 1 )

		If DBSeek( cFilSQ3+cCargo )
			cRet += AllTrim( SQ3->Q3_DESCSUM ) + SubStr( AllTrim( MSMM( SQ3->Q3_DESCDET, , , , , , , , , "RDY" ) ), 1, 100 )

			If !lCusto
				cCodCustoCar := SQ3->Q3_CC
				lCusto := .T.
			EndIf

		EndIf

	EndIf

	If lFlagEmp1
		EMP700OPEN( "SQ3", "SQ3", 1, cEmpPPP, @cModo )
		EMP700OPEN( "SYP", "SYP", 1, cEmpPPP, @cModo )
	EndIf

	FWRestArea( aAreaTRBE )
	FWRestArea( aAreaSIX )
	FWRestArea( aArea )

Return cRet

/*
===============================================================================================================================
Programa--------------: RMDT006()
Autores---------------: Denis Hyroshi de Souza / Gabriel Sokacheski (Totvs)
Conversão para Italac-: Julio de Paula Paz
Data da Criacao-------: 22/09/2023
Descrição-------------: Faz a impressao das funcoes dos funcionarios
Parametros------------: Nenhum
Retorno---------------: Logico, return_descr
===============================================================================================================================
*/
Static Function IMPFUN700()

	Local lRetorno := .T.
	Local lFirst := .T.
	Local lPerOk := .T.
	Local dIniFun
	Local dFimFun
	Local LinhaCorrente
	Local nFx
	Local nX
	Local dDateAte
	Local cFilialFun
	Local cModoCom := ""
	Local cMemo := ""
	Local cFilBkp := ""
	Local aDatasPPP := {}
	Local cFilFuncao := ""
	Local cEmpFuncao := ""
	Local cCodFuncao := ""
	Local cCodCC     := ""
	Local cCodDepto  := ""
	Local oFontPrint := oFont07_

	DBSelectArea( cTRBPPP )
	DBGoTop()

	While (cTRBPPP)->(!Eof())
		lFlagEmp1 := .F.
		cFilialFun := SubStr( (cTRBPPP)->FILIAL, 1, FwSizeFilial( (cTRBPPP)->EMP ) )

		If lMudEmpr .And. (cTRBPPP)->EMP != cEmpPPP
			lFlagEmp1 := .T.
			cModo := FWModeAccess( "SRJ" )
			EMP700OPEN( "SRJ", "SRJ", 1, (cTRBPPP)->EMP, @cModo, cFilialFun )
			cModo := FWModeAccess( "SYP" )
			EMP700OPEN( "SYP", "SYP", 1, (cTRBPPP)->EMP, @cModo, cFilialFun )
			cModo := FWModeAccess( "RDY" )
			EMP700OPEN( "RDY", "RDY", 1, (cTRBPPP)->EMP, @cModo, cFilialFun )

			If AliasInDic( "TYA" )
				cModo := FWModeAccess( "TYA" )
				EMP700OPEN( "TYA", "TYA", 1, (cTRBPPP)->EMP, @cModo, cFilialFun )
			EndIf

		EndIf

		cModoCom := f700RetCom( "SRJ" )

		// Realizado a troca da Variavel cFilAnt
		// pois estava vindo posicionada sempre na ultima filial
		// assim não encontrava os valores de memo, com essa alteração
		// a filial posicionada sempre será a atual da TRB.
		If cFilAnt <> (cTRBPPP)->FILIAL
			cFilBkp := cFilAnt
			cFilAnt := (cTRBPPP)->FILIAL
		EndIf

		DBSelectArea( "SRJ" )
		Store CtoD( "  /  /    " ) To dIniFun, dFimFun
		cCodCC	   := (cTRBPPP)->CUSTO
		cCodDepto  := (cTRBPPP)->DEPTO
		cCodFuncao := (cTRBPPP)->CODFUN
		cFilFuncao := FwxFilial( "SRJ", cFilialFun, SubStr( cModoCom, 1, 1 ), SubStr( cModoCom, 2, 1 ), SubStr( cModoCom, 3, 1 ) )
		cEmpFuncao := (cTRBPPP)->EMP
		lFirst := .T.

		While (cTRBPPP)->(!Eof()) .And. cCodFuncao == (cTRBPPP)->CODFUN .And. cEmpFuncao == (cTRBPPP)->EMP .And. ;
					FwxFilial( "SRJ", (cTRBPPP)->FILIAL, SubStr( cModoCom, 1, 1 ), SubStr( cModoCom, 2, 1 ), SubStr( cModoCom, 3, 1 ) ) ==;
					FwxFilial( "SRJ", cFilialFun, SubStr( cModoCom, 1, 1 ), SubStr( cModoCom, 2, 1 ), SubStr( cModoCom, 3, 1 ) )
			If lFirst
				dIniFun := (cTRBPPP)->DTDE
				dFimFun := (cTRBPPP)->DTATE
				lFirst  := .F.
			Else
				If dFimFun < (cTRBPPP)->DTATE
					dFimFun := (cTRBPPP)->DTATE
				EndIf
			EndIf

			DBSelectArea( cTRBPPP )
			(cTRBPPP)->(DBSkip())
		End

		// Responsavel por buscar o valor do campo MEMO
		DBSelectArea( "SRJ" )
		DBSetOrder( 1 )
		DBSeek( cFilFuncao + cCodFuncao )

		If SRJ->(FieldPos( "RJ_MEMOATI" )) > 0
			cMemo := SRJ->RJ_MEMOATI
		Else
			cMemo := MSMM( SRJ->RJ_DESCREQ, , , , , , , , , "RDY" )
		EndIf

		If AliasInDic( "TYA" )
			DBSelectArea( "TYA" )
			DBSetOrder( 1 )

			If DBSeek( cFilFuncao + cCodFuncao )

				While TYA->( !Eof() ) .And. TYA->TYA_FILIAL == cFilFuncao .And. ;
					TYA->TYA_CODFUN == cCodFuncao .And. TYA->TYA_PERINI <= dFimFun //Caso tenha um periodo de função menor que o inicio da função.
					lPerOk := .T.

					If TYA->( ColumnPos( "TYA_CC" ) ) > 0

						If ( !Empty( TYA->TYA_CC ) .And. AllTrim( TYA->TYA_CC ) <> AllTrim( cCodCC ) ) .Or. ;
							( !Empty( TYA->TYA_DEPTO ) .And. AllTrim( TYA->TYA_DEPTO ) <> AllTrim( cCodDepto ) )
							lPerOk := .F.
						EndIf

					EndIf

					If lPerOk

						If TYA->TYA_PERINI > dIniFun
							aAdd( aFuncao, { dIniFun, DaySub( TYA->TYA_PERINI, 1 ), cFilFuncao, cCodFuncao, cEmpFuncao, cMemo } )
							dIniFun := TYA->TYA_PERINI
							cMemo := MSMM( TYA->TYA_ODESFU, TamSX3( "TYA_MDESFU" )[1] )
						Else
							cMemo := MSMM( TYA->TYA_ODESFU, TamSX3( "TYA_MDESFU" )[1] )
						EndIf

					EndIf

					TYA->(DBSkip())
				End

			EndIf

		EndIf

		aAdd( aFuncao, { dIniFun, dFimFun, cFilFuncao, cCodFuncao, cEmpFuncao, cMemo } )

		// Caso ocorreu alteração do cFilAnt retorna o valor do backup.
		If cFilAnt <> cFilBkp .And. !Empty( cFilBkp )
			cFilAnt := cFilBkp
		EndIf

		If lFlagEmp1
			EMP700OPEN( "SRJ", "SRJ", 1, cEmpPPP, @cModo )
			EMP700OPEN( "SYP", "SYP", 1, cEmpPPP, @cModo )
			EMP700OPEN( "RDY", "RDY", 1, cEmpPPP, @cModo )

			If AliasInDic( "TYA" )
				EMP700OPEN( "TYA", "TYA", 1, cEmpPPP, @cModo )
			EndIf

		EndIf

	End

	For nFx := 1 to Len( aFuncao )

		If lMudEmpr .And. aFuncao[nFx, 5] != cEmpPPP
			cModo := FWModeAccess( "SRJ" )
			EMP700OPEN( "SRJ", "SRJ", 1, aFuncao[nFx, 5], @cModo, aFuncao[nFx][3] )
			cModo := FWModeAccess( "SYP" )
			EMP700OPEN( "SYP", "SYP", 1, aFuncao[nFx, 5], @cModo, aFuncao[nFx][3] )

			If AliasInDic( "TYA" )
				cModo := FWModeAccess( "TYA" )
				EMP700OPEN( "TYA", "TYA", 1, aFuncao[nFx, 5], @cModo, aFuncao[nFx][3] )
			EndIf

		EndIf

		cModoCom := f700RetCom( "SRJ" )
		DBSelectArea( "SRJ" )
		DBSetOrder( 1 )

		If DBSeek( FwxFilial( "SRJ", aFuncao[nFx][3], SubStr( cModoCom, 1, 1 ), SubStr( cModoCom, 2, 1 ), SubStr( cModoCom, 3, 1 ) )+aFuncao[nFx][4] )

			If Len( aFuncao ) > nFx
				dDateAte :=  aFuncao[nFx + 1 ][1] - 1
			Else
				dDateAte := aFuncao[nFx][2]
			EndIf

			If !fVerAte()
				dDateAte := IIf( nFx == Len( aFuncao ), IIf( !lDemitido, CToD( '//' ), aFuncao[ nFx, 2 ] ), dDateAte )
			Else
				dDateAte := aFuncao[ nFx, 2 ]
			EndIf

			aDatasPPP := fDesagData( aFuncao[nFx][1], dDateAte )
			cMemo := aFuncao[nFx, 6]

			nLinhasMemo := MLCOUNT( cMemo, 140 )

			If !lNG2M400
				nLinhasMemo := IIf( nLinhasMemo > 5, 5, nLinhasMemo )
			EndIf

			For nX := 1 To Len( aDatasPPP )

				For LinhaCorrente := 1 To nLinhasMemo
					lRetorno := .T.

					If LinhaCorrente == 1
						oPrintPPP:Line( lin, 50, lin + 45, 50 )
						oPrintPPP:Say( lin + 30, 60, aDatasPPP[ nX ], oFont09 )
						oPrintPPP:Line( lin, 550, lin + 45, 550 )

						If xm_par33 == 1
							oPrintPPP:Say( lin + 30, 560, Transform( SRJ->RJ_DESC, "@!" ), oFont08 )
							oPrintPPP:Line( lin, 2940, lin + 45, 2940 )
							oFontPrint := oFont08
							SomaLinha( 45 )
						EndIf

					Else
						oFontPrint := oFont07_
					EndIf

					oPrintPPP:Line( lin, 50, lin + 45, 50 )
					oPrintPPP:Line( lin, 550, lin + 45, 550 )
					oPrintPPP:Line( lin, 2940, lin + 45, 2940 )
					oPrintPPP:Say( lin + 30, 560, Transform( MemoLine( cMemo, 140, LinhaCorrente ), "@!" ), oFontPrint )

					If LinhaCorrente == nLinhasMemo
						oPrintPPP:Line( lin + 45, 50, lin + 45, 2940 )
					EndIf

					SomaLinha( 45, LinhaCorrente != nLinhasMemo )
				Next LinhaCorrente

			Next nX

		EndIf

		If lMudEmpr .And. aFuncao[nFx, 5] != cEmpPPP
			EMP700OPEN( "SRJ", "SRJ", 1, cEmpPPP, @cModo )
			EMP700OPEN( "SYP", "SYP", 1, cEmpPPP, @cModo )

			If AliasInDic( "TYA" )
				EMP700OPEN( "TYA", "TYA", 1, cEmpPPP, @cModo )
			EndIf

		EndIf

	Next nFx

Return lRetorno

/*
===============================================================================================================================
Programa--------------: RMDT006()
Autores---------------: Denis Hyroshi de Souza / Gabriel Sokacheski (Totvs)
Conversão para Italac-: Julio de Paula Paz
Data da Criacao-------: 22/09/2023
Descrição-------------: Executa a impressao da secao de Comprovante de entrega
Parametros------------: Nenhum
Retorno---------------: Logico, Sempre .T.
===============================================================================================================================
*/
Static Function MDTERMO700()

	Local cCNPJ

	DBSelectArea( "TM0" )
	DBSetOrder( 3 )
	DBSeek( xFilial( "SRA" ) + SRA->RA_MAT )

	DBSelectArea( cAlias )
	DBSetOrder( 1 )
	DBSeek( xFilial( cAlias ) + SRA->RA_CC )

	DBSelectArea( "SRJ" )
	DBSetOrder( 1 )
	DBSeek( xFilial( "SRJ" ) + SRA->RA_CODFUNC )

	DBSelectArea( "SR6" )
	DBSetOrder( 1 )
	DBSeek( xFilial( "SR6" ) + SRA->RA_TNOTRAB )

	oPrintPPP:StartPage()
	lin := 180
	oPrintPPP:SayAlign( lin + 70, 50, "COMPROVANTE DE ENTREGA DO PERFIL PROFISSIOGRÁFICO PREVIDENCIÁRIO (PPP)", oFont13, 2160, lin + 100, CLR_BLACK, 2, 1 ) // "COMPROVANTE DE ENTREGA DO PERFIL PROFISSIOGRÁFICO PREVIDENCIÁRIO ( PPP)" STR0238
	oPrintPPP:Box( lin + 200, 50, lin + 580, 2940 )
	oPrintPPP:Say( lin + 260, 60, "DADOS ADMINISTRATIVOS", oFont13 ) // "DADOS ADMINISTRATIVOS" STR0239
	oPrintPPP:Line( lin + 280, 50, lin + 280, 2940 )
	oPrintPPP:Line( lin + 280, 800, lin + 380, 800 )
	oPrintPPP:Line( lin + 280, 2000, lin + 380, 2000 )
	// "CNPJ do Domicílio Tributário/CEI/CAEPF/CNO"
	oPrintPPP:Say( lin + 310, 60, Memoline( "CNPJ do Domicílio Tributário/CEI/CAEPF/CNO", 41, 1 ), oFont09n ) // STR0240
	oPrintPPP:Say( lin + 340, 60, Memoline( "CNPJ do Domicílio Tributário/CEI/CAEPF/CNO", 41, 2 ), oFont09n ) // STR0240

	// Ponto de entrada RMDT0063 para CNPJ
	If ExistBlock( "RMDT0063" )
		cCNPJ:= ExecBlock( "RMDT0063", .F., .F. )
	EndIf

	// Caso não teha ponto de entrada
	If ValType( cCNPJ ) <> "C" .Or. Empty( cCNPJ )

		If lNGMDTPS .Or. lSigaMdtps
			cCNPJ:= SA1->A1_CGC
		Else
			cCNPJ:= SM0->M0_CGC
		EndIf

	EndIf

	If !Empty( cCNPJ )

		If lNGMDTPS .Or. lSigaMdtps
			oPrintPPP:Say( lin + 370, 60, Transform( cCNPJ, "@R! NN.NNN.NNN/NNNN-99" ), oFont10 )
		Else

			If SM0->M0_TPINSC != 2
				oPrintPPP:Say( lin + 370, 60, Transform( cCNPJ, "@R 99.999.99999/99" ), oFont10 )
			Else
				oPrintPPP:Say( lin + 370, 60, Transform( cCNPJ, "@R! NN.NNN.NNN/NNNN-99" ), oFont10 )
			EndIf

		EndIf

	EndIf

	oPrintPPP:Say( lin + 310, 810, "Nome Empresarial", oFont09 ) // "Nome Empresarial" STR0241

	If lNGMDTPS .Or. lSigaMdtps
		oPrintPPP:Say( lin + 370, 810, SubStr( SA1->A1_NOME, 1, 40 ), oFont10 )
	Else
		oPrintPPP:Say( lin + 370, 810, SubStr( SM0->M0_NOMECOM, 1, 40 ), oFont10 )
	EndIf

	oPrintPPP:Say( lin + 310, 2010, "CNAE", oFont09 )

	If lNGMDTPS .Or. lSigaMdtps
		nSizeCNAE := Len( AllTrim( SA1->A1_ATIVIDA ) )

		If nSizeCNAE > 5
			oPrintPPP:Say( lin + 370, 2010, Transform( SA1->A1_ATIVIDA, "@R 99.99-9/99" ), oFont10 )
		ElseIf Empty( SA1->A1_ATIVIDA )
			oPrintPPP:Say( lin + 370, 2010, "NA", oFont10 )
		Else
			oPrintPPP:Say( lin + 370, 2010, Transform( SA1->A1_ATIVIDA, "@R 99.99-9" ), oFont10 )
		EndIf

	Else
		nSizeCNAE := Len( AllTrim( SM0->M0_CNAE ) )

		If nSizeCNAE > 5
			oPrintPPP:Say( lin + 370, 2010, Transform( SM0->M0_CNAE, "@R 99.99-9/99" ), oFont10 )
		ElseIf Empty( SA1->A1_ATIVIDA )
			oPrintPPP:Say( lin + 370, 2010, "NA", oFont10 )
		Else
			oPrintPPP:Say( lin + 370, 2010, Transform( SM0->M0_CNAE, "@R 99.99-9" ), oFont10 )
		EndIf

	EndIf

	oPrintPPP:Line( lin + 380, 50, lin + 380, 2940 )
	oPrintPPP:Say( lin + 410, 60, "Nome do Trabalhador", oFont09 ) // "Nome do Trabalhador" // STR0015

	If !Empty(SRA->RA_NOMECMP)
		oPrintPPP:Say( lin + 470, 60, SRA->RA_NOMECMP, oFont10 )
	Else
		oPrintPPP:Say( lin + 470, 60, SRA->RA_NOME, oFont10 )
	EndIf

	oPrintPPP:Line( lin + 380, 1525, lin + 480, 1525 )
	oPrintPPP:Say( lin + 410, 1535, "BR/PDH", oFont09 )
	cBRPDH := "NA"

	If SRA->RA_BRPDH == "1"
		cBRPDH := "BR"
	ElseIf SRA->RA_BRPDH == "2"
		cBRPDH := "PDH"
	EndIf

	oPrintPPP:Say( lin + 470, 1535, cBRPDH, oFont10 )
	oPrintPPP:Line( lin + 380, 1925, lin + 480, 1925 )
	oPrintPPP:Say( lin + 410, 1935, "NIT", oFont09 )

	If !Empty( SRA->RA_PIS )
		oPrintPPP:Say( lin + 470, 1935, Transform( SRA->RA_PIS, "@R 999.99999.99-9" ), oFont10 )
	Else
		oPrintPPP:Say( lin + 470, 1935, "NA", oFont10 )
	EndIf

	oPrintPPP:Line( lin + 480, 50, lin + 480, 2940 )
	oPrintPPP:Line( lin + 480, 500, lin + 580, 500 )
	oPrintPPP:Line( lin + 480, 800, lin + 580, 800 )
	oPrintPPP:Line( lin + 480, 1400, lin + 580, 1400 )
	oPrintPPP:Line( lin + 480, 1800, lin + 580, 1800 )
	oPrintPPP:Say( lin + 510, 60, "Data do Nascimento", oFont09 ) // "Data do Nascimento" STR0242
	oPrintPPP:Say( lin + 570, 60, NGPPPDATE( SRA->RA_NASC ), oFont10 )
	oPrintPPP:Say( lin + 510, 510, "Sexo(F/M)", oFont09 ) // "Sexo( F/M )" STR0243
	oPrintPPP:Say( lin + 570, 510, Upper( SRA->RA_SEXO ), oFont10 )
	oPrintPPP:Say( lin + 510, 810, "CTPS(Nº, Série e UF)", oFont09 ) // "CTPS( Nº,  Série e UF )" // STR0244
	oPrintPPP:Say( lin + 570, 810, SRA->RA_NUMCP + "/" + SRA->RA_SERCP + " - " + SRA->RA_UFCP, oFont10 )
	oPrintPPP:Say( lin + 510, 1410, "Data de Admissão", oFont09 ) // "Data de Admissão" //STR0245
	oPrintPPP:Say( lin + 570, 1410, NGPPPDATE( SRA->RA_ADMISSA ), oFont10 )
	oPrintPPP:Say( lin + 510, 1810, "Regime Revezamento", oFont09 ) // "Regime Revezamento" STR0246

	If !Empty( SubStr( SR6->R6_REVEZAM, 1, 20 ) )
		oPrintPPP:Say( lin + 570, 1810, SubStr( SR6->R6_REVEZAM, 1, 20 ), oFont09 )
	Else
		oPrintPPP:Say( lin + 570, 1810, "NA", oFont10 )
	EndIf

	SomaLinha( 580 )
	oPrintPPP:Line( lin, 50, lin + 100, 50 )
	oPrintPPP:Say( lin + 30, 60, "Matrícula", oFont09 ) // "Matrícula" STR0247
	oPrintPPP:Say( lin + 90, 60, SRA->RA_MAT, oFont10 )
	oPrintPPP:Line( lin, 500, lin + 100, 500 )
	oPrintPPP:Say( lin + 30, 510, "Centro de Custo", oFont09 ) // "Centro de Custo" STR0248
	oPrintPPP:Say( lin + 90, 510, &cDescr, oFont10 )
	oPrintPPP:Line( lin, 1400, lin + 100, 1400 )
	oPrintPPP:Say( lin + 30, 1410, "Função", oFont09 ) // "Função" STR0277

	If !Empty( SRJ->RJ_DESC )
		oPrintPPP:Say( lin + 90, 1410, SRJ->RJ_DESC, oFont10 )
	Else
		oPrintPPP:Say( lin + 90, 1410, "NA", oFont10 )
	EndIf

	oPrintPPP:Line( lin, 2940, lin + 100, 2940 )
	oPrintPPP:Line( lin + 100, 50, lin + 100, 2940 )
	SomaLinha( 100 )

	If !Empty( xm_par11 ) // Termo Responsab. ?
		oPrintPPP:Line( lin, 50, lin + 80, 50 )
		oPrintPPP:Say( lin + 60, 60, "TERMO DE RESPONSABILIDADE", oFont13 ) // "TERMO DE RESPONSABILIDADE" STR0250
		oPrintPPP:Line( lin, 2940, lin + 80, 2940 )
		oPrintPPP:Line( lin + 80, 50, lin + 80, 2940 )
		SomaLinha( 80 )
		DBSelectArea( "TMZ" )
		DBSetOrder( 1 )
		DBSeek( xFilial( "TMZ" ) + xm_par11 ) // Termo Responsab. ?
		fImpMemo( TMZ->TMZ_DESCRI )

		If Empty( TMZ->TMZ_DESCRI )
			oPrintPPP:Line( lin, 50, lin + 90, 50 )
			oPrintPPP:Line( lin, 2940, lin + 90, 2940 )
			oPrintPPP:Line( lin + 90, 50, lin + 90, 2940 )
			SomaLinha( 60 )
		EndIf

		SomaLinha( 30 )
	EndIf

	If lin > 2770
		SomaLinha( , , .T. )
	EndIf

	oPrintPPP:Line( lin, 50, lin + 250, 50 )
	oPrintPPP:Line( lin, 2940, lin + 250, 2940 )
	oPrintPPP:Line( lin + 250, 50, lin + 250, 2940 )
	dDtEmiR  := CTOD( NGPPPDATE( IIf( xm_par21==3, xm_par22, IIf( xm_par21==2, dDtDemiss, dDataBase ) ), .T. ) ) //Data Emissao PPP ?//Informe a Data ?
	cDataCid := " "

	If lNGMDTPS .Or. lSigaMdtps
		cDataCid := AllTrim( SA1->A1_MUN ) + ",  " + StrZero( Day( dDtEmiR ), 2 ) + " de " + MesExtenso( Month( dDtEmiR ) ) // STR0251
		cDataCid  += " de " + Str( Year( dDtEmiR ), 4 ) // STR0251
	Else
		cDataCid := AllTrim( IIf( lParEnd, SM0->M0_CIDCOB, SM0->M0_CIDENT ) ) + ",  " + StrZero( Day( dDtEmiR ), 2 ) + " de " // STR0251
		cDataCid  += MesExtenso( Month( dDtEmiR ) ) + " de " + Str( Year( dDtEmiR ), 4 )
	EndIf

	oPrintPPP:Say( lin + 60, 60, cDataCid, oFont09 )

	oPrintPPP:Line( lin + 190, 850, lin + 190, 1550 )
	oPrintPPP:Say( lin + 240, 950, "(Assinatura do Funcionário)", oFont08 ) // STR0252

	oPrintPPP:SayAlign( 2200, 50, Str( nPaginaPPP, 3 ), oFont09n, 2940, 280, CLR_BLACK, 2, 1 )
	oPrintPPP:EndPage()
	nPaginaPPP++
Return .T.

/*
===============================================================================================================================
Programa--------------: RMDT006()
Autores---------------: Denis Hyroshi de Souza / Gabriel Sokacheski (Totvs)
Conversão para Italac-: Julio de Paula Paz
Data da Criacao-------: 22/09/2023
Descrição-------------: Retorna a data em formato correto para ser usada no PPP.
Parametros------------: dDtPPP, Date, Data a ser manipulada
                        lDtAtual, Logico, Define se será usada a data base do sistema
Retorno---------------: Caracter, Data base ou passada por parametro em formato "99/99/9999"
===============================================================================================================================
*/
Static Function NGPPPDATE( dDtPPP, lDtAtual )

	Local cRet := ""
	Local cDia := ""
	Local cMes := ""
	Local cAno := ""

	Default lDtAtual := .F.

	If Empty( dDtPPP ) .And. lDtAtual
		dDtPPP := dDataBase
	EndIf

	If Empty( dDtPPP )
		cRet := "__/__/____"
	EndIf

	If Empty( cRet )
		cDia := StrZero( Day( dDtPPP ), 2 )
		cMes := StrZero( Month( dDtPPP ), 2 )
		cAno := SubStr( Str( Year( dDtPPP ), 4 ), 1, 4 )

		cRet := cDia + "/" + cMes + "/" + cAno
	EndIf

Return cRet

/*
===============================================================================================================================
Programa--------------: RMDT006()
Autores---------------: Denis Hyroshi de Souza / Gabriel Sokacheski (Totvs)
Conversão para Italac-: Julio de Paula Paz
Data da Criacao-------: 22/09/2023
Descrição-------------: Busca usuarios do sesmt para impressao do PPP.
Parametros------------: Nenhum
Retorno---------------: Nenhum
===============================================================================================================================
*/
Static Function NG700SESMT()

	Local aArea := SM0->(GetArea())
	Local dDtFim, dDtIni
	Local dDateIni
	Local dDateFim
	Local lEntrou
	Local cModoTMK
	Local cModoTMW
	Local cFilTMK
	Local cFilTMW
	Local cFiltroTRB
	Local cFilSESMT
	Local cTipFun := IIf( xm_par28 == 1, "5", "1" )

	Private cMat
	Private cCodUser
	Private cFilMat

	DBSelectArea( cTRBPPP )
	DBGoTop()

	While ( cTRBPPP )->( !Eof() )

		lFlagEmp1 := .F.

		If lMudEmpr .And. (cTRBPPP)->EMP != cEmpPPP
			lFlagEmp1 := .T.
			cModo := FWModeAccess( "TMK" )
			EMP700OPEN( "TMK", "TMK", 1, (cTRBPPP)->EMP, @cModo, SubStr( (cTRBPPP)->FILIAL, 1, FwSizeFilial( (cTRBPPP)->EMP ) ) )
			cModo := FWModeAccess( "TMW" )
			EMP700OPEN( "TMW", "TMW", 1, (cTRBPPP)->EMP, @cModo, SubStr( (cTRBPPP)->FILIAL, 1, FwSizeFilial( (cTRBPPP)->EMP ) ) )
		EndIf

		cModoTMK := f700RetCom( "TMK" )
		cModoTMW := f700RetCom( "TMW" )

		cFilSESMT := SubStr( ( cTRBPPP )->FILIAL, 1, FwSizeFilial( ( cTRBPPP )->EMP ) )
		// Altera variaveis para o xFilial
		DBSelectArea( "SM0" )
		DBSeek( ( cTRBPPP )->EMP+cFilSESMT )
		cEmpAnt := ( cTRBPPP )->EMP
		cFilAnt := cFilSESMT

		cFilTMK := FwxFilial( "TMK", cFilSESMT, SubStr( cModoTMK, 1, 1 ), SubStr( cModoTMK, 2, 1 ), SubStr( cModoTMK, 3, 1 ) )
		cFilTMW := FwxFilial( "TMW", cFilSESMT, SubStr( cModoTMW, 1, 1 ), SubStr( cModoTMW, 2, 1 ), SubStr( cModoTMW, 3, 1 ) )

		DBSelectArea( "TMW" )
		DBSetOrder( 1 )
		DBSeek( cFilTMW )

		DBSelectArea( "TMK" )
		DBSetOrder( 1 )
		DBSeek( cFilTMK )

		While ( 'TMK' )->( !Eof() ) .And. cFilTMK == TMK->TMK_FILIAL

			If TMK->TMK_DTINIC >= (cTRBPPP)->DTATE .Or. ( !Empty( TMK->TMK_DTTERM ) .And. TMK->TMK_DTTERM <= (cTRBPPP)->DTDE )
				DBSelectArea( "TMK" )
				DBSkip()
				Loop
			EndIf

			If !Empty( TMK->TMK_CC ) .And. TMK->TMK_CC <> (cTRBPPP)->CUSTO .And. !fVlCCSRE()
				DBSelectArea( "TMK" )
				DBSkip()
				Loop
			EndIf

			If xm_par32 == 1 .And. TMK->TMK_SESMT <> "1" // Se não Compoe SESMT
				DBSelectArea( "TMK" )
				DBSkip()
				Loop
			EndIf

			// Somente quem gerou laudo.
			If xm_par29 == 2 .And. aScan( aRespLaudo, { | x | x == TMK->TMK_CODUSU } ) == 0
				DBSelectArea( "TMK" )
				DBSkip()
				Loop
			EndIf


			If lRespFim
				dDtIni := TMK->TMK_DTINIC
				dDtFim := TMK->TMK_DTTERM
			Else
				dDtIni := (cTRBPPP)->DTDE
				dDtFim := (cTRBPPP)->DTATE

				If TMK->TMK_DTINIC > dDtIni
					dDtIni := TMK->TMK_DTINIC
				EndIf

				If TMK->TMK_DTTERM < dDtFim .And. !Empty( TMK->TMK_DTTERM )
					dDtFim := TMK->TMK_DTTERM
				EndIf

			EndIf

			DBSelectArea( cTRBTMK )
			DBSetOrder( 3 )

			( cTRBTMK )->( dbAppend() )
			( cTRBTMK )->DTINI  := dDtIni
			( cTRBTMK )->DTFIM  := dDtFim
			( cTRBTMK )->FILIAL := TMK->TMK_FILIAL
			( cTRBTMK )->CODIGO := TMK->TMK_CODUSU
			( cTRBTMK )->NOME   := TMK->TMK_NOMUSU
			( cTRBTMK )->INDFUN := TMK->TMK_INDFUN
			( cTRBTMK )->NIT    := TMK->TMK_NIT
			( cTRBTMK )->REGNUM := TMK->TMK_NUMENT
			( cTRBTMK )->MAT 	:= ( cTRBPPP )->MAT
			( cTRBTMK )->RESAMB := TMK->TMK_RESAMB
			( cTRBTMK )->MONBIO := TMK->TMK_MONBIO
			( cTRBTMK )->CIC    := TMK->TMK_CIC

			( 'TMK' )->( DBSkip() )

		End

		If lFlagEmp1
			EMP700OPEN( "TMK", "TMK", 1, cEmpPPP, @cModo )
			EMP700OPEN( "TMW", "TMW", 1, cEmpPPP, @cModo )
		EndIf

		( cTRBPPP )->( DBSkip() )

	End

	// Verifica se os usuarios SESMT gravados na tabela cTRBTMK possuem registros reduntantes, rela-
	// cionados 'a matricula do funcionario. Para cada usuario nesta tabela sera'
	// mantido apenas um unico registro, com a menor data inicial e a maior data final do usuario.
	DBSelectArea( cTRBTMK )
	DBSetOrder( 4 ) //MAT + CODIGO + DToS(DTINI) + DToS(DTFIM)
	DBGoTop()

	While ( cTRBTMK )->( !Eof() )

		nRecnoTRB := Recno()
		cMat := (cTRBTMK)->MAT
		cCodUser := (cTRBTMK)->CODIGO
		dDateIni := (cTRBTMK)->DTINI
		cFilMat  := (cTRBTMK)->FILIAL
		lEntrou := .F.

		cFiltroTRB := 'cFilMat == (cTRBTMK)->FILIAL .And. cMat == (cTRBTMK)->MAT .And. cCodUser == (cTRBTMK)->CODIGO'
		dbSetFilter( {|| &cFiltroTRB}, cFiltroTRB )
		dbGoBottom()
		dDateFim := (cTRBTMK)->DTFIM
		dbClearFilter()

		DBGoTo( nRecnoTRB )
		RecLock( cTRBTMK, .F. )
			(cTRBTMK)->DTFIM := dDateFim
		MSUnLock()
		DBSkip()

		While !Eof() .And. cFilial + cMat + cCodUser == (cTRBTMK)->FILIAL + (cTRBTMK)->MAT + (cTRBTMK)->CODIGO
			RecLock( cTRBTMK, .F. )
				dbDelete()
			MSUnLock()
			DBSkip()
			lEntrou := .T.
		End

		If !lEntrou
			DBSkip()
		EndIf

	End

	FWRestArea( aArea )
Return

/*
===============================================================================================================================
Programa--------------: RMDT006()
Autores---------------: Denis Hyroshi de Souza / Gabriel Sokacheski (Totvs)
Conversão para Italac-: Julio de Paula Paz
Data da Criacao-------: 22/09/2023
Descrição-------------: Reclassifica os riscos
Parametros------------: Nenhum
Retorno---------------: Nulo, Sempre nulo
===============================================================================================================================
*/
Static Function RECLASS_RISCOS()
	Local cChave

	// Agrupa riscos que foram separados na mudanca de Filial/Matricula/Setor/Funcao
	DBSelectArea( cTRBTN0 )
	DBSetOrder( 3 )
	DBGoTop()

	While !Eof()

		If (cTRBTN0)->PROTEC != "S "
			DBSelectArea( cTRBTN0 )
			DBSkip()
			Loop
		EndIf

		cChave    := (cTRBTN0)->(GRISCO+AGENTE+Str( INTENS, nQTAGENt, nQTAGENd )+TECNIC)
		dtstart   := (cTRBTN0)->DT_DE
		dtstop    := (cTRBTN0)->DT_ATE
		nRecOld   := Recno()

		DBSelectArea( cTRBTN0 )
		DBSkip()

		While !Eof() .And. cChave == (cTRBTN0)->(GRISCO + AGENTE + Str( INTENS, nQTAGENt, nQTAGENd ) + TECNIC)

			If (cTRBTN0)->PROTEC != "S "
				DBSelectArea( cTRBTN0 )
				DBSkip()
				Loop
			EndIf

			If (cTRBTN0)->DT_DE == dtstop + 1

				RecLock( cTRBTN0, .F. )
					(cTRBTN0)->ATIVO := "N"
				MSUnLock()
				aAreaTRB := (cTRBTN0)->(GetArea())
				dtstop   := (cTRBTN0)->DT_ATE

				DBSelectArea( cTRBTN0 )
				DBGoTo( nRecOld )
				RecLock( cTRBTN0, .F. )
					(cTRBTN0)->DT_ATE := dtstop
				MSUnLock()

				FWRestArea( aAreaTRB )
			EndIf

			DBSkip()
		End

		DBSelectArea( cTRBTN0 )
		DBGoTo( nRecOld )
		DBSkip()
	End

	DBSelectArea( cTRBTN0 )
	DBSetOrder( 2 )
	DBGoTop()

	While !Eof()

		If (cTRBTN0)->ATIVO != "S"
			DBSelectArea( cTRBTN0 )
			DBSkip()
			Loop
		EndIf

		cKeyRisco := (cTRBTN0)->(GRISCO+AGENTE+Str( INTENS, nQTAGENt, nQTAGENd )+TECNIC+EPC+PROTEC+NUMCAP)
		dtstart   := (cTRBTN0)->DT_DE
		dtstop    := (cTRBTN0)->DT_ATE
		nRecOld   := Recno()

		While !Eof() .And. cKeyRisco == (cTRBTN0)->(GRISCO+AGENTE+Str( INTENS, nQTAGENt, nQTAGENd )+TECNIC+EPC+PROTEC+NUMCAP)

			If (cTRBTN0)->ATIVO != "S"
				DBSelectArea( cTRBTN0 )
				DBSkip()
				Loop
			EndIf

			If (cTRBTN0)->DT_DE == dtstop+1
				RecLock( cTRBTN0, .F. )
					(cTRBTN0)->ATIVO := "N"
				MSUnLock()
				aAreaTRB := (cTRBTN0)->(GetArea())
				dtstop   := (cTRBTN0)->DT_ATE

				DBSelectArea( cTRBTN0 )
				DBGoTo( nRecOld )
				RecLock( cTRBTN0, .F. )
					(cTRBTN0)->DT_ATE := dtstop
				MSUnLock()

				FWRestArea( aAreaTRB )
			EndIf

			DBSkip()
		End

		DBSelectArea( cTRBTN0 )
		DBGoTo( nRecOld )
		DBSkip()
	End

Return

/*
===============================================================================================================================
Programa--------------: RMDT006()
Autores---------------: Denis Hyroshi de Souza / Gabriel Sokacheski (Totvs)
Conversão para Italac-: Julio de Paula Paz
Data da Criacao-------: 22/09/2023
Descrição-------------: Monta Combo Box para exibir na tela
Parametros------------: cCampo, Caracter, Campo que tera o Combo Box anex
                        cForaCombo, Caracter, String contendo item a nao ser apresentado "56
                        nLenGrava, Numerico, Tamanho a ser verificado a cada item da string
Retorno---------------: Return, return_type, Array com combo box
===============================================================================================================================
*/
Static Function PPPMDTCbox( cCampo, cForaCombo, nLenGrava )

	Local aArray1	:= {}
	Local aArray2	:= {}
	Local aSaveArea	:= FWGetArea()
	Local cVar
	Local nCont

	Default cForaCombo := ""
	Default nLenGrava  := 1

	DBSelectArea( "SX3" )
	DBSetOrder( 2 )
	MsSeek( cCampo )

	cVar := X3CBox()

	If Empty( cVar )
		Return aArray2
	EndIf

	aArray1	:= RetSx3Box( cVar, , , 1 )

	For nCont := 1 To Len( aArray1 )

		If cForaCombo <> "" .And. Left( aArray1[nCont][1], nLenGrava ) $ cForaCombo
			Loop
		EndIf

		aAdd( aArray2, aArray1[nCont][1] )
	Next nCont

	FWRestArea( aSaveArea )

Return aArray2

/*
===============================================================================================================================
Programa--------------: RMDT006()
Autores---------------: Denis Hyroshi de Souza / Gabriel Sokacheski (Totvs)
Conversão para Italac-: Julio de Paula Paz
Data da Criacao-------: 22/09/2023
Descrição-------------: Verifica conteudo do parametro sx6 MV_MDTRESP
Parametros------------: Nenhum
Retorno---------------: Nenhum
===============================================================================================================================
*/
Static Function SX6PPPRES()

	// Representante Medico
	If AllTrim( GetMV( "MV_MDTRESP" ) ) == "2"
		cFilRES     := xFilial( "TMK" )
		cAliasRES 	:= "TMK"
		cCNomeRES 	:= "TMK->TMK_NOMUSU"
		cCpfRes 	:= "TMK->TMK_CIC"
		cValRES		:= "ExistCPO('TMK',MV_PAR" + cNumSX1 + ")"
	EndIf

Return

/*
===============================================================================================================================
Programa--------------: RMDT006()
Autores---------------: Denis Hyroshi de Souza / Gabriel Sokacheski / Jorge Luis Siementkowski (Totvs)
Conversão para Italac-: Julio de Paula Paz
Data da Criacao-------: 22/09/2023
Descrição-------------: Consulta padrao da pergunta Representante Empresa?
Parametros------------: Nenhum
Retorno---------------: Logico, Define se o usuario clicou em Ok na consulta padrao
===============================================================================================================================
*/
Static Function MDT700SXB()

	Local lRet	:= .F.

	If AllTrim( GetMV( "MV_MDTRESP" ) ) == "2"
		DBSelectArea( "TMK" )
		DBSetOrder( 1 ) //TMK_FILIAL + TMK_CODUSU
		If (lRet := ConPad1( , , , "TMK", "cRetF3", , .F. ) )
			cRetF3 := TMK->TMK_CODUSU
		EndIf
	Else
		DBSelectArea( "SRA" )
		DBSetOrder( 1 ) //RA_FILIAL + RA_MAT
		If (lRet := ConPad1( , , , "SRA", "cRetF3", , .F. ) )
			cRetF3 := SRA->RA_MAT
		EndIf
	EndIf

Return lRet

/*
===============================================================================================================================
Programa--------------: RMDT006()
Autores---------------: Denis Hyroshi de Souza / Gabriel Sokacheski / Jorge Luis Siementkowski (Totvs)
Conversão para Italac-: Julio de Paula Paz
Data da Criacao-------: 22/09/2023
Descrição-------------: Retorna o resultado da consulta padrão da pergunta Representante Empresa?
Parametros------------: Nenhum
Retorno---------------: Caracter, Retorno da consulta de Representante Empresa?
===============================================================================================================================
*/
Static Function MDT700RSXB()
Return IIf( Type( 'cRetF3' ) != 'U' .And. !Empty( cRetF3 ), cRetF3, Space( TamSX3( ReadVar() )[1] ) )

/*
===============================================================================================================================
Programa--------------: RMDT006()
Autores---------------: Denis Hyroshi de Souza / Gabriel Sokacheski / Jorge Luis Siementkowski (Totvs)
Conversão para Italac-: Julio de Paula Paz
Data da Criacao-------: 22/09/2023
Descrição-------------: Abre arquivo de outra empresa
Parametros------------: cAlias1, Caracter, Nome do Alias conforme X2_CHAVE
                        cAlias2, Caracter, Nome do Alias com a qual a Tabela será aberta
                        nIndice, Numerico, Ordem com a qual a Tabela sera aberta
                        MvEmpresa, Caracter, Codigo da Empresa do arquivo
                        cMd, Caracter, Modo de Acesso do arquivo conforme X2_MODO
                        MvFilial, Caracter, Filial usada para posicionamentos na SM0
Retorno---------------: Logico, Sempre verdadeiro
===============================================================================================================================
*/
Static Function EMP700OPEN(cAlias1, cAlias2, nIndice, MvEmpresa, cMd, MvFilial)

	Local nAT := 0
	Local aArea := GetArea()//Salva area posicionada

	Default nIndice := 1
	Default cAlias1 := Alias()
	Default cAlias2 := Alias()
	Default MvEmpresa := cEmpAnt
	Default cMd := FWModeAccess( Alias() )
	Default MvFilial  := cSvFilAnt

	// Restaura variaveis para alteracao da tabela
	DBSelectArea( "SM0" )
	DBSeek( cEmpPPP + cSvFilAnt )
	cEmpAnt := cEmpPPP
	cFilAnt := cSvFilAnt

	UniqueKey( NIL, cAlias1, .T. )
	EmpOpenFile( cAlias2, cAlias1, nIndice, .T., MvEmpresa, @cMd )   // Abre arquivo da empresa selecionada
	nAT := AT( cAlias1, cArqTab )

	If nAT > 0
		cArqTab := Subs( cArqTab, 1, nAT + 2 ) + cMd + Subs( cArqTab, nAT + 4 )
	EndIf

	cArqTab := Subs( cArqTab, 1, nTamTable )

	// Altera variaveis para o xFilial
	DBSelectArea( "SM0" )
	DBSeek( MvEmpresa + MvFilial )
	cEmpAnt := MvEmpresa
	cFilAnt := MvFilial

	FWRestArea( aArea )

Return .T.

/*
===============================================================================================================================
Programa--------------: RMDT006()
Autores---------------: Denis Hyroshi de Souza / Gabriel Sokacheski / Jorge Luis Siementkowski (Totvs)
Conversão para Italac-: Julio de Paula Paz
Data da Criacao-------: 22/09/2023
Descrição-------------: Busca data de demissao do funcionaro na tabela SRG
Parametros------------: Nenhum
Retorno---------------: Date, Data de demissao do funcionario na tabela de Rescisoes
===============================================================================================================================
*/
Static Function PPPDTDEMIS()

	Local dDtDem := SToD( Space( 8 ) )
	Local aArea := FWGetArea()

	DBSelectArea( "SRG" )
	DBSetOrder( 1 )
	DBSeek( SRA->RA_FILIAL+SRA->RA_MAT )

	While !Eof() .And. SRA->RA_FILIAL+SRA->RA_MAT == SRG->RG_FILIAL+SRG->RG_MAT

		If SRG->RG_DATADEM >= dDataBase-30
			dDtDem := SRG->RG_DATADEM
		EndIf

		DBSkip()
	End

	FWRestArea( aArea )
Return dDtDem

/*
===============================================================================================================================
Programa--------------: RMDT006()
Autores---------------: Denis Hyroshi de Souza / Gabriel Sokacheski / Jorge Luis Siementkowski (Totvs)
Conversão para Italac-: Julio de Paula Paz
Data da Criacao-------: 22/09/2023
Descrição-------------: Verifica se a data de emissao do PPP foi informada
Parametros------------: cpar22, Caracter, Conteudo do campo de data de emissao
Retorno---------------: Logico, .T. se o campo foi preenchido
===============================================================================================================================
*/
Static Function MDT700VLDD( cpar22 )

	If Empty( cpar22 )
		MsgInfo( "Esse campo devera ser preenchido com a data de emissao que sera exibida no PPP." ) // "Esse campo devera ser preenchido com a data de emissao que sera exibida no PPP." STR0253
		Return .F.
	EndIf

Return .T.

/*
===============================================================================================================================
Programa--------------: RMDT006()
Autores---------------: Denis Hyroshi de Souza / Gabriel Sokacheski / Jorge Luis Siementkowski (Totvs)
Conversão para Italac-: Julio de Paula Paz
Data da Criacao-------: 22/09/2023
Descrição-------------: Verifica a quantidade de meses do parametro MV_NG2MEAN
Parametros------------: Nenhum
Retorno---------------: Numerico, Quantidade de meses do parametro ajustado para uso no PPP
===============================================================================================================================
*/
Static Function MDT700MES()

	Local nQtdMes := 1
	Local nMes

	nMes := GETMV( "MV_NG2MEAN" )

	If ValType( nMes ) == "N"

		If nMes == 0
			nQtdMes := 0
		ElseIf nMes < 0
			nQtdMes := 1
		ElseIf nMes > 12
			nQtdMes := 12
		Else
			nQtdMes := nMes
		EndIf

	EndIf

Return nQtdMes

/*
===============================================================================================================================
Programa--------------: RMDT006()
Autores---------------: Denis Hyroshi de Souza / Gabriel Sokacheski / Jorge Luis Siementkowski (Totvs)
Conversão para Italac-: Julio de Paula Paz
Data da Criacao-------: 22/09/2023
Descrição-------------: Ajusta os Epis entregues em outra funcao/setor
Parametros------------: dInicio, Date, Data a ser comparada com a date de entrega do epi
Retorno---------------: Nulo, Sempre nulo
===============================================================================================================================
*/
Static Function fPPP_EPI(dInicio)

	Local aRecnos := {}
	Local nFor

	DBSelectArea( cTRBTNF )
	DBSetOrder( 1 )
	DBSeek( DToS( dInicio ) )

	While !Eof() .And. dInicio == (cTRBTNF)->DTINI

		cSvCA     := (cTRBTNF)->NUMCAP
		dDtIniTRB := (cTRBTNF)->DTREAL
		nRecnoTRB := (cTRBTNF)->(Recno())
		lFirstTRB := .T.

		While !Eof() .And. dInicio == (cTRBTNF)->DTINI .And. cSvCA == (cTRBTNF)->NUMCAP

			If !lFirstTRB .And. (cTRBTNF)->DTREAL > dDtIniTRB
				dDtIniTRB := (cTRBTNF)->DTREAL
				nRecnoTRB := (cTRBTNF)->(Recno())
			EndIf

			RecLock( cTRBTNF, .F. )
				(cTRBTNF)->SITUAC := "S"
			MSUnLock()

			lFirstTRB := .F.

			DBSelectArea( cTRBTNF )
			DBSkip()
		End

		aAdd( aRecnos, nRecnoTRB )
	End

	For nFor := 1 To Len( aRecnos )
		DBSelectArea( cTRBTNF )
		DBGoTo( aRecnos[nFor] )

		If !Eof() .And. !Bof()
			RecLock( cTRBTNF, .F. )
				(cTRBTNF)->SITUAC := " "
			MSUnLock()
		EndIf

	Next nFor

Return

/*
===============================================================================================================================
Programa--------------: RMDT006()
Autores---------------: Denis Hyroshi de Souza / Gabriel Sokacheski / Jorge Luis Siementkowski / Liber De Esteban (Totvs)
Conversão para Italac-: Julio de Paula Paz
Data da Criacao-------: 22/09/2023
Descrição-------------: Envia email do relatorio, conforme parametros definidos no
                        SX6 e informacoes entradas pelo usuario
Parametros------------: cPrefixo, Caracter, Caminho para salvar os arquivos
Retorno---------------: Logico, Sempre verdadeiro
===============================================================================================================================
*/
Static Function PPPSENDMAIL(cPrefixo)

	Local cBarraSrv := "\"
	Local cNameArq  := Lower( OemToAnsi( "Perfil Profissiografico Previdenciario") ) + ".PDF" // STR0006
	Local cArqLocal := cPathEst + cNameArq

	If isSRVunix()  //servidor eh da familia Unix (linux, solaris, free-bsd, hp-ux, etc.)
		cBarraSrv := "/"
	EndIf

	If nProcessa == 1

		cDiretorio := AllTrim( GetMV( "MV_RELT", , " " ) )
		cAnexos    := ""

		If Empty( cDiretorio )
			cDiretorio := cBarraSrv
		EndIf

		//imagem boa qualidade
		nLargura := 920
		nAltura  := 1300
		nZoom    := 145

		//imagem pessima qualidade
		If xm_par25 == 2 //Imagem PPP enviada p. e-mail ?
			nLargura := 745.5
			nAltura  := 1050
			nZoom    := 115.5
		EndIf

		If CpyT2S( cArqLocal, cDiretorio )
			cAnexos := cDiretorio + cNameArq
		Else
			MsgStop( "Não foi possível gravar o relatório", "AVISO" ) // "Não foi possível gravar o relatório"###"AVISO" STR0254, STR0255
			Return .F.
		EndIf

		cBody  := "Segue em anexo relatório de " + OemToAnsi( "Perfil Profissiografico Previdenciario" ) + ": " + SRA->RA_MAT + " - " + AllTrim( SRA->RA_NOME ) // "Segue em anexo relatório de " STR0256 /  STR0006

		CONNECT SMTP SERVER cServer ACCOUNT cAccount PASSWORD cPassword Result lOk

		If !lAutOk

			If ( lSmtpAuth )
				lAutOk := MailAuth( cUserAut, cPassAut )
			Else
				lAutOk := .T.
			EndIf

		EndIf

		If lOk .And. lAutOk

			If !Empty( cCC )
				SEND MAIL FROM cFrom To cTo CC cCC SUBJECT AllTrim( cSubject ) BODY cBody ATTACHMENT cAnexos Result lOk
			Else
				SEND MAIL FROM cFrom To cTo SUBJECT AllTrim( cSubject ) BODY cBody ATTACHMENT cAnexos Result lOk
			EndIf

			If lOk
				MsgInfo( "Email enviado com sucesso" ) // "Email enviado com sucesso" STR0257
			Else
				GET MAIL ERROR cErro
				MsgStop( "Não foi possível enviar o Email." +Chr( 13 ) + Chr( 10 ) + cErro, "AVISO") // "Não foi possível enviar o Email."###"AVISO" // STR0255 / STR0258
				Return .F.
			EndIf

		Else
			GET MAIL ERROR cErro
			MsgStop( "Erro na conexão com o SMTP Server." + Chr( 13 ) + Chr( 10 ) + cErro, "AVISO") // "Erro na conexão com o SMTP Server."###"AVISO" STR0255 / STR0259
			Return .F.
		EndIf

		DISCONNECT SMTP SERVER

	EndIf

	If MsgYesNo( "Deseja visualizar o relatório?" ) // "Deseja visualizar o relatório?" STR0260
		 shellExecute( "Open", cArqLocal, "", cBarraSrv, 1 )
	EndIf

	//Apaga os arquivos da Estação de Trabalho e do Servidor
	FErase( cArqLocal )
	FErase( cAnexos )

Return .T.

/*
===============================================================================================================================
Programa--------------: RMDT006()
Autores---------------: Denis Hyroshi de Souza / Gabriel Sokacheski / Jorge Luis Siementkowski / Liber De Esteban (Totvs)
Conversão para Italac-: Julio de Paula Paz
Data da Criacao-------: 22/09/2023
Descrição-------------: Verifica os parametros do SX6 usados para enviar email.
                        Exibe janela para o usuario entrar os dados.
Parametros------------: Nenhum
Retorno---------------: Numerico, Opcao feita na tela de emails
===============================================================================================================================
*/
Static Function PPPCONFMAIL()

	// Verifica se existe o SMTP Server
	If 	Empty( cServer )
		MsgStop( "O Servidor de SMTP não foi configurado !!!", "ATENÇÃO" ) // "O Servidor de SMTP não foi configurado !!!"###"Atenção" STR0261
		Return 0
	EndIf

	If lSmtpAuth

		// Verifica se existe a CONTA
		If 	Empty( cAccount )
			Msgstop( "A Conta do email não foi configurada !!!" , "ATENÇÃO" ) // "A Conta do email não foi configurada !!!"###"Atenção" STR0263
			Return 0
		EndIf

		// Verifica se existe a Senha
		If 	Empty( cPassword )
			Msgstop( "A Senha do email não foi configurada !!!", "ATENÇÃO" ) // "A Senha do email não foi configurada !!!"###"Atenção" STR0264
			Return 0
		EndIf

	EndIf

	PswOrder( 1 )
	PswSeek( __cUserId, .T. )
	aUsuario := PswRet( 1 )

	DEFINE MSDIALOG oDlgMail OF oMainWnd FROM 0, 0 To 200, 544 PIXEL TITLE "Dados do E-mail" // STR0265 // "Dados do E-mail"

		@ 05, 04 To 079, 268 OF oDlgMail PIXEL
		@ 18, 08 Say "De:"	    Size 012, 08 OF oDlgMail PIXEL // STR0266
		@ 33, 08 Say "Para:"	Size 016, 08 OF oDlgMail PIXEL // STR0267
		@ 48, 08 Say "CC:"	    Size 016, 08 OF oDlgMail PIXEL // STR0268
		@ 63, 08 Say "Assunto:"	Size 021, 08 OF oDlgMail PIXEL // STR0269

		@ 18, 33 MSGet cFrom    Size 233, 10 When .F. OF oDlgMail PIXEL
		@ 33, 33 MSGet cTo      Size 233, 10          OF oDlgMail PIXEL
		@ 48, 33 MSGet cCC      Size 233, 10          OF oDlgMail PIXEL
		@ 63, 33 MSGet cSubject Size 233, 10          OF oDlgMail PIXEL

		DEFINE SBUTTON FROM 85, 100 Type 1 ACTION (IIf( !Empty( cTo ), IIf( oDlgMail:End(), nOpca:=1, nOpca:=1 ), Help( "", 1, "AVG0001054" ) ) ) ENABLE OF oDlgMail PIXEL
		DEFINE SBUTTON FROM 85, 140 Type 2 ACTION ( oDlgMail:End() ) ENABLE OF oDlgMail PIXEL

	ACTIVATE MSDIALOG oDlgMail CENTERED

Return nOpca

/*
===============================================================================================================================
Programa--------------: RMDT006()
Autores---------------: Denis Hyroshi de Souza / Gabriel Sokacheski / Jorge Luis Siementkowski / Liber De Esteban (Totvs)
Conversão para Italac-: Julio de Paula Paz
Data da Criacao-------: 22/09/2023
Descrição-------------: Verifica se as perguntas de data de demissao estao preenchidas
Parametros------------: Nenhum
Retorno---------------: Logico
===============================================================================================================================
*/
Static Function R700VL19()

	If lSigaMdtps

		If MV_PAR22==3 .Or. MV_PAR22==4

			If Empty( MV_PAR23 )
				HELP( " ", 1, "NVAZIO" )
				Return .F.
			EndIf

		EndIf

	Else

		// Situacao e data de demissao dos funcionarios
		If (MV_PAR18==3 .Or. MV_PAR18==4) .And. Empty( MV_PAR19 )
			Help( " ", 1, "NVAZIO" )
			Return .F.
		EndIf

	EndIf

Return .T.

/*
===============================================================================================================================
Programa--------------: RMDT006()
Autores---------------: Denis Hyroshi de Souza / Gabriel Sokacheski / Jorge Luis Siementkowski / Liber De Esteban (Totvs)
Conversão para Italac-: Julio de Paula Paz
Data da Criacao-------: 22/09/2023
Descrição-------------: Verifica a validade das perguntas de data de demissao
Parametros------------: Nenhum
Retorno---------------: Logico, Define se as datas de demissao sao validas
===============================================================================================================================
*/
Static Function R700VL20()

	Local lRet := .T.

	If lSigaMdtps

		If MV_PAR22==3 .Or. MV_PAR22==4

			If MV_PAR23 > MV_PAR24
				Help( " ", 1, "DEATEINVAL" )
				lRet := .F.
			EndIf

		EndIf

	Else

		// Situacao e data de demissao dos funcionarios
		If ( MV_PAR18==3 .Or. MV_PAR18==4 ) .And. MV_PAR19 > MV_PAR20
			Help( " ", 1, "DEATEINVAL" )
			lRet := .F.
		EndIf

	EndIf

Return lRet

/*
===============================================================================================================================
Programa--------------: RMDT006()
Autores---------------: Denis Hyroshi de Souza / Gabriel Sokacheski / Jorge Luis Siementkowski / Liber De Esteban (Totvs)
Conversão para Italac-: Julio de Paula Paz
Data da Criacao-------: 22/09/2023
Descrição-------------: Verifica se houve afastamento e retorna a quantidade de dias
Parametros------------: cFilFun, Caracter, Filial do funcionario
                        cMatric, Caracter, Matricula do funcionario
                        _dtIniRis, Date, Data inicial a ser comparada
                        _dtFimRis, Date, Data final a ser comparada
Retorno---------------: Numerico, Quantidade de dias do afastamento
===============================================================================================================================
*/
Static Function fQtdeAfast( cFilFun, cMatric, _dtIniRis, _dtFimRis )

	Local nPos
	Local nX
	Local nCont   := 0
	Local lMudou  := .F.
	Local nDias   := 0
	Local nVetID  := 0
	Local dTmpSR8 := SToD( "" )
	Local dIniAfa := SToD( "" )
	Local dFimAfa := SToD( "" )
	Local aAfasta := {}
	Local cModoSR8
	Local cXFilSR8

	cModoSR8 := f700RetCom( "SR8" )
	cXFilSR8 := FwxFilial( "SR8", cFilFun, SubStr( cModoSR8, 1, 1 ), SubStr( cModoSR8, 2, 1 ), SubStr( cModoSR8, 3, 1 ) )

	DBSelectArea( "SR8" )
	DBSetOrder( 1 )
	DBSeek( cXFilSR8 + cMatric )

	While !Eof(  ) .And. SR8->R8_FILIAL + SR8->R8_MAT == cXFilSR8 + cMatric
		dTmpSR8 := IIf( Empty( SR8->R8_DATAFIM ), _dtFimRis, SR8->R8_DATAFIM )

		If SR8->R8_DATAINI <= _dtFimRis .And. dTmpSR8 >= _dtIniRis .And. !Empty( SR8->R8_DATAINI )
			dIniAfa := IIf( SR8->R8_DATAINI < _dtIniRis, _dtIniRis, SR8->R8_DATAINI )
			dFimAfa := IIf( dTmpSR8 > _dtFimRis, _dtFimRis, dTmpSR8 )
			nVetID++
			aAdd( aAfasta, { dIniAfa, dFimAfa, .T., nVetID } )
		EndIf

		DBSelectArea( "SR8" )
		DBSkip()
	EndDo

	While nCont < 1000
		nCont++
		lMudou := .F.

		For nX := 1 To Len( aAfasta )

			If aAfasta[nX, 3]
				nPos := aScan( aAfasta, { |x| x[1] <= aAfasta[nX, 2] .And. x[2] >= aAfasta[nX, 1] .And. nX <> x[4] .And. x[3] } )

				If nPos > 0
					aAfasta[nX, 1] := IIf( aAfasta[nX, 1] > aAfasta[nPos, 1], aAfasta[nPos, 1], aAfasta[nX, 1] )
					aAfasta[nX, 2] := IIf( aAfasta[nX, 2] < aAfasta[nPos, 2], aAfasta[nPos, 2], aAfasta[nX, 2] )
					aAfasta[nPos, 3] := .F.
					lMudou := .T.
				EndIf

			EndIf

		Next nX

		If !lMudou
			Exit
		EndIf

	End

	For nX := 1 To Len( aAfasta )

		If aAfasta[nX, 3]
			nDias += (aAfasta[nX, 2]-aAfasta[nX, 1]) + 1
		EndIf

	Next nX

Return nDias

/*
===============================================================================================================================
Programa--------------: RMDT006()
Autores---------------: Denis Hyroshi de Souza / Gabriel Sokacheski / Jorge Luis Siementkowski / Liber De Esteban 
                        Roger Rodrigues (Totvs)
Conversão para Italac-: Julio de Paula Paz
Data da Criacao-------: 22/09/2023
Descrição-------------: Retorna compartilhamento da tabela
Parametros------------: Nenhum
Retorno---------------: SX2->(X2_MODOEMP+X2_MODOUN+X2_MODO
===============================================================================================================================
*/
Static Function f700RetCom(cAlias)

	DBSelectArea( "SX2" )
	DBSetOrder( 1 )
	DBSeek( cAlias )

Return FWModeAccess( cAlias, 1 ) + FWModeAccess( cAlias, 2 ) + FWModeAccess( cAlias, 3 )

/*
===============================================================================================================================
Programa--------------: RMDT006()
Autores---------------: Denis Hyroshi de Souza / Gabriel Sokacheski / Jorge Luis Siementkowski / Liber De Esteban 
                        Roger Rodrigues / Bruno Lobo de Souza (Totvs)
Conversão para Italac-: Julio de Paula Paz
Data da Criacao-------: 22/09/2023
Descrição-------------: Função para validação do parâmetro até .... ?
Parametros------------: Nenhum
Retorno---------------: cTabela   = Tabela do campo
                        cMvParDe  = Parmetro  De
						cMvParAte = Parametro Ate
						nTam   := Tamanho do campo 
===============================================================================================================================
*/
Static Function RMDT006ATE( cTabela, cMvParDe, cMvParAte, nTam )

	If Empty( cMvParAte )
		ShowHelpDlg( "ATENÇÃO", {"Para opção de parâmetro Até no arquivo de perguntas esta opção é inválida." }, 2, { "Informe uma opção válida para este parâmetro." }, 2 ) // STR0273 // STR0275
		Return .F.
	ElseIf cMvParAte < cMvParDe
		ShowHelpDlg( "ATENÇÃO", {"Para opção de parâmetro De/Até no arquivo de perguntas esta opção é inválida."}, 2, { "Informe uma opção válida para este parâmetro." }, 2 ) // STR0274 // STR0275
		Return .F.
	EndIf

	If cMvParAte = Replicate( 'Z', Len( cMvParAte ) )
		Return .T.
	Else

		If cTabela == "SRA"

			If !ExCpoMDT( cTabela, cMvParAte )
				Return .F.
			EndIf

		ElseIf !ExistCpo( cTabela, cMvParAte )
			Return .F.
		EndIf

	EndIf

Return .T.

/*
===============================================================================================================================
Programa--------------: RMDT006()
Autores---------------: Denis Hyroshi de Souza / Gabriel Sokacheski / Jorge Luis Siementkowski / Liber De Esteban 
                        Roger Rodrigues / Bruno Lobo de Souza / Guilherme Benkendorf (Totvs)
Conversão para Italac-: Julio de Paula Paz
Data da Criacao-------: 22/09/2023
Descrição-------------: Desagrupa datas para impressão.
Parametros------------: dDtIni
                        dDtFim
Retorno---------------: Retorna array aBloco, onde cada posição corresponde a impressão
                        Exemplo: { "11/01/2012 a 31/12/2012" , "01/01/2013 a 31/12/2013" , "01/01/2014 a 15/01/2014" }
===============================================================================================================================
*/
Static Function fDesagData( dDtIni, dDtFim )

	Local aBloco  := {}
	Local nRepete := 1
	Local nX
	Local nAnoAux // Auxilia na soma dos anos

	// Variaveis para auxiliar na impressão das datas
	Local dDtAuxIni
	Local dDtAuxFim

	/*/---------------------------------------------------------------------------------
		Campos 13.1, 14.1, 15.1, 16.1 e 18.1 - As informações a partir de 01/01/2004,
		deverão ser discriminadas anualmente, não se admitindo a informação em bloco em
		virtude do contido no § 3º, artigo 254 e § 7º, artigo 272 da IN 45/2010
	---------------------------------------------------------------------------------/*/

	// Será desmembrado a impressão apenas se o parâmetro estiver habilitado
	// e seguir a regra do INSS, a partir de 2004, antes é jogado em um único bloco
	If xm_par30 == 1

		If Year( dDtIni ) < 2004
			aAdd( aBloco, NGPPPDATE( dDtIni ) + " a " + IIf( !Empty( dDtFim ) .And. dDtFim < SToD( "20031231" ), NGPPPDATE( dDtFim ), NGPPPDATE( SToD( "20031231" ) ) ) ) //" a " STR0173

			If !Empty( dDtFim ) .And. dDtFim < SToD( "20040101" )
				dDtIni := dDtFim
			Else
				dDtIni := SToD( "20040101" )
			EndIf

		EndIf

		nRepete := IIf( !Empty( dDtFim ), Year( dDtFim ), Year( dDataBase ) ) - Year( dDtIni )
		nRepete := IIf( nRepete > 0, nRepete + 1, 1 )
	EndIf

	nAnoAux := Year( dDtIni )

	For nX := 1 To nRepete

		dDtAuxIni:= IIf( nX == 1, dDtIni, CToD( "01/01/" + Str( nAnoAux+1, 4 ) ) )
		nAnoAux  := Year( dDtAuxIni )

		dDtAuxFim:= IIf( nX <> nRepete, CToD( "31/12/" + Str( nAnoAux, 4 ) ), dDtFim )
		nAnoAux  := Year( dDtAuxFim )

		aAdd( aBloco, NGPPPDATE( dDtAuxIni ) + " a " + NGPPPDATE( dDtAuxFim ) ) //" a " // STR0173

	Next nX

Return aBloco

/*
===============================================================================================================================
Programa--------------: RMDT006()
Autores---------------: Denis Hyroshi de Souza / Gabriel Sokacheski / Jorge Luis Siementkowski / Liber De Esteban 
                        Roger Rodrigues / Bruno Lobo de Souza / Guilherme Benkendorf / Guilherme Freudenburg (Totvs)
Conversão para Italac-: Julio de Paula Paz
Data da Criacao-------: 22/09/2023
Descrição-------------: Responsavel por verificar afastamento do funcionário durante o período de
                        exposição ao risco, e dividir em períodos o tempo de exposição.

Parametros------------: cMat    , Caracter	, Matrícula do funcionário utilizado
                        dIniRis	, Date		, Data Início do Risco
                        dFimRis	, Date		, Data Fim do Risco
Retorno---------------: aEficaz, Array , Retorna a data de início e fim de cada período.
===============================================================================================================================
*/
Static Function MDT700AFAS( cMat, dIniRis, dFimRis  )

	Local cVarAfas := xm_par36
	Local nX := 0
	Local aEficaz := {}
	Local aAfasta := {}
	Local aVarFas := {}

	While !Empty( cVarAfas )
		aAdd( aVarFas, SubStr( cVarAfas, 1, 3 ) )
		cVarAfas := SubStr( cVarAfas, 4 )
	End

	DBSelectArea( "SR8" )
	DBSetOrder( 1 )//R8_FILIAL+R8_MAT+DToS( R8_DATAINI )+R8_TIPO

	If DBSeek( xFilial( "SR8" )+cMat )//Verifica se houve algum afastamento para o funcionário.

		While !Eof() .And. SR8->R8_MAT == cMat

			If aScan( aVarFas, { | x | x == SR8->R8_TIPOAFA } ) > 0 .And.; // Verifica se o tipo de afastamento está contido nos selecionados através do SX1.
			   dIniRis <= SR8->R8_DATAFIM .And. dFimRis >= SR8->R8_DATAINI  // Verifica se o risco esta contido no periodo de afastamento
				aAdd( aAfasta, { SR8->R8_DATAINI, SR8->R8_DATAFIM } ) // Adiciona o período de afastado.
			EndIf

			SR8->(DBSkip())
		End

	EndIf

	If Len( aAfasta ) > 0

		For nX := 1 To Len( aAfasta ) //Percorre todos os períodos afastados.

			If nX == 1

				If aAfasta[nX, 1]-1 >= dIniRis //Inicio do afastamento deve ser maior que o inicio do risco.
					aAdd( aEficaz, { dIniRis, aAfasta[nX, 1]-1 } )
				EndIf

				If nX + 1 <= Len( aAfasta )
					aAdd( aEficaz, { aAfasta[nX, 2]+1, aAfasta[nX+1, 1]-1 } )
				ElseIf nX == Len( aAfasta ) .And. aAfasta[nX, 2]+1 <= dFimRis
					aAdd( aEficaz, { aAfasta[nX, 2]+1, dFimRis } )
				EndIf

			Else

				If nX == Len( aAfasta )
					aAdd( aEficaz, { aAfasta[nX, 2]+1, dFimRis } )
				Else
					aAdd( aEficaz, { aAfasta[nX, 2]+1, aAfasta[nX+1, 1]-1 } )
				EndIf

			EndIf

		Next nX

	Else // Caso não encontre nenhum afastamento.
		aAdd( aEficaz, { dIniRis, dFimRis } )
	EndIf

Return aEficaz

/*
===============================================================================================================================
Programa--------------: RMDT006()
Autores---------------: Denis Hyroshi de Souza / Gabriel Sokacheski / Jorge Luis Siementkowski / Liber De Esteban 
                        Roger Rodrigues / Bruno Lobo de Souza / Guilherme Benkendorf / Guilherme Freudenburg (Totvs)
Conversão para Italac-: Julio de Paula Paz
Data da Criacao-------: 22/09/2023
Descrição-------------: Permite selecionar os tipos dos afastamentos desejados.
Parametros------------: Nenhum
Retorno---------------: lRet,Lógico, Retorna verdadeiro quando função estiver correta
===============================================================================================================================
*/
Static Function MDT700FAST()

	Local aArea := FWGetArea()
	// Variaveis para montar TRB
	Local aDBF, aTRBSX5
	// Variaveis de Tela
	Local oDlgAfas
	// Varivaeis operacionais
	Local cKeyAfas   := ""
	Local cResultAfas := Space( 60 )
	Local aAfasCombo := {"Código","Descrição","Marcados"} // "Código","Descrição","Marcados" // STR0311, STR0312, STR0313
	Local oAfasCombo
	Local oPanelAfas
	Local oButtonAfas
	Local oGetAfas
	Local oMarkAfas
	Local cAfasta := ""

	// Variaveis da TRB
	Local nOpcao
	Local lInverte, lRet
	Local cTRB700 := GetNextAlias()

	Private cMarca := GetMark()

	lInverte:= .F.

	//Valores e Caracteristicas da TRB
	aDBF := {}
	aAdd( aDBF, { "TRB_OK", "C", 02, 0 } )
	aAdd( aDBF, { "TRB_COD", "C", 03, 0 } )
	aAdd( aDBF, { "TRB_DESC", "C", 75, 0 } )

	aTRBSX5 := {}
	aAdd( aTRBSX5, { "TRB_OK", NIL, " ", } )
	aAdd( aTRBSX5, { "TRB_COD", NIL, "Afastamento" , } )  //"Afastamento" // STR0309
	aAdd( aTRBSX5, { "TRB_DESC", NIL, "Descrição", } )  //"Descrição" // STR0310

	//Cria TRB
	oTemp700 := FWTemporaryTable():New( cTRB700, aDBF )
	oTemp700:AddIndex( "1", {"TRB_COD"} )
	oTemp700:AddIndex( "2", {"TRB_DESC"} )
	oTemp700:AddIndex( "3", {"TRB_OK"} )
	oTemp700:Create()

	Processa( {|lEnd| FSeachAfas( cTRB700 )}, "Buscando Afastamentos..." , "Espere" )//"Buscando Afastamentos..."//"Espere" / STR0307 / STR0308
	DBSelectArea( cTRB700 )
	DBGoTop()

	If (cTRB700)->(RecCount()) <= 0
		oTemp700:Delete()
		FWRestArea( aArea )
		Msgstop( "Não existem Afastamentos cadastrados" , "ATENÇÃO" )  //"Não existem Afastamentos cadastrados" //"ATENÇÃO" //STR0306
		Return .T.
	EndIf

	nOpcao := 0

	DEFINE MSDIALOG oDlgAfas TITLE OemToAnsi( "Afastamentos" ) From 150, 0 To 735, 550 PIXEL OF oMainWnd //"Afastamentos" STR0305

		oPanelAfas	:= TPanel():New( , , , oDlgAfas, , , , , , , , .F., .F. )
			oPanelAfas:Align	:= CONTROL_ALIGN_ALLCLIENT

			TGroup():New(8, 8, 40, 270, , oPanelAfas, , , .T.)
			TSay():New( 16, 12, {|| OemtoAnsi( "Estes são os Afastamentos cadastrados no sistema.") }, oPanelAfas, , , .F., .F., .F., .T., CLR_BLACK, CLR_WHITE, 200, 010 )//"Estes são os Afastamentos cadastrados no sistema."  STR0303
			TSay():New( 26, 12, {|| OemtoAnsi( "Selecione aqueles que são necessários a tarefa.") }, oPanelAfas, , , .F., .F., .F., .T., CLR_BLACK, CLR_WHITE, 200, 010 )//"Selecione aqueles que são necessários a tarefa." STR0304

			//Campo combo de indice para busca
			oAfasCombo := TComboBox():New( 45, 5, {|u| IIf( Pcount()>0, cKeyAfas:= u, cKeyAfas ) }, aAfasCombo,;
														 190, 10, oPanelAfas, , {|| MDT700ORAF( @oAfasCombo, @oGetAfas, @oMarkAfas, cTRB700 ) }, , , CLR_BLACK,;
														 .T., , , , , , , , , cKeyAfas, , , , CLR_BLACK )
			//Campo de busca
			oGetAfas := TGet():New( 58, 5, {|u| IIf( Pcount()>0, cResultAfas:= u, cResultAfas ) }, oPanelAfas, 190, 7, "@!",;
													 , CLR_BLACK, , , , , .T., , , {|| oAfasCombo:nAt <> 3 },;
													 , , , , , , cResultAfas, , , , , , , , , )
			//Botão de pesquisa
			oButtonAfas := TButton():New( 44, 200, "Pesquisar", oPanelAfas, {|| IIf( oAfasCombo:nAt <> 3, MDT700SEAR( @oAfasCombo, @oGetAfas, @oMarkAfas, cTRB700 ), .T. ) },; // STR0302
														 73, 12, , , , .T., , , , {|| oAfasCombo:nAt <> 3  }, , )//"Pesquisar"

			oMarkAfas:= MsSelect():NEW( cTRB700, "TRB_OK", , aTRBSX5, @lINVERTE, @cMARCA, { 73, 5, 260, 272 }, , , oPanelAfas )
				oMarkAfas:bMARK               := {|| MDT700MK( cMarca, cTRB700, @oAfasCombo, @oMarkAfas )}
				oMarkAfas:oBROWSE:lHASMARK    := .T.
				oMarkAfas:oBROWSE:lCANALLMARK := .T.
				oMarkAfas:oBROWSE:bALLMARK    := {|| MDT700INV( cTRB700, cMarca ) }

	ACTIVATE MSDIALOG oDlgAfas ON INIT EnchoiceBar( oDlgAfas, { || nOpcao := 1, oDlgAfas:End() }, { || nOpcao := 2, oDlgAfas:End() } ) Centered

	lRet := ( nOpcao == 1 )

	If lRet //Caso seja confirmado
		DBSelectArea( cTRB700 )
		DBGoTop()

		While !Eof()

			If !Empty( (cTRB700)->TRB_OK )
				cAfasta += (cTRB700)->TRB_COD
			Else
				cAfasta += "***"
			EndIf

			DBSkip()
		End

		If !Empty( cAfasta )
			MV_PAR36 := cAfasta
		EndIf

	ElseIf Empty( MV_PAR36 )
		MV_PAR36 := cAfasta
	EndIf

	oTemp700:Delete()

	FWRestArea( aArea )

Return .T.

/*
===============================================================================================================================
Programa--------------: RMDT006()
Autores---------------: Denis Hyroshi de Souza / Gabriel Sokacheski / Jorge Luis Siementkowski / Liber De Esteban 
                        Roger Rodrigues / Bruno Lobo de Souza / Guilherme Benkendorf / Guilherme Freudenburg (Totvs)
Conversão para Italac-: Julio de Paula Paz
Data da Criacao-------: 22/09/2023
Descrição-------------: Função responsável por realizar a busca de todos os tipos de
                        afastamentos cadastrados no sistema.
Parametros------------: cAliasTRB, 	 Caracter	, Alias da TRB utilizada.
Retorno---------------: Nil, vazio.
===============================================================================================================================
*/
Static Function FSeachAfas( cAliasTRB )
	Local aArea   := FWGetArea()

	//----------------------------------------
	//| Adiciona os tipos de Afastamentos.   |
	//----------------------------------------
	DBSelectArea( "RCM" )
	DBSetOrder( 1 )
	DBSeek( xFilial( "RCM" ) )

	While RCM->(!Eof()) .And. xFilial( "RCM" ) == RCM->RCM_FILIAL

		If RCM->RCM_TIPOAF == "1" //Afastamentos
			RecLock( cAliasTRB, .T. )
				(cAliasTRB)->TRB_OK := IIf( Len( AllTrim( MV_PAR36 ) ) > 1, IIf( AllTrim( RCM->RCM_TIPO ) $ MV_PAR36, cMarca, "" ),;
				 IIf( AllTrim( RCM->RCM_TIPO ) $ "003,004,010,011,012", cMarca, "" ) )
				(cAliasTRB)->TRB_COD := RCM->RCM_TIPO
				(cAliasTRB)->TRB_DESC := RCM->RCM_DESCRI
			(cAliasTRB)->(MSUnLock())
		EndIf

		RCM->(DBSkip())
	End

	FWRestArea( aArea )

Return

/*
===============================================================================================================================
Programa--------------: RMDT006()
Autores---------------: Denis Hyroshi de Souza / Gabriel Sokacheski / Jorge Luis Siementkowski / Liber De Esteban 
                        Roger Rodrigues / Bruno Lobo de Souza / Guilherme Benkendorf / Guilherme Freudenburg (Totvs)
Conversão para Italac-: Julio de Paula Paz
Data da Criacao-------: 22/09/2023
Descrição-------------: Função de ordenação para o MarkBrose conforme selecionado
                        no ComboBox
Parametros------------: oCombo	 , Object	, Objeto do comboBox
                        oGet	 , Object	, Objeto do campo Get
                        oMark 	 , Object	, Objeto do MarkBrowse
                        cAliasTRB, Caracter	, Alias da TRB utilizada.
Retorno---------------: Lógico, sempre verdadeiro
===============================================================================================================================
*/
Static Function MDT700ORAF( oCombo, oGet, oMark, cAliasTRB )

	Local nIndAfas := oCombo:nAt

	// Ordena TRB conforme selecionado no combo
	DBSelectArea( cAliasTRB )
	DBSetOrder( nIndAfas )
	DBGoTop()

	// Caso For marcação, limpa Get
	If nIndAfas == 3 //TRB_OK
		oGet:cText	:= Space( 60 )
	EndIf

	oMark:oBrowse:Refresh()

Return .T.

/*
===============================================================================================================================
Programa--------------: RMDT006()
Autores---------------: Denis Hyroshi de Souza / Gabriel Sokacheski / Jorge Luis Siementkowski / Liber De Esteban 
                        Roger Rodrigues / Bruno Lobo de Souza / Guilherme Benkendorf / Guilherme Freudenburg (Totvs)
Conversão para Italac-: Julio de Paula Paz
Data da Criacao-------: 22/09/2023
Descrição-------------: Função de busca do EPI para o Mark Browse.
Parametros------------: oCombo	 ,	 Object		, Objeto do comboBox
                        oGet	 ,	 Object		, Objeto do campo Get
                        oMark 	 , 	 Object		, Objeto do MarkBrowse
                        cAliasTRB, 	 Caracter	, Alias da TRB utilizada.
Retorno---------------: lRet,Lógico, caso encontre valores retorna .T.
===============================================================================================================================
*/
Static Function MDT700SEAR( oCombo, oGet, oMark, cAliasTRB )
	Local lRet    := .T.
	Local nInd    := oCombo:nAt
	Local cResult := AllTrim( oGet:cText )

	DBSelectArea( cAliasTRB )
	DBSetOrder( nInd )

	If ! ( lRet := DBSeek( cResult ) )
		MsgInfo( "Valor não encontrado.", "ATENÇÃO" )//"Valor não encontrado."##"ATENÇÃO" STR0301
		(cAliasTRB)->(DBGoTop())
	Else
		oMark:oBrowse:SetFocus()//Se encontra resultado, focaliza tela do mark
	EndIf

Return lRet

/*
===============================================================================================================================
Programa--------------: RMDT006()
Autores---------------: Denis Hyroshi de Souza / Gabriel Sokacheski / Jorge Luis Siementkowski / Liber De Esteban 
                        Roger Rodrigues / Bruno Lobo de Souza / Guilherme Benkendorf / Guilherme Freudenburg (Totvs)
Conversão para Italac-: Julio de Paula Paz
Data da Criacao-------: 22/09/2023
Descrição-------------: Efetua Ações na marcações do MarkBrowse.
Parametros------------: cMARCA	 , Caracter, Determina a marcação dos afastamentos.
                        cAliasTRB, Caracter, Alias da TRB utilizada.
                        oCombo	 , Object,	Objeto do campo combo.
                        oMark	 , Object,	Objeto do markbrowser.
Retorno---------------: Lógico, sempre verdadeiro.
===============================================================================================================================
*/
Static Function MDT700MK( cMarca, cAliasTRB, oCombo, oMark )
	Local nIndAfas := oCombo:nAt

	// Ordena o marcado quando For o indice 3 - Marcado
	If nIndAfas == 3
		DBSelectArea( cAliasTRB )
		DBSetOrder( nIndAfas )
		//Atualiza tela do Mark, para exibir a ordem
		oMark:oBrowse:Refresh()
	EndIf

Return .T.

/*
===============================================================================================================================
Programa--------------: RMDT006()
Autores---------------: Denis Hyroshi de Souza / Gabriel Sokacheski / Jorge Luis Siementkowski / Liber De Esteban 
                        Roger Rodrigues / Bruno Lobo de Souza / Guilherme Benkendorf / Guilherme Freudenburg (Totvs)
Conversão para Italac-: Julio de Paula Paz
Data da Criacao-------: 22/09/2023
Descrição-------------: Responsavel por inveter a marcação do Browser.
Parametros------------: cAliasTRB, Caracter, Alias da TRB utilizada.
                        cMARCA	, Caracter, Determina a marcação dos afastamentos.
Retorno---------------: Lógico, sempre verdadeiro.
===============================================================================================================================
*/
Static Function MDT700INV(cAliasTRB, cMARCA)
	Local aArea := (cAliasTRB)->(GetArea()) // Salva área posicionada.

	DBSelectArea( cAliasTRB )
	DBSetOrder( 1 )
	DBGoTop()

	While !Eof()
		(cAliasTRB)->TRB_OK := IIf( Empty( (cAliasTRB)->TRB_OK), cMARCA, Space( Len( cMARCA ) ) )
		DBSelectArea( cAliasTRB )
		( cAliasTRB )->( DBSkip() )
	End

	FWRestArea( aArea )
Return .T.

/*
===============================================================================================================================
Programa--------------: RMDT006()
Autores---------------: Denis Hyroshi de Souza / Gabriel Sokacheski / Jorge Luis Siementkowski / Liber De Esteban 
                        Roger Rodrigues / Bruno Lobo de Souza / Guilherme Benkendorf / Guilherme Freudenburg (Totvs)
Conversão para Italac-: Julio de Paula Paz
Data da Criacao-------: 22/09/2023
Descrição-------------: Busca a quantidade de afastamentos.
Parametros------------: Nenhum
Retorno---------------: nQuant, Numérico, Quantidade de afastamentos.
===============================================================================================================================
*/
Static Function MDT700RCM()

	Local nQuant := 0

	DBSelectArea( "RCM" )
	DBGoTop()

	While RCM->(!Eof()) .And. xFilial( "RCM" ) == RCM->RCM_FILIAL

		If RCM->RCM_TIPOAF == "1"
			nQuant++
		EndIf

		RCM->(DBSkip())
	End

	nQuant := nQuant * 3 //Multiplica por 3 mediante ao tamanho do campo RCM_TIPO

Return nQuant

/*
===============================================================================================================================
Programa--------------: RMDT006()
Autores---------------: Denis Hyroshi de Souza / Gabriel Sokacheski / Jorge Luis Siementkowski / Liber De Esteban 
                        Roger Rodrigues / Bruno Lobo de Souza / Guilherme Benkendorf / Guilherme Freudenburg (Totvs)
Conversão para Italac-: Julio de Paula Paz
Data da Criacao-------: 22/09/2023
Descrição-------------: Função responsavel por realizar a validação do SX1 - MV_PAR36
Parametros------------: Nenhum
Retorno---------------: lRet, Lógico, Verdadeiro quando não ocorrer alguma inconsistência.
===============================================================================================================================
*/
Static Function MDT700VALF()

	Local lRet := .T.
	Local aAfast := {} // Recebe os tipos de afastamentos.
	Local cMvAfas := MV_PAR36
	Local aMvAfas := {}
	Local nX := 0

	While !Empty( cMvAfas ) .And. lRet

		If ( SubStr( cMvAfas, 1, 3 ) <> "***" .And. aScan( aMvAfas, { |x| x == SubStr( cMvAfas, 1, 3 ) } ) == 0  .Or. SubStr( cMvAfas, 1, 3 ) == "***" )
			aAdd( aMvAfas, SubStr( cMvAfas, 1, 3 ) )
			cMvAfas := SubStr( cMvAfas, 4 )
		Else
			lRet := .F.
			ShowHelpDlg( "ATENÇÃO", { "Não é permitido incluir tipos de afastamentos iguais." }, 2, { "Favor selecionar apenas um de cada tipo de afastamento." }, 2 ) //Atenção ## "Não é permitido incluir tipos de afastamentos iguais." ## "Favor selecionar apenas um de cada tipo de afastamento." STR0316 / STR0317 
		EndIf

	End

	// Adiciona os tipos de Afastamentos.
	If lRet
		DBSelectArea( "RCM" )
		DBSetOrder( 1 )
		DBSeek( xFilial( "RCM" ) )
		While RCM->(!Eof()) .And. xFilial( "RCM" ) == RCM->RCM_FILIAL

			If RCM->RCM_TIPOAF == "1" //Afastamentos
				aAdd( aAfast, AllTrim( RCM->RCM_TIPO ) )
			EndIf

			RCM->(DBSkip())
		End

		If Len( aMvAfas ) > 0

			For nX := 1 To Len( aMvAfas )

				If aScan( aAfast, { |x| x == aMvAfas[nX] } ) == 0 .And. aMvAfas[nX] <> '***'
					lRet := .F.
					Help( " ", 1, "REGNOIS" )
					Exit
				EndIf

			Next nX

		EndIf

	EndIf

Return lRet

/*
===============================================================================================================================
Programa--------------: RMDT006()
Autores---------------: Denis Hyroshi de Souza / Gabriel Sokacheski / Jorge Luis Siementkowski / Liber De Esteban 
                        Roger Rodrigues / Bruno Lobo de Souza / Guilherme Benkendorf / Guilherme Freudenburg (Totvs)
Conversão para Italac-: Julio de Paula Paz
Data da Criacao-------: 22/09/2023
Descrição-------------: Faz a impressao de memos para o PPP
Parametros------------: cMemo, Caracter, Memo a ser impresso
Retorno---------------: Nenhum
===============================================================================================================================
*/
Static Function fImpMemo(cMemo)

	Local linhaCorrente
	Local nLinhasMemo := MlCount( cMemo, 148 )

	// Cria um pequeno espacamento entre o titulo e o memo
	If !Empty( cMemo )
		oPrintPPP:Line( lin, 50, lin + 25, 50 )
		oPrintPPP:Line( lin, 2940, lin + 25, 2940 )
		SomaLinha( 25, .T. )
	EndIf

	// Faz a impressao do memo
	For linhaCorrente := 1 To nLinhasMemo

		oPrintPPP:Line( lin, 50, lin + 40, 50 )
		oPrintPPP:Line( lin, 2940, lin + 40, 2940 )

		// Verifica se o texto a ser impresso tem tamanho maior do que 80% do tamanho máximo da linha
		If Len( AllTrim( MemoLine( cMemo, 148, LinhaCorrente ) ) ) > 118
			oPrintPPP:Say( lin + 30, 60, AV_Justifica( MemoLine( cMemo, 148, LinhaCorrente ) ), oFont08 )
		Else // Não justifica para não fazer espaçamentos grandes demais entre as palavras
			oPrintPPP:Say( lin + 30, 60, MemoLine( cMemo, 148, LinhaCorrente ), oFont08 )
		EndIf

		// Quando acaba a impressao desenha as linhas que fecham a secao
		If linhaCorrente == nLinhasMemo
			oPrintPPP:Line( lin + 40, 50, lin + 55, 50 )
			oPrintPPP:Line( lin + 40, 2940, lin + 55, 2940 )
			oPrintPPP:Line( lin + 55, 50, lin + 55, 2940 )
		Else
			SomaLinha( 40, .T. )
		EndIf

	Next

Return

/*
===============================================================================================================================
Programa--------------: RMDT006()
Autores---------------: Denis Hyroshi de Souza / Gabriel Sokacheski / Jorge Luis Siementkowski / Liber De Esteban 
                        Roger Rodrigues / Bruno Lobo de Souza / Guilherme Benkendorf / Guilherme Freudenburg (Totvs)
Conversão para Italac-: Julio de Paula Paz
Data da Criacao-------: 22/09/2023
Descrição-------------: Incrementa linha e quebra pagina
Parametros------------: nLi   , Numerico      , Espacamento que tera a quebra de linha
                        lLinha, Logico, Se .T., faz uma linha no final da pagina
                        lPula , Logico, Se .T., quebra a pagina independente da posicao atual da linha

Retorno---------------: Nenhum
===============================================================================================================================
*/
Static Function SomaLinha( nLi, lLinha, lPula )

	If nLi != Nil
		lin += nLi
	Else
		lin += 60
	EndIf

	If lin > 2000 .Or. lPula

		If lLinha
			oPrintPPP:Line( lin, 50, lin, 2940 )
		EndIf

		oPrintPPP:SayAlign( 2200, 50, Str( nPaginaPPP, 3 ), oFont09n, 2940, 280, CLR_BLACK, 2, 1 )
		oPrintPPP:EndPage()
		nPaginaPPP++
		oPrintPPP:StartPage()
		lin := 380
		oPrintPPP:SayAlign( 250, 50, "PERFIL PROFISSIOGRÁFICO PREVIDENCIÁRIO - PPP", oFont13, 2940, 280, CLR_BLACK, 2, 1 ) //STR0149= "PERFIL PROFISSIOGRÁFICO PREVIDENCIÁRIO - PPP"
		oPrintPPP:Line( lin, 50, lin, 2940 )
	EndIf

Return

/*
===============================================================================================================================
Programa--------------: RMDT006()
Autores---------------: Denis Hyroshi de Souza / Gabriel Sokacheski / Jorge Luis Siementkowski / Liber De Esteban 
                        Roger Rodrigues / Bruno Lobo de Souza / Guilherme Benkendorf / Guilherme Freudenburg 
						Eduardo Mussi(Totvs)
Conversão para Italac-: Julio de Paula Paz
Data da Criacao-------: 22/09/2023
Descrição-------------: Valida centro de custo caso o funcionário tenha sido transferido
Parametros------------: Nenhum
Retorno---------------: Lógico, .T. caso encontre um centro de custo compativel
===============================================================================================================================
*/
Static Function fVlCCSRE()

	Local aBind     := {}
	Local cAliasSRE := GetNextAlias()
	Local lReturn   := .T.

	/*----------------------------------------+
	| Verifica a existência da query em cache |
	+----------------------------------------*/
	If Empty( cQryVlCC )
		
		cQryVlCC :=	'SELECT SRE.RE_CCD '
		cQryVlCC +=	'	FROM ' + RetSqlName( 'SRE' ) + ' SRE '
		cQryVlCC +=	'WHERE SRE.RE_EMPD    = ? '
		cQryVlCC +=	'  AND SRE.RE_FILIALD = ? '
		cQryVlCC +=	'  AND SRE.RE_MATD    = ? '
		cQryVlCC +=	'  AND SRE.RE_DATA   >= ? '
		cQryVlCC +=	'  AND SRE.RE_CCD     = ? '
		cQryVlCC +=	'  AND SRE.D_E_L_E_T_ = ? '

		cQryVlCC := ChangeQuery( cQryVlCC )
	
	EndIf
	
	aBind := {}
	aAdd( aBind, (cTRBPPP)->EMP    )
	aAdd( aBind, (cTRBPPP)->FILIAL )
	aAdd( aBind, (cTRBPPP)->MAT    )
	aAdd( aBind, DToS( (cTRBPPP)->DTATE ) )
	aAdd( aBind, (cTRBPPP)->CUSTO  )
	aAdd( aBind, Space( 1 )        )

	dbUseArea( .T., 'TOPCONN', TcGenQry2( , , cQryVlCC, aBind ), cAliasSRE, .T., .T. )

	lReturn := (cAliasSRE)->( !Eof() )

	(cAliasSRE)->( DBCloseArea() )

	/*------------------------------------------------+
	| Libera consumo de memória p/ melhor performance |
	+------------------------------------------------*/
	aSize( aBind, 0 )
	aBind := Nil

Return lReturn

/*
===============================================================================================================================
Programa--------------: RMDT006()
Autores---------------: Denis Hyroshi de Souza / Gabriel Sokacheski / Jorge Luis Siementkowski / Liber De Esteban 
                        Roger Rodrigues / Bruno Lobo de Souza / Guilherme Benkendorf / Guilherme Freudenburg 
						Eduardo Mussi / Elisson França (Totvs)
Conversão para Italac-: Julio de Paula Paz
Data da Criacao-------: 22/09/2023
Descrição-------------: Valida se os tipos de medidade controle são: 
                        Tipo da Medida de Controle = "2" (Protecao Coletiva) ou Medida de Controle = "4" ( Administrativas )
Parametros------------: cFilRis, Caracter, Filial do funcionario
Retorno---------------: cTipCtr, Caracter, retorna a medida de controle
===============================================================================================================================
*/
Static Function fVlMedCon( cFilRis )
	
	Local cTipCtr   := ""
	Local lExisMed  := .T.
	Local cNumRis   := ( cTRBTN0 )->NUMRIS

	DBSelectArea( "TJF" )
	DBSetOrder( 1 )
	DBSeek( xFilial( "TJF" , cFilRis ) + cNumRis )

	While !Eof() .And. lExisMed

		DBSelectArea( "TO4" )
		DBSetOrder( 1 )
		If DBSeek( xFilial( "TO4" ) + TJF->TJF_MEDCON )

			If TO4->TO4_TIPCTR == "2"

				lExisMed := .F.
				cTipCtr := TO4->TO4_TIPCTR 
				Exit

			ElseIf TO4->TO4_TIPCTR == "4"

				cTipCtr := TO4->TO4_TIPCTR 

			Else
				
				lExisMed := .F.
				Exit

			EndIf
			
		EndIf

		( 'TJF' )->( DBSkip() )
		
	End

Return cTipCtr
