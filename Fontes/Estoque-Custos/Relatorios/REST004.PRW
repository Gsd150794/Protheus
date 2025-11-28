/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz     |02/05/2017| Chamado 19813. Inclusão da função de Log ITLOGACS().
Alex Walaluer |19/12/2018| Chamado 27369. Inclusão para gerar somente com o centro de custo informado no novo parâmetro.
Lucas Borges  |11/09/2024| Chamado 48465. Removendo warning de compilação.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: REST004
Autor-------------: Lucas Crevilari
Data da Criacao---: 21/07/2014
Descrição---------: Relatorio de Relacao Das Ordens de Producao.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function REST004()

Local   oReport
Private cQryOP
Private nQuant  := 0
Private nQtdProd := 0
Private nCusReq	:=0  
Private nCMOP 	:= 0  
Private lCalc 	:= .T.
Private cPerg 	:= "REST004"
Private _aItalac_F3:={}

oReport:= ReportDef()
oReport:PrintDialog()

//========================================================================
// Grava log Relatorio de Relacao Das Ordens de Producao.
//======================================================================== 
U_ITLOGACS('REST004')

Return

/*
===============================================================================================================================
Programa----------: REST004
Autor-------------: Lucas Crevilari
Data da Criacao---: 21/07/2014
Descrição---------: Relatorio de Relacao Das Ordens de Producao.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ReportDef()
Local oReport
Local oSection1

oReport:= TReport():New("REST004","Relacao por Ordem de Producao","REST004", {|oReport| ReportPrint(oReport)},"O objetivo deste relatório e exibir detalhadamente todas as movimenta-"+"ções feitas para cada Ordem de Produção , a mostrar inclusive os custos.") 
oReport:SetLandscape() //Define a orientacao de pagina do relatorio como paisagem.

Pergunte(oReport:uParam,.F.)                                                
//===========================================================================
//| Secao 1 (oSection1) 		                                             |
//===========================================================================

oSection1 := TRSection():New(oReport,"Ordens de Produção",{"SD3","SB1"},/*Ordem*/)
oSection1:SetHeaderPage()
oSection1:SetTotalInLine(.F.)

TRCell():New(oSection1,'D3_CC'    	,'SD3',/*Titulo*/,/*Picture*/				  ,/*Tamanho*/,/*lPixel*/,  {|| NgSeek('SI3',(cQryOP)->D3_CC,1,'SI3->I3_DESC') })
TRCell():New(oSection1,'D3_OP'	  	,'SD3',/*Titulo*/,/*Picture*/				  ,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,'C2_REVISAO' ,'SC2',/*Titulo*/,/*Picture*/				  ,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,'D3_CF'   	,'SD3',/*Titulo*/,/*Picture*/				  ,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,'D3_COD'   	,'SD3',/*Titulo*/,/*Picture*/				  ,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,'B1_DESC'  	,'SB1',/*Titulo*/,/*Picture*/				  ,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,'D3_QUANT' 	,'SD3',/*Titulo*/,/*Picture*/				  ,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,'D3_UM'    	,'SD3',"UM" ,/*Picture*/			      ,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,'Unitario'	,'SD3',"Unitario",  		"@E 999,999.99999",14/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,'Custo'   	,'SD3',"Custo",     		"@E 999,999.99999",14/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)                   
TRCell():New(oSection1,'CustProd'	,'SB1',"CustProd",			"@E 999,999.99999",14/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/) 
TRCell():New(oSection1,'Unit2'		,'SB1',"Imp+Unitario",		"@E 999,999.99999",14/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/) 
TRCell():New(oSection1,'Cust2'	 	,'SB1',"Imp+Custo",		    "@E 999,999.99999",14/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/) 
TRCell():New(oSection1,'CustPro2'	,'SB1',"Imp+CustProd",  	"@E 999,999.99999",14/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/) 
TRCell():New(oSection1,'D3_EMISSAO'	,'SD3',/*Titulo*/,/*Picture*/				  ,  /*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,'B1_CUSTD'	,'SB1',/*Titulo*/,,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,'TotalSTD'	,'SB1',/*Titulo*/,,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,'CMOP'		,'',/*Titulo*/,	"@E 999,999.99999",/*Tamanho*/,/*lPixel*/,/*{|| CalcCMOP(nCMOP) }*/)

Return(oReport)

/*
===============================================================================================================================
Programa----------: ReportPrint
Autor-------------: Lucas Crevilari
Data da Criacao---: 21/07/2014
Descrição---------: FuncStaticatica ReportPrint 
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ReportPrint(oReport)
Local oSection1 := oReport:Section(1)
Local dDataFec	:= GETMV("MV_ULMES")
Local cOrderBy  := ''
Local cCampoCus := ''
Local oBreak, oBreak2
Local oFunction
Local cOpAnt , cFiltraCC

//=================================================================================
//MV_CUSREP - Parametro utilizado para habilitar o calculo do Custo de Reposicao. |
//=================================================================================

Local lCusRep  := SuperGetMv("MV_CUSREP",.F.,.F.) .And. (FindFunction("MA330AvRep") .And. MA330AvRep())

//======================
// Titulo do Relatorio |
//======================

oReport:SetTitle("Relação Por Ordem De Produção"+" - "+AllTrim(GetMV("MV_SIMB"+LTrim(Str(MV_PAR03))))+ " / " + IIf(lCusRep .And. MV_PAR07==2,"( CUSTO REPOSIÇÃO )","( CUSTO MEDIO )") )

//============================================================
//Alerta o usuario que o custo de reposicao esta desativado. |
//============================================================

If MV_PAR07==2 .And. !lCusRep
	Help(" ",1,"A860CUSRP")
	MV_PAR07 := 1
EndIf

//========================
//Filtragem do relatorio |
//========================
oReport:SetMeter(3)
oReport:IncMeter()

MakeSqlExpr(oReport:uParam)

oSection1:BeginQuery()	
cQryOP   := GetNextAlias()
cOrderBy := "% D3_FILIAL, D3_OP, D3_CHAVE, D3_NUMSEQ, D3_COD  %"

//	MV_PAR10:=AllTrim(MV_PAR10)
If !Empty(MV_PAR10) .And. Len(AllTrim(MV_PAR10)) > (Len(SD3->D3_CC)+1)
	cFiltraCC:= "% D3_ESTORNO <> 'S' AND D3_CC IN "+FormatIn(MV_PAR10,";")+"  %"
Else
	MV_PAR10:=LEFT(MV_PAR10,Len(SD3->D3_CC))
	If !Empty(MV_PAR10)
		cFiltraCC:= "% D3_ESTORNO <> 'S' AND D3_CC = '"+MV_PAR10+"'  %"
	Else   
		cFiltraCC:= "% D3_ESTORNO <> 'S'  %"
	EndIf   
EndIf   

BeginSql Alias cQryOP


SELECT SD3.D3_FILIAL, SD3.D3_CC , SD3.D3_OP , SD3.D3_CF , SD3.D3_COD , SD3.D3_QUANT , SD3.D3_UM , SD3.D3_EMISSAO ,
		SD3.D3_CUSRP1 , SD3.D3_CUSTO1 , SD3.D3_CUSRP2  , SD3.D3_CUSTO2  , SD3.D3_CUSRP3  , SD3.D3_CUSTO3 , SD3.D3_CUSRP4  , SD3.D3_CUSTO4  , SD3.D3_CUSRP5  , SD3.D3_CUSTO5 , 
		SB1.B1_COD, SB1.B1_DESC, SB1.B1_CUSTD , SC2.C2_REVISAO

FROM %Table:SD3% SD3, %Table:SB1% SB1, %Table:SC2% SC2 

WHERE SD3.D3_FILIAL   = %xFilial:SD3%	 AND 
		SB1.B1_FILIAL   = %xFilial:SB1%	 AND
		SC2.C2_FILIAL   = SD3.D3_FILIAL	 AND
		SD3.D3_OP       = SC2.C2_NUM||SC2.C2_ITEM||SC2.C2_SEQUEN AND
		SC2.C2_PRODUTO >= %EXP:MV_PAR08%	 AND
		SC2.C2_PRODUTO <= %EXP:MV_PAR09%	 AND 
		SB1.B1_COD      = SD3.D3_COD     	 AND
		SD3.D3_OP    	 >= %EXP:MV_PAR01%	 AND 
		SD3.D3_OP      <= %EXP:MV_PAR02%	 AND 
		SD3.D3_EMISSAO >= %EXP:MV_PAR04%	 AND 
		SD3.D3_EMISSAO <= %EXP:MV_PAR05%	 AND 
		SD3.D3_OP      <> ' '            	 AND
		%Exp:cFiltraCC%					 AND
		SD3.%NotDel%						 AND
		SB1.%NotDel%						 AND
		SC2.%NotDel%

ORDER BY %Exp:cOrderBy%

EndSql 

oSection1:EndQuery()

oReport:IncMeter()

//==============================================
//Totalizando a OP conforme parametro MV_PAR01 |
//==============================================
If MV_PAR06 == 1
	oBreak    := TRBreak():New(oSection1,oSection1:Cell("D3_OP"),NIL,.F.)
	oFunction := TRFunction():New(oSection1:Cell('D3_QUANT'),NIL,"SUM",oBreak,NIL,/*Picture*/,{|| If(!IsProdMod((cQryOP)->D3_COD) .And. SubStr((cQryOP)->D3_CF,1,2)<>"PR", oSection1:Cell('D3_QUANT'):GetValue(), 0) },.F.,.F.)
	oFunction := TRFunction():New(oSection1:Cell('Custo'   ),NIL,"SUM",oBreak,NIL,/*Picture*/,{|| If(!IsProdMod((cQryOP)->D3_COD) .And. SubStr((cQryOP)->D3_CF,1,2)<>"PR", oSection1:Cell('Custo'   ):GetValue(), 0) },.F.,.F.)
EndIf
//==========================================
//Definindo a Quebra Por Ordem de Producao |
//==========================================

oBreak2   := TRBreak():New(oSection1,oSection1:Cell("D3_OP"),"Total OP",.T.)

//===================================
//Totalizando Por Ordem de Producao |
//===================================
If !(lCusRep .And. MV_PAR07==2)
	oFunction := TRFunction():New(oSection1:Cell('B1_CUSTD'),NIL,"MAX",oBreak2,"Custo Unit STD -----",/*Picture*/,/*uFormula*/,.F.,.F.)
	oFunction := TRFunction():New(oSection1:Cell('TotalSTD'),NIL,"SUM",oBreak2,"Custo Total STD ----",/*Picture*/,/*uFormula*/,.F.,.F.)
EndIf	
oFunction := TRFunction():New(oSection1:Cell('D3_QUANT'),NIL,"SUM",oBreak2,"Qtd. Mao de Obra ---",/*Picture*/,{|| If(IsProdMod((cQryOP)->D3_COD), oSection1:Cell('D3_QUANT'):GetValue() , 0 ) },.F.,.F.) 
oFunction := TRFunction():New(oSection1:Cell('Custo'   ),NIL,"SUM",oBreak2,"Custo Mao de Obra --",/*Picture*/,{|| If(IsProdMod((cQryOP)->D3_COD), oSection1:Cell('Custo'):GetValue()    , 0 ) },.F.,.F.) 

//===============
//Totais gerais |
//===============
oFunction := TRFunction():New(oSection1:Cell('D3_QUANT'),NIL,"SUM",NIL,"QTDE. TOTAL REQUISICOES ------->",,{|| If(!IsProdMod((cQryOP)->D3_COD) .And. SubStr((cQryOP)->D3_CF,1,2)=="RE" .And. SubStr(D3_CF,3,1) # "9", oSection1:Cell('D3_QUANT'):GetValue(), 0) },.F.,.T.)
oFunction := TRFunction():New(oSection1:Cell('Custo'   ),NIL,"SUM",NIL,"CUSTO TOTAL REQUISICOES ------->",PesqPict("SD3","D3_CUSTO1",21),{|| If(!IsProdMod((cQryOP)->D3_COD) .And. SubStr((cQryOP)->D3_CF,1,2)=="RE" .And. SubStr(D3_CF,3,1) # "9", oSection1:Cell('Custo'   ):GetValue(), 0) },.F.,.T.)

If lCalc
	nCMOP := CalcCMOP()
EndIf
oReport:Section(1):Cell('CMOP'):SetValue(nCMOP)
nCMOP := oSection1:Cell('CMOP'):GetValue()
oFunction := TRFunction():New(oSection1:Cell('CMOP'	   ),NIL,"ONPRINT",NIL,"CUSTO MEDIO OP ---------------->",,{|| nCMOP })
                                                         
oFunction := TRFunction():New(oSection1:Cell('D3_QUANT'),NIL,"SUM",NIL,"QTDE. TOTAL PRODUCAO ---------->",,{|| If(SubStr(D3_CF,1,2)=="PR",oSection1:Cell('D3_QUANT'):GetValue(),0) },.F.,.T.)
oFunction := TRFunction():New(oSection1:Cell('Custo'   ),NIL,"SUM",NIL,"CUSTO TOTAL PRODUCAO ---------->",PesqPict("SD3","D3_CUSTO1",21),{|| If(SubStr(D3_CF,1,2)=="PR",oSection1:Cell('Custo'   ):GetValue(),0) },.F.,.T.)

oFunction := TRFunction():New(oSection1:Cell('D3_QUANT'),NIL,"SUM",NIL,"QTDE. TOTAL DEVOLUCOES  ------->",,{|| If(!IsProdMod((cQryOP)->D3_COD) .And. SubStr((cQryOP)->D3_CF,1,2)=="DE" .And. SubStr(D3_CF,3,1) # "9", (- oSection1:Cell('D3_QUANT'):GetValue()), 0) },.F.,.T.)
oFunction := TRFunction():New(oSection1:Cell('Custo'   ),NIL,"SUM",NIL,"CUSTO TOTAL DEVOLUCOES  ------->",PesqPict("SD3","D3_CUSTO1",21),{|| If(!IsProdMod((cQryOP)->D3_COD) .And. SubStr((cQryOP)->D3_CF,1,2)=="DE" .And. SubStr(D3_CF,3,1) # "9", (- oSection1:Cell('Custo'   ):GetValue()), 0) },.F.,.T.)

oFunction := TRFunction():New(oSection1:Cell('D3_QUANT'),NIL,"SUM",NIL,"QTDE. TOTAL REQ PODER 3 ------->",,{|| If(!IsProdMod((cQryOP)->D3_COD) .And. SubStr((cQryOP)->D3_CF,1,2)=="RE" .And. SubStr(D3_CF,3,1)=="9", oSection1:Cell('D3_QUANT'):GetValue(), 0) },.F.,.T.)
oFunction := TRFunction():New(oSection1:Cell('Custo'   ),NIL,"SUM",NIL,"CUSTO TOTAL REQ PODER 3 ------->",PesqPict("SD3","D3_CUSTO1",21),{|| If(!IsProdMod((cQryOP)->D3_COD) .And. SubStr((cQryOP)->D3_CF,1,2)=="RE" .And. SubStr(D3_CF,3,1)=="9", oSection1:Cell('Custo'   ):GetValue(), 0) },.F.,.T.)
                                                                        
oFunction := TRFunction():New(oSection1:Cell('D3_QUANT'),NIL,"SUM",NIL,"QTDE. TOTAL DEV PODER 3 ------->",,{|| If(!IsProdMod((cQryOP)->D3_COD) .And. SubStr((cQryOP)->D3_CF,1,2)=="DE" .And. SubStr(D3_CF,3,1)=="9", (- oSection1:Cell('D3_QUANT'):GetValue()), 0) },.F.,.T.)
oFunction := TRFunction():New(oSection1:Cell('Custo'   ),NIL,"SUM",NIL,"CUSTO TOTAL DEV PODER 3 ------->",PesqPict("SD3","D3_CUSTO1",21),{|| If(!IsProdMod((cQryOP)->D3_COD) .And. SubStr((cQryOP)->D3_CF,1,2)=="DE" .And. SubStr(D3_CF,3,1)=="9", (- oSection1:Cell('Custo'   ):GetValue()), 0) },.F.,.T.)

oFunction := TRFunction():New(oSection1:Cell('D3_QUANT'),NIL,"SUM",NIL,"QTDE. TOTAL REQ. MAO DE OBRA -->",,{|| If(IsProdMod((cQryOP)->D3_COD) .And. SubStr((cQryOP)->D3_CF,1,2)=="RE" .And. SubStr(D3_CF,3,1) # "9", oSection1:Cell('D3_QUANT'):GetValue(), 0) },.F.,.T.)
oFunction := TRFunction():New(oSection1:Cell('Custo'   ),NIL,"SUM",NIL,"CUSTO TOTAL REQ. MAO DE OBRA -->",PesqPict("SD3","D3_CUSTO1",17),{|| If(IsProdMod((cQryOP)->D3_COD) .And. SubStr((cQryOP)->D3_CF,1,2)=="RE" .And. SubStr(D3_CF,3,1) # "9", oSection1:Cell('Custo'   ):GetValue(), 0) },.F.,.T.)

oFunction := TRFunction():New(oSection1:Cell('D3_QUANT'),NIL,"SUM",NIL,"QTDE. TOTAL DEV. MAO DE OBRA -->",,{|| If(IsProdMod((cQryOP)->D3_COD) .And. SubStr((cQryOP)->D3_CF,1,2)=="DE" .And. SubStr(D3_CF,3,1) # "9", (- oSection1:Cell('D3_QUANT'):GetValue()), 0) },.F.,.T.)
oFunction := TRFunction():New(oSection1:Cell('Custo'   ),NIL,"SUM",NIL,"CUSTO TOTAL DEV. MAO DE OBRA -->",PesqPict("SD3","D3_CUSTO1",17),{|| If(IsProdMod((cQryOP)->D3_COD) .And. SubStr((cQryOP)->D3_CF,1,2)=="DE" .And. SubStr(D3_CF,3,1) # "9", (- oSection1:Cell('Custo'   ):GetValue()), 0) },.F.,.T.)

//========================================================
//Inibindo celulas, utilizadas apenas para totalizadores |
//========================================================
oSection1:Cell('B1_CUSTD'):Hide()
oSection1:Cell('B1_CUSTD'):HideHeader()
oSection1:Cell('TotalSTD'):Hide()
oSection1:Cell('TotalSTD'):HideHeader() 
oSection1:Cell('CMOP'):Hide()
oSection1:Cell('CMOP'):HideHeader()

//==========================================================================
//Define o campo a ser impresso no valor de acordo com a moeda selecionada |
//==========================================================================
Do Case
	Case MV_PAR03 == 1
		If lCusRep .And. MV_PAR07==2
			cCampoCus :=   "(cQryOP)->D3_CUSRP1"
		Else
			cCampoCus :=   "(cQryOP)->D3_CUSTO1"
		EndIf	
	Case MV_PAR03 == 2
		If lCusRep .And. MV_PAR07==2
			cCampoCus :=   "(cQryOP)->D3_CUSRP2"
		Else
			cCampoCus :=   "(cQryOP)->D3_CUSTO2"
		EndIf	
	Case MV_PAR03 == 3
		If lCusRep .And. MV_PAR07==2
			cCampoCus :=   "(cQryOP)->D3_CUSRP3"
		Else
			cCampoCus :=   "(cQryOP)->D3_CUSTO3"
		EndIf	
	Case MV_PAR03 == 4
		If lCusRep .And. MV_PAR07==2
			cCampoCus :=   "(cQryOP)->D3_CUSRP4"
		Else
			cCampoCus :=   "(cQryOP)->D3_CUSTO4"
		EndIf	
	Case MV_PAR03 == 5
		If lCusRep .And. MV_PAR07==2
			cCampoCus :=   "(cQryOP)->D3_CUSRP5"
		Else
			cCampoCus :=   "(cQryOP)->D3_CUSTO5"
		EndIf	
EndCase

//===========================================
//Inicio da impressao do fluxo do relatorio |
//===========================================
DBSelectArea(cQryOP)
COUNT TO _nTotal
DBGoTop()
oSection1:Init()
nTxCofin := GetMv("MV_TXCOFIN") 
nTxPis	 := GetMv("MV_TXPIS")
oReport:IncMeter()
oReport:SetMeter(_nTotal)

While !oReport:Cancel() .And. !(cQryOP)->(Eof())

	cOpAnt	:= (cQryOP)->D3_OP
	lPrim	:= .T.   

	While (cQryOP)->D3_FILIAL+(cQryOP)->D3_OP == xFilial("SD3")+cOpAnt		
		
	    oReport:IncMeter()
		If lPrim
			CalcTot()
			lPrim := .F.
		EndIf
		
		oReport:Section(1):Cell('D3_OP'   ):SetValue( (cQryOP)->D3_OP )
		oReport:Section(1):Cell('D3_QUANT'):SetValue( If(SubStr((cQryOP)->D3_CF,1,2)=="DE",( -(cQryOP)->D3_QUANT ),(cQryOP)->D3_QUANT) )
		oReport:Section(1):Cell('Unitario'):SetValue( (&(cCampoCus)/oSection1:Cell('D3_QUANT'):GetValue()) )
		oReport:Section(1):Cell('Custo'   ):SetValue( If(SubStr((cQryOP)->D3_CF,1,2)=="DE",( -&(cCampoCus)),&(cCampoCus)) )             
		oReport:Section(1):Cell('CustProd'):SetValue( If(SubStr((cQryOP)->D3_CF,1,2)=="DE",( -&(cCampoCus)),&(cCampoCus)) / nQuant )
		oReport:Section(1):Cell('Unit2'):SetValue( ((oSection1:Cell('Unitario'):GetValue() * (nTxCofin+nTxPis)) / 100) + oSection1:Cell('Unitario'):GetValue() )
		oReport:Section(1):Cell('Cust2'):SetValue( ((oSection1:Cell('Custo'):GetValue() * (nTxCofin+nTxPis)) / 100) + oSection1:Cell('Custo'):GetValue() )
		oReport:Section(1):Cell('CustPro2'):SetValue( ((oSection1:Cell('CustProd'):GetValue() * (nTxCofin+nTxPis)) / 100) + oSection1:Cell('CustProd'):GetValue())
   		#IFDEF TOP
			If !(lCusRep .And. MV_PAR07==2)
				oReport:Section(1):Cell('B1_CUSTD'):SetValue( If(SubStr((cQryOP)->D3_CF,1,2)=="PR", RetFldProd((cQryOP)->B1_COD,"B1_CUSTD",cQryOP) ,0) )
			EndIf	
		#Else
			DBSelectArea("SB1")
			DBSeek(xFilial("SB1")+(cQryOP)->D3_COD)
			If !(lCusRep .And. MV_PAR07==2)
				oReport:Section(1):Cell('B1_CUSTD'):SetValue( If(SubStr((cQryOP)->D3_CF,1,2)=="PR",RetFldProd(SB1->B1_COD,"B1_CUSTD"),0) )
			EndIf	
			DBSelectArea(cQryOP)
		#EndIf
		If !(lCusRep .And. MV_PAR07==2)
			oReport:Section(1):Cell('TotalSTD'):SetValue( If(SubStr((cQryOP)->D3_CF,1,2)=="PR",( oSection1:Cell('B1_CUSTD'):GetValue() * oSection1:Cell('D3_QUANT'):GetValue() ) , 0)  )
		EndIf	
		If SubStr((cQryOP)->D3_CF,1,2) == "PR"
			oReport:SkipLine()
		EndIf
		If oReport:Cancel()
    	   	Exit
		EndIf
		oSection1:PrintLine()
		DBSkip()
	EndDo
	If lCusRep .And. MV_PAR07==2
		oReport:PrintText( cOpAnt+" - Valor final no ultimo fechamento ("+DToC(dDataFec)+") => "+Transform(Posicione("SC2",1,xFilial("SC2")+cOpAnt,"C2_VFIMRP"+Str(MV_PAR03,1)),PesqPict("SC2","C2_VFIM1")) ) //" - Valor final no ultimo fechamento ("
	Else
		oReport:PrintText( cOpAnt+" - Valor final no ultimo fechamento ("+DToC(dDataFec)+") => "+Transform(Posicione("SC2",1,xFilial("SC2")+cOpAnt,"C2_VFIM"+Str(MV_PAR03,1)),PesqPict("SC2","C2_VFIM1")) ) //" - Valor final no ultimo fechamento ("
	EndIf		
	oReport:PrintText( "Produto : "+Posicione("SC2",1,xFilial("SC2")+cOpAnt,"C2_PRODUTO") ) 
EndDo
oSection1:Finish()
(cQryOP)->(DBCloseArea())
Return

/*
===============================================================================================================================
Programa----------: CalcTot
Autor-------------: Lucas Crevilari
Data da Criacao---: 21/07/2014
Descrição---------: Realiza o calculo da quantitade total por OP
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function CalcTot()

Local cChave	:= xFilial("SD3")+(cQryOP)->D3_OP

Private cNumOp	:= ""
Private nCont	:= 0

While (cQryOP)->(!Eof()) .And. (cQryOP)->D3_FILIAL+(cQryOP)->D3_OP == cChave
	nQuant := If(SubStr((cQryOP)->D3_CF,1,2)=="DE",( -(cQryOP)->D3_QUANT ),(cQryOP)->D3_QUANT) 		
	(cQryOP)->(DBSkip())
EndDo

(cQryOP)->( DBGoTop() )

While (cQryOP)->(!Eof()) .And. (cQryOP)->D3_FILIAL+(cQryOP)->D3_OP <> cChave
	(cQryOP)->(DBSkip())
EndDo

Return   

/*
===============================================================================================================================
Programa----------: CalcCMOP
Autor-------------: Lucas Crevilari
Data da Criacao---: 24/09/2014
Descrição---------: Realiza o calculo do Total Custo Medio por OP. Chamado 7515
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function CalcCMOP()

Local cChave	:= xFilial("SD3")+(cQryOP)->D3_OP
Private cNumOp	:= ""
Private nCont	:= 0

While !(cQryOP)->(Eof())
	cOpAnt	:= (cQryOP)->D3_OP
	lPrim	:= .T.
	While (cQryOP)->D3_FILIAL+(cQryOP)->D3_OP == xFilial("SD3")+cOpAnt
		If lPrim
			While (cQryOP)->D3_FILIAL+(cQryOP)->D3_OP == xFilial("SD3")+cOpAnt //While (cQryOP)->(!Eof()) .And. (cQryOP)->D3_FILIAL+(cQryOP)->D3_OP == cChave
				nCusReq += If(SubStr((cQryOP)->D3_CF,1,2)=="RE" .And. SubStr(D3_CF,3,1) # "9", (cQryOP)->D3_CUSTO1, 0)
				nQtdProd += If(SubStr((cQryOP)->D3_CF,1,2)=="PR",(cQryOP)->D3_QUANT,0)
				(cQryOP)->(DBSkip())
			EndDo
			lPrim := .F.
		Else
			(cQryOP)->(DBSkip())		
		EndIf 
	EndDo     
EndDo
                 
(cQryOP)->( DBGoTop() )
While (cQryOP)->(!Eof()) .And. (cQryOP)->D3_FILIAL+(cQryOP)->D3_OP <> cChave
	(cQryOP)->(DBSkip())
EndDo     
     
nCMOP := nCusReq/nQtdProd
lCalc := .F.

Return(nCMOP)
