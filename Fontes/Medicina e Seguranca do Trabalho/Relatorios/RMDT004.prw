/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz     |10/04/2018| Chamado 23960. Alterar a rotina de manutenção de EPIs para imprimir corretamente o numero da SA
Josué Danich  |11/06/2019| Chamado 29593. Revisão para loboguara
Lucas Borges  |02/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25.
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "TOPCONN.ch"

#DEFINE _nVERSAO 02 //Versao do fonte

/*
===============================================================================================================================
Programa----------: RMDT004
Autor-------------: TOTVS
Data da Criacao---: 20/09/2000
Descrição---------: Recibo de entrega do epi.  
Parametros--------: aDados - Array com os dados da entrega.
                    aRegs
                    aRegsTNF - Arry com os numeros dos Recnos dos registros da tabela TNF.
                    lDevEpi - Indica se é necessário a devolução.
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RMDT004( aDados, aRegs , aRegsTNF , lDevEpi , aDev )
//---------------------------------------------------------------
// Armazena variaveis p/ devolucao (NGRIGHTCLICK)						  
//---------------------------------------------------------------
Local aNGBEGINPRM := NGBEGINPRM(_nVERSAO)   
   
//---------------------------------------------------------------
// Define Variaveis                                             
//---------------------------------------------------------------
Local wnrel   := "RMDT004"
Local cDesc1  := "Relatorio de Comprovante de Entrega de EPI." // STR0001
Local cDesc2  := "Conforme parametros o usuario pode selecionar os funcionarios, periodo desejado" // STR0002 
Local cDesc3  := "e indicar se deseja imprimir apenas epi's nao impressos ou para todos."  // STR0003
Local cString := "TNF"
Local nFor
Default lDevEpi := .F.
Default aDev 	:= {} 

Private aOldACols := {}  
If ValType(aRegs) == "A"
	aOldACols := aClone(aRegs)
EndIf
 
Private aDad695
Private aRegs695
If ValType(aDados) == "A"
	aDad695 := aClone(aDados)
EndIf
If ValType(aRegsTNF) == "A"
	aRegs695 := aClone(aRegsTNF)
EndIf

Private nomeprog := "RMDT004"
Private tamanho  := "G"
Private aReturn  := { "Zebrado", 1,"Administracao", 2, 2, 1, "",1 } // STR0004###STR0005
Private titulo
Private ntipo    := 0
Private nLastKey := 0
Private cPerg    := ""
Private cPerg2	 := "MDT805A" 
Private cabec1	  := " "
Private cabec2   := " "
Private nSizeSI3, nSizeSRJ
Private cFuncMat := " "
Private dDataEnt := " "
Private nDist    := 0
Private cAliasCC := "SI3"
Private cDescCC  := "SI3->I3_DESC"
Private cF3CC    := "SI3" 
Private cCodcc   := "I3_CUSTO"
Private nSizeCC
Private oTempTRB
Private cUsaInt1  := AllTrim(GetMv("MV_NGMDTES"))
Private lMdtGerSA := If( SuperGetMv("MV_NG2SA",.F.,"N") == "S", .T. , .F. ) //Indica se gera SA ao inves de requisitar do estoque
Private lGera_SA  := .T.
Private lDevol := lDevEpi 
Private aDevParc := aClone(aDev)

If !lDevol
	titulo   := "Comprovante de Entrega de EPI" // STR0006 
Else
	titulo   := "Comprovante de Devolução de EPI" // STR0087 
EndIf

If cUsaInt1 != "S" .Or. !lMdtGerSA
	lGera_SA := .F.
EndIf

nSizeCod := If((TamSX3("B1_COD")[1]) < 1,2,(TamSX3("B1_COD")[1]))
If nSizeCod > 15
	nDist   := (nSizeCod/2) + 2
EndIf

nSizeSI3 := If((TamSX3("I3_CUSTO" )[1]) < 1,9 ,(TamSX3("I3_CUSTO" )[1]))
nSizeSRJ := If((TamSX3("RJ_FUNCAO")[1]) < 1,4 ,(TamSX3("RJ_FUNCAO")[1]))
nSizeCC  := If((TamSX3("CTT_CUSTO")[1]) < 1,20,(TamSX3("CTT_CUSTO")[1]))
Private nSizeFil:= FwSizeFilial()

If AllTrim(GETMV("MV_MCONTAB")) == "CTB"
	cAliasCC := "CTT"
	cDescCC  := "CTT->CTT_DESC01"
	cF3CC    := "CTT" 
	cCodcc    := "CTT_CUSTO"
	nSizeSI3 := If((TamSX3("CTT_CUSTO")[1]) < 1,9,(TamSX3("CTT_CUSTO")[1]))	
EndIf

Private cCliMdtPs  := ""
Private lSigaMdtPS := If( SuperGetMv("MV_MDTPS",.F.,"N") == "S", .T. , .F. )
Private lBioMDT    := SuperGetMv("MV_NG2BIOM",.F.,"2") == "1" 

cPerg:= If(!lSigaMdtPS,"MDT805    ","MDT805PS  ")
cCliMdtPs:= If(!lSigaMdtPS,Space(Len(SA1->A1_COD+SA1->A1_LOJA)),"Z")
/*--------------------------------------------------------------------
//PERGUNTAS PADRÃO                                                   |
| MV_PAR01              De Funcionario                               |
| MV_PAR02              Ate Funcionario                              |  
| MV_PAR03              De Data Entrega                              |  
| MV_PAR04              Ate Data Entrega                             |  
| MV_PAR05              So nao Impresos / Todos / Ultima retirada    |  
| MV_PAR06              Termo de Responsabilidade                    |  
| MV_PAR07              Duas vias                                    |  
| MV_PAR08              Ordenar por                                  |  
| MV_PAR09              De Centro de Custo                           |  
| MV_PAR10              Ate Centro de Custo                          |  
| MV_PAR11              Considerar funcionarios demitidos            |  
|                           1 - Sim                                  |  
|                           2 - Nao                                  |  
| MV_PAR12              Ordenar EPIs por:                            |  
|                            1 - Cod                                 |  
|                            2 - Nome                                |  
| MV_PAR13              De Data Admissao                             |  
| MV_PAR14              Ate Data Admissao                            |  
| MV_PAR15              De Filial                                    |  
| MV_PAR16              Ate Filial                                   | 
| MV_PAR17    		   Tipo de Relatório                            | 
|                             1 - Antalítico                         | 
|                             2 - Sintérico                          | 
| MV_PAR18    			 Considerar Ass. Lateral ?                   | 
|             				1 - Sim                                  | 
|      						2 - Não                                  |
|                                                                    |
//PERGUNTAS PRESTADOR DE SERVIÇO                                     |
| MV_PAR01              De Cliente ?                                 |
| MV_PAR02              Loja                                         |
| MV_PAR03              Até Cliente ?                                |
| MV_PAR04              Loja                                         |
| MV_PAR05              De Funcionario                               |
| MV_PAR06              Ate Funcionario                              |  
| MV_PAR07              De Data Entrega                              |  
| MV_PAR08              Ate Data Entrega                             |  
| MV_PAR09              So nao Impresos / Todos / Ultima retirada    |  
| MV_PAR10              Termo de Responsabilidade                    |  
| MV_PAR11              Duas vias                                    |  
| MV_PAR12              Ordenar por                                  |  
| MV_PAR13              De Centro de Custo                           |  
| MV_PAR14              Ate Centro de Custo                          |  
| MV_PAR1              Considerar funcionarios demitidos             |  
|                           1 - Sim                                  |  
|                           2 - Nao                                  |  
| MV_PAR16              Ordenar EPIs por:                            |  
|                            1 - Cod                                 |  
|                            2 - Nome                                |  
| MV_PAR17              De Data Admissao                             |  
| MV_PAR18              Ate Data Admissao                            |  
| MV_PAR19              De Filial                                    |  
| MV_PAR20              Ate Filial                                   | 
| MV_PAR21    		   Tipo de Relatório                            | 
|                             1 - Antalítico                         | 
|                             2 - Sintérico                          | 
| MV_PAR22    			 Considerar Ass. Lateral ?                   | 
|             				1 - Sim                                  | 
|      						2 - Não                                  |
---------------------------------------------------------------------*/

//|-----------------------------------------------------------------------|
//| Verifica as perguntas selecionadas                                    |
//|-----------------------------------------------------------------------|
If IsInCallStack("MDTA695") .Or. IsInCallStack("MDTA630") .Or. IsInCallStack("MDTA410")
	Pergunte(cPerg2,.F.)
Else
	Pergunte(cPerg,.F.)
EndIf
//---------------------------------------------------------------
// Envia controle para a funcao SETPRINT                        
//---------------------------------------------------------------
wnrel:="RMDT004"

If ValType(aRegs695) == "A"
	wnrel := SetPrint(cString,wnrel,cPerg2,titulo,cDesc1,cDesc2,cDesc3,.F.,"")
	Pergunte(cPerg,.F.)
ElseIf ValType(aDad695) == "A"
	wnrel := SetPrint(cString,wnrel,cPerg2,titulo,cDesc1,cDesc2,cDesc3,.F.,"")
	//Adiciona os valores do novo grupo de perguntas no aDad695
	aAdd( aDad695 , { "MV_PAR06" , MV_PAR01 } )
	aAdd( aDad695 , { "MV_PAR07" , MV_PAR02 } )
	aAdd( aDad695 , { "MV_PAR12" , MV_PAR03 } )
	aAdd( aDad695 , { "MV_PAR18" , MV_PAR04 } )
	Pergunte(cPerg,.F.)
	For nFor := 1 To Len(aDad695)
		&(aDad695[nFor,1]) := aDad695[nFor,2]
	Next nFor
	If lSigaMdtps
		cCliMdtPs := MV_PAR01+MV_PAR02
	EndIf
Else
	wnrel:=SetPrint(cString,wnrel,cPerg,titulo,cDesc1,cDesc2,cDesc3,.F.,"")
EndIf

If nLastKey == 27
	Set Filter to
	//---------------------------------------------------------------
	// Devolve variaveis armazenadas (NGRIGHTCLICK)             
	//---------------------------------------------------------------
	NGRETURNPRM(aNGBEGINPRM)
	Return
EndIf                                                                                                  

SetDefault(aReturn,cString)

If nLastKey == 27
	Set Filter to
	//---------------------------------------------------------------
	// Devolve variaveis armazenadas (NGRIGHTCLICK)                          
	//---------------------------------------------------------------
	NGRETURNPRM(aNGBEGINPRM)
	Return
EndIf

RptStatus({|lEnd| RMDT004I(@lEnd,wnRel,titulo,tamanho)},titulo)

//---------------------------------------------------------------
// Devolve variaveis armazenadas (NGRIGHTCLICK)               
//---------------------------------------------------------------
NGRETURNPRM(aNGBEGINPRM)

Return

/*
===============================================================================================================================
Programa----------: RMDT004I
Autor-------------: TOTVS
Data da Criacao---: 20/09/2000
Descrição---------: Chama o relatório.
Parametros--------:lEnd - Cancela a impressão. 
                   wnRel - Nome do programa.
                   titulo - Titulo do relatório. 
                   tamanho - Indica o tamanho do relatório. 
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RMDT004I(lEnd,wnRel,titulo,tamanho)
//---------------------------------------------------------------
// Define Variaveis                                             
//---------------------------------------------------------------
Local cCC := ""
Local i
Local lImp := .F.

//---------------------------------------------------------------
// Variaveis locais exclusivas deste programa                   
//---------------------------------------------------------------
Local nRegAtual := 0
Local nCont
Local nPOSCOD
Local nPOSNUM
Local nPOSDAT
Local nPOSHOR
Local lExistOld
Local aFiliais := {}

//---------------------------------------------------------------
// Contadores de linha e pagina                                 
//---------------------------------------------------------------
Private Li := 80 ,M_PAG := 1
Private lCPODtVenc := .T.

Private cTRB := GetNextAlias()
aDBF := {}
aAdd(aDBF,{"FUNCI"  , "C", 06,0})
aAdd(aDBF,{"NOME"   , "C", 40,0})
aAdd(aDBF,{"RG"     , "C", 15,0})
aAdd(aDBF,{"NASC"   , "D", 10,0})
aAdd(aDBF,{"ADMIS"  , "D", 10,0})
aAdd(aDBF,{"IDADE"  , "C", 03,0})
aAdd(aDBF,{"CC"     , "C", nSizeSI3,0})
aAdd(aDBF,{"DESCC"  , "C", 60,0})
aAdd(aDBF,{"FUNCAO" , "C", nSizeSRJ,0})
aAdd(aDBF,{"DESCFUN", "C", 20,0})
aAdd(aDBF,{"CODEPI" , "C", nSizeCod,0})
aAdd(aDBF,{"DESEPI" , "C", 80,0})
aAdd(aDBF,{"DTENT"  , "D", 10,0})
aAdd(aDBF,{"HRENT"  , "C", 05,0})
aAdd(aDBF,{"QTDE"   , "N", 06,2})
aAdd(aDBF,{"DEV"    , "C", 01,0})
aAdd(aDBF,{"NUMCAP" , "C", 12,0})
aAdd(aDBF,{"NUMCRI" , "C", 12,0})
aAdd(aDBF,{"NUMCRF" , "C", 12,0})
aAdd(aDBF,{"DTDEVO" , "D", 10,0})
aAdd(aDBF,{"CATFUNC", "C", 01,0})
aAdd(aDBF,{"NUMSA"  , "C", 06,0})
aAdd(aDBF,{"ITEMSA" , "C", 02,0})
aAdd(aDBF,{"BIOMET" , "N", 01,0})
aAdd(aDBF,{"NRRECNO", "N", 10,0}) 

If lSigaMdtps
	aAdd(aDBF,{"CLIENT"	, "C", nTa1,0})
	aAdd(aDBF,{"LOJA"	, "C", nTa1L,0})
Else
	aAdd(aDBF,{"FILIAL"	, "C", nSizeFil	,0})
	aAdd(aDBF,{"NOMFIL"	, "C", 40		,0})
EndIf

If Len(aOldACols) > 0
	nPOSCOD := aScan( aHEADER, { |x| Trim( Upper(x[2]) ) == "TNF_CODEPI" }) // Codigo do Epi
	nPOSNUM := aScan( aHEADER, { |x| Trim( Upper(x[2]) ) == "TNF_NUMCAP" }) // Num C. A.
	nPOSDAT := aScan( aHEADER, { |x| Trim( Upper(x[2]) ) == "TNF_DTENTR" }) // Data da Entrega
	nPOSHOR := aScan( aHEADER, { |x| Trim( Upper(x[2]) ) == "TNF_HRENTR" }) // Hora da Entrega
EndIf

If lSigaMdtps
	
	oTempTRB := FWTemporaryTable():New( cTRB, aDBF )
	If MV_PAR16 == 1  //Cod EPI
		oTempTRB:AddIndex( "1", {"FUNCI","CODEPI","NUMCAP","DTENT"} )
		oTempTRB:AddIndex( "2", {"NOME","CODEPI","NUMCAP","DTENT"} )
		oTempTRB:AddIndex( "3", {"CC","FUNCI","CODEPI","NUMCAP","DTENT"} )
		oTempTRB:AddIndex( "4", {"DESCC","FUNCI","CODEPI","NUMCAP","DTENT"} )
	ElseIf MV_PAR16 == 2   //Nome EPI
		oTempTRB:AddIndex( "1", {"FUNCI","DESEPI","CODEPI","NUMCAP","DTENT"} )
		oTempTRB:AddIndex( "2", {"NOME","DESEPI","CODEPI","NUMCAP","DTENT"} )
		oTempTRB:AddIndex( "3", {"CC","FUNCI","DESEPI","CODEPI","NUMCAP","DTENT"} )
		oTempTRB:AddIndex( "4", {"DESCC","FUNCI","DESEPI","CODEPI","NUMCAP","DTENT"} )
	Else	//Data EPI
		oTempTRB:AddIndex( "1", {"FUNCI","DTENT","HRENT","CODEPI","NUMCAP"} )
		oTempTRB:AddIndex( "2", {"FILIAL","NOME","DTENT","HRENT","CODEPI","NUMCAP"} )
		oTempTRB:AddIndex( "3", {"FILIAL","CC","FUNCI","DTENT","CODEPI","NUMCAP","HRENT"} )
		oTempTRB:AddIndex( "4", {"FILIAL","DESCC","FUNCI","DTENT","HRENT","CODEPI","NUMCAP"} )
	EndIf
	oTempTRB:Create()
	
	//---------------------------------------------------------------
	// Verifica se deve comprimir ou nao                            
	//---------------------------------------------------------------
	nTipo  := IIf(aReturn[4]==1,15,18)
	     
	DBSelectArea("TNF")
	If MV_PAR09 == 3
		DBSetOrder(10) //TNF_FILIAL+TNF_CLIENT+TNF_LOJACL+TNF_MAT+DToS(TNF_DTENTR)+TNF_HRENTR+TNF_CODEPI
	Else
		DBSetOrder(08) //TNF_FILIAL+TNF_CLIENT+TNF_LOJACL+TNF_MAT+TNF_CODEPI+DToS(TNF_DTENTR)+TNF_HRENTR
	EndIf 
	DBSeek(xFilial("TNF")+MV_PAR01+MV_PAR02,.T.)

	lImpAuto := .F.
	If ValType(aRegs695) == "A"
		lImpAuto := .T.
		SetRegua(Len(aRegs695))
		For i := 1 to Len(aRegs695)
			IncRegua()
			DBSelectArea("TNF")
			DBGoTo(aRegs695[i])
			If !Eof() .And. !Bof()
				cFuncMat := TNF->TNF_MAT
				RMDT004A()
			EndIf
		Next i
	Else
		SetRegua(LastRec())
	EndIf
	
	//---------------------------------------------------------------
	// Correr TNF para ler os  EPI's Entregues aos Funcionarios 
	//---------------------------------------------------------------
	
	While !Eof() .And. !lImpAuto           	.AND.;
		TNF->TNF_FILIAL == xFilial("TNF")  	.AND.;
		TNF->(TNF_CLIENT+TNF_LOJACL) >= MV_PAR01+MV_PAR02 .And. TNF->(TNF_CLIENT+TNF_LOJACL) <= MV_PAR03+MV_PAR04
		
		IncRegua()
		
		If TNF->TNF_MAT < MV_PAR05 .Or. TNF->TNF_MAT > MV_PAR06
			DBSkip()
			Loop
		EndIf
		
		DBSelectArea("SRA")
		DBSetOrder(01)
		DBSeek(xFilial("SRA")+TNF->TNF_MAT)
		DBSelectArea("TM0")
		DBSetOrder(03)
		DBSeek(SRA->RA_FILIAL+SRA->RA_MAT)
		
		If MV_PAR11 == 2  //Nao considerar funcionarios demitidos
			If ( SRA->RA_SITFOLH == "D" ) .Or. ( !Empty( SRA->RA_DEMISSA ) )
				DBSelectArea("TNF")
				DBSkip()
				Loop
			EndIf
		EndIf
		
		//Data de Admissao
		If SRA->RA_ADMISSA < MV_PAR17 .Or. SRA->RA_ADMISSA > MV_PAR18
			DBSelectArea("TNF")
			DBSkip()
			Loop
		EndIf
		
		cCC := SRA->RA_CC
		
		If ValType(MV_PAR13) == "C" .And. ValType(MV_PAR14) == "C"
			If (cCC < MV_PAR13) .Or. (cCC > MV_PAR14)
				DBSelectArea("TNF")
				DBSkip()
				Loop
			EndIf
		EndIf
		
		If TNF->TNF_DTENTR < MV_PAR07 .Or. TNF->TNF_DTENTR > MV_PAR08
			DBSelectArea("TNF")
			DBSkip()
			Loop
		EndIf
		
		If MV_PAR09 == 2 .And. !Empty(TNF->TNF_DTRECI)
			DBSelectArea("TNF")
			DBSkip()
			Loop
		EndIf
		
		lExistOld := .F.
		If Len(aOldACols) > 0
			For nCont := 1 To Len(aOldACols)
				If aOldACols[nCont][nPOSCOD] == TNF->TNF_CODEPI
					If aOldACols[nCont][nPOSNUM] == TNF->TNF_NUMCAP
						If aOldACols[nCont][nPOSDAT] == TNF->TNF_DTENTR
							If aOldACols[nCont][nPOSHOR] == TNF->TNF_HRENTR
								lExistOld := .T.
								Exit
							EndIf
						EndIf
					EndIf
				EndIf
			Next nCont
			
			If lExistOld
				DBSelectArea("TNF")
				DBSkip()
				Loop
			EndIf
		EndIf
		
		cFuncMat := TNF->TNF_MAT
		
		If MV_PAR09 == 3
			DBSelectArea("TNF")
			dDataEnt := TNF->TNF_DTENTR
			nRegAtual := Recno()
			DBSkip()
			If cFuncMat <> TNF->TNF_MAT
				DBSkip(-1)
				While !Bof()							.AND.;
					TNF->TNF_FILIAL == xFilial("TNF")  	.AND.;
					TNF->TNF_MAT	== cFuncMat        	.AND.;
					TNF->TNF_DTENTR == dDataEnt
					RMDT004A()
					DBSelectArea ("TNF")
					If !lBioMDT .Or. (lBioMDT .And. TM0->TM0_INDBIO != "1")
						RecLock("TNF",.F.)
						TNF->TNF_DTRECI := Date()
						MSUnLock("TNF")
					EndIf
					DBSkip(-1)
				EndDo
				DBGoTo(nRegAtual)
				DBSkip()
			EndIf
			Loop
		Else
			RMDT004A()
			DBSelectArea("TNF")
			If !lBioMDT .Or. (lBioMDT .And. TM0->TM0_INDBIO != "1")
				RecLock("TNF",.F.)
				TNF->TNF_DTRECI := Date()
				MSUnLock("TNF")
			EndIf
			DBSetOrder(03)
			DBSkip()      
		EndIf   

	EndDo
	
Else
	
	oTempTRB := FWTemporaryTable():New( cTRB, aDBF )
	If MV_PAR12 == 1  //Cod EPI
		oTempTRB:AddIndex( "1", {"FILIAL","FUNCI","CODEPI","NUMCAP","DTENT"} )
		oTempTRB:AddIndex( "2", {"FILIAL","NOME","CODEPI","NUMCAP","DTENT"} )
		oTempTRB:AddIndex( "3", {"FILIAL","CC","FUNCI","CODEPI","NUMCAP","DTENT"} )
		oTempTRB:AddIndex( "4", {"FILIAL","DESCC","FUNCI","CODEPI","NUMCAP","DTENT"} )
	ElseIf MV_PAR12 == 2  //Nome EPI
		oTempTRB:AddIndex( "1", {"FUNCI","DESEPI","CODEPI","NUMCAP","DTENT"} )
		oTempTRB:AddIndex( "2", {"FILIAL","NOME","DESEPI","CODEPI","NUMCAP","DTENT"} )
		oTempTRB:AddIndex( "3", {"FILIAL","CC","FUNCI","CODEPI","NUMCAP","DTENT"} )
		oTempTRB:AddIndex( "4", {"FILIAL","DESCC","FUNCI","DESEPI","CODEPI","NUMCAP","DTENT"} )
	Else // Data EPI
		oTempTRB:AddIndex( "1", {"FUNCI","DTENT","HRENT","CODEPI","NUMCAP"} )
		oTempTRB:AddIndex( "2", {"FILIAL","NOME","DTENT","HRENT","CODEPI","NUMCAP"} )
		oTempTRB:AddIndex( "3", {"FILIAL","CC","FUNCI","DTENT","CODEPI","NUMCAP","HRENT"} )
		oTempTRB:AddIndex( "4", {"FILIAL","DESCC","FUNCI","DTENT","HRENT","CODEPI","NUMCAP"} )
	EndIf
	oTempTRB:Create()
   
	lImpAuto := .F.   
	If ValType(aRegs695) == "A"
		lImpAuto := .T.
		SetRegua(Len(aRegs695))
		For i := 1 to Len(aRegs695)      
			IncRegua()   
			DBSelectArea("TNF")
			DBGoTo(aRegs695[i])   
			If !Eof() .And. !Bof()
				cFuncMat := TNF->TNF_MAT
				RMDT004A(cFilAnt,Upper(SubStr(SM0->M0_NOME, 1, 40)))
			EndIf
		Next i
	EndIf
	
	//---------------------------------------------------------------
	// Define Filiais a percorrer                                   
	//---------------------------------------------------------------
	If ValType(aDad695) == "A"
		aFiliais := {{cFilAnt, Upper(SubStr(SM0->M0_NOME, 1, 40)) }}
	Else
		aFiliais := MDTRETFIL("TNF", MV_PAR15, MV_PAR16)
	EndIf
	//---------------------------------------------------------------
	// Verifica se deve comprimir ou nao                            
	//---------------------------------------------------------------
	nTipo  := IIf(aReturn[4]==1,15,18)  
	
	For i:=1 to Len(aFiliais)
		If lImpAuto
			Loop    
		EndIf
		DBSelectArea("TNF")
		If MV_PAR05 == 3
			DBSetOrder(05) //TNF_MAT + DToS(TNF_DTENTR) + TNF_HRENTR + TNF_CODEPI
		Else
			DBSetOrder(03) //TNF_MAT + TNF_CODEPI + DToS(TNF_DTENTR) + TNF_HRENTR
		EndIf
		DBSeek(xFilial("TNF",aFiliais[i,1])+MV_PAR01,.T.)
		
		SetRegua(LastRec())
		
		//---------------------------------------------------------------
		// Correr TNF para ler os  EPI's Entregues aos Funcionarios 
		//---------------------------------------------------------------
		While !Eof() .And. TNF->TNF_FILIAL == xFilial("TNF",aFiliais[i,1]) .And. TNF->TNF_MAT <= MV_PAR02
		
			IncRegua()
			
			DBSelectArea("SRA")
			DBSetOrder(01)
			DBSeek(xFilial("SRA",aFiliais[i,1])+TNF->TNF_MAT)
			DBSelectArea("TM0")
			DBSetOrder(03)
			DBSeek(SRA->RA_FILIAL+SRA->RA_MAT)
			
			If MV_PAR11 == 2  //Nao considerar funcionarios demitidos
				If ( SRA->RA_SITFOLH == "D" ) .Or. ( !Empty( SRA->RA_DEMISSA ) )
					DBSelectArea("TNF")
					DBSkip()
					Loop
				EndIf
			EndIf
			
			//Data de Admissao
			If SRA->RA_ADMISSA < MV_PAR13 .Or. SRA->RA_ADMISSA > MV_PAR14
				DBSelectArea("TNF")
				DBSkip()
				Loop
			EndIf
			
			cCC := SRA->RA_CC
			
			If ValType(MV_PAR09) == "C" .And. ValType(MV_PAR10) == "C"
				If (cCC < MV_PAR09) .Or. (cCC > MV_PAR10)
					DBSelectArea("TNF")
					DBSkip()
					Loop
				EndIf
			EndIf
			
			If TNF->TNF_DTENTR < MV_PAR03 .Or. TNF->TNF_DTENTR > MV_PAR04
				DBSelectArea("TNF")
				DBSkip()
				Loop
			EndIf
			
			If MV_PAR05 == 2 .And. !Empty(TNF->TNF_DTRECI)
				DBSelectArea("TNF")
				DBSkip()
				Loop
			EndIf
			
			lExistOld := .F.
			If Len(aOldACols) > 0
				For nCont := 1 To Len(aOldACols)
					If aOldACols[nCont][nPOSCOD] == TNF->TNF_CODEPI
						If aOldACols[nCont][nPOSNUM] == TNF->TNF_NUMCAP
							If aOldACols[nCont][nPOSDAT] == TNF->TNF_DTENTR
								If aOldACols[nCont][nPOSHOR] == TNF->TNF_HRENTR
									lExistOld := .T.
									Exit
								EndIf
							EndIf
						EndIf
					EndIf
				Next nCont
				
				If lExistOld
                   DBSelectArea("TNF")
				   DBSkip()
				   Loop
				EndIf
			EndIf
			
			cFuncMat := TNF->TNF_MAT
			
			If MV_PAR05 == 3
				DBSelectArea("TNF")
				dDataEnt := TNF->TNF_DTENTR
				nRegAtual := Recno()
				DBSkip()
				If cFuncMat <> TNF->TNF_MAT
					DBSkip(-1)
					While !Bof() .And. TNF->TNF_FILIAL == xFilial("TNF",aFiliais[i,1]) .AND.;
						TNF->TNF_MAT	== cFuncMat .And. TNF->TNF_DTENTR == dDataEnt
						RMDT004A(aFiliais[i,1], aFiliais[i,2])
						DBSelectArea ("TNF")
						If !lBioMDT .Or. (lBioMDT .And. TM0->TM0_INDBIO != "1")
							RecLock("TNF",.F.)
							TNF->TNF_DTRECI := Date()
							MSUnLock("TNF")
						EndIf
						DBSkip(-1)
					EndDo
					DBGoTo(nRegAtual)
					DBSkip()
				EndIf
				Loop
			Else
				RMDT004A(aFiliais[i,1], aFiliais[i,2])
				DBSelectArea("TNF")
				If !lBioMDT .Or. (lBioMDT .And. TM0->TM0_INDBIO != "1")
					RecLock("TNF",.F.)
					TNF->TNF_DTRECI := Date()
					MSUnLock("TNF")
				EndIf
				DBSetOrder(03)
				DBSkip()
			EndIf

		End
	Next i	
EndIf 
//Teste de parametros para saber o tipo de relatório a ser imprimido.
If lSigaMdtPS
	If MV_PAR19 == 1
		RMDT004T()
	Else
  		RMDT004O()
	EndIf
Else 
	If MV_PAR17 == 1
		RMDT004T()
	Else
  		RMDT004O()
	EndIf
EndIf	

If (cTRB)->(RecCount()) > 0
	lImp := .T.
EndIf

oTempTRB:Delete()

//---------------------------------------------------------------
// Devolve a condicao original do arquivo principal             
//---------------------------------------------------------------
RetIndex("TNF")
Set Filter To

If lImp
	Set device to Screen
	
	If aReturn[5] = 1
		Set Printer To
		dbCommitAll()
		OurSpool(wnrel)
	EndIf
	MS_FLUSH()
Else
	MsgStop("Não existem dados para montar o relatório.", "Atenção") // STR0079 ### STR0080
EndIf

DBSelectArea("TNF")
DBSetOrder(1)

Return

/*
===============================================================================================================================
Programa----------: RMDT004S
Autor-------------: TOTVS
Data da Criacao---: 20/09/2000
Descrição---------: Incrementa Linha e Controla Salto de Pagina  
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RMDT004S()
    Li++
    If Li > 58   
       Cabec(titulo,cabec1,cabec2,nomeprog,tamanho,nTipo)
    EndIf
Return

/*
Layout de Impressão:
====================

          1         2         3         4         5         6         7         8         9         0         1         2         3
0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012
-------------------------------------------------------------------------------------------------------------------------------------
|XXXXXXXXXXXXX                                      COMPROVANTE DE ENTREGA DE EPI'S                                                 |
|SIGA/RMDT004                                    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx                Emissao: 99/99/99   hh:mm    |
-------------------------------------------------------------------------------------------------------------------------------------
|Funcionario.....: xxxxxx - xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx                         RG.: xxx.xxx.xxx			        		|
|Centro de Custo.: xxxxxxxxx - xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx						 		                                    |
|Funcao..........: xxxx  -  xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx   					                                     		|
|Nascimento......: xx/xx/xx                                                               Admissao.: xx/xx/xx     Idade.: xx  		|
------------------------------------------------------------EPI's--------------------------------------------------------------------
|EPI              Nome do EPI                        Dt. Entr  Hora     Qtde  Dev. Dt. Devo  Num. CA 	                            |
|  Num. CRF      Num. CRI      Num. SA  Item SA                   													                |
|xxxxxxxxxxxxxxx  xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx  xx/xx/xx  xx:xx  xxx,xx  xxx  xx/xx/xx  xxxxxxxxxxxx  Ass.: _________________  |
|  xxxxxxxxxxxx  xxxxxxxxxxxx  xxxxxx   xx                                                                                          |
|xxxxxxxxxxxxxxx  xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx  xx/xx/xx  xx:xx  xxx,xx  xxx  xx/xx/xx  xxxxxxxxxxxx  Ass.: _________________  |
|xxxxxxxxxxxxxxx  xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx  xx/xx/xx  xx:xx  xxx,xx  xxx  xx/xx/xx  xxxxxxxxxxxx  Ass.: _________________  |
|                                                                               													|
-------------------------------------------------------------------------------------------------------------------------------------
|       Data : ___/___/___                                                           							              	    |
|                                                                               													|
|       Assinatura: _______________________                                   Resp Empr: _______________________                    |
|                                                                               													|
-------------------------------------------------------------------------------------------------------------------------------------
*/             

/*
===============================================================================================================================
Programa----------: RMDT004T
Autor-------------: TOTVS
Data da Criacao---: 20/09/2000
Descrição---------: Impressão do Relatório.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RMDT004T()
Local LinhaCorrente
Local lPrimvez := .T. 
Local _nRegAtu 

If lSigaMdtps
	
	DBSelectArea(cTRB)
	If MV_PAR12 == 1  //Matricula
		DBSetOrder(1)
	ElseIf MV_PAR12 == 2  //Nome Funcionario
		DBSetOrder(2)
	ElseIf MV_PAR12 == 3  //Cod. C. Custo
		DBSetOrder(3)
	ElseIf MV_PAR12 == 4  //Nome C. Custo
		DBSetOrder(4)
	EndIf
	
	DBGoTop()
	
	While !Eof()
		
		DBSelectArea("SA1")
		DBSetOrder(1)
		DBSeek(xFilial("SA1")+(cTRB)->CLIENT+(cTRB)->LOJA)
		
		CFUNC := (cTRB)->FUNCI
		nVolta := 0
		RMDT004S()
		@ Li,000 PSay " "+Replicate("_",219)
		RMDT004S()
		@ Li,000 PSay "|"
		@ Li,001 Psay "Empresa...:" + SubStr(SA1->A1_NOME,1,60) //  STR0027
		@ Li,127 Psay "CNPJ..:" + SA1->A1_CGC // STR0075
		@ Li,220 PSay "|"
		RMDT004S()
		
		@ Li,000 PSay "|"
		@ Li,001 Psay "Endereco..:" + SA1->A1_END // STR0028
		@ Li,127 Psay "Cidade..:" + SA1->A1_MUN // STR0029
		@ Li,162 Psay "Estado.." + ":" + SA1->A1_EST  // STR0030
		@ Li,221 PSay "|"
		RMDT004S()
		@ Li,000 PSay "|"
		@ Li,001 PSay Replicate("_",219)
		@ Li,220 PSay "|"
		
		RMDT004S()
		@ Li,000 PSay "|Funcionario.....:" // STR0010 
		@ Li,019 PSay CFUNC PICTURE "@!"
		@ Li,026 PSAY " - " + (cTRB)->NOME
		@ Li,127 PSay "RG.:" // STR0011
		@ Li,132 PSay (cTRB)->RG PICTURE "@!"
		@ Li,220 PSay "|"  
		
		RMDT004S()
		@ Li,000 PSay "|Centro de Custo.:" // STR0012 
		
		@ Li,019 PSay AllTrim((cTRB)->CC) +" - "+ AllTrim((cTRB)->DESCC)
		@ Li,127 PSay "Categoria Func.:" // STR0066
		
		cGrpCus := " SELECT "
		cGrpCus += " X5_CHAVE CHAVE,X5_DESCRI DESCRI "
		cGrpCus += " FROM "+ RetSqlName("SX5") +" X5 "
		cGrpCus += " WHERE "
		cGrpCus += "     D_E_L_E_T_ = ' ' "
		cGrpCus += " AND X5_TABELA  = '28' "
		cGrpCus += " AND X5_CHAVE >= '" + (cTRB)->CATFUNC + "'"
		cGrpCus += " AND X5_FILIAL  = '" + xFilial("SX5") + "'"	
		cGrpCus += " ORDER BY X5_CHAVE"

		If Select("TR5") > 0
			DBSelectArea("TR5")
			DBCloseArea()
		EndIf

		TCQUERY cGrpCus New Alias "TR5"
		DBSelectArea("TR5")

		@ Li,144 PSay SubStr(TR5->_DESCRI,1,30) PICTURE "@!"
		@ Li,220 PSay "|"

		If Select("TR5") >0
			DBSelectArea("TR5")
			DBCloseArea()
		EndIf
		
		RMDT004S()
		@ Li,000 PSay "|Funcao..........:" // STR0013 
		@ Li,019 PSay AllTrim((cTRB)->FUNCAO) +" - "+ AllTrim((cTRB)->DESCFUN) PICTURE "@!"
		@ Li,220 PSay "|"
		
		RMDT004S()
		@ Li,000 PSay "|Nascimento......:" // STR0014 
		@ Li,019 PSay (cTRB)->NASC PICTURE "99/99/9999"
		@ Li,127 PSay "Admissao.:" // STR0015 
		@ Li,138 PSay (cTRB)->ADMIS PICTURE "99/99/9999"
		@ Li,157 PSay "Idade.:" // STR0016 
		@ Li,165 PSay (cTRB)->IDADE +" "+ "anos" // STR0039 
		@ Li,220 PSay "|"
		
		lLinha := .F.
		lFirst := .T.
		
		RMDT004S()
		@ Li,000 PSay "|"
		@ Li,001 PSay Replicate("_",219)
		@ Li,220 PSay "|"
		RMDT004S()
		@ Li,000 Psay "|"
		@ Li,001 PSay "EPI" // STR0017    
		@ Li,017+nDist PSay "Nome do EPI" // STR0018
		@ Li,139+nDist PSay "Dt. Entr" // STR0019    
		@ Li,151+nDist PSay "Hora" // STR0040    
		@ Li,158+nDist PSay "Qtde" // STR0025 
		@ Li,166+nDist PSay "Dev." // STR0020    
		@ Li,171+nDist PSay "Dt. Devo" // STR0042 
		@ Li,183+nDist PSay "Num C.A." // STR0026
		@ Li,220 Psay "|"
		RMDT004S()
		@ Li,000 Psay "|"
		DBSelectArea("TN3")
		@ Li,002 PSay "Num. CRF" // STR0033
		lLinha := .T.
		@ Li,016 PSay "Num. CRI" // STR0034
		lLinha := .T.
		If lGera_SA
			@ Li,031 PSay "Num. SA" // STR0082 
			@ Li,040 PSay "Item SA" // STR0083 
			lLinha := .T.
		EndIf
		DBSelectArea(cTRB)
		While !Eof() .And. (cTRB)->FUNCI == CFUNC
			If lLinha .And. lFirst
				@ Li,220 Psay "|"
				RMDT004S()
				@ Li,000 PSay "|"
			EndIf
			If !lFirst
				RMDT004S()
				@ Li,000 PSay "|"
			EndIf
			lFirst := .F.
			@ Li,001 PSAY (cTRB)->CODEPI
			@ Li,017+nDist PSay SubStr(AllTrim((cTRB)->DESEPI),1,80) PICTURE "@!"
			@ Li,139+nDist PSay (cTRB)->DTENT PICTURE "99/99/9999"
			@ Li,151+nDist PSay (cTRB)->HRENT PICTURE "99:99"
			@ Li,158+nDist PSay (cTRB)->QTDE  PICTURE "@E 999.99"
			If (cTRB)->DEV = "1"
				@ LI,166+nDist PSAY "SIM" // STR0021 
			Else
				@ LI,166+nDist PSAY "NAO" // STR0022  
			EndIf
			@ Li,171+nDist PSay (cTRB)->DTDEVO PICTURE "99/99/9999"
			If !Empty((cTRB)->NUMCAP)
				@ Li,183+nDist PSay AllTrim(SubStr((cTRB)->NUMCAP,1,12))
			EndIf 
			If lLinha
				@ Li,220 Psay "|" 
				RMDT004S()  
				@ Li,000 Psay "|"
			EndIf
		
			DBSelectArea("TN3")
			@ Li,002 PSay (cTRB)->NUMCRF
			@ Li,016 PSay (cTRB)->NUMCRI
			If lGera_SA
	           _nRegAtu := TNF->(Recno()) 	 
			   TNF->(DBGoTo((cTRB)->NRRECNO)) 
			   
				//@ Li,031 PSay (cTRB)->NUMSA  
				//@ Li,040 PSay (cTRB)->ITEMSA 
				
				@ Li,031 PSay TNF->TNF_NUMSA  
				@ Li,040 PSay TNF->TNF_ITEMSA 
				
				TNF->(DBGoTo(_nRegAtu)) 
			EndIf      
			
			If (cTRB)->BIOMET == 1 .Or. ValType(aRegs695) == "A"
				If lDevol .And. (cTRB)->BIOMET == 2
					@ Li,195 PSay "Ass.: _________________" // STR0076 
				Else
					@ Li,199 PSay "Registro Biométrico" // STR0086 
				EndIf	
	   		Else
				If MV_PAR20 == 1
					@ Li,195 PSay "Ass.: _________________" // STR0076 
				EndIf
			EndIf
			
			@ Li,220 PSay "|"
			nVolta++
			DBSelectArea(cTRB)
			DBSkip()
		EndDo
		DBSkip(-1)
		
		//termo
		DBSelectArea("TMZ")
		DBSetOrder(01)
		If DBSeek(xFilial("TMZ")+MV_PAR10)
			RMDT004S()
			@ Li,000 PSay "|"
			@ Li,001 PSay Replicate("_",219)
			@ Li,220 PSay "|"
			RMDT004S()
			@ Li,000 PSay "|"
			@ Li,098 PSay "TERMO DE RESPONSABILIDADE" // STR0041 
			@ Li,220 PSay "|"
			RMDT004S()
			@ Li,000 PSay "|"
			lPrimeiro := .T.
			
			nLinhasMemo := MLCOUNT(TMZ->TMZ_DESCRI,219)
			For LinhaCorrente := 1 to nLinhasMemo
				If lPrimeiro
					If !Empty((MemoLine(TMZ->TMZ_DESCRI,56,LinhaCorrente)))
						@ Li,001 PSAY (MemoLine(TMZ->TMZ_DESCRI,219,LinhaCorrente))
						@ Li,220 PSay "|"
						lPrimeiro := .F.
					Else
						Exit
					EndIf
				Else
					@ Li,000 PSay "|"
					@ Li,001 PSAY (MemoLine(TMZ->TMZ_DESCRI,219,LinhaCorrente))
					@ Li,220 PSay "|"
				EndIf
				RMDT004S()
			Next
			If !lPrimeiro
				@ Li,000 PSay "|"
			EndIf
			@ Li,220 PSay "|"
		EndIf
		// fim do termo
		
		RMDT004S()
		@ Li,000 PSay "|"
		@ Li,001 PSay Replicate("_",219)
		@ Li,220 PSay "|"
		RMDT004S()
		@ Li,000 PSay "|"
		@ Li,220 PSay "|"
		RMDT004S()
		@ Li,000 PSay "|       Data : ____/____/____" // STR0036 
		@ Li,220 PSay "|"
		RMDT004S()
		@ Li,000 PSay "|"
		@ Li,220 PSay "|"
		RMDT004S()
		@ Li,000 PSay "|       Assinatura: _______________________ " // STR0037 
		@ Li,127 PSay "Resp Empr: _______________________" // STR0088 
		@ Li,220 Psay "|"
		RMDT004S()
		@ Li,000 Psay "|"
		@ Li,220 Psay "|"
		RMDT004S()
		@ Li,000 PSay "|"
		@ Li,001 PSay Replicate("_",219)
		@ Li,220 PSay "|"
		LI := 80
		If MV_PAR11 == 2 .And. lPrimvez
			DBSelectArea(cTRB)
			DBSkip(-(nVolta-1))
			lPrimvez := .F.
		Else
			DBSelectArea(cTRB)
			DBSkip()
			lPrimvez := .T.
		EndIf
		
	EndDo
	
Else
	
	DBSelectArea(cTRB)
	If MV_PAR08 == 1  //Matricula
		DBSetOrder(1)
	ElseIf MV_PAR08 == 2  //Nome Funcionario
		DBSetOrder(2)
	ElseIf MV_PAR08 == 3  //Cod. C. Custo
		DBSetOrder(3)
	ElseIf MV_PAR08 == 4  //Nome C. Custo
		DBSetOrder(4)
	EndIf
	
	DBGoTop()
	
	While !Eof()
		
		CFUNC := (cTRB)->FUNCI
		nVolta := 0
		RMDT004S()
		@ Li,000 PSay " "+Replicate("_",219)
		RMDT004S()
		@ Li,000 PSay "|"
		@ Li,001 Psay "Empresa...:" + SubStr(SM0->M0_NOMECOM,1,60) // STR0027
		@ Li,127 Psay "CNPJ..:" + SM0->M0_CGC // STR0075
		@ Li,220 PSay "|"
		If NGSX2MODO("TNF") != "C"
			RMDT004S()
			@ Li,000 PSay "|"
			@ Li,001 Psay "Filial....:" + AllTrim((cTRB)->FILIAL) + " - " + (cTRB)->NOMFIL // STR0081
			@ Li,220 PSay "|"
		EndIf
		RMDT004S()
		
		@ Li,000 PSay "|"
		@ Li,001 Psay  "Endereco..:" + SM0->M0_ENDENT // STR0028
		@ Li,127 Psay  "Cidade..:" + SM0->M0_CIDCOB // STR0029
		@ Li,162 Psay  "Estado.." + ":" + SM0->M0_ESTCOB // STR0030
		@ Li,221 PSay "|"
		RMDT004S()
		@ Li,000 PSay "|"
		@ Li,001 PSay Replicate("_",219)
		@ Li,220 PSay "|"
		
		RMDT004S()
		@ Li,000 PSay "|Funcionario.....:" // STR0010 
		@ Li,019 PSay CFUNC PICTURE "@!"
		@ Li,026 PSAY " - " + (cTRB)->NOME
		@ Li,127 PSay "RG.:" // STR0011 
		@ Li,132 PSay (cTRB)->RG PICTURE "@!"
		@ Li,220 PSay "|"
		
		RMDT004S()
		@ Li,000 PSay "|Centro de Custo.:" // STR0012 
		
		@ Li,019 PSay AllTrim((cTRB)->CC) +" - "+ AllTrim((cTRB)->DESCC)
		@ Li,127 PSay "Categoria Func.:" // STR0066
		
			cGrpCus := " SELECT "
		cGrpCus += " X5_CHAVE CHAVE,X5_DESCRI DESCRI "
		cGrpCus += " FROM "+ RetSqlName("SX5") +" X5 "
		cGrpCus += " WHERE "
		cGrpCus += "     D_E_L_E_T_ = ' ' "
		cGrpCus += " AND X5_TABELA  = '28' "
		cGrpCus += " AND X5_CHAVE >= '" + (cTRB)->CATFUNC + "'"
		cGrpCus += " AND X5_FILIAL  = '" + xFilial("SX5") + "'"	
		cGrpCus += " ORDER BY X5_CHAVE"

		If Select("TR5") >0
			DBSelectArea("TR5")
			DBCloseArea()
		EndIf

		TCQUERY cGrpCus New Alias "TR5"
		DBSelectArea("TR5")

		@ Li,144 PSay SubStr(TR5->DESCRI,1,30) PICTURE "@!"
		@ Li,220 PSay "|"

		If Select("TR5") >0
			DBSelectArea("TR5")
			DBCloseArea()
		EndIf
		
		RMDT004S()
		@ Li,000 PSay "|Funcao..........:" // STR0013 
		@ Li,019 PSay AllTrim((cTRB)->FUNCAO) +" - "+ AllTrim((cTRB)->DESCFUN) PICTURE "@!"
		@ Li,220 PSay "|"
		
		RMDT004S()
		@ Li,000 PSay "|Nascimento......:" // STR0014 
		@ Li,019 PSay (cTRB)->NASC PICTURE "99/99/9999"
		@ Li,127 PSay "Admissao.:" // STR0015 
		@ Li,138 PSay (cTRB)->ADMIS PICTURE "99/99/9999"
		@ Li,157 PSay "Idade.:" // STR0016 
		@ Li,165 PSay (cTRB)->IDADE +" "+ "anos" // STR0039
		@ Li,220 PSay "|"
		
		lLinha := .F.
		lFirst := .T.
		
		RMDT004S()
		@ Li,000 PSay "|"
		@ Li,001 PSay Replicate("_",219)
		@ Li,220 PSay "|"
		RMDT004S()
		@ Li,000 Psay "|"
		@ Li,001 PSay "EPI" // STR0017     
		@ Li,017+nDist PSay "Nome do EPI" // STR0018 
		@ Li,139+nDist PSay "Dt. Entr" // STR0019  
		@ Li,151+nDist PSay "Hora" // STR0040     
		@ Li,158+nDist PSay "Qtde" // STR0025 
		@ Li,166+nDist PSay "Dev." // STR0020     
		@ Li,171+nDist PSay "Dt. Devo" // STR0042
		@ Li,183+nDist PSay "Num C.A." // STR0026
		@ Li,220 Psay "|"
		RMDT004S()
		@ Li,000 Psay "|"
		DBSelectArea("TN3")
		@ Li,002 PSay "Num. CRF" // STR0033 
		lLinha := .T.
		@ Li,016 PSay "Num. CRI" // STR0034
		lLinha := .T.
		If lGera_SA
			@ Li,031 PSay "Num. SA" // STR0082 
			@ Li,040 PSay "Item SA" // STR0083 
			lLinha := .T.
		EndIf
		DBSelectArea(cTRB)
		While !Eof() .And. (cTRB)->FUNCI == CFUNC
			If lLinha .And. lFirst
				@ Li,220 Psay "|"
				RMDT004S()
				@ Li,000 PSay "|"
			EndIf
			If !lFirst
				RMDT004S()
				@ Li,000 PSay "|"
			EndIf
			lFirst := .F.
			@ Li,001 PSAY (cTRB)->CODEPI
			@ Li,017+nDist PSay SubStr(AllTrim((cTRB)->DESEPI),1,80) PICTURE "@!"
			@ Li,139+nDist PSay (cTRB)->DTENT PICTURE "99/99/9999"
			@ Li,151+nDist PSay (cTRB)->HRENT PICTURE "99:99"
			@ Li,158+nDist PSay (cTRB)->QTDE  PICTURE "@E 999.99"
			If (cTRB)->DEV = "1"
				@ LI,166+nDist PSAY "SIM" // STR0021 
			Else
				@ LI,166+nDist PSAY "NAO" // STR0022  
			EndIf
			@ Li,171+nDist PSay (cTRB)->DTDEVO PICTURE "99/99/9999"
			If !Empty((cTRB)->NUMCAP)
				@ Li,183+nDist PSay AllTrim(SubStr((cTRB)->NUMCAP,1,12))
			EndIf

			If lLinha
				@ Li,220 Psay "|" 
				RMDT004S()  
				@ Li,000 Psay "|"
			EndIf
							
			DBSelectArea("TN3")
			@ Li,002 PSay (cTRB)->NUMCRF
			@ Li,016 PSay (cTRB)->NUMCRI
			If lGera_SA
				//@ Li,031 PSay (cTRB)->NUMSA
				//@ Li,040 PSay (cTRB)->ITEMSA
				
				
			   _nRegAtu := TNF->(Recno()) 		 
			   TNF->(DBGoTo((cTRB)->NRRECNO )) 
			   
				//@ Li,031 PSay (cTRB)->NUMSA  
				//@ Li,040 PSay (cTRB)->ITEMSA 
				
				@ Li,031 PSay TNF->TNF_NUMSA  
				@ Li,040 PSay TNF->TNF_ITEMSA 
				
				TNF->(DBGoTo(_nRegAtu)) 
				
				
			EndIf 

			If (cTRB)->BIOMET == 1 .Or. ValType(aRegs695) == "A"
				If lDevol .And. (cTRB)->BIOMET == 2
					@ Li,195 PSay "Ass.: _________________" // STR0076 
				Else
					@ Li,199 PSay "Registro Biométrico" // STR0086
				EndIf					
	   		Else
	   			If MV_PAR18 == 1
					@ Li,195 PSay "Ass.: _________________" // STR0076 
				EndIf	
			EndIf
				
			@ Li,220 PSay "|"
			nVolta++
			DBSelectArea(cTRB)
			DBSkip()
		EndDo
		DBSkip(-1)
		
		//termo
		DBSelectArea("TMZ")
		DBSetOrder(01)
		If DBSeek(xFilial("TMZ")+MV_PAR06)
			RMDT004S()
			@ Li,000 PSay "|"
			@ Li,001 PSay Replicate("_",219)
			@ Li,220 PSay "|"
			RMDT004S()
			@ Li,000 PSay "|"
			@ Li,098 PSay "TERMO DE RESPONSABILIDADE" // STR0041 
			@ Li,220 PSay "|"
			RMDT004S()
			@ Li,000 PSay "|"
			lPrimeiro := .T.
			
			nLinhasMemo := MLCOUNT(TMZ->TMZ_DESCRI,219)
			For LinhaCorrente := 1 to nLinhasMemo
				If lPrimeiro
					If !Empty((MemoLine(TMZ->TMZ_DESCRI,56,LinhaCorrente)))
						@ Li,001 PSAY (MemoLine(TMZ->TMZ_DESCRI,219,LinhaCorrente))
						@ Li,220 PSay "|"
						lPrimeiro := .F.
					Else
						Exit
					EndIf
				Else
					@ Li,000 PSay "|"
					@ Li,001 PSAY (MemoLine(TMZ->TMZ_DESCRI,219,LinhaCorrente))
					@ Li,220 PSay "|"
				EndIf
				RMDT004S()
			Next
			If !lPrimeiro
				@ Li,000 PSay "|"
			EndIf
			@ Li,220 PSay "|"
		EndIf
		// fim do termo
		
		RMDT004S()
		@ Li,000 PSay "|"
		@ Li,001 PSay Replicate("_",219)
		@ Li,220 PSay "|"
		RMDT004S()
		@ Li,000 PSay "|"
		@ Li,220 PSay "|"
		RMDT004S()
		@ Li,000 PSay "|       Data : ____/____/____" // STR0036
		@ Li,220 PSay "|"
		RMDT004S()
		@ Li,000 PSay "|"
		@ Li,220 PSay "|"
		RMDT004S()
		@ Li,000 PSay "|       Assinatura: _______________________" // STR0037 
		@ Li,127 PSay "Resp Empr: _______________________" // STR0088 
		@ Li,220 Psay "|"
		RMDT004S()
		@ Li,000 Psay "|"
		@ Li,220 Psay "|"
		RMDT004S()
		@ Li,000 PSay "|"
		@ Li,001 PSay Replicate("_",219)
		@ Li,220 PSay "|"
		LI := 80
		If MV_PAR07 == 2 .And. lPrimvez
			DBSelectArea(cTRB)
			DBSkip(-(nVolta-1))
			lPrimvez := .F.
		Else
			DBSelectArea(cTRB)
			DBSkip()
			lPrimvez := .T.
		EndIf
		
	End
EndIf

Return

/*
===============================================================================================================================
Programa----------: RMDT004A
Autor-------------: TOTVS
Data da Criacao---: 20/09/2000
Descrição---------: Armazena informacoes de um recibo para impressao.
Parametros--------: cCodFil - Codigo da Filial 
                    cNomFil - Nome da Filial 
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RMDT004A(cCodFil, cNomFil)

Local nW := 0
Local _nQtdDevolv, _dDtDevolv, _aRetQtdDev

Default cCodFil := "", cNomFil := ""

If lSigaMdtps
	
	DBSelectArea("TN3")
	DBSetOrder(5)  //TN3_FILIAL+TN3_CLIENT+TN3_LOJACL+TN3_FORNEC+TN3_LOJA+TN3_CODEPI+TN3_NUMCAP
	DBSeek(xFilial("TN3")+TNF->TNF_CLIENT+TNF->TNF_LOJACL+TNF->TNF_FORNEC+TNF->TNF_LOJA+TNF->TNF_CODEPI+TNF->TNF_NUMCAP)
	
	DBSelectArea("SRA")
	DBSetOrder(01)
	DBSeek(xFilial("SRA")+cFuncMat)
	
	DBSelectArea(cTRB)
	(cTRB)->(DbAppend())
	(cTRB)->FUNCI    := cFuncMat
	(cTRB)->NOME     := SubStr(SRA->RA_NOME,1,40)
	(cTRB)->RG       := SRA->RA_RG
	(cTRB)->CATFUNC  := SRA->RA_CATFUNC
	(cTRB)->NASC     := SRA->RA_NASC
	(cTRB)->ADMIS    := SRA->RA_ADMISSA
	(cTRB)->IDADE    := R555ID( ( cTRB )->NASC )
	(cTRB)->CC       := SRA->RA_CC
	(cTRB)->DESCC    := NgSeek(cAliasCC,(cTRB)->CC,1,cDescCC)
	(cTRB)->FUNCAO   := SRA->RA_CODFUNC
	(cTRB)->DESCFUN  := AllTrim (NgSeek("SRJ",(cTRB)->FUNCAO,1,"SRJ->RJ_DESC"))
	(cTRB)->CODEPI   := TNF->TNF_CODEPI
	(cTRB)->DESEPI   := NgSeek("SB1",TNF->TNF_CODEPI,1,"SB1->B1_DESC")
	(cTRB)->DTENT    := TNF->TNF_DTENTR
	(cTRB)->HRENT    := TNF->TNF_HRENTR
	(cTRB)->QTDE     := TNF->TNF_QTDENT 
	(cTRB)->DEV      := TNF->TNF_INDDEV
	(cTRB)->NUMCAP   := TNF->TNF_NUMCAP
	(cTRB)->NRRECNO  := TNF->(Recno()) 

	If lDevol	//Se For recibo de Devolução
		If TNF->TNF_DEVBIO == "1"
			(cTRB)->BIOMET   := 1
		Else
			(cTRB)->BIOMET   := 2
		EndIf	
	Else
		(cTRB)->BIOMET   := If(!Empty(TNF->TNF_DIGIT1),1,2)
	EndIf
	(cTRB)->NUMCRI := TN3->TN3_NUMCRI
	(cTRB)->NUMCRF := TN3->TN3_NUMCRF
	(cTRB)->DTDEVO := TNF->TNF_DTDEVO
	If lGera_SA
		(cTRB)->NUMSA  := TNF->TNF_NUMSA
		(cTRB)->ITEMSA := TNF->TNF_ITEMSA
	EndIf
	
	(cTRB)->CLIENT    := TNF->TNF_CLIENT
	(cTRB)->LOJA      := TNF->TNF_LOJACL
	
Else
	
	DBSelectArea("TN3")
	DBSetOrder(1)
	DBSeek(xFilial("TN3",cCodFil)+TNF->TNF_FORNEC+TNF->TNF_LOJA+TNF->TNF_CODEPI+TNF->TNF_NUMCAP)
	
	DBSelectArea("SRA")
	DBSetOrder(01)
	DBSeek(xFilial("SRA",cCodFil)+cFuncMat)

	DBSelectArea(cAliasCC)
	DBSetOrder(01)
	DBSeek(xFilial(cAliasCC,cCodFil)+SRA->RA_CC)

	DBSelectArea("SRJ")
	DBSetOrder(01)
	DBSeek(xFilial("SRJ",cCodFil)+SRA->RA_CODFUNC)

	DBSelectArea("SB1")
	DBSetOrder(01)
	DBSeek(xFilial("SB1",cCodFil)+TNF->TNF_CODEPI)
				
	If Len(aDevParc) > 0 .And.; //Caso seja devolução parcial. 
	   aScan( aDevParc , { | x | x[ 1 ] == TNF->TNF_FILIAL .And.;
	   						 x[ 2 ] == TNF->TNF_CODEPI .And.;
	   					     x[ 3 ] == TNF->TNF_FORNEC .And.;
	   						 x[ 4 ] == TNF->TNF_LOJA .And.;
	   						 x[ 5 ] == TNF->TNF_NUMCAP .And.;
	   						 x[ 6 ] == TNF->TNF_MAT .And.;
	   						 x[ 7 ] == TNF->TNF_DTENTR .And.;
	   						 x[ 8 ] == TNF->TNF_HRENTR } )//Caso Epi estaja em uso, verifica a devolução Parcial.
	
		For nW := 1 To Len(aDevParc)
			If aDevParc[nW,1] == TNF->TNF_FILIAL .And. aDevParc[nW,2] == TNF->TNF_CODEPI .And.;
			   aDevParc[nW,3] == TNF->TNF_FORNEC .And. aDevParc[nW,4] == TNF->TNF_LOJA .And.;
			   aDevParc[nW,5] == TNF->TNF_NUMCAP .And. aDevParc[nW,6] == TNF->TNF_MAT .And.;
			   aDevParc[nW,7] == TNF->TNF_DTENTR .And. aDevParc[nW,8] == TNF->TNF_HRENTR
			   
			 	DBSelectArea(cTRB)
				(cTRB)->(DbAppend())
				(cTRB)->FUNCI    := cFuncMat
				(cTRB)->NOME     := SubStr(SRA->RA_NOME,1,40)
				(cTRB)->RG       := SRA->RA_RG
				(cTRB)->CATFUNC  := SRA->RA_CATFUNC
				(cTRB)->NASC     := SRA->RA_NASC
				(cTRB)->ADMIS    := SRA->RA_ADMISSA
				(cTRB)->IDADE    := R555ID( ( cTRB )->NASC )
				(cTRB)->CC       := SRA->RA_CC
				(cTRB)->DESCC    := AllTrim(&(cDescCC))
				(cTRB)->FUNCAO   := SRA->RA_CODFUNC
				(cTRB)->DESCFUN  := AllTrim(SRJ->RJ_DESC)
				(cTRB)->CODEPI   := TNF->TNF_CODEPI
				(cTRB)->DESEPI   := AllTrim(SB1->B1_DESC)
				(cTRB)->DTENT    := TNF->TNF_DTENTR
				(cTRB)->HRENT    := TNF->TNF_HRENTR
				(cTRB)->QTDE     := aDevParc[nW,11]//TNF->TNF_QTDENT
				(cTRB)->DEV      := "1"
				(cTRB)->DTDEVO   := aDevParc[nW,9]
				(cTRB)->NUMCAP   := TNF->TNF_NUMCAP
				(cTRB)->NRRECNO  := TNF->(Recno()) 
				
				If lDevol	//Se For recibo de Devolução
					If TNF->TNF_DEVBIO == "1"
						(cTRB)->BIOMET   := 1
					Else
						(cTRB)->BIOMET   := 2
					EndIf	
				Else
					(cTRB)->BIOMET   := If(!Empty(TNF->TNF_DIGIT1),1,2)
				EndIf
				(cTRB)->NUMCRI := TN3->TN3_NUMCRI
				(cTRB)->NUMCRF := TN3->TN3_NUMCRF
				If lGera_SA
					(cTRB)->NUMSA  := TNF->TNF_NUMSA
					(cTRB)->ITEMSA := TNF->TNF_ITEMSA
				EndIf
				(cTRB)->FILIAL    := xFilial("SRA",cCodFil)
				(cTRB)->NOMFIL    := cNomFil  
			EndIf
		Next nW 
	Else //Caso seja devolução total.
	
        _nQtdDevolv := 0
        
        If lDevol
           _aRetQtdDev := RMDT004Q()
           _nQtdDevolv := _aRetQtdDev[1] 
           _dDtDevolv  := _aRetQtdDev[2] 
        Else
           _nQtdDevolv := TNF->TNF_QTDENT 
           _dDtDevolv  := TNF->TNF_DTDEVO 
        EndIf	
	
		DBSelectArea(cTRB)
		(cTRB)->(DbAppend())
	    (cTRB)->FUNCI    := cFuncMat
	    (cTRB)->NOME     := SubStr(SRA->RA_NOME,1,40)
	    (cTRB)->RG       := SRA->RA_RG
	    (cTRB)->CATFUNC  := SRA->RA_CATFUNC
	    (cTRB)->NASC     := SRA->RA_NASC
	    (cTRB)->ADMIS    := SRA->RA_ADMISSA
	    (cTRB)->IDADE    := R555ID( ( cTRB )->NASC )
	    (cTRB)->CC       := SRA->RA_CC
	    (cTRB)->DESCC    := AllTrim(&(cDescCC))
	    (cTRB)->FUNCAO   := SRA->RA_CODFUNC
	    (cTRB)->DESCFUN  := AllTrim(SRJ->RJ_DESC)
	    (cTRB)->CODEPI   := TNF->TNF_CODEPI
	    (cTRB)->DESEPI   := AllTrim(SB1->B1_DESC)
	    (cTRB)->DTENT    := TNF->TNF_DTENTR
	    (cTRB)->HRENT    := TNF->TNF_HRENTR
	    (cTRB)->QTDE     := _nQtdDevolv  
	    (cTRB)->DEV      := TNF->TNF_INDDEV
	    (cTRB)->DTDEVO   := _dDtDevolv  
	    (cTRB)->NUMCAP   := TNF->TNF_NUMCAP
	    (cTRB)->NRRECNO  := TNF->(Recno()) 
	    
	    If lDevol	//Se For recibo de Devolução
		   If TNF->TNF_DEVBIO == "1"
			  (cTRB)->BIOMET   := 1
		   Else
			  (cTRB)->BIOMET   := 2
		   EndIf	
	    Else
	       (cTRB)->BIOMET   := If(!Empty(TNF->TNF_DIGIT1),1,2)
	    EndIf
	   (cTRB)->NUMCRI := TN3->TN3_NUMCRI
	   (cTRB)->NUMCRF := TN3->TN3_NUMCRF
	   If lGera_SA
	      (cTRB)->NUMSA  := TNF->TNF_NUMSA
	      (cTRB)->ITEMSA := TNF->TNF_ITEMSA
	   EndIf
	   (cTRB)->FILIAL    := xFilial("SRA",cCodFil)
	   (cTRB)->NOMFIL    := cNomFil
    EndIf
EndIf

Return

/*
===============================================================================================================================
Programa----------: RMDT004O
Autor-------------: TOTVS
Data da Criacao---: 20/09/2000
Descrição---------: Impressao do relatorio sintérico.
Parametros--------: cCodFil - Codigo da Filial 
                    cNomFil - Nome da Filial 
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RMDT004O()
Local lPrimvez := .T.

If lSigaMdtps
	
	DBSelectArea(cTRB)
	If MV_PAR12 == 1  //Matricula
		DBSetOrder(1)
	ElseIf MV_PAR12 == 2  //Nome Funcionario
		DBSetOrder(2)
	ElseIf MV_PAR12 == 3  //Cod. C. Custo
		DBSetOrder(3)
	ElseIf MV_PAR12 == 4  //Nome C. Custo
		DBSetOrder(4)
	EndIf
	
	DBGoTop()
	
	While !Eof()
		
		DBSelectArea("SA1")
		DBSetOrder(1)
		DBSeek(xFilial("SA1")+(cTRB)->CLIENT+(cTRB)->LOJA)
		
		CFUNC := (cTRB)->FUNCI
		nVolta := 0
		RMDT004S()
		@ Li,001 PSay Replicate("_",219)
		@ Li,220 PSay "|"
		RMDT004S()
		@ Li,000 PSay "|Funcionario.....:" // STR0010 
		@ Li,019 PSay CFUNC PICTURE "@!"
		@ Li,026 PSAY " - " + (cTRB)->NOME
		@ Li,127 PSay "RG.:" // STR0011 
		@ Li,132 PSay (cTRB)->RG PICTURE "@!"
		@ Li,220 PSay "|"
		lLinha := .F.
		lFirst := .T.
		
		RMDT004S()
		@ Li,000 PSay "|"
		@ Li,001 PSay Replicate("_",219)
		@ Li,220 PSay "|"
		RMDT004S()
		@ Li,000 Psay "|"
		@ Li,001 PSay "EPI" // STR0017     
		@ Li,017+nDist PSay "Nome do EPI" // STR0018
		@ Li,160+nDist PSay "Qtde" // STR0025 
		@ Li,181+nDist PSay "Num C.A." // STR0026
		@ Li,220 Psay "|"
		DBSelectArea(cTRB)
		While !Eof() .And. (cTRB)->FUNCI == CFUNC
			cCodNumEpi := (cTRB)->CODEPI
			cDescEpi := SubStr(AllTrim((cTRB)->DESEPI),1,80)
			nQuant := 0
			cCodNumCap := (cTRB)->NUMCAP

			DBSelectArea(cTRB)
 			While !Eof() .And. (cTRB)->FUNCI == CFUNC .And. (cTRB)->CODEPI + (cTRB)->NUMCAP == cCodNumEpi + cCodNumCap
 				nQuant += (cTRB)->QTDE
				DBSelectArea(cTRB)
				DBSkip()
				nVolta++	 			
	 		EndDo
			If lLinha .And. lFirst
				@ Li,220 Psay "|"
				RMDT004S()
				@ Li,000 PSay "|"
			EndIf
			If !lFirst
				RMDT004S()
				@ Li,000 PSay "|"
			EndIf
			lFirst := .F.
			@ Li,001 PSAY cCodNumEpi
			@ Li,017+nDist PSay cDescEpi PICTURE "@!"
			@ Li,158+nDist PSay nQuant  PICTURE "@E 999.99"
			If !Empty(cCodNumCap)
				@ Li,181+nDist PSay cCodNumCap
			EndIf
			If lLinha
				@ Li,220 Psay "|"
				RMDT004S()
				@ Li,000 Psay "|"
			EndIf
			nVolta++
			DBSelectArea(cTRB)
			DBSkip()
			@ Li,220 PSay "|"
		EndDo
		DBSkip(-1)
		
		RMDT004S()
		@ Li,000 PSay "|"
		@ Li,001 PSay Replicate("_",219)
		@ Li,220 PSay "|"
		RMDT004S()
		@ Li,000 PSay "|"
		@ Li,220 PSay "|"
		RMDT004S()
		@ Li,000 PSay "|       Data : ____/____/____" // STR0036 
		@ Li,220 PSay "|"
		RMDT004S()
		@ Li,000 PSay "|"
		@ Li,220 PSay "|"
		RMDT004S()
		@ Li,000 PSay "|       Assinatura: _______________________" // STR0037
		@ Li,127 PSay "Resp Empr: _______________________" // STR0088 
		@ Li,220 Psay "|"
		RMDT004S()
		@ Li,000 Psay "|"
		@ Li,220 Psay "|"
		RMDT004S()
		@ Li,000 PSay "|"
		@ Li,001 PSay Replicate("_",219)
		@ Li,220 PSay "|"
		LI := 80
		If MV_PAR11 == 2 .And. lPrimvez
			DBSelectArea(cTRB)
			DBSkip(-(nVolta-1))
			lPrimvez := .F.
		Else
			DBSelectArea(cTRB)
			DBSkip()
			lPrimvez := .T.
		EndIf
		
	EndDo
	
Else
	
	DBSelectArea(cTRB)
	If MV_PAR08 == 1  //Matricula
		DBSetOrder(1)
	ElseIf MV_PAR08 == 2  //Nome Funcionario
		DBSetOrder(2)
	ElseIf MV_PAR08 == 3  //Cod. C. Custo
		DBSetOrder(3)
	ElseIf MV_PAR08 == 4  //Nome C. Custo
		DBSetOrder(4)
	EndIf
	
	DBGoTop()
	
	While !Eof()
		
		CFUNC := (cTRB)->FUNCI
		nVolta := 0
		RMDT004S()
		@ Li,000 PSay " "+Replicate("_",219)
		RMDT004S()
		@ Li,000 PSay "|Funcionario.....:" // STR0010 
		@ Li,019 PSay CFUNC PICTURE "@!"
		@ Li,026 PSAY " - " + (cTRB)->NOME
		@ Li,127 PSay "RG.:" // STR0011 
		@ Li,132 PSay (cTRB)->RG PICTURE "@!"
		@ Li,220 PSay "|"
		
		lLinha := .F.
		lFirst := .T.
		
		RMDT004S()
		@ Li,000 PSay "|"
		@ Li,001 PSay Replicate("_",219)
		@ Li,220 PSay "|"
		RMDT004S()
		@ Li,000 Psay "|"
		@ Li,001 PSay "EPI" // STR0017     
		@ Li,017+nDist PSay "Nome do EPI" // STR0018 
		@ Li,160+nDist PSay "Qtde" // STR0025  
		@ Li,181+nDist PSay "Num C.A." // STR0026
		@ Li,220 Psay "|"
		RMDT004S()
		@ Li,000 Psay "|"
		DBSelectArea(cTRB)
		While !Eof() .And. (cTRB)->FUNCI == CFUNC
			cCodNumEpi := (cTRB)->CODEPI
			cDescEpi := SubStr(AllTrim((cTRB)->DESEPI),1,80)
			nQuant := 0
			cCodNumCap := (cTRB)->NUMCAP

			DBSelectArea(cTRB)
 			While !Eof() .And. (cTRB)->FUNCI == CFUNC .And. (cTRB)->CODEPI + (cTRB)->NUMCAP == cCodNumEpi + cCodNumCap
 				nQuant += (cTRB)->QTDE
				DBSelectArea(cTRB)
				DBSkip()
				nVolta++	 			
	 		EndDo
	 		
			If lLinha .And. lFirst
				@ Li,220 Psay "|"
				RMDT004S()
				@ Li,000 PSay "|"
			EndIf
			If !lFirst
				RMDT004S()
				@ Li,000 PSay "|"
			EndIf
			lFirst := .F.
			@ Li,001 PSAY cCodNumEpi
			@ Li,017+nDist PSay cDescEpi PICTURE "@!"
			@ Li,158+nDist PSay nQuant  PICTURE "@E 999.99"
			If !Empty(cCodNumCap)
				@ Li,181+nDist PSay cCodNumCap
			EndIf
			If lLinha
				@ Li,220 Psay "|"
				RMDT004S()
				@ Li,000 Psay "|"
			EndIf
			DBSelectArea(cTRB)
			@ Li,220 Psay "|"
		EndDo
		DBSkip(-1)
		
		RMDT004S()
		@ Li,000 PSay "|"
		@ Li,001 PSay Replicate("_",219)
		@ Li,220 PSay "|"
		RMDT004S()
		@ Li,000 PSay "|"
		@ Li,220 PSay "|"
		RMDT004S()
		@ Li,000 PSay "|       Data : ____/____/____" // STR0036 
		@ Li,220 PSay "|"
		RMDT004S()
		@ Li,000 PSay "|"
		@ Li,220 PSay "|"
		RMDT004S()
		@ Li,000 PSay "|       Assinatura: _______________________" // STR0037 
		@ Li,127 PSay "Resp Empr: _______________________" // STR0088 
		@ Li,220 Psay "|"
		RMDT004S()
		@ Li,000 Psay "|"
		@ Li,220 Psay "|"
		RMDT004S()
		@ Li,000 PSay "|"
		@ Li,001 PSay Replicate("_",219)
		@ Li,220 PSay "|"
		LI := 80
		If MV_PAR07 == 2 .And. lPrimvez
			DBSelectArea(cTRB)
			DBSkip(-(nVolta-1))
			lPrimvez := .F.
		Else
			DBSelectArea(cTRB)
			DBSkip()
			lPrimvez := .T.
		EndIf
		
	End
EndIf

Return

/*
===============================================================================================================================
Programa----------: RMDT004Q
Autor-------------: Julio de Paula Paz
Data da Criacao---: 10/11/2017
Descrição---------: Lê as quantidades de devolução de EPI na tabela TLW para impressão no relatório.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RMDT004Q()
Local _aRet := 0
Local _aOrd := SaveOrd({"TLW"})
Local _nRegAtu := TLW->(Recno())
Local _nQtdEntr, _nDtEntr

Begin Sequence
   _nQtdEntr := 0
   _nDtEntr  := CtoD("  /  /  ")
   
   TLW->(DBSetOrder(1)) // TLW_FILIAL+TLW_FORNEC+TLW_LOJA+TLW_CODEPI+TLW_NUMCAP+TLW_MAT+DToS(TLW_DTENTR)+TLW_HRENTR+DToS(TLW_DTDEVO)+TLW_HRDEVO  
   // TNF_FILIAL+TNF_FORNEC+TNF_LOJA+TNF_CODEPI+TNF_NUMCAP+TNF_MAT+DToS(TNF_DTENTR)+TNF_HRENTR 
   TLW->(DBSeek(TNF->(TNF_FILIAL+TNF_FORNEC+TNF_LOJA+TNF_CODEPI+TNF_NUMCAP+TNF_MAT+DToS(TNF_DTENTR)+TNF_HRENTR)))
   
   While ! TLW->(Eof()) .And. TLW->(TLW_FILIAL+TLW_FORNEC+TLW_LOJA+TLW_CODEPI+TLW_NUMCAP+TLW_MAT+DToS(TLW_DTENTR)+TLW_HRENTR) ==;
                                 TNF->(TNF_FILIAL+TNF_FORNEC+TNF_LOJA+TNF_CODEPI+TNF_NUMCAP+TNF_MAT+DToS(TNF_DTENTR)+TNF_HRENTR)
      _nQtdEntr := TLW->TLW_QTDEVO
      _nDtEntr  := TLW->TLW_DTDEVO
      
      TLW->(DBSkip())
   EndDo
   _aRet := {_nQtdEntr,_nDtEntr}

End Sequence

RestOrd(_aOrd)
TLW->(DBGoTo(_nRegAtu))

Return _aRet
