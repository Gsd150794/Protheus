/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "FISR020.CH"
/*
===============================================================================================================================
Programa----------: RFIS009
Autor-------------: Igor Melgaço
Data da Criacao---: 24/10/2022
Descrição---------: Impressão do relatório de conferência SPED-PIS/COFINS. Chamado 41042
Parametros--------: Nenhum
Retorno-----------: .T.
===============================================================================================================================
*/
User Function RFIS009()
Local	cNomWiz			:=	""
Local	aWizard			:=	{}    

Private	lEnd 			:= .F.

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Chamada para o Wizard da rotina³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

If TRepInUse()
	cNomWiz			:=	"FSR020"
	If !(MontWiz(cNomWiz))
		Return	//Se o wizard For cancelado aborto o processamento.
	EndIf
	If (!xMagLeWiz(cNomWiz, @aWizard, .T. ))
		Return	//Se por algum motivo a leitura do CFP falhar aborto a rotina.
	EndIf
	PrcFisr20(aWizard )
Else
	MsgInfo(STR0669) //"Opção somente disponível na versão personalizável"
EndIf

Return

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Programa  |PrcFisr20   ³ Autor ³Caio Oliveira	    ³ Data ³14.04.2012³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Processamento do Relatório                                 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Observacao³Processamento do relatório de conferência SPED-PIS/COFINS	  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros|aWizard - Contém o resultado da Wizard                      ³±±
±±³          ³                                                            ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Static Function PrcFisr20(aWizard)

Local nI			:=	0
Local nArqVal		:=	0
Local cPer			:= ""
Local lEnd			:= .F.
Local lDetalhado	:= .F.
Local oReport    
Local lAutomato 	:= .F.
Local aRetAuto		:= {}

//--------------------------------------------------------------------------------
// Altera o escopo das variáveis para Private para conseguir efetuar a impressão 
// do relatório via ReportPrint()através do método do TestCase UTStartRpt()
//--------------------------------------------------------------------------------
Private	cFile		:=	""
Private aRegra		:=	{}
Private aStrCmps	:=	{}
Private aTitulo		:=	{}
Private aTrbs		:=	{}

If FindFunction( "GetParAuto" )
	aRetAuto := GetParAuto( "FISR020TESTCASE" )
	lAutomato := IIf( ValType(aRetAuto) == "A" .And. Len( aRetAuto ) > 0, .T., .F. ) 
	If lAutomato
		aWizard := aRetAuto[1] 
	EndIf 
EndIf

lDetalhado := IIf(SubStr(aWizard[1][2],1,1) == "1",.T.,.F.)

If lDetalhado
	//Tratamento do legado imprimindo informações detalhadas	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Chamada para o Wizard da rotina³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If !lAutomato
		Processa({|lEnd| aTrbs := LeTxt(@aRegra,@aStrCmps,@aTitulo,aWizard,@nArqVal,@cFile)},,,.T.)
	Else
		aTrbs := LeTxt(@aRegra,@aStrCmps,@aTitulo,aWizard,@nArqVal,@cFile)
	EndIf
	
	If nArqVal==0
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Interface de impressao                                                  ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		oReport := ReportDef(aTrbs,aRegra,aStrCmps,aTitulo,cFile)
		If !lAutomato
			oReport:PrintDialog()
		EndIf
		
	ElseIf nArqVal==1 .And. !lAutomato
		xMagHelpFis(STR0008,STR0009,STR0010)	//"Atenção"###"Arquivo texto base para a geração deste relatório de conferência é incompatível com a estrutura definida para o EFD-PIS/COFINS."###"Selecione um arquivo válido para utilização desta rotina. Este arquivo deve ser gerado de acordo com as implementações do boletim técnico da rotina."			
	ElseIf nArqVal==2 .And. !lAutomato
		xMagHelpFis(STR0008,STR0011,STR0010)	//"Atenção"###"Arquivo inexistente no diretório especificado."###"Selecione um arquivo válido para utilização desta rotina. Este arquivo deve ser gerado de acordo com as implementações do boletim técnico da rotina."
	EndIf
	If !lAutomato		
		For nI:= 1 To Len( aTrbs )
			If File( aTrbs[ni,1] + GetDBExtension() )
				DBSelectArea( aTrbs[ni,2] )
				DBCloseArea()
				Ferase( aTrbs[ni,1] + GetDBExtension() )
				Ferase( aTrbs[ni,1] + OrdBagExt() )
			EndIf	
		Next
	EndIf
Else
	//Tratamento do relatório Sintético.
	oReport := ReportDef2()
	If File( aWizard[1][1] )
		SntCriaTab()	
		Processa({|lEnd| ProcArqSnt(aWizard[1][1],@cPer,@lEnd)},,,.T.)		
		If !lEnd
			oReport:SetTitle(STR0762  +  cPer)//"Conferência EFD PIS/COFINS - Período: "	
			If !lAutomato
				oReport:PrintDialog()
			EndIf
		EndIf		
	Else 
		If !lAutomato
			xMagHelpFis(STR0008,STR0011,STR0010)	//"Atenção"###"Arquivo inexistente no diretório especificado."###"Selecione um arquivo válido para utilização desta rotina. Este arquivo deve ser gerado de acordo com as implementações do boletim técnico da rotina."
		Else 
			Help(,,"NOARQ",,STR0011+STR0010,1,0) //"Atenção"###"Arquivo inexistente no diretório especificado."###"Selecione um arquivo válido para utilização desta rotina. Este arquivo deve ser gerado de acordo com as implementações do boletim técnico da rotina."
		EndIf
	EndIf	
EndIf

Return oReport

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Programa  |MontWiz   ³ Autor ³Igor Franzoi   		³ Data ³14.03.2012³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ MONTAGEM DO WIZARD                                         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Observacao³Funcao que monta o Wizard em tela para processamento.       ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Nivel Hier³Nenhum                                                      ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³lRet -> .T. se o wizard foi finalizado com sucesso ou .F. se³±±
±±³          ³ foi cancelado.                                             ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros|cNomWiz - Nome da Wizard utilizado para gravar o arquivo    ³±±
±±³          ³ com o preenchido pelo usuário                              ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Static Function MontWiz( cNomWiz )

Local	aTxtApre	:=	{}
Local	aPaineis	:=	{}
Local	cTitObj1	:=	""
Local	cTitObj2	:=	""
Local	lRet		:=	.T.

aAdd (aTxtApre, STR0001)	//"Parametros necessarios."
aAdd (aTxtApre, "")	
aAdd (aTxtApre, STR0002)	//"Preencha corretamente as informacoes solicitadas."
aAdd (aTxtApre, STR0003)	//"Informacoes necessarias para a impressão de um relatório de conferência do SPED - PIS/COFINS, baseado no arquivo texto já gerado."
	
aAdd (aPaineis, {})
nPos	:=	Len (aPaineis)
aAdd (aPaineis[nPos], STR0004)	//"Preencha corretamente as informacoes solicitadas."
aAdd (aPaineis[nPos], STR0005)	//"Parametros para Geração"
aAdd (aPaineis[nPos], {})


aAdd (aPaineis[nPos][3], {0,"",,,,,,});							aAdd (aPaineis[nPos][3], {0,"",,,,,,})

aAdd (aPaineis[nPos][3], {0,"",,,,,,});							aAdd (aPaineis[nPos][3], {0,"",,,,,,})

cTitObj1	:=	STR0006;											cTitObj2	:=	Replicate("X",100)	//"Informe o Arquivo origem"
aAdd (aPaineis[nPos][3], {1, cTitObj1,,,,,,});					aAdd (aPaineis[nPos][3], {2,,cTitObj2,1,,,,100,,.T.})

aAdd (aPaineis[nPos][3], {0,"",,,,,,});							aAdd (aPaineis[nPos][3], {0,"",,,,,,})

cTitObj1	:= "Tipo do Relatório"
aAdd (aPaineis[nPos][3], {1, cTitObj1,,,,,,})				
//
aItens1	:=	{}		
aAdd (aItens1, "1-Detalhado")
aAdd (aItens1, "2-Sintético")
																	
aAdd (aPaineis[nPos][3], {3,,,,,aItens1,,})						
//
aAdd (aPaineis[nPos][3], {0,"",,,,,,})

lRet	:=	xMagWizard (aTxtApre, aPaineis, cNomWiz)

Return (lRet)

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Programa  |ReportDef ³ Autor ³ Igor Franzoi          ³ Data ³13.03.2012³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³Funcao de definicao dos objetos do relatorio.               |±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³oReport -> Objeto do TReport.                               ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros|aTrbs -> Arquivos de trabalho utilizado na rotina.          ³±±
±±³          |aRegra -> Array contendo as regras para geracao dos registros³±±
±±³          |aStrCmps -> Array contendo a estrutura das celulas          ³±±
±±³          |aTitulos -> Array contendo os labels e pictures das celulas ³±±
±±³          |cFile    -> Nome do arquivo a ser importado                 ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/ 
Static Function ReportDef(aTrbs,aRegra,aStrCmps,aTitulo,cFile)

Local	oReport
Local	aReg	:=	{}
Local	nI		:=	0
Local	nY		:=	0
Local	nX		:=	0
Local	nZ		:=	0
Local	nA		:=	0
Local	nB		:=	0
Local	nC		:=	0
Local	nD		:=	0
Local	nCont	:=	0
Local	nTam	:=	0
Local	nPos1	:=	0
Local	nPosPai	:=	0
Local	nPosReg	:=	0
Local	nPosReg2:=	0
Local	nPosReg3:=	0
Local	nPosReg4:=	0
Local	nPosReg5:=	0
Local	nPosReg6:=	0
Local	nPosReg7:=	0
Local	nPosPai2:=	0
Local	nPosPai3:=	0
Local 	nPosPai4:=	0
Local	nPosPai5:=	0
Local	nPosPai6:=	0

oReport	:=	TReport():New("FISR020",noacento(OemToAnsi(STR0012)),"", {|oReport| ReportPrint(oReport,aRegra,aTitulo,cFile,aTrbs,aStrCmps)},noacento(OemToAnsi(STR0013))/*,,,,,,,,1*/)	//"Conferência SPED - PIS/COFINS"###"Este relatório tem o objetivo de possibiliar de forma gráfica a conferência das informações que serão enviadas ao fisco."
oReport:SetLandscape()
oReport:nLogPxXDiff := 0.50		

For nX := 1 To Len(aTitulo)
	cReg	:=	SubStr(aTitulo[nX][1],1,4)
	nCont	:=	aScan(aTrbs,{|x| x[3] == cReg })
	cAlias	:=	aTrbs[nCont,02]	

	DBSelectArea(cAlias)
	If (nPosReg	:=	aScan(aRegra,{|aX| aX[1]==cReg}))>0
		aAdd( aReg, TRSection():New(oReport,noacento(OemToAnsi(aTitulo[nX][1])),{cAlias},{STR0014},/*Campos do SX3*/,/*Campos do SIX*/,,,,,,,,,1,,,,,,,) )
		aReg[Len(aReg)]:SetNoFilter({cAlias})		
		// Para uso futuro - utilizado para imprimir por coluna.
		//
		//aReg[Len(aReg)]:SetLineStyle(.T.)
		//aReg[Len(aReg)]:SetCols(nCols)				
		nPosPai	:=	Len(aReg)
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³PRIMEIRO NIVEL³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		For nI := 1 To Len(aTitulo[nX][2])
			nPos1	:=	aScan(aStrCmps[nX], {|aX| aX[1]==FieldName(nI)})
	    	nTam	:=	aStrCmps[nX][nPos1][3]			    	
	    	TRCell():New(aReg[Len(aReg)],noacento(FieldName(nI)),cAlias,noacento(aTitulo[nX][2][nI][1]),noacento(aTitulo[nX][2][nI][2]),	nTam,/*lPixel*/,&("{|| "+cAlias+"->"+FieldName( nI )+"}"),,,,,1, .T.)
		Next nI
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³SEGUNDO NIVEL³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If Len(aRegra[nPosReg])>1
			For nY := 2 To Len(aRegra[nPosReg])
				cReg	:=	aRegra[nPosReg][nY][1]
				
				If (nPosReg2 := aScan(aTitulo,{|aX| SubStr(aX[1],1,4)==cReg}))>0
					nCont	:=	aScan(aTrbs,{|x| x[3] == cReg })
					cAlias	:=	aTrbs[nCont,02]
					DBSelectArea(cAlias)
					
					aAdd( aReg, TRSection():New(aReg[nPosPai],noacento(OemToAnsi(aTitulo[nPosReg2][1])),{cAlias},/*{Array com as ordens do relatório}*/,/*Campos do SX3*/,/*Campos do SIX*/,,,,,,,,,1,,,,,,,)) 
					aReg[Len(aReg)]:NLEFTMARGIN := 4
					nPosPai2:=	Len(aReg)
	
					For nI := 1 To Len(aTitulo[nPosReg2][2])
						nPos1	:=	aScan(aStrCmps[nPosReg2], {|aX| aX[1]==FieldName(nI)})
				    	nTam	:=	aStrCmps[nPosReg2][nPos1][3]	

				    	TRCell():New(aReg[Len(aReg)],noacento(FieldName(nI)),cAlias,noacento(aTitulo[nPosReg2][2][nI][1]),noacento(aTitulo[nPosReg2][2][nI][2]),	nTam,/*lPixel*/,&("{|| "+cAlias+"->"+FieldName( nI )+"}"),,,,,1,.T.)
					Next nI
					//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
					//³TERCEIRO NIVEL³
					//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
					If Len(aRegra[nPosReg][nY])>1
						For nZ := 2 To Len(aRegra[nPosReg][nY])
							cReg	:=	aRegra[nPosReg][nY][nZ][1]
							
							If (nPosReg3 := aScan(aTitulo,{|aX| SubStr(aX[1],1,4)==cReg}))>0
								nCont	:=	aScan(aTrbs,{|x| x[3] == cReg })
								cAlias	:=	aTrbs[nCont,02]
				
								DBSelectArea(cAlias)
								
								aAdd( aReg, TRSection():New(aReg[nPosPai2],noacento(OemToAnsi(aTitulo[nPosReg3][1])),{cAlias},/*{Array com as ordens do relatório}*/,/*Campos do SX3*/,/*Campos do SIX*//*,,,,,,,,,1,,,,,,,*/))
								aReg[Len(aReg)]:NLEFTMARGIN := 8
								nPosPai3:=	Len(aReg)
				
								For nI := 1 To Len(aTitulo[nPosReg3][2])
									nPos1	:=	aScan(aStrCmps[nPosReg3], {|aX| aX[1]==FieldName(nI)})
							    	nTam	:=	aStrCmps[nPosReg3][nPos1][3]	
								    	
							    	TRCell():New(aReg[Len(aReg)],noacento(FieldName(nI)),cAlias,noacento(aTitulo[nPosReg3][2][nI][1]),noacento(aTitulo[nPosReg3][2][nI][2]),	nTam,/*lPixel*/,&("{|| "+cAlias+"->"+FieldName( nI )+"}")/*,,,,,1,.T.*/)
								Next nI
								//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
								//³QUARTO NIVEL  ³
								//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
								If Len(aRegra[nPosReg][nY][nZ])>1
									For nA := 2 To Len(aRegra[nPosReg][nY][nZ])
										cReg	:=	aRegra[nPosReg][nY][nZ][nA][1]
										
										If (nPosReg4 := aScan(aTitulo,{|aX| SubStr(aX[1],1,4)==cReg}))>0
											nCont	:=	aScan(aTrbs,{|x| x[3] == cReg })
											cAlias	:=	aTrbs[nCont,02]
							
											DBSelectArea(cAlias)
											
											aAdd( aReg, TRSection():New(aReg[nPosPai3],noacento(OemToAnsi(aTitulo[nPosReg4][1])),{cAlias},/*{Array com as ordens do relatório}*/,/*Campos do SX3*/,/*Campos do SIX*//*,,,,,,,,,1,,,,,,,*/))
											aReg[Len(aReg)]:NLEFTMARGIN := 12
											nPosPai4:=	Len(aReg)											
							
											For nI := 1 To Len(aTitulo[nPosReg4][2])
												nPos1	:=	aScan(aStrCmps[nPosReg4], {|aX| aX[1]==FieldName(nI)})
										    	nTam	:=	aStrCmps[nPosReg4][nPos1][3]	
											    	
										    	TRCell():New(aReg[Len(aReg)],noacento(FieldName(nI)),cAlias,noacento(aTitulo[nPosReg4][2][nI][1]),noacento(aTitulo[nPosReg4][2][nI][2]),	nTam+1,/*lPixel*/,&("{|| "+cAlias+"->"+FieldName( nI )+"}")/*,,,,,1,.T.*/)
											Next nI
											//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
											//³QUINTO NIVEL  ³
											//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ											
											If Len(aRegra[nPosReg][nY][nZ][nA])>1
												For nB := 2 To Len(aRegra[nPosReg][nY][nZ][nA])
													cReg	:=	aRegra[nPosReg][nY][nZ][nA][nB][1]
													
													If (nPosReg5 := aScan(aTitulo,{|aX| SubStr(aX[1],1,4)==cReg}))>0
														nCont	:=	aScan(aTrbs,{|x| x[3] == cReg })
														cAlias	:=	aTrbs[nCont,02]
										
														DBSelectArea(cAlias)
														
														aAdd( aReg, TRSection():New(aReg[nPosPai4],noacento(OemToAnsi(aTitulo[nPosReg5][1])),{cAlias},/*{Array com as ordens do relatório}*/,/*Campos do SX3*/,/*Campos do SIX*//*,,,,,,,,,1,,,,,,,*/))
														aReg[Len(aReg)]:NLEFTMARGIN := 16
														nPosPai5:=	Len(aReg)														
										
														For nI := 1 To Len(aTitulo[nPosReg5][2])
															nPos1	:=	aScan(aStrCmps[nPosReg5], {|aX| aX[1]==FieldName(nI)})
													    	nTam	:=	aStrCmps[nPosReg5][nPos1][3]	
														    	
													    	TRCell():New(aReg[Len(aReg)],noacento(FieldName(nI)),cAlias,noacento(aTitulo[nPosReg5][2][nI][1]),noacento(aTitulo[nPosReg5][2][nI][2]),	nTam+1,/*lPixel*/,&("{|| "+cAlias+"->"+FieldName( nI )+"}")/*,,,,,1,.T.*/)
														Next nI
														//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
														//³SEXTO  NIVEL  ³
														//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
														If Len(aRegra[nPosReg][nY][nZ][nA][nB])>1
															For nC := 2 To Len(aRegra[nPosReg][nY][nZ][nA][nB])
																cReg	:=	aRegra[nPosReg][nY][nZ][nA][nB][nC][1]
																
																If (nPosReg6 := aScan(aTitulo,{|aX| SubStr(aX[1],1,4)==cReg}))>0
																	nCont	:=	aScan(aTrbs,{|x| x[3] == cReg })
																	cAlias	:=	aTrbs[nCont,02]
													
																	DBSelectArea(cAlias)

																	aAdd( aReg, TRSection():New(aReg[nPosPai5],noacento(OemToAnsi(aTitulo[nPosReg6][1])),{cAlias},/*{Array com as ordens do relatório}*/,/*Campos do SX3*/,/*Campos do SIX*//*,,,,,,,,,1,,,,,,,*/))
																	aReg[Len(aReg)]:NLEFTMARGIN := 20
																	nPosPai6:=	Len(aReg)														
													
																	For nI := 1 To Len(aTitulo[nPosReg6][2])
																		nPos1	:=	aScan(aStrCmps[nPosReg6], {|aX| aX[1]==FieldName(nI)})
																    	nTam	:=	aStrCmps[nPosReg6][nPos1][3]	
																	    	
																    	TRCell():New(aReg[Len(aReg)],noacento(FieldName(nI)),cAlias,noacento(aTitulo[nPosReg6][2][nI][1]),noacento(aTitulo[nPosReg6][2][nI][2]), nTam+1,/*lPixel*/,&("{|| "+cAlias+"->"+FieldName( nI )+"}")/*,,,,,1,.T.*/)
																	Next nI

																	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
																	//³SETIMO NIVEL  ³
																	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
																	If Len(aRegra[nPosReg][nY][nZ][nA][nB][nC])>1
																		For nD := 2 To Len(aRegra[nPosReg][nY][nZ][nA][nB][nC])
																			cReg	:=	aRegra[nPosReg][nY][nZ][nA][nB][nC][nD][1]
																		
																			If (nPosReg7 := aScan(aTitulo,{|aX| SubStr(aX[1],1,4)==cReg}))>0
																				nCont	:=	aScan(aTrbs,{|x| x[3] == cReg })
																				cAlias	:=	aTrbs[nCont,02]
														
																				DBSelectArea(cAlias)
        		                                        	
																				aAdd( aReg, TRSection():New(aReg[nPosPai6],noacento(OemToAnsi(aTitulo[nPosReg7][1])),{cAlias},/*{Array com as ordens do relatório}*/,/*Campos do SX3*/,/*Campos do SIX*//*,,,,,,,,,1,,,,,,,*/))
																				aReg[Len(aReg)]:NLEFTMARGIN := 20
														        	
																				For nI := 1 To Len(aTitulo[nPosReg7][2])
																					nPos1	:=	aScan(aStrCmps[nPosReg7], {|aX| aX[1]==FieldName(nI)})
																			    	nTam	:=	aStrCmps[nPosReg7][nPos1][3]	
																		    	
																			    	TRCell():New(aReg[Len(aReg)],noacento(FieldName(nI)),cAlias,noacento(aTitulo[nPosReg7][2][nI][1]),noacento(aTitulo[nPosReg7][2][nI][2]),nTam+1,/*lPixel*/,&("{|| "+cAlias+"->"+FieldName( nI )+"}")/*,,,,,1,.T.*/)
																				Next nI																																																																		
																			EndIf																
																		Next nD																	
																																																
																	EndIf																
																EndIf																
															Next nC													
														EndIf																											
													EndIf
												Next nB
											EndIf											
										EndIf
									Next nA
								EndIf								
							EndIf        	
						Next nZ
					EndIf
				EndIf
			Next nY
		EndIf
	EndIf
Next nX

Return oReport

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Programa  |ReportPrint³ Autor ³ Igor Franzoi         ³ Data ³14.03.2012³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³Funcao de processamento e armazenamento dos conteudos a serem|±±
±±³          ³ impressos.                                                 |±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³oReport -> Objeto do TReport.                               ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros|oReport -> Objeto do TReport.                               ³±±
±±³          |aRegra -> Array contendo as regras para geracao dos registros³±±
±±³          |aTitulos -> Array contendo os labels e pictures das celulas ³±±
±±³          |aTrbs    -> Array contendo os Arquivos de trabalho          ³±±
±±³          |aStrCmps -> Array contendo os Campos dos arquivos           ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Static Function ReportPrint(oReport,aRegra,aTitulo,cFile,aTrbs,aStrCmps)
Local	nX			:=	0
Local	nY			:=	0
Local	nZ			:=	0		
Local	nA			:=	0
Local	nB			:=	0
Local	nC			:=	0
Local	nD			:=	0
Local	nCont		:=	0
Local	nPosReg		:=	0
Local	nPosReg2	:=	0
Local	nPosReg3	:=	0
Local	nPosReg4	:=	0
Local	nPosReg5	:=	0
Local	nPosReg6	:=	0
Local	nPosReg7	:=	0
Local	cAlias		:=	""
Local	cAlias2		:=	""
Local	cAlias3		:=	""
Local	cAlias4		:=	""
Local	cAlias5		:=	""
Local	cAlias6		:=	""
Local	cAlias7		:=	""
Local	cReg		:=	""
Local	b2Relation	:=	{||}
Local	b2ParFilter	:=	{||}
Local	b3Relation	:=	{||}
Local	b3ParFilter	:=	{||}
Local	b4Relation	:=	{||}
Local	b4ParFilter	:=	{||}
Local	b5Relation	:=	{||}
Local	b5ParFilter	:=	{||}
Local	b6Relation	:=	{||}
Local	b6ParFilter	:=	{||}
Local	b7Relation	:=	{||}
Local	b7ParFilter	:=	{||}

Local nLogPxXDiff := 300/oReport:oPrint:nLogPixelX()
If nLogPxXDiff == 0.7
	oReport:nLogPxXDiff := 0.49
EndIf	
//Alimentacao dos arquivos de trabalho
AlimentTrb(cFile, aTrbs, aRegra, aStrCmps)
 
ProcRegua(Len(aTitulo))
For nX := 1 To Len(aTitulo)	
	If oReport:Cancel()
		Exit
	EndIf
	IncProc("Imprimindo...")
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³PRIMEIRO NIVEL³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
    cReg	:=	SubStr(aTitulo[nX][1],1,4)
	nCont	:=	aScan(aTrbs,{|x| x[3] == cReg })
	cAlias	:=	aTrbs[nCont,02]	

	If Interrupcao(lEnd)
	    Return
	EndIf   
	
	DBSelectArea(cAlias)
	If (nPosReg	:=	aScan(aRegra,{|aX| aX[1]==cReg}))>0
		If Len(aRegra[nPosReg])>1
			For nY := 2 To Len(aRegra[nPosReg])
				cReg	:=	aRegra[nPosReg][nY][1]
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³SEGUNDO NIVEL³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				If (nPosReg2 := aScan(aTitulo,{|aX| SubStr(aX[1],1,4)==cReg}))>0
					nCont	:=	aScan(aTrbs,{|x| x[3] == cReg })
					cAlias2	:=	aTrbs[nCont,02]				
					DBSelectArea(cAlias2)
					
					b2Relation	:=	&("{||"+cAlias+"->RELAC}")
					b2ParFilter	:=	&("{||"+cAlias2+"->RELAC=="+cAlias+"->RELAC}")
	
					oReport:Section(nPosReg):Section(nY-1):SetRelation(b2Relation,cAlias2,1,.T.)
					oReport:Section(nPosReg):Section(nY-1):SetParentFilter(b2ParFilter)
					
					If Len(aRegra[nPosReg][nY])>1
						For nZ := 2 To Len(aRegra[nPosReg][nY])
							cReg	:=	aRegra[nPosReg][nY][nZ][1]
							//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
							//³TERCEIRO NIVEL³
							//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
							If (nPosReg3 := aScan(aTitulo,{|aX| SubStr(aX[1],1,4)==cReg}))>0							
								nCont	:=	aScan(aTrbs,{|x| x[3] == cReg })
								cAlias3	:=	aTrbs[nCont,02]							
								DBSelectArea(cAlias3)
								
								b3Relation	:=	&("{||"+cAlias2+"->RELAC2}")
								b3ParFilter	:=	&("{||"+cAlias3+"->RELAC2=="+cAlias2+"->RELAC2}")
															
								oReport:Section(nPosReg):Section(nY-1):Section(nZ-1):SetRelation(b3Relation,cAlias3,1,.T.)
								oReport:Section(nPosReg):Section(nY-1):Section(nZ-1):SetParentFilter(b3ParFilter)
								
								If Len(aRegra[nPosReg][nY][nZ])>1
									For nA := 2 To Len(aRegra[nPosReg][nY][nZ])
										cReg	:=	aRegra[nPosReg][nY][nZ][nA][1]	
										//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
										//³QUARTO NIVEL  ³
										//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
										If (nPosReg4 := aScan(aTitulo,{|aX| SubStr(aX[1],1,4)==cReg}))>0										
											nCont	:=	aScan(aTrbs,{|x| x[3] == cReg })
											cAlias4	:=	aTrbs[nCont,02]
											DBSelectArea(cAlias4)
											
											b4Relation	:=	&("{||"+cAlias3+"->RELAC3}")
											b4ParFilter	:=	&("{||"+cAlias4+"->RELAC3=="+cAlias3+"->RELAC3}")
																																	
											oReport:Section(nPosReg):Section(nY-1):Section(nZ-1):Section(nA-1):SetRelation(b4Relation,cAlias4,1,.T.)
											oReport:Section(nPosReg):Section(nY-1):Section(nZ-1):Section(nA-1):SetParentFilter(b4ParFilter)
											
											If Len(aRegra[nPosReg][nY][nZ][nA])>1
												For nB := 2 To Len(aRegra[nPosReg][nY][nZ][nA])
													cReg	:=	aRegra[nPosReg][nY][nZ][nA][nB][1]
													//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
													//³QUINTO NIVEL  ³
													//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
													If (nPosReg5 := aScan(aTitulo,{|aX| SubStr(aX[1],1,4)==cReg}))>0													
														nCont	:=	aScan(aTrbs,{|x| x[3] == cReg })
														cAlias5	:=	aTrbs[nCont,02]													
														DBSelectArea(cAlias5)
														
														b5Relation	:=	&("{||"+cAlias4+"->RELAC4}")
														b5ParFilter	:=	&("{||"+cAlias5+"->RELAC4=="+cAlias4+"->RELAC4}")
																												
														oReport:Section(nPosReg):Section(nY-1):Section(nZ-1):Section(nA-1):Section(nB-1):SetRelation(b5Relation,cAlias5,1,.T.)
														oReport:Section(nPosReg):Section(nY-1):Section(nZ-1):Section(nA-1):Section(nB-1):SetParentFilter(b5ParFilter)
														
														If Len(aRegra[nPosReg][nY][nZ][nA][nB])>1
															For nC := 2 To Len(aRegra[nPosReg][nY][nZ][nA][nB])
																cReg	:=	aRegra[nPosReg][nY][nZ][nA][nB][nC][1]
																//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
																//³SEXTO NIVEL   ³
																//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
																If (nPosReg6 := aScan(aTitulo,{|aX| SubStr(aX[1],1,4)==cReg}))>0															
																	nCont	:=	aScan(aTrbs,{|x| x[3] == cReg })
																	cAlias6	:=	aTrbs[nCont,02]
																	DBSelectArea(cAlias6)											
																	
																	b6Relation	:=	&("{||"+cAlias5+"->RELAC5}")
																	b6ParFilter	:=	&("{||"+cAlias6+"->RELAC5=="+cAlias5+"->RELAC5}")
																	
									   								oReport:Section(nPosReg):Section(nY-1):Section(nZ-1):Section(nA-1):Section(nB-1):Section(nC-1):SetRelation(b6Relation,cAlias6,1,.T.)
																	oReport:Section(nPosReg):Section(nY-1):Section(nZ-1):Section(nA-1):Section(nB-1):Section(nC-1):SetParentFilter(b6ParFilter)
																	
																	If Len(aRegra[nPosReg][nY][nZ][nA][nB][nC])>1
																		For nD := 2 To Len(aRegra[nPosReg][nY][nZ][nA][nB][nC])
																			cReg	:=	aRegra[nPosReg][nY][nZ][nA][nB][nC][nD][1]
																			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
																			//³SETIMO NIVEL  ³
																			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
																			If (nPosReg7 := aScan(aTitulo,{|aX| SubStr(aX[1],1,4)==cReg}))>0															
																				nCont	:=	aScan(aTrbs,{|x| x[3] == cReg })
																				cAlias7	:=	aTrbs[nCont,02]
																				DBSelectArea(cAlias7)											
																			
																				b7Relation	:=	&("{||"+cAlias6+"->RELAC6}")
																				b7ParFilter	:=	&("{||"+cAlias7+"->RELAC6=="+cAlias6+"->RELAC6}")
																	
																				oReport:Section(nPosReg):Section(nY-1):Section(nZ-1):Section(nA-1):Section(nB-1):Section(nC-1):Section(nD-1):SetRelation(b7Relation,cAlias7,1,.T.)
																				oReport:Section(nPosReg):Section(nY-1):Section(nZ-1):Section(nA-1):Section(nB-1):Section(nC-1):Section(nD-1):SetParentFilter(b7ParFilter)
																			EndIf															
																		Next nD
																	EndIf										
																EndIf															
															Next nC
														EndIf														
														
													EndIf
												Next nB
											EndIf											
										EndIf
									Next nA
								EndIf								
							EndIf
						Next nZ
					EndIf
				EndIf
			Next nY
		EndIf
		oReport:Section(nPosReg):Print()
	EndIf
Next nX

Return

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Programa  |RetCntCmp ³ Autor ³ Gustavo G. Rueda      ³ Data ³20.08.2006³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³Funcao utilizada para montar um array com os campos de cada |±±
±±³          ³ registro.                                                  |±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³aRet -> Array na estrutura do registro alimentado.          ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros|cLinha -> Linha do arquivo texto a ser estruturado.         ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Static Function RetCntCmp( cLinha )

Local	nX		:=	2
Local	aRet	:=	{}
Local	cCmp	:=	""

For nX := 2 To Len( cLinha )
	If SubStr( cLinha,nX,1 )=="|"
		aAdd( aRet, cCmp )
		cCmp	:=	""
	Else
		cCmp	+=	SubStr( cLinha,nX,1 )
	EndIf
Next nX

Return( aRet )

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Programa  |AlimentTrb³ Autor ³ Igor Franzoi          ³ Data ³15.03.2012³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³Funcao utilizada para alimentar os TRBs criados de acordo   |±±
±±³          ³ o arquivo texto gerado anteriormente.                      |±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³Nenhum                                                      ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros|cFile -> Nome do arquivo texto gerado anteriormente.        ³±±
±±³          |aTrbs -> Array contendo os nomes dos TRBs gerados.          ³±±
±±³          |aRegra -> Regra de nivel dos registros.                     ³±±
±±³          |aStrCmps -> Estrutura de campos dos TRBs criados.           ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Static Function AlimentTrb(cFile, aTrbs, aRegra, aStrCmps)
Local	cLinha		:=	""
Local	aCmps		:=	{}
Local	nCmp		:=	0
Local	nI			:=	1
Local	nX			:=	1
Local	nD			:=	1
Local 	nY			:=	1
Local	nZ			:=	1
Local	nA			:=	1
Local	nB			:=	1
Local	nC			:=	1
Local	nF			:=	1

//Registro principal
Local	cReg		:=	""

Local	cRegPai		:=	""
Local	cRegPai2	:=	""
Local	cRegPai3	:=	""
Local	cRegPai4	:=	""
Local	cRegPai5	:=	""
Local	cRegPai6	:=	""

Local	nPosReg		:=	0
Local	nPosReg2	:=	0
Local	nPosReg3	:=	0
Local	nPosReg4	:=	0
Local	nPosReg5	:=	0
Local	nPosReg6	:=	0

Local	nRecPai		:=	0
Local	nRecFilho	:=	0
Local	nRecFilho2	:=	0
Local	nRecFilho3	:=	0
Local	nRecFilho4	:=	0
Local	nRecFilho5	:=	0
Local	nRecFilho6	:=	0

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Alimentacao dos TRBs acima³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
FT_FUSE(cFile)
FT_FGOTOP()
ProcRegua(FT_FLastRec())
While !FT_FEOF()
	cLinha	:=	FT_FREADLN()
	aCmps	:=	RetCntCmp( cLinha )
	nCmp	:=	1
	cReg	:=	SubStr(cLinha,2,4)
	IncProc("Carregando Arquivo...")
	
	If Interrupcao(lEnd)
	    Return
	EndIf   

	If (nPos	:=	aScan(aTrbs, {|aX| aX[3]==cReg}))>0
		cAlias	:=	aTrbs[nPos][2]
    	nX		:=	nPos

		DBSelectArea(cAlias)
		RecLock(cAlias,.T.)		
		
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³PRIMEIRO NIVEL³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		For nD := 1 To Len(aRegra)
			If (nPosReg	:=	aScan(aRegra,{|aX| aX[1]==cReg}))>0				
				cRegPai	:=	cReg
				nRecPai	:=	(cAlias)->(Recno())
				
				cRegPai2	:=	""
				cRegPai3	:=	""
				cRegPai4	:=	""
				cRegPai5	:=	""
				cRegPai6	:=	""
							
				nPosReg2	:=	0
				nPosReg3	:=	0
				nPosReg4	:=	0
				nPosReg5	:=	0
				nPosReg6	:=	0
				
				nRecFilho	:=	0
				nRecFilho2	:=	0
				nRecFilho3	:=	0
				nRecFilho4	:=	0
				nRecFilho5	:=	0
				nRecFilho6	:=	0
				
				nD := Len(aRegra)
				
			Else		
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³SEGUNDO NIVEL³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				If Len(aRegra[nD])>1
					For nY := 2 To Len(aRegra[nD])
						If (aRegra[nD,nY,01] == cReg)
							cRegPai2	:=	cReg
							nRecFilho	:=	(cAlias)->(Recno())
							
							cRegPai3	:=	""
							cRegPai4	:=	""
							cRegPai5	:=	""
							cRegPai6	:=	""
										
							nPosReg3	:=	0
							nPosReg4	:=	0
							nPosReg5	:=	0
							nPosReg6	:=	0
							
							nRecfilho2	:=	0
							nRecFilho3	:=	0
							nRecFilho4	:=	0
							nRecFilho5	:=	0
							nRecFilho6	:=	0
							
							nY := Len(aRegra[nD])
							
						Else
							//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
							//³TERCEIRO NIVEL³
							//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
							If Len(aRegra[nD][nY])>1
								For nZ := 2 To Len(aRegra[nD][nY])
									If (aRegra[nD,nY,nZ,01] == cReg)
										cRegPai3	:=	cReg
										nRecFilho2	:=	(cAlias)->(Recno())
										
										cRegPai4	:=	""
										cRegPai5	:=	""
										cRegPai6	:=	""
													
										nPosReg4	:=	0
										nPosReg5	:=	0
										nPosReg6	:=	0
										
										nRecFilho3	:=	0
										nRecFilho4	:=	0
										nRecFilho5	:=	0
										
										nZ := Len(aRegra[nD,nY])
										
									Else
										//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
										//³QUARTO NIVEL  ³
										//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
										If Len(aRegra[nD][nY][nZ])>1
											For nA := 2 To Len(aRegra[nD][nY][nZ])
												If (aRegra[nD,nY,nZ,nA,01] == cReg)
													cRegPai4	:=	cReg
													nRecFilho3	:=	(cAlias)->(Recno())													
													cRegPai5	:=	""
													cRegPai6	:=	""																
													nPosReg5	:=	0
													nPosReg6	:=	0													
													nRecFilho4	:=	0
													nRecFilho5	:=	0													
													nA := Len(aRegra[nD,nY,nZ])													
												Else
													//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
													//³QUINTO NIVEL  ³
													//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ											
													If Len(aRegra[nD][nY][nZ][nA])>1
														For nB := 2 To Len(aRegra[nD][nY][nZ][nA])
															If (aRegra[nD,nY,nZ,nA,nB,01] == cReg)
																cRegPai5	:=	cReg
																nRecFilho4	:=	(cAlias)->(Recno())														
																cRegPai6	:=	""																			
																nPosReg6	:=	0																
																nRecFilho5	:=	0																
																nB := Len(aRegra[nD,nY,nZ,nA])																
															Else
																//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
																//³SEXTO NIVEL  ³
																//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÙ                   
																If Len(aRegra[nD][nY][nZ][nA][nB])>1
																	For nC := 2 To Len(aRegra[nD][nY][nZ][nA][nB])
																		If (aRegra[nD,nY,nZ,nA,nB,nC,01] == cReg)
																			cRegPai6	:=	cReg
																			nRecFilho5	:=	(cAlias)->(Recno())														
																			cRegPai7	:=	""																			
																			nPosReg7	:=	0																
																			nRecFilho6	:=	0																
																			nC := Len(aRegra[nD,nY,nZ,nA,nB])																
																		Else																
																			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
																			//³SETIMO NIVEL ³
																			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÙ                   
																			If Len(aRegra[nD][nY][nZ][nA][nB][nC])>1
																				For nF := 2 To Len(aRegra[nD][nY][nZ][nA][nB][nC])
																					If (aRegra[nD,nY,nZ,nA,nB,nC,nF,01] == cReg)
																						cRegPai7	:=	cReg
																						nRecFilho6	:=	(cAlias)->(Recno())
																					EndIf
																				Next nF
																			EndIf
																		EndIf
																	Next nC
																EndIf
															EndIf
														Next nB
													EndIf												
												EndIf												
											Next nA
										EndIf									
									EndIf        	
								Next nZ
							EndIf						
						EndIf
					Next nY
				EndIf		
			EndIf
		Next nD
		
		For nI := 1 To Len(aStrCmps[nX])
			If nI<=Len(aCmps) .Or. "RELAC"$aStrCmps[nX][nI][1]
				If !"RELAC"$aStrCmps[nX][nI][1]
					If aStrCmps[nX][nI][2]=="D"
						(cAlias)->(FieldPut(nI, CToD( Transform( aCmps[nCmp++],"@R 99/99/9999" ))))
					ElseIf aStrCmps[nX][nI][2]=="N"
						(cAlias)->(FieldPut(nI, Val(StrTran(aCmps[nCmp++],",","."))))
					Else
						(cAlias)->(FieldPut(nI, aCmps[nCmp++]))
					EndIf	
				ElseIf ("RELAC2"$aStrCmps[nX][nI][1]) 
					(cAlias)->(FieldPut(nI, StrZero(nRecFilho,10)))
				ElseIf ("RELAC3"$aStrCmps[nX][nI][1])
					(cAlias)->(FieldPut(nI, StrZero(nRecFilho2,10)))
				ElseIf ("RELAC4"$aStrCmps[nX][nI][1])
					(cAlias)->(FieldPut(nI, StrZero(nRecFilho3,10)))
				ElseIf ("RELAC5"$aStrCmps[nX][nI][1])
					(cAlias)->(FieldPut(nI, StrZero(nRecFilho4,10)))
				ElseIf ("RELAC6"$aStrCmps[nX][nI][1])
					(cAlias)->(FieldPut(nI, StrZero(nRecFilho5,10)))
				ElseIf ("RELAC7"$aStrCmps[nX][nI][1])
					(cAlias)->(FieldPut(nI, StrZero(nRecFilho6,10)))
				ElseIf "RELAC"$aStrCmps[nX][nI][1]
					(cAlias)->(FieldPut(nI, StrZero(nRecPai,10)))
				EndIf
			EndIf
		Next nI
		MSUnLock()
	EndIf
	
	FT_FSKIP()
EndDo

Return

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Programa  |ReadTxt   ³ Autor ³ Igor Franzoi			³ Data ³20.08.2006³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³Estrutura de impressão do relatório						  |±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³aTrbs -> Array contendo os temporarios criados na rotina.   ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros|aRegra ->Array contendo as regras para geracao dos registros³±±
±±³          |aStrCmps ->Array contendo a estrutura das celulas           ³±±
±±³          |aTitulos ->Array contendo os labels e pictures das celulas  ³±±
±±³          |aWizard ->Array contendo as informacoes do assistente.      ³±±
±±³          |nArqVal ->verificador do arquivo.                           ³±±
±±³          |cFile   ->Arquivo a ser lido.                               ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Static Function LeTxt(aRegra,aStrCmps, aTitulo,aWizard,nArqVal,cFile)

Local	aTrbs		:=	{}
Local	aStru		:=	{}
Local	cLinha		:=	""
Local	cPictNUM	:=	"@E 999,999,999.99"		//Campos numéricos
Local	cPictNUM2	:=	"@E 999,999,999.999"	//Campos numéricos
Local	cPictNUM3	:=	"@E 999,999,999,999.99"	//Campos numéricos
Local	cPictCNPJ	:=  "@R ##.###.###/####-##"	//CNPJ
Local	cPictChar	:=	"@!"                    //Campos caracter
Local	cPictALI1	:=	"@E 9999.99"			//Alíquotas com 2 casas
Local	cPictALI2	:=	"@E 9999.9999"			//Alíquotas com 4 casas
 
cFile		:=	aWizard[1][1]
ProcRegua(12)
If File( cFile )
	IncProc("Gerando estrutura...")
	FT_FUSE(cFile)
	FT_FGOTOP()
	If !FT_FEOF()
		cLinha	:=	FT_FREADLN()
		If !("|0000|" $ cLinha)
			nArqVal	:= 1
			Return(aTrbs)
		EndIf
	EndIf
    
	//BLOCO 0: ABERTURA, IDENTIFICAÇÃO E REFERÊNCIAS
	//REGISTRO 0000: ABERTURA DO ARQUIVO DIGITAL E IDENTIFICAÇÃO DA PESSOA JURÍDICA
	aAdd( aRegra, {"0000"} ) //N1	
	//REGISTRO 0001: ABERTURA DO BLOCO 0
	aAdd( aRegra[Len( aRegra )], {"0001"} )									//N2
	//REGISTRO 0100: DADOS DO CONTABILISTA
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )] )], {"0100"} )	//N3
	//REGISTRO 0110: REGIMES DE APURAÇÃO DA CONTRIBUIÇÃO SOCIAL E DE APROPRIAÇÃO DE CRÉDITO
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )] )], {"0110"} ) 	//N3
	//REGISTRO 0111: TABELA DE RECEITA BRUTA MENSAL PARA FINS DE RATEIO DE CRÉDITOS COMUNS	
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )], {"0111"} ) //N4	
	//REGISTRO 0140: TABELA DE CADASTRO DE ESTABELECIMENTO
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )] )], {"0140"} )	//N3	
	//REGISTRO 0145: TABELA DE CADASTRO DO PARTICIPANTE
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )], {"0145"} ) //N4	
	//REGISTRO 0150: TABELA DE CADASTRO DO PARTICIPANTE
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )], {"0150"} ) //N4	
	//REGISTRO 0190: IDENTIFICAÇÃO DAS UNIDADES DE MEDIDA
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )], {"0190"} ) //N4
	//0200 - TABELA DE IDENTIFICAÇÃO DO ITEM (PRODUTOS E SERVIÇOS)"
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )], {"0200"} ) //N4	
	//REGISTRO 0205: ALTERAÇÃO DO ITEM
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] )], {"0205"} ) //N5	
	//REGISTRO 0206: CÓDIGO DE PRODUTO CONFORME TABELA ANP (COMBUSTÍVEIS)
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] )], {"0206"} ) //N5	
	//REGISTRO 0208: CÓDIGO DE GRUPOS POR MARCA COMERCIAL - REFRI (BEBIDAS FRIAS)
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] )], {"0208"} ) //N5	
	//REGISTRO 0400: TABELA DE NATUREZA DA OPERAÇÃO/PRESTAÇÃO
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )], {"0400"} ) //N4
	//REGISTRO 0450: TABELA DE INFORMAÇÃO COMPLEMENTAR DO DOCUMENTO FISCAL
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )], {"0450"} ) //N4	
	//REGISTRO 0500: PLANO DE CONTAS CONTÁBEIS
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )] )], {"0500"} ) //N3	
	//REGISTRO 0600: CENTRO DE CUSTOS
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )] )], {"0600"} ) //N3	
	//REGISTRO 0990: ENCERRAMENTO DO BLOCO 0
	aAdd( aRegra[Len( aRegra )], {"0990"} )								  //N2
	//FIM  - BLOCO 0: ABERTURA, IDENTIFICAÇÃO E REFERÊNCIAS
	
	//BLOCO A: DOCUMENTOS FISCAIS - SERVIÇOS (NÃO SUJEITOS AO ICMS)
	//REGISTRO A001: ABERTURA DO BLOCO A
	aAdd( aRegra[Len( aRegra )], {"A001"} )									//N2
	//REGISTRO A010: IDENTIFICAÇÃO DO ESTABELECIMENTO
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )] )], {"A010"} )	//N3
	//REGISTRO A100: DOCUMENTO - NOTA FISCAL DE SERVIÇO
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )], {"A100"} ) //N4	
	//REGISTRO A110: COMPLEMENTO DO DOCUMENTO - INFORMAÇÃO COMPLEMENTAR DA NF
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ], {"A110"} ) //N5
	//REGISTRO A111: PROCESSO REFERENCIADO
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ], {"A111"} ) //N5	
	//REGISTRO A120: INFORMAÇÃO COMPLEMENTAR - OPERAÇÕES DE IMPORTAÇÃO
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ], {"A120"} ) //N5
	//REGISTRO A170: COMPLEMENTO DO DOCUMENTO - ITENS DO DOCUMENTO
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ], {"A170"} ) //N5
	//REGISTRO A990: ENCERRAMENTO DO BLOCO A
	aAdd( aRegra[Len( aRegra )], {"A990"} )									//N2
	//FIM - BLOCO A: DOCUMENTOS FISCAIS - SERVIÇOS (NÃO SUJEITOS AO ICMS)
	
	//BLOCO C: DOCUMENTOS FISCAIS I - MERCADORIAS (ICMS/IPI)
	//REGISTRO C001: ABERTURA DO BLOCO C
	aAdd( aRegra[Len( aRegra )], {"C001"} )									//N2
	//REGISTRO C010: IDENTIFICAÇÃO DO ESTABELECIMENTO
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )] )], {"C010"} )	//N3
	//REGISTRO C100: DOCUMENTO - NOTA FISCAL (CÓDIGO 01), NOTA FISCAL AVULSA (CÓDIGO 1B), NOTA FISCAL DE PRODUTOR (CÓDIGO 04) e NF-e (CÓDIGO 55)
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )], {"C100"} ) //N4
	//REGISTRO C110: COMPLEMENTO DO DOCUMENTO - INFORMAÇÃO COMPLEMENTAR DA NOTA FISCAL (CÓDIGOS 01, 1B, 04 e 55)
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ], {"C110"} ) //N5	
	//REGISTRO C111: PROCESSO REFERENCIADO
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ], {"C111"} ) //N5
	//REGISTRO C120: COMPLEMENTO DO DOCUMENTO - OPERAÇÕES DE IMPORTAÇÃO (CÓDIGO 01) 
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ], {"C120"} ) //N5	
	//REGISTRO C170: COMPLEMENTO DO DOCUMENTO - ITENS DO DOCUMENTO (CÓDIGOS 01, 1B, 04 e 55)
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ], {"C170"} ) //N5		
	//REGISTRO C180: CONSOLIDAÇÃO DE NOTAS FISCAIS ELETRÔNICAS EMITIDAS PELA PESSOA JURÍDICA (CÓDIGO 55) - OPERAÇÕES DE VENDAS
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )], {"C180"} ) //N4	
	//REGISTRO C181: DETALHAMENTO DA CONSOLIDAÇÃO - OPERAÇÕES DE VENDAS - PIS/PASEP
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ], {"C181"} ) //N5
	//REGISTRO C185: DETALHAMENTO DA CONSOLIDAÇÃO - OPERAÇÕES DE VENDAS - COFINS
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ], {"C185"} ) //N5	
	//REGISTRO C188: PROCESSO REFERENCIADO 
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ], {"C188"} ) //N5
	//REGISTRO C190: CONSOLIDAÇÃO DE NOTAS FISCAIS ELETRÔNICAS (CÓDIGO 55) - OPERAÇÕES DE AQUISIÇÃO COM DIREITO A CRÉDITO, E OPERAÇÕES DE DEVOLUÇÃO DE COMPRAS E VENDAS
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )], {"C190"} ) //N4
	//REGISTRO C191: DETALHAMENTO DA CONSOLIDAÇÃO - OPERAÇÕES DE AQUISIÇÃO COM DIREITO A CRÉDITO, E OPERAÇÕES DE DEVOLUÇÃO DE COMPRAS E VENDAS - PIS/PASEP
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ], {"C191"} ) //N5	
	//REGISTRO C195: DETALHAMENTO DA CONSOLIDAÇÃO - OPERAÇÕES DE AQUISIÇÃO COM DIREITO A CRÉDITO, E OPERAÇÕES DE DEVOLUÇÃO DE COMPRAS E VENDAS - COFINS
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ], {"C195"} ) //N5
	//REGISTRO C198: PROCESSO REFERENCIADO
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ], {"C198"} ) //N5	
	//REGISTRO C199: COMPLEMENTO DO DOCUMENTO - OPERAÇÕES DE IMPORTAÇÃO (CÓDIGO 55) 
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ], {"C199"} ) //N5
	//REGISTRO C380: NOTA FISCAL DE VENDA A CONSUMIDOR (CÓDIGO 02) - CONSOLIDAÇÃO DE DOCUMENTOS EMITIDOS
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )], {"C380"} ) //N4
	//REGISTRO C381: DETALHAMENTO DA CONSOLIDAÇÃO - PIS/PASEP
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ], {"C381"} ) //N5
	//REGISTRO C385: DETALHAMENTO DA CONSOLIDAÇÃO - COFINS 
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ], {"C385"} ) //N5	
	//REGISTRO C395: NOTAS FISCAIS DE VENDA A CONSUMIDOR (CÓDIGOS 02, 2D, 2E e 59) - AQUISIÇÕES/ENTRADAS COM CRÉDITO
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )], {"C395"} ) //N4
	//REGISTRO C396: ITENS DO DOCUMENTO (CÓDIGOS 02, 2D, 2E e 59) - AQUISIÇÕES/ENTRADAS COM CRÉDITO
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ], {"C396"} ) //N5
	//REGISTRO C400: EQUIPAMENTO ECF (CÓDIGOS 02 e 2D)
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )], {"C400"} ) //N4
	//REGISTRO C405: REDUÇÃO Z (CÓDIGOS 02 e 2D)
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ], {"C405"} ) //N5	
	//REGISTRO C481: RESUMO DIÁRIO DE DOCUMENTOS EMITIDOS POR ECF - PIS/PASEP (CÓDIGOS 02 e 2D)
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ][	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ] )], {"C481"} ) //N6
	//REGISTRO C485: RESUMO DIÁRIO DE DOCUMENTOS EMITIDOS POR ECF - COFINS (CÓDIGOS 02 e 2D)
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ][	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ] )], {"C485"} ) //N6	
	//REGISTRO C489: PROCESSO REFERENCIADO
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ], {"C489"} ) //N5	
	//REGISTRO C490: CONSOLIDAÇÃO DE DOCUMENTOS EMITIDOS POR ECF (CÓDIGOS 02, 2D e 59)
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )], {"C490"} ) //N4
	//REGISTRO C491: DETALHAMENTO DA CONSOLIDAÇÃO DE DOCUMENTOS EMITIDOS POR ECF (CÓDIGOS 02, 2D e 59) - PIS/PASEP
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ], {"C491"} ) //N5	
	//REGISTRO C495: DETALHAMENTO DA CONSOLIDAÇÃO DE DOCUMENTOS EMITIDOS POR ECF (CÓDIGOS 02, 2D e 59) - COFINS
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ], {"C495"} ) //N5		
	//REGISTRO C499: PROCESSO REFERENCIADO
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ], {"C499"} ) //N5
	//REGISTRO C500: NOTA FISCAL/CONTA DE ENERGIA ELÉTRICA (CÓDIGO 06), NOTA FISCAL/CONTA DE FORNECIMENTO D'ÁGUA CANALIZADA (CÓDIGO 29) E NOTA FISCAL CONSUMO FORNECIMENTO DE GÁS (CÓDIGO 28) - DOCUMENTOS DE ENTRADA/AQUISIÇÃO COM CRÉDITO
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )], {"C500"} ) //N4	
	//REGISTRO C501: COMPLEMENTO DA OPERAÇÃO (CÓDIGOS 06, 28 e 29) - PIS/PASEP
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ], {"C501"} ) //N5	
	//REGISTRO C505: COMPLEMENTO DA OPERAÇÃO (CÓDIGOS 06, 28 e 29) - COFINS
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ], {"C505"} ) //N5
	//REGISTRO C509: PROCESSO REFERENCIADO 
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ], {"C509"} ) //N5	
	//REGISTRO C600: CONSOLIDAÇÃO DIÁRIA DE NOTAS FISCAIS/CONTAS EMITIDAS DE ENERGIA ELÉTRICA (CÓDIGO 06), NOTA FISCAL/CONTA DE FORNECIMENTO D'ÁGUA CANALIZADA (CÓDIGO 29) E NOTA FISCAL/CONTA DE FORNECIMENTO DE GÁS (CÓDIGO 28) (EMPRESAS OBRIGADAS OU NÃO OBRIGADAS AO CONVENIO ICMS 115/03) - DOCUMENTOS DE SAÍDA
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )], {"C600"} ) //N4		
	//REGISTRO C601: COMPLEMENTO DA CONSOLIDAÇÃO DIÁRIA (CÓDIGOS 06, 28 e 29) - DOCUMENTOS DE SAÍDAS - PIS/PASEP
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ], {"C601"} ) //N5
	//REGISTRO C605: COMPLEMENTO DA CONSOLIDAÇÃO DIÁRIA (CÓDIGOS 06, 28 e 29) - DOCUMENTOS DE SAÍDAS - COFINS
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ], {"C605"} ) //N5
	//REGISTRO C609: PROCESSO REFERENCIADO 
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ], {"C609"} ) //N5		
	//REGISTRO C800: CUPOM FISCAL ELETRÔNICO (CÓDIGO 59)
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )], {"C800"} ) //N4	
	//REGISTRO C810: DETALHAMENTO DO CUPOM FISCAL ELETRÔNICO (CÓDIGO 59) - PIS/PASEP E COFINS
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ], {"C810"} ) //N5	
	//REGISTRO C820: DETALHAMENTO DO CUPOM FISCAL ELETRÔNICO (CÓDIGO 59) - PIS/PASEP E COFINS APURADO POR UNIDADE DE MEDIDA DE PRODUTO
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ], {"C820"} ) //N5
	//REGISTRO C830: PROCESSO RERENCIADO
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ], {"C830"} ) //N5	
	//REGISTRO C860: IDENTIFICAÇÃO DO EQUIPAMENTO SAT-CF-E 
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )], {"C860"} ) //N4	
	//REGISTRO C870: RESUMO DIÁRIO DE DOCUMENTOS EMITIDOS POR EQUIPAMENTO SAT-CF-E (CÓDIGO 59) - PIS/PASEP E COFINS
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ], {"C870"} ) //N5		
	//REGISTRO C880: RESUMO DIÁRIO DE DOCUMENTOS EMITIDOS POR EQUIPAMENTO SAT-CF-E (CÓDIGO 59) - PIS/PASEP E COFINS APURADO POR UNIDADE DE MEDIDA DE PRODUTO
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ], {"C880"} ) //N5
	//REGISTRO C890: PROCESSO RERENCIADO
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ], {"C890"} ) //N5
	//REGISTRO C990: ENCERRAMENTO DO BLOCO 0
	aAdd( aRegra[Len( aRegra )], {"C990"} )								  //N2	
	//FIM - BLOCO C: DOCUMENTOS FISCAIS I - MERCADORIAS (ICMS/IPI)
	
	//BLOCO D: DOCUMENTOS FISCAIS II - SERVIÇOS (ICMS)
	//REGISTRO D001: ABERTURA DO BLOCO D
	aAdd( aRegra[Len( aRegra )], {"D001"} )								  //N2	
	//REGISTRO D010: IDENTIFICAÇÃO DO ESTABELECIMENTO
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )] )], {"D010"} )	//N3
	//REGISTRO D100: AQUISIÇÃO DE SERVIÇOS DE TRANSPORTE - NOTA FISCAL DE SERVIÇO DE TRANSPORTE (CÓDIGO 07) E CONHECIMENTOS DE TRANSPORTE RODOVIÁRIO DE CARGAS (CÓDIGO 08), CONHECIMENTO DE TRANSPORTE DE CARGAS AVULSO (CÓDIGO 8B), AQUAVIÁRIO DE CARGAS (CÓDIGO 09), AÉREO (CÓDIGO 10), FERROVIÁRIO DE CARGAS (CÓDIGO 11), MULTIMODAL DE CARGAS (CÓDIGO 26), NOTA FISCAL DE TRANSPORTE FERROVIÁRIO DE CARGA (CÓDIGO 27) E CONHECIMENTO DE TRANSPORTE ELETRÔNICO - CT-e (CÓDIGO 57)
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )], {"D100"} ) //N4
	//REGISTRO D101: COMPLEMENTO DO DOCUMENTO DE TRANSPORTE (Códigos 07, 08, 8B, 09, 10, 11, 26, 27 e 57) - PIS/PASEP
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ], {"D101"} ) //N5	
	//REGISTRO D105: COMPLEMENTO DO DOCUMENTO DE TRANSPORTE (Códigos 07, 08, 8B, 09, 10, 11, 26, 27 e 57) - COFINS
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ], {"D105"} ) //N5	
	//REGISTRO D111: PROCESSO REFERENCIADO
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ], {"D111"} ) //N5		
	//REGISTRO D200: RESUMO DA ESCRITURAÇÃO DIÁRIA - PRESTAÇÃO DE SERVIÇOS DE TRANSPORTE - NOTA FISCAL DE SERVIÇO DE TRANSPORTE (CÓDIGO 07) E CONHECIMENTOS DE TRANSPORTE RODOVIÁRIO DE CARGAS (CÓDIGO 08), CONHECIMENTO DE TRANSPORTE DE CARGAS AVULSO (CÓDIGO 8B), AQUAVIÁRIO DE CARGAS (CÓDIGO 09), AÉREO (CÓDIGO 10), FERROVIÁRIO DE CARGAS (CÓDIGO 11), MULTIMODAL DE CARGAS (CÓDIGO 26), NOTA FISCAL DE TRANSPORTE FERROVIÁRIO DE CARGA (CÓDIGO 27) E CONHECIMENTO DE TRANSPORTE ELETRÔNICO - CT-e (CÓDIGO 57)
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )], {"D200"} ) //N4
	//REGISTRO D201: TOTALIZAÇÃO DO RESUMO DIÁRIO - PIS/PASEP
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ], {"D201"} ) //N5	
	//REGISTRO D205: TOTALIZAÇÃO DO RESUMO DIÁRIO - COFINS
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ], {"D205"} ) //N5
	//REGISTRO D209: PROCESSO REFERENCIADO
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ], {"D209"} ) //N5	
	//REGISTRO D300: RESUMO DA ESCRITURAÇÃO DIÁRIA - BILHETES CONSOLIDADOS DE PASSAGEM RODOVIÁRIO (CÓDIGO 13), DE PASSAGEM AQUAVIÁRIO (CÓDIGO 14), DE PASSAGEM E NOTA DE BAGAGEM (CÓDIGO 15), DE PASSAGEM FERROVIÁRIO (CÓDIGO 16) E RESUMO DE MOVIMENTO DIÁRIO (CÓDIGO 18)
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )], {"D300"} ) //N4	
	//REGISTRO D309: PROCESSO REFERENCIADO 
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ], {"D309"} ) //N5
	//REGISTRO D350: RESUMO DIÁRIO DE CUPOM FISCAL EMITIDO POR ECF - (CÓDIGOS 2E, 13, 14, 15 e 16)
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )], {"D350"} ) //N4
	//REGISTRO D359: PROCESSO REFERENCIADO 
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ], {"D359"} ) //N5	
	//REGISTRO D500: NOTA FISCAL DE SERVIÇO DE COMUNICAÇÃO (CÓDIGO 21) E NOTA FISCAL DE SERVIÇO DE TELECOMUNICAÇÃO (CÓDIGO 22) - DOCUMENTOS DE AQUISIÇÃO COM DIREITO A CRÉDITO
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )], {"D500"} ) //N4
	//REGISTRO D501: COMPLEMENTO DA OPERAÇÃO (CÓDIGOS 21 e 22) - PIS/PASEP
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ], {"D501"} ) //N5	
	//REGISTRO D505: COMPLEMENTO DA OPERAÇÃO (CÓDIGOS 21 e 22) - COFINS
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ], {"D505"} ) //N5	
	//REGISTRO D509: PROCESSO REFERENCIADO 
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ], {"D509"} ) //N5		
	//REGISTRO D600: CONSOLIDAÇÃO DA PRESTAÇÃO DE SERVIÇOS - NOTAS DE SERVIÇO DE COMUNICAÇÃO (CÓDIGO 21) E DE SERVIÇO DE TELECOMUNICAÇÃO (CÓDIGO 22)
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )], {"D600"} ) //N4	
	//REGISTRO D601: COMPLEMENTO DA CONSOLIDAÇÃO DA PRESTAÇÃO DE SERVIÇOS (CÓDIGOS 21 E 22) - PIS/PASEP
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ], {"D601"} ) //N5
	//REGISTRO D605: COMPLEMENTO DA CONSOLIDAÇÃO DA PRESTAÇÃO DE SERVIÇOS (CÓDIGOS 21 E 22) - COFINS
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ], {"D605"} ) //N5	
	//REGISTRO D609: PROCESSO REFERENCIADO 
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ], {"D609"} ) //N5	
	//REGISTRO D990: ENCERRAMENTO DO BLOCO D
	aAdd( aRegra[Len( aRegra )], {"D990"} )								  //N2
	//FIM  - BLOCO D: DOCUMENTOS FISCAIS II - SERVIÇOS (ICMS)
	
	//BLOCO F: DEMAIS DOCUMENTOS E OPERAÇÕES
	//REGISTRO F001: ABERTURA DO BLOCO F
	aAdd( aRegra[Len( aRegra )], {"F001"} )									//N2
	//REGISTRO F010: IDENTIFICAÇÃO DO ESTABELECIMENTO
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )] )], {"F010"} )	//N3
	//REGISTRO F100: DEMAIS DOCUMENTOS E OPERAÇÕES GERADORAS DE CONTRIBUIÇÃO E CRÉDITOS
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )], {"F100"} ) //N4
	//REGISTRO F111: PROCESSO REFERENCIADO
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ], {"F111"} ) //N5
	//REGISTRO F120: BENS INCORPORADOS AO ATIVO IMOBILIZADO - OPERAÇÕES GERADORAS DE CRÉDITOS COM BASE NOS ENCARGOS DE DEPRECIAÇÃO E AMORTIZAÇÃO
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )], {"F120"} ) //N4
	//REGISTRO F129: PROCESSO REFERENCIADO
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ], {"F129"} ) //N5
	//REGISTRO F130: BENS INCORPORADOS AO ATIVO IMOBILIZADO - OPERAÇÕES GERADORAS DE CRÉDITOS COM BASE NO VALOR DE AQUISIÇÃO/CONTRIBUIÇÃO
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )], {"F130"} ) //N4	
	//REGISTRO F139: PROCESSO REFERENCIADO
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ], {"F139"} ) //N5		
	//REGISTRO F150: CRÉDITO PRESUMIDO SOBRE ESTOQUE DE ABERTURA
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )], {"F150"} ) //N4
	//REGISTRO F200: OPERAÇÕES DA ATIVIDADE IMOBILIÁRIA - UNIDADE IMOBILIÁRIA VENDIDA
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )], {"F200"} ) //N4
	//REGISTRO F205: OPERAÇÕES DA ATIVIDADE IMOBILIÁRIA - CUSTO INCORRIDO DA UNIDADE IMOBILIÁRIA
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ], {"F205"} ) //N5	
	//REGISTRO F210: OPERAÇÕES DA ATIVIDADE IMOBILIÁRIA - CUSTO ORÇADO DA UNIDADE IMOBILIÁRIA VENDIDA
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ], {"F210"} ) //N5	
	//REGISTRO F211: PROCESSO REFERENCIADO
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ], {"F211"} ) //N5	
	//REGISTRO F500: CONSOLIDAÇÃO DAS OPERAÇÕES DA PESSOA JURÍDICA SUBMETIDA AO REGIME DE TRIBUTAÇÃO COM BASE NO LUCRO PRESUMIDO  - INCIDÊNCIA DO PIS/PASEP E DA COFINS PELO REGIME DE CAIXA
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )], {"F500"} ) //N4
	//REGISTRO F509: PROCESSO REFERENCIADO
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ], {"F509"} ) //N5	
	//REGISTRO F510: CONSOLIDAÇÃO DAS OPERAÇÕES DA PESSOA JURÍDICA SUBMETIDA AO REGIME DE TRIBUTAÇÃO COM BASE NO LUCRO PRESUMIDO - INCIDÊNCIA DO PIS/PASEP E DA COFINS PELO REGIME DE CAIXA (APURAÇÃO DA CONTRIBUIÇÃO POR UNIDADE DE MEDIDA DE PRODUTO - ALÍQUOTA EM REAIS)
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )], {"F510"} ) //N4
	//REGISTRO F519: PROCESSO REFERENCIADO
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ], {"F519"} ) //N5		
	//REGISTRO F525: COMPOSIÇÃO DA RECEITA ESCRITURADA NO PERÍODO - DETALHAMENTO DA RECEITA RECEBIDA PELO REGIME DE CAIXA
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )], {"F525"} ) //N4	
	//REGISTRO F550: CONSOLIDAÇÃO DAS OPERAÇÕES DA PESSOA JURÍDICA SUBMETIDA AO REGIME DE TRIBUTAÇÃO COM BASE NO LUCRO PRESUMIDO  - INCIDÊNCIA DO PIS/PASEP E DA COFINS PELO REGIME DE COMPETÊNCIA
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )], {"F550"} ) //N4
	//REGISTRO F559: PROCESSO REFERENCIADO
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ], {"F559"} ) //N5			
	//REGISTRO F560: CONSOLIDAÇÃO DAS OPERAÇÕES DA PESSOA JURÍDICA SUBMETIDA AO REGIME DE TRIBUTAÇÃO COM BASE NO LUCRO PRESUMIDO - INCIDÊNCIA DO PIS/PASEP E DA COFINS PELO REGIME DE COMPETÊNCIA (APURAÇÃO DA CONTRIBUIÇÃO POR UNIDADE DE MEDIDA DE PRODUTO - ALÍQUOTA EM REAIS)
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )], {"F560"} ) //N4	
	//REGISTRO F569: PROCESSO REFERENCIADO
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ], {"F569"} ) //N5			
	//REGISTRO F600: CONTRIBUIÇÃO RETIDA NA FONTE
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )], {"F600"} ) //N4
	//REGISTRO F700: DEDUÇÕES DIVERSAS
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )], {"F700"} ) //N4
	//REGISTRO F800: CRÉDITOS DECORRENTES DE EVENTOS DE INCORPORAÇÃO, FUSÃO E CISÃO
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )], {"F800"} ) //N4		
	//REGISTRO F990: ENCERRAMENTO DO BLOCO F
	aAdd( aRegra[Len( aRegra )], {"F990"} )								  //N2	
	//FIM  - BLOCO F: DEMAIS DOCUMENTOS E OPERAÇÕES

	//BLOCO I - OPERAÇÕES DAS INSTITUIÇÕES FINANCEIRAS
	//REGISTRO I001: ABERTURA DO BLOCO I
	aAdd( aRegra[Len( aRegra )], {"I001"} )									//N2	
	//REGISTRO I010: IDENTIFICAÇÃO DA PESSOA JURIDICA/ESTABELECIMENTO
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )] )], {"I010"} )	//N3
	//REGISTRO I100: CONSOLIDAÇÃO DAS OPERAÇÕES DO PERÍODO
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )], {"I100"} ) //N4
	//REGISTRO I199: PROCESSO REFERENCIADO
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] )], {"I199"} ) //N5
	//REGISTRO I200: COMPOSIÇÃO DAS RECEITAS, DEDUÇÕES E/OU EXCLUSÕES DO PERÍODO
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)])])])], {"I200"} ) //N5	
	//REGISTRO I299: PROCESSO REFERENCIADO
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ][	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ] )], {"I299"} ) //N6
	//REGISTRO I300: COMPLEMENTO DAS OPERAÇÕES – DETALHAMENTO DAS RECEITAS, DEDUÇÕES E/OU EXCLUSÕES DO PERÍODO
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ][	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ] )], {"I300"} ) //N6
	
	//REGISTRO I399: PROCESSO REFERENCIADO
	aAdd(aRegra[Len(aRegra)][Len(aRegra[Len(aRegra)])];
		[Len(aRegra[Len(aRegra)][Len(aRegra[Len(aRegra)])])];
		[Len(aRegra[Len(aRegra)][Len(aRegra[Len(aRegra)])][Len(aRegra[Len(aRegra)][Len(aRegra[Len(aRegra)])])])];          
		[Len(aRegra[Len(aRegra)][Len(aRegra[Len(aRegra)])][Len(aRegra[Len(aRegra)][Len(aRegra[Len(aRegra)])])];
		[Len(aRegra[Len(aRegra)][Len(aRegra[Len(aRegra)])][Len(aRegra[Len(aRegra)][Len(aRegra[Len(aRegra)])])])])];
		[Len(aRegra[Len(aRegra)][Len(aRegra[Len(aRegra)])][Len(aRegra[Len(aRegra)][Len(aRegra[Len(aRegra)])])];
		[Len(aRegra[Len(aRegra)][Len(aRegra[Len(aRegra)])][Len(aRegra[Len(aRegra)][Len(aRegra[Len(aRegra)])])])])];
		, {"I399"} ) //N7

	//REGISTRO I990: ENCERRAMENTO DO BLOCO I
	aAdd( aRegra[Len( aRegra )], {"I990"} )								  //N2	
	//FIM  - BLOCO I: OPERAÇÕES DAS INSTITUIÇÕES FINANCEIRAS
		
	//BLOCO M - APURAÇÃO DA CONTRIBUIÇÃO E CRÉDITO DO PIS/PASEP E DA COFINS
	//REGISTRO M001: ABERTURA DO BLOCO M
	aAdd( aRegra[Len( aRegra )], {"M001"} )									//N2	
	//REGISTRO M100: CRÉDITO DE PIS/PASEP RELATIVO AO PERÍODO
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )] )], {"M100"} )	//N3
	//REGISTRO M105: DETALHAMENTO DA BASE DE CALCULO DO CRÉDITO APURADO NO PERÍODO - PIS/PASEP
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )], {"M105"} ) //N4
	//REGISTRO M110: AJUSTES DO CRÉDITO DE PIS/PASEP APURADO
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )], {"M110"} ) //N4
	//REGISTRO M200: CONSOLIDAÇÃO DA CONTRIBUIÇÃO PARA O PIS/PASEP DO PERÍODO
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )] )], {"M200"} )	//N3
	//REGISTRO M210: DETALHAMENTO DA CONTRIBUIÇÃO PARA O PIS/PASEP DO PERÍODO
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )], {"M210"} ) //N4
	//REGISTRO M211: SOCIEDADES COOPERATIVAS - COMPOSIÇÃO DA BASE DE CALCULO - PIS/PASEP
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ], {"M211"} ) //N5	
	//REGISTRO M220: AJUSTES DA CONTRIBUIÇÃO PARA O PIS/PASEP APURADA
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ], {"M220"} ) //N5	
	//REGISTRO M230: INFORMAÇÕES ADICIONAIS DE DIFERIMENTO
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ], {"M230"} ) //N5	
	//REGISTRO M300: CONTRIBUIÇÃO DE PIS/PASEP DIFERIDA EM PERÍODOS ANTERIORES - VALORES A PAGAR NO PERÍODOs	
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )] )], {"M300"} )	//N3
	//REGISTRO M350: PIS/PASEP - FOLHA DE SALÁRIOS
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )] )], {"M350"} )	//N3
	//REGISTRO M400: RECEITAS ISENTAS, NÃO ALCANÇADAS PELA INCIDÊNCIA DA CONTRIBUIÇÃO, SUJEITAS A ALÍQUOTA ZERO OU DE VENDAS COM SUSPENSÃO - PIS/PASEP
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )] )], {"M400"} )	//N3
	//REGISTRO M410: DETALHAMENTO DAS RECEITAS ISENTAS, NÃO ALCANÇADAS PELA INCIDÊNCIA DA CONTRIBUIÇÃO, SUJEITAS A ALÍQUOTA ZERO OU DE VENDAS COM SUSPENSÃO - PIS/PASEP
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )], {"M410"} ) //N4	
	//REGISTRO M500: CRÉDITO DE COFINS RELATIVO AO PERÍODO
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )] )], {"M500"} )	//N3	
	//REGISTRO M505: DETALHAMENTO DA BASE DE CALCULO DO CRÉDITO APURADO NO PERÍODO - COFINS
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )], {"M505"} ) //N4	
	//REGISTRO M510: AJUSTES DO CRÉDITO DE COFINS APURADO
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )], {"M510"} ) //N4	
	//REGISTRO M600: CONSOLIDAÇÃO DA CONTRIBUIÇÃO PARA A SEGURIDADE SOCIAL - COFINS DO PERÍODO
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )] )], {"M600"} )	//N3	
	//REGISTRO M610: DETALHAMENTO DA CONTRIBUIÇÃO PARA A SEGURIDADE SOCIAL - COFINS DO PERÍODO
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )], {"M610"} ) //N4
	//REGISTRO M611: SOCIEDADES COOPERATIVAS - COMPOSIÇÃO DA BASE DE CALCULO - COFINS
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ], {"M611"} ) //N5			
	//REGISTRO M620: AJUSTES DA COFINS APURADA
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ], {"M620"} ) //N5			
	//REGISTRO M630: INFORMAÇÕES ADICIONAIS DE DIFERIMENTO
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ], {"M630"} ) //N5
	//REGISTRO M700: COFINS DIFERIDA EM PERÍODOS ANTERIORES - VALORES A PAGAR NO PERÍODO
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )] )], {"M700"} )	//N3	    
	//REGISTRO M800: RECEITAS ISENTAS, NÃO ALCANÇADAS PELA INCIDÊNCIA DA CONTRIBUIÇÃO, SUJEITAS A ALÍQUOTA ZERO OU DE VENDAS COM SUSPENSÃO - COFINS
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )] )], {"M800"} )	//N3
	//REGISTRO M810: DETALHAMENTO DAS RECEITAS ISENTAS, NÃO ALCANÇADAS PELA INCIDÊNCIA DA CONTRIBUIÇÃO, SUJEITAS A ALÍQUOTA ZERO OU DE VENDAS COM SUSPENSÃO - COFINS
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )], {"M810"} ) //N4	
	//REGISTRO M990: ENCERRAMENTO DO BLOCO M
	aAdd( aRegra[Len( aRegra )], {"M990"} )								  //N2
	//FIM  - BLOCO M - APURAÇÃO DA CONTRIBUIÇÃO E CRÉDITO DO PIS/PASEP E DA COFINS

	//BLOCO P: APURAÇÃO DA CONTRIBUIÇÃO PREVIDENCIÁRIA SOBRE A RECEITA BRUTA 
	//REGISTRO P001: ABERTURA DO BLOCO P
	aAdd( aRegra[Len( aRegra )], {"P001"} )									//N2
	//REGISTRO P010: IDENTIFICAÇÃO DO ESTABELECIMENTO
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )] )], {"P010"} )	//N3
	//REGISTRO P100: CONTRIBUIÇÃO PREVIDENCIÁRIA SOBRE A RECEITA BRUTA
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )], {"P100"} ) //N4
	//REGISTRO P200: CONSOLIDAÇÃO DA CONTRIBUIÇÃO PREVIDENCIÁRIA SOBRE A RECEITA BRUTA
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )] )], {"P200"} )	//N3
	//REGISTRO P990: ENCERRAMENTO DO BLOCO P
	aAdd( aRegra[Len( aRegra )], {"P990"} )								  //N2
	//FIM  - BLOCO P - APURAÇÃO DA CONTRIBUIÇÃO PREVIDENCIÁRIA SOBRE A RECEITA BRUTA

	//BLOCO 1: COMPLEMENTO DA ESCRITURAÇÃO - CONTROLE DE SALDOS DE CRÉDITOS E DE RETENÇÕES, OPERAÇÕES EXTEMPORÂNEAS E OUTRAS INFORMAÇÕES
	//REGISTRO 1001: ABERTURA DO BLOCO 1
	aAdd( aRegra[Len( aRegra )], {"1001"} )	
	//REGISTRO 1010: PROCESSO REFERENCIADO - AÇÃO JUDICIAL
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )] )], {"1010"} )	//N3
	//REGISTRO 1020: PROCESSO REFERENCIADO - PROCESSO ADMINISTRATIVO
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )] )], {"1020"} )	//N3
	//REGISTRO 1100: CONTROLE DE CRÉDITOS FISCAIS - PIS/PASEP
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )] )], {"1100"} )	//N3	
	//REGISTRO 1101: APURAÇÃO DE CRÉDITO EXTEMPORÂNEO - DOCUMENTOS E OPERAÇÕES DE PERÍODOS ANTERIORES - PIS/PASEP
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )], {"1101"} ) //N4
	//REGISTRO 1102: DETALHAMENTO DO CRÉDITO EXTEMPORANEO VINCULADO A MAIS DE UM TIPO DE RECEITA - PIS/PASEP
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ], {"1102"} ) //N5	
	//REGISTRO 1200: CONTRIBUIÇÃO SOCIAL EXTEMPORÂNEA - PIS/PASEP
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )] )], {"1200"} )	//N3		
	//REGISTRO 1210: DETALHAMENTO DA CONTRIBUIÇÃO SOCIAL EXTEMPORÂNEA - PIS/PASEP
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )], {"1210"} ) //N4
	//REGISTRO 1220: DEMONSTRAÇÃO DO CRÉDITO A DESCONTAR DA CONTRIBUIÇÃO EXTEMPORÂNEA - PIS/PASEP
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )], {"1220"} ) //N4	
	//REGISTRO 1300: CONTROLE DOS VALORES RETIDOS NA FONTE - PIS/PASEP
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )] )], {"1300"} )	//N3
	//REGISTRO 1500: CONTROLE DE CRÉDITOS FISCAIS - COFINS
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )] )], {"1500"} )	//N3	
	//REGISTRO 1501: APURAÇÃO DE CRÉDITO EXTEMPORÂNEO - DOCUMENTOS E OPERAÇÕES DE PERÍODOS ANTERIORES - COFINS
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )], {"1501"} ) //N4
	//REGISTRO 1502: DETALHAMENTO DO CRÉDITO EXTEMPORÂNEO VINCULADO A MAIS DE UM TIPO DE RECEITA - COFINS
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )][ 	Len( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )] ) ], {"1502"} ) //N5	
	//REGISTRO 1600: CONTRIBUIÇÃO SOCIAL EXTEMPORÂNEA - COFINS
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )] )], {"1600"} )	//N3
	//REGISTRO 1610: DETALHAMENTO DA CONTRIBUIÇÃO SOCIAL EXTEMPORÂNEA - COFINS
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )], {"1610"} ) //N4
	//REGISTRO 1620: DEMONSTRAÇÃO DO CRÉDITO A DESCONTAR DA CONTRIBUIÇÃO EXTEMPORÂNEA - COFINS
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )], {"1620"} ) //N4	
	//REGISTRO 1700: CONTROLE DOS VALORES RETIDOS NA FONTE - COFINS
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )] )], {"1700"} )	//N3
	//REGISTRO 1800: INCORPORAÇÃO IMOBILIÁRIA - RET
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )] )], {"1800"} )	//N3
	//REGISTRO 1809: PROCESSO REFERENCIADO 
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )])][Len( aRegra[ Len(aRegra) ][ Len( aRegra[Len(aRegra)]) ] )], {"1809"} ) //N4	
	//REGISTRO 1900: CONSOLIDAÇÃO DOS DOCUMENTOS EMITIDOS NO PERÍODO POR PESSOA JURÍDICA SUBMETIDA AO REGIME DE TRIBUTAÇÃO COM BASE NO LUCRO PRESUMIDO - REGIME DE CAIXA OU DE COMPETÊNCIA
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )] )], {"1900"} )	//N3	
	//REGISTRO 1990: ENCERRAMENTO DO BLOCO 1
	aAdd( aRegra[Len( aRegra )], {"1990"} )
	//FIM - BLOCO 1: COMPLEMENTO DA ESCRITURAÇÃO - CONTROLE DE SALDOS DE CRÉDITOS E DE RETENÇÕES, OPERAÇÕES EXTEMPORÂNEAS E OUTRAS INFORMAÇÕES
	
	//BLOCO 9: CONTROLE E ENCERRAMENTO DO ARQUIVO DIGITAL
	//REGISTRO 9001: ABERTURA DO BLOCO 9
	aAdd( aRegra[Len( aRegra )], {"9001"} )									//N2
	//REGISTRO 9900: REGISTROS DO ARQUIVO
	aAdd( aRegra[Len( aRegra )][Len( aRegra[Len( aRegra )] )], {"9900"} )	//N3	
	//REGISTRO 9990: ENCERRAMENTO DO BLOCO 9
	aAdd( aRegra[Len( aRegra )], {"9990"} )									//N2
	
	//REGISTRO 9999: ENCERRAMENTO DO ARQUIVO DIGITAL	
	aAdd( aRegra, {"9999"} ) //N1
					
	//REGISTRO 0000: ABERTURA DO ARQUIVO DIGITAL E IDENTIFICAÇÃO DA PESSOA JURÍDICA	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	006,	0 } ) //"_REG"
	aAdd( aStru,{ "CODVER",	"C",	003,	0 } ) //"_COD_VER"	
	aAdd( aStru,{ "T_E",		"C",	001,	0 } ) //"_TIPO_ESCRIT"
	aAdd( aStru,{ "I_S_E",		"C",	001,	0 } ) //"_IND_SIT_ESP"
	aAdd( aStru,{ "N_R_A",		"C",	020,	0 } ) //"_NUM_REC_ANTERIOR"
	aAdd( aStru,{ "DT_INI",	"C",	008,	0 } ) //"_DT_INI"
	aAdd( aStru,{ "DT_FIN",	"C",	008,	0 } ) //"_DT_FIN"
	aAdd( aStru,{ "NOME",		"C",	040,	0 } ) //"_NOME"
	aAdd( aStru,{ "CNPJ",		"C",	025,	0 } ) //"_CNPJ"
	aAdd( aStru,{ "UF",		"C",	003,	0 } ) //"_UF"
	aAdd( aStru,{ "CODMUN",	"C",	008,	0 } ) //"_COD_MUN"
	aAdd( aStru,{ "SUFRAM",	"C",	009,	0 } ) //"_SUFRAMA"
	aAdd( aStru,{ "I_N_PJ",	"C",	002,	0 } ) //"_IND_NAT_PJ"
	aAdd( aStru,{ "I_ATIV",	"C",	001,	0 } ) //"_IND_ATIV"
	aAdd( aStru,{ "RELAC",		"C",	010,	0 } )
	aAdd( aStrCmps,aStru )

	CriaTMPReg(aStru,"RELAC","0000",@aTrbs)	
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0015))	//0000 - ABERTURA DO ARQUIVO DIGITAL E IDENTIFICAÇÃO DA PESSOA JURÍDICA
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0017, cPictChar })	//"Versão leiaute"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0018, cPictChar })	//"Escrituração" //0 - Original;1 - Retificadora.
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0019, cPictChar })	//"Situação especial"			//0 - Abertura, 1 - Cisão, 2 - Fusão, 3 - Incorporação, 4 - Encerramento
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0020, cPictChar })	//"Recibo da Escrituração"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0021, cPictChar })	//"Data inicial"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0022, cPictChar })	//"Data final"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0023, cPictChar })	//"Nome"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0024, cPictCNPJ })	//"CNPJ"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0025, cPictChar })	//"UF"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0026, cPictChar })	//"Cód. do município - IBGE"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0027, cPictChar })	//"SUFRAMA"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0028, cPictChar })	//"Natureza da Pessoa Jurídica" //00 - Sociedade empresária em geral, 01 - Sociedade cooperativa, 02 - Entidade sujeita ao PIS/Pasep exclusivamente com base na Folha de Salários
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0029, cPictChar })	//"Tipo de Atividade"			//0 - Industrial ou equiparado a industrial;1 - Prestador de serviços;2 - Atividade de comércio;3 - Atividade financeira;4 - Atividade imobiliária;9 - Outros.
	
	//REGISTRO 0001: ABERTURA DO BLOCO 0	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) //"_REG"
	aAdd( aStru,{ "IND_MO",	"C",	003,	0 } ) //"_IND_MOV"
	aAdd( aStru,{ "RELAC",		"C",	010,	0 } )
	aAdd( aStru,{ "RELAC2",	"C",	010,	0 } )
	aAdd( aStrCmps,aStru )
	
	CriaTMPReg(aStru,"RELAC","0001",@aTrbs)
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0030))	//0001 - ABERTURA DO BLOCO 0
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0031, cPictChar })	//"Movimento"
	
	//REGISTRO 0100: DADOS DO CONTABILISTA	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	006,	0 } ) 	//"_REG"
	aAdd( aStru,{ "NOME",		"C",	030,	0 } ) 	//"_NOME"	
	aAdd( aStru,{ "CPF",		"C",	011,	0 } ) 	//"_CPF"
	aAdd( aStru,{ "CRC",		"C",	015,	0 } ) 	//"_CRC"
	aAdd( aStru,{ "CNPJ",		"C",	025,	0 } ) 	//"_CNPJ"
	aAdd( aStru,{ "CEP",		"C",	012,	0 } ) 	//"_CEP"
	aAdd( aStru,{ "END",		"C",	030,	0 } ) 	//"_END"
	aAdd( aStru,{ "NUM",		"C",	003,	0 } ) 	//"_NUM"
	aAdd( aStru,{ "COMPL",		"C",	020,	0 } ) 	//"_COMPL"	
	aAdd( aStru,{ "BAIRRO",	"C",	020,	0 } ) 	//"_BAIRRO"
	aAdd( aStru,{ "FONE",		"C",	010,	0 } ) 	//"_FONE"
	aAdd( aStru,{ "FAX",		"C",	010,	0 } ) 	//"_FAX"
	aAdd( aStru,{ "EMAIL",		"C",	030,	0 } ) 	//"_EMAIL"
	aAdd( aStru,{ "COD_MU",	"C",	007,	0 } ) 	//"_COD_MUN"
	aAdd( aStru,{ "RELAC2",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )		
	
	CriaTMPReg(aStru,"RELAC2","0100",@aTrbs)
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0032))	//0100 - DADOS DO CONTABILISTA
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0033, cPictChar })	//"Nome"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0034, cPictChar })	//"Núm. de insc. no CPF"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0035, cPictChar })	//"Conselho Regional de Contabilidade"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0036, cPictCNPJ })	//"Inscrição do escritório de contabilidade no CNPJ"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0037, cPictChar })	//"Código de Endereçamento Postal"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0038, cPictChar })	//"Logradouro e endereço do imóvel"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0039, cPictChar })	//"Número"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0040, cPictChar })	//"Dados complementares"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0041, cPictChar })	//"Bairro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0042, cPictChar })	//"Telefone"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0043, cPictChar })	//"FAX"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0044, cPictChar })	//"Endereço do correio eletrônico"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0045, cPictChar })	//"Código do município - IBGE"	
	
	IncProc("Gerando estrutura...")
	
	//REGISTRO 0110: REGIMES DE APURAÇÃO DA CONTRIBUIÇÃO SOCIAL E DE APROPRIAÇÃO DE CRÉDITO
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",	"C",	004,	0 } ) //"_REG"
	aAdd( aStru,{ "C_I_T",	"C",	001,	0 } ) //"COD_INC_TRIB"	
	aAdd( aStru,{ "I_A_C",	"C",	001,	0 } ) //"_IND_APRO_CRED"
	aAdd( aStru,{ "C_T_C",	"C",	001,	0 } ) //"_COD_TIPO_CONT"
	aAdd( aStru,{ "I_R_C",	"C",	001,	0 } ) //"IND_REG_CUM"
	aAdd( aStru,{ "RELAC2","C",	010,	0 } )
	aAdd( aStru,{ "RELAC3","C",	010,	0 } )	
	aAdd( aStrCmps,aStru )
	
	CriaTMPReg(aStru,"RELAC2","0110",@aTrbs)	
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0046))	//0110 - REGIMES DE APURAÇÃO DA CONTRIBUIÇÃO SOCIAL E DE APROPRIAÇÃO DE CRÉDITO
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0047, cPictChar })	//"Cód. ind. da incid. tributária no período"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0048, cPictChar })	//"Cód. ind. de mét. de aprop. de créditos comuns"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0049, cPictChar })	//"Cód. ind. do Tp. de Contribuição no Período"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0050, cPictChar })	//"Cód. ind. do critério de escrituração e apuração adotado"
	
	//REGISTRO 0111: TABELA DE RECEITA BRUTA MENSAL PARA FINS DE RATEIO DE CRÉDITOS COMUNS
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) //"_REG"
	aAdd( aStru,{ "RBNTMI",	"N",	014,	2 } ) //REC_BRU_NCUM_TRIB_MI
	aAdd( aStru,{ "RBNNMI",	"N",	014,	2 } ) //REC_BRU_NCUM_NT_MI
	aAdd( aStru,{ "RBNEXP",	"N",	014,	2 } ) //REC_BRU_NCUM_EXP
	aAdd( aStru,{ "R_B_C",		"N",	014,	2 } ) //REC_BRU_CUM
	aAdd( aStru,{ "R_B_T",		"N",	014,	2 } ) //REC_BRU_TOTAL
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )
	aAdd( aStrCmps,aStru )
	
	CriaTMPReg(aStru,"RELAC3","0111",@aTrbs)

	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0051))	//"0111 - TABELA DE RECEITA BRUTA MENSAL PARA FINS DE RATEIO DE CRÉDITOS COMUNS"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0052, cPictNUM	 })	//"Não-Cumulativa - Trib. no Mercado Interno"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0053, cPictNUM	 })	//"Não-Cumulativa - Não Tributada no Mercado Interno"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0054, cPictNUM	 })	//"Não-Cumulativa - Exportação"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0055, cPictNUM	 })	//"Receita Bruta Cumulativa"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0056, cPictNUM	 })	//"Receita Bruta Total"
	
	//REGISTRO 0140: TABELA DE CADASTRO DE ESTABELECIMENTO
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) //"_REG"
	aAdd( aStru,{ "COD_ES",	"C",	030,	0 } ) //"_COD_EST"
	aAdd( aStru,{ "NOME",		"C",	030,	0 } ) //"_NOME"
	aAdd( aStru,{ "CNPJ",		"C",	020,	0 } ) //"_CNPJ"
	aAdd( aStru,{ "UF",		"C",	002,	0 } ) //"_UF"
	aAdd( aStru,{ "IE",		"C",	014,	0 } ) //"_IE"
	aAdd( aStru,{ "COD_MU",	"C",	007,	0 } ) //"_COD_MUN"	
	aAdd( aStru,{ "IM",		"C",	020,	0 } ) //"_IM"	
	aAdd( aStru,{ "SUFRAM",	"C",	009,	0 } ) //"_SUFRAMA"
	aAdd( aStru,{ "RELAC2",	"C",	010,	0 } )
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )
	
	CriaTMPReg(aStru,"RELAC2","0140",@aTrbs)
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0057))	//0140 - TABELA DE CADASTRO DE ESTABELECIMENTO
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0058, cPictChar })	//"Cód. de ident. do estabelecimento"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0059, cPictChar })	//"Nome"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0024, cPictCNPJ })	//"CNPJ"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0025, cPictChar })	//"UF"	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0060, cPictChar })	//"Inscrição Estadual"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0026, cPictChar })	//"Código do município do domicílio fiscal do estabelecimento, conforme a tabela IBGE"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0061, cPictChar })	//"Inscrição Municipal"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0027, cPictChar })	//"Inscrição do estabelecimento na Suframa"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0062, cPictChar })	//"Cód. de identificação do estabelecimento"

	//REGISTRO 0145: 
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) //"_REG"
	aAdd( aStru,{ "INDIC",		"C",	001,	0 } ) //"_COD_PART"
	aAdd( aStru,{ "RECTOT",	"N",	014,	2 } ) //"_NOME"
	aAdd( aStru,{ "RECATV",	"N",	014,	2 } ) //"_COD_PAIS"	
	aAdd( aStru,{ "DMATV",		"N",	014,	2 } ) //"_CNPJ"
	aAdd( aStru,{ "INFO",		"C",	050,	0 } ) //"_CPF"
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )
	aAdd( aStrCmps,aStru )	
	
	CriaTMPReg(aStru,"RELAC3","0145",@aTrbs)		

	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi("0145 - Regime Apuração INSS Patronal"))	//"0145 - 
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016		, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0683		, cPictChar })	//"indicador de incidencia"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0684		, cPictNUM  })	//"Receita total"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0685		, cPictNUM  })	//"Vl Atividade"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0686		, cPictNUM  })	//"Vl Demais"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0136		, cPictChar })	//"inf. Comple"

	//REGISTRO 0150: TABELA DE CADASTRO DO PARTICIPANTE		
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) //"_REG"
	aAdd( aStru,{ "COD_PA",	"C",	020,	0 } ) //"_COD_PART"
	aAdd( aStru,{ "NOME",		"C",	020,	0 } ) //"_NOME"
	aAdd( aStru,{ "COD_PS",	"C",	005,	0 } ) //"_COD_PAIS"	
	aAdd( aStru,{ "CNPJ",		"C",	025,	0 } ) //"_CNPJ"
	aAdd( aStru,{ "CPF",		"C",	016,	0 } ) //"_CPF"
	aAdd( aStru,{ "IE",		"C",	014,	0 } ) //"_IE"	
	aAdd( aStru,{ "COD_MU",	"C",	008,	0 } ) //"_COD_MUN"	
	aAdd( aStru,{ "SUFRAM",	"C",	009,	0 } ) //"_SUFRAMA"
	aAdd( aStru,{ "END",		"C",	030,	0 } ) //"_END"
	aAdd( aStru,{ "NUM",		"C",	010,	0 } ) //"_NUM"	
	aAdd( aStru,{ "COMPL",		"C",	020,	0 } ) //"_COMPL"
	aAdd( aStru,{ "BAIRRO",	"C",	020,	0 } ) //"_BAIRRO"
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )
	aAdd( aStrCmps,aStru )	
	
	CriaTMPReg(aStru,"RELAC3","0150",@aTrbs)		

	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0063))	//"0150 - TABELA DE CADASTRO DO PARTICIPANTE"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0064, cPictChar })	//"Cód. de ident. do participante"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0664, cPictChar })	//"Nome pessoal/empresarial do participante."
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0665, cPictChar })	//"Cód. do país"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0024, cPictCNPJ })	//"CNPJ"	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0666, cPictChar })	//"CPF"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0060, cPictChar })	//"Inscrição Estadual nte"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0045, cPictChar })	//"Código do município, conforme a tabela IBGE"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0027, cPictChar })	//"SUFRAMA"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0038, cPictChar })	//"Logradouro e endereço do imóvel"				
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0039, cPictChar })	//"Número do imóvel"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0040, cPictChar })	//"Dados complementares do endereço"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0041, cPictChar })	//"Bairro em que o imóvel está situado"		
	
	//REGISTRO 0190: IDENTIFICAÇÃO DAS UNIDADES DE MEDIDA	
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) //"_REG"
	aAdd( aStru,{ "UNID",		"C",	006,	0 } ) //"_UNID"
	aAdd( aStru,{ "DESCR",		"C",	100,	0 } ) //"_DESCR"
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )	

	CriaTMPReg(aStru,"RELAC3","0190",@aTrbs)
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0065))	//"0190 - IDENTIFICAÇÃO DAS UNIDADES DE MEDIDA"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0066, cPictChar })	//"Código"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0067, cPictChar })	//"Descrição"
	
	//0200 - TABELA DE IDENTIFICAÇÃO DO ITEM (PRODUTOS E SERVIÇOS)"
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	006,	0 } ) //"_REG"
	aAdd( aStru,{ "COD_IT",	"C",	030,	0 } ) //"_COD_ITEM"
	aAdd( aStru,{ "DES_IT",	"C",	060,	0 } ) //"_DESCR_ITEM"
	aAdd( aStru,{ "COD_BA",	"C",	030,	0 } ) //"_COD_BARRA"
  	aAdd( aStru,{ "COD_AN",	"C",	030,	0 } ) //"_COD_ANT_ITE"
	aAdd( aStru,{ "UNI_IN",	"C",	006,	0 } ) //"_UNID_INV"
	aAdd( aStru,{ "TIP_IT",	"C",	003,	0 } ) //"_TIPO_ITEM"	
	aAdd( aStru,{ "COD_NC",	"C",	008,	0 } ) //"_COD_NCM"
	aAdd( aStru,{ "EX_IPI",	"C",	003,	0 } ) //"_EX_IPI"
	aAdd( aStru,{ "COD_GE",	"C",	002,	0 } ) //"_COD_GEN"	
	aAdd( aStru,{ "COD_LS",	"C",	004,	0 } ) //"_COD_GEN"	
	aAdd( aStru,{ "AL_ICM",	"N",	006,	2 } ) //"_ALIQ_ICMS"
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )
	aAdd( aStrCmps,aStru )
	
	CriaTMPReg(aStru,"RELAC3","0200",@aTrbs)	

	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0068))	//"0200 - TABELA DE IDENTIFICAÇÃO DO ITEM (PRODUTOS E SERVIÇOS)"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0066, cPictChar })	//"Código"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0067, cPictChar })	//"Descrição"	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0069, cPictChar })	//"Representação alfanumérico do código de barra"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0070, cPictChar })	//"Cód. ant. do item com relação a últ. infor. apresentada"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0071, cPictChar })	//"Un. de medida da quantificação de estoques"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0072, cPictChar })	//"Tipo do item"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0073, cPictChar })	//"Cód. da Nom. Comum do Mercosul"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0074, cPictChar })	//"Cód. EX, conforme a TIPI"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0075, cPictChar })	//"Cód. do gênero do item"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0076, cPictChar })	//"Cód. do serviço - Lei Complementar Federal nº 116/03"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0077, cPictALI1 })	//"Alíq. de ICMS aplicável ao item nas op. internas"	
	
	//REGISTRO 0205: ALTERAÇÃO DO ITEM	
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) //"_REG"
	aAdd( aStru,{ "D_A_I",		"C",	060,	0 } ) //"_DESCR_ANT_ITEM"
	aAdd( aStru,{ "DT_INI",	"C",	008,	0 } ) //"_DT_INI"
	aAdd( aStru,{ "DT_FIM",	"C",	008,	0 } ) //"_DT_FIM"
	aAdd( aStru,{ "C_A_I",		"C",	060,	0 } ) //"_COD_ANT_ITEM"
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )	

	CriaTMPReg(aStru,"RELAC4","0205",@aTrbs)	
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0078))	//"0205 - ALTERAÇÃO DO ITEM"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0079, cPictChar })	//"Descrição anterior do item"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0080, cPictChar })	//"Data inicial"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0081, cPictChar })	//"Data final"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0070, cPictChar })	//"Cód. ant. do item com relação à última informação apresentada.

	//REGISTRO 0206: CÓDIGO DE PRODUTO CONFORME TABELA ANP (COMBUSTÍVEIS)	
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) //"_REG"
	aAdd( aStru,{ "C_COMB",	"C",	060,	0 } ) //"_COD_COMB"
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )

	CriaTMPReg(aStru,"RELAC4","0206",@aTrbs)	
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0082))	//"0206 - CÓDIGO DE PRODUTO CONFORME TABELA ANP (COMBUSTÍVEIS)"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0083, cPictChar })	//"Descrição anterior do item"
	
	//REGISTRO 0208: CÓDIGO DE GRUPOS POR MARCA COMERCIAL - REFRI (BEBIDAS FRIAS)
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) //"_REG"
	aAdd( aStru,{ "COD_TA",	"C",	002,	0 } ) //"_COD_TAB"
	aAdd( aStru,{ "COD_GR",	"C",	002,	0 } ) //"_COD_GRU"
	aAdd( aStru,{ "MAR_CO",	"C",	060,	0 } ) //"_MARCA_COM"
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )
	aAdd( aStrCmps,aStru )

	CriaTMPReg(aStru,"RELAC4","0208",@aTrbs)

	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0084))	//"0208 - CÓDIGO DE GRUPOS POR MARCA COMERCIAL - REFRI (BEBIDAS FRIAS)"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0085, cPictChar })	//"Tab. de Incidência - Decreto nº 6.707/08"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0086, cPictChar })	//"Cód. do grupo - Decreto nº 6.707/08"	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0087, cPictChar })	//"Marca Comercial"

	//REGISTRO 0400: TABELA DE NATUREZA DA OPERAÇÃO/PRESTAÇÃO
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) //"_REG"
	aAdd( aStru,{ "COD_NA",	"C",	010,	0 } ) //"_COD_NAT"
	aAdd( aStru,{ "DES_NA",	"C",	060,	0 } ) //"_DESCR_NAT"
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )
	aAdd( aStrCmps,aStru )
	
	CriaTMPReg(aStru,"RELAC3","0400",@aTrbs)

	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0088))	//"0400: TABELA DE NATUREZA DA OPERAÇÃO/PRESTAÇÃO"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0066, cPictChar })	//"Cód. da nat. da operação/prestação
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0067, cPictChar })	//"Desc. da nat. da operação/prestação"	
	
	//REGISTRO 0450: TABELA DE INFORMAÇÃO COMPLEMENTAR DO DOCUMENTO FISCAL
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) //"_REG"
	aAdd( aStru,{ "COD_IN",	"C",	006,	0 } ) //"_COD_INF"
	aAdd( aStru,{ "TXT",		"C",	060,	0 } ) //"_TXT"
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )
	aAdd( aStrCmps,aStru )
	
	CriaTMPReg(aStru,"RELAC3","0450",@aTrbs)

	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0089))	//"0450 - TABELA DE INFORMAÇÃO COMPLEMENTAR DO DOCUMENTO FISCAL"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0090, cPictChar })	//"Código da informação"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0091, cPictChar })	//"Texto livre"	

	//REGISTRO 0500: PLANO DE CONTAS CONTÁBEIS
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "DT_ALT",	"C",	008,	0 } )	//"_DT_ALT"	
	aAdd( aStru,{ "C_N_C",		"C",	010,	0 } )	//"_COD_NAT_CC"
	aAdd( aStru,{ "I_C",		"C",	001,	0 } )	//"_CRC"
	aAdd( aStru,{ "NIVEL",		"C",	005,	0 } )	//"_NÍVEL"
	aAdd( aStru,{ "COD_CT",	"C",	030,	0 } )	//"_COD_CTA"
	aAdd( aStru,{ "NOM_CT",	"C",	030,	0 } )	//"_NOME_CTA"
	aAdd( aStru,{ "C_C_R",		"C",	030,	0 } ) 	//"_COD_CTA_REF"
	aAdd( aStru,{ "C_EST",		"C",	020,	0 } ) 	//"_CNPJ_EST"
	aAdd( aStru,{ "RELAC2",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )
	
	CriaTMPReg(aStru,"RELAC2","0500",@aTrbs)
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0100))	//0500 - PLANO DE CONTAS CONTÁBEIS
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0101, cPictChar })	//"Data da inclusão/alteração"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0102, cPictChar })	//"Cód. da nat. da conta/grupo de contas"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0103, cPictChar })	//"Tipo de conta"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0104, cPictChar })	//"Nível da conta analítica/grupo de contas"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0105, cPictChar })	//"Cód. da conta analítica/grupo de contas"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0106, cPictChar })	//"Nome da conta analítica/grupo de contas"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0107, cPictChar })	//"Cód. da conta correlacionada no Plano de Contas Referenciado, publicado pela RFB"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0024, cPictCNPJ })	//"CNPJ"
	
	//REGISTRO 0600: CENTRO DE CUSTOS
	
	aStru	:=	{}
	aAdd( aStru,{ "_REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "DT_ALT",	"C",	008,	0 } )	//"_DT_ALT"	
	aAdd( aStru,{ "C_CCUS",	"C",	060,	0 } )	//"_COD_CCUS"
	aAdd( aStru,{ "CCUS",		"C",	060,	0 } )	//"_CCUS"
	aAdd( aStru,{ "RELAC2",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )
	
	CriaTMPReg(aStru,"RELAC2","0600",@aTrbs)		
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0108))	//"0600 - CENTRO DE CUSTOS"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0101, cPictChar })	//"Data da inclusão/alteração"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0066, cPictChar })	//Código do centro de custos.
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0023, cPictChar })	//Nome do centro de custos.
	
	//REGISTRO 0990: ENCERRAMENTO DO BLOCO 0	
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) //"_REG"
	aAdd( aStru,{ "Q_LIN0",	"N",	010,	0 } ) //"_QTD_LIN_0"	
	aAdd( aStru,{ "RELAC",		"C",	010,	0 } )
	aAdd( aStrCmps,aStru )
	
	CriaTMPReg(aStru,"RELAC","0990",@aTrbs)
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0109))	//0990 - ENCERRAMENTO DO BLOCO 0
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0110, cPictChar })	//"Qtde tot. de lin. do Bloco 0"

	//REGISTRO A001: ABERTURA DO BLOCO A
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) //"_REG"
	aAdd( aStru,{ "IND_MO",	"C",	001,	0 } ) //"_IND_MOV"	
	aAdd( aStru,{ "RELAC",		"C",	010,	0 } )
	aAdd( aStru,{ "RELAC2",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )

	CriaTMPReg(aStru,"RELAC","A001",@aTrbs)
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0111))	//"A001 - ABERTURA DO BLOCO A"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0031, cPictChar })	//"Movimento"
	
	//REGISTRO A010: IDENTIFICAÇÃO DO ESTABELECIMENTO
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) //"_REG"
	aAdd( aStru,{ "CNPJ",		"C",	020,	0 } ) //"_CNPJ"
	aAdd( aStru,{ "RELAC2",	"C",	010,	0 } )
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )
	
	CriaTMPReg(aStru,"RELAC2","A010",@aTrbs)
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0112))	//"A010 - IDENTIFICAÇÃO DO ESTABELECIMENTO"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0024, cPictCNPJ })	//"_CNPJ"	

	//REGISTRO A100: DOCUMENTO - NOTA FISCAL DE SERVIÇO
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "I_O",		"C",	001,	0 } ) 	//"_IND_OPER"	
	aAdd( aStru,{ "I_E",		"C",	001,	0 } ) 	//"_IND_EMIT"
	aAdd( aStru,{ "C_P",		"C",	015,	0 } ) 	//"_COD_PART"
	aAdd( aStru,{ "C_S",		"C",	002,	0 } ) 	//"_COD_SIT"
	aAdd( aStru,{ "SER",		"C",	005,	0 } ) 	//"_SER"
	aAdd( aStru,{ "SUB",		"C",	001,	0 } ) 	//"_SUB"
	aAdd( aStru,{ "NUM_DO",	"C",	015,	0 } ) 	//"_NUM"
	aAdd( aStru,{ "CHV_NF",	"C",	010,	0 } ) 	//"_CHV_NFSE"	
	aAdd( aStru,{ "DT_DOC",	"C",	008,	0 } ) 	//"_DT_DOC"
	aAdd( aStru,{ "DT_E_S",	"C",	008,	0 } ) 	//"_DT_EXE_SERV"
	aAdd( aStru,{ "VL_DOC",	"N",	014,	2 } ) 	//"_VL_DOC"
	aAdd( aStru,{ "I_PGTO",	"C",	001,	0 } ) 	//"_IND_PGTO"
	aAdd( aStru,{ "V_DESC",	"N",	014,	2 } ) 	//"_VL_DESC"
	aAdd( aStru,{ "V_BC_P",	"N",	014,	2 } ) 	//"_VL_BC_PIS"
	aAdd( aStru,{ "VL_PIS",	"N",	014,	2 } ) 	//"_VL_PIS"	
	aAdd( aStru,{ "V_B_CO",	"N",	014,	2 } ) 	//"_VL_BC_COFINS"
	aAdd( aStru,{ "V_COFI",	"N",	014,	2 } ) 	//"_VL_COFINS"
	aAdd( aStru,{ "V_P_RE",	"N",	014,	2 } ) 	//"_VL_PIS_RET"
	aAdd( aStru,{ "V_CO_R",	"N",	014,	2 } ) 	//"_VL_COFINS_RET"
	aAdd( aStru,{ "VL_ISS",	"N",	014,	2 } ) 	//"_VL_COFINS_RET"	
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )
	
	CriaTMPReg(aStru,"RELAC3","A100",@aTrbs)
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0113))	//A100 - DOCUMENTO - NOTA FISCAL DE SERVIÇO
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0114, cPictChar })	//"Tipo de Operação"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0115, cPictChar })	//"Emitente do documento fiscal"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0116, cPictChar })	//"Código do participante"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0117, cPictChar })	//"Cód. da sit. do documento fiscal"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0118, cPictChar })	//"Série"
	aAdd( aTitulo[Len(aTitulo)][2],{ ""/*STR0119*/, cPictChar })	//"Subsérie"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0120, cPictChar })	//"Número ou documento internacional equivalente"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0121, cPictChar })	//"Chave/Código de Verificação da NFSE"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0122, cPictChar })	//"Data da emissão"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0123, cPictChar })	//"Data de Execução / Conclusão do Serviço"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0124, cPictNUM })	//"Valor total"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0125, cPictChar })	//"Tipo de Pagamento"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0126, cPictNUM })	//"Valor total do desconto"	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0127, cPictNUM })	//"Valor da base de cálculo do PIS/PASEP"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0128, cPictNUM })	//"Valor total do PIS"	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0129, cPictNUM })	//"Valor da base de cálculo da COFINS"	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0130, cPictNUM })	//"Valor total da COFINS"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0131, cPictNUM })	//"Valor total do PIS retido na fonte"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0132, cPictNUM })	//"Valor total da COFINS retido na fonte"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0133, cPictNUM })	//"Valor do ISS"	 
	
	//REGISTRO A110: COMPLEMENTO DO DOCUMENTO - INFORMAÇÃO COMPLEMENTAR DA NF
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "COD_IN",	"C",	006,	0 } ) 		//"_COD_INF"
	aAdd( aStru,{ "TXT_CO",	"C",	060,	0 } ) 		//"_TXT_COMPL"
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )	
		
	CriaTMPReg(aStru,"RELAC4","A110",@aTrbs)
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0134))	//"A110 - COMPLEMENTO DO DOCUMENTO - INFORMAÇÃO COMPLEMENTAR DA NF"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0135, cPictChar })	//"Cód. da inf. complementar"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0136, cPictChar })	//"Informação Complementar"

	//REGISTRO A111: PROCESSO REFERENCIADO
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "NUM_PR",	"C",	015,	0 } ) 	//"_NUM_PROC"
	aAdd( aStru,{ "IND_PR",	"C",	001,	0 } ) 	//"_IND_PROC"
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )	
	
	CriaTMPReg(aStru,"RELAC4","A111",@aTrbs)
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0137))	//"A111 - PROCESSO REFERENCIADO "
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0138, cPictChar })	//"Identificação do processo ou ato concessório"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0139, cPictChar })	//"Origem do processo"
	
	IncProc("Gerando estrutura...")
	
	//REGISTRO A120: INFORMAÇÃO COMPLEMENTAR - OPERAÇÕES DE IMPORTAÇÃO
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",	"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "V_T_S",	"N",	014,	2 } ) 	//"_VL_TOT_SERV"
	aAdd( aStru,{ "V_B_P",	"N",	014,	2 } ) 	//"_VL_BC_PIS"
	aAdd( aStru,{ "V_P_I",	"N",	014,	2 } ) 	//"_VL_PIS_IMP"
	aAdd( aStru,{ "D_P_P",	"C",	008,	0 } ) 	//"_DT_PAG_PIS"
	aAdd( aStru,{ "V_B_C",	"N",	014,	2 } ) 	//"_VL_BC_COFINS"	
	aAdd( aStru,{ "V_C_I",	"N",	014,	2 } ) 	//"_VL_COFINS_IMP"
	aAdd( aStru,{ "D_P_C",	"C",	008,	0 } ) 	//"_DT_PAG_COFINS"	
	aAdd( aStru,{ "L_E_S",	"C",	001,	0 } ) 	//"_LOC_EXE_SERV"	
	aAdd( aStru,{ "RELAC4","C",	010,	0 } )	
	aAdd( aStrCmps,aStru )		

	CriaTMPReg(aStru,"RELAC4","A120",@aTrbs)
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0140))	//"A120 - INFORMAÇÃO COMPLEMENTAR - OPERAÇÕES DE IMPORTAÇÃO"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0141, cPictNUM })	//"Valor total do serviço"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0142, cPictNUM })	//"Valor da base de cálculo da Operação - PIS/PASEP"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0143, cPictNUM })	//"Valor pago/recolhido de PIS/PASEP"	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0144, cPictChar })	//"Data de pagamento do PIS/PASEP"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0145, cPictNUM })	//"Valor da base de cálculo da Operação - COFINS"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0146, cPictNUM })	//"Valor pago/recolhido de COFINS"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0147, cPictChar })	//"Data de pagamento do COFINS"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0148, cPictChar })	//"Local da execução do serviço"

	//REGISTRO A170: COMPLEMENTO DO DOCUMENTO - ITENS DO DOCUMENTO
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "NUM_IT",	"C",	004,	0 } ) 	//"_VL_TOT_SERV"
	aAdd( aStru,{ "COD_IT",	"C",	033,	0 } ) 	//"_VL_BC_PIS"
	aAdd( aStru,{ "DE_COM",	"C",	020,	0 } ) 	//"_VL_PIS_IMP"
	aAdd( aStru,{ "VL_ITE",	"N",	014,	2 } ) 	//"_DT_PAG_PIS"
	aAdd( aStru,{ "VL_DES",	"N",	014,	2 } ) 	//"_VL_BC_COFINS"	
	aAdd( aStru,{ "N_B_C",		"C",	002,	0 } ) 	//"_VL_COFINS_IMP"
	aAdd( aStru,{ "I_O_C",		"C",	001,	0 } ) 	//"_DT_PAG_COFINS"	
	aAdd( aStru,{ "CST_PI",	"C",	002,	0 } ) 	//"_LOC_EXE_SERV"	
	aAdd( aStru,{ "V_B_PI",	"N",	014,	2 } ) 	//"_LOC_EXE_SERV"		
	aAdd( aStru,{ "ALI_PI",	"N",	006,	2 } ) 	//"_LOC_EXE_SERV"	
	aAdd( aStru,{ "VL_PIS",	"N",	014,	2 } ) 	//"_LOC_EXE_SERV"
	aAdd( aStru,{ "C_COFI",	"C",	002,	0 } ) 	//"_LOC_EXE_SERV"
	aAdd( aStru,{ "V_B_CO",	"N",	014,	2 } ) 	//"_LOC_EXE_SERV"
	aAdd( aStru,{ "ALI_CO",	"N",	006,	2 } ) 	//"_LOC_EXE_SERV"
	aAdd( aStru,{ "VL_COF",	"N",	014,	2 } ) 	//"_LOC_EXE_SERV"
	aAdd( aStru,{ "COD_CT",	"C",	015,	0 } ) 	//"_LOC_EXE_SERV"
	aAdd( aStru,{ "COD_CC",	"C",	015,	0 } ) 	//"_LOC_EXE_SERV"							
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )
	
	CriaTMPReg(aStru,"RELAC4","A170",@aTrbs)

	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0149))	//"A170 - COMPLEMENTO DO DOCUMENTO - ITENS DO DOCUMENTO"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0039, cPictChar })	//"Número do item"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0066, cPictChar })	//"Código do item"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0150, cPictChar })	//"Descrição complementar"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0151, cPictNUM })	//"Valor total do item"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0152, cPictNUM })	//"Valor do desconto do item / Exclusão"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0153, cPictChar })	//"Código da Base de Cálculo do Crédito"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0154, cPictChar })	//"Origem do Crédito"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0155, cPictChar })	//"Código da Situação Tributária referente ao PIS/PASEP"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0156, cPictNUM })	//"Valor da base de cálculo do PIS/PASEP"	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0157, cPictALI1 })	//"Alíquota do PIS/PASEP - Percentual"	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0158, cPictNUM })	//"Valor do PIS/PASEP"	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0159, cPictChar })	//"Código da Situação Tributária"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0160, cPictNUM })	//"Valor da base de cálculo da COFINS"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0161, cPictALI1 })	//"Alíquota do COFINS - Percentual"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0162, cPictNUM })	//"Valor da COFINS"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0163, cPictChar })	//"Código da conta analítica contábil debitada/creditada"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0164, cPictChar })	//"Código do centro de custos"	
	
	//REGISTRO A990: ENCERRAMENTO DO BLOCO 0	
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) //"_REG"
	aAdd( aStru,{ "Q_LIN0",	"N",	010,	0 } ) //"_QTD_LIN_0"	
	aAdd( aStru,{ "RELAC",		"C",	010,	0 } )
	aAdd( aStrCmps,aStru )
	
	CriaTMPReg(aStru,"RELAC","A990",@aTrbs)
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0165))	//A990 - ENCERRAMENTO DO BLOCO 0
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0166, cPictChar })	//"Qtde tot. de linhas do Bloco A"*/
		
	//REGISTRO C001: ABERTURA DO BLOCO C
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) //"_REG"
	aAdd( aStru,{ "IND_MO",	"C",	001,	0 } ) //"_IND_MOV"	
	aAdd( aStru,{ "RELAC",		"C",	010,	0 } )
	aAdd( aStru,{ "RELAC2",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )
	
	CriaTMPReg(aStru,"RELAC","C001",@aTrbs)
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0167))	//"C001 - ABERTURA DO BLOCO C"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0031, cPictChar })	//"Movimento"
	
	//REGISTRO C010: IDENTIFICAÇÃO DO ESTABELECIMENTO
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "CNPJ",		"C",	020,	0 } )	//"_CNPJ"	
	aAdd( aStru,{ "I_ESCI",	"C",	001,	0 } )	//"_COD_NAT_CC"
	aAdd( aStru,{ "RELAC2",	"C",	010,	0 } )	
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )
	aAdd( aStrCmps,aStru )
	
	CriaTMPReg(aStru,"RELAC2","C010",@aTrbs)	
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0168))	//"C010 - IDENTIFICAÇÃO DO ESTABELECIMENTO"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0024, cPictCNPJ })	//"CNPJ"	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0169, cPictChar })	//"Apuração das contribuições e créditos"

	//REGISTRO C100: DOCUMENTO - NOTA FISCAL (CÓDIGO 01), NOTA FISCAL AVULSA (CÓDIGO 1B), NOTA FISCAL DE PRODUTOR (CÓDIGO 04) e NF-e (CÓDIGO 55)
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "IND_OP",	"C",	001,	0 } ) 		//"_IND_OPER"	
	aAdd( aStru,{ "I_E",		"C",	001,	0 } ) 		//"_IND_EMIT"
	aAdd( aStru,{ "C_P",		"C",	060,	0 } ) 		//"_COD_PART"
	aAdd( aStru,{ "COD_MO",	"C",	002,	0 } ) 		//"_COD_MOD"
	aAdd( aStru,{ "COD_SI",	"C",	002,	0 } ) 		//"_COD_SIT"
	aAdd( aStru,{ "SER",		"C",	020,	0 } ) 		//"_SER"
	aAdd( aStru,{ "NUM_DO",	"C",	060,	0 } ) 		//"_NUM_DOC"
	aAdd( aStru,{ "CHV_NF",	"C",	060,	0 } ) 		//"_CHV_NFSE"	
	aAdd( aStru,{ "DT_DOC",	"C",	008,	0 } ) 		//"_DT_DOC"
	aAdd( aStru,{ "DT_E_S",	"C",	008,	0 } ) 		//"_DT_EXE_SERV"
	aAdd( aStru,{ "VL_DOC",	"N",	014,	2 } ) 		//"_VL_DOC"
	aAdd( aStru,{ "I_PGTO",	"C",	001,	0 } ) 		//"_IND_PGTO"
	aAdd( aStru,{ "V_DESC",	"N",	014,	2 } ) 		//"_VL_DESC"
	aAdd( aStru,{ "VL_A_N",	"N",	014,	2 } ) 		//"_VL_ABAT_NT"
	aAdd( aStru,{ "VL_MER",	"N",	014,	2 } ) 		//"_VL_MERC"	
	aAdd( aStru,{ "IND_FR",	"C",	001,	0 } ) 		//"_VL_BC_COFINS"
	aAdd( aStru,{ "VL_FRT",	"N",	014,	2 } ) 		//"_VL_FRT"
	aAdd( aStru,{ "VL_SEG",	"N",	014,	2 } ) 		//"_VL_SEG"
	aAdd( aStru,{ "VL_O_D",	"N",	014,	2 } ) 		//"_VL_OUT_DA"
	aAdd( aStru,{ "V_BICM",	"N",	014,	2 } ) 		//"_VL_BC_ICMS"	
	aAdd( aStru,{ "V_ICMS",	"N",	014,	2 } ) 		//"_VL_BC_ICMS"		
	aAdd( aStru,{ "V_BI_S",	"N",	014,	2 } ) 		//"_VL_BC_ICMS"		
	aAdd( aStru,{ "V_IC_S",	"N",	014,	2 } ) 		//"_VL_ICMS_ST"		
	aAdd( aStru,{ "VL_IPI",	"N",	014,	2 } ) 		//"_VL_ICMS_ST"	
	aAdd( aStru,{ "VL_PIS",	"N",	014,	2 } ) 		//"_VL_ICMS_ST"	
	aAdd( aStru,{ "V_COFI",	"N",	014,	2 } ) 		//"_VL_COFINS"	
	aAdd( aStru,{ "V_PI_S",	"N",	014,	2 } ) 		//"_VL_COFINS"		
	aAdd( aStru,{ "V_CO_S",	"N",	014,	2 } ) 		//"_VL_COFINS"		
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )
	
	CriaTMPReg(aStru,"RELAC3","C100",@aTrbs)	
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0170))	//"C100: DOCUMENTO - NOTA FISCAL (CÓDIGO 01), NOTA FISCAL AVULSA (CÓDIGO 1B), NOTA FISCAL DE PRODUTOR (CÓDIGO 04) e NF-e (CÓDIGO 55)"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0114, cPictChar })	//"Tipo de Operação"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0115, cPictChar })	//"Emitente do documento fiscal"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0116, cPictChar })	//"Código do participante"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0171, cPictChar })	//"Cód. do modelo do documento fiscal"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0117, cPictChar })	//"Cód. da sit. do documento fiscal"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0118, cPictChar })	//"Série"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0172, cPictChar })	//"Número do documento fiscal"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0173, cPictChar })	//"Chave da NF-E"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0122, cPictChar })	//"Data da emissão"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0174, cPictChar })	//"Data da entrada ou da saída"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0124, cPictNUM })	//"Valor total"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0125, cPictChar })	//"Tipo de Pagamento"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0126, cPictNUM })	//"Valor total do desconto"	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0175, cPictNUM })	//"Abatimento não tributado e não comercial"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0176, cPictNUM })	//"Valor total das mercadorias e serviços"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0177, cPictChar })	//"Tipo do Frete"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0178, cPictNUM })	//"Valor do frete indicado no documento fiscal"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0179, cPictNUM })	//"Valor do seguro indicado no documento fiscal"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0180, cPictNUM })	//"Valor de outras despesas acessórias"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0181, cPictNUM })	//"Valor da base de cálculo do ICMS"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0182, cPictNUM })	//"Valor do ICMS"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0183, cPictNUM })	//"Valor da base de cálculo do ICMS substituição tributária"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0184, cPictNUM })	//"Valor do ICMS retido por substituição tributária"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0185, cPictNUM })	//"Valor total do IPI"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0128, cPictNUM })	//"Valor total do PIS"					
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0130, cPictNUM })	//"Valor total da COFINS"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0186, cPictNUM })	//"Valor total do PIS retido por substituição tributária"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0187, cPictNUM })	//"Valor total da COFINS retido por substituição tributária"	
	
	//REGISTRO C110: COMPLEMENTO DO DOCUMENTO - INFORMAÇÃO COMPLEMENTAR DA NOTA FISCAL (CÓDIGOS 01, 1B, 04 e 55)
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "COD_IN",	"C",	006,	0 } ) 	//"_COD_INF"
	aAdd( aStru,{ "TXT_CO",	"C",	060,	0 } ) 	//"_TXT_COMPL"
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )	
		
	CriaTMPReg(aStru,"RELAC4","C110",@aTrbs)
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0188))	//"C110 - COMPLEMENTO DO DOCUMENTO - INFORMAÇÃO COMPLEMENTAR DA NOTA FISCAL (CÓDIGOS 01, 1B, 04 e 55)"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0135, cPictChar })	//"Cód. da inf. complementar"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0136, cPictChar })	//"Informação Complementar"	
	
	//REGISTRO C111: PROCESSO REFERENCIADO
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "NUM_PR",	"C",	020,	0 } ) 	//"_NUM_PROC"
	aAdd( aStru,{ "IND_PR",	"C",	001,	0 } ) 	//"_IND_PROC"
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )	
	
	CriaTMPReg(aStru,"RELAC4","C111",@aTrbs)
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0189))	//"C111 - PROCESSO REFERENCIADO"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0138, cPictChar })	//"Identificação do processo ou ato concessório"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0139, cPictChar })	//"Origem do processo"
	
	//REGISTRO C120: COMPLEMENTO DO DOCUMENTO - OPERAÇÕES DE IMPORTAÇÃO (CÓDIGO 01) 
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "COD_DI",	"C",	001,	0 } ) 	//"_COD_DOC_IMP"
	aAdd( aStru,{ "N_D_IM",	"C",	010,	0 } ) 	//"_NUM_DOC_IMP"
	aAdd( aStru,{ "V_P_IM",	"N",	014,	2 } ) 	//"_VL_PIS_IMP"	
	aAdd( aStru,{ "V_C_IM",	"N",	014,	2 } ) 	//"_VL_COFINS_IMP"		
	aAdd( aStru,{ "N_ACDR",	"C",	020,	0 } ) 	//"_VL_COFINS_IMP"			
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )	

	CriaTMPReg(aStru,"RELAC4","C120",@aTrbs)	
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0190))	//"C120 - COMPLEMENTO DO DOCUMENTO - OPERACOES DE IMPORTACAO (CODIGO 01)"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0191, cPictChar })	//"Documento de importação"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0192, cPictChar })	//"Número do documento de Importação"	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0193, cPictNUM })	//"Valor pago de PIS na importação"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0194, cPictNUM })	//"Valor pago de COFINS na importação"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0195, cPictChar })	//"Número do Ato Concessório do regime"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0196, cPictChar })	//"Drawback"	
	
	//REGISTRO C170: COMPLEMENTO DO DOCUMENTO - ITENS DO DOCUMENTO (CÓDIGOS 01, 1B, 04 e 55)
	
	aStru	:=	{}
	
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "NUM_IT",	"C",	003,	0 } ) 	//"_NUM_ITEM"
	aAdd( aStru,{ "COD_IT",	"C",	060,	0 } ) 	//"_COD_ITEM"
	aAdd( aStru,{ "DES_CO",	"C",	060,	0 } ) 	//"_DESCR_COMPL"
	aAdd( aStru,{ "QTD",		"C",	006,	0 } ) 	//"_QTD"
	aAdd( aStru,{ "UNID",		"C",	006,	0 } ) 	//"_UNID"
	aAdd( aStru,{ "VL_ITE",	"N",	014,	2 } ) 	//"_VL_ITEM"
	aAdd( aStru,{ "VL_DES",	"N",	014,	2 } ) 	//"_VL_DESC"
	aAdd( aStru,{ "IND_MO",	"C",	001,	0 } ) 	//"_IND_MOV"
	aAdd( aStru,{ "C_ICMS",	"C",	003,	0 } ) 	//"_CST_ICMS"	
	aAdd( aStru,{ "CFOP",		"C",	004,	0 } ) 	//"_CFOP"
	aAdd( aStru,{ "COD_NA",	"C",	010,	0 } ) 	//"_COD_NAT"
	aAdd( aStru,{ "V_B_IC",	"N",	014,	2 } ) 	//"_VL_BC_ICMS"
	aAdd( aStru,{ "A_ICMS",	"N",	006,	2 } ) 	//"_ALIQ_ICMS"
	aAdd( aStru,{ "V_ICMS",	"N",	014,	2 } ) 	//"_VL_ICMS"
	aAdd( aStru,{ "VB_I_S",	"N",	014,	2 } ) 	//"_VL_BC_ICMS_ST"
	aAdd( aStru,{ "ALIQ_S",	"N",	006,	2 } ) 	//"_ALIQ_ST"
	aAdd( aStru,{ "V_I_ST",	"N",	014,	2 } ) 	//"_VL_ICMS_ST"
	aAdd( aStru,{ "I_APUR",	"C",	001,	0 } ) 	//"_IND_APUR"
	aAdd( aStru,{ "CS_IPI",	"C",	002,	0 } ) 	//"_CST_IPI"
	aAdd( aStru,{ "CO_ENQ",	"C",	003,	0 } ) 	//"_COD_ENQ"
	aAdd( aStru,{ "V_B_IP",	"N",	014,	2 } ) 	//"_VL_BC_IPI"
	aAdd( aStru,{ "AL_IPI",	"N",	006,	2 } ) 	//"_ALIQ_IPI"
	aAdd( aStru,{ "VL_IPI",	"N",	014,	2 } ) 	//"_VL_IPI"	
	aAdd( aStru,{ "CT_PIS",	"C",	002,	0 } ) 	//"_CST_PIS"
	aAdd( aStru,{ "VB_PIS",	"N",	014,	2 } ) 	//"_VL_BC_PIS"
	aAdd( aStru,{ "AL_PIS",	"N",	008,	4 } ) 	//"_ALIQ_PIS"	
	aAdd( aStru,{ "QB_PIS",	"N",	014,	3 } ) 	//"_QUANT_BC_PIS"
	aAdd( aStru,{ "A_P_QU",	"N",	014,	4 } ) 	//"_ALIQ_PIS_QUANT"	
	aAdd( aStru,{ "VL_PIS",	"N",	014,	2 } ) 	//"_VL_PIS"		
	aAdd( aStru,{ "CS_COF",	"C",	002,	0 } ) 	//"_CST_COFINS"	
	aAdd( aStru,{ "VB_COF",	"N",	014,	2 } ) 	//"_VL_BC_COFINS"
	aAdd( aStru,{ "AL_COF",	"N",	008,	4 } ) 	//"_ALIQ_COFINS"
	aAdd( aStru,{ "QB_COF",	"N",	014,	3 } ) 	//"_QUANT_BC_COFINS"
	aAdd( aStru,{ "A_C_QU",	"N",	014,	4 } ) 	//"_ALIQ_COFINS_QUANT"		
	aAdd( aStru,{ "VL_COF",	"N",	014,	2 } ) 	//"_VL_COFINS"
	aAdd( aStru,{ "CO_CTA",	"C",	060,	0 } ) 	//"_COD_CTA"
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )	
	
	CriaTMPReg(aStru,"RELAC4","C170",@aTrbs)
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0197))	//"C170 - COMPLEMENTO DO DOCUMENTO - ITENS DO DOCUMENTO (CÓDIGOS 01, 1B, 04 e 55)"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0198, cPictChar })	//"Núm. seq. do item"	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0066, cPictChar })	//"Código"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0200, cPictChar })	//"Desc. complementar"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0201, cPictChar })	//"Quantidade"	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0202, cPictChar })	//"Unidade"	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0124, cPictNUM })	//"Valor total do item (mercadorias ou serviços)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0203, cPictNUM })	//"Valor do desconto comercial"		
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0204, cPictChar })	//"Movimentação física do ITEM/PRODUTO"	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0205, cPictChar })	//"Código da Situação Tributária - ICMS"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0206, cPictChar })	//"CFOP"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0207, cPictChar })	//"Código da natureza da operação"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0208, cPictNUM })	//"Valor da base de cálculo do ICMS"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0209, cPictALI1 })	//"Alíquota do ICMS"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0210, cPictNUM })	//"Valor do ICMS creditado/debitado"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0211, cPictNUM })	//"Valor da base de cálculo referente à substituição tributária"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0212, cPictALI1 })	//"Alíquota do ICMS da substituição tributária na unidade da federação de destino"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0213, cPictNUM })	//"Valor do ICMS referente à substituição tributária"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0214, cPictChar })	//"Indicador de período de apuração do IPI"	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0215, cPictChar })	//"Código da Situação Tributária referente ao IPI, conforme a Tabela indicada no item 4.3.2."
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0216, cPictChar })	//"Código de enquadramento legal do IPI, conforme tabela indicada no item 4.5.3."
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0217, cPictNUM })	//"Valor da base de cálculo do IPI"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0218, cPictALI1 })	//"Alíquota do IPI"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0219, cPictNUM })	//"Valor do IPI creditado/debitado"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0220, cPictChar })	//"Código da Situação Tributária referente ao PIS"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0221, cPictNUM })	//"Valor da base de cálculo do PIS"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0222, cPictALI2 })	//"Alíquota do PIS - Percentual)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0223, cPictNUM })	//"Quantidade - Base de cálculo PIS/PASEP"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0224, cPictALI2 })	//"Alíquota do PIS (em reais)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0225, cPictNUM })	//"Valor do PIS"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0226, cPictChar })	//"Código da Situação Tributária referente ao COFINS"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0227, cPictNUM })	//"Valor da base de cálculo da COFINS"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0228, cPictALI2 })	//"Alíquota do COFINS (em percentual)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0229, cPictNUM })	//"Quantidade - Base de cálculo COFINS"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0230, cPictALI2 })	//"Alíquota da COFINS (em reais)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0231, cPictNUM })	//"Valor da COFINS"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0232, cPictChar })	//"Código da conta analítica contábil debitada/creditada"
		
	//REGISTRO C180: CONSOLIDAÇÃO DE NOTAS FISCAIS ELETRÔNICAS EMITIDAS PELA PESSOA JURÍDICA (CÓDIGO 55) - OPERAÇÕES DE VENDAS
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "COD_MO",	"C",	002,	0 } ) 		//"_COD_MOD"	
	aAdd( aStru,{ "DD_INI",	"C",	008,	0 } ) 		//DT_DOC_INI"
	aAdd( aStru,{ "DD_FIN",	"C",	008,	0 } ) 		//"_DT_DOC_FIN"
	aAdd( aStru,{ "COD_IT",	"C",	060,	0 } ) 		//"_COD_ITEM"
	aAdd( aStru,{ "COD_NC",	"C",	008,	0 } ) 		//"_COD_NCM"
	aAdd( aStru,{ "EX_IPI",	"C",	003,	0 } ) 		//"_EX_IPI"
	aAdd( aStru,{ "V_T_IT",	"N",	014,	2 } ) 		//"_NUM_DOC"
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )
	aAdd( aStrCmps,aStru )
	
	CriaTMPReg(aStru,"RELAC3","C180",@aTrbs)	
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0233))	//"C180 - CONSOLIDAÇÃO DE NOTAS FISCAIS ELETRÔNICAS EMITIDAS PELA PESSOA JURÍDICA (CÓDIGO 55) - OPERAÇÕES DE VENDAS"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0234, cPictChar })	//"Cód. da NF-E (modelo 55)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0235, cPictChar })	//"Data de Emissão Inicial"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0236, cPictChar })	//"Data de Emissão Final"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0237, cPictChar })	//"Cód. do Item"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0238, cPictChar })	//"Cód. da Nomenclatura Comum do Mercosul"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0239, cPictChar })	//"Código EX, conforme a TIPI"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0240, cPictNUM })	//"Valor Total do Item"

	//REGISTRO C181: DETALHAMENTO DA CONSOLIDAÇÃO - OPERAÇÕES DE VENDAS - PIS/PASEP
	
	aStru	:=	{}	
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "CST_PI",	"C",	002,	0 } ) 	//"_NUM_ITEM"
	aAdd( aStru,{ "CFOP",		"C",	004,	0 } ) 	//"_COD_ITEM"
	aAdd( aStru,{ "VL_ITE",	"N",	014,	2 } ) 	//"_DESCR_COMPL"
	aAdd( aStru,{ "VL_DES",	"N",	014,	2 } ) 	//"_QTD"
	aAdd( aStru,{ "VB_PIS",	"N",	014,	2 } ) 	//"_UNID"
	aAdd( aStru,{ "AL_PIS",	"N",	008,	4 } ) 	//"_VL_ITEM"
	aAdd( aStru,{ "QB_PIS",	"N",	014,	3 } ) 	//"_VL_DESC"
	aAdd( aStru,{ "AP_QUA",	"N",	008,	4 } ) 	//"_IND_MOV"
	aAdd( aStru,{ "VL_PIS",	"N",	014,	2 } ) 	//"_CST_ICMS"	
	aAdd( aStru,{ "CO_CTA",	"C",	060,	0 } ) 	//"_CST_ICMS"		
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )	
	
	CriaTMPReg(aStru,"RELAC4","C181",@aTrbs)
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0241))	//"C181 - DETALHAMENTO DA CONSOLIDAÇÃO - OPERAÇÕES DE VENDAS - PIS/PASEP"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0155, cPictChar })	//"Código da Situação Tributária referente ao PIS/PASEP, conforme a Tabela indicada no item 4.3.3."
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0206, cPictChar })	//Código fiscal de operação e prestação
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0242, cPictNUM })	//"Valor do item"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0203, cPictNUM })	//Valor do desconto comercial / Exclusão
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0156, cPictNUM })	//Valor da base de cálculo do PIS/PASEP
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0157, cPictALI2 })	//Alíquota do PIS/PASEP (em percentual)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0223, cPictNUM2 })	//Quantidade - Base de cálculo PIS/PASEP
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0224, cPictALI2 })	//Alíquota do PIS/PASEP (em reais)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0243, cPictNUM })	//"Valor do PIS/PASEP"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0232, cPictChar })	//"Código da conta analítica contábil debitada/creditada"	

	//REGISTRO C185: DETALHAMENTO DA CONSOLIDAÇÃO - OPERAÇÕES DE VENDAS - COFINS
	
	aStru	:=	{}	
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "CS_COF",	"C",	002,	0 } ) 	//"_CST_COFINS"
	aAdd( aStru,{ "CFOP",		"C",	004,	0 } ) 	//"_CFOP"
	aAdd( aStru,{ "VL_ITE",	"N",	014,	2 } ) 	//"_VL_ITEM"
	aAdd( aStru,{ "VL_DES",	"N",	014,	2 } ) 	//"_VL_DESC"
	aAdd( aStru,{ "V_B_CO",	"N",	014,	2 } ) 	//"_VL_BC_COFINS"
	aAdd( aStru,{ "AL_COF",	"N",	008,	4 } ) 	//"_ALIQ_COFINS"
	aAdd( aStru,{ "Q_B_CO",	"N",	014,	3 } ) 	//"_QUANT_BC_COFINS"
	aAdd( aStru,{ "A_C_QU",	"N",	008,	4 } ) 	//"_IND_MOV"
	aAdd( aStru,{ "V_COFI",	"N",	014,	2 } ) 	//"_VL_COFINS"	
	aAdd( aStru,{ "CO_CTA",	"C",	060,	0 } ) 	//"_COD_CTA"		
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )	
	
	CriaTMPReg(aStru,"RELAC4","C185",@aTrbs)	
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0244))	//"C185 - DETALHAMENTO DA CONSOLIDAÇÃO - OPERAÇÕES DE VENDAS - COFINS"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0226, cPictChar })	//Código da Situação Tributária referente a COFINS, conforme a Tabela indicada no item 4.3.4.
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0206, cPictChar })	//Código fiscal de operação e prestação
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0242, cPictNUM })	//"Valor do item"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0203, cPictNUM })	//Valor do desconto comercial / Exclusão
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0227, cPictNUM })	//Valor da base de cálculo da COFINS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0228, cPictALI2 })	//Alíquota da COFINS (em percentual)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0229, cPictNUM2 })	//Quantidade - Base de cálculo da COFINS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0230, cPictALI2 })	//Alíquota da COFINS (em reais)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0231, cPictNUM })	//Valor da COFINS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0232, cPictChar })	//"Código da conta analítica contábil debitada/creditada"	

	//REGISTRO C188: PROCESSO REFERENCIADO 
	
	aStru	:=	{}	
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "NUM_PR",	"C",	015,	0 } ) 	//"_NUM_PROC"
	aAdd( aStru,{ "IND_PR",	"C",	001,	0 } ) 	//"_IND_PROC"		
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )	
	
	CriaTMPReg(aStru,"RELAC4","C188",@aTrbs)
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0245))	//"C188 - PROCESSO REFERENCIADO"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0138, cPictChar })	//"Identificação do processo ou ato concessório"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0139, cPictChar })	//"Origem do processo"

	//REGISTRO C190: CONSOLIDAÇÃO DE NOTAS FISCAIS ELETRÔNICAS (CÓDIGO 55) - OPERAÇÕES DE AQUISIÇÃO COM DIREITO A CRÉDITO, E OPERAÇÕES DE DEVOLUÇÃO DE COMPRAS E VENDAS.
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "COD_MO",	"C",	002,	0 } ) 	//"_COD_MOD"	
	aAdd( aStru,{ "D_R_IN",	"C",	008,	0 } ) 	//_DT_REF_INI"
	aAdd( aStru,{ "D_R_FI",	"C",	008,	0 } ) 	//"_DT_REF_FIN"
	aAdd( aStru,{ "COD_IT",	"C",	060,	0 } ) 	//"_COD_ITEM"
	aAdd( aStru,{ "COD_NC",	"C",	008,	0 } ) 	//"_COD_NCM"
	aAdd( aStru,{ "EX_IPI",	"C",	003,	0 } ) 	//"_EX_IPI"
	aAdd( aStru,{ "V_T_IT",	"N",	014,	2 } ) 	//"_VL_TOT_ITEM"
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )
	aAdd( aStrCmps,aStru )
	
	CriaTMPReg(aStru,"RELAC3","C190",@aTrbs)	
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0246))	//"C190 - CONSOLIDAÇÃO DE NOTAS FISCAIS ELETRÔNICAS (CÓDIGO 55) - OPERAÇÕES DE AQUISIÇÃO COM DIREITO A CRÉDITO, E OPERAÇÕES DE DEVOLUÇÃO DE COMPRAS E VENDAS"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0234, cPictChar })	//"Cód. da NF-E (modelo 55)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0247, cPictChar })	//"Data Inicial de Referência da Consolidação"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0248, cPictChar })	//"Data Final de Referência da Consolidação"	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0237, cPictChar })	//"Cód. do Item"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0238, cPictChar })	//"Cód. da Nomenclatura Comum do Mercosul"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0239, cPictChar })	//"Código EX, conforme a TIPI"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0240, cPictNUM })	//"Valor Total do Item"

	IncProc("Gerando estrutura...")

	//REGISTRO C191: DETALHAMENTO DA CONSOLIDAÇÃO - OPERAÇÕES DE AQUISIÇÃO COM DIREITO A CRÉDITO, E OPERAÇÕES DE DEVOLUÇÃO DE COMPRAS E VENDAS - PIS/PASEP
	
	aStru	:=	{}	
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "CNPJ",		"C",	020,	0 } ) 	//"_NUM_ITEM"
	aAdd( aStru,{ "CS_PIS",	"C",	002,	0 } ) 	//"_CST_PIS"
	aAdd( aStru,{ "CFOP",		"C",	004,	0 } ) 	//"_CFOP"
	aAdd( aStru,{ "VL_ITE",	"N",	014,	2 } ) 	//"_VL_ITEM"
	aAdd( aStru,{ "VL_DES",	"N",	014,	2 } ) 	//"_VL_DESC"
	aAdd( aStru,{ "VB_PIS",	"N",	014,	2 } ) 	//"_VL_BC_PIS"
	aAdd( aStru,{ "AL_PIS",	"N",	008,	4 } ) 	//"_ALIQ_PIS"
	aAdd( aStru,{ "QB_PIS",	"N",	014,	3 } ) 	//"_QUANT_BC_PIS"
	aAdd( aStru,{ "AP_QUA",	"N",	008,	4 } ) 	//"_ALIQ_PIS_QUANT"
	aAdd( aStru,{ "VL_PIS",	"N",	014,	2 } ) 	//"_VL_PIS"	
	aAdd( aStru,{ "CO_CTA",	"C",	060,	0 } ) 	//"_COD_CTA"		
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )	
	
	CriaTMPReg(aStru,"RELAC4","C191",@aTrbs)	
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0249))	//"C191 - DETALHAMENTO DA CONSOLIDAÇÃO - OPERAÇÕES DE AQUISIÇÃO COM DIREITO A CRÉDITO, E OPERAÇÕES DE DEVOLUÇÃO DE COMPRAS E VENDAS - PIS/PASEP"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0250, cPictChar })	//"CNPJ/CPF do Participante"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0155, cPictChar })	//Código da Situação Tributária referente ao PIS/PASEP
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0206, cPictChar })	//"Código fiscal de operação e prestação"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0242, cPictNUM })	//Valor do item
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0203, cPictNUM })	//Valor do desconto comercial / Exclusão
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0127, cPictNUM })	//Valor da base de cálculo do PIS/PASEP
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0222, cPictALI2 })	//Alíquota do PIS/PASEP (Porcentagem)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0223, cPictNUM2 })	//Quantidade - Base de cálculo PIS/PASEP
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0224, cPictALI2 })	//Alíquota do PIS/PASEP (em reais)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0243, cPictNUM })	//"Valor do PIS/PASEP"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0232, cPictChar })	//"Código da conta analítica contábil debitada/creditada"
	
	//REGISTRO C195: DETALHAMENTO DA CONSOLIDAÇÃO - OPERAÇÕES DE AQUISIÇÃO COM DIREITO A CRÉDITO, E OPERAÇÕES DE DEVOLUÇÃO DE COMPRAS E VENDAS - COFINS
	
	aStru	:=	{}	
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "CNPJ",		"C",	020,	0 } ) 	//"_CNPJ_CPF_PART"
	aAdd( aStru,{ "CS_COF",	"C",	002,	0 } ) 	//"_CST_PIS"
	aAdd( aStru,{ "CFOP",		"C",	004,	0 } ) 	//"_CFOP"
	aAdd( aStru,{ "VL_ITE",	"N",	014,	2 } ) 	//"_VL_ITEM"
	aAdd( aStru,{ "VL_DES",	"N",	014,	2 } ) 	//"_VL_DESC"
	aAdd( aStru,{ "V_B_CO",	"N",	014,	2 } ) 	//"_VL_BC_PIS"
	aAdd( aStru,{ "AL_COF",	"N",	008,	4 } ) 	//"_ALIQ_PIS"
	aAdd( aStru,{ "Q_B_CO",	"N",	014,	3 } ) 	//"_QUANT_BC_PIS"
	aAdd( aStru,{ "A_C_QU",	"N",	008,	4 } ) 	//"_ALIQ_PIS_QUANT"
	aAdd( aStru,{ "VL_COF",	"N",	014,	2 } ) 	//"_VL_PIS"	
	aAdd( aStru,{ "CO_CTA",	"C",	060,	0 } ) 	//"_COD_CTA"		
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )	
	
	CriaTMPReg(aStru,"RELAC4","C195",@aTrbs)	
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0251))	//"C195 - DETALHAMENTO DA CONSOLIDAÇÃO - OPERAÇÕES DE AQUISIÇÃO COM DIREITO A CRÉDITO, E OPERAÇÕES DE DEVOLUÇÃO DE COMPRAS E VENDAS - COFINS"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0250, cPictChar })	//"CNPJ/CPF do Participante"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0226, cPictChar })	//Código da Situação Tributária referente a COFINS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0206, cPictChar })	//"Código fiscal de operação e prestação"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0242, cPictNUM })	//Valor do item
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0203, cPictNUM })	//Valor do desconto comercial / Exclusão
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0227, cPictNUM })	//Valor da base de cálculo da COFINS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0228, cPictALI2 })	//Alíquota da COFINS (em percentual)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0229, cPictNUM2 })	//Quantidade - Base de cálculo da COFINS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0230, cPictALI2 })	//"Alíquota da COFINS (em reais)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0162, cPictNUM })	//Valor da COFINS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0232, cPictChar })	//"Código da conta analítica contábil debitada/creditada"	
	
	//REGISTRO C198: PROCESSO REFERENCIADO
	
	aStru	:=	{}	
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "NUM_PR",	"C",	015,	0 } ) 	//"_NUM_PROC"
	aAdd( aStru,{ "IND_PR",	"C",	001,	0 } ) 	//"_IND_PROC"		
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )	
	
	CriaTMPReg(aStru,"RELAC4","C198",@aTrbs)	
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0252))	//"C198 - PROCESSO REFERENCIADO"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0138, cPictChar })	//"Identificação do processo ou ato concessório"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0139, cPictChar })	//"Origem do processo"	
	
	//REGISTRO C199: COMPLEMENTO DO DOCUMENTO - OPERAÇÕES DE IMPORTAÇÃO (CÓDIGO 55) 
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "COD_DI",	"C",	001,	0 } ) 	//"_COD_DOC_IMP"
	aAdd( aStru,{ "N_D_IM",	"C",	010,	0 } ) 	//"_NUM_DOC_IMP"
	aAdd( aStru,{ "V_P_IM",	"N",	014,	2 } ) 	//"_VL_PIS_IMP"	
	aAdd( aStru,{ "V_C_IM",	"N",	014,	2 } ) 	//"_VL_COFINS_IMP"		
	aAdd( aStru,{ "N_ACDR",	"C",	020,	0 } ) 	//"_NUM_ACDRAW"			
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )	
	
	CriaTMPReg(aStru,"RELAC4","C199",@aTrbs)	
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0253))	//"C199 - COMPLEMENTO DO DOCUMENTO - OPERAÇÕES DE IMPORTAÇÃO (CÓDIGO 55)"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0191, cPictChar })	//"Documento de importação"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0192, cPictChar })	//"Número do documento de Importação"	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0193, cPictNUM })	//"Valor pago de PIS na importação"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0194, cPictNUM })	//"Valor pago de COFINS na importação"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0195, cPictChar })	//"Número do Ato Concessório do regime"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0196, cPictChar })	//"Drawback"	
	
	//REGISTRO C380: NOTA FISCAL DE VENDA A CONSUMIDOR (CÓDIGO 02) - CONSOLIDAÇÃO DE DOCUMENTOS EMITIDOS
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "COD_MO",	"C",	002,	0 } ) 	//"_COD_MOD"	
	aAdd( aStru,{ "DD_INI",	"C",	008,	0 } ) 	//_DT_DOC_INI"
	aAdd( aStru,{ "DD_FIN",	"C",	008,	0 } ) 	//"_DT_DOC_FIN"
	aAdd( aStru,{ "ND_INI",	"C",	060,	0 } ) 	//"_NUM_DOC_INI"
	aAdd( aStru,{ "ND_FIN",	"C",	008,	0 } ) 	//"_NUM_DOC_FIN"
	aAdd( aStru,{ "VL_DOC",	"N",	014,	2 } ) 	//"_VL_DOC"
	aAdd( aStru,{ "VL_D_C",	"N",	014,	2 } ) 	//"_VL_TOT_ITEM"
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )
	aAdd( aStrCmps,aStru )
	
	CriaTMPReg(aStru,"RELAC3","C380",@aTrbs)	
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0254))	//"C380 - NOTA FISCAL DE VENDA A CONSUMIDOR (CÓDIGO 02) - CONSOLIDAÇÃO DE DOCUMENTOS EMITIDOS"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0171, cPictChar })	//"Código do modelo do documento fiscal, conforme a Tabela 4.1.1 (Código 02 - Nota Fiscal de Venda a Consumidor)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0235, cPictChar })	//"Data de Emissão Inicial dos Documentos"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0236, cPictChar })	//"Data de Emissão Final dos Documentos"	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0255, cPictChar })	//"Número do documento fiscal inicial"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0256, cPictChar })	//"Número do documento fiscal final"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0257, cPictNUM })	//"Valor total dos documentos emitidos"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0258, cPictNUM })	//"Valor total dos documentos cancelados"
	
	//REGISTRO C381: DETALHAMENTO DA CONSOLIDAÇÃO - PIS/PASEP
	
	aStru	:=	{}	
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "CS_PIS",	"C",	002,	0 } ) 	//"_CST_PIS"
	aAdd( aStru,{ "COD_IT",	"C",	060,	0 } ) 	//"_COD_ITEM"
	aAdd( aStru,{ "VL_ITE",	"N",	014,	2 } ) 	//"_VL_ITEM"
	aAdd( aStru,{ "V_B_PI",	"N",	014,	2 } ) 	//"_VL_DESC"
	aAdd( aStru,{ "AL_PIS",	"N",	008,	4 } ) 	//"_ALIQ_PIS"
	aAdd( aStru,{ "Q_B_PI",	"N",	014,	2 } ) 	//"_QUANT_BC_PIS"
	aAdd( aStru,{ "A_P_QT",	"N",	008,	4 } ) 	//"_ALIQ_PIS_QUANT"
	aAdd( aStru,{ "VL_PIS",	"N",	014,	2 } ) 	//"_VL_PIS"	
	aAdd( aStru,{ "CO_CTA",	"C",	030,	0 } ) 	//"_COD_CTA"		
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )	
	
	CriaTMPReg(aStru,"RELAC4","C381",@aTrbs)
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0259))	//"C381 - DETALHAMENTO DA CONSOLIDAÇÃO - PIS/PASEP"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0155, cPictChar })	//Código da Situação Tributária referente ao PIS/PASEP
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0237, cPictChar })	//"Código do item (campo 02 do Registro 0200)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0668, cPictNUM })	//Valor total dos itens
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0127, cPictNUM })	//Valor da base de cálculo do PIS/PASEP
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0157, cPictALI2 })	//Alíquota do PIS/PASEP (Percentual)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0223, cPictNUM })	//Quantidade - Base de cálculo PIS/PASEP
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0224, cPictALI2 })	//Alíquota do PIS/PASEP (em reais)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0243, cPictNUM })	//"Valor do PIS/PASEP"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0232, cPictChar })	//"Código da conta analítica contábil debitada/creditada"		

	//REGISTRO C385: DETALHAMENTO DA CONSOLIDAÇÃO - COFINS 
	
	aStru	:=	{}	
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "C_COFI",	"C",	002,	0 } ) 	//"_CST_COFINS"
	aAdd( aStru,{ "COD_IT",	"C",	060,	0 } ) 	//"_COD_ITEM"
	aAdd( aStru,{ "VL_ITE",	"N",	014,	2 } ) 	//"_VL_ITEM"
	aAdd( aStru,{ "V_B_CO",	"N",	014,	2 } ) 	//"_VL_BC_COFINS"
	aAdd( aStru,{ "AL_COF",	"N",	008,	4 } ) 	//"_ALIQ_COFINS"
	aAdd( aStru,{ "Q_B_CO",	"N",	014,	2 } ) 	//"_QUANT_BC_COFINS"
	aAdd( aStru,{ "A_C_QU",	"N",	014,	4 } ) 	//"_ALIQ_COFINS_QUANT"
	aAdd( aStru,{ "V_COFI",	"N",	014,	2 } ) 	//"_VL_COFINS"
	aAdd( aStru,{ "CO_CTA",	"C",	030,	0 } ) 	//"_COD_CTA"		
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )
	
	CriaTMPReg(aStru,"RELAC4","C385",@aTrbs)
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0261))	//"C385 - DETALHAMENTO DA CONSOLIDAÇÃO - COFINS"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0226, cPictChar })	//Código da Situação Tributária referente a COFINS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0237, cPictChar })	//"Código do item (campo 02 do Registro 0200)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0668, cPictNUM })	//Valor total dos itens
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0227, cPictNUM })	//Valor da base de cálculo da COFINS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0228, cPictALI2 })	//Alíquota da COFINS (em percentual)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0229, cPictNUM })	//Quantidade - Base de cálculo da COFINS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0230, cPictALI2 })	//"Alíquota da COFINS (em reais)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0162, cPictNUM })	//Valor da COFINS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0232, cPictChar })	//"Código da conta analítica contábil debitada/creditada"	
	
	//REGISTRO C395: NOTAS FISCAIS DE VENDA A CONSUMIDOR (CÓDIGOS 02, 2D, 2E e 59) - AQUISIÇÕES/ENTRADAS COM CRÉDITO
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "COD_MO",	"C",	002,	0 } ) 	//"_COD_MOD"	
	aAdd( aStru,{ "COD_PA",	"C",	060,	0 } ) 	//_COD_PART"
	aAdd( aStru,{ "SER",		"C",	003,	0 } ) 	//"_SER"
	aAdd( aStru,{ "SUB_SE",	"C",	001,	0 } ) 	//"_SUB_SER"
	aAdd( aStru,{ "NUM_DO",	"C",	006,	0 } ) 	//"_NUM_DOC"
	aAdd( aStru,{ "DT_DOC",	"C",	008,	0 } ) 	//"_VL_DOC"
	aAdd( aStru,{ "VL_DOC",	"N",	014,	2 } ) 	//"_VL_TOT_ITEM"
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )
	aAdd( aStrCmps,aStru )
		
	CriaTMPReg(aStru,"RELAC3","C395",@aTrbs)
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0262))	//"C395 - NOTAS FISCAIS DE VENDA A CONSUMIDOR (CÓDIGOS 02, 2D, 2E e 59) - AQUISIÇÕES/ENTRADAS COM CRÉDITO"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0171, cPictChar })	//"Código do modelo do documento fiscal, conforme a Tabela 4.1.1 (Código 02 - Nota Fiscal de Venda a Consumidor)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0116, cPictChar })	//"Data de Emissão Inicial dos Documentos"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0118, cPictChar })	//Série do documento fiscal
	aAdd( aTitulo[Len(aTitulo)][2],{ "" /*STR0119*/, cPictChar })	//Subsérie do documento fiscal
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0256, cPictChar })	//"Número do documento fiscal final"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0122, cPictChar })	//Data da emissão do documento fiscal
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0124, cPictNUM })	//Valor total do documento fiscal	
	
	//REGISTRO C396: ITENS DO DOCUMENTO (CÓDIGOS 02, 2D, 2E e 59) - AQUISIÇÕES/ENTRADAS COM CRÉDITO
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "CO_ITE",	"C",	030,	0 } ) 	//"_COD_ITEM"
	aAdd( aStru,{ "VL_ITE",	"N",	014,	2 } ) 	//"_VL_ITEM"
	aAdd( aStru,{ "VL_DES",	"N",	014,	2 } ) 	//"_VL_DESC"
	aAdd( aStru,{ "N_B_CR",	"C",	002,	0 } ) 	//"_NAT_BC_CRED"
	aAdd( aStru,{ "CS_PIS",	"C",	002,	0 } ) 	//"_CST_PIS"
	aAdd( aStru,{ "VB_PIS",	"N",	014,	2 } ) 	//"_VL_BC_PIS"
	aAdd( aStru,{ "AQ_PIS",	"N",	008,	4 } ) 	//"_ALIQ_PIS"
	aAdd( aStru,{ "VL_PIS",	"N",	014,	2 } ) 	//"_VL_PIS"
	aAdd( aStru,{ "CS_COF",	"C",	002,	0 } ) 	//"_CST_COFINS"
	aAdd( aStru,{ "V_B_CO",	"N",	014,	2 } ) 	//"_VL_BC_COFINS"
	aAdd( aStru,{ "AL_COF",	"N",	008,	4 } ) 	//"_ALIQ_COFINS"
	aAdd( aStru,{ "VL_COF",	"N",	014,	2 } ) 	//"_ALIQ_COFINS"
	aAdd( aStru,{ "CO_CTA",	"C",	030,	0 } ) 	//"_ALIQ_COFINS"
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )

	CriaTMPReg(aStru,"RELAC4","C396",@aTrbs)
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0263))	//"C396 - ITENS DO DOCUMENTO (CÓDIGOS 02, 2D, 2E e 59) - AQUISIÇÕES/ENTRADAS COM CRÉDITO"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0237, cPictChar })	//Código do item (campo 02 do Registro 0200)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0240, cPictNUM })	//Valor total do item (mercadorias ou serviços)	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0203, cPictNUM })	//Valor do desconto comercial do item
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0153, cPictChar })	//Código da Base de Cálculo do Crédito, conforme a Tabela indicada no item 4.3.7.
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0155, cPictChar })	//Código da Situação Tributária referente ao PIS/PASEP
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0156, cPictNUM })	//Valor da base de cálculo do crédito de PIS/PASEP
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0157, cPictALI2 })	//Alíquota do PIS/PASEP (em percentual)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0264, cPictNUM })	//"Valor do crédito de PIS/PASEP"	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0226, cPictChar })	//"Código da Situação Tributária referente a COFINS"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0227, cPictNUM })	//"Valor da base de cálculo do crédito de COFINS"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0228, cPictALI2 })	//"Alíquota da COFINS (em percentual)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0265, cPictNUM })	//"Valor do crédito de COFINS"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0232, cPictChar })	//"Código da conta analítica contábil debitada/creditada"
	
	//REGISTRO C400: EQUIPAMENTO ECF (CÓDIGOS 02 e 2D)
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "COD_MO",	"C",	002,	0 } ) 	//"_COD_MOD"	
	aAdd( aStru,{ "ECF_MO",	"C",	020,	0 } ) 	//_ECF_MOD"
	aAdd( aStru,{ "ECF_FA",	"C",	020,	0 } ) 	//"_ECF_FAB"
	aAdd( aStru,{ "ECF_CX",	"C",	003,	0 } ) 	//"_ECF_CX"
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )
	aAdd( aStrCmps,aStru )
		
	CriaTMPReg(aStru,"RELAC3","C400",@aTrbs)		
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0266))	//"C400 - EQUIPAMENTO ECF (CÓDIGOS 02 e 2D)"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0171, cPictChar })	//"Código do modelo do documento fiscal, conforme a Tabela 4.1.1 (Código 02 - Nota Fiscal de Venda a Consumidor)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0267, cPictChar })	//"Modelo do equipamento"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0268, cPictChar })	//"Número de série de fabricação do ECF"	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0269, cPictChar })	//"úmero do caixa atribuído ao ECF"	
	
	//REGISTRO C405: REDUÇÃO Z (CÓDIGOS 02 e 2D)
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "DT_DOC",	"C",	008,	0 } ) 	//"_COD_ITEM"
	aAdd( aStru,{ "CRO",		"C",	006,	0 } ) 	//"_VL_ITEM"
	aAdd( aStru,{ "CRZ",		"C",	006,	0 } ) 	//"_VL_DESC"
	aAdd( aStru,{ "N_C_FI",	"C",	006,	0 } ) 	//"_NAT_BC_CRED"
	aAdd( aStru,{ "VL_BRT",	"N",	014,	2 } ) 	//"_CST_PIS"
	aAdd( aStru,{ "GT_FIN",	"N",	014,	2 } ) 	//"_GT_FIN"	
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStru,{ "RELAC5",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )	

	CriaTMPReg(aStru,"RELAC4","C405",@aTrbs)
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0270))	//"C405 - REDUÇÃO Z (CÓDIGOS 02 e 2D)"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0271, cPictChar })	//"Data do movimento a que se refere a Redução Z"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0272, cPictChar })	//"Posição do Contador de Reinício de Operação"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0273, cPictChar })	//"Posição do Contador de Redução Z"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0274, cPictChar })	//"Número do Contador de Ordem de Operação do último documento emitido no dia (Número do COO na Redução Z)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0275, cPictNUM })	//"Valor do Grande Total final"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0276, cPictNUM })	//"Valor da venda bruta"	
	
	//REGISTRO C481: RESUMO DIÁRIO DE DOCUMENTOS EMITIDOS POR ECF - PIS/PASEP (CÓDIGOS 02 e 2D).
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "CS_PIS",	"C",	002,	0 } ) 	//"_CST_PIS"
	aAdd( aStru,{ "VL_ITE",	"N",	014,	2 } ) 	//"_VL_ITEM"
	aAdd( aStru,{ "V_B_PI",	"N",	014,	2 } ) 	//"_VL_BC_PIS"
	aAdd( aStru,{ "AL_PIS",	"N",	008,	4 } ) 	//"_ALIQ_PIS"
	aAdd( aStru,{ "QB_PIS",	"N",	006,	3 } ) 	//"_QUANT_BC_PIS"
	aAdd( aStru,{ "A_P_QU",	"N",	008,	4 } ) 	//"_ALIQ_PIS_QUANT"
	aAdd( aStru,{ "VL_PIS",	"N",	014,	2 } ) 	//"_VL_PIS"
	aAdd( aStru,{ "CO_ITE",	"C",	060,	0 } ) 	//"_COD_ITEM"
	aAdd( aStru,{ "CO_CTA",	"C",	060,	0 } ) 	//"_COD_CTA"
	aAdd( aStru,{ "RELAC5",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )	
	
	CriaTMPReg(aStru,"RELAC5","C481",@aTrbs)	
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0277))	//"C481 - RESUMO DIÁRIO DE DOCUMENTOS EMITIDOS POR ECF - PIS/PASEP (CÓDIGOS 02 e 2D)"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0155, cPictChar })	//"Cód. da Sit. Tributária referente ao PIS/PASEP"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0260, cPictNUM })	//"Vl. total dos itens"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0156, cPictNUM })	//Valor da base de cálculo do PIS/PASEP
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0157, cPictALI2 })	//Alíquota do PIS/PASEP (em percentual)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0223, cPictNUM })	//Quantidade - Base de cálculo PIS/PASEP
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0224, cPictALI2 })	//Alíquota do PIS/PASEP (em reais)	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0225, cPictNUM })	//Valor do PIS/PASEP	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0237, cPictChar })	//Código do item (campo 02 do Registro 0200)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0232, cPictChar })	//Código da conta analítica contábil debitada/creditada			
	
	//REGISTRO C485: RESUMO DIÁRIO DE DOCUMENTOS EMITIDOS POR ECF - COFINS (CÓDIGOS 02 e 2D)
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "C_COFI",	"C",	002,	0 } ) 	//"_CST_COFINS"
	aAdd( aStru,{ "VL_ITE",	"N",	014,	2 } ) 	//"_VL_ITEM"
	aAdd( aStru,{ "V_B_CO",	"N",	014,	2 } ) 	//"_VL_BC_COFINS"
	aAdd( aStru,{ "AL_COF",	"N",	008,	4 } ) 	//"_ALIQ_COFINS"
	aAdd( aStru,{ "Q_B_CO",	"N",	006,	3 } ) 	//"_QUANT_BC_COFINS"
	aAdd( aStru,{ "A_C_QU",	"N",	014,	4 } ) 	//"_ALIQ_COFINS_QUANT"
	aAdd( aStru,{ "V_COFI",	"N",	014,	2 } ) 	//"_VL_COFINS"
	aAdd( aStru,{ "COD_IT",	"C",	060,	0 } ) 	//"_COD_ITEM"
	aAdd( aStru,{ "CO_CTA",	"C",	060,	0 } ) 	//"_COD_CTA"
	aAdd( aStru,{ "RELAC5",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )	
	
	CriaTMPReg(aStru,"RELAC5","C485",@aTrbs)	
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0278))	//"C485 - RESUMO DIÁRIO DE DOCUMENTOS EMITIDOS POR ECF - COFINS (CÓDIGOS 02 e 2D)"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0159, cPictChar })	//Código da Situação Tributária referente a COFINS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0260, cPictNUM })	//Valor total dos itens
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0160, cPictNUM })	//"Vl. da base de cálculo da COFINS"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0161, cPictALI2 })	//"Alíquota do COFINS - Percentual"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0229, cPictNUM })	//Quantidade - Base de cálculo da COFINS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0230, cPictALI2 })	//Alíquota da COFINS (em reais) 
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0162, cPictNUM })	//"Vl. da COFINS"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0237, cPictChar })	//Código do item (campo 02 do Registro 0200)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0232, cPictChar })	//"Código da conta analítica contábil debitada/creditada"

	//REGISTRO C489: PROCESSO REFERENCIADO	
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "NUM_PR",	"C",	020,	0 } ) 	//"_NUM_PROC"
	aAdd( aStru,{ "IND_PR",	"C",	001,	0 } ) 	//"_IND_PROC"
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )	
	
	CriaTMPReg(aStru,"RELAC4","C489",@aTrbs)	
		
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0279))	//"C489: PROCESSO REFERENCIADO"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0138, cPictChar })	//"Identificação do processo ou ato concessório"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0139, cPictChar })	//"Origem do processo"	
	
	//REGISTRO C490: CONSOLIDAÇÃO DE DOCUMENTOS EMITIDOS POR ECF (CÓDIGOS 02, 2D e 59)
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "DD_INI",	"C",	008,	0 } ) 	//"_DT_DOC_INI"	
	aAdd( aStru,{ "DD_FIN",	"C",	008,	0 } ) 	//"_DT_DOC_FIN"
	aAdd( aStru,{ "COD_MO",	"C",	020,	0 } ) 	//"_COD_MOD"
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )		
	aAdd( aStrCmps,aStru )
		
	CriaTMPReg(aStru,"RELAC3","C490",@aTrbs)	
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0280))	//"C490 - CONSOLIDAÇÃO DE DOCUMENTOS EMITIDOS POR ECF (CÓDIGOS 02, 2D e 59)"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0235, cPictChar })	//"Data de Emissão Inicial dos Documentos"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0236, cPictChar })	//"Data de Emissão Final dos Documentos"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0171, cPictChar })	//"Código do modelo do documento fiscal, conforme a Tabela 4.1.1"

	//REGISTRO C491: DETALHAMENTO DA CONSOLIDAÇÃO DE DOCUMENTOS EMITIDOS POR ECF (CÓDIGOS 02, 2D e 59) - PIS/PASEP
	
	aStru	:=	{}	
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"	
	aAdd( aStru,{ "COD_IT",	"C",	030,	0 } ) 	//"_COD_ITEM"	
	aAdd( aStru,{ "CST_PI",	"C",	002,	0 } ) 	//"_CST_PIS"
	aAdd( aStru,{ "CFOP",		"C",	004,	0 } ) 	//"_COD_ITEM"
	aAdd( aStru,{ "VL_ITE",	"N",	014,	2 } ) 	//"_VL_ITEM"
	aAdd( aStru,{ "VB_PIS",	"N",	014,	2 } ) 	//"_VL_BC_PIS"
	aAdd( aStru,{ "AL_PIS",	"N",	008,	4 } ) 	//"_ALIQ_PIS"
	aAdd( aStru,{ "QB_PIS",	"N",	006,	3 } ) 	//"_QUANT_BC_PIS"
	aAdd( aStru,{ "AP_QUA",	"N",	008,	4 } ) 	//"_ALIQ_PIS_QUANT
	aAdd( aStru,{ "VL_PIS",	"N",	014,	2 } ) 	//"_CST_ICMS"	
	aAdd( aStru,{ "CO_CTA",	"C",	030,	0 } ) 	//"_CST_ICMS"		
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )
	
	CriaTMPReg(aStru,"RELAC4","C491",@aTrbs)	
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0281))	//"C491 - DETALHAMENTO DA CONSOLIDAÇÃO DE DOCUMENTOS EMITIDOS POR ECF (CÓDIGOS 02, 2D e 59) - PIS/PASEP"	
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0237, cPictChar })	//"Código do item (campo 02 do Registro 0200)"	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0155, cPictChar })	//"Código da Situação Tributária referente ao PIS/PASEP, conforme a Tabela indicada no item 4.3.3."
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0206, cPictChar })	//Código fiscal de operação e prestação
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0242, cPictNUM })	//"Valor do item"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0156, cPictNUM })	//Valor da base de cálculo do PIS/PASEP
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0157, cPictALI2 })	//Alíquota do PIS/PASEP (em percentual)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0223, cPictNUM })	//Quantidade - Base de cálculo PIS/PASEP
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0224, cPictALI2 })	//Alíquota do PIS/PASEP (em reais)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0243, cPictNUM })	//"Valor do PIS/PASEP"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0232, cPictChar })	//"Código da conta analítica contábil debitada/creditada"	
	
	//REGISTRO C495: DETALHAMENTO DA CONSOLIDAÇÃO DE DOCUMENTOS EMITIDOS POR ECF (CÓDIGOS 02, 2D e 59) - COFINS
	
	aStru	:=	{}	
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "COD_IT",	"C",	030,	0 } ) 	//"_COD_ITEM"	
	aAdd( aStru,{ "CS_COF",	"C",	002,	0 } ) 	//"_CST_COFINS"
	aAdd( aStru,{ "CFOP",		"C",	004,	0 } ) 	//"_CFOP"
	aAdd( aStru,{ "VL_ITE",	"N",	014,	2 } ) 	//"_VL_ITEM"
	aAdd( aStru,{ "V_B_CO",	"N",	014,	2 } ) 	//"_VL_BC_COFINS"
	aAdd( aStru,{ "AL_COF",	"N",	008,	4 } ) 	//"_ALIQ_COFINS"
	aAdd( aStru,{ "Q_B_CO",	"N",	006,	3 } ) 	//"_QUANT_BC_COFINS"
	aAdd( aStru,{ "A_C_QU",	"N",	014,	4 } ) 	//"_ALIQ_COFINS_QUANT"
	aAdd( aStru,{ "V_COFI",	"N",	014,	2 } ) 	//"_VL_COFINS"	
	aAdd( aStru,{ "CO_CTA",	"C",	030,	0 } ) 	//"_COD_CTA"		
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )	
		
	CriaTMPReg(aStru,"RELAC4","C495",@aTrbs)
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0282))	//"C495 - DETALHAMENTO DA CONSOLIDAÇÃO DE DOCUMENTOS EMITIDOS POR ECF (CÓDIGOS 02, 2D e 59) - COFINS"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0237, cPictChar })	//"Código do item (campo 02 do Registro 0200)"	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0226, cPictChar })	//Código da Situação Tributária referente a COFINS, conforme a Tabela indicada no item 4.3.4.
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0206, cPictChar })	//Código fiscal de operação e prestação
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0242, cPictNUM })	//"Valor do item"
   	aAdd( aTitulo[Len(aTitulo)][2],{ STR0227, cPictNUM })	//Valor da base de cálculo da COFINS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0228, cPictALI2 })	//Alíquota da COFINS (em percentual)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0229, cPictNUM })	//Quantidade - Base de cálculo da COFINS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0230, cPictALI2 })	//Alíquota da COFINS (em reais)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0231, cPictNUM })	//Valor da COFINS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0232, cPictChar })	//"Código da conta analítica contábil debitada/creditada"	
	
	IncProc("Gerando estrutura...")
	
	//REGISTRO C499: PROCESSO REFERENCIADO
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "NUM_PR",	"C",	020,	0 } ) 	//"_NUM_PROC"
	aAdd( aStru,{ "IND_PR",	"C",	001,	0 } ) 	//"_IND_PROC"
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )	
	
	CriaTMPReg(aStru,"RELAC4","C499",@aTrbs)
		
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0283))	//"C499 - PROCESSO REFERENCIADO"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0138, cPictChar })	//"Identificação do processo ou ato concessório"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0139, cPictChar })	//"Origem do processo"	
	
	//REGISTRO C500: NOTA FISCAL/CONTA DE ENERGIA ELÉTRICA (CÓDIGO 06), NOTA FISCAL/CONTA DE FORNECIMENTO D'ÁGUA CANALIZADA (CÓDIGO 29) E NOTA FISCAL CONSUMO FORNECIMENTO DE GÁS (CÓDIGO 28) - DOCUMENTOS DE ENTRADA/AQUISIÇÃO COM CRÉDITO
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "COD_PA",	"C",	030,	0 } ) 	//_COD_PART"
	aAdd( aStru,{ "COD_MO",	"C",	002,	0 } ) 	//"_COD_MOD"	
	aAdd( aStru,{ "COD_SI",	"C",	002,	0 } ) 	//"_COD_SIT"
	aAdd( aStru,{ "SER",		"C",	004,	0 } ) 	//"_SER"
	aAdd( aStru,{ "SUB",	 	"C",	001,	0 } ) 	//"_SUBR"
	aAdd( aStru,{ "NUM_DO",	"C",	015,	0 } ) 	//"_NUM_DOC"
	aAdd( aStru,{ "DT_DOC",	"C",	008,	0 } ) 	//"_DT_DOC"	
	aAdd( aStru,{ "DT_ENT",	"C",	008,	0 } ) 	//"_DT_ENT"	
	aAdd( aStru,{ "VL_DOC",	"N",	014,	2 } ) 	//"_VL_DOC"
	aAdd( aStru,{ "VL_ICM",	"N",	014,	2 } ) 	//"_VL_ICMS"	
	aAdd( aStru,{ "COD_IN",	"C",	006,	0 } ) 	//"_COD_INF"	
	aAdd( aStru,{ "VL_PIS",	"N",	014,	2 } ) 	//"_VL_PIS"	
	aAdd( aStru,{ "VL_COF",	"N",	014,	2 } ) 	//"_VL_COFINS"	
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )
	aAdd( aStrCmps,aStru )
			
	CriaTMPReg(aStru,"RELAC3","C500",@aTrbs)	
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0284))	//"C500 - NOTA FISCAL/CONTA DE ENERGIA ELÉTRICA (CÓDIGO 06), NOTA FISCAL/CONTA DE FORNECIMENTO D'ÁGUA CANALIZADA (CÓDIGO 29) E NOTA FISCAL CONSUMO FORNECIMENTO DE GÁS (CÓDIGO 28) - DOCUMENTOS DE ENTRADA/AQUISIÇÃO COM CRÉDITO" 
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0116, cPictChar })	//Código do participante do fornecedor (campo 02 do Registro 0150)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0171, cPictChar })	//"Código do modelo do documento fiscal, conforme a Tabela 4.1.1"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0117, cPictChar })	//Código da situação do documento fiscal, conforme a Tabela 4.1.2 
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0118, cPictChar })	//Série do documento fiscal
	aAdd( aTitulo[Len(aTitulo)][2],{ "" /*STR0119*/, cPictChar })	//Subsérie do documento fiscal
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0172, cPictChar })	//"Número do documento fiscal"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0122, cPictChar })	//Data da emissão do documento fiscal
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0285, cPictChar })	//"Data da entrada"	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0124, cPictNUM })	//"Valor total do documento fiscal"		
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0286, cPictNUM })	//"Valor acumulado do ICMS"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0090, cPictChar })	//"Código da informação complementar do documento fiscal (campo 02 do Registro 0450)"	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0243, cPictNUM })	//"Valor do PIS/PASEP"		
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0162, cPictNUM })	//"Valor da COFINS"	
	
	//REGISTRO C501: COMPLEMENTO DA OPERAÇÃO (CÓDIGOS 06, 28 e 29) - PIS/PASEP
	
	aStru	:=	{}	
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "CST_PI",	"C",	002,	0 } ) 	//"_CST_PIS"	
	aAdd( aStru,{ "VL_ITE",	"N",	014,	2 } ) 	//"_VL_ITEM"	
	aAdd( aStru,{ "N_B_CR",	"C",	002,	0 } ) 	//"_NAT_BC_CRED"
	aAdd( aStru,{ "VB_PIS",	"N",	014,	2 } ) 	//"_VL_BC_PIS"	
	aAdd( aStru,{ "AL_PIS",	"N",	008,	4 } ) 	//"_ALIQ_PIS"	
	aAdd( aStru,{ "VL_PIS",	"N",	014,	2 } ) 	//"_VL_PIS"	
	aAdd( aStru,{ "CO_CTA",	"C",	060,	0 } ) 	//"_CST_ICMS"		
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )	
	
	CriaTMPReg(aStru,"RELAC4","C501",@aTrbs)
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0287))	//"C501 - COMPLEMENTO DA OPERAÇÃO (CÓDIGOS 06, 28 e 29) - PIS/PASEP"	 
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0220, cPictChar })	//"Código da Situação Tributária referente ao PIS/PASEP"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0260, cPictNUM })	//Valor total dos itens
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0153, cPictChar })	//"Código da Base de Cálculo do Crédito, conforme a Tabela indicada no item 4.3.7."
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0156, cPictNUM })	//Valor da base de cálculo do PIS/PASEP
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0157, cPictALI2 })	//Alíquota do PIS/PASEP (em percentual)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0243, cPictNUM })	//"Valor do PIS/PASEP"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0232, cPictChar })	//"Código da conta analítica contábil debitada/creditada"	
	
	//REGISTRO C505: COMPLEMENTO DA OPERAÇÃO (CÓDIGOS 06, 28 e 29) - COFINS
	
	aStru	:=	{}	
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "C_COFI",	"C",	002,	0 } ) 	//"_CST_COFINS"
	aAdd( aStru,{ "VL_ITE",	"N",	014,	2 } ) 	//"_VL_ITEM"
	aAdd( aStru,{ "N_B_CR",	"C",	014,	2 } ) 	//"_NAT_BC_CRED"
	aAdd( aStru,{ "V_B_CO",	"N",	014,	2 } ) 	//"_VL_BC_COFINS"
	aAdd( aStru,{ "AL_COF",	"N",	008,	4 } ) 	//"_ALIQ_COFINS"
	aAdd( aStru,{ "V_COFI",	"N",	014,	2 } ) 	//"_VL_COFINS"
	aAdd( aStru,{ "CO_CTA",	"C",	060,	0 } ) 	//"_COD_CTA"		
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )
	
	CriaTMPReg(aStru,"RELAC4","C505",@aTrbs)	
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0288))	//"C505 - COMPLEMENTO DA OPERAÇÃO (CÓDIGOS 06, 28 e 29) - COFINS"	 	
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0226, cPictChar })	//Código da Situação Tributária referente a COFINS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0260, cPictNUM })	//Valor total dos itens
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0153, cPictChar })	//"Código da Base de Cálculo do Crédito, conforme a Tabela indicada no item 4.3.7 "
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0227, cPictNUM })	//Valor da base de cálculo da COFINS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0228, cPictALI2 })	//Alíquota da COFINS (em percentual)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0162, cPictNUM })	//Valor da COFINS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0232, cPictChar })	//"Código da conta analítica contábil debitada/creditada"	
	
	//REGISTRO C509: PROCESSO REFERENCIADO
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "NUM_PR",	"C",	020,	0 } ) 	//"_NUM_PROC"
	aAdd( aStru,{ "IND_PR",	"C",	001,	0 } ) 	//"_IND_PROC"
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )	
	
	CriaTMPReg(aStru,"RELAC4","C509",@aTrbs)
		 
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0289))	//"C509 - PROCESSO REFERENCIADO"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0138, cPictChar })	//"Identificação do processo ou ato concessório"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0139, cPictChar })	//"Origem do processo"	
	
	//REGISTRO C600: CONSOLIDAÇÃO DIÁRIA DE NOTAS FISCAIS/CONTAS EMITIDAS DE ENERGIA ELÉTRICA (CÓDIGO 06), NOTA FISCAL/CONTA DE FORNECIMENTO D'ÁGUA CANALIZADA (CÓDIGO 29) E NOTA FISCAL/CONTA DE FORNECIMENTO DE GÁS (CÓDIGO 28) (EMPRESAS OBRIGADAS OU NÃO OBRIGADAS AO CONVENIO ICMS 115/03) - DOCUMENTOS DE SAÍDA
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "COD_MO",	"C",	002,	0 } ) 	//_COD_MOD"
	aAdd( aStru,{ "COD_MU",	"C",	007,	0 } ) 	//_COD_MUN"
	aAdd( aStru,{ "SER",		"C",	004,	0 } ) 	//_SER"
	aAdd( aStru,{ "SUB",		"C",	001,	0 } ) 	//_SUB"
	aAdd( aStru,{ "COD_CO",	"C",	002,	0 } ) 	//_COD_CONS"	
	aAdd( aStru,{ "QTD_CO",	"C",	006,	0 } ) 	//_QTD_CONS"
	aAdd( aStru,{ "QTD_CA",	"C",	006,	0 } ) 	//_QTD_CANC"	
	aAdd( aStru,{ "DT_DOC",	"C",	008,	0 } ) 	//_DT_DOC"	
	aAdd( aStru,{ "VL_DOC",	"N",	014,	2 } ) 	//_VL_DOC"	
	aAdd( aStru,{ "VL_DES",	"N",	014,	2 } ) 	//_VL_DESC"	
	aAdd( aStru,{ "CONS",		"C",	008,	0 } ) 	//_CONS"
	aAdd( aStru,{ "VL_FOR",	"N",	014,	2 } ) 	//_VL_FORN"
	aAdd( aStru,{ "V_S_NT",	"N",	014,	2 } ) 	//_VL_SERV_NT"
	aAdd( aStru,{ "VL_TER",	"N",	014,	2 } ) 	//_VL_TERC"
	aAdd( aStru,{ "VL_DA",		"N",	014,	2 } ) 	//_VL_DA"
	aAdd( aStru,{ "VB_IC",		"N",	014,	2 } ) 	//_VL_BC_ICMS"
	aAdd( aStru,{ "V_ICM",		"N",	014,	2 } ) 	//_VL_ICMS"
	aAdd( aStru,{ "VBI_S",		"N",	014,	2 } ) 	//_VL_BC_ICMS_ST"
	aAdd( aStru,{ "V_I_S",		"N",	014,	2 } ) 	//"_VL_ICMS_ST"
	aAdd( aStru,{ "V_PIS",		"N",	014,	2 } ) 	//"_VL_PIS"
	aAdd( aStru,{ "V_COFS",	"N",	014,	2 } ) 	//"_VL_PIS"	
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )
	aAdd( aStrCmps,aStru )
				
	CriaTMPReg(aStru,"RELAC3","C600",@aTrbs)	
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0290))	//"C600 - CONSOLIDAÇÃO DIÁRIA DE NOTAS FISCAIS/CONTAS EMITIDAS DE ENERGIA ELÉTRICA (CÓDIGO 06), NOTA FISCAL/CONTA DE FORNECIMENTO D'ÁGUA CANALIZADA (CÓDIGO 29) E NOTA FISCAL/CONTA DE FORNECIMENTO DE GÁS (CÓDIGO 28) (EMPRESAS OBRIGADAS OU NÃO OBRIGADAS AO CONVENIO ICMS 115/03) - DOCUMENTOS DE SAÍDA"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0171, cPictChar })	//"Código do modelo do documento fiscal, conforme a Tabela 4.1.1"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0045, cPictChar })	//Código do município dos pontos de consumo, conforme a tabela IBGE
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0118, cPictChar })	//Série do documento fiscal
	aAdd( aTitulo[Len(aTitulo)][2],{ "" /*STR0119*/, cPictChar })	//Subsérie do documento fiscal
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0291, cPictChar })	//"Código de classe: consumo de energia elétrica / Código de Consumo de Fornecimento D água / Consumo de gás canalizado"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0292, cPictChar })	//"Quantidade de documentos consolidados neste registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0293, cPictChar })	//"Quantidade de documentos cancelados"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0294, cPictChar })	//"Data dos documentos consolidados"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0124, cPictNUM })	//Valor total dos documentos		
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0295, cPictNUM })	//"Valor acumulado dos descontos"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0296, cPictChar })	//"Consumo total acumulado, em kWh (Código 06)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0297, cPictNUM })	//"Valor acumulado do fornecimento"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0298, cPictNUM })	//"Valor acumulado dos serviços não-tributados pelo ICMS"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0299, cPictNUM })	//"Valores cobrados em nome de terceiros"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0300, cPictNUM })	//"Valor acumulado das despesas acessórias"	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0301, cPictNUM })	//"Valor acumulado da base de cálculo do ICMS"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0286, cPictNUM })	//Valor acumulado do ICMS	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0302, cPictNUM })	//"Valor acumulado da base de cálculo do ICMS substituição tributária"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0303, cPictNUM })	//"Valor acumulado do ICMS retido por substituição tributária"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0304, cPictNUM })	//"Valor acumulado do PIS/PASEP"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0305, cPictNUM })	//"Valor acumulado da COFINS"
	
	//REGISTRO C601: COMPLEMENTO DA CONSOLIDAÇÃO DIÁRIA (CÓDIGOS 06, 28 e 29) - DOCUMENTOS DE SAÍDAS - PIS/PASEP
	
	aStru	:=	{}	
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "CS_PIS",	"C",	002,	0 } ) 	//"_CST_PIS"
	aAdd( aStru,{ "VL_ITE",	"N",	014,	2 } ) 	//"_VL_ITEM"
	aAdd( aStru,{ "V_B_PI",	"N",	014,	2 } ) 	//"_VL_BC_PIS"
	aAdd( aStru,{ "AL_PIS",	"N",	008,	4 } ) 	//"_ALIQ_PIS"
	aAdd( aStru,{ "VL_PIS",	"N",	014,	2 } ) 	//"_VL_PIS"	
	aAdd( aStru,{ "CO_CTA",	"C",	060,	0 } ) 	//"_COD_CTA"		
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )	
		
	CriaTMPReg(aStru,"RELAC4","C601",@aTrbs)
		
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0306))	//"C601 - COMPLEMENTO DA CONSOLIDAÇÃO DIÁRIA (CÓDIGOS 06, 28 e 29) - DOCUMENTOS DE SAÍDAS - PIS/PASEP"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0155, cPictChar })	//Código da Situação Tributária referente ao PIS/PASEP
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0260, cPictNUM })	//Valor total dos itens
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0127, cPictNUM })	//Valor da base de cálculo do PIS/PASEP
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0157, cPictALI2 })	//Alíquota do PIS/PASEP (Percentual)	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0243, cPictNUM })	//"Valor do PIS/PASEP"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0232, cPictChar })	//"Código da conta analítica contábil debitada/creditada"	
	
	//REGISTRO C605: COMPLEMENTO DA CONSOLIDAÇÃO DIÁRIA (CÓDIGOS 06, 28 e 29) - DOCUMENTOS DE SAÍDAS - COFINS
	
	aStru	:=	{}	
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "CS_COF",	"C",	002,	0 } ) 	//"_CST_COFINS"
	aAdd( aStru,{ "VL_ITE",	"N",	014,	2 } ) 	//"_VL_ITEM"
	aAdd( aStru,{ "V_B_CO",	"N",	014,	2 } ) 	//"_VL_BC_COFINS"
	aAdd( aStru,{ "AL_COF",	"N",	008,	4 } ) 	//"_ALIQ_COFINS"
	aAdd( aStru,{ "V_COFI",	"N",	014,	2 } ) 	//"_VL_COFINS"	
	aAdd( aStru,{ "CO_CTA",	"C",	060,	0 } ) 	//"_COD_CTA"		
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )		
		
	CriaTMPReg(aStru,"RELAC4","C605",@aTrbs)
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0307))	//"C605 - COMPLEMENTO DA CONSOLIDAÇÃO DIÁRIA (CÓDIGOS 06, 28 e 29) - DOCUMENTOS DE SAÍDAS - COFINS"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0226, cPictChar })	//Código da Situação Tributária referente a COFINS, conforme a Tabela indicada no item 4.3.4.
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0242, cPictNUM })	//"Valor do item"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0227, cPictNUM })	//Valor da base de cálculo da COFINS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0228, cPictALI2 })	//Alíquota da COFINS (em percentual)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0231, cPictNUM })	//Valor da COFINS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0232, cPictChar })	//"Código da conta analítica contábil debitada/creditada"	
	
	//REGISTRO C609: PROCESSO REFERENCIADO  
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "NUM_PR",	"C",	020,	0 } ) 	//"_NUM_PROC"
	aAdd( aStru,{ "IND_PR",	"C",	001,	0 } ) 	//"_IND_PROC"
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )	
	
	CriaTMPReg(aStru,"RELAC4","C609",@aTrbs)	
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0308))	//"C609 - PROCESSO REFERENCIADO"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0138, cPictChar })	//"Identificação do processo ou ato concessório"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0139, cPictChar })	//"Origem do processo"	
		
	//REGISTRO C800: CUPOM FISCAL ELETRÔNICO (CÓDIGO 59)
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "COD_MO",	"C",	002,	0 } ) 	//"_COD_MOD"
	aAdd( aStru,{ "COD_SI",	"C",	002,	0 } ) 	//"_COD_SIT"
	aAdd( aStru,{ "NUM_CF",	"C",	009,	0 } ) 	//"_NUM_CFE"
	aAdd( aStru,{ "DT_DOC",	"C",	008,	0 } ) 	//"_DT_DOC"
	aAdd( aStru,{ "VL_CFE",	"N",	014,	2 } ) 	//"_VL_CFE"
	aAdd( aStru,{ "VL_PIS",	"N",	014,	2 } ) 	//"_VL_PIS"
	aAdd( aStru,{ "VL_COF",	"N",	014,	2 } ) 	//"_VL_COFINS"
	aAdd( aStru,{ "CNPJ_C",	"C",	020,	0 } ) 	//"_CNPJ_CPF"
	aAdd( aStru,{ "NR_SAT",	"C",	001,	0 } ) 	//"_NR_SAT"
	aAdd( aStru,{ "CHV_CF",	"C",	044,	0 } ) 	//"_CHV_CFE"
	aAdd( aStru,{ "VL_DES",	"N",	014,	2 } ) 	//"_VL_DESC"
	aAdd( aStru,{ "VL_MER",	"N",	014,	2 } ) 	//"_VL_MERC"
	aAdd( aStru,{ "V_O_DA",	"N",	014,	2 } ) 	//"_VL_OUT_DA"	
	aAdd( aStru,{ "VL_ICM",	"N",	014,	2 } ) 	//"_VL_ICMS"
	aAdd( aStru,{ "V_P_ST",	"N",	014,	2 } ) 	//"_VL_PIS_ST"
	aAdd( aStru,{ "V_C_ST",	"N",	014,	2 } ) 	//"_VL_COFINS_ST"	
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )	
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )	
	
	CriaTMPReg(aStru,"RELAC3","C800",@aTrbs)	
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0309))	//"C800 - CUPOM FISCAL ELETRÔNICO (CÓDIGO 59)"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0171, cPictChar })	//Código do modelo do documento fiscal, conforme a Tabela 4.1.1
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0117, cPictChar })	//Código da situação do documento fiscal, conforme a Tabela 4.1.2
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0039, cPictChar })	//"Número do Cupom Fiscal Eletrônico"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0122, cPictChar })	//Data da emissão do Cupom Fiscal Eletrônico
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0124, cPictNUM })	//Valor total do Cupom Fiscal Eletrônico
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0128, cPictNUM })	//Valor total do PIS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0130, cPictNUM })	//Valor total da COFINS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0024+"/"+STR0666, cPictChar })	//CNPJ ou CPF do destinatário
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0310, cPictChar })	//"Número de Série do equipamento SAT"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0311, cPictChar })	//"Chave do Cupom Fiscal Eletrônico"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0152, cPictNUM })	//Valor total do desconto/exclusão sobre item
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0176, cPictNUM })	//Valor total das mercadorias e serviços
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0312, cPictNUM })	//"Valor de outras desp. Acessórias (acréscimo)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0182, cPictNUM })	//Valor do ICMS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0186, cPictNUM })	//Valor total do PIS retido por subst. trib.
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0187, cPictNUM })	//Valor total da COFINS retido por subst. trib.
	
	//REGISTRO C810: DETALHAMENTO DO CUPOM FISCAL ELETRÔNICO (CÓDIGO 59) - PIS/PASEP E COFINS
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "CFOP",		"C",	004,	0 } ) 	//"_CFOP"
	aAdd( aStru,{ "V_ITEM",	"N",	014,	2 } ) 	//"_COD_SIT"
	aAdd( aStru,{ "C_ITEM",	"C",	060,	0 } ) 	//"_NUM_CFE"
	aAdd( aStru,{ "CT_PIS",	"N",	002,	0 } ) 	//"_DT_DOC"
	aAdd( aStru,{ "VB_PIS",	"N",	014,	2 } ) 	//"_VL_CFE"
	aAdd( aStru,{ "AL_PIS",	"N",	008,	4 } ) 	//"_ALIQ_PIS"
	aAdd( aStru,{ "VL_PIS",	"N",	014,	2 } ) 	//"_VL_COFINS"
	aAdd( aStru,{ "CS_COF",	"C",	002,	0 } ) 	//"_CST_COFINS"
	aAdd( aStru,{ "VB_COF",	"N",	014,	2 } ) 	//"_VL_BC_COFINS"
	aAdd( aStru,{ "AL_COF",	"N",	008,	4 } ) 	//"_CHV_CFE"
	aAdd( aStru,{ "VL_COF",	"N",	014,	2 } ) 	//"_VL_DESC"
	aAdd( aStru,{ "CO_CTA",	"C",	060,	2 } ) 	//"_VL_MERC"	
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )
	
	CriaTMPReg(aStru,"RELAC4","C810",@aTrbs)	
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0313))	//"C810 - DETALHAMENTO DO CUPOM FISCAL ELETRÔNICO (CÓDIGO 59) - PIS/PASEP E COFINS"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0206, cPictChar })	//Código fiscal de operação e prestação	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0260, cPictNUM })	//Valor total dos itens
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0237, cPictChar })	//Código do item (campo 02 do Registro 0200)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0155, cPictChar })	//Código da Situação Tributária referente ao PIS/PASEP	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0156, cPictNUM })	//Valor da base de cálculo do PIS/PASEP
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0222, cPictALI2 })	//Alíquota do PIS/PASEP (em percentual)	                                                                                               
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0158, cPictNUM })	//Valor do PIS/PASEP
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0226, cPictChar })	//Código da Situação Tributária referente a COFINS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0129, cPictNUM })	//Valor da base de cálculo da COFINS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0161, cPictALI2 })	//Alíquota da COFINS (em percentual)	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0162, cPictNUM })	//Valor da COFINS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0232, cPictChar })	//Código da conta analítica contábil debitada/creditada
	
	//REGISTRO C820: DETALHAMENTO DO CUPOM FISCAL ELETRÔNICO (CÓDIGO 59) - PIS/PASEP E COFINS APURADO POR UNIDADE DE MEDIDA DE PRODUTO
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "CFOP",		"C",	004,	0 } ) 	//"_CFOP"
	aAdd( aStru,{ "V_ITEM",	"N",	014,	2 } ) 	//"_COD_SIT"
	aAdd( aStru,{ "C_ITEM",	"C",	060,	0 } ) 	//"_COD_ITEM"
	aAdd( aStru,{ "CT_PIS",	"C",	002,	0 } ) 	//"_DT_DOC"
	aAdd( aStru,{ "QB_PIS",	"N",	014,	2 } ) 	//"_QUANT_BC_PIS"
	aAdd( aStru,{ "AP_QUA",	"N",	008,	2 } ) 	//"_ALIQ_PIS"
	aAdd( aStru,{ "VL_PIS",	"N",	014,	2 } ) 	//"_VL_PIS"
	aAdd( aStru,{ "CS_COF",	"C",	002,	0 } ) 	//"_CST_COFINS"
	aAdd( aStru,{ "QB_COF",	"N",	014,	2 } ) 	//"_VL_BC_COFINS"
	aAdd( aStru,{ "AC_QUA",	"N",	014,	4 } ) 	//"_ALIQ_COFINS_QUANT"
	aAdd( aStru,{ "VL_COF",	"N",	014,	2 } ) 	//"_VL_COFINS"
	aAdd( aStru,{ "CO_CTA",	"C",	060,	2 } ) 	//"_VL_MERC"	
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )
	
	CriaTMPReg(aStru,"RELAC4","C820",@aTrbs)	
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0319))	//"C820 - DETALHAMENTO DO CUPOM FISCAL ELETRÔNICO (CÓDIGO 59) - PIS/PASEP E COFINS APURADO POR UNIDADE DE MEDIDA DE PRODUTO"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0206, cPictChar })	//Código fiscal de operação e prestação	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0260, cPictNUM })	//Valor total dos itens	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0237, cPictChar })	//Código do item (campo 02 do Registro 0200)	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0155, cPictChar })	//Código da Situação Tributária referente ao PIS/PASEP	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0223, cPictNUM })	//Base de cálculo em quantidade - PIS/PASEP	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0224, cPictALI2 })	//Alíquota do PIS/PASEP (em reais)	                                                                                               
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0158, cPictNUM })	//Valor do PIS/PASEP	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0226, cPictChar })	//Código da Situação Tributária referente a COFINS	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0229, cPictNUM })	//base de cálculo da COFINS	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0230, cPictALI2 })	//Alíquota da COFINS (em reais)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0231, cPictNUM })	//Valor da COFINS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0232, cPictChar })	//Código da conta analítica contábil debitada/creditada

	//REGISTRO C830: PROCESSO RERENCIADO

	aStru	:=	{}
	aAdd( aStru,{ "REG",    "C", 004, 0 } ) //"_REG"
	aAdd( aStru,{ "NUM_PR", "C", 020, 0 } ) //"_NUM_PROC"
	aAdd( aStru,{ "IND_PR", "C", 001, 0 } ) //"_IND_PROC"
	aAdd( aStru,{ "RELAC4", "C", 010, 0 } )
	aAdd( aStrCmps,aStru )

	CriaTMPReg(aStru,"RELAC4","C830",@aTrbs)

	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0314)) //"C830 - PROCESSO RERENCIADO"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar }) //"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0138, cPictChar }) //"Identificação do processo ou ato concessório"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0139, cPictChar }) //"Origem do processo"

	//REGISTRO C860: IDENTIFICAÇÃO DO EQUIPAMENTO SAT-CF-E

	aStru	:=	{}
	aAdd( aStru,{ "REG",    "C", 004, 0 } ) //"_REG"
	aAdd( aStru,{ "COD_MO", "C", 002, 0 } ) //"_COD_MOD"
	aAdd( aStru,{ "NR_SAT", "C", 009, 0 } ) //"_NR_SAT"
	aAdd( aStru,{ "DT_DOC", "C", 008, 0 } ) //"_DT_DOC"
	aAdd( aStru,{ "DO_INI", "C", 009, 0 } ) //"_DOC_INI"
	aAdd( aStru,{ "DO_FIM", "C", 009, 0 } ) //"_DOC_FIM"
	aAdd( aStru,{ "RELAC3", "C", 010, 0 } )
	aAdd( aStru,{ "RELAC4", "C", 010, 0 } )
	aAdd( aStrCmps,aStru )

	CriaTMPReg(aStru,"RELAC3","C860",@aTrbs)

	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0315)) //"C860 - IDENTIFICAÇÃO DO EQUIPAMENTO SAT-CF-E"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar }) //"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0171, cPictChar }) //Código do modelo do documento fiscal, conforme a Tabela 4.1.1
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0310, cPictChar }) //Número de Série do equipamento SAT
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0122, cPictChar }) //Data de emissão dos documentos fiscais
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0316, cPictChar }) //"Número do documento inicial"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0317, cPictChar }) //"Número do documento final"
	
	//REGISTRO C870: RESUMO DIÁRIO DE DOCUMENTOS EMITIDOS POR EQUIPAMENTO SAT-CF-E (CÓDIGO 59) - PIS/PASEP E COFINS
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",    "C", 004, 0 } ) //"_REG"
	aAdd( aStru,{ "C_ITEM", "C", 060, 0 } ) //"_COD_ITEM"
	aAdd( aStru,{ "CFOP",   "C", 004, 0 } ) //"_CFOP"
	aAdd( aStru,{ "V_ITEM", "N", 014, 2 } ) //"_VL_ITEM"
	aAdd( aStru,{ "V_DESC", "N", 014, 2 } ) //"_VL_DESC"
	aAdd( aStru,{ "CT_PIS", "C", 002, 0 } ) //"_CST_PIS"
	aAdd( aStru,{ "VB_PIS", "N", 014, 2 } ) //"_VL_BC_PIS"
	aAdd( aStru,{ "AL_PIS", "N", 008, 4 } ) //"_ALIQ_PIS"
	aAdd( aStru,{ "VL_PIS", "N", 014, 2 } ) //"_VL_PIS"
	aAdd( aStru,{ "CS_COF", "C", 002, 0 } ) //"_CST_COFINS"
	aAdd( aStru,{ "VB_COF", "N", 014, 2 } ) //"_VL_BC_COFINS"
	aAdd( aStru,{ "A_COFI", "N", 014, 4 } ) //"_ALIQ_COFINS_QUANT"
	aAdd( aStru,{ "VL_COF", "N", 014, 2 } ) //"_VL_COFINS"
	aAdd( aStru,{ "CO_CTA", "C", 060, 2 } ) //"_VL_MERC"
	aAdd( aStru,{ "RELAC4", "C", 010, 0 } )
	aAdd( aStrCmps,aStru )

	CriaTMPReg(aStru,"RELAC4","C870",@aTrbs)

	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0318))	//"C870 - RESUMO DIÁRIO DE DOCUMENTOS EMITIDOS POR EQUIPAMENTO SAT-CF-E (CÓDIGO 59) - PIS/PASEP E COFINS"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0206, cPictChar })	//Código fiscal de operação e prestação	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0260, cPictNUM })	//Valor total dos itens	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0237, cPictChar })	//Código do item (campo 02 do Registro 0200)	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0220, cPictChar })	//Código da Situação Tributária referente ao PIS/PASEP	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0221, cPictNUM })	//Valor da base de cálculo do PIS/PASEP	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0157, cPictALI2 })	//Alíquota do PIS/PASEP (em percentual)	                                                                                               
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0158, cPictNUM })	//Valor do PIS/PASEP		
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0226, cPictChar })	//Código da Situação Tributária referente a COFINS	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0227, cPictNUM })	//Valor da base de cálculo da COFINS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0161, cPictALI2 })	//Alíquota da COFINS (em percentual)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0162, cPictNUM })	//Valor da COFINS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0232, cPictChar })	//Código da conta analítica contábil debitada/creditada
   
	IncProc("Gerando estrutura...")
	  	     
	//REGISTRO C880: RESUMO DIÁRIO DE DOCUMENTOS EMITIDOS POR EQUIPAMENTO SAT-CF-E (CÓDIGO 59) - PIS/PASEP E COFINS APURADO POR UNIDADE DE MEDIDA DE PRODUTO
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "C_ITEM",	"C",	060,	0 } ) 	//"_COD_ITEM"
	aAdd( aStru,{ "CFOP",		"C",	004,	0 } ) 	//"_CFOP"
	aAdd( aStru,{ "V_ITEM",	"N",	014,	2 } ) 	//"_VL_ITEM"
	aAdd( aStru,{ "CT_PIS",	"C",	002,	0 } ) 	//"_CST_PIS"	
	aAdd( aStru,{ "QB_PIS",	"N",	014,	2 } ) 	//"_QUANT_BC_PIS"	
	aAdd( aStru,{ "AP_QUA",	"N",	008,	4 } ) 	//"_ALIQ_PIS_QUANT"
	aAdd( aStru,{ "VL_PIS",	"N",	014,	2 } ) 	//"_VL_PIS"
	aAdd( aStru,{ "CS_COF",	"C",	002,	0 } ) 	//"_CST_COFINS"
	aAdd( aStru,{ "QB_COF",	"N",	014,	2 } ) 	//"_QUANT_BC_COFINS"
	aAdd( aStru,{ "A_COFI",	"N",	014,	4 } ) 	//"_ALIQ_COFINS_QUANT"	
	aAdd( aStru,{ "VL_COF",	"N",	014,	2 } ) 	//"_VL_COFINS"
	aAdd( aStru,{ "CO_CTA",	"C",	060,	2 } ) 	//"_VL_MERC"	
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )	

	CriaTMPReg(aStru,"RELAC4","C880",@aTrbs)	
		
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0323))	//"C880 - RESUMO DIÁRIO DE DOCUMENTOS EMITIDOS POR EQUIPAMENTO SAT-CF-E (CÓDIGO 59) - PIS/PASEP E COFINS APURADO POR UNIDADE DE MEDIDA DE PRODUTO"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0237, cPictChar })	//Código do item (campo 02 do Registro 0200)		
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0206, cPictChar })	//Código fiscal de operação e prestação	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0260, cPictNUM })	//Valor total dos itens	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0220, cPictChar })	//Código da Situação Tributária referente ao PIS/PASEP	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0223, cPictNUM })	//Base de cálculo em quantidade - PIS/PASEP
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0224, cPictALI2 })	//Alíquota do PIS/PASEP (em reais)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0158, cPictNUM })	//Valor do PIS/PASEP		
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0226, cPictChar })	//Código da Situação Tributária referente a COFINS		
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0229, cPictNUM })	//Base de cálculo em quantidade - COFINS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0224, cPictALI2 })	//Alíquota da COFINS (em percentual)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0231, cPictNUM })	//Valor da COFINS   
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0232, cPictChar })	//Código da conta analítica contábil debitada/creditada
	
	//REGISTRO C890: PROCESSO REFERENCIADO
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "NUM_PR",	"C",	020,	0 } ) 	//"_NUM_PROC"
	aAdd( aStru,{ "IND_PR",	"C",	001,	0 } ) 	//"_IND_PROC"
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )	
	
	CriaTMPReg(aStru,"RELAC4","C890",@aTrbs)
		
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0320))	//"C890 - PROCESSO REFERENCIADO"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0138, cPictChar })	//"Identificação do processo ou ato concessório"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0139, cPictChar })	//"Origem do processo"	
	
	//REGISTRO C990: ENCERRAMENTO DO BLOCO C
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) //"_REG"
	aAdd( aStru,{ "Q_LIN0",	"N",	010,	0 } ) //"_QTD_LIN_0"	
	aAdd( aStru,{ "RELAC",		"C",	010,	0 } )
	aAdd( aStrCmps,aStru )
	
	CriaTMPReg(aStru,"RELAC","C990",@aTrbs)	
	 
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0321))	//"C990 - ENCERRAMENTO DO BLOCO C"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0322, cPictChar })	//"Quantidade total de linhas do Bloco C"	
	
	//REGISTRO D001: ABERTURA DO BLOCO D
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) //"_REG"
	aAdd( aStru,{ "IND_MO",	"C",	003,	0 } ) //"_IND_MOV"
	aAdd( aStru,{ "RELAC",		"C",	010,	0 } )
	aAdd( aStru,{ "RELAC2",	"C",	010,	0 } )
	aAdd( aStrCmps,aStru )
	
	CriaTMPReg(aStru,"RELAC","D001",@aTrbs)	
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0324))	//"D001 - ABERTURA DO BLOCO D"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0031, cPictChar })	//"Movimento"	
	
	//REGISTRO D010: IDENTIFICAÇÃO DO ESTABELECIMENTO
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "CNPJ",		"C",	020,	0 } )	//"_CNPJ"	
	aAdd( aStru,{ "RELAC2",	"C",	010,	0 } )	
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )
	aAdd( aStrCmps,aStru )
	
	CriaTMPReg(aStru,"RELAC2","D010",@aTrbs)		
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0325))	//"D010 - IDENTIFICAÇÃO DO ESTABELECIMENTO"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0024, cPictCNPJ })	//"CNPJ"
	
	//REGISTRO D100: AQUISIÇÃO DE SERVIÇOS DE TRANSPORTE - NOTA FISCAL DE SERVIÇO DE TRANSPORTE (CÓDIGO 07) E CONHECIMENTOS DE TRANSPORTE RODOVIÁRIO DE CARGAS (CÓDIGO 08), CONHECIMENTO DE TRANSPORTE DE CARGAS AVULSO (CÓDIGO 8B), AQUAVIÁRIO DE CARGAS (CÓDIGO 09), AÉREO (CÓDIGO 10), FERROVIÁRIO DE CARGAS (CÓDIGO 11), MULTIMODAL DE CARGAS (CÓDIGO 26), NOTA FISCAL DE TRANSPORTE FERROVIÁRIO DE CARGA (CÓDIGO 27) E CONHECIMENTO DE TRANSPORTE ELETRÔNICO - CT-e (CÓDIGO 57)
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "IND_OP",	"C",	001,	0 } ) 	//"_IND_OPER"	
	aAdd( aStru,{ "I_E",		"C",	001,	0 } ) 	//"_IND_EMIT"
	aAdd( aStru,{ "C_P",		"C",	020,	0 } ) 	//"_COD_PART"
	aAdd( aStru,{ "COD_MO",	"C",	002,	0 } ) 	//"_COD_MOD"
	aAdd( aStru,{ "COD_SI",	"C",	002,	0 } ) 	//"_COD_SIT"
	aAdd( aStru,{ "SER",		"C",	004,	0 } ) 	//"_SER"
	aAdd( aStru,{ "SUB",		"C",	001,	0 } ) 	//"_SUB"		
	aAdd( aStru,{ "NUM_DO",	"C",	009,	0 } ) 	//"_NUM_DOC"
	aAdd( aStru,{ "CHV_CT",	"C",	044,	0 } ) 	//"_CHV_CTE"
	aAdd( aStru,{ "DT_DOC",	"C",	008,	0 } ) 	//"_DT_DOC"
	aAdd( aStru,{ "DT_A_P",	"C",	008,	0 } ) 	//"_DT_A_P"
	aAdd( aStru,{ "TP_CTE",	"C",	001,	0 } ) 	//"_TP_CT-e"
	aAdd( aStru,{ "CC_REF",	"C",	044,	0 } ) 	//"_CHV_CTE_REF"		
	aAdd( aStru,{ "VL_DOC",	"N",	014,	2 } ) 	//"_VL_DOC"
	aAdd( aStru,{ "V_DESC",	"N",	014,	2 } ) 	//"_VL_DESC"
	aAdd( aStru,{ "IN_FRT",	"C",	001,	0 } ) 	//"_IND_FRT"
	aAdd( aStru,{ "VL_SER",	"N",	014,	2 } ) 	//"_VL_SERV"
	aAdd( aStru,{ "V_BICM",	"N",	014,	2 } ) 	//"_VL_BC_ICMS"
	aAdd( aStru,{ "V_ICMS",	"N",	014,	2 } ) 	//"_VL_ICMS"	
	aAdd( aStru,{ "VL_NT",		"N",	014,	2 } ) 	//"_VL_BC_ICMS"		
	aAdd( aStru,{ "CO_INF",	"C",	006,	0 } ) 	//"_COD_INF"
	aAdd( aStru,{ "CO_CTA",	"C",	030,	0 } ) 	//"_VL_FRT"
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )
	
	CriaTMPReg(aStru,"RELAC3","D100",@aTrbs)	

	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0326))	// "D100 - AQUISIÇÃO DE SERVIÇOS DE TRANSPORTE - NOTA FISCAL DE SERVIÇO DE TRANSPORTE (CÓDIGO 07) E CONHECIMENTOS DE TRANSPORTE RODOVIÁRIO DE CARGAS (CÓDIGO 08), CONHECIMENTO DE TRANSPORTE DE CARGAS AVULSO (CÓDIGO 8B), AQUAVIÁRIO DE CARGAS (CÓDIGO 09), AÉREO (CÓDIGO 10), FERROVIÁRIO DE CARGAS (CÓDIGO 11), MULTIMODAL DE CARGAS (CÓDIGO 26), NOTA FISCAL DE TRANSPORTE FERROVIÁRIO DE CARGA (CÓDIGO 27) E CONHECIMENTO DE TRANSPORTE ELETRÔNICO - CT-e (CÓDIGO 57"	
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0114, cPictChar })	//"Tipo de Operação"	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0115, cPictChar })	//"Emitente do documento fiscal"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0116, cPictChar })	//"Código do participante"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0171, cPictChar })	//"Cód. do modelo do documento fiscal"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0117, cPictChar })	//"Cód. da sit. do documento fiscal"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0118, cPictChar })	//"Série"
	aAdd( aTitulo[Len(aTitulo)][2],{ "" /*STR0119*/, cPictChar })	//"Subsérie do documento fiscal"	                 
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0172, cPictChar })	//"Número do documento fiscal"	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0327, cPictChar })	//"Chave do Conhecimento de Transporte Eletrônico"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0328, cPictChar })	//"Data da aquisição ou da prestação do serviço"	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0667, cPictChar })	//"Data da aquisição ou da prestação do serviço"	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0329, cPictChar })	//"Tipo de Conhecimento de Transporte Eletrônico conforme definido no Manual de Integração do CT-e"		
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0330, cPictChar })	//"Chave do CT-e de referência cujos valores foram complementados (opção "1" do campo anterior) ou cujo débito foi anulado (opção '2' do campo anterior)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0124, cPictNUM })	//"Valor total do documento fiscal"		
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0126, cPictNUM })	//"Valor total do desconto"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0177, cPictChar })	//"Tipo do Frete"	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0331, cPictNUM })	//"Valor total da prestação de serviço"	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0181, cPictNUM })	//"Valor da base de cálculo do ICMS"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0182, cPictNUM })	//"Valor do ICMS"	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0332, cPictNUM })	//"Valor não-tributado do ICMS"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0135, cPictChar })	//"Código da informação complementar do documento fiscal (campo 02 do Registro 0450)"	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0163, cPictChar })	//"Código da conta analítica contábil debitada/creditada"	
	
	//REGISTRO D101: COMPLEMENTO DO DOCUMENTO DE TRANSPORTE (Códigos 07, 08, 8B, 09, 10, 11, 26, 27 e 57) - PIS/PASEP
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "I_N_F",		"C",	001,	0 } ) 	//"_IND_NAT_FRT"	
	aAdd( aStru,{ "V_ITEM",	"N",	014,	2} ) 	//"_VL_ITEM"
	aAdd( aStru,{ "CS_PIS",	"C",	002,	0 } ) 	//"_CST_PIS"
	aAdd( aStru,{ "N_B_CR",	"C",	002,	0 } ) 	//"_NAT_BC_CRED"	
	aAdd( aStru,{ "VB_PIS",	"N",	014,	2 } ) 	//"_VL_BC_PIS"
	aAdd( aStru,{ "AL_PIS",	"N",	008,	4 } ) 	//"_ALIQ_PIS"	
	aAdd( aStru,{ "VL_PIS",	"N",	014,	2 } ) 	//"_VL_PIS"	
	aAdd( aStru,{ "CO_CTA",	"C",	030,	0 } ) 	//"_VL_PIS"		
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )
		
	CriaTMPReg(aStru,"RELAC4","D101",@aTrbs)
		
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0333))	//"D101 - COMPLEMENTO DO DOCUMENTO DE TRANSPORTE (Códigos 07, 08, 8B, 09, 10, 11, 26, 27 e 57) - PIS/PASEP"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0334, cPictChar })	//"Indicador da Natureza do Frete Contratado"	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0260, cPictNUM })	//Valor total dos itens
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0155, cPictChar })	//Código da Situação Tributária referente ao PIS/PASEP
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0153, cPictChar })	//Código da Base de Cálculo do Crédito, conforme a Tabela indicada no item 4.3.7.
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0127, cPictNUM })	//Valor da base de cálculo do PIS/PASEP
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0157, cPictALI2 })	//Alíquota do PIS/PASEP (em percentual)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0158, cPictNUM })	//Valor do PIS/PASEP
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0232, cPictChar })	//Código da conta analítica contábil debitada/creditada						

	//REGISTRO D105: COMPLEMENTO DO DOCUMENTO DE TRANSPORTE (Códigos 07, 08, 8B, 09, 10, 11, 26, 27 e 57) - COFINS
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "I_N_F",		"C",	001,	0 } ) 	//"_IND_NAT_FRT"	
	aAdd( aStru,{ "V_ITEM",	"N",	014,	2} ) 	//"_VL_ITEM"
	aAdd( aStru,{ "CT_COF",	"C",	002,	0 } ) 	//"_CST_COFINS"
	aAdd( aStru,{ "N_B_CR",	"C",	002,	0 } ) 	//"_NAT_BC_CRED"	
	aAdd( aStru,{ "V_B_CO",	"N",	014,	2 } ) 	//"_VL_BC_PIS"
	aAdd( aStru,{ "AL_COF",	"N",	008,	4 } ) 	//"_ALIQ_COFINS"	
	aAdd( aStru,{ "VL_COF",	"N",	014,	2 } ) 	//"_VL_COFINS"	
	aAdd( aStru,{ "CO_CTA",	"C",	030,	0 } ) 	//"_COD_CTA"		
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )
			
	CriaTMPReg(aStru,"RELAC4","D105",@aTrbs)
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0335))   		//"D105 - COMPLEMENTO DO DOCUMENTO DE TRANSPORTE (Códigos 07, 08, 8B, 09, 10, 11, 26, 27 e 57) - COFINS"	 
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0334, cPictChar })	//"Indicador da Natureza do Frete Contratado"	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0260, cPictNUM })	//Valor total dos itens
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0226, cPictChar })	//Código da Situação Tributária referente a COFINS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0153, cPictChar })	//Código da Base de Cálculo do Crédito, conforme a Tabela indicada no item 4.3.7.
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0129, cPictNUM })	//Valor da base de cálculo da COFINS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0161, cPictALI2 })	//Alíquota da COFINS (em percentual)	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0162, cPictNUM })	//Valor da COFINS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0232, cPictChar })	//Código da conta analítica contábil debitada/creditada	
	
	//REGISTRO D111: PROCESSO REFERENCIADO
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "NUM_PR",	"C",	020,	0 } ) 	//"_NUM_PROC"
	aAdd( aStru,{ "IND_PR",	"C",	001,	0 } ) 	//"_IND_PROC"
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )	
	
	CriaTMPReg(aStru,"RELAC4","D111",@aTrbs)
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0336))		//"D111 - PROCESSO REFERENCIADO"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0138, cPictChar })	//"Identificação do processo ou ato concessório"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0139, cPictChar })	//"Origem do processo"
	
	//REGISTRO D200: RESUMO DA ESCRITURAÇÃO DIÁRIA - PRESTAÇÃO DE SERVIÇOS DE TRANSPORTE - NOTA FISCAL DE SERVIÇO DE TRANSPORTE (CÓDIGO 07) E CONHECIMENTOS DE TRANSPORTE RODOVIÁRIO DE CARGAS (CÓDIGO 08), CONHECIMENTO DE TRANSPORTE DE CARGAS AVULSO (CÓDIGO 8B), AQUAVIÁRIO DE CARGAS (CÓDIGO 09), AÉREO (CÓDIGO 10), FERROVIÁRIO DE CARGAS (CÓDIGO 11), MULTIMODAL DE CARGAS (CÓDIGO 26), NOTA FISCAL DE TRANSPORTE FERROVIÁRIO DE CARGA (CÓDIGO 27) E CONHECIMENTO DE TRANSPORTE ELETRÔNICO - CT-e (CÓDIGO 57)
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "COD_MO",	"C",	002,	0 } ) 	//"_COD_MOD"	
	aAdd( aStru,{ "COD_SI",	"C",	002,	0 } ) 	//"_COD_SIT"
	aAdd( aStru,{ "SER",		"C",	004,	0 } ) 	//"_SER"
	aAdd( aStru,{ "SUB",	 	"C",	001,	0 } ) 	//"_SUBR"
	aAdd( aStru,{ "ND_INI",	"C",	009,	0 } ) 	//"_NUM_DOC_INI"
	aAdd( aStru,{ "ND_FIN",	"C",	009,	0 } ) 	//"_NUM_DOC_FIN"	
	aAdd( aStru,{ "CFOP",		"C",	004,	0 } ) 	//"_DT_ENT"	
	aAdd( aStru,{ "DT_REF",	"C",	008,	0 } ) 	//"_VL_DOC"
	aAdd( aStru,{ "VL_DOC",	"N",	014,	2 } ) 	//"_VL_DOC"	
	aAdd( aStru,{ "VL_DES",	"N",	014,	2 } ) 	//"_COD_INF"		
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )	
	
	CriaTMPReg(aStru,"RELAC3","D200",@aTrbs)	
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0337))	//"REGISTRO D200: RESUMO DA ESCRITURAÇÃO DIÁRIA - PRESTAÇÃO DE SERVIÇOS DE TRANSPORTE - NOTA FISCAL DE SERVIÇO DE TRANSPORTE (CÓDIGO 07) E CONHECIMENTOS DE TRANSPORTE RODOVIÁRIO DE CARGAS (CÓDIGO 08), CONHECIMENTO DE TRANSPORTE DE CARGAS AVULSO (CÓDIGO 8B), AQUAVIÁRIO DE CARGAS (CÓDIGO 09), AÉREO (CÓDIGO 10), FERROVIÁRIO DE CARGAS (CÓDIGO 11), MULTIMODAL DE CARGAS (CÓDIGO 26), NOTA FISCAL DE TRANSPORTE FERROVIÁRIO DE CARGA (CÓDIGO 27) E CONHECIMENTO DE TRANSPORTE ELETRÔNICO - CT-e (CÓDIGO 57)"	
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0171, cPictChar })	//"Código do modelo do documento fiscal, conforme a Tabela 4.1.1 "
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0117, cPictChar })	//"Código da situação do documento fiscal, conforme a Tabela 4.1.2"		
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0118, cPictChar })	//"Série do documento fiscal"		
	aAdd( aTitulo[Len(aTitulo)][2],{ "" /*STR0119*/, cPictChar })	//"Subsérie do documento fiscal"		
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0255, cPictChar })	//"Número do documento fiscal inicial emitido no período (mesmo modelo, série e subsérie)"			
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0256, cPictChar })	//"Número do documento fiscal final emitido no período (mesmo modelo, série e subsérie)."				
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0206, cPictChar })	//"Código Fiscal de Operação e Prestação conforme tabela indicada no item 4.2.2"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0338, cPictChar })	//"Data do dia de referência do resumo diário"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0339, cPictNUM })	//"Valor total dos documentos fiscais"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0126, cPictNUM })	//Valor total dos descontos
	
	//REGISTRO D201: TOTALIZAÇÃO DO RESUMO DIÁRIO - PIS/PASEP
	
	aStru	:=	{}	
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "CS_PIS",	"C",	002,	0 } ) 	//"_CST_PIS"
	aAdd( aStru,{ "VL_ITE",	"N",	014,	2 } ) 	//"_VL_ITEM"
	aAdd( aStru,{ "V_B_PI",	"N",	014,	2 } ) 	//"_VL_BC_PIS"
	aAdd( aStru,{ "AL_PIS",	"N",	014,	2 } ) 	//"_ALIQ_PIS"
	aAdd( aStru,{ "VL_PIS",	"N",	014,	2 } ) 	//"_VL_PIS"	
	aAdd( aStru,{ "CO_CTA",	"C",	030,	0 } ) 	//"_COD_CTA"		
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )	

	CriaTMPReg(aStru,"RELAC4","D201",@aTrbs)
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0340))	//"D201 - TOTALIZAÇÃO DO RESUMO DIÁRIO - PIS/PASEP"	  
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0155, cPictChar })	//Código da Situação Tributária referente ao PIS/PASEP
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0260, cPictNUM })	//Valor total dos itens
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0127, cPictNUM })	//Valor da base de cálculo do PIS/PASEP
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0157, cPictALI2 })	//Alíquota do PIS/PASEP (Percentual)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0243, cPictNUM })	//"Valor do PIS/PASEP"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0232, cPictChar })	//"Código da conta analítica contábil debitada/creditada"	
	
	//REGISTRO D205: TOTALIZAÇÃO DO RESUMO DIÁRIO - COFINS
	
	aStru	:=	{}	
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "C_COFI",	"C",	002,	0 } ) 	//"_CST_COFINS"
	aAdd( aStru,{ "VL_ITE",	"N",	014,	2 } ) 	//"_VL_ITEM"
	aAdd( aStru,{ "V_B_CO",	"N",	014,	2 } ) 	//"_VL_BC_COFINS"
	aAdd( aStru,{ "AL_COF",	"N",	008,	4 } ) 	//"_ALIQ_COFINS"
	aAdd( aStru,{ "V_COFI",	"N",	014,	2 } ) 	//"_VL_COFINS"
	aAdd( aStru,{ "CO_CTA",	"C",	030,	0 } ) 	//"_COD_CTA"		
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )	
	
	CriaTMPReg(aStru,"RELAC4","D205",@aTrbs)	
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0341))	//"D205 - TOTALIZAÇÃO DO RESUMO DIÁRIO - COFINS"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0226, cPictChar })	//Código da Situação Tributária referente a COFINS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0260, cPictNUM })	//Valor total dos itens
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0227, cPictNUM })	//Valor da base de cálculo da COFINS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0230, cPictALI2 })	//"Alíquota da COFINS (em reais)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0162, cPictNUM })	//Valor da COFINS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0232, cPictChar })	//"Código da conta analítica contábil debitada/creditada"	
	
	//REGISTRO D209: PROCESSO REFERENCIADO 
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "NUM_PR",	"C",	020,	0 } ) 	//"_NUM_PROC"
	aAdd( aStru,{ "IND_PR",	"C",	001,	0 } ) 	//"_IND_PROC"
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )	
	
	CriaTMPReg(aStru,"RELAC4","D209",@aTrbs)	
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0342))	//"D209 - PROCESSO REFERENCIADO"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0138, cPictChar })	//"Identificação do processo ou ato concessório"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0139, cPictChar })	//"Origem do processo"	
	
	//REGISTRO D300: RESUMO DA ESCRITURAÇÃO DIÁRIA - BILHETES CONSOLIDADOS DE PASSAGEM RODOVIÁRIO (CÓDIGO 13), DE PASSAGEM AQUAVIÁRIO (CÓDIGO 14), DE PASSAGEM E NOTA DE BAGAGEM (CÓDIGO 15), DE PASSAGEM FERROVIÁRIO (CÓDIGO 16) E RESUMO DE MOVIMENTO DIÁRIO (CÓDIGO 18)
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "COD_MO",	"C",	002,	0 } ) 	//"_COD_MOD"	
	aAdd( aStru,{ "SER",		"C",	004,	0 } ) 	//"_SER"
	aAdd( aStru,{ "SUB",	 	"C",	001,	0 } ) 	//"_SUBR"
	aAdd( aStru,{ "ND_INI",	"C",	009,	0 } ) 	//"_NUM_DOC_INI"
	aAdd( aStru,{ "ND_FIN",	"C",	009,	0 } ) 	//"_NUM_DOC_FIN"	
	aAdd( aStru,{ "CFOP",		"C",	004,	0 } ) 	//"_DT_ENT"	
	aAdd( aStru,{ "DT_REF",	"C",	008,	0 } ) 	//"_VL_DOC"
	aAdd( aStru,{ "VL_DOC",	"N",	014,	2 } ) 	//"_VL_DOC"	
	aAdd( aStru,{ "VL_DES",	"N",	014,	2 } ) 	//"_COD_INF"	
	aAdd( aStru,{ "CS_PIS",	"C",	002,	0 } ) 	//"_CST_PIS"
	aAdd( aStru,{ "VB_PIS",	"N",	014,	2 } ) 	//"_VL_BC_PIS"
	aAdd( aStru,{ "AL_PIS",	"N",	008,	4 } ) 	//"_ALIQ_PIS"
	aAdd( aStru,{ "VL_PIS",	"N",	014,	2 } ) 	//"_VL_PIS"
	aAdd( aStru,{ "CT_COF",	"C",	002,	0 } ) 	//"_CST_COFINS"
	aAdd( aStru,{ "VB_COF",	"N",	014,	2 } ) 	//"_VL_BC_COFINS"
	aAdd( aStru,{ "AL_COF",	"N",	008,	4 } ) 	//"_ALIQ_COFINS"
	aAdd( aStru,{ "VL_COF",	"N",	014,	2 } ) 	//"_VL_COFINS"	
	aAdd( aStru,{ "CO_CTA",	"C",	030,	0 } ) 	//"_COD_CTA"
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )
	
	CriaTMPReg(aStru,"RELAC3","D300",@aTrbs)	
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0343))	//"D300 - RESUMO DA ESCRITURAÇÃO DIÁRIA - BILHETES CONSOLIDADOS DE PASSAGEM RODOVIÁRIO (CÓDIGO 13), DE PASSAGEM AQUAVIÁRIO (CÓDIGO 14), DE PASSAGEM E NOTA DE BAGAGEM (CÓDIGO 15), DE PASSAGEM FERROVIÁRIO (CÓDIGO 16) E RESUMO DE MOVIMENTO DIÁRIO (CÓDIGO 18)"	
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0171, cPictChar })	//"Código do modelo do documento fiscal, conforme a Tabela 4.1.1 "
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0118, cPictChar })	//"Série do documento fiscal"		
	aAdd( aTitulo[Len(aTitulo)][2],{ "" /*STR0119*/, cPictChar })	//"Subsérie do documento fiscal"		
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0255, cPictChar })	//"Número do documento fiscal inicial emitido no período (mesmo modelo, série e subsérie)"			
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0256, cPictChar })	//"Número do documento fiscal final emitido no período (mesmo modelo, série e subsérie)."				
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0206, cPictChar })	//"Código Fiscal de Operação e Prestação conforme tabela indicada no item 4.2.2"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0338, cPictChar })	//"Data do dia de referência do resumo diário"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0339, cPictNUM })	//"Valor total dos documentos fiscais"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0126, cPictNUM })	//Valor total dos descontos
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0155, cPictChar })	//Código da Situação Tributária referente ao PIS/PASEP
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0156, cPictNUM })	//Valor da base de cálculo do PIS/PASEP
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0157, cPictALI2 })	//Alíquota do PIS/PASEP (em percentual)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0158, cPictNUM })	//Valor do PIS/PASEP
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0226, cPictChar })	//Código da Situação Tributária referente a COFINS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0227, cPictNUM })	//Valor da base de cálculo da COFINS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0228, cPictALI2 })	//Alíquota da COFINS (em percentual)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0162, cPictNUM })	//Valor da COFINS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0232, cPictChar })	//Código da conta analítica contábil debitada/creditada
	
	//REGISTRO D309: PROCESSO REFERENCIADO 
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "NUM_PR",	"C",	020,	0 } ) 	//"_NUM_PROC"
	aAdd( aStru,{ "IND_PR",	"C",	001,	0 } ) 	//"_IND_PROC"
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )	
	
	CriaTMPReg(aStru,"RELAC4","D309",@aTrbs)
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0344))	//"D309 - PROCESSO REFERENCIADO"	 	
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0138, cPictChar })	//"Identificação do processo ou ato concessório"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0139, cPictChar })	//"Origem do processo"		
	
	//REGISTRO D350: RESUMO DIÁRIO DE CUPOM FISCAL EMITIDO POR ECF - (CÓDIGOS 2E, 13, 14, 15 e 16)
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "COD_MO",	"C",	002,	0 } ) 	//"_COD_MOD"		
	aAdd( aStru,{ "ECF_MO",	"C",	020,	0 } ) 	//"_ECF_MOD"	
	aAdd( aStru,{ "ECF_FA",	"C",	020,	0 } ) 	//"_ECF_FAB"
	aAdd( aStru,{ "DT_DOC",	"C",	008,	0 } ) 	//"_DT_DOC"	
	aAdd( aStru,{ "CRO",		"C",	003,	0 } ) 	//"_DT_DOC"
	aAdd( aStru,{ "CRZ",		"C",	006,	0 } ) 	//"_DT_DOC"	
	aAdd( aStru,{ "NC_FIN",	"C",	006,	0 } ) 	//"_DT_DOC"
	aAdd( aStru,{ "GT_FIN",	"N",	014,	2 } ) 	//"_DT_DOC"		
	aAdd( aStru,{ "VL_BRT",	"N",	014,	2 } ) 	//"_VL_BRT"
	aAdd( aStru,{ "CS_PIS",	"C",	002,	0 } ) 	//"_CST_PIS"
	aAdd( aStru,{ "VB_PIS",	"N",	014,	2 } ) 	//"_VL_BC_PIS"
	aAdd( aStru,{ "AL_PIS",	"N",	008,	4 } ) 	//"_ALIQ_PIS"
	aAdd( aStru,{ "QB_PIS",	"N",	014,	3 } ) 	//"_QUANT_BC_PIS"	
	aAdd( aStru,{ "AP_QUA",	"N",	008,	4 } ) 	//"_ALIQ_PIS_QUANT"
	aAdd( aStru,{ "VL_PIS",	"N",	014,	2 } ) 	//"_VL_PIS"
	aAdd( aStru,{ "CT_COF",	"C",	002,	0 } ) 	//"_CST_COFINS"
	aAdd( aStru,{ "VB_COF",	"N",	014,	2 } ) 	//"_VL_BC_COFINS"
	aAdd( aStru,{ "AL_COF",	"N",	008,	4 } ) 	//"_ALIQ_COFINS"
	aAdd( aStru,{ "QB_COF",	"N",	014,	3 } ) 	//"_QUANT_BC_COFINS"	
	aAdd( aStru,{ "AC_QUA",	"N",	014,	4 } ) 	//"_ALIQ_COFINS_QUANT"
	aAdd( aStru,{ "VL_COF",	"N",	014,	2 } ) 	//"_VL_COFINS"	
	aAdd( aStru,{ "CO_CTA",	"C",	030,	0 } ) 	//"_COD_CTA"
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )
	
	CriaTMPReg(aStru,"RELAC3","D350",@aTrbs)		
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0345))	//"D350 - RESUMO DIÁRIO DE CUPOM FISCAL EMITIDO POR ECF - (CÓDIGOS 2E, 13, 14, 15 e 16)"		
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0171, cPictChar })	//"Código do modelo do documento fiscal, conforme a Tabela 4.1.1 "
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0267, cPictChar })	//"Modelo do equipamento"		
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0268, cPictChar })	//"Número de série de fabricação do ECF"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0271, cPictChar })	//"Data do movimento a que se refere a Redução Z"			
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0272, cPictChar })	//"Posição do Contador de Reinício de Operação"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0273, cPictChar })	//Posição do Contador de Redução Z
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0274, cPictChar })	//Número do Contador de Ordem de Operação do último documento emitido no dia. (Número do COO na Redução Z)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0275, cPictNUM })	//Valor do Grande Total final
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0276, cPictNUM })	//Valor da venda bruta
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0155, cPictChar })	//Código da Situação Tributária referente ao PIS/PASEP
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0156, cPictNUM })	//Valor da base de cálculo do PIS/PASEP
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0157, cPictALI2 })	//Alíquota do PIS/PASEP (em percentual)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0223, cPictNUM })	//Quantidade - Base de cálculo PIS/PASEP
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0224, cPictALI2 })	//Alíquota do PIS/PASEP (em reais)	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0158, cPictNUM })	//Valor do PIS/PASEP
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0226, cPictChar })	//Código da Situação Tributária referente a COFINS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0227, cPictNUM })	//Valor da base de cálculo da COFINS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0228, cPictALI2 })	//Alíquota da COFINS (em percentual)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0229, cPictChar })	//Quantidade - Base de cálculo da COFINS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0230, cPictALI2 })	//"Alíquota da COFINS (em reais)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0162, cPictNUM })	//Valor da COFINS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0232, cPictChar })	//Código da conta analítica contábil debitada/creditada

	//REGISTRO D359: PROCESSO REFERENCIADO 
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "NUM_PR",	"C",	020,	0 } ) 	//"_NUM_PROC"
	aAdd( aStru,{ "IND_PR",	"C",	001,	0 } ) 	//"_IND_PROC"
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )	
	
	CriaTMPReg(aStru,"RELAC4","D359",@aTrbs)	
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0346))	//"D359 - PROCESSO REFERENCIADO"	 	
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0138, cPictChar })	//"Identificação do processo ou ato concessório"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0139, cPictChar })	//"Origem do processo"
	
	//REGISTRO D500: NOTA FISCAL DE SERVIÇO DE COMUNICAÇÃO (CÓDIGO 21) E NOTA FISCAL DE SERVIÇO DE TELECOMUNICAÇÃO (CÓDIGO 22) - DOCUMENTOS DE AQUISIÇÃO COM DIREITO A CRÉDITO
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "IND_OP",	"C",	001,	0 } ) 	//"_IND_OPER"	
	aAdd( aStru,{ "I_E",		"C",	001,	0 } ) 	//"_IND_EMIT"
	aAdd( aStru,{ "C_P",		"C",	020,	0 } ) 	//"_COD_PART"
	aAdd( aStru,{ "COD_MO",	"C",	002,	0 } ) 	//"_COD_MOD"
	aAdd( aStru,{ "COD_SI",	"C",	002,	0 } ) 	//"_COD_SIT"
	aAdd( aStru,{ "SER",		"C",	004,	0 } ) 	//"_SER"
	aAdd( aStru,{ "SUB",		"C",	001,	0 } ) 	//"_SUB"
	aAdd( aStru,{ "NUM_DO",	"C",	009,	0 } ) 	//"_NUM_DOC"
	aAdd( aStru,{ "DT_DOC",	"C",	008,	0 } ) 	//"_DT_DOC"
	aAdd( aStru,{ "DT_A_P",	"C",	008,	0 } ) 	//"_DT_A_P"		
	aAdd( aStru,{ "VL_DOC",	"N",	014,	2 } ) 	//"_VL_DOC"
	aAdd( aStru,{ "V_DESC",	"N",	014,	2 } ) 	//"_VL_DESC"
	aAdd( aStru,{ "VL_SER",	"N",	014,	2 } ) 	//"_VL_ABAT_NT"
	aAdd( aStru,{ "V_S_NT",	"N",	014,	2 } ) 	//"_VL_SERV_NT"	
	aAdd( aStru,{ "VL_TER",	"N",	014,	2 } ) 	//"_VL_BC_COFINS"
	aAdd( aStru,{ "VL_DA",		"N",	014,	2 } ) 	//"_VL_FRT"
	aAdd( aStru,{ "V_BICM",	"N",	014,	2 } ) 	//"_VL_BC_ICMS"	
	aAdd( aStru,{ "V_ICMS",	"N",	014,	2 } ) 	//"_VL_BC_ICMS"		
	aAdd( aStru,{ "VL_PIS",	"N",	014,	2 } ) 	//"_VL_ICMS_ST"	
	aAdd( aStru,{ "V_COFI",	"N",	014,	2 } ) 	//"_VL_COFINS"	
	aAdd( aStru,{ "COD_IN",	"C",	006,	0 } ) 	//"_COD_INF"		
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )

	CriaTMPReg(aStru,"RELAC3","D500",@aTrbs)		
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0347))	//"D500 - NOTA FISCAL DE SERVIÇO DE COMUNICAÇÃO (CÓDIGO 21) E NOTA FISCAL DE SERVIÇO DE TELECOMUNICAÇÃO (CÓDIGO 22) - DOCUMENTOS DE AQUISIÇÃO COM DIREITO A CRÉDITO"	
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0114, cPictChar })	//"Tipo de Operação"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0115, cPictChar })	//"Emitente do documento fiscal"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0116, cPictChar })	//"Código do participante"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0171, cPictChar })	//"Cód. do modelo do documento fiscal"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0117, cPictChar })	//"Cód. da sit. do documento fiscal"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0118, cPictChar })	//"Série"
	aAdd( aTitulo[Len(aTitulo)][2],{ "" /*STR0119*/, cPictChar })	//"Subsérie"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0172, cPictChar })	//"Número do documento fiscal"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0122, cPictChar })	//"Data da emissão"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0285, cPictChar })	//"Data da aquisição"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0124, cPictNUM })	//"Valor total"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0126, cPictNUM })	//"Valor total do desconto"				
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0331, cPictNUM })	//Valor da prestação de serviços
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0348, cPictNUM })	//"Valor total dos serviços não-tributados pelo ICMS"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0299, cPictNUM })	//Valores cobrados em nome de terceiros
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0349, cPictNUM })	//"Valor de outras despesas indicadas no documento fiscal"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0208, cPictNUM })	//Valor da base de cálculo do ICMS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0182, cPictNUM })	//"Valor do ICMS"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0135, cPictNUM })	//Código da informação complementar (campo 02 do Registro 0450)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0225, cPictNUM })	//Valor do PIS/PASEP
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0162, cPictChar })	//Valor da COFINS	    
	
	IncProc("Gerando estrutura...")
	
	//REGISTRO D501: COMPLEMENTO DA OPERAÇÃO (CÓDIGOS 21 e 22) - PIS/PASEP
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "CS_PIS",	"C",	002,	0 } ) 	//"_CST_PIS"
	aAdd( aStru,{ "VL_ITE",	"N",	014,	2 } ) 	//"_VL_ITEM"
   	aAdd( aStru,{ "N_B_CR",	"C",	002,	0 } ) 	//"_NAT_BC_CRED"
	aAdd( aStru,{ "VB_PIS",	"N",	014,	2 } ) 	//"_VL_BC_PIS"
	aAdd( aStru,{ "AQ_PIS",	"N",	008,	4 } ) 	//"_ALIQ_PIS"
	aAdd( aStru,{ "VL_PIS",	"N",	014,	2 } ) 	//"_VL_PIS"
	aAdd( aStru,{ "CO_CTA",	"C",	060,	0 } ) 	//"_ALIQ_COFINS"
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )

	CriaTMPReg(aStru,"RELAC4","D501",@aTrbs)	
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0350))	//"D501 - COMPLEMENTO DA OPERAÇÃO (CÓDIGOS 21 e 22) - PIS/PASEP"	 
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0155, cPictChar })	//Código da Situação Tributária referente ao PIS/PASEP
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0240, cPictNUM })	//Valor Total dos Itens (Serviços)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0153, cPictChar })	//Código da Base de Cálculo do Crédito, conforme a Tabela indicada no item 4.3.7.
   	aAdd( aTitulo[Len(aTitulo)][2],{ STR0156, cPictNUM })	//Valor da base de cálculo do crédito de PIS/PASEP
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0157, cPictALI1 })	//Alíquota do PIS/PASEP (em percentual)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0158, cPictNUM })	//Valor do PIS/PASEP
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0232, cPictChar })	//"Código da conta analítica contábil debitada/creditada"						

	//REGISTRO D505: COMPLEMENTO DA OPERAÇÃO (CÓDIGOS 21 e 22) - COFINS
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "CT_COF",	"C",	002,	0 } ) 	//"_CST_COFINS"
	aAdd( aStru,{ "V_ITEM",	"N",	014,	2} ) 	//"_VL_ITEM"	
	aAdd( aStru,{ "N_B_CR",	"C",	002,	0 } ) 	//"_NAT_BC_CRED"	
	aAdd( aStru,{ "V_B_CO",	"N",	014,	2 } ) 	//"_VL_BC_PIS"
	aAdd( aStru,{ "AL_COF",	"N",	008,	4 } ) 	//"_ALIQ_COFINS"	
	aAdd( aStru,{ "VL_COF",	"N",	014,	2 } ) 	//"_VL_COFINS"	
	aAdd( aStru,{ "CO_CTA",	"C",	030,	0 } ) 	//"_COD_CTA"		
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )
			
	CriaTMPReg(aStru,"RELAC4","D505",@aTrbs)	
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0351))	//"D505 - COMPLEMENTO DA OPERAÇÃO (CÓDIGOS 21 e 22) - COFINS"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0226, cPictChar })	//Código da Situação Tributária referente a COFINS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0260, cPictNUM })	//Valor total dos itens
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0153, cPictChar })	//Código da Base de Cálculo do Crédito, conforme a Tabela indicada no item 4.3.7.
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0129, cPictNUM })	//Valor da base de cálculo da COFINS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0161, cPictALI1 })	//Alíquota da COFINS (em percentual)	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0162, cPictNUM })	//Valor da COFINS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0232, cPictChar })	//Código da conta analítica contábil debitada/creditada	
	
	//REGISTRO D509: PROCESSO REFERENCIADO
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "NUM_PR",	"C",	020,	0 } ) 	//"_NUM_PROC"
	aAdd( aStru,{ "IND_PR",	"C",	001,	0 } ) 	//"_IND_PROC"
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )	
	
	CriaTMPReg(aStru,"RELAC4","D509",@aTrbs)
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0352))	//"D509 - PROCESSO REFERENCIADO"	 
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0138, cPictChar })	//"Identificação do processo ou ato concessório"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0139, cPictChar })	//"Origem do processo"	
	
	//REGISTRO D600: CONSOLIDAÇÃO DA PRESTAÇÃO DE SERVIÇOS - NOTAS DE SERVIÇO DE COMUNICAÇÃO (CÓDIGO 21) E DE SERVIÇO DE TELECOMUNICAÇÃO (CÓDIGO 22)
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "COD_MO",	"C",	002,	0 } ) 	//_COD_MOD"
	aAdd( aStru,{ "COD_MU",	"C",	007,	0 } ) 	//_COD_MUN"
	aAdd( aStru,{ "SER",		"C",	004,	0 } ) 	//_SER"
	aAdd( aStru,{ "SUB",		"C",	001,	0 } ) 	//_SUB"
	aAdd( aStru,{ "IND_RE",	"C",	001,	0 } ) 	//_IND_REC"
	aAdd( aStru,{ "QTD_CO",	"N",	014,	2 } ) 	//"_QTD_CONS"
	aAdd( aStru,{ "DD_INI",	"C",	008,	0 } ) 	//"_DT_DOC_INI"	
	aAdd( aStru,{ "DD_FIN",	"C",	008,	0 } ) 	//"_DT_DOC_FIN"	
	aAdd( aStru,{ "VL_DOC",	"N",	014,	2 } ) 	//_VL_DOC"	
	aAdd( aStru,{ "VL_DES",	"N",	014,	2 } ) 	//_VL_DESC"	
	aAdd( aStru,{ "VL_SER",	"N",	014,	2 } ) 	//_VL_SERV"
	aAdd( aStru,{ "V_S_NT",	"N",	014,	2 } ) 	//_VL_SERV_NT"
	aAdd( aStru,{ "VL_TER",	"N",	014,	2 } ) 	//_VL_TERC"
	aAdd( aStru,{ "VL_DA",		"N",	014,	2 } ) 	//_VL_DA"
	aAdd( aStru,{ "VB_IC",		"N",	014,	2 } ) 	//_VL_BC_ICMS"
	aAdd( aStru,{ "V_ICM",		"N",	014,	2 } ) 	//_VL_ICMS"
	aAdd( aStru,{ "V_PIS",		"N",	014,	2 } ) 	//"_VL_PIS"
	aAdd( aStru,{ "V_COFS",	"N",	014,	2 } ) 	//"_VL_COFINS"	
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )		
				
	CriaTMPReg(aStru,"RELAC3","D600",@aTrbs)
		
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0353))	//"D600 - CONSOLIDAÇÃO DA PRESTAÇÃO DE SERVIÇOS - NOTAS DE SERVIÇO DE COMUNICAÇÃO (CÓDIGO 21) E DE SERVIÇO DE TELECOMUNICAÇÃO (CÓDIGO 22)"	 
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0171, cPictChar })	//"Código do modelo do documento fiscal, conforme a Tabela 4.1.1"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0045, cPictChar })	//Código do município dos pontos de consumo, conforme a tabela IBGE
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0118, cPictChar })	//Série do documento fiscal
	aAdd( aTitulo[Len(aTitulo)][2],{ "" /*STR0119*/, cPictChar })	//Subsérie do documento fiscal
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0354, cPictChar })	//Indicador do tipo de receita 	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0292, cPictNUM })	//"Quantidade de documentos consolidados neste registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0355, cPictChar })	//Data Inicial dos documentos consolidados no período
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0356, cPictChar })	//Data Final dos documentos consolidados no período
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0357, cPictNUM })	//Valor total acumulado dos documentos fiscais
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0295, cPictNUM })	//"Valor acumulado dos descontos"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0358, cPictNUM })	//"Valor acumulado das prestações de serviços tributados pelo ICMS"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0298, cPictNUM })	//"Valor acumulado dos serviços não-tributados pelo ICMS" 
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0299, cPictNUM })	//"Valores cobrados em nome de terceiros"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0300, cPictNUM })	//"Valor acumulado das despesas acessórias"	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0301, cPictNUM })	//"Valor acumulado da base de cálculo do ICMS"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0286, cPictNUM })	//Valor acumulado do ICMS	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0158, cPictNUM })	//"Vl. do PIS/PASEP"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0162, cPictNUM })	//"Vl. da COFINS"	
	
	//REGISTRO D601: COMPLEMENTO DA CONSOLIDAÇÃO DA PRESTAÇÃO DE SERVIÇOS (CÓDIGOS 21 E 22) - PIS/PASEP
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "C_CLAS",	"C",	004,	0 } ) 	//"_COD_CLASS"
	aAdd( aStru,{ "VL_ITE",	"N",	014,	2 } ) 	//"_VL_ITEM"
	aAdd( aStru,{ "VL_DES",	"N",	014,	2 } ) 	//"_VL_DESC"
	aAdd( aStru,{ "CS_PIS",	"C",	002,	0 } ) 	//"_CST_PIS"
	aAdd( aStru,{ "VB_PIS",	"N",	014,	2 } ) 	//"_VL_BC_PIS"
	aAdd( aStru,{ "AQ_PIS",	"N",	008,	4 } ) 	//"_ALIQ_PIS"
	aAdd( aStru,{ "VL_PIS",	"N",	014,	2 } ) 	//"_VL_PIS"
	aAdd( aStru,{ "CO_CTA",	"C",	060,	0 } ) 	//"_ALIQ_COFINS"
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )	

	CriaTMPReg(aStru,"RELAC4","D601",@aTrbs)	
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0359))	//"D601 - COMPLEMENTO DA CONSOLIDAÇÃO DA PRESTAÇÃO DE SERVIÇOS (CÓDIGOS 21 E 22) - PIS/PASEP"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0360, cPictChar })	//"Código de classificação do item do serviço de comunicação ou de telecomunicação, conforme a Tabela 4.4.1"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0361, cPictNUM })	//Valor acumulado do item"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0362, cPictNUM })	//Valor acumulado dos descontos/exclusões da base de cálculo
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0155, cPictChar })	//Código da Situação Tributária referente ao PIS/PASEP
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0156, cPictNUM })	//Valor da base de cálculo do crédito de PIS/PASEP
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0157, cPictALI2 })	//Alíquota do PIS/PASEP (em percentual)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0158, cPictNUM })	//Valor do PIS/PASEP
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0232, cPictChar })	//"Código da conta analítica contábil debitada/creditada"

	//REGISTRO D605: COMPLEMENTO DA CONSOLIDAÇÃO DA PRESTAÇÃO DE SERVIÇOS (CÓDIGOS 21 E 22) - COFINS
	
	aStru	:=	{}	
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "C_CLAS",	"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "VL_ITE",	"N",	014,	2 } ) 	//"_VL_ITEM"
	aAdd( aStru,{ "VL_DES",	"N",	014,	2 } ) 	//"_VL_DESC"
	aAdd( aStru,{ "C_COFI",	"C",	002,	0 } ) 	//"_CST_COFINS"
	aAdd( aStru,{ "V_B_CO",	"N",	014,	2 } ) 	//"_VL_BC_COFINS"
	aAdd( aStru,{ "AL_COF",	"N",	008,	4 } ) 	//"_ALIQ_COFINS"
	aAdd( aStru,{ "V_COFI",	"N",	014,	2 } ) 	//"_VL_COFINS"
	aAdd( aStru,{ "CO_CTA",	"C",	060,	0 } ) 	//"_COD_CTA"
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )
		
	CriaTMPReg(aStru,"RELAC4","D605",@aTrbs)	
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0363))	//"D605 - COMPLEMENTO DA CONSOLIDAÇÃO DA PRESTAÇÃO DE SERVIÇOS (CÓDIGOS 21 E 22) - COFINS" 	
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0360, cPictChar })	//"Código de classificação do item do serviço de comunicação ou de telecomunicação, conforme a Tabela 4.4.1"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0361, cPictNUM })	//Valor acumulado do item"	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0362, cPictNUM })	//Valor acumulado dos descontos/exclusões da base de cálculo
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0226, cPictChar })	//Código da Situação Tributária referente a COFINS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0227, cPictNUM })	//Valor da base de cálculo da COFINS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0228, cPictALI2 })	//Alíquota da COFINS (em percentual)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0162, cPictNUM })	//Valor da COFINS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0232, cPictChar })	//"Código da conta analítica contábil debitada/creditada"		

	//REGISTRO D609: PROCESSO REFERENCIADO
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "NUM_PR",	"C",	020,	0 } ) 	//"_NUM_PROC"
	aAdd( aStru,{ "IND_PR",	"C",	001,	0 } ) 	//"_IND_PROC"
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )	
	
	CriaTMPReg(aStru,"RELAC4","D609",@aTrbs)	
	
	aAdd( aTitulo, {}) 
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0364))	//"D609 - PROCESSO REFERENCIADO"	 
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0138, cPictChar })	//"Identificação do processo ou ato concessório"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0139, cPictChar })	//"Origem do processo"	
	
	//REGISTRO D990: ENCERRAMENTO DO BLOCO D
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) //"_REG"
	aAdd( aStru,{ "Q_LIN0",	"N",	010,	0 } ) //"_QTD_LIN_0"	
	aAdd( aStru,{ "RELAC",		"C",	010,	0 } )
	aAdd( aStrCmps,aStru )
	
	CriaTMPReg(aStru,"RELAC","D990",@aTrbs)	
		
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0365))	//"D990 - ENCERRAMENTO DO BLOCO D"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0366, cPictChar })	//"Quantidade total de linhas do Bloco D"	 
	
	//REGISTRO F001: ABERTURA DO BLOCO F	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) //"_REG"
	aAdd( aStru,{ "IND_MO",	"C",	003,	0 } ) //"_IND_MOV"
	aAdd( aStru,{ "RELAC",		"C",	010,	0 } )
	aAdd( aStru,{ "RELAC2",	"C",	010,	0 } )
	aAdd( aStrCmps,aStru )
	
	CriaTMPReg(aStru,"RELAC","F001",@aTrbs)	
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0367))	//"F001 - ABERTURA DO BLOCO F"	 
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0031, cPictChar })	//"Movimento"	
	
	//REGISTRO F010: IDENTIFICAÇÃO DO ESTABELECIMENTO
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "CNPJ",		"C",	020,	0 } )	//"_CNPJ"	
	aAdd( aStru,{ "RELAC2",	"C",	010,	0 } )	
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )
	aAdd( aStrCmps,aStru )
	
	CriaTMPReg(aStru,"RELAC2","F010",@aTrbs)		
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0368))	//"F010 - IDENTIFICAÇÃO DO ESTABELECIMENTO"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0024, cPictCNPJ })	//"CNPJ"	
		
	//REGISTRO F100: DEMAIS DOCUMENTOS E OPERAÇÕES GERADORAS DE CONTRIBUIÇÃO E CRÉDITOS
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "IND_OP",	"C",	001,	0 } ) 	//"_IND_OPER"	
	aAdd( aStru,{ "C_P",		"C",	020,	0 } ) 	//"_COD_PART"
	aAdd( aStru,{ "C_ITEM",	"C",	002,	0 } ) 	//"_COD_ITEM"
	aAdd( aStru,{ "DT_OPE",	"C",	012,	0 } ) 	//"_DT_OPER"
	aAdd( aStru,{ "VL_OPE",	"N",	014,	2 } ) 	//"_VL_OPER"
	aAdd( aStru,{ "CS_PIS",	"C",	002,	0 } ) 	//"_CST_PIS"		
	aAdd( aStru,{ "VB_PIS",	"N",	014,	2 } ) 	//"_VL_BC_PIS"
	aAdd( aStru,{ "AL_PIS",	"N",	008,	4 } ) 	//"_ALIQ_PIS"
	aAdd( aStru,{ "VL_PIS",	"N",	014,	2 } ) 	//"_VL_PIS"	
	aAdd( aStru,{ "CS_COF",	"C",	002,	0 } ) 	//"_CST_COFINS"
	aAdd( aStru,{ "VB_COF",	"N",	014,	2 } ) 	//"_VL_BC_COFINS"
	aAdd( aStru,{ "AL_COF",	"N",	008,	4 } ) 	//"_ALIQ_COFINS"		
	aAdd( aStru,{ "VL_COF",	"N",	014,	2 } ) 	//"_VL_COFINS"
	aAdd( aStru,{ "NB_CRE",	"C",	002,	0 } ) 	//"_NAT_BC_CRED"
	aAdd( aStru,{ "IO_CRE",	"C",	001,	0 } ) 	//"_IND_ORIG_CRED"	
	aAdd( aStru,{ "CO_CTA",	"C",	020,	0 } ) 	//"_VL_SERV"
	aAdd( aStru,{ "CO_CCU",	"C",	020,	0 } ) 	//"_VL_BC_ICMS"
	aAdd( aStru,{ "DD_OPE",	"C",	010,	0 } ) 	//"_VL_ICMS"	
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )	
	
	CriaTMPReg(aStru,"RELAC3","F100",@aTrbs)		

	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0369))	// "F100 - DEMAIS DOCUMENTOS E OPERAÇÕES GERADORAS DE CONTRIBUIÇÃO E CRÉDITOS"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0114, cPictChar })	//"Tipo de Operação"	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0116, cPictChar })	//"Código do participante"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0237, cPictChar })	//Código do item (campo 02 do Registro 0200)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0370, cPictChar })	//"Data da Operação (ddmmaaaa)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0371, cPictNUM })	//"Valor da Operação/Item"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0220, cPictChar })	//Código da Situação Tributária referente ao PIS/PASEP, conforme a Tabela indicada no item 4.3.3.	                 	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0221, cPictNUM })	//"Base de cálculo do PIS/PASEP"	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0372, cPictALI2 })	//"Alíquota do PIS/PASEP"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0158, cPictNUM })	//Valor do PIS/PASEP
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0226, cPictChar })	//Código da Situação Tributária referente a COFINS, conforme a Tabela indicada no item 4.3.4.
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0227, cPictNUM })	//Base de cálculo da COFINS	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0373, cPictALI2 })	//"Alíquota da COFINS"		
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0162, cPictNUM })	//Valor da COFINS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0374, cPictChar })	//"Código da Base de Cálculo dos Créditos, conforme a tabela indicada no item 4.3.7, caso seja informado código representativo de crédito nos Campos 07 (CST_PIS) e 11 (CST_COFINS)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0154, cPictChar })	//Indicador da origem do crédito:
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0232, cPictChar })	//Código da conta analítica contábil debitada/creditada
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0164, cPictChar })	//Código do Centro de Custos
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0375, cPictChar })	//"Descrição do Documento/Operação"
//	aAdd( aTitulo[Len(aTitulo)][2],{ "" /*STR0135*/, cPictChar })	//"Código da informação complementar do documento fiscal (campo 02 do Registro 0450)"	
//	aAdd( aTitulo[Len(aTitulo)][2],{ "" /*STR0163*/, cPictChar })	//"Código da conta analítica contábil debitada/creditada"	

	//REGISTRO F111: PROCESSO REFERENCIADO
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "NUM_PR",	"C",	020,	0 } ) 	//"_NUM_PROC"
	aAdd( aStru,{ "IND_PR",	"C",	001,	0 } ) 	//"_IND_PROC"
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )	
	
	CriaTMPReg(aStru,"RELAC4","F111",@aTrbs)	
	
	aAdd( aTitulo, {}) 
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0376))	//"F111 - PROCESSO REFERENCIADO"	 
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0138, cPictChar })	//"Identificação do processo ou ato concessório"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0139, cPictChar })	//"Origem do processo"	
	
	//REGISTRO F120: BENS INCORPORADOS AO ATIVO IMOBILIZADO - OPERAÇÕES GERADORAS DE CRÉDITOS COM BASE NOS ENCARGOS DE DEPRECIAÇÃO E AMORTIZAÇÃO
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "NB_CRE",	"C",	002,	0 } ) 	//"_NAT_BC_CRED"
	aAdd( aStru,{ "IB_IMO",	"C",	002,	0 } ) 	//"_IDENT_BEM_IMOB"	
	aAdd( aStru,{ "IO_CRE",	"C",	001,	0 } ) 	//"_IND_ORIG_CRED"
	aAdd( aStru,{ "IUBIMO",	"C",	001,	0 } ) 	//"_IND_UTIL_BEM_IMOB"
	aAdd( aStru,{ "V_O_DE",	"N",	014,	2 } ) 	//"_VL_OPER_DEP"	
	aAdd( aStru,{ "PONBCR",	"N",	014,	2 } ) 	//"_PARC_OPER_NAO_BC_CRED"	
	aAdd( aStru,{ "CS_PIS",	"C",	002,	0 } ) 	//"_CST_PIS"
	aAdd( aStru,{ "VB_PIS",	"N",	014,	2 } ) 	//"_VL_BC_PIS"
	aAdd( aStru,{ "AL_PIS",	"N",	008,	4 } ) 	//"_ALIQ_PIS"
	aAdd( aStru,{ "VL_PIS",	"N",	014,	2 } ) 	//"_VL_PIS"
	aAdd( aStru,{ "CS_COF",	"C",	002,	0 } ) 	//"_IDENT_BEM_IMOB"
	aAdd( aStru,{ "VB_COF",	"N",	014,	2 } ) 	//"_IDENT_BEM_IMOB"
	aAdd( aStru,{ "AL_COF",	"N",	008,	4 } ) 	//"_ALIQ_COFINS"
	aAdd( aStru,{ "VL_COF",	"N",	014,	2 } ) 	//"_VL_COFINS"
	aAdd( aStru,{ "CO_CTA",	"C",	030,	0 } ) 	//"_COD_CTA"
	aAdd( aStru,{ "CO_CCU",	"C",	030,	0 } ) 	//"_COD_CCUS"
	aAdd( aStru,{ "DB_IMO",	"C",	030,	0 } ) 	//"_DESC_BEM_IMOB"
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )	
	
	CriaTMPReg(aStru,"RELAC3","F120",@aTrbs)	
	
	aAdd( aTitulo, {}) 
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0377))	//"F120 - BENS INCORPORADOS AO ATIVO IMOBILIZADO - OPERAÇÕES GERADORAS DE CRÉDITOS COM BASE NOS ENCARGOS DE DEPRECIAÇÃO E AMORTIZAÇÃO"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0378, cPictChar })	//"Código da Base de Cálculo do Crédito sobre Bens Incorporados ao Ativo Imobilizado, conforme a Tabela indicada no item 4.3.7"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0379, cPictChar })	//"Identificação dos Bens/Grupo de Bens Incorporados ao Ativo Imobilizado"	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0380, cPictChar })	//"Indicador da origem do bem incorporado ao ativo imobilizado, gerador de crédito"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0381, cPictChar })	//"Indicador da Utilização dos Bens Incorporados ao Ativo Imobilizado"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0382, cPictNUM })	//"Valor do Encargo de Depreciação/Amortização Incorrido no Período"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0383, cPictNUM })	//"Parcela do Valor do Encargo de Depreciação/Amortização a excluir da base de cálculo de Crédito"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0220, cPictChar })	//Código da Situação Tributária referente ao PIS/PASEP, conforme a Tabela indicada no item 4.3.3.
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0156, cPictNUM })	//Base de cálculo do Crédito de PIS/PASEP no período (06 - 07)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0222, cPictALI2 })	//Alíquota do PIS/PASEP (em percentual)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0264, cPictNUM })	//Valor do Crédito de PIS/PASEP
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0226, cPictChar })	//Código da Situação Tributária referente a COFINS, conforme a Tabela indicada no item 4.3.4.
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0227, cPictNUM })	//Base de Cálculo do Crédito da COFINS no período (06 - 07)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0228, cPictALI2 })	//Alíquota da COFINS (em percentual)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0265, cPictNUM })	//Valor do crédito da COFINS	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0232, cPictChar })	//Código da conta analítica contábil debitada/creditada		
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0164, cPictChar })	//Código do Centro de Custos
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0384, cPictChar })	//"Descrição complementar do bem ou grupo de bens, com crédito apurado com base nos encargos de depreciação ou amortização"	

	//REGISTRO F129: PROCESSO REFERENCIADO
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "NUM_PR",	"C",	020,	0 } ) 	//"_NUM_PROC"
	aAdd( aStru,{ "IND_PR",	"C",	001,	0 } ) 	//"_IND_PROC"
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )	
	
	CriaTMPReg(aStru,"RELAC4","F129",@aTrbs)	
	
	aAdd( aTitulo, {}) 
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0385))	//F129 - PROCESSO REFERENCIADO
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0138, cPictChar })	//"Identificação do processo ou ato concessório"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0139, cPictChar })	//"Origem do processo"
	
	//REGISTRO F130: BENS INCORPORADOS AO ATIVO IMOBILIZADO - OPERAÇÕES GERADORAS DE CRÉDITOS COM BASE NO VALOR DE AQUISIÇÃO/CONTRIBUIÇÃO
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "NB_CRE",	"C",	002,	0 } ) 	//"_NAT_BC_CRED"
	aAdd( aStru,{ "IB_IMO",	"C",	002,	0 } ) 	//"_IDENT_BEM_IMOB"	
	aAdd( aStru,{ "IO_CRE",	"C",	001,	0 } ) 	//"_IND_ORIG_CRED"
	aAdd( aStru,{ "IUBIMO",	"C",	001,	0 } ) 	//"_IND_UTIL_BEM_IMOB"
	aAdd( aStru,{ "MO_AQU",	"C",	007,	0 } ) 	//"_MES_OPER_AQUIS"	
	aAdd( aStru,{ "V_O_DE",	"N",	014,	2 } ) 	//"_VL_OPER_DEP"	
	aAdd( aStru,{ "PONBCR",	"N",	014,	2 } ) 	//"_PARC_OPER_NAO_BC_CRED"
	aAdd( aStru,{ "VB_CRE",	"N",	014,	2 } ) 	//"_VL_BC_CRED"
	aAdd( aStru,{ "IN_PAR",	"C",	002,	0 } ) 	//"_IND_NR_PARC"
	aAdd( aStru,{ "CS_PIS",	"C",	002,	0 } ) 	//"_CST_PIS"
	aAdd( aStru,{ "VB_PIS",	"N",	014,	2 } ) 	//"_VL_BC_PIS"
	aAdd( aStru,{ "AL_PIS",	"N",	008,	4 } ) 	//"_ALIQ_PIS"
	aAdd( aStru,{ "VL_PIS",	"N",	014,	2 } ) 	//"_VL_PIS"
	aAdd( aStru,{ "CS_COF",	"C",	002,	0 } ) 	//"_CST_COFINS"
	aAdd( aStru,{ "VB_COF",	"N",	014,	2 } ) 	//"_VL_BC_COFINS"
	aAdd( aStru,{ "AL_COF",	"N",	008,	4 } ) 	//"_ALIQ_COFINS"
	aAdd( aStru,{ "VL_COF",	"N",	014,	2 } ) 	//"_VL_COFINS"
	aAdd( aStru,{ "CO_CTA",	"C",	020,	0 } ) 	//"_COD_CTA"
	aAdd( aStru,{ "CO_CCU",	"C",	020,	0 } ) 	//"_COD_CCUS"
	aAdd( aStru,{ "DB_IMO",	"C",	020,	0 } ) 	//"_DESC_BEM_IMOB"
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )
		
	CriaTMPReg(aStru,"RELAC3","F130",@aTrbs)	
	
	aAdd( aTitulo, {}) 
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0386))	//"F130 - BENS INCORPORADOS AO ATIVO IMOBILIZADO - OPERAÇÕES GERADORAS DE CRÉDITOS COM BASE NO VALOR DE AQUISIÇÃO/CONTRIBUIÇÃO"	
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0378, cPictChar })	//"Código da Base de Cálculo do Crédito sobre Bens Incorporados ao Ativo Imobilizado, conforme a Tabela indicada no item 4.3.7"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0379, cPictChar })	//"Identificação dos Bens/Grupo de Bens Incorporados ao Ativo Imobilizado"	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0380, cPictChar })	//"Indicador da origem do bem incorporado ao ativo imobilizado, gerador de crédito"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0381, cPictChar })	//"Indicador da Utilização dos Bens Incorporados ao Ativo Imobilizado"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0387, cPictChar })	//"Mês/Ano de Aquisição dos Bens Incorporados ao Ativo Imobilizado, com apuração de crédito com base no valor de aquisição"	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0388, cPictNUM })	//"Valor de Aquisição dos Bens Incorporados ao Ativo Imobilizado - Crédito com base no valor de aquisição"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0389, cPictNUM })	//"Parcela do Valor de Aquisição a excluir da base de cálculo de Crédito"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0390, cPictNUM })	//"Valor da Base de Cálculo do Crédito sobre Bens Incorporados ao Ativo Imobilizado (07 - 08)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0391, cPictChar })	//"Indicador do Número de Parcelas a serem apropriadas (Crédito sobre Valor de Aquisição)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0220, cPictChar })	//Código da Situação Tributária referente ao PIS/PASEP, conforme a Tabela indicada no item 4.3.3.
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0156, cPictNUM })	//Base de cálculo do Crédito de PIS/PASEP no período (06 - 07)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0222, cPictALI2 })	//Alíquota do PIS/PASEP (em percentual)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0264, cPictNUM })	//Valor do Crédito de PIS/PASEP
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0226, cPictChar })	//Código da Situação Tributária referente a COFINS, conforme a Tabela indicada no item 4.3.4.
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0227, cPictNUM })	//Base de Cálculo do Crédito da COFINS no período (06 - 07)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0228, cPictALI2 })	//Alíquota da COFINS (em percentual)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0265, cPictNUM })	//Valor do crédito da COFINS	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0232, cPictChar })	//Código da conta analítica contábil debitada/creditada		
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0164, cPictChar })	//Código do Centro de Custos
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0384, cPictChar })	//"Descrição complementar do bem ou grupo de bens, com crédito apurado com base nos encargos de depreciação ou amortização"		

	//REGISTRO F139: PROCESSO REFERENCIADO
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "NUM_PR",	"C",	020,	0 } ) 	//"_NUM_PROC"
	aAdd( aStru,{ "IND_PR",	"C",	001,	0 } ) 	//"_IND_PROC"
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )	
	
	CriaTMPReg(aStru,"RELAC4","F139",@aTrbs)	
	
	aAdd( aTitulo, {}) 
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0392))	//"F139 - PROCESSO REFERENCIADO"	 
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0138, cPictChar })	//"Identificação do processo ou ato concessório"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0139, cPictChar })	//"Origem do processo"
	
	IncProc("Gerando estrutura...")
	
	//REGISTRO F150: CRÉDITO PRESUMIDO SOBRE ESTOQUE DE ABERTURA
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "NB_CRE",	"C",	002,	0 } ) 	//"_NAT_BC_CRED"
	aAdd( aStru,{ "VT_EST",	"N",	014,	2 } ) 	//"_IDENT_BEM_IMOB"	
	aAdd( aStru,{ "EST_IMP",	"N",	014,	2 } ) 	//"_IND_ORIG_CRED"
	aAdd( aStru,{ "V_B_EST",	"N",	014,	2 } ) 	//"_IND_UTIL_BEM_IMOB"
	aAdd( aStru,{ "VBM_EST",	"N",	014,	2 } ) 	//"_VL_OPER_DEP"	
	aAdd( aStru,{ "CS_PIS",	"C",	002,	0 } ) 	//"_CST_PIS"
	aAdd( aStru,{ "AL_PIS",	"N",	008,	4 } ) 	//"_ALIQ_PIS"	
	aAdd( aStru,{ "VC_PIS",	"N",	014,	2 } ) 	//"_VL_CRED_PIS"	
	aAdd( aStru,{ "CS_COF",	"C",	002,	0 } ) 	//"_IDENT_BEM_IMOB"
	aAdd( aStru,{ "AL_COF",	"N",	008,	4 } ) 	//"_ALIQ_COFINS"
	aAdd( aStru,{ "VC_COF",	"N",	014,	2 } ) 	//"_VL_CRED_ COFINS"
	aAdd( aStru,{ "DES_EST",	"C",	100,	0 } ) 	//"_DESC_EST"
	aAdd( aStru,{ "CO_CTA",	"C",	030,	0 } ) 	//"_COD_CTA"
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )
	//aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )	
	
	CriaTMPReg(aStru,"RELAC3","F150",@aTrbs)	

	aAdd( aTitulo, {}) 
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0393))	//"F150 - CRÉDITO PRESUMIDO SOBRE ESTOQUE DE ABERTURA"	 
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0153, cPictChar })	//"Código da Base de Cálculo do Crédito sobre Estoque de Abertura, conforme a Tabela indicada no item 4.3.7."
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0394, cPictNUM })	//"Valor Total do Estoque de Abertura"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0395, cPictNUM })	//"Parcela do estoque de abertura referente a bens, produtos e mercadorias importados, ou adquiridas no mercado interno sem direito ao crédito"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0396, cPictNUM })	//"Valor da Base de Cálculo do Crédito sobre o Estoque de Abertura (03 - 04)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0397, cPictNUM })	//"Valor da Base de Cálculo Mensal do Crédito sobre o Estoque de Abertura (1/12 avos do campo 05)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0220, cPictChar })	//Código da Situação Tributária referente ao PIS/PASEP, conforme a Tabela indicada no item 4.3.3.
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0222, cPictALI2 })	//Alíquota do PIS/PASEP (em percentual)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0398, cPictNUM })	//"Valor Mensal do Crédito Presumido Apurado para o Período -  PIS/PASEP  (06 x 08)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0226, cPictChar })	//Código da Situação Tributária referente ao COFINS, conforme a Tabela indicada no item 4.3.4
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0228, cPictALI2 })	//Alíquota do COFINS (em percentual)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0399, cPictNUM })	//"Valor Mensal do Crédito Presumido Apurado para o Período - COFINS (06 x 11)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0400, cPictChar })	//"Descrição do estoque"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0232, cPictChar })	//"Código da conta analítica contábil debitada/creditada"
	
	//REGISTRO F200: OPERAÇÕES DA ATIVIDADE IMOBILIÁRIA - UNIDADE IMOBILIÁRIA VENDIDA
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "IND_OPE",	"C",	002,	0 } ) 	//"_IND_OPER"
	aAdd( aStru,{ "UN_IMOB",	"C",	002,	0 } ) 	//"_UNID_IMOB"	
	aAdd( aStru,{ "IDE_EMP",	"C",	060,	0 } ) 	//"_IDENT_EMP"
	aAdd( aStru,{ "DU_IMOB",	"C",	090,	0 } ) 	//"_DESC_UNID_IMOB"
	aAdd( aStru,{ "NUM_CON",	"C",	090,	0 } ) 	//"_NUM_CONT"	
	aAdd( aStru,{ "CPFCNPJ",	"C",	020,	0 } ) 	//"_CPF_CNPJ_ADQU"
	aAdd( aStru,{ "DT_OPER",	"C",	008,	0 } ) 	//"_DT_OPER"	
	aAdd( aStru,{ "VT_VEND",	"N",	014,	2 } ) 	//"_VL_TOT_VEND"	
	aAdd( aStru,{ "VR_ACUM",	"N",	014,	2 } ) 	//"_VL_REC_ACUM"
	aAdd( aStru,{ "VTT_REC",	"N",	014,	2 } ) 	//"_VL_TOT_REC"
	aAdd( aStru,{ "CST_PIS",	"C",	002,	0 } ) 	//"_CST_PIS"
	aAdd( aStru,{ "VBC_PIS",	"N",	014,	2 } ) 	//"_VL_BC_PIS"
	aAdd( aStru,{ "ALQ_PIS",	"N",	008,	2 } ) 	//"_ALIQ_PIS"
	aAdd( aStru,{ "VL_PIS",	"N",	014,	2 } ) 	//"_VL_PIS"
	aAdd( aStru,{ "CS_COF",	"C",	002,	0 } ) 	//"_CST_COFINS"
	aAdd( aStru,{ "VB_COF",	"N",	014,	2 } ) 	//"_VL_BC_COFINS"
	aAdd( aStru,{ "AL_COF",	"N",	008,	4 } ) 	//"_ALIQ_COFINS"
	aAdd( aStru,{ "VL_COF",	"N",	014,	2 } ) 	//"_VL_COFINS"
	aAdd( aStru,{ "PR_REC",	"N",	006,	2 } ) 	//"_PERC_REC_RECEB"
	aAdd( aStru,{ "IN_EMP",	"C",	030,	0 } ) 	//"_IND_NAT_EMP"
	aAdd( aStru,{ "IN_COM",	"C",	030,	0 } ) 	//"_PERC_REC_RECEB"		
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )

	CriaTMPReg(aStru,"RELAC3","F200",@aTrbs)		

	aAdd( aTitulo, {}) 
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0401))	//"F200 - OPERAÇÕES DA ATIVIDADE IMOBILIÁRIA - UNIDADE IMOBILIÁRIA VENDIDA"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0114, cPictChar })	//Indicador do Tipo da Operação
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0402, cPictChar })	//"Indicador do tipo de unidade imobiliária Vendida"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0403, cPictChar })	//"Identificação/Nome do Empreendimento"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0404, cPictChar })	//"Descrição resumida da unidade imobiliária vendida"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0405, cPictChar })	//"Número do Contrato/Documento que formaliza a Venda da Unidade Imobiliária"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0406, cPictChar })	//"Identificação da pessoa física (CPF) ou da pessoa jurídica (CNPJ) adquirente da unidade imobiliária"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0370, cPictChar })	//Data da operação de venda da unidade imobiliária
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0407, cPictNUM })	//"Valor total da unidade imobiliária vendida atualizado até o período da escrituração"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0408, cPictNUM })	//"Valor recebido acumulado até o mês anterior ao da escrituração"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0409, cPictNUM })	//"Valor total recebido no mês da escrituração"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0220, cPictChar })	//Código da Situação Tributária referente ao PIS/PASEP, conforme a Tabela indicada no item 4.3.3.
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0221, cPictNUM })	//Base de Cálculo do PIS/PASEP
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0222, cPictALI1 })	//Alíquota do PIS/PASEP (em percentual)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0225, cPictNUM })	//Valor do PIS/PASEP
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0226, cPictChar })	//Código da Situação Tributária referente a COFINS, conforme a Tabela indicada no item 4.3.4.
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0227, cPictNUM })	//Base de Cálculo da COFINS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0228, cPictALI1 })	//Alíquota da COFINS (em percentual)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0231, cPictNUM })	//Valor da COFINS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0410, cPictChar })	//"Percentual da receita total recebida até o mês, da unidade imobiliária vendida ((Campo 10 + Campo 11) / Campo 09)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0411, cPictChar })	//"Indicador da Natureza Específica do Empreendimento"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0136, cPictChar })	//"Informações Complementares"
	
	//REGISTRO F205: OPERAÇÕES DA ATIVIDADE IMOBILIÁRIA - CUSTO INCORRIDO DA UNIDADE IMOBILIÁRIA
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "VLCIAA",	"N",	014,	2 } ) 	//"_VL_CUS_INC_ACUM_ANT"
	aAdd( aStru,{ "VCIPEC",	"N",	014,	2 } ) 	//"_VL_CUS_INC_PER_ESC"	
	aAdd( aStru,{ "VCIACU",	"N",	014,	2 } ) 	//"_VL_CUS_INC_ACUM"
	aAdd( aStru,{ "VEBIAC",	"N",	014,	2 } ) 	//"_VL_EXC_BC_CUS_INC_ACUM"
	aAdd( aStru,{ "VBCINC",	"N",	014,	2 } ) 	//"_VL_BC_CUS_INC"	
	aAdd( aStru,{ "CST_PIS",	"C",	002,	0 } ) 	//"_CST_PIS"
	aAdd( aStru,{ "ALQ_PIS",	"N",	008,	4 } ) 	//"_ALIQ_PIS"	
	aAdd( aStru,{ "VCPACUM",	"N",	014,	2 } ) 	//"_VL_CRED_PIS_ACUM"	
	aAdd( aStru,{ "VCPDANT",	"N",	014,	2 } ) 	//"_VL_CRED_PIS_DESC_ANT"
	aAdd( aStru,{ "VCPDESC",	"N",	014,	2 } ) 	//"_VL_CRED_PIS_DESC"
	aAdd( aStru,{ "VCPDFUT",	"N",	014,	2 } ) 	//"_VL_CRED_PIS_DESC_FUT"
	aAdd( aStru,{ "CS_COFI",	"C",	002,	0 } ) 	//"_CST_COFINS"
	aAdd( aStru,{ "AL_COFI",	"N",	014,	4 } ) 	//"_ALIQ_COFINS"
	aAdd( aStru,{ "VCCACUM",	"N",	014,	2 } ) 	//"_VL_CRED_COFINS_ACUM"
	aAdd( aStru,{ "VCCDANT",	"N",	014,	2 } ) 	//"_VL_CRED_COFINS_DESC_ANT"
	aAdd( aStru,{ "VCCDESC",	"N",	014,	2 } ) 	//"_VL_CRED_COFINS_DESC"
	aAdd( aStru,{ "VCCDFUT",	"N",	014,	2 } ) 	//"_VL_CRED_COFINS_DESC_FUT"
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )

	CriaTMPReg(aStru,"RELAC4","F205",@aTrbs)		

	aAdd( aTitulo, {}) 
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0412))	//"F205 - OPERAÇÕES DA ATIVIDADE IMOBILIÁRIA - CUSTO INCORRIDO DA UNIDADE IMOBILIÁRIA"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0413, cPictNUM })	//"Valor Total do Custo Incorrido da unidade imobiliária acumulado até o mês anterior ao da escrituração"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0414, cPictNUM })	//"Valor Total do Custo Incorrido da unidade imobiliária no mês da escrituração"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0415, cPictNUM })	//"Valor Total do Custo Incorrido da unidade imobiliária acumulado até o mês da escrituração (Campo 02 + 03)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0416, cPictNUM })	//"Parcela do Custo Incorrido sem direito ao crédito da atividade imobiliária, acumulado até o período"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0417, cPictNUM })	//"Valor da Base de Cálculo do Crédito sobre o Custo Incorrido, acumulado até o período da escrituração (Campo 04 - 05)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0220, cPictChar })	//Código da Situação Tributária referente ao PIS/PASEP, conforme a Tabela indicada no item 4.3.3.
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0157, cPictALI2 })	//Alíquota do PIS/PASEP (em percentual)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0418, cPictNUM })	//"Valor Total do Crédito Acumulado sobre o custo incorrido - PIS/PASEP (Campo 06 x 08)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0419, cPictNUM })	//"Parcela do crédito descontada até o período anterior da escrituração - PIS/PASEP (proporcional à receita recebida até o mês anterior)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0420, cPictNUM })	//"Parcela a descontar no período da escrituração  - PIS/PASEP (proporcional à receita recebida no mês)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0421, cPictNUM })	//"Parcela a descontar em períodos futuros  - PIS/PASEP (Campo 09 - 10 - 11)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0226, cPictChar })	//Código da Situação Tributária referente ao COFINS, conforme a Tabela indicada no item 4.3.4.
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0228, cPictALI2 })	//Alíquota do COFINS (em percentual)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0422, cPictNUM })	//"Valor Total do Crédito Acumulado sobre o custo incorrido - COFINS (Campo 06 x 14)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0423, cPictNUM })	//"Parcela do crédito descontada até o período anterior da escrituração - COFINS (proporcional à receita recebida até o mês anterior)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0424, cPictNUM })	//"Parcela a descontar no período da escrituração  - COFINS (proporcional à receita recebida no mês)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0425, cPictNUM })	//"Parcela a descontar em períodos futuros  - COFINS (Campo 15 - 16 - 17)"

	//REGISTRO F210: OPERAÇÕES DA ATIVIDADE IMOBILIÁRIA - CUSTO ORÇADO DA UNIDADE IMOBILIÁRIA VENDIDA
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "VC_ORC",	"N",	014,	2 } ) 	//"_VL_CUS_INC_ACUM_ANT"
	aAdd( aStru,{ "VL_EXC",	"N",	014,	2 } ) 	//"_VL_CUS_INC_PER_ESC"	
	aAdd( aStru,{ "VCOAJU",	"N",	014,	2 } ) 	//"_VL_CUS_INC_ACUM"
	aAdd( aStru,{ "VBCRED",	"N",	014,	2 } ) 	//"_VL_EXC_BC_CUS_INC_ACUM"
	aAdd( aStru,{ "CS_PIS",	"C",	002,	0 } ) 	//"_CST_PIS"
	aAdd( aStru,{ "AL_PIS",	"N",	008,	4 } ) 	//"_ALIQ_PIS"	
	aAdd( aStru,{ "VCPUTI",	"N",	014,	2 } ) 	//"_VL_CRED_PIS_UTIL"	
	aAdd( aStru,{ "CS_COFI",	"C",	002,	0 } ) 	//"_CST_COFINS"
	aAdd( aStru,{ "AL_COFI",	"N",	014,	4 } ) 	//"_ALIQ_COFINS"
	aAdd( aStru,{ "VCCUTIL",	"N",	014,	2 } ) 	//"_VL_CRED_COFINS_UTIL"
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )
	
	CriaTMPReg(aStru,"RELAC4","F210",@aTrbs)		

	aAdd( aTitulo, {}) 
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0426))	//"F210 - OPERAÇÕES DA ATIVIDADE IMOBILIÁRIA - CUSTO ORÇADO DA UNIDADE IMOBILIÁRIA VENDIDA"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0427, cPictNUM })	//"Valor Total do Custo Orçado para Conclusão da Unidade Vendida"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0428, cPictNUM })	//"Valores Referentes a Pagamentos a Pessoas Físicas, Encargos Trabalhistas, Sociais e Previdenciários e à aquisição de bens e serviços não sujeitos ao pagamento das contribuições"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0429, cPictNUM })	//"Valor da Base de Calculo do Crédito sobre o Custo Orçado Ajustado (Campo 02 - 03)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0430, cPictNUM })	//"Valor da Base de Cálculo do Crédito sobre o Custo Orçado referente ao mês da escrituração, proporcionalizada em função da receita recebida no mês"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0220, cPictChar })	//Código da Situação Tributária referente ao PIS/PASEP, conforme a Tabela indicada no item 4.3.3.
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0222, cPictALI2 })	//Alíquota do PIS/PASEP (em percentual)	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0431, cPictNUM })	//"Valor do Crédito sobre o custo orçado a ser utilizado no período da escrituração - PIS/PASEP (Campo 05 x 07)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0226, cPictChar })	//Código da Situação Tributária referente ao COFINS, conforme a Tabela indicada no item 4.3.4.
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0228, cPictALI2 })	//Alíquota do COFINS (em percentual)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0432, cPictNUM })	//"Valor do Crédito sobre o custo orçado a ser utilizado no período da escrituração - COFINS (Campo 05 x 10)"
	
	//REGISTRO F211: PROCESSO REFERENCIADO
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "NUM_PR",	"C",	020,	0 } ) 	//"_NUM_PROC"
	aAdd( aStru,{ "IND_PR",	"C",	001,	0 } ) 	//"_IND_PROC"
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )	
	
	CriaTMPReg(aStru,"RELAC4","F211",@aTrbs)	
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0433))	// "F211 - PROCESSO REFERENCIADO"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0138, cPictChar })	//"Identificação do processo ou ato concessório"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0139, cPictChar })	//"Origem do processo"

	//REGISTRO F500: CONSOLIDAÇÃO DAS OPERAÇÕES DA PESSOA JURÍDICA SUBMETIDA AO REGIME DE TRIBUTAÇÃO COM BASE NO LUCRO PRESUMIDO  - INCIDÊNCIA DO PIS/PASEP E DA COFINS PELO REGIME DE CAIXA
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	005,	0 } ) 	//"_REG"
	aAdd( aStru,{ "VRCAIXA",	"N",	014,	2 } ) 	//"_VL_REC_CAIXA"
	aAdd( aStru,{ "CST_PIS",	"C",	002,	0 } ) 	//"_CST_PIS"
	aAdd( aStru,{ "VDC_PIS",	"N",	010,	2 } ) 	//"_VL_DESC_PIS"
	aAdd( aStru,{ "VBC_PIS",	"N",	016,	2 } ) 	//"_VL_BC_PIS"
	aAdd( aStru,{ "ALQ_PIS",	"N",	005,	2 } ) 	//"_ALIQ_PIS"
	aAdd( aStru,{ "VL_PIS",	"N",	014,	2 } ) 	//"_VL_PIS"
	aAdd( aStru,{ "CS_COFS",	"C",	002,	0 } ) 	//"_CST_COFINS"
	aAdd( aStru,{ "VD_COFI",	"N",	010,	2 } ) 	//"_VL_DESC_COFINS"
	aAdd( aStru,{ "VB_COFI",	"N",	016,	2 } ) 	//"_VL_BC_COFINS"
	aAdd( aStru,{ "AL_COFI",	"N",	014,	4 } ) 	//"_ALIQ_COFINS"
	aAdd( aStru,{ "VL_COFI",	"N",	014,	2 } ) 	//"_VL_COFINS"
	aAdd( aStru,{ "COD_MOD",	"C",	002,	0 } ) 	//"_COD_MOD"
	aAdd( aStru,{ "CFOP",		"C",	004,	0 } ) 	//"_CFOP"
	aAdd( aStru,{ "CO_CTA",	"C",	020,	0 } ) 	//"_COD_CTA"
	aAdd( aStru,{ "IN_COMP",	"C",	020,	0 } ) 	//"_COD_CTA"
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )	                                               	 	
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )
	
	CriaTMPReg(aStru,"RELAC3","F500",@aTrbs)	
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0434))	//"F500 - CONSOLIDAÇÃO DAS OPERAÇÕES DA PESSOA JURÍDICA SUBMETIDA AO REGIME DE TRIBUTAÇÃO COM BASE NO LUCRO PRESUMIDO  - INCIDÊNCIA DO PIS/PASEP E DA COFINS PELO REGIME DE CAIXA"		 
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0435, cPictNUM })	//"Valor total da receita recebida, referente à combinação de CST e Alíquota"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0220, cPictChar })	//Código da Situação Tributária referente ao PIS/PASEP	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0436, cPictNUM })	//"Valor do desconto / exclusão da base de cálculo"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0221, cPictNUM })	//Valor da base de cálculo do PIS/PASEP
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0222, cPictALI2 })	//Alíquota do PIS/PASEP (em percentual)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0225, cPictNUM })	//Valor do PIS/PASEP
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0159, cPictChar })	//Código da Situação Tributária referente a COFINS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0437, cPictNUM })	//"Valor do desconto / exclusão da base de cálculo"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0160, cPictNUM })	//Valor da base de cálculo da COFINS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0161, cPictALI2 })	//Alíquota da COFINS (em percentual)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0162, cPictNUM })	//Valor da COFINS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0171, cPictChar })	//Código do modelo do documento fiscal conforme a Tabela 4.1.1
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0206, cPictChar })	//Código fiscal de operação e prestação
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0232, cPictChar })	//Código da conta analítica contábil debitada/creditada
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0136, cPictChar })	//Informação complementar			

	//REGISTRO F509: PROCESSO REFERENCIADO
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "NUM_PR",	"C",	020,	0 } ) 	//"_NUM_PROC"
	aAdd( aStru,{ "IND_PR",	"C",	001,	0 } ) 	//"_IND_PROC"
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )	
	
	CriaTMPReg(aStru,"RELAC4","F509",@aTrbs)	
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0438))	//"F509 - PROCESSO REFERENCIADO"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0138, cPictChar })	//"Identificação do processo ou ato concessório"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0139, cPictChar })	//"Origem do processo"

	//REGISTRO F510: CONSOLIDAÇÃO DAS OPERAÇÕES DA PESSOA JURÍDICA SUBMETIDA AO REGIME DE TRIBUTAÇÃO COM BASE NO LUCRO PRESUMIDO - INCIDÊNCIA DO PIS/PASEP E DA COFINS PELO REGIME DE CAIXA (APURAÇÃO DA CONTRIBUIÇÃO POR UNIDADE DE MEDIDA DE PRODUTO - ALÍQUOTA EM REAIS)
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	005,	0 } ) 	//"_REG"
	aAdd( aStru,{ "VRCAIXA",	"N",	014,	2 } ) 	//"_VL_REC_CAIXA"
	aAdd( aStru,{ "CST_PIS",	"C",	002,	0 } ) 	//"_CST_PIS"
	aAdd( aStru,{ "VDC_PIS",	"N",	014,	2 } ) 	//"_VL_DESC_PIS"
	aAdd( aStru,{ "QBC_PIS",	"N",	014,	2 } ) 	//"_QUANT_BC_PIS"
	aAdd( aStru,{ "AP_QUAN",	"N",	008,	4 } ) 	//"_ALIQ_PIS_QUANT"
	aAdd( aStru,{ "VL_PIS",	"N",	018,	2 } ) 	//"_VL_PIS"	
	aAdd( aStru,{ "CS_COFS",	"C",	002,	0 } ) 	//"_CST_COFINS"
	aAdd( aStru,{ "VD_COFI",	"N",	014,	2 } ) 	//"_VL_DESC_COFINS"
	aAdd( aStru,{ "QB_COFI",	"N",	014,	2 } ) 	//"_QUANT_BC_COFINS"
	aAdd( aStru,{ "AC_QUAN",	"N",	014,	4 } ) 	//"_ALIQ_COFINS_QUANT"
	aAdd( aStru,{ "VL_COFI",	"N",	018,	2 } ) 	//"_VL_COFINS"
	aAdd( aStru,{ "COD_MOD",	"C",	002,	0 } ) 	//"_COD_MOD"
	aAdd( aStru,{ "CFOP",		"C",	004,	0 } ) 	//"_CFOP"
	aAdd( aStru,{ "CO_CTA",	"C",	040,	0 } ) 	//"_COD_CTA"
	aAdd( aStru,{ "IN_COMP",	"C",	040,	0 } ) 	//"_INFO_COMPL"
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )	
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )
	
	CriaTMPReg(aStru,"RELAC4","F510",@aTrbs)		

	aAdd( aTitulo, {}) 
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0439))	//"F510 - CONSOLIDAÇÃO DAS OPERAÇÕES DA PESSOA JURÍDICA SUBMETIDA AO REGIME DE TRIBUTAÇÃO COM BASE NO LUCRO PRESUMIDO - INCIDÊNCIA DO PIS/PASEP E DA COFINS PELO REGIME DE CAIXA (APURAÇÃO DA CONTRIBUIÇÃO POR UNIDADE DE MEDIDA DE PRODUTO - ALÍQUOTA EM REAIS)"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0435, cPictNUM })	//Valor total da receita recebida, referente à combinação de CST e Alíquota.
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0220, cPictChar })	//Código da Situação Tributária referente ao PIS/PASEP
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0440, cPictNUM })	//"Valor do desconto / exclusão"	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0223, cPictNUM })	//Base de cálculo em quantidade - PIS/PASEP
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0224, cPictALI2 })	//Alíquota do PIS/PASEP (em reais)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0225, cPictNUM })	//Valor do PIS/PASEP
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0226, cPictChar })	//Código da Situação Tributária referente a COFINS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0440, cPictNUM })	//Valor do desconto / exclusão
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0229, cPictNUM })	//Base de cálculo em quantidade - COFINS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0230, cPictALI2 })	//Alíquota da COFINS (em reais)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0162, cPictNUM })	//Valor da COFINS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0171, cPictChar })	//Código do modelo do documento fiscal conforme a Tabela 4.1.1
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0206, cPictChar })	//Código fiscal de operação e prestação
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0232, cPictChar })	//Código da conta analítica contábil debitada/creditada
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0136, cPictChar })	//Informação complementar

	//REGISTRO F519: PROCESSO REFERENCIADO
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "NUM_PR",	"C",	015,	0 } ) 	//"_NUM_PROC"
	aAdd( aStru,{ "IND_PR",	"C",	001,	0 } ) 	//"_IND_PROC"
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )	
	
	CriaTMPReg(aStru,"RELAC4","F519",@aTrbs)	
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0441))	//"F519 - PROCESSO REFERENCIADO"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0138, cPictChar })	//"Identificação do processo ou ato concessório"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0139, cPictChar })	//"Origem do processo"	
	
	//REGISTRO F525: COMPOSIÇÃO DA RECEITA ESCRITURADA NO PERÍODO - DETALHAMENTO DA RECEITA RECEBIDA PELO REGIME DE CAIXA	
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	005,	0 } ) 	//"_REG"
	aAdd( aStru,{ "VL_REC",	"N",	018,	2 } ) 	//"_VL_REC"
	aAdd( aStru,{ "IND_REC",	"C",	002,	0 } ) 	//"_IND_REC"
	aAdd( aStru,{ "CNPJCPF",	"C",	020,	0 } ) 	//"_CNPJ_CPF"
	aAdd( aStru,{ "NUM_DOC",	"C",	040,	0 } ) 	//"_NUM_DOC"
	aAdd( aStru,{ "CODITEM",	"C",	040,	0 } ) 	//"_COD_ITEM"
	aAdd( aStru,{ "VRC_DET",	"N",	018,	2 } ) 	//"_VL_REC_DET"
	aAdd( aStru,{ "CST_PIS",	"C",	002,	0 } ) 	//"_CST_PIS"	
	aAdd( aStru,{ "CST_COF",	"C",	002,	0 } ) 	//"_CST_COFINS"	
	aAdd( aStru,{ "IN_COMP",	"C",	040,	0 } ) 	//"_INFO_COMPL"	
	aAdd( aStru,{ "COD_CTA",	"C",	040,	0 } ) 	//"_COD_CTA"	
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )
	aAdd( aStrCmps,aStru )	
				
	CriaTMPReg(aStru,"RELAC3","F525",@aTrbs)
	
	aAdd( aTitulo, {}) 
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0442))	//"F525 - COMPOSIÇÃO DA RECEITA ESCRITURADA NO PERÍODO - DETALHAMENTO DA RECEITA RECEBIDA PELO REGIME DE CAIXA"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0443, cPictNUM })	//"Valor total da receita recebida, correspondente ao indicador informado no campo 03 (IND_REC)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0444, cPictChar })	//"Indicador da composição da receita recebida no período (Campo 02), por"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0250, cPictChar })	//CNPJ/CPF do participante (cliente/pessoa física ou jurídica pagadora) ou da administradora de cartões (vendas por cartão de débito ou de crédito), no caso de detalhamento da receita recebida conforme os indicadores "01" ou "02", respectivamente.
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0445, cPictChar })	//"Número do título de crédito ou do documento fiscal, no caso de detalhamento da receita recebida conforme os indicadores '03' ou '04', respectivamente"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0237, cPictChar })	//Código do item (campo 02 do Registro 0200), no caso de detalhamento da receita recebida por item vendido, conforme o indicador "05".
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0446, cPictNUM })	//"Valor da receita detalhada, correspondente ao conteúdo informado no campo 04, 05 ou 06"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0155, cPictChar })	//Código da Situação Tributária do PIS/Pasep
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0226, cPictChar })	//Código da Situação Tributária da Cofins
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0136, cPictChar })	//Informação complementar
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0447, cPictChar })	//"Código da conta analítica contábil representativa da receita recebida"	

	//REGISTRO F550: CONSOLIDAÇÃO DAS OPERAÇÕES DA PESSOA JURÍDICA SUBMETIDA AO REGIME DE TRIBUTAÇÃO COM BASE NO LUCRO PRESUMIDO  - INCIDÊNCIA DO PIS/PASEP E DA COFINS PELO REGIME DE COMPETÊNCIA	
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "VR_COMP",	"N",	014,	2 } ) 	//"_VL_REC_COMP"
	aAdd( aStru,{ "CST_PIS",	"C",	002,	0 } ) 	//"_CST_PIS"		
	aAdd( aStru,{ "VDE_PIS",	"N",	014,	2 } ) 	//"_VL_DESC_PIS"
	aAdd( aStru,{ "VBC_PIS",	"N",	014,	2 } ) 	//"_VL_BC_PIS"
	aAdd( aStru,{ "ALI_PIS",	"N",	008,	4 } ) 	//"_ALIQ_PIS"
	aAdd( aStru,{ "VL_PIS",	"N",	014,	2 } ) 	//"_VL_PIS"
	aAdd( aStru,{ "CST_COF",	"C",	002,	0 } ) 	//"_CST_COFINS"	
	aAdd( aStru,{ "VDE_COF",	"N",	014,	2 } ) 	//"_VL_DESC_COFINS"	
	aAdd( aStru,{ "VBC_COF",	"N",	014,	2 } ) 	//"_VL_BC_COFINS"	
	aAdd( aStru,{ "AL_COFI",	"N",	014,	4 } ) 	//"_ALIQ_COFINS"
	aAdd( aStru,{ "VL_COFI",	"N",	014,	2 } ) 	//"_VL_COFINS"
	aAdd( aStru,{ "COD_MOD",	"C",	002,	0 } ) 	//"_COD_MOD"
	aAdd( aStru,{ "CFOP",		"C",	004,	0 } ) 	//"_CFOP"
	aAdd( aStru,{ "COD_CTA",	"C",	060,	0 } ) 	//"_VL_BC_COFINS"				
	aAdd( aStru,{ "IN_COMP",	"C",	060,	0 } ) 	//"_VL_BC_COFINS"	
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )
	
	CriaTMPReg(aStru,"RELAC3","F550",@aTrbs)		

	aAdd( aTitulo, {}) 
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0448))	//"REGISTRO F550: CONSOLIDAÇÃO DAS OPERAÇÕES DA PESSOA JURÍDICA SUBMETIDA AO REGIME DE TRIBUTAÇÃO COM BASE NO LUCRO PRESUMIDO  - INCIDÊNCIA DO PIS/PASEP E DA COFINS PELO REGIME DE COMPETÊNCIA"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0449, cPictNUM })	//"Valor total da receita auferida, referente à combinação de CST e Alíquota"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0220, cPictChar })	//Código da Situação Tributária referente ao PIS/PASEP
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0440, cPictNUM })	//Valor do desconto / exclusão da base de cálculo
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0221, cPictNUM })	//Valor da base de cálculo do PIS/PASEP
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0222, cPictALI2 })	//Alíquota do PIS/PASEP (em percentual)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0225, cPictNUM })	//Valor do PIS/PASEP
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0226, cPictChar })	//Código da Situação Tributária referente a COFINS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0440, cPictNUM })	//Valor do desconto / exclusão da base de cálculo
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0227, cPictNUM })	//Valor da base de cálculo da COFINS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0228, cPictALI2 })	// Alíquota da COFINS (em percentual)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0231, cPictNUM })	// Valor da COFINS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0171, cPictChar })	//Código do modelo do documento fiscal conforme a Tabela 4.1.1
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0206, cPictChar })	//Código fiscal de operação e prestação
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0163, cPictChar })	//Código da conta analítica contábil debitada/creditada
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0136, cPictChar })	//Informação complementar	
	
	//REGISTRO F559: PROCESSO REFERENCIADO
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "NUM_PR",	"C",	020,	0 } ) 	//"_NUM_PROC"
	aAdd( aStru,{ "IND_PR",	"C",	001,	0 } ) 	//"_IND_PROC"
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )	
	
	CriaTMPReg(aStru,"RELAC4","F559",@aTrbs)	
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0441))	//"F519 - PROCESSO REFERENCIADO"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0138, cPictChar })	//"Identificação do processo ou ato concessório"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0139, cPictChar })	//"Origem do processo"	

	//REGISTRO F560: CONSOLIDAÇÃO DAS OPERAÇÕES DA PESSOA JURÍDICA SUBMETIDA AO REGIME DE TRIBUTAÇÃO COM BASE NO LUCRO PRESUMIDO - INCIDÊNCIA DO PIS/PASEP E DA COFINS PELO REGIME DE COMPETÊNCIA (APURAÇÃO DA CONTRIBUIÇÃO POR UNIDADE DE MEDIDA DE PRODUTO - ALÍQUOTA EM REAIS)
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "VR_COMP",	"N",	014,	2 } ) 	//"_VL_REC_COMP"
	aAdd( aStru,{ "CST_PIS",	"C",	002,	0 } ) 	//"_CST_PIS" 
	aAdd( aStru,{ "VDE_PIS",	"N",	014,	2 } )   //"_VL_DESC_PIS"		
	aAdd( aStru,{ "QBC_PIS",	"N",	014,	2 } ) 	//"_QUANT_BC_PIS"
	aAdd( aStru,{ "AP_QUAN",	"N",	014,	2 } ) 	//"_ALIQ_PIS_QUANT"	
	aAdd( aStru,{ "VL_PIS",	"N",	014,	2 } ) 	//"_VL_PIS"
	aAdd( aStru,{ "CST_COF",	"C",	002,	0 } ) 	//"_CST_COFINS"	
	aAdd( aStru,{ "VDE_COF",	"N",	014,	2 } ) 	//"_VL_DESC_COFINS"	
	aAdd( aStru,{ "QBC_COF",	"N",	014,	2 } ) 	//"_QUANT_BC_COFINS"	
	aAdd( aStru,{ "AC_QUAN",	"N",	014,	4 } ) 	//"_ALIQ_COFINS_QUANT"
	aAdd( aStru,{ "VL_COFI",	"N",	014,	2 } ) 	//"_VL_COFINS"
	aAdd( aStru,{ "COD_MOD",	"C",	002,	0 } ) 	//"_COD_MOD"
	aAdd( aStru,{ "CFOP",		"C",	004,	0 } ) 	//"_CFOP"
	aAdd( aStru,{ "COD_CTA",	"C",	060,	0 } ) 	//"_COD_CTA"				
	aAdd( aStru,{ "IN_COMP",	"C",	060,	0 } ) 	//"_INFO_COMPL"		
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )	
	
	CriaTMPReg(aStru,"RELAC3","F560",@aTrbs)		

	aAdd( aTitulo, {}) 
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0451))	//"F560 - CONSOLIDAÇÃO DAS OPERAÇÕES DA PESSOA JURÍDICA SUBMETIDA AO REGIME DE TRIBUTAÇÃO COM BASE NO LUCRO PRESUMIDO - INCIDÊNCIA DO PIS/PASEP E DA COFINS PELO REGIME DE COMPETÊNCIA (APURAÇÃO DA CONTRIBUIÇÃO POR UNIDADE DE MEDIDA DE PRODUTO - ALÍQUOTA EM REAIS)"	 
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0449, cPictNUM })	//"Valor total da receita auferida, referente à combinação de CST e Alíquota"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0220, cPictChar })	//Código da Situação Tributária referente ao PIS/PASEP
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0440, cPictNUM })	//Valor do desconto / exclusão
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0223, cPictNUM })	//Base de cálculo em quantidade - PIS/PASEP
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0224, cPictALI2 })	//Alíquota do PIS/PASEP (em reais)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0225, cPictNUM })	//Valor do PIS/PASEP
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0226, cPictChar })	//Código da Situação Tributária referente a COFINS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0440, cPictNUM })	//Valor do desconto / exclusão
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0229, cPictNUM })	//Base de cálculo em quantidade - COFINS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0230, cPictNUM })	//Alíquota da COFINS (em reais)
	//aAdd( aTitulo[Len(aTitulo)][2],{ STR0228, cPictALI2 })	// Alíquota da COFINS (em percentual)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0231, cPictNUM })	// Valor da COFINS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0171, cPictChar })	//Código do modelo do documento fiscal conforme a Tabela 4.1.1
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0206, cPictChar })	//Código fiscal de operação e prestação
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0163, cPictChar })	//Código da conta analítica contábil debitada/creditada
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0136, cPictChar })	//Informação complementar	

	//REGISTRO F569: PROCESSO REFERENCIADO
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "NUM_PR",	"C",	020,	0 } ) 	//"_NUM_PROC"
	aAdd( aStru,{ "IND_PR",	"C",	001,	0 } ) 	//"_IND_PROC"
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )	
	
	CriaTMPReg(aStru,"RELAC4","F569",@aTrbs)	
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0452))	//"F569 - PROCESSO REFERENCIADO"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0138, cPictChar })	//"Identificação do processo ou ato concessório"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0139, cPictChar })	//"Origem do processo"	
	
	//REGISTRO F600: CONTRIBUIÇÃO RETIDA NA FONTE
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "IN_RET",	"C",	002,	0 } ) 	//"_IND_NAT_RET"
	aAdd( aStru,{ "DT_RET",	"C",	008,	0 } ) 	//"_DT_RET"		
	aAdd( aStru,{ "VB_RET",	"N",	014,	2 } ) 	//"_VL_BC_RET"
	aAdd( aStru,{ "AP_QUAN",	"N",	014,	2 } ) 	//"_ALIQ_PIS_QUANT"	
	aAdd( aStru,{ "COD_REC",	"C",	004,	0 } ) 	//"_COD_REC"	
	aAdd( aStru,{ "IN_REC",	"C",	001,	0 } ) 	//"_IND_NAT_REC"	
	aAdd( aStru,{ "CNPJ",		"C",	020,	0 } ) 	//"_CNPJ"	
	aAdd( aStru,{ "VR_PIS",	"N",	014,	2 } ) 	//"_VL_RET_PIS"
	aAdd( aStru,{ "VR_COFI",	"N",	014,	2 } ) 	//"_VL_RET_COFINS"
	aAdd( aStru,{ "IND_DEC",	"C",	001,	0 } ) 	//"_COD_MOD"
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )
	aAdd( aStrCmps,aStru )	
	
	CriaTMPReg(aStru,"RELAC3","F600",@aTrbs)		

	aAdd( aTitulo, {}) 
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0453))	//"F600 - CONTRIBUIÇÃO RETIDA NA FONTE"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0454, cPictChar })	//"Indicador de Natureza da Retenção na Fonte"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0455, cPictChar })	//"Data da Retenção"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0456, cPictNUM })	//"Base de calculo da retenção ou do recolhimento (sociedade cooperativa)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0457, cPictNUM })	//"Valor Total Retido na Fonte / Recolhido (sociedade cooperativa)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0458, cPictChar })	//"Código da Receita"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0459, cPictChar })	//"Indicador da Natureza da Receita"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0024, cPictCNPJ })	//CNPJ
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0460, cPictNUM })	//"Valor Retido na Fonte - Parcela Referente ao PIS/Pasep"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0461, cPictNUM })	//"Valor Retido na Fonte - Parcela Referente a COFINS"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0462, cPictChar })	//"Indicador da condição da pessoa jurídica declarante"
	
	IncProc("Gerando estrutura...")
	
	//REGISTRO F700: DEDUÇÕES DIVERSAS
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "IO_DED",	"C",	002,	0 } ) 	//"_IND_ORI_DED"
	aAdd( aStru,{ "IN_DED",	"C",	001,	0 } ) 	//"_IND_NAT_DED"		
	aAdd( aStru,{ "VD_PIS",	"N",	014,	2 } ) 	//"_VL_DED_PIS"
	aAdd( aStru,{ "VD_COF",	"N",	014,	2 } ) 	//"_VL_DED_COFINS"	
	aAdd( aStru,{ "VB_OPER",	"N",	014,	2 } ) 	//"_VL_BC_OPER"
	aAdd( aStru,{ "CNPJ",		"C",	020,	0 } ) 	//"_CNPJ"	
	aAdd( aStru,{ "INF_COM",	"C",	090,	0 } ) 	//"_IND_NAT_REC"	
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )
	aAdd( aStrCmps,aStru )
	
	CriaTMPReg(aStru,"RELAC3","F700",@aTrbs)		

	aAdd( aTitulo, {}) 
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0463))	//"F700 - DEDUÇÕES DIVERSAS"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0464, cPictChar })	//"Indicador de Origem de Deduções Diversas"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0465, cPictChar })	//"Indicador da Natureza da Dedução"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0466, cPictNUM })	//"Valor a Deduzir - PIS/PASEP"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0467, cPictNUM })	//"Valor a Deduzir - Cofins"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0468, cPictNUM })	//"Valor da Base de Cálculo da Operação que ensejou o Valor a Deduzir informado nos Campos 04 e 05"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0024, cPictCNPJ })	//CNPJ
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0136, cPictChar })	//Informações Complementares do Documento/Operação que ensejou o Valor a Deduzir informado nos Campos 04 e 05.

	//REGISTRO F800: CRÉDITOS DECORRENTES DE EVENTOS DE INCORPORAÇÃO, FUSÃO E CISÃO
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "IN_EVEN",	"C",	002,	0 } ) 	//"_IND_NAT_EVEN"
	aAdd( aStru,{ "DT_EVEN",	"C",	008,	0 } ) 	//"_DT_EVEN"		
	aAdd( aStru,{ "CNPJSUC",	"C",	020,	0 } ) 	//"_CNPJ_SUCED"
	aAdd( aStru,{ "PC_CRED",	"C",	006,	0 } ) 	//"_PA_CONT_CRED"	
	aAdd( aStru,{ "CO_CRED",	"C",	003,	0 } ) 	//"_COD_CRED"
	aAdd( aStru,{ "VCD_PIS",	"N",	014,	2 } ) 	//"_VL_CRED_PIS"	
	aAdd( aStru,{ "VCR_COF",	"N",	014,	2 } ) 	//"_VL_CRED_COFINS"	
	aAdd( aStru,{ "PCR_CIS",	"N",	006,	2 } ) 	//"_PER_CRED_CIS"
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )
	aAdd( aStrCmps,aStru )	
	
	CriaTMPReg(aStru,"RELAC3","F800",@aTrbs)	
	
	aAdd( aTitulo, {}) 
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0469))	//"F800 - CRÉDITOS DECORRENTES DE EVENTOS DE INCORPORAÇÃO, FUSÃO E CISÃO"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0470, cPictChar })	//"Indicador da Natureza do Evento de Sucessão"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0471, cPictChar })	//"Data do Evento"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0024, cPictCNPJ })	//CNPJ da Pessoa Jurídica Sucedida
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0472, cPictChar })	//"Período de Apuração do Crédito - Mês/Ano (MM/AAAA)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0473, cPictChar })	//"Código do crédito transferido, conforme Tabela 4.3.6"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0474, cPictNUM })	//"Valor do Crédito Transferido de PIS/Pasep"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0475, cPictNUM })	//"Valor do Crédito Transferido de Cofins"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0476, cPictALI1 })	//"Percentual do crédito original transferido, no caso de evento de Cisão"
	
	//REGISTRO F990: ENCERRAMENTO DO BLOCO F	
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) //"_REG"
	aAdd( aStru,{ "Q_LIN0",	"N",	010,	0 } ) //"_QTD_LIN_0"	
	aAdd( aStru,{ "RELAC",		"C",	010,	0 } )
	aAdd( aStrCmps,aStru )
	
	CriaTMPReg(aStru,"RELAC","F990",@aTrbs)	
		
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0477))	//"F990 - ENCERRAMENTO DO BLOCO F"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0478, cPictChar })	//"Quantidade total de linhas do Bloco F"
		
	//REGISTRO I001: ABERTURA DO BLOCO I
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) //"_REG"
	aAdd( aStru,{ "IND_MO",		"C",	003,	0 } ) //"_IND_MOV"
	aAdd( aStru,{ "RELAC",		"C",	010,	0 } )
	aAdd( aStru,{ "RELAC2",		"C",	010,	0 } )
	aAdd( aStrCmps,aStru )
	
	CriaTMPReg(aStru,"RELAC","I001",@aTrbs)	
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0778))	//"I001 - ABERTURA DO BLOCO I"	 
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0031, cPictChar })	//"Movimento"	
	
	//REGISTRO I010: IDENTIFICAÇÃO DA PESSOA JURIDICA/ESTABELECIMENTO
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) //"_REG"
	aAdd( aStru,{ "CNPJ",		"C",	014,	0 } ) //"_CNPJ"	
	aAdd( aStru,{ "IND_ATV",	"C",	002,	0 } ) //"_IND_ATIV"
	aAdd( aStru,{ "INF_COM",	"C",	060,	2 } ) //"_INFO_COMPL"
	aAdd( aStru,{ "RELAC2",		"C",	010,	0 } )
	aAdd( aStru,{ "RELAC3",		"C",	010,	0 } )
	aAdd( aStrCmps,aStru )

	CriaTMPReg(aStru,"RELAC2","I010",@aTrbs)	
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0779))	//"I010 - IDENTIFICAÇÃO DA PESSOA JURIDICA/ESTABELECIMENTO"	  	 
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0024, cPictChar })	//"CNPJ"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0764, cPictChar })	//"Indicador de operações realizadas no período"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0483, cPictChar })	//"Informação Complementar"		

	//REGISTRO I100: CONSOLIDAÇÃO DAS OPERAÇÕES DO PERÍODO
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) //"_REG"
	aAdd( aStru,{ "VL_REC",		"N",	018,	2 } ) //"_VL_REC"	
	aAdd( aStru,{ "CST_PIS",	"C",	002,	0 } ) //"_CST_PIS_COFINS"
	aAdd( aStru,{ "VL_TDG",		"N",	014,	2 } ) //"_VL_TOT_DED_GER"
	aAdd( aStru,{ "VL_TDE",		"N",	014,	2 } ) //"_VL_TOT_DED_ESP"
	aAdd( aStru,{ "VBC_PIS",	"N",	014,	2 } ) //"_VL_BC_PIS"
	aAdd( aStru,{ "ALQ_PIS",	"N",	008,	2 } ) //"_ALIQ_PIS"
	aAdd( aStru,{ "VL_PIS",		"N",	014,	2 } ) //"_VL_PIS"
	aAdd( aStru,{ "VBC_COF",	"N",	014,	2 } ) //"_VL_BC_COFINS"
	aAdd( aStru,{ "ALQ_COF",	"N",	008,	2 } ) //"_ALIQ_COFINS"
	aAdd( aStru,{ "VL_COF",		"N",	014,	2 } ) //"_VL_COFINS"
	aAdd( aStru,{ "INF_COM",	"C",	050,	2 } ) //"_INFO_COMPL"
	aAdd( aStru,{ "RELAC3",		"C",	010,	0 } )
	aAdd( aStru,{ "RELAC4",		"C",	010,	0 } )
	aAdd( aStrCmps,aStru )	

	CriaTMPReg(aStru,"RELAC3","I100",@aTrbs)	

	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0780))	//"I100 - CONSOLIDAÇÃO DAS OPERAÇÕES DO PERÍODO"	 
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0787, cPictNUM3 })	//"Total Faturamento/Rec. Bruta no Período"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0765, cPictChar })	//"Situação Tributária"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0766, cPictNUM3 })	//"Total das Deduções e Exclusões Geral"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0767, cPictNUM3 })	//"Total das Deduções e Exclusões Específicos"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0768, cPictNUM3 })	//"Base de cálculo do PIS/PASEP"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0769, cPictALI2 })	//"Alíq. PIS/PASEP"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0770, cPictNUM })	//"Vlr PIS/PASEP"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0771, cPictNUM3 })	//"Base de cálculo da Cofins "
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0772, cPictALI2 })	//"Alíq. COFINS"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0773, cPictNUM })	//"Vlr COFINS"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0483, cPictChar })	//"Informação Complementar"

	//REGISTRO I199: PROCESSO REFERENCIADO
		
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "NUM_PRO",	"C",	020,	0 } ) 	//"_NUM_PROC"
	aAdd( aStru,{ "IND_PRO",	"C",	001,	0 } ) 	//"_IND_PROC"
	aAdd( aStru,{ "RELAC4",		"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )	
	
	CriaTMPReg(aStru,"RELAC4","I199",@aTrbs)	
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0781))	//"I199 - PROCESSO REFERENCIADO"	 
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0138, cPictChar })	//"Identificação do processo ou ato concessório"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0139, cPictChar })	//"Origem do processo"	
	
	//REGISTRO I200: COMPOSIÇÃO DAS RECEITAS, DEDUÇÕES E/OU EXCLUSÕES DO PERÍODO
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "NUM_CPO",	"C",	002,	0 } ) 	//"_NUM_CAMPO"
	aAdd( aStru,{ "COD_DET",	"C",	005,	0 } ) 	//"_COD_DET"
	aAdd( aStru,{ "DET_VAL",	"N",	018,	2 } ) 	//"_DET_VALOR"
	aAdd( aStru,{ "COD_CTA",	"C",	060,	0 } ) 	//"_COD_CTA"
	aAdd( aStru,{ "INF_COM",	"C",	060,	0 } ) 	//"_INFO_COMPL"
	aAdd( aStru,{ "RELAC4",		"C",	010,	0 } )	
	aAdd( aStru,{ "RELAC5",		"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )	

	CriaTMPReg(aStru,"RELAC4","I200",@aTrbs)	
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0782))	//"I200 - COMPOSIÇÃO DAS RECEITAS, DEDUÇÕES E/OU EXCLUSÕES DO PERÍODO"	 
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0774, cPictChar })	//"Número do campo do reg. I100"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0775, cPictChar })	//"Cód. do tipo de detalhamento"	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0776, cPictNUM3 })	//"Valor detalhado"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0777, cPictChar })	//"Cód. da cta contábil"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0139, cPictChar })	//"Informação Complementar"	

	//REGISTRO I299: PROCESSO REFERENCIADO
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "NUM_PRO",	"C",	020,	0 } ) 	//"_NUM_PROC"
	aAdd( aStru,{ "IND_PRO",	"C",	001,	0 } ) 	//"_IND_PROC"
	aAdd( aStru,{ "RELAC5",		"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )	
	
	CriaTMPReg(aStru,"RELAC5","I299",@aTrbs)
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0783))	//"I299 - PROCESSO REFERENCIADO"	 
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0138, cPictChar })	//"Identificação do processo ou ato concessório"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0139, cPictChar })	//"Origem do processo"	

	//REGISTRO I300: COMPLEMENTO DAS OPERAÇÕES – DETALHAMENTO DAS RECEITAS, DEDUÇÕES E/OU EXCLUSÕES DO PERÍODO
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "COD_COM",	"C",	060,	0 } ) 	//"_COD_COMP"
	aAdd( aStru,{ "DET_VAL",	"N",	018,	2 } ) 	//"_DET_VALOR"
	aAdd( aStru,{ "COD_CTA",	"C",	060,	0 } ) 	//"_COD_CTA"
	aAdd( aStru,{ "INF_COM",	"C",	060,	0 } ) 	//"_INFO_COMPL"
	aAdd( aStru,{ "RELAC5",	"C",	010,	0 } )	
	aAdd( aStru,{ "RELAC6",	"C",	010,	0 } )
	aAdd( aStrCmps,aStru )	
	
	CriaTMPReg(aStru,"RELAC5","I300",@aTrbs)	
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0784))	//"I300 - COMPLEMENTO DAS OPERAÇÕES – DETALHAMENTO DAS RECEITAS, DEDUÇÕES E/OU EXCLUSÕES DO PERÍODO"	 
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0775, cPictChar })	//"Tipo de detalhamento"	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0776, cPictNUM3 })	//"Valor detalhado"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0777, cPictChar })	//"Cód. da conta contábil "
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0139, cPictChar })	//"Informação Complementar"	

	//REGISTRO I399: PROCESSO REFERENCIADO
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "NUM_PRO",	"C",	020,	0 } ) 	//"_NUM_PROC"
	aAdd( aStru,{ "IND_PRO",	"C",	001,	0 } ) 	//"_IND_PROC"
	aAdd( aStru,{ "RELAC6",		"C",	010,	0 } )
	aAdd( aStrCmps,aStru )	
	
	CriaTMPReg(aStru,"RELAC6","I399",@aTrbs)	
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0785))	//"I399 - PROCESSO REFERENCIADO"	 
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0138, cPictChar })	//"Identificação do processo ou ato concessório"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0139, cPictChar })	//"Origem do processo"
		
	//REGISTRO I990: ENCERRAMENTO DO BLOCO I
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) //"_REG"
	aAdd( aStru,{ "Q_LIN0",		"N",	010,	0 } ) //"_QTD_LIN_0"	
	aAdd( aStru,{ "RELAC",		"C",	010,	0 } )
	aAdd( aStrCmps,aStru )
	
	CriaTMPReg(aStru,"RELAC","I990",@aTrbs)	
		
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0786))	//"I990 - ENCERRAMENTO DO BLOCO I"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0788, cPictChar })	//"Quantidade total de linhas do Bloco I"
	
			
	//REGISTRO M001: ABERTURA DO BLOCO M
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) //"_REG"
	aAdd( aStru,{ "IND_MO",	"C",	003,	0 } ) //"_IND_MOV"
	aAdd( aStru,{ "RELAC",		"C",	010,	0 } )
	aAdd( aStru,{ "RELAC2",	"C",	010,	0 } )
	aAdd( aStrCmps,aStru )
	
	CriaTMPReg(aStru,"RELAC","M001",@aTrbs)	
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0479))	//"M001 - ABERTURA DO BLOCO M"	 
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0031, cPictChar })	//"Movimento"	
	
	//REGISTRO M100: CRÉDITO DE PIS/PASEP RELATIVO AO PERÍODO
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) //"_REG"
	aAdd( aStru,{ "CO_CRED",	"C",	003,	0 } ) //"_COD_CRED"	
	aAdd( aStru,{ "ICR_ORI",	"C",	001,	0 } ) //"_IND_CRED_ORI"
	aAdd( aStru,{ "VBC_PIS",	"N",	018,	2 } ) //"_VL_BC_PIS"
	aAdd( aStru,{ "ALI_PIS",	"N",	008,	4 } ) //"_ALIQ_PIS"
	aAdd( aStru,{ "QBC_PIS",	"N",	014,	2 } ) //"_QUANT_BC_PIS"
	aAdd( aStru,{ "AP_QUAN",	"N",	008,	4 } ) //"_ALIQ_PIS_QUANT"
	aAdd( aStru,{ "VL_CRED",	"N",	014,	2 } ) //"_VL_CRED"
	aAdd( aStru,{ "VA_ACRE",	"N",	014,	2 } ) //"_VL_AJUS_ACRES"
	aAdd( aStru,{ "VA_REDU",	"N",	014,	2 } ) //"_VL_AJUS_REDUC"
	aAdd( aStru,{ "VCR_DIF",	"N",	014,	2 } ) //"_VL_CRED_DIF"
	aAdd( aStru,{ "VC_DISP",	"N",	014,	2 } ) //"_VL_CRED_DISP"
	aAdd( aStru,{ "ID_CRED",	"C",	001,	0 } ) //"_IND_DESC_CRED"
	aAdd( aStru,{ "VC_DESC",	"N",	014,	2 } ) //"_VL_CRED_DESC"
	aAdd( aStru,{ "SLD_CRE",	"N",	014,	2 } ) //"_SLD_CRED"	
	aAdd( aStru,{ "RELAC2",	"C",	010,	0 } )
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )
	aAdd( aStrCmps,aStru )	

	CriaTMPReg(aStru,"RELAC2","M100",@aTrbs)	
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0480))	//"M100 - CRÉDITO DE PIS/PASEP RELATIVO AO PERÍODO"	  	 
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0481, cPictChar })	//"Código de Tipo de Crédito apurado no período, conforme a Tabela 4.3.6."
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0482, cPictChar })	//"Indicador de Crédito Oriundo"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0483, cPictNUM3 })	//"Valor da Base de Cálculo do Crédito"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0222, cPictALI2 })	//Alíquota do PIS/PASEP (em percentual)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0223, cPictNUM })	//Quantidade - Base de cálculo PIS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0224, cPictALI2 })	//Alíquota do PIS (em reais)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0484, cPictNUM })	//"Valor total do crédito apurado no período"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0485, cPictNUM })	//"Valor total dos ajustes de acréscimo"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0486, cPictNUM })	//"Valor total dos ajustes de redução"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0487, cPictNUM })	//"Valor total do crédito diferido no período"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0488, cPictNUM })	//"Valor Total do Crédito Disponível relativo ao Período (08 + 09 - 10 - 11)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0489, cPictChar })	//"Indicador de opção de utilização do crédito disponível no período"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0490, cPictNUM })	//"Valor do Crédito disponível, descontado  da contribuição apurada no próprio período"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0491, cPictNUM })	//"Saldo de créditos a utilizar em períodos futuros (12 - 14)"
	
	//REGISTRO M105: DETALHAMENTO DA BASE DE CALCULO DO CRÉDITO APURADO NO PERÍODO - PIS/PASEP
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) //"_REG"
	aAdd( aStru,{ "NB_CRED",	"C",	002,	0 } ) //"_NAT_BC_CRED"	
	aAdd( aStru,{ "CST_PIS",	"C",	002,	0 } ) //"_CST_PIS"
	aAdd( aStru,{ "VBP_TOT",	"N",	018,	2 } ) //"_VL_BC_PIS_TOT"
	aAdd( aStru,{ "VBP_CUM",	"N",	018,	2 } ) //"_VL_BC_PIS_CUM"
	aAdd( aStru,{ "VBPI_NC",	"N",	018,	2 } ) //"_VL_BC_PIS_NC"
	aAdd( aStru,{ "VBC_PIS",	"N",	018,	2 } ) //"_VL_BC_PIS"
	aAdd( aStru,{ "QBP_TOT",	"N",	014,	3 } ) //"_QUANT_BC_PIS_TOT"
	aAdd( aStru,{ "QBC_PIS",	"N",	014,	3 } ) //"_QUANT_BC_PIS"
	aAdd( aStru,{ "DE_CRED",	"C",	080,	2 } ) //"_DESC_CRED"
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )
	aAdd( aStrCmps,aStru )	

	CriaTMPReg(aStru,"RELAC3","M105",@aTrbs)	

	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0492))	//"M105 - DETALHAMENTO DA BASE DE CALCULO DO CRÉDITO APURADO NO PERÍODO - PIS/PASEP"	 
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0493, cPictChar })	//"Código da Base de Cálculo do Crédito apurado no período, conforme a Tabela 4.3.7."
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0494, cPictChar })	//"Código da Situação Tributária referente ao crédito de PIS/Pasep (Tabela 4.3.3) vinculado ao tipo de crédito escriturado em M100."
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0495, cPictNUM3 })	//"Valor Total da Base de Cálculo escriturada nos documentos e operações (Blocos 'A', 'C', 'D' e 'F'), referente ao CST_PIS informado no Campo 03"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0496, cPictNUM3 })	//"Parcela do Valor Total da Base de Cálculo informada no Campo 04, vinculada a receitas com incidência cumulativa"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0497, cPictNUM3 })	//"Campo de preenchimento específico para a pessoa jurídica sujeita ao regime cumulativo e não-cumulativo da contribuição (COD_INC_TRIB = 3 do Registro 0110)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0498, cPictNUM3 })	//"Valor Total da Base de Cálculo do Crédito, vinculada a receitas com incidência não-cumulativa (Campo 04 - Campo 05)."
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0499, cPictNUM })	//"Valor da Base de Cálculo do Crédito, vinculada ao tipo de Crédito escriturado em M100."
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0500, cPictNUM2 })	//"Quantidade Total da Base de Cálculo do Crédito apurado em Unidade de Medida de Produto, escriturada nos documentos e operações (Blocos 'A', 'C', 'D' e 'F'), referente ao CST_PIS informado no Campo 03"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0501, cPictChar })	//"Parcela da base de cálculo do crédito em quantidade (campo 08) vinculada ao tipo de crédito escriturado em M100."
   //	aAdd( aTitulo[Len(aTitulo)][2],{ STR0502, cPictChar })	//"Descrição do crédito"	

	//REGISTRO M110: AJUSTES DO CRÉDITO DE PIS/PASEP APURADO
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) //"_REG"
	aAdd( aStru,{ "IND_AJ",	"C",	001,	0 } ) //"_IND_AJ"	
	aAdd( aStru,{ "VL_AJ",		"N",	014,	2 } ) //"_VL_AJ"
	aAdd( aStru,{ "COD_AJ",	"C",	002,	0 } ) //"_COD_AJ"
	aAdd( aStru,{ "NUM_DOC",	"C",	030,	0 } ) //"_NUM_DOC"
	aAdd( aStru,{ "DESCR_A",	"C",	150,	0 } ) //"_DESCR_AJ"
	aAdd( aStru,{ "DT_REF",	"C",	008,	0 } ) //"_DT_REF"
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )
	aAdd( aStrCmps,aStru )	

	CriaTMPReg(aStru,"RELAC3","M110",@aTrbs)	
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0503))	//"M110 - AJUSTES DO CRÉDITO DE PIS/PASEP APURADO"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0504, cPictChar })	//"Indicador do tipo de ajuste"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0505, cPictNUM })	//"Valor do ajuste"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0506, cPictChar })	//"Código do ajuste, conforme a Tabela indicada no item 4.3.8."
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0507, cPictChar })	//"Número do processo, documento ou ato concessório ao qual o ajuste está vinculado, se houver"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0508, cPictChar })	//"Descrição resumida do ajuste"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0509, cPictChar })	//"Data de referência do ajuste (ddmmaaaa)"
	
	//REGISTRO M200: CONSOLIDAÇÃO DA CONTRIBUIÇÃO PARA O PIS/PASEP DO PERÍODO
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) //"_REG"
	aAdd( aStru,{ "VTCNPER",	"N",	014,	2 } ) //"_VL_TOT_CONT_NC_PER"	
	aAdd( aStru,{ "VTCDESC",	"N",	014,	2 } ) //"_VL_TOT_CRED_DESC"
	aAdd( aStru,{ "VTCDANT",	"N",	014,	2 } ) //"_VL_TOT_CRED_DESC_ANT"
	aAdd( aStru,{ "VTCNDEV",	"N",	014,	2 } ) //"_VL_TOT_CONT_NC_DEV"
	aAdd( aStru,{ "VRET_NC",	"N",	014,	2 } ) //"_VL_RET_NC"
	aAdd( aStru,{ "VODE_NC",	"N",	014,	2 } ) //"_VL_OUT_DED_NC"
	aAdd( aStru,{ "VCNCREC",	"N",	014,	2 } ) //"_VL_CONT_NC_REC"
	aAdd( aStru,{ "VTCCPER",	"N",	014,	2 } ) //"_VL_TOT_CONT_CUM_PER"
	aAdd( aStru,{ "VRE_CUM",	"N",	014,	2 } ) //"_VL_RET_CUM"
	aAdd( aStru,{ "VOD_CUM",	"N",	014,	2 } ) //"_VL_OUT_DED_CUM"
	aAdd( aStru,{ "VCC_REC",	"N",	014,	2 } ) //"_VL_CONT_CUM_REC"
	aAdd( aStru,{ "VTC_REC",	"N",	014,	2 } ) //"_IND_DESC_CRED"
	aAdd( aStru,{ "RELAC2",	"C",	010,	0 } )
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )	

	CriaTMPReg(aStru,"RELAC2","M200",@aTrbs)		

	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0510))	//"M200 - CONSOLIDAÇÃO DA CONTRIBUIÇÃO PARA O PIS/PASEP DO PERÍODO"	  	 
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0511, cPictNUM })	//"Valor Total da Contribuição Não Cumulativa do Período (recuperado do campo 13 do Registro M210, quando o campo 'COD_CONT' = 01, 02, 03, 04, 32 e 71)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0512, cPictNUM })	//"Valor do Crédito Descontado, Apurado no Próprio Período da Escrituração (recuperado do campo 14 do Registro M100)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0513, cPictNUM })	//"Valor do Crédito Descontado, Apurado em Período de Apuração Anterior (recuperado do campo 13 do Registro 1100)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0514, cPictNUM })	//"Valor Total da Contribuição Não Cumulativa Devida (02 - 03 - 04)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0515, cPictNUM })	//"Valor Retido na Fonte Deduzido no Período"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0516, cPictNUM })	//"Outras Deduções no Período"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0517, cPictNUM })	//"Valor da Contribuição Não Cumulativa a Recolher/Pagar (05 - 06 - 07)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0518, cPictNUM })	//"Valor Total da Contribuição Cumulativa do Período  (recuperado do campo 13 do Registro M210, quando o campo 'COD_CONT' = 31, 32, 51, 52, 53, 54 e 72)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0519, cPictNUM })	//"Valor Retido na Fonte Deduzido no Período"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0516, cPictNUM })	//Outras Deduções no Período
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0520, cPictNUM })	//"Valor da Contribuição Cumulativa a Recolher/Pagar (09 - 10 - 11)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0521, cPictNUM })	//"Valor Total da Contribuição a Recolher/Pagar no Período (08 + 12)"

	//REGISTRO M210: DETALHAMENTO DA CONTRIBUIÇÃO PARA O PIS/PASEP DO PERÍODO
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) //"_REG"
	aAdd( aStru,{ "CO_CONT",	"C",	002,	0 } ) //"_COD_CONT"	
	aAdd( aStru,{ "VRE_BRT",	"N",	018,	2 } ) //"_VL_REC_BRT"
	aAdd( aStru,{ "VB_CONT",	"N",	018,	2 } ) //"_VL_BC_CONT"
	aAdd( aStru,{ "ALI_PIS",	"N",	008,	4 } ) //"_ALIQ_PIS"
	aAdd( aStru,{ "QTBCPIS",	"N",	014,	2 } ) //"_QUANT_BC_PIS"
	aAdd( aStru,{ "AP_QUAN",	"N",	014,	2 } ) //"_ALIQ_PIS_QUANT"
	aAdd( aStru,{ "VC_APUR",	"N",	014,	2 } ) //"_VL_CONT_APUR"
	aAdd( aStru,{ "VAACRES",	"N",	014,	2 } ) //"_VL_AJUS_ACRES"
	aAdd( aStru,{ "VAREDUC",	"N",	014,	2 } ) //"_VL_AJUS_REDUC"
	aAdd( aStru,{ "VCDIFER",	"N",	014,	2 } ) //"_VL_CONT_DIFER"
	aAdd( aStru,{ "VCD_ANT",	"N",	014,	2 } ) //"_VL_CONT_DIFER_ANT"
	aAdd( aStru,{ "VCT_PER",	"N",	014,	2 } ) //"_IND_DESC_CRED"
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )	
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )		
	aAdd( aStrCmps,aStru )	

	CriaTMPReg(aStru,"RELAC3","M210",@aTrbs)	

	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0522))	//"M210 - DETALHAMENTO DA CONTRIBUIÇÃO PARA O PIS/PASEP DO PERÍODO"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0523, cPictChar })	//"Código da contribuição social apurada no período, conforme a Tabela 4.3.5."
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0524, cPictNUM3 })	//"Valor da Receita Bruta"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0525, cPictNUM3 })	//"Valor da Base de Cálculo da Contribuição"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0372, cPictNUM })	//Alíquota do PIS/PASEP (em percentual)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0223, cPictNUM })	//Quantidade - Base de cálculo PIS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0224, cPictNUM })	//Alíquota do PIS (em reais)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0526, cPictNUM })	//"Valor total da contribuição social apurada"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0527, cPictNUM })	//"Valor total dos ajustes de acréscimo"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0528, cPictNUM })	//"Valor total dos ajustes de redução"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0529, cPictNUM })	//"Valor da contribuição a diferir no período"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0530, cPictNUM })	//"Valor da contribuição diferida em períodos anteriores"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0531, cPictNUM })	//"Valor Total da Contribuição do Período (08 + 09 - 10 - 11+12)"
	
	//REGISTRO M211: SOCIEDADES COOPERATIVAS - COMPOSIÇÃO DA BASE DE CALCULO - PIS/PASEP
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) //"_REG"
	aAdd( aStru,{ "IT_COOP",	"C",	002,	0 } ) //"_IND_TIP_COOP"	
	aAdd( aStru,{ "VBCAECP",	"N",	014,	2 } ) //"_VL_BC_CONT_ANT_EXC_COOP"
	aAdd( aStru,{ "VECPGER",	"N",	014,	2 } ) //"_VL_EXC_COOP_GER"
	aAdd( aStru,{ "VEECOOP",	"N",	014,	2 } ) //"_VL_EXC_ESP_COOP"
	aAdd( aStru,{ "VB_CONT",	"N",	014,	2 } ) //"_VL_BC_CONT"
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )	
	
	CriaTMPReg(aStru,"RELAC4","M211",@aTrbs)	

	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0532))	//"M211 - SOCIEDADES COOPERATIVAS - COMPOSIÇÃO DA BASE DE CALCULO - PIS/PASEP"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0533, cPictChar })	//"Indicador do Tipo de Sociedade Cooperativa"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0526, cPictNUM })	//Valor da Base de Cálculo da Contribuição, conforme Registros escriturados nos Blocos A, C, D e F, antes das Exclusões das Cooperativas.
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0534, cPictNUM })	//"Valor de Exclusão Especifica das Cooperativas em Geral, decorrente das Sobras Apuradas na DRE, destinadas a constituição do Fundo de Reserva e do FATES"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0535, cPictNUM })	//"Valor das Exclusões da Base de Cálculo Especifica do Tipo da Sociedade Cooperativa, conforme Campo 02 (IND_TIP_COOP)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0536, cPictNUM })	//"Valor da Base de Cálculo, Após as Exclusões Especificas da Sociedade Cooperativa (04 - 05 - 06) - Transportar para M210"	

	//REGISTRO M220: AJUSTES DA CONTRIBUIÇÃO PARA O PIS/PASEP APURADA
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) //"_REG"
	aAdd( aStru,{ "IND_AJ",	"C",	001,	0 } ) //"_IND_AJ"	
	aAdd( aStru,{ "VL_AJ",		"N",	014,	2 } ) //"_VL_AJ"
	aAdd( aStru,{ "COD_AJ",	"C",	002,	0 } ) //"_COD_AJ"
	aAdd( aStru,{ "NUM_DOC",	"C",	060,	0 } ) //"_NUM_DOC"
	aAdd( aStru,{ "DESCR_A",	"C",	060,	0 } ) //"_DESCR_AJ"
	aAdd( aStru,{ "DT_REF",	"C",	008,	0 } ) //"_DT_REF"
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )
	aAdd( aStrCmps,aStru )	

	CriaTMPReg(aStru,"RELAC4","M220",@aTrbs)		

	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0537))	//"M220 - AJUSTES DA CONTRIBUIÇÃO PARA O PIS/PASEP APURADA"	 
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0504, cPictChar })	//"Indicador do tipo de ajuste"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0505, cPictNUM })	//"Valor do ajuste"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0506, cPictChar })	//"Código do ajuste, conforme a Tabela indicada no item 4.3.8."
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0507, cPictChar })	//"Número do processo, documento ou ato concessório ao qual o ajuste está vinculado, se houver"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0508, cPictChar })	//"Descrição resumida do ajuste"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0509, cPictChar })	//"Data de referência do ajuste (ddmmaaaa)"	

	//REGISTRO M230: INFORMAÇÕES ADICIONAIS DE DIFERIMENTO
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) //"_REG"
	aAdd( aStru,{ "CNPJ",		"C",	020,	0 } ) //"_IND_AJ"	
	aAdd( aStru,{ "VL_VEND",	"N",	014,	2 } ) //"_VL_AJ"
	aAdd( aStru,{ "VN_RECE",	"N",	014,	2 } ) //"_COD_AJ"
	aAdd( aStru,{ "VCO_DIF",	"N",	014,	2 } ) //"_NUM_DOC"
	aAdd( aStru,{ "VCD_DIF",	"N",	014,	2 } ) //"_DESCR_AJ"
	aAdd( aStru,{ "CO_CRED",	"C",	003,	0 } ) //"_DT_REF"
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )
	aAdd( aStrCmps,aStru )	

	CriaTMPReg(aStru,"RELAC4","M230",@aTrbs)	

	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0538))	//"M230 - INFORMAÇÕES ADICIONAIS DE DIFERIMENTO"	 
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0024, cPictCNPJ })	//CNPJ da pessoa jurídica de direito público, empresa pública, sociedade de economia mista ou suas subsidiárias.
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0539, cPictNUM })	//"Valor Total das vendas no período"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0540, cPictNUM })	//"Valor Total não recebido no período"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0541, cPictNUM })	//"Valor da Contribuição diferida no período"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0542, cPictNUM })	//"Valor do Crédito diferido no período"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0543, cPictChar })	//"Código de Tipo de Crédito diferido no período, conforme a Tabela 4.3.6."	

	//REGISTRO M300: CONTRIBUIÇÃO DE PIS/PASEP DIFERIDA EM PERÍODOS ANTERIORES - VALORES A PAGAR NO PERÍODO
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) //"_REG"
	aAdd( aStru,{ "CO_CONT",	"C",	002,	0 } ) //"_COD_CONT"	
	aAdd( aStru,{ "VCADIFE",	"N",	014,	2 } ) //"_VL_CONT_APUR_DIFER"
	aAdd( aStru,{ "NC_DESC",	"C",	002,	0 } ) //"_NAT_CRED_DESC"
	aAdd( aStru,{ "VCDDIFE",	"N",	014,	2 } ) //"_VL_CRED_DESC_DIFER"
	aAdd( aStru,{ "VCD_ANT",	"N",	014,	2 } ) //"_VL_CONT_DIFER_ANT"
	aAdd( aStru,{ "DT_RECE",	"C",	008,	0 } ) //"_DT_RECEB"
	aAdd( aStru,{ "RELAC2",	"C",	010,	0 } )
	aAdd( aStrCmps,aStru )

	CriaTMPReg(aStru,"RELAC2","M300",@aTrbs)	

	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0544))	//"M300 - CONTRIBUIÇÃO DE PIS/PASEP DIFERIDA EM PERÍODOS ANTERIORES - VALORES A PAGAR NO PERÍODO"	 	 
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0545, cPictChar })	//"Código da contribuição social diferida em períodos anteriores, conforme a Tabela 4.3.5."
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0546, cPictNUM })	//"Valor da Contribuição Apurada, diferida em períodos anteriores"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0547, cPictChar })	//"Natureza do Crédito Diferido, vinculado à receita tributada no mercado interno, a descontar"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0548, cPictNUM })	//"Valor do Crédito a Descontar vinculado à contribuição diferida"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0549, cPictNUM })	//"Valor da Contribuição a Recolher, diferida em períodos anteriores (Campo 03 - Campo 05)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0550, cPictChar })	//"Período de apuração da contribuição social e dos créditos diferidos (MMAAAA)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0551, cPictChar })	//"Data de recebimento da receita, objeto de diferimento" 

	//REGISTRO M350: PIS/PASEP - FOLHA DE SALÁRIOS	
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) //"_REG"
	aAdd( aStru,{ "VTOTFOL",	"N",	014,	2 } ) //"_VL_TOT_FOL"	
	aAdd( aStru,{ "VEXC_BC",	"N",	014,	2 } ) //"_VL_EXC_BC"
	aAdd( aStru,{ "VLTOTBC",	"N",	014,	2 } ) //"_VL_TOT_BC"
	aAdd( aStru,{ "APISFOL",	"N",	008,	4 } ) //"_ALIQ_PIS_FOL"
	aAdd( aStru,{ "VTCOFOL",	"N",	014,	2 } ) //"_VL_TOT_CONT_FOL"
	aAdd( aStru,{ "RELAC2",	"C",	010,	0 } )
	aAdd( aStrCmps,aStru )

	CriaTMPReg(aStru,"RELAC2","M350",@aTrbs)	

	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0552))	//"M350 - PIS/PASEP - FOLHA DE SALÁRIOS"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0553, cPictNUM })	//"Valor Total da Folha de Salários"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0554, cPictNUM })	//"Valor Total das Exclusões à Base de Cálculo"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0555, cPictNUM })	//"Valor Total da Base de Cálculo"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0556, cPictALI2 })	//"Alíquota do PIS/PASEP - Folha de Salários"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0557, cPictNUM })	//"Valor Total da Contribuição Social sobre a Folha de Salários"	

	//REGISTRO M400: RECEITAS ISENTAS, NÃO ALCANÇADAS PELA INCIDÊNCIA DA CONTRIBUIÇÃO, SUJEITAS A ALÍQUOTA ZERO OU DE VENDAS COM SUSPENSÃO - PIS/PASEP
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) //"_REG"
	aAdd( aStru,{ "CST_PIS",	"C",	002,	0 } ) //"_CST_PIS"	
	aAdd( aStru,{ "VTO_REC",	"N",	014,	2 } ) //"_VL_TOT_REC"
	aAdd( aStru,{ "COD_CTA",	"C",	060,	0 } ) //"_COD_CTA"
	aAdd( aStru,{ "D_COMPL",	"C",	060,	0 } ) //"_DESC_COMPL"
	aAdd( aStru,{ "RELAC2",	"C",	010,	0 } )
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )	

	CriaTMPReg(aStru,"RELAC2","M400",@aTrbs)		

	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0558))	//"M400 - RECEITAS ISENTAS, NÃO ALCANÇADAS PELA INCIDÊNCIA DA CONTRIBUIÇÃO, SUJEITAS A ALÍQUOTA ZERO OU DE VENDAS COM SUSPENSÃO - PIS/PASEP"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0159, cPictChar })	//Código de Situação Tributária - CST das demais receitas auferidas no período, sem incidência da contribuição, ou sem contribuição apurada a pagar, conforme a Tabela 4.3.3.
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0559, cPictNUM })	//"Valor total da receita bruta no período"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0232, cPictChar })	//Código da conta analítica contábil debitada/creditada.
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0560, cPictChar })	//"Descrição Complementar da Natureza da Receita"

	//REGISTRO M410: DETALHAMENTO DAS RECEITAS ISENTAS, NÃO ALCANÇADAS PELA INCIDÊNCIA DA CONTRIBUIÇÃO, SUJEITAS A ALÍQUOTA ZERO OU DE VENDAS COM SUSPENSÃO - PIS/PASEP
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) //"_REG"
	aAdd( aStru,{ "NAT_REC",	"C",	002,	0 } ) //"_NAT_REC"	
	aAdd( aStru,{ "VL_REC",	"N",	014,	2 } ) //"_VL_REC"
	aAdd( aStru,{ "COD_CTA",	"C",	060,	0 } ) //"_COD_CTA"
	aAdd( aStru,{ "D_COMPL",	"C",	060,	0 } ) //"_DESC_COMPL"
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )		

	CriaTMPReg(aStru,"RELAC3","M410",@aTrbs)		

	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0561))	//"M410 - DETALHAMENTO DAS RECEITAS ISENTAS, NÃO ALCANÇADAS PELA INCIDÊNCIA DA CONTRIBUIÇÃO, SUJEITAS A ALÍQUOTA ZERO OU DE VENDAS COM SUSPENSÃO - PIS/PASEP"				
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0562, cPictChar })	//"Natureza da Receita, conforme relação constante nas Tabelas de Detalhamento da Natureza da Receita por Situação Tributária abaixo"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0559, cPictNUM })	//"Valor total da receita bruta no período"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0232, cPictChar })	//Código da conta analítica contábil debitada/creditada.
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0560, cPictChar })	//"Descrição Complementar da Natureza da Receita"

	//REGISTRO M500: CRÉDITO DE COFINS RELATIVO AO PERÍODO
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) //"_REG"
	aAdd( aStru,{ "CO_CRED",	"C",	003,	0 } ) //"_COD_CRED"	
	aAdd( aStru,{ "ICR_ORI",	"C",	001,	0 } ) //"_IND_CRED_ORI"
	aAdd( aStru,{ "VB_COFI",	"N",	018,	2 } ) //"_VL_BC_COFINS"
	aAdd( aStru,{ "AL_COFI",	"N",	014,	4 } ) //"_ALIQ_COFINS"
	aAdd( aStru,{ "QB_COFI",	"N",	014,	2 } ) //"_QUANT_BC_COFINS"
	aAdd( aStru,{ "ACOFQUA",	"N",	014,	4 } ) //"_ALIQ_COFINS_QUANT"
	aAdd( aStru,{ "VL_CRED",	"N",	014,	2 } ) //"_VL_CRED"
	aAdd( aStru,{ "VA_ACRE",	"N",	014,	2 } ) //"_VL_AJUS_ACRES"
	aAdd( aStru,{ "VA_REDU",	"N",	014,	2 } ) //"_VL_AJUS_REDUC"
	aAdd( aStru,{ "VCR_DIF",	"N",	014,	2 } ) //"_VL_CRED_DIF"
	aAdd( aStru,{ "VC_DISP",	"N",	014,	2 } ) //"_VL_CRED_DISP"
	aAdd( aStru,{ "ID_CRED",	"C",	001,	0 } ) //"_IND_DESC_CRED"
	aAdd( aStru,{ "VC_DESC",	"N",	014,	2 } ) //"_VL_CRED_DESC"
	aAdd( aStru,{ "SLD_CRE",	"N",	014,	2 } ) //"_SLD_CRED"	
	aAdd( aStru,{ "RELAC2",	"C",	010,	0 } )
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )
	aAdd( aStrCmps,aStru )
	
	CriaTMPReg(aStru,"RELAC2","M500",@aTrbs)	
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0563))	//"M500 - CRÉDITO DE COFINS RELATIVO AO PERÍODO"	 
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0481, cPictChar })	//"Código de Tipo de Crédito apurado no período, conforme a Tabela 4.3.6."
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0482, cPictChar })	//"Indicador de Crédito Oriundo"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0483, cPictNUM3 })	//"Valor da Base de Cálculo do Crédito"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0161, cPictALI2 })	//Alíquota da COFINS (em percentual)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0229, cPictNUM })	//Quantidade - Base de cálculo COFINS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0230, cPictALI2 })	//Alíquota da COFINS (em reais)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0484, cPictNUM })	//"Valor total do crédito apurado no período"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0485, cPictNUM })	//"Valor total dos ajustes de acréscimo"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0486, cPictNUM })	//"Valor total dos ajustes de redução"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0487, cPictNUM })	//"Valor total do crédito diferido no período"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0488, cPictNUM })	//"Valor Total do Crédito Disponível relativo ao Período (08 + 09 - 10 - 11)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0564, cPictChar })	//"Indicador de utilização do crédito disponível no período:"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0490, cPictNUM })	//"Valor do Crédito disponível, descontado  da contribuição apurada no próprio período"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0491, cPictNUM })	//"Saldo de créditos a utilizar em períodos futuros (12 - 14)"	
    
	IncProc("Gerando estrutura...")

	//REGISTRO M505: DETALHAMENTO DA BASE DE CALCULO DO CRÉDITO APURADO NO PERÍODO - COFINS
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) //"_REG"
	aAdd( aStru,{ "NB_CRED",	"C",	002,	0 } ) //"_NAT_BC_CRED"	
	aAdd( aStru,{ "CST_COF",	"C",	002,	0 } ) //"_CST_COFINS"
	aAdd( aStru,{ "VBC_TOT",	"N",	018,	2 } ) //"_VL_BC_COFINS_TOT"
	aAdd( aStru,{ "VBC_CUM",	"N",	018,	2 } ) //"_VL_BC_COFINS_CUM"
	aAdd( aStru,{ "VBCI_NC",	"N",	018,	2 } ) //"_VL_BC_COFINS_NC"
	aAdd( aStru,{ "VBC_COF",	"N",	018,	2 } ) //"_VL_BC_COFINS"
	aAdd( aStru,{ "QBC_TOT",	"N",	014,	3 } ) //"_QUANT_BC_COFINS_TOT"
	aAdd( aStru,{ "QBC_COF",	"N",	014,	3 } ) //"_QUANT_BC_COFINS"
	aAdd( aStru,{ "DE_CRED",	"C",	020,	2 } ) //"_DESC_CRED"
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )
	aAdd( aStrCmps,aStru )	
	
	CriaTMPReg(aStru,"RELAC3","M505",@aTrbs)		
	
	aAdd( aTitulo, {})	 
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0565))	//"M505 - DETALHAMENTO DA BASE DE CALCULO DO CRÉDITO APURADO NO PERÍODO - COFINS"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0493, cPictChar })	//"Código da Base de Cálculo do Crédito apurado no período, conforme a Tabela 4.3.7."
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0566, cPictChar })	//"Código da Situação Tributária referente ao crédito de COFINS (Tabela 4.3.4) vinculado ao tipo de crédito escriturado em M500."
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0567, cPictNUM3 })	//"Valor Total da Base de Cálculo escriturada nos documentos e operações (Blocos 'A', 'C', 'D' e 'F'), referente ao CST_COFINS informado no Campo 03"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0496, cPictNUM3 })	//Parcela do Valor Total da Base de Cálculo informada no Campo 04, vinculada a receitas com incidência cumulativa.
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0497, cPictNUM3 })	//Campo de preenchimento específico para a pessoa jurídica sujeita ao regime cumulativo e não-cumulativo da contribuição (COD_INC_TRIB = 3 do Registro 0110)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0498, cPictNUM3 })	//Valor Total da Base de Cálculo do Crédito, vinculada a receitas com incidência não-cumulativa (Campo 04 - Campo 05).
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0568, cPictNUM2 })	//"Valor da Base de Cálculo do Crédito, vinculada ao tipo de Crédito escriturado em M500"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0569, cPictNUM2 })	//"Quantidade Total da Base de Cálculo do Crédito apurado em Unidade de Medida de Produto, escriturada nos documentos e operações (Blocos 'A', 'C', 'D' e 'F'), referente ao CST_COFINS informado no Campo 03"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0570, cPictNUM })	//"Parcela da base de cálculo do crédito em quantidade (campo 08) vinculada ao tipo de crédito escriturado em M500"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0502, cPictChar })	//"Descrição do crédito"
	
	//REGISTRO M510: AJUSTES DO CRÉDITO DE COFINS APURADO
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) //"_REG"
	aAdd( aStru,{ "IND_AJ",	"C",	001,	0 } ) //"_IND_AJ"	
	aAdd( aStru,{ "VL_AJ",		"N",	014,	2 } ) //"_VL_AJ"
	aAdd( aStru,{ "COD_AJ",	"C",	002,	0 } ) //"_COD_AJ"
	aAdd( aStru,{ "NUM_DOC",	"C",	030,	0 } ) //"_NUM_DOC"
	aAdd( aStru,{ "DESCR_A",	"C",	150,	0 } ) //"_DESCR_AJ"
	aAdd( aStru,{ "DT_REF",	"C",	008,	0 } ) //"_DT_REF"
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )
	aAdd( aStrCmps,aStru )	

	CriaTMPReg(aStru,"RELAC3","M510",@aTrbs)	
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0571))	//"M510 - AJUSTES DO CRÉDITO DE COFINS APURADO"	 
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0504, cPictChar })	//"Indicador do tipo de ajuste"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0505, cPictNUM })	//"Valor do ajuste"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0506, cPictChar })	//"Código do ajuste, conforme a Tabela indicada no item 4.3.8."
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0507, cPictChar })	//"Número do processo, documento ou ato concessório ao qual o ajuste está vinculado, se houver"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0508, cPictChar })	//"Descrição resumida do ajuste"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0509, cPictChar })	//"Data de referência do ajuste (ddmmaaaa)"
	
	//REGISTRO M600: CONSOLIDAÇÃO DA CONTRIBUIÇÃO PARA A SEGURIDADE SOCIAL - COFINS DO PERÍODO
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) //"_REG"
	aAdd( aStru,{ "VTCNPER",	"N",	014,	2 } ) //"_VL_TOT_CONT_NC_PER"	
	aAdd( aStru,{ "VTCDESC",	"N",	014,	2 } ) //"_VL_TOT_CRED_DESC"
	aAdd( aStru,{ "VTCDANT",	"N",	014,	2 } ) //"_VL_TOT_CRED_DESC_ANT"
	aAdd( aStru,{ "VTCNDEV",	"N",	014,	2 } ) //"_VL_TOT_CONT_NC_DEV"
	aAdd( aStru,{ "VRET_NC",	"N",	014,	2 } ) //"_VL_RET_NC"
	aAdd( aStru,{ "VODE_NC",	"N",	014,	2 } ) //"_VL_OUT_DED_NC"
	aAdd( aStru,{ "VCNCREC",	"N",	014,	2 } ) //"_VL_CONT_NC_REC"
	aAdd( aStru,{ "VTCCPER",	"N",	014,	2 } ) //"_VL_TOT_CONT_CUM_PER"
	aAdd( aStru,{ "VRE_CUM",	"N",	014,	2 } ) //"_VL_RET_CUM"
	aAdd( aStru,{ "VOD_CUM",	"N",	014,	2 } ) //"_VL_OUT_DED_CUM"
	aAdd( aStru,{ "VCC_REC",	"N",	014,	2 } ) //"_VL_CONT_CUM_REC"
	aAdd( aStru,{ "VTC_REC",	"N",	014,	2 } ) //"_VL_TOT_CONT_REC"
	aAdd( aStru,{ "RELAC2",	"C",	010,	0 } )
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )		
	
	CriaTMPReg(aStru,"RELAC2","M600",@aTrbs)	

	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0572))	//"M600 - CONSOLIDAÇÃO DA CONTRIBUIÇÃO PARA A SEGURIDADE SOCIAL - COFINS DO PERÍODO"	
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0511, cPictNUM })	//"Valor Total da Contribuição Não Cumulativa do Período (recuperado do campo 13 do Registro M210, quando o campo 'COD_CONT' = 01, 02, 03, 04, 32 e 71)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0512, cPictNUM })	//"Valor do Crédito Descontado, Apurado no Próprio Período da Escrituração (recuperado do campo 14 do Registro M100)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0513, cPictNUM })	//"Valor do Crédito Descontado, Apurado em Período de Apuração Anterior (recuperado do campo 13 do Registro 1100)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0514, cPictNUM })	//"Valor Total da Contribuição Não Cumulativa Devida (02 - 03 - 04)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0515, cPictNUM })	//"Valor Retido na Fonte Deduzido no Período"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0516, cPictNUM })	//"Outras Deduções no Período"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0517, cPictNUM })	//"Valor da Contribuição Não Cumulativa a Recolher/Pagar (05 - 06 - 07)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0518, cPictNUM })	//"Valor Total da Contribuição Cumulativa do Período  (recuperado do campo 13 do Registro M210, quando o campo 'COD_CONT' = 31, 32, 51, 52, 53, 54 e 72)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0519, cPictNUM })	//"Valor Retido na Fonte Deduzido no Período"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0516, cPictNUM })	//Outras Deduções no Período
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0520, cPictNUM })	//"Valor da Contribuição Cumulativa a Recolher/Pagar (09 - 10 - 11)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0521, cPictNUM })	//"Valor Total da Contribuição a Recolher/Pagar no Período (08 + 12)"	

	//REGISTRO M610: DETALHAMENTO DA CONTRIBUIÇÃO PARA A SEGURIDADE SOCIAL - COFINS DO PERÍODO
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) //"_REG"
	aAdd( aStru,{ "CO_CONT",	"C",	002,	0 } ) //"_COD_CONT"	
	aAdd( aStru,{ "VRE_BRT",	"N",	018,	2 } ) //"_VL_REC_BRT"
	aAdd( aStru,{ "VB_CONT",	"N",	018,	2 } ) //"_VL_BC_CONT"
	aAdd( aStru,{ "AL_COFI",	"N",	014,	4 } ) //"_ALIQ_COFINS"
	aAdd( aStru,{ "QBCCOFI",	"N",	014,	2 } ) //"_QUANT_BC_COFINS"
	aAdd( aStru,{ "ACQUANT",	"N",	014,	4 } ) //"_ALIQ_COFINS_QUANT"
	aAdd( aStru,{ "VCOAPUR",	"N",	014,	2 } ) //"_VL_CONT_APUR"
	aAdd( aStru,{ "VAACRES",	"N",	014,	2 } ) //"_VL_AJUS_ACRES"
	aAdd( aStru,{ "VAREDUC",	"N",	014,	2 } ) //"_VL_AJUS_REDUC"
	aAdd( aStru,{ "VCOIFER",	"N",	014,	2 } ) //"_VL_CONT_DIFER"
	aAdd( aStru,{ "VCODANT",	"N",	014,	2 } ) //"_VL_CONT_DIFER_ANT"
	aAdd( aStru,{ "VCONPER",	"N",	014,	2 } ) //"_VL_CONT_PER"
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )	
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )		
	aAdd( aStrCmps,aStru )	

	CriaTMPReg(aStru,"RELAC3","M610",@aTrbs)	
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0573))	//"M610 - DETALHAMENTO DA CONTRIBUIÇÃO PARA A SEGURIDADE SOCIAL - COFINS DO PERÍODO" 
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0523, cPictChar })	//"Código da contribuição social apurada no período, conforme a Tabela 4.3.5."
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0524, cPictNUM3 })	//"Valor da Receita Bruta"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0525, cPictNUM3 })	//"Valor da Base de Cálculo da Contribuição"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0161, cPictALI2 })	//Alíquota do COFINS (em percentual)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0229, cPictNUM })	//Quantidade - Base de cálculo COFINS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0230, cPictNUM })	//Alíquota do COFINS (em reais)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0526, cPictNUM })	//"Valor total da contribuição social apurada"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0527, cPictNUM })	//"Valor total dos ajustes de acréscimo"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0528, cPictNUM })	//"Valor total dos ajustes de redução"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0529, cPictNUM })	//"Valor da contribuição a diferir no período"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0530, cPictNUM })	//"Valor da contribuição diferida em períodos anteriores"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0531, cPictNUM })	//"Valor Total da Contribuição do Período (08 + 09 - 10 - 11+12)"	

	//REGISTRO M611: SOCIEDADES COOPERATIVAS - COMPOSIÇÃO DA BASE DE CALCULO - COFINS
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) //"_REG"
	aAdd( aStru,{ "IT_COOP",	"C",	002,	0 } ) //"_IND_TIP_COOP"	
	aAdd( aStru,{ "VBCAECP",	"N",	014,	2 } ) //"_VL_BC_CONT_ANT_EXC_COOP"
	aAdd( aStru,{ "VECPGER",	"N",	014,	2 } ) //"_VL_EXC_COOP_GER"
	aAdd( aStru,{ "VEECOOP",	"N",	014,	2 } ) //"_VL_EXC_ESP_COOP"
	aAdd( aStru,{ "VB_CONT",	"N",	014,	2 } ) //"_VL_BC_CONT"
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )	
	
	CriaTMPReg(aStru,"RELAC4","M611",@aTrbs)	

	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0574))	//"M611 - SOCIEDADES COOPERATIVAS - COMPOSIÇÃO DA BASE DE CALCULO - COFINS"		
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0533, cPictChar })	//"Indicador do Tipo de Sociedade Cooperativa"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0526, cPictNUM })	//Valor da Base de Cálculo da Contribuição, conforme Registros escriturados nos Blocos A, C, D e F, antes das Exclusões das Cooperativas.
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0534, cPictNUM })	//"Valor de Exclusão Especifica das Cooperativas em Geral, decorrente das Sobras Apuradas na DRE, destinadas a constituição do Fundo de Reserva e do FATES"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0535, cPictNUM })	//"Valor das Exclusões da Base de Cálculo Especifica do Tipo da Sociedade Cooperativa, conforme Campo 02 (IND_TIP_COOP)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0536, cPictNUM })	//"Valor da Base de Cálculo, Após as Exclusões Especificas da Sociedade Cooperativa (04 - 05 - 06) - Transportar para M210"		

	//REGISTRO M620: AJUSTES DA COFINS APURADA
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) //"_REG"
	aAdd( aStru,{ "IND_AJ",	"C",	001,	0 } ) //"_IND_AJ"	
	aAdd( aStru,{ "VL_AJ",		"N",	014,	2 } ) //"_VL_AJ"
	aAdd( aStru,{ "COD_AJ",	"C",	002,	0 } ) //"_COD_AJ"
	aAdd( aStru,{ "NUM_DOC",	"C",	060,	0 } ) //"_NUM_DOC"
	aAdd( aStru,{ "DESCR_A",	"C",	060,	0 } ) //"_DESCR_AJ"
	aAdd( aStru,{ "DT_REF",	"C",	008,	0 } ) //"_DT_REF"
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )
	aAdd( aStrCmps,aStru )	

	CriaTMPReg(aStru,"RELAC4","M620",@aTrbs)	
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0575))	//"M620 - AJUSTES DA COFINS APURADA" 
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0504, cPictChar })	//"Indicador do tipo de ajuste"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0505, cPictNUM })	//"Valor do ajuste"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0506, cPictChar })	//"Código do ajuste, conforme a Tabela indicada no item 4.3.8."
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0507, cPictChar })	//"Número do processo, documento ou ato concessório ao qual o ajuste está vinculado, se houver"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0508, cPictChar })	//"Descrição resumida do ajuste"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0509, cPictChar })	//"Data de referência do ajuste (ddmmaaaa)"	

	//REGISTRO M630: INFORMAÇÕES ADICIONAIS DE DIFERIMENTO
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) //"_REG"
	aAdd( aStru,{ "CNPJ",		"C",	020,	0 } ) //"_CNPJ"	
	aAdd( aStru,{ "VL_VEND",	"N",	014,	2 } ) //"_VL_VEND"
	aAdd( aStru,{ "VNRECEB",	"N",	014,	2 } ) //"_VL_NAO_RECEB"
	aAdd( aStru,{ "VCT_DIF",	"N",	014,	2 } ) //"_VL_CONT_DIF"
	aAdd( aStru,{ "VCR_DIF",	"N",	014,	2 } ) //"_VL_CRED_DIF"
	aAdd( aStru,{ "CO_CRED",	"C",	003,	0 } ) //"_DT_REF"
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )
	aAdd( aStrCmps,aStru )	

	CriaTMPReg(aStru,"RELAC4","M630",@aTrbs)		

	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0576))	//"M630 - INFORMAÇÕES ADICIONAIS DE DIFERIMENTO" 
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0024, cPictCNPJ })	//CNPJ da pessoa jurídica de direito público, empresa pública, sociedade de economia mista ou suas subsidiárias.
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0539, cPictNUM })	//"Valor Total das vendas no período"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0540, cPictNUM })	//"Valor Total não recebido no período"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0541, cPictNUM })	//"Valor da Contribuição diferida no período"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0542, cPictNUM })	//"Valor do Crédito diferido no período"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0543, cPictChar })	//"Código de Tipo de Crédito diferido no período, conforme a Tabela 4.3.6."		

	//REGISTRO M700: COFINS DIFERIDA EM PERÍODOS ANTERIORES - VALORES A PAGAR NO PERÍODO
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) //"_REG"
	aAdd( aStru,{ "CO_CONT",	"C",	002,	0 } ) //"_COD_CONT"	
	aAdd( aStru,{ "VCADIFE",	"N",	014,	2 } ) //"_VL_CONT_APUR_DIFER"
	aAdd( aStru,{ "NC_DESC",	"C",	002,	0 } ) //"_NAT_CRED_DESC"
	aAdd( aStru,{ "VCDDIFE",	"N",	014,	2 } ) //"_VL_CRED_DESC_DIFER"
	aAdd( aStru,{ "VCD_ANT",	"N",	014,	2 } ) //"_VL_CONT_DIFER_ANT"
	aAdd( aStru,{ "PER_APU",	"C",	006,	0 } ) //"_PER_APUR"
	aAdd( aStru,{ "DT_RECE",	"C",	008,	0 } ) //"_DT_RECEB"
	aAdd( aStru,{ "RELAC2",	"C",	010,	0 } )
	aAdd( aStrCmps,aStru )
	
	CriaTMPReg(aStru,"RELAC2","M700",@aTrbs)	

	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0577))	//"M700 - COFINS DIFERIDA EM PERÍODOS ANTERIORES - VALORES A PAGAR NO PERÍODO"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0545, cPictChar })	//"Código da contribuição social diferida em períodos anteriores, conforme a Tabela 4.3.5."
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0546, cPictNUM })	//"Valor da Contribuição Apurada, diferida em períodos anteriores"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0547, cPictChar })	//"Natureza do Crédito Diferido, vinculado à receita tributada no mercado interno, a descontar"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0548, cPictNUM })	//"Valor do Crédito a Descontar vinculado à contribuição diferida"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0549, cPictNUM })	//"Valor da Contribuição a Recolher, diferida em períodos anteriores (Campo 03 - Campo 05)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0550, cPictChar })	//"Período de apuração da contribuição social e dos créditos diferidos (MMAAAA)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0551, cPictChar })	//"Data de recebimento da receita, objeto de diferimento" 	

	//REGISTRO M800: RECEITAS ISENTAS, NÃO ALCANÇADAS PELA INCIDÊNCIA DA CONTRIBUIÇÃO, SUJEITAS A ALÍQUOTA ZERO OU DE VENDAS COM SUSPENSÃO - COFINS
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) //"_REG"
	aAdd( aStru,{ "CST_PIS",	"C",	002,	0 } ) //"_CST_PIS"	
	aAdd( aStru,{ "VTO_REC",	"N",	014,	2 } ) //"_VL_TOT_REC"
	aAdd( aStru,{ "COD_CTA",	"C",	060,	0 } ) //"_COD_CTA"
	aAdd( aStru,{ "D_COMPL",	"C",	150,	0 } ) //"_DESC_COMPL"
	aAdd( aStru,{ "RELAC2",	"C",	010,	0 } )
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )	

	CriaTMPReg(aStru,"RELAC2","M800",@aTrbs)		

	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0578))	//"M800 - RECEITAS ISENTAS, NÃO ALCANÇADAS PELA INCIDÊNCIA DA CONTRIBUIÇÃO, SUJEITAS A ALÍQUOTA ZERO OU DE VENDAS COM SUSPENSÃO - COFINS"	
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0159, cPictChar })	//Código de Situação Tributária - CST das demais receitas auferidas no período, sem incidência da contribuição, ou sem contribuição apurada a pagar, conforme a Tabela 4.3.3.
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0559, cPictNUM })	//"Valor total da receita bruta no período"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0232, cPictChar })	//Código da conta analítica contábil debitada/creditada.
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0560, cPictChar })	//"Descrição Complementar da Natureza da Receita"	

	//REGISTRO M810: DETALHAMENTO DAS RECEITAS ISENTAS, NÃO ALCANÇADAS PELA INCIDÊNCIA DA CONTRIBUIÇÃO, SUJEITAS A ALÍQUOTA ZERO OU DE VENDAS COM SUSPENSÃO - COFINS
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) //"_REG"
	aAdd( aStru,{ "CST_PIS",	"C",	002,	0 } ) //"_CST_PIS"	
	aAdd( aStru,{ "VTO_REC",	"N",	014,	2 } ) //"_VL_TOT_REC"
	aAdd( aStru,{ "COD_CTA",	"C",	030,	0 } ) //"_COD_CTA"
	aAdd( aStru,{ "D_COMPL",	"C",	150,	0 } ) //"_DESC_COMPL"
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )	

	CriaTMPReg(aStru,"RELAC3","M810",@aTrbs)		
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0579))	//"M810 - DETALHAMENTO DAS RECEITAS ISENTAS, NÃO ALCANÇADAS PELA INCIDÊNCIA DA CONTRIBUIÇÃO, SUJEITAS A ALÍQUOTA ZERO OU DE VENDAS COM SUSPENSÃO - COFINS"	 
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0562, cPictChar })	//"Natureza da Receita, conforme relação constante nas Tabelas de Detalhamento da Natureza da Receita por Situação Tributária abaixo"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0559, cPictNUM })	//"Valor total da receita bruta no período"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0232, cPictChar })	//Código da conta analítica contábil debitada/creditada.
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0560, cPictChar })	//"Descrição Complementar da Natureza da Receita"

	//REGISTRO M990: ENCERRAMENTO DO BLOCO M
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) //"_REG"
	aAdd( aStru,{ "Q_LIN0",	"N",	010,	0 } ) //"_QTD_LIN_0"	
	aAdd( aStru,{ "RELAC",		"C",	010,	0 } )
	aAdd( aStrCmps,aStru )
	
	CriaTMPReg(aStru,"RELAC","M990",@aTrbs)	
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0580))	//"M990 - ENCERRAMENTO DO BLOCO M"	 
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0581, cPictChar })	//"Quantidade total de linhas do Bloco M"

	//REGISTRO P001: ABERTURA DO BLOCO P
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) //"_REG"
	aAdd( aStru,{ "IND_MO",	"C",	003,	0 } ) //"_IND_MOV"
	aAdd( aStru,{ "RELAC",		"C",	010,	0 } )
	aAdd( aStru,{ "RELAC2",	"C",	010,	0 } )
	aAdd( aStrCmps,aStru )
	
	CriaTMPReg(aStru,"RELAC2","P001",@aTrbs)	
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi("P001 - ABERTURA DO BLOCO P"))	//"P001 - ABERTURA DO BLOCO P"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0031, cPictChar })	//"Movimento"	
	
	//REGISTRO P010: IDENTIFICAÇÃO DO ESTABELECIMENTO
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "CNPJ",		"C",	020,	0 } )	//"_CNPJ"	
	aAdd( aStru,{ "RELAC2",	"C",	010,	0 } )	
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )
	aAdd( aStrCmps,aStru )
	
	CriaTMPReg(aStru,"RELAC2","P010",@aTrbs)		
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi("P010 - IDENTIFICAÇÃO DO ESTABELECIMENTO"))	//"P010 - IDENTIFICAÇÃO DO ESTABELECIMENTO"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0024, cPictCNPJ })	//"CNPJ"
	
	//REGISTRO P100: CONTRIBUIÇÃO PREVIDENCIÁRIA SOBRE A RECEITA BRUTA
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "DT_INI",	"C",	008,	0 } ) 	//"DT_INI"	
	aAdd( aStru,{ "DT_FIN",	"C",	008,	0 } ) 	//"DT_FIN"
	aAdd( aStru,{ "RECTOT",	"N",	014,	2 } ) 	//"VL_REC_TOT_EST"
	aAdd( aStru,{ "CODATI",	"C",	008,	0 } ) 	//"COD_ATIV_ECON"
	aAdd( aStru,{ "RECATI",	"N",	014,	2 } ) 	//"VL_REC_ATIV_ESTAB"
	aAdd( aStru,{ "VL_EXC",	"N",	014,	2 } ) 	//"VL_EXC"
	aAdd( aStru,{ "BCCONT",	"N",	014,	2 } ) 	//"VL_BC_CONT"
	aAdd( aStru,{ "ALIQ",		"N",	008,	4 } ) 	//"ALIQ_CONT"
	aAdd( aStru,{ "VLAPU",		"N",	014,	2 } ) 	//"VL_CONT_APU"
	aAdd( aStru,{ "CODCTA",	"C",	030,	0 } ) 	//"COD_CTA"
	aAdd( aStru,{ "INFOCO",	"C",	050,	0 } ) 	//"INFO_COMPL"
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )
	aAdd( aStrCmps,aStru )

	CriaTMPReg(aStru,"RELAC3","P100",@aTrbs)		

	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi("P100: CONTRIBUIÇÃO PREVIDENCIÁRIA SOBRE A RECEITA BRUTA"))	// "P100: CONTRIBUIÇÃO PREVIDENCIÁRIA SOBRE A RECEITA BRUTA"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016		, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0021 		, cPictChar })	//"Data Inicial"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0022 		, cPictChar })	//"Data Final"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0670 	 	, cPictNUM  })	//"Receita Bruta Total"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0671 		, cPictChar })	//"Cód. atividade"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0672 		, cPictNUM  })	//"Receita Bruta relativa a atividade"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0673 		, cPictNUM  })	//"Exclusões"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0674 		, cPictNUM  })	//"Base de Cálculo"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0675 		, cPictALI2 })	//"Alíquota da Contribuição Previdenciária sobre a Receita Bruta"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0676 		, cPictNUM  })	//"Valor da Contribuição Previdenciária Apurada sobre a Receita Bruta"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0163		, cPictChar })	//"Código da conta analítica contábil debitada/creditada"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0136		, cPictChar })	//"Informação complementar do registro"

	//REGISTRO P200: CONSOLIDAÇÃO DA CONTRIBUIÇÃO PREVIDENCIÁRIA SOBRE A RECEITA BRUTA
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "PERI",		"C",	006,	0 } ) 	//"PER_REF"	
	aAdd( aStru,{ "TOTAPU",	"N",	014,	2 } ) 	//"VL_TOT_CONT_APU"
	aAdd( aStru,{ "AJREDU",	"N",	014,	2 } ) 	//"VL_TOT_AJ_REDUC"
	aAdd( aStru,{ "AJACRE",	"N",	014,	2 } ) 	//"VL_TOT_AJ_ACRES"
	aAdd( aStru,{ "DEVIDO",	"N",	014,	2 } ) 	//"VL_TOT_CONT_DEV"
	aAdd( aStru,{ "CODREC",	"C",	006,	0 } ) 	//"COD_REC"
	aAdd( aStru,{ "RELAC2",	"C",	010,	0 } )
	aAdd( aStrCmps,aStru )

	CriaTMPReg(aStru,"RELAC2","P200",@aTrbs)		

	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi("P200: CONSOLIDAÇÃO DA CONTRIBUIÇÃO PREVIDENCIÁRIA SOBRE A RECEITA BRUTA"))	// "P200: CONSOLIDAÇÃO DA CONTRIBUIÇÃO PREVIDENCIÁRIA SOBRE A RECEITA BRUTA"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016		, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0677 		, cPictChar })	//"Período"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0678 		, cPictNUM  })	//"Total Apurado"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0679 		, cPictNUM  })	//"Ajustes de redução"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0680  		, cPictNUM  })	//"Ajustes de acréscimo"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0681 		, cPictNUM  })	//"Valor total devido"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0682		, cPictChar })	//"Código de Receita"

	//REGISTRO P990: ENCERRAMENTO DO BLOCO P
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) //"_REG"
	aAdd( aStru,{ "Q_LIN0",	"N",	010,	0 } ) //"_QTD_LIN_0"	
	aAdd( aStru,{ "RELAC",		"C",	010,	0 } )
	aAdd( aStrCmps,aStru )
	
	CriaTMPReg(aStru,"RELAC","P990",@aTrbs)	
		
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi("P990 - ENCERRAMENTO DO BLOCO P"))	//"P990 - ENCERRAMENTO DO BLOCO P"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0366, cPictChar })	//"Quantidade total de linhas do Bloco D"	 

	//REGISTRO 1001: ABERTURA DO BLOCO 1
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) //"_REG"
	aAdd( aStru,{ "IND_MO",	"C",	001,	0 } ) //"_IND_MOV"
	aAdd( aStru,{ "RELAC",		"C",	010,	0 } )
	aAdd( aStru,{ "RELAC2",	"C",	010,	0 } )
	aAdd( aStrCmps,aStru )
	
	CriaTMPReg(aStru,"RELAC","1001",@aTrbs)	
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0582))	//"1001 - ABERTURA DO BLOCO 1"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0031, cPictChar })	//"Movimento"	

	//REGISTRO 1010: PROCESSO REFERENCIADO - AÇÃO JUDICIAL
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) //"_REG"
	aAdd( aStru,{ "NUM_PRO",	"C",	020,	0 } ) //"_NUM_PROC"
	aAdd( aStru,{ "ISC_JUD",	"C",	060,	0 } ) //"_ID_SEC_JUD"
	aAdd( aStru,{ "ID_VARA",	"C",	002,	0 } ) //"_ID_VARA"
	aAdd( aStru,{ "IN_ACAO",	"C",	002,	0 } ) //"_IND_NAT_ACAO"
	aAdd( aStru,{ "DDC_JUD",	"C",	050,	0 } ) //"_DESC_DEC_JUD"
	aAdd( aStru,{ "DST_JUD",	"C",	008,	0 } ) //"_DT_SENT_JUD"		
	aAdd( aStru,{ "RELAC2",	"C",	010,	0 } )
	aAdd( aStrCmps,aStru )	

	CriaTMPReg(aStru,"RELAC2","1010",@aTrbs)	

	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0583))	//"1010 - PROCESSO REFERENCIADO - AÇÃO JUDICIAL"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0584, cPictChar })	//"Identificação do Número do Processo Judicial"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0585, cPictChar })	//"Identificação da Seção Judiciária"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0586, cPictChar })	//"Identificação da Vara"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0587, cPictChar })	//"Indicador da Natureza da Ação Judicial, impetrada na Justiça Federal"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0588, cPictChar })	//"Descrição Resumida dos Efeitos Tributários abrangidos pela Decisão Judicial proferida"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0589, cPictChar })	//"Data da Sentença/Decisão Judicial"

	//REGISTRO 1020: PROCESSO REFERENCIADO - PROCESSO ADMINISTRATIVO
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) //"_REG"
	aAdd( aStru,{ "NUM_PRO",	"C",	020,	0 } ) //"_NUM_PROC"
	aAdd( aStru,{ "IN_ACAO",	"C",	002,	0 } ) //"_IND_NAT_ACAO"
	aAdd( aStru,{ "DTD_ADM",	"C",	008,	0 } ) //"_DT_DEC_ADM"	
	aAdd( aStru,{ "RELAC2",	"C",	010,	0 } )
	aAdd( aStrCmps,aStru )	

	CriaTMPReg(aStru,"RELAC2","1020",@aTrbs)	

	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0590))	//"1020 - PROCESSO REFERENCIADO - PROCESSO ADMINISTRATIVO"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0591, cPictChar })	//"Identificação do Processo Administrativo ou da Decisão Administrativa"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0592, cPictChar })	//"Indicador da Natureza da Ação, decorrente de Processo Administrativo na Secretaria da Receita Federal do Brasil"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0593, cPictChar })	//"Data do Despacho/Decisão Administrativa"	

	//REGISTRO 1100: CONTROLE DE CRÉDITOS FISCAIS - PIS/PASEP
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) //"_REG"
	aAdd( aStru,{ "PA_CRED",	"C",	006,	0 } ) //"_PER_APU_CRED"
	aAdd( aStru,{ "OR_CRED",	"C",	002,	0 } ) //"_ORIG_CRED"
	aAdd( aStru,{ "CNPJSUC",	"C",	020,	0 } ) //"_DT_DEC_ADM"
	aAdd( aStru,{ "CO_CRED",	"C",	003,	0 } ) //"_COD_CRED"	
	aAdd( aStru,{ "VCR_APU",	"N",	014,	2 } ) //"_VL_CRED_APU"	
	aAdd( aStru,{ "VCE_APU",	"N",	014,	2 } ) //"_VL_CRED_EXT_APU"	
	aAdd( aStru,{ "VTC_APU",	"N",	014,	2 } ) //"_VL_TOT_CRED_APU"	
	aAdd( aStru,{ "VCDPANT",	"N",	014,	2 } ) //"_VL_CRED_DESC_PA_ANT"	
	aAdd( aStru,{ "VCPPANT",	"N",	014,	2 } ) //"_VL_CRED_PER_PA_ANT"	
	aAdd( aStru,{ "VCDCPAN",	"N",	014,	2 } ) //"_VL_CRED_DCOMP_PA_ANT"	
	aAdd( aStru,{ "SCDPEFD",	"N",	014,	2 } ) //"_SD_CRED_DISP_EFD"	
	aAdd( aStru,{ "VCDEEFD",	"N",	014,	2 } ) //"_VL_CRED_DESC_EFD"	
	aAdd( aStru,{ "VCPEEFD",	"N",	014,	2 } ) //"_VL_CRED_PER_EFD"	
	aAdd( aStru,{ "VCDPEFD",	"N",	014,	2 } ) //"_VL_CRED_DCOMP_EFD"	
	aAdd( aStru,{ "VCTRANS",	"N",	014,	2 } ) //"_VL_CRED_TRANS"	
	aAdd( aStru,{ "VCR_OUT",	"N",	014,	2 } ) //"_DT_DEC_ADM"	
	aAdd( aStru,{ "SCR_FIM",	"N",	014,	2 } ) //"_SLD_CRED_FIM"																
	aAdd( aStru,{ "RELAC2",	"C",	010,	0 } )
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )	

	CriaTMPReg(aStru,"RELAC2","1100",@aTrbs)	

	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0594))	// "1100 - CONTROLE DE CRÉDITOS FISCAIS - PIS/PASEP"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0472, cPictChar })	//"Período de Apuração do Crédito (MM/AAAA)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0154, cPictChar })	//Indicador da origem do crédito:
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0024, cPictCNPJ })	//CNPJ da pessoa jurídica cedente do crédito (se ORIG_CRED = 02).
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0595, cPictChar })	//"Código do Tipo do Crédito, conforme Tabela 4.3.6."
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0596, cPictNUM })	//"Valor do Crédito apurado na Escrituração Fiscal Digital ou em demonstrativo DACON de períodos anteriores"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0597, cPictNUM })	//"Valor de Crédito Extemporâneo Apurado (Registro 1101), referente a Período Anterior, Informado no Campo 02 - PER_APU_CRED"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0598, cPictNUM })	//"Valor Total do Crédito Apurado (06 + 07)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0599, cPictNUM })	//"Valor do Crédito utilizado mediante Desconto, em Período(s)  Anterior(es)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0600, cPictNUM })	//"Valor do Crédito utilizado mediante Pedido de Ressarcimento, em Período(s) Anterior(es)."
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0601, cPictNUM })	//"Valor do Crédito utilizado mediante Declaração de Compensação Intermediária (Crédito de Exportação), em Período(s) Anterior(es)."
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0602, cPictNUM })	//"Saldo do Crédito Disponível para Utilização neste Período de Escrituração (08 - 09 - 10 - 11)."
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0603, cPictNUM })	//"Valor do Crédito descontado neste período de escrituração."
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0604, cPictNUM })	//"Valor do Crédito objeto de Pedido de Ressarcimento (PER) neste período de escrituração."
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0605, cPictNUM })	//"Valor do Crédito utilizado mediante Declaração de Compensação Intermediária neste período de escrituração."
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0606, cPictNUM })	//"Valor do crédito transferido em evento de cisão, fusão ou incorporação."
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0607, cPictNUM })	//"Valor do crédito utilizado por outras formas."
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0608, cPictNUM })	//"Saldo de créditos a utilizar em período de apuração futuro (12 - 13 - 14 - 15 - 16 - 17)."

	//REGISTRO 1101: APURAÇÃO DE CRÉDITO EXTEMPORÂNEO - DOCUMENTOS E OPERAÇÕES DE PERÍODOS ANTERIORES - PIS/PASEP
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "C_P",		"C",	060,	0 } ) 	//"_COD_PART"
	aAdd( aStru,{ "C_ITEM",	"C",	060,	0 } ) 	//"_COD_ITEM"
	aAdd( aStru,{ "COD_MOD",	"C",	002,	0 } ) 	//"_COD_MOD"
	aAdd( aStru,{ "SER",		"C",	004,	0 } ) 	//"_SER"
	aAdd( aStru,{ "SUB_SER",	"C",	001,	0 } ) 	//"_SUB_SER"		
	aAdd( aStru,{ "NUM_DOC",	"C",	009,	0 } ) 	//"_VL_BC_PIS"
	aAdd( aStru,{ "DT_OPER",	"C",	008,	0 } ) 	//"_DT_OPER"
	aAdd( aStru,{ "CHV_NFE",	"C",	044,	0 } ) 	//"_CHV_NFE"	
	aAdd( aStru,{ "VL_OPER",	"N",	014,	2 } ) 	//"_VL_OPER"
	aAdd( aStru,{ "CFOP",		"C",	004,	0 } ) 	//"_CFOP"
	aAdd( aStru,{ "NB_CRED",	"C",	002,	0 } ) 	//"_NAT_BC_CRED"		
	aAdd( aStru,{ "IO_CRED",	"C",	001,	0 } ) 	//"_IND_ORIG_CRED"
	aAdd( aStru,{ "CST_PIS",	"C",	002,	0 } ) 	//"_CST_PIS"
	aAdd( aStru,{ "VBC_PIS",	"N",	014,	3 } ) 	//"_VL_BC_PIS"	
	aAdd( aStru,{ "ALI_PIS",	"N",	006,	4 } ) 	//"_ALIQ_PIS"
	aAdd( aStru,{ "VL_PIS",	"N",	014,	2 } ) 	//"_VL_PIS"
	aAdd( aStru,{ "COD_CTA",	"C",	060,	0 } ) 	//"_COD_CTA"		
	aAdd( aStru,{ "COD_CCU",	"C",	060,	0 } ) 	//"_COD_CCUS"	
	aAdd( aStru,{ "DE_COMP",	"C",	060,	0 } ) 	//"_DESC_COMPL"		
	aAdd( aStru,{ "PE_ESCR",	"C",	006,	0 } ) 	//"_PER_ESCRIT"	
	aAdd( aStru,{ "CNPJ",		"C",	020,	0 } ) 	//"_CNPJ"			
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )	

	CriaTMPReg(aStru,"RELAC3","1101",@aTrbs)	

	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0609))	//"1101 - APURAÇÃO DE CRÉDITO EXTEMPORÂNEO - DOCUMENTOS E OPERAÇÕES DE PERÍODOS ANTERIORES - PIS/PASEP"	 
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	//aAdd( aTitulo[Len(aTitulo)][2],{ STR0114, cPictChar })	//"Tipo de Operação"	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0116, cPictChar })	//"Código do participante"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0237, cPictChar })	//Código do item (campo 02 do Registro 0200)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0171, cPictChar })	//Código do modelo do documento fiscal, conforme a Tabela 4.1.1.
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0118, cPictChar })	//Série do documento fiscal
	aAdd( aTitulo[Len(aTitulo)][2],{ "" /*STR0119*/, cPictChar })	//Subsérie do documento fiscal
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0172, cPictChar })	//Número do documento fiscal
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0370, cPictChar })	//"Data da Operação (ddmmaaaa)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0173, cPictChar })	//"Chave da Nota Fiscal Eletrônica"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0371, cPictNUM })	//Valor da Operação
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0206, cPictChar })	//Código fiscal de operação e prestação	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0493, cPictChar })	//Código da Base de Cálculo do Crédito, conforme a Tabela indicada no item 4.3.7.
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0154, cPictChar })	//Indicador da origem do crédito:
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0220, cPictChar })	//Código da Situação Tributária referente ao PIS/PASEP, conforme a Tabela indicada no item 4.3.3.
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0221, cPictNUM })	//Base de Cálculo do Crédito de PIS/PASEP (em valor ou em quantidade).
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0372, cPictALI1 })	// Alíquota do PIS/PASEP (em percentual ou em reais).
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0264, cPictNUM })	//Valor do Crédito de PIS/PASEP.
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0447, cPictChar })	//Código da conta analítica contábil debitada/creditada.
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0164, cPictChar })	//Código do Centro de Custos.
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0200, cPictChar })	//Descrição complementar do Documento/Operação.
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0610, cPictChar })	//"Mês/Ano da Escrituração em que foi registrado o documento/operação (Crédito pelo método da Apropriação Direta)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0024, cPictCNPJ })	//CNPJ do estabelecimento gerador do crédito extemporâneo (Campo 04  do Registro 0140)	
	
	//REGISTRO 1102: DETALHAMENTO DO CRÉDITO EXTEMPORANEO VINCULADO A MAIS DE UM TIPO DE RECEITA - PIS/PASEP
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "VCPTMI",	"N",	014,	2 } ) 	//"_VL_CRED_PIS_TRIB_MI"
	aAdd( aStru,{ "VCPNTMI",	"N",	014,	2 } ) 	//"_VL_CRED_PIS_NT_MI"
	aAdd( aStru,{ "VCPEXP",	"N",	014,	2 } ) 	//"_VL_CRED_PIS_EXP"
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )		

	CriaTMPReg(aStru,"RELAC4","1102",@aTrbs)		

	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0611))	//"1102 - DETALHAMENTO DO CRÉDITO EXTEMPORANEO VINCULADO A MAIS DE UM TIPO DE RECEITA - PIS/PASEP"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0612, cPictNUM })	//"Parcela do Crédito de PIS/PASEP, vinculada a Receita Tributada no Mercado Interno"	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0613, cPictNUM })	//"Parcela do Crédito de PIS/PASEP, vinculada a Receita Não Tributada no Mercado Interno"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0614, cPictNUM })	//"Parcela do Crédito de PIS/PASEP, vinculada a Receita de Exportação"

	//REGISTRO 1200: CONTRIBUIÇÃO SOCIAL EXTEMPORÂNEA - PIS/PASEP
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "PA_ANT",	"C",	006,	0 } ) 	//"_PER_APUR_ANT"
	aAdd( aStru,{ "NC_REC",	"C",	002,	0 } ) 	//"_NAT_CONT_REC"
	aAdd( aStru,{ "VC_APUR",	"N",	014,	2 } ) 	//"_VL_CONT_APUR"
	aAdd( aStru,{ "VCPDESC",	"N",	014,	2 } ) 	//"_VL_CONT_APUR"
	aAdd( aStru,{ "VC_DEV",	"N",	014,	2 } ) 	//"_VL_CONT_DEV"
	aAdd( aStru,{ "VO_DED",	"N",	014,	2 } ) 	//"_VL_OUT_DED"
	aAdd( aStru,{ "VC_EXT",	"N",	014,	2 } ) 	//"_VL_CONT_EXT"
	aAdd( aStru,{ "VL_MUL",	"N",	014,	2 } ) 	//"_VL_MUL"
	aAdd( aStru,{ "VL_JUR",	"N",	014,	2 } ) 	//"_VL_JUR"
	aAdd( aStru,{ "DT_RECO",	"C",	008,	0 } ) 	//"_DT_RECOL"	
	aAdd( aStru,{ "RELAC2",	"C",	010,	0 } )	
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )		
	aAdd( aStrCmps,aStru )	
	
	CriaTMPReg(aStru,"RELAC2","1200",@aTrbs)		
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0615))	//"1200 - CONTRIBUIÇÃO SOCIAL EXTEMPORÂNEA - PIS/PASEP"	 
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0550, cPictChar })	// Período de Apuração da Contribuição Social Extemporânea (MMAAAA).
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0616, cPictChar })	//"Natureza da Contribuição a Recolher, conforme Tabela 4.3.5."
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0546, cPictNUM })	//"Valor da Contribuição Apurada"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0264, cPictNUM })	//Valor do Crédito de PIS/PASEP a Descontar, da Contribuição Social Extemporânea.
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0617, cPictNUM })	//"Valor da Contribuição Social Extemporânea Devida"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0618, cPictNUM })	//"Valor da Contribuição Social Extemporânea a pagar"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0619, cPictNUM })	//"Valor da Multa"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0620, cPictNUM })	//"Valor dos Juros"	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0621, cPictChar })	//"Data do Recolhimento"
    
	IncProc("Gerando estrutura...")

	//REGISTRO 1210: DETALHAMENTO DA CONTRIBUIÇÃO SOCIAL EXTEMPORÂNEA - PIS/PASEP
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "CNPJ",		"C",	020,	0 } ) 	//"_PER_APUR_ANT"
	aAdd( aStru,{ "CST_PIS",	"C",	002,	0 } ) 	//"_CST_PIS"
	aAdd( aStru,{ "COD_PAR",	"C",	060,	0 } ) 	//"_COD_PART"
	aAdd( aStru,{ "DT_OPER",	"C",	008,	0 } ) 	//"_DT_OPER"
	aAdd( aStru,{ "VL_OPER",	"N",	014,	2 } ) 	//"_VL_OPER"
	aAdd( aStru,{ "VBC_PIS",	"N",	014,	3 } ) 	//"_VL_BC_PIS"
	aAdd( aStru,{ "ALI_PIS",	"N",	006,	4 } ) 	//"_ALIQ_PIS"
	aAdd( aStru,{ "VL_PIS",	"N",	014,	2 } ) 	//"_VL_PIS"
	aAdd( aStru,{ "COD_CTA",	"C",	060,	2 } ) 	//"_COD_CTA"
	aAdd( aStru,{ "D_COMPL",	"C",	060,	0 } ) 	//"_DESC_COMPL"	
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )	
	
	CriaTMPReg(aStru,"RELAC3","1210",@aTrbs)	

	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0622))	//"1210 - DETALHAMENTO DA CONTRIBUIÇÃO SOCIAL EXTEMPORÂNEA - PIS/PASEP"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0024, cPictChar })	//Número de inscrição do estabelecimento no CNPJ (Campo 04 do Registro 0140).
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0155, cPictChar })	//Código da Situação Tributária referente ao PIS/PASEP, conforme a Tabela indicada no item 4.3.3.
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0116, cPictChar })	//Código do participante (Campo 02 do Registro 0150)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0370, cPictChar })	//Data da Operação (ddmmaaaa)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0371, cPictNUM })	//Valor da Operação
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0221, cPictChar })	//Base de cálculo do PIS/PASEP (em valor ou em quantidade)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0372, cPictALI2 })	//Alíquota da PIS (em percentual ou em reais)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0243, cPictNUM })	//Valor do PIS/PASEP
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0232, cPictChar })	//Código da conta analítica contábil debitada/creditada
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0200, cPictChar })	//Descrição complementar do Documento/Operação	
	
	//REGISTRO 1220: DEMONSTRAÇÃO DO CRÉDITO A DESCONTAR DA CONTRIBUIÇÃO EXTEMPORÂNEA - PIS/PASEP
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) //"_REG"
	aAdd( aStru,{ "PA_CRED",	"C",	006,	0 } ) //"_PER_APU_CRED"
	aAdd( aStru,{ "OR_CRED",	"C",	002,	0 } ) //"_ORIG_CRED"
	aAdd( aStru,{ "CO_CRED",	"C",	003,	0 } ) //"_COD_CRED"	
	aAdd( aStru,{ "VL_CRED",	"N",	014,	2 } ) //"_VL_CRED"	
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )		

	CriaTMPReg(aStru,"RELAC3","1220",@aTrbs)		

	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0623))	//"1220 - DEMONSTRAÇÃO DO CRÉDITO A DESCONTAR DA CONTRIBUIÇÃO EXTEMPORÂNEA - PIS/PASEP"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0472, cPictChar })	//Período de Apuração do Crédito (MM/AAAA)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0154, cPictChar })	//Indicador da origem do crédito:
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0595, cPictChar })	//Código do Tipo do Crédito, conforme Tabela 4.3.6.
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0548, cPictNUM })	//Valor do Crédito a Descontar	

	//REGISTRO 1300: CONTROLE DOS VALORES RETIDOS NA FONTE - PIS/PASEP
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) //"_REG"
	aAdd( aStru,{ "INA_RET",	"C",	002,	0 } ) //"_IND_NAT_RET"
	aAdd( aStru,{ "PRE_RET",	"C",	006,	0 } ) //"_PR_REC_RET"
	aAdd( aStru,{ "VRE_APU",	"N",	014,	2 } ) //"_VL_RET_APU"	
	aAdd( aStru,{ "VRE_DED",	"N",	014,	2 } ) //"_VL_RET_DED"	
	aAdd( aStru,{ "VRE_PER",	"N",	014,	2 } ) //"_VL_RET_PER"	
	aAdd( aStru,{ "VRE_DCO",	"N",	014,	2 } ) //"_VL_RET_DCOMP"			
	aAdd( aStru,{ "SLD_RET",	"N",	014,	2 } ) //"_VL_RET_DCOMP"	
	aAdd( aStru,{ "RELAC2",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )

	CriaTMPReg(aStru,"RELAC2","1300",@aTrbs)		

	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0624))	//"1300 - CONTROLE DOS VALORES RETIDOS NA FONTE - PIS/PASEP"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0454, cPictChar })	//Indicador de Natureza da Retenção na Fonte:
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0625, cPictChar })	//"Período do Recebimento e da Retenção (MM/AAAA)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0124, cPictNUM })	//Valor Total da Retenção
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0626, cPictNUM })	//"Valor da Retenção deduzida da Contribuição devida no período da escrituração e em períodos anteriores"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0627, cPictNUM })	//"Valor da Retenção utilizada mediante Pedido de Restituição"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0628, cPictNUM })	//"Valor da Retenção utilizada mediante Declaração de Compensação"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0629, cPictNUM })	//"Saldo de Retenção a utilizar em períodos de apuração futuros (04 - 05 - 06 - 07)"	

	//REGISTRO 1500: CONTROLE DE CRÉDITOS FISCAIS - COFINS
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) //"_REG"
	aAdd( aStru,{ "PEACRED",	"C",	002,	0 } ) //"_PER_APU_CRED"
	aAdd( aStru,{ "ORICRED",	"C",	006,	0 } ) //"_ORIG_CRED"
	aAdd( aStru,{ "CNPJSUC",	"C",	020,	2 } ) //"_CNPJ_SUC"	
	aAdd( aStru,{ "CODCRED",	"C",	006,	0 } ) //"_COD_CRED"	
	aAdd( aStru,{ "VCREAPU",	"N",	014,	2 } ) //"_VL_CRED_APU"	
	aAdd( aStru,{ "VCEXAPU",	"N",	014,	2 } ) //"_VL_CRED_EXT_APU"			
	aAdd( aStru,{ "VTCRAPU",	"N",	014,	2 } ) //"_VL_TOT_CRED_APU"	
	aAdd( aStru,{ "VCDPAAN",	"N",	014,	2 } ) //"_VL_CRED_DESC_PA_ANT"	
	aAdd( aStru,{ "VCPPANT",	"N",	014,	2 } ) //"_VL_CRED_PER_PA_ANT"	
	aAdd( aStru,{ "VCDPANT",	"N",	014,	2 } ) //"_VL_CRED_DCOMP_PA_ANT"	
	aAdd( aStru,{ "SCDIEFD",	"N",	014,	2 } ) //"_SD_CRED_DISP_EFD"	
	aAdd( aStru,{ "VCRDEFD",	"N",	014,	2 } ) //"_VL_CRED_DESC_EFD"	
	aAdd( aStru,{ "VCRPEFD",	"N",	014,	2 } ) //"_VL_CRED_PER_EFD"	
	aAdd( aStru,{ "VCRDCFD",	"N",	014,	2 } ) //"_VL_CRED_DCOMP_EFD"	
	aAdd( aStru,{ "VCTRANS",	"N",	014,	2 } ) //"_VL_CRED_TRANS"	
	aAdd( aStru,{ "VCREOUT",	"N",	014,	2 } ) //"_VL_CRED_OUT"	
	aAdd( aStru,{ "SCREFIM",	"N",	014,	2 } ) //"_SLD_CRED_FIM"		
	aAdd( aStru,{ "RELAC2",	"C",	010,	0 } )	
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )

	CriaTMPReg(aStru,"RELAC2","1500",@aTrbs)	

	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0630))	//"1500 - CONTROLE DE CRÉDITOS FISCAIS - COFINS"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0472, cPictChar })	//Período de Apuração do Crédito (MM/AAAA)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0154, cPictChar })	//Indicador da origem do crédito:
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0024, cPictCNPJ })	//CNPJ da pessoa jurídica cedente do crédito (se ORIG_CRED = 02).
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0595, cPictChar })	//Código do Tipo do Crédito, conforme Tabela 4.3.6.
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0596, cPictNUM })	//Valor do Crédito apurado na Escrituração Fiscal Digital ou em demonstrativo DACON de períodos anteriores.
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0597, cPictNUM })	//Valor de Crédito Extemporâneo Apurado (Registro 1501), referente a Período Anterior, Informado no Campo 02 - PER_APU_CRED
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0598, cPictNUM })	//Valor Total do Crédito Apurado (06 + 07)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0599, cPictNUM })	//Valor do Crédito utilizado mediante Desconto, em Período(s)  Anterior(es) 
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0600, cPictNUM })	//Valor do Crédito utilizado mediante Pedido de Ressarcimento, em Período(s) Anterior(es).
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0601, cPictNUM })	//Valor do Crédito utilizado mediante Declaração de Compensação Intermediária (Crédito de Exportação), em Período(s) Anterior(es)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0602, cPictNUM })	//Saldo do Crédito Disponível para Utilização neste Período de Escrituração (08-09-10-11)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0603, cPictNUM })	//Valor do Crédito descontado neste período de escrituração
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0604, cPictNUM })	//Valor do Crédito objeto de Pedido de Ressarcimento (PER) neste período de escrituração
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0605, cPictNUM })	//Valor do Crédito utilizado mediante Declaração de Compensação Intermediária neste período de escrituração
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0606, cPictNUM })	//Valor do crédito transferido em evento de cisão, fusão ou incorporação
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0607, cPictNUM })	//Valor do crédito utilizado por outras formas
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0608, cPictNUM })	//Saldo de créditos a utilizar em período de apuração futuro (12-13-14-15-16-17).

	//REGISTRO 1501: APURAÇÃO DE CRÉDITO EXTEMPORÂNEO - DOCUMENTOS E OPERAÇÕES DE PERÍODOS ANTERIORES - COFINS
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "C_P",		"C",	060,	0 } ) 	//"_COD_PART"
	aAdd( aStru,{ "C_ITEM",	"C",	060,	0 } ) 	//"_COD_ITEM"
	aAdd( aStru,{ "COD_MOD",	"C",	002,	0 } ) 	//"_COD_MOD"
	aAdd( aStru,{ "SER",		"C",	004,	0 } ) 	//"_SER"
	aAdd( aStru,{ "SUB_SER",	"C",	001,	0 } ) 	//"_SUB_SER"		
	aAdd( aStru,{ "NUM_DOC",	"C",	009,	0 } ) 	//"_VL_BC_PIS"
	aAdd( aStru,{ "DT_OPER",	"C",	008,	0 } ) 	//"_DT_OPER"
	aAdd( aStru,{ "CHV_NFE",	"C",	044,	0 } ) 	//"_CHV_NFE"	
	aAdd( aStru,{ "VL_OPER",	"N",	014,	2 } ) 	//"_VL_OPER"
	aAdd( aStru,{ "CFOP",		"C",	004,	0 } ) 	//"_CFOP"
	aAdd( aStru,{ "NB_CRED",	"C",	002,	0 } ) 	//"_NAT_BC_CRED"		
	aAdd( aStru,{ "IO_CRED",	"C",	001,	0 } ) 	//"_IND_ORIG_CRED"	
	aAdd( aStru,{ "CS_COFI",	"C",	002,	0 } ) 	//"_CST_COFINS"
	aAdd( aStru,{ "VB_COFI",	"N",	014,	3 } ) 	//"_VL_BC_COFINS"	
	aAdd( aStru,{ "AL_COFI",	"N",	014,	4 } ) 	//"_ALIQ_COFINS"
	aAdd( aStru,{ "VL_COFI",	"N",	014,	2 } ) 	//"_VL_COFINS"
	aAdd( aStru,{ "COD_CTA",	"C",	060,	0 } ) 	//"_COD_CTA"		
	aAdd( aStru,{ "COD_CCU",	"C",	060,	0 } ) 	//"_COD_CCUS"	
	aAdd( aStru,{ "DE_COMP",	"C",	060,	0 } ) 	//"_DESC_COMPL"		
	aAdd( aStru,{ "PE_ESCR",	"C",	006,	0 } ) 	//"_PER_ESCRIT"	
	aAdd( aStru,{ "CNPJ",		"C",	020,	0 } ) 	//"_CNPJ"			
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )

	CriaTMPReg(aStru,"RELAC3","1501",@aTrbs)		

	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0631))	//"1501 - APURAÇÃO DE CRÉDITO EXTEMPORÂNEO - DOCUMENTOS E OPERAÇÕES DE PERÍODOS ANTERIORES - COFINS"	 
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0116, cPictChar })	//"Código do participante"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0237, cPictChar })	//Código do item (campo 02 do Registro 0200)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0171, cPictChar })	//Código do modelo do documento fiscal, conforme a Tabela 4.1.1.
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0118, cPictChar })	//Série do documento fiscal
	aAdd( aTitulo[Len(aTitulo)][2],{ "" /*STR0119*/, cPictChar })	//Subsérie do documento fiscal
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0172, cPictChar })	//Número do documento fiscal
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0370, cPictChar })	//"Data da Operação (ddmmaaaa)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0173, cPictChar })	//"Chave da Nota Fiscal Eletrônica"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0371, cPictNUM })	//Valor da Operação
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0206, cPictChar })	//Código fiscal de operação e prestação	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0493, cPictChar })	//Código da Base de Cálculo do Crédito, conforme a Tabela indicada no item 4.3.7.
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0154, cPictChar })	//Indicador da origem do crédito:
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0226, cPictChar })	//Código da Situação Tributária referente ao COFINS, conforme a Tabela indicada no item 4.3.4.
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0229, cPictNUM })	//Base de Cálculo do Crédito de COFINS (em valor ou em quantidade)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0373, cPictALI2 })	//Alíquota do COFINS (em percentual ou em reais)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0231, cPictNUM })	//Valor do Crédito de COFINS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0447, cPictChar })	//Código da conta analítica contábil debitada/creditada.
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0164, cPictChar })	//Código do Centro de Custos.
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0200, cPictChar })	//Descrição complementar do Documento/Operação.
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0610, cPictChar })	//"Mês/Ano da Escrituração em que foi registrado o documento/operação (Crédito pelo método da Apropriação Direta)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0024, cPictCNPJ })	//CNPJ do estabelecimento gerador do crédito extemporâneo (Campo 04  do Registro 0140)		

	//REGISTRO 1502: DETALHAMENTO DO CRÉDITO EXTEMPORÂNEO VINCULADO A MAIS DE UM TIPO DE RECEITA - COFINS
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "VCCT_MI",	"N",	014,	2 } ) 	//"_VL_CRED_COFINS_TRIB_MI"
	aAdd( aStru,{ "VCCN_MI",	"N",	014,	2 } ) 	//"_VL_CRED_COFINS_NT_MI"
	aAdd( aStru,{ "VCC_EXP",	"N",	014,	2 } ) 	//"_VL_CRED_COFINS_EXP"
	aAdd( aStru,{ "RELAC4",	"C",	010,	0 } )
	aAdd( aStrCmps,aStru ) 
	
	CriaTMPReg(aStru,"RELAC4","1502",@aTrbs)		

	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0650))	//"1502 - DETALHAMENTO DO CRÉDITO EXTEMPORÂNEO VINCULADO A MAIS DE UM TIPO DE RECEITA - COFINS"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0632, cPictNUM })	//"Parcela do Crédito de COFINS, vinculada a Receita Tributada no Mercado Interno"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0633, cPictNUM })	//"Parcela do Crédito de COFINS, vinculada a Receita Não Tributada no Mercado Interno"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0634, cPictNUM })	//"Parcela do Crédito de COFINS, vinculada a Receita de Exportação"	

	//REGISTRO 1600: CONTRIBUIÇÃO SOCIAL EXTEMPORÂNEA - COFINS
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "PA_ANT",	"C",	006,	0 } ) 	//"_PER_APUR_ANT"
	aAdd( aStru,{ "NC_REC",	"C",	002,	0 } ) 	//"_NAT_CONT_REC"
	aAdd( aStru,{ "VC_APUR",	"N",	014,	2 } ) 	//"_VL_CONT_APUR"
	aAdd( aStru,{ "VCPDESC",	"N",	014,	2 } ) 	//"_VL_CRED_COFINS_DESC"
	aAdd( aStru,{ "VC_DEV",	"N",	014,	2 } ) 	//"_VL_CONT_DEV"
	aAdd( aStru,{ "VO_DED",	"N",	014,	2 } ) 	//"_VL_OUT_DED"
	aAdd( aStru,{ "VC_EXT",	"N",	014,	2 } ) 	//"_VL_CONT_EXT"
	aAdd( aStru,{ "VL_MUL",	"N",	014,	2 } ) 	//"_VL_MUL"
	aAdd( aStru,{ "VL_JUR",	"N",	014,	2 } ) 	//"_VL_JUR"
	aAdd( aStru,{ "DT_RECO",	"C",	008,	0 } ) 	//"_DT_RECOL"	
	aAdd( aStru,{ "RELAC2",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )
	
	CriaTMPReg(aStru,"RELAC2","1600",@aTrbs)			
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0635))	//"1600 - CONTRIBUIÇÃO SOCIAL EXTEMPORÂNEA - COFINS"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0550, cPictChar })	// Período de Apuração da Contribuição Social Extemporânea (MMAAAA).
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0616, cPictChar })	//"Natureza da Contribuição a Recolher, conforme Tabela 4.3.5."
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0546, cPictNUM })	//"Valor da Contribuição Apurada"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0636, cPictNUM })	//"Valor do Crédito de COFINS a Descontar, da Contribuição Social Extemporânea"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0617, cPictNUM })	//"Valor da Contribuição Social Extemporânea Devida"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0637, cPictNUM })	//"Valor de Outras Deduções"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0618, cPictNUM })	//"Valor da Contribuição Social Extemporânea a pagar"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0619, cPictNUM })	//"Valor da Multa"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0620, cPictNUM })	//"Valor dos Juros"	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0621, cPictChar })	//"Data do Recolhimento"	

	//REGISTRO 1610: DETALHAMENTO DA CONTRIBUIÇÃO SOCIAL EXTEMPORÂNEA - COFINS
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "CNPJ",		"C",	020,	0 } ) 	//"_CNPJ"
	aAdd( aStru,{ "CST_COF",	"C",	002,	0 } ) 	//"_CST_COFINS"
	aAdd( aStru,{ "CO_PART",	"C",	060,	0 } ) 	//"_COD_PART"
	aAdd( aStru,{ "DT_OPER",	"C",	008,	0 } ) 	//"_DT_OPER"
	aAdd( aStru,{ "VL_OPER",	"N",	014,	2 } ) 	//"_VL_OPER"		
	aAdd( aStru,{ "VB_COFI",	"N",	014,	2 } ) 	//"_VL_BC_COFINS"
	aAdd( aStru,{ "AL_COFI",	"N",	014,	4 } ) 	//"_ALIQ_COFINS"
	aAdd( aStru,{ "VL_COFI",	"N",	014,	2 } ) 	//"_VL_COFINS"	
	aAdd( aStru,{ "COD_CTA",	"C",	060,	0 } ) 	//"_COD_CTA"
	aAdd( aStru,{ "DE_COMP",	"C",	060,	0 } ) 	//"_CFOP"
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )
	aAdd( aStrCmps,aStru )

	CriaTMPReg(aStru,"RELAC3","1610",@aTrbs)		

	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0638))	//"1610 - DETALHAMENTO DA CONTRIBUIÇÃO SOCIAL EXTEMPORÂNEA - COFINS"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0024, cPictChar })	//Número de inscrição do estabelecimento no CNPJ (Campo 04 do Registro 0140).
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0226, cPictChar })	//Código da Situação Tributária referente a COFINS, conforme a Tabela indicada no item 4.3.4.
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0116, cPictChar })	//Código do participante (Campo 02 do Registro 0150)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0370, cPictChar })	//Data da Operação (ddmmaaaa)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0371, cPictNUM })	//Valor da Operação
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0160, cPictNUM })	//Base de cálculo da COFINS (em valor ou em quantidade)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0373, cPictALI2 })	//Alíquota da COFINS (em percentual ou em reais)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0162, cPictNUM })	//Valor da COFINS
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0232, cPictChar })	//Código da conta analítica contábil debitada/creditada
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0150, cPictChar })	//Descrição complementar do Documento/Operação	

	//REGISTRO 1620: DEMONSTRAÇÃO DO CRÉDITO A DESCONTAR DA CONTRIBUIÇÃO EXTEMPORÂNEA - COFINS
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) //"_REG"
	aAdd( aStru,{ "PA_CRED",	"C",	006,	0 } ) //"_PER_APU_CRED"
	aAdd( aStru,{ "OR_CRED",	"C",	002,	0 } ) //"_ORIG_CRED"
	aAdd( aStru,{ "CO_CRED",	"C",	003,	0 } ) //"_COD_CRED"	
	aAdd( aStru,{ "VL_CRED",	"N",	014,	2 } ) //"_VL_CRED"	
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )

	CriaTMPReg(aStru,"RELAC3","1620",@aTrbs)		

	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0639))	//"1620 - DEMONSTRAÇÃO DO CRÉDITO A DESCONTAR DA CONTRIBUIÇÃO EXTEMPORÂNEA - COFINS"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0472, cPictChar })	//Período de Apuração do Crédito (MM/AAAA)
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0154, cPictChar })	//Indicador da origem do crédito:
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0595, cPictChar })	//Código do Tipo do Crédito, conforme Tabela 4.3.6.
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0548, cPictNUM })	//Valor do Crédito a Descontar		

	//REGISTRO 1700: CONTROLE DOS VALORES RETIDOS NA FONTE - COFINS
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) //"_REG"
	aAdd( aStru,{ "INA_RET",	"C",	002,	0 } ) //"_IND_NAT_RET"
	aAdd( aStru,{ "PRE_RET",	"C",	006,	0 } ) //"_PR_REC_RET"
	aAdd( aStru,{ "VRE_APU",	"C",	014,	2 } ) //"_VL_RET_APU"	
	aAdd( aStru,{ "VRE_DED",	"N",	014,	2 } ) //"_VL_RET_DED"	
	aAdd( aStru,{ "VRE_PER",	"N",	014,	2 } ) //"_VL_RET_PER"	
	aAdd( aStru,{ "VRE_DCO",	"N",	014,	2 } ) //"_VL_RET_DCOMP"			
	aAdd( aStru,{ "SLD_RET",	"N",	014,	2 } ) //"_SLD_RET"	
	aAdd( aStru,{ "RELAC2",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )

	CriaTMPReg(aStru,"RELAC2","1700",@aTrbs)		

	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0640))	//"1700 - CONTROLE DOS VALORES RETIDOS NA FONTE - COFINS"	
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0454, cPictChar })	//Indicador de Natureza da Retenção na Fonte:
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0625, cPictChar })	//"Período do Recebimento e da Retenção (MM/AAAA)"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0124, cPictChar })	//Valor Total da Retenção
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0626, cPictNUM })	//"Valor da Retenção deduzida da Contribuição devida no período da escrituração e em períodos anteriores"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0627, cPictNUM })	//"Valor da Retenção utilizada mediante Pedido de Restituição"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0628, cPictNUM })	//"Valor da Retenção utilizada mediante Declaração de Compensação"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0629, cPictNUM })	//"Saldo de Retenção a utilizar em períodos de apuração futuros (04 - 05 - 06 - 07)"		

	//REGISTRO 1800: INCORPORAÇÃO IMOBILIÁRIA - RET
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) //"_REG"
	aAdd( aStru,{ "INC_IMO",	"C",	090,	0 } ) //"_INC_IMOB"
	aAdd( aStru,{ "RRE_RET",	"N",	014,	2 } ) //"_REC_RECEB_RET"
	aAdd( aStru,{ "RFI_RET",	"N",	014,	2 } ) //"_REC_FIN_RET"	
	aAdd( aStru,{ "BC_RET",	"N",	014,	2 } ) //"_BC_RET"	
	aAdd( aStru,{ "ALI_RET",	"N",	006,	4 } ) //"_ALIQ_RET"	
	aAdd( aStru,{ "VRE_UNI",	"N",	014,	2 } ) //"_VL_REC_UNI"			
	aAdd( aStru,{ "DTR_UNI",	"C",	008,	0 } ) //"_DT_REC_UNI"	
	aAdd( aStru,{ "COD_REC",	"C",	004,	0 } ) //"_COD_REC"	
	aAdd( aStru,{ "RELAC2",	"C",	010,	0 } )	
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )

	CriaTMPReg(aStru,"RELAC2","1800",@aTrbs)	
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0648))	//"1800 - INCORPORAÇÃO IMOBILIÁRIA - RET"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0641, cPictChar })	//"Empreendimento objeto de Incorporação Imobiliária, optante pelo RET"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0642, cPictNUM })	//"Receitas recebidas pela incorporadora na venda das unidades imobiliárias que compõem a incorporação"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0643, cPictNUM })	//"Receitas Financeiras e Variações Monetárias decorrentes das vendas submetidas ao RET"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0644, cPictNUM })	//"Base de Cálculo do Recolhimento Unificado"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0645, cPictALI2 })	//"Alíquota do Recolhimento Unificado"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0646, cPictNUM })	//"Valor do Recolhimento Unificado"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0647, cPictChar })	//"Data do recolhimento unificado"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0458, cPictChar })	//Código da Receita			
	
	//REGISTRO 1809: PROCESSO REFERENCIADO 
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "NUM_PR",	"C",	020,	0 } ) 	//"_NUM_PROC"
	aAdd( aStru,{ "IND_PR",	"C",	001,	0 } ) 	//"_IND_PROC"
	aAdd( aStru,{ "RELAC3",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )	
	
	CriaTMPReg(aStru,"RELAC3","1809",@aTrbs)	
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0649))	//"1809 - PROCESSO REFERENCIADO"	
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0138, cPictChar })	//"Identificação do processo ou ato concessório"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0139, cPictChar })	//"Origem do processo"	
	
	//REGISTRO 1900: CONSOLIDAÇÃO DOS DOCUMENTOS EMITIDOS NO PERÍODO POR PESSOA JURÍDICA SUBMETIDA AO REGIME DE TRIBUTAÇÃO COM BASE NO LUCRO PRESUMIDO - REGIME DE CAIXA OU DE COMPETÊNCIA
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) 	//"_REG"
	aAdd( aStru,{ "CNPJ",		"C",	020,	0 } ) 	//"_CNPJ"
	aAdd( aStru,{ "COD_MOD",	"C",	002,	0 } ) 	//"_COD_MOD"
	aAdd( aStru,{ "SER",		"C",	004,	0 } ) 	//"_SER"
	aAdd( aStru,{ "SUB_SER",	"C",	001,	0 } ) 	//"_SUB_SER"
	aAdd( aStru,{ "COD_SIT",	"C",	002,	0 } ) 	//"_COD_SIT"
	aAdd( aStru,{ "VTO_REC",	"N",	014,	2 } ) 	//"_VL_TOT_REC"
	aAdd( aStru,{ "QUA_DOC",	"N",	014,	2 } ) 	//"_QUANT_DOC"
	aAdd( aStru,{ "CST_PIS",	"C",	002,	0 } ) 	//"_CST_PIS"
	aAdd( aStru,{ "CST_COF",	"C",	002,	0 } ) 	//"_CST_COFINS"
	aAdd( aStru,{ "CFOP",		"C",	004,	0 } ) 	//"_CFOP"
	aAdd( aStru,{ "INF_COM",	"C",	060,	0 } ) 	//"_INF_COMPL"
	aAdd( aStru,{ "COD_CTA",	"C",	060,	0 } ) 	//"_COD_CTA"				
	aAdd( aStru,{ "RELAC2",	"C",	010,	0 } )	
	aAdd( aStrCmps,aStru )		

	CriaTMPReg(aStru,"RELAC2","1900",@aTrbs)	
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0653))	//"1900 - CONSOLIDAÇÃO DOS DOCUMENTOS EMITIDOS NO PERÍODO POR PESSOA JURÍDICA SUBMETIDA AO REGIME DE TRIBUTAÇÃO COM BASE NO LUCRO PRESUMIDO - REGIME DE CAIXA OU DE COMPETÊNCIA"	
 	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0024, cPictCNPJ })	//CNPJ do estabelecimento da pessoa jurídica, emitente dos documentos geradores de receita
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0171, cPictChar })	//Código do modelo do documento fiscal conforme a Tabela 4.1.1, ou:
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0118, cPictChar })	//Série do documento fiscal
	aAdd( aTitulo[Len(aTitulo)][2],{ "" /*STR0119*/, cPictChar })	//Subserie do documento fiscal
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0117, cPictChar })	//Código da situação do documento fiscal:
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0651, cPictNUM })	//"Valor total da receita, conforme os documentos emitidos no período, representativos da venda de bens e serviços"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0652, cPictNUM })	//"Quantidade total de documentos emitidos no período"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0220, cPictChar })	//Código da Situação Tributária do PIS/Pasep 
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0226, cPictChar })	//Código da Situação Tributária da Cofins
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0206, cPictChar })	//Código fiscal de operação e prestação
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0136, cPictChar })	//Informações complementares
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0447, cPictChar })	//Código da conta analítica contábil representativa da receita	

	//REGISTRO 1990: ENCERRAMENTO DO BLOCO 1
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) //"_REG"
	aAdd( aStru,{ "Q_LIN0",	"N",	010,	0 } ) //"_QTD_LIN_0"	
	aAdd( aStru,{ "RELAC",		"C",	010,	0 } )
	aAdd( aStrCmps,aStru )
	
	CriaTMPReg(aStru,"RELAC","1990",@aTrbs)	
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0654))	//"1990: ENCERRAMENTO DO BLOCO 1"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0655, cPictChar })	//"Quantidade total de linhas do Bloco 1"               
	
	//REGISTRO 9001: ABERTURA DO BLOCO 9
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) //"_REG"
	aAdd( aStru,{ "IND_MO",	"C",	003,	0 } ) //"_IND_MOV"
	aAdd( aStru,{ "RELAC",		"C",	010,	0 } )
	aAdd( aStru,{ "RELAC2",	"C",	010,	0 } )
	aAdd( aStrCmps,aStru )
	
	CriaTMPReg(aStru,"RELAC","9001",@aTrbs)	
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0656))	//"9001 - ABERTURA DO BLOCO 9"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0031, cPictChar })	//"Movimento"	

    //REGISTRO 9900: REGISTROS DO ARQUIVO
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) //"_REG"
	aAdd( aStru,{ "REG_BLC",	"C",	004,	0 } ) //"_REG_BLC"
	aAdd( aStru,{ "QTDRBLC",	"N",	014,	0 } ) //"_REG_BLC"	
	aAdd( aStru,{ "RELAC2",	"C",	010,	0 } )
	aAdd( aStrCmps,aStru )
	
	CriaTMPReg(aStru,"RELAC2","9900",@aTrbs)	
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0657))	//"9900 - REGISTROS DO ARQUIVO"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0658, cPictChar })	//"Registro que será totalizado no próximo campo"	
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0659, cPictChar })	//"Total de registros do tipo informado no campo anterior"

	//REGISTRO 9990: ENCERRAMENTO DO BLOCO 9
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) //"_REG"
	aAdd( aStru,{ "Q_LIN9",	"N",	010,	0 } ) //"_QTD_LIN_0"	
	aAdd( aStru,{ "RELAC",		"C",	010,	0 } )
	aAdd( aStrCmps,aStru )
	
	CriaTMPReg(aStru,"RELAC","9990",@aTrbs)	
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0660))	//"9990 - ENCERRAMENTO DO BLOCO 9"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0661, cPictChar })	//"Quantidade total de linhas do Bloco 9"
	
	IncProc("Gerando estrutura...")    

	//REGISTRO 9999: ENCERRAMENTO DO ARQUIVO DIGITAL
	
	aStru	:=	{}
	aAdd( aStru,{ "REG",		"C",	004,	0 } ) //"_REG"
	aAdd( aStru,{ "Q_LIN9",	"N",	009,	0 } ) //"_QTD_LIN_9"	
	aAdd( aStru,{ "RELAC",		"C",	010,	0 } )
	aAdd( aStrCmps,aStru )
	
	CriaTMPReg(aStru,"RELAC","9999",@aTrbs)	
	
	aAdd( aTitulo, {})
	aAdd( aTitulo[Len(aTitulo)], OemToAnsi(STR0662))	//"9999 - ENCERRAMENTO DO ARQUIVO DIGITAL"
	aAdd( aTitulo[Len(aTitulo)], {})
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0016, cPictChar })	//"Registro"
	aAdd( aTitulo[Len(aTitulo)][2],{ STR0663, cPictChar })	//"Quantidade total de linhas do arquivo digital"
	
Else
	nArqVal	:=	2
EndIf

Return( aTrbs )


//-------------------------------------------------------------------
/*/{Protheus.doc} RetCmpSnt
	
Função que retorna os campos do registro formatado em array

@param 	cLinha   	-> Linha do arquivo que está sendo processado

		
@Return aLinha		-> Array com os valores do registro formatado em array.
			
@author Erick Dias 
@since  09/12/2013
@version 11.80
/*/
//-------------------------------------------------------------------
Static Function RetCmpSnt( cLinha )

Local nPos		:= At("|",SubStr(cLinha,1,Len(cLinha))) 
Local cField	:= ""
Local aLinha	:= {}

cLinha	:= SubStr(cLinha,nPos+1,Len(cLinha))
nPos	:= At("|",SubStr(cLinha,1,Len(cLinha))) 
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Montando array com os campos do registro ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
While nPos > 0
	cField := SubStr(cLinha,1,nPos-1)
	aAdd(aLinha,StrTran(AllTrim(cField),",","."))
	cLinha := SubStr(cLinha,nPos+1,Len(cLinha))
	nPos  := At("|",SubStr(cLinha,1,Len(cLinha)))
EndDo

If Len(cLinha) > 0
	aAdd(aLinha,StrTran(AllTrim(cField),",","."))
EndIf
  
Return( aLinha )

//-------------------------------------------------------------------
/*/{Protheus.doc} SntCriaTab
	
Função que cria tabelas temporárias para impressão do relatório Sintético

@param 	cPeríodo   	-> Objeto TREPORT

		
@Return
			
@author Erick Dias 
@since  09/12/2013
@version 11.80
/*/
//-------------------------------------------------------------------

Static Function SntCriaTab()

Local aCmp	:= {}
Local cArq	:= ""

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³RECE- Tabela da composição da receita   ³
//³RETE- Tabela da composição de retenção  ³
//³APUN- Tabela da apuração não cumulativa ³
//³APUC- Tabela da apuração cumulativa     ³
//³DEBI- Tabela da composição dos débitos  ³
//³CRED- Tabela da composição dos créditos ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Tabela Temporária das Receitas                                          ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
aCmp:={{"RTNC"    ,"N", 14,2},;	//Receita Tributada Não Cumulativa
{"RNT"  	 		,"N", 14,2},;	//Receita Não Tributada
{"RE"   			,"N", 14,2},;	//Receita de Exportação
{"RC"       		,"N", 14,2},;	//Receita Cumulativa
{"TotalR"      	,"N", 14,2},;	//Total Receitas
{"RecSer"			,"N", 14,2},;	//Receita Serviços
{"RecMer"			,"N", 14,2},;	//Receitas Mercadorias
{"RecTrans"		,"N", 14,2},;	//Receitas Transporte
{"OutRec"			,"N", 14,2},;	//Outras Receitas
{"InstFin"			,"N", 14,2},;	//Instituicoes Financeiras
{"TotalD"			,"N", 14,2},;	//Total Detalhamento das Receitas
{"Bloco"			,"C", 1,0}}	//Bloco do Registro
cArq := CriaTrab(aCmp)
dbUseArea(.T.,__LocalDriver, cArq, "RECE")
IndRegua("RECE",cArq,"Bloco")

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Tabela Temporária das Retenções                                         ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
aCmp:={{"INDRET"  ,"C", 02,0},;	//Indicador de Retenção
{"VLRPIS"			,"N", 14,2},;	//valor da retencao PIS
{"VLRCOF"			,"N", 14,2}}	//Valor da Retenção COFINS
cArq := CriaTrab(aCmp)
dbUseArea(.T.,__LocalDriver, cArq, "RETE")
IndRegua("RETE",cArq,"INDRET")

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Tabela Temporária da Apuração Não Cumulativo                            ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
aCmp:={{"TRIB"    ,"C", 01,0},;	//Tributo 1-PIS 2-COFINS
{"VLRDEB"			,"N", 14,2},;	//Valor do Débito
{"VLRCREDPER"		,"N", 14,2},;	//Valor do Crédito do Período
{"VLRCREDANT"		,"N", 14,2},;	//Valor do Crédito Período anterior
{"VLRRET"			,"N", 14,2},;	//Valor da Retenção
{"VLROUTDED"		,"N", 14,2},;	//Valor de Outras Deduções
{"VLRPAG"			,"N", 14,2},;	//VAlor a Pagar
{"FOLHASAL"		,"N", 14,2},;	//Pis Folha de salário
{"CREDPROX"		,"N", 14,2}}	//Crédito para Próximo Período.
cArq := CriaTrab(aCmp)
dbUseArea(.T.,__LocalDriver, cArq, "APUN")
IndRegua("APUN",cArq,"TRIB")

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Tabela Temporária da Apuração Cumulativa                                ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
aCmp:={{"TRIB"    ,"C", 01,0},;	//Tributo 1-PIS 2-COFINS
{"VLRDEB"			,"N", 14,2},;	//Valor do Débito
{"VLRRET"			,"N", 14,2},;	//Valor da Retenção
{"VLROUTDED"		,"N", 14,2},;	//Valor de Outras Deduções
{"VLRPAG"			,"N", 14,2},;	//VAlor a Pagar
{"FOLHASAL"		,"N", 14,2}}	//Pis Folha Salário
cArq := CriaTrab(aCmp)
dbUseArea(.T.,__LocalDriver, cArq, "APUC")
IndRegua("APUC",cArq,"TRIB")

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Tabela Temporária Composição Débitos                                    ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
aCmp:={{"COD"     	,"C", 02,0},;	//Código Contribuição
{"TRIB"			,"C", 01,0},;	//Base de Cálculo
{"BASECALC"		,"N", 14,3},;	//Base de Cálculo
{"ALIQ"			,"C", 9,0},;	//Alíquota
{"NALIQ"			,"N", 8,4},;	//Alíquota
{"VLCONTRIB"		,"N", 14,2},;	//Valor de Contribuição
{"ACRESCIMO"		,"N", 14,2},;	//Valor de Acréscimo
{"REDUCAO"			,"N", 14,2},;	//Valor de Redução
{"DIFER"			,"N", 14,2},;	//Valor Diferimento
{"DIFERANT"		,"N", 14,2},;	//Valor Diferimento período anterior
{"DEBAPUR"			,"N", 14,2}}	//Valor de Débito para apuração
cArq := CriaTrab(aCmp)
dbUseArea(.T.,__LocalDriver, cArq, "DEBI")
IndRegua("DEBI",cArq,"TRIB+COD+ALIQ")

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Tabela Temporária Composição Créditos                                   ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
aCmp:={{"COD"     	,"C", 03,0},;	//Código Crédito
{"TRIB"			,"C", 01,0},;	//Tributo 1-Pis 2-Cofins
{"ALIQ"			,"C", 9,0},;	//Alíquota
{"NALIQ"			,"N", 8,4},;	//Alíquota
{"BASECALC"		,"N", 14,2},;	//Crédito Não Cumulativo
{"CREDNC"			,"N", 14,2},;	//Crédito Não Cumulativo
{"CREDDISP"		,"N", 14,2},;	//Crédito Disponível
{"ACRESCIMO"		,"N", 14,2},;	//Valor de acréscimo
{"REDUCAO"			,"N", 14,2},;	//Valor de redução
{"CREDDIF"			,"N", 14,2},;	//Valor do crédito diferido
{"CREDAPUR"		,"N", 14,2}}	//Valor de Crédito para apuração
cArq := CriaTrab(aCmp)
dbUseArea(.T.,__LocalDriver, cArq, "CRED")
IndRegua("CRED",cArq,"TRIB+COD+ALIQ")

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Tabela Temporária Saldos de Créditos                                    ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
aCmp:={{"TRIB"    ,"C", 01,0},;	//Tributo 1-Pis 2-Cofins
{"PER"				,"C", 07,0},;	//Período
{"COD"				,"C", 03,0},;	//Código do Crédito
{"CREDPER"			,"N", 14,2},;	//Crédito do Período
{"CREDUTI"			,"N", 14,2},;	//Crédito utilizado
{"SALDO"			,"N", 14,2}}	//Valor de Crédito para apuração

cArq := CriaTrab(aCmp)
dbUseArea(.T.,__LocalDriver, cArq, "SCRE")
IndRegua("SCRE",cArq,"TRIB+PER+COD")

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Tabela Temporária Saldos de Retenções                                   ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
aCmp:={{"TRIB"    ,"C", 01,0},;	//Tributo 1-Pis 2-Cofins
{"PER"				,"C", 07,0},;	//Período
{"INDNAT"			,"C", 02,0},;	//Período
{"VLRET"			,"N", 14,2},;	//Crédito do Período
{"VLRETUTI"		,"N", 14,2},;	//Crédito utilizado
{"SALDO"			,"N", 14,2}}	//Valor de Crédito para apuração

cArq := CriaTrab(aCmp)
dbUseArea(.T.,__LocalDriver, cArq, "SRET")
IndRegua("SRET",cArq,"TRIB+PER+INDNAT")


//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Tabela Temporária Detalhamento Base de Cálculo do Crédito               ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
aCmp:={{"TRIB"    ,"C", 01,0},;	//Tributo 1-Pis 2-Cofins
{"CODBCC"			,"C", 02,0},;	//Código da base de cálculo do crédito
{"BASECALC"		,"N", 14,2},;	//Valor da Base de Cálculo
{"BASECALCQT"		,"N", 14,3}}	//Valor da Base de Cálculo em quantidade

cArq := CriaTrab(aCmp)
dbUseArea(.T.,__LocalDriver, cArq, "BASC")
IndRegua("BASC",cArq,"TRIB+CODBCC")


Return

//-------------------------------------------------------------------
/*/{Protheus.doc} SntArq
	
Função que irá percorrer o arquivo e gravar as informações nas tabelas temporárias

@param 	cFile   	-> Caminho do arquivo texto que será processado

		
@Return
			
@author Erick Dias 
@since  09/12/2013
@version 11.80
/*/
//-------------------------------------------------------------------


//-------------------------------------------------------------------
/*/{Protheus.doc} ProcArqSnt
	
Função que irá percorrer arquivo texto e irá fazer verificações e gravação nas tabelas
Auxiliares.

@param 	aCmps   	-> Array com valores e informações do registro do arquivo texto.
		
@Return
			
@author Erick Dias 
@since  09/12/2013
@version 11.80
/*/
//-------------------------------------------------------------------
Static Function ProcArqSnt(cFile,cPer,lEnd)
	
Local cBloco		:= ""
Local nValor		:= 0
Local nLinha		:= 0
Local cTrib		:= ""
Local cAliq		:= ""
Local cRegime		:= ""
Local cIndRegime	:= ""
Local aCmps		:= {} 
Local aCmp     	:= ""
Local cArq     	:= ""
Local cAliasTXT	:= "TXT"
Local cSubStr		:= "" 

aCmp:={{"TEXTO"    ,"C", 300,0}}

Conout("Início TXTA	 ####" + time())	
cArq := CriaTrab(aCmp)
dbUseArea(.T.,, cArq, "TXTA")

Append From &cFile  SDF


cArq := CriaTrab(aCmp)
dbUseArea(.T.,__LocalDriver, cArq, "TXT")

Append From "TXTA" For SubStr(TXTA->TEXTO,2,4) $ "0000/0110/0111/A100/C100/C180/C380/C481/C491/C601/D200/D300/D350/D600/F100/0111/F600/M210/M610/M105/M505/M100/M500/M200/M600/1100/1500/1300/1700/I100"    
(cAliasTXT)->(DBGoTop ())
ProcRegua((cAliasTXT)->(RecCount()))
While !(cAliasTXT)->(Eof ())	
	nLinha++
	IncProc(STR0687 + STR0688+ Str(nLinha)) 
	If Interrupcao(lEnd)
	    Return 
	EndIf
	
	cSubStr	:= SubStr((cAliasTXT)->TEXTO,2,4)	
	If cSubStr$ "0000"
		aCmps	:=	RetCmpSnt( (cAliasTXT)->TEXTO)		
		cPer:= 	MesExtenso(SubStr(aCmps[6],3,2)) + " de " + SubStr(aCmps[6],5,4)
	ElseIf cSubStr$ "0110"
		aCmps		:=	RetCmpSnt( (cAliasTXT)->TEXTO )
		cRegime	:= aCmps[2]
		If Len(aCmps) >=5
			cIndRegime:= aCmps[5] 
		EndIf	
	ElseIf cSubStr$ "0111/A100/C100/C180/C380/C481/C491/C601/D200/D300/D350/D600/F100"
		cBloco	:= ""
		nValor	:= 0
		aCmps	:=	RetCmpSnt( (cAliasTXT)->TEXTO )
		
		If cSubStr$ "0111"
			//Valores de receita registro 0111
			RecLock("RECE",.T.)
			RECE->BLOCO	:= "1"
			RECE->RTNC		:= Val(aCmps[2])
			RECE->RNT		:= Val(aCmps[3])
			RECE->RE		:= Val(aCmps[4])
			RECE->RC		:= Val(aCmps[5])
			RECE->TotalR	:= Val(aCmps[6])		
			MSUnLock()		
					
		ElseIf cSubStr$ "A100"
			//Valores de receita do bloco A	
			If aCmps[2] == "1" .And. aCmps[5] == "00"  //Verifica se é prestação de serviço e não está cancelado 
				cBloco	:= "A"
				nValor	:= Val(aCmps[12])
			EndIf
		ElseIf cSubStr$ "C100"	
			If aCmps[2] == "1" .And. aCmps[6] == "00"  //Verifica se é saída e é um documento regular				
				cBloco	:= "C"
				nValor	:= Val(aCmps[12])			
			EndIf
	
		ElseIf cSubStr$ "C180"	
			cBloco	:= "C"
			nValor	:= Val(aCmps[8])
	
		ElseIf cSubStr$ "C380"	
			cBloco	:= "C"
			nValor	:= Val(aCmps[7])		
			
		ElseIf cSubStr$ "C481"	
			cBloco	:= "C"
			nValor	:= Val(aCmps[7])
	 
		ElseIf cSubStr$ "C491"	
			cBloco	:= "C"
			nValor	:= Val(aCmps[5])		
			
		ElseIf cSubStr$ "C601"	
			cBloco	:= "C"
			nValor	:= Val(aCmps[3])		
	
		ElseIf cSubStr$ "D200"	
			cBloco	:= "D"
			nValor	:= Val(aCmps[10])	
	
		ElseIf cSubStr$ "D300"	
			cBloco	:= "D"
			nValor	:= Val(aCmps[10])		
	
		ElseIf cSubStr$ "D350"	
			cBloco	:= "D"
			nValor	:= Val(aCmps[10])		
	
		ElseIf cSubStr$ "D600"	
			cBloco	:= "D"
			nValor	:= Val(aCmps[10])
	
		ElseIf cSubStr$ "F100"	
			If aCmps[2] == "1"
				cBloco	:= "F"
				nValor	:= Val(aCmps[6])
			EndIf		

		ElseIf cSubStr$ "I100"
			cBloco	:= "I"
			nValor	:= Val(aCmps[2])
		EndIf	
		
		If nValor > 0
			If RECE->(MsSeek(cBloco))
				RecLock("RECE",.F.)
			Else
				RecLock("RECE",.T.)
				RECE->BLOCO	:= cBloco
			EndIf
			
			If cBloco == "A"
				RECE->RecSer += nValor			
			ElseIf cBloco == "C"
				RECE->RecMer += nValor			
			ElseIf cBloco == "D"
				RECE->RecTrans += nValor			
			ElseIf cBloco == "F"
				RECE->OUTREC += nValor			
			ElseIf cBloco == "I"
				RECE->InstFin += nValor			
			EndIf
			RECE->TotalD	+= nValor
			MSUnLock()
		EndIf				
		
	ElseIf cSubStr== "F600"
		aCmps	:=	RetCmpSnt( (cAliasTXT)->TEXTO )
		If !Empty(aCmps[2])
			If RETE->(MsSeek(aCmps[2]))
				RecLock("RETE",.F.)
			Else
				RecLock("RETE",.T.)
				RETE->INDRET	:= aCmps[2]
			EndIf
				
			RETE->VLRPIS	+= Val(aCmps[9])		
			RETE->VLRCOF	+= Val(aCmps[10])
			MSUnLock()
		EndIf
		
	ElseIf cSubStr$ "M200/M350/M600/"
		aCmps	:=	RetCmpSnt( (cAliasTXT)->TEXTO )	
		
		If cSubStr$ "M200/M600"
			cTrib	:= IIf(cSubStr== "M200","1","2")
			
			If cRegime $ "1/3" //Se regime Não Cumultivo ou ambos Processa informações não cumulativa			
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³Valores Apuração Não Cumulativo³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				If APUN->(MsSeek(cTrib))
					RecLock("APUN",.F.)
				Else
					RecLock("APUN",.T.)
					APUN->TRIB	:= cTrib
				EndIf
					
				APUN->VLRDEB		+= Val(aCmps[2])
				APUN->VLRCREDPER	+= Val(aCmps[3])
				APUN->VLRCREDANT	+= Val(aCmps[4])
				APUN->VLRRET		+= Val(aCmps[6])
				APUN->VLROUTDED	+= Val(aCmps[7])			
				APUN->VLRPAG		+= Val(aCmps[8])						
				MSUnLock()
			EndIf
			
			If cRegime $ "2/3" //Se regime Cumulativo ou ambos gerar informações cumulativo			
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³Valores Apuração Cumulativo³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				If APUC->(MsSeek(cTrib))
					RecLock("APUC",.F.)
				Else
					RecLock("APUC",.T.)
					APUC->TRIB	:= cTrib
				EndIf
					
				APUC->VLRDEB		+= Val(aCmps[9])
				APUC->VLRRET		+= Val(aCmps[10])
				APUC->VLROUTDED	+= Val(aCmps[11])
				APUC->VLRPAG		+= Val(aCmps[12])
				MSUnLock()
			EndIf
					
		ElseIf cSubStr== "M350"
			
			If cRegime $ "1/3"
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³Valores Apuração Não Cumulativo³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				If APUN->(MsSeek("1"))
					RecLock("APUN",.F.)
				Else
					RecLock("APUN",.T.)
					APUN->TRIB	:= "1"
				EndIf
				APUN->FOLHASAL	+= Val(aCmps[6])						
				MSUnLock()	
			EndIf		
			
			If cRegime $ "2/3"
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³Valores Apuração Não Cumulativo³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				If APUC->(MsSeek("1"))
					RecLock("APUC",.F.)
				Else
					RecLock("APUC",.T.)
					APUC->TRIB	:= "1"
				EndIf				
				APUC->FOLHASAL	+= Val(aCmps[6])
				MSUnLock()	
			EndIf
			
		EndIf
	
	ElseIf cSubStr$ "M105/M505"

		aCmps	:=	RetCmpSnt( (cAliasTXT)->TEXTO )		
		cTrib	:= IIf(cSubStr== "M105","1","2")
		
		If BASC->(MsSeek(cTrib+aCmps[2]))
			RecLock("BASC",.F.)
		Else
			RecLock("BASC",.T.)
			BASC->TRIB		:= cTrib
			BASC->CODBCC	:= aCmps[2]			
		EndIf
		BASC->BASECALC	+= Val(aCmps[7])
		BASC->BASECALCQT	+= Val(aCmps[9])
		MSUnLock()

	ElseIf cSubStr$ "M100/M500/M210/M610"			
		aCmps	:=	RetCmpSnt( (cAliasTXT)->TEXTO )		
		If cSubStr$ "M100/M500"	 .And. cRegime $ "1/3"	
			
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Composição Créditos³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ			
			cTrib	:= IIf(cSubStr== "M100","1","2")
			cAliq	:= IIf(Val(aCmps[5])>0,aCmps[5],aCmps[7]) //Verificação da alíquota			
			
			If CRED->(MsSeek(cTrib+aCmps[2]+cAliq))
				RecLock("CRED",.F.)
			Else
				RecLock("CRED",.T.)
				CRED->COD	:= aCmps[2]
				CRED->ALIQ	:= cAliq
				CRED->TRIB	:= cTrib				
			EndIf

			CRED->NALIQ		+= IIf(Val(aCmps[5])>0,Val(aCmps[5]),Val(aCmps[7]))
			CRED->BASECALC	+= IIf(Val(aCmps[4])>0,Val(aCmps[4]),Val(aCmps[6]))
			CRED->CREDDISP	+= Val(aCmps[8])
			CRED->ACRESCIMO	+= Val(aCmps[9])				
			CRED->REDUCAO		+= Val(aCmps[10])
			CRED->CREDDIF		+= Val(aCmps[11])															
			CRED->CREDAPUR	+= Val(aCmps[12])
			MSUnLock()
		

		ElseIf cSubStr$ "M210/M610"
			
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Composição Débitos ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			cTrib	:= IIf(cSubStr== "M210","1","2")
			cAliq	:= IIf(aCmps[2]$"03/53",aCmps[7],aCmps[5]) //Verificação da alíquota	
			
			If DEBI->(MsSeek(cTrib+aCmps[2]+cAliq))
				RecLock("DEBI",.F.)
			Else
				RecLock("DEBI",.T.)
				DEBI->COD	:= aCmps[2]
				DEBI->ALIQ	:= cAliq
				DEBI->TRIB	:= cTrib				
			EndIf
			
			DEBI->NALIQ		:= IIf(aCmps[2]$"03/53",Val(aCmps[7]),Val(aCmps[5]))
			DEBI->BASECALC	:= IIf(aCmps[2]$"03/53",Val(aCmps[6]),Val(aCmps[4])) //Verificação da base de cálculo  
			DEBI->VLCONTRIB	:= Val(aCmps[8])
			DEBI->ACRESCIMO	:= Val(aCmps[9])
			DEBI->REDUCAO		:= Val(aCmps[10])
			DEBI->DIFER		:= Val(aCmps[11])
			DEBI->DIFERANT	:= Val(aCmps[12])
			DEBI->DEBAPUR		:= Val(aCmps[13])
			MSUnLock()
					
		EndIf
			
	ElseIf cSubStr$ "1100/1500"
		If cRegime $ "1/3"
			aCmps	:=	RetCmpSnt( (cAliasTXT)->TEXTO )		
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Saldos de Créditos ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			cTrib	:= IIf(cSubStr== "1100","1","2")			
			If SCRE->(MsSeek(cTrib+ SubStr(aCmps[2],1,2) + "/"+ SubStr(aCmps[2],3,4)+aCmps[5]))
				RecLock("SCRE",.F.)
			Else
				RecLock("SCRE",.T.)
				SCRE->TRIB	:= cTrib				
				SCRE->PER	:= SubStr(aCmps[2],1,2) + "/"+ SubStr(aCmps[2],3,4)
				SCRE->COD	:= aCmps[5]
			EndIf
			SCRE->CREDPER	:= Val(aCmps[12])
			SCRE->CREDUTI	:= Val(aCmps[13])
			SCRE->SALDO	:= Val(aCmps[18])			
			MSUnLock()			
		EndIf

	ElseIf cSubStr$ "1300/1700"
		aCmps	:=	RetCmpSnt( (cAliasTXT)->TEXTO )		
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Saldos de Retenções³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		cTrib	:= IIf(cSubStr== "1300","1","2")			
		If SRET->(MsSeek(cTrib+SubStr(aCmps[3],1,2) + "/"+ SubStr(aCmps[2],3,4)+aCmps[2]))
			RecLock("SRET",.F.)
		Else
			RecLock("SRET",.T.)
			SRET->TRIB		:= cTrib				
			SRET->PER		:= SubStr(aCmps[3],1,2) + "/"+ SubStr(aCmps[3],3,4)
			SRET->INDNAT	:= aCmps[2]
		EndIf

		SRET->VLRET		:= Val(aCmps[4])	
		SRET->VLRETUTI	:= Val(aCmps[5])+Val(aCmps[6])+Val(aCmps[7])
		SRET->SALDO		:= Val(aCmps[8])
		MSUnLock()
	
	EndIf
	(cAliasTXT)->(DBSkip())  
EndDo

Return


//-------------------------------------------------------------------
/*/{Protheus.doc} ReportPri2
	
Função que cria estrutura das Section do relatório Sintético
		
@Return oReport	-> Objeto TReport
			
@author Erick Dias 
@since  11/12/2013
@version 11.80
/*/
//-------------------------------------------------------------------
Static Function ReportDef2()

Local oReport
Local oReceita
Local oRetencao
Local oApurNCum
Local oApurCum
Local oDebito
Local oCredito
Local oSldCred
Local oSldRet
Local oCodBcc

oReport	:=	TReport():New("FISR020",STR0012,"", {|oReport| ReportPri2(oReport)},STR0013/*,,,,,,,,1*/)	//"Conferência SPED - PIS/COFINS"###"Este relatório tem o objetivo de possibiliar de forma gráfica a conferência das informações que serão enviadas ao fisco."
oReport:nFontBody := 8
oReport:SetLeftMargin(5)

oReceita:= TRSection():New(oReport,"Receita",{""},/*{Array com as ordens do relatório}*/,/*Campos do SX3*/,/*Campos do SIX*/)
TRCell():New(oReceita,"TEXTO"	,""	,"Receita" ,/*Picture*/,100,/*lPixel*/,/*{|| code-block de impressao }*/,,,,,,,,,.F.)
TRCell():New(oReceita,"VALOR"	,""	,"VALOR" ,"@E 99,999,999,999.99",18,/*lPixel*/,/*{|| code-block de impressao }*/,,,,,,,,,.T.)

oRetencao:= TRSection():New(oReport,"Retencao",{""},/*{Array com as ordens do relatório}*/,/*Campos do SX3*/,/*Campos do SIX*/)
TRCell():New(oRetencao,"TEXTO"	,""	,"Retencao" ,/*Picture*/,100,/*lPixel*/,/*{|| code-block de impressao }*/,,,,,,,,,.F.)
TRCell():New(oRetencao,"VALOR"	,""	,"VALOR" ,"@E 99,999,999,999.99",18,/*lPixel*/,/*{|| code-block de impressao }*/,,,,,,,,,.T.)

oDebito:= TRSection():New(oReport,"Debito",{""},/*{Array com as ordens do relatório}*/,/*Campos do SX3*/,/*Campos do SIX*/)
TRCell():New(oDebito,"TEXTO"	,""	,"Debito" ,/*Picture*/,100,/*lPixel*/,/*{|| code-block de impressao }*/,,,,,,,,,.F.)
TRCell():New(oDebito,"VALOR"	,""	,"VALOR" ,"@E 99,999,999,999.99",18,/*lPixel*/,/*{|| code-block de impressao }*/,,,,,,,,,.T.)

oCredito:= TRSection():New(oReport,"Crédito",{""},/*{Array com as ordens do relatório}*/,/*Campos do SX3*/,/*Campos do SIX*/)
TRCell():New(oCredito,"TEXTO"	,""	,"Crédito" ,/*Picture*/,100,/*lPixel*/,/*{|| code-block de impressao }*/,,,,,,,,,.F.)
TRCell():New(oCredito,"VALOR"	,""	,"VALOR" ,"@E 99,999,999,999.99",18,/*lPixel*/,/*{|| code-block de impressao }*/,,,,,,,,,.T.)

oApurNCum:= TRSection():New(oReport,"ApurNCum",{""},/*{Array com as ordens do relatório}*/,/*Campos do SX3*/,/*Campos do SIX*/)
TRCell():New(oApurNCum,"TEXTO"	,""	,"ApurNCum" ,/*Picture*/,100,/*lPixel*/,/*{|| code-block de impressao }*/,,,,,,,,,.F.)
TRCell():New(oApurNCum,"VALOR"	,""	,"VALOR" ,"@E 99,999,999,999.99",18,/*lPixel*/,/*{|| code-block de impressao }*/,,,,,,,,,.T.)

oApurCum:= TRSection():New(oReport,"ApurCum",{""},/*{Array com as ordens do relatório}*/,/*Campos do SX3*/,/*Campos do SIX*/)
TRCell():New(oApurCum,"TEXTO"	,""	,"ApurCum" ,/*Picture*/,100,/*lPixel*/,/*{|| code-block de impressao }*/,,,,,,,,,.F.)
TRCell():New(oApurCum,"VALOR"	,""	,"VALOR" ,"@E 99,999,999,999.99",18,/*lPixel*/,/*{|| code-block de impressao }*/,,,,,,,,,.T.)

oSldCred:= TRSection():New(oReport,"SldCred",{""},/*{Array com as ordens do relatório}*/,/*Campos do SX3*/,/*Campos do SIX*/)
TRCell():New(oSldCred,"TEXTO"	,""	,"SldCred" ,/*Picture*/,100,/*lPixel*/,/*{|| code-block de impressao }*/,,,,,,,,,.F.)
TRCell():New(oSldCred,"VALOR"	,""	,"VALOR" ,"@E 99,999,999,999.99",18,/*lPixel*/,/*{|| code-block de impressao }*/,,,,,,,,,.T.)

oSldRet:= TRSection():New(oReport,"SldRet",{""},/*{Array com as ordens do relatório}*/,/*Campos do SX3*/,/*Campos do SIX*/)
TRCell():New(oSldRet,"TEXTO"	,""	,"SldRet" ,/*Picture*/,100,/*lPixel*/,/*{|| code-block de impressao }*/,,,,,,,,,.F.)
TRCell():New(oSldRet,"VALOR"	,""	,"VALOR" ,"@E 99,999,999,999.99",18,/*lPixel*/,/*{|| code-block de impressao }*/,,,,,,,,,.T.)

oCodBcc:= TRSection():New(oReport,"CodBcc",{""},/*{Array com as ordens do relatório}*/,/*Campos do SX3*/,/*Campos do SIX*/)
TRCell():New(oCodBcc,"TEXTO"	,""	,"BaseCred" ,/*Picture*/,200,/*lPixel*/,/*{|| code-block de impressao }*/,,,,,,,,,.F.)
TRCell():New(oCodBcc,"VALOR"	,""	,"VALOR" ,"@E 99,999,999,999.99",18,/*lPixel*/,/*{|| code-block de impressao }*/,,,,,,,,,.T.)

Return(oReport)

//-------------------------------------------------------------------
/*/{Protheus.doc} ReportPri2
	
Função que chama as demais funções para realizar impressão

@param 	oReport   	-> Objeto Treport
		
@Return
			
@author Erick Dias 
@since  11/12/2013
@version 11.80
/*/
//-------------------------------------------------------------------
Static Function ReportPri2(oReport)

PrtReceita(oReport)
PrRetencao(oReport)
PrtDebito(oReport)
PrtCodBcc(oReport)
PrtCred(oReport)
PrApuNC(oReport)
PrApuC(oReport)
PrtSldCred(oReport)
PrtSldRet(oReport)

FechaArq("RETE")
FechaArq("RECE")
FechaArq("APUN")
FechaArq("APUC")
FechaArq("DEBI")
FechaArq("CRED")
FechaArq("SCRE")
FechaArq("SRET")
FechaArq("BASC")
FechaArq("TXTA")		
FechaArq("TXT")

Return       

//-------------------------------------------------------------------
/*/{Protheus.doc} PrtReceita
	
Função que realiza a impressão da composição da receita

@param 	oReport   	-> Objeto Treport
		
@Return
			
@author Erick Dias 
@since  11/12/2013
@version 11.80
/*/
//-------------------------------------------------------------------
Static Function PrtReceita(oReport)

Local nRTNC		:= 0
Local nRNT		:= 0
Local nRE			:= 0
Local nRC			:= 0
Local nTotalR		:= 0
Local nRecSer		:= 0
Local nRecMer		:= 0
Local nRecTrans	:= 0
Local nOUTREC		:= 0
Local nTotalD		:= 0
Local nInstFin		:= 0 
Local oTFont 		:= TFont():New('Arial',,10,.T.)

DBSelectArea("RECE")
RECE->(DBGoTop())

While !RECE->(Eof())
	
	If RECE->BLOCO == "1"
		nRTNC		:= RECE->RTNC	
		nRNT		:= RECE->RNT
		nRE			:= RECE->RE
		nRC			:= RECE->RC
		nTotalR	:= RECE->TotalR									
	ElseIf RECE->BLOCO == "A"
		nRecSer	:= RECE->RecSer
	ElseIf RECE->BLOCO == "C"
		nRecMer	:= RECE->RecMer
	ElseIf RECE->BLOCO == "D"
		nRecTrans	:= RECE->RecTrans
	ElseIf RECE->BLOCO == "F"
		nOUTREC	:= RECE->OUTREC
	ElseIf RECE->BLOCO == "I"
		nInstFin	:= RECE->InstFin
	EndIf	
	nTotalD	+= RECE->TotalD
	RECE->(DBSkip())
EndDo

oReport:SkipLine()
oReport:Say(295,1000,STR0689,oTFont) //"Composição das Receitas"
oReport:Section(1):Init()

oReport:SkipLine(3)
oReport:Section(1):Cell("TEXTO"):SetBlock({|| " " })	
oReport:Section(1):PrintLine()

oReport:Section(1):Cell("TEXTO"):SetBlock({|| STR0690 })//"RECEITAS NO PERÍODO"
oReport:Section(1):Cell("VALOR"):SetBlock({||})
oReport:Section(1):PrintLine()

oReport:SkipLine()   
oReport:Section(1):Cell("TEXTO"):SetBlock({|| STR0691 })//"Receita Tributada Não Cumulativa"
oReport:Section(1):Cell("VALOR"):SetBlock({||nRTNC})
oReport:Section(1):PrintLine()

oReport:SkipLine()
oReport:Section(1):Cell("TEXTO"):SetBlock({|| STR0692 }) //"Receita Não Tributada "
oReport:Section(1):Cell("VALOR"):SetBlock({||nRNT})
oReport:Section(1):PrintLine()

oReport:SkipLine()
oReport:Section(1):Cell("TEXTO"):SetBlock({|| STR0693 })//"Receita de Exportação "
oReport:Section(1):Cell("VALOR"):SetBlock({||nRE})
oReport:Section(1):PrintLine()

oReport:SkipLine()
oReport:Section(1):Cell("TEXTO"):SetBlock({|| STR0694 })//"Receita Cumulativa "
oReport:Section(1):Cell("VALOR"):SetBlock({||nRC})
oReport:Section(1):PrintLine()
oReport:FatLine()
oReport:Section(1):Cell("TEXTO"):SetBlock({|| STR0695 })//"Total"
oReport:Section(1):Cell("VALOR"):SetBlock({||nTotalR})
oReport:Section(1):PrintLine() 

oReport:SkipLine(5)
oReport:PrintText(STR0696)//"DETALHAMENTO DA RECEITA"

oReport:SkipLine()
oReport:Section(1):Cell("TEXTO"):SetBlock({|| STR0697 })//"Receita de Serviço"
oReport:Section(1):Cell("VALOR"):SetBlock({||nRecSer})
oReport:Section(1):PrintLine()

oReport:SkipLine()
oReport:Section(1):Cell("TEXTO"):SetBlock({|| STR0698 })//"Receita de Mercadoria"
oReport:Section(1):Cell("VALOR"):SetBlock({||nRecMer})
oReport:Section(1):PrintLine()	

oReport:SkipLine()
oReport:Section(1):Cell("TEXTO"):SetBlock({|| STR0699 })//"Receita de Transportes"
oReport:Section(1):Cell("VALOR"):SetBlock({||nRecTrans})
oReport:Section(1):PrintLine()		

oReport:SkipLine()
oReport:Section(1):Cell("TEXTO"):SetBlock({|| STR0763 })//"Instituicoes Financeiras" 
oReport:Section(1):Cell("VALOR"):SetBlock({||nInstFin})
oReport:Section(1):PrintLine()		

oReport:SkipLine()
oReport:Section(1):Cell("TEXTO"):SetBlock({|| STR0700 })//"Outras Receitas"
oReport:Section(1):Cell("VALOR"):SetBlock({||nOUTREC})
oReport:Section(1):PrintLine()	

oReport:FatLine()

oReport:Section(1):Cell("TEXTO"):SetBlock({|| STR0695 })//Total
oReport:Section(1):Cell("VALOR"):SetBlock({||nTotalD})
oReport:Section(1):PrintLine()	
    	
oReport:EndPage()   	

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} PrRetencao
	
Função que realiza a impressao da composição das retenções

@param 	oReport   	-> Objeto Treport
		
@Return
			
@author Erick Dias 
@since  11/12/2013
@version 11.80
/*/
//-------------------------------------------------------------------
Static Function PrRetencao(oReport)

Local nPis01		:= 0
Local nCof01		:= 0
Local nPis02		:= 0
Local nCof02		:= 0
Local nPis03		:= 0
Local nCof03		:= 0
Local nPis04		:= 0
Local nCof04		:= 0
Local nPis05		:= 0
Local nCof05		:= 0
Local nPis99		:= 0
Local nCof99		:= 0
Local nTotPis		:= 0
Local nTotCof		:= 0
Local nCont		:= 0
Local oTFont 		:= TFont():New('Arial',,10,.T.)

DBSelectArea("RETE")
RETE->(DBGoTop())

While !RETE->(Eof())
	
	If RETE->INDRET == "01"
		nPis01 		+=	RETE->VLRPIS
		nCof01		+=	RETE->VLRCOF									
	ElseIf RETE->INDRET == "02"
		nPis02 		+=	RETE->VLRPIS
		nCof02		+=	RETE->VLRCOF
	ElseIf RETE->INDRET == "03"
		nPis03 		+=	RETE->VLRPIS
		nCof03		+=	RETE->VLRCOF
	ElseIf RETE->INDRET == "04"
		nPis04 		+=	RETE->VLRPIS
		nCof04		+=	RETE->VLRCOF
	ElseIf RETE->INDRET == "05"
		nPis05 		+=	RETE->VLRPIS
		nCof05		+=	RETE->VLRCOF	
	ElseIf RETE->INDRET == "99"
		nPis99 		+=	RETE->VLRPIS
		nCof99		+=	RETE->VLRCOF	
	EndIf	
	nTotPis	+= RETE->VLRPIS
	nTotCof	+= RETE->VLRCOF
	
	RETE->(DBSkip())
EndDo

If nPis01 + nPis02 + nPis03 + nPis04 + nPis05 + nPis99 >0

	oReport:SkipLine()
	oReport:Say(295,1000,STR0701,oTFont)//"Composição das Retenções"
	oReport:Section(2):Init()
	
	For nCont:= 1 to 2	
			
		If nCont == 1 //PIS
			oReport:SkipLine(3)
			oReport:Section(2):Cell("TEXTO"):SetBlock({|| " " })	
			oReport:Section(2):PrintLine()		
		
			oReport:Section(2):Cell("TEXTO"):SetBlock({|| STR0711 })//"RETENÇÃO PIS"
			oReport:Section(2):Cell("VALOR"):SetBlock({||})
			oReport:Section(2):PrintLine()	
		ElseIf nCont == 2 //COFINS
			oReport:SkipLine(3)
			oReport:Section(2):Cell("TEXTO"):SetBlock({|| STR0712 })//"RETENÇÃO COFINS"
			oReport:Section(2):Cell("VALOR"):SetBlock({||})
			oReport:Section(2):PrintLine()
		EndIf
		
		oReport:SkipLine()	   
		oReport:Section(2):Cell("TEXTO"):SetBlock({|| STR0703 })//"(+) Retenção por Órgãos, Autarquias e Fundações Federais"
		oReport:Section(2):Cell("VALOR"):SetBlock({||IIf(nCont==1,nPis01,nCof01)})
		oReport:Section(2):PrintLine()
		
		oReport:SkipLine()
		oReport:Section(2):Cell("TEXTO"):SetBlock({|| STR0704 })//"(+) Retenção por outras Entidades da Administração Pública Federal"
		oReport:Section(2):Cell("VALOR"):SetBlock({||IIf(nCont==1,nPis02,nCof02)})
		oReport:Section(2):PrintLine()
		
		oReport:SkipLine()
		oReport:Section(2):Cell("TEXTO"):SetBlock({|| STR0705 })//"(+) Retenção por Pessoas Jurídicas de Direito Privado"
		oReport:Section(2):Cell("VALOR"):SetBlock({||IIf(nCont==1,nPis03,nCof03)})
		oReport:Section(2):PrintLine()
		
		oReport:SkipLine()
		oReport:Section(2):Cell("TEXTO"):SetBlock({|| STR0706 })//"(+) Recolhimento por Sociedade Cooperativa"
		oReport:Section(2):Cell("VALOR"):SetBlock({||IIf(nCont==1,nPis04,nCof04)})
		oReport:Section(2):PrintLine()
		
		oReport:SkipLine()
		oReport:Section(2):Cell("TEXTO"):SetBlock({|| STR0707 })//"(+) Retenção por Fabricante de Máquinas e Veículos"
		oReport:Section(2):Cell("VALOR"):SetBlock({||IIf(nCont==1,nPis05,nCof05)})
		oReport:Section(2):PrintLine() 
		
		oReport:SkipLine()
		oReport:Section(2):Cell("TEXTO"):SetBlock({|| STR0708 })//"(+) Outras Retenções"
		oReport:Section(2):Cell("VALOR"):SetBlock({||IIf(nCont==1,nPis99,nCof99)})
		oReport:Section(2):PrintLine()
	
		oReport:FatLine()
		
		oReport:Section(2):Cell("TEXTO"):SetBlock({|| STR0709 })//"Total das Retenções"
		oReport:Section(2):Cell("VALOR"):SetBlock({||IIf(nCont==1,nTotPis,nTotCof)})
		oReport:Section(2):PrintLine()
		oReport:SkipLine()
	
	Next nCont	
	
	oReport:EndPage()	 
	
EndIf   	

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} PrApuNC
	
Função que realiza a impressao da apuração regime não cumulativo

@param 	oReport   	-> Objeto Treport
		
@Return
			
@author Erick Dias 
@since  11/12/2013
@version 11.80
/*/
//-------------------------------------------------------------------
Static Function PrApuNC(oReport)

Local oTFont 		:= TFont():New('Arial',,10,.T.)

DBSelectArea("APUN")
APUN->(DBGoTop())

While !APUN->(Eof())
	
	If APUN->TRIB == "1"
		oReport:SkipLine()
		oReport:Say(295,980,STR0710,oTFont)//"Apuração (Regime Não Cumulativo)"
		oReport:Section(5):Init()
	EndIf

	If APUN->TRIB == "1"
		oReport:SkipLine(3)
		oReport:Section(5):Cell("TEXTO"):SetBlock({|| " " })
		oReport:Section(5):PrintLine()		
	
		oReport:Section(5):Cell("TEXTO"):SetBlock({|| STR0721 })//"PIS"
		oReport:Section(5):Cell("VALOR"):SetBlock({||})
		oReport:Section(5):PrintLine()	
	ElseIf APUN->TRIB == "2"
		oReport:SkipLine(3)
		oReport:Section(5):Cell("TEXTO"):SetBlock({|| STR0722 })// "COFINS"
		oReport:Section(5):Cell("VALOR"):SetBlock({||})
		oReport:Section(5):PrintLine()
	EndIf

	oReport:SkipLine()
	oReport:Section(5):Cell("TEXTO"):SetBlock({|| STR0713 })//"Valor do Débito"
	oReport:Section(5):Cell("VALOR"):SetBlock({||APUN->VLRDEB})
	oReport:Section(5):PrintLine()
	
	oReport:SkipLine()
	oReport:Section(5):Cell("TEXTO"):SetBlock({|| STR0714 })//"(-)Crédito do Período utilizado"
	oReport:Section(5):Cell("VALOR"):SetBlock({||APUN->VLRCREDPER})
	oReport:Section(5):PrintLine()
	
	oReport:SkipLine()
	oReport:Section(5):Cell("TEXTO"):SetBlock({|| STR0715 })//"(-) Crédito de Período Anterior utilizado"
	oReport:Section(5):Cell("VALOR"):SetBlock({||APUN->VLRCREDANT})
	oReport:Section(5):PrintLine()
	
	oReport:SkipLine()
	oReport:Section(5):Cell("TEXTO"):SetBlock({|| STR0716 })//"(-) Retenção utilizada"
	oReport:Section(5):Cell("VALOR"):SetBlock({||APUN->VLRRET})
	oReport:Section(5):PrintLine()
	
	oReport:SkipLine()
	oReport:Section(5):Cell("TEXTO"):SetBlock({|| STR0717 })//"(-) Outras Deduções"
	oReport:Section(5):Cell("VALOR"):SetBlock({||APUN->VLROUTDED})
	oReport:Section(5):PrintLine() 
	
	oReport:FatLine()
	oReport:Section(5):Cell("TEXTO"):SetBlock({|| STR0718 })//"Valor a Pagar"
	oReport:Section(5):Cell("VALOR"):SetBlock({||APUN->VLRPAG})
	oReport:Section(5):PrintLine()
	
	//Somente imprime folha de salário para PIS
	If APUN->TRIB == "1"
		oReport:SkipLine()
		oReport:Section(5):Cell("TEXTO"):SetBlock({|| STR0719 })//"PIS Folha de Salário"
		oReport:Section(5):Cell("VALOR"):SetBlock({||APUN->FOLHASAL})
		oReport:Section(5):PrintLine()
	EndIf

	APUN->(DBSkip())
EndDo

oReport:EndPage()	    	

Return


//-------------------------------------------------------------------
/*/{Protheus.doc} PrApuC
	
Função que realiza a impressão da apuração regime Cumulativo

@param 	oReport   	-> Objeto Treport
		
@Return
			
@author Erick Dias 
@since  11/12/2013
@version 11.80
/*/
//-------------------------------------------------------------------
Static Function PrApuC(oReport)

Local oTFont 		:= TFont():New('Arial',,10,.T.)

DBSelectArea("APUC")
APUC->(DBGoTop())

While !APUC->(Eof())		

	If APUC->TRIB == "1"
		oReport:SkipLine()
		oReport:Say(295,980,STR0723,oTFont)//"Apuração (Regime Cumulativo)"
		oReport:Section(6):Init()
	EndIf
	
	If APUC->TRIB == "1"
		oReport:SkipLine(3)
		oReport:Section(6):Cell("TEXTO"):SetBlock({|| " " })
		oReport:Section(6):PrintLine()		
	
		oReport:Section(6):Cell("TEXTO"):SetBlock({|| STR0721 })//"PIS"
		oReport:Section(6):Cell("VALOR"):SetBlock({||})
		oReport:Section(6):PrintLine()	
	ElseIf APUC->TRIB == "2"
		oReport:SkipLine(3)
		oReport:Section(6):Cell("TEXTO"):SetBlock({|| STR0722 })// "COFINS"
		oReport:Section(6):Cell("VALOR"):SetBlock({||})
		oReport:Section(6):PrintLine()
	EndIf

	oReport:SkipLine()   
	oReport:Section(6):Cell("TEXTO"):SetBlock({|| STR0713 })//"Valor do Débito"
	oReport:Section(6):Cell("VALOR"):SetBlock({||APUC->VLRDEB})
	oReport:Section(6):PrintLine()
	
	oReport:SkipLine()
	oReport:Section(6):Cell("TEXTO"):SetBlock({|| STR0716 })//"(-) Retenção utilizada"
	oReport:Section(6):Cell("VALOR"):SetBlock({||APUC->VLRRET})
	oReport:Section(6):PrintLine()
	
	oReport:SkipLine()
	oReport:Section(6):Cell("TEXTO"):SetBlock({|| STR0717 })//"(-) Outras Deduções"
	oReport:Section(6):Cell("VALOR"):SetBlock({||APUC->VLROUTDED})
	oReport:Section(6):PrintLine() 

	oReport:FatLine()
	oReport:Section(6):Cell("TEXTO"):SetBlock({|| STR0718 })//"Valor a Pagar"
	oReport:Section(6):Cell("VALOR"):SetBlock({||APUC->VLRPAG})
	oReport:Section(6):PrintLine()
	
	//Somente imprime folha de salário para o PIS
	If APUC->TRIB == "1"	
		oReport:SkipLine()
		oReport:Section(6):Cell("TEXTO"):SetBlock({|| STR0719 })//"PIS Folha de Salário"
		oReport:Section(6):Cell("VALOR"):SetBlock({||APUC->FOLHASAL})
		oReport:Section(6):PrintLine()
		oReport:SkipLine()
	EndIf

	APUC->(DBSkip())
EndDo

oReport:EndPage()	    	

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} PrtCred
	
Função que realizará a impressão da composição dos Créditos

@param 	oReport   	-> Objeto Treport
		
@Return
			
@author Erick Dias 
@since  11/12/2013
@version 11.80
/*/
//-------------------------------------------------------------------
Static Function PrtCred(oReport)

Local nCont		:= 0
Local oTFont 		:= TFont():New('Arial',,10,.T.)

DBSelectArea("CRED")
CRED->(DBGoTop())

While !CRED->(Eof())
	
	nCont ++
	
	If nCont == 1
		oReport:SkipLine()
		oReport:Say(295,960,"COMPOSIÇÃO DO VALOR DE CRÉDITO",oTFont)//"Composição dos Créditos" 
		oReport:Section(4):Init()
		oReport:SkipLine(3)
		oReport:Section(4):Cell("TEXTO"):SetBlock({|| " " })
		oReport:Section(4):Cell("VALOR"):SetBlock({||})		
		oReport:Section(4):PrintLine()	
	EndIf	
	
	oReport:Section(4):Cell("TEXTO"):SetBlock({||  IIf(CRED->TRIB == "1",STR0744,STR0745)  + " - " + NomeSnt("436",CRED->COD) + STR0728 + CRED->ALIQ})//Crédito de PIS + Código da Contribuição + alíquota
	oReport:Section(4):Cell("VALOR"):SetBlock({||})
	oReport:Section(4):PrintLine()	

	oReport:SkipLine()
	oReport:Section(4):Cell("TEXTO"):SetBlock({|| STR0729 })//"     Base de Cálculo"
	oReport:Section(4):Cell("VALOR"):SetBlock({||CRED->BASECALC})
	oReport:Section(4):PrintLine()
	
	oReport:SkipLine()
	oReport:Section(4):Cell("TEXTO"):SetBlock({|| STR0739 })//"     Total Crédito Disponível"
	oReport:Section(4):Cell("VALOR"):SetBlock({||CRED->CREDDISP})
	oReport:Section(4):PrintLine() 
	
	oReport:SkipLine()	
	oReport:Section(4):Cell("TEXTO"):SetBlock({|| STR0740 })//"     Total de Acréscimo"
	oReport:Section(4):Cell("VALOR"):SetBlock({||CRED->ACRESCIMO})
	oReport:Section(4):PrintLine()
	
	oReport:SkipLine()
	oReport:Section(4):Cell("TEXTO"):SetBlock({|| STR0741 })//"     Total de Redução"
	oReport:Section(4):Cell("VALOR"):SetBlock({||CRED->REDUCAO})
	oReport:Section(4):PrintLine()			
	
	oReport:SkipLine()	
	oReport:Section(4):Cell("TEXTO"):SetBlock({|| STR0742})//"     Crédito Diferido" 
	oReport:Section(4):Cell("VALOR"):SetBlock({||CRED->CREDDIF})
	oReport:Section(4):PrintLine()	

	oReport:FatLine()	
	oReport:Section(4):Cell("TEXTO"):SetBlock({|| STR0743 })//"Total Disponível para apuração"
	oReport:Section(4):Cell("VALOR"):SetBlock({||CRED->CREDAPUR})
	oReport:Section(4):PrintLine()
	oReport:SkipLine(3)
		
	If nCont == 4
		nCont	:= 0
		oReport:EndPage()
	EndIf
	
	CRED->(DBSkip())
EndDo
oReport:EndPage()	    	

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} PrtDebito
	
Função que realizará a impressão da composição dos débitos

@param 	oReport   	-> Objeto Treport
		
@Return
			
@author Erick Dias 
@since  11/12/2013
@version 11.80
/*/
//-------------------------------------------------------------------
Static Function PrtDebito(oReport)

Local nCont		:= 0
Local oTFont 		:= TFont():New('Arial',,10,.T.)

DBSelectArea("DEBI")
DEBI->(DBGoTop())

While !DEBI->(Eof())
	
	nCont ++	
	If nCont == 1
		oReport:SkipLine()
		oReport:Say(295,1000,STR0724,oTFont)//"COMPOSIÇÃO DOS DÉBITOS" 
		oReport:Section(3):Init()
		oReport:SkipLine(3)
		oReport:Section(3):Cell("TEXTO"):SetBlock({|| " " })
		oReport:Section(3):Cell("VALOR"):SetBlock({||})
		oReport:Section(3):PrintLine()	
	EndIf	
		
	oReport:Section(3):Cell("TEXTO"):SetBlock({|| IIf(DEBI->TRIB == "1","PIS","COFINS")  + " - " + NomeSnt("435",DEBI->COD) + STR0728 + DEBI->ALIQ })//Débito de PIS + Código da Contribuição + alíquota
	oReport:Section(3):Cell("VALOR"):SetBlock({||})
	oReport:Section(3):PrintLine()		

	oReport:SkipLine()
	oReport:Section(3):Cell("TEXTO"):SetBlock({|| STR0729 })//"Base de Cálculo"
	oReport:Section(3):Cell("VALOR"):SetBlock({||DEBI->BASECALC})
	oReport:Section(3):PrintLine()	

	oReport:SkipLine()
	oReport:Section(3):Cell("TEXTO"):SetBlock({|| STR0730 })//"Valor da Contribuição"
	oReport:Section(3):Cell("VALOR"):SetBlock({||DEBI->VLCONTRIB})
	oReport:Section(3):PrintLine()
	
	oReport:SkipLine()
	oReport:Section(3):Cell("TEXTO"):SetBlock({|| STR0731 })//"Total de Ajustes de Acréscimo"
	oReport:Section(3):Cell("VALOR"):SetBlock({||DEBI->ACRESCIMO})
	oReport:Section(3):PrintLine() 
	
	oReport:SkipLine()	
	oReport:Section(3):Cell("TEXTO"):SetBlock({|| STR0732 })//"Total de Ajustes de Redução"
	oReport:Section(3):Cell("VALOR"):SetBlock({||DEBI->REDUCAO})
	oReport:Section(3):PrintLine()
	
	oReport:SkipLine()
	oReport:Section(3):Cell("TEXTO"):SetBlock({|| STR0733 })//"Total a Diferir"
	oReport:Section(3):Cell("VALOR"):SetBlock({||DEBI->DIFER})
	oReport:Section(3):PrintLine()			
	
	oReport:SkipLine()	
	oReport:Section(3):Cell("TEXTO"):SetBlock({|| STR0734 })//"Total de Diferimento de Período Anterior"
	oReport:Section(3):Cell("VALOR"):SetBlock({||DEBI->DIFERANT})
	oReport:Section(3):PrintLine()	
	
	oReport:FatLine()	
	oReport:Section(3):Cell("TEXTO"):SetBlock({|| STR0735 })//"Total de Débito para Apuração"
	oReport:Section(3):Cell("VALOR"):SetBlock({||DEBI->DEBAPUR})
	oReport:Section(3):PrintLine()
	oReport:SkipLine(3)	
		
	//Zera a sequência, para que sejam impressos de 4 em 4
	If nCont == 4
		nCont	:= 0
		oReport:EndPage()
	EndIf
	
	DEBI->(DBSkip())
EndDo

oReport:EndPage()	    	

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} PrtSldCred
	
Função que realizará a impressão do saldo de crédito 

@param 	oReport   	-> Objeto Treport
		
@Return
			
@author Erick Dias 
@since  11/12/2013
@version 11.80
/*/
//-------------------------------------------------------------------
Static Function PrtSldCred(oReport)

Local nCont		:= 0
Local oTFont 		:= TFont():New('Arial',,10,.T.)

DBSelectArea("SCRE")
SCRE->(DBGoTop())

While !SCRE->(Eof())
	
	nCont ++	
	If nCont == 1
		oReport:SkipLine()
		oReport:Say(295,1000,STR0748,oTFont)//"SALDOS DE CRÉDITOS" 
		oReport:Section(7):Init()
		oReport:SkipLine(3)
		oReport:Section(7):Cell("TEXTO"):SetBlock({|| " " })
		oReport:Section(7):PrintLine()	
	EndIf	
	
	oReport:Section(7):Cell("TEXTO"):SetBlock({|| IIf(SCRE->TRIB == "1",STR0749,STR0751 ) + SCRE->PER + " - " + NomeSnt("436",SCRE->COD)})//CRÉDITO DE PIS PERÍODO ALÍQUOTA

	oReport:Section(7):Cell("VALOR"):SetBlock({||})
	oReport:Section(7):PrintLine()	
	
	oReport:SkipLine()
	oReport:Section(7):Cell("TEXTO"):SetBlock({|| STR0752 })//"   Crédito disponível no período"
	oReport:Section(7):Cell("VALOR"):SetBlock({||SCRE->CREDPER})
	oReport:Section(7):PrintLine()	

	oReport:SkipLine()
	oReport:Section(7):Cell("TEXTO"):SetBlock({|| STR0753 })//"   (-) Valor do Crédito Utilizado no período"
	oReport:Section(7):Cell("VALOR"):SetBlock({||SCRE->CREDUTI})
	oReport:Section(7):PrintLine()
	
	oReport:SkipLine()
	oReport:FatLine()
	oReport:Section(7):Cell("TEXTO"):SetBlock({|| STR0754 })//"   Saldo de Crédito para próximo período"
	oReport:Section(7):Cell("VALOR"):SetBlock({||SCRE->SALDO})
	oReport:Section(7):PrintLine() 
		
	oReport:SkipLine(3)	
	
	//Zera a sequência, para que sejam impressos de 4 em 4
	If nCont == 6
		nCont	:= 0
		oReport:EndPage()
	EndIf
	
	SCRE->(DBSkip())
EndDo

oReport:EndPage()	    	

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} PrtSldRet
	
Função que irá imprimir saldo de retenção na fonte

@param 	oReport   	-> Objeto Treport
		
@Return
			
@author Erick Dias 
@since  11/12/2013
@version 11.80
/*/
//-------------------------------------------------------------------
Static Function PrtSldRet(oReport)

Local nCont		:= 0
Local oTFont 		:= TFont():New('Arial',,10,.T.)

DBSelectArea("SRET")
SRET->(DBGoTop())

While !SRET->(Eof())
	
	nCont ++	
	If nCont == 1
		oReport:SkipLine()
		oReport:Say(295,1000,STR0755,oTFont)//"Saldos de Retenções" 
		oReport:Section(8):Init()
		oReport:SkipLine(3)
		oReport:Section(8):Cell("TEXTO"):SetBlock({|| " " })
		oReport:Section(8):PrintLine()	
	EndIf
	oReport:Section(8):Cell("TEXTO"):SetBlock({|| IIf(SRET->TRIB == "1",STR0756,STR0758) + SRET->PER + " - " + NomeSnt("F600",SRET->INDNAT)})//Débito de PIS + Código da Contribuição + alíquota

	oReport:Section(8):Cell("VALOR"):SetBlock({||})
	oReport:Section(8):PrintLine()	
	
	oReport:SkipLine()
	oReport:Section(8):Cell("TEXTO"):SetBlock({|| STR0759 })//"   Valor da Retenção"
	oReport:Section(8):Cell("VALOR"):SetBlock({||SRET->VLRET})
	oReport:Section(8):PrintLine()	

	oReport:SkipLine()
	oReport:Section(8):Cell("TEXTO"):SetBlock({|| STR0760 })//"   (-) Valor da Retenção Utilizada"
	oReport:Section(8):Cell("VALOR"):SetBlock({||SRET->VLRETUTI})
	oReport:Section(8):PrintLine()
	
	oReport:SkipLine()
	oReport:FatLine()
	oReport:Section(8):Cell("TEXTO"):SetBlock({|| STR0761 })//"   Valor de Retenção para próximo período"
	oReport:Section(8):Cell("VALOR"):SetBlock({||SRET->SALDO})
	oReport:Section(8):PrintLine() 
		
	oReport:SkipLine(3)	
	
	//Zera a sequência, para que sejam impressos de 4 em 4
	If nCont == 6
		nCont	:= 0
		oReport:EndPage()
	EndIf
	
	SRET->(DBSkip())
EndDo

oReport:EndPage()	    	

Return


//-------------------------------------------------------------------
/*/{Protheus.doc} PrtCodBcc
	
Função que irá imprimir a composição da base de cálculo do crédito 

@param 	oReport   	-> Objeto Treport
		
@Return
			
@author Erick Dias 
@since  16/12/2013
@version 11.80
/*/
//-------------------------------------------------------------------
Static Function PrtCodBcc(oReport)

Local nCont		:= 0
Local oTFont 		:= TFont():New('Arial',,10,.T.)

DBSelectArea("BASC")
BASC->(DBGoTop())

While !BASC->(Eof())
	
	nCont ++	
	If nCont == 1
		oReport:SkipLine()
		oReport:Say(295,940, "COMPOSIÇÃO DA BASE DE CÁLCULO DO CRÉDITO",oTFont) 
		oReport:Section(9):Init()
		oReport:SkipLine(3)
		oReport:Section(9):Cell("TEXTO"):SetBlock({|| " " })
		oReport:Section(9):PrintLine()	
	EndIf	
	oReport:Section(9):Cell("TEXTO"):SetBlock({|| IIf(BASC->TRIB == "1","PIS - ","COFINS - ") + NomeSnt("437",BASC->CODBCC)})	
	oReport:Section(9):Cell("VALOR"):SetBlock({||})
	oReport:Section(9):PrintLine()	
		
	oReport:SkipLine()
	oReport:Section(9):Cell("TEXTO"):SetBlock({|| "   Base de Cálculo" })//"   Base de Cálculo"
	oReport:Section(9):Cell("VALOR"):SetBlock({||BASC->BASECALC})
	oReport:Section(9):PrintLine()	

	oReport:SkipLine()
	oReport:Section(9):Cell("TEXTO"):SetBlock({|| "   Base de Cálculo em Quantidade" })//"   Base de Cálculo em Quantidade"
	oReport:Section(9):Cell("VALOR"):SetBlock({||BASC->BASECALCQT})
	oReport:Section(9):PrintLine()	 
		
	oReport:SkipLine()
	oReport:FatLine()	
	oReport:SkipLine()
	//Zera a sequência, para que sejam impressos de 4 em 4
	If nCont == 10
		nCont	:= 0
		oReport:EndPage()
	EndIf
	
	BASC->(DBSkip())
EndDo

oReport:EndPage()	    	

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} FechaArq
	
Função que fecha os arquivos de trabalho abertos 

@param 	cNomeTab   	-> Nome da tabela
		
@Return
			
@author Erick Dias 
@since  13/12/2013
@version 11.80
/*/
//-------------------------------------------------------------------

Static Function FechaArq(cNomeTab)

(cNomeTab)->(DBCloseArea())
FErase(cArqRel+GetDBExtension())
FErase(cArqRel+IndexExt())

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} NomeSnt
	
Função que irá retornar a descrição referente a códigos de tabelas utilizadas no SPED 

@param 	ctab   	-> Tabela
			cCod   	-> Código
		
@Return
			
@author Erick Dias 
@since  16/12/2013
@version 11.80
/*/
//-------------------------------------------------------------------
Static Function NomeSnt(cTab,cCod)

Local cDescr	:= ""

If cTab == "437"

	Do Case	
		
		Case cCod == "01"
			cDescr:= "Aquisição de bens para revenda"
		
		Case cCod == "02"
			cDescr:= "Aquisição de bens utilizados como insumo"
			
		Case cCod == "03"
			cDescr:= "Aquisição de serviços utilizados como insumo"		

		Case cCod == "04"
			cDescr:= "Energia elétrica e térmica, inclusive sob a forma de vapor"		
		Case cCod == "05"
			cDescr:= "Aluguéis de prédios"		

		Case cCod == "06"
			cDescr:= "Aluguéis de máquinas e equipamentos"		

		Case cCod == "07"
			cDescr:= "Armazenagem de mercadoria e frete na operação de venda"		

		Case cCod == "08"
			cDescr:= "Contraprestações de arrendamento mercantil"		

		Case cCod == "09"
			cDescr:= "Máquinas, equipamentos e outros bens incorporados ao ativo imobilizado(depreciação)"		

		Case cCod == "10"
			cDescr:= "Máquinas, equipamentos e outros bens incorporados ao ativo imobilizado(aquisição)"		

		Case cCod == "11"
			cDescr:= "Amortização e Depreciação de edificações e benfeitorias em imóveis"		

		Case cCod == "12"
			cDescr:= "Devolução de Vendas Sujeitas à Incidência Não-Cumulativa"

		Case cCod == "13"
			cDescr:= "Outras Operações com Direito a Crédito"

		Case cCod == "14"
			cDescr:= "Atividade de Transporte de Cargas – Subcontratação"

		Case cCod == "15"
			cDescr:= "Atividade Imobiliária – Custo Incorrido de Unidade Imobiliária"

		Case cCod == "16"
			cDescr:= "Atividade Imobiliária – Custo Orçado de unidade não concluída"

		Case cCod == "17"
			cDescr:= "Atividade Serviços de Limpeza, Conservação e Manutenção - vale-transporte, vale-refeição."

		Case cCod == "18"
			cDescr:= "Estoque de abertura de bens"
	EndCase

ElseIf cTab == "435"

	Do Case

		Case cCod == "01"
			cDescr:= "Contribuição não cumulativa apurada a alíquota básica"

		Case cCod == "02"
			cDescr:= "Contribuição não cumulativa apurada a alíquotas diferenciadas"			

		Case cCod == "03"
			cDescr:= "Contribuição não cumulativa apurada a alíquota por unidade de medida"

		Case cCod == "04"
			cDescr:= "Contribuição não cumulativa - Atividade Imobiliária"

		Case cCod == "31"
			cDescr:= "Contribuição por substituição tributária"
			
		Case cCod == "32"
			cDescr:= "Contribuição por substituição tributária - Vendas à ZFM"

		Case cCod == "51"
			cDescr:= "Contribuição cumulativa apurada a alíquota básica"

		Case cCod == "52"
			cDescr:= "Contribuição cumulativa apurada a alíquotas diferenciadas"			

		Case cCod == "53"
			cDescr:= "Contribuição cumulativa apurada a alíquota por unidade de medida"

		Case cCod == "54"
			cDescr:= "Contribuição cumulativa - Atividade Imobiliária"
			
		Case cCod == "70"
			cDescr:= "Contribuição apurada da Atividade Imobiliária - RET"

		Case cCod == "71"
			cDescr:= "Contribuição apurada de SCP – Incidência Não Cumulativa"			

		Case cCod == "72"
			cDescr:= "Contribuição apurada de SCP – Incidência Cumulativa"
			
		Case cCod == "99"
			cDescr:= "Contribuição para o PIS/Pasep – Folha de Salários"
			
	EndCase

ElseIf cTab == "436"
	Do Case

		Case cCod == "101"
			cDescr:= "Vinculado à receita tributada-Alíquota Básica"
			
		Case cCod == "102"
			cDescr:= "Vinculado à receita tributada-Alíquota Diferenciada"

		Case cCod == "103"
			cDescr:= "Vinculado à receita tributada-Unidade de Produto"

		Case cCod == "104"
			cDescr:= "Vinculado à receita tributada-Estoque de Abertura"

		Case cCod == "105"
			cDescr:= "Vinculado à receita tributada-Embalagens para revenda"
			
		Case cCod == "106"
			cDescr:= "Vinculado à receita tributada-Presumido da Agroindústria"

		Case cCod == "107"
			cDescr:= "Vinculado à receita tributada-Outros Créditos Presumidos"

		Case cCod == "108"
			cDescr:= "Vinculado à receita tributada-Importação"			

		Case cCod == "109"
			cDescr:= "Vinculado à receita tributada-Atividade Imobiliária"

		Case cCod == "199"
			cDescr:= "Vinculado à receita tributada-Outros"			

		Case cCod == "201"
			cDescr:= "Vinculado à receita não tributada-Alíquota Básica"
			
		Case cCod == "202"
			cDescr:= "Vinculado à receita não tributada-Alíquota Diferenciada"

		Case cCod == "203"
			cDescr:= "Vinculado à receita não tributada-Unidade de Produto"

		Case cCod == "204"
			cDescr:= "Vinculado à receita não tributada-Estoque de Abertura"

		Case cCod == "205"
			cDescr:= "Vinculado à receita não tributada-Embalagens para revenda"
			
		Case cCod == "206"
			cDescr:= "Vinculado à receita não tributada-Presumido da Agroindústria"

		Case cCod == "207"
			cDescr:= "Vinculado à receita não tributada-Outros Créditos Presumidos"

		Case cCod == "208"
			cDescr:= "Vinculado à receita não tributada-Importação"			

		Case cCod == "209"
			cDescr:= "Vinculado à receita não tributada-Atividade Imobiliária"

		Case cCod == "199"
			cDescr:= "Vinculado à receita não tributada-Outros"	
								
		Case cCod == "301"
			cDescr:= "Vinculado à receita de exportação-Alíquota Básica"
			
		Case cCod == "302"
			cDescr:= "Vinculado à receita de exportação-Alíquota Diferenciada"

		Case cCod == "303"
			cDescr:= "Vinculado à receita de exportação-Unidade de Produto"

		Case cCod == "304"
			cDescr:= "Vinculado à receita de exportação-Estoque de Abertura"

		Case cCod == "305"
			cDescr:= "Vinculado à receita de exportação-Embalagens para revenda"
			
		Case cCod == "306"
			cDescr:= "Vinculado à receita de exportação-Presumido da Agroindústria"

		Case cCod == "307"
			cDescr:= "Vinculado à receita de exportação-Outros Créditos Presumidos"

		Case cCod == "308"
			cDescr:= "Vinculado à receita de exportação-Importação"

		Case cCod == "399"
			cDescr:= "Vinculado à receita de exportação-Outros"
			
	EndCase

ElseIf cTab == "F600"
	Do Case

		Case cCod == "01"
			cDescr:= "Retenção por Órgãos, Autarquias e Fundações Federais"
			
		Case cCod == "02"
			cDescr:= "Retenção por outras Entidades da Administração Pública Federal"					

		Case cCod == "03"
			cDescr:= "Retenção por Pessoas Jurídicas de Direito Privado"

		Case cCod == "04"
			cDescr:= "Recolhimento por Sociedade Cooperativa"

		Case cCod == "05"
			cDescr:= "Retenção por Fabricante de Máquinas e Veículos"			

		Case cCod == "99"
			cDescr:= "Outras Retenções"			
		
	EndCase

EndIf 

//Por padrão se não encontrar descrição para o código, irá retornar o próprio código. 
If Empty(cDescr)
	cDescr := "Código : " + cCod
EndIf

Return cDescr

//-------------------------------------------------------------------
/*/{Protheus.doc} CriaTMPReg()
Função que irá realizar a criação das tabelas temporárias para impressao
das informações detalhadas da EFD Contribuições, centralizando assim a
regra de alias e de campos. 

@author Erick G. Dias
@since 08/09/2014
@param aStru 	 - Array  - Informações dos campos da tabela temporária
@param cRelac  - String - Nome do campo de relacionamento com registro pai/filho
@param cReg 	 - String - Nome do registro correspondente no layout da EFD Contribuições
@param aTrbs	 - Array  - Informações das tabelas criadas.
@version 11.80
/*/
//-------------------------------------------------------------------
Static Function CriaTMPReg(aStru,cRelac,cReg,aTrbs)

Local cArq	:=	''
Local cAls	:=	GetNextAlias()

cArq	:=	CriaTrab(aStru)	

dbUseArea(.T.,__LocalDriver,cArq,cAls)

IndRegua(cAls,cArq,cRelac)

aAdd( aTrbs,{ cArq,cAls,cReg } )

Return 
