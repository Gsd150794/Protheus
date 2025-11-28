/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
 Autor        |    Data    |                              Motivo                      										 
-------------------------------------------------------------------------------------------------------------------------------
 Lucas Borges | 11/10/2019 | Removidos os Warning na compilação da release 12.1.25. Chamado 28346                
-------------------------------------------------------------------------------------------------------------------------------
 Jerry        | 17/04/2020 | Ajustes e inclusão de melhorias nas rotinas de tabelas de preços. Chamado 28370.
===============================================================================================================================
*/
 
//==============================p======================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================
#Include "TOTVS.ch"
#Include "FWMVCDEF.CH"
#Include "TBICONN.CH"

/*
===============================================================================================================================
Programa----------: OM010QRY
Autor-------------: Josué Danich Prestes
Data da Criacao---: 09/04/2018
===============================================================================================================================
Descrição---------: Ponto de entrada para filtrar o itens da tabela de preço - Chamado 24295
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function OM010QRY()

Local aRet		:= {}
Local cCodProD	:= Space(TamSX3("DA1_CODPRO")[1])
Local cCodProA	:= Space(TamSX3("DA1_CODPRO")[1])
Local cDesProD	:= Space(50)
Local cDesProA	:= Space(50)
Local cMix   	:= Space(2)
Local cGrupoD	:= Space(TamSX3("DA1_GRUPO")[1])
Local cGrupoA	:= Space(TamSX3("DA1_GRUPO")[1])
Local dVigenD	:= SToD("")
Local dVigenA	:= SToD("")
Local cQryDA1	:= ""
Local 	cQuery := "SELECT DA1.*,DA1.R_E_C_N_O_ DA1RECNO, B1_DESC, B1_PRV1 FROM "
		
		cQuery += RetSqlName("DA1")+ " DA1 "
		cQuery += "LEFT JOIN " +RetSqlName("SB1")+ " SB1  "
		cQuery += "  ON SB1.B1_FILIAL  = '"+xFilial("SB1")+"'"
		cQuery += "  AND SB1.B1_COD     = DA1.DA1_CODPRO"
		cQuery += "  AND SB1.D_E_L_E_T_ = ' ' "
		cQuery += "WHERE DA1.DA1_FILIAL = '"+xFilial("DA1")+"'"
		cQuery += "  AND DA1.DA1_CODTAB = '"+DA0->DA0_CODTAB+"'"
		cQuery += "  AND DA1.D_E_L_E_T_ = ' ' "
		cQuery += "ORDER BY "+SqlOrder(DA1->(IndexKey()))

//Se For exclusão não faz filtro

If Type("_lexclui") == "L"

	If _lexclui

		Return cQuery
		
	EndIf
	
EndIf

Private _apergs	:= {}

aAdd( _apergs ,{1,"Produto de"	    ,cCodProD	,"@!",'.T.','SB1'	,'.T.',60,.F.})
aAdd( _apergs ,{1,"Produto ate"	    ,cCodProA	,"@!",'.T.','SB1'	,'.T.',60,.F.})
aAdd( _apergs ,{1,"Descrição de"	,cDesProD	,"@!",'.T.',		,'.T.',90,.F.})
aAdd( _apergs ,{1,"Descrição ate"   ,cDesProA	,"@!",'.T.',		,'.T.',90,.F.})
aAdd( _apergs ,{1,"Grupo de"		,cGrupoD	,"@!",'.T.','SBM'	,'.T.',40,.F.})
aAdd( _apergs ,{1,"Grupo ate"	    ,cGrupoA	,"@!",'.T.','SBM'	,'.T.',40,.F.})
aAdd( _apergs ,{1,"Vigência de"	    ,dVigenD	,"@D",'.T.',		,'.T.',40,.F.})
aAdd( _apergs ,{1,"Vigência ate"	,dVigenA	,"@D",'.T.',		,'.T.',40,.F.})
aAdd( _apergs ,{1,"Mix"	            ,cMix 	    ,"@!",'.T.',		,'.T.',2,.F.})
	
aAdd( _apergs ,{2,"Ordem","Grupo", { "Grupo+Desc.Produto","Desc.Produto","Cod.Produto","Vigencia","Mix+Descricao"}, 90,'.T.',.T.}) // 50
	
If ParamBox(_apergs ,"Parametros",aRet,,,,,,,,.T.,.T.)
	
		
		cQryDA1 := "SELECT DA1.*,DA1.R_E_C_N_O_ DA1RECNO, B1_DESC, B1_PRV1 "
		cQryDA1 += "FROM " + RetSqlName("DA1") + " DA1 "
		cQryDA1 += "JOIN " + RetSqlName("SB1") + " "
		cQryDA1 += "SB1 ON B1_FILIAL = '" + xFilial("SB1") + "' "
		cQryDA1 += "  AND B1_COD = DA1_CODPRO " 
		If !Empty(aRet[3]) .Or. !Empty(aRet[4])
			cQryDA1 += "  AND B1_DESC BETWEEN '" + aRet[3] + "' AND '" + aRet[4] + "' "
		EndIf
		cQryDA1 += "  AND SB1.D_E_L_E_T_ = ' ' "
		cQryDA1 += "WHERE DA1_FILIAL = '" + xFilial("DA1") + "' "
		cQryDA1 += "  AND DA1_CODTAB = '" + DA0->DA0_CODTAB + "' "
		If !Empty(aRet[1]) .Or. !Empty(aRet[2])
			cQryDA1 += "  AND DA1_CODPRO BETWEEN '" + aRet[1] + "' AND '" + aRet[2] + "' "
		EndIf
		If !Empty(aRet[5]) .Or. !Empty(aRet[6])
			cQryDA1 += "  AND DA1_GRUPO BETWEEN '" + aRet[5] + "' AND '" + aRet[6] + "' "
		EndIf
		If !Empty(aRet[7]) .Or. !Empty(aRet[8])
			cQryDA1 += "  AND DA1_DATVIG BETWEEN '" + DToS(aRet[7]) + "' AND '" + DToS(aRet[8]) + "' "
		EndIf
		If !Empty(aRet[9])
			cQryDA1 += "  AND DA1_I_MIX = '" + (aRet[9]) + "' " 
		EndIf
		cQryDA1 += "  AND DA1.D_E_L_E_T_ = ' ' "
	
		If ValType(aRet[10]) == "N"
			cQryDA1 += "ORDER BY DA1_FILIAL, DA1_CODTAB, B1_DESC "
		ElseIf AllTrim(aRet[10]) == "Grupo+Desc.Produto" //"Grupo"
			cQryDA1 += "ORDER BY DA1_FILIAL, DA1_CODTAB, DA1_GRUPO, B1_DESC "
		ElseIf AllTrim(aRet[10]) == "Desc.Produto"
			cQryDA1 += "ORDER BY DA1_FILIAL, DA1_CODTAB, B1_DESC "
		ElseIf AllTrim(aRet[10]) == "Cod.Produto"
			cQryDA1 += "ORDER BY DA1_FILIAL, DA1_CODTAB, DA1_CODPRO "
		ElseIf AllTrim(aRet[10]) == "Vigencia"
			cQryDA1 += "ORDER BY DA1_FILIAL, DA1_CODTAB, DA1_DATVIG "
		ElseIf AllTrim(aRet[10]) == "Mix"
			cQryDA1 += "ORDER BY DA1_FILIAL, DA1_CODTAB, DA1_I_MIX, B1_DESC "
		EndIf
		
		cquery := cQryDA1

Else
	
		U_ITMsg("Filtro cancelado, abrindo toda a tabela","Atenção",,3)
			
EndIf
	
Return cquery
