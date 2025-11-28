/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |02/10/2019| Chamado 30614. Ajustes e campos novos no LayOut.
Igor Melgaço  |07/08/2023| Chamado 44623. Ajustes para impressão dos campos RQ_BCDEPBE e RQ_CTDEPBE.
Alex Wallauer |17/02/2025| Chamado 49915. Correção o Error.log: invalid field name in Alias SRA->RA_TPCONTR on 
              |          | GP020BUSCALIQ(GPER020.PRX) 22/01/2025 16:47:10
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "report.ch"

/*
===============================================================================================================================
Programa----------: RGPE012
Autor-------------: Darcio Ribeiro Sporl
Data da Criacao---: 07/10/2016
Descrição---------: Relatorio Líquidos Italac
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RGPE012()

 Local 	oReport , nI
 Private nPgQuant := 0
 Private nPgValor := 0


     // Interface de impressao
 If !Pergunte("GPE20R3",.T.)
    Return
 EndIf

 Private MV_PAR91:="SIM"
 Private MV_PAR92:="PAGAMENTO  PARA: "
 Private MV_PAR93:=10
 Private MVPAR01 :=MV_PAR01//SALVA
 Private MVPAR02 :=MV_PAR02//SALVA
 Private MVPAR03 :=MV_PAR03//SALVA
 bOk:={|| If(MV_PAR03 > 5 .And. MV_PAR03 < 16 ,.T., (U_ITMsg("Tamanho de fonte invalido ",'Atenção!',;
                                                             "Tamanho de fonte deve ser maior ou igual a 6 e menor ou igual a 15",1),.F.) ) }

 _aParAux:={}
 aAdd(_aParAux , { 02, "Mostrar Data de Pagamento"     , MV_PAR91 , {"SIM","NAO"} ,070 , "" , .T. } )
 aAdd(_aParAux , { 11, "Comentario Final Rel.-5 linhas", MV_PAR92 , ".T.",".T.",.T.})
 If MV_PAR19 == 2//SINTETICO
    aAdd(_aParAux , { 01, "Tamanho do Fonte Sintetico" , MV_PAR93 ,"99","","","",20,.T.}) // Tipo numérico
 Else
    bOk:={|| .T. }
 EndIf
 _aParRet:={}
 For nI := 1 To Len( _aParAux )
     aAdd( _aParRet , _aParAux[nI][03] )
 Next
 lMostraDTPGTP:=.T.
                 //aParametros, cTitle         , @aRet     ,[bOk]  , [ aButtons ] [ lCentered ] [ nPosX ] [ nPosy ] [ oDlgWizard ] [ cLoad ] [ lCanSave ] [ lUserSave ]
 If ParamBox( _aParAux , "Relacao de Liquidos" , @_aParRet , bOk   , /*aButtons*/,/*lCentered*/,/*nPosX*/,/*nPosy*/,/*oDlgWizard*/,/*cLoad*/,.T.         ,.T.          )
    lMostraDTPGTP:=(MV_PAR01="SIM")
    MV_PAR92:=MV_PAR02
    MV_PAR93:=MV_PAR03
 Else
    Return .F.
 EndIf

 oReport := RGPE012D()
 oReport:PrintDialog()

Return

/*
===============================================================================================================================
Programa----------: RGPE012
Autor-------------: Darcio Ribeiro Sporl
Data da Criacao---: 07/10/2016
Descrição---------: Definicao do relatorio.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RGPE012D()
 Local oReport
 Local oSection
 Local oTransp
 Local cDesc		:=	 "Relacao de Liquidos. Ser impresso de acordo com os parametros solicitados pelo usuario."
 Local aOrd	  	:=	{	"Filial+Bco+Nome",;
                          "Filial+Bco/Ag.+Cc+Mat",;
                         "Filial+Bco/Ag.+Mat",;
                         "Filial+Bco/Ag.+Cta",;
                         "Filial+Bco/Ag.+Cc+Nome",;
                         "Bco/Ag.+Mat",;
                         "Bco/Ag.+Cc+Mat",;
                         "Bco/Ag.+Nome",;
                         "Bco/Ag.+Cta",;
                         "Bco/Ag.+Cc+Nome",;
                         "Filial+Bco/Ag."}

 //Local cTitBcAg	:= GetSx3Cache("RA_BCDEPSA", "X3_TITULO")

 DEFINE REPORT oReport NAME "RGPE012" TITLE  "Relacao de Liquidos"  ACTION {|oReport| RGPE012P(oReport)} DESCRIPTION cDesc TOTAL IN COLUMN PAGE TOTAL IN COLUMN//PARAMETER "GPE20R3"

 If MV_PAR19 == 2//SINTETICO
     oReport:nFontBody  := MV_PAR93
     oReport:cFontBody  := "Courier New"
     oReport:nLineHeight:= 50 // Define a altura da linha.
     oReport:lBold      := .T.
     nSize:=30
 Else
     nSize:=20
 EndIf

 DEFINE Section oSection OF oReport TABLES "SRA" ORDERS aOrd TOTAL IN COLUMN TITLE "Liquidos"
 oSection:SetHeaderBreak(.T.)

 DEFINE CELL NAME "RA_FILIAL" 	OF oSection ALIAS "SRA"
 DEFINE CELL NAME "BANCO"	    OF oSection
 DEFINE CELL NAME "RA_BCDEPSA"	OF oSection ALIAS "SRA" SIZE 10 TITLE "Bco/Ag."
 DEFINE CELL NAME "RA_CTDEPSA"	OF oSection ALIAS "SRA" TITLE "Conta"
 DEFINE CELL NAME "RA_MAT" 		OF oSection ALIAS "SRA"
 DEFINE CELL NAME "RA_NOME" 		OF oSection ALIAS "SRA"
 DEFINE CELL NAME "RA_CIC" 		OF oSection ALIAS "SRA"
 DEFINE CELL NAME "VALOR" 		OF oSection ALIAS "   " ALIGN RIGHT TITLE "Valor" PICTURE "@E  99,999,999,999.99" SIZE nSize
 DEFINE CELL NAME "TIPOPAGTO"   	OF oSection ALIAS TITLE "Tp. Pagto"
 DEFINE CELL NAME "DATAPAGTO"   	OF oSection ALIAS TITLE "Dt. Pagto" PICTURE "@D"
 DEFINE CELL NAME "FUNCBENEF" 	OF oSection ALIAS TITLE "Func./Benef."
 DEFINE CELL NAME "RA_CC"      	OF oSection ALIAS "SRA"

 oSection:Cell("BANCO"):Disable()
 oSection:Cell("RA_CC"):Disable()

 // Total de Pagina
 DEFINE FUNCTION NAME "PAGQUANT" FROM oSection:Cell("RA_CTDEPSA") 	FUNCTION COUNT PRINT WHEN {|| oSection:GetFunction("PAGQUANT"):PageValue() > 0 } NO END Section NO END REPORT END PAGE
 DEFINE FUNCTION NAME "PAGVALOR" FROM oSection:Cell("VALOR")			FUNCTION SUM 	PRINT WHEN {|| oSection:GetFunction("PAGVALOR"):PageValue() > 0 } PICTURE "@E  99,999,999,999.99" NO END Section NO END REPORT END PAGE

 // Transportado Pagina Anterior
 DEFINE FUNCTION oTransp NAME "TPAGQUANT" FROM oSection:Cell("RA_CTDEPSA")	FUNCTION ONPRINT FORMULA {|| nPgQuant += oSection:GetFunction("PAGQUANT"):PageValue(), nPgQuant - oSection:GetFunction("PAGQUANT"):PageValue()} PRINT WHEN {|| nPgQuant <> oSection:GetFunction("PAGQUANT"):PageValue() .And. oSection:GetFunction("TPAGQUANT"):PageValue() > 0 } NO END Section NO END REPORT END PAGE
 DEFINE FUNCTION 		NAME "TPAGVALOR" FROM oSection:Cell("VALOR")		FUNCTION ONPRINT FORMULA {|| nPgValor += oSection:GetFunction("PAGVALOR"):PageValue(), nPgValor - oSection:GetFunction("PAGVALOR"):PageValue()} PRINT WHEN {|| nPgValor <> oSection:GetFunction("PAGVALOR"):PageValue() .And. oSection:GetFunction("TPAGVALOR"):PageValue() > 0 } PICTURE "@E  99,999,999,999.99"  NO END Section NO END REPORT END PAGE

 oTransp:SetTitle("TRANSPORTADO PAGINA ANTERIOR    ")
 oTransp:ShowHeader()

Return( oReport )

/*
===============================================================================================================================
Programa----------: RGPE012
Autor-------------: Darcio Ribeiro Sporl
Data da Criacao---: 07/10/2016
Descrição---------: Impressão do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RGPE012P(oReport)
 // Objeto
 Local oSection 	:= oReport:Section(1)
 Local oBreakCc
 Local oBreakAg
 Local oBreakbco
 Local oBreakFil
 Local oBreakUnN
 Local oBreakEFil
 Local aValBenef 	:= {}
 Local aCodFol  	:= {}
 Local cTitulo		:= ""
 Local cCabec		:= "                                     |-------  F U N C I O N A R I O  -------|                                   "
 Local cAliasX		:= ""
 Local cSitQuery	:= ""
 Local cCatQuery	:= ""
 Local cOrdem		:= ""
 Local cFiltro		:= ""
 Local cParBanco 	:= ""
 Local cParConta 	:= ""
 Local cRProc		:= ""
 Local cAuxPrc		:= ""
 Local cTitFil		:= ""
 Local cTitUnN		:= ""
 Local cTitEFil		:= ""
 Local cTitCc		:= ""
 //-- Numerico
 Local nOrdem		:= oSection:GetOrder()
 Local nReg			:= 0
 Local nValor    	:= 0
 Local nValor2    	:= 0
 Local nValBenef		:= 0
 Local nTamCod		:= 0
 Local lFuncTrf    	:= .F. , _nI //, nI

 Private nTamBcAg	:= GetSx3Cache( "RA_BCDEPSA" , "X3_TAMANHO" )
 Private cPicBcAg	:= GetSx3Cache( "RA_BCDEPSA" , "X3_PICTURE" )
 Private nTamBco		:= 0
 Private nTamAge		:= 0
 // String
 Private cUltAg 		:= ""
 //Private cBcoUlt  	:= ""
 Private cBcoAg		:= ""
 // Variaveis de Acesso do Usuario
 Private cAcessaSRA,cAcessaSRC,cAcessaSRD,cAcessaSRR,cAcessaSRG,cAcessaSRH,lImprFunci,aBenefCop // variaveis usadas na Gp020BuscaLiq(@nValor,@aValBenef)
 cAcessaSRA	:= &( " { || " + ChkRH( "RGPE012" , "SRA" , "2" ) + " } " )
 cAcessaSRC	:= &( " { || " + ChkRH( "RGPE012" , "SRC" , "2" ) + " } " )
 cAcessaSRD	:= &( " { || " + ChkRH( "RGPE012" , "SRD" , "2" ) + " } " )
 cAcessaSRR	:= &( " { || " + ChkRH( "RGPE012" , "SRR" , "2" ) + " } " )
 cAcessaSRG	:= &( " { || " + ChkRH( "RGPE012" , "SRG" , "2" ) + " } " )
 cAcessaSRH	:= &( " { || " + ChkRH( "RGPE012" , "SRH" , "2" ) + " } " )
 // Array
 Private aInfo			:= {}
 Private aRoteiros		:= {}// variavel usada na SelecRoteiros()

 Private lCorpManage	:= fIsCorpManage( FWGrpCompany() )	// Verifica se o cliente possui Gestão Corporativa no Grupo Logado

 //lMostraDTPGTP:= U_ITMsg("Mostrar data de Pagamento?",'Atenção!',,2,2,2)

 If !lMostraDTPGTP
    oSection:Cell("DATAPAGTO"):Disable()
 EndIf

 MV_PAR01:=MVPAR01//VOLTA
 MV_PAR02:=MVPAR02//VOLTA
 MV_PAR03:=MVPAR03//VOLTA
 MV_PAR11:=MV_PAR11
 MV_PAR12:=MV_PAR12
 MV_PAR13:=MV_PAR13
 MV_PAR14:=MV_PAR14
 MV_PAR15:=MV_PAR15
 MV_PAR16:=MV_PAR16
 MV_PAR17:=MV_PAR17
 MV_PAR18:=MV_PAR18
 MV_PAR19:=MV_PAR19
 MV_PAR20:=MV_PAR20
 MV_PAR21:=MV_PAR21

    If oReport:nDevice == 4 //excel
        oSection:Cell("RA_BCDEPSA"):cPicture := "@!"
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

    If Empty(cPicBcAg)
        cPicBcAg := '@R 999/99999'
    EndIf

    nTamBco := At( "/" , cPicBcAg ) - At( "9" , cPicBcAg )
    nTamAge := nTamBcAg - nTamBco

    // Carregando array aRoteiros com os roteiros selecionados
    // EM MVPAR01, MVPAR02 E MVPAR03.
    aRoteiros:={}
    If Len(MV_PAR01) > 0 .Or. Len(MV_PAR02) > 0 .Or. Len(MV_PAR03) > 0
        SelecRoteiros()
    Else
       Return .F.
    EndIf
    If Len(aRoteiros) < 1
       Return .F.
    EndIf

    lRescisao   := .F. 	// Definida para utilizacao em fBuscaLiq()
    ComConta	:= If(MV_PAR04 == 1,"C",(If(MV_PAR04 == 2,"S","A")))	                // Qto. a Conta Corrente
    cSituacao	:= MV_PAR11																// Situacao
    Quebloc		:= If(MV_PAR12 == 1,.T.,.F.)											// Totalizar por Filial
    cSalta		:= If(MV_PAR13 == 1,"S","N")											// Imprime Filial em Outra Pagina
    LstNome		:= If(MV_PAR14 == 1,"S","N")											// Mostrar Nomes dos Funcionarios
    dDataDe		:= MV_PAR15																// Data Pagamento De
    dDataAte	:= MV_PAR16																// Data Pagamento Ate
    cSaltaAg	:= If(MV_PAR17 == 1,"S","N")											// Quebra Pagina p/Agencia   Sim,Nao
    cTotAgen	:= If(MV_PAR18 == 1,"S","N")											// Totaliza por Agencia
    cTipoRel	:= If(MV_PAR19 == 1, "A" , "S" )										// Tipo de Relacao:1-Analitica, 2-Sintetica
    nFunBenAmb  := MV_PAR20  															// Imprimir : 1-Funcionarios  2-Beneficiarias  3-Ambos
    cCategoria	:= MV_PAR21 															// Categorias
    cProcessos	:= If( Empty(MV_PAR22),"", AllTrim(MV_PAR22) )							// Processos para Impressao
    cBanco    	:= MV_PAR07 															// Ban co
    cConta 		:= MV_PAR10																// Conta

    // Altera o titulo do relatorio
    cTitulo := "RELACAO DE LIQUIDOS"
    cTitulo += " ("+StrZero( nOrdem , 2 )+")"+ If(cTipoRel="A","Analitica","Sintetica")

    //------------------------------------------------------------
    // Total Centro de Custo
    //------------------------------------------------------------
    If (nOrdem == 2 .Or. nOrdem == 5 .Or. nOrdem == 7 .Or. nOrdem == 10)

        If (nOrdem == 2 .Or. nOrdem == 5) .And. Quebloc
            DEFINE BREAK oBreakCc OF oSection WHEN {|| oSection:Cell("RA_FILIAL"):GetText() + IIf(Empty(oSection:Cell("RA_BCDEPSA"):GetText()), Space(nTamBcAg), oSection:Cell("RA_BCDEPSA"):GetText()) + oSection:Cell("RA_CC"):GetText()}
            oBreakCc:OnBreak({|x,y|cTitCc:="Total Centro de Custo"+SubStr(x,Len(oSection:Cell("RA_FILIAL"):GetText())+nTamBcAg+1)})
        Else
            DEFINE BREAK oBreakCc OF oSection WHEN {|| IIf(Empty(oSection:Cell("RA_BCDEPSA"):GetText()), Space(nTamBcAg), oSection:Cell("RA_BCDEPSA"):GetText()) + oSection:Cell("RA_CC"):GetText()}
            oBreakCc:OnBreak({|x,y|cTitCc:="Total Centro de Custo"+SubStr(x,nTamBcAg+1)})
        EndIf

        DEFINE FUNCTION FROM oSection:Cell("RA_CTDEPSA") FUNCTION COUNT BREAK oBreakCc NO END Section NO END REPORT
        DEFINE FUNCTION FROM oSection:Cell("VALOR") 	 FUNCTION SUM   BREAK oBreakCc NO END Section NO END REPORT PICTURE "@E  99,999,999,999.99"
        //DEFINE FUNCTION FROM oSection:Cell("TIPOPAGTO")  FUNCTION MAX   BREAK oBreakCc NO END Section NO END REPORT
        //DEFINE FUNCTION FROM oSection:Cell("DATAPAGTO")  FUNCTION MIN   BREAK oBreakCc NO END Section NO END REPORT PICTURE "@D" FORMULA {||  }

        oBreakCc:SetTotalText({||cTitCc})
    EndIf

    //------------------------------------------------------------
    // Total Agencia
    //------------------------------------------------------------
    // Verifica se deseja totalizar por Agencia
    If cTotAgen == "S" .And. nOrdem <> 1
        If (nOrdem >= 2 .And. nOrdem <= 5) .And. Quebloc
            DEFINE BREAK oBreakAg OF oSection WHEN {|| oSection:Cell("RA_FILIAL"):GetText() + oSection:Cell("RA_BCDEPSA"):GetText()}
            oBreakAg:OnBreak({|x| cUltAg := SubStr(x,7,10) , cBcoAg := SubStr(x,3,3) })
        Else
            DEFINE BREAK oBreakAg OF oSection WHEN {|| oSection:Cell("RA_BCDEPSA"):GetText()}
            oBreakAg:OnBreak({|x| cUltAg := SubStr(x,7,10) , cBcoAg := SubStr(x,3,3) })
        EndIf

        oBreakAg:SetTotalText({|| "BCO/AG" + cBcoAg + "/" + cUltAg + " - " + Posicione("SA6",1,xFilial("SA6")+cBcoAg+cUltAg,"A6_NREDUZ") })
        If cSaltaAg == "S"
            oBreakAg:SetPageBreak(.T.)
        EndIf

        DEFINE FUNCTION FROM oSection:Cell("RA_CTDEPSA") FUNCTION COUNT BREAK oBreakAg NO END Section NO END REPORT
        DEFINE FUNCTION FROM oSection:Cell("VALOR") 	 FUNCTION SUM 	BREAK oBreakAg NO END Section NO END REPORT PICTURE "@E  99,999,999,999.99"
        //DEFINE FUNCTION FROM oSection:Cell("TIPOPAGTO")  FUNCTION MAX   BREAK oBreakAg NO END Section NO END REPORT
        //DEFINE FUNCTION FROM oSection:Cell("DATAPAGTO")  FUNCTION MIN   BREAK oBreakAg NO END Section NO END REPORT PICTURE "@D"
    EndIf

    //------------------------------------------------------------
    // Total Ban co
    //------------------------------------------------------------
    If (nOrdem >= 1 .And. nOrdem <= 5) .And. Quebloc
        DEFINE BREAK oBreakbco OF oSection WHEN {|| oSection:Cell("RA_FILIAL"):GetText() + oSection:Cell("BANCO"):GetText()}
        oBreakbco:OnBreak({|x|  cBanco := SubStr(x,3,3) })
    Else
        DEFINE BREAK oBreakbco OF oSection WHEN {|| oSection:Cell("BANCO"):GetText()}
        oBreakbco:OnBreak({|x|  cBanco := x })
    EndIf

    oBreakbco:SetTotalText({|| "Banco " + cBanco + " - " + Posicione("SX5",1,xFilial("SX5")+"K6"+cBanco,"X5_DESCRI") })
    oBreakbco:SetPageBreak(.F.)

    DEFINE FUNCTION FROM oSection:Cell("RA_CTDEPSA") FUNCTION COUNT BREAK oBreakbco NO END Section NO END REPORT
    DEFINE FUNCTION FROM oSection:Cell("VALOR") 	 FUNCTION SUM 	BREAK oBreakbco NO END Section NO END REPORT PICTURE "@E 99,999,999,999.99"
    //	DEFINE FUNCTION FROM oSection:Cell("TIPOPAGTO")  FUNCTION MAX   BREAK oBreakbco NO END Section NO END REPORT
    //	DEFINE FUNCTION FROM oSection:Cell("DATAPAGTO")  FUNCTION MIN   BREAK oBreakbco NO END Section NO END REPORT PICTURE "@D"

    //------------------------------------------------------------
    // Total Filial
    //------------------------------------------------------------
    // Verifica se deseja totalizar por Filial
    If Quebloc
        DEFINE BREAK oBreakFil OF oSection WHEN oSection:Cell("RA_FILIAL") TITLE "Total da Filial"
        If cSalta == "S"
            oBreakFil:SetPageBreak(.T.)
        EndIf

        oBreakFil:OnBreak({|x,y|cTitFil:="Total da Filial"+x})
        oBreakFil:SetTotalText({||cTitFil})

        DEFINE FUNCTION FROM oSection:Cell("RA_CTDEPSA") 	FUNCTION COUNT BREAK oBreakFil NO END Section NO END REPORT
        DEFINE FUNCTION FROM oSection:Cell("VALOR") 		FUNCTION SUM 	BREAK oBreakFil PICTURE "@E  99,999,999,999.99" NO END Section NO END REPORT

        If lCorpManage
            If lUniNeg
                DEFINE BREAK oBreakUnN OF oSection WHEN { || SubStr((cAliasX)->RA_FILIAL, nStartUnN, nUnNLength) }

                If cSalta == "S"
                    oBreakUnN:SetPageBreak(.T.)
                EndIf

                oBreakUnN:OnBreak({ |x, y| cTitUnN := "Total Unidade de Negocios:" + " " + x})
                oBreakUnN:SetTotalText({ || cTitUnN })
                oBreakUnN:SetTotalInLine(.F.)

                DEFINE FUNCTION NAME "FUNNCTDESPSA" FROM oSection:Cell("RA_CTDEPSA") FUNCTION COUNT BREAK oBreakUnN NO END Section NO END REPORT
                DEFINE FUNCTION NAME "FUNNVALOR" FROM oSection:Cell("VALOR") 		 FUNCTION SUM 	BREAK oBreakUnN PICTURE "@E  99,999,999,999.99" NO END Section NO END REPORT
            EndIf
            If lEmpFil
                DEFINE BREAK oBreakEFil OF oSection WHEN { || SubStr((cAliasX)->RA_FILIAL, nStartEmp, nEmpLength) }

                If cSalta == "S"
                    oBreakEFil:SetPageBreak(.T.)
                EndIf

                oBreakEFil:OnBreak({ |x,y| cTitEFil := "Total Empresa" + " " + x})
                oBreakEFil:SetTotalText({ || cTitEFil })
                oBreakEFil:SetTotalInLine(.F.)

                DEFINE FUNCTION NAME "FEFCTDESPSA" FROM oSection:Cell("RA_CTDEPSA") FUNCTION COUNT BREAK oBreakEFil NO END Section NO END REPORT
                DEFINE FUNCTION NAME "FEFVALOR" FROM oSection:Cell("VALOR") 		FUNCTION SUM 	BREAK oBreakEFil PICTURE "@E  99,999,999,999.99" NO END Section NO END REPORT
            EndIf
        EndIf

    EndIf

    //------------------------------------------------------------
    // Total Filial + Ban co
    //------------------------------------------------------------
    // Verifica se deseja totalizar por Filial e Ban co

    If nOrdem == 11
        DEFINE BREAK oBreakFil OF oSection WHEN {||"RA_FILIAL"+"RA_BCDEPSA"} TITLE "Total Filial"

        DEFINE FUNCTION NAME "CTDESPSA" FROM oSection:Cell("RA_CTDEPSA") FUNCTION COUNT BREAK oBreakFil NO END Section NO END REPORT
        DEFINE FUNCTION NAME "VALOR" FROM oSection:Cell("VALOR") FUNCTION SUM BREAK oBreakFil NO END Section NO END REPORT

        If cSalta == "S"
            oBreakFil:SetPageBreak(.T.)
        EndIf
    EndIf

    ////Define se devera ser impresso Funcionarios ou Beneficiarios
    DBSelectArea( "SRQ" )
    lImprFunci  := ( nFunBenAmb # 2 )// variavel usada na Gp020BuscaLiq(@nValor,@aValBenef)
    lImprBenef  := ( nFunBenAmb # 1 )// variavel usada na Gp020BuscaLiq(@nValor,@aValBenef)

    // Informa a nao existencia dos campos de bco/age/conta corrente
    If nFunBenAmb # 1 .And. !lImprBenef
        fAvisoBC()
        Return .F.
    EndIf

    If lImprBenef
        If nFunBenAmb == 2
            cCabec := "                                     -------  B E N E F I C I A R I O  -------                                   "
        Else
            cCabec := "                         -------  F U N C I O N A R I O / B E N E F I C I A R I O  -------                       "
        EndIf
    EndIf
    If !Empty(MV_PAR92)
       oReport:OnPageBreak({|| ImpRoda(oReport) })
    Else
       oReport:OnPageBreak({|| oReport:SkipLine(),oReport:PrintText(cCabec)})
    EndIf
    //Transforma parametros do tipo Range em expressao ADVPL para ser utilizada no filtro

    MakeSqlExpr("GPE20R3")
    // Faz filtro no arquivo...
    // Monta a string de Processos para Impressao
    If AllTrim(cProcessos) <> "*"
        cRProc := ""
        nTamCod := GetSx3Cache( "RCJ_CODIGO" , "X3_TAMANHO" )
        For nReg := 1 to Len(cProcessos) Step 5
            If Len(Subs(cProcessos,nReg,5)) < nTamCod
                cAuxPrc := Subs(cProcessos,nReg,5) + Space(nTamCod - Len(Subs(cProcessos,nReg,5)))
            Else
                cAuxPrc := Subs(cProcessos,nReg,5)
            EndIf
            cRProc += cAuxPrc
            If ( nReg+5 ) <= Len(cProcessos)
                cRProc += "','"
            EndIf
        Next X
        cFiltro += "SRA.RA_PROCES IN ('"+ cRProc + "') "
    EndIf

    // Adiciona no filtro o parametro tipo Range

    // Filial
    If !Empty(MV_PAR05)
        cFiltro += If( !Empty(cFiltro), " AND " + MV_PAR05, MV_PAR05 )
    EndIf

    // Centro de Custo
    If !Empty(MV_PAR06)
        cFiltro += If( !Empty(cFiltro), " AND  " + MV_PAR06, MV_PAR06 )
    EndIf

    // Ban co/Ag
    If !Empty(MV_PAR07)
        cFiltro += If( !Empty(cFiltro), " AND"  + MV_PAR07, MV_PAR07 )
    EndIf

    // Matricula
    If !Empty(MV_PAR08)
        cFiltro += If( !Empty(cFiltro), " AND " + MV_PAR08, MV_PAR08 )
    EndIf

    // Nome
    If !Empty(MV_PAR09)
        cFiltro += If( !Empty(cFiltro), " AND " + MV_PAR09, MV_PAR09 )
    EndIf

    // Conta Corrente
    If !Empty(MV_PAR10)
        cFiltro += If( !Empty(cFiltro), " AND " + MV_PAR10, MV_PAR10 )
    EndIf

    cFiltro := If( !Empty(cFiltro), "% " + cFiltro + " AND %", "%%" )

    // Neste caso foi utilizado o alias fixo com o mesmo nome da tabela (e nao GetNextAlias, conforme o
    // padrao de programacao), pois neste relatorio existe chamadas para outras funcoes e essas funcoes
    // utilizam sempre "SRA".
    cAliasX := GetNextAlias()//Então é so por o recno no select e usar o DBGoTo para prodicionar no SRA
    // Modifica variaveis para a Query
    For nReg:=1 to Len(cSituacao)
        cSitQuery += "'"+Subs(cSituacao,nReg,1)+"'"
        If ( nReg+1 ) <= Len(cSituacao)
            cSitQuery += ","
        EndIf
    Next nReg
    cSitQuery := "%" + cSitQuery + "%"

    cCatQuery := ""
    For nReg:=1 to Len(cCategoria)
        cCatQuery += "'"+Subs(cCategoria,nReg,1)+"'"
        If ( nReg+1 ) <= Len(cCategoria)
            cCatQuery += ","
        EndIf
    Next nReg
    cCatQuery := "%" + cCatQuery + "%"

    If nOrdem == 1
        If Quebloc
            cOrdem += "%RA_FILIAL, SubStr(RA_BCDEPSA,1,3), RA_NOME%"
        Else
            cOrdem += "%SubStr(RA_BCDEPSA,1,3), RA_FILIAL, RA_NOME%"
        EndIf
    ElseIf nOrdem == 2
        If Quebloc
            cOrdem += "%RA_FILIAL, SubStr(RA_BCDEPSA,1,3), RA_CC, RA_MAT%"
        Else
            cOrdem += "%SubStr(RA_BCDEPSA,1,3), RA_FILIAL, RA_CC, RA_MAT%"
        EndIf
    ElseIf nOrdem == 3
        If Quebloc
            cOrdem += "%RA_FILIAL, SubStr(RA_BCDEPSA,1,3),RA_MAT%"
        Else
            cOrdem += "%SubStr(RA_BCDEPSA,1,3), RA_FILIAL, RA_MAT%"
        EndIf
    ElseIf nOrdem == 4
        If Quebloc
            cOrdem += "%RA_FILIAl, SubStr(RA_BCDEPSA,1,3), RA_CTDEPSA%"
        Else
            cOrdem += "%SubStr(RA_BCDEPSA,1,3), RA_FILIAl, RA_CTDEPSA%"
        EndIf
    ElseIf nOrdem == 5
        If Quebloc
            cOrdem += "%RA_FILIAL, SubStr(RA_BCDEPSA,1,3), RA_CC, RA_NOME%"
        Else
            cOrdem += "%SubStr(RA_BCDEPSA,1,3), RA_FILIAL, RA_CC, RA_NOME%"
        EndIf
    ElseIf nOrdem == 6
        cOrdem += "%SubStr(RA_BCDEPSA,1,3), RA_FILIAL, RA_NOME%"
    ElseIf nOrdem == 7
        cOrdem += "%SubStr(RA_BCDEPSA,1,3), RA_CC, RA_FILIAL, RA_MAT%"
    ElseIf nOrdem == 8
        cOrdem += "%SubStr(RA_BCDEPSA,1,3), RA_FILIAL, RA_NOME%"
    ElseIf nOrdem == 9
        cOrdem += "%SubStr(RA_BCDEPSA,1,3), RA_FILIAL, RA_CTDEPSA%"
    ElseIf nOrdem == 10
        cOrdem += "%SubStr(RA_BCDEPSA,1,3), RA_CC, RA_FILIAL, RA_NOME%"
    ElseIf nOrdem == 11
        cOrdem += "%RA_FILIAL, SubStr(RA_BCDEPSA,1,3)%"
    EndIf

    //NAO RETIRAR ESTA LINHA
    //Este relatorio abre a query abaixo com o nome de "SRA" e
    //como a tabela "SRA" eh utilizada em varios outros programas,
    //foi preciso fechar primeiro a area para depois poder utiliza-la.
    SRA->( DBCloseArea() )

    BeginSql alias cAliasX
        SELECT RA_FILIAL,RA_BCDEPSA,RA_CC,RA_MAT,RA_NOME,RA_CIC,RA_CTDEPSA, RA_SITFOLH,RA_AFASFGT,RA_RESCRAI,RA_PROCES, R_E_C_N_O_ RECSRA
        FROM %Table:SRA% SRA
        WHERE SRA.RA_SITFOLH IN (%exp:Upper(cSitQuery)%) AND
               SRA.RA_CATFUNC IN (%exp:Upper(cCatQuery)%) AND
               %exp:cFiltro%
               SRA.%notDel%
          ORDER BY %exp:cOrdem%
    EndSql

    // Prepara relatorio para executar a query gerada pelo Embedded SQL passando como
    // parametro a pergunta ou vetor com perguntas do tipo Range que foramadmin	 alterados
    // pela funcao MakeSqlExpr para serem adicionados a query

    FilAnt := Replicate("!", FWGETTAMFILIAL)

    // Define o total da regua da tela de processamento do relatorio
    DBSelectArea(cAliasX)
    Count to _nCont
    oReport:SetMeter(_ncont*2)
    (cAliasX)->(DBGoTop())

    // Incializa impressao
    oSection:Init(.F.)

    //Loop de montagem de array de dados
    _aimprime := {}

    _cTot:=AllTrim(Str(_nCont))
    _nTam:=Len(_cTot)+1
    _nConta:=0

    While (cAliasX)->( !Eof() )

        SRA->(DBGoTo((cAliasX)->RECSRA))

        oReport:IncMeter()
        _nConta++
        oReport:SetMsgPrint("1/2-Lendo Mat.: "+AllTrim(Str(_nConta,_nTam)) +" de "+ _cTot)

        // Verifica se o usuario cancelou a impressao do relatorio
        If oReport:Cancel()
            Exit
        EndIf

        nValor    	:= 0
        nValor2		:= 0
        aValBenef 	:= {}

        If (cAliasX)->RA_FILIAL # FilAnt
            If !Fp_CodFol(@aCodFol,(cAliasX)->RA_FILIAL) .Or. !fInfo(@aInfo,(cAliasX)->RA_FILIAL)
                Exit
            EndIf
            FilAnt := (cAliasX)->RA_FILIAL
        EndIf

        If !Empty(oSection:aUserFilter) .And. !Empty(oSection:aUserFilter[1,2]) .And. !(cAliasX)->&(oSection:aUserFilter[1,2])
            (cAliasX)->( DBSkip() )
            Loop
        EndIf

        // Consiste controle de acessos e filiais validas
        If !((cAliasX)->RA_FILIAL $ fValidFil()) .Or. !Eval(cAcessaSRA)
            (cAliasX)->( DBSkip() )
            Loop
        EndIf

        lFuncTrf := .F.
        // Verif. se Demitido esta dentro da Data de Pagamento do Parametro
        If (cAliasX)->RA_SITFOLH <> "T" //se estiver como "T", busca os valores. Senão, verifica se na transferência foi gravado como "D".
            If ((cAliasX)->RA_SITFOLH == "D")
                DBSelectArea("SRG")
                If DBSeek( (cAliasX)->(RA_FILIAL + RA_MAT )  )
                    While !( SRG->( Eof() ) )  .And. (cAliasX)->RA_FILIAL + (cAliasX)->RA_MAT ==  SRG->RG_FILIAL + SRG->RG_MAT
                        If SRG->RG_DATAHOM >= dDataDe .And. SRG->RG_DATAHOM <= dDataAte
                            lRescisao := .T.
                        EndIf
                        SRG->( DBSkip())
                    EndDo
                Else
                    //Antes de ir para o próximo funcionário, verificar se não é transferência
                    If (cAliasX)->RA_AFASFGT $ "N1/N2/N3"
                       lFuncTrf := .T.
                    ElseIf (cAliasX)->RA_RESCRAI $ "31/32"
                       lFuncTrf := .T.
                    EndIf
                    If !lFuncTrf
                        DBSelectArea("SRA")
                        (cAliasX)->( DBSkip() )
                        Loop
                    EndIf
                EndIf
            EndIf
        EndIf

        // Busca os valores de Liquido e beneficios
        Gp020BuscaLiq(@nValor,@aValBenef)

        // Consiste parametros de ban co e conta do funcionario
        // Se nFunBenAmb=2, apenas sera testado a Bco e conta do Beneficario

        If nFunBenAmb # 2 	.And.  ;	//Se nao For Beneficiario, testa Bco e Conta do Funcionario
           (( ComConta = "C" .And. (cAliasX)->RA_CTDEPSA == Space(Len((cAliasX)->RA_CTDEPSA)) .And. nFunBenAmb # 2) .Or.;
             ( ComConta = "S" .And. (cAliasX)->RA_CTDEPSA #  Space(Len((cAliasX)->RA_CTDEPSA)) .And. nFunBenAmb # 2))
            nValor := 0
        EndIf

        // Consiste parametros de ban co e conta do beneficiario
        // aValBenef: 1-Nome  2-Ban co  3-Conta  4-Verba  5-Valor  6-CPF
        If Len(aValBenef) > 0
            aBenefCop  := aClone(aValBenef)
            aValBenef  := {}

            If ( nFunBenAmb == 2 .Or. nFunBenAmb == 3)

                // Como as perguntes Ban co e Conta sao do tipo Range, para fazer o aEval no
                // array aBenefCop, foi preciso substituir os campos da expressao (pergunte range)
                // por X[2] ou X[3].
                // Ex.: Pergunte range tem o seguinte conteudo:
                //--			(((cAliasX)->RA_CTDEPSA >= '000000000001' .And. (cAliasX)->RA_CTDEPSA <= '999999999999'))
                //--      substituindo:
                //--			((X[3] >= '000000000001' .And. X[3] <= '999999999999'))
                MV_PAR07 := cBanco
                MV_PAR10 := cConta
                MakeAdvplExpr("GPE20R3")

                cParBanco := ""
                cParConta := ""

                cParBanco := StrTran(MV_PAR07, "RA_BCDEPSA","X[2]")
                cParConta := StrTran(MV_PAR10, "RA_CTDEPSA","X[3]")

                If ComConta == "C" 					// Beneficiario e  com Conta, testo a Conta
                    If !Empty(cParBanco) .And. !Empty(cParConta)
                        &('Aeval(aBenefCop, { |X| If(	( ' + cParBanco + ' ) .And. ( ' + cParConta + ' .And. !Empty(X[3]) ) , aAdd(aValBenef,X ), "" ) })')
                    ElseIf !Empty(cParBanco)
                        &('Aeval(aBenefCop, { |X| If(	( ' + cParBanco + ' ) .And. ( !Empty(X[3]) ) , aAdd(aValBenef,X ), "" ) })')
                    ElseIf !Empty(cParConta)
                        &('Aeval(aBenefCop, { |X| If(	( ' + cParConta + ' .And. !Empty(X[3]) ) , aAdd(aValBenef,X ), "" ) })')
                    Else
                        &('Aeval(aBenefCop, { |X| If(	( !Empty(X[3]) ) , aAdd(aValBenef,X ), "" ) })')
                    EndIf

                ElseIf ComConta == "S"				// Se For beneficiario,  sem  Conta
                    If !Empty(cParBanco)
                        &('Aeval(aBenefCop, { |X| If(	( ' + cParBanco + ' ) .And.  ( X[3] = Space( TamSX3("RQ_CTDEPBE")[1] )) , aAdd(aValBenef,X ), ""  )  })')
                    Else
                        &('Aeval(aBenefCop, { |X| If(	( X[3] = Space( TamSX3("RQ_CTDEPBE")[1] )) , aAdd(aValBenef,X ), ""  )  })')
                    EndIf

                ElseIf ComConta == "A"
                    If !Empty(cParBanco) .And. !Empty(cParConta)
                        &('Aeval(aBenefCop, { |X| If(	( 	( ' + cParBanco + ' ) .And. ( ' + cParConta + ' ) ) .Or. ( 	( ' + cParBanco + ' ) .And.  ( X[3] = Space( TamSX3("RQ_CTDEPBE")[1] )) ), aAdd(aValBenef,X ), ""  )  })')
                    ElseIf !Empty(cParBanco)
                        &('Aeval(aBenefCop, { |X| If(	( 	( ' + cParBanco + ' ) ) , aAdd(aValBenef,X ), ""  )  })')
                    ElseIf !Empty(cParConta)
                        &('Aeval(aBenefCop, { |X| If(	( 	( ' + cParConta + ' ) ), aAdd(aValBenef,X ), ""  )  })')
                    Else
                        &('Aeval(aBenefCop, { |X| aAdd(aValBenef,X ) })')
                    EndIf
                EndIf
            EndIf
        EndIf

        // 1 - Testa Com Conta
        // 2 - Testa Sem Conta
        // 3 - Testa se Valor == 0
        // 4 - Testa se beneficiario
        If	( nValor == 0 .And. Len(aValBenef) == 0 ) .Or. ;
            ( nFunBenAmb == 2 .And. Len(aValBenef) == 0)
            (cAliasX)->( DBSkip() )
            Loop
        EndIf

        nValBenef := 0
        If nValor > 0
            //Cria posição no array
            aAdd(_aimprime,{SRA->RA_FILIAL,;
                            SubStr(SRA->RA_BCDEPSA,1,3),;
                            SRA->RA_BCDEPSA,;
                            SRA->RA_CTDEPSA,;
                            SRA->RA_MAT,;
                            SRA->RA_NOME,;
                            SRA->RA_CIC,;
                            SRA->RA_CC,;
                            0,;
                            ""})


            // Alteracao do conteudo das colunas
            // Verifica o conteudo que sera impresso na coluna nome conforme parametro.
            If LstNome <> "S"
                // Atualiza campo nome
                _aimprime[Len(_aimprime)][6] := "***  N o m e   Oculto   ***   "
            EndIf

            // Atualiza campo Valor
            _aimprime[Len(_aimprime)][9] := nValor

            If Len(aValBenef) > 0
                _aimprime[Len(_aimprime)][10] := "-Func."
            EndIf

        EndIf

        // Impressao dos Beneficiarios
          For nReg := 1 To Len(aValBenef)
            If !Empty(aValBenef[nReg,1]) .And. aValBenef[nReg,5] > 0

                //Cria posição no array
                aAdd(_aimprime,{SRA->RA_FILIAL,;//01
                            SubStr(SRA->RA_BCDEPSA,1,3),;//02
                            SRA->RA_BCDEPSA,;   //03
                            SRA->RA_CTDEPSA,;   //04
                            SRA->RA_MAT,;	    //05
                            SRA->RA_NOME,;      //06
                            SRA->RA_CIC,;       //07
                            SRA->RA_CC,;        //08
                            0,;                 //09
                            ""})                //10


                // Alteracao do conteudo das colunas
                // Verifica o conteudo que sera impresso na coluna nome conforme parametro.
                // Atualiza campo nome
                If LstNome = "S"
                    _aimprime[Len(_aimprime)][6] := Subs(aValBenef[nReg,1],1,30)
                Else
                    _aimprime[Len(_aimprime)][6] := "***  N o m e   Oculto   ***   "
                EndIf

                // Atualiza campo Ban co
                _aimprime[Len(_aimprime)][3] := aValBenef[nReg,2]
                _aimprime[Len(_aimprime)][2] := SubStr(aValBenef[nReg,2],1,3)
                // Atualiza campo nome
                _aimprime[Len(_aimprime)][7] := aValBenef[nReg,6]
                // Atualiza campo Conta
                //_aimprime[Len(_aimprime)][8] := aValBenef[nReg,3]
                _aimprime[Len(_aimprime)][4] := aValBenef[nReg,3]
                // Atualiza campo Valor
                _aimprime[Len(_aimprime)][9] := aValBenef[nReg,5]

                _aimprime[Len(_aimprime)][10] := "-Benef."

            EndIf
        Next nReg

        (cAliasX)->( DBSkip() )
    EndDo

    //Reordena array de acordo com ordem escolhida
    If nOrdem == 1
        If Quebloc
            _aimprime := aSort(_aimprime,,,{|x,y| x[1] + x[2] + x[6] < y[1] + y[2] + y[6] })
        Else
            _aimprime := aSort(_aimprime,,,{|x,y| x[2] + x[1] + x[6] < y[2] + y[1] + y[6] })
        EndIf
    ElseIf nOrdem == 2
        If Quebloc
            _aimprime := aSort(_aimprime,,,{|x,y| x[1] + x[3] + x[5] < y[1] + y[3] + y[5] })
        Else
            _aimprime := aSort(_aimprime,,,{|x,y| x[3] + x[1] + x[5] < y[3] + y[1] + y[5] })
        EndIf
    ElseIf nOrdem == 3
        If Quebloc
            _aimprime := aSort(_aimprime,,,{|x,y| x[1] + x[3] + x[5] < y[1] + y[3] + y[5] })
        Else
            _aimprime := aSort(_aimprime,,,{|x,y| x[3] + x[1] + x[5] < y[3] + y[1] + y[5] })
        EndIf
    ElseIf nOrdem == 4
        If Quebloc
            _aimprime := aSort(_aimprime,,,{|x,y| x[1] + x[3] + x[8] < y[1] + y[3] + y[8] })
        Else
            _aimprime := aSort(_aimprime,,,{|x,y| x[3] + x[1] + x[6] < y[3] + y[1] + y[8] })
        EndIf
    ElseIf nOrdem == 5
        If Quebloc
            _aimprime := aSort(_aimprime,,,{|x,y| x[1] + x[3] + x[4] + x[6] < y[1] + y[3] + y[4] + y[6] })
        Else
            _aimprime := aSort(_aimprime,,,{|x,y| x[3] + x[1] + x[4] + x[6] < y[3] + y[1] + y[4] + y[6] })
        EndIf
    ElseIf nOrdem == 6
        _aimprime := aSort(_aimprime,,,{|x,y| x[3] + x[1] + x[6] < y[3] + y[1] + y[6] })
    ElseIf nOrdem == 7
        _aimprime := aSort(_aimprime,,,{|x,y| x[3] + x[4] + x[1] + x[5] < y[3] + y[4] + y[1] + y[5] })
    ElseIf nOrdem == 8
        _aimprime := aSort(_aimprime,,,{|x,y| x[3] + x[1] + x[6] < y[3] + y[1] + y[6] })
    ElseIf nOrdem == 9
        _aimprime := aSort(_aimprime,,,{|x,y| x[3] + x[1] + x[8] < y[3] + y[1] + y[8] })
    ElseIf nOrdem == 10
        _aimprime := aSort(_aimprime,,,{|x,y| x[3] + x[4] + x[1] + x[6] < y[3] + y[4] + y[1] + y[6] })
    ElseIf nOrdem == 11
        _aimprime := aSort(_aimprime,,,{|x,y| x[1] + x[3]  < y[1] + y[3]  })
    EndIf

    _cTot:=AllTrim(Str(Len(_aimprime)))
    _nTam:=Len(_cTot)+1
    _nConta:=0

    SRC->(DBSetOrder(8))//SRC->RC_FILIAL + SRC->RC_MAT + SRC->RC_PD + SRC->RC_ROTEIR
    SRH->(DBSetOrder(3))//SRH->RH_FILIAL + SRH->RH_MAT + SRH->RH_ROTEIR
    SRG->(DBSetOrder(2))//SRG->RG_FILIAL + SRG->RG_MAT + SRG->RG_ROTEIR
    SRD->(DBSetOrder(6))//SRD->RD_FILIAL + SRD->RD_MAT + SRD->RD_PD + SRD->RD_ROTEIR

    cRoteiro 	:= aRoteiros[1,1]
    //	cTipoRot 	:= aRoteiros[1,2]
    cVerbaBusca := aRoteiros[1,3]
    //Loop de impressão
    For _nI := 1 to Len(_aimprime)

        // Verifica se o usuario cancelou a impressao do relatorio
        If oReport:Cancel()
            Exit
        EndIf

        // Incrementa a regua da tela de processamento do relatorio
          oReport:IncMeter()
          _nConta++
        oReport:SetMsgPrint("2/2-Imprmindo Mat.: "+AllTrim(Str(_nConta,_nTam)) +" de "+ _cTot)

        If cTipoRel == "S"	// So Imprime Dados dos Funcionarios quando Relacao For Analitica.
            // Habilita a impressao das colunas
            oSection:SetHeaderBreak(.F.)
            oSection:Hide()
        EndIf

        oSection:Cell("RA_FILIAL" ):SetValue(_aimprime[_nI][01])
        oSection:Cell("RA_BCDEPSA"):SetValue(_aimprime[_nI][02])
        oSection:Cell("RA_BCDEPSA"):SetValue(_aimprime[_nI][03])
        oSection:Cell("RA_CTDEPSA"):SetValue(_aimprime[_nI][04])
        oSection:Cell("RA_MAT"    ):SetValue(_aimprime[_nI][05])
        oSection:Cell("RA_NOME"   ):SetValue(_aimprime[_nI][06])
        oSection:Cell("RA_CIC"    ):SetValue(_aimprime[_nI][07])
        oSection:Cell("RA_CC"     ):SetValue(_aimprime[_nI][08])
        oSection:Cell("VALOR"     ):SetValue(_aimprime[_nI][09])
        oSection:Cell("FUNCBENEF" ):SetValue(_aimprime[_nI][10])

        If Len(AllTrim(MV_PAR01+MV_PAR02+MV_PAR03)) > 3
            oSection:Cell("TIPOPAGTO"):SetValue(AllTrim(MV_PAR01+MV_PAR02+MV_PAR03))
        Else
            oSection:Cell("TIPOPAGTO"):SetValue(AllTrim(Posicione("SRY",1,xFilial("SRY")+cRoteiro,"RY_DESC")))
        EndIf

        If lMostraDTPGTP

            cFil_Mat:=_aimprime[_nI][1]+_aimprime[_nI][5]

            If SRH->(DBSeek( cFil_Mat + cRoteiro )) //DATA DAS FERIAS "131","132","FER"
                While SRH->(!Eof()) .And. AllTrim(cFil_Mat + cRoteiro) = AllTrim(SRH->RH_FILIAL + SRH->RH_MAT + SRH->RH_ROTEIR)
                    If (SRH->RH_DTRECIB >= dDataDe .And. SRH->RH_DTRECIB <= dDataAte )
                        oSection:Cell("DATAPAGTO"):SetValue(DToC(SRH->RH_DTRECIB))
                        Exit
                    EndIf
                    SRH->(DBSkip())
                EndDo
            EndIf

            If SRC->(DBSeek(cFil_Mat + cVerbaBusca + cRoteiro)) //DATA DAS FOLHA E 131
                While SRC->(!Eof()) .And. ( AllTrim(cFil_Mat+ cVerbaBusca + cRoteiro) = AllTrim(SRC->RC_FILIAL + SRC->RC_MAT + SRC->RC_PD + SRC->RC_ROTEIR) )
                    If SRC->RC_DATA >= dDataDe .And. SRC->RC_DATA <= dDataAte
                        oSection:Cell("DATAPAGTO"):SetValue(DToC(SRC->RC_DATA))
                        Exit
                    EndIf
                    SRC->(DBSkip())
                EndDo
            EndIf

            If SRG->(DBSeek( cFil_Mat + cRoteiro))//DATA DA RECISAO
                While SRG->(!Eof()) .And. ( AllTrim(cFil_Mat + cRoteiro) ) == ( AllTrim(SRG->RG_FILIAL + SRG->RG_MAT + SRG->RG_ROTEIR) )
                    If SRG->RG_DATAHOM >= dDataDe .And. SRG->RG_DATAHOM <= dDataAte
                        oSection:Cell("DATAPAGTO"):SetValue(DToC(SRG->RG_DATAHOM))
                        Exit
                    EndIf
                    SRG->(DBSkip())
                EndDo
            EndIf

            If SRD->(DBSeek(cFil_Mat+ cVerbaBusca + cRoteiro) )// MOVIMENTO FECHADO
                While !Eof() .And. ( AllTrim(cFil_Mat+ cVerbaBusca + cRoteiro) = AllTrim(SRD->RD_FILIAL + SRD->RD_MAT + SRD->RD_PD + SRD->RD_ROTEIR) )
                    If SRD->RD_DATPGT >= dDataDe .And. SRD->RD_DATPGT <= dDataAte
                        oSection:Cell("DATAPAGTO"):SetValue(DToC(SRD->RD_DATPGT))
                        Exit
                    EndIf
                    SRD->(DBSkip())
                EndDo
            EndIf
        EndIf

        oSection:PrintLine()

    Next _nI

    // Finaliza impressao inicializada pelo metodo Init
    oSection:Finish()

    SRC->(DBSetOrder(1))
    SRH->(DBSetOrder(1))
    SRG->(DBSetOrder(1))
    SRD->(DBSetOrder(1))

    (cAliasX)->(DBCloseArea())

Return( Nil )

Static Function ImpRoda(oReport)
 Local R

 For R := 1 TO MlCount(MV_PAR92,100)
    oReport:PrintText(MEMOLINE(MV_PAR92,100,R))
 Next

Return
