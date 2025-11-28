/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |01/10/2024| Chamado 48644. Incluído tratamento para rotina de consulta de chave
Lucas Borges  |19/02/2025| Chamado 49952. Validada a existência da tag _vICMS
Lucas Borges  |22/04/2025| Chamado 50505. Alterada a picture do CNPJ para contemplar campo alfanumérico
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "TBICONN.CH"
#Include "COLORS.CH"
#Include "RPTDEF.CH"
#Include "FWPrintSetup.ch" 

#DEFINE IMP_SPOOL 2

#DEFINE MAXITEM    022				    // Máximo de produtos para a primeira página
#DEFINE MAXITEMP2  049					// Máximo de produtos para a pagina 2 em diante
#DEFINE MAXITEMP2F 030					// Máximo de produtos para a página 2 em diante quando a página não possui informações complementares
#DEFINE MAXITEMC   035					// Máxima de caracteres por linha de produtos/serviços
#DEFINE MAXMENLIN  080					// Máximo de caracteres por linha de dados adicionais
#DEFINE MAXMSG     013					// Máximo de dados adicionais por página
#DEFINE MAXVALORC  009					// Máximo de caracteres por linha de valores numéricos
#DEFINE MAXCODPRD  050				// Máximo de caracteres do codigo de produtos/servicos conforme o tamanho do quadro "Cod. prod"


/*
===============================================================================================================================
Programa--------: MCOM024
Autor-----------: Lucas Borges Ferreira
Data da Criacao-: 16/05/2024
Descrição-------: Realiza a impressão dos Danfes Retrato dos documentos de entrada. Chamado 47282
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function MCOM024(oDanfe ,oSetup ,cFilePrint,_cMarca)

Local lJob		:= isBlind()
Local aArea     := FWGetArea()
Local lExistNfe := .F.

Private nConsNeg := 0.4 // Constante para concertar o cálculo retornado pelo GetTextWidth para fontes em negrito.
Private nConsTex := 0.5 // Constante para concertar o cálculo retornado pelo GetTextWidth.
Private oRetNF

Default _cMarca := ' '

lJob := (oDanfe:lInJob .Or. oSetup == nil)
oDanfe:SetResolution(78) //Tamanho estipulado para a Danfe
oDanfe:SetPortrait()
oDanfe:SetPaperSize(DMPAPER_A4)
oDanfe:SetMargin(60,60,60,60)
oDanfe:lServer := If( lJob , .T., oSetup:GetProperty(PD_DESTINATION)==AMB_SERVER )
// ----------------------------------------------
// Define saida de impressão
// ----------------------------------------------
If lJob .Or. oSetup:GetProperty(PD_PRINTTYPE) == IMP_PDF
	oDanfe:nDevice := IMP_PDF
	// ----------------------------------------------
	// Define para salvar o PDF
	// ----------------------------------------------
	oDanfe:cPathPDF := If ( lJob , __RelDir , oSetup:aOptions[PD_VALUETYPE] )
ElseIf oSetup:GetProperty(PD_PRINTTYPE) == IMP_SPOOL
	oDanfe:nDevice := IMP_SPOOL
	oDanfe:SetParm( "-RFS")
	// ----------------------------------------------
	// Salva impressora selecionada
	// ----------------------------------------------
	fwWriteProfString(GetPrinterSession(),"DEFAULT", oSetup:aOptions[PD_VALUETYPE], .T.)
	oDanfe:cPrinter := oSetup:aOptions[PD_VALUETYPE]
EndIf

RPTStatus( {|lEnd| DANFE(@oDanfe, _cMarca, @lEnd, @lExistNFe)}, "Imprimindo DANFE..." )

If lExistNFe
	oDanfe:Preview()//Visualiza antes de imprimir
Else
	Aviso("DANFE","Nenhuma NF-e a ser impressa nos parametros utilizados.",{"OK"},3)
EndIf

FreeObj(oDANFE)
oDanfe := Nil
oSetup := Nil

FWRestArea(aArea)

Return

/*
===============================================================================================================================
Programa--------: DANFE
Autor-----------: Eduardo Riera
Data da Criacao-: 16/01/2006
Descrição-------: Rdmake de exemplo para impressão da DANFE no formato Retrato
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function DANFE(oDanfe,_cMarca,lEnd,lExistNfe)

Local aArea		:= FWGetArea()
Local cWhere	:= "%"
Local cAviso	:= ""
Local cErro		:= ""
Local oNfe		:= Nil
Local cAlias	:= ""
Local cNoImpr	:= "" 
Local _lSaida	:= IIf(_cMarca == "SAIDA",.T.,.F.)

Private oFont10N   := TFontEx():New(oDanfe,"Times New Roman",08,08,.T.,.T.,.F.)// 1
Private oFont07N   := TFontEx():New(oDanfe,"Times New Roman",06,06,.T.,.T.,.F.)// 2
Private oFont07    := TFontEx():New(oDanfe,"Times New Roman",06,06,.F.,.T.,.F.)// 3
Private oFont08    := TFontEx():New(oDanfe,"Times New Roman",07,07,.F.,.T.,.F.)// 4
Private oFont08N   := TFontEx():New(oDanfe,"Times New Roman",06,06,.T.,.T.,.F.)// 5
Private oFont09N   := TFontEx():New(oDanfe,"Times New Roman",08,08,.T.,.T.,.F.)// 6
Private oFont09    := TFontEx():New(oDanfe,"Times New Roman",08,08,.F.,.T.,.F.)// 7
Private oFont10    := TFontEx():New(oDanfe,"Times New Roman",09,09,.F.,.T.,.F.)// 8
Private oFont11    := TFontEx():New(oDanfe,"Times New Roman",10,10,.F.,.T.,.F.)// 9
Private oFont12    := TFontEx():New(oDanfe,"Times New Roman",11,11,.F.,.T.,.F.)// 10
Private oFont11N   := TFontEx():New(oDanfe,"Times New Roman",10,10,.T.,.T.,.F.)// 11
Private oFont18N   := TFontEx():New(oDanfe,"Times New Roman",17,17,.T.,.T.,.F.)// 12
Private OFONT12N   := TFontEx():New(oDanfe,"Times New Roman",11,11,.T.,.T.,.F.)// 12	 
Private oFont13N   := TFontEx():New(oDanfe,"Times New Roman",08,08,.T.,.T.,.F.)// 13 


Default lEnd		:= .F.

Public nMaxItem := MAXITEM

If !_lSaida
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
		AND CKO_CODEDI = '109'
		%exp:cWhere%
		ORDER BY CKO_FILPRO, CKO_I_EMIT, CKO_ARQUIV
	EndSql
EndIf

While (cAlias)->(!Eof())
	If _lSaida
		oRetNF := XmlParser(SPED050->XML_SIG,"_",@cAviso,@cErro)
	Else
		CKO->(DBGoTo((cAlias)->RECNO))
		oRetNF := XmlParser(IIf(CKO->CKO_I_ALTX=="N",CKO->CKO_XMLRET,CKO->CKO_I_ORIG),"_",@cAviso,@cErro)
	EndIf
	lExistNFe := .T.
	If ValAtrib("oRetNF:_NFEPROC") <> "U"
		oNfe := WSAdvValue( oRetNF,"_NFEPROC","string",NIL,NIL,NIL,NIL,NIL)
	Else
		oNfe := oRetNF
	EndIf
	If Empty( cAviso ) .And. Empty( cErro )
		PrtDanfe(@oDanfe,oNfe)
		If !_lSaida
			RecLock("CKO",.F.)
				CKO->CKO_I_IMP := CKO->CKO_I_IMP+1
				CKO->CKO_I_DTIM := Date()
			MSUnLock()
		EndIf
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
Static Function PrtDanfe(oDanfe,oNFE)

Local aAuxCabec     := {} // Array que conterá as strings de cabeçalho das colunas de produtos/serviços.
Local aTamCol       := {} // Array que conterá o tamanho das colunas dos produtos/serviços.
Local aSitTrib      := {}
Local aSitSN        := {}
Local aTransp       := {}
Local aDest         := {}
Local aRetirada     := {}
Local aEntrega      := {}
Local aHrEnt        := {}
Local aFaturas      := {}
Local aItens        := {}
Local aISSQN        := {}
Local aSimpNac		:= {}
Local aTotais       := {}
Local aAux          := {}
Local aUF           := {}
Local aMensagem     := {}
Local aEspVol       := {}
Local aResFisco     := {}
Local aIndImp	    := {}
Local aIndAux	    := {}

Local nAuxH         := 0
Local nAuxH2        := 0
Local nX            := 0
Local nY            := 0
Local nL            := 0
Local nFolha        := 1
Local nFolhas       := 0
Local nItem         := 0
Local nMensagem     := 0
Local nBaseICM      := 0
Local nValICM       := 0
Local nValIPI       := 0
Local nPICM         := 0
Local nPIPI         := 0
Local nFaturas      := 0
Local nVTotal       := 0
Local nQtd          := 0
Local nVUnit        := 0
Local nVolume	    := 0
Local nLenVol
Local nLenDet
Local nLenSit
Local nLenItens     := 0
Local nLenMensagens := 0
Local nColuna	    := 0
Local nAjustImp     := 0
Local nAjustaRet    := 0
Local nAjustaEnt    := 0
Local nAjustaFat    := 0
Local nAjustaVt     := 0
Local nAjustaPro    := 0
Local nZ		    := 0
Local nMaxCod	    := 0
Local nMaxDes	    := MAXITEMC
Local nLinhavers    := 0
Local nMaxItemP2    := MAXITEM // Variável utilizada para tratamento de quantos itens devem ser impressos na página corrente
Local nTamB5Cod		:= 0
Local cAux          := ""
Local cAuxOnu		:= ""
Local cSitTrib      := ""
Local cUF		 	:= ""
Local cMVCODREG		:= AllTrim( SuperGetMV("MV_CODREG", ," ") )
Local cChaveCont 	:= ""
Local cLogoTotvs 	:= "Powered_by_TOTVS.bmp"
Local cStartPath 	:= GetSrvProfString("Startpath","")
Local lPreview      := .F.
Local lFlag         := .T.
Local lConverte     := GetNewPar("MV_CONVERT",.F.)
Local lMv_ItDesc    := IIf( GetNewPar("MV_ITDESC","N")=="S", .T., .F. )
Local lFimpar	    := .T.
Local lPontilhado 	:= .F.
Local aAuxCom 		:= {}
Local cUnTrib		:= ""
Local nQtdTrib		:= 0
Local nVUnitTrib	:= 0
Local cDadosProt	:= ""
Local cMarca		:= ""
Local cNumeracao	:= ""
Local aMarca		:= {}
Local aNumeracao	:= {}
Local lNFCE 		:= SubStr(oNFe:_NFe:_InfNfe:_ID:Text,24,2) == "65"
Local nMaxUn		:= 2
Local cAuxUn		:= ""
Local lInfAdProd	:= .F.

Private aInfNf    := {}
Private oNF       := oNFe:_NFe
Private oEmitente := oNF:_InfNfe:_Emit
Private oIdent    := oNF:_InfNfe:_IDE
Private oDestino  := IIf(Type("oNF:_InfNfe:_Dest")=="U",Nil,oNF:_InfNfe:_Dest)
Private oTotal    := oNF:_InfNfe:_Total
Private oTransp   := oNF:_InfNfe:_Transp
Private oDet      := oNF:_InfNfe:_Det
Private oFatura   := IIf(Type("oNF:_InfNfe:_Cobr")=="U",Nil,oNF:_InfNfe:_Cobr)
Private oImposto
Private oEntrega  := IIf(Type("oNF:_InfNfe:_Entrega") =="U",Nil,oNF:_InfNfe:_Entrega)
Private oRetirada := IIf(Type("oNF:_InfNfe:_Retirada")=="U",Nil,oNF:_InfNfe:_Retirada)
Private nPrivate  := 0
Private nPrivate2 := 0
Private nXAux	  := 0

nFaturas := IIf(oFatura<>Nil.And.Type("oFatura:_DUP")<>"U",IIf(ValType(oNF:_InfNfe:_Cobr:_Dup)=="A",Len(oNF:_InfNfe:_Cobr:_Dup),1),0)
oDet := IIf(ValType(oDet)=="O",{oDet},oDet)

nAjustImp  := 0
nAjustaRet := 0
nAjustaEnt := 0
nAjustaFat := 0
nAjustaVt  := 0
nAjustaPro := 0

// Popula as variaveis
If( ValType(oEntrega)=="O" ) .And. ( ValType(oRetirada)=="O")
	nAjustImp  := 160
	nAjustaRet := 75
	nAjustaEnt := 150
	nAjustaFat := 160
	nAjustaVt  := 160
	nAjustaPro := 160
	nMaxItem   := 6
	nMaxItemP2 := 6
ElseIf ( ValType(oEntrega)=="O" ) .And. ( ValType(oRetirada)=="U")
	nAjustaRet := 37
	nAjustaEnt := 75
	nAjustImp  := 80
	nAjustaFat := 80
	nAjustaVt  := 80
	nAjustaPro := 80
	nMaxItem   := 14
	nMaxItemP2 := 14
ElseIf ( ValType(oEntrega)=="U" ) .And. ( ValType(oRetirada)=="O")
	nAjustaRet := 75
	nAjustaEnt := 150
	nAjustImp  := 80
	nAjustaFat := 80
	nAjustaVt  := 80
	nAjustaPro := 80
	nMaxItem   := 14
	nMaxItemP2 := 14
EndIf

If ( ValType(oRetirada)=="O" )
	aRetirada := {IIf(Type("oRetirada:_xNome")=="U","",oRetirada:_xNome:Text),;   
    IIf(Type("oRetirada:_CNPJ")=="U","",oRetirada:_CNPJ:Text),;
    IIf(Type("oRetirada:_CPF")=="U","",oRetirada:_CPF:Text),;
    IIf(Type("oRetirada:_xLgr")=="U","",oRetirada:_xLgr:Text),;
    IIf(Type("oRetirada:_nro")=="U","",oRetirada:_nro:Text),;
    IIf(Type("oRetirada:_xCpl")=="U","",oRetirada:_xCpl:Text),;
    IIf(Type("oRetirada:_xBairro")=="U","",oRetirada:_xBairro:Text),;
    IIf(Type("oRetirada:_xMun")=="U","",oRetirada:_xMun:Text),;
    IIf(Type("oRetirada:_UF")=="U","",oRetirada:_UF:Text),;
	IIf(Type("oRetirada:_IE")=="U","",oRetirada:_IE:Text),;
	IIf(Type("oRetirada:_CEP")=="U","",oRetirada:_CEP:Text),;
	IIf(Type("oRetirada:_FONE")=="U","",oRetirada:_Fone:Text),;
	""}
EndIf

If ( ValType(oEntrega)=="O" )
	aEntrega := {IIf(Type("oEntrega:_xNome")=="U","",oEntrega:_xNome:Text),;   
    IIf(Type("oEntrega:_CNPJ")=="U","",oEntrega:_CNPJ:Text),;
    IIf(Type("oEntrega:_CPF")=="U","",oEntrega:_CPF:Text),;
    IIf(Type("oEntrega:_xLgr")=="U","",oEntrega:_xLgr:Text),;
    IIf(Type("oEntrega:_nro")=="U","",oEntrega:_nro:Text),;
    IIf(Type("oEntrega:_xCpl")=="U","",oEntrega:_xCpl:Text),;
    IIf(Type("oEntrega:_xBairro")=="U","",oEntrega:_xBairro:Text),;
    IIf(Type("oEntrega:_xMun")=="U","",oEntrega:_xMun:Text),;
    IIf(Type("oEntrega:_UF")=="U","",oEntrega:_UF:Text),;
	IIf(Type("oEntrega:_IE")=="U","",oEntrega:_IE:Text),;
	IIf(Type("oEntrega:_CEP")=="U","",oEntrega:_CEP:Text),;
	IIf(Type("oEntrega:_FONE")=="U","",oEntrega:_Fone:Text),;
	""}
EndIf

//===========================================================
//Carrega as variaveis de impressao
//===========================================================
aAdd(aSitTrib,"00")
aAdd(aSitTrib,"02")
aAdd(aSitTrib,"10")
aAdd(aSitTrib,"15")
aAdd(aSitTrib,"20")
aAdd(aSitTrib,"30")
aAdd(aSitTrib,"40")
aAdd(aSitTrib,"41")
aAdd(aSitTrib,"50")
aAdd(aSitTrib,"51")
aAdd(aSitTrib,"53")
aAdd(aSitTrib,"60")
aAdd(aSitTrib,"61")
aAdd(aSitTrib,"70")
aAdd(aSitTrib,"90")
aAdd(aSitTrib,"PART")

aAdd(aSitSN,"101")
aAdd(aSitSN,"102")
aAdd(aSitSN,"201")
aAdd(aSitSN,"202")
aAdd(aSitSN,"500")
aAdd(aSitSN,"900")

//Impressao DANFE A4 no PDV NFC-e
If lNFCE .And. (oDestino == Nil .Or. Type("oDestino:_EnderDest") == "U")
	oDestino := MontaNfcDest(oDestino)
EndIf

//===========================================================
//Quadro Destinatario
//===========================================================

aDest := {MontaEnd(oDestino:_EnderDest),;
NoChar(oDestino:_EnderDest:_XBairro:Text,lConverte),;
IIf(Type("oDestino:_EnderDest:_Cep")=="U","",Transform(oDestino:_EnderDest:_Cep:Text,"@r 99999-999")),;
IIf(oNF:_INFNFE:_VERSAO:TEXT >= "3.10",IIf(Type("oIdent:_DHSaiEnt")=="U","",oIdent:_DHSaiEnt:Text),IIf(Type("oIdent:_DSaiEnt")=="U","",oIdent:_DSaiEnt:Text)),;
oDestino:_EnderDest:_XMun:Text,;
IIf(Type("oDestino:_EnderDest:_fone")=="U","",oDestino:_EnderDest:_fone:Text),;
oDestino:_EnderDest:_UF:Text,;
IIf(Type("oDestino:_IE")=="U","",oDestino:_IE:Text),;
""}

If oNF:_INFNFE:_VERSAO:TEXT >= "3.10"
	aAdd(aHrEnt,IIf(Type("oIdent:_dhSaiEnt")=="U","",SubStr(oIdent:_dhSaiEnt:TEXT,12,8)))
Else
	If Type("oIdent:_DSaiEnt")<>"U" .And. Type("oIdent:_HSaiEnt:Text")<>"U"
		aAdd(aHrEnt,oIdent:_HSaiEnt:Text)
	Else
		aAdd(aHrEnt,"")
	EndIf
EndIf
//===========================================================
//Calculo do Imposto
//===========================================================
aTotais := {"","","","","","","","","","",""}
aTotais[01] := Transform(Val(oTotal:_ICMSTOT:_vBC:TEXT),"@e 9,999,999,999,999.99")
aTotais[02] := Transform(Val(oTotal:_ICMSTOT:_vICMS:TEXT),"@e 9,999,999,999,999.99")
aTotais[03] := Transform(Val(oTotal:_ICMSTOT:_vBCST:TEXT),"@e 9,999,999,999,999.99")
aTotais[04] := Transform(Val(oTotal:_ICMSTOT:_vST:TEXT),"@e 9,999,999,999,999.99")
aTotais[05] := Transform(Val(oTotal:_ICMSTOT:_vProd:TEXT),"@e 9,999,999,999,999.99")
aTotais[06] := Transform(Val(oTotal:_ICMSTOT:_vFrete:TEXT),"@e 9,999,999,999,999.99")
aTotais[07] := Transform(Val(oTotal:_ICMSTOT:_vSeg:TEXT),"@e 9,999,999,999,999.99")
aTotais[08] := Transform(Val(oTotal:_ICMSTOT:_vDesc:TEXT),"@e 9,999,999,999,999.99")
aTotais[09] := Transform(Val(oTotal:_ICMSTOT:_vOutro:TEXT),"@e 9,999,999,999,999.99")
aTotais[10] := 	Transform(Val(oTotal:_ICMSTOT:_vIPI:TEXT),"@e 9,999,999,999,999.99")
aTotais[11] := 	Transform(Val(oTotal:_ICMSTOT:_vNF:TEXT),"@e 9,999,999,999,999.99")

//===========================================================
//Quadro Faturas
//===========================================================
If nFaturas > 0
	For nX := 1 To 3
		aAux := {}
		For nY := 1 To Min(9, nFaturas)
			Do Case
				Case nX == 1
					If nFaturas > 1
						aAdd(aAux, AllTrim(oFatura:_Dup[nY]:_nDup:TEXT))
					Else
						aAdd(aAux, AllTrim(oFatura:_Dup:_nDup:TEXT))
					EndIf
				Case nX == 2
					If nFaturas > 1
						aAdd(aAux, AllTrim(ConvDate(oFatura:_Dup[nY]:_dVenc:TEXT)))
					Else
						aAdd(aAux, AllTrim(ConvDate(oFatura:_Dup:_dVenc:TEXT)))
					EndIf
				Case nX == 3
					If nFaturas > 1
						aAdd(aAux, AllTrim(TransForm(Val(oFatura:_Dup[nY]:_vDup:TEXT), "@E 9,999,999,999,999.99")))
					Else
						aAdd(aAux, AllTrim(TransForm(Val(oFatura:_Dup:_vDup:TEXT), "@E 9,999,999,999,999.99")))
					EndIf
			EndCase
		Next nY
		If nY <= 9
			For nY := 1 To 9
				aAdd(aAux, Space(20))
			Next nY
		EndIf
		aAdd(aFaturas, aAux)
	Next nX
EndIf

//===========================================================
//Quadro transportadora
//===========================================================
aTransp := {"","0","","","","","","","","","","","","","",""}

If Type("oTransp:_ModFrete")<>"U"
	aTransp[02] := IIf(Type("oTransp:_ModFrete:TEXT")<>"U",oTransp:_ModFrete:TEXT,"0")
EndIf
If Type("oTransp:_Transporta")<>"U"
	aTransp[01] := IIf(Type("oTransp:_Transporta:_xNome:TEXT")<>"U",NoChar(oTransp:_Transporta:_xNome:TEXT,lConverte),"")
	//	aTransp[02] := IIf(Type("oTransp:_ModFrete:TEXT")<>"U",oTransp:_ModFrete:TEXT,"0")
	aTransp[03] := IIf(Type("oTransp:_VeicTransp:_RNTC")=="U","",oTransp:_VeicTransp:_RNTC:TEXT)
	aTransp[04] := IIf(Type("oTransp:_VeicTransp:_Placa:TEXT")<>"U",oTransp:_VeicTransp:_Placa:TEXT,"")
	aTransp[05] := IIf(Type("oTransp:_VeicTransp:_UF:TEXT")<>"U",oTransp:_VeicTransp:_UF:TEXT,"")
	If Type("oTransp:_Transporta:_CNPJ:TEXT")<>"U"
		aTransp[06] := Transform(oTransp:_Transporta:_CNPJ:TEXT,"@R! NN.NNN.NNN/NNNN-99")
	ElseIf Type("oTransp:_Transporta:_CPF:TEXT")<>"U"
		aTransp[06] := Transform(oTransp:_Transporta:_CPF:TEXT,"@r 999.999.999-99")
	EndIf
	aTransp[07] := IIf(Type("oTransp:_Transporta:_xEnder:TEXT")<>"U",NoChar(oTransp:_Transporta:_xEnder:TEXT,lConverte),"")
	aTransp[08] := IIf(Type("oTransp:_Transporta:_xMun:TEXT")<>"U",oTransp:_Transporta:_xMun:TEXT,"")
	aTransp[09] := IIf(Type("oTransp:_Transporta:_UF:TEXT")<>"U",oTransp:_Transporta:_UF:TEXT,"")
	aTransp[10] := IIf(Type("oTransp:_Transporta:_IE:TEXT")<>"U",oTransp:_Transporta:_IE:TEXT,"")
ElseIf Type("oTransp:_VEICTRANSP")<>"U"
	aTransp[03] := IIf(Type("oTransp:_VeicTransp:_RNTC")=="U","",oTransp:_VeicTransp:_RNTC:TEXT)
	aTransp[04] := IIf(Type("oTransp:_VeicTransp:_Placa:TEXT")<>"U",oTransp:_VeicTransp:_Placa:TEXT,"")
	aTransp[05] := IIf(Type("oTransp:_VeicTransp:_UF:TEXT")<>"U",oTransp:_VeicTransp:_UF:TEXT,"")
EndIf
If Type("oTransp:_Vol")<>"U"
	If ValType(oTransp:_Vol) == "A"
		nX := nPrivate
		nLenVol := Len(oTransp:_Vol)
		cMarca := ""
		aMarca := {}
		cNumeracao := ""
		aNumeracao := {}
		For nX := 1 to nLenVol
			nXAux := nX
			nVolume += IIf(!ValAtrib("oTransp:_Vol[nXAux]:_QVOL:TEXT")=="U",Val(oTransp:_Vol[nXAux]:_QVOL:TEXT),0)
			If !ValAtrib("oTransp:_Vol[nXAux]:_MARCA:TEXT") == "U" .And. !Empty(oTransp:_Vol[nXAux]:_MARCA:TEXT)
				If aScan( aMarca, { |X| X == oTransp:_Vol[nXAux]:_MARCA:TEXT}) == 0 
					aAdd( aMarca, oTransp:_Vol[nXAux]:_MARCA:TEXT )
				EndIf
			EndIf
			If !ValAtrib("oTransp:_Vol[nXAux]:_nVOL:TEXT") == "U" .And. !Empty(oTransp:_Vol[nXAux]:_nVOL:TEXT)
				If aScan( aNumeracao, { |X| X == oTransp:_Vol[nXAux]:_nVOL:TEXT } ) == 0
					aAdd( aNumeracao, oTransp:_Vol[nXAux]:_nVOL:TEXT )
				EndIf
			EndIf
		Next nX

		If Len(aMarca) == 1
			cMarca := aMarca[1]
		ElseIf Len(aMarca) > 1
			cMarca := "Diversos"
		EndIf
		aSize(aMarca,0)
		If Len(aNumeracao) == 1
			cNumeracao := aNumeracao[1]
		ElseIf Len(aNumeracao) > 1
			cNumeracao := "Diversos"
		EndIf
		aSize(aNumeracao,0)

		If Type("oTransp:_Vol:_Marca") == "U" 
			cMarca := NoChar(cMarca,lConverte)
		Else
			cMarca := NoChar(oTransp:_Vol:_Marca:TEXT,lConverte)
		EndIf

		If !Type("oTransp:_Vol:_nVol:TEXT") == "U"
			cNumeracao := oTransp:_Vol:_nVol:TEXT
		EndIf

		aTransp[11]	:= AllTrim(Str(nVolume))
		aTransp[12]	:= IIf(Type("oTransp:_Vol:_Esp")=="U","Diversos","")
		aTransp[13] := cMarca
		aTransp[14] := cNumeracao

		If  Type("oTransp:_Vol[1]:_PesoB") <>"U"
			aTransp[15] := AllTrim(oTransp:_Vol[1]:_PesoB:TEXT)
		EndIf
		If Type("oTransp:_Vol[1]:_PesoL") <>"U"
			aTransp[16] := AllTrim(oTransp:_Vol[1]:_PesoL:TEXT)
		EndIf
	Else
		aTransp[11] := IIf(Type("oTransp:_Vol:_qVol:TEXT")<>"U",oTransp:_Vol:_qVol:TEXT,"")
		aTransp[12] := IIf(Type("oTransp:_Vol:_Esp")=="U","",oTransp:_Vol:_Esp:TEXT)
		aTransp[13] := IIf(Type("oTransp:_Vol:_Marca")=="U","",NoChar(oTransp:_Vol:_Marca:TEXT,lConverte))
		aTransp[14] := IIf(Type("oTransp:_Vol:_nVol:TEXT")<>"U",oTransp:_Vol:_nVol:TEXT,"")
		aTransp[15] := IIf(Type("oTransp:_Vol:_PesoB:TEXT")<>"U",oTransp:_Vol:_PesoB:TEXT,"")
		aTransp[16] := IIf(Type("oTransp:_Vol:_PesoL:TEXT")<>"U",oTransp:_Vol:_PesoL:TEXT,"")
	EndIf
	aTransp[13] := SubStr( aTransp[13], 1, 20)
	aTransp[14] := SubStr( aTransp[14], 1, 20)
	aTransp[15] := StrTran(aTransp[15],".",",")
	aTransp[16] := StrTran(aTransp[16],".",",")
EndIf

If Type("oTransp:_ModFrete") <> "U"
	cModFrete := oTransp:_ModFrete:TEXT
Else
	cModFrete := "1"
EndIf

//==============================================================
//Quadro Dados do Produto / Serviço
//==============================================================
nLenDet := Len(oDet)
If lMv_ItDesc
	For nX := 1 To nLenDet
		aAdd(aIndAux, {nX, SubStr(NoChar(oDet[nX]:_Prod:_xProd:TEXT,lConverte),1,MAXITEMC)})
	Next

	aIndAux := aSort(aIndAux,,, { |x, y| x[2] < y[2] })

	For nX := 1 To nLenDet
		aAdd(aIndImp, aIndAux[nX][1] )
	Next
EndIf

nTamB5Cod := GetSX3Cache( "B5_COD", "X3_TAMANHO" )

For nZ := 1 To nLenDet
	If lMv_ItDesc
		nX := aIndImp[nZ]
	Else
		nX := nZ
	EndIf
	nPrivate := nX

	nVTotal  := Val(oDet[nX]:_Prod:_vProd:TEXT)//-Val(IIf(Type("oDet[nPrivate]:_Prod:_vDesc")=="U","",oDet[nX]:_Prod:_vDesc:TEXT))
	nVUnit   := Val(oDet[nX]:_Prod:_vUnCom:TEXT)

	nQtd     	:= Val(oDet[nX]:_Prod:_qCom:TEXT)
	nBaseICM 	:= 0
	nValICM  	:= 0
	nValIPI  	:= 0
	nPICM    	:= 0
	nPIPI    	:= 0
	oImposto 	:= oDet[nX]
	cSitTrib 	:= ""

    lPontilhado	:= .F.
	If ValAtrib("oImposto:_Imposto")<>"U"
		If ValAtrib("oImposto:_Imposto:_ICMS")<>"U"
			nLenSit := Len(aSitTrib)
			For nY := 1 To nLenSit
				nPrivate2 := nY
				If ValAtrib("oImposto:_Imposto:_ICMS:_ICMS"+aSitTrib[nPrivate2])<>"U" .Or. ValAtrib("oImposto:_Imposto:_ICMS:_ICMSST")<>"U"
					If ValAtrib("oImposto:_Imposto:_ICMS:_ICMS"+aSitTrib[nPrivate2]+":_VBC:TEXT")<>"U"
						nBaseICM := Val(&("oImposto:_Imposto:_ICMS:_ICMS"+aSitTrib[nY]+":_VBC:TEXT"))
						nValICM  := IIf(ValAtrib("oImposto:_Imposto:_ICMS:_ICMS"+aSitTrib[nY]+":_vICMS") <> "U",Val(&("oImposto:_Imposto:_ICMS:_ICMS"+aSitTrib[nY]+":_vICMS:TEXT")),0)
						nPICM    := Val(&("oImposto:_Imposto:_ICMS:_ICMS"+aSitTrib[nY]+":_PICMS:TEXT"))
					ElseIf ValAtrib("oImposto:_Imposto:_ICMS:_ICMS"+aSitTrib[nPrivate2]+":_MOTDESICMS") <> "U" .And. ValAtrib("oImposto:_PROD:_VDESC:TEXT") <> "U"   //SINIEF 25/12, efeitos a partir de 20.12.12
						If !(&("oImposto:_Imposto:_ICMS:_ICMS"+aSitTrib[nY]+":_CST:TEXT") $"40-41")
							If AllTrim(&("oImposto:_Imposto:_ICMS:_ICMS"+aSitTrib[nY]+":_motDesICMS:TEXT")) == "7" .And. &("oImposto:_Imposto:_ICMS:_ICMS"+aSitTrib[nY]+":_CST:TEXT") == "30"
								nValICM  := 0
							Else
								nValICM  := Val(&("oImposto:_Imposto:_ICMS:_ICMS"+aSitTrib[nY]+":_vICMSDESON:TEXT"))
							EndIf
					    EndIf
					EndIf
					If ValAtrib("oImposto:_Imposto:_ICMS:_ICMSST")<>"U" // Tratamento para 4.0
						cSitTrib := &("oImposto:_Imposto:_ICMS:_ICMSST:_ORIG:TEXT")
						cSitTrib += &("oImposto:_Imposto:_ICMS:_ICMSST:_CST:TEXT")
					Else
						cSitTrib := &("oImposto:_Imposto:_ICMS:_ICMS"+aSitTrib[nY]+":_ORIG:TEXT")
						cSitTrib += &("oImposto:_Imposto:_ICMS:_ICMS"+aSitTrib[nY]+":_CST:TEXT")
					EndIf
				EndIf
			Next nY

			//Tratamento para o ICMS para optantes pelo Simples Nacional
			If ValAtrib("oEmitente:_CRT") <> "U" .And. oEmitente:_CRT:TEXT == "1"
				nLenSit := Len(aSitSN)
				For nY := 1 To nLenSit
					nPrivate2 := nY
					If ValAtrib("oImposto:_Imposto:_ICMS:_ICMSSN"+aSitSN[nPrivate2])<>"U"
						If ValAtrib("oImposto:_Imposto:_ICMS:_ICMSSN"+aSitSN[nPrivate2]+":_VBC:TEXT")<>"U"
							nBaseICM := Val(&("oImposto:_Imposto:_ICMS:_ICMSSN"+aSitSN[nY]+":_VBC:TEXT"))
							nValICM  := Val(&("oImposto:_Imposto:_ICMS:_ICMSSN"+aSitSN[nY]+":_vICMS:TEXT"))
							nPICM    := Val(&("oImposto:_Imposto:_ICMS:_ICMSSN"+aSitSN[nY]+":_PICMS:TEXT"))
						EndIf
						cSitTrib := &("oImposto:_Imposto:_ICMS:_ICMSSN"+aSitSN[nY]+":_ORIG:TEXT")
						cSitTrib += &("oImposto:_Imposto:_ICMS:_ICMSSN"+aSitSN[nY]+":_CSOSN:TEXT")
					EndIf
				Next nY
			EndIf

		EndIf
		If ValAtrib("oImposto:_Imposto:_IPI")<>"U"
			If ValAtrib("oImposto:_Imposto:_IPI:_IPITrib:_vIPI:TEXT")<>"U"
				nValIPI := Val(oImposto:_Imposto:_IPI:_IPITrib:_vIPI:TEXT)
			EndIf
			If ValAtrib("oImposto:_Imposto:_IPI:_IPITrib:_pIPI:TEXT")<>"U"
				nPIPI   := Val(oImposto:_Imposto:_IPI:_IPITrib:_pIPI:TEXT)
			EndIf
		EndIf
	EndIf

	nMaxCod := MaxCod(oDet[nX]:_Prod:_cProd:TEXT, MAXCODPRD)

	//Tratativa para que COD Onu seja impresso antes de produto.
	lInfAdProd := (ValAtrib("oNf:_infnfe:_det[nPrivate]:_Infadprod:TEXT") <> "U" .Or. ValAtrib("oNf:_infnfe:_det:_Infadprod:TEXT") <> "U")
	If lInfAdProd
		If nX == 1
			aAdd(aItens,{;
				"-",;
				"-",;
				"-",;
				"-",;
				"-",;
				"-",;
				"-",;
				"-",;
				"-",;
				"-",;
				"-",;
				"-",;
				"-",;
				"-";
			})
		EndIf
	EndIf
	// Tratamento para quebrar os digitos dos valores
	aAux := {}
	aAdd(aAux, AllTrim(TransForm(nQtd,TM(nQtd,15,4))))
	aAdd(aAux, AllTrim(TransForm(nVUnit,TM(nVUnit,TamSX3("D2_PRCVEN")[1],TamSX3("D2_PRCVEN")[2]))))
	aAdd(aAux, AllTrim(TransForm(nVTotal,TM(nVTotal,TamSX3("D2_TOTAL")[1],TamSX3("D2_TOTAL")[2]))))
	aAdd(aAux, AllTrim(TransForm(nBaseICM,TM(nBaseICM,TamSX3("D2_BASEICM")[1],TamSX3("D2_BASEICM")[2]))))
	aAdd(aAux, AllTrim(TransForm(nValICM,TM(nValICM,TamSX3("D2_VALICM")[1],TamSX3("D2_VALICM")[2]))))
	aAdd(aAux, AllTrim(TransForm(nValIPI,TM(nValIPI,TamSX3("D2_VALIPI")[1],TamSX3("D2_BASEIPI")[2]))))

	aAdd(aItens,{;
		SubStr(oDet[nX]:_Prod:_cProd:TEXT,1,nMaxCod),;
		{SubStr(NoChar(oDet[nX]:_Prod:_xProd:TEXT,lConverte),1,nMaxDes), .F.},;
		IIf(ValAtrib("oDet[nPrivate]:_Prod:_NCM")=="U","",oDet[nX]:_Prod:_NCM:TEXT),;
		cSitTrib,;
		oDet[nX]:_Prod:_CFOP:TEXT,;
		SubStr(oDet[nX]:_Prod:_uCom:TEXT,1,nMaxUn),;
		SubStr(aAux[1], 1, PosQuebrVal(aAux[1])),;
		SubStr(aAux[2], 1, PosQuebrVal(aAux[2])),;
		SubStr(aAux[3], 1, PosQuebrVal(aAux[3])),;
		SubStr(aAux[4], 1, PosQuebrVal(aAux[4])),;
		SubStr(aAux[5], 1, PosQuebrVal(aAux[5])),;
		SubStr(aAux[6], 1, PosQuebrVal(aAux[6])),;
		AllTrim(TransForm(nPICM,"@r 99.99%")),;
		AllTrim(TransForm(nPIPI,"@r 99.99%"));
	})

	/*------------------------------------------------------------
		Tratativa para caso haja quebra de linha em algum quadro do item atual
		 a impressao finalize na linha seguinte, antes de iniciar a impressao dos próx. itens.
	------------------------------------------------------------*/
	cAuxItem := AllTrim(SubStr(oDet[nX]:_Prod:_cProd:TEXT,nMaxCod+1))
	cAux     := AllTrim(SubStr(NoChar(oDet[nX]:_Prod:_xProd:TEXT,lConverte),(nMaxDes+1)))
	cAuxUn	 := AllTrim(SubStr(oDet[nX]:_Prod:_uCom:TEXT,nMaxUn+1))
	aAux[1]  := SubStr(aAux[1], PosQuebrVal(aAux[1]) + 1)
	aAux[2]  := SubStr(aAux[2], PosQuebrVal(aAux[2]) + 1)
	aAux[3]  := SubStr(aAux[3], PosQuebrVal(aAux[3]) + 1)
	aAux[4]  := SubStr(aAux[4], PosQuebrVal(aAux[4]) + 1)
	aAux[5]  := SubStr(aAux[5], PosQuebrVal(aAux[5]) + 1)
	aAux[6]  := SubStr(aAux[6], PosQuebrVal(aAux[6]) + 1)

	While !Empty(cAux) .Or. !Empty(cAuxItem) .Or. !Empty(cAuxUn) .Or. !Empty(aAux[1]) .Or. !Empty(aAux[2]) .Or. !Empty(aAux[3]) .Or. !Empty(aAux[4]) .Or. !Empty(aAux[5]) .Or. !Empty(aAux[6])
		nMaxCod := MaxCod(cAuxItem, MAXCODPRD)

		aAdd(aItens,{;
			SubStr(cAuxItem,1,nMaxCod),;
			{SubStr(cAux,1,nMaxDes),.F.},;
			"",;
			"",;
			"",;
			SubStr(cAuxUn,1,nMaxUn),;
			SubStr(aAux[1], 1, PosQuebrVal(aAux[1])),;
			SubStr(aAux[2], 1, PosQuebrVal(aAux[2])),;
			SubStr(aAux[3], 1, PosQuebrVal(aAux[3])),;
			SubStr(aAux[4], 1, PosQuebrVal(aAux[4])),;
			SubStr(aAux[5], 1, PosQuebrVal(aAux[5])),;
			SubStr(aAux[6], 1, PosQuebrVal(aAux[6])),;
			"",;
			"";
		})

		// Popula as informações para as próximas linhas adicionais
		cAux        := SubStr(cAux,(nMaxDes+1))
		cAuxItem    := SubStr(cAuxItem,nMaxCod+1)
		cAuxUn		:= AllTrim(SubStr(cAuxUn,nMaxUn+1))
		aAux[1]     := SubStr(aAux[1], PosQuebrVal(aAux[1]) + 1)
		aAux[2]     := SubStr(aAux[2], PosQuebrVal(aAux[2]) + 1)
		aAux[3]     := SubStr(aAux[3], PosQuebrVal(aAux[3]) + 1)
		aAux[4]     := SubStr(aAux[4], PosQuebrVal(aAux[4]) + 1)
		aAux[5]     := SubStr(aAux[5], PosQuebrVal(aAux[5]) + 1)
		aAux[6]     := SubStr(aAux[6], PosQuebrVal(aAux[6]) + 1)
		lPontilhado := .T.
	EndDo

	// Tratamento quando houver diferença entre as unidades uCom e uTrib ( SEFAZ MT )
	If ( oDet[nX]:_Prod:_uTrib:TEXT <> oDet[nX]:_Prod:_uCom:TEXT )

	    lPontilhado := IIf( nLenDet > 1, .T., lPontilhado )

		cUnTrib		:= SubStr(oDet[nX]:_Prod:_uTrib:TEXT,1,nMaxUn)
		nQtdTrib	:= Val(oDet[nX]:_Prod:_qTrib:TEXT)
	    nVUnitTrib	:= Val(oDet[nX]:_Prod:_vUnTrib:TEXT)

		aAuxCom := {}
		aAdd(aAuxCom, AllTrim(TransForm(nQtdTrib,TM(nQtdTrib,15,4) )))
		aAdd(aAuxCom, AllTrim(TransForm(nVUnitTrib,TM(nVUnitTrib,TamSX3("D2_PRCVEN")[1],TamSX3("D2_PRCVEN")[2]))))

		aAdd(aItens,{;
			"",;
			{"",.F.},;
			"",;
			"",;
			"",;
			cUnTrib,;
			SubStr(aAuxCom[1], 1, PosQuebrVal(aAuxCom[1])),;
			SubStr(aAuxCom[2], 1, PosQuebrVal(aAuxCom[2])),;
			"",;
			"",;
			"",;
			"",;
			"",;
			"";
		})

		aAuxCom[1]  := SubStr(aAuxCom[1], PosQuebrVal(aAuxCom[1]) + 1) // Quantidade - D2_QUANT
		aAuxCom[2]  := SubStr(aAuxCom[2], PosQuebrVal(aAuxCom[2]) + 1) // Valor Unitario - D2_PRCVEN
		cAuxUn := AllTrim(SubStr(oDet[nX]:_Prod:_uTrib:TEXT,nMaxUn+1))
		/*------------------------------------------------------------
			Quebra de linha para os quadros "Quant." e "V.unitário" 
				da 2a. unidade de medida
		------------------------------------------------------------*/
		While !Empty(aAuxCom[1]) .Or. !Empty(aAuxCom[2]) .Or. !Empty(cAuxUn)
			aAdd(aItens,{;
				"",;
				{"",.F.},;
				"",;
				"",;
				"",;
				SubStr(cAuxUn,1,nMaxUn),;
				SubStr(aAuxCom[1], 1, PosQuebrVal(aAuxCom[1])),;
				SubStr(aAuxCom[2], 1, PosQuebrVal(aAuxCom[2])),;
				"",;
				"",;
				"",;
				"",;
				"",;
				"";
				})
			aAuxCom[1]  := SubStr(aAuxCom[1], PosQuebrVal(aAuxCom[1]) + 1) // Quantidade - D2_QUANT
			aAuxCom[2]  := SubStr(aAuxCom[2], PosQuebrVal(aAuxCom[2]) + 1) // Valor Unitario - D2_PRCVEN
			cAuxUn		:= AllTrim(SubStr(cAuxUn,nMaxUn+1))	
		EndDo
	EndIf

	If lInfAdProd
		If at("<", AllTrim(SubStr(oDet[nX]:_Infadprod:TEXT,1))) <> 0
			cAux := stripTags(AllTrim(SubStr(oDet[nX]:_Infadprod:TEXT,1)), .T.) + " "
			cAux += stripTags(AllTrim(SubStr(oDet[nX]:_Infadprod:TEXT,1)), .F.)
		Else
			cAux := stripTags(AllTrim(SubStr(oDet[nX]:_Infadprod:TEXT,1)), .T.)
		EndIf

		While !Empty(cAux)
			aAdd(aItens,{;
				"",;
				{SubStr(cAux,1,nMaxDes), .F.},;
				"",;
				"",;
				"",;
				"",;
				"",;
				"",;
				"",;
				"",;
				"",;
				"",;
				"",;
				"";
			})
			cAux := SubStr(cAux,(nMaxDes + 1))
			lPontilhado := .T.
		EndDo
	EndIf
	If (lPontilhado .Or. !Empty(cAuxOnu)) .And. nZ < nLenDet
		aAdd(aItens,{;
			"-",;
			{"-",.F.},;
			"-",;
			"-",;
			"-",;
			"-",;
			"-",;
			"-",;
			"-",;
			"-",;
			"-",;
			"-",;
			"-",;
			"-";
		})
	EndIf

Next nZ

//==============================================================
//Quadro ISSQN
//==============================================================
aISSQN := {"","","",""}
If Type("oEmitente:_IM:TEXT")<>"U"
	aISSQN[1] := oEmitente:_IM:TEXT
EndIf
If Type("oTotal:_ISSQNtot")<>"U"
	If Type("oTotal:_ISSQNtot:_vServ:TEXT") <> "U"
		aISSQN[2] := Transform(Val(oTotal:_ISSQNtot:_vServ:TEXT),"@e 999,999,999.99")
	EndIf
	If Type("oTotal:_ISSQNtot:_vBC:TEXT") <> "U"
		aISSQN[3] := Transform(Val(oTotal:_ISSQNtot:_vBC:TEXT),"@e 999,999,999.99")
	EndIf
	If Type("oTotal:_ISSQNtot:_vISS:TEXT") <> "U"
		aISSQN[4] := Transform(Val(oTotal:_ISSQNtot:_vISS:TEXT),"@e 999,999,999.99")
	EndIf
EndIf

//==============================================================
//Quadro de informacoes complementares
//==============================================================

aMensagem := {}
If Type("oIdent:_tpAmb:TEXT")<>"U" .And. oIdent:_tpAmb:TEXT=="2"
	cAux := "DANFE emitida no ambiente de homologação - SEM VALOR FISCAL"
	While !Empty(cAux)
		aAdd(aMensagem, { SubStr(cAux,1,IIf(EspacoAt(cAux, MAXMENLIN) > 1, EspacoAt(cAux, MAXMENLIN) - 1, MAXMENLIN)) , .F. } )
		cAux := SubStr(cAux,IIf(EspacoAt(cAux, MAXMENLIN) > 1, EspacoAt(cAux, MAXMENLIN), MAXMENLIN) + 1)
	EndDo
EndIf

If Type("oNF:_InfNfe:_infAdic:_infAdFisco:TEXT")<>"U"
	cAux := oNF:_InfNfe:_infAdic:_infAdFisco:TEXT
	While !Empty(cAux)
		aAdd(aMensagem, { SubStr(cAux,1,IIf(EspacoAt(cAux, MAXMENLIN) > 1, EspacoAt(cAux, MAXMENLIN) - 1, MAXMENLIN)) , .F. } )
		cAux := SubStr(cAux,IIf(EspacoAt(cAux, MAXMENLIN) > 1, EspacoAt(cAux, MAXMENLIN), MAXMENLIN) + 1)
	EndDo
EndIf


If Type("oNF:_InfNfe:_infAdic:_infCpl:TEXT")<>"U"
	If at("<", oNF:_InfNfe:_infAdic:_InfCpl:TEXT) <> 0
		cAux := stripTags(oNF:_InfNfe:_infAdic:_InfCpl:TEXT, .T.) + " "
		cAux += stripTags(oNF:_InfNfe:_infAdic:_InfCpl:TEXT, .F.)
	Else
		cAux := stripTags(oNF:_InfNfe:_infAdic:_InfCpl:TEXT, .T.)
	EndIf
	
	While !Empty(cAux)
		aAdd(aMensagem, { SubStr(cAux,1,IIf(EspacoAt(cAux, MAXMENLIN) > 1, EspacoAt(cAux, MAXMENLIN) - 1, MAXMENLIN)) , .F. } )
		cAux := SubStr(cAux,IIf(EspacoAt(cAux, MAXMENLIN) > 1, EspacoAt(cAux, MAXMENLIN), MAXMENLIN) + 1)
	EndDo
EndIf

For Nx := 1 to Len(aMensagem)
	NoChar(aMensagem[Nx][1],lConverte)
Next

//==============================================================
//Quadro "RESERVADO AO FISCO"
//==============================================================

aResFisco := {}
nBaseIcm  := 0

If GetNewPar("MV_BCREFIS",.F.) .And. SuperGetMv("MV_ESTADO")$"PR"
	If Val(&("oTotal:_ICMSTOT:_VBCST:TEXT")) <> 0
		cAux := "Substituição Tributária: Art. 471, II e §1º do RICMS/PR: "
   		nLenDet := Len(oDet)
   		For nX := 1 To nLenDet
	   		oImposto := oDet[nX]
	   		If ValAtrib("oImposto:_Imposto")<>"U"
		 		If ValAtrib("oImposto:_Imposto:_ICMS")<>"U"
		 			nLenSit := Len(aSitTrib)
		 			For nY := 1 To nLenSit
		 				nPrivate2 := nY
		 				If ValAtrib("oImposto:_Imposto:_ICMS:_ICMS"+aSitTrib[nPrivate2])<>"U"
		 					If ValAtrib("oImposto:_IMPOSTO:_ICMS:_ICMS"+aSitTrib[nPrivate2]+":_VBCST:TEXT")<>"U"
		 		   				nBaseIcm := Val(&("oImposto:_Imposto:_ICMS:_ICMS"+aSitTrib[nY]+":_VBCST:TEXT"))
		 						cAux += oDet[nX]:_PROD:_CPROD:TEXT + ": BCICMS-ST R$" + AllTrim(TransForm(nBaseICM,TM(nBaseICM,TamSX3("D2_BASEICM")[1],TamSX3("D2_BASEICM")[2]))) + " / "
   		 	  				EndIf
   		 	 			EndIf
   					Next nY
   	   			EndIf
   	 		EndIf
   	   	Next nX
	EndIf
	While !Empty(cAux)
 		aAdd(aResFisco,SubStr(cAux,1,60))
   		cAux := SubStr(cAux,IIf(EspacoAt(cAux, MAXMENLIN) > 1, 59, MAXMENLIN) +2)
	EndDo
EndIf

/*
	Calculo do numero de folhas
*/
	nFolhas	  := 1
	nLenItens := Len(aItens) - nMaxItem		// Todos os produtos/serviços excluindo a primeira página
	nMsgCompl := Len(aMensagem) - MAXMSG	// Todas as mensagens complementares excluindo a primeira página
	lFlag     := .T.

	While lFlag
		// Caso existam produtos/serviços e mensagens complementares a serem escritas
		If nLenItens > 0 .And. nMsgCompl > 0
			nFolhas++			
			nLenItens -= MAXITEMP2
			nMsgCompl -= MAXMSG
			
		// Caso existam apenas mensagens complementares a serem escritas
		ElseIf nLenItens <= 0 .And. nMsgCompl > 0
			nFolhas++
			nMsgCompl -= MAXITEMP2
		// Caso existam apenas produtos/serviços a serem escritos
		ElseIf nLenItens > 0 .And. nMsgCompl <= 0
			nFolhas++			
			nLenItens -= MAXITEMP2F
		Else
			lFlag := .F.
		EndIf
	EndDo

//==============================================================
//Inicializacao do objeto grafico
//==============================================================
If oDanfe == Nil
	lPreview := .T.
	oDanfe 	:= FWMSPrinter():New("DANFE", IMP_SPOOL)
	oDanfe:SetPortrait()
	oDanfe:Setup()
EndIf

//==============================================================
//Inicializacao da pagina do objeto grafico
//==============================================================
oDanfe:StartPage()

//==============================================================
//Definicao do Box - Recibo de entrega
//==============================================================

oDanfe:Box(000,000,010,501)
oDanfe:Say(006, 002, "RECEBEMOS DE "+NoChar(oEmitente:_xNome:Text,lConverte)+" OS PRODUTOS CONSTANTES DA NOTA FISCAL INDICADA AO LADO", oFont07:oFont)
oDanfe:Box(009,000,037,101)
oDanfe:Say(017, 002, "DATA DE RECEBIMENTO", oFont07N:oFont)
oDanfe:Box(009,100,037,500)
oDanfe:Say(017, 102, "IDENTIFICAÇÃO E ASSINATURA DO RECEBEDOR", oFont07N:oFont)
oDanfe:Box(000,500,037,603)
oDanfe:Say(007, 542, IIf(lNFCE,"NFC-e","NF-e"), oFont08N:oFont)
oDanfe:Say(017, 510, "N. "+StrZero(Val(oIdent:_NNf:Text),9), oFont08:oFont)
oDanfe:Say(027, 510, "SÉRIE "+SubStr(oIdent:_Serie:Text,1,3), oFont08:oFont)

//==============================================================
//Quadro 1 IDENTIFICACAO DO EMITENTE
//==============================================================

oDanfe:Box(042,000,137,250)
oDanfe:Say(052,096, "Identificação do emitente",oFont12N:oFont)
nLinCalc	:=	065
cStrAux		:=	AllTrim(NoChar(oEmitente:_xNome:Text,lConverte))
nForTo		:=	Len(cStrAux)/24
nForTo		:=	IIf(nForTo>Round(nForTo,0),Round(nForTo,0)+1,Round(nForTo,0))
For nX := 1 To nForTo
	oDanfe:Say(nLinCalc,096,SubStr(cStrAux,IIf(nX==1,1,((nX-1)*24)+1),24), ValidDanfe(oDanfe:nDevice) )
	nLinCalc+=10
Next nX

cStrAux		:=	AllTrim(NoChar(oEmitente:_EnderEmit:_xLgr:Text,lConverte))+", "+AllTrim(oEmitente:_EnderEmit:_Nro:Text)
nForTo		:=	Len(cStrAux)/40
nForTo		+=	IIf(nForTo>Round(nForTo,0),Round(nForTo,0)+1-nForTo,nForTo)
For nX := 1 To nForTo
	oDanfe:Say(nLinCalc,096,SubStr(cStrAux,IIf(nX==1,1,((nX-1)*40)+1),40),oFont08N:oFont)
	nLinCalc+=10
Next nX

If Type("oEmitente:_EnderEmit:_xCpl") <> "U"
	cStrAux		:=	"Complemento: "+AllTrim(NoChar(oEmitente:_EnderEmit:_xCpl:TEXT,lConverte))
	nForTo		:=	Len(cStrAux)/40
	nForTo		+=	IIf(nForTo>Round(nForTo,0),Round(nForTo,0)+1-nForTo,nForTo)
	For nX := 1 To nForTo
		oDanfe:Say(nLinCalc,096,SubStr(cStrAux,IIf(nX==1,1,((nX-1)*40)+1),40),oFont08N:oFont)
		nLinCalc+=10
	Next nX

	cStrAux		:=	AllTrim(oEmitente:_EnderEmit:_xBairro:Text)
	If Type("oEmitente:_EnderEmit:_Cep")<>"U"
		cStrAux		+=	" Cep:"+TransForm(oEmitente:_EnderEmit:_Cep:Text,"@r 99999-999")
	EndIf
	nForTo		:=	Len(cStrAux)/40
	nForTo		+=	IIf(nForTo>Round(nForTo,0),Round(nForTo,0)+1-nForTo,nForTo)
	For nX := 1 To nForTo
		oDanfe:Say(nLinCalc,096,SubStr(cStrAux,IIf(nX==1,1,((nX-1)*40)+1),40),oFont08N:oFont)
		nLinCalc+=10
	Next nX
	oDanfe:Say(nLinCalc,096, oEmitente:_EnderEmit:_xMun:Text+"/"+oEmitente:_EnderEmit:_UF:Text,oFont08N:oFont)
	nLinCalc+=9
	oDanfe:Say(nLinCalc,096, "Fone: "+IIf(Type("oEmitente:_EnderEmit:_Fone")=="U","",oEmitente:_EnderEmit:_Fone:Text),oFont08N:oFont)
Else
	oDanfe:Say(nLinCalc,096, NoChar(oEmitente:_EnderEmit:_xBairro:Text,lConverte)+" Cep:"+TransForm(IIf(Type("oEmitente:_EnderEmit:_Cep")=="U","",oEmitente:_EnderEmit:_Cep:Text),"@r 99999-999"),oFont08N:oFont)
	nLinCalc+=10
	oDanfe:Say(nLinCalc,096, oEmitente:_EnderEmit:_xMun:Text+"/"+oEmitente:_EnderEmit:_UF:Text,oFont08N:oFont)
	nLinCalc+=9
	oDanfe:Say(nLinCalc,096, "Fone: "+IIf(Type("oEmitente:_EnderEmit:_Fone")=="U","",oEmitente:_EnderEmit:_Fone:Text),oFont08N:oFont)
EndIf

//==============================================================
//Quadro 2
//==============================================================

oDanfe:Box(042,248,137,351)
If oDanfe:nDevice == 2
	oDanfe:Say(055,275, "DANFE",oFont12N:oFont)
Else
	oDanfe:Say(055,275, "DANFE",oFont18N:oFont)
EndIf
oDanfe:Say(065,258, "DOCUMENTO AUXILIAR DA",oFont07:oFont)

If lNFCE
	oDanfe:Say(075,258, "NOTA FISCAL DE CONSUMIDOR",oFont07:oFont)
Else
	oDanfe:Say(075,258, "NOTA FISCAL ELETRÔNICA",oFont07:oFont)
EndIf
oDanfe:Say(085,266, "0-ENTRADA",oFont08:oFont)
oDanfe:Say(095,266, "1-SAÍDA"  ,oFont08:oFont)
oDanfe:Box(078,315,095,325)
oDanfe:Say(089,318, oIdent:_TpNf:Text,oFont08N:oFont)
oDanfe:Say(110,255,"N. "+StrZero(Val(oIdent:_NNf:Text),9),oFont10N:oFont)
oDanfe:Say(120,255,"SÉRIE "+SubStr(oIdent:_Serie:Text,1,3),oFont10N:oFont)
oDanfe:Say(130,255,"FOLHA "+StrZero(nFolha,2)+"/"+StrZero(nFolhas,2),oFont10N:oFont)

//==============================================================
//Preenchimento do Array de UF
//==============================================================
aAdd(aUF,{"RO","11"})
aAdd(aUF,{"AC","12"})
aAdd(aUF,{"AM","13"})
aAdd(aUF,{"RR","14"})
aAdd(aUF,{"PA","15"})
aAdd(aUF,{"AP","16"})
aAdd(aUF,{"TO","17"})
aAdd(aUF,{"MA","21"})
aAdd(aUF,{"PI","22"})
aAdd(aUF,{"CE","23"})
aAdd(aUF,{"RN","24"})
aAdd(aUF,{"PB","25"})
aAdd(aUF,{"PE","26"})
aAdd(aUF,{"AL","27"})
aAdd(aUF,{"MG","31"})
aAdd(aUF,{"ES","32"})
aAdd(aUF,{"RJ","33"})
aAdd(aUF,{"SP","35"})
aAdd(aUF,{"PR","41"})
aAdd(aUF,{"SC","42"})
aAdd(aUF,{"RS","43"})
aAdd(aUF,{"MS","50"})
aAdd(aUF,{"MT","51"})
aAdd(aUF,{"GO","52"})
aAdd(aUF,{"DF","53"})
aAdd(aUF,{"SE","28"})
aAdd(aUF,{"BA","29"})
aAdd(aUF,{"EX","99"})

//==============================================================
//Codigo de barra
//==============================================================

oDanfe:Box(042,350,088,603)
oDanfe:Box(075,350,110,603)
If oDanfe:nDevice == 2
	oDanfe:Say(095,355,TransForm(SubStr(oNF:_InfNfe:_ID:Text,4),"@r 9999 9999 9999 9999 9999 9999 9999 9999 9999 9999 9999"),oFont09N:oFont)
Else
	oDanfe:Say(095,355,TransForm(SubStr(oNF:_InfNfe:_ID:Text,4),"@r 9999 9999 9999 9999 9999 9999 9999 9999 9999 9999 9999"),oFont12N:oFont)
EndIf

oDanfe:Box(105,350,137,603)

If nFolha == 1
	If oDanfe:nDevice == 2
		oDanfe:Say(085,355,"CHAVE DE ACESSO DA "+IIf(lNFCE,"NFC-E","NF-E"),oFont09N:oFont)
	Else
		oDanfe:Say(085,355,"CHAVE DE ACESSO DA "+IIf(lNFCE,"NFC-E","NF-E"),oFont12N:oFont)
	EndIf		
	
	nFontSize := 28
	oDanfe:Code128C(072,370,SubStr(oNF:_InfNfe:_ID:Text,4), nFontSize )

EndIf

If !Empty(cUF) .And. !Empty(cDataEmi) .And. !Empty(cTPEmis) .And. !Empty(cValIcm) .And. !Empty(cICMSp) .And. !Empty(cICMSs)
	If Type("oNF:_InfNfe:_DEST:_CNPJ:Text")<>"U"
		cCNPJCPF := oNF:_InfNfe:_DEST:_CNPJ:Text
		If cUf == "99"
			cCNPJCPF := StrZero(Val(cCNPJCPF),14)
		EndIf
	ElseIf Type("oNF:_INFNFE:_DEST:_CPF:Text")<>"U"
		cCNPJCPF := oNF:_INFNFE:_DEST:_CPF:Text
		cCNPJCPF := StrZero(Val(cCNPJCPF),14)
	Else
		cCNPJCPF := ""
	EndIf
	cChaveCont += cUF+cTPEmis+cCNPJCPF+cValIcm+cICMSp+cICMSs+cDataEmi
	cChaveCont := cChaveCont+Modulo11(cChaveCont)
EndIf

If oDanfe:nDevice == 2
	oDanfe:Say(117,355,"Consulta de autenticidade no portal nacional da "+IIf(lNFCE,"NFC-e","NF-e"),oFont09N:oFont)
	oDanfe:Say(127,355,"www.nfe.fazenda.gov.br/portal ou no site da SEFAZ Autorizada",oFont09:oFont)
Else
	oDanfe:Say(117,355,"Consulta de autenticidade no portal nacional da "+IIf(lNFCE,"NFC-e","NF-e"),oFont12:oFont)
	oDanfe:Say(127,355,"www.nfe.fazenda.gov.br/portal ou no site da SEFAZ Autorizada",oFont12:oFont)
EndIf

// inicio do segundo codigo de barras ref. a transmissao CONTIGENCIA OFF Line
If !Empty(cChaveCont)  .And. !(Val(SubStr(oNF:_INFNFE:_IDE:_SERIE:TEXT,1,3)) >= 900)
	If nFolha == 1
		If !Empty(cChaveCont)
			nFontSize := 28
			oDanfe:Code128C(135,370,cChaveCont, nFontSize )
		EndIf
	Else
		If !Empty(cChaveCont)
			nFontSize := 28
			oDanfe:Code128C(112,370,cChaveCont, nFontSize )
		EndIf
	EndIf
EndIf

//Quadro 4
oDanfe:Box(139,000,162,603)
oDanfe:Box(139,000,162,350)
oDanfe:Say(148,002,"NATUREZA DA OPERAÇÃO",oFont08N:oFont)
oDanfe:Say(158,002,oIdent:_NATOP:TEXT,oFont08:oFont)

If (((Val(SubStr(oNF:_INFNFE:_IDE:_SERIE:TEXT,1,3)) >= 900).And.(oNFe:_NFE:_INFNFE:_IDE:_TPEMIS:TEXT)$"23") .Or. (oNFe:_NFE:_INFNFE:_IDE:_TPEMIS:TEXT)$"1|6|7")
	oDanfe:Say(148,352,"PROTOCOLO DE AUTORIZAÇÃO DE USO",oFont08N:oFont)
EndIf
If((oNFe:_NFE:_INFNFE:_IDE:_TPEMIS:TEXT)$"25")
	oDanfe:Say(148,352,"DADOS DA "+IIf(lNFCE,"NFC-E","NF-E"),oFont08N:oFont)
EndIf

cDadosProt := IIf(((Val(SubStr(oNF:_INFNFE:_IDE:_SERIE:TEXT,1,3)) >= 900).And.(oNFe:_NFE:_INFNFE:_IDE:_TPEMIS:TEXT)$"23") .Or. (oNFe:_NFE:_INFNFE:_IDE:_TPEMIS:TEXT)$"1|6|7",AllTrim(ConvDate(IIf(oNF:_INFNFE:_VERSAO:TEXT >= "3.10",ConvDate(oIdent:_DHEmi:TEXT),ConvDate(oIdent:_DEmi:TEXT))))+" ",TransForm(cChaveCont,"@r 9999 9999 9999 9999 9999 9999 9999 9999 9999"))
oDanfe:Say(158,354,cDadosProt,oFont08:oFont)

nFolha++

//Quadro 5
oDanfe:Box(164,000,187,603)
oDanfe:Box(164,000,187,200)
oDanfe:Box(164,200,187,400)
oDanfe:Box(164,400,187,603)
oDanfe:Say(172,002,"INSCRIÇÃO ESTADUAL",oFont08N:oFont)
oDanfe:Say(180,002,IIf(Type("oEmitente:_IE:TEXT")<>"U",oEmitente:_IE:TEXT,""),oFont08:oFont)
oDanfe:Say(172,205,"INSC.ESTADUAL DO SUBST.TRIB.",oFont08N:oFont)
oDanfe:Say(180,205,IIf(Type("oEmitente:_IEST:TEXT")<>"U",oEmitente:_IEST:TEXT,""),oFont08:oFont)
oDanfe:Say(172,405,"CNPJ/CPF",oFont08N:oFont)
Do Case
	Case Type("oEmitente:_CNPJ")=="O"
		cAux := TransForm(oEmitente:_CNPJ:TEXT,"@R! NN.NNN.NNN/NNNN-99")
	Case Type("oEmitente:_CPF")=="O"
		cAux := TransForm(oEmitente:_CPF:TEXT,"@r 999.999.999-99")
	OtherWise
		cAux := Space(14)
EndCase

oDanfe:Say(180,405,cAux,oFont08:oFont)

//Quadro destinatário/remetente
Do Case
	Case Type("oDestino:_CNPJ")=="O"
		cAux := TransForm(oDestino:_CNPJ:TEXT,"@R! NN.NNN.NNN/NNNN-99")
	Case Type("oDestino:_CPF")=="O"
		cAux := TransForm(oDestino:_CPF:TEXT,"@r 999.999.999-99")
	OtherWise
		cAux := Space(14)
EndCase

oDanfe:Say(195,002,"DESTINATARIO/REMETENTE",oFont08N:oFont)
oDanfe:Box(197,000,217,450)
oDanfe:Say(205,002, "NOME/RAZÃO SOCIAL",oFont08N:oFont)
oDanfe:Say(215,002,NoChar(oDestino:_XNome:TEXT,lConverte),oFont08:oFont)
oDanfe:Box(197,280,217,500)
oDanfe:Say(205,283,"CNPJ/CPF",oFont08N:oFont)
oDanfe:Say(215,283,cAux,oFont08:oFont)

oDanfe:Box(217,000,237,500)
oDanfe:Box(217,000,237,260)
oDanfe:Say(224,002,"ENDEREÇO",oFont08N:oFont)
oDanfe:Say(234,002,aDest[01],oFont08:oFont)
oDanfe:Box(217,230,237,380)
oDanfe:Say(224,232,"BAIRRO/DISTRITO",oFont08N:oFont)
oDanfe:Say(234,232,aDest[02],oFont08:oFont)
oDanfe:Box(217,380,237,500)
oDanfe:Say(224,382,"CEP",oFont08N:oFont)
oDanfe:Say(234,382,aDest[03],oFont08:oFont)

oDanfe:Box(236,000,257,500)
oDanfe:Box(236,000,257,180)
oDanfe:Say(245,002,"MUNICIPIO",oFont08N:oFont)
oDanfe:Say(255,002,aDest[05],oFont08:oFont)
oDanfe:Box(236,150,257,256)
oDanfe:Say(245,152,"FONE/FAX",oFont08N:oFont)
oDanfe:Say(255,152,aDest[06],oFont08:oFont)
oDanfe:Box(236,255,257,341)
oDanfe:Say(245,257,"UF",oFont08N:oFont)
oDanfe:Say(255,257,aDest[07],oFont08:oFont)
oDanfe:Box(236,340,257,500)
oDanfe:Say(245,342,"INSCRIÇÃO ESTADUAL",oFont08N:oFont)
oDanfe:Say(255,342,aDest[08],oFont08:oFont)

oDanfe:Box(197,502,217,603)
oDanfe:Say(205,504,"DATA DE EMISSÃO",oFont08N:oFont)
oDanfe:Say(215,504,IIf(oNF:_INFNFE:_VERSAO:TEXT >= "3.10",ConvDate(oIdent:_DHEmi:TEXT),ConvDate(oIdent:_DEmi:TEXT)),oFont08:oFont)
oDanfe:Box(217,502,237,603)
oDanfe:Say(224,504,"DATA ENTRADA/SAÍDA",oFont08N:oFont)
oDanfe:Say(233,504,IIf( Empty(aDest[4]),"",ConvDate(aDest[4]) ),oFont08:oFont)
oDanfe:Box(236,502,257,603)
oDanfe:Say(243,503,"HORA ENTRADA/SAÍDA",oFont08N:oFont)
oDanfe:Say(252,503,aHrEnt[01],oFont08:oFont)

//Quadro Informações do Local de retirada
If ValType(oRetirada)=="O"
	Do Case
		Case Type("oRetirada:_CNPJ")=="O"
			cAux := TransForm(oRetirada:_CNPJ:TEXT,"@R! NN.NNN.NNN/NNNN-99")
		Case Type("oRetirada:_CPF")=="O"
			cAux := TransForm(oRetirada:_CPF:TEXT,"@r 999.999.999-99")
		OtherWise
			cAux := Space(14)
	EndCase

	oDanfe:Say(195+nAjustaRet,002,"INFORMAÇÕES DO Local DE RETIRADA",oFont08N:oFont)
	oDanfe:Box(197+nAjustaRet,000,217+nAjustaRet,450)
	oDanfe:Say(205+nAjustaRet,002, "NOME/RAZÃO SOCIAL",oFont08N:oFont)
	oDanfe:Say(215+nAjustaRet,002,NoChar(aRetirada[1],lConverte),oFont08:oFont)
	oDanfe:Box(197+nAjustaRet,380,217+nAjustaRet,500)
	oDanfe:Say(205+nAjustaRet,383,"CNPJ/CPF",oFont08N:oFont)
	oDanfe:Say(215+nAjustaRet,383,cAux,oFont08:oFont)
	oDanfe:Box(217+nAjustaRet,000,237+nAjustaRet,500)
	oDanfe:Box(217+nAjustaRet,000,237+nAjustaRet,260)
	oDanfe:Say(224+nAjustaRet,002,"ENDEREÇO",oFont08N:oFont)
	oDanfe:Say(234+nAjustaRet,002,MontaEnd(oRetirada),oFont08:oFont)
	oDanfe:Say(224+nAjustaRet,262,"BAIRRO/DISTRITO",oFont08N:oFont)
	oDanfe:Say(234+nAjustaRet,262,aRetirada[7],oFont08:oFont)
	oDanfe:Box(236+nAjustaRet,000,257+nAjustaRet,500)
	oDanfe:Box(236+nAjustaRet,000,257+nAjustaRet,480)
	oDanfe:Say(245+nAjustaRet,002,"MUNICIPIO",oFont08N:oFont)
	oDanfe:Say(255+nAjustaRet,002,aRetirada[8],oFont08:oFont)
	oDanfe:Say(245+nAjustaRet,485,"UF",oFont08N:oFont)
	oDanfe:Say(255+nAjustaRet,485,aRetirada[09],oFont08:oFont)
	oDanfe:Box(197+nAjustaRet,502,217+nAjustaRet,603)
	oDanfe:Say(205+nAjustaRet,504,"INSCRIÇÃO ESTADUAL",oFont08N:oFont)
	oDanfe:Say(215+nAjustaRet,504,aRetirada[10],oFont08:oFont)
	oDanfe:Box(217+nAjustaRet,502,237+nAjustaRet,603)
	oDanfe:Say(224+nAjustaRet,504,"CEP",oFont08N:oFont)
	oDanfe:Say(233+nAjustaRet,504,aRetirada[11],oFont08:oFont)
	oDanfe:Box(236+nAjustaRet,502,257+nAjustaRet,603)
	oDanfe:Say(243+nAjustaRet,503,"FONE/FAX",oFont08N:oFont)
	oDanfe:Say(252+nAjustaRet,503,aRetirada[12],oFont08:oFont)
EndIf

//Quadro Informações do Local de entrega
If ValType(oEntrega)=="O"
	Do Case
		Case Type("oEntrega:_CNPJ")=="O"
			cAux := TransForm(oEntrega:_CNPJ:TEXT,"@R! NN.NNN.NNN/NNNN-99")
		Case Type("oEntrega:_CPF")=="O"
			cAux := TransForm(oEntrega:_CPF:TEXT,"@r 999.999.999-99")
		OtherWise
			cAux := Space(14)
	EndCase

	oDanfe:Say(195+nAjustaEnt,002,"INFORMAÇÕES DO Local DE ENTREGA",oFont08N:oFont)
	oDanfe:Box(197+nAjustaEnt,000,217+nAjustaEnt,450)
	oDanfe:Say(205+nAjustaEnt,002, "NOME/RAZÃO SOCIAL",oFont08N:oFont)
	oDanfe:Say(215+nAjustaEnt,002,NoChar(aEntrega[1],lConverte),oFont08:oFont)
	oDanfe:Box(197+nAjustaEnt,380,217+nAjustaEnt,500)
	oDanfe:Say(205+nAjustaEnt,383,"CNPJ/CPF",oFont08N:oFont)
	oDanfe:Say(215+nAjustaEnt,383,cAux,oFont08:oFont)
	oDanfe:Box(217+nAjustaEnt,000,237+nAjustaEnt,500)
	oDanfe:Box(217+nAjustaEnt,000,237+nAjustaEnt,260)
	oDanfe:Say(224+nAjustaEnt,002,"ENDEREÇO",oFont08N:oFont)
	oDanfe:Say(234+nAjustaEnt,002,MontaEnd(oEntrega),oFont08:oFont)
	oDanfe:Say(224+nAjustaEnt,262,"BAIRRO/DISTRITO",oFont08N:oFont)
	oDanfe:Say(234+nAjustaEnt,262,aEntrega[7],oFont08:oFont)
	oDanfe:Box(236+nAjustaEnt,000,257+nAjustaEnt,500)
	oDanfe:Box(236+nAjustaEnt,000,257+nAjustaEnt,480)
	oDanfe:Say(245+nAjustaEnt,002,"MUNICIPIO",oFont08N:oFont)
	oDanfe:Say(255+nAjustaEnt,002,aEntrega[8],oFont08:oFont)
	oDanfe:Say(245+nAjustaEnt,485,"UF",oFont08N:oFont)
	oDanfe:Say(255+nAjustaEnt,485,aEntrega[9],oFont08:oFont)
	oDanfe:Box(197+nAjustaEnt,502,217+nAjustaEnt,603)
	oDanfe:Say(205+nAjustaEnt,504,"INSCRIÇÃO ESTADUAL",oFont08N:oFont)
	oDanfe:Say(215+nAjustaEnt,504,aEntrega[10],oFont08:oFont)
	oDanfe:Box(217+nAjustaEnt,502,237+nAjustaEnt,603)
	oDanfe:Say(224+nAjustaEnt,504,"CEP",oFont08N:oFont)
	oDanfe:Say(233+nAjustaEnt,504,aEntrega[11],oFont08:oFont)
	oDanfe:Box(236+nAjustaEnt,502,257+nAjustaEnt,603)
	oDanfe:Say(243+nAjustaEnt,503,"FONE/FAX",oFont08N:oFont)
	oDanfe:Say(252+nAjustaEnt,503,aEntrega[12],oFont08:oFont)

EndIf

//Quadro fatura
aAux := {{{},{},{},{},{},{},{},{},{}}}
nY := 0
For nX := 1 To Len(aFaturas)
	nY++
	aAdd(Atail(aAux)[nY],aFaturas[nX][1])
	nY++
	aAdd(Atail(aAux)[nY],aFaturas[nX][2])
	nY++
	aAdd(Atail(aAux)[nY],aFaturas[nX][3])
	nY++
	aAdd(Atail(aAux)[nY],aFaturas[nX][4])
	nY++
	aAdd(Atail(aAux)[nY],aFaturas[nX][5])
	nY++
	aAdd(Atail(aAux)[nY],aFaturas[nX][6])
	nY++
	aAdd(Atail(aAux)[nY],aFaturas[nX][7])
	nY++
	aAdd(Atail(aAux)[nY],aFaturas[nX][8])
	nY++
	aAdd(Atail(aAux)[nY],aFaturas[nX][9])
	If nY >= 9
		nY := 0
	EndIf
Next nX

oDanfe:Say(263+nAjustaFat,002,"FATURA",oFont08N:oFont)
oDanfe:Box(265+nAjustaFat,000,296+nAjustaFat,068)
oDanfe:Box(265+nAjustaFat,067,296+nAjustaFat,134)
oDanfe:Box(265+nAjustaFat,134,296+nAjustaFat,202)
oDanfe:Box(265+nAjustaFat,201,296+nAjustaFat,268)
oDanfe:Box(265+nAjustaFat,268,296+nAjustaFat,335)
oDanfe:Box(265+nAjustaFat,335,296+nAjustaFat,403)
oDanfe:Box(265+nAjustaFat,402,296+nAjustaFat,469)
oDanfe:Box(265+nAjustaFat,469,296+nAjustaFat,537)
oDanfe:Box(265+nAjustaFat,536,296+nAjustaFat,603)

nColuna := 002
If Len(aFaturas) >0
	For nY := 1 To 9
		oDanfe:Say(273+nAjustaFat,nColuna,aAux[1][nY][1],oFont08:oFont)
		oDanfe:Say(281+nAjustaFat,nColuna,aAux[1][nY][2],oFont08:oFont)
		oDanfe:Say(289+nAjustaFat,nColuna,aAux[1][nY][3],oFont08:oFont)
		nColuna:= nColuna+67
	Next nY
EndIf

//Calculo do imposto
oDanfe:Say(305+nAjustImp,002,"CALCULO DO IMPOSTO",oFont08N:oFont)
oDanfe:Box(307+nAjustImp,000,330+nAjustImp,121)
oDanfe:Say(316+nAjustImp,002,"BASE DE CALCULO DO ICMS",oFont08N:oFont)
If cMVCODREG $ "2|3"
	oDanfe:Say(326+nAjustImp,002,aTotais[01],oFont08:oFont)
ElseIf lImpSimpN
	oDanfe:Say(326+nAjustImp,002,aSimpNac[01],oFont08:oFont)
EndIf
oDanfe:Box(307+nAjustImp,120,330+nAjustImp,200)
oDanfe:Say(316+nAjustImp,125,"VALOR DO ICMS",oFont08N:oFont)
If cMVCODREG $ "2|3"
	oDanfe:Say(326+nAjustImp,125,aTotais[02],oFont08:oFont)
ElseIf lImpSimpN
	oDanfe:Say(326+nAjustImp,125,aSimpNac[02],oFont08:oFont)
EndIf
oDanfe:Box(307+nAjustImp,199,330+nAjustImp,360)
oDanfe:Say(316+nAjustImp,200,"BASE DE CALCULO DO ICMS SUBSTITUIÇÃO",oFont08N:oFont)
oDanfe:Say(326+nAjustImp,202,aTotais[03],oFont08:oFont)
oDanfe:Box(307+nAjustImp,360,330+nAjustImp,490)
oDanfe:Say(316+nAjustImp,363,"VALOR DO ICMS SUBSTITUIÇÃO",oFont08N:oFont)
oDanfe:Say(326+nAjustImp,363,aTotais[04],oFont08:oFont)
oDanfe:Box(307+nAjustImp,490,330+nAjustImp,603)
oDanfe:Say(316+nAjustImp,491,"VALOR TOTAL DOS PRODUTOS",oFont08N:oFont)
oDanfe:Say(327+nAjustImp,491,aTotais[05],oFont08:oFont)

oDanfe:Box(330+nAjustImp,000,353+nAjustImp,110)
oDanfe:Say(339+nAjustImp,002,"VALOR DO FRETE",oFont08N:oFont)
oDanfe:Say(349+nAjustImp,002,aTotais[06],oFont08:oFont)
oDanfe:Box(330+nAjustImp,100,353+nAjustImp,190)
oDanfe:Say(339+nAjustImp,102,"VALOR DO SEGURO",oFont08N:oFont)
oDanfe:Say(349+nAjustImp,102,aTotais[07],oFont08:oFont)
oDanfe:Box(330+nAjustImp,190,353+nAjustImp,290)
oDanfe:Say(339+nAjustImp,194,"DESCONTO",oFont08N:oFont)
oDanfe:Say(349+nAjustImp,194,aTotais[08],oFont08:oFont)
oDanfe:Box(330+nAjustImp,290,353+nAjustImp,415)
oDanfe:Say(339+nAjustImp,295,"OUTRAS DESPESAS ACESSÓRIAS",oFont08N:oFont)
oDanfe:Say(349+nAjustImp,295,aTotais[09],oFont08:oFont)
oDanfe:Box(330+nAjustImp,414,353+nAjustImp,500)
oDanfe:Say(339+nAjustImp,420,"VALOR DO IPI",oFont08N:oFont)
oDanfe:Say(349+nAjustImp,420,aTotais[10],oFont08:oFont)
oDanfe:Box(330+nAjustImp,500,353+nAjustImp,603)
oDanfe:Say(339+nAjustImp,506,"VALOR TOTAL DA NOTA",oFont08N:oFont)
oDanfe:Say(349+nAjustImp,506,aTotais[11],oFont08:oFont)

//Transportador/Volumes transportados
oDanfe:Say(361+nAjustaVt,002,"TRANSPORTADOR/VOLUMES TRANSPORTADOS",oFont08N:oFont)
oDanfe:Box(363+nAjustaVt,000,386+nAjustaVt,603)
oDanfe:Say(372+nAjustaVt,002,"RAZÃO SOCIAL",oFont08N:oFont)
oDanfe:Say(382+nAjustaVt,002,aTransp[01],oFont08:oFont)
oDanfe:Box(363+nAjustaVt,243,386+nAjustaVt,315)
oDanfe:Say(372+nAjustaVt,245,"FRETE POR CONTA",oFont08N:oFont)
If cModFrete =="0"
	oDanfe:Say(382+nAjustaVt,245,"0-REMETENTE",oFont08:oFont)
ElseIf cModFrete =="1"
	oDanfe:Say(382+nAjustaVt,245,"1-DESTINATARIO",oFont08:oFont)
ElseIf cModFrete =="2"
	oDanfe:Say(382+nAjustaVt,245,"2-TERCEIROS",oFont08:oFont)
ElseIf cModFrete =="3"
	oDanfe:Say(382+nAjustaVt,245,"3-TRANSP PROP/REM",oFont08:oFont)
ElseIf cModFrete =="4"
	oDanfe:Say(382+nAjustaVt,245,"4-TRANSP PROP/DEST",oFont08:oFont)
ElseIf cModFrete =="9"
	oDanfe:Say(382+nAjustaVt,245,"9-SEM FRETE",oFont08:oFont)
Else
	oDanfe:Say(382+nAjustaVt,245,"",oFont08:oFont)
EndIf
oDanfe:Box(363+nAjustaVt,315,386+nAjustaVt,370)
oDanfe:Say(372+nAjustaVt,317,"CÓDIGO ANTT",oFont08N:oFont)
oDanfe:Say(382+nAjustaVt,319,aTransp[03],oFont08:oFont)
oDanfe:Box(363+nAjustaVt,370,386+nAjustaVt,490)
oDanfe:Say(372+nAjustaVt,375,"PLACA DO VEÍCULO",oFont08N:oFont)
oDanfe:Say(382+nAjustaVt,375,aTransp[04],oFont08:oFont)
oDanfe:Box(363+nAjustaVt,450,386+nAjustaVt,510)
oDanfe:Say(372+nAjustaVt,452,"UF",oFont08N:oFont)
oDanfe:Say(382+nAjustaVt,452,aTransp[05],oFont08:oFont)
oDanfe:Box(363+nAjustaVt,510,386+nAjustaVt,603)
oDanfe:Say(372+nAjustaVt,512,"CNPJ/CPF",oFont08N:oFont)
oDanfe:Say(382+nAjustaVt,512,aTransp[06],oFont08:oFont)

oDanfe:Box(385+nAjustaVt,000,409+nAjustaVt,603)
oDanfe:Box(385+nAjustaVt,000,409+nAjustaVt,241)
oDanfe:Say(393+nAjustaVt,002,"ENDEREÇO",oFont08N:oFont)
oDanfe:Say(404+nAjustaVt,002,aTransp[07],oFont08:oFont)
oDanfe:Box(385+nAjustaVt,240,409+nAjustaVt,341)
oDanfe:Say(393+nAjustaVt,242,"MUNICIPIO",oFont08N:oFont)
oDanfe:Say(404+nAjustaVt,242,aTransp[08],oFont08:oFont)
oDanfe:Box(385+nAjustaVt,340,409+nAjustaVt,440)
oDanfe:Say(393+nAjustaVt,342,"UF",oFont08N:oFont)
oDanfe:Say(404+nAjustaVt,342,aTransp[09],oFont08:oFont)
oDanfe:Box(385+nAjustaVt,440,409+nAjustaVt,603)
oDanfe:Say(393+nAjustaVt,442,"INSCRIÇÃO ESTADUAL",oFont08N:oFont)
oDanfe:Say(404+nAjustaVt,442,aTransp[10],oFont08:oFont)

oDanfe:Box(408+nAjustaVt,000,432+nAjustaVt,603)
oDanfe:Box(408+nAjustaVt,000,432+nAjustaVt,101)
oDanfe:Say(418+nAjustaVt,002,"QUANTIDADE",oFont08N:oFont)
oDanfe:Say(428+nAjustaVt,002,aTransp[11],oFont08:oFont)
oDanfe:Box(408+nAjustaVt,59,432+nAjustaVt,285)
oDanfe:Say(418+nAjustaVt,61,"ESPECIE",oFont08N:oFont)
oDanfe:Say(428+nAjustaVt,61,IIf(!Empty(aTransp[12]),aTransp[12],IIf(Len(aEspVol)>0,aEspVol[1][1],"")),oFont08:oFont)
oDanfe:Box(408+nAjustaVt,285,432+nAjustaVt,285)
oDanfe:Say(418+nAjustaVt,287,"MARCA",oFont08N:oFont)
oDanfe:Say(428+nAjustaVt,287,aTransp[13],oFont08:oFont)
oDanfe:Box(408+nAjustaVt,385,432+nAjustaVt,385)
oDanfe:Say(418+nAjustaVt,387,"NUMERAÇÃO",oFont08N:oFont)
oDanfe:Say(428+nAjustaVt,387,aTransp[14],oFont08:oFont)
oDanfe:Box(408+nAjustaVt,485,432+nAjustaVt,485)
oDanfe:Say(418+nAjustaVt,487,"PESO BRUTO",oFont08N:oFont)
oDanfe:Say(428+nAjustaVt,487,IIf(!Empty(aTransp[15]),aTransp[15],IIf(Len(aEspVol)>0 .And. Val(aEspVol[1][3])>0,Transform(Val(aEspVol[1][3]),"@E 999999.9999"),"")),oFont08:oFont)
oDanfe:Box(408+nAjustaVt,544,432+nAjustaVt,603)
oDanfe:Say(418+nAjustaVt,546,"PESO LIQUIDO",oFont08N:oFont)
oDanfe:Say(428+nAjustaVt,546,IIf(!Empty(aTransp[16]),aTransp[16],IIf(Len(aEspVol)>0 .And. Val(aEspVol[1][2])>0,Transform(Val(aEspVol[1][2]),"@E 999999.9999"),"")),oFont08:oFont)

//Calculo do ISSQN
oDanfe:Say(686,000,"CALCULO DO ISSQN",oFont08N:oFont)
oDanfe:Box(688,000,711,151)
oDanfe:Say(696,002,"INSCRIÇÃO MUNICIPAL",oFont08N:oFont)
oDanfe:Say(706,002,aISSQN[1],oFont08:oFont)
oDanfe:Box(688,150,711,301)
oDanfe:Say(696,152,"VALOR TOTAL DOS SERVIÇOS",oFont08N:oFont)
oDanfe:Say(706,152,aISSQN[2],oFont08:oFont)
oDanfe:Box(688,300,711,451)
oDanfe:Say(696,302,"BASE DE CÁLCULO DO ISSQN",oFont08N:oFont)
oDanfe:Say(706,302,aISSQN[3],oFont08:oFont)
oDanfe:Box(688,450,711,603)
oDanfe:Say(696,452,"VALOR DO ISSQN",oFont08N:oFont)
oDanfe:Say(706,452,aISSQN[4],oFont08:oFont)

//Dados Adicionais
oDanfe:Say(719,000,"DADOS ADICIONAIS",oFont08N:oFont)
oDanfe:Box(721,000,865,351)
oDanfe:Say(729,002,"INFORMAÇÕES COMPLEMENTARES",oFont08N:oFont)

nLenMensagens:= Len(aMensagem)
nLin:= 741
nMensagem := 0
For nX := 1 To Min(nLenMensagens, MAXMSG)
	If aMensagem[nX][2]
		oDanfe:Say( nLin, 002, aMensagem[nX][1], oFont08N:oFont )
	Else
		oDanfe:Say( nLin, 002, aMensagem[nX][1], oFont08:oFont )
	EndIf
	nLin:= nLin+10
Next nX
nMensagem := nX

oDanfe:Box(721,350,865,603)
oDanfe:Say(729,352,"RESERVADO AO FISCO",oFont08N:oFont)

//Logotipo Rodape
If file(cLogoTotvs) .Or. Resource2File ( cLogoTotvs, cStartPath+cLogoTotvs )
	oDanfe:SayBitmap(866,484,cLogoTotvs,120,20)
EndIf

nLenMensagens:= Len(aResFisco)
nLin:= 741
For nX := 1 To Min(nLenMensagens, MAXMSG)
	oDanfe:Say(nLin,351,aResFisco[nX],oFont08:oFont)
	nLin:= nLin+10
Next

//Dados do produto ou servico
aAux := {{{},{},{},{},{},{},{},{},{},{},{},{},{},{}}}
nY := 0
nLenItens := Len(aItens)

For nX :=1 To nLenItens
	nY++
	aAdd(Atail(aAux)[nY],aItens[nX][01])
	nY++
	aAdd(Atail(aAux)[nY],aItens[nX][02])
	nY++
	aAdd(Atail(aAux)[nY],aItens[nX][03])
	nY++
	aAdd(Atail(aAux)[nY],aItens[nX][04])
	nY++
	aAdd(Atail(aAux)[nY],aItens[nX][05])
	nY++
	aAdd(Atail(aAux)[nY],aItens[nX][06])
	nY++
	aAdd(Atail(aAux)[nY],aItens[nX][07])
	nY++
	aAdd(Atail(aAux)[nY],aItens[nX][08])
	nY++
	aAdd(Atail(aAux)[nY],aItens[nX][09])
	nY++
	aAdd(Atail(aAux)[nY],aItens[nX][10])
	nY++
	aAdd(Atail(aAux)[nY],aItens[nX][11])
	nY++
	aAdd(Atail(aAux)[nY],aItens[nX][12])
	nY++
	aAdd(Atail(aAux)[nY],aItens[nX][13])
	nY++
	aAdd(Atail(aAux)[nY],aItens[nX][14])
	If nY >= 14
		nY := 0
	EndIf
Next nX
For nX := 1 To nLenItens
	nY++
	aAdd(Atail(aAux)[nY],"")
	nY++
	aAdd(Atail(aAux)[nY],"")
	nY++
	aAdd(Atail(aAux)[nY],"")
	nY++
	aAdd(Atail(aAux)[nY],"")
	nY++
	aAdd(Atail(aAux)[nY],"")
	nY++
	aAdd(Atail(aAux)[nY],"")
	nY++
	aAdd(Atail(aAux)[nY],"")
	nY++
	aAdd(Atail(aAux)[nY],"")
	nY++
	aAdd(Atail(aAux)[nY],"")
	nY++
	aAdd(Atail(aAux)[nY],"")
	nY++
	aAdd(Atail(aAux)[nY],"")
	nY++
	aAdd(Atail(aAux)[nY],"")
	nY++
	aAdd(Atail(aAux)[nY],"")
	nY++
	aAdd(Atail(aAux)[nY],"")
	If nY >= 14
		nY := 0
	EndIf

Next nX

// Popula o array de cabeçalho das colunas de produtos/serviços.
aAuxCabec := {;
	"COD. PROD",;
	"DESCRIÇÃO DO PROD./SERV.",;
	"NCM/SH",;
	IIf( cMVCODREG == "1", "CSOSN","CST" ),;
	"CFOP",;
	"UN",;
	"QUANT.",;
	"V.UNITARIO",;
	"V.TOTAL",;
	"BC.ICMS",;
	"V.ICMS",;
	"V.IPI",;
	"A.ICMS",;
	"A.IPI";
}

// Retorna o tamanho das colunas baseado em seu conteudo
aTamCol := RetTamCol(aAuxCabec, aAux, oDanfe, oFont08:oFont, oFont08N:oFont)

oDanfe:Say(440+nAjustaPro,002,"DADOS DO PRODUTO / SERVIÇO",oFont08N:oFont)
oDanfe:Box(442+nAjustaPro,000,678,603)
nAuxH := 0
oDanfe:Box(442+nAjustaPro, nAuxH, 678, nAuxH + aTamCol[1])
oDanfe:Say(450+nAjustaPro, nAuxH + 2, "COD. PROD",oFont08N:oFont)
nAuxH += aTamCol[1]
oDanfe:Box(442+nAjustaPro, nAuxH, 678, nAuxH + aTamCol[2])
oDanfe:Say(450+nAjustaPro, nAuxH + 2, "DESCRIÇÃO DO PROD./SERV.", oFont08N:oFont)
nAuxH += aTamCol[2]
oDanfe:Box(442+nAjustaPro, nAuxH, 678, nAuxH + aTamCol[3])
oDanfe:Say(450+nAjustaPro, nAuxH + 2, "NCM/SH", oFont08N:oFont)
nAuxH += aTamCol[3]
oDanfe:Box(442+nAjustaPro, nAuxH, 678, nAuxH + aTamCol[4])

If cMVCODREG == "1"
	oDanfe:Say(450+nAjustaPro, nAuxH + 2, "CSOSN", oFont08N:oFont)
Else
	oDanfe:Say(450+nAjustaPro, nAuxH + 2, "CST", oFont08N:oFont)
EndIf
nAuxH += aTamCol[4]
oDanfe:Box(442+nAjustaPro, nAuxH, 678, nAuxH + aTamCol[5])
oDanfe:Say(450+nAjustaPro, nAuxH + 2, "CFOP", oFont08N:oFont)
nAuxH += aTamCol[5]
oDanfe:Box(442+nAjustaPro, nAuxH, 678, nAuxH + aTamCol[6])
oDanfe:Say(450+nAjustaPro, nAuxH + 2, "UN", oFont08N:oFont)
nAuxH += aTamCol[6]
oDanfe:Box(442+nAjustaPro, nAuxH, 678, nAuxH + aTamCol[7])
oDanfe:Say(450+nAjustaPro, nAuxH + 2, "QUANT.", oFont08N:oFont)
nAuxH += aTamCol[7]
oDanfe:Box(442+nAjustaPro, nAuxH, 678, nAuxH + aTamCol[8])
oDanfe:Say(450+nAjustaPro, nAuxH + 2, "V.UNITARIO", oFont08N:oFont)
nAuxH += aTamCol[8]
oDanfe:Box(442+nAjustaPro, nAuxH, 678, nAuxH + aTamCol[9])
oDanfe:Say(450+nAjustaPro, nAuxH + 2, "V.TOTAL", oFont08N:oFont)
nAuxH += aTamCol[9]
oDanfe:Box(442+nAjustaPro, nAuxH, 678, nAuxH + aTamCol[10])
oDanfe:Say(450+nAjustaPro, nAuxH + 2, "BC.ICMS", oFont08N:oFont)
nAuxH += aTamCol[10]
oDanfe:Box(442+nAjustaPro, nAuxH, 678, nAuxH + aTamCol[11])
oDanfe:Say(450+nAjustaPro, nAuxH + 2, "V.ICMS", oFont08N:oFont)
nAuxH += aTamCol[11]
oDanfe:Box(442+nAjustaPro, nAuxH, 678, nAuxH + aTamCol[12])
oDanfe:Say(450+nAjustaPro, nAuxH + 2, "V.IPI", oFont08N:oFont)
nAuxH += aTamCol[12]
oDanfe:Box(442+nAjustaPro, nAuxH, 678, nAuxH + aTamCol[13])
oDanfe:Say(450+nAjustaPro, nAuxH + 2, "A.ICMS", oFont08N:oFont)
nAuxH += aTamCol[13]
oDanfe:Box(442+nAjustaPro, nAuxH, 678, nAuxH + aTamCol[14])
oDanfe:Say(450+nAjustaPro, nAuxH + 2, "A.IPI", oFont08N:oFont)

// INICIANDO INFORMAÇÕES PARA O CABEÇALHO DA PAGINA 2
nLinha	:= 460+nAjustaPro
nL	:= 0
lFlag	:= .T.

For nY := 1 To nLenItens
	nL++
	nLin:= 741
	nCont := 0

	If lflag
		If nL > nMaxItemP2
			oDanfe:EndPage()
			oDanfe:StartPage()
			nLinhavers := 0
			nLinha    	:=	181 + IIf(nFolha >=3 ,0, nLinhavers)

			oDanfe:Box(000+nLinhavers,000,095+nLinhavers,250)
			oDanfe:Say(010+nLinhavers,096, "Identificação do emitente",oFont12N:oFont)

			nLinCalc	:=	023 + nLinhavers
			cStrAux		:=	AllTrim(NoChar(oEmitente:_xNome:Text,lConverte))
			nForTo		:=	Len(cStrAux)/24
			nForTo		:=	IIf(nForTo>Round(nForTo,0),Round(nForTo,0)+1,Round(nForTo,0))
			For nX := 1 To nForTo
				oDanfe:Say(nLinCalc,096,SubStr(cStrAux,IIf(nX==1,1,((nX-1)*24)+1),24), ValidDanfe(oDanfe:nDevice) )
				nLinCalc+=10
			Next nX

			cStrAux		:=	AllTrim(NoChar(oEmitente:_EnderEmit:_xLgr:Text,lConverte))+", "+AllTrim(oEmitente:_EnderEmit:_Nro:Text)
			nForTo		:=	Len(cStrAux)/40
			nForTo		+=	IIf(nForTo>Round(nForTo,0),Round(nForTo,0)+1-nForTo,nForTo)
			For nX := 1 To nForTo
				oDanfe:Say(nLinCalc,098,SubStr(cStrAux,IIf(nX==1,1,((nX-1)*40)+1),40),oFont08N:oFont)
				nLinCalc+=10
			Next nX

			If ValAtrib("oEmitente:_EnderEmit:_xCpl") <> "U"
				cStrAux		:=	"Complemento: "+AllTrim(NoChar(oEmitente:_EnderEmit:_xCpl:TEXT,lConverte))
				nForTo		:=	Len(cStrAux)/40
				nForTo		+=	IIf(nForTo>Round(nForTo,0),Round(nForTo,0)+1-nForTo,nForTo)
				For nX := 1 To nForTo
					oDanfe:Say(nLinCalc,098,SubStr(cStrAux,IIf(nX==1,1,((nX-1)*40)+1),40),oFont08N:oFont)
					nLinCalc+=10
				Next nX

				cStrAux		:=	AllTrim(NoChar(oEmitente:_EnderEmit:_xBairro:Text,lConverte))
				If ValAtrib("oEmitente:_EnderEmit:_Cep")<>"U"
					cStrAux		+=	" Cep:"+TransForm(oEmitente:_EnderEmit:_Cep:Text,"@r 99999-999")
				EndIf
				nForTo		:=	Len(cStrAux)/40
				nForTo		+=	IIf(nForTo>Round(nForTo,0),Round(nForTo,0)+1-nForTo,nForTo)
				For nX := 1 To nForTo
					oDanfe:Say(nLinCalc,098,SubStr(cStrAux,IIf(nX==1,1,((nX-1)*40)+1),40),oFont08N:oFont)
					nLinCalc+=10
				Next nX
				oDanfe:Say(nLinCalc,098, oEmitente:_EnderEmit:_xMun:Text+"/"+oEmitente:_EnderEmit:_UF:Text,oFont08N:oFont)
				nLinCalc+=9
				oDanfe:Say(nLinCalc,098, "Fone: "+IIf(ValAtrib("oEmitente:_EnderEmit:_Fone")=="U","",oEmitente:_EnderEmit:_Fone:Text),oFont08N:oFont)
			Else
				oDanfe:Say(nLinCalc,098, NoChar(oEmitente:_EnderEmit:_xBairro:Text,lConverte)+" Cep:"+TransForm(IIf(ValAtrib("oEmitente:_EnderEmit:_Cep")=="U","",oEmitente:_EnderEmit:_Cep:Text),"@r 99999-999"),oFont08N:oFont)
				nLinCalc+=10
				oDanfe:Say(nLinCalc,098, oEmitente:_EnderEmit:_xMun:Text+"/"+oEmitente:_EnderEmit:_UF:Text,oFont08N:oFont)
				nLinCalc+=9
				oDanfe:Say(nLinCalc,098, "Fone: "+IIf(ValAtrib("oEmitente:_EnderEmit:_Fone")=="U","",oEmitente:_EnderEmit:_Fone:Text),oFont08N:oFont)
			EndIf

			oDanfe:Box(000+nLinhavers,248,095+nLinhavers,351)
			If oDanfe:nDevice == 2
				oDanfe:Say(013+nLinhavers,275, "DANFE",oFont12N:oFont)
			Else
				oDanfe:Say(013+nLinhavers,275, "DANFE",oFont18N:oFont)
			EndIf
			
			oDanfe:Say(023+nLinhavers,255, "DOCUMENTO AUXILIAR DA",oFont07:oFont)
			If lNFCE
				oDanfe:Say(033+nLinhavers,255, "NOTA FISCAL DE CONSUMIDOR",oFont07:oFont)
			Else
				oDanfe:Say(033+nLinhavers,255, "NOTA FISCAL ELETRÔNICA",oFont07:oFont)
			EndIf
			oDanfe:Say(043+nLinhavers,255, "0-ENTRADA",oFont08:oFont)
			oDanfe:Say(053+nLinhavers,255, "1-SAÍDA"  ,oFont08:oFont)
			oDanfe:Box(037+nLinhavers,305,047+nLinhavers,315)
			oDanfe:Say(045+nLinhavers,307, oIdent:_TpNf:Text,oFont08N:oFont)
			oDanfe:Say(062+nLinhavers,255,"N. "+StrZero(Val(oIdent:_NNf:Text),9),oFont10N:oFont)
			oDanfe:Say(072+nLinhavers,255,"SÉRIE "+SubStr(oIdent:_Serie:Text,1,3),oFont10N:oFont)
			oDanfe:Say(082+nLinhavers,255,"FOLHA "+StrZero(nFolha,2)+"/"+StrZero(nFolhas,2),oFont10N:oFont)

			oDanfe:Box(000+nLinhavers,350,095+nLinhavers,603)
			oDanfe:Box(000+nLinhavers,350,040+nLinhavers,603)
			oDanfe:Box(040+nLinhavers,350,062+nLinhavers,603)
			oDanfe:Box(063+nLinhavers,350,095+nLinhavers,603)
			If oDanfe:nDevice == 2
				oDanfe:Say(058+nLinhavers,355,TransForm(SubStr(oNF:_InfNfe:_ID:Text,4),"@r 9999 9999 9999 9999 9999 9999 9999 9999 9999 9999 9999"),oFont09N:oFont)
				oDanfe:Say(048+nLinhavers,355,"CHAVE DE ACESSO DA "+IIf(lNFCE,"NFC-E","NF-E"),oFont09:oFont)
			Else
				oDanfe:Say(058+nLinhavers,355,TransForm(SubStr(oNF:_InfNfe:_ID:Text,4),"@r 9999 9999 9999 9999 9999 9999 9999 9999 9999 9999 9999"),oFont12N:oFont)
				oDanfe:Say(048+nLinhavers,355,"CHAVE DE ACESSO DA "+IIf(lNFCE,"NFC-E","NF-E"),oFont12N:oFont)
			EndIf
			
			nFontSize := 28		
			
			oDanfe:Code128C(036+nLinhavers,370,SubStr(oNF:_InfNfe:_ID:Text,4), nFontSize )

			If Empty(cChaveCont)
				If oDanfe:nDevice == 2
					oDanfe:Say(075+nLinhavers,355,"Consulta de autenticidade no portal nacional da "+IIf(lNFCE,"NFC-e","NF-e"),oFont09N:oFont)
					oDanfe:Say(085+nLinhavers,355,"www.nfe.fazenda.gov.br/portal ou no site da SEFAZ Autorizada",oFont09:oFont)
				Else
					oDanfe:Say(075+nLinhavers,355,"Consulta de autenticidade no portal nacional da "+IIf(lNFCE,"NFC-e","NF-e"),oFont12:oFont)
					oDanfe:Say(085+nLinhavers,355,"www.nfe.fazenda.gov.br/portal ou no site da SEFAZ Autorizada",oFont12:oFont)
				EndIf
			EndIf

			// inicio do segundo codigo de barras ref. a transmissao CONTIGENCIA OFF Line
			If !Empty(cChaveCont) .And. !(Val(SubStr(oNF:_INFNFE:_IDE:_SERIE:TEXT,1,3)) >= 900)
				If nFolha == 1
					If !Empty(cChaveCont)
						nFontSize := 28
						oDanfe:Code128C(093+nLinhavers,370,cChaveCont, nFontSize )
					EndIf
				Else
					If !Empty(cChaveCont)
						nFontSize := 28
						oDanfe:Code128C(093+nLinhavers,370,cChaveCont, nFontSize )
					EndIf
				EndIf
			EndIf

			oDanfe:Box(100+nLinhavers,000,123+nLinhavers,603)
			oDanfe:Box(100+nLinhavers,000,123+nLinhavers,300)
			oDanfe:Say(109+nLinhavers,002,"NATUREZA DA OPERAÇÃO",oFont08N:oFont)
			oDanfe:Say(119+nLinhavers,002,oIdent:_NATOP:TEXT,oFont08:oFont)			
			If(((Val(SubStr(oNF:_INFNFE:_IDE:_SERIE:TEXT,1,3)) >= 900).And.(oNFe:_NFE:_INFNFE:_IDE:_TPEMIS:TEXT)$"2") .Or. (oNFe:_NFE:_INFNFE:_IDE:_TPEMIS:TEXT)$"1")
				oDanfe:Say(109+nLinhavers,302,"PROTOCOLO DE AUTORIZAÇÃO DE USO",oFont08N:oFont)
			EndIf
			If((oNFe:_NFE:_INFNFE:_IDE:_TPEMIS:TEXT)$"25")
				oDanfe:Say(109+nLinhavers,300,"DADOS DA "+IIf(lNFCE,"NFC-E","NF-E"),oFont08N:oFont)
			EndIf
			oDanfe:Say(119+nLinhavers,302,cDadosProt,oFont08:oFont)

			nFolha++

			oDanfe:Box(126+nLinhavers,000,153+nLinhavers,603)
			oDanfe:Box(126+nLinhavers,000,153+nLinhavers,200)
			oDanfe:Box(126+nLinhavers,200,153+nLinhavers,400)
			oDanfe:Box(126+nLinhavers,400,153+nLinhavers,603)
			oDanfe:Say(135+nLinhavers,002,"INSCRIÇÃO ESTADUAL",oFont08N:oFont)
			oDanfe:Say(143+nLinhavers,002,IIf(ValAtrib("oEmitente:_IE:TEXT")<>"U",oEmitente:_IE:TEXT,""),oFont08:oFont)
			oDanfe:Say(135+nLinhavers,205,"INSC.ESTADUAL DO SUBST.TRIB.",oFont08N:oFont)
			oDanfe:Say(143+nLinhavers,205,IIf(ValAtrib("oEmitente:_IEST:TEXT")<>"U",oEmitente:_IEST:TEXT,""),oFont08:oFont)
			oDanfe:Say(135+nLinhavers,405,"CNPJ/CPF",oFont08N:oFont)
			Do Case
				Case ValAtrib("oEmitente:_CNPJ")=="O"
					cAux := TransForm(oEmitente:_CNPJ:TEXT,"@R! NN.NNN.NNN/NNNN-99")
				Case ValAtrib("oEmitente:_CPF")=="O"
					cAux := TransForm(oEmitente:_CPF:TEXT,"@r 999.999.999-99")
				OtherWise
					cAux := Space(14)
			EndCase

			oDanfe:Say(143+nLinhavers,405,cAux,oFont08:oFont)
			nLenMensagens:= Len(aMensagem)

			nColLim		:=	IIf(nMensagem <= nLenMensagens,680,865) + nLinhavers
			oDanfe:Say(161+nLinhavers,002,"DADOS DO PRODUTO / SERVIÇO",oFont08N:oFont)
			oDanfe:Box(163+nLinhavers,000,nColLim,603)

			nAuxH := 0
			oDanfe:Box(163+nLinhavers, nAuxH, nColLim, nAuxH + aTamCol[1])
			oDanfe:Say(171+nLinhavers, nAuxH + 2, "COD. PROD",oFont08N:oFont)
			nAuxH += aTamCol[1]
			oDanfe:Box(163+nLinhavers, nAuxH, nColLim, nAuxH + aTamCol[2])
			oDanfe:Say(171+nLinhavers, nAuxH + 2, "DESCRIÇÃO DO PROD./SERV.", oFont08N:oFont)
			nAuxH += aTamCol[2]
			oDanfe:Box(163+nLinhavers, nAuxH, nColLim, nAuxH + aTamCol[3])
			oDanfe:Say(171+nLinhavers, nAuxH + 2, "NCM/SH", oFont08N:oFont)
			nAuxH += aTamCol[3]
			oDanfe:Box(163+nLinhavers, nAuxH, nColLim, nAuxH + aTamCol[4])
			If cMVCODREG == "1"
				oDanfe:Say(171+nLinhavers, nAuxH + 2, "CSOSN", oFont08N:oFont)
			Else
				oDanfe:Say(171+nLinhavers, nAuxH + 2, "CST", oFont08N:oFont)
			EndIf
			nAuxH += aTamCol[4]
			oDanfe:Box(163+nLinhavers, nAuxH, nColLim, nAuxH + aTamCol[5])
			oDanfe:Say(171+nLinhavers, nAuxH + 2, "CFOP", oFont08N:oFont)
			nAuxH += aTamCol[5]
			oDanfe:Box(163+nLinhavers, nAuxH, nColLim, nAuxH + aTamCol[6])
			oDanfe:Say(171+nLinhavers, nAuxH + 2, "UN", oFont08N:oFont)
			nAuxH += aTamCol[6]
			oDanfe:Box(163+nLinhavers, nAuxH, nColLim, nAuxH + aTamCol[7])
			oDanfe:Say(171+nLinhavers, nAuxH + 2, "QUANT.", oFont08N:oFont)
			nAuxH += aTamCol[7]
			oDanfe:Box(163+nLinhavers, nAuxH, nColLim, nAuxH + aTamCol[8])
			oDanfe:Say(171+nLinhavers, nAuxH + 2, "V.UNITARIO", oFont08N:oFont)
			nAuxH += aTamCol[8]
			oDanfe:Box(163+nLinhavers, nAuxH, nColLim, nAuxH + aTamCol[9])
			oDanfe:Say(171+nLinhavers, nAuxH + 2, "V.TOTAL", oFont08N:oFont)
			nAuxH += aTamCol[9]
			oDanfe:Box(163+nLinhavers, nAuxH, nColLim, nAuxH + aTamCol[10])
			oDanfe:Say(171+nLinhavers, nAuxH + 2, "BC.ICMS", oFont08N:oFont)
			nAuxH += aTamCol[10]
			oDanfe:Box(163+nLinhavers, nAuxH, nColLim, nAuxH + aTamCol[11])
			oDanfe:Say(171+nLinhavers, nAuxH + 2, "V.ICMS", oFont08N:oFont)
			nAuxH += aTamCol[11]
			oDanfe:Box(163+nLinhavers, nAuxH, nColLim, nAuxH + aTamCol[12])
			oDanfe:Say(171+nLinhavers, nAuxH + 2, "V.IPI", oFont08N:oFont)
			nAuxH += aTamCol[12]
			oDanfe:Box(163+nLinhavers, nAuxH, nColLim, nAuxH + aTamCol[13])
			oDanfe:Say(171+nLinhavers, nAuxH + 2, "A.ICMS", oFont08N:oFont)
			nAuxH += aTamCol[13]
			oDanfe:Box(163+nLinhavers, nAuxH, nColLim, nAuxH + aTamCol[14])
			oDanfe:Say(171+nLinhavers, nAuxH + 2, "A.IPI", oFont08N:oFont)

			// FINALIZANDO INFORMAÇÕES PARA O CABEÇALHO DA PAGINA 2
			nL	:= 1
			lFlag	:= .F.

			//Verifico se ainda existem Dados Adicionais a serem impressos
			If nMensagem <= nLenMensagens
				//Dados Adicionais
				oDanfe:Say(719+nLinhavers,000,"DADOS ADICIONAIS",oFont08N:oFont)
				oDanfe:Box(721+nLinhavers,000,865+nLinhavers,351)
				oDanfe:Say(729+nLinhavers,002,"INFORMAÇÕES COMPLEMENTARES",oFont08N:oFont)

				nLin:= 741
				nLenMensagens:= Len(aMensagem)
				--nMensagem
				For nX := 1 To Min(nLenMensagens - nMensagem, MAXMSG)
					If aMensagem[nMensagem+nX][2]
						oDanfe:Say( nLin, 002, aMensagem[nMensagem+nX][1], oFont08N:oFont )
					Else
						oDanfe:Say( nLin, 002, aMensagem[nMensagem+nX][1], oFont08:oFont )
					EndIf
					nLin:= nLin+10
				Next nX
				nMensagem := nMensagem+nX

				oDanfe:Box(721+nLinhavers,350,865+nLinhavers,603)
				oDanfe:Say(729+nLinhavers,352,"RESERVADO AO FISCO",oFont08N:oFont)

				//Logotipo Rodape
				If file(cLogoTotvs) .Or. Resource2File ( cLogoTotvs, cStartPath+cLogoTotvs )
					oDanfe:SayBitmap(866,484,cLogoTotvs,120,20)
				EndIf

				// Seta o máximo de itens para o MAXITEMP2
				nMaxItemP2 := MAXITEMP2
			EndIf
		EndIf
	EndIf

	// INICIANDO INFORMAÇÕES PARA O CABEÇALHO DA PAGINA 3 E DIANTE
	If	nL > nMaxItemP2
		oDanfe:EndPage()
		oDanfe:StartPage()
		nLenMensagens:= Len(aMensagem)
		nColLim		:=	IIf(nMensagem <= nLenMensagens,680,865)
		lFimpar		:=  ((nfolha-1)%2==0)
		nLinha    	:=	181
		If nfolha >= 3
			nLinhavers := 0
		EndIf
		oDanfe:Box(000,000,095,250)
		oDanfe:Say(010,096, "Identificação do emitente",oFont12N:oFont)
		nLinCalc	:=	023
		cStrAux		:=	AllTrim(NoChar(oEmitente:_xNome:Text,lConverte))
		nForTo		:=	Len(cStrAux)/24
		nForTo		:=	IIf(nForTo>Round(nForTo,0),Round(nForTo,0)+1,Round(nForTo,0))
		For nX := 1 To nForTo
			oDanfe:Say(nLinCalc,096,SubStr(cStrAux,IIf(nX==1,1,((nX-1)*24)+1),24), ValidDanfe(oDanfe:nDevice) )
			nLinCalc+=10
		Next nX

		cStrAux		:=	AllTrim(NoChar(oEmitente:_EnderEmit:_xLgr:Text,lConverte))+", "+AllTrim(oEmitente:_EnderEmit:_Nro:Text)
		nForTo		:=	Len(cStrAux)/40
		nForTo		+=	IIf(nForTo>Round(nForTo,0),Round(nForTo,0)+1-nForTo,nForTo)
		For nX := 1 To nForTo
			oDanfe:Say(nLinCalc,098,SubStr(cStrAux,IIf(nX==1,1,((nX-1)*40)+1),40),oFont08N:oFont)
			nLinCalc+=10
		Next nX

		If ValAtrib("oEmitente:_EnderEmit:_xCpl") <> "U"
			cStrAux		:=	"Complemento: "+AllTrim(NoChar(oEmitente:_EnderEmit:_xCpl:TEXT,lConverte))
			nForTo		:=	Len(cStrAux)/40
			nForTo		+=	IIf(nForTo>Round(nForTo,0),Round(nForTo,0)+1-nForTo,nForTo)
			For nX := 1 To nForTo
				oDanfe:Say(nLinCalc,098,SubStr(cStrAux,IIf(nX==1,1,((nX-1)*40)+1),40),oFont08N:oFont)
				nLinCalc+=10
			Next nX

			cStrAux		:=	AllTrim(NoChar(oEmitente:_EnderEmit:_xBairro:Text,lConverte))
			If ValAtrib("oEmitente:_EnderEmit:_Cep")<>"U"
				cStrAux		+=	" Cep:"+TransForm(oEmitente:_EnderEmit:_Cep:Text,"@r 99999-999")
			EndIf
			nForTo		:=	Len(cStrAux)/40
			nForTo		+=	IIf(nForTo>Round(nForTo,0),Round(nForTo,0)+1-nForTo,nForTo)
			For nX := 1 To nForTo
				oDanfe:Say(nLinCalc,098,SubStr(cStrAux,IIf(nX==1,1,((nX-1)*40)+1),40),oFont08N:oFont)
				nLinCalc+=10
			Next nX
			oDanfe:Say(nLinCalc,098, oEmitente:_EnderEmit:_xMun:Text+"/"+oEmitente:_EnderEmit:_UF:Text,oFont08N:oFont)
			nLinCalc+=9
			oDanfe:Say(nLinCalc,098, "Fone: "+IIf(ValAtrib("oEmitente:_EnderEmit:_Fone")=="U","",oEmitente:_EnderEmit:_Fone:Text),oFont08N:oFont)
		Else
			oDanfe:Say(nLinCalc,098, NoChar(oEmitente:_EnderEmit:_xBairro:Text,lConverte)+" Cep:"+TransForm(IIf(ValAtrib("oEmitente:_EnderEmit:_Cep")=="U","",oEmitente:_EnderEmit:_Cep:Text),"@r 99999-999"),oFont08N:oFont)
			nLinCalc+=10
			oDanfe:Say(nLinCalc,098, oEmitente:_EnderEmit:_xMun:Text+"/"+oEmitente:_EnderEmit:_UF:Text,oFont08N:oFont)
			nLinCalc+=9
			oDanfe:Say(nLinCalc,098, "Fone: "+IIf(ValAtrib("oEmitente:_EnderEmit:_Fone")=="U","",oEmitente:_EnderEmit:_Fone:Text),oFont08N:oFont)
		EndIf

		oDanfe:Box(000,248,095,351)
		If oDanfe:nDevice == 2
			oDanfe:Say(013,275, "DANFE",oFont12N:oFont)
		Else
			oDanfe:Say(013,275, "DANFE",oFont18N:oFont)
		EndIf
		
		oDanfe:Say(023,255, "DOCUMENTO AUXILIAR DA",oFont07:oFont)

		If lNFCE
			oDanfe:Say(033,255, "NOTA FISCAL DE CONSUMIDOR",oFont07:oFont)
		Else
			oDanfe:Say(033,255, "NOTA FISCAL ELETRÔNICA",oFont07:oFont)
		EndIf
		oDanfe:Say(043,255, "0-ENTRADA",oFont08:oFont)
		oDanfe:Say(053,255, "1-SAÍDA"  ,oFont08:oFont)
		oDanfe:Box(037,305,047,315)
		oDanfe:Say(045,307, oIdent:_TpNf:Text,oFont08N:oFont)
		oDanfe:Say(062,255,"N. "+StrZero(Val(oIdent:_NNf:Text),9),oFont10N:oFont)
		oDanfe:Say(072,255,"SÉRIE "+SubStr(oIdent:_Serie:Text,1,3),oFont10N:oFont)
		oDanfe:Say(082,255,"FOLHA "+StrZero(nFolha,2)+"/"+StrZero(nFolhas,2),oFont10N:oFont)

		oDanfe:Box(000,350,095,603)
		oDanfe:Box(000,350,040,603)
		oDanfe:Box(040,350,062,603)
		oDanfe:Box(063,350,095,603)
		If oDanfe:nDevice == 2
			oDanfe:Say(058,355,TransForm(SubStr(oNF:_InfNfe:_ID:Text,4),"@r 9999 9999 9999 9999 9999 9999 9999 9999 9999 9999 9999"),oFont09N:oFont)
			oDanfe:Say(048,355,"CHAVE DE ACESSO DA "+IIf(lNFCE,"NFC-E","NF-E"),oFont09:oFont)
		Else
			oDanfe:Say(058,355,TransForm(SubStr(oNF:_InfNfe:_ID:Text,4),"@r 9999 9999 9999 9999 9999 9999 9999 9999 9999 9999 9999"),oFont12N:oFont)
			oDanfe:Say(048,355,"CHAVE DE ACESSO DA "+IIf(lNFCE,"NFC-E","NF-E"),oFont12N:oFont)
		EndIf
		
		nFontSize := 28
		oDanfe:Code128C(036,370,SubStr(oNF:_InfNfe:_ID:Text,4), nFontSize )

		If Empty(cChaveCont)
			oDanfe:Say(075,355,"Consulta de autenticidade no portal nacional da "+IIf(lNFCE,"NFC-e","NF-e"),oFont09N:oFont)
			oDanfe:Say(085,355,"www.nfe.fazenda.gov.br/portal ou no site da SEFAZ Autorizada",oFont09:oFont)
		EndIf

		// inicio do segundo codigo de barras ref. a transmissao CONTIGENCIA OFF Line
		If !Empty(cChaveCont) .And. !(Val(SubStr(oNF:_INFNFE:_IDE:_SERIE:TEXT,1,3)) >= 900)
			If nFolha == 1
				If !Empty(cChaveCont)
					nFontSize := 28
					oDanfe:Code128C(093,370,cChaveCont, nFontSize )
				EndIf
			Else
				If !Empty(cChaveCont)
					nFontSize := 28
					oDanfe:Code128C(093,370,cChaveCont, nFontSize )
				EndIf
			EndIf
		EndIf

		oDanfe:Box(100,000,123,603)
		oDanfe:Box(100,000,123,300)
		oDanfe:Say(109,002,"NATUREZA DA OPERAÇÃO",oFont08N:oFont)
		oDanfe:Say(119,002,oIdent:_NATOP:TEXT,oFont08:oFont)
		If(((Val(SubStr(oNF:_INFNFE:_IDE:_SERIE:TEXT,1,3)) >= 900).And.(oNFe:_NFE:_INFNFE:_IDE:_TPEMIS:TEXT)$"2") .Or. (oNFe:_NFE:_INFNFE:_IDE:_TPEMIS:TEXT)$"1")
			oDanfe:Say(109,302,"PROTOCOLO DE AUTORIZAÇÃO DE USO",oFont08N:oFont)
		EndIf
		If((oNFe:_NFE:_INFNFE:_IDE:_TPEMIS:TEXT)$"25")
			oDanfe:Say(109,300,"DADOS DA "+IIf(lNFCE,"NFC-E","NF-E"),oFont08N:oFont)
		EndIf
		oDanfe:Say(119,302,cDadosProt,oFont08:oFont)
		nFolha++

		oDanfe:Box(126,000,153,603)
		oDanfe:Box(126,000,153,200)
		oDanfe:Box(126,200,153,400)
		oDanfe:Box(126,400,153,603)
		oDanfe:Say(135,002,"INSCRIÇÃO ESTADUAL",oFont08N:oFont)
		oDanfe:Say(143,002,IIf(ValAtrib("oEmitente:_IE:TEXT")<>"U",oEmitente:_IE:TEXT,""),oFont08:oFont)
		oDanfe:Say(135,205,"INSC.ESTADUAL DO SUBST.TRIB.",oFont08N:oFont)
		oDanfe:Say(143,205,IIf(ValAtrib("oEmitente:_IEST:TEXT")<>"U",oEmitente:_IEST:TEXT,""),oFont08:oFont)
		oDanfe:Say(135,405,"CNPJ/CPF",oFont08N:oFont)
		Do Case
			Case ValAtrib("oEmitente:_CNPJ")=="O"
				cAux := TransForm(oEmitente:_CNPJ:TEXT,"@R! NN.NNN.NNN/NNNN-99")
			Case ValAtrib("oEmitente:_CPF")=="O"
				cAux := TransForm(oEmitente:_CPF:TEXT,"@r 999.999.999-99")
			OtherWise
				cAux := Space(14)
		EndCase

  		oDanfe:Say(143,405,cAux,oFont08:oFont)
		oDanfe:Say(161,002,"DADOS DO PRODUTO / SERVIÇO",oFont08N:oFont)
		oDanfe:Box(163,000,nColLim,603)

		nAuxH := 0
		oDanfe:Box(163, nAuxH, nColLim, nAuxH + aTamCol[1])
		oDanfe:Say(171, nAuxH + 2, "COD. PROD",oFont08N:oFont)
		nAuxH += aTamCol[1]
		oDanfe:Box(163, nAuxH, nColLim, nAuxH + aTamCol[2])
		oDanfe:Say(171, nAuxH + 2, "DESCRIÇÃO DO PROD./SERV.", oFont08N:oFont)
		nAuxH += aTamCol[2]
		oDanfe:Box(163, nAuxH, nColLim, nAuxH + aTamCol[3])
		oDanfe:Say(171, nAuxH + 2, "NCM/SH", oFont08N:oFont)
		nAuxH += aTamCol[3]
		oDanfe:Box(163, nAuxH, nColLim, nAuxH + aTamCol[4])
		If cMVCODREG == "1"
			oDanfe:Say(171, nAuxH + 2, "CSOSN", oFont08N:oFont)
		Else
			oDanfe:Say(171, nAuxH + 2, "CST", oFont08N:oFont)
		EndIf
		nAuxH += aTamCol[4]
		oDanfe:Box(163, nAuxH, nColLim, nAuxH + aTamCol[5])
		oDanfe:Say(171, nAuxH + 2, "CFOP", oFont08N:oFont)
		nAuxH += aTamCol[5]
		oDanfe:Box(163, nAuxH, nColLim, nAuxH + aTamCol[6])
		oDanfe:Say(171, nAuxH + 2, "UN", oFont08N:oFont)
		nAuxH += aTamCol[6]
		oDanfe:Box(163, nAuxH, nColLim, nAuxH + aTamCol[7])
		oDanfe:Say(171, nAuxH + 2, "QUANT.", oFont08N:oFont)
		nAuxH += aTamCol[7]
		oDanfe:Box(163, nAuxH, nColLim, nAuxH + aTamCol[8])
		oDanfe:Say(171, nAuxH + 2, "V.UNITARIO", oFont08N:oFont)
		nAuxH += aTamCol[8]
		oDanfe:Box(163, nAuxH, nColLim, nAuxH + aTamCol[9])
		oDanfe:Say(171, nAuxH + 2, "V.TOTAL", oFont08N:oFont)
		nAuxH += aTamCol[9]
		oDanfe:Box(163, nAuxH, nColLim, nAuxH + aTamCol[10])
		oDanfe:Say(171, nAuxH + 2, "BC.ICMS", oFont08N:oFont)
		nAuxH += aTamCol[10]
		oDanfe:Box(163, nAuxH, nColLim, nAuxH + aTamCol[11])
		oDanfe:Say(171, nAuxH + 2, "V.ICMS", oFont08N:oFont)
		nAuxH += aTamCol[11]
		oDanfe:Box(163, nAuxH, nColLim, nAuxH + aTamCol[12])
		oDanfe:Say(171, nAuxH + 2, "V.IPI", oFont08N:oFont)
		nAuxH += aTamCol[12]
		oDanfe:Box(163, nAuxH, nColLim, nAuxH + aTamCol[13])
		oDanfe:Say(171, nAuxH + 2, "A.ICMS", oFont08N:oFont)
		nAuxH += aTamCol[13]
		oDanfe:Box(163, nAuxH, nColLim, nAuxH + aTamCol[14])
		oDanfe:Say(171, nAuxH + 2, "A.IPI", oFont08N:oFont)

		//Verifico se ainda existem Dados Adicionais a serem impressos
		nLenMensagens:= Len(aMensagem)
		If nMensagem <= nLenMensagens
			//========================================================================
			//Dados Adicionais
			//========================================================================
			oDanfe:Say(719,000,"DADOS ADICIONAIS",oFont08N:oFont)
			oDanfe:Box(721,000,865,351)
			oDanfe:Say(729,002,"INFORMAÇÕES COMPLEMENTARES",oFont08N:oFont)

			nLin:= 741
			nLenMensagens:= Len(aMensagem)
			--nMensagem
			For nX := 1 To Min(nLenMensagens - nMensagem, MAXMSG)
				If aMensagem[nMensagem+nX][2]
					oDanfe:Say( nLin, 002, aMensagem[nMensagem+nX][1], oFont08N:oFont )
				Else
					oDanfe:Say( nLin, 002, aMensagem[nMensagem+nX][1], oFont08:oFont )
				EndIf
				nLin:= nLin+10
			Next nX
			nMensagem := nMensagem+nX

			oDanfe:Box(721+nLinhavers,350,865+nLinhavers,603)
			oDanfe:Say(729+nLinhavers,352,"RESERVADO AO FISCO",oFont08N:oFont)

			//========================================================================
			//Logotipo Rodape
			//========================================================================
			If file(cLogoTotvs) .Or. Resource2File ( cLogoTotvs, cStartPath+cLogoTotvs )
				oDanfe:SayBitmap(866,484,cLogoTotvs,120,20)
			EndIf

			// Seta o máximo de itens para o MAXITEMP2
			nMaxItemP2 := MAXITEMP2
		Else
			// Seta o máximo de itens para o MAXITEMP2F
			nMaxItemP2 := MAXITEMP2F
		EndIf
		
		nL := 1
	EndIf

	nAuxH := 0

	If aAux[1][1][nY] == "-"
		If oDanfe:nDevice == 2
			oDanfe:Say(nLinha, nAuxH, Replicate("- ", 155), oFont07:oFont)
		Else
			oDanfe:Say(nLinha, nAuxH, Replicate("- ", 150), oFont08:oFont)
		EndIf
	Else
		oDanfe:Say(nLinha, nAuxH + 2, aAux[1][1][nY], oFont08:oFont )
		nAuxH += aTamCol[1]
		If aAux[1][2][nY][2]
			oDanfe:Say(nLinha, nAuxH + 2, NoChar(aAux[1][2][nY][1], lConverte), oFont08N:oFont) // COD ONU DESTACADO EM NEGRITO
		Else
			oDanfe:Say(nLinha, nAuxH + 2, NoChar(aAux[1][2][nY][1], lConverte), oFont08:oFont) // DESCRICAO DO PRODUTO
		EndIf
		nAuxH += aTamCol[2]
		oDanfe:Say(nLinha, nAuxH + 2, aAux[1][3][nY], oFont08:oFont) // NCM
		nAuxH += aTamCol[3]
		oDanfe:Say(nLinha, nAuxH + 2, aAux[1][4][nY], oFont08:oFont) // CST
		nAuxH += aTamCol[4]	
		oDanfe:Say(nLinha, nAuxH + 2, aAux[1][5][nY], oFont08:oFont) // CFOP
		nAuxH += aTamCol[5]
		oDanfe:Say(nLinha, nAuxH + 2, aAux[1][6][nY], oFont08:oFont) // UN
		nAuxH += aTamCol[6]
		// Workaround para falha no FWMSPrinter:GetTextWidth()

		nAuxH2 := Len(aAux[1][7][nY]) + (nAuxH + (aTamCol[7]) - RetTamTex(aAux[1][7][nY], oFont08:oFont, oDanfe))
		oDanfe:Say(nLinha, nAuxH2, aAux[1][7][nY], oFont08:oFont) // QUANT
		nAuxH += aTamCol[7]

		nAuxH2 := Len(aAux[1][8][nY]) + (nAuxH + (aTamCol[8]) - RetTamTex(aAux[1][8][nY], oFont08:oFont, oDanfe))
		oDanfe:Say(nLinha, nAuxH2, aAux[1][8][nY], oFont08:oFont) // V UNITARIO
		nAuxH += aTamCol[8]

		nAuxH2 := Len(aAux[1][9][nY]) + (nAuxH + (aTamCol[9]) - RetTamTex(aAux[1][9][nY], oFont08:oFont, oDanfe))
		oDanfe:Say(nLinha, nAuxH2, aAux[1][9][nY], oFont08:oFont) // V. TOTAL
		nAuxH += aTamCol[9]

		nAuxH2 := Len(aAux[1][10][nY]) + (nAuxH + (aTamCol[10]) - RetTamTex(aAux[1][10][nY], oFont08:oFont, oDanfe))
		oDanfe:Say(nLinha, nAuxH2, aAux[1][10][nY], oFont08:oFont) // BC. ICMS
		nAuxH += aTamCol[10]

		nAuxH2 := Len(aAux[1][11][nY]) + (nAuxH + (aTamCol[11]) - RetTamTex(aAux[1][11][nY], oFont08:oFont, oDanfe))
		oDanfe:Say(nLinha, nAuxH2, aAux[1][11][nY], oFont08:oFont) // V. ICMS
		nAuxH += aTamCol[11]

		nAuxH2 := Len(aAux[1][12][nY]) + (nAuxH + (aTamCol[12]) - RetTamTex(aAux[1][12][nY], oFont08:oFont, oDanfe))
		oDanfe:Say(nLinha, nAuxH2, aAux[1][12][nY], oFont08:oFont) // V.IPI
		nAuxH += aTamCol[12]

		nAuxH2 := Len(aAux[1][13][nY]) + (nAuxH + (aTamCol[13]) - RetTamTex(aAux[1][13][nY], oFont08:oFont, oDanfe))
		oDanfe:Say(nLinha, nAuxH2, aAux[1][13][nY], oFont08:oFont) // A.ICMS
		nAuxH += aTamCol[13]

		nAuxH2 := Len(aAux[1][14][nY]) + (nAuxH + (aTamCol[14]) - RetTamTex(aAux[1][14][nY], oFont08:oFont, oDanfe))
		oDanfe:Say(nLinha, nAuxH2, aAux[1][14][nY], oFont08:oFont) // A.IPI
	EndIf

	nLinha :=nLinha + 10
Next nY

nLenMensagens := Len(aMensagem)
While nMensagem <= nLenMensagens
	DanfeCpl(oDanfe,aItens,aMensagem,@nItem,@nMensagem,oNFe,oIdent,oEmitente,@nFolha,nFolhas,aUF,cDadosProt)
EndDo

oDanfe:EndPage()

Return(.T.)

/*
Private oNF        := oNFe:_NFe
*/
//Impressao do Complemento da NFe
Static Function DanfeCpl(oDanfe,aItens,aMensagem,nItem,nMensagem,oNFe,oIdent,oEmitente,nFolha,nFolhas,aUF,cDadosProt)

Local nX            := 0
Local nLinha        := 0
Local nLenMensagens := Len(aMensagem)
Local nItemOld	    := nItem
Local nMensagemOld  := nMensagem
Local nForMensagens := 0
Local lMensagens    := .F.
Local cChaveCont 	:= ""
Local lConverte     := GetNewPar("MV_CONVERT",.F.)
Local cCNPJCPF 		:=  ""
Local cUF      		:=  ""
Local cDataEmi 		:=  ""
Local cTPEmis  		:=  ""
Local cValIcm  		:=  ""
Local cICMSp   		:=  ""
Local cICMSs   		:=  ""
Local cLogoTotvs 	:= "Powered_by_TOTVS.bmp"
Local cStartPath 	:= GetSrvProfString("Startpath","")
Local lNFCE 		:= SubStr(oNFe:_NFe:_InfNfe:_ID:Text,24,2) == "65"

If (nLenMensagens - (nMensagemOld - 1)) > 0
	lMensagens := .T.
EndIf

//Dados Adicionais segunda parte em diante
If lMensagens
	nLenMensagens := Len(aMensagem)
	nForMensagens := Min(nLenMensagens, MAXITEMP2 + (nMensagemOld - 1) - (nItem - nItemOld))
	oDanfe:EndPage()
	oDanfe:StartPage()
	nLinha    :=180
	oDanfe:Say(160,000,"DADOS ADICIONAIS",oFont08N:oFont)
	oDanfe:Box(172,000,865,351)
	oDanfe:Say(170,002,"INFORMAÇÕES COMPLEMENTARES",oFont08N:oFont)
	oDanfe:Box(172,350,865,603)
	oDanfe:Say(170,352,"RESERVADO AO FISCO",oFont08N:oFont)

	//Logotipo Rodape
	If file(cLogoTotvs) .Or. Resource2File ( cLogoTotvs, cStartPath+cLogoTotvs )
		oDanfe:SayBitmap(866,484,cLogoTotvs,120,20)
	EndIf

	oDanfe:Box(000,000,095,250)
	oDanfe:Say(010,096, "Identificação do emitente",oFont12N:oFont)
	nLinCalc	:=	023
	cStrAux		:=	AllTrim(NoChar(oEmitente:_xNome:Text,lConverte))
	nForTo		:=	Len(cStrAux)/24
	nForTo		:=	IIf(nForTo>Round(nForTo,0),Round(nForTo,0)+1,Round(nForTo,0))
	For nX := 1 To nForTo
		oDanfe:Say(nLinCalc,096,SubStr(cStrAux,IIf(nX==1,1,((nX-1)*24)+1),24), ValidDanfe(oDanfe:nDevice))
		nLinCalc+=10
	Next nX

	cStrAux		:=	AllTrim(NoChar(oEmitente:_EnderEmit:_xLgr:Text,lConverte))+", "+AllTrim(oEmitente:_EnderEmit:_Nro:Text)
	nForTo		:=	Len(cStrAux)/40
	nForTo		+=	IIf(nForTo>Round(nForTo,0),Round(nForTo,0)+1-nForTo,nForTo)
	For nX := 1 To nForTo
		oDanfe:Say(nLinCalc,098,SubStr(cStrAux,IIf(nX==1,1,((nX-1)*40)+1),40),oFont08N:oFont)
		nLinCalc+=10
	Next nX

	If Type("oEmitente:_EnderEmit:_xCpl") <> "U"
		cStrAux		:=	"Complemento: "+AllTrim(NoChar(oEmitente:_EnderEmit:_xCpl:TEXT,lConverte))
		nForTo		:=	Len(cStrAux)/40
		nForTo		+=	IIf(nForTo>Round(nForTo,0),Round(nForTo,0)+1-nForTo,nForTo)
		For nX := 1 To nForTo
			oDanfe:Say(nLinCalc,098,SubStr(cStrAux,IIf(nX==1,1,((nX-1)*40)+1),40),oFont08N:oFont)
			nLinCalc+=10
		Next nX

		cStrAux		:=	AllTrim(NoChar(oEmitente:_EnderEmit:_xBairro:Text,lConverte))
		If Type("oEmitente:_EnderEmit:_Cep")<>"U"
			cStrAux		+=	" Cep:"+TransForm(oEmitente:_EnderEmit:_Cep:Text,"@r 99999-999")
		EndIf
		nForTo		:=	Len(cStrAux)/40
		nForTo		+=	IIf(nForTo>Round(nForTo,0),Round(nForTo,0)+1-nForTo,nForTo)
		For nX := 1 To nForTo
			oDanfe:Say(nLinCalc,098,SubStr(cStrAux,IIf(nX==1,1,((nX-1)*40)+1),40),oFont08N:oFont)
			nLinCalc+=10
		Next nX
		oDanfe:Say(nLinCalc,098, oEmitente:_EnderEmit:_xMun:Text+"/"+oEmitente:_EnderEmit:_UF:Text,oFont08N:oFont)
		nLinCalc+=9
		oDanfe:Say(nLinCalc,098, "Fone: "+IIf(Type("oEmitente:_EnderEmit:_Fone")=="U","",oEmitente:_EnderEmit:_Fone:Text),oFont08N:oFont)
	Else
		oDanfe:Say(nLinCalc,098, oEmitente:_EnderEmit:_xBairro:Text+" Cep:"+TransForm(IIf(Type("oEmitente:_EnderEmit:_Cep")=="U","",oEmitente:_EnderEmit:_Cep:Text),"@r 99999-999"),oFont08N:oFont)
		nLinCalc+=10
		oDanfe:Say(nLinCalc,098, oEmitente:_EnderEmit:_xMun:Text+"/"+oEmitente:_EnderEmit:_UF:Text,oFont08N:oFont)
		nLinCalc+=9
		oDanfe:Say(nLinCalc,098, "Fone: "+IIf(Type("oEmitente:_EnderEmit:_Fone")=="U","",oEmitente:_EnderEmit:_Fone:Text),oFont08N:oFont)
	EndIf

	oDanfe:Box(000,248,095,351)
	oDanfe:Say(013,275, "DANFE", oFont18N:oFont)
	oDanfe:Say(023,255, "DOCUMENTO AUXILIAR DA",oFont07:oFont)

	If lNFCE
		oDanfe:Say(033,255, "NOTA FISCAL DE CONSUMIDOR",oFont07:oFont)
	Else
		oDanfe:Say(033,255, "NOTA FISCAL ELETRÔNICA",oFont07:oFont)
	EndIf
	oDanfe:Say(043,255, "0-ENTRADA",oFont08:oFont)
	oDanfe:Say(053,255, "1-SAÍDA"  ,oFont08:oFont)
	oDanfe:Box(037,305,047,315)
	oDanfe:Say(045,307, oIdent:_TpNf:Text,oFont08N:oFont)
	oDanfe:Say(062,255,"N. "+StrZero(Val(oIdent:_NNf:Text),9),oFont10N:oFont)
	oDanfe:Say(072,255,"SÉRIE "+SubStr(oIdent:_Serie:Text,1,3),oFont10N:oFont)
	oDanfe:Say(082,255,"FOLHA "+StrZero(nFolha,2)+"/"+StrZero(nFolhas,2),oFont10N:oFont)

	oDanfe:Box(000,350,095,603)
	oDanfe:Box(000,350,040,603)
	oDanfe:Box(040,350,062,603)
	oDanfe:Box(063,350,095,603)
	oDanfe:Say(058,355,TransForm(SubStr(oNF:_InfNfe:_ID:Text,4),"@r 9999 9999 9999 9999 9999 9999 9999 9999 9999 9999 9999"),ValidDanfe(oDanfe:nDevice))
	
	oDanfe:Say(048,355,"CHAVE DE ACESSO DA "+IIf(lNFCE,"NFC-E","NF-E"),ValidDanfe(oDanfe:nDevice))
	nFontSize := 28
	oDanfe:Code128C(036,370,SubStr(oNF:_InfNfe:_ID:Text,4), nFontSize )

	If Empty(cChaveCont)
		oDanfe:Say(075,355,"Consulta de autenticidade no portal nacional da "+IIf(lNFCE,"NFC-e","NF-e"),oFont09N:oFont)
		oDanfe:Say(085,355,"www.nfe.fazenda.gov.br/portal ou no site da SEFAZ Autorizada",oFont09:oFont)
	EndIf

	// inicio do segundo codigo de barras ref. a transmissao CONTIGENCIA OFF Line
	If !Empty(cChaveCont) .And. !(Val(SubStr(oNF:_INFNFE:_IDE:_SERIE:TEXT,1,3)) >= 900)
		If nFolha == 1
			If !Empty(cChaveCont)
				nFontSize := 28
				oDanfe:Code128C(093,370,cChaveCont, nFontSize )
			EndIf
		Else
			If !Empty(cChaveCont)
				nFontSize := 28
				oDanfe:Code128C(093,370,cChaveCont, nFontSize )
			EndIf
		EndIf
	EndIf

	oDanfe:Box(100,000,123,603)
	oDanfe:Box(100,000,123,300)
	oDanfe:Say(109,002,"NATUREZA DA OPERAÇÃO",oFont08N:oFont)
	oDanfe:Say(119,002,oIdent:_NATOP:TEXT,oFont08:oFont)
	If(((Val(SubStr(oNF:_INFNFE:_IDE:_SERIE:TEXT,1,3)) >= 900).And.(oNFe:_NFE:_INFNFE:_IDE:_TPEMIS:TEXT)$"2") .Or. (oNFe:_NFE:_INFNFE:_IDE:_TPEMIS:TEXT)$"1")
		oDanfe:Say(109,302,"PROTOCOLO DE AUTORIZAÇÃO DE USO",oFont08N:oFont)
	EndIf
	If((oNFe:_NFE:_INFNFE:_IDE:_TPEMIS:TEXT)$"25")
		oDanfe:Say(109,300,"DADOS DA "+IIf(lNFCE,"NFC-E","NF-E"),oFont08N:oFont)
	EndIf

	If !Empty(cUF) .And. !Empty(cDataEmi) .And. !Empty(cTPEmis) .And. !Empty(cValIcm) .And. !Empty(cICMSp) .And. !Empty(cICMSs)
		If Type("oNF:_InfNfe:_DEST:_CNPJ:Text")<>"U"
			cCNPJCPF := oNF:_InfNfe:_DEST:_CNPJ:Text
			If cUf == "99"
				cCNPJCPF := StrZero(Val(cCNPJCPF),14)
			EndIf
		ElseIf Type("oNF:_INFNFE:_DEST:_CPF:Text")<>"U"
			cCNPJCPF := oNF:_INFNFE:_DEST:_CPF:Text
			cCNPJCPF := StrZero(Val(cCNPJCPF),14)
		Else
			cCNPJCPF := ""
		EndIf
		cChaveCont += cUF+cTPEmis+cCNPJCPF+cValIcm+cICMSp+cICMSs+cDataEmi
		cChaveCont := cChaveCont+Modulo11(cChaveCont)
	EndIf

	oDanfe:Say(119,302,cDadosProt,oFont08:oFont)
	nFolha++

	oDanfe:Box(126,000,153,603)
	oDanfe:Box(126,000,153,200)
	oDanfe:Box(126,200,153,400)
	oDanfe:Box(126,400,153,603)
	oDanfe:Say(135,002,"INSCRIÇÃO ESTADUAL",oFont08N:oFont)
	oDanfe:Say(143,002,IIf(Type("oEmitente:_IE:TEXT")<>"U",oEmitente:_IE:TEXT,""),oFont08:oFont)
	oDanfe:Say(135,205,"INSC.ESTADUAL DO SUBST.TRIB.",oFont08N:oFont)
	oDanfe:Say(143,205,IIf(Type("oEmitente:_IEST:TEXT")<>"U",oEmitente:_IEST:TEXT,""),oFont08:oFont)
	oDanfe:Say(135,405,"CNPJ/CPF",oFont08N:oFont)
	Do Case
		Case Type("oEmitente:_CNPJ")=="O"
			cAux := TransForm(oEmitente:_CNPJ:TEXT,"@R! NN.NNN.NNN/NNNN-99")
		Case Type("oEmitente:_CPF")=="O"
			cAux := TransForm(oEmitente:_CPF:TEXT,"@r 999.999.999-99")
		OtherWise
			cAux := Space(14)
	EndCase

	oDanfe:Say(143,405,cAux,oFont08:oFont)

	For nX := nMensagem To nForMensagens
		If aMensagem[nX][2]
			oDanfe:Say( nLinha, 002, aMensagem[nX][1], oFont08N:oFont )
		Else
			oDanfe:Say( nLinha, 002, aMensagem[nX][1], oFont08:oFont )
		EndIf
		nMensagem++
		nLinha:= nLinha+ 10
	Next nX
EndIf

//Finalizacao da pagina do objeto grafico
oDanfe:EndPage()

Return(.T.)

Static Function ConvDate(cData)

Local dData
cData  := StrTran(cData,"-","")
dData  := SToD(cData)

Return PadR(StrZero(Day(dData),2)+ "/" + StrZero(Month(dData),2)+ "/" + StrZero(Year(dData),4),15)

//-----------------------------------------------------------------------
/*/{Protheus.doc} NoCEspacoAthar
Pega uma posição (nTam) na string cString, e retorna o caractere de espaço 
anterior.
@author Marcos Taranta
@since 10.01.2009
@version 12.1.17

@param	Null

/*/
//-----------------------------------------------------------------------
Static Function EspacoAt(cString, nTam)

Local nRetorno := 0
Local nX       := 0

/**
* Caso a posição (nTam) For maior que o tamanho da string, ou For um valor
* inválido, retorna 0.
*/
If nTam > Len(cString) .Or. nTam < 1
	nRetorno := 0
	Return nRetorno
EndIf

/**
* Procura pelo caractere de espaço anterior a posição e retorna a posição
* dele.
*/
nX := nTam
While nX > 1
	If SubStr(cString, nX, 1) == " "
		nRetorno := nX
		Return nRetorno
	EndIf

	nX--
EndDo

/**
* Caso não encontre nenhum caractere de espaço, é retornado 0.
*/
nRetorno := 0

Return nRetorno

//-----------------------------------------------------------------------
/*/{Protheus.doc} NoChar
Converte caracteres espceiais

@author ³Fabio Santana
@since 04.10.2010
@version 12.1.17

@param	Null

/*/
//-----------------------------------------------------------------------
Static Function NoChar(cString,lConverte)

Default lConverte := .F.

If lConverte
	cString := (StrTran(cString,"&lt;","<"))
	cString := (StrTran(cString,"&gt;",">"))
	cString := (StrTran(cString,"&amp;","&"))
	cString := (StrTran(cString,"&quot;",'"'))
	cString := (StrTran(cString,"&#39;","'"))
EndIf

Return(cString)

//-----------------------------------------------------------------------
/*/{Protheus.doc} MaxCod
Tratamento para o código do item

@author Bruno Seiji
@since 12.17.2010
@version 12.1.17

@param	Null

/*/
//-----------------------------------------------------------------------
Static Function MaxCod(cString,nTamanho)

//===============================================================
//Tratamento para saber quantos caracteres irão caber na linha
//visto que letras ocupam mais espaço do que os números.
//===============================================================

Local nMax	:= 0
Local nY   	:= 0
Default nTamanho := 45

For nMax := 1 to Len(cString)
	If IsAlpha(SubStr(cString,nMax,1)) .And. SubStr(cString,nMax,1) $ "MOQW"  // Caracteres que ocupam mais espaço em pixels
		nY += 7
	Else
		nY += 5
	EndIf

	If nY > nTamanho   // é o máximo de espaço para uma coluna
		nMax--
		Exit
	EndIf
Next

Return nMax

//-----------------------------------------------------------------------
/*/{Protheus.doc} RetTamCol
Retorna um array do mesmo tamanho do array de entrada, contendo as
medidas dos maiores textos para cálculo de colunas.

@author Marcos Taranta
@since 24/05/2011
@version 1.0

@param  aCabec     Array contendo as strings de cabeçalho das colunas
        aValores   Array contendo os valores que serão populados nas
                   colunas.
        oPrinter   Objeto de impressão instanciado para utilizar o método
                   nativo de cálculo de tamanho de texto.
        oFontCabec Objeto da fonte que será utilizada no cabeçalho.
        oFont      Objeto da fonte que será utilizada na impressão.

@Return aTamCol  Array contendo os tamanhos das colunas baseados nos
                 valores.
/*/
//-----------------------------------------------------------------------
Static Function RetTamCol(aCabec, aValores, oPrinter, oFontCabec, oFont)

	Local aTamCol    := {}
	Local nAux       := 0
	Local nX         := 0

	/* Valores fixados, devido erro de impr. quando S.O está com visualização <> de 100% 
	*/		
	aTamCol := {50,;
				150,;
				33,;
				IIf(aCabec[4] == "CSOSN", 22, 16),; // CST/CSON
				22,;
				15,;
				IIf(aCabec[4] == "CSOSN", 33, 35),; // Quant.
				IIf(aCabec[4] == "CSOSN", 49, 53),; // V.Unitário
				38,;
				37,;
				32,;
				32,;
				24,;
				24} 

	// Checa se os campos completam a página, senão joga o resto na coluna da
	//   descrição de produtos/serviços
	nAux := 0
	For nX := 1 To Len(aTamCol)
		nAux += aTamCol[nX]
	Next nX

	If nAux < 603
		aTamCol[2] += 603 - nAux
	EndIf
	If nAux > 603
		aTamCol[2] -= nAux - 603
	EndIf

Return aTamCol

//-----------------------------------------------------------------------
/*/{Protheus.doc} RetTamTex
Retorna o tamanho em pixels de uma string. (Workaround para o GetTextWidth)

@author Marcos Taranta
@since 24/05/2011
@version 1.0

@param  cTexto   Texto a ser medido.
        oFont    Objeto instanciado da fonte a ser utilizada.
        oPrinter Objeto de impressão instanciado.

@Return nTamanho Tamanho em pixels da string.
/*/
//-----------------------------------------------------------------------
Static Function RetTamTex(cTexto, oFont, oPrinter)

	Local nTamanho := 0
	//Local oFontSize:= FWFontSize():new()
	Local cAux := ""

	Local cValor := "0123456789"
	Local cVirgPonto := ",."
	Local cPerc := "%"
	Local nX := 0

	//nTamanho := oPrinter:GetTextWidth(cTexto, oFont)
	//nTamanho := oFontSize:getTextWidth( cTexto, oFont:Name, oFont:nWidth, oFont:Bold, oFont:Italic )
	/*O calculo abaixo é o mesmo realizado pela oFontSize:getTextWidth
	Retorna 5 para numeros (0123456789), 2 para virgula e ponto (, .) e 7 para percentual (%)
	O ajuste foi realizado para diminuir o tempo na impressão de um danfe com muitos itens*/
	For nX:= 1 to Len(cTexto)
		cAux:= SubStr(cTexto,nX,1)
		If cAux $ cValor
			nTamanho += 5
		ElseIf cAux $ cVirgPonto
			nTamanho += 2
		ElseIf cAux $ cPerc
			nTamanho += 7
		EndIf
	Next nX

  	nTamanho := Round(nTamanho, 0)

Return nTamanho

//-----------------------------------------------------------------------
/*/{Protheus.doc} PosQuebrVal
Retorna a posição onde um valor deve ser quebrado

@author Marcos Taranta
@since 27/05/2011
@version 1.0

@param  cTexto Texto a ser medido.

@Return nPos   Posição aonde o valor deve ser quebrado.
/*/
//-----------------------------------------------------------------------
Static Function PosQuebrVal(cTexto)

	Local nPos := 0

	If Empty(cTexto)
		Return 0
	EndIf

	If Len(cTexto) <= MAXVALORC
		Return Len(cTexto)
	EndIf

	If SubStr(cTexto, MAXVALORC, 1) $ ",."
		nPos := MAXVALORC - 2
	Else
		nPos := MAXVALORC
	EndIf

Return nPos

//-----------------------------------------------------------------------
/*/{Protheus.doc} MontaEnd
Retorna o endereço completo do cliente (Logradouro + Número + Complemento)

@author Renan Franco
@since 11/07/2019
@version 1.0

@param  oMontaEnd	Objeto que possui _xLgr, _xcpl e _xNRO.

@Return cEndereco   Endereço concatenado. Ex.: AV BRAZ LEME, 1000, SÊNECA MALL
/*/
//-----------------------------------------------------------------------
Static Function MontaEnd(oMontaEnd)

	Local lConverte		:= GetNewPar("MV_CONVERT",.F.)
	Local cEndereco		:= ""

	Default oMontaEnd	:= Nil

	Private oEnd		:= oMontaEnd
	
	If  oEnd <> Nil .And. ValType(oEnd)=="O"

		cEndereco := NoChar(oEnd:_Xlgr:Text,lConverte) 
	
		If  " SN" $ (Upper (oEnd:_Xlgr:Text)) .Or. ",SN" $ (Upper (oEnd:_Xlgr:Text)) .Or. "S/N" $ (Upper (oEnd:_Xlgr:Text))
            cEndereco += IIf(Type("oEnd:_xcpl") == "O", ", " + NoChar(oEnd:_xcpl:Text,lConverte), " ")
		Else
            cEndereco += ", " + NoChar(oEnd:_NRO:Text,lConverte) + IIf(Type("oEnd:_xcpl") == "O", ", " + NoChar(oEnd:_xcpl:Text,lConverte), " ")
		EndIf

	EndIf	

Return cEndereco

/*/{Protheus.doc} ValAtrib
Função utilizada para substituir o Type onde não seja possivél a sua retirada para não haver  
ocorrencia indevida pelo SonarQube.

@author 	valter Silva
@since 		09/01/2018
@version 	12
@Return 	Nil
/*/
//-----------------------------------------------------------------------
Static Function ValAtrib(atributo)
Return (Type(atributo) )

//-----------------------------------------------------------------------
/*/{Protheus.doc} MontaNfcDest
Faz criação tag <dest> quando não vem no XML da NFCe
@author 	anderson.machado
@since 		29/04/2020
@version 	12
@Return 	Nil
/*/
//-----------------------------------------------------------------------
Static Function MontaNfcDest(oDestino)
Local oDestRet	:= NIL
Local cAux		:= ""

cAux	:= '<?xml version="1.0" encoding="UTF-8"?>'
cAux	+= '<dest>'
If Type("oDestino:_xNome") == "U"
	cAux	+= 		'<xNome>CONSUMIDOR NAO IDENTIFICADO</xNome>'
EndIf
cAux	+=		'<enderDest>'
cAux	+=   		'<xLgr> </xLgr>'
cAux  	+= 			'<nro> </nro>'
cAux	+= 			'<xBairro> </xBairro>'
cAux	+=			'<cMun> </cMun>'
cAux	+= 			'<Cep> </Cep>'
cAux	+=			'<xMun> </xMun>'
cAux	+=			'<UF> </UF>'
cAux	+=			'<cPais>105</cPais>'
cAux	+=			'<xPais>BRASIL</xPais>'	
cAux 	+= 		'</enderDest>'
cAux	+= '</dest>'

oDestRet := XmlParser(cAux,"_","","")
oDestRet := oDestRet:_dest

Return oDestRet

/*/{Protheus.doc} ValidDanfe
Valida o estilo de fonte caso For PDF ou SPOOl.
@Type function
@version V12 P2210
@author Gabriel Jesus
@since 27/06/2023
@param oDanfe, object, recebe o nDevice para identificar se é pdf ou spool.
/*/
Static Function ValidDanfe(oDanfe)
	Local oEstilo	:= oFont13N:oFont
	Default oDanfe	:= 6

	If oDanfe == 6
		oEstilo := oFont12N:oFont
	EndIf

Return oEstilo
