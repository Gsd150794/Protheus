/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Igor Melgaço  |11/11/2024| Chamado 49005. Ajustes para exibir descrição de abono
Igor Melgaço  |06/05/2025| Chamado 50525. Ajuste para remoção de diretório Local C:\SMARTCLIENT\.
Lucas Borges  |27/06/2025| Chamado 50617. Revisões diversas visando padronizar os fontes
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "PONR010.CH"
#Include "RPTDEF.CH"  
#Include "FWPrintSetup.ch" 

/*
===============================================================================================================================
Programa----------: RPON002
Autor-------------: TOTVS
Data da Criacao---: 07/04/1996
Descrição---------: Relatório de espelho de ponto
					  
					  Esse fonte é baseado no rdmake padrão da TOTVS com inclusão de personalizações
					  
					  Portanto, qualquer personalização nesse fonte deve ser precedida e terminada com comentário contendo a palavra
					  'ITALAC' de modo que possa ser localizado facilmente.
					  
					  Esse fonte também não deve ser 'normalizado' nos padrões internos de desenvolvimento pois  impossibilitaria
					  comparações com atualizações do mesmo liberadas pela TOTVS.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RPON002(lTerminal As Logical,cFilTerminal As Character,cMatTerminal As Character,cPerAponta As Character,;
						lPortal As Logical,aRetPortal As Array)

Local aOrdem		:= {STR0004 , STR0005 , STR0006 , STR0007, STR0038, STR0060, STR0061  } As Array// 'Matricula'###'Centro de Custo'###'Nome'###'Turno'###'C.Custo + Nome'###'Departamento'###'Departamento + Nome'
Local cHtml			:= '' As Character
Local cAviso		:= '' as Character
Local aFilesOpen	:= {"SP5", "SPN", "SP8", "SPG","SPB","SPL","SPC", "SPH", "SPF"} As Array
Local bCloseFiles	:= {|cFiles| If( Select(cFiles) > 0, (cFiles)->( DBCloseArea() ), NIL) } As Codeblock
Local oPrinter		:= Nil As Object
Local oSetup		:= Nil As Object
Local cPathTemp  	:= GetTempPath() As Character
Local cSession	 	:= GetPrinterSession() As Character
Local cDevice    	:= fwGetProfString(cSession,"PRINTTYPE","PDF",.T.) As Character
Local cDestino	 	:= "C:\" As Character
Local nFlags   	 	:= PD_ISTOTVSPRINTER + PD_DISABLEORIENTATION As Numeric
Local _oFile		:= Nil As Object

// Define Variaveis Private(Basicas)                            
Private nomeprog := 'RPON002' As Character//'PONR010'
Private nLastKey := 0 As Numeric
Private cPerg    := 'RPON002' As Character

// Define variaveis Private utilizadas no programa RDMAKE ImpEsp
Private aImp      := {} As Array
Private aTotais   := {} As Array
Private aAbonados := {} As Array
Private aAfast    := {} As Array
Private nImpHrs   := 0 As Numeric
Private _cdtinici := DToC(Date()) As Character
Private _choraini := Time() As Character

// Variaveis Utilizadas na funcao IMPR                          
Private Titulo   := OemToAnsi(STR0001 ) As Character// 'Espelho do Ponto'

// Define Variaveis Private(Programa)                           
Private dPerIni  := Ctod("//") As Date
Private dPerFim  := Ctod("//") As Date
Private cMenPad1 := Space(30) As Character
Private cMenPad2 := Space(19) As Character
Private cFilSPA	 := xFilial("SPA", SRA->RA_FILIAL) As Character
Private nOrdem   := 1 As Numeric
Private aInfo    := {} As Array
Private aTurnos  := {} As Array
Private nColunas := 0 As Numeric
Private aNaES	 := {} As Array
Private nCol	 := 0 As Numeric
Private nColTot	 := 0 As Numeric
Private nLinTot	 := 0 As Numeric
Private aMargRel := {} As Array
Private nLin	 := 0 As Numeric
Private nPxData	 :=	0 As Numeric
Private nPxSemana:= 0 As Numeric
Private nPxAbonos:= 0 As Numeric
Private nPxHe	 := 0 As Numeric
Private nPxFalta := 0 As Numeric
Private nPxObser := 0 As Numeric
Private lImpMarc := .T. As Logical
Private lCodeBar := .F. As Logical
Private lBigLine := .T. As Logical
Private _cSetorDe := "" As Character
Private _cSetorAte := "" As Character
Private _cRegraDe  := "" As Character
Private _cRegraAte := "" As Character
Private _nOrdemImp := 1 As Numeric
Private _nImpRef   := 0 As Numeric

DEFAULT lTerminal := .F.

#DEFINE Imp_Spool      	2
#DEFINE ALIGN_H_LEFT   	0
#DEFINE ALIGN_H_RIGHT  	1
#DEFINE ALIGN_H_CENTER 	2
#DEFINE ALIGN_V_CENTER 	0
#DEFINE ALIGN_V_TOP	   	1
#DEFINE ALIGN_V_BOTTON 	2
#DEFINE oFontT 			TFont():New( "Verdana", 09, 09, , .T., , , , .T., .F. )//Titulo
#DEFINE oFontP 			TFont():New( "Verdana", 09, 09, , .T., , , , .T., .F. )//Linhas
#DEFINE oFontM 			TFont():New( "Verdana", 08, 08, , .T., , , , .T., .F. )//Marcacoes
#DEFINE oFontO 			TFont():New( "Verdana", 08, 08, , .T., , , , .T., .F. )//Marcacoes
#DEFINE oFont06 		TFont():New( "Verdana", 06, 06, , .T., , , , .T., .F. )//CodeBar

lPortal   := If( lPortal == NIL , .F. , lPortal )   

// Parƒmetro MV_COLMARC										   
nColunas := SuperGetmv("MV_COLMARC")

If ( nColunas == NIL )
	Help("", 1, "MVCOLNCAD")
	Return( .F. )
EndIf

// O numero de colunas eh sempre aos pares					   
nColunas *= 2

// Envia controle para a funcao SETPRINT                        
If !( lTerminal )
	aDevice := {}
	// Define os Tipos de Impressao validos 
	aAdd(aDevice,"DISCO") 
	aAdd(aDevice,"SPOOL") 
	aAdd(aDevice,"EMAIL") 
	aAdd(aDevice,"EXCEL") 
	aAdd(aDevice,"HTML" ) 
	aAdd(aDevice,"PDF"  )  
	
	// Realiza as configuracoes necessarias para a impressao 
	nPrintType := aScan(aDevice,{|x| x == cDevice }) 
	nLocal     := If( fWGetProfString( cSession, "LOCAL", "SERVER", .T. ) == "SERVER", 1, 2 )                                                                                                                                                                                                                          
	
	oSetup := FWPrintSetup():New(nFlags, Titulo)
	oSetup:SetUserParms( {|| Pergunte(cPerg, .T.) } ) 
	oSetup:SetPropert(PD_PRINTTYPE   , nPrintType)
	oSetup:SetPropert(PD_ORIENTATION , 2) 
	oSetup:SetPropert(PD_DESTINATION , nLocal)
	oSetup:SetPropert(PD_MARGIN      , {10,10,10,10})
	oSetup:SetPropert(PD_PAPERSIZE   , 2)
	oSetup:SetPropert(PD_PREVIEW,.T.)
	oSetup:SetOrderParms(aOrdem,@nOrdem)
	
	If cDevice == "PDF"
		oSetup:aOptions[PD_VALUETYPE] := cDestino
	EndIf
	
	oPrinter      	 := FWMSPrinter():New( 'PONR010', IMP_PDF , .F., , .T., , oSetup,,.T. )
	If !(oSetup:Activate() == PD_OK)
		oPrinter:Deactivate() 
		Return
	EndIf
	// Indique o caminho onde será gravado o PDF
	If Upper(oPrinter:cPathPDF) == "C:\" .Or. Empty(oPrinter:cPathPDF)
	   oPrinter:cPathPDF := cPathTemp
	EndIf
	If oPrinter:nModalResult = 2//APERTOU O CANCELA
	   Return .F.
	EndIf

	oPrinter:SetResolution( 75 )
	
	oPrinter:SetLandscape()
	       
	oPrinter:SetPaperSize( oSetup:GetProperty( PD_PAPERSIZE ) )
	oPrinter:SetMargin(oSetup:GetProperty( PD_MARGIN )[1],oSetup:GetProperty( PD_MARGIN )[2],oSetup:GetProperty( PD_MARGIN )[3],oSetup:GetProperty( PD_MARGIN )[4])
	aMargRel := {oSetup:GetProperty( PD_MARGIN )[1],oSetup:GetProperty( PD_MARGIN )[2],oSetup:GetProperty( PD_MARGIN )[3],oSetup:GetProperty( PD_MARGIN )[4]}	
		
	oPrinter:nDevice := IMP_PDF

EndIf

// Verifica as perguntas selecionadas                           
If !(Pergunte( cPerg , .T. ))
	Return
EndIf

//Trata arquivo ponr010 antes do processamento
_oFile:= FWFileWriter():New(cPathTemp+"PONR010.PDF")
If _oFile:Exists()
	If FWAlertYesNo("Apagar arquivo "+cPathTemp+"ponr010.pdf?","RPON00201")
		If !_oFile:Erase()
			FWAlertWarning("Não foi possível apagar o arquivo "+cPathTemp+"ponr010.pdf, o relatório não será executado. Feche o arquivo e apague manualmente","RPON00202")
			Return
		EndIf
	Else
		FWAlertInfo("Selecionado não apagar o arquivo "+cPathTemp+"ponr010.pdf, o relatório não será executado. Feche o arquivo e apague manualmente","RPON00203")
		Return
	EndIf
EndIf

// Carregando variaveis MV_PAR?? para Variaveis do Sistema.     
FilialDe	:= If( !lTerminal , MV_PAR01, cFilTerminal )			//Filial  De
FilialAte	:= If( !lTerminal , MV_PAR02, cFilTerminal )			//Filial  Ate
CcDe		:= If( !lTerminal , MV_PAR03, SRA->RA_CC   )			//Centro de Custo De
CcAte		:= If( !lTerminal , MV_PAR04, SRA->RA_CC   )			//Centro de Custo Ate
TurDe		:= If( !lTerminal , MV_PAR05, SRA->RA_TNOTRAB)			//Turno De
TurAte		:= If( !lTerminal , MV_PAR06, SRA->RA_TNOTRAB)			//Turno Ate
MatDe		:= If( !lTerminal , MV_PAR07, cMatTerminal)				//Matricula De
MatAte		:= If( !lTerminal , MV_PAR08, cMatTerminal)				//Matricula Ate
NomDe		:= If( !lTerminal , MV_PAR09, SRA->RA_NOME)				//Nome De
NomAte		:= If( !lTerminal , MV_PAR10, SRA->RA_NOME)				//Nome Ate
cSit		:= If( !lTerminal , MV_PAR11, fSituacao( NIL , .F. ))	//Situacao
cCat		:= If( !lTerminal , MV_PAR12, fCategoria( NIL , .F. ))	//Categoria
nImpHrs		:= If( !lTerminal , MV_PAR13, 3 )						//Imprimir horas Calculadas/Inform/Ambas/NA
nImpAut		:= If( !lTerminal , MV_PAR14, 1 )						//Demonstrar horas Autoriz/Nao Autorizadas
nCopias		:= If( !lTerminal , If(MV_PAR15>0,MV_PAR15,1),1)		//N£mero de C¢pias
lSemMarc	:= If( !lTerminal , (MV_PAR16==1)	, .F. )				//Imprime para Funcion rios sem Marca‡oes
cMenPad1	:= If( !lTerminal , MV_PAR17, "" )						//Mensagem padr„o anterior a Assinatura
cMenPad2	:= If( !lTerminal , MV_PAR18, "" )						//Mens. padr„o anterior a Assinatura(Cont.)
dPerIni     := If( !lTerminal ,;
                    MV_PAR19,SToD( Subst( cPerAponta , 1 , 8 ) ))	//Data Contendo o Inicio do Periodo de Apontamento
dPerFim     := If( !lTerminal ,;
                    MV_PAR20,SToD( Subst( cPerAponta , 9 , 8 ) ))	//Data Contendo o Fim  do Periodo de Apontamento
lSexagenal	:= If( !lTerminal , (MV_PAR21==1), .T.  )				//Horas em  (Sexagenal/Centesimal)
lImpRes		:= If( !lTerminal , (MV_PAR22==1), .F.	)				//Imprime eventos a partir do resultado ?
lImpTroca   := If( !lTerminal , (MV_PAR23==1), .F.	)				//Imprime Descricao Troca de Turnos ou o Atual 
lImpExcecao := If( !lTerminal , (MV_PAR24==1), .F.	)				//Imprime Descricao da Excecao no Lugar da do Afastamento  
DeptoDe		:= If( !lTerminal , MV_PAR25, SRA->RA_DEPTO   )			//Departamento De
DeptoAte	:= If( !lTerminal , MV_PAR26, SRA->RA_DEPTO   )			//Departamento Ate
lImpMarc 	:= If( !lTerminal , MV_PAR27==1, .T.   )		 		//Imprime marcações? .T.
lCodeBar 	:= If( !lTerminal , MV_PAR28==1, .F.   ) 				//Imprime código de barras? .F.
lBigLine 	:= If( !lTerminal , MV_PAR29==1, .T.   ) 				//Destaca linhas? .T.
lImpBh 		:= If( !lTerminal , MV_PAR30==1, .F.   ) 				//Imprime banco de horas

_cSetorDe  := If( !lTerminal , MV_PAR31, "" )   // Filtro Setor Inicial
_cSetorAte := If( !lTerminal , MV_PAR32, "" )   // Filtro Setor Final
_cRegraDe  := If( !lTerminal , MV_PAR33, "" )   // Filtro Regra de Apontamento Inicial
_cRegraAte := If( !lTerminal , MV_PAR34, "" )   // Filtro Regra de Apontamento Final
_nOrdemImp := If( !lTerminal , MV_PAR35, "" )   // Ordem de Impressão do Relatório
_nImpRef   := If( !lTerminal , MV_PAR36, 1 )    // Imprime Refeições
// Redefine o Tamanho das Mensagens Padroes					   
cMenpad1 := If(Empty( cMenPad1 ) , Space( 30 ) , cMenPad1 )
cMenpad2 := If(Empty( cMenPad2 ) , Space( 19 ) , cMenPad2 )

Begin Sequence

	If ( lTerminal )
		//-- Verifica se foi possivel abrir os arquivos sem exclusividade
		If Pn090Open(@cHtml, @cAviso)
			cHtml := ""	
			cHtml := Pnr010Imp( NIL , lTerminal, lPortal, aRetPortal  )
		    //====================================================================
			// Apos a obtencao da consulta solicitada fecha os arquivos     
			// utilizados no fechamento mensal para abertura exclusiva      
			//====================================================================
		    Aeval(aFilesOpen, bCloseFiles)
		Else
		   cHtml := HtmlDefault( cAviso , cHtml )   
		EndIf    
	ElseIf !( nLastKey == 27 )
	
		If Pn090Open(@cHtml, @cAviso)

			If Empty( dPerIni ) .Or. Empty( dPerFim )
				Help(" ",1,"PONFORAPER" , , OemToAnsi( STR0039 ) , 5 , 0  )	//'Periodo de Apontamento Invalido.'
				Break
			EndIf
	
			If !( nLastKey == 27 )
	
				oSay := nil
				FWMsgRun(, {|oSay| Pnr010Imp(@lEnd, lTerminal, ,,oPrinter, oSay ) }, "Processando", Titulo)
	
			EndIf
		Else
			MsgStop( cHtml, cAviso )
			cHtml := ""
		EndIf
	
	EndIf
	
End Sequence

If !lTerminal
	oPrinter:Preview()
EndIf
	
Return( cHtml )

/*
===============================================================================================================================
Programa----------: Pnr010Imp
Autor-------------: TOTVS
Data da Criacao---: 07/04/1996
Descrição---------: Relatório de espelho de ponto - Impressão
Parametros--------:  lEnd = Ação do Codelock  
                     lTerminal
                     lPortal
                     aRetPortal
                     oPrinter
                     osay
Retorno-----------: cHtml
===============================================================================================================================
*/
Static Function Pnr010Imp(lEnd As Logical,lTerminal As Logical,lPortal As Logical,aRetPortal As Array,oPrinter As Object,osay As Object)

Local aAbonosPer	:= {} As Array
Local cOrdem		:= "" As Character
Local cWhere		:= "" As Character
Local cSituacao		:= "" As Character
Local cCategoria	:= "" As Character
Local cLastFil		:= "__cLastFil__" As Character
Local cAcessaSRA	:= &("{ || " + ChkRH("PONR010","SRA","2") + "}") As Character
Local cSeq			:= "" As Character
Local cTurno		:= "" As Character
Local cHtml			:= "" As Character
Local cAliasSRA		:= GetNextAlias() As Character
Local cAliasQTD		:= GetNextAlias() As Character
Local lSPJExclu		:= !Empty( xFilial("SPJ") ) As Logical
Local lSP9Exclu		:= !Empty( xFilial("SP9") ) As Logical
Local nCount		:= 0.00 As Numeric
Local nX			:= 0.00 As Numeric
Local lMvAbosEve	:= .F. As Logical
Local lMvSubAbAp	:= .F. As Logical
Local _nni 			:= 0 As Numeric
Local _nsoma        := 1 As Numeric

Private aFuncFunc  := {Space(1), Space(1), Space(1), Space(1), Space(1), Space(1)} As Array
Private aMarcacoes := {} As Array
Private aTabPadrao := {} As Array
Private aTabCalend := {} As Array
Private aPeriodos  := {} As Array
Private aId		   := {} As Array
Private aResult	   := {} As Array
Private aResultPDI := {} As Array
Private aBoxSPC	   := LoadX3Box("PC_TPMARCA") As Array
Private aBoxSPH	   := LoadX3Box("PH_TPMARCA") As Array
Private cCodeBar   := "" As Character
Private dIniCale   := Ctod("//") As Date //-- Data Inicial a considerar para o Calendario
Private dFimCale   := Ctod("//") As Date //-- Data Final a considerar para o calendario
Private dMarcIni   := Ctod("//") As Date //-- Data Inicial a Considerar para Recuperar as Marcacoes
Private dMarcFim   := Ctod("//") As Date //-- Data Final a Considerar para Recuperar as Marcacoes
Private dIniPonMes := Ctod("//") As Date //-- Data Inicial do Periodo em Aberto 
Private dFimPonMes := Ctod("//") As Date //-- Data Final do Periodo em Aberto 
Private lImpAcum   := .F. As Logical

//====================================================================
// Como a Cada Periodo Lido reinicializamos as Datas Inicial e 
// Final preservamos-as nas variaveis: dCaleIni e dCaleFim.		   
//====================================================================
dIniCale   := dPerIni   //-- Data Inicial a considerar para o Calendario
dFimCale   := dPerFim   //-- Data Final a considerar para o calendario

For nX:=1 to Len(cSit)
	If Subs(cSit,nX,1) <> "*"
		cSituacao += "'"+Subs(cSit,nX,1)+"'"
		If ( nX+1 ) <= Len(cSit)
			cSituacao += "," 
		EndIf
	EndIf
Next nX

If !Empty(cSituacao) .And. Subs(cSituacao,Len(cSituacao),1) == ","
	cSituacao := Subs(cSituacao,1,Len(cSituacao)-1)
EndIf     

For nX:=1 to Len(cCat)
	If Subs(cCat,nX,1) <> "*"
		cCategoria += "'"+Subs(cCat,nX,1)+"'"
		If ( nX+1 ) <= Len(cCat)
			cCategoria += "," 
		EndIf
	EndIf
Next nX

If !Empty(cCategoria) .And. Subs(cCategoria,Len(cCategoria),1) == ","
	cCategoria := Subs(cCategoria,1,Len(cCategoria)-1)
EndIf 

// Inicializa Variaveis Static								   
( CarExtAut() , RstGetTabExtra() )

//--Seleciona funcionários de acordo com filtros
cWhere += "%"
cWhere += "SRA.RA_FILIAL >= '" + FilialDe + "' AND "
cWhere += "SRA.RA_FILIAL <= '" + FilialAte + "' AND "
cWhere += "SRA.RA_CC >= '" + CCDe + "' AND "
cWhere += "SRA.RA_CC <= '" + CCAte + "' AND "
cWhere += "SRA.RA_TNOTRAB >= '" + TurDe + "' AND "
cWhere += "SRA.RA_TNOTRAB <= '" + TurAte + "' AND "
cWhere += "SRA.RA_MAT >= '" + MatDe + "' AND "
cWhere += "SRA.RA_MAT <= '" + MatAte + "' AND "

cWhere += "((SRA.RA_NOME >= '" + NomDe  + "' AND "
cWhere += "  SRA.RA_NOME <= '" + NomAte + "') OR "
cWhere += "(SRA.RA_NSOCIAL >= '" + NomDe  + "' AND "
cWhere += " SRA.RA_NSOCIAL <= '" + NomAte + "')) AND "

cWhere += "SRA.RA_DEPTO >= '" + DeptoDe + "' AND "
cWhere += "SRA.RA_DEPTO <= '" + DeptoAte + "'"
If !Empty( cSituacao )
	cWhere += " AND SRA.RA_SITFOLH IN ( " + cSituacao + ") " 
EndIf
If !Empty(cCategoria)
	cWhere += " AND SRA.RA_CATFUNC IN ( " + cCategoria + ") "
EndIf

If !Empty(_cSetorDe)  //:= If( !lTerminal , MV_PAR31, "" )   // Filtro Setor Inicial 
   cWhere += " AND SRA.RA_I_SETOR >= '" + _cSetorDe + "' "
EndIf

If !Empty(_cSetorAte) //:= If( !lTerminal , MV_PAR32, "" )   // Filtro Setor Final
   cWhere += " AND SRA.RA_I_SETOR <= '" + _cSetorAte + "' "
EndIf

If !Empty(_cRegraDe)  //:= If( !lTerminal , MV_PAR33, "" )   // Filtro Regra de Apontamento Inicial
   cWhere += " AND SRA.RA_REGRA >= '" + _cRegraDe + "' "
EndIf

If !Empty(_cRegraAte) //:= If( !lTerminal , MV_PAR34, "" )   // Filtro Regra de Apontamento Final
   cWhere += " AND SRA.RA_REGRA <= '" + _cRegraAte + "' "
EndIf

cWhere += " AND SRA.D_E_L_E_T_ = ' ' " 
cWhere += "%"

If _nOrdemImp == 1 // Nome
   cOrdem := "%SRA.RA_FILIAL, SRA.RA_NOME, SRA.RA_MAT%"   
ElseIf _nOrdemImp == 2 // Matricula
   cOrdem := "%SRA.RA_FILIAL, SRA.RA_MAT%"
ElseIf _nOrdemImp == 3 // Setor
   cOrdem := "%SRA.RA_FILIAL, SRA.RA_I_SETOR, SRA.RA_NOME%"
ElseIf _nOrdemImp == 4 // Turno
   cOrdem := "%SRA.RA_FILIAL, SRA.RA_TNOTRAB, SRA.RA_NOME%"   
EndIf

BeginSql Alias cAliasSRA

 	SELECT SRA.RA_FILIAL, SRA.RA_MAT
	FROM 
		%Table:SRA% SRA
	WHERE %Exp:cWhere%
	ORDER BY %Exp:cOrdem%	

EndSql 	

// Inicializa R‚gua de Impress„o								   
If !( lTerminal )
	BeginSql Alias cAliasQTD
	
	 	SELECT Count(*) AS QTDREG
		FROM 
			%Table:SRA% SRA
		WHERE %Exp:cWhere%
	EndSql
	 	
	_nni :=  (cAliasQTD)->QTDREG 
	(cAliasQTD)->(DBCloseArea())
EndIf

If lCodeBar
	DBSelectArea("RS4")
	RS4->(DBSetOrder(1))
EndIf

DBSelectArea('SRA')
SRA->( DBSetOrder( 1 ) )	

// Processa o Cadastro de Funcionarios						   
While (cAliasSRA)->( !Eof() )

	//Posiciona no funcionário atual
	SRA->(DBSeek((cAliasSRA)->RA_FILIAL + (cAliasSRA)->RA_MAT))
	
	// So Faz Validacoes Quando nao For Terminal					   
	If !( lTerminal ) 
		If ValType(osay) = "O"
			osay:cCaption := ("Processando relatório  - Registro " + StrZero(_nsoma,6) + " de " + StrZero(_nni,6) + "...")
			ProcessMessages()
			_nsoma++
 		EndIf
		
		If ( lEnd )
			Exit
		EndIf

		// Consiste controle de acessos e filiais validas               
		If SRA->( !( RA_FILIAL $ fValidFil() ) .Or. !Eval( cAcessaSRA ) )
			(cAliasSRA)->( DBSkip() )
			Loop
		EndIf

		//====================================================================
		// Consiste a data de Demiss„o								   
		// Se o Funcionario Foi Demitido Anteriormente ao Inicio do Perio
		// do Solicitado Desconsidera-o								   
		//====================================================================
		If !Empty(SRA->RA_DEMISSA) .And. ( SRA->RA_DEMISSA < dIniCale )
			(cAliasSRA)->( DBSkip() )
			Loop
		EndIf

	EndIf

    // Verifica a Troca de Filial           						  
	If !( SRA->RA_FILIAL == cLastFil )

		// Alimenta as variaveis com o conteudo dos MV_'S correspondetes³
		lMvAbosEve	:= RPON002MV("MV_ABOSEVE", cLastFil)
		
	    lMvSubAbAp  := RPON002MV("MV_SUBABAP", cLastFil)
	    
		// Atualiza a Filial Corrente           						  
		cLastFil := SRA->RA_FILIAL
		
		// Carrega periodo de Apontamento Aberto						  
		If !CheckPonMes( @dPerIni , @dPerFim , .F. , .T. , .F. , cLastFil )
			Exit
		EndIf

		// Obtem datas do Periodo em Aberto							  
		GetPonMesDat( @dIniPonMes , @dFimPonMes , cLastFil )
		
		// Atualiza o Array de Informa‡”es sobre a Empresa.			  
		aInfo := {}
		fInfo( @aInfo , cLastFil )
	
		// Carrega as Tabelas de Horario Padrao						  
		If ( lSPJExclu .Or. Empty( aTabPadrao ) )
			aTabPadrao := {}
			fTabTurno( @aTabPadrao , If( lSPJExclu , cLastFil , NIL ) )
		EndIf

		// Carrega TODOS os Eventos da Filial						  
		If ( Empty( aId ) .Or. ( lSP9Exclu ) )
			aId := {}
			CarId( fFilFunc("SP9") , @aId , "*" )
		EndIf
	EndIf

	// Retorna Periodos de Apontamentos Selecionados				  
	If ( lTerminal )
		dPerIni	:= dIniCale
		dPerFim := dFimCale
	EndIf
	
	aPeriodos := Monta_per( dIniCale , dFimCale , cLastFil , SRA->RA_MAT , dPerIni , dPerFim )

	// Corre Todos os Periodos 									  
	naPeriodos := Len( aPeriodos )
	For nX := 1 To naPeriodos

   		//====================================================================
		// Reinicializa as Datas Inicial e Final a cada Periodo Lido.	  
		// Os Valores de dPerIni e dPerFim foram preservados nas   varia
		// veis: dCaleIni e dCaleFim.									  
		//====================================================================
        dPerIni		:= aPeriodos[ nX , 1 ]
        dPerFim		:= aPeriodos[ nX , 2 ] 

		// Obtem as Datas para Recuperacao das Marcacoes				  
        dMarcIni	:= aPeriodos[ nX , 3 ]
        dMarcFim	:= aPeriodos[ nX , 4 ]

		// Verifica se Impressao eh de Acumulado						  
		lImpAcum := ( dPerFim < dIniPonMes )
		   
		// Retorna Turno/Sequencia das Marca‡”es Acumuladas			 
		If ( lImpAcum )
			If SPF->( DBSeek( SRA->( RA_FILIAL + RA_MAT ) + DToS( dPerIni) ) ) .And. !Empty(SPF->PF_SEQUEPA)
				cTurno	:= SPF->PF_TURNOPA
				cSeq	:= SPF->PF_SEQUEPA
			Else
				// Tenta Achar a Sequencia Inicial utilizando RetSeq()
				If !RetSeq(cSeq,@cTurno,dPerIni,dPerFim,dDataBase,aTabPadrao,@cSeq) .Or. Empty( cSeq )
					// Tenta Achar a Sequencia Inicial utilizando fQualSeq()		  
					cSeq := fQualSeq( NIL , aTabPadrao , dPerIni , @cTurno )
				EndIf
			EndIf

			If ( Empty(cTurno) )
				SPF->( DBSeek( SRA->( RA_FILIAL + RA_MAT ) ) )
				While	( !Eof() ) .AND.;
						 	( SRA->RA_FILIAL + SRA->RA_MAT == SPF->PF_FILIAL + SPF->PF_MAT )
					If ( SPF->PF_DATA >= dPerIni .And. SPF->PF_DATA <= dPerFim )						
						cTurno	:= SPF->PF_TURNOPA
						cSeq	:= SPF->PF_SEQUEPA
						Exit
					Else
						SPF->( DBSkip() )
					EndIf
				EndDo
			EndIf

		Else
			// Considera a Sequencia e Turno do Cadastro            		  
			cTurno	:= SRA->RA_TNOTRAB
			cSeq	:= SRA->RA_SEQTURN  
		EndIf
		
		// Obtem Codigo e Descricao da Funcao do Trabalhador na Epoca   
		fBuscaCC(dMarcFim, @aFuncFunc[1], @aFuncFunc[2], Nil, .F. , .T.  ) 
		aFuncFunc[2]:= SubStr(aFuncFunc[2], 1, 25)
		fBuscaFunc(dMarcFim, @aFuncFunc[3], @aFuncFunc[4],@aFuncFunc[6],.T. )
		If Empty(aFuncFunc[6])
			aFuncFunc[6] := DescCateg(SRA->RA_CATFUNC , 25)
		EndIf	

	    //====================================================================
		// Carrega Arrays com as Marca‡”es do Periodo (aMarcacoes), com³
		// o Calendario de Marca‡”es do Periodo (aTabCalend) e com    as³	
		// Trocas de Turno do Funcionario (aTurnos)					  ³	
		//====================================================================
		( aMarcacoes := {} , aTabCalend := {} , aTurnos := {} )
		
		If lImpMarc   
		    //====================================================================
			// Importante: 												  
			// O periodo fornecido abaixo para recuperar as marcacoes   cor
			// respondente ao periodo de apontamentoo Calendario de 	 Marca	
			// ‡”es do Periodo ( aTabCalend ) e com  as Trocas de Turno  do	
			// Funcionario ( aTurnos ) integral afim de criar o  calendario	
			// com as ordens correspondentes as gravadas nas marcacoes	  	
			//====================================================================
			If !GetMarcacoes(	@aMarcacoes					,;	//Marcacoes dos Funcionarios
								@aTabCalend					,;	//Calendario de Marcacoes
								@aTabPadrao					,;	//Tabela Padrao
								@aTurnos					,;	//Turnos de Trabalho
								dPerIni 					,;	//Periodo Inicial
								dPerFim						,;	//Periodo Final
								SRA->RA_FILIAL				,;	//Filial
								SRA->RA_MAT					,;	//Matricula
								cTurno						,;	//Turno
								cSeq						,;	//Sequencia de Turno
								SRA->RA_CC					,;	//Centro de Custo
								If(lImpAcum,"SPG","SP8")	,;	//Alias para Carga das Marcacoes
								NIL							,;	//Se carrega Recno em aMarcacoes
								.T.							,;	//Se considera Apenas Ordenadas
							    .T.    						,;	//Se Verifica as Folgas Automaticas
							  	.F.    			 			 ;	//Se Grava Evento de Folga Automatica Periodo Anterior
						 )
				Loop
			EndIf
		EndIf					 
	   	   
		// Reinicializa os Arrays aToais e aAbonados					  
		( aTotais := {} , aAbonados := {} )
		
		//Reinicializa array
		aAfast := {}

		// Carrega os Abonos Conforme Periodo       					  
		If 	lImpMarc
			fAbonosPer( @aAbonosPer , dPerIni , dPerFim , cLastFil , SRA->RA_MAT )
		EndIf

		// Carrega os Totais de Horas e Abonos.						  
		If 	lImpMarc	
			CarAboTot( @aTotais , @aAbonados , aAbonosPer, lMvAbosEve, lMvSubAbAp )
		EndIf
	
	    //====================================================================
		// Carrega o Array a ser utilizado na Impress„o.				  
		// aPeriodos[nX,3] --> Inicio do Periodo para considerar as  mar
		//                     cacoes e tabela						  
		// aPeriodos[nX,4] --> Fim do Periodo para considerar as   marca
		//                     coes e tabela							  
		//====================================================================
		If ( !fMontaAimp( aTabCalend, aMarcacoes, @aImp,dMarcIni,dMarcFim, lTerminal, lImpAcum) .And. !( lSemMarc ) )
			Loop
		EndIf

		// Carrega a situacao e os Afastamentos.			              
		Pnr010Afas( dMarcIni, dMarcFim, @aAfast )

		// Imprime o Espelho para um Funcionario.						  
		For nCount := 1 To nCopias
			If !( lTerminal )
				oPrinter:StartPage()
				If lCodeBar
					cCodeBar := cEmpAnt + SRA->RA_FILIAL + SRA->RA_MAT + DToS(dPerIni) + DToS(dPerFim) + DToS(dDataBase) + StrTran(Time(),":","")
				EndIf
				fImpFun( aImp , nColunas, ,oPrinter )
				If lCodeBar //Grava o código de barras gerado na tabela RS4
					RecLock("RS4",.T.)
					RS4->RS4_FILIAL := SRA->RA_FILIAL
					RS4->RS4_MAT	:= SRA->RA_MAT
					RS4->RS4_PER	:= DToS(dPerIni) + DToS(dPerFim) 
					RS4->RS4_DATAI	:= dPerIni
					RS4->RS4_DATAF	:= dPerFim
					RS4->RS4_CODEBA	:= cCodeBar
					RS4->RS4_STATUS	:= "2" //Pendente
					MSUnLock()
				EndIf
				oPrinter:EndPage()				
			Else
				If lPortal					
					aRetPortal  := aClone(aImp)
				Else
					cHtml := fImpFun( aImp , nColunas , lTerminal )
				EndIf
		    EndIf		    
		Next nCount
	
		// Reinicializa Variaveis										  
		aImp      := {}
		aTotais   := {}
		aAbonados := {}
		
	Next nX

    (cAliasSRA)->( DBSkip() )

End While

(cAliasSRA)->(DBCloseArea())

Return( cHtml )

/*
===============================================================================================================================
Programa----------: Pnr010Imp
Autor-------------: J.Ricardo
Data da Criacao---: 09/04/1996
Descrição---------: Imprime o espelho do ponto do funcionario
Parametros--------:  aImp 
                     nColunas 
                     lTerminal
                     oPrinter
Retorno-----------: cHtml
===============================================================================================================================
*/
Static Function fImpFun(aImp As Array,nColunas As Numeric,lTerminal As Logical,oPrinter As Object)

Local cHtml			:= "" As Character
Local cOcorr		:= "" As Character
Local cAbHora		:= "" As Character
Local lZebrado		:= .F. As Logical
Local nX        	:= 0.00 As Numeric
Local nY        	:= 0.00 As Numeric
Local nColMarc  	:= 0.00 As Numeric
Local nTamLin   	:= 0.00 As Numeric
Local nMin			:= 0.00 As Numeric
Local nLenImp		:= 0.00 As Numeric
Local nLenImpnX		:= 0.00 As Numeric
Local nTamAuxlin	:= 0.00 As Numeric
Local nSaldoAnt		:= 0.00 As Numeric
Local nSaldoAtu		:= 0.00 As Numeric
Local nCredito		:= 0.00 As Numeric
Local nDebito		:= 0.00 As Numeric
Local nAbHora		:= 0 As Numeric
Local nPosES		:= 0 As Numeric
Local nValAux		:= 0 As Numeric
Local nContEve		:= 0 As Numeric
Local oBrushC	    := TBrush():New( ,  RGB(228, 228, 228)  ) As Object
Local oBrushI	    := TBrush():New( ,  RGB(242, 242, 242)  ) As Object
Local lBrush		:= .F. As Logical
Local _nI			:= 0 As Numeric
Local _nJ			:= 0 As Numeric
Local _dDataInic	:= CtoD('//') As Date

//-- Define o tamanho da linha com base no MV_ColMarc.
aEval(aImp, { |x| nColMarc := If(Len(x)-3>nColMarc, Len(x)-3, nColMarc) } )
nColMarc += If(nColMarc%2 == 0, 0, 1)
 
//-- Calcula a Maior das Qtdes de Colunas existentes
nColunas := Max(nColunas, nColMarc)

//-- Define configura‡”es da impress„o
nTamAuxLin	:= 19+(nColunas*6)+50
nTamLin    	:= If(nTamAuxLin <= 80,80,If(nTamAuxLin<=132,132,220))

If ( lTerminal )
	// Inicio da Estrutura do Codigo HTML						   
	cHtml += HtmlProcId() + CRLF
	cHtml += '<html>'  + CRLF
	cHtml += 	'<head>'  + CRLF
	cHtml += 		'<title>RH Online</title>'  + CRLF
	cHtml +=		'<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">'  + CRLF
	cHtml +=		'<link rel="stylesheet" href="css/rhonline.css" Type="text/css">'  + CRLF
	cHtml +=	'</head>'  + CRLF
	cHtml +=	'<body bgcolor="#FFFFFF" text="#000000">' + CRLF
	cHtml +=		'<table width="515" border="0" cellspacing="0" cellpadding="0">'  + CRLF
  	cHtml +=			'<tr>'  + CRLF
    cHtml +=				'<td class="titulo">'  + CRLF
    cHtml +=					'<p>' + CRLF
    cHtml +=						'<img src="'+TcfRetDirImg()+'/icone_titulo.gif" width="7" height="9">' + CRLF
    cHtml +=							'<span class="titulo_opcao">' + CRLF
    cHtml +=								STR0040 + CRLF	//'Consultar Marca&ccedil;&otilde;es'
    cHtml +=							'</span>' + CRLF
    cHtml +=							'<br><br>' + CRLF
	cHtml +=					'</p>' + CRLF
	cHtml +=				'</td>' + CRLF
  	cHtml +=			'</tr>' + CRLF
  	cHtml +=			'<tr>' + CRLF
    cHtml +=				'<td>' + CRLF
    cHtml +=					'<table width="515" border="0" cellspacing="0" cellpadding="0">' + CRLF
    cHtml +=						'<tr>' + CRLF
    cHtml +=							'<td background="'+TcfRetDirImg()+'/tabela_conteudo_1.gif" width="10">&nbsp;</td>' + CRLF
    cHtml +=							'<td class="titulo" width="498">' + CRLF
    cHtml +=								'<table width="498" border="0" cellspacing="2" cellpadding="1">' + CRLF
	cHtml += Imp_Cabec( nTamLin , nColunas , lTerminal )
Else
	//-- Imprime Cabecalho Especifico.
	Imp_Cabec( nTamLin , nColunas ,  lTerminal, 1, oPrinter )
EndIf

//-- Imprime Marcações
nLenImp := Len(aImp)
For nX := 1 To nLenImp
	If !( lTerminal )
		nLin += 12
		
		If nLin > nLinTot - 40
			fImpSign(oPrinter)
			oPrinter:EndPage()
			oPrinter:StartPage()
			Imp_Cabec( nTamLin , nColunas ,  lTerminal, 1, oPrinter )
		EndIf
	
		oPrinter:Box( nLin, nCol	, nLin+13, nColTot, "-6" )			// Caixa da linha total
		
		If lBigLine .And. nX%2 == 0 //Pinta somente as linhas pares
			oPrinter:Fillrect( {nLin+1, nCol+1, nLin+12, nColTot-1 }, oBrushI, "-2") // Quadro na Cor Cinza
		EndIf
		
		oPrinter:Line( nLin, nPxData	, nLin+13, nPxData	, 0 , "-6") 	// Linha Pos Data

		oPrinter:SayAlign(nLin,nCol+2,DToC(aImp[nX,1]),oFontM,500,100,,ALIGN_H_LEFT)
		oPrinter:SayAlign(nLin,nPxData+2,DiaSemana(aImp[nX,1],8),oFontM,nPxSemana-nPxData,100,,ALIGN_H_LEFT)
		
		nMin := Len(aImp[nX])
				
		If Len(aImp[nX]) >= 4 .Or. !lImpMarc
			For nPosES := 1 to Len(aNaES)
				oPrinter:Line( nLin, aNaES[nPosES]-6, nLin+13, aNaES[nPosES]-6, 0 , "-6")	
				nY := nPosES + 3
				If lImpMarc .And. nY <= nMin
					oPrinter:SayAlign(nLin,aNaES[nPosES]+2,SubStr(aImp[nX,nY],1,30),oFontM,500,100,,ALIGN_H_LEFT)
					oPrinter:SayAlign(nLin+5,aNaES[nPosES]+2,SubStr(aImp[nX,nY],30,60),oFontM,500,100,,ALIGN_H_LEFT)
				EndIf
			Next nPosES
		Else
			oPrinter:Line( nLin, aNaES[1]-6, nLin+13, aNaES[1]-6, 0 , "-6")
			oPrinter:SayAlign(nLin,aNaES[1],aImp[nX,2],oFontM,Len(aNaES)*40,100,,ALIGN_H_CENTER)
		EndIf
	        
	    // Localiza e imprime o turno para data	
		//==============================================================================
		// O conteúdo do array aTabCalend pode ser dado através do link: 
		// http://tdn.totvs.com/pages/releaseview.action?pageId=6082431 
		//==============================================================================
		    
		_nI := aScan(aTabCalend,{|x| x[48] ==  aImp[nX,1]})
		    
		If _nI > 0
	       _nJ := _nI
	    Else	    
		   _nJ := 1
		EndIf
		    
		_dDataInic :=  aTabCalend[_nJ,48]
		cturno := ""
		For _nI := _nJ To Len(aTabCalend)
            If _dDataInic <>  aTabCalend[_nI,48]
               Exit		        
		    EndIf

		    If aTabCalend[_nI,3] > 0
		      cturno += SubStr(StrZero((aTabCalend[_nI,3]*100),4),1,2) + ":" + SubStr(StrZero((aTabCalend[_nI,3]*100),4),3,2) + " "
		    EndIf
		Next _nI
		    
        oPrinter:SayAlign(nLin,nPxData+40,cTurno,oFont06,500,100,,ALIGN_H_LEFT)
		oPrinter:Line( nLin, nPxAbonos-6, nLin+13	, nPxAbonos-6, 0 , "-6")
		oPrinter:Line( nLin, nPxHE-6	, nLin+13	, nPxHE-6, 0 , "-6")
		oPrinter:Line( nLin, nPxFalta-6	, nLin+13	, nPxFalta-6, 0 , "-6")
		oPrinter:Line( nLin, nPxObser	, nLin+13	, nPxObser, 0 , "-6")	
		oPrinter:Line( nLin, nPxData+36  	, nLin+13	, nPxData+36, 0 , "-6")	
		
		If lImpMarc //Imprime abonos,He,Faltas,adicionais apenas se For para imprimir marcações.
			If ValType(aImp[nX,3]) == "A"
				oPrinter:SayAlign(nLin,nPxAbonos+2,aImp[nX,3,2],oFontM,500,100,,ALIGN_H_LEFT)
				If Len(AllTrim(aImp[nX,3,1])) < 20
					oPrinter:SayAlign(nLin,nPxObser+2,aImp[nX,3,1],oFontM,500,100,,ALIGN_H_LEFT)
				Else	
					oPrinter:SayAlign(nLin,nPxObser+2,SubStr(aImp[nX,3,1],1,24),oFontO,500,100,,ALIGN_H_LEFT)     
					//oPrinter:SayAlign(nLin+5,nPxObser+2,SubStr(aImp[nX,3,1],25,24),oFontO,500,100,,ALIGN_H_LEFT)  // Imprimir apenas os 24 primeiros digitos.
				EndIf
			Else
				If Len(AllTrim(aImp[nX,3])) < 20
					oPrinter:SayAlign(nLin,nPxObser+2,aImp[nX,3],oFontM,500,100,,ALIGN_H_LEFT)
				Else
					oPrinter:SayAlign(nLin,nPxObser+2,SubStr(aImp[nX,3],1,24),oFontO,500,100,,ALIGN_H_LEFT)
					//oPrinter:SayAlign(nLin+5,nPxObser+2,SubStr(aImp[nX,3],25,24),oFontO,500,100,,ALIGN_H_LEFT)  // Imprimir apenas os 24 primeiros digitos.
				EndIf
			EndIf
         
         If Len(aResultPDI) > 0
			   cObs := RPON002OBS(aImp[nX,1])
            If Empty(AllTrim(aImp[nX,3])) .And. !Empty(cObs)
               oPrinter:SayAlign(nLin,nPxObser+2,cObs,oFontO,500,100,,ALIGN_H_LEFT)
            EndIf
         EndIf

			If Len(aResult) > 0
				nValAux := 0
				Aeval(aResult, {|x| If( x[1] == DToS(aImp[nX,1]) .And. x[2] == "1", nValAux := __TimeSum(nValAux,x[3]),Nil )} )
				If nValAux > 0
					oPrinter:SayAlign(nLin,nPxHE+2,StrTran(StrZero(nValAux,5,2),'.',':'),oFontM,500,100,,ALIGN_H_LEFT)
					nValAux := 0
				EndIf
				//Apenas gero as horas de Absenteismo na ultima linha do Dia.
				If nX == Len(aImp) .Or. aScan(aImp,{|x| x[1] == aImp[nX,1]},nX + 1) == 0
					Aeval(aResult, {|x| If( x[1] == DToS(aImp[nX,1]) .And. x[2] =="2", nValAux := __TimeSum(nValAux,x[3]),Nil )} )
					If nValAux > 0
						oPrinter:SayAlign(nLin,nPxFalta+2,StrTran(StrZero(nValAux,5,2),'.',':'),oFontM,500,100,,ALIGN_H_LEFT)
						nValAux := 0
					EndIf
				EndIf
			EndIf
		EndIf							                                                                   
	Else
		// Detalhes do Codigo HTML          							   
		If ( lZebrado := ( nX%2 == 0.00 ) )
			cHtml += '<tr bgcolor="#FAFBFC">' + CRLF
			cHtml += 	'<td class="dados_2" bgcolor="#FAFBFC" nowrap><div align="center">' + CRLF
			cHtml += 		DToC(aImp[nX,1]) + CRLF
			cHtml += 	'</td>' + CRLF
			cHtml += 	'<td class="dados_2" bgcolor="#FAFBFC" nowrap><div align="left">' + CRLF
			cHtml +=		DiaSemana(aImp[nX,1]) + CRLF
			cHtml += 	'</td>' + CRLF
		Else
			cHtml += '<tr>' + CRLF
			cHtml += 	'<td class="dados_2" nowrap><div align="center">' + CRLF
			cHtml += 		DToC(aImp[nX,1]) + CRLF
			cHtml += 	'</td>' + CRLF
			cHtml += 	'<td class="dados_2" nowrap><div align="left">' + CRLF
			cHtml +=		DiaSemana(aImp[nX,1]) + CRLF
			cHtml += 	'</td>' + CRLF
		EndIf
		If ( nLenImpnX := Len(aImp[nX]) ) < ( ( nColunas + nLenImpnX ) - 1 )
			For nY := Len(aImp[nX]) To ( ( nColunas + 3 ) - 1 )
				aAdd(aImp[nX] , Space(05) )
			Next nY
		EndIf
		nLenImpnX := Len(aImp[nX])
		For nY := 4 To nLenImpnX
			If ( lZebrado )
				cHtml += 	'<td class="dados_2" bgcolor="#FAFBFC" nowrap><div align="center">' + CRLF
				cHtml += 		aImp[nX,nY] + CRLF
				cHtml += 	'</td>' + CRLF
			Else
				cHtml += 	'<td class="dados_2" nowrap><div align="center">' + CRLF
				cHtml += 		aImp[nX,nY] + CRLF
				cHtml += 	'</td>' + CRLF
			EndIf	
		Next nY
		
		//-- Trata Abonos e Excecoes
		If ValType(aImp[nX,3]) == "A"
			nAbHora:=  At( ":" , aImp[nX,3,2] )
		Else
			nAbHora:=  At( ":" , aImp[nX,3] )
		EndIf
		 
		If nAbHora > 0 
			cOcorr :=	Capital( If (ValType(aImp[nX,3]) == "A",aImp[nX,3,1],SubStr( aImp[nX,3] , 1 , nAbHora - 3 )) ) 
			cAbHora:= 	Capital( If (ValType(aImp[nX,3]) == "A",aImp[nX,3,2],SubStr( aImp[nX,3] , nAbHora - 2 ) ) ) 
		Else                                                                      
			cOcorr :=	Capital( If (ValType(aImp[nX,3]) == "A",aImp[nX,3,1],AllTrim( aImp[nX,3] ) ))
			cAbHora:= 	'&nbsp;'	
		EndIf                                                
		
		If ( lZebrado )
			cHtml += 		'<td class="dados_2" bgcolor="#FAFBFC" nowrap><div align="center">' + CRLF
			cHtml +=			Capital( AllTrim( aImp[nX,2] ) )
			cHtml += 		'</td>' + CRLF
			cHtml += 		'<td class="dados_2" bgcolor="#FAFBFC" nowrap><div align="left">' + CRLF
			cHtml +=	 		cOcorr   						
			cHtml += 		'</td>' + CRLF
			cHtml += 		'<td class="dados_2" bgcolor="#FAFBFC" nowrap><div align="left">' + CRLF
			cHtml +=	 		cAbHora	
			cHtml += 		'</td>' + CRLF
		Else
			cHtml += 		'<td class="dados_2" nowrap><div align="center">' + CRLF
			cHtml +=			Capital( AllTrim( aImp[nX,2] ) )
			cHtml += 		'</td>' + CRLF
			cHtml += 		'<td class="dados_2" nowrap><div align="left">' + CRLF
			cHtml +=	 		cOcorr   						
			cHtml += 		'</td>' + CRLF
			cHtml += 		'<td class="dados_2" nowrap><div align="left">' + CRLF
			cHtml +=			cAbHora
			cHtml += 		'</td>' + CRLF
		EndIf	
	EndIf
Next nX

If !( lTerminal )
	
	nLin += 25	
		
	If lImpBH
		If Pnr010ImpBh(@nSaldoAnt, @nSaldoAtu, @nCredito, @nDebito)
			
			If nLin > nLinTot - 40
				fImpSign(oPrinter)
				oPrinter:EndPage()
				oPrinter:StartPage()
				Imp_Cabec( nTamLin , nColunas ,  lTerminal, 0, oPrinter )
			EndIf
			
			oPrinter:Box( nLin, nCol , nLin+13, nColTot, "-6" )		// Caixa da linha total
			
			nTamCol	 := (nColTot - nCol) / 6
			nColCod1 := nCol + nTamCol * 2
			nColCod2 := nColCod1 + nTamCol
			nColCod3 := nColCod2 + nTamCol
			nColCod4 := nColCod3 + nTamCol
			
			If lBigLine
				oPrinter:Fillrect( {nLin+1, nCol+1, nLin+13, nColTot-1 }, oBrushC, "-2") // Quadro na Cor Cinza
			EndIf
			
			oPrinter:Line( nLin, nColCod1	, nLin+13, nColCod1		, 0 , "-6")
			oPrinter:Line( nLin, nColCod2	, nLin+13, nColCod2		, 0 , "-6")
			oPrinter:Line( nLin, nColCod3	, nLin+13, nColCod3		, 0 , "-6")
			oPrinter:Line( nLin, nColCod4	, nLin+13, nColCod4		, 0 , "-6")

			oPrinter:SayAlign(nLin,nCol+2,STR0081,oFontP,500,100,,ALIGN_H_LEFT)		//Banco de Horas
			oPrinter:SayAlign(nLin,nColCod1+2,STR0082,oFontP,500,100,,ALIGN_H_LEFT)	//Saldo Anterior
			oPrinter:SayAlign(nLin,nColCod2+2,STR0083,oFontP,500,100,,ALIGN_H_LEFT)	//Débito
			oPrinter:SayAlign(nLin,nColCod3+2,STR0084,oFontP,500,100,,ALIGN_H_LEFT)	//Crédito
			oPrinter:SayAlign(nLin,nColCod4+2,STR0085,oFontP,500,100,,ALIGN_H_LEFT)	//Saldo Atual
			
			nLin+=12
			
			oPrinter:Box(  nLin, nCol	, nLin+13, nColTot	, "-6" )
			
			oPrinter:Line( nLin, nColCod1	, nLin+13, nColCod1		, 0 , "-6")
			oPrinter:Line( nLin, nColCod2	, nLin+13, nColCod2		, 0 , "-6")
			oPrinter:Line( nLin, nColCod3	, nLin+13, nColCod3		, 0 , "-6")
			oPrinter:Line( nLin, nColCod4	, nLin+13, nColCod4		, 0 , "-6")
			
			oPrinter:SayAlign(nLin,nColCod1+2, Transform(nSaldoAnt,'@E 99,999.99'),oFontM,500,100,,ALIGN_H_LEFT)		//Saldo Anterior
			oPrinter:SayAlign(nLin,nColCod2+2, Transform(nDebito,'@E 99,999.99'),oFontM,500,100,,ALIGN_H_LEFT)			//Débito
			oPrinter:SayAlign(nLin,nColCod3+2, Transform(nCredito,'@E 99,999.99'),oFontM,500,100,,ALIGN_H_LEFT)			//Crédito
			oPrinter:SayAlign(nLin,nColCod4+2, Transform(nSaldoAtu,'@E 99,999.99'),oFontM,500,100,,ALIGN_H_LEFT)		//Saldo Atual	

			nLin += 25									
		EndIf
	EndIf	
		
		
	//-- Se existirem totais, e se For selecionada sua impress„o, ser„o impressos.
	If lImpMarc .And. Len(aTotais) > 0 .And. nImpHrs # 4
		If nLin > nLinTot - 40
			fImpSign(oPrinter)
			oPrinter:EndPage()
			oPrinter:StartPage()
			Imp_Cabec( nTamLin , nColunas ,  lTerminal, 0, oPrinter )
			nLin+=20
		EndIf
		
		oPrinter:Box( nLin, nCol , nLin+13, nColTot, "-6" )			// Caixa da linha total
		
		nTamCol	 := (nColTot - nCol) / 21
		nColCod1 := nCol + nTamCol
		nColDesc1:= nColCod1 + (nTamCol*4)
		nColCalc1:= nColDesc1 + nTamCol
		nColInf1 := nColCalc1 + nTamCol
		nColCod2 := nColInf1 + nTamCol
		nColDesc2:= nColCod2 + (nTamCol*4)
		nColCalc2:= nColDesc2 + nTamCol
		nColInf2 := nColCalc2 + nTamCol
		nColCod3 := nColInf2 + nTamCol
		nColDesc3:= nColCod3 + (nTamCol*4)
		nColCalc3:= nColDesc3 + nTamCol
		
		If lBigLine
			oPrinter:Fillrect( {nLin+1, nCol+1, nLin+13, nColTot-1 }, oBrushC, "-2") // Quadro na Cor Cinza
		EndIf		 
		
		oPrinter:Line( nLin, nColCod1	, nLin+13, nColCod1		, 0 , "-6")
		If nImpHrs == 1 .Or. nImpHrs == 3
			oPrinter:Line( nLin, nColDesc1	, nLin+13, nColDesc1	, 0 , "-6")
		EndIf
		oPrinter:Line( nLin, nColCalc1	, nLin+13, nColCalc1	, 0 , "-6")
		oPrinter:Line( nLin, nColInf1	, nLin+13, nColInf1		, 0 , "-6")
		oPrinter:Line( nLin, nColCod2	, nLin+13, nColCod2		, 0 , "-6")
		If nImpHrs == 1 .Or. nImpHrs == 3
			oPrinter:Line( nLin, nColDesc2	, nLin+13, nColDesc2	, 0 , "-6")
		EndIf
		oPrinter:Line( nLin, nColCalc2	, nLin+13, nColCalc2	, 0 , "-6")
		oPrinter:Line( nLin, nColInf2	, nLin+13, nColInf2		, 0 , "-6")
		oPrinter:Line( nLin, nColCod3	, nLin+13, nColCod3		, 0 , "-6")
		If nImpHrs == 1 .Or. nImpHrs == 3
			oPrinter:Line( nLin, nColDesc3	, nLin+13, nColDesc3	, 0 , "-6")
		EndIf
		oPrinter:Line( nLin, nColCalc3	, nLin+13, nColCalc3	, 0 , "-6")

		oPrinter:SayAlign(nLin,nCol+2,STR0064,oFontP,500,100,,ALIGN_H_LEFT)				//Codigo
		oPrinter:SayAlign(nLin,nColCod1+2,STR0065,oFontP,500,100,,ALIGN_H_LEFT)			//Descrição
		
		If nImpHrs == 1 .Or. nImpHrs == 3
			oPrinter:SayAlign(nLin,nColDesc1+2,STR0066,oFontP,500,100,,ALIGN_H_LEFT)	//Calculado
		EndIf
		
		oPrinter:SayAlign(nLin,nColCalc1+2,STR0067,oFontP,500,100,,ALIGN_H_LEFT)		//Informado
		
		oPrinter:SayAlign(nLin,nColInf1+2,STR0064,oFontP,500,100,,ALIGN_H_LEFT)			//Codigo
		oPrinter:SayAlign(nLin,nColCod2+2,STR0065,oFontP,500,100,,ALIGN_H_LEFT)			//Descrição
		
		If nImpHrs == 1 .Or. nImpHrs == 3		
			oPrinter:SayAlign(nLin,nColDesc2+2,STR0066,oFontP,500,100,,ALIGN_H_LEFT)	//Calculado
		EndIf
		oPrinter:SayAlign(nLin,nColCalc2+2,STR0067,oFontP,500,100,,ALIGN_H_LEFT)		//Informado
		
		oPrinter:SayAlign(nLin,nColInf2+2,STR0064,oFontP,500,100,,ALIGN_H_LEFT)			//Codigo
		oPrinter:SayAlign(nLin,nColCod3+2,STR0065,oFontP,500,100,,ALIGN_H_LEFT)			//Descrição
		
		If nImpHrs == 1 .Or. nImpHrs == 3		
			oPrinter:SayAlign(nLin,nColDesc3+2,STR0066,oFontP,500,100,,ALIGN_H_LEFT)	//Calculado
		EndIf
		oPrinter:SayAlign(nLin,nColCalc3+2,STR0067,oFontP,500,100,,ALIGN_H_LEFT)		
		
		nMetade := nLin
		nContEve:= 1
		
		For nX := 1 To Len(aTotais)
			If nContEve == 1
				nMetade+=12
				If nMetade > nLinTot - 40
					fImpSign(oPrinter)
					oPrinter:EndPage()
					oPrinter:StartPage()
					Imp_Cabec( nTamLin , nColunas ,  lTerminal, 2, oPrinter )
					nLin+=12
					nMetade := nLin
				EndIf
				oPrinter:Box(  nMetade, nCol	, nMetade+13, nColTot	, "-6" )
				If lBigLine .And. lBrush
					oPrinter:Fillrect( {nMetade+1, nCol+1, nMetade+12, nColTot-1 }, oBrushI, "-2") // Quadro na Cor Cinza
					lBrush := .F.
				Else
					lBrush := .T.
				EndIf				
				oPrinter:Line( nMetade, nColCod1	, nMetade+13, nColCod1	, 0 , "-6")
				oPrinter:Line( nMetade, nColDesc1	, nMetade+13, nColDesc1	, 0 , "-6")
				oPrinter:Line( nMetade, nColCalc1	, nMetade+13, nColCalc1	, 0 , "-6")
				oPrinter:Line( nMetade, nColInf1	, nMetade+13, nColInf1	, 0 , "-6")
				oPrinter:Line( nMetade, nColCod2	, nMetade+13, nColCod2	, 0 , "-6")
				oPrinter:Line( nMetade, nColDesc2	, nMetade+13, nColDesc2	, 0 , "-6")
				oPrinter:Line( nMetade, nColCalc2	, nMetade+13, nColCalc2	, 0 , "-6")
				oPrinter:Line( nMetade, nColInf2	, nMetade+13, nColInf2	, 0 , "-6")
				oPrinter:Line( nMetade, nColCod3	, nMetade+13, nColCod3	, 0 , "-6")
				oPrinter:Line( nMetade, nColDesc3	, nMetade+13, nColDesc3	, 0 , "-6")
				oPrinter:Line( nMetade, nColCalc3	, nMetade+13, nColCalc3	, 0 , "-6")
				
				oPrinter:SayAlign(nMetade,nCol+2,aTotais[nX,1],oFontM,500,100,,ALIGN_H_LEFT)
				oPrinter:SayAlign(nMetade,nColCod1+2,aTotais[nX,2],oFontM,500,100,,ALIGN_H_LEFT)
				oPrinter:SayAlign(nMetade,nColDesc1,aTotais[nX,3],oFontM,500,100,,ALIGN_H_LEFT)
				oPrinter:SayAlign(nMetade,nColCalc1,aTotais[nX,4],oFontM,500,100,,ALIGN_H_LEFT)
				nContEve++
			ElseIf nContEve == 2
				oPrinter:SayAlign(nMetade,nColInf1+2,aTotais[nX,1],oFontM,500,100,,ALIGN_H_LEFT)
				oPrinter:SayAlign(nMetade,nColCod2+2,aTotais[nX,2],oFontM,500,100,,ALIGN_H_LEFT)
				oPrinter:SayAlign(nMetade,nColDesc2,aTotais[nX,3],oFontM,500,100,,ALIGN_H_LEFT)
				oPrinter:SayAlign(nMetade,nColCalc2,aTotais[nX,4],oFontM,500,100,,ALIGN_H_LEFT)
				nContEve++
			ElseIf nContEve == 3
				oPrinter:SayAlign(nMetade,nColInf2+2,aTotais[nX,1],oFontM,500,100,,ALIGN_H_LEFT)
				oPrinter:SayAlign(nMetade,nColCod3+2,aTotais[nX,2],oFontM,500,100,,ALIGN_H_LEFT)
				oPrinter:SayAlign(nMetade,nColDesc3,aTotais[nX,3],oFontM,500,100,,ALIGN_H_LEFT)
				oPrinter:SayAlign(nMetade,nColCalc3,aTotais[nX,4],oFontM,500,100,,ALIGN_H_LEFT)			
				nContEve++
			EndIf
			If nContEve > 3
				nContEve := 1
			EndIf
			nLin := nMetade
		Next nX
	EndIf
	
	fImpSign(oPrinter)
Else
	// Final da Estrutura do Codigo HTML							   
    cHtml +=									'<tr>' + CRLF
    cHtml +=										'<td colspan="' + AllTrim( Str( nColunas + 5 ) ) + '" class="etiquetas_1" bgcolor="#FAFBFC"><hr size="1"></td>' + CRLF 
    cHtml +=									'</tr>' + CRLF
	cHtml +=								'</table>' + CRLF
	cHtml +=							'</td>' + CRLF
    cHtml +=							'<td background="'+TcfRetDirImg()+'/tabela_conteudo_2.gif" width="7">&nbsp;</td>' + CRLF
    cHtml +=						'</tr>' + CRLF
    cHtml +=					'</table>' + CRLF
    cHtml +=				'</td>' + CRLF
  	cHtml +=			'</tr>' + CRLF
	cHtml +=		'</table>' + CRLF
	cHtml +=		'<p align="right"><a href="javascript:self.print()"><img src="'+TcfRetDirImg()+'/imprimir.gif" width="90" height="28" hspace="20" border="0"></a></p>' + CRLF
	cHtml +=	'</body>' + CRLF
	cHtml += '</html>' + CRLF
EndIf
	
Return( cHtml )

/*
===============================================================================================================================
Programa----------: FMontaAimp
Autor-------------: Totvs
Data da Criacao---: 09/04/1996
Descrição---------: Monta o Vetor aImp , utilizado na impressao do espelho 
Parametros--------:  aTabCalend
                     aMarcacoes
                     aImp
                     dInicio
                     dFim
                     lTerminal
                     lImpAcum
Retorno-----------: lRet = .T. / .F.
===============================================================================================================================
*/
Static Function FMontaAimp(aTabCalend As Array,aMarcacoes As Array,aImp As Array,dInicio As Date,dFim As Date,lTerminal As Logical,lImpAcum As Logical)

Local aDescAbono := {} As Array
Local cTipAfas   := "" As Character
Local cDescAfas  := "" As Character
Local cOcorr     := "" As Character
Local cOrdem     := "" As Character
Local cTipDia    := "" As Character
Local dData      := CtoD("//") As Date
Local dDtBase    := dFim As Date
Local lRet       := .T. As Logical
Local lFeriado   := .T. As Logical
Local lTrabaFer  := .F. As Logical
Local lAfasta    := .T. As Logical
Local nX         := 0 As Numeric
Local nDia       := 0 As Numeric
Local nMarc      := 0 As Numeric
Local nLenMarc	 := Len( aMarcacoes ) As Numeric
Local nLenDescAb := Len( aDescAbono ) As Numeric
Local nTab       := 0 As Numeric
Local nContMarc  := 0 As Numeric
Local nDias		 := 0  As Numeric

//-- Variaveis ja inicializadas.
aImp := {}

nDias := ( dDtBase - dInicio )
For nDia := 0 To nDias

	//-- Reinicializa Variaveis.
	dData      := dInicio + nDia
	aDescAbono := {}
	cOcorr     := ""
	cTipAfas   := ""
	cDescAfas  := ""
	cOcorr	   := ""

	If !lImpMarc	
		//-- Adiciona Nova Data a ser impressa.
		aAdd(aImp,{})
		aAdd(aImp[Len(aImp)], dData)
		aAdd(aImp[Len(aImp)], Space(1))
		nContMarc++
		Loop 
	EndIf	
	
	//-- o Array aTabcalend ‚ setado para a 1a Entrada do dia em quest„o.
	If ( nTab := aScan(aTabCalend, {|x| x[1] == dData .And. x[4] == '1E' }) ) == 0.00
		Loop
	EndIf
	
	//-- o Array aMarcacoes ‚ setado para a 1a Marca‡„o do dia em quest„o.
	nMarc := aScan(aMarcacoes, { |x| x[3] == aTabCalend[nTab, 2] })

	//-- Consiste Afastamentos, Demissoes ou Transferencias.
	If ( ( lAfasta := aTabCalend[ nTab , 24 ] ) .Or. SRA->( RA_SITFOLH $ 'DúT' .And. dData > RA_DEMISSA ) )
		lAfasta		:= .T.
		cTipAfas	:= If(!Empty(aTabCalend[ nTab , 25 ]),aTabCalend[ nTab , 25 ],fDemissao(SRA->RA_SITFOLH, SRA->RA_RESCRAI) )
		cDescAfas	:= AllTrim(fDescAfast( cTipAfas, TamSX3("RCM_DESCRI")[1], Nil, SRA->( RA_SITFOLH == 'D' .And. dData > RA_DEMISSA ), aTabCalend[ nTab , 47 ], SRA->RA_FILIAL ))
	EndIf

	//Verifica Regra de Apontamento ( Trabalha Feriado ? )
	lTrabaFer := ( PosSPA( aTabCalend[ nTab , 23 ] , cFilSPA , "PA_FERIADO" , 01 ) == "S" )

	//-- Consiste Feriados.
	If ( lFeriado := aTabCalend[ nTab , 19 ] )  .And. !lTrabaFer
		cOcorr := aTabCalend[ nTab , 22 ]
	EndIf

	//-- Carrega Array aDescAbono com os Abonos ocorridos no Dia
	nLenDescAb := Len(aAbonados)
	For nX := 1 To nLenDescAb
		If aAbonados[nX,1] == dData
			aAdd(aDescAbono, { aAbonados[nX,2] , aAbonados[nX,3] , aAbonados[nX,4] })
		EndIf
	Next nX

	//-- Ordem e Tipo do dia em quest„o.
	cOrdem  := aTabCalend[nTab,2]
	cTipDia := aTabCalend[nTab,6]

    //-- Se a Data da marcacao For Posterior a Admissao
	If dData >= SRA->RA_ADMISSA
		//-- Se Afastado
		If ( lAfasta  .And. aTabCalend[nTab,10] <> 'E' ) .Or. ( lAfasta  .And. aTabCalend[nTab,10] == 'E' .And. ( !lImpExcecao .Or. !aTabCalend[nTab,32] ) )
			cOcorr := cDescAfas 
		//-- Se nao For Afastado
		Else                    

		    //-- Se tiver EXCECAO para o Dia  ------------------------------------------------
			If aTabCalend[nTab,10] == 'E'			
		       //-- Se excecao trabalhada
		       If cTipDia == 'S'  
		          //-- Se nao fez Marcacao
		          If Empty(nMarc)
					 cOcorr := STR0020  // '** Ausente **'	
				  //-- Se fez marcacao	 
		          Else
		          	 //-- Motivo da Marcacao
	          		 If !Empty(aTabCalend[nTab,11])
					 	cOcorr := AllTrim(aTabCalend[nTab,11])
					 Else
					 	cOcorr := STR0018  // '** Excecao nao Trabalhada **'
					 EndIf
		          EndIf	 
		       //-- Se excecao outros dias (DSR/Compensado/Nao Trabalhado)
		       Else
 					//-- Motivo da Marcacao
		       		If !Empty(aTabCalend[nTab,11])
						cOcorr := AllTrim(aTabCalend[nTab,11])
					Else
						cOcorr := STR0018  // '** Excecao nao Trabalhada **'  
					EndIf
			   EndIf	

		    //-- Se nao Tiver Excecao  no Dia ---------------------------------------------------
		    Else    
		        //-- Se feriado 
		       	If lFeriado 
		       	    //-- Se nao trabalha no Feriado
		       	    If !lTrabaFer 
						cOcorr := If(!Empty(cOcorr),cOcorr,STR0019 ) // '** Feriado **' 
					//-- Se trabalha no Feriado
					Else                  
					    //-- Se Dia Trabalhado e Nao fez Marcacao
				    	If cTipDia == 'S' .And. Empty(nMarc)
							cOcorr := STR0020  // '** Ausente **'
				    	ElseIf cTipDia == 'D'
							cOcorr := STR0021  // '** D.S.R. **'  
						ElseIf cTipDia == 'C'
							cOcorr := STR0022  // '** Compensado **'
						ElseIf cTipDia == 'N'
							cOcorr := STR0023  // '** Nao Trabalhado **'
						EndIf
					EndIf
		    	Else                                    
		    	    //-- Se Dia Trabalhado e Nao fez Marcacao
			    	If cTipDia == 'S' .And. Empty(nMarc)
						cOcorr := STR0020  // '** Ausente **'
			    	ElseIf cTipDia == 'D'
						cOcorr := STR0021  // '** D.S.R. **'
					ElseIf cTipDia == 'C'
						cOcorr := STR0022  // '** Compensado **'
					ElseIf cTipDia == 'N'
						cOcorr := STR0023  // '** Nao Trabalhado **'
					EndIf
				
				EndIf	
		    EndIf
		EndIf
	EndIf	    
	
	nLenDescAb := Len(aDescAbono) 
	
	//-- Adiciona Nova Data a ser impressa.
	aAdd(aImp,{})
	aAdd(aImp[Len(aImp)], aTabCalend[nTab,1])

	//-- Ocorrencia na Data.
	If (lTerminal) 
		aAdd( aImp[Len(aImp)], cOcorr) 
	EndIf	
	
	//-- Abono na Data.
	If ( nLenDescAb  > 0 )
	    If !( lTerminal)
	    	If cOcorr == STR0020  // '** Ausente **'
			  	aAdd( aImp[Len(aImp)], cOcorr ) // '** Ausente **'
			Else
				If !Empty(cOcorr)
					aAdd( aImp[Len(aImp)],	Space(01)) 
				  	aAdd( aImp[Len(aImp)], cOcorr )
					aAdd( aImp,{})
					aAdd( aImp[Len(aImp)], aTabCalend[nTab,1])
					aAdd( aImp[Len(aImp)],	Space(01) )
				Else                                   
					aAdd( aImp[Len(aImp)],	Space(01)) 
				EndIf	
			EndIf
	    EndIf
		For nX := 1 To nLenDescAb
			If nX == 1
				aAdd( aImp[Len(aImp)], aDescAbono[nX])
			Else
				aAdd(aImp, {})
				aAdd(aImp[Len(aImp)], aTabCalend[nTab,1]		)
				aAdd(aImp[Len(aImp)], Space(01)			 	)
				aAdd(aImp[Len(aImp)], aDescAbono[nX]			)
			EndIf
		Next nX
	Else
		If ( lTerminal ) 
			aAdd( aImp[Len(aImp)], '' )
		Else
			If cOcorr == STR0020  // '** Ausente **'
				aAdd( aImp[Len(aImp)], cOcorr) 
				aAdd( aImp[Len(aImp)], Space(01)) 
			Else
				aAdd( aImp[Len(aImp)], Space(01)) 
			  	aAdd( aImp[Len(aImp)], cOcorr )
			EndIf	
		EndIf		
	EndIf

	//-- Marca‡oes ocorridas na data.
	If nMarc > 0
		While nMarc <= nLenMarc .And. cOrdem == aMarcacoes[nMarc,3]
			nContMarc ++
			aAdd( aImp[Len(aImp)], StrTran(StrZero(aMarcacoes[nMarc,2],5,2),'.',':') + If(aMarcacoes[nMarc,28]<>"O","*","") ) //Se nao For original, inclui asterisco na frente da marcacao
			nMarc ++
		End While
	EndIf

Next nDia

If lImpMarc .And. !lTerminal //Carrega o array aResult para exibicao das HE, faltas e adc. noturno.
	aResult := {}
    aResultPDI := {}
	fGetApo(@aResult, dInicio, dFim, lImpAcum)
EndIf

lRet := If(nContMarc>=1,.T.,.F.)

Return( lRet )

/*
===============================================================================================================================
Programa----------: Imp_Cabec
Autor-------------: Totvs
Data da Criacao---: 09/04/1996
Descrição---------: Imprime o cabecalho do espelho do ponto
Parametros--------:  nTamLin 
                     nColunas
                     lTerminal
                     nTipoCab
                     oPrinter
Retorno-----------: cHtml
===============================================================================================================================
*/
Static Function Imp_Cabec(nTamLin As Numeric,nColunas As Numeric,lTerminal As Logical,nTipoCab As Numeric,oPrinter As Object)

Local cDet			:= "" As Character
Local cHtml			:= "" As Character
Local lImpTurnos	:=.F. As Logical
Local nVezes		:= ( nColunas / 2 ) As Numeric
Local nX			:= 0.00 As Numeric
Local nSizePage		:= 0 As Numeric
Local nColCab12		:= 0 As Numeric
Local nColCab13		:= 0 As Numeric
Local nVarAux		:= 0 As Numeric
Local nESAux		:= 0 As Numeric
Local oBrush		:= TBrush():New( ,  RGB(228, 228, 228)  ) As Object

DEFAULT lTerminal := .F.
DEFAULT nTipoCab  := 3 // 1 - Cab para as Marcacoes / 2 - Totais / 3 - Sem Cab Auxiliar

lImpTurnos := nTipoCab <> 2

If !( lTerminal )

	nSizePage	:= oPrinter:nPageWidth / oPrinter:nFactorHor //Largura da página em cm dividido pelo fator horizontal, retorna tamanho da página em pixels
	nLin		:= aMargRel[2] 
	nCol		:= aMargRel[1] - 8  
	nPxData	 	:= nCol+50
	nPxSemana	:= nPxData+50
	nVarAux		:= nPxSemana+165
	nColTot		:= nSizePage-(aMargRel[1]+aMargRel[3]) + 16 
	nLinTot		:= (oPrinter:nPageHeight / oPrinter:nFactorVert) - (aMargRel[2]+aMargRel[4])
	nColCab12	:= nColTot / 3
	nColCab13	:= ( nColTot / 3 ) * 2
	aNaES		:= Array(nColunas)
	
	For nX := 1 to Len(aNaES)
		aNaES[nX] := nVarAux
		nVarAux += 40	
	Next nX
	
	nPxAbonos 	:= nVarAux
	nPxHe	 	:= nPxAbonos + 40
	nPxFalta 	:= nPxHe + 40
	nPxObser  	:= nPxFalta + 40

	If lCodeBar
		If lBigLine
			oPrinter:Fillrect( {nLin, nCol, nLin+17, nColTot-210 }, oBrush, "-2") 	// Quadro na Cor Cinza
		EndIf
		oPrinter:SayAlign(nLin+2,nCol,STR0001,oFontT,nColTot-210,100,,ALIGN_H_CENTER)  	// 'Espelho do Ponto'	
	
		oPrinter:Box( nLin+3, nColTot-200	, nLin+38, nColTot-5, "-6" )				// Caixa da linha total
		oPrinter:Code128c(nLin+30, nColTot-176, cCodeBar, 20)
		oPrinter:SayAlign(nLin+30,nColTot-200,cCodeBar,oFont06,(nColTot-(nColTot-200)),100,,ALIGN_H_CENTER)
	Else
		If lBigLine
			oPrinter:Fillrect( {nLin, nCol, nLin+17, nColTot }, oBrush, "-2") 	// Quadro na Cor Cinza
		EndIf
		oPrinter:SayAlign(nLin+2,nCol,STR0001,oFontT,nColTot,100,,ALIGN_H_CENTER)  	// 'Espelho do Ponto'	
	EndIf
	
	nLin += 18	
	
	cDet := STR0071  + PadR( If(Len(aInfo)>0,aInfo[03],SM0->M0_NOMECOM) , 50)  // 'Empresa: '
	oPrinter:SayAlign(nLin,nCol,cDet,oFontP,500,100,,ALIGN_H_LEFT)
	
	If ( Len(aInfo) > 0 ) .And. ( aInfo[28] == 1 )
		cDet := STR0095  + PadR(Transform( If(!Empty(aInfo[27]), aInfo[27], SM0->M0_CEI),'@R ##.###.#####/##'),50)   // 'CEI: '
	ElseIf ( Len(aInfo) > 0 ) .And. ( aInfo[28] == 3 )
		cDet := STR0096  + PadR(Transform( If((aInfo[08]#""), aInfo[08], SM0->M0_CGC),'@R ###.###.###-##'),50)   // 'CPF: '
	Else
		cDet := STR0075  + PadR(Transform( If(Len(aInfo)>0,aInfo[08],SM0->M0_CGC),'@R ##.###.###/####-##'),50)   // 'CGC: '
	EndIf
	oPrinter:SayAlign(nLin,nColCab12,cDet,oFontP,500,100,,ALIGN_H_LEFT)
	
	cDet := PadR( If(Len(aInfo)>0,aInfo[04],SM0->M0_EndCob) , 50)
	oPrinter:SayAlign(nLin,nColCab13,cDet,oFontP,500,100,,ALIGN_H_LEFT)
	
	nLin += 13
	
	oPrinter:Line(nLin,nCol,nLin,nColTot)
	
	nLin += 5
	cDet := STR0072  + AllTrim(SRA->RA_FILIAL) + ' - ' + SRA->RA_MAT  // ' Matr..: '
	oPrinter:SayAlign(nLin,nCol,cDet,oFontP,500,100,,ALIGN_H_LEFT)
	
	cDet := STR0074  + If(!Empty(SRA->RA_NSOCIAL),SRA->RA_NSOCIAL,SRA->RA_NOME)  // ' Nome..: '
	oPrinter:SayAlign(nLin,nColCab12,cDet,oFontP,500,100,,ALIGN_H_LEFT)
	
	cDet := STR0060 + ": " + AllTrim(SRA->RA_DEPTO)  + " - " + Posicione("SQB",1,SRA->RA_FILIAL+SRA->RA_DEPTO,"QB_DESCRIC") // 'Departamento: '
	oPrinter:SayAlign(nLin,nColCab13,cDet,oFontP,500,100,,ALIGN_H_LEFT)
	
	nLin += 13
	cDet := STR0078  + aFuncFunc[6] // ' Categ.: '
	oPrinter:SayAlign(nLin,nCol,cDet,oFontP,500,100,,ALIGN_H_LEFT)
	
	cDet := STR0077  + PadR(AllTrim(aFuncFunc[1]) + ' - ' + aFuncFunc[2] , 50) // 'C.C...: '
	oPrinter:SayAlign(nLin,nColCab12,cDet,oFontP,500,100,,ALIGN_H_LEFT)
	
	cDet := STR0076  + AllTrim(aFuncFunc[3]) + ' - ' + aFuncFunc[4]  // 'Funcao: '
	oPrinter:SayAlign(nLin,nColCab13,cDet,oFontP,500,100,,ALIGN_H_LEFT)
	
	nLin += 13
		    		
	oPrinter:Line(nLin,nCol,nLin,nColTot)
	If nTipoCab==1 //Monta e Imprime Cabecalho das Marcacoes
	
		// Desenho do cabecalho //
		oPrinter:Box( nLin+=5, nCol	, nLin+20, nColTot, "-6" )				// Caixa da linha total

		If lBigLine
			oPrinter:Fillrect( {nLin+1, nCol+1, nLin+17, nColTot-1 }, oBrush, "-2") // Quadro na Cor Cinza
		EndIf
		
		oPrinter:Line( nLin, nPxData	, nLin+20, nPxData	, 0 , "-6") 		// Linha Pos Data
		
		For nX := 1 to Len(aNaES)
			oPrinter:Line( nLin, aNaES[nX]-6	, nLin+20	, aNaES[nX]-6, 0 , "-6")			// Linha Pos Na. Entrada/Saída
		Next nX
		
		oPrinter:Line( nLin, nPxAbonos-6	, nLin+20	, nPxAbonos-6, 0 , "-6")
		oPrinter:Line( nLin, nPxHe-6		, nLin+20	, nPxHe-6, 0 , "-6")
		oPrinter:Line( nLin, nPxFalta-6		, nLin+20	, nPxFalta-6, 0 , "-6")
		oPrinter:Line( nLin, nPxData+36  	, nLin+20	, nPxData+36, 0 , "-6")
		
		oPrinter:Line( nLin, nPxObser	, nLin+20	, nPxObser, 0 , "-6")
		
		oPrinter:SayAlign( nLin+=3 , nCol+5		, STR0042	, oFontP, nPxData, 150 , , ALIGN_H_LEFT ) //Data
		oPrinter:SayAlign( nLin, nPxData+6	, STR0043		, oFontP, nPxSemana, 150 , , ALIGN_H_LEFT ) //Semana
		oPrinter:SayAlign( nLin, nPxData+45	, "Turno"		, oFontP, nPxSemana, 150 , , ALIGN_H_LEFT ) //Turno

		nESAux := 1
		For nX := 1 to Len(aNaES)
			If nX%2 == 0
				oPrinter:SayAlign( nLin, aNaES[nX], AllTrim(Str(nESAux)) + STR0036, oFontP, aNaES[nX]+40, 150 , , ALIGN_H_LEFT ) //Saida
				nESAux++
			Else
				oPrinter:SayAlign( nLin, aNaES[nX], AllTrim(Str(nESAux)) + STR0035, oFontP, aNaES[nX]+40, 150 , , ALIGN_H_LEFT ) //Entrada
			EndIf
		Next nX
		
		oPrinter:SayAlign( nLin, nPxAbonos	, STR0062		, oFontP, 500, 150 , , ALIGN_H_LEFT ) //Abonos
		oPrinter:SayAlign( nLin, nPxHe		, STR0068		, oFontP, 500, 150 , , ALIGN_H_LEFT ) //H.E.
		oPrinter:SayAlign( nLin, nPxFalta	, STR0069		, oFontP, 500, 150 , , ALIGN_H_LEFT ) //Falt/Atra
		oPrinter:SayAlign( nLin, nPxObser+6	, STR0063		, oFontP, 500, 150 , , ALIGN_H_LEFT ) //Observação
		
		
	ElseIf nTipoCab == 2
		nLin += 18
		oPrinter:Box( nLin, nCol , nLin+13, nColTot, "-6" )			// Caixa da linha total
		
		nTamCol	 := (nColTot - nCol) / 21
		nColCod1 := nCol + nTamCol
		nColDesc1:= nColCod1 + (nTamCol*4)
		nColCalc1:= nColDesc1 + nTamCol
		nColInf1 := nColCalc1 + nTamCol
		nColCod2 := nColInf1 + nTamCol
		nColDesc2:= nColCod2 + (nTamCol*4)
		nColCalc2:= nColDesc2 + nTamCol
		nColInf2 := nColCalc2 + nTamCol
		nColCod3 := nColInf2 + nTamCol
		nColDesc3:= nColCod3 + (nTamCol*4)
		nColCalc3:= nColDesc3 + nTamCol
		
		If lBigLine
			oPrinter:Fillrect( {nLin+1, nCol+1, nLin+13, nColTot-1 }, oBrush, "-2") // Quadro na Cor Cinza
		EndIf		 
		
		oPrinter:Line( nLin, nColCod1	, nLin+13, nColCod1		, 0 , "-6")
		If nImpHrs == 1 .Or. nImpHrs == 3
			oPrinter:Line( nLin, nColDesc1	, nLin+13, nColDesc1	, 0 , "-6")
		EndIf
		oPrinter:Line( nLin, nColCalc1	, nLin+13, nColCalc1	, 0 , "-6")
		oPrinter:Line( nLin, nColInf1	, nLin+13, nColInf1		, 0 , "-6")
		oPrinter:Line( nLin, nColCod2	, nLin+13, nColCod2		, 0 , "-6")
		If nImpHrs == 1 .Or. nImpHrs == 3
			oPrinter:Line( nLin, nColDesc2	, nLin+13, nColDesc2	, 0 , "-6")
		EndIf
		oPrinter:Line( nLin, nColCalc2	, nLin+13, nColCalc2	, 0 , "-6")
		oPrinter:Line( nLin, nColInf2	, nLin+13, nColInf2		, 0 , "-6")
		oPrinter:Line( nLin, nColCod3	, nLin+13, nColCod3		, 0 , "-6")
		If nImpHrs == 1 .Or. nImpHrs == 3
			oPrinter:Line( nLin, nColDesc3	, nLin+13, nColDesc3	, 0 , "-6")
		EndIf
		oPrinter:Line( nLin, nColCalc3	, nLin+13, nColCalc3	, 0 , "-6")		

		oPrinter:SayAlign(nLin,nCol+2,STR0064,oFontP,500,100,,ALIGN_H_LEFT) //Codigo
		oPrinter:SayAlign(nLin,nColCod1+2,STR0065,oFontP,500,100,,ALIGN_H_LEFT) //Descricao
		
		If nImpHrs == 1 .Or. nImpHrs == 3 //Calculado
			oPrinter:SayAlign(nLin,nColDesc1+2,STR0066,oFontP,500,100,,ALIGN_H_LEFT)
		EndIf
		
		oPrinter:SayAlign(nLin,nColCalc1+2,STR0067,oFontP,500,100,,ALIGN_H_LEFT) //Informado
		
		oPrinter:SayAlign(nLin,nColInf1+2,STR0064,oFontP,500,100,,ALIGN_H_LEFT) //Codigo
		oPrinter:SayAlign(nLin,nColCod2+2,STR0065,oFontP,500,100,,ALIGN_H_LEFT) //Descricao
		
		If nImpHrs == 1 .Or. nImpHrs == 3 //Calculado		
			oPrinter:SayAlign(nLin,nColDesc2+2,STR0066,oFontP,500,100,,ALIGN_H_LEFT)
		EndIf
		oPrinter:SayAlign(nLin,nColCalc2+2,STR0067,oFontP,500,100,,ALIGN_H_LEFT) //Informado
		oPrinter:SayAlign(nLin,nColInf2+2,STR0064,oFontP,500,100,,ALIGN_H_LEFT) //Codigo
		oPrinter:SayAlign(nLin,nColCod3+2,STR0065,oFontP,500,100,,ALIGN_H_LEFT) //Descricao
		If nImpHrs == 1 .Or. nImpHrs == 3 //Calculado		
			oPrinter:SayAlign(nLin,nColDesc3+2,STR0066,oFontP,500,100,,ALIGN_H_LEFT)
		EndIf
		oPrinter:SayAlign(nLin,nColCalc3+2,STR0067,oFontP,500,100,,ALIGN_H_LEFT)//Informado
	EndIf
Else
	// Monta o Cabecalho das Marcacoes							   
    cHtml +=									'<tr>' + CRLF
    cHtml +=										'<td colspan="' + AllTrim( Str( nColunas + 5 ) ) + '" class="etiquetas_1" bgcolor="#FAFBFC"><hr size="1"></td>' + CRLF
    cHtml +=									'</tr>' + CRLF
	cHtml +=									'<tr>' + CRLF
	cHtml +=											'<td class="etiquetas_1" bgcolor="#FAFBFC" nowrap>' + CRLF
    cHtml +=												'<div align="left">' + CRLF
	cHtml +=													STR0042 + CRLF	//'Data'
    cHtml +=												'</div>' + CRLF
	cHtml +=											'</td>' + CRLF
	cHtml +=											'<td class="etiquetas_1" bgcolor="#FAFBFC" nowrap>' + CRLF
    cHtml +=												'<div align="left">' + CRLF
	cHtml +=													STR0043 + CRLF	//'Dia'
    cHtml +=												'</div>' + CRLF
	cHtml +=											'</td>' + CRLF
	For nX := 1 To nVezes
		cHtml +=										'<td class="etiquetas_1" bgcolor="#FAFBFC" nowrap>' + CRLF
   		cHtml +=											'<div align="center">' + CRLF
    	cHtml +=												StrZero(nX,If(nX<10,1,2)) + STR0044 + CRLF	// '&#170;E.'
   		cHtml +=											'</div>' + CRLF
    	cHtml +=										'</td>' + CRLF
		cHtml +=										'<td class="etiquetas_1" bgcolor="#FAFBFC" nowrap>' + CRLF
   		cHtml +=											'<div align="center">' + CRLF
    	cHtml +=												StrZero(nX,If(nX<10,1,2)) + STR0045 + CRLF	//'&#170;S.'
   		cHtml +=											'</div>' + CRLF
    	cHtml +=										'</td>' + CRLF
	Next nX
	cHtml +=											'<td class="etiquetas_1" bgcolor="#FAFBFC" nowrap>' + CRLF
    cHtml +=												'<div align="left">' + CRLF
	cHtml +=													STR0046 + CRLF //'Observa&ccedil;&otilde;s
    cHtml +=												'</div>' + CRLF
	cHtml +=											'</td>' + CRLF
	cHtml +=											'<td class="etiquetas_1" bgcolor="#FAFBFC" nowrap>' + CRLF
    cHtml +=												'<div align="left">' + CRLF
	cHtml +=													STR0041 + CRLF	//'Motivo de Abono           Horas  Tipo da Marca&ccedil;&atilde;o'
    cHtml +=												'</div>' + CRLF
	cHtml +=											'</td>' + CRLF
	cHtml +=											'<td class="etiquetas_1" bgcolor="#FAFBFC" nowrap>' + CRLF
    cHtml +=												'<div align="left">' + CRLF
	cHtml +=													STR0047 + CRLF	//'Horas  Tipo da Marca&ccedil;&atilde;o'
    cHtml +=												'</div>' + CRLF
	cHtml +=											'</td>' + CRLF
    cHtml +=									'</tr>' + CRLF
    cHtml +=									'<tr>' + CRLF
    cHtml +=										'<td colspan="' + AllTrim( Str( nColunas + 5 ) ) + '" class="etiquetas_1" bgcolor="#FAFBFC"><hr size="1"></td>' + CRLF
    cHtml +=									'</tr>' + CRLF
EndIf
	
Return( cHtml )

/*
===============================================================================================================================
Programa----------: CarAboTot
Autor-------------: Totvs
Data da Criacao---: 08/08/1996
Descrição---------: Carrega os totais do SPC e os abonos
Parametros--------:   aTotais 
                      aAbonados 
                      aAbonosPer
                      lMvAbosEve
                      lMvSubAbAp
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function CarAboTot(aTotais As Array,aAbonados As Array,aAbonosPer As Array,lMvAbosEve As Logical,lMvSubAbAp As Logical)

Local aTotSpc		:= {} As Array//-- 1-SPC->PC_PD/2-SPC->PC_QUANTC/3-SPC->PC_QUANTI/4-SPC->PC_QTABONO
Local aCodAbono		:= {} As Array
Local cFilSP9   	:= xFilial( "SP9" , SRA->RA_FILIAL ) As Character
Local cFilSRV		:= xFilial( "SRV" , SRA->RA_FILIAL ) As Character
Local cImpHoras 	:= If(nImpHrs==1,"C",If(nImpHrs==2,"I","*")) As Character//-- Calc/Info/Ambas
Local cAutoriza 	:= If(nImpAut==1,"A",If(nImpAut==2,"N","*"))  As Character//-- Aut./N.Aut./Ambas
Local cAliasRes		:= If( lImpAcum , "SPL" , "SPB" ) As Character
Local cAliasApo		:= If( lImpAcum , "SPH" , "SPC" ) As Character
Local bAcessaSPC 	:= &("{ || " + ChkRH("PONR010","SPC","2") + "}") As Codeblock
Local bAcessaSPH 	:= &("{ || " + ChkRH("PONR010","SPH","2") + "}") As Codeblock
Local bAcessaSPB 	:= &("{ || " + ChkRH("PONR010","SPB","2") + "}") As Codeblock
Local bAcessaSPL 	:= &("{ || " + ChkRH("PONR010","SPL","2") + "}") As Codeblock
Local bAcessRes		:= If( lImpAcum , bAcessaSPH , bAcessaSPC ) As Codeblock
Local bAcessApo		:= If( lImpAcum , bAcessaSPL , bAcessaSPB ) As Codeblock
Local nColSpc   	:= 0.00 As Numeric
Local nCtSpc    	:= 0.00 As Numeric
Local nPass     	:= 0.00 As Numeric
Local nHorasCal 	:= 0.00 As Numeric
Local nHorasInf 	:= 0.00 As Numeric
Local nX        	:= 0.00 As Numeric

If ( lImpRes )
	//Totaliza Codigos a partir do Resultado	
	fTotalSPB(;
				@aTotSpc		,;
				SRA->RA_FILIAL	,;
				SRA->RA_Mat		,;
				dMarcIni		,;
				dMarcFim		,;
				bAcessRes		,;
				cAliasRes)
	//-- Converte as horas para sexagenal quando impressao For a partir do resultado
	If ( lSexagenal )	// Sexagenal
		For nCtSpc := 1 To Len(aTotSpc)
			For nColSpc := 2 To 4
				aTotSpc[nCtSpc,nColSpc]:=fConvHr(aTotSpc[nCtSpc,nColSpc],'H')
			Next nColSpc
		Next nCtSpc
	EndIf
EndIf

//Totaliza Codigos a partir do Movimento
fTotaliza(;
			@aTotSpc,;
			SRA->RA_FILIAL,;
			SRA->RA_MAT,;
			bAcessApo,;
			cAliasApo,;
			cAutoriza,;
			@aCodAbono,;
			aAbonosPer,;
			lMvAbosEve,;
			lMvSubAbAp;
	 	)
//-- Converte as horas para Centesimal quando impressao For a partir do apontamento
If !( lImpRes ) .And. !( lSexagenal ) // Centesimal
	For nCtSpc :=1 To Len(aTotSpc)
		For nColSpc :=2 To 4
			aTotSpc[nCtSpc,nColSpc]:=fConvHr(aTotSpc[nCtSpc,nColSpc],'D')
		Next nColSpc
	Next nCtSpc
EndIf

//-- Monta Array com Totais de Horas
If nImpHrs # 4  //-- Se solicitado para Listar Totais de Horas
	For nPass := 1 To Len(aTotSpc)
		If ( lImpRes ) //Impressao dos Resultados
			//-- Se encontrar o Codigo da Verba ou For um codigo de hora extra valido de acordo com o solicitado  
			If PosSrv( aTotSpc[nPass,1] , cFilSRV , NIL , 01 )
		   	   nHorasCal 	:= aTotSpc[nPass,2] //-- Calculado - Abonado
			   nHorasInf 	:= aTotSpc[nPass,3] //-- Informado
			   If nHorasCal > 0 .And. cImpHoras $ 'Cú*' .Or. nHorasInf > 0 .And. cImpHoras $ 'Iú*'
			  	  cHorCal := If(cImpHoras$'Cú*',Transform(nHorasCal, '@E 999.99'),Space(9)) + Space(1)
				  cHorInf := If(cImpHoras$'Iú*',Transform(nHorasInf, '@E 999.99'),Space(9))
				  aAdd(aTotais, { aTotSpc[nPass,1], SRV->RV_DESC , cHorCal, cHorInf } )
		  	   EndIf	
	        EndIf
		ElseIf PosSP9( aTotSpc[nPass,1] , cFilSP9 , NIL , 01 )
			//-- Impressao a Partir do Movimento
			nHorasCal 	:= aTotSpc[nPass,2] //-- Calculado - Abonado
			nHorasInf 	:= aTotSpc[nPass,3] //-- Informado
			If nHorasCal > 0 .And. cImpHoras $ 'Cú*' .Or. nHorasInf > 0 .And. cImpHoras $ 'Iú*'
				cHorCal := If(cImpHoras$'Cú*',Transform(nHorasCal, '@E 999.99'),Space(9)) + Space(1)
				cHorInf := If(cImpHoras$'Iú*',Transform(nHorasInf, '@E 999.99'),Space(9))
				aAdd(aTotais, { aTotSpc[nPass,1] , DescPDPon(aTotSpc[nPass,1], cFilSP9 ) , cHorCal, cHorInf } )
			EndIf  
		EndIf
	Next nPass
	
	//-- Acrescenta as informacoes referentes aos eventos associados aos motivos de abono
	//-- Condicoes: Se nao For Impressao de Resultados 
	//-- 			e Se For para Imprimir Horas Calculadas ou Ambas
	If !( lImpRes ) .And. (nImpHrs == 1 .Or. nImpHrs == 3) 
		For nX := 1 To Len(aCodAbono) 
			// Converte as horas para Centesimal
			If !( lSexagenal ) // Centesimal
				aCodAbono[nX,2]:=fConvHr(aCodAbono[nX,2],'D')
			EndIf
			aAdd(aTotais, { aCodAbono[nX,1] , DescPDPon(aCodAbono[nX,1], cFilSP9) , '  0,00'  , Transform(aCodAbono[nX,2],'@E 999.99') } )
		Next nX
	EndIf
EndIf

Return( NIL )

/*
===============================================================================================================================
Programa----------: fTotaliza
Autor-------------: Mauricio MR
Data da Criacao---: 08/08/1996
Descrição---------: Totalizar as Verbas do SPC (Apontamentos) /SPH (Acumulado)
Parametros--------:  aTotais		
					 cFil		
					 cMat		
					 bAcessa 	
					 cAlias		
					 cAutoriza	
					 aCodAbono	
					 aAbonosPer	
					 lMvAbosEve	
					 lMvSubAbAp 
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function fTotaliza(	aTotais		As Array,;
							cFil		As Character,;
							cMat		As Character,;
							bAcessa 	As Codeblock,;
							cAlias		As Character,;
							cAutoriza	As Character,;
							aCodAbono	As Array,;
							aAbonosPer	As Array,;
							lMvAbosEve	As Logical,;
							lMvSubAbAp 	As Logical;
						 )

Local aJustifica	:= {} As Array
Local cCodigo		:= "" As Character
Local cPrefix		:= SubStr(cAlias,-2)
Local cTno			:= "" As Character
Local cCodExtras	:= "" As Character
Local cEvento		:= "" As Character
Local cPD			:= "" As Character
Local cPDI			:= "" As Character
Local cCC			:= "" As Character
Local cTPMARCA		:= "" As Character
Local lExtra		:= .T. As Logical
Local lAbHoras		:= .T. As Logical
Local nQuaSpc		:= 0.00 As Numeric
Local nX			:= 0.00 As Numeric
Local nEfetAbono	:= 0.00 As Numeric
Local nQUANTC		:= 0.00 As Numeric
Local nQuanti		:= 0.00 As Numeric
Local nQTABONO		:= 0.00 As Numeric
Local lRemonta		:= .F. As Logical
Local lContinua		:= .F. As Logical

If ( cAlias )->(DBSeek( cFil + cMat ) )
	While (cAlias)->( !Eof() .And. cFil+cMat == &(cPrefix+"_FILIAL")+&(cPrefix+"_MAT") )
        
        dData	:= (cAlias)->(&(cPrefix+"_DATA"))  	//-- Data do Apontamento
        cPD		:= (cAlias)->(&(cPrefix+"_PD"))    	//-- Codigo do Evento
        cPDI	:= (cAlias)->(&(cPrefix+"_PDI"))     	//-- Codigo do Evento Informado
        nQUANTC	:= (cAlias)->(&(cPrefix+"_QUANTC"))  	//-- Quantidade Calculada pelo Apontamento
        nQuanti	:= (cAlias)->(&(cPrefix+"_QUANTI"))  	//-- Quantidade Informada
        nQTABONO:= (cAlias)->(&(cPrefix+"_QTABONO")) 	//-- Quantidade Abonada
		cTPMARCA:= (cAlias)->(&(cPrefix+"_TPMARCA")) 	//-- Tipo da Marcacao
		cCC		:= (cAlias)->(&(cPrefix+"_CC")) 		//-- Centro de Custos
		
		If (cAlias)->( !Eval(bAcessa) )
			(cAlias)->( DBSkip() )
			Loop
		EndIf
		
		If dData < dMarcIni .Or. dDATA > dMarcFim 
			(cAlias)->( DBSkip() )
			Loop
		EndIf
        
		// Obtem TODOS os ABONOS do Evento							   
        //-- Trata a Qtde de Abonos
        aJustifica 	:= {} //-- Reinicializa aJustifica
        nEfetAbono	:=	0.00
		If nQuanti == 0 .And. fAbonos( dData , cPD , NIL , @aJustifica , cTPMARCA , cCC , aAbonosPer ) > 0
            
            //-- Corre Todos os Abonos
			For nX := 1 To Len(aJustifica)
			    
			   // Cria Array Analitico de Abonos com horas Convertidas.		   
			   //-- Obtem a Quantidade de Horas Abonadas
				nQuaSpc := aJustifica[nX,2] //_QtAbono
				
				//-- Converte as horas Abonadas para Centesimal
				If !( lSexagenal ) // Centesimal
					nQuaSpc:= fConvHr(nQuaSpc,'D')
				EndIf
                
                //-- Cria Novo Elemento no array ANALITICO de Abonos 
				aAdd( aAbonados, {} )
				aAdd( aAbonados[Len(aAbonados)], dData )
				aAdd( aAbonados[Len(aAbonados)], DescAbono(aJustifica[nX,1],'C' , NIL , SRA->RA_FILIAL) )
				
				aAdd( aAbonados[Len(aAbonados)], StrTran(StrZero(nQuaSpc,5,2),'.',':') )
				aAdd( aAbonados[Len(aAbonados)], DescTpMarca(aBoxSPC,cTPMARCA))
				
				If !( lImpres )
					// Trata das Informacoes sobre o Evento Associado ao Motivo corrente 
					//-- Obtem Evento Associado
					cEvento := PosSP6( aJustifica[nX,1] , SRA->RA_FILIAL , "P6_EVENTO" , 01 )
					If ( lAbHoras := ( PosSP6( aJustifica[nX,1] , SRA->RA_FILIAL , "P6_ABHORAS" , 01 ) $ " S" ) )
					    //-- Se o motivo abona Horas
						If ( lAbHoras )
							If !Empty( cEvento )
								If ( nPos := aScan( aCodAbono, { |x| x[1] == cEvento } ) ) > 0
									aCodAbono[nPos,2] := __TimeSum(aCodAbono[nPos,2], aJustifica[nX,2] ) //_QtAbono
								Else
									aAdd(aCodAbono, {cEvento,  aJustifica[nX,2] }) // Codigo do Evento e Qtde Abonada
								EndIf
							Else 
								//==========================================================================
								// A T E N C A O: Neste Ponto deveriamos tratar o paramentro MV_ABOSEVE  
								//                no entanto, como ja havia a deducao abaixo e caso al-  
								//                guem migra-se da versao 609 com o cadastro de motivo   
								//                de abonos abonando horas mas sem o codigo, deixariamos 
								//                de tratar como antes e o cliente argumentaria alteracao
								//                de conceito.											
								//==========================================================================
							    //-- Se o motivo  nao possui abono associado
							    //-- Calcula o total de horas a abonar efetivamente
							    nEfetAbono:= __TimeSum(nEfetAbono, aJustifica[nX,2] ) //_QtAbono
							EndIf
						EndIf
					Else	
						//====================================================================
						// Se Motivo de Abono Nao Abona Horas e o Codigo do Evento Relaci
						// onado ao Abono nao Estiver Vazio, Eh como se fosse uma  altera
						// racao do Codigo de Evento. Ou seja, Vai para os Totais      as
						// Horas do Abono que serao subtraidas das Horas Calculadas (  Po
						// deriamos Chamar esta operacao de "Informados via Abono" ).	   
						// Para que esse processo seja feito o Parametro MV_SUBABAP  deve
						// ra ter o Conteudo igual a "S"								   
						//====================================================================
						If ( ( lMvSubAbAp ) .And. !Empty( cEvento ) )
						   //-- Se o motivo  nao possui abono associado
						   //-- Calcula o total de horas a abonar efetivamente 
						   If ( nPos := aScan( aCodAbono, { |x| x[1] == cEvento } ) ) > 0
								aCodAbono[nPos,2] := __TimeSum(aCodAbono[nPos,2], aJustifica[nX,2] ) //_QtAbono
						   Else
								aAdd(aCodAbono, {cEvento,  aJustifica[nX,2] }) // Codigo do Evento e Qtde Abonada
						   EndIf
						   //-- O total de horas acumulado em nEfetAbono sera deduzido do 
						   //-- total de horas apontadas.
						   nEfetAbono:= __TimeSum(nEfetAbono, aJustifica[nX,2] ) //_QtAbono
						EndIf
					EndIf
				EndIf	
			Next nX 
		EndIf
        
        If !( lImpres )
	        //-- Obtem o Codigo do Evento  (Informado ou Calculado)
	        cCodigo:= If(!Empty(cPDI), cPDI, cPD )
	         
	        //-- Obtem a posicao no Calendario para a Data
	        
	        If ( nPos 	:= aScan(aTabCalend, {|x| x[1] ==dDATA .And. x[4] == '1E' }) ) > 0 
			    //-- Obtem o Turno vigente na Data
			    cTno	:=	aTabCalend[nPos,14]  
			    //-- Carrega ou recupera os codigos correspondentes a horas extras na Data
			    cCodExtras	:= ''
			    lRemonta	:= .F.
				If ( cAutoriza $ "A|N" .And. !Empty(AllTrim(cPdi) ) ) 
					lRemonta	:= .T.
				EndIf	
			    CarExtAut( @cCodExtras , cTno , cAutoriza , lRemonta )
			    lExtra:=.F.
			    If cCodigo$cCodExtras 
			       lExtra:=.T.
			    EndIf   
			EndIf      
	                 
	        //-- Se o Evento For Alguma HE Solicitada (Autorizada ou Nao Autorizada) 
	        //-- Ou  Valido Qquer Evento (Autorizado e Nao Autorizado)
	        //-- OU  Evento possui um identificador correspondente a Evento Autorizado ou Nao Autorizado.
			//-- Ou  Evento e' referente a banco de horas 
			lContinua	:= .F.	
			If ( cAutoriza == "A" )
				If ( lExtra )
					lContinua	:= .T.
				EndIf	
			Else
				If ( lExtra .Or. cAutoriza == '*' .Or. (aScan(aId,{|aEvento| ( aEvento[1] == cCodigo .And. Right(aEvento[2],1) == cAutoriza ) .Or. ( aEvento[1] == cCodigo .And. cAutoriza == 'A' .And. Empty(aEvento[2]) .And. aEvento[4] == "S" ) }  ) > 0.00))
					lContinua	:= .T.
				EndIf
			EndIf
			
			If ( lContinua )
	           
		        //-- Procura em aTotais pelo acumulado do Evento Lido
				If ( nPos := aScan(aTotais,{|x| x[1] = cCodigo  }) ) > 0    
				   //-- Subtrai do evento a qtde de horas que efetivamente abona horas conforme motivo de abono
			       aTotais[nPos,2] := __TimeSum(aTotais[nPos,2],If(nQuanti>0, 0, __TimeSub(nQUANTC,nEfetAbono)))
				   aTotais[nPos,3] := __TimeSum(aTotais[nPos,3],nQuanti)
				   aTotais[nPos,4] := __TimeSum(aTotais[nPos,4],nQTABONO)
			    
				Else 
				   //-- Adiciona Evento em Acumulados
				   //-- Subtrai do evento a qtde de horas que efetivamente abona horas conforme motivo de abono
	           	   aAdd(aTotais,{cCodigo,If(nQuanti > 0, 0, __TimeSub(nQUANTC,nEfetAbono)), nQuanti,nQTABONO,lExtra })
	            EndIf
	        EndIf
        EndIf
		(cAlias)->( DBSkip() )
	End While
EndIf

Return( NIL )

/*
===============================================================================================================================
Programa----------: fTotalSPB
Autor-------------: Totvs
Data da Criacao---: 05/06/2000
Descrição---------: Totaliza eventos a partir do SPB.
Parametros--------: aTotais
                    cFil
                    cMat
                    dDataIni
                    dDataFim
                    bAcessa
                    cAlias 
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function fTotalSPB(aTotais As Array,cFil As Character,cMat As Character,dDataIni As Date,dDataFim As Date,bAcessa As Codeblock,cAlias As Character)

Local cPrefix := "" As Character

cPrefix		:= SubStr(cAlias,-2)

If ( cAlias )->( DBSeek( cFil + cMat ) )
	While (cAlias)->( !Eof() .And. cFil+cMat == &(cPrefix+"_FILIAL")+&(cPrefix+"_MAT") )

		If (cAlias)->( &(cPrefix+"_DATA") < dDataIni .Or. &(cPrefix+"_DATA") > dDataFim )
			(cAlias)->( DBSkip() )
			Loop
		EndIf

		If (cAlias)->( !Eval(bAcessa) )
			(cAlias)->( DBSkip() )
			Loop
		EndIf

		If ( nPos := aScan(aTotais,{|x| x[1] == (cAlias)->( &(cPrefix+"_PD") ) }) ) > 0
			aTotais[nPos,2] := aTotais[nPos,2] + (cAlias)->( &(cPrefix+"_HORAS") ) 
		Else
			If _nImpRef = 2
				DBSelectArea("SRV")
				SRV->(DBSetOrder(1))
				If SRV->(DBSeek(xFilial("SRV")+(cAlias)->( &(cPrefix+"_PD") )))
					If  SRV->RV_CODFOL <> '0050' .And. SRV->RV_CODFOL <> '0212' 
						aAdd(aTotais,{(cAlias)->( &(cPrefix+"_PD") ),(cAlias)->( &(cPrefix+"_HORAS") ),0,0 })
					EndIf
				Else
					aAdd(aTotais,{(cAlias)->( &(cPrefix+"_PD") ),(cAlias)->( &(cPrefix+"_HORAS") ),0,0 })
				EndIf
			Else
				aAdd(aTotais,{(cAlias)->( &(cPrefix+"_PD") ),(cAlias)->( &(cPrefix+"_HORAS") ),0,0 })
			EndIf
		EndIf
		(cAlias)->( DBSkip() )
	EndDo
EndIf

Return( NIL )

/*
===============================================================================================================================
Programa----------: LoadX3Box
Autor-------------: Mauricio MR 
Data da Criacao---: 10/12/2001
Descrição---------: Retorna array da ComboBox 
Parametros--------: cCampo - Nome do Campo 
Retorno-----------: aRet = Dados do combobox
===============================================================================================================================
*/
Static Function LoadX3Box(cCampo As Character)

Local aRet		:= {} As Array
Local nCont 	:= 0 As Numeric
Local nIgual	:= 0 As Numeric
Local cCbox		:= '' As Character
Local cString	:= '' As Character
Private aCols 	:= {} As Array
Private aHeader := {} As Array

If cCampo == "PC_TPMARCA"
   cCbox := PonRetOpcBox(06)  
Else //"PH_TPMARCA"
   cCbox := PonRetOpcBox(06)  
EndIf

//-- Opcao 1   |Opcao 2 |Opcao 3|Opcao 4
//-- 01=Amarelo;02=Preto;03=Azul;04=Vermelho  
//   | À->nIgual        À->nCont
//   À->cString: 01=Amarelo
//aRet:={{01,Amarelo},{02.Preto},...}

While !Empty(cCbox) 
   nCont:=AT(";",cCbox) 
   nIgual:=AT("=",cCbox)
   cString:=AllTrim(SubStr(cCbox,1,nCont-1)) //Opcao
   If nCont == 0
       aAdd(aRet,{SubStr(cString,1,nigual-1),SubStr(cString,nigual+1)})
      Exit
   Else
       aAdd(aRet,{SubStr(cString,1,nigual-1),SubStr(cString,nigual+1)})
   EndIf 
   cCbox:=SubStr(cCbox,nCont+1)
EndDo
   
Return( aRet )

/*
===============================================================================================================================
Programa----------: DescTpMarca
Autor-------------: Mauricio MR 
Data da Criacao---: 10/12/2001
Descrição---------: Retorna Descricao do Tipo da Marcacao  
Parametros--------: aBox     - Array Contendo as Opcoes do Combox Ja Carregadas³±±
                    cTpMarca - Tipo da Marcacao     
Retorno-----------: cRet = Descrição do Tipo da Marcação
===============================================================================================================================
*/
Static Function DescTpMarca(aBox As Array,cTpMarca As Character)

Local cRet		:= '' As Character
Local nTpMarca	:= 0 As Numeric
//-- SE Existirem Opcoes Realiza a Busca da Marcacao
If Len(aBox)>0
   nTpmarca:=aScan(aBox,{|xtp| xTp[1] == cTpMarca})
   cRet:=If(nTpMarca>0,aBox[nTpmarca,2],"")
EndIf

Return( cRet )

/*
===============================================================================================================================
Programa----------: Monta_Per
Autor-------------: Totvs 
Data da Criacao---: 10/12/2001
Descrição---------: Retorna períodos de apontamentos. 
Parametros--------: dDataIni 
                    dDataFim 
                    cFil 
                    cMat 
                    dIniAtu 
                    dFimAtu   
Retorno-----------: aPeriodos
===============================================================================================================================
*/
Static Function Monta_Per(dDataIni As Date,dDataFim As Date,cFil As Character,cMat As Character,dIniAtu As Date,dFimAtu As Date)

Local aPeriodos := {} As Array
Local cFilSPO	:= xFilial( "SPO" , cFil ) As Character
Local dAdmissa	:= SRA->RA_ADMISSA As Date
Local dPerIni   := Ctod("//") As Date
Local dPerFim   := Ctod("//") As Date

SPO->( DBSetOrder( 1 ) )
SPO->( DBSeek( cFilSPO , .F. ) )
While SPO->( !Eof() .And. PO_FILIAL == cFilSPO )
                       
    dPerIni := SPO->PO_DATAINI
    dPerFim := SPO->PO_DATAFIM  

    //-- Filtra Periodos de Apontamento a Serem considerados em funcao do Periodo Solicitado
    If dPerFim < dDataIni .Or. dPerIni > dDataFim                                                      
		SPO->( DBSkip() )  
		Loop  
    EndIf

    //-- Somente Considera Periodos de Apontamentos com Data Final Superior a Data de Admissao
    If ( dPerFim >= dAdmissa )
       aAdd( aPeriodos , { dPerIni , dPerFim , Max( dPerIni , dDataIni ) , Min( dPerFim , dDataFim ) } )
	Else
		Exit
	EndIf

	SPO->( DBSkip() )

EndDo

If ( aScan( aPeriodos , { |x| x[1] == dIniAtu .And. x[2] == dFimAtu } ) == 0.00 )
	dPerIni := dIniAtu
	dPerFim	:= dFimAtu 
	If !(dPerFim < dDataIni .Or. dPerIni > dDataFim)
		If ( dPerFim >= dAdmissa )
			aAdd(aPeriodos, { dPerIni, dPerFim, Max(dPerIni,dDataIni), Min(dPerFim,dDataFim) } )
		EndIf
    EndIf
EndIf

Return( aPeriodos )

/*
===============================================================================================================================
Programa----------: CarExtAut
Autor-------------: Mauricio MR  
Data da Criacao---: 24/05/2002
Descrição---------: Retorna Relacao de Horas Extras por Filial/Turno.
Parametros--------: cCodExtras --> String que Contem ou Contera os Codigos     
                    cTnoCad    --> Turno conforme o Dia                        
                    cAutoriza  --> "*" Horas Autorizadas/Nao Autorizadas        
                                   "A" Horas Autorizadas                        
                                   "N" Horas Nao Autorizadas  
Retorno-----------: lRet = .T. / .F.
===============================================================================================================================
*/
Static Function CarExtAut(cCodExtras As Character,cTnoCad As Character,cAutoriza As Character,lRemonta As Logical)

Local aTabExtra		:= {} As Array
Local cFilSP4		:= fFilFunc("SP4") As Character
Local cTno			:= "" As Character
Local lFound		:= .F. As Logical
Local lRet			:= .T. As Logical
Local nX			:= 0 As Numeric
Local naTabExtra	:= 0 As Numeric
Local ncTurno	    := 0.00 As Numeric

Static aExtrasTno	:= Nil As Array

If ( PCount() == 0.00 )

	aExtrasTno	:= NIL 

Else

	Default aExtrasTno	:= {} 
		
	//-- Procura Tabela (Filial + Turno corrente)
	If ( lFound	:= ( SP4->( DBSeek( cFilSP4 + cTnoCad , .F. ) ) ) )
	   cTno		:=	cTnoCad
	   lFound	:=	.T.
	Else      
	    //-- Procura Tabela (Filial)    
	    cTno	:= Space(Len(SP4->P4_TURNO))
		lFound	:= SP4->( DBSeek(  cFilSP4 + cTno , .F.) )
	EndIf    
	
	//-- Se Existe Tabela de HE
	If ( lFound )
	   //-- Verifica se a Tabela de HE para o Turno ainda nao foi carregada
   	   If (lRemonta) .Or. (ncTurno:=aScan(aExtrasTno,{|aTurno| aTurno[1]  == cFilSP4 .And. aTurno[2] == cTno} )) == 0.00
	      //-- Se nao Encontrou Carrega Tabela para Filial e Turno especificos
	      GetTabExtra( @aTabExtra , cFilSP4 , cTno , .F. , .F. )     
	      //-- Posiciona no inicio da Tabela de HE da Filial Solicitada
		  If !Empty(aTabExtra)
			  naTabExtra:=	Len(aTabExtra)
			  //-- Corre C¢digos de Hora Extra da Filial
			  For nX:=1 To naTabExtra
					//-- Se Ambos os Tipos de Eventos ou Autorizados
					If cAutoriza == '*' .Or. (cAutoriza == 'A' .And. !Empty(aTabExtra[nX,4]))
						cCodExtras += aTabExtra[nX,4]+'A' //-- Cod Autorizado                
					EndIf
					//-- Se Ambos os Tipos de Eventos ou Nao Autorizados					
					If cAutoriza == '*' .Or. (cAutoriza == 'N' .And. !Empty(aTabExtra[nX,5]))
						cCodExtras += aTabExtra[nX,5]+'N' //-- Cod Nao Autorizado                
					EndIf
			  Next nX
		  EndIf	  
		  //-- Cria Nova Relacao de Codigos Extras para o Turno Lido
		  aAdd(aExtrasTno,{cFilSP4,cTno,cCodExtras})
	    Else
	        //-- Recupera Tabela Anteriormente Lida
	        cCodExtras:=aExtrasTno[ncTurno,3] 
	    EndIf                    
	EndIf	
EndIf

Return( lRet )

/*
===============================================================================================================================
Programa----------: CarExtAut
Autor-------------: Mauricio MR  
Data da Criacao---: 24/05/2002
Descrição---------: Retorna Relacao de Eventos da Filial	
Parametros--------: cFil       --> Codigo da Filial desejada	
                    aId    	   --> Array com a Relacao	                      
                    cAutoriza  --> "*" Horas Autorizadas/Nao Autorizadas        
                                   "A" Horas Autorizadas                       
                                   "N" Horas Nao Autorizadas
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function CarId(cFil As Character,aId As Array,cAutoriza As Character)

Local nPos	:= 0.00 As Numeric

//-- Preenche o Array aCodAut com os Eventos (Menos DSR Mes Ant.)
SP9->( DBSeek( cFil , .T. ) )
While SP9->( !Eof() .And. cFil == P9_FILIAL ) 
	If ( ( Right(SP9->P9_IDPON,1) == cAutoriza ) .Or. ( cAutoriza == "*" ) )
		aAdd( aId , Array( 04 ) )
		nPos := Len( aId )
		aId[ nPos , 01 ] := SP9->P9_CODIGO	//-- Codigo do Evento 
		aId[ nPos , 02 ] := SP9->P9_IDPON 	//-- Identificador do Ponto 
		aId[ nPos , 03 ] := SP9->P9_CODFOL	//-- Codigo do da Verba Folha
		aId[ nPos , 04 ] := SP9->P9_BHORAS	//-- Evento para B.Horas
	EndIf
	SP9->( DBSkip() )
EndDo

Return( NIL )

/*
===============================================================================================================================
Programa----------: fGetApo
Autor-------------: Leandro Dr.
Data da Criacao---: 23/03/2015
Descrição---------: Retorna Apontamentos do funcionario.	
Parametros--------: aResult
                    dInicio
                    dFim
                    lImpAcum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function fGetApo(aResult As Array,dInicio As Date,dFim As Date,lImpAcum As Logical)

Local aArea		:= FWGetArea() As Array
Local cAliasQry	:= GetNextAlias() As Character
Local cWhere	:= "" As Character
Local cPrefixo	:= If(lImpAcum,"PH_","PC_") As Character
Local cJoinFil	:= "" As Character

cWhere += "%"
cWhere += cPrefixo + "FILIAL = '" + SRA->RA_FILIAL + "' AND "
cWhere += cPrefixo + "MAT = '" + SRA->RA_MAT + "' AND "
cWhere += cPrefixo + "DATA >= '" + DToS(dInicio) + "' AND "
cWhere += cPrefixo + "DATA <= '" + DToS(dFim) + "' "
cWhere += "%"

If lImpAcum
	cJoinFil:= "%" + FWJoinFilial("SPH", "SP9") + "%"

	BeginSql Alias cAliasQry
	
	 	SELECT             
			SPH.PH_DATA, SPH.PH_PD, SPH.PH_QUANTC, SPH.PH_QUANTI, SP9.P9_CLASEV, SP9.P9_IDPON,'' AS PC_PDI, SP9.P9_DESC
		FROM 
			%Table:SPH% SPH
		INNER JOIN %Table:SP9% SP9
		ON %exp:cJoinFil% AND SP9.%NotDel% AND SPH.PH_PD = SP9.P9_CODIGO		
		WHERE
			%Exp:cWhere% AND SPH.%NotDel%
		ORDER BY SPH.PH_DATA, SPH.PH_PD	
	
	EndSql 	
Else
	cJoinFil:= "%" + FWJoinFilial("SPC", "SP9") + "%"
	
	BeginSql Alias cAliasQry
	
	 	SELECT             
			SPC.PC_DATA, SPC.PC_PDI, SPC.PC_PD, SPC.PC_QUANTC, SPC.PC_QUANTI, SP9.P9_CLASEV, SP9.P9_IDPON, (Case WHEN SPC.PC_PDI <> ' ' THEN SP9.P9_DESC Else ''   END) AS  P9_DESC
		FROM 
			%Table:SPC% SPC
		INNER JOIN %Table:SP9% SP9
		ON %exp:cJoinFil% AND SP9.%NotDel% AND (Case WHEN SPC.PC_PDI <> ' ' THEN SPC.PC_PDI Else SPC.PC_PD   END) = SP9.P9_CODIGO			
		WHERE
			%Exp:cWhere%  AND SPC.%NotDel%
		ORDER BY SPC.PC_DATA, (Case WHEN SPC.PC_PDI <> ' ' THEN SPC.PC_PDI Else SPC.PC_PD   END)
	EndSql 	
EndIf

While !(cAliasQry)->(Eof())
	If (cAliasQry)->P9_CLASEV == "01" //Hora Extra
		(cAliasQry)->(aAdd(aResult,{&(cPrefixo+"DATA"),"1",If(&(cPrefixo+"QUANTI")>0,&(cPrefixo+"QUANTI"),&(cPrefixo+"QUANTC")),(cAliasQry)->P9_DESC}))
	ElseIf (cAliasQry)->P9_CLASEV $ "02*03*04*05" //Faltas/Atrasos/Saida antecipada
		(cAliasQry)->(aAdd(aResult,{&(cPrefixo+"DATA"),"2",If(&(cPrefixo+"QUANTI")>0,&(cPrefixo+"QUANTI"),&(cPrefixo+"QUANTC")),(cAliasQry)->P9_DESC}))
	ElseIf (cAliasQry)->P9_IDPON $ "003N*004A*027N*028A" //Adicional Noturno
		(cAliasQry)->(aAdd(aResult,{&(cPrefixo+"DATA"),"3",If(&(cPrefixo+"QUANTI")>0,&(cPrefixo+"QUANTI"),&(cPrefixo+"QUANTC")),(cAliasQry)->P9_DESC}))
	EndIf
   
   If !Empty(AllTrim((cAliasQry)->PC_PDI))  //Abono
		(cAliasQry)->(aAdd(aResultPDI,{&(cPrefixo+"DATA"),"3",If(&(cPrefixo+"QUANTI")>0,&(cPrefixo+"QUANTI"),&(cPrefixo+"QUANTC")),(cAliasQry)->P9_DESC}))
	EndIf	
	(cAliasQry)->(DBSkip())
EndDo

(cAliasQry)->(DBCloseArea())

FWRestArea(aArea)

Return

/*
===============================================================================================================================
Programa----------: fImpSign
Autor-------------: Leandro Dr.
Data da Criacao---: 23/03/2015
Descrição---------: Imprime espaço para assinatura do funcionario. 	
Parametros--------: oPrinter
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function fImpSign(oPrinter As Object)
	
oPrinter:SayAlign(nLinTot-40,nCol,Replicate("_",50),oFontP,nColTot,100,,ALIGN_H_LEFT)

oPrinter:SayAlign(nLinTot-30,nCol,STR0013,oFontP,nColTot,100,,ALIGN_H_LEFT) // 'Assinatura do Funcionario'

oPrinter:SayAlign(nLinTot-40,nCol+400,Replicate("_",50),oFontP,nColTot,100,,ALIGN_H_LEFT)

oPrinter:SayAlign(nLinTot-30,nCol+400,"GOIASMINAS INDUSTRIA DE LATICINIOS LTDA.",oFontP,nColTot,100,,ALIGN_H_LEFT) 	
	
Return

/*
===============================================================================================================================
Programa----------: Pnr010ImpBh
Autor-------------: Totvs
Data da Criacao---: 09/04/1996
Descrição---------: Calcula saldos.
Parametros--------: nSaldoAnt
                    nSaldoAtu
                    nCredito
                    nDebito
Retorno-----------: lRet = .T./ .F.
===============================================================================================================================
*/
Static Function Pnr010ImpBh(nSaldoAnt As Numeric,nSaldoAtu As Numeric,nCredito As Numeric,nDebito As Numeric)

Local aArea 	:= FWGetArea() As Array
Local nValor 	:= 0 As Numeric
Local lRet		:= .F. As Logical

nSaldoAnt	:= 0
nDebito		:= 0
nCredito	:= 0
nSaldoAtu	:= 0

DBSelectArea( "SPI" )
SPI->(DBSetOrder(2))
SPI->(DBSeek( SRA->RA_FILIAL + SRA->RA_MAT ))
While SPI->( !Eof() .And. PI_FILIAL+PI_MAT == SRA->( RA_FILIAL+RA_MAT ) )

	PosSP9(SPI->PI_PD,SRA->RA_FILIAL,"P9_TIPOCOD")
		// Totaliza Saldo Anterior
		If SPI->PI_DATA < dPerIni
			If !(SPI->PI_STATUS == 'B' .And. SPI->PI_DTBAIX < dPerIni)
				If (SPI->PI_STATUS == 'B' .And. SPI->PI_DTBAIX <= dPerFim)
					If SP9->P9_TIPOCOD $  "1*3"
						nValor := SPI->PI_QUANT
					   	If lSexagenal
							nSaldoAnt := __TimeSum(nSaldoAnt,nValor)  
							nSaldoAtu := __TimeSub(nSaldoAtu,nValor)
						Else
							nSaldoAnt := nSaldoAnt + fConvhR(nValor,"D") 
							nSaldoAtu := nSaldoAtu - fConvhR(nValor,"D") 
						EndIf 
					Else
						nValor := SPI->PI_QUANT
						If lSexagenal
							nSaldoAnt := __TimeSub(nSaldoAnt,nValor)
							nSaldoAtu := __TimeSum(nSaldoAtu,nValor)    
						Else
							nSaldoAnt := nSaldoAnt - fConvhR(nValor,"D")
							nSaldoAtu := nSaldoAtu + fConvhR(nValor,"D")  
						EndIf
					EndIf
				Else
					If SP9->P9_TIPOCOD $  "1*3"
						nValor := SPI->PI_QUANT
					   	If lSexagenal
							nSaldoAnt := __TimeSum(nSaldoAnt,nValor)  
						Else
							nSaldoAnt := nSaldoAnt + fConvhR(nValor,"D") 
						EndIf 
					Else
						nValor := SPI->PI_QUANT
						If lSexagenal
							nSaldoAnt := __TimeSub(nSaldoAnt,nValor)  
						Else
							nSaldoAnt := nSaldoAnt - fConvhR(nValor,"D") 
						EndIf
					EndIf
				EndIf
			EndIf
		ElseIf SPI->PI_DATA <= dPerFim
			If !(SPI->PI_STATUS == 'B' .And. SPI->PI_DTBAIX <= dPerFim)
				If SP9->P9_TIPOCOD $  "1*3"
					nValor := SPI->PI_QUANT
				   	If lSexagenal
						nCredito := __TimeSum(nCredito,nValor)  
					Else
						nCredito := nCredito + fConvhR(nValor,"D") 
					EndIf 
				Else
					nValor := SPI->PI_QUANT
					If lSexagenal
						nDebito := __TimeSum(nDebito,nValor)  
					Else
						nDebito := nDebito + fConvhR(nValor,"D") 
					EndIf
				EndIf
			EndIf	
		Else
			Exit
		EndIf

	SPI->(DBSkip())
EndDo

If nSaldoAnt <> 0 .Or. nCredito > 0 .Or. nDebito > 0
	lRet := .T.
	If lSexagenal
		nSaldoAtu := __TimeSum(nSaldoAtu, __TimeSub( __TimeSum( nSaldoAnt , nCredito ) , nDebito ))
	Else
		nSaldoAtu := ( nSaldoAtu + nSaldoAnt + nCredito ) - nDebito
	EndIf
EndIf

FWRestArea(aArea)

Return lRet

/*
===============================================================================================================================
Programa----------: Pnr010Afas
Autor-------------: M. Silveira
Data da Criacao---: 09/02/2017
Descrição---------: Busca a situacao e afastamentos do funcionario.
Parametros--------: dDtIniP
                    dDtFimP
                    aAfast
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function Pnr010Afas(dDtIniP As Date,dDtFimP As Date,aAfast As Array)

Local nX		:= 0 As Numeric
Local nReg		:= 0 As Numeric
Local cSitu		:= "" As Character
Local aAux  	:= {} As Array
Local aArea 	:= FWGetArea() As Array
Local aSitFunc  := RetSituacao( SRA->RA_FILIAL, SRA->RA_MAT, .F., dDtIniP  ) As Array

If Len(aSitFunc) > 0

	Do Case
		Case aSitFunc[1] == "A"
			cSitu := STR0090 //"AFASTADO"
		Case aSitFunc[1] == "F"
			cSitu := STR0091 //"FERIAS"
		Case aSitFunc[1] == "T"
			cSitu := STR0092 //"TRANSFERIDO"
		Case aSitFunc[1] == "D"
			cSitu := STR0093 //"DEMITIDO"
		OtherWise
			cSitu := STR0094 //"NORMAL"
	EndCase

	If aSitFunc[1] $ "A/F"
	
		aAfast	:= {}
		fRetAfas( dDtIniP, dDtFimP,,,,, @aAux )
		nReg := Len(aAux)
		
		If nReg > 0
			For nX := 1 To nReg

				//Considera somente os afastamentos compreendidos no periodo de apontamento
				If ( aAux[nX][3] >= dDtIniP .And. aAux[nX][3] <= dDtFimP ) .Or.;
				   ( aAux[nX][4] >= dDtIniP .And. aAux[nX][4] <= dDtFimP ) .Or.;
				   ( aAux[nX][4] >= dDtIniP .And. aAux[nX][3] >= dDtFimP ) .Or.;
				   ( aAux[nX][4] >= dDtFimp .And. aAux[nX][3] <= dDtInip ) .Or.;
				   ( Empty(aAux[nX][4])     .And. aAux[nX][3] <= dDtFimP )

					//Se tiver mais de um registro a situacao sai apenas na primeira linha e nas demais apenas o periodo
					If Empty( aAfast )
						aAdd( aAfast, { STR0088 + cSitu + " - " + STR0089 + DToC(aAux[nX][3]) + " a " + DToC(aAux[nX][4]) } ) //"Sit...: "#"Período: "
					Else
						aAdd( aAfast, { Space( Len(STR0088)+Len(cSitu)+3 ) + STR0089 + DToC(aAux[nX][3]) + " a " + DToC(aAux[nX][4]) } ) //"Período: "	
					EndIf
				EndIf
				
			Next nX
			
			If Empty( aAfast )
				cSitu := STR0094 //"NORMAL"
				aAdd( aAfast, { STR0088 + cSitu } )	
			EndIf
			
		EndIf
	Else
		aAdd( aAfast, { STR0088 + cSitu } )	
	EndIf
	
EndIf

FWRestArea( aArea )

Return

/*
===============================================================================================================================
Programa----------: RPON002MV
Autor-------------: Julio de Paula Paz
Data da Criacao---: 14/12/2018
Descrição---------: Função criada para retornar parêmentros, de forma que possa ser utilizados dentro loopings e ao mesmo 
                    tempo, seguir os padrões de desenvolvimento do no bo servidor lobo guará.
Parametros--------: _cParam = Parametro a ser lido
                    _cVarFil = filial passada para a função.
Retorno-----------: _cRet = conteúdo do parâmetro obtido pela função.
===============================================================================================================================
*/
Static Function RPON002MV(_cParam As Character,_cVarFil As Character)

Local _cRet := "" As Character

Begin Sequence
   // Alimenta as variaveis com o conteudo dos MV_'S correspondetes³
   If _cParam == "MV_ABOSEVE"
      _cRet	:= ( Upper(AllTrim(SuperGetMv("MV_ABOSEVE",NIL,"N",_cVarFil))) == "S" )	//--Verifica se Deduz as horas abonadas das horas do evento Sem a necessidade de informa o Codigo do Evento no motivo de abono que abona horas
   ElseIf _cParam == "MV_SUBABAP"
      _cRet	:= ( Upper(AllTrim(SuperGetMv("MV_SUBABAP",NIL,"N",_cVarFil))) == "S" )	//--Verifica se Quando Abono nao Abonar Horas e Possuir codigo de Evento, se devera Gera-lo em outro evento e abater suas horas das Horas Calculadas
   EndIf

End Sequence

Return _cRet

/*
===============================================================================================================================
Programa----------: RPON002OBS
Autor-------------: Igor Melgaço
Data da Criacao---: 06/11/2024
Descrição---------: Função para buscas a Descrição do P9_DESC qdo !Empty(PC_PDI)
Parametros--------: dData 
Retorno-----------: cResult 
===============================================================================================================================
*/
Static Function RPON002OBS(dData As Date)

Local i := 1 As Numeric
Local cResult := "" As Character

i := aScan(aResultPDI,{|x| x[1] = DToS(dData)})

If i > 0
   cResult := IIf(aResultPDI[i,3] > 0,AllTrim(Transform(aResultPDI[i,3],"@E 999,999.99")) + "Hrs ","") + AllTrim(aResultPDI[i,4])
EndIf

Return cResult
