/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |21/03/2022| Chamado 29470 e 39535. Retornada inclusão manual na C00 visto que não será mais possível sincronizar
			  |			 | com a SEFAZ pois o ITGS já faz isso. 
Lucas Borges  |26/07/2022| Chamado 40821. Corrigido erro de chave duplicada
Lucas Borges  |20/02/2024| Chamado 46341. Incluído filtro para processar quem obteve alguma rejeição
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MCOM009
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 07/02/2018
Descrição---------: Rotina para manifestar os documentos já classificados no MATA103
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MCOM009

Local _aArea		:= FWGetArea()
Private _cPerg		:= "MCOM009"
Private _oSelf		:= nil
Private _aSelFil	:= {}
Private _aButtons	:={}
Private _lScheduler := FWGetRunSchedule()

ProcLogIni( _aButtons )

If _lScheduler
	MCOM09P(_oSelf)
Else
	//============================================
	//Cria interface principal
	//============================================
	tNewProcess():New(	"MCOM009"										,; // Função inicial
						"Manifesta Documentos de Entrada"					,; // Descrição da Rotina
						{|_oSelf| MCOM09P(_oSelf) }							,; // Função do processamento
						"Realiza a transmissão do evento 210200 - Confirmação da Operação para documentos já escriturados. "+;
						"Realiza o monitoramento de qualquer MD-e ainda não monitorado.",; // Descrição da Funcionalidade
						_cPerg											,; // Configuração dos Parâmetros
						{}												,; // Opções adicionais para o painel lateral
						.F.												,; // Define criação do Painel auxiliar
						0												,; // Tamanho do Painel Auxiliar
						''												,; // Descrição do Painel Auxiliar
						.T.												,; // Se .T. exibe o painel de execução. Se falso, apenas executa a função sem exibir a régua de processamento.
    	                .F.                                              ) // Se .T. cria apenas uma regua de processamento.
EndIf
FWRestArea(_aArea)

Return

/*
===============================================================================================================================
Programa----------: MCOM09P
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 07/02/2018
Descrição---------: Processa registros
Parametros--------: 
Retorno-----------: 
===============================================================================================================================
*/
Static Function MCOM09P(_oSelf)

Local _aArea 	:= FWGetArea()
Local _aSelFil	:= {}
Local _cFilAnt	:= cFilAnt //Salva filial corrente
Local _cAlias	:= GetNextAlias()
Local _cIdEnt	:= " "
Local _aDocMani	:= {}
Local _cRazao	:= ""
Local _cCNPJEM	:= ""
Local _cIEemit	:= ""
Local cRetorno	:= ""
Local cTpEvento	:= "210200"
Local _nDias	:= 180
Local _dDataLim	:= "  /  /  "
Local _lRet		:= .F.
Local _aDados	:= {}
Local _nTotReg	:= 0
Local _nX		:=0
Private cAmbiente:= ""
Private	cModelo := ""
//Chama função que permitirá a seleção das filiais
If MV_PAR09 == 1
	If Empty(_aSelFil)
		_aSelFil := AdmGetFil(.F.,.F.,"SF1")
	EndIf
Else
	aAdd(_aSelFil,cFilAnt)
EndIf

For _nX:=1 to Len(_aSelFil)

	//Carrga filial corrente com a filial a ser processada
	cFilAnt := _aSelFil[_nX]

	If _lScheduler
		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00901"/*cMsgId*/, "Inicio processamento filial "+cFilant/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	Else
		_oSelf:SetRegua1(Len(_aSelFil))
		_oSelf:SaveLog("Inicio processamento filial "+cFilAnt)
		_oSelf:IncRegua1("Processando filial "+cFilAnt)
	EndIf
	
	//Posiciona corretamente no SIGAMAT para que as funções do TSS reconheçam corretamente a entidade
	SM0->(DBSeek(SUBS(cNumEmp,1,2) + cFilAnt)) 
	
	If  EntAtivTss() .And. CTIsReady()
		
		cAmbiente	:= getAmbMde()
		_cIdEnt		:= RetIdEnti()

		//Caso o documento tenha mais de 180 dias, nem tento manifestar pois será recusado pela SEFAZ
		_dDataLim :=(DATE()-_nDias)
		
		//Traz documentos classificados
		BeginSql Alias _cAlias
	     SELECT F1_FILIAL, F1_CHVNFE, F1_DOC, F1_SERIE, F1_FORNECE, F1_LOJA, F1_EMISSAO, F1_DTDIGIT, F1_TIPO, F1_VALBRUT, F1_DAUTNFE,
	            NVL((SELECT 'S'
	               FROM %Table:C00% C00
	              WHERE C00.D_E_L_E_T_ = ' '
	                AND C00.C00_FILIAL = %xFilial:C00%
	                AND C00.C00_CHVNFE = SF1.F1_CHVNFE),'N') GEROUC00
	       FROM %Table:SF1% SF1
	      WHERE SF1.D_E_L_E_T_ = ' '
            AND SF1.F1_FILIAL = %xFilial:SF1%
	        AND SF1.F1_DTDIGIT BETWEEN %exp:MV_PAR05% AND %exp:MV_PAR06% 
	        AND SF1.F1_EMISSAO BETWEEN %exp:MV_PAR07% AND %exp:MV_PAR08%
	        AND SF1.F1_EMISSAO > %exp:_dDataLim% 
	        AND SF1.F1_FORNECE BETWEEN %exp:MV_PAR01% AND %exp:MV_PAR03%
	        AND SF1.F1_LOJA BETWEEN %exp:MV_PAR02% AND %exp:MV_PAR04%
	        AND SF1.F1_STATUS = 'A'
	        AND SF1.F1_ESPECIE = 'SPED'
	        AND SF1.F1_FORMUL <> 'S'
	        AND NOT EXISTS
	      (SELECT 1
	               FROM SPED150
	              WHERE SPED150.D_E_L_E_T_ = ' '
	                AND SPED150.NFE_CHV = SF1.F1_CHVNFE
	                AND SPED150.ID_ENT = %exp:_cIdEnt%
	                AND SPED150.TPEVENTO = %exp:cTpEvento%
	                AND SPED150.AMBIENTE = %exp:cAmbiente%
					AND SPED150.STATUS = 6)
	      ORDER BY SF1.F1_DTDIGIT, SF1.F1_DOC
		EndSql

		If !_lScheduler
			Count To _nTotReg
			(_cAlias)->( DBGoTop())
			_oSelf:SetRegua2(_nTotReg)
		EndIf

		//Varre dados realizando a transmissão dos eventos
		While !(_cAlias)->(Eof())
			
			_aDocMani	:= {}

			If !_lScheduler
				_oSelf:IncRegua2("Transmitindo dia " +DToC(SToD((_cAlias)->F1_DTDIGIT))+", documento "+(_cAlias)->F1_DOC)
			EndIf

			// Validar se o emitente da NF-e a ser manifestada é o cliente ou fornecedor
			If (_cAlias)->F1_TIPO $ "DB" 
				DBSelectArea("SA1")
				DBSetOrder(1)
				MsSeek(xFilial("SA1")+(_cAlias)->(F1_FORNECE+F1_LOJA))
				_cRazao  := AllTrim(SA1->A1_NOME)
				_cCNPJEM := AllTrim(SA1->A1_CGC)
				_cIEemit := AllTrim(SA1->A1_INSCR)
				SA1->(DBCloseArea())
			Else
				DBSelectArea("SA2")
				DBSetOrder(1)  				
				MsSeek(xFilial("SA2")+(_cAlias)->(F1_FORNECE+F1_LOJA))
				_cRazao  := AllTrim(SA2->A2_NOME)
				_cCNPJEM := AllTrim(SA2->A2_CGC)
				_cIEemit := AllTrim(SA2->A2_INSCR)
				SA2->(DBCloseArea())
			EndIf
			aAdd(_aDocMani,{,(_cAlias)->F1_CHVNFE,(_cAlias)->F1_SERIE,(_cAlias)->F1_DOC,(_cAlias)->F1_VALBRUT,_cCNPJEM,AllTrim(_cRazao),AllTrim(_cIEemit),(_cAlias)->F1_EMISSAO,(_cAlias)->F1_DAUTNFE,.T.,'0','1'})
			If AllTrim((_cAlias)->GEROUC00) <> 'S'
				_aDados	:= {}
				
				aAdd(_aDados,{"C00_FILIAL"	,	cFilAnt					})
				aAdd(_aDados,{"C00_CHVNFE"	,	(_cAlias)->F1_CHVNFE	})
				aAdd(_aDados,{"C00_SERNFE"	,	StrZero(Val(AllTrim((_cAlias)->F1_SERIE)),SerieNfId("SF1",6,"F1_SERIE"))})
				aAdd(_aDados,{"C00_NUMNFE"	,	(_cAlias)->F1_DOC		})
				aAdd(_aDados,{"C00_VLDOC"	,	(_cAlias)->F1_VALBRUT	})
				aAdd(_aDados,{"C00_DTEMI"	,	(_cAlias)->F1_EMISSAO	})
				aAdd(_aDados,{"C00_DTREC"	,	(_cAlias)->F1_EMISSAO	})
				aAdd(_aDados,{"C00_NOEMIT"	,	AllTrim(_cRazao)		})
				aAdd(_aDados,{"C00_CNPJEM"	,	_cCNPJEM				})
				aAdd(_aDados,{"C00_IEEMIT"	,	AllTrim(_cIEemit)		})
				aAdd(_aDados,{"C00_STATUS"	,	'0'						})
				aAdd(_aDados,{"C00_CODRET"	,	'999'					})
				aAdd(_aDados,{"C00_DESRES"	,	'Documento incluido manualmente'})
				aAdd(_aDados,{"C00_MESNFE"	,	SubStr((_cAlias)->F1_EMISSAO,5,2)})
				aAdd(_aDados,{"C00_ANONFE"	,	SubStr((_cAlias)->F1_EMISSAO,1,4)})
				aAdd(_aDados,{"C00_SITDOC"	,	'1'						}) //"Uso autorizado da NFe"
				aAdd(_aDados,{"C00_CODEVE"	,	'1'						}) //"Envio de Evento não realizado"_

				_lRet:= InC00(.T.,_aDados)
			EndIf
			If AllTrim((_cAlias)->GEROUC00) == 'S' .Or. _lRet
				Sleep(1000)//Aguarda 2 segundos para não sobrecarregar o TSS na tentativa de evitar as falhas constantes de falta de retorno
				MontaXmlManif(cTpEvento,_aDocMani,@cRetorno,"")
			EndIf
			(_cAlias)->(DBSkip())
		End
		(_cAlias)->(DBCloseArea())
		
		Sleep(10000)//Aguarda 10 segundos para dar tempo de pegar o correto retorno da SEFAZ. Isso não resolve o problema, apenas minimiza
		
		//Traz documentos transmitidos, inclusive os que foram transmitidos manualmente e não foram monitorados
		BeginSql Alias _cAlias
	     SELECT C00.C00_FILIAL, C00.C00_CHVNFE, C00.C00_NUMNFE, C00.C00_DTEMI
	       FROM %Table:C00% C00
	      WHERE C00.D_E_L_E_T_ = ' '
            AND C00.C00_FILIAL = %xFilial:C00%
	        AND C00.C00_CODEVE = '2'
	      ORDER BY C00.C00_DTEMI, C00.C00_NUMNFE
		EndSql

		If !_lScheduler
			Count To _nTotReg
			(_cAlias)->( DBGoTop())
			_oSelf:SetRegua2(_nTotReg)
		EndIf
				
		While !(_cAlias)->(Eof())
			If !_lScheduler
				_oSelf:IncRegua2("Monitorando dia " +DToC(SToD((_cAlias)->C00_DTEMI))+", documento "+(_cAlias)->C00_NUMNFE)
			EndIf
			
			MonitEven((_cAlias)->C00_CHVNFE,(_cAlias)->C00_CHVNFE,cTpEvento,cModelo,,getSitConf(cTpEvento))
			(_cAlias)->(DBSkip())
		End
			
		(_cAlias)->(DBCloseArea())
		
	Else
		If _lScheduler
			FWLogMsg("WARN"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00902"/*cMsgId*/, "TSS não está configurado para a filial "+cFilant/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
			Loop
	 	Else
			Aviso("SPED",IIf(Empty(GetWscError(3)),GetWscError(1),GetWscError(3)),{"OK"},3)
		EndIf
	EndIf
	If _lScheduler
		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00903"/*cMsgId*/, "Fim processamento filial "+cFilant/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	Else
		_oSelf:SaveLog("Fim processamento filial "+cFilAnt)
	EndIf
Next _nX
	
cFilAnt := _cFilAnt //Restaura filial
SM0->(DBSeek(SUBS(cNumEmp,1,2) + cFilAnt)) //Restaura posição no SIGAMAT 

If _lScheduler
	FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00904"/*cMsgId*/, "Fim do processamento."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
Else
	Aviso("Envio Manifesto","Acesse a rotina Manifesto do Destinatário e filtre por Código do Evento igual a 2 ou 4 para pegar todas as inconsistências.",{"OK"},3)
EndIf
FWRestArea(_aArea)

Return

/*
===============================================================================================================================
Programa----------: MontaXmlManif
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 07/02/2018
Descrição---------: Monta xml para transmissão da manifestação
Parametros--------: cTpEvento  - Evento a ser processado
					aMontXml   - Dados da nota que deve ser transmitida
					cRetorno   - Chaves de acesso das notas transmitidas
					cJustific  - Justificativa da Operação não realizada
Retorno-----------: lRetOk	   - Se a transmissão foi concluída ou não
===============================================================================================================================
*/
Static Function MontaXmlManif(cTpEvento,aMontXml,cRetorno,cJustific) 

Local _aArea		:= FWGetArea()
Local aRet			:={}
Local cXml			:= ""
Local cIdEnt		:= ""
Local cURL			:= PadR(GetNewPar("MV_SPEDURL","http://"),250)
Local lRetOk		:= .T. 
Local _nX 			:= 0

Private lUsaColab	:= .F.
Private oWs			:= Nil

Default cJustific 	:= ""

cIdEnt		:= RetIdEnti(lUsaColab)

If CTIsReady()
	oWs :=WSMANIFESTACAODESTINATARIO():New()
	oWs:cUserToken   := "TOTVS"
	oWs:cIDENT	     := cIdEnt
	oWs:cAMBIENTE	 := ""
	oWs:cVERSAO      := ""
	oWs:_URL         := AllTrim(cURL)+"/MANIFESTACAODESTINATARIO.apw" 
	
	If oWs:CONFIGURARPARAMETROS()
		cAmbiente		 := oWs:OWSCONFIGURARPARAMETROSRESULT:CAMBIENTE
		
		cXml+='<envEvento>'
		cXml+='<eventos>'
		
		For _nX:=1 To Len(aMontXml)
			cXml+='<detEvento>'
			cXml+='<tpEvento>'+cTpEvento+'</tpEvento>'
			cXml+='<chNFe>'+AllTrim(aMontXml[_nX][2])+'</chNFe>'
			cXml+='<ambiente>'+cAmbiente+'</ambiente>'
			If '210240' $ cTpEvento .And. !Empty(cJustific)
				cXml+='<xJust>'+AllTrim(cJustific)+'</xJust>'
			EndIf		
			cXml+='</detEvento>'
		Next
		cXml+='</eventos>'
		cXml+='</envEvento>'
		
		lRetOk:= RetEnvManif(cXml,cIdEnt,cURL,@aRet)
		
		If lRetOk .And. Len(aRet) > 0
			For _nX:=1 to Len(aRet)
			    cRetorno:= SubStr(aRet[_nX],9,44)
			Next
		EndIf
	Else
		If _lScheduler
			FWLogMsg("WARN"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00905"/*cMsgId*/, "TSS não está configurado para a filial "+cFilant/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	 	Else
			Aviso("SPED",IIf(Empty(GetWscError(3)),GetWscError(1),GetWscError(3)),{"OK"},3)
		EndIf
	EndIf	
	AtuStatus(aRet,cTpEvento)

Else
	If _lScheduler
		FWLogMsg("WARN"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00906"/*cMsgId*/, "Execute o módulo de configuração do serviço, antes de utilizar esta opção!!!"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	Else
		Aviso("SPED","Execute o módulo de configuração do serviço, antes de utilizar esta opção!!!",{"OK"},3)
	EndIf
EndIf

FWRestArea(_aArea)
		
Return lRetOk

/*
===============================================================================================================================
Programa----------: AtuStatus
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 07/02/2018
Descrição---------: Atualiza o Status da Manifestação de acordo com o Tipo de Evento
Parametros--------: aRet   	   - Chaves de acesso das notas transmitidas
Retorno-----------: cTpEvento  - Tipo do Evento em que a nota foi transmitida
===============================================================================================================================
*/
Static Function AtuStatus(aRet,cTpEvento)

Local aAreas	:= {}
Local cStat		:= "0"
Local _nX		:= 0 

cStat := getSitConf(cTpEvento)

If Len(aRet) > 0
	aAreas := FWGetArea()
	DBSelectArea("C00")
	For _nX:=1 to Len(aRet)
		C00->(DBSetOrder(1))
		aRet[_nX]:= SubStr(aRet[_nX],9,44)
		If C00->(DBSeek(xFilial("C00")+aRet[_nX]))
			RecLock("C00")
			C00->C00_STATUS := cStat
			C00->C00_CODEVE := "2"
			MSUnLock()
		EndIf
	Next
	C00->(DBCloseArea())
	FWRestArea(aAreas)	
EndIf	

Return
/*
===============================================================================================================================
Programa----------: getAmbMde
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 07/02/2018
Descrição---------: Retorna ambiente de configuração do Md-e
Parametros--------: Nenhum
Retorno-----------: cAmbiente
===============================================================================================================================
*/
Static Function getAmbMde()
	
Local cAmbiente := ""
Local cURL		:= PadR(GetNewPar("MV_SPEDURL","http://"),250)	
Local oWs
If CTIsReady()
	oWs :=WSMANIFESTACAODESTINATARIO():New()
	oWs:cUserToken   := "TOTVS"
	oWs:cIDENT	     := retIdEnti()
	oWs:cAMBIENTE	 := ""
	oWs:cVERSAO      := ""
	oWs:_URL         := AllTrim(cURL)+"/MANIFESTACAODESTINATARIO.apw" 
	oWs:CONFIGURARPARAMETROS()
	cAmbiente		 := oWs:OWSCONFIGURARPARAMETROSRESULT:CAMBIENTE

	freeObj(oWs)
	oWs := nil 	
EndIf

Return cAmbiente

/*
===============================================================================================================================
Programa----------: MonitEven
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 07/02/2018
Descrição---------: Realiza o monitoramento do Evento
Parametros--------: cChvIni   - Chave inicial a ser monitorada
					cChvFin   - Chave final a ser monitorada
					cCodEve	  - Codigo de Evento utilizado na busca
					cStat	  - Código do Status do evento processado
Retorno-----------: aListBox  - Retorna o resultado da solicitação
===============================================================================================================================
*/
Static Function MonitEven(cChvIni,cChvFin,cCodEve,cModelo,cChaves,cStat)

Local _aArea		:= FWGetArea()
Local aListBox		:= {}
Local oOk			:= LoadBitMap(GetResources(), "ENABLE")
Local oNo			:= LoadBitMap(GetResources(), "DISABLE")

Local cURL   		:= PadR(GetNewPar("MV_SPEDURL","http://"),250) 
Local cOpcUpd		:= ""
Local cIdEnt		:= RetIdEnti()
Local _nX			:= 0
Local lOk      		:= .T.

Private oWS			:= Nil	

Default cModelo 	:= ""
Default cChaves	:= ""
If CTIsReady()

	// Executa o metodo NfeRetornaEvento()
	oWS:= WSNFeSBRA():New()
	oWS:cUSERTOKEN	:= "TOTVS"
	oWS:cID_ENT		:= cIdEnt 
	oWS:_URL			:= AllTrim(cURL)+"/NFeSBRA.apw"
	oWS:cEVENTO		:= cCodEve
	oWS:cCHVINICIAL	:= cChvIni
	oWS:cCHVFINAL		:= cChvFin
	oWS:cCHAVES		:= cChaves
	lOk:=oWS:NFEMONITORLOTEEVENTO()
	
	If lOk
	
		// Tratamento do retorno do evento
		If Type("oWS:oWsNfemonitorLoteEventoResult:OWSNfeMonitorEvento") <> "U" 
			
			If ValType(oWS:oWsNfemonitorLoteEventoResult:OWSNfeMonitorEvento) <> "A"
				aMonitor := {oWS:oWsNfemonitorLoteEventoResult:OWSNfeMonitorEvento}
			Else
				aMonitor := oWS:oWsNfemonitorLoteEventoResult:OWSNfeMonitorEvento
			EndIf

			For _nX:=1 To Len(aMonitor)                                          					
				aAdd( aListBox, {	If(aMonitor[_nX]:nStatus <> 6 .And. aMonitor[_nX]:nStatus <> 7 ,oNo,oOk),;
									If(aMonitor[_nX]:nProtocolo <> 0 ,AllTrim(Str(aMonitor[_nX]:nProtocolo)),""),;
									aMonitor[_nX]:cId_Evento,;
									AllTrim(Str(aMonitor[_nX]:nAmbiente)),;	
									AllTrim(Str(aMonitor[_nX]:nStatus)),;
									If(!Empty(aMonitor[_nX]:cCMotEven),AllTrim(aMonitor[_nX]:cCMotEven),AllTrim(aMonitor[_nX]:cMensagem)),;
									"" }) //XML manter devido ao TOTVS Colaboração.
				//Atualizacao do Status do registro de saida
				cOpcUpd := "3"					
				
				If aListBox[_nX][5]	== "3" .Or. aListBox[_nX][5] == "5"					
					cOpcUpd :=	"4"  //Evento rejeitado +msg rejeiçao					
				ElseIf aListBox[_nX][5] == "6"  
					cOpcUpd := "3"  //Evento vinculado com sucesso
				ElseIf aListBox[_nX][5] == "1"
					cOpcUpd := "2"  //Envio de Evento realizado - Aguardando processamento
				EndIf

				cChave:= SubStr(aMonitor[_nX]:cId_Evento,9,44)
				_aArea := FWGetArea()
				DBSelectArea("C00")
				C00->(DBSetOrder(1))
				If C00->(DBSeek(xFilial("C00")+cChave))
				
					If AllTrim(C00->C00_STATUS) == cStat//Atualiza apenas evento atual 
						If cOpcUpd <> "4" 
							RecLock("C00")
							C00->C00_CODEVE := cOpcUpd
							MSUnLock()
						Else
							MonitoraManif({cChave}, cAmbiente, cIdEnt, AllTrim(cURL) + "/MANIFESTACAODESTINATARIO.apw",,cOpcUpd)
						EndIf
					Else
						If AllTrim(C00->C00_STATUS) <> '4'
							RecLock("C00")
							C00->C00_CODEVE := cOpcUpd
							MSUnLock() 
						EndIf
					EndIf
				EndIf
				C00->(DBCloseArea())
				FWRestArea(_aArea)
			Next       

		EndIf

	EndIf

Else
	Aviso("SPED","Execute o módulo de configuração do serviço, antes de utilizar esta opção!!!",{"OK"},3)
EndIf

FWRestArea(_aArea)

Return aListBox 

/*
===============================================================================================================================
Programa----------: getSitConf
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 07/02/2018
Descrição---------: Realiza De/Para nos códigos dos Eventos
Parametros--------: cTpEvento - Código do evento que está sendo processado
Retorno-----------: cSitConf  - Retorna o código da situação a ser gravada no C00_STATUS
===============================================================================================================================
*/
Static Function getSitConf(cTpEvento)
	
Local cSitConf := "0"

Do Case
	Case cTpEvento == "210200"
		cSitConf := "1"
	Case cTpEvento == "210210"
		cSitConf := "4"
	Case cTpEvento == "210220"
		cSitConf := "2"
	Case cTpEvento == "210240"
		cSitConf := "3"									
EndCase
	
Return cSitConf

/*
===============================================================================================================================
Programa----------: InC00
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 07/02/2018
Descrição---------: Inclui/Altera registro de manifesto na C00
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function InC00(_lInclui,_aDados)
	Local _nI		:= 1
	Local _lRet		:= .F.
	Default _aDados	:= {}
	
	If Len(_aDados) > 0
		
		//Checo novamente se realmente não existe o documento pois entre o início do processamento da rotina até esse ponto 
		//outras rotinas podem ter incluído a informação causando erro de chave duplicada.
		C00->(DBSetOrder(1))
		If !C00->(DBSeek(_aDados[01][02]+_aDados[02][02]))//Filial+Chave
			//Grava na Tabela
			Begin Transaction
				RecLock("C00",_lInclui)
				For _nI := 1 To Len(_aDados)				
					C00->(FieldPut(FieldPos(_aDados[_nI][1]),_aDados[_nI][2]))
				Next _nI
				C00->(MSUnLock())
				_lRet := .T.
			End Transaction
		EndIf
	Else
		_lRet := .F.
	EndIf
	
Return _lRet

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
            "MCOM009",;
            "",;
            aOrd,;
            }
            
Return aParam
