/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
 Autor        |    Data    |                              Motivo                      										 
-------------------------------------------------------------------------------------------------------------------------------
Alexandre V.  | 11/05/2015 | Ajuste na impressão dos dados da condição de pagamento. Chamado 9325
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer | 18/10/2016 |  Inclusão do valor do pedágio no RPA - Chamado 17.222
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  | 16/10/2019 | Removidos os Warning na compilação da release 12.1.25. Chamado 28346
===============================================================================================================================
*/
//====================================================================================================
// Definicoes de Includes e Defines da Rotina.
//====================================================================================================
#Include "TOTVS.ch"
#Include "rwmake.ch"
#Include "topconn.ch"
#Include "TBICONN.CH" 

/*
===============================================================================================================================
Programa----------: ROMS001
Autor-------------: Tiago Correa
Data da Criacao---: 02/02/2009
===============================================================================================================================
Descrição---------: Relatório para emissão de RPA
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ROMS001()

Private cPerg      := "ROMS001"
Private _nNum	   := 0 
Private cErro 	   := ""
Private aItens	   := {}
Private cItens	   := ""
Private cOrigemRPA := ""

If !Pergunte (cPerg,.T.)
	Return
EndIf

Processa( {|lEnd| MontaRel() } , 'Efetuando processamento...' , 'Aguarde!' )

Return

/*
===============================================================================================================================
Programa----------: MontaRel
Autor-------------: Tiago Correa
Data da Criacao---: 02/02/2009
===============================================================================================================================
Descrição---------: Relatório para emissão de RPA
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/                      
Static Function MontaRel()

Local _aDados      := {}
Local oPrint       := Nil 
Local _cAliasDados := GetNextAlias()
Local _cQuery      := ""
Local nCountRec    := 0           
Local _nX			:= 0

//================================================================================
// Inicializacao do Objeto de Impressão
//================================================================================
oPrint:= TMSPrinter():New( "Recibo de prestacao de servico" )
oPrint:SetPortrait()
oPrint:StartPage()

//================================================================================
// Verifica se o RPA está pronto para o processamento
//================================================================================
_cQuery := " SELECT "
_cQuery += "	ZZ2_FILIAL  ,"
_cQuery += "    ZZ2_RECIBO  ,"
_cQuery += "    ZZ2_SEST    ,"
_cQuery += "    ZZ2_INSS    ,"
_cQuery += "    ZZ2_IRRF    ,"
_cQuery += "    ZZ2_PAMVLR  ,"
_cQuery += "    ZZ2_TOTAL   ,"
_cQuery += "    ZZ2_TIPAUT  ,"
_cQuery += "    ZZ2_CARGA   ,"
_cQuery += "    A2_NOME     ,"
_cQuery += "    A2_COD      ,"
_cQuery += "    A2_END      ,"
_cQuery += "    A2_MUN      ,"
_cQuery += "    A2_BAIRRO   ,"
_cQuery += "    A2_CEP      ,"
_cQuery += "    A2_CGC      ,"
_cQuery += "    RA_PIS      ,"
_cQuery += "    A2_INSCR    , ZZ2_VRPEDA  "
_cQuery += " FROM "+ RetSqlName("ZZ2") +" ZZ2 "

_cQuery += " JOIN "+ RetSqlName("SA2") +" SA2 "
_cQuery += " ON "
_cQuery += " (   ZZ2.ZZ2_AUTONO = SA2.A2_I_AUTAV OR ZZ2.ZZ2_AUTONO = SA2.A2_I_AUT ) "

_cQuery += " JOIN "+ RetSqlName("SRA") +" SRA "
_cQuery += " ON "
_cQuery += "     ZZ2.ZZ2_AUTONO = SRA.RA_MAT "

_cQuery += " WHERE "
_cQuery += "     ZZ2.D_E_L_E_T_ = ' ' "
_cQuery += " AND SA2.D_E_L_E_T_ = ' ' "
_cQuery += " AND SRA.D_E_L_E_T_ = ' ' "
_cQuery += " AND ZZ2.ZZ2_FILIAL = '"+ xFilial("ZZ2") + "' "
_cQuery += " AND ZZ2.ZZ2_RECIBO BETWEEN '"+ MV_PAR01 +"' AND '"+ MV_PAR02 +"' "
_cQuery += " AND ZZ2.ZZ2_CARGA  BETWEEN '"+ MV_PAR03 +"' AND '"+ MV_PAR04 +"' "
_cQuery += " AND SA2.A2_COD		BETWEEN '"+ MV_PAR05 +"' AND '"+ MV_PAR06 +"' "

_cQuery += " ORDER BY ZZ2.ZZ2_RECIBO "

If Select(_cAliasDados) > 0
	(_cAliasDados)->( DBCloseArea() )
EndIf

DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQuery) , _cAliasDados , .T. , .F. )
COUNT TO nCountRec //Contabiliza o numero de registros encontrados pela query

//Verifica a existencia de pelo menos um registro de dados 
If nCountRec > 0

	ProcRegua(nCountRec)
	
	DBSelectArea(_cAliasDados)
	(_cAliasDados)->( DBGoTop() )
	
	While (_cAliasDados)->(!Eof())
	
		IncProc( "Favor Aguardar... Recibo corrente: " + AllTrim( (_cAliasDados)->ZZ2_RECIBO ) )
		
		If !Empty( (_cAliasDados)->ZZ2_CARGA )
		
			DBSelectArea('SF2')
			SF2->( DBSetOrder(5) )
			If SF2->( DBSeek( (_cAliasDados)->( ZZ2_FILIAL + ZZ2_CARGA ) ) )
			
				_aDados := {	(_cAliasDados)->ZZ2_RECIBO ,; //01
								(_cAliasDados)->ZZ2_SEST   ,; //02
								(_cAliasDados)->ZZ2_INSS   ,; //03
								(_cAliasDados)->ZZ2_IRRF   ,; //04
								(_cAliasDados)->ZZ2_PAMVLR ,; //05
								(_cAliasDados)->ZZ2_TOTAL  ,; //06
								(_cAliasDados)->A2_NOME    ,; //07
								(_cAliasDados)->A2_COD     ,; //08
								(_cAliasDados)->A2_END     ,; //09
								(_cAliasDados)->A2_MUN     ,; //10
								(_cAliasDados)->A2_BAIRRO  ,; //11
								(_cAliasDados)->A2_CEP     ,; //12
								(_cAliasDados)->A2_CGC     ,; //13
								(_cAliasDados)->RA_PIS     ,; //14
								(_cAliasDados)->A2_INSCR   ,; //15
								(_cAliasDados)->ZZ2_TIPAUT ,; //16
								(_cAliasDados)->ZZ2_CARGA  ,; //17
								(_cAliasDados)->ZZ2_VRPEDA  } //18
			
			Else
				
				_aDados := { '-1-' , '---' , '---' , '---' , '---' , '---' , '---' , '---' , '---' , '---' , '---' , '---' , '---' , '---' , '---' , '---' , '---' }
				
			EndIf
		
		Else
		
			_aDados := { '-0-' , '---' , '---' , '---' , '---' , '---' , '---' , '---' , '---' , '---' , '---' , '---' , '---' , '---' , '---' , '---' , '---' }
			
		EndIf
						
		ROMS001IMP( oPrint , _aDados )
	
	(_cAliasDados)->( DBSkip() )
	EndDo

Else

	_aDados := { '-0-' , '---' , '---' , '---' , '---' , '---' , '---' , '---' , '---' , '---' , '---' , '---' , '---' , '---' , '---' , '---' , '---' }
	
	ROMS001IMP( oPrint , _aDados )
	
EndIf
                  
(_cAliasDados)->( DBCloseArea() )

If _nNum == 1 //Verifica se houve algum erro durante as impressões

	For _nX := 1 to Len(aItens)
    		cItens += aItens[_nX][1] + ", "
	Next _nX
	
	xMagHelpFis(	"Divergência de valores"								,;
					"Ocorreram problemas na impressão do RPA nº "+ cItens	,;
					"Entre em contato com o Depto. de TI"					 )
	
	Email()
	
EndIf

oPrint:EndPage() // Finaliza a página
oPrint:Preview() // Visualiza antes de imprimir

Return

/*
===============================================================================================================================
Programa----------: ROMS001IMP
Autor-------------: Tiago Correa
Data da Criacao---: 02/02/2009
===============================================================================================================================
Descrição---------: Montagem do Relatorio de Emissao de RPA
===============================================================================================================================
Parametros--------: oPrint   = Objeto de dados de impressão
------------------: _aDados  = Dados para a impressão
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS001IMP( oPrint , _aDados )

Local oFont10 	:= TFont():New( "Arial"			, 9 , 08 , .T. , .T. , 5 , .T. , 5 , .T. , .F. )
Local oFont10n 	:= TFont():New( "Courier New"	, 9 , 08 , .T. , .T. , 5 , .T. , 5 , .T. , .F. )
Local oFont12n 	:= TFont():New( "Courier New"	, 9 , 10 , .T. , .T. , 5 , .T. , 5 , .T. , .F. )
Local oFont12  	:= TFont():New( "Courier New"	, 9 , 10 , .T. , .F. , 5 , .T. , 5 , .T. , .F. )
Local oFont16n	:= TFont():New( "Arial"			, 9 , 14 , .T. , .F. , 5 , .T. , 5 , .T. , .F. )
Local oBrush	:= Nil
Local _nTotItem	:= 	0
Local _nTotPag 	:= 	0
Local cont		:= 	1
Local _nSeq		:=	1
Local _nTPeso	:=	0
Local _nTFrete	:=	0
Local _aParc 	:=	{}
Local _nAvista 	:= 	0
Local _nAPrazo 	:= 	0
Local _nPedagio :=	0
Local _cQuery   := "" 
Local _cQry		:= ""
Local _cAliasSE2:= GetNextAlias()
Local _cAliasZZ3:= GetNextAlias()
Local nCountRec := 0 
Local nNotas    := 1 
Local Pag		:= 0
Private _nLin   :=  0

oBrush	:=	TBrush():New("",4)

If Empty(_aDados) .Or. _aDados[01] == '-0-' .Or. _aDados[01] == '-1-'
	
	oPrint:StartPage() //Inicia uma nova página
	oPrint:Say( 84 , 0100 , "RECIBO DE PRESTAÇÃO DE SERVIÇOS - ERRO DE IMPRESSÃO" )
	
	oPrint:Box( 0150 , 0100 , 0420 , 2300 )
	oPrint:Say( 0200 , 0120 , 'Não foram encontrados registros para imprimir. Verifique a(s) possível(eis) causas :'	, oFont12 )
	
	If _aDados[01] == '-1-'
		oPrint:Say( 0300 , 0120 , '-> Documento referente à RPA pode ainda não ter sido faturado'						, oFont12 )
		oPrint:Say( 0350 , 0120 , '-> Documento referente à RPA foi estornado ou não é válido'							, oFont12 )
	Else
		oPrint:Say( 0300 , 0120 , '-> Dados preenchidos nos parâmetros não permitem a impressão de nenhum registro'		, oFont12 )
		oPrint:Say( 0350 , 0120 , '-> Documento referente à RPA selecionado não é relacionado à Montagem de Carga'		, oFont12 )
	EndIf

	oPrint:Say( 3600 , 1980 , "Pagina: 01/01"																			, oFont12 )
	oPrint:EndPage() //Finaliza a página
	
Else

	_cQuery := " SELECT "
	_cQuery += "     E2_EMISSAO,E2_VENCTO,E2_VENCREA,E2_VALOR "
	_cQuery += " FROM "+ RetSqlName("SE2") +" SE2 "
	_cQuery += " WHERE "
	_cQuery += "     D_E_L_E_T_  = ' ' "
	_cQuery += " AND E2_FILIAL   = '"+ xFilial("SE2") +"' "
	_cQuery += " AND E2_NUM      = '"+ _aDados[01]    +"' "
	_cQuery += " AND E2_PREFIXO  = 'AUT' "
	_cQuery += " AND E2_TIPO     = 'RPA' "
	_cQuery += " AND E2_ORIGEM   IN ( 'GERAZZ3' , 'AOMS042' ) "
	
	If Select(_cAliasSE2) > 0
		(_cAliasSE2)->( DBCloseArea() )
	EndIf
	
	DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQuery) , _cAliasSE2 , .T. , .F. )
	COUNT TO nCountRec //Contabiliza o numero de registros encontrados pela query
	
	//================================================================================
	// Comparação da ZZ2 com SE2 - Lucas Crevilari 17/07/14
	//================================================================================
	_cQry := " SELECT "
	_cQry += "     ZZ2_FILIAL, ZZ2_RECIBO, ZZ2_CARGA, ZZ2_AUTONO, ZZ2_TOTAL, ZZ2_SEST, ZZ2_INSS, ZZ2_IRRF, ZZ2_DATA, ZZ2_COND "
	_cQry += " FROM "+RetSqlName("ZZ2")+" ZZ2 "
	_cQry += " WHERE "
	_cQry += "     ZZ2.D_E_L_E_T_ = ' ' "
	_cQry += " AND ZZ2_RECIBO     = '"+ _aDados[01] +"'" 
	_cQry += " AND ZZ2_FILIAL     = '"+xFilial("ZZ2")+"'"	
	_cQry += " AND ZZ2_TOTAL - ZZ2_SEST -ZZ2_INSS - ZZ2_PAMVLR <> NVL( ( SELECT SUM(E2_VALOR) FROM "+RetSqlName("SE2")+" SE2 "
	_cQry +=                                                           " WHERE "
	_cQry +=                                                           "     SE2.D_E_L_E_T_  = ' '"
	_cQry +=                                                           " AND ZZ2_FILIAL      = E2_FILIAL "
	_cQry +=                                                           " AND ZZ2_RECIBO      = E2_NUM "
	_cQry +=                                                           " AND E2_PREFIXO      = 'AUT'"
	_cQry +=                                                           " AND E2_ORIGEM       IN ('GERAZZ3','AOMS042') ) , 0 ) "
	
	TCQUERY _cQry NEW ALIAS "_cQry"
	
	cErro := ""
	
	If ( AllTrim( _cQry->ZZ2_RECIBO ) ) <> ""
	
		cErro += " VALOR SEST/SENAT e/ou VALOR INSS e/ou VALOR IRRF "
		
		aAdd( aItens , { AllTrim(_aDados[01]) , AllTrim(cErro) } )
		
		_nNum := 1
		
		_cQry->( DBCloseArea() )
		
		Return
		
	EndIf
	
	_cQry->( DBCloseArea() )
	
	//================================================================================
	// Verifica a existencia de pelo menos um registro de dados
	//================================================================================
	If nCountRec > 0
	
		DBSelectArea(_cAliasSE2)
		(_cAliasSE2)->( DBGoTop() )
		
		While (_cAliasSE2)->(!Eof())
		
			aAdd( _aParc , { (_cAliasSE2)->E2_VENCREA , (_cAliasSE2)->E2_VALOR } )
			
			If (_cAliasSE2)->E2_EMISSAO == (_cAliasSE2)->E2_VENCTO
				_nAvista += (_cAliasSE2)->E2_VALOR
			Else
				_nAPrazo += (_cAliasSE2)->E2_VALOR
			EndIf
			
		(_cAliasSE2)->( DBSkip() )
		EndDo
	
	EndIf
	
	(_cAliasSE2)->( DBCloseArea() )
	
	_cQuery := " SELECT "
	_cQuery += " 	ZZ3_DOC,ZZ3_PESO,ZZ3_VLRFRT,ZZ3_PESO,SF2.F2_TIPO,SF2.F2_CLIENTE,SF2.F2_LOJA,ZZ3.ZZ3_VRPEDA"
	_cQuery += " FROM " + RetSqlName("ZZ3") + " ZZ3 "
	_cQuery += " JOIN " + RetSqlName("SF2") + " SF2 ON SF2.F2_FILIAL	= ZZ3.ZZ3_FILIAL AND SF2.F2_DOC		= ZZ3.ZZ3_DOC "
	_cQuery += " WHERE "
	_cQuery += " ZZ3.D_E_L_E_T_ = ' ' "
	_cQuery += " AND SF2.D_E_L_E_T_ = ' ' "
	_cQuery += " AND ZZ3_FILIAL = '"+ xFilial("ZZ3") + "' "
	_cQuery += " AND ZZ3_CARGA  = '"+ _aDados[17]    + "' "
	_cQuery += " ORDER BY "
	_cQuery += " ZZ3.ZZ3_DOC "
	
	If Select(_cAliasZZ3) > 0
		(_cAliasZZ3)->( DBCloseArea() )
	EndIf
	
	DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQuery) , _cAliasZZ3 , .T. , .F. )
	COUNT TO _nTotItem //Contabiliza o numero de registros encontrados pela query
	
	_nTotPag := IIf( ( _nTotItem / 20 ) < 0 , 1 , Int( _nTotItem / 20 ) + IIf( ( ( _nTotItem / 20 ) - Int(_nTotItem / 20) ) * 100 > 0 , 1 , 0 ) )
	
	For Pag := 1 To _nTotPag
	
		oPrint:StartPage() //Inicia uma nova página
		oPrint:Say( 84 , 0100 , "RECIBO DE PRESTAÇÃO DE SERVIÇOS - Número : " + _aDados[01] , oFont16n )
		
		//================================================================================
		// Dados do autonomo
		//================================================================================
		oPrint:Box( 0150 , 0100 , 0420 , 2300 )
		oPrint:Say( 0150 , 0120 , "Nome....: "			, oFont12 )
		oPrint:Say( 0150 , 0370 , AllTrim(_aDados[07])	, oFont12n)
		oPrint:Say( 0150 , 1700 , "Cod.....: "			, oFont12 )
		oPrint:Say( 0150 , 2000 , AllTrim(_aDados[08])	, oFont12 )
		oPrint:Say( 0200 , 0120 , "Endereco: "			, oFont12 )
		oPrint:Say( 0200 , 0370 , AllTrim(_aDados[09])	, oFont12 )
		oPrint:Say( 0250 , 0120 , "Cidade..: "			, oFont12 )
		oPrint:Say( 0250 , 0370 , AllTrim(_aDados[10])	, oFont12 )
		oPrint:Say( 0300 , 0120 , "Bairro..: "			, oFont12 )
		oPrint:Say( 0300 , 0370 , AllTrim(_aDados[11])	, oFont12 )
		oPrint:Say( 0300 , 1700 , "CEP.....: "			, oFont12 )
		oPrint:Say( 0300 , 2000 , AllTrim(_aDados[12])	, oFont12 )
		
		If _aDados[16] == "1"
		
			oPrint:Say( 350 , 0120 , "CPF.....: "			,oFont12 )
			oPrint:Say( 350 , 0370 , AllTrim(_aDados[13])	,oFont12 )
			oPrint:Say( 350 , 1700 , "PIS.....: "			,oFont12 )
			oPrint:Say( 350 , 2000 , AllTrim(_aDados[14])	,oFont12 )
			
		Else
		
			oPrint:Say  (350,0120,"CGC.....: "			, oFont12 )
			oPrint:Say  (350,0370,AllTrim(_aDados[13])	, oFont12 )
			oPrint:Say  (350,1700,"Inscric.: "			, oFont12 )
			oPrint:Say  (350,2000,AllTrim(_aDados[15])	, oFont12 )
			
		EndIf
		
		//================================================================================
		// Dados das notas fiscais
		//================================================================================
		_nCol1 := 120       //120
		_nCol2 := _nCol1+100//300
		_nCol3 := _nCol2+330//850
		_nCol4 := _nCol3+345//1200
		_nCol5 := _nCol4+650//1900
		_nCol6 := _nCol5+350
		
		oPrint:Box( 460 , 0100 , 1560 , 2300 )
		oPrint:Say( 460 , _nCol1    , "SEQ.",oFont12n)
		oPrint:Say( 460 , _nCol2    , "NOTA",oFont12n)
		oPrint:Say( 460 , _nCol3+115, "PESO (KG)",oFont12n)//960
		oPrint:Say( 460 , _nCol4    , "MUNICIPIO DEST.",oFont12n)
		oPrint:Say( 460 , _nCol5+110, "PEDAGIOS",oFont12n)
		oPrint:Say( 460 , _nCol6+90 , "VLR. FRETE",oFont12n)//1990
		
		_nLin  := 510
		cont   := 1    
		nNotas := 1

		DBSelectArea(_cAliasZZ3)
		(_cAliasZZ3)->( DBGoTop() )
		
		While (_cAliasZZ3)->( !Eof() ) 
		
			If cont >= _nseq .And. nNotas <= 20
				
				If (_cAliasZZ3)->F2_TIPO $ 'B/D'
					_cMun	:= Posicione('SA2',1,xFilial('SA2')+(_cAliasZZ3)->(F2_CLIENTE+F2_LOJA),'A2_MUN')
					_cEst	:= Posicione('SA2',1,xFilial('SA2')+(_cAliasZZ3)->(F2_CLIENTE+F2_LOJA),'A2_EST')
				Else
					_cMun	:= Posicione('SA1',1,xFilial('SA1')+(_cAliasZZ3)->(F2_CLIENTE+F2_LOJA),'A1_MUN')
					_cEst	:= Posicione('SA1',1,xFilial('SA1')+(_cAliasZZ3)->(F2_CLIENTE+F2_LOJA),'A1_EST')
				EndIf
				
				oPrint:Say( _nLin , _nCol1 , StrZero( _nseq++ , 3 )											, oFont12n )
				oPrint:Say( _nLin , _nCol2 , (_cAliasZZ3)->ZZ3_DOC											, oFont12n )
				oPrint:Say( _nLin , _nCol3 , Transform( (_cAliasZZ3)->ZZ3_PESO 	, '@re 999,999,999.99' )	, oFont12n )
				oPrint:Say( _nLin , _nCol4 , AllTrim( _cMun ) +" - "+ AllTrim( _cEst )						, oFont12n )
				oPrint:Say( _nLin , _nCol5 , Transform( (_cAliasZZ3)->ZZ3_VRPEDA, '@re 999,999,999.99' )	, oFont12n )
				oPrint:Say( _nLin , _nCol6 , Transform( ((_cAliasZZ3)->ZZ3_VLRFRT-(_cAliasZZ3)->ZZ3_VRPEDA), '@re 999,999,999.99' )	, oFont12n )
				
				_nLin    += 50
				_nTPeso  += (_cAliasZZ3)->ZZ3_PESO
				_nTFrete += (_cAliasZZ3)->ZZ3_VLRFRT
				_nPedagio+= (_cAliasZZ3)->ZZ3_VRPEDA
				nNotas++
			
			EndIf
			
			cont++
			
		(_cAliasZZ3)->( DBSkip() )
		EndDo
		
		If Pag == _nTotPag
			_nTFrete := (_nTFrete-_nPedagio)
			oPrint:Say( 1510 , _nCol1 , "Total"										, oFont12n )
			oPrint:Say( 1510 , _nCol3, Transform( _nTPeso  , '@re 999,999,999.99' )	, oFont12n )
			oPrint:Say( 1510 , _nCol5, Transform( _nPedagio, '@re 999,999,999.99' )	, oFont12n )
			oPrint:Say( 1510 , _nCol6, Transform( _nTFrete , '@re 999,999,999.99' )	, oFont12n )
		EndIf
		
		//================================================================================
		// Dados dos impostos
		//================================================================================
		_nTDesc	:=	_aDados[02] + _aDados[03] + _aDados[04] + _aDados[05]
		_nTliq 	:=	_aDados[06] - _nTDesc
		
		//================================================================================
		// modificacao feita por Jeane
		// As linhas impressas abaixo do seguro serao ajustadas conforme variavel _nLin
		//================================================================================
		If _aDados[05] == 0
		   _nLin := 1850
		Else
		   _nLin := 1900
		EndIf
		
		oPrint:Box( 1600 , 0100 , _nLin + 50 , 1130 )
		oPrint:Box( 1600 , 1170 , _nLin + 50 , 2300 )
		
		oPrint:Say( 1600 , 0120 , "(+) Valor dos servicos: "																			, oFont12  )
		oPrint:Say( 1600 , 0740 , IIf( Pag == _nTotPag , Transform( (_aDados[06]-_aDados[18]) , '@re 999,999,999.99' ) , Replicate( "*" , 10 ) )	, oFont12n )
		oPrint:Say( 1650 , 0120 , "(+) Valor dos pedagios:"																				, oFont12  )
		oPrint:Say( 1650 , 0740 , IIf( Pag == _nTotPag , Transform( _aDados[18] , '@re 999,999,999.99' ) , Replicate( "*" , 10 ) )	, oFont12n )
		oPrint:Say( 1700 , 0120 , "(-) Desc.SEST/SENAT: "																				, oFont12  )
		oPrint:Say( 1700 , 0740 , IIf( Pag == _nTotPag , Transform( _aDados[02] , '@re 999,999,999.99' ) , Replicate( "*" , 10 ) )	, oFont12n )
		oPrint:Say( 1750 , 0120 , "(-) Contribuicoes INSS: "																			, oFont12  )
		oPrint:Say( 1750 , 0740 , IIf( Pag == _nTotPag , Transform( _aDados[03] , '@re 999,999,999.99' ) , Replicate( "*" , 10 ) )	, oFont12n )
		oPrint:Say( 1800 , 0120 , "(-) Desconto IRRF:  "																				, oFont12  )
		oPrint:Say( 1800 , 0740 , IIf( Pag == _nTotPag , Transform( _aDados[04] , '@re 999,999,999.99' ) , Replicate( "*" , 10 ) )	, oFont12n )
		
		//================================================================================
		// modificacao feita por Jeane 
		// Imprime valor do seguro caso seja maior que zero
		// As linhas impressas abaixo do seguro serao ajustadas conforme variavel _nLin
		//================================================================================
		If _aDados[05] > 0
			oPrint:Say( 1850 , 0120 , "(-) Vlr.Pamcary"																						, oFont12  )
			oPrint:Say( 1850 , 0740 , IIf( Pag == _nTotPag , Transform( _aDados[05] , '@re 999,999,999.99' ) , Replicate( "*" , 10 ) )	, oFont12n )
		EndIf
		
		oPrint:Say( _nLin , 0120 , "(=) Total Liquido: "																					, oFont12  )
		oPrint:Say( _nLin , 0740 , IIf( Pag == _nTotPag , Transform( _nTLiq , '@re 999,999,999.99' ) , Replicate("*",10) )		 		, oFont12n )
		
		oPrint:Say( 1600  , 1210 , "Total de Proventos: "																				, oFont12  )
		oPrint:Say( 1600  , 1920 , IIf( Pag == _nTotPag , Transform( _aDados[06] , '@re 999,999,999.99' ) , Replicate( "*" , 10 ) )		, oFont12n )
		oPrint:Say( 1750  , 1210 , "Descontos: "																						, oFont12  )
		oPrint:Say( 1750  , 1920 , IIf( Pag == _nTotPag , Transform( _nTDesc , '@re 999,999,999.99' ) , Replicate( "*" , 10 ) )			, oFont12n )
		oPrint:Say( _nLin , 1210 , "Total Liquido: "																					, oFont12  )
		oPrint:Say( _nLin , 1920 , IIf( Pag == _nTotPag , Transform( _nTLiq , '@re 999,999,999.99' ) , Replicate( "*" , 10 ) )			, oFont12n )
		
		oPrint:Box( _nLin+90  , 0100 , _nLin+240 , 2300 )
		oPrint:Say( _nLin+140 , 0120 , IIf( Pag == _nTotPag , PadC("("+AllTrim(Extenso(_nTLiq))+")",100," ") , Replicate( "*" , 100 ) )	, oFont10n )
		
		//================================================================================
		// Impressao da condicao de pagto        
		//================================================================================
		oPrint:Box(_nLin+260,0100, _nLin+450 , 2300 )
		oPrint:Say(_nlin+265,0120, "Condição de Pagamento:"																												, oFont12n )
		oPrint:Say(_nlin+295,1400, "Valor pago à Vista.:"																												, oFont12  )
		oPrint:Say(_nlin+295,2210, IIf( Pag == _nTotPag .And. _nAvista > 0 , Transform( _nAvista , '@re 999,999,999.99' ) , Replicate( "*" , 10 ) )						, oFont12n ,,,, 1 )
		oPrint:Say(_nlin+345,1400, "Valor à prazo......:"																												, oFont12  )
		oPrint:Say(_nlin+345,2210, IIf( Pag == _nTotPag .And. _nAPrazo > 0 , Transform( _nAPrazo , '@re 999,999,999.99' ) , Replicate( "*" , 10 ) )						, oFont12n ,,,, 1 )
		oPrint:Say(_nlin+405,0120, "- Pagamento(depósito) do saldo é efetuado de 3 a 5 dias úteis após chegada dos canhotos originais na empresa - Obrigatório nº PIS"	, oFont10  )
		        
		oPrint:Box( _nLin+480 , 0100 , _nLin+880 , 2300 )
		oPrint:Say( _nLin+480 , 0120 , "Recebi de "																, oFont12  )
		oPrint:Say( _nLin+480 , 0520 , AllTrim(SM0->M0_NOMECOM)													, oFont12n )
		oPrint:Say( _nLin+530 , 0120 , "Razão Social: "															, oFont12  )
		oPrint:Say( _nLin+530 , 0520 , AllTrim(SM0->M0_NOMECOM)													, oFont12  )
		oPrint:Say( _nLin+580 , 0120 , "Estabelicida à "														, oFont12  )
		oPrint:Say( _nLin+580 , 0520 , AllTrim(SM0->M0_ENDENT)													, oFont12  )
		oPrint:Say( _nLin+630 , 0120 , "Cidade de "																, oFont12  )
		oPrint:Say( _nLin+630 , 0520 , AllTrim(SM0->M0_CIDENT) +"    Estado: "+ SM0->M0_ESTENT					, oFont12  )
		oPrint:Say( _nLin+680 , 0120 , "CNPJ "																	, oFont12  )
		oPrint:Say( _nLin+680 , 0520 , AllTrim(SM0->M0_CGC) +"    Inscrição Estadual: "+ AllTrim(SM0->M0_INSC)	, oFont12  )
		oPrint:Say( _nLin+780 , 0120 , "A importância acima discriminada com os descontos de lei, referente ao"	, oFont12  )
		oPrint:Say( _nLin+830 , 0120 , "transporte de carga conforme o DEMONSTRATIVO DE CARGAS acima."			, oFont12  )
		
		oPrint:Box( _nLin+0920  , 0480 , _nLin+1160 , 2300 )
		oPrint:Line( _nLin+1100 , 1170 , _nLin+1100 , 2200 )
		oPrint:Say( _nLin+0920  , 0500 , "Para maior clareza, firmo o presente"									, oFont12  )
		oPrint:Say( _nLin+0970  , 0500 , AllTrim(SM0->M0_CIDENT)+" - "+SM0->M0_ESTENT+", "+StrZero(Day(dDataBase),2)+" de "+MesExtenso(dDataBase)+" de "+StrZero(Year(dDataBase),4) , oFont12 )
		oPrint:Say( _nLin+1100  , 1585 , "Assinatura"															, oFont12  )
		oPrint:Say( _nLin+1180  , 0120 , "Observação:"															, oFont12  )
		oPrint:Line( _nLin+1330 , 0120 , _nLin+1330 , 2200 )
		oPrint:Line( _nLin+1450 , 0120 , _nLin+1450 , 2200 )
		oPrint:Say( _nLin+1260  , 0120 , "Este recibo e referente a carga:" + _aDados[17]						, oFont12  )
		oPrint:Say( _nLin+1390  , 0120 , "DESCARGA POR CONTA DO MOTORISTA"										, oFont16n )
		
		oPrint:Say( _nLin+1470  , 1980 , "Pagina:"+ StrZero(Pag,2) +"/"+ StrZero(_nTotPag,2)					, oFont12  )
		oPrint:EndPage() // Finaliza a página
		
	Next Pag
	
	(_cAliasZZ3)->( DBCloseArea() )

EndIf
	
Return

/*
===============================================================================================================================
Programa----------: Envia Email
Autor-------------: Lucas Crevilari
Data da Criacao---: 17/07/2014
===============================================================================================================================
Descrição---------: Quando há divergencias entre valores gravados na SZ2 e os titulos gerados na SE2 é enviado e-mail para
------------------: sistema@italac.com.br
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/ 
Static Function Email()

Local _nX	:= 0
      
nInd    := 0
lResult := .F.
_cArq   := '' 
cTitulo := "RPA Fretistas - Divergencias" 

cHtml := Space(0)
cHtml += '<!DOCTYPE HTML Public "-//W3C//DTD HTML 4.01 Transitional//EN""http://www.w3.org/TR/html4/loose.dtd">'
cHtml += '<html>'
cHtml += '<head>'
cHtml += '<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1"><title>Untitled Document</title>'
cHtml += '<style Type="text/css">'
cHtml += '<!--body,td,th { font-family: Arial, Helvetica, sans-serif; font-size: 12px;}.negrito { font-family: Arial, Helvetica, sans-serif; font-size: 12px; font-weight: bold; color: #003366;}.negrito2 { font-family: Arial, Helvetica, sans-serif; font-size: 15px; font-weight: bold; color: #003366;}.texto1 { font-family: Arial, Helvetica, sans-serif; font-size: 11px; color: #666666;}.texto2 { font-family: Arial, Helvetica, sans-serif; font-size: 9px; color: #666666;}-->'
cHtml += '</style>'
cHtml += '</head>'
cHtml += '<body>'                                                         
cHtml += '<p class=MsoNormal>'
cHtml += '<table width="996" height="39"> <tr> <td align="center"><span class="negrito2" align="center">Divergencia de Valores</span><br>'
cHtml += '<br> </td> </tr> </table>'
cHtml += '<p><span class="negrito">Prezados, </span></p>'
cHtml += '<p><span class="negrito">HÁ DIVERGENCIA DE VALORES (VALOR SEST/SENAT e/ou VALOR INSS e/ou VALOR IRRF) ENTRE TABELAS ZZ2 E SE2:</span><span class="texto1"> </span> <br>' 
cHtml += '</p>'
cHtml += '<table width="900" height="53" border="1">'
cHtml += '  <tr>'
cHtml += '    <td width="200" height="22"><span class="negrito">Filial</span></td>'	
cHtml += '    <td width="200"><span class="negrito">Recibo</span></td>'
cHtml += '  </tr>'	

For _nX := 1 to Len(aItens)
	cHtml += '  <tr>'
	cHtml += '    <td>'+xFilial("SE2")+'</td>' 	
	cHtml += '    <td height="23">'+aItens[_nX][1]+'</td>'
	cHtml += '  </tr>  			
Next _nX
cHtml += '<table width="500" border="0" cellpadding="0" cellspacing="8"> <tr> <td width="167"><P class=MsoNormal> <span class="texto2" align="center"></span></p></body></html>'

//================================================================================
// Tenta conexao com o servidor de E-Mail
//================================================================================
CONNECT SMTP                     ;
SERVER       GetMV("MV_RELSERV") ; // Nome do servidor de e-mail = smtp.bra.terra.com.br
ACCOUNT 	 GetMV("MV_RELACNT") ; // Nome da conta a ser usada no e-mail = fulano
PASSWORD 	 GetMV("MV_RELPSW")  ; // Senha = senha
RESULT       lResult               // Resultado da tentativa de conexão

If lResult

	SEND MAIL                                 ;
	FROM              GetMV("MV_RELACNT")     ;
	TO               "sistema@italac.com.br"  ;
	SUBJECT          cTitulo                  ;
	BODY             cHtml                    ;  
	ATTACHMENT       _cArq                    ;
	RESULT           lResult
	
EndIf

//================================================================================
// Finaliza conexao com o servidor de E-Mail
//================================================================================
DISCONNECT SMTP SERVER

Return( lResult )
