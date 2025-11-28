/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alexandre V.  |22/12/2015| Chamado 13062. Tratativa na cláusula "ORDER BY" para remover a referência numérica.
Lucas Borges  |02/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: RFIS002
Autor-----------: Erich Buttner
Data da Criacao-: 08/04/2013
Descrição-------: Relatório do código de Ajuste
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function RFIS002()

Local _cPerg := "RFIS002"

Pergunte( _cPerg , .F. )

oReport := RFIS002RUN()

oReport:PrintDialog()

Return

/*
===============================================================================================================================
Programa--------: RFIS002RUN
Autor-----------: Erich Buttner
Data da Criacao-: 08/04/2013
Descrição-------: Processa a execução do relatório
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function RFIS002RUN()

Local oReport	:= Nil
Local oSection1	:= Nil
Local cAliasZLD	:= "ZLD"
Local cAliasSA2	:= "SA2"
Local cAliasQRY	:= "cQRY1"

Public cNome	:= ""
Public cDescr	:= ""
Public nVlr		:= 0
Public nDif		:= 0
Public dDtDig	:= SToD('')

oReport := TReport():New( "RFIS002" , "Relatório de Codigo de Ajuste" , "RFIS002" , {|oReport| RFIS002PRT( oReport , cAliasZLD , cAliasSA2 , cAliasQRY ) } , "Relatório de Codigo de Ajuste" , .T. )

oSection := TRSection():New( oReport , "" , {""} )

oSection:SetTotalInLine(.F.)

TRCell():New( oSection , "cPeriodo" )

oSection1 := TRSection():New( oSection , "" , { "ZLD" , "ZLE" , "ZL3" , "ZLF" , "ZLB" , "ZLC" } )

oSection1:SetTotalInLine(.F.)

TRCell():New( oSection1 , "CODLAN"		,, "Codigo Ajuste"		, "@!"				, 10 ,, {|| CODLAN		})

oSection2 := TRSection():New( oSection , "" , { "ZLD" , "ZLE" , "ZL3" , "ZLF" , "ZLB" , "ZLC" } )

oSection2:SetTotalInLine(.F.)

TRCell():New( oSection2 , "FILIAL"		,, "Filial"				, "@!"				, 09 ,, {|| FILIAL		})
TRCell():New( oSection2 , "DOC"			,, "Nota Fiscal"		, "@!"				, 09 ,, {|| DOC			})
TRCell():New( oSection2 , "SERIE"		,, "Serie"				, "@!"				, 03 ,, {|| SERIE		})
TRCell():New( oSection2 , "dDtDig"		,, "Data Digitação"		,					, 10 ,, {|| dDtDig		})
TRCell():New( oSection2 , "FORNECE"		,, "Fornecedor"			, "@!"				, 06 ,, {|| FORNECE		})
TRCell():New( oSection2 , "LOJA"		,, "Loja"				, "@!"				, 06 ,, {|| LOJA		})
TRCell():New( oSection2 , "cNome"		,, "Nome"				, "@!"				, 60 ,, {|| cNome		})
TRCell():New( oSection2 , "ITEM"		,, "Item"				, "@!"				, 04 ,, {|| ITEM		})
TRCell():New( oSection2 , "PROD"		,, "Produto"			, "@!"				, 15 ,, {|| PROD		})
TRCell():New( oSection2 , "cDescr"		,, "Descrição"			, "@!"				, 40 ,, {|| cDescr		})
TRCell():New( oSection2 , "nVlr"		,, "Valor Documento"	, "@E 9,999,999.99"	, 12 ,, {|| nVlr		})
TRCell():New( oSection2 , "APURACAO"	,, "Valor Apurado"		, "@E 9,999,999.99"	, 12 ,, {|| APURACAO	})
TRCell():New( oSection2 , "nDif"		,, "Diferença"			, "@E 9,999,999.99"	, 12 ,, {|| nDif		})

TRFunction():New( oSection2:Cell( "nVlr"     ) ,, "SUM" ,,,,, .T. , .F. )
TRFunction():New( oSection2:Cell( "APURACAO" ) ,, "SUM" ,,,,, .T. , .F. )
TRFunction():New( oSection2:Cell( "nDif"     ) ,, "SUM" ,,,,, .T. , .F. )

Return( oReport )

/*
===============================================================================================================================
Programa--------: RFIS002PRT
Autor-----------: Erich Buttner
Data da Criacao-: 08/04/2013
Descrição-------: Processa a impressão dos dados do relatório
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function RFIS002PRT( oReport , cAliasSB1 , cAliasSB5 , cAliasQRY )

Local oSection1 := oReport:Section(1):Section(1)

cCodAjust := "%"+ FormatIn( MV_PAR13 , ";" ) +"%"

oSection1:BeginQuery()

BeginSql alias cAliasQRY
	
	SELECT
		D1_FILIAL	AS FILIAL,
		D1_DOC		AS DOC,
		D1_SERIE	AS SERIE,
		D1_DTDIGIT	AS DTDIGIT,
		D1_FORNECE	AS FORNECE,
		D1_LOJA		AS LOJA,
		D1_ITEM		AS ITEM,
		D1_COD		AS PROD,
		D1_VALICM	AS ICMS,
		D1_ICMSCOM	AS DIF_ALQ,
		CC7_CODLAN	AS CODLAN,
		(	SELECT	SUM(CDA_VALOR)
			FROM	%Table:CDA%
			WHERE	D_E_L_E_T_ = ' '
			AND		CDA_FILIAL = D1_FILIAL
			AND		CDA_TPMOVI = 'E'
			AND		CDA_NUMERO = D1_DOC
			AND		CDA_SERIE  = D1_SERIE
			AND		CDA_CLIFOR = D1_FORNECE
			AND		CDA_LOJA   = D1_LOJA
			AND		CDA_NUMITE = D1_ITEM ) AS APURACAO
	FROM %Table:SD1% D1, %Table:CC7% CC7
	WHERE
		D1.D_E_L_E_T_	= ' '
	AND CC7.D_E_L_E_T_	= ' '
	AND CC7.CC7_FILIAL	= D1.D1_FILIAL
	AND CC7.CC7_TES		= D1.D1_TES
	AND CC7.CC7_FILIAL	BETWEEN %exp:MV_PAR01% AND %exp:MV_PAR02%
	AND CC7.CC7_SEQ		>= '001'
	AND D1.D1_FORNECE	BETWEEN %exp:MV_PAR07% AND %exp:MV_PAR09%
	AND D1.D1_LOJA		BETWEEN %exp:MV_PAR08% AND %exp:MV_PAR10%
	AND D1.D1_DOC		BETWEEN %exp:MV_PAR03% AND %exp:MV_PAR04%
	AND D1.D1_SERIE		BETWEEN %exp:MV_PAR05% AND %exp:MV_PAR06%
	AND CC7.CC7_CODLAN	IN %exp:cCodAjust%
	AND D1.D1_FILIAL	BETWEEN %exp:MV_PAR01% AND %exp:MV_PAR02%
	AND D1.D1_DTDIGIT	BETWEEN %exp:MV_PAR11% AND %exp:MV_PAR12%
	AND SubStr( D1.D1_CF , 1 , 1 ) = '2'
	
	UNION ALL
	
	SELECT
		D1_FILIAL	AS FILIAL,
		D1_DOC		AS DOC,
		D1_SERIE	AS SERIE,
		D1_DTDIGIT	AS DTDIGIT,
		D1_FORNECE	AS FORNECE,
		D1_LOJA		AS LOJA,
		D1_ITEM		AS ITEM,
		D1_COD		AS PROD,
		D1_VALICM	AS ICMS,
		D1_ICMSCOM	AS DIF_ALQ,
		CC7_CLANAP	AS CODLAN,
		(	SELECT	SUM(CDA_VALOR)
			FROM	%Table:CDA%
			WHERE D_E_L_E_T_ = ' '
			AND CDA_FILIAL   = D1_FILIAL
			AND CDA_TPMOVI   = 'E'
			AND CDA_NUMERO   = D1_DOC
			AND CDA_SERIE    = D1_SERIE
			AND CDA_CLIFOR   = D1_FORNECE
			AND CDA_LOJA     = D1_LOJA
			AND CDA_NUMITE   = D1_ITEM ) AS APURACAO
	FROM %Table:SD1% D1, %Table:CC7% CC7
	WHERE
		D1.D_E_L_E_T_  = ' '
	AND CC7.D_E_L_E_T_ = ' '
	AND CC7.CC7_FILIAL = D1.D1_FILIAL
	AND CC7.CC7_TES    = D1.D1_TES
	AND CC7.CC7_CLANAP IN %exp:cCodAjust%
	AND CC7.CC7_SEQ    >= '001'
	AND CC7.CC7_FILIAL BETWEEN %exp:MV_PAR01% AND %exp:MV_PAR02%
	AND D1.D1_FORNECE  BETWEEN %exp:MV_PAR07% AND %exp:MV_PAR09%
	AND D1.D1_LOJA     BETWEEN %exp:MV_PAR08% AND %exp:MV_PAR10%
	AND D1.D1_DOC      BETWEEN %exp:MV_PAR03% AND %exp:MV_PAR04%
	AND D1.D1_SERIE    BETWEEN %exp:MV_PAR05% AND %exp:MV_PAR06%
	AND D1.D1_FILIAL   BETWEEN %exp:MV_PAR01% AND %exp:MV_PAR02%
	AND D1.D1_DTDIGIT  BETWEEN %exp:MV_PAR11% AND %exp:MV_PAR12%
	AND SubStr( D1.D1_CF , 1 , 1 ) = '2'
	
	ORDER BY CODLAN, FILIAL, DOC, SERIE, DTDIGIT, FORNECE, LOJA, ITEM
	
EndSql

oSection1:EndQuery()

oReport:Section(1):Section(1):Init()
oReport:Section(1):Section(1):PrintLine()
oReport:Section(1):Section(2):Init()

nInc := RecCount()

oReport:SetMeter(nInc)

cCodAj := (cAliasQRY)->CODLAN

While !oReport:Cancel() .And. (cAliasQRY)->( !Eof() )
	
	cNome	:= GetAdvFVal( "SA2" , "A2_NOME"	, xFilial("SA2") + (cAliasQRY)->FORNECE + (cAliasQRY)->LOJA	, 1 , "" )
	cDescr	:= GetAdvFVal( "SB1" , "B1_I_DESCD"	, xFilial("SB1") + (cAliasQRY)->PROD						, 1 , "" )
	nVlr	:= IIf( (cAliasQRY)->CODLAN == 'GO10009029' , (cAliasQRY)->ICMS , IIf( (cAliasQRY)->CODLAN == 'GO000019  ' , (cAliasQRY)->DIF_ALQ , IIf( (cAliasQRY)->CODLAN == 'RO40000001' .Or. (cAliasQRY)->CODLAN == 'RO40000002' , (cAliasQRY)->DIF_ALQ , 0 ) ) )
	nDif	:= nVlr - (cAliasQRY)->APURACAO
	dDtDig	:= SubStr( (cAliasQRY)->DTDIGIT , 7 , 2 ) +"\"+ SubStr( (cAliasQRY)->DTDIGIT , 5 , 2 ) +"\"+ SubStr( (cAliasQRY)->DTDIGIT , 1 , 4 )
	
	If (cAliasQRY)->CODLAN <> cCodAj
	
		oReport:Section(1):Section(1):Finish()
		oReport:Section(1):Section(2):Finish()
		oReport:Section(1):Section(1):Init()
		oReport:Section(1):Section(2):Init()
		oReport:Section(1):Section(1):PrintLine()
		oReport:Section(1):Section(2):PrintLine()
		
		cCodAj := (cAliasQRY)->CODLAN
		
	Else
	
		oReport:Section(1):Section(2):PrintLine()
		
	EndIf
	
(cAliasQRY)->( DBSkip() )
EndDo

oReport:Section(1):Section(1):Finish()
oReport:Section(1):Section(1):Init()
oReport:Section(1):Section(2):Finish()
oReport:Section(1):Section(2):Init()

Return
