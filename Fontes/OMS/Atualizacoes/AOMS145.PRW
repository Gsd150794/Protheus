/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
Analista         - Programador       - Inicio     - Envio      - Chamado - Motivo da Alteração
---------------------------------------------------------------------------------------------------------------------------------------------------------
Vanderlei Alves  -  Julio Paz        - 04/10/2023 -            - 47259   - Desenvolvimento de um Novo WebService Rest de Integração TMS Multiembarcador com Protheus de Envio de Chamadas a Pagers [OMS]
=========================================================================================================================================================
*/

//====================================================================================================
// Definicoes de Includes e Defines da Rotina.
//====================================================================================================
#Include "TOTVS.ch"
#Include "RESTFUL.ch"

/*
===============================================================================================================================
Programa----------: AOMS145
Autor-------------: Julio de Paula Paz
Data da Criacao---: 04/10/2023
===============================================================================================================================
Descrição---------: Webservice Italac x Multiembarcador.

WebSevice de chamada de Pager. Recebe JSon com código de operação para localizar o endereço IP do Pager e o Numero de pager a
                    ser chamado.

Os acessos destes webservices precisa da obtenção de Token, através do link abaixo:

http://wfteste.italac.com.br:11408/rest/api/oauth2/v1/token?grant_type=password&username=TMS&password=TmsM1234

Códigos de retorno da integração:

200 - Integrado com sucesso.
300 - Dados inválidos.
400 - Falha interna Webservice.
500 - Duplicidade de requisição.

Modelo Json de Chamada de Pager:

http://wfteste.italac.com.br:11408/rest/AOMS145/ChamadoDePager

{"codigointegracao": "valor";
 "numeropager":"valor"}
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum 
===============================================================================================================================
*/
WsRestful AOMS145 Description "WebService REST Italac x TMS Multiembarcador"

	 WsMethod POST ChamadoPag Description "Chamado de Pager" PATH "/AOMS145/ChamadoDePager" WsSyntax "/AOMS145/ChamadoDePager"     // /POST/{method}"
    
End WsRestful

WsMethod POST ChamadoPag WsService AOMS145
Local _cJson := ::GetContent()
Local _nJ 
Local _oJson
Local _cMsg, _nStatus   
Local _cDir, _cArq 

// https://protheusteste.italac.com.br:11408/rest/AOMS145/ChamadoDePager
/*
{"codigointegracao": "valor";
 "numeropager":"valor"}
*/
Begin Sequence
   
   _cstatus := ""
   _cMsg    := ""
   _nStatus := 400

   If Empty(_cJson)
      _cMsg := 'Aquivo JSon nao enviado.'
      _nStatus := 300
      Break
   EndIf  
   
   //=====================================================================
   // Limpa o ambiente, liberando a licença e fechando as conexões
   //=====================================================================
   RpcClearEnv()
   RpcSetType(2)

   //===========================================================================================
   // Preparando o ambiente com a filial do CNPJ recebidO
   //===========================================================================================
   RpcSetEnv("01", "01",,,"OMS",, {"SA7","SB1","SB2","SB5","SB8","SBJ","SB9","SBE","SBF","SC0","SD5","SBK","SD7","SDC","SF4","SGA","SM2","SDA","SDB","SBM","ADA","SA2","DAK","DAI","DA4","ZFU","ZFV","SC9","SA1","SC5","SC6", "SA1" ,"ZP1","SX6","SX1","SX2","SX3","SM0", "SIX","ZEL"})
   Sleep(2000)

   _oJSon := ""
      
   If ! FWJsonDeserialize(_cJson,@_oJSon)
      _cMsg := 'JSon invalido.'
      _nStatus := 300
      Break
   EndIf 

   If Empty(_oJSon:codigointegracao)
      _cMsg := 'O código de integração não foi preenchido.'
      _nStatus := 300
      Break
   EndIf 

   If ValType(_oJSon:numeropager) == "N" .And. _oJSon:numeropager == 0
      _cMsg := 'O numero do pager não foi preenchido.'
      _nStatus := 300
      Break
   EndIf 

   If ValType(_oJSon:numeropager) <> "N" .And. Empty(_oJSon:numeropager) 
      _cMsg := 'O numero do pager não foi preenchido.'
      _nStatus := 300
      Break
   EndIf 

   ZEL->(DBSetOrder(4)) // ZEL_FILIAL+ZEL_FILTMS+ZEL_LOCAL
   If ! ZEL->(MsSeek(xFilial("ZEL")+U_ItKey(_oJSon:codigointegracao,"ZEL_FILTMS")))
      _cMsg := 'O código de integração não foi localizado.'
      _nStatus := 300
      Break
   EndIf 
	
   If Empty(ZEL->ZEL_IPANTE)
      _cMsg := 'O endereço IP da antena do pager não está preenchido para esta filial do TMS.'
      _nStatus := 300
      Break
   EndIf 

   If Empty(ZEL->ZEL_FAIXAI) .Or. ZEL->ZEL_FAIXAI == 0
      _cMsg := 'O número de faixa inicial do pager não preenchido para esta filial do TMS.'
      _nStatus := 300
      Break
   EndIf 

   If Empty(ZEL->ZEL_FAIXAF) .Or. ZEL->ZEL_FAIXAF == 0 
      _cMsg := 'O número de faixa final do pager não está preenchido para esta filial do TMS.'
      _nStatus := 300
      Break
   EndIf 

   If (ValType(_oJSon:numeropager) == "N" .And. _oJSon:numeropager < ZEL->ZEL_FAIXAI) .Or. (ValType(_oJSon:numeropager) == "N" .And. _oJSon:numeropager > ZEL->ZEL_FAIXAF)
      _cMsg := 'O número de pager informado não existe para esta filila do TMS.'
      _nStatus := 300
      Break
   EndIf

   If (ValType(_oJSon:numeropager) <> "N" .And. Val(AllTrim(_oJSon:numeropager)) < ZEL->ZEL_FAIXAI) .Or. (ValType(_oJSon:numeropager) <> "N" .And. Val(AllTrim(_oJSon:numeropager)) > ZEL->ZEL_FAIXAF)
      _cMsg := 'O número de pager informado não existe para esta filila do TMS.'
      _nStatus := 300
      Break
   EndIf

   //StrTokArr( < cValue >, < cToken > )
   _aIpAntena := StrTokArr(ZEL->ZEL_IPANTE,";")

   //_cDir := U_ITGETMV( 'IT_PYTODIR', "C:\Julio\Chamados\47259\Python_Files\")
   _cDir := U_ITGETMV( 'IT_PYTODIR', "/totvs/desenv/protheus_data/data/italac/tmsPython/")
   _cArq := U_ITGETMV( 'IT_PYTFILE', "python chama-pager-lrsn.py")

   For _nJ := 1 To Len(_aIpAntena)
       If Empty(_aIpAntena[_nJ])
          Loop
       EndIf
        
	   _aEnderIP := StrTokArr(_aIpAntena[_nJ],":")
	   _cEndIP   := AllTrim(_aEnderIP[1])
	   _nNrPorta := Val(AllTrim(_aEnderIP[2]))

      If ValType(_oJSon:numeropager) <> "N"
         _cMsg := 'Chamada do Pager ' + _oJSon:numeropager + ", realizada com sucesso." 
         _nStatus := 200
      EndIf 

      If ValType(_oJSon:numeropager) == "N"
         _cMsg := 'Chamada do Pager ' + AllTrim(Str(_oJSon:numeropager,10)) + ", realizada com sucesso." 
         _nStatus := 200
      EndIf 

	   //------------------------------
       If ValType(_oJSon:numeropager) == "N"
          _cParam := AllTrim(_cEndIP) + " " + AllTrim(Str(_oJSon:numeropager,10))
       Else 
          _cParam := AllTrim(_cEndIP) + " " + AllTrim(_oJSon:numeropager)
       EndIf 
       
       //_cArq2 := _cArq 
       _cArq  := _cArq + " " + _cParam
       
	   //================================================================
	   // Roda o programa em Python de envio de mensagem para o Pager.
	   //================================================================
      //ShellExecute("Open", _cArq, /*_cParam*/, _cDir, 0 ) - Não funciona em Job, só funciona com o SmartClient.
      
      //ShellExecute("Open", _cDir + _cArq, "", "C:\" , 0 ) - Não funciona em Job, só funciona com o SmartClient.

      //ShellExecute("Open", _cDir + _cArq2, _cParam , "C:\" , 0 ) - Não funciona em Job, só funciona com o SmartClient.

      //nErr := WinExec(_cDir + _cArq) - Não funciona em Job, só funciona com o SmartClient.
     
      //_nRet := WaitRunSrv( _cDir + _cArq, .F. ,_cDir )
      If ! WaitRunSrv(_cArq, .F. ,_cDir )
         _cMsg := 'Não foi possivel chamar o Pager ' + AllTrim(Str(_oJSon:numeropager,10)) + "." 
         _nStatus := 300
      EndIf 

   Next 
	
End Sequence 

_cRet := '{"status":'+ StrZero(_nStatus,3) + ', ' + CRLF + '"mensagem":"' + AllTrim(_cMsg) + '"}'

//self:setStatus(200) 
self:setResponse(_cRet)

Return .T.
