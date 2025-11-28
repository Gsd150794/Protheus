/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |04/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25.
Alex Wallauer |15/07/2024| Chamado 47732. Ajsute para aparece a mensagem do arquivo de erro junto com a do ParamIXB[2].
Lucas Borges  |13/10/2024| Chamado 48465. Retirada da função de conout
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: WFPE007
Autor-------------: Darcio Ribeiro Sporl
Data da Criacao---: 23/05/2016
Descrição---------: Ponto de Entrada para alterar a mensagem de retorno do workflow
Parametros--------: ParamIXB[1] -> L -> Indica se o processamento foi executado com sucesso.
					ParamIXB[2] -> C -> Mensagem de status retornada pela execução do processamento do processo.
					ParamIXB[3] -> C -> ID do processo para o qual foi realizado o retorno.
Retorno-----------: cHTML -> Conteúdo HTML que será exibido em substituição à página processamento padrão do Workflow por link
===============================================================================================================================
*/
User Function WFPE007

Local _aArea		:= FWGetArea()
Local _cHTML		:= ""
Local _lSuccess		:= ParamIXB[1]

If ( _lSuccess )
   FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "WFPE007"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "WFPE00701"/*cMsgId*/, "WFPE00701 - Executado com sucesso"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

	// Mensagem em formato HTML para sucesso no processamento.

	_cHTML += '<html> '
	_cHTML += '<head> '
	_cHTML += '</head> '

	_cHTML += '<style Type="text/css"><!-- '
	_cHTML += 'table.bordasimples { border-collapse: collapse; } '
	_cHTML += 'table.bordasimples tr td { border:1px solid #777777; } '
	_cHTML += 'td.grupos	{ font-family:VERDANA; font-size:20px; V-align:middle; background-color: #C6E2FF; color:#000080; } '
	_cHTML += 'td.totais	{ font-family:VERDANA; font-size:18px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #0000FF; color:#FFFFFF; } '
	_cHTML += '--></style> '
	_cHTML += '<body> '
	_cHTML += '<center> '

	_cHTML += '<table width="050%" cellspacing="0" cellpadding="2" border="0"> '
	_cHTML += '  <tr> '
	_cHTML += '    <td width="02%" class="grupos"> '
	_cHTML += '      <center><img src="http://wf.italac.com.br:1026/workflow/htm/logo_novo.jpg" width="100px" height="030px"></center> '
	_cHTML += '	</td> '
	_cHTML += '    <td width="98%" class="grupos"><center> '
	_cHTML += '    <b>Aviso WorkFlow ITALAC</b>'
	_cHTML += '    </center></td> '
	_cHTML += '  </tr> '
	_cHTML += '  <tr> '
	_cHTML += '	<td class="totais" colspan="2"><center> '
	_cHTML += '	<b>Processo executado com sucesso !!!</b><br>'+ParamIXB[2]
	_cHTML += '	</center></td> '
	_cHTML += '  </tr> '
	_cHTML += '</table> '

	_cHTML += '</center> '
	_cHTML += '</body> '
	_cHTML += '</html> '

Else
   FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "WFPE007"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "WFPE00702"/*cMsgId*/, "WFPE00702 - Falha no processamento"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

	//Mensagem em formato HTML para falha no processamento.
	_cHTML += '<html> '
	_cHTML += '<head> '
	_cHTML += '</head> '

	_cHTML += '<style Type="text/css"><!-- '
	_cHTML += 'table.bordasimples { border-collapse: collapse; } '
	_cHTML += 'table.bordasimples tr td { border:1px solid #777777; } '
	_cHTML += 'td.grupos	{ font-family:VERDANA; font-size:20px; V-align:middle; background-color: #CC0000; color:#FFFFFF; } '
	_cHTML += 'td.totais	{ font-family:VERDANA; font-size:18px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #CC0000; color:#FFFFFF; } '//0000FF
	_cHTML += '--></style> '
	_cHTML += '<body> '
	_cHTML += '<center> '

	_cHTML += '<table width="050%" cellspacing="0" cellpadding="2" border="0"> '
	_cHTML += '  <tr> '
	_cHTML += '    <td width="02%" class="grupos"> '
	_cHTML += '      <center><img src="http://wf.italac.com.br:1026/workflow/htm/logo_novo.jpg" width="100px" height="030px"></center> '
	_cHTML += '	</td> '
	_cHTML += '    <td width="98%" class="grupos"><center> '
	_cHTML += '    <b>Aviso WorkFlow ITALAC</b>'
	_cHTML += '    </center></td> '
	_cHTML += '  </tr> '
	_cHTML += '  <tr> '
	_cHTML += '	<td class="totais" colspan="2"><center> '

    chtmlfile  := "\workflow\emp01\" + AllTrim(ParamIXB[3]) + ".Erro"
	_cConteudo:=""
   If File(chtmlfile)
	  FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "WFPE007"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "WFPE00703"/*cMsgId*/, "WFPE00703 - WF-Arq do Erro.........: " + chtmlfile/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
      _cConteudo := MemoRead( chtmlfile)+"<br>"
	  FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "WFPE007"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "WFPE00704"/*cMsgId*/, "WFPE00704 - Obs do WF-Arq do Erro..: " + _cConteudo/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
   Else
	  FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "WFPE007"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "WFPE00705"/*cMsgId*/, "WFPE00705 - Nao tem WF-Arq do Erro.: " + chtmlfile/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
   EndIf
   _cConteudo +=ParamIXB[2]

	_cHTML += '	<b>Falha no processamento !!!</b><br>'+_cConteudo
	_cHTML += '	</center></td> '
	_cHTML += '  </tr> '
	_cHTML += '</table> '

	_cHTML += '</center> '
	_cHTML += '</body> '
	_cHTML += '</html> '

EndIf

FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "WFPE007"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "WFPE00706"/*cMsgId*/, "WFPE00706 - ParamIXB[2]: "+ParamIXB[2]/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "WFPE007"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "WFPE00707"/*cMsgId*/, "WFPE00707 - ParamIXB[3]: "+ParamIXB[3]/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

FWRestArea(_aArea)

Return(_cHTML)
