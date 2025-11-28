/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Walaluer |30/10/2020| Chamado 34513. Inclusão do Campo CID.
Julio Paz     |30/06/2023| Chamado 44259. Alterar o relatório para exibir a descrição CID.
Julio Paz     |08/11/2023| Chamado 45508. Incluir no relatório colunas para exibir:Nrdias afastado, nome medico,CRM do Médico.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: RGPE009
Autor-----------: Erich Buttner
Data da Criacao-: 14/10/2013
Descrição-------: Imprimir relatório de funcionarios afastados de um determinado periodo
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function RGPE009()

Local oReport	:= Nil

Private cPerg	:= "RGPE009"
Private cAliasQRY := GetNextAlias() 

Pergunte( cPerg , .F. )

oReport := RGPE009RUN()

oReport:PrintDialog()

If Select(cAliasQRY) > 0
   (cAliasQRY)->(DBCloseArea())
EndIf

Return

/*
===============================================================================================================================
Programa--------: RGPE009RUN
Autor-----------: Erich Buttner
Data da Criacao-: 14/10/2013
Descrição-------: Processa a impressão do relatório
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/

Static Function RGPE009RUN()

Local oReport	:= Nil
Local oSection1	:= Nil
Local cAliasSR8 := "SR8"
Local cAliasSRA := "SRA"
//Local cAliasQRY := CriaTrab( Nil , .F. ) 

If Select(cAliasQRY) > 0
   (cAliasQRY)->(DBCloseArea())
EndIf

oReport := TReport():New( "RGPE009" , "Relatório de Afastamento" , "RGPE009" , {|oReport| RGPE009PRT( oReport , cAliasSRA , cAliasSR8 , cAliasQRY ) } , "Relatório de Afastamento" )

oSection := TRSection():New( oReport , "" , {""} )

oSection:SetTotalInLine(.F.)

TRCell():New( oSection , "_Filial" ,, "Filial" ,, 40 ,, {|| _Filial } )

oSection1 := TRSection():New( oSection , "Afastados" , { "SR8" , "SRA" } )

oSection1:SetTotalInLine(.F.)

TRCell():New( oSection1 , "MATRICULA"	,, "Matricula"			,, 10 ,, {|| (cAliasQRY)->MATRICULA	} )
TRCell():New( oSection1 , "NOME"		,, "Nome"				,, 60 ,, {|| (cAliasQRY)->NOME		} )
TRCell():New( oSection1 , "DTAFAST"		,, "Dt. Afastam."		,, 15 ,, {|| (cAliasQRY)->DTAFAST	} )
TRCell():New( oSection1 , "DTFIMAFAST"	,, "Dt. Fim. Afast."	,, 15 ,, {|| (cAliasQRY)->DTFIMAFAST	} )
TRCell():New( oSection1 , "DIASAFAST"	,, "Dias Afastado"	    ,, 14 ,, {|| (cAliasQRY)->DIASAFAST	} )
TRCell():New( oSection1 , "NOMEMEDICO"	,, "Nome do Medico"	    ,, 80 ,, {|| (cAliasQRY)->NOMEMEDICO } )
TRCell():New( oSection1 , "CRMMEDICO"	,, "CRM do Medico"	    ,, 15 ,, {|| (cAliasQRY)->CRMMEDICO } )
TRCell():New( oSection1 , "TPAFAST"		,, "Tipo Afast."		,, 60 ,, {|| U_RGPE009A((cAliasQRY)->TPAFAST , (cAliasQRY)->TIPOAFA) } )
TRCell():New( oSection1 , "AFRAIS"		,, "CID"			    ,, 10 ,, {|| (cAliasQRY)->AFRAIS		} )
TRCell():New( oSection1 , "DESCAFRAIS"	,, "Descrição CID"	    ,, 200 ,, {|| Posicione("TMR",1,xFilial("TMR")+(cAliasQRY)->AFRAIS,"TMR_DOENCA")	} )

Return( oReport )

/*
===============================================================================================================================
Programa--------: RGPE009PRT
Autor-----------: Erich Buttner
Data da Criacao-: 14/10/2013
Descrição-------: Processa a impressão do relatório
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/

Static Function RGPE009PRT( oReport , cAliasSRA , cAliasSR8 , cAliasQRY )

Local oSection1	:= oReport:Section(1)
Local cQuery	:= "%"
Local _nX		:= 0

If !Empty(AllTrim(MV_PAR05))

	cQuery += " AND RA_SITFOLH IN (' "
	
	For _nX := 1 To Len( MV_PAR05 )
	
		cQuery += SubStr( MV_PAR05 , _nX , 1 ) +"'"
		
		If ( _nX <> Len( MV_PAR05 ) )
			cQuery += ",'"
		EndIf
		
	Next _nX
	
	cQuery += ")"
	
EndIf

If !Empty(AllTrim(MV_PAR08))
	cQuery += " AND RA_FILIAL IN " +FormatIn(AllTrim(MV_PAR08),";")
EndIf

If MV_PAR07 == 1
	cQuery += " AND (R8_TIPO = 'F' OR R8_TIPOAFA = '001') "   // RETIRADA AS FERIAS OU R8_TIPOAFA == 001
ElseIf MV_PAR07 == 2
	cQuery += " AND (R8_TIPO <> 'F' AND R8_TIPOAFA <> '001') " // -- RETIRADA AS FERIAS
EndIf

cQuery += 	"%"

oSection1:BeginQuery()

BeginSql alias cAliasQRY
	SELECT RA_FILIAL FILIAL, R8_MAT MATRICULA, RA_NOME NOME, R8_DURACAO DIASAFAST, R8_NMMED NOMEMEDICO, R8_CRMMED CRMMEDICO, 
	       SubStr(R8_DATAINI, 7, 2) || '/' || SubStr(R8_DATAINI, 5, 2) || '/' || SubStr(R8_DATAINI, 1, 4) DTAFAST,
	       SubStr(R8_DATAFIM, 7, 2) || '/' || SubStr(R8_DATAFIM, 5, 2) || '/' || SubStr(R8_DATAFIM, 1, 4) DTFIMAFAST,
	       R8_TIPO TPAFAST, R8_TIPOAFA TIPOAFA, R8_CID AFRAIS
	  FROM %Table:SRA% A, %Table:SR8% B
	 WHERE A.D_E_L_E_T_ = ' '
	   AND B.D_E_L_E_T_ = ' '
	   AND RA_MAT = R8_MAT
	   AND RA_MAT BETWEEN %exp:MV_PAR03% AND %Exp:MV_PAR04%
	   AND RA_FILIAL = R8_FILIAL
	   AND (R8_DATAINI BETWEEN %exp:MV_PAR01% AND %exp:MV_PAR02% 
	   		OR R8_DATAFIM BETWEEN %exp:MV_PAR01% AND %exp:MV_PAR02%)
	   %Exp:cQuery%
	 ORDER BY RA_FILIAL, R8_MAT, RA_NOME, DTFIMAFAST
EndSql

oSection1:EndQuery()

_cFilial	:= (cAliasQRY)->FILIAL
_Filial		:= _cFilial +'-'+ FWFilialName(,_cFilial)

oReport:Section(1):Init()
oReport:Section(1):PrintLine() 
oReport:Section(1):Section(1):Init()

While (cAliasQRY)->(!Eof())
    
    If _cFilial <> (cAliasQRY)->FILIAL
    	oReport:Section(1):Finish()
    	oReport:Section(1):Section(1):Finish()
    	_cFilial := (cAliasQRY)->FILIAL
		_Filial := _cFilial + '-' + FWFilialName(,_cFilial)

		oReport:Section(1):Init()
		oReport:Section(1):PrintLine() 
    	oReport:Section(1):Section(1):Init()
    EndIf
    
    oReport:Section(1):Section(1):PrintLine() 
	DBSkip()
EndDo

oReport:Section(1):SetPageBreak(.T.)
oReport:Section(1):Finish()
oReport:Section(1):Section(1):Finish()

Return

/*
===============================================================================================================================
Programa--------: RGPE009A
Autor-----------: Julio de Paula Paz
Data da Criacao-: 16/08/2019
Descrição-------: Retornar o código e a descrição do afastamento.
Parametros------: _cTPAFAST = Código de afastamento lido do campo R8_TIPO, Descrição na tabela SX5. (Campo antigo) 
                  _cTIPOAFA = Código de afastamento lido do campo R8_TIPOAFA, Descrição na tabela RCM. (Campo novo)
Retorno---------: _cRet = Código e descrição do afastamento concatenados.
===============================================================================================================================
*/
User Function RGPE009A(_cTPAFAST , _cTIPOAFA)
Local _cRet := " "
Local _cDesc

Begin Sequence
   
   If ! Empty(_cTPAFAST)
      _cDesc := Tabela("30" , _cTPAFAST , .F.)
      _cRet := _cTPAFAST + " - " + _cDesc

   ElseIf ! Empty(_cTIPOAFA)
      _cDesc := Posicione("RCM",1,xFilial("RCM")+_cTIPOAFA,"RCM_DESCRI")
      _cRet := _cTIPOAFA + " - " + _cDesc

   EndIf

End Sequence

Return _cRet
