/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Igor Melgaço  |15/07/2025| Chamado 50972. Ajuste para chamada de workflow de liberação de crédito Pedido de Vendas.
Igor Melgaço  |15/07/2025| Chamado 51335. Ajuste na msg ao final do envio do Workflow
Lucas Borges  |02/10/2025| Chamado 51526. Modificada forma para recuperar a matrícula do usuário.
Jose Gavetti  |26/11/2025| Chamado 51341. __cUserId não deve ter seu conteúdo alterado orientação TOTVS. 
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "RESTFUL.ch"

/*
===============================================================================================================================
Programa----------: AOMS141
Autor-------------: Julio de Paula Paz
Data da Criacao---: 12/09/2016
Descrição---------: Webservice Italac x Multiembarcador.

WebService de recepção de arquivos JSon solicitando liberação de pedidos de vendas bloqueados por 
                    crédito e preço.

http://wfteste.italac.com.br:11408/rest/api/oauth2/v1/token?grant_type=password&username=TMS&password=TmsM1234

self:setStatus(404)
self:setResponse('{"meuJson":"Meu valor"}')

200 - Integrado com sucesso.
300 - Dados inválidos.
400 - Falha interna Webservice.
500 - Duplicidade de requisição.

Modelo Json:

{"cnpjembarcador":"1234567890ABCD",
 "nrpedido":"123456",
 "usuariolib":"123456"}

Parametros--------: CNPJ - Fornecedor
                    NRPEDVEN - Numero do pedido de vendas.
Retorno-----------: Nenhum 
===============================================================================================================================
*/
WsRestful AOMS141 Description "WebService REST Italac x TMS Multiembarcador"

     WsMethod POST LiberarPV Description "Liberação de Pedidos de Vendas Bloqueados" PATH "/AOMS141/LiberaPedidoVendas"  WsSyntax "/AOMS141/LiberaPedidoVendas" // /POST/{method}"
    
End WsRestful

WsMethod POST LiberarPV WsService AOMS141
Local _cJson := ::GetContent()
Local _aFilial, _nI 
Local _oJson
Local _cMsg, _nStatus   
  
Begin Sequence
   
   _dDtEmtrega := Ctod("  /  /  ")
   _cSituacao   := "E"
   _cNrPedV    := ""
   _cCodUsuario :=""
   _cstatus := ""
   _cMsg    := ""
   _cMatriUSR := ""
   _nStatus := 400

   If Empty(_cJson)
      _cMsg := 'Aquivo JSon nao enviado.'
      _nStatus := 300
      Break
   EndIf  

   _oJSon := ""
      
   If ! FWJsonDeserialize(_cJson,@_oJSon)
      _cMsg := 'JSon invalido.'
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
    RpcSetEnv("01", "01",,,"OMS",, {"SA7","SB1","SB2","SB5","SB8","SBJ","SB9","SBE","SBF","SC0","SD5","SBK","SD7","SDC","SF4","SGA","SM2","SDA","SDB","SBM","ADA","SA2","DAK","DAI","DA4","ZFU","ZFV","SC9","SA1","SC5","SC6", "SA1" ,"ZP1","SX6","SX1","SX2","SX3","SM0", "SIX"})

    _aFilial := FwLoadSM0()
    If Empty(_oJSon:CNPJEMBARCADOR) .Or. aScan(_aFilial,{|x| x[18] = U_ItKey(_oJSon:CNPJEMBARCADOR,"A2_CGC")}) == 0
       _cMsg := "CNPJ Embarcador nao preenchido, ou nao esta cadastrado. "
	   _nStatus := 300
       Break
	Else
	   _nI := aScan(_aFilial,{|x| x[18] = U_ItKey(_oJSon:CNPJEMBARCADOR,"A2_CGC")})
	   _cFilial := _aFilial[_nI,5]
	EndIf 	

    //=====================================================================
	// Limpa o ambiente, liberando a licença e fechando as conexões
	//=====================================================================
	RpcClearEnv()
	RpcSetType(2)

	//===========================================================================================
	// Preparando o ambiente com a filial do CNPJ recebidO
	//===========================================================================================
    RpcSetEnv("01", _cFilial,,,"OMS",, {"SA7","SB1","SB2","SB5","SB8","SBJ","SB9","SBE","SBF","SC0","SD5","SBK","SD7","SDC","SF4","SGA","SM2","SDA","SDB","SBM","ADA","SA2","DAK","DAI","DA4","ZFU","ZFV","SC9","SA1","SC5","SC6", "SA1" ,"ZP1","SX6","SX1","SX2","SX3","SM0", "SIX"})
	cFilAnt := _cfilial

	//=======================================================================================================
	// Verifica se o usuário que Liberou o Pedido de Vendas está cadastrado, no cadastro de usuários Italac.
	//=======================================================================================================
	//_nTamCodUser := TamSX3("ZZL_RDCUSR")[1]
	_cMatriUSR   := ""
	//_cCodUsuario := Posicione("ZZL",6,xFilial("ZZL")+U_ItKey(_cCPFUsuar,"RA_CIC"),"ZZL_CODUSU")
	_cCPFUsuar := U_ITKEY(_oJSon:USUARIOLIB,"ZZL_CPFCNP")
	_cCodUsuario := Posicione("ZZL",6,xFilial("ZZL")+_cCPFUsuar,"ZZL_CODUSU") // ZZL_FILIAL+ZZL_RDCUSR
	_cEmailZZL   := Posicione("ZZL",6,xFilial("ZZL")+_cCPFUsuar,"ZZL_EMAIL")  // ZZL_FILIAL+ZZL_RDCUSR

	If Empty(_cCodUsuario)
	   _cMsg := " Usuario nao cadastrado no Cadastro de Usuarios Italac. "
       _nStatus := 300
	   Break
	EndIf

	_cUserNome := UsrFullName(IIF(!Empty(_cCodUsuario), _cCodUsuario, __cUserId))
	_cMatriUSR := FWSFAllUsers({IIF(!Empty(_cCodUsuario), _cCodUsuario, __cUserId)},{"USR_FILIAL"})[1][3]+FWSFAllUsers({IIF(!Empty(_cCodUsuario), _cCodUsuario, __cUserId)},{"USR_CODFUNC"})[1][3]

    //===========================================  
    // Verifica se pedido existe
    //===========================================
	SC5->(DBSetOrder(01))
	If !SC5->(DBSeek(cfilant + U_ItKey(_oJSon:NRPEDIDO,"C5_NUM")))
	   _cMsg := " Pedido de vendas nao localizado: " + AllTrim(_oJSon:NRPEDIDO)
       _nStatus := 300
	   Break
	EndIf

	// Verifica se pedido pode ser bloqueado
	If !SC5->(MsRLock(SC5->(RECNO())))
       _cMsg := "No momento este Pedido de Vendas esta sendo utilizado por outro usuario e nao pode ser manipulado. Tente integrar novamente mais tarde: " + AllTrim(U_LIBERP:NRPEDIDO)
       _nStatus := 300
	   Break
	EndIf

	// Verifica se cliente pode ser bloqueado
	SA1->(DBSetOrder(1))
	If !(SA1->(DBSeek(xFilial("SA1") + SC5->C5_CLIENTE+SC5->C5_LOJACLI)))
	   _cMsg := " Cliente do pedido de vendas nao localizado: " + SC5->C5_CLIENTE+"/"+SC5->C5_LOJACLI
       _nStatus := 300
	   Break
	EndIf

	// Verifica se cliente pode ser bloqueado
	If !SA1->(MsRLock(SA1->(RECNO())))
	   _cMsg := "No momento Cliente deste Pedido de Vendas esta sendo utilizado por outro usuario e nao pode ser manipulado. Tente integrar novamente mais tarde: "  + SC5->C5_CLIENTE+"/"+SC5->C5_LOJACLI
       _nStatus := 300
	   Break
	EndIf

	// Verifica se pedido não foi faturado já
	If !Empty(SC5->C5_NOTA)
	   _cMsg := " Pedido de vendas ja faturado: " + AllTrim(_oJSon:NRPEDIDO) + " - Nota: " + AllTrim(SC5->C5_NOTA)
       _nStatus := 300
	   Break
	EndIf

	If SC5->C5_I_STATU == '04'
       _cMsg := " Pedido de vendas com bloqueio de estoque. Pedidos de vendas com bloqueio de estoque nao podem ser liberados via Integracao: " + AllTrim(_oJSon:NRPEDIDO)
       _nStatus := 300
	   Break 
    EndIf

	SC9->(DBSetOrder(1)) // 1 = C9_FILIAL+C9_PEDIDO+C9_ITEM+C9_SEQUEN+C9_PRODUTO+C9_BLEST+C9_BLCRED
	SC9->(MsSeek(SC5->C5_FILIAL+SC5->C5_NUM))
	While ! SC9->(Eof()) .And. SC9->C9_FILIAL+SC9->C9_PEDIDO == SC5->C5_FILIAL+SC5->C5_NUM
	   If !Empty(SC9->C9_BLEST) .And. SC9->C9_BLEST == "02" // Bloqueio de Estoque
          _cMsg := " Pedido de vendas com bloqueio de estoque. Pedidos de vendas com bloqueio de estoque nao podem ser liberados via Integracao: " + AllTrim(_oJSon:NRPEDIDO)
          _nStatus := 300
	      Break 
       EndIf

       SC9->(DBSkip())
	EndDo

	If SC5->C5_I_BLOQ <> "B" .And. SC5->C5_I_BLPRC <> "B" .And. SC5->C5_I_BLCRE <> "B" 
       _cMsg := " Pedido de vendas: " + SC5->C5_NUM + " desbloqueado."
       _nStatus := 200
	   Break 
	EndIf 

	If Posicione("SA1",1,xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI,"A1_MSBLQL") == '1'
	   _cMsg := " Cliente do pedido bloqueado no cadastro "+AllTrim(SC5->C5_CLIENTE+"/"+SC5->C5_LOJACLI)+"."
       _nStatus := 300
	   Break
	EndIf

	// Verifica se os itens do pedido podem ser bloqueados
	SC6->(DBSetOrder(1))
	SC6->(DBGoTop())
	SC6->(DBSeek(SC5->C5_FILIAL+SC5->C5_NUM))

    SB2->(DBSetOrder(1))
    _ntotqtd := 0
 	_ntotprc := 0

	While SC6->C6_NUM == SC5->C5_NUM .And. SC5->C5_FILIAL == SC6->C6_FILIAL
	   _ntotqtd += SC6->C6_QTDVEN
 	   _ntotprc += SC6->C6_PRCVEN

	   If !SC6->(MsRLock(SC6->(RECNO())))
		  _cMsg := "Item do pedido em uso: "+AllTrim(SC6->C6_FILIAL+"/"+SC6->C6_PRODUTO+"/"+SC6->C6_LOCAL)+"."
		  _nStatus := 300
          Break
	   Else
  		  If U_ITGETMV( 'IT_LOCKPD' , .F. )
  			 SC6->(MSUnLockALL())
			 SC6->(MSUnLock())
		  EndIf
       EndIf
   
	   SB2->(DBSeek(SC6->C6_FILIAL+SC6->C6_PRODUTO+SC6->C6_LOCAL))

	   If !SB2->(MsRLock(SB2->(RECNO())))
		  _cMsg := "Produto em uso: "+AllTrim(SC6->C6_FILIAL+"/"+SC6->C6_PRODUTO+"/"+SC6->C6_LOCAL)+"."
		  _nStatus := 300
          Break
	   Else
          If U_ITGETMV( 'IT_LOCKPD' , .F. )
			 SB2->(MSUnLockALL())
			 SB2->(MSUnLock())
		  EndIf
	   EndIf

	   SC6->(DBSkip())
	EndDo
	
	U_MOMS030W()

    _cmotivo := "Pedido de Vendas Desbloqueado pelo usuario " + AllTrim(_cUserNome) + " atraves da integracao com o TMS Multiembarcador."
    _cMsg    := _cmotivo     

    _StatusPV :=  SC5->C5_I_STATU

    _cSituacao  := "P"
	_dDtEmtrega := SC5->C5_I_DTENT // _dDtEmtrega
    _cNrPedV    := SC5->C5_NUM     // _cNrPedV
    _nStatus    := 200             // Sucesso na liberação.
	_cMsg       := "Solicitação de Avaliação via WF do Pedido: " + SC5->C5_NUM + ", enviado com sucesso via integração TMS."

End Sequence 

//===================================================================================
// Atualiza tabela de muro
//===================================================================================
ZGB->(RecLock("ZGB",.T.))
ZGB->ZGB_DTENT   := _dDtEmtrega 
ZGB->ZGB_SITUAC  := _cSituacao
ZGB->ZGB_NUM     := _cNrPedV    
ZGB->ZGB_USUARI  := _cMatriUSR  
ZGB->ZGB_DATAAL  := Date()
ZGB->ZGB_HORASA  := Time()
ZGB->ZGB_STATUS  := U_STPEDIDO()
ZGB->ZGB_RETORN  := Str(_nStatus,3) + "-" + _cMsg 
ZGB->(MSUnLock())

_cRet := '{"status":'+ StrZero(_nStatus,3) + ', ' + CRLF + '"mensagem":"' + AllTrim(_cMsg) + '"}'

/*
If _nStatus == 200
   self:setStatus(_nStatus) 
   //self:setResponse(_cMsg)
   self:setResponse(_cRet)
Else 
   //SetRestFault(_nStatus,_cMsg)
   SetRestFault(_nStatus,_cRet)
EndIf
*/

self:setStatus(_nStatus) 
self:setResponse(_cRet)

If ! Empty(_cNrPedV)
   //Garante que vai liberar lock de todos os cabeçalhos e todos os itens
   SC5->(DBSetOrder(1))
   If SC5->(DBSeek(_cFilial+_cNrPedV))
	  SC5->(MSUnLock())
	  SC5->(MSUnLockall())

	  SA1->(DBSetOrder(1))
	  If SA1->(DBSeek(xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI))
		 SA1->(MSUnLock())
		 SA1->(MSUnLockall())
      EndIf

	  SC6->(DBSetOrder(1))
	  If SC6->(DBSeek(_cFilial+_cNrPedV))
 		 While SC6->C6_FILIAL == SC5->C5_FILIAL .And. SC6->C6_NUM == SC5->C5_NUM
			SC6->(MSUnLock())
			SC6->(MSUnLockall())

			SB2->(DBSetOrder(1))
			If SB2->(DBSeek(SC6->C6_FILIAL+SC6->C6_PRODUTO+SC6->C6_LOCAL))
		       SB2->(MSUnLock())
			   SB2->(MSUnLockall())
			EndIf

			SC6->(DBSkip())
		 EndDo
	  EndIf
   EndIf
EndIf 

Return .T.

/*
http://wfteste.italac.com.br:11408/rest/AOMS141/LiberaPedidoVendas
                                       /AOMS141/LiberaPedidoVendas
{"username":"TMS","password":"TmsM1234"}

01257995001458
ACWWRV - BLOQUEIO PREÇO
ACWWS3 - BLOQUEIO PREÇO
ACWROE - BLOQUEIO DE CREDITO
ACWROH - BLOQUEIO DE CREDITO

01257995000800
ACWQLV - BOQUEIO DE ESTOQUE

001446

{"cnpjembarcador":"01257995001458",
 "nrpedido":"ACWWRV",
 "usuariolib":"001446"}

Status HTTP	Descrição
422	Exceções de negócio
400	Requisição Mal Formada
401	Requisição Requer Autenticação
403	Requisição Negada
404	Recurso não Encontrado
405	Método não Permitido
408	Tempo esgotado para a requisição
413	Requisição excede o tamanho máximo permitido
415	Tipo de mídia inválida (falta de informar o content-Type correto, ver JSON)
429	Requisição excede a quantidade máxima de chamadas permitidas à API
500	Erro de servidor



*/
