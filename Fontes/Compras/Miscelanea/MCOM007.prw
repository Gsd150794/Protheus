/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
 Autor        |    Data    |                              Motivo                      										 
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  | 28/08/2024 | Chamado 48277. Incluídos novos códigos para retirada da fila de reprocessamento. 
Lucas Borges  | 10/12/2024 | Chamado 49351. Incluída limpeza da marca na CKO. 
Lucas Borges  | 19/12/2024 | Chamado 49415. Corrigida sintaxe na query.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MCOM007
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 25/05/2017
Descrição---------: Rotina para checar status dos XMLs recebidos junto à SEFAZ. Rotina será agendada para chegar o status de 
					todos os XMLs recebidos e caso estejam cancelados, irá excluir os possíveis e para os escriturados, enviará 
					um e-mail informando.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MCOM007

Local _aArea 	:= FWGetArea()
Local _nDias	:= SuperGetMV("IT_TCPERCON",.F., "6/9")
Local _cArqLog	:= "\temp\mcom007_log_analise_xml_filial_"+ cFilAnt +"_"+ DToS(Date()) +"_"+ StrTran(Time(),":","")+"_"+ RetCodUsr() +".log"
Local _aLog		:={}
Local _nHdlLog	:= 0
Local _cPerg	:= "MCOM007"
Local _lScheduler := FWGetRunSchedule()

If _lScheduler
	MV_PAR01 :=(DATE()-Val(SubStr(_nDias,3,1)))
	MV_PAR02 :=(DATE()-Val(SubStr(_nDias,1,1)))
	_nHdlLog := FCreate(_cArqLog )
	If _nHdlLog == -1
		FWLogMsg("WARN"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00701"/*cMsgId*/, "Filial: "+cFilant+" - Arquivo de Log não pode ser criado. Rotina será interrompida!"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	Else
		aAdd(_aLog,{'Processamento das manutenções periódicas do TOTVS Colaboração, bem como a checagem junto à SEFAZ de documentos cancelados. Ambiente: '+GetEnvServer(),'','','','','','','',''})
		aAdd(_aLog,{'Data: ' + DToC(Date()) +' - '+ Time() +' Filial: ' + cFilAnt + ' Período: ' + DToC(MV_PAR01) + ' a ' +DToC(MV_PAR02),'','','','','','','',''})
		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00702"/*cMsgId*/, "Filial: "+cFilant+"] - Inciando processamento dos Updates..."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		MCOM007U(_nHdlLog)
		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00703"/*cMsgId*/, "Filial: "+cFilant+"] - Inciando processamento da consulta na SEFAZ..."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		MCOM007C(_nHdlLog,_lScheduler,@_aLog)
		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00704"/*cMsgId*/, "Filial: "+cFilant+"] - Iniciando envio do e-mail com log."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		If Len(_aLog)>3
			MCOM007E(_cArqLog,_aLog)
		Else
			FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00705"/*cMsgId*/, "Filial: "+cFilant+"] - Filial sem inconsistência. E-mail não será enviado."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		EndIf
		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00706"/*cMsgId*/, "Filial: "+cFilant+"] - Término do Processamento."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	EndIf
Else
	Pergunte( _cPerg , .T. )
	If MsgYesNo("Confirma processamento da rotina para manutenção dos XMLs no TOTVS Colaboração?")
		_nHdlLog := FCreate(_cArqLog )
		If _nHdlLog == -1
			Aviso( 'MCOM00707' , 'Arquivo de Log não pode ser criado. Rotina será interrompida!' , {'Sair'} )			
			Return
		Else
			aAdd(_aLog,{'Processamento das manutenções periódicas do TOTVS Colaboração, bem como a checagem junto à SEFAZ de documentos cancelados. Ambiente: '+GetEnvServer(),'','','','','','','',''})
			aAdd(_aLog,{'Data: ' + DToC(Date()) +' - '+ Time() +' Filial: ' + cFilAnt + ' Período: ' + DToC(MV_PAR01) + ' a ' +DToC(MV_PAR02),'','','','','','','',''})		
			Processa({|| MCOM007U(_nHdlLog) } )
			Processa({|| MCOM007C(_nHdlLog,_lScheduler,@_aLog) } )
			Processa({|| MCOM007E(_cArqLog,_aLog) } )
			FWrite( _nHdlLog , 'Término do Processamento. ' + CRLF )
			FClose( _nHdlLog )
		EndIf
	EndIf
EndIf

FWRestArea(_aArea)
Return

/*
===============================================================================================================================
Programa----------: MCOM007U
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 25/05/2017
Descrição---------: Executa Updates de manutenção nas tabelas SDS, SDT e CKO
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MCOM007U(_nHdlLog)

Local _aArea 	:= FWGetArea()
Local _cQuery 	:= ""

	//====================================================================================================
	// 01- Preenche informações na C00 para registros com problema. Acontece quando JOBMANI é interrompido
	//====================================================================================================
	_cQuery:=" UPDATE "+RETSQLNAME('C00')+" 
	_cQuery+="   SET C00_VLDOC = (SELECT DOCVTOT FROM SPED156 WHERE D_E_L_E_T_ = ' ' AND C00_CHVNFE = DOCCHV), "
	_cQuery+="       C00_SITDOC = (SELECT DOCSIT FROM SPED156 WHERE D_E_L_E_T_ = ' ' AND C00_CHVNFE = DOCCHV), "
	_cQuery+="       C00_NOEMIT = (SELECT EMITNOME FROM SPED156 WHERE D_E_L_E_T_ = ' ' AND C00_CHVNFE = DOCCHV), "
	_cQuery+="       C00_CNPJEM = (SELECT EMITCNPJ FROM SPED156 WHERE D_E_L_E_T_ = ' ' AND C00_CHVNFE = DOCCHV), "
	_cQuery+="       C00_DTEMI = (SELECT DOCDTEMIS FROM SPED156 WHERE D_E_L_E_T_ = ' ' AND C00_CHVNFE = DOCCHV), "
	_cQuery+="       C00_DTREC = (SELECT DOCDTAUT FROM SPED156 WHERE D_E_L_E_T_ = ' ' AND C00_CHVNFE = DOCCHV), "
	_cQuery+="       C00_CODRET = (SELECT RESPSTAT FROM SPED156 WHERE D_E_L_E_T_ = ' ' AND C00_CHVNFE = DOCCHV), "
	_cQuery+="       C00_DESRES = (SELECT 'Documento(s) localizado(s)' FROM SPED156 WHERE D_E_L_E_T_ = ' ' AND C00_CHVNFE = DOCCHV), "
	_cQuery+="       C00_IEEMIT = (SELECT SubStr(EMITIE, 1, 11) FROM SPED156 WHERE D_E_L_E_T_ = ' ' AND C00_CHVNFE = DOCCHV) "
	_cQuery+=" WHERE D_E_L_E_T_ = ' ' "
	_cQuery+="   AND C00_CODRET = ' ' "
	_cQuery+="   AND C00_FILIAL = '"+cFilAnt+"'"      
	_cQuery+="   AND EXISTS (SELECT 1 "
	_cQuery+="          FROM SPED156 "
	_cQuery+="         WHERE D_E_L_E_T_ = ' ' "
	_cQuery+="           AND C00_CHVNFE = DOCCHV) "

	If TCSqlExec( _cQuery ) < 0
		FWLogMsg("ERROR"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00708"/*cMsgId*/, "Filial: "+cFilant+"] - Processamento 01 com erro: "+AllTrim(TCSQLError())/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWrite( _nHdlLog , 'Processamento 01 com erro: '+AllTrim(TCSQLError()) + CRLF )	
	Else
		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00709"/*cMsgId*/, "Filial: "+cFilant+"] - Processamento 01 executado com sucesso. Inconsistências ajustadas na C00."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWrite( _nHdlLog , 'Processamento 01 executado com sucesso. Inconsistências ajustadas na C00.' + CRLF )	
	EndIf

	//====================================================================================================
	// 02-Limpa as notas Canceladas, com Rejeição e situações que não são tratadas para não aparecerem no monitor
	//====================================================================================================	
	_cQuery:=" UPDATE "+RETSQLNAME('CKO')
	_cQuery+="    SET CKO_FLAG   = '9' " 
	_cQuery+="           WHERE D_E_L_E_T_ = ' ' "
	_cQuery+="             AND CKO_FILPRO = '"+cFilAnt+"'"
	_cQuery+="    		   AND CKO_FLAG <> '9' "
	_cQuery+="    		   AND CKO_CODERR IN ('COM003','COM004','COM047','COM036','COM037','COM040','COM041','COM045','COM046')"
	    
	If TCSqlExec( _cQuery ) < 0
		FWLogMsg("ERROR"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00710"/*cMsgId*/, "Filial: "+cFilant+"] - Processamento 02 com erro: "+AllTrim(TCSQLError())/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWrite( _nHdlLog , 'Processamento 02 com erro: '+AllTrim(TCSQLError()) + CRLF )	
	Else
		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00711"/*cMsgId*/, "Filial: "+cFilant+"] - Processamento 02 executado com sucesso. CKO_FLAG ajustado para documentos cancelados/rejeitados."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWrite( _nHdlLog , 'Processamento 02 executado com sucesso. CKO_FLAG ajustado para documentos cancelados/rejeitados.' + CRLF )	
	EndIf

	//====================================================================================================
	// 03-Limpa as notas Recusadas e com Operação Desconhecida para não aparecerem no monitor - Itens das Notas
	//====================================================================================================
	_cQuery:=" UPDATE "+RETSQLNAME('SDT')+" SET D_E_L_E_T_ = '*', R_E_C_D_E_L_ = R_E_C_N_O_ "
	_cQuery+="  WHERE D_E_L_E_T_ = ' ' "
	_cQuery+="  AND DT_FILIAL = '"+cFilAnt+"'"
	_cQuery+="  AND EXISTS "
	_cQuery+="    (SELECT 1 FROM "+RETSQLNAME('SDS')
	_cQuery+="         WHERE D_E_L_E_T_ = ' '"
	_cQuery+="         AND DS_FILIAL = DT_FILIAL"
	_cQuery+="         AND DS_DOC = DT_DOC"
	_cQuery+="         AND DS_SERIE = DT_SERIE"
	_cQuery+="         AND DS_FORNEC = DT_FORNEC"
	_cQuery+="         AND DS_LOJA = DT_LOJA"
	_cQuery+="         AND DS_CNPJ = DT_CNPJ"
	_cQuery+="         AND EXISTS"
	_cQuery+="    (SELECT 1 CHAVE FROM "+RETSQLNAME('C00')
	_cQuery+="         WHERE D_E_L_E_T_ = ' '"
	_cQuery+="         AND C00_FILIAL = DS_FILIAL"
	_cQuery+="         AND C00_CHVNFE = DS_CHAVENF"
	_cQuery+="         AND C00_CODEVE = '3'"
	_cQuery+="         AND C00_STATUS IN ('2','3')"
	_cQuery+="         AND NOT EXISTS 
	_cQuery+="    (SELECT 1 FROM "+RETSQLNAME('SF1')
	_cQuery+="         WHERE D_E_L_E_T_ = ' '"
	_cQuery+="         AND C00_FILIAL = F1_FILIAL"
	_cQuery+="         AND C00_CHVNFE = F1_CHVNFE)))"

	If TCSqlExec( _cQuery ) < 0
		FWLogMsg("ERROR"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00712"/*cMsgId*/, "Filial: "+cFilant+"] - Processamento 03 com erro: "+AllTrim(TCSQLError())/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWrite( _nHdlLog , 'Processamento 03 com erro: '+AllTrim(TCSQLError()) + CRLF )	
	Else
		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00713"/*cMsgId*/, "Filial: "+cFilant+"] - Processamento 03 executado com sucesso. Registros apagados na tabela SDT."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWrite( _nHdlLog , 'Processamento 03 executado com sucesso. Registros apagados na tabela SDT.' + CRLF )	
	EndIf

	//====================================================================================================
	// 03-Limpa as notas Recusadas e com Operação Desconhecida para não aparecerem no monitor - Cabeçalho das notas
	//====================================================================================================	
	_cQuery:=" UPDATE "+RETSQLNAME('SDS')+" SET D_E_L_E_T_ = '*', R_E_C_D_E_L_ = R_E_C_N_O_"
	_cQuery+="   WHERE D_E_L_E_T_ = ' '"
	_cQuery+="   AND DS_FILIAL = '"+cFilAnt+"'"
	_cQuery+="   AND EXISTS"
	_cQuery+="   (SELECT 1 CHAVE FROM "+RETSQLNAME('C00')
	_cQuery+="       WHERE D_E_L_E_T_ = ' '"
	_cQuery+="         AND C00_FILIAL = DS_FILIAL"
	_cQuery+="         AND C00_CHVNFE = DS_CHAVENF"
	_cQuery+="         AND C00_CODEVE = '3'"
	_cQuery+="         AND C00_STATUS IN ('2','3')"
	_cQuery+="         AND NOT EXISTS (SELECT 1 FROM "+RETSQLNAME('SF1')
	_cQuery+="               WHERE D_E_L_E_T_ = ' '"
	_cQuery+="                 AND C00_FILIAL = F1_FILIAL"
	_cQuery+="                 AND C00_CHVNFE = F1_CHVNFE))"
	
	If TCSqlExec( _cQuery ) < 0
		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00714"/*cMsgId*/, "Filial: "+cFilant+"] - Processamento 04 com erro: "+AllTrim(TCSQLError())/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWrite( _nHdlLog , 'Processamento 04 com erro: '+AllTrim(TCSQLError()) + CRLF )	
	Else
		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00715"/*cMsgId*/, "Filial: "+cFilant+"] - Processamento 04 executado com sucesso. Registros apagados na tabela SDS."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWrite( _nHdlLog , 'Processamento 04 executado com sucesso. Registros apagados na tabela SDS.' + CRLF )	
	EndIf

	//====================================================================================================
	// 04-Limpa as notas com 210220-Desconhecimento da operação para não aparecerem no monitor
	//====================================================================================================	
	_cQuery:=" UPDATE "+RETSQLNAME('CKO')
	_cQuery+="    SET CKO_FLAG   = '9', " 
	_cQuery+="        CKO_CODERR = 'MCOM01' "
	_cQuery+="           WHERE D_E_L_E_T_ = ' ' "
	_cQuery+="             AND CKO_FILPRO = '"+cFilAnt+"'"
	_cQuery+="             AND CKO_CODEDI = '109' "
	_cQuery+="    		   AND CKO_FLAG <> '9' "
	_cQuery+="             AND EXISTS "
	_cQuery+="             (SELECT 1 FROM "+RETSQLNAME('C00')
	_cQuery+="                     WHERE D_E_L_E_T_ = ' ' "
	_cQuery+="                       AND C00_FILIAL = CKO_FILPRO "
	_cQuery+="                       AND C00_CHVNFE = SubStr(CKO_ARQUIV,4,44) "
	_cQuery+="         				 AND C00_CODEVE = '3'"
	_cQuery+="         				 AND C00_STATUS = '2'"
	_cQuery+="                       AND NOT EXISTS (SELECT 1 FROM "+RETSQLNAME('SF1') 
	_cQuery+="                             WHERE D_E_L_E_T_ = ' ' "
	_cQuery+="                               AND C00_FILIAL = F1_FILIAL "
	_cQuery+="                               AND C00_CHVNFE = F1_CHVNFE)) "

	If TCSqlExec( _cQuery ) < 0
		FWLogMsg("ERROR"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00716"/*cMsgId*/, "Filial: "+cFilant+"] - Processamento 05 com erro: "+AllTrim(TCSQLError())/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWrite( _nHdlLog , 'Processamento 05 com erro: '+AllTrim(TCSQLError()) + CRLF )	
	Else
		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00717"/*cMsgId*/, "Filial: "+cFilant+"] - Processamento 05 executado com sucesso. CKO_FLAG ajustado para documentos 210220-Desconhecimento da operação."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWrite( _nHdlLog , 'Processamento 05 executado com sucesso. CKO_FLAG ajustado para documentos 210220-Desconhecimento da operação.' + CRLF )	
	EndIf

	//====================================================================================================
	// 05-Limpa as notas com 21040-Operação não realizada para não aparecerem no monitor
	//====================================================================================================	
	_cQuery:=" UPDATE "+RETSQLNAME('CKO')
	_cQuery+="    SET CKO_FLAG   = '9', " 
	_cQuery+="        CKO_CODERR = 'MCOM02' "
	_cQuery+="           WHERE D_E_L_E_T_ = ' ' "
	_cQuery+="             AND CKO_FILPRO = '"+cFilAnt+"'"
	_cQuery+="             AND CKO_CODEDI = '109' "
	_cQuery+="    		   AND CKO_FLAG <> '9' "
	_cQuery+="             AND EXISTS "
	_cQuery+="             (SELECT 1 FROM "+RETSQLNAME('C00')
	_cQuery+="                     WHERE D_E_L_E_T_ = ' ' "
	_cQuery+="                       AND C00_FILIAL = CKO_FILPRO "
	_cQuery+="                       AND C00_CHVNFE = SubStr(CKO_ARQUIV,4,44) "
	_cQuery+="         				 AND C00_CODEVE = '3'"
	_cQuery+="         				 AND C00_STATUS = '3'"
	_cQuery+="                       AND NOT EXISTS (SELECT 1 FROM "+RETSQLNAME('SF1') 
	_cQuery+="                             WHERE D_E_L_E_T_ = ' ' "
	_cQuery+="                               AND C00_FILIAL = F1_FILIAL "
	_cQuery+="                               AND C00_CHVNFE = F1_CHVNFE)) "

	If TCSqlExec( _cQuery ) < 0
		FWLogMsg("ERROR"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00718"/*cMsgId*/, "Filial: "+cFilant+"] - Processamento 06 com erro: "+AllTrim(TCSQLError())/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWrite( _nHdlLog , 'Processamento 06 com erro: '+AllTrim(TCSQLError()) + CRLF )	
	Else
		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00719"/*cMsgId*/, "Filial: "+cFilant+"] - Processamento 06 executado com sucesso. CKO_FLAG ajustado para documentos com 21040-Operação não realizada."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWrite( _nHdlLog , 'Processamento 06 executado com sucesso. CKO_FLAG ajustado para documentos 21040-Operação não realizada.' + CRLF )	
	EndIf

	//====================================================================================================
	// 06-Limpa os CT-e com 610110-Prestação de Serviço em Desacordo para não aparecerem no monitor - Itens das Notas
	//====================================================================================================
	_cQuery:=" UPDATE "+RETSQLNAME('SDT')+" SET D_E_L_E_T_ = '*', R_E_C_D_E_L_ = R_E_C_N_O_ "
	_cQuery+="  WHERE D_E_L_E_T_ = ' ' "
	_cQuery+="  AND DT_FILIAL = '"+cFilAnt+"'"
	_cQuery+="  AND EXISTS "
	_cQuery+="    (SELECT 1 FROM "+RETSQLNAME('SDS')
	_cQuery+="         WHERE D_E_L_E_T_ = ' '"
	_cQuery+="         AND DS_FILIAL = DT_FILIAL"
	_cQuery+="         AND DS_DOC = DT_DOC"
	_cQuery+="         AND DS_SERIE = DT_SERIE"
	_cQuery+="         AND DS_FORNEC = DT_FORNEC"
	_cQuery+="         AND DS_LOJA = DT_LOJA"
	_cQuery+="         AND DS_CNPJ = DT_CNPJ"
	_cQuery+="         AND EXISTS"
	_cQuery+="    (SELECT 1 CHAVE FROM SPED150, SPED001, SYS_COMPANY S"
	_cQuery+="         WHERE SPED150.D_E_L_E_T_ = ' '"
	_cQuery+="         AND SPED001.D_E_L_E_T_ = ' '"
	_cQuery+="         AND S.D_E_L_E_T_ = ' '"
	_cQuery+="         AND SPED001.CNPJ = S.M0_CGC"
	_cQuery+="         AND SPED001.IE = S.M0_INSC"
	_cQuery+="         AND SPED001.ID_ENT = SPED150.ID_ENT"
	_cQuery+="         AND DS_FILIAL = S.M0_CODFIL"
	_cQuery+="         AND SPED150.NFE_CHV = DS_CHAVENF"
	_cQuery+="         AND SPED150.TPEVENTO = '610110'"
	_cQuery+="         AND SPED150.STATUS = 6"
	_cQuery+="         AND NOT EXISTS 
	_cQuery+="    (SELECT 1 FROM "+RETSQLNAME('SF1')
	_cQuery+="         WHERE D_E_L_E_T_ = ' '"
	_cQuery+="         AND DS_FILIAL = F1_FILIAL"
	_cQuery+="         AND DS_CHAVENF = F1_CHVNFE)))"

	If TCSqlExec( _cQuery ) < 0
		FWLogMsg("ERROR"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00720"/*cMsgId*/, "Filial: "+cFilant+"] - Processamento 07 com erro: "+AllTrim(TCSQLError())/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWrite( _nHdlLog , 'Processamento 07 com erro: '+AllTrim(TCSQLError()) + CRLF )	
	Else
		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00721"/*cMsgId*/, "Filial: "+cFilant+"] - Processamento 07 executado com sucesso. Registros apagados na tabela SDT."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWrite( _nHdlLog , 'Processamento 07 executado com sucesso. Registros apagados na tabela SDT.' + CRLF )	
	EndIf

	//====================================================================================================
	// 06-Limpa os CT-e com 610110-Prestação de Serviço em Desacordo para não aparecerem no monitor - Cabeçalho das notas
	//====================================================================================================	
	_cQuery:=" UPDATE "+RETSQLNAME('SDS')+" SET D_E_L_E_T_ = '*', R_E_C_D_E_L_ = R_E_C_N_O_"
	_cQuery+="   WHERE D_E_L_E_T_ = ' '"
	_cQuery+="   AND DS_FILIAL = '"+cFilAnt+"'"
	_cQuery+="   AND EXISTS"          
	_cQuery+="    (SELECT 1 CHAVE FROM SPED150, SPED001, SYS_COMPANY S"
	_cQuery+="         WHERE SPED150.D_E_L_E_T_ = ' '"
	_cQuery+="         AND SPED001.D_E_L_E_T_ = ' '"
	_cQuery+="         AND S.D_E_L_E_T_ = ' '"
	_cQuery+="         AND SPED001.CNPJ = S.M0_CGC"
	_cQuery+="         AND SPED001.IE = S.M0_INSC"
	_cQuery+="         AND SPED001.ID_ENT = SPED150.ID_ENT"
	_cQuery+="         AND DS_FILIAL = S.M0_CODFIL"
	_cQuery+="         AND SPED150.NFE_CHV = DS_CHAVENF"
	_cQuery+="         AND SPED150.TPEVENTO = '610110'"
	_cQuery+="         AND SPED150.STATUS = 6"
	_cQuery+="         AND NOT EXISTS (SELECT 1 FROM "+RETSQLNAME('SF1')
	_cQuery+="               WHERE D_E_L_E_T_ = ' '"
	_cQuery+="                 AND DS_FILIAL = F1_FILIAL"
	_cQuery+="                 AND DS_CHAVENF = F1_CHVNFE))"
	
	If TCSqlExec( _cQuery ) < 0
		FWLogMsg("ERROR"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00722"/*cMsgId*/, "Filial: "+cFilant+"] - Processamento 08 com erro: "+AllTrim(TCSQLError())/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWrite( _nHdlLog , 'Processamento 08 com erro: '+AllTrim(TCSQLError()) + CRLF )	
	Else
		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00723"/*cMsgId*/, "Filial: "+cFilant+"] - Processamento 08 executado com sucesso. Registros apagados na tabela SDS."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWrite( _nHdlLog , 'Processamento 08 executado com sucesso. Registros apagados na tabela SDS.' + CRLF )	
	EndIf

	//====================================================================================================
	// 06-Limpa os CT-e notas com 610110-Prestação de Serviço em Desacordo para não aparecerem no monitor
	//====================================================================================================	
	_cQuery:=" UPDATE "+RETSQLNAME('CKO')
	_cQuery+="    SET CKO_FLAG   = '9', " 
	_cQuery+="        CKO_CODERR = 'MCOM03' "
	_cQuery+="           WHERE D_E_L_E_T_ = ' ' "
	_cQuery+="             AND CKO_FILPRO = '"+cFilAnt+"'"
	_cQuery+="             AND CKO_CODEDI = '214' "
	_cQuery+="    		   AND CKO_FLAG <> '9' "
	_cQuery+="             AND EXISTS "
	_cQuery+="    			(SELECT 1 CHAVE FROM SPED150, SPED001, SYS_COMPANY S"
	_cQuery+="         			WHERE SPED150.D_E_L_E_T_ = ' '"
	_cQuery+="         			AND SPED001.D_E_L_E_T_ = ' '"
	_cQuery+="         			AND S.D_E_L_E_T_ = ' '"
	_cQuery+="         			AND SPED001.CNPJ = S.M0_CGC"
	_cQuery+="         			AND SPED001.IE = S.M0_INSC"
	_cQuery+="         			AND SPED001.ID_ENT = SPED150.ID_ENT"
	_cQuery+="         			AND CKO_FILPRO = S.M0_CODFIL"
	_cQuery+="         			AND SPED150.NFE_CHV = SubStr(CKO_ARQUIV,4,44)"
	_cQuery+="         			AND SPED150.TPEVENTO = '610110'"
	_cQuery+="         			AND SPED150.STATUS = 6"
	_cQuery+="                  AND NOT EXISTS (SELECT 1 FROM "+RETSQLNAME('SF1') 
	_cQuery+="                  	WHERE D_E_L_E_T_ = ' ' "
	_cQuery+="                      AND CKO_FILPRO = F1_FILIAL "
	_cQuery+="                      AND SubStr(CKO_ARQUIV,4,44) = F1_CHVNFE)) "

	If TCSqlExec( _cQuery ) < 0
		FWLogMsg("ERROR"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00724"/*cMsgId*/, "Filial: "+cFilant+"] - Processamento 09 com erro: "+AllTrim(TCSQLError())/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWrite( _nHdlLog , 'Processamento 09 com erro: '+AllTrim(TCSQLError()) + CRLF )	
	Else
		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00725"/*cMsgId*/, "Filial: "+cFilant+"] - Processamento 09 executado com sucesso. CKO_FLAG ajustado para documentos com 21040-Operação não realizada."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWrite( _nHdlLog , 'Processamento 09 executado com sucesso. CKO_FLAG ajustado para documentos 610110-Prestação de Serviço em Desacordo.' + CRLF )	
	EndIf

	//====================================================================================================
	// 07-Ajusta flag para documentos que estão com erro na CKO mas não deveriam, já que estão na SDS
	//====================================================================================================	
	_cQuery:=" UPDATE "+RETSQLNAME('CKO')
	_cQuery+="    SET CKO_CODERR = ' ', CKO_FLAG = '1' "
	_cQuery+="  WHERE D_E_L_E_T_ = ' ' "
	_cQuery+="    AND CKO_FILPRO = '"+cFilAnt+"'"
//	_cQuery+="    AND CKO_CODERR IN ('COM005','COM006','COM019','COM025') "
	_cQuery+="    AND EXISTS (SELECT 1 FROM "+RETSQLNAME('SDS')
	_cQuery+="    WHERE D_E_L_E_T_ = ' ' "
	_cQuery+="    AND CKO_ARQUIV = DS_ARQUIVO) "
    
	If TCSqlExec( _cQuery ) < 0
		FWLogMsg("ERROR"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00726"/*cMsgId*/, "Filial: "+cFilant+"] - Processamento 10 com erro: "+AllTrim(TCSQLError())/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWrite( _nHdlLog , 'Processamento 10 com erro: '+AllTrim(TCSQLError()) + CRLF )	
	Else
		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00727"/*cMsgId*/, "Filial: "+cFilant+"] - Processamento 10 executado com sucesso. CKO_FLAG ajustado para documentos que já estavam processados."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWrite( _nHdlLog , 'Processamento 10 executado com sucesso. CKO_FLAG ajustado para documentos que já estavam processados.' + CRLF )	
	EndIf

	//====================================================================================================
	// 08-Deleta registros que não deveriam ser recebibos pelo TOTVS Colaboração
	//====================================================================================================	
	_cQuery:=" UPDATE "+RETSQLNAME('CKO')
	_cQuery+=" SET D_E_L_E_T_ = '*' , "
	_cQuery+="     R_E_C_D_E_L_ = R_E_C_N_O_  "
	_cQuery+="     WHERE D_E_L_E_T_= ' ' AND CKO_CODERR IN ('COM002','COM052') "
	_cQuery+="     AND CKO_FILPRO = ' ' "
    
	If TCSqlExec( _cQuery ) < 0
		FWLogMsg("ERROR"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00728"/*cMsgId*/, "Filial: "+cFilant+"] - Processamento 11 com erro: "+AllTrim(TCSQLError())/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWrite( _nHdlLog , 'Processamento 11 com erro: '+AllTrim(TCSQLError()) + CRLF )	
	Else
		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00729"/*cMsgId*/, "Filial: "+cFilant+"] - Processamento 11 executado com sucesso. Apagados registros COM002 que não pertencem à Italac."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWrite( _nHdlLog , 'Processamento 11 executado com sucesso. Apagados registros COM002 que não pertencem à Italac.' + CRLF )	
	EndIf

	//====================================================================================================
	// 09-Verifica notas foram incluídas manualmente mesmo estando disponíveis para importação e depois marca como importadas
	//====================================================================================================	
	_cQuery:=" UPDATE "+RETSQLNAME('SDS')
	_cQuery+="    SET DS_USERPRE = 'ACERTO MANUAL MCOM007', "
	_cQuery+="        DS_DATAPRE = '"+DToS(DATE())+"', "
	_cQuery+="        DS_HORAPRE= '"+LEFT(TIME(),5)+"', "
	_cQuery+="        DS_STATUS = 'P'"
	_cQuery+="   WHERE D_E_L_E_T_ = ' '"
	_cQuery+="     AND DS_STATUS NOT IN ('P','B')"
	_cQuery+="     AND DS_FILIAL = '"+cFilAnt+"'"
	_cQuery+="     AND EXISTS (SELECT 1 FROM "+RETSQLNAME('SF1')
	_cQuery+="                     WHERE D_E_L_E_T_ = ' '"
	_cQuery+="                       AND DS_CHAVENF = F1_CHVNFE"
	_cQuery+="                       AND DS_FILIAL  = F1_FILIAL)"
    
	If TCSqlExec( _cQuery ) < 0
		FWLogMsg("ERROR"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00730"/*cMsgId*/, "Filial: "+cFilant+"] - Processamento 12 com erro: "+AllTrim(TCSQLError())/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWrite( _nHdlLog , 'Processamento 12 com erro: '+AllTrim(TCSQLError()) + CRLF )	
	Else
		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00731"/*cMsgId*/, "Filial: "+cFilant+"] - Processamento 12 executado com sucesso. Ajustado status para documentos incluídos manualmente."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWrite( _nHdlLog , 'Processamento 12 executado com sucesso. Ajustado status para documentos incluídos manualmente.' + CRLF )	
	EndIf

	//====================================================================================================
	// 10-Reprocessa notas que estão marcadas como processadas, mas não estão na SDS
	//====================================================================================================	
	_cQuery:=" UPDATE "+RETSQLNAME('CKO')
	_cQuery+="    SET CKO_FLAG = '0' "
	_cQuery+="  WHERE D_E_L_E_T_ = ' ' "
	_cQuery+="    AND CKO_FILPRO = '"+cFilAnt+"'"
	_cQuery+="    AND CKO_FLAG = '1' "
	_cQuery+="    AND NOT EXISTS (SELECT 1 FROM "+RETSQLNAME('SDS')
	_cQuery+="    WHERE D_E_L_E_T_ = ' ' "
	_cQuery+="    AND CKO_ARQUIV = DS_ARQUIVO) "
    
	If TCSqlExec( _cQuery ) < 0
		FWLogMsg("ERROR"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00732"/*cMsgId*/, "Filial: "+cFilant+"] - Processamento 13 com erro: "+AllTrim(TCSQLError())/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWrite( _nHdlLog , 'Processamento 13 com erro: '+AllTrim(TCSQLError()) + CRLF )	
	Else
		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00733"/*cMsgId*/, "Filial: "+cFilant+"] - Processamento 13 executado com sucesso. Ajustado status para documentos processados, mas excluídos."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)	
		FWrite( _nHdlLog , 'Processamento 13 executado com sucesso. Ajustado status para documentos processados, mas excluídos.' + CRLF )	
	EndIf

	//====================================================================================================
	// 11-Preenche campos de Empresa e filial pois não consegui reproduzir o problema para repassar para a  
	// TOTVS. Eles não tem essa ocorrência mapeada
	//====================================================================================================	
	_cQuery:=" UPDATE "+RETSQLNAME('CKO')
	_cQuery+="    SET CKO_EMPPRO = '01', "
	_cQuery+="        CKO_FILPRO = '"+cFilAnt+"'"
	_cQuery+="  WHERE D_E_L_E_T_ = ' ' "
	_cQuery+="    AND CKO_FLAG = '1' "
	_cQuery+="    AND CKO_FILPRO = ' ' "
	_cQuery+="    AND EXISTS (SELECT DS_FILIAL "
	_cQuery+="           FROM "+RETSQLNAME('SDS')
	_cQuery+="          WHERE D_E_L_E_T_ = ' ' "
	_cQuery+="            AND DS_FILIAL = '"+cFilAnt+"'"
	_cQuery+="            AND DS_CHAVENF = SubStr(CKO_ARQUIV, 4, 44)) "
	
	If TCSqlExec( _cQuery ) < 0
		FWLogMsg("ERROR"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00736"/*cMsgId*/, "Filial: "+cFilant+"] - Processamento 15 com erro: "+AllTrim(TCSQLError())/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWrite( _nHdlLog , 'Processamento 15 com erro: '+AllTrim(TCSQLError()) + CRLF )	
	Else
		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00737"/*cMsgId*/, "Filial: "+cFilant+"] - Processamento 15 executado com sucesso. Preenche CKO_FILPRO."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWrite( _nHdlLog , 'Processamento 15 executado com sucesso. Preenchido CKO_FILPRO.' + CRLF )	
	EndIf

	//====================================================================================================
	// 12-Limpa os CT-e de Anulação TPCTE=2 (DS_TPCTE=A) para não aparecerem no monitor - COMXCOL
	//====================================================================================================	
	_cQuery:=" UPDATE "+RETSQLNAME('CKO')
	_cQuery+="    SET CKO_FLAG   = '9', " 
	_cQuery+="        CKO_CODERR = 'MCOM04' "
	_cQuery+="           WHERE D_E_L_E_T_ = ' ' "
	_cQuery+="             AND CKO_FILPRO = '"+cFilAnt+"'"
	_cQuery+="             AND CKO_CODEDI = '214' "
	_cQuery+="    		   AND CKO_FLAG <> '9' "
	_cQuery+="    		   AND EXISTS (SELECT 1 FROM "+RETSQLNAME('SDS')
	_cQuery+="    		   WHERE D_E_L_E_T_ = ' ' "
	_cQuery+="    		   AND CKO_ARQUIV = DS_ARQUIVO"
	_cQuery+="             AND DS_TPCTE = 'A' 
	_cQuery+="    		   AND NOT EXISTS 
	_cQuery+="    		   		(SELECT 1 FROM "+RETSQLNAME('SF1')
	_cQuery+="         			WHERE D_E_L_E_T_ = ' '"
	_cQuery+="         			AND DS_FILIAL = F1_FILIAL"
	_cQuery+="         			AND DS_CHAVENF = F1_CHVNFE))"

	If TCSqlExec( _cQuery ) < 0
		FWLogMsg("ERROR"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00738"/*cMsgId*/, "Filial: "+cFilant+"] - Processamento 16 com erro: "+AllTrim(TCSQLError())/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWrite( _nHdlLog , 'Processamento 16 com erro: '+AllTrim(TCSQLError()) + CRLF )	
	Else
		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00739"/*cMsgId*/, "Filial: "+cFilant+"] - Processamento 16 executado com sucesso. CKO_FLAG ajustado para CT-e de Anulação"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWrite( _nHdlLog , 'Processamento 16 executado com sucesso. CKO_FLAG ajustado para CT-e de Anulação' + CRLF )	
	EndIf
	
	//====================================================================================================
	// 12-Limpa os CT-e de Anulação TPCTE=2 (DS_TPCTE=A) para não aparecerem no monitor - Itens das Notas
	//====================================================================================================
	_cQuery:=" UPDATE "+RETSQLNAME('SDT')+" SET D_E_L_E_T_ = '*', R_E_C_D_E_L_ = R_E_C_N_O_ "
	_cQuery+="  WHERE D_E_L_E_T_ = ' ' "
	_cQuery+="  AND DT_FILIAL = '"+cFilAnt+"'"
	_cQuery+="  AND EXISTS "
	_cQuery+="    (SELECT 1 FROM "+RETSQLNAME('SDS')
	_cQuery+="         WHERE D_E_L_E_T_ = ' '"
	_cQuery+="         AND DS_FILIAL = DT_FILIAL"
	_cQuery+="         AND DS_DOC = DT_DOC"
	_cQuery+="         AND DS_SERIE = DT_SERIE"
	_cQuery+="         AND DS_FORNEC = DT_FORNEC"
	_cQuery+="         AND DS_LOJA = DT_LOJA"
	_cQuery+="         AND DS_CNPJ = DT_CNPJ"
	_cQuery+="         AND DS_TPCTE = 'A' 
	_cQuery+="         AND NOT EXISTS 
	_cQuery+="    		(SELECT 1 FROM "+RETSQLNAME('SF1')
	_cQuery+="         		WHERE D_E_L_E_T_ = ' '"
	_cQuery+="         		AND DS_FILIAL = F1_FILIAL"
	_cQuery+="         		AND DS_CHAVENF = F1_CHVNFE))"

	If TCSqlExec( _cQuery ) < 0
		FWLogMsg("ERROR"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00740"/*cMsgId*/, "Filial: "+cFilant+"] - Processamento 17 com erro: "+AllTrim(TCSQLError())/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWrite( _nHdlLog , 'Processamento 17 com erro: '+AllTrim(TCSQLError()) + CRLF )	
	Else
		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00741"/*cMsgId*/, "Filial: "+cFilant+"] - Processamento 17 executado com sucesso. Registros apagados na tabela SDT."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWrite( _nHdlLog , 'Processamento 17 executado com sucesso. Registros apagados na tabela SDT.' + CRLF )	
	EndIf

	//====================================================================================================
	// 12-Limpa os CT-e de Anulação TPCTE=2 (DS_TPCTE=A) para não aparecerem no monitor - Cabeçalho das notas
	//====================================================================================================	
	_cQuery:=" UPDATE "+RETSQLNAME('SDS')+" SET D_E_L_E_T_ = '*', R_E_C_D_E_L_ = R_E_C_N_O_"
	_cQuery+="   WHERE D_E_L_E_T_ = ' '"
	_cQuery+="   AND DS_FILIAL = '"+cFilAnt+"'"
	_cQuery+="   AND DS_TPCTE = 'A'"
	_cQuery+="   AND NOT EXISTS (SELECT 1 FROM "+RETSQLNAME('SF1')
	_cQuery+="   		            WHERE D_E_L_E_T_ = ' '"
	_cQuery+="          		    AND DS_FILIAL = F1_FILIAL"
	_cQuery+="                 		AND DS_CHAVENF = F1_CHVNFE)"
	
	If TCSqlExec( _cQuery ) < 0
		FWLogMsg("ERROR"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00742"/*cMsgId*/, "Filial: "+cFilant+"] - Processamento 18 com erro: "+AllTrim(TCSQLError())/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWrite( _nHdlLog , 'Processamento 18 com erro: '+AllTrim(TCSQLError()) + CRLF )	
	Else
		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00743"/*cMsgId*/, "Filial: "+cFilant+"] - Processamento 18 executado com sucesso. Registros apagados na tabela SDS."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWrite( _nHdlLog , 'Processamento 18 executado com sucesso. Registros apagados na tabela SDS.' + CRLF )	
	EndIf

	//====================================================================================================
	// 13-Recupera as NF-e que foram recusadas, porém foram confirmadas depois.
	//====================================================================================================	
	_cQuery:=" UPDATE "+RETSQLNAME('CKO')+" SET CKO_FLAG = '0', CKO_CODERR = ' ' "
	_cQuery+="  WHERE D_E_L_E_T_ = ' ' "
	_cQuery+="    AND CKO_CODERR IN ('MCOM01', 'MCOM02') "
	_cQuery+="    AND CKO_FLAG = '9' "
	_cQuery+="    AND CKO_FILPRO = '"+cFilAnt+"'"
	_cQuery+="    AND EXISTS (SELECT 1 FROM "+RETSQLNAME('C00')+" "
	_cQuery+="          WHERE D_E_L_E_T_ = ' ' "
	_cQuery+="            AND C00_FILIAL = CKO_FILPRO "
	_cQuery+="            AND C00_CHVNFE = SubStr(CKO_ARQUIV, 4, 44) "
	_cQuery+="            AND C00_CODEVE = '3' "
	_cQuery+="            AND C00_STATUS = '1') "
	
	If TCSqlExec( _cQuery ) < 0
		FWLogMsg("ERROR"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00744"/*cMsgId*/, "Filial: "+cFilant+"] - Processamento 19 com erro: "+AllTrim(TCSQLError())/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWrite( _nHdlLog , 'Processamento 19 com erro: '+AllTrim(TCSQLError()) + CRLF )	
	Else
		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00745"/*cMsgId*/, "Filial: "+cFilant+"] - Processamento 19 executado com sucesso. Registros retornados para a fila de processamento na CKO."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWrite( _nHdlLog , 'Processamento 19 executado com sucesso. Registros retornados para a fila de processamento na CKO.' + CRLF )	
	EndIf

	//==============================================================================================================
	// 14-Limpa as NF-e Formulário Próprio do Fornecedor (DT_CODCFOP < '5000') para não aparecerem no monitor - COMXCOL
	//==============================================================================================================
	_cQuery:=" UPDATE "+RETSQLNAME('CKO')+" SET D_E_L_E_T_ = '*', R_E_C_D_E_L_ = R_E_C_N_O_"
	_cQuery+=" WHERE D_E_L_E_T_ = ' ' "
	_cQuery+=" AND CKO_FILPRO = '"+cFilAnt+"'"
	_cQuery+=" AND CKO_CODEDI = '109' "
	_cQuery+=" AND CKO_FLAG = '1' "
	_cQuery+=" AND EXISTS (SELECT 1 FROM "+RETSQLNAME('SDS') + " SDS, " + RETSQLNAME('SDT') + " SDT "
	_cQuery+="				WHERE SDS.D_E_L_E_T_ = ' ' "
	_cQuery+="				AND SDT.D_E_L_E_T_ = ' ' "
	_cQuery+="				AND CKO_ARQUIV = DS_ARQUIVO"
	_cQuery+="				AND DS_FILIAL = DT_FILIAL"
	_cQuery+="				AND DS_DOC = DT_DOC"
	_cQuery+="				AND DS_SERIE = DT_SERIE"
	_cQuery+="				AND DS_FORNEC = DT_FORNEC"
	_cQuery+="				AND DS_LOJA = DT_LOJA"
	_cQuery+="				AND DT_CODCFOP <> ' '"
	_cQuery+="				AND DT_CODCFOP < '5000'"
	_cQuery+="				AND NOT EXISTS "
	_cQuery+="    		   		(SELECT 1 FROM "+RETSQLNAME('SF1')
	_cQuery+="         			WHERE D_E_L_E_T_ = ' '"
	_cQuery+="         			AND DS_FILIAL = F1_FILIAL"
	_cQuery+="         			AND DS_CHAVENF = F1_CHVNFE))"

	If TCSqlExec( _cQuery ) < 0
		FWLogMsg("ERROR"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00746"/*cMsgId*/, "Filial: "+cFilant+"] - Processamento 20 com erro: "+AllTrim(TCSQLError())/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWrite( _nHdlLog , 'Processamento 20 com erro: '+AllTrim(TCSQLError()) + CRLF )	
	Else
		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00747"/*cMsgId*/, "Filial: "+cFilant+"] - Processamento 20 executado com sucesso. Registros apagados na tabela CKO"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWrite( _nHdlLog , 'Processamento 20 executado com sucesso. Registros apagados na tabela CKO' + CRLF )	
	EndIf

	//===========================================================================================================================
	// 14-Limpa as NF-e Formulário Próprio do Fornecedor (DOCTPOP = '0' pelo MD-e) para não aparecerem no monitor
	//===========================================================================================================================
	_cQuery:=" UPDATE "+RETSQLNAME('CKO')+" SET D_E_L_E_T_ = '*', R_E_C_D_E_L_ = R_E_C_N_O_"
	_cQuery+=" WHERE D_E_L_E_T_ = ' ' "
	_cQuery+=" AND CKO_FILPRO = '"+cFilAnt+"'"
	_cQuery+=" AND CKO_CODEDI = '109' "
	_cQuery+=" AND CKO_FLAG = '2' "
	_cQuery+=" AND EXISTS (SELECT 1 FROM SPED156 WHERE SPED156.D_E_L_E_T_ = ' ' AND SubStr(CKO_ARQUIV,4,44) = DOCCHV AND DOCTPOP = '0')

	If TCSqlExec( _cQuery ) < 0
		FWLogMsg("ERROR"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00754"/*cMsgId*/, "Filial: "+cFilant+"] - Processamento 24 com erro: "+AllTrim(TCSQLError())/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWrite( _nHdlLog , 'Processamento 24 com erro: '+AllTrim(TCSQLError()) + CRLF )	
	Else
		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00755"/*cMsgId*/, "Filial: "+cFilant+"] - Processamento 24 executado com sucesso. Registros apagados na tabela CKO"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWrite( _nHdlLog , 'Processamento 24 executado com sucesso. Registros apagados na tabela CKO' + CRLF )	
	EndIf
	
	//===========================================================================================================================
	// 14-Limpa as NF-e Formulário Próprio do Fornecedor (DT_CODCFOP < '5000') para não aparecerem no monitor - Cabeçalho das notas
	//===========================================================================================================================
	_cQuery:=" UPDATE "+RETSQLNAME('SDS')+" SET D_E_L_E_T_ = '*', R_E_C_D_E_L_ = R_E_C_N_O_"
	_cQuery+="   WHERE D_E_L_E_T_ = ' '"
	_cQuery+="   AND DS_FILIAL = '"+cFilAnt+"'"
	_cQuery+="   AND EXISTS "
	_cQuery+="    (SELECT 1 FROM "+RETSQLNAME('SDT')
	_cQuery+="         WHERE D_E_L_E_T_ = ' '"
	_cQuery+="         AND DS_FILIAL = DT_FILIAL"
	_cQuery+="         AND DS_DOC = DT_DOC"
	_cQuery+="         AND DS_SERIE = DT_SERIE"
	_cQuery+="         AND DS_FORNEC = DT_FORNEC"
	_cQuery+="         AND DS_LOJA = DT_LOJA"
	_cQuery+="  	   AND DT_CODCFOP <> ' '"
	_cQuery+="  	   AND DT_CODCFOP < '5000')"
	_cQuery+="   AND NOT EXISTS (SELECT 1 FROM "+RETSQLNAME('SF1')
	_cQuery+="   		            WHERE D_E_L_E_T_ = ' '"
	_cQuery+="          		    AND DS_FILIAL = F1_FILIAL"
	_cQuery+="                 		AND DS_CHAVENF = F1_CHVNFE)"
	
	If TCSqlExec( _cQuery ) < 0
		FWLogMsg("ERROR"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00748"/*cMsgId*/, "Filial: "+cFilant+"] - Processamento 21 com erro: "+AllTrim(TCSQLError())/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWrite( _nHdlLog , 'Processamento 21 com erro: '+AllTrim(TCSQLError()) + CRLF )	
	Else
		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00749"/*cMsgId*/, "Filial: "+cFilant+"] - Processamento 21 executado com sucesso. Registros apagados na tabela SDS."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWrite( _nHdlLog , 'Processamento 21 executado com sucesso. Registros apagados na tabela SDS.' + CRLF )	
	EndIf

	//======================================================================================================================
	// 14-Limpa as NF-e Formulário Próprio do Fornecedor (DT_CODCFOP < '5000') para não aparecerem no monitor - Itens das Notas
	//======================================================================================================================
	_cQuery:=" UPDATE "+RETSQLNAME('SDT')+" SET D_E_L_E_T_ = '*', R_E_C_D_E_L_ = R_E_C_N_O_ "
	_cQuery+="  WHERE D_E_L_E_T_ = ' ' "
	_cQuery+="  AND DT_FILIAL = '"+cFilAnt+"'"
	_cQuery+="  AND DT_CODCFOP <> ' '"
	_cQuery+="  AND DT_CODCFOP < '5000'"
	_cQuery+="  AND NOT EXISTS "
	_cQuery+="    (SELECT 1 FROM "+RETSQLNAME('SF1')
	_cQuery+="         WHERE D_E_L_E_T_ = ' '"
	_cQuery+="         AND F1_FILIAL = DT_FILIAL"
	_cQuery+="         AND F1_DOC = DT_DOC"
	_cQuery+="         AND F1_SERIE = DT_SERIE"
	_cQuery+="         AND F1_FORNECE = DT_FORNEC"
	_cQuery+="         AND F1_LOJA = DT_LOJA)"	

	If TCSqlExec( _cQuery ) < 0
		FWLogMsg("ERROR"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00750"/*cMsgId*/, "Filial: "+cFilant+"] - Processamento 22 com erro: "+AllTrim(TCSQLError())/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWrite( _nHdlLog , 'Processamento 22 com erro: '+AllTrim(TCSQLError()) + CRLF )	
	Else
		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00751"/*cMsgId*/, "Filial: "+cFilant+"] - Processamento 22 executado com sucesso. Registros apagados na tabela SDT."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWrite( _nHdlLog , 'Processamento 22 executado com sucesso. Registros apagados na tabela SDT.' + CRLF )	
	EndIf

	//====================================================================================================
	// 15-Limpa marcas da SDS para que não classifique documentos indevidos. Ajuste necessário porque a 
	// TOTVS não quis corrigir o problema
	//====================================================================================================	
	_cQuery := " UPDATE " + RetSqlName("CKO") +" SET CKO_I_OK = ' '"
	_cQuery += " WHERE CKO_I_OK <> ' ' AND D_E_L_E_T_ = ' '"
	TCSqlExec(_cQuery)

	_cQuery:=" UPDATE " + RetSqlName("SDS") +" SET DS_OK = ' ' "
	_cQuery+=" WHERE DS_OK <> ' ' AND D_E_L_E_T_ = ' ' "
    TCSqlExec(_cQuery)

	//===================================================================================================================================
	// 16-Limpa as notas que não são processadas pelo TOTVS Colaboração para não aparecerem no monitor. Apenas as que foram escrituradas
	// para que as que não foram, sejam identificadas como pendentes. Notas de Complemento de impostos
	//==================================================================================================================================
	_cQuery:=" UPDATE "+RETSQLNAME('CKO')
	_cQuery+="    SET CKO_FLAG   = '9' " 
	_cQuery+="           WHERE D_E_L_E_T_ = ' ' "
	_cQuery+="             AND CKO_FILPRO = '"+cFilAnt+"'"
	_cQuery+="    		   AND CKO_FLAG <> '9' "
	_cQuery+="    		   AND CKO_CODERR IN ('COM003','COM004','COM047')"
	_cQuery+="    AND EXISTS (SELECT 1 "
	_cQuery+="           FROM "+RETSQLNAME('SF1')
	_cQuery+="          WHERE D_E_L_E_T_ = ' ' "
	_cQuery+="            AND F1_FILIAL = '"+cFilAnt+"'"
	_cQuery+="            AND F1_CHVNFE = SubStr(CKO_ARQUIV, 4, 44)) "
	    
	If TCSqlExec( _cQuery ) < 0
		FWLogMsg("ERROR"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00756"/*cMsgId*/, "Filial: "+cFilant+"] - Processamento 25 com erro: "+AllTrim(TCSQLError())/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWrite( _nHdlLog , 'Processamento 25 com erro: '+AllTrim(TCSQLError()) + CRLF )	
	Else
		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00757"/*cMsgId*/, "Filial: "+cFilant+"] - Processamento 25 executado com sucesso. CKO_FLAG ajustado para documentos não processados."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWrite( _nHdlLog , 'Processamento 25 executado com sucesso. CKO_FLAG ajustado para documentos não processados.' + CRLF )	
	EndIf

	//===================================================================================================================================
	// 17-Corrije status dos documentos cancelados na C00
	//==================================================================================================================================
	_cQuery:=" UPDATE "+RETSQLNAME('C00')
	_cQuery+="    SET C00_SITDOC = '3' " 
	_cQuery+="   WHERE D_E_L_E_T_ = ' ' "
	_cQuery+="    AND C00_FILIAL = '"+cFilAnt+"'"
	_cQuery+="    AND C00_SITDOC <> '3' "
	_cQuery+="    AND EXISTS (SELECT 1 "
	_cQuery+="           FROM "+RETSQLNAME('CKO')
	_cQuery+="          WHERE D_E_L_E_T_ = ' ' "
	_cQuery+="            AND C00_FILIAL = CKO_FILPRO"
	_cQuery+="            AND CKO_FLAG = '9'
	_cQuery+="            AND C00_CHVNFE = SubStr(CKO_ARQUIV, 4, 44) "
	_cQuery+="            AND CKO_CODERR = 'COM040')"
	    
	If TCSqlExec( _cQuery ) < 0
		FWLogMsg("ERROR"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00758"/*cMsgId*/, "Filial: "+cFilant+"] - Processamento 26 com erro: "+AllTrim(TCSQLError())/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWrite( _nHdlLog , 'Processamento 26 com erro: '+AllTrim(TCSQLError()) + CRLF )	
	Else
		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00759"/*cMsgId*/, "Filial: "+cFilant+"] - Processamento 26 executado com sucesso. C00_SITDOC ajustado para documento cancelado."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWrite( _nHdlLog , 'Processamento 26 executado com sucesso. C00_SITDOC ajustado para documento cancelado.' + CRLF )	
	EndIf

	//===================================================================================================================================
	// 17-Apaga C00 para documentos cancelados
	//==================================================================================================================================
	_cQuery:=" UPDATE "+RETSQLNAME('C00')
	_cQuery+="    SET D_E_L_E_T_ = '*', R_E_C_D_E_L_ = R_E_C_N_O_ " 
	_cQuery+="   WHERE D_E_L_E_T_ = ' ' "
	_cQuery+="    AND C00_FILIAL = '"+cFilAnt+"'"
	_cQuery+="    AND C00_SITDOC = '3' "
	_cQuery+="    AND C00_STATUS = '0' "
	_cQuery+="    AND C00_CODEVE = '1' "
	    
	If TCSqlExec( _cQuery ) < 0
		FWLogMsg("ERROR"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00760"/*cMsgId*/, "Filial: "+cFilant+"] - Processamento 27 com erro: "+AllTrim(TCSQLError())/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWrite( _nHdlLog , 'Processamento 27 com erro: '+AllTrim(TCSQLError()) + CRLF )	
	Else
		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00761"/*cMsgId*/, "Filial: "+cFilant+"] - Processamento 27 executado com sucesso. Apaga C00 para documento cancelado."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWrite( _nHdlLog , 'Processamento 27 executado com sucesso. Apaga C00 para documento cancelado.' + CRLF )	
	EndIf

	//============================================================================================================================================================
	// 18-Reprocessa notas que estão com status incompatíveis com nosso processo (CKO_FLAG=4) ou processos que não consegui reproduzir para repassar para a TOTVS
	//CKO_FLAG=3 -> Pela TOTVS deveria existir apenas {"COM005","COM006","COM019"} que seria o cenário onde recebo o mesmo XML com chaves diferentes. 
	//Isso não acontece, mas está sendo registrado o status 3 para outros tipos de erro, indevidamente.
	//============================================================================================================================================================
	_cQuery:=" UPDATE "+RETSQLNAME('CKO')
	_cQuery+="    SET CKO_FLAG = '0' "
	_cQuery+="  WHERE D_E_L_E_T_ = ' ' "
	_cQuery+="    AND CKO_FILPRO = '"+cFilAnt+"'"
	_cQuery+="    AND ((CKO_FLAG = '3' AND CKO_CODERR NOT IN ('COM005','COM006','COM019','COM025'))"
	_cQuery+="    OR CKO_FLAG = '4')
    
	If TCSqlExec( _cQuery ) < 0
		FWLogMsg("ERROR"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00762"/*cMsgId*/, "Filial: "+cFilant+"] - Processamento 28 com erro: "+AllTrim(TCSQLError())/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWrite( _nHdlLog , 'Processamento 28 com erro: '+AllTrim(TCSQLError()) + CRLF )	
	Else
		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM007063"/*cMsgId*/, "Filial: "+cFilant+"] - Processamento 28 executado com sucesso. Ajustado status para documentos fora da lista de reprocesso."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)	
		FWrite( _nHdlLog , 'Processamento 28 executado com sucesso. Ajustado status para documentos fora da lista de reprocesso' + CRLF )	
	EndIf

FWRestArea(_aArea)
    
Return

/*
===============================================================================================================================
Programa----------: MCOM007C
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 25/05/2017
Descrição---------: Executa Consulta na SEFAZ para verificar os documentos que estão cancelados e excluílos.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MCOM007C(_nHdlLog,_lScheduler,_aLog)

Local _aArea 	:= FWGetArea()
Local _cAlias	:= GetNextAlias()
Local _lRet 	:= .T.
Local cURL      := PadR(GetNewPar("MV_SPEDURL","http://"),250)
Local cIdEnt   	:= ""
Local _cChave	:= ""
Local _cFilial	:= "" 
Local _nI		:= 0
Local _cEspecie := ''
Local _lCons	:= .F.

If  EntAtivTss() .And. CTIsReady()
  	//Obtem o codigo da entidade 
	oWS := WsSPEDAdm():New()
	oWS:cUSERTOKEN := "TOTVS"
	oWS:oWSEMPRESA:cCNPJ       := IIf(SM0->M0_TPINSC==2 .Or. Empty(SM0->M0_TPINSC),SM0->M0_CGC,"")	
	oWS:oWSEMPRESA:cCPF        := IIf(SM0->M0_TPINSC==3,SM0->M0_CGC,"")
	oWS:oWSEMPRESA:cIE         := SM0->M0_INSC
	oWS:oWSEMPRESA:cIM         := SM0->M0_INSCM		
	oWS:oWSEMPRESA:cNOME       := SM0->M0_NOMECOM
	oWS:oWSEMPRESA:cFANTASIA   := SM0->M0_NOME
	oWS:oWSEMPRESA:cENDERECO   := FisGetEnd(SM0->M0_ENDENT)[1]
	oWS:oWSEMPRESA:cNUM        := FisGetEnd(SM0->M0_ENDENT)[3]
	oWS:oWSEMPRESA:cCOMPL      := FisGetEnd(SM0->M0_ENDENT)[4]
	oWS:oWSEMPRESA:cUF         := SM0->M0_ESTENT
	oWS:oWSEMPRESA:cCEP        := SM0->M0_CEPENT
	oWS:oWSEMPRESA:cCOD_MUN    := SM0->M0_CODMUN
	oWS:oWSEMPRESA:cCOD_PAIS   := "1058"
	oWS:oWSEMPRESA:cBAIRRO     := SM0->M0_BAIRENT
	oWS:oWSEMPRESA:cMUN        := SM0->M0_CIDENT
	oWS:oWSEMPRESA:cCEP_CP     := Nil
	oWS:oWSEMPRESA:cCP         := Nil
	oWS:oWSEMPRESA:cDDD        := Str(FisGetTel(SM0->M0_TEL)[2],3)
	oWS:oWSEMPRESA:cFONE       := AllTrim(Str(FisGetTel(SM0->M0_TEL)[3],15))
	oWS:oWSEMPRESA:cFAX        := AllTrim(Str(FisGetTel(SM0->M0_FAX)[3],15))
	oWS:oWSEMPRESA:cEMAIL      := UsrRetMail(RetCodUsr())
	oWS:oWSEMPRESA:cNIRE       := SM0->M0_NIRE
	oWS:oWSEMPRESA:dDTRE       := SM0->M0_DTRE
	oWS:oWSEMPRESA:cNIT        := IIf(SM0->M0_TPINSC==1,SM0->M0_CGC,"")
	oWS:oWSEMPRESA:cINDSITESP  := ""
	oWS:oWSEMPRESA:cID_MATRIZ  := ""
	oWS:oWSOUTRASINSCRICOES:oWSInscricao := SPEDADM_ARRAYOFSPED_GENERICSTRUCT():New()
	oWS:_URL := AllTrim(cURL)+"/SPEDADM.apw"

	If oWS:ADMEMPRESAS()
		cIdEnt  := oWs:cADMEMPRESASRESULT
		oWS:= WsNFeSBra():New()
		oWS:cUserToken   := "TOTVS"
		oWs:cID_ENT      := cIdEnt
		oWS:_URL         := AllTrim(cURL)+"/NFeSBRA.apw"
	
		//====================================================================================================
		// Levanta todas as chaves que foram recebidas e/ou escrituradas para chegar cada uma
		//====================================================================================================
		BeginSql Alias _cAlias
			SELECT RTRIM(CKO.CKO_FILPRO) FILIAL, SubStr(CKO_ARQUIV,4,44) CHAVE
			FROM  %Table:CKO% CKO
			WHERE CKO.%NotDel%
			AND CKO.CKO_FLAG <> '9'
			AND CKO.CKO_DT_IMP BETWEEN %exp:MV_PAR01% AND %exp:MV_PAR02%
			AND CKO.CKO_FILPRO = %exp:cFilAnt%
			UNION
			SELECT SF1.F1_FILIAL FILIAL, SF1.F1_CHVNFE CHAVE
			FROM %Table:SF1% SF1
			WHERE SF1.%NotDel%
			AND SF1.F1_DTDIGIT BETWEEN %exp:MV_PAR01% AND %exp:MV_PAR02%
			AND SF1.F1_FILIAL = %exp:cFilAnt%
			AND SF1.F1_FORMUL <> 'S'
			AND SF1.F1_ESPECIE IN ('SPED','CTE','CTEOS')
			UNION
			SELECT C00.C00_FILIAL FILIAL, C00.C00_CHVNFE CHAVE
			FROM %Table:C00% C00
			WHERE C00.%NotDel%
			AND C00.C00_DTREC BETWEEN %exp:MV_PAR01% AND %exp:MV_PAR02%
			AND C00.C00_FILIAL = %exp:cFilAnt%
			AND C00.C00_STATUS = '0'
			AND C00.C00_CODEVE = '1  '
			AND C00.C00_SITDOC = '1'
		EndSql
		aAdd(_aLog,{"Filial","Documento","Serie","Forn","Loja","Especie","Chave"+ Replicate(CHR(09),5),"Clas","Digitação"})

		DBSelectArea("SF1")
		SF1->(DBSetOrder(8))
		DBSelectArea("SDS")
		SDS->(DBSetOrder(2))
		DBSelectArea("SDT")
		SDT->(DBSetOrder(3))
		DBSelectArea("CKO")
		CKO->(DBSetOrder(1))
		DBSelectArea("C00")
		C00->(DBSetOrder(1))

		While (_cAlias)->( !Eof() )			                             
			_lRet:= .T.
			_lCons:=.F.
			_cChave:= AllTrim((_cAlias)->CHAVE)
			_cFilial:= AllTrim((_cAlias)->FILIAL)
			oWS:cCHVNFE := _cChave
			
			For _nI := 1 to 5
				_lCons := oWS:ConsultaChaveNFE()
				If _lCons
					Exit
				Else
					Sleep(1000)//Aguarda 2 segundos para não sobrecarregar o TSS na tentativa de evitar as falhas constantes de falta de retorno
				EndIf
			Next _nI

			If _lCons
				//====================================
				//101 -> Cancelada
				//102 -> Inutilizada
				//155 -> Cancelada fora do prazo
				//205 -> Denegada
				//301 -> Denegada emitente
				//302 -> Denegada destinatário
				//====================================
				If AllTrim(oWS:oWSCONSULTACHAVENFERESULT:cCODRETNFE) $ '101/102/155/205/301/302'
					//Verifica se documento já foi gerado
					If SF1->(DBSeek(_cFilial+_cChave))
						_lRet:= .F.
						aAdd(_aLog,{SF1->F1_FILIAL,SF1->F1_DOC,SF1->F1_SERIE,SF1->F1_FORNECE,SF1->F1_LOJA,SF1->F1_ESPECIE,SF1->F1_CHVNFE,IIf(SF1->F1_STATUS=='A','SIM','NAO'),DToC(SF1->F1_DTDIGIT)})
					EndIf
		
					//Deleta cabecalho do documento
					If _lRet .And. SDS->(DBSeek(_cFilial+_cChave))
						RecLock("SDS",.F.)
						SDS->(dbDelete())
						SDS->(MSUnLock())
					
						//Deleta itens do documento 
						If _lRet .And. SDT->(DBSeek(SDS->(DS_FILIAL+DS_FORNEC+DS_LOJA+DS_DOC+DS_SERIE)))
							While !SDT->(Eof()) .And. SDT->(DT_FILIAL+DT_FORNEC+DT_LOJA+DT_DOC+DT_SERIE) == SDS->(DS_FILIAL+DS_FORNEC+DS_LOJA+DS_DOC+DS_SERIE) 
								RecLock("SDT",.F.)
								SDT->(dbDelete())
								SDT->(MSUnLock())		
								SDT->(DBSkip())
							End
						EndIf
					EndIf
								
					If SubStr(_cChave,21,2)=='55'
						_cChave:= '109'+AllTrim((_cAlias)->CHAVE)+'.xml'
						_cEspecie:= 'SPED'
					ElseIf SubStr(_cChave,21,2)=='57'
						_cChave:= '214'+AllTrim((_cAlias)->CHAVE)+'.xml'
						_cEspecie:= 'CTE'
					ElseIf SubStr(_cChave,21,2)=='67'
						_cChave:= '273'+AllTrim((_cAlias)->CHAVE)+'.xml'
						_cEspecie:= 'CTEOS'
					Else
						_cEspecie:= ''
					EndIf
						
					//Atualiza status na fila de processamento
					If _lRet .And. CKO->(DBSeek(_cChave)) .And. (_cAlias)->FILIAL == CKO->CKO_FILPRO
						RecLock("CKO",.F.)
						CKO->CKO_FLAG := '9'
						If AllTrim(oWS:oWSCONSULTACHAVENFERESULT:cCODRETNFE) $ '101/155'
							If _cEspecie=='SPED'
								CKO->CKO_CODERR := 'COM040'
							ElseIf _cEspecie=='CTE'
								CKO->CKO_CODERR := 'COM036'
							ElseIf _cEspecie=='CTEOS'
								CKO->CKO_CODERR := 'COM045'
							EndIf
						Else 
							If _cEspecie=='SPED'
								CKO->CKO_CODERR := 'COM041'
							ElseIf _cEspecie=='CTE'
								CKO->CKO_CODERR := 'COM037'
							ElseIf _cEspecie=='CTEOS'
								CKO->CKO_CODERR := 'COM046'
							EndIf
						EndIf
						CKO->(MSUnLock())
					EndIf

					//Apaga registros cancelados pois não podem ser manifestados
					If _lRet .And. _cEspecie == 'SPED' .And. AllTrim(oWS:oWSCONSULTACHAVENFERESULT:cCODRETNFE) $ '101/155' ;
						.And.C00->(DBSeek((_cAlias)->FILIAL+AllTrim((_cAlias)->CHAVE))) .And. C00->C00_STATUS == '0' .And. C00->C00_CODEVE == '1  '
						RecLock("C00",.F.)
						C00->C00_SITDOC := '3'
						C00->(dbDelete())
						C00->(MSUnLock())
					EndIf				
				EndIf
			Else	
				FWLogMsg("WARN"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00736"/*cMsgId*/, "Filial: "+cFilant+"] - Problemas no TSS, Consulta Chave: "+IIf(Empty(GetWscError(3)),GetWscError(1),GetWscError(3))/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
				If !_lScheduler
					Aviso("SPED",IIf(Empty(GetWscError(3)),GetWscError(1),GetWscError(3)),{"OK"},3)
				EndIf
				If SF1->(DBSeek(AllTrim((_cAlias)->FILIAL)+AllTrim((_cAlias)->CHAVE)))
					aAdd(_aLog,{SF1->F1_FILIAL,SF1->F1_DOC,SF1->F1_SERIE,SF1->F1_FORNECE,SF1->F1_LOJA,SF1->F1_ESPECIE,SF1->F1_CHVNFE,IIf(SF1->F1_STATUS=='A','SIM','NAO'),DToC(SF1->F1_DTDIGIT) + ' Erro ao Consultar a chave. Acionar a TI.'})
				EndIf
				FWrite( _nHdlLog , 'Problemas no TSS, Consulta Chave: ' +SF1->F1_CHVNFE +' - ' + DToC(Date()) +' - '+ Time() +' Filial: ' + cFilAnt + ' Erro: ' + IIf(Empty(GetWscError(3)),GetWscError(1),GetWscError(3)) + CRLF )	
			EndIf
		(_cAlias)->( DBSkip() )
		
		EndDo
		(_cAlias)->(DBCloseArea())
		If Len(_aLog)==1
			FWrite( _nHdlLog , 'Registros processados sem inconsistências.' + CRLF )
		Else
			For _nI := 1 To Len(_aLog)
				FWrite( _nHdlLog , _aLog[_nI][1] +Char(09)+_aLog[_nI][2]+ CHR(09)+_aLog[_nI][3] + CHR(09)+_aLog[_nI][4] + CHR(09)+_aLog[_nI][5] + CHR(09)+_aLog[_nI][6] + CHR(09)+_aLog[_nI][7] + CHR(09)+_aLog[_nI][8] + CHR(09)+_aLog[_nI][9] + CRLF )
			Next _nI
	
		EndIf
	Else
		FWLogMsg("WARN"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00735"/*cMsgId*/, "Filial: "+cFilant+"] - Problemas no TSS: "+IIf(Empty(GetWscError(3)),GetWscError(1),GetWscError(3))/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		If !_lScheduler
			Aviso("SPED",IIf(Empty(GetWscError(3)),GetWscError(1),GetWscError(3)),{"OK"},3)
		EndIf
		FWrite( _nHdlLog , 'Problemas no TSS. ' + DToC(Date()) +' - '+ Time() +' Filial: ' + cFilAnt + ' Erro: ' + IIf(Empty(GetWscError(3)),GetWscError(1),GetWscError(3)) + CRLF )	
	EndIf
Else
	FWLogMsg("WARN"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00737"/*cMsgId*/, "Filial: "+cFilant+"] - TSS Inativo."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	FWrite( _nHdlLog , 'TSS Inativo. ' + DToC(Date()) +' - '+ Time() +' Filial: ' + cFilAnt + CRLF )	
EndIf

FClose(_nHdlLog)
FWRestArea(_aArea)

Return

/*
===============================================================================================================================
Programa----------: SchedDef
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 25/05/2017
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

/*
===============================================================================================================================
Programa----------: MCOM007E
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 25/05/2017
Descrição---------: Executa envio do e-mails com os logs para os usuários habilitados para tal.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MCOM007E(_cArqLog,_aLog)

Local _nI		:= 0
Local _cAssunto	:= "Análise XMLs TOTVS Colaboração: "+ DToC(MV_PAR01)+" - "+ DToC(MV_PAR02)+" Filial: "+cFilAnt
Local _cMensagem:= ""
Local _cErro	:= ""
Local _cAlias	:= GetNextAlias()
Local _cFilAnt	:= "%'%"+cFilAnt+"%'%"

_cMensagem := '<HMTL>'
_cMensagem += '<HEAD>'
_cMensagem += '<META http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />'
_cMensagem += '<TITLE>TOTVS Colaboração</TITLE>'
_cMensagem += '</HEAD>'
_cMensagem += '<BODY><br>'
_cMensagem += '<FONT FACE="Courier New" Style="font-size:12px">'
_cMensagem += '-------------------------------------------------------------------------------------------------------<br>'
_cMensagem += ' Ambiente.........: '+ GetEnvServer() +'<br>'
_cMensagem += ' Data Proc........: '+ DToC( Date() ) +'<br>'
_cMensagem += ' Hora.............: '+ Time() +'<br>'
_cMensagem += '-------------------------------------------------------------------------------------------------------<br>'
For _nI := 1 To Len(_aLog)
	_cMensagem +=  '<pre>'+_aLog[_nI][1]+Char(09)+_aLog[_nI][2]+Char(09)+_aLog[_nI][3]+Char(09)+_aLog[_nI][4]+Char(09)+_aLog[_nI][5]+Char(09)+_aLog[_nI][6]+Char(09)+_aLog[_nI][7]+Char(09)+_aLog[_nI][8]+Char(09)+_aLog[_nI][9]+'</pre>'
Next _nI
If Len(_aLog)==3
	_cMensagem += 'Registros processados sem inconsistências.<br><br>'
EndIf
_cMensagem += '=======================================================================================================<br>'
_cMensagem += '<i><b> Atenção: essa é uma mensagem automática, favor não responder. </b></i>                          <br>'
_cMensagem += '=======================================================================================================<br>'
_cMensagem += '</FONT>'
_cMensagem += '</BODY>'
_cMensagem += '</HMTL>'

BeginSql Alias _cAlias
	SELECT ZZL_EMAIL 
	FROM %Table:ZZL%
	WHERE D_E_L_E_T_ =' '
	AND ZZL_FILIAL = %xFilial:ZZL%
	AND ZZL_WFTCOL LIKE %exp:_cFilAnt%
EndSql

While (_cAlias)->( !Eof() )
	U_EnvMail(_cMensagem,/*_cFrom*/,(_cAlias)->ZZL_EMAIL/*_cTO*/,/*_cCC*/,/*_cBCC*/,/*_cReplyTo*/,_cAssunto,_cErro,{_cArqLog}/*_aAttach*/)
	FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00738"/*cMsgId*/, "Filial: "+cFilant+"] - E-mail:" + AllTrim((_cAlias)->ZZL_EMAIL) + " Resultado: " +AllTrim(_cErro)/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	(_cAlias)->( DBSkip() )
EndDo
(_cAlias)->( DBCloseArea() )		
Return
