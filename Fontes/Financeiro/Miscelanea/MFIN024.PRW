/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Antonio Ramos |22/01/2024| Chamado 46144. Tratativa para incluir exceções de email para o cliente
Lucas Borges  |13/10/2024| Chamado 48465. Retirada da função de conout
Lucas Borges  |23/07/2025| Chamado 51340. Trocado e-mail padrão para sistema@italac.com.br
===============================================================================================================================
*/ 

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MFIN024
Autor-------------: Julio de Paula Paz
Data da Criacao---: 02/10/2023
Descrição---------: Workflow de Cobranças - Envio de e-mail/notificações para clientes com Títulos a Vencer ou Vencidos.
                    Chamado: 45189.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MFIN024()
//Local lWFHTML		:= .T.
Local _aTables		:= {"SA1","SA2","SE1","SE2","ZP1"}
Local _cQry, _nI 
Local _LigaDesWS 
Local _nDiaEnvWF
Local _aDiaEnvWF
Local _cClienteL := ""
Local _aDadosTit := {}
Local _cMsgTitulo := ""
Local _cMsgTabela := ""
Local _cQtdExten
Local _dDtVenc
Local _cEmail

Private _cHostWF	:= ""
Private _dDtIni	:= ""
Private cLogo		:= ""

Begin Sequence
   FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MFIN024"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MFIN02401"/*cMsgId*/, "MFIN02401 - Inicio do Workflow de Cobranças"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
   
   //====================
   //Nao consome licensas
   //====================
   RPCSetType(2)

   //==========================================
   //seta o ambiente com a empresa 01 filial 01
   //==========================================   	 
   RpcSetEnv("01","01",,,,"SCHEDULE_WF_PEDIDOS_VENDAS_PORTAL ",_aTables)

   //====================================================================
   // Liga ou Desliga a integração Workflow de Cobranças.
   //====================================================================
   _LigaDesWS := U_ITGETMV('IT_LIGAWCB', .T.) 
   If ! _LigaDesWS
      Break 
   EndIf 

   cLogo	 := _cHostWF + "htm/logo_novo.jpg"

   _cEmailCopia := "" 
   
   _cDiaEnvWF := U_ITGETMV('IT_DIASWFCB', "7;3;0;-1;-3") 
   _aDiaEnvWF := U_ITTXTARRAY(_cDiaEnvWF,";",20,1)

   For _nI := 1 To Len(_aDiaEnvWF)

       If Empty(_aDiaEnvWF[_nI])
          Loop
       EndIf 

       _nDiaEnvWF := Val(_aDiaEnvWF[_nI])
                   
       _cQtdExten := AllTrim(Extenso(_nDiaEnvWF,.T.,0,,"1",.F.,.F.))

       If _nDiaEnvWF < 0 
          _nDiasVenc := -1 * _nDiaEnvWF
          _cMsgTitulo := "Constam em aberto títulos cujo vencimento ocorreu em " + AllTrim(Str(_nDiasVenc,4)) + " Dia(s). "
          _cMsgTabela := "Titulo(s) Vencido(s) em " + AllTrim(Str(_nDiasVenc,4)) + " Dia(s). "
          _cMsgTit2   := ""
       ElseIf _nDiaEnvWF == 0  
          _cMsgTitulo := "Constam em aberto títulos cujo vencimento ocorrerá hoje. "
          _cMsgTabela := "Titulo(s) a Vencer Hoje. "
          _cMsgTit2   := "Fique atento ao vencimento."
       Else
          _cMsgTitulo := "Informamos que seu título vencerá em " + AllTrim(Str(_nDiaEnvWF,4)) + " Dia(s). "
          _cMsgTabela := "Titulo(s) a Vencer em " + AllTrim(Str(_nDiaEnvWF,4)) + " Dia(s). "
          _cMsgTit2   := "Fique atento ao vencimento."
       EndIf 

       _dDtVenc   := Date() + _nDiaEnvWF
                                                                              
       _cQry := " SELECT E1_FILIAL FILIAL,E1_PREFIXO PREFIXO, E1_NUM TITULO, E1_CLIENTE COD_CLI, E1_LOJA LOJA_CLI, E1_NOMCLI NOME_CLIENTE,"  
       _cQry += " E1_EMISSAO DATA_EMISSAO, E1_VENCTO VENCIMENTO, E1_VALOR VALOR_TITULO, E1_SALDO SALDO_TITULO, "
       _cQry += " A1_END END_CLI, A1_MUN MUNICIPIO, A1_CEP CEP, A1_EST UF, "
       _cQry += " A1_EMAIL EMAIL_CLIENTE, A3_EMAIL EMAIL_VEND, E1_PARCELA PARCELA " 
       _cQry += " FROM " + RetSqlName("SE1") + " SE1 "
       _cQry += " INNER JOIN " + RetSqlName("SA1") + " SA1 ON A1_COD = E1_CLIENTE AND A1_LOJA = E1_LOJA AND SE1.D_E_L_E_T_ =' ' AND A1_I_IBOLE='S' " 
       _cQry += " LEFT JOIN "  + RetSqlName("SA3") + " SA3 ON A1_VEND = A3_COD AND SA3.D_E_L_E_T_ = ' ' "
       _cQry += " WHERE E1_VENCTO = '" + DToS(_dDtVenc) + "' "
       _cQry += " AND E1_SALDO > 0 AND E1_TIPO='NF' " 
       _cQry += " AND E1_I_CART= ' ' AND E1_I_DTPRO = '  ' "
       _cQry += " UNION "
       _cQry += " SELECT E1_FILIAL FILIAL,E1_PREFIXO PREFIXO, E1_NUM TITULO, E1_CLIENTE COD_CLI, E1_LOJA LOJA_CLI, E1_NOMCLI NOME_CLIENTE,"  
       _cQry += " E1_EMISSAO DATA_EMISSAO, E1_VENCTO VENCIMENTO, E1_VALOR VALOR_TITULO, E1_SALDO SALDO_TITULO, "
       _cQry += " A1_END END_CLI, A1_MUN MUNICIPIO, A1_CEP CEP, A1_EST UF, "
       _cQry += " A1_EMAIL EMAIL_CLIENTE, A3_EMAIL EMAIL_VEND, E1_PARCELA PARCELA  " 
       _cQry += " FROM " + RetSqlName("SE1") + " SE1 "
       _cQry += " INNER JOIN " + RetSqlName("SA1") + " SA1 ON A1_COD = E1_CLIENTE AND A1_LOJA = E1_LOJA AND SE1.D_E_L_E_T_ =' ' AND A1_I_IBOLE='S' " 
       _cQry += " LEFT JOIN "  + RetSqlName("SA3") + " SA3 ON A1_VEND = A3_COD AND SA3.D_E_L_E_T_ = ' ' "
       _cQry += " WHERE E1_I_DTPRO = '" + DToS(_dDtVenc) + "' "
       _cQry += " AND E1_SALDO > 0 AND E1_TIPO='NF' " 
       _cQry += " AND E1_I_CART= ' ' AND E1_I_DTPRO <> '  ' "
       _cQry += " ORDER BY COD_CLI, LOJA_CLI, FILIAL "
   
       If Select("TRBSE1") <> 0
	       TRBSE1->(DBCloseArea())
       EndIf

       DbUseArea(.T., "TOPCONN", TcGenQry(,,_cQry), "TRBSE1", .T., .F.)

       If ! TRBSE1->(Eof()) 
          _cClienteL := TRBSE1->COD_CLI + TRBSE1->LOJA_CLI
       EndIf 

       _aDadosTit := {}

       While !TRBSE1->(Eof())

         _cEmail := ""

          If _cClienteL <> TRBSE1->COD_CLI + TRBSE1->LOJA_CLI
             
             _cClienteL := TRBSE1->COD_CLI + TRBSE1->LOJA_CLI
                     //(_aDadosEnv,_cTextoTit, _cMsgTitulo,_cMsgTabela,_cMsgTit2) 
             U_MFIN024E(_aDadosTit, _cMsgTitulo,_cMsgTabela,_cMsgTit2)
             
             _aDadosTit := {}

          EndIf 
             //ADICAO DA ROTINA PARA BUSCAR O EMAIL DO CADASTRO DE CONTATOS

            DBSelectArea("AC8")
            DBSetOrder(2)
            If DBSeek(xFilial("AC8")+"SA1"+xFilial("SA1")+TRBSE1->COD_CLI+TRBSE1->LOJA_CLI)
               While xFilial("AC8")+"SA1"+xFilial("SA1")+TRBSE1->COD_CLI+TRBSE1->LOJA_CLI == Rtrim(AC8->(AC8_FILIAL + "SA1" + AC8_FILENT + AC8_CODENT)) .And. AC8->(!Eof())
                  DBSelectArea("SU5")
                  DBSetOrder(1)
                  If DBSeek(AC8->(AC8_FILIAL+AC8_CODCON))
                     _cEmail += IIf(Empty(AllTrim(_cEmail)),"",";") + AllTrim(SU5->U5_EMAIL)
                  EndIf
                  AC8->(DBSkip())
               EndDo
            Else
               _cEmail := AllTrim(TRBSE1->EMAIL_CLIENTE)
            EndIf


            //FIM DA ADICAO

          aAdd(_aDadosTit, {TRBSE1->COD_CLI,;         // 1-Codigo Cliente
                            TRBSE1->LOJA_CLI,;        // 2-Loja Cliente
                            TRBSE1->NOME_CLIENTE,;    // 3-Nome Cliente
                            TRBSE1->FILIAL,;          // 4-Filial
                            TRBSE1->PREFIXO,;         // 5-Prefixo
                            TRBSE1->TITULO,;          // 6-Numero Titulo
                            TRBSE1->DATA_EMISSAO,;    // 7-Data de Emissão
                            TRBSE1->VENCIMENTO,;      // 8-Data de Vencimento
                            TRBSE1->VALOR_TITULO,;    // 9-Valor do Titulo
                            TRBSE1->SALDO_TITULO,;    // 10-Saldo 
                            TRBSE1->END_CLI,;         // 11-Endereço 
                            TRBSE1->MUNICIPIO,;       // 12-Municipio
                            TRBSE1->CEP,;             // 13-Cep
                            TRBSE1->UF,;              // 14-Estado
                            _cEmail,;   // 15-Email Cliente
                            TRBSE1->EMAIL_VEND,;      // 16-Email Vendedor
                            TRBSE1->PARCELA})         // 17-Parcela

          TRBSE1->(DBSkip())
       EndDo

       If Len(_aDadosTit) > 0
          U_MFIN024E(_aDadosTit, _cMsgTitulo,_cMsgTabela,_cMsgTit2)
       EndIf 

       _cMsgTitulo := ""
       _cMsgTabela := ""
       _cMsgTit2   := ""      
       
   Next

 	//============================================================
	//Limpa o ambiente, liberando a licença e fechando as conexoes
	//============================================================
	RpcClearEnv()  
	
End Sequence 

If Select("TRBSE1") <> 0
   TRBSE1->(DBCloseArea())
EndIf

Return

/*
===============================================================================================================================
Programa----------: MFIN024E
Autor-------------: Julio de Paula Paz
Data da Criacao---: 02/10/2023
Descrição---------: Rotina de envio de e-mail via Workflow para coordenadores ou gerentes.
Parametros--------: _aDadosEnv  - Array com os dados de envio do Workflow    // _cTextoTit  - Texto a complementar o Título do Workflow
                    _cMsgTitulo - Mensagem de titulo
                    _cMsgTabela - Mensagem na parte da tabela
                    _cMsgTit2   - Complemento da mensagem do título
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MFIN024E(_aDadosEnv, _cMsgTitulo,_cMsgTabela,_cMsgTit2)
Local _nI 
Local _cMsgEml
Local _cRazaoSoc
Local _cEnder1
Local _cEnder2
Local _cFrom,_cItem5 // _cItem3,
Local _cItem6,_cItem7,_cPassword
Local _cServer,_cPortCon,_lRelauth,_cUserAut,_cPassAut,_cItem15
Local _aConfig	
Local _cEmailBcc

Local _aListEml := StrTokArr( U_ITGETMV('IT_EXCEMLCB', ''),";")
Local _nItEml 

Begin Sequence

   _cRazaoSoc := AllTrim(_aDadosEnv[1,3]) + " ( " + AllTrim(_aDadosEnv[1,1]) + " - " + AllTrim(_aDadosEnv[1,2]) + " )" // 3-Nome Cliente
   _cEnder1   := _aDadosEnv[1,11] // 11-Endereço 
   _cEnder2   := AllTrim(_aDadosEnv[1,12]) + " - " + AllTrim(_aDadosEnv[1,14]) + " - " + AllTrim(_aDadosEnv[1,13]) // 12-Municipio // TRBSE1->UF = 14-Estado / TRBSE1->CEP = 13-Cep

   //Logo Italac
   _cMsgEml := '<html>'
   _cMsgEml += '<head><title>Workflow de Cobrança - Italac</title></head>'
   _cMsgEml += '<body>'
   _cMsgEml += '<style Type="text/css"><!--'
   _cMsgEml += 'table.bordasimples { border-collapse: collapse; }'
   _cMsgEml += 'table.bordasimples tr td { border:1px solid #777777; }'
   _cMsgEml += 'td.titulos	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #C6E2FF; }'
   _cMsgEml += 'td.grupos	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #E5E5E5; }'
   _cMsgEml += 'td.itens	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #E5E5E5; }' // #FFFFFF
   _cMsgEml += '--></style>'
   _cMsgEml += '<center>'
   _cMsgEml += '<img src="http://www.italac.com.br/wf/italac-wf.jpg" width="600" height="50"><br>'
   _cMsgEml += '<br>'

   //Celula Azul para Título
   _cMsgEml += '<table class="bordasimples" width="100%">' // _cMsgEml += '<table class="bordasimples" width="600">'
   _cMsgEml += '    <tr>'
   _cMsgEml += '	     <td class="titulos"><center>Workflow de Cobranças - Italac</center></td>'
   _cMsgEml += '	 </tr>'
   _cMsgEml += '</table>'
   _cMsgEml += '<br>'

   _cMsgEml += '<br>'
   _cMsgEml += '<table border="0" width="095%">'
   _cMsgEml += '	<tr>'
   _cMsgEml += '		<td valign="top" class="texto">'
   _cMsgEml += '			<br><b> FAVOR NÃO RESPONDER ESSE EMAIL. </b>'   
   _cMsgEml += '     </td>
   _cMsgEml += '	 </tr>'
   _cMsgEml += '</table>'
   _cMsgEml += '<br>'

   _cMsgEml += '  <table border="0" width="095%">'
   _cMsgEml += '	<tr>'
   _cMsgEml += '		<td valign="top" class="texto">'
   _cMsgEml += '			<br>Prezado Cliente'
   _cMsgEml += '			<br><br>' + _cRazaoSoc  // !RazaoSoc!
   _cMsgEml += '			<br>' + _cEnder1        // !Endereco1!'
   _cMsgEml += '			<br>' + _cEnder2        // !Endereco2!
   _cMsgEml += '			<br><br>' + _cMsgTitulo // !TextoVenc!
   
   If ! Empty(_cMsgTit2)
      _cMsgEml += '			<br><br>' + _cMsgTit2   // !TextoVen2!
      _cMsgEml += '			<br>'
   EndIf 

   _cMsgEml += '		</td>'
   _cMsgEml += '	</tr>'
   _cMsgEml += '</table>'
   _cMsgEml += '<br>'

   _cMsgEml += '<table class="bordasimples" width="100%">' //_cMsgEml += '<table class="bordasimples" width="600">'//_cMsgEml += '<table width="095%" border="0" CellSpacing="2" CellPadding="0">'
   _cMsgEml += '<tr>' 
   _cMsgEml += '<td align="center" width="100%" height="23" class="titulos">'+_cMsgTabela+'</td>' // !TextoTab! // class="grupos"
   _cMsgEml += '</tr>
   _cMsgEml += '</table>'
   _cMsgEml += '<table class="bordasimples" width="100%">' //_cMsgEml += '<table class="bordasimples" width="600">'//_cMsgEml += '<table width="095%" border="0" CellSpacing="2" CellPadding="0">'
   _cMsgEml += '<tr> 
   _cMsgEml += '<td align="center" width="5%"  height="23" class="titulos">Filial</td>'
   _cMsgEml += '<td align="center" width="5%"  height="23" class="titulos">Prefixo</td>'
   _cMsgEml += '<td align="center" width="15%" height="23" class="titulos">No.Titulo</td>'
   _cMsgEml += '<td align="center" width="5%"  height="23" class="titulos">Parcela</td>'
   _cMsgEml += '<td align="center" width="5%"  height="23" class="titulos">Dt.Emissão</td>'
   _cMsgEml += '<td align="center" width="5%"  height="23" class="titulos">Vencimento Original</td>'
   _cMsgEml += '<td align="center" width="15%" height="23" class="titulos">Valor do Titulo</td>'	
   _cMsgEml += '<td align="center" width="15%" height="23" class="titulos">Saldo</td>'	
   _cMsgEml += '</tr>'

   For _nI := 1 To Len(_aDadosEnv)
       _cCodFilial := _aDadosEnv[_nI,4]  // 4-Filial
       _cPrefixo   := _aDadosEnv[_nI,5]  // 5-Prefixo
       _cNrTitulo  := _aDadosEnv[_nI,6]  // 6-Numero Titulo
       _dDtEimiss  := _aDadosEnv[_nI,7]  // 7-Data de Emissão
       _dDtVecOri  := _aDadosEnv[_nI,8]  // 8-Data de Vencimento
       _nValTitul  := _aDadosEnv[_nI,9]  // 9-Valor do Titulo
       _nValSaldo  := _aDadosEnv[_nI,10] // 10-Saldo 
       _cParcela   := _aDadosEnv[_nI,17] // 17-Parcela

       _cMsgEml += '<tr>'
       _cMsgEml += '<td align="center" valign="top" width="5%" height="23" class="itens">' +_cCodFilial+'</td>'
       _cMsgEml += '<td align="center" valign="top" width="5%" height="23" class="itens">' +_cPrefixo  +'</td>'
       _cMsgEml += '<td align="center" valign="top" width="15%" height="23" class="itens">'+_cNrTitulo +'</td>'
       _cMsgEml += '<td align="center" valign="top" width="5%" height="23" class="itens">' +_cParcela  +'</td>'
       _cMsgEml += '<td align="center" valign="top" width="5%" height="23" class="itens">' +DToC(SToD(_dDtEimiss))+'</td>'
       _cMsgEml += '<td align="center" valign="top" width="5%" height="23" class="itens">' +DToC(SToD(_dDtVecOri))+'</td>'		
       _cMsgEml += '<td align="right"  valign="top" width="15%" height="23" class="itens">'+Transform(_nValTitul,"@E 999,999,999,999.99")+'</td>'	// AllTrim(Str(_nValTitul,16,2))
       _cMsgEml += '<td align="right"  valign="top" width="15%" height="23" class="itens">'+Transform(_nValSaldo,"@E 999,999,999,999.99")+'</td>'	// AllTrim(Str(_nValSaldo,16,2))	
       _cMsgEml += '</tr>
   Next 
   _cMsgEml += '</table>'

   _cMsgEml += '<br>'
   _cMsgEml += '<br>'
   _cMsgEml += '<br>'
   _cMsgEml += '<table border="0" width="095%">'
   _cMsgEml += '	<tr>'
   _cMsgEml += '		<td valign="top" class="texto">'
   _cMsgEml += '			<br>Em virtude de uma FRAUDE que vem ocorrendo no mercado, alertamos nossos clientes e parceiros que tivemos '
   _cMsgEml += '            <br>conhecimento nos últimos dias de emissão fraudulenta, por terceiros, de boletos bancários utilizando indevidamente o '
   _cMsgEml += '            <br>nome da nossa empresa.'
   _cMsgEml += '            <br><br>Estes boletos estão sendo enviados por e-mail, sob falso aviso de títulos a vencer, troca de boletos ou concessão de '
   _cMsgEml += '            <br>descontos/bonificações. '
   _cMsgEml += '            <br>Trata-se de uma FRAUDE para subtrair dinheiro dos destinatários dos boletos, motivo pelo qual, reiteramos que a '
   _cMsgEml += '            <br>Italac não tem o procedimento de alterar boletos, o envio de nossos Boletos é sempre impresso e anexados às notas '
   _cMsgEml += '            <br>fiscais e nosso e-mail sempre possui a extensão @italac.com.br.'
   _cMsgEml += '            <br><br>Ressaltamos que o pagamento de boletos falsos não quitará a duplicata que eventualmente estiver aberta com a '
   _cMsgEml += '            <br>nossa empresa, motivo pelo qual, caso receba algum contato neste sentido ou observe qualquer situação  suspeita, '
   _cMsgEml += '            <br>pedimos a gentileza de que comunique imediatamente o nosso Departamento Financeiro através do telefone (11) '
   _cMsgEml += '            <br>2889-5959 / 11-9-7335-1381 ou através do e-mail  cobranca@italac.com.br.'
   _cMsgEml += '            <br><br>Caso o pagamento já tenha sido realizado, pedimos que desconsidere esta notificação. '
   _cMsgEml += '			<br>'
   _cMsgEml += '		</td>'
   _cMsgEml += '	</tr>'
   _cMsgEml += '</table>'

   _cMsgEml += '</center>'
   _cMsgEml += '<br>'
   _cMsgEml += '<br>'
   _cMsgEml += '    <tr>'
   _cMsgEml += '      <td class="itens" align="center" ><b>Ambiente:</b></td>'
   _cMsgEml += '      <td class="itens" align="left" > ['+ GETENVSERVER() +'] / <b>Fonte:</b> [MFIN024]</td>'
   _cMsgEml += '    </tr>'
   _cMsgEml += '</body>'
   _cMsgEml += '</html>'

   //================================================================================
   // Retorna as informações do servidor Workflow
   //================================================================================
   _aConfig	  := U_ITCFGEML('')
   _cFrom     := _aConfig[01]   
   _cAccount  := _aConfig[01]
   _cPassword := _aConfig[02] 
   _cServer   := _aConfig[03] 
   _cPortCon  := _aConfig[04]
   _lRelauth  := _aConfig[05] 
   _cUserAut  := _aConfig[06]
   _cPassAut  := _aConfig[07]

   _cEmlLog := ""
   _cEmailCli := _aDadosEnv[1,15] // E-mail do Cliente

   _cItem2    := "" 
   _cEmailVen := AllTrim(_aDadosEnv[1,16]) // E-mail do Vendedor
   _cEmailBcc := SuperGetMV("IT_MLFINWF",.F.,"sistema@italac.com.br")
   _cItem5    := "WORKFLOW DE COBRANÇAS - ITALAC - GERADO EM: "+ DToC(Date()) + " - AS: " + Time()
   _cItem6    := AllTrim(_cMsgEml)
   _cItem7    := "" // AllTrim(_cAnexos)
   _cItem15   := "" //_cEmlLog


   For _nItEml := 1 To Len(_aListEml)
      _cEmailVen := StrTran(lower(AllTrim(_cEmailVen)),AllTrim(_aListEml[_nItEml]),"")
      _cEmailCli := StrTran(lower(AllTrim(_cEmailCli)),AllTrim(_aListEml[_nItEml]),"")
   Next _nItEml

   //ITEnvMail(cFrom ,cEmailTo,cEmailCo,cEmailBcc,cAssunto,cMensagem,cAttach,cAccount,cPassword,cServer,cPortCon,lRelauth,cUserAut,cPassAut,cLogErro,lExibeAmb)
   U_ITEnvMail(_cFrom,_cEmailCli	,_cEmailVen,_cEmailBcc,_cItem5,_cItem6,_cItem7,_cFrom ,_cPassword,_cServer,_cPortCon,_lRelauth,_cUserAut,_cPassAut,@_cItem15)

   FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MFIN024"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MFIN02402"/*cMsgId*/, "MFIN02402 - "+_cEmlLog/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

End Sequence

Return
