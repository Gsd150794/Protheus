/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |22/04/2025| Chamado 50505. Alterada a picture do CNPJ para contemplar campo alfanumérico
Lucas Borges  |23/07/2025| Chamado 51340. Trocado e-mail padrão para sistema@italac.com.br
===============================================================================================================================
*/ 

#Include "TOTVS.ch"

Static _lScheduler := FWGetRunSchedule() .Or. SELECT("SX3") <= 0

/*
===============================================================================================================================
Programa----------: MFIN028
Autor-------------: Igor Melgaço
Data da Criacao---: 19/02/2025
Descrição---------: Email referente a fraude de boletos. Chamado: 49940.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MFIN028()
Local _aTables     := {"SA1","SA2","SE1","SE2","ZP1","AC8"} As Array
Local _LigaDesWS   := "" As Char

   If _lScheduler
      FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MFIN028"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MFIN02801"/*cMsgId*/, "MFIN02801 - Inicio do Workflow de Boletos"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
      
      //====================
      //Nao consome licensas
      //====================
      RPCSetType(2)

      //==========================================
      //seta o ambiente com a empresa 01 filial 01
      //==========================================   	 
      RpcSetEnv("01","01",,,,"SCHEDULE_WF_BOLETOS ",_aTables)

      //====================================================================
      // Liga ou Desliga a integração Workflow de Cobranças.
      //====================================================================
      _LigaDesWS := U_ITGETMV('IT_MF25LIG', .T.) 

      If _LigaDesWS
         MFIN028A()
      EndIf 

      //============================================================
      //Limpa o ambiente, liberando a licença e fechando as conexoes
      //============================================================
      RpcClearEnv()  
   Else

      _LigaDesWS := U_ITGETMV('IT_LIGAWCB', .T.) 

      If _LigaDesWS
         Processa( {|| MFIN028A() } , 'Aguarde!' , 'Processando Titulos...' )
      EndIf

   EndIf

Return


/*
===============================================================================================================================
Programa----------: MFIN028
Autor-------------: Igor Melgaço
Data da Criacao---: 19/02/2025
Descrição---------: Workflow de alerta de fraude de boletos. Chamado: 36304.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MFIN028A()
Local _cAlias      := GetNextAlias() As Char
Local _cQry        := "" As Char
Local _nTotRegs    := 0 As Numeric
Local _nRegAtu     := 0 As Numeric
Local _aConfig     := U_ITCFGEML(' ') As Array
Local cFrom        := SuperGetMV('IT_FIN028M',.F., 'sistema@italac.com.br') As Character
Local cTo          := "" As Char
Local cGetCco      := SuperGetMV('ITRFIN28CO',.F., '') As Character
Local _cLog        := "" As Char
Local _cAssunto    := "Boletos Fraudados" As Char
Local cHtml        := "" As Char
Local _aLog        := {} As Array
Local _aCabec      := {"Status","Cod","Loja","Nome","Email","Log"} As Array
Local _cTitAux     := "Log de Processamento" As Char
Local _cMsgTop     := "Registros:" As Char

Begin Sequence

   _cQry := " SELECT E1_CLIENTE, E1_LOJA, A1_NOME, A1_EMAIL, A1_CGC " 
   _cQry += " FROM " + RetSqlName("SE1") + " SE1 "
   _cQry += " INNER JOIN " + RetSqlName("SA1") + " SA1 ON A1_COD = E1_CLIENTE AND A1_LOJA = E1_LOJA AND SA1.D_E_L_E_T_ = ' ' " 
   _cQry += " WHERE A1_EMAIL <> ' ' AND A1_I_IBOLE <> 'N' " 
   _cQry += " AND E1_TIPO = 'NF' AND E1_SALDO > 0 AND E1_ORIGEM = 'MATA460' AND SE1.D_E_L_E_T_ = ' ' " // Linha de Filtro solicitada pelo Antônio
   _cQry += " GROUP BY E1_CLIENTE, E1_LOJA, A1_NOME, A1_EMAIL, A1_CGC " 
   _cQry += " ORDER BY E1_CLIENTE, E1_LOJA, A1_NOME, A1_EMAIL, A1_CGC " 

   If Select(_cAlias) <> 0
      (_cAlias)->(DBCloseArea())
   EndIf
   
   MPSysOpenQuery( _cQry , _cAlias)

   DBSelectArea(_cAlias)
   Count to _nTotRegs

   If !_lScheduler .And. ! U_ITMsg("Confirma envio dos email?","Inicio de processamento",,4,2,2) 
      Break
   EndIf

   (_cAlias)->(DBGoTop())
   While !(_cAlias)->(Eof()) 
      
      _nRegAtu++

      cTo := ""

      If _lScheduler
         FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MFIN028"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MFIN02802"/*cMsgId*/, "MFIN02802 - Enviando o Boleto ref. ao Titulo "+SE1->E1_NUM+" Prefixo "+SE1->E1_PREFIXO+" Parcela "+SE1->E1_PARCELA+" - Registro : " + AllTrim(Str(_nRegAtu)) + " de " + AllTrim(Str(_nTotRegs))/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
      Else
         IncProc("Enviando a Msg do Cliente "+(_cAlias)->A1_NOME+" - Registro : " + AllTrim(Str(_nRegAtu)) + " de " + AllTrim(Str(_nTotRegs)))  
      EndIf

		DBSelectArea("AC8")
		DBSetOrder(2)
		If DBSeek(xFilial("AC8")+"SA1"+xFilial("SA1")+(_cAlias)->E1_CLIENTE+(_cAlias)->E1_LOJA)
			While xFilial("AC8")+"SA1"+xFilial("SA1")+(_cAlias)->E1_CLIENTE+(_cAlias)->E1_LOJA == Rtrim(AC8->(AC8_FILIAL + "SA1" + AC8_FILENT + AC8_CODENT)) .And. AC8->(!Eof())
				DBSelectArea("SU5")
				DBSetOrder(1)
				If DBSeek(AC8->(AC8_FILIAL+AC8_CODCON))
					If !(AllTrim(SU5->U5_EMAIL) $ cTo)
						cTo += IIf(Empty(AllTrim(cTo)),"",";") + AllTrim(SU5->U5_EMAIL)
					EndIf
				EndIf
				AC8->(DBSkip())
			EndDo

			If Empty(AllTrim(cTo))
				cTo := (_cAlias)->A1_EMAIL
			EndIf
		Else
			cTo := (_cAlias)->A1_EMAIL
		EndIf

   	cHtml := 'Prezado Cliente,'
   	cHtml += '<br><br>'
   	cHtml += '&nbsp;&nbsp;&nbsp;<b>'+AllTrim((_cAlias)->A1_NOME)+'.</b>'
   	cHtml += '&nbsp;&nbsp;&nbsp;CNPJ '+TRANSFORM(AllTrim((_cAlias)->A1_CGC),"@R! NN.NNN.NNN/NNNN-99")+'.'
   	cHtml += '<br><br>'
   	cHtml += '&nbsp;&nbsp;&nbsp;MENSAGEM IMPORTANTE!'
   	cHtml += '<br><br>'

   	cHtml += '</table>'
   	cHtml += '<table class=MsoNormalTable border=0 cellpadding=0 width=1010 style="width:327.75pt">'
   	cHtml +=     '<tr>'
   	cHtml +=         '<td style="padding:.75pt .75pt .75pt .75pt">'
   	cHtml +=             '<p class=MsoNormal align=center style="text-align:center">'
   	cHtml +=             '<span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR">'
   	cHtml +=                 '<img width=650 height=1000 src="https://www.italac.com.br/wp-content/uploads/2025/02/WhatsApp_Fraude_2025.png">'
   	cHtml +=             '</span>
   	cHtml +=             '</p>'
   	cHtml +=         '</td>'
   	cHtml +=     '</tr>'
   	cHtml += '</table>'

      U_ITENVMAIL( cFrom , cTo ,  ,cGetCco  , _cAssunto , cHtml ,  , _aConfig[01] , _aConfig[02] , _aConfig[03] , _aConfig[04] , _aConfig[05] , _aConfig[06] , _aConfig[07] , @_cLog ) 
   	lRet :=  ("Sucesso" $ _cLog)

      If !lRet
         aAdd(_aLog,{lRet,(_cAlias)->E1_CLIENTE,(_cAlias)->E1_LOJA,(_cAlias)->A1_NOME,(_cAlias)->A1_EMAIL,_cLog})
      EndIf
      
      (_cAlias)->(DBSkip())

   EndDo

	cHtml := '</table>'
	cHtml += '<table class=MsoNormalTable border=0 cellpadding=0 width=1010 style="width:327.75pt">'
	cHtml +=     '<tr>'
	cHtml +=         '<td style="padding:.75pt .75pt .75pt .75pt">'
	cHtml +=             '<p class=MsoNormal align=center style="text-align:center">'
	cHtml +=             '<span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR">'
	cHtml +=                 '<img width=650 height=1000 src="https://www.italac.com.br/wp-content/uploads/2025/02/WhatsApp_Fraude_2025.png">'
	cHtml +=             '</span>
	cHtml +=             '</p>'
	cHtml +=         '</td>'
	cHtml +=     '</tr>'
	cHtml += '</table>'

   cTo := cFrom
   
   U_ITENVMAIL( cFrom , cTo ,  ,cGetCco  , _cAssunto , cHtml ,  , _aConfig[01] , _aConfig[02] , _aConfig[03] , _aConfig[04] , _aConfig[05] , _aConfig[06] , _aConfig[07] , @_cLog ) 
   //lRet :=  ("Sucesso" $ _cLog)

   If Len(_aLog) > 0
      //ITListBox( _cTitAux , _aHeader , _aCols , _lMaxSiz , _nTipo , _cMsgTop , _lSelUnc , _aSizes , _nCampo , bOk , bCancel, _abuttons, _aCab , bDblClk , _aColXML , bCondMarca,_bLegenda                      ,_lHasOk,_bHeadClk,_aSX1)
      U_ITListBox( _cTitAux , _aCabec  , _aLog  , .F.      , 2      , _cMsgTop ,          ,         ,         ,     ,        ,          ,       ,         ,          ,           , {|C,L|U_MGPE026L(C,L)}        , .F.   ,         ,     )
   EndIf

End Sequence

If Select(_cAlias) <> 0
   (_cAlias)->(DBCloseArea())
EndIf

Return
