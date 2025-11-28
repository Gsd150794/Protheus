/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |23/05/2025| Chamado 50754. Incluído tratamento para CT-e Simplificado
Lucas Borges  |17/09/2025| Chamado 52161. Incluída validação para tags que não são obrigatórias
Lucas Borges  |05/10/2025| Chamado 52325. Incluído tratamento para algumas tags do CT-e Simplificado
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "COLORS.CH"
#Include "RPTDEF.CH"
#Include "FWPrintSetup.ch"

#DEFINE doDTC_SERNFC	1
#DEFINE doDTC_NUMNFC	2
#DEFINE doDTC_NFEID		8
#DEFINE doDTC_CTEID		9

/*
===============================================================================================================================
Programa--------: MCOM025
Autor-----------: Lucas Borges Ferreira
Data da Criacao-: 16/05/2024
Descrição-------: Realiza a impressão dos Dacte dos documentos de entrada (RTMSR35). Chamado 47282
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function MCOM025(oDacte As Object, oSetup As Object, cFilePrint As Character, _cMarca As Character)
Local lJob		:= isBlind()
Local aArea     := FWGetArea()
Local lExistNfe := .F.

Private nConsNeg := 0.4 // Constante para concertar o cálculo retornado pelo GetTextWidth para fontes em negrito.
Private nConsTex := 0.5 // Constante para concertar o cálculo retornado pelo GetTextWidth.
Private oRetNF

Default _cMarca := ' '

lJob := (oDacte:lInJob .Or. oSetup == nil)
oDacte:SetResolution(72) //Tamanho estipulado para a Danfe
oDacte:SetPortrait()
oDacte:SetPaperSize(DMPAPER_A4)
oDacte:SetMargin(60,60,60,60)
oDacte:lServer := If( lJob , .T., oSetup:GetProperty(PD_DESTINATION)==AMB_SERVER )
// ----------------------------------------------
// Define saida de impressão
// ----------------------------------------------
If lJob .Or. oSetup:GetProperty(PD_PRINTTYPE) == IMP_PDF
	oDacte:nDevice := IMP_PDF
	// ----------------------------------------------
	// Define para salvar o PDF
	// ----------------------------------------------
	oDacte:cPathPDF := If ( lJob , __RelDir , oSetup:aOptions[PD_VALUETYPE] )
ElseIf oSetup:GetProperty(PD_PRINTTYPE) == IMP_SPOOL
	oDacte:nDevice := IMP_SPOOL
	oDacte:SetParm( "-RFS")
	// ----------------------------------------------
	// Salva impressora selecionada
	// ----------------------------------------------
	fwWriteProfString(GetPrinterSession(),"DEFAULT", oSetup:aOptions[PD_VALUETYPE], .T.)
	oDacte:cPrinter := oSetup:aOptions[PD_VALUETYPE]
EndIf

RPTStatus( {|lEnd| DACTE(@oDacte, _cMarca, @lEnd, @lExistNFe)}, "Imprimindo DANFE..." )

If lExistNFe
	oDacte:Preview()//Visualiza antes de imprimir
Else
	Aviso("DANFE","Nenhuma NF-e a ser impressa nos parametros utilizados.",{"OK"},3)
EndIf

FreeObj(oDacte)
oDacte := Nil
oSetup := Nil

FWRestArea(aArea)

Return

/*
===============================================================================================================================
Programa--------: DACTE
Autor-----------: Eduardo Riera
Data da Criacao-: 16/01/2006
Descrição-------: Rdmake de exemplo para impressão da DANFE no formato Retrato
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function DACTE(oDacte,_cMarca,lEnd,lExistNfe)

Local aArea		:= FWGetArea()
Local cWhere	:= "%"
Local cAviso	:= ""
Local cErro		:= ""
Local oNfe		:= Nil
Local cAlias	:= ""
Local cNoImpr	:= "" 

Default lEnd		:= .F.

If Empty(_cMarca)
	cWhere += " AND R_E_C_N_O_ = "+CValToChar(CKO->(RECNO()))
Else
	cWhere += " AND CKO_I_OK = '"+_cMarca+"'"
EndIf
cWhere += " %"
cAlias := GetNextAlias()

BeginSql Alias cAlias
	SELECT R_E_C_N_O_ RECNO FROM %Table:CKO% 
	WHERE D_E_L_E_T_ = ' '
	AND CKO_CODEDI IN ('214','273')
	%exp:cWhere%
	ORDER BY CKO_FILPRO, CKO_I_EMIT, CKO_ARQUIV
EndSql

While (cAlias)->(!Eof())
	CKO->(DBGoTo((cAlias)->RECNO))
	lExistNFe := .T.
	oRetNF := XmlParser(IIf(CKO->CKO_I_ALTX=="N",CKO->CKO_XMLRET,CKO->CKO_I_ORIG),"_",@cAviso,@cErro)
	
	If ValType(XmlChildEx(oRetNF,"_CTE")) == "O" //-- Nota de transporte
		oRetNF := oRetNF:_CTe
	ElseIf ValType(XmlChildEx(oRetNF,"_CTESIMPPROC")) == "O" //CT-e Simplificado
	    oRetNF := oRetNF:_CTeSimpProc:_CTeSimp
	ElseIf ValType(XmlChildEx(oRetNF,"_CTEPROC")) == "O"
		If ValType(XmlChildEx(oRetNF:_CTEPROC,"_ENVICTE")) == "O" //-- Nota de transporte
			oRetNF := oRetNF:_CTeProc:_ENVICTE:_Cte
		ElseIf ValType(XmlChildEx(oRetNF:_CTEPROC,"_CTEOS")) == "O" //-- Nota de transporte CTEOS
			oRetNF := oRetNF:_CTeProc:_CTEOS
		Else
			oRetNF := oRetNF:_CTeProc:_Cte
		EndIf
	ElseIf ValType(XmlChildEx(oRetNF,"_CTEOSPROC")) == "O"
        oRetNF := oRetNF:_CTeOSProc:_CteOS
	EndIf
	If ValType(XmlChildEx(oRetNF,"_CTEPROC")) == "O"
		oNfe := WSAdvValue( oRetNF,"_CTEPROC","string",NIL,NIL,NIL,NIL,NIL)
	Else
		oNfe := oRetNF
	EndIf
	If Empty( cAviso ) .And. Empty( cErro )
		PrtDacte(@oDacte,oNfe)
		RecLock("CKO",.F.)
			CKO->CKO_I_IMP := CKO->CKO_I_IMP+1
			CKO->CKO_I_DTIM := Date()
		MSUnLock()
	Else
		cNoImpr += SubStr(CKO->CKO_ARQUIV,4,44) + " / "
	EndIf

	oNfe     := nil
	delClassIntF()
	(cAlias)->(DBSkip())
EndDo
(cAlias)->(DBCloseArea())
FWRestArea(aArea)

//Mensagem para informar os DACTE's que tiveram problema de impressao e nao foram impressas
If !Empty(cNoImpr)
	FWAlertWarning("Os seguinte documentos não foram impressos por apresentarem inconsistências no XML: "+CRLF+cNoImpr)		//"Os seguinte documentos não foram impressos: "
EndIf

Return .T.
/*
===============================================================================================================================
Programa--------: PrtDanfe
Autor-----------: Eduardo Riera
Data da Criacao-: 16/01/2006
Descrição-------: Impressao do formulario DANFE grafico conforme laytout no formato retrato
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function PrtDacte(oDacte,oNFE)

Local nCount		:= 0
Local nSoma			:= 0
Local nCInic		:= 0	// Coluna Inicial
Local cChaveA		:= ''
Local cChaveB		:= ''
Local cTmsAntt		:= SuperGetMv( "MV_TMSANTT", .F., .F. )	//Numero do registro na ANTT com 14 dígitos
Local cTmsCOTM		:= SuperGetMv( "MV_TMSCOTM", .F., .F. )	//Numero do registro da OTM
Local aCab			:= {}
Local aDoc			:= {}
Local oFont07		:= TFont():New("Times New Roman",07,07,,.F.,,,,.T.,.F.)
Local oFont08		:= TFont():New("Times New Roman",08,08,,.F.,,,,.T.,.F.)
Local oFont08N		:= TFont():New("Times New Roman",08,08,,.T.,,,,.T.,.F.)
Local oFont10N		:= TFont():New("Times New Roman",10,10,,.T.,,,,.T.,.F.)
Local lControl		:= .F.
Local nCont			:= 0
Local lSeqDes		:= .F.
Local lSeqRec		:= .F.
Local cDT6Obs		:= ''
Local cDT6Obs2		:= ''
Local cDT6Obs3		:= '' 
Local cDTCObs		:= ''
Local aDTCObserv	:= {"","","","","","","",""} //--Linha da Observação proveniente da tabela DTC
Local nCountDTC		:= 0
Local cObsProp		:= ''
Local cObsStat		:= ''
Local nCountObs		:= 0
Local nLinhaObs  	:= 0
Local aObsCont		:= ''
Local cCtrDpc		:= ''
Local cSerDpc		:= ''
Local cCTEDocAnt	:= ''
//-- Buscar dados XML
Local cHorAut		:= ""
Local cDatAut		:= ""
Local nX			:= 0
//-- CFOP - Natureza da Prestacao
Local cCFOP			:= ''
Local cDescCfop		:= ''
//-- Origem Prestacao
Local cOriMunPre	:= ""
Local cOriUFPre		:= ""
//-- Destino Prestacao
Local cDesMunPre	:= ""
Local cDesUFPre		:= ""
//-- Remetente
Local cRemMun		:= ""
Local cRemUF		:= ""
Local cRemNome		:= ""
Local cRemEnd		:= ""
Local cRemNro		:= ""
Local cRemCompl		:= ""
Local cRemBair		:= ""
Local cRemCEP		:= ""
Local cRemCNPJ		:= ""
Local cRemIE		:= ""
Local cRemPais		:= ""
Local cRemFone		:= ""
//-- Destinatario
Local cDesMun		:= ""
Local cDesUF		:= ""
Local cDesNome		:= ""
Local cDesEnd		:= ""
Local cDesNro		:= ""
Local cDesCompl		:= ""
Local cDesBair		:= ""
Local cDesCEP		:= ""
Local cDesCNPJ		:= ""
Local cDesIE		:= ""
Local cDesPais		:= ""
Local cDesFone		:= ""
//-- Expedidor
Local cExpNome		:= ""
Local cExpEnd		:= ""
Local cExpNro		:= ""
Local cExpMun		:= ""
Local cExpBai		:= ""
Local cExpUF		:= ""
Local cExpPais		:= ""
//-- Recebedor
Local cRecNome		:= ""
Local cRecEnd		:= ""
Local cRecNro   	:= ""
Local cRecBai		:= ""
Local cRecMun		:= ""
Local cRecUF		:= ""
Local cRecCEP		:= ""
Local cRecFone  	:= ""
Local lRecPJ		:= .F.
Local cRecCGC		:= ""
Local cRecCPF		:= ""
Local cRecINSCR		:= ""
Local cRecPais		:= ""
Local cRecCompl 	:= ""
//-- Tomador do Servico
Local cDevMun		:= ""
Local cDevUF		:= ""
Local cDevNome		:= ""
Local cDevEnd		:= ""
Local cDevNro		:= ""
Local cDevCompl		:= ""
Local cDevBair		:= ""
Local cDevCEP		:= ""
Local cDevCNPJ		:= ""
Local cDevIE		:= ""
Local cDevPais		:= ""
Local cDevFone		:= ""
//-- Produto Predominante
Local cPPDesc		:= ""
Local cPPCarga	:= ""
Local cPPVlTot	:= ""
Local cPPPesoB	:= ""
Local cPPPeso3	:= ""
Local cPPMetro3	:= ""
Local cPPQtdVol	:= ""
Local cPesoBC   := ""

//-- Documentos Originarios
Local aDocOri		:= {}
//Lotação
Local cDesDocAnt	:= ""
Local lPerig		:= .F.	//-- Informa se ha produtos perigosos
Local cTipoDoc		:= ''
Local cTagObs		:= ''
Local nLinIEM		:= 0 //-- valor de ajuste de salto pra as linhas relacionadas a Informações do Modal Rodoviário
Local cEndCom		:= ""

//-- Variaveis Private
Private nLInic		:= 0	// Linha Inicial
Private nLFim		:= 0	// Linha Inicial
Private nDifEsq		:= 0	// Variavel com Diferenca para alinhar os Print da Esquerda com os da Direita
Private cInsRemOpc	:= ''	// Remetente com sequencia de IE
Private nFolhas		:= 1
Private nFolhAtu	:= 1
Private PixelX		:= nil
Private PixelY		:= nil
Private nMM			:= 0
Private lComp		:= .F.	//CTE Complementar
Private cVersaoCTE	:= ""

PixelX  := oDacte:nLogPixelX()
PixelY  := oDacte:nLogPixelY()
nMM     := 0

	oDacte:StartPage()

	cExpMun		:= ""
	cExpUF		:= ""
	cExpNome	:= ""
	cExpEnd		:= ""
	cExpNro		:= ""
	cExpCompl	:= ""
	cExpBai		:= ""
	cExpCEP		:= ""
	cExpCNPJ	:= ""
	cExpIE		:= ""
	cExpPais	:= ""
	cExpFone	:= ""
	cHorAut		:= ""
	cDatAut		:= ""
	lExped		:= .F.

	nX   := 1
	nFolhas := 1
	// Controla o documento a ser enviado para montagem do cabecalho.
	nCont += 1
		aAdd(aCab, {;
		AllTrim(oNfe:_INFCTE:_IDE:_NCT:TEXT),;
		AllTrim(oNfe:_INFCTE:_IDE:_SERIE:TEXT),;
		AllTrim(StrTran( SubStr( oNfe:_INFCTE:_IDE:_dhEmi:TEXT, 1, AT('T', oNfe:_INFCTE:_IDE:_dhEmi:TEXT) - 1) , '-', '')),;
		AllTrim(StrTran( SubStr( oNfe:_INFCTE:_IDE:_dhEmi:TEXT, AT('T', oNfe:_INFCTE:_IDE:_dhEmi:TEXT) + 1, 5) , ':', '')),;
		AllTrim(StrTran(Upper(oNFE:_INFCTE:_ID:TEXT),'CTE','')),;
		""/*(cAliasCT)->DT6_PROCTE*/,"" ,cDatAut, cHorAut})	//-- Nao possui ref. no XML
	
	// Funcao responsavel por montar o cabecalho do relatorio
	nFolhAtu := 1
	lSeqDes  :=.F.
	lSeqRec  :=.F.
	TMSR31Cab(oDacte, oNfe, aCab[nCont])

	//-- Estrutura da funcao que retorna o logradouro, numero e complemento.
	//-- Logradouro		FisGetEnd(XXXXXXXX)[1]
	//-- Numero			FisGetEnd(XXXXXXXX)[2]
	//-- Complemento	FisGetEnd(XXXXXXXX)[4]

	//-- CFOP
	cCFOP		:= AllTrim(oNfe:_INFCTE:_IDE:_CFOP:TEXT)
	cDescCfop	:= AllTrim(oNfe:_INFCTE:_IDE:_NATOP:TEXT)

	//-- Origem da Prestacao
	cOriMunPre	:= IIf(XmlChildEx( oNfe:_INFCTE:_IDE, '_XMUNINI') == NIL," ",oNfe:_INFCTE:_IDE:_XMUNINI:TEXT )
	cOriUFPre	:= oNfe:_INFCTE:_IDE:_UFINI:TEXT

	//-- Destino da Prestacao
	cDesMunPre	:= IIf(XmlChildEx( oNfe:_INFCTE:_IDE, '_XMUNFIM') == NIL," ",oNfe:_INFCTE:_IDE:_XMUNFIM:TEXT )
	cDesUFPre	:= IIf(XmlChildEx( oNfe:_INFCTE:_IDE, '_UFFIM') == NIL," ",oNfe:_INFCTE:_IDE:_UFFIM:TEXT )

	//-- Remetente
	If XmlChildEx(oNfe:_INFCTE,'_REM') <> NIL
		cRemMun   := oNfe:_INFCTE:_REM:_ENDERREME:_XMUN:TEXT
		cRemUF    := oNfe:_INFCTE:_REM:_ENDERREME:_UF:TEXT
		cRemNome  := oNfe:_INFCTE:_REM:_XNOME:TEXT
		cRemEnd   := oNfe:_INFCTE:_REM:_ENDERREME:_XLGR:TEXT
		cRemNro   := oNfe:_INFCTE:_REM:_ENDERREME:_NRO:TEXT
		cRemCompl := IIf(XmlChildEx(oNfe:_INFCTE:_REM:_ENDERREME,'_XCPL' )== NIL," ",oNfe:_INFCTE:_REM:_ENDERREME:_XCPL:TEXT)
		cRemBair  := IIf(XmlChildEx(oNfe:_INFCTE:_REM:_ENDERREME,'_XBAIRRO' )== NIL," ",oNfe:_INFCTE:_REM:_ENDERREME:_XBAIRRO:TEXT)
		cRemCEP   := IIf(XmlChildEx(oNfe:_INFCTE:_REM:_ENDERREME,'_CEP' )== NIL," ",oNfe:_INFCTE:_REM:_ENDERREME:_CEP:TEXT)
		cRemCNPJ  := IIf(XmlChildEx(oNfe:_INFCTE:_REM,'_CNPJ') == Nil,oNfe:_INFCTE:_REM:_CPF:TEXT,oNfe:_INFCTE:_REM:_CNPJ:TEXT)
		cRemIE    := IIf(XmlChildEx(oNfe:_INFCTE:_REM,'_IE' ) == Nil," ",oNfe:_INFCTE:_REM:_IE:TEXT)
		cRemPais  := IIf(XmlChildEx(oNfe:_INFCTE:_REM:_ENDERREME,'_XPAIS') == Nil," ",oNfe:_INFCTE:_REM:_ENDERREME:_XPAIS:TEXT)
		cRemFone  := IIf(XmlChildEx(oNfe:_INFCTE:_REM,'_FONE') == Nil," ",oNfe:_INFCTE:_REM:_FONE:TEXT)
	EndIf
	//-- Expedidor
	If (XmlChildEx(oNfe:_INFCTE,'_EXPED')) <> Nil
		lExped		:= .T.
		cExpMun		:= oNfe:_INFCTE:_EXPED:_ENDEREXPED:_XMUN:TEXT
		cExpUF		:= oNfe:_INFCTE:_EXPED:_ENDEREXPED:_UF:TEXT
		cExpNome	:= oNfe:_INFCTE:_EXPED:_XNOME:TEXT
		cExpEnd		:= oNfe:_INFCTE:_EXPED:_ENDEREXPED:_XLGR:TEXT
		cExpNro		:= oNfe:_INFCTE:_EXPED:_ENDEREXPED:_NRO:TEXT
		cExpCompl 	:= ""
		cExpBai		:= IIf(XmlChildEx(oNfe:_INFCTE:_EXPED:_ENDEREXPED,'_XBAIRRO' )== NIL," ",oNfe:_INFCTE:_EXPED:_ENDEREXPED:_XBAIRRO:TEXT)
		cExpCEP		:= IIf(XmlChildEx(oNfe:_INFCTE:_EXPED:_ENDEREXPED,'_CEP' )== NIL," ",oNfe:_INFCTE:_EXPED:_ENDEREXPED:_CEP:TEXT)
		cExpCNPJ	:= IIf(XmlChildEx(oNfe:_INFCTE:_EXPED,'_CNPJ')==Nil, oNfe:_INFCTE:_EXPED:_CPF:TEXT , oNfe:_INFCTE:_EXPED:_CNPJ:TEXT)
		cExpIE		:= IIf(XmlChildEx(oNfe:_INFCTE:_EXPED,'_IE' )==Nil," ",oNfe:_INFCTE:_EXPED:_IE:TEXT)
		cExpPais	:= IIf(XmlChildEx(oNfe:_INFCTE:_EXPED:_ENDEREXPED,'_XPAIS')==Nil," ",oNfe:_INFCTE:_EXPED:_ENDEREXPED:_XPAIS:TEXT)
		cExpFone	:= IIf(XmlChildEx(oNfe:_INFCTE:_EXPED,'_FONE')==Nil," ",oNfe:_INFCTE:_EXPED:_FONE:TEXT)
	EndIf

	//-- Destinatario
	If XmlChildEx(oNfe:_INFCTE,'_DEST') <> Nil
		cDesMun   := oNfe:_INFCTE:_DEST:_ENDERDEST:_XMUN:TEXT
		cDesUF    := oNfe:_INFCTE:_DEST:_ENDERDEST:_UF:TEXT
		cDesNome  := oNfe:_INFCTE:_DEST:_XNOME:TEXT
		cDesEnd   := oNfe:_INFCTE:_DEST:_ENDERDEST:_XLGR:TEXT
		cDesNro   := oNfe:_INFCTE:_DEST:_ENDERDEST:_NRO:TEXT
		cDesCompl := IIf(XmlChildEx(oNfe:_INFCTE:_DEST:_ENDERDEST,'_XCPL' ) == Nil," ", oNfe:_INFCTE:_DEST:_ENDERDEST:_XCPL:TEXT)
		cDesBair  := IIf(XmlChildEx(oNfe:_INFCTE:_DEST:_ENDERDEST,'_XBAIRRO' ) == Nil," ", oNfe:_INFCTE:_DEST:_ENDERDEST:_XBAIRRO:TEXT)
		cDesCEP   := IIf(XmlChildEx(oNfe:_INFCTE:_DEST:_ENDERDEST,'_XCEP' ) == Nil," ", oNfe:_INFCTE:_DEST:_ENDERDEST:_XCEP:TEXT)
		cDesCNPJ  := IIf(XmlChildEx(oNfe:_INFCTE:_DEST,'_CNPJ') == Nil,    oNfe:_INFCTE:_DEST:_CPF:TEXT, oNfe:_INFCTE:_DEST:_CNPJ:TEXT)
		cDesIE    := IIf(XmlChildEx(oNfe:_INFCTE:_DEST,'_IE'  ) == Nil," ",oNfe:_INFCTE:_DEST:_IE:TEXT)
		cDesPais  := IIf(XmlChildEx(oNfe:_INFCTE:_DEST:_ENDERDEST,'_XPAIS') == Nil," ",oNfe:_INFCTE:_DEST:_ENDERDEST:_XPAIS:TEXT)
		cDesFone  := IIf(XmlChildEx(oNfe:_INFCTE:_DEST,'_FONE') == Nil," ",oNfe:_INFCTE:_DEST:_FONE:TEXT)
	EndIf

	//-- Local de Entrega
	If XmlChildEx(oNfe:_INFCTE,'_RECEB') <> Nil .And. XmlChildEx(oNfe:_INFCTE:_RECEB,'_ENDERRECEB') <> Nil
		lSeqRec := .T.
		//Destino Recebedor
		cRecNome	:= oNfe:_INFCTE:_RECEB:_XNOME:TEXT
		cRecEnd		:= oNfe:_INFCTE:_RECEB:_ENDERRECEB:_XLGR:TEXT
		cRecNro  	:= oNfe:_INFCTE:_RECEB:_ENDERRECEB:_NRO:TEXT
		cRecBai		:= IIf( XmlChildEx(oNfe:_INFCTE:_RECEB:_ENDERRECEB,'_XBAIRRO')== Nil," ",oNfe:_INFCTE:_RECEB:_ENDERRECEB:_XBAIRRO:TEXT)
		cRecMun		:= IIf( XmlChildEx(oNfe:_INFCTE:_RECEB:_ENDERRECEB,'_XMUN')== Nil," ",oNfe:_INFCTE:_RECEB:_ENDERRECEB:_XMUN:TEXT)
		crecUF		:= IIf( XmlChildEx(oNfe:_INFCTE:_RECEB:_ENDERRECEB,'_XUF')== Nil," ",oNfe:_INFCTE:_RECEB:_ENDERRECEB:_XUF:TEXT)
		cRecPais  	:= IIf( XmlChildEx(oNfe:_INFCTE:_RECEB:_ENDERRECEB,'_XPAIS')== Nil," ",oNfe:_INFCTE:_RECEB:_ENDERRECEB:_XPAIS:TEXT)
		cRecCompl 	:= IIf( XmlChildEx(oNfe:_INFCTE:_RECEB:_ENDERRECEB,'_XCPL') == Nil," ",oNfe:_INFCTE:_RECEB:_ENDERRECEB:_XCPL:TEXT )
		cRecCEP   	:= IIf( XmlChildEx(oNfe:_INFCTE:_RECEB:_ENDERRECEB,'_CEP')  == Nil," ",oNfe:_INFCTE:_RECEB:_ENDERRECEB:_CEP:TEXT  )
		
		cRecFone := IIf( XmlChildEx(oNfe:_INFCTE:_RECEB,'_FONE') == Nil," ",oNfe:_INFCTE:_RECEB:_FONE:TEXT )
		If Empty(cRecFone)
			cRecFone := IIf( XmlChildEx(oNfe:_INFCTE:_RECEB:_ENDERRECEB,'_FONE') == Nil," ",oNfe:_INFCTE:_RECEB:_ENDERRECEB:_FONE:TEXT )
		EndIf

		If XmlChildEx(oNfe:_INFCTE:_RECEB,'_CNPJ')==Nil
			cRecCPF	:= oNfe:_INFCTE:_RECEB:_CPF:TEXT
		Else
			cRecCGC	:= oNfe:_INFCTE:_RECEB:_CNPJ:TEXT				
			cRecINSCR := IIf(XmlChildEx(oNfe:_INFCTE:_RECEB,'_IE' )==Nil," ",oNfe:_INFCTE:_RECEB:_IE:TEXT)
			lRecPJ	:= .T.
		EndIf		
	EndIf

	//-- Produto Predominante
	If (XmlChildEx(oNFE:_INFCTE,'_INFCTENORM')) <> Nil .And. (XmlChildEx(oNFE:_INFCTE:_INFCTENORM,'_INFCARGA')) <> Nil
		If XmlChildEx(oNFE:_INFCTE:_INFCTENORM:_INFCARGA,'_PROPRED') <> Nil
			cPPDesc		:= oNFE:_INFCTE:_INFCTENORM:_INFCARGA:_PROPRED:TEXT
		EndIf
		If XmlChildEx(oNFE:_INFCTE:_INFCTENORM:_INFCARGA,'_XOUTCAT') <> Nil
			cPPCarga	:= oNFE:_INFCTE:_INFCTENORM:_INFCARGA:_XOUTCAT:TEXT
		EndIf
		If XmlChildEx(oNFE:_INFCTE:_INFCTENORM:_INFCARGA,'_VMERC') <> Nil
			cPPVlTot	:= oNFE:_INFCTE:_INFCTENORM:_INFCARGA:_VMERC:TEXT
		Else
			cPPVlTot	:= oNFE:_INFCTE:_INFCTENORM:_INFCARGA:_VCARGA:TEXT
		EndIf
		If XmlChildEx( oNFE:_INFCTE:_INFCTENORM:_INFCARGA,'_INFQ' ) <> Nil
			aAux := If(ValType(oNFE:_InfCte:_InfCteNorm:_InfCarga:_InfQ) == "O",{oNFE:_InfCte:_InfCteNorm:_InfCarga:_InfQ},oNFE:_InfCte:_InfCteNorm:_InfCarga:_InfQ)
			For nCount := 1 To Len( aAux )
				Do Case
					Case aAux[ nCount ]:_TPMED:TEXT == "PESO DECLARADO"
						cPPPesoB := aAux[ nCount ]:_QCARGA:TEXT
					Case aAux[ nCount ]:_TPMED:TEXT == "PESO BASE DE CALCULO"
						cPesoBC := aAux[ nCount ]:_QCARGA:TEXT	
					Case aAux[ nCount ]:_TPMED:TEXT == "PESO CUBADO"
						cPPPeso3 := aAux[ nCount ]:_QCARGA:TEXT
					Case aAux[ nCount ]:_TPMED:TEXT == "LITRAGEM"
						cPPQtdVol := aAux[ nCount ]:_QCARGA:TEXT
					Case aAux[ nCount ]:_TPMED:TEXT == "VOLUME"
						cPPQtdVol := aAux[ nCount ]:_QCARGA:TEXT
					Case aAux[ nCount ]:_TPMED:TEXT == "METROS CUBICOS"
						cPPMetro3 := aAux[ nCount ]:_QCARGA:TEXT
				EndCase
			Next nCount
		EndIf
	EndIf

	// Tomador
	//
	// Tomador do Servico
	// 0 - Remetente;
	// 1 - Expedidor;
	// 2 - Recebedor;
	// 3 - Destinatario. 
		//| Remetente é o tomador do frete
	If XmlChildEx(oNfe:_INFCTE:_IDE, '_TOMA3') <> Nil .And. (oNfe:_INFCTE:_IDE:_TOMA3,'_TOMA') <> Nil
		If oNfe:_INFCTE:_IDE:_TOMA3:_TOMA:TEXT == "0"
			cDevMun   := cRemMun
			cDevUF    := cRemUF
			cDevNome  := cRemNome
			cDevEnd   := cRemEnd
			cDevNro   := cRemNro
			cDevCompl := cRemCompl
			cDevBair  := cRemBair
			cDevCEP   := cRemCEP
			cDevCNPJ  := cRemCNPJ
			cDevIE    := cRemIE
			cDevPais  := cRemPais
			cDevFone  := cRemFone
		//| Expedidor é o Tomador do Frete
		ElseIf oNfe:_INFCTE:_IDE:_TOMA3:_TOMA:TEXT == "1"
			cDevMun   := cExpMun
			cDevUF    := cExpUF
			cDevNome  := cExpNome
			cDevEnd   := cExpEnd
			cDevNro   := cExpNro
			cDevCompl := cExpCompl
			cDevBair  := cExpBai
			cDevCEP   := cExpCEP
			cDevCNPJ  := cExpCNPJ
			cDevIE    := cExpIE
			cDevPais  := cExpPais
			cDevFone  := cExpFone
		//| Recebedor é o tomador do frete
		ElseIf oNfe:_INFCTE:_IDE:_TOMA3:_TOMA:TEXT == "2"
			cDevMun   := cRecMun
			cDevUF    := cRecUF
			cDevNome  := cRecNome
			cDevEnd   := cRecEnd
			cDevNro   := cRecNro
			cDevCompl := cRecCompl
			cDevBair  := cRecBai
			cDevCEP   := cRecCEP
			cDevCNPJ  := cRecCGC
			cDevIE    := cRecINSCR
			cDevPais  := cRecPais
			cDevFone  := cRecFone
		//| Destinatário  é o Tomador do Frete
		ElseIf oNfe:_INFCTE:_IDE:_TOMA3:_TOMA:TEXT == "3"
			cDevMun   := cDesMun
			cDevUF    := cDesUF
			cDevNome  := cDesNome
			cDevEnd   := cDesEnd
			cDevNro   := cDesNro
			cDevCompl := cDesCompl
			cDevBair  := cDesBair
			cDevCEP   := cDesCEP
			cDevCNPJ  := cDesCNPJ
			cDevIE    := cDesIE
			cDevPais  := cDesPais
			cDevFone  := cDesFone
		EndIf
	ElseIf XmlChildEx(oNfe:_INFCTE:_IDE, '_TOMA4') <> Nil .And. (oNfe:_INFCTE:_IDE:_TOMA4,'_TOMA') <> Nil
		If oNfe:_INFCTE:_IDE:_TOMA4:_TOMA:TEXT == "4"
			// Subcontratacao DT6_DEVFRE == "4" - Despachante		
			cDevMun   := oNfe:_INFCTE:_IDE:_TOMA4:_ENDERTOMA:_XMUN:TEXT
			cDevUF    := oNfe:_INFCTE:_IDE:_TOMA4:_ENDERTOMA:_UF:TEXT
			cDevNome  := oNfe:_INFCTE:_IDE:_TOMA4:_XNOME:TEXT
			cDevEnd   := oNfe:_INFCTE:_IDE:_TOMA4:_ENDERTOMA:_XLGR:TEXT
			cDevNro   := oNfe:_INFCTE:_IDE:_TOMA4:_ENDERTOMA:_NRO:TEXT
			cDevCompl := ""
			cDevBair  := IIf(XmlChildEx(oNfe:_INFCTE:_IDE:_TOMA4:_ENDERTOMA,'_XBAIRRO')==Nil," ",oNfe:_INFCTE:_IDE:_TOMA4:_ENDERTOMA:_XBAIRRO:TEXT)
			cDevCEP   := IIf(XmlChildEx(oNfe:_INFCTE:_IDE:_TOMA4:_ENDERTOMA,'_CEP')==Nil," ",oNfe:_INFCTE:_IDE:_TOMA4:_ENDERTOMA:_CEP:TEXT)
			cDevCNPJ  := IIf(XmlChildEx(oNfe:_INFCTE:_IDE:_TOMA4,'_CNPJ')==Nil,oNfe:_INFCTE:_IDE:_TOMA4:_CPF:TEXT,oNfe:_INFCTE:_IDE:_TOMA4:_CNPJ:TEXT)
			cDevIE    := IIf(XmlChildEx(oNfe:_INFCTE:_IDE:_TOMA4,'_IE' )==Nil," ",oNfe:_INFCTE:_IDE:_TOMA4:_IE:TEXT)
			cDevPais  := ""
			cDevFone  := IIf(XmlChildEx(oNfe:_INFCTE:_IDE:_TOMA4,'_FONE')==Nil," ",oNfe:_INFCTE:_IDE:_TOMA4:_FONE:TEXT)
		EndIf
	ElseIf XmlChildEx(oNfe:_INFCTE, '_TOMA') <> Nil
		cDevMun   := oNfe:_INFCTE:_TOMA:_ENDERTOMA:_XMUN:TEXT
		cDevUF    := oNfe:_INFCTE:_TOMA:_ENDERTOMA:_UF:TEXT
		cDevNome  := oNfe:_INFCTE:_TOMA:_XNOME:TEXT
		cDevEnd   := oNfe:_INFCTE:_TOMA:_ENDERTOMA:_XLGR:TEXT
		cDevNro   := oNfe:_INFCTE:_TOMA:_ENDERTOMA:_NRO:TEXT
		cDevCompl := ""
		cDevBair  := IIf(XmlChildEx(oNfe:_INFCTE:_TOMA:_ENDERTOMA,'_XBAIRRO')==Nil," ",oNfe:_INFCTE:_TOMA:_ENDERTOMA:_XBAIRRO:TEXT)
		cDevCEP   := IIf(XmlChildEx(oNfe:_INFCTE:_TOMA:_ENDERTOMA,'_CEP')==Nil," ",oNfe:_INFCTE:_TOMA:_ENDERTOMA:_CEP:TEXT)
		cDevCNPJ  := IIf(XmlChildEx(oNfe:_INFCTE:_TOMA,'_CNPJ')==Nil,oNfe:_INFCTE:_TOMA:_CPF:TEXT,oNfe:_INFCTE:_TOMA:_CNPJ:TEXT)
		cDevIE    := IIf(XmlChildEx(oNfe:_INFCTE:_TOMA,'_IE' )==Nil," ",oNfe:_INFCTE:_TOMA:_IE:TEXT)
		cDevPais  := ""
		cDevFone  := IIf(XmlChildEx(oNfe:_INFCTE:_TOMA,'_FONE')==Nil," ",oNfe:_INFCTE:_TOMA:_FONE:TEXT)
	EndIf
	//-- Documentos Originarios
	aDocOri := {}
	If (XmlChildEx(oNFE:_INFCTE,'_REM') <> Nil) .And. ( XmlChildEx( oNFE:_INFCTE:_REM,'_INFNFE' ) <> Nil )
		If ValType( oNFE:_INFCTE:_REM:_INFNFE ) == 'A'
			For nCount := 1 To Len( oNFE:_INFCTE:_REM:_INFNFE )
				If aScan(aDocOri,{|x|x[8]==oNFE:_INFCTE:_REM:_INFNFE[ nCount ]:_CHAVE:TEXT})==0
					aAdd(aDocOri, {;
					'',;
					'',;
					'',;
					'',;
					'',;
					'',;
					'',;
					oNFE:_INFCTE:_REM:_INFNFE[ nCount ]:_CHAVE:TEXT })
				EndIf
			Next nCount
		ElseIf ValType( oNFE:_INFCTE:_REM:_INFNFE ) == 'O'
			If aScan(aDocOri,{|x|x[8]==oNFE:_INFCTE:_REM:_INFNFE:_CHAVE:TEXT})==0
				aAdd(aDocOri, {;
				'',;
				'',;
				'',;
				'',;
				'',;
				'',;
				'',;
				oNFE:_INFCTE:_REM:_INFNFE:_CHAVE:TEXT }) 
			EndIf
		EndIf
	ElseIf	(XmlChildEx(oNFE:_INFCTE,'_REM') <> Nil) .And. ( XmlChildEx( oNFE:_INFCTE:_REM,'_INFNF' ) <> Nil ) 
		If ValType( oNFE:_INFCTE:_REM:_INFNF ) == 'A'
			For nCount := 1 To Len( oNFE:_INFCTE:_REM:_INFNF )
				If aScan(aDocOri,{|x|x[1]+x[2]==oNFE:_INFCTE:_REM:_INFNF[ nCount ]:_SERIE:TEXT+oNFE:_INFCTE:_REM:_INFNF[ nCount ]:_NDOC:TEXT})==0
					aAdd(aDocOri, {;
					oNFE:_INFCTE:_REM:_INFNF[ nCount ]:_SERIE:TEXT,;
					oNFE:_INFCTE:_REM:_INFNF[ nCount ]:_NDOC:TEXT,;
					If (XmlChildEx(oNFE:_INFCTE:_REM:_INFNF[ nCount ],'_DEMI') <> Nil, StrTran(oNFE:_INFCTE:_REM:_INFNF[ nCount ]:_DEMI:TEXT,'-'),''),;
					oNFE:_INFCTE:_REM:_INFNF[ nCount ]:_VPROD:TEXT,;
					'',;
					'',;
					'',;
					'' })
				EndIf
			Next nCount
			//-- Local de Retirada
			If (XmlChildEx(oNfe:_INFCTE:_REM:_INFNF[1],'_LOCRET')) <> Nil
				cExpMun	:= oNfe:_INFCTE:_REM:_INFNF[1]:_LOCRET:_XMUN:TEXT
				cExpUF		:= oNfe:_INFCTE:_REM:_INFNF[1]:_LOCRET:_UF:TEXT
				cExpNome	:= oNfe:_INFCTE:_REM:_INFNF[1]:_LOCRET:_XNOME:TEXT
				cExpEnd	:= oNfe:_INFCTE:_REM:_INFNF[1]:_LOCRET:_XLGR:TEXT
				cExpNro	:= oNfe:_INFCTE:_REM:_INFNF[1]:_LOCRET:_NRO:TEXT
				cExpCompl 	:= ""
				cExpBai	:= oNfe:_INFCTE:_REM:_INFNF[1]:_LOCRET:_XBAIRRO:TEXT
				cExpCEP   	:= ""
				cExpCNPJ  	:= IIf(XmlChildEx(oNfe:_INFCTE:_REM:_INFNF[1]:_LOCRET,'_CNPJ')==Nil, oNfe:_INFCTE:_REM:_INFNF[1]:_LOCRET:_CPF:TEXT , oNfe:_INFCTE:_REM:_INFNF[1]:_LOCRET:_CNPJ:TEXT)
				cExpIE    	:= ""
				cExpPais  	:= cRemPais
				cExpFone  	:= ""
			EndIf
		Else
			If aScan(aDocOri,{|x|x[1]+x[2]==oNFE:_INFCTE:_REM:_INFNF:_SERIE:TEXT+oNFE:_INFCTE:_REM:_INFNF:_NDOC:TEXT})==0
				aAdd(aDocOri, {;
				oNFE:_INFCTE:_REM:_INFNF:_SERIE:TEXT,;
				oNFE:_INFCTE:_REM:_INFNF:_NDOC:TEXT,;
				If(XmlChildEx(oNFE:_INFCTE:_REM:_INFNF,'_DEMI') <> Nil, StrTran(oNFE:_INFCTE:_REM:_INFNF:_DEMI:TEXT,'-'),''),;
				oNFE:_INFCTE:_REM:_INFNF:_VPROD:TEXT,;
				'',;
				'',;
				'',;
				'' })
			EndIf
			If (XmlChildEx(oNfe:_INFCTE:_REM:_INFNF,'_LOCRET')) <> Nil
				cExpMun	:= oNfe:_INFCTE:_REM:_INFNF:_LOCRET:_XMUN:TEXT
				cExpUF		:= oNfe:_INFCTE:_REM:_INFNF:_LOCRET:_UF:TEXT
				cExpNome	:= oNfe:_INFCTE:_REM:_INFNF:_LOCRET:_XNOME:TEXT
				cExpEnd	:= oNfe:_INFCTE:_REM:_INFNF:_LOCRET:_XLGR:TEXT
				cExpNro	:= oNfe:_INFCTE:_REM:_INFNF:_LOCRET:_NRO:TEXT
				cExpCompl 	:= ""
				cExpBai	:= oNfe:_INFCTE:_REM:_INFNF:_LOCRET:_XBAIRRO:TEXT
				cExpCEP   	:= ""
				cExpCNPJ  	:= IIf(XmlChildEx(oNfe:_INFCTE:_REM:_INFNF:_LOCRET,'_CNPJ')==Nil, oNfe:_INFCTE:_REM:_INFNF:_LOCRET:_CPF:TEXT , oNfe:_INFCTE:_REM:_INFNF:_LOCRET:_CNPJ:TEXT)
				cExpIE    	:= ""
				cExpPais  	:= cRemPais
				cExpFone  	:= ""
			EndIf
		EndIf
	//Aqui Inicio
	ElseIf XmlChildEx(oNFE:_INFCTE,'_INFCTENORM') <> Nil .And. XmlChildEx(oNFE:_INFCTE:_INFCTENORM,'_INFDOC') <> Nil .And. XmlChildEx( oNFE:_INFCTE:_INFCTENORM:_INFDOC,'_INFNF') <> Nil
		aAux := If(ValType(oNFE:_InfCte:_InfCTeNorm:_InfDoc:_INFNF) == "O",{oNFE:_InfCte:_InfCTeNorm:_InfDoc:_INFNF},oNFE:_InfCte:_InfCTeNorm:_InfDoc:_INFNF)
		For nCount := 1 To Len(aAux)
			If aScan(aDocOri,{|x|x[1]+x[2]==aAux[ nCount ]:_SERIE:TEXT+aAux[ nCount ]:_NDOC:TEXT})==0
					aAdd(aDocOri, {;
					aAux[ nCount ]:_SERIE:TEXT,;
					aAux[ nCount ]:_NDOC:TEXT,;
					If(XmlChildEx(aAux[ nCount ],'_DEMI') <> Nil, StrTran(aAux[ nCount ]:_DEMI:TEXT,'-'),''),;
					aAux[ nCount ]:_VPROD:TEXT,;
					'',;
					'',;
					'',;
					'' })
			EndIf
		Next nCount
		
    //CTE MULTIMODAL
	ElseIf XmlChildEx(oNFE:_INFCTE,'_INFCTENORM') <> Nil .And. XmlChildEx(oNFE:_INFCTE:_INFCTENORM,'_INFSERVVINC') <> Nil .And. XmlChildEx( oNFE:_INFCTE:_INFCTENORM:_INFSERVVINC,'_INFCTEMULTIMODAL' ) <> Nil 
		aAux := If(ValType(oNFE:_InfCte:_InfCTeNorm:_INFSERVVINC:_INFCTEMULTIMODAL) == "O",{oNFE:_InfCte:_InfCTeNorm:_INFSERVVINC:_INFCTEMULTIMODAL},oNFE:_InfCte:_InfCTeNorm:_INFSERVVINC:_INFCTEMULTIMODAL)
		For nCount := 1 To Len(aAux)
			If aScan(aDocOri,{|x|x[8]==aAux[ nCount ]:_CHCTEMULTIMODAL:TEXT})==0
					aAdd(aDocOri, {;
					'',;
					'',;
					'',;
					'',;
					'',;
					'',;
					'',;
					aAux[ nCount ]:_CHCTEMULTIMODAL:TEXT })
			EndIf
		Next nCount

	ElseIf XmlChildEx(oNFE:_INFCTE,'_INFCTENORM') <> Nil .And. XmlChildEx(oNFE:_INFCTE:_INFCTENORM,'_INFDOC') <> Nil .And. XmlChildEx( oNFE:_INFCTE:_INFCTENORM:_INFDOC,'_INFNFE' ) <> Nil 
		aAux := If(ValType(oNFE:_InfCte:_InfCTeNorm:_INFDOC:_INFNFE) == "O",{oNFE:_InfCte:_InfCTeNorm:_INFDOC:_INFNFE},oNFE:_InfCte:_InfCTeNorm:_INFDOC:_INFNFE)
		For nCount := 1 To Len(aAux)
			If aScan(aDocOri,{|x|x[8]==aAux[ nCount ]:_CHAVE:TEXT})==0
					aAdd(aDocOri, {;
					'',;
					'',;
					'',;
					'',;
					'',;
					'',;
					'',;
					aAux[ nCount ]:_CHAVE:TEXT })
			EndIf
		Next nCount
		
	ElseIf	(XmlChildEx(oNFE:_INFCTE,'_REM') <> Nil) .And. ( XmlChildEx( oNFE:_INFCTE:_REM,'_INFOUTROS' ) <> Nil )
		aAux := If(ValType(oNFE:_InfCte:_REM:_INFOUTROS) == "O",{oNFE:_InfCte:_REM:_INFOUTROS},oNFE:_InfCte:_REM:_INFOUTROS)
		For nCount := 1 To Len(aAux)
			If aScan(aDocOri,{|x|x[1]+x[2]==aAux[ nCount ]:_NDOC:TEXT})==0
						aAdd(aDocOri, {;
						'',;//SERIE DO DOCUMENTO NAO INFORMADA NO XML QUANDO O DOCUMENTO NAO EH FISCAL
						aAux[ nCount ]:_NDOC:TEXT,;
						If(XmlChildEx(aAux[ nCount ],'_DEMI') <> Nil, StrTran(aAux[ nCount ]:_DEMI:TEXT,'-'),''),;
						'',;//--VALOR DO PRODUTO NAO INFORMADO NO XML QUANDO O DOCUMENTO NAO EH FISCAL
						'',;
						'',;
						'',;
						'' })
			EndIf
		Next nCount

	ElseIf XmlChildEx(oNFE:_INFCTE,'_INFCTENORM') <> Nil .And. XmlChildEx(oNFE:_INFCTE:_INFCTENORM,'_INFDOC') <> Nil .And. ( XmlChildEx( oNFE:_INFCTE:_INFCTENORM:_INFDOC,'_INFOUTROS' ) <> Nil ) 
		aAux := If(ValType(oNFE:_InfCte:_InfCTeNorm:_INFDOC:_INFOUTROS) == "O",{oNFE:_InfCte:_InfCTeNorm:_INFDOC:_INFOUTROS},oNFE:_InfCte:_InfCTeNorm:_INFDOC:_INFOUTROS)
		For nCount := 1 To Len(aAux)
			If ValType(XmlChildEx(aAux[ nCount ],"_NDOC")) == "O" .And. aScan(aDocOri,{|x|x[1]+x[2]==aAux[ nCount ]:_NDOC:TEXT})==0
						aAdd(aDocOri, {;
						'',;//SERIE DO DOCUMENTO NAO INFORMADA NO XML QUANDO O DOCUMENTO NAO EH FISCAL
						aAux[ nCount ]:_NDOC:TEXT,;
						If(XmlChildEx(aAux[ nCount ],"_DEMI") <> Nil, StrTran(aAux[ nCount ]:_DEMI:TEXT,'-'),''),;
						'',;//--VALOR DO PRODUTO NAO INFORMADO NO XML QUANDO O DOCUMENTO NAO EH FISCAL
						'',;
						'',;
						'',;
						'' })
			EndIf
		Next nCount

	//CT-e Simplificado
	ElseIf (XmlChildEx(oNFE:_INFCTE,'_DET') <> Nil) .And. ( XmlChildEx(oNFE:_INFCTE:_DET,'_INFNFE') <> Nil ) 
		If ValType( oNFE:_INFCTE:_DET:_INFNFE ) == 'A'
			For nCount := 1 To Len( oNFE:_INFCTE:_DET:_INFNFE )
				If aScan(aDocOri,{|x|x[8]==oNFE:_INFCTE:_DET:_INFNFE[ nCount ]:_CHNFE:TEXT})==0
					aAdd(aDocOri, {;
					'',;
					'',;
					'',;
					'',;
					'',;
					'',;
					'',;
					oNFE:_INFCTE:_DET:_INFNFE[ nCount ]:_CHNFE:TEXT })
				EndIf
			Next nCount
		ElseIf ValType( oNFE:_INFCTE:_DET:_INFNFE ) == 'O'
			If aScan(aDocOri,{|x|x[8]==oNFE:_INFCTE:_DET:_INFNFE:_CHNFE:TEXT})==0
				aAdd(aDocOri, {;
				'',;
				'',;
				'',;
				'',;
				'',;
				'',;
				'',;
				oNFE:_INFCTE:_DET:_INFNFE:_CHNFE:TEXT }) 
			EndIf
		EndIf
	EndIf

	//Tratamento para a tag docAnt
	If (XmlChildEx(oNFE:_INFCTE,'_INFCTENORM')) <> Nil .And. XmlChildEx( oNFE:_INFCTE:_INFCTENORM,'_DOCANT' ) <> Nil .And. ;
		XmlChildEx( oNFE:_INFCTE:_INFCTENORM:_DOCANT,'_EMIDOCANT' ) <> NIL .AND.;
		XmlChildEx( oNFE:_INFCTE:_INFCTENORM:_DOCANT:_EMIDOCANT:_IDDOCANT,'_IDDOCANTELE' ) <> Nil
		aDocOri := {}
		aAux := If(ValType(oNFE:_InfCte:_InfCTeNorm:_DOCANT:_EMIDOCANT:_IDDOCANT:_IDDOCANTELE) == "O",{oNFE:_InfCte:_InfCTeNorm:_DOCANT:_EMIDOCANT:_IDDOCANT:_IDDOCANTELE},oNFE:_InfCte:_InfCTeNorm:_DOCANT:_EMIDOCANT:_IDDOCANT:_IDDOCANTELE)
		For nCount := 1 To Len(aAux)
			If aScan(aDocOri,{|x|x[9]==aAux[ nCount ]:_CHCTE:TEXT})==0
						aAdd(aDocOri, {;
						'',;
						'',;
						'',;
						'',;
						'',;
						'',;
						'',;
						'',;
						aAux[ nCount ]:_CHCTE:TEXT })
			EndIf
		Next nCount
	EndIf

	// BOX: CFOP - Natureza da Prestacao
	oDacte:Box(0195, 0000, 0215, 0280)
	oDacte:Say(0202, 0003, "Código Fiscal de Operações - Natureza da Operação",	oFont08N)
	oDacte:Say(0211, 0003, cCFOP + " - " + cDescCfop,		oFont08)

	// BOX: ORIGEM DA PRESTACAO
	oDacte:Box(0215, 0000, 0229, 0280)
	oDacte:Say(0221, 0003, "Início da Prestação" , oFont08N)
	oDacte:Say(0228, 0003, AllTrim(cOriMunPre) + ' - ' + AllTrim(cOriUFPre), oFont08)	

	// BOX: DESTINO DA PRESTACAO
	oDacte:Box(0215, 0280, 0229, 0559)
	oDacte:Say(0221, 0288, "Término da Prestação", oFont08N)
	oDacte:Say(0228, 0288, AllTrim(cDesMunPre) + ' - ' + AllTrim(cDesUFPre), oFont08)

	// BOX: Remetente
	// BOX: Destinatario
	oDacte:Box(0231, 0000, 0282, 0279)	//Remetente
	oDacte:Box(0231, 0281, 0282, 0559)	//Destinatario

	oDacte:Say(0237, 0003, "Remetente:", oFont08)
	oDacte:Say(0237, 0043, NoAcentoCte(SubStr(cRemNome,1,45)), oFont08N)
	oDacte:Say(0237, 0286, "Destinatário:", oFont08)
	oDacte:Say(0237, 0328, NoAcentoCte(SubStr(cDesNome,1,45)), oFont08N)

	cInsRemOpc := AllTrim(cRemIE)
	For nCount := 1 To 5
		Do Case
			Case ( nCount == 1 )
				oDacte:Say(0246, 0003, "Endereço:", oFont08)
				If Len(AllTrim(cRemEnd)) > 40
					oDacte:Say(0246, 0039, SubStr( AllTrim(cRemEnd), 1, 40 ) , oFont08)
					oDacte:Say(0253, 0039, SubStr( AllTrim(cRemEnd), 40,Len(AllTrim(cRemEnd) ) ) + ", " + cRemNro, oFont08)
				Else
					oDacte:Say(0246, 0039, AllTrim(cRemEnd) + ", " + cRemNro, oFont08)
				EndIf
				
				oDacte:Say(0246, 0286, "Endereço:", oFont08)
				If Len(AllTrim(cDesEnd)) > 40
					oDacte:Say(0246, 0324, SubStr( AllTrim(cDesEnd), 1, 40) , oFont08)
					oDacte:Say(0253, 0324, SubStr( AllTrim(cDesEnd), 40, 35 ) + ", " + cDesNro, oFont08)
				Else
					oDacte:Say(0246, 0324, AllTrim(cDesEnd) + ", " + cDesNro, oFont08)
				EndIf
			Case ( nCount == 2 )
				oDacte:Say(0260, 0039, SubStr( AllTrim(cRemCompl), 1, 20 ) + " - " + SubStr( AllTrim(cRemBair), 1, 20 ), oFont08)
				oDacte:Say(0260, 0324, SubStr( AllTrim(cDesCompl), 1, 20 ) + " - " + SubStr( AllTrim(cDesBair), 1, 20 ), oFont08)
			Case ( nCount == 3 )
				oDacte:Say(0267, 0003, "Município:", oFont08)
				oDacte:Say(0267, 0043, AllTrim(cRemMun) + ' - ' + AllTrim(cRemUF)  + ' CEP.: ' + Transform(AllTrim(cRemCEP), "@r 99999-999"), oFont08)
				oDacte:Say(0267, 0286, "Município:", oFont08)
				oDacte:Say(0267, 0328, AllTrim(cDesMun) + ' - ' + AllTrim(cDesUF) + ' CEP.: ' + Transform(AllTrim(cDesCEP), "@r 99999-999"), oFont08)
			Case ( nCount == 4 )
				oDacte:Say(0274, 0003, "CNPJ/CPF:", oFont08)
				oDacte:Say(0274, 0043, Transform(AllTrim(cRemCNPJ), "@R! NN.NNN.NNN/NNNN-99") + "   Inscrição Estadual: " +  AllTrim(cInsRemOpc), oFont08)
				oDacte:Say(0274, 0286, "CNPJ/CPF:", oFont08)
				oDacte:Say(0274, 0328, Transform(AllTrim(cDesCNPJ), "@R! NN.NNN.NNN/NNNN-99") + "   Inscrição Estadual: " +  AllTrim(cDesIE),    oFont08)
			Case ( nCount == 5 )
				oDacte:Say(0281, 0003, "País:", oFont08)
				oDacte:Say(0281, 0043, AllTrim(cRemPais) + ' - Telefone: ' + Transform(AllTrim(cRemFone),"@r (999) 999999999"),  oFont08)
				oDacte:Say(0281, 0286, "País:", oFont08)
				oDacte:Say(0281, 0328, AllTrim(cDesPais) + '  - Telefone: ' + Transform(AllTrim(cDesFone),"@r (999) 999999999"), oFont08)
		EndCase
	Next nCount

	// BOX: Expedidor / BOX: Recebedor
	oDacte:Box(0284, 0000, 0335, 0279)	//Expedidor
	oDacte:Box(0284, 0281, 0335, 0559)	//Recebedor

	If lExped .Or. Empty(cExpNome) 		
		oDacte:Say(0291, 0003, "Expedidor:", oFont08) 
	Else
		oDacte:Say(0291, 0003, "Local de Coleta:", oFont08)
	EndIf
	oDacte:Say(0291, 0043, NoAcentoCte(SubStr(cExpNome,1,45))    , oFont08N)

	//-- Sequencia de endereco preenchida, fica como Local de entrega.
	If lSeqDes
		oDacte:Say(0291, 0286, "Local de Entrega:", oFont08)
		oDacte:Say(0291, 0342,  NoAcentoCte(SubStr(cRecNome,1,45)), oFont08N)
	EndIf
	
	If lSeqRec
		oDacte:Say(0291, 0286, "Recebedor:", oFont08)
		oDacte:Say(0291, 0328,  NoAcentoCte(SubStr(cRecNome,1,45)), oFont08N)
	EndIf

	If !lSeqDes .And. !lSeqRec
		oDacte:Say(0291, 0286, "Recebedor:", oFont08)
	EndIf

	For nCount := 1 To 5
		Do Case
			Case ( nCount == 1 )
				oDacte:Say(0300, 0003, "Endereço:", oFont08)
				If Len(AllTrim(cDesEnd)) > 40
					oDacte:Say(0300, 0039, If( !Empty(cExpEnd), SubStr(AllTrim(cExpEnd), 1, 40 ), " "), oFont08)
					oDacte:Say(0307, 0039, If( !Empty(cExpEnd), SubStr(AllTrim(cExpEnd), 40, Len(AllTrim(cExpEnd) ) ) + ", " + cExpNro, " "), oFont08)
				Else
					oDacte:Say(0300, 0039, IIf(!Empty(cExpEnd), AllTrim(cExpEnd) + ", " + cExpNro, " "), oFont08)
				EndIf
				oDacte:Say(0300, 0286, "Endereço:", oFont08)
				//-- Sequencia de endereco preenchida, fica como Local de entrega.
				If Len(AllTrim(cRecEnd)) > 40
					oDacte:Say(0300, 0324, If(lSeqDes .Or. lSeqRec, SubStr(AllTrim(cRecEnd), 1, 40 ), " "), oFont08)
					oDacte:Say(0307, 0324, If(lSeqDes .Or. lSeqRec, SubStr(AllTrim(cRecEnd), 40, Len(AllTrim(cRecEnd) ) ) + ", " + cRecNro, " "), oFont08)
				Else
					oDacte:Say(0300, 0324, If(lSeqDes .Or. lSeqRec, AllTrim(cRecEnd) + ", " + cRecNro, " "), oFont08)
				EndIf
			Case ( nCount == 2 )
				oDacte:Say(0314, 0039, If(!Empty(cExpCompl), If(!Empty(cExpCompl), SubStr(AllTrim(cExpCompl), 1, 20 ), "" ) + " - " + SubStr(AllTrim(cExpBai), 1, 20 ), cExpBai), oFont08)
				oDacte:Say(0314, 0324, If(lSeqDes .Or. lSeqRec, AllTrim(cValtoChar(FisGetEnd(cRecEnd)[4] ) ) + " - " + AllTrim(cRecBai),""), oFont08)
			Case ( nCount == 3 )
				oDacte:Say(0321, 0003, "Município:", oFont08)
				oDacte:Say(0321, 0043, IIf(!Empty(cExpMun),  AllTrim(cExpMun) + ' - ' + AllTrim(cExpUF), " ")  + ' CEP.: ' + IIf(!Empty(cExpCEP), Transform(AllTrim(cExpCEP), "@r 99999-999"), ""), oFont08)
				oDacte:Say(0321, 0286, "Município:", oFont08)
				oDacte:Say(0321, 0328, If(lSeqDes .Or. lSeqRec, AllTrim(cRecMun) + ' - ' + AllTrim(cRecUF),"") + ' CEP.: ' + IIf(!Empty(cRecCEP), Transform(AllTrim(cRecCEP), "@r 99999-999"), ""), oFont08)
			Case ( nCount == 4 )
				oDacte:Say(0328, 0003, "CNPJ/CPF:", oFont08)
				oDacte:Say(0328, 0043, IIf(!Empty(cExpCNPJ), Transform(AllTrim(cExpCNPJ), "@R! NN.NNN.NNN/NNNN-99"), " ") + "   Inscrição Estadual: " +  AllTrim(cExpIE), oFont08)
				oDacte:Say(0328, 0286, "CNPJ/CPF:", oFont08)
				If lSeqDes .Or. lSeqRec
					If lRecPJ
						oDacte:Say(0328, 0328, IIf(!Empty(cRecCGC), Transform(cRecCGC,"@R! NN.NNN.NNN/NNNN-99"), " ") + "   Inscrição Estadual: " +  cRecINSCR, oFont08)
					Else
						oDacte:Say(0328, 0328, Transform(cRecCPF,"@r 999.999.999-99"), oFont08)
					EndIf
				Else
					oDacte:Say(0328, 0328, "", oFont08)
				EndIf

			Case ( nCount == 5 )
				If lExped .Or. Empty(cExpNome)
					oDacte:Say(0335, 0003, "País:" , oFont08)
					oDacte:Say(0335, 0043, AllTrim(cExpPais) + ' Telefone: ' + IIf(!Empty(cExpFone), Transform(AllTrim(cExpFone),"@r (999) 999999999"), " "),  oFont08)
				EndIf
				If !lSeqDes
					oDacte:Say(0335, 0286, "País:" , oFont08)
					oDacte:Say(0335, 0328, AllTrim(cRecPais) + ' Telefone: ' + IIf(!Empty(cRecFone), Transform(AllTrim(cRecFone),"@r (999) 999999999"), " "),  oFont08)
				EndIf
		EndCase
	Next nCount

	// BOX: Tomador do Servico
	oDacte:Box(0337, 0000, 0364, 0559)
	oDacte:Say(0344, 0003, "Tomador do Serviço:", oFont08)
	oDacte:Say(0344, 0072, NoAcentoCte(SubStr(cDevNome,1,45)), oFont08)
	oDacte:Say(0344, 0328, "Município:", oFont08)
	oDacte:Say(0344, 0368, AllTrim(cDevMun) + ' - ' + AllTrim(cDevUF) + ' CEP.: ' + Transform(AllTrim(cDevCEP),"@r 99999-999"), oFont08)

	For nCount := 1 To 2
		Do Case
			Case ( nCount == 1 )
				cEndCom := SubStr(AllTrim(cDevEnd),1,40) + ", " + cDevNro + " - " + AllTrim(cDevCompl) + " - " + AllTrim(cDevBair)
				oDacte:Say(0352, 0003, "Endereço:", oFont08	)

				If Len(cEndCom) > 64 .And. !Empty(cDevCompl)
					cEndCom := SubStr(AllTrim(cDevEnd),1,40) + ", " + cDevNro + " - " + SubStr(AllTrim(cDevCompl), 1, 10 ) + " - " + SubStr(AllTrim(cDevBair), 1, 29 )
					oDacte:Say(0352, 0038, cEndCom, oFont08		)
					oDacte:Say(0352, 0485, "País: ", oFont08	)
					oDacte:Say(0352, 0505, AllTrim(cDevPais), oFont08	)
				ElseIf Len(cEndCom) > 64
					oDacte:Say(0352, 0038, cEndCom, oFont08		)
					oDacte:Say(0352, 0485, "País: ", oFont08	)
					oDacte:Say(0352, 0505, AllTrim(cDevPais), oFont08	)
				Else
					oDacte:Say(0352, 0038, cEndCom, oFont08		)
					oDacte:Say(0352, 0328, "País: ", oFont08	)
					oDacte:Say(0352, 0368, AllTrim(cDevPais), oFont08	)
				EndIf
				
			Case ( nCount == 2 )
				oDacte:Say(0360, 0003, "CNPJ/CPF:", oFont08)
				oDacte:Say(0360, 0043, Transform(AllTrim(cDevCNPJ),"@R! NN.NNN.NNN/NNNN-99") + "   Inscrição Estadual: " + AllTrim(cDevIE), oFont08)
				oDacte:Say(0360, 0328, "Telefone:", oFont08)
				oDacte:Say(0360, 0368, Transform(AllTrim(cDevFone),"@r (999) 999999999"), oFont08)
		EndCase
	Next nCount

	If	.T.
		// BOX: Prod Predom || Outras Caract || Valor Total da Mercadoria
		oDacte:Box(0366 , 0000, 0383, 0559)
		oDacte:Line(0366, 0189, 0383, 0189) // Linha: Prod.Predominante e Out.Caracteristicas
		oDacte:Line(0366, 0378, 0383, 0378) // Linha: Out.Caracteristicas e Vlr.Total
		oDacte:Say(0372, 0003, "Produto Predominante"           , oFont08N)
		oDacte:Say(0372, 0192, "Outras Características da Carga", oFont08N)
		oDacte:Say(0372, 0381, "Valor Total da Mercadoria"      , oFont08N)
		oDacte:Say(0380, 0003, SubStr(cPPDesc,1,40), oFont08)	//Produto Predominante
		oDacte:Say(0380, 0192, AllTrim(cPPCarga)	, oFont08)	//Outras Caracteristicas da Carga
		oDacte:Say(0380, 0381, PadL( Transform( Val(cPPVlTot), PesqPict("DT6","DT6_VALMER") ), 20 ), oFont08)	//Valor Total da Mercadoria

		// BOX: QNT. / UNIDADE MEDIDA /
		oDacte:Box(0385, 0000, 0443,  0559)	
		oDacte:Box(0385, 0000, 0443,  0040) // Box Qtd / Carga
		oDacte:Say(0392 , 0003, "Qtd."	, oFont08N)
		oDacte:Say(0402 , 0003, "Carga"	, oFont08N)	
		oDacte:Say(0392 , 0043, "Peso Bruto (KG)"			, oFont08N)
		oDacte:Say(0392 , 0143, "Peso Base de Cálculo (KG)"	, oFont08N)
		oDacte:Say(0392 , 0247, "Peso Aferido (KG)  "	, oFont08N)
		oDacte:Say(0392 , 0352, "Cubagem (M³)        "		, oFont08N)
		oDacte:Say(0392 , 0457, "Qtd. Volume (UN)"	, oFont08N)
		oDacte:Say(0392 , nCInic, "                ", oFont08N)
		oDacte:Line(0385, 0140, 0443, 0140) // Linha: Separador Peso Bruto (KG) / Peso Cubado		
		oDacte:Line(0385, 0245, 0443, 0245) // Linha: Separador Peso Cubado / M³				
		oDacte:Line(0385, 0350, 0443, 0350) // Linha: Separador M³ / Qtd. Volume (Un)			
		oDacte:Line(0385, 0455, 0443, 0455) // Linha: SeparadorQtd. Volume (Un) / 				

		oDacte:Say(0405, 0043, Transform(Val(cPPPesoB) ,	PesqPict("DT6","DT6_PESO")   ),	oFont08) 
		oDacte:Say(0405, 0143, Transform(Val(cPesoBC) ,  	PesqPict("DT6","DT6_PESO")   ),	oFont08) 						
		oDacte:Say(0405, 0247, Transform(Val(cPPPeso3) ,	PesqPict("DT6","DT6_PESOM3") ),	oFont08)  			
		oDacte:Say(0405, 0352, Transform(Val(cPPMetro3),	PesqPict("DT6","DT6_METRO3") ),	oFont08)   				
		oDacte:Say(0405, 0457, Transform(Val(cPPQtdVol),	PesqPict("DT6","DT6_QTDVOL") ),	oFont08)    
		
		//-- Zera as variaveis(Peso, Peso Cubado, Metro Cubico e Qtd Volume) depois de impresso no DACTE.
		cPPPesoB  := ""
		cPPPeso3  := ""
		cPPMetro3 := ""
		cPPQtdVol := ""
		cPesoBC	  := ""	

		// Conteudo do Box: Componentes do Valor da Prestacao de Servico
		// Conteudo do Box: Informacoes Relativas ao Imposto
		TMSR31Comp(oDacte, oNfe)

		lPerig := .F.

		// BOX: DOCUMENTOS ORIGINARIOS
		oDacte:Box(0502, 0000, 0559, 0559)
		If Empty(cCtrDpc)
			oDacte:Say(0508 , 0243, "Documentos Originários", oFont08N)
		Else
			oDacte:Say(0508 , 0143, "Documentos Originários",oFont08N)
			oDacte:Say(0508 , 0443, "Documentos Anteriores ",oFont08N)
		EndIf

		oDacte:Line(0510, 0000, 0510, 0559)	// Linha: Abaixo    DOCUMENTOS ORIGINARIOS
		oDacte:Line(0510, 0283, 0590, 0283)	// Linha: Separador DOCUMENTOS ORIGINARIOS
		
		oDacte:Say(0517 , 0003, "Tp. Doc."           , oFont08N)
		If !Empty(aDocOri) .And. Empty(AllTrim(aDocOri[1][doDTC_NFEID]))
			oDacte:Say(0517 , 0033, "CNPJ/CPF Emitente"  , oFont08N)
		EndIf
		oDacte:Say(0517 , 0163, "Série/Nr. Documento", oFont08N)
		oDacte:Say(0517 , 0286, "Tp. Doc."           , oFont08N)
		If !Empty(aDocOri) .And. Empty(AllTrim(aDocOri[1][doDTC_NFEID]))
			oDacte:Say(0517 , 0316, "CNPJ/CPF Emitente"  , oFont08N)
		EndIf
		oDacte:Say(0517 , 0448, "Série/Nr. Documento", oFont08N)
				
		// Documentos Originarios
		lControl := .F.
		nLInic   := 0525

		nCount := 0
		aDoc   := {}

		For nCount := 1 to Len( aDocOri )
			lControl := !lControl
			If nCount < 11
				If Empty(cCtrDpc)
					If lControl
						If Empty(AllTrim(aDocOri[nCount][doDTC_NFEID])) .And. !Empty(AllTrim(aDocOri[nCount][doDTC_SERNFC]))
							//-- Imprime a Chave da NF-e, lado esquerdo
							oDacte:Say(nLInic, 0003, "NF", oFont08)
							oDacte:Say(nLInic, 0033, Transform(AllTrim(cRemCNPJ),"@R! NN.NNN.NNN/NNNN-99"), oFont08)
							oDacte:Say(nLInic, 0163, AllTrim(aDocOri[nCount][doDTC_SERNFC] + " / " + AllTrim(aDocOri[nCount][doDTC_NUMNFC])), oFont08)
						ElseIf Len(aDocOri[nCount]) >= doDTC_CTEID .And. !Empty(AllTrim(aDocOri[nCount][doDTC_CTEID])) 
							//-- Imprime a Chave da CT-e docAnt, lado esquerdo
							cChaveA := (AllTrim(aDocOri[nCount][doDTC_CTEID]))
							oDacte:Say(nLInic, 0003, "CT-E CHAVE:", oFont08)
							oDacte:Say(nLInic, 0073, cChaveA, oFont08)
							cChaveA := ''
						ElseIf Empty(AllTrim(aDocOri[nCount][doDTC_NFEID]))
							//-- Imprime os dados do documento não fiscal do lado esquerdo.
							oDacte:Say(nLInic, 0003, "OUTROS", oFont08)
							oDacte:Say(nLInic, 0033, Transform(AllTrim(cRemCNPJ),"@R! NN.NNN.NNN/NNNN-99"), oFont08)
							oDacte:Say(nLInic, 0163, AllTrim(aDocOri[nCount][doDTC_NUMNFC]), oFont08)						
						Else
							//-- Imprime a Chave da NF-e, lado esquerdo
							cChaveA := AllTrim(aDocOri[nCount][doDTC_NFEID])
							oDacte:Say(nLInic, 0003, "NF-E CHAVE:", oFont08)
							oDacte:Say(nLInic, 0073, SubStr(cChaveA,1,22), oFont08)
							oDacte:Say(nLInic, 0168, SubStr(cChaveA,23,3) + " " + SubStr(cChaveA,26,9), oFont08N)
							oDacte:Say(nLInic, 0223, SubStr(cChaveA,35,10), oFont08)
							cChaveA := ''
						EndIf

					Else
						If Empty(AllTrim(aDocOri[nCount][doDTC_NFEID])) .And. !Empty(AllTrim(aDocOri[nCount][doDTC_SERNFC]))
							//-- Imprime a Chave da NF-e, lado direito
							oDacte:Say(nLInic, 0286, "NF", oFont08)
							oDacte:Say(nLInic, 0316, Transform(AllTrim(cRemCNPJ),"@R! NN.NNN.NNN/NNNN-99"), oFont08)
							oDacte:Say(nLInic, 0448, AllTrim(aDocOri[nCount][doDTC_SERNFC]) + " / " + AllTrim(aDocOri[nCount][doDTC_NUMNFC]), oFont08)
						ElseIf Len(aDocOri[nCount]) >= doDTC_CTEID .And. !Empty(AllTrim(aDocOri[nCount][doDTC_CTEID])) 
							//-- Imprime a Chave da CT-e docAnt, lado direito
							cChaveB := (AllTrim(aDocOri[nCount][doDTC_CTEID]))
							oDacte:Say(nLInic, 0286, "CT-E CHAVE:", oFont08)
							oDacte:Say(nLInic, 0356, cChaveB, oFont08)
							cChaveB := ''
						ElseIf Empty(AllTrim(aDocOri[nCount][doDTC_NFEID]))
							//-- Imprime os dados do documento não fiscal do lado direito.
							oDacte:Say(nLInic, 0286, "OUTROS", oFont08)
							oDacte:Say(nLInic, 0316, Transform(AllTrim(cRemCNPJ),"@R! NN.NNN.NNN/NNNN-99"), oFont08)
							oDacte:Say(nLInic, 0448, AllTrim(aDocOri[nCount][doDTC_NUMNFC]), oFont08)
						Else
							//-- Imprime a Chave da NF-e, lado direito
							cChaveB := AllTrim(aDocOri[nCount][doDTC_NFEID])
							oDacte:Say(nLInic, 0286, "NF-E CHAVE:", oFont08)
							oDacte:Say(nLInic, 0356, SubStr(cChaveB,1,22), oFont08)
							oDacte:Say(nLInic, 0451, SubStr(cChaveB,23,3) + " " + SubStr(cChaveB,26,9), oFont08N)
							oDacte:Say(nLInic, 0506, SubStr(cChaveB,35,10), oFont08)
							cChaveB := ''
						EndIf
					EndIf
				ElseIf lControl
					If Empty(AllTrim(aDocOri[nCount][doDTC_NFEID])) .And. !Empty(AllTrim(aDocOri[nCount][doDTC_SERNFC]))
						oDacte:Say(nLInic, 0003, "NF", oFont08)
						oDacte:Say(nLInic, 0033, Transform(AllTrim(cRemCNPJ),"@R! NN.NNN.NNN/NNNN-99"), oFont08)
						oDacte:Say(nLInic, 0163, AllTrim(aDocOri[nCount][doDTC_SERNFC]) + " / " + AllTrim(aDocOri[nCount][doDTC_NUMNFC]), oFont08)
					ElseIf Empty(AllTrim(aDocOri[nCount][doDTC_NFEID]))
						oDacte:Say(nLInic, 0003, "OUTROS", oFont08)
						oDacte:Say(nLInic, 0033, Transform(AllTrim(cRemCNPJ),"@R! NN.NNN.NNN/NNNN-99"), oFont08)
						oDacte:Say(nLInic, 0163, AllTrim(aDocOri[nCount][doDTC_NUMNFC]), oFont08)					
					Else
						//-- Imprime a Chave da NF-e, lado direito
						cChaveA := AllTrim(aDocOri[nCount][doDTC_NFEID])
						oDacte:Say(nLInic, 0003, "NF-E CHAVE:", oFont08)
						oDacte:Say(nLInic, 0073, cChaveA, oFont08)
						cChaveA := ''
					EndIf
					If !Empty(cCtrDpc)
						If Empty(cCTEDocAnt)
							oDacte:Say(nLInic, 0286, cDesDocAnt, oFont08)
							oDacte:Say(nLInic, 0316, Transform(AllTrim((cAliasCT)->DPC_CNPJ),"@R! NN.NNN.NNN/NNNN-99"), oFont08)
							oDacte:Say(nLInic, 0448, AllTrim(cSerDpc) + " / " + AllTrim(cCtrDpc), oFont08)
						Else
							//-- Imprime a Chave da NF-e, lado esquerdo
							cChaveB := AllTrim(cCTEDocAnt)
							oDacte:Say(nLInic, 0286, "NF-E CHAVE:", oFont08)
							oDacte:Say(nLInic, 0356, cChaveB, oFont08)
							cChaveB := ''
						EndIf
					EndIf
				EndIf
			Else
				cTipoDoc := IIf(Empty(AllTrim(aDocOri[nCount][doDTC_NFEID])) .And. Empty(AllTrim(aDocOri[nCount][doDTC_SERNFC])),'Outros',IIf(Empty(AllTrim(aDocOri[nCount][doDTC_NFEID])),'NF','NF-e'))
				If cTipoDoc == 'Outros' .And. !Empty(AllTrim(aDocOri[nCount][doDTC_CTEID]))
					cTipoDoc := 'CT-e'
					aAdd(aDoc,{ AllTrim(cRemCNPJ), AllTrim(aDocOri[nCount][doDTC_SERNFC]) + " / " + AllTrim(aDocOri[nCount][doDTC_NUMNFC]),	AllTrim(aDocOri[nCount][doDTC_CTEID]), cTipoDoc})					
				Else
					aAdd(aDoc,{ AllTrim(cRemCNPJ),;
						AllTrim(aDocOri[nCount][doDTC_SERNFC]) + " / " + AllTrim(aDocOri[nCount][doDTC_NUMNFC]),;
						AllTrim(aDocOri[nCount][doDTC_NFEID]),cTipoDoc})
				 		//--Acrescenta o Tipo do Documento no aDoc
				EndIf
			EndIf

			// FORCAR A "QUEBRA" DA LINHA
			If ( (mod(nCount,2)) == 0 )
				If nCount < 11
					If !Empty(cChaveA)
						nLInic += 0008
						oDacte:Say(nLInic, 0003, "NF-E CHAVE:", oFont08)
						oDacte:Say(nLInic, 0073, cChaveA, oFont08)
						cChaveA := ''
					
						If !Empty(cChaveB)
							oDacte:Say(nLInic, 0286, "NF-E CHAVE:", oFont08)
							oDacte:Say(nLInic, 0356, cChaveB, oFont08)
							cChaveB := ''
						EndIf
					EndIf
					
					nLInic += 0008
				EndIf
			EndIf
		Next nCount
		nLInic := 2050
	Else
		TMSR31Cmp(oDacte, oNfe)
		TMSR31Comp(oDacte, oNfe)
	EndIf
	
	// BOX: PREVISÃO DO FLUXO CARGA
	oDacte:Box(0561 , 0000, 0590, 0559)
	oDacte:Say(0568,  0245, "Previsão do Fluxo de Carga", oFont08N)
	oDacte:Line(0569, 0000, 0569, 0559)	// Linha: Abaixo    
	oDacte:Say(0575,  0003, "Sigla ou Código da Filial/Porto/Estação/Aeroporto de Origem", oFont07)
	oDacte:Say(0583,  0003, cOriUFPre, oFont07)
	oDacte:Say(0575,  0188, "Sigla ou Código da Filial/Porto/Estação/Aeroporto de Passagem", oFont07)
	oDacte:Say(0575,  0374, "Sigla ou Código da Filial/Porto/Estação/Aeroporto de Destino", oFont07)
	oDacte:Say(0583,  0374, cDesUFPre, oFont07)
	oDacte:Line(0569, 0186, 0590, 0186)	// Linha: Separadoras
	oDacte:Line(0569, 0372, 0590, 0372)	// Linha: Separadoras

	// BOX: OBSERVACOES GERAIS
	oDacte:Box(0592,  0000, 0683, 0559)	
	oDacte:Say(0598,  0258, "Observações Gerais", oFont08N)
	oDacte:Line(0600, 0000, 0600, 0559) // Linha: OBSERVACOES
    nCountObs := 9

	// BOX: OBSERVACOES
	DBSelectArea("DT6") //-- Nao retirar
	cDT6Obs := " "
	If XmlChildEx(oNfe:_INFCTE:_IMP,'_INFADFISCO') == Nil
		cDT6Obs := " "
	Else
		cDT6Obs := oNfe:_INFCTE:_IMP:_INFADFISCO:TEXT
	EndIf
	cObsProp := " "
	If (XmlChildEx(oNFE:_INFCTE,'_INFCTENORM')) <> Nil .And. ;
		XmlChildEx(oNfe:_INFCTE:_INFCTENORM:_INFMODAL,'_RODO') != Nil .And. ;
		XmlChildEx(oNfe:_INFCTE:_INFCTENORM:_INFMODAL:_RODO,'_VEIC') != Nil .And. ;
		XmlChildEx(oNfe:_INFCTE:_INFCTENORM:_INFMODAL:_RODO:_VEIC,'_PROP') != Nil .And. ;
		XmlChildEx(oNfe:_INFCTE:_INFCTENORM:_INFMODAL:_RODO:_VEIC:_PROP,'_XNOME') != Nil .And.;
		XmlChildEx(oNfe:_INFCTE:_INFCTENORM:_INFMODAL:_RODO:_VEIC,'_TPPROP') != Nil
		If oNfe:_INFCTE:_INFCTENORM:_INFMODAL:_RODO:_VEIC:_TPPROP:TEXT == 'T'
			cObsProp += " Proprietario : " + AllTrim(oNfe:_INFCTE:_INFCTENORM:_INFMODAL:_RODO:_VEIC:_PROP:_XNOME:TEXT)			
		EndIf
	EndIf
	cDTCObs := " "

	If XmlChildEx(oNfe:_INFCTE,'_COMPL') != Nil 
		If XmlChildEx(oNfe:_INFCTE:_COMPL,'_XOBS') != Nil
			cDTCObs += oNfe:_INFCTE:_COMPL:_XOBS:TEXT
		EndIf
		If XmlChildEx(oNfe:_INFCTE:_COMPL, '_OBSCONT') <> Nil
			If ValType(oNfe:_INFCTE:_COMPL:_OBSCONT) == "A"
				aObsCont := {}
				For nX := 1 to Len(oNfe:_INFCTE:_COMPL:_OBSCONT)
					aAdd(aObsCont, oNfe:_INFCTE:_COMPL:_OBSCONT[nX]:_XTEXTO:TEXT )
				Next nX
			ElseIf XmlChildEx(oNfe:_INFCTE:_COMPL:_OBSCONT,'_XTEXTO') == Nil
				aObsCont := {""}
			Else
				aObsCont := {oNfe:_INFCTE:_COMPL:_OBSCONT:_XTEXTO:TEXT}
			EndIf
		EndIf
	EndIf

	cDT6Obs3:= SubStr(cDT6Obs,281,140)
	cDT6Obs2:= SubStr(cDT6Obs,141,140)
	cDT6Obs := SubStr(cDT6Obs,  1,140)
	//-- Popula o vetor de observações
	cObsProp:= SubStr(cObsProp,  1,140)
	nObsStart := 1
	For nCountDTC := 1 To Len(aDTCObserv)		
		aDTCObserv[nCountDTC] := SubStr(cDTCObs ,  nObsStart,140)
		//--Atualiza Tags
		cTagObs += "OBSDTC"+AllTrim(Str(nCountDTC))+";"
		nCountObs -= 1
		nObsStart += 140
	Next nCountDTC
	
	// Tratamento para aproveitar todo o espaco do quadro observacao
	If !Empty(cDT6Obs)
	  nCountObs -= 1
	  cTagObs += 'OBSDT61;' 
	EndIf
	
	If !Empty(cDT6Obs2)
	  nCountObs -= 1
	  cTagObs += 'OBSDT62;' 
	EndIf

	If !Empty(cObsProp)
	  nCountObs -= 1
	  cTagObs  += 'OBSPRO1;' 
	EndIf
	
	// If (nCountObs > 0) .And. (!Empty(cDTCObs2))
	//   nCountObs -= 1
	//   cTagObs += 'OBSDTC2;' 
	// EndIf
	
	If (nCountObs > 0) .And. (!Empty(cDT6Obs3))
	  nCountObs -= 1
	  cTagObs += 'OBSDT63;' 
	EndIf

	nLinhaObs := 0608
	If AT('OBSGER1;',cTagObs) > 0
	  oDacte:Say (nLinhaObs, 0003, cObsStat, oFont10N)
	  nLinhaObs += 8  
	EndIf
	
	If AT('OBSDT61;',cTagObs) > 0
	  oDacte:Say (nLinhaObs, 0003, cDT6Obs, oFont07)
	  nLinhaObs += 8  
	EndIf
	
	If AT('OBSDT62;',cTagObs) > 0
	  oDacte:Say (nLinhaObs, 0003, cDT6Obs2, oFont07)
	  nLinhaObs += 8  
	EndIf
	
	If AT('OBSDT63;',cTagObs) > 0
	  oDacte:Say (nLinhaObs, 0003, cDT6Obs3, oFont07)
	  nLinhaObs += 8  
	EndIf
	
	//-- Realiza a impressão da observações gerais
	For nCountDTC := 1 To Len(aDTCObserv)
		If AT("OBSDTC" + AllTrim(Str(nCountDTC)) + ";",cTagObs) > 0
			oDacte:Say (nLinhaObs, 0003, aDTCObserv[nCountDTC], oFont07)
			nLinhaObs += 8
		EndIf
	Next nCountDTC
	
	If AT('OBSPRO1;',cTagObs) > 0
	  oDacte:Say (nLinhaObs, 0003, cObsProp, oFont07)
	  nLinhaObs += 8  
	End If		

	// BOX: INFORMACOES ESPECIFICAS DO MODAL
	nLinIEM := 40
	If  oNfe:_INFCTE:_IDE:_modal:TEXT == "06" // do tipo MultiModal 
		oDacte:Box(0688+nLinIEM, 0000, 0717+nLinIEM, 0559)
		oDacte:Say(0651+nLinIEM, 0210, "Informações Específicas do Transporte Multimodal de Cargas", oFont08N)
		oDacte:Line(0654+nLinIEM, 0000, 0654+nLinIEM, 0559)
		oDacte:Say(0664+nLinIEM, 0003, "COTM da Empresa: " + cTmsCOTM	, oFont08)

		If (XmlChildEx(oNFE:_INFCTE,'_INFCTENORM')) <> Nil .And. (XmlChildEx(oNFE:_INFCTE:_INFCTENORM:_INFMODAL,'_MULTIMODAL')) <> NIL //Existe Stru da MultiModal.
			cIndNegoci := oNFE:_INFCTE:_INFCTENORM:_INFMODAL:_MULTIMODAL:_indNegociavel:TEXT

			oDacte:Box(0658+nLinIEM, 0295, 0666+nLinIEM, 0285)
			oDacte:Say(0664+nLinIEM, 0300, "Negociável" , oFont08)	 
			
			oDacte:Box(0658+nLinIEM, 0350, 0666+nLinIEM, 0360)
			oDacte:Say(0664+nLinIEM, 0368, "Não Negociável" , oFont08)
			
			If (cIndNegoci == "1") 			
				oDacte:Say(0664+nLinIEM, 0287, "X" /* DTC_INDNEG */	, oFont08) 
			Else
				oDacte:Say(0664+nLinIEM, 0352, "X" /* DTC_INDNEG */	, oFont08)
			EndIf
		EndIf
	Else
		oDacte:Box(0645+nLinIEM, 0000, 0672+nLinIEM, 0559)
		oDacte:Say(0651+nLinIEM, 0210, "Informações do Modal Rodoviário", oFont08N)
		oDacte:Line(0654+nLinIEM, 0000, 0654+nLinIEM, 0559)
		oDacte:Say(0661+nLinIEM, 0003, "RNTRC da Empresa: " + cTmsAntt	, oFont08)
	EndIf

	// BOX: USO EXCLUSIVO DO EMISSOR + RESERVADO AO FISCO
	oDacte:Box(0674+nLinIEM , 0000, 0720+nLinIEM, 0559)  
	oDacte:Say(0681+nLinIEM , 0090, "USO EXCLUSIVO DO EMISSOR DO CT-E", oFont08N)
	nSoma := 0
	For nX := 1 to Len(aObsCont)
		If nX > 3
			Exit
		EndIf
		oDacte:Say(0690 + nSoma+nLinIEM, 0003, aObsCont[nX], oFont08)
		nSoma += 10
	Next
	oDacte:Say(0681+nLinIEM , 0420, "RESERVADO AO FISCO", oFont08N)
	oDacte:Line(0683+nLinIEM, 0000, 0683+nLinIEM, 0559)	//Linha Horizontal
	oDacte:Line(0674+nLinIEM, 0355, 0720+nLinIEM, 0355)	//Linha Vertical

	oDacte:EndPage()

	//-- aDoc > 0, existe mais de uma pagina com Doc a ser impressa.
	//-- lPerig .T. existem produtos perigosos a serem impressos.
	If Len(aDoc) > 0 .Or. lPerig
		//-- Caso de mais de uma pagina, chama a funcao para montar as paginas seguites.
		TMSR35Cont(oDacte, oNfe, aDoc, aCab[nCont] )
	EndIf

Return(.T.)

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Programa  |TMSR35Cont³ Autor ³Felipe Barbiere           ³ Data ³01/10/12  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ³±±
±±³Descri‡…o ³Caso de mais de uma pagina, chama a funcao para montar      ³±±
±±³          ³as paginas seguites.                                        ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   |                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³Nenhum                                                      ³±±
±±³          ³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³   DATA   ³ Programador   ³Manutencao efetuada                         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³          ³               ³                                            ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Static Function TMSR35Cont(oDacte, oNfe, aDoc, aCab, aPerigo, nCnt)
Local oFont08	:= TFont():New( "Times New Roman", 08, 08, , .F., , , , .T., .F. )
Local oFont08N	:= TFont():New( "Times New Roman", 08, 08, , .T., , , , .T., .F. )
Local lControl	:= .F.
Local nCount	:= 0
Local aDoc1		:= {}
Local cChaveA	:= ''
Local cChaveB	:= ''

Default nCnt	:= 1
Default aPerigo	:= {}
Default aDoc	:= {}
Default aCab	:= {}

oDacte:StartPage()
oDacte:SetPaperSize( Val( GetProfString( GetPrinterSession(), "PAPERSIZE", "1", .T. ) ) )

// Funcao responsavel pela montagem do cabecalho do DACTE
TMSR31Cab(oDacte, oNfe, aCab)

// BOX: DOCUMENTOS ORIGINARIOS
oDacte:Box(	0224, 0000, 0593, 0559)
oDacte:Say(	0230, 0210, "Documentos Originários",	oFont08N )
oDacte:Line(0232, 0000, 0232, 0559)							// Linha: DOCUMENTOS ORIGINARIOS
oDacte:Line(0232, 0280, 0593, 0280)							// Linha: Separador DOCUMENTOS ORIGINARIOS
oDacte:Say(	0238, 0003, "Tp.Doc",					oFont08N )

If Len(aDoc) > 0 .And. Empty(AllTrim(aDoc[1][3]))
	oDacte:Say( 0238, 0033, "CNPJ/CPF Emitente",	oFont08N )
EndIf

oDacte:Say(	0238, 0163, "Série/Nr.Documento",		oFont08N )
oDacte:Say(	0238, 0286, "Tp.Doc",					oFont08N )

If Len(aDoc) > 0 .And. Empty(AllTrim(aDoc[1][3]))
	oDacte:Say( 0238, 0316, "CNPJ/CPF Emitente",	oFont08N )
EndIf

oDacte:Say( 0238, 0448, "Série/Nr.Documento",		oFont08N )

// Imprime as NF
lControl := .F.
nLInic := 0244
For nCount := 1 To Len(aDoc)
	lControl := !lControl

	If nCount < 75         
		If (lControl == .T.)			
			If Empty(aDoc[nCount,3])
				oDacte:Say(nLInic, 0003, aDoc[nCount,4],										oFont08)
				oDacte:Say(nLInic, 0033, Transform(aDoc[nCount,1],"@R! NN.NNN.NNN/NNNN-99"),		oFont08)
				oDacte:Say(nLInic, 0163, aDoc[nCount,2],										oFont08)
			ElseIf Upper(aDoc[nCount,4]) == "CT-E"
				cChaveA     := aDoc[nCount,3]
				oDacte:Say(nLInic, 0003, "CT-E CHAVE:",											oFont08)
				oDacte:Say(nLInic, 0073, cChaveA,												oFont08)
				cChaveA := ''
			Else
				cChaveA     := aDoc[nCount,3]
				oDacte:Say(nLInic, 0003, "NF-E CHAVE:",											oFont08)
				oDacte:Say(nLInic, 0073, SubStr(cChaveA,1,22),									oFont08)
				oDacte:Say(nLInic, 0168, SubStr(cChaveA,23,3) + " " + SubStr(cChaveA,26,9),		oFont08N)
				oDacte:Say(nLInic, 0223, SubStr(cChaveA,35,10),									oFont08)
				cChaveA     := ''
			EndIf
			
		Else
			If Empty(aDoc[nCount,3])
				oDacte:Say(nLInic, 0286, aDoc[nCount,4],									    oFont08)
				oDacte:Say(nLInic, 0316, Transform(aDoc[nCount,1],"@R! NN.NNN.NNN/NNNN-99"),		oFont08)
				oDacte:Say(nLInic, 0448, aDoc[nCount,2],										oFont08)
			ElseIf Upper(aDoc[nCount,4]) == "CT-E"
				cChaveB     := aDoc[nCount,3]
				oDacte:Say(nLInic, 0286, "CT-E CHAVE:",											oFont08)
				oDacte:Say(nLInic, 0356, cChaveB,												oFont08)
				cChaveB := ''
			Else
				cChaveB     := aDoc[nCount,3]
				oDacte:Say(nLInic, 0286, "NF-E CHAVE:",											oFont08)
				oDacte:Say(nLInic, 0356, SubStr(cChaveB,1,22),									oFont08)
				oDacte:Say(nLInic, 0451, SubStr(cChaveB,23,3) + " " + SubStr(cChaveB,26,9),		oFont08N)
				oDacte:Say(nLInic, 0506, SubStr(cChaveB,35,10),									oFont08)
				cChaveB     := ''
			EndIf
			nLInic += 0008
		EndIf		
	Else
		aAdd( aDoc1, { aDoc[nCount,1], aDoc[nCount,2], aDoc[nCount,3], aDoc[nCount,4] } )
	EndIf
	
Next nCount

// Imprime a ultima Chave.
// FORCAR A "QUEBRA" DA LINHA
If !Empty(cChaveA)
	nLInic += 0008
	oDacte:Say(nLInic, 0003, "NF-E CHAVE:",		oFont08)
	oDacte:Say(nLInic, 0073,cChaveA ,			oFont08)
	cChaveA := ''

	If !Empty(cChaveB)
		oDacte:Say(nLInic, 0286, "NF-E CHAVE:",	oFont08)
		oDacte:Say(nLInic, 0356, cChaveB,		oFont08)
		cChaveB := ''
	EndIf
EndIf

// Linha de finalizacao.
oDacte:EndPage()

// Se existir mais doc para outra pagina, chama a mesma funcao.
If Len(aDoc1) > 1
	TMSR35Cont(oDacte, oNfe, aDoc1,aCab)
EndIf

// Se existir mais prod perigoso para outra pagina, chama a mesma funcao.
If nLInic >= 0820
	TMSR35Cont(oDacte, oNfe, aCab,aPerigo,nCnt)
EndIf

Return

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Programa  ³ TMSR31Cab³ Autor ³Felipe Barbiere           ³ Data ³01/10/12  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³Funcao responsavel por montar o cabecalho do relatorio      ³±±
±±³          ³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   |                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³Nenhum                                                      ³±±
±±³          ³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³   DATA   ³ Programador   ³Manutencao efetuada                         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³          ³               ³                                            ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Static Function TMSR31Cab(oDacte, oNfe, aCab)
Local oFont07    := TFont():New("Times New Roman",07,07,,.F.,,,,.T.,.F.)	//Fonte Times New Roman 07
Local oFont07N   := TFont():New("Times New Roman",07,07,,.T.,,,,.T.,.F.)	//Fonte Times New Roman 08 Negrito
Local oFont08    := TFont():New("Times New Roman",08,08,,.F.,,,,.T.,.F.)	//Fonte Times New Roman 08
Local oFont08N   := TFont():New("Times New Roman",08,08,,.T.,,,,.T.,.F.)	//Fonte Times New Roman 08 Negrito
Local oFont10N   := TFont():New("Times New Roman",10,10,,.T.,,,,.T.,.F.)
Local cTpServ    := ''
Local cProtocolo := ''
Local cStartPath := GetSrvProfString("Startpath","")
Local cLogoTp	 := cStartPath + "logoCte" + cEmpAnt + ".BMP" //Insira o caminho do Logo da empresa logada, na variavel cLogoTp.
Local cQrCode    := ''
Local cTpCte	 := ""

If	IsSrvUnix() .And. GetRemoteType() == 1
	cLogoTp := StrTran(cLogoTp,"/","\")
EndIf

If  !File(cLogoTp)
	cLogoTp    := cStartPath + "logoCte.bmp"
EndIf

oDacte:Box(0086, 0000, 0148, 0240)

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ BOX: Empresa + 0050                                                    ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
oDacte:SayBitmap(0088, 0005,cLogoTp,0088,0057 )		//Logo

If XmlChildEx(oNfe:_INFCTE,'_EMIT') <> Nil
	oDacte:Say(0100, 0090, AllTrim(oNfe:_INFCTE:_EMIT:_XNOME:Text),oFont07) 	//Nome Comercial
	oDacte:Say(0110, 0090, 'CNPJ ' + Transform(AllTrim(oNfe:_INFCTE:_EMIT:_CNPJ:TEXT),"@R! NN.NNN.NNN/NNNN-99") +;
						   ' - IE ' + IIf(XmlChildEx(oNfe:_INFCTE:_EMIT,'_IE'  )==NIL," ",AllTrim(oNfe:_INFCTE:_EMIT:_IE:TEXT)), oFont07)
	oDacte:Say(0120, 0090, AllTrim(oNfe:_INFCTE:_EMIT:_ENDEREMIT:_XLGR:TEXT) + ;
						   ", "+ AllTrim(oNfe:_INFCTE:_EMIT:_ENDEREMIT:_NRO:TEXT) +;
						   IIf(XmlChildEx(oNfe:_INFCTE:_EMIT:_ENDEREMIT,'_XCPL')==Nil, " ", " " + AllTrim(oNfe:_INFCTE:_EMIT:_ENDEREMIT:_XCPL:TEXT) + " ") +;
						   AllTrim(oNfe:_INFCTE:_EMIT:_ENDEREMIT:_XBAIRRO:TEXT), oFont07)	//Endereço + Bairro      
	oDacte:Say(0130, 0090, AllTrim(oNfe:_INFCTE:_EMIT:_ENDEREMIT:_XMUN:TEXT) + '  -  ' +;
					       AllTrim(oNfe:_INFCTE:_EMIT:_ENDEREMIT:_UF:TEXT) + ;
						   '  CEP:  ' + Transform(AllTrim(IIf(XmlChildEx(oNfe:_INFCTE:_EMIT:_ENDEREMIT,'_CEP')==Nil," ",AllTrim(oNfe:_INFCTE:_EMIT:_ENDEREMIT:_CEP:TEXT))), "@r 99999-999") ,oFont07)	//Cidade, UF, CEP
	oDacte:Say(0140, 0090, AllTrim(IIf(XmlChildEx(oNfe:_INFCTE:_EMIT:_ENDEREMIT,'_FONE')==Nil," ",oNfe:_INFCTE:_EMIT:_ENDEREMIT:_FONE:TEXT))	,oFont07)	//Telefone
EndIf
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ BOX: DACTE                                                             ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
oDacte:Box(0086, 0240, 0133, 0377)					
oDacte:Say(0095, 292, "DACTE", oFont10N)
oDacte:Say(0105, 243, "Documento Auxiliar do Conhecimento", oFont08N)
oDacte:Say(0116, 265, "de Transporte Eletrônico", oFont08N)

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ BOX: MODAL                                                             ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
oDacte:Box(0086, 0377, 0133, 0433)
oDacte:Say(0093, 390,"MODAL"     ,oFont08N)
If oNfe:_INFCTE:_IDE:_modal:TEXT == "06" // do tipo MultiModal
	oDacte:Say(0116, 380,Upper("MULTIMODAL"),oFont08 ) 
Else
	oDacte:Say(0116, 380,Upper("Rodoviário"),oFont08 ) 
EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ BOX: FOLHA
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
oDacte:Box(0086, 0433, 0133, 0460)
oDacte:Say(0093, 0435, "Folha"  , oFont08N)	//Folha
oDacte:Say(0116, 0437, AllTrim(Str(nFolhAtu)) + " / " + AllTrim(Str(nFolhas)), oFont08)
nFolhAtu ++

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
//³QRCODE ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
If XmlChildEx( oNfe,'_INFCTESUPL') != Nil
	If XmlChildEx( oNfe:_INFCTESUPL,'_QRCODCTE' ) != NIL .And. !Empty(oNFE:_INFCTESUPL:_QRCODCTE:TEXT  )
		cQrCode := oNfe:_INFCTESUPL:_QRCODCTE:TEXT
	EndIf
EndIf
oDacte:QRCODE(190, 466, cQrCode, 90)	

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³BOX: Modelo / Serie / Numero / Emis                                     ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
oDacte:Box(0125, 0240, 0148, 0270)
oDacte:Say(0133, 0242, "Modelo", oFont08N)	//Modelo
oDacte:Say(0144, 0242, "57", oFont08)

oDacte:Box(0125, 0270, 0148 , 0294)
oDacte:Say(0133, 0272, "Série"  , oFont08N)	//Serie
oDacte:Say(0144, 0272, cValtoChar( Val(aCab[2]) ), oFont08)

oDacte:Box(0125, 0294, 0148, 0333)
oDacte:Say(0133, 0295, "Número" , oFont07N)	//Numero
oDacte:Say(0144, 0295, cValtoChar( Val(aCab[1]) ), oFont08)

oDacte:Box(0125, 0333, 0148, 0396)
oDacte:Say(0133, 0334, "Emissão", oFont07N) //Emissao
oDacte:Say(0144, 0334, 	SubStr(AllTrim(aCab[3]), 7, 2) + '/'   +;
						SubStr(AllTrim(aCab[3]), 5, 2) + "/"   +; 
						SubStr(AllTrim(aCab[3]), 1, 4) + "-" +; 
						SubStr(AllTrim(aCab[4]), 1, 2) + ":"   +;	
						SubStr(AllTrim(aCab[4]), 3, 2) + ":00", oFont07)
oDacte:Box(0125, 0396, 0148, 0460)
oDacte:Say(0133, 0397, "Ins SUFRAMA Des"  , oFont07N)	//Insc. SUFRAMA Destinatário
oDacte:Say(0144, 0397, IIf(XmlChildEx(oNfe:_INFCTE,'_DEST') <> Nil .And. XmlChildEx(oNfe:_INFCTE:_DEST,'_ISUF') <> Nil, oNfe:_INFCTE:_DEST:_ISUF:TEXT, " "), oFont07)

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ BOX: Controle do Fisco                                                 ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
oDacte:Box(0173, 0460, 0185, 0460)
oDacte:Code128C(171.4,286,Right(AllTrim(oNfe:_InfCte:_Id:Text),44), 24)
oDacte:Say(0205, 0282, "Consulta em: http://www.cte-fazenda.gov.br/portal", oFont07)

oDacte:Line(0173, 0280, 0173, 0460 )	//Linha Separadora
oDacte:Say( 0178, 0282,"Chave de acesso",oFont07)
If oDacte:nDevice == 2
	oDacte:Say( 0185, 0281, Transform(AllTrim(aCab[5]),"@r 9999999999999999 9999999999999999 999999999999"), oFont07)
Else 
	oDacte:Say( 0185, 0282, Transform(AllTrim(aCab[5]),"@r 9999 9999 9999 9999 9999 9999 9999 9999 9999 9999 9999"), oFont07N)
EndIf

oDacte:Line(0186, 0280, 0186, 0460 )	//Linha Separadora 
oDacte:Line(0209, 0280, 0209, 0559 )	//Linha Separadora
oDacte:Say(0214,  0282, "Protocolo de Autorização de uso", oFont07)
oDacte:Line(0217, 0280, 0217, 0559 )	//Linha Separadora

oDacte:Line(0173, 0460, 0209, 0460 )	//Linha Vertical
oDacte:Line(0209, 0559, 0217, 0559 )	//Linha Vertical

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³  BOX: Tipo do CTe                                                      ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
oDacte:Box(0148, 0000, 0170, 0280) 
oDacte:Say(0157, 0003, "Tipo do CT-e"   , oFont08N)
oDacte:Say(0157, 0143, "Tipo de Serviço", oFont08N)

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³  BOX: Tipo do CTe  Globalizado                                         ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
oDacte:Box(0170, 0000, 0195, 0280)
oDacte:Say(0180, 0003, "Indicador CT-e Globalizado"  , oFont08N)

If XmlChildEx(oNfe:_INFCTE:_IDE,'_INDGLOBALIZADO') <> NIL .And. AllTrim(oNfe:_INFCTE:_IDE:_INDGLOBALIZADO:Text) == "1"
	oDacte:Say(0190, 0003, "Sim"  , oFont08N)
Else
	oDacte:Say(0190, 0003, "Não"  , oFont08N)
EndIf

oDacte:Say(0180, 0143, "Informações CT-e Globalizado", oFont08N)
oDacte:Line(0148,0140, 0195, 0140)  //Linha Vertical Tipo CT-e / Inf. CT-e Globalizado

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Tipo de Conhecimento                                            ³
//³ 0 - Normal                                                      ³
//³ 1 - Complemento de Valores                                      ³
//³ 2 - Emitido em Hipotese de anulacao de Debito                   ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
cTpCte := If(ValType(XmlChildEx(oNFe:_InfCte,"_IDE")) == "O",AllTrim(oNFe:_InfCte:_Ide:_tpCTe:Text),"") //-- Armazena o tipo do CT-e.
If ( cTpCte == "1" )
	oDacte:Say(0167,  0003, "COMPLEMENTO"	, oFont08)
ElseIf ( cTpCte == "3" )
	oDacte:Say(0167,  0003, "SUBSTITUTO"		, oFont08)	
ElseIf ( cTpCte == "2" )
	oDacte:Say(0167,  0003, "ANULACAO"		, oFont08)
Else
	oDacte:Say(0167,  0003, "NORMAL"		, oFont08)
EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Tipo de Servico                                                 ³
//³ 0 - Normal                                                      ³
//³ 1 - SubContratacao                                              ³
//³ 2 - Redespacho                                                  ³
//³ 3 - Redespacho Intermediario                                    ³
//³ 4 - Serviço Vinculado a Multimodal                              ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ DTC - Notas Fiscais: (Informacao do campo DTC_TIPNFC)           ³
//³   0 - Normal                                                    ³
//³   1 - Devolucao                                                 ³
//³   2 - SubContratacao                                            ³
//³   3 - Dcto Nao Fiscal                                           ³
//³   4 - Exportacao                                                ³
//³   5 - Redespacho                                                ³
//³   6 - Dcto Nao Fiscal 1                                         ³
//³   7 - Dcto Nao Fiscal 2                                         ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
cTpServ := oNfe:_INFCTE:_IDE:_tpserv:TEXT

If (cTpServ $ '0')
	oDacte:Say(0167, 0145, "NORMAL"				, oFont08)
ElseIf (cTpServ == '1')
	oDacte:Say(0167, 0145, "SUBCONTRATAÇÃO"		, oFont08)
ElseIf (cTpServ == '2')
	oDacte:Say(0167, 0145, "REDESPACHO"			, oFont08)
ElseIf (cTpServ == '3')
	oDacte:Say(0167, 0145, "REDESPACHO INTERM"			, oFont08)	//--Redespacho Intermediário
ElseIf (cTpServ == '4')
	oDacte:Say(0167, 0145, "SERV.VINC.MULTIMODAL"			, oFont08)	//--Serviço vinculado Multimodal
Else
	oDacte:Say(0167, 0145, "NORMAL"				, oFont08)
EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Numero Protocolo + Data e Hora Autorizacao                      ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄadminÙ
cProtocolo := aCab[6] + " " + aCab[8] + " " + aCab[9]
oDacte:Say(0214,  0378, cProtocolo, oFont08)

Return

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Programa  ³TMSR27Comp³ Autor ³Felipe Barbiere           ³ Data ³01/10/12  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³Funcao responsavel por montar o BOX com as informacoes do   ³±±
±±³          ³componentes do frete e impostos                             ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   |                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³Nenhum                                                      ³±±
±±³          ³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³   DATA   ³ Programador   ³Manutencao efetuada                         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³          ³               ³                                            ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Static Function TMSR31Comp(oDacte, oNfe)
Local cLabel      	:= ''
Local nCInic      	:= 0			// Coluna Inicial
Local oFont08     	:= TFont():New("Times New Roman",08,08,,.F.,,,,.T.,.F.)
Local oFont08N    	:= TFont():New("Times New Roman",08,08,,.T.,,,,.T.,.F.)
Local oFont10N    	:= TFont():New("Times New Roman",10,10,,.T.,,,,.T.,.F.)
Local lControl    	:= .F.
Local nCount      	:= 0
Local nCount_2    	:= 0
Local cSitTriba		:= "Sit Trib"
Local cBaseIcms		:= ''			//-- Base de Calculo
Local cAliqIcms		:= ''			//-- Aliquota ICMS
Local cValIcms		:= ''			//-- Valor ICMS
Local cRedBcCalc	:= ''			//-- "Red.Bc.Calc."
Local nCount_3		:= 0
Local aComp			:= {}

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ BOX: COMPONENTES DA PRESTACAO                                          ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If lComp
	nLInic	:= 0474
	nLFim	:= 0532	
Else
	nLInic	:= 0414
	nLFim	:= 0472	
EndIf

oDacte:Box(nLInic, 0000, nLFim, 0559)

nLInic	+= 0008
oDacte:Say(nLInic, 0210, "Componentes do Valor da Prestação de Serviço", oFont08N)
	
nLInic	+= 0004
	
oDacte:Line(nLInic, 0000, nLInic, 0559) // Linha: Componentes da Prestacao
oDacte:Line(nLInic, 0140, nLFim, 0140) // Linha: Separador Vertical
oDacte:Line(nLInic, 0280, nLFim, 0280) // Linha: Separador Vertical
oDacte:Line(nLInic, 0420, nLFim, 0420) // Linha: Separador Vertical
	
nLInic	+= 0006
oDacte:Say(nLInic, 0003, "Nome",	oFont08N)
oDacte:Say(nLInic, 0073, "Valor",	oFont08N)
oDacte:Say(nLInic, 0143, "Nome",	oFont08N)
oDacte:Say(nLInic, 0213, "Valor",	oFont08N)
oDacte:Say(nLInic, 0283, "Nome",	oFont08N)
oDacte:Say(nLInic, 0353, "Valor",	oFont08N)
oDacte:Say(nLInic, 0423, "Valor Total da Prestação do Serviço", oFont08N)
	
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Componentes do Valor da Prestacao de Servico                           ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³DT8 - Componentes do Frete                                              ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
nLInic		+= 0008
nCInic		:= 0003
lControl	:= .F.

	aComp := TMSGetComp(oDacte, oNfe)
		
	For nCount_3 := 1 To Len( aComp )
		nCount += 2
		oDacte:Say(nLInic, nCInic, SubStr(AllTrim(aComp[nCount_3][1]),1,14), oFont08)	//Descricao do Componente
		nCInic += 0070	//Proxima Coluna

		oDacte:Say(nLInic, nCInic, Transform(Val(AllTrim(aComp[nCount_3][2])),'@E 999,999,999.99'), oFont08)	//Valor do Componente
		nCInic += 0070	//Proxima Coluna


		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ FORCAR A "QUEBRA" DA LINHA, SENDO 6 CAMPOS POR LINHA.                  ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If ( (mod(nCount,6)) == 0 )
			nCount_2 += 1
			Do Case
				Case ( nCount_2 == 1 )
				cLabel := PadL(Transform(Val(IIf(XmlChildEx( oNfe:_INFCTE,'_VPREST') == NIL," ",oNFE:_INFCTE:_VPREST:_VTPREST:TEXT)),'@E 999,999,999.99'),20)
				Case ( nCount_2 == 2 )
				cLabel := ""
				Case ( nCount_2 == 3 )
					oDacte :Line(nLInic - 8, 0420, nLInic - 8, 0559) // Linha: VALOR A RECEBER
					cLabel := "Valor a Receber"
				Case ( nCount_2 == 4 )
					cLabel := PadL(Transform(Val(IIf(XmlChildEx( oNfe:_INFCTE,'_VPREST') == NIL," ",oNFE:_INFCTE:_VPREST:_VREC:TEXT )),'@E 999,999,999.99'),20)
			EndCase
				
			oDacte:Say(nLInic + 4 , 0423, cLabel, oFont10N)
			nLInic   += 0008
			nCInic   := 0003
		EndIf
	Next nCount_3
	For nCount := (1 + nCount) To 24
		lControl := !lControl
		nCInic   += 0070
		cLabel   := ""
		
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ FORCAR A "QUEBRA" DA LINHA, SENDO 6 CAMPOS POR LINHA.                  ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If ( (mod(nCount,6)) == 0 )
			nCount_2 += 1
			Do Case
				Case ( nCount_2 == 1 )
					If XmlChildEx( oNfe:_INFCTE,'_VPREST') == NIL
						If XmlChildEx( oNfe:_INFCTE,'_TOTAL') == NIL
							cLabel := PadL(Transform(Val(""),'@E 999,999,999.99'),20)
						ElseIf XmlChildEx( oNfe:_INFCTE:_TOTAL,'_VTPREST') == NIL
							cLabel := PadL(Transform(Val(""),'@E 999,999,999.99'),20)
						Else
							cLabel := PadL(Transform(Val(oNFE:_INFCTE:_TOTAL:_VTPREST:TEXT),'@E 999,999,999.99'),20)
						EndIf
					Else
						cLabel := PadL(Transform(Val(IIf(XmlChildEx( oNfe:_INFCTE,'_VPREST') == NIL," ",oNFE:_INFCTE:_VPREST:_VTPREST:TEXT )),'@E 999,999,999.99'),20)
					EndIf
				Case ( nCount_2 == 2 )
					cLabel := ""
				Case ( nCount_2 == 3 )
					oDacte :Line(nLInic - 8, 0420, nLInic - 8, 0559) // Linha: VALOR A RECEBER
					cLabel := "Valor a Receber"
				Case ( nCount_2 == 4 )
					If XmlChildEx( oNfe:_INFCTE,'_VPREST') == NIL
						If XmlChildEx( oNfe:_INFCTE,'_TOTAL') == NIL
							cLabel := PadL(Transform(Val(""),'@E 999,999,999.99'),20)
						ElseIf XmlChildEx( oNfe:_INFCTE:_TOTAL,'_VTREC') == NIL
							cLabel := PadL(Transform(Val(""),'@E 999,999,999.99'),20)
						Else
							cLabel := PadL(Transform(Val(oNFE:_INFCTE:_TOTAL:_VTREC:TEXT),'@E 999,999,999.99'),20)
						EndIf
					Else
						cLabel := PadL(Transform(Val(IIf(XmlChildEx( oNfe:_INFCTE,'_VPREST') == NIL," ",oNFE:_INFCTE:_VPREST:_VREC:TEXT)),'@E 999,999,999.99'),20)
					EndIf
			EndCase
			
			oDacte:Say(nLInic, 0423, cLabel, oFont10N)
			nLInic   += 0008
			nCInic   := 0003
		EndIf
	Next nCount

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ BOX: INFORMACOES RELATIVAS AO IMPOSTO                                  ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

If !lComp
	nLInic	:= 0474
	nLFim	:= 0500	
Else
	nLInic	:= 0534
	nLFim	:= 0560
EndIf

oDacte:Box(nLInic , 0000, nLFim, 0559)

nLInic += 0006
oDacte:Say(nLInic , 0212, "Informações Relativas ao Imposto", oFont08N)

nLInic += 0002
oDacte:Line(nLInic, 0000, nLInic, 0559)	// Linha:
oDacte:Line(nLInic, 0240, nLFim, 0240)	// Linha: Separador Situacao Trib	/ Base de Calculo
oDacte:Line(nLInic, 0350, nLFim, 0350) 	// Linha: Separador Base de Calculo	/ Aliq.ICMS
oDacte:Line(nLInic, 0400, nLFim, 0400) 	// Linha: Separador Aliq.ICMS    	/ Valor ICMS
oDacte:Line(nLInic, 0470, nLFim, 0470) 	// Linha: Separador Valor ICMS    	/ %Red Bc.Calc

nLInic += 0008
oDacte:Say(nLInic , 0003, "Classificação Tributária", oFont08N)   // Label: Classificação Tributária
oDacte:Say(nLInic , 0243, "Base de Cálculo"    , oFont08N)   // Label: Base de Cálculo
oDacte:Say(nLInic , 0353, "Aliq. ICMS"         , oFont08N)   // Label: Aliq.ICMS
oDacte:Say(nLInic , 0403, "Valor ICMS"         , oFont08N)   // Label: Valor ICMS
oDacte:Say(nLInic , 0473, "%Red. Bc. Calc."    , oFont08N)   // Label: %Red.Bc.Calc.

	/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	  ³ Tag <ICMS00>                                                    ³
	  ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ*/
	If !XmlChildEx(oNfe:_INFCTE:_IMP:_ICMS,'_ICMS00') == NIL .And. !XmlChildEx(oNfe:_INFCTE:_IMP:_ICMS:_ICMS00,'_CST') == NIL

		cAliasD2  := DataSource(oDacte, oNfe, 'DESCRSUBSTTRIBUTARIA' )
		
		cSitTriba	:= IIf( XmlChildEx(oNfe:_INFCTE:_IMP:_ICMS:_ICMS00,'_CST') == Nil," ",;
		oNfe:_INFCTE:_IMP:_ICMS:_ICMS00:_CST:TEXT + " - " + SubStr(AllTrim((cAliasD2)->X5DESCRI),1,40) )

		cBaseIcms	:= Val(oNFE:_INFCTE:_IMP:_ICMS:_ICMS00:_VBC:TEXT)
		cAliqIcms	:= Val(oNFE:_INFCTE:_IMP:_ICMS:_ICMS00:_PICMS:TEXT)
		cValIcms	:= Val(oNFE:_INFCTE:_IMP:_ICMS:_ICMS00:_VICMS:TEXT)
		
		(cAliasD2)->(DBCloseArea())
	/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	  ³ Tag <ICMS45>                                                    ³
	  ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ*/
	ElseIf !XmlChildEx(oNfe:_INFCTE:_IMP:_ICMS,'_ICMS45') == Nil .And. !XmlChildEx(oNfe:_INFCTE:_IMP:_ICMS:_ICMS45,'_CST') == Nil

		cAliasD2  := DataSource(oDacte, oNfe, 'DESCRSUBSTTRIBUTARIA' )

		cSitTriba	:= IIf( XmlChildEx(oNfe:_INFCTE:_IMP:_ICMS:_ICMS45,'_CST')==Nil," ",;
		oNfe:_INFCTE:_IMP:_ICMS:_ICMS45:_CST:TEXT + " - " + SubStr(AllTrim((cAliasD2)->X5DESCRI),1,40) )
		
		(cAliasD2)->(DBCloseArea()) 
	/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	  ³ Tag <ICMS90>                                                    ³
	  ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ*/
	ElseIf !XmlChildEx(oNfe:_INFCTE:_IMP:_ICMS,'_ICMS90') == Nil

		cAliasD2  := DataSource(oDacte, oNfe, 'DESCRSUBSTTRIBUTARIA' )

		cSitTriba	:= IIf( XmlChildEx(oNfe:_INFCTE:_IMP:_ICMS:_ICMS90,'_CST') == Nil," ",;
		oNfe:_INFCTE:_IMP:_ICMS:_ICMS90:_CST:TEXT + " - " + SubStr(AllTrim((cAliasD2)->X5DESCRI),1,40) )

		cBaseIcms	:= Val(oNFE:_INFCTE:_IMP:_ICMS:_ICMS90:_VBC:TEXT)
	   	cAliqIcms	:= Val(oNFE:_INFCTE:_IMP:_ICMS:_ICMS90:_PICMS:TEXT)
		cValIcms	:= Val(oNFE:_INFCTE:_IMP:_ICMS:_ICMS90:_VICMS:TEXT)
		cRedBcCalc := Val(IIf( XmlChildEx(oNFE:_INFCTE:_IMP:_ICMS:_ICMS90,'_pRedBC')==Nil," ",(oNFE:_INFCTE:_IMP:_ICMS:_ICMS90:_pRedBC:TEXT) ))
		
		(cAliasD2)->(DBCloseArea())
	/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	  ³ Tag <ICMS20>                                                    ³
	  ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ*/
	ElseIf !XmlChildEx(oNfe:_INFCTE:_IMP:_ICMS,'_ICMS20') == Nil

		cAliasD2  := DataSource(oDacte, oNfe, 'DESCRSUBSTTRIBUTARIA' )

		cSitTriba	:= IIf( XmlChildEx(oNfe:_INFCTE:_IMP:_ICMS:_ICMS20,'_CST')==Nil," ",;
		oNfe:_INFCTE:_IMP:_ICMS:_ICMS20:_CST:TEXT + " - " + SubStr(AllTrim((cAliasD2)->X5DESCRI),1,40) )

		cBaseIcms	:= Val(oNFE:_INFCTE:_IMP:_ICMS:_ICMS20:_VBC:TEXT)
		cAliqIcms	:= Val(oNFE:_INFCTE:_IMP:_ICMS:_ICMS20:_PICMS:TEXT)
		cValIcms	:= Val(oNFE:_INFCTE:_IMP:_ICMS:_ICMS20:_VICMS:TEXT)
		cRedBcCalc := Val(oNFE:_INFCTE:_IMP:_ICMS:_ICMS20:_pRedBC:TEXT)
		
		(cAliasD2)->(DBCloseArea())
	/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	  ³ Tag <ICMS60>                                                    ³
	  ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ*/
	ElseIf !XmlChildEx(oNfe:_INFCTE:_IMP:_ICMS,'_ICMS60') == Nil

		cAliasD2  := DataSource(oDacte, oNfe, 'DESCRSUBSTTRIBUTARIA' )

		cSitTriba	:= IIf( XmlChildEx(oNfe:_INFCTE:_IMP:_ICMS:_ICMS60,'_CST') == "U"," ",;
		oNfe:_INFCTE:_IMP:_ICMS:_ICMS60:_CST:TEXT + " - " + SubStr(AllTrim((cAliasD2)->X5DESCRI),1,40) )

		cBaseIcms	:= Val(oNFE:_INFCTE:_IMP:_ICMS:_ICMS60:_VBCSTRET:TEXT)
		cValIcms	:= Val(oNFE:_INFCTE:_IMP:_ICMS:_ICMS60:_VICMSSTRET:TEXT)
		cAliqIcms	:= Val(oNFE:_INFCTE:_IMP:_ICMS:_ICMS60:_PICMSSTRET:TEXT)
		
		(cAliasD2)->(DBCloseArea())
	ElseIf !XmlChildEx(oNfe:_INFCTE:_IMP:_ICMS,'_ICMSOUTRAUF') == NIL

		cAliasD2  := DataSource(oDacte, oNfe, 'DESCRSUBSTTRIBUTARIA' )

		cSitTriba	:= IIf( XmlChildEx(oNfe:_INFCTE:_IMP:_ICMS:_ICMSOUTRAUF,'_CST') == Nil," ",;
		oNfe:_INFCTE:_IMP:_ICMS:_ICMSOUTRAUF:_CST:TEXT + " - " + SubStr(AllTrim((cAliasD2)->X5DESCRI),1,40) )

	   	cAliqIcms	:= Val(oNFE:_INFCTE:_IMP:_ICMS:_ICMSOUTRAUF:_PICMSOUTRAUF:TEXT)
		cBaseIcms	:= Val(oNFE:_INFCTE:_IMP:_ICMS:_ICMSOUTRAUF:_VBCOUTRAUF:TEXT)
		cValIcms   := Val(oNFE:_INFCTE:_IMP:_ICMS:_ICMSOUTRAUF:_VICMSOUTRAUF:TEXT)
		
		(cAliasD2)->(DBCloseArea())
	/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	  ³ Tag <ICMSSN> Simples Nacional                                   ³
	  ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ*/	
	ElseIf !XmlChildEx(oNfe:_INFCTE:_IMP:_ICMS,'_ICMSSN') == Nil
		cSitTriba	:= IIf( XmlChildEx(oNfe:_INFCTE:_IMP:_ICMS:_ICMSSN,'_INDSN')==Nil," "," Simples Nacional ")		
	EndIf

nLInic += 0008
oDacte:Say(nLInic , 0003, cSitTriba,								oFont08)
oDacte:Say(nLInic , 0243, Transform(cBaseIcms , '@E 999,999,999.99'),	oFont08)
oDacte:Say(nLInic , 0353, Transform(cAliqIcms , '@E 999,999,999.99'),	oFont08)
oDacte:Say(nLInic , 0403, Transform(cValIcms  , '@E 999,999,999.99'),	oFont08)
oDacte:Say(nLInic , 0473, Transform(cRedBcCalc, '@E 999,999,999.99'),	oFont08)

lComp := .F. //CTE Complementar

Return

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Programa  ³ TMSR27Cmp³ Autor ³Felipe Barbiere           ³ Data ³01/10/12  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³Funcao responsavel por montar o BOX relativo as informacoes ³±±
±±³          ³dos componentes e valores complementados                    ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   |                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³Nenhum                                                      ³±±
±±³          ³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³   DATA   ³ Programador   ³Manutencao efetuada                         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³          ³               ³                                            ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Static Function TMSR31Cmp(oDacte, oNfe)

Local nCount    := 0
Local nCount_2  := 0
Local oFont08N  := TFont():New("Times New Roman",08,08,,.T.,,,,.T.,.F.)
Local lControl  := .F.

lComp := .T.	//CTE Complementar

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ BOX: COMPONENTES DO VALOR DA PRESTACAO DO SERVICO                      ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
nLInic  := 0400
nLFim   := 0506
oDacte:Box(nLInic , 0000, nLFim, 0559)

nLInic += 0006
oDacte:Say(nLInic , 0210, "Componentes do Valor da Prestação do Serviço", oFont08N)

nLInic += 0002
oDacte:Line(nLInic, 0000, nLInic, 0559)		// Linha: DOCUMENTOS ORIGINARIOS       
oDacte:Line(nLInic, 0279, nLFim , 0279)	// Linha: Separador DOCUMENTOS ORIGINARIOS

nLInic += 0007
oDacte:Say(nLInic , 0003, "Chave do CT-e Complementado", oFont08N)
oDacte:Say(nLInic , 0205, "Valor Complementado", oFont08N)
oDacte:Say(nLInic , 0281, "Chave do CT-e Complementado", oFont08N)
oDacte:Say(nLInic , 0483, "Valor Complementado", oFont08N)

nLInic   += 0008
nCount   := 0
nCount_2 := 0
lControl := .F.

Return
/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³RTMSR35   ³ Autor ³Felipe Barbiere        ³ Data ³01/10/12     º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Retorna um Array com a estrutura do campo complemento rel. º±±
±±º          ³ ao objeto passado por parametro                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ TMS                                                        º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function TMSGetComp(oDacte, oNfe)
Local i			:= 0		// Auxiliar no Incremento da Estrutura de Laco
Local aAuxClone	:= { }		// Copia da propriedade Comp do Objeto passado por parametro
Local aAuxComp	:= { }		// Auxiliar no processamento de aAuxClone
Local aResult	:= { }		// Retorno da Funcao
If XmlChildEx( oNfe:_INFCTE,'_VPREST') <> NIL
	If ValType(XmlChildEx(oNfe:_INFCTE:_VPREST,"_COMP")) <> "U"
		If	ValType(oNfe:_INFCTE:_VPREST:_COMP) == "A"
			aAuxClone := ACLONE( oNfe:_INFCTE:_VPREST:_COMP )
			For i := 1 To Len( aAuxClone )
				aAdd( aResult, {AllTrim(aAuxClone[ i ]:_XNOME:TEXT), AllTrim(aAuxClone[ i ]:_VCOMP:TEXT)} )
			Next i
		ElseIf	ValType(oNfe:_INFCTE:_VPREST:_COMP) == "O"
			aAdd( aAuxComp, AllTrim(oNfe:_INFCTE:_VPREST:_COMP:_XNOME:TEXT) )
			aAdd( aAuxComp, AllTrim(oNfe:_INFCTE:_VPREST:_COMP:_VCOMP:TEXT) )
			aAdd( aResult, aAuxComp )
			aAuxComp := {}
		EndIf
	EndIf
EndIf
Return ( aResult )


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³RTMSR35   ³ Autor ³Felipe Barbiere        ³ Data ³01/10/12  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³                                                            º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ AP                                                         º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function DataSource(oDacte, oNfe, cSource, cFilDoc, cDoc, cSerie )
Local cNewArea	:= GetNextAlias()
Local cQuery	:= ""

cQuery := GetSQL(oDacte, oNfe, cSource)
DbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), cNewArea, .F., .T.)

Return ( cNewArea )

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³RTMSR35   ³ Autor ³Felipe Barbiere        ³ Data ³01/10/12  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³                                                            º±±
±±º          ³  Cria DACTE sem utilizar o XML, utilizando tabela.         º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ AP                                                         º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function GetSQL(oDacte, oNfe, cSource)
Local cQuery	:= ""
Local cSitTriba	:= ""
// Verifica se existe filtro por lote especifico

If cSource == 'DESCRSUBSTTRIBUTARIA'

	cQuery := " SELECT SX5.X5_DESCRI X5DESCRI"
	cQuery += " FROM " + RetSqlName("SX5") + " SX5 "
	cQuery += " WHERE SX5.X5_FILIAL ='"  + xFilial("SX5") + "'"
	cQuery += "   AND SX5.X5_TABELA ='S2'"

	If !XmlChildEx(oNfe:_INFCTE:_IMP:_ICMS,'_ICMS00')==Nil
		cSitTriba := IIf( XmlChildEx(oNfe:_INFCTE:_IMP:_ICMS:_ICMS00,'_CST')==Nil," ",;
		oNfe:_INFCTE:_IMP:_ICMS:_ICMS00:_CST:TEXT)
	ElseIf !XmlChildEx(oNfe:_INFCTE:_IMP:_ICMS,'_ICMS45')==Nil
		cSitTriba := IIf( XmlChildEx(oNfe:_INFCTE:_IMP:_ICMS:_ICMS45,'_CST')==Nil," ",;
		oNfe:_INFCTE:_IMP:_ICMS:_ICMS45:_CST:TEXT)
	ElseIf !XmlChildEx(oNfe:_INFCTE:_IMP:_ICMS,'_ICMS90')==Nil
		cSitTriba := IIf( XmlChildEx(oNfe:_INFCTE:_IMP:_ICMS:_ICMS90,'_CST')==Nil," ",;
		oNfe:_INFCTE:_IMP:_ICMS:_ICMS90:_CST:TEXT)
	ElseIf !XmlChildEx(oNfe:_INFCTE:_IMP:_ICMS,'_ICMS20')==Nil
		cSitTriba := IIf( XmlChildEx(oNfe:_INFCTE:_IMP:_ICMS:_ICMS20,'_CST')==Nil," ",;
		oNfe:_INFCTE:_IMP:_ICMS:_ICMS20:_CST:TEXT)
	ElseIf !XmlChildEx(oNfe:_INFCTE:_IMP:_ICMS,'_ICMS60')==Nil
		cSitTriba := IIf( XmlChildEx(oNfe:_INFCTE:_IMP:_ICMS:_ICMS60,'_CST')==Nil," ",;
		oNfe:_INFCTE:_IMP:_ICMS:_ICMS60:_CST:TEXT)
	ElseIf !XmlChildEx(oNfe:_INFCTE:_IMP:_ICMS,'_ICMSOUTRAUF')==Nil
		cSitTriba := IIf( XmlChildEx(oNfe:_INFCTE:_IMP:_ICMS:_ICMSOUTRAUF,'_CST')==Nil," ",;
		oNfe:_INFCTE:_IMP:_ICMS:_ICMSOUTRAUF:_CST:TEXT)
	EndIf

	cQuery += " AND SX5.X5_CHAVE  ='" +cSitTriba+ "'"
	cQuery += " AND SX5.D_E_L_E_T_ = ' '"

EndIf

cQuery := ChangeQuery( cQuery )

Return ( cQuery )
