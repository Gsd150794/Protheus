/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz     |26/09/2022| Chamado 40619 - Incluir no relatório Totalizadores: Total NF e Total Fisico.
Alex Wallauer |20/01/2022| Chamado 42645 - Correção de erro de virgula a mais na SELECT.
Lucas Borges  |09/10/2024| Chamado 48465. Retirada manipulação do SX1
===============================================================================================================================
*/
//====================================================================================================
// Definicoes de Includes e Defines da Rotina.
//====================================================================================================
#Include "TOTVS.ch"
#Include 'TOPCONN.CH' 
#DEFINE CRLF Chr(13)+Chr(10)

/*
===============================================================================================================================
Programa--------: ROMS036
Autor-----------: Erick Buttner
Data da Criacao-: 30/09/2013
Descrição-------: Relatório de Faturamento de Notas Fiscais de pallet para os clientes não cadastrados da CHEP
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function ROMS036()

Local oReport

Private _oSection2

Private cAliasQRY := GetNextAlias()
Private cAliasQRY2 := GetNextAlias()

_aItalac_F3 :={}

_cSelectSA1:="SELECT DISTINCT A1_COD, A1_NOME, A1_LOJA   FROM "+RETSQLNAME("SA1")+" SA1 WHERE A1_MSBLQL <> '1' AND D_E_L_E_T_ = ' ' ORDER BY A1_COD, A1_LOJA " 
_bCondSA1  := NIL//{|| If(MV_PAR07="2",(A1_MSBLQL = "1"),(A1_MSBLQL <> "1")) }
//aAdd(_aItalac_F3,{"MV_PAR02","SA1",SA1->(FIELDPOS("A1_COD")),{|| SA1->A1_LOJA+"-"+SA1->A1_NOME } ,_bCondSA1 ,"Clientes",,,} )
aAdd(_aItalac_F3,{"MV_PAR07",_cSelectSA1,{|Tab| (Tab)->A1_COD + (Tab)->A1_LOJA }, {|Tab| (Tab)->A1_NOME } ,_bCondSA1 ,"Clientes",,,30,.F.        ,       , } )

Pergunte("ROMS036",.T.)

oReport := Report()
oReport	:PrintDialog()

If Select(cAliasQRY) <> 0
   (cAliasQRY)->(DBCloseArea())
EndIf

If Select(cAliasQRY2) <> 0
   (cAliasQRY2)->(DBCloseArea())
EndIf

If Select("TRBZE2") <> 0
   TRBZE2->(DBCloseArea())
EndIf

Return

/*
===============================================================================================================================
Programa--------: Report
Autor-----------: Erick Buttner
Data da Criacao-: 30/09/2013
Descrição-------: Função de controle da impressão do relatório
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function Report()

Local oReport
Local oSection1 
Local cAliasSA1 := "SA1"
Local cAliasSF2 := "SF2"
//Local cAliasQRY := CriaTrab(Nil,.F.)
//Local cAliasQRY2 := GetNextAlias()

oReport := TReport():New("ROMS036","Relatório de Pallet CHEP",,{|oReport| u_Printrel(oReport,cAliasSA1,cAliasSF2,cAliasQRY,cAliasQRY2)},"Relatório de Pallet CHEP")

oSection := TRSection():New(oReport,""	,{""})
oSection:SetTotalInLine(.F.)
TRCell():New(oSection,"_Filial"		,/*Tabela*/,"Filial"	,/*Picture*/					,	40					,/*lPixel*/	,{||_Filial	}/*Block*/		 )

oSection1 := TRSection():New(oSection,"Nota Fiscais"		,{"SF2","SD2","SA1"})

oSection1:SetTotalInLine(.F.)

TRCell():New(oSection1,"NOTA"		,/*Tabela*/,"Nota Fiscal"		,/*Picture*/			,15		,/*lPixel*/	,{||NOTA	}/*Block*/	)
TRCell():New(oSection1,"SERIE"		,/*Tabela*/,"Serie"				,/*Picture*/			,03		,/*lPixel*/	,{||SERIE	}/*Block*/	)
TRCell():New(oSection1,"EMISSAO"	,/*Tabela*/,"Emissao"			,/*Picture*/			,15		,/*lPixel*/	,{||SToD(EMISSAO)	}/*Block*/	)
TRCell():New(oSection1,"CLIENTE"	,/*Tabela*/,"Cliente"			,/*Picture*/			,06		,/*lPixel*/	,{||CLIENTE	}/*Block*/	)
TRCell():New(oSection1,"LOJA"		,/*Tabela*/,"Loja"	  			,/*Picture*/			,04		,/*lPixel*/	,{||LOJA	}/*Block*/	)
TRCell():New(oSection1,"NOME"		,/*Tabela*/,"Nome"		    	,/*Picture*/ 			,60		,/*lPixel*/	,{||NOME	}/*Block*/	)
TRCell():New(oSection1,"END_CLI"	,/*Tabela*/,"Endereço"			,/*Picture*/			,40		,/*lPixel*/	,{||END_CLI	}/*Block*/	)
TRCell():New(oSection1,"QUANT"		,/*Tabela*/,"Qtde"				,"@E 999,999,999.99"	,14		,/*lPixel*/	,{||QUANT	}/*Block*/	)
TRCell():New(oSection1,"TRANSP"		,/*Tabela*/,"Transportadora"	,/*Picture*/			,60		,/*lPixel*/	,{||TRANSP	}/*Block*/	)

TRCell():New(oSection1,"ARMAZEM"	,/*Tabela*/,"Armazem"	  		,/*Picture*/			,04		,/*lPixel*/	,{||ARMAZEM	}/*Block*/	)
TRCell():New(oSection1,"CHEP"		,/*Tabela*/,"Chep"	  			,/*Picture*/			,04		,/*lPixel*/	,{||CHEP	}/*Block*/	)


TRFunction():New(oSection1:Cell("NOTA"), /* cID */,"COUNT",/*oBreak*/, /*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/)
TRFunction():New(oSection1:Cell("QUANT"), /* cID */,"SUM",/*oBreak*/, /*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/)

_oSection2 := TRSection():New(oReport,"Totalizadores"		,{"SF2","SD2","SA1","ZE2"}, {} , .F., .T.)

TRCell():New(_oSection2,"WK_FILIAL"	, "QRYTOT" /*Tabela*/ ,"Filial"		    ,/*Picture*/ ,08,/*lPixel*/	,{||WK_FILIAL	}/*Block*/	)
TRCell():New(_oSection2,"WK_TOTNF"	, "QRYTOT" /*Tabela*/ ,"Total NF"		,"@E 999,999,999.99",15,/*lPixel*/	,{||WK_TOTNF	}/*Block*/	)
TRCell():New(_oSection2,"WK_TOTFISC", "QRYTOT" /*Tabela*/ ,"Total Fisico"	,"@E 999,999,999.99",15,/*lPixel*/	,{||WK_TOTFISC	}/*Block*/	)

_oSection2:SetTotalInLine(.F.)

Return oReport

/*
===============================================================================================================================
Programa--------: PrintRel
Autor-----------: Erick Buttner
Data da Criacao-: 30/09/2013
Descrição-------: Função que Processa a impressão do relatório
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function PrintRel(oReport,cAliasSB1,cAliasSB5,cAliasQRY,cAliasQRY2)

Local oSection1 := oReport:Section(1)
Local cFiltro   := "%"
Local _cQry := ""

If ! Empty(MV_PAR01) // Filial/Filiais  
   cFiltro +=  " AND D2.D2_FILIAL IN " + FormatIn(MV_PAR01,";")
EndIf

cFiltro += 	" AND F2.F2_EMISSAO BETWEEN '"+DToS(MV_PAR02)+"' AND '"+DToS(MV_PAR03)+"' "

If MV_PAR05 = 1 //Com Saldo
	cFiltro += 	" AND (D2.D2_QUANT - D2.D2_QTDEDEV) > 0 "
ElseIf MV_PAR05 = 2 //Sem Saldo
	cFiltro += 	" AND (D2.D2_QUANT - D2.D2_QTDEDEV) <= 0 "
EndIf

If MV_PAR06 = 1 //Chep
	cFiltro += 	" AND C5_I_OPER = '50' "
ElseIf MV_PAR06 = 2 //Não Chep
	cFiltro += 	" AND C5_I_OPER = '51' "
EndIf

If !Empty(AllTrim(MV_PAR07))
	cFiltro += 	" AND D2.D2_CLIENTE || D2.D2_LOJA IN " + FormatIn(MV_PAR07,";")
EndIf

cFiltro += 	"%"

If MV_PAR04 = 1 //Com abatimento de notas de devolução

 
	oSection1:BeginQuery()

	BeginSql alias cAliasQRY

	SELECT D2.D2_FILIAL FILIAL,
		D2.D2_DOC NOTA,
		D2.D2_SERIE SERIE,
		D2.D2_EMISSAO EMISSAO,
		D2.D2_CLIENTE CLIENTE,
		D2.D2_LOJA LOJA,
		D2.D2_PEDIDO PEDIDO,
		D2.D2_ITEMPV ITEMPV,
		A1.A1_NOME NOME,
		A1.A1_END END_CLI,
		F2.F2_I_NTRAN TRANSP,
		D2.D2_LOCAL ARMAZEM,
		A1.A1_I_CCHEP CHEP,
		(D2.D2_QUANT-D2.D2_QTDEDEV) QUANT

	FROM %Table:SD2% D2
	    LEFT JOIN %Table:SA1% A1 ON (D2.D2_CLIENTE = A1.A1_COD AND D2_LOJA = A1.A1_LOJA AND A1.%notDel% )
	    LEFT JOIN %Table:SF2% F2 ON (F2.F2_FILIAL = D2.D2_FILIAL AND F2.F2_DOC = D2.D2_DOC AND F2.F2_SERIE = D2.D2_SERIE AND F2.F2_CLIENTE = D2.D2_CLIENTE AND F2.F2_LOJA = D2.D2_LOJA AND F2.%notDel% )
		LEFT JOIN %Table:SC5% C5 ON (D2.D2_FILIAL = C5.C5_FILIAL AND C5.C5_NUM = D2.D2_PEDIDO AND C5.%notDel% )
	WHERE D2.D_E_L_E_T_ = ' '
		AND D2.D2_COD 	= '08130000002'

		%exp:cFiltro%

	ORDER BY D2.D2_FILIAL, D2.D2_DOC, D2.D2_SERIE, D2.D2_COD, D2.D2_LOJA

	EndSql
	oSection1:EndQuery()

Else

	oSection1:BeginQuery()

	BeginSql alias cAliasQRY

	SELECT D2.D2_FILIAL FILIAL,
		D2.D2_DOC NOTA,
		D2.D2_SERIE SERIE,
		D2.D2_EMISSAO EMISSAO,
		D2.D2_CLIENTE CLIENTE,
		D2.D2_LOJA LOJA,
		D2.D2_PEDIDO PEDIDO,
		D2.D2_ITEMPV ITEMPV,
		A1.A1_NOME NOME,
		A1.A1_END END_CLI,
		F2.F2_I_NTRAN TRANSP,
		D2.D2_QUANT QUANT,
		D2.D2_LOCAL ARMAZEM,
		A1.A1_I_CCHEP CHEP 

	FROM %Table:SD2% D2
	    LEFT JOIN %Table:SA1% A1 ON (D2.D2_CLIENTE = A1.A1_COD AND D2_LOJA = A1.A1_LOJA AND A1.%notDel% )
	    LEFT JOIN %Table:SF2% F2 ON (F2.F2_FILIAL = D2.D2_FILIAL AND F2.F2_DOC = D2.D2_DOC AND F2.F2_SERIE = D2.D2_SERIE AND F2.F2_CLIENTE = D2.D2_CLIENTE AND F2.F2_LOJA = D2.D2_LOJA AND F2.%notDel% )
		LEFT JOIN %Table:SC5% C5 ON (C5.C5_NUM = D2.D2_PEDIDO AND C5.%notDel% )
	WHERE D2.D_E_L_E_T_ = ' '
		AND D2.D2_COD  = '08130000002'

		%exp:cFiltro%

	ORDER BY D2.D2_FILIAL, D2.D2_DOC, D2.D2_SERIE, D2.D2_COD, D2.D2_LOJA

	EndSql

	oSection1:EndQuery()  

EndIf

_cFilial := (cAliasQRY)->FILIAL
_Filial := _cFilial + '-' + FWFilialName(,_cFilial)

oReport:Section(1):Init()
oReport:Section(1):PrintLine() 
oReport:Section(1):Section(1):Init()

While (cAliasQRY)->(!Eof())
    
	If oReport:Cancel()
	   Exit
    EndIf

	oReport:IncMeter()

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

//=============================================================
// Trecho destinado a impressão dos totalizadores.
//=============================================================
_cQry := "SELECT ZE2_FILIAL, ZE2_DTCONT, ZE2_PALTOT "
_cQry += " FROM " + RetSqlName("ZE2") + " ZE2 " 
_cQry += " WHERE ZE2.D_E_L_E_T_ = ' ' "
_cQry += " AND ZE2.ZE2_DTCONT BETWEEN '"+DToS(MV_PAR02)+"' AND '"+DToS(MV_PAR03)+"' "

If ! Empty(MV_PAR01) // Filial/Filiais  
   _cQry +=  " AND ZE2_FILIAL IN " + FormatIn(MV_PAR01,";")
EndIf

_cQry += " AND ZE2_PRODUT = '08130000002' "
_cQry += " ORDER BY ZE2_FILIAL, ZE2_DTCONT "

If Select("TRBZE2") <> 0
   TRBZE2->(DBCloseArea())
EndIf

TCQUERY _cQry NEW ALIAS "TRBZE2"	
TCSetField('TRBZE2',"ZE2_DTCONT","D",8,0)

_aDadosZE2 := {}

While ! TRBZE2->(Eof())
   oReport:IncMeter()

   _nI := aScan(_aDadosZE2,{|x| x[1] == TRBZE2->ZE2_FILIAL })
   If _nI == 0
      aAdd(_aDadosZE2,{TRBZE2->ZE2_FILIAL, TRBZE2->ZE2_DTCONT, TRBZE2->ZE2_PALTOT})
   Else
      If DToS(TRBZE2->ZE2_DTCONT) >= DToS(_aDadosZE2[_nI,2])
         _aDadosZE2[_nI,2] := TRBZE2->ZE2_DTCONT
		 _aDadosZE2[_nI,3] := TRBZE2->ZE2_PALTOT  
      EndIf 
   EndIf

   TRBZE2->(DBSkip())
EndDo 

If Len(_aDadosZE2) == 0
   aAdd(_aDadosZE2, {"  ", Ctod("  /  /  "), 0}) 
EndIf 

//=========================================================================//

If MV_PAR04 = 1 //Com abatimento de notas de devolução
 
	_oSection2:BeginQuery()

	BeginSql alias "TRBTOT" //cAliasQRY2

	   SELECT D2.D2_FILIAL WK_FILIAL,
		  SUM(D2.D2_QUANT-D2.D2_QTDEDEV) WK_TOTNF
	   FROM %Table:SD2% D2
	      LEFT JOIN %Table:SA1% A1  ON (D2.D2_CLIENTE = A1.A1_COD     AND D2_LOJA = A1.A1_LOJA AND A1.%notDel% )
	      LEFT JOIN %Table:SF2% F2  ON (F2.F2_FILIAL = D2.D2_FILIAL   AND F2.F2_DOC = D2.D2_DOC AND F2.F2_SERIE = D2.D2_SERIE AND F2.F2_CLIENTE = D2.D2_CLIENTE AND F2.F2_LOJA = D2.D2_LOJA AND F2.%notDel% )
		  LEFT JOIN %Table:SC5% C5  ON (D2.D2_FILIAL = C5.C5_FILIAL   AND C5.C5_NUM = D2.D2_PEDIDO AND C5.%notDel% )
	   WHERE D2.D_E_L_E_T_ = ' '
		  AND D2.D2_COD 	= '08130000002'
		  %exp:cFiltro%
	   GROUP BY D2.D2_FILIAL
	   ORDER BY D2.D2_FILIAL

	EndSql

	_oSection2:EndQuery()

Else

	_oSection2:BeginQuery()

	BeginSql alias "TRBTOT" // cAliasQRY2

	   SELECT D2.D2_FILIAL WK_FILIAL,
	          SUM(D2.D2_QUANT-D2.D2_QTDEDEV) WK_TOTNF
	   FROM %Table:SD2% D2
	          LEFT JOIN %Table:SA1% A1 ON (D2.D2_CLIENTE = A1.A1_COD AND D2_LOJA = A1.A1_LOJA AND A1.%notDel% )
	          LEFT JOIN %Table:SF2% F2 ON (F2.F2_FILIAL = D2.D2_FILIAL AND F2.F2_DOC = D2.D2_DOC AND F2.F2_SERIE = D2.D2_SERIE AND F2.F2_CLIENTE = D2.D2_CLIENTE AND F2.F2_LOJA = D2.D2_LOJA AND F2.%notDel% )
		      LEFT JOIN %Table:SC5% C5 ON (C5.C5_NUM = D2.D2_PEDIDO AND C5.%notDel% )
	   WHERE D2.D_E_L_E_T_ = ' '
		      AND D2.D2_COD  = '08130000002'
	          %exp:cFiltro%
	   GROUP BY D2.D2_FILIAL
	   ORDER BY D2.D2_FILIAL

	EndSql

	_oSection2:EndQuery()  

EndIf

_oSection2:Enable()
_oSection2:Init()

While TRBTOT->(!Eof()) 
    
   If oReport:Cancel()
	  Exit
   EndIf

   oReport:IncMeter()

   _nI := aScan(_aDadosZE2,{|x| x[1] == TRBTOT->WK_FILIAL })
   If _nI == 0
      _oSection2:Cell("WK_TOTFISC"):SetValue(0)    
   Else
      _oSection2:Cell("WK_TOTFISC"):SetValue(_aDadosZE2[_nI,3])
   EndIf

   _oSection2:PrintLine() 
	
   TRBTOT->(DBSkip())

EndDo

_oSection2:SetPageBreak(.T.)
_oSection2:Finish()

Return
