/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |24/09/2024| Chamado 48465. Removendo warning de compilação, corrigida chamada para schedule e melhorado log
Lucas Borges  |01/08/2025| Chamado 51453. Substituir função U_ITEncode por FWHttpEncode
Lucas Borges  |19/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
Jose Gavetti  |26/11/2025| Chamado 51341. __cUserId não deve ter seu conteúdo alterado orientação TOTVS. 
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MCOM003
Autor-------------: Darcio Ribeiro Sporl
Data da Criacao---: 17/11/2015
Descrição---------: Rotina responsavel pelo envio de workflow de solicitação de compras
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MCOM003

Local _cAliasSC1	:= ""
Local lWFHTML		:= .T.

Private _cHostWF	:= ""
Private _dDtIni		:= ""

//Mensagem que ficara armazenada no arquivo totvsconsole.log para posterior monitoramento 
FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00301"/*cMsgId*/, 'MCOM00301 - Gerando envio do workflow das solicitações de compras aos aprovadores na data: ' + DToC(Date()) + ' - ' + Time()/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

_cHostWF 	:= SuperGetMV("IT_WFHOSTS",.T.,"http://wfteste.italac.com.br:4034/")
_dDtIni		:= DToS(SuperGetMV("IT_WFDTINI",.F.,"26/11/2025"))
lWFHTML		:= GetMv("MV_WFHTML")

PutMV("MV_WFHTML",.T.)

_cAliasSC1 := GetNextAlias()
MCOM003Q(1,_cAliasSC1,"","","","","","","","","","")

DBSelectArea(_cAliasSC1)
(_cAliasSC1)->(DBGoTop())

If !(_cAliasSC1)->(Eof())
	MCOM003S(_cAliasSC1) //Rotina responsável por montar o formulário de aprovação e o envio do link gerado.
EndIf

(_cAliasSC1)->(DBCloseArea())          

PutMV("MV_WFHTML",lWFHTML)

FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00302"/*cMsgId*/,'MCOM00302 - Termino do envio do workflow das solicitações de compras na data: ' + DToC(Date()) + ' - ' + Time()/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

Return        

/*
===============================================================================================================================
Programa----------: MCOM003R
Autor-------------: Darcio Ribeiro Sporl
Data da Criacao---: 17/11/2015
Descrição---------: Rotina responsável pela execução do retorno do workflow
Parametros--------: _oProcess - Processo inicializado do workflow
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MCOM003R( _oProcess )

Local _cFilial		:= SubStr(_oProcess:oHtml:RetByName("Filial"),1,2)
Local _cNumSC		:= _oProcess:oHtml:RetByName("NumSC")    
Local _cAprova		:= Upper(_oProcess:oHtml:RetByName("opcao"))        
Local _cObs			:= AllTrim(Upper(_oProcess:oHtml:RetByName("CR_OBS")))
Local _cArqHtm		:= SubStr(_oProcess:oHtml:RetByName("WFMAILID"),3,Len(_oProcess:oHtml:RetByName("WFMAILID")))
Local _sDtLiber		:= DToS(Date())
Local _cHrLiber		:= SubStr(Time(),1,5)
Local _cVlrCampo	:= ""
Local _cHtmlMode	:= "\Workflow\htm\sc_concluida.htm"
Local _cPergPai := ""
//na variavel vem escrito "APROVAR (Aguarde...)"
If "APROVAR" $ _cAprova//_cAprova == "APROVAR"    
   _cAprova:= "APROVAR" 
	_cVlrCampo:= "L"
ElseIf "REJEITAR"  $ _cAprova//_cAprova == "REJEITAR" 
    _cAprova:="REJEITAR" 
	_cVlrCampo:= "R"		
Else    //QUESTIONAR
    _cAprova:="QUESTIONAR" 
	_cVlrCampo:= "Q"		
EndIf

If Empty(_cObs)
	_cObs := "EXECUTADO VIA WORKFLOW"
EndIf

//============================================================
//Atualiza rastreamento de aprovação da solicitação de compras
//============================================================
RastreiaWF(_oProcess:fProcessId + '.' + _oProcess:fTaskID , _oProcess:fProcCode, "1002", "Recebimento da Aprovacao da SC", "")

//===================
//Grava log no server
//===================
FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00303"/*cMsgId*/,'MCOM00303 - Filial...........: ' + _cFilial/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00303"/*cMsgId*/,'MCOM00303 - Solicitacao......: ' + _cNumSC/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00303"/*cMsgId*/,'MCOM00303 - Aprova...........: ' + _cAprova/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00303"/*cMsgId*/,'MCOM00303 - Data Liberacao...: ' + _sDtLiber/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00303"/*cMsgId*/,'MCOM00303 - Hora Liberacao...: ' + _cHrLiber/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00303"/*cMsgId*/,'MCOM00303 - Arquivo..........: ' + _cArqHtm/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

//===================================================================================================
//Chama query para atualização do registro da solicitação de compras, com as informações da aprovação
//===================================================================================================
If _cVlrCampo = 'Q'
// MCOM003Q(_nOpcao,_cAlias,_cFilial,_cNumSC,_cWFID,_cSITWF,_cIDHTM,_cAprova  ,_cObs,_sDtLiber,_cHrLiber,_cProduto,_cPergPai) 
   MCOM003Q(9      ,""     ,_cFilial,_cNumSC,"1002","3"    ,""     ,"P"       ,_cObs,_sDtLiber,_cHrLiber,""       ,@_cPergPai)
Else//aprovado ou rejeitado
   MCOM003Q(4      ,""     ,_cFilial,_cNumSC,"1002","3"    ,""     ,_cVlrCampo,_cObs,_sDtLiber,_cHrLiber,"")
EndIf

//==================================================
//Finalize a tarefa anterior para não ficar pendente
//==================================================
_oProcess:Finish()

//========================================================================================
//Faz a cópia do arquivo de aprovação para .old, e cria o arquivo de processo já concluído
//========================================================================================
If File("\workflow\emp01\" + _cArqHtm + ".htm")
	If __CopyFile("\workflow\emp01\" + _cArqHtm + ".htm", "\workflow\emp01\" + _cArqHtm + ".old")
		If MCOM003CP("\workflow\emp01\" + _cArqHtm + ".htm",_cHtmlMode) //Recria _cArqHtm com conteudo do modelo _cHtmlMode
			FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00304"/*cMsgId*/,"MCOM00304 - Cópia do arquivo DE "+_cHtmlMode+" PARA \workflow\emp01\" + _cArqHtm + ".htm de conclusão efetuada com sucesso."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		Else
			FWLogMsg("ERROR"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00305"/*cMsgId*/,"MCOM00305 - Problema na cópia de arquivo DE "+_cHtmlMode+" PARA \workflow\emp01\" + _cArqHtm + ".htm"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		EndIf
	Else
		FWLogMsg("ERROR"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00306"/*cMsgId*/,"MCOM00306 - Não foi possível renomear o arquivo " + _cArqHtm + ".htm."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	EndIf
EndIf

If _cVlrCampo = 'Q'
  MCOM003D(_oProcess,_cPergPai)//RETORNO QUE ENVIA E-MAIL DE QUESTIONMENTO
Else//aprovado ou rejeitado
  MCOM003A(_oProcess)//RETORNO QUE ENVIA E-MAIL
EndIf

Return

/*
===============================================================================================================================
Programa----------: MCOM003Q
Autor-------------: Darcio Ribeiro Sporl
Data da Criacao---: 17/11/2015
Descrição---------: Rotina responsável pela seleção dos dados das solicitações, pedido de compras e atualizações do workflow
Parametros--------: _nOpcao		- 1 = Dados SC / 2 = Dados PC / 3 = Atualização E-mail Enviado / 4 = Retorno Workflow
------------------: _cAlias		- Alias a ser utilizado no caso das consultas
------------------: _cFilial	- Filial do registro que está sendo executado
------------------: _cNumSC		- Número da Solicitação de Compras
------------------: _cWFID		- Id Workflow
------------------: _cSITWF		- Situação do Workflow
------------------: _cIDHTM		- Link do html gerado
------------------: _cAprova	- L - Liberado / R = Rejeitado / Q = Questionar
------------------: _cObs		- Observação do aprovador, preenchido no formulário de aprovação
------------------: _sDtLiber	- Data da aprovação
------------------: _cHrLiber	- Hora da aprovação
------------------: _cProduto	- Produto da solicitação de compras
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MCOM003Q(_nOpcao,_cAlias,_cFilial,_cNumSC,_cWFID,_cSITWF,_cIDHTM,_cAprova,_cObs,_sDtLiber,_cHrLiber,_cProduto,_cPergPai) 

Local _cQuery := ""

Do Case    

	//=============================================================================================================================
	//Seleciona todas as solicitações de compras que ainda não foram aprovadas e não foram enviadas, para serem enviar ao aprovador
	//=============================================================================================================================
	Case _nOpcao == 1   
		BeginSql alias _cAlias

			SELECT	DISTINCT C1_FILIAL, C1_NUM, C1_ITEM, C1_PRODUTO, C1_DESCRI, C1_EMISSAO, C1_UM, C1_QUANT, C1_OBS, C1_I_CDSOL, ZZ7A.ZZ7_NOME AS ZZ7_NOMSOL,
					C1_I_CODAP, ZZ7B.ZZ7_NOME AS ZZ7_NOMAPR, C1_CC, C1_I_CDINV, ZZI_DESINV, C1_I_APLIC, C1_I_URGEN, C1_I_ULTDT, C1_I_ULTPR, C1_DATPRF,
					C1_I_OBSSC, BZ_LOCPAD, (B2_QATU+B2_QNPT) B2_QATU, C1_I_ORPRU,C1_I_ORTOT, C1_I_CLAIM,
					(SELECT DISTINCT (Round(SUM(D3_QUANT/3),2)) D3_QUANT FROM %Table:SD3% WHERE D3_COD = C1_PRODUTO AND D3_EMISSAO BETWEEN TO_CHAR(SYSDATE-90,'YYYYMMDD') and TO_CHAR(SYSDATE,'YYYYMMDD') AND D3_ESTORNO <> 'S' AND D3_TM = '560' AND D_E_L_E_T_ = ' ') QTDTOT
			FROM %Table:SC1% SC1
			JOIN %Table:SBZ% SBZ ON BZ_FILIAL = C1_FILIAL AND BZ_COD = C1_PRODUTO AND SBZ.%notDel%
			LEFT JOIN %Table:SB2% SB2 ON B2_FILIAL = C1_FILIAL AND B2_COD = C1_PRODUTO AND B2_LOCAL = BZ_LOCPAD AND SB2.%notDel%
			LEFT JOIN %Table:SD3% SD3 ON D3_FILIAL = C1_FILIAL AND D3_COD = C1_PRODUTO AND D3_LOCAL = BZ_LOCPAD AND SD3.%notDel%
			JOIN %Table:ZZ7% ZZ7A ON ZZ7A.ZZ7_FILIAL = C1_FILIAL AND ZZ7A.ZZ7_CODUSR = C1_I_CDSOL AND ZZ7A.%notDel%
			JOIN %Table:ZZ7% ZZ7B ON ZZ7B.ZZ7_FILIAL = C1_FILIAL AND ZZ7B.ZZ7_CODUSR = C1_I_CODAP AND ZZ7B.%notDel%
			LEFT JOIN %Table:ZZI% ZZI ON ZZI_FILIAL = C1_FILIAL AND ZZI_CODINV = C1_I_CDINV AND ZZI.%notDel%
			WHERE C1_EMISSAO >= %Exp:_dDtIni%
			  AND C1_I_SITWF = '1'
			  AND C1_APROV = 'B'
			  AND C1_RESIDUO <> 'S' 
			  AND SC1.%notDel%
			ORDER BY C1_FILIAL, C1_NUM, C1_ITEM

		EndSql
                  
	//===============================================================
	//Seleciona Último pedido de compras por cada item da Solicitação
	//===============================================================
    Case _nOpcao == 2                                       

	    BeginSql alias _cAlias                                       
			SELECT C7_NUM, C7_ITEM, C7_PRODUTO, C7_EMISSAO, C7_QUANT, C7_UM, C7_PRECO, C7_TOTAL, C7_FORNECE, C7_LOJA, C7_I_NFORN, C7_DESCRI, B1_CONV
			FROM %Table:SC7% SC7
			JOIN %Table:SB1% SB1 ON B1_FILIAL = %xFilial:SB1% AND B1_COD = C7_PRODUTO AND SB1.%notDel%
			WHERE C7_FILIAL = %Exp:_cFilial%
			  AND C7_PRODUTO = %Exp:_cProduto%
			  AND C7_EMISSAO = (SELECT MAX(C7_EMISSAO) FROM %Table:SC7% WHERE C7_FILIAL = %Exp:_cFilial% AND C7_PRODUTO = %Exp:_cProduto% AND C7_RESIDUO <> 'S' AND C7_QUJE > 0 AND D_E_L_E_T_ = ' ')//AWF-07/06/16
			  AND C7_RESIDUO <> 'S'
			  AND C7_QUJE > 0
			  AND SC7.%notDel%
		EndSql		  
	             	
	//===========================================================================
	//Atualiza a solicitação de compras com WFID, SITWF e IDHTML - E-mail Enviado
	//===========================================================================
	Case _nOpcao == 3    
		_cQuery := "UPDATE "
		_cQuery += RETSQLNAME("SC1")
		_cQuery += " SET	C1_I_WFID  = '" + _cWFID  + "', "
		_cQuery += " 		C1_I_SITWF = '" + _cSITWF + "', "
		_cQuery += " 		C1_I_HTM   = '" + _cIDHTM + "' "
		_cQuery += "WHERE"
		_cQuery += " D_E_L_E_T_ = ' '" 
		_cQuery += " AND	C1_FILIAL = '" + _cFilial + "' "
		_cQuery += " AND	C1_NUM    = '" + _cNumSC  + "' "
		If TCSqlExec( _cQuery ) < 0
	   		FWLogMsg("ERROR"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00307"/*cMsgId*/,"MCOM00307 - TCSqlExec( _cQuery ) : "+_cQuery+" - TCSQLError(): "+AllTrim(TCSQLError())/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	    EndIf
		             				
	//====================================================================
	//Atualiza a solicitação de compras com os dados da aprovação/rejeição
	//====================================================================
	Case _nOpcao == 4
		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00308"/*cMsgId*/,"MCOM00308 - ---UPDATE SOLICITACAO---"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00308"/*cMsgId*/,"MCOM00308 - WFID........: " + _cWFID/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00308"/*cMsgId*/,"MCOM00308 - APROVADO....: " + _cAprova/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00308"/*cMsgId*/,"MCOM00308 - SITWF.......: " + _cSITWF/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00308"/*cMsgId*/,"MCOM00308 - DTAPR.......: " + _sDtLiber/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00308"/*cMsgId*/,"MCOM00308 - HRAPR.......: " + _cHrLiber/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00308"/*cMsgId*/,"MCOM00308 - OBSAP.......: " + _cObs/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	 		
		_cQuery := "UPDATE "
		_cQuery += RETSQLNAME("SC1")
		_cQuery += " SET	C1_I_WFID  = '" + _cWFID  	+ "', "
		_cQuery += " 		C1_APROV   = '" + _cAprova  + "', "
		_cQuery += " 		C1_I_SITWF = '" + _cSITWF 	+ "', "
		_cQuery += " 		C1_I_DTAPR = '" + _sDtLiber + "', "
		_cQuery += " 		C1_I_HRAPR = '" + _cHrLiber + "', "
		_cQuery += " 		C1_I_OBSAP = '" + LEFT(_cObs,Len(SC1->C1_I_OBSAP)) 	+ "' "
		_cQuery += "WHERE"
		_cQuery += " D_E_L_E_T_ = ' '" 
		_cQuery += " AND	C1_FILIAL = '" + _cFilial + "' "
		_cQuery += " AND	C1_NUM    = '" + _cNumSC  + "' " 
		_cQuery += " AND	C1_APROV  = 'B' " 
		_cQuery += " AND    C1_RESIDUO <> 'S' "
		
		If TCSqlExec( _cQuery ) < 0
			FWLogMsg("ERROR"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00309"/*cMsgId*/,"MCOM00309 - TCSqlExec( _cQuery ) : "+_cQuery+" - TCSQLError(): "+AllTrim(TCSQLError())/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	    EndIf

	Case _nOpcao == 5
		//=============================================================
		//Seleciona o último preço de compras do produto através da NFE
		//=============================================================
		BeginSql alias _cAlias
			SELECT D1_VUNIT
			FROM %Table:SD1% SD1
			WHERE D1_FILIAL = %Exp:_cFilial%
			  AND D1_COD = %Exp:_cProduto%
			  AND D1_EMISSAO = (SELECT MAX(D1_EMISSAO) FROM %Table:SD1% WHERE D1_FILIAL = %Exp:_cFilial% AND D1_COD = %Exp:_cProduto% AND D1_TIPO = 'N' AND D_E_L_E_T_ = ' ')
			  AND D1_TIPO = 'N'
			  AND SD1.%notDel%
		EndSql
	//=======================================================================================
	//Atualiza os dados de questionamento
	//=======================================================================================
	Case _nOpcao == 9
    
   		_cQuery := "UPDATE "
		_cQuery += RETSQLNAME("SC1")
		_cQuery += " SET	C1_I_WFID  = '" + _cWFID  	+ "', "
		_cQuery += " 		C1_I_OBSAP = '" + LEFT(_cObs,Len(SC1->C1_I_OBSAP)) 	+ "' "
		_cQuery += "WHERE"
		_cQuery += " D_E_L_E_T_ = ' '" 
		_cQuery += " AND	C1_FILIAL = '" + _cFilial + "' "
		_cQuery += " AND	C1_NUM    = '" + _cNumSC  + "' " 
		_cQuery += " AND	C1_APROV  = 'B' " 
		_cQuery += " AND    C1_RESIDUO <> 'S' "

		If TCSqlExec( _cQuery ) < 0
			FWLogMsg("ERROR"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00310"/*cMsgId*/,"MCOM00310 - TCSqlExec( _cQuery ) : "+_cQuery+" - TCSQLError(): "+AllTrim(TCSQLError())/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	    EndIf

		//Se For questionamento, adiciona questionamento 
		SC1->(DBSetOrder(1))
        SC1->(DBSeek(_cFilial+_cNumSC))

		DBSelectArea("ZY2")

		_cNumQ := GetSxeNum("ZY2","ZY2_CODIGO")

		If Empty(_cPergPai)
			_cPergPai := _cNumQ
		EndIf

		RecLock("ZY2", .T.)
		
		ZY2->ZY2_FILIAL := xFilial("ZY2")
		ZY2->ZY2_CODIGO	:= _cNumQ
		ZY2->ZY2_PEDIDO	:= _cNumSC
		ZY2->ZY2_FILPED	:= _cFilial
		ZY2->ZY2_NIVEL	:= ""
		ZY2->ZY2_DATAM	:= Date()
		ZY2->ZY2_HORAM	:= _cHrLiber
		ZY2->ZY2_WFID	:= _cWFID
		ZY2->ZY2_MENSAG := _cObs
		ZY2->ZY2_TIPO	:= _cAprova
		If _cAprova = "R"//Resposta
		   ZY2->ZY2_USER	:= SC1->C1_I_CDSOL//Solicitante
		Else//PERGUNTA
		   ZY2->ZY2_USER	:= SC1->C1_I_CODAP//Aprovador
		EndIf
		ZY2->ZY2_PAI	:= _cPergPai
		If ZY2->(FIELDPOS("ZY2_ORIGEM")) <> 0
		   ZY2->ZY2_ORIGEM	:= "SC"
		EndIf
		
		ZY2->( MSUnLock() )
		ConfirmSX8()

EndCase

Return

/*
===============================================================================================================================
Programa----------: MCOM003S
Autor-------------: Darcio Ribeiro Sporl
Data da Criacao---: 17/11/2015
Descrição---------: Rotina responsável por montar o formulário de aprovação e o envio do link gerado.
Parametros--------: _cAliasSC1 - Recebe o alias aberto das solicitações de compras
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MCOM003S(_cAliasSC1)

Local nCont		 := 0
Local aAreaSC1	 := (_cAliasSC1)->(GetArea())
Local cEmail	 := ""
Local cLogo		 := _cHostWF + "htm/logo_novo.jpg"
Local aDados	 := {}
Local nI		    := 0
Local _cInves   := ""
Local nVlrTotOrc:= 0
Local _cGet     := GetMV('MV_WFMLBOX')
Local _cAssunto := ""

//Codigo do processo cadastrado no CFG
_cCodProce := "APROVS"
// Arquivo html template utilizado para montagem da aprovação
_cHtmlMode := "\Workflow\htm\sc_aprovador.htm"
// Assunto da mensagem
_cAssunto := "1-Aprovação da Solicitação de Compras Filial " + (_cAliasSC1)->C1_FILIAL + " - " + AllTrim(FWFilialName(cEmpAnt,(_cAliasSC1)->C1_FILIAL,1)) + " SC Número: " + (_cAliasSC1)->C1_NUM
// Inicialize a classe TWFProcess e assinale a variável objeto oProcess:
_oProcess := TWFProcess():New(_cCodProce,"Aprovação da Solicitação de Compras") //PARA O HTML

cFilSC	:= (_cAliasSC1)->C1_FILIAL + " - " + AllTrim(FWFilialName(cEmpAnt, (_cAliasSC1)->C1_FILIAL, 1 ))
cNumSC	:= (_cAliasSC1)->C1_NUM
cSolic	:= (_cAliasSC1)->ZZ7_NOMSOL
dDtEmi	:= DToC(SToD((_cAliasSC1)->C1_EMISSAO))
cAprov	:= (_cAliasSC1)->ZZ7_NOMAPR
cEmail	:= (_cAliasSC1)->C1_I_CODAP
cCcust	:= (_cAliasSC1)->C1_CC + Posicione("CTT",1,xFilial("CTT") + (_cAliasSC1)->C1_CC,"CTT_DESC01")
cObsGen	:= (_cAliasSC1)->C1_I_OBSSC
cAprNom	:= SubStr((_cAliasSC1)->ZZ7_NOMAPR, 1, At(" ", (_cAliasSC1)->ZZ7_NOMAPR)-1)
If (_cAliasSC1)->C1_I_URGEN == "S"
	cUrgen	:= "Sim"
ElseIf (_cAliasSC1)->C1_I_URGEN == "F"
	cUrgen	:= "NF"
Else
	cUrgen	:= "Não"
EndIf
If (_cAliasSC1)->C1_I_APLIC == "C"
	cAplic := "Consumo"
ElseIf (_cAliasSC1)->C1_I_APLIC == "I"
	cAplic := "Investimento"
ElseIf (_cAliasSC1)->C1_I_APLIC == "M"
	cAplic := "Manutenção"
ElseIf (_cAliasSC1)->C1_I_APLIC == "S"
	cAplic := "Serviço"
EndIf

_cInves :=Posicione("ZZI",1,(_cAliasSC1)->C1_FILIAL+(_cAliasSC1)->C1_I_CDINV,"ZZI_DESINV")

While !(_cAliasSC1)->(Eof())
	nCont++	
	//=================================================================
	//Monta a estrutura para envio do workflow de cada pedido de venda
	//=================================================================
	If SubStr(cFilSC,1,2) == (_cAliasSC1)->C1_FILIAL .And. cNumSC == (_cAliasSC1)->C1_NUM

		// Crie uma tarefa.
		If nCont <= 1
			_oProcess:NewTask("Aprovacao_SC", _cHtmlMode)  

			_oProcess:oHtml:ValByName("cLogo"			, cLogo )
			_oProcess:oHtml:ValByName("AprNom"			, cAprNom)
			_oProcess:oHtml:ValByName("Filial"			, cFilSC)
			_oProcess:oHtml:ValByName("NumSC"			, cNumSC)
			_oProcess:oHtml:ValByName("Solicitante"		, cSolic)
			_oProcess:oHtml:ValByName("DtEmissao"  		, dDtEmi)
			_oProcess:oHtml:ValByName("Aprovador"  		, cAprov)
			_oProcess:oHtml:ValByName("Urgente"  		, cUrgen)
			If "Investimento" $ cAplic
				_oProcess:oHtml:ValByName("Aplicacao"   	, cAplic + " - " + _cInves)
			Else
				_oProcess:oHtml:ValByName("Aplicacao"   	, cAplic )
			EndIf
			_oProcess:oHtml:ValByName("CentroCusto"		, cCcust)
			_oProcess:oHtml:ValByName("ObsGen"			, cObsGen)         
			
			If (_cAliasSC1)->C1_I_CLAIM = '1'
	           _oProcess:oHtml:ValByName("cCLAIM"," **CLAIM**")
		    EndIf

		EndIf

		aAdd( _oProcess:oHtml:ValByName("Itens.Item" 		), (_cAliasSC1)->C1_ITEM												)
		aAdd( _oProcess:oHtml:ValByName("Itens.Produto"		), (_cAliasSC1)->C1_PRODUTO + " - " + (_cAliasSC1)->C1_DESCRI			)
		aAdd( _oProcess:oHtml:ValByName("Itens.UM"			), (_cAliasSC1)->C1_UM													)
		aAdd( _oProcess:oHtml:ValByName("Itens.Almox"		), (_cAliasSC1)->BZ_LOCPAD												)
		aAdd( _oProcess:oHtml:ValByName("Itens.Qtde"		), Transform((_cAliasSC1)->C1_QUANT, PesqPict("SC1","C1_QUANT")) 		)

		_cAliasSD1 := GetNextAlias()
		MCOM003Q(5,_cAliasSD1,(_cAliasSC1)->C1_FILIAL,"","","","","","","","",(_cAliasSC1)->C1_PRODUTO)

		DBSelectArea(_cAliasSD1)
		(_cAliasSD1)->(DBGoTop())

		If !(_cAliasSD1)->(Eof())
			aAdd( _oProcess:oHtml:ValByName("Itens.VlrUc"		), Transform((_cAliasSD1)->D1_VUNIT, PesqPict("SD1","D1_VUNIT"))	)
		Else
			aAdd( _oProcess:oHtml:ValByName("Itens.VlrUc"		), Transform(0, PesqPict("SD1","D1_VUNIT"))							)
		EndIf

		DBSelectArea(_cAliasSD1)
		(_cAliasSD1)->(DBCloseArea())

		aAdd( _oProcess:oHtml:ValByName("Itens.DtNeces"		), DToC(SToD((_cAliasSC1)->C1_DATPRF))									)
		aAdd( _oProcess:oHtml:ValByName("Itens.SldAtFil"	), Transform((_cAliasSC1)->B2_QATU, PesqPict("SB2","B2_QATU"))			)
		aAdd( _oProcess:oHtml:ValByName("Itens.SldAtEmp"	), Transform((_cAliasSC1)->QTDTOT , PesqPict("SD3","D3_QUANT"))			)

	    cOrcado:="Vlr. Unit.: "+Transform((_cAliasSC1)->C1_I_ORPRU,PesqPict("SC1","C1_I_ORPRU"))+" // Vlr. Total: "+Transform((_cAliasSC1)->C1_I_ORTOT,PesqPict("SC1","C1_I_ORTOT"))
	    nVlrTotOrc+=(_cAliasSC1)->C1_I_ORTOT
		If !Empty((_cAliasSC1)->C1_OBS)
			aAdd( _oProcess:oHtml:ValByName("Itens.Obs"			), cOrcado+" -- Obs. do Item:" + (_cAliasSC1)->C1_OBS					)
		Else
			aAdd( _oProcess:oHtml:ValByName("Itens.Obs"			),cOrcado																)
		EndIf

        //=========================
        //Dados dos questionamentos
        //=========================
        _cQuest:=U_M004Quest(SubStr(cFilSC,1,2), AllTrim(cNumSC),"SC")
        If !Empty(_cQuest)
        	_oProcess:oHtml:ValByName("cQuest",_cQuest )
        Else
        	_oProcess:oHtml:ValByName("cQuest","" )
        EndIf

		aAreaSC1 := (_cAliasSC1)->(GetArea())

		_cAliasSC7 := GetNextAlias()
		MCOM003Q(2,_cAliasSC7,(_cAliasSC1)->C1_FILIAL,"","","","","","","","",(_cAliasSC1)->C1_PRODUTO)

		DBSelectArea(_cAliasSC7)
		(_cAliasSC7)->(DBGoTop())

		If !Empty((_cAliasSC7)->C7_PRODUTO) 
		   If aScan(aDados,{|P| P[11] == (_cAliasSC7)->C7_PRODUTO } ) = 0//AWF-07/06/16
			  aAdd(aDados,{	"Produto: " + (_cAliasSC7)->C7_PRODUTO + " - " + (_cAliasSC7)->C7_DESCRI,;						// [01] Descricao do Produto
							(_cAliasSC7)->C7_NUM,;																			// [02] Número do Pedido
							(_cAliasSC7)->C7_ITEM,;																			// [03] Item do produto
							(_cAliasSC7)->C7_FORNECE + "/" + (_cAliasSC7)->C7_LOJA + " - " + (_cAliasSC7)->C7_I_NFORN,; 	// [04] Dados Fornecedor
							Transform((_cAliasSC7)->C7_QUANT, PesqPict("SC7","C7_QUANT")),;									// [05] Quantidade
							(_cAliasSC7)->C7_UM,;																			// [06] Unidade de Medida
							(_cAliasSC7)->B1_CONV,;																			// [07] Fator de conversão
							Transform((_cAliasSC7)->C7_PRECO, PesqPict("SC7","C7_PRECO")),;									// [08] Preço unitário
							Transform((_cAliasSC7)->C7_TOTAL , PesqPict("SC7","C7_TOTAL")),;								// [09] Valor Total
							DToC(SToD((_cAliasSC7)->C7_EMISSAO)),;                           	                            // [10] Data de Emissão
							(_cAliasSC7)->C7_PRODUTO})														                // [11] Codigo item//AWF-07/06/16 
			EndIf
		EndIf

		DBSelectArea(_cAliasSC7)
		(_cAliasSC7)->(DBCloseArea())

		FWRestArea(aAreaSC1)
    
    Else
    
    	If Len(aDados) > 0
	    	For nI := 1 To Len(aDados)
	    		aAdd( _oProcess:oHtml:ValByName("ItensPC1.Prodpc" 		), aDados[nI][01]	)
				aAdd( _oProcess:oHtml:ValByName("ItensPC1.Numpc"		), aDados[nI][02]	)
				aAdd( _oProcess:oHtml:ValByName("ItensPC1.Itempc"		), aDados[nI][03]	)
				aAdd( _oProcess:oHtml:ValByName("ItensPC1.Fornecpc" 	), aDados[nI][04]	)
				aAdd( _oProcess:oHtml:ValByName("ItensPC1.Quantpc"		), aDados[nI][05] 	)
				aAdd( _oProcess:oHtml:ValByName("ItensPC1.UMpc"			), aDados[nI][06]  	)
				aAdd( _oProcess:oHtml:ValByName("ItensPC1.Qtdepc"		), aDados[nI][07]	)
				aAdd( _oProcess:oHtml:ValByName("ItensPC1.Valorpc"		), aDados[nI][08]	)
				aAdd( _oProcess:oHtml:ValByName("ItensPC1.Totalpc"		), aDados[nI][09]	)
				aAdd( _oProcess:oHtml:ValByName("ItensPC1.Emissaopc"	), aDados[nI][10]	)
	    	Next nI
	    	aDados:={}//Depois que gravau no htm zera para nao acumalar da proxima SC //AWF-07/06/16
		Else	
			aAdd( _oProcess:oHtml:ValByName("ItensPC1.Prodpc" 		), "")
			aAdd( _oProcess:oHtml:ValByName("ItensPC1.Numpc"		), "")
			aAdd( _oProcess:oHtml:ValByName("ItensPC1.Itempc"		), "")
			aAdd( _oProcess:oHtml:ValByName("ItensPC1.Fornecpc" 	), "")
			aAdd( _oProcess:oHtml:ValByName("ItensPC1.Quantpc"		), "")
			aAdd( _oProcess:oHtml:ValByName("ItensPC1.UMpc"			), "")
			aAdd( _oProcess:oHtml:ValByName("ItensPC1.Qtdepc"		), "")
			aAdd( _oProcess:oHtml:ValByName("ItensPC1.Valorpc"		), "")
			aAdd( _oProcess:oHtml:ValByName("ItensPC1.Totalpc"		), "")
			aAdd( _oProcess:oHtml:ValByName("ItensPC1.Emissaopc"	), "")
		EndIf

		_oProcess:oHtml:ValByName("VlrTotOrc",Transform(nVlrTotOrc,PesqPict("SC1","C1_I_ORTOT")))
		nVlrTotOrc:=0

		_oProcess:oHtml:ValByName("cLogo"			, cLogo )
        //=========================================================================
		// Informe o nome da função de retorno a ser executada quando a mensagem de
		// respostas retornar ao Workflow:
		//=========================================================================
		_oProcess:bReturn := "U_MCOM003R"
		
		//========================================================================
		// Após ter repassado todas as informacões necessárias para o Workflow,
		// execute o método Start() para gerar todo o processo e enviar a mensagem
		// ao destinatário.
        //========================================================================
    	_cMailID := _oProcess:Start("\workflow\emp01")//PARA O HTML

		If File("\workflow\emp01\" + _cMailID + ".htm")
			FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00311"/*cMsgId*/,"MCOM00311 - Arquivo da Task " + CVALTOCHAR(nCont) + " copiado com sucesso."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		EndIf 

		//==================================================================
   		// "LINK"
		//==================================================================
		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00312"/*cMsgId*/,"MCOM00312 - Email da Task: "+CVALTOCHAR(nCont)/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00313"/*cMsgId*/,"MCOM00313 - "+UsrRetMail(cEmail)/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

		//====================================
		//Codigo do processo cadastrado no CFG
		//====================================
		_cCodProce := "APROVS"

		//===========================================================
		// Arquivo html template utilizado para montagem da aprovação
		//===========================================================
		_cHtmlMode := "\Workflow\htm\sc_aprovador.htm"

		//====================
		// Assunto da mensagem
		//====================
		_cAssunto := "2-Aprovação da Solicitação de Compras Filial " + cFilSC + " SC Número: " + cNumSC

		//======================================================================
		// Inicialize a classe TWFProcess e assinale a variável objeto oProcess:
		//======================================================================
		_oProcess := TWFProcess():New(_cCodProce,"Aprovação da Solicitação de Compras")//Para E-MAIL

		//=================================================================
		// Criamos o link para o arquivo que foi gerado na tarefa anterior.  
		//=================================================================
		_oProcess:NewTask("LINK", "\workflow\htm\sc_link.htm")

		chtmlfile := _cMailID + ".htm"
		cMailTo	:= "mailto:" + AllTrim(Posicione("WF7", 1, xFilial("WF7") + AllTrim(_cGet), "WF7_ENDERE"))
		chtmltexto := wfloadfile("\workflow\emp01\" + chtmlfile )
		chtmltexto := StrTran( chtmltexto, cmailto, "WFHTTPRET.APL" )
		wfsavefile("\workflow\emp"+cEmpAnt+"\" + chtmlfile, chtmltexto)

		cLink := _cHostWF + "emp01/" + _cMailID + ".htm"

		//=====================================
		// Populo as variáveis do template html
		//=====================================
		_oProcess:oHtml:ValByName("cLogo"	, cLogo 	)
		_oProcess:oHtml:ValByName("AprNom"	, cAprNom	)
		_oProcess:oHtml:ValByName("A_LINK"	, cLink		)
		_oProcess:oHtml:ValByName("A_SOLIC"	, cSolic	)
		_oProcess:oHtml:ValByName("A_CUSTO"	, cCcust	)
		_oProcess:oHtml:ValByName("A_URGEN"	, cUrgen	)
		_oProcess:oHtml:ValByName("A_INVES"	, _cInves	)
		_oProcess:oHtml:ValByName("A_EMAIL"	, "Filial: " + cFilSC + " SC Número: " + cNumSC	)
		_oProcess:oHtml:ValByName("A_OBSSC"	, cObsGen	)

		//================================================================
		// Informamos o destinatário (aprovador) do email contendo o link.  
		//================================================================
		_oProcess:cTo := UsrRetMail(cEmail)

		//===============================
		// Informamos o assunto do email.  
		//===============================
		_oProcess:cSubject	:= FWHttpEncode(_cAssunto)

		_cMailID	:= _oProcess:fProcessId
		_cTaskID	:= _oProcess:fTaskID
		RastreiaWF(_cMailID + '.' + _cTaskID , _oProcess:fProcCode, "1001", "Recebimento da Aprovacao da SC", "")

		//=======================================================
		// Iniciamos a tarefa e enviamos o email ao destinatário.
		//=======================================================  FIM DO ENVIO DA PRIMIERA SC
		_oProcess:Start() //PARA O E-MAIL

		//==================================
		//Fim do trecho para criacao do link
		//==================================
		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00314"/*cMsgId*/,"MCOM00314 - Email com link da Task: "+CVALTOCHAR(nCont)+" enviado com sucesso!"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		
		//=============================================================
		//Atualiza o sistema com as informações do WFID, SITWF e IDHTML
		//=============================================================
		MCOM003Q(3,"",SubStr(cFilSC,1,2),cNumSC,"1001","2",cLink,"","","","","")

		//====================================
		//Codigo do processo cadastrado no CFG
		//====================================
		_cCodProce := "APROVS"

		//===========================================================
		// Arquivo html template utilizado para montagem da aprovação
		//===========================================================
		_cHtmlMode := "\Workflow\htm\sc_aprovador.htm"

		//====================
		// Assunto da mensagem
		//====================
		_cAssunto := "3-Aprovação da Solicitação de Compras Filial " + cFilSC + " SC Número: " + (_cAliasSC1)->C1_NUM

		//======================================================================
		// Inicialize a classe TWFProcess e assinale a variável objeto oProcess:
		//======================================================================   INICIO DO ENVIO DA PROXIMA SC
		_oProcess := TWFProcess():New(_cCodProce,"Aprovação da Solicitação de Compras") //PARA O HTML

		_oProcess:NewTask("Aprovacao_SC", _cHtmlMode)

        cCcust	:= (_cAliasSC1)->C1_CC + Posicione("CTT",1,xFilial("CTT") + (_cAliasSC1)->C1_CC,"CTT_DESC01")
        cObsGen	:= (_cAliasSC1)->C1_I_OBSSC
    	cFilSC	:= (_cAliasSC1)->C1_FILIAL + " - " + AllTrim(FWFilialName(cEmpAnt, (_cAliasSC1)->C1_FILIAL, 1 ))
		cNumSC	:= (_cAliasSC1)->C1_NUM
		cSolic	:= (_cAliasSC1)->ZZ7_NOMSOL
		dDtEmi	:= DToC(SToD((_cAliasSC1)->C1_EMISSAO))
		cAprov	:= (_cAliasSC1)->ZZ7_NOMAPR
		cAprNom	:= SubStr((_cAliasSC1)->ZZ7_NOMAPR, 1, At(" ", (_cAliasSC1)->ZZ7_NOMAPR)-1)
		If (_cAliasSC1)->C1_I_URGEN == "S"
			cUrgen	:= "Sim"
        ElseIf (_cAliasSC1)->C1_I_URGEN == "F"
	        cUrgen	:= "NF"
		Else
			cUrgen	:= "Não"
		EndIf
		If (_cAliasSC1)->C1_I_APLIC == "C"
			cAplic := "Consumo"
		ElseIf (_cAliasSC1)->C1_I_APLIC == "I"
			cAplic := "Investimento"
		ElseIf (_cAliasSC1)->C1_I_APLIC == "M"
			cAplic := "Manutenção"
		ElseIf (_cAliasSC1)->C1_I_APLIC == "S"
			cAplic := "Serviço"
		EndIf
		_cInves :=Posicione("ZZI",1,(_cAliasSC1)->C1_FILIAL+(_cAliasSC1)->C1_I_CDINV,"ZZI_DESINV")

		cReavaliar := ""		
		If (_cAliasSC1)->C1_I_CLAIM = '1'
			cReavaliar:=cReavaliar+" **CLAIM**"
		EndIf
		If (_cAliasSC1)->C1_I_APLIC == "I"
			cReavaliar:=cReavaliar+" **INVESTIMENTO**"
		EndIf
        _oProcess:oHtml:ValByName("cCLAIM",cReavaliar)

		_oProcess:oHtml:ValByName("cLogo"			, cLogo )
		_oProcess:oHtml:ValByName("AprNom"			, cAprNom)
		_oProcess:oHtml:ValByName("Filial"			, cFilSC)
		_oProcess:oHtml:ValByName("NumSC"			, cNumSC)
		_oProcess:oHtml:ValByName("Solicitante"		, cSolic)
		_oProcess:oHtml:ValByName("DtEmissao"  		, dDtEmi)
		_oProcess:oHtml:ValByName("Aprovador"  		, cAprov)
		_oProcess:oHtml:ValByName("Urgente"  		, cUrgen)
		If "Investimento" $ cAplic
			_oProcess:oHtml:ValByName("Aplicacao"   	, cAplic + " - " + _cInves)
		Else
			_oProcess:oHtml:ValByName("Aplicacao"   	, cAplic )
		EndIf
		_oProcess:oHtml:ValByName("CentroCusto"		, cCcust)
		_oProcess:oHtml:ValByName("ObsGen"			, cObsGen)

		aAdd( _oProcess:oHtml:ValByName("Itens.Item" 		), (_cAliasSC1)->C1_ITEM												)
		aAdd( _oProcess:oHtml:ValByName("Itens.Produto"		), (_cAliasSC1)->C1_PRODUTO + " - " + (_cAliasSC1)->C1_DESCRI			)
		aAdd( _oProcess:oHtml:ValByName("Itens.UM"			), (_cAliasSC1)->C1_UM													)
		aAdd( _oProcess:oHtml:ValByName("Itens.Almox"		), (_cAliasSC1)->BZ_LOCPAD												)
		aAdd( _oProcess:oHtml:ValByName("Itens.Qtde"		), Transform((_cAliasSC1)->C1_QUANT, PesqPict("SC1","C1_QUANT")) 		)

		_cAliasSD1 := GetNextAlias()
		MCOM003Q(5,_cAliasSD1,(_cAliasSC1)->C1_FILIAL,"","","","","","","","",(_cAliasSC1)->C1_PRODUTO)

		DBSelectArea(_cAliasSD1)
		(_cAliasSD1)->(DBGoTop())

		If !(_cAliasSD1)->(Eof())
			aAdd( _oProcess:oHtml:ValByName("Itens.VlrUc"		), Transform((_cAliasSD1)->D1_VUNIT, PesqPict("SD1","D1_VUNIT"))	)
		Else
			aAdd( _oProcess:oHtml:ValByName("Itens.VlrUc"		), Transform(0, PesqPict("SD1","D1_VUNIT"))							)
		EndIf

		DBSelectArea(_cAliasSD1)
		(_cAliasSD1)->(DBCloseArea())

		aAdd( _oProcess:oHtml:ValByName("Itens.DtNeces"		), DToC(SToD((_cAliasSC1)->C1_DATPRF))									)
		aAdd( _oProcess:oHtml:ValByName("Itens.SldAtFil"	), Transform((_cAliasSC1)->B2_QATU, PesqPict("SB2","B2_QATU"))			)
		aAdd( _oProcess:oHtml:ValByName("Itens.SldAtEmp"	), Transform((_cAliasSC1)->QTDTOT , PesqPict("SD3","D3_QUANT"))			)
		
   	    cOrcado:="Vlr. Unit.: "+Transform((_cAliasSC1)->C1_I_ORPRU,PesqPict("SC1","C1_I_ORPRU"))+" // Vlr. Total: "+Transform((_cAliasSC1)->C1_I_ORTOT,PesqPict("SC1","C1_I_ORTOT"))
	    nVlrTotOrc+=(_cAliasSC1)->C1_I_ORTOT
		If !Empty((_cAliasSC1)->C1_OBS)
			aAdd( _oProcess:oHtml:ValByName("Itens.Obs"			), cOrcado+" -- Obs. do Item:" + (_cAliasSC1)->C1_OBS)
		Else
			aAdd( _oProcess:oHtml:ValByName("Itens.Obs"			), cOrcado															)
		EndIf

		cEmail	:= (_cAliasSC1)->C1_I_CODAP

		aAreaSC1 := (_cAliasSC1)->(GetArea())

		_cAliasSC7 := GetNextAlias()
		MCOM003Q(2,_cAliasSC7,(_cAliasSC1)->C1_FILIAL,"","","","","","","","",(_cAliasSC1)->C1_PRODUTO)

		DBSelectArea(_cAliasSC7)
		(_cAliasSC7)->(DBGoTop())

		If !Empty((_cAliasSC7)->C7_PRODUTO)
    	   If aScan(aDados,{|P| P[11] == (_cAliasSC7)->C7_PRODUTO } ) = 0//AWF-07/06/16
		      aAdd(aDados,{	"Produto: " + (_cAliasSC7)->C7_PRODUTO + " - " + (_cAliasSC7)->C7_DESCRI,;						// [01] Descricao do Produto
							(_cAliasSC7)->C7_NUM,;																			// [02] Número do Pedido
							(_cAliasSC7)->C7_ITEM,;																			// [03] Item do produto
							(_cAliasSC7)->C7_FORNECE + "/" + (_cAliasSC7)->C7_LOJA + " - " + (_cAliasSC7)->C7_I_NFORN,; 	// [04] Dados Fornecedor
							Transform((_cAliasSC7)->C7_QUANT, PesqPict("SC7","C7_QUANT")),;									// [05] Quantidade
							(_cAliasSC7)->C7_UM,;																			// [06] Unidade de Medida
							(_cAliasSC7)->B1_CONV,;																			// [07] Fator de conversão
							Transform((_cAliasSC7)->C7_PRECO, PesqPict("SC7","C7_PRECO")),;									// [08] Preço unitário
							Transform((_cAliasSC7)->C7_TOTAL , PesqPict("SC7","C7_TOTAL")),;								// [09] Valor Total
							DToC(SToD((_cAliasSC7)->C7_EMISSAO)),;                           	                            // [10] Data de Emissão
							(_cAliasSC7)->C7_PRODUTO})																		// [11] Cod do produto//AWF-07/06/16
           EndIf
		EndIf
	
		DBSelectArea(_cAliasSC7)
		(_cAliasSC7)->(DBCloseArea())

		FWRestArea(aAreaSC1)
	EndIf
	
	(_cAliasSC1)->(DBSkip())
End

If Len(aDados) > 0
	For nI := 1 To Len(aDados)
		aAdd( _oProcess:oHtml:ValByName("ItensPC1.Prodpc" 		), aDados[nI][01]	)
		aAdd( _oProcess:oHtml:ValByName("ItensPC1.Numpc"		), aDados[nI][02]	)
		aAdd( _oProcess:oHtml:ValByName("ItensPC1.Itempc"		), aDados[nI][03]	)
		aAdd( _oProcess:oHtml:ValByName("ItensPC1.Fornecpc" 	), aDados[nI][04]	)
		aAdd( _oProcess:oHtml:ValByName("ItensPC1.Quantpc"		), aDados[nI][05] 	)
		aAdd( _oProcess:oHtml:ValByName("ItensPC1.UMpc"			), aDados[nI][06]  	)
		aAdd( _oProcess:oHtml:ValByName("ItensPC1.Qtdepc"		), aDados[nI][07]	)
		aAdd( _oProcess:oHtml:ValByName("ItensPC1.Valorpc"		), aDados[nI][08]	)
		aAdd( _oProcess:oHtml:ValByName("ItensPC1.Totalpc"		), aDados[nI][09]	)
 		aAdd( _oProcess:oHtml:ValByName("ItensPC1.Emissaopc"	), aDados[nI][10]	)
   	Next nI
Else	
	aAdd( _oProcess:oHtml:ValByName("ItensPC1.Prodpc" 		), "")
	aAdd( _oProcess:oHtml:ValByName("ItensPC1.Numpc"		), "")
	aAdd( _oProcess:oHtml:ValByName("ItensPC1.Itempc"		), "")
	aAdd( _oProcess:oHtml:ValByName("ItensPC1.Fornecpc" 	), "")
	aAdd( _oProcess:oHtml:ValByName("ItensPC1.Quantpc"		), "")
	aAdd( _oProcess:oHtml:ValByName("ItensPC1.UMpc"			), "")
	aAdd( _oProcess:oHtml:ValByName("ItensPC1.Qtdepc"		), "")
	aAdd( _oProcess:oHtml:ValByName("ItensPC1.Valorpc"		), "")
	aAdd( _oProcess:oHtml:ValByName("ItensPC1.Totalpc"		), "")
	aAdd( _oProcess:oHtml:ValByName("ItensPC1.Emissaopc"	), "")
EndIf

_oProcess:oHtml:ValByName("VlrTotOrc",Transform(nVlrTotOrc,PesqPict("SC1","C1_I_ORTOT")))
nVlrTotOrc:=0

_oProcess:oHtml:ValByName("cLogo"			, cLogo )

_oProcess:cTo := NIL
	
//===============================================================================================
//Grava nome da task e email do aprovador no array aParams
//A propriedade "aParams" (Array) serve para armazenar qualquer tipo de informacao para controle.
//===============================================================================================  
aAdd(_oProcess:aParams, { _oProcess:FTaskID, UsrRetMail(cEmail) }) 

//================================
// respostas retornar ao Workflow:
//================================
_oProcess:bReturn := "U_MCOM003R"
	
_cMailID := _oProcess:Start("\workflow\emp01")//GRAVA O HTML
	
If File("\workflow\emp01\" + _cMailID + ".htm")
	FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00315"/*cMsgId*/,"MCOM00315 - Arquivo da Task " + CVALTOCHAR(nCont) + " copiado com sucesso."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
EndIf 
FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00316"/*cMsgId*/,"MCOM00316 - Email da Task: "+CVALTOCHAR(nCont)/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00317"/*cMsgId*/,"MCOM00317 - "+UsrRetMail(cEmail)/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)	

//====================================
//Codigo do processo cadastrado no CFG
//====================================
_cCodProce := "APROVS"

//===========================================================
// Arquivo html template utilizado para montagem da aprovação
//===========================================================
_cHtmlMode := "\Workflow\htm\sc_aprovador.htm"

//====================
// Assunto da mensagem
//====================
_cAssunto := "4-Aprovação da Solicitação de Compras Filial " + cFilSC + " SC Número: " + cNumSC

//======================================================================
// Inicialize a classe TWFProcess e assinale a variável objeto oProcess:
//======================================================================
_oProcess := TWFProcess():New(_cCodProce,"Aprovação da Solicitação de Compras")//CRIA PARA O ENVIO DO E-MAIL

chtmlfile := _cMailID + ".htm"
cMailTo	:= "mailto:" + AllTrim(Posicione("WF7", 1, xFilial("WF7") + AllTrim(GetMV('MV_WFMLBOX')), "WF7_ENDERE"))
chtmltexto := wfloadfile("\workflow\emp01\" + chtmlfile )
chtmltexto := StrTran( chtmltexto, cmailto, "WFHTTPRET.APL" )
wfsavefile("\workflow\emp"+cEmpAnt+"\" + chtmlfile, chtmltexto) // grava novamente com as alteracoes necessarias.

//=================================================================
// Criamos o link para o arquivo que foi gerado na tarefa anterior.  
//=================================================================
_oProcess:NewTask("LINK", "\workflow\htm\sc_link.htm")
	
cLink := _cHostWF + "emp01/" + _cMailID + ".htm"

_oProcess:oHtml:ValByName("A_LINK"	, cLink		)
_oProcess:oHtml:ValByName("cLogo"	, cLogo		)
_oProcess:oHtml:ValByName("AprNom"	, cAprNom	)
_oProcess:oHtml:ValByName("A_SOLIC"	, cSolic	)
_oProcess:oHtml:ValByName("A_CUSTO"	, cCcust	)
_oProcess:oHtml:ValByName("A_URGEN"	, cUrgen	)
_oProcess:oHtml:ValByName("A_INVES"	, _cInves	)
_oProcess:oHtml:ValByName("A_EMAIL"	, "Filial: " + cFilSC + " SC Número: " + cNumSC	)
_oProcess:oHtml:ValByName("A_OBSSC"	, cObsGen	)

//================================================================
// Informamos o destinatário (Aprovador) do email contendo o link.  
//================================================================
_oProcess:cTo := UsrRetMail(cEmail)

//===============================
// Informamos o assunto do email.  
//===============================
_oProcess:cSubject	:= FWHttpEncode(_cAssunto)

_cMailID	:= _oProcess:fProcessId
_cTaskID	:= _oProcess:fTaskID

//=======================================================
// Iniciamos a tarefa e enviamos o email ao destinatário.
//=======================================================
_oProcess:Start() //ENVIA O E-MAIL

FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00318"/*cMsgId*/,"MCOM00318 - Email enviado para: " + UsrRetMail(cEmail) + ", enviado com sucesso!"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

//=============================================================
//Atualiza o sistema com as informações do WFID, SITWF e IDHTML
//=============================================================
MCOM003Q(3,"",SubStr(cFilSC,1,2),cNumSC,"1001","2",cLink,"","","","","")
Return

/*
===============================================================================================================================
Programa----------: MCOM003E
Autor-------------: Darcio Ribeiro Sporl
Data da Criacao---: 18/11/2015
Descrição---------: Rotina responsável por atualizar a flag de reenvio do workflow
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MCOM003E()

Local aArea		:= FWGetArea()
Local cFilSC	:= SC1->C1_FILIAL
Local cNumSC	:= SC1->C1_NUM
Local cQuery	:= ""

If SC1->C1_APROV == 'B'
	cQuery := "UPDATE "
	cQuery += RETSQLNAME("SC1")
	cQuery += " SET	C1_I_SITWF	= '1', "
	cQuery += "		C1_I_HTM	= ' ', "
	cQuery += "		C1_I_WFID	= ' ' " 
	cQuery += "WHERE"
	cQuery += " D_E_L_E_T_ = ' '" 
	cQuery += " AND	C1_FILIAL = '" + cFilSC + "' "
	cQuery += " AND	C1_NUM    = '" + cNumSC + "' "

	If TCSqlExec( cQuery ) < 0
	   MsgAlert("Esta solicitação não pode ser reenviada, pois ocorreu um erro: TCSQLError(): "+AllTrim(TCSQLError()))
	Else
	   MsgInfo("Solicitação preparada para reenvio.")		
	EndIf

Else
	MsgAlert("Esta solicitação não pode ser reenviada, pois esta encontra-se Liberada ou Rejeitada.")
EndIf

FWRestArea(aArea)
Return

/*
===============================================================================================================================
Programa----------: MCOM003L
Autor-------------: Darcio Ribeiro Sporl
Data da Criacao---: 19/11/2015
===============================================================================================================================
Descrição---------: Rotina responsável por montar a lista de SC's por Aprovador e enviar por e-mail
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MCOM003L()

Local cQryZZ7		:= ""
Local cQrySC1		:= ""
Local lWFHTML		:= .T.
Local _cCodProce	:= ""
Local _cHtmlMode	:= ""
Local _cAssunto	:= ""
Local _cMailId		:= ""
Local cAplic		:= ""
Local _cTaskID		:= ""
Local _oProcess
Local _cGet			:= ""

Private _cHostWF	:= ""
Private _dDtIni	:= ""
Private cLogo		:= ""

FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00319"/*cMsgId*/,'MCOM00319 - Gerando envio do workflow das solicitações de compras aos aprovadores na data: ' + DToC(Date()) + ' - ' + Time()/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

_cHostWF	:= SuperGetMV("IT_WFHOSTS",.T.,"http://wfteste.italac.com.br:4034/")
_dDtIni		:= DToS(SuperGetMV("IT_WFDTINI",.F.,"26/11/2025"))
cLogo		:= _cHostWF + "htm/logo_novo.jpg"
_cGet		:= GetMV('MV_WFMLBOX')


lWFHTML	:= GetMv("MV_WFHTML")

PutMV("MV_WFHTML",.T.)

cQryZZ7 := "SELECT DISTINCT ZZ7_CODUSR, ZZ7_USER, ZZ7_NOME "
cQryZZ7 += "FROM " + RetSqlName("ZZ7") + " ZZ7, " + RetSqlName("SC1") + " SC1 "
cQryZZ7 += "WHERE ZZ7_TIPO = 'A' "
cQryZZ7 += "  AND C1_I_CODAP = ZZ7_CODUSR "
cQryZZ7 += "  AND ZZ7.D_E_L_E_T_ = ' ' "
cQryZZ7 += "  AND SC1.D_E_L_E_T_ = ' ' "
cQryZZ7 += "  AND C1_EMISSAO >= '" + _dDtIni + "' "
cQryZZ7 += "  AND C1_I_SITWF = '2' "
cQryZZ7 += "  AND C1_APROV = 'B' "
cQryZZ7 += "  AND C1_RESIDUO <> 'S' "
cQryZZ7 += "ORDER BY ZZ7_CODUSR "

cQryZZ7 := ChangeQuery(cQryZZ7)
MPSysOpenQuery(cQryZZ7,"TRBZZ7")

DBSelectArea("TRBZZ7")
TRBZZ7->(DBGoTop())

While !TRBZZ7->(Eof())

	cAprNom	:= SubStr(TRBZZ7->ZZ7_NOME, 1, At(" ", TRBZZ7->ZZ7_NOME)-1)

	//====================================
	//Codigo do processo cadastrado no CFG
	//====================================
	_cCodProce := "APROVS"

	//===========================================================
	// Arquivo html template utilizado para montagem da aprovação
	//===========================================================
	_cHtmlMode := "\Workflow\htm\sc_aprovador.htm"

	//====================
	// Assunto da mensagem
	//====================
	_cAssunto := "5-Aprovação da Solicitação de Compras Filial "

	//======================================================================
	// Inicialize a classe TWFProcess e assinale a variável objeto oProcess:
	//======================================================================
	_oProcess := TWFProcess():New(_cCodProce,"Aprovação da Solicitação de Compras")
		
	_oProcess:NewTask("LINK", "\workflow\htm\sc_lista.htm")

	_cMailId	:= _oProcess:fProcessId
	_cTaskID	:= _oProcess:fTaskID

	chtmlfile	:= _cMailID + ".htm"
	cMailTo		:= "mailto:" + AllTrim(Posicione("WF7", 1, xFilial("WF7") + AllTrim(_cGet), "WF7_ENDERE"))
	chtmltexto	:= wfloadfile("\workflow\emp01\" + chtmlfile )
	chtmltexto	:= StrTran( chtmltexto, cmailto, "WFHTTPRET.APL" )
	wfsavefile("\workflow\emp"+cEmpAnt+"\" + chtmlfile, chtmltexto)

	_oProcess:oHtml:ValByName("cLogo"	, cLogo		)
	_oProcess:oHtml:ValByName("AprNom"	, cAprNom	)
			
	RastreiaWF(_cMailID + '.' + _cTaskID , _oProcess:fProcCode, "1001", "Recebimento da Aprovacao da SC", "")

	cQrySC1 := "SELECT DISTINCT C1_NUM, C1_FILIAL, C1_CC, C1_I_CDSOL, C1_I_URGEN, C1_I_CDINV, C1_I_APLIC, C1_I_HTM, ZZ7_NOME, ZZI_DESINV "
	cQrySC1 += "FROM " + RetSqlName("SC1") + " SC1 "
	cQrySC1 += "LEFT JOIN " + RetSqlName("ZZ7") + " ZZ7 ON ZZ7_FILIAL = C1_FILIAL AND ZZ7_CODUSR = C1_I_CDSOL AND ZZ7.D_E_L_E_T_ = ' ' "
	cQrySC1 += "LEFT JOIN " + RetSqlName("ZZI") + " ZZI ON ZZI_FILIAL = C1_FILIAL AND ZZI_CODINV = C1_I_CDINV AND ZZI.D_E_L_E_T_ = ' ' "
	cQrySC1 += "WHERE C1_I_CODAP = '" + TRBZZ7->ZZ7_CODUSR + "' "
	cQrySC1 += "  AND C1_EMISSAO >= '" + _dDtIni + "' "
	cQrySC1 += "  AND C1_I_SITWF = '2' "
	cQrySC1 += "  AND C1_APROV = 'B' "
	cQrySC1 += "  AND C1_RESIDUO <> 'S' "
	cQrySC1 += "  AND SC1.D_E_L_E_T_ = ' ' "
	cQrySC1 += "ORDER BY C1_FILIAL, C1_NUM " 

	cQrySC1 := ChangeQuery(cQrySC1)
	MPSysOpenQuery(cQrySC1,"TRBSC1")

	DBSelectArea("TRBSC1")
	TRBSC1->(DBGoTop())

	While !TRBSC1->(Eof())
		
		If TRBSC1->C1_I_APLIC == "C"
			cAplic := "Consumo"
		ElseIf TRBSC1->C1_I_APLIC == "I"
			cAplic := "Investimento"
		ElseIf TRBSC1->C1_I_APLIC == "M"
			cAplic := "Manutenção"
		ElseIf TRBSC1->C1_I_APLIC == "S"
			cAplic := "Serviço"
		EndIf
		
		aAdd( _oProcess:oHtml:ValByName("itens.FILIAL")	, TRBSC1->C1_FILIAL + " - " + AllTrim(FWFilialName(cEmpAnt,TRBSC1->C1_FILIAL,1)))
		aAdd( _oProcess:oHtml:ValByName("itens.NUMSC")	, TRBSC1->C1_NUM																)
		aAdd( _oProcess:oHtml:ValByName("itens.SOLIC")	, TRBSC1->ZZ7_NOME																)
		aAdd( _oProcess:oHtml:ValByName("itens.CUSTO")	, TRBSC1->C1_CC																	)
		If TRBSC1->C1_I_URGEN == 'S'
			aAdd( _oProcess:oHtml:ValByName("itens.URGEN")	, "Sim"																		)
		ElseIf TRBSC1->C1_I_URGEN == 'N'
			aAdd( _oProcess:oHtml:ValByName("itens.URGEN")	, "NF"																		)
		Else
			aAdd( _oProcess:oHtml:ValByName("itens.URGEN")	, "Não"																		)
		EndIf
		aAdd( _oProcess:oHtml:ValByName("itens.INVES")	, cAplic + " " + TRBSC1->ZZI_DESINV												)
		aAdd( _oProcess:oHtml:ValByName("itens.LINK")	, AllTrim(TRBSC1->C1_I_HTM)														)

		TRBSC1->(DBSkip())
	End

	//====================================================
	// Informamos o destinatário do email contendo o link.  
	//====================================================
	_oProcess:cTo := UsrRetMail(TRBZZ7->ZZ7_CODUSR)

	//===============================
	// Informamos o assunto do email.  
	//===============================
	_oProcess:cSubject	:= FWHttpEncode(_cAssunto)

	_cMailID	:= _oProcess:fProcessId
	_cTaskID	:= _oProcess:fTaskID
	RastreiaWF(_cMailID + '.' + _cTaskID , _oProcess:fProcCode, "1001", "Recebimento da Aprovacao da SC", "")

	//=======================================================
	// Iniciamos a tarefa e enviamos o email ao destinatário.
	//=======================================================
	_oProcess:Start()

	DBSelectArea("TRBSC1")
	TRBSC1->(DBCloseArea())

	TRBZZ7->(DBSkip())
End

DBSelectArea("TRBZZ7")
TRBZZ7->(DBCloseArea())

PutMV("MV_WFHTML",lWFHTML)

FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00320"/*cMsgId*/,'MCOM00320 - Termino do envio do workflow das solicitações de compras na data: ' + DToC(Date()) + ' - ' + Time()/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

Return

/*
===============================================================================================================================
Programa----------: MCOM003A
Autor-------------: Alex Wallauer
Data da Criacao---: 07/06/2016
Descrição---------: Função criada aviso ao Solicitante para enviar e-mail de Aprovacao ou Rejeição
Parametros--------: _oProcess - Processo inicializado do workflow
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MCOM003A(_oProcess)

Local _cFilName := _oProcess:oHtml:RetByName("Filial")
Local _cFilSC	 := SubStr(_cFilName,1,2)
Local _cNumSC	 := _oProcess:oHtml:RetByName("NumSC")    
Local _cAprova	 := Upper(_oProcess:oHtml:RetByName("opcao"))        
Local _cObs		 := AllTrim(Upper(_oProcess:oHtml:RetByName("CR_OBS")))
Local _sDtLiber := DToS(Date())
Local _cHrLiber := SubStr(Time(),1,5)
Local _cHostWF  := SuperGetMV("IT_WFHOSTS",.T.,"http://wfteste.italac.com.br:4034/")
Local _cLogo	 := _cHostWF + "htm/logo_novo.jpg"
Local _cSolic   := ""
Local _cAprNom  := ""
Local _cInves   := ""
Local _cCcust   := ""
Local _cUrgen   := ""
Local _cEmail	 := ""
Local _cAssunto := ""

FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00321"/*cMsgId*/,"MCOM00321 - /////////////////   INCIO DA MCOM003A   /////////////////////////////////////////////////////////////////////////////////"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

//======================================================================
// Inicialize a classe TWFProcess e assinale a variável objeto oProcess:
//======================================================================
_oProcess := TWFProcess():New("APROVS","Aprovação da Solicitação de Compras")//CRIA PARA O ENVIO DO E-MAIL

//=================================================================
// Criamos o link para o arquivo que foi gerado na tarefa anterior.  
//=================================================================
_oProcess:NewTask("LINK", "\workflow\htm\sc_solicitante.htm")

SC1->(DBSetOrder(1))
SC1->(DBSeek(_cFilSC+_cNumSC))

_cSolic :=Posicione("ZZ7",1,SC1->C1_FILIAL+SC1->C1_I_CDSOL,"ZZ7_NOME")
_cAprNom:=Posicione("ZZ7",1,SC1->C1_FILIAL+SC1->C1_I_CODAP,"ZZ7_NOME")
_cInves :=Posicione("ZZI",1,SC1->C1_FILIAL+SC1->C1_I_CDINV,"ZZI_DESINV")
_cCcust :=SC1->C1_CC + Posicione("CTT",1,xFilial("CTT") +SC1->C1_CC,"CTT_DESC01")
_cEmail	:= UsrRetMail(SC1->C1_I_CDSOL)
If SC1->C1_I_URGEN == "S"
   _cUrgen:= "Sim"
ElseIf SC1->C1_I_URGEN == "F"
	cUrgen	:= "NF"
Else
   _cUrgen:= "Não"
EndIf
//na variavel vem escrito "APROVAR (Aguarde...)"
If "APROVAR" $ _cAprova//_cAprova == "APROVAR"
   _cAprova:= "APROVAR" 
   _cAviso:= "<font color= #0101DF  style='font-size: 12px; font-weight: bold;'>APROVADA</font>"//AZUL
   _cAvisoAssu:= "APROVADA"
ElseIf "REJEITAR"  $ _cAprova//_cAprova == "REJEITAR" 
   _cAprova:= "REJEITAR"
   _cAviso:= "<font color= #FF0000  style='font-size: 12px; font-weight: bold;'>REJEITADA</font>"//VERMELHO
   _cAvisoAssu:= "REJEITADA"
EndIf

If Empty(_cObs)
   _cObs := "EXECUTADO VIA WORKFLOW"
EndIf

_oProcess:oHtml:ValByName("Filial"	  , _cFilName)
_oProcess:oHtml:ValByName("NumSC"	  , _cNumSC	 )
_oProcess:oHtml:ValByName("cLogo"	  , _cLogo	)
_oProcess:oHtml:ValByName("A_SOLIC"	  , _cSolic	)
_oProcess:oHtml:ValByName("Aprovacao" , _cAviso)
_oProcess:oHtml:ValByName("AprNom"	  , _cAprNom)
_oProcess:oHtml:ValByName("A_Data"	  , DToC(SToD(_sDtLiber)))
_oProcess:oHtml:ValByName("A_Hora"	  , _cHrLiber)
_oProcess:oHtml:ValByName("A_CUSTO"	  , _cCcust	)
_oProcess:oHtml:ValByName("A_URGEN"	  , _cUrgen	)
_oProcess:oHtml:ValByName("A_INVES"	  , _cInves	)
_oProcess:oHtml:ValByName("A_OBSSC"	, _cObs   	)
_cQuest:=U_M004Quest(_cFilSC, AllTrim(_cNumSC),"SC")
If !Empty(_cQuest)
	_oProcess:oHtml:ValByName("cQuest",_cQuest )
Else
	_oProcess:oHtml:ValByName("cQuest","" )
EndIf

//================================================================
// Informamos o destinatário (Aprovador) do email contendo o link.  
//================================================================
_oProcess:cTo := _cEmail

//===============================
// Informamos o assunto do email.  
//===============================
_cAssunto:="7-Retorno WF da Solicitação de Compras Filial " + _cFilName + " / SC Número: " + AllTrim(_cNumSC) + " - " + _cAvisoAssu
_oProcess:cSubject	:= FWHttpEncode(_cAssunto)

//=======================================================
// Iniciamos a tarefa e enviamos o email ao destinatário.
//=======================================================
_oProcess:Start() //ENVIA O E-MAIL
// AGUARDANDO FONTE MATA235.PRX ATUALIZADO PRA ANALISE
If _cAprova == "REJEITAR"             
   
   _cQrySC1 := "SELECT R_E_C_N_O_ RECNUM  "
   _cQrySC1 += "FROM "  + RetSqlName("SC1") + " SC1 "
   _cQrySC1 += "WHERE D_E_L_E_T_ = ' ' "
   _cQrySC1 += "  AND C1_FILIAL = '" + _cFilSC + "' "
   _cQrySC1 += "  AND C1_NUM = '" + _cNumSC + "' "
   _cQrySC1 += "  AND (C1_COTACAO < '1' OR C1_COTACAO = 'XXXXXX') "   //Cotação não realizada ou realizado pedido direto que atualiza a C1_QUJE
   _cQrySC1 += "  AND C1_RESIDUO <> 'S' "
   _cQrySC1 += "  AND C1_QUJE < C1_QUANT"
   _cQrySC1 += "  AND C1_APROV = 'R' "
   _cQrySC1 += "  AND C1_RESIDUO <> 'S' "
   
   _cQrySC1 := ChangeQuery(_cQrySC1)
	MPSysOpenQuery(_cQrySC1,"TRBSC1")

   cFilAnt:=_cFilSC
   					
   TRBSC1->(DBGoTop())
   BEGIN TRANSACTION
   While !TRBSC1->(Eof())
      SC1->(DBSetOrder(1))
	  SC1->(DBGoTo(TRBSC1->RECNUM))

	  SC1->(RecLock("SC1",.F.))
	  SC1->C1_I_USREL := SC1->C1_I_CDSOL
	  SC1->C1_I_DTELR := Date()
	  SC1->C1_I_HRELR := Time()	
	  SC1->(MSUnLock())
	  _cResiduo:=SC1->C1_RESIDUO

	//MA235SC(nPerc, dEmisDe  , dEmisAte         , cCodigoDe  , cCodigoAte , cProdDe , cProdAte         , cFornDe, cFornAte, dDatPrfde, dDatPrfAte        , lSemOp, cItemDe      , cItemAte   ,aRecSC1)
	  MA235SC(100  , CTOD("") ,CTOD("31/12/2030"), SC1->C1_NUM, SC1->C1_NUM,Space(15) ,"ZZZZZZZZZZZZZZZ",Space(6),"ZZZZZZ" , CTOD("") , CTOD("31/12/2030"),.F.    , SC1->C1_ITEM, SC1->C1_ITEM)      
	  TRBSC1->(DBSkip())
   EndDo
   END TRANSACTION

   TRBSC1->(DBCloseArea())
EndIf
FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00322"/*cMsgId*/,"MCOM00322 - Email enviado para: " + _cEmail + " com sucesso!"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00323"/*cMsgId*/,"MCOM00323 - /////////////////   FIM DA MCOM003A   /////////////////////////////////////////////////////////////////////////////////"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

Return

/*
===============================================================================================================================
Programa----------: MCOM003CP()
Autor-------------: Alex Wallauer
Data da Criacao---: 12/09/19
Descrição---------: Recria arquivo com conteúdo de outro arquivo
Parametros--------: _carqori - Arquivo de origem
					_carqsrc - Arquivo com conteúdo a ser utilizado
Retorno-----------: _lRet - lógico indicando se completou o processo
===============================================================================================================================
*/
Static Function MCOM003CP(_carqori,_carqsrc)

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
Programa----------: MCOM003D
Autor-------------: Alex Wallauer
Data da Criacao---: 29/07/2021
Descrição---------: Função criada aviso ao Solicitante para enviar e-mail de QUESTINAMENTO
Parametros--------: _oProcess - Processo inicializado do workflow / _cPergPai
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MCOM003D(_oProcess,_cPergPai)

Local _cFilName := _oProcess:oHtml:RetByName("Filial")
Local _cFilSC	 := SubStr(_cFilName,1,2)
Local _cNumSC	 := _oProcess:oHtml:RetByName("NumSC")    
Local _cObs		 := AllTrim(Upper(_oProcess:oHtml:RetByName("ObsGen")))
Local _sDtLiber := DToS(Date())
Local _cHrLiber := SubStr(Time(),1,5)
Local _cHostWF	 := SuperGetMV("IT_WFHOSTS",.T.,"http://wfteste.italac.com.br:4034/")
Local _cLogo	 := _cHostWF + "htm/logo_novo.jpg"
Local _cSolic   :=""
Local _cAprNom  :=""
Local _cInves   :=""
Local _cCcust   :=""
Local _cUrgen   :=""
Local _cEmail	 := ""
Local _cAssunto := ""

FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00324"/*cMsgId*/,"MCOM00324 - /////////////////   INCIO DA MCOM003D   /////////////////////////////////////////////////////////////////////////////////"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

//===================================================================================================================================================================
//INICIA A CRIACAO DO HTM DO BOTAO DO CORPO DO E-MAIL SC_SOLICITANTE_Q.htm
//======================================================================
// Inicialize a classe TWFProcess e assinale a variável objeto oProcess:
//======================================================================
_oProcess := TWFProcess():New("APROVS","Questionamento da Solicitação de Compras")//CRIA PARA O ENVIO DO E-MAIL

//=================================================================
// Criamos o link para o arquivo que foi gerado na tarefa anterior.  
//=================================================================
_oProcess:NewTask("LINK", "\workflow\htm\SC_SOLICITANTE_Q.htm")

SC1->(DBSetOrder(1))
SC1->(DBSeek(_cFilSC+_cNumSC))

_cSolic :=Posicione("ZZ7",1,SC1->C1_FILIAL+SC1->C1_I_CDSOL,"ZZ7_NOME")
_cAprNom:=Posicione("ZZ7",1,SC1->C1_FILIAL+SC1->C1_I_CODAP,"ZZ7_NOME")
_cInves :=Posicione("ZZI",1,SC1->C1_FILIAL+SC1->C1_I_CDINV,"ZZI_DESINV")
_cCcust :=SC1->C1_CC + Posicione("CTT",1,xFilial("CTT") +SC1->C1_CC,"CTT_DESC01")
_cEmail	:= UsrRetMail(SC1->C1_I_CDSOL)
If SC1->C1_I_URGEN == "S"
   _cUrgen:= "Sim"
ElseIf SC1->C1_I_URGEN == "F"
	cUrgen	:= "NF"
Else
   _cUrgen:= "Não"
EndIf
_cAviso:= "<font color= #000000  style='font-size: 12px; font-weight: bold;'>QUESTIONADA</font>"		

//Variaveis que serão guardados no SC_SOLICITANTE_Q.HTM para serem usadas na funcao U_M003RET()
_oProcess:oHtml:ValByName("cPergPai", _cPergPai)
_oProcess:oHtml:ValByName("cUser"	, SC1->C1_I_CDSOL)
//ate aqui

_oProcess:oHtml:ValByName("Filial"	  , _cFilName)
_oProcess:oHtml:ValByName("NumSC"	  , _cNumSC	 )
_oProcess:oHtml:ValByName("cLogo"	  , _cLogo	)
_oProcess:oHtml:ValByName("A_SOLIC"	  , _cSolic	)
_oProcess:oHtml:ValByName("Aprovacao" , _cAviso)
_oProcess:oHtml:ValByName("AprNom"	  , _cAprNom)
_oProcess:oHtml:ValByName("A_Data"	  , DToC(SToD(_sDtLiber)))
_oProcess:oHtml:ValByName("A_Hora"	  , _cHrLiber)
_oProcess:oHtml:ValByName("A_CUSTO"	  , _cCcust	)
_oProcess:oHtml:ValByName("A_URGEN"	  , _cUrgen	)
_oProcess:oHtml:ValByName("A_INVES"	  , _cInves	)
_oProcess:oHtml:ValByName("A_OBSSC"	  , _cObs   	)
//Dados dos questionamentos
_cQuest:=U_M004Quest(_cFilSC, AllTrim(_cNumSC),"SC")
If !Empty(_cQuest)
	_oProcess:oHtml:ValByName("cQuest",_cQuest )
Else
	_oProcess:oHtml:ValByName("cQuest","" )
EndIf

// Informe o nome da função de retorno a ser executada quando a mensagem de
// respostas retornar ao Workflow:
_oProcess:bReturn := "U_M003RET"

_cMailID := _oProcess:Start("\workflow\emp01")
cLink := _cMailID
If !File("\workflow\emp01\" + _cMailID + ".htm")
	FWLogMsg("WARN"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00325"/*cMsgId*/,"MCOM00325 - 01 - Arquivo SC_SOLICITANTE_Q:  \workflow\emp01\" + _cMailID + ".htm nao encontrado."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
EndIf 

//===================================================================================================================================================================
//INICIA A CRIACAO DO HTM DO CORPO DO E-MAIL SC_LINK_Q.HTM
//======================================================================
// Inicialize a classe TWFProcess e assinale a variável objeto oProcess:
//======================================================================
_oProcess := TWFProcess():New("APROVS","Questionamento da Solicitação de Compras")
//=================================================================
// Criamos o link para o arquivo que foi gerado na tarefa anterior.  
//=================================================================
_oProcess:NewTask("LINK", "\workflow\htm\SC_LINK_Q.HTM")//Atalho no corpo do CORPO DO EMAIL

_cMV_WFMLBOX:= AllTrim(GetMV('MV_WFMLBOX'))
chtmlfile := cLink + ".htm"
cMailTo	:= "mailto:" + AllTrim(Posicione("WF7", 1, xFilial("WF7") + _cMV_WFMLBOX, "WF7_ENDERE"))
chtmltexto := wfloadfile("\workflow\emp01\" + chtmlfile )//Carrega o arquivo 
chtmltexto := StrTran( chtmltexto, cmailto, "WFHTTPRET.APL" )//Procura e troca a string
wfsavefile("\workflow\emp"+cEmpAnt+"\" + chtmlfile, chtmltexto)//Grava o arquivo de volta
cLink := _cHostWF + "emp01/" + cLink + ".htm"

_oProcess:oHtml:ValByName("A_LINK"		, cLink		)//clique no corpo do email para chamar a SC_SOLICITANTE_Q.htm

_oProcess:oHtml:ValByName("Filial"	  , _cFilName)
_oProcess:oHtml:ValByName("NumSC"	  , _cNumSC	 )
_oProcess:oHtml:ValByName("cLogo"	  , _cLogo	)
_oProcess:oHtml:ValByName("A_SOLIC"	  , _cSolic	)
_oProcess:oHtml:ValByName("Aprovacao" , _cAviso)
_oProcess:oHtml:ValByName("AprNom"	  , _cAprNom)
_oProcess:oHtml:ValByName("A_Data"	  , DToC(SToD(_sDtLiber)))
_oProcess:oHtml:ValByName("A_Hora"	  , _cHrLiber)
_oProcess:oHtml:ValByName("A_CUSTO"	  , _cCcust	)
_oProcess:oHtml:ValByName("A_URGEN"	  , _cUrgen	)
_oProcess:oHtml:ValByName("A_INVES"	  , _cInves	)
_oProcess:oHtml:ValByName("A_OBSSC"	  , _cObs   	)

//Dados dos questionamentos
If !Empty(_cQuest)
	_oProcess:oHtml:ValByName("cQuest",_cQuest )
Else
	_oProcess:oHtml:ValByName("cQuest","" )
EndIf

//================================================================
// Informamos o destinatário (Aprovador) do email contendo o link.  
//================================================================
_oProcess:cTo := _cEmail

//===============================
// Informamos o assunto do email.  
//===============================
_cAssunto:="8-QUESTIONAMENTO da Solicitação de Compras Filial " + _cFilName + " / SC Número: " + AllTrim(_cNumSC) 
_oProcess:cSubject	:= FWHttpEncode(_cAssunto)

//=======================================================
// Iniciamos a tarefa e enviamos o email ao destinatário.
//=======================================================
_oProcess:Start() //ENVIA O E-MAIL

FWLogMsg("WARN"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00326"/*cMsgId*/,"MCOM00326 - Email enviado para: " + _cEmail + " com sucesso!"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)	

Return

/*
===============================================================================================================================
Programa----------: M003RET
Autor-------------: Alex Wallauer
Data da Criacao---: 29/07/2021
Descrição---------: Função criada para montar o retorno dos questionamentos referente ao pedido de compras em questão.
Parametros--------: _oProcess - Objeto do Processo de Questionamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function M003RET(_oProcess)

//Variaveis  guardados no SC_SOLICITANTE_Q.HTM para serem usadas aqui na funcao U_M003RET()
Local _cFilial	:= SubStr(_oProcess:oHtml:RetByName("Filial"),1,2)
Local _cNumSC	:= _oProcess:oHtml:RetByName("NumSC")    
Local _cPergPai	:= _oProcess:oHtml:RetByName("cPergPai")
Local _cUser	:= _oProcess:oHtml:RetByName("cUser")
//Acaba aqui

Local _cAssunto     := "6-Retorno do questionamento do SC " + _cFilial + " " + _cNumSC
Local _cObs			:= AllTrim(Upper(_oProcess:oHtml:RetByName("CR_OBS")))
Local _cArqHtm		:= SubStr(_oProcess:oHtml:RetByName("WFMAILID"),3,Len(_oProcess:oHtml:RetByName("WFMAILID")))
Local _sDtLiber		:= DToS(Date())
Local _cHrLiber		:= SubStr(Time(),1,5)
Local _cHtmlMode	:= "\Workflow\htm\sc_concluida.htm"

_cQrySCR := "SELECT COUNT(C1_NUM) C1_REGS "
_cQrySCR += "FROM "  + RetSqlName("SC1") + " SC1 "
_cQrySCR += "WHERE SC1.D_E_L_E_T_ = ' ' "
_cQrySCR += "  AND C1_FILIAL = '" + _cFilial + "' "
_cQrySCR += "  AND C1_NUM = '" + _cNumSC + "' "
_cQrySCR += "  AND C1_APROV = 'B' "
_cQrySCR += "  AND C1_RESIDUO <> 'S' "

_cQrySCR := ChangeQuery(_cQrySCR)
MPSysOpenQuery(_cQrySCR,"TRBSC1")

DBSelectArea("TRBSC1")
TRBSC1->(DBGoTop())

If TRBSC1->C1_REGS > 0

	//=======================================================
	//Atualiza rastreamento de aprovação do pedido de compras
	//=======================================================
	RastreiaWF(_oProcess:fProcessId + '.' + _oProcess:fTaskID , _oProcess:fProcCode, "1002", _cAssunto , "")

	//==============================================================================================
	//Chama query para atualização do registro do pedido de compras, com as informações da aprovação
	//==============================================================================================
//  MCOM004Q(9,"",_cFilial,_cNumPC,"1002","2","",_cSituacao,_cObs,_sDtLiber,_cHrLiber,"", _oProcess:fProcessId,cNivelAP,"R",_sDtAviso,_cUser,_cPergPai)
//  MCOM003Q(_nOpcao,_cAlias,_cFilial,_cNumSC,_cWFID,_cSITWF,_cIDHTM,_cAprova,_cObs,_sDtLiber,_cHrLiber,_cProduto,_cPergPai) 
    MCOM003Q(9      ,""     ,_cFilial,_cNumSC,"1002","Q"    ,""     ,"R"     ,_cObs,_sDtLiber,_cHrLiber,""       ,@_cPergPai)


	//==================================================
	//Finalize a tarefa anterior para não ficar pendente
	//==================================================
	_oProcess:Finish()

	//========================================================================================
	//Faz a cópia do arquivo de aprovação para .old, e cria o arquivo de processo já concluído
	//========================================================================================
	If File("\workflow\emp01\" + _cArqHtm + ".htm")
		If __CopyFile("\workflow\emp01\" + _cArqHtm + ".htm", "\workflow\emp01\" + _cArqHtm + ".old")
        	If !Empty(_cHtmlMode) 
        		If MCOM003CP("\workflow\emp01\" + _cArqHtm + ".htm",_cHtmlMode) //Recria _carqhtm com conteudo do modelo chtmlmode
  			   		FWLogMsg("WARN"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00327"/*cMsgId*/,"MCOM00327 - Cópia do arquivo DE "+_cHtmlMode+" PARA \workflow\emp01\" + _cArqHtm + ".htm de conclusão efetuada com sucesso."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
  		    	Else
			 		FWLogMsg("ERROR"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00328"/*cMsgId*/,"MCOM00328 - Problema na cópia de arquivo DE "+_cHtmlMode+" PARA \workflow\emp01\" + _cArqHtm + ".htm"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)	
				EndIf
  		  	EndIf
	   	Else
	   		FWLogMsg("ERROR"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00329"/*cMsgId*/,"MCOM00329 - Não foi possível renomear o arquivo \workflow\emp01\" + _cArqHtm + ".htm"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		EndIf
	EndIf

	cQuery := "UPDATE "
	cQuery += RETSQLNAME("SC1")
	cQuery += " SET	C1_I_SITWF	= '1', "
	cQuery += "		C1_I_HTM	= ' ', "
	cQuery += "		C1_I_WFID	= ' ' " 
	cQuery += "WHERE"
	cQuery += " D_E_L_E_T_ = ' '" 
	cQuery += " AND	C1_FILIAL = '" + _cFilial + "' "
	cQuery += " AND	C1_NUM    = '" + _cNumSC + "' "

	If TCSqlExec( cQuery ) < 0
		FWLogMsg("ERROR"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00330"/*cMsgId*/,"MCOM00330 - TCSqlExec( cQuery ) : "+cQuery+" - TCSQLError(): "+AllTrim(TCSQLError())/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	EndIf

Else

 
	//==================================================
	//Finalize a tarefa anterior para não ficar pendente
	//==================================================
	_oProcess:Finish()

	_aConfig	:= U_ITCFGEML('')

	_cHtml := '<html> '
	_cHtml += '	<head> '
	_cHtml += '		<title>Questionamento Solicitacao de Compras</title> '
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
	_cHtml += '						<b>O Processo do solicitacao de compras já foi encerrado, sendo assim, sua resposta não será enviada!</b></center> '
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
Programa----------: SchedDef
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 09/09/2024
Descrição---------: DefiniçStaticStatic Function SchedDef para o novo Schedule
					No novo Schedule existe uma forma para a definição dos Perguntes para o botão Parâmetros, além do cadastro 
					das funções no SXD. Ao definir em sua rotinStaticatic Function SchedDef(), no cadastro da rotina no Agenda-
					mento do Schedule será verificado se existe estStaticic Function e irá executá-la habilitando o botão Parâ-
					metros com as informações do retorno da SchedDef(), deixando de verificar assim as informações na SXD. O 
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
