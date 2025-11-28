/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |14/03/2017| Chamado 19233. Incluída a coluna de vencimento.
Lucas Borges  |13/06/2019| Chamado 28346. Revisão de fontes.
Lucas Borges  |27/09/2019| Chamado 28346. Revisão de fontes.
===============================================================================================================================
*/

#Include "TOTVS.ch"

#Define TITULO	"Recepção do Leite de Terceiros - Fatura de Frete"

/*
===============================================================================================================================
Programa--------: RGLT013
Autor-----------: Alexandre Villar
Data da Criacao-: 13/07/2015
Descrição-------: Relatório dos registros de recebimentos de leite de terceiros - Detalhamento por Frete
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function RGLT013()

Local _aCabec1		:= { 'Transportadora', 'Capac.' , 'Número' , 'Valor do' , 'Pedágio' , 'ICMS' , ' Total' , 'Acrésc./' , 'Dia Mov.' , 'Placa' , 'Cód. da' , 'Fornecedor' , 'Núm. NF' , '   Vol.' , 'Custo' ," Data" }
Local _aCabec2		:= { ''              , ''       , '    CTE', '  Frete'  , ''        , ''     , 'Prest.' , 'Desconto' , ''         , ''      , 'Recep.'  , ''           , ''        , 'Transp.' , 'Frete' ,"Vencto"}

Local _aColItnST    := { 0050            , 0600     , 0690      , 1000       , 1200      , 1400   , 1600     , 1800       , 1935       , 2020    , 2200      , 2400         , 2850      , 3120      , 3300 }
Local _aColCab		:= ARRAY(Len(_aCabec1))
Local _aColItn	    := ARRAY(Len(_aCabec2))
Local _aDados		:= {}
Local _cPerg		:= "RGLT013"
Local _nOpca		:= 0
Local _aSays		:= {}
Local _aButtons		:= {}

_aColCab[01]:=50
_aColCab[02]:=_aColCab[01]+380//0500
_aColCab[03]:=_aColCab[02]+200//0700
_aColCab[04]:=_aColCab[03]+200//0900
_aColCab[05]:=_aColCab[04]+200//1100
_aColCab[06]:=_aColCab[05]+200//1300
_aColCab[07]:=_aColCab[06]+200//1500
_aColCab[08]:=_aColCab[07]+200//1700
_aColCab[09]:=_aColCab[08]+200//1900
_aColCab[10]:=_aColCab[09]+150//2050
_aColCab[11]:=_aColCab[10]+150//2200
_aColCab[12]:=_aColCab[11]+200//2400
_aColCab[13]:=_aColCab[12]+400//2850
_aColCab[14]:=_aColCab[13]+200//3050
_aColCab[15]:=_aColCab[14]+160//3200
_aColCab[16]:=_aColCab[15]+150

_aColItn[01]:=50
_aColItn[02]:=_aColItn[01]+480//0600
_aColItn[03]:=_aColItn[02]+090//0690
_aColItn[04]:=_aColItn[03]+310//1000
_aColItn[05]:=_aColItn[04]+200//1200
_aColItn[06]:=_aColItn[05]+200//1400
_aColItn[07]:=_aColItn[06]+200//1600
_aColItn[08]:=_aColItn[07]+200//1800
_aColItn[09]:=_aColItn[08]+135//1935
_aColItn[10]:=_aColItn[09]+085//2020
_aColItn[11]:=_aColItn[10]+180//2200
_aColItn[12]:=_aColItn[11]+200//2400
_aColItn[13]:=_aColItn[12]+400//2850
_aColItn[14]:=_aColItn[13]+270//3120
_aColItn[15]:=_aColItn[14]+180//3300
_aColItn[16]:=_aColItn[15]+050

//SET DATE FORMAT TO "DD/MM/YYYY"

Pergunte( _cPerg , .F. )

aAdd( _aSays , OemToAnsi( "Este programa tem como objetivo gerar o relatório de registros da recepção de leite "	) )
aAdd( _aSays , OemToAnsi( "de terceiros: fatura de frete. "															) )

aAdd( _aButtons , { 5 , .T. , {| | Pergunte( _cPerg )			} } )
aAdd( _aButtons , { 1 , .T. , {|o| _nOpca := 1 , o:oWnd:End()	} } )
aAdd( _aButtons , { 2 , .T. , {|o| _nOpca := 0 , o:oWnd:End()	} } )

FormBatch( "RGLT013" , _aSays , _aButtons ,, 155 , 500 )

If _nOpca == 1

	Processa( {|| _aDados := RGLT013SEL() } , "Aguarde!" , "Selecionando registros das recepções..." )
	
	If Empty(_aDados)
		MessageBox( "Não foram encontrados registros para exibir! Verifique os parâmetros e tente novamente." , "RGLT01301" , 48 )
	Else
		Processa( {|| RGLT013PRT( _aCabec1 , _aCabec2 , _aColCab , _aColItn , _aDados , _aColItnST) } , 'Aguarde!' , 'Imprimindo registros...' )
	EndIf

Else
	MsgInfo( 'Operação cancelada pelo usuário!' , 'RGLT01302' )
EndIf

Return

/*
===============================================================================================================================
Programa--------: RGLT013SEL
Autor-----------: Alexandre Villar
Data da Criacao-: 13/07/2015
Descrição-------: Função para consulta e preparação dos dados do relatório
Parametros------: Nenhum
Retorno---------: _aRet - Dados do relatório
===============================================================================================================================
*/
Static Function RGLT013SEL()

Local _aRet			:= {}
Local _cAlias		:= GetNextAlias()
Local _cFiltro		:= '%'
Local _nTotReg		:= 0
Local _nRegAtu		:= 0

If MV_PAR03 < 4
	_cFiltro += IIf( !Empty( MV_PAR03 ) , " AND ZLX.ZLX_TIPOLT = '"+ IIf( MV_PAR03 == 1 , 'F' , IIf( MV_PAR03 == 2 , 'T' , 'P' ) ) +"' ","")
EndIf

_cFiltro += IIf( !Empty( MV_PAR04 ) , " AND ZZX.ZZX_CODPRD IN "+ FormatIn( AllTrim(MV_PAR04) , ';' ),"")
_cFiltro += IIf( !Empty( MV_PAR13 ) , " AND ZLX.ZLX_PLACA  IN "+ FormatIn( MV_PAR13 , ';' ),"")
_cFiltro += IIf( !Empty( MV_PAR14 ) , " AND ZZV.ZZV_FXCAPA IN "+ FormatIn( MV_PAR14 , ';' ),"")
_cFiltro += IIf( !Empty( MV_PAR19 ) , " AND ZLX.ZLX_STATUS IN "+ FormatIn( MV_PAR19 , ';' ),"")
_cFiltro += "%"

BeginSql alias _cAlias
 SELECT ZZX.ZZX_CODPRD, A2T.A2_NREDUZ TRANSP, ZZV.ZZV_CAPACI, ZLX.ZLX_CTE, ZLX.ZLX_CTESER, ZLX.ZLX_VLRFRT, ZLX.ZLX_PEDAGI,
        ZLX.ZLX_ICMSFR, ZLX.ZLX_TVLFRT, ZLX.ZLX_ADCFRT, SubStr(ZLX.ZLX_DTENTR, 7, 2) DIA, ZLX.ZLX_PLACA, ZLX.ZLX_CODIGO,
        A2F.A2_NREDUZ FORNECE, ZLX.ZLX_NRONF, ZLX.ZLX_VOLREC, Round((ZLX.ZLX_VLRFRT + ZLX.ZLX_PEDAGI) / ZLX.ZLX_VOLREC, 4) CUSTO_FRETE,
        NVL((SELECT MAX(SE2.E2_VENCREA)
              FROM %Table:SE2% SE2
             WHERE SE2.D_E_L_E_T_ = ' '
               AND SE2.E2_FILIAL = %xFilial:SE2%
               AND SE2.E2_PREFIXO = ZLX.ZLX_CTESER
               AND SE2.E2_NUM = ZLX.ZLX_CTE
               AND SE2.E2_FORNECE = ZLX.ZLX_TRANSP
               AND SE2.E2_LOJA = ZLX.ZLX_LJTRAN),
            ' ') AS VENCTO
   FROM %Table:ZLX% ZLX, %Table:SA2% A2T, %Table:SA2% A2F, %Table:ZZX% ZZX, %Table:ZZV% ZZV
  WHERE ZLX.D_E_L_E_T_ = ' '
    AND ZZX.D_E_L_E_T_ = ' '
    AND ZZV.D_E_L_E_T_ = ' '
    AND A2T.D_E_L_E_T_ = ' '
    AND A2F.D_E_L_E_T_ = ' '
    AND ZLX.ZLX_FILIAL = %xFilial:ZLX%
    AND ZZX.ZZX_FILIAL = %xFilial:ZZX%
    AND ZZV.ZZV_FILIAL = %xFilial:ZZV%
    AND A2T.A2_FILIAL = %xFilial:SA2%
    AND A2F.A2_FILIAL = %xFilial:SA2%
    AND ZLX.ZLX_FILIAL = ZZX.ZZX_FILIAL
    AND ZZX.ZZX_FILIAL = ZZV.ZZV_FILIAL
    AND ZLX.ZLX_FORNEC = A2F.A2_COD
    AND ZLX.ZLX_LJFORN = A2F.A2_LOJA
    AND ZLX.ZLX_TRANSP = A2T.A2_COD
    AND ZLX.ZLX_LJTRAN = A2T.A2_LOJA
    AND ZZX.ZZX_CODIGO = ZLX.ZLX_CODANA
    AND ZZX.ZZX_PLACA = ZZV.ZZV_PLACA
    AND ZZX.ZZX_TRANSP = ZZV.ZZV_TRANSP
    AND ZZX.ZZX_LJTRAN = ZZV.ZZV_LJTRAN
    AND ZLX.ZLX_PGFRT = 'S'
    %exp:_cFiltro%
    AND ZLX.ZLX_DTENTR BETWEEN %exp:MV_PAR01% AND %exp:MV_PAR02%
    AND ZLX.ZLX_FORNEC BETWEEN %exp:MV_PAR05% AND %exp:MV_PAR07%
    AND ZLX.ZLX_LJFORN BETWEEN %exp:MV_PAR06% AND %exp:MV_PAR08%
    AND ZLX.ZLX_TRANSP BETWEEN %exp:MV_PAR09% AND %exp:MV_PAR11%
    AND ZLX.ZLX_LJTRAN BETWEEN %exp:MV_PAR10% AND %exp:MV_PAR12%
    AND ZLX.ZLX_NRONF BETWEEN %exp:MV_PAR15% AND %exp:MV_PAR16%
    AND ZLX.ZLX_CODIGO BETWEEN %exp:MV_PAR17% AND %exp:MV_PAR18%
  ORDER BY A2T.A2_NREDUZ, ZZX.ZZX_CODPRD, ZLX.ZLX_CTE, ZLX.ZLX_CTESER
EndSql

(_cAlias)->( DBEval( {|| _nTotReg++ } ) )
(_cAlias)->( DBGoTop() )

ProcRegua(_nTotReg)
While (_cAlias)->( !Eof() )
	
	_nRegAtu++
	IncProc( "Lendo registros: ["+ StrZero( _nRegAtu , 6 ) +"] de ["+ StrZero( _nTotReg , 6 ) +"]" )
	
	aAdd( _aRet , {				(_cAlias)->ZZX_CODPRD																	,; //   - Codigo de Produto (não mostra)
					AllTrim(	(_cAlias)->TRANSP )																		,; //01 - Nome do Fornecedor
	AllTrim( Transform(	Val(	(_cAlias)->ZZV_CAPACI )			 						, '@E 999,999,999,999'      ) )	,; //02 - Capacidade do Veículo
					AllTrim(	(_cAlias)->ZLX_CTE )																	,; //03 - Número do CTE
			AllTrim( Transform(	(_cAlias)->ZLX_VLRFRT								    , '@E 999,999,999,999.99'   ) )	,; //04 - Valor do Frete
			AllTrim( Transform(	(_cAlias)->ZLX_PEDAGI								    , '@E 999,999,999,999.99'   ) )	,; //05 - Valor de Pedágio
			AllTrim( Transform(	(_cAlias)->ZLX_ICMSFR						    		, '@E 999,999,999,999.99'   ) )	,; //06 - ICMS do Frete
			AllTrim( Transform(	(_cAlias)->ZLX_TVLFRT									, '@E 999,999,999,999.99'   ) ) ,; //07 - Total do Frete
			AllTrim( Transform(	(_cAlias)->ZLX_ADCFRT								    , '@E 999,999,999,999.99'   ) )	,; //08 - Adicional do Frete
					AllTrim(	(_cAlias)->DIA )																		,; //09 - Nome do Transportador
   					AllTrim(	(_cAlias)->ZLX_PLACA )																	,; //10 - Placa do veículo
					AllTrim(	(_cAlias)->ZLX_CODIGO )																	,; //11 - Número da NF
					AllTrim(	(_cAlias)->FORNECE )																	,; //12 - Nome do Transportador
					AllTrim(	(_cAlias)->ZLX_NRONF )																	,; //13 - Volume NF
			AllTrim( Transform(	(_cAlias)->ZLX_VOLREC									, '@E 999,999,999,999'      ) )	,; //14 - Volume Recebido
			AllTrim( Transform(	(_cAlias)->CUSTO_FRETE									, '@E 999,999,999,999.9999' ) )	,; //15 - Procedencia
			          If(Empty( (_cAlias)->VENCTO ),"        ",DToC(SToD((_cAlias)->VENCTO)))     	  					}) //16 - Data de VEnciemnto 

	(_cAlias)->( DBSkip() )
EndDo

(_cAlias)->( DBCloseArea() )

Return( _aRet )

/*
===============================================================================================================================
Programa--------: RGLT013PRT
Autor-----------: Alexandre Villar
Data da Criacao-: 13/07/2015
Descrição-------: Função para controlar e imprimir os dados do relatório
Parametros------: _aCabec1 - Primeira linha dos dados de cabeçalho
----------------: _aCabec2 - Segunda linha dos dados de cabeçalho
----------------: _aColCab - Posicionamento dos dados de cabeçalho
----------------: _aColItn - Ajuste do posicionamento dos dados
----------------: _aDados  - Dados do relatório
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function RGLT013PRT( _aCabec1 , _aCabec2 , _aColCab , _aColItn , _aDados , _aColItnST )

Local _aTotGer	:= {0,0,0,0,0,0,0,0}
Local _aResTot	:= {}
Local _aFretes	:= {}
Local _nLinha	:= 300
Local _nTotCol	:= Len(_aCabec1)
Local _nI		:= 0
Local _nX		:= 0
Local _oPrint	:= Nil
Local _cCodPro	:= ''
Local _cTipPrd	:= ''
Local _cCodTrn	:= ''
Local _nColAux	:= 0
Local _nConTot	:= 0
Local _nTotFrt	:= 0
Local _nTotPed	:= 0
Local _nTotICM	:= 0
Local _nTotPre	:= 0
Local _nTotAcr	:= 0
Local _nTotVol	:= 0
Local _nTotCst	:= 0

Local _nTtfVol := 0
Local _nTtfVal := 0
Local _nTtfPed := 0
Local _nTtfIcm := 0
Local _nTtfFrt := 0
Local _nTtfCus := 0

Local _nTtgVol := 0
Local _nTtgVal := 0
Local _nTtgPed := 0
Local _nTtgIcm := 0
Local _nTtgFrt := 0
Local _nTtgCus := 0
Private _oFont01	:= TFont():New( "Tahoma" ,, 14 , .F. , .T. ,, .T. ,, .T. , .F. )
Private _oFont02	:= TFont():New( "Tahoma" ,, 08 , .F. , .T. ,, .T. ,, .T. , .F. )
Private _oFont03	:= TFont():New( "Tahoma" ,, 08 , .F. , .F. ,, .T. ,, .T. , .F. )
Private _oFont03B	:= TFont():New( "Tahoma" ,, 08 , .F. , .T. ,, .T. ,, .T. , .F. )

//====================================================================================================
// Inicializa o objeto do relatório
//====================================================================================================
_oPrint := TMSPrinter():New( TITULO )
//_oPrint:Setup()
_oPrint:SetLandscape()
_oPrint:SetPaperSize(9)
//====================================================================================================
// Processa a impressão dos dados
//====================================================================================================
ProcRegua(Len( _aDados ))
_nRegAtu:=0
_cTot:=AllTrim(Str( Len( _aDados ) ))
For _nI := 1 To Len( _aDados )
	
	//====================================================================================================
	// Inicializa a primeira página do relatório
	//====================================================================================================
	_nRegAtu++
	IncProc( "Lendo registros: ["+ AllTrim(Str( _nRegAtu )) +"] de ["+_cTot+"]" )
	If _nI == 1

		_nLinha		:= 50000
		
		RGLT013VPG( @_oPrint , @_nLinha , .F. )
		
		If _cTipPrd <> _aDados[_nI][01]
			
			_cTipPrd := _aDados[_nI][01]
			_cCodTrn := _aDados[_nI][02]
			
			_nLinha += 040
			
			_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
			_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
			_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
			_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
			
			_nLinha += 010
			
			_oPrint:Say( _nLinha , _aColItn[01] , 'Recepção de '+ Posicione('SX5',1,xFilial('SX5')+'Z7'+PadR(_aDados[_nI][01],TamSX3('X5_CHAVE')[01]),'X5_DESCRI') , _oFont02 )
			_nLinha += 060
			
		EndIf
		
		If _nTotCol > 0
		
			For _nX := 1 To _nTotCol
				_oPrint:Say( IIf( Empty( _aCabec2[_nX] ) , _nLinha + 07 , _nLinha ) , _aColCab[_nX] , _aCabec1[_nX] , _oFont02 )
			Next _nX
			
			_nLinha += 030
			
			For _nX := 1 To _nTotCol
				If !Empty( _aCabec2[_nX] )
					_oPrint:Say( _nLinha , _aColCab[_nX] , _aCabec2[_nX] , _oFont02 )
				EndIf
			Next _nX
			
			_nLinha += 050
			
			_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
			_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
			
			_nLinha += 010
			
		EndIf
		
	//=============================================================================
	//| Encerra Lote do Setor atual                                               |
	//=============================================================================	
	ElseIf _nLinha > 2100
		
		_nLinha := 50000
		//=============================================================================
		//| Verifica o posicionamento da página                                       |
		//=============================================================================
		RGLT013VPG( @_oPrint , @_nLinha , .T. )
		
		If _cCodTrn <> _aDados[_nI][02]
			
			_nLinha += 035
			_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha += 10
			
			_oPrint:Say( _nLinha , _aColCab[01] , 'Sub-Total ('+ cValToChar(_nConTot) + IIf( _nConTot == 1 , ' viagem' , ' viagens' ) +')'	, _oFont03 )
			_oPrint:Say( _nLinha , _aColItn[04] , Transform( _nTotFrt				, '@E 999,999,999.99' )									, _oFont03 ,,,, 1 )
			_oPrint:Say( _nLinha , _aColItn[05] , Transform( _nTotPed				, '@E 999,999,999.99' )									, _oFont03 ,,,, 1 )
			_oPrint:Say( _nLinha , _aColItn[06] , Transform( _nTotICM				, '@E 999,999,999.99' )									, _oFont03 ,,,, 1 )
			_oPrint:Say( _nLinha , _aColItn[07] , Transform( _nTotPre				, '@E 999,999,999.99' )									, _oFont03 ,,,, 1 )
			_oPrint:Say( _nLinha , _aColItn[08] , Transform( _nTotAcr				, '@E 999,999,999.99' )									, _oFont03 ,,,, 1 )
			_oPrint:Say( _nLinha , _aColItn[14] , Transform( _nTotVol				, '@E 999,999,999' ) +' L'								, _oFont03 ,,,, 1 )
			_oPrint:Say( _nLinha , _aColItn[15] , Transform( _nTotCst / _nConTot	, '@E 999,999,999.9999' ) 								, _oFont03 ,,,, 1 )
			
			_aTotGer[01] += _nConTot
			_aTotGer[02] += _nTotFrt
			_aTotGer[03] += _nTotPed
			_aTotGer[04] += _nTotICM
			_aTotGer[05] += _nTotPre
			_aTotGer[06] += _nTotAcr
			_aTotGer[07] += _nTotVol
			_aTotGer[08] += _nTotCst
			
			_nLinha += 100
			
			_oPrint:Say( _nLinha , _aColCab[01] , 'Total Geral ('+ cValToChar(_aTotGer[01]) + IIf( _aTotGer[01] == 1 , ' viagem' , ' viagens' ) +')'	, _oFont03 )
			_oPrint:Say( _nLinha , _aColItn[04] , Transform( _aTotGer[02]					, '@E 999,999,999.99' )										, _oFont03 ,,,, 1 )
			_oPrint:Say( _nLinha , _aColItn[05] , Transform( _aTotGer[03]					, '@E 999,999,999.99' )										, _oFont03 ,,,, 1 )
			_oPrint:Say( _nLinha , _aColItn[06] , Transform( _aTotGer[04]					, '@E 999,999,999.99' )										, _oFont03 ,,,, 1 )
			_oPrint:Say( _nLinha , _aColItn[07] , Transform( _aTotGer[05]					, '@E 999,999,999.99' )										, _oFont03 ,,,, 1 )
			_oPrint:Say( _nLinha , _aColItn[08] , Transform( _aTotGer[06]					, '@E 999,999,999.99' )										, _oFont03 ,,,, 1 )
			_oPrint:Say( _nLinha , _aColItn[14] , Transform( _aTotGer[07]					, '@E 999,999,999' ) +' L'									, _oFont03 ,,,, 1 )
			_oPrint:Say( _nLinha , _aColItn[15] , Transform( _aTotGer[08] / _aTotGer[01]	, '@E 999,999,999.9999' ) 									, _oFont03 ,,,, 1 )
			
			_nLinha += 100
			
			_oPrint:Say( _nLinha , _aColCab[01] , 'Valor a Pagar: '+ Transform( _aTotGer[05] , '@E 999,999,999.99' ) , _oFont03 )
			
			_nLinha += 100
			
			_oPrint:Say( _nLinha , _aColCab[01] + 0150 , '______________________________________________________________' , _oFont03 )
			_oPrint:Say( _nLinha , _aColCab[01] + 1450 , '______________________________________________________________' , _oFont03 ) ; _nLinha += 25
			_oPrint:Say( _nLinha , _aColCab[01] + 0470 , 'Departamento do Leite'   , _oFont03 )
			_oPrint:Say( _nLinha , _aColCab[01] + 1780 , 'Departamento Financeiro' , _oFont03 )
			
			_nLinha := 5000
			
			RGLT013VPG( @_oPrint , @_nLinha , .T. )
			
			_aTotGer := {0,0,0,0,0,0,0,0}
			_nConTot := _nTotFrt := _nTotPed := _nTotICM := _nTotPre := _nTotAcr := _nTotVol := _nTotCst := 0
			
			_cTipPrd := _aDados[_nI][01]
			_cCodTrn := _aDados[_nI][02]
			
			_nLinha += 040
			
			_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
			_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
			_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
			_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
			
			_nLinha += 010
			
			_oPrint:Say( _nLinha , _aColItn[01] , 'Recepção de '+ Posicione('SX5',1,xFilial('SX5')+'Z7'+PadR(_aDados[_nI][01],TamSX3('X5_CHAVE')[01]),'X5_DESCRI') , _oFont02 )
			_nLinha += 060
			
		ElseIf _cTipPrd <> _aDados[_nI][01]
			
			_cTipPrd := _aDados[_nI][01]
			
			_nLinha += 035
			_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha += 10
			
			_oPrint:Say( _nLinha , _aColCab[01] , 'Sub-Total ('+ cValToChar(_nConTot) + IIf( _nConTot == 1 , ' viagem' , ' viagens' ) +')'	, _oFont03 )
			_oPrint:Say( _nLinha , _aColItn[04] , Transform( _nTotFrt				, '@E 999,999,999.99' )									, _oFont03 ,,,, 1 )
			_oPrint:Say( _nLinha , _aColItn[05] , Transform( _nTotPed				, '@E 999,999,999.99' )									, _oFont03 ,,,, 1 )
			_oPrint:Say( _nLinha , _aColItn[06] , Transform( _nTotICM				, '@E 999,999,999.99' )									, _oFont03 ,,,, 1 )
			_oPrint:Say( _nLinha , _aColItn[07] , Transform( _nTotPre				, '@E 999,999,999.99' )									, _oFont03 ,,,, 1 )
			_oPrint:Say( _nLinha , _aColItn[08] , Transform( _nTotAcr				, '@E 999,999,999.99' )									, _oFont03 ,,,, 1 )
			_oPrint:Say( _nLinha , _aColItn[14] , Transform( _nTotVol	 			, '@E 999,999,999' ) +' L'								, _oFont03 ,,,, 1 )
			_oPrint:Say( _nLinha , _aColItn[15] , Transform( _nTotCst / _nConTot	, '@E 999,999,999.9999' ) 								, _oFont03 ,,,, 1 )
			
			_aTotGer[01] += _nConTot
			_aTotGer[02] += _nTotFrt
			_aTotGer[03] += _nTotPed
			_aTotGer[04] += _nTotICM
			_aTotGer[05] += _nTotPre
			_aTotGer[06] += _nTotAcr
			_aTotGer[07] += _nTotVol
			_aTotGer[08] += _nTotCst
			
			_nLinha += 100
			
			_nConTot := _nTotFrt := _nTotPed := _nTotICM := _nTotPre := _nTotAcr := _nTotVol := _nTotCst := 0
			
			_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
			_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
			_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
			_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
			
			_nLinha += 010
			
			_oPrint:Say( _nLinha , _aColItn[01] , 'Recepção de '+ Posicione('SX5',1,xFilial('SX5')+'Z7'+PadR(_aDados[_nI][01],TamSX3('X5_CHAVE')[01]),'X5_DESCRI') , _oFont02 )
			_nLinha += 060
			
		EndIf
			
		If _nTotCol > 0
			
			For _nX := 1 To _nTotCol
				_oPrint:Say( IIf( Empty( _aCabec2[_nX] ) , _nLinha + 07 , _nLinha ) , _aColCab[_nX] , _aCabec1[_nX] , _oFont02 )
			Next _nX
			
			_nLinha += 030
			
			For _nX := 1 To _nTotCol
				If !Empty( _aCabec2[_nX] )
					_oPrint:Say( _nLinha , _aColCab[_nX] , _aCabec2[_nX] , _oFont02 )
				EndIf
			Next _nX
			
			_nLinha += 050
			
			_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
			_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
			
			_nLinha += 010
			
		EndIf
		
	ElseIf _cCodTrn <> _aDados[_nI][02]
		
		_nLinha += 035
		_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha += 10
		
		_oPrint:Say( _nLinha , _aColCab[01] , 'Sub-Total ('+ cValToChar(_nConTot) + IIf( _nConTot == 1 , ' viagem' , ' viagens' ) +')'	, _oFont03 )
		_oPrint:Say( _nLinha , _aColItn[04] , Transform( _nTotFrt				, '@E 999,999,999.99' )									, _oFont03 ,,,, 1 )
		_oPrint:Say( _nLinha , _aColItn[05] , Transform( _nTotPed				, '@E 999,999,999.99' )									, _oFont03 ,,,, 1 )
		_oPrint:Say( _nLinha , _aColItn[06] , Transform( _nTotICM				, '@E 999,999,999.99' )									, _oFont03 ,,,, 1 )
		_oPrint:Say( _nLinha , _aColItn[07] , Transform( _nTotPre				, '@E 999,999,999.99' )									, _oFont03 ,,,, 1 )
		_oPrint:Say( _nLinha , _aColItn[08] , Transform( _nTotAcr				, '@E 999,999,999.99' )									, _oFont03 ,,,, 1 )
		_oPrint:Say( _nLinha , _aColItn[14] , Transform( _nTotVol				, '@E 999,999,999' ) +' L'								, _oFont03 ,,,, 1 )
		_oPrint:Say( _nLinha , _aColItn[15] , Transform( _nTotCst / _nConTot	, '@E 999,999,999.9999' ) 								, _oFont03 ,,,, 1 )
		
		_aTotGer[01] += _nConTot
		_aTotGer[02] += _nTotFrt
		_aTotGer[03] += _nTotPed
		_aTotGer[04] += _nTotICM
		_aTotGer[05] += _nTotPre
		_aTotGer[06] += _nTotAcr
		_aTotGer[07] += _nTotVol
		_aTotGer[08] += _nTotCst
		
		_nLinha += 100
		
		RGLT013VPG( @_oPrint , @_nLinha , .T. )
		
		_oPrint:Say( _nLinha , _aColCab[01] , 'Total Geral ('+ cValToChar(_aTotGer[01]) + IIf( _aTotGer[01] == 1 , ' viagem' , ' viagens' ) +')'	, _oFont03 )
		_oPrint:Say( _nLinha , _aColItn[04] , Transform( _aTotGer[02]					, '@E 999,999,999.99' )										, _oFont03 ,,,, 1 )
		_oPrint:Say( _nLinha , _aColItn[05] , Transform( _aTotGer[03]					, '@E 999,999,999.99' )										, _oFont03 ,,,, 1 )
		_oPrint:Say( _nLinha , _aColItn[06] , Transform( _aTotGer[04]					, '@E 999,999,999.99' )										, _oFont03 ,,,, 1 )
		_oPrint:Say( _nLinha , _aColItn[07] , Transform( _aTotGer[05]					, '@E 999,999,999.99' )										, _oFont03 ,,,, 1 )
		_oPrint:Say( _nLinha , _aColItn[08] , Transform( _aTotGer[06]					, '@E 999,999,999.99' )										, _oFont03 ,,,, 1 )
		_oPrint:Say( _nLinha , _aColItn[14] , Transform( _aTotGer[07]					, '@E 999,999,999' ) +' L'									, _oFont03 ,,,, 1 )
		_oPrint:Say( _nLinha , _aColItn[15] , Transform( _aTotGer[08] / _aTotGer[01]	, '@E 999,999,999.9999' )									, _oFont03 ,,,, 1 )
		
		_nLinha += 100
		
		RGLT013VPG( @_oPrint , @_nLinha , .T. )
		
		_oPrint:Say( _nLinha , _aColCab[01] , 'Valor a Pagar: '+ Transform( _aTotGer[05] , '@E 999,999,999.99' ) , _oFont03 )
		
		_nLinha += 100
		
		RGLT013VPG( @_oPrint , @_nLinha , .T. )
		
		_oPrint:Say( _nLinha , _aColCab[01] + 0150 , '______________________________________________________________' , _oFont03 )
		_oPrint:Say( _nLinha , _aColCab[01] + 1450 , '______________________________________________________________' , _oFont03 ) ; _nLinha += 25
		_oPrint:Say( _nLinha , _aColCab[01] + 0470 , 'Departamento do Leite'   , _oFont03 )
		_oPrint:Say( _nLinha , _aColCab[01] + 1780 , 'Departamento Financeiro' , _oFont03 )
		
		_nLinha := 5000
		
		RGLT013VPG( @_oPrint , @_nLinha , .T. )

		_aTotGer := {0,0,0,0,0,0,0,0}
		_nConTot := _nTotFrt := _nTotPed := _nTotICM := _nTotPre := _nTotAcr := _nTotVol := _nTotCst := 0
		_cTipPrd := _aDados[_nI][01]
		_cCodTrn := _aDados[_nI][02]
		
		_nLinha += 040
		
		_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
		_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
		_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
		_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
		
		_nLinha += 020
		_oPrint:Say( _nLinha , _aColItn[01] , 'Recepção de '+ Posicione('SX5',1,xFilial('SX5')+'Z7'+PadR(_aDados[_nI][01],TamSX3('X5_CHAVE')[01]),'X5_DESCRI') , _oFont02 )
		_nLinha += 050
		
		RGLT013VPG( @_oPrint , @_nLinha , .T. )
		
		If _nTotCol > 0
		
			For _nX := 1 To _nTotCol
				_oPrint:Say( IIf( Empty( _aCabec2[_nX] ) , _nLinha + 07 , _nLinha ) , _aColCab[_nX] , _aCabec1[_nX] , _oFont02 )
			Next _nX
			
			_nLinha += 030
			
			For _nX := 1 To _nTotCol
				If !Empty( _aCabec2[_nX] )
					_oPrint:Say( _nLinha , _aColCab[_nX] , _aCabec2[_nX] , _oFont02 )
				EndIf
			Next _nX
			
			_nLinha += 050
			
			_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
			_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
			
			_nLinha += 010
			
		EndIf
	
	ElseIf _cTipPrd <> _aDados[_nI][01]
	
		_nLinha += 035
		_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha += 10
		
		_oPrint:Say( _nLinha , _aColCab[01] , 'Sub-Total ('+ cValToChar(_nConTot) + IIf( _nConTot == 1 , ' viagem' , ' viagens' ) +')'	, _oFont03 )
		_oPrint:Say( _nLinha , _aColItn[04] , Transform( _nTotFrt				, '@E 999,999,999.99' )									, _oFont03 ,,,, 1 )
		_oPrint:Say( _nLinha , _aColItn[05] , Transform( _nTotPed				, '@E 999,999,999.99' )									, _oFont03 ,,,, 1 )
		_oPrint:Say( _nLinha , _aColItn[06] , Transform( _nTotICM				, '@E 999,999,999.99' )									, _oFont03 ,,,, 1 )
		_oPrint:Say( _nLinha , _aColItn[07] , Transform( _nTotPre				, '@E 999,999,999.99' )									, _oFont03 ,,,, 1 )
		_oPrint:Say( _nLinha , _aColItn[08] , Transform( _nTotAcr				, '@E 999,999,999.99' )									, _oFont03 ,,,, 1 )
		_oPrint:Say( _nLinha , _aColItn[14] , Transform( _nTotVol				, '@E 999,999,999' ) +' L'								, _oFont03 ,,,, 1 )
		_oPrint:Say( _nLinha , _aColItn[15] , Transform( _nTotCst / _nConTot	, '@E 999,999,999.9999' ) 								, _oFont03 ,,,, 1 )
		
		_aTotGer[01] += _nConTot
		_aTotGer[02] += _nTotFrt
		_aTotGer[03] += _nTotPed
		_aTotGer[04] += _nTotICM
		_aTotGer[05] += _nTotPre
		_aTotGer[06] += _nTotAcr
		_aTotGer[07] += _nTotVol
		_aTotGer[08] += _nTotCst
		
		_nLinha += 100
		
		RGLT013VPG( @_oPrint , @_nLinha , .T. )
		
		_nConTot := _nTotFrt := _nTotPed := _nTotICM := _nTotPre := _nTotAcr := _nTotVol := _nTotCst := 0
		_cTipPrd := _aDados[_nI][01]
		_cCodTrn := _aDados[_nI][02]
		
		_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
		_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
		_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
		_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
		
		_nLinha += 020
		_oPrint:Say( _nLinha , _aColItn[01] , 'Recepção de '+ Posicione('SX5',1,xFilial('SX5')+'Z7'+PadR(_aDados[_nI][01],TamSX3('X5_CHAVE')[01]),'X5_DESCRI') , _oFont02 )
		_nLinha += 050
		
		RGLT013VPG( @_oPrint , @_nLinha , .T. )
		
		If _nTotCol > 0
		
			For _nX := 1 To _nTotCol
				_oPrint:Say( IIf( Empty( _aCabec2[_nX] ) , _nLinha + 07 , _nLinha ) , _aColCab[_nX] , _aCabec1[_nX] , _oFont02 )
			Next _nX
			
			_nLinha += 030
			
			For _nX := 1 To _nTotCol
				If !Empty( _aCabec2[_nX] )
					_oPrint:Say( _nLinha , _aColCab[_nX] , _aCabec2[_nX] , _oFont02 )
				EndIf
			Next _nX
			
			_nLinha += 050
			
			_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
			_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
			
			_nLinha += 010
			
		EndIf
	
	Else
	
		_nLinha += 030
		
	EndIf
	
	RGLT013VPG( @_oPrint , @_nLinha , .T. )
	//IMPREASAO DO CORPO DO RELATORIO
	For _nX := 1 To _nTotCol
		_oPrint:Say( _nLinha , _aColItn[_nX] , _aDados[_nI][_nX+1] , _oFont03 ,,,, IIf( StrZero(_nX,2) $ '02;04;05;06;07;08;14;15' , 1 , 0 ) )
	Next _nX
	//IMPREASAO DO CORPO DO RELATORIO
	_nConTot++
	_nTotFrt	+= Val( StrTran( StrTran( _aDados[_nI][05] , '.' , '' ) , ',' , '.' ) )
	_nTotPed	+= Val( StrTran( StrTran( _aDados[_nI][06] , '.' , '' ) , ',' , '.' ) )
	_nTotICM	+= Val( StrTran( StrTran( _aDados[_nI][07] , '.' , '' ) , ',' , '.' ) )
	_nTotPre	+= Val( StrTran( StrTran( _aDados[_nI][08] , '.' , '' ) , ',' , '.' ) )
	_nTotAcr	+= Val( StrTran( StrTran( _aDados[_nI][09] , '.' , '' ) , ',' , '.' ) )
	_nTotVol	+= Val( StrTran( StrTran( _aDados[_nI][15] , '.' , '' ) , ',' , '.' ) )
	_nTotCst	+= Val( StrTran( StrTran( _aDados[_nI][16] , '.' , '' ) , ',' , '.' ) )
	
	aAdd( _aResTot , { _aDados[_nI][02] , _aDados[_nI][01] , Val( StrTran( StrTran( _aDados[_nI][08] , '.' , '' ) , ',' , '.' ) ) } )
	
Next _nI

//=============================================================================
//| Verifica o posicionamento da página                                       |
//=============================================================================
_nLinha += 035
_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha += 10

_oPrint:Say( _nLinha , _aColCab[01] , 'Sub-Total ('+ cValToChar(_nConTot) + IIf( _nConTot == 1 , ' viagem' , ' viagens' ) +')'	, _oFont03 )
_oPrint:Say( _nLinha , _aColItn[04] , Transform( _nTotFrt				, '@E 999,999,999.99' )									, _oFont03 ,,,, 1 )
_oPrint:Say( _nLinha , _aColItn[05] , Transform( _nTotPed				, '@E 999,999,999.99' )									, _oFont03 ,,,, 1 )
_oPrint:Say( _nLinha , _aColItn[06] , Transform( _nTotICM				, '@E 999,999,999.99' )									, _oFont03 ,,,, 1 )
_oPrint:Say( _nLinha , _aColItn[07] , Transform( _nTotPre				, '@E 999,999,999.99' )									, _oFont03 ,,,, 1 )
_oPrint:Say( _nLinha , _aColItn[08] , Transform( _nTotAcr				, '@E 999,999,999.99' )									, _oFont03 ,,,, 1 )
_oPrint:Say( _nLinha , _aColItn[14] , Transform( _nTotVol				, '@E 999,999,999' ) +' L'								, _oFont03 ,,,, 1 )
_oPrint:Say( _nLinha , _aColItn[15] , Transform( _nTotCst / _nConTot	, '@E 999,999,999.9999' ) 								, _oFont03 ,,,, 1 )

_aTotGer[01] += _nConTot
_aTotGer[02] += _nTotFrt
_aTotGer[03] += _nTotPed
_aTotGer[04] += _nTotICM
_aTotGer[05] += _nTotPre
_aTotGer[06] += _nTotAcr
_aTotGer[07] += _nTotVol
_aTotGer[08] += _nTotCst

_nLinha += 050

_nConTot := _nTotFrt := _nTotPed := _nTotICM := _nTotPre := _nTotAcr := _nTotVol := _nTotCst := 0

_nLinha += 100

RGLT013VPG( @_oPrint , @_nLinha , .T. )

_oPrint:Say( _nLinha , _aColCab[01] , 'Total Geral ('+ cValToChar(_aTotGer[01]) + IIf( _aTotGer[01] == 1 , ' viagem' , ' viagens' ) +')'	, _oFont03 )
_oPrint:Say( _nLinha , _aColItn[04] , Transform( _aTotGer[02]				 		, '@E 999,999,999.99' )									, _oFont03 ,,,, 1 )
_oPrint:Say( _nLinha , _aColItn[05] , Transform( _aTotGer[03]				 		, '@E 999,999,999.99' )									, _oFont03 ,,,, 1 )
_oPrint:Say( _nLinha , _aColItn[06] , Transform( _aTotGer[04]				 		, '@E 999,999,999.99' )									, _oFont03 ,,,, 1 )
_oPrint:Say( _nLinha , _aColItn[07] , Transform( _aTotGer[05]				 		, '@E 999,999,999.99' )									, _oFont03 ,,,, 1 )
_oPrint:Say( _nLinha , _aColItn[08] , Transform( _aTotGer[06]				 		, '@E 999,999,999.99' )									, _oFont03 ,,,, 1 )
_oPrint:Say( _nLinha , _aColItn[14] , Transform( _aTotGer[07]				 		, '@E 999,999,999' ) +' L'								, _oFont03 ,,,, 1 )
_oPrint:Say( _nLinha , _aColItn[15] , Transform( ( _aTotGer[08] / _aTotGer[01] )	, '@E 999,999,999.9999' ) 								, _oFont03 ,,,, 1 )

_nLinha += 100

_oPrint:Say( _nLinha , _aColCab[01] , 'Valor a Pagar: '+ Transform( _aTotGer[05] , '@E 999,999,999.99' ) , _oFont03 )

_nLinha += 100

_oPrint:Say( _nLinha , _aColCab[01] + 0150 , '______________________________________________________________' , _oFont03 )
_oPrint:Say( _nLinha , _aColCab[01] + 1450 , '______________________________________________________________' , _oFont03 ) ; _nLinha += 25
_oPrint:Say( _nLinha , _aColCab[01] + 0470 , 'Departamento do Leite'   , _oFont03 )
_oPrint:Say( _nLinha , _aColCab[01] + 1780 , 'Departamento Financeiro' , _oFont03 )

_nLinha := 5000

RGLT013VPG( @_oPrint , @_nLinha , .T. )

_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++

_nLinha += 010

_oPrint:Say( _nLinha , _aColItn[01] , 'Resumo das Faturas de Frete' , _oFont02 )

_nLinha += 060

_oPrint:Say( _nLinha , _aColCab[01] , 'TRANSPORTADORA' , _oFont03 )

_nColAux := 700

_aTotGer := {}

_oPrint:Say( _nLinha , _nColAux 		, 'VALOR DOS TRANSPORTES' , _oFont03 )
_oPrint:Say( _nLinha , _nColAux + 500	, 'TOTAL DE TRANSPORTES'  , _oFont03 )

_nLinha += 035

_aTotal := { 0 , 0 }

For _nI := 1 To Len( _aResTot )
	
	_oPrint:Say( _nLinha , _aColCab[01] , _aResTot[_nI][01] , _oFont03 )
	
	_cCodTrn := _aResTot[_nI][01]
	
	_nTotGer := 0
	_nConTot := 0
	
	While _nI <= Len( _aResTot ) .And. _cCodTrn == _aResTot[_nI][01]
		
		_nTotGer += _aResTot[_nI][03]
		_nConTot ++
		
	_nI++
	EndDo
	
	_nI--
	
	_oPrint:Say( _nLinha , _nColAux + 220	, Transform( _nTotGer , '@E 999,999,999,999.99'	) , _oFont03	,,,, 1 )
	_oPrint:Say( _nLinha , _nColAux + 690	, Transform( _nConTot , '@E 999,999,999,999'	) , _oFont03B	,,,, 1 )
	
	_aTotal[01] += _nTotGer
	_aTotal[02] += _nConTot

	_nLinha += 035
	RGLT013VPG( @_oPrint , @_nLinha , .T. )
	
Next _nI

_nLinha += 020
_oPrint:Say( _nLinha , _aColCab[01] , 'TOTAL GERAL ->' , _oFont03 )

_oPrint:Say( _nLinha , _nColAux + 220	, Transform( _aTotal[01] , '@E 999,999,999,999.99'	) , _oFont03		,,,, 1 )
_oPrint:Say( _nLinha , _nColAux + 690	, Transform( _aTotal[02] , '@E 999,999,999,999'		) , _oFont03B	,,,, 1 )

_nLinha += 100

_oPrint:Say( _nLinha , _aColCab[01] + 0150 , '______________________________________________________________' , _oFont03 )
_oPrint:Say( _nLinha , _aColCab[01] + 1450 , '______________________________________________________________' , _oFont03 ) ; _nLinha += 25
_oPrint:Say( _nLinha , _aColCab[01] + 0470 , 'Departamento do Leite'   , _oFont03 )
_oPrint:Say( _nLinha , _aColCab[01] + 1780 , 'Departamento Financeiro' , _oFont03 )

//=============================================================================
//| Síntese do frete                                                          |
//=============================================================================
_aFretes := RGLT013FRT()

_nLinha := 5000

RGLT013VPG( @_oPrint , @_nLinha , .T. )

_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++

_nLinha += 010

_oPrint:Say( _nLinha , _aColItn[01] , 'SÍNTESE DO FRETE' , _oFont02 )

_nLinha += 050
_aColItn:=ACLONE(_aColItnST)
For _nI := 1 To Len(_aFretes)
	If _cCodPro <> _aFretes[_nI][01]
		If !Empty(_cCodPro)
			_nLinha += 020
			RGLT013VPG( @_oPrint , @_nLinha , .T. )
			_oPrint:Say(_nLinha, _aColItn[01],"SUB-TOTAL 2o PERCURSO -->", _oFont02)

			_oPrint:Say(_nLinha, _aColItn[04]-300	, Transform(_nTtfVol, '@E 999,999,999,999'		)+" Lt"		, _oFont02)
			_oPrint:Say(_nLinha, _aColItn[05]-200	, Transform(_nTtfVal, '@E 999,999,999,999.99'	)	, _oFont02)
			_oPrint:Say(_nLinha, _aColItn[06]-80	, Transform(_nTtfPed, '@E 999,999,999,999.99'	)	, _oFont02)
			_oPrint:Say(_nLinha, _aColItn[07]+20	, Transform(_nTtfIcm, '@E 999,999,999,999.99'	)	, _oFont02)
			_oPrint:Say(_nLinha, _aColItn[08]+120	, Transform(_nTtfFrt, '@E 999,999,999,999.99'	)	, _oFont02)
			_oPrint:Say(_nLinha, _aColItn[10]+170	, Transform((_nTtfVal + _nTtfPed) / _nTtfVol, '@E 9,999,999,999.9999'	)			, _oFont02)

			_nTtfVol := 0
			_nTtfVal := 0
			_nTtfPed := 0
			_nTtfIcm := 0
			_nTtfFrt := 0
			_nTtfCus := 0

			_nLinha += 020
			RGLT013VPG( @_oPrint , @_nLinha , .T. )

			_nLinha += 030
			_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
			_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
			_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
			_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
			_nLinha += 050
			RGLT013VPG( @_oPrint , @_nLinha , .T. )

		EndIf
		_oPrint:Say(_nLinha, _aColItn[01],Posicione('SX5',1,xFilial('SX5')+'Z7'+PadR(_aFretes[_nI][01],TamSX3('X5_CHAVE')[01]),'X5_DESCRI'), _oFont02)
		_cCodPro := _aFretes[_nI][01]

		_nLinha += 050
		_oPrint:Line(_nLinha, 0, _nLinha, _aColItn[12])
		_nLinha += 010
		RGLT013VPG( @_oPrint , @_nLinha , .T. )

		_oPrint:Say(_nLinha, _aColItn[01]		, "Código"			, _oFont02)
		_oPrint:Say(_nLinha, _aColItn[02]-430	, "Loja"			, _oFont02)
		_oPrint:Say(_nLinha, _aColItn[03]-400	, "Transportadora"	, _oFont02)
		_oPrint:Say(_nLinha, _aColItn[04]-315	, "Volume 2o Perc."	, _oFont02)
		_oPrint:Say(_nLinha, _aColItn[05]-140	, "Valor (R$)"		, _oFont02)
		_oPrint:Say(_nLinha, _aColItn[06]+002	, "Pedágio"			, _oFont02)
		_oPrint:Say(_nLinha, _aColItn[07]+130	, "ICMS"			, _oFont02)
		_oPrint:Say(_nLinha, _aColItn[08]+168	, "Total Prest."	, _oFont02)
		_oPrint:Say(_nLinha, _aColItn[10]+222	, "Custo/LT"		, _oFont02)

		_nLinha += 050
		_oPrint:Line(_nLinha, 0, _nLinha, _aColItn[12])
		_nLinha += 020
		RGLT013VPG( @_oPrint , @_nLinha , .T. )
	EndIf

	//===================================
	//[01] - Codigo de Produto			|
	//[02] - Código da Transportadora	|
	//[03] - Loja da Transpostadora		|
	//[04] - Nome da Transportadora		|
	//[05] - Percurso (1 ou 2)			|
	//[06] - Volume Recebido			|
	//[07] - Valor de Pedágio			|
	//[08] - ICMS do Frete				|
	//[09] - Valor do Frete				|
	//[10] - Total do Frete				|
	//[11] - Custo LT					|
	//===================================

	_oPrint:Say(_nLinha, _aColItn[01]		, _aFretes[_nI][02]	, _oFont03)
	_oPrint:Say(_nLinha, _aColItn[02]-430	, _aFretes[_nI][03]	, _oFont03)
	_oPrint:Say(_nLinha, _aColItn[03]-400	, _aFretes[_nI][04]	, _oFont03)
	_oPrint:Say(_nLinha, _aColItn[04]-300	, Transform(_aFretes[_nI][06], '@E 999,999,999,999'		)+" Lt"		, _oFont03)
	_oPrint:Say(_nLinha, _aColItn[05]-200	, Transform(_aFretes[_nI][09], '@E 999,999,999,999.99'	)	, _oFont03)
	_oPrint:Say(_nLinha, _aColItn[06]-80	, Transform(_aFretes[_nI][07], '@E 999,999,999,999.99'	)	, _oFont03)
	_oPrint:Say(_nLinha, _aColItn[07]+20	, Transform(_aFretes[_nI][08], '@E 999,999,999,999.99'	)	, _oFont03)
	_oPrint:Say(_nLinha, _aColItn[08]+120	, Transform(_aFretes[_nI][10], '@E 999,999,999,999.99'	)	, _oFont03)
	_oPrint:Say(_nLinha, _aColItn[10]+170	, Transform((_aFretes[_nI][09]+_aFretes[_nI][07]) / _aFretes[_nI][06], '@E 9,999,999,999.9999'	)			, _oFont03)

	_nTtfVol += _aFretes[_nI][06]
	_nTtfVal += _aFretes[_nI][09]
	_nTtfPed += _aFretes[_nI][07]
	_nTtfIcm += _aFretes[_nI][08]
	_nTtfFrt += _aFretes[_nI][10]
	_nTtfCus += (_aFretes[_nI][09]+_aFretes[_nI][07]) / _aFretes[_nI][06]

	_nTtgVol += _aFretes[_nI][06]
	_nTtgVal += _aFretes[_nI][09]
	_nTtgPed += _aFretes[_nI][07]
	_nTtgIcm += _aFretes[_nI][08]
	_nTtgFrt += _aFretes[_nI][10]
	_nTtgCus += (_aFretes[_nI][09]+_aFretes[_nI][07]) / _aFretes[_nI][06]

	_nLinha += 030
	RGLT013VPG( @_oPrint , @_nLinha , .T. )

	_nLinha += 010
	_oPrint:Line(_nLinha, 0, _nLinha, _aColItn[12])
	_nLinha += 010
	RGLT013VPG( @_oPrint , @_nLinha , .T. )

Next _nI

_nLinha += 020
_oPrint:Say(_nLinha, _aColItn[01],"SUB-TOTAL 2o PERCURSO -->", _oFont02)

_oPrint:Say(_nLinha, _aColItn[04]-300	, Transform(_nTtfVol, '@E 999,999,999,999'		)+" Lt"		, _oFont02)
_oPrint:Say(_nLinha, _aColItn[05]-200	, Transform(_nTtfVal, '@E 999,999,999,999.99'	)	, _oFont02)
_oPrint:Say(_nLinha, _aColItn[06]-80	, Transform(_nTtfPed, '@E 999,999,999,999.99'	)	, _oFont02)
_oPrint:Say(_nLinha, _aColItn[07]+20	, Transform(_nTtfIcm, '@E 999,999,999,999.99'	)	, _oFont02)
_oPrint:Say(_nLinha, _aColItn[08]+120	, Transform(_nTtfFrt, '@E 999,999,999,999.99'	)	, _oFont02)
_oPrint:Say(_nLinha, _aColItn[10]+170	, Transform((_nTtfVal + _nTtfPed) / _nTtfVol, '@E 9,999,999,999.9999'	)			, _oFont02)

_nLinha += 050
//_oPrint:Line(_nLinha, 0, _nLinha, _aColItn[12])
_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
_nLinha += 010
RGLT013VPG( @_oPrint , @_nLinha , .T. )

_nLinha += 050
_oPrint:Say(_nLinha, _aColItn[01],"TOTAL GERAL -->", _oFont02)
_oPrint:Say(_nLinha, _aColItn[04]-300	, Transform(_nTtgVol, '@E 999,999,999,999'		)+" Lt"		, _oFont02)
_oPrint:Say(_nLinha, _aColItn[05]-200	, Transform(_nTtgVal, '@E 999,999,999,999.99'	)	, _oFont02)
_oPrint:Say(_nLinha, _aColItn[06]-80	, Transform(_nTtgPed, '@E 999,999,999,999.99'	)	, _oFont02)
_oPrint:Say(_nLinha, _aColItn[07]+20	, Transform(_nTtgIcm, '@E 999,999,999,999.99'	)	, _oFont02)
_oPrint:Say(_nLinha, _aColItn[08]+120	, Transform(_nTtgFrt, '@E 999,999,999,999.99'	)	, _oFont02)
_oPrint:Say(_nLinha, _aColItn[10]+170	, Transform((_nTtgVal + _nTtgPed) / _nTtgVol, '@E 9,999,999,999.9999'	)			, _oFont02)

_nLinha += 050
//_oPrint:Line(_nLinha, 0, _nLinha, _aColItn[12])
_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
_nLinha += 010

_nLinha += 170
RGLT013VPG( @_oPrint , @_nLinha , .T. )

_oPrint:Say( _nLinha , _aColCab[01] + 0150 , '______________________________________________________________' , _oFont03 )
_oPrint:Say( _nLinha , _aColCab[01] + 1450 , '______________________________________________________________' , _oFont03 ) ; _nLinha += 25
_oPrint:Say( _nLinha , _aColCab[01] + 0470 , 'Departamento do Leite'   , _oFont03 )
_oPrint:Say( _nLinha , _aColCab[01] + 1780 , 'Departamento Financeiro' , _oFont03 )

//=============================================================================
//| Starta o objeto de impressão                                              |
//=============================================================================
_oPrint:Setup()
_oPrint:SetLandscape()
_oPrint:SetPaperSize(9)
_oPrint:Preview()

Return

/*
===============================================================================================================================
Programa--------: RGLT013VPG
Autor-----------: Alexandre Villar
Data da Criacao-: 29/04/2014
Descrição-------: Validação do pocicionamento da página atual para quebras
Parametros------: oPrint	- Objeto de Impressão do Relatório
----------------: nLinha	- Variável de controle do posicionamento
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function RGLT013VPG( _oPrint , _nLinha , _lEndPag )

Local _nLimPag		:= 2300

Default _lEndPag	:= .T.

If _nLinha > _nLimPag

	//====================================================================================================
	// Verifica se encerra a página atual
	//====================================================================================================
	If _lEndPag
		_oPrint:EndPage()
	EndIf
	
	//====================================================================================================
	// Inicializa a nova página e o posicionamento
	//====================================================================================================
	_oPrint:StartPage()
	
	//====================================================================================================
	// Insere logo no cabecalho
	//====================================================================================================
	If File( "LGRL01.BMP" )
		_oPrint:SayBitmap( 050 , 020 , "LGRL01.BMP" , 410 , 170 )
	EndIf
	
	//====================================================================================================
	// Imprime quadro do Título
	//====================================================================================================
	_oPrint:Line( 050 , 0400 , 050 , 3350 )
	_oPrint:Line( 240 , 0400 , 240 , 3350 )
	_oPrint:Line( 050 , 0400 , 240 , 0400 )
	_oPrint:Line( 050 , 3350 , 240 , 3350 )
	
	_oPrint:Say( 060 , 420 , TITULO +" ( "+ DToC(Date()) +" - "+ Time() +")" , _oFont01 )
	_oPrint:Say( 120 , 420 , "Período de Recepção: "+ DToC( MV_PAR01 ) +" - "+ DToC( MV_PAR02 ) +" | Filial: "+ cFilAnt , _oFont02 )
	_oPrint:Say( 150 , 420 ,	"Considera: "+ IIf(MV_PAR03==1,'Leite de Filiais',IIf(MV_PAR03==3,'Leite de Plataformas',IIf(MV_PAR03==2,'Leite de Terceiros','Todas as Procedências'))) , _oFont02 )
	
	//====================================================================================================
	// Adiciona cabecalho de conteúdo
	//====================================================================================================
	_nLinha := 255
	
EndIf

Return
               
/*
===============================================================================================================================
Programa--------: RGLT013FRT
Autor-----------: Darcio Ribeiro Spörl
Data da Criacao-: 05/09/2016
Descrição-------: Rotina para gerar as informações da Síntese do Frete
Parametros------: Nenhum
Retorno---------: _aRet - Array com as informações dos fretes por produto
===============================================================================================================================
*/
Static Function RGLT013FRT()

Local _aArea	:= FWGetArea()
Local _aRet		:= {}
Local _cFiltro	:= "%"
Local _cProd	:= ""
Local _cTran	:= ""
Local _cLoja	:= ""
Local _nItem	:= 0
Local _cAlias	:= GetNextAlias()

If MV_PAR03 < 4
_cFiltro += IIf( !Empty( MV_PAR03 ) , " AND ZLX.ZLX_TIPOLT = '"+ IIf( MV_PAR03 == 1 , 'F' , IIf( MV_PAR03 == 2 , 'T' , 'P' ) ) +"' ","")
EndIf

_cFiltro += IIf( !Empty( MV_PAR04 ) , " AND ZZX.ZZX_CODPRD IN "+ FormatIn( MV_PAR04 , ';' ),"")
_cFiltro += IIf( !Empty( MV_PAR13 ) , " AND ZLX.ZLX_PLACA  IN "+ FormatIn( MV_PAR13 , ';' ),"")
_cFiltro += IIf( !Empty( MV_PAR14 ) , " AND ZZV.ZZV_FXCAPA IN "+ FormatIn( MV_PAR14 , ';' ),"")
_cFiltro += IIf( !Empty( MV_PAR19 ) , " AND ZLX.ZLX_STATUS IN "+ FormatIn( MV_PAR19 , ';' ),"")
_cFiltro += "%"

BeginSql alias _cAlias
SELECT ZZX.ZZX_CODPRD, A2T.A2_COD, A2T.A2_LOJA, A2T.A2_NREDUZ, ZZV.ZZV_PERCUR, ZLX.ZLX_VOLREC, ZLX.ZLX_PEDAGI, ZLX.ZLX_ICMSFR, ZLX.ZLX_VLRFRT, ZLX.ZLX_TVLFRT
  FROM %Table:ZLX% ZLX, %Table:SA2% A2T, %Table:SA2% A2F, %Table:ZZX% ZZX, %Table:ZZV% ZZV
 WHERE ZLX.D_E_L_E_T_ = ' '
   AND ZZX.D_E_L_E_T_ = ' '
   AND ZZV.D_E_L_E_T_ = ' '
   AND A2T.D_E_L_E_T_ = ' '
   AND A2F.D_E_L_E_T_ = ' '
   AND ZLX.ZLX_FILIAL = %xFilial:ZLX%
   AND ZZX.ZZX_FILIAL = %xFilial:ZZX%
   AND ZZV.ZZV_FILIAL = %xFilial:ZZV%
   AND A2T.A2_FILIAL = %xFilial:SA2%
   AND A2F.A2_FILIAL = %xFilial:SA2%
   AND ZLX.ZLX_FILIAL = ZZX.ZZX_FILIAL
   AND ZZX.ZZX_FILIAL = ZZV.ZZV_FILIAL
   AND ZLX.ZLX_FORNEC = A2F.A2_COD
   AND ZLX.ZLX_LJFORN = A2F.A2_LOJA
   AND ZLX.ZLX_TRANSP = A2T.A2_COD
   AND ZLX.ZLX_LJTRAN = A2T.A2_LOJA
   AND ZZX.ZZX_CODIGO = ZLX.ZLX_CODANA
   AND ZZX.ZZX_PLACA = ZZV.ZZV_PLACA
   AND ZZX.ZZX_TRANSP = ZZV.ZZV_TRANSP
   AND ZZX.ZZX_LJTRAN = ZZV.ZZV_LJTRAN
   AND ZLX.ZLX_PGFRT = 'S'
   %exp:_cFiltro%
   AND ZLX.ZLX_DTENTR BETWEEN %exp:MV_PAR01% AND %exp:MV_PAR02%
   AND ZLX.ZLX_FORNEC BETWEEN %exp:MV_PAR05% AND %exp:MV_PAR07%
   AND ZLX.ZLX_LJFORN BETWEEN %exp:MV_PAR06% AND %exp:MV_PAR08%
   AND ZLX.ZLX_TRANSP BETWEEN %exp:MV_PAR09% AND %exp:MV_PAR11%
   AND ZLX.ZLX_LJTRAN BETWEEN %exp:MV_PAR10% AND %exp:MV_PAR12%
   AND ZLX.ZLX_NRONF BETWEEN %exp:MV_PAR15% AND %exp:MV_PAR16%
   AND ZLX.ZLX_CODIGO BETWEEN %exp:MV_PAR17% AND %exp:MV_PAR18%
 ORDER BY ZZX.ZZX_CODPRD, A2T.A2_COD, A2T.A2_LOJA, A2T.A2_NREDUZ, ZZV.ZZV_PERCUR, ZLX.ZLX_VOLREC, ZLX.ZLX_PEDAGI, 
 			ZLX.ZLX_PEDAGI, ZLX.ZLX_ICMSFR, ZLX.ZLX_VLRFRT, ZLX.ZLX_TVLFRT
EndSql

While (_cAlias)->( !Eof() )

	If (_cAlias)->ZZX_CODPRD <> _cProd .Or. (_cAlias)->A2_COD <> _cTran .Or. (_cAlias)->A2_LOJA <> _cLoja
		_nItem++
		aAdd( _aRet , {	(_cAlias)->ZZX_CODPRD																	,; //[01] - Codigo de Produto
						(_cAlias)->A2_COD																		,; //[02] - Código da Transportadora
						(_cAlias)->A2_LOJA																		,; //[03] - Loja da Transpostadora
						(_cAlias)->A2_NREDUZ																	,; //[04] - Nome da Transportadora
						(_cAlias)->ZZV_PERCUR																	,; //[05] - Percurso (1 ou 2)
						(_cAlias)->ZLX_VOLREC																	,; //[06] - Volume Recebido
						(_cAlias)->ZLX_PEDAGI																	,; //[07] - Valor de Pedágio
						(_cAlias)->ZLX_ICMSFR																	,; //[08] - ICMS do Frete
						(_cAlias)->ZLX_VLRFRT																	,; //[09] - Valor do Frete
						(_cAlias)->ZLX_TVLFRT																	,; //[10] - Total do Frete
						Round( ( (_cAlias)->ZLX_VLRFRT + (_cAlias)->ZLX_PEDAGI ) / (_cAlias)->ZLX_VOLREC , 4 )  }) //[11] - Custo LT

		_cProd := (_cAlias)->ZZX_CODPRD
		_cTran := (_cAlias)->A2_COD
		_cLoja := (_cAlias)->A2_LOJA
	Else
		_aRet[_nItem][06] += (_cAlias)->ZLX_VOLREC
		_aRet[_nItem][07] += (_cAlias)->ZLX_PEDAGI
		_aRet[_nItem][08] += (_cAlias)->ZLX_ICMSFR
		_aRet[_nItem][09] += (_cAlias)->ZLX_VLRFRT
		_aRet[_nItem][10] += (_cAlias)->ZLX_TVLFRT
		_aRet[_nItem][11] += Round( ( (_cAlias)->ZLX_VLRFRT + (_cAlias)->ZLX_PEDAGI ) / (_cAlias)->ZLX_VOLREC , 4 )
	EndIf
								
	(_cAlias)->( DBSkip() )
EndDo

(_cAlias)->( DBCloseArea() )

FWRestArea(_aArea)
Return(_aRet)
