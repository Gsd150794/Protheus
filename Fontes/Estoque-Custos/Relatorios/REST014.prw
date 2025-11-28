/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |08/10/2024| Chamado 48465. Retirada manipulação do SX1
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include 'TOPCONN.CH'

/*
===============================================================================================================================
Programa----------: REST014
Autor-------------: Alex Wallauer
Data da Criacao---: 23/05/2019
Descrição---------: Relatório para validar estoque X aplicação direta - CHAMADO 28530
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function REST014()//U_REST014
Local oReport	:= nil
Private _cPerg	:= "REST014"
Private aOrd	:= {} 

While .T.

   If !Pergunte(_cPerg,.T.)
      Return .F.
   EndIf

   If MV_PAR01 > MV_PAR02
      MSGSTOP("Periodo de datas invalido.")
      Loop
   EndIf
   
   If MV_PAR04 > MV_PAR05
      MSGSTOP("Periodo de produtos invalido.")
      Loop
   EndIf
   
   Exit
   
EndDo

oReport := RptDef(_cPerg)
oReport:PrintDialog()  

//========================================================================
// Grava log de Relatório de Relatório Clientes com Contrato.
//======================================================================== 
U_ITLOGACS('REST014')

Return

/*
===============================================================================================================================
Programa----------: RptDef
Autor-------------: Alex Wallauer
Data da Criacao---: 19/03/2019
Descrição---------: Função que faz a montagem do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RptDef(cNome)
Local oReport	:= Nil
Local oSection1	:= Nil
	
oReport:= TReport():New("REST014","Relatório de Estoque X Aplicação Direta","REST014", {|oReport| ReportPrint(oReport)},"Estoque X Aplicação Direta")

oReport:SetLandscape()

oSection1 := TRSection():New(oReport, "Estoque X Aplicacao Direta", {"TRB"},aOrd , .F., .T.)

	TRCell():New(oSection1,"PRODUTO"	,"TRB","Produto"  		    ,"@!",100)
	TRCell():New(oSection1,"DESCR"	    ,"TRB","Descrição " 	    ,"@!",100)
	TRCell():New(oSection1,"ESTOQ_DI"	,"TRB","Estoque Ini"		,"@E 99999,999,999.9999",25)
	TRCell():New(oSection1,"ESTOQ_DF"	,"TRB","Estoque Fim"		,"@E 99999,999,999.9999",25)
	TRCell():New(oSection1,"QTDE_APL"   ,"TRB","Qtde Aplic."   		,"@E 99999,999,999.9999",25)
	TRCell():New(oSection1,"QTDE_SAP"	,"TRB","Qtde S/ Aplic"		,"@E 99999,999,999.9999",25)

oSection2 := TRSection():New(oReport, "Aplicacao Direta Detalhada", {"TRB"},aOrd , .F., .T.)

	TRCell():New(oSection2,"PRODUTO"	,"TRB","Produto"  		    ,"@!",050)
	TRCell():New(oSection2,"DESCR"	    ,"TRB","Descrição " 	    ,"@!",100)
	TRCell():New(oSection2,"QTDE_APL"   ,"TRB","Qtde Aplic."   		,"@E 99999,999,999.9999",25)
	TRCell():New(oSection2,"PEDIDO"	    ,"TRB","Pedido"		 	    ,"@!",050)
	TRCell():New(oSection2,"NUMSC"	    ,"TRB","Num. SC"	 	    ,"@!",050)
	TRCell():New(oSection2,"OBS"	    ,"TRB","Observacao"		 	,"@!",150)

Return(oReport)

/*
===============================================================================================================================
Programa----------: RptDef
Autor-------------: Alex Wallauer
Data da Criacao---: 19/03/2019
Descrição---------: Função que imprime o relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ReportPrint(oReport)

Local oSection1 := oReport:Section(1)
Local oSection2 := oReport:Section(2)
Local cQry		:= ""

oSection1:Init()
oReport:SetMeter(0)

Begin Sequence
	
    oReport:IncMeter()

//******************  
	cQry := "SELECT M.FIL FILIAL, M.COD D3_COD, M.QTDE QTDE_A_D, (CP.QTDE-M.QTDE) QTDE_COMPRA "
	cQry += "  FROM(  SELECT D1_FILIAL FIL, D1_COD COD, SUM(D1_QUANT) QTDE  "///***ABRE
	cQry += "         FROM " + RetSqlName("SD1") + " SD1 "
	cQry += "         JOIN " + RetSqlName("SF4") + " SF4 ON D1_FILIAL = F4_FILIAL AND D1_TES = F4_CODIGO "
	cQry += "         WHERE SD1.D_E_L_E_T_ = ' ' AND SF4.D_E_L_E_T_ = ' ' "
	cQry += "               AND D1_FILIAL = '"+xFilial("SD1")+"' "
	cQry += "               AND D1_DTDIGIT BETWEEN '" + DToS(MV_PAR01) + "' AND '" + DToS(MV_PAR02) + "' " 
  	If !Empty(MV_PAR04)
	   cQry += "            AND D1_COD >= '" + AllTrim(MV_PAR04) + "' "
    EndIf
  	If !Empty(MV_PAR05)
	   cQry += "            AND D1_COD <= '" + AllTrim(MV_PAR05) + "' "
    EndIf
	cQry += "               AND D1_COD IN (   " ///** ABRE
	cQry += "               	SELECT DISTINCT D3_COD "
	cQry += "                          FROM " + RetSqlName("SD3") + " D3 "
	cQry += "                          JOIN " + RetSqlName("SC7") + " C7 ON D3_FILIAL = C7_FILIAL AND D3_NUMSEQ = C7_I_SEQD3 "
	cQry += "                          WHERE D3.D_E_L_E_T_ = ' ' AND C7.D_E_L_E_T_ = ' ' "
	cQry += "                          AND D3_FILIAL = '"+xFilial("SD3")+"' "
	cQry += "                          AND D3_EMISSAO BETWEEN '" + DToS(MV_PAR01) + "' AND '" + DToS(MV_PAR02) + "' " 
  	If !Empty(MV_PAR04)
	   cQry += "                       AND D3_COD >= '" + AllTrim(MV_PAR04) + "' "
    EndIf
  	If !Empty(MV_PAR05)
	   cQry += "                       AND D3_COD <= '" + AllTrim(MV_PAR05) + "' "
    EndIf
	If !Empty(MV_PAR03)
		cQry += "                      AND D3.D3_GRUPO IN " + FormatIn( AllTrim(MV_PAR03) , ";" )
 	EndIf
	cQry += "                          AND C7_I_USOD = 'S' "
	cQry += "                          AND D3_ESTORNO <> 'S' ) "///**FECHA
	cQry += "         GROUP BY D1_FILIAL, D1_COD "
	cQry += "         ORDER BY D1_FILIAL, D1_COD) CP "///***FECHA
     
	cQry += "JOIN(  SELECT D3_FILIAL FIL, D3_COD COD, SUM(D3_QUANT) QTDE  "///****ABRE  
 	cQry += "               FROM " + RetSqlName("SD3") + " D3 "
	cQry += "               JOIN " + RetSqlName("SC7") + " C7 ON D3_FILIAL = C7_FILIAL AND D3_NUMSEQ = C7_I_SEQD3 "
	cQry += "               WHERE D3.D_E_L_E_T_ = ' ' AND C7.D_E_L_E_T_ = ' ' "
	cQry += "               AND D3_ESTORNO <> 'S' AND C7_I_USOD = 'S' AND D3.D3_FILIAL = '"+xFilial("SD3")+"' "
  	If !Empty(MV_PAR04)
	   cQry += "            AND D3_COD >= '" + AllTrim(MV_PAR04) + "' "
    EndIf
  	If !Empty(MV_PAR05)
	   cQry += "            AND D3_COD <= '" + AllTrim(MV_PAR05) + "' "
    EndIf
	If !Empty(MV_PAR03)
		cQry += "           AND D3.D3_GRUPO IN " + FormatIn( AllTrim(MV_PAR03) , ";" )
 	EndIf
	cQry += "               AND D3.D3_EMISSAO BETWEEN '" + DToS(MV_PAR01) + "' AND '" + DToS(MV_PAR02) + "' "  
  	cQry += "               GROUP BY D3.D3_FILIAL , D3.D3_COD "
  	cQry += "               ORDER BY D3.D3_FILIAL , D3.D3_COD ) M "///****FECHA
  	cQry += " ON M.FIL = CP.FIL AND M.COD = CP.COD "
  	cQry += " ORDER BY M.COD "
	
	If Select("TRB") <> 0
	   TRB->(DBCloseArea())
	EndIf
	TCQUERY cQry  NEW ALIAS "TRB"  

	_nTot:=0
    COUNT TO _nTot
	oReport:SetMeter(_nTot)
	
	TRB->(DBGoTop())
	While !TRB->(Eof())

	   oReport:IncMeter()

	    SB1->( DBSeek( xFilial() + TRB->D3_COD) )
		oSection1:Cell("PRODUTO"):SetValue(TRB->D3_COD)
		oSection1:Cell("DESCR")  :SetValue(SB1->B1_DESC)		

        _aSaldos := CalcEst( TRB->D3_COD , "00" , MV_PAR01  ) 
		oSection1:Cell("ESTOQ_DI"):SetValue(_aSaldos[1])

        _aSaldos := CalcEst( TRB->D3_COD , "00" , MV_PAR02  ) 
		oSection1:Cell("ESTOQ_DF"):SetValue(_aSaldos[1])
		oSection1:Cell("QTDE_APL"):SetValue(TRB->QTDE_A_D)
		oSection1:Cell("QTDE_SAP"):SetValue(TRB->QTDE_COMPRA)

		oSection1:PrintLine()

		TRB->(DBSkip())
	EndDo

	oReport:SetMeter(0)
    oReport:IncMeter()
	cQry := " SELECT D3_FILIAL FIL, D3_COD, D3_QUANT QTDE ,C7_NUM ,C7_NUMSC , D3_I_OBS  "
 	cQry += "        FROM " + RetSqlName("SD3") + " D3 "
	cQry += "        JOIN " + RetSqlName("SC7") + " C7 ON D3_FILIAL = C7_FILIAL AND D3_NUMSEQ = C7_I_SEQD3 "
	cQry += "             WHERE D3.D_E_L_E_T_ = ' ' AND C7.D_E_L_E_T_ = ' ' "
	cQry += "               AND D3_ESTORNO <> 'S' AND C7_I_USOD = 'S' AND D3.D3_FILIAL = '"+xFilial("SD3")+"' "
  	If !Empty(MV_PAR04)
	   cQry += "            AND D3_COD >= '" + AllTrim(MV_PAR04) + "' "
    EndIf
  	If !Empty(MV_PAR05)
	   cQry += "            AND D3_COD <= '" + AllTrim(MV_PAR05) + "' "
    EndIf
	If !Empty(MV_PAR03)
	   cQry += "            AND D3.D3_GRUPO IN " + FormatIn( AllTrim(MV_PAR03) , ";" )
 	EndIf
	cQry += "               AND D3.D3_EMISSAO BETWEEN '" + DToS(MV_PAR01) + "' AND '" + DToS(MV_PAR02) + "' "  
  	cQry += "          ORDER BY D3.D3_FILIAL , D3.D3_COD "
	If Select("TRB") <> 0
	   TRB->(DBCloseArea())
	EndIf
	TCQUERY cQry  NEW ALIAS "TRB"  

	_nTot:=0
    COUNT TO _nTot
	oReport:SetMeter(_nTot)

    oSection2:Init()
	TRB->(DBGoTop())
	While !TRB->(Eof())
	    oReport:IncMeter()

	    SB1->( DBSeek( xFilial() + TRB->D3_COD) )
		oSection2:Cell("PRODUTO") :SetValue(TRB->D3_COD)
		oSection2:Cell("DESCR")   :SetValue(SB1->B1_DESC)		
		oSection2:Cell("QTDE_APL"):SetValue(TRB->QTDE)
		oSection2:Cell("PEDIDO")  :SetValue(TRB->C7_NUM)
		oSection2:Cell("NUMSC")   :SetValue(TRB->C7_NUMSC)
		oSection2:Cell("OBS")     :SetValue(TRB->D3_I_OBS)
		oSection2:PrintLine()
		
		TRB->(DBSkip())
	EndDo

End Sequence

oSection1:Finish()
oSection1:Enable()

Return .T.
