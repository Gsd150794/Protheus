/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas C.  	  |13/10/2014| Chamado 7708. Inclusão Status "S" para OPs Suspensas, Coluna Motivo (C2_I_MOTIV), Ajuste diferença
			  |			 | Qtd. Realizada - Programada
Julio Paz     |02/05/2017| Chamado 19813. Inclusão da função de Log ITLOGACS().
Lucas Borges  |11/09/2024| Chamado 48465. Removendo warning de compilação.
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "TOPCONN.CH"

/*
===============================================================================================================================
Programa----------: REST005
Autor-------------: Lucas Crevilari
Data da Criacao---: 27/08/2014
Descrição---------: Relatorio Producao Programada x Realizada
Parametros--------: 
Retorno-----------: 
===============================================================================================================================
*/
User Function REST005()

Private oReport  
Private cPerg 	:= "REST005"
Private aOrdem 	:= {}
Private _nVal01 := 0
Private _nVal02 := 0
Private _nVal03 := 0
Private _nVal04 := 0   
Private nTotQtd := 0
Private nTotPer := 0     

aAdd( aOrdem, "Data + OP" )
aAdd( aOrdem, "Produto + Data" )        

oReport := ReportDef()
oReport:PrintDialog()   

//========================================================================
// Grava log do Relatorio Producao Programada x Realizada.
//======================================================================== 
U_ITLOGACS('REST005')

Return

/*
===============================================================================================================================
Programa----------: ReportDef
Autor-------------: Lucas Crevilari
Data da Criacao---: 27/08/2014
Descrição---------: Relatorio Producao Programada x Realizada
Parametros--------: 
Retorno-----------: 
===============================================================================================================================
*/
Static Function ReportDef()
Local oSection1 
Local oSection2
Private oBreak  
Private oBreak2

oReport:= TReport():New("REST005","Producao Programada X Realizada","REST005",{|oReport| ReportPrint(oReport) },"Producao Programada X Realizada")
oReport:SetLandscape()
oReport:SetTotalInLine(.F.)

Pergunte(oReport:uParam,.F.) 

//===================================
//Definição das seções do relatorio |
//===================================

oSection1 := TRSection():New(oReport, "Produtos",{"SC2","SB1"},aOrdem) 
oSection2 := TRSection():New(oSection1,"Total",{"SC2"}) 

//======================================
//Definição das células para impressão |
//======================================
DBSelectArea("SX3")
SX3->(DBSetOrder(2))

DBSeek("C2_NUM")                                
TRCell():New(oSection1,"C2_NUM","SC2",X3TITULO(),,TamSX3("C2_NUM")[1]+1)
DBSeek("C2_PRODUTO")
TRCell():New(oSection1,"C2_PRODUTO","SC2",X3TITULO(),,TamSX3("C2_PRODUTO")[1]+1)
DBSeek("B1_I_DESCD")
TRCell():New(oSection1,"B1_I_DESCD","SB1",X3TITULO(),,50)
DBSeek("C2_I_MOTIV")
TRCell():New(oSection1,"C2_I_MOTIV","SC2",X3TITULO(),,TamSX3("C2_I_MOTIV")[1]+1)
DBSeek("C2_EMISSAO")
TRCell():New(oSection1,"C2_EMISSAO","SC2",X3TITULO(),,TamSX3("C2_EMISSAO")[1]+1)
DBSeek("C2_QUANT")
TRCell():New(oSection1,"C2_QUANT","SC2","Programada",PesqPict("SC2","C2_QUANT"),TamSX3("C2_QUANT")[1]+1)
DBSeek("C2_QUJE")
TRCell():New(oSection1,"C2_QUJE","SC2","Realizada",PesqPict("SC2","C2_QUJE"),TamSX3("C2_QUJE")[1]+1) 
TRCell():New(oSection1,"DIFQTD","SC2","Dif. Qtd.",PesqPict("SC2","C2_QUJE"),11,,,"RIGHT",,"RIGHT")    
TRCell():New(oSection1,"DIFPER","SC2","Dif. Perc.","@R 999,999.9999%",11,,,"RIGHT",,"RIGHT")             
TRCell():New(oSection1,"STATUS","SC2","Status",,7,,,"RIGHT",,"RIGHT")

TRCell():New(oSection2,"TOTQTD","SC2","Total Dif. Qtd.","@E 999,999,999.99",11,,,"RIGHT",,"RIGHT")    
TRCell():New(oSection2,"TOTPER","SC2","Total Dif. Perc.","@R 999,999.9999%",11,,,"RIGHT",,"RIGHT")             

oSection1:SetTotalInLine(.F.)
oSection2:SetTotalInLine(.F.)

Return oReport

/*
===============================================================================================================================
Programa----------: ReportPrint
Autor-------------: Lucas Crevilari
Data da Criacao---: 27/08/2014
Descrição---------: Relatorio Producao Programada x Realizada
Parametros--------: 
Retorno-----------: 
===============================================================================================================================
*/
Static Function ReportPrint(oReport)
                                                  
Local _cNumAux	:= ""
Local _cDtAux   := ""
Local oSection1 := oReport:Section(1) 
Local oSection2 := oReport:Section(1):Section(1)  
nOrdem    		:= oReport:Section(1):GetOrder()  

//============================================                           
//| Definiçao das quebras e soma das colunas |
//============================================

If nOrdem == 1 //Data+OP
	oBreak := TRBreak():New(oSection1,oSection1:Cell("C2_EMISSAO"),,.F.)
	TRFunction():New(oSection1:Cell("DIFQTD"),"DIFQTD","ONPRINT",oBreak,,,{|| _nVal03 - _nVal04},.F.,.F.,.F.) //Diferenca em valor
	TRFunction():New(oSection1:Cell("DIFPER"),"DIFPER","ONPRINT",oBreak,,,{|| Round(((_nVal04 / _nVal03) - 1) *100 ,4)},.F.,.F.,.F.) //Diferenca em percentual
ElseIf nOrdem == 2 //Produto+Data
	oBreak2 := TRBreak():New(oSection1,oSection1:Cell("C2_PRODUTO"),,.F.)
	TRFunction():New(oSection1:Cell("DIFQTD"),"DIFQTD","ONPRINT",oBreak2,,,{|| _nVal01 - _nVal02},.F.,.F.,.F.) //Diferenca em valor
	TRFunction():New(oSection1:Cell("DIFPER"),"DIFPER","ONPRINT",oBreak2,,,{|| Round(((_nVal02 / _nVal01) - 1) *100 ,4)},.F.,.F.,.F.) //Diferenca em percentual
EndIf

MakeSqlExpr(cPerg)

cQuery	:= " SELECT C2_NUM,C2_SEQUEN,C2_PRODUTO,B1_I_DESCD,C2_EMISSAO,C2_I_MOTIV,C2_QUANT,C2_QUJE,C2_DATRF,C2_STATUS FROM "+ RetSqlName("SC2")+ " SC2 "
cQuery	+= " INNER JOIN "+ RetSqlName("SB1")+ " B1 ON B1_COD = C2_PRODUTO "
cQuery	+= " WHERE C2_NUM BETWEEN '"+MV_PAR01+ "' AND '" +MV_PAR02 +"' "
cQuery  += " AND   C2_EMISSAO BETWEEN '"+DToS(MV_PAR03)+ "' AND '"+DToS(MV_PAR04)+"' "
cQuery 	+= " AND   C2_PRODUTO BETWEEN '"+MV_PAR05+ "' AND '"+MV_PAR06+"' "
If MV_PAR07 == 1 //OPs Encerradas
	cQuery  += " AND   C2_DATRF <> ' ' "
ElseIf MV_PAR07 == 2 //OPs Abertas
	cQuery  += " AND   C2_DATRF = ' ' "
EndIf
cQuery	+= " AND   C2_FILIAL = '"+xFilial("SC2")+"' "
cQuery	+= " AND   SC2.D_E_L_E_T_ = ' ' "
If nOrdem == 1 //Data+OP
	cQuery  += " ORDER BY C2_EMISSAO,C2_NUM,C2_SEQUEN "
ElseIf nOrdem == 2 //Produto+Data
	cQuery  += " ORDER BY C2_PRODUTO,C2_EMISSAO "
EndIf
TcQuery cQuery New Alias "cQuery"

oReport:SetMeter(("cQuery")->(RecCount()))
DBSelectArea("cQuery")
oSection1:Init()       

While cQuery->(!Eof())
	
	oSection1:Cell("C2_NUM"):SetValue(cQuery->C2_NUM+cQuery->C2_SEQUEN)
	oSection1:Cell("C2_PRODUTO"):SetValue(cQuery->C2_PRODUTO)
	oSection1:Cell("B1_I_DESCD"):SetValue(cQuery->B1_I_DESCD)
	oSection1:Cell("C2_EMISSAO"):SetValue(SToD(cQuery->C2_EMISSAO))
	oSection1:Cell("C2_I_MOTIV"):SetValue(cQuery->C2_I_MOTIV)
	oSection1:Cell("C2_QUANT"):SetValue(cQuery->C2_QUANT)
	oSection1:Cell("C2_QUJE"):SetValue(cQuery->C2_QUJE)
	If Empty(cQuery->C2_DATRF) .And. cQuery->C2_STATUS == "U"
		oSection1:Cell("STATUS"):SetValue("S") //Suspensa
	ElseIf Empty(cQuery->C2_DATRF)
		oSection1:Cell("STATUS"):SetValue("A") //Aberta
	Else
		oSection1:Cell("STATUS"):SetValue("E") //Encerrada
	EndIf		                          
	oSection1:Cell("DIFQTD"):SetValue(Round((cQuery->C2_QUJE - cQuery->C2_QUANT),4))
	oSection1:Cell("DIFPER"):SetValue(Round(((cQuery->C2_QUJE / cQuery->C2_QUANT) - 1) *100,4))

	oSection1:PrintLine()
	oReport:IncMeter()
 	
 	_nVal01 += cQuery->C2_QUANT
 	_nVal02 += cQuery->C2_QUJE
 	_nVal03 += cQuery->C2_QUANT
 	_nVal04 += cQuery->C2_QUJE            
	 	 	            		 	 	
 	If !Empty(_cNumAux) 	
 		If _cNumAux <> cQuery->C2_PRODUTO
 			_cNumAux	:= cQuery->C2_PRODUTO
 			_nVal01		:= cQuery->C2_QUANT
		 	_nVal02		:= cQuery->C2_QUJE

 		EndIf
 	Else
 		_cNumAux := cQuery->C2_PRODUTO
 	EndIf
 	
 	If !Empty(_cDtAux)	 		
 		If _cDtAux <> cQuery->C2_EMISSAO
 			_cDtAux	:= cQuery->C2_EMISSAO
 			_nVal03	:= cQuery->C2_QUANT
		 	_nVal04	:= cQuery->C2_QUJE
 		EndIf	
 	Else
 		_cDtAux := cQuery->C2_EMISSAO
 	EndIf                            
	
	nTotQtd += oSection1:Cell("DIFQTD"):GetValue()
	nTotPer += oSection1:Cell("DIFPER"):GetValue()

	cQuery->(DBSkip())  
EndDo

oSection1:Finish()
cQuery->(DBCloseArea())

oSection2:Init() 
oSection2:Cell("TOTQTD"):SetValue(nTotQtd)
oSection2:Cell("TOTPER"):SetValue(nTotPer)
oSection2:PrintLine()         
oSection2:Finish()

Return
