/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Igor Melgaço  |23/08/2024| Chamado 47047 - Retirada de dados de email do Fernando no fonte.
Lucas Borges  |13/10/2024| Chamado 48465. Retirada da função de conout
Lucas Borges  |23/07/2025| Chamado 51340. Trocado e-mail padrão para sistema@italac.com.br
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MFIN022
Autor-------------: Igor Melgaço
Data da Criacao---: 16/08/2023
Descrição---------: Workflow relação de Titulos integrados do Paytrack. Chamado 44768
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MFIN022()
Local nI         := 0
Local _aParRet   := {}
Local _aParAux   := {}
Local _bOK       := {|| .T. }
Local _lTela     := .T.
Local _cTimeIni  := Time()
Local _lRet      := .F.

//Testa se esta sendo rodado do menu
If Select('SX3') == 0
	
	RPCSetType( 3 )					//Não consome licensa de uso
		
	RpcSetEnv('01','01',,,,GetEnvServer(),{ "SA2","SE2" })
	sleep( 5000 )					//Aguarda 5 segundos para que as jobs IPC subam.
		
	MV_PAR01 := U_ItGetMV( 'IT_SIWF022' , "T" ) 
	MV_PAR02 := U_ItGetMV( 'IT_DTWF022' , SToD('20230101') )
	
	_lTela := .F.

Else

	MV_PAR01 := U_ItGetMV( 'IT_SIWF022' , "T" ) 
	MV_PAR02 := U_ItGetMV( 'IT_DTWF022' , SToD('20230101') )

	aAdd( _aParAux , { 2 , "Situação:"              , MV_PAR01, {"A-Abertos","L-Liquidados","T-Todos"}     , 050 ,".T.",.T.,".T."}) 
	aAdd( _aParAux , { 1 , "Emissão a partir de:"	, MV_PAR02, "@E"	, ""	, ""	, "" , 050 , .F. } )

	For nI := 1 To Len( _aParAux )
			aAdd( _aParRet , _aParAux[nI][03] )
	Next nI
	
	If !ParamBox( _aParAux , "Títulos à Pagar Paytrack" , @_aParRet, _bOK )
		Return .F.
	EndIf
   
EndIf

If _lTela
	
	FWMsgRun( ,{|oProc|  _lRet := MFIN022EM(oProc) } , "Hora Inicial: "+_cTimeIni+" Lendo Títulos a partir de: "+DToC(MV_PAR02))

Else
	//Atualização tabela SM2
	FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MFIN022"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MFIN02201"/*cMsgId*/, "MFIN02201 - Início do Processamento"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	_lRet := MFIN022EM()
	FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MFIN022"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MFIN02202"/*cMsgId*/, "MFIN02202 - Fim do Processamento"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)		
	RpcClearEnv() //Libera o Ambiente

EndIf

Return _lRet

/*
===============================================================================================================================
Programa----------: MFIN022EM
Autor-------------: Igor Melgaço
Data da Criacao---: 16/08/2023
Descrição---------: Rotina de envio do email
Parametros--------: oProc = objeto da barra de processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MFIN022EM(oProc)
Local _aConfig	   := {}
Local _cEmlLog	   := ""
Local _cMsgEml	   := ""
Local _cGetLista  := ""
Local _aCab       := {}
Local _aSizes     := {}
Local cGetCc	   := ""
Local cGetPara	   := SuperGetMV("IT_EMWF022",.F.,"")
Local cGetAssun   := "Títulos Paytrack"
Local _cTit       := " "
Local _aTit       := {}
Local _nTit       := 0
Local _nContTit   := 0
Local _nTotalTit  := 0
Local j           := 0

//           01       02        03     04       05        06        07             08     09         10             11      12            13       14    15
_aSizes := {"10"    ,"02"     ,"02"  ,"08"    ,"04"     ,"05"          ,"05"  ,"20"          ,"04"    ,"03"  ,"08"          ,"04"    ,"08"   , "03"     }
_aCab   := {"Filial","Prefixo","Tipo","Numero","Emissão","Cod. Fornecedor","Loja","Razão Social","Cidade","UF"  ,"Vlr Original","Vencto","Saldo","Dt Baixa"} 
_align  := {"left"  ,"left"   ,"left","left"  ,"left"   ,"left"        ,"left","left"        ,"left"  ,"left","right"       ,"left"  ,"right","left"    }

If oProc <> Nil
	oProc:cCaption := ("Lendo Registros...")
	ProcessMessages()
EndIf

	_cTit    := "Titulos paytrack " + IIf(Subs(MV_PAR01,1,1) == "A","Em Aberto",IIf(Subs(MV_PAR01,1,1) == "L","Liquidados",""))

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
		oProc:cCaption := ("Lendo títulos ")
		ProcessMessages()
	EndIf

	_aTit      := {}
	_aTit      := MFIN022QRY()
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
		For j := 1 To Len(_aCab)
			_cMsgEml += '      <td class="itens" align="'+_align[j]+'"   width="'+_aSizes[j]+'%"><b>'+_aCab[j]+'</b></td>'
		Next
		_cMsgEml += '    </tr>'
		_cMsgEml += '    #LISTA#'
		_cMsgEml += '</table>'

		For _nContTit := 1 To _nTit
			

			_cGetLista += '    <tr>'
				For j := 1 To Len(_aCab)
					_cGetLista += '      <td class="itens" align="'+_align[j]+'"   width="'+_aSizes[j]+'%">'+ _aTit[_nContTit][j] +'</td>' 
				Next
			_cGetLista += '    </tr>'

		Next

		_cMsgEml := StrTran(_cMsgEml,"#LISTA#",_cGetLista)

	EndIf

	_cMsgEml += '</center>'
	_cMsgEml += '<br>'
	_cMsgEml += '<br>'
	_cMsgEml += '    <tr>'
	_cMsgEml += '      <td class="itens" align="center" ><b>Ambiente:</b></td>'
	_cMsgEml += '      <td class="itens" align="left" > ['+ GETENVSERVER() +'] / <b>Fonte:</b> [MFIN022]</td>'
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

Return .T.

/*
===============================================================================================================================
Programa----------: MFIN022QRY
Autor-------------: Igor Melgaço
Data da Criacao---: 16/08/2023
Descrição---------: Gera a lista de Títulos a Receber (SE2)
Parametros--------: _aSizes   = Tamanho das colunas	
------------------: _cCodVend = Vendedor que será usado como filtro na lista de titulos	
Retorno-----------: _cGetLista = Lista dos títulos
===============================================================================================================================
*/  
Static Function MFIN022QRY()
Local _cAliasSE2 := ''
Local _cFiltro	  := ''
Local _aRet      := {}

_cAliasSE2 := GetNextAlias()

_cFiltro += "% "
_cFiltro += " SE2.D_E_L_E_T_ = ' ' "

If Subs(MV_PAR01,1,1) == "A"
	_cFiltro += " AND SE2.E2_SALDO >= 0 
ElseIf Subs(MV_PAR01,1,1) == "L"
	_cFiltro += " AND SE2.E2_SALDO <= 0 
EndIf 

_cFiltro += " AND SE2.E2_EMISSAO >='"+ DToS(MV_PAR02) +"' "
_cFiltro += " AND (SE2.E2_PREFIXO = 'RVI') "
_cFiltro += " AND SE2.E2_FILIAL = '92' "
_cFiltro += " %"

BeginSql Alias _cAliasSE2
	SELECT SE2.E2_FILIAL, SE2.E2_PREFIXO, SE2.E2_TIPO, SE2.E2_NUM, SE2.E2_PARCELA, SE2.E2_EMISSAO, SE2.E2_FORNECE, SE2.E2_LOJA,
			SA2.A2_NREDUZ, SA2.A2_NOME, SA2.A2_MUN, SA2.A2_EST, SE2.E2_VALOR, SE2.E2_VENCTO, SE2.E2_VENCREA, SE2.E2_HIST,SE2.E2_SALDO, SE2.E2_BAIXA
			FROM	%Table:SE2% SE2
			JOIN	%Table:SA2% SA2 ON SA2.A2_COD = SE2.E2_FORNECE AND SA2.%notdel% AND SA2.A2_FILIAL = %xFilial:SA2% 
					AND SA2.A2_LOJA = SE2.E2_LOJA 
			WHERE	%Exp:_cFiltro%
			ORDER BY SE2.E2_FORNECE, SE2.E2_LOJA, SE2.E2_FILIAL, SE2.E2_PREFIXO, SE2.E2_TIPO, SE2.E2_NUM, SE2.E2_PARCELA
EndSql

DBSelectArea(_cAliasSE2)
(_cAliasSE2)->(DBGoTop())
If !(_cAliasSE2)->(Eof())
	
	While !(_cAliasSE2)->(Eof())
		
		aAdd(_aRet,{(_cAliasSE2)->E2_FILIAL + " - " + AllTrim(FWFilialName(cEmpAnt,(_cAliasSE2)->E2_FILIAL,1)),;
						(_cAliasSE2)->E2_PREFIXO,;
						(_cAliasSE2)->E2_TIPO,;
						(_cAliasSE2)->E2_NUM,;
						DToC(SToD((_cAliasSE2)->E2_EMISSAO)),;
						AllTrim((_cAliasSE2)->E2_FORNECE),;
						AllTrim((_cAliasSE2)->E2_LOJA),;
						(_cAliasSE2)->A2_NOME,;
						(_cAliasSE2)->A2_MUN,;
						(_cAliasSE2)->A2_EST,;
						Transform((_cAliasSE2)->E2_VALOR,"@E 999,999,999,999.99"),;
						DToC(SToD((_cAliasSE2)->E2_VENCTO)),;
                        Transform((_cAliasSE2)->E2_SALDO,"@E 999,999,999,999.99") ,;
                        DToC(SToD((_cAliasSE2)->E2_BAIXA))})
		
		(_cAliasSE2)->(DBSkip())

	EndDo
	
	(_cAliasSE2)->( DBCloseArea() )

EndIf

Return _aRet
