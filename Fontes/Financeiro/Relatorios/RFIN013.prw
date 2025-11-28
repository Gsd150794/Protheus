/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Talita        |08/01/2014| Chamaro 5122. Corrigido o erro que estava ocorrendo com relação ao parâmetro maior.
Alexandre V.  |22/12/2015| Chamado 13062. Tratativa na cláusula "ORDER BY" para remover a referência numérica.
Lucas Borges  |11/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: RFIN013
Autor-----------: Talita Teixeira
Data da Criacao-: 08/04/2013
Descrição-------: Relatório para verificar as comissões pagas indevidamente à vendedores e coordenadores
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function RFIN013()

Local oReport

Pergunte("RFIN013",.F.)

oReport := Report()

oReport:PrintDialog()

Return

/*
===============================================================================================================================
Programa--------: Report
Autor-----------: Talita Teixeira
Data da Criacao-: 08/04/2013
Descrição-------: Relatório para verificar as comissões pagas indevidamente à vendedores e coordenadores
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function Report()

Local oReport
Local oSection1 
Local cAliasSD2 := "SD2"
Local cAliasSE5 := "SE5"
Local cAliasSE3 := "SE3"
Local cAliasQRY := CriaTrab(Nil,.F.)

oReport := TReport():New("RFIN013","Relatório de Comissão Indevida","RFIN013",{|oReport| u_PrintDifComi(oReport,cAliasSD2,cAliasSE5,cAliasSE3,cAliasQRY)},"Relatório de Comissão Indevida")

oSection := TRSection():New(oReport,""	,{""})
oSection:SetTotalInLine(.F.)
TRCell():New(oSection,"_NomeVend"		,/*Tabela*/,"Vendedor"	,/*Picture*/,	40	,/*lPixel*/	,{||_NomeVend	}/*Block*/)

oSection1 := TRSection():New(oSection,"Diferença de Comissão"		,{"SD2","SE3","SE5"})

oSection1:SetTotalInLine(.F.)

TRCell():New( oSection1 , "E3_FILIAL"		,/*Tabela*/, "Filial"			,/*Picture*/			, 03 ,/*lPixel*/, {||E3_FILIAL		} /*Block*/ )
TRCell():New( oSection1 , "E3_NUM"			,/*Tabela*/, "Nota Fiscal"		,/*Picture*/			, 09 ,/*lPixel*/, {||E3_NUM			} /*Block*/ )
TRCell():New( oSection1 , "E3_SERIE"		,/*Tabela*/, "Serie"			,/*Picture*/			, 03 ,/*lPixel*/, {||E3_SERIE		} /*Block*/ )
TRCell():New( oSection1 , "D2_EMISSAO"		,/*Tabela*/, "Dt de Emissão"	,/*Picture*/			, 15 ,/*lPixel*/, {||D2_EMISSAO		} /*Block*/ ) 
TRCell():New( oSection1 , "E3_CODCLI"		,/*Tabela*/, "Cliente"			,/*Picture*/			, 06 ,/*lPixel*/, {||E3_CODCLI		} /*Block*/ )
TRCell():New( oSection1 , "E3_LOJA"			,/*Tabela*/, "Loja"	  			,/*Picture*/			, 05 ,/*lPixel*/, {||E3_LOJA		} /*Block*/ )
TRCell():New( oSection1 , "BASE_E3"			,/*Tabela*/, "Base E3"			,"@E 999,999,999.99"	, 10 ,/*lPixel*/, {||BASE_E3		} /*Block*/ )
TRCell():New( oSection1 , "COMIS_PG"		,/*Tabela*/, "Comissão Paga"	,"@E 999,999,999.99"	, 10 ,/*lPixel*/, {||COMIS_PG		} /*Block*/ )
TRCell():New( oSection1 , "VL_BAIXA"		,/*Tabela*/, "Valor da Baixa"	,"@E 999,999,999.99"	, 10 ,/*lPixel*/, {||VL_BAIXA		} /*Block*/ )
TRCell():New( oSection1 , "PERC_MED"		,/*Tabela*/, "Percentual Med"	,"@E 999,999,999.99"	, 04 ,/*lPixel*/, {||PERC_MED		} /*Block*/ )
TRCell():New( oSection1 , "VALOR_A_PAGAR"	,/*Tabela*/, "Valor a Pagar"	,"@E 999,999,999.99"	, 10 ,/*lPixel*/, {||VALOR_A_PAGAR	} /*Block*/ )
TRCell():New( oSection1 , "DIF_COMIS"		,/*Tabela*/, "Diferença"		,"@E 999,999,999.99"	, 10 ,/*lPixel*/, {||DIF_COMIS		} /*Block*/ )

TRFunction():New(oSection1:Cell("DIF_COMIS"),/* cID */,"SUM",/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,/*lEndReport*/,/*lEndPage*/)

Return( oReport )

/*
===============================================================================================================================
Programa--------: PrintDifComi
Autor-----------: Talita Teixeira
Data da Criacao-: 30/09/2013
Descrição-------: Relatório para verificar as comissões pagas indevidamente à vendedores e coordenadores
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function PrintDifComi(oReport,cAliasSE5,cAliasSE3,cAliasSD2,cAliasQRY)

Local oSection1 := oReport:Section(1)
Local nCont:= 0

oSection1:BeginQuery()

BeginSql alias cAliasQRY

SELECT EFET.E3_FILIAL,
       EFET.E3_VEND,
       EFET.E3_NUM,
       EFET.E3_SERIE,
       CORRET.D2_EMISSAO,
       EFET.E3_CODCLI,
       EFET.E3_LOJA,
       EFET.BASE_E3,
       EFET.COMIS_PG,
       CORRET.VL_BAIXA,
       CORRET.RAZAO_CORRETA,
       CORRET.PERC_MED,
       CORRET.VALOR_A_PAGAR,
       EFET.COMIS_PG - CORRET.VALOR_A_PAGAR DIF_COMIS
  FROM (SELECT E3_FILIAL,
               E3_VEND,
               E3_NUM,
               E3_SERIE,
               E3_CODCLI,
               E3_LOJA,
               SUM(E3_BASE) BASE_E3,
               SUM(E3_COMIS) COMIS_PG
          FROM %Table:SE3%, %Table:SE5%
         WHERE SE3010.D_E_L_E_T_ = ' '
           AND SE5010.D_E_L_E_T_ = ' '
           AND E5_FILIAL = E3_FILIAL
           AND E5_PREFIXO = E3_PREFIXO
           AND E3_NUM = E5_NUMERO
           AND E5_PARCELA = E3_PARCELA
           AND E3_CODCLI = E5_CLIFOR
           AND E3_LOJA = E5_LOJA
           AND E3_TIPO = E5_TIPO
           AND E3_SEQ = E5_SEQ
           AND E5_TIPODOC = 'VL'
           AND E5_MOTBX = 'NOR'
           AND E3_VEND BETWEEN %exp:MV_PAR03% AND %exp:MV_PAR04%
         GROUP BY E3_FILIAL,
                  E3_VEND,
                  E3_NUM,
                  E3_SERIE,
                  E3_CODCLI,
                  E3_LOJA,
                  E3_PEDIDO) EFET,
       (SELECT QRY2.D2_FILIAL,
               QRY2.F2_VEND1,
               QRY2.D2_EMISSAO,
               QRY2.D2_DOC,
               QRY2.D2_SERIE,
               QRY2.D2_CLIENTE,
               QRY2.D2_LOJA,
               QRY2.PERC_MED,
               SUM(QRY2.BASE),
               SUM(QRY2.RETIDO),
               SUM(QRY2.VALOR_BAIXA) VL_BAIXA,
               Round(SUM(QRY2.VALOR_BAIXA) * (SUM(QRY2.COMISSAO) / SUM(QRY2.BASE)),
                     2) COMIS_BAIXA,
               Round(SUM(QRY2.BASE) / (SUM(QRY2.BASE) + SUM(QRY2.RETIDO)), 6) RAZAO_CORRETA,
               Round(SUM(QRY2.VALOR_BAIXA) * (SUM(QRY2.COMISSAO) / SUM(QRY2.BASE)) * (Round(SUM(QRY2.BASE) / (SUM(QRY2.BASE) + SUM(QRY2.RETIDO)),
                            6)),
                     2) VALOR_A_PAGAR
          FROM (SELECT QRY1.D2_FILIAL,
                       QRY1.F2_VEND1,
                       QRY1.D2_EMISSAO,
                       QRY1.D2_DOC,
                       QRY1.D2_SERIE,
                       QRY1.D2_CLIENTE,
                       QRY1.D2_LOJA,
                       SUM(TOTAL_D2) BASE,
                       Round((SUM(COMIS) / SUM(TOTAL_D2)) * 100, 2) PERC_MED,
                       SUM(COMIS) COMISSAO,
                       SUM(ICMSRET_D2) RETIDO,
                       NVL((SELECT SUM(E5_VALOR) - SUM(E5_VLJUROS) - SUM(E5_VLMULTA)
                          FROM %Table:SE5%
                         WHERE SE5010.D_E_L_E_T_ = ' '
                           AND D2_FILIAL = E5_FILIAL
                           AND D2_DOC = E5_NUMERO
                           AND D2_SERIE = E5_PREFIXO
                           AND D2_CLIENTE = E5_CLIFOR
                           AND D2_LOJA = E5_LOJA
                           AND E5_TIPO = 'NF'
                           AND E5_TIPODOC = 'VL'
                           AND E5_MOTBX = 'NOR'),0) - NVL((SELECT SUM(E5_VALOR) - SUM(E5_VLJUROS) - SUM(E5_VLMULTA)
                          FROM %Table:SE5%
                         WHERE SE5010.D_E_L_E_T_ = ' '
                           AND D2_FILIAL = E5_FILIAL
                           AND D2_DOC = E5_NUMERO
                           AND D2_SERIE = E5_PREFIXO
                           AND D2_CLIENTE = E5_CLIFOR
                           AND D2_LOJA = E5_LOJA
                           AND E5_TIPO = 'NF'
                           AND E5_TIPODOC = 'ES'
                           AND E5_MOTBX = 'NOR'),0)
                            VALOR_BAIXA
                  FROM (SELECT D2_FILIAL,
                               F2_VEND1,
                               D2_EMISSAO,
                               D2_DOC,
                               D2_SERIE,
                               D2_CLIENTE,
                               D2_LOJA,
                               SUM(D2_TOTAL) TOTAL_D2,
                               SUM(D2_ICMSRET) ICMSRET_D2,
                               D2_COMIS1,
                               Round(SUM(D2_TOTAL) * D2_COMIS1 / 100, 2) COMIS
                          FROM %Table:SD2%, %Table:SF2%
                         WHERE SD2010.D_E_L_E_T_ = ' '
                           AND SF2010.D_E_L_E_T_ = ' '
                           AND D2_EMISSAO BETWEEN %exp:DToS(MV_PAR01)% AND %exp:DToS(MV_PAR02)%
                           AND F2_FILIAL = D2_FILIAL
                           AND F2_DOC = D2_DOC
                           AND F2_SERIE = D2_SERIE
                           AND F2_EMISSAO = D2_EMISSAO
                           AND F2_CLIENTE = D2_CLIENTE
                           AND F2_LOJA = D2_LOJA
                           AND D2_COMIS1 > 0
                           AND D2_TOTAL > 0
                         GROUP BY D2_FILIAL,
                                  F2_VEND1,
                                  D2_EMISSAO,
                                  D2_DOC,
                                  D2_SERIE,
                                  D2_CLIENTE,
                                  D2_LOJA,
                                  D2_COMIS1) QRY1
                       GROUP BY QRY1.D2_FILIAL,
                          QRY1.F2_VEND1,
                          QRY1.D2_EMISSAO,
                          QRY1.D2_DOC,
                          QRY1.D2_SERIE,
                          QRY1.D2_CLIENTE,
                          QRY1.D2_LOJA) QRY2
         GROUP BY QRY2.D2_FILIAL,
                  QRY2.F2_VEND1,
                  QRY2.D2_EMISSAO,
                  QRY2.D2_DOC,
                  QRY2.D2_SERIE,
                  QRY2.D2_CLIENTE,
                  QRY2.D2_LOJA,
                  QRY2.PERC_MED) CORRET
 WHERE EFET.E3_FILIAL = CORRET.D2_FILIAL
   AND EFET.E3_VEND = CORRET.F2_VEND1
   AND EFET.E3_NUM = CORRET.D2_DOC
   AND EFET.E3_SERIE = CORRET.D2_SERIE
   AND EFET.E3_CODCLI = CORRET.D2_CLIENTE
   AND EFET.E3_LOJA = CORRET.D2_LOJA
   AND ABS(EFET.COMIS_PG - CORRET.VALOR_A_PAGAR) > 0.03
   
UNION ALL

SELECT EFET.E3_FILIAL,
       EFET.E3_VEND,
       EFET.E3_NUM,
       EFET.E3_SERIE,
       CORRET.D2_EMISSAO,
       EFET.E3_CODCLI,
       EFET.E3_LOJA,
       EFET.BASE_E3,
       EFET.COMIS_PG,
       CORRET.VL_BAIXA,
       CORRET.RAZAO_CORRETA,
       CORRET.PERC_MED,
       CORRET.VALOR_A_PAGAR,
       EFET.COMIS_PG - CORRET.VALOR_A_PAGAR DIF_COMIS
  FROM (SELECT E3_FILIAL,
               E3_VEND,
               E3_NUM,
               E3_SERIE,
               E3_CODCLI,
               E3_LOJA,
               SUM(E3_BASE) BASE_E3,
               SUM(E3_COMIS) COMIS_PG
          FROM %Table:SE3%, %Table:SE5%
         WHERE SE3010.D_E_L_E_T_ = ' '
           AND SE5010.D_E_L_E_T_ = ' '
           AND E5_FILIAL = E3_FILIAL
           AND E5_PREFIXO = E3_PREFIXO
           AND E3_NUM = E5_NUMERO
           AND E5_PARCELA = E3_PARCELA
           AND E3_CODCLI = E5_CLIFOR
           AND E3_LOJA = E5_LOJA
           AND E3_TIPO = E5_TIPO
           AND E3_SEQ = E5_SEQ
           AND E5_TIPODOC = 'VL'
           AND E5_MOTBX = 'NOR'
           AND E3_VEND BETWEEN %exp:MV_PAR03% AND %exp:MV_PAR04%
         GROUP BY E3_FILIAL,
                  E3_VEND,
                  E3_NUM,
                  E3_SERIE,
                  E3_CODCLI,
                  E3_LOJA,
                  E3_PEDIDO) EFET,
       (SELECT QRY2.D2_FILIAL,
               QRY2.F2_VEND2,
               QRY2.D2_EMISSAO,
               QRY2.D2_DOC,
               QRY2.D2_SERIE,
               QRY2.D2_CLIENTE,
               QRY2.D2_LOJA,
               QRY2.PERC_MED,
               SUM(QRY2.BASE),
               SUM(QRY2.RETIDO),
               SUM(QRY2.VALOR_BAIXA) VL_BAIXA,
               Round(SUM(QRY2.VALOR_BAIXA) * (SUM(QRY2.COMISSAO) / SUM(QRY2.BASE)),
                     2) COMIS_BAIXA,
               Round(SUM(QRY2.BASE) / (SUM(QRY2.BASE) + SUM(QRY2.RETIDO)), 6) RAZAO_CORRETA,
               Round(SUM(QRY2.VALOR_BAIXA) * (SUM(QRY2.COMISSAO) / SUM(QRY2.BASE)) * (Round(SUM(QRY2.BASE) / (SUM(QRY2.BASE) + SUM(QRY2.RETIDO)),
                            6)),
                     2) VALOR_A_PAGAR
          FROM (SELECT QRY1.D2_FILIAL,
                       QRY1.F2_VEND2,
                       QRY1.D2_EMISSAO,
                       QRY1.D2_DOC,
                       QRY1.D2_SERIE,
                       QRY1.D2_CLIENTE,
                       QRY1.D2_LOJA,
                       SUM(TOTAL_D2) BASE,
                       Round((SUM(COMIS) / SUM(TOTAL_D2)) * 100, 2) PERC_MED,
                       SUM(COMIS) COMISSAO,
                       SUM(ICMSRET_D2) RETIDO,
		               NVL((SELECT SUM(E5_VALOR) - SUM(E5_VLJUROS) - SUM(E5_VLMULTA)
                          FROM %Table:SE5%
                         WHERE SE5010.D_E_L_E_T_ = ' '
                           AND D2_FILIAL = E5_FILIAL
                           AND D2_DOC = E5_NUMERO
                           AND D2_SERIE = E5_PREFIXO
                           AND D2_CLIENTE = E5_CLIFOR
                           AND D2_LOJA = E5_LOJA
                           AND E5_TIPO = 'NF'
                           AND E5_TIPODOC = 'VL'
                           AND E5_MOTBX = 'NOR'),0)- NVL((SELECT SUM(E5_VALOR) - SUM(E5_VLJUROS) - SUM(E5_VLMULTA)
                          FROM %Table:SE5%
                         WHERE SE5010.D_E_L_E_T_ = ' '
                           AND D2_FILIAL = E5_FILIAL
                           AND D2_DOC = E5_NUMERO
                           AND D2_SERIE = E5_PREFIXO
                           AND D2_CLIENTE = E5_CLIFOR
                           AND D2_LOJA = E5_LOJA
                           AND E5_TIPO = 'NF'
                           AND E5_TIPODOC = 'ES'
                           AND E5_MOTBX = 'NOR'),0) VALOR_BAIXA
                  FROM (SELECT D2_FILIAL,
                               F2_VEND2,
                               D2_EMISSAO,
                               D2_DOC,
                               D2_SERIE,
                               D2_CLIENTE,
                               D2_LOJA,
                               SUM(D2_TOTAL) TOTAL_D2,
                               SUM(D2_ICMSRET) ICMSRET_D2,
                               D2_COMIS2,
                               Round(SUM(D2_TOTAL) * D2_COMIS2 / 100, 2) COMIS
                          FROM %Table:SD2%, %Table:SF2%
                         WHERE SD2010.D_E_L_E_T_ = ' '
                           AND SF2010.D_E_L_E_T_ = ' '
                           AND F2_FILIAL = D2_FILIAL
                           AND F2_DOC = D2_DOC
                           AND F2_SERIE = D2_SERIE
                           AND F2_EMISSAO = D2_EMISSAO
                           AND F2_CLIENTE = D2_CLIENTE
                           AND F2_LOJA = D2_LOJA
                           AND D2_COMIS2 > 0
                           AND D2_TOTAL > 0
                           AND D2_EMISSAO BETWEEN %exp:DToS(MV_PAR01)% AND %exp:DToS(MV_PAR02)%
                         GROUP BY D2_FILIAL,
                                  F2_VEND2,
                                  D2_EMISSAO,
                                  D2_DOC,
                                  D2_SERIE,
                                  D2_CLIENTE,
                                  D2_LOJA,
                                  D2_COMIS2) QRY1
                         GROUP BY QRY1.D2_FILIAL,
                          QRY1.F2_VEND2,
                          QRY1.D2_EMISSAO,
                          QRY1.D2_DOC,
                          QRY1.D2_SERIE,
                          QRY1.D2_CLIENTE,
                          QRY1.D2_LOJA) QRY2
         GROUP BY QRY2.D2_FILIAL,
                  QRY2.F2_VEND2,
                  QRY2.D2_EMISSAO,
                  QRY2.D2_DOC,
                  QRY2.D2_SERIE,
                  QRY2.D2_CLIENTE,
                  QRY2.D2_LOJA,
                  QRY2.PERC_MED) CORRET
 WHERE EFET.E3_FILIAL = CORRET.D2_FILIAL
   AND EFET.E3_VEND   = CORRET.F2_VEND2
   AND EFET.E3_NUM    = CORRET.D2_DOC
   AND EFET.E3_SERIE  = CORRET.D2_SERIE
   AND EFET.E3_CODCLI = CORRET.D2_CLIENTE
   AND EFET.E3_LOJA   = CORRET.D2_LOJA
   AND ABS(EFET.COMIS_PG - CORRET.VALOR_A_PAGAR) > 0.03 //Alteração - 17/12/13 - Talita - Alterado a query para que traga os números absolutos e incluido o parametro para que separe o relatorio o tipo de pagamento maior ou menor conforme o chamado: 5000
ORDER BY EFET.E3_VEND, EFET.E3_FILIAL, CORRET.D2_EMISSAO, EFET.E3_NUM

EndSql

oSection1:EndQuery()
_cVend 	  := (cAliasQRY)->E3_VEND
_NomeVend := _cVend + '-' + U_getNomVend(_cVend) 
//Inicio da alteração	
If MV_PAR05 == 1 .And. (cAliasQRY)->DIF_COMIS > 0	//Alteração - 17/12/13 - Talita - Alterado a query para que traga os números absolutos e incluido o parametro para que separe o relatorio o tipo de pagamento maior ou menor conforme o chamado: 5000
	oReport:Section(1):Init()
	oReport:Section(1):PrintLine() 
	oReport:Section(1):Section(1):Init()  
	nCont++  
EndIf      

If MV_PAR05 == 2 .And. (cAliasQRY)->DIF_COMIS < 0	
	oReport:Section(1):Init()
	oReport:Section(1):PrintLine() 
	oReport:Section(1):Section(1):Init()
	nCont++    
EndIf  

If MV_PAR05 == 1 .And. (cAliasQRY)->DIF_COMIS < 0  //Alteração - 07/01/13 - Talita - Corrigido o erro que estava ocorrendo com relação as informações do parametro maior conforme chamado 5122.
	nCont++
EndIf

While (cAliasQRY)->(!Eof()) 

	If MV_PAR05 == 1 .And. (cAliasQRY)->DIF_COMIS > 0
		If nCont > 0  
			oReport:Section(1):Init()
			oReport:Section(1):PrintLine() 
			oReport:Section(1):Section(1):Init() 
			nCont:= 0
       	EndIf

		If _cVend <> (cAliasQRY)->E3_VEND   
    	   	oReport:Section(1):SetPageBreak(.T.)
		   	oReport:Section(1):Finish()
		   	oReport:Section(1):Section(1):Finish()
		   	_cVend := (cAliasQRY)->E3_VEND
		   	_NomeVend := _cVend + '-' + U_getNomVend(_cVend)
		
			oReport:Section(1):Init()
			oReport:Section(1):PrintLine() 
		   	oReport:Section(1):Section(1):Init()                                         
		EndIf
		oReport:Section(1):Section(1):PrintLine()  
	EndIf
 
	If MV_PAR05 == 2 .And. (cAliasQRY)->DIF_COMIS < 0 
 		If nCont > 0  
    		oReport:Section(1):Init()
			oReport:Section(1):PrintLine() 
			oReport:Section(1):Section(1):Init() 
			nCont:= 0
		EndIf
		//Fim da alteração    
		If _cVend <> (cAliasQRY)->E3_VEND  
    	   	oReport:Section(1):SetPageBreak(.T.)
	    	oReport:Section(1):Finish()
	    	oReport:Section(1):Section(1):Finish()
	       	_cVend := (cAliasQRY)->E3_VEND
		   	_NomeVend := _cVend + '-' + U_getNomVend(_cVend)
			
			oReport:Section(1):Init()
			oReport:Section(1):PrintLine() 
	    	oReport:Section(1):Section(1):Init()                                         
		EndIf
		oReport:Section(1):Section(1):PrintLine()  
	EndIf
   		
	DBSkip()
EndDo

oReport:Section(1):SetPageBreak(.T.)
oReport:Section(1):Finish()
oReport:Section(1):Section(1):Finish()

Return

/*
===============================================================================================================================
Programa--------: getNomVend
Autor-----------: Talita Teixeira
Data da Criacao-: 29/07/2013
Descrição-------: Busca nome do vendedor
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function getNomVend(_cVend)

Local aAreaSA3 := SA3->(getArea())
Local cRet := " "

SA3->(DBSelectArea("SA3"))
SA3->(DBSetOrder(1))
SA3->(DBSeek(xFilial("SA3")+ _cVend))
cRet := SA3->A3_NOME

//Restaura integridade da SM0
SA3->(DBSetOrder(aAreaSA3[2]))
SA3->(DBGoTo(aAreaSA3[3]))

Return cRet
