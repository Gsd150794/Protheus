/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |06/01/2017| Chamado 18250. Realizado tratamento para permitir gerar o relatório para várias filiais.
Lucas Borges  |17/06/2019| Chamado 28346. Revisão de fontes.
Lucas Borges  |27/09/2019| Chamado 28346. Revisão de fontes.
===============================================================================================================================
*/

#Include "TOTVS.ch"

#Define TITULO	"Recepção do Leite de Terceiros - Mapa Analítico"

/*
===============================================================================================================================
Programa--------: RGLT006
Autor-----------: Alexandre Villar
Data da Criacao-: 13/07/2015
Descrição-------: Relatório do mapa analítico da recepção de leite de terceiros
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function RGLT006()

Local _aCabec1		:= {'01','02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18','19','20','21','22','23','24','25','26','27','28','29','30','31','TOTAL'}
Local _aColCab		:= {0050,0105,0210,0315,0420,0525,0630,0735,0840,0945,1050,1155,1260,1365,1470,1575,1680,1785,1890,1995,2100,2205,2310,2415,2520,2625,2730,2835,2940,3045,3150, 3260  }
Local _aColItn		:= {0055,0160,0265,0370,0475,0580,0685,0790,0895,1000,1105,1210,1315,1420,1525,1630,1735,1840,1945,2050,2155,2260,2365,2470,2575,2680,2785,2890,2995,3100,3205, 3310  }
Local _aDados		:= {}
Local _cPerg		:= "RGLT006"
Local _nOpca		:= 0
Local _aSays		:= {}
Local _aButtons		:= {}

SET DATE FORMAT TO "DD/MM/YYYY"

Pergunte( _cPerg , .F. )

aAdd( _aSays , OemToAnsi( "Este programa tem como objetivo gerar o relatório de registros da recepção de leite "	) )
aAdd( _aSays , OemToAnsi( "de terceiros: mapa analítico. "															) )

aAdd( _aButtons , { 5 , .T. , {| | Pergunte( _cPerg )			} } )
aAdd( _aButtons , { 1 , .T. , {|o| _nOpca := 1 , o:oWnd:End()	} } )
aAdd( _aButtons , { 2 , .T. , {|o| _nOpca := 0 , o:oWnd:End()	} } )

FormBatch( "RGLT006" , _aSays , _aButtons ,, 155 , 500 )

If _nOpca == 1

	Processa( {|| _aDados := RGLT006SEL() } , "Aguarde!" , "Selecionando registros das recepções..." )
	
	If Empty(_aDados)
		MessageBox( "Não foram encontrados registros para exibir! Verifique os parâmetros e tente novamente." , "RGLT00601" , 48 )
	Else
		Processa( {|| RGLT006PRT( _aCabec1 , _aColCab , _aColItn , _aDados ) } , 'Aguarde!' , 'Imprimindo registros...' )
	EndIf

Else
	MsgInfo( "Operação cancelada pelo usuário!" , "RGLT00602" )
EndIf

Return

/*
===============================================================================================================================
Programa--------: RGLT006SEL
Autor-----------: Alexandre Villar
Data da Criacao-: 13/07/2015
Descrição-------: Função para consulta e preparação dos dados do relatório
Parametros------: Nenhum
Retorno---------: _aRet - Dados do relatório
===============================================================================================================================
*/
Static Function RGLT006SEL()

Local _aRet			:= {}
Local _cAlias		:= GetNextAlias()
Local _cFiltro		:= '%'
Local _nTotReg		:= 0
Local _nRegAtu		:= 0

_cFiltro += IIf( !Empty( MV_PAR02 ) .And. MV_PAR02 < 4 , " AND ZLX.ZLX_TIPOLT = '"+ IIf( MV_PAR02 == 1 , 'F' , IIf( MV_PAR02 == 2 , 'T' , 'P' ) ) +"' "	, "" )
_cFiltro += IIf( !Empty( MV_PAR03 ) , " AND ZZX.ZZX_CODPRD IN "+ FormatIn( MV_PAR03 , ';' ), "" )
_cFiltro += IIf( !Empty( MV_PAR08 ) , " AND ZLX.ZLX_STATUS IN "+ FormatIn( MV_PAR08 , ';' ), "" )
_cFiltro += " %"

BeginSql alias _cAlias
	SELECT ZZX.ZZX_CODPRD, ZLX.ZLX_TIPOLT, SA2.A2_COD, SA2.A2_LOJA, SA2.A2_NREDUZ, SubStr(ZLX.ZLX_DTENTR, 7, 2) DIA, SUM(ZLX.ZLX_VOLREC) VOLREC,
	       SUM(ZLX.ZLX_VOLNF) VOLNF, SUM(ZLX.ZLX_DIFVOL) DIFVOL
	  FROM %Table:ZLX% ZLX, %Table:SA2% SA2, %Table:ZZX% ZZX
	 WHERE ZLX.D_E_L_E_T_ = ' '
	   AND ZZX.D_E_L_E_T_ = ' '
	   AND SA2.D_E_L_E_T_ = ' '
	   AND ZLX.ZLX_FILIAL = %xFilial:ZLX%
	   AND ZZX.ZZX_FILIAL = %xFilial:ZZX%
	   AND SA2.A2_FILIAL = %xFilial:SA2%
	   AND ZLX.ZLX_FILIAL = ZZX.ZZX_FILIAL
	   AND ZLX.ZLX_FORNEC = SA2.A2_COD
	   AND ZLX.ZLX_LJFORN = SA2.A2_LOJA
	   AND ZZX.ZZX_CODIGO = ZLX.ZLX_CODANA
	   %exp:_cFiltro%
	   AND ZLX.ZLX_DTENTR BETWEEN %exp:FirstDate(MV_PAR01)% AND %exp:LastDate(MV_PAR01)%
	   AND ZLX.ZLX_FORNEC BETWEEN %exp:MV_PAR04% AND %exp:MV_PAR06%
	   AND ZLX.ZLX_LJFORN BETWEEN %exp:MV_PAR05% AND %exp:MV_PAR07%
	 GROUP BY ZZX.ZZX_CODPRD, ZLX.ZLX_TIPOLT, SA2.A2_COD, SA2.A2_LOJA, SubStr(ZLX.ZLX_DTENTR, 7, 2), SA2.A2_NREDUZ
	 ORDER BY ZZX.ZZX_CODPRD, ZLX.ZLX_TIPOLT, SA2.A2_COD, SA2.A2_LOJA, SubStr(ZLX.ZLX_DTENTR, 7, 2)
EndSql

(_cAlias)->( DBEval( {|| _nTotReg++ } ) )
(_cAlias)->( DBGoTop() )

ProcRegua(_nTotReg)
While (_cAlias)->( !Eof() )
	
	_nRegAtu++
	IncProc( "Lendo registros: ["+ StrZero( _nRegAtu , 6 ) +"] de ["+ StrZero( _nTotReg , 6 ) +"]" )
	
	aAdd( _aRet , {				(_cAlias)->ZZX_CODPRD								,; //01 - Codigo de Produto
								(_cAlias)->ZLX_TIPOLT								,; //02 - Procedencia
								(_cAlias)->A2_COD									,; //03 - Código do Fornecedor
								(_cAlias)->A2_LOJA									,; //04 - Loja do Fornecedor
					AllTrim(	(_cAlias)->A2_NREDUZ )								,; //05 - Nome Fantasia
								(_cAlias)->DIA										,; //06 - Dia do Acumulado
			AllTrim( Transform(	(_cAlias)->VOLREC	, '@E 999,999,999,999'      ) )	,; //07 - Volume Recebido
			AllTrim( Transform(	(_cAlias)->VOLNF	, '@E 999,999,999,999'      ) )	,; //08 - Volume na NF
			AllTrim( Transform(	(_cAlias)->DIFVOL	, '@E 999,999,999,999'      ) )	}) //09 - Diferença de Volume

	(_cAlias)->( DBSkip() )
EndDo

(_cAlias)->( DBCloseArea() )

Return( _aRet )

/*
===============================================================================================================================
Programa--------: RGLT006PRT
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
Static Function RGLT006PRT( _aCabec1 , _aColCab , _aColItn , _aDados )

Local _aDias	:= {}
Local _aTotais	:= {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
Local _aTotRec	:= {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
Local _aTotGer	:= {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
Local _nLinha	:= 300
Local _nColIni	:= 050
Local _nTotCol	:= Len(_aCabec1)
Local _nI		:= 0
Local _nX		:= 0
Local _oPrint	:= Nil
Local _cTipAux	:= ''
Local _cTipPrd	:= ''
Local _cCodCli	:= ''
Local _nTotFil	:= 0
Local _nTotPlt	:= 0
Local _nTotTer	:= 0
Local _nTotGer	:= 0
Local _nTotDes	:= 0
Local _nTotLin	:= 0

Private _oFont01 := TFont():New( "Tahoma" ,, 14 , .F. , .T. ,, .T. ,, .T. , .F. )
Private _oFont02 := TFont():New( "Tahoma" ,, 08 , .F. , .T. ,, .T. ,, .T. , .F. )
Private _oFont03 := TFont():New( "Tahoma" ,, 08 , .F. , .F. ,, .T. ,, .T. , .F. )
Private _oFont05 := TFont():New( "Tahoma" ,, 06 , .F. , .F. ,, .T. ,, .T. , .F. )

//====================================================================================================
// Inicializa o objeto do relatório
//====================================================================================================
_oPrint := TMSPrinter():New( TITULO )
_oPrint:Setup()
_oPrint:SetLandscape()
_oPrint:SetPaperSize(9)

//====================================================================================================
// Processa a impressão dos dados
//====================================================================================================
For _nI := 1 To Len( _aDados )
	
	//====================================================================================================
	// Inicializa a primeira página do relatório
	//====================================================================================================
	If _nI == 1
	
		_nLinha		:= 50000
		
		RGLT006VPG( @_oPrint , @_nLinha , .F. , _aCabec1 , _aColCab )
		
		_nLinha += 030
		_oPrint:Say( _nLinha , _nColIni , 'Mapa analítico das recepções de leite de terceiros: '+ DToC( FirstDay( MV_PAR01 ) ) +' - '+ DToC( LastDay( MV_PAR01 ) ) , _oFont02 )
		_nLinha += 035
		_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
		_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
		_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
		_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
		_nLinha += 010
		
		_cTipPrd := _aDados[_nI][01] + _aDados[_nI][02]
		_oPrint:Say( _nLinha , _nColIni ,	'Recepção de '+ AllTrim( Posicione('SX5',1,xFilial('SX5')+'Z7'+PadR(_aDados[_nI][01],TamSX3('X5_CHAVE')[01]),'X5_DESCRI') ) +;
											' / Procedência: '+ IIf(_aDados[_nI][02]=='F','Filiais',IIf(_aDados[_nI][02]=='P','Plataforma','Terceiros')) , _oFont02 )
		_nLinha += 060
		
		If _nTotCol > 0
		
			For _nX := 1 To _nTotCol
				_oPrint:Say( _nLinha , _aColCab[_nX] , _aCabec1[_nX] , _oFont02 )
			Next _nX
			_nLinha += 050
			
			_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
			_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
			
			_nLinha += 010
			
		EndIf
		
	//=============================================================================
	//| Encerra Lote do Setor atual                                               |
	//=============================================================================	
	ElseIf _nLinha > 2300
		
		_nLinha := 50000
		//=============================================================================
		//| Verifica o posicionamento da página                                       |
		//=============================================================================
		RGLT006VPG( @_oPrint , @_nLinha , .T. , _aCabec1 , _aColCab )
		
		_nLinha += 030
		_oPrint:Say( _nLinha , _nColIni , 'Mapa analítico das recepções de leite de terceiros: '+ DToC( FirstDay( MV_PAR01 ) ) +' - '+ DToC( LastDay( MV_PAR01 ) ) , _oFont02 )
		_nLinha += 035
		_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
		_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
		_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
		_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
		_nLinha += 010
		
		If _cTipPrd <> _aDados[_nI][01] + _aDados[_nI][02]
			
			_cTipPrd := _aDados[_nI][01] + _aDados[_nI][02]
			
			_nLinha += 035
			_oPrint:Say( _nLinha , _nColIni , 'SUBTOTAL' , _oFont03 )
			_nLinha += 030
			
			For _nX := 1 To Len(_aTotais)
				_oPrint:Say( _nLinha , _aColItn[_nX] , AllTrim( Transform( _aTotais[_nX] , '@E 999,999,999,999' ) ) , _oFont05 ,,,, 1 )
			Next _nX
			
			_nLinha += 035
			_oPrint:Line( _nLinha , 0 , _nLinha , 5000 )
			_nLinha += 050

			For _nX := 1 To Len(_aTotais)
				_aTotRec[_nX] += _aTotais[_nX]
				_aTotGer[_nX] += _aTotais[_nX]
			Next _nX

			If _cTipAux <> _aDados[_nI][01]
			
				_cTipAux := _aDados[_nI][01]
				
				_nLinha += 035
				_oPrint:Say( _nLinha , _nColIni , 'SUBTOTAL - RECEPCAO DE '+ AllTrim( Posicione('SX5',1,xFilial('SX5')+'Z7'+PadR(_aDados[_nI][01],TamSX3('X5_CHAVE')[01]),'X5_DESCRI') ) , _oFont03 )
				_nLinha += 030
				
				For _nX := 1 To Len(_aTotRec)
					_oPrint:Say( _nLinha , _aColItn[_nX] , AllTrim( Transform( _aTotRec[_nX] , '@E 999,999,999,999' ) ) , _oFont05 ,,,, 1 )
				Next _nX
				
				_nLinha += 035
				_oPrint:Line( _nLinha , 0 , _nLinha , 5000 )
				_nLinha += 050
				
				_aTotRec := {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
				
			EndIf
			
			_aTotais := {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
			
			_nLinha += 030
			_oPrint:Say( _nLinha , _nColIni ,	'Recepção de '+ AllTrim( Posicione('SX5',1,xFilial('SX5')+'Z7'+PadR(_aDados[_nI][01],TamSX3('X5_CHAVE')[01]),'X5_DESCRI') ) +;
										 		' / Procedência: '+ IIf(_aDados[_nI][02]=='F','Filiais',IIf(_aDados[_nI][02]=='P','Plataforma','Terceiros')) , _oFont02 )
			_nLinha += 035
			
		EndIf
		
		If _nTotCol > 0
			
			For _nX := 1 To _nTotCol
				_oPrint:Say( _nLinha , _aColCab[_nX] , _aCabec1[_nX] , _oFont02 )
			Next _nX
			_nLinha += 050
			
			_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
			_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
			
			_nLinha += 010
			
		EndIf
		
	ElseIf _cTipPrd <> _aDados[_nI][01] + _aDados[_nI][02]
	
		_cTipAux := _aDados[_nI][01]
		_cTipPrd := _aDados[_nI][01] + _aDados[_nI][02]
		
		_nLinha += 035
		_oPrint:Say( _nLinha , _nColIni , 'SUBTOTAL' , _oFont03 )
		_nLinha += 030
		
		For _nX := 1 To Len(_aTotais)
			_oPrint:Say( _nLinha , _aColItn[_nX] , AllTrim( Transform( _aTotais[_nX] , '@E 999,999,999,999' ) ) , _oFont05 ,,,, 1 )
		Next _nX
		
		_nLinha += 035
		_oPrint:Line( _nLinha , 0 , _nLinha , 5000 )
		_nLinha += 050
		
		For _nX := 1 To Len(_aTotais)
			_aTotRec[_nX] += _aTotais[_nX]
			_aTotGer[_nX] += _aTotais[_nX]
		Next _nX

		If _cTipAux <> _aDados[_nI][01]
		
			_cTipAux := _aDados[_nI][01]
			
			_nLinha += 035
			_oPrint:Say( _nLinha , _nColIni , 'SUBTOTAL - RECEPCAO DE '+ AllTrim( Posicione('SX5',1,xFilial('SX5')+'Z7'+PadR(_aDados[_nI][01],TamSX3('X5_CHAVE')[01]),'X5_DESCRI') ) , _oFont03 )
			_nLinha += 030
			
			For _nX := 1 To Len(_aTotRec)
				_oPrint:Say( _nLinha , _aColItn[_nX] , AllTrim( Transform( _aTotRec[_nX] , '@E 999,999,999,999' ) ) , _oFont05 ,,,, 1 )
			Next _nX
			
			_nLinha += 035
			_oPrint:Line( _nLinha , 0 , _nLinha , 5000 )
			_nLinha += 050
			
			_aTotRec := {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
			
		EndIf
		
		_aTotais := {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
		
		RGLT006VPG( @_oPrint , @_nLinha , .T. , _aCabec1 , _aColCab )
		
		_nTotPlt := _nTotFil := _nTotTer := _nTotGer := _nTotDes := 0
		
		_nLinha += 035
		_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
		_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
		_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
		_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
		_nLinha += 010
		
		RGLT006VPG( @_oPrint , @_nLinha , .T. , _aCabec1 , _aColCab )
		
		_oPrint:Say( _nLinha , _nColIni ,	'Recepção de '+ AllTrim( Posicione('SX5',1,xFilial('SX5')+'Z7'+PadR(_aDados[_nI][01],TamSX3('X5_CHAVE')[01]),'X5_DESCRI') ) +;
									 		' / Procedência: '+ IIf(_aDados[_nI][02]=='F','Filiais',IIf(_aDados[_nI][02]=='P','Plataforma','Terceiros')) , _oFont02 )
		_nLinha += 035
		
		If _nTotCol > 0
			
			For _nX := 1 To _nTotCol
				_oPrint:Say( _nLinha , _aColCab[_nX] , _aCabec1[_nX] , _oFont02 )
			Next _nX
			_nLinha += 050
			
			_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
			_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
			
			_nLinha += 010
			
		EndIf
		
	Else
	
		_nLinha += 030
		
	EndIf
	
	RGLT006VPG( @_oPrint , @_nLinha , .T. , _aCabec1 , _aColCab )
	
	If _cCodCli <> _aDados[_nI][03] + _aDados[_nI][04]
		
		_cCodCli := _aDados[_nI][03] + _aDados[_nI][04]
		_oPrint:Say( _nLinha , _nColIni , _aDados[_nI][03] +'/'+ _aDados[_nI][04] +' - '+ _aDados[_nI][05] , _oFont03 )
		_nLinha += 030
		
	EndIf
	
	_aDias := {'0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0'}
		
	While _nI <= Len( _aDados ) .And. _cCodCli == _aDados[_nI][03] + _aDados[_nI][04]
	
		_aDias[ Val( _aDados[_nI][06] ) ] := IIf( MV_PAR09 == 1 , _aDados[_nI][07] , IIf( MV_PAR09==2 , _aDados[_nI][08] , _aDados[_nI][09] ) )
	
	_nI++
	EndDo
	
	_nI--
	
	For _nX := 1 To Len(_aDias)
	
		_oPrint:Say( _nLinha , _aColItn[_nX] , _aDias[_nX] , _oFont05 ,,,, 1 )
		
		_nTotLin		+= Val( StrTran( StrTran( _aDias[_nX] , '.' , '' ) , ',' , '.' ) )
		_aTotais[_nX]	+= Val( StrTran( StrTran( _aDias[_nX] , '.' , '' ) , ',' , '.' ) )
		
	Next _nX
	
	_aTotais[32] += _nTotLin
	_oPrint:Say( _nLinha , _aColItn[32] , AllTrim( Transform( _nTotLin , '@E 999,999,999,999' ) ) , _oFont05 ,,,, 1 )
	_nTotLin := 0
	
	_nLinha += 035
	_oPrint:Line( _nLinha , 0 , _nLinha , 5000 )
	_nLinha += 010
	
Next _nI

_nI--

//=============================================================================
//| Verifica o posicionamento da página                                       |
//=============================================================================
_nLinha += 035
_oPrint:Say( _nLinha , _nColIni , 'SUBTOTAL' , _oFont03 )
_nLinha += 030

For _nX := 1 To Len(_aTotais)
	_oPrint:Say( _nLinha , _aColItn[_nX] , AllTrim( Transform( _aTotais[_nX] , '@E 999,999,999,999' ) ) , _oFont05 ,,,, 1 )
Next _nX

_nLinha += 035
	_oPrint:Line( _nLinha , 0 , _nLinha , 5000 )
_nLinha += 050

For _nX := 1 To Len(_aTotais)
	_aTotRec[_nX] += _aTotais[_nX]
	_aTotGer[_nX] += _aTotais[_nX]
Next _nX

RGLT006VPG( @_oPrint , @_nLinha , .T. , _aCabec1 , _aColCab )

_nLinha += 035
_oPrint:Say( _nLinha , _nColIni , 'SUBTOTAL - RECEPCAO DE '+ AllTrim( Posicione('SX5',1,xFilial('SX5')+'Z7'+PadR(_aDados[_nI][01],TamSX3('X5_CHAVE')[01]),'X5_DESCRI') ) , _oFont03 )
_nLinha += 030

For _nX := 1 To Len(_aTotRec)
	_oPrint:Say( _nLinha , _aColItn[_nX] , AllTrim( Transform( _aTotRec[_nX] , '@E 999,999,999,999' ) ) , _oFont05 ,,,, 1 )
Next _nX

_nLinha += 035
_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
_oPrint:Line( _nLinha , 0 , _nLinha , 5000 )
_nLinha += 050

RGLT006VPG( @_oPrint , @_nLinha , .T. , _aCabec1 , _aColCab )

_nLinha += 035
_oPrint:Say( _nLinha , _nColIni , 'TOTAL GERAL - TODAS AS RECEPÇÕES' , _oFont03 )
_nLinha += 030

For _nX := 1 To Len(_aTotGer)
	_oPrint:Say( _nLinha , _aColItn[_nX] , AllTrim( Transform( _aTotGer[_nX] , '@E 999,999,999,999' ) ) , _oFont05 ,,,, 1 )
Next _nX

_nLinha += 035
_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
_oPrint:Line( _nLinha , 0 , _nLinha , 5000 )

//=============================================================================
//| Starta o objeto de impressão                                              |
//=============================================================================
_oPrint:Preview()

Return

/*
===============================================================================================================================
Programa--------: RGLT006VPG
Autor-----------: Alexandre Villar
Data da Criacao-: 29/04/2014
Descrição-------: Validação do pocicionamento da página atual para quebras
Parametros------: oPrint	- Objeto de Impressão do Relatório
----------------: nLinha	- Variável de controle do posicionamento
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function RGLT006VPG( _oPrint , _nLinha , _lFinPag , _aCabec1 , _aColCab )

Local _nLimPag		:= 2300 //3400

Default _lFinPag	:= .T.

If _nLinha > _nLimPag

	//====================================================================================================
	// Verifica se encerra a página atual
	//====================================================================================================
	If _lFinPag
		_oPrint:EndPage()
	EndIf
	
	//====================================================================================================
	// Inicializa a nova página e o posicionamento
	//====================================================================================================
	_oPrint:StartPage()
	_nLinha	:= 280
	
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
	_oPrint:Say( 120 , 420 , "Período de análise: "+ SubStr( DToS( MV_PAR01 ) , 5 , 2 ) +"/"+ SubStr( DToS( MV_PAR01 ) , 1 , 4 ) +"    | Filial: "+ cFilAnt , _oFont02 )
	_oPrint:Say( 150 , 420 ,	"Considera: "+ IIf(MV_PAR02==1,'Leite de Filiais',IIf(MV_PAR02==2,'Leite de Terceiros',IIf(MV_PAR02==3,'Leite de Plataformas','Todas as Procedências'))) +;
								"    | Volume considerado: "+ IIf(MV_PAR09==1,'Recebido',IIf(MV_PAR09==2,'Faturado','Dif. na Balança')) , _oFont02 )
	
	//====================================================================================================
	// Adiciona cabecalho de conteúdo
	//====================================================================================================
	_nLinha := 255
	
EndIf

Return
