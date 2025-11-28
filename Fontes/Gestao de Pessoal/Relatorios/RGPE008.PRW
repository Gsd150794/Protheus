/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz     |12/09/2019| Chamado 30478. Correção de error log na emissão do relatório.
Lucas Borges  |17/09/2019| Chamado 28346. Retirada chamada da função itputx1.
Lucas Borges  |02/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: RGPE008
Autor-----------: Erich Buttner
Data da Criacao-: 19/07/2013
Descrição-------: Relatório da Média Verba - Lançamento Mensal
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function RGPE008()

Local oReport
Local _cSelectSX5

Private _aItalac_F3:={}

Private FILIAL, SETOR, MATRICULA, VERBA  

Public _cPerg := "RGPE008"

_cSelectSX5:="SELECT X5_CHAVE CHAVE, X5_DESCRI DESCRI FROM "+RETSQLNAME("SX5")+" WHERE D_E_L_E_T_ = ' ' AND X5_TABELA = '28' AND TRIM(X5_CHAVE) NOT IN ('0','1','2','3','4','5','6','7','8','9') ORDER BY X5_CHAVE " 

//AD(_aItalac_F3,{"MV_PAR10",_cTabela   ,_nCpoChave                      , _nCpoDesc              ,_bCondTab , _cTitAux            , _nTamChv , _aDados  , _nMaxSel , _lFilAtual,_cMVRET,_bValida})
aAdd(_aItalac_F3,{"MV_PAR07",_cSelectSX5,{|Tab| Left((Tab)->CHAVE,1)} ,{|Tab|(Tab)->DESCRI} ,          ,"Lista de Categorias", 1        ,          ,    } ) 

If Pergunte( _cPerg , .T. )

	oReport := RGPE008PRT()
	oReport	:PrintDialog()

Else
	U_ITMsg(  'Operação cancelada pelo usuário!' , 'Atenção!' ,,1 )
EndIf

Return

/*
===============================================================================================================================
Programa--------: RGPE008PRT
Autor-----------: Erich Buttner
Data da Criacao-: 19/07/2013
Descrição-------: Função que imprime o relatório conforme parametrização do usuário
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/

Static Function RGPE008PRT()

Local oReport
Local oSection1
Local cAliasSRA := "SRA"
Local cAliasQRY := CriaTrab(Nil,.F.)
Local nMedHr	:= 0
Local nMedVlr	:= 0

Public oBreak1

oReport := TReport():New("RGPE008","Média Verba - Lançamento Mensal - Periodo "+MV_PAR08+" a "+MV_PAR09 ,"RGPE008",{|oReport| RGPE008PTM(oReport,cAliasSRA,cAliasQRY)},"Média Verba - Lançamento Mensal - Periodo "+MV_PAR08+" a "+MV_PAR09,.T.)

oReport:SetTotalInLine(.F.)

oSection := TRSection():New(oReport,""	,{""})

oSection:SetTotalInLine(.F.)

oSection1 := TRSection():New(oSection,"Filial"	,{""})

oSection1:SetTotalInLine(.F.)

TRCell():New( oSection1 , "FILIAL" ,, "Filial" ,, 20 ,, {|| (cAliasQRY)->RD_FILIAL + '-' + FWFilialName(,(cAliasQRY)->RD_FILIAL) } ) 

oSection2 := TRSection():New(oSection,"Setor",{""})

oSection2:SetTotalInLine(.F.)

TRCell():New( oSection2 , "SETOR" ,, "Setor: " ,, 30 ,, {|| (cAliasQRY)->RA_I_SETOR+" - "+Posicione("ZAK",1,xFilial("ZAK") + (cAliasQRY)->RA_I_SETOR,"ZAK->ZAK_DESCRI") } ) 

oSection3 := TRSection():New(oSection,"Verba"		,{""})

oSection3:SetTotalInLine(.F.)

If MV_PAR11 == 3
   TRCell():New( oSection3 , "MATRICULA"	,, "Matricula"	,, 30 ,, {|| (cAliasQRY)->MATR +" - " + (cAliasQRY)->NOME  } )
Else
   TRCell():New( oSection3 , "VERBA"		,, "Verba"		,, 30 ,, {|| (cAliasQRY)->RD_PD +" - " + (cAliasQRY)->RV_DESC  } ) 
EndIf

oSection4 := TRSection():New(oSection,"SRA"		,{"SRA"})

If MV_PAR11 == 3
	TRCell():New(oSection4,"VERB"		,/*Tabela*/,"Verba"		,/*Picture*/							,06		,/*lPixel*/	,{|| (cAliasQRY)->VERB})  
	TRCell():New(oSection4,"DES_VER"		,/*Tabela*/,"Descrição"			,/*Picture*/							,60		,/*lPixel*/	,{|| (cAliasQRY)->DES_VER}) 
Else
	TRCell():New(oSection4,"MATR"		,/*Tabela*/,"Matricula"		,/*Picture*/							,06		,/*lPixel*/	,{|| (cAliasQRY)->MATR}) // MATRICULA 
	TRCell():New(oSection4,"NOME"		,/*Tabela*/,"Nome"			,/*Picture*/							,60		,/*lPixel*/	,{|| (cAliasQRY)->NOME}) 
EndIf

If MV_PAR10 == 1
	TRCell():New(oSection4,"SALBASE"	,/*Tabela*/,"Salario Base"	,"@E 9,999,999.99" /*Picture*/		,12		,/*lPixel*/	,{|| (cAliasQRY)->SALBASE}) 
EndIf

TRCell():New(oSection4,"TOTHR"		,/*Tabela*/,"Total Horas"	,"@E 9,999,999.99" /*Picture*/		,12		,/*lPixel*/	,{|| (cAliasQRY)->TOTHR}) 
TRCell():New(oSection4,"nMedHr"  	,/*Tabela*/,"Media Horas"	,"@E 9,999,999.99" /*Picture*/		,12		,/*lPixel*/	,{|| nMedHr})
TRCell():New(oSection4,"VLRTOT"		,/*Tabela*/,"Valor Total"	,"@E 9,999,999.99" /*Picture*/		,12		,/*lPixel*/	,{|| (cAliasQRY)->VLRTOT}) 
TRCell():New(oSection4,"nMedVlr"	,/*Tabela*/,"Media Valor"	,"@E 9,999,999.99" /*Picture*/		,12		,/*lPixel*/	,{|| nMedVlr})

oBreak1:= TRBreak():New(oSection1,oSection1:CELL("FILIAL"),"Total Filial: ",.F.) 
oBreak1:SetTotalText("Total Filial: ")

TRFunction():New(oSection4:Cell("TOTHR"), /* cID */,"SUM",oBreak1/*oBreak*/, /*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.T./*lEndReport*/,/*lEndPage*/)
TRFunction():New(oSection4:Cell("nMedHr"), /* cID */,"SUM",oBreak1/*oBreak*/, /*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.T./*lEndReport*/,/*lEndPage*/)
TRFunction():New(oSection4:Cell("VLRTOT"), /* cID */,"SUM",oBreak1/*oBreak*/, /*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.T./*lEndReport*/,/*lEndPage*/)
TRFunction():New(oSection4:Cell("nMedVlr"), /* cID */,"SUM",oBreak1/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.T./*lEndReport*/,/*lEndPage*/)

If MV_PAR11 == 3
	oSection4:SetTotalText("Total Matricula ")
Else
	oSection4:SetTotalText("Total Verba ")
EndIf

oSection4:Cell("TOTHR"):SetHeaderAlign("RIGHT")
oSection4:Cell("nMedHr"):SetHeaderAlign("RIGHT")
oSection4:Cell("VLRTOT"):SetHeaderAlign("RIGHT")
oSection4:Cell("nMedVlr"):SetHeaderAlign("RIGHT")

oSection4:SetTotalInLine(.F.)


oSection5 := TRSection():New(oSection,"SRA"		,{"SRA"})
If MV_PAR11 == 3
	TRCell():New(oSection5,"VERB"		,/*Tabela*/,		,/*Picture*/							,06		,/*lPixel*/	,)
	TRCell():New(oSection5,"DES_VER"		,/*Tabela*/,		,/*Picture*/							,60		,/*lPixel*/	,)
Else
	TRCell():New(oSection5,"MATR"		,/*Tabela*/,		,/*Picture*/							,06		,/*lPixel*/	,)
	TRCell():New(oSection5,"NOME"		,/*Tabela*/,			,/*Picture*/							,60		,/*lPixel*/	,)
EndIf

If MV_PAR10 == 1
	TRCell():New(oSection5,"SAL1BASE"	,/*Tabela*/,	,"@E 9,999,999.99" /*Picture*/		,12		,/*lPixel*/	,{|| SAL1BASE}) 
EndIf

TRCell():New(oSection5,"TOT1HR"		,/*Tabela*/,	,"@E 9,999,999.99" /*Picture*/		,12		,/*lPixel*/	,{|| TOT1HR}) 
TRCell():New(oSection5,"nMed1Hr"  	,/*Tabela*/,	,"@E 9,999,999.99" /*Picture*/		,12		,/*lPixel*/	,{|| nMedHr})
TRCell():New(oSection5,"VLR1TOT"		,/*Tabela*/,	,"@E 9,999,999.99" /*Picture*/		,12		,/*lPixel*/	,{|| VLRTOT}) 
TRCell():New(oSection5,"nMed1Vlr"	,/*Tabela*/,	,"@E 9,999,999.99" /*Picture*/		,12		,/*lPixel*/	,{|| nMedVlr})

TRFunction():New(oSection5:Cell("TOT1HR"), /* cID */,"SUM",/*oBreak*/, /*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/)
TRFunction():New(oSection5:Cell("nMed1Hr"), /* cID */,"SUM",/*oBreak*/, /*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/)
TRFunction():New(oSection5:Cell("VLR1TOT"), /* cID */,"SUM",/*oBreak*/, /*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/)
TRFunction():New(oSection5:Cell("nMed1Vlr"), /* cID */,"SUM",/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/)

If MV_PAR11 == 3
	oSection5:Cell("VERB"):lVisible := .F.
	oSection5:Cell("VERB"):SetCBox('2=Não')
	oSection5:Cell("DES_VER"):lVisible := .F.
	oSection5:Cell("DES_VER"):SetLineStyle(.F.)
Else	
	oSection5:Cell("MATR"):lVisible := .F.
	oSection5:Cell("NOME"):lVisible := .F.
EndIf

If MV_PAR10 == 1
	oSection5:Cell("SAL1BASE"):lVisible := .F.
EndIf

oSection5:Cell("TOT1HR"):lVisible := .F.
oSection5:Cell("nMed1Hr"):lVisible := .F.
oSection5:Cell("VLR1TOT"):lVisible := .F.
oSection5:Cell("nMed1Vlr"):lVisible := .F.

If MV_PAR11 == 3
	oSection5:Cell("VERB"):lHeaderVisible := .F.
	oSection5:Cell("DES_VER"):lHeaderVisible := .F.
Else	
	oSection5:Cell("MATR"):lHeaderVisible := .F.
	oSection5:Cell("NOME"):lHeaderVisible := .F.
EndIf

If MV_PAR10 == 1
	oSection5:Cell("SAL1BASE"):lHeaderVisible := .F.
EndIf

oSection5:Cell("TOT1HR"):lHeaderVisible := .F.
oSection5:Cell("nMed1Hr"):lHeaderVisible := .F.
oSection5:Cell("VLR1TOT"):lHeaderVisible := .F.
oSection5:Cell("nMed1Vlr"):lHeaderVisible := .F.

oSection5:SetTotalText("Total Setor ")

oSection5:Cell("TOT1HR"):SetAlign("LEFT")
oSection5:Cell("nMed1Hr"):SetAlign("LEFT")
oSection5:Cell("VLR1TOT"):SetAlign("LEFT")
oSection5:Cell("nMed1Vlr"):SetAlign("LEFT")

oSection5:SetTotalInLine(.F.)

Return oReport

/*
===============================================================================================================================
Programa--------: RGPE008PTM
Autor-----------: Erich Buttner
Data da Criacao-: 19/07/2013
Descrição-------: Função que imprime os dados do relatório
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/

Static Function RGPE008PTM(oReport,cAliasSRA,cAliasQRY)

Local oSection1 := oReport:Section(1):Section(1)
Local _cFiltro  := "%"
Local _cFiltroL := "%"
Local oXml 

oReport:Section(1):Section(3):XmlLoad(oXml)

oReport:Section(1):Section(4):Cell("nMedHr"		):SetBlock({|| nMedHr 			})
oReport:Section(1):Section(4):Cell("nMedVlr"  	):SetBlock({|| nMedVlr 			})
oReport:Section(1):Section(5):Cell("TOT1HR"		):SetBlock({|| TOT1HR 			})
oReport:Section(1):Section(5):Cell("nMed1Hr"  	):SetBlock({|| nMed1Hr			})
oReport:Section(1):Section(5):Cell("VLR1TOT"  	):SetBlock({|| VLR1TOT 			})
oReport:Section(1):Section(5):Cell("nMed1Vlr" 	):SetBlock({|| nMed1Vlr			})

If !Empty(MV_PAR01)
	
	If !Empty(xFilial("SRD"))
		_cFiltro += " AND RD.RD_FILIAL IN " + FormatIn(MV_PAR01,";")
	EndIf
	
	If !Empty(xFilial("SRC"))
		_cFiltroL += " AND RC.RC_FILIAL IN " + FormatIn(MV_PAR01,";")
	EndIf			
	
	If !Empty(xFilial("SRA"))
		_cFiltro += " AND RA.RA_FILIAL IN " + FormatIn(MV_PAR01,";")
		_cFiltroL+= " AND RA.RA_FILIAL IN " + FormatIn(MV_PAR01,";")
	EndIf
	
	If !Empty(xFilial("SRV"))
		_cFiltro += " AND RV.RV_FILIAL IN " + FormatIn(MV_PAR01,";")
		_cFiltroL+= " AND RV.RV_FILIAL IN " + FormatIn(MV_PAR01,";")
	EndIf
	
EndIf

//Setor
If !Empty(MV_PAR04)
	_cFiltro += " AND RA.RA_I_SETOR IN " + FormatIn(MV_PAR04,";")
	_cFiltroL+= " AND RA.RA_I_SETOR IN " + FormatIn(MV_PAR04,";")
EndIf

//Verba
If !Empty(MV_PAR05)
	_cFiltro += " AND RD.RD_PD IN " + FormatIn(MV_PAR05,";")
	_cFiltroL+= " AND RC.RC_PD IN " + FormatIn(MV_PAR05,";")
EndIf

//Situacao
If !Empty(MV_PAR06)
	_cFiltro += " AND RA.RA_SITFOLH IN " + RGPE008FCM(MV_PAR06)
	_cFiltroL += " AND RA.RA_SITFOLH IN " + RGPE008FCM(MV_PAR06)
EndIf

//Categoria
If !Empty(MV_PAR07)
	_cFiltro += " AND RA.RA_CATFUNC IN " + RGPE008FCM(AllTrim(MV_PAR07))
	_cFiltroL+= " AND RA.RA_CATFUNC IN " + RGPE008FCM(AllTrim(MV_PAR07))
EndIf

//Periodo Inicial e Final
If !(MV_PAR08 == '  /    ') .And. !(MV_PAR09 == '  /    ')
	_cFiltro += "AND RD.RD_DATARQ BETWEEN '" + SubStr(MV_PAR08,4,4)+SubStr(MV_PAR08,1,2) + "' AND '" + SubStr(MV_PAR09,4,4)+SubStr(MV_PAR09,1,2) + "'"
EndIf

_cFiltro	+= "%"
_cFiltroL	+= "%"

//Verifica se o usuario escolheu a ordem de impressao verba
If MV_PAR11 == 1
	            
	If MV_PAR12 == 1
		oSection1:BeginQuery()

		BeginSql alias cAliasQRY
		SELECT	RD.RD_FILIAL,RD.RD_MAT MATR,RA.RA_NOME NOME,RD.RD_PD,RV.RV_DESC,RA.RA_SALARIO SALBASE,
		SUM(RD.RD_VALOR) VLRTOT,SUM(RD.RD_HORAS) TOTHR 
		FROM %Table:SRD% RD 
		JOIN %Table:SRA% RA ON RD.RD_FILIAL = RA.RA_FILIAL AND RD.RD_MAT = RA.RA_MAT
		JOIN %Table:SRV% RV ON RV.RV_FILIAL = RD.RD_FILIAL AND RV.RV_COD = RD.RD_PD 
		WHERE RD.%notdel%
		AND RA.%notdel%
		AND RV.%notdel%
		%Exp:_cFiltro%
		AND RD.RD_MAT BETWEEN %Exp:MV_PAR02% AND %Exp:MV_PAR03%
		GROUP BY RD.RD_FILIAL, RD.RD_MAT, RA.RA_NOME, RD.RD_PD, RV.RV_DESC, RA.RA_SALARIO 
		ORDER BY RD.RD_FILIAL,RD.RD_PD,RD.RD_MAT
	
		EndSql

		oSection1:EndQuery()
	
	ElseIf MV_PAR12 == 2
		oSection1:BeginQuery()

		BeginSql alias cAliasQRY
	
		SELECT RC.RC_FILIAL RD_FILIAL,RC.RC_MAT MATR,RA.RA_NOME NOME,RC.RC_PD RD_PD,RV.RV_DESC RV_DESC,RA.RA_SALARIO SALBASE,
		SUM(RC.RC_VALOR) VLRTOT,SUM(RC.RC_HORAS) TOTHR   
		FROM %Table:SRC% RC   
		JOIN %Table:SRA% RA ON RC.RC_FILIAL = RA.RA_FILIAL AND RC.RC_MAT = RA.RA_MAT 
		JOIN %Table:SRV% RV ON RV.RV_FILIAL = RC.RC_FILIAL AND RV.RV_COD = RC.RC_PD 
		WHERE RC.%notdel%
		AND RA.%notdel%
		AND RV.%notdel% 
		%Exp:_cFiltroL%                
		AND RC.RC_MAT BETWEEN %Exp:MV_PAR02% AND %Exp:MV_PAR03%
		GROUP BY RC.RC_FILIAL, RC.RC_MAT, RA.RA_NOME, RC.RC_PD, RV.RV_DESC, RA.RA_SALARIO         
		ORDER BY RC.RC_FILIAL,RC.RC_PD,RC.RC_MAT	 		

		EndSql

		oSection1:EndQuery()
	
	EndIf
	
	_cFilial := (cAliasQRY)->RD_FILIAL
	FILIAL := _cFilial + '-' + FWFilialName(,_cFilial)
	_cVerba := (cAliasQRY)->RD_PD
	VERBA := _cVerba+" - "+(cAliasQRY)->RV_DESC 
	oReport:Section(1):Section(1):Init()
	oReport:Section(1):Section(1):PrintLine()
	oReport:Section(1):Section(3):Init()
	oReport:Section(1):Section(3):PrintLine()
	oReport:Section(1):Section(4):Init()
		
	While (cAliasQRY)->(!Eof())
		nMeses := If ( AllTrim(MV_PAR08) == AllTrim(MV_PAR09), 1,If(Val(SubStr(AllTrim(MV_PAR09),1,2)) - Val(SubStr(AllTrim(MV_PAR08),1,2)) == 1, 2 ,INT((((LASTDAY(CTOD("01/"+MV_PAR09))-(CTOD("01/"+MV_PAR08)))/30)/12)*10)+1))
		nMedHr  := (cAliasQRY)->TOTHR/nMeses
		nMedVlr := (cAliasQRY)->VLRTOT/nMeses
			
			If _cFilial <> (cAliasQRY)->RD_FILIAL
				
				//Finaliza o box da ultima pagina da Filial corrente e imprime o totalizador por Filial
				If !Empty(_cFilial)
	
					oReport:Section(1):Section(4):Finish()
					oReport:Section(1):Section(3):Finish()
					oReport:Section(1):Section(1):Finish()
					
					_cFilial := (cAliasQRY)->RD_FILIAL
					FILIAL := _cFilial + '-' + FWFilialName(,_cFilial)

					_cVerba := (cAliasQRY)->RD_PD
					VERBA := _cVerba+" - "+(cAliasQRY)->RV_DESC 

					oReport:Section(1):Section(1):Init()
					oReport:Section(1):Section(1):PrintLine()					
					oReport:Section(1):Section(3):Init()
					oReport:Section(1):Section(3):PrintLine()					
					oReport:Section(1):Section(4):Init()
				EndIf
				
			EndIf
			If _cVerba <> 	(cAliasQRY)->RD_PD		
					oReport:Section(1):Section(4):Finish()
					oReport:Section(1):Section(3):Finish()


					_cVerba := (cAliasQRY)->RD_PD
					VERBA := _cVerba+" - "+(cAliasQRY)->RV_DESC 

					oReport:Section(1):Section(3):Init()
					oReport:Section(1):Section(3):PrintLine()					
					oReport:Section(1):Section(4):Init()

			EndIf
			
			oReport:Section(1):Section(4):PrintLine()
			
			(cAliasQRY)->(DBSkip())
		EndDo
	
ElseIf MV_PAR11 == 2

	If MV_PAR12 == 1
		oSection1:BeginQuery()

		BeginSql alias cAliasQRY
		SELECT RD.RD_FILIAL,RD.RD_MAT MATR,RA.RA_NOME NOME,RD.RD_PD,RV.RV_DESC,RA.RA_SALARIO SALBASE,RA_I_SETOR,
		SUM(RD.RD_VALOR) VLRTOT,SUM(RD.RD_HORAS) TOTHR
		FROM %Table:SRD% RD 
		JOIN %Table:SRA% RA ON RD.RD_FILIAL = RA.RA_FILIAL AND RD.RD_MAT = RA.RA_MAT 
		JOIN %Table:SRV% RV ON RV.RV_FILIAL = RD.RD_FILIAL AND RV.RV_COD = RD.RD_PD 
		WHERE RD.%notdel%
		AND RA.%notdel%
		AND RV.%notdel%
		%Exp:_cFiltro%
		AND RD.RD_MAT BETWEEN %Exp:MV_PAR02% AND %Exp:MV_PAR03%
		GROUP BY RD.RD_FILIAL, RD.RD_MAT, RA.RA_NOME, RD.RD_PD, RV.RV_DESC, RA.RA_SALARIO , RA_I_SETOR 
		ORDER BY RD.RD_FILIAL,RA_I_SETOR,RD.RD_PD,RD.RD_MAT
		
		EndSql

		oSection1:EndQuery()	
		
	ElseIf MV_PAR12 == 2
		oSection1:BeginQuery()

		BeginSql alias cAliasQRY
	
		SELECT RC.RC_FILIAL RD_FILIAL,RC.RC_MAT MATR,RA.RA_NOME NOME,RC.RC_PD RD_PD,RV.RV_DESC,RA.RA_SALARIO SALBASE,RA_I_SETOR ,
		SUM(RC.RC_VALOR) VLRTOT,SUM(RC.RC_HORAS) TOTHR     
		FROM %Table:SRC% RC   
		JOIN %Table:SRA% RA ON RC.RC_FILIAL = RA.RA_FILIAL AND RC.RC_MAT = RA.RA_MAT 
		JOIN %Table:SRV% RV ON RV.RV_FILIAL = RC.RC_FILIAL AND RV.RV_COD = RC.RC_PD  
		WHERE RC.%notdel%
		AND RA.%notdel%
		AND RV.%notdel%   
		%Exp:_cFiltroL%                 
		AND RC.RC_MAT BETWEEN %Exp:MV_PAR02% AND %Exp:MV_PAR03%  
		GROUP BY RC.RC_FILIAL, RC.RC_MAT, RA.RA_NOME, RC.RC_PD, RV.RV_DESC, RA.RA_SALARIO, RA_I_SETOR         
		ORDER BY RC.RC_FILIAL,RA_I_SETOR,RC.RC_PD,RC.RC_MAT 	

		EndSql

		oSection1:EndQuery()
		
	EndIf

	SAL1BASE := 0
	TOT1HR := 0
	nMed1Hr := 0
	VLR1TOT := 0
	nMed1Vlr := 0	
	_cFilial := (cAliasQRY)->RD_FILIAL
	FILIAL := _cFilial + '-' + FWFilialName(,_cFilial)
	_cVerba := (cAliasQRY)->RD_PD
	VERBA := _cVerba+" - "+(cAliasQRY)->RV_DESC 
	_cSetor := (cAliasQRY)->RA_I_SETOR
	SETOR := (cAliasQRY)->RA_I_SETOR+" - "+Posicione("ZAK",1,xFilial("ZAK") + (cAliasQRY)->RA_I_SETOR,"ZAK->ZAK_DESCRI")

	oReport:Section(1):Section(1):Init()
	oReport:Section(1):Section(1):PrintLine()
	oReport:Section(1):Section(2):Init()
	oReport:Section(1):Section(2):PrintLine()
	oReport:Section(1):Section(3):Init()
	oReport:Section(1):Section(3):PrintLine()
	oReport:Section(1):Section(4):Init()
	oReport:Section(1):Section(5):Init()

	While (cAliasQRY)->(!Eof())
	
		nMeses := If ( AllTrim(MV_PAR08) == AllTrim(MV_PAR09), 1,If(Val(SubStr(AllTrim(MV_PAR09),1,2)) - Val(SubStr(AllTrim(MV_PAR08),1,2)) == 1, 2 ,INT((((LASTDAY(CTOD("01/"+MV_PAR09))-(CTOD("01/"+MV_PAR08)))/30)/12)*10)+1))
		nMedHr  := (cAliasQRY)->TOTHR/nMeses
		nMedVlr := (cAliasQRY)->VLRTOT/nMeses
			
		If _cFilial <> (cAliasQRY)->RD_FILIAL
				
				If !Empty(_cFilial)

					oReport:Section(1):Section(4):Finish()
					oReport:Section(1):Section(5):PrintLine()
					oReport:Section(1):Section(5):Finish()
					oReport:Section(1):Section(2):Finish()
					oReport:Section(1):Section(3):Finish()
					oReport:Section(1):Section(1):Finish()

					_cFilial := (cAliasQRY)->RD_FILIAL
					FILIAL := _cFilial + '-' + FWFilialName(,_cFilial)
					_cVerba := (cAliasQRY)->RD_PD
					VERBA := _cVerba+" - "+(cAliasQRY)->RV_DESC 
					_cSetor := (cAliasQRY)->RA_I_SETOR
					SETOR := (cAliasQRY)->RA_I_SETOR+" - "+Posicione("ZAK",1,xFilial("ZAK") + (cAliasQRY)->RA_I_SETOR,"ZAK->ZAK_DESCRI")
					
					TOT1HR := 0
					nMed1Hr := 0
					VLR1TOT := 0
					nMed1Vlr := 0
					
					oReport:Section(1):Section(1):Init()
					oReport:Section(1):Section(1):PrintLine()
					oReport:Section(1):Section(2):Init()
					oReport:Section(1):Section(2):PrintLine()
					oReport:Section(1):Section(3):Init()
					oReport:Section(1):Section(3):PrintLine()
					oReport:Section(1):Section(4):Init()
					oReport:Section(1):Section(5):Init()
				
				EndIf
				
			EndIf

			If _cSetor <> (cAliasQRY)->RA_I_SETOR
				
					oReport:Section(1):Section(4):Finish()
					oReport:Section(1):Section(5):PrintLine()
					oReport:Section(1):Section(5):Finish()
					oReport:Section(1):Section(2):Finish()
					oReport:Section(1):Section(3):Finish()

					TOT1HR := 0
					nMed1Hr := 0
					VLR1TOT := 0
					nMed1Vlr := 0
					_cFilial := (cAliasQRY)->RD_FILIAL
					FILIAL := _cFilial + '-' + FWFilialName(,_cFilial)
					_cVerba := (cAliasQRY)->RD_PD
					VERBA := _cVerba+" - "+(cAliasQRY)->RV_DESC 
					_cSetor := (cAliasQRY)->RA_I_SETOR
					SETOR := (cAliasQRY)->RA_I_SETOR+" - "+Posicione("ZAK",1,xFilial("ZAK") + (cAliasQRY)->RA_I_SETOR,"ZAK->ZAK_DESCRI")

					oReport:Section(1):Section(2):Init()
					oReport:Section(1):Section(2):PrintLine()
					oReport:Section(1):Section(3):Init()
					oReport:Section(1):Section(3):PrintLine()
					oReport:Section(1):Section(4):Init()
					oReport:Section(1):Section(5):Init()
				
			EndIf
						
			If _cVerba <> 	(cAliasQRY)->RD_PD		
					oReport:Section(1):Section(4):Finish()
					oReport:Section(1):Section(3):Finish()


					_cVerba := (cAliasQRY)->RD_PD
					VERBA := _cVerba+" - "+(cAliasQRY)->RV_DESC 
					_cSetor := (cAliasQRY)->RA_I_SETOR
					SETOR := (cAliasQRY)->RA_I_SETOR+" - "+Posicione("ZAK",1,xFilial("ZAK") + (cAliasQRY)->RA_I_SETOR,"ZAK->ZAK_DESCRI")

					oReport:Section(1):Section(3):Init()
					oReport:Section(1):Section(3):PrintLine()					
					If _cSetor == (cAliasQRY)->RA_I_SETOR
						oReport:Section(1):Section(4):Init()
					EndIf
			EndIf

			TOT1HR += (cAliasQRY)->TOTHR
			nMed1Hr += nMedHr
			VLR1TOT += (cAliasQRY)->VLRTOT
			nMed1Vlr += nMedVlr
				
			oReport:Section(1):Section(4):PrintLine()
			
			(cAliasQRY)->(DBSkip())
		EndDo
Else

	If MV_PAR12 == 1
		oSection1:BeginQuery()

		BeginSql alias cAliasQRY
		SELECT RD.RD_FILIAL,RD.RD_MAT MATR,RA.RA_NOME NOME,RD.RD_PD VERB,RV.RV_DESC DES_VER,RA.RA_SALARIO SALBASE,RA_I_SETOR,
		SUM(RD.RD_VALOR) VLRTOT,SUM(RD.RD_HORAS) TOTHR
		FROM %Table:SRD% RD 
		JOIN %Table:SRA% RA ON RD.RD_FILIAL = RA.RA_FILIAL AND RD.RD_MAT = RA.RA_MAT 
		JOIN %Table:SRV% RV ON RV.RV_FILIAL = RD.RD_FILIAL AND RV.RV_COD = RD.RD_PD 
		WHERE RD.%notdel%
		AND RA.%notdel%
		AND RV.%notdel%
		%Exp:_cFiltro%
		AND RD.RD_MAT BETWEEN %Exp:MV_PAR02% AND %Exp:MV_PAR03%
		GROUP BY RD.RD_FILIAL, RD.RD_MAT, RA.RA_NOME, RD.RD_PD, RV.RV_DESC, RA.RA_SALARIO , RA_I_SETOR 
		ORDER BY RD.RD_FILIAL,RA_I_SETOR,RD.RD_MAT,RD.RD_PD
		
		EndSql

		oSection1:EndQuery()	
		
	ElseIf MV_PAR12 == 2
		oSection1:BeginQuery()

		BeginSql alias cAliasQRY
	
		SELECT RC.RC_FILIAL RD_FILIAL,RC.RC_MAT MATR,RA.RA_NOME NOME,RC.RC_PD VERB,RV.RV_DESC DES_VER,RA.RA_SALARIO SALBASE,RA_I_SETOR ,
		SUM(RC.RC_VALOR) VLRTOT,SUM(RC.RC_HORAS) TOTHR     
		FROM %Table:SRC% RC   
		JOIN %Table:SRA% RA ON RC.RC_FILIAL = RA.RA_FILIAL AND RC.RC_MAT = RA.RA_MAT 
		JOIN %Table:SRV% RV ON RV.RV_FILIAL = RC.RC_FILIAL AND RV.RV_COD = RC.RC_PD  
		WHERE RC.%notdel%
		AND RA.%notdel%
		AND RV.%notdel%   
		%Exp:_cFiltroL%                 
		AND RC.RC_MAT BETWEEN %Exp:MV_PAR02% AND %Exp:MV_PAR03%  
		GROUP BY RC.RC_FILIAL, RC.RC_MAT, RA.RA_NOME, RC.RC_PD, RV.RV_DESC, RA.RA_SALARIO, RA_I_SETOR         
		ORDER BY RC.RC_FILIAL,RA_I_SETOR,RC.RC_MAT,RC.RC_PD	

		EndSql

		oSection1:EndQuery()
		
	EndIf
	
	(cAliasQRY)->(DBGoTop())

	SAL1BASE := 0
	TOT1HR := 0
	nMed1Hr := 0
	VLR1TOT := 0
	nMed1Vlr := 0	
	_cFilial := (cAliasQRY)->RD_FILIAL
	FILIAL := _cFilial + '-' + FWFilialName(,_cFilial)
	_cMatricula := (cAliasQRY)->MATR
	MATRICULA := (cAliasQRY)->MATR+" - "+(cAliasQRY)->NOME 
	_cSetor := (cAliasQRY)->RA_I_SETOR
	SETOR := (cAliasQRY)->RA_I_SETOR+" - "+Posicione("ZAK",1,xFilial("ZAK") + (cAliasQRY)->RA_I_SETOR,"ZAK->ZAK_DESCRI")

	oReport:Section(1):Section(1):Init()
	oReport:Section(1):Section(1):PrintLine()
	oReport:Section(1):Section(2):Init()
	oReport:Section(1):Section(2):PrintLine()
	oReport:Section(1):Section(3):Init()
	oReport:Section(1):Section(3):PrintLine()
	oReport:Section(1):Section(4):Init()
	oReport:Section(1):Section(5):Init()

	While (cAliasQRY)->(!Eof())
	
		nMeses := If ( AllTrim(MV_PAR08) == AllTrim(MV_PAR09), 1,If(Val(SubStr(AllTrim(MV_PAR09),1,2)) - Val(SubStr(AllTrim(MV_PAR08),1,2)) == 1, 2 ,INT((((LASTDAY(CTOD("01/"+MV_PAR09))-(CTOD("01/"+MV_PAR08)))/30)/12)*10)+1))
		nMedHr  := (cAliasQRY)->TOTHR/nMeses
		nMedVlr := (cAliasQRY)->VLRTOT/nMeses
			
		If _cFilial <> (cAliasQRY)->RD_FILIAL
				
				If !Empty(_cFilial)

					oReport:Section(1):Section(4):Finish()
					oReport:Section(1):Section(5):PrintLine()
					oReport:Section(1):Section(5):Finish()
					oReport:Section(1):Section(2):Finish()
					oReport:Section(1):Section(3):Finish()
					oReport:Section(1):Section(1):Finish()

					_cFilial := (cAliasQRY)->RD_FILIAL
					FILIAL := _cFilial + '-' + FWFilialName(,_cFilial)
					_cSetor := (cAliasQRY)->RA_I_SETOR
					SETOR := (cAliasQRY)->RA_I_SETOR+" - "+Posicione("ZAK",1,xFilial("ZAK") + (cAliasQRY)->RA_I_SETOR,"ZAK->ZAK_DESCRI")
					
					TOT1HR := 0
					nMed1Hr := 0
					VLR1TOT := 0
					nMed1Vlr := 0
					oReport:EndPage(.F.)
					oReport:SetStartPage(.T.)
					
					oReport:Section(1):Section(1):Init()
					oReport:Section(1):Section(1):PrintLine()
					
					If MV_PAR13 == 1
						oReport:Section(1):Section(2):Init()
						oReport:Section(1):Section(2):PrintLine()
					EndIf
					
					oReport:Section(1):Section(3):Init()
					oReport:Section(1):Section(3):PrintLine()
					oReport:Section(1):Section(4):Init()
					
					If MV_PAR13 == 1
						oReport:Section(1):Section(5):Init()
					EndIf
					
				EndIf
				
			EndIf
			
			If _cSetor <> (cAliasQRY)->RA_I_SETOR
			
				oReport:Section(1):Section(4):Finish()
				oReport:Section(1):Section(5):PrintLine()
				oReport:Section(1):Section(5):Finish()
				oReport:Section(1):Section(2):Finish()
				oReport:Section(1):Section(3):Finish()

				TOT1HR := 0
				nMed1Hr := 0
				VLR1TOT := 0
				nMed1Vlr := 0
				_cFilial := (cAliasQRY)->RD_FILIAL
				FILIAL := _cFilial + '-' + FWFilialName(,_cFilial)
				_cMatricula := (cAliasQRY)->MATR
				MATRICULA := (cAliasQRY)->MATR+" - "+(cAliasQRY)->NOME 					
				_cSetor := (cAliasQRY)->RA_I_SETOR
				SETOR := (cAliasQRY)->RA_I_SETOR+" - "+Posicione("ZAK",1,xFilial("ZAK") + (cAliasQRY)->RA_I_SETOR,"ZAK->ZAK_DESCRI")
						
				If MV_PAR13 == 1
						oReport:EndPage(.F.)
						oReport:SetStartPage(.T.)
				EndIf
						
				oReport:Section(1):Section(2):Init()
				oReport:Section(1):Section(2):PrintLine()
				oReport:Section(1):Section(3):Init()
				oReport:Section(1):Section(3):PrintLine()
				oReport:Section(1):Section(4):Init()
				oReport:Section(1):Section(5):Init()
				
			EndIf

			If _cMatricula <> 	(cAliasQRY)->MATR		
					oReport:Section(1):Section(4):Finish()
					oReport:Section(1):Section(3):Finish()


					_cMatricula := (cAliasQRY)->MATR
					MATRICULA := (cAliasQRY)->MATR+" - "+(cAliasQRY)->NOME 					
					_cSetor := (cAliasQRY)->RA_I_SETOR
					SETOR := (cAliasQRY)->RA_I_SETOR+" - "+Posicione("ZAK",1,xFilial("ZAK") + (cAliasQRY)->RA_I_SETOR,"ZAK->ZAK_DESCRI")
					
					oReport:Section(1):Section(3):Init()
					oReport:Section(1):Section(3):PrintLine()					
					If _cSetor == (cAliasQRY)->RA_I_SETOR
						oReport:Section(1):Section(4):Init()
					EndIf
			EndIf
			
			TOT1HR += (cAliasQRY)->TOTHR
			nMed1Hr += nMedHr
			VLR1TOT += (cAliasQRY)->VLRTOT
			nMed1Vlr += nMedVlr
				
			oReport:Section(1):Section(4):PrintLine()
			
			(cAliasQRY)->(DBSkip())
		EndDo

EndIf

(cAliasQRY)->(DBCloseArea())

oReport:Section(1):Section(4):Finish()
oReport:Section(1):Section(4):Init()
oReport:Section(1):Section(5):PrintLine()
oReport:Section(1):Section(5):Finish()
oReport:Section(1):Section(5):Init()
oReport:Section(1):Section(1):Finish()
oReport:Section(1):Section(1):Init()
oReport:Section(1):Section(2):Finish()
oReport:Section(1):Section(2):Init()
oReport:Section(1):Section(3):Finish()
oReport:Section(1):Section(3):Init()

Return

/*
===============================================================================================================================
Programa--------: RGPE008FCM
Autor-----------: Erich Buttner
Data da Criacao-: 19/07/2013
Descrição-------: Função que formata o conteúdo de um campo
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function RGPE008FCM( _cDados )

Local _cStrFormt:= "("
Local _nX		:= 0

For _nX:=1 To Len(_cDados)
	_cStrFormt += "'"+ SubStr( _cDados , _nX , 1 ) +"',"
Next _nX

_cStrFormt:= SubStr(_cStrFormt,1,Len(_cStrFormt) - 1) + ")"

Return( _cStrFormt )
