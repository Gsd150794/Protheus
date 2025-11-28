/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |02/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25
Alex Wallauer |05/12/2023| Chamado 45739 - Fernando. Correção do JOIN do SRJ para o relatorio trazer as marcações corretas.
Lucas Borges  |27/06/2025| Chamado 50617. Revisões diversas visando padronizar os fontes
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Define TITULO	"Ponto Eletrônico - Marcação de Ponto (Jornada x Intervalos)"

/*
===============================================================================================================================
Programa----------: RPON006
Autor-------------: Alexandre Villar
Data da Criacao---: 24/03/2014
Descrição---------: Relatório de Análise da Marcação de Pontos - Jornada x Intervalo
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RPON006

Local _aColAux	:= { 0050		, 0000			, 0050			, 0300  			, 0800 	  , 1100		  	, 1350	  , 1700			, 1880				, 2150			, 2550		, 2700			} As Array
Local _aCabec	:= { "Filial"	, "Setor"		, "Matrícula"	, "Funcionário"		, "Função", "Cod. Setor"	, "Setor" , "Dt Admissao"	, "Data do Apont."	, "Marcações"	, "Jornada"	, "Intervalo"	} As Array
Local _aColAjs	:= { 0000		, 0000			, 0015			, -0100 			, -0100   , 0010		  	, -0050	  , 0020			, 0020				, -0070			, 0015		, 0020			} As Array
Local _aDados	:= {} As Array
Local _cPerg	:= "RPON006" As Character

SET DATE FORMAT TO "DD/MM/YYYY"

If Pergunte(_cPerg)
	//Grava log de execução
	U_ITLOGACS()
	
	MV_PAR07 := U_ITSEPDEL( MV_PAR07 , 1 , ";" , "*" )
	
	//Verifica o registro de ponto em busca das informações
	Processa( {|| _aDados := RPON006SEL( ) } , "Aguarde!" , "Selecionando dados..." )
Else
	FWAlertInfo("Processamento cancelado pelo usuário!","RPON00601")
	Return
EndIf

If Empty(_aDados)
	FWAlertInfo(  "Não foram encontrados registros para exibir! Verifique os parâmetros e tente novamente.","RPON00602")
	Return
EndIf

If MV_PAR09 == 1
	LjMsgRun( "Exportando dados para planilha, aguarde..." , TITULO , {|| U_ITListBox( TITULO , _aCabec , _aDados , .T. ) } )
Else
	LjMsgRun( "Imprimindo dados, aguarde..." , TITULO , {|| RPON006PRT( _aCabec , _aColAux , _aColAjs , _aDados ) } )
EndIf

Return

/*
===============================================================================================================================
Programa----------: RPON006
Autor-------------: Alexandre Villar
Data da Criacao---: 24/03/2014
Descrição---------: Carga de dados para o relatório
Parametros--------: 	Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RPON006SEL

Local _aRet		:= {} As Array
Local _cAlias	:= '' As Character
Local _aFiliais	:= {} As Array
Local _cQuery	:= "" As Character
Local _cIntMax	:= cValToChar((Val(SubStr(MV_PAR08,1,2))*60) + (Val(SubStr(MV_PAR08,4,2)))) As Character
Local _dDtAux	:= SToD("") As Date
Local _nEnt_02	:= 0 As Numeric
Local _nSai_01	:= 0 As Numeric
Local _nResInt	:= 0 As Numeric
Local _nRegAtu	:= 0 As Numeric
Local _nTotReg	:= 0 As Numeric
Local __nOpcao	:= 0 As Numeric
Local _cFuncAnt	:= "" As Character
Local _lPrim	:= .T. As Logical
Local _nI		:= 0 As Numeric

If !Empty(MV_PAR08)
	_cIntMax := cValToChar((Val(SubStr(MV_PAR08,1,2))*60) + (Val(SubStr(MV_PAR08,4,2))))
Else
	_cIntMax := cValToChar((Val(SubStr("99:59",1,2))*60) + (Val(SubStr(MV_PAR08,4,2))))
EndIf

_aFiliais := StrTokArr(AllTrim(MV_PAR01),";")

If Empty(_aFiliais)
	FWAlertInfo( "Não foram informadas Filiais válidas para o processamento!","RPON00603")
EndIf

For _nI := 1 To Len( _aFiliais )
	_cAlias	:= GetNextAlias()
	BeginSql alias _cAlias
		SELECT MAX(PO_DATAFIM) AS DTFECHA
		FROM %Table:SPO% SPO
		WHERE PO_FILIAL = %exp:_aFiliais[_nI]%
		AND D_E_L_E_T_	= ' '
	EndSql
	
	_dDtAux := SToD( (_cAlias)->DTFECHA )
	(_cAlias)->(DBCloseArea())
	If _dDtAux >= MV_PAR02 .And. _dDtAux <= MV_PAR03 // fechamento entre os periodos 
		__nOpcao := 1
	ElseIf _dDtAux > MV_PAR03 // fechamento maior data ate
		__nOpcao := 2
	ElseIf _dDtAux < MV_PAR02 // fechamento menor data ate
		__nOpcao := 3
	EndIf
	
	If __nOpcao == 1 .Or. __nOpcao == 2
		_cAlias	:= GetNextAlias()
		_cQuery += " SELECT "
		_cQuery += "     	A.PG_FILIAL	AS FILIAL		, "		
		_cQuery += "		A.RA_I_SETOR	AS SETOR		, "		
		_cQuery += "     	A.PG_MAT		AS MATRIC		, "		
		_cQuery += "		A.RA_NOME		AS NOME		, "		
		_cQuery += "		A.RA_CODFUNC					, "		 
		_cQuery += "		A.RJ_DESC 		AS DESCFUNC 	, "		 
		_cQuery += "		TO_DATE(A.RA_ADMISSA, 'YYYYMMDD') AS DTADMIS,"	 
		_cQuery += "		A.ZAK_COD 		AS CODSET		,"		 
		_cQuery += "		A.ZAK_DESCRI 	AS DESCSET		,"		 
		_cQuery += " 		TO_DATE(A.PG_DATAAPO, 'YYYYMMDD') AS DT_APO, "	
		_cQuery += "     	SubStr(A.ENT_01, 12, 5)		|| ' ' || SubStr(A.SAI_01, 12, 5) || ' ' || SubStr(A.ENT_02, 12, 5) || ' ' || SubStr(A.SAI_02, 12, 5) || ' ' || "	
		_cQuery += "     	SubStr(A.ENT_03, 12, 5) || ' ' || SubStr(A.SAI_03, 12, 5) || ' ' || SubStr(A.ENT_04, 12, 5) || ' ' || SubStr(A.SAI_04, 12, 5) AS MARCAS, "		
		_cQuery += "     	SubStr(A.SAI_01,12,5) AS SAI_01, "	
		_cQuery += "     	SubStr(A.ENT_02,12,5) AS ENT_02, "	
		_cQuery += "     	LPAD( TRUNC( ABS( ( (		TO_DATE(A.SAI_01,'DD/MM/YYYY hh24:mi') - TO_DATE(A.ENT_01,'DD/MM/YYYY hh24:mi') 	) "	
		_cQuery += " 						+ NVL(	TO_DATE(A.SAI_02,'DD/MM/YYYY hh24:mi') - TO_DATE(A.ENT_02,'DD/MM/YYYY hh24:mi')	, 0	) "		
		_cQuery += " 						+ NVL(	TO_DATE(A.SAI_03,'DD/MM/YYYY hh24:mi') - TO_DATE(A.ENT_03,'DD/MM/YYYY hh24:mi') , 0	) "		
		_cQuery += " 						+ NVL(	TO_DATE(A.SAI_04,'DD/MM/YYYY hh24:mi') - TO_DATE(A.ENT_04,'DD/MM/YYYY hh24:mi') , 0	) ) ) * 1440 / 60 ) , 2 , 0 ) || ':' || "
		_cQuery += " 		LPAD( Round( MOD( ( ABS( ( (	TO_DATE(A.SAI_01,'DD/MM/YYYY hh24:mi') - TO_DATE(A.ENT_01,'DD/MM/YYYY hh24:mi') ) "	
		_cQuery += " 						+ NVL(			TO_DATE(A.SAI_02,'DD/MM/YYYY hh24:mi') - TO_DATE(A.ENT_02,'DD/MM/YYYY hh24:mi') , 0	) "	
		_cQuery += " 						+ NVL(			TO_DATE(A.SAI_03,'DD/MM/YYYY hh24:mi') - TO_DATE(A.ENT_03,'DD/MM/YYYY hh24:mi') , 0	) "	
		_cQuery += " 						+ NVL(			TO_DATE(A.SAI_04,'DD/MM/YYYY hh24:mi') - TO_DATE(A.ENT_04,'DD/MM/YYYY hh24:mi') , 0	) ) ) *1440 ) , 60 ) , 2 ) , 2 , 0 ) AS TOTAL "
		_cQuery += " FROM ( "
		_cQuery += " 		SELECT "
		_cQuery += " 			PG_FILIAL, "
		_cQuery += "			RA_I_SETOR, "
		_cQuery += " 			PG_MAT, "
		_cQuery += "			RA_NOME, "
		_cQuery += " 			RA_CODFUNC, " 
		_cQuery += " 			RJ_DESC, " 
		_cQuery += " 			RA_ADMISSA, " 
		_cQuery += " 			ZAK_COD, " 
		_cQuery += " 			ZAK_DESCRI, " 
		_cQuery += " 			PG_DATAAPO, "
		_cQuery += " 			ENT_01, "
		_cQuery += " 			SAI_01, "
		_cQuery += " 			ENT_02, "
		_cQuery += " 			SAI_02, "
		_cQuery += " 			ENT_03, "
		_cQuery += " 			SAI_03, "
		_cQuery += " 			ENT_04, "
		_cQuery += " 			SAI_04 "
		_cQuery += " 		FROM ( "
		_cQuery += " 				SELECT "
		_cQuery += " 					PG_FILIAL, "
		_cQuery += " 					RA_I_SETOR, "
		_cQuery += " 					PG_MAT, "
		_cQuery += " 					RA_NOME, "
		_cQuery += " 					RA_CODFUNC, " 
		_cQuery += " 					RJ_DESC, " 
		_cQuery += " 					RA_ADMISSA, " 
		_cQuery += " 					ZAK_COD, " 
		_cQuery += " 					ZAK_DESCRI, " 
		_cQuery += " 					PG_DATAAPO, "
		_cQuery += " 					PG_HORA, "
		_cQuery += " 					ROW_NUMBER() OVER( PARTITION BY PG_FILIAL, PG_MAT, PG_DATAAPO ORDER BY PG_FILIAL, PG_MAT, PG_DATA, PG_HORA ) RN "
		_cQuery += " 				FROM ( "
		_cQuery += " 						SELECT "
		_cQuery += " 							SPG.PG_FILIAL, "
		_cQuery += " 							SRA.RA_I_SETOR, "
		_cQuery += " 							SPG.PG_MAT, "
		_cQuery += " 							SRA.RA_NOME, "
		_cQuery += " 							RA_CODFUNC, " 
		_cQuery += " 							RJ_DESC, " 
		_cQuery += " 							RA_ADMISSA, " 
		_cQuery += " 							RA_I_SETOR AS ZAK_COD, " 
		_cQuery += " 							(SELECT ZAK_DESCRI FROM "+ RetSqlName("ZAK") +" WHERE ZAK_FILIAL = '" +  xFilial("ZAK") + "'"
		_cQuery += " 							AND D_E_L_E_T_ = ' ' AND ZAK_COD = RA_I_SETOR AND ROWNUM = 1) AS ZAK_DESCRI, " 
		_cQuery += " 							SPG.PG_DATAAPO, "
		_cQuery += " 							SPG.PG_DATA, "
		_cQuery += " 							SubStr(SPG.PG_DATA,7,2) ||'/'|| SubStr(SPG.PG_DATA,5,2) ||'/'|| SubStr(SPG.PG_DATA,1,4) || ' ' || "
		_cQuery += " 								TO_CHAR(TO_DATE(to_char(PG_HORA, '00.00'),'hh24:mi'),'hh24:mi') AS PG_HORA "
		_cQuery += " 						FROM "+ RetSqlName("SPG") +" SPG "
		_cQuery += " 						INNER JOIN "+ RetSqlName("SRA") +" SRA ON "
		_cQuery += " 							SRA.RA_FILIAL	= SPG.PG_FILIAL "
		_cQuery += " 						AND	SRA.RA_MAT		= SPG.PG_MAT "
		_cQuery += "							INNER JOIN " +RetSqlName("SRJ")+ " SRJ ON RJ_FUNCAO = RA_CODFUNC  AND RJ_FILIAL = RA_FILIAL " 
		_cQuery += " 						WHERE "
		_cQuery += " 							SPG.D_E_L_E_T_	= ' ' "
		_cQuery += " 						AND	SRA.D_E_L_E_T_	= ' ' "

		If !Empty( MV_PAR10 )
			_cQuery += " 						AND	SRA.RA_I_SETOR	IN "+ FormatIn( AllTrim( MV_PAR10 ) , ";" ) 
		EndIf

		_cQuery += " 						AND SPG.PG_FILIAL	= '"+ _aFiliais[_nI] +"' " 
		_cQuery += "						AND SRA.RA_CATFUNC	IN "+ FormatIn( RTrim( MV_PAR06 ) , ";" ) 
		_cQuery += " 						AND SRA.RA_SITFOLH  IN "+ FormatIn( RTrim( MV_PAR07 ) , ";" ) 
		_cQuery += " 						AND SPG.PG_APONTA	= 'S' "
		_cQuery += " 						AND SPG.PG_TPMCREP	<> 'D' "
		_cQuery += " 						AND SPG.PG_MAT		BETWEEN '"+ MV_PAR04 +"' AND '"+ MV_PAR05 +"' "
	
		If __nOpcao == 1
			_cQuery += "					AND SPG.PG_DATAAPO	BETWEEN '"+ DToS( MV_PAR02 ) +"' AND '"+ DToS( _dDtAux ) +"' "
		ElseIf __nOpcao == 2
			_cQuery += "					AND SPG.PG_DATAAPO	BETWEEN '"+ DToS( MV_PAR02 ) +"' AND '"+ DToS( MV_PAR03 ) +"' "
		EndIf
	
		_cQuery += " 				) "
		_cQuery += " 		) PG "
		_cQuery += " 			PIVOT ( MAX(PG_HORA) For RN IN (	1 AS ENT_01 , "
		_cQuery += " 												2 AS SAI_01 , "
		_cQuery += " 												3 AS ENT_02 , "
		_cQuery += " 												4 AS SAI_02 , "
		_cQuery += " 												5 AS ENT_03 , "
		_cQuery += " 												6 AS SAI_03 , "
		_cQuery += " 												7 AS ENT_04 , "
		_cQuery += " 												8 AS SAI_04 ) "
		_cQuery += " 		) "
		_cQuery += " ) A "
		_cQuery += " HAVING "
		
		_cQuery += "	DECODE ( TRUNC( ( TO_DATE(SubStr(A.ENT_02, 12, 5),'hh24:mi') - TO_DATE(SubStr(A.SAI_01, 12, 5),'hh24:mi') ) * 1440 ) + "
       	_cQuery += "          ABS(TRUNC( ( TO_DATE(SubStr(A.ENT_02, 12, 5),'hh24:mi') - TO_DATE(SubStr(A.SAI_01, 12, 5),'hh24:mi') ) * 1440 )),0,"
       	_cQuery += "             TRUNC( (( TO_DATE(SubStr(A.ENT_02, 12, 5),'hh24:mi') - TO_DATE(SubStr(A.SAI_01, 12, 5),'hh24:mi') ) * 1440) + 1440 ),"
       	_cQuery += "              TRUNC( ( TO_DATE(SubStr(A.ENT_02, 12, 5),'hh24:mi') - TO_DATE(SubStr(A.SAI_01, 12, 5),'hh24:mi') ) * 1440 )) < "+ _cIntMax  
		 
		_cQuery += " AND (	Case	WHEN Round( ( ( TO_DATE(A.SAI_01,'DD/MM/YYYY hh24:mi') - TO_DATE(A.ENT_01,'DD/MM/YYYY hh24:mi') ) * 1440 ) , 0 ) IS NOT NULL "
		_cQuery += " 				THEN Round( ( ( TO_DATE(A.SAI_01,'DD/MM/YYYY hh24:mi') - TO_DATE(A.ENT_01,'DD/MM/YYYY hh24:mi') ) * 1440 ) , 0 ) Else 0 END + "
		_cQuery += " 		Case	WHEN Round( ( ( TO_DATE(A.SAI_02,'DD/MM/YYYY hh24:mi') - TO_DATE(A.ENT_02,'DD/MM/YYYY hh24:mi') ) * 1440 ) , 0 ) IS NOT NULL "
		_cQuery += " 				THEN Round( ( ( TO_DATE(A.SAI_02,'DD/MM/YYYY hh24:mi') - TO_DATE(A.ENT_02,'DD/MM/YYYY hh24:mi') ) * 1440 ) , 0 ) Else 0 END + "
		_cQuery += " 		Case	WHEN Round( ( ( TO_DATE(A.SAI_03,'DD/MM/YYYY hh24:mi') - TO_DATE(A.ENT_03,'DD/MM/YYYY hh24:mi') ) * 1440 ) , 0 ) IS NOT NULL "
		_cQuery += " 				THEN Round( ( ( TO_DATE(A.SAI_03,'DD/MM/YYYY hh24:mi') - TO_DATE(A.ENT_03,'DD/MM/YYYY hh24:mi') ) * 1440 ) , 0 ) Else 0 END + "
		_cQuery += " 		Case	WHEN Round( ( ( TO_DATE(A.SAI_04,'DD/MM/YYYY hh24:mi') - TO_DATE(A.ENT_04,'DD/MM/YYYY hh24:mi') ) * 1440 ) , 0 ) IS NOT NULL "
		_cQuery += " 				THEN Round( ( ( TO_DATE(A.SAI_04,'DD/MM/YYYY hh24:mi') - TO_DATE(A.ENT_04,'DD/MM/YYYY hh24:mi') ) * 1440 ) , 0 ) Else 0 END ) >= 0"
		
		_cQuery += " GROUP BY A.PG_FILIAL, A.RA_I_SETOR, A.PG_MAT, A.RA_NOME, A.PG_DATAAPO, A.ENT_01, A.SAI_01, A.ENT_02, A.SAI_02, A.ENT_03, A.SAI_03, A.ENT_04, A.SAI_04,A.RA_CODFUNC,A.RJ_DESC,A.RA_ADMISSA,A.ZAK_COD,A.ZAK_DESCRI "
	EndIf
	
	If __nOpcao == 1
		_cQuery += " UNION ALL "
	EndIf

	If __nOpcao == 1 .Or. __nOpcao == 3

		_cQuery += " SELECT "
		_cQuery += "     	A.P8_FILIAL		AS FILIAL	, "
		_cQuery += "		A.RA_I_SETOR	AS SETOR	, "
		_cQuery += "     	A.P8_MAT		AS MATRIC	, "
		_cQuery += " 		A.RA_NOME		AS NOME		, "
		_cQuery += "		A.RA_CODFUNC," 
		_cQuery += "		A.RJ_DESC 		AS DESCFUNC , " 
		_cQuery += "		TO_DATE(A.RA_ADMISSA, 'YYYYMMDD') AS DTADMIS," 
		_cQuery += "		A.ZAK_COD AS CODSET," 
		_cQuery += "		A.ZAK_DESCRI AS DESCSET," 
		_cQuery += " 		TO_DATE(A.P8_DATAAPO, 'YYYYMMDD') AS DT_APO, "
		_cQuery += "    	SubStr(A.ENT_01, 12, 5)		|| ' ' || SubStr(A.SAI_01, 12, 5) || ' ' || SubStr(A.ENT_02, 12, 5) || ' ' || SubStr(A.SAI_02, 12, 5) || ' ' || "
		_cQuery += "     	SubStr(A.ENT_03, 12, 5) || ' ' || SubStr(A.SAI_03, 12, 5) || ' ' || SubStr(A.ENT_04, 12, 5) || ' ' || SubStr(A.SAI_04, 12, 5) AS MARCAS, "
		_cQuery += "     	SubStr(A.SAI_01,12,5) AS SAI_01, "
		_cQuery += "     	SubStr(A.ENT_02,12,5) AS ENT_02, "
		_cQuery += "     	LPAD( TRUNC( ABS( ( (		TO_DATE(A.SAI_01,'DD/MM/YYYY hh24:mi') - TO_DATE(A.ENT_01,'DD/MM/YYYY hh24:mi') 	) "
		_cQuery += " 						+ NVL(	TO_DATE(A.SAI_02,'DD/MM/YYYY hh24:mi') - TO_DATE(A.ENT_02,'DD/MM/YYYY hh24:mi')	, 0	) "
		_cQuery += " 						+ NVL(	TO_DATE(A.SAI_03,'DD/MM/YYYY hh24:mi') - TO_DATE(A.ENT_03,'DD/MM/YYYY hh24:mi') , 0	) "
		_cQuery += " 						+ NVL(	TO_DATE(A.SAI_04,'DD/MM/YYYY hh24:mi') - TO_DATE(A.ENT_04,'DD/MM/YYYY hh24:mi') , 0	) ) ) * 1440 / 60 ) , 2 , 0 ) || ':' || "
		_cQuery += " 		LPAD( Round( MOD( ( ABS( ( (	TO_DATE(A.SAI_01,'DD/MM/YYYY hh24:mi') - TO_DATE(A.ENT_01,'DD/MM/YYYY hh24:mi') ) "
		_cQuery += " 						+ NVL(			TO_DATE(A.SAI_02,'DD/MM/YYYY hh24:mi') - TO_DATE(A.ENT_02,'DD/MM/YYYY hh24:mi') , 0	) "
		_cQuery += " 						+ NVL(			TO_DATE(A.SAI_03,'DD/MM/YYYY hh24:mi') - TO_DATE(A.ENT_03,'DD/MM/YYYY hh24:mi') , 0	) "
		_cQuery += " 						+ NVL(			TO_DATE(A.SAI_04,'DD/MM/YYYY hh24:mi') - TO_DATE(A.ENT_04,'DD/MM/YYYY hh24:mi') , 0	) ) ) *1440 ) , 60 ) , 2 ) , 2 , 0 ) AS TOTAL "
		_cQuery += " FROM ( "
		_cQuery += " 		SELECT "
		_cQuery += " 			P8_FILIAL, "
		_cQuery += " 			RA_I_SETOR, "
		_cQuery += " 			P8_MAT, "
		_cQuery += " 			RA_NOME, "
		_cQuery += " 			RA_CODFUNC, " 
		_cQuery += " 			RJ_DESC, " 
		_cQuery += " 			RA_ADMISSA, " 
		_cQuery += " 			ZAK_COD, " 
		_cQuery += " 			ZAK_DESCRI, " 
		_cQuery += " 			P8_DATAAPO, "
		_cQuery += " 			ENT_01, "
		_cQuery += " 			SAI_01, "
		_cQuery += " 			ENT_02, "
		_cQuery += " 			SAI_02, "
		_cQuery += " 			ENT_03, "
		_cQuery += " 			SAI_03, "
		_cQuery += " 			ENT_04, "
		_cQuery += " 			SAI_04 "
		_cQuery += " 		FROM ( "
		_cQuery += " 				SELECT "
		_cQuery += " 					P8_FILIAL, "
		_cQuery += " 					RA_I_SETOR, "
		_cQuery += " 					P8_MAT, "
		_cQuery += " 					RA_NOME, "
		_cQuery += " 					RA_CODFUNC, " 
		_cQuery += " 					RJ_DESC, " 
		_cQuery += " 					RA_ADMISSA, " 
		_cQuery += " 					ZAK_COD, " 
		_cQuery += " 					ZAK_DESCRI, " 
		_cQuery += " 					P8_DATAAPO, "
		_cQuery += " 					P8_HORA, "
		_cQuery += " 					ROW_NUMBER() OVER( PARTITION BY P8_FILIAL, P8_MAT, P8_DATAAPO ORDER BY P8_FILIAL, P8_MAT, P8_DATA, P8_HORA ) RN "
		_cQuery += " 				FROM ( "
		_cQuery += " 						SELECT "
		_cQuery += " 							SP8.P8_FILIAL, "
		_cQuery += " 							SRA.RA_I_SETOR, "
		_cQuery += " 							SP8.P8_MAT, "
		_cQuery += "							SRA.RA_NOME, "
		_cQuery += " 							RA_CODFUNC, " 
		_cQuery += " 							RJ_DESC, " 
		_cQuery += " 							RA_ADMISSA, " 
		_cQuery += " 							RA_I_SETOR AS ZAK_COD, " 
		_cQuery += " 							(SELECT ZAK_DESCRI FROM "+ RetSqlName("ZAK") +" WHERE ZAK_FILIAL = '" +  xFilial("ZAK") + "'"
		_cQuery += " 							AND D_E_L_E_T_ = ' ' AND ZAK_COD = RA_I_SETOR AND ROWNUM = 1) AS ZAK_DESCRI, " 
		_cQuery += " 							SP8.P8_DATAAPO, "
		_cQuery += " 							SP8.P8_DATA, "
		_cQuery += " 							SubStr(SP8.P8_DATA,7,2) ||'/'|| SubStr(SP8.P8_DATA,5,2) ||'/'|| SubStr(SP8.P8_DATA,1,4) || ' ' || "
		_cQuery += " 								TO_CHAR(TO_DATE(to_char(P8_HORA, '00.00'),'hh24:mi'),'hh24:mi') AS P8_HORA "
		_cQuery += " 						FROM "+ RetSqlName("SP8") +" SP8 "
		_cQuery += " 						INNER JOIN "+ RetSqlName("SRA") +" SRA ON "
		_cQuery += " 							SRA.RA_FILIAL	= SP8.P8_FILIAL "
		_cQuery += " 						AND	SRA.RA_MAT		= SP8.P8_MAT "
		_cQuery += "							AND SRA.RA_CATFUNC	IN "+ FormatIn( RTrim( MV_PAR06 ) , ";" ) 
		_cQuery += " 						AND SRA.RA_SITFOLH  IN "+ FormatIn( RTrim( MV_PAR07 ) , ";" ) 
		_cQuery += "							INNER JOIN " +RetSqlName("SRJ")+ " SRJ ON RJ_FUNCAO = RA_CODFUNC  AND RJ_FILIAL = RA_FILIAL " 
		_cQuery += " 						WHERE "
		_cQuery += " 							SP8.D_E_L_E_T_	= ' ' "
		_cQuery += " 						AND	SRA.D_E_L_E_T_	= ' ' "
	
		If !Empty( MV_PAR10 )
			_cQuery += " 					AND	SRA.RA_I_SETOR	IN "+ FormatIn( AllTrim( MV_PAR10 ) , ";" ) 
		EndIf
	
		_cQuery += " 						AND SP8.P8_FILIAL	= '"+ _aFiliais[_nI] +"' " 
		_cQuery += " 						AND SP8.P8_APONTA	= 'S' "
		_cQuery += " 						AND SP8.P8_TPMCREP	<> 'D' "
		_cQuery += " 						AND SP8.P8_MAT		BETWEEN '"+ MV_PAR04 +"' AND '"+ MV_PAR05 +"' "
	
		If __nOpcao == 1
			_cQuery += " 					AND SP8.P8_DATAAPO	> '"+ DToS( _dDtAux ) +"' "
			_cQuery += " 					AND SP8.P8_DATAAPO	<= '"+ DToS( MV_PAR03 ) +"' "
		ElseIf __nOpcao == 3
			_cQuery += " 					AND SP8.P8_DATAAPO	BETWEEN '"+ DToS( MV_PAR02 ) +"' AND '"+ DToS( MV_PAR03 ) +"' "
		EndIf
	
		_cQuery += " 				) "
		_cQuery += " 		) P8 "
		_cQuery += " 			PIVOT ( MAX(P8_HORA) For RN IN (	1 AS ENT_01 , "
		_cQuery += " 												2 AS SAI_01 , "
		_cQuery += " 												3 AS ENT_02 , "
		_cQuery += " 												4 AS SAI_02 , "
		_cQuery += " 												5 AS ENT_03 , "
		_cQuery += " 												6 AS SAI_03 , "
		_cQuery += " 												7 AS ENT_04 , "
		_cQuery += " 												8 AS SAI_04 ) "
		_cQuery += " 		) "
		_cQuery += " ) A "
		
		_cQuery += " HAVING "
		
		_cQuery += "	DECODE ( TRUNC( ( TO_DATE(SubStr(A.ENT_02, 12, 5),'hh24:mi') - TO_DATE(SubStr(A.SAI_01, 12, 5),'hh24:mi') ) * 1440 ) + "
       	_cQuery += "            ABS(TRUNC( ( TO_DATE(SubStr(A.ENT_02, 12, 5),'hh24:mi') - TO_DATE(SubStr(A.SAI_01, 12, 5),'hh24:mi') ) * 1440 )),0,"
       	_cQuery += "                TRUNC( (( TO_DATE(SubStr(A.ENT_02, 12, 5),'hh24:mi') - TO_DATE(SubStr(A.SAI_01, 12, 5),'hh24:mi') ) * 1440) + 1440 ),"
       	_cQuery += "                TRUNC( ( TO_DATE(SubStr(A.ENT_02, 12, 5),'hh24:mi') - TO_DATE(SubStr(A.SAI_01, 12, 5),'hh24:mi') ) * 1440 )) < "+ _cIntMax  
				
		_cQuery += " AND (	Case	WHEN Round( ( ( TO_DATE(A.SAI_01,'DD/MM/YYYY hh24:mi') - TO_DATE(A.ENT_01,'DD/MM/YYYY hh24:mi') ) * 1440 ) , 0 ) IS NOT NULL "
		_cQuery += " 				THEN Round( ( ( TO_DATE(A.SAI_01,'DD/MM/YYYY hh24:mi') - TO_DATE(A.ENT_01,'DD/MM/YYYY hh24:mi') ) * 1440 ) , 0 ) Else 0 END + "
		_cQuery += " 		Case	WHEN Round( ( ( TO_DATE(A.SAI_02,'DD/MM/YYYY hh24:mi') - TO_DATE(A.ENT_02,'DD/MM/YYYY hh24:mi') ) * 1440 ) , 0 ) IS NOT NULL "
		_cQuery += " 				THEN Round( ( ( TO_DATE(A.SAI_02,'DD/MM/YYYY hh24:mi') - TO_DATE(A.ENT_02,'DD/MM/YYYY hh24:mi') ) * 1440 ) , 0 ) Else 0 END + "
		_cQuery += " 		Case	WHEN Round( ( ( TO_DATE(A.SAI_03,'DD/MM/YYYY hh24:mi') - TO_DATE(A.ENT_03,'DD/MM/YYYY hh24:mi') ) * 1440 ) , 0 ) IS NOT NULL "
		_cQuery += " 				THEN Round( ( ( TO_DATE(A.SAI_03,'DD/MM/YYYY hh24:mi') - TO_DATE(A.ENT_03,'DD/MM/YYYY hh24:mi') ) * 1440 ) , 0 ) Else 0 END + "
		_cQuery += " 		Case	WHEN Round( ( ( TO_DATE(A.SAI_04,'DD/MM/YYYY hh24:mi') - TO_DATE(A.ENT_04,'DD/MM/YYYY hh24:mi') ) * 1440 ) , 0 ) IS NOT NULL "
		_cQuery += " 				THEN Round( ( ( TO_DATE(A.SAI_04,'DD/MM/YYYY hh24:mi') - TO_DATE(A.ENT_04,'DD/MM/YYYY hh24:mi') ) * 1440 ) , 0 ) Else 0 END ) >= 0 "
		
		_cQuery += " GROUP BY A.P8_FILIAL, A.RA_I_SETOR, A.P8_MAT, A.RA_NOME, A.P8_DATAAPO, A.ENT_01, A.SAI_01, A.ENT_02, A.SAI_02, A.ENT_03, A.SAI_03, A.ENT_04, A.SAI_04,A.RA_CODFUNC,A.RJ_DESC,A.RA_ADMISSA,A.ZAK_COD,A.ZAK_DESCRI "
	EndIf

	_cQuery += " ORDER BY FILIAL, SETOR, NOME, DT_APO	 "
	_cQuery := ChangeQuery(_cQuery)
	MPSysOpenQuery(_cQuery,_cAlias)

	(_cAlias)->( DBGoTop() )
	(_cAlias)->( DBEval( {|| _nTotReg++ } ) )
	(_cAlias)->( DBGoTop() )
	
	ProcRegua(_nTotReg)
	
	While (_cAlias)->(!Eof())
		_nRegAtu++
		IncProc( "Lendo registros... ["+ StrZero( _nRegAtu , 9 ) +"] de ["+ StrZero( _nTotReg , 9 ) +"]" )
		
		If ( Val(SubStr((_cAlias)->ENT_02,1,2)) < Val(SubStr((_cAlias)->SAI_01,1,2)) )
			_nEnt_02	:= ( ( Val(SubStr((_cAlias)->ENT_02,1,2)) + 24 ) * 60 )	+ Val(SubStr((_cAlias)->ENT_02,4,2))
			_nSai_01	:= ( Val(SubStr((_cAlias)->SAI_01,1,2)) * 60 )			+ Val(SubStr((_cAlias)->SAI_01,4,2))
		Else
			_nEnt_02	:= ( Val(SubStr((_cAlias)->ENT_02,1,2)) * 60 ) + Val(SubStr((_cAlias)->ENT_02,4,2))
			_nSai_01	:= ( Val(SubStr((_cAlias)->SAI_01,1,2)) * 60 ) + Val(SubStr((_cAlias)->SAI_01,4,2))
		EndIf
		
		_nResInt := _nEnt_02 - _nSai_01
		cInterv	:= StrZero( INT( _nResInt / 60 ) , 2 ) +":"+ StrZero( MOD( _nResInt , 60 ) , 2 )
		
		aAdd( _aRet , {	AllTrim((_cAlias)->FILIAL)	,; //Filial
		AllTrim((_cAlias)->SETOR)						,; //Setor
		AllTrim((_cAlias)->MATRIC)						,; //Matrícula
		AllTrim(Capital(AllTrim((_cAlias)->NOME )))	,; //Funcionário
		AllTrim((_cAlias)->DESCFUNC)					,; //Desc. Funçao - Inclusao de novos campos. Chamado 7392
		AllTrim((_cAlias)->CODSET)						,; //Codigo Setor
		AllTrim((_cAlias)->DESCSET)						,; //Desc. Setor
		AllTrim(DToC((_cAlias)->DTADMIS))				,; //Dt Admissao - Fim Inclusao de novos campos.
		AllTrim(DToC((_cAlias)->DT_APO ))				,; //Data do Apontamento
		AllTrim((_cAlias)->MARCAS)						,; //Marcações da Data
		AllTrim((_cAlias)->TOTAL)						,; //Jornada
		AllTrim(cInterv)				}) 				   //Intervalo
		
		_lPrim := .F.
		_cFuncAnt := (_cAlias)->(FILIAL+MATRIC)
		(_cAlias)->( DBSkip() )
	EndDo
	(_cAlias)->(DBCloseArea())
Next _nI

Return _aRet

/*
===============================================================================================================================
Programa----------: RPON006PRT
Autor-------------: Alexandre Villar
Data da Criacao---: 28/04/2014
Descrição---------: Chamada de Impressao de Relatório dos dados de marcação de Ponto manual
Parametros--------: _aCabec	- Cabeçalho do Relatório
------------------: _aColAux	- Posicionamento das Colunas
------------------: _aColAjs	- Ajuste de posicionamento dos conteúdos
------------------: _aDados	- Dados do Relatório
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RPON006PRT(_aCabec As Array,_aColAux As Array,_aColAjs As Array,_aDados As Array)

Local _aResTot	:= {} As Array
Local _nLinha	:= 300 As Numeric
Local _nTotCol	:= Len(_aCabec) As Numeric
Local _nI		:= 0 As Numeric
Local _nX		:= 0 As Numeric
Local _nCont	:= 0 As Numeric
Local _nConFil	:= 0 As Numeric
Local _nTotFun	:= 0 As Numeric
Local _nConTot	:= 0 As Numeric
Local _nJornada	:= 0 As Numeric
Local _nInterv	:= 0 As Numeric
Local _nJorSet	:= 0 As Numeric
Local _nIntSet	:= 0 As Numeric
Local _cChvAux	:= "" As Character
Local _cSetAux	:= "" As Character
Local _cTxtCab	:= "" As Character
Local _oPrint	:= Nil As Object
Local _oFont01	:= TFont():New( "Arial" , 9 , 14 ,.F.,.T.,,.T.,,.T.,.F.) As Object
Local _oFont02	:= TFont():New( "Arial" , 9 , 08 ,.F.,.T.,,.T.,,.T.,.F.) As Object
Local _oFont03	:= TFont():New( "Arial" , 9 , 08 ,.F.,.F.,,.T.,,.T.,.F.) As Object
Local _oFont04	:= TFont():New( "Arial" , 9 , 10 ,.F.,.T.,,.T.,,.T.,.F.) As Object

//Inicializa o objeto do relatório

_oPrint := TMSPrinter():New( TITULO )
_oPrint:Setup()
_oPrint:SetLandscape()
_oPrint:SetPaperSize(9)

//Processa a impressão dos dados
For _nI := 1 To Len(_aDados)
	
	//Inicializa as variáveis de controle
	_cChvAux		:= _aDados[_nI][01] + _aDados[_nI][02] + _aDados[_nI][03]
	_nJornada	:= 0
	_nInterv		:= 0
	
	//Valida o controle do Setor atual
	If Empty(_cSetAux)
		
		//Inicializa a primeira página do relatório
		_cSetAux := _aDados[_nI][01] + _aDados[_nI][02]
		
		_cTxtCab	:= "Filial: "+	_aDados[_nI][01] +" - "+ AllTrim( Posicione("ZZM",1,xFilial("ZZM")+_aDados[_nI][01],"ZZM_DESCRI") ) +" | "
		_cTxtCab	+= "Setor: "+	_aDados[_nI][02] +" - "+ AllTrim( Posicione("ZAK",1,xFilial("ZAK")+_aDados[_nI][02],"ZAK_DESCRI") )
		
		_nLinha	:= 50000
		_nTotFun	:= 1
		
		// Verifica o posicionamento da página
		RPON006VPG( @_oPrint , @_nLinha , _aCabec , _cTxtCab , _aColAux , _oFont01 , _oFont02 , _oFont03 , _oFont04 , .F. )
		
		// Encerra Lote do Setor atual
	ElseIf (_cSetAux <> _aDados[_nI][01] + _aDados[_nI][02])
		If _nLinha > 2900
			_nLinha := 50000
			// Verifica o posicionamento da página
			RPON006VPG( @_oPrint , @_nLinha , _aCabec , _cTxtCab , _aColAux , _oFont01 , _oFont02 , _oFont03 , _oFont04 )
		EndIf
		
		// Formata a informação para a impressão
		_nJorSet		:= Round( ( _nJorSet / _nTotFun )	, 0 )
		_nIntSet		:= Round( ( _nIntSet / _nTotFun )	, 0 )
		
		__cMedInt		:= StrZero( Int( _nJorSet / 60 ) , 2 ) +":"+ StrZero( Mod( _nJorSet , 60 ) , 2 )
		cMedInt		:= StrZero( Int( _nIntSet / 60 ) , 2 ) +":"+ StrZero( Mod( _nIntSet , 60 ) , 2 )
		
		// Formata a informação para a impressão
		aAdd( _aResTot , {	SubStr(_cSetAux,1,2) +" - "+ AllTrim( Posicione("ZZM",1,xFilial("ZZM")+_aDados[_nI][01],"ZZM_DESCRI") )	,;
		AllTrim( Posicione( "ZAK" , 1 , xFilial("ZAK") + SubStr(_cSetAux,3,6) , "ZAK_DESCRI" ) )					,;
		StrZero( _nTotFun , 6 )																					,;
		StrZero( _nConFil , 6 )																					,;
		__cMedInt																									,;
		cMedInt																									})
		
		_oPrint:Say( _nLinha , 0050 , "Setor: "+ AllTrim(Posicione("ZAK",1,xFilial("ZAK")+SubStr(_cSetAux,3,6),"ZAK_DESCRI"))	, _oFont02 )
		_nLinha += 040
		_oPrint:Say( _nLinha , 0050 , "Total de Funcionários: "+ StrZero( _nTotFun , 6 )								 		, _oFont02 )
		_oPrint:Say( _nLinha , 1000 , "Total de Marcações: "+ StrZero( _nConFil , 6 )									 		, _oFont02 )
		_nLinha += 040
		_oPrint:Say( _nLinha , 0050 , "Média de Jornadas: "+ __cMedInt															, _oFont02 )
		_oPrint:Say( _nLinha , 1000 , "Média de Intervalos: "+ cMedInt														, _oFont02 )
		_nLinha += 040
		_oPrint:Line( _nLinha + 020 , 0 , _nLinha + 020 , 5000 )
		_oPrint:Line( _nLinha + 021 , 0 , _nLinha + 021 , 5000 )
		_oPrint:Line( _nLinha + 022 , 0 , _nLinha + 022 , 5000 )
		_oPrint:Line( _nLinha + 023 , 0 , _nLinha + 023 , 5000 )
		_oPrint:Line( _nLinha + 024 , 0 , _nLinha + 024 , 5000 )
		
		// Reinicia as variáveis de controle
		_nConFil	:= 0
		_nJorSet	:= 0
		_nIntSet	:= 0
		_nLinha	:= 50000
		_nTotFun	:= 1
		
		_cSetAux	:= _aDados[_nI][01] + _aDados[_nI][02]
		
		_cTxtCab	:= "Filial: "+	_aDados[_nI][01] +" - "+ AllTrim( Posicione("ZZM",1,xFilial("ZZM")+_aDados[_nI][01],"ZZM_DESCRI") ) +" | "
		_cTxtCab	+= "Setor: "+	_aDados[_nI][02] +" - "+ AllTrim( Posicione("ZAK",1,xFilial("ZAK")+_aDados[_nI][02],"ZAK_DESCRI") )
	Else
		_nLinha += 020
		_nTotFun++
	EndIf
	
	//Processa os dados do Funcionário Atual
	While _nI <= Len(_aDados) .And. _cChvAux == _aDados[_nI][01] + _aDados[_nI][02] + _aDados[_nI][03]
		//Registra o processamento

		_nCont++
		_nConFil++
		
		//Verifica o posicionamento da página
		RPON006VPG( @_oPrint , @_nLinha , _aCabec , _cTxtCab , _aColAux , _oFont01 , _oFont02 , _oFont03 , _oFont04 )
		
		// Guarda valores para o cálculo das médias
		_nJornada	+= ( Val( SubStr( _aDados[_nI][11] , 1 , 2 ) ) * 60 ) + Val( SubStr( _aDados[_nI][11] , 4 , 2 ) )
		_nInterv		+= ( Val( SubStr( _aDados[_nI][12] , 1 , 2 ) ) * 60 ) + Val( SubStr( _aDados[_nI][12] , 4 , 2 ) )
		
		// Imprime os registros do Funcionário atual
		For _nX := 3 To _nTotCol
			_oPrint:Say( _nLinha , _aColAux[_nX] + _aColAjs[_nX] , _aDados[_nI][_nX] , _oFont03 )
		Next _nX
		_nLinha += 030
		
		_nI++
	EndDo
	
	// Verifica o posicionamento da página
	RPON006VPG( @_oPrint , @_nLinha , _aCabec , _cTxtCab , _aColAux , _oFont01 , _oFont02 , _oFont03 , _oFont04 )
	
	// Calcula a média dos apontamentos
	_nJornada := Round( ( _nJornada / _nCont )	, 0 )
	_nInterv := Round( ( _nInterv / _nCont )	, 0 )
	
	// Grava a média dos apontamentos para totalizador do Setor
	_nJorSet += _nJornada
	_nIntSet += _nInterv
	
	// Formata a informação para a impressão
	__cMedInt := StrZero( Int( _nJornada / 60 )	, 2 ) +":"+ StrZero( Mod( _nJornada	, 60 ) , 2 )
	cMedInt	:= StrZero( Int( _nInterv / 60 )		, 2 ) +":"+ StrZero( Mod( _nInterv	, 60 ) , 2 )
	
	// Imprime o totalizador do Funcionário
	_oPrint:Line( _nLinha + 020 , 0 , _nLinha + 020 , 5000 )
	_oPrint:Line( _nLinha + 021 , 0 , _nLinha + 021 , 5000 )
	_oPrint:Line( _nLinha + 022 , 0 , _nLinha + 022 , 5000 )
	_nLinha += 030
	_oPrint:Say( _nLinha , _aColAux[01] , "Total de registros do Funcionário: "+ AllTrim( Transform( _nCont , "@E 999,999,999,999" ) )	, _oFont02 )
	_oPrint:Say( _nLinha , _aColAux[10] , "Média de Apontamento: "																		, _oFont02 )
	_oPrint:Say( _nLinha , _aColAux[11] + 015 , __cMedInt																				, _oFont02 )
	_oPrint:Say( _nLinha , _aColAux[12] + 020 , cMedInt																				, _oFont02 )
	_nLinha += 030
	_oPrint:Line( _nLinha + 020 , 0 , _nLinha + 020 , 5000 )
	_oPrint:Line( _nLinha + 021 , 0 , _nLinha + 021 , 5000 )
	_oPrint:Line( _nLinha + 022 , 0 , _nLinha + 022 , 5000 )
	_nLinha += 030
	
	// Ajusta as variáveis de controle
	_nI--
	_nCont := 0
Next _nI

// Considera o único ou último setor na totalização - Início
If _nLinha > 2900
	_nLinha := 50000
	// Verifica o posicionamento da página
	RPON006VPG( @_oPrint , @_nLinha , _aCabec , _cTxtCab , _aColAux , _oFont01 , _oFont02 , _oFont03 , _oFont04 )
EndIf
		
// Formata a informação para a impressão
_nJorSet		:= Round( ( _nJorSet / _nTotFun )	, 0 )
_nIntSet		:= Round( ( _nIntSet / _nTotFun )	, 0 )
		
__cMedInt		:= StrZero( Int( _nJorSet / 60 ) , 2 ) +":"+ StrZero( Mod( _nJorSet , 60 ) , 2 )
cMedInt		:= StrZero( Int( _nIntSet / 60 ) , 2 ) +":"+ StrZero( Mod( _nIntSet , 60 ) , 2 )
		
//Formata a informação para a impressão
aAdd( _aResTot , {	SubStr(_cSetAux,1,2) +" - "+ AllTrim( Posicione("ZZM",1,xFilial("ZZM")+SubStr(_cChvAux,1,2),"ZZM_DESCRI") )	,;
					AllTrim( Posicione( "ZAK" , 1 , xFilial("ZAK") + SubStr(_cSetAux,3,6) , "ZAK_DESCRI" ) )					,;
					StrZero( _nTotFun , 6 )																					,;
					StrZero( _nConFil , 6 )																					,;
					__cMedInt																									,;
					cMedInt																									})
		
_oPrint:Say( _nLinha , 0050 , "Setor: "+ AllTrim(Posicione("ZAK",1,xFilial("ZAK")+SubStr(_cSetAux,3,6),"ZAK_DESCRI"))	, _oFont02 )
_nLinha += 040
_oPrint:Say( _nLinha , 0050 , "Total de Funcionários: "+ StrZero( _nTotFun , 6 )								 		, _oFont02 )
_oPrint:Say( _nLinha , 1000 , "Total de Marcações: "+ StrZero( _nConFil , 6 )									 		, _oFont02 )
_nLinha += 040
_oPrint:Say( _nLinha , 0050 , "Média de Jornadas: "+ __cMedInt															, _oFont02 )
_oPrint:Say( _nLinha , 1000 , "Média de Intervalos: "+ cMedInt														, _oFont02 )
_nLinha += 040
_oPrint:Line( _nLinha + 020 , 0 , _nLinha + 020 , 5000 )
_oPrint:Line( _nLinha + 021 , 0 , _nLinha + 021 , 5000 )
_oPrint:Line( _nLinha + 022 , 0 , _nLinha + 022 , 5000 )
_oPrint:Line( _nLinha + 023 , 0 , _nLinha + 023 , 5000 )
_oPrint:Line( _nLinha + 024 , 0 , _nLinha + 024 , 5000 )

// Considera o único ou último setor na totalização - Fim
		
//Reinicia as variáveis de controle
_nConFil	:= 0
_nJorSet	:= 0
_nIntSet	:= 0
_nLinha	:= 50000
_nTotFun	:= 1
		
_cTxtCab	:= "Filial: "+	SubStr(_cChvAux,1,2) +" - "+ AllTrim( Posicione("ZZM",1,xFilial("ZZM")+SubStr(_cChvAux,1,2),"ZZM_DESCRI") ) +" | "
_cTxtCab	+= "Setor: "+	SubStr(_cSetAux,3,6) +" - "+ AllTrim( Posicione("ZAK",1,xFilial("ZAK")+SubStr(_cSetAux,3,6),"ZAK_DESCRI") )

_nLinha	:= 50000
_cTxtCab	:= "Resumo Geral do Relatório por Filial/Setor"
_aColAux := { ,, 0050 , 0600 , 1350 , 1650 , 1900 , 2150 }
_aColAjs := { ,, 0000 , 0000 , 0090 , 0080 , 0065 , 0080 }
_aCabec	:= { ,, "Filial" , "Setor" , "Total Funcionários" , "Total Marcações" , "Média Jornada" , "Média Intervalos" }
_cSetAux	:= ""
_nTotFun	:= 0
_nConTot := 0
_nCont	:= 0
_nConFil	:= 0

//=============================================================================
//| Verifica o posicionamento da página                                       |
//=============================================================================
RPON006VPG( @_oPrint , @_nLinha , _aCabec , _cTxtCab , _aColAux , _oFont01 , _oFont02 , _oFont03 , _oFont04 )

If !Empty(_aResTot)
	For _nI := 1 To Len( _aResTot )
		If !Empty(_cSetAux) .And. _cSetAux <> SubStr( _aResTot[_nI][01] , 1 , 2 )
			// Verifica o posicionamento da página
			RPON006VPG( @_oPrint , @_nLinha , _aCabec , _cTxtCab , _aColAux , _oFont01 , _oFont02 , _oFont03 , _oFont04 )
			
			// Grava o fechamento da Filial no relatório
			_nLinha += 020
			_oPrint:Say( _nLinha , _aColAux[03] , "Total Geral da Filial ================= [ Funcionários: "+ StrZero( _nCont , 6 ) +" ] / [ Marcações: "+ StrZero( _nConFil , 6 ) +" ]" , _oFont02 )
			_nLinha += 040
			_oPrint:Line( _nLinha , 0 , _nLinha , 5000 )
			_nLinha += 050
			
			_nCont	:= 0
			_nConFil	:= 0
		EndIf
		
		_cSetAux := SubStr( _aResTot[_nI][01] , 1 , 2 )
		
		If _nLinha > 3100
			_nLinha := 50000
			// Verifica o posicionamento da página
			RPON006VPG( @_oPrint , @_nLinha , _aCabec , _cTxtCab , _aColAux , _oFont01 , _oFont02 , _oFont03 , _oFont04 )
		EndIf
		
		// Imprime o resumo do relatório
		For _nX := 1 To Len( _aResTot[_nI] )
			_oPrint:Say( _nLinha , _aColAux[_nX+2] + _aColAjs[_nX+2] , _aResTot[_nI][_nX] , _oFont02 )
		Next _nX
		
		// Registra o total geral do relatório
		_nTotFun += Val( _aResTot[_nI][03] )
		_nCont	+= Val( _aResTot[_nI][03] )
		_nConTot	+= Val( _aResTot[_nI][04] )
		_nConFil	+= Val( _aResTot[_nI][04] )
		
		_nLinha += 035
		_oPrint:Line( _nLinha , 0 , _nLinha , 5000 )
		_nLinha += 020
	Next _nI
	
	// Verifica o posicionamento da página
	RPON006VPG( @_oPrint , @_nLinha , _aCabec , _cTxtCab , _aColAux , _oFont01 , _oFont02 , _oFont03 , _oFont04 )
	
	// Grava o fechamento da última Filial do relatório
	_nLinha += 020
	_oPrint:Say( _nLinha , _aColAux[03] , "Total Geral da Filial ================= [ Funcionários: "+ StrZero( _nCont , 6 ) +" ] / [ Marcações: "+ StrZero( _nConFil , 6 ) +" ]" , _oFont02 )
	_nLinha += 040
	_oPrint:Line( _nLinha , 0 , _nLinha , 5000 )
	_nLinha += 050
	
	// Verifica o posicionamento da página
	RPON006VPG( @_oPrint , @_nLinha , _aCabec , _cTxtCab , _aColAux , _oFont01 , _oFont02 , _oFont03 , _oFont04 )
	
	// Grava o fechamento do relatório
	_nLinha += 050
	_oPrint:Line( _nLinha , 0 , _nLinha , 5000 )
	_nLinha += 020
	_oPrint:Say( _nLinha , _aColAux[03] , "==== Total Geral ==== [ Funcionários: "+ StrZero( _nTotFun , 6 ) +" ] / [ Marcações: "+ StrZero( _nConTot , 6 ) +" ] ====" , _oFont02 )
	_nLinha += 040
	_oPrint:Line( _nLinha , 0 , _nLinha , 5000 )
Else
	// Imprime o total geral do relatório
	_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
	_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha += 7
	_oPrint:Say( _nLinha , _aColAux[01] , "Não foram encontrados registros para gerar o resumo do relatório." , _oFont01 ) ; _nLinha += 060
	_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
	_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha += 7
EndIf

// Starta o objeto de impressão
_oPrint:Preview()

Return

/*
===============================================================================================================================
Programa----------: RPON006P
Autor-------------: Alexandre Villar
Data da Criacao---: 29/04/2014
Descrição---------: Validação das Perguntas da Rotina
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/

User Function RPON006P(_nOpc aS Numeric)

Local _lRet		:= .T. As Logical//Se retornar .F. nao deixa sair do campo
Local _cNomeVar	:= ReadVar() As Character
Local _xVarAux	:= &(_cNomeVar) As Variant
Local _aArea	:= FWGetArea() As Array
Local _cEmpAux	:= cEmpAnt As Character
Local _aAcesso	:= FWEmpLoad(.F.) As Array
Local _aDadAux	:= {} As Array
Local _nI		:= 0 As Numeric
Local _nX		:= 0 as Numeric

Do Case
	Case _nOpc == 1 //Filiais Consideradas ?
		//-- Verifica se o campo esta vazio --//
		If Empty(_xVarAux)
			FWAlertWarning( "É obrigatório informar o filtro de Filiais, clique em 'selecionar todas' para utilizar todas as Filiais.","RPON00604")
			_lRet := .F.
			//-- Verifica se o campo foi preenchido com conteudo valido --//
		Else
			_aDadAux := U_ITLinDel( AllTrim(_xVarAux) )
			For _nI := 1 To Len(_aDadAux)
				_lRet := .F.
				For _nX := 1 To Len(_aAcesso)
					If _aDadAux[_nI] == _aAcesso[_nX][03]
						_lRet := .T.
					EndIf
				Next _nX
				
				If !_lRet
					FWAlertWarning("O usuário não tem acesso às 'Filiais' informadas! Verifique os dados digitados.","RPON00605")
					Exit
				EndIf
				
				_lRet := .F.
				
				SM0->( DBGoTop() )
				While SM0->(!Eof())
					If SM0->M0_CODIGO == _cEmpAux .And. AllTrim(SM0->M0_CODFIL) == _aDadAux[_nI]
						_lRet := .T.
						Exit
					EndIf
					SM0->( DBSkip() )
				EndDo
				
				If !_lRet
					FWAlertWarning("As 'Filiais' informadas não são válidas! Verifique os dados digitados." ,"RPON00606")
					Exit
				EndIf
			Next _nI
		EndIf
	Case _nOpc == 2 //Categorias a Imp. ?
		If Empty(_xVarAux)
			FWAlertWarning(  "É obrigatório informar o filtro de Categorias Funcionais, clique em 'selecionar todas' para utilizar todas as Categorias.","RPON00607")
			_lRet := .F.
		Else
			_aDadAux := U_ITLinDel( AllTrim(_xVarAux) )
			For _nI := 1 To Len(_aDadAux)
				DBSelectArea("SX5")
				SX5->( DBSetOrder(1) )
				SX5->( DBGoTop() )
				If !SX5->( DBSeek( xFilial("SX5") + "28" + _aDadAux[_nI] ) )
					FWAlertWarning(  "As 'Categorias Funcionais' informadas não são válidas! Verifique os dados digitados.","RPON00608")
					_lRet := .F.
					Exit
				EndIf
			Next _nI
		EndIf
	Case _nOpc == 3 //Situações ?
		If Empty(_xVarAux)
			&(_cNomeVar) := " ;"
		Else
			_aDadAux := U_ITLinDel( _xVarAux )
			For _nI := 1 To Len(_aDadAux)
				DBSelectArea("SX5")
				SX5->( DBSetOrder(1) )
				SX5->( DBGoTop() )
				If !SX5->( DBSeek( xFilial("SX5") + "31" + _aDadAux[_nI] ) )
					FWAlertWarning( "As 'Situações na Folha' informadas não são válidas! Verifique os dados digitados.","RPON00610")
					_lRet := .F.
					Exit
				EndIf
			Next _nI
		EndIf
		
	//Verifica se o campo "Time()" foi preenchido corretamente
	Case _nOpc == 4
		If	!( SubStr(	_xVarAux , 1 , 1 ) $ '0123456789' )	.Or.;
			!( SubStr(	_xVarAux , 2 , 1 ) $ '0123456789' )	.Or.;
			SubStr(		_xVarAux , 3 , 1 ) <> ':'			.Or.;
			!( SubStr(	_xVarAux , 4 , 1 ) $ '0123456789' )	.Or.;
			!( SubStr(	_xVarAux , 5 , 1 ) $ '0123456789' )
			
			FWAlertWarning("A hora digitada não é válida, informar o campo no formato correto: '00:00' ('HH:MM')","RPON00611")
			_lRet := .F.
		EndIf
		
		If _lRet .And. Val( SubStr(_xVarAux,4,2) ) > 59
			FWAlertWarning(  "A hora digitada não é válida, informar valores válidos entre: '00:00' e '99:59'. (Formato:'HH:MM')","RPON00612")
			_lRet := .F.
		EndIf
EndCase

FWRestArea(_aArea)

Return _lRet

/*
===============================================================================================================================
Programa----------: RPON006VPG
Autor-------------: Alexandre Villar
Data da Criacao---: 29/04/2014
Descrição---------: Validação do pocicionamento da página atual para quebras
Parametros--------: _oPrint	- Objeto de Impressão do Relatório
------------------: _nLinha	- Variável de controle do posicionamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RPON006VPG(_oPrint As Object,_nLinha As Numeric,_aCabec As Array,_cTxtCab As Character,_aColAux As Array,;
							_oFont01 As Object,_oFont02 As Object,_oFont03 As Object,_oFont04 As Object,_lFinPag As Logical)

Local _nTotCol	:= Len(_aCabec) As Numeric
Local _nLimPag	:= 2600 As Numeric
Local _nX		:= 0 As Numeric

Default _lFinPag := .T.

If _nLinha > _nLimPag
	// Encerra página atual e abre uma nova
	If _lFinPag
		_oPrint:EndPage()
	EndIf
	
	_oPrint:StartPage()
	//Reinicia o posicionamento da linha
	_nLinha	:= 280
	//Insere logo no cabecalho
	If File( "LGRL01.BMP" )
		_oPrint:SayBitmap( 050 , _aColAux[01] , "LGRL01.BMP" , 300 , 130 )
	EndIf
	
	// Desenha quadro do Título
	_oPrint:Line( 050 , 0400 , 050 , 2450 )
	_oPrint:Line( 240 , 0400 , 240 , 2450 )
	_oPrint:Line( 050 , 0400 , 240 , 0400 )
	_oPrint:Line( 050 , 2450 , 240 , 2450 )
	
	// Insere Informações no cabecalho
	_oPrint:Say( 060 , 420 , TITULO +" ( "+ DToC(Date()) +" - "+ Time() +")" , _oFont01 )
	_oPrint:Say( 120 , 420 , "Período: "+ DToC( MV_PAR02 ) +" - "+ DToC( MV_PAR03 ) +" | Filiais: "+ AllTrim( MV_PAR01 )											, _oFont02 )
	_oPrint:Say( 150 , 420 ,	"Categorias: "+ AllTrim( MV_PAR06 ) +" | Sit. Folha: "+ AllTrim( MV_PAR07 ) +" | Intervalo: "+ MV_PAR08, _oFont02 )
	
	_oPrint:Say( 190 , 420 , _cTxtCab , _oFont04 )
	
	// Adiciona cabecalho do conteúdo
	_nLinha := 255
	
	For _nX := 3 To _nTotCol
		_oPrint:Say( _nLinha , _aColAux[_nX] , _aCabec[_nX] , _oFont02 )
	Next _nX
	
	// Adiciona linha separadora e posiciona abaixo
	_oPrint:Line( 290 , 0 , 290 , 5000 )
	_nLinha := 300
EndIf

Return
