/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |07/10/2024| Chamado 48764. Corrigido erro quando o XML ainda não foi recebido pelo TOTVS Colaboração
Lucas Borges  |23/05/2025| Chamado 50754. Incluído tratamento para CT-e Simplificado
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MCOM027
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 01/10/2024
Descrição---------: Realiza a consulta do status do documento na SEFAZ
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MCOM027

Local oDlgKey As Object
Local oBtnOut As Object
Local oBtnCon As Object
Local _cChaveNFe := Space(44) as Character

DEFINE MSDIALOG oDlgKey TITLE "Consulta chave" FROM 0,0 TO 150,305 PIXEL OF GetWndDefault()

@ 12,008 Say "Informe a Chave de acesso do documento: " PIXEL OF oDlgKey
@ 20,008 MSGET _cChaveNFe PICTURE "99999999999999999999999999999999999999999999" SIZE 140,10 PIXEL OF oDlgKey

@ 46,035 BUTTON oBtnCon PROMPT "&Consultar" SIZE 38,11 PIXEL ACTION ConsNFeChave(_cChaveNFe)
@ 46,077 BUTTON oBtnOut PROMPT "&Sair" SIZE 38,11 PIXEL ACTION oDlgKey:End()

ACTIVATE DIALOG oDlgKey CENTERED

Return

/*
===============================================================================================================================
Programa----------: ConsNFeChave
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 01/10/2024
Descrição---------: Realiza a consulta do status do documento na SEFAZ
Parametros--------: C -> Chave a ser consultada
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ConsNFeChave(_cChaveNFe As Character)

Local cIdEnt   As Character
Local _cXML    As Character
Local cUrl		:= PadR( GetNewPar("MV_SPEDURL",""), 250 ) As Character
Local aSize    As Array
Local aObjects As Array
Local aListBox As Array
Local aInfo    As Array
Local aPosObj  As Array
Local oDlg     As Object
Local oListBox As Object
Local oBtn1    As Object
Local oBtn3    As Object
Local oBtn4    As Object
			
If Len(AllTrim(_cChaveNFe)) == 44
   If CTIsReady()
      cIdEnt		:= RetIdEnti()
      If !Empty(cIdEnt)
         aListBox := getListBox(cIdEnt, cUrl, _cChaveNFe,@_cXML)

         If !Empty(aListBox)
            aSize := MsAdvSize()
            aObjects := {}
            aAdd( aObjects, { 100, 100, .T., .T. } )
            aAdd( aObjects, { 100, 015, .T., .F. } )

            aInfo := { aSize[ 1 ], aSize[ 2 ], aSize[ 3 ], aSize[ 4 ], 3, 3 }
            aPosObj := MsObjSize( aInfo, aObjects )

            DEFINE MSDIALOG oDlg TITLE "SPED - NFe" From aSize[7],0 to aSize[6],aSize[5] OF oMainWnd PIXEL

            @ aPosObj[1,1],aPosObj[1,2] LISTBOX oListBox Fields HEADER "","Finalidade","Emissão","Dt.Receb/Escrit.","Hr.Receb/Escrit.","Protocolo","Ret. Sefaz           ","Status/Recomendação           ";
              SIZE aPosObj[1,4]-aPosObj[1,2],aPosObj[1,3]-aPosObj[1,1] PIXEL
            oListBox:SetArray( aListBox )
            oListBox:bLine := { || { aListBox[ oListBox:nAT,1 ],aListBox[ oListBox:nAT,2 ],aListBox[ oListBox:nAT,3 ],aListBox[ oListBox:nAT,4 ],aListBox[ oListBox:nAT,5 ],aListBox[ oListBox:nAT,6 ],aListBox[ oListBox:nAT,7 ],aListBox[ oListBox:nAT,8 ] } }

            @ aPosObj[2,1],aPosObj[2,4]-040 BUTTON oBtn1 PROMPT "OK"   		ACTION oDlg:End() OF oDlg PIXEL SIZE 035,011
            @ aPosObj[2,1],aPosObj[2,4]-080 BUTTON oBtn3 PROMPT "Baixa XML"ACTION (getXml(_cChaveNFe,_cXML)) OF oDlg PIXEL SIZE 035,011
            @ aPosObj[2,1],aPosObj[2,4]-120 BUTTON oBtn4 PROMPT "Refresh" 	ACTION (aListBox := getListBox(cIdEnt, cUrl, _cChaveNFe,_cXML),oListBox:nAt := 1,IIf(Empty(aListBox),oDlg:End(),oListBox:Refresh())) OF oDlg PIXEL SIZE 035,011
            @ aPosObj[2,1],aPosObj[2,4]-160 BUTTON oBtn4 PROMPT "Imprimir" ACTION (U_MCOM023D(),oListBox:nAt := 1,IIf(Empty(aListBox),oDlg:End(),oListBox:Refresh())) OF oDlg PIXEL SIZE 035,011

            ACTIVATE MSDIALOG oDlg
         EndIf
      Else
         FWAlertInfo("TSS não configurado ou serviço indisponível","MCOM02701")
      EndIf
   Else
      FWAlertInfo("TSS não configurado ou serviço indisponível","MCOM02702")
      Return
   EndIf
Else
   FWAlertInfo("A chave informada não possui 44 caracteres. Verifique!","MCOM02703")
EndIf
Return

/*
===============================================================================================================================
Programa----------: getListBox
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 01/10/2024
Descrição---------: Retorna lista com os dados para serem apresentados na tela
Parametros--------: _cIdEnt -> C -> Entidade do TSS para processamento
                    _cUrl -> C -> Endereço do Web Wervice no TSS
                    _cChaveNFe -> C -> Chave do documento a ser consultado
Retorno-----------: _aListBox -> A -> Array com a lista dos eventos do documento
===============================================================================================================================
*/
Static Function getListBox(_cIdEnt As Character,_cUrl As Character,_cChaveNFe As Character,_cXML As Character)

Local _aListBox   := {} As Array
Local _cDeneg     := "'110','301','205','302','303','304'" As Character
Local _oOk			:= LoadBitMap(GetResources(), "ENABLE") As Object
Local _oNo			:= LoadBitMap(GetResources(), "DISABLE") As Object
Local _cAlias     := GetNextAlias() As Character
Local _cFinalid   := '' As Character
Local _cDtEmissa  := '' As Character
Local _cError	   := ' ' As Character
Local _cWarning	:= ' ' As Character
Local _oXML       := Nil As Object
Local _oFullXML   := Nil As Object
Local oWS         := Nil As Object

oWs:= WsNFeSBra():New()
oWs:cUserToken   := "TOTVS"
oWs:cID_ENT      := _cIdEnt
oWs:_URL         := AllTrim(_cURL)+"/NFeSBRA.apw"
oWS:cCHVNFE       := _cChaveNFe

BeginSql alias _cAlias
   SELECT 'CKO' TIPO, (SELECT 'SIM' FROM %Table:SF1% WHERE D_E_L_E_T_ = ' ' AND F1_CHVNFE = CKO_CHVDOC AND F1_FILIAL = CKO_FILPRO) CLAS,
   CKO_DT_IMP DATA_INC, CKO_HR_IMP HORA_INC, 
   Case WHEN CKO_I_ALTX = 'N' THEN CKO_XMLRET Else CKO_I_ORIG END CKO_XMLRET
   FROM %Table:CKOCOL%
   WHERE D_E_L_E_T_ = ' '
   AND CKO_CHVDOC = %exp:_cChaveNFe%
   UNION ALL
   SELECT 'SF1', '', TO_CHAR(CAST( I_N_S_D_T_ AT TIME ZONE '-06:00' AS DATE), 'YYYYMMDD'),
   TO_CHAR(CAST( I_N_S_D_T_ AT TIME ZONE '-06:00' AS DATE), 'HH24:MM:SS'),
   Empty_BLOB() CKO_XMLRET
   FROM %Table:SF1%
   WHERE D_E_L_E_T_ = ' '
   AND F1_CHVNFE  = %exp:_cChaveNFe%
   UNION ALL
   SELECT 'SPED050', '', '', '', XML_SIG
   FROM SPED050
   WHERE D_E_L_E_T_ = ' '
   AND DOC_CHV = %exp:_cChaveNFe%
EndSql

While (_cAlias)->(!Eof())
   _cAux:= ""
   If AllTrim((_cAlias)->TIPO) == 'CKO'
      _cAux := "XML recebido pela Italac - "+ IIf(AllTrim((_cAlias)->CLAS) == 'SIM',"Escriturado","Não escriturado")
   ElseIf AllTrim((_cAlias)->TIPO) == 'SF1'
      _cAux := "Documento escriturado"
   EndIf

   If !(_cAlias)->TIPO == 'SPED050'
      aAdd(_aListBox,{IIf(AllTrim((_cAlias)->TIPO) == 'CKO' .And. Empty(AllTrim((_cAlias)->CLAS)),_oNo,_oOk),;
            '',;//Finalidade
            '',;//Emissao
            DToC(SToD((_cAlias)->DATA_INC)),;//Dt Recebimento Ambiente Nacional
            (_cAlias)->HORA_INC,;//Hora Recebimento Ambiente Nacional
            '',;//Protocolo
            '',;//Código de retorno SEFAZ
            _cAux;//Status/Recomendação
            })
   EndIf
   If Empty(_cXML)
      _cXML := (_cAlias)->CKO_XMLRET
   EndIf
   (_cAlias)->(DBSkip())
EndDo
(_cAlias)->(DBCloseArea())

//Buscando status do documento
If oWS:CONSULTADTCHAVENFE()

   If !Empty(_cXML)
      If "ObsContxCampo" $ _cXML
         _cXML := StrTran(_cXML,"ObsContxCampo","ObsCont xCampo")
      EndIf
         
      If "ReferenceURI" $ _cXML
         _cXML := StrTran(_cXML,"ReferenceURI","Reference URI") 
      EndIf

      _cXML := SubStr( _cXML , At( '<' , _cXML ) )
      
      // Inicializa o objeto do XML
      _oFullXML := XmlParser( _cXML , "_" , @_cError , @_cWarning )
      
      If ValType( XmlChildEx( _oFullXML , "_NFEPROC" ) ) == "O" //-- Nota normal, devolucao, beneficiamento, bonificacao
         If ValType( XmlChildEx( _oFullXML:_NFeProc , "_NFE" ) ) == "O"
               _oXML := _oFullXML:_NFeProc:_Nfe    
         Else
               _oXML := _oFullXML:_NFeProc:_NFeProc:_Nfe
         EndIf
      ElseIf ValType(XmlChildEx(_oFullXML,"_CTE")) == "O" //-- Nota de transporte
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

      If SubStr(_cChaveNFe,21,2)=="55"
         _cFinalid := AllTrim(_oXML:_InfNfe:_Ide:_finNFe:Text)
         If ValType(XmlChildEx(_oXML:_InfNfe:_Ide,"_DEMI")) == "O"
            _cDtEmissa := DToC(SToD(StrTran(AllTrim(_oXML:_InfNfe:_Ide:_DEmi:Text),"-","")))
         ElseIf ValType(XmlChildEx(_oXML:_InfNfe:_Ide,"_DHEMI")) == "O"
            _cDtemissa := DToC(SToD(StrTran(SubStr((_oXML:_InfNfe:_Ide:_DhEmi:Text),1,10),"-","")))
         EndIf
      ElseIf SubStr(_cChaveNFe,21,2)$"57/67"
         _cFinalid := AllTrim(If(ValType(XmlChildEx(_oXML:_InfCte,"_IDE")) == "O",AllTrim(_oXML:_InfCte:_Ide:_tpCTe:Text),""))
         _cDtemissa := DToC(SToD(StrTran(AllTrim(_oXML:_InfCte:_Ide:_Dhemi:Text),"-","")))
      EndIf
   EndIf

   aAdd(_aListBox,{IIf(Empty(oWs:OWSCONSULTADTCHAVENFERESULT:cPROTOCOLO) .Or.  oWs:OWSCONSULTADTCHAVENFERESULT:cCODRETNFE $ _cDeneg,_oNo,_oOk),;
                  getDesc(IIf(SubStr(_cChaveNFe,21,2)=="55",'NFE','CTE'),_cFinalid),;//Finalidade
                  _cDtEmissa,;//Emissao
                  DToC(oWs:OWSCONSULTADTCHAVENFERESULT:dRECBTO),;//Dt Recebimento Ambiente Nacional
                  SubStr(oWs:OWSCONSULTADTCHAVENFERESULT:cRECBTOTM,1,8),;//Hora Recebimento Ambiente Nacional
                  oWs:OWSCONSULTADTCHAVENFERESULT:cPROTOCOLO,;//Protocolo
                  getDesc('EVENTO',oWs:OWSCONSULTADTCHAVENFERESULT:cCODRETNFE),;//Código de retorno SEFAZ
                  oWs:OWSCONSULTADTCHAVENFERESULT:cMSGRETNFE;//Status/Recomendação
                  })
Else
   FWAlertError(IIf(Empty(GetWscError(3)),GetWscError(1),GetWscError(3)),"MCOM02704")
EndIf

freeObj(oWs)
oWs := nil
_oXML := Nil
_oFullXML:= Nil
DelClassIntF()

BeginSql alias _cAlias
   SELECT STATUS, PROTOCOLO, TPEVENTO, CMOTEVEN, DATE_EVEN, TIME_EVEN
   FROM SPED150
   WHERE D_E_L_E_T_ = ' '
   AND NFE_CHV = %exp:_cChaveNFe%
EndSql

While (_cAlias)->(!Eof())
   aAdd(_aListBox,{IIf((_cAlias)->STATUS <> 6 .And. (_cAlias)->STATUS <> 7,_oNo,_oOk),;
                  '',;//Finalidade
                  '',;//Emissao
                   DToC(SToD((_cAlias)->DATE_EVEN)),;//DToC(oWs:NFEMONITORLOTEEVENTORESULT:dRECBTO),;//Dt Recebimento Ambiente Nacional
                  (_cAlias)->TIME_EVEN,;//oWs:NFEMONITORLOTEEVENTORESULT:cRECBTOTM;//Hora Recebimento Ambiente Nacional
                  AllTrim(Str((_cAlias)->PROTOCOLO)),;//Protocolo
                  getDesc('EVENTO',AllTrim(Str((_cAlias)->TPEVENTO))),;//Código do evento
                  (_cAlias)->CMOTEVEN;//Status/Recomendação
               })

   (_cAlias)->(DBSkip())
EndDo
(_cAlias)->(DBCloseArea())

//ordena por data do evento
aSort(_aListBox,,,{|x,y| DToS(cTod(x[4]))+x[5] < DToS(cTod(y[4]))+y[5]})
Return _aListBox

/*
===============================================================================================================================
Programa----------: getDesc
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 01/10/2024
Descrição---------: Retorna a descrição
Parametros--------: _cTipo -> C -> Indica se é uma NF-e, NF-e ou um Evento
                    _cEvento -> C -> Código do evento
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function getDesc(_cTipo As Character,_cEvento As Character)

Local _cDesc := '' As Character

If _cTipo == 'NFE'
   Do Case
      Case _cEvento == "1"
         _cDesc := "NF-e normal"
      Case _cEvento == "2"
         _cDesc := "NF-e complementar"
      Case _cEvento == "3"
         _cDesc := "NF-e de ajuste"
      Case _cEvento == "4"
         _cDesc := "Devolução de mercadoria"
      OtherWise
         _cDesc := "XML não recebido"
   End Case
ElseIf _cTipo == 'CTE'
   Do Case
      Case _cEvento == "0"
         _cDesc := "CT-e Normal"
      Case _cEvento == "1"
         _cDesc := "CT-e de Complemento de Valores"
      Case _cEvento == "2"
         _cDesc := "CT-e de Anulação de Valores"
      Case _cEvento == "3"
         _cDesc := "CT-e Substituto"
      OtherWise
         _cDesc := "XML não recebido"
   End Case
Else
   Do Case
      Case _cEvento == "210200"
         _cDesc := "Confirmação da Operação"
      Case _cEvento == "210210"
         _cDesc := "Ciencia da Operação"
      Case _cEvento == "210220"
         _cDesc := "Desconhecimento da Operação"						
      Case _cEvento == "210240"
         _cDesc := "Operação não Realizada"
      Case _cEvento == "610110"
         _cDesc := "Prestação de serviço em desacordo"
      Case _cEvento == "110110"
      _cDesc := "Carta de correção"
      Case _cEvento == "100"
         _cDesc := "Autorização"
      Case _cEvento == "101"
         _cDesc := "Cancelamento"
      Case _cEvento == "102"
         _cDesc := "Inutilização"
   End Case
EndIf
Return _cDesc

/*
===============================================================================================================================
Programa----------: getXML
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 01/10/2024
Descrição---------: Realiza o download do arquivo XML na estação do usuário
Parametros--------: _cChaveNFe -> C -> Chave do documento a ser consultado
                    _cXML -> C -> Arquivo XML a ser gravado
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function getXML(_cChaveNFe As Character,_cXML As Character)

Local _oFile := Nil As Object

Pergunte("MCOM027")
  
If !Empty(_cXML)
   _oFile:= FWFileWriter():New(AllTrim(MV_PAR01)+_cChaveNFe+".xml")
   _oFile:SetEncodeUTF8(.T.)
   If _oFile:Create()
      _oFile:Write(AllTrim(_cXML))
      _oFile:Close()
      If _oFile:Exists()
         FWAlertSuccess("Arquivo gerado com sucesso.","MCOM02706")
      Else
         FWAlertError("Erro na gravação do arquivo XML. Erro: "+ _oFile:Error():Message,"MCOM02707")
      EndIf
    Else
      FWAlertError("Erro na criação do arquivo XML. Erro: "+ _oFile:Error():Message,"MCOM02708")
    EndIf
    FreeObj(_oFile)
Else
   FWAlertWarning("Não foi possível localizar o XML desse documento. Verifique se ele foi recebido pelo TOTVS colaboração.","MCOM02709")
EndIf

Return
