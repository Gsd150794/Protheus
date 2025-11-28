/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |30/08/2021| Chamado 37601. Trazer o conteúdo do campo RA_NSOCIAL, quando preenchido no lugar do RA_NOME.
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "RGPE020.CH"
#Include "Report.ch"
#Include "topconn.ch"

/*
===============================================================================================================================
Função------------: RGPE020
Autor-------------: Igor Melgaço
Data da Criacao---: 14/04/2021
Descrição---------: Rotina para tratar a emissao do relatorio mensal. CHAMADO 36180
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RGPE020()

	Local	oReport   
	Local	aArea 		:= FWGetArea()
	Private cPerg		:= "RGPE020" //"GPE103R" 
	Private cProcesso	:= ""
	Private cPeriodo	:= ""
	Private cPagamento	:= ""
	Private cRot		:= ""	
	Private cAliasQry	:= ""
	Private cRepete		:= ""
	Private cTitulo		:= OemToAnsi(STR0012)	//"Valores por Verba no Período"
	Private nOrdem		:= 1
	Private nTotLiq		:= 0
	Private lRepete		:= .F.
	Private lImpEmpr  	:= .T.
	Private lImpLiq		:= .T.
	Private lUsaArqui	:= IIf(GetMv("MV_ORGCFG",,"0")=="0",.F.,.T.)	// 0-Nao utiliza	1-Utiliza Postos e Deptos	2-Utiliza so Deptos.
	Private aOrd		:= {}
	Private nItensRetirados := 0
	Private nPosRetirada 	:= 0
	Private lItemCLVL		:= SuperGetMv( "MV_ITMCLVL", .F., "2" ) $ "1*3" //Define se os campos "Item Contabil" e Classe de Valor" estão ativos	
	Private lCorpManage		:= fIsCorpManage( FWGrpCompany() )	// Verifica se o cliente possui Gestão Corporativa no Grupo Logado	
	Private cDigHoras		:= SuperGetmv("MV_HORASDE" , .F. , "N")		
	Private _cCodTurno      := ""
	Private _cDescTurno     := ""

	aAdd(aOrd, OemToAnsi(STR0004))													//1 - "Matricula"	
	aAdd(aOrd, OemToAnsi(STR0006))													//2 - "Nome"
	aAdd(aOrd, OemToAnsi(STR0005)+"+"+OemToAnsi(STR0004))							//3 - "C.Custo + Matrícula"
	aAdd(aOrd, OemToAnsi(STR0005)+"+"+OemToAnsi(STR0006))							//4 - "C.Custo + Nome"
	aAdd(aOrd, OemToAnsi(STR0008)+"+"+OemToAnsi(STR0004))							//5 - "Depto + Matricula"
	aAdd(aOrd, OemToAnsi(STR0008)+"+"+OemToAnsi(STR0006)) 							//6 - "Depto + Nome"
	aAdd(aOrd, OemToAnsi(STR0005)+"+"+OemToAnsi(STR0008)+"+"+OemToAnsi(STR0004))	//7 - "C.Custo + Depto + Matricula"
	aAdd(aOrd, OemToAnsi(STR0005)+"+"+OemToAnsi(STR0008)+"+"+OemToAnsi(STR0006))	//8 - "C.Custo + Depto + Nome"

	nPosRetirada := Len(aOrd) + 1
	
	DBSelectArea("SRA")
	If SRA->(FIELDPOS("RA_KEYLOC")) > 0 //Se existe o campo
		aAdd(aOrd, OemToAnsi(IIf(cPaisLoc $ "COL", STR0045, STR0028))+"+"+OemToAnsi(STR0004))	//9 - "Loc.Pago + Matrícula" - "Centro Trab."
		aAdd(aOrd, OemToAnsi(IIf(cPaisLoc $ "COL", STR0045, STR0028))+"+"+OemToAnsi(STR0006))	//10 - "Loc.Pago + Nome"     - "Centro Trab."
		nPosRetirada += 2
	Else
		nItensRetirados += 2			
	EndIf
		
	If SRA->(FIELDPOS("RA_CODRPAT")) > 0//Se existe o campo
		If !(cPaisLoc $ "PER|COL")
			aAdd(aOrd, OemToAnsi(STR0031)+"+"+OemToAnsi(STR0004))	//11 - "Reg.Patronal + Matricula"
			aAdd(aOrd, OemToAnsi(STR0031)+"+"+OemToAnsi(STR0006))	//12 - "Reg.Patronal + Nome"
		
			If nItensRetirados == 0
				nPosRetirada += 2
			EndIf
		EndIf
	Else
		nItensRetirados += 2  	
	EndIf	
	
	If lCorpManage
		Private lUniNeg	:= !Empty(FWSM0Layout(cEmpAnt, 2)) // Verifica se possui tratamento para unidade de Negocios
		Private lEmpFil	:= !Empty(FWSM0Layout(cEmpAnt, 1)) // Verifica se possui tratamento para Empresa
		Private cLayoutGC 	:= FWSM0Layout(cEmpAnt)
		Private nStartEmp	:= At("E",cLayoutGC)
		Private nStartUnN	:= At("U",cLayoutGC)
		Private nEmpLength	:= Len(FWSM0Layout(cEmpAnt, 1))
		Private nUnNLength	:= Len(FWSM0Layout(cEmpAnt, 2))
	EndIf

	Pergunte(cPerg,.F.)

	cRot := MV_PAR10
	
	oReport := ReportDef()
	oReport:SetLandScape()
	oReport:PrintDialog()
	
	FWRestArea( aArea )
	
Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³ ReportDef  ³ Autor ³ Tania Bronzeri        ³ Data ³15/08/2007³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Relatorio de Valores por Verba Horizontal                    ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ GPER103                                                      ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Static Function ReportDef()
	Local oReport 
	Local oSecFun 
	Local oSecNom
	Local oSecCtt
	Local oSecSqb 
	Local oSecRgc 
	Local oSecRco
	Local oSectionh        
	Local cDesc1	:= OemToAnsi(STR0001) + OemToAnsi(STR0025) + OemToAnsi(STR0002) + OemToAnsi(STR0003) //"Relatorio por Codigo" ### "Este relatório imprime os valores por período, referente às verbas selecionadas." ### "Ser  impresso de acordo com os parametros solicitados pelo" ### "usu rio."

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Criacao dos componentes de impressao                                    ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	DEFINE REPORT oReport NAME "RGPE020" TITLE cTitulo PARAMETER cPerg ACTION {|oReport| R103Imp(oReport)} DESCRIPTION cDesc1	

		oReport:SetTotalInLine(.F.)     // para totalizar em linhas
		oReport:nFontBody	:= 7
		oReport:SetDynamic()

	//Section 1
	DEFINE Section oSecFun OF oReport TITLE OemToAnsi(STR0024) TABLES "SRA", "SQB", "RGC", "RCO" ORDERS aOrd	//Processo / Periodo

		DEFINE CELL NAME "RA_FILIAL"  OF oSecFun ALIAS "SRA" BLOCK {||IIf(lRepete,"",(cAliasQry)->RA_FILIAL)} TITLE OemToAnsi(STR0020)	//"Fil."
		DEFINE CELL NAME "RA_MAT"     OF oSecFun ALIAS "SRA" TITLE OemToAnsi(STR0011)	//"Matric."
		DEFINE CELL NAME "RA_NOME"    OF oSecFun ALIAS "SRA" BLOCK {|| If(!Empty((cAliasQry)->RA_NSOCIAL),(cAliasQry)->RA_NSOCIAL,(_cAliaQRY)->RA_NOME)	}	
		DEFINE CELL NAME "SINAL"      OF oSecFun TITLE "."
		DEFINE CELL NAME "STATUS"     OF oSecFun TITLE "."

        DEFINE CELL NAME "RA_CODFUNC" OF oSecFun TITLE "Funcao" 
        DEFINE CELL NAME "RJ_DESC"    OF oSecFun TITLE "Desc. da Funcao" 
		DEFINE CELL NAME "RA_CC"      OF oSecFun TITLE "Cent.Cus." 
		DEFINE CELL NAME "DESC_CC"    OF oSecFun TITLE "Desc. Centro de Custo" 
		DEFINE CELL NAME "RA_I_SETOR" OF oSecFun TITLE "Setor" 
        DEFINE CELL NAME "ZAK_DESCRI" OF oSecFun TITLE "Desc. do Setor" 
		DEFINE CELL NAME "TURNO"      OF oSecFun TITLE "Turno" 
		DEFINE CELL NAME "DESCTURNO"  OF oSecFun TITLE "Desc. do Turno" 
        
		DEFINE CELL NAME "RA_DEPTO"   OF oSecFun ALIAS "SRA"
		DEFINE CELL NAME "QB_DESCRIC" OF oSecFun ALIAS "SQB"
		
		If SRA->(FIELDPOS("RA_KEYLOC")) > 0
			DEFINE CELL NAME "RA_KEYLOC"  OF oSecFun ALIAS "SRA"
			DEFINE CELL NAME "RGC_DESLOC" OF oSecFun ALIAS "RGC"
		EndIf

		If SRA->(FIELDPOS("RA_CODRPAT")) > 0
			DEFINE CELL NAME "RA_CODRPAT" OF oSecFun ALIAS "SRA"
			DEFINE CELL NAME "RCO_NREPAT" OF oSecFun ALIAS "RCO"
			DEFINE CELL NAME "RCO_NOME"   OF oSecFun ALIAS "RCO"
		EndIf
		
		oSecFun:SetTotalInLine(.F.)
		oSecFun:Cell("SINAL"     ):Disable()              
		oSecFun:Cell("STATUS"    ):Disable()
		oSecFun:Cell("QB_DESCRIC"):Disable()

		If SRA->(FIELDPOS("RA_KEYLOC")) > 0
			oSecFun:Cell("RGC_DESLOC"):Disable() 
		EndIf
		
		If SRA->(FIELDPOS("RA_CODRPAT")) > 0
			oSecFun:Cell("RCO_NOME"  ):Disable()
			TRPosition():New(oSecFun,"RCO",1,{|| xFilial("RCO",(cAliasQry)->RA_FILIAL)+(cAliasQry)->RA_CODRPAT},.T.)
		EndIf
		
		oSecFun:Disable()
		oSecFun:SetDynamicKey(OemToAnsi(STR0004))	//"Matrícula"
		
 
	//Section 2                                         
	DEFINE Section oSectionh OF oReport TITLE OemToAnsi(STR0024) TABLE "SRA" ORDERS aOrd	PAGE HEADER	//Processo / Periodo

		DEFINE CELL NAME "PROCESSO"   OF oSectionh TITLE OemToAnsi(STR0014) SIZE 5 BLOCK {||cProcesso} 		//Processo: 
		DEFINE CELL NAME "PERIODO" 	  OF oSectionh TITLE OemToAnsi(STR0015) SIZE 6 BLOCK {||cPeriodo}		//Periodo: 
		DEFINE CELL NAME "PAGAMENTO"  OF oSectionh TITLE OemToAnsi(STR0016) SIZE 2 BLOCK {||cPagamento} 	//Pagamento:
		DEFINE CELL NAME "ROTEIRO"    OF oSectionh TITLE OemToAnsi(STR0017) SIZE 3 BLOCK {||cRot}		//Roteiro:
    
		oSectionh:SetLineStyle()  

	//Section 3
	DEFINE Section oSecNom OF oReport TITLE OemToAnsi(STR0024) TABLES "SRA", "SQB", "RGC", "RCO" ORDERS aOrd	//Processo / Periodo

		DEFINE CELL NAME "RA_FILIAL"  OF oSecNom ALIAS "SRA" BLOCK {||IIf(lRepete,"",(cAliasQry)->RA_FILIAL)} TITLE OemToAnsi(STR0020)	//"Fil."
		DEFINE CELL NAME "RA_NOME"    OF oSecNom ALIAS "SRA" BLOCK {|| If(!Empty((cAliasQry)->RA_NSOCIAL),(cAliasQry)->RA_NSOCIAL,(_cAliaQRY)->RA_NOME)	}
		DEFINE CELL NAME "RA_MAT"     OF oSecNom ALIAS "SRA" TITLE OemToAnsi(STR0011)	//"Matric."
		DEFINE CELL NAME "SINAL"      OF oSecNom TITLE "."
		DEFINE CELL NAME "STATUS"     OF oSecNom TITLE "."

		DEFINE CELL NAME "RA_CC"      OF oSecNom ALIAS "SRA" 
		DEFINE CELL NAME "RA_DEPTO"   OF oSecNom ALIAS "SRA"
		DEFINE CELL NAME "QB_DESCRIC" OF oSecNom ALIAS "SQB"
		
		If SRA->(FIELDPOS("RA_KEYLOC")) > 0
			DEFINE CELL NAME "RA_KEYLOC"  OF oSecNom ALIAS "SRA"
			DEFINE CELL NAME "RGC_DESLOC" OF oSecNom ALIAS "RGC"
			oSecNom:Cell("RGC_DESLOC"):Disable()
		EndIf

		If SRA->(FIELDPOS("RA_CODRPAT")) > 0
			DEFINE CELL NAME "RA_CODRPAT" OF oSecNom ALIAS "SRA"
			DEFINE CELL NAME "RCO_NREPAT" OF oSecNom ALIAS "RCO"
			DEFINE CELL NAME "RCO_NOME"   OF oSecNom ALIAS "RCO"
			oSecNom:Cell("RCO_NOME"  ):Disable()
		EndIf	

		oSecNom:SetTotalInLine(.F.)
		oSecNom:Cell("SINAL"     ):Disable()
		oSecNom:Cell("STATUS"    ):Disable()
		oSecNom:Cell("QB_DESCRIC"):Disable() 

		oSecNom:Disable()
		oSecNom:SetDynamicKey(OemToAnsi(STR0006))	//"Nome"
		
		
		If SRA->(FIELDPOS("RA_CODRPAT")) > 0
			TRPosition():New(oSecNom,"RCO",1,{|| xFilial("RCO",(cAliasQry)->RA_FILIAL)+(cAliasQry)->RA_CODRPAT},.T.)
		EndIf
		
	//Section 4
	DEFINE Section oSecCtt OF oReport TABLES "SRA", "SQB" ORDERS aOrd TITLE OemToAnsi(STR0007) TOTAL IN COLUMN // "Centro de Custo"
		
		DEFINE CELL NAME "RA_FILIAL" 	OF oSecCtt ALIAS "SRA"
		DEFINE CELL NAME "RA_CC"    	OF oSecCtt SIZE(50) BLOCK {|| (cAliasQry)->CCUSTO + " - " + Posicione("CTT",1,xFilial( "CTT",(cAliasQry)->FILIAL ) + (cAliasQry)->CCUSTO, "CTT_DESC01") }
		DEFINE CELL NAME "SINAL"    	OF oSecCtt TITLE "."
		DEFINE CELL NAME "STATUS"   	OF oSecCtt TITLE "."
		
		DEFINE CELL NAME "QB_DEPTO"		OF oSecCtt ALIAS "SQB"
		DEFINE CELL NAME "QB_DESCRIC"	OF oSecCtt ALIAS "SQB"
		
		oSecCtt:Cell("QB_DEPTO"):Disable()
		oSecCtt:Cell("QB_DESCRIC"):Disable()

		oSecCtt:Cell("SINAL"     ):Disable()
		oSecCtt:Cell("STATUS"    ):Disable()
		oSecCtt:Disable()
		oSecCtt:SetDynamicKey(OemToAnsi(STR0005))	//"C.Custo"

	//Section 5
	DEFINE Section oSecSqb OF oReport TABLES "SRA", "SQB" ORDERS aOrd TITLE OemToAnsi(STR0009) TOTAL IN COLUMN // "Departamento"
		
		DEFINE CELL NAME "RA_FILIAL" 	OF oSecSqb ALIAS "SRA"
		DEFINE CELL NAME "RA_CC"		OF oSecSqb ALIAS "SQB"
		DEFINE CELL NAME "RA_DEPTO"   	OF oSecSqb ALIAS "SRA"
		DEFINE CELL NAME "QB_DEPTO"		OF oSecSqb ALIAS "SQB"
		DEFINE CELL NAME "QB_DESCRIC"	OF oSecSqb ALIAS "SQB"

		oSecSqb:Cell("RA_FILIAL"):Disable()                  
		oSecSqb:Cell("RA_CC"    ):Disable() 
		oSecSqb:Cell("QB_DEPTO" ):Disable()
		oSecSqb:Disable()
		oSecSqb:SetDynamicKey(OemToAnsi(STR0008))	//"Depto."
		TRPosition():New(oSecSqb,"SQB",1,{|| RhFilial("SQB",(cAliasQry)->RA_FILIAL)+(cAliasQry)->RA_DEPTO},.T.)

		If SRA->(FIELDPOS("RA_KEYLOC")) > 0
			DEFINE Section oSecRgc OF oReport TABLES "RGC", "SRA" ORDERS aOrd TITLE OemToAnsi(STR0029) TOTAL IN COLUMN // "Localidade Pagamento"
			DEFINE CELL NAME "RA_FILIAL" 	OF oSecRgc ALIAS "SRA"
			DEFINE CELL NAME "RA_KEYLOC" 	OF oSecRgc ALIAS "RGC"
			DEFINE CELL NAME "RGC_DESLOC"	OF oSecRgc ALIAS "RGC"
        
			oSecRgc:Cell("RA_FILIAL"):Disable()
			oSecRgc:Disable()
			oSecRgc:SetDynamicKey(OemToAnsi(IIf(cPaisLoc == "COL", STR0045, STR0028)))	//"Loc.Pago" - Para COL se utiliza "Centro Trab."
			TRPosition():New(oSecRgc,"RGC",1,{|| RhFilial("RGC",(cAliasQry)->RA_FILIAL)+(cAliasQry)->RA_KEYLOC},.T.)
		EndIf

		If SRA->(FIELDPOS("RA_CODRPAT")) > 0
			DEFINE Section oSecRco OF oReport TABLES "RCO" ORDERS aOrd TITLE OemToAnsi(STR0032) TOTAL IN COLUMN // "Registro Patronal"
		
			DEFINE CELL NAME "RA_FILIAL" 	OF oSecRco ALIAS "RCO"
			DEFINE CELL NAME "RA_CODRPAT"   OF oSecRco ALIAS "SRA"
			DEFINE CELL NAME "RCO_CODIGO"  	OF oSecRco ALIAS "RCO"
			DEFINE CELL NAME "RCO_NREPAT"	OF oSecRco ALIAS "RCO"
			DEFINE CELL NAME "RCO_NOME" 	OF oSecRco ALIAS "RCO"

			oSecRco:Cell("RA_FILIAL" ):Disable()
			oSecRco:Cell("RCO_CODIGO"):Disable()
			oSecRco:Disable()
			oSecRco:SetDynamicKey(OemToAnsi(STR0031))	//"Reg.Patronal"
		EndIf

Return(oReport)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³ R103Imp    ³ Autor ³ Tania Bronzeri        ³ Data ³15/08/2007³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Relatorio de Valores por Verba                               ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ GPER103                                                      ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Static Function R103Imp(oReport)
Local aAreaRep 		:= FWGetArea()
Local oSectionh		:= oReport:Section(2)
Local oSectDet
Local cFiltro 		:= ""
Local cValidFil		:= ""
Local cVerQry		:= ""
Local cSraCpoAdd	:= ""
Local cVerQry0		:= ""
Local cUnion		:= ""
Local cUnionSRD		:= ""
Local cSum			:= ""
Local cCellVerba	:= ""
Local cTitFil		:= ""

Local cTitUN		:= ""
Local cTitEFil		:= ""

Local cTitCC		:= ""
Local cTitDp		:= ""
Local cTitLp		:= ""
Local cTitRpt		:= ""
Local cCodigos		:= ""
Local cOrdem		:= ""
Local cAls			:= ""
Local cPref			:= ""
Local cCountQ		:= ""
Local cCpoQuebra	:= "" 
Local cCpoQuebr2	:= ""
Local cCpoDelim		:= "" 
Local cOrgJoin		:= ""
Local cChaveArq		:= ""
Local cVisaoDepto	:= ""
Local nX			:= 0
Local nReg			:= 0
Local nCont			:= 0
Local aQryVerba		:= {}
Local aVerQry		:= {}
Local aChaveArq		:= array(2)
Local lShar			:= .T.
Local aPosics		:= Array(3)
Local aValidFil		:= StrToArray(fValidFil(,.T.),"/")
Local aValidFil2	:= StrToArray(fValidFil(),"/")

Local oBreakFil
Local oBreakUnN
Local oBreakEFil

Private oSectHead
Private oSectSubHd
Private nSinAna		:= 0
Private aVerbas		:= {}
Private aVerbasRet	:= {}
Private aVerbasSin	:= {}
Private aPerAberto	:= {}
Private aPerFechado	:= {} 
Private cCodVisao	:= ""
Private cCodDepto	:= ""

cSituacao   := MV_PAR06					
cCategoria 	:= MV_PAR07					
nSinAna   	:= MV_PAR08						// 1-Analitico ou 2-Sintetico
cProcesso	:= MV_PAR09        		
cRot		:= MV_PAR10        
cPeriodo	:= MV_PAR11        
cPagamento	:= MV_PAR12        			
cCodigos  	:= AllTrim(MV_PAR13)			// Codigos ( Verbas )

If Empty(MV_PAR14)
	lImpEmpr := .F.							// Listar total empresa
Else
	lImpEmpr := MV_PAR14 == 1
EndIf

If Empty(MV_PAR15)
	lImpLiq := .F.							
Else
	lImpLiq := MV_PAR15 == 1
EndIf

If Len(AllTrim(cCodigos)) == 0
	Aviso(OemToAnsi(STR0034), OemToAnsi(STR0035), {"OK"})	//"Atenção!" ### "Não foi selecionada nenhuma verba para impressão. Favor selecionar pelo menos uma verba."
	Return
EndIf

If ValType(MV_PAR18) == "N"
	nVerHor := MV_PAR18
Else
	nVerHor := 1
EndIf

If "*" $ cCodigos
	MsgAlert(OemToAnsi(STR0041),OemToAnsi(STR0034))	//"Máximo de verbas para impressão é 15. Selecione os códigos" ### "Aten;'ao!"
	FWRestArea(aAreaRep)
	Return
EndIf

If nVerHor == 1
	If Len(AllTrim(cCodigos)) > 30 .And. !lImpLiq
		MsgAlert(OemToAnsi(STR0042),OemToAnsi(STR0034))	//"Não é possível listar mais do que 10 verbas, quando solicitado exibição em valores." ### "Aten;'ao!"
		Return
	ElseIf lImpLiq .And. Len(AllTrim(cCodigos)) > 27
		MsgAlert(OemToAnsi(STR0043),OemToAnsi(STR0034))	//"Não é possível listar mais do que 9 verbas, quando solicitado exibição em valores e valor líquido." ### "Aten;'ao!"
		Return
	EndIf
Else
	If lImpLiq .And. Len(AllTrim(cCodigos)) > 42
		MsgAlert(OemToAnsi(STR0044),OemToAnsi(STR0034))	//"Não é possível listar mais do que 14 verbas, quando solicitado exibição em horas e valor líquido." ### "Aten;'ao!"
		Return
	EndIf
EndIf

cCodDepto	:= MV_PAR17
If lUsaArqui 	//Se uas Arquitetura Organizadional (SIGAORG)
	cCodVisao	:= MV_PAR16
Else
	cCodVisao	:= ""
EndIf  

If !Empty(cCodVisao + cCodDepto)
	aChaveArq	:= fQueryVisao()
	cChaveArq	:= aChaveArq[2]
	lShar		:= IIf(Empty(aChaveArq[1]),.T.,.F.)
	cOrgJoin	:= " INNER JOIN (SELECT RD4.RD4_FILIDE, RD4.RD4_CODIDE, RD4.RD4_CHAVE "
	cOrgJoin	+= " FROM " + RetSqlName("RD4") + " RD4 "
	cOrgJoin	+= " WHERE RD4_CHAVE LIKE '" + AllTrim(cChaveArq) + "%' AND RD4.D_E_L_E_T_ = ' ' ) TVRD4 "
	cOrgJoin	+= " ON TRB.RA_DEPTO = TVRD4.RD4_CODIDE "
	If !lShar
		cOrgJoin+= " AND TRB.RA_FILIAL = TVRD4.RD4_FILIDE "
	EndIf
	
    oSectionh:Cell("ROTEIRO"):SetCellBreak(.T.)
	cVisaoDepto	:=	OemToAnsi(STR0037) + AllTrim(cCodVisao) + " / " + 	;	//"Visão: "
					OemToAnsi(STR0008) + AllTrim(cCodDepto)					//"Depto.: "  	
					
	DEFINE CELL NAME "ARQORG"  OF oSectionh TITLE OemToAnsi(STR0036) SIZE 125	;	//"Arquitetura Organizacional - " 
				BLOCK {|| cVisaoDepto}

EndIf

cCodigos	:= IIf(lImpLiq,AllTrim(Left(cCodigos+Space(42),42)),AllTrim(Left(cCodigos+Space(45),45)))
nOrdem		:= oReport:GetOrder()

If nOrdem == 1		//Matrícula
	oSectDet 	:= oReport:Section(1)
ElseIf nOrdem == 2	//Nome
	oSectDet	:= oReport:Section(3)
ElseIf nOrdem == 3	//C.Custo + Matrícula
	If nSinAna == 1	//Analitico
		oSectHead:= oReport:Section(4)
		oSectHead:SetLineStyle()
		oSectHead:SetCharSeparator(": ")
		oSectDet	:= oReport:Section(1)
	Else	//Sintetico
		oSectHead	:= oReport:Section(1)
		oSectDet	:= oReport:Section(4)		 
		oSectDet:HideHeader()
		oSectDet:SetHeaderSection(.T.)
	EndIf
ElseIf nOrdem == 4	//C.Custo + Nome
	If nSinAna == 1	//Analitico
		oSectHead:= oReport:Section(4)
		oSectHead:SetLineStyle()
		oSectHead:SetCharSeparator(": ")
		oSectDet	:= oReport:Section(3)
	Else	//Sintetico
		oSectHead	:= oReport:Section(3) 
		oSectDet	:= oReport:Section(4)
		oSectDet:HideHeader()
		oSectDet:SetHeaderSection(.T.)
	EndIf
ElseIf nOrdem == 5	//Depto + Matrícula
	If nSinAna == 1	//Analitico
		oSectHead	:= oReport:Section(5)
		oSectDet	:= oReport:Section(1) 
		oSectHead:SetLineStyle()
		oSectHead:SetCharSeparator(": ")
	Else	//Sintetico
		oSectDet	:= oReport:Section(5)
		oSectHead	:= oReport:Section(1) 
		oSectDet:HideHeader()
		oSectDet:SetHeaderSection(.T.)
	EndIf
ElseIf nOrdem == 6	//Depto + Nome
	If nSinAna == 1	//Analitico
		oSectHead	:= oReport:Section(5)
		oSectDet	:= oReport:Section(3)
		oSectHead:SetLineStyle()
		oSectHead:SetCharSeparator(": ")
	Else	//Sintetico
		oSectDet	:= oReport:Section(5)
		oSectHead	:= oReport:Section(3) 
		oSectDet:HideHeader()
		oSectDet:SetHeaderSection(.T.)
	EndIf
ElseIf nOrdem == 7	//C.Custo + Depto + Matrícula
	If nSinAna == 1	//Analitico
		oSectHead	:= oReport:Section(4)
		oSectHead:SetLineStyle()
		oSectHead:SetCharSeparator(": ")
		oSectSubHd	:= oReport:Section(5)
		oSectSubHd:SetLineStyle()
		oSectSubHd:SetCharSeparator(": ")
		oSectDet	:= oReport:Section(1)
	Else	//Sintetico
		oSectHead	:= oReport:Section(4)
		oSectHead:SetLineStyle()
		oSectHead:SetCharSeparator(": ")
		oSectSubHd	:= oReport:Section(5)
		oSectSubHd:SetLineStyle()
		oSectSubHd:SetCharSeparator(": ")
		oSectDet	:= oReport:Section(1) 
	EndIf
ElseIf nOrdem == 8	//C.Custo + Depto + Nome
	If nSinAna == 1	//Analitico
		oSectHead:= oReport:Section(4)
		oSectHead:SetLineStyle()
		oSectHead:SetCharSeparator(": ")
		oSectSubHd	:= oReport:Section(5)
		oSectSubHd:SetLineStyle()
		oSectSubHd:SetCharSeparator(": ")
		oSectDet	:= oReport:Section(3)
	Else	//Sintetico
		oSectHead	:= oReport:Section(4)
		oSectHead:SetLineStyle()
		oSectHead:SetCharSeparator(": ")
		oSectSubHd	:= oReport:Section(5)
		oSectSubHd:SetLineStyle()
		oSectSubHd:SetCharSeparator(": ")
		oSectDet	:= oReport:Section(3) 
	EndIf
ElseIf nOrdem == 9	//Local.Pago + Matrícula
	If nSinAna == 1	//Analitico
		oSectHead	:= oReport:Section(6)
		oSectDet	:= oReport:Section(1) 
		oSectHead:SetLineStyle()
		oSectHead:SetCharSeparator(": ")
	Else	//Sintetico
		oSectDet	:= oReport:Section(6)
		oSectHead	:= oReport:Section(1) 
		oSectDet:HideHeader()
		oSectDet:SetHeaderSection(.T.)
	EndIf
ElseIf nOrdem == 10	//Local.Pago + Nome
	If nSinAna == 1	//Analitico
		oSectHead	:= oReport:Section(6)
		oSectDet	:= oReport:Section(3)
		oSectHead:SetLineStyle()
		oSectHead:SetCharSeparator(": ")
	Else	//Sintetico
		oSectDet	:= oReport:Section(6)
		oSectHead	:= oReport:Section(3) 
		oSectDet:HideHeader()
		oSectDet:SetHeaderSection(.T.)
	EndIf
ElseIf nOrdem == 11	//Reg.Patronal + Matrícula
	If nSinAna == 1	//Analitico
		oSectHead	:= oReport:Section(7)
		oSectDet	:= oReport:Section(1) 
		oSectHead:SetLineStyle()
		oSectHead:SetCharSeparator(": ")
	Else	//Sintetico
		oSectDet	:= oReport:Section(7)
		oSectHead	:= oReport:Section(1) 
		oSectDet:HideHeader()
		oSectDet:SetHeaderSection(.T.)
	EndIf
ElseIf nOrdem == 12	//Reg.Patronal + Nome
	If nSinAna == 1	//Analitico
		oSectHead	:= oReport:Section(7)
		oSectDet	:= oReport:Section(3)
		oSectHead:SetLineStyle()
		oSectHead:SetCharSeparator(": ")
	Else	//Sintetico
		oSectDet	:= oReport:Section(7)
		oSectHead	:= oReport:Section(3) 
		oSectDet:HideHeader()
		oSectDet:SetHeaderSection(.T.)
	EndIf
EndIf

If nSinAna == 1	//Analitico

	If nOrdem == 9 .Or. nOrdem == 10 			
		oSectDet:Cell("RA_KEYLOC" ):Disable()
	EndIf
	
	If nOrdem == 11 .Or. nOrdem == 12			
		oSectDet:Cell("RA_CODRPAT"):Disable()
		oSectDet:Cell("RCO_NREPAT"):Disable()
		oSectDet:Cell("RCO_NOME"  ):Disable()
	EndIf	

Else //Sintetico

	If nOrdem == 3 .Or. nOrdem == 4	
		oSectHead:Cell("RA_CC"):bCellBlock := { || (cAliasQry)->CCUSTO }
	EndIf
	
	If nOrdem == 7 .Or. nOrdem == 8		
		oSectSubHd:Cell("RA_CC"):bCellBlock := { || (cAliasQry)->CCUSTO }				
	EndIf 
	
EndIf

If !(AllTrim(oReport:Title()) == cTitulo)
	cTitulo	:= oReport:Title()
EndIf

If nOrdem == 3 .Or. nOrdem == 4 .Or. nOrdem == 7 .Or. nOrdem == 8		//Centro de Custo
	If nSinAna == 2	//Sintetico	
		cCpoQuebra := "CCUSTO" 
		If nOrdem == 7 .Or. nOrdem == 8
			DEFINE BREAK oBreakCC OF oReport WHEN  {||(cAliasQry)->RA_FILIAL+(cAliasQry)->CCUSTO} TITLE OemToAnsi(STR0013) //"Total do Centro de Custo "
			oBreakCc:OnBreak({|x,y|cTitCC:=SubStr(x,TamSX3("RA_FILIAL ")[1]+1,TamSX3("RA_CC     ")[1])})
	    	oBreakCc:SetTotalText({||cTitCC:=OemToAnsi(STR0013)+" "+cTitCC})
	    	oBreakCc:SetTotalInLine(.F.)                                                                
	  	Else
  			oSectDet:Cell("RA_CC"):Enable()
		EndIf
	Else			//Analitico
		oSectDet:Cell( "RA_CC"):Disable()

		DEFINE BREAK oBreakCC OF oSectHead WHEN  {||(cAliasQry)->RA_FILIAL+(cAliasQry)->CCUSTO} TITLE OemToAnsi(STR0013) //"Total do Centro de Custo "
		
		oBreakCc:OnBreak({|x,y|cTitCC:=OemToAnsi(STR0013) + " " + oSectHead:Cell("RA_CC"):GetText()})
    	oBreakCc:SetTotalText({||cTitCC})
    	oBreakCc:SetTotalInLine(.F.)                                                                
	EndIf

EndIf

If nOrdem == 5 .Or. nOrdem == 6 .Or. nOrdem == 7 .Or. nOrdem == 8		//Departamento

	If nSinAna == 2	//Sintetico
	
		If nOrdem == 7 .Or. nOrdem == 8
		
			cCpoQuebr2	:= "RA_DEPTO, QB_DESCRIC"		
			oSectDet:Cell( "RA_FILIAL"  ):Disable()
			oSectDet:Cell( "RA_MAT"     ):Disable()
			oSectDet:Cell( "RA_NOME"    ):Disable()
			oSectDet:Cell( "RA_CC"      ):Disable()
			
			If SRA->(FIELDPOS("RA_CODRPAT")) > 0
				oSectDet:Cell( "RA_CODRPAT" ):Disable() 
				oSectDet:Cell( "RCO_NREPAT" ):Disable()
				oSectDet:Cell( "RCO_NOME"   ):Disable()
			EndIf
			
			If SRA->(FIELDPOS("RA_KEYLOC")) > 0
				oSectDet:Cell( "RA_KEYLOC"  ):Disable()
			EndIf
			
			oSectSubHd:Cell("RA_DEPTO"  ):Disable()
			oSectSubHd:Cell("QB_DESCRIC"):Disable()
			oSectSubHd:Cell("RA_FILIAL" ):Enable()
			oSectSubHd:Cell("RA_CC"     ):Enable()
		Else
			cCpoQuebra	:= "RA_DEPTO, QB_DESCRIC"			 			
			oSectHead:Cell("QB_DESCRIC"):Disable()			
		EndIf
		
		oSectDet:Cell( "RA_FILIAL"):Enable()		
		oSectDet:Cell( "RA_DEPTO"  ):Enable() 
		oSectDet:Cell( "QB_DESCRIC"):Enable()
		TRPosition():New(oSectDet,"SQB",1,{|| RhFilial("SQB",(cAliasQry)->RA_FILIAL)+(cAliasQry)->RA_DEPTO},.T.)
	Else			//Analitico
		oSectDet:Cell( "RA_DEPTO"  ):Disable() 
		oSectDet:Cell( "QB_DESCRIC"):Disable()
		
		If nOrdem == 7 .Or. nOrdem == 8
			oSectSubHd:Cell("QB_DESCRIC"):Enable()
			DEFINE BREAK oBreakDp OF oSectSubHd WHEN  {||(cAliasQry)->RA_FILIAL+(cAliasQry)->CCUSTO+(cAliasQry)->RA_DEPTO} TITLE OemToAnsi(STR0018) //"Total do Departamento"
			oBreakDp:OnBreak({|x,y|cTitDp := oSectSubHd:Cell("QB_DEPTO"):GetText() + " - " + oSectSubHd:Cell("QB_DESCRIC"):GetText()})
		Else 
			oSectHead:Cell("QB_DESCRIC"):Enable()
			DEFINE BREAK oBreakDp OF oSectHead WHEN  {||(cAliasQry)->RA_FILIAL+(cAliasQry)->RA_DEPTO} TITLE OemToAnsi(STR0018) //"Total do Departamento"
			oBreakDp:OnBreak({|x,y|cTitDp := oSectHead:Cell("QB_DEPTO"):GetText() + " - " + oSectHead:Cell("QB_DESCRIC"):GetText()})
		EndIf

    	oBreakDp:SetTotalText({||cTitDp:=OemToAnsi(STR0018)+" "+cTitDp})
    	oBreakDp:SetTotalInLine(.F.)                                                                
	EndIf
EndIf
                                 
If nOrdem == 9 .Or. nOrdem == 10 		//Loc.Pago
	If nSinAna == 2	//Sintetico
		cCpoQuebra	:= "RA_KEYLOC" 
		oSectDet:Cell( "RA_KEYLOC" ):Enable() 
		oSectDet:Cell( "RGC_DESLOC"):Enable()
		TRPosition():New(oSectDet,"RGC",1,{|| RhFilial("RGC",(cAliasQry)->RA_FILIAL)+(cAliasQry)->RA_KEYLOC},.T.)

	Else			//Analitico
		oSectDet:Cell("RA_FILIAL"  ):Disable()
		oSectDet:Cell( "RGC_DESLOC"):Disable()
		oSectHead:Cell("RA_FILIAL" ):Enable()
		oSectHead:Cell("RGC_DESLOC"):Enable()
		DEFINE BREAK oBreakLp OF oSectHead WHEN  {||(cAliasQry)->RA_KEYLOC} TITLE OemToAnsi(STR0030) //"Total da Localidade de Pagamento"
		oBreakLp:OnBreak({|x,y|cTitLp:=x})	
    	oBreakLp:SetTotalText({||cTitLp:=OemToAnsi(STR0030)+" "+cTitLp})
    	oBreakLp:SetTotalInLine(.F.)                                                                
	EndIf
EndIf
                                 
If nOrdem == 11 .Or. nOrdem == 12 		//Reg.Patronal
	If nSinAna == 2	//Sintetico
		cCpoQuebra	:= "RA_CODRPAT" 
		oSectDet:Cell( "RA_FILIAL" ):Enable()
		oSectDet:Cell( "RA_CODRPAT"):Enable() 
		oSectDet:Cell( "RCO_NREPAT"):Enable()
		oSectDet:Cell( "RCO_NOME"  ):Enable()
		TRPosition():New(oSectDet,"RCO",1,{|| RhFilial("RCO",(cAliasQry)->RA_FILIAL)+(cAliasQry)->RA_CODRPAT},.T.)
	Else			//Analitico
		oSectDet:Cell( "RA_FILIAL" ):Disable()
		oSectDet:Cell( "RA_CODRPAT"):Disable() 
		oSectHead:Cell("RA_CODRPAT"):Disable() 
		oSectHead:Cell("RA_FILIAL" ):Enable()
		oSectHead:Cell("RCO_CODIGO"):Enable()
		DEFINE BREAK oBreakRpt OF oSectHead WHEN  {||(cAliasQry)->RA_FILIAL+(cAliasQry)->RA_CODRPAT} TITLE OemToAnsi(STR0033) //"Total do Registro Patronal"
		oBreakRpt:OnBreak({|x,y|cTitRpt:=SubStr(x,TamSX3("RA_FILIAL")[1]+1,TamSX3("RA_CODRPAT")[1])})	
    	oBreakRpt:SetTotalText({||cTitRpt:=OemToAnsi(STR0033)+" "+cTitRpt})
    	oBreakRpt:SetTotalInLine(.F.)                                                                
	EndIf
EndIf

If (nSinAna == 1)	//Analitico
	If nOrdem == 1 .Or. nOrdem == 2
		If (SRA->(FIELDPOS("RA_KEYLOC")) > 0)
			oSectDet:Cell( "RGC_DESLOC"):Disable()
		EndIf
		DEFINE BREAK oBreakFil OF oSectDet  WHEN {||(cAliasQry)->RA_FILIAL} TITLE OemToAnsi(STR0019) //"Total da Filial "

		If lCorpManage
			If lUniNeg
				DEFINE BREAK oBreakUnN OF oSectDet WHEN {|| SubStr((cAliasQry)->RA_FILIAL, nStartUnN, nUnNLength) }
			EndIf
			If lEmpFil
				DEFINE BREAK oBreakEFil OF oSectDet WHEN  { || SubStr((cAliasQry)->RA_FILIAL, nStartEmp, nEmpLength) }
			EndIf
		EndIf
	Else   
		DEFINE BREAK oBreakFil OF oReport WHEN {||(cAliasQry)->RA_FILIAL} TITLE OemToAnsi(STR0019) //"Total da Filial "

		If lCorpManage
			If lUniNeg
				DEFINE BREAK oBreakUnN OF oReport WHEN {|| SubStr((cAliasQry)->RA_FILIAL, nStartUnN, nUnNLength) }
			EndIf
			If lEmpFil
				DEFINE BREAK oBreakEFil OF oReport WHEN  { || SubStr((cAliasQry)->RA_FILIAL, nStartEmp, nEmpLength) }
			EndIf
		EndIf
	EndIf
Else   //Sintetico
	If nOrdem == 1 .Or. nOrdem == 2   
		oSectDet:Cell( "RA_MAT"	   ):Disable()
		oSectDet:Cell( "RA_NOME"   ):Disable() 
		
		If SRA->(FIELDPOS("RA_CODRPAT")) > 0
			oSectDet:Cell( "RA_CODRPAT"):Disable() 
			oSectDet:Cell( "RCO_NREPAT"):Disable()
		EndIf
		
		oSectDet:Cell( "RA_CC"     ):Disable()	
		oSectDet:Cell( "RA_DEPTO"  ):Disable()	
		
		If (SRA->(FIELDPOS("RA_KEYLOC")) > 0)
			oSectDet:Cell( "RA_KEYLOC" ):Disable()		
		EndIf
		
	EndIf	
	DEFINE BREAK oBreakFil OF oReport WHEN {||(cAliasQry)->RA_FILIAL} TITLE OemToAnsi(STR0019) //"Total da Filial "
	
	If lCorpManage
		If lUniNeg
			DEFINE BREAK oBreakUnN OF oReport WHEN {|| SubStr((cAliasQry)->RA_FILIAL, nStartUnN, nUnNLength) }
		EndIf
		If lEmpFil
			DEFINE BREAK oBreakEFil OF oReport WHEN  { || SubStr((cAliasQry)->RA_FILIAL, nStartEmp, nEmpLength) }
		EndIf
	EndIf
EndIf

oBreakFil:OnBreak({|x,y|cTitFil:=x,	oSectDet:SetHeaderSection(.T.)})	
oBreakFil:SetTotalText({||cTitFil:=OemToAnsi(STR0019)+" "+cTitFil})
oBreakFil:SetTotalInLine(.F.)

If lCorpManage
	If lUniNeg
		oBreakUnN:OnBreak({|x,y| cTitUN := x,	oSectDet:SetHeaderSection(.T.)})	
		oBreakUnN:SetTotalText({|| cTitUN := OemToAnsi(STR0039)+": "+cTitUN})
		oBreakUnN:SetTotalInLine(.F.)
	EndIf
	
	If lEmpFil
		oBreakEFil:OnBreak({|x,y| cTitEFil := x,	oSectDet:SetHeaderSection(.T.)})	
		oBreakEFil:SetTotalText({|| cTitEFil := OemToAnsi(STR0040)+": "+cTitEFil})
		oBreakEFil:SetTotalInLine(.F.)
	EndIf
EndIf

For nCont:= 1 to Len(AllTrim(cCodigos)) Step 3
	cCellVerba	:= SubStr(cCodigos,nCont,3)
	DEFINE CELL NAME (cCellVerba) OF oSectDet TITLE SubStr(cCellVerba,2,3) PICTURE "@E 99,999,999,999.99" SIZE 20 BLOCK {||(cAliasQry)->("V"+&(cCellVerba))}
	oSectDet:Cell(cCellVerba):SetHeaderAlign("RIGHT")
	oSectDet:Cell(cCellVerba):SetAutoSize()		
	oSectDet:Cell(cCellVerba):SetTitle(cCellVerba+"-"+DescPd(cCellVerba,xFilial("SRA"),8))	//Cod.+Descricao
	DEFINE FUNCTION NAME ("T"+cCellVerba) FROM oSectDet:Cell(cCellVerba) FUNCTION SUM PICTURE "@E 99,999,999,999.99"	NO END Section
	If nSinAna == 1	//Analitico
		If nOrdem == 5 .Or. nOrdem == 6 .Or. nOrdem == 7 .Or. nOrdem == 8	//Depto ou C.Custo + Depto
			DEFINE FUNCTION NAME ("D"+cCellVerba) FROM oSectDet:Cell(cCellVerba) FUNCTION SUM BREAK oBreakDp NO END Section NO END REPORT PICTURE "@E 99,999,999,999.99"  
		EndIf
		If nOrdem == 3 .Or. nOrdem == 4 .Or. nOrdem == 7 .Or. nOrdem == 8	//C.Custo ou C.Custo + Depto
			DEFINE FUNCTION NAME ("C"+cCellVerba) FROM oSectDet:Cell(cCellVerba) FUNCTION SUM BREAK oBreakCC NO END Section NO END REPORT PICTURE "@E 99,999,999,999.99"  
		EndIf
		If nOrdem == 9 .Or. nOrdem == 10 	//Localidade Pagamento
			DEFINE FUNCTION NAME ("L"+cCellVerba) FROM oSectDet:Cell(cCellVerba) FUNCTION SUM BREAK oBreakLp NO END Section NO END REPORT PICTURE "@E 99,999,999,999.99"  
		EndIf
		If nOrdem == 11 .Or. nOrdem == 12 	//Registro Patronal
			DEFINE FUNCTION NAME ("R"+cCellVerba) FROM oSectDet:Cell(cCellVerba) FUNCTION SUM BREAK oBreakRpt NO END Section NO END REPORT PICTURE "@E 99,999,999,999.99"  
		EndIf
	Else			//Sintetico
		If nOrdem == 7 .Or. nOrdem == 8
			DEFINE FUNCTION NAME ("C"+cCellVerba) FROM oSectDet:Cell(cCellVerba) FUNCTION SUM BREAK oBreakCC NO END Section NO END REPORT PICTURE "@E 99,999,999,999.99"  
		EndIf
	EndIf
	DEFINE FUNCTION NAME ("F"+cCellVerba) FROM oSectDet:Cell(cCellVerba) FUNCTION SUM BREAK oBreakFil NO END Section NO END REPORT PICTURE "@E 99,999,999,999.99"  
	aAdd(aQryVerba,AllTrim(cCellVerba))
	
	If lCorpManage
		If lUniNeg
			DEFINE FUNCTION NAME ("FUN"+cCellVerba) FROM oSectDet:Cell(cCellVerba) FUNCTION SUM BREAK oBreakUnN NO END Section NO END REPORT PICTURE "@E 99,999,999,999.99"
		EndIf
		If lEmpFil
			DEFINE FUNCTION NAME ("FEF"+cCellVerba) FROM oSectDet:Cell(cCellVerba) FUNCTION SUM BREAK oBreakEFil NO END Section NO END REPORT PICTURE "@E 99,999,999,999.99"
		EndIf
	EndIf
Next

If nSinAna == 2	//Sintetico
	cTitulo	+= " - " + OemToAnsi(STR0027)	//Sintético
Else		//Analitico
	oSectDet:Cell("RA_MAT"    ):Enable()
	oSectDet:Cell("RA_NOME"   ):Enable()
	oSectDet:Cell("RA_DEPTO"  ):Disable()
	oSectDet:Cell("RA_MAT"    ):SetBlock({||IIf(lRepete,"",(cAliasQry)->RA_MAT )})
	oSectDet:Cell("RA_NOME"   ):SetBlock({||IIf(lRepete,"", If(!Empty((cAliasQry)->RA_NSOCIAL),(cAliasQry)->RA_NSOCIAL, (cAliasQry)->RA_NOME) ) })
	If nOrdem == 1 
		oSectDet:Cell("RA_KEYLOC"  ):Disable()
		oSectDet:Cell("RA_CODFUNC"):SetBlock({||IIf(lRepete,"",(cAliasQry)->RA_CODFUNC)}) // Código da Função
		oSectDet:Cell("RJ_DESC"   ):SetBlock({||IIf(lRepete,"",(cAliasQry)->RJ_DESC)}) // Descrição da Função
		oSectDet:Cell("RA_CC"     ):SetBlock({||IIf(lRepete,"",(cAliasQry)->RA_CC)}) // Centro de Custo
		oSectDet:Cell("DESC_CC"):SetBlock({||IIf(lRepete,"",(cAliasQry)->CTT_DESC01)}) // Descrição Centro de Custo
		oSectDet:Cell("RA_I_SETOR"):SetBlock({||IIf(lRepete,"",(cAliasQry)->RA_I_SETOR)}) // Código do Setor
		oSectDet:Cell("ZAK_DESCRI"):SetBlock({||IIf(lRepete,"",(cAliasQry)->ZAK_DESCRI)}) // Descrição do Setor
		oSectDet:Cell("TURNO"):SetBlock({|| U_RGPE020T("CTURNO", (cAliasQry)->RA_FILIAL , (cAliasQry)->RA_MAT)} ) // Código do Turno
		oSectDet:Cell("DESCTURNO"):SetBlock({|| U_RGPE020T("TURNO", (cAliasQry)->RA_FILIAL , (cAliasQry)->RA_MAT)} ) // Descrição do Turno 
	Else
		oSectDet:Cell("RA_CC"     ):Disable()
	EndIf
	cTitulo	+= " - " + OemToAnsi(STR0026)	//Analáitico
EndIf
	
If lImpLiq
	DEFINE CELL NAME "TOTLIQ" OF oSectDet TITLE OemToAnsi(STR0010) PICTURE "@E 99,999,999,999.99" SIZE 20 BLOCK {||nTotLiq} 	//Total Líquido
	oSectDet:Cell("TOTLIQ"):SetHeaderAlign("RIGHT")
	oSectDet:Cell("TOTLIQ"):SetAutoSize()		
	If lImpEmpr	
		DEFINE FUNCTION NAME ("TTOTLIQ") FROM oSectDet:Cell("TOTLIQ") FUNCTION SUM PICTURE "@E 99,999,999,999.99" NO END Section
	EndIf
	If nSinAna == 1	//Analitico
		If nOrdem == 3 .Or. nOrdem == 4 .Or. nOrdem == 7 .Or. nOrdem == 8	//C.Custo ou C.Custo + Depto
			DEFINE FUNCTION NAME ("CTOTLIQ") FROM oSectDet:Cell("TOTLIQ") FUNCTION SUM BREAK oBreakCC NO END Section NO END REPORT PICTURE "@E 99,999,999,999.99"  
		EndIf
		If nOrdem == 5 .Or. nOrdem == 6 .Or. nOrdem == 7 .Or. nOrdem == 8	//Depto ou C.Custo + Depto
			DEFINE FUNCTION NAME ("DTOTLIQ") FROM oSectDet:Cell("TOTLIQ") FUNCTION SUM BREAK oBreakDp NO END Section NO END REPORT PICTURE "@E 99,999,999,999.99"  
		EndIf
		If nOrdem == 9 .Or. nOrdem == 10 	//Localidade Pago
			DEFINE FUNCTION NAME ("LTOTLIQ") FROM oSectDet:Cell("TOTLIQ") FUNCTION SUM BREAK oBreakLp NO END Section NO END REPORT PICTURE "@E 99,999,999,999.99"  
		EndIf
		If nOrdem == 11 .Or. nOrdem == 12 	//Registro Patronal
			DEFINE FUNCTION NAME ("RTOTLIQ") FROM oSectDet:Cell("TOTLIQ") FUNCTION SUM BREAK oBreakRpt NO END Section NO END REPORT PICTURE "@E 99,999,999,999.99"  
		EndIf
	EndIf
	DEFINE FUNCTION NAME ("FTOTLIQ") FROM oSectDet:Cell("TOTLIQ") FUNCTION SUM BREAK oBreakFil NO END Section NO END REPORT PICTURE "@E 99,999,999,999.99"
	
	If lCorpManage
		If lUniNeg
			DEFINE FUNCTION NAME ("FUNTOTLIQ") FROM oSectDet:Cell("TOTLIQ") FUNCTION SUM BREAK oBreakUnN NO END Section NO END REPORT PICTURE "@E 99,999,999,999.99"
		EndIf
		If lEmpFil
			DEFINE FUNCTION NAME ("FEFTOTLIQ") FROM oSectDet:Cell("TOTLIQ") FUNCTION SUM BREAK oBreakEFil NO END Section NO END REPORT PICTURE "@E 99,999,999,999.99"
		EndIf
	EndIf  
EndIf

DBSelectArea("SRA")
DBSetOrder(1)

SRA->( DBGoTop() )

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Esta função busca todos os periodos em aberto e fechado dos funcionarios.³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
RetPerAbertFech(cProcesso,cRot,cPeriodo,cPagamento,,,@aPerAberto,@aPerFechado, , Space(FwGetTamFilial), Replicate("z", FwGetTamFilial))
	
If Empty(aPerAberto) .And. Empty(aPerFechado)
	MsgAlert(OemToAnsi(STR0022),OemToAnsi(STR0023))	//"Não foi encontrado nenhum período" ### "Falta parâametro"
	FWRestArea(aAreaRep)
	Return
EndIf
	
cAls 		:= "SRC"
cPref		:= "RC_"
	
MakeSqlExpr(cPerg)    

If nOrdem == 1
	cOrdem := "%TRB.RA_FILIAL,TRB.RA_MAT"
	cTitulo += IIf(nSinAna == 1, " - " + OemToAnsi(STR0004), "")	//" + Matrícula" //" - " + OemToAnsi(STR0004)	//Matrícula
ElseIf nOrdem == 2
	cOrdem := "%TRB.RA_FILIAL,TRB.RA_NOME,TRB.RA_MAT"
	cTitulo += IIf(nSinAna == 1, " - " + OemToAnsi(STR0006), "")	//" + Nome" //" - " + OemToAnsi(STR0006)	//Nome
ElseIf nOrdem == 3
	cOrdem := "%TRB.RA_FILIAL,TRB.RA_CC,TRB.RA_MAT"
	cTitulo += " - " + OemToAnsi(STR0007) 	//"Centro de Custo"
	cTitulo += IIf(nSinAna == 1, " + " + OemToAnsi(STR0004), "")	//" + Matrícula"
ElseIf nOrdem == 4                    
	cOrdem := "%TRB.RA_FILIAL,TRB.RA_CC,TRB.RA_NOME,TRB.RA_MAT"
	cTitulo += " - " + OemToAnsi(STR0007)	//"Centro de Custo"
	cTitulo += IIf(nSinAna == 1, " + " + OemToAnsi(STR0006), "")	//" + Nome"
ElseIf nOrdem == 5
	cOrdem := "%TRB.RA_FILIAL,TRB.RA_DEPTO,TRB.RA_MAT" 
	cTitulo += " - " + OemToAnsi(STR0009)	//"Departamento"
	cTitulo += IIf(nSinAna == 1, " + " + OemToAnsi(STR0004), "")	//" + Matrícula"
ElseIf nOrdem == 6
	cOrdem := "%TRB.RA_FILIAL,TRB.RA_DEPTO,TRB.RA_NOME,TRB.RA_MAT"
	cTitulo += " - " + OemToAnsi(STR0009) 	//"Departamento"
	cTitulo += IIf(nSinAna == 1, " + " + OemToAnsi(STR0006), "")	//" + Nome"
ElseIf nOrdem == 7
	cOrdem := "%TRB.RA_FILIAL,TRB.RA_CC,TRB.RA_DEPTO,TRB.RA_MAT"
	cTitulo += " - " + OemToAnsi(STR0005) + " + " + OemToAnsi(STR0008)	//"C.Custo" ## "Depto."
	cTitulo += IIf(nSinAna == 1, " + " + OemToAnsi(STR0004), "")	//" + Matrícula"
ElseIf nOrdem == 8                    
	cOrdem := "%TRB.RA_FILIAL,TRB.RA_CC,TRB.RA_DEPTO,TRB.RA_NOME,TRB.RA_MAT"
	cTitulo += " - " + OemToAnsi(STR0005) + " + " + OemToAnsi(STR0008)	//"C.Custo" ## "Depto."
	cTitulo += IIf(nSinAna == 1, " + " + OemToAnsi(STR0006), "")	//" + Nome"
ElseIf nOrdem == 9
	cOrdem := "%TRB.RA_FILIAL,TRB.RA_KEYLOC,TRB.RA_MAT"
	cTitulo += " - " + OemToAnsi(IIf(cPaisLoc $ "COL", STR0045, STR0028)) 	//"Loc.Pago" - Para COL se utiliza "Centro Trab."
	cTitulo += IIf(nSinAna == 1, " + " + OemToAnsi(STR0004), "")	//" + Matrícula"
ElseIf nOrdem == 10                    
	cOrdem := "%TRB.RA_FILIAL,TRB.RA_KEYLOC,TRB.RA_NOME,TRB.RA_MAT"
	cTitulo += " - " + OemToAnsi(IIf(cPaisLoc $ "COL", STR0045, STR0028))	//"Loc.Pago" - Para COL se utiliza "Centro Trab."
	cTitulo += IIf(nSinAna == 1, " + " + OemToAnsi(STR0006), "")	//" + Nome"
ElseIf nOrdem == 11
	cOrdem := "%TRB.RA_FILIAL,TRB.RA_CODRPAT,TRB.RA_MAT" 
	cTitulo += " - " + OemToAnsi(STR0031)	//"Reg.Patronal"
	cTitulo += IIf(nSinAna == 1, " + " + OemToAnsi(STR0004), "")	//" + Matrícula"
ElseIf nOrdem == 12
	cOrdem := "%TRB.RA_FILIAL,TRB.RA_CODRPAT,TRB.RA_NOME,TRB.RA_MAT"
	cTitulo += " - " + OemToAnsi(STR0031) 	//"Reg.Patronal"
	cTitulo += IIf(nSinAna == 1, " + " + OemToAnsi(STR0006), "")	//" + Nome"
EndIf                        
cOrdem		:= cOrdem + ",TRB.SEQ%"
		
cAliasQry	:= GetNextAlias()

//-- Filial
If !Empty(MV_PAR01)
	cFiltro += MV_PAR01
EndIf

//Filtra filiais de acesso do usuario
If Len(aValidFil) > Len(aValidFil2)
	cValidFil := " SRA.RA_FILIAL IN ('' "
Else
	cValidFil := " SRA.RA_FILIAL NOT IN ('' "
EndIf

If Len(aValidFil) > Len(aValidFil2)
	aValidFil := aValidFil2
EndIf

For nX := 1 to Len(aValidFil)
	cValidFil += ", '" + aValidFil[nX] + "' "
Next nX
cValidFil += ") "

//-- Centro de Custo
If !Empty(MV_PAR02)
	cFiltro += IIf(!Empty(cFiltro)," AND ","")
	cFiltro += MV_PAR02
EndIf

//-- Departamento
If !Empty(MV_PAR03)
	cFiltro += IIf(!Empty(cFiltro)," AND ","")
	cFiltro += MV_PAR03
EndIf

//=== Matricula   
If !Empty(MV_PAR04)
	cFiltro += IIf(!Empty(cFiltro)," AND ","")
	cFiltro	+= MV_PAR04
EndIf

//=== Nome   
If !Empty(MV_PAR05)
	cFiltro += IIf(!Empty(cFiltro)," AND ","")
	cFiltro += MV_PAR05
EndIf

//== Filtro de usuário
If !Empty(oSectDet:GetSqlExp())
   cFiltro += IIf(!Empty(cFiltro)," AND ","")
   cFiltro += oSectDet:GetSqlExp()
EndIf


If SRA->(FIELDPOS("RA_KEYLOC")) > 0 .And. ( nOrdem <> 9 .And. nOrdem <> 10 )
	cVerQry	+= "SRA.RA_KEYLOC, "
EndIf

If SRA->(FIELDPOS("RA_CODRPAT")) > 0 .And. ( nOrdem <> 11 .And. nOrdem <> 12 ) .And. !(cPaisLoc $ "PER|COL")
	cVerQry	+= "SRA.RA_CODRPAT, "
EndIf

cVerQry	+= cAls + "." + cPref + "SEMANA SEMANA, "
cVerQry	+= cAls + "." + cPref + "PROCES PROCES, "
cVerQry	+= cAls + "." + cPref + "PERIODO PERIODO, "
cVerQry	+= cAls + "." + cPref + "ROTEIR ROTEIR, " 

cVerQry	+= cAls + "." + cPref + "SEQ SEQ " 
  
cVerQry	+= "FROM " 
cVerQry	+= RetSqlName("SRA")  + " SRA "
cVerQry	+= "INNER JOIN  " 
cVerQry	+= RetSqlName(cAls)   + " " + cAls + " ON "
cVerQry	+= "SRA.RA_FILIAL = " + cAls + "." + cPref + "FILIAL AND "
cVerQry	+= "SRA.RA_MAT = " + cAls + "." + cPref + "MAT "

cVerQry	+= "LEFT JOIN  "
cVerQry	+= RetSqlName("SRJ")   + " " + "RJ" + " ON "
cVerQry	+= "RJ.RJ_FILIAL = '" + xFilial("SRJ") + "' "
cVerQry	+= "AND SRA.RA_CODFUNC = RJ.RJ_FUNCAO "
cVerQry	+= "AND RJ.D_E_L_E_T_ = ' ' "

cVerQry	+= "LEFT JOIN  "
cVerQry	+= RetSqlName("CTT")   + " " + "CTT" + " ON "
cVerQry	+= "CTT.CTT_FILIAL = '" + xFilial("CCT") + "'"
cVerQry	+= "AND SRA.RA_CC = CTT.CTT_CUSTO "
cVerQry	+= "AND CTT.D_E_L_E_T_ = ' ' "

cVerQry	+= "LEFT JOIN  "
cVerQry	+= RetSqlName("ZAK")   + " " + "ZAK" + " ON "
cVerQry	+= "ZAK.ZAK_FILIAL = '" + xFilial("ZAK") + "'"
cVerQry	+= "AND SRA.RA_I_SETOR = ZAK.ZAK_COD "
cVerQry	+= "AND ZAK.D_E_L_E_T_ = ' ' "

If nOrdem >= 5 .And. nOrdem <= 8
	For nCont := 1 to 3
		aPosics[nCont] := Len(FWSM0Layout(,nCont)) //Pega quantidade de caracteres usados para empresa, unid. negocio, filial
	Next
	
	cVerQry += "LEFT JOIN " + RetSqlName("SQB") + " SQB"
	cVerQry += " ON SRA.RA_DEPTO=SQB.QB_DEPTO " +  fGetJOINGestEmp(aPosics, 'SQB', 'QB_FILIAL', 'SRA', 'RA_FILIAL')
EndIf
	
If nOrdem == 9 .Or. nOrdem == 10
	cVerQry	+= "INNER JOIN  " + RetSqlName("RGC") + " RGC" 
	cVerQry	+= " ON SRA.RA_KEYLOC=RGC.RGC_KEYLOC "   	
EndIf

cVerQry	+= "WHERE " 
cVerQry	+= IIf(Empty(cFiltro),"",cFiltro + " AND ")
cVerQry	+= cValidFil + " AND "
cVerQry	+= cAls + "." + cPref + "PROCES  = Upper('" + cProcesso  + "') AND "
cVerQry	+= cAls + "." + cPref + "PERIODO = Upper('" + cPeriodo   + "') AND " 
cVerQry	+= cAls + "." + cPref + "ROTEIR  = Upper('" + cRot   + "') AND "
cVerQry	+= cAls + "." + cPref + "SEMANA  = Upper('" + cPagamento + "') AND " 
If cAls == "SRD"
	cVerQry	+= cAls + "." + cPref + "EMPRESA = ' ' AND "
EndIf
cVerQry	+= "SRA.D_E_L_E_T_= ' ' AND " + cAls + ".D_E_L_E_T_= ' '  "
cVerQry	+= " AND SRA.RA_SITFOLH IN (" + fSqlIN(cSituacao,1 ) + ")"
cVerQry += " AND SRA.RA_CATFUNC IN (" + fSqlIN(cCategoria,1) + ")" 

cVerQry0	:= "SELECT DISTINCT SRA.RA_FILIAL, SRA.RA_MAT, SRA.RA_CC, SRA.RA_NOME, SRA.RA_NSOCIAL, SRA.RA_DEPTO, SRA.RA_CODFUNC, RJ.RJ_DESC, CTT.CTT_DESC01, SRA.RA_I_SETOR, ZAK.ZAK_DESCRI,  "

If nOrdem >= 5 .And. nOrdem <= 8  
	cVerQry0	+= "SQB.QB_DESCRIC, SQB.QB_DEPTO, "
EndIf

If nOrdem == 9 .Or. nOrdem == 10  
	cVerQry0	+= "SRA.RA_KEYLOC, RGC.RGC_DESLOC, "
EndIf

If nOrdem == 11 .Or. nOrdem == 12
	cVerQry0	+= "SRA.RA_CODRPAT, "
EndIf

cVerQry0	+= "SRA.RA_SITFOLH, " + cAls + "." + cPref + "FILIAL FILIAL, " + cAls + "." + cPref 
cVerQry0	+= "MAT MAT, " + cAls + "." + cPref + "CC CCUSTO, "
If lItemCLVL
	 cVerQry0	+= cAls + "." + cPref + "ITEM, " + cAls + "." + cPref + "CLVL, "
EndIf	 

aVerQry	:= Array(Len(aQryVerba))
For nReg	:= 1 to Len(aVerQry)
	aVerQry[nReg] := cVerQry0	
Next

For nReg	:= 1 to Len(aQryVerba)

	cSum	+= IIf(Empty(cSum),"",", ")
	cSum	+= " SUM(V" + aQryVerba[nReg] + ") V" + aQryVerba[nReg] //+ "' "
	    
	For nCont	:= 1 to Len(aVerQry)
		If nReg == nCont
			If nVerHor == 1
				aVerQry[nReg]	+= cAls + "." + cPref + "VALOR V" + aQryVerba[nReg] + ", "
			Else
				aVerQry[nReg]	+= cAls + "." + cPref + "HORAS V" + aQryVerba[nReg] + ", "
			EndIf
		Else
			aVerQry[nCont]	+= "0 V" + aQryVerba[nReg] + ", "
		EndIf
	Next
Next
    
cUnion	:= IIf(!Empty(aVerQry[1]), " (" + aVerQry[1] + cVerQry + " AND " + cAls + "." + cPref + ;
			"PD = '" + aQryVerba[1]  + "' ", "")

For nCont	:= 2 to Len(aVerQry)
	cUnion	+= IIf(!Empty(aVerQry[nCont]), " UNION ALL " + aVerQry[nCont] + cVerQry + " AND " + cAls + ;
			"." + cPref + "PD = '" + aQryVerba[nCont] + "' ", "")
Next

cUnionSRD	:= StrTran(cUnion, "SRC", "SRD")
cUnionSRD	:= StrTran(cUnionSRD, "RC_", "RD_")
cUnionSRD   := SubStr(cUnionSRD, 3)
cUnion		+= "UNION "
cUnion		+= cUnionSRD
cUnion		+= ") TRB "
cUnion		:= "%" + cUnion		
cUnion		+= IIf(Empty(cOrgJoin),"%",cOrgJoin+"%")
cSum		:= "%" + cSum 		+ "%"
               
cCpoDelim	:= "%RA_FILIAL "
cCpoDelim	+= IIf(!Empty(cCpoQuebra),","+AllTrim(cCpoQuebra),"")
cCpoDelim	+= IIf(!Empty(cCpoQuebr2),","+AllTrim(cCpoQuebr2),"")
cCpoDelim	+= "%"

If (SRA->(FieldPos('RA_KEYLOC')) > 0) .And. ( nOrdem <> 9 .And. nOrdem <> 10 )
	cSraCpoAdd += ", TRB.RA_KEYLOC"
EndIf
If (SRA->(FieldPos('RA_CODRPAT')) > 0) .And. ( nOrdem <> 11 .And. nOrdem <> 12 ) .And. !(cPaisLoc $ "PER|COL")
	cSraCpoAdd += ", TRB.RA_CODRPAT"
EndIf	

cSraCpoAdd := "%" + cSraCpoAdd + "%"

SRA->( DBCloseArea() ) //Fecha o SRA para uso da Query
SRC->( DBCloseArea() ) //Fecha o SRC para uso da Query
SRD->( DBCloseArea() ) //Fecha o SRD para uso da Query

//-- Altera o titulo do relatorio
oReport:SetTitle(cTitulo)

If nSinAna == 1	//Analitico
	If nOrdem == 1 .Or. nOrdem == 2
		BEGIN REPORT QUERY oSectDet
	Else
		BEGIN REPORT QUERY oSectHead
	EndIf
	
	Do Case
	
		Case nOrdem >= 5 .And. nOrdem <= 8

			BeginSql alias cAliasQry
				SELECT 	TRB.RA_FILIAL,  TRB.RA_MAT,     TRB.RA_CC,   TRB.RA_NOME, TRB.RA_NSOCIAL, TRB.RA_DEPTO,
						TRB.QB_DESCRIC, TRB.RA_SITFOLH, TRB.FILIAL,  TRB.MAT,     TRB.CCUSTO,      
						%exp:cSum%, TRB.SEMANA,     TRB.PROCES,     TRB.PERIODO, TRB.ROTEIR, TRB.SEQ, TRB.QB_DEPTO %exp:cSraCpoAdd%
				FROM  	%exp:cUnion% 
				GROUP BY TRB.RA_FILIAL, TRB.RA_MAT,     TRB.RA_CC,  TRB.RA_NOME, TRB.RA_NSOCIAL, TRB.RA_DEPTO,
						TRB.QB_DESCRIC, TRB.RA_SITFOLH, TRB.FILIAL, TRB.MAT,     TRB.CCUSTO,   TRB.SEMANA,   
						TRB.PROCES,     TRB.PERIODO,    TRB.ROTEIR, TRB.SEQ, TRB.QB_DEPTO %exp:cSraCpoAdd%                  
				ORDER BY %exp:cOrdem%
			EndSql
		
		Case nOrdem == 9 .Or. nOrdem == 10 //Localidade Pagamento

			BeginSql alias cAliasQry
				SELECT 	TRB.RA_FILIAL,  TRB.RA_MAT,     TRB.RA_CC,   TRB.RA_NOME, TRB.RA_NSOCIAL, TRB.RA_DEPTO, TRB.RA_KEYLOC,
						TRB.RGC_DESLOC, TRB.RA_SITFOLH, TRB.FILIAL,  TRB.MAT,     TRB.CCUSTO,      %exp:cSum%,
						TRB.SEMANA,     TRB.PROCES,     TRB.PERIODO, TRB.SEQ, TRB.ROTEIR  %exp:cSraCpoAdd%
				FROM  	%exp:cUnion% 
				GROUP BY TRB.RA_FILIAL, TRB.RA_MAT,     TRB.RA_CC,  TRB.RA_NOME, TRB.RA_NSOCIAL, TRB.RA_DEPTO, TRB.RA_KEYLOC,
						TRB.RGC_DESLOC, TRB.RA_SITFOLH, TRB.FILIAL, TRB.MAT,     TRB.CCUSTO,   TRB.SEMANA,   
						TRB.PROCES,     TRB.PERIODO,   TRB.SEQ, TRB.ROTEIR  %exp:cSraCpoAdd%
				ORDER BY %exp:cOrdem%
			EndSql
			
		Case nOrdem == 11 .Or. nOrdem == 12 //Registro Patronal

			BeginSql alias cAliasQry
				SELECT 	TRB.RA_FILIAL,  TRB.RA_MAT,     TRB.RA_CC,   TRB.RA_NOME, TRB.RA_NSOCIAL, TRB.RA_DEPTO,
						TRB.RA_SITFOLH, TRB.RA_CODRPAT, TRB.FILIAL,  TRB.MAT,     TRB.CCUSTO,   %exp:cSum%,
						TRB.SEMANA,     TRB.PROCES,     TRB.PERIODO, TRB.SEQ, TRB.ROTEIR %exp:cSraCpoAdd%
				FROM  	%exp:cUnion% 
				GROUP BY TRB.RA_FILIAL, TRB.RA_MAT,     TRB.RA_CC,  TRB.RA_NOME, TRB.RA_NSOCIAL, TRB.RA_DEPTO,
						TRB.RA_SITFOLH, TRB.RA_CODRPAT, TRB.FILIAL, TRB.MAT,     TRB.CCUSTO,   TRB.SEMANA,   
						TRB.PROCES,     TRB.PERIODO,    TRB.SEQ, TRB.ROTEIR  %exp:cSraCpoAdd%
				ORDER BY %exp:cOrdem%
			EndSql
		
		OtherWise

			BeginSql alias cAliasQry
				SELECT 	TRB.RA_FILIAL,  TRB.RA_MAT,     TRB.RA_CC,   TRB.RA_NOME, TRB.RA_NSOCIAL, TRB.RA_DEPTO, TRB.RA_CODFUNC, TRB.RJ_DESC, TRB.CTT_DESC01, TRB.RA_I_SETOR, TRB.ZAK_DESCRI, 
						TRB.RA_SITFOLH, TRB.FILIAL,  TRB.MAT,     TRB.CCUSTO,      
						%exp:cSum%, TRB.SEMANA,     TRB.PROCES,     TRB.PERIODO, TRB.SEQ, TRB.ROTEIR %exp:cSraCpoAdd%
				FROM  	%exp:cUnion% 
				GROUP BY TRB.RA_FILIAL, TRB.RA_MAT,     TRB.RA_CC,  TRB.RA_NOME, TRB.RA_NSOCIAL, TRB.RA_DEPTO, TRB.RA_CODFUNC,TRB.RJ_DESC, TRB.CTT_DESC01, TRB.RA_I_SETOR, TRB.ZAK_DESCRI,
						TRB.RA_SITFOLH, TRB.FILIAL, TRB.MAT,     TRB.CCUSTO,   TRB.SEMANA,   
						TRB.PROCES,     TRB.PERIODO,    TRB.SEQ, TRB.ROTEIR %exp:cSraCpoAdd%
				ORDER BY %exp:cOrdem%
			EndSql
									
	EndCase

	If nOrdem == 1 .Or. nOrdem == 2
		END REPORT QUERY oSectDet
	ElseIf nOrdem == 3 .Or. nOrdem == 4
		END REPORT QUERY oSectHead
		oSectDet:SetParentQuery()
		oSectDet:SetParentFilter({|cParam|(cAliasQry)->RA_FILIAL+(cAliasQry)->CCUSTO==cParam},{||(cAliasQry)->RA_FILIAL+(cAliasQry)->CCUSTO})
	ElseIf nOrdem == 5 .Or. nOrdem == 6
		END REPORT QUERY oSectHead
		oSectDet:SetParentQuery()
		oSectDet:SetParentFilter({|cParam|(cAliasQry)->RA_FILIAL+(cAliasQry)->RA_DEPTO==cParam},{||(cAliasQry)->RA_FILIAL+(cAliasQry)->RA_DEPTO})
	ElseIf nOrdem == 7 .Or. nOrdem == 8
		END REPORT QUERY oSectHead
		oSectSubHd:SetParentQuery()
		oSectSubHd:SetParentFilter({|cParam|(cAliasQry)->RA_FILIAL+(cAliasQry)->CCUSTO==cParam},{||(cAliasQry)->RA_FILIAL+(cAliasQry)->CCUSTO})
		oSectDet:SetParentQuery()   
		oSectDet:SetParentFilter({|cParam|(cAliasQry)->RA_FILIAL+(cAliasQry)->CCUSTO+(cAliasQry)->RA_DEPTO==cParam},{||(cAliasQry)->RA_FILIAL+(cAliasQry)->CCUSTO+(cAliasQry)->RA_DEPTO})
	ElseIf nOrdem == 9 .Or. nOrdem == 10
		END REPORT QUERY oSectHead
		oSectDet:SetParentQuery()
		oSectDet:SetParentFilter({|cParam|(cAliasQry)->RA_FILIAL+(cAliasQry)->RA_KEYLOC==cParam},{||(cAliasQry)->RA_FILIAL+(cAliasQry)->RA_KEYLOC})
	ElseIf nOrdem == 11 .Or. nOrdem == 12
		END REPORT QUERY oSectHead
		oSectDet:SetParentQuery()
		oSectDet:SetParentFilter({|cParam|(cAliasQry)->RA_FILIAL+(cAliasQry)->RA_CODRPAT==cParam},{||(cAliasQry)->RA_FILIAL+(cAliasQry)->RA_CODRPAT})
	EndIf

Else	//Sintético

	If nOrdem == 7 .Or. nOrdem == 8
	
		BEGIN REPORT QUERY oSectHead
		BeginSql alias cAliasQry

			SELECT 	TRB.FILIAL, %exp:cSum%, TRB.SEMANA, TRB.PROCES, TRB.PERIODO, TRB.ROTEIR,     
					TRB.%exp:cCpoDelim%
			FROM  	%exp:cUnion% 
			GROUP BY TRB.SEMANA, TRB.PROCES, TRB.PERIODO, TRB.ROTEIR, %exp:cCpoDelim%, TRB.FILIAL         
			ORDER BY %exp:cCpoDelim%
	
		EndSql   
		END REPORT QUERY oSectHead
		oSectDet:SetParentQuery()   
		oSectDet:SetParentFilter({|cParam|(cAliasQry)->FILIAL+(cAliasQry)->CCUSTO==cParam},{||(cAliasQry)->RA_FILIAL+(cAliasQry)->CCUSTO})

	Else

		BEGIN REPORT QUERY oSectDet
		BeginSql alias cAliasQry

			SELECT 	TRB.FILIAL, %exp:cSum%, TRB.SEMANA, TRB.PROCES, TRB.PERIODO, TRB.ROTEIR,     
					TRB.%exp:cCpoDelim%
			FROM  	%exp:cUnion% 
			GROUP BY TRB.SEMANA, TRB.PROCES, TRB.PERIODO, TRB.ROTEIR, %exp:cCpoDelim%, TRB.FILIAL         
			ORDER BY TRB.%exp:cCpoDelim%
	
		EndSql   

		END REPORT QUERY oSectDet
		
	EndIf

EndIf

oReport:OnPageBreak({||fGR103Header(oReport)})	

//-- Verifica se o usuário cancelou a impressão do relatorio
If oReport:Cancel()
	Return
EndIf               

DBSelectArea( cAliasQry )

For nCont:= 1 to Len(AllTrim(cCodigos)) Step 3
	oSectDet:Cell(SubStr(cCodigos,nCont,3)):SetTitle(SubStr(cCodigos,nCont,3)+"-"+DescPd(SubStr(cCodigos,nCont,3),(cAliasQry)->RA_FILIAL,8))	//Cod.+Descricao
Next

If nSinAna == 1	//Analitico
	If nOrdem == 3 .Or. nOrdem == 4	//Centro de Custo 
		oSectHead:SetLineCondition({||!Empty((cAliasQry)->CCUSTO)})
	EndIf
EndIf
oSectDet:SetLineCondition({||fAcumValores(@oSectDet,cCodigos)})

//-- Define o total da regua da tela de processamento do relatorio
cCountQ := " SELECT COUNT(*) NRECS FROM ( "+ SubStr(GetLastQuery()[2],1,At("ORDER BY",GetLastQuery()[2])-1) + ") Y"
dbUseArea(.T., 'TOPCONN', TcGenQry(,,cCountQ), 'QTREGIS', .F., .F. ) 
oReport:SetMeter(QTREGIS->NRECS)  
QTREGIS->( DBCloseArea() ) 

If nOrdem == 1 .Or. nOrdem == 2
    oSectDet:Print()
ElseIf nOrdem == 7 .Or. nOrdem == 8
	If nSinAna == 1	//Analitico
		oSectHead:Print()
	Else			//Sintetico
		oSectSubHd:Print()
	EndIf
Else
	If nSinAna == 1	//Analitico
		oSectHead:Print()
	Else			//Sintetico
		oSectDet:Print()
	EndIf
EndIf

FWRestArea(aAreaRep)
	        
Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³fAcumValores() ³ Autor ³ Tania Bronzeri   ³ Data ³27/09/2007³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³Acumula os valores das Verbas selecionadas.                 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ Folha Mexico                                               ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Static Function fAcumValores(oSection1,cCodigos)

	Local aArea 	:= FWGetArea()
	Local cPd		:= ""
	Local cTpCod	:= ""	//Sinal - Retorna 1,2,3 ou 4
	Local cTpval	:= ""	//Status - Retorna H,D ou V
	Local nCont		:= 0	    
	Local nValor	:= 0
	Local lRet		:= .T.
	
	nTotLiq			:= 0
	           
	For nCont	:= 1 to Len(AllTrim(cCodigos)) Step 3
		cPd		:= SubStr(cCodigos,nCont,3)		
		
		cTpCod	:= PosSrv(cPd,(cAliasQry)->RA_FILIAL,"RV_TIPOCOD")	//Retorna 1,2,3 ou 4
		cTpval	:= PosSrv(cPd,(cAliasQry)->FILIAL   ,"RV_TIPO")	//Retorna H,D ou V
		
		If cDigHoras == "N" .And. cTpval == "H" .And. nVerHor == 2
			nValor := fConvHr( (cAliasQry)->&("V"+cPd) , "D" )
			oSection1:Cell(cPd):SetValue(nValor)
		Else 
			oSection1:Cell(cPd):SetValue((cAliasQry)->&("V"+cPd))
		EndIf
		
		If cTpCod == "1"
			If cDigHoras == "N" .And. cTpval == "H" .And. nVerHor == 2
				nTotLiq	+= nValor
			Else
				nTotLiq	+= (cAliasQry)->&("V"+cPd)
			EndIf
		ElseIf cTpCod == "2"
			If cDigHoras == "N" .And. cTpval == "H" .And. nVerHor == 2
				nTotLiq	-= nValor				
			Else			
				nTotLiq -= (cAliasQry)->&("V"+cPd)
			EndIf
		EndIf
	Next
	
	If nSinAna == 1
		If cRepete == ((cAliasQry)->RA_FILIAL + (cAliasQry)->RA_MAT)
			lRepete	:= .T.
		Else
			lRepete := .F.
			cRepete := ((cAliasQry)->RA_FILIAL + (cAliasQry)->RA_MAT)
		EndIf                 
	EndIf
	                                   
	If nSinAna == 2	//Sintetico
		If nOrdem == 3 .Or. nOrdem == 4
			oSection1:Cell("RA_CC"):SetValue((cAliasQry)->CCUSTO)
			oSectHead:Disable() 
	
		ElseIf nOrdem == 5 .Or. nOrdem == 6
			oSection1:Cell("RA_DEPTO"):SetValue((cAliasQry)->RA_DEPTO)
			oSectHead:Disable() 
			oSection1:SetHeaderSection(.F.)
	
		ElseIf nOrdem == 7 .Or. nOrdem == 8
			oSection1:Cell("RA_CC"):SetValue((cAliasQry)->CCUSTO)
			oSectHead:Disable() 
	
		ElseIf nOrdem == 9 .Or. nOrdem == 10
			oSection1:Cell("RA_KEYLOC"):SetValue((cAliasQry)->RA_KEYLOC)
			oSectHead:Disable() 
			oSection1:SetHeaderSection(.F.)
	
		ElseIf nOrdem == 11 .Or. nOrdem == 12
			oSection1:Cell("RA_CODRPAT"):SetValue((cAliasQry)->RA_CODRPAT)
			oSectHead:Disable() 
			oSection1:SetHeaderSection(.F.)
		EndIf
	
	EndIf
	
	FWRestArea(aArea)

Return lRet

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³ fQueryVisao   ³ Autor ³ Tania Bronzeri        ³ Data ³19/03/2008³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Pesquisa Visao / Departamento para a Arquitetura Organizacional.³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ GPER103                                                         ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Static Function fQueryVisao() 

Local aArea		:= FWGetArea()
Local aChave	:= array(2)
Local cQuery 	:= ""
Local cQryAlias	:= GetNextAlias()

DBSelectArea("RD4")
DBCloseArea()               
cQuery := "SELECT RD4.RD4_CHAVE, RD4.RD4_FILIDE FROM " + RetSqlName("RD4") + " RD4 "
cQuery += "INNER JOIN " + RetSqlName("RDK") + " RDK "
cQuery += "ON RD4_CODIGO = RDK_CODIGO AND RD4_FILIAL = RDK_FILIAL "
cQuery += "WHERE RD4_CODIDE = '" + cCodDepto + "' AND RDK_HIERAR = '1' AND RDK_CODIGO = '" + cCodVisao + "' "
cQuery += "AND RD4.D_E_L_E_T_ = ' ' AND RDK.D_E_L_E_T_ = ' ' "
cQuery := ChangeQuery(cQuery)

dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cQryAlias,.T.,.T.)

aChave[1]	:= (cQryAlias)->RD4_FILIDE
aChave[2]	:= (cQryAlias)->RD4_CHAVE

(cQryAlias)->(DBCloseArea())

FWRestArea( aArea )

Return aChave

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³ fGR103Header  ³ Autor ³ Tania Bronzeri        ³ Data ³19/03/2008³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Define el encabezado del Informe.                               ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ GPER103                                                         ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Static Function fGR103Header(oReport)
	Local cDescProc := ""

	cDescProc := EVAL({||SubStr(PosAlias("RCJ",cProcesso,xFilial("RCJ"),"RCJ_DESCRI"),1,20)}) 

	oReport:SkipLine()
	oReport:PrintText(OemToAnsi(STR0014) + ': ' + cProcesso + ' - ' + cDescProc + Space(05) + OemToAnsi(STR0015) + ': ' + cPeriodo;
		+ Space(05) + OemToAnsi(STR0016) + ': ' + cPagamento + Space(05) + OemToAnsi(STR0017) + ': ' + cRot, ;
		/*nRow*/,/*nCol*/,/*nClrText*/,/*cStyle*/,/*nCells*/,.F.) //"Processo"##"Período"##"Pagamento"##"Roteiro"
	oReport:ThinLine()
	oReport:SkipLine()
Return


/*
===============================================================================================================================
Função------------: RGPE020T
Autor-------------: Igor Melgaço
Data da Criacao---: 14/04/2021
Descrição---------: Retornar o código e a descrição do turno.
Parametros--------: _cCampo = Campo que chamou a função.
                    _cCodFilial = Codigo da Filial
						  _cMatricula = Codigo da Matricula
Retorno-----------: _cRet = Retorna o código ou a descrição do turno.
===============================================================================================================================
*/
User Function RGPE020T(_cCampo, _cCodFilial, _cMatricula)
Local _cRet := ""
Local _cQry 

Begin Sequence

   If _cCampo == "CTURNO"
      _cQry := " SELECT MAX(R_E_C_N_O_) NRRECNO FROM "+ RetSqlName("SPF") + " SPF " 
	  _cQry += " WHERE SPF.PF_FILIAL = '" + _cCodFilial + "' "
	  _cQry += " AND SPF.PF_MAT = '" + _cMatricula + "' "
	  _cQry += " AND SPF.PF_DATA <= '" + DToS(Date()) + "' "
	  _cQry += " AND SPF.D_E_L_E_T_ = ' ' "
     
      If Select("TRBSPF") > 0
	     TRBSPF->(DBCloseArea())
      EndIf
      
	  TCQUERY _cQry NEW ALIAS "TRBSPF"
   
      If TRBSPF->(Eof()) .Or. TRBSPF->(Bof()) .Or. TRBSPF->NRRECNO == 0
         _cCodTurno  := "SEM TURNO"
		 _cDescTurno := "NAO HA TURNO CADASTRADO PARA O PERIODO INFORMADO."
		 _cRet       := _cCodTurno

         Break
      EndIf
    
      SPF->(DBGoTo(TRBSPF->NRRECNO))
	  SR6->(DBSetOrder(1)) // R6_FILIAL+R6_TURNO 

	  _cCodTurno  := SPF->PF_TURNOPA
	  _cDescTurno := "SEM DESCRICAO PARA O TURNO"

	  If SR6->(DBSeek(SPF->PF_FILIAL+SPF->PF_TURNOPA))
	     _cDescTurno := SR6->R6_DESC
	  EndIf
      _cRet := _cCodTurno
   Else
      _cRet := _cDescTurno
   EndIf

End Sequence

Return _cRet

/*
===============================================================================================================================
Função------------: Gpe020Per
Autor-------------: Igor Melgaço
Data da Criacao---: 14/04/2021
Descrição---------: Retornar se o Periodo digitado no parametro existe na RCH
Parametros--------: cParam = Periodo 
Retorno-----------: _lRet = Retorna se encontrou o periodo
===============================================================================================================================
*/ 
User Function Gpe020Per(cParam)
    Local aArea := FWGetArea()
    Local lPerValido
    Local cFil := FWxFilial("RCH", RCH->RCH_FILIAL)
    Local lRet := .T.

    DBSelectArea("RCH")
    DBSetOrder(RetOrder ("RCH", "RCH_FILIAL+RCH_PROCES+RCH_ROTEIR+RCH_PER"))
    lPerValido := DBSeek(cFil+MV_PAR09+MV_PAR10+cParam)

    If !lPerValido
        MsgAlert(OemToAnsi("Periodo nao encontrado! Confira tambem o roteiro."), OemToAnsi("Atencao")) //"Periodo nao encontrado! Confira tambem o roteiro."###"Atencao"
        lRet := .F.
    EndIf

    FWRestArea(aArea) 

Return lRet
