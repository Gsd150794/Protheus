/*
=========================================================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
=========================================================================================================================================================
Analista         - Programador       - Inicio     - Envio      - Chamado - Motivo da Alteração
---------------------------------------------------------------------------------------------------------------------------------------------------------
Uidson Silva     - Igor Melgaço     - 27/10/2025  - 28/10/25   - 52729   - Ajustes para captura de parametros.
Igor Melgaço     - Igor Melgaço     - 30/10/2025  - 30/10/25   - 52759   - Ajustes para exibir msg no console log.
=========================================================================================================================================================
*/

#Include "RESTFUL.CH"
#Include "FWMVCDef.CH"
#Include "PROTHEUS.CH"


/*
===============================================================================================================================
Programa----------: MGPE030
Autor-------------: Igor Melgaço
Data da Criacao---: 25/02/2025
Descrição---------: Rotinas de Integração REST Gupy. Chamado: 49804 
Parametros--------: 
Retorno-----------: 
===============================================================================================================================
*/ 
User Function MGPE030()	
   Local oRest As Object   
   Local nStatus := 0 As Numeric
   Local cError := "" As Character
   Local cResult := "" As Character
   Local cRegistro := "" As Character
   Local _aHeader := {} As Array
   Local _cUrl := "" As Character
   Local _cParms := ""  As Character //Id do Endpoint no Weebhook para alteração 
   Local _cToken := ""  As Character //Token Gupy
   Local _cTkItalac := "" As Character //Token Protheus
   Local _cUrlItalac := "" //SuperGetMv( "MV_MGPE30U", .F.,'https://apirestdesenv.italac.com.br:21408/rest/MGPE029/Funcionario/Post')
   
   Local _bMaisDetalhes := Nil As CodeBlock

   Private _lSchedule := FWGetRunSchedule()  .OR. SELECT("SX3") <= 0

   If _lSchedule
      RPCSetType( 3 )						//Não consome licensa de uso
   	RpcSetEnv('01','01',,,,GetEnvServer(),{})
   	Sleep( 5000 )						//Aguarda 5 segundos para que as jobs IPC subam.
      
      FWLogMsg("WARN"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE030"/*cMsgId*/, "Abrindo ambiente..."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
   EndIf

   _cUrl       := SuperGetMv( "MV_MGPE30A", .F.,"https://api.gupy.io/api/v1/webhooks") 
   _cParms     := SuperGetMv( "MV_MGPE30H", .F.,"/cbbf257a-25e3-49da-a68b-0e56ba44a1fd")  
   _cToken     := SuperGetMv( "MV_MGPE30T", .F.,"19304db7-6268-4582-8b9a-3e92f986a112") 
   _cUrlItalac := SuperGetMv( "MV_MGPE30U", .F.,'https://apirestdesenv.italac.com.br:21408/rest/MGPE029/Funcionario/Post')

   _cTkItalac := MGPE030T()

   If !Empty(_cTkItalac)

      _cBodyJson := ' {'
      _cBodyJson += '   "action": "pre-employee.moved",'
      _cBodyJson += '   "status": "active",'
      _cBodyJson += '   "techOwnerName": "Nome Sobrenome",'
      _cBodyJson += '   "techOwnerEmail": "nome.sobrenome@gupy.com.br",'
      _cBodyJson += '   "postbackUrl": "'+_cUrlItalac+'",'
      _cBodyJson += '   "clientHeaders": {'
      _cBodyJson += '   "Content-Type": "application/json",'
      _cBodyJson += '   "Authorization": "Bearer '+_cTkItalac+'"'
      _cBodyJson += '   }'
      _cBodyJson += '}'
      
      //_cBodyJson := EncodeUtf8(_cBodyJson)

      _aHeader := {}
      
      oRest := FWRest():New(_cUrl)
      oRest:SetPath(_cParms)

      //Cabeçalho de requisição
      aAdd(_aHeader , "Content-Type: application/json")
      aAdd(_aHeader , 'Authorization: Bearer '+_cToken+' ') 

      If oRest:Put(_aHeader,_cBodyJson)
         cError := ""
         nStatus := HTTPGetStatus(@cError)

         If nStatus >= 200 .And. nStatus <= 299
            If Empty(oRest:getResult())
               cResult := "Falha de comunicação no retorno da requisição com o sistema GUPY!" + CRLF + "Status " + Alltrim(Str(nStatus))
               _lStatus := .F.
               If _lSchedule
                  FWLogMsg("WARN"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE030"/*cMsgId*/, cResult/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
               Else
                  U_ItMsg(cResult,"Atenção",,1)
               EndIf
            Else
               cResult := oRest:getResult()                

               oJson := JsonObject():new()

               cRegistro := oJson:fromJson(cResult)

               If ValType(cRegistro) == "U"
                  If _lSchedule
                     FWLogMsg("WARN"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE030"/*cMsgId*/, "Falha ao popular JsonObject."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
                  Else
                     _bMaisDetalhes:={||  U_ITMsgLog(cResult, "ATENCAO",1,.F.)}
                     U_ItMsg("Integração para atualização do webhook no sistema GUPY concluida com sucesso!","Atenção",,2,,,,,,_bMaisDetalhes)
                  EndIf
               Else
                  If _lSchedule
                 		FWLogMsg("WARN"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE030"/*cMsgId*/, "Falha ao popular JsonObject."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
                  Else
                     U_ItMsg("Falha ao popular JsonObject.","Atenção",,1)
                  EndIf
               EndIf
               
               FreeObj(oJson)
            EndIf
         Else

            cResult := oRest:getResult() 

            oJson := JsonObject():new()

            cRegistro := oJson:fromJson(cResult)

            cRegistro := oJson:GetJsonText("erros") 

            If cRegistro <> "null"
               FWJsonDeserialize(cRegistro,@oErro)
               cMsg := oErro[1]:MENSAGEM
            Else
               cMsg := cError
            EndIf

            cResult := "Falha na integração com o sistema GUPY!" + CRLF + "Erro:" + cError  + CRLF + "Mensagem" + CRLF + cMsg // LimpaString(oErro[1]:MENSAGEM),"")

            If _lSchedule
               FWLogMsg("WARN"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE030"/*cMsgId*/, "Falha ao popular JsonObject."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
            Else
               U_ItMsg(cResult,"Atenção",,1)
            EndIf
            
            FreeObj(oJson) 
         EndIf
      Else
         cResult := oRest:getResult() 

         If ValType(cResult) == "U"
            cResult := ""
         EndIf
         
         cResult := "Falha de comunicação com o sistema GUPY!" + CRLF + oRest:getLastError() + CRLF + cResult
         
         If _lSchedule
            FWLogMsg("WARN"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE030"/*cMsgId*/, "Falha ao popular JsonObject."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
         Else
            U_ItMsg(cResult,"Atenção",,1)
         EndIf
      EndIf
      
      FreeObj(oRest) 
   Endif

   If _lSchedule
      FWLogMsg("WARN"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE030"/*cMsgId*/, "Fechando ambiente..."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
      RpcClearEnv()
   EndIf
   
Return()



/*
===============================================================================================================================
Programa----------: MGPE030T
Autor-------------: Igor Melgaço
Data da Criacao---: 05/06/2025
Descrição---------: Resgate do Token da Italac. Chamado: 49804 
Parametros--------: 
Retorno-----------: 
===============================================================================================================================
*/ 
Static Function MGPE030T() As Character
   Local oRest As Object   
   Local nStatus := 0 As Numeric
   Local cError := "" As Character
   Local cResult := "" As Character
   Local cRegistro := "" As Character
   Local _aHeader := {} As Array
   Local _cUrl := SuperGetMv( "MV_MGPE30R", .F.,"https://apirestdesenv.italac.com.br:21408/rest") As Character
   Local _cParms := SuperGetMv( "MV_MGPE30X", .F.,"/api/oauth2/v1/token") As Character
   Local _cToken := "" As Character
   Local _cUser := SuperGetMv( "MV_MGPE30S", .F.,"GUPY") As Character
   Local _cSenha := SuperGetMv( "MV_MGPE30W", .F.,"Gsd#150790") As Character

   _aHeader := {}
   _cParms += "?grant_type=password&username="+urlEncode(_cUser)+"&password="+urlEncode(_cSenha) 
   oRest := FWRest():New(_cUrl)
   oRest:SetPath(_cParms)

   Aadd(_aHeader , "Content-Type: application/json")

   //oRest:SetPostParams(_cBodyJson)
   oRest:SetChkStatus(.F.)

   If oRest:Post(_aHeader)
      cError := ""
      nStatus := HTTPGetStatus(@cError)

      If nStatus >= 200 .And. nStatus <= 299
         If Empty(oRest:getResult())
            cResult := "Falha de comunicação no retorno da requisição com o Servidor Protheus Rest!" + CRLF + "Status " + Alltrim(Str(nStatus))
            _lStatus := .F.
            If _lSchedule
               FWLogMsg("WARN"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE030"/*cMsgId*/, cResult/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
            Else
               U_ItMsg(cResult,"Atenção",,1)
            EndIf
         Else
            cResult := oRest:getResult()

            oJson := JsonObject():new()

            cRegistro := oJson:fromJson(cResult)

            If ValType(cRegistro) == "U"
            	_cToken := oJson:GetJsonText("access_token")
            Else
               If _lSchedule
                  FWLogMsg("WARN"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE030"/*cMsgId*/, "Falha ao popular JsonObject."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
               Else
                  U_ItMsg("Falha ao popular JsonObject.","Atenção",,1)
               EndIf
            EndIf

            FreeObj(oJson)
         EndIf
      Else

         cResult := oRest:getResult() 

         oJson := JsonObject():new()

         cRegistro := oJson:fromJson(cResult)

         cRegistro := oJson:GetJsonText("erros") 

         If cRegistro <> "null"
            FWJsonDeserialize(cRegistro,@oErro)
            cMsg := oErro[1]:MENSAGEM
         Else
            cMsg := cError
         EndIf

         cResult := "Falha na integração com o Servidor Protheus Rest!" + CRLF + "Erro:" + cError  + CRLF + "Mensagem" + CRLF + cMsg // LimpaString(oErro[1]:MENSAGEM),"")
         
         If _lSchedule
            FWLogMsg("WARN"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE030"/*cMsgId*/, cResult/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
         Else
            U_ItMsg(cResult,"Atenção",,1)
         EndIf

         FreeObj(oJson) 

      EndIf
   Else
      cResult := oRest:getResult() 

      If ValType(cResult) == "U"
         cResult := ""
      EndIf
      
      cResult := "Falha de comunicação com o Servidor Protheus Rest para obtenção do Token!" + CRLF + oRest:getLastError() + CRLF + cResult

      If _lSchedule
         FWLogMsg("WARN"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE030"/*cMsgId*/, cResult/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
      Else
         U_ItMsg(cResult,"Atenção",,1)
      EndIf

   EndIf

   FreeObj(oRest) 

Return(_cToken)
