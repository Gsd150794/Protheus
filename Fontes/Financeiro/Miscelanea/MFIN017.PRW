/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |13/10/2024| Chamado 48465. Retirada da função de conout
Lucas Borges  |23/07/2025| Chamado 51340. Trocado e-mail padrão para sistema@italac.com.br
Lucas Borges  |22/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MFIN017
Autor-------------: Igor Melgaço
Data da Criacao---: 15/04/2021
Descrição---------: Workflow relação de Titulos a Receber com 10 dias ou mais de Atraso no Pagto Chamado 36275
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MFIN017

Local nI         := 0
Local _aParRet   := {}
Local _aParAux   := {}
Local _bOK       := {|| .T. }
Local _cTimeIni  := Time()
Local _lRet      := .F.

Private _lTela   := .T.

//Testa se esta sendo rodado do menu
If Select('SX3') == 0
	
	RPCSetType( 3 )					//Não consome licensa de uso
		
	RpcSetEnv('01','01',,,,GetEnvServer(),{ "SA3","SE1" })
	sleep( 5000 )					//Aguarda 5 segundos para que as jobs IPC subam.
		
	MV_PAR01 := SuperGetMV( 'IT_DTWI017',.F.,dDatabase ) 
	MV_PAR02 := SuperGetMV( 'IT_DTWF017',.F.,SToD('20210401') )
	
	_lTela := .F.

Else

	MV_PAR01 := SuperGetMV('IT_DTWI017',.F.,dDatabase ) 
	MV_PAR02 := SuperGetMV('IT_DTWF017',.F.,SToD('20210401') )

	aAdd( _aParAux , {1,"Data atual:"		  ,MV_PAR01,"@E","","","",50,.F.} )
	aAdd( _aParAux , {1,"Emissão a partir de:",MV_PAR02,"@E","","","",50,.F.} )

	For nI := 1 To Len( _aParAux )
			aAdd( _aParRet , _aParAux[nI][03] )
	Next nI
	
	If !ParamBox( _aParAux , "Seleção de filtros [MFIN017]" , @_aParRet, _bOK )
		Return .F.
	EndIf
EndIf

If _lTela
	
	FWMsgRun( ,{|oProc|  _lRet := MFIN017EM(oProc) } , "Hora Inicial: "+_cTimeIni+" Lendo Títulos a partir de: "+DToC(MV_PAR02))

Else
	//Atualização tabela SM2
	FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MFIN017"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MFIN01701"/*cMsgId*/, "MFIN01701 - Início do Processamento"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	_lRet := MFIN017EM()
	FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MFIN017"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MFIN01702"/*cMsgId*/, "MFIN01702 - Fim do Processamento"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)	
	RpcClearEnv() //Libera o Ambiente

EndIf

Return _lRet


/*
===============================================================================================================================
Programa----------: MFIN017EM
Autor-------------: Igor Melgaço
Data da Criacao---: 15/04/2021
Descrição---------: Rotina de envio do email
Parametros--------: oProc = objeto da barra de processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MFIN017EM(oProc)

Local _aConfig	  := {}
Local _cEmlLog	  := ""
Local _cMsgEml	  := ""
Local _cGetLista := ""
Local _aCab      := {}
Local _aSizes    := {}
Local cGetCc	  := ""
Local cGetPara	  := ""
Local cGetAssun  := "Títulos à receber vencidos anteriores a "+If( _lTela,DToC(MV_PAR01),DToC(SToD(Subs(DToS(MV_PAR01),1,6)+"01")))+". "
Local _cTit      := " "
Local _aVend     := {}
Local _nCont     := 0
Local _aTit      := {}
Local _nTit      := 0
Local _nContTit  := 0
Local _nTotalTit := 0

//           01       02        03     04       05        06        07             08     09         10             11      12            13       14    15
_aSizes := {"02"    ,"02"     ,"02"  ,"08"    ,"03"     ,"04"     ,"05"          ,"05"  ,"15"      ,"20"          ,"10"     ,"04"         ,"04"    ,"03" ,"13"}
_aCab   := {"Filial","Prefixo","Tipo","Numero","Parcela","Emissão","Cod. Cliente","Loja","Fantasia","Razão Social","Vlr Original","Vencto","Cidade","UF","Historico"} 

If oProc <> Nil
	oProc:cCaption := ("Lendo Vendedores...")
	ProcessMessages()
EndIf

_aVend := MFIN017BRO() // 

For _nCont := 1 to Len(_aVend)
	
	_cTit    := "Vendedor: " + _aVend[_nCont][1] + " - " + _aVend[_nCont][2] + "  e-mail: " + _aVend[_nCont][3] 
	cGetPara := _aVend[_nCont][3]
	cGetCC   := _aVend[_nCont][4]

	//Logo Italac
	_cMsgEml := '<html>'
	_cMsgEml += '<head><title>'+_cTit+'</title></head>'
	_cMsgEml += '<body>'
	_cMsgEml += '<style Type="text/css"><!--'
	_cMsgEml += 'table.bordasimples { border-collapse: collapse; }'
	_cMsgEml += 'table.bordasimples tr td { border:1px solid #777777; }'
	_cMsgEml += 'td.titulos	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #C6E2FF; }'
	_cMsgEml += 'td.grupos	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #E5E5E5; }'
	_cMsgEml += 'td.itens	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #FFFFFF; }'
	_cMsgEml += '--></style>'
	_cMsgEml += '<center>'
	_cMsgEml += '<img src="http://www.italac.com.br/wf/italac-wf.jpg" width="600" height="50"><br>'
	_cMsgEml += '<br>'
	//Celula Azul para Título
	_cMsgEml += '<table class="bordasimples" width="600">'
	_cMsgEml += '    <tr>'
	_cMsgEml += '	     <td class="titulos"><center>'+_cTit+'</center></td>'
	_cMsgEml += '	 </tr>'
	_cMsgEml += '</table>'
	_cMsgEml += '<br>'

	If oProc <> Nil
		oProc:cCaption := ("Lendo títulos do vendedor "+_aVend[_nCont][2])
		ProcessMessages()
	EndIf

	_aTit      := {}
	_aTit      := MFIN017QRY(_aSizes,_aVend[_nCont][1])
	_nTit      := Len(_aTit)
	_nTotalTit := 0
	_cGetLista := ""

	If _nTit > 0
			
		//Cabeçalho
		_cMsgEml += '<br>'
		_cMsgEml += '<table class="bordasimples" width="1300">'
		_cMsgEml += '    <tr>'
		_cMsgEml += '		<td align="center" colspan="'+AllTrim(Str(Len(_aSizes)))+'" class="grupos"><b>'+cGetAssun+'</b></td>'
		_cMsgEml += '    </tr>'
		_cMsgEml += '    <tr>'
		_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[07]+'%"><b>'+_aCab[07]+'</b></td>'
		_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[08]+'%"><b>'+_aCab[08]+'</b></td>'
		_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[09]+'%"><b>'+_aCab[09]+'</b></td>'
		_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[10]+'%"><b>'+_aCab[10]+'</b></td>'
		_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[13]+'%"><b>'+_aCab[13]+'</b></td>'
		_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[14]+'%"><b>'+_aCab[14]+'</b></td>'
		_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[01]+'%"><b>'+_aCab[01]+'</b></td>'
		_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[02]+'%"><b>'+_aCab[02]+'</b></td>'
		_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[03]+'%"><b>'+_aCab[03]+'</b></td>'
		_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[04]+'%"><b>'+_aCab[04]+'</b></td>'
		_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[05]+'%"><b>'+_aCab[05]+'</b></td>'
		_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[06]+'%"><b>'+_aCab[06]+'</b></td>'
		_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[11]+'%"><b>'+_aCab[11]+'</b></td>'
		_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[12]+'%"><b>'+_aCab[12]+'</b></td>'
		_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[15]+'%"><b>'+_aCab[15]+'</b></td>'
		_cMsgEml += '    </tr>'
		_cMsgEml += '    #LISTA#'
		_cMsgEml += '</table>'

		For _nContTit := 1 To _nTit
			
			_cGetLista += '    <tr>'
			_cGetLista += '      <td class="itens" align="left"   width="'+_aSizes[07]+'%">'+ _aTit[_nContTit][07] +'</td>' 
			_cGetLista += '      <td class="itens" align="left"   width="'+_aSizes[08]+'%">'+ _aTit[_nContTit][08] +'</td>' 
			_cGetLista += '      <td class="itens" align="left"   width="'+_aSizes[09]+'%">'+ _aTit[_nContTit][09] +'</td>' 
			_cGetLista += '      <td class="itens" align="left"   width="'+_aSizes[10]+'%">'+ _aTit[_nContTit][10] +'</td>'
			_cGetLista += '      <td class="itens" align="left"   width="'+_aSizes[13]+'%">'+ _aTit[_nContTit][13] +'</td>'
			_cGetLista += '      <td class="itens" align="left"   width="'+_aSizes[14]+'%">'+ _aTit[_nContTit][14] +'</td>'
			_cGetLista += '      <td class="itens" align="center" width="'+_aSizes[01]+'%">'+ _aTit[_nContTit][01] +'</td>' 
			_cGetLista += '      <td class="itens" align="center" width="'+_aSizes[02]+'%">'+ _aTit[_nContTit][02] +'</td>' 
			_cGetLista += '      <td class="itens" align="left"   width="'+_aSizes[03]+'%">'+ _aTit[_nContTit][03] +'</td>' 
			_cGetLista += '      <td class="itens" align="left"   width="'+_aSizes[04]+'%">'+ _aTit[_nContTit][04] +'</td>' 
			_cGetLista += '      <td class="itens" align="left"   width="'+_aSizes[05]+'%">'+ _aTit[_nContTit][05] +'</td>' 
			_cGetLista += '      <td class="itens" align="left"   width="'+_aSizes[06]+'%">'+ _aTit[_nContTit][06] +'</td>'
			_cGetLista += '      <td class="itens" align="right"  width="'+_aSizes[11]+'%">'+ AllTrim(Transform( _aTit[_nContTit][11],"@E 999,999,999,999.99")) +'</td>' 
			_cGetLista += '      <td class="itens" align="left"   width="'+_aSizes[12]+'%">'+ _aTit[_nContTit][12] +'</td>' 
			_cGetLista += '      <td class="itens" align="left"   width="'+_aSizes[15]+'%">'+ _aTit[_nContTit][15] +'</td>'
			_cGetLista += '    </tr>'
			
			_nTotalTit := _nTotalTit + _aTit[_nContTit][11]

		Next

		//Adicionando o Total
		_cGetLista += '    <tr>'
		_cGetLista += '      <td class="itens" align="left"   width="'+_aSizes[07]+'%">'+ "" +'</td>' 
		_cGetLista += '      <td class="itens" align="left"   width="'+_aSizes[08]+'%">'+ "" +'</td>' 
		_cGetLista += '      <td class="itens" align="left"   width="'+_aSizes[09]+'%">'+ "" +'</td>' 
		_cGetLista += '      <td class="itens" align="left"   width="'+_aSizes[10]+'%">'+ "" +'</td>'
		_cGetLista += '      <td class="itens" align="left"   width="'+_aSizes[13]+'%">'+ "" +'</td>'
		_cGetLista += '      <td class="itens" align="left"   width="'+_aSizes[14]+'%">'+ "" +'</td>'
		_cGetLista += '      <td class="itens" align="center" width="'+_aSizes[01]+'%">'+ "" +'</td>' 
		_cGetLista += '      <td class="itens" align="center" width="'+_aSizes[02]+'%">'+ "" +'</td>' 
		_cGetLista += '      <td class="itens" align="left"   width="'+_aSizes[03]+'%">'+ "" +'</td>' 
		_cGetLista += '      <td class="itens" align="left"   width="'+_aSizes[04]+'%">'+ "" +'</td>' 
		_cGetLista += '      <td class="itens" align="left"   width="'+_aSizes[05]+'%">'+ "" +'</td>' 
		_cGetLista += '      <td class="itens" align="center" width="'+_aSizes[06]+'%"><b>'+ "Total" +'</b></td>'
		_cGetLista += '      <td class="itens" align="center" width="'+_aSizes[11]+'%"><b>'+ AllTrim(Transform(_nTotalTit,"@E 999,999,999,999.99")) +'</b></td>' 
		_cGetLista += '      <td class="itens" align="left"   width="'+_aSizes[12]+'%">'+ "" +'</td>' 
		_cGetLista += '      <td class="itens" align="left"   width="'+_aSizes[15]+'%">'+ "" +'</td>'
		_cGetLista += '    </tr>'

		_cMsgEml := StrTran(_cMsgEml,"#LISTA#",_cGetLista)

	EndIf

	_cMsgEml += '</center>'
	_cMsgEml += '<br>'
	_cMsgEml += '    <tr>'
	_cMsgEml += '      <td class="itens" align="center" > <b>*</b> Data de vencimento prorrogada </td>'
	_cMsgEml += '    </tr>'
	_cMsgEml += '<br>'
	_cMsgEml += '<br>'
	_cMsgEml += '    <tr>'
	_cMsgEml += '      <td class="itens" align="center" ><b>Ambiente:</b></td>'
	_cMsgEml += '      <td class="itens" align="left" > ['+ GETENVSERVER() +'] / <b>Fonte:</b> [MFIN017]</td>'
	_cMsgEml += '    </tr>'
	_cMsgEml += '</body>'
	_cMsgEml += '</html>'

	If oProc <> Nil
		oProc:cCaption := ("Enviando o e-mail...")
		ProcessMessages()
	EndIf

	_aConfig	  := U_ITCFGEML('')

	// Chama a função para envio do e-mail
	//ITEnvMail(cFrom       ,cEmailTo ,_cEmailCo,cEmailBcc,cAssunto ,cMensagem,cAttach   ,cAccount    ,cPassword   ,cServer     ,cPortCon    ,lRelauth     ,cUserAut     ,cPassAut     ,cLogErro)
	U_ITENVMAIL(_aConfig[01], cGetPara,   cGetCc,       "",cGetAssun, _cMsgEml,        "",_aConfig[01], _aConfig[02],_aConfig[03],_aConfig[04],_aConfig[05],_aConfig[06],_aConfig[07], @_cEmlLog )
	
	If oProc <> Nil
		U_ITMsg(Upper(_cEmlLog)+CHR(13)+CHR(10)+;
		"E-mail para: "+cGetPara+;
		" Com Copia: "+cGetCc+CHR(13)+CHR(10),"Envio do E-MAIL",,3)
	EndIf 
Next

If Len(_aVend) = 0 .And. oProc <> Nil
   U_ITMsg("Não há títulos atrasados de vendedores com atividade de Broker no periodo para listar.","Envio do E-MAIL",,3)
EndIf

Return .T.

/*
===============================================================================================================================
Programa----------: MFIN017BRO
Autor-------------: Igor Melgaço
Data da Criacao---: 15/04/2021
Descrição---------: Vendedores aos quais serão enviado o email
Parametros--------: Nenhum
Retorno-----------: _aVend = Lista dos vendedores
===============================================================================================================================
*/  
Static Function MFIN017BRO

Local _cAliasSA3 := '' , _nCont
Local _cFiltro	 := ''
Local _aVend     := {}

_cAliasSA3:= GetNextAlias()

_cFiltro += "% "
_cFiltro += " SE1.D_E_L_E_T_ = ' ' "
If _lTela
   _cFiltro += " AND ((SE1.E1_I_DTPRO <> ' ' AND SE1.E1_I_DTPRO <'"+ DToS(MV_PAR01)+"')     "
   _cFiltro += " OR   (SE1.E1_I_DTPRO =  ' ' AND SE1.E1_VENCTO  <'"+ DToS(MV_PAR01)+"'))    "
Else
   _cFiltro += " AND ((SE1.E1_I_DTPRO <> ' ' AND SE1.E1_I_DTPRO <'"+ Subs(DToS(MV_PAR01),1,6)+"01')     "
   _cFiltro += " OR   (SE1.E1_I_DTPRO =  ' ' AND SE1.E1_VENCTO  <'"+ Subs(DToS(MV_PAR01),1,6)+"01'))    "
EndIf
_cFiltro += " AND SE1.E1_EMISSAO >='"+ DToS(MV_PAR02) +"' "
_cFiltro += " AND (SE1.E1_TIPO = 'NF' OR SE1.E1_TIPO = 'FT' OR SE1.E1_TIPO = 'FTF' OR SE1.E1_TIPO = 'FTC') "
_cFiltro += " AND SE1.E1_SALDO > 0 "
_cFiltro += " AND SE1.E1_PREFIXO <> 'R' "
_cFiltro += " AND (SE1.E1_I_CART = '' OR SE1.E1_I_CART = '17' OR SE1.E1_I_CART = '20')"
_cFiltro += " AND SA3.A3_I_VBROK = 'B' "
_cFiltro += " AND SA3.A3_I_TIPV = 'V' "
_cFiltro += " %"

BeginSql Alias _cAliasSA3
	SELECT SE1.E1_VEND1, SA3.A3_NOME, SA3.A3_I_EMWF, SA3.A3_I_CCWF
			FROM	%Table:SE1% SE1
			JOIN	%Table:SA3% SA3 ON SA3.A3_COD = SE1.E1_VEND1 AND SA3.%notdel% AND SA3.A3_FILIAL = %xFilial:SA3%
			WHERE	%Exp:_cFiltro%
			GROUP BY SE1.E1_VEND1, SA3.A3_NOME, SA3.A3_I_EMWF, SA3.A3_I_CCWF

	UNION SELECT SE1.E1_VEND2, SA3.A3_NOME, SA3.A3_I_EMWF, SA3.A3_I_CCWF
			FROM	%Table:SE1% SE1
			JOIN	%Table:SA3% SA3 ON SA3.A3_COD = SE1.E1_VEND2 AND SA3.%notdel% AND SA3.A3_FILIAL = %xFilial:SA3%
			WHERE	%Exp:_cFiltro%
			GROUP BY SE1.E1_VEND2, SA3.A3_NOME, SA3.A3_I_EMWF, SA3.A3_I_CCWF

	UNION SELECT SE1.E1_VEND3, SA3.A3_NOME, SA3.A3_I_EMWF, SA3.A3_I_CCWF
			FROM	%Table:SE1% SE1
			JOIN	%Table:SA3% SA3 ON SA3.A3_COD = SE1.E1_VEND3 AND SA3.%notdel% AND SA3.A3_FILIAL = %xFilial:SA3%
			WHERE	%Exp:_cFiltro%
			GROUP BY SE1.E1_VEND3, SA3.A3_NOME, SA3.A3_I_EMWF, SA3.A3_I_CCWF

	UNION SELECT SE1.E1_VEND4, SA3.A3_NOME, SA3.A3_I_EMWF, SA3.A3_I_CCWF
			FROM	%Table:SE1% SE1
			JOIN	%Table:SA3% SA3 ON SA3.A3_COD = SE1.E1_VEND4 AND SA3.%notdel% AND SA3.A3_FILIAL = %xFilial:SA3%
			WHERE	%Exp:_cFiltro%
			GROUP BY SE1.E1_VEND4, SA3.A3_NOME, SA3.A3_I_EMWF, SA3.A3_I_CCWF

	UNION SELECT SE1.E1_VEND5, SA3.A3_NOME, SA3.A3_I_EMWF, SA3.A3_I_CCWF
			FROM	%Table:SE1% SE1
			JOIN	%Table:SA3% SA3 ON SA3.A3_COD = SE1.E1_VEND5 AND SA3.%notdel% AND SA3.A3_FILIAL = %xFilial:SA3%
			WHERE	%Exp:_cFiltro%
			GROUP BY SE1.E1_VEND5, SA3.A3_NOME, SA3.A3_I_EMWF, SA3.A3_I_CCWF
EndSql

cListaEmail:=""
DBSelectArea(_cAliasSA3)
(_cAliasSA3)->(DBGoTop())
If !(_cAliasSA3)->(Eof())
	While !(_cAliasSA3)->(Eof())

       _cEmailPA:=AllTrim((_cAliasSA3)->A3_I_EMWF)
       _cEmailCC:=AllTrim((_cAliasSA3)->A3_I_CCWF)
	   If !_cEmailPA $ cListaEmail
	      cListaEmail+=_cEmailPA+CHR(13)+CHR(10)
	   EndIf
	   If !_cEmailCC $ cListaEmail
	      cListaEmail+=_cEmailCC+CHR(13)+CHR(10)
	   EndIf
		aAdd(_aVend,{(_cAliasSA3)->E1_VEND1,;
		              (_cAliasSA3)->A3_NOME,;
					  _cEmailPA,;
					  _cEmailCC})
						
		(_cAliasSA3)->(DBSkip())
	EndDo
	(_cAliasSA3)->( DBCloseArea() )
EndIf

If _lTela 
	cListaEmail:=StrTran(cListaEmail,";",CHR(13)+CHR(10))
	cListaEmail:=StrTran(cListaEmail,",",CHR(13)+CHR(10))
	bBloco:={||  U_ITMsgLog(cListaEmail, "E-MAILs",1,.F.) }

	_cEmailPA:=AllTrim(UsrRetMail(__cUserId))

	If U_ITMsg("Deseja enviar o relatório somente para "+_cEmailPA+", ou enviar para todos os envolvidos (visualize em mais detalhes).",'Atenção!',,3,2,4,,"USUARIO","TODOS",bBloco)
		For _nCont := 1 to Len(_aVend)
			_aVend[_nCont][3] := _cEmailPA
			_aVend[_nCont][4] := ""
		Next _nCont
	EndIf
EndIf

Return _aVend

/*
===============================================================================================================================
Programa----------: MFIN017QRY
Autor-------------: Igor Melgaço
Data da Criacao---: 15/04/2021
Descrição---------: Gera a lista de Títulos a Receber (SE1)
Parametros--------: _aSizes   = Tamanho das colunas	
------------------: _cCodVend = Vendedor que será usado como filtro na lista de titulos	
Retorno-----------: _cGetLista = Lista dos títulos
===============================================================================================================================
*/  
Static Function MFIN017QRY(_aSizes,_cCodVend)
Local _cAliasSE1 := ''
Local _cFiltro	  := ''
Local _aRet      := {}

_cAliasSE1 := GetNextAlias()

_cFiltro += "% "
_cFiltro += " SE1.D_E_L_E_T_ = ' ' "
If _lTela
   _cFiltro += " AND ((SE1.E1_I_DTPRO <> ' ' AND SE1.E1_I_DTPRO <'"+ DToS(MV_PAR01)+"')     "
   _cFiltro += " OR   (SE1.E1_I_DTPRO =  ' ' AND SE1.E1_VENCTO  <'"+ DToS(MV_PAR01)+"'))    "
Else
   _cFiltro += " AND ((SE1.E1_I_DTPRO <> ' ' AND SE1.E1_I_DTPRO <'"+ Subs(DToS(MV_PAR01),1,6)+"01')     "
   _cFiltro += " OR   (SE1.E1_I_DTPRO =  ' ' AND SE1.E1_VENCTO  <'"+ Subs(DToS(MV_PAR01),1,6)+"01'))    "
EndIf
_cFiltro += " AND SE1.E1_EMISSAO >='"+ DToS(MV_PAR02) +"' "
_cFiltro += " AND (SE1.E1_TIPO = 'NF' OR SE1.E1_TIPO = 'FT' OR SE1.E1_TIPO = 'FTF' OR SE1.E1_TIPO = 'FTC') "
_cFiltro += " AND SE1.E1_SALDO > 0 "
_cFiltro += " AND SE1.E1_PREFIXO <> 'R' "
_cFiltro += " AND (SE1.E1_I_CART = '' OR SE1.E1_I_CART = '17' OR SE1.E1_I_CART = '20')"
_cFiltro += " AND (SE1.E1_VEND1 = '"+_cCodVend+"' "
_cFiltro += "      OR SE1.E1_VEND2 = '"+_cCodVend+"' "
_cFiltro += "      OR SE1.E1_VEND3 = '"+_cCodVend+"' "
_cFiltro += "      OR SE1.E1_VEND4 = '"+_cCodVend+"' "
_cFiltro += "      OR SE1.E1_VEND5 = '"+_cCodVend+"')"
_cFiltro += " %"

BeginSql Alias _cAliasSE1
	SELECT SE1.E1_FILIAL, SE1.E1_PREFIXO, SE1.E1_TIPO, SE1.E1_NUM, SE1.E1_PARCELA, SE1.E1_EMISSAO, SE1.E1_CLIENTE, SE1.E1_LOJA,
			SA1.A1_NREDUZ, SA1.A1_NOME, SA1.A1_MUN, SA1.A1_EST, SE1.E1_VALOR, SE1.E1_VENCTO, SE1.E1_VENCREA, SE1.E1_HIST, SE1.E1_I_DTPRO
			FROM	%Table:SE1% SE1
			JOIN	%Table:SA1% SA1 ON SA1.A1_COD = SE1.E1_CLIENTE AND SA1.%notdel% AND SA1.A1_FILIAL = %xFilial:SA1% 
					AND SA1.A1_LOJA = SE1.E1_LOJA 
			WHERE	%Exp:_cFiltro%
			ORDER BY SE1.E1_CLIENTE, SE1.E1_LOJA, SE1.E1_FILIAL, SE1.E1_PREFIXO, SE1.E1_TIPO, SE1.E1_NUM, SE1.E1_PARCELA
EndSql

DBSelectArea(_cAliasSE1)
(_cAliasSE1)->(DBGoTop())
If !(_cAliasSE1)->(Eof())
	
	While !(_cAliasSE1)->(Eof())
		
		aAdd(_aRet,{(_cAliasSE1)->E1_FILIAL,;
						(_cAliasSE1)->E1_PREFIXO,;
						(_cAliasSE1)->E1_TIPO,;
						(_cAliasSE1)->E1_NUM,;
						(_cAliasSE1)->E1_PARCELA,;
						DToC(SToD((_cAliasSE1)->E1_EMISSAO)),;
						AllTrim((_cAliasSE1)->E1_CLIENTE),;
						AllTrim((_cAliasSE1)->E1_LOJA),;
						(_cAliasSE1)->A1_NREDUZ,;
						(_cAliasSE1)->A1_NOME,;
						(_cAliasSE1)->E1_VALOR,;
						If(!Empty((_cAliasSE1)->E1_I_DTPRO),DToC(SToD((_cAliasSE1)->E1_I_DTPRO))+"*", DToC(SToD((_cAliasSE1)->E1_VENCTO)) ),;
						(_cAliasSE1)->A1_MUN,;
						(_cAliasSE1)->A1_EST,;
						(_cAliasSE1)->E1_HIST})
		
		(_cAliasSE1)->(DBSkip())

	EndDo
	
	(_cAliasSE1)->( DBCloseArea() )

EndIf

Return _aRet
