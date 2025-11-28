/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |17/09/2019| Chamado 28346. Retirada chamada da função itputx1.
Lucas Borges  |27/06/2025| Chamado 50617. Revisões diversas visando padronizar os fontes
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: RPON004
Autor-----------: Erich Buttner
Data da Criacao-: 17/10/2013
Descrição-------: Imprimir relatório de divergencia de importação de relogio de ponto
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function RPON004

Local oReport := Nil As Object
Local cPerg := "PON004" As Character

Pergunte(cPerg,.F.)

oReport := Report()
oReport	:PrintDialog()

Return

/*
===============================================================================================================================
Programa--------: Report
Autor-----------: Erich Buttner
Data da Criacao-: 14/10/2013
Descrição-------: Imprimir relatório de funcionarios afastados de um determinado periodo
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function Report

Local oReport	:= Nil As Object
Local oSection1 := Nil As Object

oReport := TReport():New("PON004","Relatório de divergencia de importação de Ponto","PON004",{|oReport| u_Print004Pon(oReport)},"Relatório de divergencia de importação de Ponto")
oSection := TRSection():New(oReport,""	,{""})
oSection:SetTotalInLine(.F.)
TRCell():New(oSection,"_Relogio"		,/*Tabela*/,"Relogio"	,/*Picture*/					,	40					,/*lPixel*/	,{||_Relogio	}/*Block*/		 )

oSection1 := TRSection():New(oSection,"Apontamentos",{"SP0","RFE"})

oSection1:SetTotalInLine(.F.)

TRCell():New(oSection1,"FILIAL"		,/*Tabela*/,"Filial"		,/*Picture*/			,02		,/*lPixel*/	,{||FILIAL	}/*Block*/	)
TRCell():New(oSection1,"MATRICULA"	,/*Tabela*/,"Matricula"		,/*Picture*/			,10		,/*lPixel*/	,{||MATRICULA	}/*Block*/	)
TRCell():New(oSection1,"NOME"		,/*Tabela*/,"Nome"			,/*Picture*/			,60		,/*lPixel*/	,{||NOME	}/*Block*/	)
TRCell():New(oSection1,"DTPONTO"	,/*Tabela*/,"Dt. Apontada"	,/*Picture*/			,15		,/*lPixel*/	,{||DTPONTO	}/*Block*/	)
TRCell():New(oSection1,"HRPONTO"	,/*Tabela*/,"Hr. Apontada"	,/*Picture*/			,06		,/*lPixel*/	,{||HRPONTO	}/*Block*/	)
TRCell():New(oSection1,"IDORG"		,/*Tabela*/,"Id. Ponto"		,/*Picture*/			,20		,/*lPixel*/	,{||IDORG	}/*Block*/	)

Return oReport

/*
===============================================================================================================================
Programa--------: PrintAfast
Autor-----------: Erich Buttner
Data da Criacao-: 14/10/2013
Descrição-------: Imprimir relatório de funcionarios afastados de um determinado periodo
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function Print004Pon(oReport As Object)

Local oSection1 := oReport:Section(1) As Object
Local _cAlias	:= GetNextAlias() As Character
Local cAliasQRY	:= GetNextAlias() As Character
Local _oFile	:= Nil As Object

oSection1:BeginQuery()

BeginSql alias cAliasQRY
	SELECT P0_FILIAL, P0_RELOGIO, P0_DESC, P0_ARQUIVO
	  FROM %Table:SP0%
	 WHERE D_E_L_E_T_ = ' '
	   AND P0_FILIAL = %xFilial:SP0%
	   AND P0_RELOGIO BETWEEN %exp:MV_PAR01% AND %exp:MV_PAR02%
	   AND P0_CONTROL = 'P'
	 ORDER BY P0_RELOGIO
EndSql

oSection1:EndQuery()

_cRelogio := (cAliasQRY)->P0_RELOGIO
_Relogio := _cRelogio + '-' + (cAliasQRY)->P0_DESC

oReport:Section(1):Init()
oReport:Section(1):Section(1):Init()

lRetPon := .T.

While (cAliasQRY)->(!Eof())
	_oFile:= FwFileReader():New(AllTrim((cAliasQRY)->P0_ARQUIVO))
	
	If _oFile:Open()

		If _cRelogio <> (cAliasQRY)->P0_RELOGIO
			oReport:Section(1):Finish()
			oReport:Section(1):Section(1):Finish()
			_cRelogio := (cAliasQRY)->P0_RELOGIO
			_Relogio := _cRelogio + '-' + (cAliasQRY)->P0_DESC

			oReport:Section(1):Init()
			oReport:Section(1):PrintLine() 
	    	oReport:Section(1):Section(1):Init()
		EndIf
	    
		While (_oFile:hasLine())
			cBuffer := _oFile:GetLine()
	    
			If Len(AllTrim(cBuffer)) == 34
				cIdOrg := SubStr(cBuffer,1,9)
				cDt  := SubStr(cBuffer,15,4)+SubStr(cBuffer,13,2)+SubStr(cBuffer,11,2)
				cHra := SubStr(cBuffer,19,4)
				cPis := SubStr(cBuffer,24,Len(cBuffer))
				
				BeginSql alias _cAlias
					SELECT RFE_PIS
					  FROM %Table:RFE%
					 WHERE D_E_L_E_T_ = ' '
					   AND RFE_FILIAL = %exp:(cAliasQRY)->P0_FILIAL%
					   AND RFE_LINHA = %exp:cBuffer%
				EndSql
    			
				If Empty(AllTrim((_cAlias)->RFE_PIS))
					FILIAL := xFilial("SRA")
    				MATRICULA := GetAdvFVal("SRA","RA_MAT",xFilial("SRA")+AllTrim(cPis),6,"")
    				NOME := AllTrim(GetAdvFVal("SRA","RA_NOME",xFilial("SRA")+AllTrim(cPis),6,""))
    				DTPONTO := SubStr(cDt,7,2)+"/"+SubStr(cDt,5,2)+"/"+SubStr(cDt,1,4)
					HRPONTO := SubStr(cHra,1,2)+":"+SubStr(cHra,3,2)
					IDORG 	 := cIdOrg

    				If lRetPon
    					oReport:Section(1):PrintLine() 
    					lRetPon := .F.
    				EndIf
    			
    				oReport:Section(1):Section(1):PrintLine() 
		
				EndIf
		        (_cAlias)->(DBCloseArea())
			EndIf
		EndDo
	EndIf
	
	_oFile:Close()
	_oFile := Nil
	(cAliasQRY)->(DBSkip())
EndDo

oReport:Section(1):SetPageBreak(.T.)
oReport:Section(1):Finish()
oReport:Section(1):Section(1):Finish()

Return
