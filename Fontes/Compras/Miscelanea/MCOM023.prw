/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |13/06/2024| Chamado 47576. Incluídos novos filtros na rotina
Lucas Borges  |01/10/2024| Chamado 48644. Incluído tratamento para rotina de consulta de chave
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "TBICONN.CH"
#Include "COLORS.CH"
#Include "RPTDEF.CH"
#Include "FWPrintSetup.ch" 

/*
===============================================================================================================================
Programa--------: MCOM023
Autor-----------: Lucas Borges Ferreira
Data da Criacao-: 16/05/2024
Descrição-------: Tela para visualização de XMLs recebidos. Chamado 47282
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function MCOM023

Local _cFilQry 	:= ""
Local _nAux		:= 0
Local _aSelFil	:= {}
Local _cUpd		:= ""
Local _oMrkBrowse := Nil

Private aRotina	  := MenuDef()
Private cCadastro := "Fila de XMLs Recebidos"

If Pergunte("MCOM023",.T.)
	If MV_PAR12 == 1
		If Empty(_aSelFil)
			_aSelFil := AdmGetFil(.F.,.F.,"SDS")
		EndIf
	Else
		aAdd(_aSelFil,cFilAnt)
	EndIf

	_cFilQry := "CKO_I_EMIT BETWEEN '" + MV_PAR06 + "' AND  '" + MV_PAR07 + "' AND "
	_cFilQry += "CKO_I_EMIS BETWEEN '" + DToS(MV_PAR01) + "' AND '" + DToS(MV_PAR02) + "' AND "
	_cFilQry += "CKO_DT_IMP BETWEEN '" + DToS(MV_PAR03) + "' AND '" + DToS(MV_PAR04) + "' AND "
	//_cFilQry += "CKO_FILPRO = '"+cFilant+"'"
	_cFilQry += "CKO_FILPRO "+ GetRngFil( _aSelFil, "SDS", .T.,)
	If MV_PAR05 == 2 //Mostra gerados no Monitor
		_cFilQry += " AND CKO_FLAG <> '1'"
	EndIf
	If MV_PAR13 == 1 //Somente Validos
		_cFilQry += " AND CKO_FLAG <> '9'"
	EndIf

	If MV_PAR08 == 1 //Apenas Não impressos
		_cFilQry += " AND CKO_I_IMP = 0"
	EndIf
	If MV_PAR09 == 1 //NF-e
		_cFilQry += " AND CKO_CODEDI = '109'"
		// Opcoes para <finNFe>
		// 1 - NF-e normal.
		// 2 - NF-e complementar.
		// 3 - NF-e de ajuste.
		// 4 - Devolução de mercadoria.
		If MV_PAR10 <> 5 //5-Todos
			_cFilQry += " AND CKO_I_FINA = "+CValToChar(MV_PAR10)
		EndIf
	ElseIf MV_PAR09 == 2//CT-e
		_cFilQry += " AND CKO_CODEDI = '214'"
		// Opcoes para <TpCte>:
		// 0 - CT-e Normal;
		// 1 - CT-e de Complemento de Valores;
		// 2 - CT-e de Anulação de Valores;
		// 3 - CT-e Substituto.
		If MV_PAR11 <> 5 //5-Todos
			_nAux := MV_PAR11-1
			_cFilQry += " AND CKO_I_FINA = "+CValToChar(_nAux)
		EndIf
	ElseIf MV_PAR09 == 3//CT-e OS
		_cFilQry += " AND CKO_CODEDI = '273'"
	EndIf

	If MV_PAR14 <> 1//CT-e do Leite
		_cFilQry += " AND "+If(MV_PAR14==2,"","NOT")+" EXISTS (SELECT 1 FROM "+RetSqlName("SA2")+" SA2 WHERE SA2.D_E_L_E_T_ = ' ' "
		_cFilQry += " 			AND CKO_I_EMIT = A2_CGC "
		_cFilQry += " 			AND A2_MSBLQL = '2' "
		_cFilQry += " 			AND SubStr(A2_COD,1,1) IN ('C','G')) "
	EndIf
	_oMrkBrowse:= FWMarkBrowse():New()
	_oMrkBrowse:SetFieldMark("CKO_I_OK")
	_oMrkBrowse:SetAlias("CKO")
	_oMrkBrowse:AddLegend( 'CKO_FLAG == "0"'		, 'WHITE'	, 'Não Processado')
	_oMrkBrowse:AddLegend( 'CKO_FLAG == "1"'		, 'GREEN'	, 'Processado com Sucesso')
	_oMrkBrowse:AddLegend( 'CKO_FLAG == "2"'		, 'RED', 'Processado com Erro')
	_oMrkBrowse:AddLegend( 'CKO_FLAG == "3"'		, 'ORANGE', 'COM005","COM006","COM019')
	_oMrkBrowse:AddLegend( 'CKO_FLAG == "4"'		, 'BLACK', 'Excluído TOTVS')
	_oMrkBrowse:AddLegend( 'CKO_FLAG == "9"'		, 'YELLOW', 'Excluído Italac')
	_oMrkBrowse:SetAllMark( {|| _oMrkBrowse:AllMark()} )// Ação do Clique no Header da Coluna de Marcação
	_oMrkBrowse:SetDescription("Fila processamento TOTVS Colaboração") //"Transferencia de Ativos"###"Cancelar"
	_oMrkBrowse:SetMenuDef("MCOM023")
	_oMrkBrowse:SetFilterDefault("@"+_cFilQry)
	_oMrkBrowse:Activate()
	
	//Limpando a marca ao sair da tela
	_cUpd := " UPDATE " + RetSqlName("CKO") 
	_cUpd += " SET CKO_I_OK = ' '"
	_cUpd += " WHERE CKO_I_OK = '" + _oMrkBrowse:Mark() + "'"
	_cUpd += " AND D_E_L_E_T_ = ' '"

	TCSqlExec(_cUpd)

EndIf

Return

/*
===============================================================================================================================
Programa--------: MenuDef
Autor-----------: Lucas Borges Ferreira
Data da Criacao-: 16/05/2024
Descrição-------: Menu Fila Processamento Totvs Colaboração
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function MenuDef()

Private aRotina	:= {}

aAdd(aRotina,{"Pesquisar"	,"PesqBrw"	,0,1,0,.F.})
aAdd(aRotina,{"Visualizar"	,"AxVisual('CKO',CKO->(Recno()),2)",0,2,0,NIL})
aAdd(aRotina,{"Danfe/Dacte"	,"U_MCOM023D()",0,4,0,nil})

Return aRotina
/*
===============================================================================================================================
Programa--------: MCOM023D
Autor-----------: Realiza a impressão do Danfe/Dacte
Data da Criacao-: 16/05/2024
Descrição-------: Menu Fila Processamento Totvs Colaboração
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function MCOM023D(_cChvNFe)

Local _aArea	:= FwGetArea()
Local _cAlias	:= GetNextAlias()
Local _nQtd		:= 0
Local _cTipo	:= ""
Local oDanfe	:= Nil
Local oSetup	:= Nil
Local aDevice  	:= {}
Local cSession  := GetPrinterSession()
Local cBarra	:= ""
Local _nX 		:= 0
Local cDir		:= ""
Local lJob		:= isBlind()
Local cFilePrint:= ""
Local _lSaida	:= .F.

Default _cChvNFe := ""

DBSelectArea("CKO")
CKO->(DBSetOrder(1))

If FWIsInCallStack("MATA103") .Or. FWIsInCallStack("MATA140")
	If AllTrim(SF1->F1_ESPECIE) == 'SPED'
		_cTipo := '109'
	ElseIf AllTrim(SF1->F1_ESPECIE) == 'CTE'
		_cTipo := '214'
	ElseIf AllTrim(SF1->F1_ESPECIE) == 'CTEOS'
		_cTipo := '273'
	EndIf
	CKO->(DBSeek(_cTipo+SF1->F1_CHVNFE+'.xml'))
ElseIf FWIsInCallStack("COMXCOL")
	CKO->(DBSeek(SDS->DS_ARQUIVO))
	_cTipo := CKO->CKO_CODEDI
ElseIf FWIsInCallStack("U_MCOM027")
	CKO->(DBSetOrder(6))
	If CKO->(DBSeek(_cChvNFe))
		_cTipo := CKO->CKO_CODEDI
	Else
		BeginSql alias _cAlias
			SELECT COUNT(1) QTD, MIN(R_E_C_N_O_)
			FROM SPED050
			WHERE DOC_CHV = %exp:_cChaveNFe%
			AND D_E_L_E_T_ = ' '
		EndSql
		If (_cAlias)->QTD > 0
			DBSelectArea("SPED050")
			SPED050->(DBGoTo((_cAlias)->RECNO))
			_cTipo := "109"
			_lSaida := .T.
		EndIf
		(_cAlias)->(DBCloseArea())
	EndIf
Else
	BeginSql alias _cAlias
		SELECT COUNT(1) QTD, CKO_CODEDI FROM %Table:CKO% WHERE D_E_L_E_T_ = ' ' AND CKO_I_OK = %exp:oMark:cMark% GROUP BY CKO_CODEDI
	EndSql
	_nQtd:= (_cAlias)->QTD
	_cTipo := (_cAlias)->CKO_CODEDI
	(_cAlias)->(DBCloseArea())
EndIf

If Empty(_cTipo)
	FWAlertWarning("Esse modelo de documento não permite a impressão","MCOM02301")
Else

	aAdd(aDevice,"DISCO") // 1
	aAdd(aDevice,"SPOOL") // 2
	aAdd(aDevice,"EMAIL") // 3
	aAdd(aDevice,"EXCEL") // 4
	aAdd(aDevice,"HTML" ) // 5
	aAdd(aDevice,"PDF"  ) // 6

	cFilePrint := "DANFE_DACTE_"+cFilAnt+"_"+DToS(MSDate())+StrTran(Time(),":","")

	nLocal       	:= If(fwGetProfString(cSession,"LOCAL","SERVER",.T.)=="SERVER",1,2 )
	nOrientation 	:= If(fwGetProfString(cSession,"ORIENTATION","PORTRAIT",.T.)=="PORTRAIT",1,2)
	cDevice     	:= If(Empty(fwGetProfString(cSession,"PRINTTYPE","SPOOL",.T.)),"PDF",fwGetProfString(cSession,"PRINTTYPE","SPOOL",.T.))
	nPrintType      := aScan(aDevice,{|x| x == cDevice })

	cBarra := "\"
	If IsSrvUnix()
		cBarra := "/"
	EndIf

	cDir := __RelDir
	If !Empty(cDir) .And. !ExistDir(cDir)
		aDir := StrTokArr(cDir, cBarra)
		cDir := ""
		For _nX := 1 to Len(aDir)
			cDir += aDir[_nX] + cBarra
			If !ExistDir(cDir)
				MakeDir(cDir)
			EndIf
		Next
	EndIf

	lAdjustToLegacy := .F. // Inibe legado de resolução com a TMSPrinter
	oDanfe := FWMSPrinter():New(cFilePrint, IMP_PDF, lAdjustToLegacy, cDir /*cPathInServer*/, .T. )

	If lJob
		oDanfe:SetViewPDF(.F.)
		oDanfe:lInJob := .T.
	EndIf

	// ----------------------------------------------
	// Cria e exibe tela de Setup Customizavel
	// OBS: Utilizar Include "FWPrintSetup.ch"
	// ----------------------------------------------
	//nFlags := PD_ISTOTVSPRINTER+ PD_DISABLEORIENTATION + PD_DISABLEPAPERSIZE + PD_DISABLEPREVIEW + PD_DISABLEMARGIN
	nFlags := PD_ISTOTVSPRINTER + PD_DISABLEPAPERSIZE + PD_DISABLEPREVIEW + PD_DISABLEMARGIN
	If ( !oDanfe:lInJob )
		oSetup := FWPrintSetup():New(nFlags, "DANFE")
		// ----------------------------------------------
		// Define saida
		// ----------------------------------------------
		oSetup:SetPropert(PD_PRINTTYPE   , nPrintType)
		oSetup:SetPropert(PD_ORIENTATION , nOrientation)
		oSetup:SetPropert(PD_DESTINATION , nLocal)
		oSetup:SetPropert(PD_MARGIN      , {60,60,60,60})
		oSetup:SetPropert(PD_PAPERSIZE   , 2)

	EndIf

	// ----------------------------------------------
	// Pressionado botão OK na tela de Setup
	// ----------------------------------------------
	If lJob .Or. oSetup:Activate() == PD_OK // PD_OK =1
		//Salva os Parametros no Profile

		fwWriteProfString( cSession, "LOCAL"      , If( lJob, "SERVER"		, If(oSetup:GetProperty(PD_DESTINATION)==1 ,"SERVER"    ,"CLIENT"    )), .T. )
		fwWriteProfString( cSession, "PRINTTYPE"  , If( lJob, "PDF"		, If(oSetup:GetProperty(PD_PRINTTYPE)==2   ,"SPOOL"     ,"PDF"       )), .T. )
		fwWriteProfString( cSession, "ORIENTATION", If( lJob, "LANDSCAPE"	, If(oSetup:GetProperty(PD_ORIENTATION)==1 ,"PORTRAIT"  ,"LANDSCAPE" )), .T. )

		// Configura o objeto de impressão com o que foi configurado na interface.
		oDanfe:setCopies( Val( If( lJob, "1", oSetup:cQtdCopia )) )

		If ( lJob ) .Or. ( !lJob .And. oSetup:GetProperty(PD_ORIENTATION) == 1 )
			If _cTipo == "109" //Danfe
				U_MCOM024(oDanfe,oSetup,cFilePrint,IIf(_lSaida,'SAIDA',IIf(_nQtd==0,'',oMark:cMark)))
			ElseIf _cTipo $ "214/273" //Dacte
				U_MCOM025(oDanfe,oSetup,cFilePrint,IIf(_nQtd==0,'',oMark:cMark))
			EndIf
			
		EndIf

	EndIf

	oDanfe := Nil
	oSetup := Nil

	//Limpa arquivos temporarios .rel da pasta MV_RELT
	aArquivos := Directory(cDir + "*.rel", "D")

	For _nX := 1 to Len(aArquivos)
		cNome := LOWER(aArquivos[_nX,1])
		If AT("danfe", cNome) > 0
			FERASE(cDir + cNome)
		EndIf
	Next _nX
EndIf

FwRestArea(_aArea)

Return
