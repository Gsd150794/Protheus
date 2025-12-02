#Include "ap5mail.ch"
#Include "tbiconn.ch"
#Include "TOTVS.ch"  

#DEFINE ENTERBR "<br>"

/*
===============================================================================================================================
Programa----------: MCOM004
Autor-------------: Darcio Ribeiro Sporl
Data da Criacao---: 14/01/2016
Descrição---------: Rotina responsavel pelo envio de workflow de pedido de compras
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MCOM004

Local _aTables		:= {"SCR","SC1","SC7","SD1","ZZ7","ZZ8","ZZI","CTT","ZZL","ZP1"}
Local _lCriaAmb		:= .F.
Local _cAliasSCR	:= ""
Local lWFHTML		:= .T.

Private _cHostWF	:= ""
Private _dDtIni		:= ""

/*
//==============================================================¿
//Verifica a necessidade de criar um ambiente, caso nao esteja 
//criado anteriormente um ambiente, pois ocorrera erro.        
//==============================================================Ù
*/
If Select("SX3") <= 0
	_lCriaAmb:= .T.
EndIf                           
             
If _lCriaAmb              

	//Nao consome licensas
	RPCSetType(3)

	//seta o ambiente com a empresa 01 filial 01   	 
	RpcSetEnv("01","01",,,,"SCHEDULE_WF_PEDIDOS",_aTables)

    DBSelectArea("ZP1")
EndIf 

//grava log de uso

_cHostWF 	:= SuperGetMV("IT_WFHOSTS",.F.,"http://wfteste.italac.com.br:4034/")
_dDtIni		:= DToS(SuperGetMV("IT_WFDTINI",.F.,"26/11/2025"))

lWFHTML	:= GetMv("MV_WFHTML")

PutMV("MV_WFHTML",.T.)

If Type("_cAliasSCR") == "C" .And. select(_cAliasSCR) > 0

	(_cAliasSCR)->(DBCloseArea())
	
EndIf

_cAliasSCR := GetNextAlias()
MCOM004Q(1,_cAliasSCR,"","","","","","","","","","")

DBSelectArea(_cAliasSCR)
(_cAliasSCR)->(DBGoTop())

If !(_cAliasSCR)->(Eof())
	MONTAPED(_cAliasSCR)
EndIf

DBSelectArea(_cAliasSCR)
(_cAliasSCR)->(DBCloseArea())          

PutMV("MV_WFHTML",.T.)

If _lCriaAmb
	
	//Limpa o ambiente, liberando a licença e fechando as conexoes
	RpcClearEnv()  
	
EndIf

Return        

/*
===============================================================================================================================
Programa----------: MCOM004R
Autor-------------: Darcio Ribeiro Sporl
Data da Criacao---: 14/01/2016
Descrição---------: Rotina responsável pela execução do retorno do workflow
Parametros--------: _oProcess - Processo inicializado do workflow
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MCOM004R( _oProcess )
Local _cFilial		:= SubStr(_oProcess:oHtml:RetByName("cNomFil"),1,2)
Local _cNumPC		:= _oProcess:oHtml:RetByName("NumPC")    
Local _cCRObs		:= AllTrim(Upper(_oProcess:oHtml:RetByName("CR_OBS")))
Local _cArqHtm		:= SubStr(_oProcess:oHtml:RetByName("WFMAILID"),3,Len(_oProcess:oHtml:RetByName("WFMAILID")))
Local _sDtLiber		:= DToS(Date())
Local _sDtAviso		:= DToS(Date())
Local _cHrLiber		:= SubStr(Time(),1,5)
Local _cSituacao	:= "Q"
Local _cHtmlMode	:= "\Workflow\htm\pc_concluido.htm"
Local cNivelAP		:= _oProcess:oHtml:RetByName("cNivelAP")
Local _cUser		:= _oProcess:oHtml:RetByName("cUser")
Local cBloq			:= ""
Local _cOpcao		:= Upper(_oProcess:oHtml:RetByName("opcao"))        
Local _cRastrear    := "Retorno da Aprovacao do PC " + _cFilial + " " + _cNumPC
Local _cQrySCR		:= ""
Local _cPergPai		:= ""
Local cQry			:= ""
Local _cQryALC		:= ""

cFilAnt:=_cFilial
FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00401"/*cMsgId*/, "MCOM00401 - Executando MCOM004R() - _cOpcao = "+_cOpcao+" / _cRastrear = "+_cRastrear+" / cFilAnt = "+cFilAnt/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
//na variavel vem escrito "APROVAR (Aguarde...)"
If "APROVAR" $ _cOpcao 
    _cOpcao:="APROVAR"
	_cSituacao:= "L"
ElseIf "AGUARDAR 5 DIAS" $ _cOpcao 
    _cOpcao:="AGUARDAR 5 DIAS"
	_cSituacao:= "A"
	_sDtAviso		:= DToS((Date()+5))
ElseIf "AGUARDAR 10 DIAS" $ _cOpcao 
    _cOpcao:="AGUARDAR 10 DIAS"
	_cSituacao:= "A"
	_sDtAviso		:= DToS((Date()+10))	
ElseIf "AGUARDAR 20 DIAS" $ _cOpcao 
    _cOpcao:="AGUARDAR 20 DIAS"
	_cSituacao:= "A"
	_sDtAviso		:= DToS((Date()+20))	
ElseIf "REJEITAR" $ _cOpcao 
    _cOpcao:="REJEITAR"
	_cSituacao:= "B"
ElseIf "QUESTIONAR" $ _cOpcao 
    _cOpcao:="QUESTIONAR"
	_cSituacao:= "Q"
EndIf

If Empty(_cCRObs)
	_cCRObs:= _cOpcao
EndIf

If _cSituacao == "A"
	_cCRObs += " A PARTIR DE " + DToC(Date())
EndIf

_cQryALC := "SELECT COUNT(*) AS CONTADOR "
_cQryALC += "FROM " + RetSqlName("SC7") + " SC7 "
_cQryALC += "JOIN " + RetSqlName("SCR") + " SCR ON CR_FILIAL = C7_FILIAL AND CR_NUM = C7_NUM AND SCR.D_E_L_E_T_ = ' ' "
_cQryALC += "WHERE CR_FILIAL	= '" + _cFilial + "' AND CR_TIPO = 'PC' AND CR_NUM =  '" + _cNumPC + "' "
_cQryALC += "  AND C7_NUM		= '" + _cNumPC + "' "
_cQryALC += "  AND SC7.D_E_L_E_T_ = ' ' "

dbUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQryALC ) , "TRBALC" , .T., .F. )
FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00402"/*cMsgId*/, 'MCOM00402 - Executando MCOM004R() - TRBALC->CONTADOR = ' + AllTrim(Str(TRBALC->CONTADOR))+" / _cSituacao = "+_cSituacao+" / _cOpcao = "+_cOpcao+" / _cCRObs = "+_cCRObs/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
DBSelectArea("TRBALC")
TRBALC->(DBGoTop())


If TRBALC->CONTADOR > 0

	//=======================================================
	//Atualiza rastreamento de aprovação do pedido de compras
	//=======================================================
	RastreiaWF(_oProcess:fProcessId + '.' + _oProcess:fTaskID , _oProcess:fProcCode, "1002", _cRastrear , "")
	
	_cQrySCR := "SELECT CR_STATUS "
	_cQrySCR += "FROM " + RetSqlName("SCR") + " "
	_cQrySCR += "WHERE CR_FILIAL	= '" + _cFilial + "' "
	_cQrySCR += "  AND CR_USER		= '" + _cUser + "' "
	_cQrySCR += "  AND CR_NUM = '" + _cNumPC + "' AND CR_TIPO = 'PC' "
	_cQrySCR += "  AND D_E_L_E_T_ = ' ' "
	
	dbUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQrySCR ) , "TRBSCR" , .T., .F. )
	FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00403"/*cMsgId*/, 'MCOM00403 -TRBSCR->CR_STATUS = ' + TRBSCR->CR_STATUS+" / _cSituacao = "+_cSituacao+" / _cOpcao = "+_cOpcao/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	DBSelectArea("TRBSCR")
	TRBSCR->(DBGoTop())
	
	
	If TRBSCR->CR_STATUS <> "03" .And. TRBSCR->CR_STATUS <> "04"//'03' - Aprovado / '04' - Bloqueado
	
		//==============================================================================================
		//Chama query para atualização do registro do pedido de compras, com as informações da aprovação
		//==============================================================================================
		If _cSituacao = "A" //Situacao Aguardar nDias
			MCOM004Q(2,"",_cFilial,_cNumPC,"1002","4","",_cSituacao,_cCRObs,_sDtLiber,_cHrLiber,"", _oProcess:fProcessId,cNivelAP,@cBloq,_sDtAviso)
			cBloq := _cOpcao
		ElseIf _cSituacao == "Q"
			_cHtmlMode:= "\Workflow\htm\pc_conc_perg.htm"//htm criado dia 13/12/2021
			MCOM004Q(9,"",_cFilial,_cNumPC,"1002","2","",_cSituacao,_cCRObs,_sDtLiber,_cHrLiber,"", _oProcess:fProcessId,cNivelAP,"P",_sDtAviso,_cUser,@_cPergPai)
		Else//Situação de Aprovado/Rejeitado
			MCOM004Q(5,"",_cFilial,_cNumPC,"1002","2","",_cSituacao,_cCRObs,_sDtLiber,_cHrLiber,"", _oProcess:fProcessId,cNivelAP,@cBloq,_sDtAviso,_cUser,@_cPergPai)
		EndIf
	
	EndIf
	
	DBSelectArea("TRBSCR")
	TRBSCR->(DBCloseArea())
	
	//==================================================
	//Finalize a tarefa anterior para não ficar pendente
	//==================================================
	_oProcess:Finish()
	
	//========================================================================================
	//Faz a Copia do arquivo de aprovação para .old, e cria o arquivo de processo já concluído
	//========================================================================================
	If File("\workflow\emp01\MCOM004\" + _cArqHtm + ".htm")
		If __CopyFile("\workflow\emp01\MCOM004\" + _cArqHtm + ".htm", "\workflow\emp01\MCOM004\" + _cArqHtm + ".old")
           If !Empty(_cHtmlMode)
			  If MCOM004CP("\workflow\emp01\MCOM004\" + _cArqHtm + ".htm",_cHtmlMode) //Recria _carqhtm com conteudo do modelo chtmlmode
				FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00404"/*cMsgId*/, "MCOM00404 - Copia do arquivo DE "+_cHtmlMode+" PARA \workflow\emp01\MCOM004\" + _cArqHtm + ".htm de conclusão efetuada com sucesso."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
			  Else
				FWLogMsg("WARN"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00405"/*cMsgId*/, "MCOM00405 - Problema na Copia de arquivo DE "+_cHtmlMode+" PARA \workflow\emp01\MCOM004\" + _cArqHtm + ".htm"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
			  EndIf
		   EndIf
		Else
			FWLogMsg("WARN"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00406"/*cMsgId*/, "MCOM00406 - Não foi possível renomear o arquivo \workflow\emp01\MCOM004\" + _cArqHtm + ".htm para .old"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		EndIf
	EndIf
	
	//========================================================================================
	//Quando o PC foi Aprovado ou Rejeitado Envia E-mail ao Grupo de Compras da Filial
	//========================================================================================
	If !Empty(cBloq) .And. _cSituacao <> "Q"
		
		DBSelectArea("SC7")
		SC7->(DBSetOrder(1))
		SC7->(DBSeek(_cFilial + _cNumPC))

		While !SC7->(Eof()) .And. SC7->C7_FILIAL == _cFilial .And. SC7->C7_NUM == _cNumPC
	       SC7->(RecLock("SC7",.F.))
	       SC7->C7_I_ENVEM:="S"
	       SC7->C7_I_STAEM:=cBloq
	       SC7->(MSUnLock())
		   SC7->(DBSkip())
		EndDo
		// MCOM004A(_cFilial,_cNumPc,cBloq,cNivelAP)

	ElseIf _cSituacao == "Q"

		_cQrySCR := "SELECT CR_FILIAL, CR_NUM, CR_USER, CR_NIVEL, CR_I_DTAPR, CR_I_HRAPR, CR_OBS "
		_cQrySCR += "FROM " + RetSqlName("SCR") + " "
		_cQrySCR += "WHERE CR_FILIAL = '" + _cFilial + "' "
		_cQrySCR += "  AND CR_NUM = '" + _cNumPC + "' "
		_cQrySCR += "  AND CR_NIVEL <> '" + cNivelAP + "' AND CR_TIPO = 'PC' "
		_cQrySCR += "  AND D_E_L_E_T_ = ' ' "
	
		dbUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQrySCR ) , "TRBSCR" , .T., .F. )
						
		DBSelectArea("TRBSCR")
		TRBSCR->(DBGoTop())
	
		If !TRBSCR->(Eof())
	
			While !TRBSCR->(Eof())
				PutMV("MV_WFHTML",.T.)
	
				MCOM004D(_cFilial, _cNumPc, TRBSCR->CR_NIVEL, TRBSCR->CR_USER,_cPergPai,"Aprovador")//ENVIO 1
	
				PutMV("MV_WFHTML",.T.)
				
				TRBSCR->(DBSkip())
			End
		EndIf
	
		//===============================================
		//Envia e-mail de questionamento para o comprador
		//===============================================
		DBSelectArea("SC7")
		DBSetOrder(1)
		DBSeek(_cFilial + _cNumPc)
			
		MCOM004D(_cFilial, _cNumPc, "", SC7->C7_USER,_cPergPai,"Comprador")//ENVIO 2
	
        If !Empty(SC7->C7_I_GCOM)
		   MCOM004D(_cFilial, _cNumPc, "", SC7->C7_I_GCOM,_cPergPai,"Gestor de Compras")//ENVIO 3
		EndIf   
		//=================================================
		//Envia e-mail de questionamento para o solicitante
		//=================================================
		cQry := "SELECT DISTINCT(C1_I_CDSOL) "
		cQry += "FROM " + RetSqlName("SC1") + " "
		cQry += "WHERE C1_FILIAL = '" + SC7->C7_FILIAL + "' "
		cQry += "  AND C1_NUM = '"    + SC7->C7_NUMSC  + "' "
		cQry += "  AND D_E_L_E_T_ = ' ' "
	
		dbUseArea( .T. , "TOPCONN" , TcGenQry(,, cQry ) , "SC1TRB" , .T., .F. )
						
		DBSelectArea("SC1TRB")
		SC1TRB->(DBGoTop())
		If !SC1TRB->(Eof())

			MCOM004D(_cFilial, _cNumPc, "", SC1TRB->C1_I_CDSOL,_cPergPai,"Solicitante")//ENVIO 4

		EndIf
	
		DBSelectArea("SC1TRB")
		SC1TRB->(DBCloseArea())
	
		//==============================================================
		//Envia e-mail de questionamento para o aprovador da solicitação
		//==============================================================
		cQry := "SELECT DISTINCT(C1_I_CODAP) "
		cQry += "FROM " + RetSqlName("SC1") + " "
		cQry += "WHERE C1_FILIAL = '" + SC7->C7_FILIAL + "' "
		cQry += "  AND C1_NUM = '"    + SC7->C7_NUMSC  + "' "
		cQry += "  AND D_E_L_E_T_ = ' ' "
	
		dbUseArea( .T. , "TOPCONN" , TcGenQry(,, cQry ) , "TMPSC1" , .T., .F. )
						
		DBSelectArea("TMPSC1")
		TMPSC1->(DBGoTop())
		If !TMPSC1->(Eof())

			MCOM004D(_cFilial, _cNumPc, "", TMPSC1->C1_I_CODAP,_cPergPai,"Aprovador SC")//ENVIO 5

		EndIf
	
		DBSelectArea("TMPSC1")
		TMPSC1->(DBCloseArea())
	
		DBSelectArea("TRBSCR")
		TRBSCR->(DBCloseArea())
		
	EndIf
Else
	//==================================================
	//Finaliza a tarefa anterior para não ficar pendente
	//==================================================
	_oProcess:Finish()
EndIf

DBSelectArea("TRBALC")
TRBALC->(DBCloseArea())

Return

/*
===============================================================================================================================
Programa----------: MCOM004Q
Autor-------------: Darcio Ribeiro Sporl
Data da Criacao---: 17/11/2015
Descrição---------: Rotina responsável pela seleção dos dados dos pedidos de compras e atualizações do workflow
Parametros--------: _nOpcao		- 1 = Dados SC / 2 = Dados PC / 3 = Atualização E-mail Enviado / 4 = Retorno Workflow
------------------: _cAlias		- Alias a ser utilizado no caso das consultas
------------------: _cFilial	- Filial do registro que está sendo executado
------------------: _cNumSC		- Número da Solicitação de Compras
------------------: _cWFID		- Id Workflow
------------------: _cSITWF		- Situação do Workflow 1-Qdo Inclui PC / 2-Enviado ao Aprovador / 3-Aprovador/Rejeitado / 4-Aguardando nDias
------------------: _cIDHTM		- Link do html gerado
------------------: _cAprova	- L - Liberado / R = Rejeitado
------------------: _cAObs		- Observação do aprovador, preenchido no formulário de aprovação
------------------: _sDtLiber	- Data da aprovação
------------------: _cHrLiber	- Hora da aprovação
------------------: _cProduto	- Produto da solicitação de compras
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MCOM004Q(_nOpcao,_cAlias,_cFilial,_cNumPC,_cWFID,_cSITWF,_cIDHTM,_cAprova,_cAObs,_sDtLiber,_cHrLiber,_cProduto,_cIdProcesso,_cNivelAP,_cBloq,_sDtAviso,_cUser,_cPergPai)
Local dDatIni
Local cDatAtual
Local lRet		:= .T.       
Local _cNumQ	:= ""
Default _cIdProcesso	:= ""
Default _cNivelAP		:= ""
Default _cBloq			:= ""
Default _cUser			:= ""
Default _cPergPai		:= ""


dDatIni:=SuperGetMV("IT_WFPCINI",.F.,"01/01/2016")
cDatAtual:=DToS(Date())

Do Case    

	//=============================================================================================================================
	//Seleciona todas as solicitações de compras que ainda não foram enviadas e-mail apos aprovações 
	//=============================================================================================================================
	Case _nOpcao == 0   
		BeginSql alias _cAlias  
			SELECT DISTINCT C7_FILIAL , C7_NUM
			FROM %Table:SC7% SC7
			WHERE C7_I_ENVEM = 'S'
			  AND SC7.%notDel%        
     		ORDER BY C7_FILIAL , C7_NUM
		EndSql
	//=============================================================================================================================
	//Seleciona todas as solicitações de compras que ainda não foram aprovadas e não foram enviadas ao aprovador
	//=============================================================================================================================
	Case _nOpcao == 1   
		BeginSql alias _cAlias
			SELECT CR_FILIAL, CR_NUM, CR_USER, CR_NIVEL, CR_I_DTAPR, CR_I_HRAPR , R_E_C_N_O_ SCR_REC , CR_STATUS , CR_OBS
			FROM %Table:SCR% SCR
			WHERE CR_STATUS = '02'
			  AND CR_EMISSAO >= %Exp:dDatIni%
			  AND CR_I_WFID = ' '
			  AND CR_TIPO = 'PC'
			  AND ((CR_I_DTAVS <> ' ' AND %Exp:cDatAtual% >= CR_I_DTAVS) OR (CR_I_DTAVS = ' '))  
			  AND EXISTS (SELECT 'Y' FROM %Table:SC7% SC7 WHERE SC7.C7_FILIAL = SCR.CR_FILIAL AND SC7.C7_NUM = TRIM(SCR.CR_NUM) AND SC7.C7_RESIDUO <> 'S' AND SC7.%notDel%)
			  AND SCR.%notDel%
			ORDER BY CR_FILIAL, CR_NUM, CR_NIVEL
		EndSql

		//======================================
		//Atualizar SCR para Aguardar nDias
		//======================================
	Case _nOpcao == 2

		DBSelectArea("SCR")
		DBSetOrder(1)
		DBSeek(_cFilial + "PC" + _cNumPC)
		
		While !SCR->(Eof()) .And. SCR->CR_FILIAL == _cFilial .And. SCR->CR_TIPO == "PC" .And. SubStr(SCR->CR_NUM,1,6) == _cNumPC
			If SCR->CR_NIVEL == _cNivelAP
				RecLock("SCR",.F.)
					Replace SCR->CR_OBS With _cAObs
					Replace SCR->CR_I_DTAVS With SToD(_sDtAviso)
					Replace SCR->CR_I_WFID With " "
				MSUnLock()
				Exit
			EndIf
			SCR->(DBSkip())
		End
 
		DBSelectArea("SC7")
		DBSetOrder(1)
		DBSeek(_cFilial + _cNumPC)

		While !SC7->(Eof()) .And. SC7->C7_FILIAL == _cFilial .And. SC7->C7_NUM == _cNumPC
			If SC7->C7_RESIDUO <> "S"
				RecLock("SC7",.F.)
				SC7->C7_I_SITWF:=_cSITWF
				MSUnLock()
			EndIf
			SC7->(DBSkip())
		End

	//=================================
	//Seleciona pedido de compras total
	//=================================
	Case _nOpcao == 3

		BeginSql alias _cAlias  
			SELECT	C7_FILIAL, C7_NUM, C7_ITEM, C7_PRODUTO, C7_EMISSAO, C7_QUANT, C7_UM, C7_PRECO, C7_TOTAL, C7_FORNECE, C7_LOJA, C7_QTDREEM, C7_VLDESC, C7_DATPRF, C7_I_URGEN, C7_I_CMPDI, C7_I_NFORN, 
			C7_DESCRI, C7_I_DESCD, C7_COND, C7_I_GCOM, C7_USER, C7_GRUPCOM, C7_NUMSC, C7_ITEMSC, C7_I_APLIC, C7_I_CDINV, C7_I_CMPDI, C7_VALIPI, C7_ICMSRET, C7_VALICM, C7_CC, C7_FRETE, C7_TPFRETE, C7_OBS, C7_FRETCON, C7_PICM,
			C7_I_CDTRA, C7_I_LJTRA, C7_I_TPFRT, C7_CONTATO, A2_COD, A2_LOJA, A2_NOME, A2_END, A2_MUN, A2_EST, A2_CEP, A2_DDD, A2_TEL, A2_FAX, A2_CGC, A2_INSCR, A2_CONTATO, C7_I_QTAPR, C7_MOEDA, C7_TXMOEDA, C7_I_CLAIM, C7_CONAPRO, C7_L_EXEMG 
			FROM %Table:SC7% SC7
			JOIN %Table:SA2% SA2 ON A2_FILIAL = %xFilial:SA2% AND A2_COD = C7_FORNECE AND A2_LOJA = C7_LOJA AND SA2.%notDel%
			WHERE C7_FILIAL = %Exp:_cFilial%
			  AND C7_RESIDUO <> 'S'
			  AND C7_NUM = %Exp:_cNumPC%
			  AND SC7.%notDel%        
     		ORDER BY C7_FILIAL, C7_NUM, C7_ITEM
		EndSql

	//===========================================================================
	//Atualiza a pedido de compras com WFID, SITWF e IDHTML - E-mail Enviado
	//===========================================================================
	Case _nOpcao == 4

		DBSelectArea("SC7")
		DBSetOrder(1)
		DBSeek(_cFilial + _cNumPC)
		
		While !SC7->(Eof()) .And. SC7->C7_FILIAL == _cFilial .And. SC7->C7_NUM == _cNumPC
			If SC7->C7_RESIDUO <> "S"
				RecLock("SC7",.F.)
				SC7->C7_I_WFID	:= _cIdProcesso
				SC7->C7_I_SITWF	:= _cSITWF
				SC7->C7_I_HTM	:= _cIDHTM
				MSUnLock()
			EndIf
			SC7->(DBSkip())
		End

		DBSelectArea("SCR")
		DBSetOrder(1)
		DBSeek(_cFilial + "PC" + _cNumPC)
		
		While !SCR->(Eof()) .And. SCR->CR_FILIAL == _cFilial .And. SCR->CR_TIPO == "PC" .And. SubStr(SCR->CR_NUM,1,6) == _cNumPC
			If SCR->CR_NIVEL == _cNivelAP
				RecLock("SCR",.F.)
					Replace SCR->CR_I_WFID With _cIdProcesso
				MSUnLock()
				Exit
			EndIf
			SCR->(DBSkip())
		End

	//====================================================================
	//Atualiza a pedido de compras com os dados da aprovação/rejeição
	//====================================================================
	Case _nOpcao == 5
	    cFilAnt:=_cFilial

        _lVista:=.F.//ATUALIZA DENTRO DA FUNCAO AtuNivel() se o aprovador é só VISTA
	    lRet := AtuNivel(_cFilial,_cNumPC,_cNivelAP,_cAprova,_sDtLiber,_cHrLiber,_cAObs,@_cBloq)
	    
		DBSelectArea("SC7")
		DBSetOrder(1)
		SC7->(DBSeek(_cFilial + _cNumPC))

		_lTemNota:=.F.
		If _lVista
		   //VER SE TEM NOTA: SE SIM BLOQUEIA ESTOQUE E NÃO FAZ NADA COM O PEDIDO AO REJEITA O PEDIDO NO FLUXO NORMAL
		   SD1->(DBSetOrder(22)) //D1_FILIAL+D1_PEDIDO+D1_ITEMPC
		   If SD1->(DBSeek(_cFilial + _cNumPC)) .And. SD1->D1_TIPO = 'N'
		      _lTemNota:=.T.
		   EndIf
		   SD1->(DBSetOrder(1)) 
		EndIf
		FWLogMsg("WARN"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00407"/*cMsgId*/,'MCOM00407 - Case _nOpcao == 5 :  _cAprova = ' + _cAprova+" / SC7->C7_CONAPRO = "+SC7->C7_CONAPRO+" / _lVista = "+If(_lVista,"SIM","NAO")/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		_cMensagem:=""//preenche no MCOM4Trans() e MCOM4DesTrans() se tiver erro
		If _lVista .And. _lTemNota

		   If lRet//APROVADO
		      _lTemNota:=MCOM4DesTrans(_cFilial + _cNumPC)//NONO
           Else// REJEITADO / BLOQUEADO
		      _lTemNota:=MCOM4Trans(_cFilial + _cNumPC)
           EndIf
		   If _lTemNota .And. !Empty(_cMensagem)
		   	  DBSelectArea("ZY2")
		      _cNumQ := GetSxeNum("ZY2","ZY2_CODIGO")
		      If Empty(_cPergPai)
		      	_cPergPai := _cNumQ
		      EndIf
		      ZY2->(RecLock("ZY2", .T.))		
		      ZY2->ZY2_FILIAL := xFilial("ZY2")
		      ZY2->ZY2_CODIGO := _cNumQ
		      ZY2->ZY2_PEDIDO := _cNumPC
		      ZY2->ZY2_FILPED := _cFilial
		      ZY2->ZY2_NIVEL  := _cNivelAP
		      ZY2->ZY2_DATAM  := Date()
		      ZY2->ZY2_HORAM  := _cHrLiber
		      ZY2->ZY2_WFID	  := _cIdProcesso
		      ZY2->ZY2_MENSAG := _cMensagem
		      ZY2->ZY2_TIPO	  := "E"//TIPO ERRO
		      ZY2->ZY2_USER	  := _cUser
		      ZY2->ZY2_PAI	  := _cPergPai		
		      ZY2->( MSUnLock() )
		   EndIf
		EndIf

		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00408"/*cMsgId*/,'MCOM00408 - Case _nOpcao == 5 :  _cAprova = ' + _cAprova+" / _cMensagem= "+_cMensagem+" / _lTemNota = "+If(_lTemNota,"SIM","NAO"+" / lRet = "+If(lRet,"SIM","NAO"))/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

		If lRet//APROVADO
			While !SC7->(Eof()) .And. SC7->C7_FILIAL == _cFilial .And. SC7->C7_NUM == _cNumPC
				If SC7->C7_CONAPRO == "B"  .Or. _lVista//.And. SC7->C7_RESIDUO <> "S"//AWF-15/06/2016
					RecLock("SC7",.F.)
					If _cAprova == "B"
						SC7->C7_I_SITWF := "3"
					Else
						SC7->C7_I_SITWF := _cSITWF
					EndIf
					SC7->C7_CONAPRO := _cAprova//POE "L"//APROVACAO
					SC7->C7_I_DTRES := SToD(_sDtLiber)
					SC7->C7_I_HRRES := _cHrLiber
					
					SC7->C7_I_WFID  := _cIdProcesso
					SC7->C7_I_QTAPR := _cNivelAP
     				SC7->C7_I_OBSAP := SubStr(_cAObs,1,Len(SC7->C7_I_OBSAP))
					SC7->C7_I_DTAPR := SToD(_sDtLiber)
					SC7->C7_I_HRAPR := _cHrLiber
					MSUnLock()
				EndIf
				SC7->(DBSkip())
			EndDo
		Else// REJEITADO / BLOQUEADO
		    SC7->(DBSeek(_cFilial + _cNumPC))
			While !SC7->(Eof()) .And. SC7->C7_FILIAL == _cFilial .And. SC7->C7_NUM == _cNumPC
				SC7->(RecLock("SC7",.F.))
				FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00409"/*cMsgId*/,'MCOM00409 - Case _nOpcao == 5 : _cAprova = ' + _cAprova+" / SC7->C7_CONAPRO = "+SC7->C7_CONAPRO+" / _lVista = "+If(_lVista,"SIM","NAO")+" / SC7->C7_RESIDUO = "+SC7->C7_RESIDUO/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
				If (SC7->C7_CONAPRO == "B" .Or. _lVista) .And. SC7->C7_RESIDUO <> "S" //.AND. !_lTemNota//SE NÃO TEM NOTA REJEITA
					If _lVista
					   SC7->C7_CONAPRO := _cAprova//POE "R"//REJEITA
					EndIf
					If _cAprova == "B"
					   SC7->C7_I_SITWF := "3"
					Else
					   SC7->C7_I_SITWF := _cSITWF
					EndIf
					SC7->C7_I_WFID  := _cIdProcesso
					SC7->C7_I_QTAPR := _cNivelAP
     				SC7->C7_I_OBSAP := SubStr(_cAObs,1,Len(SC7->C7_I_OBSAP))
					SC7->C7_I_DTAPR := SToD(_sDtLiber)
					SC7->C7_I_HRAPR := _cHrLiber
				EndIf
			    If _lVista .And. _lTemNota
				   SC7->C7_I_OBSAP:="PEDIDO REJEITADO POS NF"
				EndIf
				SC7->(MSUnLock())
				SC7->(DBSkip())
			EndDo

		EndIf

		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00410"/*cMsgId*/,'MCOM00410 - Case _nOpcao == 5 : _cAprova = ' + _cAprova+" / SC7->C7_CONAPRO = "+SC7->C7_CONAPRO+" / SC7->C7_I_SITWF = "+SC7->C7_I_SITWF+" / _lVista = "+If(_lVista,"SIM","NAO")+" / SC7->C7_I_OBSAP = "+SC7->C7_I_OBSAP/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

	Case _nOpcao == 6
		//=============================================================
		//Seleciona o último preço de compras do produto através da NFE
		//=============================================================
	
		BeginSql ALIAS _cAlias
          SELECT * FROM (SELECT D1_DTDIGIT, D1_EMISSAO BZ_UCOM , 
						        D1_VUNIT BZ_UPRC
				                FROM %Table:SD1% D1 
				                JOIN %Table:SF4% F4 ON D1_FILIAL = F4_FILIAL AND D1_TES = F4_CODIGO
                         WHERE D1.D_E_L_E_T_ = ' ' AND F4.D_E_L_E_T_ = ' '
                           AND D1_FILIAL =  %Exp:_cFilial%
                           AND D1_COD = %Exp:_cProduto%
                           AND F4_UPRC = 'S'
						   AND D1_TIPO = 'N'
                         ORDER BY D1.R_E_C_N_O_ DESC)  
		  WHERE ROWNUM <= 1			  
		EndSql
	Case _nOpcao == 7
		//=====================================
		//Seleciona quantidade atual por filial
		//=====================================
		BeginSql alias _cAlias
			SELECT SUM(B2_QATU+B2_QNPT) B2_QATU 
			FROM %Table:SB2% SB2
			WHERE B2_FILIAL = %Exp:_cFilial%
			  AND B2_COD    = %Exp:_cProduto%
			  AND B2_STATUS <> '2' 
			  AND SB2.%notDel%
		EndSql
	Case _nOpcao == 8
		//======================================
		//Seleciona quantidade atual por empresa
		//======================================
		BeginSql alias _cAlias
			SELECT SUM(B2_QATU+B2_QNPT) B2_QATU 
			FROM %Table:SB2% SB2
			WHERE B2_COD    = %Exp:_cProduto%
			  AND B2_STATUS <> '2' 
			  AND SB2.%notDel%
		EndSql

	//=======================================================================================
	//Atualiza os dados de questionamento
	//=======================================================================================
	Case _nOpcao == 9
    
    	DBSelectArea("SC7")
		DBSetOrder(1)
		DBSeek(_cFilial + _cNumPC)

		While !SC7->(Eof()) .And. SC7->C7_FILIAL == _cFilial .And. SC7->C7_NUM == _cNumPC
			RecLock("SC7",.F.)
			SC7->C7_I_WFID :=_cIdProcesso
			SC7->C7_I_SITWF:= "Q"
			MSUnLock()
			SC7->(DBSkip())
		EndDo
			
		//Se For questionamento, adiciona questionamento 

		DBSelectArea("ZY2")

		_cNumQ := GetSxeNum("ZY2","ZY2_CODIGO")

		If Empty(_cPergPai)
			_cPergPai := _cNumQ
		EndIf

		RecLock("ZY2", .T.)
		
		ZY2->ZY2_FILIAL := xFilial("ZY2")
		ZY2->ZY2_CODIGO	:= _cNumQ
		ZY2->ZY2_PEDIDO	:= _cNumPC
		ZY2->ZY2_FILPED	:= _cFilial
		ZY2->ZY2_NIVEL	:= _cNivelAP
		ZY2->ZY2_DATAM	:= Date()
		ZY2->ZY2_HORAM	:= _cHrLiber
		ZY2->ZY2_WFID	:= _cIdProcesso
		ZY2->ZY2_MENSAG := _cAObs
		ZY2->ZY2_TIPO	:= _cBloq
		ZY2->ZY2_USER	:= _cUser
		ZY2->ZY2_PAI	:= _cPergPai
		
		ZY2->( MSUnLock() )

		ConfirmSX8()
EndCase

_cRet:=" "

Return

/*
===============================================================================================================================
Programa----------: MONTAPED
Autor-------------: Darcio Ribeiro Sporl
Data da Criacao---: 14/01/2016
Descrição---------: Rotina responsável por montar o formulário de aprovação e o envio do link gerado.
Parametros--------: _cAliasSCR - Recebe o alias aberto das aprovações dos pedidos de compras
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MONTAPED(_cAliasSCR)
Local cEmail		:= ""
Local cLogo			:= _cHostWF + "htm/logo_novo.jpg"
Local nContrl		:= 0
Local cFilPC		:= SuperGetMV("IT_FILWFPC",.F.,"01")
Local cQry			:= ""
Local cQrySCR		:= ""
Local cUsuario		:= ""
Local cNomSol		:= ""
Local cNomApr		:= ""
Local cFiltro		:= ""
Local cNivel		:= ""
Local nTotal		:= 0
Local nTotMerc		:= 0
Local nTotDesc		:= 0
Local nTotIpi		:= 0
Local nTotIcms		:= 0
Local nTotDesp		:= 0
Local nTotFrete		:= 0
Local nTotSeguro	:= 0
Local nUlprc        := 0 
Local dDtUlPrc    := CTOD("")
Local nLinhas		:= 0
Local nX			:= 0
Local nI			:= 0
Local nJ			:= 0
Local cTransp		:= ""
Local cNivelAP		:= ""
Local cQryDT		:= ""
Local aDados		:= {}
Local aItens		:= {}
Local aAprov		:= {}
Local cNomFor		:= ""
Local cCgcFor		:= ""
Local cEndFor		:= ""
Local cCEPFor		:= ""
Local cCidFor		:= ""
Local cEstFor		:= ""
Local cTelFor		:= ""
Local cFaxFor		:= ""
Local cIEFor		:= ""
Local cContatFor	:= ""
Local cCondPG		:= ""
Local cEmissao		:= ""
Local cNomGes		:= ""
Local cLink			:= ""
Local cTpFrete		:= ""
Local cReavaliar    := " "
Local _cRastrear    := "Envio para Aprovacao do PC "
Local _cnumsc		:= ""
Local _cscemissao	:= ""
Local _cscaprov		:= ""
Local _cAliasSC7	:= ""
Local _cAliasSBZ	:= ""
Local _cAliasSBF	:= "" 
Local _cAliasSBE	:= "" 
Local _cQuest	    := "" 
Local _cMV_WFMLBOX  := AllTrim(GetMV('MV_WFMLBOX'))
Local _cCntlNoRepeti:= ""
Local _cCntlUser    := ""
Local _aRecRepets   := {} ,R
Local cObsSc		:= ""
Local _cGrpLeite    := ""
Private _lGrpLeite  := .F.//PARA TESTAR AS DECIMAIS na função MCOM004Totais() e "cTitulo"

(_cAliasSCR)->(DBGoTop())
While !(_cAliasSCR)->(Eof())

	If !((_cAliasSCR)->CR_USER+"|"+(_cAliasSCR)->CR_NUM) $ _cCntlUser
		_cCntlUser+=((_cAliasSCR)->CR_USER+"|"+(_cAliasSCR)->CR_NUM)+"/"
	Else//Regs Repetidos
		_cCntlNoRepeti+=(_cAliasSCR)->CR_NUM+"/"
        aAdd(_aRecRepets, (_cAliasSCR)->SCR_REC )
	EndIf
   (_cAliasSCR)->(DBSkip())

EndDo
cMensagem:=Upper( GetEnvServer() )+" - Tem Usuarios repetidos no SCR: "+CHR(13)+CHR(10)
(_cAliasSCR)->(DBGoTop())

If !(_cAliasSCR)->(Eof())

    cFilant:=(_cAliasSCR)->CR_FILIAL
    _cGrpLeite    := AllTrim(SuperGetMV("IT_GRPLEIT",.F.,""))

	FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00411"/*cMsgId*/,"MCOM00411 - 01-IT_GRPLEITE =" +_cGrpLeite + ' /  _lGrpLeite =' + If(_lGrpLeite,".T.",".F.")+" / cFilant = "+cFilant/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

	While !(_cAliasSCR)->(Eof())
	
		cFilPC		:= (_cAliasSCR)->CR_FILIAL + " - " + AllTrim(FWFilialName(cEmpAnt, (_cAliasSCR)->CR_FILIAL, 1 ))
		cNomFil		:= AllTrim(FWFilialName(cEmpAnt, (_cAliasSCR)->CR_FILIAL, 1 ))
		cNumPC		:= SubStr((_cAliasSCR)->CR_NUM,1,6)
		cNivelAP	:= (_cAliasSCR)->CR_NIVEL

	    If (_cAliasSCR)->CR_NUM $ _cCntlNoRepeti

           cMensagem+="User: "+(_cAliasSCR)->CR_USER+" - "+UsrRetMail((_cAliasSCR)->CR_USER)+" no Nivel: "+cNivelAP+" / Status: "+(_cAliasSCR)->CR_STATUS+" / "
           cMensagem+=cNumPC+" / "+cFilPC+" / "+cNomFil+" / Recno: "+AllTrim(Str( (_cAliasSCR)->SCR_REC ))
           If aScan(_aRecRepets, (_cAliasSCR)->SCR_REC ) <> 0
              cMensagem+=" Deletado"
           EndIf   
           cMensagem+=CHR(13)+CHR(10)

	       (_cAliasSCR)->(DBSkip())
	       Loop
	    EndIf	

		MaFisEnd()
		M004FIniPC(cNumPC,,,cFiltro,(_cAliasSCR)->CR_FILIAL)

		nTotal		:= 0
		nTotIcms    := 0
		nTotMerc	:= 0
		nTotDesc	:= 0
		nC7_L_EXEMG := 0
		
		DBSelectArea("SM0")
		DBSetOrder(1)
		DBSeek(cEmpAnt + (_cAliasSCR)->CR_FILIAL)
		
		cNomFil	:= AllTrim(SM0->M0_FILIAL)
		cEndFil	:= AllTrim(SM0->M0_ENDCOB)
		cCepFil	:= SubStr(AllTrim(SM0->M0_CEPCOB),1,2) + "." + SubStr(AllTrim(SM0->M0_CEPCOB),3,3) + "-" + SubStr(AllTrim(SM0->M0_CEPCOB),6,3)
		cCidFil	:= SubStr(AllTrim(SM0->M0_CIDCOB),1,50)
		cEstFil	:= AllTrim(SM0->M0_ESTCOB)
		cTelFil	:= '(' + SubStr(SM0->M0_TEL,4,2) + ')' + SubStr(SM0->M0_TEL,7,4) + '-' +SubStr(SM0->M0_TEL,11,4)
		cFaxFil	:= '(' + SubStr(SM0->M0_FAX,4,2) + ')' + SubStr(SM0->M0_FAX,7,4) + '-' +SubStr(SM0->M0_FAX,11,4)
		cCGCFil	:= formCPFCNPJ(SM0->M0_CGC)
		cIEFil	:= AllTrim(SM0->M0_INSC)
		
		nContrl	:= 0

		cEmail := (_cAliasSCR)->CR_USER

  		If !Empty(_cAliasSC7) .And. select(_cAliasSC7) > 0
  			(_cAliasSC7)->(DBCloseArea())
  		EndIf

		_cAliasSC7 := GetNextAlias()
		MCOM004Q(3,_cAliasSC7,SubStr(cFilPC,1,2),AllTrim(cNumPC),"","","","","","","","")
		
		DBSelectArea(_cAliasSC7)
		(_cAliasSC7)->(DBGoTop())
		_lGrpLeite  := IIf((_cAliasSC7)->C7_GRUPCOM $ _cGrpLeite ,.T.,.F.)//PARA TESTAR AS DECIMAIS na função MCOM004Totais() e "cTitulo"

		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00412"/*cMsgId*/,"MCOM00412 - 02-IT_GRPLEITE =" +_cGrpLeite + ' /  _lGrpLeite =' + If(_lGrpLeite,".T.",".F.")+" / cFilant = "+cFilant+" / (_cAliasSC7)->C7_GRUPCOM = "+(_cAliasSC7)->C7_GRUPCOM/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

		_nMoedaSC7:=(_cAliasSC7)->C7_MOEDA
		_nTxMoeSC7:=(_cAliasSC7)->C7_TXMOEDA
		_nDtMoeSC7:=(_cAliasSC7)->C7_EMISSAO
		_cObs:=""
		_cPObsProdAlter:="Saldo Produtos Alternativos:"+ENTERBR
        nContaItem:=0

		If !(_cAliasSC7)->(Eof())
			While !(_cAliasSC7)->(Eof())
				nContrl++
				If nContrl == 1
							
					//Codigo do processo cadastrado no CFG
					_cCodProce := "PEDIDO"
					// Arquivo html template utilizado para montagem da aprovação
					_cHtmlMode := "\Workflow\htm\pc_aprovador.htm"
					// Assunto da mensagem
					_cAssunto := "1-Aprovação do Pedido de Compras Filial " + (_cAliasSCR)->CR_FILIAL + " - " + AllTrim(FWFilialName(cEmpAnt,(_cAliasSCR)->CR_FILIAL,1)) + " SC Número: " + SubStr((_cAliasSCR)->CR_NUM,1,6)

					// Inicialize a classe TWFProcess e assinale a variável objeto oProcess:
					_oProcess := TWFProcess():New(_cCodProce,"Aprovação de Pedido de Compras")
					_oProcess:NewTask("Aprovacao_PC", _cHtmlMode)   

					//=========================
					//Dados dos questionamentos
					//=========================
					_cQuest:=U_M004Quest((_cAliasSCR)->CR_FILIAL, SubStr((_cAliasSCR)->CR_NUM,1,6))
					If !Empty(_cQuest)
						_oProcess:oHtml:ValByName("cQuest", _cQuest )
					Else
						_oProcess:oHtml:ValByName("cQuest", "" )
					EndIf

					_oProcess:oHtml:ValByName("cUser"			, (_cAliasSCR)->CR_USER )

					//=======================================
					//Dados do cabeçalho do pedido de compras
					//=======================================
					_oProcess:oHtml:ValByName("cLogo"			, cLogo )
					_oProcess:oHtml:ValByName("cNomFil"			, cFilPC)
					_oProcess:oHtml:ValByName("cEndFil"			, cEndFil)
					_oProcess:oHtml:ValByName("cCepFil"			, cCepFil)
					_oProcess:oHtml:ValByName("cCidFil"			, cCidFil)
					_oProcess:oHtml:ValByName("cEstFil"			, cEstFil)
					_oProcess:oHtml:ValByName("cTelFil"			, cTelFil)
					_oProcess:oHtml:ValByName("cFaxFil"			, cFaxFil)
					_oProcess:oHtml:ValByName("cCGCFil"			, cCGCFil)
					_oProcess:oHtml:ValByName("cIEFil"			, cIEFil)
					
					_oProcess:oHtml:ValByName("cNivelAP"		, cNivelAP)
					_oProcess:oHtml:ValByName("NumPC"			, cNumPC)

					If !Empty((_cAliasSC7)->C7_I_GCOM)
					    _C7_I_GCOM:=MCOM004FullNome((_cAliasSC7)->C7_I_GCOM)
                        cNomGes := SubStr(_C7_I_GCOM, 1, At(" ", _C7_I_GCOM)-1)
						_oProcess:oHtml:ValByName("cNomGes", cNomGes)
					Else
						_oProcess:oHtml:ValByName("cNomGes"  		, "")
					EndIf

					cQry := "SELECT C1_I_CDSOL, C1_I_CODAP, C1_NUM, C1_EMISSAO, C1_I_DTAPR, C1_I_OBSAP , C1_I_OBSSC "
					cQry += "FROM " + RetSqlName("SC1") + " "
					cQry += "WHERE C1_FILIAL = '" + (_cAliasSC7)->C7_FILIAL + "' "
					cQry += "  AND C1_NUM = '"    + (_cAliasSC7)->C7_NUMSC  + "' "
					cQry += "  AND C1_ITEM = '"   + (_cAliasSC7)->C7_ITEMSC + "' "
					cQry += "  AND D_E_L_E_T_ = ' ' "

					dbUseArea( .T. , "TOPCONN" , TcGenQry(,, cQry ) , "TRBSC1" , .T., .F. )
					
					DBSelectArea("TRBSC1")
					TRBSC1->(DBGoTop())

					If AllTrim(TRBSC1->C1_I_OBSAP) == "EXECUTADO VIA WORKFLOW" .AND.;
					   AllTrim(TRBSC1->C1_I_OBSAP) == "SC Aprovada via acesso ao Protheus"
						cObsSc := ""
					Else
						cObsSc := AllTrim(TRBSC1->C1_I_OBSAP)
					EndIf
					cObsScGen:=AllTrim(TRBSC1->C1_I_OBSSC)					

					If !TRBSC1->(Eof())

						If Empty(AllTrim(TRBSC1->C1_I_CDSOL))
							_oProcess:oHtml:ValByName("cNomSol","")
						Else
							_oProcess:oHtml:ValByName("cNomSol",AllTrim(Posicione("ZZ7",1,SubStr(cFilPC,1,2) + TRBSC1->C1_I_CDSOL, "ZZ7_NOME")))
							cNomSol := AllTrim(Posicione("ZZ7",1,SubStr(cFilPC,1,2) + TRBSC1->C1_I_CDSOL, "ZZ7_NOME"))
						EndIf
						
						If Empty(TRBSC1->C1_I_CODAP)
							_oProcess:oHtml:ValByName("cNomApr","")
							cNomApr := ""
						Else
							_oProcess:oHtml:ValByName("cNomApr", AllTrim(Posicione("ZZ7",1,SubStr(cFilPC,1,2) + TRBSC1->C1_I_CODAP, "ZZ7_NOME")))
							cNomApr := AllTrim(Posicione("ZZ7",1,SubStr(cFilPC,1,2) + TRBSC1->C1_I_CODAP, "ZZ7_NOME"))
						EndIf
						
						_cnumsc		:= AllTrim(TRBSC1->C1_NUM)
						_cscemissao	:= AllTrim(DToC(SToD(TRBSC1->C1_EMISSAO)))
						_cscaprov		:= AllTrim(DToC(SToD(TRBSC1->C1_I_DTAPR)))
			
			
						_oProcess:oHtml:ValByName("cnumSC",AllTrim(TRBSC1->C1_NUM))
						_oProcess:oHtml:ValByName("cdtinc",AllTrim(DToC(SToD(TRBSC1->C1_EMISSAO))))
						_oProcess:oHtml:ValByName("cdtapr",AllTrim(DToC(SToD(TRBSC1->C1_I_DTAPR))))
												
						
					Else
						_oProcess:oHtml:ValByName("cNomSol","")
						_oProcess:oHtml:ValByName("cNomApr","")
						_oProcess:oHtml:ValByName("cnumSC","")
						_oProcess:oHtml:ValByName("cdtinc","")
						_oProcess:oHtml:ValByName("cdtapr","")
		
						cNomSol := ""  
  						cNomApr := ""
  						_cNumsc		:= ""
						_cScemissao	:= ""
						_cScaprov	:= ""
  						
					EndIf

					DBSelectArea("TRBSC1")
					TRBSC1->(DBCloseArea())
                    _C7_USER:=MCOM004FullNome((_cAliasSC7)->C7_USER)
					_oProcess:oHtml:ValByName("cDigiFor"		, SubStr(_C7_USER, 1, At(" ", _C7_USER)-1))
					cUsuario := (_cAliasSC7)->C7_USER
                    
					_oProcess:oHtml:ValByName("cObsSC",cObsSc+" -/- "+cObsScGen)//pc_aprovador.htm TEM essa vairiavel 

					If (_cAliasSC7)->C7_I_APLIC == "C"
						cAplic := "Consumo"
					ElseIf (_cAliasSC7)->C7_I_APLIC == "I"
						cAplic := "Investimento - " + Posicione("ZZI",1,SubStr(cFilPC,1,2) + (_cAliasSC7)->C7_I_CDINV, "ZZI_DESINV")
					ElseIf (_cAliasSC7)->C7_I_APLIC == "M"
						cAplic := "Manutenção"
					ElseIf (_cAliasSC7)->C7_I_APLIC == "S"
						cAplic := "Serviço"
					EndIf
					
					_oProcess:oHtml:ValByName("cAplic", cAplic)

					cReavaliar := ""		
					If MCOM004B( (_cAliasSC7)->C7_FILIAL,(_cAliasSC7)->C7_NUM,(_cAliasSCR)->CR_NIVEL )
    					cReavaliar := "**REAVALIAR**"
					EndIf
					If (_cAliasSC7)->C7_I_CLAIM = '1'
					   cReavaliar:=cReavaliar+" **CLAIM**" 
					EndIf
					If (_cAliasSC7)->C7_I_APLIC == "I"
					   cReavaliar:=cReavaliar+" **INVESTIMENTO**"
					EndIf
					_oProcess:oHtml:ValByName("cReavaliar",cReavaliar)
					If _lGrpLeite
					   _oProcess:oHtml:ValByName("cTitulo"," - DPTO. LEITE")
					Else
					   _oProcess:oHtml:ValByName("cTitulo","")
					EndIf
                    FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00413"/*cMsgId*/,"MCOM00413 - 03-IT_GRPLEITE =" +_cGrpLeite + ' /  _lGrpLeite =' + If(_lGrpLeite,".T.",".F.")+" / cFilant = "+cFilant+" / (_cAliasSC7)->C7_GRUPCOM = "+(_cAliasSC7)->C7_GRUPCOM/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

					If (_cAliasSC7)->C7_I_URGEN == "S"
						cUrgen	:= "Sim"
						cCorUrgen   := "color=#FF0000"
					ElseIf (_cAliasSC7)->C7_I_URGEN == "F"
						cUrgen	:= "NF"
						cCorUrgen   := "color=#FF0000"
					Else
						cUrgen	   := "Não"    
						cCorUrgen  := " "						
					EndIf
					_oProcess:oHtml:ValByName("cCorUrgen", cCorUrgen)
					_oProcess:oHtml:ValByName("cUrgen", cUrgen)

					If (_cAliasSC7)->C7_I_CMPDI == "S"
						cCmpdi	:= "Sim"
					Else
						cCmpdi	:= "Não"
					EndIf

			
					If (_cAliasSC7)->C7_TPFRETE == "C"
						_oProcess:oHtml:ValByName("cFrete"	, "CIF")
						cTpFrete := "CIF"
					ElseIf (_cAliasSC7)->C7_TPFRETE == "F"
						_oProcess:oHtml:ValByName("cFrete"	, "FOB")
						cTpFrete := "FOB"
					ElseIf (_cAliasSC7)->C7_TPFRETE == "T"
						_oProcess:oHtml:ValByName("cFrete"	, "TERCEIROS")
						cTpFrete := "TERCEIROS"
					ElseIf (_cAliasSC7)->C7_TPFRETE == "S"
						_oProcess:oHtml:ValByName("cFrete"	, "SEM FRETE")
						cTpFrete := "SEM FRETE"
					EndIf

					_oProcess:oHtml:ValByName("cCompDir"  		, cCmpdi)

					_oProcess:oHtml:ValByName("dDtEmiss"  		, DToC(SToD((_cAliasSC7)->C7_EMISSAO)))
					cEmissao := DToC(SToD((_cAliasSC7)->C7_EMISSAO))
                    
					If  !Empty(AllTrim((_cAliasSC7)->C7_CC))
						cCcusto	:= (_cAliasSC7)->C7_CC + " - " + AllTrim(Posicione("CTT",1,xFilial("CTT") + AllTrim((_cAliasSC7)->C7_CC), "CTT_DESC01"))
					Else
					    cCcusto := ""
					EndIf

					cNomFor		:= AllTrim((_cAliasSC7)->A2_NOME) + " - " + (_cAliasSC7)->A2_COD + "/" + (_cAliasSC7)->A2_LOJA
					cCgcFor		:= formCPFCNPJ((_cAliasSC7)->A2_CGC)
					cEndFor		:= AllTrim((_cAliasSC7)->A2_END)
					cCEPFor		:= (_cAliasSC7)->A2_CEP
					cCidFor		:= AllTrim((_cAliasSC7)->A2_MUN)
					cEstFor		:= (_cAliasSC7)->A2_EST
					cTelFor		:= "(" + (_cAliasSC7)->A2_DDD + ") " + (_cAliasSC7)->A2_TEL
					cFaxFor		:= "(" + (_cAliasSC7)->A2_DDD + ") " + (_cAliasSC7)->A2_FAX
					cIEFor		:= (_cAliasSC7)->A2_INSCR
					cContatFor	:= AllTrim((_cAliasSC7)->C7_CONTATO)
					cCondPG		:= AllTrim(Posicione("SE4",1,xFilial("SE4") + AllTrim((_cAliasSC7)->C7_COND),"E4_DESCRI"))

					_oProcess:oHtml:ValByName("cNomFor"			, AllTrim((_cAliasSC7)->A2_NOME) + " - " + (_cAliasSC7)->A2_COD + "/" + (_cAliasSC7)->A2_LOJA)
					_oProcess:oHtml:ValByName("cEndFor"			, AllTrim((_cAliasSC7)->A2_END))
					_oProcess:oHtml:ValByName("cCEPFor"			, (_cAliasSC7)->A2_CEP)
					_oProcess:oHtml:ValByName("cCidFor"			, AllTrim((_cAliasSC7)->A2_MUN))
					_oProcess:oHtml:ValByName("cEstFor"			, (_cAliasSC7)->A2_EST)
					_oProcess:oHtml:ValByName("cTelFor"			, "(" + (_cAliasSC7)->A2_DDD + ") " + (_cAliasSC7)->A2_TEL)
					_oProcess:oHtml:ValByName("cFaxFor"			, "(" + (_cAliasSC7)->A2_DDD + ") " + (_cAliasSC7)->A2_FAX)
					_oProcess:oHtml:ValByName("cCGCFor"			, formCPFCNPJ((_cAliasSC7)->A2_CGC))
					_oProcess:oHtml:ValByName("cIEFor"	 		, (_cAliasSC7)->A2_INSCR)
					_oProcess:oHtml:ValByName("cContatFor"		, AllTrim((_cAliasSC7)->C7_CONTATO))
					_oProcess:oHtml:ValByName("cCondPG"	  		, AllTrim(Posicione("SE4",1,xFilial("SE4") + AllTrim((_cAliasSC7)->C7_COND),"E4_DESCRI")))

					cTransp := ""

					If !Empty((_cAliasSC7)->C7_I_CDTRA) .And. !Empty((_cAliasSC7)->C7_I_LJTRA)
						cTransp := "&nbsp;"
						cTransp += "Código: " + (_cAliasSC7)->C7_I_CDTRA + "&nbsp;Loja: " + (_cAliasSC7)->C7_I_LJTRA + "<br>"
						cTransp += "Razão Social: " + AllTrim(SubStr(Posicione("SA2", 1, xFilial("SA2")+(_cAliasSC7)->C7_I_CDTRA+(_cAliasSC7)->C7_I_LJTRA,"A2_NOME"),1,30)) + "<br>"
						cTransp += "Nome Fantasia: " + AllTrim(SubStr(Posicione("SA2", 1, xFilial("SA2")+(_cAliasSC7)->C7_I_CDTRA+(_cAliasSC7)->C7_I_LJTRA, "A2_NREDUZ"),1,30)) + "<br>"
						cTransp += "CNPJ: " + Transform(Posicione("SA2", 1, xFilial("SA2")+(_cAliasSC7)->C7_I_CDTRA+(_cAliasSC7)->C7_I_LJTRA, "A2_CGC"), PesqPict("SA2","A2_CGC")) + "&nbsp;&nbsp;&nbsp;"
						cTransp += "Ins. Estad.: " + Posicione("SA2", 1, xFilial("SA2")+(_cAliasSC7)->C7_I_CDTRA+(_cAliasSC7)->C7_I_LJTRA, "A2_INSCR") + "<br>"
						cTransp += "Bairro: " + AllTrim(SubStr(Posicione("SA2", 1, xFilial("SA2")+(_cAliasSC7)->C7_I_CDTRA+(_cAliasSC7)->C7_I_LJTRA, "A2_BAIRRO"),1,25)) + "<br>"
						cTransp += "Cidade: " + SubStr(Posicione("SA2", 1, xFilial("SA2")+(_cAliasSC7)->C7_I_CDTRA+(_cAliasSC7)->C7_I_LJTRA, "A2_MUN"),1,30) + "&nbsp;&nbsp;&nbsp;"
						cTransp += "Estado: " + Posicione("SA2", 1, xFilial("SA2")+(_cAliasSC7)->C7_I_CDTRA+(_cAliasSC7)->C7_I_LJTRA, "A2_EST") + "<br>"
						cTransp += "Telefone: (" + AllTrim(Posicione("SA2", 1, xFilial("SA2")+(_cAliasSC7)->C7_I_CDTRA+(_cAliasSC7)->C7_I_LJTRA, "A2_DDD")) + ")" + Posicione("SA2", 1, xFilial("SA2")+(_cAliasSC7)->C7_I_CDTRA+(_cAliasSC7)->C7_I_LJTRA, "A2_TEL") + "<br>"
						cTransp += "Contato: " + AllTrim(Posicione("SA2", 1, xFilial("SA2")+(_cAliasSC7)->C7_I_CDTRA+(_cAliasSC7)->C7_I_LJTRA, "A2_CONTATO")) + "<br>"
						cTransp += "Obs. Frete: " + If((_cAliasSC7)->C7_I_TPFRT == "1","Entregar na Transportadora","Solicitar Coleta pela Transportadora" )
					EndIf
					
					_oProcess:oHtml:ValByName("cTransp"	  		, cTransp)
					
				EndIf
				
				aAdd( _oProcess:oHtml:ValByName("Itens.Item" 			), (_cAliasSC7)->C7_ITEM 												)
				aAdd( _oProcess:oHtml:ValByName("Itens.Prodpc" 			), (_cAliasSC7)->C7_PRODUTO								 				)
				If AllTrim((_cAliasSC7)->C7_I_DESCD) $ (_cAliasSC7)->C7_DESCRI
					aAdd( _oProcess:oHtml:ValByName("Itens.DesProd"		), AllTrim((_cAliasSC7)->C7_DESCRI)														)
				Else
					aAdd( _oProcess:oHtml:ValByName("Itens.DesProd"		), AllTrim((_cAliasSC7)->C7_DESCRI) + " " + AllTrim((_cAliasSC7)->C7_I_DESCD)			)
				EndIf
				aAdd( _oProcess:oHtml:ValByName("Itens.UM"				), (_cAliasSC7)->C7_UM													)
				aAdd( _oProcess:oHtml:ValByName("Itens.qtde"			), Transform((_cAliasSC7)->C7_QUANT, PesqPict("SC7","C7_QUANT"))		)

                _cValor:=MCOM004Totais((_cAliasSC7)->C7_MOEDA,0,(_cAliasSC7)->C7_PRECO,.F.)
		        aAdd( _oProcess:oHtml:ValByName("Itens.VlrUni"			), _cValor)//Transform((_cAliasSC7)->C7_PRECO, "@E 999,999,999.999") 	      )

                _cValor:=MCOM004Totais((_cAliasSC7)->C7_MOEDA,0,(_cAliasSC7)->C7_VLDESC,.F.)
		        aAdd( _oProcess:oHtml:ValByName("Itens.VlrDes"		   	), _cValor)//Transform((_cAliasSC7)->C7_VLDESC, PesqPict("SC7","C7_VLDESC"))  )

                _cValor:=MCOM004Totais((_cAliasSC7)->C7_MOEDA,0,((_cAliasSC7)->C7_TOTAL-(_cAliasSC7)->C7_VLDESC),.F.)
		        aAdd( _oProcess:oHtml:ValByName("Itens.VlrTot"			), _cValor)//Transform((_cAliasSC7)->C7_TOTAL, PesqPict("SC7","C7_TOTAL")) 	  )

                _cValor:=MCOM004Totais(1,0,(_cAliasSC7)->C7_PICM,.F.,.T.)
		        aAdd( _oProcess:oHtml:ValByName("Itens.ICMS"			), _cValor)

				aAdd( _oProcess:oHtml:ValByName("Itens.DtEmis"			), DToC(SToD((_cAliasSC7)->C7_DATPRF))									)

  				If !Empty(_cAliasSBZ) .And. select(_cAliasSBZ) > 0
  					(_cAliasSBZ)->(DBCloseArea())
  				EndIf
				
				_cAliasSBZ := GetNextAlias()
				MCOM004Q(6,_cAliasSBZ,(_cAliasSC7)->C7_FILIAL,"","","","","","","","",(_cAliasSC7)->C7_PRODUTO)
				nUlPrc := 0
            dDtUlPrc := CTOD("")
				If !(_cAliasSBZ)->(Eof())
				   If (_cAliasSC7)->C7_MOEDA = 1
				      nUlPrc  :=(_cAliasSBZ)->BZ_UPRC
                  dDtUlPrc:=SToD((_cAliasSBZ)->BZ_UCOM)
				   ElseIf !Empty((_cAliasSBZ)->BZ_UCOM)
				      dDtUlPrc:=SToD((_cAliasSBZ)->BZ_UCOM)
				      nTxMoeda:=RecMoeda(dDtUlPrc,(_cAliasSC7)->C7_MOEDA)
				      nUlPrc  :=((_cAliasSBZ)->BZ_UPRC/nTxMoeda)
				   EndIf   
				EndIf
                _cValor:=MCOM004Totais((_cAliasSC7)->C7_MOEDA,0,nUlPrc,.F.)
				aAdd( _oProcess:oHtml:ValByName("Itens.VlrUc"),_cValor)
            aAdd( _oProcess:oHtml:ValByName("Itens.DtUc"),DToC(dDtUlPrc))

				If !Empty(_cAliasSBF) .And. select(_cAliasSBF) > 0
					(_cAliasSBF)->(DBCloseArea())
				EndIf
				_cProdAlt:=Posicione("SGI",1,(_cAliasSC7)->C7_FILIAL+(_cAliasSC7)->C7_PRODUTO,"GI_PRODALT")
				If !Empty(_cProdAlt)
				   _cAliasSBF := GetNextAlias()
				   MCOM004Q(7,_cAliasSBF,(_cAliasSC7)->C7_FILIAL,"","","","","","","","",_cProdAlt)
			       _cPObsProdAlter+="<b>"+AllTrim(_cProdAlt)+'-'+AllTrim(Posicione("SB1",1,xFilial("SB1")+_cProdAlt,"B1_DESC"))+;
			   	                    " = "+AllTrim(Transform((_cAliasSBF)->B2_QATU, PesqPict("SB2","B2_QATU")))+"</b>"+ENTERBR
				EndIf

				If !Empty(_cAliasSBF) .And. select(_cAliasSBF) > 0
					(_cAliasSBF)->(DBCloseArea())
				EndIf
				
				_cAliasSBF := GetNextAlias()
				MCOM004Q(7,_cAliasSBF,(_cAliasSC7)->C7_FILIAL,"","","","","","","","",(_cAliasSC7)->C7_PRODUTO)
				If !(_cAliasSBF)->(Eof())
					aAdd( _oProcess:oHtml:ValByName("Itens.SldAtFil"		), Transform((_cAliasSBF)->B2_QATU, PesqPict("SB2","B2_QATU"))		)
				Else
					aAdd( _oProcess:oHtml:ValByName("Itens.SldAtFil"		), Transform(0, PesqPict("SB2","B2_QATU"))		)
				EndIf
				
				If !Empty(_cAliasSBE) .And. select(_cAliasSBE) > 0
					(_cAliasSBE)->(DBCloseArea())
				EndIf
				
				_cAliasSBE := GetNextAlias()
				MCOM004Q(8,_cAliasSBE,(_cAliasSC7)->C7_FILIAL,"","","","","","","","",(_cAliasSC7)->C7_PRODUTO)
				If !(_cAliasSBE)->(Eof())
					aAdd( _oProcess:oHtml:ValByName("Itens.SldAtEmp"		), Transform((_cAliasSBE)->B2_QATU, PesqPict("SB2","B2_QATU"))		)
				Else
					aAdd( _oProcess:oHtml:ValByName("Itens.SldAtEmp"		), Transform(0, PesqPict("SB2","B2_QATU"))		)
				EndIf

				aAdd(aItens, {	(_cAliasSC7)->C7_ITEM,;			                                    // [01] Item
								(_cAliasSC7)->C7_PRODUTO,;		                                    // [02] Código do Produto
								IIf( AllTrim((_cAliasSC7)->C7_I_DESCD) $ (_cAliasSC7)->C7_DESCRI, AllTrim((_cAliasSC7)->C7_DESCRI), AllTrim((_cAliasSC7)->C7_DESCRI) + " " + AllTrim((_cAliasSC7)->C7_I_DESCD)),;	// [03] Descrição do Produto
								(_cAliasSC7)->C7_UM,;			                                    // [04] Unidade de Medida
								Transform((_cAliasSC7)->C7_QUANT  , PesqPict("SC7","C7_QUANT")),;	// [05] Quantidade
								(_cAliasSC7)->C7_PRECO  ,;	                                        // [06] Preço
								(_cAliasSC7)->C7_VLDESC ,;	                                        // [07] Valor do Desconto
								Transform((_cAliasSC7)->C7_TOTAL  , PesqPict("SC7","C7_TOTAL")),;	// [08] Valor Total
								(_cAliasSC7)->C7_PICM ,;	                                        // [09] Valor do IPI
								Transform((_cAliasSC7)->C7_ICMSRET, PesqPict("SC7","C7_ICMSRET")),;	// [10] Valor do ICMS RET
								DToC(SToD((_cAliasSC7)->C7_DATPRF)),;								// [11] Data de Entrega
								nUlprc,;	                 		                                // [12] Ultimo Preço de Compras
								Transform((_cAliasSBF)->B2_QATU, PesqPict("SB2","B2_QATU")),;		// [13] Quantidade Total por Filial
								Transform((_cAliasSBE)->B2_QATU, PesqPict("SB2","B2_QATU")),;  		// [14] Quantidade Total da Empresa
								((_cAliasSC7)->C7_TOTAL-(_cAliasSC7)->C7_VLDESC) ,; //[15] Valor Total - Valor do Desconto
                        DToC(dDtUlPrc) }) //[16] Data Ultimo Preço de Vendas
                    
                //nContaItem++
				nTotIcms    += (_cAliasSC7)->C7_VALICM//MaFisRet(nContaItem,"IT_VALICM")
				nTotDesc	+= (_cAliasSC7)->C7_VLDESC  
				nTotal		+= (_cAliasSC7)->C7_TOTAL 
				nC7_L_EXEMG += (_cAliasSC7)->C7_L_EXEMG 

                If !Empty((_cAliasSC7)->C7_OBS) .And. !Upper(AllTrim((_cAliasSC7)->C7_OBS)) $ Upper(_cObs)
                   _cObs+=AllTrim((_cAliasSC7)->C7_OBS)+" // "
                EndIf

				(_cAliasSC7)->(DBSkip())
			
			EndDo
			
            (_cAliasSC7)->(DBGoTop())
			nTotMerc:= MaFisRet(,'NF_TOTAL')
			nTotIpi	:= MaFisRet(,'NF_VALIPI')
			nTotDesp:= MaFisRet(,'NF_DESPESA')
			_nTotImp:= nTotal+nTotIpi
		    _nOutImp:= MaFisRet(,'NF_VALISS')+MaFisRet(,'NF_VALIRR')+MaFisRet(,'NF_VALINS')+MaFisRet(,'NF_VALSOL')

	         If(_cAliasSC7)->C7_TPFRETE = "F"
	            nTotFrete:=(_cAliasSC7)->C7_FRETCON
	         Else
	            nTotFrete:= MaFisRet(,'NF_FRETE')
	         EndIf
			nTotSeguro	:= MaFisRet(,'NF_SEGURO')

    
	        _cObs:=LEFT( _cObs, Len(_cObs)-4)
	        If (_cAliasSC7)->C7_MOEDA <> 1
	           _cObs:=MCOM004Moeda((_cAliasSC7)->C7_MOEDA,(_cAliasSC7)->C7_TXMOEDA,_cObs,(_cAliasSC7)->C7_EMISSAO)
            EndIf

			If "</b>" $ _cPObsProdAlter
			   If !Empty(_cObs) 
			      _cPObsProdAlter:=_cObs+ENTERBR+_cPObsProdAlter
			   EndIf
			Else
			   _cPObsProdAlter:=_cObs
			EndIf

	        _oProcess:oHtml:ValByName("cObs", _cPObsProdAlter)//FORA While/PC_APROVADOR.HTM

            _cTotais:=MCOM004Totais((_cAliasSC7)->C7_MOEDA,(_cAliasSC7)->C7_TXMOEDA,nTotal,.F.)
        	_oProcess:oHtml:ValByName("nTotMer"	, _cTotais	)

            _cTotais:=MCOM004Totais((_cAliasSC7)->C7_MOEDA,(_cAliasSC7)->C7_TXMOEDA,_nTotImp,.F.)
        	_oProcess:oHtml:ValByName("nTotImp"	, _cTotais	)

            _cTotais:=MCOM004Totais((_cAliasSC7)->C7_MOEDA,(_cAliasSC7)->C7_TXMOEDA,nTotDesc,.F.)
        	_oProcess:oHtml:ValByName("nTotDesc"	, _cTotais	)

            _cTotais:=MCOM004Totais((_cAliasSC7)->C7_MOEDA,(_cAliasSC7)->C7_TXMOEDA,nTotIpi,.F.)
			_oProcess:oHtml:ValByName("nIPI"	, _cTotais 	)

            _cTotais:=MCOM004Totais((_cAliasSC7)->C7_MOEDA,(_cAliasSC7)->C7_TXMOEDA,nTotIcms,.F.)
			_oProcess:oHtml:ValByName("nICMS"	, _cTotais)

            _cTotais:=MCOM004Totais((_cAliasSC7)->C7_MOEDA,(_cAliasSC7)->C7_TXMOEDA,_nOutImp,.F.)
	        _oProcess:oHtml:ValByName("nOutImp"	, _cTotais	)

            _cTotais:=MCOM004Totais((_cAliasSC7)->C7_MOEDA,(_cAliasSC7)->C7_TXMOEDA,nTotDesp,.F.)
 			_oProcess:oHtml:ValByName("nDesp"	, _cTotais)

            _cTotais:=MCOM004Totais((_cAliasSC7)->C7_MOEDA,(_cAliasSC7)->C7_TXMOEDA,nTotFrete,.F.)
			_oProcess:oHtml:ValByName("nVlFrete", _cTotais 	)

            If _lGrpLeite
	           _cTotais:=MCOM004Totais(1,0,nC7_L_EXEMG,(_cAliasSC7)->C7_TXMOEDA <> 1)
	           _oProcess:oHtml:ValByName("cGord"  ,"Vlr.Pag.MG")
	        Else
               _cTotais:=MCOM004Totais((_cAliasSC7)->C7_MOEDA,(_cAliasSC7)->C7_TXMOEDA,nTotSeguro,.F.)
	           _oProcess:oHtml:ValByName("cGord"  ,"Seguro")
	        EndIf
		    _oProcess:oHtml:ValByName("nSeguro", _cTotais)

            _cTotais:=MCOM004Totais((_cAliasSC7)->C7_MOEDA,(_cAliasSC7)->C7_TXMOEDA,nTotMerc,.F.)
		    _oProcess:oHtml:ValByName("nTotGer"	, _cTotais	)


			cQrySCR := "SELECT CR_USER, CR_APROV, CR_DATALIB, CR_I_HRAPR, CR_STATUS, R_E_C_N_O_ NUMREC, CR_NIVEL, CR_OBS "
			cQrySCR += "FROM " + RetSqlName("SCR") + " "
			cQrySCR += "WHERE CR_FILIAL = '" + (_cAliasSCR)->CR_FILIAL + "' "
			cQrySCR += "  AND CR_NUM = '" + cNumPC + "' "
			cQrySCR += "  AND CR_TIPO = 'PC' "
			cQrySCR += "  AND D_E_L_E_T_ = ' ' "  
			cQrySCR += "  ORDER BY CR_FILIAL, CR_NUM, CR_NIVEL "

			dbUseArea( .T. , "TOPCONN" , TcGenQry(,, cQrySCR ) , "TRBSCR" , .T., .F. )
					
			DBSelectArea("TRBSCR")
			TRBSCR->(DBGoTop())
					
			If !TRBSCR->(Eof())
				While !TRBSCR->(Eof())
				
					nLinhas ++
					SCR->(DBGoTo(TRBSCR->NUMREC))
				
					If aScan(aAprov,{|A| A[6] == TRBSCR->CR_USER+"|"+TRBSCR->CR_NIVEL } ) <> 0
			           If TRBSCR->CR_STATUS <> "02"//Os recnos do status = 02 já peguei lá em cima
			              aAdd(_aRecRepets, TRBSCR->NUMREC )
                          cMensagem+="User: "+TRBSCR->CR_USER+" - "+UsrRetMail(TRBSCR->CR_USER)+" no Nivel: "+cNivelAP+" / Status: "+TRBSCR->CR_STATUS+" / "
                          cMensagem+=cNumPC+" / "+cFilPC+" / "+cNomFil+" / Recno: "+AllTrim(Str( TRBSCR->NUMREC ))
                          cMensagem+=" Deletado"
                          cMensagem+=CHR(13)+CHR(10)
			           EndIf
					   TRBSCR->(DBSkip())
					   Loop
					EndIf				
				
					If Empty(TRBSCR->CR_APROV)
						aAdd( _oProcess:oHtml:ValByName("Apr.Aprovador")	, "")
					Else
						aAdd( _oProcess:oHtml:ValByName("Apr.Aprovador")	, "Sr.(a) " + MCOM004FullNome(TRBSCR->CR_USER,.T.) )
					EndIf
					
					If Empty(TRBSCR->CR_DATALIB)
						aAdd( _oProcess:oHtml:ValByName("Apr.DtAprov")		, DToC(SToD("//")))
					Else
						aAdd( _oProcess:oHtml:ValByName("Apr.DtAprov")		, DToC(SToD(TRBSCR->CR_DATALIB)))
					EndIf

					If Empty(TRBSCR->CR_I_HRAPR)
						aAdd( _oProcess:oHtml:ValByName("Apr.HrAprov")		, "")
					Else
						aAdd( _oProcess:oHtml:ValByName("Apr.HrAprov")		, TRBSCR->CR_I_HRAPR)
					EndIf

					If Empty(SCR->CR_OBS)
						aAdd( _oProcess:oHtml:ValByName("Apr.ObsAprov")		, "")
					Else
						aAdd( _oProcess:oHtml:ValByName("Apr.ObsAprov")		, AllTrim(SCR->CR_OBS))
					EndIf
					
					If Empty(TRBSCR->CR_STATUS)
						aAdd( _oProcess:oHtml:ValByName("Apr.NivelAprov")	, ""		)
					Else
						If TRBSCR->CR_STATUS == '01'
							cNivel := "Nível Bloqueado"
						ElseIf TRBSCR->CR_STATUS == '02'
							cNivel := "Aguardando Aprovação"
						ElseIf TRBSCR->CR_STATUS == '03'
							cNivel := "Nível Aprovado"
						ElseIf TRBSCR->CR_STATUS == '04'
							cNivel := "PC Bloqueado"
						EndIf

						aAdd( _oProcess:oHtml:ValByName("Apr.NivelAprov")	, cNivel		)
					EndIf

					If aScan(aAprov,{|A| A[6] == TRBSCR->CR_USER+"|"+TRBSCR->CR_NIVEL } ) = 0
					aAdd(aAprov, {	"Sr.(a) " + MCOM004FullNome(TRBSCR->CR_USER,.T.),;	// [01] Nome do Aprovador
									DToC(SToD(TRBSCR->CR_DATALIB)),;	// [02] Data da Liberação
									TRBSCR->CR_I_HRAPR,;				// [03] Hora da Aprovação
									AllTrim(SCR->CR_OBS),;			    // [04] Observação da Aprovação
									cNivel,;							// [05] Nível do Aprovador
									TRBSCR->CR_USER+"|"+TRBSCR->CR_NIVEL})//[06] Chave para previnir duplicação
					EndIf				
					TRBSCR->(DBSkip())
				End
			Else
		        aAdd( _oProcess:oHtml:ValByName("Apr.Aprovador")	, "")
		        aAdd( _oProcess:oHtml:ValByName("Apr.HrAprov")		, "")
		        aAdd( _oProcess:oHtml:ValByName("Apr.DtAprov")		, "")
		        aAdd( _oProcess:oHtml:ValByName("Apr.ObsAprov")		, "")
	        	aAdd( _oProcess:oHtml:ValByName("Apr.NivelAprov")	, "")
			EndIf

			_oProcess:oHtml:ValByName("nLinhas"	, StrZero(nLinhas, 2) 	)

			aAdd(aDados, {	cFilPC,;				// [01] Filial do Pedido de Compras
							cUsuario,;				// [02] Código do Usuário
							cNomFil,;				// [03] Nome da Filial
							cNumPC,;				// [04] Número do Pedido
							cNivelAP,;				// [05] Nível do Aprovador
							cEndFil,;				// [06] Endereço da Filial
							cCepFil,;				// [07] CEP da Filial
							cCidFil,;				// [08] Cidade da Filial		
							cEstFil,;				// [09] Estado da Filial
							cTelFil,;				// [10] Telefone da Filial
							cFaxFil,;				// [11] Fax da Filial
							cCGCFil,;				// [12] CGC da Filial
							cIEFil,;				// [13] I.E da Filial
							cNomGes,;				// [14] Nome do Gestor de Compras
							cNomSol,;				// [15] Nome do Solicitante
							cNomApr,;				// [16] Nome do Aprovador
							cAplic,;				// [17] Aplicação
							cUrgen,;				// [18] Urgente
							cCmpdi,;				// [19] Compra Direta
							cEmissao,;				// [20] Emissão do Pedido de Compras
							cNomFor,;				// [21] Nome do Fornecedor
							cCgcFor,;				// [22] CGC do Fornecedor
							cEndFor,;				// [23] Endereço do Fornecedor
							cCEPFor,;  				// [24] CEP do Fornecedor
							cCidFor,;				// [25] Município do Fornecedor
							cEstFor,;				// [26] Estado do Fornecedor
							cTelFor,;				// [27] Telefone do Fornecedor
							cFaxFor,;				// [28] Fax do Fornecedor
							cIEFor,;				// [29] I.E do Fornecedor
							cContatFor,;			// [30] Contato
							cCondPG,;				// [31] Condição de Pagamento
							cTransp,;				// [32] Dados da Transportadora
							nTotal,;				// [33] Total do Pedido
							nTotMerc,;				// [34] Total das Mercadorias
							nTotIpi,;				// [35] Total IPI
							nTotIcms,;				// [36] Total ICMS
							nTotDesp,;				// [37] Total das Despesas
							nTotFrete,;				// [38] Total do Frete
							nTotSeguro,;			// [39] Total do Seguro
							nTotDesc,;				// [40] Total Desconto
							_cObs,;					// [41] Observação do Pedido
							cTpFrete,;				// [42] Tipo de Frete
							aItens,;				// [43] Dados dos Itens
							aAprov,;				// [44] Dados dos Aprovadores
							cCorUrgen,;             // [45] Cor variavel Urgente
							cReavaliar,;			// [46] Reavaliar ou não
							_cnumsc,;				// [47] Numero da SC
							_cscemissao,;			// [48] Emissão da SC
							_cscaprov,;             // [49] Aprovação da SC
							_nMoedaSC7,;            // [50] MOEDA 
							_nTxMoeSC7,;            // [51] TAXA da MOEDA
							_nDtMoeSC7,;            // [52] DATA DA TAXA da MOEDA
							_cPObsProdAlter})       // [53] Observação com produtos alternaivos


			cEstFil	:= AllTrim(SM0->M0_ESTCOB)
			cTelFil	:= '(' + SubStr(SM0->M0_TEL,4,2) + ')' + SubStr(SM0->M0_TEL,7,4) + '-' +SubStr(SM0->M0_TEL,11,4)
			cFaxFil	:= '(' + SubStr(SM0->M0_FAX,4,2) + ')' + SubStr(SM0->M0_FAX,7,4) + '-' +SubStr(SM0->M0_FAX,11,4)
			cCGCFil	:= formCPFCNPJ(SM0->M0_CGC)
			cIEFil	:= AllTrim(SM0->M0_INSC)
		
			nContrl	:= 0

			cEmail := (_cAliasSCR)->CR_USER

			DBSelectArea("TRBSCR")
			TRBSCR->(DBCloseArea())

			//=========================================================================
   			// Informe o nome da função de retorno a ser executada quando a mensagem de
			// respostas retornar ao Workflow:
			//=========================================================================
			_oProcess:bReturn := "U_MCOM004R"//Retorno do pc_aprovador.htm
		
			//========================================================================
			// Após ter repassado todas as informacões necessárias para o Workflow,
			// execute o método Start() para gerar todo o processo e enviar a mensagem
			// ao destinatário.
	   	    //========================================================================
    		_cMailID := _oProcess:Start("\workflow\emp01\MCOM004")
    		cLink := _cMailID

			If !File("\workflow\emp01\MCOM004\" + _cMailID + ".htm")
				FWLogMsg("WARN"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00414"/*cMsgId*/,"MCOM00314 - 01 - Arquivo:  \workflow\emp01\MCOM004\" + _cMailID + ".htm nao encontrado."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
			EndIf 

			//====================================
			//Codigo do processo cadastrado no CFG
			//====================================
			_cCodProce := "PEDIDO"

			//===========================================================
			// Arquivo html template utilizado para montagem da aprovação
			//===========================================================
			_cHtmlMode := "\Workflow\htm\pc_link.htm"

			//====================
			// Assunto da mensagem
			//====================
			_cAssunto := "2-Aprovação " + AllTrim(cNomFil) + " - " + "PC " + cNumPC + " - " + AllTrim(cNomFor)

			//======================================================================
			// Inicialize a classe TWFProcess e assinale a variável objeto oProcess:
			//======================================================================
			_oProcess := TWFProcess():New(_cCodProce,"Aprovação do Pedido de Compras")

			//=================================================================
			// Criamos o link para o arquivo que foi gerado na tarefa anterior.  
			//=================================================================
			_oProcess:NewTask("LINK", "\workflow\htm\pc_link.htm")//Atalho no corpo do CORPO DO EMAIL			

			chtmlfile := cLink + ".htm"
			cMailTo	:= "mailto:" + AllTrim(Posicione("WF7", 1, xFilial("WF7") + _cMV_WFMLBOX, "WF7_ENDERE"))
			chtmltexto := wfloadfile("\workflow\emp01\MCOM004\" + chtmlfile )//Carrega o arquivo 
			chtmltexto := StrTran( chtmltexto, cmailto, "WFHTTPRET.APL" )//Procura e troca a string
			wfsavefile("\workflow\emp01\MCOM004\" + chtmlfile, chtmltexto)//Grava o arquivo de volta

			cLink := _cHostWF + "emp01/MCOM004/" + cLink + ".htm"

			//=====================================
			// Populo as variáveis do template html
			//=====================================
			_oProcess:oHtml:ValByName("cLogo"		, cLogo 	)
  			_oProcess:oHtml:ValByName("A_LINK"		, cLink	    )//clique no CORPO DO EMAIL
			_oProcess:oHtml:ValByName("A_NOMSOL"	, cNomSol	)
			_oProcess:oHtml:ValByName("A_NOMAPR"	, MCOM004FullNome((_cAliasSCR)->CR_USER,.T.))
			_oProcess:oHtml:ValByName("A_CUSTO"		, cCcusto	)
			_oProcess:oHtml:ValByName("A_URGEN"		, cUrgen	)
			_oProcess:oHtml:ValByName("A_INVES"		, cAplic	)
			_oProcess:oHtml:ValByName("A_CMPDI"		, cCmpdi	)
			_oProcess:oHtml:ValByName("A_FORNEC"	, AllTrim(cNomFor) + " - " + AllTrim(cCgcFor)	)

			cQryDT := "SELECT MIN(C7_DATPRF) C7_DATPRF "
			cQryDT += "FROM " + RetSqlName("SC7") + " "
			cQryDT += "WHERE C7_FILIAL = '" + SubStr(cFilPC,1,2) + "' "
			cQryDT += " AND C7_NUM = '" + cNumPC + "' "
			cQryDT += " AND C7_RESIDUO <> 'S' "
			cQryDT += " AND D_E_L_E_T_ = ' ' "
			
			dbUseArea(.T., "TOPCONN", TcGenQry(,,cQryDT), "TRBDT", .T., .F.)
			
			DBSelectArea("TRBDT")
			TRBDT->(DBGoTop())
			
			_oProcess:oHtml:ValByName("A_DTENTR"	, DToC(SToD(TRBDT->C7_DATPRF))		)
			
			DBSelectArea("TRBDT")
			TRBDT->(DBCloseArea())

		    SC7->(DBSetOrder(1))
		    SC7->(DBSeek(SubStr(cFilPC,1,2)+cNumPC))
			
			_oProcess:oHtml:ValByName("A_VLTOTAL" , MCOM004Totais(SC7->C7_MOEDA,0,nTotMerc))//AllTrim(GETMV("MV_SIMB"+AllTrim(Str(SC7->C7_MOEDA))))+" "+Transform(nTotMerc,PesqPict("SC7","C7_TOTAL"))	)
			_oProcess:oHtml:ValByName("A_OBSPC"   , _cObs    )//**PC_LINK.HTM*****************
			_oProcess:oHtml:ValByName("A_OBSSC"   , cObsSc   )//PC_LINK.HTM
	        _oProcess:oHtml:ValByName("A_OBSSCGEN", cObsScGen)//PC_LINK.HTM

			//=========================
			//Dados dos questionamentos
			//=========================
			_cQuest:=U_M004Quest((_cAliasSCR)->CR_FILIAL, SubStr((_cAliasSCR)->CR_NUM,1,6))
			If !Empty(_cQuest)
				_oProcess:oHtml:ValByName("cQuest", _cQuest )
			Else
				_oProcess:oHtml:ValByName("cQuest", "" )
			EndIf

			For nX := 1 To Len(aDados)

				//=======================================
				//Dados do cabeçalho do pedido de compras
				//=======================================
				_oProcess:oHtml:ValByName("cLogo"			, cLogo )
				_oProcess:oHtml:ValByName("cNomFil"			, aDados[nX][01])
				_oProcess:oHtml:ValByName("cEndFil"			, aDados[nX][06])
				_oProcess:oHtml:ValByName("cCepFil"			, aDados[nX][07])
				_oProcess:oHtml:ValByName("cCidFil"			, aDados[nX][08])
				_oProcess:oHtml:ValByName("cEstFil"			, aDados[nX][09])
				_oProcess:oHtml:ValByName("cTelFil"			, aDados[nX][10])
				_oProcess:oHtml:ValByName("cFaxFil"			, aDados[nX][11])
				_oProcess:oHtml:ValByName("cCGCFil"			, aDados[nX][12])
				_oProcess:oHtml:ValByName("cIEFil"			, aDados[nX][13])
				_oProcess:oHtml:ValByName("NumPC"			, aDados[nX][04])
				_oProcess:oHtml:ValByName("cnumSC"			, aDados[nX][47])
				_oProcess:oHtml:ValByName("cdtinc"			, aDados[nX][48])
				_oProcess:oHtml:ValByName("cdtapr"			, aDados[nX][49])
								
		
				If Empty(aDados[nX][14])
					_oProcess:oHtml:ValByName("cNomGes"  , "")
				Else
					_oProcess:oHtml:ValByName("cNomGes", aDados[nX][14])
				EndIf
		
				If Empty(aDados[nX][15])
					_oProcess:oHtml:ValByName("cNomSol"			, "")
				Else
					_oProcess:oHtml:ValByName("cNomSol"			, aDados[nX][15])
				EndIf
								
				If Empty(aDados[nX][16])
					_oProcess:oHtml:ValByName("cNomApr"			, "")
				Else
					_oProcess:oHtml:ValByName("cNomApr"			, aDados[nX][16])
				EndIf
		
				_oProcess:oHtml:ValByName("cDigiFor"		, MCOM004FullNome(aDados[nX][02],.T.) )

				If aDados[nX][50] <> 1
				   _cObs:=MCOM004Moeda(aDados[nX][50],aDados[nX][51],aDados[nX][41],aDados[nX][52])
                Else
				   _cObs:=AllTrim(aDados[nX][41]) 
                EndIf
				_cPObsProdAlter:=aDados[nX][53]

				_oProcess:oHtml:ValByName("cObs", _cPObsProdAlter) //ESTA ANTES DO For DOS ITENS PQ O aDados[nX][41] já tem as descricao de todos os itens
		
				_oProcess:oHtml:ValByName("cAplic" 		  	, aDados[nX][17])
				_oProcess:oHtml:ValByName("cUrgen"  		, aDados[nX][18])
				_oProcess:oHtml:ValByName("cCorUrgen"  		, aDados[nX][45])
				_oProcess:oHtml:ValByName("cCompDir"  		, aDados[nX][19])
				_oProcess:oHtml:ValByName("dDtEmiss"  		, aDados[nX][20])
		
				_oProcess:oHtml:ValByName("cNomFor"			, aDados[nX][21])
				_oProcess:oHtml:ValByName("cEndFor"			, aDados[nX][23])
				_oProcess:oHtml:ValByName("cCEPFor"			, aDados[nX][24])
				_oProcess:oHtml:ValByName("cCidFor"			, aDados[nX][25])
				_oProcess:oHtml:ValByName("cEstFor"			, aDados[nX][26])
				_oProcess:oHtml:ValByName("cTelFor"			, aDados[nX][27])
				_oProcess:oHtml:ValByName("cFaxFor"			, aDados[nX][28])
				_oProcess:oHtml:ValByName("cCGCFor"			, aDados[nX][22])
				_oProcess:oHtml:ValByName("cIEFor"	 		, aDados[nX][29])
				_oProcess:oHtml:ValByName("cContatFor"		, aDados[nX][30])
				_oProcess:oHtml:ValByName("cCondPG"	  		, aDados[nX][31])		
				_oProcess:oHtml:ValByName("cTransp"	  		, aDados[nX][32])				
				_oProcess:oHtml:ValByName("cFrete"			, aDados[nX][42])				
				_oProcess:oHtml:ValByName("cReavaliar"      , aDados[nX][46])
                
				//Conout("05-IT_GRPLEITE =" +_cGrpLeite + ' /  _lGrpLeite =' + If(_lGrpLeite,".T.",".F.")+" / cFilant = "+cFilant+" / (_cAliasSC7)->C7_GRUPCOM = "+(_cAliasSC7)->C7_GRUPCOM )
				If _lGrpLeite
				   _oProcess:oHtml:ValByName("cTitulo"," - DPTO. LEITE")
				Else
				   _oProcess:oHtml:ValByName("cTitulo","")
				EndIf

				For nI := 1 To Len(aDados[nX][43])			
					aAdd( _oProcess:oHtml:ValByName("Itens.Item" 		), aDados[nX][43][nI][01])
					aAdd( _oProcess:oHtml:ValByName("Itens.Prodpc" 		), aDados[nX][43][nI][02])
					aAdd( _oProcess:oHtml:ValByName("Itens.DesProd"		), aDados[nX][43][nI][03])
					aAdd( _oProcess:oHtml:ValByName("Itens.UM"			), aDados[nX][43][nI][04])
					aAdd( _oProcess:oHtml:ValByName("Itens.qtde"		), aDados[nX][43][nI][05])

                    _cValor:=MCOM004Totais(aDados[nX][50],0,aDados[nX][43][nI][06],.F.)
			        aAdd( _oProcess:oHtml:ValByName("Itens.VlrUni"		), _cValor)//aDados[nX][43][nI][06])

                    _cValor:=MCOM004Totais(aDados[nX][50],0,aDados[nX][43][nI][07],.F.)
		        	aAdd( _oProcess:oHtml:ValByName("Itens.VlrDes"		), _cValor)//aDados[nX][43][nI][07])

                    _cValor:=MCOM004Totais(aDados[nX][50],0,aDados[nX][43][nI][15],.F.)//Valor com Desconto
		        	aAdd( _oProcess:oHtml:ValByName("Itens.VlrTot"		), _cValor)//aDados[nX][43][nI][08])-aDados[nX][43][nI][07]

                    _cValor:=MCOM004Totais(1,0,aDados[nX][43][nI][09],.F.,.T.)
			        aAdd( _oProcess:oHtml:ValByName("Itens.ICMS"		), _cValor)

                    _cValor:=MCOM004Totais(1,0,aDados[nX][43][nI][12],aDados[nX][50] <> 1)
			        aAdd( _oProcess:oHtml:ValByName("Itens.VlrUc"		), _cValor)//aDados[nX][43][nI][12])
                 aAdd( _oProcess:oHtml:ValByName("Itens.DtUc"		), aDados[nX][43][nI][16])//aDados[nX][43][nI][16])

			        aAdd( _oProcess:oHtml:ValByName("Itens.DtEmis"		), aDados[nX][43][nI][11])
					aAdd( _oProcess:oHtml:ValByName("Itens.SldAtFil"	), aDados[nX][43][nI][13])
					aAdd( _oProcess:oHtml:ValByName("Itens.SldAtEmp"	), aDados[nX][43][nI][14])

				Next nI

                _cTotais:=MCOM004Totais(aDados[nX][50],aDados[nX][51],aDados[nX][33],.F.)
		        _oProcess:oHtml:ValByName("nTotMer"	, _cTotais)

                _cTotais:=MCOM004Totais(aDados[nX][50],aDados[nX][51],_nTotImp,.F.)
		        _oProcess:oHtml:ValByName("nTotImp"	, _cTotais)

                _cTotais:=MCOM004Totais(aDados[nX][50],aDados[nX][51],aDados[nX][40],.F.)
		        _oProcess:oHtml:ValByName("nTotDesc"	, _cTotais)
		
                _cTotais:=MCOM004Totais(aDados[nX][50],aDados[nX][51],aDados[nX][35],.F.)
				_oProcess:oHtml:ValByName("nIPI"	, _cTotais)

                _cTotais:=MCOM004Totais(aDados[nX][50],aDados[nX][51],aDados[nX][36],.F.)
				_oProcess:oHtml:ValByName("nICMS"	, _cTotais)

                _cTotais:=MCOM004Totais(aDados[nX][50],aDados[nX][51],_nOutImp,.F.)
	            _oProcess:oHtml:ValByName("nOutImp"	, _cTotais	)

                _cTotais:=MCOM004Totais(aDados[nX][50],aDados[nX][51],aDados[nX][37],.F.)
				_oProcess:oHtml:ValByName("nDesp"	, _cTotais)

                _cTotais:=MCOM004Totais(aDados[nX][50],aDados[nX][51],aDados[nX][38],.F.)
				_oProcess:oHtml:ValByName("nVlFrete", _cTotais)

                If _lGrpLeite
	               _cTotais:=MCOM004Totais(1,0,nC7_L_EXEMG,aDados[nX][50] <> 1)
	               _oProcess:oHtml:ValByName("cGord","Vlr.Pag.MG")
	            Else
                   _cTotais:=MCOM004Totais(aDados[nX][50],aDados[nX][51],aDados[nX][39],.F.)
	               _oProcess:oHtml:ValByName("cGord"  ,"Seguro")
	            EndIf
			    _oProcess:oHtml:ValByName("nSeguro", _cTotais)
		        
		        _cTotais:=MCOM004Totais(aDados[nX][50],aDados[nX][51],aDados[nX][34],.F.)
				_oProcess:oHtml:ValByName("nTotGer"	, _cTotais	)
		
				For nJ := 1 To Len(aDados[nX][44])
					nLinhas ++
					aAdd( _oProcess:oHtml:ValByName("Apr.Aprovador")	, aDados[nX][44][nJ][01])
					aAdd( _oProcess:oHtml:ValByName("Apr.DtAprov")		, aDados[nX][44][nJ][02])
					aAdd( _oProcess:oHtml:ValByName("Apr.HrAprov")		, aDados[nX][44][nJ][03])
					aAdd( _oProcess:oHtml:ValByName("Apr.ObsAprov")		, aDados[nX][44][nJ][04])
					aAdd( _oProcess:oHtml:ValByName("Apr.NivelAprov")	, aDados[nX][44][nJ][05])
				Next nJ
		
				_oProcess:oHtml:ValByName("nLinhas"	, StrZero(nLinhas, 2) 	)

			Next nX

			aDados	:= {}
			aItens	:= {}
			aAprov	:= {}

	        FWLogMsg("WARN"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00415"/*cMsgId*/,'MCOM00415 - E-mail: '+_cAssunto+' para: ' + UsrRetMail(cEmail)/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

			//================================================================
			// Informamos o destinatário (aprovador) do email contendo o link.  
			//================================================================
			_oProcess:cTo := UsrRetMail(cEmail)//01-"Envio para Aprovacao do PC "

			//===============================
			// Informamos o assunto do email.  
			//===============================
			_oProcess:cSubject	:= FWHttpEncode(_cAssunto)

			//===============================================
			// Informamos o arquivo a ser atachado no e-mail.
			//===============================================
			//_oProcess:AttachFile(cConsulta)

			_cRastrear    := "Envio para Aprovacao do PC " + SubStr(cFilPC,1,2) + " " + cNumPC

			_cMailID	:= _oProcess:fProcessId
			_cTaskID	:= _oProcess:fTaskID
			RastreiaWF(_cMailID + '.' + _cTaskID , _oProcess:fProcCode, "1001", _cRastrear, "")

			MCOM004Q(4,"",SubStr(cFilPC,1,2),cNumPC,"1001","2",cLink,"","","","","",_oProcess:fProcessId,cNivelAP)

			//=======================================================
			// Iniciamos a tarefa e enviamos o email ao destinatário.
			//=======================================================
			_oProcess:Start()

	        _oProcess:Finish()
	        
	        If !Empty(_cQuest)
               U_MCOM004F(SubStr(cFilPC,1,2),cNumPC,"Respondido",.T.)
            EndIf   

		EndIf
		
		DBSelectArea(_cAliasSC7)
		(_cAliasSC7)->(DBCloseArea())
		
		(_cAliasSCR)->(DBSkip())
	End
EndIf

If Len(_aRecRepets) > 0
 
    _cGetAssun:="MCOM004 - Usuario repetido no SCR "
    _cEmlLog:=""
	_aConfig:=U_ITCFGEML('')
 
    U_ITENVMAIL( "", "sistema@italac.com.br", "", "", _cGetAssun, cMensagem, "", _aConfig[01], _aConfig[02], _aConfig[03], _aConfig[04], _aConfig[05], _aConfig[06], _aConfig[07], @_cEmlLog )
    FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00416"/*cMsgId*/,"MCOM00416 - "+ _cEmlLog/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
    If "SUCESSO" $ Upper(_cEmlLog)
       For R := 1 To Len(_aRecRepets)
         SCR->( DBGoTo( _aRecRepets[R] ))
         SCR->( RecLock("SCR",.F.) )           
         SCR->( DBDelete() )
         SCR->( MSUnLock() )
			FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00417"/*cMsgId*/,"MCOM00417 - Recno SCR: "+AllTrim(Str( _aRecRepets[R] ))+" Deletado "/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
       Next
    EndIf

EndIf
Return

/*
===============================================================================================================================
Programa----------: MCOM004E
Autor-------------: Darcio Ribeiro Sporl
Data da Criacao---: 18/01/2016
Descrição---------: Rotina responsável por atualizar a flag de reenvio do workflow
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MCOM004E()
Local aArea		:= FWGetArea()
Local _cFilial	:= SC7->C7_FILIAL
Local cQrySC7	:= ""
Local cFilPC	:= SuperGetMV("IT_FILWFPC",.F.,"01")
Local dDatIni	:= SuperGetMV("IT_WFPCINI",.F.,"01/01/2016")

//==================================================================
// Verifica se a filial corrente esta apta a utilização desta rotina
//==================================================================
If cFilAnt $ cFilPC
	//=======================================================================
	// Verifica se pedido posicionado está na condição para reenvio de e-mail
	//=======================================================================
	If SC7->C7_APROV <> "PENLIB" .And. SC7->C7_EMISSAO >= dDatIni
		//===============================================================================
		// O sistema verificará se o pedido posicionado está apto para reenvio de e-mail,
		// se o pedido tiver todos os seus itens com eliminação de resíduo para este pedi
		// do, o sistema não deixará efetuar o reenvio do workflow
		//===============================================================================
		cQrySC7 := "SELECT COUNT(*) C7_QTD "
		cQrySC7 += "FROM " + RetSqlName("SC7") + " "
		cQrySC7 += "WHERE D_E_L_E_T_ = ' ' "
		cQrySC7 += "  AND C7_FILIAL = '" + SC7->C7_FILIAL + "'"
		cQrySC7 += "  AND C7_NUM = '" + SC7->C7_NUM + "' "
		cQrySC7 += "  AND C7_RESIDUO <> 'S' "
		cQrySC7 += "  AND C7_CONAPRO = 'B' "
	
		dbUseArea( .T. , "TOPCONN" , TcGenQry(,, cQrySC7 ) , "TRBSC7" , .T., .F. )
																	
		DBSelectArea("TRBSC7")
		TRBSC7->(DBGoTop())
		
		If TRBSC7->C7_QTD > 0
			//====================================================================================
			// É feita a atualização da tabela SCR, para reenvio do workflow do pedido selecionado
			//====================================================================================
			DBSelectArea("SCR")
			DBSetOrder(1)
            _cMensagem:=""
			DBSeek(_cFilial + "PC" + SC7->C7_NUM)
			While !SCR->(Eof()) .And. SCR->CR_FILIAL == SC7->C7_FILIAL .And. SCR->CR_TIPO == "PC" .And. SubStr(SCR->CR_NUM,1,6) == SC7->C7_NUM
               If SCR->CR_STATUS = "04"
                  _cMensagem:="Bloqueado pelo Worflow de Compras. (Bloqueado por "+AllTrim(Posicione("SAK",1,xFilial("SAK")+SCR->CR_APROV,"AK_NOME"))+" ("+SCR->CR_GRUPO+")"
	         	 Exit
               EndIf
               If SCR->CR_STATUS = "06"
                  _cMensagem:="Rejeitado pelo Worflow de Compras. (Rejeitado por "+AllTrim(Posicione("SAK",1,xFilial("SAK")+SCR->CR_APROV,"AK_NOME"))+" ("+SCR->CR_GRUPO+")"
	         	 Exit
               EndIf
			   SCR->(DBSkip())
			EndDo
	        If !Empty(_cMensagem)
               U_ITMsg("Pedido não pode ser reenviado, pois o mesmo encontra-se "+_cMensagem,"Atenção","Procure o Gestor de compras.",1)
            Else
			   DBSeek(_cFilial + "PC" + SC7->C7_NUM)
			   While !SCR->(Eof()) .And. SCR->CR_FILIAL == SC7->C7_FILIAL .And. SCR->CR_TIPO == "PC" .And. SubStr(SCR->CR_NUM,1,6) == SC7->C7_NUM
	              If SCR->CR_STATUS == "02"
	                 RecLock("SCR",.F.)
	                 SCR->CR_I_WFID  := " "
	                 SCR->CR_I_DTAVS := SToD(" ")
	                 MSUnLock()
	              EndIf
		   		  SCR->(DBSkip())
			   EndDo		
			   FWAlertInfo("Pedido preparado para reenvio.","MCOM00476")
	        EndIf
		Else
			FWAlertWarning("Pedido não pode ser reenviado, pois o mesmo encontra-se Liberado ou eliminado resíduo.","MCOM00477")
		EndIf
		
		DBSelectArea("TRBSC7")
		TRBSC7->(DBCloseArea())
	Else
		If SC7->C7_CONAPRO == 'B' .And. SC7->C7_APROV == "PENLIB"
			FWAlertWarning("Este pedido não pode ser reenviado, pois este ainda não foi liberado pelo Gestor de Compras.","MCOM00478")
		ElseIf SC7->C7_EMISSAO < dDatIni
			FWAlertWarning("Este Pedido não pode ser reenviado, pois sua data de emissão é anterior a data de início de utilização do Workflow.","MCOM00479")
		Else
			FWAlertWarning("Este Pedido não pode ser reenviado, pois este encontra-se Liberado.","MCOM00480")
		EndIf
	EndIf
Else
	FWAlertWarning("Filial não habilitada para utilização desta rotina.","MCOM00481")
EndIf

FWRestArea(aArea)
Return
/*
===============================================================================================================================
Programa----------: MCOM004L
Autor-------------: Darcio Ribeiro Sporl
Data da Criacao---: 12/02/2016
Descrição---------: Rotina responsável por montar a lista de PC's por Aprovador e enviar por e-mail via Workflow
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MCOM004L()
Local cQrySCR		:= ""
Local cQrySC7		:= ""
Local _lCriaAmb		:= .F.
Local lWFHTML		:= .T.
Local _aTables		:= {"SCR","SC7","ZZ7","ZZ8","ZZI","CTT","ZZL","ZP1"}
Local _cCodProce	:= ""
Local _cAssunto		:= ""
Local _cTaskID		:= ""
Local cDatAtual     := DToS(Date())
Local _cMV_WFMLBOX  := ""
Local _oProcess

Private _cHostWF	:= ""
Private _dDtIni		:= ""
Private cLogo		:= ""

If Select("SX3") <= 0
	_lCriaAmb:= .T.
EndIf                           
             
If _lCriaAmb

	//====================
	//Nao consome licensas
	//====================
	RPCSetType(3)

	//==========================================
	//seta o ambiente com a empresa 01 filial 01
	//==========================================   	 
	RpcSetEnv("01","01",,,,"SCHEDULE_WF_PEDIDOS",_aTables)

EndIf 

_cHostWF := SuperGetMV("IT_WFHOSTS",.F.,"http://wfteste.italac.com.br:4034/")
_dDtIni	 := DToS(SuperGetMV("IT_WFDTINI",.F.,"26/11/2025"))
cLogo	 := _cHostWF + "htm/logo_novo.jpg"

_cMV_WFMLBOX:= AllTrim(GetMV('MV_WFMLBOX'))
lWFHTML	    := GetMv("MV_WFHTML")

PutMV("MV_WFHTML",.T.)

cQrySCR := "SELECT DISTINCT(CR_USER) "
cQrySCR += "FROM " + RetSqlName("SCR") + " SCR "
cQrySCR += "WHERE CR_STATUS = '02' "
cQrySCR += "  AND CR_I_WFID <> ' ' "
cQrySCR += "  AND CR_TIPO = 'PC' "     
cQrySCR += "  AND CR_EMISSAO <> '" + cDatAtual + "' "
cQrySCR += "  AND EXISTS (SELECT 'Y' FROM " +  RetSqlName("SC7") + " SC7 WHERE SC7.C7_FILIAL = SCR.CR_FILIAL AND SC7.C7_NUM = TRIM(SCR.CR_NUM) AND SC7.C7_RESIDUO <>'S' AND SC7.D_E_L_E_T_ = ' ') "
cQrySCR += "  AND SCR.D_E_L_E_T_ = ' ' "
cQrySCR += "ORDER BY CR_USER "

dbUseArea(.T., "TOPCONN", TcGenQry(,,cQrySCR), "TRBSCR", .T., .F.)
	
DBSelectArea("TRBSCR")
TRBSCR->(DBGoTop())

While !TRBSCR->(Eof())

	//====================================
	//Codigo do processo cadastrado no CFG
	//====================================
	_cCodProce := "PEDIDO"

	//======================================================================
	// Inicialize a classe TWFProcess e assinale a variável objeto oProcess:
	//======================================================================
	_oProcess := TWFProcess():New(_cCodProce,"Aprovação de Pedido de Compras")

	_oProcess:NewTask("LINK", "\workflow\htm\pc_lista.htm")

	_cMailID	:= _oProcess:fProcessId
	_cTaskID	:= _oProcess:fTaskID

	chtmlfile	:= _cMailID + ".htm"
	cMailTo		:= "mailto:" + AllTrim(Posicione("WF7", 1, xFilial("WF7") + _cMV_WFMLBOX, "WF7_ENDERE"))
	chtmltexto	:= wfloadfile("\workflow\emp01\MCOM004\" + chtmlfile )//Carrega o arquivo 
	chtmltexto	:= StrTran( chtmltexto, cmailto, "WFHTTPRET.APL" )//Procura e troca a string
	wfsavefile("\workflow\emp01\MCOM004\" + chtmlfile, chtmltexto)//Grava o arquivo de volta
			
	If _lCriaAmb
	   RastreiaWF(_cMailID + '.' + _cTaskID , _oProcess:fProcCode, "1001", "Recebimento da Aprovacao do PC", "")
    EndIf

	cQrySC7 := "SELECT DISTINCT(CR_NUM) CR_NUM, CR_FILIAL, CR_USER "
	cQrySC7 += "FROM " + RetSqlName("SCR") + " SCR "
	cQrySC7 += "WHERE CR_STATUS = '02' "
	cQrySC7 += "  AND CR_USER = '" + TRBSCR->CR_USER + "' "
	cQrySC7 += "  AND CR_I_WFID <> ' ' "
	cQrySC7 += "  AND CR_TIPO = 'PC' "     
	cQrySC7 += "  AND CR_EMISSAO <> '" + cDatAtual + "' "
	cQrySC7 += "  AND SCR.D_E_L_E_T_ = ' ' " 
	cQrySC7 += "  AND EXISTS (SELECT 'Y' FROM " +  RetSqlName("SC7") + " SC7 WHERE SC7.C7_FILIAL = SCR.CR_FILIAL AND SC7.C7_NUM = TRIM(SCR.CR_NUM) AND SC7.C7_RESIDUO <>'S' AND SC7.D_E_L_E_T_ = ' ') "
	cQrySC7 += "ORDER BY CR_USER,CR_FILIAL, CR_NUM "

	dbUseArea(.T., "TOPCONN", TcGenQry(,,cQrySC7), "TRBSC7", .T., .F.)

	DBSelectArea("TRBSC7")
	TRBSC7->(DBGoTop())

	While !TRBSC7->(Eof())

		DBSelectArea("SC7")
		DBSetOrder(1)
		DBSeek(TRBSC7->CR_FILIAL + SubStr(TRBSC7->CR_NUM,1,6))

		While !SC7->(Eof()) .And. SC7->C7_FILIAL == TRBSC7->CR_FILIAL .And. SC7->C7_NUM == SubStr(TRBSC7->CR_NUM,1,6)

			If SC7->C7_RESIDUO <> 'S' .And. !Empty(SC7->C7_I_HTM)
				aAdd( _oProcess:oHtml:ValByName("itens.FILIAL")	, TRBSC7->CR_FILIAL + " - " + AllTrim(FWFilialName(cEmpAnt,TRBSC7->CR_FILIAL,1))	)
				aAdd( _oProcess:oHtml:ValByName("itens.EMISSA")	, DToC(SC7->C7_EMISSAO)									  							)
				aAdd( _oProcess:oHtml:ValByName("itens.NUMPC")	, SubStr(TRBSC7->CR_NUM,1,6)														)
				aAdd( _oProcess:oHtml:ValByName("itens.COMPRA")	, MCOM004FullNome(SC7->C7_USER)														)
				aAdd( _oProcess:oHtml:ValByName("itens.FORNEC")	, Posicione("SA2",1,xFilial("SA2") + SC7->C7_FORNECE	+ SC7->C7_LOJA,"A2_NOME")	)
				If SC7->C7_I_SITWF == 'Q'
					aAdd( _oProcess:oHtml:ValByName("itens.OBSERV")	, "Aguardando resposta do questionamento."										)
					aAdd( _oProcess:oHtml:ValByName("itens.LINK")	, ""																			)
					aAdd( _oProcess:oHtml:ValByName("itens.cTxtLnk")	, "Não Disponível!"															)
				Else
					aAdd( _oProcess:oHtml:ValByName("itens.OBSERV")	, AllTrim(SC7->C7_OBS)															)
					aAdd( _oProcess:oHtml:ValByName("itens.LINK")	, AllTrim(SC7->C7_I_HTM)														)//Atalho no corpo do CORPO DO EMAIL
					aAdd( _oProcess:oHtml:ValByName("itens.cTxtLnk")	, "Clique Aqui!"															)
				EndIf
				Exit
			EndIf

			SC7->(DBSkip())
		End

		TRBSC7->(DBSkip())
	End

	cAprNom := MCOM004FullNome(TRBSCR->CR_USER)
	cAprNom	:= SubStr(cAprNom, 1, At(" ", cAprNom)-1)

	_oProcess:oHtml:ValByName("cLogo"	, cLogo		)
	_oProcess:oHtml:ValByName("AprNom"	, cAprNom	)
    _oProcess:oHtml:ValByName("Ambiente", AllTrim(Upper(GETENVSERVER())))

	_cAssunto := "3-Lista de Pedidos de Compras Pendente Aprovação."

    _cEmail:=UsrRetMail(TRBSCR->CR_USER) //+ "," + _cEmailCopia
	
	FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00418"/*cMsgId*/,'MCOM00418 - E-mail: '+_cAssunto+' para: ' + _cEmail/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	//====================================================
	// Informamos o destinatário do email contendo o link.  
	//====================================================
	_oProcess:cTo := _cEmail   //02 - lista de PC's por Aprovador
	
	//===============================
	// Informamos o assunto do email.  
	//===============================
	_oProcess:cSubject	:= FWHttpEncode(_cAssunto)

	If _lCriaAmb
	   _cMailID	:= _oProcess:fProcessId
	   _cTaskID	:= _oProcess:fTaskID
	   RastreiaWF(_cMailID + '.' + _cTaskID , _oProcess:fProcCode, "1004", "Lista de Pedidos de Compras Pendente Aprovação", "")
    EndIf
	//=======================================================
	// Iniciamos a tarefa e enviamos o email ao destinatário.
	//=======================================================
	_oProcess:Start()

	DBSelectArea("TRBSC7")
	TRBSC7->(DBCloseArea())

	TRBSCR->(DBSkip())
End

DBSelectArea("TRBSCR")
TRBSCR->(DBCloseArea())

PutMV("MV_WFHTML",lWFHTML)

If _lCriaAmb

	//============================================================
	//Limpa o ambiente, liberando a licença e fechando as conexoes
	//============================================================
	RpcClearEnv()  
	
EndIf

Return

/*
===============================================================================================================================
Programa----------: formCPFCNPJ
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 14/01/2016
Descrição---------: Função criada para formatar CPF/CNPJ
Parametros--------: cCPFCNPJ	- Texto a ser quebrado
Retorno-----------: cCampFormat	- Retorna o campo formatado conforme CPF/CNPJ
===============================================================================================================================
*/
Static Function formCPFCNPJ(cCPFCNPJ)
Local cCampFormat := ""	//Armazena o CPF ou CNPJ formatado
																														   
If Len(AllTrim(cCPFCNPJ)) == 11			//CPF
	cCampFormat:=SubStr(cCPFCNPJ,1,3) + "." + SubStr(cCPFCNPJ,4,3) + "." + SubStr(cCPFCNPJ,7,3) + "-" + SubStr(cCPFCNPJ,10,2) 
Else									//CNPJ
	cCampFormat:=SubStr(cCPFCNPJ,1,2)+"."+SubStr(cCPFCNPJ,3,3)+"."+SubStr(cCPFCNPJ,6,3)+"/"+SubStr(cCPFCNPJ,9,4)+"-"+ SubStr(cCPFCNPJ,13,2)
EndIf
																															
Return cCampFormat

/*
===============================================================================================================================
Programa----------: M004FIniPC
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 14/01/2016
Descrição---------: Inicializa as funções Fiscais com o Pedido de Compras
Parametros--------: ExpC1	- Número do Pedido
				  : ExpC2	- Item do Pedido
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function M004FIniPC(cPedido,cItem,cSequen,cFiltro,cFilScr)

Local aArea		:= FWGetArea()
Local aAreaSC7	:= SC7->(GetArea())
Local nItem		:= 0
Local cItemDe	:= IIf(cItem==Nil,'',cItem)
Local cItemAte	:= IIf(cItem==Nil,Repl('Z',Len(SC7->C7_ITEM)),cItem)

Default cSequen	:= ""
Default cFiltro	:= ""

DBSelectArea("SC7")
DBSetOrder(1)
If DBSeek(cFilScr+cPedido+cItemDe+AllTrim(cSequen))
	MaFisEnd()
	MaFisIni(SC7->C7_FORNECE,SC7->C7_LOJA,"F","N","R",{})
	While !Eof() .And. SC7->C7_FILIAL+SC7->C7_NUM == cFilScr+cPedido .And. SC7->C7_ITEM <= cItemAte .And. (Empty(cSequen) .Or. cSequen == SC7->C7_SEQUEN)

		// Nao processar os Impostos se o item possuir residuo eliminado  
		If  SC7->C7_RESIDUO = "S"
			DBSelectArea('SC7')
			DBSkip()
			Loop
		EndIf

		// Inicia a Carga do item nas funcoes MATXFIS  
		nItem++
		MaFisIniLoad(nItem)
	
		MaFisLoad("IT_PRODUTO",&("SC7->C7_PRODUTO"),nitem)
		MaFisLoad("IT_QUANT",&("SC7->C7_QUANT  "),nitem)
		MaFisLoad("IT_PRCUNI",&("SC7->C7_PRECO  "),nitem)
		MaFisLoad("IT_VALMERC",&("SC7->C7_TOTAL  "),nitem)
		MaFisLoad("IT_DESCONTO",&("SC7->C7_VLDESC "),nitem)
		MaFisLoad("IT_BASEIPI",&("SC7->C7_BASEIPI"),nitem)
		MaFisLoad("IT_ALIQIPI",&("SC7->C7_IPI    "),nitem)
		MaFisLoad("IT_VALIPI",&("SC7->C7_VALIPI "),nitem)
		MaFisLoad("IT_BASEICM",&("SC7->C7_BASEICM"),nitem)
		MaFisLoad("IT_ALIQICM",&("SC7->C7_PICM   "),nitem)
		//MaFisLoad("IT_VALICM",&("SC7->C7_VALICM "),nitem)
		MaFisLoad("IT_VALCMP",&("SC7->C7_ICMCOMP"),nitem)
		MaFisLoad("IT_VALEMB",&("SC7->C7_VALEMB "),nitem)
		MaFisLoad("IT_TES",&("SC7->C7_TES    "),nitem)
		MaFisLoad("IT_SEGURO",&("SC7->C7_SEGURO "),nitem)
		MaFisLoad("IT_DESPESA",&("SC7->C7_DESPESA"),nitem)
		MaFisLoad("IT_FRETE",&("SC7->C7_VALFRE "),nitem)
		MaFisLoad("IT_BASEIRR",&("SC7->C7_BASEIR "),nitem)
		MaFisLoad("IT_ALIQIRR",&("SC7->C7_ALIQIR "),nitem)
		MaFisLoad("IT_BASESOL",&("SC7->C7_BASESOL"),nitem)
		MaFisLoad("IT_VALSOL",&("SC7->C7_ICMSRET"),nitem)
		MaFisLoad("IT_BASECSL",&("SC7->C7_BASECSL"),nitem)
		MaFisLoad("IT_ALIQCSL",&("SC7->C7_ALQCSL "),nitem)
		MaFisLoad("IT_VALCSL",&("SC7->C7_VALCSL "),nitem)
		MaFisLoad("IT_BASECF2",&("SC7->C7_BASIMP5"),nitem)
		MaFisLoad("IT_BASEPS2",&("SC7->C7_BASIMP6"),nitem)
		MaFisLoad("IT_VALCF2",&("SC7->C7_VALIMP5"),nitem)
		MaFisLoad("IT_BASEISS",&("SC7->C7_BASEISS"),nitem)
		MaFisLoad("IT_ALIQISS",&("SC7->C7_ALIQISS"),nitem)
		MaFisLoad("IT_BASEINS",&("SC7->C7_BASEINS"),nitem)
		MaFisLoad("IT_ALIQINS",&("SC7->C7_ALIQINS"),nitem)
		MaFisLoad("IT_VALPS2",&("SC7->C7_VALIMP6"),nitem)
		MaFisLoad("IT_VALISS",&("SC7->C7_VALISS "),nitem)
		MaFisLoad("IT_VALIRR",&("SC7->C7_VALIR  "),nitem)
		MaFisLoad("IT_VALINS",&("SC7->C7_VALINS "),nitem)
		MaFisLoad("IT_VALSOL",&("SC7->C7_VALSOL "),nitem)
	
		MaFisEndLoad(nItem,2)
		DBSelectArea('SC7')
		DBSkip()
	End
EndIf

FWRestArea(aAreaSC7)
FWRestArea(aArea)

Return .T.

/*
===============================================================================================================================
Programa----------: AtuNivel
Autor-------------: Darcio Ribeiro Sporl
Data da Criacao---: 18/01/2016
Descrição---------: Função criada para atualizar o Nível da tabela SCR
Parametros--------: ExpC1	- Filial
				  : ExpC2	- Pedido
				  : ExpC3	- Nível do Aprovador
				  : ExpC4	- Se foi aprovado ou bloqueado
Retorno-----------: _lRet	- .T. Atualiza a tabela SC7 / .F. Não Atualiza a tabela SC7
===============================================================================================================================
*/
Static Function AtuNivel(_cFilial,_cNumPC,_cNivelAP,_cAprova,_sDtLiber,_cHrLiber,_cNObs,_cBloq)
Local _lRet		:= .T.
Local _cQry		:= ""
Local _cGrpALeite:= AllTrim(SuperGetMV("IT_GRPALEI",.F.,""))

Default _cFilial	:= ""
Default _cNumPC		:= ""
Default _cNivelAP	:= ""

If _cAprova == "L"		//APROVADO ****************************

	_cQry := "SELECT CR_FILIAL,CR_NUM,CR_NIVEL,R_E_C_N_O_ CR_NREG "
	_cQry += "FROM " + RetSqlName("SCR") + " "
	_cQry += " WHERE D_E_L_E_T_ = ' '" 
	_cQry  += " AND	CR_FILIAL  			= '" + _cFilial + "' "
	_cQry  += " AND	CR_NUM		= '" + _cNumPC  + "' "
	_cQry  += " AND	CR_NIVEL			= '" + _cNivelAP  + "' "
	_cQry  += " AND CR_TIPO             = 'PC' "
	_cQry += " AND CR_STATUS IN ('03','04') "//APROVADO E BLOQUEADO
	_cQry += " ORDER BY CR_FILIAL,CR_NUM,CR_NIVEL "
	
	dbUseArea(.T., "TOPCONN", TcGenQry(,,_cQry), "TRBNEW", .T., .F.)
	
	DBSelectArea("TRBNEW")
	TRBNEW->(DBGoTop())
	
	If TRBNEW->(Eof()) //Não existe aprovação anterior do nivel permite gravar

		DBSelectArea("SCR")
		SCR->(DBSetOrder(1))//CR_FILIAL+CR_TIPO+CR_NUM+CR_NIVEL
		SCR->(DBSeek(_cFilial + "PC" + _cNumPC))
		_cNivelMaisAlto:=SCR->CR_NIVEL
		While !SCR->(Eof()) .And. SCR->CR_FILIAL == _cFilial .And. SCR->CR_TIPO == "PC" .And. SubStr(SCR->CR_NUM,1,6) == _cNumPC
		   FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00419"/*cMsgId*/,"MCOM00419 - AtuNivel(1) - SCR->CR_NIVEL = "+SCR->CR_NIVEL+" / SCR->CR_GRUPO = "+SCR->CR_GRUPO/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		   If AllTrim(SCR->CR_GRUPO) $ _cGrpALeite .AND.;
		      SAL->(DBSeek(xFilial("SAL")+SCR->CR_GRUPO+SCR->CR_NIVEL))
		      If SAL->AL_LIBAPR = "V"//VISTA
		         SCR->(DBSkip())
		   	     Loop
		      EndIf
		   EndIf
		   _cNivelMaisAlto:=SCR->CR_NIVEL
		   SCR->(DBSkip())
		EndDo
        FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00420"/*cMsgId*/,"MCOM00420 - AtuNivel(1.1) - _cNivelMaisAlto = "+_cNivelMaisAlto+" / _cGrpALeite = "+_cGrpALeite/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		SAL->(DBSetOrder(2))//AL_FILIAL+AL_COD+AL_NIVEL

		SCR->(DBSeek(_cFilial + "PC" + _cNumPC))
		While !SCR->(Eof()) .And. SCR->CR_FILIAL == _cFilial .And. SCR->CR_TIPO == "PC" .And. SubStr(SCR->CR_NUM,1,6) == _cNumPC
			If SCR->CR_NIVEL == _cNivelAP
				SCR->(RecLock("SCR",.F.))
				SCR->CR_STATUS  := "03"// APROVADO - "Nível Aprovado"
				SCR->CR_USERLIB := SCR->CR_USER
				SCR->CR_OBS     := _cNObs
				SCR->CR_LIBAPRO := SCR->CR_APROV
				SCR->CR_DATALIB := SToD(_sDtLiber)
				SCR->CR_I_HRAPR := _cHrLiber
				If _cNivelMaisAlto == SCR->CR_NIVEL//ULTIMO NIVEL ANTES DO VISTA
			       SCR->CR_VALLIB  := SCR->CR_TOTAL
			       SCR->CR_TIPOLIM := Posicione("SAK",1,xFilial("SAK")+SCR->CR_LIBAPRO,"AK_TIPO")
				EndIf
				SCR->(MSUnLock())
				If AllTrim(SCR->CR_GRUPO) $ _cGrpALeite .AND.;
				   SAL->(DBSeek(xFilial("SAL")+SCR->CR_GRUPO+SCR->CR_NIVEL))
				   If SAL->AL_LIBAPR = "V"//VISTA
				     _lVista:=.T.
				   EndIf
				EndIf
				FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00421"/*cMsgId*/,'MCOM00421 - AtuNivel(1.2) - SCR->CR_STATUS = ' + SCR->CR_STATUS+" / _cNivelAP = "+_cNivelAP+" / _lVista = "+If(_lVista,"SIM","NAO")+" / _cNivelMaisAlto = "+_cNivelMaisAlto+" / SCR->CR_NIVEL = "+SCR->CR_NIVEL/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
			EndIf
			SCR->(DBSkip())
		End
		SAL->(DBSetOrder(1))

		_cQry := "SELECT CR_FILIAL,CR_NUM,CR_NIVEL,R_E_C_N_O_ CR_NREG "
		_cQry += "FROM " + RetSqlName("SCR") + " "
		_cQry += "WHERE CR_FILIAL = '" + _cFilial + "' "
		_cQry += "  AND CR_NUM = '" + _cNumPC + "' "
		_cQry += "  AND CR_STATUS = '01' "//Pendente em níveis anteriores
		_cQry += "  AND CR_TIPO = 'PC' "
		_cQry += "  AND D_E_L_E_T_ = ' ' "
		_cQry += "ORDER BY CR_FILIAL,CR_NUM,CR_NIVEL "

		dbUseArea(.T., "TOPCONN", TcGenQry(,,_cQry), "TRBAP", .T., .F.)
		
		DBSelectArea("TRBAP")
		TRBAP->(DBGoTop())
		
		If !TRBAP->(Eof())
			While !TRBAP->(Eof())

				DBSelectArea("SCR")
				DBGoTo(TRBAP->CR_NREG)

				SCR->(RecLock("SCR",.F.))
				SCR->CR_STATUS := "02"//"Aguardando Aprovação"
				SCR->CR_EMISSAO:= SToD(_sDtLiber)
				SCR->(MSUnLock())
				_lRet :=   .F.
				SAL->(DBSetOrder(2))//AL_FILIAL+AL_COD+AL_NIVEL
				If AllTrim(SCR->CR_GRUPO) $ _cGrpALeite .AND.;
				   SAL->(DBSeek(xFilial("SAL")+SCR->CR_GRUPO+SCR->CR_NIVEL))
				   If SAL->AL_LIBAPR = "V"//VISTA
			         _cBloq := "APROVADO"
				     _lRet := .T.
				   EndIf
					FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00422"/*cMsgId*/,'MCOM00422 - AtuNivel(2) -  SCR->CR_STATUS = ' + SCR->CR_STATUS+" / SCR->CR_GRUPO+SCR->CR_NIVEL = "+SCR->CR_GRUPO+SCR->CR_NIVEL+" / SAL->AL_LIBAPR  = "+SAL->AL_LIBAPR /*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
				EndIf
				SAL->(DBSetOrder(1))
				FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00423"/*cMsgId*/,'MCOM00423 - AtuNivel(3) -   SCR->CR_STATUS = ' + SCR->CR_STATUS+" / SCR->CR_GRUPO+SCR->CR_NIVEL = "+SCR->CR_GRUPO+SCR->CR_NIVEL+" / _cBloq  = "+_cBloq  /*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
				Exit//SÓ COLOCA O PROXIMO PARA APROVAR
				TRBAP->(DBSkip())
			End
		Else
			_cBloq := "APROVADO"
			_lRet := .T.
		EndIf
    Else
		_lRet := .F.    		
	EndIf
ElseIf _cAprova == "B"		//BLOQUEADO ************************

	DBSelectArea("SCR")
	DBSetOrder(1)
	DBSeek(_cFilial + "PC" + _cNumPC)
	
	While !SCR->(Eof()) .And. SCR->CR_FILIAL == _cFilial .And. SCR->CR_TIPO == "PC" .And. SubStr(SCR->CR_NUM,1,6) == _cNumPC
		If SCR->CR_NIVEL == _cNivelAP
			RecLock("SCR",.F.)
			SCR->CR_STATUS  := "04" // "PC Bloqueado"
			SCR->CR_USERLIB := SCR->CR_USER
			SCR->CR_OBS     := _cNObs
			SCR->CR_LIBAPRO := SCR->CR_APROV
			SCR->CR_DATALIB := SToD(_sDtLiber)
			SCR->CR_I_HRAPR := _cHrLiber
			MSUnLock()
			SAL->(DBSetOrder(2))//AL_FILIAL+AL_COD+AL_NIVEL
			If AllTrim(SCR->CR_GRUPO) $ _cGrpALeite .AND.;
			   SAL->(DBSeek(xFilial("SAL")+SCR->CR_GRUPO+SCR->CR_NIVEL))
			   If SAL->AL_LIBAPR = "V"//VISTA
			     _lVista:=.T.
			   EndIf
			EndIf
			SAL->(DBSetOrder(1))
			FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00424"/*cMsgId*/,'MCOM00424 - AtuNivel(4) -  SCR->CR_STATUS = ' + SCR->CR_STATUS+" / SCR->CR_GRUPO+SCR->CR_NIVEL = "+SCR->CR_GRUPO+SCR->CR_NIVEL+" / _lVista = "+If(_lVista,"SIM","NAO")+" / _cBloq = "+_cBloq /*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		EndIf
		SCR->(DBSkip())
	EndDo
 
	_cBloq := "BLOQUEADO"

	_lRet := .F.      
EndIf

Return(_lRet)


/*
===============================================================================================================================
Programa----------: MCOM004B
Autor-------------: Jerry
Data da Criacao---: 31/03/2016
Descrição---------: Função criada para validar se o PC tem histórico de Aprovação/Rejeição
Parametros--------: ExpC1	- Filial
				  : ExpC2	- Pedido
Retorno-----------: _lRet	- .T. Tem Histórico  / .F. Não Tem Histórico
===============================================================================================================================
*/
Static Function MCOM004B(_cFilial,_cNumPC,_cNivel)
Local _lRet	:= .F.
Local _cQry	:= ""

Default _cFilial	:= ""
Default _cNumPC		:= ""

_cQry := "SELECT COUNT(*) SCYCONT "
_cQry += "FROM " + RetSqlName("SCY") + " "
_cQry += "WHERE CY_FILIAL = '" + _cFilial + "' "
_cQry += "  AND CY_NUM  = '" + _cNumPC + "' "
_cQry += "  AND CY_I_QTAPR  = '" + _cNivel + "' "
_cQry += "  AND CY_I_WFID <> ' ' "
_cQry += "  AND D_E_L_E_T_ = ' ' "
	
dbUseArea(.T., "TOPCONN", TcGenQry(,,_cQry), "TRBSCY", .T., .F.)
	
DBSelectArea("TRBSCY")
TRBSCY->(DBGoTop())
If !TRBSCY->(Eof()) .And. TRBSCY->SCYCONT > 0
	_lRet := .T.	
EndIf
FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00425"/*cMsgId*/,"MCOM00425 - ** _lRet = "+If(_lRet,".T.**",".F. **")+" / _cQry = "+_cQry /*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

TRBSCY->(DBCloseArea())

Return(_lRet)

/*
===============================================================================================================================
Programa----------: MCOM004A
Autor-------------: Darcio Ribeiro Sporl
Data da Criacao---: 29/01/2016
Descrição---------: Função criada aviso ao Comprador/Solicitante para enviar e-mail de Aprovacao ou Rejeição
Parametros--------: _cFilial	- Filial do Pedido de Compras
				  : _cNumPC		- Número do Pedido de Compras
				  : cBloq		- Controla se o pedido foi bloqueado ou não
				  : _cOrigem	- Indica de onde gerou
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MCOM004A(_cFilial,_cNumPc,cBloq,_cOrigem)
Local _sArqHTM	  := "\Workflow\htm\pc_comprador.htm" 
Local _cHostWF 	  := SuperGetMV("IT_WFHOSTS",.F.,"http://wfteste.italac.com.br:4034/")
Local cLogo		  := _cHostWF + "htm/logo_novo.jpg"
Local cLogo1	  := _cHostWF + "htm/logo_novo.jpg"
Local cFiltro	  := ""
Local nLinhas	  := 0
Local cNomSol	  := ""
Local cNomApr	  := ""
Local cNomFor	  := ""
Local cCgcFor	  := ""
Local _cAssunto   := "" 
Local _cEmail     := ""
Local _cFilAntJob := cFilAnt  
Local _lEmaLeite  := .F.
Local _cQuery     := ""
Local _cEmailGrpLeite := ""
Local _cAliasSBZ	:= ""
Local _cAliasSBF	:= "" 
Local _cAliasSBE	:= ""
Local cObsSc 		:= "" 
Local _cGrpLeite    := ""
Private _lGrpLeite  := .F.//PARA TESTAR AS DECIMAIS na função MCOM004Totais() e "cTitulo"

cFilAnt   := _cFilial 
_cGrpLeite:= AllTrim(SuperGetMV("IT_GRPLEIT",.F.,""))
_cEmail	  := AllTrim(SuperGetMV("IT_MAILWFC",.F.,""))
If !Empty(_cEmail)
  _cEmail+=";"
EndIf
FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00426"/*cMsgId*/,"MCOM00426 - 06-IT_GRPLEITE =" +_cGrpLeite + ' /  _lGrpLeite =' + If(_lGrpLeite,".T.",".F.")+" / cFilant = "+cFilant /*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

MaFisEnd()
M004FIniPC(_cNumPC,,,cFiltro,SubStr(_cFilial,1,2))

nTotal		:= 0
nTotIcms    := 0
nTotMerc	:= 0
nTotDesc	:= 0
nC7_L_EXEMG := 0
		
DBSelectArea("SM0")
DBSetOrder(1)
DBSeek(cEmpAnt + SubStr(_cFilial,1,2))
		
cNomFil	:= _cFilial + " - " + AllTrim(SM0->M0_FILIAL)
cEndFil	:= AllTrim(SM0->M0_ENDCOB)
cCepFil	:= SubStr(AllTrim(SM0->M0_CEPCOB),1,2) + "." + SubStr(AllTrim(SM0->M0_CEPCOB),3,3) + "-" + SubStr(AllTrim(SM0->M0_CEPCOB),6,3)
cCidFil	:= SubStr(AllTrim(SM0->M0_CIDCOB),1,50)
cEstFil	:= AllTrim(SM0->M0_ESTCOB)
cTelFil	:= '(' + SubStr(SM0->M0_TEL,4,2) + ')' + SubStr(SM0->M0_TEL,7,4) + '-' +SubStr(SM0->M0_TEL,11,4)
cFaxFil	:= '(' + SubStr(SM0->M0_FAX,4,2) + ')' + SubStr(SM0->M0_FAX,7,4) + '-' +SubStr(SM0->M0_FAX,11,4)
cCGCFil	:= formCPFCNPJ(SM0->M0_CGC)
cIEFil	:= AllTrim(SM0->M0_INSC)
		
nContrl	:= 0

If Type("_cAliasSC7") == "C" .And. select(_cAliasSC7) > 0

	(_cAliasSC7)->(DBCloseArea())
	
EndIf


_cAliasSC7 := GetNextAlias()
If _cOrigem = "REENVIO"
     BeginSql alias _cAliasSC7  
     	SELECT	SC7.R_E_C_N_O_ AS REG_SC7 ,C7_FILIAL, C7_NUM, C7_ITEM, C7_PRODUTO, C7_EMISSAO, C7_QUANT, C7_UM, C7_PRECO, C7_TOTAL, C7_FORNECE, C7_LOJA, C7_QTDREEM, C7_VLDESC, C7_DATPRF, C7_I_URGEN, C7_I_CMPDI, C7_I_NFORN, 
     	C7_DESCRI, C7_I_DESCD, C7_COND, C7_I_GCOM, C7_USER, C7_GRUPCOM, C7_NUMSC, C7_ITEMSC, C7_I_APLIC, C7_I_CDINV, C7_I_CMPDI, C7_VALIPI, C7_ICMSRET, C7_VALICM, C7_CC, C7_FRETE, C7_TPFRETE, C7_OBS, C7_FRETCON, C7_PICM,
     	C7_I_CDTRA, C7_I_LJTRA, C7_I_TPFRT, C7_CONTATO, A2_COD, A2_LOJA, A2_NOME, A2_END, A2_MUN, A2_EST, A2_CEP, A2_DDD, A2_TEL, A2_FAX, A2_CGC, A2_INSCR, A2_CONTATO, C7_I_QTAPR, C7_MOEDA, C7_TXMOEDA, C7_I_CLAIM, C7_CONAPRO, C7_L_EXEMG 
     	FROM %Table:SC7% SC7
		JOIN %Table:SA2% SA2 ON A2_FILIAL = %xFilial:SA2% AND A2_COD = C7_FORNECE AND A2_LOJA = C7_LOJA AND SA2.%notDel%
     	WHERE C7_FILIAL = %Exp:_cFilial%
     	  AND C7_NUM = %Exp:_cNumPC%
     	  AND SC7.%notDel%        
     	ORDER BY C7_FILIAL, C7_NUM, C7_ITEM
     EndSql
Else
   MCOM004Q(3,_cAliasSC7,SubStr(_cFilial,1,2),AllTrim(_cNumPc),"","","","","","","","")
EndIf

lWFHTML	:= GetMv("MV_WFHTML")
PutMV("MV_WFHTML",.T.)

DBSelectArea(_cAliasSC7)
(_cAliasSC7)->(DBGoTop())
_cMemEnv:="Não foi possivel enviar o e-mail"		
If !(_cAliasSC7)->(Eof())
	// Inicialize a classe TWFProcess e assinale a variável objeto oProcess:
	_oProcess := TWFProcess():New("SendMail", "Envio de email no retorno" )
	_oProcess:NewTask("SendMail", _sArqHTM)

	//=======================================
	//Validade se o PC é do Grupo de Leite
	//======================================= 
	_lGrpLeite:= If((_cAliasSC7)->C7_GRUPCOM $ _cGrpLeite,.T.,.F.)//PARA TESTAR AS DECIMAIS na função MCOM004Totais() e "cTitulo"
	_lEmaLeite:= If((_cAliasSC7)->C7_CONAPRO =  "L"  ,.T.,.F.)
    
	FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00427"/*cMsgId*/,"MCOM00427 - 08-IT_GRPLEITE =" +_cGrpLeite + ' /  _lGrpLeite =' + If(_lGrpLeite,".T.",".F.")+" / cFilant = "+cFilant+" / (_cAliasSC7)->C7_GRUPCOM = "+(_cAliasSC7)->C7_GRUPCOM /*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	
	If _lGrpLeite .And. _lEmaLeite

       cFilAnt:= _cFilial 
	   _cEmail:=AllTrim(SuperGetMV("IT_MAILGRP",.F.,""))+";"
       cFilAnt:= _cFilAntJob  

	EndIf
    _cObs:=""
	_cPObsProdAlter:="Saldo Produtos Alternativos:"+ENTERBR
    nContaItem:=0
	While !(_cAliasSC7)->(Eof())
		nContrl++
		If nContrl == 1	
			
			//=======================================
			//Dados do cabeçalho do pedido de compras
			//======================================= 
			_oProcess:oHtml:ValByName("cLogo"			, cLogo )
			_oProcess:oHtml:ValByName("cNomFil"			, cNomFil)
			_oProcess:oHtml:ValByName("cEndFil"			, cEndFil)
			_oProcess:oHtml:ValByName("cCepFil"			, cCepFil)
			_oProcess:oHtml:ValByName("cCidFil"			, cCidFil)
			_oProcess:oHtml:ValByName("cEstFil"			, cEstFil)
			_oProcess:oHtml:ValByName("cTelFil"			, cTelFil)
			_oProcess:oHtml:ValByName("cFaxFil"			, cFaxFil)
			_oProcess:oHtml:ValByName("cCGCFil"			, cCGCFil)
			_oProcess:oHtml:ValByName("cIEFil"			, cIEFil)
					
			_oProcess:oHtml:ValByName("NumPC"			, _cNumPC)

			If !Empty((_cAliasSC7)->C7_I_GCOM)
				cNomGes := MCOM004FullNome((_cAliasSC7)->C7_I_GCOM,.T.)
				_oProcess:oHtml:ValByName("cNomGes", cNomGes )
			Else
				_oProcess:oHtml:ValByName("cNomGes"  		, "")
			EndIf
            _cMailAux:=AllTrim(UsrRetMail((_cAliasSC7)->C7_USER))
			If !Empty(_cMailAux) .And. !Upper(_cMailAux) $ Upper(_cEmail)
				_cEmail += _cMailAux+ ";"
			EndIf
            _cMailAux:=AllTrim(UsrRetMail((_cAliasSC7)->C7_I_GCOM))
            If !Empty(_cMailAux)  .And. !Upper(_cMailAux) $ Upper(_cEmail)
			   _cEmail += _cMailAux+ ";"
		    EndIf   

			cQry := "SELECT C1_I_CDSOL, C1_I_CODAP, C1_NUM, C1_EMISSAO, C1_I_DTAPR, C1_I_OBSAP, C1_I_OBSAP, C1_I_OBSSC"
			cQry += " FROM " + RetSqlName("SC1") + " "
			cQry += " WHERE C1_FILIAL = '" + (_cAliasSC7)->C7_FILIAL + "' "
			cQry += "  AND C1_NUM = '"    + (_cAliasSC7)->C7_NUMSC + "' "
			cQry += "  AND C1_ITEM = '"   + (_cAliasSC7)->C7_ITEMSC + "' "
			cQry += "  AND D_E_L_E_T_ = ' ' "

			dbUseArea( .T. , "TOPCONN" , TcGenQry(,, cQry ) , "TRBSC1" , .T., .F. )
					
			DBSelectArea("TRBSC1")
			TRBSC1->(DBGoTop())
					
			If AllTrim(TRBSC1->C1_I_OBSAP) == "EXECUTADO VIA WORKFLOW" .AND.;
			   AllTrim(TRBSC1->C1_I_OBSAP) == "SC Aprovada via acesso ao Protheus"
				cObsSc := ""
			Else
				cObsSc := TRBSC1->C1_I_OBSAP
			EndIf
			cObsScGen:=TRBSC1->C1_I_OBSSC

			If !TRBSC1->(Eof())

				If Empty(AllTrim(TRBSC1->C1_I_CDSOL))
					_oProcess:oHtml:ValByName("cNomSol"			, "")
					cNomSol := ""           
				Else
					_oProcess:oHtml:ValByName("cNomSol",AllTrim(Posicione("ZZ7",1,SubStr(_cFilial,1,2) + TRBSC1->C1_I_CDSOL, "ZZ7_NOME")))
					cNomSol := AllTrim(Posicione("ZZ7",1,SubStr(_cFilial,1,2) + TRBSC1->C1_I_CDSOL, "ZZ7_NOME"))  
					_cMailAux:=AllTrim(UsrRetMail(TRBSC1->C1_I_CDSOL))
					If !Empty(_cMailAux) .And. !Upper(_cMailAux) $ Upper(_cEmail)
					   _cEmail += _cMailAux + ";"
					EndIf
				EndIf
						
				If Empty(TRBSC1->C1_I_CODAP)
					_oProcess:oHtml:ValByName("cNomApr","")
					cNomApr := ""
				Else
					_oProcess:oHtml:ValByName("cNomApr", AllTrim(Posicione("ZZ7",1,SubStr(_cFilial,1,2) + TRBSC1->C1_I_CODAP, "ZZ7_NOME")))
					cNomApr := AllTrim(Posicione("ZZ7",1,SubStr(_cFilial,1,2) + TRBSC1->C1_I_CODAP, "ZZ7_NOME"))
					_cMailAux:=AllTrim(UsrRetMail(TRBSC1->C1_I_CODAP))
                    If !Empty(_cMailAux) .And. !Upper(_cMailAux) $ Upper(_cEmail)
                       _cEmail += _cMailAux + ";"
					EndIf
				EndIf
				
				_oProcess:oHtml:ValByName("cnumSC",AllTrim(TRBSC1->C1_NUM))
				_oProcess:oHtml:ValByName("cdtinc",AllTrim(DToC(SToD(TRBSC1->C1_EMISSAO))))
				_oProcess:oHtml:ValByName("cdtapr",AllTrim(DToC(SToD(TRBSC1->C1_I_DTAPR))))
	
				
			Else
				_oProcess:oHtml:ValByName("cNomSol"			, "")
				_oProcess:oHtml:ValByName("cNomApr"			, "") 
				cNomSol := ""        
				cNomApr := ""
			EndIf

			DBSelectArea("TRBSC1")
			TRBSC1->(DBCloseArea())

			_oProcess:oHtml:ValByName("cDigiFor"		, MCOM004FullNome((_cAliasSC7)->C7_USER,.T.) )

			If (_cAliasSC7)->C7_I_APLIC == "C"
				cAplic := "Consumo"
			ElseIf (_cAliasSC7)->C7_I_APLIC == "I"
				cAplic := "Investimento - " + Posicione("ZZI",1,SubStr(_cFilial,1,2) + (_cAliasSC7)->C7_I_CDINV, "ZZI_DESINV")
			ElseIf (_cAliasSC7)->C7_I_APLIC == "M"
				cAplic := "Manutenção"
			ElseIf (_cAliasSC7)->C7_I_APLIC == "S"
				cAplic := "Serviço"
			EndIf
					
			_oProcess:oHtml:ValByName("cAplic" 		  	, cAplic)

			If (_cAliasSC7)->C7_I_URGEN == "S"
				cUrgen	:= "Sim"                  
			ElseIf (_cAliasSC7)->C7_I_URGEN == "F"
				cUrgen	:= "NF"
			Else
				cUrgen	:= "Não"
			EndIf

			_oProcess:oHtml:ValByName("cUrgen" 		, cUrgen)

			If (_cAliasSC7)->C7_I_CMPDI == "S"
				cCmpdi	:= "Sim"
			Else
				cCmpdi	:= "Não"
			EndIf

			If (_cAliasSC7)->C7_TPFRETE == "C"
				_oProcess:oHtml:ValByName("cFrete"	, "CIF")
				cTpFrete := "CIF"
			ElseIf (_cAliasSC7)->C7_TPFRETE == "F"
				_oProcess:oHtml:ValByName("cFrete"	, "FOB")
				cTpFrete := "FOB"
			ElseIf (_cAliasSC7)->C7_TPFRETE == "T"
				_oProcess:oHtml:ValByName("cFrete"	, "TERCEIROS")
				cTpFrete := "TERCEIROS"
			ElseIf (_cAliasSC7)->C7_TPFRETE == "S"
				_oProcess:oHtml:ValByName("cFrete"	, "SEM FRETE")
				cTpFrete := "SEM FRETE"
			EndIf

			_oProcess:oHtml:ValByName("cCompDir"  		, cCmpdi)

			_oProcess:oHtml:ValByName("dDtEmiss"  		, DToC(SToD((_cAliasSC7)->C7_EMISSAO)))
			cEmissao := DToC(SToD((_cAliasSC7)->C7_EMISSAO))

			If  !Empty(AllTrim((_cAliasSC7)->C7_CC))
				cCcusto	:= (_cAliasSC7)->C7_CC + " - " + AllTrim(Posicione("CTT",1,xFilial("CTT") + AllTrim((_cAliasSC7)->C7_CC), "CTT_DESC01"))
			Else
			    cCcusto := ""
			EndIf

			cNomFor	:= AllTrim((_cAliasSC7)->A2_NOME)
			cCgcFor	:= formCPFCNPJ((_cAliasSC7)->A2_CGC)

			_oProcess:oHtml:ValByName("cNomFor"			, AllTrim((_cAliasSC7)->A2_NOME) + " - " + (_cAliasSC7)->C7_FORNECE + "/" + (_cAliasSC7)->C7_LOJA)
			_oProcess:oHtml:ValByName("cEndFor"			, AllTrim((_cAliasSC7)->A2_END))
			_oProcess:oHtml:ValByName("cCEPFor"			, (_cAliasSC7)->A2_CEP)
			_oProcess:oHtml:ValByName("cCidFor"			, AllTrim((_cAliasSC7)->A2_MUN))
			_oProcess:oHtml:ValByName("cEstFor"			, (_cAliasSC7)->A2_EST)
			_oProcess:oHtml:ValByName("cTelFor"			, "(" + (_cAliasSC7)->A2_DDD + ") " + (_cAliasSC7)->A2_TEL)
			_oProcess:oHtml:ValByName("cFaxFor"			, "(" + (_cAliasSC7)->A2_DDD + ") " + (_cAliasSC7)->A2_FAX)
			_oProcess:oHtml:ValByName("cCGCFor"			, formCPFCNPJ((_cAliasSC7)->A2_CGC))
			_oProcess:oHtml:ValByName("cIEFor"	 		, (_cAliasSC7)->A2_INSCR)
			_oProcess:oHtml:ValByName("cContatFor"		, AllTrim((_cAliasSC7)->C7_CONTATO))
			_oProcess:oHtml:ValByName("cCondPG"	  		, AllTrim(Posicione("SE4",1,xFilial("SE4") + AllTrim((_cAliasSC7)->C7_COND),"E4_DESCRI")))

			cTransp := ""

			If !Empty((_cAliasSC7)->C7_I_CDTRA) .And. !Empty((_cAliasSC7)->C7_I_LJTRA)
				cTransp := "&nbsp;"
				cTransp += "Código: " + (_cAliasSC7)->C7_I_CDTRA + "&nbsp;Loja: " + (_cAliasSC7)->C7_I_LJTRA + "<br>"
				cTransp += "Razão Social: " + AllTrim(SubStr(Posicione("SA2", 1, xFilial("SA2")+(_cAliasSC7)->C7_I_CDTRA+(_cAliasSC7)->C7_I_LJTRA,"A2_NOME"),1,30)) + "<br>"
				cTransp += "Nome Fantasia: " + AllTrim(SubStr(Posicione("SA2", 1, xFilial("SA2")+(_cAliasSC7)->C7_I_CDTRA+(_cAliasSC7)->C7_I_LJTRA, "A2_NREDUZ"),1,30)) + "<br>"
				cTransp += "CNPJ: " + Transform(Posicione("SA2", 1, xFilial("SA2")+(_cAliasSC7)->C7_I_CDTRA+(_cAliasSC7)->C7_I_LJTRA, "A2_CGC"), PesqPict("SA2","A2_CGC")) + "&nbsp;&nbsp;&nbsp;"
				cTransp += "Ins. Estad.: " + Posicione("SA2", 1, xFilial("SA2")+(_cAliasSC7)->C7_I_CDTRA+(_cAliasSC7)->C7_I_LJTRA, "A2_INSCR") + "<br>"
				cTransp += "Bairro: " + AllTrim(SubStr(Posicione("SA2", 1, xFilial("SA2")+(_cAliasSC7)->C7_I_CDTRA+(_cAliasSC7)->C7_I_LJTRA, "A2_BAIRRO"),1,25)) + "<br>"
				cTransp += "Cidade: " + SubStr(Posicione("SA2", 1, xFilial("SA2")+(_cAliasSC7)->C7_I_CDTRA+(_cAliasSC7)->C7_I_LJTRA, "A2_MUN"),1,30) + "&nbsp;&nbsp;&nbsp;"
				cTransp += "Estado: " + Posicione("SA2", 1, xFilial("SA2")+(_cAliasSC7)->C7_I_CDTRA+(_cAliasSC7)->C7_I_LJTRA, "A2_EST") + "<br>"
				cTransp += "Telefone: (" + AllTrim(Posicione("SA2", 1, xFilial("SA2")+(_cAliasSC7)->C7_I_CDTRA+(_cAliasSC7)->C7_I_LJTRA, "A2_DDD")) + ")" + Posicione("SA2", 1, xFilial("SA2")+(_cAliasSC7)->C7_I_CDTRA+(_cAliasSC7)->C7_I_LJTRA, "A2_TEL") + "<br>"
				cTransp += "Contato: " + AllTrim(Posicione("SA2", 1, xFilial("SA2")+(_cAliasSC7)->C7_I_CDTRA+(_cAliasSC7)->C7_I_LJTRA, "A2_CONTATO")) + "<br>"
				cTransp += "<B> Obs. Frete: " + If((_cAliasSC7)->C7_I_TPFRT == "1","Entregar na Transportadora","Solicitar Coleta pela Transportadora" ) +"/B>
			EndIf
					
			_oProcess:oHtml:ValByName("cTransp"	  		, cTransp)
					
		EndIf
				
		aAdd( _oProcess:oHtml:ValByName("Itens.Item" 			), (_cAliasSC7)->C7_ITEM 												)
		aAdd( _oProcess:oHtml:ValByName("Itens.Prodpc" 			), (_cAliasSC7)->C7_PRODUTO								 				)
		If AllTrim((_cAliasSC7)->C7_I_DESCD) $ (_cAliasSC7)->C7_DESCRI
			aAdd( _oProcess:oHtml:ValByName("Itens.DesProd"		), AllTrim((_cAliasSC7)->C7_DESCRI)														)
		Else
			aAdd( _oProcess:oHtml:ValByName("Itens.DesProd"		), AllTrim((_cAliasSC7)->C7_DESCRI) + " " + AllTrim((_cAliasSC7)->C7_I_DESCD)			)
		EndIf
		aAdd( _oProcess:oHtml:ValByName("Itens.UM"				), (_cAliasSC7)->C7_UM													)
		aAdd( _oProcess:oHtml:ValByName("Itens.qtde"			), Transform((_cAliasSC7)->C7_QUANT , PesqPict("SC7","C7_QUANT"))		)

        _cValor:=MCOM004Totais((_cAliasSC7)->C7_MOEDA,0,(_cAliasSC7)->C7_PRECO,.F.)
		aAdd( _oProcess:oHtml:ValByName("Itens.VlrUni"			), _cValor)//Transform((_cAliasSC7)->C7_PRECO, "@E 999,999,999.999") 	      )

        _cValor:=MCOM004Totais((_cAliasSC7)->C7_MOEDA,0,(_cAliasSC7)->C7_VLDESC,.F.)
		aAdd( _oProcess:oHtml:ValByName("Itens.VlrDes"		   	), _cValor)//Transform((_cAliasSC7)->C7_VLDESC, PesqPict("SC7","C7_VLDESC"))  )

        _cValor:=MCOM004Totais((_cAliasSC7)->C7_MOEDA,0,((_cAliasSC7)->C7_TOTAL-(_cAliasSC7)->C7_VLDESC),.F.)
		aAdd( _oProcess:oHtml:ValByName("Itens.VlrTot"			), _cValor)//Transform((_cAliasSC7)->C7_TOTAL, PesqPict("SC7","C7_TOTAL")) 	  )

        _cValor:=MCOM004Totais(1,0,(_cAliasSC7)->C7_PICM,.F.,.T.)
		aAdd( _oProcess:oHtml:ValByName("Itens.ICMS"			), _cValor)

		aAdd( _oProcess:oHtml:ValByName("Itens.DtEmis"			), DToC(SToD((_cAliasSC7)->C7_DATPRF))									)

  		If !Empty(_cAliasSBZ) .And. select(_cAliasSBZ) > 0
  			(_cAliasSBZ)->(DBCloseArea())
  		EndIf
				
		_cAliasSBZ := GetNextAlias()
		MCOM004Q(6,_cAliasSBZ,(_cAliasSC7)->C7_FILIAL,"","","","","","","","",(_cAliasSC7)->C7_PRODUTO)
		nUlPrc := 0
      dDtUlPrc := CTOD("")
		If !(_cAliasSBZ)->(Eof())
		   If (_cAliasSC7)->C7_MOEDA = 1
		      nUlPrc  :=(_cAliasSBZ)->BZ_UPRC
            dDtUlPrc:=SToD((_cAliasSBZ)->BZ_UCOM)
		   ElseIf !Empty((_cAliasSBZ)->BZ_UCOM)
		      dDtUlPrc:=SToD((_cAliasSBZ)->BZ_UCOM)
		      nTxMoeda:=RecMoeda(dDtUlPrc,(_cAliasSC7)->C7_MOEDA)
		      nUlPrc  :=((_cAliasSBZ)->BZ_UPRC/nTxMoeda)
		   EndIf   
		EndIf
        _cValor:=MCOM004Totais((_cAliasSC7)->C7_MOEDA,0,nUlPrc,.F.)
		aAdd( _oProcess:oHtml:ValByName("Itens.VlrUc"),_cValor)
      aAdd( _oProcess:oHtml:ValByName("Itens.DtUc"),DToC(dDtUlPrc))

		If !Empty(_cAliasSBF) .And. select(_cAliasSBF) > 0
			(_cAliasSBF)->(DBCloseArea())
		EndIf
		_cProdAlt:=Posicione("SGI",1,(_cAliasSC7)->C7_FILIAL+(_cAliasSC7)->C7_PRODUTO,"GI_PRODALT")
		If !Empty(_cProdAlt)
		   _cAliasSBF := GetNextAlias()
		   MCOM004Q(7,_cAliasSBF,(_cAliasSC7)->C7_FILIAL,"","","","","","","","",_cProdAlt)
		   _cPObsProdAlter+="<b>"+AllTrim(_cProdAlt)+'-'+AllTrim(Posicione("SB1",1,xFilial("SB1")+_cProdAlt,"B1_DESC"))+;
		                    " = "+AllTrim(Transform((_cAliasSBF)->B2_QATU, PesqPict("SB2","B2_QATU")))+"</b>"+ENTERBR
		EndIf

  		If !Empty(_cAliasSBF) .And. select(_cAliasSBF) > 0
  			(_cAliasSBF)->(DBCloseArea())
  		EndIf
				
		_cAliasSBF := GetNextAlias()
		MCOM004Q(7,_cAliasSBF,(_cAliasSC7)->C7_FILIAL,"","","","","","","","",(_cAliasSC7)->C7_PRODUTO)
		If !(_cAliasSBF)->(Eof())
			aAdd( _oProcess:oHtml:ValByName("Itens.SldAtFil"		), Transform((_cAliasSBF)->B2_QATU, PesqPict("SB2","B2_QATU"))		)
		Else
			aAdd( _oProcess:oHtml:ValByName("Itens.SldAtFil"		), Transform(0, PesqPict("SB2","B2_QATU"))		)
		EndIf
		
		
  		If !Empty(_cAliasSBE) .And. select(_cAliasSBE) > 0
  			(_cAliasSBE)->(DBCloseArea())
  		EndIf
			
		_cAliasSBE := GetNextAlias()
		MCOM004Q(8,_cAliasSBE,(_cAliasSC7)->C7_FILIAL,"","","","","","","","",(_cAliasSC7)->C7_PRODUTO)
		If !(_cAliasSBE)->(Eof())
			aAdd( _oProcess:oHtml:ValByName("Itens.SldAtEmp"		), Transform((_cAliasSBE)->B2_QATU, PesqPict("SB2","B2_QATU"))		)
		Else
			aAdd( _oProcess:oHtml:ValByName("Itens.SldAtEmp"		), Transform(0, PesqPict("SB2","B2_QATU"))		)
		EndIf
        
		//nContaItem++
		nTotDesc	+= (_cAliasSC7)->C7_VLDESC
        nC7_L_EXEMG += (_cAliasSC7)->C7_L_EXEMG 
		nTotal		+= (_cAliasSC7)->C7_TOTAL
		nTotIcms    += (_cAliasSC7)->C7_VALICM//MaFisRet(nContaItem,"IT_VALICM")

        If !Empty((_cAliasSC7)->C7_OBS) .And. !Upper(AllTrim((_cAliasSC7)->C7_OBS)) $ Upper(_cObs)
           _cObs+=AllTrim((_cAliasSC7)->C7_OBS)+" // "
        EndIf

		(_cAliasSC7)->(DBSkip())

	End

    (_cAliasSC7)->(DBGoTop())
	nTotMerc	:= MaFisRet(,'NF_TOTAL')
	nTotIpi		:= MaFisRet(,'NF_VALIPI')
	nTotDesp	:= MaFisRet(,'NF_DESPESA')
	_nTotImp    := nTotal+nTotIpi
    _nOutImp    := MaFisRet(,'NF_VALISS')+MaFisRet(,'NF_VALIRR')+MaFisRet(,'NF_VALINS')+MaFisRet(,'NF_VALSOL')
	
	If(_cAliasSC7)->C7_TPFRETE = "F"
	   nTotFrete:=(_cAliasSC7)->C7_FRETCON
	Else
	   nTotFrete:= MaFisRet(,'NF_FRETE')
	EndIf
	nTotSeguro	:= MaFisRet(,'NF_SEGURO')


    _cObs:=LEFT( _cObs, Len(_cObs)-4)
    If (_cAliasSC7)->C7_MOEDA <> 1
       _cObs:=MCOM004Moeda((_cAliasSC7)->C7_MOEDA,(_cAliasSC7)->C7_TXMOEDA,_cObs,(_cAliasSC7)->C7_EMISSAO)
    EndIf

	If "</b>" $ _cPObsProdAlter
	   If !Empty(_cObs) 
	      _cObs:="<b>"+_cObs+"</b>"
	      _cPObsProdAlter:=_cObs+ENTERBR+_cPObsProdAlter
	   EndIf
	Else
	   If !Empty(_cObs) 
	      _cObs:="<b>"+_cObs+"</b>"
	      _cPObsProdAlter:=_cObs
	   EndIf
	EndIf

    _oProcess:oHtml:ValByName("cObs", _cPObsProdAlter)//FORA While

    _cTotais:=MCOM004Totais((_cAliasSC7)->C7_MOEDA,(_cAliasSC7)->C7_TXMOEDA,nTotal,.F.)
	_oProcess:oHtml:ValByName("nTotMer"	, _cTotais	)

    _cTotais:=MCOM004Totais((_cAliasSC7)->C7_MOEDA,(_cAliasSC7)->C7_TXMOEDA,_nTotImp,.F.)
	_oProcess:oHtml:ValByName("nTotImp"	, _cTotais	)

    _cTotais:=MCOM004Totais((_cAliasSC7)->C7_MOEDA,(_cAliasSC7)->C7_TXMOEDA,nTotDesc,.F.)
	_oProcess:oHtml:ValByName("nTotDesc"	, _cTotais	)

    _cTotais:=MCOM004Totais((_cAliasSC7)->C7_MOEDA,(_cAliasSC7)->C7_TXMOEDA,nTotIpi,.F.)
	_oProcess:oHtml:ValByName("nIPI"	, _cTotais	)

    _cTotais:=MCOM004Totais((_cAliasSC7)->C7_MOEDA,(_cAliasSC7)->C7_TXMOEDA,nTotIcms,.F.)
	_oProcess:oHtml:ValByName("nICMS"	, _cTotais	)

    _cTotais:=MCOM004Totais((_cAliasSC7)->C7_MOEDA,(_cAliasSC7)->C7_TXMOEDA,_nOutImp,.F.)
	_oProcess:oHtml:ValByName("nOutImp"	, _cTotais	)

    _cTotais:=MCOM004Totais((_cAliasSC7)->C7_MOEDA,(_cAliasSC7)->C7_TXMOEDA,nTotDesp,.F.)
	_oProcess:oHtml:ValByName("nDesp"	, _cTotais)

    _cTotais:=MCOM004Totais((_cAliasSC7)->C7_MOEDA,(_cAliasSC7)->C7_TXMOEDA,nTotFrete,.F.)
	_oProcess:oHtml:ValByName("nVlFrete", _cTotais	)

	FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00428"/*cMsgId*/,"MCOM00428 - 09-IT_GRPLEITE =" +_cGrpLeite + ' /  _lGrpLeite =' + If(_lGrpLeite,".T.",".F.")+" / cFilant = "+cFilant+" / (_cAliasSC7)->C7_GRUPCOM = "+(_cAliasSC7)->C7_GRUPCOM /*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

    If _lGrpLeite
	   _cTotais:=MCOM004Totais(1,0,nC7_L_EXEMG,(_cAliasSC7)->C7_TXMOEDA <> 1)
	   _oProcess:oHtml:ValByName("cGord","Vlr.Pag.MG")
	Else
       _cTotais:=MCOM004Totais((_cAliasSC7)->C7_MOEDA,(_cAliasSC7)->C7_TXMOEDA,nTotSeguro,.F.)
	   _oProcess:oHtml:ValByName("cGord"  ,"Seguro")
	EndIf
    _oProcess:oHtml:ValByName("nSeguro", _cTotais)

    _cTotais:=MCOM004Totais((_cAliasSC7)->C7_MOEDA,(_cAliasSC7)->C7_TXMOEDA,nTotMerc,.F.)
    _oProcess:oHtml:ValByName("nTotGer"	, _cTotais	)

	cQrySCR := "SELECT CR_USER, CR_APROV, CR_DATALIB, CR_I_HRAPR, CR_STATUS, R_E_C_N_O_ RECNUM, CR_NIVEL , CR_OBS "
	cQrySCR += "FROM " + RetSqlName("SCR") + " "
	cQrySCR += "WHERE CR_FILIAL = '" + SubStr(_cFilial,1,2) + "' "
	cQrySCR += "  AND CR_NUM = '" + _cNumPC + "' "
	cQrySCR += "  AND CR_TIPO = 'PC' "
	cQrySCR += "  AND D_E_L_E_T_ = ' ' "                        
	cQrySCR += "  ORDER BY CR_FILIAL, CR_NUM, CR_NIVEL "	

	dbUseArea( .T. , "TOPCONN" , TcGenQry(,, cQrySCR ) , "TRBSCR" , .T., .F. )

	DBSelectArea("TRBSCR")
	TRBSCR->(DBGoTop())
	_aAprov:={}
					
	If !TRBSCR->(Eof())
		While !TRBSCR->(Eof())
		
			nLinhas ++
			SCR->(DBGoTo(TRBSCR->RECNUM))

		    If aScan(_aAprov,TRBSCR->CR_USER+"|"+TRBSCR->CR_NIVEL ) = 0
		       aAdd(_aAprov,TRBSCR->CR_USER+"|"+TRBSCR->CR_NIVEL)
		    Else
		       TRBSCR->(DBSkip())
		       Loop
		    EndIf
			
			_cDep := FWSFAllUsers({TRBSCR->CR_USER},{"USR_DEPTO"})[1][3]

			If Empty(_cDep)
				_cDep:="XXXXXXX"
			Endif

            _cMailAux:=""
			If Upper(_cDep) <> "DIRECAO"//Não envia para diretoria
			   _cMailAux:=AllTrim(UsrRetMail(TRBSCR->CR_USER))
               If !Empty(_cMailAux) .And. !Upper(_cMailAux) $ Upper(_cEmail)
			      _cEmail += _cMailAux+";"
			   EndIf
			EndIf
			FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00429"/*cMsgId*/,"MCOM00429 - Cargo: "+_cDep+' _cMailAux: ' + _cMailAux/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
			
			If Empty(TRBSCR->CR_APROV)
				aAdd( _oProcess:oHtml:ValByName("Apr.Aprovador")	, "")
			Else
				aAdd( _oProcess:oHtml:ValByName("Apr.Aprovador")	, "Sr.(a) " + MCOM004FullNome(TRBSCR->CR_USER,.T.) )
			EndIf
					
			If Empty(TRBSCR->CR_DATALIB)
				aAdd( _oProcess:oHtml:ValByName("Apr.DtAprov")		, DToC(SToD("//")))
			Else
				aAdd( _oProcess:oHtml:ValByName("Apr.DtAprov")		, DToC(SToD(TRBSCR->CR_DATALIB)))
			EndIf

			If Empty(TRBSCR->CR_I_HRAPR)
				aAdd( _oProcess:oHtml:ValByName("Apr.HrAprov")		, "")
			Else
				aAdd( _oProcess:oHtml:ValByName("Apr.HrAprov")		, TRBSCR->CR_I_HRAPR)
			EndIf

			If Empty(SCR->CR_OBS)
				aAdd( _oProcess:oHtml:ValByName("Apr.ObsAprov")		, "")
			Else
				aAdd( _oProcess:oHtml:ValByName("Apr.ObsAprov")		, AllTrim(SCR->CR_OBS))
			EndIf
					
			If Empty(TRBSCR->CR_STATUS)
				aAdd( _oProcess:oHtml:ValByName("Apr.NivelAprov")	, ""		)
			Else
				If TRBSCR->CR_STATUS == '01'
					cNivel := "Nível Bloqueado"
				ElseIf TRBSCR->CR_STATUS == '02'
					cNivel := "Aguardando Aprovação"
				ElseIf TRBSCR->CR_STATUS == '03'
					cNivel := "Nível Aprovado"
				ElseIf TRBSCR->CR_STATUS == '04'
					cNivel := "PC Bloqueado"
				EndIf

				aAdd( _oProcess:oHtml:ValByName("Apr.NivelAprov")	, cNivel		)
			EndIf

			TRBSCR->(DBSkip())
		End
	Else
		aAdd( _oProcess:oHtml:ValByName("Apr.Aprovador")	, "")
		aAdd( _oProcess:oHtml:ValByName("Apr.HrAprov")		, "")
		aAdd( _oProcess:oHtml:ValByName("Apr.DtAprov")		, "")
		aAdd( _oProcess:oHtml:ValByName("Apr.ObsAprov")		, "")
		aAdd( _oProcess:oHtml:ValByName("Apr.NivelAprov")	, "")
	EndIf

	_oProcess:oHtml:ValByName("nLinhas"	, StrZero(nLinhas, 2) 	)

	nContrl	:= 0

	DBSelectArea("TRBSCR")
	TRBSCR->(DBCloseArea())

	If _lGrpLeite
		_cQuery := "SELECT AJ_USER "
		_cQuery += "FROM " + RetSqlName("SAJ") + " "
		_cQuery += "WHERE AJ_FILIAL = ' ' "
		_cQuery += "  AND AJ_MSBLQL <> '1' "
		_cQuery += "  AND AJ_GRCOM IN " + FormatIn(_cGrpLeite,";") 
		_cQuery += "  AND D_E_L_E_T_ = ' ' "

		dbUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQuery ) , "TRBGRP" , .T., .F. )
						
		DBSelectArea("TRBGRP")
		TRBGRP->(DBGoTop())
			
		If !TRBGRP->(Eof())
			While !TRBGRP->(Eof())
			   _cMailAux:=AllTrim(UsrRetMail(TRBGRP->AJ_USER))
               If !Empty(_cMailAux) .And. !Upper(_cMailAux) $ Upper(_cEmail) .And. !Upper(_cMailAux) $ Upper(_cEmailGrpLeite)
                  _cEmailGrpLeite += _cMailAux+";" 
			   EndIf
			   TRBGRP->(DBSkip())
			EndDo
		EndIf

		DBSelectArea("TRBGRP")
		TRBGRP->(DBCloseArea())   
		
		_cEmail += _cEmailGrpLeite 
	
    EndIf

	//=====================================
	// Populo as variáveis do template html
	//=====================================
	_oProcess:oHtml:ValByName("cLogo1"		, cLogo1 	)
	_oProcess:oHtml:ValByName("A_NOMSOL"	, cNomSol	)
	_oProcess:oHtml:ValByName("A_CUSTO"		, cCcusto	)
	_oProcess:oHtml:ValByName("A_URGEN"		, cUrgen	)
	_oProcess:oHtml:ValByName("A_INVES"		, cAplic	)
	_oProcess:oHtml:ValByName("A_CMPDI"		, cCmpdi	)
	_oProcess:oHtml:ValByName("A_FORNEC"	, AllTrim(cNomFor) + " - " + AllTrim(cCgcFor)	)

	cQryDT := "SELECT MIN(C7_DATPRF) C7_DATPRF "
	cQryDT += "FROM " + RetSqlName("SC7") + " "                                                           
	cQryDT += "WHERE C7_FILIAL = '" + SubStr(_cFilial,1,2) + "' "
	cQryDT += "  AND C7_NUM = '" + _cNumPC + "' "
  	cQryDT += "  AND C7_RESIDUO <> 'S' "	
	cQryDT += "  AND D_E_L_E_T_ = ' ' "
			
	dbUseArea(.T., "TOPCONN", TcGenQry(,,cQryDT), "TRBDT", .T., .F.)
			
	DBSelectArea("TRBDT")
	TRBDT->(DBGoTop())
			
	_oProcess:oHtml:ValByName("A_DTENTR"	, DToC(SToD(TRBDT->C7_DATPRF))		)

	DBSelectArea("TRBDT")
	TRBDT->(DBCloseArea())

    SC7->(DBSetOrder(1))
    SC7->(DBSeek(SubStr(_cFilial,1,2)+_cNumPC))

	_oProcess:oHtml:ValByName("A_VLTOTAL" , MCOM004Totais(SC7->C7_MOEDA,0,nTotMerc))//AllTrim(GETMV("MV_SIMB"+AllTrim(Str(SC7->C7_MOEDA))))+" "+Transform(nTotMerc,	PesqPict("SC7","C7_TOTAL")))
	_oProcess:oHtml:ValByName("A_OBSPC"   , _cObs    )//**PC_COMPRADOR.HTM*******
	_oProcess:oHtml:ValByName("A_OBSSC"   , cObsSc   )//PC_COMPRADOR.HTM
	_oProcess:oHtml:ValByName("A_OBSSCGEN", cObsScGen)//PC_COMPRADOR.HTM

	cReavaliar := ""		
	If (_cAliasSC7)->C7_I_CLAIM = '1'
	   cReavaliar:=cReavaliar+" **CLAIM**" 
	EndIf
	If (_cAliasSC7)->C7_I_APLIC == "I"
	   cReavaliar:=cReavaliar+" **INVESTIMENTO**"
	EndIf
	_oProcess:oHtml:ValByName("cReavaliar",cReavaliar)
	FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00430"/*cMsgId*/,"MCOM00430 - 21-IT_GRPLEITE =" +_cGrpLeite + ' /  _lGrpLeite =' + If(_lGrpLeite,".T.",".F.")+" / cFilant = "+cFilant+" / (_cAliasSC7)->C7_GRUPCOM = "+(_cAliasSC7)->C7_GRUPCOM/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	If _lGrpLeite
	   _oProcess:oHtml:ValByName("cTitulo"," - DPTO. LEITE")
	Else
	   _oProcess:oHtml:ValByName("cTitulo","")
	EndIf

	_oProcess:oHtml:ValByName("cBloc"		, cBloq)

	//=========================
	//Dados dos questionamentos
	//=========================
	_cQuest:=U_M004Quest(_cFilial, AllTrim(_cNumPC))
	_oProcess:oHtml:ValByName("cQuest",_cQuest )

	_cAssunto := "5-Retorno WF do PC Filial " + _cFilial + " Número: " + SubStr(_cNumPc,1,6) + " - " + cBloq

	_oProcess:cSubject := FWHttpEncode(_cAssunto)

    If _cOrigem = "REENVIO"
       If _lTodos
         _cEmail+=";"+Lower(AllTrim(UsrRetMail(RetCodUsr())))
       Else
         _cEmail:=Lower(AllTrim(UsrRetMail(RetCodUsr())))
       EndIf
    EndIf
   	_oProcess:cTo := _cEmail//03 - Retorno WF do PC - "IT_MAILWFC"
              
	_oProcess:Start()

	_oProcess:Finish()

	FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00431"/*cMsgId*/,'MCOM00431 - MCOM004A-E-mail: '+AllTrim(_cAssunto)+' para: ' + _cEmail/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
    
	_cMemEnv:='ENVIADO COM SUCESSO: E-mail: '+AllTrim(_cAssunto)+' para: ' + _cEmail

EndIf

PutMV("MV_WFHTML",.T.)

SC7->(DBSetOrder(1))
SC7->(DBSeek(_cFilial + _cNumPC))
If _cOrigem = "REENVIO"
   _cStsEmail:="REENVIADO "+DToC(Date())+" / "+Time()
Else
   _cStsEmail:="ENVIADO "+DToC(Date())+" / "+Time()
EndIf
While !SC7->(Eof()) .And. SC7->C7_FILIAL == _cFilial .And. SC7->C7_NUM == _cNumPC
   SC7->(RecLock("SC7",.F.))
   SC7->C7_I_ENVEM:="N"
   SC7->C7_I_STAEM:=_cStsEmail
   SC7->(MSUnLock())
   SC7->(DBSkip())
EndDo
SC7->(DBSeek(_cFilial + _cNumPC))

Return _cMemEnv 

/*
===============================================================================================================================
Programa----------: MCOM004D
Autor-------------: Darcio Ribeiro Sporl
Data da Criacao---: 17/05/2016
Descrição---------: Função criada para envio do e-mail de pergunta (questionamento)
Parametros--------: _cFilial	- Filial do Pedido de Compras
				  : _cNumPC		- Número do Pedido de Compras
				  : cBloq		- Controla se o pedido foi bloqueado ou não
				  : cNivelAP	- Indica o nível do aprovador
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MCOM004D(_cFilial, _cNumPc, _cNivelAP, _cUser, _cPergPai,_cResponsavel)
Local aArea			:= FWGetArea()
Local _cHostWF		:= SuperGetMV("IT_WFHOSTS",.F.,"http://wfteste.italac.com.br:4034/")
Local cLogo			:= _cHostWF + "htm/logo_novo.jpg"
Local nContrl		:= 0
Local cFilPC		:= SuperGetMV("IT_FILWFPC",.F.,"01")
Local cQry			:= ""
Local cQrySCR		:= ""
Local cUsuario		:= ""
Local cNomSol		:= ""
Local cNomApr		:= ""
Local cFiltro		:= ""
Local cNivel		:= ""
Local nTotal		:= 0
Local nTotMerc		:= 0
Local nTotDesc		:= 0
Local nTotIpi		:= 0
Local nTotIcms		:= 0
Local nTotDesp		:= 0
Local nTotFrete	:= 0
Local nTotSeguro	:= 0
Local nUlprc      := 0
Local dDtUlPrc    := CTOD("")
Local nLinhas		:= 0
Local nX			:= 0
Local nI			:= 0
Local nJ			:= 0
Local cTransp		:= ""
Local cNivelAP		:= ""
Local cQryDT		:= ""
Local aDados		:= {}
Local aItens		:= {}
Local aAprov		:= {}
Local cNomFor		:= ""
Local cCgcFor		:= ""
Local cEndFor		:= ""
Local cCEPFor		:= ""
Local cCidFor		:= ""
Local cEstFor		:= ""
Local cTelFor		:= ""
Local cFaxFor		:= ""
Local cIEFor		:= ""
Local cContatFor	:= ""
Local cCondPG		:= ""
Local cEmissao		:= ""
Local cNomGes		:= ""
Local cLink			:= ""
Local cTpFrete		:= ""
Local cReavaliar    := " "
Local _cRastrear    := "Envio para Questionamento do PC "
Local _cnumsc		:= ""
Local _cscemissao	:= ""
Local _cscaprov		:= ""
Local _cAliasSBZ	:= ""
Local _cAliasSBF	:= "" 
Local _cAliasSBE	:= "" 
Local _cMV_WFMLBOX  := AllTrim(GetMV('MV_WFMLBOX'))
Local cObsSc		:= ""
Local _cGrpLeite    := ""
Private _lGrpLeite  := .F.//PARA TESTAR AS DECIMAIS na função MCOM004Totais() e "cTitulo"

cFilPC		:= _cFilial + " - " + AllTrim(FWFilialName(cEmpAnt, _cFilial, 1 ))
cNomFil		:= AllTrim(FWFilialName(cEmpAnt, _cFilial, 1 ))
cNumPC		:= SubStr(_cNumPc,1,6)
cNivelAP	:= _cNivelAP
cFilant     := _cFilial
_cGrpLeite  := AllTrim(SuperGetMV("IT_GRPLEIT",.F.,""))

FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00432"/*cMsgId*/,"MCOM00432 - 10-IT_GRPLEITE =" +_cGrpLeite + ' /  _lGrpLeite =' + If(_lGrpLeite,".T.",".F.")+" / cFilant = "+cFilant/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

MaFisEnd()
M004FIniPC(cNumPC,,,cFiltro,_cFilial)

nTotal		:= 0
nTotIcms    := 0
nTotMerc	:= 0
nTotDesc	:= 0
nC7_L_EXEMG := 0
		
DBSelectArea("SM0")
DBSetOrder(1)
DBSeek(cEmpAnt + _cFilial)
		
cNomFil	:= AllTrim(SM0->M0_FILIAL)
cEndFil	:= AllTrim(SM0->M0_ENDCOB)
cCepFil	:= SubStr(AllTrim(SM0->M0_CEPCOB),1,2) + "." + SubStr(AllTrim(SM0->M0_CEPCOB),3,3) + "-" + SubStr(AllTrim(SM0->M0_CEPCOB),6,3)
cCidFil	:= SubStr(AllTrim(SM0->M0_CIDCOB),1,50)
cEstFil	:= AllTrim(SM0->M0_ESTCOB)
cTelFil	:= '(' + SubStr(SM0->M0_TEL,4,2) + ')' + SubStr(SM0->M0_TEL,7,4) + '-' +SubStr(SM0->M0_TEL,11,4)
cFaxFil	:= '(' + SubStr(SM0->M0_FAX,4,2) + ')' + SubStr(SM0->M0_FAX,7,4) + '-' +SubStr(SM0->M0_FAX,11,4)
cCGCFil	:= formCPFCNPJ(SM0->M0_CGC)
cIEFil	:= AllTrim(SM0->M0_INSC)
		
nContrl	:= 0

If Type("_cAliasSC7") == "C" .And. select(_cAliasSC7) > 0

	(_cAliasSC7)->(DBCloseArea())
	
EndIf

_cAliasSC7 := GetNextAlias()
MCOM004Q(3,_cAliasSC7,_cFilial,AllTrim(cNumPC),"","","","","","","","")
		
DBSelectArea(_cAliasSC7)
(_cAliasSC7)->(DBGoTop())
_cObs:=""		
_cPObsProdAlter:="Saldo Produtos Alternativos:"+ENTERBR
If !(_cAliasSC7)->(Eof())
	While !(_cAliasSC7)->(Eof())

		//Validade se o PC é do Grupo de Leite
		_lGrpLeite:= IIf((_cAliasSC7)->C7_GRUPCOM $ _cGrpLeite ,.T.,.F.)//PARA TESTAR AS DECIMAIS na função MCOM004Totais()  e "cTitulo"

		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00433"/*cMsgId*/,"MCOM00433 - 11-IT_GRPLEITE =" +_cGrpLeite + ' /  _lGrpLeite =' + If(_lGrpLeite,".T.",".F.")+" / cFilant = "+cFilant+" / (_cAliasSC7)->C7_GRUPCOM = "+(_cAliasSC7)->C7_GRUPCOM/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

		nContrl++
		If nContrl == 1
							
			//Codigo do processo cadastrado no CFG
			_cCodProce := "PEDIDO"
			// Arquivo html template utilizado para montagem da aprovação
			_cHtmlMode := "\Workflow\htm\pc_aprova_q.htm"
			// Assunto da mensagem
			_cAssunto := "6-Questionamento do Pedido de Compras Filial " + _cFilial + " - " + AllTrim(FWFilialName(cEmpAnt,_cFilial,1)) + " PC Número: " + AllTrim(cNumPC) + " Responsável " + _cResponsavel + " " +MCOM004FullNome(_cUser)
			// Inicialize a classe TWFProcess e assinale a variável objeto oProcess:
			_oProcess := TWFProcess():New(_cCodProce,"Questionamento de Pedido de Compras") 
			_oProcess:NewTask("Aprovacao_PC_Quest", _cHtmlMode)

			//=========================
			//Dados dos questionamentos
			//=========================
			_cQuest:=U_M004Quest(_cFilial, AllTrim(cNumPC))
			If !Empty(_cQuest)
				_oProcess:oHtml:ValByName("cQuest",_cQuest )
			Else
				_oProcess:oHtml:ValByName("cQuest","" )
			EndIf

			_oProcess:oHtml:ValByName("cUser"			, _cUser )
			_oProcess:oHtml:ValByName("cPergPai"		,_cPergPai)

			//=======================================
			//Dados do cabeçalho do pedido de compras
			//=======================================
			_oProcess:oHtml:ValByName("cLogo"			, cLogo )
			_oProcess:oHtml:ValByName("cNomFil"			, cFilPC)
			_oProcess:oHtml:ValByName("cEndFil"			, cEndFil)
			_oProcess:oHtml:ValByName("cCepFil"			, cCepFil)
			_oProcess:oHtml:ValByName("cCidFil"			, cCidFil)
			_oProcess:oHtml:ValByName("cEstFil"			, cEstFil)
			_oProcess:oHtml:ValByName("cTelFil"			, cTelFil)
			_oProcess:oHtml:ValByName("cFaxFil"			, cFaxFil)
			_oProcess:oHtml:ValByName("cCGCFil"			, cCGCFil)
			_oProcess:oHtml:ValByName("cIEFil"			, cIEFil)
					
			_oProcess:oHtml:ValByName("cNivelAP"		, cNivelAP)
			_oProcess:oHtml:ValByName("NumPC"			, cNumPC)

			If !Empty((_cAliasSC7)->C7_I_GCOM)
				cNomGes := MCOM004FullNome((_cAliasSC7)->C7_I_GCOM,.T.)
				_oProcess:oHtml:ValByName("cNomGes", cNomGes )
			Else
				_oProcess:oHtml:ValByName("cNomGes"  		, "")
			EndIf

			cQry := "SELECT C1_I_CDSOL, C1_I_CODAP, C1_NUM, C1_EMISSAO, C1_I_DTAPR, C1_I_OBSAP, C1_I_OBSSC "
			cQry += "FROM " + RetSqlName("SC1") + " "
			cQry += "WHERE C1_FILIAL = '" + (_cAliasSC7)->C7_FILIAL + "' "
			cQry += "  AND C1_NUM = '"    + (_cAliasSC7)->C7_NUMSC  + "' "
			cQry += "  AND C1_ITEM = '"   + (_cAliasSC7)->C7_ITEMSC + "' "
			cQry += "  AND D_E_L_E_T_ = ' ' "

			dbUseArea( .T. , "TOPCONN" , TcGenQry(,, cQry ) , "TRBSC1" , .T., .F. )
					
			DBSelectArea("TRBSC1")
			TRBSC1->(DBGoTop())

			If AllTrim(TRBSC1->C1_I_OBSAP) == "EXECUTADO VIA WORKFLOW" .AND.;
			   AllTrim(TRBSC1->C1_I_OBSAP) == "SC Aprovada via acesso ao Protheus"
				cObsSc := ""
			Else
				cObsSc := TRBSC1->C1_I_OBSAP
			EndIf
			cObsScGen:=TRBSC1->C1_I_OBSSC

			If !TRBSC1->(Eof())

				If Empty(AllTrim(TRBSC1->C1_I_CDSOL))
					_oProcess:oHtml:ValByName("cNomSol","")
				Else
					_oProcess:oHtml:ValByName("cNomSol",AllTrim(Posicione("ZZ7",1,SubStr(cFilPC,1,2) + TRBSC1->C1_I_CDSOL, "ZZ7_NOME")))
					cNomSol := AllTrim(Posicione("ZZ7",1,SubStr(cFilPC,1,2) + TRBSC1->C1_I_CDSOL, "ZZ7_NOME"))
				EndIf
						
				If Empty(TRBSC1->C1_I_CODAP)
					_oProcess:oHtml:ValByName("cNomApr","")
					cNomApr := ""
				Else
					_oProcess:oHtml:ValByName("cNomApr", AllTrim(Posicione("ZZ7",1,SubStr(cFilPC,1,2) + TRBSC1->C1_I_CODAP, "ZZ7_NOME")))
					cNomApr := AllTrim(Posicione("ZZ7",1,SubStr(cFilPC,1,2) + TRBSC1->C1_I_CODAP, "ZZ7_NOME"))
				EndIf
				
				_cnumsc		:= AllTrim(TRBSC1->C1_NUM)
				_cscemissao	:= AllTrim(DToC(SToD(TRBSC1->C1_EMISSAO)))
				_cscaprov		:= AllTrim(DToC(SToD(TRBSC1->C1_I_DTAPR)))

				_oProcess:oHtml:ValByName("cnumSC",AllTrim(TRBSC1->C1_NUM))
				_oProcess:oHtml:ValByName("cdtinc",AllTrim(DToC(SToD(TRBSC1->C1_EMISSAO))))
				_oProcess:oHtml:ValByName("cdtapr",AllTrim(DToC(SToD(TRBSC1->C1_I_DTAPR))))
		
			Else
				_oProcess:oHtml:ValByName("cNomSol","")
				_oProcess:oHtml:ValByName("cNomApr","")
				cNomSol := ""  
				cNomApr := ""
				_cnumsc		:= ""
				_cscemissao	:= ""
				_cscaprov	:= ""
			
				_oProcess:oHtml:ValByName("cnumSC",AllTrim(TRBSC1->C1_NUM))
				_oProcess:oHtml:ValByName("cdtinc",AllTrim(DToC(SToD(TRBSC1->C1_EMISSAO))))
				_oProcess:oHtml:ValByName("cdtapr",AllTrim(DToC(SToD(TRBSC1->C1_I_DTAPR))))
		
			EndIf

			DBSelectArea("TRBSC1")
			TRBSC1->(DBCloseArea())

			_oProcess:oHtml:ValByName("cDigiFor"		, MCOM004FullNome((_cAliasSC7)->C7_USER,.T.) )
			cUsuario := (_cAliasSC7)->C7_USER

			_oProcess:oHtml:ValByName("cObsSC",cObsSc+" -/- "+cObsScGen)//pc_aprova_q.htm TEM essa vairiavel 

			If (_cAliasSC7)->C7_I_APLIC == "C"
				cAplic := "Consumo"
			ElseIf (_cAliasSC7)->C7_I_APLIC == "I"
				cAplic := "Investimento - " + Posicione("ZZI",1,SubStr(cFilPC,1,2) + (_cAliasSC7)->C7_I_CDINV, "ZZI_DESINV")
			ElseIf (_cAliasSC7)->C7_I_APLIC == "M"
				cAplic := "Manutenção"
			ElseIf (_cAliasSC7)->C7_I_APLIC == "S"
				cAplic := "Serviço"
			EndIf
					
			_oProcess:oHtml:ValByName("cAplic", cAplic)

			cReavaliar := " "
			If MCOM004B( (_cAliasSC7)->C7_FILIAL,(_cAliasSC7)->C7_NUM, AllTrim((_cAliasSC7)->C7_I_QTAPR) )
   			   cReavaliar := "**REAVALIAR**"
			EndIf
			If (_cAliasSC7)->C7_I_CLAIM = '1'
				cReavaliar:=cReavaliar+" **CLAIM**"
			EndIf
			If (_cAliasSC7)->C7_I_APLIC == "I"
				cReavaliar:=cReavaliar+" **INVESTIMENTO**"
			EndIf
		   _oProcess:oHtml:ValByName("cReavaliar",cReavaliar)

			FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00434"/*cMsgId*/,"MCOM00433 - 12-IT_GRPLEITE =" +_cGrpLeite + ' /  _lGrpLeite =' + If(_lGrpLeite,".T.",".F.")+" / cFilant = "+cFilant+" / (_cAliasSC7)->C7_GRUPCOM = "+(_cAliasSC7)->C7_GRUPCOM/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

			If _lGrpLeite
			   _oProcess:oHtml:ValByName("cTitulo"," - DPTO. LEITE")
			Else
			   _oProcess:oHtml:ValByName("cTitulo","")
			EndIf

			If (_cAliasSC7)->C7_I_URGEN == "S"
				cUrgen	:= "Sim"
				cCorUrgen   := "color=#FF0000"
			ElseIf (_cAliasSC7)->C7_I_URGEN == "F'
				cUrgen	:= "NF"
				cCorUrgen   := "color=#FF0000"
			Else
				cUrgen	   := "Não"    
				cCorUrgen  := " "						
			EndIf
			_oProcess:oHtml:ValByName("cCorUrgen", cCorUrgen)
			_oProcess:oHtml:ValByName("cUrgen", cUrgen)

			If (_cAliasSC7)->C7_I_CMPDI == "S"
				cCmpdi	:= "Sim"
			Else
				cCmpdi	:= "Não"
			EndIf

			If (_cAliasSC7)->C7_TPFRETE == "C"
				_oProcess:oHtml:ValByName("cFrete"	, "CIF")
				cTpFrete := "CIF"
			ElseIf (_cAliasSC7)->C7_TPFRETE == "F"
				_oProcess:oHtml:ValByName("cFrete"	, "FOB")
				cTpFrete := "FOB"
			ElseIf (_cAliasSC7)->C7_TPFRETE == "T"
				_oProcess:oHtml:ValByName("cFrete"	, "TERCEIROS")
				cTpFrete := "TERCEIROS"
			ElseIf (_cAliasSC7)->C7_TPFRETE == "S"
				_oProcess:oHtml:ValByName("cFrete"	, "SEM FRETE")
				cTpFrete := "SEM FRETE"
			EndIf

			_oProcess:oHtml:ValByName("cCompDir"  		, cCmpdi)

			_oProcess:oHtml:ValByName("dDtEmiss"  		, DToC(SToD((_cAliasSC7)->C7_EMISSAO)))
			cEmissao := DToC(SToD((_cAliasSC7)->C7_EMISSAO))
                    
			If  !Empty(AllTrim((_cAliasSC7)->C7_CC))
				cCcusto	:= (_cAliasSC7)->C7_CC + " - " + AllTrim(Posicione("CTT",1,xFilial("CTT") + AllTrim((_cAliasSC7)->C7_CC), "CTT_DESC01"))
			Else
			    cCcusto := ""
			EndIf

			cNomFor		:= AllTrim((_cAliasSC7)->A2_NOME) + " - " + (_cAliasSC7)->A2_COD + "/" + (_cAliasSC7)->A2_LOJA
			cCgcFor		:= formCPFCNPJ((_cAliasSC7)->A2_CGC)
			cEndFor		:= AllTrim((_cAliasSC7)->A2_END)
			cCEPFor		:= (_cAliasSC7)->A2_CEP
			cCidFor		:= AllTrim((_cAliasSC7)->A2_MUN)
			cEstFor		:= (_cAliasSC7)->A2_EST
			cTelFor		:= "(" + (_cAliasSC7)->A2_DDD + ") " + (_cAliasSC7)->A2_TEL
			cFaxFor		:= "(" + (_cAliasSC7)->A2_DDD + ") " + (_cAliasSC7)->A2_FAX
			cIEFor		:= (_cAliasSC7)->A2_INSCR
			cContatFor	:= AllTrim((_cAliasSC7)->C7_CONTATO)
			cCondPG		:= AllTrim(Posicione("SE4",1,xFilial("SE4") + AllTrim((_cAliasSC7)->C7_COND),"E4_DESCRI"))
		    _nMoedaSC7  :=(_cAliasSC7)->C7_MOEDA
		    _nTxMoeSC7  :=(_cAliasSC7)->C7_TXMOEDA
    		_nDtMoeSC7  :=(_cAliasSC7)->C7_EMISSAO

			_oProcess:oHtml:ValByName("cNomFor"			, AllTrim((_cAliasSC7)->A2_NOME) + " - " + (_cAliasSC7)->A2_COD + "/" + (_cAliasSC7)->A2_LOJA)
			_oProcess:oHtml:ValByName("cEndFor"			, AllTrim((_cAliasSC7)->A2_END))
			_oProcess:oHtml:ValByName("cCEPFor"			, (_cAliasSC7)->A2_CEP)
			_oProcess:oHtml:ValByName("cCidFor"			, AllTrim((_cAliasSC7)->A2_MUN))
			_oProcess:oHtml:ValByName("cEstFor"			, (_cAliasSC7)->A2_EST)
			_oProcess:oHtml:ValByName("cTelFor"			, "(" + (_cAliasSC7)->A2_DDD + ") " + (_cAliasSC7)->A2_TEL)
			_oProcess:oHtml:ValByName("cFaxFor"			, "(" + (_cAliasSC7)->A2_DDD + ") " + (_cAliasSC7)->A2_FAX)
			_oProcess:oHtml:ValByName("cCGCFor"			, formCPFCNPJ((_cAliasSC7)->A2_CGC))
			_oProcess:oHtml:ValByName("cIEFor"	 		, (_cAliasSC7)->A2_INSCR)
			_oProcess:oHtml:ValByName("cContatFor"		, AllTrim((_cAliasSC7)->C7_CONTATO))
			_oProcess:oHtml:ValByName("cCondPG"	  		, AllTrim(Posicione("SE4",1,xFilial("SE4") + AllTrim((_cAliasSC7)->C7_COND),"E4_DESCRI")))

			cTransp := ""

			If !Empty((_cAliasSC7)->C7_I_CDTRA) .And. !Empty((_cAliasSC7)->C7_I_LJTRA)
				cTransp := "&nbsp;"
				cTransp += "Código: " + (_cAliasSC7)->C7_I_CDTRA + "&nbsp;Loja: " + (_cAliasSC7)->C7_I_LJTRA + "<br>"
				cTransp += "Razão Social: " + AllTrim(SubStr(Posicione("SA2", 1, xFilial("SA2")+(_cAliasSC7)->C7_I_CDTRA+(_cAliasSC7)->C7_I_LJTRA,"A2_NOME"),1,30)) + "<br>"
				cTransp += "Nome Fantasia: " + AllTrim(SubStr(Posicione("SA2", 1, xFilial("SA2")+(_cAliasSC7)->C7_I_CDTRA+(_cAliasSC7)->C7_I_LJTRA, "A2_NREDUZ"),1,30)) + "<br>"
				cTransp += "CNPJ: " + Transform(Posicione("SA2", 1, xFilial("SA2")+(_cAliasSC7)->C7_I_CDTRA+(_cAliasSC7)->C7_I_LJTRA, "A2_CGC"), PesqPict("SA2","A2_CGC")) + "&nbsp;&nbsp;&nbsp;"
				cTransp += "Ins. Estad.: " + Posicione("SA2", 1, xFilial("SA2")+(_cAliasSC7)->C7_I_CDTRA+(_cAliasSC7)->C7_I_LJTRA, "A2_INSCR") + "<br>"
				cTransp += "Bairro: " + AllTrim(SubStr(Posicione("SA2", 1, xFilial("SA2")+(_cAliasSC7)->C7_I_CDTRA+(_cAliasSC7)->C7_I_LJTRA, "A2_BAIRRO"),1,25)) + "<br>"
				cTransp += "Cidade: " + SubStr(Posicione("SA2", 1, xFilial("SA2")+(_cAliasSC7)->C7_I_CDTRA+(_cAliasSC7)->C7_I_LJTRA, "A2_MUN"),1,30) + "&nbsp;&nbsp;&nbsp;"
				cTransp += "Estado: " + Posicione("SA2", 1, xFilial("SA2")+(_cAliasSC7)->C7_I_CDTRA+(_cAliasSC7)->C7_I_LJTRA, "A2_EST") + "<br>"
				cTransp += "Telefone: (" + AllTrim(Posicione("SA2", 1, xFilial("SA2")+(_cAliasSC7)->C7_I_CDTRA+(_cAliasSC7)->C7_I_LJTRA, "A2_DDD")) + ")" + Posicione("SA2", 1, xFilial("SA2")+(_cAliasSC7)->C7_I_CDTRA+(_cAliasSC7)->C7_I_LJTRA, "A2_TEL") + "<br>"
				cTransp += "Contato: " + AllTrim(Posicione("SA2", 1, xFilial("SA2")+(_cAliasSC7)->C7_I_CDTRA+(_cAliasSC7)->C7_I_LJTRA, "A2_CONTATO")) + "<br>"
				cTransp += "Obs. Frete: " + If((_cAliasSC7)->C7_I_TPFRT == "1","Entregar na Transportadora","Solicitar Coleta pela Transportadora" )
			EndIf
					
			_oProcess:oHtml:ValByName("cTransp"	  		, cTransp)
					
		EndIf

		aAdd( _oProcess:oHtml:ValByName("Itens.Item" 			), (_cAliasSC7)->C7_ITEM 												)
		aAdd( _oProcess:oHtml:ValByName("Itens.Prodpc" 			), (_cAliasSC7)->C7_PRODUTO								 				)
		If AllTrim((_cAliasSC7)->C7_I_DESCD) $ (_cAliasSC7)->C7_DESCRI
			aAdd( _oProcess:oHtml:ValByName("Itens.DesProd"		), AllTrim((_cAliasSC7)->C7_DESCRI)														)
		Else
			aAdd( _oProcess:oHtml:ValByName("Itens.DesProd"		), AllTrim((_cAliasSC7)->C7_DESCRI) + " " + AllTrim((_cAliasSC7)->C7_I_DESCD)			)
		EndIf
		aAdd( _oProcess:oHtml:ValByName("Itens.UM"				), (_cAliasSC7)->C7_UM													)
		aAdd( _oProcess:oHtml:ValByName("Itens.qtde"			), Transform((_cAliasSC7)->C7_QUANT, PesqPict("SC7","C7_QUANT"))		)

        _cValor:=MCOM004Totais((_cAliasSC7)->C7_MOEDA,0,(_cAliasSC7)->C7_PRECO,.F.)
		aAdd( _oProcess:oHtml:ValByName("Itens.VlrUni"			), _cValor)//Transform((_cAliasSC7)->C7_PRECO, "@E 999,999,999.999") 	      )

        _cValor:=MCOM004Totais((_cAliasSC7)->C7_MOEDA,0,(_cAliasSC7)->C7_VLDESC,.F.)
		aAdd( _oProcess:oHtml:ValByName("Itens.VlrDes"		   	), _cValor)//Transform((_cAliasSC7)->C7_VLDESC, PesqPict("SC7","C7_VLDESC"))  )

        _cValor:=MCOM004Totais((_cAliasSC7)->C7_MOEDA,0,((_cAliasSC7)->C7_TOTAL-(_cAliasSC7)->C7_VLDESC),.F.)
		aAdd( _oProcess:oHtml:ValByName("Itens.VlrTot"			), _cValor)//Transform((_cAliasSC7)->C7_TOTAL, PesqPict("SC7","C7_TOTAL")) 	  )

        _cValor:=MCOM004Totais(1,0,(_cAliasSC7)->C7_PICM,.F.,.T.)
		aAdd( _oProcess:oHtml:ValByName("Itens.ICMS"			), _cValor)

		aAdd( _oProcess:oHtml:ValByName("Itens.DtEmis"			), DToC(SToD((_cAliasSC7)->C7_DATPRF))									)

		If !Empty(_cAliasSBZ) .And. select(_cAliasSBZ) > 0
			(_cAliasSBZ)->(DBCloseArea())
		EndIf
		
		_cAliasSBZ := GetNextAlias()
		MCOM004Q(6,_cAliasSBZ,(_cAliasSC7)->C7_FILIAL,"","","","","","","","",(_cAliasSC7)->C7_PRODUTO)

		nUlPrc := 0
      dDtUlPrc := CTOD("")
		If !(_cAliasSBZ)->(Eof())
		   If (_cAliasSC7)->C7_MOEDA = 1
		      nUlPrc  :=(_cAliasSBZ)->BZ_UPRC
            dDtUlPrc:=SToD((_cAliasSBZ)->BZ_UCOM)
		   ElseIf !Empty((_cAliasSBZ)->BZ_UCOM)
		      dDtUlPrc:=SToD((_cAliasSBZ)->BZ_UCOM)
		      nTxMoeda:=RecMoeda(dDtUlPrc,(_cAliasSC7)->C7_MOEDA)
		      nUlPrc  :=((_cAliasSBZ)->BZ_UPRC/nTxMoeda)
		   EndIf   
		EndIf
        _cValor:=MCOM004Totais((_cAliasSC7)->C7_MOEDA,0,nUlPrc,.F.)
		aAdd( _oProcess:oHtml:ValByName("Itens.VlrUc"),_cValor)
      aAdd( _oProcess:oHtml:ValByName("Itens.DtUc"),DToC(dDtUlPrc))

		If !Empty(_cAliasSBF) .And. select(_cAliasSBF) > 0
			(_cAliasSBF)->(DBCloseArea())
		EndIf
		_cProdAlt:=Posicione("SGI",1,(_cAliasSC7)->C7_FILIAL+(_cAliasSC7)->C7_PRODUTO,"GI_PRODALT")
		If !Empty(_cProdAlt)
		   _cAliasSBF := GetNextAlias()
		   MCOM004Q(7,_cAliasSBF,(_cAliasSC7)->C7_FILIAL,"","","","","","","","",_cProdAlt)
		   _cPObsProdAlter+="<b>"+AllTrim(_cProdAlt)+'-'+AllTrim(Posicione("SB1",1,xFilial("SB1")+_cProdAlt,"B1_DESC"))+;
		                    " = "+AllTrim(Transform((_cAliasSBF)->B2_QATU, PesqPict("SB2","B2_QATU")))+"</b>"+ENTERBR
		EndIf

		If !Empty(_cAliasSBF) .And. select(_cAliasSBF) > 0
			(_cAliasSBF)->(DBCloseArea())
		EndIf
				
		_cAliasSBF := GetNextAlias()
		MCOM004Q(7,_cAliasSBF,(_cAliasSC7)->C7_FILIAL,"","","","","","","","",(_cAliasSC7)->C7_PRODUTO)
		If !(_cAliasSBF)->(Eof())
			aAdd( _oProcess:oHtml:ValByName("Itens.SldAtFil"		), Transform((_cAliasSBF)->B2_QATU, PesqPict("SB2","B2_QATU"))		)
		Else
			aAdd( _oProcess:oHtml:ValByName("Itens.SldAtFil"		), Transform(0, PesqPict("SB2","B2_QATU"))		)
		EndIf

		If !Empty(_cAliasSBE) .And. select(_cAliasSBE) > 0
			(_cAliasSBE)->(DBCloseArea())
		EndIf
				
		_cAliasSBE := GetNextAlias()
		
		MCOM004Q(8,_cAliasSBE,(_cAliasSC7)->C7_FILIAL,"","","","","","","","",(_cAliasSC7)->C7_PRODUTO)
		If !(_cAliasSBE)->(Eof())
			aAdd( _oProcess:oHtml:ValByName("Itens.SldAtEmp"		), Transform((_cAliasSBE)->B2_QATU, PesqPict("SB2","B2_QATU"))		)
		Else
			aAdd( _oProcess:oHtml:ValByName("Itens.SldAtEmp"		), Transform(0, PesqPict("SB2","B2_QATU"))		)
		EndIf

		aAdd(aItens, {	(_cAliasSC7)->C7_ITEM,;			// [01] Item
						(_cAliasSC7)->C7_PRODUTO,;		// [02] Código do Produto
						IIf( AllTrim((_cAliasSC7)->C7_I_DESCD) $ (_cAliasSC7)->C7_DESCRI, AllTrim((_cAliasSC7)->C7_DESCRI), AllTrim((_cAliasSC7)->C7_DESCRI) + " " + AllTrim((_cAliasSC7)->C7_I_DESCD)),;	// [03] Descrição do Produto
						(_cAliasSC7)->C7_UM,;			// [04] Unidade de Medida
						Transform((_cAliasSC7)->C7_QUANT, PesqPict("SC7","C7_QUANT")),;		// [05] Quantidade
						(_cAliasSC7)->C7_PRECO ,;	// [06] Preço
						(_cAliasSC7)->C7_VLDESC,;	// [07] Valor do Desconto
						Transform((_cAliasSC7)->C7_TOTAL, PesqPict("SC7","C7_TOTAL")),;		// [08] Valor Total
						(_cAliasSC7)->C7_PICM,;	// [09] Valor do IPI
						Transform((_cAliasSC7)->C7_ICMSRET, PesqPict("SC7","C7_ICMSRET")),;	// [10] Valor do ICMS RET
						DToC(SToD((_cAliasSC7)->C7_DATPRF)),;								// [11] Data de Entrega
						nUlPrc,;		                	// [12] Ultimo Preço de Vendas
						Transform((_cAliasSBF)->B2_QATU, PesqPict("SB2","B2_QATU")),;		// [13] Quantidade Total por Filial
						Transform((_cAliasSBE)->B2_QATU, PesqPict("SB2","B2_QATU")),;  		// [14] Quantidade Total da Empresa
						((_cAliasSC7)->C7_TOTAL-(_cAliasSC7)->C7_VLDESC),; //[15] Valor Total - Valor do Desconto
                  DToC(dDtUlPrc) }) //[16] Data Ultimo Preço de Vendas


		nTotDesc	+= (_cAliasSC7)->C7_VLDESC  
		nTotal		+= (_cAliasSC7)->C7_TOTAL
		nC7_L_EXEMG += (_cAliasSC7)->C7_L_EXEMG 
		nTotIcms    += (_cAliasSC7)->C7_VALICM//MaFisRet(Val((_cAliasSC7)->C7_ITEM),"IT_VALICM") 

		If !Empty((_cAliasSC7)->C7_OBS) .And. !Upper(AllTrim((_cAliasSC7)->C7_OBS)) $ Upper(_cObs)
			_cObs+=AllTrim((_cAliasSC7)->C7_OBS)+" // "
        EndIf

		(_cAliasSBF)->(DBCloseArea())
		(_cAliasSBE)->(DBCloseArea())
		(_cAliasSC7)->(DBSkip())
			
	EndDo
			
    (_cAliasSC7)->(DBGoTop())
	nTotMerc	:= MaFisRet(,'NF_TOTAL')
	nTotIpi		:= MaFisRet(,'NF_VALIPI')
	nTotDesp	:= MaFisRet(,'NF_DESPESA')
	_nTotImp    := nTotal+nTotIpi
    _nOutImp    := MaFisRet(,'NF_VALISS')+MaFisRet(,'NF_VALIRR')+MaFisRet(,'NF_VALINS')+MaFisRet(,'NF_VALSOL')

	If(_cAliasSC7)->C7_TPFRETE = "F"
	   nTotFrete:=(_cAliasSC7)->C7_FRETCON
	Else
	   nTotFrete:= MaFisRet(,'NF_FRETE')
	EndIf
	nTotSeguro	:= MaFisRet(,'NF_SEGURO')

    _cObs:=LEFT( _cObs, Len(_cObs)-4)
	If (_cAliasSC7)->C7_MOEDA <> 1
	   _cObs:=MCOM004Moeda((_cAliasSC7)->C7_MOEDA,(_cAliasSC7)->C7_TXMOEDA,_cObs,(_cAliasSC7)->C7_EMISSAO)
    EndIf

	If "</b>" $ _cPObsProdAlter
	   If !Empty(_cObs) 
	      _cPObsProdAlter:=_cObs+ENTERBR+_cPObsProdAlter
	   EndIf
	Else
	   _cPObsProdAlter:=_cObs
	EndIf

    _oProcess:oHtml:ValByName("cObs", _cPObsProdAlter)//FORA While

    _cTotais:=MCOM004Totais((_cAliasSC7)->C7_MOEDA,(_cAliasSC7)->C7_TXMOEDA,nTotal,.F.)
	_oProcess:oHtml:ValByName("nTotMer"	, _cTotais	)

    _cTotais:=MCOM004Totais((_cAliasSC7)->C7_MOEDA,(_cAliasSC7)->C7_TXMOEDA,_nTotImp,.F.)
	_oProcess:oHtml:ValByName("nTotImp"	, _cTotais	)

    _cTotais:=MCOM004Totais((_cAliasSC7)->C7_MOEDA,(_cAliasSC7)->C7_TXMOEDA,nTotDesc,.F.)
	_oProcess:oHtml:ValByName("nTotDesc"	, _cTotais	)

    _cTotais:=MCOM004Totais((_cAliasSC7)->C7_MOEDA,(_cAliasSC7)->C7_TXMOEDA,nTotIpi,.F.)
	_oProcess:oHtml:ValByName("nIPI"	, _cTotais	)

    _cTotais:=MCOM004Totais((_cAliasSC7)->C7_MOEDA,(_cAliasSC7)->C7_TXMOEDA,nTotIcms,.F.)
	_oProcess:oHtml:ValByName("nICMS"	, _cTotais	)

    _cTotais:=MCOM004Totais((_cAliasSC7)->C7_MOEDA,(_cAliasSC7)->C7_TXMOEDA,_nOutImp,.F.)
	_oProcess:oHtml:ValByName("nOutImp"	, _cTotais	)

    _cTotais:=MCOM004Totais((_cAliasSC7)->C7_MOEDA,(_cAliasSC7)->C7_TXMOEDA,nTotDesp,.F.)
	_oProcess:oHtml:ValByName("nDesp"	, _cTotais)

    _cTotais:=MCOM004Totais((_cAliasSC7)->C7_MOEDA,(_cAliasSC7)->C7_TXMOEDA,nTotFrete,.F.)
	_oProcess:oHtml:ValByName("nVlFrete", _cTotais	)
	FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00435"/*cMsgId*/,"MCOM00435 - 13-IT_GRPLEITE =" +_cGrpLeite + ' /  _lGrpLeite =' + If(_lGrpLeite,".T.",".F.")+" / cFilant = "+cFilant+" / (_cAliasSC7)->C7_GRUPCOM = "+(_cAliasSC7)->C7_GRUPCOM/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
    If _lGrpLeite
	   _cTotais:=MCOM004Totais(1,0,nC7_L_EXEMG,(_cAliasSC7)->C7_TXMOEDA <> 1)
	   _oProcess:oHtml:ValByName("cGord","Vlr.Pag.MG")
	Else
       _cTotais:=MCOM004Totais((_cAliasSC7)->C7_MOEDA,(_cAliasSC7)->C7_TXMOEDA,nTotSeguro,.F.)
	   _oProcess:oHtml:ValByName("cGord"  ,"Seguro")
	EndIf
	_oProcess:oHtml:ValByName("nSeguro", _cTotais)

	_cTotais:=MCOM004Totais((_cAliasSC7)->C7_MOEDA,(_cAliasSC7)->C7_TXMOEDA,nTotMerc,.F.)
    _oProcess:oHtml:ValByName("nTotGer"	, _cTotais	)
	
	cQrySCR := "SELECT CR_USER, CR_APROV, CR_DATALIB, CR_I_HRAPR, CR_STATUS, R_E_C_N_O_ RECNUM , CR_NIVEL, CR_OBS " 
	cQrySCR += "FROM " + RetSqlName("SCR") + " "
	cQrySCR += "WHERE CR_FILIAL = '" + _cFilial + "' "
	cQrySCR += "  AND CR_NUM = '" + _cNumPC + "' "
	cQrySCR += "  AND CR_TIPO = 'PC' "
	cQrySCR += "  AND D_E_L_E_T_ = ' ' "
	cQrySCR += "  ORDER BY CR_FILIAL, CR_NUM, CR_NIVEL "
	
	dbUseArea( .T. , "TOPCONN" , TcGenQry(,, cQrySCR ) , "TRBAPR" , .T., .F. )
					
	DBSelectArea("TRBAPR")
	TRBAPR->(DBGoTop())
					
    aAprov:={}
    
	If !TRBAPR->(Eof())
		While !TRBAPR->(Eof())
			nLinhas ++
			SCR->(DBGoTo(TRBAPR->RECNUM))

		    If aScan(aAprov,{|A| A[6] == TRBAPR->CR_USER+"|"+TRBAPR->CR_NIVEL } ) <> 0
			   FWLogMsg("WARN"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00436"/*cMsgId*/,"MCOM00436 - 3-Aprovador repetido no SCR: "+TRBAPR->CR_USER+"-"+MCOM004FullNome(TRBAPR->CR_USER)+" Nivel: "+TRBAPR->CR_NIVEL/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		       TRBAPR->(DBSkip())
		       Loop
		    EndIf				

			If Empty(TRBAPR->CR_APROV)
				aAdd( _oProcess:oHtml:ValByName("Apr.Aprovador")	, "")
			Else
				aAdd( _oProcess:oHtml:ValByName("Apr.Aprovador")	, "Sr.(a) " + MCOM004FullNome(TRBAPR->CR_USER,.T.) )
			EndIf
					
			If Empty(TRBAPR->CR_DATALIB)
				aAdd( _oProcess:oHtml:ValByName("Apr.DtAprov")		, DToC(SToD("//")))
			Else
				aAdd( _oProcess:oHtml:ValByName("Apr.DtAprov")		, DToC(SToD(TRBAPR->CR_DATALIB)))
			EndIf

			If Empty(TRBAPR->CR_I_HRAPR)
				aAdd( _oProcess:oHtml:ValByName("Apr.HrAprov")		, "")
			Else
				aAdd( _oProcess:oHtml:ValByName("Apr.HrAprov")		, TRBAPR->CR_I_HRAPR)
			EndIf

			If Empty(SCR->CR_OBS)
				aAdd( _oProcess:oHtml:ValByName("Apr.ObsAprov")		, "")
			Else
				aAdd( _oProcess:oHtml:ValByName("Apr.ObsAprov")		, AllTrim(SCR->CR_OBS))
			EndIf
					
			If Empty(TRBAPR->CR_STATUS)
				aAdd( _oProcess:oHtml:ValByName("Apr.NivelAprov")	, ""		)
			Else
				If TRBAPR->CR_STATUS == '01'
					cNivel := "Nível Bloqueado"
				ElseIf TRBAPR->CR_STATUS == '02'
					cNivel := "Aguardando Aprovação"
				ElseIf TRBAPR->CR_STATUS == '03'
					cNivel := "Nível Aprovado"
				ElseIf TRBAPR->CR_STATUS == '04'
					cNivel := "PC Bloqueado"
				EndIf

				aAdd( _oProcess:oHtml:ValByName("Apr.NivelAprov")	, cNivel		)
			EndIf
		    If aScan(aAprov,{|A| A[6] == TRBAPR->CR_USER+"|"+TRBAPR->CR_NIVEL } ) = 0
			aAdd(aAprov, {	"Sr.(a) " + MCOM004FullNome(TRBAPR->CR_USER,.T.) ,;	// [01] Nome do Aprovador
							DToC(SToD(TRBAPR->CR_DATALIB)),;	// [02] Data da Liberação
							 TRBAPR->CR_I_HRAPR,;				   // [03] Hora da Aprovação
							 AllTrim(SCR->CR_OBS),;			       // [04] Observação da Aprovação
							cNivel,;							   // [05] Nível do Aprovador
							 TRBAPR->CR_USER+"|"+TRBAPR->CR_NIVEL})// [06] Chave para previnir duplicação
		    Else
			   FWLogMsg("WARN"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00437"/*cMsgId*/,"MCOM00437 - 4-Aprovador repetido no SCR: "+TRBAPR->CR_USER+"-"+MCOM004FullNome(TRBAPR->CR_USER)+" Nivel: "+TRBAPR->CR_NIVEL/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		    EndIf				

			TRBAPR->(DBSkip())
		End
	Else
		aAdd( _oProcess:oHtml:ValByName("Apr.Aprovador")	, "")
		aAdd( _oProcess:oHtml:ValByName("Apr.HrAprov")		, "")
		aAdd( _oProcess:oHtml:ValByName("Apr.DtAprov")		, "")
		aAdd( _oProcess:oHtml:ValByName("Apr.ObsAprov")		, "")
		aAdd( _oProcess:oHtml:ValByName("Apr.NivelAprov")	, "")
	EndIf

	_oProcess:oHtml:ValByName("nLinhas"	, StrZero(nLinhas, 2) 	)

	aAdd(aDados, {	cFilPC,;				// [01] Filial do Pedido de Compras
					cUsuario,;				// [02] Código do Usuário
					cNomFil,;				// [03] Nome da Filial
					cNumPC,;				// [04] Número do Pedido
					cNivelAP,;				// [05] Nível do Aprovador
					cEndFil,;				// [06] Endereço da Filial
					cCepFil,;				// [07] CEP da Filial
					cCidFil,;				// [08] Cidade da Filial		
					cEstFil,;				// [09] Estado da Filial
					cTelFil,;				// [10] Telefone da Filial
					cFaxFil,;				// [11] Fax da Filial
					cCGCFil,;				// [12] CGC da Filial
					cIEFil,;				// [13] I.E da Filial
					cNomGes,;				// [14] Nome do Gestor de Compras
					cNomSol,;				// [15] Nome do Solicitante
					cNomApr,;				// [16] Nome do Aprovador
					cAplic,;				// [17] Aplicação
					cUrgen,;				// [18] Urgente
					cCmpdi,;				// [19] Compra Direta
					cEmissao,;				// [20] Emissão do Pedido de Compras
					cNomFor,;				// [21] Nome do Fornecedor
					cCgcFor,;				// [22] CGC do Fornecedor
					cEndFor,;				// [23] Endereço do Fornecedor
					cCEPFor,;  				// [24] CEP do Fornecedor
					cCidFor,;				// [25] Município do Fornecedor
					cEstFor,;				// [26] Estado do Fornecedor
					cTelFor,;				// [27] Telefone do Fornecedor
					cFaxFor,;				// [28] Fax do Fornecedor
					cIEFor,;				// [29] I.E do Fornecedor
					cContatFor,;			// [30] Contato
					cCondPG,;				// [31] Condição de Pagamento
					cTransp,;				// [32] Dados da Transportadora
					nTotal,;				// [33] Total do Pedido
					nTotMerc,;				// [34] Total das Mercadorias
					nTotIpi,;				// [35] Total IPI
					nTotIcms,;				// [36] Total ICMS
					nTotDesp,;				// [37] Total das Despesas
					nTotFrete,;				// [38] Total do Frete
					nTotSeguro,;			// [39] Total do Seguro
					nTotDesc,;				// [40] Total Desconto
					_cObs,;					// [41] Observação do Pedido
					cTpFrete,;				// [42] Tipo de Frete
					aItens,;				// [43] Dados dos Itens
					aAprov,;				// [44] Dados dos Aprovadores
					cCorUrgen,;             // [45] Cor variavel Urgente
					cReavaliar,;			// [46] Reavaliar ou não
					_cnumsc,;				// [47] Numero da SC
					_cscemissao,;			// [48] Emissão da SC
					_cscaprov,;             // [49] Aprovação da SC
					_nMoedaSC7,;            // [50] MOEDA 
					_nTxMoeSC7,;            // [51] TAXA da MOEDA
					_nDtMoeSC7,;            // [52] DATA DA TAXA da MOEDA
					_cPObsProdAlter})       // [53] Observação com produtos alternaivos

	cEstFil	:= AllTrim(SM0->M0_ESTCOB)
	cTelFil	:= '(' + SubStr(SM0->M0_TEL,4,2) + ')' + SubStr(SM0->M0_TEL,7,4) + '-' +SubStr(SM0->M0_TEL,11,4)
	cFaxFil	:= '(' + SubStr(SM0->M0_FAX,4,2) + ')' + SubStr(SM0->M0_FAX,7,4) + '-' +SubStr(SM0->M0_FAX,11,4)
	cCGCFil	:= formCPFCNPJ(SM0->M0_CGC)
	cIEFil	:= AllTrim(SM0->M0_INSC)
	
	nContrl	:= 0

	DBSelectArea("TRBAPR")
	TRBAPR->(DBCloseArea())

	//=========================================================================
	// Informe o nome da função de retorno a ser executada quando a mensagem de
	// respostas retornar ao Workflow:
	//=========================================================================
	_oProcess:bReturn := "U_M004RET" //Retorno do pc_aprova_q.htm
		
	//========================================================================
	// Após ter repassado todas as informacões necessárias para o Workflow,
	// execute o método Start() para gerar todo o processo e enviar a mensagem
	// ao destinatário.
    //========================================================================
	_cMailID := _oProcess:Start("\workflow\emp01\MCOM004")
	cLink := _cMailID

	If !File("\workflow\emp01\MCOM004\" + _cMailID + ".htm")
	   FWLogMsg("WARN"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00438"/*cMsgId*/,"MCOM00438 - 03 - MCOM004-Arquivo \workflow\emp01\MCOM004\" + _cMailID + ".htm nao encontrado."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	EndIf 

	//==================================================================
	// "LINK"
	//==================================================================
	//cConsulta := MCOM004C(aDados)

	//====================================
	//Codigo do processo cadastrado no CFG
	//====================================
   	_cCodProce := "PEDIDO"

	//====================
	// Assunto da mensagem
	//====================
	_cAssunto := "7-Questionamento " + AllTrim(cNomFil) + " - " + "PC " + cNumPC + " - " + AllTrim(cNomFor) + " Responsável " + _cResponsavel + " " +MCOM004FullNome(_cUser)

	//======================================================================
	// Inicialize a classe TWFProcess e assinale a variável objeto oProcess:
	//======================================================================
	_oProcess := TWFProcess():New(_cCodProce,"Questionamento do Pedido de Compras")
	//=================================================================
	// Criamos o link para o arquivo que foi gerado na tarefa anterior.  
	//=================================================================
	_oProcess:NewTask("LINK", "\workflow\htm\pc_link_q.htm")//Atalho no corpo do CORPO DO EMAIL

	chtmlfile := cLink + ".htm"
	cMailTo	:= "mailto:" + AllTrim(Posicione("WF7", 1, xFilial("WF7") + _cMV_WFMLBOX, "WF7_ENDERE"))
	chtmltexto := wfloadfile("\workflow\emp01\MCOM004\" + chtmlfile )//Carrega o arquivo 
	chtmltexto := StrTran( chtmltexto, cmailto, "WFHTTPRET.APL" )//Procura e troca a string
	wfsavefile("\workflow\emp01\MCOM004\" + chtmlfile, chtmltexto)//Grava o arquivo de volta
	cLink := _cHostWF + "emp01/MCOM004/" + cLink + ".htm"

	//=====================================
	// Populo as variáveis do template html
	//=====================================
	_oProcess:oHtml:ValByName("cLogo"		, cLogo 	)
	_oProcess:oHtml:ValByName("A_LINK"		, cLink		)//clique no corpo do email
	_oProcess:oHtml:ValByName("A_NOMSOL"	, cNomSol	)
	_oProcess:oHtml:ValByName("A_NOMAPR"	, MCOM004FullNome(_cUser,.T.) )
	_oProcess:oHtml:ValByName("A_CUSTO"		, cCcusto	)
	_oProcess:oHtml:ValByName("A_URGEN"		, cUrgen	)
	_oProcess:oHtml:ValByName("A_INVES"		, cAplic	)
	_oProcess:oHtml:ValByName("A_CMPDI"		, cCmpdi	)
	_oProcess:oHtml:ValByName("A_FORNEC"	, AllTrim(cNomFor) + " - " + AllTrim(cCgcFor)	)

	cQryDT := "SELECT MIN(C7_DATPRF) C7_DATPRF "
	cQryDT += "FROM " + RetSqlName("SC7") + " "
	cQryDT += "WHERE C7_FILIAL = '" + SubStr(cFilPC,1,2) + "' "
	cQryDT += " AND C7_NUM = '" + cNumPC + "' "
  	cQryDT += " AND C7_RESIDUO <> 'S' "
	cQryDT += " AND D_E_L_E_T_ = ' ' "
			
	dbUseArea(.T., "TOPCONN", TcGenQry(,,cQryDT), "TRBDT", .T., .F.)
			
	DBSelectArea("TRBDT")
	TRBDT->(DBGoTop())
			
	_oProcess:oHtml:ValByName("A_DTENTR"	, DToC(SToD(TRBDT->C7_DATPRF))		)
			
	DBSelectArea("TRBDT")
	TRBDT->(DBCloseArea())

    SC7->(DBSetOrder(1))
    SC7->(DBSeek(SubStr(cFilPC,1,2)+cNumPC))

	_oProcess:oHtml:ValByName("A_VLTOTAL" , MCOM004Totais(SC7->C7_MOEDA,0,nTotMerc))//AllTrim(GETMV("MV_SIMB"+AllTrim(Str(SC7->C7_MOEDA))))+" "+Transform(nTotMerc,	PesqPict("SC7","C7_TOTAL"))		)
	_oProcess:oHtml:ValByName("A_OBSPC"   , _cObs    )//**PC_LINK_Q.HTM**************
	_oProcess:oHtml:ValByName("A_OBSSC"   , cObsSc   )//PC_LINK_Q.HTM
    _oProcess:oHtml:ValByName("A_OBSSCGEN", cObsScGen)//PC_LINK_Q.HTM

	//=========================
	//Dados dos questionamentos
	//=========================
	If !Empty(U_M004Quest(_cFilial, AllTrim(cNumPC)))
		_oProcess:oHtml:ValByName("cQuest"			, U_M004Quest(_cFilial, AllTrim(cNumPC)) )
	Else
		_oProcess:oHtml:ValByName("cQuest"			, "" )
	EndIf

	For nX := 1 To Len(aDados)

		//=======================================
		//Dados do cabeçalho do pedido de compras
		//=======================================
		_oProcess:oHtml:ValByName("cLogo"			, cLogo )
		_oProcess:oHtml:ValByName("cNomFil"			, aDados[nX][01])
		_oProcess:oHtml:ValByName("cEndFil"			, aDados[nX][06])
		_oProcess:oHtml:ValByName("cCepFil"			, aDados[nX][07])
		_oProcess:oHtml:ValByName("cCidFil"			, aDados[nX][08])
		_oProcess:oHtml:ValByName("cEstFil"			, aDados[nX][09])
		_oProcess:oHtml:ValByName("cTelFil"			, aDados[nX][10])
		_oProcess:oHtml:ValByName("cFaxFil"			, aDados[nX][11])
		_oProcess:oHtml:ValByName("cCGCFil"			, aDados[nX][12])
		_oProcess:oHtml:ValByName("cIEFil"			, aDados[nX][13])
		_oProcess:oHtml:ValByName("NumPC"			, aDados[nX][04])
		_oProcess:oHtml:ValByName("cnumSC"			, aDados[nX][47])
		_oProcess:oHtml:ValByName("cdtinc"			, aDados[nX][48])
		_oProcess:oHtml:ValByName("cdtapr"			, aDados[nX][49])
		
 

		If Empty(aDados[nX][14])
			_oProcess:oHtml:ValByName("cNomGes"  		, "")
		Else
			_oProcess:oHtml:ValByName("cNomGes", aDados[nX][14])
		EndIf
		
		If Empty(aDados[nX][15])
			_oProcess:oHtml:ValByName("cNomSol"			, "")
		Else
			_oProcess:oHtml:ValByName("cNomSol"			, aDados[nX][15])
		EndIf
								
		If Empty(aDados[nX][16])
			_oProcess:oHtml:ValByName("cNomApr"			, "")
		Else
			_oProcess:oHtml:ValByName("cNomApr"			, aDados[nX][16])
		EndIf
		
		_oProcess:oHtml:ValByName("cDigiFor"		, MCOM004FullNome(aDados[nX][02],.T.) )

		If aDados[nX][50] <> 1
		   _cObs:=MCOM004Moeda(aDados[nX][50],aDados[nX][51],aDados[nX][41],aDados[nX][52])
        Else
		   _cObs:=AllTrim(aDados[nX][41]) 
        EndIf
		_cPObsProdAlter:=AllTrim(aDados[nX][53]) 
		_oProcess:oHtml:ValByName("cObs",_cPObsProdAlter)//ESTA ANTES DO For DOS ITENS PQ O aDados[nX][41] já tem as descricao de todos os itens
	
		_oProcess:oHtml:ValByName("cAplic" 		  	, aDados[nX][17])
		_oProcess:oHtml:ValByName("cUrgen"  		, aDados[nX][18])
		_oProcess:oHtml:ValByName("cCorUrgen"  		, aDados[nX][45])
		_oProcess:oHtml:ValByName("cCompDir"  		, aDados[nX][19])
		_oProcess:oHtml:ValByName("dDtEmiss"  		, aDados[nX][20])
		
		_oProcess:oHtml:ValByName("cNomFor"			, aDados[nX][21])
		_oProcess:oHtml:ValByName("cEndFor"			, aDados[nX][23])
		_oProcess:oHtml:ValByName("cCEPFor"			, aDados[nX][24])
		_oProcess:oHtml:ValByName("cCidFor"			, aDados[nX][25])
		_oProcess:oHtml:ValByName("cEstFor"			, aDados[nX][26])
		_oProcess:oHtml:ValByName("cTelFor"			, aDados[nX][27])
		_oProcess:oHtml:ValByName("cFaxFor"			, aDados[nX][28])
		_oProcess:oHtml:ValByName("cCGCFor"			, aDados[nX][22])
		_oProcess:oHtml:ValByName("cIEFor"	 		, aDados[nX][29])
		_oProcess:oHtml:ValByName("cContatFor"		, aDados[nX][30])
		_oProcess:oHtml:ValByName("cCondPG"	  		, aDados[nX][31])		
		_oProcess:oHtml:ValByName("cTransp"	  		, aDados[nX][32])				
		_oProcess:oHtml:ValByName("cFrete"			, aDados[nX][42])				
		_oProcess:oHtml:ValByName("cReavaliar"      , aDados[nX][46])
        
		FWLogMsg("WARN"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00439"/*cMsgId*/,"MCOM00439 - 14-IT_GRPLEITE =" +_cGrpLeite + ' /  _lGrpLeite =' + If(_lGrpLeite,".T.",".F.")+" / cFilant = "+cFilant+" / (_cAliasSC7)->C7_GRUPCOM = "+(_cAliasSC7)->C7_GRUPCOM/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		If _lGrpLeite
		   _oProcess:oHtml:ValByName("cTitulo"," - DPTO. LEITE")
		Else
		   _oProcess:oHtml:ValByName("cTitulo","")
		EndIf
		
		For nI := 1 To Len(aDados[nX][43])			
			aAdd( _oProcess:oHtml:ValByName("Itens.Item" 		), aDados[nX][43][nI][01])
			aAdd( _oProcess:oHtml:ValByName("Itens.Prodpc" 		), aDados[nX][43][nI][02])
			aAdd( _oProcess:oHtml:ValByName("Itens.DesProd"		), aDados[nX][43][nI][03])
			aAdd( _oProcess:oHtml:ValByName("Itens.UM"			), aDados[nX][43][nI][04])
			aAdd( _oProcess:oHtml:ValByName("Itens.qtde"		), aDados[nX][43][nI][05])

            _cValor:=MCOM004Totais(aDados[nX][50],0,aDados[nX][43][nI][06],.F.)
			aAdd( _oProcess:oHtml:ValByName("Itens.VlrUni"		), _cValor)//aDados[nX][43][nI][06])

            _cValor:=MCOM004Totais(aDados[nX][50],0,aDados[nX][43][nI][07],.F.)
			aAdd( _oProcess:oHtml:ValByName("Itens.VlrDes"		), _cValor)//aDados[nX][43][nI][07])

            _cValor:=MCOM004Totais(aDados[nX][50],0,aDados[nX][43][nI][15],.F.)
			aAdd( _oProcess:oHtml:ValByName("Itens.VlrTot"		), _cValor)//aDados[nX][43][nI][08])

            _cValor:=MCOM004Totais(1,0,aDados[nX][43][nI][09],.F.,.T.)
			aAdd( _oProcess:oHtml:ValByName("Itens.ICMS"		), _cValor)

            _cValor:=MCOM004Totais(1,0,aDados[nX][43][nI][12],aDados[nX][50] <> 1)
			aAdd( _oProcess:oHtml:ValByName("Itens.VlrUc"), _cValor)//aDados[nX][43][nI][12])
         aAdd( _oProcess:oHtml:ValByName("Itens.DtUc"		), aDados[nX][43][nI][16])//aDados[nX][43][nI][16])

			aAdd( _oProcess:oHtml:ValByName("Itens.DtEmis"		), aDados[nX][43][nI][11])
			aAdd( _oProcess:oHtml:ValByName("Itens.SldAtFil"	), aDados[nX][43][nI][13])
			aAdd( _oProcess:oHtml:ValByName("Itens.SldAtEmp"	), aDados[nX][43][nI][14])
		Next nI
		
        _cTotais:=MCOM004Totais(aDados[nX][50],aDados[nX][51],aDados[nX][33],.F.)
		_oProcess:oHtml:ValByName("nTotMer"	, _cTotais)

        _cTotais:=MCOM004Totais(aDados[nX][50],aDados[nX][51],_nTotImp,.F.)
		_oProcess:oHtml:ValByName("nTotImp"	, _cTotais)

        _cTotais:=MCOM004Totais(aDados[nX][50],aDados[nX][51],aDados[nX][40],.F.)
		_oProcess:oHtml:ValByName("nTotDesc"	, _cTotais)

         _cTotais:=MCOM004Totais(aDados[nX][50],aDados[nX][51],aDados[nX][35],.F.)
		_oProcess:oHtml:ValByName("nIPI"	, _cTotais	)

         _cTotais:=MCOM004Totais(aDados[nX][50],aDados[nX][51],aDados[nX][36],.F.)
		_oProcess:oHtml:ValByName("nICMS"	, _cTotais	)

        _cTotais:=MCOM004Totais(aDados[nX][50],aDados[nX][51],_nOutImp,.F.)
	    _oProcess:oHtml:ValByName("nOutImp"	, _cTotais	)

         _cTotais:=MCOM004Totais(aDados[nX][50],aDados[nX][51],aDados[nX][37],.F.)
		_oProcess:oHtml:ValByName("nDesp"	, _cTotais)

         _cTotais:=MCOM004Totais(aDados[nX][50],aDados[nX][51],aDados[nX][38],.F.)
		_oProcess:oHtml:ValByName("nVlFrete", _cTotais	)

		FWLogMsg("WARN"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00440"/*cMsgId*/,"MCOM00440 - 15-IT_GRPLEITE =" +_cGrpLeite + ' /  _lGrpLeite =' + If(_lGrpLeite,".T.",".F.")+" / cFilant = "+cFilant+" / (_cAliasSC7)->C7_GRUPCOM = "+(_cAliasSC7)->C7_GRUPCOM/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
        If _lGrpLeite
	       _cTotais:=MCOM004Totais(1,0,nC7_L_EXEMG,aDados[nX][50] <> 1)
	       _oProcess:oHtml:ValByName("cGord","Vlr.Pag.MG")
	    Else
           _cTotais:=MCOM004Totais(aDados[nX][50],aDados[nX][51],aDados[nX][39],.F.)
	       _oProcess:oHtml:ValByName("cGord"  ,"Seguro")
	    EndIf
		_oProcess:oHtml:ValByName("nSeguro", _cTotais)

	    _cTotais:=MCOM004Totais(aDados[nX][50],aDados[nX][51],aDados[nX][34],.F.)
		_oProcess:oHtml:ValByName("nTotGer"	, _cTotais	)
	
		For nJ := 1 To Len(aDados[nX][44])
			nLinhas ++
			aAdd( _oProcess:oHtml:ValByName("Apr.Aprovador")	, aDados[nX][44][nJ][01])
			aAdd( _oProcess:oHtml:ValByName("Apr.DtAprov")		, aDados[nX][44][nJ][02])
			aAdd( _oProcess:oHtml:ValByName("Apr.HrAprov")		, aDados[nX][44][nJ][03])
			aAdd( _oProcess:oHtml:ValByName("Apr.ObsAprov")		, aDados[nX][44][nJ][04])
			aAdd( _oProcess:oHtml:ValByName("Apr.NivelAprov")	, aDados[nX][44][nJ][05])
		Next nJ
		
		_oProcess:oHtml:ValByName("nLinhas"	, StrZero(nLinhas, 2) 	)

	Next nX

	aDados	:= {}
	aItens	:= {}
	aAprov	:= {}

	//================================================================
	// Informamos o destinatário (aprovador) do email contendo o link.  
	//================================================================    
    _cFilAntJob := cFilAnt  
	cFilAnt:=_cFilial
    _cEmail:=UsrRetMail(_cUser)
    cFilAnt:=_cFilAntJob  

    FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00441"/*cMsgId*/,'MCOM00441 - E-mail: '+_cAssunto+' para: ' + _cEmail/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

	_oProcess:cTo := _cEmail//04 - "Questionamento "  - "IT_MAILWFC"

	//===============================
	// Informamos o assunto do email.  
	//===============================
	_oProcess:cSubject	:= FWHttpEncode(_cAssunto)

	_cRastrear    := "Envio para Aprovacao do PC " + SubStr(cFilPC,1,2) + " " + cNumPC//

	_cMailID	:= _oProcess:fProcessId
	_cTaskID	:= _oProcess:fTaskID
	RastreiaWF(_cMailID + '.' + _cTaskID , _oProcess:fProcCode, "1001", _cRastrear, "")

	//=======================================================
	// Iniciamos a tarefa e enviamos o email ao destinatário.
	//=======================================================
	_oProcess:Start()

EndIf
		
DBSelectArea(_cAliasSC7)
(_cAliasSC7)->(DBCloseArea())
		
FWRestArea(aArea)

Return  // MCOM004D

/*
===============================================================================================================================
Programa----------: M004Quest
Autor-------------: Darcio Ribeiro Sporl
Data da Criacao---: 29/01/2016
Descrição---------: Função criada para montar os questionamentos referente ao pedido de compras em questão.
Parametros--------: _cFilPC	- Filial do Pedido de Compras
				  : _cNumPC	- Número do Pedido de Compras
Retorno-----------: _cRet - Retorna a tabela HTML com os questionamentos referente ao pedido em questão
===============================================================================================================================
*/
User Function M004Quest(_cFilPC, _cNumPC, _cOrigem)
Local _cRet		:= ""
Local _cQryZY2	:= ""
Local _cNomUsr	:= ""
Default _cOrigem:=" "//"PC"

_cQryZY2 := "SELECT R_E_C_N_O_ ZY2_RECNO "
_cQryZY2 += "FROM " + RetSqlName("ZY2") + " "
_cQryZY2 += "WHERE ZY2_FILPED = '" + _cFilPC + "' "
_cQryZY2 += "  AND ZY2_PEDIDO = '" + _cNumPC + "' "
If ZY2->(FIELDPOS("ZY2_ORIGEM")) <> 0
   _cQryZY2 += "  AND ZY2_ORIGEM = '" + _cOrigem + "' "
EndIf
_cQryZY2 += "  AND D_E_L_E_T_ = ' ' "
_cQryZY2 += "ORDER BY ZY2_DATAM , ZY2_HORAM "

dbUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQryZY2 ) , "TRBZY2" , .T., .F. )
					
DBSelectArea("TRBZY2")
TRBZY2->(DBGoTop())
					
If !TRBZY2->(Eof())

	_cRet := "<table width='100%' class='bordasimples' cellpadding='0' cellspacing='0'> "
	_cRet += "	<tr width='100%'> "
	_cRet += "		<td align='center' BGCOLOR=#7f99b2 colspan='2'><font color= #F2FBEF  style='font-size: 16px; font-weight: bold;'>Questionamentos</font></td> "
	_cRet += "	</tr> "

	While !TRBZY2->(Eof())

		DBSelectArea("ZY2")
		DBGoTo(TRBZY2->ZY2_RECNO)

		_cNomUsr := MCOM004FullNome(ZY2->ZY2_USER,.T.) 

		_cRet += "	<tr> "
		If ZY2->ZY2_TIPO == "E"             //AZUL                      //VERMELHO
			_cRet += "		<td width='25%' BGCOLOR=#4169E1><font color= #FF0000  style='font-size: 16px; font-weight: bold;'>Mensagem de Erro na Rejeicao:</font></td> "
		ElseIf ZY2->ZY2_TIPO == "P"         //AZUL                      //AMARELO
			_cRet += "		<td width='25%' BGCOLOR=#4169E1><font color= #FFFF00  style='font-size: 16px; font-weight: bold;'>Pergunta de " + _cNomUsr + ":</font></td> "
		Else                       //AZUL                      //BRANCO
			_cRet += "		<td width='25%' BGCOLOR=#4169E1><font color= #F2FBEF  style='font-size: 16px; font-weight: bold;'>Resposta de " + _cNomUsr + ":</font></td> "
		EndIf
		_cRet += "		<td width='75%'>(" + DToC(ZY2->ZY2_DATAM) + " - " + ZY2->ZY2_HORAM + ") " + AllTrim(ZY2->ZY2_MENSAG) + "</td> "
		_cRet += "	</tr> "

		TRBZY2->(DBSkip())
		End

	_cRet += "</table> "
	_cRet += "<br> "

EndIf

//U_IT C ONOUT("Executado M004Quest() - _cFilial = " + _cFilPC + " - _cNumPC = "+_cNumPC+" RETORNO: "+_cRet)

DBSelectArea("TRBZY2")
TRBZY2->(DBCloseArea())

Return(_cRet)

/*
===============================================================================================================================
Programa----------: M004RET
Autor-------------: Darcio Ribeiro Sporl
Data da Criacao---: 29/01/2016
Descrição---------: Função criada para montar o retorno dos questionamentos referente ao pedido de compras em questão.
Parametros--------: _oProcess - Objeto do Processo de Questionamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function M004RET(_oProcess)
Local _cFilial		:= SubStr(_oProcess:oHtml:RetByName("cNomFil"),1,2)
Local _cNumPC		:= _oProcess:oHtml:RetByName("NumPC")
Local _cCRObs		:= AllTrim(Upper(_oProcess:oHtml:RetByName("CR_OBS")))
Local _cArqHtm		:= SubStr(_oProcess:oHtml:RetByName("WFMAILID"),3,Len(_oProcess:oHtml:RetByName("WFMAILID")))
Local _sDtLiber		:= DToS(Date())
Local _sDtAviso		:= DToS(Date())
Local _cHrLiber		:= SubStr(Time(),1,5)
Local _cSituacao	:= "B"
Local _cHtmlMode	:= "\Workflow\htm\pc_conc_resp.htm"////HTM CRIADO DIA 13/12/2021
Local cNivelAP		:= _oProcess:oHtml:RetByName("cNivelAP")
Local _cUser		:= _oProcess:oHtml:RetByName("cUser")
Local _cPergPai		:= _oProcess:oHtml:RetByName("cPergPai")
Local _cRastrear    := "Retorno do questionamento do PC " + _cFilial + " " + _cNumPC
Local _cQrySCR		:= ""
Local _aConfig		:= {}
Local _cEmlLog		:= ""
Local _cEmail		:= ""
Local _cAssunto		:= "9-Retorno do questionamento do PC " + _cFilial + " " + _cNumPC

_cQrySCR := "SELECT COUNT(*) CR_REGS "
_cQrySCR += "FROM " + RetSqlName("SCR") + " "
_cQrySCR += "WHERE CR_FILIAL = '" + _cFilial + "' "
_cQrySCR += "  AND CR_NUM = '" + _cNumPC + "' "
_cQrySCR += "  AND CR_TIPO = 'PC' "
_cQrySCR += "  AND CR_STATUS = '02' "
_cQrySCR += "  AND D_E_L_E_T_ = ' ' "

dbUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQrySCR ) , "TRBSCR" , .T., .F. )
					
DBSelectArea("TRBSCR")
TRBSCR->(DBGoTop())

If TRBSCR->CR_REGS > 0

	//=======================================================
	//Atualiza rastreamento de aprovação do pedido de compras
	//=======================================================
	RastreiaWF(_oProcess:fProcessId + '.' + _oProcess:fTaskID , _oProcess:fProcCode, "1002", _cRastrear , "")

	//==============================================================================================
	//Chama query para atualização do registro do pedido de compras, com as informações da aprovação
	//==============================================================================================
	MCOM004Q(9,"",_cFilial,_cNumPC,"1002","2","",_cSituacao,_cCRObs,_sDtLiber,_cHrLiber,"", _oProcess:fProcessId,cNivelAP,"R",_sDtAviso,_cUser,_cPergPai)

	//==================================================
	//Finalize a tarefa anterior para não ficar pendente
	//==================================================
	_oProcess:Finish()

	//========================================================================================
	//Faz a Copia do arquivo de aprovação para .old, e cria o arquivo de processo já concluído
	//========================================================================================
	If File("\workflow\emp01\MCOM004\" + _cArqHtm + ".htm")
	   If __CopyFile("\workflow\emp01\MCOM004\" + _cArqHtm + ".htm", "\workflow\emp01\MCOM004\" + _cArqHtm + ".old")
          If !Empty(_cHtmlMode) 
             If MCOM004CP("\workflow\emp01\MCOM004\" + _cArqHtm + ".htm",_cHtmlMode) //Recria _carqhtm com conteudo do modelo chtmlmode
				FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00442"/*cMsgId*/,"MCOM00442 - Copia do arquivo DE "+_cHtmlMode+" PARA \workflow\emp01\MCOM004\" + _cArqHtm + ".htm de conclusão efetuada com sucesso."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
  		     Else
				FWLogMsg("WARN"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00443"/*cMsgId*/,"MCOM00443 - Problema na Copia de arquivo DE "+_cHtmlMode+" PARA \workflow\emp01\MCOM004\" + _cArqHtm + ".htm"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
  		     EndIf
  		  EndIf
	   Else
		FWLogMsg("WARN"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00444"/*cMsgId*/,"MCOM00444 - Não foi possível renomear o arquivo \workflow\emp01\MCOM004\" + _cArqHtm + ".htm"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	   EndIf
	EndIf

	DBSelectArea("SCR")
	DBSetOrder(1)
	DBSeek(_cFilial + "PC" + _cNumPC)
	
	While !SCR->(Eof()) .And. SCR->CR_FILIAL == _cFilial .And. SCR->CR_TIPO == "PC" .And. SubStr(SCR->CR_NUM,1,6) == _cNumPC
		If SCR->CR_STATUS == "02"
			RecLock("SCR",.F.)
			Replace SCR->CR_I_WFID With " "
			MSUnLock()
			Exit
		EndIf
		SCR->(DBSkip())
	End

Else
	//==================================================
	//Finalize a tarefa anterior para não ficar pendente
	//==================================================
	_oProcess:Finish()

	_aConfig	:= U_ITCFGEML('')

	_cHtml := '<html> '
	_cHtml += '	<head> '
	_cHtml += '		<title>Questionamento Pedido de Compras</title> '
	_cHtml += '	</head> '
	_cHtml += '	<style Type="text/css"><!-- '
	_cHtml += '	table.bordasimples { border-collapse: collapse; } '
	_cHtml += '	table.bordasimples tr td { border:1px solid #777777; } '
	_cHtml += '	td.grupos	{ font-family:VERDANA; font-size:20px; V-align:middle; background-color: #C6E2FF; color:#000080; } '
	_cHtml += '	td.totais	{ font-family:VERDANA; font-size:18px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #0000FF; color:#FFFFFF; } '
	_cHtml += '	--></style> '
	_cHtml += '	<body> '
	_cHtml += '		<center> '
	_cHtml += '			<table width="050%" cellspacing="0" cellpadding="2" border="0"> '
	_cHtml += '				<tr> '
	_cHtml += '					<td width="02%" class="grupos"> '
	_cHtml += '						<center><img src="http://wf.italac.com.br:1026/workflow/htm/logo_novo.jpg" width="100px" height="030px"></center> '
	_cHtml += '					</td>
	_cHtml += '					<td width="98%" class="grupos"><center> '
	_cHtml += '						Aviso WF de Questionamento Pedido de Compras '
	_cHtml += '					</center></td> '
	_cHtml += '				</tr> '
	_cHtml += '				<tr> '
	_cHtml += '					<td class="totais" colspan="2"><center> '
	_cHtml += '						<b>O Processo do pedido de compras já foi encerrado, sendo assim, sua resposta não será enviada!</b></center> '
	_cHtml += '					</td> '
	_cHtml += '				</tr> '
	_cHtml += '				<tr> '
	_cHtml += '						<td class="grupos" colspan="2"><center>Filial: ' + _cFilial + ' - ' + AllTrim(FwFilialName(cEmpAnt, _cFilial,1)) + '</center></td> '
	_cHtml += '				</tr> '
	_cHtml += '				<tr> '                                                                          		
	_cHtml += '						<td class="grupos" colspan="2"><center>Pedido: ' + _cNumPC + '</center></td> '
	_cHtml += '				</tr> '
	_cHtml += '				</tr> '
	_cHtml += '			</table> '
	_cHtml += '		</center> '
	_cHtml += '	</body> '
	_cHtml += '</html> '

	_cEmail := AllTrim(UsrRetMail(_cUser))

	//====================================
	// Chama a função para envio do e-mail
	//====================================
	U_ITENVMAIL( "", _cEmail, "", _cEmail, _cAssunto, _cHtml, "", _aConfig[01], _aConfig[02], _aConfig[03], _aConfig[04], _aConfig[05], _aConfig[06], _aConfig[07], @_cEmlLog )

EndIf

Return

/*
===============================================================================================================================
Programa----------: MCOM004F
Autor-------------: Darcio Ribeiro Sporl
Data da Criacao---: 01/03/2017
Descrição---------: Função criada para fazer o reenvio do e-mail via botao na tela do pedido de compras
Parametros--------: _cFilial	- Filial do Pedido de Compras
				  : _cNumPC		- Número do Pedido de Compras
				  : cBloq		- Controla se o pedido foi bloqueado ou não
				  : cNivelAP	- Indica o nível do aprovador
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MCOM004F(_cFilial,_cNumPc,cBloq,_lWF)
Local _aArea			:= FWGetArea()
Local _sArqHTM			:= "\Workflow\htm\pc_comprador.htm" 
Local _cHostWF			:= SuperGetMV("IT_WFHOSTS",.F.,"http://wfteste.italac.com.br:4034/")
Local cLogo				:= _cHostWF + "htm/logo_novo.jpg"
Local cLogo1			:= _cHostWF + "htm/logo_novo.jpg"
Local cFiltro			:= ""
Local nLinhas			:= 0
Local cNomSol			:= ""
Local cNomApr			:= ""
Local cNomFor			:= ""
Local cCgcFor			:= ""
Local _cAssunto			:= "" 
Local _cEmail			:= ""
Local _cGrpLeite		:= AllTrim(SuperGetMV("IT_GRPLEIT",.F.,""))
Local _cQuery			:= ""
Local _cEmailGrpLeite	:= ""
Local cFilPC			:= SuperGetMV("IT_FILWFPC",.F.,"01")
Local _nRecno			:= SC7->(Recno())
Local _cConaPro			:= ""
Local cAplic			:= ""
Local cUrgen			:= ""
Local _cAliasSBZ	:= ""
Local _cAliasSBF	:= "" 
Local _cAliasSBE	:= "" 
Local _cTipo        := 'X'
Local _lTodos       := .T.
Private _lGrpLeite  := .F.//PARA TESTAR AS DECIMAIS na função MCOM004Totais() e "cTitulo"

FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00445"/*cMsgId*/,"MCOM00445-16-IT_GRPLEITE =" +_cGrpLeite + ' /  _lGrpLeite =' + If(_lGrpLeite,".T.",".F.")+" / cFilant = "+cFilant/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

Default _lWF:=.F.


If !_lWF .And. !(cFilAnt $ cFilPC)
	FWAlertWarning("A filial atual não está habilitada para reenvio de E-mail! Favor entrar em contato com o responsável!","MCOM00482")
	FWRestArea(_aArea)
	Return
EndIf

While  !_lWF .And. !SC7->(Eof()) .And. SC7->C7_FILIAL == _cFilial .And. SC7->C7_NUM == _cNumPc
	If SC7->C7_CONAPRO <> "L" .And. SC7->C7_CONAPRO <> "R"
		U_ITMsg("O pedido selecionado ainda não foi analisado pelo aprovador!",;
				"Reenvio de E-mail",;
				"Favor aguarde o envio de e-mail de aprovação/rejeição deste pedido!",1)
		FWRestArea(_aArea)
		Return
	ElseIf  SC7->C7_RESIDUO == "S" .And. SC7->C7_QUJE == 0
		FWAlertWarning("O e-mail referente ao pedido selecionado, não pode ser enviado, pois há item(s) com eliminação de residuo! Favor verIficar a situação do pedido de compras selecionado!","MCOM00484")
		FWRestArea(_aArea)
		Return
	EndIf
	SC7->(DBSkip())
End

SC7->(DBGoTo(_nRecno))

MaFisEnd()
M004FIniPC(_cNumPC,,,cFiltro,SubStr(_cFilial,1,2))

nTotal		:= 0
nTotIcms    := 0
nTotMerc	:= 0
nTotDesc	:= 0
nC7_L_EXEMG := 0
		
DBSelectArea("SM0")
DBSetOrder(1)
DBSeek(cEmpAnt + SubStr(_cFilial,1,2))
		
cNomFil	:= _cFilial + " - " + AllTrim(SM0->M0_FILIAL)
cEndFil	:= AllTrim(SM0->M0_ENDCOB)
cCepFil	:= SubStr(AllTrim(SM0->M0_CEPCOB),1,2) + "." + SubStr(AllTrim(SM0->M0_CEPCOB),3,3) + "-" + SubStr(AllTrim(SM0->M0_CEPCOB),6,3)
cCidFil	:= SubStr(AllTrim(SM0->M0_CIDCOB),1,50)
cEstFil	:= AllTrim(SM0->M0_ESTCOB)
cTelFil	:= '(' + SubStr(SM0->M0_TEL,4,2) + ')' + SubStr(SM0->M0_TEL,7,4) + '-' +SubStr(SM0->M0_TEL,11,4)
cFaxFil	:= '(' + SubStr(SM0->M0_FAX,4,2) + ')' + SubStr(SM0->M0_FAX,7,4) + '-' +SubStr(SM0->M0_FAX,11,4)
cCGCFil	:= formCPFCNPJ(SM0->M0_CGC)
cIEFil	:= AllTrim(SM0->M0_INSC)
		
nContrl	:= 0

If Type("_cAliasSC7") == "C" .And. select(_cAliasSC7) > 0

	(_cAliasSC7)->(DBCloseArea())
	
EndIf

_cAliasSC7 := GetNextAlias()

If _lWF 
   _cTipo:='X'
Else
   _cTipo:='B'

   nRet:=AVISO("Reenviando E-mail de WF" , "Enviar e-mail para TODOS e Usuario Logado ou SOMENTE para o Usuario Logado: "+;
               LOWER(AllTrim(UsrRetMail(RetCodUsr()))), {"TODOS","User Logado","CANCELAR"} ,2 ) 
   If nRet = 1
      _lTodos:=.T.
   ElseIf nRet = 2
      _lTodos:=.F.
   Else
     Return .F.
   EndIf

EndIf

cQry := "SELECT	C7_FILIAL, C7_NUM, C7_ITEM, C7_PRODUTO, C7_EMISSAO, C7_QUANT, C7_UM, C7_PRECO, C7_TOTAL, C7_FORNECE, C7_LOJA, C7_QTDREEM, C7_VLDESC, C7_DATPRF, C7_I_URGEN, C7_I_CMPDI, C7_I_NFORN, C7_CONAPRO, "
cQry += "			C7_DESCRI, C7_I_DESCD, C7_COND, C7_I_GCOM, C7_USER, C7_GRUPCOM, C7_NUMSC, C7_ITEMSC, C7_I_APLIC, C7_I_CDINV, C7_I_CMPDI, C7_VALIPI, C7_ICMSRET, C7_VALICM, C7_CC, C7_FRETE, C7_TPFRETE, C7_OBS, C7_FRETCON, C7_PICM,"
cQry += "			C7_I_CDTRA, C7_I_LJTRA, C7_I_TPFRT, C7_CONTATO, A2_COD, A2_LOJA, A2_NOME, A2_END, A2_MUN, A2_EST, A2_CEP, A2_DDD, A2_TEL, A2_FAX, A2_CGC, A2_INSCR, A2_CONTATO, C7_I_QTAPR, C7_MOEDA, C7_TXMOEDA, C7_I_CLAIM, C7_L_EXEMG "
cQry += "	FROM " + RetSqlName("SC7")+" SC7 "//%table:SC7% SC7
cQry += "	JOIN " + RetSqlName("SA2")+" SA2 ON A2_FILIAL = '"+xFilial("SA2")+"' AND A2_COD = C7_FORNECE AND A2_LOJA = C7_LOJA AND SA2.D_E_L_E_T_ = ' '  "
cQry += "	WHERE C7_FILIAL = '"+_cFilial+"' "
cQry += "	  AND C7_NUM = '"+_cNumPC+"' "    //%Exp:_cNumPC%
cQry += "	  AND C7_CONAPRO <> '"+_cTipo+"' "//%Exp:_cTipo%
cQry += "	  AND C7_APROV <> 'PENLIB' "
cQry += "	  AND C7_RESIDUO <> 'S' "
cQry += "	  AND SC7.D_E_L_E_T_ = ' ' "
cQry += "	ORDER BY C7_FILIAL, C7_NUM, C7_ITEM	  "

dbUseArea( .T. , "TOPCONN" , TcGenQry(,, cQry ) , _cAliasSC7 , .T., .F. )

lWFHTML	:= GetMv("MV_WFHTML")
PutMV("MV_WFHTML",.T.)

DBSelectArea(_cAliasSC7)
_nConta:=0
COUNT To _nConta

(_cAliasSC7)->(DBGoTop())
_cObs:=""
_cPObsProdAlter:="Saldo Produtos Alternativos:"+ENTERBR
If !(_cAliasSC7)->(Eof())
	// Inicialize a classe TWFProcess e assinale a variável objeto oProcess:
	_oProcess := TWFProcess():New("SendMail", "Envio de email no retorno" )
	_oProcess:NewTask("SendMail", _sArqHTM)

	While !(_cAliasSC7)->(Eof())

		//Validade se o PC é do Grupo de Leite
		_lGrpLeite:= IIf((_cAliasSC7)->C7_GRUPCOM $ _cGrpLeite ,.T.,.F.)//PARA TESTAR AS DECIMAIS na função MCOM004Totais() e "cTitulo"

		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00446"/*cMsgId*/,"MCOM00446-17-IT_GRPLEITE =" +_cGrpLeite + ' /  _lGrpLeite =' + If(_lGrpLeite,".T.",".F.")+" / cFilant = "+cFilant+" / (_cAliasSC7)->C7_GRUPCOM = "+(_cAliasSC7)->C7_GRUPCOM/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

		nContrl++
		If nContrl == 1        
					
			//=======================================
			//Dados do cabeçalho do pedido de compras
			//======================================= 
			_oProcess:oHtml:ValByName("cLogo"			, cLogo )
			_oProcess:oHtml:ValByName("cNomFil"			, cNomFil)
			_oProcess:oHtml:ValByName("cEndFil"			, cEndFil)
			_oProcess:oHtml:ValByName("cCepFil"			, cCepFil)
			_oProcess:oHtml:ValByName("cCidFil"			, cCidFil)
			_oProcess:oHtml:ValByName("cEstFil"			, cEstFil)
			_oProcess:oHtml:ValByName("cTelFil"			, cTelFil)
			_oProcess:oHtml:ValByName("cFaxFil"			, cFaxFil)
			_oProcess:oHtml:ValByName("cCGCFil"			, cCGCFil)
			_oProcess:oHtml:ValByName("cIEFil"			, cIEFil)
					
			cReavaliar := " "
			If MCOM004B( (_cAliasSC7)->C7_FILIAL,(_cAliasSC7)->C7_NUM, AllTrim((_cAliasSC7)->C7_I_QTAPR) )
   			   cReavaliar := "**REAVALIAR**"
			EndIf
			If (_cAliasSC7)->C7_I_CLAIM = '1'
				cReavaliar:=cReavaliar+" **CLAIM**"
			EndIf
			If (_cAliasSC7)->C7_I_APLIC == "I"
				cReavaliar:=cReavaliar+" **INVESTIMENTO**"
			EndIf
		    _oProcess:oHtml:ValByName("cReavaliar",cReavaliar)
            
			FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00447"/*cMsgId*/,"MCOM00447-18-IT_GRPLEITE =" +_cGrpLeite + ' /  _lGrpLeite =' + If(_lGrpLeite,".T.",".F.")+" / cFilant = "+cFilant+" / (_cAliasSC7)->C7_GRUPCOM = "+(_cAliasSC7)->C7_GRUPCOM/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
			If _lGrpLeite
			   _oProcess:oHtml:ValByName("cTitulo"," - DPTO. LEITE")
			Else
			   _oProcess:oHtml:ValByName("cTitulo","")
			EndIf

			_oProcess:oHtml:ValByName("NumPC"			, _cNumPC)

			If !Empty((_cAliasSC7)->C7_I_GCOM)
				cNomGes := MCOM004FullNome((_cAliasSC7)->C7_I_GCOM,.T.)
				_oProcess:oHtml:ValByName("cNomGes",cNomGes  )
			Else
				_oProcess:oHtml:ValByName("cNomGes"  		, "")
			EndIf
            
			If Empty(AllTrim(_cEmail))
			   _cMailAux:=AllTrim(UsrRetMail((_cAliasSC7)->C7_USER) )
               If !Empty(_cMailAux) 
				  _cEmail := _cMailAux+ ";"
		       EndIf  
			EndIf
			cQry := "SELECT C1_I_CDSOL, C1_I_CODAP, C1_NUM, C1_EMISSAO, C1_I_DTAPR, C1_I_OBSAP, C1_I_OBSSC "
			cQry += "FROM " + RetSqlName("SC1") + " "
			cQry += "WHERE C1_FILIAL = '" + (_cAliasSC7)->C7_FILIAL + "' "
			cQry += "  AND C1_NUM = '"    + (_cAliasSC7)->C7_NUMSC + "' "
			cQry += "  AND C1_ITEM = '"   + (_cAliasSC7)->C7_ITEMSC + "' "
			cQry += "  AND D_E_L_E_T_ = ' ' "

			dbUseArea( .T. , "TOPCONN" , TcGenQry(,, cQry ) , "TRBSC1" , .T., .F. )
					
			DBSelectArea("TRBSC1")
			TRBSC1->(DBGoTop())
					
			If AllTrim(TRBSC1->C1_I_OBSAP) == "EXECUTADO VIA WORKFLOW" .AND.;
			   AllTrim(TRBSC1->C1_I_OBSAP) == "SC Aprovada via acesso ao Protheus"
				cObsSc := ""
			Else
				cObsSc := TRBSC1->C1_I_OBSAP
			EndIf
			cObsScGen:=TRBSC1->C1_I_OBSSC

			If !TRBSC1->(Eof())

				If Empty(AllTrim(TRBSC1->C1_I_CDSOL))
					_oProcess:oHtml:ValByName("cNomSol"			, "")
					cNomSol := ""           
				Else
					_oProcess:oHtml:ValByName("cNomSol",AllTrim(Posicione("ZZ7",1,SubStr(_cFilial,1,2) + TRBSC1->C1_I_CDSOL, "ZZ7_NOME")))
					cNomSol := AllTrim(Posicione("ZZ7",1,SubStr(_cFilial,1,2) + TRBSC1->C1_I_CDSOL, "ZZ7_NOME"))
					_cMailAux:=AllTrim(UsrRetMail(TRBSC1->C1_I_CDSOL) )
                    If !Empty(_cMailAux) .And. !Upper(_cMailAux) $ Upper(_cEmail)  
					   _cEmail += _cMailAux+ ";"
					EndIf
				EndIf
						
				If Empty(TRBSC1->C1_I_CODAP)
					_oProcess:oHtml:ValByName("cNomApr","")
					cNomApr := ""
				Else
					_oProcess:oHtml:ValByName("cNomApr", AllTrim(Posicione("ZZ7",1,SubStr(_cFilial,1,2) + TRBSC1->C1_I_CODAP, "ZZ7_NOME")))
					cNomApr := AllTrim(Posicione("ZZ7",1,SubStr(_cFilial,1,2) + TRBSC1->C1_I_CODAP, "ZZ7_NOME"))
					_cMailAux:=AllTrim(UsrRetMail(TRBSC1->C1_I_CODAP))
                    If !Empty(_cMailAux) .And. !Upper(_cMailAux) $ Upper(_cEmail)
					   _cEmail += _cMailAux + ";"
					EndIf
				EndIf
				
					_oProcess:oHtml:ValByName("cnumSC",AllTrim(TRBSC1->C1_NUM))
					_oProcess:oHtml:ValByName("cdtinc",AllTrim(DToC(SToD(TRBSC1->C1_EMISSAO))))
					_oProcess:oHtml:ValByName("cdtapr",AllTrim(DToC(SToD(TRBSC1->C1_I_DTAPR))))
			Else
				_oProcess:oHtml:ValByName("cNomSol"			, "")
				_oProcess:oHtml:ValByName("cNomApr"			, "") 
				cNomSol := ""        
				cNomApr := ""
			EndIf

			DBSelectArea("TRBSC1")
			TRBSC1->(DBCloseArea())

			_oProcess:oHtml:ValByName("cDigiFor"		, MCOM004FullNome((_cAliasSC7)->C7_USER,.T.) )

			If (_cAliasSC7)->C7_I_APLIC == "C"
				cAplic := "Consumo"
			ElseIf (_cAliasSC7)->C7_I_APLIC == "I"
				cAplic := "Investimento - " + Posicione("ZZI",1,SubStr(_cFilial,1,2) + (_cAliasSC7)->C7_I_CDINV, "ZZI_DESINV")
			ElseIf (_cAliasSC7)->C7_I_APLIC == "M"
				cAplic := "Manutenção"
			ElseIf (_cAliasSC7)->C7_I_APLIC == "S"
				cAplic := "Serviço"
			EndIf
					
			_oProcess:oHtml:ValByName("cAplic" 		  	, cAplic)

			If (_cAliasSC7)->C7_I_URGEN == "S"
				cUrgen	:= "Sim"                  
			ElseIf (_cAliasSC7)->C7_I_URGEN == "F"
				cUrgen	:= "NF"
			Else
				cUrgen	:= "Não"
			EndIf

			_oProcess:oHtml:ValByName("cUrgen" 		, cUrgen)

			If (_cAliasSC7)->C7_I_CMPDI == "S"
				cCmpdi	:= "Sim"
			Else
				cCmpdi	:= "Não"
			EndIf

			If (_cAliasSC7)->C7_TPFRETE == "C"
				_oProcess:oHtml:ValByName("cFrete"	, "CIF")
				cTpFrete := "CIF"
			ElseIf (_cAliasSC7)->C7_TPFRETE == "F"
				_oProcess:oHtml:ValByName("cFrete"	, "FOB")
				cTpFrete := "FOB"
			ElseIf (_cAliasSC7)->C7_TPFRETE == "T"
				_oProcess:oHtml:ValByName("cFrete"	, "TERCEIROS")
				cTpFrete := "TERCEIROS"
			ElseIf (_cAliasSC7)->C7_TPFRETE == "S"
				_oProcess:oHtml:ValByName("cFrete"	, "SEM FRETE")
				cTpFrete := "SEM FRETE"
			EndIf

			_oProcess:oHtml:ValByName("cCompDir"  		, cCmpdi)

			_oProcess:oHtml:ValByName("dDtEmiss"  		, DToC(SToD((_cAliasSC7)->C7_EMISSAO)))
			cEmissao := DToC(SToD((_cAliasSC7)->C7_EMISSAO))

			If  !Empty(AllTrim((_cAliasSC7)->C7_CC))
				cCcusto	:= (_cAliasSC7)->C7_CC + " - " + AllTrim(Posicione("CTT",1,xFilial("CTT") + AllTrim((_cAliasSC7)->C7_CC), "CTT_DESC01"))
			Else
			    cCcusto := ""
			EndIf
			
			cNomFor	:= AllTrim((_cAliasSC7)->A2_NOME)
			cCgcFor	:= formCPFCNPJ((_cAliasSC7)->A2_CGC)

			_oProcess:oHtml:ValByName("cNomFor"			, AllTrim((_cAliasSC7)->A2_NOME) + " - " + (_cAliasSC7)->C7_FORNECE + "/" + (_cAliasSC7)->C7_LOJA)
			_oProcess:oHtml:ValByName("cEndFor"			, AllTrim((_cAliasSC7)->A2_END))
			_oProcess:oHtml:ValByName("cCEPFor"			, (_cAliasSC7)->A2_CEP)
			_oProcess:oHtml:ValByName("cCidFor"			, AllTrim((_cAliasSC7)->A2_MUN))
			_oProcess:oHtml:ValByName("cEstFor"			, (_cAliasSC7)->A2_EST)
			_oProcess:oHtml:ValByName("cTelFor"			, "(" + (_cAliasSC7)->A2_DDD + ") " + (_cAliasSC7)->A2_TEL)
			_oProcess:oHtml:ValByName("cFaxFor"			, "(" + (_cAliasSC7)->A2_DDD + ") " + (_cAliasSC7)->A2_FAX)
			_oProcess:oHtml:ValByName("cCGCFor"			, formCPFCNPJ((_cAliasSC7)->A2_CGC))
			_oProcess:oHtml:ValByName("cIEFor"	 		, (_cAliasSC7)->A2_INSCR)
			_oProcess:oHtml:ValByName("cContatFor"		, AllTrim((_cAliasSC7)->C7_CONTATO))
			_oProcess:oHtml:ValByName("cCondPG"	  		, AllTrim(Posicione("SE4",1,xFilial("SE4") + AllTrim((_cAliasSC7)->C7_COND),"E4_DESCRI")))

			cTransp := ""

			If !Empty((_cAliasSC7)->C7_I_CDTRA) .And. !Empty((_cAliasSC7)->C7_I_LJTRA)
				cTransp := "&nbsp;"
				cTransp += "Código: " + (_cAliasSC7)->C7_I_CDTRA + "&nbsp;Loja: " + (_cAliasSC7)->C7_I_LJTRA + "<br>"
				cTransp += "Razão Social: " + AllTrim(SubStr(Posicione("SA2", 1, xFilial("SA2")+(_cAliasSC7)->C7_I_CDTRA+(_cAliasSC7)->C7_I_LJTRA,"A2_NOME"),1,30)) + "<br>"
				cTransp += "Nome Fantasia: " + AllTrim(SubStr(Posicione("SA2", 1, xFilial("SA2")+(_cAliasSC7)->C7_I_CDTRA+(_cAliasSC7)->C7_I_LJTRA, "A2_NREDUZ"),1,30)) + "<br>"
				cTransp += "CNPJ: " + Transform(Posicione("SA2", 1, xFilial("SA2")+(_cAliasSC7)->C7_I_CDTRA+(_cAliasSC7)->C7_I_LJTRA, "A2_CGC"), PesqPict("SA2","A2_CGC")) + "&nbsp;&nbsp;&nbsp;"
				cTransp += "Ins. Estad.: " + Posicione("SA2", 1, xFilial("SA2")+(_cAliasSC7)->C7_I_CDTRA+(_cAliasSC7)->C7_I_LJTRA, "A2_INSCR") + "<br>"
				cTransp += "Bairro: " + AllTrim(SubStr(Posicione("SA2", 1, xFilial("SA2")+(_cAliasSC7)->C7_I_CDTRA+(_cAliasSC7)->C7_I_LJTRA, "A2_BAIRRO"),1,25)) + "<br>"
				cTransp += "Cidade: " + SubStr(Posicione("SA2", 1, xFilial("SA2")+(_cAliasSC7)->C7_I_CDTRA+(_cAliasSC7)->C7_I_LJTRA, "A2_MUN"),1,30) + "&nbsp;&nbsp;&nbsp;"
				cTransp += "Estado: " + Posicione("SA2", 1, xFilial("SA2")+(_cAliasSC7)->C7_I_CDTRA+(_cAliasSC7)->C7_I_LJTRA, "A2_EST") + "<br>"
				cTransp += "Telefone: (" + AllTrim(Posicione("SA2", 1, xFilial("SA2")+(_cAliasSC7)->C7_I_CDTRA+(_cAliasSC7)->C7_I_LJTRA, "A2_DDD")) + ")" + Posicione("SA2", 1, xFilial("SA2")+(_cAliasSC7)->C7_I_CDTRA+(_cAliasSC7)->C7_I_LJTRA, "A2_TEL") + "<br>"
				cTransp += "Contato: " + AllTrim(Posicione("SA2", 1, xFilial("SA2")+(_cAliasSC7)->C7_I_CDTRA+(_cAliasSC7)->C7_I_LJTRA, "A2_CONTATO")) + "<br>"
				cTransp += "<B> Obs. Frete: " + If((_cAliasSC7)->C7_I_TPFRT == "1","Entregar na Transportadora","Solicitar Coleta pela Transportadora" ) +"/B>
			EndIf
					
			_oProcess:oHtml:ValByName("cTransp"	  		, cTransp)
					
		EndIf
				
		aAdd( _oProcess:oHtml:ValByName("Itens.Item" 			), (_cAliasSC7)->C7_ITEM 												)
		aAdd( _oProcess:oHtml:ValByName("Itens.Prodpc" 			), (_cAliasSC7)->C7_PRODUTO								 				)
		If AllTrim((_cAliasSC7)->C7_I_DESCD) $ (_cAliasSC7)->C7_DESCRI
			aAdd( _oProcess:oHtml:ValByName("Itens.DesProd"		), AllTrim((_cAliasSC7)->C7_DESCRI)														)
		Else
			aAdd( _oProcess:oHtml:ValByName("Itens.DesProd"		), AllTrim((_cAliasSC7)->C7_DESCRI) + " " + AllTrim((_cAliasSC7)->C7_I_DESCD)			)
		EndIf
		aAdd( _oProcess:oHtml:ValByName("Itens.UM"				), (_cAliasSC7)->C7_UM													)
		aAdd( _oProcess:oHtml:ValByName("Itens.qtde"			), Transform((_cAliasSC7)->C7_QUANT, PesqPict("SC7","C7_QUANT"))		)

        _cValor:=MCOM004Totais((_cAliasSC7)->C7_MOEDA,0,(_cAliasSC7)->C7_PRECO,.F.)
		aAdd( _oProcess:oHtml:ValByName("Itens.VlrUni"			), _cValor)//Transform((_cAliasSC7)->C7_PRECO, "@E 999,999,999.999") 	      )

        _cValor:=MCOM004Totais((_cAliasSC7)->C7_MOEDA,0,(_cAliasSC7)->C7_VLDESC,.F.)
		aAdd( _oProcess:oHtml:ValByName("Itens.VlrDes"		   	), _cValor)//Transform((_cAliasSC7)->C7_VLDESC, PesqPict("SC7","C7_VLDESC"))  )

        _cValor:=MCOM004Totais((_cAliasSC7)->C7_MOEDA,0,((_cAliasSC7)->C7_TOTAL-(_cAliasSC7)->C7_VLDESC),.F.)
		aAdd( _oProcess:oHtml:ValByName("Itens.VlrTot"			), _cValor)//Transform((_cAliasSC7)->C7_TOTAL, PesqPict("SC7","C7_TOTAL")) 	  )

        _cValor:=MCOM004Totais(1,0,(_cAliasSC7)->C7_PICM,.F.,.T.)
		aAdd( _oProcess:oHtml:ValByName("Itens.ICMS"			), _cValor)

		aAdd( _oProcess:oHtml:ValByName("Itens.DtEmis"			), DToC(SToD((_cAliasSC7)->C7_DATPRF))									)

		If !Empty(_cAliasSBZ) .And. select(_cAliasSBZ) > 0
			(_cAliasSBZ)->(DBCloseArea())
		EndIf		

		_cAliasSBZ := GetNextAlias()
		MCOM004Q(6,_cAliasSBZ,(_cAliasSC7)->C7_FILIAL,"","","","","","","","",(_cAliasSC7)->C7_PRODUTO)
		nUlPrc := 0
      dDtUlPrc := CTOD("")
		If !(_cAliasSBZ)->(Eof())
		   If (_cAliasSC7)->C7_MOEDA = 1
		      nUlPrc  :=(_cAliasSBZ)->BZ_UPRC
            dDtUlPrc:=SToD((_cAliasSBZ)->BZ_UCOM)
		   ElseIf !Empty((_cAliasSBZ)->BZ_UCOM)
		      dDtUlPrc:=SToD((_cAliasSBZ)->BZ_UCOM)
		      nTxMoeda:=RecMoeda(dDtUlPrc,(_cAliasSC7)->C7_MOEDA)
		      nUlPrc  :=((_cAliasSBZ)->BZ_UPRC/nTxMoeda)
		   EndIf   
		EndIf
        _cValor:=MCOM004Totais((_cAliasSC7)->C7_MOEDA,0,nUlPrc,.F.)
		aAdd( _oProcess:oHtml:ValByName("Itens.VlrUc"),_cValor)
      aAdd( _oProcess:oHtml:ValByName("Itens.DtUc"),DToC(dDtUlPrc))
      
		If !Empty(_cAliasSBF) .And. select(_cAliasSBF) > 0
			(_cAliasSBF)->(DBCloseArea())
		EndIf
		_cProdAlt:=Posicione("SGI",1,(_cAliasSC7)->C7_FILIAL+(_cAliasSC7)->C7_PRODUTO,"GI_PRODALT")
		If !Empty(_cProdAlt)
		   _cAliasSBF := GetNextAlias()
		   MCOM004Q(7,_cAliasSBF,(_cAliasSC7)->C7_FILIAL,"","","","","","","","",_cProdAlt)
		   _cPObsProdAlter+="<b>"+AllTrim(_cProdAlt)+'-'+AllTrim(Posicione("SB1",1,xFilial("SB1")+_cProdAlt,"B1_DESC"))+;
		                    " = "+AllTrim(Transform((_cAliasSBF)->B2_QATU, PesqPict("SB2","B2_QATU")))+"</b>"+ENTERBR
		EndIf

		If !Empty(_cAliasSBF) .And. select(_cAliasSBF) > 0
			(_cAliasSBF)->(DBCloseArea())
		EndIf
				
		_cAliasSBF := GetNextAlias()

		BeginSql alias _cAliasSBF
			SELECT SUM(B2_QATU+B2_QNPT) B2_QATU 
			FROM %Table:SB2% SB2
			WHERE B2_FILIAL = %Exp:(_cAliasSC7)->C7_FILIAL%
			  AND B2_COD    = %Exp:(_cAliasSC7)->C7_PRODUTO%
			  AND B2_STATUS <> '2' 
			  AND SB2.%notDel%
		EndSql

		If !(_cAliasSBF)->(Eof())
			aAdd( _oProcess:oHtml:ValByName("Itens.SldAtFil"		), Transform((_cAliasSBF)->B2_QATU, PesqPict("SB2","B2_QATU"))		)
		Else
			aAdd( _oProcess:oHtml:ValByName("Itens.SldAtFil"		), Transform(0, PesqPict("SB2","B2_QATU"))		)
		EndIf
		
		If !Empty(_cAliasSBE)  .And. select(_cAliasSBE) > 0
			(_cAliasSBE)->(DBCloseArea())
		EndIf
			
		_cAliasSBE := GetNextAlias()

		BeginSql alias _cAliasSBE
			SELECT SUM(B2_QATU+B2_QNPT) B2_QATU 
			FROM %Table:SB2% SB2
			WHERE B2_COD    = %Exp:(_cAliasSC7)->C7_PRODUTO%
			  AND B2_STATUS <> '2' 
			  AND SB2.%notDel%
		EndSql

		If !(_cAliasSBE)->(Eof())
			aAdd( _oProcess:oHtml:ValByName("Itens.SldAtEmp"		), Transform((_cAliasSBE)->B2_QATU, PesqPict("SB2","B2_QATU"))		)
		Else
			aAdd( _oProcess:oHtml:ValByName("Itens.SldAtEmp"		), Transform(0, PesqPict("SB2","B2_QATU"))		)
		EndIf

		nTotDesc	+= (_cAliasSC7)->C7_VLDESC
        nC7_L_EXEMG += (_cAliasSC7)->C7_L_EXEMG 
		nTotal		+= (_cAliasSC7)->C7_TOTAL
		nTotIcms    += (_cAliasSC7)->C7_VALICM//MaFisRet(Val((_cAliasSC7)->C7_ITEM),"IT_VALICM")

		_cConaPro	:= (_cAliasSC7)->C7_CONAPRO

         If !Empty((_cAliasSC7)->C7_OBS) .And. !Upper(AllTrim((_cAliasSC7)->C7_OBS)) $ Upper(_cObs)
            _cObs+=AllTrim((_cAliasSC7)->C7_OBS)+" // "
         EndIf

		(_cAliasSC7)->(DBSkip())

	EndDo

    (_cAliasSC7)->(DBGoTop())
	nTotMerc	:= MaFisRet(,'NF_TOTAL')
	nTotIpi		:= MaFisRet(,'NF_VALIPI')
  //nTotIcms	:= MaFisRet(,'NF_VALICM')
	nTotDesp	:= MaFisRet(,'NF_DESPESA')
	_nTotImp    := nTotal+nTotIpi
    _nOutImp    := MaFisRet(,'NF_VALISS')+MaFisRet(,'NF_VALIRR')+MaFisRet(,'NF_VALINS')+MaFisRet(,'NF_VALSOL')
	
	If(_cAliasSC7)->C7_TPFRETE = "F"
	   nTotFrete:=(_cAliasSC7)->C7_FRETCON
	Else
	   nTotFrete:= MaFisRet(,'NF_FRETE')
	EndIf
	nTotSeguro	:= MaFisRet(,'NF_SEGURO')

    _cObs:=LEFT( _cObs, Len(_cObs)-4)
    If (_cAliasSC7)->C7_MOEDA <> 1
       _cObs:=MCOM004Moeda((_cAliasSC7)->C7_MOEDA,(_cAliasSC7)->C7_TXMOEDA,_cObs,(_cAliasSC7)->C7_EMISSAO)
    EndIf
	If "</b>" $ _cPObsProdAlter
	   If !Empty(_cObs) 
	      _cPObsProdAlter:=_cObs+ENTERBR+_cPObsProdAlter
	   EndIf
	Else
	   _cPObsProdAlter:=_cObs
	EndIf
    _oProcess:oHtml:ValByName("cObs", _cPObsProdAlter)//FORA While

    _cTotais:=MCOM004Totais((_cAliasSC7)->C7_MOEDA,(_cAliasSC7)->C7_TXMOEDA,nTotal,.F.)
	_oProcess:oHtml:ValByName("nTotMer"	, _cTotais	)

    _cTotais:=MCOM004Totais((_cAliasSC7)->C7_MOEDA,(_cAliasSC7)->C7_TXMOEDA,_nTotImp,.F.)
	_oProcess:oHtml:ValByName("nTotImp"	, _cTotais	)

    _cTotais:=MCOM004Totais((_cAliasSC7)->C7_MOEDA,(_cAliasSC7)->C7_TXMOEDA,nTotDesc,.F.)
	_oProcess:oHtml:ValByName("nTotDesc"	, _cTotais	)

    _cTotais:=MCOM004Totais((_cAliasSC7)->C7_MOEDA,(_cAliasSC7)->C7_TXMOEDA,nTotIpi,.F.)
	_oProcess:oHtml:ValByName("nIPI"	, _cTotais	)

    _cTotais:=MCOM004Totais((_cAliasSC7)->C7_MOEDA,(_cAliasSC7)->C7_TXMOEDA,nTotIcms,.F.)
	_oProcess:oHtml:ValByName("nICMS"	, _cTotais	)

    _cTotais:=MCOM004Totais((_cAliasSC7)->C7_MOEDA,(_cAliasSC7)->C7_TXMOEDA,_nOutImp,.F.)
	_oProcess:oHtml:ValByName("nOutImp"	, _cTotais	)

    _cTotais:=MCOM004Totais((_cAliasSC7)->C7_MOEDA,(_cAliasSC7)->C7_TXMOEDA,nTotDesp,.F.)
	_oProcess:oHtml:ValByName("nDesp"	, _cTotais)

    _cTotais:=MCOM004Totais((_cAliasSC7)->C7_MOEDA,(_cAliasSC7)->C7_TXMOEDA,nTotFrete,.F.)
	_oProcess:oHtml:ValByName("nVlFrete", _cTotais	)

	FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00448"/*cMsgId*/,"MCOM00448 - 19-IT_GRPLEITE =" +_cGrpLeite + ' /  _lGrpLeite =' + If(_lGrpLeite,".T.",".F.")+" / cFilant = "+cFilant+" / (_cAliasSC7)->C7_GRUPCOM = "+(_cAliasSC7)->C7_GRUPCOM/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
    If _lGrpLeite
	   _cTotais:=MCOM004Totais(1,0,nC7_L_EXEMG,(_cAliasSC7)->C7_TXMOEDA <> 1)
	   _oProcess:oHtml:ValByName("cGord","Vlr.Pag.MG")
	Else
       _cTotais:=MCOM004Totais((_cAliasSC7)->C7_MOEDA,(_cAliasSC7)->C7_TXMOEDA,nTotSeguro,.F.)
	   _oProcess:oHtml:ValByName("cGord"  ,"Seguro")
	EndIf
    _oProcess:oHtml:ValByName("nSeguro", _cTotais 	)

    _cTotais:=MCOM004Totais((_cAliasSC7)->C7_MOEDA,(_cAliasSC7)->C7_TXMOEDA,nTotMerc,.F.)
	_oProcess:oHtml:ValByName("nTotGer"	, _cTotais	)

	cQrySCR := "SELECT CR_USER, CR_APROV, CR_DATALIB, CR_I_HRAPR, CR_STATUS, R_E_C_N_O_ RECNUM , CR_NIVEL, CR_OBS "
	cQrySCR += "FROM " + RetSqlName("SCR") + " "
	cQrySCR += "WHERE CR_FILIAL = '" + SubStr(_cFilial,1,2) + "' "
	cQrySCR += "  AND CR_NUM = '" + _cNumPC + "' "
	cQrySCR += "  AND CR_TIPO = 'PC' "
	cQrySCR += "  AND D_E_L_E_T_ = ' ' "                        
	cQrySCR += "  ORDER BY CR_FILIAL, CR_NUM, CR_NIVEL "	

	dbUseArea( .T. , "TOPCONN" , TcGenQry(,, cQrySCR ) , "TRBSCR" , .T., .F. )
					
	DBSelectArea("TRBSCR")

    _nConta:=0
    COUNT To _nConta

    _aAprov:={}
	TRBSCR->(DBGoTop())
					
	If !TRBSCR->(Eof())
		While !TRBSCR->(Eof())
		
			nLinhas ++
			SCR->(DBGoTo(TRBSCR->RECNUM)) 

		    If aScan(_aAprov,TRBSCR->CR_USER+"|"+TRBSCR->CR_NIVEL ) = 0
		       aAdd(_aAprov,TRBSCR->CR_USER+"|"+TRBSCR->CR_NIVEL)
		    Else
			   FWLogMsg("WARN"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00449"/*cMsgId*/,"MCOM00449 - Aprovador repetido no SCR: "+TRBSCR->CR_USER+"-"+MCOM004FullNome(TRBSCR->CR_USER)+" Nivel: "+TRBSCR->CR_STATUS/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		       TRBSCR->(DBSkip())
		       Loop
		    EndIf
			If !_lWF
				_cDep := FWSFAllUsers({TRBSCR->CR_USER},{"USR_DEPTO"})[1][3]

				If Empty(_cDep)
					_cDep:="XXXXXXX"
				Endif
				
				If Upper(_cDep) <> "DIRECAO"//Não envia para diretoria
			       _cMailAux:=AllTrim(UsrRetMail(TRBSCR->CR_USER))
                   If !Empty(_cMailAux) .And. !Upper(_cMailAux) $ Upper(_cEmail)
			          _cEmail += _cMailAux+";"
			       EndIf
				EndIf
				FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00450"/*cMsgId*/,"MCOM00450 - Cargo: "+_cDep+' - E-mail: '+_cAssunto+' para: ' + _cEmail/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
			EndIf
			
		
			If Empty(TRBSCR->CR_APROV)
				aAdd( _oProcess:oHtml:ValByName("Apr.Aprovador")	, "")
			Else
				aAdd( _oProcess:oHtml:ValByName("Apr.Aprovador")	, "Sr.(a) " + MCOM004FullNome(TRBSCR->CR_USER,.T.) )
			EndIf
					
			If Empty(TRBSCR->CR_DATALIB)
				aAdd( _oProcess:oHtml:ValByName("Apr.DtAprov")		, DToC(SToD("//")))
			Else
				aAdd( _oProcess:oHtml:ValByName("Apr.DtAprov")		, DToC(SToD(TRBSCR->CR_DATALIB)))
			EndIf

			If Empty(TRBSCR->CR_I_HRAPR)
				aAdd( _oProcess:oHtml:ValByName("Apr.HrAprov")		, "")
			Else
				aAdd( _oProcess:oHtml:ValByName("Apr.HrAprov")		, TRBSCR->CR_I_HRAPR)
			EndIf

			If Empty(SCR->CR_OBS)
				aAdd( _oProcess:oHtml:ValByName("Apr.ObsAprov")		, "")
			Else
				aAdd( _oProcess:oHtml:ValByName("Apr.ObsAprov")		, AllTrim(SCR->CR_OBS))
			EndIf
					
			If Empty(TRBSCR->CR_STATUS)
				aAdd( _oProcess:oHtml:ValByName("Apr.NivelAprov")	, ""		)
			Else
				If TRBSCR->CR_STATUS == '01'
					cNivel := "Nível Bloqueado"
				ElseIf TRBSCR->CR_STATUS == '02'
					cNivel := "Aguardando Aprovação"
				ElseIf TRBSCR->CR_STATUS == '03'
					cNivel := "Nível Aprovado"
				ElseIf TRBSCR->CR_STATUS == '04'
					cNivel := "PC Bloqueado"
				EndIf

				aAdd( _oProcess:oHtml:ValByName("Apr.NivelAprov")	, cNivel		)
			EndIf

			TRBSCR->(DBSkip())
		End
	Else
		aAdd( _oProcess:oHtml:ValByName("Apr.Aprovador")	, "")
		aAdd( _oProcess:oHtml:ValByName("Apr.HrAprov")		, "")
		aAdd( _oProcess:oHtml:ValByName("Apr.DtAprov")		, "")
		aAdd( _oProcess:oHtml:ValByName("Apr.ObsAprov")		, "")
		aAdd( _oProcess:oHtml:ValByName("Apr.NivelAprov")	, "")
	EndIf

	_oProcess:oHtml:ValByName("nLinhas"	, StrZero(nLinhas, 2) 	)

	nContrl	:= 0

	DBSelectArea("TRBSCR")
	TRBSCR->(DBCloseArea())

	If _lGrpLeite

		_cQuery := "SELECT AJ_USER "
		_cQuery += "FROM " + RetSqlName("SAJ") + " "
		_cQuery += "WHERE AJ_FILIAL = ' ' "
		_cQuery += "  AND AJ_MSBLQL <> '1' "
		_cQuery += "  AND AJ_GRCOM IN " + FormatIn(_cGrpLeite,";") 
		_cQuery += "  AND D_E_L_E_T_ = ' ' "

		dbUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQuery ) , "TRBGRP" , .T., .F. )
						
		DBSelectArea("TRBGRP")
		TRBGRP->(DBGoTop())
			
		If !TRBGRP->(Eof())
			While !TRBGRP->(Eof())
			   _cMailAux:=AllTrim(UsrRetMail(TRBGRP->AJ_USER))
               If !Empty(_cMailAux) .And. !Upper(_cMailAux) $ Upper(_cEmail) .And. !Upper(_cMailAux) $ Upper(_cEmailGrpLeite)
                  _cEmailGrpLeite += _cMailAux+";" 
			   EndIf
			   TRBGRP->(DBSkip())
			End
		EndIf

		DBSelectArea("TRBGRP")
		TRBGRP->(DBCloseArea())   
		
		_cEmail += _cEmailGrpLeite 
	
    EndIf

	//=====================================
	// Populo as variáveis do template html
	//=====================================
	_oProcess:oHtml:ValByName("cLogo1"		, cLogo1 	)
	_oProcess:oHtml:ValByName("A_NOMSOL"	, cNomSol	)
	_oProcess:oHtml:ValByName("A_CUSTO"		, cCcusto	)
	_oProcess:oHtml:ValByName("A_URGEN"		, cUrgen	)
	_oProcess:oHtml:ValByName("A_INVES"		, cAplic	)
	_oProcess:oHtml:ValByName("A_CMPDI"		, cCmpdi	)
	_oProcess:oHtml:ValByName("A_FORNEC"	, AllTrim(cNomFor) + " - " + AllTrim(cCgcFor)	)

	cQryDT := "SELECT MIN(C7_DATPRF) C7_DATPRF "
	cQryDT += "FROM " + RetSqlName("SC7") + " "                                                           
	cQryDT += "WHERE C7_FILIAL = '" + SubStr(_cFilial,1,2) + "' "
	cQryDT += "  AND C7_NUM = '" + _cNumPC + "' "
  	cQryDT += "  AND C7_RESIDUO <> 'S' "	
	cQryDT += "  AND D_E_L_E_T_ = ' ' "
			
	dbUseArea(.T., "TOPCONN", TcGenQry(,,cQryDT), "TRBDT", .T., .F.)
			
	DBSelectArea("TRBDT")
	TRBDT->(DBGoTop())
			
	_oProcess:oHtml:ValByName("A_DTENTR"	, DToC(SToD(TRBDT->C7_DATPRF))		)

	DBSelectArea("TRBDT")
	TRBDT->(DBCloseArea())

    SC7->(DBSetOrder(1))
    SC7->(DBSeek(SubStr(_cFilial,1,2)+_cNumPC))

	_oProcess:oHtml:ValByName("A_VLTOTAL" , MCOM004Totais(SC7->C7_MOEDA,0,nTotMerc))//AllTrim(GETMV("MV_SIMB"+AllTrim(Str(SC7->C7_MOEDA))))+" "+Transform(nTotMerc,	PesqPict("SC7","C7_TOTAL")))
	_oProcess:oHtml:ValByName("A_OBSPC"   , _cObs    )//**PC_COMPRADOR.HTM*******
	_oProcess:oHtml:ValByName("A_OBSSC"   , cObsSc   )//PC_COMPRADOR.HTM
	_oProcess:oHtml:ValByName("A_OBSSCGEN", cObsScGen)//PC_COMPRADOR.HTM

	cReavaliar := ""		
	If (_cAliasSC7)->C7_I_CLAIM = '1'
	   cReavaliar:=cReavaliar+" **CLAIM**" 
	EndIf
	If (_cAliasSC7)->C7_I_APLIC == "I"
	   cReavaliar:=cReavaliar+" **INVESTIMENTO**"
	EndIf
	_oProcess:oHtml:ValByName("cReavaliar",cReavaliar)
    
	FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00451"/*cMsgId*/,"MCOM00451 - 21-IT_GRPLEITE =" +_cGrpLeite + ' /  _lGrpLeite =' + If(_lGrpLeite,".T.",".F.")+" / cFilant = "+cFilant+" / (_cAliasSC7)->C7_GRUPCOM = "+(_cAliasSC7)->C7_GRUPCOM/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	If _lGrpLeite
	   _oProcess:oHtml:ValByName("cTitulo"," - DPTO. LEITE")
	Else
	   _oProcess:oHtml:ValByName("cTitulo","")
	EndIf

	If _cConaPro == "L"
		_oProcess:oHtml:ValByName("cBloc"		, "Aprovado - [" + cBloq + "]")
	ElseIf (_cAliasSC7)->C7_CONAPRO == "R"
		_oProcess:oHtml:ValByName("cBloc"		, "Reprovado - [" + cBloq + "]")
	Else
		_oProcess:oHtml:ValByName("cBloc"		, "Respondido" )
	EndIf

    If _lWF 
	   _cAssunto := "8-Retorno WF do PC Filial " + _cFilial + " Número: " + SubStr(_cNumPc,1,6) + " - Respondido"
    Else
	   _cAssunto := "8-Retorno WF do PC Filial " + _cFilial + " Número: " + Substr(_cNumPc,1,6) + " - " + IIf(_cConaPro == "L", "Aprovado - [" + cBloq + "]", "Reprovado - [" + cBloq + "]")
    EndIf
    
	_oProcess:cSubject := FWHttpEncode(_cAssunto) 

	//=========================
	//Dados dos questionamentos
	//=========================
	If !Empty(U_M004Quest(_cFilial, AllTrim(_cNumPc)))
	   _oProcess:oHtml:ValByName("cQuest", U_M004Quest(_cFilial, AllTrim(_cNumPc)) )
	Else
	   _oProcess:oHtml:ValByName("cQuest", "" )
	EndIf

    If _lWF 
 	   _oProcess:cTo := _cEmail//05 - "Retorno WF do PC Filial "  - "IT_MAILWFC"
    Else
       If _lTodos
         _cEmail+=";"+Lower(AllTrim(UsrRetMail(RetCodUsr())))
       Else
         _cEmail:=Lower(AllTrim(UsrRetMail(RetCodUsr())))
       EndIf
 	   _oProcess:cTo := _cEmail//05 - "Retorno WF do PC Filial "  - "IT_MAILWFC"
    
    EndIf
              
	_oProcess:Start()

	_oProcess:Finish()

EndIf

PutMV("MV_WFHTML",.T.)

FWRestArea(_aArea)

If !_lWF 
  _cEmail:=StrTran(_cEmail,";;",CHR(13)+CHR(10))
  _cEmail:=StrTran(_cEmail,",,",CHR(13)+CHR(10))
  _cEmail:=StrTran(_cEmail,";",CHR(13)+CHR(10))
  _cEmail:=StrTran(_cEmail,",",CHR(13)+CHR(10))
   U_ITMsg("Email's enviados com sucesso para... Ver botão [Mais Detalhes]","Atenção!",'Assunto: '+_cAssunto,2,,,,,,{|| AVISO("E-MAIL'S",_cEmail,{"Fechar"},3) } )
EndIf

Return

/*
===============================================================================================================================
Programa----------: MCOM004Moeda()
Autor-------------: Alex Wallauer
Data da Criacao---: 23/10/2018
===============================================================================================================================
Descrição---------: RETORNA A DESCRIÇÃO DA MOEDA NA OBS
===============================================================================================================================
Parametros--------: _nMoedaSC7,_nTxMoeSC7,_cMObs
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MCOM004Moeda(_nMoedaSC7,_nTxMoeSC7,_cMObs,_nDtMoeSC7)//,nUlPrc)

_cMObs:=AllTrim(_cMObs)+"<br>"+"VALORES DO PEDIDO EM "+Upper(AllTrim(GETMV("MV_MOEDA"+AllTrim(Str(_nMoedaSC7)))))+;
                             ", TAXA: "+Transform(_nTxMoeSC7, PesqPict("SC7","C7_TXMOEDA"))+;
                             ", DATA TX: "+DToC(SToD(_nDtMoeSC7))//+;

Return _cMObs

/*
===============================================================================================================================
Programa----------: MCOM004Totais()
Autor-------------: Alex Wallauer
Data da Criacao---: 23/10/2018
Descrição---------: RETORNA A DESCRIÇÃO DAS MOEDAS
Parametros--------: _nMoedaSC7,_nTxMoeSC7
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MCOM004Totais(_nMoedaSC7,_nTxMoeSC7,nTotMerc,_lSimbolo,_lPerc)
Local _cPict:=PesqPict("SC7","C7_TOTAL")
Static _aAllmoedas:= {}
Default _lSimbolo:=.T.
Default _lPerc:=.F.
If _lPerc
    Return AllTrim(Transform( nTotMerc ,"@E 999,99"))+"%"//PERCENTUAL
EndIf
If Type("_lGrpLeite") <> "L"
   _lGrpLeite:=.F.
EndIf
If _lGrpLeite
   _cPict:="@E 999,999,999.9999"
EndIf
If Len(_aAllmoedas) = 0 .And. _nMoedaSC7 > 1
   aAdd(_aAllmoedas, AllTrim(GETMV("MV_SIMB1")) )
   aAdd(_aAllmoedas, AllTrim(GETMV("MV_SIMB2")) )
   aAdd(_aAllmoedas, AllTrim(GETMV("MV_SIMB3")) )
   aAdd(_aAllmoedas, AllTrim(GETMV("MV_SIMB4")) )
   aAdd(_aAllmoedas, AllTrim(GETMV("MV_SIMB5")) )
EndIf   

If _nMoedaSC7 > 1 .And. _nMoedaSC7 < 6
   If _nTxMoeSC7 <> 0// NA MOEDA / EM REAL
      Return  _aAllmoedas[_nMoedaSC7]+" "+AllTrim(Transform(nTotMerc,_cPict))+" / R$ "+AllTrim(Transform( (nTotMerc*_nTxMoeSC7) ,_cPict))
   Else//SÓ NA MOEDA
       If ValType(nTotMerc) = "N"
          Return _aAllmoedas[_nMoedaSC7]+" "+AllTrim(Transform(nTotMerc,_cPict))// NA MOEDA
       Else
          Return _aAllmoedas[_nMoedaSC7]+" "+AllTrim(nTotMerc)// NA MOEDA
       EndIf   
   EndIf   
Else//EM REAL
   If ValType(nTotMerc) = "N"
      Return If(_lSimbolo,"R$ ","")+AllTrim(Transform( nTotMerc ,_cPict))//EM REAL
   Else
      Return If(_lSimbolo,"R$ ","")+AllTrim(nTotMerc)
   EndIf   
EndIf

Return

/*
===============================================================================================================================
Programa----------: MCOM004FullNome()
Autor-------------: Alex Wallauer
Data da Criacao---: 29/10/2018
Descrição---------: RETORNA o nome complerto do usuario
Parametros--------: _cCodUser,lPrimeiroNome
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MCOM004FullNome(_cCodUser,lPrimeiroNome)

Local nPos:=0
Static _aAllusers := {}
Default lPrimeiroNome := .F.
If Len(_aAllusers) = 0
   _aAllusers := FWSFALLUSERS()
EndIf   

If (nPos:=aScan(_aAllusers, { |A| AllTrim(A[2]) == AllTrim(_cCodUser) })) <> 0
   If lPrimeiroNome
      Return SubStr(_aAllusers[nPos][4], 1, At(" ", _aAllusers[nPos][4])-1)
   Else
      Return _aAllusers[nPos][4]
   EndIf      
Else
   FWLogMsg("WARN"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00452"/*cMsgId*/,'MCOM00452 - FullNome-Usuario NÃO encontrado para retornar o e-mail: '+_cCodUser/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
   Return ""   
EndIf

Return

/*
===============================================================================================================================
Programa----------: MCOM004CP()
Autor-------------: Josué Danich Prestes
Data da Criacao---: 06/03/2019
Descrição---------: Recria arquivo com conteúdo de outro arquivo
Parametros--------: _carqori - Arquivo de origem
					_carqsrc - Arquivo com conteúdo a ser utilizado
Retorno-----------: _lRet - lógico indicando se completou o processo
===============================================================================================================================
*/
Static Function MCOM004CP(_carqori,_carqsrc)

Local _lRet := .T.
Local _cconteudo := MemoRead( _carqsrc)

	If Empty(_cconteudo)

		_lRet := .F.

	EndIf

	If _lRet .And. FERASE(_carqori)==0 
	
		_nHandle := FCreate(_carqori) 

		If _nHandle > 0

			FClose(_nHandle)
			_lRet := memowrite(_carqori,_cconteudo)

		Else

			_lRet := .F.

		EndIf

	Else

		_lRet := .F.

	EndIf 
	
Return _lRet

/*
===============================================================================================================================
Programa----------: MC004OBS
Autor-------------: Jonathan Torioni
Data da Criacao---: 03/07/2020
===============================================================================================================================
Descrição---------: Busca a informação da Observação do aprovador na Solicitação de Compras
===============================================================================================================================
Parametros--------: cFilc7 - Filial da SC7 -> C7_FILIAL
					cNumSc - Número da Solicitação de compra -> C7_NUMSC
					cItemSc- Item do pedido de compra -> C7_ITEMSC
===============================================================================================================================
Retorno-----------: _lRet - lógico indicando se completou o processo
===============================================================================================================================
*/
Static Function MC004OBS(cFilc7,cNumSc,cItemSc)
	Local cQry	:= ""
	Local cNwAlias := GetNextAlias()

	cQry := "SELECT C1_I_OBSAP "
	cQry += "FROM " + RetSqlName("SC1") + " "
	cQry += "WHERE C1_FILIAL = '" + cFilc7 + "' "
	cQry += "  AND C1_NUM = '"    + cNumSc + "' "
	cQry += "  AND C1_ITEM = '"   + cItemSc + "' "
	cQry += "  AND D_E_L_E_T_ = ' ' "

	dbUseArea( .T. , "TOPCONN" , TcGenQry(,, cQry ) , cNwAlias , .T., .F. )


Return (cNwAlias)->C1_I_OBSAP

/*
===============================================================================================================================
Programa----------: MCOM04Email
Autor-------------: Alex Wallauer 
Data da Criacao---: 26/02/2021
Descrição---------: Rotina responsavel pelo envio de e-mails de pedido de compras - Chamado 35739
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MCOM04Email()//U_MCOM04Email
Local _aTables		:= {"SCR","SC1","SC7","SD1","ZZ7","ZZ8","ZZI","CTT","ZZL","ZP1"}
Local _lCriaAmb		:= .F.
Local _cAliasSC7	:= ""
Local lWFHTML		:= .T.
Private _cHostWF	:= ""
Private _dDtIni		:= ""

//Verifica a necessidade de criar um ambiente, caso nao esteja 
//criado anteriormente um ambiente, pois ocorrera erro.        
If Select("SX3") <= 0
	_lCriaAmb:= .T.
EndIf                           
             
If _lCriaAmb              

	//Nao consome licensas
	RPCSetType(3)

	//seta o ambiente com a empresa 01 filial 01   	 
	RpcSetEnv("01","01",,,,"SCHEDULE_WF_PEDIDOS",_aTables)

    DBSelectArea("ZP1")
EndIf 

//grava log de uso

PutMV("MV_WFHTML",.T.)

_cHostWF   := SuperGetMV("IT_WFHOSTS",.F.,"http://wfteste.italac.com.br:4034/")
_dDtIni	   := DToS(SuperGetMV("IT_WFDTINI",.F.,"26/11/2025"))
lWFHTML	   := GetMv("MV_WFHTML")
_cAliasSC7 := GetNextAlias()

MCOM004Q(0,_cAliasSC7,"","","","","","","","","","") // C7_I_ENVEM = 'S'

DBSelectArea(_cAliasSC7)
_nTot:=0
COUNT To _nTot
(_cAliasSC7)->(DBGoTop())
SC7->(DBSetOrder(1))

While  !(_cAliasSC7)->(Eof())
   If SC7->(DBSeek((_cAliasSC7)->C7_FILIAL+(_cAliasSC7)->C7_NUM))

	  MCOM004A(SC7->C7_FILIAL,SC7->C7_NUM,SC7->C7_I_STAEM,"SCHEDULE")
   
   EndIf
   (_cAliasSC7)->(DBSkip())
EndDo

DBSelectArea(_cAliasSC7)
(_cAliasSC7)->(DBCloseArea())          

PutMV("MV_WFHTML",.T.)

If _lCriaAmb
	
	//Limpa o ambiente, liberando a licença e fechando as conexoes
	RpcClearEnv()  
	
EndIf

Return        
/*
===============================================================================================================================
Programa--------: MCOM4Trans()
Autor-----------: Alex Wallauer
Data da Criacao-: 07/01/2022
Descrição-------: Transfere o produto de leite a granel de volta
Parametros------: _cChave: _cFilial + _cNumPC
Retorno---------: .T. OU .F.
===============================================================================================================================*/
Static Function MCOM4Trans(_cChave)
Local _aTransferecias:={}
Local _nOpcAuto   := 3 // Indica qual tipo de ação será tomada (Inclusão/Exclusão)
Local _cOriLocal  := "03"
Local _cDesLocal  := "01"//armazem usado para bloquear (processo)
Local _cLOriCodProd:= AVKEY(SuperGetMV("IT_LTMP",.F.,'08000000034'),"D3_COD")//LEITE
Local _cLDestprod  := SuperGetMV("IT_LTGRN",.F.,'08000000062')//LEITE
Local _cCOriCodProd:= AVKEY(SuperGetMV("IT_CRMP",.F.,'08000000007'),"D3_COD")//CREME
Local _cCDestprod  := SuperGetMV("IT_CRGRN",.F.,'08000000064;08000000063')//CREME
Local _cDesCodProd := ""
Local _nQtde :=0
Local dDataVl:=CTOD("")
Local _nX//,B
Local _lTrocaLeite:=!(cFilAnt $ SuperGetMV('IT_FLNGRA',.F.,'10')) //Filiais que não fazem transferência de leite a granel
Local _lTrocaCreme:=!(cFilAnt $ SuperGetMV('IT_CRNGRA',.F.,'40')) //Filiais que não fazem transferência de creme a granel
Local _aRecSB2 :={}
Local _aRecTSB2:={}
Local _cFilVld34 := SuperGetMV('IT_FILVLD3',.F.,'')

FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00453"/*cMsgId*/,"MCOM00453 - MCOM4Trans - INICIO - PV: "+_cChave/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

_cMensagem:=""//INICIADA ANTES DA CHAMADA DA FUNCAO

SF4->(DBSetOrder(1))
SB1->(DBSetOrder(1))

SD1->(DBSetOrder(22)) //D1_FILIAL+D1_PEDIDO+D1_ITEMPC
If !SD1->(DBSeek(_cChave)) //.OR. SD1->D1_TIPO <> 'N'
   FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00454"/*cMsgId*/,"MCOM00454 - MCOM4Trans- Nao achou - _cChave: "+_cChave/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
   Return .F.
EndIf

aAuto:={""}
While SD1->(!Eof()) .And. _cChave == SD1->(D1_FILIAL+D1_PEDIDO)

    aAuto:={""}
	If SD1->D1_TIPO <> 'N' //!SF4->(DBSeek(SD1->D1_FILIAL + SD1->D1_TES)) .Or. SF4->F4_ESTOQUE <> "S" .Or. SD1->D1_TIPO <> 'N"
	   FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00455"/*cMsgId*/,"MCOM00455 - MCOM4Trans- SD1->D1_TIPO = " +SD1->D1_TIPO+" / SD1->D1_FILIAL+SD1->D1_DOC+SD1->D1_SERIE+SD1->D1_FORNECE+SD1->D1_LOJA: "+SD1->D1_FILIAL+SD1->D1_DOC+SD1->D1_SERIE+SD1->D1_FORNECE+SD1->D1_LOJA/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	   aAuto[1]:="IGNOROU NF MOTIVO: SD1->D1_TIPO = " +SD1->D1_TIPO+" / SD1->D1_FILIAL+SD1->D1_DOC+SD1->D1_SERIE+SD1->D1_FORNECE+SD1->D1_LOJA: "+SD1->D1_FILIAL+SD1->D1_DOC+SD1->D1_SERIE+SD1->D1_FORNECE+SD1->D1_LOJA
	    SD1->(DBSkip())
		Loop
	EndIf
	
	_cOriLocal   := SD1->D1_LOCAL
	_cDesCodProd := SD1->D1_COD
    _cOriCodProd := SD1->D1_COD
	If AllTrim(_cDesCodProd) $ _cLDestprod .And. _lTrocaLeite
	   _cOriCodProd := _cLOriCodProd
	   _cDesCodProd := _cLOriCodProd
	ElseIf AllTrim(_cDesCodProd) $ _cCDestprod .And. _lTrocaCreme
	   _cOriCodProd := _cCOriCodProd
	   _cDesCodProd := _cCOriCodProd
	EndIf

    FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00456"/*cMsgId*/,'MCOM00456 - MCOM4Trans-TRANSFERENCIA DE ' +_cOriLocal+ " "+ _cOriCodProd+" PARA "+_cDesLocal+" "+_cDesCodProd+" SD1->D1_QUANT = "+CVALTOCHAR(SD1->D1_QUANT)/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	If _cOriCodProd == _cDesCodProd .And. _cOriLocal == _cDesLocal
	   aAuto[1]:='TRANSFERENCIA DE ' +_cOriLocal+ " "+ _cOriCodProd+" PARA "+_cDesLocal+" "+_cDesCodProd+" TUDO IGUAL"
	   SD1->(DBSkip())
	   Loop
	EndIf

	If SB2->(DBSeek(SD1->D1_FILIAL+_cOriCodProd+_cDesLocal)) 
	   If SB2->B2_BLOQUEI =  "4"
  	      SB2->(RecLock("SB2",.F.))
  	      SB2->B2_BLOQUEI :=  ""
  	      SB2->(MSUnLock())
	      aAdd(_aRecSB2,SB2->(RECNO()) )  
		  FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00457"/*cMsgId*/,'MCOM00457 - MCOM4Trans-Desbloqueou SC7->C7_FILIAL+SC7->C7_PRODUTO+_cDesLocal = '+SC7->C7_FILIAL+SC7->C7_PRODUTO+_cDesLocal/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	   EndIf
	   aAdd(_aRecTSB2,SB2->(RECNO()) )  
	EndIf

    SF1->(DBSetOrder(1))
    If SF1->(DBSeek(SD1->D1_FILIAL+SD1->D1_DOC+SD1->D1_SERIE+SD1->D1_FORNECE+SD1->D1_LOJA) )
    
       SE2->(DBSetOrder(6)) // E2_FILIAL+E2_FORNECE+E2_LOJA+E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO
       If SE2->(DBSeek(SF1->F1_FILIAL+SF1->F1_FORNECE+SF1->F1_LOJA+SF1->F1_SERIE+SF1->F1_DOC))
          SE2->(RecLock("SE2", .F.))
          SE2->E2_MSBLQL := "1" 
          SE2->(MSUnLock())
		  FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00458"/*cMsgId*/,'MCOM00458 - MCOM4Trans-Bloqueou Titulo SF1->F1_FILIAL+SF1->F1_FORNECE+SF1->F1_LOJA+SF1->F1_SERIE+SF1->F1_DOC= '+SF1->F1_FILIAL+SF1->F1_FORNECE+SF1->F1_LOJA+SF1->F1_SERIE+SF1->F1_DOC/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
       EndIf
       SE2->(DBSetOrder(1)) 
    
    EndIf

	//****** Cabecalho a Incluir ***
	cDoc:=GetSxENum("SD3","D3_DOC",1)
	aAuto:={}
	aAdd(aAuto,{cDoc,dDataBase})  //Cabecalho
	//****** Cabecalho a Incluir ***

	//****** Itens a Incluir  ******
    SB1->(DBSeek(xFilial()+_cOriCodProd)) // ORIGEM ************
    _nQtde:=SD1->D1_QUANT
    aItem:={}
	aAdd(aItem,_cOriCodProd)//D3_COD
	aAdd(aItem,SB1->B1_DESC)//D3_DESCRI
	aAdd(aItem,SB1->B1_UM)  //D3_UM
	aAdd(aItem,_cOriLocal)  //D3_LOCAL
	aAdd(aItem,"")		    //D3_LOCALIZ //Endereço Orig
    
	SB1->(DBSeek(xFilial()+_cDesCodProd)) // DESTINO ***************
	aAdd(aItem,_cDesCodProd)//D3_COD
	aAdd(aItem,SB1->B1_DESC)//D3_DESCRI
	aAdd(aItem,SB1->B1_UM)  //D3_UM
	aAdd(aItem,_cDesLocal)  //D3_LOCAL
	aAdd(aItem,"")		    //D3_LOCALIZ //Endereço Dest
	aAdd(aItem,"")          //D3_NUMSERI
	aAdd(aItem,"")  	    //D3_LOTECTL
	aAdd(aItem,"")         	//D3_NUMLOTE
	aAdd(aItem,dDataVl)	    //D3_DTVALID
	aAdd(aItem,0)		    //D3_POTENCI
	aAdd(aItem,_nQtde)      //D3_QUANT
	aAdd(aItem,0)		    //D3_QTSEGUM
	aAdd(aItem,"")          //D3_ESTORNO
	aAdd(aItem,"")      	//D3_NUMSEQ
	aAdd(aItem,"")  	    //D3_LOTECTL
	aAdd(aItem,dDataVl)	    //D3_DTVALID
	aAdd(aItem,"")	 	    //D3_ITEMGRD
	aAdd(aItem,"")	 	    //D3_OBSERVA  //Observação C        30
	//Campos Customizados:                                       
	aAdd(aItem,"BLOQUEIO DO PC: "+_cChave)	 	    //D3_I_OBS    //Observação C       254
    If ! cFilant $ _cFilVld34 // Este campo não deve estar disponível para filiais de validação do armazém 34 (Descarte).
	   aAdd(aItem,"")	 	              //D3_I_TPTRS  // Mot.Tran.R C  1
	   aAdd(aItem,"")	 	              //D3_I_DSCTM  // Des.Mot.Tr C  1
    EndIf 
    If cFilant $ _cFilVld34 // Este campo não deve estar disponível para filiais de validação do armazém 34 (Descarte).
	   aAdd(aItem,"")	 	          //D3_I_MOTTR  // Mot.Tran.R C         8 
	   aAdd(aItem,"")	 	          //D3_I_DSCMT  // Des.Mot.Tr C        40 
	   aAdd(aItem,"")	 	          //D3_I_SETOR  // Origem Trf C        40 
	   aAdd(aItem,"")	 	          //D3_I_DESTI  // Destino    C        40 
    EndIf 
	//****** Itens a Incluir  ******

	aAdd(aAuto,aItem)
		
	aAdd(_aTransferecias,aAuto)//Tem que ser um MSExecAuto para cada linha pq ele não deixa em uma mesma inclusao colocar itens origem/destino repetidos
		
	SD1->(DBSkip())
EndDo

Begin Sequence
If Empty(_aTransferecias)
// _cMensagem PARA O E-MAIL
   _cMensagem+="Nao foi possivel Transferir o estoque do Pedido P/ BLOQUEIO: "+_cChave+", MOTIVO: "+aAuto[1]
   FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00459"/*cMsgId*/,'MCOM00459 - MCOM4Trans-_cMensagem = ' +_cMensagem/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
   Break
EndIf

BEGIN TRANSACTION

For _nX := 1 To Len(_aTransferecias)
	
	lMsErroAuto := .F.
	_cMenITmsgLog:=""//Variavel preenchida na User Function ITmsg()
	_cChavePC:=_cChave//Usa essa variavel _cChavePC no rdmake MA261D3 para gravar no campo D3_CHAVEF1

	MSExecAuto({|x,y| MATA261(x,y)},_aTransferecias[_nX],_nOpcAuto)
	
	If lMsErroAuto
		If __lSx8
			RollBackSX8()
		EndIf
		
        _cMensagem+="Não foi possivel Transferir/Bloquear o estoque dos itens, faça o Transferencia/Bloqueio manualmente por favor, Erros: ["+_cMenITmsgLog+"] ["+MostraErro(Upper(GetSrvProfString("STARTPATH","")),"MCOM004.LOG")+"] "
		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00460"/*cMsgId*/,'MCOM00460 - MCOM4Trans-_cMensagem = ' +_cMensagem/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
        Exit
	Else
		
		 ConfirmSX8()

	EndIf
	
Next

//If !lMsErroAuto
   For _nX := 1 To Len(_aRecTSB2)
       SB2->(DBGoTo(_aRecTSB2[_nX]))
       If SB2->B2_BLOQUEI <> "4"
  	      SB2->(RecLock("SB2",.F.))
  	      SB2->B2_BLOQUEI :=  "4"
  	      SB2->(MSUnLock())
		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00461"/*cMsgId*/,'MCOM00461 - MCOM4Trans-Bloqueou B2_FILIAL+B2_COD+B2_LOCAL = '+SB2->(B2_FILIAL+B2_COD+B2_LOCAL)/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	   EndIf
   Next

END TRANSACTION

End Sequence
SD1->(DBSetOrder(1)) 

FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00462"/*cMsgId*/,"MCOM00462 - MCOM4Trans - TERMINO - PV: "+_cChave/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

Return .T.

/*
===============================================================================================================================
Programa--------: MCOM4DesTrans()
Autor-----------: Alex Wallauer
Data da Criacao-: 07/01/2022
Descrição-------: DesTransfere o produto de leite a granel de volta
Parametros------: _cChave: _cFilial + _cNumPC
Retorno---------: .T. OU .F.
===============================================================================================================================*/
Static Function MCOM4DesTrans(_cChave)
Local _aTransferecias:={}
Local _nOpcAuto   := 3 // Indica qual tipo de ação será tomada (Inclusão/Exclusão)
Local _cOriLocal  := "01"//armazem usado para bloquear (processo)
Local _cDesLocal  := "03"
Local _cLOriCodProd:= AVKEY(SuperGetMV("IT_LTMP",.F.,'08000000034'),"D3_COD")//LEITE
Local _cLDestprod  := SuperGetMV("IT_LTGRN",.F.,'08000000062')//LEITE
Local _cCOriCodProd:= AVKEY(SuperGetMV("IT_CRMP",.F.,'08000000007'),"D3_COD")//CREME
Local _cCDestprod  := SuperGetMV("IT_CRGRN",.F.,'08000000064;08000000063')//CREME
Local _cDesCodProd := ""
Local _nQtde :=0
Local dDataVl:=CTOD("")
Local _nX,B
Local _lTrocaLeite:=!(cFilAnt $ SuperGetMV('IT_FLNGRA',.F.,'10')) //Filiais que não fazem transferência de leite a granel
Local _lTrocaCreme:=!(cFilAnt $ SuperGetMV('IT_CRNGRA',.F.,'40')) //Filiais que não fazem transferência de creme a granel
Local _aRecSB2 :={}
Local _aRecTSB2:={}
Local _cFilVld34:= SuperGetMV('IT_FILVLD3',.F.,'')

_cMensagem:=""//INICIADA ANTES DA CHAMADA DA FUNCAO

SF4->(DBSetOrder(1))
SB1->(DBSetOrder(1))

FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00463"/*cMsgId*/,"MCOM00463 - MCOM4DesTrans - INICIO - PV: "+_cChave/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

SD1->(DBSetOrder(22)) //D1_FILIAL+D1_PEDIDO+D1_ITEMPC
If !SD1->(DBSeek(_cChave)) //.OR. SD1->D1_TIPO <> 'N'
   FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00464"/*cMsgId*/,"MCOM00464 - MCOM4DesTrans- Nao achou - _cChave: "+_cChave/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
   Return .F.
EndIf

aAuto:={""}
While SD1->(!Eof()) .And. _cChave == SD1->(D1_FILIAL+D1_PEDIDO)

    aAuto:={""}
	If SD1->D1_TIPO <> 'N' //!SF4->(DBSeek(SD1->D1_FILIAL + SD1->D1_TES)) .Or. SF4->F4_ESTOQUE <> "S" .Or. 
		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00465"/*cMsgId*/,"MCOM00465 - MCOM4DesTrans- SD1->D1_TIPO = " +SD1->D1_TIPO+" / SD1->D1_FILIAL+SD1->D1_DOC+SD1->D1_SERIE+SD1->D1_FORNECE+SD1->D1_LOJA: "+SD1->D1_FILIAL+SD1->D1_DOC+SD1->D1_SERIE+SD1->D1_FORNECE+SD1->D1_LOJA/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	   aAuto[1]:="SD1->D1_TIPO = " +SD1->D1_TIPO+" / SD1->D1_FILIAL+SD1->D1_DOC+SD1->D1_SERIE+SD1->D1_FORNECE+SD1->D1_LOJA: "+SD1->D1_FILIAL+SD1->D1_DOC+SD1->D1_SERIE+SD1->D1_FORNECE+SD1->D1_LOJA
	    SD1->(DBSkip())
		Loop
	EndIf
	
	_cDesLocal   := SD1->D1_LOCAL
    _cOriCodProd := SD1->D1_COD
	_cDesCodProd := SD1->D1_COD
	If AllTrim(_cDesCodProd) $ _cLDestprod .And. _lTrocaLeite
	   _cOriCodProd := _cLOriCodProd
	   _cDesCodProd := _cLOriCodProd
	ElseIf AllTrim(_cDesCodProd) $ _cCDestprod .And. _lTrocaCreme
	   _cOriCodProd := _cCOriCodProd
	   _cDesCodProd := _cCOriCodProd
	EndIf

    _nQtde:=SD1->D1_QUANT
	SD3->(DBSetOrder(13)) //D3_FILIAL + D3_CHAVEF1
	If !SD3->(DBSeek(SD1->D1_FILIAL+"MCOM004"+_cChave+SD1->D1_DOC+SD1->D1_SERIE))  //VERIFICA SE HOUVE BLOQUEIO / REJEICAO ANTERIOR DO PEDIDO	    
	   FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00466"/*cMsgId*/,"MCOM00466 - MCOM4DesTrans - MCOM004 + _cChave+SD1->D1_DOC+SD1->D1_SERIE = " +"MCOM004" + _cChave+SD1->D1_DOC+SD1->D1_SERIE+" NAO ACHOU"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	   aAuto[1]:="SEEK SD3: MCOM004 + _cChave+SD1->D1_DOC+SD1->D1_SERIE = " +"MCOM004" + _cChave+SD1->D1_DOC+SD1->D1_SERIE+" NAO ACHOU"
	   SD1->(DBSkip())
	   Loop
	Else
	    While  !SD3->(Eof()) .And. SD1->D1_FILIAL+"MCOM004"+AllTrim(_cChave+SD1->D1_DOC+SD1->D1_SERIE) == SD3->D3_FILIAL+AllTrim(SD3->D3_CHAVEF1)
		   _nQtde+=SD3->D3_QUANT
		   FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00467"/*cMsgId*/,"MCOM00467 - MCOM4DesTrans - _cChave+SD1->D1_DOC+SD1->D1_SERIE = " + _cChave+SD1->D1_DOC+SD1->D1_SERIE+" ACHOU E SOMOU "+CVALTOCHAR(SD3->D3_QUANT)/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	       SD3->(DBSkip())
		EndDo
	EndIf

	FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00468"/*cMsgId*/,'MCOM00468 - MCOM4DesTrans-TRANSFERENCIA DE ' +_cOriLocal+ " "+ _cOriCodProd+" PARA "+_cDesLocal+" "+_cDesCodProd+" SD1->D1_QUANT = "+CVALTOCHAR(_nQtde)/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	If _cOriCodProd == _cDesCodProd .And. _cOriLocal == _cDesLocal
	   aAuto[1]:='TRANSFERENCIA DE ' +_cOriLocal+ " "+ _cOriCodProd+" PARA "+_cDesLocal+" "+_cDesCodProd+" TUDO IGUAL"
	   SD1->(DBSkip())
	   Loop
	EndIf

	If SB2->(DBSeek(SD1->D1_FILIAL+_cOriCodProd+_cOriLocal)) 
	   If SB2->B2_BLOQUEI =  "4"
  	      SB2->(RecLock("SB2",.F.))
  	      SB2->B2_BLOQUEI :=  ""
  	      SB2->(MSUnLock())
	      aAdd(_aRecSB2,SB2->(RECNO()) )  
		  FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00469"/*cMsgId*/,'MCOM00469 - MCOM4DesTrans-Desbloqueou SC7->C7_FILIAL+SC7->C7_PRODUTO+_cOriLocal = '+SC7->C7_FILIAL+SC7->C7_PRODUTO+_cOriLocal/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	   EndIf
	   aAdd(_aRecTSB2,SB2->(RECNO()) )  
	EndIf

    SF1->(DBSetOrder(1))
    If SF1->(DBSeek(SD1->D1_FILIAL+SD1->D1_DOC+SD1->D1_SERIE+SD1->D1_FORNECE+SD1->D1_LOJA) )
    
       SE2->(DBSetOrder(6)) // E2_FILIAL+E2_FORNECE+E2_LOJA+E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO
       If SE2->(DBSeek(SF1->F1_FILIAL+SF1->F1_FORNECE+SF1->F1_LOJA+SF1->F1_SERIE+SF1->F1_DOC))
          SE2->(RecLock("SE2", .F.))
          SE2->E2_MSBLQL := "2" //DESBLOQUEIA
          SE2->(MSUnLock())
		  FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00470"/*cMsgId*/,'MCOM00470 - MCOM4DesTrans-DesBloqueou Titulo SF1->F1_FILIAL+SF1->F1_FORNECE+SF1->F1_LOJA+SF1->F1_SERIE+SF1->F1_DOC= '+SF1->F1_FILIAL+SF1->F1_FORNECE+SF1->F1_LOJA+SF1->F1_SERIE+SF1->F1_DOC/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
       EndIf
       SE2->(DBSetOrder(1)) 
    
    EndIf

	//****** Cabecalho a Incluir ***
	cDoc:=GetSxENum("SD3","D3_DOC",1)
	aAuto:={}
	aAdd(aAuto,{cDoc,dDataBase})  //Cabecalho
	//****** Cabecalho a Incluir ***

	//****** Itens a Incluir  ******
    SB1->(DBSeek(xFilial()+_cOriCodProd)) // ORIGEM ************
    aItem:={}
	aAdd(aItem,_cOriCodProd)//D3_COD
	aAdd(aItem,SB1->B1_DESC)//D3_DESCRI
	aAdd(aItem,SB1->B1_UM)  //D3_UM
	aAdd(aItem,_cOriLocal)  //D3_LOCAL
	aAdd(aItem,"")		    //D3_LOCALIZ //Endereço Orig
    
	SB1->(DBSeek(xFilial()+_cDesCodProd)) // DESTINO ***************
	aAdd(aItem,_cDesCodProd)//D3_COD
	aAdd(aItem,SB1->B1_DESC)//D3_DESCRI
	aAdd(aItem,SB1->B1_UM)  //D3_UM
	aAdd(aItem,_cDesLocal)  //D3_LOCAL
	aAdd(aItem,"")		    //D3_LOCALIZ //Endereço Dest
	aAdd(aItem,"")          //D3_NUMSERI
	aAdd(aItem,"")  	    //D3_LOTECTL
	aAdd(aItem,"")         	//D3_NUMLOTE
	aAdd(aItem,dDataVl)	    //D3_DTVALID
	aAdd(aItem,0)		    //D3_POTENCI
	aAdd(aItem,_nQtde)      //D3_QUANT
	aAdd(aItem,0)		    //D3_QTSEGUM
	aAdd(aItem,"")          //D3_ESTORNO
	aAdd(aItem,"")      	//D3_NUMSEQ
	aAdd(aItem,"")  	    //D3_LOTECTL
	aAdd(aItem,dDataVl)	    //D3_DTVALID
	aAdd(aItem,"")	 	    //D3_ITEMGRD
	aAdd(aItem,"")	 	    //D3_OBSERVA  //Observação C        30
	//Campos Customizados:                                       
	aAdd(aItem,"DESBLOQUEIO DO PC: "+_cChave)	 	    //D3_I_OBS    //Observação C       254
    If ! cFilant $ _cFilVld34 // Este campo não deve estar disponível para filiais de validação do armazém 34 (Descarte).
	   aAdd(aItem,"")	 	              //D3_I_TPTRS  // Mot.Tran.R C  1
	   aAdd(aItem,"")	 	              //D3_I_DSCTM  // Des.Mot.Tr C  1
    EndIf 
    If cFilant $ _cFilVld34 // Este campo não deve estar disponível para filiais de validação do armazém 34 (Descarte).
	   aAdd(aItem,"")	 	          //D3_I_MOTTR  // Mot.Tran.R C         8 
	   aAdd(aItem,"")	 	          //D3_I_DSCMT  // Des.Mot.Tr C        40 
	   aAdd(aItem,"")	 	          //D3_I_SETOR  // Origem Trf C        40 
	   aAdd(aItem,"")	 	          //D3_I_DESTI  // Destino    C        40 
    EndIf 
	//****** Itens a Incluir  ******

	aAdd(aAuto,aItem)
		
	aAdd(_aTransferecias,aAuto)//Tem que ser um MSExecAuto para cada linha pq ele não deixa em uma mesma inclusao colocar itens origem/destino repetidos
		
	SD1->(DBSkip())
EndDo


Begin Sequence
If Empty(_aTransferecias)
// _cMensagem ENVIA E-MAIL
   _cMensagem+="Nao foi possivel Transferir o estoque do Pedido DE VOLTA: "+_cChave+", MOTIVO: "+aAuto[1]
   FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00471"/*cMsgId*/,'MCOM00471 - MCOM4DesTrans-_cMensagem = ' +_cMensagem/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
   _cMensagem:=""//para não mostrar no e-mail
   Break
EndIf

BEGIN TRANSACTION
For _nX := 1 To Len(_aTransferecias)
	
	lMsErroAuto := .F.
	_cMenITmsgLog:=""//Variavel preenchida na User Function ITmsg()

	MSExecAuto({|x,y| MATA261(x,y)},_aTransferecias[_nX],_nOpcAuto)
	
	If lMsErroAuto
		If __lSx8
			RollBackSX8()
		EndIf
		
        _cMensagem+="Não foi possivel Tranferir/Desbloquear o estoque dos itens, faça o Tranferencia/Desbloqueio manualmente por favor, Erros: ["+_cMenITmsgLog+"] ["+MostraErro(Upper(GetSrvProfString("STARTPATH","")),"MCOM004.LOG")+"] "
		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00472"/*cMsgId*/,'MCOM00472 - MCOM4DesTrans-_cMensagem = ' +_cMensagem/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
  
        For B := 1 To Len(_aRecSB2)
		    SB2->(DBGoTo(_aRecSB2[B]))
  	        SB2->(RecLock("SB2",.F.))
  	        SB2->B2_BLOQUEI :=  "4"
  	        SB2->(MSUnLock())
			FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00473"/*cMsgId*/,'MCOM00473 - MCOM4DesTrans-Bloqueou B2_FILIAL+B2_COD+B2_LOCAL = '+SB2->(B2_FILIAL+B2_COD+B2_LOCAL)/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		Next
        Exit
	Else
		
		 ConfirmSX8()

	EndIf
	
Next

End Sequence
END TRANSACTION

SD1->(DBSetOrder(1)) 

FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00474"/*cMsgId*/,"MCOM00474 - MCOM4DesTrans - TERMINO - PV: "+_cChave/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

Return .T.

/*
===============================================================================================================================
Programa----------: MCOM04RA
Autor-------------: Alex Wallauer
Data da Criacao---: 07/04/2022
Descrição---------: Rotina CHAMADA DO BOTAO "Reenvio E-mail Avaliacao","U_MCOM04RA()" mo RDMAKE MT121BRW.PRW
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MCOM04RA()

Local aArea		:= FWGetArea()
Local cFilPC	:= SuperGetMV("IT_FILWFPC",.F.,"01")
Local dDatIni	:= SuperGetMV("IT_WFPCINI",.F.,"01/01/2016")

//==================================================================
// Verifica se a filial corrente esta apta a utilização desta rotina
//==================================================================
If cFilAnt $ cFilPC
	//=======================================================================
	// Verifica se pedido posicionado está na condição para reenvio de e-mail
	//=======================================================================
	If (SC7->C7_CONAPRO = "L" .Or. SC7->C7_CONAPRO = "R") .And. SC7->C7_EMISSAO >= dDatIni//SC7->C7_APROV <> "PENLIB" 
		//===============================================================================
		// O sistema verificará se o pedido posicionado está apto para reenvio de e-mail,
		// se o pedido tiver todos os seus itens com eliminação de resíduo para este pedi
		// do, o sistema não deixará efetuar o reenvio do workflow
		//===============================================================================
          _lTodos:=.T.
          nRet:=AVISO("Reenviando E-mail de WF" , "Enviar e-mail para TODOS e Usuario Logado ou SOMENTE para o Usuario Logado: "+;
                      LOWER(AllTrim(UsrRetMail(RetCodUsr()))), {"TODOS","User Logado","CANCELAR"} ,2 ) 
          If nRet = 1
             _lTodos:=.T.
          ElseIf nRet = 2
             _lTodos:=.F.
          Else
            Return .F.
          EndIf


	        _cMemEnv:=MCOM004A(SC7->C7_FILIAL,SC7->C7_NUM,SC7->C7_I_STAEM,"REENVIO")

			U_ITMsg(_cMemEnv,"CONCLUSAO",,2)
	Else
		If SC7->C7_CONAPRO <> "L" .And. SC7->C7_CONAPRO <> "R" //SC7->C7_APROV == "PENLIB"//SC7->C7_CONAPRO == 'B' .And. 
			FWAlertWarning("Este pedido não pode ser reenviado, pois ainda não foi avaliado pelo Gestor de Compras. Status Pedido: C7_CONAPRO = "+SC7->C7_CONAPRO+" / C7_APROV = "+SC7->C7_APROV ,"MCOM00486")
		ElseIf SC7->C7_EMISSAO < dDatIni
			FWAlertWarning("Este Pedido não pode ser reenviado, pois sua data de emissão é anterior a data de início de utilização do Workflow: "+DToC(dDatIni),"MCOM00487")
		EndIf
	EndIf
Else
	FWAlertWarning("Filial não habilitada para utilização desta rotina.","MCOM00488")
EndIf

FWRestArea(aArea)
Return

/*
===============================================================================================================================
Programa----------: SchedDef
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 13/09/2024
Descrição---------: DefiniçStaticStatic Function SchedDef para o novo Schedule
					No novo Schedule existe uma forma para a definição dos Perguntes para o botão Parâmetros, além do cadastro 
					das funções no SXD. Ao definir em sua rotinStaticatic Function SchedDef(), no cadastro da rotina no Agenda-
					mento do Schedule será verIficado se existe estStaticic Function e irá executá-la habilitando o botão Parâ-
					metros com as informações do retorno da SchedDef(), deixando de verIficar assim as informações na SXD. O 
					retorno da SchedDef deverá ser um array.
					Válido para Function e User Function, lembrando que uma vez definido a SchedDef, ao chamar a rotina o ambi-
					ente já está inicializado.
					Uma vez definido a Static Function SchedDef(), a rotina deixa de ser uma execução como processo especial, 
					ou seja, não se deve cadastrá-la no Agendamento passando parâmetros de linha. Ex: Funcao("A","B") ou 
					U_Funcao("A","B").
Parametros--------: aReturn[1] - Tipo: "P" - para Processo, "R" -  para Relatórios
					aReturn[2] - Nome do Pergunte, caso nao use passar ParamDef
					aReturn[3] - Alias  (para Relatório)
					aReturn[4] - Array de ordem  (para Relatório)
					aReturn[5] - Título (para Relatório)
Retorno-----------: aParam
===============================================================================================================================
*/
Static Function SchedDef()

Local aParam  := {}
Local aOrd := {}

aParam := { "P",;
            "PARAMDEFF",;
            "",;
            aOrd,;
            }

Return aParam

/*
===============================================================================================================================
Programa----------: MCOM004Z
Autor-------------: Igor Melgaço
Data da Criacao---: 25/11/2024
Descrição---------: Envio e email na inclusão ou alteração do pedido de compra                              
Parametros--------: _cFilial,_cNumPc,_aItens,_lInclui,_lWF
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MCOM004Z(_cFilial As Character,_cNumPc As Character,_aItens As Array,_lInclui As Logical)
Local _aArea As Array
Local _sArqHTM As Character
Local _cHostWF As Character
Local cLogo As Character
Local cLogo1 As Character
Local cFiltro As Character
Local cNomSol As Character
Local cNomApr As Character
Local cNomFor As Character
Local cCgcFor As Character
Local _cAssunto As Character
Local _cEmail As Character
Local _cMailAux As Character
Local _cGrpLeite As Character
Local _cQuery As Character
Local _cEmailGrpLeite As Character
Local _lTodos As Logical
Local _cItens As Character
Local _nI As Numeric
Local _nPos As Numeric
Local nLinhas As Numeric
Local dDataSol As Data
Local dDataAnt As Data
Local nQtdSol As Numeric
Local nQtdAnt As Numeric
Local _aAprov As Array
Local _lGrpLeite As Logical 
Local _cDep As Character
Local _aDados As Array
Local nContrl As Numeric
Local _nConta As Numeric

Default _lInclui := .F.

_aArea			:= FWGetArea()
_sArqHTM		:= "" 
_cHostWF		:= SuperGetMV("IT_WFHOSTS",.F.,"http://wfteste.italac.com.br:4034/")
cLogo			:= _cHostWF + "htm/logo_novo.jpg"
cLogo1			:= _cHostWF + "htm/logo_novo.jpg"
cFiltro			:= ""
nLinhas			:= 0
cNomSol			:= ""
cNomApr			:= ""
cNomFor			:= ""
cCgcFor			:= ""
_cAssunto		:= "" 
_cEmail			:= ""
_cGrpLeite		:= AllTrim(SuperGetMV("IT_GRPLEIT",.F.,""))
_cQuery			:= ""
_cEmailGrpLeite	:= ""
_lTodos			:= .T.
_cItens			:= ""
_nI				:= 0
_nPos			:= 0
_aAprov			:= {}
_cDep           := ""
_aDados         := {}
_cMailAux       := ""
nContrl         := 0
_nConta         := 0

_lGrpLeite		:= .F.

_sArqHTM := "\workflow\htm\pc_prevent.htm" 

nContrl	:= 0

For _nI := 1 To Len(_aItens)
	If !(_aItens[_nI,2] $ _cItens)
		_cItens += IIf(Empty(_cItens),"",";") + _aItens[_nI,2]
	EndIf
Next

_cAliasSC7 := GetNextAlias()

cQry := "SELECT	C7_FILIAL, C7_NUM, C7_ITEM, C7_PRODUTO, C7_EMISSAO, C7_QUANT, C7_UM, C7_PRECO, C7_TOTAL, C7_FORNECE, C7_LOJA, C7_QTDREEM, C7_VLDESC, C7_DATPRF, C7_I_URGEN, C7_I_CMPDI, C7_I_NFORN, C7_CONAPRO, "
cQry += "			C7_DESCRI, C7_I_DESCD, C7_COND, C7_I_GCOM, C7_USER, C7_GRUPCOM, C7_NUMSC, C7_ITEMSC, C7_I_APLIC, C7_I_CDINV, C7_I_CMPDI, C7_VALIPI, C7_ICMSRET, C7_VALICM, C7_CC, C7_FRETE, C7_TPFRETE, C7_OBS, C7_FRETCON, C7_PICM,"
cQry += "			C7_I_CDTRA, C7_I_LJTRA, C7_I_TPFRT, C7_CONTATO, A2_COD, A2_LOJA, A2_NOME, A2_END, A2_MUN, A2_EST, A2_CEP, A2_DDD, A2_TEL, A2_FAX, A2_CGC, A2_INSCR, A2_CONTATO, C7_I_QTAPR, C7_MOEDA, C7_TXMOEDA, C7_I_CLAIM, C7_L_EXEMG "
cQry += "	FROM " + RetSqlName("SC7")+" SC7 "//%table:SC7% SC7
cQry += "	JOIN " + RetSqlName("SA2")+" SA2 ON A2_FILIAL = '"+xFilial("SA2")+"' AND A2_COD = C7_FORNECE AND A2_LOJA = C7_LOJA AND SA2.D_E_L_E_T_ = ' '  "
cQry += "	WHERE C7_FILIAL = '"+_cFilial+"' "
cQry += "	  AND C7_NUM = '"+_cNumPC+"' "    //%Exp:_cNumPC%
cQry += "     AND C7_ITEM IN "+FormatIn(_cItens,';')+" "
cQry += "	  AND SC7.D_E_L_E_T_ = ' ' "
cQry += "	ORDER BY C7_FILIAL, C7_NUM, C7_ITEM	  "

MPSysOpenQuery( cQry,_cAliasSC7 )

DBSelectArea(_cAliasSC7)
_nConta := 0
COUNT To _nConta

(_cAliasSC7)->(DBGoTop())

If !(_cAliasSC7)->(Eof())
	// Inicialize a classe TWFProcess e assinale a variável objeto oProcess:
	_oProcess := TWFProcess():New("SendMail", "Envio de email no retorno" )
	_oProcess:NewTask("SendMail", _sArqHTM)

	While !(_cAliasSC7)->(Eof())

		nContrl++

		If nContrl == 1

			nQtdSol	 := 0
			dDataSol := CTOD("")
			nQtdAnt	 := 0
			dDataAnt := CTOD("")

			//Validade se o PC é do Grupo de Leite
			_lGrpLeite := IIf((_cAliasSC7)->C7_GRUPCOM $ _cGrpLeite ,.T.,.F.)

			_oProcess:oHtml:ValByName("NumPC" , _cNumPC)
			_oProcess:oHtml:ValByName("Modelo", IIf(_lInclui,"incluído","alterado"))

			If !Empty((_cAliasSC7)->C7_I_GCOM)
				cNomGes := MCOM004FullNome((_cAliasSC7)->C7_I_GCOM,.T.)
			Else
				cNomGes := ""
			EndIf

            _oProcess:oHtml:ValByName("cNomGes",cNomGes  )

			If Empty(AllTrim(_cEmail))
				_cMailAux := AllTrim(UsrRetMail((_cAliasSC7)->C7_USER))
				If !Empty(_cMailAux) 
					_cEmail := _cMailAux+ ";"
				EndIf  
			EndIf

			_cAliasSC1 := GetNextAlias()

			cQry := "SELECT C1_I_CDSOL, C1_I_CODAP, C1_NUM, C1_EMISSAO, C1_I_DTAPR, C1_I_OBSAP, C1_I_OBSSC , C1_DATPRF, C1_QTDORIG "
			cQry += "FROM " + RetSqlName("SC1") + " "
			cQry += "WHERE C1_FILIAL = '" + (_cAliasSC7)->C7_FILIAL + "' "
			cQry += "  AND C1_NUM = '"    + (_cAliasSC7)->C7_NUMSC + "' "
			cQry += "  AND C1_ITEM = '"   + (_cAliasSC7)->C7_ITEMSC + "' "
			cQry += "  AND D_E_L_E_T_ = ' ' "

			MPSysOpenQuery( cQry,_cAliasSC1 )

			If !(_cAliasSC1)->(Eof())

				If Empty(AllTrim((_cAliasSC1)->C1_I_CDSOL))					
					cNomSol := ""           
				Else
					cNomSol := AllTrim(Posicione("ZZ7",1,SubStr(_cFilial,1,2) + (_cAliasSC1)->C1_I_CDSOL, "ZZ7_NOME"))
					_cMailAux := AllTrim(UsrRetMail((_cAliasSC1)->C1_I_CDSOL))

                    If !Empty(_cMailAux) .And. !Upper(_cMailAux) $ Upper(_cEmail)  
						_cEmail += _cMailAux + ";"
					EndIf
				EndIf

				If Empty((_cAliasSC1)->C1_I_CODAP)
					cNomApr := ""
				Else
					cNomApr := AllTrim(Posicione("ZZ7",1,SubStr(_cFilial,1,2) + (_cAliasSC1)->C1_I_CODAP, "ZZ7_NOME"))
					_cMailAux := AllTrim(UsrRetMail((_cAliasSC1)->C1_I_CODAP))

                    If !Empty(_cMailAux) .And. !Upper(_cMailAux) $ Upper(_cEmail)
					   _cEmail += _cMailAux + ";"
					EndIf
				EndIf

				_oProcess:oHtml:ValByName("cnumSC",AllTrim((_cAliasSC1)->C1_NUM))
				_oProcess:oHtml:ValByName("cdtinc",AllTrim(DToC(SToD((_cAliasSC1)->C1_EMISSAO))))

			Else
				cNomSol := ""        
				cNomApr := ""
			EndIf

			_oProcess:oHtml:ValByName("cNomSol" , cNomSol)
			_oProcess:oHtml:ValByName("cNomApr" , cNomApr)
			_oProcess:oHtml:ValByName("cDigiFor", MCOM004FullNome((_cAliasSC7)->C7_USER,.T.) )
			_oProcess:oHtml:ValByName("dDtEmiss", DToC(SToD((_cAliasSC7)->C7_EMISSAO)))
		
			cNomFor	:= AllTrim((_cAliasSC7)->A2_NOME)
			cCgcFor	:= formCPFCNPJ((_cAliasSC7)->A2_CGC)

			_oProcess:oHtml:ValByName("cNomFor"			, cNomFor+ " - " + (_cAliasSC7)->C7_FORNECE + "/" + (_cAliasSC7)->C7_LOJA)
			_oProcess:oHtml:ValByName("cCGCFor"			, cCgcFor)
			_oProcess:oHtml:ValByName("cContatFor"		, AllTrim((_cAliasSC7)->C7_CONTATO))

		EndIf

		_nPos := aScan(_aItens,{|x| x[1] = 'DATA' .And.  x[2] = (_cAliasSC7)->C7_ITEM  })

		If _nPos > 0
			nQtdSol	 := _aItens[_nPos,3]
			dDataSol := _aItens[_nPos,4]

			dDataAnt := _aItens[_nPos,5]
		EndIf

		_nPos := aScan(_aItens,{|x| x[1] = 'QTD' .And.  x[2] = (_cAliasSC7)->C7_ITEM  })
		
		If _nPos > 0
			nQtdSol	 := _aItens[_nPos,3]
			dDataSol := _aItens[_nPos,4]

			nQtdAnt	:= _aItens[_nPos,5]
		EndIf

		aAdd( _oProcess:oHtml:ValByName("Itens.Item" 			), (_cAliasSC7)->C7_ITEM 												)
		aAdd( _oProcess:oHtml:ValByName("Itens.Prodpc" 			), (_cAliasSC7)->C7_PRODUTO								 				)		
		aAdd( _oProcess:oHtml:ValByName("Itens.DesProd"			), IIf(AllTrim((_cAliasSC7)->C7_I_DESCD) $ (_cAliasSC7)->C7_DESCRI,AllTrim((_cAliasSC7)->C7_DESCRI), AllTrim((_cAliasSC7)->C7_DESCRI) + " " + AllTrim((_cAliasSC7)->C7_I_DESCD)))
		aAdd( _oProcess:oHtml:ValByName("Itens.UM"				), (_cAliasSC7)->C7_UM													)
		aAdd( _oProcess:oHtml:ValByName("Itens.qtdeSol"			), Transform(nQtdSol, PesqPict("SC7","C7_QUANT"))		)
		aAdd( _oProcess:oHtml:ValByName("Itens.DtSol"			), DToC(dDataSol) )
		aAdd( _oProcess:oHtml:ValByName("Itens.qtde"			), AllTrim(Transform((_cAliasSC7)->C7_QUANT, PesqPict("SC7","C7_QUANT"))) + IIf((_cAliasSC7)->C7_QUANT == nQtdAnt .Or. nQtdAnt = 0,""," Qtd Anterior: " + AllTrim(Transform(nQtdAnt, PesqPict("SC7","C7_QUANT"))))		)
		aAdd( _oProcess:oHtml:ValByName("Itens.DtEmis"			), DToC(SToD((_cAliasSC7)->C7_DATPRF)) + IIf(SToD((_cAliasSC7)->C7_DATPRF) == dDataAnt .Or. Empty(AllTrim(DToS(dDataAnt))),""," Data Anterior: " + DToC(dDataAnt)) )

		If Select(_cAliasSC1) > 0
			(_cAliasSC1)->(DBCloseArea())
		EndIf

		(_cAliasSC7)->(DBSkip())

	EndDo

	(_cAliasSC7)->(DBGoTop())

	_cAliasSCR := GetNextAlias()

	cQrySCR := "SELECT CR_USER, CR_APROV, CR_DATALIB, CR_I_HRAPR, CR_STATUS, R_E_C_N_O_ RECNUM , CR_NIVEL, CR_OBS "
	cQrySCR += "FROM " + RetSqlName("SCR") + " "
	cQrySCR += "WHERE CR_FILIAL = '" + SubStr(_cFilial,1,2) + "' "
	cQrySCR += "  AND CR_NUM = '" + _cNumPC + "' "
	cQrySCR += "  AND CR_TIPO = 'PC' "
	cQrySCR += "  AND D_E_L_E_T_ = ' ' "                        
	cQrySCR += "  ORDER BY CR_FILIAL, CR_NUM, CR_NIVEL "	

	MPSysOpenQuery( cQrySCR,_cAliasSCR )

	_aAprov	:= {}

	If !(_cAliasSCR)->(Eof())
		While !(_cAliasSCR)->(Eof())

			nLinhas ++

			SCR->(DBGoTo((_cAliasSCR)->RECNUM)) 

			If aScan(_aAprov,(_cAliasSCR)->CR_USER+"|"+(_cAliasSCR)->CR_NIVEL ) = 0
				aAdd(_aAprov,(_cAliasSCR)->CR_USER+"|"+(_cAliasSCR)->CR_NIVEL)
			Else
				(_cAliasSCR)->(DBSkip())
				Loop
			EndIf
			
			_cDep := FWSFAllUsers({(_cAliasSCR)->CR_USER},{"USR_DEPTO"})[1][3]

			If Empty(_cDep)
				_cDep := "XXXXXXX"
			Endif
			
			If Upper(_cDep) <> "DIRECAO"//Não envia para diretoria
				_cMailAux := AllTrim(UsrRetMail((_cAliasSCR)->CR_USER))
				If !Empty(_cMailAux) .And. !Upper(_cMailAux) $ Upper(_cEmail)
					_cEmail += _cMailAux + ";"
				EndIf
			EndIf
		
			(_cAliasSCR)->(DBSkip())
		EndDo
	EndIf

	If Select(_cAliasSCR) > 0
		(_cAliasSCR)->(DBCloseArea())
	EndIf

	If _lGrpLeite

		_cAliasSAJ := GetNextAlias()

		_cQuery := "SELECT AJ_USER "
		_cQuery += "FROM " + RetSqlName("SAJ") + " "
		_cQuery += "WHERE AJ_FILIAL = ' ' "
		_cQuery += "	AND AJ_MSBLQL <> '1' "
		_cQuery += "	AND AJ_GRCOM IN " + FormatIn(_cGrpLeite,";") 
		_cQuery += "	AND D_E_L_E_T_ = ' ' "

		MPSysOpenQuery( _cQuery,_cAliasSAJ )

		If !(_cAliasSAJ)->(Eof())
			While !(_cAliasSAJ)->(Eof())
				_cMailAux := AllTrim(UsrRetMail((_cAliasSAJ)->AJ_USER))

				If !Empty(_cMailAux) .And. !Upper(_cMailAux) $ Upper(_cEmail) .And. !Upper(_cMailAux) $ Upper(_cEmailGrpLeite)
					_cEmailGrpLeite += _cMailAux + ";" 
				EndIf

				(_cAliasSAJ)->(DBSkip())
			EndDo
		EndIf

		(_cAliasSAJ)->(DBCloseArea())   
		
		_cEmail += _cEmailGrpLeite 
	
	EndIf
	
	_cAssunto := "Alteração do Pedido de Compra Filial " + _cFilial + " Número: " + SubStr(_cNumPc,1,6) 

	_oProcess:cSubject := FWHttpEncode(_cAssunto) 

	If _lTodos
		_cEmail += ";" + Lower(AllTrim(UsrRetMail(RetCodUsr())))
	Else
		_cEmail := Lower(AllTrim(UsrRetMail(RetCodUsr())))
	EndIf
	
	_oProcess:cTo := _cEmail //05 - "Retorno WF do PC Filial "  - "IT_MAILWFC"

	_oProcess:Start()
	_oProcess:Finish()
EndIf

FWRestArea(_aArea)

If Select(_cAliasSC7) > 0
	(_cAliasSC7)->(DBCloseArea())
EndIf

Return
