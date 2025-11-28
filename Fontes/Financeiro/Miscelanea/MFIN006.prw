/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |30/10/2019| Chamado 31032. Correção do envio do e-mail
Julio Paz     |13/12/2022| Chamado 42025. Realização de Ajustes no Workflow, alteração titulos e filtros do relatório.
Lucas Borges  |13/10/2024| Chamado 48465. Retirada da função de conout
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: MFIN006
Autor-----------: Guilherme Diogo
Data da Criacao-: 11/12/2012
Descrição-------: Funcao desenvolvida para o envio do relatorio do fluxo de caixa diário a partir do dia corrente do mes.
                  Envia relatório HTML para destinatários cadastrados no configurador (ZZL)
Parametros------: N/enhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function MFIN006()

Local aTables    := { "SE1" , "SE2" , "ZZL" }
Local _cAliasEm  := ""
Local _cEmails   := ""

Local _lCriaAmb  := .F.

//================================================================================
// Verifica a necessidade de abrir um ambiente, caso ainda nao tenha sido aberto
//================================================================================
If Select("SX3") <= 0
	_lCriaAmb := .T.
EndIf

If _lCriaAmb

	RPCSetType(3)												//Nao consome licensas
	RpcSetEnv("01","01",,,,"SCHEDULE_EMAIL_RESUMO",aTables)		//seta o ambiente com a empresa 01 filial 01
    sleep( 5000 )												//aguarda 5 segundos para que as jobs IPC subam.
	
    //================================================================================
    // Mensagem que ficara armazenada no arquivo de log para posterior monitoramento
    //================================================================================
	FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MFIN00601"/*cMsgId*/, "MFIN00601 - Gerando envio do arquivo HTML de Fluxo de Caixa na data: "+ DToC(DATE()) +" - "+ Time()/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

EndIf
	
//================================================================================
// Verifica inicialmente para quais usuarios o resumo sera enviado.
//================================================================================
_cAliasEm := GetNextAlias()
MFIN006Q( 5 , _cAliasEm )

DBSelectArea(_cAliasEm)
(_cAliasEm)->( DBGoTop() )

//================================================================================
// Devera existir no minimo um e-mail para que a rotina processo a montagem e 
// envio do arquivo de resumo de vendas.
//================================================================================
If (_cAliasEm)->( !Eof() )

	While (_cAliasEm)->( !Eof() )
	
		_cEmails += ";" + AllTrim( (_cAliasEm)->ZZL_EMAIL )
		
	(_cAliasEm)->( DBSkip() )
	EndDo
	
	_cEmails := SubStr( _cEmails , 2 , Len(_cEmails) )
	
	//================================================================================
	// Funcao responsavel por montar o HTML para envio.
	//================================================================================
	MFIN006H( _cEmails )
	
EndIf

//================================================================================
// Finaliza a area criada anteriormente.
//================================================================================
DBSelectArea(_cAliasEm)


(_cAliasEm)->( DBCloseArea() )

If _lCriaAmb
    
	RpcClearEnv() //Limpa o ambiente, liberando a licença e fechando as conexões
	FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MFIN00602"/*cMsgId*/, "MFIN00602 - Termino de execucao normal do envio do HTML de Fluxo de Caixa na data:" + DToC(DATE()) + " - " + Time()/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

EndIf

Return

/*
===============================================================================================================================
Programa--------: MFIN006H
Autor-----------: Fabiano Dias da Silva
Data da Criacao-: 13/09/2011
Descrição-------: Funcao desenvolvida para realizar a geracao do arquivo HTML para posterior envio aos usuarios.
                  Envia relatório HTML para destinatários cadastrados no configurador (ZZL).
Parametros------: _cEmailDes = E-mails dos destinatários.
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function MFIN006H(_cEmailDes)

Local _horario		:= StrTran(Time(),":","'")				//Nao se pode gerar um arquivo com o nome que contenha o caracter ":"
Local _cArqAnexo	:= "\spool\fluxo" + _horario + ".HTM"	//Nome do arquivo anexo a ser enviado ao usuario
Local _cArqHtml		:= ''
Local _nHdl			:= 0
Local _cTxtHTM		:= ""
Local _aDadosAux	:= {}
Local _aDadVen		:= {}
Local _lRet			:= .T.
Local _cAliasGer	:= "" 
Local _cAliasRec	:= ""
Local _cAliasSld	:= ""
Local _cAliasPag 	:= ""
Local _cAlias		:= GetNextAlias()
Local _cAliSC7		:= ""
Local _cRecD1		:= ""
Local _cMsgEmail	:= ""
Local _cGeracao		:= DToC( Date() )
Local _nVenc15		:= 0
Local _nI			:= 0
Local _nSldBan		:= 0
Local _nSldAdt		:= 0
Local _nTGerPag		:= 0
Local _nTGerRec		:= 0
Local _nTMesPag		:= 0
Local _nTMesRec		:= 0
Local _cMes			:= ""
Local _cAno			:= ""
Local _nTSaldDia	:= 0
Local _nValAnt		:= 0
Local _nValSum		:= 0
Local _nVencPag		:= 0
Local _nPagNDF		:= 0
Local _nPagPrev		:= 0
Local _nVePagR		:= 0
Local _nVencREC1	:= 0
Local _nNCCD1		:= 0
Local _nNDFR		:= 0
Local _nPrevR		:= 0
Local _nTMesPrev	:= 0
Local _nTGerPrev	:= 0
Local _nTMesPC		:= 0
Local _nTGerPC		:= 0
Local _cCorPN		:= ""
Local _nCont		:= 0
Local _nTC			:= 0
Local _nPosAux		:= 0
Local _aConfig	  := U_ITCFGEML('')

//================================================================================
// Inicialização do HTML e configuração dos scripts
//================================================================================
_cTxtHTM += '<html><head><title>Relatório de Fluxo de Caixa - Italac</title></head>'
_cTxtHTM += '<style Type="text/css"><!--'
_cTxtHTM += 'table.bordasimples { border-collapse: collapse; } '
_cTxtHTM += 'table.bordasimples tr td { border:1px solid #777777; } '
_cTxtHTM += 'td.grupos	{ font-family:VERDANA; font-size:18px; V-align:middle; background-color: #000099; color:#FFFFFF; } '
_cTxtHTM += 'td.titulos	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #EEDD82; } '
_cTxtHTM += 'td.itens	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; } '
_cTxtHTM += 'td.totais	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #AAAAAA; } '
_cTxtHTM += '--></style>'
_cTxtHTM += '<body>'

//================================================================================
// Título do relatório.
//================================================================================
_cTxtHTM += '<table class="bordasimples" cellpadding=5 cellspacing=0 width="100%">'
_cTxtHTM += '<tr><td align=center class="grupos"><b>Fluxo de Caixa - Italac</b></td></tr>'
_cTxtHTM += '</table>'
_cTxtHTM += '<br>'
_cTxtHTM += '<table class="bordasimples" cellpadding=2 cellspacing=0 width="100%">'
_cTxtHTM += '<tr><td align=center class="grupos"><b>Gerado em: '+ _cGeracao +' às '+ Transform(Time(),"@R 99:99") +'</b></td></tr>'
_cTxtHTM += '</table>'
_cTxtHTM += '<br>'

//================================================================================
// TABELA QUE RETORNA OS SALDOS BANCARIOS.
//================================================================================
_cAliasSld := GetNextAlias()
MFIN006Q( 4 , _cAliasSld )

DBSelectArea(_cAliasSld)
(_cAliasSld)->( DBGoTop() )
	_nSldBan := (_cAliasSld)->SLD_ATUAL
(_cAliasSld)->( DBCloseArea() )

//================================================================================
// Chama funcao para retornar o por dia a Receber, a pagar e previsao(cp)
//================================================================================
_nSldAdt	:= 0
_cAliasGer	:= GetNextAlias()
_cAliSC7	:= GetNextAlias()
_aDadVen	:= MFIN006Q( 9 , _cAliSC7 )

MFIN006Q( 1 , _cAliasGer )

DBSelectArea(_cAliasGer)
(_cAliasGer)->( DBGoTop() )
While (_cAliasGer)->( !Eof() )
	
	_nValPC		:= 0
	_nPosAux	:= aScan( _aDadVen , {|x| DToS( x[1] ) == (_cAliasGer)->VENCIMENTO } )
	
	If _nPosAux > 0
	
		While _nPosAux <= Len(_aDadVen) .And. DToS( _aDadVen[_nPosAux][1] ) == (_cAliasGer)->VENCIMENTO
			
			_nValPC += _aDadVen[_nPosAux][2]
			
		_nPosAux++
		EndDo
	
	EndIf
	
	aAdd( _aDadosAux , {	(_cAliasGer)->VENCIMENTO	,;
							(_cAliasGer)->SALDO_REC		,;
							(_cAliasGer)->SALDO_PAG		,;
							(_cAliasGer)->VAL_ADT		,;
							(_cAliasGer)->PREV_CP		,;
							_nValPC						})
	
	_nSldAdt += (_cAliasGer)->VAL_ADT
	
(_cAliasGer)->( DBSkip() )
EndDo

(_cAliasGer)->( DBCloseArea() )

_cTxtHTM += '<table class="bordasimples" cellpadding=0 cellspacing=0 width="400px">'
_cTxtHTM += '<tr>'
_cTxtHTM += '  <td class="itens"   width="60%" align="LEFT" bgcolor="#D8D8D8"><b>Saldos Bancários</b></td>'
IIf( _nSldBan >= 0 , _cCorPN := "#000000" , _cCorPN := "#CD0000" )
_cTxtHTM += '  <td class="titulos" width="40%" align="RIGHT"><b><font color="'+ _cCorPN +'">'+ Transform( _nSldBan , "@E 999,999,999,999.99" )+'</font></b></td>'
_cTxtHTM += '</tr>'
_cTxtHTM += '<tr>'
_cTxtHTM += '  <td class="itens"   width="60%" align="LEFT" bgcolor="#D8D8D8"><b>Saldos Antecipados:</b></td>'
IIf( _nSldAdt >= 0 , _cCorPN := "#000000" , _cCorPN := "#CD0000" )
_cTxtHTM += '  <td class="titulos" width="40%" align="RIGHT"><b><font color="'+ _cCorPN +'">'+ Transform( _nSldAdt , "@E 999,999,999,999.99" )+'</font></b></td>'
_cTxtHTM += '</tr>'
_cTxtHTM += '<tr>'
_cTxtHTM += '  <td class="itens"   width="60%" align="LEFT" bgcolor="#D8D8D8"><b>Saldo Inicial:</b></td>'
IIf( ( _nSldBan + _nSldAdt ) >= 0 , _cCorPN := "#000000" , _cCorPN := "#CD0000" )
_cTxtHTM += '  <td class="titulos" width="40%" align="RIGHT"><b><font color="'+ _cCorPN +'">'+ Transform( _nSldBan + _nSldAdt , "@E 999,999,999,999.99" ) +'</font></b></td>'
_cTxtHTM += '</tr>'
_cTxtHTM += '</table>'
_cTxtHTM += '<br>'

_nSldBan += _nSldAdt

//================================================================================
// Define estrutura da primeira secao CONTAS A RECEBER DIARIO
//================================================================================
_cTxtHTM += '<table class="bordasimples" cellpadding=0 cellspacing=0 width="100%">'
_cTxtHTM += '<tr>'
_cTxtHTM += '  <td class="itens" bgcolor="#D8D8D8" width="20%" align=center><b>Data</b></td>'
_cTxtHTM += '  <td class="itens" bgcolor="#D8D8D8" width="12%" align=center><b>Valor a Receber(R$)</b></td>'
_cTxtHTM += '  <td class="itens" bgcolor="#D8D8D8" width="12%" align=center><b>Valor a Pagar(R$)</b></td>'
_cTxtHTM += '  <td class="itens" bgcolor="#D8D8D8" width="12%" align=center><b>Valor Antecipado(R$)</b></td>'
_cTxtHTM += '  <td class="itens" bgcolor="#D8D8D8" width="16%" align=center><b>Saldo na Data(R$)</b></td>'
_cTxtHTM += '  <td class="itens" bgcolor="#777777" width="02%" align=center>&nbsp;</td>'
_cTxtHTM += '  <td class="itens" bgcolor="#D8D8D8" width="12%" align=center><b>Valor de Previsão(CP)</b></td>'
_cTxtHTM += '  <td class="itens" bgcolor="#777777" width="02%" align=center>&nbsp;</td>'
_cTxtHTM += '  <td class="itens" bgcolor="#D8D8D8" width="12%" align=center><b>Valor de PC(R$)</b></td>'
_cTxtHTM += '</tr>'

//================================================================================
// Retornar as informacoes de Vencidas a Receber - 1 dia de vencido
//================================================================================
_cRecD1 := GetNextAlias()
MFIN006Q( 7 , _cRecD1 )

DBSelectArea(_cRecD1)
(_cRecD1)->( DBGoTop() )

	_nVencREC1	:=	(_cRecD1)->VREC_D1
	_nNCCD1		:=	(_cRecD1)->NCC_D1
	
(_cRecD1)->( DBCloseArea() )

//================================================================================
// Retornar informações do quadro Posicao - Contas a Pagar Vencidos - Até 30 dias
//================================================================================
_cAliasPag:= GetNextAlias()
MFIN006Q( 3 , _cAliasPag )

DBSelectArea( _cAliasPag )
(_cAliasPag)->( DBGoTop() )

	_nVencPag	:=	(_cAliasPag)->VENC_PAG
	_nPagPrev   :=	(_cAliasPag)->PAG_PREV
	_nPagNDF	:=	(_cAliasPag)->PAG_NDF
	
(_cAliasPag)->( DBCloseArea() )

//================================================================================
// Primeira linha da tabela com vencidas a pagar
//================================================================================
If GETMV("IT_SLDFLU") == "S"
	_nTSaldDia := (_nTSaldDia-(_nVencPag+_nPagPrev-_nPagNDF)+(_nVencREC1 - _nNCCD1)) + _nSldBan
Else
	_nTSaldDia := _nTSaldDia-(_nVencPag+_nPagPrev-_nPagNDF)+(_nVencREC1 - _nNCCD1)
EndIf

If _nTSaldDia >= 0
	_cCorPN := "#000000"
Else
	_cCorPN := "#CD0000"
EndIf

_cTxtHTM += '<tr>'
_cTxtHTM += '  <td class="itens" bgcolor="#EEDD82" width="20%" align="center">&nbsp;</td>'
_cTxtHTM += '  <td class="itens" bgcolor="#EEDD82" width="12%" align="RIGHT" >'+ Transform( _nVencREC1 - _nNCCD1 , "@E 999,999,999,999.99" ) +'</td>'
_cTxtHTM += '  <td class="itens" bgcolor="#EEDD82" width="12%" align="RIGHT" >'+ Transform( _nVencPag + _nPagPrev - _nPagNDF	, "@E 999,999,999,999.99" )	+'</td>'
_cTxtHTM += '  <td class="itens" bgcolor="#EEDD82" width="12%" align="center">&nbsp;</td>'
_cTxtHTM += '  <td class="itens" bgcolor="#EEDD82" width="16%" align="RIGHT" ><font color="'+ _cCorPN +'">'+ Transform( _nTSaldDia , "@E 999,999,999,999.99" ) +'</font></td>'
_cTxtHTM += '  <td class="itens" bgcolor="#777777" width="02%" align="center">&nbsp;</td>'
_cTxtHTM += '  <td class="itens" bgcolor="#EEDD82" width="12%" align="center">&nbsp;</td>'
_cTxtHTM += '  <td class="itens" bgcolor="#777777" width="02%" align="center">&nbsp;</td>'
_cTxtHTM += '  <td class="itens" bgcolor="#EEDD82" width="12%" align="center">&nbsp;</td>'
_cTxtHTM += '</tr>'

//================================================================================
// Insere os dados de todas as filiais encontradas na consulta.
//================================================================================
_nI := 1

While _nI <= Len( _aDadosAux )
    
    _nCont++
    
	_dUltDia	:= DToS( lastday( SToD( _aDadosAux[_nI][01] ) ) )
	_cMes       := SubStr( _aDadosAux[_nI][01] , 5 , 2 )
	_cAno       := SubStr( _aDadosAux[_nI][01] , 3 , 2 )
	_nTMesRec	:= 0
	_nTMesPrev	:= 0
	_nTMesAdt	:= 0
	_nTMesPC	:= 0
	
	If _nCont == 1
		_nTMesPag	:= _nVencPag+_nPagPrev-_nPagNDF
	Else	
		_nTMesPag	:=	0
	EndIf
	
	While _nI <= Len( _aDadosAux ) .And. _aDadosAux[_nI][01] <= _dUltDia
		
		_nTMesRec	+= _aDadosAux[_nI][02]
		_nTMesPag	+= _aDadosAux[_nI][03] + _aDadosAux[_nI][06]
		_nTMesAdt	+= _aDadosAux[_nI][04]
		_nTGerPag	+= _aDadosAux[_nI][03] + _aDadosAux[_nI][06]
		_nTGerRec	+= _aDadosAux[_nI][02]
		_nTSaldDia  += _aDadosAux[_nI][02] - ( _aDadosAux[_nI][03] + _aDadosAux[_nI][06] ) - _aDadosAux[_nI][04]
		_nTMesPrev  += _aDadosAux[_nI][05]
		_nTGerPrev  += _aDadosAux[_nI][05]
		_nTMesPC	+= _aDadosAux[_nI][06]
		_nTGerPC	+= _aDadosAux[_nI][06]
		_dData	    := DToC( SToD( _aDadosAux[_nI][01] ) )
		
		If _nTSaldDia >= 0
			_cCorPN := "#000000"
		Else
			_cCorPN := "#CD0000"
		EndIf
		
		_cTxtHTM += '<tr>'
		_cTxtHTM += '  <td class="itens" bgcolor="#EEDD82" width="20%" align="center">'+ _dData +'</td>'
		_cTxtHTM += '  <td class="itens" bgcolor="#EEDD82" width="12%" align="right" >'+ Transform( _aDadosAux[_nI][02] , "@E 999,999,999,999.99" ) +'</td>'
		_cTxtHTM += '  <td class="itens" bgcolor="#EEDD82" width="12%" align="right" >'+ Transform( _aDadosAux[_nI][03] + _aDadosAux[_nI][06] , "@E 999,999,999,999.99" )	+'</td>'
		_cTxtHTM += '  <td class="itens" bgcolor="#EEDD82" width="12%" align="right" >'+ Transform( _aDadosAux[_nI][04] , "@E 999,999,999,999.99" ) +'</td>'
		_cTxtHTM += '  <td class="itens" bgcolor="#EEDD82" width="16%" align="right" ><font color="'+ _cCorPN +'">'+ Transform( _nTSaldDia , "@E 999,999,999,999.99" ) +'</font></td>'
		_cTxtHTM += '  <td class="itens" bgcolor="#777777" width="02%" align="center">&nbsp;</td>'
		_cTxtHTM += '  <td class="itens" bgcolor="#EEDD82" width="12%" align="right" >'+ Transform( _aDadosAux[_nI][05] , "@E 999,999,999,999.99" ) +'</td>'
		_cTxtHTM += '  <td class="itens" bgcolor="#777777" width="02%" align="center">&nbsp;</td>'
		_cTxtHTM += '  <td class="itens" bgcolor="#EEDD82" width="12%" align="right" >'+ Transform( _aDadosAux[_nI][06] , "@E 999,999,999,999.99" ) +'</td>'
		_cTxtHTM += '</tr>'
		
	_nI++
	EndDo
	
	If _nTSaldDia >= 0
		_cCorPN := "#000000"
	Else
		_cCorPN := "#CD0000"
	EndIf
	
	//================================================================================
	// Imprime total do mes
	//================================================================================
	_cTxtHTM += '<tr>'
	_cTxtHTM += '  <td class="totais" width="20%" align="center">Total do mês ['+ _cMes +'/'+ _cAno +']</td>'
	_cTxtHTM += '  <td class="totais" width="12%" align="right" ><b>'+ Transform( _nTMesRec  , "@E 999,999,999,999.99" ) +'</b></td>'
	_cTxtHTM += '  <td class="totais" width="12%" align="right" ><b>'+ Transform( _nTMesPag  , "@E 999,999,999,999.99" ) +'</b></td>'
	_cTxtHTM += '  <td class="totais" width="12%" align="right" ><b>'+ Transform( _nTMesAdt  , "@E 999,999,999,999.99" ) +'</b></td>'
	_cTxtHTM += '  <td class="totais" width="16%" align="right" ><b><font color="'+ _cCorPN +'">'+ Transform( _nTSaldDia , "@E 999,999,999,999.99" ) +'</font></b></td>'
	_cTxtHTM += '  <td class="itens"  width="02%" align="center" bgcolor="#777777">&nbsp;</td>'
	_cTxtHTM += '  <td class="totais" width="12%" align="right" ><b>'+ Transform( _nTMesPrev , "@E 999,999,999,999.99" ) +'</b></td>'
	_cTxtHTM += '  <td class="itens"  width="02%" align="center" bgcolor="#777777">&nbsp;</td>'
	_cTxtHTM += '  <td class="totais" width="12%" align="right" ><b>'+ Transform( _nTMesPC   , "@E 999,999,999,999.99" ) +'</b></td>'
	_cTxtHTM += '</tr>'
	
	_nValAnt := 0
	
	If Month( Date() ) == Val(_cMes) .And. Day( Date() ) > 1
	
		MFIN006Q( 8 , _cAlias )
		
		DBSelectArea(_cAlias)
		(_cAlias)->( DBGoTop() )
		
		If (_cAlias)->( !Eof() )
			_nValAnt := (_cAlias)->VALOR
		EndIf
		
		(_cAlias)->( DBCloseArea() )
		
	EndIf
	
	_cTxtHTM += '<tr>'
	_cTxtHTM += '  <td class="totais" width="20%" align="center"><b>Baixas Anteriores no Mês</b></td>'
	_cTxtHTM += '  <td class="totais" width="12%" align="right" >&nbsp;</td>'
	_cTxtHTM += '  <td class="totais" width="12%" align="right" ><b>'+ Transform( _nValAnt , "@E 999,999,999,999.99" ) +'</b></td>'
	_cTxtHTM += '  <td class="totais" width="12%" align="right" >&nbsp;</td>'
	_cTxtHTM += '  <td class="totais" width="16%" align="right" >&nbsp;</td>'
	_cTxtHTM += '  <td class="itens"  width="02%" align="center" bgcolor="#777777">&nbsp;</td>'
	_cTxtHTM += '  <td class="totais" width="12%" align="right" >&nbsp;</td>'
	_cTxtHTM += '  <td class="itens"  width="02%" align="center" bgcolor="#777777">&nbsp;</td>'
	_cTxtHTM += '  <td class="totais" width="12%" align="right" >&nbsp;</td>'
	_cTxtHTM += '</tr>'
	
	_nValSum := _nValAnt + _nTMesPag + _nTMesAdt
	
	_cTxtHTM += '<tr>'
	_cTxtHTM += '  <td class="totais" width="20%" align="center"><b>Total Geral do Mês ['+ _cMes +'/'+ _cAno +']</b></td>'
	_cTxtHTM += '  <td class="totais" width="12%" align="right" >&nbsp;</td>'
	_cTxtHTM += '  <td class="totais" width="12%" align="right" ><b>'+ Transform( _nValSum , "@E 999,999,999,999.99" ) +'</b></td>'
	_cTxtHTM += '  <td class="totais" width="12%" align="right" >&nbsp;</td>'
	_cTxtHTM += '  <td class="totais" width="16%" align="right" >&nbsp;</td>'
	_cTxtHTM += '  <td class="itens"  width="02%" align="center" bgcolor="#777777">&nbsp;</td>'
	_cTxtHTM += '  <td class="totais" width="12%" align="right" >&nbsp;</td>'
	_cTxtHTM += '  <td class="itens"  width="02%" align="center" bgcolor="#777777">&nbsp;</td>'
	_cTxtHTM += '  <td class="totais" width="12%" align="right" >&nbsp;</td>'
	_cTxtHTM += '</tr>'
	
EndDo

If _nTSaldDia >= 0
	_cCorPN := "#000000"
Else
	_cCorPN := "#CD0000"
EndIf

//================================================================================
// Finaliza a tabela da secao CONTAS A RECEBER DIARIO
//================================================================================
_cTxtHTM += '<tr>'
_cTxtHTM += '  <td class="totais" width="20%" align="center"><b>Total Geral</b></td>'
_cTxtHTM += '  <td class="totais" width="12%" align="right" ><b>'+ Transform( _nTGerRec , "@E 999,999,999,999.99" ) +'</b></td>'
_cTxtHTM += '  <td class="totais" width="12%" align="right" ><b>'+ Transform( _nTGerPag + ( _nVencPag + _nPagPrev - _nPagNDF ) , "@E 999,999,999,999.99" ) +'</b></td>'
_cTxtHTM += '  <td class="totais" width="12%" align="right" ><b>'+ Transform( _nSldAdt , "@E 999,999,999,999.99" ) +'</b></td>'
_cTxtHTM += '  <td class="totais" width="16%" align="right" ><b><font color="'+ _cCorPN +'">' + Transform( _nTSaldDia , "@E 999,999,999,999.99" ) +'</font></b></td>'
_cTxtHTM += '  <td class="itens"  width="02%" align="center" bgcolor="#777777">&nbsp;</td>'
_cTxtHTM += '  <td class="totais" width="12%" align="right" ><b>'+ Transform( _nTGerPrev , "@E 999,999,999,999.99" ) +'</b></td>'
_cTxtHTM += '  <td class="itens"  width="02%" align="center" bgcolor="#777777">&nbsp;</td>'
_cTxtHTM += '  <td class="totais" width="12%" align="right" ><b>'+ Transform( _nTGerPC , "@E 999,999,999,999.99" ) +'</b></td>'
_cTxtHTM += '</tr>'
_cTxtHTM += '</table>'
_cTxtHTM += '<br>'

//======================================================================================
// Define a estrutura da segunda secao Posicao - Contas a Receber Vencidos - até 15 dias
//======================================================================================
_cTxtHTM += '<table class="bordasimples" cellpadding=2 cellspacing=0 width="100%">'
_cTxtHTM += '<tr><td align=center class="grupos"><b>Posição - Contas a Receber: Vencidos até 15 dias</b></td></tr>'
_cTxtHTM += '</table>'

_cTxtHTM += '<table class="bordasimples" cellpadding=0 cellspacing=0 width="100%">'
_cTxtHTM += '<tr>'
_cTxtHTM += '  <td class="itens" bgcolor="#D8D8D8" width="30%" align=center><b>Classificação</b></td>'
_cTxtHTM += '  <td class="itens" bgcolor="#D8D8D8" width="70%" align=center><b>Valor (R$)</b></td>'
_cTxtHTM += '</tr>'

//=====================================================================================
// Retornar as informacoes do quadro Posicao - Contas a Receber Vencidos - até 15 dias
//=====================================================================================
_cAliasRec := GetNextAlias()

MFIN006Q( 2 , _cAliasRec )

DBSelectArea(_cAliasRec)
(_cAliasRec)->( DBGoTop() )

While (_cAliasRec)->( !Eof() )
    
	If (_cAliasRec)->COD_CART = ' '
	
		_nVenc15	:=	(_cAliasRec)->VENC_15
	
		_cTxtHTM += '<tr>'
		_cTxtHTM += '  <td class="itens" bgcolor="#EEDD82" width="30%" align="LEFT" >Vencidos à Receber (Vencidos até 15 dias)</td>'
		_cTxtHTM += '  <td class="itens" bgcolor="#EEDD82" width="70%" align="RIGHT">'+ Transform( _nVenc15 , "@E 999,999,999,999.99" ) +'</td>'
		_cTxtHTM += '</tr>'
				
	EndIf

(_cAliasRec)->( DBSkip() )
EndDo

(_cAliasRec)->( DBCloseArea() )

//================================================================================
// Imprime totalizador. ate 15 dias
//================================================================================
_cTxtHTM += '<tr>'
_cTxtHTM += '  <td class="totais" width="30%" align="LEFT" >Total de Contas a Receber Vencidas - até 15 dias</td>'
_cTxtHTM += '  <td class="totais" width="70%" align="RIGHT">'+ Transform( _nVenc15 , "@E 999,999,999,999.99" ) +'</td>'//_cTxtHTM += '  <td class="totais" width="70%" align="RIGHT">'+ Transform( _nVenc15 + _nTC + _nVencDuv - _nNCC , "@E 999,999,999,999.99" ) +'</td>'
_cTxtHTM += '</tr>'

//================================================================================
// Finaliza a tabela da 2 secao POSICAO CONTAS A RECEBER
//================================================================================
_cTxtHTM += '</table>'
_cTxtHTM += '<br>'


//======================================================================================
// Define a estrutura da segunda secao Posicao - Contas a Receber Vencidos - até 5 anos  
//======================================================================================
_cTxtHTM += '<table class="bordasimples" cellpadding=2 cellspacing=0 width="100%">'
//_cTxtHTM += '<tr><td align=center class="grupos"><b>Posição - Contas a Receber: Vencidos até 60 dias</b></td></tr>' 
_cTxtHTM += '<tr><td align=center class="grupos"><b>Posição - Contas a Receber: Vencidos até 5 anos</b></td></tr>' 
_cTxtHTM += '</table>'

_cTxtHTM += '<table class="bordasimples" cellpadding=0 cellspacing=0 width="100%">'
_cTxtHTM += '<tr>'
_cTxtHTM += '  <td class="itens" bgcolor="#D8D8D8" width="30%" align=center><b>Classificação</b></td>'
_cTxtHTM += '  <td class="itens" bgcolor="#D8D8D8" width="70%" align=center><b>Valor (R$)</b></td>'
_cTxtHTM += '</tr>'

//=====================================================================================
// Retornar as informacoes do quadro Posicao - Contas a Receber Vencidos - até 5 anos  
//=====================================================================================
_cAliasRec := GetNextAlias()

MFIN006Q( 2 , _cAliasRec )

DBSelectArea(_cAliasRec)
(_cAliasRec)->( DBGoTop() )

While (_cAliasRec)->( !Eof() )
    
	If (_cAliasRec)->COD_CART = ' '
	
		_nVenc60	:=	(_cAliasRec)->VENC_60
		
		_cTxtHTM += '<tr>'
		_cTxtHTM += '  <td class="itens" bgcolor="#EEDD82" width="30%" align="LEFT" >Vencidos à Receber (Vencidos até 5 anos)</td>' 
		_cTxtHTM += '  <td class="itens" bgcolor="#EEDD82" width="70%" align="RIGHT">'+ Transform( _nVenc60 , "@E 999,999,999,999.99" ) +'</td>'
		_cTxtHTM += '</tr>'
		
	ElseIf (_cAliasRec)->COD_CART <> ' ' 
		
		_nTC := _nTC + (_cAliasRec)->CART_COB
		
		_cTxtHTM += '<tr>'
		_cTxtHTM += '  <td class="itens" bgcolor="#EEDD82" width="30%" align="LEFT" >'+ Capital( AllTrim( (_cAliasRec)->TIPO_CART ) ) +'</td>'
		_cTxtHTM += '  <td class="itens" bgcolor="#EEDD82" width="70%" align="RIGHT">'+ Transform( (_cAliasRec)->CART_COB , "@E 999,999,999,999.99" ) +'</td>'
		_cTxtHTM += '</tr>'
		
	EndIf

(_cAliasRec)->( DBSkip() )
EndDo

(_cAliasRec)->( DBCloseArea() )

//================================================================================
// Imprime totalizador. ate 5 anos 
//================================================================================
_cTxtHTM += '<tr>'
_cTxtHTM += '  <td class="totais" width="30%" align="LEFT" >Total de Contas a Receber Vencidas - até 5 anos</td>' 
_cTxtHTM += '  <td class="totais" width="70%" align="RIGHT">'+ Transform( _nVenc60 + _nTC , "@E 999,999,999,999.99" ) +'</td>'//_cTxtHTM += '  <td class="totais" width="70%" align="RIGHT">'+ Transform( _nVenc15 + _nTC + _nVencDuv - _nNCC , "@E 999,999,999,999.99" ) +'</td>'
_cTxtHTM += '</tr>'

//================================================================================
// Finaliza a tabela da 2 secao POSICAO CONTAS A RECEBER
//================================================================================
_cTxtHTM += '</table>'
_cTxtHTM += '<br>'



//================================================================================
// Define a estrutura da segunda secao Posicao - Contas a Pagar Vencidos
//================================================================================
_cTxtHTM += '<table class="bordasimples" cellpadding=2 cellspacing=0 width="100%">'
_cTxtHTM += '<tr><td align=center class="grupos"><b>Posição - Contas a Pagar: Vencidos (Até 30 dias)</b></td></tr>'
_cTxtHTM += '</table>'

_cTxtHTM += '<table class="bordasimples" cellpadding=0 cellspacing=0 width="100%">'
_cTxtHTM += '<tr>'
_cTxtHTM += '  <td class="itens" bgcolor="#D8D8D8" width="30%" align=center><b>Classificação</b></td>'
_cTxtHTM += '  <td class="itens" bgcolor="#D8D8D8" width="70%" align=center><b>Valor (R$)</b></td>'
_cTxtHTM += '</tr>'

//================================================================================
// Define a secao titulos vencidos - pagar
//================================================================================
_cTxtHTM += '<tr>'
_cTxtHTM += '  <td class="itens" bgcolor="#EEDD82" width="30%" align="LEFT" >Vencidos a pagar</td>'
_cTxtHTM += '  <td class="itens" bgcolor="#EEDD82" width="70%" align="RIGHT">'+ Transform( _nVencPag , "@E 999,999,999,999.99" ) +'</td>'
_cTxtHTM += '</tr>'

//================================================================================
// Define a secao titulos previstos a pagar
//================================================================================
_cTxtHTM += '<tr>'
_cTxtHTM += '  <td class="itens" bgcolor="#EEDD82" width="30%" align="LEFT" >Títulos previstos</td>'
_cTxtHTM += '  <td class="itens" bgcolor="#EEDD82" width="70%" align="RIGHT">'+ Transform( _nPagPrev , "@E 999,999,999,999.99" ) +'</td>'
_cTxtHTM += '</tr>'

//================================================================================
// Notas de Debito ao Fornecedor
//================================================================================
_cTxtHTM += '<tr>'
_cTxtHTM += '  <td class="itens" bgcolor="#EEDD82" width="30%" align="LEFT" >Notas de Débito ao Fornecedor (NDF)</td>'
_cTxtHTM += '  <td class="itens" bgcolor="#EEDD82" width="70%" align="RIGHT">'+ Transform( _nPagNDF , "@E 999,999,999,999.99" ) +'</td>'
_cTxtHTM += '</tr>'

//================================================================================
// Imprime totalizador
//================================================================================
_cTxtHTM += '<tr>'
_cTxtHTM += '  <td class="totais" width="30%" align="LEFT" >Total de Contas a Pagar Vencidas</td>'
_cTxtHTM += '  <td class="totais" width="70%" align="RIGHT">'+ Transform( _nVencPag + _nPagPrev - _nPagNDF , "@E 999,999,999,999.99" ) +'</td>'
_cTxtHTM += '</tr>'

//================================================================================
// Finaliza a tabela da 2 secao POSICAO CONTAS A RECEBER
//================================================================================
_cTxtHTM += '</table>'
_cTxtHTM += '<br>'

//================================================================================
// Define a secao titulos vencidos - pagar
//================================================================================
_cTxtHTM += '<tr>'                	
_cTxtHTM += '  <td class="itens" bgcolor="#EEDD82" width="30%" align="LEFT" >Vencidos a pagar</td>'
_cTxtHTM += '  <td class="itens" bgcolor="#EEDD82" width="70%" align="RIGHT">'+ Transform( _nVePagR , "@E 999,999,999,999.99" ) +'</td>'
_cTxtHTM += '</tr>'

//================================================================================
// Define a secao titulos previstos a pagar
//================================================================================
_cTxtHTM += '<tr>'
_cTxtHTM += '  <td class="itens" bgcolor="#EEDD82" width="30%" align="LEFT" >Títulos previstos</td>'
_cTxtHTM += '  <td class="itens" bgcolor="#EEDD82" width="70%" align="RIGHT">'+ Transform( _nPrevR , "@E 999,999,999,999.99" ) +'</td>'
_cTxtHTM += '</tr>'

//================================================================================
// Notas de Debito ao Fornecedor
//================================================================================
_cTxtHTM += '<tr>'
_cTxtHTM += '  <td class="itens" bgcolor="#EEDD82" width="30%" align="LEFT" >Notas de Débito ao Fornecedor (NDF)</td>'
_cTxtHTM += '  <td class="itens" bgcolor="#EEDD82" width="70%" align="RIGHT">'+ Transform( _nNDFR , "@E 999,999,999,999.99" ) +'</td>'
_cTxtHTM += '</tr>'

//================================================================================
// Imprime totalizador.
//================================================================================
_cTxtHTM += '<tr>'
_cTxtHTM += '  <td class="totais" width="30%" align="LEFT" >Total de Contas a Pagar Vencidas (Resíduos)</td>'
_cTxtHTM += '  <td class="totais" width="70%" align="RIGHT">'+ Transform( _nVePagR + _nPrevR - _nNDFR , "@E 999,999,999,999.99" ) +'</td>'
_cTxtHTM += '</tr>'

//================================================================================
// Finaliza a tabela da 2 secao POSICAO CONTAS A RECEBER
//================================================================================
_cTxtHTM += '</table>'
_cTxtHTM += '<br>'

//================================================================================
// Finaliza o HTML.
//================================================================================
_cTxtHTM += '</body>'
_cTxtHTM += '</html>'   

//================================================================================
// Caso nao tenha gerado erra na montagem do arquivo html gera o arquivo para
// posterior envio via e-mail.
//================================================================================
If _lRet

	//================================================================================
	// Cria o arquivo HTML na pasta spool da raiz do server.
	//================================================================================
	_cArqHtml	:= _cArqAnexo
	_nHdl		:= FCreate(_cArqHtml)
	
	If _nHdl == -1
		FWLogMsg("ERROR"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MFIN00603"/*cMsgId*/, "MFIN00603 - O arquivo de fluxo de caixa nome "+ _cArqHtml +" nao pode ser criado!"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		_lRet := .F.
	EndIf
	
	FWrite( _nHdl , _cTxtHTM , Len(_cTxtHTM) )
	FClose( _nHdl )
	
	//================================================================================
	// Caso nao tenho ocorrido erro na geracao do arquivo, sera enviado um e-mail
	// contendo o reusmo em HTML.
	//================================================================================
	If _lRet
	
		_cMsgEmail := "<B>Senhor Diretor<BR><BR>"
		_cMsgEmail += "Segue em anexo o Fluxo de Caixa ITALAC para acompanhamento.<BR><BR>"
		_cMsgEmail += "Favor não responder a este e-mail.</B><BR><BR>" + _cTxtHTM

		_cEmlLog := ""
			
	    U_ITENVMAIL( _aConfig[01] , _cEmailDes ,      ,          ,"FLUXO DE CAIXA ITALAC - GERADO EM: "+ _cGeracao,;
					 _cMsgEmail,_cArqAnexo,_aConfig[01],_aConfig[02], _aConfig[03],_aConfig[04], _aConfig[05], _aConfig[06],;
					_aConfig[07], @_cEmlLog )

	   FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MFIN00604"/*cMsgId*/, "MFIN00604 - "+_cEmlLog/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

		// ITEnvMail(cFrom        ,cEmailTo   ,cEmailCo,cEmailBcc,cAssunto,
		//           cMensagem ,cAttach    ,cAccount    ,cPassword   ,cServer      ,cPortCon    ,lRelauth     ,cUserAut,
		//          cPassAut,cLogErro,lExibeAmb)
	
			
		//================================================================================
		// Remove o arquivo criado após a finalizacao da tarefa de envio de e-mail.
		//================================================================================
		If FERASE(_cArqAnexo) == -1
		   FWLogMsg("ERROR"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MFIN00605"/*cMsgId*/, "MFIN00605 - Falha na deleção do Arquivo HTML"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		EndIf
	
	EndIf

EndIf

Return

/*
===============================================================================================================================
Programa--------: MFIN006Q
Autor-----------: Fabiano Dias da Silva
Data da Criacao-: 14/09/2011
Descrição-------: Funcao desenvolvida para realizar as consultas em banco de dados do fonte corrente.
                  Envia relatório HTML para destinatários cadastrados no configurador (ZZL).
Parametros------: _nOpcao - Define a query a ser executada
----------------: _cAlias - Define o Alias para montagem da área temporária
Retorno---------: _aDadVenc - Array com data de vencimento e valor médio.
===============================================================================================================================
*/
Static Function MFIN006Q( _nOpcao , _cAlias )

Local _aDadVenc	:= {}
Local _cQuery	:= ""
Local _cFiltro 	:= ""
Local _cFiltro2 := ""  
Local _cFiltro3 := ""  
Local _cFiltro4 := ""
Local _nDias	:= GETMV( "IT_QDIASFL" ,, 0 )
Local _nDiaAux	:= _nDias
Local _sDtInic  := DToS( Date() )
Local _dDtVenc	:= SToD('')
Local _nI		:= 0

_cFiltro	:= "% "
_cFiltro	+= " AND E1.E1_VENCREA BETWEEN '"+ DToS( Date() ) +"' AND '"+ DToS( Date() + _nDias ) +"' "
_cFiltro	+= " %"

_cFiltro2	:= "% "
_cFiltro2	+= " AND E2.E2_VENCREA BETWEEN '"+ DToS( Date() ) +"' AND '"+ DToS( Date() + _nDias ) +"' "
_cFiltro2	+= " %"

_cFiltro3	:= "% "
_cFiltro3	+= _sDtInic
_cFiltro3	+= " %"

If DOW( Date() ) == 1 //DOMINGO
	_nDias := "2"
ElseIf DOW( Date() ) == 2 //SEGUNDA
	_nDias := "3"
Else
   	_nDias := "1"
EndIf

_cFiltro4 := "% "
_cFiltro4 +=  _nDias
_cFiltro4 += " %"

Do Case

//================================================================================
// Query para selecionar e-mail's dos usuarios que sera enviado o resumo do HTML.
//================================================================================
Case _nOpcao == 1

	_cQuery := " SELECT "
	_cQuery +=     " DADOS.VENCIMENTO     VENCIMENTO, "
	_cQuery +=     " SUM(DADOS.SALDO_REC) SALDO_REC, "
	_cQuery +=     " SUM(DADOS.SALDO_PAG) SALDO_PAG, "
	_cQuery +=     " SUM(DADOS.VAL_ADT)   VAL_ADT, "
	_cQuery +=     " SUM(DADOS.PREV_CP)   PREV_CP "
	_cQuery += " FROM ( SELECT "
	_cQuery +=            " E1.E1_VENCREA VENCIMENTO , "
	_cQuery +=            " SUM( (E1.E1_SALDO+E1.E1_SDACRES) - E1.E1_SDDECRE ) - NVL( ( SELECT SUM( ( E11.E1_SALDO + E11.E1_SDACRES ) - E11.E1_SDDECRE ) "
	_cQuery +=                                                                        " FROM "+ RetSqlName('SE1') +" E11 "
	_cQuery +=                                                                        " WHERE "
	_cQuery +=                                                                            " E11.D_E_L_E_T_ = ' ' "
	_cQuery +=                                                                        " AND E11.E1_SALDO   > 0 "
	_cQuery +=                                                                        " AND E11.E1_TIPO    = 'NCC' "
	_cQuery +=                                                                        " AND E11.E1_VENCREA = E1.E1_VENCREA ) , 0 ) AS SALDO_REC, "
	_cQuery +=            " 0 AS VAL_ADT, "
	_cQuery +=            " 0 AS SALDO_PAG, "
	_cQuery +=            " 0 AS PREV_CP "
	_cQuery +=        " FROM "+ RetSqlName('SE1') +" E1 "
	_cQuery +=        " WHERE "
	_cQuery +=            " E1.D_E_L_E_T_ = ' ' "
	_cQuery +=        " AND E1.E1_SALDO   > 0 "
	_cQuery +=        " AND E1.E1_TIPO    NOT IN ('RA','NCC') "
	_cQuery +=        " AND E1.E1_VENCREA <> ' ' "
	_cQuery +=        " AND E1.E1_VENCREA BETWEEN '"+ DToS( Date() ) +"' AND '"+ DToS( Date() + _nDiaAux ) +"' "
	
	_cQuery +=        " GROUP BY E1.E1_VENCREA "
	
	_cQuery +=        " UNION ALL "
	
	_cQuery +=        " SELECT "
	_cQuery +=            " E2.E2_VENCREA, "
	_cQuery +=            " 0 AS SALDO_REC, "
	_cQuery +=            " ( NVL( ( SELECT SUM( VALLIQ.VALOR ) "
	_cQuery +=                     " FROM (	SELECT "
	_cQuery +=                                " SUM(SE5.E5_VALOR) AS VALOR "
	_cQuery +=                            " FROM  "+ RetSqlName('SE5') +" SE5 "
	_cQuery +=                            " WHERE "+ RetSqlDel('SE5')
	_cQuery +=                            " AND SE5.E5_DATA      =  E2.E2_VENCREA "
	_cQuery +=                            " AND SE5.E5_MOTBX     IN ( 'NOR' , 'DEB' ) "
	_cQuery +=                            " AND SE5.E5_CONTA     <> ' ' "
	_cQuery +=                            " AND SE5.E5_RECPAG    =  'P' "
	_cQuery +=                            " AND SE5.E5_TIPODOC   NOT IN ( 'DC' , 'ES' ) "
	_cQuery +=                            " AND SE5.E5_TIPODOC   NOT IN ('MT','JR','DC') "
	_cQuery +=                            " AND ( SE5.E5_TIPO    <> 'PA' OR ( SE5.E5_TIPO    = 'PA' AND SE5.E5_NUMERO <> ' ' ) ) "
	_cQuery +=                            " AND ( SE5.E5_TIPODOC <> 'PA' OR ( SE5.E5_TIPODOC = 'PA' AND SE5.E5_NUMERO <> ' ' ) ) "
	_cQuery +=                            " UNION ALL "
	_cQuery +=                            " SELECT "
	_cQuery +=                                " SUM(SE5.E5_VALOR) * -1 AS VALOR "
	_cQuery +=                            " FROM  "+ RetSqlName('SE5') +" SE5 "
	_cQuery +=                            " WHERE "+ RetSqlDel('SE5')
	_cQuery +=                            " AND SE5.E5_DATA    = E2.E2_VENCREA "
	_cQuery +=                            " AND SE5.E5_MOTBX   IN ( 'NOR' , 'DEB' ) "
	_cQuery +=                            " AND SE5.E5_CONTA   <> ' ' "
	_cQuery +=                            " AND SE5.E5_TIPODOC IN ('ES' ) "
	_cQuery +=                            " AND SE5.E5_FORNECE <> ' '  "
	_cQuery +=                            " AND SE5.E5_NUMERO  <> ' '  "
	_cQuery +=                            " AND SE5.E5_TIPODOC NOT IN ('MT','JR','DC') "
	_cQuery +=                            " AND ( SE5.E5_TIPO    <> 'PA' OR ( SE5.E5_TIPO    = 'PA' AND SE5.E5_NUMERO <> ' ' ) ) "
	_cQuery +=                            " AND ( SE5.E5_TIPODOC <> 'PA' OR ( SE5.E5_TIPODOC = 'PA' AND SE5.E5_NUMERO <> ' ' ) ) "
	_cQuery +=                     " ) VALLIQ ) , 0 ) ) AS VAL_ADT, "
	_cQuery +=            " SUM( ( E2.E2_SALDO + E2.E2_SDACRES ) - E2.E2_SDDECRE ) - NVL( (	SELECT SUM( ( E21.E2_SALDO + E21.E2_SDACRES ) - E21.E2_SDDECRE ) "
	_cQuery +=                                                                            " FROM  "+ RetSqlName('SE2') +" E21 "
	_cQuery +=                                                                            " WHERE "
	_cQuery +=                                                                                " E21.D_E_L_E_T_ = ' ' "
	_cQuery +=                                                                            " AND E21.E2_SALDO   > 0 "
	_cQuery +=                                                                            " AND E21.E2_TIPO    = 'NDF' "
	_cQuery +=                                                                            " AND E21.E2_VENCREA = E2.E2_VENCREA ) , 0 ) AS SALDO_PAG, "
	_cQuery +=            " NVL( ( SELECT SUM( ( E22.E2_SALDO + E22.E2_SDACRES ) - E22.E2_SDDECRE ) "
	_cQuery +=                   " FROM  "+ RetSqlName('SE2') +" E22 "
	_cQuery +=                   " WHERE "
	_cQuery +=                       " E22.D_E_L_E_T_ = ' ' "
	_cQuery +=                   " AND E22.E2_SALDO   > 0 "
	_cQuery +=                   " AND E22.E2_TIPO    = 'PR' "
	_cQuery +=                   " AND E22.E2_VENCREA = E2.E2_VENCREA ) , 0 ) AS PREV_CP "
	_cQuery +=        " FROM "+ RetSqlName('SE2') +" E2 "
	_cQuery +=        " WHERE "
	_cQuery +=            " E2.D_E_L_E_T_ = ' ' "
	_cQuery +=        " AND E2.E2_SALDO   > 0 "
	_cQuery +=        " AND E2.E2_TIPO    NOT IN ('PA','NDF') "
	_cQuery +=        " AND E2.E2_VENCREA <> ' ' "
	_cQuery +=        " AND E2.E2_VENCREA BETWEEN '"+ DToS( Date() ) +"' AND '"+ DToS( Date() + _nDiaAux ) +"' "
	
	_cQuery +=        " GROUP BY E2.E2_VENCREA "
	
	_cQuery += " ) DADOS "
	
	_cQuery += " GROUP BY DADOS.VENCIMENTO "
	_cQuery += " ORDER BY DADOS.VENCIMENTO "
	
	If Select(_cAlias) > 0
		(_cAlias)->( DBCloseArea() )
	EndIf
	
	DBUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQuery ) , _cAlias , .T., .F. )

//================================================================================
// Query da consulta do quadro de Contas a Receber - Titulos vencidos ate 15 dias
//================================================================================
Case _nOpcao == 2
	
	BeginSql alias _cAlias
	
		SELECT  E1.E1_I_CART AS COD_CART,
				NVL((SELECT ZAR.ZAR_DESC FROM %Table:ZAR% ZAR WHERE ZAR.D_E_L_E_T_ = ' ' AND ZAR.ZAR_COD = E1.E1_I_CART),'SEM TIPO') TIPO_CART,
				SUM((Case WHEN (TO_DATE(%Exp:_cFiltro3%,'YYYY/MM/DD') - TO_DATE(E1.E1_VENCREA,'YYYY/MM/DD') > %Exp:_cFiltro4% AND TO_DATE(%Exp:_cFiltro3%,'YYYY/MM/DD') - TO_DATE(E1.E1_VENCREA,'YYYY/MM/DD') <=1825 AND E1.E1_TIPO <> 'NCC' AND E1.E1_I_CART <> ' ') THEN ((E1.E1_SALDO+E1.E1_SDACRES)-E1.E1_SDDECRE) Else 0 END)) AS CART_COB, // SUM((Case WHEN (TO_DATE(%Exp:_cFiltro3%,'YYYY/MM/DD') - TO_DATE(E1.E1_VENCREA,'YYYY/MM/DD') > %Exp:_cFiltro4% AND TO_DATE(%Exp:_cFiltro3%,'YYYY/MM/DD') - TO_DATE(E1.E1_VENCREA,'YYYY/MM/DD') <=60 AND E1.E1_TIPO <> 'NCC' AND E1.E1_I_CART <> ' ') THEN ((E1.E1_SALDO+E1.E1_SDACRES)-E1.E1_SDDECRE) Else 0 END)) AS CART_COB,
				SUM((Case WHEN (TO_DATE(%Exp:_cFiltro3%,'YYYY/MM/DD') - TO_DATE(E1.E1_VENCREA,'YYYY/MM/DD') > %Exp:_cFiltro4% AND TO_DATE(%Exp:_cFiltro3%,'YYYY/MM/DD') - TO_DATE(E1.E1_VENCREA,'YYYY/MM/DD') <=15 AND E1.E1_TIPO <> 'NCC' AND E1.E1_I_CART = ' ') THEN ((E1.E1_SALDO+E1.E1_SDACRES)-E1.E1_SDDECRE) Else 0 END)) AS VENC_15,
				SUM((Case WHEN (TO_DATE(%Exp:_cFiltro3%,'YYYY/MM/DD') - TO_DATE(E1.E1_VENCREA,'YYYY/MM/DD') > %Exp:_cFiltro4% AND TO_DATE(%Exp:_cFiltro3%,'YYYY/MM/DD') - TO_DATE(E1.E1_VENCREA,'YYYY/MM/DD') <=1825 AND E1.E1_TIPO <> 'NCC' AND E1.E1_I_CART = ' ') THEN ((E1.E1_SALDO+E1.E1_SDACRES)-E1.E1_SDDECRE) Else 0 END)) AS VENC_60, // SUM((Case WHEN (TO_DATE(%Exp:_cFiltro3%,'YYYY/MM/DD') - TO_DATE(E1.E1_VENCREA,'YYYY/MM/DD') > %Exp:_cFiltro4% AND TO_DATE(%Exp:_cFiltro3%,'YYYY/MM/DD') - TO_DATE(E1.E1_VENCREA,'YYYY/MM/DD') <=60 AND E1.E1_TIPO <> 'NCC' AND E1.E1_I_CART = ' ') THEN ((E1.E1_SALDO+E1.E1_SDACRES)-E1.E1_SDDECRE) Else 0 END)) AS VENC_60, 
				SUM((Case WHEN E1.E1_TIPO = 'NCC' THEN E1.E1_SALDO Else 0 END)) AS REC_NCC
		FROM %Table:SE1% E1
		WHERE
			E1.D_E_L_E_T_ = ' '
		AND E1.E1_SALDO   > 0 
		AND E1.E1_TIPO    <> 'RA'
		AND E1.E1_VENCREA <> ' '
		
		GROUP BY E1.E1_I_CART
		ORDER BY E1.E1_I_CART
	
	EndSql

//================================================================================
// Query para realizar o consulta do Fluxo Contas a Pagar
//================================================================================
Case _nOpcao == 3

	BeginSql alias _cAlias
	
    	SELECT	SUM((Case WHEN (TO_DATE(%Exp:_cFiltro3%,'YYYY/MM/DD') > TO_DATE(E2.E2_VENCREA,'YYYY/MM/DD') AND TO_DATE(%Exp:_cFiltro3%,'YYYY/MM/DD') - TO_DATE(E2.E2_VENCREA,'YYYY/MM/DD') <=30 AND E2.E2_TIPO NOT IN ('NDF','PR') ) THEN ((E2.E2_SALDO+E2.E2_SDACRES) - E2.E2_SDDECRE) Else 0 END)) AS VENC_PAG,
				SUM((Case WHEN (TO_DATE(%Exp:_cFiltro3%,'YYYY/MM/DD') > TO_DATE(E2.E2_VENCREA,'YYYY/MM/DD') AND TO_DATE(%Exp:_cFiltro3%,'YYYY/MM/DD') - TO_DATE(E2.E2_VENCREA,'YYYY/MM/DD') <=30 AND E2.E2_TIPO = 'NDF') THEN ((E2.E2_SALDO+E2.E2_SDACRES) - E2.E2_SDDECRE) Else 0 END)) AS PAG_NDF,
				SUM((Case WHEN (TO_DATE(%Exp:_cFiltro3%,'YYYY/MM/DD') > TO_DATE(E2.E2_VENCREA,'YYYY/MM/DD') AND TO_DATE(%Exp:_cFiltro3%,'YYYY/MM/DD') - TO_DATE(E2.E2_VENCREA,'YYYY/MM/DD') <=30 AND E2.E2_TIPO = 'PR') THEN ((E2.E2_SALDO+E2.E2_SDACRES) - E2.E2_SDDECRE) Else 0 END)) AS PAG_PREV
		FROM %Table:SE2% E2
		WHERE
			E2.D_E_L_E_T_ = ' '
		AND E2.E2_TIPO    <> 'PA'
		AND E2.E2_SALDO   > 0
		AND E2.E2_VENCREA <> ' '
	
	EndSql

Case _nOpcao == 4

	BeginSql alias _cAlias
	
		SELECT	SUM(E8.E8_SALATUA) SLD_ATUAL
		FROM	%Table:SE8% E8
		JOIN	%Table:SA6% A6 ON A6.A6_COD = E8.E8_BANCO AND A6.A6_AGENCIA = E8.E8_AGENCIA AND A6.A6_NUMCON = E8.E8_CONTA
		WHERE
		    E8.D_E_L_E_T_ = ' '
		AND A6.D_E_L_E_T_ = ' '
		AND E8.E8_DTSALAT = (	SELECT	MAX(E8D.E8_DTSALAT)
								FROM	%Table:SE8% E8D
								WHERE
									E8D.D_E_L_E_T_ = ' ' 
								AND E8D.E8_FILIAL  = E8.E8_FILIAL
								AND E8D.E8_BANCO   = E8.E8_BANCO
								AND E8D.E8_AGENCIA = E8.E8_AGENCIA
								AND E8D.E8_CONTA   = E8.E8_CONTA )
		AND A6.A6_FLUXCAI = 'S'
		AND A6.A6_BLOCKED <> '1'
	
	EndSql

Case _nOpcao == 5

	BeginSql alias _cAlias
	
		SELECT	zzl_email
		FROM	%Table:ZZL%
		WHERE
			d_e_l_e_t_ = ' '
		AND ZZL_ENVFL2 = 'S'
		
	EndSql

//================================================================================
// Query para realizar o consulta do Contas a Pagar - Residuo
//================================================================================
Case _nOpcao == 6

	BeginSql alias _cAlias
	
		SELECT	SUM((Case WHEN (TO_DATE(%Exp:_cFiltro3%,'YYYY/MM/DD') > TO_DATE(E2.E2_VENCREA,'YYYY/MM/DD') AND TO_DATE(%Exp:_cFiltro3%,'YYYY/MM/DD') - TO_DATE(E2.E2_VENCREA,'YYYY/MM/DD') >30 AND E2.E2_TIPO NOT IN ('NDF','PR') ) THEN ((E2.E2_SALDO+E2.E2_SDACRES) - E2.E2_SDDECRE) Else 0 END)) AS VENC_PAGR,
				SUM((Case WHEN (TO_DATE(%Exp:_cFiltro3%,'YYYY/MM/DD') > TO_DATE(E2.E2_VENCREA,'YYYY/MM/DD') AND TO_DATE(%Exp:_cFiltro3%,'YYYY/MM/DD') - TO_DATE(E2.E2_VENCREA,'YYYY/MM/DD') >30 AND E2.E2_TIPO = 'NDF') THEN ((E2.E2_SALDO+E2.E2_SDACRES) - E2.E2_SDDECRE) Else 0 END)) AS PAG_NDFR,
				SUM((Case WHEN (TO_DATE(%Exp:_cFiltro3%,'YYYY/MM/DD') > TO_DATE(E2.E2_VENCREA,'YYYY/MM/DD') AND TO_DATE(%Exp:_cFiltro3%,'YYYY/MM/DD') - TO_DATE(E2.E2_VENCREA,'YYYY/MM/DD') >30 AND E2.E2_TIPO = 'PR') THEN ((E2.E2_SALDO+E2.E2_SDACRES) - E2.E2_SDDECRE) Else 0 END)) AS PAG_PREVR
		FROM	%Table:SE2% E2
		WHERE
			E2.D_E_L_E_T_ = ' '
		AND E2.E2_TIPO    <> 'PA'
		AND E2.E2_SALDO   > 0
		AND E2.E2_VENCREA <> ' '
		
	EndSql

//================================================================================
// Query para realizar o consulta do Contas a Receber - Vencidos de 1, 2 ou dias 
// dependendo do dia atual Domingo (vai pegar 2 de vencido), Segunda(vai pegar 3 
// dias de Vencido), Outros Dias (1 dia de Vencido)
//================================================================================
Case _nOpcao == 7

	BeginSql alias _cAlias

		SELECT	SUM((Case WHEN (TO_DATE(%Exp:_cFiltro3%,'YYYY/MM/DD') - TO_DATE(E1.E1_VENCREA,'YYYY/MM/DD') > 0  AND TO_DATE(%Exp:_cFiltro3%,'YYYY/MM/DD') - TO_DATE(E1.E1_VENCREA,'YYYY/MM/DD') <= %Exp:_cFiltro4% AND E1.E1_TIPO <> 'NCC' AND E1.E1_I_CART = ' ') THEN ((E1.E1_SALDO+E1.E1_SDACRES)-E1.E1_SDDECRE) Else 0 END)) AS VREC_D1,
				SUM((Case WHEN (TO_DATE(%Exp:_cFiltro3%,'YYYY/MM/DD') - TO_DATE(E1.E1_VENCREA,'YYYY/MM/DD') > 0  AND TO_DATE(%Exp:_cFiltro3%,'YYYY/MM/DD') - TO_DATE(E1.E1_VENCREA,'YYYY/MM/DD') <= %Exp:_cFiltro4% AND E1.E1_TIPO = 'NCC') THEN ((E1.E1_SALDO+E1.E1_SDACRES)-E1.E1_SDDECRE) Else 0 END)) AS NCC_D1
		FROM	%Table:SE1% E1
		WHERE
			E1.D_E_L_E_T_ = ' '
		AND E1.E1_SALDO   > 0 
		AND E1.E1_TIPO    <> 'RA'
		AND E1.E1_VENCREA <> ' '
		
	EndSql

Case _nOpcao == 8
    
   	_cQuery := " SELECT SUM( DADOS.VALOR ) AS VALOR "
	_cQuery += " FROM ( "
	
		_cQuery += " SELECT
		_cQuery += "     SUM(SE5.E5_VALOR) AS VALOR
		_cQuery += " FROM  "+ RetSqlName('SE5') +" SE5
		_cQuery += " WHERE "+ RetSqlDel('SE5')
		_cQuery += " AND SE5.E5_DATA    BETWEEN '"+ SubStr( DToS( Date() ) , 1 , 6 ) +"01' AND '"+ DToS( DaySub( Date() , 1 ) ) +"' "
		_cQuery += " AND SE5.E5_MOTBX   IN ( 'NOR' , 'DEB' ) "
		_cQuery += " AND SE5.E5_CONTA   <> ' ' "
		_cQuery += " AND SE5.E5_RECPAG  = 'P' "
		_cQuery += " AND SE5.E5_TIPODOC NOT IN ( 'DC' , 'ES' ) "
		_cQuery += " AND SE5.E5_TIPODOC NOT IN ('MT','JR','DC') "
		_cQuery += " AND ( SE5.E5_TIPO    <> 'PA' OR ( SE5.E5_TIPO    = 'PA' AND SE5.E5_NUMERO <> ' ' ) ) "
		_cQuery += " AND ( SE5.E5_TIPODOC <> 'PA' OR ( SE5.E5_TIPODOC = 'PA' AND SE5.E5_NUMERO <> ' ' ) ) "
		
		_cQuery += " UNION ALL
		
		_cQuery += " SELECT
		_cQuery += "    SUM(SE5.E5_VALOR) * -1 AS VALOR
		_cQuery += " FROM  "+ RetSqlName('SE5') +" SE5
		_cQuery += " WHERE "+ RetSqlDel('SE5')
		_cQuery += " AND SE5.E5_DATA    BETWEEN '"+ SubStr( DToS( Date() ) , 1 , 6 ) +"01' AND '"+ DToS( DaySub( Date() , 1 ) ) +"' "
		_cQuery += " AND SE5.E5_MOTBX   IN ( 'NOR' , 'DEB' ) "
		_cQuery += " AND SE5.E5_CONTA   <> ' ' "
		_cQuery += " AND SE5.E5_TIPODOC IN ('ES' ) "
		_cQuery += " AND SE5.E5_FORNECE <> ' ' "
		_cQuery += " AND SE5.E5_NUMERO  <> ' ' "
		_cQuery += " AND SE5.E5_TIPODOC NOT IN ('MT','JR','DC') "
		_cQuery += " AND ( SE5.E5_TIPO    <> 'PA' OR ( SE5.E5_TIPO    = 'PA' AND SE5.E5_NUMERO <> ' ' ) ) "
		_cQuery += " AND ( SE5.E5_TIPODOC <> 'PA' OR ( SE5.E5_TIPODOC = 'PA' AND SE5.E5_NUMERO <> ' ' ) ) "
	
	_cQuery += " ) DADOS
    
    If Select(_cAlias) > 0
		(_cAlias)->( DBCloseArea() )
	EndIf
	
	DBUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQuery ) , _cAlias , .T., .F. )

Case _nOpcao == 9
                        
	_nValPC := 0
	
	_cQuery := " SELECT "
    _cQuery += "     SC7.C7_FILIAL , "
	_cQuery += "     SC7.C7_I_DTFAT, "
    _cQuery += "     SC7.C7_COND   , "
    _cQuery += "     SC7.C7_QUANT  , "
    _cQuery += "     SC7.C7_QUANT - SC7.C7_QUJE AS SALDO, "
    _cQuery += "     SC7.C7_PRECO  , "
    _cQuery += "     ( ( ( SC7.C7_PRECO * SC7.C7_QUANT ) - SC7.C7_VLDESC ) / SC7.C7_QUANT ) * ( SC7.C7_QUANT - SC7.C7_QUJE ) AS TOTAL "
    _cQuery += " FROM "+ RetSqlName('SC7') +" SC7 "
    _cQuery += " WHERE "
    _cQuery += "     SC7.D_E_L_E_T_ = ' ' "
    _cQuery += " AND SC7.C7_QUJE    < SC7.C7_QUANT "
    _cQuery += " AND SC7.C7_RESIDUO <> 'S' "
    _cQuery += " AND SC7.C7_CONAPRO = 'L' "
    _cQuery += " AND SC7.C7_I_DTFAT <> '  ' "
    _cQuery += " ORDER BY SC7.C7_FILIAL, SC7.C7_I_DTFAT, SC7.C7_COND "
	
	If Select(_cAlias) > 0
		(_cAlias)->( DBCloseArea() )
	EndIf
	
	DBUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQuery ) , _cAlias , .T., .F. )
	
	(_cAlias)->( DBGoTop() )
	While (_cAlias)->( !Eof() )
		
		_dDtEmis	:= SToD( (_cAlias)->C7_I_DTFAT )
		_aCond		:= Condicao( (_cAlias)->TOTAL , (_cAlias)->C7_COND , 0 , _dDtEmis )
		
		For _nI := 1 To Len( _aCond )
			
			_dDtVenc := DataValida( _aCond[_nI][01] )
			aAdd( _aDadVenc , { _dDtVenc , Round( (_cAlias)->Total / Len(_aCond) , 2 ) } )
			
		Next _nI
		
	(_cAlias)->( DBSkip() )
	EndDo
	
	(_cAlias)->( DBCloseArea() )
	
	_aDadVenc := aSort( _aDadVenc ,,, {|x,y| x[01] < y[01] } )
	
EndCase

Return( _aDadVenc )

/*
===============================================================================================================================
Programa--------: MFIN006M
Autor-----------: Alexandre Villar
Data da Criacao-: 07/08/2015
Descrição-------: Funcao desenvolvida para chamar o processamento do WF manualmente via Menu - Chamado 11286.
                  Envia relatório para destinatários cadastrados no configurador (ZZL) com chamada via Menu.
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function MFIN006M()

Local _xAcesso	:= U_ITACSUSR( "ZZL_WFFLCX" , "S" )

//====================================================================================================
// Verifica se o usuário tem permissão para rodar o WF
//====================================================================================================
If ValType( _xAcesso ) == 'N' .And. _xAcesso == 0
	U_ITMsg( 'Usuário não está cadastrado na Gestão de Usuários do Configurador Italac!'	, 'Atenção!' , ,1)
	Return
ElseIf !_xAcesso
	U_ITMsg(  'Usuário sem acesso à rotina de execução manual do WF do Fluxo de Caixa!'	, 'Atenção!',,1)
	Return
EndIf

//====================================================================================================
// Verifica e inicia o processamento do WF
//====================================================================================================
If U_ITMsg( 'Essa rotina irá processar o relatório do WF de Fluxo de Caixa diário e enviar à todos os destinatários automaticamente! Deseja solicitar o processamento do WF de Fluxo de Caixa diário?' , 'Atenção!',,2,2,2 )

	FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MFIN00606"/*cMsgId*/, "MFIN00606 - Chamada da execução do JOB. Usuário - "+ RetCodUsr() +" / "+ UsrFullName( RetCodUsr() )/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	StartJob( "U_MFIN006" , GetEnvServer() , .F. )
	
	U_ITMsg(	'Foi feita a solicitação para o processamento do WF, o mesmo será processado e enviará automaticamente as mensagens aos destinatários conforme configuração! ' ,"Atenção",;
				'Aguarde o processamento do WF, no caso de não receber, entre em contato com a área de TI/Sistema.' ,2)
	
EndIf

Return
