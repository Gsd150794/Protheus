/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz     |27/09/2018| Chamado 26160. Realização correções relatorio e consulta específica para listar todas filiais.
Julio Paz     |09/10/2018| Chamado 26160. Correções na exibição de dados do Relatório e ajustes para exportar para Excel.
Lucas Borges  |02/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RFIS005
Autor-------------: Lucas Crevilari
Data da Criacao---: 12/12/2014
Descrição---------: Relatório de Código de Ajuste Saídas
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RFIS005

Private cPerg := "RFIS005"
Private _aOrder := {"Cod.Lançamento+Filial+NF+Serie"}
Private oSection  := Nil
Private oSection1 := Nil
Private oSection2 := Nil

Pergunte(cPerg,.F.)

oReport := RepMap()
oReport	:PrintDialog()

Return

/*
===============================================================================================================================
Programa----------: RepMap()
Autor-------------: Lucas Crevilari
Data da Criacao---: 12/12/2014
Descrição---------: Define a estrutura do Relatório de Código de Ajuste Saídas.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RepMap()

Local oReport
Local 	cAliasZLD 	:= "ZLD"
Local 	cAliasSA1 	:= "SA1"
Local 	cAliasQRY 	:= "cQRY1"
Public cNome		:= ""
Public cDescr		:= ""
Public nVlr			:= 0
Public nDif			:= 0
Public dDtEmis

oReport := TReport():New("RFIS005","Relatório de Codigo de Ajuste - Saídas","RFIS005",{|oReport| PrintMap(oReport,cAliasZLD,cAliasSA1,cAliasQRY)},"Relatório de Codigo de Ajuste - Saidas",.T.)

oSection := TRSection():New(oReport,"Codigo de Ajuste - Saídas"	,{"ZLD","ZLE","ZL3","ZLF","ZLB","ZLC"},_aOrder , .F., .T.)
oSection:SetTotalInLine(.F.)
TRCell():New(oSection,"cPeriodo"		,/*Tabela*/,"Codigo de Ajuste - Saídas",/*Picture*/,,/*lPixel*/,/*Block*/)

oSection1 := TRSection():New(oSection,"Codigo de Ajuste - Saídas",{"ZLD","ZLE","ZL3","ZLF","ZLB","ZLC"},_aOrder , .F., .T.)
oSection1:SetTotalInLine(.F.)

TRCell():New(oSection1,"CODLAN",/*Tabela*/,"Codigo Ajuste","@!",10,/*lPixel*/,{||CODLAN	})

//oSection2 := TRSection():New(oSection,"Codigo de Ajuste - Saídas",{"ZLD","ZLE","ZL3","ZLF","ZLB","ZLC"},_aOrder , .F., .T.)
oSection2 := TRSection():New(oSection1,"Codigo de Ajuste - Saídas",{"ZLD","ZLE","ZL3","ZLF","ZLB","ZLC"},_aOrder , .F., .T.)
oSection2:SetTotalInLine(.F.)
TRCell():New(oSection2,"CODLAN"		,/*Tabela*/,"Codigo Ajuste"		,"@!"							,10		,/*lPixel*/	,{||CODLAN		})
TRCell():New(oSection2,"FILIAL"		,/*Tabela*/,"Filial"			,"@!"							,09		,/*lPixel*/	,{||FILIAL		})
TRCell():New(oSection2,"DOC"		,/*Tabela*/,"Nota Fiscal"		,"@!"							,12		,/*lPixel*/	,{||DOC			})
TRCell():New(oSection2,"SERIE"		,/*Tabela*/,"Serie"				,"@!"/*Picture*/				,6		,/*lPixel*/	,{||SERIE		})
TRCell():New(oSection2,"dDtEmis"	,/*Tabela*/,"Dt.Digitaç."	    ,/*Picture*/					,12		,/*lPixel*/	,{||dDtEmis		})
TRCell():New(oSection2,"CLIENTE"	,/*Tabela*/,"Cliente"		    ,"@!"/*Picture*/				,10		,/*lPixel*/	,{||CLIENTE		})
TRCell():New(oSection2,"LOJA"		,/*Tabela*/,"Loja"				,"@!"/*Picture*/				,06		,/*lPixel*/	,{||LOJA		})
TRCell():New(oSection2,"cNome"		,/*Tabela*/,"Nome"				,"@!"/*Picture*/				,25		,/*lPixel*/	,{||cNome		})
TRCell():New(oSection2,"ITEM"		,/*Tabela*/,"Item"				,"@!"/*Picture*/				,04		,/*lPixel*/	,{||ITEM		})
TRCell():New(oSection2,"PROD"		,/*Tabela*/,"Produto"			,"@!"/*Picture*/				,18		,/*lPixel*/	,{||PROD		})
TRCell():New(oSection2,"cDescr"		,/*Tabela*/,"Descrição"			,"@!"/*Picture*/				,25		,/*lPixel*/	,{||cDescr		})
TRCell():New(oSection2,"nVlr"		,/*Tabela*/,"Valor Documento"	,"@E 9,999,999.99"/*Picture*/	,15		,/*lPixel*/	,{||nVlr		})
TRCell():New(oSection2,"APURACAO"	,/*Tabela*/,"Valor Apurado"		,"@E 9,999,999.99"/*Picture*/	,13		,/*lPixel*/	,{||APURACAO	})
TRCell():New(oSection2,"nDif"		,/*Tabela*/,"Diferença"			,"@E 9,999,999.99"/*Picture*/	,12		,/*lPixel*/	,{||nDif		})
oSection2:Cell("CODLAN"):Disable()

TRFunction():New(oSection2:Cell("nVlr"),/* cID */,"SUM",/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/)
TRFunction():New(oSection2:Cell("APURACAO"),/* cID */,"SUM",/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/)
TRFunction():New(oSection2:Cell("nDif"),/* cID */,"SUM",/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/)

Return oReport

/*
===============================================================================================================================
Programa----------: PrintMap
Autor-------------: Lucas Crevilari
Data da Criacao---: 12/12/2014
Descrição---------: Imprimir relatório com informações referente ao Mapa de leite para análise de custos conforme parâmetros
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function PrintMap(oReport,cAliasSB1,cAliasSA1,cAliasQRY)

Local nPercApu	:= 1

oSection:Enable()
oSection1:Enable()
oSection2:Enable()

_cFiliais := "%"+FormatIn(AllTrim(MV_PAR01),";")+"%"
cCodAjust := "%"+FormatIn(AllTrim(MV_PAR12),";")+"%"

oSection1:BeginQuery()

BeginSql alias cAliasQRY
	
	SELECT D2_FILIAL FILIAL,D2_DOC DOC,D2_SERIE SERIE,D2_EMISSAO EMISSAO,D2_CLIENTE CLIENTE,D2_LOJA LOJA,D2_ITEM ITEM,D2_COD PROD,D2_VALICM ICMS,D2_VALICM DIF_ALQ, CC7_CLANAP CODLAN,
		(SELECT SUM(CDA_VALOR)
		FROM %Table:CDA% CDA
		WHERE CDA.D_E_L_E_T_ = ' '
		AND	CDA_FILIAL = D2_FILIAL
		AND CDA_TPMOVI = 'S'
		AND CDA_NUMERO = D2_DOC
		AND CDA_SERIE  = D2_SERIE
		AND CDA_CLIFOR = D2_CLIENTE
		AND CDA_LOJA   = D2_LOJA
		AND CDA_CODLAN IN %exp:cCodAjust%
		AND CDA_NUMITE = D2_ITEM)APURACAO
	FROM %Table:SD2% D2, %Table:CC7% CC7
	WHERE D2.D_E_L_E_T_ = ' '
	AND CC7.D_E_L_E_T_  = ' '
	AND CC7.CC7_FILIAL  = D2.D2_FILIAL
	AND CC7.CC7_TES     = D2.D2_TES
	AND D2.D2_FILIAL    IN %exp:_cFiliais%
	AND CC7.CC7_SEQ     >= '001'
	AND D2.D2_CLIENTE BETWEEN %exp:MV_PAR06% AND %exp:MV_PAR08%
	AND D2.D2_LOJA    BETWEEN %exp:MV_PAR07% AND %exp:MV_PAR09%
	AND D2.D2_DOC     BETWEEN %exp:MV_PAR02% AND %exp:MV_PAR03%
	AND D2.D2_SERIE   BETWEEN %exp:MV_PAR04% AND %exp:MV_PAR05%
	AND CC7.CC7_CLANAP  IN %exp:cCodAjust%
	AND D2.D2_FILIAL    IN %exp:_cFiliais%
    AND D2.D2_EMISSAO BETWEEN %exp:MV_PAR10% AND %exp:MV_PAR11%
	UNION ALL
	SELECT D2_FILIAL FILIAL,D2_DOC DOC,D2_SERIE SERIE,D2_EMISSAO EMISSAO,D2_CLIENTE CLIENTE,D2_LOJA LOJA,D2_ITEM ITEM,D2_COD PROD,D2_VALICM ICMS,D2_VALICM DIF_ALQ,CC7_CODLAN CODLAN,
		(SELECT SUM(CDA_VALOR)
		FROM %Table:CDA% CDA
		WHERE CDA.D_E_L_E_T_ = ' '
		AND CDA_FILIAL = D2_FILIAL
		AND CDA_TPMOVI = 'S'
		AND CDA_NUMERO = D2_DOC
		AND CDA_SERIE  = D2_SERIE
		AND CDA_CLIFOR = D2_CLIENTE
		AND CDA_LOJA   = D2_LOJA
		AND CDA_CODLAN IN %exp:cCodAjust%
		AND CDA_NUMITE = D2_ITEM)APURACAO
	FROM %Table:SD2% D2, %Table:CC7% CC7
	WHERE D2.D_E_L_E_T_ = ' '
	AND CC7.D_E_L_E_T_  = ' '
	AND CC7.CC7_FILIAL  = D2.D2_FILIAL
	AND CC7.CC7_TES     = D2.D2_TES
	AND CC7.CC7_FILIAL  IN %exp:_cFiliais%
	AND CC7.CC7_SEQ     >= '001'
	AND D2.D2_CLIENTE BETWEEN %exp:MV_PAR06% AND %exp:MV_PAR08%
	AND D2.D2_LOJA    BETWEEN %exp:MV_PAR07% AND %exp:MV_PAR09%
	AND D2.D2_DOC     BETWEEN %exp:MV_PAR02% AND %exp:MV_PAR03%
	AND D2.D2_SERIE   BETWEEN %exp:MV_PAR04% AND %exp:MV_PAR05%
	AND CC7.CC7_CODLAN  IN %exp:cCodAjust%
	AND D2.D2_FILIAL    IN %exp:_cFiliais%
    AND D2.D2_EMISSAO BETWEEN %exp:MV_PAR10% AND %exp:MV_PAR11%
	ORDER BY 11,1,2,3,4,5,6,7
	
EndSql

oSection1:EndQuery()
oSection:Init()
oSection1:Init()
If (cAliasQRY)->(!Eof())
   oSection1:Cell("CODLAN"):SetValue((cAliasQRY)->CODLAN)
   oSection1:PrintLine()
EndIf

oSection2:Init()

nInc	:= RecCount()
oReport:SetMeter(nInc)

cCodAj := ""
If (cAliasQRY)->(!Eof())
   cCodAj := (cAliasQRY)->CODLAN
EndIf

While !oReport:Cancel() .And. (cAliasQRY)->(!Eof())
	If (cAliasQRY)->CODLAN == 'RO10000006'
		nPercApu := 0.95
	ElseIf (cAliasQRY)->CODLAN == 'RO10000003'
		nPercApu := 0.75
	ElseIf (cAliasQRY)->CODLAN == 'RO10000007'
		nPercApu := 0.7647
	ElseIf (cAliasQRY)->CODLAN == 'RO10000012'
		nPercApu := 0.85
	EndIf
	
	cNome   := GetAdvFVal("SA1","A1_NOME",xFilial("SA1")+(cAliasQRY)->CLIENTE+(cAliasQRY)->LOJA,1,"")
	cDescr  := GetAdvFVal("SB1","B1_I_DESCD",xFilial("SB1")+(cAliasQRY)->PROD,1,"")
	nVlr	:= (cAliasQRY)->DIF_ALQ*nPercApu
	nDif	:= nVlr - (cAliasQRY)->APURACAO
	dDtEmis	:= SToD((cAliasQRY)->EMISSAO)
	
	If (cAliasQRY)->CODLAN <> cCodAj
		oSection2:Finish()
		oSection1:Init()
		oSection1:Cell("CODLAN"):SetValue((cAliasQRY)->CODLAN)
        oSection1:PrintLine()
        oSection1:Finish()
        oSection2:Init()
        oSection2:Cell("CODLAN"):SetValue((cAliasQRY)->CODLAN)
        oSection2:Cell("FILIAL"):SetValue((cAliasQRY)->FILIAL)
        oSection2:Cell("DOC"):SetValue((cAliasQRY)->DOC)
        oSection2:Cell("SERIE"):SetValue((cAliasQRY)->SERIE)
        oSection2:Cell("dDtEmis"):SetValue(dDtEmis)
        oSection2:Cell("CLIENTE"):SetValue((cAliasQRY)->CLIENTE)
        oSection2:Cell("LOJA"):SetValue((cAliasQRY)->LOJA)
        oSection2:Cell("cNome"):SetValue(cNome)
        oSection2:Cell("ITEM"):SetValue((cAliasQRY)->ITEM)
        oSection2:Cell("PROD"):SetValue((cAliasQRY)->PROD)
        oSection2:Cell("cDescr"):SetValue(cDescr)
        oSection2:Cell("nVlr"):SetValue(nVlr)
        oSection2:Cell("APURACAO"):SetValue((cAliasQRY)->APURACAO)
        oSection2:Cell("nDif"):SetValue(nDif)
    
        oSection2:PrintLine()
		
		cCodAj := (cAliasQRY)->CODLAN
	Else
		oSection2:Cell("CODLAN"):SetValue((cAliasQRY)->CODLAN)
		oSection2:Cell("FILIAL"):SetValue((cAliasQRY)->FILIAL)
        oSection2:Cell("DOC"):SetValue((cAliasQRY)->DOC)
        oSection2:Cell("SERIE"):SetValue((cAliasQRY)->SERIE)
        oSection2:Cell("dDtEmis"):SetValue(dDtEmis)
        oSection2:Cell("CLIENTE"):SetValue((cAliasQRY)->CLIENTE)
        oSection2:Cell("LOJA"):SetValue((cAliasQRY)->LOJA)
        oSection2:Cell("cNome"):SetValue(cNome)
        oSection2:Cell("ITEM"):SetValue((cAliasQRY)->ITEM)
        oSection2:Cell("PROD"):SetValue((cAliasQRY)->PROD)
        oSection2:Cell("cDescr"):SetValue(cDescr)
        oSection2:Cell("nVlr"):SetValue(nVlr)
        oSection2:Cell("APURACAO"):SetValue((cAliasQRY)->APURACAO)
        oSection2:Cell("nDif"):SetValue(nDif)
		
		oSection2:PrintLine()
	EndIf
	
	(cAliasQRY)->(DBSkip())
	
EndDo

oSection:Finish()
oSection1:Finish()
oSection2:Finish()

Return
