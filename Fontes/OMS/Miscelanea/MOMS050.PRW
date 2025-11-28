/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |01/08/2025| Chamado 51453. Substituir função U_ITEncode por FWHttpEncode
Alex Wallauer |12/08/2025| Chamado 51742. Retirada da gravação da TAG CRESPPED pq ela não existe nos htmls [libportal_prc.htm / libportal_bon.HTM]
Lucas Borges  |22/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
===============================================================================================================================
*/

#Include "TOTVS.ch"

Static cEnvSrv	  := Upper(GetEnvServer())

/*
===============================================================================================================================
Programa----------: MOMS050
Autor-------------: Jonathan Everton Torioni de Oliveira
Data da Criacao---: 13/03/2020
Descrição---------: Rotina responsavel pelo envio de workflow de liberação de preço Pedido de Vendas.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS050

Local _lWFHTML		:= .T.
Local _aPedidos     := {} //RECNO DOS PEDIDOS BLOQUEADOS
Local _aAprov       := {} //LISTA DE EMAIL DOS COORDENADORES
Local _nX           := 0
Local _nZ           := 0
Local aTables       := {"SZW","SA3","ZGT","SB1","SF4","ZAY","DA1","SC6"}
Local _cLinkG       := ""
Local _cCoord       := ""
Local _cGerente     := ""
Local _cCoordWF     := "1"  //1-Envia WF / 2-Não Envia WF
Local _cAprovador   := ""
Local _lSimplNac    := .F.
Local _nPesoBrut    := 0
Local _aBlqprc      := {}
Local _lPrcErr      := .F.
Local _lEfetiva     := .F.
Local _nPrecoIt		:= 0
Local _nPrecoMin    := 0

//Local _nFaixa       := 0
Private _cHostWF	:= ""
Private _cAprPreco  := ""
Private _cEmaisEnv	:= ""
Private _LExecSelect:= .T.
Private _oDlg
Private _cGetSol    := "Preço fora da tabela"

If Select ("SX3") == 0
	RPCSetType(3)
	RpcSetEnv("01","01" ,,,, "SCHEDULE_WF_PORTAL", aTables )
	sleep( 5000 )

	_lEfetiva := SuperGetMV("IT_EFETV112",.F.,.T.)

	If _lEfetiva
		U_SOMS112S(.F.) //Efetivação Automática
	EndIf

	MOMS050REC() // Recusar pedido com mais de 24 horas sem Liberação ou sem Aprovação

	_aPedidos := RetBloq("N") //Pego todos os recnos dos pedidos a processar

	If Len(_aPedidos) >= 1
		For _nX := 1 To Len(_aPedidos)
			_nPrecoIt  := 0
			_nPrecoMin := 0
			SZW->(DBGoTo(_aPedidos[_nX]))
			SA1->(DBSetOrder(1))
			SA1->(DBSeek(xFilial("SA1")+SZW->ZW_CLIENTE+SZW->ZW_LOJACLI))
			If SA1->A1_SIMPNAC == "1"
				_lSimplNac := .T. // O cliente é optante do Simples Nacional
			Else
				_lSimplNac := .F. // O cliente não é Optante do Simples Nacional
			EndIf

			_cCoord     := Posicione("SA3",1,xFilial("SA3")+SZW->ZW_VEND1,"A3_SUPER")
			_cGerente   := SA3->A3_GEREN
			_cCoordWF   := Posicione("SA3",1,xFilial("SA3")+_cCoord,"A3_I_WF")

			_nPesoBrut  := MOMS050PESO(SZW->ZW_FILIAL,SZW->ZW_IDPED)

			If SZW->ZW_TIPO == "10" .Or. ! Empty(SZW->ZW_KIT)  
				_lPrcErr := .F.
			Else
				_aBlqprc := U_BLQPRC(SZW->ZW_PRODUTO,SZW->ZW_PRCVEN,SZW->ZW_FILIAL,  .F. ,SZW->ZW_TABELA,    .T.,      .T.,          0,           ,         ,SA1->A1_EST,         ,SZW->ZW_TPVENDA,_lSimplNac,_nPesoBrut,SZW->ZW_I_FXPES)
				_lPrcErr := _aBlqprc[1]
				_nPrecoIt:= _aBlqprc[4]
				_nPrecoMin := _aBlqprc[5]
			EndIf
			//_nFaixa  := _aBlqprc[2]
			//---------------------------------------------------
			// _cCoordWF = 1 - Pedido Nao precisa Liberar no Portal pelo Coordenador
			// _cCoordWF = 2 - Pedido Precisa da Liberação no Portal pelo Coordenador
			//---------------------------------------------------			

			If _cCoordWF == "1" .And. SZW->ZW_STATUS = "A" .And. Empty(SZW->ZW_ENVWF)

				If _lPrcErr
					SZW->(RecLock("SZW",.F.))
					SZW->ZW_BLOPRC  := "B"
					SZW->ZW_STATUS  := "P" //tem q ser P
					SZW->ZW_DATAAPR := Date()
					SZW->ZW_HORAAPR := Time()
					SZW->ZW_NIVELWF := "E"  //E-Enviado WF
					SZW->ZW_ENVWF   := "C"
					SZW->ZW_IMPRIME := '1'
					SZW->ZW_PRUNIT  := _nPrecoIt
						If SZW->ZW_I_PRMP  = 0
							SZW->ZW_I_PRMP  := _nPrecoMin
						EndIf
					SZW->(MSUnLock())
					_cAprovador:= _cCoord
				Else
					SZW->(RecLock("SZW",.F.))
					SZW->ZW_BLOPRC := " "
					SZW->ZW_STATUS := "L"
					SZW->ZW_DATAAPR := Date()
					SZW->ZW_HORAAPR := Time()
					SZW->ZW_NIVELWF := "P"  //P-Processado
					SZW->ZW_ENVWF := "C"
					SZW->ZW_IMPRIME := '1'
					SZW->ZW_PRUNIT  := _nPrecoIt
						If SZW->ZW_I_PRMP  = 0
							SZW->ZW_I_PRMP  := _nPrecoMin
						EndIf
					SZW->(MSUnLock())
				EndIf
			ElseIf ( _cCoordWF == "2" .Or.  _cCoordWF == "3" )  //1o Liberado pelo Coord. no Portal antigo
				If SZW->ZW_STATUS == "A" .And. Empty(SZW->ZW_ENVWF)
					SZW->(RecLock("SZW",.F.))
					SZW->ZW_NIVELWF := "P"  //P-Processado
					SZW->ZW_ENVWF   := "C"
					If _cCoordWF == "3"
						SZW->ZW_STATUS := "L"		
					EndIf
					SZW->(MSUnLock()) 
				ElseIf SZW->ZW_STATUS == "L" .And. SZW->ZW_ENVWF <> "G"
					If _lPrcErr
						SZW->(RecLock("SZW",.F.))
						SZW->ZW_STATUS  := "P"
						SZW->ZW_BLOPRC  := "B"
						SZW->ZW_DATAAPR := Date()
						SZW->ZW_HORAAPR := Time()
						SZW->ZW_NIVELWF := "E"  //E-Enviado WF
						SZW->ZW_ENVWF   := "G"
						SZW->ZW_IMPRIME := '1'
						SZW->ZW_PRUNIT  := _nPrecoIt												
							If SZW->ZW_I_PRMP  = 0
							SZW->ZW_I_PRMP  := _nPrecoMin
							EndIf		
						SZW->(MSUnLock())
						_cAprovador:= _cGerente
					Else
						SZW->(RecLock("SZW",.F.))
						SZW->ZW_BLOPRC  := " "
						SZW->ZW_STATUS  := "L"
						SZW->ZW_DATAAPR := Date()
						SZW->ZW_HORAAPR := Time()
						SZW->ZW_NIVELWF := "P"  //P-Processado
						SZW->ZW_ENVWF   := "G"
						SZW->ZW_IMPRIME := '1'
						SZW->ZW_PRUNIT  := _nPrecoIt												
							If SZW->ZW_I_PRMP  = 0
							SZW->ZW_I_PRMP  := _nPrecoMin
							EndIf 
					SZW->(MSUnLock())
					EndIf
				EndIf
			EndIf

			If (nPos:=aScan(_aAprov, {|x| x[5] == SZW->ZW_IDPED })) == 0 .And. SZW->ZW_BLOPRC == "B"
				aAdd(_aAprov, { SZW->ZW_FILIAL                                   ,;
					SZW->ZW_VEND1                                                ,;
					SZW->ZW_ENVWF  ,;
					Posicione("SA3",1, xFilial("SA3")+_cAprovador, "A3_EMAIL") ,; //Quando For testar, comente o Posicione e coloque o e-mail fixo.
				SZW->ZW_IDPED                                                ,;
					_aPedidos[_nX]                                               ,;
					_cAprovador,;
					SZW->ZW_TIPO})
			EndIf
		Next _nX

		_cHostWF 	:= SuperGetMV("IT_WFHOSTS",.T.,"http://wfteste.italac.com.br:4034/")
		_lWFHTML	:= GetMv("MV_WFHTML")

		PutMV("MV_WFHTML",.T.)
		DBSelectArea("SZW")
		SZW->(DBSetOrder(1))

		For _nZ := 1 To Len(_aAprov)
			SZW->(DBSeek(_aAprov[_nZ][1]+_aAprov[_nZ][5]))

			If _aAprov[_nZ][8] == "10"
				_cLinkG := U_MOMS050B(_aAprov[_nZ][1],_aAprov[_nZ][2], _aAprov[_nZ][3],_aAprov[_nZ][4], _aAprov[_nZ][5], _aAprov[_nZ][6]," ",_aAprov[_nZ][7]    ) //Envia e-mail para aprovação de preço
			Else
				_cLinkG := U_MOMS050O(_aAprov[_nZ][1],_aAprov[_nZ][2], _aAprov[_nZ][3],_aAprov[_nZ][4], _aAprov[_nZ][5], _aAprov[_nZ][6]," ",_aAprov[_nZ][7]    ) //Envia e-mail para aprovação de preço
			EndIf

			AtuSzw(_aAprov[_nZ][1],_aAprov[_nZ][5],_aAprov[_nZ][3], _cLinkG, "B") //Atualização de informações referente o envio de e-mail para aprovação.

			//GrVLZGT(_aAprov[_nZ][1],_aAprov[_nZ][2], Date(), "E", "C", _cLinkG,_aAprov[_nZ][5]) // Gravo logo de envio para o coordenador

		Next _nZ
	EndIf

	//inicio BONIFICACAO
	_aPedidos :=  {}
	_aPedidos := RetBloq('B') //Busca todos os recnos dos pedidos de Bonificação a processar

	If Len(_aPedidos) >= 1
		For _nX := 1 To Len(_aPedidos)
			SZW->(DBGoTo(_aPedidos[_nX]))
			SA1->(DBSetOrder(1))
			SA1->(DBSeek(xFilial("SA1")+SZW->ZW_CLIENTE+SZW->ZW_LOJACLI))

			_cCoord     := Posicione("SA3",1,xFilial("SA3")+SZW->ZW_VEND1,"A3_SUPER")
			_cGerente   := SA3->A3_GEREN
			_cCoordWF   := Posicione("SA3",1,xFilial("SA3")+_cCoord,"A3_I_WF")

			If _cCoordWF == "1" .And. SZW->ZW_BLOQ = " " .And. Empty(SZW->ZW_ENVWF)

					SZW->(RecLock("SZW",.F.))
					SZW->ZW_BLOQ    := "B" //Bloqueio Bonificação
					SZW->ZW_DATAAPR := Date()
					SZW->ZW_HORAAPR := Time()
					SZW->ZW_NIVELWF := "E"  //E-Enviado WF
					SZW->ZW_ENVWF   := "C"
					SZW->ZW_IMPRIME := '1'
					SZW->(MSUnLock())
					_cAprovador:= _cCoord

			ElseIf ( _cCoordWF == "2" .Or.  _cCoordWF == "3" )  .And. SZW->ZW_BLOQ == " " .And. SZW->ZW_ENVWF <> "G" //1o Liberado pelo Coord. no Portal antigo

					SZW->(RecLock("SZW",.F.))
					SZW->ZW_BLOQ    := "B" //Bloqueio Bonificação
					SZW->ZW_DATAAPR := Date()
					SZW->ZW_HORAAPR := Time()
					SZW->ZW_NIVELWF := "E"  //E-Enviado WF
					SZW->ZW_ENVWF   := "G"
					SZW->ZW_IMPRIME := '1'
					If _cCoordWF == "3"
						SZW->ZW_STATUS := "L"		
					EndIf
					SZW->(MSUnLock())
					_cAprovador:= _cGerente
			EndIf

			If (nPos:=aScan(_aAprov, {|x| x[5] == SZW->ZW_IDPED })) == 0 .And. SZW->ZW_BLOQ == "B"
				aAdd(_aAprov, { SZW->ZW_FILIAL                                   ,;
					SZW->ZW_VEND1                                                ,;
					SZW->ZW_ENVWF  ,;
					Posicione("SA3",1, xFilial("SA3")+_cAprovador, "A3_EMAIL") ,; //Quando For testar, comente o Posicione e coloque o e-mail fixo.
				SZW->ZW_IDPED                                                ,;
					_aPedidos[_nX]                                               ,;
					_cAprovador,;
					SZW->ZW_TIPO})
			EndIf
		Next _nX

		_cHostWF 	:= SuperGetMV("IT_WFHOSTS",.T.,"http://wfteste.italac.com.br:4034/")
		_lWFHTML	:= GetMv("MV_WFHTML")

		PutMV("MV_WFHTML",.T.)
		DBSelectArea("SZW")
		SZW->(DBSetOrder(1))

		For _nZ := 1 To Len(_aAprov)
			SZW->(DBSeek(_aAprov[_nZ][1]+_aAprov[_nZ][5]))

			
			_cLinkG := U_MOMS050B(_aAprov[_nZ][1],_aAprov[_nZ][2], _aAprov[_nZ][3],_aAprov[_nZ][4], _aAprov[_nZ][5], _aAprov[_nZ][6]," ",_aAprov[_nZ][7]    ) //Envia e-mail para aprovação de preço

			AtuSzw(_aAprov[_nZ][1],_aAprov[_nZ][5],_aAprov[_nZ][3], _cLinkG, "B") //Atualização de informações referente o envio de e-mail para aprovação.

		Next _nZ
	EndIf

	//Fim Bonificacao
	RPCClearEnv()
EndIf

Return 

/*
===============================================================================================================================
Programa----------: MOMS050R
Autor-------------: Jonathan Everton Torioni de Oliveira
Data da Criacao---: 13/03/2020
Descrição---------: Rotina responsável pela execução do retorno do workflow
Parametros--------: _oProcess - Processo inicializado do workflow
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS050R( _oProcess )

Local _cFilial		:= SubStr(_oProcess:oHtml:RetByName("cFilPV"),1,2)
Local _cNumPV		:= _oProcess:oHtml:RetByName("cNumPV")
Local _cOpcao		:= If("APROVAR" $ Upper(_oProcess:oHtml:RetByName("OPCAO")), "APROVADO", "REJEITADO")//na variavel vem escrito "APROVAR (Aguarde...)"
Local _cCodSol		:= _oProcess:oHtml:RetByName("cCodSol")
Local _cObsAprov	:= AllTrim(SubStr(Upper(_oProcess:oHtml:RetByName("CR_OBS")),1,100))
Local _cArqHtm		:= SubStr(_oProcess:oHtml:RetByName("WFMAILID"),3,Len(_oProcess:oHtml:RetByName("WFMAILID")))
Local _cTipRet		:= AllTrim(_oProcess:oHtml:RetByName("CTIPOPER"))
Local _cHtmlMode	:= "\Workflow\htm\pv_concluido.htm"
Local _cCodApr		:= _oProcess:oHtml:RetByName("cCodApr")
Local _cCliente		:= ""
Local _lSoAprovador :=.F.
Local _aAvaliacao   :={}
Local _aMail        :={}
Local _cEmailGeren  := ""
Local _cEmailAprov  := ""
Local _cNomeAprov   := ""
Local _cTipv        := ""
Local _cGeren       := ""
Local _nRec
Local _cLink        := ""
Local _cObs         := _cObsAprov
Local aTables       := {"SZW","SA3","ZGT","SB1","SF4","ZAY","DA1","SC6","SX2","SX3","SX6","WFA"}

RPCSetType(3)
RpcSetEnv("01","01" ,,,, "SCHEDULE_WF_APROVACAO_BLPRE", aTables )
sleep( 5000 )

DBSelectArea("SA3")
DBSetOrder(1)
DBSeek(xFilial("SA3") + _cCodApr )

_cTipv       := SA3->A3_I_TIPV
_cEmailAprov := SA3->A3_EMAIL
_cNomeAprov  := SA3->A3_NOME
_cCPF        := AllTrim(SA3->A3_CGC)
_cGeren      := SA3->A3_GEREN
_cCPFGeren   := AllTrim(Posicione("SA3",1,xFilial("SA3")+_cGeren,"A3_CGC"))
_lMesmoAprov :=(_cCPF == _cCPFGeren)//O coordenador e gerente são a mesma pessoa

DBSeek(xFilial("SA3") + _cCodApr )//REPOSICIONA no aprovador por causa do Posicione

aAdd(_aMail, _cEmailAprov )
aAdd(_aMail, Posicione("SA3",1, xFilial("SA3")+_cCodSol, "A3_EMAIL"))

DBSelectArea("SZW")
DBSetOrder(1)
DBSeek(_cFilial+_cNumPV)

DBSelectArea("SA1")
DBSetOrder(1)
DBSeek(xFilial("SA1") + SZW->ZW_CLIENTE + SZW->ZW_LOJACLI)
_cCliente := SZW->ZW_CLIENTE + "/" + SZW->ZW_LOJACLI + " - " + AllTrim(SA1->A1_NOME) + " - " + AllTrim(SA1->A1_NREDUZ)

_lSoAprovador:=.F.
_aAvaliacao:={}

If _cTipRet == "BONIFICACAO" .And. !Empty(AllTrim(SZW->ZW_I_HTML))

	u_itconout("Retorno da Bonificação Pedido " + _cFilial + " " +  _cNumPV + " " + _cOpcao )
	If SZW->ZW_BLOQ  = "L" .Or. SZW->ZW_BLOQ = "R"

		If SZW->ZW_BLOQ  = "L"
			_cOpcao:= "APROVADO"
			aAdd(_aAvaliacao,{SZW->ZW_DTLIB,ZW->ZW_HLIBP  ,"Ja foi Aprovado"})
		Else
			_cOpcao:= "REJEITADO"
			aAdd(_aAvaliacao,{SZW->ZW_DTLIB  ,"-----","Ja foi Rejeitado"})
		EndIf
		_cObs:=SZW->ZW_MOTLP
		_lSoAprovador:=.T.

	EndIf

	SZW->(DBSeek(_cFilial+_cNumPV))
	_nRec := SZW->(RECNO())
	If  SZW->ZW_IDPED == _cNumPV .And. SZW->ZW_FILIAL == _cFilial
		If _cOpcao == "APROVADO"

			While SZW->(!Eof()) .And. SZW->ZW_IDPED == _cNumPV .And. SZW->ZW_FILIAL == _cFilial

				If _cTipv == "G"
					RecLock("SZW",.F.)
					SZW->ZW_MLIBPRC     := _cCodApr
					SZW->ZW_BLOQ        := "L"
					SZW->ZW_ULIBP       := _cNomeAprov
					SZW->ZW_MOTLP       := "Aprovado pelo código: " + _cCodApr
					SZW->ZW_STATUS      := "L"
					SZW->ZW_IMPRIME     := '1'
					SZW->ZW_I_OBS       := _cObs
					SZW->ZW_I_HLIBG     := Time()  // Hora Gerente
					SZW->ZW_I_DLIBG     := Date()  // Data Gerente
					SZW->( MSUnLock() )
					SZW->(DBSkip())
				ElseIf _cTipv == "C"
					RecLock("SZW",.F.)
					SZW->ZW_MLIBPRC     := _cCodApr
					SZW->ZW_BLOQ        := "B"
					SZW->ZW_HLIBP       := Time()  // Hora Coordenador
					SZW->ZW_DLIBP       := Date()  // Data Coordenador
					SZW->ZW_ULIBP       := _cNomeAprov
					SZW->ZW_MOTLP       := "Submetido aprovação para o gerente."
					SZW->ZW_ENVWF       := 'G'
					SZW->ZW_IMPRIME     := '1'
					SZW->ZW_I_OBS       := _cObs
					SZW->ZW_I_DLIBG     :=  ctod(" / / ")
					SZW->ZW_I_HLIBG     := ""
					SZW->( MSUnLock() )
					SZW->(DBSkip())
				EndIf
			EndDo
			//Verfica se deve ser submetido o envio de e-mail de aprovação para o gerente.
			If _cTipv == "C"
				_cEmailGeren := Posicione("SA3",1,xFilial("SA3")+_cGeren,"A3_EMAIL")
				_cLink := U_MOMS050O(_cFilial,_cCodSol,"G",_cEmailGeren,_cNumPV,_nRec, _cObsAprov,_cGeren, _cTipv, _cObs) //Retorno - prepara o HTML para aprovacao do GERENTE
				AtuSzw(_cFilial,_cNumPV,"G", _cLink, "B")
			EndIf

		Else//Rejeitado
			While SZW->(!Eof()) .And. SZW->ZW_IDPED == _cNumPV .And. SZW->ZW_FILIAL == _cFilial
				RecLock("SZW",.F.)
				SZW->ZW_MLIBPRC     := _cCodApr
				SZW->ZW_BLOQ        := "R"
				If _cTipv == "C"
					SZW->ZW_HLIBP       := Time()
					SZW->ZW_DLIBP       := Date()
					SZW->ZW_I_DLIBG     := ctod(" / / ")
					SZW->ZW_I_HLIBG     := ""
				Else
					SZW->ZW_I_DLIBG     := Date()
					SZW->ZW_I_HLIBG     := Time()
				End
				SZW->ZW_ULIBP       := _cNomeAprov
				SZW->ZW_MOTLP       := "Rejeitado pelo código: " + _cCodApr
				SZW->ZW_STATUS      := "R"
				SZW->ZW_IMPRIME     := '1'
				SZW->ZW_I_OBS       := _cObs
				SZW->ZW_MOTREC      := _cObsAprov

				SZW->(DBSkip())
			EndDo
			AtuSzw(_cFilial,_cNumPV,_cTipv, _cLink, "R") //Atualiza Pedido Rejeitado
			SZW->( MSUnLock() )
		EndIf
	EndIf

Else

	If _cTipRet == "PRECO" .And. (SZW->ZW_BLOPRC  = "L" .Or. SZW->ZW_BLOPRC = "R") .And. !Empty(AllTrim(SZW->ZW_I_HTML))

		If SZW->ZW_BLOPRC  = "L"
			_cOpcao:= "APROVADO"
			aAdd(_aAvaliacao,{SZW->ZW_DTLIB,SZW->ZW_HLIBP  ,"Ja foi Aprovado"})
		Else
			_cOpcao:= "REJEITADO"
			aAdd(_aAvaliacao,{SZW->ZW_DTLIB  ,"-----","Ja foi Rejeitado"})
		EndIf
		_cObs:=SZW->ZW_MOTLP
		_lSoAprovador:=.T.

	EndIf

	If _cTipRet == "PRECO" 

		SZW->(DBSeek(_cFilial+_cNumPV))
		_nRec := SZW->(RECNO())
		If  SZW->ZW_IDPED == _cNumPV .And. SZW->ZW_FILIAL == _cFilial .And. !Empty(AllTrim(SZW->ZW_I_HTML))
			If _cOpcao == "APROVADO"

				While SZW->(!Eof()) .And. SZW->ZW_IDPED == _cNumPV .And. SZW->ZW_FILIAL == _cFilial
					If _cTipv == "G"
						RecLock("SZW",.F.)
						SZW->ZW_MLIBPRC     := _cCodApr
						SZW->ZW_BLOPRC      := "L"
						SZW->ZW_ULIBP       := _cNomeAprov
						SZW->ZW_MOTLP       := "Aprovado pelo código: " + _cCodApr
						SZW->ZW_STATUS      := "L"
						SZW->ZW_IMPRIME     := '1'
						SZW->ZW_I_OBS       := _cObs
						SZW->ZW_I_HLIBG     := Time()
						SZW->ZW_I_DLIBG     := Date()
						SZW->( MSUnLock() )
						SZW->(DBSkip())
					ElseIf _cTipv == "C"
						RecLock("SZW",.F.)
						SZW->ZW_MLIBPRC     := _cCodApr
						SZW->ZW_BLOPRC      := "B"
						SZW->ZW_HLIBP       := Time()
						SZW->ZW_DLIBP       := Date()
						SZW->ZW_ULIBP       := _cNomeAprov
						SZW->ZW_MOTLP       := "Submetido aprovação para o gerente."
						SZW->ZW_ENVWF       := 'G'
						SZW->ZW_IMPRIME     := '1'
						SZW->ZW_I_OBS       := _cObs
						SZW->ZW_I_HLIBG     := ""
						SZW->ZW_I_DLIBG     := ctod(" / / ")
						If _lMesmoAprov
							SZW->ZW_BLOPRC   := "L"
							SZW->ZW_MOTLP    := "Aprovado pelo código: " + _cCodApr+" Coord+Gerente"
							SZW->ZW_STATUS   := "L"
							SZW->ZW_IMPRIME  := '1'
							SZW->ZW_I_OBS    := _cObs
							SZW->ZW_I_HLIBG  := Time() // Hora Gerente
							SZW->ZW_I_DLIBG  := Date() // Data Gerente
						EndIf
						SZW->( MSUnLock() )
						SZW->(DBSkip())
					EndIf
				EndDo
				//Verfica se deve ser submetido o envio de e-mail de aprovação para o gerente.
				If _cTipv == "C" .And. !_lMesmoAprov
					_cEmailGeren := Posicione("SA3",1,xFilial("SA3")+_cGeren,"A3_EMAIL")
					_cLink := U_MOMS050O(_cFilial,_cCodSol,"G",_cEmailGeren,_cNumPV,_nRec, _cObsAprov,_cGeren, _cTipv,_cObs)
					AtuSzw(_cFilial,_cNumPV,"G", _cLink, "B")
				EndIf

			Else//Rejeitado
				While SZW->(!Eof()) .And. SZW->ZW_IDPED == _cNumPV .And. SZW->ZW_FILIAL == _cFilial
					RecLock("SZW",.F.)
					SZW->ZW_MLIBPRC     := _cCodApr
					SZW->ZW_BLOPRC      := "R"
					If _cTipv == "C"
						SZW->ZW_HLIBP       := Time()
						SZW->ZW_DLIBP       := Date()
						SZW->ZW_I_DLIBG     := ctod(" / / ")
						SZW->ZW_I_HLIBG     := ""
					Else
						SZW->ZW_I_DLIBG     := Date()
						SZW->ZW_I_HLIBG     := Time()
					End
					SZW->ZW_ULIBP       := _cNomeAprov
					SZW->ZW_MOTLP       := "Rejeitado pelo código: " + _cCodApr
					SZW->ZW_STATUS      := "Q"
					SZW->ZW_IMPRIME     := '1'
					SZW->ZW_I_OBS       := _cObs
					SZW->ZW_MOTREC      := _cObsAprov
					SZW->(DBSkip())
				EndDo
				AtuSzw(_cFilial,_cNumPV,_cTipv, _cLink, "R") //Atualiza Pedido Rejeitado
				SZW->( MSUnLock() )
			EndIf
		EndIf
	EndIf
EndIf

//==================================================
//Finalize a tarefa anterior para não ficar pendente
//==================================================
_oProcess:Finish()

//========================================================================================
//Faz a cópia do arquivo de aprovação para .old, e cria o arquivo de processo já concluído
//========================================================================================

u_itconout("Cópia do htm  " + _cFilial + " " +  _cNumPV + " Arquivo " + _cArqHtm )

If File("\workflow\emp01\" + _cArqHtm + ".htm")
	If __CopyFile("\workflow\emp01\" + _cArqHtm + ".htm", "\workflow\emp01\" + _cArqHtm + ".old")
		If __CopyFile(_cHtmlMode, "\workflow\emp01\" + _cArqHtm + ".htm")
			u_itconout("Cópia de arquivo de conclusão efetuada com sucesso.")
		Else
			u_itconout("Problema na cópia de arquivo de conclusão.")
		EndIf
	Else
		u_itconout("Não foi possível renomear o arquivo " + _cArqHtm + ".htm.")
	EndIf
EndIf

u_itconout("Fimd da Cópia do htm  " + _cFilial + " " +  _cNumPV + " Arquivo " + _cArqHtm )

Return

/*
===============================================================================================================================
Programa----------: MOMS050CPF
Autor-------------: Jonathan Everton Torioni de Oliveira
Data da Criacao---: 17/03/2020
Descrição---------: Função criada para formatar CPF/CNPJ
Parametros--------: cCPFCNPJ	- Texto a ser quebrado
Retorno-----------: cCampFormat	- Retorna o campo formatado conforme CPF/CNPJ
===============================================================================================================================
*/
Static Function MOMS050CPF(_cCPFCNPJ)

Local _cCampFormat := ""	//Armazena o CPF ou CNPJ formatado

If Len(AllTrim(_cCPFCNPJ)) == 11			//CPF
	_cCampFormat:=SubStr(_cCPFCNPJ,1,3) + "." + SubStr(_cCPFCNPJ,4,3) + "." + SubStr(_cCPFCNPJ,7,3) + "-" + SubStr(_cCPFCNPJ,10,2)
Else									//CNPJ
	_cCampFormat:=SubStr(_cCPFCNPJ,1,2)+"."+SubStr(_cCPFCNPJ,3,3)+"."+SubStr(_cCPFCNPJ,6,3)+"/"+SubStr(_cCPFCNPJ,9,4)+"-"+ SubStr(_cCPFCNPJ,13,2)
EndIf

Return(_cCampFormat)

/*
===============================================================================================================================
Programa----------: MOMS050VSC
Autor-------------: Jonathan Everton Torioni de Oliveira
Data da Criacao---: 17/03/2020
Descrição---------: Recupera saldo atual em aberto do Cliente.
Parametros--------: cCodCli := codigo do cliente. 
Retorno-----------: nValUso := valor em aberto do cliente.  
===============================================================================================================================
*/
Static Function MOMS050VSC( _cCodCli )

Local _cAlias	:= GetNextAlias()
Local _nValUso	:= 0

Default _cCodCli	:= ""

//-- Verifica o saldo atual em aberto do Cliente --//
BeginSql alias _cAlias
	SELECT SUM( SE1.E1_SALDO + SE1.E1_SDACRES - SE1.E1_SDDECRE) VALUSO
	FROM %Table:SE1% SE1
	WHERE SE1.E1_CLIENTE = %exp:_cCodCli%
	AND SE1.D_E_L_E_T_	= ' ' 
	AND SE1.E1_TIPO NOT IN ('RA','NCC') 
	AND SE1.E1_SALDO + SE1.E1_SDACRES - SE1.E1_SDDECRE > 0 
EndSql

If (_cAlias)->(!Eof()) .And. (_cAlias)->VALUSO > 0
	_nValUso := (_cAlias)->VALUSO
EndIf

(_cAlias)->( DBCloseArea() )

Return(_nValUso)

/*
===============================================================================================================================
Programa----------: MOMS050VT2
Autor-------------: Jonathan Everton Torioni de Oliveira
Data da Criacao---: 17/03/2020
Descrição---------: Recupera valor total do pedido de vendas. 
Parametros--------: cCodCli := codigo do cliente. 
Retorno-----------: nValUso := valor em aberto do cliente.  
===============================================================================================================================
*/
Static Function MOMS050VT2( _cNumPed , _cFilAux , _cCodCli , _nOpc )

Local _aArea	:= FWGetArea()
Local _cAlias	:= GetNextAlias()
Local _nValPed	:= 0

Default _cNumPed	:= ""
Default _cFilAux	:= ""
Default _cCodCli	:= ""
Default _nOpc		:= 0

//Verifica o valor total do pedido
BeginSql alias _cAlias
	SELECT SUM(SZW.ZW_QTDVEN * SZW.ZW_PRCVEN) VALPED
	FROM %Table:SZW% SZW
	WHERE D_E_L_E_T_ = ' '
	AND SZW.ZW_IDPED = %exp:_cNumPed%
	AND	SZW.ZW_FILIAL = %exp:_cFilAux%
EndSql

If (_cAlias)->(!Eof()) .And. (_cAlias)->VALPED > 0
	_nValPed := (_cAlias)->VALPED
EndIf

(_cAlias)->( DBCloseArea() )

FWRestArea(_aArea)

Return(_nValPed)

/*
===============================================================================================================================
Programa----------: MOMS50ML
Autor-------------: Jonathan Everton Torioni de Oliveira
Data da Criacao---: 17/03/2020
Descrição---------: Função criada para enviar e-mail ao Aprovador e ao Solicitante com o status do pedido de vendas
Parametros--------: _cFilial	- Filial do Pedido de Vendas
------------------: _cNumPV		- Número do Pedido de Vendas
------------------: _cOpcao		- Status de Aprovação/Rejeição
------------------: _cObs		- Observação da Aprovação/Rejeição
------------------: _cCodApr	- Código do Aprovador
------------------: _cCodSol	- Código do Solicitante
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS50ML(_cFilial, _cNumPV, _cOpcao, _cObs, _cCodApr, _cCodSol, _cTipo, _cCliente, _lSoAprovador, _aAvaliacao, cMailZY0)

Local _cHostWF 	:= SuperGetMV("IT_WFHOSTS",.T.,"http://wfteste.italac.com.br:4034/")
Local _cLogo	:= _cHostWF + "htm/logo_novo.jpg"
Local _chtmfile	:= ""
Local oProc	:= Nil
Local _cNomeAprovador    := ""
Local _cEmailAprovador   := ""
Local _cEmailSolicitante := ""

If _cTipo == "PRECO"

	_chtmfile	:= _cHostWF + "htm/pvprec_retorno.htm"
	//====================================
	//Codigo do processo cadastrado no CFG
	//====================================
	_cCodProce := "PRCPORTAL"

	//====================
	// Assunto da mensagem
	//====================

	_cAssunto := "Retorno da Solicitação da Liberação Preço Pedido Portal,  CNPJ " + _cCliente + " - " + _cFilial + " - " + AllTrim(FWFilialName(cEmpAnt, _cFilial,1)) + ' - PV ' + _cNumPV + ' - ' + '"' + _cOpcao + '"'

	//======================================================================
	// Inicialize a classe TWFProcess e assinale a variável objeto oProcess:
	//======================================================================
	oProc := TWFProcess():New(_cCodProce,"Liberação Preço P.Portal - Retorno")

	//=================================================================
	// Criamos o link para o arquivo que foi gerado na tarefa anterior.
	//=================================================================

	oProc:NewTask("SendMail", "/workflow/htm/pvprec_retorno.htm")

EndIf

_cNomeAprovador   := Posicione("SA3",1,xFilial("SA3")+_cCodApr,"A3_NOME")
_cEmailAprovador  := Posicione("SA3",1,xFilial("SA3")+_cCodApr,"A3_EMAIL")
_cTipoAprovador   := Posicione("SA3",1,xFilial("SA3")+_cCodApr,"A3_I_TIPV")
_cEmailSolicitante:= Posicione("SA3",1,xFilial("SA3")+_cCodSol,"A3_EMAIL")

//=====================================
// Populo as variáveis do template html
//=====================================
oProc:oHtml:ValByName("cLogo"		, _cLogo)
oProc:oHtml:ValByName("A_FILIAL"	, _cFilial + " - " + AllTrim(FWFilialName(cEmpAnt,_cFilial,1)))
oProc:oHtml:ValByName("A_CLIENTE"	, _cCliente)
oProc:oHtml:ValByName("A_PEDVEN"	, _cNumPV)
oProc:oHtml:ValByName("A_STATUS"	, _cOpcao)
oProc:oHtml:ValByName("A_OBSERV"	, AllTrim(_cObs))
If _lSoAprovador//Quando já foi re/aprovado por outro aprovador
	oProc:oHtml:ValByName("A_TESTE01", "***JÁ FOI EXECUTADO POR OUTRO APROVADOR***")
	oProc:oHtml:ValByName("A_DATA"	, _aAvaliacao[1,1])
	oProc:oHtml:ValByName("A_HORA"	, _aAvaliacao[1,2])
	oProc:oHtml:ValByName("A_APROV"	, _aAvaliacao[1,3])
Else
	oProc:oHtml:ValByName("A_TESTE01", "Foi efetivado")
	oProc:oHtml:ValByName("A_DATA"	, DToC(Date()))
	oProc:oHtml:ValByName("A_HORA"	, Time())
	oProc:oHtml:ValByName("A_APROV"	, AllTrim(_cNomeAprovador))
EndIf

//================================================================
// Informamos o destinatário (aprovador) do email contendo o link.  
//================================================================
_cEmailAprovador := AllTrim(_cEmailAprovador)  
oProc:cTo    := _cEmailAprovador 
If !_lSoAprovador .And. _cTipoAprovador = "G" //Quando já foi re/aprovado por outro aprovador
	oProc:cCc := AllTrim(_cEmailSolicitante)  
EndIf
//===============================
// Informamos o assunto do email.  
//===============================

oProc:cSubject	:= FWHttpEncode(_cAssunto)

//===============================================
// Informamos o arquivo a ser atachado no e-mail.
//===============================================
//_oProcess:AttachFile(cConsulta)

_cMailID	:= oProc:fProcessId
_cTaskID	:= oProc:fTaskID

//=======================================================
// Iniciamos a tarefa e enviamos o email ao destinatário.
//=======================================================
oProc:Start()

Return

/*
===============================================================================================================================
Programa----------: MOMS050O
Autor-------------: Jonathan Everton Torioni de Oliveira
Data da Criacao---: 13/03/2020
Descrição---------: Rotina responsável por montar o formulário de aprovação e o envio do link gerado. (Liberação Preço)
Parametros--------: _cFil: filial SZW
                    _RECNO: RECNO SZW
Retorno-----------: _cLink - Link gerado com o html de aprovação do pedido.
===============================================================================================================================
*/
User Function MOMS050O(_cFil,_cCodVen, _cTipoApr, _cMailApr,_cNumPV,_RECNO, _cObsAprov,_cCodApr,_cTipv,_cObs)

Static _nValAtraso	:= 0
Static _nValPed     := 0
Local _aArea		:= FWGetArea()
Local _aAreaSZW		:= SZW->(GetArea())
Local _cHostWF  	:= SuperGetMV("IT_WFHOSTS",.T.,"http://wfteste.italac.com.br:4034/")
Local _cLogo		:= _cHostWF + "htm/logo_novo.jpg"
Local _nMCusto		:= 0
Local _cCodiApr		:= ""
Local _cNomeApr		:= ""
Local _cFilApr		:= ""
Local _cFilial		:= _cFil
Local _nMCustoCli	:= 0
Local _nLimCred		:= 0
Local _nSalPed 		:= 0
Local _nSalPedL		:= 0
Local _nSalDupM		:= 0
Local _nLcFin		:= 0
Local _nSalFinM		:= 0
Local _nSalDup		:= 0
Local _nSalFin		:= 0
Local _nMoeda		:= 0
Local _cQryDA1		:= ""
Local _aVlrDesc		:= {}
Local _nRecnoSZW    := _RECNO
Local _lExecSelect  := .T.
Local _cGetSol      := "Preço fora da tabela"
Local _cTipo        := Posicione("SA3",1,xFilial("SA3")+_cCodApr,"A3_I_TIPV")
Local _cTpcarg      := "F"
Local _cCalcSuframa := "NÃO"
Local _cCodCoord    := ""
Local _cCodGeren    := ""
Local _cTipoAg      := ""
Local _cEnvio       := "ENVIO"
Local _nCalcPesoBruto := 0
Local _nPesBruTotItem := 0
Local _cDesctab       := ""
Local _nPesoFaixa     := 0
Local _cEmailAdd	  := ""

If IsInCallStack("U_MOMS050R") .Or. IsInCallStack("REENVAPR")//QUANDO APERTA OS BOTOES NO HTML
	_lExecSelect := .T.
EndIf

If IsInCallStack("U_MOMS050R") .Or. IsInCallStack("REENVAPR")//QUANDO APERTA OS BOTOES NO HTML
	_cEnvio :="REENVIO"
Else
	_cEnvio :="ENVIO"
EndIf

_cCodiApr	:= _cCodApr
_cNomeApr	:= Posicione("SA3",1, xFilial("SA3")+_cCodApr, "A3_NOME")
_cTipo		:= SA3->A3_I_TIPV
_cEmailAdd  := SA3->A3_I_EMWF
_cFilApr	:= _cFil

//Codigo do processo cadastrado no CFG
_cCodProce := "LIBPVPRC"

// Arquivo html template utilizado para montagem da aprovação
_cHtmlMode := "\Workflow\htm\libportal_prc.htm"

// Inicialize a classe TWFProcess e assinale a variável objeto oProcess:
_oProcess := TWFProcess():New(_cCodProce,"Liberação de Preço Pedido de Vendas")

SZW->(DBGoTo(_RECNO)) // Ao rodar o comando TWFProcess():New, a tabela SZW estava sendo desposicionada. Esta instrução reposiciona a tabela SZW.

_oProcess:NewTask("Liberacao_PVP", _cHtmlMode)

//======================================
//Dados do cabeçalho do pedido de vendas
//======================================
_oProcess:oHtml:ValByName("cLogo", _cLogo)

//====================
//Dados do Solicitante
//====================
_oProcess:oHtml:ValByName("cCodSol"			, _cCodVen)
_oProcess:oHtml:ValByName("cNomSol"			, AllTrim(Posicione("SA3",1, xFilial("SA3")+_cCodVen, "A3_NOME")))
_oProcess:oHtml:ValByName("cMaiSol"			, SA3->A3_EMAIL)
_oProcess:oHtml:ValByName("cFilSol"			, _cFil + ' - ' + AllTrim(FWFilialName(cEmpAnt,_cFil,1)))
_oProcess:oHtml:ValByName("cNumPVSol"		, AllTrim(_cNumPV))
_oProcess:oHtml:ValByName("cDtAtu"			, DToC(Date()) + " - " + Time())
_oProcess:oHtml:ValByName("cTipo"           , IIf(_cTipo == "C","Coordenador", "Gerente"))

_oProcess:oHtml:ValByName("cTipOper"		, "PRECO"			)

_oProcess:oHtml:ValByName("cCodApr"			, _cCodiApr			)
_oProcess:oHtml:ValByName("cNomApr"			, AllTrim(_cNomeApr))

_oProcess:oHtml:ValByName("cCodRep"			, _cCodVen      			)
_oProcess:oHtml:ValByName("cNomRep"			, AllTrim(Posicione("SA3",1,xFilial("SA3")+_cCodVen, "A3_NOME"))   	)

_cCodCoord := Posicione("SA3",1, xFilial("SA3")+_cCodVen, "A3_SUPER")
_oProcess:oHtml:ValByName("cCodCoo"			, _cCodCoord  				)
_oProcess:oHtml:ValByName("cNomCoo"			, AllTrim(Posicione("SA3",1,xFilial("SA3")+_cCodCoord, "A3_NOME"))	)

_cCodGeren := Posicione("SA3",1, xFilial("SA3")+_cCodVen, "A3_GEREN")

_oProcess:oHtml:ValByName("cCodGer"			, _cCodGeren        			)
_oProcess:oHtml:ValByName("cNomGer"			, AllTrim(Posicione("SA3",1, xFilial("SA3")+_cCodGeren,"A3_NOME"))	)

//===============
//Dados do Pedido
//===============
_oProcess:oHtml:ValByName("cNumPV"			, _cNumPV		)
DBSelectArea("SZW")
SZW->(DBGoTo(_nRecnoSZW))

_oProcess:oHtml:ValByName("cTipoPV"			, Posicione("ZB4",1,xFilial("ZB4")+SZW->ZW_TIPO, "ZB4_DESCRI")				)


_oProcess:oHtml:ValByName("cFilPV"			, _cFil + " - " + AllTrim(FWFilialName(cEmpAnt,_cFil,1)))
_oProcess:oHtml:ValByName("cEmisPV"			, DToC(SZW->ZW_EMISSAO)	                            	)

If SZW->ZW_FILPRO != '0 ' .And. !Empty(SZW->ZW_FILPRO) .And. SZW->ZW_FILPRO != SZW->ZW_FILIAL

	_cfilpro := SZW->ZW_FILPRO

	_oProcess:oHtml:ValByName("ctrocanf"		, "SIM"	)
	_oProcess:oHtml:ValByName("cFilCarregamento"	, _cfilpro + " - " + AllTrim(FWFilialName(cEmpAnt,_cfilpro,1)))

Else
	_oProcess:oHtml:ValByName("ctrocanf"		, "NÃO"	)
	_oProcess:oHtml:ValByName("cFilCarregamento"	, " " )
EndIf

_ctab := SZW->ZW_TABELA
_cDesctab := Posicione("DA0",1,xFilial("DA0")+SZW->ZW_TABELA,'DA0_DESCRI')

_oProcess:oHtml:ValByName("cTabPrc"		, _ctab	)
_oProcess:oHtml:ValByName("cDecPrc"		, AllTrim(_cDesctab))

_oProcess:oHtml:ValByName("nFaixa"		, SZW->ZW_I_FXPES)

If SZW->ZW_I_FXPES == 3
	_nPesoFaixa := DA0->DA0_I_PES3
ElseIf SZW->ZW_I_FXPES == 2
	_nPesoFaixa := DA0->DA0_I_PES2
Else
	_nPesoFaixa := DA0->DA0_I_PES1
EndIf

_oProcess:oHtml:ValByName("nPesoFaixa"		, _nPesoFaixa)

DBSelectArea("SE4")
DBSetOrder(1)
DBSeek(xFilial("SE4") + SZW->ZW_CONDPAG)
_oProcess:oHtml:ValByName("cCondPG"			, SE4->E4_CODIGO + " - " + SE4->E4_DESCRI	)

//================
//Dados do Cliente
//================

DBSelectArea("SA1")
DBSetOrder(1)
DBSeek(xFilial("SA1") + SZW->ZW_CLIENTE + SZW->ZW_LOJACLI)

// Assunto da mensagem
If _cTipo == "C"
	_cAssunto := "Sol.Coord. para Lib.Preço, Pedido " + AllTrim(_cNumPV) + " CNPJ " + MOMS050CPF(SA1->A1_CGC) + " " + AllTrim(A1_NOME) + " - " + _cFilApr + " " + AllTrim(FWFilialName(cEmpAnt,_cFilApr,1))  + " --> " + _cEnvio
Else
	_cAssunto := "Sol.Gerente para Lib.Preço, Pedido " + AllTrim(_cNumPV) + " CNPJ " + MOMS050CPF(SA1->A1_CGC) + " " + AllTrim(A1_NOME) + " - " + _cFilApr + " " + AllTrim(FWFilialName(cEmpAnt,_cFilApr,1))  + " --> " + _cEnvio
EndIf

DBSelectArea("SE4")
DBSetOrder(1)
DBSeek(xFilial("SE4") + SA1->A1_COND)
_oProcess:oHtml:ValByName("cCondPgPad"		, SE4->E4_CODIGO + " - " + SE4->E4_DESCRI	)

If SA1->A1_CALCSUF = "I"
	_cCalculSuframa:= "ICMS"
ElseIf SA1->A1_CALCSUF = "S"
	_cCalculSuframa:= "SIM"
Else
	_cCalculSuframa:= "NÃO"
EndIf
_oProcess:oHtml:ValByName("cNomCli"			, SA1->A1_NOME				)
_oProcess:oHtml:ValByName("cNomRed"			, SA1->A1_NREDUZ			)
_oProcess:oHtml:ValByName("cCodCli"			, SA1->A1_COD				)
_oProcess:oHtml:ValByName("cLojCli"			, SA1->A1_LOJA				)
_oProcess:oHtml:ValByName("cCnpjCli"		, MOMS050CPF(SA1->A1_CGC)	)
_oProcess:oHtml:ValByName("cGrpVen"			, SA1->A1_GRPVEN + " - " + Posicione("ACY",1,xFilial("ACY") + SA1->A1_GRPVEN, "ACY_DESCRI")				)
_oProcess:oHtml:ValByName("cContatCli"		, SA1->A1_CONTATO			)
_oProcess:oHtml:ValByName("cFoneCli"		, SA1->A1_TEL				)
_oProcess:oHtml:ValByName("cEmailCli"		, SA1->A1_EMAIL				)
_oProcess:oHtml:ValByName("cCidCli"			, SA1->A1_MUN				)
_oProcess:oHtml:ValByName("cEstCli"			, SA1->A1_EST				)
_oProcess:oHtml:ValByName("cEndCli"			, SA1->A1_END				)
_oProcess:oHtml:ValByName("cAnaCre"			, SA1->A1_I_ACRED			)
_oProcess:oHtml:ValByName("cSuframa"		, _cCalcSuframa  			)

//========================
//Informarções Financeiras
//========================
DBSelectArea("SA1")
SA1->( DBSetOrder(1) )
SA1->( DBSeek( xFilial("SA1") + SZW->ZW_CLIENTE ) )

While SA1->(!Eof()) .And. SA1->A1_COD == SZW->ZW_CLIENTE

	_nMCustoCli	:= IIf( SA1->A1_MOEDALC > 0 , SA1->A1_MOEDALC	, Val(SuperGetMv("MV_MCUSTO")) )
	_nLimCred	+= xMoeda( SA1->A1_LC							, _nMCustoCli , _nMCusto , Date() )
	_nSalPed 	+= xMoeda( SA1->A1_SALPED + SA1->A1_SALPEDB		, _nMCustoCli , _nMCusto , Date() )
	_nSalPedL	+= xMoeda( SA1->A1_SALPEDL						, _nMCustoCli , _nMCusto , Date() )
	_nSalDupM	+= xMoeda( SA1->A1_SALDUPM						, _nMCustoCli , _nMCusto , Date() )
	_nLcFin		+= xMoeda( SA1->A1_LCFIN						, _nMCustoCli , _nMCusto , Date() )
	_nSalFinM	+= xMoeda( SA1->A1_SALFINM						, _nMCustoCli , _nMCusto , Date() )
	_nSalDup	+= SA1->A1_SALDUP
	_nSalFin	+= SA1->A1_SALFIN

	SA1->( DBSkip() )
EndDo

DBSelectArea("SA1")
SA1->( DBSetOrder(1) )
SA1->( DBSeek( xFilial("SA1") + SZW->ZW_CLIENTE + SZW->ZW_LOJACLI) )

_nMCusto 	:= IIf( SA1->A1_MOEDALC > 0 , SA1->A1_MOEDALC , Val( SuperGetMv("MV_MCUSTO") ) )
_nMoeda		:= 1
If _lExecSelect
	_nValAtraso:= MOMS050VSC( SZW->ZW_CLIENTE + SZW->ZW_LOJACLI )
	_nValPed   := MOMS050VT2( SZW->ZW_IDPED , _cFil , 1 )
EndIf

_oProcess:oHtml:ValByName("nLimCrd"			, TRansform(_nLimCred,PesqPict("SA1","A1_LC",17,1)))
_oProcess:oHtml:ValByName("nTitAber"		, TRansform(_nSalDup,PesqPict("SA1","A1_SALDUP",17,1)))
_oProcess:oHtml:ValByName("nTitVenc"		, TRansform(_nSalPedL,PesqPict("SA1","A1_SALPEDL",17,1)))
_oProcess:oHtml:ValByName("nSLimCrd"		, TRansform(_nLimCred-_nSaldupM-_nSalPedL,PesqPict("SA1","A1_SALDUP",17,1)))
_oProcess:oHtml:ValByName("nPedAtu"			, TRansform(_nValPed ,PesqPict("SA1","A1_SALDUP",17,1)))
_oProcess:oHtml:ValByName("nSalNFat"		, TRansform(_nSalPed ,PesqPict("SA1","A1_SALPED",17,1)))
_oProcess:oHtml:ValByName("nLimCChe"		, TRansform(_nLcFin ,PesqPict("SA1","A1_LCFIN",17,1)))
_oProcess:oHtml:ValByName("nSldChq"			, TRansform(_nSalFin ,PesqPict("SA1","A1_SALDUP",17,1)))
_oProcess:oHtml:ValByName("nTitProt"		, Str(SA1->A1_TITPROT,3))
_oProcess:oHtml:ValByName("nChqDev"			, Str(SA1->A1_CHQDEVO,3))
_oProcess:oHtml:ValByName("nMComp"			, Transform(SA1->A1_MCOMPRA ,PesqPict("SA1","A1_MCOMPRA",17,_nMCusto)))
_oProcess:oHtml:ValByName("nMDuplic"		, Transform(SA1->A1_MAIDUPL ,PesqPict("SA1","A1_MAIDUPL",17,_nMCusto)))
_oProcess:oHtml:ValByName("nMAtras"			, Transform(SA1->A1_METR ,PesqPict("SA1","A1_METR",7)))
_oProcess:oHtml:ValByName("cVenLCr"			, DToC(SA1->A1_VENCLC))
_oProcess:oHtml:ValByName("cDtLiLib"		, DToC(SToD("")))
_oProcess:oHtml:ValByName("nAtraAtu"		, TRansform(_nValAtraso ,PesqPict("SA1","A1_SALDUP",17,1)))

//==================
//Posição do Cliente
//==================

_oProcess:oHtml:ValByName("nLimCrl"			, TRansform(SA1->A1_LC,PesqPict("SA1","A1_LC",14,_nMCusto)))
_oProcess:oHtml:ValByName("nSldHist"		, TRansform(SA1->A1_SALDUP,PesqPict("SA1","A1_SALDUP",14,1)))
_oProcess:oHtml:ValByName("nLimcSec"		, TRansform(Round(Noround(xMoeda(SA1->A1_LCFIN,_nMcusto,1,dDataBase,MsDecimais(1)+1),2),MsDecimais(1)),PesqPict("SA1","A1_LCFIN",14,1)),TRansform(SA1->A1_LCFIN,PesqPict("SA1","A1_LCFIN",14,_nMcusto)))
_oProcess:oHtml:ValByName("nSldLcSe"		, TRansform(SA1->A1_SALFIN,PesqPict("SA1","A1_SALFIN",14,1)))
_oProcess:oHtml:ValByName("nMaiCom"			, TRansform(Round(Noround(xMoeda(SA1->A1_MCOMPRA, _nMcusto ,1, dDataBase,MsDecimais(1)+1),2),MsDecimais(1)),PesqPict("SA1","A1_MCOMPRA",14,1)),TRansform(SA1->A1_MCOMPRA,PesqPict("SA1","A1_MCOMPRA",14,_nMcusto)))
_oProcess:oHtml:ValByName("nMaiSld"			, TRansform(Round(Noround(xMoeda(SA1->A1_MSALDO, _nMcusto ,1, dDataBase,MsDecimais(1)+1 ),2),MsDecimais(1)),PesqPict("SA1","A1_MSALDO",14,1)))
_oProcess:oHtml:ValByName("cPriCom"			, DToC(SA1->A1_PRICOM))
_oProcess:oHtml:ValByName("cUltCom"			, DToC(SA1->A1_ULTCOM))
_oProcess:oHtml:ValByName("nMaiAtr"			, Transform(SA1->A1_MATR,PesqPict("SA1","A1_MATR",14)))
_oProcess:oHtml:ValByName("nMedAtr"			, PADC(Str(SA1->A1_METR,7,2),22))
_oProcess:oHtml:ValByName("cGrauRis"		, SA1->A1_RISCO)


//===============================
//Informações do Pedido de Vendas
//===============================
If SZW->ZW_TPFRETE == "C"
	_oProcess:oHtml:ValByName("cFrete"			, "CIF"					)
ElseIf SZW->ZW_TPFRETE == "F"
	_oProcess:oHtml:ValByName("cFrete"			, "FOB"					)
ElseIf SZW->ZW_TPFRETE == "T"
	_oProcess:oHtml:ValByName("cFrete"			, "TERCEIROS"			)
ElseIf SZW->ZW_TPFRETE == "S"
	_oProcess:oHtml:ValByName("cFrete"			, "Sem Frete"			)
EndIf

_cTipoAg:=SZW->ZW_I_AGEND+" - "+U_TipoEntrega(SZW->ZW_I_AGEND)

_oProcess:oHtml:ValByName("cTpCarga"		, IIf(SZW->ZW_TIPCAR == "1", SZW->ZW_TIPCAR + " - Paletizada", IIf(SZW->ZW_TIPCAR == "2", SZW->ZW_TIPCAR + " - Batida", "")))
_oProcess:oHtml:ValByName("nQtdChap"		, SZW->ZW_CHAPA  			)
_oProcess:oHtml:ValByName("cHrDescg"		, SZW->ZW_HORDES			)
_oProcess:oHtml:ValByName("nCusCarg"		, "0"						)
_oProcess:oHtml:ValByName("dDtEntrega"		, SZW->ZW_FECENT 			)
_oProcess:oHtml:ValByName("cHrEntrega"		, SZW->ZW_HOREN  			)
_oProcess:oHtml:ValByName("cSenhaEntr"		, SZW->ZW_SENHA    			)
_oProcess:oHtml:ValByName("cTipoAgenda"		, _cTipoAg       			)
_oProcess:oHtml:ValByName("cCarga"          , IIf(AllTrim(SZW->ZW_TPVENDA) == "F" .And. SZW->ZW_TPVENDA != "", " F - Fechada", " V - Fracionada"))
_oProcess:oHtml:ValByName("cEnvio"			, _cEnvio       			)
_oProcess:oHtml:ValByName("cMensNF"			, SZW->ZW_MENNOTA			)
_oProcess:oHtml:ValByName("cObsPed"			, SZW->ZW_OBSCOM 			)



//=========================================================================
// Dados de Aprovação quando Retorno é do Coordenador
//=========================================================================

_oProcess:oHtml:ValByName("nGetMagro"		, TRansform(SZW->ZW_I_LMAGR,PesqPict("SZW","ZW_I_LMAGR",14,1)))
_oProcess:oHtml:ValByName("cGetObsCoord"	, _cObs )

If _cTipv = 'C'
	_oProcess:oHtml:ValByName("cDataAprov"	, DToC(SZW->ZW_DLIBP)	 	)
	_oProcess:oHtml:ValByName("cHoraAprov"	, SZW->ZW_HLIBP )
Else
	_oProcess:oHtml:ValByName("cDataAprov"	, DToC(SZW->ZW_I_DLIBG) )
	_oProcess:oHtml:ValByName("cHoraAprov"	, SZW->ZW_I_HLIBG )
EndIf

//=========================================
//Informações dos itens do Pedido de Vendas
//=========================================
DBSelectArea("SZW")
DBSetOrder(1)
DBSeek(_cFil + _cNumPV)

_nCalcPesoBruto := 0
_nPesoBrut := MOMS050PESO(SZW->ZW_FILIAL,SZW->ZW_IDPED)

DBSelectArea("SZW")
DBSetOrder(1)
DBSeek(_cFil + _cNumPV)
SA1->(DBSetOrder(1))
SA1->(DBSeek(xFilial("SA1")+SZW->ZW_CLIENTE+SZW->ZW_LOJACLI))
If SA1->A1_SIMPNAC == "1"
	_lSimplNac := .T. // O cliente é optante do Simples Nacional
Else
	_lSimplNac := .F. // O cliente não é Optante do Simples Nacional
EndIf

While !SZW->(Eof()) .And. SZW->ZW_FILIAL == _cFil .And. AllTrim(SZW->ZW_IDPED) == AllTrim(_cNumPV)

	aAdd( _oProcess:oHtml:ValByName("Itens.cItem" 			), SZW->ZW_ITEM																	)
	aAdd( _oProcess:oHtml:ValByName("Itens.cProdPV" 		), SZW->ZW_PRODUTO								 									)
	aAdd( _oProcess:oHtml:ValByName("Itens.cDescPV"			), AllTrim(Posicione("SB1",1,xFilial("SB1")+ZW_PRODUTO, "B1_DESC"))															)
	aAdd( _oProcess:oHtml:ValByName("Itens.cNumPCli"		), SZW->ZW_PEDCLI																	)
	aAdd( _oProcess:oHtml:ValByName("Itens.nPrcVen"			), Transform(SZW->ZW_PRCVEN, "@E 999,999,999.999")									)
	aAdd( _oProcess:oHtml:ValByName("Itens.nQuantPV"		), Transform(SZW->ZW_SEGQTD, PesqPict("SZW","ZW_SEGQTD"))							)
	aAdd( _oProcess:oHtml:ValByName("Itens.cUM"				), SZW->ZW_2UM    																		)
	aAdd( _oProcess:oHtml:ValByName("Itens.nTotalPV"	   	), Transform(SZW->ZW_PRCVEN*SZW->ZW_QTDVEN, PesqPict("SC6","C6_VALOR"))								)

	SB1->(DBSetOrder(1))
	SB1->(DBSeek(xFilial("SB1")+ SZW->ZW_PRODUTO))

	//CALCULA O PESO BRUTO TOTAL DO PEDIDO DE VENDA
	_nPesBruTotItem:=(SB1->B1_PESBRU * SZW->ZW_QTDVEN)

	_nCalcPesoBruto += _nPesBruTotItem

	_ctab := SZW->ZW_TABELA

	_cQryDA1 := "SELECT DA1_PRCVEN, DA1_I_PRCA, DA1_I_PMFE, DA1_I_PMFR, DA1_I_PRFE, "
	_cQryDA1 += " DA1_I_PRF1,DA1_I_PMF1, DA1_I_PRF2, DA1_I_PMF2,DA1_I_PRF3, DA1_I_PMF3 "
	_cQryDA1 += "FROM " + RetSqlName("DA1") + " "
	_cQryDA1 += "WHERE DA1_FILIAL = '" + xFilial("DA1") + "' "
	_cQryDA1 += "  AND DA1_CODTAB = '" + _ctab + "' "
	_cQryDA1 += "  AND DA1_CODPRO = '" + SZW->ZW_PRODUTO + "' "
	_cQryDA1 += "  AND D_E_L_E_T_ = ' ' "

	If Select("TRBDA1") > 0
		TRBDA1->(DBCloseArea())
	EndIf
		
	_cQryDA1 := ChangeQuery(_cQryDA1)
	MPSysOpenQuery(_cQryDA1,"TRBDA1")
	
	DBSelectArea("TRBDA1")
	TRBDA1->(DBGoTop())

	Do Case
	Case AllTrim(SZW->ZW_TPVENDA) == "F"
		_cTpCarg := "F"
	Case AllTrim(SZW->ZW_TPVENDA) == "V"
		_cTpCarg := "V"
	EndCase

	If Empty(SZW->ZW_KIT)
		_aBlqprc := U_BLQPRC(SZW->ZW_PRODUTO,SZW->ZW_PRCVEN,SZW->ZW_FILIAL,  .F. ,SZW->ZW_TABELA,    .T.,      .T.,          0,           ,         ,SA1->A1_EST,         ,SZW->ZW_TPVENDA,_lSimplNac,_nPesoBrut,SZW->ZW_I_FXPES)

		_lPrcErr := _aBlqprc[1]
		_nPrecoIt:= _aBlqprc[4]
	Else
		_lPrcErr := .T.
		_nPrecoIt:=  SZW->ZW_PRCVEN
	EndIf 

	If _cEnvio ="ENVIO"
		aAdd( _oProcess:oHtml:ValByName("Itens.nPrcMin"			), Transform(_nPrecoIt, PesqPict("DA1","DA1_I_PRF1")))//IIf(_cTpCarg == "F", TRBDA1->DA1_PRCVEN, TRBDA1->DA1_I_PRFE)
	Else
		aAdd( _oProcess:oHtml:ValByName("Itens.nPrcMin"			), Transform(SZW->ZW_PRUNIT, PesqPict("DA1","DA1_I_PRF1"))					)
	EndIf

	_aVlrDesc	:= U_veriContrato( SZW->ZW_CLIENTE , SZW->ZW_LOJACLI , SZW->ZW_PRODUTO )
	aAdd( _oProcess:oHtml:ValByName("Itens.nPerCon"			), Transform(_aVlrDesc[1], PesqPict("SZW","ZW_I_PRCD"))		)
	aAdd( _oProcess:oHtml:ValByName("Itens.nPrcNet"			), Transform(SZW->ZW_I_PRNET, PesqPict("SZW","ZW_I_PRNET"))	)//Transform(SZW->ZW_PRCVEN - ( ( _aVlrDesc[1] * SZW->ZW_PRCVEN ) / 100 ), PesqPict("SC6","C6_VALOR")))
	aAdd( _oProcess:oHtml:ValByName("Itens.nPrcNetKG"		), Transform(SZW->ZW_I_PRNET / SB1->B1_PESO, PesqPict("SZW","ZW_I_PRNET"))	)

	If _lPrcErr
		aAdd( _oProcess:oHtml:ValByName("Itens.cCor"), "color=#FF0000" )//VERMELHO
	Else
		aAdd( _oProcess:oHtml:ValByName("Itens.cCor"), "color=#006400" )//VERDE
	EndIf

	DBSelectArea("TRBDA1")
	TRBDA1->(DBCloseArea())

	SZW->(DBSkip())
End

_oProcess:oHtml:ValByName("nPesoBruto"		         , TRansform(_nCalcPesoBruto ,PesqPict("SA1","A1_SALDUP",17,1)))

_oProcess:oHtml:ValByName("cGetSol"		, _cGetSol		)

//=========================================================================
// Informe o nome da função de retorno a ser executada quando a mensagem de
// respostas retornar ao Workflow:
//=========================================================================
_oProcess:bReturn := "U_MOMS050R"

//========================================================================
// Após ter repassado todas as informacões necessárias para o Workflow,
// execute o método Start() para gerar todo o processo e enviar a mensagem
// ao destinatário.
//========================================================================
_cMailID	:= _oProcess:Start("\workflow\emp01")
_cLink		:= _cMailID

If File("\workflow\emp01\" + _cMailID + ".htm")
	conout("Arquivo \workflow\emp01\" + _cMailID + ".htm criado com sucesso.")
Else
	conout("Arquivo \workflow\emp01\" + _cMailID + ".htm não encotrado.")
EndIf

//====================================
//Codigo do processo cadastrado no CFG
//==================================== 
_cCodProce := "LIBPVPRC"

//======================================================================
// Inicialize a classe TWFProcess e assinale a variável objeto oProcess:
//======================================================================
_oProcess := TWFProcess():New(_cCodProce,"Liberação PV Preço")

SZW->(DBGoTo(_nRecnoSZW)) // Ao rodar o comando TWFProcess():New, a tabela SZW estava sendo desposicionada. Esta instrução reposiciona a tabela SZW.

//=================================================================
// Criamos o link para o arquivo que foi gerado na tarefa anterior.  
//=================================================================
_oProcess:NewTask("LINK", "\workflow\htm\pvprecportal_link.htm")

_chtmlfile	:= _cLink + ".htm"
_cMailTo	:= "mailto:" + AllTrim(Posicione("WF7", 1, xFilial("WF7") + AllTrim(GetMV('MV_WFMLBOX')), "WF7_ENDERE"))
_chtmltexto := wfloadfile("\workflow\emp01\" + _chtmlfile )
_chtmltexto := StrTran( _chtmltexto, _cmailto, "WFHTTPRET.APL" )
wfsavefile("\workflow\emp"+cEmpAnt+"\" + _chtmlfile, _chtmltexto)
_cLink := _cHostWF + "emp01/" + _cLink + ".htm"

//=====================================
// Populo as variáveis do template html
//=====================================
_oProcess:oHtml:ValbyName("A_COORD"     , _cNomeApr)
_oProcess:oHtml:ValByName("cLogo"		, _cLogo)
_oProcess:oHtml:ValByName("A_FILIAL"	, _cFilial + " - " + FWFilialName(cEmpAnt,_cFilial,1))
_oProcess:oHtml:ValByName("A_PEDVEN"	, _cNumPV)
_oProcess:oHtml:ValByName("A_LINK"		, _cLink)
_oProcess:oHtml:ValByName("A_NOMREP"	, _cCodVen + " - " + Posicione("SA3",1, xFilial("SA3")+_cCodVen, "A3_NOME"))
_oProcess:oHtml:ValByName("A_CLIENTE"	, SA1->A1_COD + "/" + SA1->A1_LOJA + " - " + SA1->A1_NOME)
_oProcess:oHtml:ValByName("A_LIMCRED"	, TRansform(SA1->A1_LC,PesqPict("SA1","A1_LC",17,1)))
_oProcess:oHtml:ValByName("A_VLRPED"	, TRansform(_nValPed,PesqPict("SC6","C6_VALOR",17,1)))
_oProcess:oHtml:ValByName("A_TITPRO"	, Str(SA1->A1_TITPROT,3))
_oProcess:oHtml:ValByName("A_MCOMP"		, Transform(SA1->A1_MCOMPRA,PesqPict("SA1","A1_MCOMPRA",17,_nMCusto)))
_oProcess:oHtml:ValByName("A_MDUPL"		, Transform(SA1->A1_MAIDUPL,PesqPict("SA1","A1_MAIDUPL",17,_nMCusto)))
_oProcess:oHtml:ValByName("A_VLCRED"	, DToC(SA1->A1_VENCLC))
_oProcess:oHtml:ValByName("A_DTLIMLB"	, DToC(SToD("")))
_oProcess:oHtml:ValByName("A_PCOMP"		, DToC(SA1->A1_PRICOM))
_oProcess:oHtml:ValByName("A_UCOMP"		, DToC(SA1->A1_ULTCOM))
_oProcess:oHtml:ValByName("A_GRISC"		, SA1->A1_RISCO)
_oProcess:oHtml:ValByName("cGetSol"		, _cGetSol)

//================================================================
// Informamos o destinatário (aprovador) do email contendo o link.  
//================================================================
_cMailApr := AllTrim(_cMailApr)   

If !Empty(AllTrim(_cEmailAdd)) 
		_cMailApr += "," + _cEmailAdd
EndIf

_oProcess:cTo  :=  _cMailApr 
//===============================
// Informamos o assunto do email.    
//===============================  

_oProcess:cSubject	:= FWHttpEncode(_cAssunto)

_cMailID	:= _oProcess:fProcessId
_cTaskID	:= _oProcess:fTaskID

//=======================================================
// Iniciamos a tarefa e enviamos o email ao destinatário.
//=======================================================
_oProcess:Start()

FWRestArea(_aArea)
FWRestArea(_aAreaSZW)

Return _cLink

/*
===============================================================================================================================
Programa----------: RetBloq
Autor-------------: Jonathan Everton Torioni de Oliveira
Data da Criacao---: 13/03/2020
Descrição---------: Rotina para retornar pedidos bloqueados por preço.
Parametros--------: Nenhum
Retorno-----------: _aPedidos
===============================================================================================================================
*/
Static Function RetBloq(_cOp)

Local _aPedidos := {}
Local _dDtIni	:= DToS(SuperGetMV("IT_WFPINI",.F.,cTod("08/06/2020")))
Local cAlias    := GetNextAlias()

Default _cOp	:= "N"

If _cOp <> "B"
	BeginSql alias cAlias
		SELECT SZW.R_E_C_N_O_,SZW.ZW_EMISSAO EMISSAO, SZW.ZW_IDPED PEDIDO, SZW.ZW_ITEM ITEM FROM %Table:SZW% SZW
		WHERE SZW.D_E_L_E_T_  = ' '
		AND SZW.ZW_TIPO      <> '10'
		AND SZW.ZW_STATUS     = 'A'
		AND SZW.ZW_EMISSAO   >= %exp:_dDtIni%
		AND SZW.ZW_NUMPED     = ' '
		AND SZW.ZW_ENVWF      = ' '
		AND SZW.ZW_TPVENDA   <> ' '
		AND SZW.ZW_BLOPRC     = ' '
		UNION
		SELECT SZW.R_E_C_N_O_,SZW.ZW_EMISSAO EMISSAO, SZW.ZW_IDPED PEDIDO, SZW.ZW_ITEM ITEM FROM %Table:SZW% SZW
		WHERE SZW.D_E_L_E_T_  = ' '
		AND SZW.ZW_TIPO      <> '10'
		AND SZW.ZW_STATUS     = 'L'
		AND SZW.ZW_EMISSAO   >= %exp:_dDtIni%
		AND SZW.ZW_NUMPED     = ' '
		AND SZW.ZW_ENVWF     <> 'G'
		AND SZW.ZW_NIVELWF   <> 'E'
		AND SZW.ZW_TPVENDA   <> ' '
		AND SZW.ZW_BLOPRC     = ' '
		ORDER BY EMISSAO, PEDIDO, ITEM 
	EndSql
	
	While (cAlias)->(!Eof())
		aAdd(_aPedidos, (cAlias)->R_E_C_N_O_)
		(cAlias)->(DBSkip())
	EndDo
	
Else// Query de BONIFICAÇÃO
	BeginSql alias cAlias
		SELECT SZW.R_E_C_N_O_,SZW.ZW_EMISSAO EMISSAO, SZW.ZW_IDPED PEDIDO, SZW.ZW_ITEM ITEM FROM %Table:SZW% SZW
		WHERE SZW.D_E_L_E_T_ = ' '
		AND SZW.ZW_TIPO      = '10'
		AND SZW.ZW_BLOQ      = ' '
		AND SZW.ZW_STATUS    = 'A'
		AND SZW.ZW_EMISSAO  >= %exp:_dDtIni%
		AND SZW.ZW_NUMPED    = ' '
		AND SZW.ZW_ENVWF     = ' '
		AND SZW.ZW_TPVENDA  <> ' '
		UNION
		SELECT SZW.R_E_C_N_O_,SZW.ZW_EMISSAO EMISSAO, SZW.ZW_IDPED PEDIDO, SZW.ZW_ITEM ITEM FROM %Table:SZW% SZW
		WHERE SZW.D_E_L_E_T_ = ' '
		AND SZW.ZW_TIPO      = '10'
		AND SZW.ZW_STATUS    = 'L'
		AND SZW.ZW_EMISSAO  >= %exp:_dDtIni%
		AND SZW.ZW_NUMPED    = ' '
		AND SZW.ZW_ENVWF    <> 'G'
		AND SZW.ZW_NIVELWF  <> 'E'
		AND SZW.ZW_TPVENDA  <> ' '
		AND SZW.ZW_BLOQ      = ' '
		ORDER BY EMISSAO, PEDIDO, ITEM
	EndSql
	
	While (cAlias)->(!Eof())
		aAdd(_aPedidos, (cAlias)->R_E_C_N_O_)
		(cAlias)->(DBSkip())
	EndDo
EndIf
(cAlias)->(DBCloseArea())

Return _aPedidos 

/*
===============================================================================================================================
Programa----------: AtuSzw
Autor-------------: Jonathan Everton Torioni de Oliveira
Data da Criacao---: 11/05/2020
Descrição---------: Rotina para atualização da SZW após envio do e-mail de aprovação.
Parametros--------: Nenhum
Retorno-----------: 
===============================================================================================================================
*/
Static Function AtuSzw(_cFilped,_cIdPed,_cTipoAprov, _cLinkG, _cSit)

If SZW->(DBSeek(_cFilped+_cIdPed))
	While SZW->(!Eof() .And. SZW->ZW_IDPED == _cIdPed .And. SZW->ZW_FILIAL == _cFilped)
		RecLock("SZW", .F.)
		SZW->ZW_ENVWF   := _cTipoAprov
		SZW->ZW_DTENVIO := Date()
		SZW->ZW_HRENVIO := LEFT(TIME(),5)
		SZW->ZW_I_HTML  := _cLinkG

		If SZW->ZW_TIPO <> "10"
			If _cSit = "B"
				SZW->ZW_STATUS = 'P'
			ElseIf _cSit = "R"
				SZW->ZW_STATUS = 'Q'
			EndIf
		Else
							
		EndIf
		SZW->(MSUnLock())
		SZW->(DBSkip())
	EndDo
EndIf

Return

/*
===============================================================================================================================
Programa----------: MOMS50RP
Autor-------------: Jonathan Everton Torioni de Oliveira
Data da Criacao---: 09/06/2020
Descrição---------: Verifica pêndendicas de aprovação de pedidos portal e notifica Coordenadores e Gerentes
Parametros--------: Nenhum
Retorno-----------: 
===============================================================================================================================
*/
User Function MOMS50RP()

Local cQuery            := ""
Local _cCodProce        := ""
Local _cNomeApr         := ""
Local _cCodApr          := ""
Local _cLogo		    := ""
Local _cHostWF  	    := ""
Local _cMailApr         := ""
Local _cLink            := ""
Local _cArq             := ""
Local _cGetSol          := "Preço fora da tabela"
Local _cHtmlMode	    := "\Workflow\htm\pv_concluido.htm"
Local _cHtml    	    := "\Workflow\htm\pvprecportalavs_link.htm"
Local cAlias            := GetNextAlias()
Local aTables           := {"SZW","SA3"}
Local nData
Local _oProcess
Local _cMailID
Local _cTaskID

RPCSetType(3)
RpcSetEnv("01","01" ,,,, "SCHEDULE_WF_PENDENCIA_BLPRECO", aTables )
sleep( 5000 )

cQuery +=   " SELECT ZW_FILIAL, ZW_IDPED, ZW_ENVWF,"+;
	"ZW_DTENVIO, ZW_HRENVIO, A1_COD,A1_CGC , A1_LOJA,"+;
	"A1_NOME, A3_COD, A3_NOME,A1_LC,A1_TITPROT,A1_MCOMPRA,"+;
	"A1_MAIDUPL,A1_VENCLC,A1_PRICOM,A1_ULTCOM,A1_RISCO,"+;
	"A3_EMAIL, A3_SUPER FROM " + RetSqlName("SZW") + " ZW, " + RetSqlName("SA1") + " A1, " + RetSqlName("SA3") + " A3 "
cQuery += " WHERE ZW.D_E_L_E_T_ = ' ' "
cQuery += " AND ZW.ZW_ITEM = '1' "
cQuery += " AND ZW_BLOPRC = 'B' "
cQuery += " AND ZW_ENVWF <> ' ' "
cQuery += " AND ZW_DTENVIO BETWEEN '"+ DToS(Date()-3) + "' AND '" +DToS(Date()-1)+"' "
cQuery += " AND A1.D_E_L_E_T_ = ' ' "
cQuery += " AND A3.D_E_L_E_T_ = ' ' "
cQuery += " AND A1.A1_COD = ZW.ZW_CLIENTE "
cQuery += " AND A1.A1_LOJA = ZW.ZW_LOJACLI "
cQuery += " AND A3.A3_COD = ZW_VEND1 "

cQuery := ChangeQuery(cQuery)
MPSysOpenQuery(cQuery,cAlias)

SA3->(DBSetOrder(1))

_cHostWF  := SuperGetMV("IT_WFHOSTS",.T.,"http://wfteste.italac.com.br:4034/")
_cLogo    := _cHostWF + "htm/logo_novo.jpg"

While (cAlias)->(!Eof())
	_cMailApr := ""
	nData := Date() - SToD((cAlias)->ZW_DTENVIO)
	_cLink := Posicione("SZW",1,(cAlias)->ZW_FILIAL+(cAlias)->ZW_IDPED, "ZW_I_HTML")
	Do Case
	Case nData == 1 //Alerta sobre pedido

		If (cAlias)->ZW_ENVWF == 'C'
			_cCodApr  := Posicione("SA3",1,xFilial("SA3")+(cAlias)->A3_COD,"A3_SUPER")
			_cNomeApr := Posicione("SA3",1,xFilial("SA3")+_cCodApr, "A3_NOME")
			_cMailApr := SA3->A3_EMAIL
			_cAssunto := "Solicitação ao Coordenador para Liberação de Preço,  CNPJ " + MOMS050CPF((cAlias)->A1_CGC) + " " + AllTrim((cAlias)->A1_NOME) + " - " + (cAlias)->ZW_FILIAL + " " + AllTrim(FWFilialName(cEmpAnt,(cAlias)->ZW_FILIAL,1)) + " - PV Número: " + (cAlias)->ZW_IDPED
		Else
			_cCodApr  := Posicione("SA3",1,xFilial("SA3")+(cAlias)->A3_COD,"A3_GEREN")
			_cNomeApr := Posicione("SA3",1,xFilial("SA3")+_cCodApr, "A3_NOME")
			_cMailApr := SA3->A3_EMAIL
			_cAssunto := "Solicitação ao Gerente de Vendas para Liberação de Preço, CNPJ " + MOMS050CPF((cAlias)->A1_CGC) + " " + AllTrim((cAlias)->A1_NOME) + " - " + (cAlias)->ZW_FILIAL + " " + AllTrim(FWFilialName(cEmpAnt,(cAlias)->ZW_FILIAL,1)) + " - PV Número: " + (cAlias)->ZW_IDPED
		EndIf

		//====================================
		//Codigo do processo cadastrado no CFG
		//====================================
		_cCodProce := "LIBPVPRC"

		_oProcess := TWFProcess():New(_cCodProce,"Liberação de Preço Pedido de Vendas")

		_oProcess:NewTask("Liberacao_PVP", _cHtml)
		//=====================================
		// Populo as variáveis do template html
		//=====================================
		_oProcess:oHtml:ValbyName("A_COORD"     , _cNomeApr)
		_oProcess:oHtml:ValByName("cLogo"		, _cLogo)
		_oProcess:oHtml:ValByName("A_FILIAL"	, (cAlias)->ZW_FILIAL + " - " + FWFilialName(cEmpAnt,(cAlias)->ZW_FILIAL,1))
		_oProcess:oHtml:ValByName("A_PEDVEN"	, (cAlias)->ZW_IDPED)
		_oProcess:oHtml:ValByName("A_LINK"		, _cLink)
		_oProcess:oHtml:ValByName("A_NOMREP"	, (cAlias)->A3_COD + " - " + (cAlias)->A3_NOME)
		_oProcess:oHtml:ValByName("A_CLIENTE"	, (cAlias)->A1_COD + "/" + (cAlias)->A1_LOJA + " - " + (cAlias)->A1_NOME)
		_oProcess:oHtml:ValByName("A_LIMCRED"	, TRansform((cAlias)->A1_LC,PesqPict("SA1","A1_LC",17,1)))
		_oProcess:oHtml:ValByName("A_TITPRO"	, Str((cAlias)->A1_TITPROT,3))
		_oProcess:oHtml:ValByName("A_VLCRED"	, DToC(SToD((cAlias)->A1_VENCLC)))
		_oProcess:oHtml:ValByName("A_PCOMP"		, DToC(SToD((cAlias)->A1_PRICOM)))
		_oProcess:oHtml:ValByName("A_UCOMP"		, DToC(SToD((cAlias)->A1_ULTCOM)))
		_oProcess:oHtml:ValByName("A_GRISC"		, (cAlias)->A1_RISCO)
		_oProcess:oHtml:ValByName("cGetSol"		, _cGetSol)

		//================================================================
		// Informamos o destinatário (aprovador) do email contendo o link.
		//================================================================
		_oProcess:cTo  :=  _cMailApr  
		//===============================
		// Informamos o assunto do email. 
		//===============================
		_oProcess:cSubject	:= FWHttpEncode(_cAssunto) 

		_cMailID	:= _oProcess:fProcessId
		_cTaskID	:= _oProcess:fTaskID
		//=======================================================
		// Iniciamos a tarefa e enviamos o email ao destinatário.
		//=======================================================
		_oProcess:Start()

	Case nData > 1 //Rejeitar pedido

		If (cAlias)->ZW_ENVWF == 'C' .Or. Empty((cAlias)->ZW_ENVWF)
			_cCodApr := Posicione("SA3",1,xFilial("SA3")+(cAlias)->A3_COD,"A3_SUPER")
			_cTpApro := SA3->A3_I_TIPV
		ElseIf (cAlias)->ZW_ENVWF == 'G'
			_cCodApr := Posicione("SA3",1,xFilial("SA3")+(cAlias)->A3_COD,"A3_GEREN")
			cTpApro := SA3->A3_I_TIPV
		EndIf

		_cArq := StrTran(SubStr(_cLink,Rat("/",_cLink)+1),"/","\")

		//========================================================================================
		//Faz a cópia do arquivo de aprovação para .old, e cria o arquivo de processo já concluído
		//========================================================================================
		If File("\workflow\emp01\" + _cArq)
			If __CopyFile("\workflow\emp01\" + _cArq, "\workflow\emp01\" + _cArq + ".old")
				If __CopyFile(_cHtmlMode, "\workflow\emp01\" + _cArq)

					RecLock("SZW",.F.)
					SZW->ZW_MLIBPRC     := _cCodApr
					SZW->ZW_BLOPRC      := "R"
					SZW->ZW_HLIBP       := Time()
					SZW->ZW_DLIBP       := Date()
					SZW->ZW_ULIBP       := AllTrim(Posicione("SA3",1, xFilial("SA3")+_cCodApr, "A3_NOME"))
					SZW->ZW_MOTLP       := "PENDENTE APROVACAO COORDENADOR / GERENTE"
					SZW->ZW_STATUS      := "Q"
					SZW->ZW_IMPRIME     := '1'
					SZW->(MSUnLock())

					//GrVLZGT((cAlias)->ZW_FILIAL, _cCodApr, Date(), "R", _cTpApro, _cLink, (cAlias)->ZW_IDPED)
				Else
					conout("Problema na cópia de arquivo de conclusão.")
				EndIf
			Else
				conout("Não foi possível renomear o arquivo " + _cArq)
			EndIf
		EndIf
	EndCase
	(cAlias)->(DBSkip())
EndDo

RPCClearEnv()

Return

/*
===============================================================================================================================
Programa----------: MOMS050PESO
Autor-------------: Jerry
Data da Criacao---: 30/09/2021
Descrição---------: Rotina para calcular o Peso Bruto para validar Preço por Faixa de Peso
Parametros--------: Nenhum
Retorno-----------: 
===============================================================================================================================
*/
Static Function MOMS050PESO(_cFilped,_cIdPed)

Local _nPesBruTot := 0
Local _aAreaSZW		:= SZW->(GetArea())

If SZW->(DBSeek(_cFilped+_cIdPed))
	While SZW->(!Eof()  .And. SZW->ZW_FILIAL == _cFilped .And. SZW->ZW_IDPED == _cIdPed )

		SB1->(DBSetOrder(1))
		SB1->(DBSeek(xFilial("SB1")+ SZW->ZW_PRODUTO))

		_nPesBruTot:=(SB1->B1_PESBRU * SZW->ZW_QTDVEN)

		SZW->(DBSkip())
	EndDo
EndIf

FWRestArea(_aAreaSZW)

Return _nPesBruTot

/*
===============================================================================================================================
Programa----------: MOMS050REC
Autor-------------: Jerry
Data da Criacao---: 03/03/2022
Descrição---------: Rotina para Recusar pedido com mais de 24 horas sem Liberação ou sem Aprovação
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS050REC()

Local _cAliasSZW   := GetNextAlias()
Local _nqtdHoras   := 0
Local _nQtdRecusar := SuperGetMV("IT_TMPRECU",.F.,48) //Qtd de Dias para Recusar Pedido Portal
Local _cCalendario := SuperGetMV("IT_CALENRE",.F.,"002") //Qtd de Dias para Recusar Pedido Portal
Local _aPedRecusar := {} //Pedidos a Recusar
Local _cMotivo	   := ""
Local _nCont       := 0

//===============================================================
// Verifica se ja existe um arquivo com mesmo nome, se sim deleta.
//===============================================================

If Select(_cAliasSZW) <> 0

	(_cAliasSZW)->(DBCloseArea())

EndIf

BeginSql alias _cAliasSZW
SELECT 
	ZW_FILIAL, ZW_IDPED, ZW_EMISSAO, ZW_HORAINC, ZW_DATAAPR,ZW_HORAAPR , ZW_ENVWF, ZW_FECENT, ZW_STATUS , SA1.A1_NOME
	, VEND.A3_COD, VEND.A3_NOME
	, COOR.A3_COD, COOR.A3_NOME
	, GER.A3_COD,  GER.A3_NOME
	FROM %Table:SZW% SZW
	LEFT JOIN %Table:SA1% SA1  ON A1_COD = ZW_CLIENTE AND A1_LOJA = ZW_LOJACLI  
	LEFT JOIN %Table:SA3% VEND ON VEND.A3_COD = ZW_VEND1 
	LEFT JOIN %Table:SA3% COOR ON COOR.A3_COD = VEND.A3_SUPER 
	LEFT JOIN %Table:SA3% GER  ON GER.A3_COD   = VEND.A3_GEREN
	WHERE SZW.%NotDel%
	AND GER.%NotDel%
	AND COOR.%NotDel%
	AND VEND.%NotDel%
	AND SA1.%NotDel%
	AND zw_numped = ' ' 
	AND SZW.ZW_STATUS = 'A' 
	AND SZW.ZW_EMISSAO >= '20190101'
	AND SZW.ZW_NUMPED = ' ' 

	UNION 

	SELECT ZW_FILIAL, ZW_IDPED, ZW_EMISSAO, ZW_HORAINC, ZW_DATAAPR,ZW_HORAAPR , ZW_ENVWF, ZW_FECENT, ZW_STATUS, SA1.A1_NOME
	, VEND.A3_COD, VEND.A3_NOME
	, COOR.A3_COD, COOR.A3_NOME
	, GER.A3_COD,  GER.A3_NOME
	FROM %Table:SZW% SZW
	LEFT JOIN %Table:SA1% SA1  ON A1_COD       = ZW_CLIENTE AND A1_LOJA = ZW_LOJACLI  
	LEFT JOIN %Table:SA3% VEND ON VEND.A3_COD  = ZW_VEND1 
	LEFT JOIN %Table:SA3% COOR ON COOR.A3_COD  = VEND.A3_SUPER 
	LEFT JOIN %Table:SA3% GER  ON GER.A3_COD   = VEND.A3_GEREN
	where SZW.%NotDel%
	AND GER.%NotDel%
	AND COOR.%NotDel%
	AND VEND.%NotDel%
	AND SA1.%NotDel% 
	and zw_numped = ' ' 
	and zw_emissao >= '20210101'
	and zw_Status <>'R'
	and ZW_BLOPRC = 'B'
	AND SZW.ZW_NUMPED = ' ' 
	AND EXISTS (SELECT 'Y' FROM %Table:SZW% szw2 where szw2.%NotDel% and szw2.zw_idped =szw.zw_idped and szw2.ZW_BLOPRC = 'B' ) 
	GROUP BY ZW_FILIAL, ZW_IDPED, ZW_EMISSAO, ZW_HORAINC, ZW_DATAAPR,ZW_HORAAPR , ZW_ENVWF, ZW_FECENT , ZW_STATUS ,SA1.A1_NOME , VEND.A3_COD, VEND.A3_NOME , COOR.A3_COD, COOR.A3_NOME , GER.A3_COD, GER.A3_NOME 
	ORDER BY ZW_ENVWF, ZW_STATUS,ZW_EMISSAO,ZW_IDPED, ZW_EMISSAO, ZW_HORAINC, ZW_DATAAPR,ZW_HORAAPR , ZW_FECENT
EndSql

DBSelectArea(_cAliasSZW)
(_cAliasSZW)->(DBGoTop())

While (_cAliasSZW)->(!Eof())
	dDtEmissao := SToD((_cAliasSZW)->ZW_EMISSAO)
	nHoraEmis  := (_cAliasSZW)->ZW_HORAINC
	dDtAprov   := SToD((_cAliasSZW)->ZW_DATAAPR)
	nHoraAprov := (_cAliasSZW)->ZW_HORAAPR
	cHoraAtual := SubStr(TIME(),1,5)

	If (_cAliasSZW)->ZW_STATUS = 'A'

		_nqtdHoras := NGCALENHORA(SToD((_cAliasSZW)->ZW_EMISSAO),(_cAliasSZW)->ZW_HORAINC,Date(),SubStr(TIME(),1,5),AllTrim(_cCalendario))
		_cMotivo := "Recusado por falta de Avaliação do Coordenador. Tempo em Espera: "

	ElseIf (_cAliasSZW)->ZW_STATUS = "P"

		If Empty(AllTrim((_cAliasSZW)->ZW_DATAAPR))
			_nqtdHoras := NGCALENHORA(SToD((_cAliasSZW)->ZW_EMISSAO),(_cAliasSZW)->ZW_HORAINC,Date(),SubStr(TIME(),1,5),AllTrim(_cCalendario))
			_cMotivo := "Recusado por falta de Avaliação do Coordenador.  Tempo em Espera: "
		Else
			_nqtdHoras := NGCALENHORA(SToD((_cAliasSZW)->ZW_DATAAPR),(_cAliasSZW)->ZW_HORAAPR,Date(),SubStr(TIME(),1,5),AllTrim(_cCalendario))
			_cMotivo := "Recusado por falta de Avaliação do Gerente.  Tempo em Espera:"
		EndIf

	EndIf

	If _nqtdHoras >= _nQtdRecusar
		_cMotivo := _cMotivo + " " + U_MOMS50DT(_nqtdHoras) + " hh:mm "
		aAdd(_aPedRecusar, {(_cAliasSZW)->ZW_FILIAL,(_cAliasSZW)->ZW_IDPED,_cMotivo })
	EndIf
	(_cAliasSZW)->(DBSkip())

EndDo

DBSelectArea(_cAliasSZW)
DBCloseArea()

If Len(_aPedRecusar) > 0

	DBSelectArea("SZW")
	SZW->(DBSetOrder(1))

	For _nCont := 1 To Len(_aPedRecusar)
		U_AOM112RC(_aPedRecusar[_nCont][1], _aPedRecusar[_nCont][2],_aPedRecusar[_nCont][3])
	Next _nCont

EndIf

Return

/*
===============================================================================================================================
Programa----------: MOMS50DT
Autor-------------: Jerry
Data da Criacao---: 08/04/2022
Descrição---------: Rotina Calcular hora para recusar o pedido portal
Parametros--------: Nenhum
Retorno-----------: cHora
===============================================================================================================================
*/
User Function MOMS50DT(nValor, cSepar)

Local cHora := ""
Local cMinutos := ""
Default cSepar := ":"
Default nValor := -1

//Se For valores negativos, retorna a hora atual
If nValor < 0
	cHora := SubStr(Time(), 1, 5)
	cHora := StrTran(cHora, ':', cSepar)

	//Senão, transforma o valor numérico
Else
	cHora := AllTrim(Transform(nValor, "@E 999.99"))

	//Se o tamanho da hora For menor que 5, adiciona zeros a esquerda
	If Len(cHora) < 5
		cHora := Replicate('0', 5-Len(cHora)) + cHora
	EndIf

	//Fazendo tratamento para minutos
	cMinutos := SubStr(cHora, At(',', cHora)+1, 2)
	cMinutos := StrZero((Val(cMinutos)*60)/100, 2)

	//Atualiza a hora com os novos minutos
	cHora := SubStr(cHora, 1, At(',', cHora))+cMinutos

	//Atualizando o separador
	cHora := StrTran(cHora, ',', cSepar)
EndIf

Return cHora

Static Function MOMS050ALT()

Local _cAliasSC5   := GetNextAlias()
Local _cStatus    := '01'
Local _nConta     := 0

//===============================================================
// Verifica se ja existe um arquivo com mesmo nome, se sim deleta.
//===============================================================

If Select(_cAliasSC5) <> 0

	(_cAliasSC5)->(DBCloseArea())

EndIf

BeginSql alias _cAliasSC5
	
	SELECT SC5.r_e_c_n_o_ RECSC5, C5_EMISSAO, C5_I_ENVRD, C5_I_DTRET,C5_I_IDPED,C5_I_BLPRC ,C5_I_DTLIP,C5_I_HLIBP,C5_I_MOTLP,C5_I_ULIBP,C5_I_MLIBP,C5_I_PLIBP,C5_I_CDUSU, c5_nota, sc5.* 
	FROM siga.sc5010 SC5, SIGA.SZW010 SZWB
	WHERE SC5.d_e_l_e_t_ = ' '
	AND C5_EMISSAO >= '20220401'
	and C5_TIPO = 'N'
	and C5_I_ENVRD = 'S'
	AND C5_I_OPER IN ( '01','25','42','24','10','05')
	AND  SC5.C5_I_IDPED <> ' ' 
	AND SC5.C5_NOTA = ' '
	AND SZWB.ZW_FILIAL (+)= C5_FILIAL 
	AND SZWB.ZW_IDPED (+)= C5_I_IDPED 
	AND SZWB.ZW_ITEM (+)= 1
	ORDER BY SC5.C5_FILIAL, SC5.C5_NUM

EndSql

DBSelectArea(_cAliasSC5)
(_cAliasSC5)->(DBGoTop())

DBSelectArea("SC5")

While (_cAliasSC5)->(!Eof())

	SC5->(DBGoTo((_cAliasSC5)->RECSC5))

	_cStatus := U_STPEDIDO() //Função de análise do pedido de vendas no xfunoms

	If AllTrim(_cStatus) != AllTrim(SC5->C5_I_STATU)
		_nConta++

		If SC5->C5_I_ENVRD == "S"

			U_ENVSITPV()   //Envia interface de alteração de situação do pedido atual

		EndIf
	EndIf
	(_cAliasSC5)->(DBSkip())
EndDo

Return

/*
===============================================================================================================================
Programa----------: MOMS050B
Autor-------------: Igor Melgaço
Data da Criacao---: 03/06/2022
Descrição---------: Rotina responsavel pelo envio de workflow de liberação de Bonificação.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS050B(_cFil,_cCodVen, _cTipoApr, _cMailApr,_cNumPV,_RECNO, _cObsAprov,_cCodApr,_cTipoOP)

Static _nValAtraso	:= 0
Static _nValPed     := 0
Local _aArea		:= FWGetArea()
Local _aAreaSZW		:= SZW->(GetArea())
Local _cHostWF  	:= SuperGetMV("IT_WFHOSTS",.T.,"http://wfteste.italac.com.br:4034/")
Local _cLogo		:= _cHostWF + "htm/logo_novo.jpg"
Local _nMCusto		:= 0
Local _cCodiApr		:= ""
Local _cNomeApr		:= ""
Local _cFilApr		:= ""
Local _cFilial		:= _cFil
Local _nMCustoCli	:= 0
Local _nLimCred		:= 0
Local _nSalPed 		:= 0
Local _nSalPedL		:= 0
Local _nSalDupM		:= 0
Local _nLcFin		:= 0
Local _nSalFinM		:= 0
Local _nSalDup		:= 0
Local _nSalFin		:= 0
Local _nMoeda		:= 0
Local _cQryDA1		:= ""
Local _aVlrDesc		:= {}
Local _nRecnoSZW    := _RECNO
Local _lExecSelect  := .T.
Local _cGetSolB     := "Bonificação"
Local _cTipo        := Posicione("SA3",1,xFilial("SA3")+_cCodApr,"A3_I_TIPV")
Local _cTpcarg      := "F"
Local _cCalcSuframa := "NÃO"
Local _cCodCoord    := ""
Local _cCodGeren    := ""
Local _cTipoAg      := ""
Local _cEnvio       := "ENVIO"
Local _nCalcPesoBruto := 0
Local _nPesBruTotItem := 0

If IsInCallStack("U_MOMS050R") .Or. IsInCallStack("REENVAPR")//QUANDO APERTA OS BOTOES NO HTML
	_lExecSelect := .T.
EndIf

If IsInCallStack("U_MOMS050R") .Or. IsInCallStack("REENVAPR")//QUANDO APERTA OS BOTOES NO HTML
	_cEnvio :="REENVIO"
Else
	_cEnvio :="ENVIO"
EndIf

_cCodiApr	:= _cCodApr
_cNomeApr	:= Posicione("SA3",1, xFilial("SA3")+_cCodApr, "A3_NOME")
_cFilApr	:= _cFil

//Codigo do processo cadastrado no CFG
_cCodProce := "LIBPVBON"

// Arquivo html template utilizado para montagem da aprovação
_cHtmlMode := "\Workflow\htm\libportal_bon.htm"

// Inicialize a classe TWFProcess e assinale a variável objeto oProcess:
_oProcess := TWFProcess():New(_cCodProce,"Liberação de Bonificação")

SZW->(DBGoTo(_RECNO)) // Ao rodar o comando TWFProcess():New, a tabela SZW estava sendo desposicionada. Esta instrução reposiciona a tabela SZW.

_oProcess:NewTask("Liberacao_BON", _cHtmlMode)

//======================================
//Dados do cabeçalho do pedido de vendas
//======================================
_oProcess:oHtml:ValByName("cLogo", _cLogo)

//====================
//Dados do Solicitante
//====================
_oProcess:oHtml:ValByName("cCodSol"			, _cCodVen)
_oProcess:oHtml:ValByName("cNomSol"			, AllTrim(Posicione("SA3",1, xFilial("SA3")+_cCodVen, "A3_NOME")))
_oProcess:oHtml:ValByName("cMaiSol"			, SA3->A3_EMAIL)
_oProcess:oHtml:ValByName("cFilSol"			, _cFil + ' - ' + AllTrim(FWFilialName(cEmpAnt,_cFil,1)))
_oProcess:oHtml:ValByName("cNumPVSol"		, AllTrim(_cNumPV))
_oProcess:oHtml:ValByName("cDtAtu"			, DToC(Date()) + " - " + Time())
_oProcess:oHtml:ValByName("cTipo"           , IIf(_cTipo == "C","Coordenador", "Gerente"))

_oProcess:oHtml:ValByName("cTipOper"		, "BONIFICACAO"			)

_oProcess:oHtml:ValByName("cCodApr"			, _cCodiApr			)
_oProcess:oHtml:ValByName("cNomApr"			, AllTrim(_cNomeApr))

_oProcess:oHtml:ValByName("cCodRep"			, _cCodVen      			)
_oProcess:oHtml:ValByName("cNomRep"			, AllTrim(Posicione("SA3",1,xFilial("SA3")+_cCodVen, "A3_NOME"))   	)

_cCodCoord := Posicione("SA3",1, xFilial("SA3")+_cCodVen, "A3_SUPER")
_oProcess:oHtml:ValByName("cCodCoo"			, _cCodCoord  				)
_oProcess:oHtml:ValByName("cNomCoo"			, AllTrim(Posicione("SA3",1,xFilial("SA3")+_cCodCoord, "A3_NOME"))	)

_cCodGeren := Posicione("SA3",1, xFilial("SA3")+_cCodVen, "A3_GEREN")

_oProcess:oHtml:ValByName("cCodGer"			, _cCodGeren        			)
_oProcess:oHtml:ValByName("cNomGer"			, AllTrim(Posicione("SA3",1, xFilial("SA3")+_cCodGeren,"A3_NOME"))	)

//===============
//Dados do Pedido
//===============
_oProcess:oHtml:ValByName("cNumPV"			, _cNumPV		)
DBSelectArea("SZW")
SZW->(DBGoTo(_nRecnoSZW))

_oProcess:oHtml:ValByName("cTipoPV"			, Posicione("ZB4",1,xFilial("ZB4")+SZW->ZW_TIPO, "ZB4_DESCRI")				)


_oProcess:oHtml:ValByName("cFilPV"			, _cFil + " - " + AllTrim(FWFilialName(cEmpAnt,_cFil,1)))
_oProcess:oHtml:ValByName("cEmisPV"			, DToC(SZW->ZW_EMISSAO)	                            	)

//================
//Dados do Cliente
//================

DBSelectArea("SA1")
DBSetOrder(1)
DBSeek(xFilial("SA1") + SZW->ZW_CLIENTE + SZW->ZW_LOJACLI)

// Assunto da mensagem
If _cTipo == "C"
	_cAssunto := "Sol.Coord. para Liberação de BONIFICAÇÃO, Pedido Portal " + AllTrim(_cNumPV) + " CNPJ " + MOMS050CPF(SA1->A1_CGC) + " " + AllTrim(A1_NOME) + " - " + _cFilApr + " " + AllTrim(FWFilialName(cEmpAnt,_cFilApr,1))  + " --> " + _cEnvio
Else
	_cAssunto := "Sol.Gerente para Liberação de BONIFICAÇÃO, Pedido Portal " + AllTrim(_cNumPV) + " CNPJ " + MOMS050CPF(SA1->A1_CGC) + " " + AllTrim(A1_NOME) + " - " + _cFilApr + " " + AllTrim(FWFilialName(cEmpAnt,_cFilApr,1))  + " --> " + _cEnvio
EndIf

DBSelectArea("SE4")
DBSetOrder(1)
DBSeek(xFilial("SE4") + SA1->A1_COND)
_oProcess:oHtml:ValByName("cCondPgPad"		, SE4->E4_CODIGO + " - " + SE4->E4_DESCRI	)

If SA1->A1_CALCSUF = "I"
	_cCalculSuframa:= "ICMS"
ElseIf SA1->A1_CALCSUF = "S"
	_cCalculSuframa:= "SIM"
Else
	_cCalculSuframa:= "NÃO"
EndIf

_oProcess:oHtml:ValByName("cNomCli"			, SA1->A1_NOME				)
_oProcess:oHtml:ValByName("cNomRed"			, SA1->A1_NREDUZ			)
_oProcess:oHtml:ValByName("cCodCli"			, SA1->A1_COD				)
_oProcess:oHtml:ValByName("cLojCli"			, SA1->A1_LOJA				)
_oProcess:oHtml:ValByName("cCnpjCli"		, MOMS050CPF(SA1->A1_CGC)	)
_oProcess:oHtml:ValByName("cGrpVen"			, SA1->A1_GRPVEN + " - " + Posicione("ACY",1,xFilial("ACY") + SA1->A1_GRPVEN, "ACY_DESCRI")				)
_oProcess:oHtml:ValByName("cContatCli"		, SA1->A1_CONTATO			)
_oProcess:oHtml:ValByName("cFoneCli"		, SA1->A1_TEL				)
_oProcess:oHtml:ValByName("cEmailCli"		, SA1->A1_EMAIL				)
_oProcess:oHtml:ValByName("cCidCli"			, SA1->A1_MUN				)
_oProcess:oHtml:ValByName("cEstCli"			, SA1->A1_EST				)
_oProcess:oHtml:ValByName("cEndCli"			, SA1->A1_END				)
_oProcess:oHtml:ValByName("cAnaCre"			, SA1->A1_I_ACRED			)
_oProcess:oHtml:ValByName("cSuframa"		, _cCalcSuframa  			)

//========================
//Informarções Financeiras
//========================
DBSelectArea("SA1")
SA1->( DBSetOrder(1) )
SA1->( DBSeek( xFilial("SA1") + SZW->ZW_CLIENTE ) )

While SA1->(!Eof()) .And. SA1->A1_COD == SZW->ZW_CLIENTE

	_nMCustoCli	:= IIf( SA1->A1_MOEDALC > 0 , SA1->A1_MOEDALC	, Val(SuperGetMv("MV_MCUSTO")) )
	_nLimCred	+= xMoeda( SA1->A1_LC							, _nMCustoCli , _nMCusto , Date() )
	_nSalPed 	+= xMoeda( SA1->A1_SALPED + SA1->A1_SALPEDB		, _nMCustoCli , _nMCusto , Date() )
	_nSalPedL	+= xMoeda( SA1->A1_SALPEDL						, _nMCustoCli , _nMCusto , Date() )
	_nSalDupM	+= xMoeda( SA1->A1_SALDUPM						, _nMCustoCli , _nMCusto , Date() )
	_nLcFin		+= xMoeda( SA1->A1_LCFIN						, _nMCustoCli , _nMCusto , Date() )
	_nSalFinM	+= xMoeda( SA1->A1_SALFINM						, _nMCustoCli , _nMCusto , Date() )
	_nSalDup	+= SA1->A1_SALDUP
	_nSalFin	+= SA1->A1_SALFIN

	SA1->( DBSkip() )
EndDo

DBSelectArea("SA1")
SA1->( DBSetOrder(1) )
SA1->( DBSeek( xFilial("SA1") + SZW->ZW_CLIENTE + SZW->ZW_LOJACLI) )

_nMCusto 	:= IIf( SA1->A1_MOEDALC > 0 , SA1->A1_MOEDALC , Val( SuperGetMv("MV_MCUSTO") ) )
_nMoeda		:= 1
If _lExecSelect
	_nValAtraso:= MOMS050VSC( SZW->ZW_CLIENTE + SZW->ZW_LOJACLI )
	_nValPed   := MOMS050VT2( SZW->ZW_IDPED , _cFil , 1 )
EndIf

_oProcess:oHtml:ValByName("nLimCrd"			, TRansform(_nLimCred,PesqPict("SA1","A1_LC",17,1)))
_oProcess:oHtml:ValByName("nTitAber"		, TRansform(_nSalDup,PesqPict("SA1","A1_SALDUP",17,1)))
_oProcess:oHtml:ValByName("nTitVenc"		, TRansform(_nSalPedL,PesqPict("SA1","A1_SALPEDL",17,1)))
_oProcess:oHtml:ValByName("nSLimCrd"		, TRansform(_nLimCred-_nSaldupM-_nSalPedL,PesqPict("SA1","A1_SALDUP",17,1)))
_oProcess:oHtml:ValByName("nPedAtu"			, TRansform(_nValPed ,PesqPict("SA1","A1_SALDUP",17,1)))
_oProcess:oHtml:ValByName("nSalNFat"		, TRansform(_nSalPed ,PesqPict("SA1","A1_SALPED",17,1)))
_oProcess:oHtml:ValByName("nLimCChe"		, TRansform(_nLcFin ,PesqPict("SA1","A1_LCFIN",17,1)))
_oProcess:oHtml:ValByName("nSldChq"			, TRansform(_nSalFin ,PesqPict("SA1","A1_SALDUP",17,1)))
_oProcess:oHtml:ValByName("nTitProt"		, Str(SA1->A1_TITPROT,3))
_oProcess:oHtml:ValByName("nChqDev"			, Str(SA1->A1_CHQDEVO,3))
_oProcess:oHtml:ValByName("nMComp"			, Transform(SA1->A1_MCOMPRA ,PesqPict("SA1","A1_MCOMPRA",17,_nMCusto)))
_oProcess:oHtml:ValByName("nMDuplic"		, Transform(SA1->A1_MAIDUPL ,PesqPict("SA1","A1_MAIDUPL",17,_nMCusto)))
_oProcess:oHtml:ValByName("nMAtras"			, Transform(SA1->A1_METR ,PesqPict("SA1","A1_METR",7)))
_oProcess:oHtml:ValByName("cVenLCr"			, DToC(SA1->A1_VENCLC))
_oProcess:oHtml:ValByName("cDtLiLib"		, DToC(SToD("")))
_oProcess:oHtml:ValByName("nAtraAtu"		, TRansform(_nValAtraso ,PesqPict("SA1","A1_SALDUP",17,1)))

//==================
//Posição do Cliente
//==================

_oProcess:oHtml:ValByName("nLimCrl"			, TRansform(SA1->A1_LC,PesqPict("SA1","A1_LC",14,_nMCusto)))
_oProcess:oHtml:ValByName("nSldHist"		, TRansform(SA1->A1_SALDUP,PesqPict("SA1","A1_SALDUP",14,1)))
_oProcess:oHtml:ValByName("nLimcSec"		, TRansform(Round(Noround(xMoeda(SA1->A1_LCFIN,_nMcusto,1,dDataBase,MsDecimais(1)+1),2),MsDecimais(1)),PesqPict("SA1","A1_LCFIN",14,1)),TRansform(SA1->A1_LCFIN,PesqPict("SA1","A1_LCFIN",14,_nMcusto)))
_oProcess:oHtml:ValByName("nSldLcSe"		, TRansform(SA1->A1_SALFIN,PesqPict("SA1","A1_SALFIN",14,1)))
_oProcess:oHtml:ValByName("nMaiCom"			, TRansform(Round(Noround(xMoeda(SA1->A1_MCOMPRA, _nMcusto ,1, dDataBase,MsDecimais(1)+1),2),MsDecimais(1)),PesqPict("SA1","A1_MCOMPRA",14,1)),TRansform(SA1->A1_MCOMPRA,PesqPict("SA1","A1_MCOMPRA",14,_nMcusto)))
_oProcess:oHtml:ValByName("nMaiSld"			, TRansform(Round(Noround(xMoeda(SA1->A1_MSALDO, _nMcusto ,1, dDataBase,MsDecimais(1)+1 ),2),MsDecimais(1)),PesqPict("SA1","A1_MSALDO",14,1)))
_oProcess:oHtml:ValByName("cPriCom"			, DToC(SA1->A1_PRICOM))
_oProcess:oHtml:ValByName("cUltCom"			, DToC(SA1->A1_ULTCOM))
_oProcess:oHtml:ValByName("nMaiAtr"			, Transform(SA1->A1_MATR,PesqPict("SA1","A1_MATR",14)))
_oProcess:oHtml:ValByName("nMedAtr"			, PADC(Str(SA1->A1_METR,7,2),22))
_oProcess:oHtml:ValByName("cGrauRis"		, SA1->A1_RISCO)


//===============================
//Informações do Pedido de Vendas
//===============================
If SZW->ZW_TPFRETE == "C"
	_oProcess:oHtml:ValByName("cFrete"			, "CIF"					)
ElseIf SZW->ZW_TPFRETE == "F"
	_oProcess:oHtml:ValByName("cFrete"			, "FOB"					)
ElseIf SZW->ZW_TPFRETE == "T"
	_oProcess:oHtml:ValByName("cFrete"			, "TERCEIROS"			)
ElseIf SZW->ZW_TPFRETE == "S"
	_oProcess:oHtml:ValByName("cFrete"			, "Sem Frete"			)
EndIf

_cTipoAg:=SZW->ZW_I_AGEND+" - "+U_TipoEntrega(SZW->ZW_I_AGEND)

_oProcess:oHtml:ValByName("cTpCarga"		, IIf(SZW->ZW_TIPCAR == "1", SZW->ZW_TIPCAR + " - Paletizada", IIf(SZW->ZW_TIPCAR == "2", SZW->ZW_TIPCAR + " - Batida", "")))
_oProcess:oHtml:ValByName("nQtdChap"		, SZW->ZW_CHAPA  			)
_oProcess:oHtml:ValByName("cHrDescg"		, SZW->ZW_HORDES			)
_oProcess:oHtml:ValByName("nCusCarg"		, "0"						)
_oProcess:oHtml:ValByName("dDtEntrega"		, SZW->ZW_FECENT 			)
_oProcess:oHtml:ValByName("cHrEntrega"		, SZW->ZW_HOREN  			)
_oProcess:oHtml:ValByName("cSenhaEntr"		, SZW->ZW_SENHA    			)
_oProcess:oHtml:ValByName("cTipoAgenda"		, _cTipoAg       			)
_oProcess:oHtml:ValByName("cCarga"          , IIf(AllTrim(SZW->ZW_TPVENDA) == "F" .And. SZW->ZW_TPVENDA != "", " F - Fechada", " V - Fracionada"))
_oProcess:oHtml:ValByName("cEnvio"			, _cEnvio       			)
_oProcess:oHtml:ValByName("cMensNF"			, SZW->ZW_MENNOTA			)
_oProcess:oHtml:ValByName("cObsPed"			, SZW->ZW_OBSCOM 			)

//=========================================================================
// Dados de Aprovação quando Retorno é do Coordenador
//=========================================================================
If SZW->ZW_ENVWF = 'C'
	_oProcess:oHtml:ValByName("cGetObsCoord", _cObsAprov	     	)
	_oProcess:oHtml:ValByName("cDataAprov"	, DToC(Date())	)
	_oProcess:oHtml:ValByName("cHoraAprov"	, Time()		)
Else
	_oProcess:oHtml:ValByName("cGetObsCoord", SZW->ZW_ULIBP )
	_oProcess:oHtml:ValByName("cDataAprov"	, SZW->ZW_HLIBP	)
	_oProcess:oHtml:ValByName("cHoraAprov"	, SZW->ZW_DLIBP   )
EndIf

//=========================================
//Informações dos itens do Pedido de Vendas
//=========================================
DBSelectArea("SZW")
DBSetOrder(1)
DBSeek(_cFil + _cNumPV)

_nCalcPesoBruto := 0
_nPesoBrut := MOMS050PESO(SZW->ZW_FILIAL,SZW->ZW_IDPED)
DBSelectArea("SZW")
DBSetOrder(1)
DBSeek(_cFil + _cNumPV)
SA1->(DBSetOrder(1))
SA1->(DBSeek(xFilial("SA1")+SZW->ZW_CLIENTE+SZW->ZW_LOJACLI))
If SA1->A1_SIMPNAC == "1"
	_lSimplNac := .T. // O cliente é optante do Simples Nacional
Else
	_lSimplNac := .F. // O cliente não é Optante do Simples Nacional
EndIf

While !SZW->(Eof()) .And. SZW->ZW_FILIAL == _cFil .And. AllTrim(SZW->ZW_IDPED) == AllTrim(_cNumPV)

	aAdd( _oProcess:oHtml:ValByName("Itens.cItem" 			), SZW->ZW_ITEM																		)
	aAdd( _oProcess:oHtml:ValByName("Itens.cProdPV" 		), SZW->ZW_PRODUTO								 									)
	aAdd( _oProcess:oHtml:ValByName("Itens.cDescPV"			), AllTrim(Posicione("SB1",1,xFilial("SB1")+ZW_PRODUTO, "B1_DESC"))					)
	aAdd( _oProcess:oHtml:ValByName("Itens.cNumPCli"		), SZW->ZW_PEDCLI																	)
	aAdd( _oProcess:oHtml:ValByName("Itens.nPrcVen"			), Transform(SZW->ZW_PRCVEN, "@E 999,999,999.999")									)
	aAdd( _oProcess:oHtml:ValByName("Itens.nQuantPV"		), Transform(SZW->ZW_SEGQTD, PesqPict("SZW","ZW_SEGQTD"))							)
	aAdd( _oProcess:oHtml:ValByName("Itens.cUM"				), SZW->ZW_2UM    																	)
	aAdd( _oProcess:oHtml:ValByName("Itens.nTotalPV"	   	), Transform(SZW->ZW_PRCVEN*SZW->ZW_QTDVEN, PesqPict("SC6","C6_VALOR"))				)

	SB1->(DBSetOrder(1))
	SB1->(DBSeek(xFilial("SB1")+ SZW->ZW_PRODUTO))

	//CALCULA O PESO BRUTO TOTAL DO PEDIDO DE VENDA
	_nPesBruTotItem:=(SB1->B1_PESBRU * SZW->ZW_QTDVEN)

	_nCalcPesoBruto += _nPesBruTotItem

	_ctab := SZW->ZW_TABELA

	_cQryDA1 := "SELECT DA1_PRCVEN, DA1_I_PRCA, DA1_I_PMFE, DA1_I_PMFR, DA1_I_PRFE, "
	_cQryDA1 += " DA1_I_PRF1,DA1_I_PMF1, DA1_I_PRF2, DA1_I_PMF2,DA1_I_PRF3, DA1_I_PMF3 "
	_cQryDA1 += "FROM " + RetSqlName("DA1") + " "
	_cQryDA1 += "WHERE DA1_FILIAL = '" + xFilial("DA1") + "' "
	_cQryDA1 += "  AND DA1_CODTAB = '" + _ctab + "' "
	_cQryDA1 += "  AND DA1_CODPRO = '" + SZW->ZW_PRODUTO + "' "
	_cQryDA1 += "  AND D_E_L_E_T_ = ' ' "

	If Select("TRBDA1") > 0
		TRBDA1->(DBCloseArea())
	EndIf
	
	_cQryDA1 := ChangeQuery(_cQryDA1)
	MPSysOpenQuery(_cQryDA1,"TRBDA1")

	DBSelectArea("TRBDA1")
	TRBDA1->(DBGoTop())

	Do Case
	Case AllTrim(SZW->ZW_TPVENDA) == "F"
		_cTpCarg := "F"
	Case AllTrim(SZW->ZW_TPVENDA) == "V"
		_cTpCarg := "V"
	EndCase

	
	
	_aBlqprc := U_BLQPRC(SZW->ZW_PRODUTO,SZW->ZW_PRCVEN,SZW->ZW_FILIAL,  .F. ,SZW->ZW_TABELA,    .T.,      .T.,          0,           ,         ,SA1->A1_EST,         ,SZW->ZW_TPVENDA,_lSimplNac,_nPesoBrut,SZW->ZW_I_FXPES)
	_lPrcErr := _aBlqprc[1]
	_nPrecoIt:= _aBlqprc[4]

	If _cEnvio ="ENVIO"
		aAdd( _oProcess:oHtml:ValByName("Itens.nPrcMin"			), Transform(_nPrecoIt, PesqPict("SC6","C6_VALOR")))//IIf(_cTpCarg == "F", TRBDA1->DA1_PRCVEN, TRBDA1->DA1_I_PRFE)
	Else
		aAdd( _oProcess:oHtml:ValByName("Itens.nPrcMin"			), Transform(SZW->ZW_PRUNIT, PesqPict("SC6","C6_VALOR"))					)
	EndIf

	_aVlrDesc	:= U_veriContrato( SZW->ZW_CLIENTE , SZW->ZW_LOJACLI , SZW->ZW_PRODUTO )
	aAdd( _oProcess:oHtml:ValByName("Itens.nPerCon"			), Transform(_aVlrDesc[1], PesqPict("SZW","ZW_I_PRCD"))					)
	aAdd( _oProcess:oHtml:ValByName("Itens.nPrcNet"			), Transform(SZW->ZW_I_PRNET, PesqPict("SZW","ZW_I_PRNET"))	) 
	aAdd( _oProcess:oHtml:ValByName("Itens.nPrcNetKG"		), Transform(SZW->ZW_I_PRNET / SB1->B1_PESO, PesqPict("SZW","ZW_I_PRNET"))	)
	
	If _lPrcErr
		aAdd( _oProcess:oHtml:ValByName("Itens.cCor"), "color=#FF0000" )//VERMELHO
	Else
		aAdd( _oProcess:oHtml:ValByName("Itens.cCor"), "color=#006400" )//VERDE
	EndIf

	DBSelectArea("TRBDA1")
	TRBDA1->(DBCloseArea())

	SZW->(DBSkip())
End

_oProcess:oHtml:ValByName("nPesoBruto"		         , TRansform(_nCalcPesoBruto ,PesqPict("SA1","A1_SALDUP",17,1)))

_oProcess:oHtml:ValByName("cGetSol"		, _cGetSolB		)

//=========================================================================
// Informe o nome da função de retorno a ser executada quando a mensagem de
// respostas retornar ao Workflow:
//=========================================================================
_oProcess:bReturn := "U_MOMS050R"

//========================================================================
// Após ter repassado todas as informacões necessárias para o Workflow,
// execute o método Start() para gerar todo o processo e enviar a mensagem
// ao destinatário.
//========================================================================
_cMailID	:= _oProcess:Start("\workflow\emp01")
_cLink		:= _cMailID

If File("\workflow\emp01\" + _cMailID + ".htm")
	conout("Arquivo \workflow\emp01\" + _cMailID + ".htm criado com sucesso.")
Else
	conout("Arquivo \workflow\emp01\" + _cMailID + ".htm não encotrado.")
EndIf

//====================================
//Codigo do processo cadastrado no CFG
//====================================
_cCodProce := "LIBPVPRC"

//======================================================================
// Inicialize a classe TWFProcess e assinale a variável objeto oProcess:
//======================================================================
_oProcess := TWFProcess():New(_cCodProce,"Liberação PV Bonificação")

SZW->(DBGoTo(_nRecnoSZW)) // Ao rodar o comando TWFProcess():New, a tabela SZW estava sendo desposicionada. Esta instrução reposiciona a tabela SZW.

//=================================================================
// Criamos o link para o arquivo que foi gerado na tarefa anterior.
//=================================================================
_oProcess:NewTask("LINK", "\workflow\htm\pvbonportal_link.htm")

_chtmlfile	:= _cLink + ".htm"
_cMailTo	:= "mailto:" + AllTrim(Posicione("WF7", 1, xFilial("WF7") + AllTrim(GetMV('MV_WFMLBOX')), "WF7_ENDERE"))
_chtmltexto := wfloadfile("\workflow\emp01\" + _chtmlfile )
_chtmltexto := StrTran( _chtmltexto, _cmailto, "WFHTTPRET.APL" )
wfsavefile("\workflow\emp"+cEmpAnt+"\" + _chtmlfile, _chtmltexto)
_cLink := _cHostWF + "emp01/" + _cLink + ".htm"

//=====================================
// Populo as variáveis do template html
//=====================================
_oProcess:oHtml:ValbyName("A_COORD"     , _cNomeApr)
_oProcess:oHtml:ValByName("cLogo"		, _cLogo)
_oProcess:oHtml:ValByName("A_FILIAL"	, _cFilial + " - " + FWFilialName(cEmpAnt,_cFilial,1))
_oProcess:oHtml:ValByName("A_PEDVEN"	, _cNumPV)
_oProcess:oHtml:ValByName("A_LINK"		, _cLink)
_oProcess:oHtml:ValByName("A_NOMREP"	, _cCodVen + " - " + Posicione("SA3",1, xFilial("SA3")+_cCodVen, "A3_NOME"))
_oProcess:oHtml:ValByName("A_CLIENTE"	, SA1->A1_COD + "/" + SA1->A1_LOJA + " - " + SA1->A1_NOME)
_oProcess:oHtml:ValByName("A_LIMCRED"	, TRansform(SA1->A1_LC,PesqPict("SA1","A1_LC",17,1)))
_oProcess:oHtml:ValByName("A_VLRPED"	, TRansform(_nValPed,PesqPict("SC6","C6_VALOR",17,1)))
_oProcess:oHtml:ValByName("A_TITPRO"	, Str(SA1->A1_TITPROT,3))
_oProcess:oHtml:ValByName("A_MCOMP"		, Transform(SA1->A1_MCOMPRA,PesqPict("SA1","A1_MCOMPRA",17,_nMCusto)))
_oProcess:oHtml:ValByName("A_MDUPL"		, Transform(SA1->A1_MAIDUPL,PesqPict("SA1","A1_MAIDUPL",17,_nMCusto)))
_oProcess:oHtml:ValByName("A_VLCRED"	, DToC(SA1->A1_VENCLC))
_oProcess:oHtml:ValByName("A_DTLIMLB"	, DToC(SToD("")))
_oProcess:oHtml:ValByName("A_PCOMP"		, DToC(SA1->A1_PRICOM))
_oProcess:oHtml:ValByName("A_UCOMP"		, DToC(SA1->A1_ULTCOM))
_oProcess:oHtml:ValByName("A_GRISC"		, SA1->A1_RISCO)
_oProcess:oHtml:ValByName("cGetSol"		, _cGetSolB)
_oProcess:oHtml:ValByName("A_RODAP"		, cEnvSrv)

If SZW->ZW_ENVWF = 'C'
	_oProcess:oHtml:ValByName("cGetObsCoord"		, _cObsAprov)
Else
	_oProcess:oHtml:ValByName("cGetObsCoord"		, " " )
End

//================================================================
// Informamos o destinatário (aprovador) do email contendo o link.
//================================================================
	
_oProcess:cTo  := _cMailApr  
//=============================== 
// Informamos o assunto do email.
//===============================

_oProcess:cSubject	:= FWHttpEncode(_cAssunto)

_cMailID	:= _oProcess:fProcessId
_cTaskID	:= _oProcess:fTaskID

//=======================================================
// Iniciamos a tarefa e enviamos o email ao destinatário.
//=======================================================
_oProcess:Start()

FWRestArea(_aArea)
FWRestArea(_aAreaSZW)

Return _cLink
