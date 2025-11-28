/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |19/06/2019| Chamado 28346. Revisão de fontes
Lucas Borges  |27/09/2019| Chamado 28346. Revisão de fontes
Lucas Borges  |22/04/2025| Chamado 50505. Alterada a picture do CNPJ para contemplar campo alfanumérico
===============================================================================================================================
*/

#Include "TOTVS.ch"

#Define TITULO	"Plataformas - Fechamento Quinzenal"

/*
===============================================================================================================================
Programa--------: RGLT060
Autor-----------: Darcio Ribeiro Spörl
Data da Criacao-: 18/07/2016
Descrição-------: Relatório Fechamento Plataformas
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function RGLT060()

Local _aDados		:= {}
Local _cPerg		:= "RGLT060"
Local _nOpca		:= 0
Local _aSays		:= {}
Local _aButtons		:= {}

Private _nNumPag	:= 0
Private _cDtIni		:= ''
Private _cDtFim		:= ''

SET DATE FORMAT TO "DD/MM/YYYY"

Pergunte( _cPerg , .F. )

aAdd( _aSays , OemToAnsi( "Este programa tem como objetivo gerar o relatório de registros das plataformas."	) )

aAdd( _aButtons , { 5 , .T. , {| | Pergunte( _cPerg )			} } )
aAdd( _aButtons , { 1 , .T. , {|o| _nOpca := 1 , o:oWnd:End()	} } )
aAdd( _aButtons , { 2 , .T. , {|o| _nOpca := 0 , o:oWnd:End()	} } )

FormBatch( "RGLT060" , _aSays , _aButtons ,, 155 , 500 )

If _nOpca == 1

	Processa( {|| _aDados := RGLT060SEL() } , "Aguarde!" , "Selecionando registros das plataformas..." )
	
	If Empty(_aDados)
		MessageBox( "Não foram encontrados registros para exibir! Verifique os parâmetros e tente novamente." , "RGLT06001" , 48 )
	Else
		Processa( {|| RGLT060PRT( _aDados ) } , 'Aguarde!' , 'Imprimindo registros...' )
	EndIf

Else
	MsgInfo( 'Operação cancelada pelo usuário!' , 'RGLT06002' )
EndIf

Return

/*
===============================================================================================================================
Programa--------: RGLT060SEL
Autor-----------: Darcio Ribeiro Spörl
Data da Criacao-: 18/07/2016
Descrição-------: Função para consulta e preparação dos dados do relatório
Parametros------: Nenhum
Retorno---------: _aRet - Dados do relatório
===============================================================================================================================
*/
Static Function RGLT060SEL()

Local _aRet			:= {}
Local _cAlias		:= GetNextAlias()
Local _cCampos		:= '%'
Local _cTables		:= '%'
Local _cFiltro		:= '%'
Local _cGroup		:= '%'
Local _cOrder		:= '%'
Local _nTotReg		:= 0
Local _nRegAtu		:= 0

If MV_PAR01 == 1
	_cDtIni := SubStr( MV_PAR02 , 3 , 4 ) + SubStr( MV_PAR02 , 1 , 2 ) + '01'
	_cDtFim := SubStr( MV_PAR02 , 3 , 4 ) + SubStr( MV_PAR02 , 1 , 2 ) + '15'
Else
	_cDtIni := SubStr( MV_PAR02 , 3 , 4 ) + SubStr( MV_PAR02 , 1 , 2 ) + '16'
	_cDtFim := DToS( LastDay( SToD( SubStr( MV_PAR02 , 3 , 4 ) + SubStr( MV_PAR02 , 1 , 2 ) + '01' ) ) )
EndIf

If !Empty(MV_PAR03)
	_cCampos += " ZA7.ZA7_TIPPRD, %"
	_cTables += ", " + RetSQLName("ZA7") + " ZA7 %"
	_cFiltro += " AND ZA7.D_E_L_E_T_ = ' '"
	_cFiltro += " AND ZA7.ZA7_FILIAL = '" + xFilial("ZA7") + "' "
	_cFiltro += " AND ZLX.ZLX_FILIAL = ZA7.ZA7_FILIAL"
	_cFiltro += " AND ZA7.ZA7_TIPPRD IN "+ FormatIn( MV_PAR03 , ';' ) +" %"
	_cGroup += "ZA7.ZA7_TIPPRD , %"
	_cOrder	+= ", ZA7.ZA7_TIPPRD %"
EndIf

BeginSql alias _cAlias
	SELECT Case WHEN SubStr(SA2.A2_COD, 1, 1) = 'Z' THEN 'PLATAFORMA' END ORIGEM,
	%exp:_cCampos% SA2.A2_COD, SA2.A2_LOJA, SA2.A2_NOME, SA2.A2_NREDUZ,
	 RTRIM(SA2.A2_DDD) || '-' || SA2.A2_TEL TELEFONE,
	 RTRIM(SA2.A2_END) || ',' || RTRIM(SA2.A2_NR_END) || SA2.A2_ENDCOMP ENDERECO,
	 SA2.A2_MUN, SA2.A2_EST, SA2.A2_EMAIL, SA2.A2_CGC, SA2.A2_INSCR, SA2.A2_CONTATO, SA2.A2_L_KMLE
	  FROM %Table:SA2% SA2, %Table:ZLX% ZLX %exp:_cTables% 
	 WHERE ZLX.D_E_L_E_T_ = ' '
	   AND SA2.D_E_L_E_T_ = ' '
   	   %exp:_cFiltro%
	   AND ZLX.ZLX_FILIAL = %xFilial:ZLX%
	   AND SA2.A2_FILIAL = %xFilial:SA2% 
	   AND SA2.A2_COD BETWEEN %exp:MV_PAR04% AND %exp:MV_PAR06%
	   AND SA2.A2_LOJA BETWEEN %exp:MV_PAR05% AND %exp:MV_PAR07%
	   AND SubStr(SA2.A2_COD, 1, 1) = 'Z'
	   AND ZLX.ZLX_DATAEN <> ' '
	   AND ZLX.ZLX_DTENTR BETWEEN %exp:_cDtIni% AND %exp:_cDtFim%
	   AND ZLX.ZLX_FORNEC = SA2.A2_COD
	   AND ZLX.ZLX_LJFORN = SA2.A2_LOJA
	 GROUP BY %exp:_cGroup% SA2.A2_COD, SA2.A2_LOJA, SA2.A2_NOME, SA2.A2_NREDUZ,
	          RTRIM(SA2.A2_DDD) || '-' || SA2.A2_TEL,
	          RTRIM(SA2.A2_END) || ',' || RTRIM(SA2.A2_NR_END) ||
	          SA2.A2_ENDCOMP, SA2.A2_MUN, SA2.A2_EST, SA2.A2_EMAIL, SA2.A2_CGC,
	          SA2.A2_INSCR, SA2.A2_CONTATO, SA2.A2_L_KMLE
	 ORDER BY SA2.A2_COD, SA2.A2_LOJA, SA2.A2_NREDUZ %exp:_cOrder%
EndSql

(_cAlias)->( DBEval( {|| _nTotReg++ } ) )
(_cAlias)->( DBGoTop() )

ProcRegua(_nTotReg)
While (_cAlias)->( !Eof() )
	
	_nRegAtu++
	IncProc( "Lendo registros: ["+ StrZero( _nRegAtu , 6 ) +"] de ["+ StrZero( _nTotReg , 6 ) +"]" )

	If !Empty(MV_PAR03)
		aAdd( _aRet , {				(_cAlias)->ORIGEM										,; //01 - Origem
									(_cAlias)->A2_COD										,; //02 - Código Fornecedor
									(_cAlias)->A2_LOJA										,; //03 - Loja
						AllTrim(	(_cAlias)->A2_NOME )									,; //04 - Razão Social
						AllTrim(	(_cAlias)->A2_NREDUZ )									,; //05 - Nome Fantasia
						AllTrim(	(_cAlias)->TELEFONE )									,; //06 - Telefone
						AllTrim(	(_cAlias)->ENDERECO )									,; //07 - Endereço
						AllTrim(	(_cAlias)->A2_MUN )										,; //08 - Município
						AllTrim(	(_cAlias)->A2_EST )										,; //09 - Estado
						AllTrim(	(_cAlias)->A2_EMAIL )									,; //10 - E-mail
						AllTrim(	(_cAlias)->A2_CGC )										,; //11 - CGC
						AllTrim(	(_cAlias)->A2_INSCR )									,; //12 - Inscrição Estadual
						AllTrim(	(_cAlias)->A2_CONTATO )									,; //13 - Contato
						AllTrim( Transform(	(_cAlias)->A2_L_KMLE	, '@E 999,999,999,999'	) )	,; //14 - KM
						AllTrim(	(_cAlias)->ZA7_TIPPRD )									}) //15 - Tipo de Produto

	Else

		aAdd( _aRet , {				(_cAlias)->ORIGEM										,; //01 - Origem
									(_cAlias)->A2_COD										,; //02 - Código Fornecedor
									(_cAlias)->A2_LOJA										,; //03 - Loja
						AllTrim(	(_cAlias)->A2_NOME )									,; //04 - Razão Social
						AllTrim(	(_cAlias)->A2_NREDUZ )									,; //05 - Nome Fantasia
						AllTrim(	(_cAlias)->TELEFONE )									,; //06 - Telefone
						AllTrim(	(_cAlias)->ENDERECO )									,; //07 - Endereço
						AllTrim(	(_cAlias)->A2_MUN )										,; //08 - Município
						AllTrim(	(_cAlias)->A2_EST )										,; //09 - Estado
						AllTrim(	(_cAlias)->A2_EMAIL )									,; //10 - E-mail
						AllTrim(	(_cAlias)->A2_CGC )										,; //11 - CGC
						AllTrim(	(_cAlias)->A2_INSCR )									,; //12 - Inscrição Estadual
						AllTrim(	(_cAlias)->A2_CONTATO )									,; //13 - Contato
						AllTrim( Transform(	(_cAlias)->A2_L_KMLE	, '@E 999,999,999,999'	) )})//14 - KM
	EndIf

	(_cAlias)->( DBSkip() )
EndDo

(_cAlias)->( DBCloseArea() )

Return( _aRet )

/*
===============================================================================================================================
Programa--------: RGLT060PRT
Autor-----------: Darcio Ribeiro Spörl
Data da Criacao-: 18/07/2016
Descrição-------: Função para controlar e imprimir os dados do relatório
Parametros------: _aDados  - Dados do relatório
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function RGLT060PRT( _aDados )

Local _aCabec1	:= { 'Data/Hora'  , ' Dia' , 'Núm. NF' , 'Volume' , '  Volume' , ' Dif. na' , 'Valor NF' , 'ICMS NF' , 'Preço' , 'Teor MG' , ' Qtd. MG' }
Local _aCabec2	:= { 'Entr. Fáb.' , 'Mov.' , ''        , '    NF' , 'Recebido' , 'Balança'  , ''         , ''        , 'Unit.' , ''        , 'Recebida' }
Local _aColCab	:= { 0100         , 0380   , 0500      , 0720     , 0900       , 1090       , 1290       , 1490      , 1690    , 1810      , 2000       }
Local _aColCab2	:= {}
Local _aColItn	:= { 0070         , 0395   , 0500      , 0830     , 1040       , 1200       , 1420       , 1620      , 1770    , 1930      , 2150       }
Local _aColItn2	:= {}
Local _aColDiv	:= { 0050         , 0355   , 0460      , 0660     , 0850       , 1060       , 1220       , 1440      , 1640    , 1790      , 1950       }
Local _aItnAux	:= {}
Local _aTotAux	:= {}
Local _cAlias	:= ""
Local _nLinha	:= 5000
Local _nI		:= 0
Local _nX		:= 0
Local _nValUlt	:= 0
Local _oPrint	:= Nil

Private _oFont01	:= TFont():New( "Tahoma" ,, 14 , .F. , .T. ,, .T. ,, .T. , .F. )
Private _oFont02	:= TFont():New( "Tahoma" ,, 08 , .F. , .T. ,, .T. ,, .T. , .F. )
Private _oFont03	:= TFont():New( "Tahoma" ,, 07 , .F. , .F. ,, .T. ,, .T. , .F. )
Private _oFont03B	:= TFont():New( "Tahoma" ,, 08 , .F. , .T. ,, .T. ,, .T. , .F. )

//====================================================================================================
// Inicializa o objeto do relatório
//====================================================================================================
_oPrint := TMSPrinter():New( TITULO )
_oPrint:Setup()
_oPrint:SetPortrait()
_oPrint:SetPaperSize(9)

ProcRegua( Len( _aDados ) )

//====================================================================================================
// Processa a impressão dos dados
//====================================================================================================
For _nI := 1 To Len( _aDados )
	
	IncProc( 'Imprimindo registro: ['+ StrZero( _nI , 6 ) +'] de ['+ StrZero( Len( _aDados ) , 6 ) +']' )
	
	//====================================================================================================
	// Inicializa a página e adiciona cabecalho de conteúdo
	//====================================================================================================
	_nLinha := 5000
	RGLT060VPG( @_oPrint , @_nLinha , ( _nI > 1 ) )
	
	_oPrint:Say( _nLinha , 060 , "> Fechamento: "+ cValToChar( MV_PAR01 ) +"ª quinzena / "+ MesExtenso( SubStr(AllTrim(MV_PAR02),1,2 ));
								 +" "+ SubStr(AllTrim(MV_PAR02),3,4 ) +" - "+ _aDados[_nI][01] , _oFont01 )
	_nLinha += 070
	
	//====================================================================================================
	// Imprime quadro dos dados do Fornecedor
	//====================================================================================================
	_oPrint:Line( _nLinha       , 0050 , _nLinha       , 2350 )
	_oPrint:Line( _nLinha + 130 , 0050 , _nLinha + 130 , 2350 )
	_oPrint:Line( _nLinha       , 0050 , _nLinha + 130 , 0050 )
	_oPrint:Line( _nLinha       , 2350 , _nLinha + 130 , 2350 )
	
	_nLinha += 015
	
	_oPrint:Say( _nLinha , 0080 , 'Fornecedor: '+	AllTrim( _aDados[_nI][02] +'/'+ _aDados[_nI][03] ) +' - '+ AllTrim( _aDados[_nI][04] )	, _oFont02 )
	_oPrint:Say( _nLinha , 1700 , 'Fantasia: '+		AllTrim( _aDados[_nI][05] )																, _oFont02 )
	
	_nLinha += 035
	
	_oPrint:Say( _nLinha , 0080 , 'Endereço: '		, _oFont02 ) ; _oPrint:Say( _nLinha + 002 , 0230 , AllTrim( _aDados[_nI][07] )										, _oFont03 )
	_oPrint:Say( _nLinha , 1080 , 'Cidade: '		, _oFont02 ) ; _oPrint:Say( _nLinha + 002 , 1200 , AllTrim( _aDados[_nI][08] ) +' / '+ AllTrim( _aDados[_nI][09] )	, _oFont03 )
	_oPrint:Say( _nLinha , 1750 , 'e-Mail: '		, _oFont02 ) ; _oPrint:Say( _nLinha + 002 , 1890 , AllTrim( _aDados[_nI][10] )										, _oFont03 )
	
	_nLinha += 035
	
	_oPrint:Say( _nLinha , 0080 , 'CNPJ: '			, _oFont02 ) ; _oPrint:Say( _nLinha + 002 , 0190 , Transform( _aDados[_nI][11] , '@R! NN.NNN.NNN/NNNN-99' )			, _oFont03 )
	_oPrint:Say( _nLinha , 0600 , 'Inscr.Est.: '	, _oFont02 ) ; _oPrint:Say( _nLinha + 002 , 0790 , AllTrim( _aDados[_nI][12] )										, _oFont03 )
	_oPrint:Say( _nLinha , 1200 , 'Telefone: '		, _oFont02 ) ; _oPrint:Say( _nLinha + 002 , 1380 , AllTrim( _aDados[_nI][06] )										, _oFont03 )
	_oPrint:Say( _nLinha , 1700 , 'Contato: '		, _oFont02 ) ; _oPrint:Say( _nLinha + 002 , 1880 , AllTrim( _aDados[_nI][13] )										, _oFont03 )

    _nLinha += 100

	//====================================================================================================
	// Verifica dados para imprimir a relação das entradas do fornecedor no período
	//====================================================================================================
	_oPrint:Say( _nLinha , 060 , "> Relação das Entradas:" , _oFont01 )
	_nLinha += 070
	_cAlias	:= GetNextAlias()
	
	BeginSql alias _cAlias
		SELECT ZLX.ZLX_DATAEN, ZLX.ZLX_HRENTR, SubStr(ZLX.ZLX_DTENTR, 7, 2) DIA_MOV, ZLX.ZLX_NRONF, ZLX.ZLX_VOLNF,
		       ZLX.ZLX_VOLREC, ZLX.ZLX_DIFVOL, ZLX.ZLX_VLRNF, ZLX.ZLX_ICMSNF, ZLX.ZLX_PRCNF,
		       NVL(Round((SELECT SUM(ZAP_GORD) / COUNT(1)
		                   FROM %Table:ZAP% ZAP
		                  WHERE ZAP.D_E_L_E_T_ = ' '
		                    AND ZAP.ZAP_FILIAL = ZLX.ZLX_FILIAL
		                    AND ZLX.ZLX_CODANA = ZAP.ZAP_CODIGO),
		                 2), 0) GORDURA
		  FROM %Table:ZLX% ZLX
		 WHERE ZLX.D_E_L_E_T_ = ' '
		   AND ZLX.ZLX_FILIAL = %xFilial:ZLX%
		   AND ZLX.ZLX_DATAEN <> ' '
		   AND ZLX.ZLX_DTENTR BETWEEN %exp:_cDtIni% AND %exp:_cDtFim%
		   AND ZLX.ZLX_FORNEC = %exp:_aDados[_nI][02]%
		   AND ZLX.ZLX_LJFORN = %exp:_aDados[_nI][03]%
		 ORDER BY ZLX.ZLX_DTENTR, ZLX.ZLX_CODIGO
	EndSql

	_aItnAux := {}
	_aTotAux := { 'Total Geral:' ,'','',0,0,0,0,0,0,0,0 }
	
	While (_cAlias)->( !Eof() )
		
		If RGLT060VPG( @_oPrint , @_nLinha , .T. ) .Or. Empty( _aItnAux )
		
			_oPrint:Line( _nLinha       , 0050 , _nLinha       , 2350 )
			_oPrint:Line( _nLinha + 080 , 0050 , _nLinha + 080 , 2350 )
			_oPrint:Line( _nLinha       , 0050 , _nLinha + 080 , 0050 )
			_oPrint:Line( _nLinha       , 2350 , _nLinha + 080 , 2350 )
			
			For _nX := 1 To Len( _aCabec1 )
			
				If Empty( _aCabec2[_nX] )
					
				    _oPrint:Say( _nLinha + 30 , _aColCab[_nX] , _aCabec1[_nX] , _oFont02 )
				
				Else
				    
					_oPrint:Say( _nLinha + 10 , _aColCab[_nX] , _aCabec1[_nX] , _oFont02 )
					_oPrint:Say( _nLinha + 40 , _aColCab[_nX] , _aCabec2[_nX] , _oFont02 )
					
				EndIf
				                         	
				_oPrint:Line( _nLinha , _aColDiv[_nX] , _nLinha + 080 ,  _aColDiv[_nX] )
				
			Next _nX
			
			_nLinha += 090
			
		EndIf		
		
		aAdd( _aItnAux , {	DToC( SToD( (_cAlias)->ZLX_DATAEN ) ) +" | "+ (_cAlias)->ZLX_HRENTR			  										,;
							StrZero( Val( (_cAlias)->DIA_MOV ) , 2 )															  				,;
							AllTrim( (_cAlias)->ZLX_NRONF )																		  				,;
							AllTrim( Transform( (_cAlias)->ZLX_VOLNF 									, '@E 999,999,999,999' ) ) +' L'		,;
							AllTrim( Transform( (_cAlias)->ZLX_VOLREC									, '@E 999,999,999,999' ) ) +' L'		,;
							AllTrim( Transform( (_cAlias)->ZLX_DIFVOL									, '@E 999,999,999,999' ) ) +' L'		,;
							AllTrim( Transform( (_cAlias)->ZLX_VLRNF 									, '@E 999,999,999,999.99' ) )			,;
							AllTrim( Transform( (_cAlias)->ZLX_ICMSNF									, '@E 999,999,999,999.99' ) )			,;
							AllTrim( Transform( (_cAlias)->ZLX_PRCNF									, '@E 999,999,999.9999' ) )				,;
							AllTrim( Transform( (_cAlias)->GORDURA										, '@E 999,999,999,999.99' ) ) +' %'		,;
							AllTrim( Transform( ( (_cAlias)->ZLX_VOLREC * (_cAlias)->GORDURA ) / 100	, '@E 999,999,999,999.99' ) ) +' Kg'	})
		
		_aTotAux[04] += (_cAlias)->ZLX_VOLNF
		_aTotAux[05] += (_cAlias)->ZLX_VOLREC
		_aTotAux[06] += (_cAlias)->ZLX_DIFVOL
		_aTotAux[07] += (_cAlias)->ZLX_VLRNF
		_aTotAux[08] += (_cAlias)->ZLX_ICMSNF
		_aTotAux[09] := _aTotAux[07] / _aTotAux[04]
		_aTotAux[11] += ( (_cAlias)->ZLX_VOLREC * ( (_cAlias)->GORDURA / 100 ) )
		
		_aTotAux[10] := ( _aTotAux[11] / _aTotAux[05] ) * 100
		
		_nValUlt := (_cAlias)->ZLX_PRCNF
		
		For _nX := 1 To Len( _aColItn )
		
			_oPrint:Say( _nLinha , _aColItn[_nX] , _aItnAux[Len(_aItnAux)][_nX] , _oFont03 ,,,, IIf( StrZero(_nX,2) $ '04,05,06,07,08,09,10,11' , 1 , 0 ) )
			_oPrint:Line( _nLinha - 30 , _aColDiv[_nX] , _nLinha + 30 , _aColDiv[_nX] )
			
		Next _nX
		
		_oPrint:Line( _nLinha - 30 , 2350 , _nLinha + 30 , 2350 )
		_nLinha += 030
		_oPrint:Line( _nLinha , 0050 , _nLinha , 2350 )
		
		(_cAlias)->( DBSkip() )
	EndDo
	
	(_cAlias)->( DBCloseArea() )
	
	_nLinha += 050
	
	_oPrint:Line( _nLinha , 0050 , _nLinha , 2350 )
	_nLinha += 010
	
	RGLT060VPG( @_oPrint , @_nLinha , .T. )
	
	//====================================================================================================
	// Processa a impressão dos Totalizadores
	//====================================================================================================
	For _nX := 1 To Len( _aTotAux )
		
		Do Case
			Case _nX <= 03 ; _oPrint:Say( _nLinha , _aColItn[_nX] , _aTotAux[_nX] , _oFont03 )
			Case _nX <= 06 ; _oPrint:Say( _nLinha , _aColItn[_nX] , Transform( _aTotAux[_nX] , '@E 999,999,999,999' ) +' L'	   		, _oFont03 ,,,, 1 )
			Case _nX <= 08 ; _oPrint:Say( _nLinha , _aColItn[_nX] , Transform( _aTotAux[_nX] , '@E 999,999,999,999.99' )	  		, _oFont03 ,,,, 1 )
			Case _nX == 09 ; _oPrint:Say( _nLinha , _aColItn[_nX] , Transform( _aTotAux[_nX] , '@E 999,999,999,999.9999' ) 	   		, _oFont03 ,,,, 1 )
			Case _nx == 10 ; _oPrint:Say( _nLinha , _aColItn[_nX] , Transform( _aTotAux[_nX] , '@E 999,999,999,999.99' ) + ' %'		, _oFont03 ,,,, 1 )
			Case _nx >  10 ; _oPrint:Say( _nLinha , _aColItn[_nX] , Transform( _aTotAux[_nX] , '@E 999,999,999,999.99' ) + ' Kg'	, _oFont03 ,,,, 1 )
		EndCase
		
		If _nX == 1 .Or. _nX > 3
			_oPrint:Line( _nLinha - 10 , _aColDiv[_nX] , _nLinha + 30 , _aColDiv[_nX] )
		EndIf
		
	Next _nX
	
	_oPrint:Line( _nLinha - 10 , 2350 , _nLinha + 30 , 2350 )
	_nLinha += 030
	_oPrint:Line( _nLinha , 0050 , _nLinha , 2350 )
	
	//====================================================================================================
	// Processa a consulta dos dados do frete
	//====================================================================================================
	_cAlias	:= GetNextAlias()
	BeginSql alias _cAlias
		SELECT ZLX.ZLX_NRONF NUMERO,
		       SubStr(ZLX.ZLX_DTENTR, 7, 2) DIA_MOV,
		       ZLX.ZLX_CTE CTE, SA2.A2_NREDUZ NREDUZ, ZLX.ZLX_PLACA PLACA,
		       Case
		         WHEN ZLX.ZLX_VLRKM > 0 THEN
		          ZLX.ZLX_VLRKM
		         WHEN ZZU.ZZU_KMFORN > 0 THEN
		          (ZLX.ZLX_VLRFRT / ZZU.ZZU_KMFORN)
		         Else
		          0
		       END VLRKM,
		       ZLX.ZLX_VLRFRT VLRFRT, ZLX.ZLX_PEDAGI PEDAGI, ZLX.ZLX_ICMSFR ICMSFR, ZLX.ZLX_TVLFRT TVLFRT,
		       Case
		         WHEN ZLX.ZLX_VOLREC > 0 THEN
		          ((ZLX.ZLX_VLRFRT + ZLX.ZLX_PEDAGI) / ZLX.ZLX_VOLREC)
		         Else
		          0
		       END CUSTO,
		       ZLX.ZLX_TRANSP || ZLX.ZLX_LJTRAN CHAVE, ZLX.ZLX_VOLREC VOLUME
		  FROM %Table:ZLX% ZLX
		  LEFT JOIN %Table:SA2% SA2
		    ON SA2.D_E_L_E_T_ = ' '
		   AND SA2.A2_FILIAL = %xFilial:SA2%
		   AND ZLX.ZLX_TRANSP = SA2.A2_COD
		   AND ZLX.ZLX_LJTRAN = SA2.A2_LOJA
		  LEFT JOIN %Table:ZZX% ZZX
		    ON ZZX.D_E_L_E_T_ = ' '
		   AND ZZX.ZZX_FILIAL = %xFilial:ZZX%
		   AND ZLX.ZLX_FILIAL = ZZX.ZZX_FILIAL
		   AND ZZX.ZZX_CODIGO = ZLX.ZLX_CODANA
		  LEFT JOIN %Table:ZZV% ZZV
		    ON ZZV.D_E_L_E_T_ = ' '
		   AND ZZV.ZZV_FILIAL = %xFilial:ZZV%
		   AND ZZX.ZZX_FILIAL = ZZV.ZZV_FILIAL
		   AND ZZX.ZZX_PLACA = ZZV.ZZV_PLACA
		   AND ZZV.ZZV_TRANSP = ZLX.ZLX_TRANSP
		   AND ZZV.ZZV_LJTRAN = ZLX.ZLX_LJTRAN
		  LEFT JOIN %Table:ZZU% ZZU
		    ON ZZU.D_E_L_E_T_ = ' '
		   AND ZZU.ZZU_FILIAL = %xFilial:ZZU%
		   AND ZLX.ZLX_FILIAL = ZZU.ZZU_FILIAL
		   AND ZZU.ZZU_TRANSP = ZLX.ZLX_TRANSP
		   AND ZZU.ZZU_LJTRAN = ZLX.ZLX_LJTRAN
		   AND ZZU.ZZU_CAPACI = ZZV.ZZV_FXCAPA
		   AND ZZU.ZZU_FORNEC = ZLX.ZLX_FORNEC
		   AND ZZU.ZZU_LJFORN = ZLX.ZLX_LJFORN
		 WHERE ZLX.D_E_L_E_T_ = ' '
		   AND ZLX.ZLX_FILIAL = %xFilial:ZLX%
		   AND ZLX.ZLX_DTENTR BETWEEN %exp:_cDtIni% AND %exp:_cDtFim%
		   AND ZLX.ZLX_FORNEC = %exp:_aDados[_nI][02]%
		   AND ZLX.ZLX_LJFORN = %exp:_aDados[_nI][03]%
		 ORDER BY ZLX.ZLX_DTENTR, ZLX.ZLX_CODIGO
	EndSql
	
	_aDadFrt := {}
	
	While (_cAlias)->( !Eof() )
		aAdd( _aDadFrt , {	(_cAlias)->NUMERO		,;
							(_cAlias)->DIA_MOV		,;
							(_cAlias)->CTE			,;
							(_cAlias)->NREDUZ		,;
							(_cAlias)->PLACA		,;
							(_cAlias)->VLRKM		,;
							(_cAlias)->VLRFRT		,;
							(_cAlias)->PEDAGI		,;
							(_cAlias)->ICMSFR		,;
							(_cAlias)->TVLFRT		,;
							(_cAlias)->CUSTO		,;
							(_cAlias)->CHAVE		,;
							(_cAlias)->VOLUME		})
		
		(_cAlias)->( DBSkip() )
	EndDo
	
	(_cAlias)->( DBCloseArea() )

	_nLinha += 4000
	RGLT060VPG( @_oPrint , @_nLinha , .T. )

	_oPrint:Say( _nLinha , 060 , "> Apuração de Frete" , _oFont01 )
	_nLinha += 070
	
	_aColCab2 := { 0070 , 0250 , 0350 , 0515 , 1020 , 1170 , 1370 , 1590 , 1780 , 1930 , 2150 }
	_aColItn2 := { 0070 , 0270 , 0355 , 0515 , 1000 , 1320 , 1550 , 1720 , 1890 , 2120 , 2330 }
	
	_oPrint:Line( _nLinha       , 0050 , _nLinha       , 2350 )
	_oPrint:Line( _nLinha       , 0050 , _nLinha + 070 , 0050 )
	_oPrint:Line( _nLinha       , 2350 , _nLinha + 070 , 2350 )
	_oPrint:Line( _nLinha + 070 , 0050 , _nLinha + 070 , 2350 )
	
	_oPrint:Say( _nLinha + 025	, _aColCab2[01] , 'Número NF'		, _oFont02 ) ; _oPrint:Line( _nLinha , 0240 , _nLinha + 070 , 0240 )
	_oPrint:Say( _nLinha		, _aColCab2[02] , ' Dia'			, _oFont02 ) 
	_oPrint:Say( _nLinha + 030	, _aColCab2[02] , 'Mov.'			, _oFont02 ) ; _oPrint:Line( _nLinha , 0340 , _nLinha + 070 , 0340 )
	_oPrint:Say( _nLinha + 025	, _aColCab2[03] , 'Núm. CTE'		, _oFont02 ) ; _oPrint:Line( _nLinha , 0505 , _nLinha + 070 , 0505 )
	_oPrint:Say( _nLinha + 025	, _aColCab2[04] , 'Transportadora'	, _oFont02 ) ; _oPrint:Line( _nLinha , 0990 , _nLinha + 070 , 0990 )
	_oPrint:Say( _nLinha + 025	, _aColCab2[05] , 'Placa'			, _oFont02 ) ; _oPrint:Line( _nLinha , 1160 , _nLinha + 070 , 1160 )
	_oPrint:Say( _nLinha + 025	, _aColCab2[06] , 'Preço/Km'		, _oFont02 ) ; _oPrint:Line( _nLinha , 1340 , _nLinha + 070 , 1340 )
	_oPrint:Say( _nLinha + 025	, _aColCab2[07] , 'Valor Frete'		, _oFont02 ) ; _oPrint:Line( _nLinha , 1560 , _nLinha + 070 , 1560 )
	_oPrint:Say( _nLinha + 025	, _aColCab2[08] , 'Pedágio'			, _oFont02 ) ; _oPrint:Line( _nLinha , 1730 , _nLinha + 070 , 1730 )
	_oPrint:Say( _nLinha + 025	, _aColCab2[09] , 'ICMS'			, _oFont02 ) ; _oPrint:Line( _nLinha , 1900 , _nLinha + 070 , 1900 )
	_oPrint:Say( _nLinha + 025	, _aColCab2[10] , 'Total Prest.'	, _oFont02 ) ; _oPrint:Line( _nLinha , 2130 , _nLinha + 070 , 2130 )
	_oPrint:Say( _nLinha + 025	, _aColCab2[11] , 'Custo/Litro'		, _oFont02 ) 
	
	_nLinha += 040
	
	_aResFrt := {}
	_aTotFrt := { 0 , 0 , 0 , 0 , 0 , 0 }
	
	For _nX := 1 To Len( _aDadFrt )
		
		_nLinha += 030
		RGLT060VPG( @_oPrint , @_nLinha , .T. )
		
		If ( _nPosAux := aScan( _aResFrt , {|x| x[01] == _aDadFrt[_nX][12] } ) ) == 0
			aAdd( _aResFrt , { _aDadFrt[_nX][12] , _aDadFrt[_nX][04] , 1 , _aDadFrt[_nX][13] , _aDadFrt[_nX][06] , _aDadFrt[_nX][07] , _aDadFrt[_nX][08] , _aDadFrt[_nX][09] , _aDadFrt[_nX][10] , _aDadFrt[_nX][11] } )
		Else
			_aResFrt[_nPosAux][03]++
			_aResFrt[_nPosAux][04] += _aDadFrt[_nX][13]
			_aResFrt[_nPosAux][05] += _aDadFrt[_nX][06]
			_aResFrt[_nPosAux][06] += _aDadFrt[_nX][07]
			_aResFrt[_nPosAux][07] += _aDadFrt[_nX][08]
			_aResFrt[_nPosAux][08] += _aDadFrt[_nX][09]
			_aResFrt[_nPosAux][09] += _aDadFrt[_nX][10]
		EndIf
		
		_aTotFrt[01] += _aDadFrt[_nX][06]
		_aTotFrt[02] += _aDadFrt[_nX][07]
		_aTotFrt[03] += _aDadFrt[_nX][08]
		_aTotFrt[04] += _aDadFrt[_nX][09]
		_aTotFrt[05] += _aDadFrt[_nX][10]
		_aTotFrt[06] += _aDadFrt[_nX][11]
		
		_oPrint:Line( _nLinha       , 0050 , _nLinha       , 2350 )
		_oPrint:Line( _nLinha       , 0050 , _nLinha + 030 , 0050 )
		_oPrint:Line( _nLinha       , 2350 , _nLinha + 030 , 2350 )
		_oPrint:Line( _nLinha + 030 , 0050 , _nLinha + 030 , 2350 )
		
		_oPrint:Say( _nLinha , _aColItn2[01] , _aDadFrt[_nX][01] , _oFont03 )																; _oPrint:Line( _nLinha , 0240 , _nLinha + 030 , 0240 )
		_oPrint:Say( _nLinha , _aColItn2[02] , _aDadFrt[_nX][02] , _oFont03 )																; _oPrint:Line( _nLinha , 0340 , _nLinha + 030 , 0340 )
		_oPrint:Say( _nLinha , _aColItn2[03] , _aDadFrt[_nX][03] , _oFont03 )																; _oPrint:Line( _nLinha , 0505 , _nLinha + 030 , 0505 )
		_oPrint:Say( _nLinha , _aColItn2[04] , _aDadFrt[_nX][04] , _oFont03 )																; _oPrint:Line( _nLinha , 0990 , _nLinha + 030 , 0990 )
		_oPrint:Say( _nLinha , _aColItn2[05] , _aDadFrt[_nX][05] , _oFont03 )																; _oPrint:Line( _nLinha , 1160 , _nLinha + 030 , 1160 )
		_oPrint:Say( _nLinha , _aColItn2[06] , AllTrim( Transform( _aDadFrt[_nX][06] , '@E 999,999,999,999.99'   ) ) , _oFont03 ,,,, 1 )	; _oPrint:Line( _nLinha , 1340 , _nLinha + 030 , 1340 )
		_oPrint:Say( _nLinha , _aColItn2[07] , AllTrim( Transform( _aDadFrt[_nX][07] , '@E 999,999,999,999.99'   ) ) , _oFont03 ,,,, 1 )	; _oPrint:Line( _nLinha , 1560 , _nLinha + 030 , 1560 )
		_oPrint:Say( _nLinha , _aColItn2[08] , AllTrim( Transform( _aDadFrt[_nX][08] , '@E 999,999,999,999.99'   ) ) , _oFont03 ,,,, 1 )	; _oPrint:Line( _nLinha , 1730 , _nLinha + 030 , 1730 )
		_oPrint:Say( _nLinha , _aColItn2[09] , AllTrim( Transform( _aDadFrt[_nX][09] , '@E 999,999,999,999.99'   ) ) , _oFont03 ,,,, 1 )	; _oPrint:Line( _nLinha , 1900 , _nLinha + 030 , 1900 )
		_oPrint:Say( _nLinha , _aColItn2[10] , AllTrim( Transform( _aDadFrt[_nX][10] , '@E 999,999,999,999.99'   ) ) , _oFont03 ,,,, 1 )	; _oPrint:Line( _nLinha , 2130 , _nLinha + 030 , 2130 )
		_oPrint:Say( _nLinha , _aColItn2[11] , AllTrim( Transform( _aDadFrt[_nX][11] , '@E 999,999,999,999.9999' ) ) , _oFont03 ,,,, 1 ) 
		
	Next _nX
	
	_nLinha += 030
	RGLT060VPG( @_oPrint , @_nLinha , .T. )
	
	_oPrint:Line( _nLinha       , 0050 , _nLinha       , 2350 )
	_oPrint:Line( _nLinha       , 0050 , _nLinha + 030 , 0050 )
	_oPrint:Line( _nLinha       , 2350 , _nLinha + 030 , 2350 )
	_oPrint:Line( _nLinha + 030 , 0050 , _nLinha + 030 , 2350 )
	
	_oPrint:Say( _nLinha , _aColItn2[01] , 'Total Geral:'																	, _oFont03B )			; _oPrint:Line( _nLinha , 1340 , _nLinha + 030 , 1340 )
	_oPrint:Say( _nLinha , _aColItn2[07] , AllTrim( Transform( _aTotFrt[02]					, '@E 999,999,999,999.99'   ) ) , _oFont03B ,,,, 1 )	; _oPrint:Line( _nLinha , 1560 , _nLinha + 030 , 1560 )
	_oPrint:Say( _nLinha , _aColItn2[08] , AllTrim( Transform( _aTotFrt[03]					, '@E 999,999,999,999.99'   ) ) , _oFont03B ,,,, 1 )	; _oPrint:Line( _nLinha , 1730 , _nLinha + 030 , 1730 )
	_oPrint:Say( _nLinha , _aColItn2[09] , AllTrim( Transform( _aTotFrt[04]					, '@E 999,999,999,999.99'   ) ) , _oFont03B ,,,, 1 )	; _oPrint:Line( _nLinha , 1900 , _nLinha + 030 , 1900 )
	_oPrint:Say( _nLinha , _aColItn2[10] , AllTrim( Transform( _aTotFrt[05]					, '@E 999,999,999,999.99'   ) ) , _oFont03B ,,,, 1 )	; _oPrint:Line( _nLinha , 2130 , _nLinha + 030 , 2130 )
	_oPrint:Say( _nLinha , _aColItn2[11] , AllTrim( Transform( _aTotFrt[06] / Len(_aDadFrt) , '@E 999,999,999,999.9999' ) ) , _oFont03B ,,,, 1 ) 	; 
	
	_nLinha += 070
	RGLT060VPG( @_oPrint , @_nLinha , .T. )
	
	_oPrint:Say( _nLinha , 060 , "> Resumo por transportadora" , _oFont01 )
	
	_nLinha += 070
	RGLT060VPG( @_oPrint , @_nLinha , .T. )
	
	_oPrint:Line( _nLinha       , 0050 , _nLinha       , 2350 )
	_oPrint:Line( _nLinha       , 0050 , _nLinha + 040 , 0050 )
	_oPrint:Line( _nLinha       , 2350 , _nLinha + 040 , 2350 )
	_oPrint:Line( _nLinha + 040 , 0050 , _nLinha + 040 , 2350 )
	
	_oPrint:Say( _nLinha + 005 , 0060 , 'Transportadora'	, _oFont03B ) ; _oPrint:Line( _nLinha , 0540 , _nLinha + 040 , 0540 )
	_oPrint:Say( _nLinha + 005 , 0550 , 'Qtd. Viagens'		, _oFont03B ) ; _oPrint:Line( _nLinha , 0840 , _nLinha + 040 , 0840 )
	_oPrint:Say( _nLinha + 005 , 0850 , 'Vol. Transp.'		, _oFont03B ) ; _oPrint:Line( _nLinha , 1140 , _nLinha + 040 , 1140 )
	_oPrint:Say( _nLinha + 005 , 1150 , 'Valor Frete'		, _oFont03B ) ; _oPrint:Line( _nLinha , 1440 , _nLinha + 040 , 1440 )
	_oPrint:Say( _nLinha + 005 , 1450 , 'Pedágio'			, _oFont03B ) ; _oPrint:Line( _nLinha , 1740 , _nLinha + 040 , 1740 )
	_oPrint:Say( _nLinha + 005 , 1750 , 'ICMS'				, _oFont03B ) ; _oPrint:Line( _nLinha , 2040 , _nLinha + 040 , 2040 )
	_oPrint:Say( _nLinha + 005 , 2050 , 'Total Prest.'		, _oFont03B )
	
	_aTotFrt := { 0 , 0 , 0 , 0 , 0 , 0 }
	
	_nLinha += 040
	RGLT060VPG( @_oPrint , @_nLinha , .T. )
	
	For _nX := 1 To Len( _aResFrt )
		
		_oPrint:Line( _nLinha       , 0050 , _nLinha       , 2350 )
		_oPrint:Line( _nLinha       , 0050 , _nLinha + 030 , 0050 )
		_oPrint:Line( _nLinha       , 2350 , _nLinha + 030 , 2350 )
		_oPrint:Line( _nLinha + 030 , 0050 , _nLinha + 030 , 2350 )
		
		_oPrint:Say( _nLinha , 0060 , _aResFrt[_nX][02]	, _oFont03 ) ; _oPrint:Line( _nLinha , 0540 , _nLinha + 030 , 0540 )
		_oPrint:Say( _nLinha , 0800 , AllTrim( Transform( _aResFrt[_nX][03] , '@E 999,999,999,999'   ) ) 	, _oFont03 ,,,, 1 ) ; _oPrint:Line( _nLinha , 0840 , _nLinha + 030 , 0840 )
		_oPrint:Say( _nLinha , 1100 , AllTrim( Transform( _aResFrt[_nX][04] , '@E 999,999,999,999'   ) ) 	, _oFont03 ,,,, 1 ) ; _oPrint:Line( _nLinha , 1140 , _nLinha + 030 , 1140 )
		_oPrint:Say( _nLinha , 1400 , AllTrim( Transform( _aResFrt[_nX][06] , '@E 999,999,999,999.99') ) 	, _oFont03 ,,,, 1 ) ; _oPrint:Line( _nLinha , 1440 , _nLinha + 030 , 1440 )
		_oPrint:Say( _nLinha , 1700 , AllTrim( Transform( _aResFrt[_nX][07] , '@E 999,999,999,999.99') ) 	, _oFont03 ,,,, 1 ) ; _oPrint:Line( _nLinha , 1740 , _nLinha + 030 , 1740 )
		_oPrint:Say( _nLinha , 2000 , AllTrim( Transform( _aResFrt[_nX][08] , '@E 999,999,999,999.99') ) 	, _oFont03 ,,,, 1 ) ; _oPrint:Line( _nLinha , 2040 , _nLinha + 030 , 2040 )
		_oPrint:Say( _nLinha , 2300 , AllTrim( Transform( _aResFrt[_nX][09] , '@E 999,999,999,999.99') ) 	, _oFont03 ,,,, 1 )
		
		_aTotFrt[01] += _aResFrt[_nX][03]
		_aTotFrt[02] += _aResFrt[_nX][04]
		_aTotFrt[03] += _aResFrt[_nX][06]
		_aTotFrt[04] += _aResFrt[_nX][07]
		_aTotFrt[05] += _aResFrt[_nX][08]
		_aTotFrt[06] += _aResFrt[_nX][09]
		
		_nLinha += 030
		RGLT060VPG( @_oPrint , @_nLinha , .T. )
		
	Next _nX
	
	_oPrint:Line( _nLinha       , 0050 , _nLinha       , 2350 )
	_oPrint:Line( _nLinha       , 0050 , _nLinha + 040 , 0050 )
	_oPrint:Line( _nLinha       , 2350 , _nLinha + 040 , 2350 )
	_oPrint:Line( _nLinha + 040 , 0050 , _nLinha + 040 , 2350 )
	
	_oPrint:Say( _nLinha + 005 , 0060 , 'Total:'														, _oFont03B        ) ; _oPrint:Line( _nLinha , 0540 , _nLinha + 040 , 0540 )
	_oPrint:Say( _nLinha + 005 , 0800 , AllTrim( Transform( _aTotFrt[01] , '@E 999,999,999,999'    ) ) 	, _oFont03B ,,,, 1 ) ; _oPrint:Line( _nLinha , 0840 , _nLinha + 040 , 0840 )
	_oPrint:Say( _nLinha + 005 , 1100 , AllTrim( Transform( _aTotFrt[02] , '@E 999,999,999,999'    ) ) 	, _oFont03B ,,,, 1 ) ; _oPrint:Line( _nLinha , 1140 , _nLinha + 040 , 1140 )
	_oPrint:Say( _nLinha + 005 , 1400 , AllTrim( Transform( _aTotFrt[03] , '@E 999,999,999,999.99' ) ) 	, _oFont03B ,,,, 1 ) ; _oPrint:Line( _nLinha , 1440 , _nLinha + 040 , 1440 )
	_oPrint:Say( _nLinha + 005 , 1700 , AllTrim( Transform( _aTotFrt[04] , '@E 999,999,999,999.99' ) ) 	, _oFont03B ,,,, 1 ) ; _oPrint:Line( _nLinha , 1740 , _nLinha + 040 , 1740 )
	_oPrint:Say( _nLinha + 005 , 2000 , AllTrim( Transform( _aTotFrt[05] , '@E 999,999,999,999.99' ) ) 	, _oFont03B ,,,, 1 ) ; _oPrint:Line( _nLinha , 2040 , _nLinha + 040 , 2040 )
	_oPrint:Say( _nLinha + 005 , 2300 , AllTrim( Transform( _aTotFrt[06] , '@E 999,999,999,999.99' ) ) 	, _oFont03B ,,,, 1 )
	
Next _nI

//====================================================================================================
// Executa o objeto de impressão
//====================================================================================================
_oPrint:Preview()

Return

/*
===============================================================================================================================
Programa--------: RGLT060VPG
Autor-----------: Darcio Ribeiro Spörl
Data da Criacao-: 18/07/2016
Descrição-------: Validação do pocicionamento da página atual para quebras
Parametros------: oPrint	- Objeto de Impressão do Relatório
----------------: nLinha	- Variável de controle do posicionamento
----------------: lFinPag	- Determina se deve encerrar a página atual
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function RGLT060VPG( _oPrint , _nLinha , _lFinPag )

Local _nLimPag		:= 3400
Local _lRet			:= .F.

Default _lFinPag	:= .T.

If _nLinha > _nLimPag

	//====================================================================================================
	// Verifica se encerra a página atual
	//====================================================================================================
	If _lFinPag
		_oPrint:EndPage()
		_lRet := .T.
	EndIf
	
	//====================================================================================================
	// Inicializa a nova página e o posicionamento
	//====================================================================================================
	_oPrint:StartPage()
	_nLinha	:= 280
	_nNumPag++
	
	//====================================================================================================
	// Insere logo no cabecalho
	//====================================================================================================
	If File( "LGRL01.BMP" )
		_oPrint:SayBitmap( 060 , 020 , "LGRL01.BMP" , 410 , 140 )
	EndIf
	
	//====================================================================================================
	// Imprime quadro do Título
	//====================================================================================================
	_oPrint:Line( 050 , 0050 , 050 , 2350 )
	_oPrint:Line( 200 , 0050 , 200 , 2350 )
	_oPrint:Line( 050 , 0050 , 200 , 0050 )
	_oPrint:Line( 050 , 2350 , 200 , 2350 )
	
	_oPrint:Say( 060 , 0420 , AllTrim( SM0->M0_NOMECOM )	 							 						, _oFont01 )
	_oPrint:Say( 120 , 0420 , 'Endereço: '+		AllTrim( SM0->M0_ENDCOB		) + AllTrim( SM0->M0_COMPCOB )		, _oFont02 )
	_oPrint:Say( 120 , 1500 , 'Bairro: '+		AllTrim( SM0->M0_BAIRCOB	)									, _oFont02 )
	_oPrint:Say( 120 , 1900 , 'Cidade: '+		AllTrim( SM0->M0_CIDCOB		) +' / '+ AllTrim( SM0->M0_ESTCOB )	, _oFont02 )
	_oPrint:Say( 160 , 0420 , 'Telefone: '+		AllTrim( SM0->M0_TEL		)									, _oFont02 )
	_oPrint:Say( 160 , 1100 , 'CNPJ: '+			Transform( SM0->M0_CGC		, '@R! NN.NNN.NNN/NNNN-99' )	  		, _oFont02 )
	_oPrint:Say( 160 , 1500 , 'Inscr.Est.: '+	AllTrim( SM0->M0_INSC )											, _oFont02 )
	
	_nLinha := 230
	
EndIf

Return( _lRet )
