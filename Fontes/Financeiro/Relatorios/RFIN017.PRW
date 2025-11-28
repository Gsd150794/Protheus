/*
F===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Josué Prestes |10/06/2019| Chamado 29593. Ajuste para loboguara
Julio Paz     |21/06/2019| Chamado 28886. Ajustes do fonte para o novo servidor Totvs Lobo Guara
Lucas Borges  |12/09/2024| Chamado 48465. Removendo warning de compilação.
===============================================================================================================================
*/

#Include "FINR610.CH"
#Include "TOTVS.ch"

#DEFINE PREFIXO		1
#DEFINE TITULO		2
#DEFINE PARCELA		3                   
#DEFINE COD_CLI		4
#DEFINE LOJA			5
#DEFINE NOME_CLI		6                 
#DEFINE DT_EMIS		7
#DEFINE DT_VENC		8
#DEFINE VAL_TIT		9
#DEFINE COM_EMISS		10
#DEFINE COM_BAIXA		11
#DEFINE VAL_BASE		12
#DEFINE PERC			13
#DEFINE VAL_COMIS		14
#DEFINE PARC			15
#DEFINE CODFIL		16

Static lSF2460I := ExistBlock("SF2460I")
Static lF440VEND

/*
===============================================================================================================================
Programa----------: RFIN017
Autor-------------: Julio de Paula Paz
Data da Criacao---: 02/08/2018                            .
Descrição---------: Relatório Previsão de Comissões baseado no FIN610 - Chamado 25644.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RFIN017()
Local oReport

If TRepInUse()
	oReport := RFIN017R()
	oReport:PrintDialog()
EndIf

Return

/*
===============================================================================================================================
Programa----------: RFIN017R()
Autor-------------: Daniel Batori
Data da Criacao---: 28.08.06
Descrição---------: Definicao do layout do Relatorio
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RFIN017R()
Local oReport
Local oSection1
Local cPictVal

pergunte("FIN610",.F.)

oReport := TReport():New("RFIN017",STR0003,"FIN610", {|oReport| RFIN017P(oReport)},STR0001+STR0002)

//================================================================
// Variaveis utilizadas para parametros                          |
// MV_PAR01         // Do Vendedor                               |
// MV_PAR02         // At‚ o Vendedor                            |
// MV_PAR03         // Vencto de                                 |
// MV_PAR04         // Vencto At‚                                |
// MV_PAR05         // Qual Moeda                                |
// MV_PAR06         // Da emiss„o                                |
// MV_PAR07         // At‚ a emiss„o                             |
// MV_PAR08         // Comiss„o Zero                             |
// MV_PAR09         // Considera P.Venda                         |
// MV_PAR10         // Abate IR Comiss                           |
// MV_PAR11         // Outras Moedas                             |
// MV_PAR12         // Salta Pagina por Vendedor                 |
// MV_PAR13         // Nome cliente							     |
//================================================================

cPictVal	:= PesqPict("SE1","E1_VLCRUZ")

oSection1 := TRSection():New(oReport,STR0024,{},)                         // "Registros"
TRCell():New(oSection1,"E1_FILORIG","SE1",STR0048,,,.F.,)                 // "FILIAL"
TRCell():New(oSection1,"E1_PREFIXO","SE1",STR0025,,,.F.,)                 // "PRF"
TRCell():New(oSection1,"E1_NUM","SE1",	STR0026+CRLF+STR0027,,,.F.,)      // "TITULO" "PEDIDO"
TRCell():New(oSection1,"E1_PARCELA","SE1",STR0028,,3,.F.,)                // "PRC"
TRCell():New(oSection1,"E1_CLIENTE"	,"SE1",STR0029+CRLF+STR0030,,,.F.,)   // "CODIGO" "CLIENTE"
TRCell():New(oSection1,"E1_LOJA","SE1",STR0031,,,.F.,)                    // "LJ"
TRCell():New(oSection1,"A1_NOME","SA1",STR0032,,,.F.,)                    // "NOME"
TRCell():New(oSection1,"E1_EMISSAO","SE1",STR0033+CRLF+STR0034,,,.F.,)    // "DATA DE""EMISSAO"
TRCell():New(oSection1,"E1_VENCREA","SE1",STR0035+CRLF+STR0036,,,.F.,)    // "DATA""VENCTO"
TRCell():New(oSection1,"E1_VLCRUZ","SE1",STR0037+CRLF+STR0038,,,.F.,)     // "VALOR""TITULO"
TRCell():New(oSection1,"VL_EMISS",,STR0039+CRLF+STR0040,cPictVal,13,.F.,) // "COMISSAO""P/EMISSAO"
TRCell():New(oSection1,"VL_BAIXA",,STR0039+CRLF+STR0041,cPictVal,13,.F.,) // "COMISSAO""P/BAIXA"
TRCell():New(oSection1,"VL_BASE",,STR0042+CRLF+STR0041,cPictVal,13,.F.,)  // "VALOR BASE""P/BAIXA"
TRCell():New(oSection1,"PERC_COMI",,STR0043+CRLF+STR0044,"999.99",5,.F.,) // "%COMIS""TOTAL"
TRCell():New(oSection1,"VL_COMIS",,STR0045+CRLF+STR0046,cPictVal,13,.F.,) // "VALOR TOTAL""DA COMISSAO"
TRCell():New(oSection1,"PARC",,STR0047,,1,.F.,)                           // "P/T"

oSection1:Cell("E1_VLCRUZ"):SetHeaderAlign("RIGHT")
oSection1:Cell("VL_EMISS"):SetHeaderAlign("RIGHT")
oSection1:Cell("VL_BAIXA"):SetHeaderAlign("RIGHT")
oSection1:Cell("VL_BASE"):SetHeaderAlign("RIGHT")
oSection1:Cell("PERC_COMI"):SetHeaderAlign("RIGHT")
oSection1:Cell("VL_COMIS"):SetHeaderAlign("RIGHT")

oSection1:SetHeaderSection(.F.)

oReport:SetLandScape()

Return oReport

/*
===============================================================================================================================
Programa----------: RFIN017P(oReport)
Autor-------------: Daniel Batori
Data da Criacao---: 28.08.06
Descrição---------: Emite o relatório.
Parametros--------: oReport = objeto do relatório
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RFIN017P(oReport)
Local oSection1 := oReport:Section(1)
Local aDados[16]

Local cTitulo

Local aCampos :={}
Local cVendAnt:=Space(6)
Local nComissao:=0.00
Local nValTit :=0.00
Local nComEnt :=0.00
Local nComVen :=0.00
Local nValBas :=0.00
Local nPorc   :=0.00
Local nVendComis :=0.00
Local nTotTit :=0.00
Local nTotEnt :=0.00
Local nTotVen :=0.00
Local nTotBas :=0.00
Local nTotComis :=0.00
Local lFirst:=.T.
Local aParcelas := {}	// Array das comissoes (geral)
Local aParcItem := {}	// Array das comissoes (item)
Local nVendSC5 := 0		// Codigo do vendedor no pedido
Local nComiSC5 := 0		// Percentual Comissao no pedido
Local nComiSC6 := 0		// Percentual comissao no item do pedido
Local nPerComE := 0		// Percentual comissao na emissao vendedor
Local nPerComB	:= 0	// Percentual comissao na Baixa vendedor
Local nRegSC6	:= 0	// Registro do item de pedido
Local nQtdItem := 0		// Quantidade de produtos nao entregues
Local nPercItem:= 0		// Percentual a ser usado (pedido ou item)
Local nVlTotPed:= 0		// Valor total do pedido nao entregue
Local nIrEnt	:= 0	// Ir na Emissao
Local nIrVen	:= 0	// Ir na Baixa
Local nVendIr	:= 0	// total de Ir do vendedor
Local nTotIrE	:= 0	// Total geral de IR na emissao
Local nTotIrB	:= 0	// Total geral de IR na Baixa
Local nTotIrVen:= 0		// Total geral de IR do relatorio
Local nTotPorc := 0	    // Percentual medio de comissoes do relatorio
Local nTotCount:= 0
Local nCount	:= 0
Local aLiquid	:= {}
Local aSeqCont	:= {}   // Controle de calculo de comissoes (Sequencia no SE5)
Local aTam		:= {}
Local nValMinRet	:= SuperGetMv( "MV_VLRETIR" ,,0) // Valor minimo para retencao do IR
Local nMoedaBco :=1, dDataConv
Local cTipo
Local cParcela
Local cPrefixo
Local cNum
Local cTipoFat
Local nBaseCom
Local nValorFat
Local nCond
Local nIrrItem := 0
Local nInsItem := 0
Local nPisItem := 0
Local nCofItem := 0
Local nCslItem := 0
Local nIcmItem := 0
Local nIssItem := 0
Local nSolItem := 0
Local nRecOri	:= 0
Local nItem		:= 0
Local nTotImp	:= 0
Local nJurLiq	:= 0
Local nPerJur	:= 0
Local nDescLiq	:= 0
Local nPerDesc	:= 0
Local nVlrLiq	:= 0
Local lImpSub := .T.		// Imprime subtotal
Local lBxReneg	:=	.F.
Local lReneg		:=	.F.

Local nX
Local aBaseAux := {}, nBaseAux, nPerAux
Local cNumLiq,_cEmp :=	""

Local lJuros   := .F. 
Local lDescont := .F. 

Local cA1Vend		:=	""
Local aSelFil		:= {}
Local cFilBack	:= cFilAnt
Local lTroca	:= .F.
Local cSeq		:= "00"
Local lGetParAut	:= FindFunction("GetParAuto")

Private nDecs   := MsDecimais(MV_PAR05)
Private nIndexSE5
Private aVendedor

//ESSA VALIDACAO É NECESSARIO APENAS PARA 
//RELEASE 12.1.7
If ValType(MV_PAR16) != "C" 
	If MV_PAR16 == 1	// Considera Juros?
		lJuros := .T.
	EndIf
EndIf

If ValType(MV_PAR17) != "C"
	If MV_PAR17 == 1	// Considera Desconto?
		lDescont := .T.
	EndIf
EndIf
//FIM VALIDACAO

If MV_PAR15 == 1 .And. !IsBlind()
	aAreaSM0 := SM0->(GetArea())
	_cEmp    :=FWSM0LayOut() //Funcao de Framework que retorna a configuracao da empresa no sigamat 
	If "E" $ _cEmP .Or. "U" $ _cEmP //Verifica se na configuracao Possui E - Empresa ou
	   aSelFil := FwSelectGC()		//U - Unidade de negocio.
	Else
		aSelFil := AdmGetFil(.F.,.F.,"SE5")
		If Empty(aSelFil)
			aAdd(aSelFil,cFilAnt)
		EndIf
	EndIf
ElseIf lGetParAut
	aRetAuto	:= GetParAuto("RFIN017TestCase")
	aSelFil:= IIf(ValType(aRetAuto) == "A", aRetAuto, aSelFil)
	nRegSM0 := SM0->(Recno())
	SM0->(DBGoTo(nRegSM0))
EndIf

If Empty(aSelFil)
	aAdd(aSelFil,cFilAnt)
EndIf

//===============================================================
// criação do indice temporario pra busca do numero da fatura
//===============================================================
SE5->(DBSetOrder(10))
SE5->(DBGoTop())

oSection1:Cell("E1_PREFIXO"):SetBlock( { || aDados[PREFIXO] })
oSection1:Cell("E1_NUM"):SetBlock( { || aDados[TITULO] })
oSection1:Cell("E1_PARCELA"):SetBlock( { || aDados[PARCELA] })
oSection1:Cell("E1_CLIENTE"):SetBlock( { || aDados[COD_CLI] })
oSection1:Cell("E1_LOJA"):SetBlock( { || aDados[LOJA] })
oSection1:Cell("A1_NOME"):SetBlock( { || aDados[NOME_CLI] })
oSection1:Cell("E1_EMISSAO"):SetBlock( { || aDados[DT_EMIS] })
oSection1:Cell("E1_VENCREA"):SetBlock( { || aDados[DT_VENC] })
oSection1:Cell("E1_VLCRUZ"):SetBlock( { || aDados[VAL_TIT] })
oSection1:Cell("VL_EMISS"):SetBlock( { || aDados[COM_EMISS] })
oSection1:Cell("VL_BAIXA"):SetBlock( { || aDados[COM_BAIXA] })
oSection1:Cell("VL_BASE"):SetBlock( { || aDados[VAL_BASE] })
oSection1:Cell("PERC_COMI"):SetBlock( { || aDados[PERC] })
oSection1:Cell("VL_COMIS"):SetBlock( { || aDados[VAL_COMIS] })
oSection1:Cell("PARC"):SetBlock( { || aDados[PARC] })
oSection1:Cell("E1_FILORIG"):SetBlock( { || aDados[CODFIL] })
oReport:OnPageBreak({ ||	oSection1:SetHeaderSection(.T.), ;
									aDados[TITULO] := " " , ;
									oSection1:SetHeaderSection(.T.) } )

//===================================================================
// Define array para arquivo de trabalho                        
//===================================================================
aTam:=TamSX3("E1_FILORIG")
aAdd(aCampos,{ "FILIAL" ,"C",aTam[1],aTam[2] } )
aTam:=TamSX3("E1_VEND1")
aAdd(aCampos,{ "CODIGO" ,"C",aTam[1],aTam[2] } )
aAdd(aCampos,{ "CHAVE"  ,"C",10,0 } )
aAdd(aCampos,{ "NVEND"  ,"N",01,0 } )
aAdd(aCampos,{ "PVEND"  ,"C",01,0 } )
aAdd(aCampos,{ "CHVFAT" ,"N",10,0 } )
aAdd(aCampos,{ "RECPRINC","N",10,0 } )

aTam := TamSX3("E1_CLIENTE")

//===================================================================
// Cria tabela temporária / Arquivo de trabalho.
//===================================================================

If Select("TRB") > 0
   TRB->( DBCloseArea() )
EndIf
   
//================================================================================
// Abre o arquivo TRBZAE criado dentro do protheus.
//================================================================================
_otemp := FWTemporaryTable():New( "TRB",  aCampos )
   
//================================================================================
// Cria os indices para o arquivo.
//================================================================================
_otemp:AddIndex( "01", {"CODIGO","FILIAL","CHAVE"} )
_otemp:Create()

/*
//===================================================================
// Cria arquivo de Trabalho                                     
//===================================================================
cNomArq := CriaTrab(aCampos)
dbUseArea( .T.,, cNomArq, "Trb", If(.F. .Or. .F., !.F., NIL), .F. )
IndRegua("TRB",cNomArq,"CODIGO+FILIAL+CHAVE",,,OemToAnsi(STR0023))
*/

//===================================================================
// Defini‡„o dos cabe‡alhos                                     
//===================================================================
cTitulo := oReport:Title() + STR0022 + GetMV("MV_MOEDA"+Str(MV_PAR05,1))
oReport:SetTitle(cTitulo)

DBSelectArea("TRB")
DBSetOrder(1)
DBGoTop()

DBSelectArea("SE1")
DBSetOrder(7)

oReport:SetMeter(SE1->(RecCount()))

If MV_PAR14 == 1
	Fr610ProcP(@oReport, ,aSelFil)
Else
	Fr610ProcF(@oReport, ,aSelFil)
EndIf

DBSelectArea("TRB")
DBGoTop()

oReport:SetMeter(TRB->(RecCount()))

oSection1:Init()
aFill(aDados,nil)

While TRB->(!Eof())

	lFirst  := .T.
	cVendAnt:= CODIGO
	nCount	:= 0
	
		While TRB->(!Eof()) .And. cVendAnt == CODIGO
					// Muda para a filial do título que irá tratar
					cFilAnt	:= TRB->FILIAL
					
					oReport:IncMeter()
			
					nComissao := 0
					nJurLiq		:= 0
					nPerJur		:= 0
					nDescLiq	:= 0
					nPerDesc	:= 0
					nVlrLiq		:= 0
					lImpSub := .T.
					//===================================================================
					// Verifica se a previsao sera calculada por titulo ja gerado   
					// ou pedido de vendas.                                         
					//===================================================================
					If TRB->PVEND == "N"
						DBSelectArea("SE1")
						DBSetOrder(1)
						If TRB->CHVFAT > 0 .And. TRB->CHVFAT <> TRB->RECPRINC
							DBGoTo(TRB->CHVFAT)
						Else
							DBGoTo(Val(TRB->CHAVE))
							lTroca	:= .T.
						EndIf
						//===================================================================		
						// Títulos renegociados LIQUIDAÇÃO
						//===================================================================
						If MV_PAR14 == 2 .And. !Empty(SE1->E1_NUMLIQ) .And. ( !lJuros .Or. !lDescont )
							
							If cNumLiq != SE1->E1_NUMLIQ
								aLiquid 	:=	{}
								aSeqCont	:=	{}
								Fa440LiqSe1(SE1->E1_NUMLIQ,@aLiquid,,@aSeqCont)
								cNumLiq	:= SE1->E1_NUMLIQ
							EndIf
							
							aAreaSE1 := FWGetArea()
							For nX := 1 To Len(aLiquid)
								SE1->(DBGoTo(aLiquid[nX]))
								nJurLiq += F440JurLiq(SE1->(Recno()))
								nDescLiq += F440DesLiq(SE1->(Recno()))
								nVlrLiq  += SE1->E1_VLCRUZ
							Next nX
							FWRestArea(aAreaSE1)
							
							nVlrLiq := nVlrLiq + nJurLiq - nDescLiq
							nPerJur	:= If( !lJuros, ((nJurLiq*1000)/nVlrLiq)/1000, 0)
							nPerDesc := If( !lDescont, ((nDescLiq*1000)/nVlrLiq)/1000, 0)
							
						EndIf
			
						//===================================================================
						// Calculo Bases, valores e percentuais de comissao.                |
						// Constituicao de aBases{} retornada por FA440COMIS()              |
						// Coluna 01    Vendedor        	       		                    |
						// Coluna 02    Valor do Titulo    		                            | 
						// Coluna 03    Base Comissao Emissao			                    |  
						// Coluna 04    Base Comissao Baixa	                                |
						// Coluna 05    Comissao Emissao								    | 
						// Coluna 06    Comissao Baixa                                      |
						// Coluna 07    % Total da comissao                                 | 
						//===================================================================
						
						aBases  := Fa440Comis(SE1->(Recno()),.F.,.T.,,,TRB->RECPRINC)
						nBases 	:= aScan(aBases,{|x| x[1] == TRB->CODIGO })
						lBxReneg	:= .F.
						lReneg		:= .F.
						
						If lTroca
							DBGoTo(TRB->CHVFAT)
						EndIf
						If MV_PAR14 == 1
							If !Empty(SE1->E1_NUMLIQ) .Or. !Empty(E1_FATURA)
								lReneg	:= .T.
							EndIf 
						ElseIf	MV_PAR14 == 2 		
							If !Empty(SE1->E1_BAIXA)		
								SE5->(DBSetOrder(7))		//E5_FILIAL+E5_PREFIXO+E5_NUMERO+E5_PARCELA+E5_TIPO+E5_CLIFOR+E5_LOJA+E5_SEQ
								cSeq	:=	MaxSeqSe5(SE1->(E1_FILIAL + E1_PREFIXO + E1_NUM + E1_PARCELA + E1_TIPO + E1_CLIENTE + E1_LOJA))
								If SE5->(MSSeek(FWxFilial('SE5') + SE1->(E1_PREFIXO + E1_NUM + E1_PARCELA + E1_TIPO + E1_CLIENTE + E1_LOJA + cSeq)))
									If SE5->E5_MOTBX == 'LIQ' .Or. SE5->E5_MOTBX ==	'FAT' 
										lBxReneg	:= .T.
									EndIf
								EndIf
							EndIf
						EndIf
						If lTroca
							DBGoTo(Val(TRB->CHAVE))
						EndIf
					
						If	!lBxReneg .And. !lReneg
						
							SE3->( DBSetOrder(3) )
							
							If Len(aBases) > 0
								If 	TRB->CHVFAT > 0 .And. (aBases[nBases][7] == 0 .Or. IsFatura()) .And.;	// Existe mais de um percentual de comissao (comissao por produto)
									!SE3->( MsSeek( xFilial("SE3") + aBases[nBases,1]+SE1->(E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA) ) ) // Nao eh comissao realizada
									
									// Recalcula bases pelo total da nota de saida, sem considerar parcelas geradas.
									cA1Vend	:= Posicione("SA1",1,xFilial("SA1") + SE1->(E1_CLIENTE + E1_LOJA),"A1_VEND")
									
									If Empty(cA1Vend) .Or. (!Empty(cA1Vend) .And. cA1Vend == cVendAnt) 
										aBases := Fa440Comis(SE1->(Recno()),.F.,.T.,,.F./*Nao calcula por parcelas*/)
									EndIf										
									nBases 	:= aScan(aBases,{|x| x[1] == TRB->CODIGO })					
									If nBases > 0  //se encontrou vendendor
										If aBases[nBases][7] == 0
											aBaseAux := Fa440Comis(TRB->RECPRINC,.F.,.T.,,.F./*Nao calcula por parcelas*/)
											nBaseAux := aScan(aBaseAux,{|x| x[1] == TRB->CODIGO })
											If nBaseAux > 0
												If aBases[nBases][5]+aBases[nBases][6] == 0
												   If ( aBaseAux[nBaseAux][3]+aBaseAux[nBaseAux][4] ) > 0
													   nPerAux := ( aBases[nBases][3]+aBases[nBases][4] ) / ( aBaseAux[nBaseAux][3]+aBaseAux[nBaseAux][4] )
												   Else
													   nPerAux := 1
												   EndIf
												   aBases[nBases][5] := aBaseAux[nBaseAux][5]*nPerAux
												   aBases[nBases][6] := aBaseAux[nBaseAux][6]*nPerAux
												   If ( aBases[nBases][3]+aBases[nBases][4] ) > 0
													   aBases[nBases][7] := ( aBases[nBases][5]+aBases[nBases][6] ) / ( aBases[nBases][3]+aBases[nBases][4] ) * 100
												   EndIf
												EndIf
											EndIf
										EndIf
									EndIf
								EndIf
							EndIf
				
							If TRB->CHVFAT > 0
								DBGoTo(Val(TRB->CHAVE))
							EndIf
							If nBases = 0
								//===================================================================
								// Caso vendedor n„o seja encontrado...           
								//===================================================================
								DBSelectArea("TRB")
								DBSkip()
								Loop
							EndIf
							cChaveSE3 := aBases[nBases,1]+SE1->(E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM)
							cTipo 	 := SE1->E1_TIPO
							cParcela	 := SE1->E1_PARCELA
				
							DBSelectArea("SE1")
							aAreaSE1 := FWGetArea()
							DBGoTo(TRB->RECPRINC)
							nBaseCom	 := SE1->&("E1_BASCOM"+Str(TRB->NVEND,1)) // Utilizado para estornar a base de comissao do titulo
							nComissao := (SE1->&("E1_COMIS"+Str(TRB->NVEND,1))/100)*nBaseCom // Utilizado para estornar o valor da comissao do titulo
							FWRestArea(aAreaSE1)
				
							If !Empty(SE1->E1_FATURA) .And. AllTrim(SE1->E1_FATURA) != "NOTFAT"
								cTipoFat	:= SE1->E1_TIPOFAT
								//========================================================================
								// Localiza o titulo de fatura, pois no SE3 eh gerado o titulo de fatura
								// para verificar as comissoes que ja foram pagas.
								//========================================================================
								SE1->(MsSeek(xFilial("SE1")+E1_FATPREF+E1_FATURA)) // Localiza o titulo de fatura
								cPrefixo := SE1->E1_PREFIXO
								cNum	   := SE1->E1_NUM
								//========================================================================
								// Processar todas as parcelas da fatura gerada e verificar se a comissao
								// para a parcela nao foi paga.
								//========================================================================
								While xFilial("SE1")+SE1->(E1_PREFIXO+E1_NUM) == xFilial("SE1")+cPrefixo+cNum .And.;
										SE1->(!Eof())
									If SE1->E1_TIPO == cTipoFat
										//===================================================================
										// Verificar comissoes ja pagas                                 
										//===================================================================
										cChaveSE3 := aBases[nBases,1]+SE1->(E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM)
										cTipo 	 := SE1->E1_TIPO
										cParcela	 := SE1->E1_PARCELA
										nValorFat := SE1->E1_VLCRUZ
										FA610ComPg(@aBases,cChaveSE3,nBases,cTipo,cParcela,nValorFat,nBaseCom,nComissao)
									EndIf
									SE1->(DBSkip())
								End
								DBSelectArea("SE1")
								DBSetOrder(1)
								DBGoTo(Val(TRB->CHAVE))
							Else
								FA610ComPg(@aBases,cChaveSE3,nBases,cTipo,cParcela,SE1->E1_VLCRUZ,nBaseCom,nComissao)
							EndIf
				
							//===================================================================
							// Caso percentual de comissao seja retornado == a zero, devo   
							// calcular a media (Faturamento com comissao no item <> percen-
							// tual do vendedor)                                            
							//===================================================================
							If aBases[nBases,7] == 0
								aBases[nBases,7] := (((aBases[nBases,5]+aBases[nBases,6])*100)/aBases[nBases,2])
							EndIf
				
							//===================================================================
							// Imprime o Vendedor caso possa imprimir Comiss„o Zero ou      
							// exista alguma comiss„o para o Vendedor                       
							//===================================================================
							If MV_PAR08 == 1 .Or. aBases[nBases,6] != 0 .Or. aBases[nBases,5] != 0
								If lFirst
									DBSelectArea("SA3")
									DBSeek(cFilial+TRB->CODIGO)
				
									oReport:PrintText( PadR(STR0009 + TRB->CODIGO,16) + STR0010 + SA3->A3_NOME ) //"CODIGO : ""NOME : "
									oReport:SkipLine()
				
									DBSelectArea("TRB")
									lFirst := .F.
								EndIf
								DBSelectArea("SE1")
								DBSetOrder(1)
								DBGoTo(Val(TRB->CHAVE))
								If cPaisLoc == "BRA"
								   nMoedaBco := 1
								   dDataConv := dDataBase
								Else
							   //	   nMoedaBco := SE1->E1_MOEDA
								   dDataConv := SE1->E1_EMISSAO
								EndIf
				
								aBases[nBases,2] := xMoeda(aBases[nBases,2],nMoedaBco,MV_PAR05,dDataConv,nDecs+1)
								aBases[nBases,4] := xMoeda(aBases[nBases,4],nMoedaBco,MV_PAR05,dDataConv,nDecs+1)
								aBases[nBases,5] := xMoeda(aBases[nBases,5],nMoedaBco,MV_PAR05,dDataConv,nDecs+1)
								aBases[nBases,6] := xMoeda(aBases[nBases,6],nMoedaBco,MV_PAR05,dDataConv,nDecs+1)
				
								aDados[PREFIXO]	:= E1_PREFIXO
								aDados[TITULO]	:= E1_NUM
								aDados[PARCELA]	:= E1_PARCELA
								aDados[COD_CLI]	:= E1_CLIENTE
								aDados[LOJA]		:= E1_LOJA
								aDados[CODFIL]	:= E1_FILORIG
								
								DBSelectArea("SA1")
								DBSeek(cFilial+SE1->E1_CLIENTE+SE1->E1_LOJA)
								aDados[NOME_CLI]	:= If(MV_PAR13 == 1,SA1->A1_NREDUZ,SA1->A1_NOME)
								DBSelectArea("SE1")
								
								For nX := 1 To Len(aBases[nBases])
									If Str(nX,1) $ "2|4|5|6"
										aBases[nBases,nX] -= NoRound(aBases[nBases,nX] * nPerJur,nDecs)
										aBases[nBases,nX] += NoRound(aBases[nBases,nX] * nPerDesc,nDecs)
									EndIf
								Next nX
								
								nComissao := xMoeda(aBases[nBases,5] + aBases[nBases,6],nMoedaBco,MV_PAR05,dDataConv,nDecs+1)
				
								aDados[DT_EMIS]	:= E1_EMISSAO
								aDados[DT_VENC]	:= E1_VENCREA
								aDados[VAL_TIT]	:= aBases[nBases,2]
								aDados[COM_EMISS]	:= aBases[nBases,5]
								aDados[COM_BAIXA]	:= aBases[nBases,6]
								aDados[VAL_BASE]	:= aBases[nBases,4]
								aDados[PERC]		:= aBases[nBases,7]
								aDados[VAL_COMIS]	:= nComissao
								aDados[PARC]		:= "T"     // identificador de Titulo ou Pedido
								
								oSection1:PrintLine()
								aFill(aDados,nil)
				
							   	nValTit		+= aBases[nBases,2]
								nComEnt		+= aBases[nBases,5]
								nIrEnt		+= If(aBases[nBases,2] > nValMinRet,aBases[nBases,5] * (MV_PAR10/100),0)
								nComVen		+= aBases[nBases,6]
								nIrVen		+= If(aBases[nBases,2] > nValMinRet, aBases[nBases,6] * (MV_PAR10/100),0)
								nValBas		+= aBases[nBases,4]
								nPorc			+= aBases[nBases,7]
								nVendComis	+= nComissao
								nVendIr		+= If(aBases[nBases,2] > nValMinRet,(aBases[nBases,5]+aBases[nBases,6])* (MV_PAR10/100),0)
								nCount++
							Else
								lImpSub := .F.
							EndIf
						EndIf
						
					Else
					   //===================================================================
					   // calculo das comissoes p/ pedido venda
					   //===================================================================	
						DBSelectArea("SC5")
						DBSetOrder(1)
						DBGoTo(Val(TRB->CHAVE))
						//======================================================================
						// Fecho os dados fiscais de um pedido antes de carregar um novo pedido
						//======================================================================
						MaFisEnd()
						//===================================================================
						// Inicializo a funcao fiscal
						//===================================================================
						MaFisIni(C5_CLIENTE,;// 1-Codigo Cliente/Fornecedor
									C5_LOJAENT,;		// 2-Loja do Cliente/Fornecedor
									IIf(C5_TIPO$'DB',"F","C"),;				// 3-C:Cliente , F:Fornecedor
									C5_TIPO,;				// 4-Tipo da NF
									C5_TIPOCLI,;		// 5-Tipo do Cliente/Fornecedor
									Nil,;
									Nil,;
									Nil,;
									Nil,;
									"MATA461")
			
						DBSelectArea("SC6")
						DBSetOrder(1)
						If DBSeek(xFilial("SC6")+SC5->C5_NUM)
							While !Eof() .And. SC6->C6_NUM == SC5->C5_NUM
								nRecOri := 0
								If !Empty(SC6->C6_NFORI) .And. !Empty(SC6->C6_ITEMORI)
									SD1->(DBSetOrder(1))
									If SD1->(MSSeek(xFilial("SD1")+SC6->C6_NFORI+SC6->C6_SERIORI+SC5->C5_CLIENTE+SC5->C5_LOJACLI+SC6->C6_PRODUTO+SC6->C6_ITEMORI))
										nRecOri := SD1->(Recno())
									EndIf
								EndIf
			
								MaFisAdd(C6_PRODUTO,;   	// 1-Codigo do Produto ( Obrigatorio )
									C6_TES,;	   	// 2-Codigo do TES ( Opcional )
									C6_QTDVEN,;  	// 3-Quantidade ( Obrigatorio )
									C6_PRCVEN,;		  	// 4-Preco Unitario ( Obrigatorio )
									a410Arred(C6_QTDVEN*C6_PRCVEN,"D2_DESCON")-C6_VALOR,; 	// 5-Valor do Desconto ( Opcional )
									"",;	   			// 6-Numero da NF Original ( Devolucao/Benef )
									"",;				// 7-Serie da NF Original ( Devolucao/Benef )
									nRecOri,;					// 8-RecNo da NF Original no arq SD1/SD2
									0,;					// 9-Valor do Frete do Item ( Opcional )
									0,;					// 10-Valor da Despesa do item ( Opcional )
									0,;					// 11-Valor do Seguro do item ( Opcional )
									0,;					// 12-Valor do Frete Autonomo ( Opcional )
									C6_VALOR ,;			// 13-Valor da Mercadoria ( Obrigatorio )
									0)					// 14-Valor da Embalagem ( Opiconal )
			
								SC6->(DBSkip())
							EndDo
						EndIf
						nComissao	:= 0
						nVlTotPed	:= 0
						DBSelectArea("SC6")
						DBSetOrder(1)
						If DBSeek(xFilial("SC6")+SC5->C5_NUM)
							aParcelas	:= {}
							nVendSC5		:= SC5->(FieldPos("C5_VEND"+Str(TRB->NVEND,1)))
							nComiSC5		:= SC5->(FieldPos("C5_COMIS"+Str(TRB->NVEND,1)))
							nComiSC6		:= SC6->(FieldPos("C6_COMIS"+Str(TRB->NVEND,1)))
							DBSelectArea("SA3")
							DBSeek(xFilial("SA3")+SC5->(FieldGet(nVendsc5)))
							nPerComE		:= (SA3->A3_ALEMISS/100)
							nPerComB		:= (SA3->A3_ALBAIXA/100)
							DBSelectArea("SC6")
							nRegSC6 := Recno()
							//===================================================================
							// valor de nao entregues total no pedido
							//===================================================================
							bAcao:= {|| nVlTotPed += SC6->(C6_PRCVEN * (C6_QTDVEN - C6_QTDENT))}
							DBEval(bAcao,,{||!Eof() .And. SC6->C6_NUM == SC5->C5_NUM},,,.T.)
							DBGoTo(nRegSC6)
							//===================================================================
							// Constituicao de aParcelas{}				                        |    
							// Coluna 01    Data Vencto da Parcela			                    |
							// Coluna 02    Valor da Parcela			                        |
							// Coluna 03    Valor Comissao Emissao		                        |
							// Coluna 04    Valor Comissao Baixa                                |
							// Coluna 05    Base da Baixa                                       |
							// Coluna 06    % Total da comissao                                 |
							//===================================================================
							aParcelas := Condicao (nVlTotPed,SC5->C5_CONDPAG,,SC5->C5_EMISSAO)
							aEval(aParcelas,{|elem| aAdd(elem,0),aAdd(elem,0),aAdd(elem,0),aAdd(elem,0),aAdd(elem,0)})
							DBSelectArea("SC6")
							nItem		:= 0
							nTotImp	:= 0
							While !Eof() .And. SC6->C6_NUM == SC5->C5_NUM
								nItem++
								If SC6->C6_QTDENT >= SC6->C6_QTDVEN .Or.;
									!Empty(SC6->C6_BLOQUEI)          .Or.;
									Left(SC6->C6_BLQ,1) $ "RS"
									DBSkip()
									Loop
								EndIf
								nQtdItem := SC6->(C6_QTDVEN - C6_QTDENT)  // Qtde nao entregue
								nBasItem := SC6->(C6_PRCVEN * nQtdItem) 	// Valor ref. nao entregue
			
								nIrrItem := 0
								nInsItem := 0
								nPisItem := 0
								nCofItem := 0
								nCslItem := 0
								nIcmItem := 0
								nIssItem := 0
								nSolItem := 0
			
								If SuperGetMv("MV_COMISIR") == "N"
									nIrrItem := MafisRet(nItem, "IT_VALIRR")
									nBasItem -= nIrrItem
								EndIf
								If GetNewPar("MV_COMIINS","N") == "N"
									nInsItem := MafisRet(nItem, "IT_VALINS")
									nBasItem -= nInsItem
								EndIf
								If GetNewPar("MV_COMIPIS","N") == "N"
									nPisItem := MafisRet(nItem, "IT_VALPIS")
									nBasItem -= nPisItem
								EndIf
								If GetNewPar("MV_COMICOF","N") == "N"
									nCofItem := MafisRet(nItem, "IT_VALCOF")
									nBasItem -= nCofItem
								EndIf
								If GetNewPar("MV_COMICSL","N") == "N"
									nCslItem := MafisRet(nItem, "IT_VALCSL")
									nBasItem -= nCslItem
								EndIf
			                    //=================================================================== 
								// Calcula abatimento de ISS e ICMS da base da comissao do vendedor
								//===================================================================
								SF4->(DBSetOrder(1))
								SF4->(MsSeek(xFilial("SF4")+SC6->C6_TES))
								If !(SF4->F4_ISS == "S")
									If ( SA3->A3_ICM == "N" )
										nIcmItem := MaFisRet(nItem, "IT_VALICM")
										nBasItem -= nIcmItem
									EndIf
								Else
									If ( SA3->A3_ISS == "N" )
										nIssItem := MaFisRet(nItem, "IT_VALISS")
										nBasItem -= nIssItem
									EndIf
								EndIf
								If ( SA3->A3_ICMSRET == "N" )
									nSolItem := MaFisRet(nItem, "IT_VALSOL")
									nBasItem -= nSolItem
								EndIf
			
								nPercItem:= IIf(SC6->(FieldGet(nComiSC6))== 0,;
													 SC5->(FieldGet(nComiSC5)),	 ;	// Percentual no Pedido
													 SC6->(FieldGet(nComiSC6)))		// Percentual no Item
								aParcItem:= Condicao(nBasItem,SC5->C5_CONDPAG,,SC5->C5_EMISSAO)

                                //===================================================================			
								// Valor dos impostos do pedido
								//===================================================================
								nTotImp := nIrrItem + nInsItem + nPisItem + nCofItem + nCslItem + nIcmItem + nIssItem + nSolItem
			
								DBSelectArea("SC6")
								For nCond := 1 to Len(aParcItem)
									aParcelas[nCond,3] += ((aParcItem[nCond,2] * (nPercItem/100)) * nPerComE)
									aParcelas[nCond,4] += ((aParcItem[nCond,2] * (nPercItem/100)) * nPerComB)
									aParcelas[nCond,5] += (aParcItem[nCond,2] * nPerComB)
									aParcelas[nCond,7] += (nTotImp / Len(aParcItem))
								Next
								DBSkip()
							EndDo
							For nCond := 1 to	Len(aParcelas)
								aParcelas[nCond,6] += (((aParcelas[nCond,3]+aParcelas[nCond,4]) * 100) / (aParcelas[nCond,2] - aParcelas[nCond,7]))
								nComissao += (aParcelas[nCond,3]+aParcelas[nCond,4])
							Next
		                    
		                    //===================================================================	
							// impressao das previsoes de comiss do ped venda
							//===================================================================
							If ( nComissao != 0 )
								If lFirst
									oReport:PrintText( PadR(STR0009 + TRB->CODIGO,16) + STR0010 + SA3->A3_NOME )
									oReport:SkipLine()
									DBSelectArea("TRB")
									lFirst := .F.
								EndIf
			
								DBSelectArea("SC5")
								DBSetOrder(1)
								DBGoTo(Val(TRB->CHAVE))
			
								If cPaisLoc == "BRA"
								   nMoedaBco := 1
								   dDataConv := dDataBase
								Else
								   nMoedaBco := SC5->C5_MOEDA
								   dDataConv := SC5->C5_EMISSAO
								EndIf
			
								For nCond := 1 to Len(aParcelas)
									If aParcelas[nCond,1] > MV_PAR03 .And.  ;
										aParcelas[nCond,1] < MV_PAR04
			
										aParcelas[nCond,2] := xMoeda(aParcelas[nCond,2],nMoedaBco,MV_PAR05,dDataConv,nDecs+1)
										aParcelas[nCond,3] := xMoeda(aParcelas[nCond,3],nMoedaBco,MV_PAR05,dDataConv,nDecs+1)
										aParcelas[nCond,4] := xMoeda(aParcelas[nCond,4],nMoedaBco,MV_PAR05,dDataConv,nDecs+1)
										aParcelas[nCond,5] := xMoeda(aParcelas[nCond,5],nMoedaBco,MV_PAR05,dDataConv,nDecs+1)
			
										aDados[TITULO]		:= C5_NUM
										aDados[PARCELA]	:= Str(nCond,3)
										aDados[COD_CLI]	:= C5_CLIENTE
										aDados[LOJA]		:= C5_LOJACLI
			
										DBSelectArea("SA1")
										DBSeek(cFilial+SC5->C5_CLIENTE+SC5->C5_LOJACLI)
										aDados[NOME_CLI]	:= If(MV_PAR13 == 1,SA1->A1_NREDUZ,SA1->A1_NOME)
										DBSelectArea("SC5")
			
										aDados[DT_EMIS]	:= C5_EMISSAO
										aDados[DT_VENC]	:= aParcelas[nCond,1]   //Vencto
										aDados[VAL_TIT]	:= aParcelas[nCond,2]
										aDados[COM_EMISS]	:= aParcelas[nCond,3]
										aDados[COM_BAIXA]	:= aParcelas[nCond,4]
										aDados[VAL_BASE]	:= aParcelas[nCond,5]
										aDados[PERC]		:= aParcelas[nCond,6]
										aDados[VAL_COMIS]	:= aParcelas[nCond,3]+aParcelas[nCond,4] //Total Comissao (Emissao+Baixa)
										aDados[PARC]		:= "P"     // identificador de Titulo ou Pedido
			
										oSection1:PrintLine()
										aFill(aDados,nil)
			
										nValTit		+= aParcelas[nCond,2]
										nComEnt		+= aParcelas[nCond,3]
										nIrEnt		+= If(aParcelas[nCond,2] > nValMinRet, aParcelas[nCond,3] * (MV_PAR10/100),0)
										nComVen		+= aParcelas[nCond,4]
										nIrVen		+= If(aParcelas[nCond,2] > nValMinRet, aParcelas[nCond,4] * (MV_PAR10/100),0)
										nValBas		+= aParcelas[nCond,5]
										nPorc			+= aParcelas[nCond,6]
										nVendComis	+= aParcelas[nCond,3]+aParcelas[nCond,4]
										nVendIr		+= If(aParcelas[nCond,2] > nValMinRet, aParcelas[nCond,3]+aParcelas[nCond,4] * (MV_PAR10/100),0)
										nCount++
									EndIf
								Next
							EndIf
						EndIf
					EndIf
			DBSelectArea("TRB")
			DBSkip()
		End
		nTotTit  +=nValTit
		nTotEnt  +=nComEnt
		nTotIrE  +=nIrEnt
		nTotVen  +=nComVen
		nTotIrB  +=nIrVen
		nTotBas  +=nValBas
		nTotComis+=nVendComis
		nTotIrVen+=nVendIr
		nTotPorc += nPorc
		nTotCount+= nCount
	
		If ((nVendComis <> 0 .Or. nTotCount > 0) .Or. MV_PAR08 == 1 ) .And. lImpSub
			RFIN0174(nValTit,nComEnt,nComVen,nValBas,nPorc,nVendComis,nIrEnt,nIrVen,nVendIr,nCount,oReport,aDados)
		EndIf
	
		nValTit		:= 0.00
		nComEnt		:= 0.00
		nIrEnt		:= 0.00
		nComVen		:= 0.00
		nIrVen		:= 0.00
		nValBas		:= 0.00
		nPorc 		:= 0
		nVendComis 	:= 0.00
		nVendIr		:= 0.00
	
		If MV_PAR12 == 1 // Salta Pagina por Vendedor? SIM/NAO
			oReport:EndPage()
		EndIf
EndDo

If nTotComis <> 0
	RFIN017T(nTotTit,nTotEnt,nTotVen,nTotBas,nTotComis,nTotIrE,nTotIrB,nTotIrVen,nTotPorc,nTotCount,oReport,aDados)
EndIf

//===================================================================
// Fecho os dados fiscais de um pedido
//===================================================================
MaFisEnd()

oSection1:Finish()

DBSelectArea("Trb")
TRB->(DBCloseArea())

DBSelectArea("SE3")
DBSetOrder(1)
DBSelectArea("SE1")
DBSetOrder(1)
dbClearFilter()
cFilAnt	:= cFilBack

Return

/*
===============================================================================================================================
Programa----------: RFIN0174()
Autor-------------: Daniel Batori
Data da Criacao---: 28.08.06
Descrição---------: Imprime Sub-Total
Parametros--------: nValTit
                    nComEnt
                    nComVen
                    nValBas
                    nPorc
                    nVendComis
                    nIrEnt
                    nIrVen
                    nVendIr
                    nCount
                    oReport
                    aDados
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RFIN0174(nValTit,nComEnt,nComVen,nValBas,nPorc,nVendComis,nIrEnt,nIrVen,nVendIr,nCount,oReport,aDados)
Local oSection1 := oReport:Section(1)

oReport:SkipLine()

If MV_PAR10 > 0  // Aliquota IRRF
	aDados[NOME_CLI]	:= STR0013  //"SUBTOTAL DO VENDEDOR --->"
	aDados[VAL_TIT]	:= nValTit
	aDados[COM_EMISS]	:= nComEnt
	aDados[COM_BAIXA]	:= nComVen
	aDados[VAL_BASE]	:= nValBas
	aDados[PERC]		:= ""
	aDados[VAL_COMIS]	:= nVendComis

	oSection1:PrintLine()
	aFill(aDados,nil)

	aDados[NOME_CLI]	:= STR0014  //"TOTAL IR VENDEDOR    --->"
	aDados[COM_EMISS]	:= nIrEnt
	aDados[COM_BAIXA]	:= nIrVen
	aDados[PERC]		:= ""
	aDados[VAL_COMIS]	:= nVendIr

	oSection1:PrintLine()
	aFill(aDados,nil)

	aDados[NOME_CLI]	:= STR0011 // "TOTAL DO VENDEDOR    --->"
	aDados[VAL_TIT]	:= nValTit
	aDados[COM_EMISS]	:= nComEnt
	aDados[COM_BAIXA]	:= nComVen - nIrVen
	aDados[VAL_BASE]	:= nValBas
	aDados[PERC]		:= ""
	aDados[VAL_COMIS]	:= nVendComis - nVendiR
	oSection1:PrintLine()
	aFill(aDados,nil)

Else

	aDados[NOME_CLI]	:= STR0011 // "TOTAL DO VENDEDOR    --->"
	aDados[VAL_TIT]	:= nValTit
	aDados[COM_EMISS]	:= nComEnt
	aDados[COM_BAIXA]	:= nComVen
	aDados[VAL_BASE]	:= nValBas
	aDados[PERC]		:= ""
	aDados[VAL_COMIS]	:= nVendComis


	oSection1:PrintLine()
	aFill(aDados,nil)
EndIf

oReport:SkipLine()

Return .T.

/*
===============================================================================================================================
Programa----------: RFIN017T()
Autor-------------: Paulo Boschetti
Data da Criacao---: 30.08.06
Descrição---------: Imprime Total de comissões.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RFIN017T(nTotTit,nTotEnt,nTotVen,nTotBas,nTotComis,nTotIrE,nTotIrB,nTotIrVen,nTotPorc,nTotCount,oReport,aDados)
Local oSection1 := oReport:Section(1)

oReport:SkipLine()

If MV_PAR10 > 0  // Aliquota IRRF

	aDados[NOME_CLI]	:= STR0015   //"SUBTOTAL GERAL    --->"
	aDados[VAL_TIT]	:= nTotTit
	aDados[COM_EMISS]	:= nTotEnt
	aDados[COM_BAIXA]	:= nTotVen
	aDados[VAL_BASE]	:= nTotBas
	aDados[PERC]		:= ""
	aDados[VAL_COMIS]	:= nTotComis

	oSection1:PrintLine()
	aFill(aDados,nil)

	aDados[NOME_CLI]	:= STR0016  //"TOTAL GERAL IR    --->"
	aDados[COM_EMISS]	:= nTotIrE
	aDados[COM_BAIXA]	:= nTotIrB
	aDados[PERC]		:= ""
	aDados[VAL_COMIS]	:= nTotIrVen

	oSection1:PrintLine()
	aFill(aDados,nil)

	aDados[NOME_CLI]	:= STR0012  //"TOTAL  GERAL         --->"
	aDados[VAL_TIT]	:= nTotTit
	aDados[COM_EMISS]	:= nTotEnt
	aDados[COM_BAIXA]	:= nTotVen - nTotIrB
	aDados[VAL_BASE]	:= nTotBas
	aDados[PERC]		:= ""
	aDados[VAL_COMIS]	:= nTotComis - nTotIrVen

	oSection1:PrintLine()
	aFill(aDados,nil)

Else
	aDados[NOME_CLI]	:= STR0012  //"TOTAL  GERAL         --->"
	aDados[VAL_TIT]	:= nTotTit
	aDados[COM_EMISS]	:= nTotEnt
	aDados[COM_BAIXA]	:= nTotVen
	aDados[VAL_BASE]	:= nTotBas
	aDados[PERC]		:= ""
	aDados[VAL_COMIS]	:= nTotComis

	oSection1:PrintLine()
	aFill(aDados,nil)

EndIf

oReport:SkipLine()

Return .T.

/*
===============================================================================================================================
Programa----------: FA610ComPg()
Autor-------------: Mauricio Pequim jr 
Data da Criacao---: 30.08.06
Descrição---------: Verifica comissoes já pagas.
Parametros--------: aBases
                    cChaveSE3
                    nBases
                    cTipo
                    cParcela
                    nValorFat
                    nBaseCom
                    nComissao
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function FA610ComPg(aBases,cChaveSE3,nBases,cTipo,cParcela,nValorFat,nBaseCom,nComissao)
Local nPercBase := 0
Local nPercEst

DEFAULT cTipo    := SE1->E1_TIPO
DEFAULT cParcela := SE1->E1_PARCELA
//===================================================================
// Caso percentual de comissao seja retornado == a zero, devo   
// calcular a media (Faturamento com comissao no item <> percen-
// tual do vendedor)                                            
//===================================================================
If aBases[nBases,7] == 0
	aBases[nBases,7] := (((aBases[nBases,5]+aBases[nBases,6])*100)/aBases[nBases,2])
EndIf

DBSelectArea("SE3")
DBSetOrder(3)
If DBSeek(xFilial("SE3")+cChaveSE3)
	While !Eof() .And. xFilial("SE3")== SE3->E3_FILIAL .and.;
		SE3->E3_VEND+SE3->E3_CODCLI+SE3->E3_LOJA+SE3->E3_PREFIXO+SE3->E3_NUM == cChaveSE3

		nPercEst	:= Abs(SE3->E3_BASE / nValorFat)
		   
	   If SE3->E3_BAIEMI == "E" .And. Empty(SE3->E3_DATA) 
           If SE3->E3_COMIS < 0
				aBases[nBases,3] += SE3->E3_BASE
				aBases[nBases,5] += SE3->E3_COMIS
			Else
				If aBases[nBases,3] > 0 .And. SE3->E3_BASE <> aBases[nBases,3]
					nPercBase:= Round(NoRound((aBases[nBases,3] * 100) / SE3->E3_BASE, 3),2)
				Else
					nPercBase:= 100
				EndIf
				aBases[nBases,3] -= Round(NoRound(SE3->E3_BASE  * (nPercBase/100) ,3),2)
				aBases[nBases,5] += Round(NoRound(SE3->E3_COMIS * (nPercBase/100) ,3),2)
			EndIf
  		ElseIf !Empty(SE3->E3_DATA)
			If SE3->E3_BAIEMI == "B" .And. cTIPO+cPARCELA == SE3->E3_TIPO+SE3->E3_PARCELA .And. SE3->E3_COMIS > 0
				aBases[nBases,4] -= (nBaseCom*nPercEst)
				aBases[nBases,6] -= (nComissao*nPercEst)
			ElseIf SE3->E3_BAIEMI == "B" .And. cTIPO+cPARCELA == SE3->E3_TIPO+SE3->E3_PARCELA .And. SE3->E3_COMIS < 0
				aBases[nBases,4] += (nBaseCom*nPercEst)
				aBases[nBases,6] += (nComissao*nPercEst)
			EndIf
		EndIf
		SE3->(DBSkip())
	EndDo
EndIf
Return

/*
===============================================================================================================================
Programa----------: Vendedor610()
Autor-------------: Marcelo Celi Marques
Data da Criacao---: 18/03/09
Descrição---------: Complemento a função TitPrinc para retorno da array de vendedores com dados de comissão de 
                    titulos principais.
Parametros--------: cAliasSe1
                    nIndexSE5
Retorno-----------: aVend610
===============================================================================================================================
*/
Static Function Vendedor610(cAliasSe1,nIndexSE5)
Local aAreaSe1 := FWGetArea()
Local aVend610	:= {{},{},{},{}}

TitPrinc(xFilial(cAliasSe1),(cAliasSe1)->e1_PREFIXO,(cAliasSe1)->e1_NUM,(cAliasSe1)->e1_PARCELA,(cAliasSe1)->e1_TIPO,"SE1",@aVend610,nIndexSE5)

FWRestArea(aAreaSe1)

Return aVend610

/*
===============================================================================================================================
Programa----------: Fr610ProcF()
Autor-------------: Marcelo Celi Marques
Data da Criacao---: 23/03/09
Descrição---------: Trata o abastecimento do TRB a partir dos títulos filhos.
Parametros--------: oReport
                    lEnd
                    aSelFil
Retorno-----------: Nenhum.
===============================================================================================================================
*/
Static Function Fr610ProcF(oReport,lEnd, aSelFil)
Local JX
Local nVendTit
Local nRecPrinc, nx1, ny1
// Se a comissão será definida na liquidação ou na baixa (1 = Liq, 2 = Baixa)
Local lComiLiq 	:= SuperGetMv("MV_COMILIQ",,"1") == "2"
Local nFilial	:= 0
Local cFilBack	:= cFilAnt
Local cFilSE1	:= ""
Local lFirstSE1	:= .T.
Local _cFilProc
Local _nRegSM0 := SM0->(Recno())
Local _cCodEmp := FWCodEmp()
Local lPVen := .F.		// Flag diferenciador de pedido de venda

Default oReport := .F.
Default lEnd := .F.
Default aSelFil	:= { cFilAnt }

For nFilial := 1 to Len(aSelFil)
	cFilAnt	:= aSelFil[nFilial]
	cFilSE1	:= cFilAnt // xFilial('SE1')
    _cFilProc :=  aSelFil[nFilial]
    
    SM0->(DBSeek( _cCodEmp + _cFilProc))
    
	If Empty(cFilSE1) .And. !lFirstSE1
		Loop	
	ElseIf Empty(cFilSE1)
		lFirstSE1	:= .F.	
	EndIf
	
	DBSeek(_cFilProc+DToS(MV_PAR03),.T.) // DBSeek(xFilial("SE1")+DToS(MV_PAR03),.T.)	
		
	While SE1->(!Eof()) .And. _cFilProc == SE1->E1_FILIAL .And. SE1->E1_VENCREA <= MV_PAR04  //  While SE1->(!Eof()) .And. xFilial("SE1") == SE1->E1_FILIAL .And. SE1->E1_VENCREA <= MV_PAR04
		lPVen := .F.
	
		If ValType(oReport) <> "L"
		   //===================================================================
		   // chamado pelo r4
		   //===================================================================
			oReport:IncMeter()
		Else
		   //===================================================================
		   // chamado pelo r3
		   //===================================================================
			If lEnd
				@PROW()+1,001 PSAY STR0008 // "CANCELADO PELO OPERADOR"
				Exit
			EndIf
			IncRegua()
		EndIf
	
		If E1_TIPO $ MVABATIM
			DBSkip()
			Loop
		EndIf
	
		If E1_EMISSAO < MV_PAR06 .Or. E1_EMISSAO > MV_PAR07
			DBSkip()
			Loop
		EndIf
	    //===================================================================
		// Despreza registros de outra moeda se escolhido nao imprimir
		//===================================================================
		If MV_PAR11 == 2 .And. E1_MOEDA != MV_PAR05
			DBSkip()
			Loop
		EndIf
	    
	    //=====================================================================
		// Se título For uma liquidação e a comissão será gerada na liquidação
		//=====================================================================
		If !Empty(E1_NUMLIQ) .And. !lComiLiq
			DBSkip()
			Loop
		EndIf
	
		aVendedor := Vendedor610("SE1",nIndexSE5)
	
		For nVendTit := 1 to Len(aVendedor[1])
			For JX:=1 TO 5
				nx := Str(JX,1)
				cVendedor := aVendedor[1][nVendTit][JX]
				If !Empty(cVendedor)
	
					// Descobrir o Recno() do titulo principal
					For nx1 := 1 to Len(aVendedor[1])
						nPos := aScan(aVendedor[1],{|x| x[nx1] == cVendedor})
						If nPos > 0
						   nx1 := Len(aVendedor[1])+1
						   DBSelectArea("SE1")
						   aAreaSE1 := FWGetArea()
						   DBSetOrder(1)
						   If DBSeek(aVendedor[4][nPos])
						      nRecPrinc := 0
						      For ny1 := 1 to 5
						      	If aVendedor[1][nPos][ny1] == cVendedor
						      	   nRecPrinc := SE1->(Recno())
						      	EndIf
						      Next
						   EndIf
						   FWRestArea(aAreaSE1)
						EndIf
					Next
	
					If cVendedor >= MV_PAR01 .And. cVendedor <= MV_PAR02
						If !Empty(SE1->E1_FATURA) .And. (AllTrim(SE1->E1_FATURA) <> "NOTFAT")
							aAreaSE1 := FWGetArea()
							cCliente := E1_CLIENTE  //Declarar variaveis
							cLoja    := E1_LOJA
							cFatura  := E1_FATURA
							cFatPref := E1_FATPREF
							nChvFat  := SE1->(Recno())
							SE1->(DBSetOrder(1))
							SE1->(DBGoTop())
							
							cChaveSE1 := _cFilProc + cFatPref + cFatura  // cChaveSE1 := xFilial("SE1") + cFatPref + cFatura
							
							SE1->(DBSeek(cChaveSE1))
							While(cChaveSE1 == SE1->(E1_FILIAL + E1_PREFIXO + E1_NUM)) // While(cChaveSE1 == xFilial("SE1") + E1_PREFIXO + E1_NUM)
								If SE1->E1_VENCREA >= MV_PAR03 .And. SE1->E1_VENCREA <= MV_PAR04
									If AllTrim(E1_FATURA) == "NOTFAT" .And. E1_SALDO > 0
										GravaCom(nX,lPVen,nChvFat,cVendedor,nRecPrinc, _cFilProc)
				  					EndIf
				  				EndIf
				  				DBSkip()
							EndDo
							FWRestArea(aAreaSE1)
						Else
							GravaCom(nX,lPVen,,cVendedor,nRecPrinc, _cFilProc)
						EndIf
					EndIf
				EndIf
			Next
		Next
		SE1->(DBSkip())
	EndDo
	
	//===================================================================
	// Verifica se considera pedidos de venda                       
	//===================================================================
	If MV_PAR09 == 1  // Considera Ped. Venda
		
		cFilAnt	:= aSelFil[nFilial]
		
		lPVen := .T.
		DBSelectArea("SC5")
		DBSetOrder(2)
	
		If ValType(oReport) <> "L"
			oReport:SetMeter(SC5->(RecCount()))
		EndIf
	
		DBSeek(_cFilProc + DToS(MV_PAR03),.T.)  // cFilial
		While !Eof() .And. _cFilProc == C5_FILIAL .And. C5_EMISSAO <= MV_PAR04 // While !Eof() .And. cFilial == C5_FILIAL .And. C5_EMISSAO <= MV_PAR04
	
			If ValType(oReport) <> "L"
			   //=================================================================== 
			   // chamado pelo r4
			   //===================================================================	
				oReport:IncMeter()
			Else
			   //===================================================================
			   // chamado pelo R3
			   //===================================================================	
				If lEnd
					@PROW()+1,001 PSAY STR0008 // "CANCELADO PELO OPERADOR"
					Exit
				EndIf
				IncRegua()
			EndIf
	
			If C5_EMISSAO < MV_PAR06 .Or. C5_EMISSAO > MV_PAR07
				DBSkip()
				Loop
			EndIf
		
			If C5_VEND1 >= MV_PAR01 .And. C5_VEND1 <= MV_PAR02
				GravaCom("1",lPVen,  ,  ,  , _cFilProc)
			EndIf

			If C5_VEND2 >= MV_PAR01 .And. C5_VEND2 <= MV_PAR02
				GravaCom("2",lPVen,  ,  ,  , _cFilProc)
			EndIf

			If C5_VEND3 >= MV_PAR01 .And. C5_VEND3 <= MV_PAR02
				GravaCom("3",lPVen,  ,  ,  , _cFilProc)
			EndIf

			If C5_VEND4 >= MV_PAR01 .And. C5_VEND4 <= MV_PAR02
				GravaCom("4",lPVen,  ,  ,  , _cFilProc)
			EndIf

			If C5_VEND5 >= MV_PAR01 .And. C5_VEND5 <= MV_PAR02
				GravaCom("5",lPVen,  ,  ,  , _cFilProc)
			EndIf

			DBSkip()
		EndDo
	EndIf
Next

SM0->(DBGoTo(_nRegSM0))
cFilAnt	:= cFilBack

Return

/*
===============================================================================================================================
Programa----------: Fr610ProcP()
Autor-------------: Marcelo Celi Marques
Data da Criacao---: 23/03/09
Descrição---------: Trata o abastecimento do TRB a partir dos títulos filhos.
Parametros--------: oReport
                    lEnd
                    aSelFil
Retorno-----------: Nenhum.
===============================================================================================================================
*/
Static Function Fr610ProcP(oReport,lEnd, aSelFil)
Local JX
Local nJ
//============================================================================
// Se a comissão será definida na liquidação ou na baixa (1 = Liq, 2 = Baixa)
//============================================================================
Local lComiLiq 	:= SuperGetMv("MV_COMILIQ",,"1") == "2"
Local aTitulos := {}
Local lLiqui	 := .F.
Local cNumLiq  := ""
Local nFilial	:= 0
Local cFilSE1	:= ""
Local cFilBack	:= cFilAnt
Local lFirstSE1	:= .T.
Local _cFilProc
Local _nRegSM0 := SM0->(Recno())
Local _cCodEmp := FWCodEmp()

Default oReport := .F.
Default lEnd := .F.
Default aSelFil	:= { cFilAnt }

For nFilial := 1 to Len(aSelFil)
	cFilAnt	:= aSelFil[nFilial]
	cFilSE1	:= cFilAnt //xFilial('SE1')
	_cFilProc := aSelFil[nFilial]
	
	SM0->(DBSeek( _cCodEmp + _cFilProc))
	
	If (Empty(cFilSE1) .And. lFirstSE1) .Or. !Empty(cFilSE1)
		lFirstSE1	:= .F.	
		//DBSeek(xFilial("SE1")+DToS(MV_PAR03),.T.)
		DBSeek(_cFilProc+DToS(MV_PAR03),.T.)
		
		While SE1->(!Eof()) .And. _cFilProc == SE1->E1_FILIAL .And. SE1->E1_VENCREA <= MV_PAR04 // While SE1->(!Eof()) .And. xFilial("SE1") == SE1->E1_FILIAL .And. SE1->E1_VENCREA <= MV_PAR04		
		    //===================================================================
			// Reposiciona filial para casos de compartilhamento do SE1
			//===================================================================
			cFilAnt	:= If(!Empty(SE1->E1_FILORIG),SE1->E1_FILORIG,cFilAnt)
					
			DBSelectArea("SE1")
			lPVen := .F.
			lLiqui := .F.
			aTitulos := {}
		
			If ValType(oReport) <> "L"
				// chamado pelo r4
				oReport:IncMeter()
			Else
				// chamado pelo r3
				If lEnd
					@PROW()+1,001 PSAY STR0008 // "CANCELADO PELO OPERADOR"
					Exit
				EndIf
				IncRegua()
			EndIf
		
			If E1_TIPO $ MVABATIM
				DBSkip()
				Loop
			EndIf
		
			nRecSe1 	:= SE1->(Recno())

			DBSelectArea("SE1")
		
			If SE1->E1_EMISSAO < MV_PAR06 .Or. SE1->E1_EMISSAO > MV_PAR07
				SE1->(DBSkip())
				Loop
			EndIf
	        
	        //===================================================================	
			// Despreza registros de outra moeda se escolhido nao imprimir
			//===================================================================
			If MV_PAR11 == 2 .And. SE1->E1_MOEDA != MV_PAR05
				SE1->(DBSkip())
				Loop
			EndIf
		
			nRecSe1 	:= SE1->(Recno())
			aArea       := FWGetArea()
			If SE1->E1_SALDO > 0
				DBSelectArea("SE5")
				DBSetOrder(10)
				If !Empty(SE1->E1_NUMLIQ) .And. DBSeek(_cFilProc+SE1->E1_NUMLIQ) // DBSeek(xFilial("SE5")+SE1->E1_NUMLIQ)
					lLiqui := .T.
					cNumLiq := SE1->E1_NUMLIQ
					DBSelectArea("SE1")
					SE1->(DBSetOrder(1))
					//===================================================================
					// Busca os titulos origens da liquidacao
					//===================================================================
					While SE5->(!Eof()) .And. _cFilProc == SE5->E5_FILIAL .And. SubStr(SE5->E5_DOCUMEN,1,Len(cNumLiq)) == cNumLiq // While SE5->(!Eof()) .And. xFilial("SE5") == SE5->E5_FILIAL .And. SubStr(SE5->E5_DOCUMEN,1,Len(cNumLiq)) == cNumLiq
						If SE5->E5_MOTBX = 'LIQ' .And. SE5->E5_SITUACA != "C" .And.  SE5->E5_TIPODOC == "BA"
							If ! SE1->(DBSeek(_cFilProc+SE5->E5_PREFIXO+SE5->E5_NUMERO+SE5->E5_PARCELA+SE5->E5_TIPO)) // If ! SE1->(DBSeek(xFilial("SE1")+SE5->E5_PREFIXO+SE5->E5_NUMERO+SE5->E5_PARCELA+SE5->E5_TIPO))
							   SE1->(DBGoTo(nRecSe1))
							   aAdd(aTitulos, nRecSe1)
							Else
								aAdd(aTitulos, SE1->(Recno()))
							EndIf
						EndIf
						SE5->(DBSkip())
					EndDo
				EndIf
			EndIf
			DBSelectArea("SE1")
			nRecSe1Pr	:= SE1->(Recno())
		
			SE1->(DBGoTo(nRecSe1Pr))
			If "NOTFAT" $ SE1->E1_FATURA .And. Empty(AllTrim((E1_VEND1+E1_VEND2+E1_VEND3+E1_VEND4+E1_VEND5))) .And. SE1->E1_SALDO == 0
			   cQuery := "SELECT * FROM " + RetSqlName("SE5") + " WHERE E5_FILIAL = '" + SE1->E1_FILIAL + "' AND "
			   cQuery += "E5_FATURA = '" + SE1->E1_NUM + "' AND "
			   cQuery += "D_E_L_E_T_=' ' "
			   cQuery := ChangeQuery(cQuery)
			   DBSelectArea("SE5")
			   DBCloseArea()
			   dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery),"SE5",.F., .T.)
		
			   DBSelectArea("SE1")
			   DBSetOrder(1)
			   If (!Empty(SE5->E5_FATURA) .And. !("NOTFAT" $ SE5->E5_FATURA)) .And. DBSeek(_cFilProc+SE5->E5_PREFIXO+SE5->E5_NUMERO+SE5->E5_PARCELA+SE5->E5_TIPO) // DBSeek(xFilial("SE1")+SE5->E5_PREFIXO+SE5->E5_NUMERO+SE5->E5_PARCELA+SE5->E5_TIPO)
				  nRecSe1Pr := Recno()
			   Else
				  nRecSe1Pr := nRecSe1
			   EndIf
			   
			   DBSelectArea("SE5")
			   DBCloseArea()
			   ChKFile("SE5")
			   DBSelectArea("SE5")
			   DBSetOrder(1)

			ElseIf !Empty(SE1->E1_FATURA) .And. Empty(AllTrim((E1_VEND1+E1_VEND2+E1_VEND3+E1_VEND4+E1_VEND5))) .And. SE1->E1_SALDO == 0
		
			    DBSelectArea("SE3")
			    DBSetOrder(1)
			    If DBSeek(_cFilProc+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA) // DBSeek(xFilial("SE3")+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA)
					DBSelectArea("SE1")
					FWRestArea(aArea)
					SE1->(DBSkip())
			    	Loop
			    EndIf
		
			    DBSelectArea("SE5")
			    DBSetOrder(10)
				If !Empty(SE1->E1_NUMLIQ) .And. DBSeek(_cFilProc+SE1->E1_NUMLIQ) // DBSeek(xFilial("SE5")+SE1->E1_NUMLIQ)
			    	DBSelectArea("SE1")
			    	DBSetOrder(1)
				    If ! DBSeek(_cFilProc+SE5->E5_PREFIXO+SE5->E5_NUMERO+SE5->E5_PARCELA+SE5->E5_TIPO) // DBSeek(xFilial("SE1")+SE5->E5_PREFIXO+SE5->E5_NUMERO+SE5->E5_PARCELA+SE5->E5_TIPO)
					   SE1->(DBGoTo(nRecSe1))
					EndIf
				EndIf
				DBSelectArea("SE1")
				nRecSe1Pr	:= SE1->(Recno())
			EndIf
			If !lLiqui
				aAdd(aTitulos, nRecSe1Pr)
			EndIf
		
			FWRestArea(aArea)
		
			For nJ := 1 To Len(aTitulos)
		
				For JX:=1 TO 5
					nx := Str(JX,1)
		
					DBSelectArea("SE1")
					SE1->(DBGoTo(aTitulos[nJ]))
		
					If  (Jx==1 .And. !Empty(E1_VEND1)) .OR.;
						(Jx==2 .And. !Empty(E1_VEND2)) .OR.;
						(Jx==3 .And. !Empty(E1_VEND3)) .OR.;
						(Jx==4 .And. !Empty(E1_VEND4)) .OR.;
						(Jx==5 .And. !Empty(E1_VEND5)) 
					
						If (Jx==1 .And. E1_VEND1 >= MV_PAR01 .And. E1_VEND1 <= MV_PAR02) .OR.;
							(Jx==2 .And. E1_VEND2 >= MV_PAR02 .And. E1_VEND2 <= MV_PAR03) .OR.;
							(Jx==3 .And. E1_VEND3 >= MV_PAR02 .And. E1_VEND3 <= MV_PAR03) .OR.;
							(Jx==4 .And. E1_VEND4 >= MV_PAR02 .And. E1_VEND4 <= MV_PAR03) .OR.;
							(Jx==5 .And. E1_VEND5 >= MV_PAR02 .And. E1_VEND5 <= MV_PAR03)
		
							cVend    := E1_VEND&nx
							If !lLiqui
								FWRestArea(aArea)
							EndIf
		
							If !Empty(SE1->E1_FATURA) .And. (AllTrim(SE1->E1_FATURA) <> "NOTFAT")
								aAreaSE1 := FWGetArea()
								cCliente := E1_CLIENTE  //Declarar variaveis
								cLoja    := E1_LOJA
								cFatura  := E1_FATURA
								cFatPref := E1_FATPREF
								cLiquid  := "/"
								nChvFat  := SE1->(Recno())
								SE1->(DBSetOrder(1))
								SE1->(DBGoTop())
								cChaveSE1 := _cFilProc + cFatPref + cFatura // xFilial("SE1") + cFatPref + cFatura
								SE1->(DBSeek(cChaveSE1))
		
								While((cChaveSE1 == _cFilProc + E1_PREFIXO + E1_NUM))  // xFilial("SE1") + E1_PREFIXO + E1_NUM))
		
										If AllTrim(E1_FATURA) == "NOTFAT" .And. SE1->E1_SALDO > 0 .And. (If(!lComiLiq,If(Empty(E1_NUMLIQ),.T.,.F.),.T.))
										   	GravaCom(nX,lPVen,nChvFat,cVend,nRecSe1Pr, _cFilProc)
					  					ElseIf AllTrim(E1_FATURA) == "NOTFAT" .And. SE1->E1_SALDO == 0 .And. !Empty(SE1->E1_TIPOLIQ)
					  						DBSelectArea("SE5")
					  						DBSetOrder(7)
					  						If DBSeek(_cFilProc+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+SE1->E1_TIPO+SE1->E1_CLIENTE) // DBSeek(xFilial("SE5")+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+SE1->E1_TIPO+SE1->E1_CLIENTE)
					  							nRegSE1 := SE1->(Recno())
					  							DBSelectArea("SE1")
					  							DBSetOrder(15)
					  							DBSeek(_cFilProc+SE5->E5_DOCUMEN) // DBSeek(xFilial("SE1")+SE5->E5_DOCUMEN)
					  							cChaveLiq := SE1->E1_FILIAL+SE1->E1_NUMLIQ
					  							While cChaveLiq == SE1->E1_FILIAL+SE1->E1_NUMLIQ .And. !Eof()
					  								If SE1->E1_SALDO > 0 .And. (If(!lComiLiq,If(Empty(E1_NUMLIQ),.T.,.F.),.T.))
					  									GravaCom(nX,lPVen,nChvFat,cVend,nRecSe1Pr,_cFilProc)
					  								EndIf
					  								DBSkip()
					  							EndDo
					  							SE1->(DBGoTo(nRegSE1))
					  							DBSetOrder(1)
					  						EndIf
					  						DBSelectArea("SE1")
					  					EndIf
		
					  				DBSkip()
								EndDo
		
								FWRestArea(aAreaSE1)
							Else
								If (lComiLiq .Or. ( !lComiLiq .And. Empty(E1_NUMLIQ) ))
									If ( AllTrim(SE1->E1_FATURA) <> "NOTFAT"   .And. SE1->E1_SALDO > 0) .Or. (lLiqui .And. SE1->E1_SALDO == 0)
									    //===================================================================
										// VERIFICAR SE DATA VENCTO ESTA NO RANGE DE/ATE
										//===================================================================
										If SE1->E1_VENCREA >= MV_PAR03 .And. SE1->E1_VENCREA <= MV_PAR04
											GravaCom(nX,lPVen,,cVend,nRecSe1Pr, _cFilProc)
										EndIf
									Else
										aAreaSE1 := FWGetArea()
										DBSelectArea("SE3")
										DBSetOrder(1)
										If DBSeek(_cFilProc+SE1->(E1_PREFIXO+E1_NUM+E1_PARCELA))  // DBSeek(xFilial("SE1")+SE1->(E1_PREFIXO+E1_NUM+E1_PARCELA))
											While SE3->(E3_FILIAL+E3_PREFIXO+E3_NUM+E3_PARCELA) == _cFilProc+SE1->(E1_PREFIXO+E1_NUM+E1_PARCELA) // xFilial("SE1")+SE1->(E1_PREFIXO+E1_NUM+E1_PARCELA)
											    //===================================================================
												// VERIFICAR SE DATA VENCTO ESTA NO RANGE DE/ATE
												//===================================================================
												If SE1->E1_VENCREA >= MV_PAR03 .And. SE1->E1_VENCREA <= MV_PAR04
												   //=================================================================== 
												   // VERIFICAR SE E3_DATA ESTA PREENCHIDO
												   //===================================================================	
											       	If Empty(E3_DATA)
											       		FWRestArea(aAreaSE1)
														GravaCom(nX,lPVen,,cVend,nRecSe1Pr, _cFilProc)
													EndIf
												EndIf
												SE3->(DBSkip())
											EndDo
										EndIf
									EndIf
								EndIf
							EndIf
						EndIf
					EndIf
				Next nX
			Next nJ
			FWRestArea(aArea)
			SE1->(DBSkip())
		EndDo
	EndIf
	
	//===================================================================
	// Verifica se considera pedidos de venda                       
	//===================================================================
	If MV_PAR09 == 1  // Considera Ped. Venda
		
		cFilAnt	:= aSelFil[nFilial]
		
		lPVen := .T.
		DBSelectArea("SC5")
		DBSetOrder(2)
	
		If ValType(oReport) <> "L"
			oReport:SetMeter(SC5->(RecCount()))
		EndIf
	
		DBSeek(_cFilProc+DToS(MV_PAR03),.T.)  // cFilial
		While !Eof() .And. _cFilProc == C5_FILIAL .And. C5_EMISSAO <= MV_PAR04 // While !Eof() .And. cFilial == C5_FILIAL .And. C5_EMISSAO <= MV_PAR04
	
			If ValType(oReport) <> "L"
			   //===================================================================
			   // chamado pelo r4
			   //===================================================================
				oReport:IncMeter()
			Else
			   //===================================================================
			   // chamado pelo R3
			   //===================================================================
				If lEnd
					@PROW()+1,001 PSAY STR0008 // "CANCELADO PELO OPERADOR"
					Exit
				EndIf
				IncRegua()
			EndIf
	
			If C5_EMISSAO < MV_PAR06 .Or. C5_EMISSAO > MV_PAR07
				DBSkip()
				Loop
			EndIf
		
			If !Empty(C5_VEND1)
				If C5_VEND1 >= MV_PAR01 .And. C5_VEND1 <= MV_PAR02
					GravaCom('1',lPVen,   ,   ,  , _cFilProc)
				End
			End
			If !Empty(C5_VEND2)
				If C5_VEND2 >= MV_PAR01 .And. C5_VEND2 <= MV_PAR02
					GravaCom('2',lPVen,   ,   ,  , _cFilProc)
				End
			End
			If !Empty(C5_VEND3)
				If C5_VEND3 >= MV_PAR01 .And. C5_VEND3 <= MV_PAR02
					GravaCom('3',lPVen,   ,   ,  , _cFilProc)
				End
			End
			If !Empty(C5_VEND4)
				If C5_VEND4 >= MV_PAR01 .And. C5_VEND4 <= MV_PAR02
					GravaCom('4',lPVen,   ,   ,  , _cFilProc)
				End
			End
			If !Empty(C5_VEND5)
				If C5_VEND5 >= MV_PAR01 .And. C5_VEND5 <= MV_PAR02
					GravaCom('5',lPVen,   ,   ,  , _cFilProc)
				End
			End
			
			DBSkip()
		EndDo
	EndIf
Next

SM0->(DBGoTo(_nRegSM0))
cFilAnt := cFilBack

Return

/*
===============================================================================================================================
Programa----------: IsFatura()
Autor-------------: Totvs
Data da Criacao---: 23/03/09
Descrição---------: Retorna se o titulo posicionado é fatura.
Parametros--------: Nenhum.
Retorno-----------: .T. / .F.
===============================================================================================================================
*/
Static Function IsFatura()
Local lFatura	 := ( AllTrim(SE1->E1_FATURA)=="NOTFAT")

Return(lFatura)

/*
===============================================================================================================================
Programa----------: ComissFat()
Autor-------------: Totvs
Data da Criacao---: 03/08/12 
Descrição---------: Retorna um array com 2 elementeos com as comissoes e valor da fatura Estrutura do Array :
                    Posicao 1 := array contendo as comissoes de todos os titulos constante na fatura - Fa440Comis().
                            2 := Valor da Fatura.
Parametros--------: cFatura
Retorno-----------: { aBases, nVlrFatur } = Posicao 1 := array contendo as comissoes de todos os titulos constante na fatura - Fa440Comis().
                                                    2 := Valor da Fatura.
===============================================================================================================================
*/
Static Function ComissFat(cFatura)
Local nVlrFatur := 0
Local aFatura   := {}
Local nQtdVend, cVend, nPosVend, nCntFor
Local nDecimal  	:= TamSX3("E1_BASCOM1")[2]
Local aArea 	:= FWGetArea()
Local aAreaSE1 	:= SE1->(GetArea())
Local aBases 	:= {}
DBSelectArea("SE1")
DBSetOrder(10)
MsSeek(xFilial("SE1")+cFatura,.F.)

nRegSE1Orig := SE1->(Recno())
If Empty(SE1->(E1_VEND1+E1_VEND2+E1_VEND3+E1_VEND4+E1_VEND5))
	If !Empty(SE1->E1_NUMLIQ)
		DBSelectArea("SE5")
		DBSetOrder(10)
		If DBSeek(xFilial("SE5")+SE1->E1_NUMLIQ)
			DBSelectArea("SE1")
			DBSetOrder(1)
			If DBSeek(xFilial("SE1")+SE5->E5_PREFIXO+SE5->E5_NUMERO+SE5->E5_PARCELA+SE5->E5_TIPO)
				nRegSE1Orig := SE1->(Recno())
			EndIf
			SE1->(DBGoTo(nRegSE1))
	    EndIf
	EndIf
EndIf

While ( !Eof() .And. xFilial("SE1") == SE1->E1_FILIAL .And.;
						SE1->(E1_CLIENTE+E1_LOJA+E1_FATPREF+E1_FATURA) == cFatura )

	DBSelectArea("SE1")
	aFatura := Fa440Comis(SE1->(Recno()),.F.,.F.,,,nRegSE1Orig)  //calculo da comissao

	nQtdVend := Len(aFatura)
	cVend := "1"
	If !SE1->E1_TIPO $ MVABATIM
		nVlrProp   := 1

		cKeySe1 := SE1->(E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO+E1_CLIENTE+E1_LOJA)

		SE5->(DBSetOrder(7))
		If SE5->(MsSeek(xFilial("SE5")+cKeySe1))  //se encontrou baixas
			While !SE5->(Eof()) .And. SE5->E5_FILIAL == xFilial("SE5") .And. ;
										SE5->(E5_PREFIXO+E5_NUMERO+E5_PARCELA+E5_TIPO+E5_CLIFOR+E5_LOJA == cKeySe1 )
                //===================================================================
				// Ignora a NCC pois já foi feito o abatimento na geração da fatura.
				//===================================================================
				If SE5->E5_MOTBX == "FAT" .And. SE5->E5_SITUACA != "C" .And. SE5->E5_TIPO != MV_CRNEG
					nVlrFatur += SE5->E5_VALOR
					nVlrProp := ((SE5->E5_VALOR*1000)/SE1->E1_VLCRUZ)/1000

					If nVlrProp+0.01 >= 1
						nVlrProp := 1
					EndIf
					Exit   //sai do Loop do SE5
				EndIf

				SE5->(DBSkip())
			EndDo

		Else

			nVlrFatur += SE1->E1_VLCRUZ
			nVlrProp   := 1

		EndIf

		For nCntFor := 1 To Len(aFatura)
			aFatura[nCntFor,2]:= Round(NoRound(aFatura[nCntFor,2]*nVlrProp,nDecimal+1),nDecimal)
			aFatura[nCntFor,3]:= Round(NoRound(aFatura[nCntFor,3]*nVlrProp,nDecimal+1),nDecimal)
			aFatura[nCntFor,4]:= Round(NoRound(aFatura[nCntFor,4]*nVlrProp,nDecimal+1),nDecimal)
			aFatura[nCntFor,5]:= Round(NoRound(aFatura[nCntFor,5]*nVlrProp,nDecimal+1),nDecimal)
			aFatura[nCntFor,6]:= Round(NoRound(aFatura[nCntFor,6]*nVlrProp,nDecimal+1),nDecimal)
		Next nCntFor

	EndIf

	For nCntFor := 1 To Len(aFatura)

		nPosVend := aScan(aBases,{|x| x[1] == aFatura[nCntFor,1]})
		If nPosVend <> 0
			nPerComis := aBases[nPosVend,7]
			If nPerComis <> aFatura[nCntFor,7]
				nPerComis := -1
			EndIf
		Else
			nPerComis := aFatura[nCntFor,7]
		EndIf
		aAdd(abases,{	aFatura[nCntFor,1],;
						aFatura[nCntFor,2],;
						aFatura[nCntFor,3],;
						aFatura[nCntFor,4],;
						aFatura[nCntFor,5],;
						aFatura[nCntFor,6],;
						Max(0,nPerComis)})
	Next nCntFor

	DBSelectArea("SE1")
	DBSkip()

EndDo

FWRestArea(aAreaSE1)
FWRestArea(aArea)

Return( { aBases, nVlrFatur } )

/*
===============================================================================================================================
Programa----------: MaxSeqSe5()
Autor-------------: Rodrigo Oliveira
Data da Criacao---: 21/08/2017
Descrição---------: Função para verificação dda maior sequencia de baixa do título.
Parametros--------: cChave
Retorno-----------: cSeq - retorna a maior sequencia de baixa do título 
===============================================================================================================================
*/
Static Function MaxSeqSe5(cChave)
Local cSeq		:= "01"
Local aAreaSE5	:= SE5->(GetArea())

SE5->(DBSetOrder(7))

If SE5->(DBSeek(cChave))

	While SE5->(!Eof()) .And. ;
		cChave == SE5->E5_FILIAL + SE5->E5_PREFIXO + SE5->E5_NUMERO + SE5->E5_PARCELA + SE5->E5_TIPO + SE5->E5_CLIENTE + SE5->E5_LOJA
		If cSeq < SE5->E5_SEQ
			cSeq	:= SE5->E5_SEQ
		EndIf
		SE5->(DBSkip())
	EndDo			
EndIf

FWRestArea(aAreaSE5)

Return cSeq

/*
===============================================================================================================================
Programa----------: GRAVACOM(nX,lPVen,nChvFat,cVend, nRecPrinc,_cFilProc)
Autor-------------: Paulo Boschetti
Data da Criacao---: 13.07.93
Descrição---------: Grava Arquivo de Trabalho 
Parametros--------: nX
                    lPVen
                    nChvFat
                    cVend
                    nRecPrinc
                    _cFilProc
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function GRAVACOM(nX,lPVen,nChvFat,cVend, nRecPrinc,_cFilProc)
Local cAlias := Alias()

Default nChvFat := 0
Default cVend   := ""
Default nRecPrinc := 0

If Empty(_cFilProc)
   _cFilProc := cFilAnt
EndIf

DBSelectArea("TRB")
If Empty(cVend)
	cVend := IIf(lPVen,"SC5->C5_VEND","SE1->E1_VEND")+nX
	cVend := &cVend
EndIf

nChave := AllTrim(Str(&(cAlias+"->(RECNO())")))

//If TRB->(!DBSeek(cVend+cFilAnt+nChave))  
If TRB->(!DBSeek(cVend+_cFilProc+nChave))  
	RecLock("TRB",.T.)
	Replace FILIAL With _cFilProc // cFilAnt  
	Replace CODIGO With cVend
	Replace CHAVE  With AllTrim(Str(&(cAlias+"->(RECNO())")))
	Replace NVEND  With Val(nX)
	Replace PVEND  With IIf(lPVen,"S","N")
	Replace RECPRINC With nRecPrinc
	If nChvFat > 0
		Replace CHVFAT With nChvFat
	EndIf
	MSUnLock()
EndIf
DBSelectArea(cAlias)

Return .T.

/*
===============================================================================================================================
Programa----------: Fa440Comis(nRegistro,lGrava,lRefaz,nRegDevol,lCalcParc,nRecnoOrig)
Autor-------------: Eduardo Riera
Data da Criacao---: 16/12/97
Descrição---------: Efetua o calculo das bases da comissao de um determinado titulo financeiro.
Parametros--------: nRegistro = Numero do Registro do SE1 ( Contas a Receber ) 
                    lGrava    = .T. : Atualiza baseS da comissao do SE1.		
                    lRefaz    = .F. : Retorna bases do SE1 ou (.T.) recalcula(Defa)
                    nRegDevol = Numero do Registro do SD2 para Devol.de Vendas
                    lCalcParc = .F. : Nao calcula array de bases por parcela da NF
                    nRecnoOrig
Retorno-----------: Retorna um Array com as bases da comissao. na seguinte   
                    estrutura [C¢digo do Vendedor] 
                              [Base da Comissao] 
                              [Base na Emissao ]
                              [Base na Baixa   ] 
                              [Vlr  na Emissao ]
                              [Vlr  na Baixa   ] 
                              [% da Comissao/Se "Zero" diversos %'s]   
===============================================================================================================================
*/
Static Function Fa440Comis(nRegistro,lGrava,lRefaz,nRegDevol,lCalcParc,nRecnoOrig)
Local aArea 	 := FWGetArea()
Local aAreaSE4  := {}
Local aAreaSF2  := {}
Local aAreaSF4  := {}
Local aAreaSD2  := {}
Local aAreaSA1  := {}
Local aAreaSA3  := {}
Local aAreaSD1  := {}
Local aAreaSF1  := {}
Local aAreaSE1  := {}
Local aAux      := {}
Local aSD2Vend  := {} // Array c/ as Bases dos Vend. por item de nota
Local aBaseNCC  := {} // Array c/ as Bases dos Vend.
Local aBaseSE1  := {} // Array c/ as Bases dos Vend. do Titulo em questao
Local aBaseSD1  := {} // Array c/ as Bases dos Vend. do Item da NFE
Local aImp			:= {}  // Recebe o array de TesImpInf
Local aSemNota		:=	{}
Local aVendPed  	:= {}
Local aRelImp		:= MaFisRelImp("MT100",{ "SD2" })
Local nVend     	:= fa440CntVen() // Numero M ximo de Vendedores
Local nCntFor   	:= 0
Local nMaxFor   	:= 0
Local nBaseSe1  	:= 0 // Base da Comissao
Local nBaseDif  	:= 0
Local nPerComis 	:= 0 // Percentual da Comissao
Local nBaseEmis 	:= 0 // Base da Comissao na Emissao
Local nBaseBaix 	:= 0 // Base da Comissao na Baixa                  s
Local nVlrEmis  	:= 0 // Valor da Comissao na Emissao
Local nVlrBaix  	:= 0 // Valor da Comissao na Baixa
Local nFrete    	:= 0 // Valor do Frete
Local nIcmFrete 	:= 0 // Valor do Icms sobre frete
Local nTotal    	:= 0 // Total das mercadorias pelo item
Local nRatFrete 	:= 0 // Valor rateado do Frete por item
Local nRatIcmFre	:= 0 // Valor rateado do icms s/ frete por item
Local nSF2IcmRet	:= 0 // Valor do Icms Retido
Local nVlrFat   	:= 0 // Valor faturado
Local nVlrTit   	:= 0 // valor do titulo em questao
Local nProp     	:= 0
Local nPos      	:= 0
Local nAlEmissao	:= 0
Local nAlBaixa  	:= 0
Local nRatINSS  	:= 0
Local nRatIRRF  	:= 0
Local nX        	:= 0
Local nRatCOF		:= 0
Local nRatCSL		:= 0
Local nRatPIS  	:= 0
Local nScanPis  	:= 0
Local nScanCof  	:= 0
Local nBaseCC		:= 0											// Base de Comissao, caso seja CC ou CD - LOJA
Local nImp      	:= 0
Local nDescImp  	:= 0
Local nFreteAux 	:= 0
Local nPis 			:= 0
Local nCofins 		:= 0
Local nCsll 		:= 0
Local nTamParc  	:= TamSX3("E1_PARCELA")[1]
Local nDecimal  	:= TamSX3("E1_BASCOM1")[2] // N@ de decimais considerados no calculo
Local cVend     	:= "1"
Local cVendedor 	:= ""
Local cSerie    	:= ""
Local cPrefixo  	:= "" // Prefixo da Duplicata
Local cFilialSD1	:= ""
Local cFilialSD2	:= ""
Local cFilialSE1	:= ""
Local cFilialSE2	:= ""
Local cFilialSE4	:= ""
Local cFilialSF1	:= ""
Local cFilialSF2	:= ""
Local cFilialSF4	:= ""
Local cFieldPis 	:= ""
Local cFieldCof 	:= ""
Local cCposSD2  	:= "D2_FILIAL#D2_DOC#D2_SERIE#D2_CLIENTE#D2_LOJA#D2_TES#D2_ICMFRET#D2_TOTAL#D2_VALICM#D2_VALIPI#D2_IPI#D2_ICMSRET#D2_VALACRS#D2_ITEM#D2_COD#D2_DESCICM"
Local cAliasSD1 	:= "SD1"
Local cAliasSD2 	:= "SD2"
Local cAliasDev 	:= "SD1"
Local cAliasSF4 	:= "SF4"
Local cImp			:= "N"	 // Se A3_COMIMP nao existe, cImp = N, senao pega valor em A3_COMIMP
Local cMvComisCC	:= Upper( SuperGetMv("MV_COMISCC",,"S") )		// Verifica se deduz ou nao a taxa da adm. financeira p/ LOJA
Local cEspSes		:= " "
Local lQuery    	:= .F.
Local lContinua 	:= .T.
Local cPrimParc 	:= " "
Local lRecIRRF  	:= .F.
Local lMata460  	:= AllTrim(SE1->E1_ORIGEM) == "MATA460"
//Controla o Pis Cofins e Csll na baixa  (1-Retem PCC na Baixa ou 2-Retem PCC na Emissão(default) )
Local lPccBxCr		:= .F. //If (lFindPccBx,FPccBxCr(),.F.) 
Local lPEPerCom 	:= ExistBlock("FIN440PE")
Local lCalEmis		:= IsInCallStack("FA440CALCE")
Local lMultVend := SuperGetMv("MV_LJTPCOM",,"1" ) == "2"
Local nTotCsAbt  := 0
Local nTotPisAbt := 0
Local nTotCofAbt := 0
Local nImpComis		:= 0
Local nIrrf     	:= 0

#IFDEF TOP
	Local cQuery    := ""
#EndIf
Static aStruSD1
Static aStruSD2
Static aStruSF4

Default lPEPerCom := ExistBlock("FIN440PE")
Default lCalcParc := .T.
DEFAULT nRecnoOrig := nRegistro
//DEFAULT cMV_1DUP	:= SuperGetMv("MV_1DUP",,"01") 
//DEFAULT cComiLiq 	:= SuperGetMv("MV_COMILIQ",,"2") 
//DEFAULT lComiLiq	:= ComisBx("LIQ") .And. cComiLiq == "1" 

If Type("cMV_1DUP") == "U"
   cMV_1DUP	:= SuperGetMv("MV_1DUP",,"01") 
EndIf

If Type("cComiLiq") == "U"
   cComiLiq 	:= SuperGetMv("MV_COMILIQ",,"2") 
EndIf

If Type("lComiLiq") == "U"
   lComiLiq	:= ComisBx("LIQ") .And. cComiLiq == "1" 
EndIf

//===================================================================
// Abertura dos arquivos pois no Loja alguns nao sao utilizados
//===================================================================

DBSelectArea("SE4")
aAreaSE4  := SE4->(GetArea())
cFilialSE4:= xFilial("SE4")

DBSelectArea("SF2")
aAreaSF2  := SF2->(GetArea())
cFilialSF2:= xFilial("SF2")

DBSelectArea("SF4")
aAreaSF4  := SF4->(GetArea())
cFilialSF4:= xFilial("SF4")

DBSelectArea("SD2")
aAreaSD2  := SD2->(GetArea())
cFilialSD2:= xFilial("SD2")

DBSelectArea("SA1")
aAreaSA1  := SA1->(GetArea())

DBSelectArea("SA3")
aAreaSA3  := SA3->(GetArea())

DBSelectArea("SD1")
aAreaSD1  := SD1->(GetArea())
cFilialSD1:= xFilial("SD1")

DBSelectArea("SF1")
aAreaSF1  := SF1->(GetArea())
cFilialSF1:= xFilial("SF1")

DBSelectArea("SE1")
aAreaSE1  := SE1->(GetArea())
cFilialSE1:= xFilial("SE1")

DBSelectArea("SE2")
cFilialSE2:= xFilial("SE2")

FWRestArea(aArea)

//===================================================================
// Verifica se é a primeira parcela de uma fatura               
//===================================================================
If nTamParc == 1
	cPrimParc := "1A "
ElseIf nTamparc == 2
	cPrimParc := cMV_1DUP+Space(2-Len(cMV_1DUP))
	cPrimParc += "#1 #A #  #01"
Else
	cPrimParc := cMV_1DUP+Space(3-Len(cMV_1DUP))
	cPrimParc += "#1  #A  #   #001"
EndIf

If cPaisLoc<>"BRA"
	cEspSes	:= GetSesNew("NDC","1")
EndIf

//===================================================================
// Tratamento de Parametros Default da funcao                   
//===================================================================
lRefaz := If( lRefaz == Nil , .T. , lRefaz )
lGrava := If( lGrava == Nil , .T. , lGrava )
If ( aStruSD1 == Nil )
	aStruSD1 := {}
	DBSelectArea("SD1")
	aAux := dbStruct()
	For nCntFor := 1 To Len(aAux)
		If ( FieldName(nCntFor)$"D1_FILIAL#D1_DOC#D1_SERIE#D1_FORNECE#D1_LOJA" .Or.;
				FieldName(nCntFor)$"D1_NFORI#D1_SERIORI#D1_COD#D1_ITEMORI#D1_TOTAL#D1_VALDESC#D1_ITEM" )
			aAdd(aStruSD1,{aAux[nCntFor,1],aAux[nCntFor,2],aAux[nCntFor,3],aAux[nCntFor,4]})
		EndIf
	Next nCntFor
EndIf

If ( aStruSD2 == Nil )

	//===================================================================
	// Verifica se os campos que gravam o valor do PIS/COFINS para  
	// abater da base conforme configurado                          
	//===================================================================

	If !Empty( nScanPis := aScan(aRelImp,{|x| x[1]=="SD2" .And. x[3]=="IT_VALPS2"} ) )
		cFieldPis  := aRelImp[nScanPis,2]
	EndIf

	If !Empty( nScanCof := aScan(aRelImp,{|x| x[1]=="SD2" .And. x[3]=="IT_VALCF2"} ) )
		cFieldCof := aRelImp[nScanCof,2]
	EndIf

	aStruSD2 := {}
	DBSelectArea("SD2")
	aAux := dbStruct()
	For nCntFor := 1 To Len(aAux)
		If ( FieldName(nCntFor)$cCposSD2 .Or.;
			FieldName(nCntFor)$cFieldPis .Or.;
			FieldName(nCntFor)$cFieldCof .Or.;
			"D2_COMIS"$FieldName(nCntFor) )
			aAdd(aStruSD2,{aAux[nCntFor,1],aAux[nCntFor,2],aAux[nCntFor,3],aAux[nCntFor,4]})
		EndIf
	Next nCntFor
EndIf
If ( aStruSF4 == Nil )
	aStruSF4 := {}
	DBSelectArea("SF4")
	aAux := dbStruct()
	For nCntFor := 1 To Len(aAux)
		If ( FieldName(nCntFor)$"F4_DUPLIC#F4_INCIDE#F4_IPIFRET#F4_INCSOL#F4_ISS" )
			aAdd(aStruSF4,{aAux[nCntFor,1],aAux[nCntFor,2],aAux[nCntFor,3],aAux[nCntFor,4]})
		EndIf
	Next nCntFor
EndIf

//===================================================================
// Posiciona no Registro do SE1 a ser calculado                 
//===================================================================
DBSelectArea("SE1")
MsGoto(nRegistro)

//====================================================================
// Verifica se o cliente e responsavel pelo recolhimento do IR ou nao.
//====================================================================
If cPaisLoc == "BRA"
	DBSelectArea("SA1")
	SA1->(DBSetOrder(1))
	If SA1->(DBSeek(xFilial("SA1")+SE1->(E1_CLIENTE+E1_LOJA))) .And. SA1->A1_RECIRRF == "1"
		lRecIRRF := .T.
	EndIf
EndIf

//===================================================================
// Verifica se o titulo foi gerado pelo faturamento e For neces-
// sario recalcular suas bases.                                 
//===================================================================
If ( SE1->E1_TIPO $ MVNOTAFIS+cEspSes ) .And. !lSF2460I
	For nCntFor := 1 To nVend
		cVendedor := SE1->(FieldGet(SE1->(FieldPos("E1_VEND"+cVend))))
		nPerComis := SE1->(FieldGet(SE1->(FieldPos("E1_COMIS"+cVend))))
		If ( nPerComis == 0 .And. !Empty(cVendedor) )
			lRefaz := .T.
			Exit
		EndIf
		cVend := Soma1(cVend,1)
	Next nCntFor
ElseIf	cPaisLoc <>"BRA" .and.( SE1->E1_TIPO $ MV_CRNEG+MVRECANT)
	lRefaz := .T.
EndIf

//===================================================================
// Posiciona Registros                                          
// Aqui se faz necessaria a cria‡Æo de tratamento de filial de  
// origem para quando se tem SE1 compartilhado e SF2, SE4 ou SD2
// exclusivos                                                   
//===================================================================
If !Empty(SE1->E1_MSFIL) .And. !(Empty(cFilialSf1)) .And. FWModeAccess("SE1",3)=="C" .And. FWModeAccess("SF1",3)=="E"
	cFilialSf1 := SE1->E1_MSFIL
EndIf
If !Empty(SE1->E1_MSFIL) .And. !(Empty(cFilialSf2)) .And. FWModeAccess("SE1",3)=="C" .And. FWModeAccess("SF2",3)=="E"
	cFilialSf2 := SE1->E1_MSFIL
EndIf
If !Empty(SE1->E1_MSFIL) .And. !(Empty(cFilialSf4)) .And. FWModeAccess("SE1",3)=="C" .And. FWModeAccess("SF4",3)=="E"
	cFilialSf4 := SE1->E1_MSFIL
EndIf
If !Empty(SE1->E1_MSFIL) .And. !(Empty(cFilialSe1)) .And. FWModeAccess("SE1",3)=="C" .And. FWModeAccess("SE1",3)=="E"
	cFilialSe1 := SE1->E1_MSFIL
EndIf
If !Empty(SE1->E1_MSFIL) .And. !(Empty(cFilialSe2)) .And. FWModeAccess("SE1",3)=="C" .And. FWModeAccess("SE2",3)=="E"
	cFilialSe2 := SE1->E1_MSFIL
EndIf
If !Empty(SE1->E1_MSFIL) .And. !(Empty(cFilialSe4)) .And. FWModeAccess("SE1",3)=="C" .And. FWModeAccess("SE4",3)=="E"
	cFilialSe4 := SE1->E1_MSFIL
EndIf
If !Empty(SE1->E1_MSFIL) .And. !(Empty(cFilialSd1)) .And. FWModeAccess("SE1",3)=="C" .And. FWModeAccess("SD1",3)=="E"
	cFilialSd1 := SE1->E1_MSFIL
EndIf
If !Empty(SE1->E1_MSFIL) .And. !(Empty(cFilialSd2)) .And. FWModeAccess("SE1",3)=="C" .And. FWModeAccess("SD2",3)=="E"
	cFilialSd2 := SE1->E1_MSFIL
EndIf

If ( SE1->E1_TIPO $ MVNOTAFIS+cEspSes .And. lRefaz)
	If Year(SE1->E1_EMISSAO)<2001
		cSerie := If(Empty(SE1->E1_SERIE),SE1->E1_PREFIXO,SE1->E1_SERIE)
	Else
		cSerie := SE1->E1_SERIE
	EndIf
	DBSelectArea("SF2")
	DBSetOrder(1)
	If (!MsSeek(cFilialSF2+SE1->E1_NUM+cSerie+SE1->E1_CLIENTE+SE1->E1_LOJA,.F.))
		lContinua := .F.
	EndIf
	DBSelectArea("SE4")
	DBSetOrder(1)
	If (!MsSeek(cFilialSE4+SF2->F2_COND))
		lContinua := .F.
	EndIf
	DBSelectArea("SD2")
	DBSetOrder(3)
	#IFDEF TOP
		If ( TcSrvType()!="AS/400" )
			SD2->(dbCommit())
			lQuery := .T.
			cAliasSD2 := "FA440COMIS"
			cAliasSF4 := "FA440COMIS"
			cQuery := ""
			For nCntFor := 1 To Len(aStruSD2)
				cQuery += ","+aStruSD2[nCntFor][1]
			Next nCntFor
			For nCntFor := 1 To Len(aStruSF4)
				cQuery += ","+aStruSF4[nCntFor][1]
			Next nCntFor

			cQuery := "SELECT SD2.R_E_C_N_O_ SD2RECNO,"+SubStr(cQuery,2)
			cQuery += "  FROM "+RetSqlName("SD2")+" SD2,"+RetSqlName("SF4")+" SF4 "
			cQuery += " WHERE SD2.D2_FILIAL   = '"+cFilialSD2+"'"
			cQuery += "   AND SD2.D2_DOC	  = '"+SE1->E1_NUM+"'"
			cQuery += "   AND SD2.D2_SERIE	  = '"+cSerie+"'"
			cQuery += "   AND SD2.D2_CLIENTE  = '"+SE1->E1_CLIENTE+"'"
			cQuery += "   AND SD2.D2_LOJA     = '"+SE1->E1_LOJA+"'"
			cQuery += "   AND SD2.D_E_L_E_T_ <> '*'"
			cQuery += "   AND SF4.F4_FILIAL	  ='"+cFilialSF4+"'"
			cQuery += "   AND SF4.F4_CODIGO   = SD2.D2_TES"
			cQuery += "   AND SF4.D_E_L_E_T_  <> '*' "
			cQuery += " ORDER BY "+SqlOrder(SD2->(IndexKey()))

			cQuery := ChangeQuery(cQuery)
			dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasSD2)

			lContinua := !(cAliasSD2)->(Eof())
			For nCntFor := 1 To Len(aStruSD2)
				If ( aStruSD2[nCntFor][2]!= "C" )
					TCSetField(cAliasSD2,aStruSD2[nCntFor][1],aStruSD2[nCntFor][2],aStruSD2[nCntFor][3],aStruSD2[nCntFor][4])
				EndIf
			Next nCntFor
			For nCntFor := 1 To Len(aStruSF4)
				If ( aStruSF4[nCntFor][2]!="C" )
					TCSetField(cAliasSF4,aStruSF4[nCntFor][1],aStruSF4[nCntFor][2],aStruSD2[nCntFor][3],aStruSF4[nCntFor][4])
				EndIf
			Next nCntFor
		Else
	#EndIf
		If (!MsSeek(cFilialSD2+SE1->E1_NUM+cSerie+SE1->E1_CLIENTE+SE1->E1_LOJA,.F.))
			lContinua := .F.
		EndIf
		#IFDEF TOP
		EndIf
		#EndIf
	If ( lContinua )
		//===================================================================
		// Calculo da comissao por item de nota fiscal                      |
		//                                                                  |
		//1)O Valor do icms s/ frete e adiciona ao campo F2_VALICM, por     |
		//esta razao deve-se somar o vlr do icms dos itens e subtrair       |
		//do total de icms (F2_VALICM) para apurar-se o vlr icms s/frete    |
		//                                                                  |
		//2)O mesmo ocorre para o valor do IPI sobre frete, Por esta ra-    |
		//zao e' calculado o valor do IPI sobre frete do item multipli-     |
		//cando-se o valor do frete do item pelo % de ipi do item.          |
		//                                                                  |
		//3)O Valor do Icms Retido pode nÆo estar no total da nota (F2_-    |
		//VALBRUT) por isto deve-se considerar o campo (D2_ICMSRET).        |
		//                                                                  |
		//4)O percentual da comissao dever ser considerado para cada i-     |
		//tem de nota fiscal pois ela pode ser diferente entre eles. O      |
		//percentual gravado no E1_COMIS ‚ sempre um valor aproximado e     |
		//nao deve ser considerado ser houver nota fiscal para o titulo.    |
		//                                                                  |
		//5)A Base da Comissao ‚ o valor da mercadoria + o valor do ipi     |
		//+ o valor das despesas acessorias +  o icms solidario. Como e'    |
		//por item deve-se conhece-lo pelo item a item.                     |
		//===================================================================
		nTotal     := 0
		nFrete     := (SF2->F2_FRETE + SF2->F2_SEGURO + SF2->F2_DESPESA)
		nIcmFrete  := 0
		nSF2IcmRet :=0

		If !Empty( nScanPis := aScan(aRelImp,{|x| x[1]=="SD2" .And. x[3]=="IT_VALPS2"} ) )
			cFieldPis  := aRelImp[nScanPis,2]
		EndIf

		If !Empty( nScanCof := aScan(aRelImp,{|x| x[1]=="SD2" .And. x[3]=="IT_VALCF2"} ) )
			cFieldCof := aRelImp[nScanCof,2]
		EndIf

		If  lPccBxCr .And. !lCalEmis

			 If !(SE5->E5_PRETPIS	$	"1;2")
			 	nPis	:= SE5->E5_VRETPIS
			 Else
			 	nPis		:=	0
			 EndIf
			 If !(SE5->E5_PRETCOF	$	"1;2")
			 	nCofins	:= SE5->E5_VRETCOF
			 Else
			 	nCofins	:= 0
			 EndIf
			 If !(SE5->E5_PRETCSL $	"1;2")
			 	nCofins	:= SE5->E5_VRETCSL
			 Else
			 	nCofins	:= 0
			 EndIf
		EndIf

		While ( !Eof() .And. (cAliasSD2)->D2_FILIAL == cFilialSD2 .And.;
				(cAliasSD2)->D2_DOC 	 == SE1->E1_NUM .And.;
				(cAliasSD2)->D2_SERIE	 == cSerie .And.;
				(cAliasSD2)->D2_CLIENTE  == SE1->E1_CLIENTE .And.;
				(cAliasSD2)->D2_LOJA	 == SE1->E1_LOJA	)

			If ( !lQuery )
				DBSelectArea("SF4")
				DBSetOrder(1)
				MsSeek(cFilialSF4+(cAliasSD2)->D2_TES)
			Else
				If cPaisLoc<>"BRA"
					SD2->(DBGoTo((cAliasSD2)->SD2RECNO))
				EndIf
			EndIf

			cVend := "1"
			For nCntFor := 1 To nVend
				cVendedor := SF2->(FieldGet(SF2->(FieldPos("F2_VEND"+cVend))))
				nPerComis := (cAliasSD2)->(FieldGet((cAliasSD2)->(FieldPos("D2_COMIS"+cVend))))
				nImp     := 0
				nDescImp := 0
				If cPaisLoc <> "BRA"
					SA3->(DBSetOrder(1))
					SA3->(DBSeek(xFilial()+cVendedor))
					aImp := TesImpInf(	(cAliasSD2)->D2_TES)
					cImp := SA3->A3_COMIMP
					For nX :=1 to Len(aImp)
						If (cImp+aImp[nX][3] == "S1")
							nImp += SD2->(FieldGet(FieldPos(aImp[nX][2])))
						ElseIf (cImp+aImp[nX][3] == "N2")
							nImp -=	SD2->(FieldGet(FieldPos(aImp[nX][2])))
						EndIf
						If cPaisLoc == "PTG" .And. cImp+aImp[nX][13] == "N1"
							nImpComis -= SD2->(FieldGet(FieldPos(aImp[nX][2])))
						EndIf
					Next nX
				Else
					If cPaisLoc == "BRA"
						nDescImp -= (cAliasSD2)->D2_DESCICM
					EndIf
				EndIf
				If ( !Empty(cVendedor) .And. (cAliasSF4)->F4_DUPLIC == "S" )
					aAdd(aSD2Vend,{ cVendedor,;
						(cAliasSD2)->D2_TOTAL+nImp+nDescImp,;
						(cAliasSD2)->D2_VALICM+nDescImp,;
						(cAliasSD2)->D2_VALIPI,;
						(cAliasSD2)->D2_IPI,;
						(cAliasSF4)->F4_INCIDE,;
						(cAliasSF4)->F4_IPIFRET,;
						IIf(cPaisLoc<>"BRA".Or.(cAliasSF4)->F4_INCSOL=="N",0,(cAliasSD2)->D2_ICMSRET),;
						nPerComis,;
						(cAliasSD2)->D2_VALACRS,;
						If(lQuery,(cAliasSD2)->SD2RECNO,(cAliasSD2)->(RecNo())),;
						(cAliasSF4)->F4_ISS=="S",;
						cVend,;
						nPis,;
						nCofins,;
						IIf(!Empty(cFieldPis), (cAliasSD2)-> D2_VALIMP5,0) ,; // pis apuração
						IIf(!Empty(cFieldCof), (cAliasSD2)-> D2_VALIMP6,0) }) // cofins apuração
						If cPaisLoc == "PTG"
							aAdd(aSD2Vend[Len(aSD2Vend)],(cAliasSD2)->D2_TOTAL+nImpComis+nDescImp)
						EndIf
					If aScan(aVendPed, cVendedor) == 0	  // Monta um array com os vendedores para rateio do frete
					   aAdd(aVendPed, cVendedor)
					EndIf
					//===================================================================
					// Ajusta a base da comissao da nota para a Moeda 01  
					//===================================================================
					If cPaisLoc<>"BRA"
						aSD2Vend[Len(aSD2Vend),2]	:= 	xMoeda( aSD2Vend[Len(aSD2Vend),2] , SF2->F2_MOEDA , 1 , SF2->F2_EMISSAO , nDecimal , SF2->F2_TXMOEDA )
					EndIf
				EndIf
				cVend := Soma1(cVend,1)
			Next nCntFor
			If ( (cAliasSF4)->F4_ISS != "S" )
				nSF2IcmRet += IIf((cAliasSF4)->F4_INCSOL=="N",0,(cAliasSD2)->D2_ICMSRET)
				nIcmFrete  += (cAliasSD2)->D2_ICMFRET
			EndIf
			nTotal	  += (cAliasSD2)->D2_TOTAL
			DBSelectArea(cAliasSD2)
			DBSkip()
		EndDo
		If ( lQuery )
			DBSelectArea(cAliasSD2)
			DBCloseArea()
			DBSelectArea("SD2")
		EndIf
		//===================================================================
		// Calculo da comissao pela nota.                                   |
		//                                                                  |
		// 1)Apos calculado as bases de cada vendedor por item de nota      |
		// deve-se aglutina-las formando uma unica base para toda a nota    |
		// fiscal.                                                          |
		//                                                                  |
		// 2)Como os valores serao aglutinados pode-se haver perda de de-   |
		// cimais por isto deve-se haver um controle para que a perda se-   |
		// ja adicionada a primeira parcela da nota.                        |
		//===================================================================
		nMaxFor := Len(aSD2Vend)
		nPerComis:=0
		nFreteAux := 0
		For nCntFor := 1 To nMaxFor
			If (lPePercom)
				nPerComis := ExecBlock("FIN440PE",.F.,.F.,{aSD2Vend[nCntFor][1]})
				If ( ValType(nPerComis)<>"N" )
					nPerComis := aSD2Vend[nCntFor][9]
				Else
					aSD2Vend[nCntFor][9] := nPerComis
				EndIf
			Else
				nPerComis := aSD2Vend[nCntFor][9]
			EndIf
			If ( SE1->E1_PARCELA $ cPrimParc )
				nBaseDif  := NoRound(nFrete*(1-(aSD2Vend[nCntFor,2]/nTotal)),nDecimal+1)
				nBaseDif  := nFrete - nBaseDif
				//================================================================================================
				// No ultimo item o valor do rateio do frete é o valor do frete menos o rateio do frete acumulado
				// ate o penultimo item (evitar diferenca de centavos na base da comissao (E1_BASCOM)
				//================================================================================================
				If nCntFor == nMaxFor
				   nRatFrete := (nFrete * If(Len(aVendPed) > 0, Len(aVendPed), 1)) - nFreteAux
				Else
					nFreteAux += nBaseDif
					nRatFrete := nBaseDif
				EndIf
			Else
				nRatFrete := NoRound(nFrete*aSD2Vend[nCntFor,2]/nTotal,nDecimal+1)
			EndIf
			If cPaisLoc == "BRA"
				If ( SE1->E1_PARCELA $ cPrimParc )
					nBaseDif  := NoRound(SF2->F2_VALINSS*(1-(aSD2Vend[nCntFor,2]/nTotal)),nDecimal+1)
					nBaseDif  := SF2->F2_VALINSS - nBaseDif
					nRatINSS  := nBaseDif
				Else
					nRatINSS := NoRound(SF2->F2_VALINSS*aSD2Vend[nCntFor,2]/nTotal,nDecimal+1)
				EndIf

				If  lPccBxCr .And. !lCalEmis
			 		If !(SE5->E5_PRETPIS	$	"1;2")
						nPis	:= SE5->E5_VRETPIS
					Else
						nPis	:=	0
					EndIf
					If !(SE5->E5_PRETCOF	$	"1;2")
						nCofins	:= SE5->E5_VRETCOF
					Else
						nCofins	:= 0
					EndIf
					If !(SE5->E5_PRETCSL	$	"1;2")
						nCsll	:= SE5->E5_VRETCSL
					Else
						nCsll	:=	0
					EndIf
					If ( SE1->E1_PARCELA $ cPrimParc )
						nBaseDif  := NoRound(nCsll*(1-(aSD2Vend[nCntFor,2]/nTotal)),nDecimal)
						nBaseDif  := nCsll - nBaseDif
						nRatCSL  := nBaseDif

						nBaseDif  := NoRound(nPis*(1-(aSD2Vend[nCntFor,2]/nTotal)),nDecimal)
						nBaseDif  := nPis - nBaseDif
						nRatPIS  := nBaseDif

						nBaseDif  := NoRound(nCofins*(1-(aSD2Vend[nCntFor,2]/nTotal)),nDecimal)
						nBaseDif  := nCofins - nBaseDif
						nRatCOF  := nBaseDif
					Else
						nRatCSL := NoRound(nCsll*aSD2Vend[nCntFor,2]/nTotal,nDecimal)
						nRatPIS:= NoRound(nPis*aSD2Vend[nCntFor,2]/nTotal,nDecimal)
						nRatCOF := NoRound(nCofins*aSD2Vend[nCntFor,2]/nTotal,nDecimal)
					EndIf

				ElseIf !lPccBxCr

					If ( SE1->E1_PARCELA $ cPrimParc )
						nBaseDif  := NoRound(SF2->F2_VALCSLL*(1-(aSD2Vend[nCntFor,2]/nTotal)),nDecimal)
						nBaseDif  := SF2->F2_VALCSLL - nBaseDif
						nRatCSL  := nBaseDif
					Else
						nRatCSL := NoRound(SF2->F2_VALCSLL*aSD2Vend[nCntFor,2]/nTotal,nDecimal)
					EndIf

					If ( SE1->E1_PARCELA $ cPrimParc )
						nBaseDif  := NoRound(SF2->F2_VALPIS*(1-(aSD2Vend[nCntFor,2]/nTotal)),nDecimal)
						nBaseDif  := SF2->F2_VALPIS - nBaseDif
						nRatPIS  := nBaseDif
					Else
						nRatPIS := NoRound(SF2->F2_VALPIS*aSD2Vend[nCntFor,2]/nTotal,nDecimal)
					EndIf

					If ( SE1->E1_PARCELA $ cPrimParc )
						nBaseDif  := NoRound(SF2->F2_VALCOFI*(1-(aSD2Vend[nCntFor,2]/nTotal)),nDecimal)
						nBaseDif  := SF2->F2_VALCOFI - nBaseDif
						nRatCOF  := nBaseDif
					Else
						nRatCOF := NoRound(SF2->F2_VALCOFI*aSD2Vend[nCntFor,2]/nTotal,nDecimal)
					EndIf
				EndIf

				If ( SE1->E1_PARCELA $ cPrimParc )
			  		nBaseDif  := NoRound(SF2->F2_VALIRRF*(1-(aSD2Vend[nCntFor,2]/nTotal)),nDecimal)
					nBaseDif  := SF2->F2_VALIRRF - nBaseDif
					nRatIRRF  := nBaseDif
					nRatIRRF := NoRound(SF2->F2_VALIRRF*aSD2Vend[nCntFor,2]/nTotal,nDecimal)
				Else
					nRatIRRF := NoRound(SF2->F2_VALIRRF*aSD2Vend[nCntFor,2]/nTotal,nDecimal)
				EndIf

			EndIf
			nRatIcmFre:= 0
			nBaseSE1  := 0
			nPos      := 0
			nRatIcmFre:= NoRound(nIcmFrete*aSD2Vend[nCntFor,2]/nTotal,nDecimal)
			nBaseSE1  := aSD2Vend[nCntFor,2]+IIf(SF2->F2_TIPO=='P',0,aSD2Vend[nCntFor,4])+aSD2Vend[nCntFor,8]+nRatFrete //soma-se IPI e ICM Retido
			DBSelectArea("SA3")
			DBSetOrder(1)
			MsSeek(xFilial()+aSD2Vend[nCntFor,1])

			If SE1->(FieldPos("E1_ALEMIS"+aSD2Vend[nCntFor,13]))<>0 //Nao criar no dicionario padrao
				nAlEmissao := SE1->(FieldGet(FieldPos("E1_ALEMIS"+aSD2Vend[nCntFor,13])))
			Else
				nAlEmissao := SA3->A3_ALEMISS
			EndIf
			If SE1->(FieldPos("E1_ALBAIX"+aSD2Vend[nCntFor,13]))<>0 //Nao criar no dicionario padrao
				nAlBaixa := SE1->(FieldGet(FieldPos("E1_ALBAIX"+aSD2Vend[nCntFor,13])))
			Else
				nAlBaixa := SA3->A3_ALBAIXA
			EndIf

			If ( SA3->A3_FRETE == "N" )
				nBaseSE1 -=  nRatFrete
				nBaseSE1 +=  nRatIcmFre
			EndIf
			If ( SA3->A3_IPI   == "N" )
				nBaseSE1 -= ( aSD2Vend[nCntFor,4] )
			EndIf
			If !aSD2Vend[nCntFor,12]
				If ( SA3->A3_ICM   == "N" )
					nBaseSE1 -= aSD2Vend[nCntFor,3]
				EndIf
			Else
				If ( SA3->A3_ISS == "N" ) .Or. (( SA3->A3_ISS == "S" ) .And. SE1->E1_FRETISS=="1" .And.;
			   		(SuperGetMV("MV_VRETISS",.F.,0) < aSD2Vend[nCntFor,3]) .And. SA1->A1_RECISS == "1")// Abate o ISS da base
					nBaseSE1 -= ( aSD2Vend[nCntFor,3] )
				EndIf
			EndIf
			If ( SA3->A3_ICMSRET == "N" )
				nBaseSE1 -= ( aSD2Vend[nCntFor,8] )
			EndIf
			If ( SA3->A3_ACREFIN == "N" ) .And. aSD2Vend[nCntFor,10] > 0
				nBaseSE1 -= ( aSD2Vend[nCntFor,10] )
			EndIf

			Do Case
			Case SA3->A3_PISCOF == "2" //Abate Pis
				nBaseSE1 -=aSD2Vend[nCntFor,16]
			Case SA3->A3_PISCOF == "3" //Abate Cofins
				nBaseSE1 -=aSD2Vend[nCntFor,17]
			Case SA3->A3_PISCOF == "4" //Abate ambos
				nBaseSE1 -=aSD2Vend[nCntFor,16]
				nBaseSE1 -=aSD2Vend[nCntFor,17]
			EndCase

			If SuperGetMv("MV_COMISIR") == "N" .And. lRecIRRF
				nBaseSE1 -= nRatIRRF
			EndIf
			If GetNewPar("MV_COMIINS","N") == "N"
				nBaseSE1 -= nRatINSS
			EndIf
			If !lPccBxCr
				If GetNewPar("MV_COMIPIS","N") == "N"
					nBaseSE1 -= nRatPIS
				EndIf
				If GetNewPar("MV_COMICOF","N") == "N"
					nBaseSE1 -= nRatCOF
				EndIf
				If GetNewPar("MV_COMICSL","N") == "N"
					nBaseSE1 -= nRatCSL
				EndIf
			Else
				If GetNewPar("MV_COMIPIS","N") == "S"
					nPIS := 0
				EndIf
				If GetNewPar("MV_COMICOF","N") == "S"
					nCofins := 0
				EndIf

				If GetNewPar("MV_COMICSL","N") == "S"
					nCsll := 0
				EndIf
			EndIf

			nPos := aScan(aBaseSE1,{|x| x[1] == aSD2Vend[nCntFor,1]})
			If AllTrim(SE1->E1_Hist) <> "VENDA EM DINHEIRO"
				nBaseBaix := Round(nBaseSE1*nAlBaixa/100,nDecimal+1)	 	// Base da Comissao na Baixa
			Else
				nBaseBaix:= 0
			EndIf
			nBaseEmis := nBaseSE1-nBaseBaix                           		// Base da Comissao na Emissao
			If ( nAlEmissao==0 .And.  AllTrim(SE1->E1_Hist) <> "VENDA EM DINHEIRO" )
				nBaseEmis := 0
			EndIf

			If (IsInCallStack("FINA070") .Or. IsInCallStack("FINA110")) .And. MV_PAR05 == 1
				nBaseBaix += nJuros
			EndIf

			nVlrEmis  := nBaseEmis*aSD2Vend[nCntFor,9]/100	// Valor da Comissao na Emissao
			nVlrBaix  := nBaseBaix*aSD2Vend[nCntFor,9]/100	// Valor da Comissao na Baixa
			If ( Empty(nRegDevol) .Or. nRegDevol == aSD2Vend[nCntFor,11] )
				If ( nPos == 0 )
					aAdd(aBaseSE1,{ aSD2Vend[nCntFor,1] ,;
						nBaseSE1  				,;
						nBaseEmis 				,;
						nBaseBaix 				,;
						nVlrEmis  				,;
						nVlrBaix				,;
						nPerComis				,;
						nPis						,;
						nCsll						,;
						nCofins})
						If cPaisLoc == "PTG"
							aAdd(aBaseSE1[Len(aBaseSE1)],Round((aSD2Vend[nCntFor,18]*aSD2Vend[nCntFor,9]/100)*SA3->A3_ALEMISS/100,nDecimal))
							aAdd(aBaseSE1[Len(aBaseSE1)],aSD2Vend[nCntFor,18]*SA3->A3_ALEMISS/100)
						EndIf
				Else
					aBaseSE1[nPos,2] += nBaseSE1
					aBaseSE1[nPos,3] += nBaseEmis
					aBaseSE1[nPos,4] += nBaseBaix
					aBaseSE1[nPos,5] += nVlrEmis
					aBaseSE1[nPos,6] += nVlrBaix
					If aBaseSE1[nPos,7] == nPerComis
						aBaseSE1[nPos,7] := nPerComis
					Else
						aBaseSE1[nPos,7] := 0
					EndIf
				EndIf
			EndIf
		Next nCntFor
		
		//===================================================================
		// Calculo da comissao pelas parcelas.                              |       
		//                                                                  |
		// 1)O SE3 ‚ gravado por parcela e nao pela nota. assim e'neces-    |
		// sario calcular a base da comissao para a parcela em questao.     |
		//                                                                  |
		// 2)Aqui deve-se tomar o maximo cuidado com a Condi‡Æo de pagto    |
		// pois se o Icms Solidario ou o Ipi For separado de alguma par-    | 
		// cela deve-se considera esta separacao para calcular-se a me-     | 
		// lhor propor‡ao possivel para a base da parcela.                  |
		//===================================================================
		If lCalcParc
			nMaxFor := Len(aBaseSE1)
			For nCntFor := 1 To nMaxFor
				nProp   := 0
				nVlrFat := xMoeda(SF2->F2_VALFAT,SE1->E1_MOEDA,1,SE1->E1_EMISSAO)
				nVlrTit := SE1->E1_VLCRUZ
				DBSelectArea("SA3")
				DBSetOrder(1)
				MsSeek(xFilial()+aBaseSE1[nCntFor,1])
				If ( SA3->A3_IPI == "N" .Or. SA3->A3_ICMSRET == "N" )
					If ( (SE4->E4_IPI == "S" .And. SF2->F2_VALIPI <> 0) .Or. ( SE4->E4_SOLID=="S" .And. SF2->F2_ICMSRET <> 0) ) .And. (SE1->E1_PARCELA $ cPrimParc)
				   		If !Empty(SE1->E1_PARCELA)
							nVlrTit := 0
							nVlrFat := 0
						EndIf
					EndIf
					If ( SE4->E4_IPI == "S" .And. !SE1->E1_PARCELA $ cPrimParc)
						nVlrFat -= ( SF2->F2_VALIPI )
					EndIf
					If ( SE4->E4_SOLID == "S" .And. !SE1->E1_PARCELA $ cPrimParc)
						nVlrFat -= (nSf2IcmRet)
					EndIf
					If ( SE4->E4_IPI == "J" .And. SE1->E1_PARCELA $ cPrimParc)
						nVlrFat -= ( SF2->F2_VALIPI )
						nVlrTit -= ( SF2->F2_VALIPI )
					EndIf
					If ( SE4->E4_IPI == "J" .And. !(SE1->E1_PARCELA $ cPrimParc ))
						nVlrFat -= ( SF2->F2_VALIPI )
					EndIf
					If ( SE4->E4_SOLID == "J" .And. SE1->E1_PARCELA $ cPrimParc )
						nVlrFat -= (nSf2IcmRet)
						nVlrTit -= (nSf2IcmRet)
					EndIf
					If ( SE4->E4_SOLID == "J" .And. !(SE1->E1_PARCELA $ cPrimParc) )
						nVlrFat -= (nSf2IcmRet)
					EndIf
				EndIf
				If ( nVlrTit > 0 )
					nProp := nVlrFat / nVlrTit
				Else
					nProp := 0
				EndIf
				If (nProp != 0 )
					nBaseSE1 := NoRound(aBaseSE1[nCntFor,2]/nProp,nDecimal+1)
					nBaseEmis:= NoRound(aBaseSE1[nCntFor,3]/nProp,nDecimal+1)
					nBaseBaix:= NoRound(aBaseSE1[nCntFor,4]/nProp,nDecimal+1)
					nVlrEmis := Round(aBaseSE1[nCntFor,5]/nProp,nDecimal+1)
					nVlrBaix := Round(aBaseSE1[nCntFor,6]/nProp,nDecimal+1)
				Else
					nBaseSE1 := 0
					nBaseEmis:= 0
					nBaseBaix:= 0
					nVlrEmis := 0
					nVlrBaix := 0
				EndIf
				If ( SE1->E1_PARCELA $ cPrimParc .And. nBaseSE1 != 0 )
				    //===================================================================
					//--> Calculo da Proporcao para a Base da Comissao
					//===================================================================
					nBaseDif := Round(nBaseSE1 * nProp,nDecimal+1)
					nBaseDif := aBaseSE1[nCntFor,2]-nBaseDif
					aBaseSE1[nCntFor,2] := nBaseSE1+nBaseDif
					
					//===================================================================
					//--> Calculo da Proporcao para a Base da Comissao pela Emissao
                    //===================================================================
					nBaseDif := Round(nBaseEmis * nProp,nDecimal+1)
					nBaseDif := aBaseSE1[nCntFor,3]-nBaseDif
					aBaseSE1[nCntFor,3] := nBaseEmis+nBaseDif
					If cPaisLoc == "PTG"
						aBaseSE1[nCntFor,12] := NoRound(aBaseSE1[nCntFor,12]/nProp,nDecimal+1)
					EndIf
					
					//===================================================================
					//--> Calculo da Proporcao para a Base da Comissao pela Baixa
					//===================================================================
					nBaseDif := Round(nBaseBaix * nProp,nDecimal+1)
					nBaseDif := aBaseSE1[nCntFor,4]-nBaseDif
					aBaseSE1[nCntFor,4] := nBaseBaix+nBaseDif
					
					//===================================================================
					//--> Calculo da Proporcao para o Valor da Comissao pela Emissao
					//===================================================================
					nBaseDif := Round(nVlrEmis * nProp,nDecimal+1)
					nBaseDif := aBaseSE1[nCntFor,5]-nBaseDif
					aBaseSE1[nCntFor,5] := nVlrEmis+nBaseDif
					If cPaisLoc == "PTG"
						aBaseSE1[nCntFor,11] := Round(aBaseSE1[nCntFor,11]/nProp,nDecimal+1)
					EndIf
					
					//===================================================================
					//--> Calculo da Proporcao para o Valor da Comissao pela Baixa
                    //===================================================================
					nBaseDif := Round(nVlrBaix * nProp,nDecimal+1)
					nBaseDif := aBaseSE1[nCntFor,6]-nBaseDif
					aBaseSE1[nCntFor,6] := nVlrBaix+nBaseDif
				Else
					aBaseSE1[nCntFor,2] := nBaseSE1
					aBaseSE1[nCntFor,3] := nBaseEmis
					aBaseSE1[nCntFor,4] := nBaseBaix
					aBaseSE1[nCntFor,5] := nVlrEmis
					aBaseSE1[nCntFor,6] := nVlrBaix
					If cPaisLoc == "PTG"
						aBaseSE1[nCntFor,12] := NoRound(aBaseSE1[nCntFor,12]/nProp,nDecimal+1)
						aBaseSE1[nCntFor,11] := Round(aBaseSE1[nCntFor,11]/nProp,nDecimal+1)
					EndIf
				EndIf
			Next nCntFor
		EndIf
	Else
		If ( lQuery .And. Select(cAliasSD2)<>0 )
			DBSelectArea(cAliasSD2)
			DBCloseArea()
			DBSelectArea("SE1")
		EndIf
	EndIf
EndIf
If ( SE1->E1_TIPO $ MV_CRNEG ) .And. !("FINA040" $ SE1->E1_ORIGEM)
   //===================================================================
   // Verifica a filial de origem das notas de devolucao de Venda  
   //===================================================================

	If !Empty(SE1->E1_FILORIG) .And. !(Empty(cFilialSF1)) .And. FWModeAccess("SE1",3)=="C" .And. FWModeAccess("SF1",3)=="E"
		cFilialSF1 := SE1->E1_FILORIG
	EndIf
	If !Empty(SE1->E1_FILORIG) .And. !(Empty(cFilialSD1)) .And. FWModeAccess("SE1",3)=="C" .And. FWModeAccess("SD1",3)=="E"
		cFilialSD1 := SE1->E1_FILORIG
	EndIf

	If Year(SE1->E1_EMISSAO)<2001
		cSerie := If(Empty(SE1->E1_SERIE),SE1->E1_PREFIXO,SE1->E1_SERIE)
	Else
		cSerie := SE1->E1_SERIE
	EndIf
	
	//===================================================================
	// Posiciona Registros                                          
	//===================================================================
	DBSelectArea("SF1")
	DBSetOrder(1)
	If (!MsSeek(cFilialSF1+SE1->E1_NUM+cSerie+SE1->E1_CLIENTE+SE1->E1_LOJA,.F.))
		lContinua := .F.
	EndIf
	
	//===================================================================
	// Calculo do Estorno da Comissao.                                  |  
	//                                                                  |
	// 1) Localiza-se a Nota Original                                   |
	//                                                                  |
	// 2) Calcula a Comissao para a Nota Original                       |
	//                                                                  |
	// 3) Faz a Proporcao entre os valor da Mercadoria e os valores     |
	//   da comissao.                                                   | 
	//                                                                  |
	//===================================================================
	DBSelectArea("SD1")
	DBSetOrder(1)
	#IFDEF TOP
		If ( TcSrvType()!="AS/400" )
			SD1->(dbCommit())
			cAliasSD1 := "BFA440COMIS"
			lQuery := .T.
			cQuery := ""
			For nCntFor := 1 To Len(aStruSD1)
				cQuery += ","+aStruSD1[nCntFor][1]
			Next nCntFor

			cQuery := "SELECT "+SubStr(cQuery,2)
			cQuery += "  FROM "+RetSqlName("SD1")+" SD1 "
			cQuery += " WHERE SD1.D1_FILIAL  = '"+cFilialSD1+"'"
			cQuery += "   AND SD1.D1_DOC	 = '"+SE1->E1_NUM+"'"
			cQuery += "   AND SD1.D1_SERIE	 = '"+cSerie+"'"
			cQuery += "   AND SD1.D1_FORNECE = '"+SE1->E1_CLIENTE+"'"
			cQuery += "   AND SD1.D1_LOJA    = '"+SE1->E1_LOJA+"'"
			cQuery += "   AND "
			If cPaisLoc<>"BRA"
				cQuery += "SD1.D_E_L_E_T_<>'*' "
			Else
				cQuery += "    SD1.D_E_L_E_T_<>'*'"
				cQuery += "AND SD1.D1_ITEMORI<>'"+Space(Len(SD1->D1_ITEMORI))+"' "
			EndIf
			cQuery += "ORDER BY "+SqlOrder(SD1->(IndexKey()))

			cQuery := ChangeQuery(cQuery)
			dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasSD1,.T.,.T.)

			lContinua := !(cAliasSD1)->(Eof())
			For nCntFor := 1 To Len(aStruSD1)
				If ( aStruSD1[nCntFor][2]!="C" )
					TCSetField(cAliasSD1,aStruSD1[nCntFor][1],aStruSD1[nCntFor][2],aStruSD1[nCntFor][3],aStruSD1[nCntFor][4])
				EndIf
			Next nCntFor
		Else
	#EndIf
		If (!MsSeek(cFilialSD1+SE1->E1_NUM+cSerie+SE1->E1_CLIENTE+SE1->E1_LOJA,.F.))
			lContinua := .F.
		EndIf
		#IFDEF TOP
		EndIf
		#EndIf
	aSemNota	:=	{}
	While ( !Eof() .And. cFilialSD1  == (cAliasSD1)->D1_FILIAL  .And.;
			SF1->F1_DOC 	 == (cAliasSD1)->D1_DOC	  .And.;
			SF1->F1_SERIE	 == (cAliasSD1)->D1_SERIE   .And.;
			SF1->F1_FORNECE == (cAliasSD1)->D1_FORNECE .And.;
			SF1->F1_LOJA	 == (cAliasSD1)->D1_LOJA )
		//===================================================================
		// Localiza a Nota de Saida - Item                              
		//===================================================================
		DBSelectArea("SD2")
		DBSetOrder(3)
		MsSeek(cFilialSD2+(cAliasSD1)->D1_NFORI+(cAliasSD1)->D1_SERIORI+(cAliasSD1)->D1_FORNECE+(cAliasSD1)->D1_LOJA+(cAliasSD1)->D1_COD+AllTrim((cAliasSD1)->D1_ITEMORI))
		If !SD2->(FOUND())
		   //===================================================================
		   // Carrega os items que nao tem nota original
		   //===================================================================
			aAdd(aSemNota,(cAliasSD1)->D1_ITEM)
		EndIf
		aBaseSD1 := {} // Inicializa Bases do Item
		
		//===================================================================
		// Posiciona no Nota Fiscal de Saida - Cabecalho                
		//===================================================================
		DBSelectArea("SF2")
		DBSetOrder(1)
		MsSeek(cFilialSF2+SD2->D2_DOC+SD2->D2_SERIE+SD2->D2_CLIENTE+SD2->D2_LOJA)
		If Empty(SF2->F2_PREFIXO)
			cPrefixo := AllTrim(Posicione("SX6",1,cFilialSF2+"MV_1DUPREF","X6_CONTEUD"))
			If Empty(cPrefixo) //Caso não exista o parametro na filial posicionada, pega o coteudo (GetMv)
				cPrefixo := &(GetMV("MV_1DUPREF"))
			EndIf
		Else
			cPrefixo := SF2->F2_PREFIXO
		EndIf
		
		//===================================================================
		// Posiciona no Titulo Financeiro                               
		//===================================================================
		DBSelectArea("SE1")
		DBSetOrder(2)
		MsSeek(cFilialSE1+SF2->F2_CLIENTE+SF2->F2_LOJA+cPrefixo+SD2->D2_DOC)
		While ( !Eof() .And. cFilialSE1  == SE1->E1_FILIAL .And.;
				SE1->E1_CLIENTE == SF2->F2_CLIENTE .And.;
				SE1->E1_LOJA    == SF2->F2_LOJA .And.;
				SE1->E1_PREFIXO == cPrefixo .And.;
				SE1->E1_NUM		 == SF2->F2_DOC )
			If ( SE1->E1_TIPO $ MVNOTAFIS+cEspSes )
				//===================================================================
				// Calcula o Valor da Comissao para a Parcela                   
				//===================================================================
				aBaseNCC := Fa440Comis(SE1->(Recno()),.F.,.T.,SD2->(RecNo()))
				For nCntFor := 1 To Len(aBaseNCC)
					cVendedor := aBaseNCC[nCntFor,1]
					nPos := aScan(aBaseSD1,{|x| x[1]==cVendedor})
					If ( nPos == 0 )
						aAdd(aBaseSD1,{ 	aBaseNCC[nCntFor,1],;
							aBaseNCC[nCntFor,2],;
							aBaseNCC[nCntFor,3],;
							aBaseNCC[nCntFor,4],;
							aBaseNCC[nCntFor,5],;
							aBaseNCC[nCntFor,6],;
							aBaseNCC[nCntFor,7]})
					Else
						aBaseSD1[nPos,2] += aBaseNCC[nCntFor,2]
						aBaseSD1[nPos,3] += aBaseNCC[nCntFor,3]
						aBaseSD1[nPos,4] += aBaseNCC[nCntFor,4]
						aBaseSD1[nPos,5] += aBaseNCC[nCntFor,5]
						aBaseSD1[nPos,6] += aBaseNCC[nCntFor,6]
					EndIf
				Next nCntFor
			EndIf
			DBSelectArea("SE1")
			DBSkip()
		EndDo
		
		//============================================================================
		// Aqui eh proporcionalizado as Bases da nota de saida com o item devol.  
		//============================================================================
		For nCntFor := 1 To Len(aBaseSD1)
			aBaseSD1[nCntFor,2] := NoRound(aBaseSD1[nCntFor,2]*((cAliasSD1)->D1_TOTAL-(cAliasSD1)->D1_VALDESC)/SD2->D2_TOTAL,nDecimal+1)
			aBaseSD1[nCntFor,3] := Round(aBaseSD1[nCntFor,3]*((cAliasSD1)->D1_TOTAL-(cAliasSD1)->D1_VALDESC)/SD2->D2_TOTAL,nDecimal+1)
			aBaseSD1[nCntFor,4] := NoRound(aBaseSD1[nCntFor,4]*((cAliasSD1)->D1_TOTAL-(cAliasSD1)->D1_VALDESC)/SD2->D2_TOTAL,nDecimal+1)
			aBaseSD1[nCntFor,5] := (aBaseSD1[nCntFor,5]*((cAliasSD1)->D1_TOTAL-(cAliasSD1)->D1_VALDESC)/SD2->D2_TOTAL)
			aBaseSD1[nCntFor,6] := NoRound(aBaseSD1[nCntFor,6]*((cAliasSD1)->D1_TOTAL-(cAliasSD1)->D1_VALDESC)/SD2->D2_TOTAL,nDecimal+1)
		Next nCntFor
		
		//============================================================================
		// Aqui eh somado as bases ja calculadas e como a NCC estorna os valores   
		// na emissao, adiciona-se a base da baixa na base da emissao.             
		//============================================================================
		For nCntFor := 1 To Len(aBaseSD1)
			cVendedor := aBaseSD1[nCntFor,1]
			nPos := aScan(aBAseSE1,{|x| x[1] == cVendedor })
			If ( nPos == 0 )
				aAdd(aBaseSE1,{ 	aBaseSD1[nCntFor,1],;
					aBaseSD1[nCntFor,2],;
					aBaseSD1[nCntFor,3]+aBaseSD1[nCntFor,4],0,;
					aBaseSD1[nCntFor,5]+aBaseSD1[nCntFor,6],0,0})
			Else
				aBaseSE1[nPos,2] += aBaseSD1[nCntFor,2]
				aBaseSE1[nPos,3] += aBaseSD1[nCntFor,3]+aBaseSD1[nCntFor,4]
				aBaseSE1[nPos,5] += aBaseSD1[nCntFor,5]+aBaseSD1[nCntFor,6]
			EndIf
		Next nCntFor
		DBSelectArea(cAliasSD1)
		DBSkip()
	EndDo
	If ( (Empty(aBaseSE1).Or. Len(aSemNota) > 0) .And. lRefaz .And. cPaisLoc<>"BRA")
		DBSelectArea("SE1")
		MsGoto(nRegistro)
		cSerie := If(Empty(SE1->E1_SERIE),SE1->E1_PREFIXO,SE1->E1_SERIE)
		DBSelectArea("SF1")
		DBSetOrder(1)
		If (!MsSeek(cFilialSF1+SE1->E1_NUM+cSerie+SE1->E1_CLIENTE+SE1->E1_LOJA,.F.))
			lContinua := .F.
		EndIf
		DBSelectArea("SE4")
		DBSetOrder(1)
		If (!MsSeek(cFilialSE4+SF1->F1_COND))
			lContinua := .F.
		EndIf
		DBSelectArea("SD1")
		DBSetOrder(1)
		#IFDEF TOP
			If ( TcSrvType()!="AS/400" )
				lQuery := .T.
				cAliasDev := "FA440COMIS"
				cAliasSF4 := "FA440COMIS"
				cQuery := ""
				For nCntFor := 1 To Len(aStruSD1)
					cQuery += ","+aStruSD1[nCntFor][1]
				Next nCntFor
				For nCntFor := 1 To Len(aStruSF4)
					cQuery += ","+aStruSF4[nCntFor][1]
				Next nCntFor

				cQuery := "SELECT SD1.R_E_C_N_O_ SD1RECNO,"+SubStr(cQuery,2)
				cQuery += "  FROM "+RetSqlName("SD1")+" SD1,"+RetSqlName("SF4")+" SF4 "
				cQuery += " WHERE SD1.D1_FILIAL   = '"+cFilialSD1+"'"
				cQuery += "   AND SD1.D1_DOC      = '"+SE1->E1_NUM+"'"
				cQuery += "   AND SD1.D1_SERIE    = '"+cSerie+"'"
				cQuery += "   AND SD1.D1_FORNECE  = '"+SE1->E1_CLIENTE+"'"
				cQuery += "   AND SD1.D1_LOJA	  = '"+SE1->E1_LOJA+"'"
				cQuery += "   AND SD1.D_E_L_E_T_  <>'*'"
				cQuery += "   AND SF4.F4_FILIAL   = '"+cFilialSF4+"'"
				cQuery += "   AND SF4.F4_CODIGO   = SD1.D1_TES"
				cQuery += "   AND SF4.D_E_L_E_T_<>'*' "
				cQuery += "ORDER BY "+SqlOrder(SD1->(IndexKey()))

				cQuery := ChangeQuery(cQuery)
				dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasDev)

				lContinua := !(cAliasDev)->(Eof())
				For nCntFor := 1 To Len(aStruSD1)
					If ( aStruSD1[nCntFor][2]!= "C" )
						TCSetField(cAliasDev,aStruSD1[nCntFor][1],aStruSD1[nCntFor][2],aStruSD1[nCntFor][3],aStruSD1[nCntFor][4])
					EndIf
				Next nCntFor
				For nCntFor := 1 To Len(aStruSF4)
					If ( aStruSF4[nCntFor][2]!="C" )
						TCSetField(cAliasSF4,aStruSF4[nCntFor][1],aStruSF4[nCntFor][2],aStruSD1[nCntFor][3],aStruSF4[nCntFor][4])
					EndIf
				Next nCntFor
			Else
		#EndIf
			If (!MsSeek(cFilialSD1+SE1->E1_NUM+cSerie+SE1->E1_CLIENTE+SE1->E1_LOJA,.F.))
				lContinua := .F.
			EndIf

			#IFDEF TOP
			EndIf
			#EndIf
		If ( lContinua )
			//===================================================================
			// Calculo da comissao por item de nota fiscal 			            |
			//																    |
			// 1)O Valor do icms s/ frete e adiciona ao campo F2_VALICM, por    |
			// esta razao deve-se somar o vlr do icms dos itens e subtrair      |
			// do total de icms (F2_VALICM) para apurar-se o vlr icms s/frete   |
			//																    | 
			// 2)O mesmo ocorre para o valor do IPI sobre frete, Por esta ra-   |
			// zao e' calculado o valor do IPI sobre frete do item multipli-    |
			// cando-se o valor do frete do item pelo % de ipi do item. 	    |
			//																    |
			// 3)O Valor do Icms Retido pode nÆo estar no total da nota (F2_-   |
			// VALBRUT) por isto deve-se considerar o campo (D2_ICMSRET).	    |
			//																    |
			// 4)O percentual da comissao dever ser considerado para cada i-    |
			// tem de nota fiscal pois ela pode ser diferente entre eles. O     |
			// percentual gravado no E1_COMIS ‚ sempre um valor aproximado e    |
			// nao deve ser considerado ser houver nota fiscal para o titulo.   |
			//																    |
			// 5)A Base da Comissao ‚ o valor da mercadoria + o valor do ipi    |
			// + o valor das despesas acessorias +  o icms solidario. Como e'   |
			// por item deve-se conhece-lo pelo item a item.				    |
			//===================================================================
			nTotal	  := 0
			nFrete	  := (SF1->F1_FRETE + SF1->F1_SEGURO + SF1->F1_DESPESA)
			nIcmFrete  := 0
			nSF2IcmRet :=0
			While ( !Eof() .And. (cAliasDev)->D1_FILIAL == cFilialSD1 .And.;
					(cAliasDev)->D1_DOC 	 == SE1->E1_NUM .And.;
					(cAliasDev)->D1_SERIE	 == cSerie .And.;
					(cAliasDev)->D1_FORNECE  == SE1->E1_CLIENTE .And.;
					(cAliasDev)->D1_LOJA	 == SE1->E1_LOJA	)

				If aScan(aSemNota,(cAliasDev)->D1_ITEM) ==0
					(cAliasDev)->(DBSkip())
					Loop
				EndIf

				If ( !lQuery )
					DBSelectArea("SF4")
					DBSetOrder(1)
					MsSeek(cFilialSF4+(cAliasDev)->D1_TES)
				Else
					If cPaisLoc<>"BRA"
						SD1->(DBGoTo((cAliasDev)->SD1RECNO))
					EndIf
				EndIf
				cVend := "1"

				cVendedor := SF1->F1_VEND1

				nImp := 0
				If cPaisLoc <> "BRA"
					SA3->(DBSetOrder(1))
					SA3->(DBSeek(xFilial()+cVendedor))
					aImp := TesImpInf(SD1->D1_TES)
					cImp := IIf( cPaisLoc <> "BRA" ,SA3->A3_COMIMP,"N")
					nPerComis := SA3->A3_COMIS
					For nX :=1 to Len(aImp)
						If (cImp+aImp[nX][3] == "S1")
							nImp += SD1->(FieldGet(FieldPos(aImp[nX][2])))
						ElseIf (cImp+aImp[nX][3] == "N2")
							nImp -= SD1->(FieldGet(FieldPos(aImp[nX][2]))	)
						EndIf
					Next
				EndIf

				If ( !Empty(cVendedor) .And. (cAliasSF4)->F4_DUPLIC == "S" )
					If (cAliasDev)->(FieldPos("D1_COMIS"+cVend)) > 0 .And.;
						(cAliasDev)->(FieldGet((cAliasDev)->(FieldPos("D1_COMIS"+cVend)))) > 0
						nPerComis := (cAliasDev)->(FieldGet((cAliasDev)->(FieldPos("D1_COMIS"+cVend))))
					EndIf
					aAdd(aSD2Vend,{ cVendedor,;
						(cAliasDev)->D1_TOTAL+nImp,;
						0,;
						0,;
						0,;
						(cAliasSF4)->F4_INCIDE,;
						(cAliasSF4)->F4_IPIFRET,;
						0,;
						nPerComis,;
						0,;
						If(lQuery,(cAliasDev)->SD1RECNO,(cAliasDev)->(RecNo()))})
				EndIf

				nTotal	  += (cAliasDev)->D1_TOTAL
				DBSelectArea(cAliasDev)
				DBSkip()
			EndDo
			If ( lQuery )
				DBSelectArea(cAliasDev)
				DBCloseArea()
				DBSelectArea("SD1")
			EndIf
			
			//===================================================================
			// Calculo da comissao pela nota.							        |
			//																    |
			// 1)Apos calculado as bases de cada vendedor por item de nota      |
			// deve-se aglutina-las formando uma unica base para toda a nota    |
			// fiscal.														    |
			//																    |
			// 2)Como os valores serao aglutinados pode-se haver perda de de-   |
			// cimais por isto deve-se haver um controle para que a perda se-   |
			// ja adicionada a primeira parcela da nota. 					    |
			//===================================================================
			nMaxFor := Len(aSD2Vend)
			nPerComis:=0
			For nCntFor := 1 To nMaxFor
				If ( lPeperCom )
					nPerComis := ExecBlock("FIN440PE",.F.,.F.,{aSD2Vend[nCntFor][1]})
					If ( ValType(nPerComis)<>"N" )
						nPerComis := aSD2Vend[nCntFor][9]
					EndIf
				EndIf
				If ( SE1->E1_PARCELA $ cPrimParc )
					nBaseDif  := NoRound(nFrete*(1-(aSD2Vend[nCntFor,2]/nTotal)),nDecimal+1)
					nBaseDif  := nFrete - nBaseDif
					nRatFrete := nBaseDif
				Else
					nRatFrete := NoRound(nFrete*aSD2Vend[nCntFor,2]/nTotal,nDecimal+1)
				EndIf
				nRatIcmFre:= 0
				nBaseSE1  := 0
				nPos		 := 0
				nRatIcmFre:= NoRound(nIcmFrete*aSD2Vend[nCntFor,2]/nTotal,nDecimal+1)
				nBaseSE1  := aSD2Vend[nCntFor,2]+aSD2Vend[nCntFor,4]+aSD2Vend[nCntFor,8]+nRatFrete
				DBSelectArea("SA3")
				DBSetOrder(1)
				MsSeek(xFilial()+aSD2Vend[nCntFor,1])

				nAlEmissao := SA3->A3_ALEMISS
				nAlBaixa := SA3->A3_ALBAIXA

				If ( SA3->A3_FRETE == "N" )
					nBaseSE1 -= ( nRatFrete )
				EndIf

				If (IsInCallStack("FINA070") .Or. IsInCallStack("FINA110")) .And. MV_PAR05 == 1 // Juros na Comissão
					nBaseBaix += nJuros
				EndIf

				If ( SA3->A3_ACREFIN == "N" ) .And. aSD2Vend[nCntFor,10] > 0
					nBaseSE1 -= ( aSD2Vend[nCntFor,10] )
				EndIf
				nPos := aScan(aBaseSE1,{|x| x[1] == aSD2Vend[nCntFor,1]})
				If AllTrim(SE1->E1_Hist) <> "VENDA EM DINHEIRO"
					nBaseBaix := Round(nBaseSE1*nAlBaixa/100,nDecimal+1) 	// Base da Comissao na Baixa
				Else
					nBaseBaix:= 0
				EndIf
				nBaseEmis := nBaseSE1-nBaseBaix											// Base da Comissao na Emissao
				nVlrEmis  := Round(nBaseEmis*aSD2Vend[nCntFor,9]/100,nDecimal+1) // Valor da Comissao na Emissao
				nVlrBaix  := Round(nBaseBaix*aSD2Vend[nCntFor,9]/100,nDecimal+1) // Valor da Comissao na Baixa
				If ( Empty(nRegDevol) .Or. nRegDevol == aSD2Vend[nCntFor,11] )
					If ( nPos == 0 )
						aAdd(aBaseSE1,{ aSD2Vend[nCntFor,1] ,;
							nBaseSE1				,;
							nBaseEmis				,;
							nBaseBaix				,;
							nVlrEmis				,;
							nVlrBaix				,;
							nPerComis		,;
							nPis,;
							nCsll,;
							nCofins})
					Else
						aBaseSE1[nPos,2] += nBaseSE1
						aBaseSE1[nPos,3] += nBaseEmis
						aBaseSE1[nPos,4] += nBaseBaix
						aBaseSE1[nPos,5] += nVlrEmis
						aBaseSE1[nPos,6] += nVlrBaix
						If aBaseSE1[nPos,7] == nPerComis
							aBaseSE1[nPos,7] := nPerComis
						Else
							aBaseSE1[nPos,7] := 0
						EndIf
					EndIf
				EndIf
			Next nCntFor
			
			//===================================================================
			// Calculo da comissao pelas parcelas.							    |
			//																    |
			// 1)O SE3 ‚ gravado por parcela e nao pela nota. assim e'neces-    |
			// sario calcular a base da comissao para a parcela em questao.     |
			//																    |
			// 2)Aqui deve-se tomar o maximo cuidado com a Condi‡Æo de pagto    |
			// pois se o Icms Solidario ou o Ipi For separado de alguma par-    |
			// cela deve-se considera esta separacao para calcular-se a me-     |
			// lhor propor‡ao possivel para a base da parcela. 				    |
			//===================================================================
			nMaxFor := Len(aBaseSE1)
			For nCntFor := 1 To nMaxFor
				nProp   := 0
				nVlrFat := xMoeda(SF1->F1_VALBRUT,SE1->E1_MOEDA,1,SE1->E1_EMISSAO)
				nVlrTit := SE1->E1_VLCRUZ
				DBSelectArea("SA3")
				DBSetOrder(1)
				MsSeek(xFilial()+aBaseSE1[nCntFor,1])
				If ( nVlrTit > 0 )
					nProp := nVlrFat / nVlrTit
				Else
					nProp := 0
				EndIf
				If (nProp != 0 )
					nBaseSE1 := NoRound(aBaseSE1[nCntFor,2]/nProp,nDecimal+1)
					nBaseEmis:= NoRound(aBaseSE1[nCntFor,3]/nProp,nDecimal+1)
					nBaseBaix:= NoRound(aBaseSE1[nCntFor,4]/nProp,nDecimal+1)
					nVlrEmis := Round(aBaseSE1[nCntFor,5]/nProp,nDecimal+1)
					nVlrBaix := Round(aBaseSE1[nCntFor,6]/nProp,nDecimal+1)
				Else
					nBaseSE1 := 0
					nBaseEmis:= 0
					nBaseBaix:= 0
					nVlrEmis := 0
					nVlrBaix := 0
				EndIf
				If ( SE1->E1_PARCELA $ cPrimParc .And. nBaseSE1 != 0 )
				    //===================================================================
					//--> Calculo da Proporcao para a Base da Comissao
					//===================================================================
					nBaseDif := Round(nBaseSE1 * nProp,nDecimal+1)
					nBaseDif := aBaseSE1[nCntFor,2]-nBaseDif
					aBaseSE1[nCntFor,2] := nBaseSE1+nBaseDif
					//===================================================================
					//--> Calculo da Proporcao para a Base da Comissao pela Emissao
                    //===================================================================
					nBaseDif := Round(nBaseEmis * nProp,nDecimal+1)
					nBaseDif := aBaseSE1[nCntFor,3]-nBaseDif
					aBaseSE1[nCntFor,3] := nBaseEmis+nBaseDif
					//===================================================================
					//--> Calculo da Proporcao para a Base da Comissao pela Baixa
                    //===================================================================
					nBaseDif := Round(nBaseBaix * nProp,nDecimal+1)
					nBaseDif := aBaseSE1[nCntFor,4]-nBaseDif
					aBaseSE1[nCntFor,4] := nBaseBaix+nBaseDif
					//===================================================================
					//--> Calculo da Proporcao para o Valor da Comissao pela Emissao
                    //===================================================================
					nBaseDif := Round(nVlrEmis * nProp,nDecimal+1)
					nBaseDif := aBaseSE1[nCntFor,5]-nBaseDif
					aBaseSE1[nCntFor,5] := nVlrEmis+nBaseDif
					//===================================================================
					//--> Calculo da Proporcao para o Valor da Comissao pela Baixa
                    //===================================================================
					nBaseDif := Round(nVlrBaix * nProp,nDecimal+1)
					nBaseDif := aBaseSE1[nCntFor,6]-nBaseDif
					aBaseSE1[nCntFor,6] := nVlrBaix+nBaseDif
				Else
					aBaseSE1[nCntFor,2] := nBaseSE1
					aBaseSE1[nCntFor,3] := nBaseEmis
					aBaseSE1[nCntFor,4] := nBaseBaix
					aBaseSE1[nCntFor,5] := nVlrEmis
					aBaseSE1[nCntFor,6] := nVlrBaix
				EndIf
			Next nCntFor
		Else
			If ( lQuery .And. Select(cAliasDev)<>0 )
				DBSelectArea(cAliasDev)
				DBCloseArea()
				DBSelectArea("SE1")
			EndIf
		EndIf
	EndIf
	If ( lQuery .And. Select(cAliasDev)<>0 )
		DBSelectArea(cAliasDev)
		DBCloseArea()
		DBSelectArea("SE1")
	EndIf
	If ( lQuery )
		DBSelectArea(cAliasSD1)
		DBCloseArea()
		DBSelectArea("SD1")
	EndIf
Else
	If Empty(nRegDevol)
		If ( Empty(aBaseSE1) .And. lRefaz )
			cVend := "1"
			For nCntFor := 1 To nVend
				nIRRF := 0
				SE1->(DBGoTo(nRecnoOrig)) // pra caso o titulo parta de uma liquidação
				cVendedor := SE1->(FieldGet(SE1->(FieldPos("E1_VEND"+cVend))))
				nPerComis := SE1->(FieldGet(SE1->(FieldPos("E1_COMIS"+cVend))))

				DBSelectArea("SE3")
				DBSetOrder(1)
				If DBSeek(xFilial("SE3")+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA)
                   //======================================================================================
				   // Verifica se o tipo da comissao bate com o tipo do titulo. Pode ocorrer dois titulos
				   // com o mesmo prefixo/numero/parcela/cliente/loja com tipos diferentes
				   //======================================================================================
					While 	SE3->( ! Eof() ) .And. ;
								SE3->( xFilial( "SE3" ) + E3_PREFIXO + E3_NUM + E3_PARCELA ) == ;
								SE1->( xFilial( "SE1" ) + E1_PREFIXO + E1_NUM + E1_PARCELA )
						If SE3->E3_TIPO == SE1->E1_TIPO .And.  SE1->(FieldGet(SE1->(FieldPos("E1_VEND"+cVend)))) ==  SE3->E3_VEND
							nPerComis := SE3->E3_PORC
							Exit
						EndIf
						SE3->( DBSkip() )
					EndDo

	            EndIf

	            MSUnLock()

				SE1->(DBGoTo(nRegistro)) // volta ao recno original

				DBSelectArea("SA3")
				DBSetOrder(1)
				MsSeek(xFilial()+cVendedor)
				If SE1->(FieldPos("E1_ALEMIS"+cVend))<>0//Nao criar no dicionario padrao
					nAlEmissao := SE1->(FieldGet(FieldPos("E1_ALEMIS"+cVend)))
				Else
					nAlEmissao := SA3->A3_ALEMISS
				EndIf
				If SE1->(FieldPos("E1_ALBAIX"+cVend))<>0//Nao criar no dicionario padrao
					nAlBaixa := SE1->(FieldGet(FieldPos("E1_ALBAIX"+cVend)))
				Else
					nAlBaixa := SA3->A3_ALBAIXA
				EndIf

				If ( !Empty(cVendedor) ) .And. !SE1->E1_TIPO $ MVABATIM
					If ( AllTrim(SE1->E1_Hist) <> "VENDA EM DINHEIRO" .And. !"LOJA"$SE1->E1_ORIGEM ) .OR.;		 //Adriano - Comissoes
						( AllTrim(SE1->E1_Hist) == "VENDA EM DINHEIRO" .And. (("LOJA"$SE1->E1_ORIGEM) .Or. "FATA701"$ SE1->E1_ORIGEM))
						If  lMultVend
							nBaseEmis := Round(SE1->(FieldGet(SE1->(FieldPos("E1_BASCOM"+cVend))))*(nAlEmissao/100),nDecimal+1)
							nBaseBaix := Round(SE1->(FieldGet(SE1->(FieldPos("E1_BASCOM"+cVend))))*(nAlBaixa/100),nDecimal+1)
						Else
							nBaseEmis := Round(SE1->E1_VLCRUZ*(nAlEmissao/100),nDecimal+1)
							nBaseBaix := Round(SE1->E1_VLCRUZ*(nAlBaixa/100),nDecimal+1)
						EndIf
					Else
						nBaseEmis := SE1->(FieldGet(SE1->(FieldPos("E1_BASCOM"+cVend))))
						nBaseBaix := nBaseEmis
						If "LOJA"$SE1->E1_ORIGEM .And. AllTrim(SE1->E1_Hist) <> "VENDA EM DINHEIRO"
                           //===================================================================
						   // Abate o percentual da administradora proporcionalmente
						   //===================================================================
							If cMvComisCC <> "N"
								nBaseCC := 1-((SE1->E1_VLRREAL - SE1->E1_VLCRUZ) / SE1->E1_VLRREAL)
							Else
								nBaseCC	:= 1
							EndIf

							If nAlEmissao > 0
								nBaseEmis := Round( (nBaseEmis * nBaseCC) * ( nAlEmissao / 100 ), nDecimal+1 )
								nBaseBaix := 0
							ElseIf nAlBaixa > 0
								nBaseEmis := 0
								nBaseBaix := Round( (nBaseBaix * nBaseCC) * ( nAlBaixa / 100 ), nDecimal+1 )
							EndIf
						EndIf
					EndIf
					If SuperGetMv("MV_COMISIR") == "N" .And. lRecIRRF
						nBaseEmis -= Round(SE1->E1_IRRF*(nAlEmissao/100),nDecimal+1)
						nBaseBaix -= Round(SE1->E1_IRRF*(nAlBaixa/100),nDecimal+1)
						nIRRF := Round(SE1->E1_IRRF*(nAlBaixa/100),nDecimal+1)
					EndIf
					If GetNewPar("MV_COMIINS","N") == "N"
						nBaseEmis -= Round(SE1->E1_INSS*(nAlEmissao/100),nDecimal+1)
						nBaseBaix -= Round(SE1->E1_INSS*(nAlBaixa/100),nDecimal+1)
					EndIf
					If  lPccBxCr .And. !lCalEmis
						If 	!(SE5->E5_PRETPIS	$	"1;2")
						 		nPis		:= SE5->E5_VRETPIS
						 Else
						 		nPis		:=	0
						 EndIf
						 If 	!(SE5->E5_PRETCOF	$	"1;2")
						 		nCofins	:= SE5->E5_VRETCOF
						 Else
						      nCofins	:= 0
						 EndIf
						 If 	!(SE5->E5_PRETCSL	$	"1;2")
						 		nCsll		:= SE5->E5_VRETCSL
						 Else
						 		nCsll		:=	0
						 EndIf
					ElseIf !lPccBxCr
						SumAbatRec( SE1->E1_PREFIXO,SE1->E1_NUM,SE1->E1_PARCELA,SE1->E1_MOEDA,'V', , ,,@nTotCsAbt,@nTotPisAbt,@nTotCofAbt)
						If nTotPisAbt > 0
							nPis		:= SE1->E1_PIS
						EndIf
						If nTotCofAbt > 0
							nCofins	:= SE1->E1_COFINS
						EndIf
						If nTotCsAbt > 0
							nCsll  	:= SE1->E1_CSLL
						EndIf
					EndIf

					If !lPccBxCr

						If GetNewPar("MV_COMIPIS","N") == "N"
							nBaseEmis -= Round(SE1->E1_PIS*(nAlEmissao/100),nDecimal+1)
							nBaseBaix -= Round(nPis*(nAlBaixa/100),nDecimal+1)
						EndIf
						If GetNewPar("MV_COMICOF","N") == "N"
							nBaseEmis -= Round(SE1->E1_COFINS*(nAlEmissao/100),nDecimal+1)
							nBaseBaix -= Round(nCofins*(nAlBaixa/100),nDecimal+1)
						EndIf
						If GetNewPar("MV_COMICSL","N") == "N"
							nBaseEmis -= Round(SE1->E1_CSLL*(nAlEmissao/100),nDecimal+1)
							nBaseBaix -= Round(nCsll*(nAlBaixa/100),nDecimal+1)
						EndIf
					EndIf
					If SA3->A3_ISS == "N" .Or. ( SA3->A3_ISS == "S"  .And.;
						SE1->E1_FRETISS=="1" .And. SuperGetMV("MV_VRETISS",.F.,0) < SE1->E1_ISS )// Abate o ISS da base
						nBaseEmis -= Round(SE1->E1_ISS*(nAlEmissao/100),nDecimal+1)
						nBaseBaix -= Round(SE1->E1_ISS*(nAlBaixa/100),nDecimal+1)
					EndIf

					If (IsInCallStack("FINA070") .Or. IsInCallStack("FINA110")) .And. MV_PAR05 == 1
						nBaseBaix += nJuros
					EndIf

					    If (!lComiLiq) .And. (IsInCallStack("FINA040") .Or. FunName()$ "FINA440|FATA701|LOJA701" .And. Empty(SE1->E1_NUMLIQ))
					     nVlrEmis  := Round(nBaseEmis * (nPerComis/100),nDecimal+1)
					     nVlrBaix  := Round(nBaseBaix * (nPerComis/100),nDecimal+1)
					    Else
					     nVlrEmis  := 0
					     nVlrBaix  := Round(nBaseBaix * (nPerComis/100),nDecimal+1)
					    EndIf

					    If (lComiliq)
					      nVlrEmis  := Round(nBaseEmis * (nPerComis/100),nDecimal+1)
					      nVlrBaix  := Round(nBaseBaix * (nPerComis/100),nDecimal+1)
					    EndIf

                    //======================================================================
					// --> quer dizer que já comissionou na liquidacao do titulo original
					//======================================================================
					If ( lComiLiq ) .And. !Empty(SE1->E1_NUMLIQ)
						If IsInCallStack("FA460CAN") .Or. ( FunName() == "FINA460" )
						//==========================================================================
						// Se "comiliq", considero comissao como se fosse na baixa e nao na emissao
						//==========================================================================
							nVlrEmis := nVlrBaix
							nBaseEmis:= nBaseBaix
						ElseIf !( FunName() == "FINA460" )
							nVlrBaix  	:= 0
							nBaseBaix	:= 0
						EndIf
					EndIf

					aAdd(aBaseSE1,{ cVendedor,;
						SE1->E1_VLCRUZ,;
						nBaseEmis,;
						nBaseBaix,;
						nVlrEmis,;
						nVlrBaix,;
						nPerComis	,;
						nPis			,;
						nCsll			,;
						nCofins, ;
						nIRRF })
				EndIf
				cVend := Soma1(cVend,1)
			Next nCntFor
		EndIf
		If ( lGrava .And. lRefaz ).AND. !"LOJA"$SE1->E1_ORIGEM
			DBSelectArea("SE1")
			RecLock("SE1")
			cVend := "1"
			For nCntFor := 1 To Len(aBaseSE1)
				DBSelectArea("SA3")
				DBSetOrder(1)
				MsSeek(xFilial()+aBaseSE1[nCntFor,1])
				DBSelectArea("SE1")
				If ( FieldGet(FieldPos("E1_VEND"+cVend)) == aBaseSE1[nCntFor,1] )
					FieldPut(FieldPos("E1_BASCOM"+cVend),aBaseSE1[nCntFor,2])
					If ( aBaseSE1[nCntFor,4] != 0 )
						FieldPut(FieldPos("E1_COMIS"+cVend),aBaseSE1[nCntFor,7])
					EndIf
					FieldPut(FieldPos("E1_VALCOM"+cVend),aBaseSE1[nCntFor,5])
					If cPaisLoc == "PTG"
			   			FieldPut(FieldPos("E1_BASCOM"+cVend),aBaseSE1[nCntFor,12])
			   			FieldPut(FieldPos("E1_VALCOM"+cVend),aBaseSE1[nCntFor,11])
					EndIf
				Else
					If ( SE1->(FieldPos("E1_VEND"+cVend)) != 0 )
						nCntFor--
					EndIf
				EndIf
				cVend := Soma1(cVend,1)
			Next nCntFor
			MSUnLock()
		EndIf
		If ( Empty(aBaseSE1) )
			cVend := "1"
			For nCntFor := 1 To nVend
				nIRRF := 0
				cVendedor := SE1->(FieldGet(SE1->(FieldPos("E1_VEND"+cVend))))
				nPerComis := SE1->(FieldGet(SE1->(FieldPos("E1_COMIS"+cVend))))
				DBSelectArea("SA3")
				DBSetOrder(1)
				MsSeek(xFilial()+cVendedor)
				If ( !Empty(cVendedor) )
				    //======================================================================================
					// Trazer a base gravada na emissao, substituindo o zero, para evitar valores negativos
					//====================================================================================== 
					If SA3->A3_ALBAIXA > 0
						nBaseSE1  := SE1->(FieldGet(FieldPos("E1_BASCOM" + "1"))) * (SA3->A3_ALBAIXA / 100)
						nBaseEmis := SE1->(FieldGet(FieldPos("E1_BASCOM" + "1"))) - (SE1->(FieldGet(FieldPos("E1_BASCOM" + "1"))) * (SA3->A3_ALBAIXA / 100))
						nBaseBaix := SE1->(FieldGet(SE1->(FieldPos("E1_BASCOM"+cVend)))) * (SA3->A3_ALBAIXA / 100)
						nVlrEmis  := SE1->(FieldGet(FieldPos("E1_BASCOM" + "1"))) - (SE1->(FieldGet(FieldPos("E1_BASCOM" + "1"))) * (SA3->A3_ALBAIXA / 100))
					Else
						nBaseSE1  := SE1->(FieldGet(FieldPos("E1_BASCOM" + "1")))
						nBaseEmis := 0
						nBaseBaix := SE1->(FieldGet(SE1->(FieldPos("E1_BASCOM"+cVend)))) * (SA3->A3_ALBAIXA / 100)
						nVlrEmis  := 0
					EndIf
					//===================================================================
					// --> Quando o percentual da comissao estiver no produto o sistema
					// --> arredonda o percentual se For pago na baixa, caso haja muita
					// --> distorcao de valores deve-se alterar o numero de casas
					// --> decimais do campo E1_COMIS1..E1_COMIS(n)
					//===================================================================
					If  lPccBxCr .And. !lCalEmis
						If !(SE5->E5_PRETPIS $	"1;2")
							nPis		:= SE5->E5_VRETPIS
						Else
							nPis		:=	0
						EndIf
						If !(SE5->E5_PRETCOF	$	"1;2")
							nCofins	:= SE5->E5_VRETCOF
						Else
							nCofins	:= 0
						EndIf
						If !(SE5->E5_PRETCSL $	"1;2")
							nCsll		:= SE5->E5_VRETCSL
						Else
							nCsll		:=	0
						 EndIf
					Else
					 	 nPis			:= SE1->E1_PIS
					 	 nCofins		:= SE1->E1_COFINS
					 	 nCsll		:= SE1->E1_CSLL
					EndIf
					If SuperGetMv("MV_COMISIR") == "N" .And. !lMata460
						nBaseSE1 -= SE1->E1_IRRF
						nBaseBaix -= SE1->E1_IRRF
						nIRRF	:= SE1->E1_IRRF
					EndIf
					If GetNewPar("MV_COMIINS","N") == "N" .And. !lMata460
						nBaseSE1 -= SE1->E1_INSS
						nBaseBaix -= SE1->E1_INSS
					EndIf
					If !lPccBxCr
						If GetNewPar("MV_COMIPIS","N") == "N" .And. !lMata460
							nBaseSE1 -= SE1->E1_PIS
							nBaseBaix -= nPis
						EndIf
						If GetNewPar("MV_COMICOF","N") == "N" .And. !lMata460
							nBaseSE1 -= SE1->E1_COFINS
							nBaseBaix -= nCofins
						EndIf
						If GetNewPar("MV_COMICSL","N") == "N" .And. !lMata460
							nBaseSE1 -= SE1->E1_CSLL
							nBaseBaix -= nCsll
						EndIf
					EndIf
					If SA3->A3_ISS == "N" .Or. ( SA3->A3_ISS == "S" .And.;
						SE1->E1_FRETISS=="1" .And. SuperGetMV("MV_VRETISS",.F.,0) < SE1->E1_ISS )// Abate o ISS da base
						nBaseEmis -= Round(SE1->E1_ISS*(SA3->A3_ALEMISS/100),nDecimal+1)
						nBaseBaix -= Round(SE1->E1_ISS*(SA3->A3_ALBAIXA/100),nDecimal+1)
					EndIf

					If (IsInCallStack("FINA070") .Or. IsInCallStack("FINA110")) .And. MV_PAR05 == 1
						nBaseBaix += nJuros
					EndIf

					nVlrBaix  := nBaseBaix * (nPerComis/100)
					
					//===============================================================================================================================
					// No segundo elemento, a variavel nBaseSE1 foi substituida pelo campo SE1->E1_VLCRUZ (base bruta), pois apenas passava valores
					// negativos
					//===============================================================================================================================
					aAdd(aBaseSE1,{ cVendedor,;
						SE1->E1_VLCRUZ,;
						nBaseEmis,;
						nBaseBaix,;
						nVlrEmis,;
						nVlrBaix,;
						nPerComis,;
						nPis		,;
						nCsll		,;
						nCofins, ;
						nIRRF})
				EndIf
				cVend := Soma1(cVend,1)
			Next nCntFor
		EndIf
	EndIf
EndIf

//=================================================================== 
// Restaura a Integridade dos dados de Entrada                  
//===================================================================
FWRestArea(aAreaSE1)
FWRestArea(aAreaSE4)
FWRestArea(aAreaSF1)
FWRestArea(aAreaSF2)
FWRestArea(aAreaSF4)
FWRestArea(aAreaSD1)
FWRestArea(aAreaSD2)
FWRestArea(aAreaSA1)
FWRestArea(aAreaSA3)
FWRestArea(aArea)

Return(aBaseSE1)
