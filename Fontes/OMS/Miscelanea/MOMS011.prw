/*
===============================================================================================================================
                          ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
       Autor      |    Data    |                                             Motivo                                          
-------------------------------------------------------------------------------------------------------------------------------
Josué Danich      | 12/07/2018 | Reconstrução de rotina usando novo tipo de envio de xml - Chamado 25300
-------------------------------------------------------------------------------------------------------------------------------
 Josué Danich     | 05/11/2018 | Ajuste de limpeza de objeto xmlparser e novas regras de codificação - Chamado 26365     
-------------------------------------------------------------------------------------------------------------------------------
 Lucas Borges     | 11/10/2019 | Removidos os Warning na compilação da release 12.1.25. Chamado 28346
-------------------------------------------------------------------------------------------------------------------------------
 Jonathan		  | 11/10/2019 | Removido o _aRegioes pois todas as regiões tem a mesma URL de transmissão. Chamado 34101
===============================================================================================================================
*/

//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================
#Include "TOTVS.ch"
#Include "apwebsrv.ch"

/*
===============================================================================================================================
Programa----------: MOMS011
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 03/03/2011 
===============================================================================================================================
Descrição---------:  Funcao desenvolvida para realizar o envio do xml da nota fiscal a rede Wall Mart.	
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS011()

Local aTables    := {"SF2","ZZK"}    

Private _lShedule  := .F. 
Private oproc

                        
If Select("SX3") <= 0
	_lShedule:= .T.
EndIf   
            
If _lShedule

	RPCSetType(3)
	RpcSetEnv("01","01",,,,/*"XML_WALlMART"*/,aTables)     

    u_itconout('Iniciando rotina de envio de xmls Walmart ' + DToC(DATE()) + ' - ' + Time())

    U_MOMS011E(.T.)

Else

   cCadastro:="Envio de Nota Fiscal do Walmart"
   aRotina := { { OemToAnsi("Pesquisar")   ,"AxPesqui"	    ,0,1,0,.F.},;
			   { OemToAnsi("Visualizar")  ,'AxVisual'       ,0,2,0,NIL},;
			   { OemToAnsi("Legenda")     ,'U_MOMS011L'     ,0,3,0,NIL},;
			   { OemToAnsi("Histórico")   ,'U_MOMS011H'     ,0,3,0,NIL},;
			   { OemToAnsi("Enviar Atual"),'FWMsgRun(,{ |oproc| U_MOMS011E(.F.,oproc)},"Aguarde...","Iniciando processo...")',0,3,0,NIL},;
			   { OemToAnsi("Enviar Todos"),'FWMsgRun(,{ |oproc| U_MOMS011E(.T.,oproc)},"Aguarde...","Iniciando processo...")',0,3,0,NIL}}

   _aCorLegen:={}
   aAdd(_aCorLegen,{"!(F2_CLIENTE $ u_itgetmv('ITCODWAL','004536;000258;008753;004925;000641'))",'BR_PRETO'})	
   aAdd(_aCorLegen,{"F2_I_ENXML == ' '",'ENABLE'  })			
   aAdd(_aCorLegen,{"F2_I_ENXML == 'S'",'DISABLE'})

   cExprFilTop := " f2_filial = '" + cfilant + "' and "
   cExprFilTop += " f2_emissao > '" + DToS(date()-60) + "' and f2_hora > '00:00' and "
   cExprFilTop += " f2_cliente IN " + FormatIn(AllTrim(u_itgetmv('ITCODWAL','004536;000258;008753;004925;000641')),";") 
  
   mBrowse(,,,,"SF2",,,,,,_aCorLegen,,,,,,,, cExprFilTop)

EndIf

Return .F.

/*
===============================================================================================================================
Programa----------: MOMS011E
Autor-------------: Alex Wallauer
Data da Criacao---: 25/07/2016
===============================================================================================================================
Descrição---------: Rotina para enviar O xml para o walmart
===============================================================================================================================
Parametros--------: lTodos: .T. envia para todos senao para o atual
					oproc: objeto da barra de processamento
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS011E(lTodos,oproc)

Local aNotas     := {} 
Local cXmlDados  := "" 
Local oWsWal                                 
Local _cURL      := "https://portalnfe.bigti.com.br/Gnfe_Port_ws/cls_403_nfe_xml.asmx?op=fu_upld"
Local _nresult,_nretorno 
Local cModalidade:= ""                                         
Local cAlias     := GetNextAlias()  
Local _cDescRet:= ""  

_cFiltro := "% SF2.F2_CLIENTE IN " + FormatIn(u_itgetmv('ITCODWAL','004536;000258;008753;004925;000641'),";") + "%"

If lTodos

   BeginSql Alias cAlias
	
	SELECT
	SPD050.R_E_C_N_O_ RECNO050,SF2.F2_FILIAL,SF2.F2_DOC,SF2.F2_SERIE,SF2.F2_CLIENTE,SF2.F2_LOJA,SA1.A1_CGC,
	SPD050.ID_ENT,SPD050.DATE_NFE
	FROM
	SPED050 SPD050
	JOIN SPED054 SPD054 ON SPD050.ID_ENT = SPD054.ID_ENT AND SPD050.NFE_ID = SPD054.NFE_ID
	JOIN SF2010 SF2 ON SPD054.NFE_CHV = SF2.F2_CHVNFE
	JOIN SA1010 SA1 ON SA1.A1_COD = SF2.F2_CLIENTE AND SA1.A1_LOJA = SF2.F2_LOJA
	WHERE SF2.D_E_L_E_T_ = ' '
	  AND SA1.D_E_L_E_T_ = ' '
	  AND SPD050.D_E_L_E_T_ = ' '
	  AND SPD054.D_E_L_E_T_ = ' '
      AND SPD054.CSTAT_SEFR >= '100'
      AND SPD054.CSTAT_SEFR <= '199'
	  AND SPD050.STATUS = 6
	  AND SF2.F2_I_ENXML = ' '
	  AND SF2.F2_CHVNFE <> ' '
	  AND %exp:_cFiltro%

   EndSql

Else

   _cFil:= SF2->F2_FILIAL
   _cNF := SF2->F2_DOC
   _DTLIM := DToS(date()-60)

   BeginSql Alias cAlias
	
	SELECT
	SPD050.R_E_C_N_O_ RECNO050,SF2.F2_FILIAL,SF2.F2_DOC,SF2.F2_SERIE,SF2.F2_CLIENTE,SF2.F2_LOJA,SA1.A1_CGC,
	SPD050.ID_ENT,SPD050.DATE_NFE
	FROM
	SPED050 SPD050
	JOIN SPED054 SPD054 ON SPD050.ID_ENT = SPD054.ID_ENT AND SPD050.NFE_ID = SPD054.NFE_ID
	JOIN SF2010 SF2 ON SPD054.NFE_CHV = SF2.F2_CHVNFE
	JOIN SA1010 SA1 ON SA1.A1_COD = SF2.F2_CLIENTE AND SA1.A1_LOJA = SF2.F2_LOJA
	WHERE SF2.D_E_L_E_T_ = ' '
	  AND SA1.D_E_L_E_T_ = ' '
	  AND SPD050.D_E_L_E_T_ = ' '
	  AND SPD054.D_E_L_E_T_ = ' '
      AND SPD054.CSTAT_SEFR >= '100'
      AND SPD054.CSTAT_SEFR <= '199'
	  AND SPD050.STATUS = 6
	  AND SF2.F2_CHVNFE <> ' '
	  AND SF2.F2_FILIAL  = %Exp:_cFil%
	  AND SF2.F2_DOC     = %Exp:_cNF%
	  AND SF2.F2_EMISSAO >= %Exp:_DTLIM%
	  AND %exp:_cFiltro%

   EndSql

EndIf

DBSelectArea(cAlias)
count to nTot

If !_lShedule 
   If nTot = 0
      U_ITMsg("Nota(s) nao pertence a nenhum criterio da selecao","Atenção","Apenas notas do grupo Walmart podem ser enviadas por essa rotina",1)
   Else
      If lTodos
      	If !U_ITMsg("Todas as notas selecionadas, confirma envio?","Envio Walmart",,2,2,2)
         	(cAlias)->(DBCloseArea())
         	Return
      	EndIf
      Else	
      	If !U_ITMsg("Nota(s): "+CHR(13)+CHR(10)+_cNF+" selecionada, confirma envio?","Envio Walmart",,2,2,2)
         	(cAlias)->(DBCloseArea())
         	Return
      	EndIf
      EndIf	
   EndIf
EndIf

(cAlias)->(DBGoTop())

_cNF:=""
lEnvio:=.F.

While (cAlias)->(!Eof())

	If !_lShedule

		oproc:cCaption := ("Enviando xml da nota " + (cAlias)->F2_FILIAL + "/" + AllTrim((cAlias)->F2_DOC) + "...")
		ProcessMessages()
		
	EndIf

	cIdEnt:= (cAlias)->ID_ENT
	
	aNotas:= {}
	aAdd(aNotas,{})
	aAdd(Atail(aNotas),.F.)
	aAdd(Atail(aNotas),"S")
	aAdd(Atail(aNotas),SToD((cAlias)->DATE_NFE))
	aAdd(Atail(aNotas),(cAlias)->F2_SERIE)
	aAdd(Atail(aNotas),(cAlias)->F2_DOC)
	aAdd(Atail(aNotas),(cAlias)->F2_CLIENTE)
	aAdd(Atail(aNotas),(cAlias)->F2_LOJA)
	
	cXmlDados:= MOMS011G(cIdEnt,aNotas,cModalidade)
	
	If 	!Empty(cXmlDados[1][2])
		
		
		oWsWal:= WScls_403_nfe_xml():New()     

		oWsWal:cpa_tp_cd_usua:= 'J'  

		cXmlDados := cXmlDados[1][2]

		oWsWal:_URL          := _cURL
		oWsWal:npa_cd_usua   := MOMS011C((cAlias)->F2_FILIAL)
		oWsWal:cpa_ds_xml_nfe:= cXmlDados
		
		_nresult:= oWsWal:fu_upld()
					
		_nRetorno:=999999
		If ValType(oWsWal:oWSfu_upldResult:NRETURN_CODE) <> 'U' 
			_nRetorno  := oWsWal:oWSfu_upldResult:NRETURN_CODE
		EndIf
		
		_cDescRet:= ""
		If ValType(oWsWal:oWSfu_upldResult:CRETURN_CHAV) <> 'U' 
			_cDescRet  := oWsWal:oWSfu_upldResult:CRETURN_CHAV
		EndIf
		
		If Empty(_cDescRet) .And. _nretorno != 0
				_cDescRet  := If(_nResult = Nil,"NAO HOUVE RETORNO","RETORNO NEGATIVO")
		EndIf
		
		/*
		//================================================================
		//Grava envio na sf2 e log de envio
		//================================================================
		*/
		If _nRetorno == 0
			
			SF2->(DBSetOrder(2))
			If SF2->(DBSeek((cAlias)->F2_FILIAL + (cAlias)->F2_CLIENTE + (cAlias)->F2_LOJA + (cAlias)->F2_DOC + (cAlias)->F2_SERIE ))
				
				RecLock("SF2",.F.)
				
				SF2->F2_I_ENXML:= 'S'
				
				SF2->(MSUnLock())
				
				lEnvio:=.T.
				
				_cNF+=(cAlias)->F2_FILIAL + "/" + (cAlias)->F2_DOC + " - "

			EndIf
			SF2->(DBSetOrder(1))
		
		EndIf
		
		RecLock("ZZK",.T.)
				
		ZZK->ZZK_FILIAL:= (cAlias)->F2_FILIAL
		ZZK->ZZK_CDERRO:= AllTrim(Str(_nretorno))
		ZZK->ZZK_DESCRI:= IIf(Empty(AllTrim(_cDescRet)) .And. _NRETORNO != 0 ,"FALHA DE CONEXAO AO SERVIDOR DO WALMART",AllTrim(_cDescRet))
		ZZK->ZZK_DOC   := (cAlias)->F2_DOC
		ZZK->ZZK_SERIE := (cAlias)->F2_SERIE
		ZZK->ZZK_CLIENT:= (cAlias)->F2_CLIENTE
		ZZK->ZZK_LOJA  := (cAlias)->F2_LOJA
		ZZK->ZZK_USER  := IIf(_lShedule,"SCHEDULE",cUserName)
		ZZK->ZZK_DATA  := Date()
		ZZK->ZZK_HORA  := Time()
				
		ZZK->(MSUnLock())

	EndIf
	
	DBSelectArea(cAlias)
	(cAlias)->(DBSkip())
	
	//limpa objetos xml
	DelClassIntf()
	
EndDo
			
(cAlias)->(DBCloseArea())

If _lShedule .And. nTot > 0

	RpcClearEnv() //Limpa o ambiente, liberando a licença e fechando as conexões
	
	u_itconout('Termino do enviou do XML das notas do cliente WALL MART na data: ' + DToC(DATE()) + ' - ' + Time())

ElseIf ntot > 0
    
    If lEnvio   
       U_ITMsg("Nota(s): "+CHR(13)+CHR(10)+_cNF+" enviada(s) com sucesso","Envio Walmart",,2 )
    Else
    	If Empty(_cDescRet)
    	
    		U_ITMsg("Nenhuma nota enviada","Atenção","Erro de conexão ao servidor do Walmart",1)
    	
    	Else
    	
    		U_ITMsg("Nenhuma nota enviada","Atenção","Erro: " + _cDescRet,1)
    		
    	EndIf
    	
    EndIf

EndIf

Return                                                                  

/*
===============================================================================================================================
Programa----------: MOMS011C
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 03/02/2011
===============================================================================================================================
Descrição---------: Busca o CNPJ da filial passada como parametro 
===============================================================================================================================
Parametros--------: cCodFil : Codigo da Filial a ser retornado o nome 
===============================================================================================================================
Retorno-----------: cRet : Cnpj da filial
===============================================================================================================================
*/

Static Function MOMS011C(cCodFil)

Local aAreaSM0 := SM0->(getArea())
Local cRet := " "

SM0->(DBSelectArea("SM0"))
SM0->(DBSetOrder(1))
SM0->(DBSeek(cEmpAnt+ cCodFil)) 

cRet := AllTrim(Str(Val(SM0->M0_CGC))) 

//Restaura integridade da SM0
SM0->(DBSetOrder(aAreaSM0[2]))
SM0->(DBGoTo(aAreaSM0[3]))

Return cRet  

/*
===============================================================================================================================
Programa----------: MOMS011G
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 03/02/2011
===============================================================================================================================
Descrição---------: Busca o atraves de um web-service o xml da nota fiscal e o identa no formato completo de um xml 
					da nota fiscal - Função copiada do Danfeii.prw, atualizar em sincroniz
===============================================================================================================================
Parametros--------: cIdEnt - Id da nfe
					aIdNFe - dados na nfe
					cModalidade - modalidade da nfe
===============================================================================================================================
Retorno-----------: aretorno - array com dados da nfe, posição [1][2] é o string do xml								
===============================================================================================================================
*/
Static Function MOMS011G(cIdEnt,aIdNFe,cModalidade)  

Local aRetorno		:= {}
Local aDados		:= {}

Local cURL			:= PadR(GetNewPar("MV_SPEDURL","http://localhost:8080/sped"),250)
Local cModel		:= "55"


Local nZ			:= 0
Local nCount		:= 0

Local oWS

If Empty(cModalidade)    

	oWS := WsSpedCfgNFe():New()
	oWS:cUSERTOKEN := "TOTVS"
	oWS:cID_ENT    := cIdEnt
	oWS:nModalidade:= 0
	oWS:_URL       := AllTrim(cURL)+"/SPEDCFGNFe.apw"
	oWS:cModelo    := cModel 
	If oWS:CFGModalidade()
		cModalidade    := SubStr(oWS:cCfgModalidadeResult,1,1)
	Else
		cModalidade    := ""
	EndIf  
	
EndIf  
         
oWs := nil

For nZ := 1 To Len(aIdNfe) 
	nCount++

	aDados := MOMS011X( aIdNfe[nZ], cIdEnt )
	
	If ( nCount == 10 )
		delClassIntF()
		nCount := 0
	EndIf
	
	aAdd(aRetorno,aDados)
	
Next nZ

Return(aRetorno)

/*
===============================================================================================================================
Programa----------: MOMS011X
Autor-------------: Henrique Brugugnoli
Data da Criacao---: 17/01/2013
===============================================================================================================================
Descrição---------: Executa retorno de notas - Função copiada do Danfeii.prw, atualizar em sincronia
===============================================================================================================================
Parametros--------: cIdEnt - Id da nfe
					aNFe - dados na nfe
===============================================================================================================================
Retorno-----------: aretorno - array com dados da nfe, posição [1][2] é o string do xml								
===============================================================================================================================
*/
Static Function MOMS011X( aNfe, cIdEnt )

Local aRetorno		:= {}
Local aIdNfe		:= {}

Local cAviso		:= "" 
Local cDHRecbto		:= ""
Local cDtHrRec		:= ""
Local cDtHrRec1		:= ""
Local cErro			:= "" 
Local cModTrans		:= ""
Local cProtDPEC		:= ""
Local cProtocolo	:= ""
Local cMsgNFE		:= ""
Local cRetDPEC		:= ""
Local cRetorno		:= ""
Local cCodRetNFE	:= ""
Local cURL			:= PadR(GetNewPar("MV_SPEDURL","http://localhost:8080/sped"),250)

Local dDtRecib		:= CToD("")
Local nDtHrRec1		:= 0
Local nX			:= 0
Local nY			:= 0
Local nZ			:= 1
Local oWS

Private oDHRecbto
Private oNFeRet
Private oDoc

aAdd(aIdNfe,aNfe)


	oWS:= WSNFeSBRA():New()
	oWS:cUSERTOKEN        := "TOTVS"
	oWS:cID_ENT           := cIdEnt
	oWS:nDIASPARAEXCLUSAO := 0
	oWS:_URL 			  := AllTrim(cURL)+"/NFeSBRA.apw"
	oWS:oWSNFEID          := NFESBRA_NFES2():New()
	oWS:oWSNFEID:oWSNotas := NFESBRA_ARRAYOFNFESID2():New()  
	
	aAdd(aRetorno,{"","",aIdNfe[nZ][4]+aIdNfe[nZ][5],"","","",CToD(""),"","",""})
	
	aAdd(oWS:oWSNFEID:oWSNotas:oWSNFESID2,NFESBRA_NFESID2():New())
	Atail(oWS:oWSNFEID:oWSNotas:oWSNFESID2):cID := aIdNfe[nZ][4]+aIdNfe[nZ][5]
	
	If oWS:RETORNANOTASNX()
		If Len(oWs:oWSRETORNANOTASNXRESULT:OWSNOTAS:OWSNFES5) > 0
			For nX := 1 To Len(oWs:oWSRETORNANOTASNXRESULT:OWSNOTAS:OWSNFES5)
				cRetorno        := oWs:oWSRETORNANOTASNXRESULT:OWSNOTAS:OWSNFES5[nX]:oWSNFE:CXML
				cProtocolo      := oWs:oWSRETORNANOTASNXRESULT:OWSNOTAS:OWSNFES5[nX]:oWSNFE:CPROTOCOLO								
				cDHRecbto  		:= oWs:oWSRETORNANOTASNXRESULT:OWSNOTAS:OWSNFES5[nX]:oWSNFE:CXMLPROT
				oNFeRet			:= XmlParser(cRetorno,"_",@cAviso,@cErro)
				
				If "_TPEMIS" $  cRetorno
					cModTrans		  := IIf (!Empty("oNFeRet:_NFE:_INFNFE:_IDE:_TPEMIS:TEXT"),oNFeRet:_NFE:_INFNFE:_IDE:_TPEMIS:TEXT,1)
				Else
					cModTrans := 1
				EndIf
				
				If ValType(oWs:OWSRETORNANOTASNXRESULT:OWSNOTAS:OWSNFES5[nX]:OWSDPEC)=="O"
					cRetDPEC        := oWs:oWSRETORNANOTASNXRESULT:OWSNOTAS:OWSNFES5[nX]:oWSDPEC:CXML
					cProtDPEC       := oWs:oWSRETORNANOTASNXRESULT:OWSNOTAS:OWSNFES5[nX]:oWSDPEC:CPROTOCOLO
				EndIf
				
	
				//Tratamento para gravar a hora da transmissao da NFe
				If !Empty(cProtocolo)
					oDHRecbto		:= XmlParser(cDHRecbto,"","","")
					
					If "_DHRECBTO" $ cDHRecbto
						cDtHrRec		:= oDHRecbto:_ProtNFE:_INFPROT:_DHRECBTO:TEXT
					Else
						cDtHrRec := ""
					EndIf
					
					nDtHrRec1		:= RAT("T",cDtHrRec)
					
					If nDtHrRec1 <> 0
						cDtHrRec1   :=	SubStr(cDtHrRec,nDtHrRec1+1)
						dDtRecib	:=	SToD(StrTran(SubStr(cDtHrRec,1,AT("T",cDtHrRec)-1),"-",""))
					EndIf
										
				EndIf
	
				nY := aScan(aIdNfe,{|x| x[4]+x[5] == SubStr(oWs:oWSRETORNANOTASNXRESULT:OWSNOTAS:OWSNFES5[nX]:CID,1,Len(x[4]+x[5]))})
	
				oWS:cIdInicial    := aIdNfe[nZ][4]+aIdNfe[nZ][5]
				oWS:cIdFinal      := aIdNfe[nZ][4]+aIdNfe[nZ][5]
				If oWS:MONITORFAIXA()
					cCodRetNFE := oWS:oWsMonitorFaixaResult:OWSMONITORNFE[1]:OWSERRO:OWSLOTENFE[Len(oWS:oWsMonitorFaixaResult:OWSMONITORNFE[1]:OWSERRO:OWSLOTENFE)]:CCODRETNFE
					cMsgNFE	:= oWS:oWsMonitorFaixaResult:OWSMONITORNFE[1]:OWSERRO:OWSLOTENFE[Len(oWS:oWsMonitorFaixaResult:OWSMONITORNFE[1]:OWSERRO:OWSLOTENFE)]:CMSGRETNFE
				EndIf
	
				If nY > 0
					aRetorno[nY][1] := cProtocolo
					aRetorno[nY][2] := cRetorno
					aRetorno[nY][4] := cRetDPEC
					aRetorno[nY][5] := cProtDPEC
					aRetorno[nY][6] := cDtHrRec1
					aRetorno[nY][7] := dDtRecib
					aRetorno[nY][8] := cModTrans
					aRetorno[nY][9] := cCodRetNFE
					aRetorno[nY][10]:= cMsgNFE
				EndIf
				cRetDPEC := ""
				cProtDPEC:= ""
			Next nX
		EndIf
	Else
		U_ITMsg(IIf(Empty(GetWscError(3)),GetWscError(1),GetWscError(3)),"DANFE",,1)
	EndIf 

oWS       := Nil
oDHRecbto := Nil
oNFeRet   := Nil

Return aRetorno[Len(aRetorno)]

/*
===============================================================================================================================
Programa----------: MOMS011L
Autor-------------: Josué Danich Prestes
Data da Criacao---: 12/07/2018
===============================================================================================================================
Descrição---------: Legenda do browse
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS011L()
aLegenda :=	{	{"BR_PRETO"		, "Notas de outros clientes"		},;
				{"BR_VERDE"		, "Pendente"	},;
				{"BR_VERMELHO"	, "Enviado"		} }

 
BrwLegenda("Envio de Xmls para o Walmart","Legenda",aLegenda)

Return

/*
===============================================================================================================================
Programa----------: WScls_403_nfe_xml
Autor-------------: Josué Danich Prestes
Data da Criacao---: 12/07/2018
===============================================================================================================================
Descrição---------: Client Webservice
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/

User Function _LQQXGDP ; Return  // "dummy" function - Internal Use 

/* -------------------------------------------------------------------------------
WSDL Service WScls_403_nfe_xml
------------------------------------------------------------------------------- */

WSCLIENT WScls_403_nfe_xml

	WSMETHOD NEW
	WSMETHOD INIT
	WSMETHOD RESET
	WSMETHOD CLONE
	WSMETHOD fu_upld

	WSDATA   _URL                      AS String
	WSDATA   _CERT                     AS String
	WSDATA   _PRIVKEY                  AS String
	WSDATA   _PASSPHRASE               AS String
	WSDATA   _HEADOUT                  AS Array of String
	WSDATA   _COOKIES                  AS Array of String
	WSDATA   cpa_tp_cd_usua            AS string
	WSDATA   npa_cd_usua               AS decimal
	WSDATA   cpa_ds_xml_nfe            AS string
	WSDATA   cpa_ds_loca_entr          AS string
	WSDATA   oWSfu_upldResult          AS cls_403_nfe_xml_SqlExecutionRetn

ENDWSCLIENT

WSMETHOD NEW WSCLIENT WScls_403_nfe_xml
::Init()
If !FindFunction("XMLCHILDEX")
	UserException("O Código-Fonte Client atual requer os executáveis do Protheus Build [7.00.131227A-20180425 NG] ou superior. Atualize o Protheus ou gere o Código-Fonte novamente utilizando o Build atual.")
EndIf
Return Self

WSMETHOD INIT WSCLIENT WScls_403_nfe_xml
	::oWSfu_upldResult   := cls_403_nfe_xml_SQLEXECUTIONRETN():New()
Return

WSMETHOD RESET WSCLIENT WScls_403_nfe_xml
	::cpa_tp_cd_usua     := NIL 
	::npa_cd_usua        := NIL 
	::cpa_ds_xml_nfe     := NIL 
	::cpa_ds_loca_entr   := NIL 
	::oWSfu_upldResult   := NIL 
	::Init()
Return

WSMETHOD CLONE WSCLIENT WScls_403_nfe_xml
Local oClone := WScls_403_nfe_xml():New()
	oClone:_URL          := ::_URL 
	oClone:_CERT         := ::_CERT 
	oClone:_PRIVKEY      := ::_PRIVKEY 
	oClone:_PASSPHRASE   := ::_PASSPHRASE 
	oClone:cpa_tp_cd_usua := ::cpa_tp_cd_usua
	oClone:npa_cd_usua   := ::npa_cd_usua
	oClone:cpa_ds_xml_nfe := ::cpa_ds_xml_nfe
	oClone:cpa_ds_loca_entr := ::cpa_ds_loca_entr
	oClone:oWSfu_upldResult :=  IIf(::oWSfu_upldResult = NIL , NIL ,::oWSfu_upldResult:Clone() )
Return oClone

// WSDL Method fu_upld of Service WScls_403_nfe_xml

WSMETHOD fu_upld WSSEND cpa_tp_cd_usua,npa_cd_usua,cpa_ds_xml_nfe,cpa_ds_loca_entr WSRECEIVE oWSfu_upldResult WSCLIENT WScls_403_nfe_xml
Private cSoap := "" , oXmlRet

BEGIN WSMETHOD

cSoap += '<fu_upld xmlns="http://www.pontsystems.com.br/">'
cSoap += WSSoapValue("pa_tp_cd_usua", self:cpa_tp_cd_usua, cpa_tp_cd_usua , "string", .F. , .F., 0 , NIL, .F.,.F.) 
cSoap += WSSoapValue("pa_cd_usua", self:npa_cd_usua, npa_cd_usua , "string", .T. , .F., 0 , NIL, .F.,.F.)
cSoap += WSSoapValue("pa_ds_xml_nfe", self:cpa_ds_xml_nfe, cpa_ds_xml_nfe , "string", .F. , .F., 0 , NIL, .F.,.F.)
cSoap += "</fu_upld>"

oXmlRet := SvcSoapCall(	Self,cSoap,; 
	"http://www.pontsystems.com.br/fu_upld",; 
	"DOCUMENT","http://www.pontsystems.com.br/",,,; 
	"https://portalnfe.wmne.com.br/Gnfe_Port_ws/cls_403_nfe_xml.asmx")

::Init()
::oWSfu_upldResult:SoapRecv( WSAdvValue( oXmlRet,"_FU_UPLDRESPONSE:_FU_UPLDRESULT","SqlExecutionRetn",NIL,NIL,NIL,NIL,NIL,NIL) )

END WSMETHOD

oXmlRet := NIL
Return .T.

WSSTRUCT cls_403_nfe_xml_SqlExecutionRetn
	WSDATA   nreturn_code              AS int
	WSDATA   creturn_chav              AS string OPTIONAL
	WSMETHOD NEW
	WSMETHOD INIT
	WSMETHOD CLONE
	WSMETHOD SOAPRECV
ENDWSSTRUCT

WSMETHOD NEW WSCLIENT cls_403_nfe_xml_SqlExecutionRetn
	::Init()
Return Self

WSMETHOD INIT WSCLIENT cls_403_nfe_xml_SqlExecutionRetn
Return

WSMETHOD CLONE WSCLIENT cls_403_nfe_xml_SqlExecutionRetn
	Local oClone := cls_403_nfe_xml_SqlExecutionRetn():NEW()
	oClone:nreturn_code         := ::nreturn_code
	oClone:creturn_chav         := ::creturn_chav
Return oClone

WSMETHOD SOAPRECV WSSEND oResponse WSCLIENT cls_403_nfe_xml_SqlExecutionRetn
	::Init()
	If oResponse = NIL ; Return ; EndIf 
	::nreturn_code       :=  WSAdvValue( oResponse,"_RETURN_CODE","int",NIL,"Property nreturn_code as s:int on SOAP Response not found.",NIL,"N",NIL,NIL) 
	::creturn_chav       :=  WSAdvValue( oResponse,"_RETURN_CHAV","string",NIL,NIL,NIL,"S",NIL,NIL) 
Return

/*
===============================================================================================================================
Programa----------: MOMS011H
Autor-------------: Josué Danich
Data da Criacao---: 16/07/2018
===============================================================================================================================
Descrição---------: histórico de envios de xml da nota selecionada
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum							
===============================================================================================================================
*/
User Function MOMS011H()

Local _alist := {}

ZZK->(DBSetOrder(1))

If ZZK->(DBSeek(SF2->F2_FILIAL+SF2->F2_DOC))

	While ZZK->ZZK_FILIAL == SF2->F2_FILIAL .And. ZZK->ZZK_DOC == SF2->F2_DOC
	
		aAdd(_alist,{ZZK->ZZK_DATA,ZZK->ZZK_HORA,ZZK->ZZK_CDERRO,ZZK->ZZK_DESCRI,ZZK->ZZK_USER})
		
		ZZK->(DBSkip())
						
	EndDo

	_alist := aSort(_alist, , , { | x,y | DToS(x[1])+x[2] < DToS(y[1])+y[2] })
	
	U_ITListBox( 'Envios de xml para nota ' + SF2->F2_FILIAL + "/" +  SF2->F2_DOC , {"Data","Hora","Status","Detalhes","Usuário"} , _alist , .T. , 1 )


Else

	U_ITMsg("Não existem envios para essa nota","Atenção",,3)
	
EndIf

Return
