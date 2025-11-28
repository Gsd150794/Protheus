/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |29/07/2024| Chamado 47704. Incluída gravação do CKO_CHVDC
Lucas Borges  |01/08/2024| Chamado 47704. Incluída gravação de novos campos
Lucas Borges  |23/05/2025| Chamado 50754. Incluído tratamento para CT-e Simplificado
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: MCOM002
Autor-----------: Josué Danich Prestes
Data da Criacao-: 22/10/2015
Descrição-------: Rotina de direcionamento de xmls entre diretórios - Chamado 12433
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function MCOM002

Local _aFiles		:= {} As Array
Local _cDirOri		:= Lower(GetMV("IT_DIRORI")) +'\' As Character
Local _cDirDes		:= Lower(GetMV("MV_NGLIDOS")) + '\' As Character
Local _nX			:= 0 As Numeric
Local _cXML 		:= '' As Character
Local _cXMLOri 		:= '' As Character
Local _oXML     	:= Nil As Object
Local _oFullXML 	:= Nil As Object
Local _cForTroca :=	SuperGetMV("IT_XMLCTEF",.F.,"76108349001428;76107770002224") As Character
Local _oFile 		:= Nil As Object
Local _lAlterou		:= .F. As Logical
Local _cError		:= '' As Character
Local _cWarning		:= '' As Character
Local _cChave		:= '' As Character
Local _cTipo		:= '' As Character
Local _lSOWin		:= !isSrvUnix() As Logical //Se é SO Windows

If !Empty(_cDirDes)
	
	_aFiles := Directory(_cDirOri + "*.xml",,,_lSOWin)

	For _nX := 1 To Len(_aFiles)
		_cXML := ""
		_lAlterou := .F.
		_cTipo := '214'
		_cChave := ""
		_oFile := FwFileReader():New(_cDirOri+_aFiles[_nX][1])

		If _oFile:Open()
			While (_oFile:hasLine())
				_cXML += AllTrim(_oFile:GetLine())
			EndDo
			_oFile:Close()
		Else
			FWLogMsg("WARN"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM02001"/*cMsgId*/, ;
			"Não foi possível abrir o arquivo "+_aFiles[_nX][1]+". Ele será ignorado. Erro: "+ _oFile:Error():Message/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
			Loop
		EndIf			

		If "ObsContxCampo" $ _cXML
			_cXML := StrTran(_cXML,"ObsContxCampo","ObsCont xCampo")
		EndIf
			
		If "ReferenceURI" $ _cXML
			_cXML := StrTran(_cXML,"ReferenceURI","Reference URI") 
		EndIf

		_cXML := SubStr( _cXML , At( '<' , _cXML ) )
		_cXMLOri:= _cXML

		// Inicializa o objeto do XML
		_oFullXML := XmlParser( _cXMLOri , "_" , @_cError , @_cWarning )
		If ValType( XmlChildEx( _oFullXML , "_NFEPROC" ) ) == "O" //-- Nota normal, devolucao, beneficiamento, bonificacao
			If ValType( XmlChildEx( _oFullXML:_NFeProc , "_NFE" ) ) == "O"
				_oXML := _oFullXML:_NFeProc:_Nfe    
			Else
				_oXML := _oFullXML:_NFeProc:_NFeProc:_Nfe
			EndIf
			_cChave := Right(AllTrim(_oXML:_InfNfe:_Id:Text),44)
			_cTipo := "109"
		ElseIf ValType(XmlChildEx(_oFullXML,"_CTE")) == "O" //-- Nota de transporte
			_oXML := _oFullXML:_CTe
			_cChave := Right(AllTrim(_oXML:_InfCte:_Id:Text),44)
			_cTipo := "214"
		ElseIf ValType(XmlChildEx(_oFullXML,"_CTESIMPPROC")) == "O"
			_oXML := _oFullXML:_CTeSimpProc:_CTeSimp
			_cChave := Right(AllTrim(_oXML:_InfCte:_Id:Text),44)
			_cTipo := "214"
		ElseIf ValType(XmlChildEx(_oFullXML,"_CTEPROC")) == "O" //-- Nota de transporte
			If ValType(XmlChildEx(_oFullXML:_CTEPROC,"_ENVICTE")) == "O"
				_oXML := _oFullXML:_CTeProc:_ENVICTE:_Cte
				_cTipo := "214"
			ElseIf ValType(XmlChildEx(_oFullXML:_CTEPROC,"_CTEOS")) == "O" //-- Nota de transporte CTEOS
				_oXML := _oFullXML:_CTeProc:_CTEOS
				_cTipo := "273"
			Else
				_oXML := _oFullXML:_CTeProc:_Cte
				_cTipo := "214"
			EndIf
			_cChave := Right(AllTrim(_oXML:_InfCte:_Id:Text),44)
		ElseIf ValType(XmlChildEx(_oFullXML,"_CTEOSPROC")) == "O" //-- Nota de transporte CTEOS
			_oXML := _oFullXML:_CTeOSProc:_CteOS
			_cChave := Right(AllTrim(_oXML:_InfCte:_Id:Text),44)
			_cTipo := "273"
		Else
			//Ignora o XML caso não esteja válido
			FWLogMsg("WARN"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM02002"/*cMsgId*/, ;
			"Não foi possível processar o arquivo "+_aFiles[_nX][1]+". XML com conteúdo inválido."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
			Loop
		EndIf

		//Verifica se deve atualizar o XML fazendo a troca da chave da NF-e referenciada
		If _cTipo == "214"
			AtuChave(_cForTroca,@_cXML,@_lAlterou)
		EndIf			

		//Atualiza o CKO
		DBSelectArea("CKO")
		CKO->(DBSetOrder(1))
		If CKO->(DBSeek(_cTipo+_cChave+'.xml'))
			//Atualiza registro
			RecLock("CKO",.F.)
			CKO->CKO_XMLRET := _cXML
			CKO->CKO_CODERR := " "
			CKO->CKO_ARQUIV := _cTipo+_cChave+'.xml'
			CKO->CKO_EMPPRO := " "
			CKO->CKO_FILPRO := " "
			CKO->CKO_FLAG := '0'
			If CKO->CKO_I_ALTX == 'N' .And. _cXMLOri <> CKO->CKO_XMLRET
				CKO->CKO_I_ORIG := _cXMLOri
				CKO->CKO_I_ALTX := 'S'
			EndIf
		Else
			//Cria registro
			RecLock("CKO",.T.)
			CKO->CKO_FLAG := '0'
			CKO->CKO_ARQUIV := _cTipo+_cChave+'.xml'
			CKO->CKO_STATUS := '2'
			CKO->CKO_DESSTA := 'Arquivo Retornado com sucesso'
			CKO->CKO_XMLRET := _cXML
			CKO->CKO_DT_RET := _aFiles[_nX][3]
			CKO->CKO_HR_RET := _aFiles[_nX][4]
			CKO->CKO_CODEDI := _cTipo
			CKO->CKO_DT_IMP := Date()
			CKO->CKO_HR_IMP := Time()
			CKO->CKO_CHVDOC := _cChave
			CKO->CKO_ARQXML := _cTipo+_cChave+'.xml'
			If _cTipo =="109"
				CKO->CKO_I_FINA := Val(_oXML:_InfNfe:_Ide:_finNFe:Text)
				If ValType(XmlChildEx(_oXML:_InfNfe:_Ide,"_DEMI")) == "O"
					CKO->CKO_I_EMIS := SToD(StrTran(AllTrim(_oXML:_InfNfe:_Ide:_DEmi:Text),"-",""))
				ElseIf ValType(XmlChildEx(_oXML:_InfNfe:_Ide,"_DHEMI")) == "O"
					CKO->CKO_I_EMIS := SToD(StrTran(SubStr((_oXML:_InfNfe:_Ide:_DhEmi:Text),1,10),"-",""))
				EndIf
				If ValType(XmlChildEx(_oXML:_InfNfe:_EMIT,"_CNPJ")) == "O"
					CKO->CKO_I_EMIT := _oXML:_InfNfe:_EMIT:_CNPJ:TEXT
				Else
					CKO->CKO_I_EMIT := _oXML:_InfNfe:_EMIT:_CPF:TEXT
				EndIf
			ElseIf _cTipo $ "214/273"
				CKO->CKO_I_FINA := Val(If(ValType(XmlChildEx(_oXML:_InfCte,"_IDE")) == "O",AllTrim(_oXML:_InfCte:_Ide:_tpCTe:Text),""))
				CKO->CKO_I_EMIS := SToD(StrTran(AllTrim(_oXML:_InfCte:_Ide:_Dhemi:Text),"-",""))
				If ValType(XmlChildEx(_oXML:_InfCte:_Emit,"_CNPJ")) == "O"
					CKO->CKO_I_EMIT := AllTrim(_oXML:_InfCte:_Emit:_CNPJ:Text)
				Else
					CKO->CKO_I_EMIT := AllTrim(_oXML:_InfCte:_Emit:_CPF:Text)
				EndIf
			EndIf

			If _lAlterou
				CKO->CKO_I_ORIG := _cXMLOri
				CKO->CKO_I_ALTX := 'S'
			Else
				CKO->CKO_I_ALTX := 'N'
			EndIf
				
		EndIf
		
		CKO->(MSUnLock())

		FreeObj(_oFile)

		If __CopyFile( _cDirOri + _aFiles[_nX][1] , _cDirDes+_cTipo+_cChave+'.xml',,,_lSOWin)
			FErase( _cDirOri + _aFiles[_nX][1],,_lSOWin)
		EndIf
		_oXML := Nil
		_oFullXML:= Nil
		DelClassIntF()
	Next _nX
EndIf

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} Scheddef
    Função para definição de parametros na tela de schedule
@author Lucas Borges Ferreira
@since 21/05/2025
//-----------------------------------------------------------------*/
Static Function Scheddef()
    Local aParam := {} As Array
    Local aOrd := {} As Array

    aAdd(aParam, "P"        ) // 01 - Tipo R para relatorio P para processo
    aAdd(aParam, "PARAMDEFF") // 02 - Pergunte do relatorio, caso nao use passar ParamDef
    aAdd(aParam, ""         ) // 03 - Alias
    aAdd(aParam, aOrd       ) // 04 - Array de ordens
    aAdd(aParam, ""         ) // 05 - Titulo
    aAdd(aParam, ""         ) // 06 - Nome do relatório (parametro 1 do metodo new da classe TReport)
 
Return aParam

/*
===============================================================================================================================
Programa--------: AtuChave
Autor-----------: Lucas Borges Ferreira
Data da Criacao-: 13/02/2023
Descrição-------: Modifica a chave informada no CT-e para tratar operação onde a Castrolanda referencia uma NF-e deles e não a 
				da Italac
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function AtuChave(_cForTroca, _cXML, _lAlterou)

Local _cError	:= '' As Character
Local _cWarning	:= '' As Character
Local _cXMLNew	:= '' As Character
Local _oXML     := Nil As Object
Local _oFullXML := Nil As Object
Local _nX       := 0 As Numeric
Local _cMensagem:= '' As Character
Local _aItens   := {} As Array
Local _cTagIni  := '<infNFe><chave>' As Character
Local _cTagFim  := '</chave></infNFe>' As Character
Local _nFindChv := 0 As Numeric
Local _cCNPJ_CF := '' As Character
Local _cTagRem  := '' As Character
Local _lComp    := .F. As Logical
Local _cChar    := '' As Character
Local _nPosIni  := 0 As Numeric
Local _nPosFim  := 0 As Numeric

// Inicializa o objeto do XML
_oFullXML := XmlParser( _cXML , "_" , @_cError , @_cWarning )
If ValType(XmlChildEx(_oFullXML,"_CTE")) == "O" //-- Nota de transporte
	_oXML := _oFullXML:_CTe
ElseIf ValType(XmlChildEx(_oFullXML,"_CTESIMPPROC")) == "O"
	_oXML := _oFullXML:_CTeSimpProc:_CTeSimp
ElseIf ValType(XmlChildEx(_oFullXML,"_CTEPROC")) == "O" //-- Nota de transporte
	If ValType(XmlChildEx(_oFullXML:_CTEPROC,"_ENVICTE")) == "O"
		_oXML := _oFullXML:_CTeProc:_ENVICTE:_Cte
	ElseIf ValType(XmlChildEx(_oFullXML:_CTEPROC,"_CTEOS")) == "O" //-- Nota de transporte CTEOS
		_oXML := _oFullXML:_CTeProc:_CTEOS
	Else
		_oXML := _oFullXML:_CTeProc:_Cte
	EndIf
ElseIf ValType(XmlChildEx(_oFullXML,"_CTEOSPROC")) == "O" //-- Nota de transporte CTEOS
	_oXML := _oFullXML:_CTeOSProc:_CteOS
EndIf

//-- Verifica se CTe é do tipo complementar
_lComp      := If(ValType(XmlChildEx(_oXml:_InfCte,"_INFCTECOMP")) != "U",.T.,.F.)
_cTpCte     := If(ValType(XmlChildEx(_oXML:_InfCte,"_IDE")) == "O",AllTrim(_oXML:_InfCte:_Ide:_tpCTe:Text),"") //-- Armazena o tipo do CT-e.
_cTagRem    := If(ValType(XmlChildEx(_oXML:_InfCte,"_REM")) == "O",If(ValType(XmlChildEx(_oXML:_InfCte:_Rem,"_CNPJ")) == "O","_CNPJ","_CPF"),"")
If !Empty(_cTagRem)
    _cCNPJ_CF   := AllTrim(XmlChildEx(_oXML:_InfCte:_Rem,_cTagRem):Text)
EndIf

If !Empty(_cTagRem) .And. !(_lComp .Or. _cTpCte == '2') .And. _cCNPJ_CF $ _cForTroca//Situações onde não deve substituir o documento referenciado

    _cXMLNew := SubStr(_cXML,1,At("<infDoc>",_cXML)+7)

    If ValType(XmlChildEx(_oXML:_InfCte:_Imp,"_INFADFISCO")) == "O" .And. !Empty(_oXML:_INFCTE:_IMP:_INFADFISCO:TEXT)
        _cMensagem += _oXML:_INFCTE:_IMP:_INFADFISCO:TEXT + ". "
    EndIf
    If ValType(XmlChildEx(_oXML:_InfCte,"_COMPL")) != "U" .And. ValType(XmlChildEx(_oXML:_InfCte:_Compl,"_XOBS")) != "U"
        _cMensagem += If(ValType(XmlChildEx(_oXML:_InfCte:_Compl,"_XOBS")) == "O",_oXML:_INFCTE:_COMPL:_XOBS:TEXT + ". ","")
    EndIf
    If ValType(XmlChildEx(_oXML:_InfCte,"_COMPL")) != "U" .And. ValType(XmlChildEx(_oXML:_InfCte:_Compl,"_OBSCONT")) == "A"
        For _nX := 1 to Len(_oXML:_INFCTE:_COMPL:_OBSCONT)
            _cMensagem += _oXML:_INFCTE:_COMPL:_OBSCONT[_nX]:_XCAMPO:TEXT + ": " + _oXML:_INFCTE:_COMPL:_OBSCONT[_nX]:_XTEXTO:TEXT + ". "
        Next _nX
    ElseIf ValType(XmlChildEx(_oXML:_InfCte,"_COMPL")) != "U" .And. ValType(XmlChildEx(_oXML:_InfCte:_Compl,"_OBSCONT")) == "O" .And. !Empty(_oXML:_INFCTE:_COMPL:_OBSCONT:TEXT)//ValType("_oXML:_INFCTE:_COMPL:_OBSCONT:_XTEXTO:TEXT") == "O" //ver
        _cMensagem := _oXML:_INFCTE:_COMPL:_OBSCONT:_XCAMPO:TEXT + ": "+ _oXML:_INFCTE:_COMPL:_OBSCONT:_XTEXTO:TEXT + ". "
    EndIf
    If ValType(XmlChildEx(_oXML:_InfCte,"_COMPL")) != "U" .And. ValType(XmlChildEx(_oXML:_InfCte:_Compl,"_OBSFISCO")) == "A"
        For _nX := 1 to Len(_oXML:_INFCTE:_COMPL:_OBSFISCO)
            _cMensagem += _oXML:_INFCTE:_COMPL:_OBSFISCO[_nX]:_XCAMPO:TEXT + ": " + _oXML:_INFCTE:_COMPL:_OBSFISCO[_nX]:_XTEXTO:TEXT + ". "
        Next _nX
    ElseIf ValType(XmlChildEx(_oXML:_InfCte,"_COMPL")) != "U" .And. ValType(XmlChildEx(_oXML:_InfCte:_Compl,"_OBSFISCO")) == "O" .And. !Empty(_oXML:_INFCTE:_COMPL:_OBSFISCO:TEXT) //ValType("_oXML:_INFCTE:_COMPL:_OBSFISCO:_XTEXTO:TEXT") <> "U" //ver
        _cMensagem := _oXML:_INFCTE:_COMPL:_OBSFISCO:_XCAMPO:TEXT + ": "+ _oXML:_INFCTE:_COMPL:_OBSFISCO:_XTEXTO:TEXT + ". "
    EndIf
    _cXMLNew := SubStr(_cXML,1,At("<infDoc>",_cXML)+7)
    //Separa o número das notas e depois converte em array
    //_cMensagem :=  SubStr(_cMensagem,At("NF DE VENDA :",_cMensagem)+13,At("Usuario",_cMensagem)-At("NF DE VENDA :",_cMensagem)-13)
    _nPosIni := At(" NF",_cMensagem)
    If _nPosIni > 0
        _cMensagem:= SubStr(_cMensagem,_nPosIni,Len(_cMensagem))//coloco msg começando com NF
        _nPosIni := 0
        For _nX:= 1 To Len(_cMensagem)
            _cChar:=SubStr(_cMensagem, _nX, 1)
            If _nPosIni == 0 .And. IsDigit(_cChar)
                _nPosIni := _nX
            EndIf
            If _nPosIni > 0 .And. IsAlpha(_cChar)
                _nPosFim := _nX-1
                Exit
            EndIf
        Next _nX
        _cMensagem:= SubStr(_cMensagem,_nPosIni,_nPosFim-_nPosIni)
        If !Empty(_cMensagem)
            _aItens := StrTokArr2(Replace(_cMensagem,' ',''),",",.T.)
        EndIf

        If Len(_aItens) > 0
            For _nX:=1 To Len(_aItens)
                _cAlias := GetNextAlias()
                _aItens[_nX] := StrZero(Val(_aItens[_nX]),9)
                BeginSql alias _cAlias
                    SELECT SubStr(CKO_ARQUIV,4,44) CHAVE FROM %Table:CKO%
                    WHERE D_E_L_E_T_ = ' '
                    AND SubStr(CKO_ARQUIV,10,14) = %exp:_cCNPJ_CF%
                    AND SubStr(CKO_ARQUIV,29,9) = %exp:_aItens[_nX]%
					ORDER BY R_E_C_N_O_ DESC
                EndSql
                If !Empty((_cAlias)->CHAVE)
                    _cXMLNew += _cTagIni + (_cAlias)->CHAVE + _cTagFim//grava nova chave
                    _nFindChv++
                EndIf
                (_cAlias)->(DBCloseArea())
            Next _nX
        EndIf

        If _nFindChv > 0
            _cXMLNew += SubStr(_cXML,At("</infDoc>",_cXML),Len(_cXML))
            _cXML := _cXMLNew
			_lAlterou := .T.
        EndIf
    EndIf
EndIf

_oXML := Nil
_oFullXML:= Nil

Return(_cXML)
