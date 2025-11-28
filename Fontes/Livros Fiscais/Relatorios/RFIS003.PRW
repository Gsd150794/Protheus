/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |04/04/2017| Chamado 19591. Retirado filtro de Devoluções para os documentos de entrada, retiradas variáveis sem 
			  |		     | uso e função que já existia no padrão.
Lucas Borges  |17/09/2019| Chamado 28346. Retirada chamada da função itputx1.
Lucas Borges  |03/09/2024| Chamado 48372. Realizado filtro para não considerar Documentos Avulsos.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RFIS003
Autor-------------: Erich Buttner
Data da Criacao---: 12/07/2013 
Descrição---------: Imprimir relatório com informações referente ao RELATORIO DO PRO LEITE para análise de custos
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RFIS003()

Public cPerg := "RFIS003"

Pergunte(cPerg,.F.)

oReport := RFIS003REL()
oReport	:PrintDialog()

Return

/*
===============================================================================================================================
Programa----------: RFIS003REL
Autor-------------: Erich Buttner
Data da Criacao---: 08/04/2013 
Descrição---------: Imprimir relatório com informações referente ao mapa de leite para análise de custos	
Parametros--------: Nenhum
Retorno-----------: Objeto com relatório montado
===============================================================================================================================
*/
Static Function RFIS003REL()

Local 	oReport
Local 	oSection1
Local 	cAliasQRY 	:= CriaTrab(Nil,.F.)
Public nVlrTot		:= 0
Public nVlrPag		:= 0

oReport := TReport():New("RFIS003","Relatório Faturamento Pró-Leite","RFIS003",{|oReport| RFIS003MAP(oReport,cAliasQRY)},"Relatório Faturamento Pró-Leite",.T.)

oSection := TRSection():New(oReport,""	,{""})
oSection:SetTotalInLine(.F.)
TRCell():New(oSection,"cPeriodo"		,/*Tabela*/,""	,/*Picture*/					,						,/*lPixel*/	,/*Block*/		 )


oSection1 := TRSection():New(oSection,""		,{"ZAY","SB1","SD1"})
oSection1:SetTotalInLine(.F.)
TRCell():New(oSection1,"CODPRO"		,/*Tabela*/,"Código"		,"@!"								,15		,/*lPixel*/	,{||CODPRO	})
TRCell():New(oSection1,"DESCR"		,/*Tabela*/,"Descrição"		,"@!"								,60		,/*lPixel*/	,{||DESCR	})
TRCell():New(oSection1,"VENDA"		,/*Tabela*/,"Saída"			,"@E 9,999,999,999.99" /*Picture*/	,16		,/*lPixel*/	,{||VENDA	})
TRCell():New(oSection1,"DEV"		,/*Tabela*/,"Devolução"		,"@E 9,999,999,999.99" /*Picture*/	,16		,/*lPixel*/	,{||DEV		})
TRCell():New(oSection1,"COMPS"     ,/*Tabela*/,"Compl Saida"   ,"@E 9,999,999,999.99" /*Picture*/  ,16		,/*Pixel*/  ,{||COMPS	})//Alteração - Talita Teixeira - 18/02/14 - Incluida a query para fazer a busca das notas de complemento. Conforme solicitado no chamado: 4384 
TRCell():New(oSection1,"nVlrTot"	,/*Tabela*/,"Total"			,"@E 9,999,999,999.99" /*Picture*/	,16		,/*lPixel*/	,{||nVlrTot	})

oSection2 := TRSection():New(oSection,"Valor a Pagar"		,{"ZAY","SB1","SD1"})
oSection2:SetTotalInLine(.F.)

TRCell():New(oSection2,"nVlrPag"		,/*Tabela*/,"Valor a Pagar"			,"@E 9,999,999,999.99"				,16	,/*lPixel*/	,{||nVlrPag	})

TRFunction():New(oSection1:Cell("VENDA"),/* cID */,"SUM",/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/)
TRFunction():New(oSection1:Cell("DEV"),/* cID */,"SUM",/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/)  
TRFunction():New(oSection1:Cell("COMPS"),/* cID */,"SUM",/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/)//Alteração - Talita Teixeira - 18/02/14 - Incluida a query para fazer a busca das notas de complemento. Conforme solicitado no chamado: 4384
TRFunction():New(oSection1:Cell("nVlrTot"),/* cID */,"SUM",/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/)

oSection1:Cell("VENDA"):SetHeaderAlign("RIGHT")
oSection1:Cell("DEV"):SetHeaderAlign("RIGHT")  
oSection1:Cell("COMPS"):SetHeaderAlign("RIGHT")//Alteração - Talita Teixeira - 18/02/14 - Incluida a query para fazer a busca das notas de complemento. Conforme solicitado no chamado: 4384
oSection1:Cell("nVlrTot"):SetHeaderAlign("RIGHT")
oSection2:Cell("nVlrPag"):SetHeaderAlign("RIGHT")

Return oReport

/*
===============================================================================================================================
Programa----------: RFIS003MAP
Autor-------------: Erich Buttner
Data da Criacao---: 08/04/2013 
Descrição---------: Imprimir relatório com informações referente ao Mapa de leite para análise de custos
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RFIS003MAP(oReport,cAliasQRY)

Local _cTpOp := "%" 
Local _cExcCF  := "%"   
Local _cExcTES := "%"   

//Parâmetro para carregar tipo de operações que devem ser consideradas
_cTpOp += FormatIn(U_ITGETMV("IT_USATES","V/T/B"),"/")+'%'

//Parâmetro para carregar cfops que não devem ser considerados
_cExcCF += FormatIn(U_ITGETMV("IT_EXCCF","5102/6102/5152/6152/5110/6110/5403/6403/5209/6209"),"/")+'%'

//Parâmetro para carregar TES que devem ser consideradas
_cExcTes += FormatIn(U_ITGETMV("IT_EXCTES",""),"/")+'%'

oReport:Section(1):BeginQuery() 
BeginSql alias cAliasQRY
	   	   
	   SELECT SB1.B1_COD CODPRO,
              SB1.B1_I_DESCD DESCR,
              NVL((SELECT SUM(SD2.D2_TOTAL) AS SAIDA
                   FROM %Table:SD2% SD2, %Table:ZAY% ZAY
                   WHERE SD2.D2_FILIAL = %xFilial:SD2%
            			 AND SD2.D2_EMISSAO BETWEEN %exp:MV_PAR01% AND %exp:MV_PAR02%
			             AND SD2.D2_COD = SB1.B1_COD
            			 AND SD2.D2_TIPO <> 'C'
            			 AND SD2.D2_CF = ZAY.ZAY_CF
            			 AND ZAY.ZAY_FILIAL = %xFilial:ZAY%
            			 AND ZAY.ZAY_TPOPER IN %Exp:_cTpOp%
            			 AND SD2.D2_TES NOT IN %Exp:_cEXCTES%  
            			 AND SD2.D2_CF NOT IN %Exp:_cExcCF% 
            			 AND SD2.D_E_L_E_T_ = ' '    
            			 AND ZAY.D_E_L_E_T_ = ' '),
              0) VENDA,
              NVL((SELECT SUM(SD1.D1_TOTAL - SD1.D1_VALDESC) AS ENTRADA
                   FROM %Table:SD1% SD1
            	   WHERE SD1.D1_FILIAL = %xFilial:SD1%
                         AND SD1.D1_COD = SB1.B1_COD  
                         AND SD1.D1_DTDIGIT BETWEEN %exp:MV_PAR01% AND %exp:MV_PAR02%
                         AND SD1.D1_TES NOT IN %Exp:_cEXCTES% 
                         AND SD1.D1_CF NOT IN %Exp:_cExcCF% 
						 AND D1_SERIE NOT BETWEEN '890' AND '899'
						 AND D1_SERIE NOT BETWEEN '910' AND '969'
                         AND SD1.%notDel%),
              0) DEV,
              NVL((SELECT SUM(COMP.D2_TOTAL)
                   FROM %Table:SD2% COMP, %Table:ZAY% ZAY
                   WHERE COMP.D2_COD = SB1.B1_COD  
                        AND COMP.D2_CF = ZAY.ZAY_CF
              			AND ZAY.ZAY_FILIAL = %xFilial:ZAY%
              			AND COMP.D2_TIPO = 'C'
              			AND COMP.D2_FILIAL = %xFilial:SD2%
              			AND ZAY.ZAY_TPOPER IN %Exp:_cTpOp%   
              			AND COMP.D2_TES NOT IN %Exp:_cEXCTES%
              			AND COMP.D2_CF NOT IN %Exp:_cExcCF%  
              			AND COMP.D2_EMISSAO BETWEEN %exp:MV_PAR01% AND %exp:MV_PAR02%
              			AND COMP.%notDel%
                        AND ZAY.%notDel%),
              0) COMPS
  	   FROM %Table:SB1% SB1
       WHERE SB1.B1_FILIAL = %xFilial:SB1%
   			AND SB1.B1_I_PROLT = 'S'
   			AND SB1.%notDel% 
	        
EndSql   

oReport:Section(1):EndQuery()

oReport:Section(1):Section(1):Init()

nInc	:= RecCount()
oReport:SetMeter(nInc)

While !oReport:Cancel() .And. (cAliasQRY)->(!Eof())
	
	nVlrTot := (cAliasQRY)->(VENDA+COMPS-DEV)
	oReport:Section(1):Section(1):PrintLine()
	nVlrPag +=	nVlrTot
	(cAliasQRY)->(DBSkip())

	If	(cAliasQRY)->(Eof())
		nVlrPag := nVlrPag * U_ITGETMV("IT_PERLT",0.007)
		oReport:Section(1):Section(1):Finish()
		oReport:Section(1):Section(2):Init()
		oReport:Section(1):Section(2):PrintLine()
	EndIf
	
EndDo

oReport:Section(1):Section(2):Finish()
oReport:Section(1):Section(2):Init()

Return
