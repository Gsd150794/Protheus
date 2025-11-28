/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |10/01/2019| Chamado 23984. Incluído tratamento para CTeOS
Lucas Borges  |26/01/2022| Chamado 39016, 39017, 39012. Criar validação se operação de exclusão foi efetiva
Lucas Borges  |10/06/2025| Chamado 50943. Retirada validação para permitir recuperar 610110
===============================================================================================================================
*/

#Include "TOTVS.ch" 

/*
===============================================================================================================================
Programa----------: MCOM006
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 28/03/2017
Descrição---------: Rotina para realizar manutenções nos XMLs do TOTVS Colaboração
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MCOM006

Local _aArea 	:= FWGetArea() As Array
Local _cChaveNFe:= Space(44) As Character
Local oDlgKey	:= Nil As Object
Local oBtnOut	:= Nil As Object
Local oBtnCon	:= Nil As Object

DEFINE MSDIALOG oDlgKey TITLE "Manutenção XML" FROM 0,0 TO 150,305 PIXEL OF GetWndDefault()

@ 12,008 Say "Esta rotina possibilida excluir ou recuperar XML"+ CRLF +"independente de qualquer validação.";
+ CRLF + "Informe a Chave de acesso: " PIXEL OF oDlgKey
@ 33,008 MSGET _cChaveNFe SIZE 140,10 PIXEL OF oDlgKey

@ 50,015 BUTTON oBtnCon PROMPT "&Excluir" SIZE 38,11 PIXEL ACTION (IIf(!Empty(_cChaveNFe),ExcMonitor(_cChaveNFe),;
		MsgStop("Chave não informada.","MCOM00601" )) , oDlgKey:End())
@ 50,055 BUTTON oBtnCon PROMPT "&Recuperar" SIZE 38,11 PIXEL ACTION (IIf(!Empty(_cChaveNFe),RecMonitor(_cChaveNFe),;
		MsgStop("Chave não informada.","MCOM00602" )) , oDlgKey:End())
@ 50,095 BUTTON oBtnOut PROMPT "&Sair" SIZE 38,11 PIXEL ACTION oDlgKey:End()

ACTIVATE DIALOG oDlgKey CENTERED

FWRestArea(_aArea)
	
Return

/*
===============================================================================================================================
Programa----------: ExcMonitor
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 28/03/2017
Descrição---------: Marca chave informada como "excluída" da fila do Colaboração. Não aparecendo mais em nenhum local
Parametros--------: _cChaveNFe - Chave da NF-e
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ExcMonitor(_cChaveNFe As Character)

Local _lRet  	:= .F. As Logical
Local _cArquiv 	:= '' As Character
Local _cEspecie := '' As Character
Local cURL      := PadR(GetNewPar("MV_SPEDURL","http://"),250) As Character
Local cIdEnt   	:= '' As Character
Local _cCodRet	:= '' As Character
Local _nAmbiente:= 0 As Numeric
Local _cAlias150:= "" As Character
Local _cAlias	:= GetNextAlias() As Character

DBSelectArea("SF1")
SF1->(DBSetOrder(8))
//-- Verifica se documento já foi gerado
If SF1->(DBSeek(xFilial("SF1") + _cChaveNFe))
	FWAlertInfo("Chave informada já consta no Documento de entrada."+ CRLF + "Exclua o registo e tente novamente.","MCOM00604")
	Return	
EndIf

If SubStr(_cChaveNFe,21,2)=='55'
	_cArquiv:= '109'+_cChaveNFe+'.xml'
	_cEspecie:= 'SPED'
ElseIf SubStr(_cChaveNFe,21,2)=='57'
	_cArquiv:= '214'+_cChaveNFe+'.xml'
	_cEspecie:= 'CTE'
ElseIf SubStr(_cChaveNFe,21,2)=='67'
	_cArquiv:= '273'+_cChaveNFe+'.xml'
	_cEspecie:= 'CTEOS'
EndIf

If CTIsReady()
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
	Else
		FWAlertWarning(IIf(Empty(GetWscError(3)),GetWscError(1),GetWscError(3)),"MCOM00613")
		Return
	EndIf
			
	oWS:= WsNFeSBra():New()
	oWS:cUserToken   := "TOTVS"
	oWs:cID_ENT      := cIdEnt
	ows:cCHVNFE		 := _cChaveNFe
	oWS:_URL         := AllTrim(cURL)+"/NFeSBRA.apw"
Else
	FWAlertWarning("Execute o módulo de configuração do serviço, antes de utilizar esta opção!!!","MCOM00612")
	Return
EndIf
		
//	oWS:cCHVNFE := _cChaveNFe
If oWS:ConsultaChaveNFE()
	DBSelectArea("SDS")
	SDS->(DBSetOrder(2))
	//-- Deleta cabecalho do documento
	If SDS->(DBSeek(xFilial("SDS") + _cChaveNFe)) .And. !SDS->DS_STATUS == 'P'
		RecLock("SDS",.F.)
		SDS->(dbDelete())
		SDS->(MSUnLock())
		_lRet := .T.
	EndIf

	DBSelectArea("SDT")
	SDT->(DBSetOrder(3))
	//-- Deleta itens do documento 
	If _lRet .And. SDT->(DBSeek(SDS->(DS_FILIAL+DS_FORNEC+DS_LOJA+DS_DOC+DS_SERIE)))
		While !SDT->(Eof()) .And. SDT->(DT_FILIAL+DT_FORNEC+DT_LOJA+DT_DOC+DT_SERIE) == SDS->(DS_FILIAL+DS_FORNEC+DS_LOJA+DS_DOC+DS_SERIE) 
			RecLock("SDT",.F.)
			SDT->(dbDelete())
			SDT->(MSUnLock())		
			SDT->(DBSkip())
		End
	EndIf
	
	BeginSql Alias _cAlias
		SELECT COUNT(1) QTD FROM %Table:SDS% WHERE D_E_L_E_T_ = ' ' AND DS_FILIAL = %xFilial:SDS% AND DS_CHAVENF = %exp:_cChaveNFe%
	EndSql

	If (_cAlias)->QTD == 0
		//====================================
		//101 -> Cancelada
		//102 -> Inutilizada
		//155 -> Cancelada fora do prazo
		//205 -> Denegada
		//301 -> Denegada emitente
		//302 -> Denegada destinatário
		//303 -> Denegada Destinatário não habilitado a operar na UF
		//====================================
		_cCodRet:= AllTrim(oWS:oWSCONSULTACHAVENFERESULT:cCODRETNFE)
		_nAmbiente	:= oWS:oWSCONSULTACHAVENFERESULT:nAMBIENTE
		
		//Atualiza status na fila de processamento
		DBSelectArea("CKO")
		CKO->(DBSetOrder(1))
		If CKO->(DBSeek(_cArquiv)) .And. cFilAnt == AllTrim(CKO->CKO_FILPRO)
			If _cCodRet $ '101/155'
				RecLock("CKO",.F.)
				CKO->CKO_FLAG := '9'
				If _cEspecie=='SPED'
					CKO->CKO_CODERR := 'COM040'
				ElseIf _cEspecie=='CTE'
					CKO->CKO_CODERR := 'COM036'
				ElseIf _cEspecie=='CTEOS'
					CKO->CKO_CODERR := 'COM045'
				EndIf
				CKO->(MSUnLock())
			ElseIf _cCodRet $ '102/205/301/302/303'
				RecLock("CKO",.F.)
				CKO->CKO_FLAG := '9'
				If _cEspecie=='SPED'
					CKO->CKO_CODERR := 'COM041'
				ElseIf _cEspecie=='CTE'
					CKO->CKO_CODERR := 'COM037'
				ElseIf _cEspecie=='CTEOS'
					CKO->CKO_CODERR := 'COM046'
				EndIf
				CKO->(MSUnLock())
			ElseIf _cEspecie == 'SPED'
				//============================================================================
				//Verifica se NF-e recebeu alguma manifestação informando que a operçação não 
				//foi realizada (3) ou que é desconhecida (2). Nesses status não é necessário
				//reprocessar o documeto.
				//============================================================================
				DBSelectArea("C00")
				C00->(DBSetOrder(1))
				If C00->(DBSeek(xFilial("C00")+_cChaveNFe)) .And. C00->C00_CODEVE=="3  "
					If C00->C00_STATUS $ "2/3"
						RecLock("CKO",.F.)
						CKO->CKO_FLAG := '9'
						CKO->CKO_CODERR := IIf(C00->C00_STATUS=='2','MCOM01','MCOM02')
						CKO->(MSUnLock())
					Else
						RecLock("CKO",.F.)
						CKO->CKO_FLAG := '9'
						CKO->CKO_CODERR := 'MCOM06'
						CKO->(MSUnLock())
					EndIf
				Else
					RecLock("CKO",.F.)
					CKO->CKO_FLAG := '9'
					CKO->CKO_CODERR := 'MCOM06'
					CKO->(MSUnLock())
				EndIf
				C00->(DBCloseArea())
			ElseIf _cEspecie == 'CTE'
				//============================================================================
				//Verifica se CT-e foi recusado pelo evento 610110 - Prestação de Serviço 
				//em Desacordo
				//============================================================================
				_cAlias150	:= GetNextAlias()
		
				BeginSql Alias _cAlias150
				SELECT 1 ACHOU
					FROM SPED150
				WHERE SPED150.D_E_L_E_T_ = ' '
					AND SPED150.NFE_CHV = %exp:_cChaveNFe%
					AND SPED150.ID_ENT = %exp:cIdEnt%
					AND SPED150.TPEVENTO = '610110'
					AND SPED150.AMBIENTE = %exp:_nAmbiente%
					AND SPED150.STATUS = 6
					AND SPED150.R_E_C_N_O_ =
								(SELECT MAX(B.R_E_C_N_O_)
									FROM SPED150 B
									WHERE B.D_E_L_E_T_ = ' '
									AND B.NFE_CHV = SPED150.NFE_CHV
									AND B.ID_ENT = SPED150.ID_ENT)
				EndSql
							
				If (_cAlias150)->ACHOU == 1
					RecLock("CKO",.F.)
					CKO->CKO_FLAG := '9'
					CKO->CKO_CODERR := 'MCOM03'
					CKO->(MSUnLock())
				Else
					RecLock("CKO",.F.)
					CKO->CKO_FLAG := '9'
					CKO->CKO_CODERR := 'MCOM06'
					CKO->(MSUnLock())
				EndIf
				(_cAlias150)->(DBCloseArea())
			Else
				RecLock("CKO",.F.)
				CKO->CKO_FLAG := '9'
				CKO->CKO_CODERR := 'MCOM06'
				CKO->(MSUnLock())
			EndIf
			_lRet := .T.
		EndIf
	EndIf
	(_cAlias)->(DBCloseArea())
	//============================================================================
	//Se o documento For cancelado não se deve realizar nenhum tipo de manifestação
	//Excluir registro para evitar manifestação indevida.
	//============================================================================
	DBSelectArea("C00")
	C00->(DBSetOrder(1))
	If _cEspecie == 'SPED' .And. _cCodRet $ '101/155' .And. C00->(DBSeek(xFilial("C00")+_cChaveNFe)) ;
		.And. C00->C00_STATUS == '0' .And. C00->C00_CODEVE == '1  '
		RecLock("C00",.F.)
		C00->C00_SITDOC := '3'
		C00->(dbDelete())
		C00->(MSUnLock())
	EndIf
	C00->(DBCloseArea())
Else	
	FWAlertWarning(IIf(Empty(GetWscError(3)),GetWscError(1),GetWscError(3)),"MCOM00611")
EndIf

If _lRet
	FWAlertInfo("Chave excluída com sucesso.","MCOM00605")
Else
	FWAlertWarning("Chave não lozalida para exclusão.","MCOM00606")
EndIf

Return

/*
===============================================================================================================================
Programa----------: RecMonitor
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 28/03/2017
Descrição---------: Recupera registro "excluído" da fila do Colaboração
Parametros--------: _cChaveNFe - Chave da NF-e
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RecMonitor(_cChaveNFe As Character)

Local _lRecup := .F. As Logical
Local _cArquiv := '' As Character

If SubStr(_cChaveNFe,21,2)=='55'
	_cArquiv:= '109'+_cChaveNFe+'.xml'
ElseIf SubStr(_cChaveNFe,21,2)=='57'
	_cArquiv:= '214'+_cChaveNFe+'.xml'
ElseIf SubStr(_cChaveNFe,21,2)=='67'
	_cArquiv:= '273'+_cChaveNFe+'.xml'
EndIf

DBSelectArea("CKO")
CKO->(DBSetOrder(1))
//Atualiza status na fila de processamento
If CKO->(DBSeek(_cArquiv)) .And. cFilAnt == AllTrim(CKO->CKO_FILPRO)
	If CKO->CKO_CODERR $ 'MCOM01/MCOM02'
		DBSelectArea("C00")
		C00->(DBSetOrder(1))
		//Verifico se depois da recusa/desconhecimento, se a operação foi confirmada para deixar restaurar
		If C00->(DBSeek(xFilial("C00")+_cChaveNFe)) .And. C00->C00_STATUS == '1' .And. C00->C00_CODEVE == '3  '
			_lRecup:= .T.
		EndIf
		C00->(DBCloseArea())
	EndIf

	If !_lRecup .And. CKO->CKO_FLAG == '9' .And. CKO->CKO_CODERR $ 'COM036/COM037/COM040/COM041/COM045/COM046/MCOM01/MCOM02'
		FWAlertWarning(U_ColErro(CKO->CKO_CODERR) + ". Ele não poderá ser recuperado.","MCOM00607" )
	ElseIf CKO->CKO_FLAG == '9'
		RecLock("CKO",.F.)
		CKO->CKO_FLAG := '0'
		CKO->CKO_CODERR := ' '
		CKO->(MSUnLock())
		FWAlertSuccess("Documento retornado para fila de processamento.","MCOM00608")
	Else
		FWAlertInfo("Chave já processada. Veirifique no Monitor ou nas pendências da rotina.","MCOM00609")
	EndIf
Else
	FWAlertWarning("Chave não lozalida para recuperação.","MCOM00610")
EndIf

Return
