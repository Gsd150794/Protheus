/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Josué Danich  |04/04/2016| Chamado 14967. Ajuste na geração de verba de empréstimo  - Rotina ITParcel
Alex Wallauer |22/03/2019| Chamado 28571. Ajustes/Adaptações para versão Lobo Guara.
Lucas Borges  |18/09/2019| Chamado 28346. Revisão do fonte, substituição da AGPE004 por VAltSal e retirada de funçãoes.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: XFUNGPE
Autor-------------: Frederico O. C. Jr
Data da Criacao---: 21/05/2009
Descrição---------: Rotinas genéricas para utilização nos desenvolvimentos do módulo GPE
===============================================================================================================================
*/

/*
===============================================================================================================================
Programa--------: ITMedOdo
Autor-----------: Alexandre Villar
Data da Criacao-: 28/02/2014
Descrição-------: Consulta Assistencia Medica/Odontologica para tela de Integracao Funcionarios x PLS
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function ITMedOdo( cTipFor , cCodFor , cTipPla , lValid , cCodAux )

Local cQuery	:= ""
Local cCons		:= ""
Local cPosCod	:= ""
Local _cAlias	:= GetNextAlias()
Local cAliasAux	:= GetNextAlias()
Local lRet		:= .T.
Local nPosIni	:= 0
Local nRetorno	:= 0

Default lValid	:= .F.
Default cCodAux	:= ""

If cTipFor == 1 .And. cTipPla == 1		//Assistencia Medica - Faixa Salarial
	cCons := "S008"
ElseIf cTipFor == 1 .And. cTipPla == 2	//Assistencia Medica - Faixa Etaria
	cCons := "S009"
ElseIf cTipFor == 1 .And. cTipPla == 3 //Assistencia Medica - Valor Fixo
	cCons := "S028"
ElseIf cTipFor == 1 .And. cTipPla == 4 //Assistencia Medica - % Valor Salario
	cCons := "S029"
ElseIf cTipFor == 2 .And. cTipPla == 1	//Assistencia Odontologica - Faixa Salarial
	cCons := "S013"
ElseIf cTipFor == 2 .And. cTipPla == 2	//Assistencia Odontologica - Faixa Etaria 
	cCons := "S014"
ElseIf cTipFor == 2 .And. cTipPla == 3	//Assistencia Odontologica - Valor Fixo
	cCons := "S030"
ElseIf cTipFor == 2 .And. cTipPla == 4	//Assistencia Odontologica - % Valor Salario
	cCons := "S031"
EndIf

If !Empty(cCons)
	BeginSql alias _cAlias
		SELECT RCB_ORDEM POSINI
		  FROM %Table:RCB%
		 WHERE D_E_L_E_T_ = ' '
		   AND RCB_FILIAL = %xFilial:RCB%
		   AND RCB_CODIGO = %exp:cCons%
		   AND RCB_CAMPOS = 'CODFOR'
	EndSql		

	If (_cAlias)->(!Eof())
		cPosCod := (_cAlias)->POSINI
	EndIf
	(_cAlias)->(DBCloseArea())
	_cAlias := GetNextAlias()
	
	BeginSql alias _cAlias
		SELECT SUM(RCB_TAMAN) + 1 POSINI
		  FROM %Table:RCB%
		 WHERE D_E_L_E_T_ = ' '
		   AND RCB_FILIAL = %xFilial:RCB%
		   AND RCB_CODIGO = %exp:cCons%
		   AND RCB_ORDEM < %exp:cPosCod%
	EndSql
	
	If (_cAlias)->(!Eof())
		nPosIni := (_cAlias)->POSINI
	EndIf
	(_cAlias)->(DBCloseArea())

EndIf

If nPosIni > 0
	
	cQuery := " SELECT "
	cQuery += "     SubStr( RCC_CONTEU , 1 , 02 )	AS CODIGO, "
	cQuery += "     SubStr( RCC_CONTEU , 3 , 20 )	AS DESCRI, "
	cQuery += "		R_E_C_N_O_						AS REGRCC
	cQuery += " FROM "+ RetSqlName("RCC")
	cQuery += " WHERE D_E_L_E_T_ = ' ' "
	cQuery += " AND RCC_FILIAL = '"+ xFilial("RCC") +"'
	cQuery += " AND SubStr( RCC_CONTEU , "+ AllTrim(Str(nPosIni)) +" , 3 ) = '"+ cCodFor +"' "
	
	If lValid
		
		If Select(cAliasAux) > 0
			(cAliasAux)->( DBCloseArea() )
		EndIf
		
		DBUseArea( .T. , "TOPCONN" , TCGenQry(,,cQuery) , cAliasAux , .F. , .T. )
		
		lRet := .F.
		
		DBSelectArea(cAliasAux)
		(cAliasAux)->( DBGoTop() )
		While (cAliasAux)->(!Eof())
			If AllTrim( (cAliasAux)->CODIGO ) == AllTrim( cCodAux )
				lRet := .T.
				Exit
			EndIf
			(cAliasAux)->( DBSkip() )
		EndDo
		
	Else
	
		//-- Tela de Consulta Padrao a partir do resultado da Query --//
		If Tk510F3Qry( cQuery/*cQuery*/,"RCC002"/*cCodCon*/,"REGRCC"/*cCpoRecno*/,@nRetorno/*nRetorno*/,/*aCoord*/,/*aSearch*/,"RCC"/*cAlias*/)
			DBSelectArea("RCC")
			RCC->( DBGoTo( nRetorno ) )
		EndIf
	
	EndIf
	
EndIf

Return( lRet )

/*
===============================================================================================================================
Programa----------: VAltSal
Autor-------------: Heder Jose Andrade
Data da Criacao---: 04/01/2010
Descrição---------: Validação do usuário para alteração do salário de Funcionários
Parametros--------: Nenhum
Retorno-----------: Lógico : retorna se o usuário tem permissão para alterar o salário de Funcionários
===============================================================================================================================
*/
User Function VAltSal

Local _aArea 	:= FWGetArea()
Local _lRet		:= .T.

If Altera .And. Posicione("ZZL",3,xFilial("ZZL")+RetCodUsr(),"ZZL_ALTSA") <> 'S'
	_lRet := .F.
	MsgStop("O usuário não esta liberado para alterar o salário dos Funcionários!","XFUNGPE001")
EndIf

FWRestArea( _aArea )

Return( _lRet )
