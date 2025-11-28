/*
=================================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
=================================================================================================================================
       Autor      |    Data    |                                             Motivo                                           
---------------------------------------------------------------------------------------------------------------------------------
Julio Paz         | 03/11/2022 | Criar nova versão relatório com ferramenta FWMSPRINTER e filtro p/sem comissão. Chamado 41516.
Julio Paz         | 09/01/2023 | Criar nova opção de filtro para imprimir apenas os Ger/Coord/Sup/Vend do filtro. Chamado 42471.
Lucas Borges      | 28/08/2024 | Incluída proteção na classe evitando error.log - Chamado 48313
Lucas Borges      | 22/04/2025 | Chamado 50505. Alterada a picture do CNPJ para contemplar campo alfanumérico
=================================================================================================================================
 Analista     - Programador  - Inicio   - Envio    - Chamado - Motivo da Alteração
===============================================================================================================================
Antonio Ramos - Julio Paz    - 11/04/25 - 24/04/25 - 50212   - Alterar o Relatório Extrato Comissão Vendedor Para Imprimir o Nome-Cargo-RG do Aprovador na Assinatura e Junto com o Valor Total.
===============================================================================================================================
*/
#Include "TOTVS.ch"      
#Include "RPTDEF.CH"
#Include "FWPrintSetup.ch"
/*
===============================================================================================================================
Programa----------: ROMS030
Autor-------------: Fabiano Dias
Data da Criacao---: 31/03/2011
===============================================================================================================================
Descrição---------: Relatorio para demonstrar os valores de comissao 
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ROMS030()
Local _nX 
Local _cDataIni 
Local _cDataFin 
Local _nMeses
Local _dDataRel 
Local _aParAux := {}
Local _aParRet := {}

Private _cPerg		:= "ROMS0302"

Private _oPrint		:= Nil
Private _oFont10	:= TFont():New( "Courier New"	,, 08 ,, .F. ,,,, .F. , .F. )
Private _oFont10b	:= TFont():New( "Courier New"	,, 08 ,, .T. ,,,, .F. , .F. )
Private _oFont11	:= TFont():New( "Courier New"	,, 09 ,, .F. ,,,, .F. , .F. )
Private _oFont11b	:= TFont():New( "Courier New"	,, 09 ,, .T. ,,,, .F. , .F. )
Private _oFont12b	:= TFont():New( "Courier New"	,, 10 ,, .T. ,,,, .F. , .F. )
Private _oFont14b	:= TFont():New( "Courier New"	,, 11 ,, .T. ,,,, .F. , .F. )
Private _oFont15b	:= TFont():New( "Helvetica"		,, 12 ,, .T. ,,,, .F. , .F. )
Private _oFont16b	:= TFont():New( "Helvetica"		,, 13 ,, .T. ,,,, .T. , .F. )

Private _nNumPag	:= 0
Private _nLinBox	:= 0
Private _nPosLin	:= 0100
Private _nColIni	:= 0100
Private _nColFim	:= 2250
Private _nLimPag	:= 3300
Private _nSpcLin	:= 0050 
Private _nAjsLin	:= 0010 //ajusta a altura de impressao dos dados do relatorio
Private _ntoti      := 0
Private _nni        := 0

Private _cTitCargo := "", _nTotRegs
Private _cAliasSA3 := GetNextAlias()  
Private _cCodRepSA3, _cTipoRepSA3  
Private _TitAssinatura := ""
Private _avenl := {}
Private _asupl := {}
Private _acoordl := {}
Private _agerenl := {}
Private _aGerNacio := {}
Private _alista := {}
Private _ccodi := ""
Private _cctipvi := ""
Private _nPagina := 0
Private _NomeRepr := ""
Private _nTotVComi := 0 
Private _nTotVINSS := 0
Private _nTotVIRRF := 0
Private _nTotVBase := 0
Private _nTotVBoni := 0
Private _nTotVReceb := 0

Private _cTipoVend   := ""
Private _aComGerenc  := {}
Private _aDadosRelac := {} 
Private _cMvMesAno   := ""

Private _aSimNao   := {'Sim','Nao'} As Array
Private _aTipoRel  := {'Analitico'  ,'Previa-Sintetic','Excel'    ,'Impresso Novo'} As Array
Private _aTipoRepr := {'Interno CLT','Externo PJ'     ,'Ambos'} As Array 

Begin Sequence

   _cTitCargo := "Repres/Superv/Coord/Geren/Geren Nac"  

   //If !Pergunte( _cPerg, .T. )
  
	//  U_ITMsg( 'Operação cancelada pelo usuário!' , 'Atenção!' , , 1)

   //Else           
   MV_PAR01 := Space(6)
   MV_PAR02 := Space(6)
   MV_PAR03 := Space(100)
   MV_PAR04 := Space(100)
   MV_PAR05 := Space(100)
   MV_PAR06 := Space(100)
   MV_PAR07 := Space(100)
   MV_PAR08 := " " // 'Sim','Nao'
   MV_PAR09 := " " // 'Analitico'  ,'Previa-Sintetic','Excel','Impresso Novo'
   MV_PAR10 := " " // 'Interno CLT','Externo PJ','Ambos'
   MV_PAR11 := " " // 'Sim','Nao'
   MV_PAR12 := " " // 'Sim','Nao'
   MV_PAR13 := Space(60)
   MV_PAR14 := Space(20)
   MV_PAR15 := Space(40)
   MV_PAR16 := Space(60) 

   aAdd( _aParAux , { 1 , "Mes/Ano Inicial "           , MV_PAR01, ""  , ""  , ""       , "" , 030 , .F. } )
   aAdd( _aParAux , { 1 , "Mes/Ano Final "             , MV_PAR02, ""  , ""  , ""       , "" , 030 , .F. } )
   aAdd( _aParAux , { 1 , "Gerente Nacional"            , MV_PAR03, "@!", ""  , 'SA3_04' , "" , 100 , .F. } )
   aAdd( _aParAux , { 1 , "Gerente "       	           , MV_PAR04, "@!", ""  , 'LSTGER' , "" , 100 , .F. } )
   aAdd( _aParAux , { 1 , "Coordenador "               , MV_PAR05, "@!", ""  , 'LSTSUP' , "" , 100 , .F. } )
   aAdd( _aParAux , { 1 , "Supervisor "                , MV_PAR06, "@!", ""  , 'LSTSUI' , "" , 100 , .F. } )
   aAdd( _aParAux , { 1 , "Representantes "            , MV_PAR07, "@!", ""  , 'LSTVEN' , "" , 100 , .F. } )
//---------------------------------------------------------------------------------------------------------------	  
   aAdd( _aParAux , { 2 , "Traz Hierarquia "           , MV_PAR08,_aSimNao  , 60 , '' , .T. } )
   aAdd( _aParAux , { 2 , "Tipo de Relatório "         , MV_PAR09,_aTipoRel , 60 , '' , .T. } )
   aAdd( _aParAux , { 2 , "Tipo de Representante "     , MV_PAR10,_aTipoRepr, 60 , '' , .T. } )
   aAdd( _aParAux , { 2 , "Imprime Comissões Zeradas " , MV_PAR11,_aSimNao  , 60 , '' , .T. } )
   aAdd( _aParAux , { 2 , "Imprime Hierarquia "        , MV_PAR12,_aSimNao  , 60 , '' , .T. } )
//----------------------------------------------------------------------------------------------------------------	  
   aAdd( _aParAux , { 1 , "Nome do Aprovador "         , MV_PAR13, "" , ""	, "" , ""          ,080      , .F. } )
   aAdd( _aParAux , { 1 , "RG do Aprovador "           , MV_PAR14 ,"" , ""	, "" , ""          ,040      , .F. } )
   aAdd( _aParAux , { 1 , "Cargo do Aprovador "        , MV_PAR15, "" , ""  , "" , ""          ,080      , .F. } )
   aAdd( _aParAux , { 1 , "Local e Data "              , MV_PAR16 ,"" , ""  , "" , ""          ,080      , .F. } )

   aAdd(_aParRet,"MV_PAR01") 
   aAdd(_aParRet,"MV_PAR02") 
   aAdd(_aParRet,"MV_PAR03") 
   aAdd(_aParRet,"MV_PAR04") 
   aAdd(_aParRet,"MV_PAR05") 
   aAdd(_aParRet,"MV_PAR06") 
   aAdd(_aParRet,"MV_PAR07") 
   aAdd(_aParRet,"MV_PAR08") 
   aAdd(_aParRet,"MV_PAR09") 	  	  
   aAdd(_aParRet,"MV_PAR10")
   aAdd(_aParRet,"MV_PAR11") 
   aAdd(_aParRet,"MV_PAR12")  
   aAdd(_aParRet,"MV_PAR13") 
   aAdd(_aParRet,"MV_PAR14") 
   aAdd(_aParRet,"MV_PAR15") 
   aAdd(_aParRet,"MV_PAR16") 

   If !ParamBox( _aParAux , "Opções de Filtro para a Impressão do Extrato." , @_aParRet,,, .T. , , , , , .T. , .T. )
      U_ITMsg( "Relatório cancelado pelo usuário!" , "Atenção!",,1 )

   Else 

	  If Empty(MV_PAR01) .Or. Empty(MV_PAR02)
	     MsgInfo("Favor preencher os parâmetros: Mes/Ano Inicial e Mes/Ano Final antes de imprimir este relatório.")
	     Break
      EndIf

      //===============================================================================
      // Emite a opção sintética do relatório, com base no programa ROMS029.
      //===============================================================================
      If MV_PAR09 == 'Previa-Sintetic' // 2  // 'Analitico'  ,'Previa-Sintetic','Excel','Impresso Novo'
         U_ROMS030T() // Gera relatório Prévia Sintético
         
         Break // Finaliza a emissão do relatório.

	  ElseIf MV_PAR09 == 'Excel' // 3  // 'Analitico'  ,'Previa-Sintetic','Excel','Impresso Novo'
         Processa( {|| ROMS030EXCEL()} , 'Gerando Dados do Relatório...' , 'Aguarde!' )

         Break // Finaliza a emissão do relatório.
	  
	  //ElseIf MV_PAR09 == 4 // Impresso Novo


      EndIf
   
	  //================================================================================
      // Emite a opção analitica do relatório.  
      //================================================================================
	  _nMeses := 0

	  If MV_PAR01 == MV_PAR02
         _nMeses := 1
	  Else 
         _cDataIni := "01/"+ SubStr(MV_PAR01,1,2) + "/" + SubStr(MV_PAR01,3,4)
	     _cDataFin := "01/"+ SubStr(MV_PAR02,1,2) + "/" + SubStr(MV_PAR02,3,4)
      EndIf 
      
	  _cMvMesAno := MV_PAR01 

	  If _nMeses == 1
	     U_ROMS030W()
	  Else   
	     _nMeses := DateDiffMonth( CTod(_cDataIni), Ctod(_cDataFin) )
		 
		 _dDataRel := Ctod(_cDataIni)
		 For _nX := 1 To (_nMeses + 1)
             U_ROMS030W()
 
			 _dDataRel := MonthSum( _dDataRel, 1 )
             _cMvMesAno := StrZero(Month(_dDataRel),2) + StrZero(Year(_dDataRel),4)
		 Next 
      EndIf 

   EndIf

End Sequence

If Select(_cAliasSA3) > 0  
   (_cAliasSA3)->( DBCloseArea() )
EndIf

Return

/*
===============================================================================================================================
Programa----------: ROMS030W
Autor-------------: Julio de Paula Paz
Data da Criacao---: 18/11/2021 
Descrição---------: Rotina para impressão do Relatório Comissão Extrato Vendedor Analítico
Parametros--------: Nenhum 
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ROMS030W()
Local _cCargo := ""
Local _aAgrupaA := {}, _aAgrupaB := {}, _aAgrupaC := {}, _aAgrupaD := {}, _aAgrupaE := {}, _aAgrupaNac := {} 
Local _nX, _nY, _lVinculado, _nJ, _nG 
Local _cCodGerNac,_aGerNC := {}

Begin Sequence 

      _avenl     := {}
      _asupl     := {}
      _acoordl   := {}
      _agerenl   := {}
      _aGerNacio := {}
      _alista    := {}

	  _cTipoVend   := ""
      _aComGerenc  := {}
      _aDadosRelac := {} 

      //================================================================================
      // Emite a opção analitica do relatório.  
      //----------------------------------------|
      // Instancia o objeto do relatório
      //================================================================================

	  If MV_PAR09 ==  "Impresso Novo" //4 // 'Analitico'  ,'Previa-Sintetic','Excel','Impresso Novo'
	     /*
         Device = "DISCO" = 1
         Device = "SPOOL" = 2
         Device = "EMAIL" = 3
         Device = "EXCEL" = 4
         Device = "HTML"  = 5
         Device = "PDF"   = 6
         */
/*
   lAdjustToLegacy := .F.
   lDisableSetup   := .T.
   cLocal          := "\spool"
    
   oPrinter := FwMsPrinter():New("exemplo.pdf", IMP_PDF, lAdjustToLegacy, cLocal, lDisableSetup, , , , , , .F., )
 
*/
		 //Criar objeto _oPrint com FWMSPRINTER()
                  //FWMsPrinter(): New (< cFilePrintert >, [ nDevice], [ lAdjustToLegacy], [ cPathInServer], [ lDisabeSetup ], [ lTReport], [ @oPrintSetup], [ cPrinter], [ lServer], [ lPDFAsPNG], [ lRaw], [ lViewPDF], [ nQtdCopy] )
	   //_oPrint := FWMsPrinter():New(_cFileName         , IMP_PDF   , .T.               , _cPathSrv       , .T.             ,            ,                ,            , .T. )
         //_oPrint:= FWMSPrinter():New("ROMS030.PDF"      , IMP_PDF   , .T.               ,"\SPOOL\"        , .T.             ,            ,                ,            , .T. )   // Ordem obrigátoria de configuração do relatório
		 
		 _oPrint:= FWMSPrinter():New("ROMS030.PDF"        , IMP_PDF   , .T.               ,"\SPOOL"        ,                 ,            ,                ,            , .T. )   // Ordem obrigátoria de configuração do relatório
         
		 If !(_oPrint:nModalResult == PD_OK)
			_oPrint:Deactivate() 
			Return
		EndIf
		 //_oPrint:Setup()
         //_oPrint:setDevice(2)
         _oPrint:SetPortrait()
         _oPrint:SetPaperSize(DMPAPER_A4)
		 _oPrint:SetMargin(0,0,0,0)
         _oPrint:cPathPDF := GetTempPath() // Caso seja utilizada impressão em IMP_PDF
		 _oPrint:SetViewPDF(.T.)    
		 _nLimPag	:= 2990   
	  Else  	
	     _nLimPag	:= 3300
         _oPrint:= TMSPrinter():New( "Extrato por Representante/Supervisor/Coordenador/Gerente/Gerente Nacional" )
         _oPrint:SetPortrait() 	// Modo Retrato
         _oPrint:SetPaperSize(9)	// Papel A4
	  EndIf 

	  //================================================================================
	  // Chama rotina principal com base no cadastro de vendedores.
	  //================================================================================
	  FWMsgRun(,{|| ROMS030QRY( _cAliasSA3, 8 ) },"Aguarde...", "Carregando dados de " + _cTitCargo + "...") 


	  (_cAliasSA3)->(DBGoTop())
		
	  //Carrega para arrays para reordenar     
	  While ! (_cAliasSA3)->(Eof()) 
	     _cCargo := "Z"
	   
	     If (_cAliasSA3)->A3_I_TIPV == "V"
	        _cCargo := "4"  
	     ElseIf (_cAliasSA3)->A3_I_TIPV == "S"
	        _cCargo := "3"
	     ElseIf (_cAliasSA3)->A3_I_TIPV == "C"
	        _cCargo := "2"
	     ElseIf (_cAliasSA3)->A3_I_TIPV == "G"
	        _cCargo := "1"
		 ElseIf (_cAliasSA3)->A3_I_TIPV == "N" 
	        _cCargo := "0"
	     EndIf

		 //==========================================================================================
         // O array _aAgrupaD armazena as principais informações dos Gerentes, Coordenadores,
         // Supervisores e Representantes filtrados pela query principal deste relatório.
         //==========================================================================================
	                  //      Código 1                  Tipo 2             Codigo Gerente 3        Codigo Coordenador 4     Código Supervisor 5    Tipo para Ordenação. 6 , SITUAÇAO   7    "Código Gerente Nacional 8"  "NOME DO REPRESENTANTE 9 "
	     aAdd(_aAgrupaD, {(_cAliasSA3)->A3_COD, (_cAliasSA3)->A3_I_TIPV, (_cAliasSA3)->A3_GEREN, (_cAliasSA3)->A3_SUPER, (_cAliasSA3)->A3_I_SUPE,  _cCargo                , "NAO GRAVADO", (_cAliasSA3)->A3_I_GERNC, (_cAliasSA3)->A3_NOME } )
	     //----------------------------------------------------------------------------------------------------------------------------------------------------------------//
                     //      Código 1                  Tipo 2              Codigo Gerente 3         Codigo Coordenador 4    Código Supervisor 5     Valor Comissão 6 , Valor Bonificação 7 , Pagto Devoluções 8
		             //      Código 1                  Tipo 2              Codigo Gerente 3         Codigo Coordenador 4    Código Supervisor 5    "Valor total recebido" 6 , "Valor total Comissão" 7 , "Valor total Devolvido" 8 , "Valor total devolvido comissão" 9 , "Valor total bonificação." 10   , "Valor total comissão bonificação. 11"  "Código Gerente Nacional 12"
	     aAdd(_aDadosRelac, {(_cAliasSA3)->A3_COD, (_cAliasSA3)->A3_I_TIPV, (_cAliasSA3)->A3_GEREN, (_cAliasSA3)->A3_SUPER, (_cAliasSA3)->A3_I_SUPE, 0                       , 0                        , 0                         , 0                                  , 0                               , 0                                    , (_cAliasSA3)->A3_I_GERNC })

		 If (_cAliasSA3)->A3_I_TIPV == "V"
		
			aAdd(_avenl,{(_cAliasSA3)->A3_COD,0})
			
		 ElseIf (_cAliasSA3)->A3_I_TIPV == "S"
		
			aAdd(_asupl,{(_cAliasSA3)->A3_COD,0})
			
		 ElseIf (_cAliasSA3)->A3_I_TIPV == "C"
		
			aAdd(_acoordl,{(_cAliasSA3)->A3_COD,0})
			
		 ElseIf (_cAliasSA3)->A3_I_TIPV == "G"
		
			aAdd(_agerenl,{(_cAliasSA3)->A3_COD,0})
		 
		 ElseIf (_cAliasSA3)->A3_I_TIPV == "N"  
		
			aAdd(_aGerNacio,{(_cAliasSA3)->A3_COD,0})	
			
		 EndIf

         _nX := aScan(_aGerNC, {|x| x[1] == (_cAliasSA3)->A3_I_GERNC })
		 If _nX == 0
            aAdd(_aGerNC, {(_cAliasSA3)->A3_I_GERNC,0})
		 EndIf

		 (_cAliasSA3)->(DBSkip())
		
	  EndDo

      aSort(_aAgrupaD, , , { | x,y | x[6]+ x[9] < y[6] + y[9] } ) 


      U_ROMS030E()
 
      If MV_PAR08 == "Sim" // 1  //traz hierarquia = SIM 
         //===================================================================================
         // Se a pergunta Mostra Hierarquiva of igual a Simm a ordenação 
	     // do relatório deve ser:
	     // GERENTE
         // -- CORDENADOR
         // ----SUPERVISOR
         // ------VENDEDOR 1
         // ------VENDEDOR 2
         // ------VENDEDOR 3
         // -----SUPERVISOR2
         // ------VENDEDOR1
         // ------VENDEDOR2
         // ----VENDEDOR1(NOS CASOS QUE NÃO TEM SUPERVISOR)
         // ----VENDEDOR2
         // GERENTE2.... ETC
         //===================================================================================
          
		 If Empty(_aGerNacio) 
		    _aGerNacio := AClone(_aGerNC)
		 EndIf 

         For _nG := 1 To Len(_aGerNacio) 
             
			 //==========================================================================================
			 // Grava o primeiro regristro da hierarquia, o gerente nacional.
			 //==========================================================================================
			 _cCodGerNac := _aGerNacio[_nG,1] 
			 For _nX := 1 To Len(_aAgrupaD)
			     If _cCodGerNac == _aAgrupaD[_nX,1]
				    _aAgrupaD[_nX,7] := "GRAVADO"
                    //aAdd(_aAgrupaA, _aAgrupaD[_nX] )   
					aAdd(_aAgrupaNac, _aAgrupaD[_nX] ) 
					Exit 
				 EndIf 
			 Next 

			 //==========================================================================================
			 // Processa os demais registros diferente de gerente nacional.
			 //==========================================================================================
             For _nX := 1 To Len(_aAgrupaD)

			     If ! Empty(_aAgrupaD[_nX,8]) .And. _aAgrupaD[_nX,8] <> _cCodGerNac // Se existir mais de um gerente nacional.
				    Loop
				 EndIf 

                 //==========================================================================================
                 // Neste trecho são armazenados no array _aAgrupaA todos os Coordenadores, Supervisores e
                 // Representantes que estão com os campos de vinculo a Gerente, Coordenadore e Supervisores
                 // vazios, ou seja, só possuem o campo código. Os Gerentes não são armazenados neste Array.
                 //==========================================================================================
                 If _aAgrupaD[_nX,2] <> "G" .And. Empty(_aAgrupaD[_nX,3]) .And. Empty(_aAgrupaD[_nX,4]) .And. Empty(_aAgrupaD[_nX,5]) 
                    _lVinculado := .F.
                    For _nY := 1 To Len(_aAgrupaD)
                        If _aAgrupaD[_nX,1]  == _aAgrupaD[_nY,3] .And. ! Empty(_aAgrupaD[_nY,3])               
                           _lVinculado := .T.
                        EndIf
               
                        If _aAgrupaD[_nX,1]  == _aAgrupaD[_nY,4] .And. ! Empty(_aAgrupaD[_nY,4])               
                           _lVinculado := .T.
                        EndIf
               
                        If _aAgrupaD[_nX,1]  == _aAgrupaD[_nY,5] .And. ! Empty(_aAgrupaD[_nY,5])               
                           _lVinculado := .T.
                        EndIf

                    Next
           
                    If ! _lVinculado 
                       _aAgrupaD[_nX,7] := "GRAVADO"
                       aAdd(_aAgrupaA, _aAgrupaD[_nX]) 
                    EndIf
                 EndIf
             Next
       
             //==========================================================================================
             // Neste trecho são gravados e agrupados no array _aAgrupaB todos os Coordenadores,
             // Supervisores e Representantes que só possuem vinculos a um determinado Gerente.
             // Os demais vinculos estão vazios. 
             //==========================================================================================
             For _nX := 1 To Len(_agerenl)
                 For _nY := 1 To Len(_aAgrupaD)

				     If ! Empty(_aAgrupaD[_nY,8]) .And. _aAgrupaD[_nY,8] <> _cCodGerNac  // Se existir mais de um gerente nacional.
				        Loop
				     EndIf 

                     If _agerenl[_nX,1] == _aAgrupaD[_nY,1] .And._aAgrupaD[_nY,7] == "GRAVADO"
                        Loop // Exit 
                     ElseIf _agerenl[_nX,1] == _aAgrupaD[_nY,1]
                  
                        //==========================================================================================
                        // Grava no array _aAgrupaB registro principal do Gerente.
                        //==========================================================================================
                        _aAgrupaD[_nY,7] := "GRAVADO"
                        aAdd(_aAgrupaB, _aAgrupaD[_nY]) 
                  
                        //==========================================================================================
                        // Grava no array _aAgrupaB os Coordenadores vinculados ao gerente.
                        //==========================================================================================
                        For _nJ := 1 To Len(_aAgrupaD)
                            If _aAgrupaD[_nJ,3] == _agerenl[_nX,1] .And._aAgrupaD[_nJ,7] <> "GRAVADO" .And. _aAgrupaD[_nJ,2] == "C"
                               _aAgrupaD[_nJ,7] := "GRAVADO"
                               aAdd(_aAgrupaB, _aAgrupaD[_nJ]) 
                            EndIf
                        Next
                  
                        //==========================================================================================
                        // Grava no array _aAgrupaB os Supervisores vinculados ao Gerente, mas sem vinculo a um
                        // Coordenador.
                        //==========================================================================================
                        For _nJ := 1 To Len(_aAgrupaD)                                                                                  // Coordenador                         Supervisor
                            If _aAgrupaD[_nJ,3] == _agerenl[_nX,1] .And._aAgrupaD[_nJ,7] <> "GRAVADO" .And. _aAgrupaD[_nJ,2] == "S" .And. Empty(_aAgrupaD[_nJ,4]) .And. Empty(_aAgrupaD[_nJ,5])
                               _aAgrupaD[_nJ,7] := "GRAVADO"
                               aAdd(_aAgrupaB, _aAgrupaD[_nJ]) 
                            EndIf
                        Next
                  
                        //==========================================================================================
                        // Grava no array _aAgrupaB os Representantes vinculado ao Gerente, mas sem vinculo a um
                        // Coordenador e a um Supervisor.
                        //==========================================================================================
                        For _nJ := 1 To Len(_aAgrupaD)                                                                                   // Coordenador                         Supervisor
                            If _aAgrupaD[_nJ,3] == _agerenl[_nX,1] .And._aAgrupaD[_nJ,7] <> "GRAVADO" .And. _aAgrupaD[_nJ,2] == "V" .And. Empty(_aAgrupaD[_nJ,4]) .And. Empty(_aAgrupaD[_nJ,5])
                               _aAgrupaD[_nJ,7] := "GRAVADO"
                               aAdd(_aAgrupaB, _aAgrupaD[_nJ]) 
                            EndIf
                        Next
                     EndIf
                 Next
             Next

             //==========================================================================================
             // Ordenada o array _aAgrupaA que possui os dados dos Coordenadores, Supervisores e 
             // Representantes que não possuem vinculos. E grava no array _aAgrupaC os dados do array
             // _aAgrupaA e no final grava os dados do array _aAgrupaB que possui os dados agrupados
             // dos Gerentes e dos Coordenadores, Supervisores e Representantes que só possuem vinculos
             // ao Gerente.
             //==========================================================================================
 	         //aSort(_aAgrupaA, , , { | x,y | x[6]+ x[1] < y[6] + y[1] } ) 
			 aSort(_aAgrupaA, , , { | x,y | x[6]+ x[9] < y[6] + y[9] } ) 
 	
             For _nX := 1 To Len(_aAgrupaA)
                 aAdd(_aAgrupaC, _aAgrupaA[_nX])
             Next
    
	         aSort(_aAgrupaB, , , { | x,y | x[6]+ x[9] < y[6] + y[9] } )  

             For _nX := 1 To Len(_aAgrupaB)
                 aAdd(_aAgrupaC, _aAgrupaB[_nX])
             Next

                          //      Código 1                  Tipo 2             Codigo Gerente 3        Codigo Coordenador 4     Código Supervisor 5    Tipo para Ordenação. 6 , SITUAÇAO   7
	         // aAdd(_aAgrupaD, {(_cAliasSA3)->A3_COD, (_cAliasSA3)->A3_I_TIPV, (_cAliasSA3)->A3_GEREN, (_cAliasSA3)->A3_SUPER, (_cAliasSA3)->A3_I_SUPE,  _cCargo                , "NAO GRAVADO"}) 

	         //==========================================================================================
             // Após gravar os dados no array _aAgrupaC, limpamos os conteúdos dos arrays _aAgrupaA e
             // _aAgrupaB para iniciar mais um agrupamento.
             // Neste trecho, os Supervisores e Representantes são vinculados ao Gerente e Coordenador
             // posicionado.
             //==========================================================================================
             _aAgrupaA := {}
             _aAgrupaB := {}
             For _nX := 1 To Len(_aAgrupaC)
                 //==========================================================================================
                 // Grava no incio do array _aAgrupaA os dados dos Coordenadores, Supervisores e 
                 // Representantes que não possuem nenhum vinculo.
                 //==========================================================================================
                          // Cod.Gerente                    Cod.Coordenador              Cod.Supervisor             Tipo
                 If Empty(_aAgrupaC[_nX, 3]) .And. Empty(_aAgrupaC[_nX, 4]) .And. Empty(_aAgrupaC[_nX, 5]) .And. _aAgrupaC[_nX, 2] <> 'G' 
                    _aAgrupaC[_nX,7] := "GRAVADO"
                    aAdd(_aAgrupaA, _aAgrupaC[_nX])
                 Else
                    //==========================================================================================
                    // Grava no array _aAgrupaA o registro do Coordenador vinculado ao Gerente posicionado.
                    //==========================================================================================
                    _aAgrupaC[_nX,7] := "GRAVADO"
                    aAdd(_aAgrupaA, _aAgrupaC[_nX])
               
                    //==========================================================================================
                    // Grava no array _aAgrupaA de forma agrupada, todos os Supervisores e Representantes
                    // Vinculados ao Gerente e Coordenador posicionado.
                    //==========================================================================================
                    For _nY := 1 To Len(_aAgrupaD)
                           //         Situacao                             Cod.Gerente                                    Cod. Coordenador                      Cod. Supervisor               
                        If _aAgrupaD[_nY,7] == "NAO GRAVADO" .And. _aAgrupaC[_nX, 3] == _aAgrupaD[_nY, 3] .And. _aAgrupaC[_nX, 1] == _aAgrupaD[_nY, 4] //.And. ! Empty(_aAgrupaC[_nX, 4]) .And. Empty(_aAgrupaC[_nX, 5])
                           _aAgrupaD[_nY,7] := "GRAVADO"
                           aAdd(_aAgrupaA, _aAgrupaD[_nY])
                        EndIf
                    Next
                 EndIf
             Next 
    
             _aAgrupaC := AClone(_aAgrupaA) 

             //==========================================================================================
             // O array _aAgrupaA é limpo para um novo agrupamento. 
             // Neste trecho os representantes são vinculados ao Gerente, Coordenador e Supervisor
             // posicionado.
             //==========================================================================================
             _aAgrupaA := {}
             For _nX := 1 To Len(_aAgrupaC)
                //==========================================================================================
                // Grava no incio do array _aAgrupaA os dados dos Coordenadores, Supervisores e 
                // Representantes que não possuem nenhum vinculo.
                //==========================================================================================
                      // Cod.Gerente                    Cod.Coordenador              Cod.Supervisor             Tipo
                If Empty(_aAgrupaC[_nX, 3]) .And. Empty(_aAgrupaC[_nX, 4]) .And. Empty(_aAgrupaC[_nX, 5]) .And. _aAgrupaC[_nX, 2] <> 'G' 
                   _aAgrupaC[_nX,7] := "GRAVADO"
                   aAdd(_aAgrupaA, _aAgrupaC[_nX])
                Else
                   //==========================================================================================
                   // Grava no array _aAgrupaA o registro do Supervisor vinculado ao Gerente e Coordenador 
                   // posicionado.
                   //==========================================================================================
                   _aAgrupaC[_nX,7] := "GRAVADO"
                   aAdd(_aAgrupaA, _aAgrupaC[_nX])
           
                   //==========================================================================================
                   // Grava no array _aAgrupaA de forma agrupada, todos os Representantes Representantes
                   // vinculados ao Gerente, Coordenador e Supervisor posicionado.
                   //==========================================================================================
                   For _nY := 1 To Len(_aAgrupaD)
                                  //         Situacao                             Cod.Gerente                                    Cod. Coordenador                      Cod. Supervisor               
                       If _aAgrupaD[_nY,7] == "NAO GRAVADO" .And. _aAgrupaC[_nX, 3] == _aAgrupaD[_nY, 3] .And. _aAgrupaC[_nX, 4] == _aAgrupaD[_nY, 4] .And. _aAgrupaC[_nX, 1] == _aAgrupaD[_nY, 5] // ! Empty(_aAgrupaC[_nX, 4]) .And. Empty(_aAgrupaC[_nX, 5])
                          _aAgrupaD[_nY,7] := "GRAVADO"
                          aAdd(_aAgrupaA, _aAgrupaD[_nY])
                       EndIf
                   Next
                EndIf
            Next 
    
	        _aAgrupaC := AClone(_aAgrupaA) 
    
           //==========================================================================================
           // Armazena em _aAgrupaE os dados salvos em _aAgrupaC, para poder repetir no mesmo processo
		   // para o próximo gerente nacional, caso exista mais de um.
		   //==========================================================================================
		   If Len(_aAgrupaNac) > 0  
              aAdd(_aAgrupaE, _aAgrupaNac[1])
		   EndIf

		   For _nX := 1 To Len(_aAgrupaC)
               aAdd(_aAgrupaE, _aAgrupaC[_nX]) 
           Next
   
		   _aAgrupaA   := {}
		   _aAgrupaB   := {}
		   _aAgrupaC   := {}
		   _aAgrupaNac := {}
	   Next 

	   _aAgrupaC := AClone(_aAgrupaE) 

       //==========================================================================================
       // Neste trecho os demais registros que não foram enquadrados nas regras de agrupamentos
       // acima, são acrescentados ao array _aAgrupaC.
       //==========================================================================================
       For _nX := 1 To Len(_aAgrupaD)
           If _aAgrupaD[_nX,7] == "NAO GRAVADO"
              aAdd(_aAgrupaC, _aAgrupaD[_nX]) 
           EndIf
       Next

     Else //traz hierarquia = NAO   
        //===================================================================================
        // Se a pergunta Mostra Hierarquia For Não, a ordenação do 
	    // relatório deve ser:
		// GERENTE NACIONAL1
		// GERENTE NACIONAL2
		// GERENTE NACIONAL3
	    // GERENTE1
        // GERENTE2
        // GERENTE3
        // COORDENADOR1
        // COORDENADOR2
        // COORDENADOR 3
        // SUPERVISOR1
        // SUPERVISOR2
        // SUPERVISOR3
        // REPRESENTANTE1
        // REPRESENTANTE2
        // REPRESENTANTE3
        //===================================================================================
      
        //===================================================================================
        // Neste trecho, os dados dos Gerentes, Cooordenadores, Supervisores e Representantes
        // são ordenados.
        //===================================================================================

        // Gerente Nacional - _aGerNacio
        aSort(_aGerNacio, , , { | x,y | x[1] < y[1] } )

        // Gerente - _aGerenl
        aSort(_aGerenl, , , { | x,y | x[1] < y[1] } )
        
        // Coordenador - _aCoordl
        aSort(_aCoordl, , , { | x,y | x[1] < y[1] } )
        
        // Supervisor - _aSupl
        aSort(_aSupl, , , { | x,y | x[1] < y[1] } )
        
        // Representante - _aVenl
        aSort(_aVenl, , , { | x,y | x[1] < y[1] } )
      
        //===================================================================================
        // No trecho a seguir, os dados dos Gerentes, Coordenadores, Supervisores e
        // Representantes são agrupados no array _aAgrupaC, seguindo esta mesma ordem de
        // agrupamento.
        //===================================================================================
        
		// Gerente Nacional
        _aAgrupaC := {}
        For _nX := 1 To Len(_aGerNacio)
            aAdd(_aAgrupaC, _aGerNacio[_nX])
        Next

        // Gerente
        //_aAgrupaC := {}
        For _nX := 1 To Len(_aGerenl)
            aAdd(_aAgrupaC, _aGerenl[_nX])
        Next
      
        // Coordenador
        For _nX := 1 To Len(_aCoordl)
            aAdd(_aAgrupaC, _aCoordl[_nx])
        Next
      
        // Supervisor
        For _nX := 1 To Len(_aSupl)
            aAdd(_aAgrupaC, _aSupl[_nX])
        Next
      
        // Representante
        For _nX := 1 To Len(_aVenl)
            aAdd(_aAgrupaC, _aVenl[_nX])
        Next
        
     EndIf  

     //=======================================================
     // Monta lista ordenada o array _aLista.
     //=======================================================
     //                     Código 1                  Tipo 2             Codigo Gerente 3        Codigo Coordenador 4     Código Supervisor 5    Tipo para Ordenação. 6 , SITUAÇAO   7
     // aAdd(_aAgrupaC, {(_cAliasSA3)->A3_COD, (_cAliasSA3)->A3_I_TIPV, (_cAliasSA3)->A3_GEREN, (_cAliasSA3)->A3_SUPER, (_cAliasSA3)->A3_I_SUPE,  _cCargo                , "NAO GRAVADO"}) 
	
     For _nX := 1 To Len(_aAgrupaC)
	     aAdd(_aLista,_aAgrupaC[_nX,1])
	
	     //Se existe gerente do registro e está na lista de gerentes não impressos coloca na lista e marca como impresso o gerente
	     _npos := aScan(_agerenl,{|aVal| aVal[1] == _aAgrupaC[_nX,1] .And. aVal[2] == 0})
			
	     If _npos > 0
	        _agerenl[_npos][2] := 1
	     EndIf
		
	     //Se existe coordendador do registro e está na lista de coordenadores não impressos coloca na lista e marca como impresso o coordenador
	     _npos := aScan(_acoordl,{|aVal| aVal[1] == _aAgrupaC[_nX,1] .And. aVal[2] == 0})
			
	     If _npos > 0
	        _acoordl[_npos][2] := 1
	     EndIf
		
	     //Se existe supervisor do registro e está na lista de supervisores não impressos coloca na lista e marca como impresso o supervisor
	     _npos := aScan(_asupl,{|aVal| aVal[1] == _aAgrupaC[_nX,1] .And. aVal[2] == 0})
			
	     If _npos > 0
		    _asupl[_npos][2] := 1
	     EndIf
     
     Next

	 _nni := 1
	
	 //================================================================================
	 // Imprime a tela inicial da parametrização do relatório
	 //================================================================================
     If MV_PAR09 == 'Impresso Novo' // 4 = "Impresso Novo" //4 // 'Analitico'  ,'Previa-Sintetic','Excel', Impresso Novo 	
        //--------------------------------------------------------------------------
		_oFont10	:= TFont():New( "Courier New"	,, 11 ,, .F. ,,,, .F. , .F. )
        _oFont10b	:= TFont():New( "Courier New"	,, 11 ,, .T. ,,,, .F. , .F. )
        _oFont11	:= TFont():New( "Courier New"	,, 12 ,, .F. ,,,, .F. , .F. )
        _oFont11b	:= TFont():New( "Courier New"	,, 12 ,, .T. ,,,, .F. , .F. )
        _oFont12b	:= TFont():New( "Courier New"	,, 13 ,, .T. ,,,, .F. , .F. )
        _oFont14b	:= TFont():New( "Courier New"	,, 15 ,, .T. ,,,, .F. , .F. )
        _oFont15b	:= TFont():New( "Helvetica"		,, 16 ,, .T. ,,,, .F. , .F. )
        _oFont16b	:= TFont():New( "Helvetica"		,, 17 ,, .T. ,,,, .T. , .F. )
        //--------------------------------------------------------------------------		
/*		_oFont10	:= TFont():New( "Courier New"	,, 10 ,, .F. ,,,, .F. , .F. )
        _oFont10b	:= TFont():New( "Courier New"	,, 10 ,, .T. ,,,, .F. , .F. )
        _oFont11	:= TFont():New( "Courier New"	,, 11 ,, .F. ,,,, .F. , .F. )
        _oFont11b	:= TFont():New( "Courier New"	,, 11 ,, .T. ,,,, .F. , .F. )
        _oFont12b	:= TFont():New( "Courier New"	,, 12 ,, .T. ,,,, .F. , .F. )
        _oFont14b	:= TFont():New( "Courier New"	,, 14 ,, .T. ,,,, .F. , .F. )
        _oFont15b	:= TFont():New( "Helvetica"		,, 15 ,, .T. ,,,, .F. , .F. )
        _oFont16b	:= TFont():New( "Helvetica"		,, 16 ,, .T. ,,,, .T. , .F. ) */
        //--------------------------------------------------------------------------
	    _nSpcLin := 38  // 0050  
	    _oPrint:StartPage()
        ROMS30RCAB( .F. )
	    ROMS030RIPP( _oPrint )
	 Else 
	    //-------------------------------------------------------------------------
        _oFont10	:= TFont():New( "Courier New"	,, 08 ,, .F. ,,,, .F. , .F. )
        _oFont10b	:= TFont():New( "Courier New"	,, 08 ,, .T. ,,,, .F. , .F. )
        _oFont11	:= TFont():New( "Courier New"	,, 09 ,, .F. ,,,, .F. , .F. )
        _oFont11b	:= TFont():New( "Courier New"	,, 09 ,, .T. ,,,, .F. , .F. )
        _oFont12b	:= TFont():New( "Courier New"	,, 10 ,, .T. ,,,, .F. , .F. )
        _oFont14b	:= TFont():New( "Courier New"	,, 11 ,, .T. ,,,, .F. , .F. )
        _oFont15b	:= TFont():New( "Helvetica"		,, 12 ,, .T. ,,,, .F. , .F. )
        _oFont16b	:= TFont():New( "Helvetica"		,, 13 ,, .T. ,,,, .T. , .F. )
		//-------------------------------------------------------------------------
	    ROMS030CAB( .F. )
	    ROMS030IPP( _oPrint )
	 EndIf 

	 _cTipoVend := ""
	
	 For _nX := 1 to Len(_alista) 
         _nni := _nX  
	
	     SA3->(DBSetOrder(1))
	     SA3->(DBSeek(xFilial("SA3")+_alista[_nni]))
	
	     _NomeRepr := SA3->A3_NOME
	    
		 If SA3->A3_I_TIPV == "V"
		
		    _cTitCargo := "Representante"
			
		 ElseIf SA3->A3_I_TIPV == "S"
		
		    _cTitCargo := "Supervisor"
			
		 ElseIf SA3->A3_I_TIPV == "C"
		
		    _cTitCargo := "Coordenador"
			
		 ElseIf SA3->A3_I_TIPV == "G"
		
		    _cTitCargo := "Gerente"
			
		 ElseIf SA3->A3_I_TIPV == "N"
		
		    _cTitCargo := "Gerente Nacional"
		 EndIf
		
		 _ccodi := _alista[_nni]
		 _cctipvi := SA3->A3_I_TIPV
		 _ntoti := Len(_alista)
		
         If MV_PAR09 == 'Analitico' // 1  // Relatório Analítico  // 'Analitico'  ,'Previa-Sintetic','Excel', // Impresso Novo 	
            //================================================================================
	        // Imprime a versão Analítica do relatório Extrato Unificado de Comissões.
	        //================================================================================
		    FWMsgRun( ,{|| ROMS030RUN() } , 'Aguarde...' , 'Processando ' + _cTitCargo + " " + StrZero(_nni,6) + ' de ' + StrZero(Len(_alista),6) + '...'   )
		 ElseIf MV_PAR09 == "Impresso Novo" // 4 // 'Analitico'  ,'Previa-Sintetic','Excel', // Impresso Novo 	
               FWMsgRun( ,{|| ROMS030RNI() } , 'Aguarde...' , 'Processando ' + _cTitCargo + " " + StrZero(_nni,6) + ' de ' + StrZero(Len(_alista),6) + '...'   )           
         EndIf
     Next
   	
     //================================================================================
     // Finaliza o relatório e chama a visualização
     //================================================================================
     _oPrint:Preview()	// Visualiza antes de Imprimir.

   //EndIf

End Sequence 

Return 

/*
===============================================================================================================================
Programa----------: ROMS030IPP
Autor-------------: Fabiano Dias
Data da Criacao---: 31/03/2011
Descrição---------: Rotina para impressão da página de parâmetros do relatório
Parametros--------: _oPrint - Objeto do Relatório.
                    _nLinAdic = Numero de linhas adicionais.
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS030IPP( _oPrint, _nLinAdic)
Local _cTipoRepres

Default _nLinAdic := 0

//================================================================================
// Inicia uma nova página
//================================================================================   
_oPrint:StartPage()  

_nPosLin	+= 080  + _nLinAdic
_oPrint:Line( _nPosLin , _nColIni , _nPosLin , _nColFim )
_nPosLin	+= 060
		
//================================================================================
// Imprime o parametro e a resposta
//================================================================================
_oPrint:Say( _nPosLin , _nColIni + 010 , "Mes/Ano Inicial?" , _oFont14b )
_oPrint:Say( _nPosLin , _nColIni + 900 , MV_PAR01			, _oFont14b )
_nPosLin += 80
_oPrint:Say( _nPosLin , _nColIni + 010 , "Mes/Ano Final?"	, _oFont14b )
_oPrint:Say( _nPosLin , _nColIni + 900 , MV_PAR02			, _oFont14b )
_nPosLin += 80
_oPrint:Say( _nPosLin , _nColIni + 010 , "Gerente Nacional?", _oFont14b )
_oPrint:Say( _nPosLin , _nColIni + 900 , MV_PAR03			, _oFont14b )
_nPosLin += 80
_oPrint:Say( _nPosLin , _nColIni + 010 , "Gerente ?"	    , _oFont14b )
_oPrint:Say( _nPosLin , _nColIni + 900 , MV_PAR04			, _oFont14b )
_nPosLin += 80
_oPrint:Say( _nPosLin , _nColIni + 010 , "Coordenador ?"	, _oFont14b )
_oPrint:Say( _nPosLin , _nColIni + 900 , MV_PAR05			, _oFont14b )
_nPosLin += 80
_oPrint:Say( _nPosLin , _nColIni + 010 , "Supervisor ?"	, _oFont14b )
_oPrint:Say( _nPosLin , _nColIni + 900 , MV_PAR06			, _oFont14b )
_nPosLin += 80
_oPrint:Say( _nPosLin , _nColIni + 010 , "Representantes ?"	, _oFont14b )
_oPrint:Say( _nPosLin , _nColIni + 900 , MV_PAR07			, _oFont14b )
_nPosLin += 80
_oPrint:Say( _nPosLin , _nColIni + 010 , "Traz Hierarquia?"	, _oFont14b )
_oPrint:Say( _nPosLin , _nColIni + 900 , IIf(MV_PAR08=="Sim","SIM","NÃO"), _oFont14b ) 
_nPosLin += 80 
_oPrint:Say( _nPosLin , _nColIni + 010 , "Tipo de Relatorio?"	, _oFont14b )
_oPrint:Say( _nPosLin , _nColIni + 900 , IIf(MV_PAR09=='Analitico',"ANALITICO","SINTETICO"), _oFont14b ) 
_nPosLin += 80 
_oPrint:Say( _nPosLin , _nColIni + 010 , "Tipo de Representante ?"	, _oFont14b )
_oPrint:Say( _nPosLin , _nColIni + 900 , MV_PAR10, _oFont14b ) 
_nPosLin += 80 
_oPrint:Say( _nPosLin , _nColIni + 010 , "Imprime Comissões Zeradas ?"	, _oFont14b )
_oPrint:Say( _nPosLin , _nColIni + 900 , MV_PAR11, _oFont14b ) 
_nPosLin += 80 
_oPrint:Say( _nPosLin , _nColIni + 010 , "Imprime Hierarquia ?"	, _oFont14b )
_oPrint:Say( _nPosLin , _nColIni + 900 , MV_PAR12, _oFont14b ) 
_nPosLin += 80 
_oPrint:Say( _nPosLin , _nColIni + 010 , "Nome do Aprovador ?"	, _oFont14b )
_oPrint:Say( _nPosLin , _nColIni + 900 , MV_PAR13, _oFont14b ) 
_nPosLin += 80 
_oPrint:Say( _nPosLin , _nColIni + 010 , "RG do Aprovador ?"	, _oFont14b )
_oPrint:Say( _nPosLin , _nColIni + 900 , MV_PAR14, _oFont14b ) 
_nPosLin += 80 
_oPrint:Say( _nPosLin , _nColIni + 010 , "Cargo do Aprovador ?"	, _oFont14b )
_oPrint:Say( _nPosLin , _nColIni + 900 , MV_PAR15, _oFont14b ) 
_nPosLin += 80 
_oPrint:Say( _nPosLin , _nColIni + 010 , "Local e Data ?"	, _oFont14b )
_oPrint:Say( _nPosLin , _nColIni + 900 , MV_PAR16, _oFont14b ) 

If MV_PAR10 == 'Interno CLT' //  1  // 'Interno CLT','Externo PJ'     ,'Ambos'
   _cTipoRepres := "Interno CLT 
ElseIf MV_PAR10 == 'Interno CLT' // 2 // 'Interno CLT','Externo PJ' ,'Ambos'
   _cTipoRepres := "Externo PJ"
Else 
   _cTipoRepres := "Ambos"
EndIf

_nPosLin += 80
_oPrint:Say( _nPosLin , _nColIni + 010 , "Tipo Representante?"	, _oFont14b )
_oPrint:Say( _nPosLin , _nColIni + 900 , _cTipoRepres, _oFont14b )
_nPosLin += 80

//================================================================================
// Finaliza a Página
//================================================================================
_oPrint:Line( _nPosLin , _nColIni , _nPosLin , _nColFim )
_oPrint:EndPage()

Return

/*
===============================================================================================================================
Programa----------: ROMS030CAB
Autor-------------: Fabiano Dias
Data da Criacao---: 31/03/2011
Descrição---------: Rotina para impressão dos cabeçalhos do relatório
Parametros--------: _lImpNPG : define se deve imprimir o número da página (.T./.F.)
------------------: _cTipo   : descrição do Tipo de Extrato que está sendo impresso
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS030CAB( _lImpNPG )

Local _cPath	:= If( IsSrvUnix() , "/" , "\" )
Local _cTitulo	:= "Pagamento de Comissão - "+ IIf( !Empty(MV_PAR01) , MesExtenso( Val( SubStr( MV_PAR01 , 1 , 2 ) ) ) + '/' + SubStr( MV_PAR01 , 3 , 4 ) , "" )
Local _cTitulo2	:= ""

If MV_PAR09 == 'Analitico' // 1 // 'Analitico'  ,'Previa-Sintetic','Excel', // Impresso Novo 	
   _cTitulo	:= "Pagamento de Comissão - "+ IIF( !Empty(_cMvMesAno) , MesExtenso( Val( SubStr( _cMvMesAno , 1 , 2 ) ) ) + '/' + SubStr( _cMvMesAno , 3 , 4 ) , "" )
Else
   If MV_PAR01 == MV_PAR02
      _cTitulo	:= "Pagamento de Comissão - "+ IIF( !Empty(MV_PAR01) , MesExtenso( Val( SubStr( MV_PAR01 , 1 , 2 ) ) ) + '/' + SubStr( MV_PAR01 , 3 , 4 ) , "" )
   Else
      _cTitulo	:= "Pagamento de Comissão - "+ IIF( !Empty(MV_PAR01) , MesExtenso( Val( SubStr( MV_PAR01 , 1 , 2 ) ) ) + '/' + SubStr( MV_PAR01 , 3 , 4 ) , "" )
	  _cTitulo  += " Até " +IIF( !Empty(MV_PAR02) , MesExtenso( Val( SubStr( MV_PAR02 , 1 , 2 ) ) ) + '/' + SubStr( MV_PAR02 , 3 , 4 ) , "" )
   EndIf 	
EndIf 

If _cTitCargo == "Repres/Superv/Coord/Geren/Geren Nac" // "Representante/Supervisor/Coordenador/Gerente" 

	_cTitulo2 := "Extrato dos " + _cTitCargo "

Else

	_cTitulo2 := "Extrato do " + _cTitCargo + " - " + _ccodi + " - " + Posicione("SA3",1,xFilial("SA3")+_ccodi,"A3_NOME")
	
EndIf

_nPosLin := 0100

_oPrint:SayBitmap( _nPosLin , _nColIni , _cPath +'system/lgrl01.bmp' , 250 , 100 )

If _lImpNPG
	_oPrint:Say( _nPosLin		, _nColFim - 600 , "ROMS030 - PÁGINA: " + cValToChar( _nNumPag )										, _oFont12b )
Else
	_oPrint:Say( _nPosLin		, _nColFim - 600 , "ROMS030"					   										, _oFont12b )
EndIf

_oPrint:Say( _nPosLin + 050		, _nColFim - 600 , "DATA DE EMISSÃO: "+ DToC( Date() )										, _oFont12b )

_nPosLin += 050
                                                   
_oPrint:Say( _nPosLin , _nColFim / 2 , _cTitulo		, _oFont15b , _nColFim ,,, 2 )
_nPosLin += _nSpcLin
_oPrint:Say( _nPosLin , _nColFim / 2 , _cTitulo2	, _oFont15b , _nColFim ,,, 2 )

_nPosLin+=_nSpcLin 
_nPosLin+=_nSpcLin        

_oPrint:Line(_nPosLin,_nColIni,_nPosLin,_nColFim) 

Return

/*
===============================================================================================================================
Programa----------: ROMS030CIC
Autor-------------: Fabiano Dias
Data da Criacao---: 31/03/2011
Descrição---------: Rotina para impressão do cabeçalhos de informações cadastrais
Parametros--------: _cCodigo : Código do Vendedor
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS030CIC( _cCodigo )

Local _cAlias		:= GetNextAlias() 
Local _cNome		:= ""
Local _cEmail		:= ""
Local _cGerente		:= ""
Local _cCGC			:= ""
Local _cBanco		:= ""
Local _cAgencia		:= ""
Local _cConta		:= ""
Local _cCodOper		:= "" 
Local _cNomeFav		:= ""  
Local _cCPFCNPJF	:= ""

Local _cNomeF		:= "" 
Local _cRegis		:= "" 
Local _cGerNac      := ""

//================================================================================
// Chama a rotina que monta a área temporária com os dados referentes ao Vendedor
//================================================================================
FWMsgRun( , {||  ROMS030QRY( _cAlias , 4 , "" , _cCodigo , "" , "" )  }, 'Aguarde...', 'Filtrando dados do ' + _cTitCargo + ' ' +  StrZero(_nni,6) + " de " + StrZero(_ntoti,6) + "..." )

DBSelectArea( _cAlias )
(_cAlias)->( DBGoTop() )

If (_cAlias)->( !Eof() )
	_cNome		:= (_cAlias)->A3_NOME
	_cEmail		:= (_cAlias)->A2_EMAIL
	_cCGC		:= (_cAlias)->A2_CGC
	_cBanco		:= (_cAlias)->A2_BANCO
	_cAgencia	:= (_cAlias)->A2_AGENCIA
	_cConta		:= (_cAlias)->A2_NUMCON
	_cCodOper	:= (_cAlias)->A2_I_CODOP 
	_cNomeFav	:= (_cAlias)->A2_I_NOMFD
	_cCPFCNPJF	:= (_cAlias)->A2_I_CGCFD
	_cNomeF		:= (_cAlias)->A3_I_NOMEF
	_cRegis		:= (_cAlias)->A3_I_REGIS

EndIf

_cCGC		:= IIf( Len( AllTrim( _cCGC			) ) == 11 , Transform( _cCGC		, "@R 999.999.999-99" ) , Transform( _cCGC		, "@R! NN.NNN.NNN/NNNN-99" ) )
_cCPFCNPJ	:= IIf( Len( AllTrim( _cCPFCNPJF	) ) == 11 , Transform( _cCPFCNPJF	, "@R 999.999.999-99" ) , Transform( _cCPFCNPJF	, "@R! NN.NNN.NNN/NNNN-99" ) )

(_cAlias)->( DBCloseArea() )

_nLinBox := _nPosLin

_oPrint:Say( _nPosLin , _nColFim / 2 , 'Informações Cadastrais' , _oFont16b , _nColFim ,,, 2 )

_nPosLin += _nSpcLin
_nPosLin += _nSpcLin

_oPrint:Say( _nPosLin + _nAjsLin	, _nColIni + 0020 , "Nome.......:"			, _oFont11b )
_oPrint:Say( _nPosLin				, _nColIni + 0260 , SubStr(_cNome,1,44)		, _oFont14b )

_oPrint:Say( _nPosLin + _nAjsLin	, _nColIni + 1300 , "Banco.....:"			, _oFont11b )
_oPrint:Say( _nPosLin + _nAjsLin	, _nColIni + 1550 , _cBanco					, _oFont11  )

_nPosLin += _nSpcLin

_oPrint:Say( _nPosLin + _nAjsLin	, _nColIni + 0020 , "CPF/CNPJ...:"			, _oFont11b )
_oPrint:Say( _nPosLin + _nAjsLin	, _nColIni + 0260 , _cCGC					, _oFont11  )

_oPrint:Say( _nPosLin + _nAjsLin	, _nColIni + 1300 , "Agencia...:"			, _oFont11b )
_oPrint:Say( _nPosLin + _nAjsLin	, _nColIni + 1550 , _cAgencia				, _oFont11  )

_nPosLin += _nSpcLin

_oPrint:Say( _nPosLin + _nAjsLin	, _nColIni + 0020 , "E-mail.....:"			, _oFont11b )
_oPrint:Say( _nPosLin + _nAjsLin	, _nColIni + 0260 , _cEmail					, _oFont11  )


_oPrint:Say( _nPosLin + _nAjsLin	, _nColIni + 1300 , "Conta.....:"			, _oFont11b )
_oPrint:Say( _nPosLin + _nAjsLin	, _nColIni + 1550 , _cConta					, _oFont11  )

If !Empty(_cCodOper) 

_oPrint:Say( _nPosLin + _nAjsLin	, _nColIni + 1730 , "Cod. Operação:"		, _oFont11b )
_oPrint:Say( _nPosLin + _nAjsLin	, _nColIni + 2060 , _cCodOper				, _oFont11  )

EndIf

_nPosLin += _nSpcLin

_oPrint:Say( _nPosLin + _nAjsLin	, _nColIni + 0020 , "Nome Fant.:"			, _oFont11b )
_oPrint:Say( _nPosLin				, _nColIni + 0260 , SubStr(_cnomeF,1,44)		, _oFont11 )

_oPrint:Say( _nPosLin + _nAjsLin	, _nColIni + 1300 , "Favorecido:"			, _oFont11b )
_oPrint:Say( _nPosLin + _nAjsLin	, _nColIni + 1550 , SubStr(_cNomeFav,1,29)	, _oFont11  )

_nPosLin+=_nSpcLin
                              
_oPrint:Say( _nPosLin + _nAjsLin	, _nColIni + 1300 , "CPF/CNPJ..:"			, _oFont11b )
_oPrint:Say( _nPosLin + _nAjsLin	, _nColIni + 1550 , _cCPFCNPJ				, _oFont11  )

_oPrint:Say( _nPosLin + _nAjsLin	, _nColIni + 0020 , "Regiões...:"			, _oFont11b )
_oPrint:Say( _nPosLin				, _nColIni + 0260 , SubStr(_cRegis,1,44)		, _oFont11 )

_nPosLin+=_nSpcLin

_oPrint:Say( _nPosLin				, _nColIni + 0260 , SubStr(_cRegis,45,44)		, _oFont11 )

_nPosLin += _nSpcLin


_cgerente := ""
_ccoord := ""
_csuper := ""
_cGerNac := ""

SA3->(DBSetOrder(1))
If SA3->(DBSeek(xFilial("SA3")+_cCodigo))

_cgerente := SA3->A3_GEREN 
_ccoord   := SA3->A3_SUPER
_csuper   := SA3->A3_I_SUPE
_cGerNac  := SA3->A3_I_GERNC 

    If SA3->(DBSeek(xFilial("SA3")+_cGerNac))
	
	   _cGerNac := _cGerNac +  " - " + SA3->A3_NOME
		
	EndIf

	If SA3->(DBSeek(xFilial("SA3")+_cgerente))
	
		_cgerente := _cgerente +  " - " + SA3->A3_NOME
		
	EndIf
	
	If SA3->(DBSeek(xFilial("SA3")+_ccoord))
	
		_ccoord := _ccoord +  " - " + SA3->A3_NOME
		
	EndIf
	
	If SA3->(DBSeek(xFilial("SA3")+_csuper))
	
		_csuper := _csuper +  " - " + SA3->A3_NOME
		
	EndIf

EndIf	

If _cTitCargo == "Gerente"
   	_oPrint:Say( _nPosLin + _nAjsLin	, _nColIni + 0020 , "Gerente Nacional...:"			, _oFont11b )
	_oPrint:Say( _nPosLin + _nAjsLin	, _nColIni + 0260 , _cGerNac					, _oFont11  )
	
	_nPosLin += _nSpcLin
	_nPosLin += _nSpcLin

ElseIf _cTitCargo == "Coordenador"
    
	_oPrint:Say( _nPosLin + _nAjsLin	, _nColIni + 0020 , "Gerente Nacional...:"			, _oFont11b )
	_oPrint:Say( _nPosLin + _nAjsLin	, _nColIni + 0260 , _cGerNac					, _oFont11  )


	_oPrint:Say( _nPosLin + _nAjsLin +_nSpcLin	, _nColIni + 0020 , "Gerente...:"			, _oFont11b )
	_oPrint:Say( _nPosLin + _nAjsLin + _nSpcLin	, _nColIni + 0260 , _cgerente					, _oFont11  )
	
	_nPosLin += _nSpcLin
	_nPosLin += _nSpcLin

ElseIf _cTitCargo == "Supervisor"

    _oPrint:Say( _nPosLin + _nAjsLin	, _nColIni + 0020 , "Gerente Nacional...:"			, _oFont11b )
	_oPrint:Say( _nPosLin + _nAjsLin	, _nColIni + 0260 , _cGerNac					, _oFont11  )

	_oPrint:Say( _nPosLin + _nAjsLin + _nSpcLin	, _nColIni + 0020 , "Gerente...:"			, _oFont11b )
	_oPrint:Say( _nPosLin + _nAjsLin + _nSpcLin	, _nColIni + 0260 , _cgerente					, _oFont11  )

	_oPrint:Say( _nPosLin + _nAjsLin + _nSpcLin + _nSpcLin	, _nColIni + 0020 , "Coord....:"			, _oFont11b )
	_oPrint:Say( _nPosLin + _nAjsLin + _nSpcLin	+ _nSpcLin  , _nColIni + 0260 , _ccoord					, _oFont11  )
	
	_nPosLin += _nSpcLin
	_nPosLin += _nSpcLin
	_nPosLin += _nSpcLin

ElseIf _cTitCargo == "Representante"

    _oPrint:Say( _nPosLin + _nAjsLin	, _nColIni + 0020 , "Gerente Nacional...:"			, _oFont11b )
	_oPrint:Say( _nPosLin + _nAjsLin	, _nColIni + 0260 , _cGerNac					, _oFont11  )

	_oPrint:Say( _nPosLin + _nAjsLin + _nSpcLin	, _nColIni + 0020 , "Gerente...:"			, _oFont11b )
	_oPrint:Say( _nPosLin + _nAjsLin + _nSpcLin	, _nColIni + 0260 , _cgerente					, _oFont11  )

	_oPrint:Say( _nPosLin + _nAjsLin + _nSpcLin + _nSpcLin	, _nColIni + 0020 , "Coord.....:"			, _oFont11b )
	_oPrint:Say( _nPosLin + _nAjsLin + _nSpcLin + _nSpcLin	, _nColIni + 0260 , _ccoord					, _oFont11  )

	_oPrint:Say( _nPosLin + _nAjsLin + _nSpcLin	+ _nSpcLin + _nSpcLin , _nColIni + 0020 , "Superv...:"			, _oFont11b )
	_oPrint:Say( _nPosLin + _nAjsLin + _nSpcLin	+ _nSpcLin + _nSpcLin , _nColIni + 0260 , _csuper					, _oFont11  )
	
	_nPosLin += _nSpcLin
	_nPosLin += _nSpcLin
	_nPosLin += _nSpcLin
	_nPosLin += _nSpcLin
	
EndIf

_oPrint:Box( _nLinBox , _nColIni , _nPosLin + _nSpcLin , _nColFim )

_nPosLin += _nSpcLin
_nPosLin += _nSpcLin

If Select(_cAlias) > 0  
   (_cAlias)->( DBCloseArea() )
EndIf

Return

/*
===============================================================================================================================
Programa----------: ROMS030COM
Autor-------------: Fabiano Dias
Data da Criacao---: 31/03/2011
Descrição---------: Rotina para impressão dos dados das vendas e do fechamento do mês atual
Parametros--------: _aHisPag : Array contendo os dados de pagamento dos três ultímos meses
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS030COM( _aComissao , _cTipo , _cCodGer )

Local _aImpostos	:= {}
Local _cDescric		:= _cTitCargo 

Local _nTotBruto	:= 0
Local _nINSS		:= 0
Local _nIRRF		:= 0
Local _nTotLiqui	:= 0

Local _nLinBox2		:= _nPosLin                                

Local _cTpComis		:= "" 
Local _nVlrDebCo	:= 0   
Local _nVlrDevol	:= 0
Local _nTotDevol    := 0

Local _nTotReceb	:= 0
Local _nTotComis	:= 0
Local _nTotBonif	:= 0
Local _nTotCmBnf	:= 0
Local _cTituloPg , y , _nI

Private _aTotBNF := {}

//================================================================================
// Verifica a necessidade de quebra de pagina
//================================================================================
ROMS030QPG( 0 , .F. , .F. , "" , "" , _cDescric )

 _nPosLin += _nSpcLin
 
For y:=1 to Len(_aComissao)

	//================================================================================
	// Verifica se o tipo da comissao gerado eh diferente de debito
	//================================================================================
	If _aComissao[y,5] <> 'D'
 	
		If _cTpComis <> _aComissao[y,5]
		     
			_nPosLin += _nSpcLin
		 	
			//================================================================================
			// Fecha o box criado anteriormente e imprime totalizador
			//================================================================================
			If !Empty(_cTpComis)
			
				//================================================================================
				// Imprime a comissão adicional por venda de leite Magro
				//================================================================================
				If _cTpComis == 'A'
				
					_aTotCAD := ROMS030CAD( _cCodGer )
					
					If _aTotCAD[04] > 0
					
						_oPrint:Say( _nPosLin + _nAjsLin , _nColIni + 0010 , "Adicional Leite Magro"								, _oFont11b )
						_oPrint:Say( _nPosLin + _nAjsLin , _nColIni + 0750 , Transform( 0            , "@E 999,999,999,999.99" )	, _oFont11b )
						_oPrint:Say( _nPosLin + _nAjsLin , _nColIni + 1380 , Transform( _aTotCAD[04] , "@E 999,999,999,999.99" )	, _oFont11b )
						_oPrint:Say( _nPosLin + _nAjsLin , _nColIni + 2100 , Transform( _aTotCAD[03] , "@E 999.999" )				, _oFont11b )
						
						_nPosLin	+= _nSpcLin
						_nTotComis	+= _aTotCAD[04]
						_nTotBruto	+= _aTotCAD[04]
					
					EndIf
				
				EndIf
			    
				_oPrint:Line( _nPosLin , _nColIni + 05 , _nPosLin , _nColFim - 05 )
			    
			    _oPrint:Say( _nPosLin + _nAjsLin , _nColIni + 0010 , "TOTAL"												, _oFont11b )
			    _oPrint:Say( _nPosLin + _nAjsLin , _nColIni + 0750 , Transform(_nTotReceb,"@E 999,999,999,999.99")			, _oFont11b )
				_oPrint:Say( _nPosLin + _nAjsLin , _nColIni + 1380 , Transform(_nTotComis,"@E 999,999,999,999.99")			, _oFont11b )
				_oPrint:Say( _nPosLin + _nAjsLin , _nColIni + 2100 , Transform((_nTotComis/_nTotReceb) * 100,"@E 999.999")	, _oFont11b )
				
			    _nPosLin += _nSpcLin
				ROMS0304()
				
				//================================================================================
				// Seta variaves do totalizador por tipo de comissao do Gerente
				//================================================================================
				_nTotReceb := 0
				_nTotComis := 0
			
			EndIf
			
			_nLinBox := _nPosLin	
			
            ROMS30RQPG( 0 , .T. , .F. , "ROMS304R()" , "" , _cDescric )

			_cTituloPg := ""
			If _cTipoRepSA3 == 'G'  	
               _cTituloPg := "Gerência"  
            ElseIf _cTipoRepSA3 == 'C'
               _cTituloPg := "Coordenação"
            ElseIf _cTipoRepSA3 == 'S'
               _cTituloPg := "Supervisão"
            ElseIf _cTipoRepSA3 == 'V'
               _cTituloPg := "Representante"
			ElseIf _cTipoRepSA3 == 'N'
               _cTituloPg := "Gerente Geral"
            EndIf
			
			_oPrint:Say( _nPosLin , _nColFim / 2 , 'Comissão a pagar sobre ' + _cTituloPg , _oFont16b , _nColFim ,,, 2 )
			
			_nPosLin += _nSpcLin
			
			_oPrint:Line( _nPosLin , _nColIni , _nPosLin , _nColFim )
			
			_oPrint:Say( _nPosLin + _nAjsLin , _nColIni + 0010 , "Unidade"      , _oFont11b )
			_oPrint:Say( _nPosLin + _nAjsLin , _nColIni + 0870 , "Vlr.Recebido" , _oFont11b )
			_oPrint:Say( _nPosLin + _nAjsLin , _nColIni + 1500 , "Vlr.Comissão" , _oFont11b )
			_oPrint:Say( _nPosLin + _nAjsLin , _nColIni + 2050 , "%"            , _oFont11b )
			
		EndIf
		
		nLinInBox := _nPosLin
		_nPosLin += _nSpcLin
		 _oPrint:Box( nLinInBox , _nColIni , _nPosLin , _nColFim )
		 
		//================================================================================
		// Verifica quebra de pagina
		//================================================================================
		ROMS030QPG( 0 , .T. , .F. , "ROMS0304()" , "" , _cDescric )
		
		_oPrint:Say( _nPosLin + _nAjsLin , _nColIni + 0010 , SubStr(FWFilialName(,_aComissao[y,1]),1,30)						, _oFont11 )
		_oPrint:Say( _nPosLin + _nAjsLin , _nColIni + 0750 , Transform(Round(_aComissao[y,2],2),"@E 999,999,999,999.99")				, _oFont11 )
		_oPrint:Say( _nPosLin + _nAjsLin , _nColIni + 1380 , Transform(Round(_aComissao[y,3],2),"@E 999,999,999,999.99")				, _oFont11 )
		_oPrint:Say( _nPosLin + _nAjsLin , _nColIni + 1980 , Transform((_aComissao[y,3]/_aComissao[y,2]) * 100,"@E 999.999")	, _oFont11 )
		
		_nTotReceb	+= Round(_aComissao[y,2],2)
		_nTotComis	+= Round(_aComissao[y,3],2)
		_nTotBruto  += Round(_aComissao[y,3],2)
		
		_cTpComis	:= _aComissao[y,5]
	
	//================================================================================
	// Calcula o valor de debito da comissão
	//================================================================================
	Else
	
		_nVlrDebCo += Round(_aComissao[y,3],2)
		_nVlrDevol += Round(_aComissao[y,6],2)
		_nTotDevol += Round(_aComissao[y,2],2)
	
	EndIf

Next y

nLinInBox := _nPosLin
_nPosLin += _nSpcLin
_oPrint:Box( nLinInBox , _nColIni , _nPosLin , _nColFim )

//================================================================================
//Calcula o desconto de comissão por bonificação
//================================================================================
FWMsgRun(, {|| _aTotBNF := ROMS030BNF( _cCodGer ) }, "Aguarde... ", 'Filtrando bonificações para ' + _cTitCargo + ' ' + StrZero(_nni,6) + " de " + StrZero(_ntoti,6) + "..." )

If !Empty( _aTotBNF )
  	
  	
	For _nI := 1 To Len(_aTotBNF)
    
    	_nTotComis	+= Round(_aTotBNF[_nI][03],2)
		_nTotCmBnf	+= Round(_aTotBNF[_nI][03],2)
		_nTotBonif	+= Round(_aTotBNF[_nI][02],2)
	
	Next _nI
	
EndIf

If !Empty( _aTotBNF ) 
 	
	ROMS030QPG( 0 , .T. , .F. , "ROMS0304()" , "" , _cDescric )
	
	_nLinBox2 := _nPosLin
	
	_oPrint:Say( _nPosLin + _nAjsLin , _nColIni + 0010 , "Débito: Comissão x Bonificações"							, _oFont11b )
	_oPrint:Say( _nPosLin + _nAjsLin , _nColIni + 0750 , Transform(-1*_nTotBonif,"@E 999,999,999,999.99")				, _oFont11b )
	_oPrint:Say( _nPosLin + _nAjsLin , _nColIni + 1380 , Transform(_nTotCmBnf,"@E 999,999,999,999.99")				, _oFont11b )
	_oPrint:Say( _nPosLin + _nAjsLin , _nColIni + 1980 , Transform(Abs((_nTotCmBnf/_nTotBonif) * 100),"@E 999.999")	, _oFont11b )
	
	_nVlrDebCo	+= _nTotCmBnf
	_nPosLin	+= _nSpcLin
	
	_oPrint:Box(_nLinBox2,_nColIni,_nPosLin,_nColFim)  

EndIf

If _nVlrDevol <> 0  
 	
	ROMS030QPG( 0 , .T. , .F. , "ROMS0304()" , "" , _cDescric )
	
	_oPrint:Say( _nPosLin + _nAjsLin , _nColIni + 0010 , "Débito: Pagamento de devoluções"							, _oFont11b )
	_oPrint:Say( _nPosLin + _nAjsLin , _nColIni + 0750 , Transform( -1*_nTotDevol ,"@E 999,999,999,999.99")				, _oFont11b )
	_oPrint:Say( _nPosLin + _nAjsLin , _nColIni + 1380 , Transform( _nVlrDevol    ,"@E 999,999,999,999.99")				, _oFont11b )
	_oPrint:Say( _nPosLin + _nAjsLin , _nColIni + 1980 , Transform(Abs((_nVlrDevol/_nTotDevol) * 100),"@E 999.999")	, _oFont11b )
	
	_nVlrDebCo	+= _nVlrDevol
	_nPosLin	+= _nSpcLin
	
	_oPrint:Box(_nLinBox2,_nColIni,_nPosLin,_nColFim)  

EndIf

//================================================================================
// Verifica quebra de pagina
//================================================================================
ROMS030QPG( 0 , .T. , .F. , "ROMS0304()" , "" , _cDescric )

_nLinBox2 := _nPosLin
_oPrint:Line( _nPosLin , _nColIni + 05 , _nPosLin , _nColFim - 05 )

_nTotLiqui := Round(_nTotBruto,2) + Round(_nVlrDebCo,2) 

_nTotComis := _nTotLiqui
_nTotReceb := _nTotReceb - _nTotBonif - _nTotDevol

_oPrint:Say( _nPosLin + _nAjsLin , _nColIni + 0010 , "Total Bruto"												, _oFont11b )
_oPrint:Say( _nPosLin + _nAjsLin , _nColIni + 0750 , Transform(_nTotReceb,"@E 999,999,999,999.99")			, _oFont11b )
_oPrint:Say( _nPosLin + _nAjsLin , _nColIni + 1380 , Transform(_nTotComis,"@E 999,999,999,999.99")			, _oFont11b )
_oPrint:Say( _nPosLin + _nAjsLin , _nColIni + 1980 , Transform((_nTotComis/_nTotReceb) * 100,"@E 999.999")	, _oFont11b )

//================================================================================
// Efetua o calculo dos Impostos do vendedor como: INSS e IRRF.
//================================================================================
_aImpostos := {} 
If Val(_aComissao[1,4]) > 0 .Or. _nTotLiqui > 0  
   _aImpostos := U_C_IRRF_INSS( _aComissao[1,4] , _nTotLiqui )
Else
   aAdd(_aImpostos, {0,0})  
EndIf

_nINSS := Round(_aImpostos[1,1],2)
_nIRRF := Round(_aImpostos[1,2],2)

_nTotLiqui -= ( _nINSS + _nIRRF )

_nPosLin += _nSpcLin

//================================================================================
// Verifica quebra de pagina
//================================================================================
ROMS030QPG( 0 , .T. , .F. , "ROMS0304()" , "" , _cDescric )

_oPrint:Line( _nPosLin , _nColIni + 05 , _nPosLin , _nColFim - 05 )

_oPrint:Say( _nPosLin + _nAjsLin , _nColIni + 0010 , "INSS"													, _oFont11b )
_oPrint:Say( _nPosLin + _nAjsLin , _nColIni + 1380 , Transform(_nINSS,"@E 999,999,999,999.99")			, _oFont11b )

_nPosLin+=_nSpcLin      

//================================================================================
// Verifica quebra de pagina
//================================================================================
ROMS030QPG( 0 , .T. , .F. , "ROMS0304()" , "" , _cDescric )


_oPrint:Line( _nPosLin , _nColIni + 05 , _nPosLin , _nColFim - 05 )

_oPrint:Say( _nPosLin + _nAjsLin , _nColIni + 0010 , "IRRF"													, _oFont11b )
_oPrint:Say( _nPosLin + _nAjsLin , _nColIni + 1380 , Transform(_nIRRF,"@E 999,999,999,999.99")			, _oFont11b )

_nPosLin += _nSpcLin
_oPrint:Box(_nLinBox2,_nColIni,_nPosLin,_nColFim)

_nPosLin += _nSpcLin

//================================================================================
// Verifica quebra de pagina 
//================================================================================
If (_nSpcLin  + _nPosLin + 200) > _nLimPag  
   _nPosLin += _nSpcLin  + _nPosLin + 22 
   ROMS030QPG( 0 , .F. , .F. , "" , "" , _cDescric ) 
EndIf

ROMS030QPG( 0 , .T. , .F. , "ROMS0304()" , "" , _cDescric )

_oPrint:Say( _nPosLin            , _nColIni + 0010 , "Total Líquido a Pagar"							, _oFont15b )
_oPrint:Say( _nPosLin            , _nColIni + 1450 , Transform( _nTotLiqui ,"@E 999,999,999,999.99")	, _oFont15b )

_nPosLin+=_nSpcLin 
_nPosLin += _nSpcLin

Return


/*
===============================================================================================================================
Programa----------: ROMS030QPG
Autor-------------: Fabiano Dias
Data da Criacao---: 31/03/2011
Descrição---------: Imprime Box fixo
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS0304()

_oPrint:Box( _nLinBox , _nColIni , _nPosLin , _nColFim )

Return

/*
===============================================================================================================================
Programa----------: ROMS030QPG
Autor-------------: Fabiano Dias
Data da Criacao---: 31/03/2011
Descrição---------: Função para controlar as quebras de página do relatório
Parametros--------: _nPosLins - numero de linhas que sera reduzido do tamanho do box do relatorio.
------------------: impBox    - .T. - indica que imprime box
------------------: impCabec  - .T. - indica que imprime cabecalho de dados
------------------: boxImp    - Nome da funcao para impressao do box e suas divisorias
------------------: cabecImp  - Nome da funcao para impressao do cabecalho de dados
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS030QPG(_nPosLins,limpBox,limpCabec,boxImp,cabecImp,_cTipoExtr)   

//====================================================================================================
// Verifica se deve quebrar a pagina
//====================================================================================================
If _nPosLin > _nLimPag

	_nPosLin:= _nPosLin - (_nSpcLin * _nPosLins)
	
	//====================================================================================================
	// Verifica se imprime o box e divisorias do relatorio
	//====================================================================================================
	If limpBox
		&boxImp
	EndIf
	
	_oPrint:EndPage()	// Finaliza a Pagina.
	_oPrint:StartPage()	//Inicia uma nova Pagina
	
	_nNumPag++
	
	ROMS030CAB( .T. ) //Chama impressão do cabecalho
	
	_nPosLin += _nSpcLin
	_nPosLin += _nSpcLin
	_nLinBox := _nPosLin
	
	//====================================================================================================
	// Verifica se imprime o cabecalho dos dados
	//====================================================================================================
	If limpCabec
	
		&cabecImp
		
		_nPosLin += _nSpcLin
		_oPrint:Line( _nPosLin , _nColIni , _nPosLin , _nColFim )
		
	EndIf

EndIf

Return

/*
===============================================================================================================================
Programa----------: ROMS030QBR
Autor-------------: Fabiano Dias
Data da Criacao---: 31/03/2011
Descrição---------: Função para quebras de página do relatório
Parametros--------: _cTipoExtr - Configurção de cabeçalho da nova página
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS030QBR()

_oPrint:EndPage()		// Finaliza a Pagina.
_oPrint:StartPage()		//Inicia uma nova Pagina

_nNumPag++

ROMS030CAB( .T. ) //Chama impressão do cabecalho

_nPosLin += _nSpcLin
_nPosLin += _nSpcLin

Return

/*
===============================================================================================================================
Programa--------: ROMS030QRY
Autor-----------: Fabiano Dias
Data da Criacao-: 31/03/2011
Descrição-------: Função que executa as querys para consulta de dados do relatório
Parametros------: _cAlias   - Alias a ser gerado,_nOpcao - query a ser executada
----------------: _cVended  - Vendedor corrente na impressao(Somente um)
----------------: _cGerente - Gerente corrente na impressao(Somente um)
----------------: _cVends   - Todos os vendedores que movimentaram comissao de acordo com parametros fornecidos pelo usuario
----------------: _cGerents - Todos os Gerentes que movimentaram comissao de acordo com os parametros fornecidos.
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS030QRY( _cAlias , _nOpcao , _cVended , _cGerente , _cVends , _cGerents, _cCodRepres, _cTipoRepres )

Local _cFilVend  := "%"

Local _cFilSE1   := "%"

Local _cFilV4    := "%"
Local _cFilV5    := "%"

Local _cAnoMesIn := ""
Local _cAnoMesFi := ""

Local _cWhere01  := "% %"
Local _cWhere02  := "% %"
Local _cWhere03  := "% %"
Local _cWhere04  := "% %"

If Select(_cAlias) > 0
   (_cAlias)->( DBCloseArea() )
EndIf

Do Case

	//====================================================================================================
	// Seleciona comissao a pagar do mes de fechamento indicado pelo pelo usuario para os Gerentes
	//====================================================================================================
	Case _nOpcao == 1
	    If MV_PAR09 == 'Analitico' // 1   // 'Analitico'  ,'Previa-Sintetic','Excel', 'Impresso Novo' 	
           _cWhere02 := "% AND SubStr(E3_EMISSAO,1,6) = '" + SubStr(_cMvMesAno,3,4) + SubStr(_cMvMesAno,1,2) + "' %" 
		Else
	       If !Empty(MV_PAR01)
		      If AllTrim(MV_PAR01) == AllTrim(MV_PAR02)
		         _cWhere02 := "% AND SubStr(E3_EMISSAO,1,6) = '" + SubStr(MV_PAR01,3,4) + SubStr(MV_PAR01,1,2) + "' %" 
		      Else
		         _cWhere02 := "% AND SubStr(E3_EMISSAO,1,6) >= '" + SubStr(MV_PAR01,3,4) + SubStr(MV_PAR01,1,2) + "' AND SubStr(E3_EMISSAO,1,6) <= '" + SubStr(MV_PAR02,3,4) + SubStr(MV_PAR02,1,2) + "' %" 
		      EndIf
		   EndIf
		EndIf 
	    
		//====================================================================================================
		// Gerente
		//====================================================================================================
		If MV_PAR10 ==  'Interno CLT' // 1 // 'Interno CLT','Externo PJ' ,'Ambos'
		   _cWhere01 := "% AND E3.E3_VEND = '" + _cCodRepSA3 + "' AND A3.A3_I_TIPV = '" + _cTipoRepSA3 + "' AND A3_TIPO = 'I' %"
        ElseIf MV_PAR10 == 'Externo PJ' // 2 // 'Interno CLT','Externo PJ' ,'Ambos'
           _cWhere01 := "% AND E3.E3_VEND = '" + _cCodRepSA3 + "' AND A3.A3_I_TIPV = '" + _cTipoRepSA3 + "' AND A3_TIPO = 'E' %"
		Else
		   _cWhere01 := "% AND E3.E3_VEND = '" + _cCodRepSA3 + "' AND A3.A3_I_TIPV = '" + _cTipoRepSA3 + "' %"	
        EndIf 

		If _cTipoRepSA3 = "V" // Extrato Vendedor 
		   _cWhere04 := "% AND F2.F2_VEND1 = E3.E3_VEND %"
		EndIf
		
		If _cTipoRepSA3 = "S" // Extrato Supervisor
		   _cWhere04 := "% AND F2.F2_VEND4 = E3.E3_VEND %"
		EndIf
		
		If _cTipoRepSA3 = "C" // Extrato Coordenador
		   _cWhere04 := "% AND F2.F2_VEND2 = E3.E3_VEND %"
		EndIf
		
		If _cTipoRepSA3 = "G" // Extrato Gerente
		   _cWhere04 := "% AND F2.F2_VEND3 = E3.E3_VEND %"
		EndIf
		
        If _cTipoRepSA3 = "N" // Extrato Gerente Nacional 
		   _cWhere04 := "% AND F2.F2_VEND5 = E3.E3_VEND %"
		EndIf

		BeginSql alias _cAlias
		
			SELECT                                   
			    E3.E3_FILIAL     AS FILIAL  ,
			    E3.E3_VEND       AS CODGER	, 
			    A3.A3_I_DEDUC    AS DEDUCAO ,
			    E3.E3_I_ORIGE    AS ORIGEM  ,
			    SUM(E3.E3_COMIS) AS COMISSAO,
			    SUM(E3.E3_BASE)  AS VLRRECEB,
			    Case
			        WHEN F2.F2_VEND2 = ' '          THEN 'A'
			        WHEN F2.F2_VEND1 <> F2.F2_VEND2 THEN 'B'
			        WHEN F2.F2_VEND3 <> ' '         THEN 'B'
			    END AS TIPOVENDA
			    
			FROM %Table:SE3% E3
			
			JOIN %Table:SA3% A3
			ON
			    A3.A3_COD = E3.E3_VEND
			
			JOIN %Table:SE1% E1
			ON
			    E1_FILIAL  = E3_FILIAL
			AND E1_NUM     = E3_NUM
			AND E1_PREFIXO = E3_PREFIXO
			AND E1_PARCELA = E3_PARCELA
			AND E1_TIPO    = E3_TIPO
			AND E1_CLIENTE = E3_CODCLI
			AND E1_LOJA    = E3_LOJA
			
			JOIN %Table:SF2% F2
			ON
			    F2.F2_FILIAL  = E1.E1_FILIAL
			AND F2.F2_DOC     = E1.E1_NUM
			AND (F2.F2_SERIE   = E1.E1_PREFIXO)
			AND F2.F2_CLIENTE = E1.E1_CLIENTE
			AND F2.F2_LOJA    = E1.E1_LOJA
			%Exp:_cWhere04%    
			WHERE
			    E3.%NotDel%
			AND A3.%NotDel%
			AND E1.%NotDel%
			%Exp:_cWhere01% 
			AND F2.%NotDel%
			%Exp:_cWhere02%
			
			GROUP BY
			    E3.E3_FILIAL ,
			    E3.E3_VEND   ,   
			    A3.A3_I_DEDUC,
			    E3.E3_I_ORIGE,
			    Case
			        WHEN F2.F2_VEND2 = ' '          THEN 'A'
			        WHEN F2.F2_VEND1 <> F2.F2_VEND2 THEN 'B'
			        WHEN F2.F2_VEND3 <> ' '         THEN 'B'
			    END
			
			UNION ALL
			
			SELECT
			    E3.E3_FILIAL     AS FILIAL  ,
			    E3.E3_VEND       AS CODGER	,
			    A3.A3_I_DEDUC    AS DEDUCAO ,
			    E3.E3_I_ORIGE    AS ORIGEM  ,
			    SUM(E3.E3_COMIS) AS COMISSAO,
			    SUM(E3.E3_BASE)  AS VLRRECEB,
			    MIN( Case
			            WHEN F2.F2_VEND2 = ' '          THEN 'A'
			            WHEN F2.F2_VEND1 <> F2.F2_VEND2 THEN 'B'
			            WHEN F2.F2_VEND3 <> ' '         THEN 'B'
			    END ) AS TIPOVENDA
			FROM %Table:SE3% E3
			
			INNER JOIN %Table:SE1% E1
			ON  E1.E1_FILIAL  = E3.E3_FILIAL
			AND E1.E1_TIPO    = E3.E3_TIPO
			AND E1.E1_PREFIXO = E3.E3_PREFIXO
			AND E1.E1_NUM     = E3.E3_NUM
			AND E1.E1_SERIE   = E3.E3_SERIE
			AND E1.E1_PARCELA = E3.E3_PARCELA
			AND E1.E1_CLIENTE = E3.E3_CODCLI
			AND E1.E1_LOJA    = E3.E3_LOJA
			
			INNER JOIN %Table:SA3% A3
			ON  A3.A3_COD     = E3.E3_VEND
			
			INNER JOIN %Table:SF2% F2
			ON  F2.F2_FILIAL  = E1.E1_FILIAL
			AND F2.F2_DOC     = E1.E1_NUM
			AND (F2.F2_SERIE   = E1.E1_PREFIXO OR E1.E1_PREFIXO = 'R')
			AND F2.F2_CLIENTE = E1.E1_CLIENTE
			AND F2.F2_LOJA    = E1.E1_LOJA
			%Exp:_cWhere04%    
					
			WHERE
			    E3.%NotDel%
			AND E1.%NotDel%
			AND A3.%NotDel%
			AND F2.%NotDel% 
			%Exp:_cWhere01%
			AND E1.E1_ORIGEM = 'FINA460'
			AND EXISTS(	SELECT E5.E5_DATA FROM %Table:SE5% E5
			  				WHERE  E5.%NotDel%
			  						AND F2.F2_FILIAL  = E5.E5_FILIAL
			  						AND F2.F2_DOC     = E5.E5_NUMERO
			  						AND (F2.F2_SERIE   = E5.E5_PREFIXO OR E5.E5_PREFIXO = 'R')
			  						AND F2.F2_CLIENTE = E5.E5_CLIFOR
			  						AND F2.F2_LOJA    = E5.E5_LOJA
			  						AND E1.E1_NUMLIQ  = E5.E5_DOCUMEN
			  						AND E1.E1_FILIAL  = E5.E5_FILIAL
			  						AND E5.E5_SITUACA <> 'C'
				  					AND E5.E5_DOCUMEN <> ' ')
			  						
			%Exp:_cWhere02%
			
			GROUP BY
			    E3.E3_FILIAL ,
			    E3.E3_VEND   ,
			    A3.A3_I_DEDUC,
			    E3.E3_I_ORIGE,
			    Case
			        WHEN F2.F2_VEND2 = ' '          THEN 'A'
			        WHEN F2.F2_VEND1 <> F2.F2_VEND2 THEN 'B'
			        WHEN F2.F2_VEND3 <> ' '         THEN 'B'
			    END
			
			UNION ALL
			
			SELECT
			    E3.E3_FILIAL     AS FILIAL  ,
			    E3.E3_VEND       AS CODGER	,
			    A3.A3_I_DEDUC    AS DEDUCAO ,
			    E3.E3_I_ORIGE    AS ORIGEM  ,
			    SUM(E3.E3_COMIS) AS COMISSAO,
			    SUM(E3.E3_BASE)  AS VLRRECEB,
			    'D'              AS TIPOVENDA
			FROM %Table:SE3% E3
			
			INNER JOIN %Table:SA3% A3
			ON  E3.E3_VEND    = A3.A3_COD
			
			INNER JOIN %Table:SA1% A1
			ON  A1.A1_COD     = E3.E3_CODCLI
			AND A1.A1_LOJA    = E3.E3_LOJA
			
			WHERE
			    E3.%NotDel%
			AND A3.%NotDel%
			AND A1.%NotDel%
			AND E3.E3_TIPO   = 'NCC'
			%Exp:_cWhere01%
			AND E3.E3_NUM    IN (  SELECT D1.D1_DOC
			                       FROM %Table:SD1% D1 , %Table:SF2% F2
			                       WHERE
			                           D1.%NotDel%
			                       AND F2.%NotDel%
			                       AND E3.E3_FILIAL  = D1.D1_FILIAL
			                       AND E3.E3_NUM     = D1.D1_DOC
			                       AND E3.E3_SERIE   = D1.D1_SERIE
			                       AND E3.E3_CODCLI  = D1.D1_FORNECE
			                       AND E3.E3_LOJA    = D1.D1_LOJA
			                       AND F2.F2_FILIAL  = D1.D1_FILIAL
			                       AND F2.F2_DOC     = D1.D1_NFORI
			                       AND F2.F2_SERIE   = D1.D1_SERIORI
			                       AND F2.F2_CLIENTE = D1.D1_FORNECE
			                       AND F2.F2_LOJA    = D1.D1_LOJA
			                       %Exp:_cWhere04%    
			                    )
			%Exp:_cWhere02%
			GROUP BY
			    E3.E3_FILIAL ,
			    E3.E3_VEND   ,
			    A3.A3_I_DEDUC,
			    E3.E3_I_ORIGE,
			    'D'
			
			UNION ALL
			
			SELECT
			    E3.E3_FILIAL     AS FILIAL  ,
			    E3.E3_VEND       AS CODGER	,
			    A3.A3_I_DEDUC    AS DEDUCAO ,
			    E3.E3_I_ORIGE    AS ORIGEM  ,
			    SUM(E3.E3_COMIS) AS COMISSAO,
			    SUM(E3.E3_BASE)  AS VLRRECEB,
			    'D'              AS TIPOVENDA
			FROM %Table:SE3% E3
			
			JOIN %Table:SA3% A3
			ON
			    E3.E3_VEND    = A3.A3_COD
			
			JOIN %Table:SA1% A1
			ON
			    A1.A1_COD     = E3.E3_CODCLI
			AND A1.A1_LOJA    = E3.E3_LOJA
			
			WHERE
			    E3.%NotDel%
			AND A3.%NotDel%
			AND A1.%NotDel%
			%Exp:_cWhere01%
			AND E3.E3_TIPO   = 'NCC'
			AND A3.A3_SUPER  = ' '
			
			AND E3.E3_NUM    NOT IN (  SELECT D1.D1_DOC
			                           FROM %Table:SD1% D1, %Table:SF2% F2
			                           WHERE
			                               D1.D_E_L_E_T_ = ' '
			                           AND F2.D_E_L_E_T_ = ' '
			                           AND E3.E3_FILIAL  = D1.D1_FILIAL
			                           AND E3.E3_NUM     = D1.D1_DOC
			                           AND E3.E3_SERIE   = D1.D1_SERIE
			                           AND E3.E3_CODCLI  = D1.D1_FORNECE
			                           AND E3.E3_LOJA    = D1.D1_LOJA
			                           AND F2.F2_FILIAL  = D1.D1_FILIAL
			                           AND F2.F2_DOC     = D1.D1_NFORI
			                           AND F2.F2_SERIE   = D1.D1_SERIORI
			                           AND F2.F2_CLIENTE = D1.D1_FORNECE
			                           AND F2.F2_LOJA    = D1.D1_LOJA )
			%Exp:_cWhere02%
			GROUP BY E3.E3_FILIAL , 
			         E3.E3_VEND , 
			         A3.A3_I_DEDUC , 
			         E3.E3_I_ORIGE , 'D'
			ORDER BY FILIAL , CODGER , TIPOVENDA
			
		EndSql
	
	//====================================================================================================
	// Query responsavel por trazer as duplicatas vencidas dos vendedores
	//====================================================================================================
	Case _nOpcao == 2
         
         _cWhere01 := "%"	
		 If _cTipoRepSA3 == 'G'  	
			_cWhere01 += " AND F2.F2_VEND3 = '" + _cCodRepSA3 + "' AND A3.A3_COD = F2.F2_VEND3 "
		 ElseIf _cTipoRepSA3 == 'C'
			_cWhere01 += " AND F2.F2_VEND2 = '" + _cCodRepSA3 + "' AND A3.A3_COD = F2.F2_VEND2 "
		 ElseIf _cTipoRepSA3 == 'S'
			_cWhere01 += " AND F2.F2_VEND4 = '" + _cCodRepSA3 + "'  AND A3.A3_COD = F2.F2_VEND4 "
		 ElseIf _cTipoRepSA3 == 'V'
			_cWhere01 += " AND F2.F2_VEND1 = '" + _cCodRepSA3 + "'  AND A3.A3_COD = F2.F2_VEND1 "
		 ElseIf _cTipoRepSA3 == 'N'
			_cWhere01 += " AND F2.F2_VEND5 = '" + _cCodRepSA3 + "' AND A3.A3_COD = F2.F2_VEND5 "  
		 EndIf

         If MV_PAR10 == 'Interno CLT' // 1 // 'Interno CLT','Externo PJ' ,'Ambos'
		    _cWhere01 += " AND A3_TIPO = 'I' "
		 ElseIf MV_PAR10 == 'Externo PJ' // 2 // 'Interno CLT','Externo PJ' ,'Ambos'
		    _cWhere01 += " AND A3_TIPO = 'E' "
         EndIf  
		 
		_cWhere01 += "%" 
		 
		BeginSql alias _cAlias
			
			SELECT
			    COUNT( Case
			    	WHEN E1.E1_SALDO > 0 AND E1.E1_VENCREA BETWEEN %Exp:DToS(DaySub(Date(),15))% AND %Exp:DToS(Date())%
			    	THEN E1.E1_SALDO
			    END ) NUMDUP15,
			    COALESCE( SUM( Case
			    	WHEN E1.E1_SALDO > 0 AND E1.E1_VENCREA BETWEEN %Exp:DToS(DaySub(Date(),15))% AND %Exp:DToS(Date())%
			    	THEN E1.E1_SALDO
			    END ) , 0 ) VENCTO15,
			    COUNT( Case
			    	WHEN E1.E1_SALDO > 0 AND E1.E1_VENCREA BETWEEN %Exp:DToS(DaySub(Date(),30))% AND %Exp:DToS(DaySub(Date(),16))%
			    	THEN E1.E1_SALDO
			    END ) NUMDUP30,
			    COALESCE( SUM( Case
			    	WHEN E1.E1_SALDO > 0 AND E1.E1_VENCREA BETWEEN %Exp:DToS(DaySub(Date(),30))% AND %Exp:DToS(DaySub(Date(),16))%
			    	THEN E1.E1_SALDO
			    END ) , 0 ) VENCTO30,
			    COUNT( Case
			    	WHEN E1.E1_SALDO > 0 AND E1.E1_VENCREA BETWEEN %Exp:DToS(DaySub(Date(),60))% AND %Exp:DToS(DaySub(Date(),31))%
			    	THEN E1.E1_SALDO
			    END ) NUMDUP60,
			    COALESCE( SUM( Case
			    	WHEN E1.E1_SALDO > 0 AND E1.E1_VENCREA BETWEEN %Exp:DToS(DaySub(Date(),60))% AND %Exp:DToS(DaySub(Date(),31))%
			    	THEN E1.E1_SALDO
			    END ) , 0 ) VENCTO60,
			    COUNT( Case
			    	WHEN E1.E1_SALDO > 0 AND E1.E1_VENCREA < %Exp:DToS(DaySub(Date(),60))%
			    	THEN E1.E1_SALDO
			    END ) NUMDUPACI,
			    COALESCE( SUM( Case
			    	WHEN E1.E1_SALDO > 0 AND E1.E1_VENCREA < %Exp:DToS(DaySub(Date(),60))%
			    	THEN E1.E1_SALDO
			    END ) , 0 ) VENCTOACIMA
			FROM %Table:SE1% E1, %Table:SF2% F2, %Table:SA3% A3

			WHERE
			    E1.%NotDel%
			AND F2.%NotDel%

            AND A3.%NotDel%
            AND F2.F2_FILIAL  = E1.E1_FILIAL
            AND F2.F2_DOC     = E1.E1_NUM
            AND (F2.F2_SERIE  = E1.E1_PREFIXO OR E1.E1_PREFIXO = 'R')
            AND F2.F2_CLIENTE = E1.E1_CLIENTE
            AND F2.F2_LOJA    = E1.E1_LOJA

			AND E1.E1_SALDO   > 0
			AND E1.E1_VENCREA < %Exp:DToS( Date() )%
			AND E1.E1_ORIGEM  NOT IN ( 'FINA460' , 'FINA280' )
			%exp:_cWhere01%
							
		EndSql

	//====================================================================================================
	// Seleciona os tres ultimos pagamentos efetuados aos Gerentes.
	//====================================================================================================
	Case _nOpcao == 3
	     
		 If _cTipoRepSA3 <> 'V'
		    _nMesAtual := Val( SubStr( MV_PAR01 , 1 , 2 ) )
		    _nAnoAtual := Val( SubStr( MV_PAR01 , 3 , 4 ) )
		
		    //====================================================================================================
		    // Seleciona os ultimos tres meses de acordo com a data de fechamento fornecida pelo usuario.
		    //====================================================================================================
			If MV_PAR09 == 'Analitico' // 1  // 'Analitico'  ,'Previa-Sintetic','Excel', 'Impresso Novo' 	
                _cAnoMesIn := DToS( MonthSub( SToD( SubStr( _cMvMesAno , 3 , 4 ) + SubStr( _cMvMesAno , 1 , 2 ) + '01' ) , 3 ) )  
		        _cAnoMesFi := SubStr( DToS( MonthSub( SToD( SubStr( _cMvMesAno , 3 , 4 ) + SubStr( _cMvMesAno , 1 , 2 ) + '01' ) , 1 ) ) , 1 , 6 ) + '31' 			   
			Else 
			   If AllTrim(MV_PAR01) == AllTrim(MV_PAR02)
		          _cAnoMesIn := DToS( MonthSub( SToD( SubStr( MV_PAR01 , 3 , 4 ) + SubStr( MV_PAR01 , 1 , 2 ) + '01' ) , 3 ) )  
		          _cAnoMesFi := SubStr( DToS( MonthSub( SToD( SubStr( MV_PAR01 , 3 , 4 ) + SubStr( MV_PAR01 , 1 , 2 ) + '01' ) , 1 ) ) , 1 , 6 ) + '31' 			   
			   Else
			      _cAnoMesIn := DToS( MonthSub( SToD( SubStr( MV_PAR01 , 3 , 4 ) + SubStr( MV_PAR01 , 1 , 2 ) + '01' ) , 3 ) )  
    		      _cAnoMesFi := SubStr( DToS( MonthSub( SToD( SubStr( MV_PAR02 , 3 , 4 ) + SubStr( MV_PAR02 , 1 , 2 ) + '01' ) , 1 ) ) , 1 , 6 ) + '31' 
		       EndIf 
	        EndIf 

			_cWhere01 := "% AND E3.E3_VEND = '" + _cCodRepSA3 + "' AND E3.E3_EMISSAO >= '"+ _cAnoMesIn +"' AND E3.E3_EMISSAO <= '"+ _cAnoMesFi +"' "
		
             If MV_PAR10 == 'Interno CLT' // 1 // 'Interno CLT','Externo PJ' ,'Ambos'
		        _cWhere01 += " AND A3.A3_TIPO = 'I' "
		     ElseIf MV_PAR10 == 'Externo PJ' // 2 // 'Interno CLT','Externo PJ' ,'Ambos'
		        _cWhere01 += " AND A3.A3_TIPO = 'E' "
             EndIf  
		
            _cWhere01 += " %"  
		    
	        BeginSql alias _cAlias	
           
			 SELECT
			     E3.E3_VEND             AS CODGER,
			     SubStr(E3_EMISSAO,1,6) AS ANOMES,
			     SUM(E3.E3_COMIS)       AS COMISSAO
			 FROM %Table:SE3% E3
            
			 INNER JOIN %Table:SA3% A3
	               ON A3.A3_COD = E3.E3_VEND
			 
			 INNER JOIN %Table:SE1% E1  
			 ON 
			     E1.E1_FILIAL  = E3.E3_FILIAL  
			 AND E1.E1_TIPO    = E3.E3_TIPO 
			 AND E1.E1_PREFIXO = E3.E3_PREFIXO 
			 AND E1.E1_NUM     = E3.E3_NUM   
			 AND E1.E1_SERIE   = E3.E3_SERIE 
			 AND E1.E1_PARCELA = E3.E3_PARCELA 
			 AND E1.E1_CLIENTE = E3.E3_CODCLI 
			 AND E1.E1_LOJA    = E3.E3_LOJA
			 
			 INNER JOIN %Table:SF2% F2
			 ON 
			     F2.F2_FILIAL  = E1.E1_FILIAL 
			 AND F2.F2_DOC     = E1.E1_NUM 
			 AND (F2.F2_SERIE  = E1.E1_PREFIXO OR E1.E1_PREFIXO = 'R')
			 AND F2.F2_CLIENTE = E1.E1_CLIENTE 
			 AND F2.F2_LOJA    = E1.E1_LOJA 

			 WHERE 
			     E3.D_E_L_E_T_ = ' ' 
			 AND E1.D_E_L_E_T_ = ' ' 
			 AND F2.D_E_L_E_T_ = ' ' 
			 AND A3.D_E_L_E_T_ = ' ' 
			 AND E3.E3_COMIS   > 0 
			 %Exp:_cWhere01%
			 AND E3.E3_I_FECH = 'S' 
			 GROUP BY E3.E3_VEND , SubStr(E3_EMISSAO,1,6)
			 
			 UNION ALL 
			 
			 SELECT 
			     E3.E3_VEND CODGER, 
			     SubStr(E3_EMISSAO,1,6) ANOMES, 
			     SUM(E3.E3_COMIS) COMISSAO 
			 FROM %Table:SE3% E3 

             INNER JOIN %Table:SA3% A3
	               ON A3.A3_COD = E3.E3_VEND 
			 
			 INNER JOIN %Table:SE1% E1  
			 ON 
			     E1.E1_FILIAL  = E3.E3_FILIAL  
			 AND E1.E1_TIPO    = E3.E3_TIPO 
			 AND E1.E1_PREFIXO = E3.E3_PREFIXO 
			 AND E1.E1_NUM     = E3.E3_NUM   
			 AND E1.E1_SERIE   = E3.E3_SERIE 
			 AND E1.E1_PARCELA = E3.E3_PARCELA 
			 AND E1.E1_CLIENTE = E3.E3_CODCLI 
			 AND E1.E1_LOJA    = E3.E3_LOJA  
			 ,(  SELECT DISTINCT 
			         SE5.E5_FILIAL, 
			         SE5.E5_DOCUMEN, 
			         MIN( Case 
			             WHEN F2.F2_VEND2 = ' '          THEN 'A' 
			             WHEN F2.F2_VEND1 <> F2.F2_VEND2 THEN 'B' 
			             WHEN F2.F2_VEND3 <> ' '         THEN 'C' 
			         END ) AS TIPOVENDA, 
			         Case 
			             WHEN F2.F2_VEND2 = ' '          THEN F2.F2_VEND1 
			             WHEN F2.F2_VEND1 <> F2.F2_VEND2 THEN F2.F2_VEND2 
			             WHEN F2.F2_VEND3 <> ' '         THEN F2.F2_VEND3 
			         END AS CODANL 
			     FROM %Table:SE5% SE5 
			     JOIN %Table:SF2% F2 
			     ON 
			         F2.F2_FILIAL  = SE5.E5_FILIAL 
			     AND F2.F2_DOC     = SE5.E5_NUMERO 
			     AND (F2.F2_SERIE   = SE5.E5_PREFIXO OR SE5.E5_PREFIXO = 'R')
			     AND F2.F2_CLIENTE = SE5.E5_CLIFOR 
			     AND F2.F2_LOJA    = SE5.E5_LOJA 
			     WHERE 
			         SE5.D_E_L_E_T_ = ' ' 
			     AND F2.D_E_L_E_T_ = ' ' 
			     AND SE5.E5_SITUACA <> 'C' 
			     AND SE5.E5_DOCUMEN  <> ' ' 
			     GROUP BY 
			         SE5.E5_FILIAL, 
			         SE5.E5_DOCUMEN, 
			         Case 
			             WHEN F2.F2_VEND2 = ' '          THEN F2.F2_VEND1 
			             WHEN F2.F2_VEND1 <> F2.F2_VEND2 THEN F2.F2_VEND2 
			             WHEN F2.F2_VEND3 <> ' '         THEN F2.F2_VEND3 
			         END 
			 ) DADOSLIQ 
			 
			 WHERE 
			     E3.D_E_L_E_T_ = ' ' 
			 AND E1.D_E_L_E_T_ = ' ' 
			
			 AND E3.E3_VEND    = DADOSLIQ.CODANL 
			 AND E1.E1_NUMLIQ  = DADOSLIQ.E5_DOCUMEN 
			 AND E1.E1_FILIAL  = DADOSLIQ.E5_FILIAL 
			 AND E3.E3_COMIS   > 0 
			 AND E1.E1_ORIGEM  = 'FINA460' 
			 %Exp:_cWhere01%
			 AND E3.E3_I_FECH  = 'S' 
			 
			 GROUP BY E3.E3_VEND , SubStr(E3_EMISSAO,1,6) 
			 
			 UNION ALL 
			 
			 SELECT 
			     E3.E3_VEND CODGER,  
			     SubStr(E3_EMISSAO,1,6) ANOMES, 
			     SUM(E3.E3_COMIS) COMISSAO    
			 FROM %Table:SE3% E3
			 
			 INNER JOIN %Table:SA1% A1  
			 ON 
			     A1.A1_COD     = E3.E3_CODCLI 
			 AND A1.A1_LOJA    = E3.E3_LOJA 
            
             INNER JOIN %Table:SA3% A3
	               ON A3.A3_COD = E3.E3_VEND 

			 WHERE 
			     E3.D_E_L_E_T_ = ' ' 
			 AND A1.D_E_L_E_T_ = ' ' 
			 AND A3.D_E_L_E_T_ = ' '
			 AND E3.E3_TIPO    = 'NCC'
			 %Exp:_cWhere01%
			 AND E3.E3_I_FECH  = 'S' 
			 AND E3.E3_NUM     IN ( SELECT D1.D1_DOC 
			                        FROM %Table:SD1% D1 , %Table:SF2% F2 
			                        WHERE 
			                            D1.D_E_L_E_T_ = ' ' 
			                        AND F2.D_E_L_E_T_ = ' ' 
			                        AND E3.E3_FILIAL  = D1.D1_FILIAL  
			                        AND E3.E3_NUM     = D1.D1_DOC 
			                        AND E3.E3_SERIE   = D1.D1_SERIE 
			                        AND E3.E3_CODCLI  = D1.D1_FORNECE  
			                        AND E3.E3_LOJA    = D1.D1_LOJA 
			                        AND F2.F2_FILIAL  = D1.D1_FILIAL 
			                        AND F2.F2_DOC     = D1.D1_NFORI 
			                        AND F2.F2_SERIE   = D1.D1_SERIORI 
			                        AND F2.F2_CLIENTE = D1.D1_FORNECE  
			                        AND F2.F2_LOJA    = D1.D1_LOJA 
			                        AND (  ( F2.F2_VEND2 = ' '          AND F2.F2_VEND1 = E3.E3_VEND )  
			                            OR ( F2.F2_VEND1 <> F2.F2_VEND2 AND F2.F2_VEND2 = E3.E3_VEND ) 
			                            OR ( F2.F2_VEND3 = E3.E3_VEND   ) ) 
			 ) 
			 GROUP BY E3.E3_VEND , SubStr(E3_EMISSAO,1,6) 
			 
			 UNION ALL 
			 
			 SELECT 
			     E3.E3_VEND             AS CODGER, 
			     SubStr(E3_EMISSAO,1,6) AS ANOMES, 
			     SUM(E3.E3_COMIS)       AS COMISSAO 
			 FROM %Table:SE3% E3
			 
			 INNER JOIN %Table:SA1% A1
			 ON 
			     A1.A1_COD     = E3.E3_CODCLI 
			 AND A1.A1_LOJA    = E3.E3_LOJA 

             INNER JOIN %Table:SA3% A3
	             ON A3.A3_COD = E3.E3_VEND 

			 WHERE 
			     E3.D_E_L_E_T_ = ' ' 
			 AND A1.D_E_L_E_T_ = ' ' 
			 AND A3.D_E_L_E_T_ = ' '
			 
			 AND E3.E3_TIPO    = 'NCC'
			 %Exp:_cWhere01%
			 AND E3.E3_I_FECH  = 'S' 
			 AND E3.E3_NUM     NOT IN ( SELECT D1.D1_DOC 
			                            FROM %Table:SD1% D1 , %Table:SF2% F2 
			                            WHERE 
			                                D1.D_E_L_E_T_ = ' ' 
			                            AND F2.D_E_L_E_T_ = ' ' 
			                            AND E3.E3_FILIAL  = D1.D1_FILIAL 
			                            AND E3.E3_NUM     = D1.D1_DOC 
			                            AND E3.E3_SERIE   = D1.D1_SERIE 
			                            AND E3.E3_CODCLI  = D1.D1_FORNECE 
			                            AND E3.E3_LOJA    = D1.D1_LOJA 
			                            AND F2.F2_FILIAL  = D1.D1_FILIAL 
			                            AND F2.F2_DOC     = D1.D1_NFORI 
			                            AND F2.F2_SERIE   = D1.D1_SERIORI 
			                            AND F2.F2_CLIENTE = D1.D1_FORNECE 
			                            AND F2.F2_LOJA    = D1.D1_LOJA 
			 ) 
			 GROUP BY E3.E3_VEND , SubStr(E3_EMISSAO,1,6)
			 
			 ORDER BY CODGER , ANOMES
			
		   EndSql
		Else 
		   If MV_PAR09 == 'Analitico' // 1 // 'Analitico'  ,'Previa-Sintetic','Excel', 'Impresso Novo' 	
              _nMesAtual := Val( SubStr( _cMvMesAno , 1 , 2 ) )
	          _nAnoAtual := Val( SubStr( _cMvMesAno , 3 , 4 ) )
		   Else 
              _nMesAtual := Val( SubStr( MV_PAR01 , 1 , 2 ) )
	          _nAnoAtual := Val( SubStr( MV_PAR01 , 3 , 4 ) )
		   EndIf  
		   //================================================================================
		   // Seleciona os ultimos tres meses de acordo com a data de fechamento fornecida
		   // pelo usuario.
		   //================================================================================
		   _a3MesesAn:= ROMS030S3M( _nMesAtual , _nAnoAtual , 1 )
		
		   _cAnoMesIn := Str( _a3MesesAn[5] , 4 ) + _a3MesesAn[2] + '01'
		   _cAnoMesFi := DToS( LastDay( SToD( Str( _a3MesesAn[7] , 4 ) + _a3MesesAn[4] + '01' ) ) )
		   
		   _cWhere01 := "% AND F2.F2_VEND1 = '"+ _cCodRepSA3 + "' %" 

		   _cWhere03 := "% AND E3.E3_VEND = '" + _cCodRepSA3 + "' %" 
           _cWhere04 := "% AND SF2.F2_VEND1 = '"+ _cCodRepSA3 + "' %" 
           
		   _cWhere02 := "% AND E3.E3_EMISSAO BETWEEN '"+ _cAnoMesIn +"' AND '"+ _cAnoMesFi +"' "

		   If MV_PAR10 == 'Interno CLT' // 1 // 'Interno CLT','Externo PJ' ,'Ambos'
		      _cWhere02 += " AND A3_TIPO = 'I' "
		   ElseIf MV_PAR10 == 'Externo PJ' // 2 // 'Interno CLT','Externo PJ' ,'Ambos'
		      _cWhere02 += " AND A3_TIPO = 'E' "
           EndIf

		   _cWhere02 += " %"

           BeginSql alias _cAlias

              SELECT 
		          E3.E3_VEND             AS CODGER, 
		          SubStr(E3_EMISSAO,1,6) AS ANOMES, 
		          SUM(E3.E3_COMIS)       AS COMISSAO 
		      FROM %Table:SE3% E3
        		   JOIN  %Table:SF2% F2  
		           ON  F2.F2_FILIAL  = E3.E3_FILIAL 
		               AND F2.F2_DOC     = E3.E3_NUM 
		               AND (F2.F2_SERIE   = E3.E3_PREFIXO)
		               AND F2.F2_CLIENTE = E3.E3_CODCLI 
		               AND F2.F2_LOJA    = E3.E3_LOJA 
              JOIN  %Table:SA3% A3  
		           ON  A3.A3_COD     = E3.E3_VEND 
		      WHERE 
		           E3.D_E_L_E_T_ = ' ' 
		           AND F2.D_E_L_E_T_ = ' ' 
		           AND A3.D_E_L_E_T_ = ' ' 
		           AND F2.F2_VEND1   <> F2.F2_VEND2 
		           AND F2.F2_VEND2   <> ' ' 
		           AND E3.E3_COMIS   > 0  
		           %Exp:_cWhere01%
		           AND E3.E3_I_FECH  = 'S' 
		           %Exp:_cWhere02%
		           GROUP BY E3.E3_VEND , SubStr(E3.E3_EMISSAO,1,6) 
		           
              UNION ALL 
		
		      SELECT 
		          E3.E3_VEND             AS CODGER, 
		          SubStr(E3_EMISSAO,1,6) AS ANOMES, 
		          SUM(E3.E3_COMIS)       AS COMISSAO 
		      FROM %Table:SE3% E3 
		          JOIN %Table:SA3% A3
		          ON A3.A3_COD = E3.E3_VEND 
		      WHERE 
		          E3.D_E_L_E_T_ = ' ' 
		          AND A3.D_E_L_E_T_ = ' ' 
		          AND E3.E3_COMIS   > 0 
		          %Exp:_cWhere03%  
		          AND E3.E3_I_FECH  = 'S' 
		          %Exp:_cWhere02%  
		          AND E3.E3_NUM     IN ( SELECT SE1.E1_FATURA 
		                       FROM  %Table:SE1% SE1 
		                       JOIN  %Table:SF2% SF2 
		                       ON  SF2.F2_FILIAL  = SE1.E1_FILIAL 
		                       AND SF2.F2_DOC     = SE1.E1_NUM 
		                       AND (SF2.F2_SERIE   = SE1.E1_PREFIXO OR SE1.E1_PREFIXO = 'R') 
		                       AND SF2.F2_CLIENTE = SE1.E1_CLIENTE 
		                       AND SF2.F2_LOJA    = SE1.E1_LOJA 
		                       WHERE 
		                           SE1.D_E_L_E_T_ = ' ' 
		                       AND SF2.D_E_L_E_T_ = ' ' 
		                       %Exp:_cWhere04% 
		                       AND SF2.F2_VEND1   <> SF2.F2_VEND2 
		                       AND SF2.F2_VEND2   <> ' ' 
		                       AND SE1.E1_FATPREF = E3.E3_PREFIXO 
		                       AND SE1.E1_FATURA  = E3.E3_NUM 
		                       AND SE1.E1_FILIAL  = E3.E3_FILIAL 
		                       AND SF2.F2_FILIAL  = E3.E3_FILIAL 
		                       AND SE1.E1_FATURA   <> ' ' ) 
		      GROUP BY E3.E3_VEND , SubStr(E3_EMISSAO,1,6) 
		   		
              UNION ALL 
		
		      SELECT 
		          E3.E3_VEND             AS CODGER, 
		          SubStr(E3_EMISSAO,1,6) AS ANOMES, 
		          SUM(E3.E3_COMIS)       AS COMISSAO 
	          FROM %Table:SE3% E3 
		
		      JOIN %Table:SE1% E1 
		      ON  E1.E1_FILIAL  = E3.E3_FILIAL 
		          AND E1.E1_TIPO    = E3.E3_TIPO 
		          AND E1.E1_PREFIXO = E3.E3_PREFIXO 
		          AND E1.E1_NUM     = E3.E3_NUM 
		          AND E1.E1_SERIE   = E3.E3_SERIE 
		          AND E1.E1_PARCELA = E3.E3_PARCELA 
	              AND E1.E1_CLIENTE = E3.E3_CODCLI 
		          AND E1.E1_LOJA    = E3.E3_LOJA 
		      JOIN %Table:SA3% A3 
		      ON  A3.A3_COD     = E3.E3_VEND 
		
		      WHERE 
		         E3.D_E_L_E_T_ = ' ' 
		         AND E1.D_E_L_E_T_ = ' ' 
		         AND A3.D_E_L_E_T_ = ' ' 
		         AND E3.E3_COMIS   > 0 
		         %Exp:_cWhere03% 
		         AND E3.E3_I_FECH  = 'S' 
		         %Exp:_cWhere02% 
		         AND E1.E1_NUMLIQ  IN ( SELECT SE5.E5_DOCUMEN 
		                                FROM %Table:SE5% SE5 
		                                     JOIN %Table:SF2% SF2 
		                                     ON  SF2.F2_FILIAL  = SE5.E5_FILIAL 
		                                     AND SF2.F2_DOC     = SE5.E5_NUMERO 
		                                     AND (SF2.F2_SERIE   = SE5.E5_PREFIXO OR SE5.E5_PREFIXO = 'R')
		                                     AND SF2.F2_CLIENTE = SE5.E5_CLIFOR 
		                                     AND SF2.F2_LOJA    = SE5.E5_LOJA 
		                                     WHERE 
		                                     SE5.D_E_L_E_T_ = ' ' 
		                                     AND SF2.D_E_L_E_T_ = ' ' 
		                                     %Exp:_cWhere04%  
		                                     AND SF2.F2_VEND1 <> SF2.F2_VEND2 
		                                     AND SF2.F2_VEND2 <> ' ' 
		                                     AND SE5.E5_DOCUMEN = E1.E1_NUMLIQ 
		                                     AND SE5.E5_FILIAL  = E1.E1_FILIAL 
		                                     AND SF2.F2_FILIAL  = E1.E1_FILIAL 
		                                     AND SE5.E5_DOCUMEN <> ' ' ) 
		         AND E1.E1_ORIGEM = 'FINA460' 
		         GROUP BY E3.E3_VEND , SubStr(E3_EMISSAO,1,6) 
		
    	         UNION ALL 
		
		         SELECT 
		             E3.E3_VEND             AS CODGER,      
		             SubStr(E3_EMISSAO,1,6) AS ANOMES,       
		             SUM(E3.E3_COMIS)       AS COMISSAO  
	             FROM %Table:SE3% E3,
		              %Table:SA3% A3,  
		              ( SELECT DISTINCT 
		                         F2.F2_VEND1, 
		                         F2.F2_VEND2, 
		                         D1.D1_FILIAL, 
		                         D1.D1_DOC, 
		                         D1.D1_SERIE, 
                                 D1.D1_FORNECE, 
                                 D1.D1_LOJA 
                                 FROM %Table:SD1% D1, %Table:SF2% F2 
                                 WHERE 
                                 D1.D_E_L_E_T_ = ' ' 
		                         AND F2.D_E_L_E_T_ = ' ' 
		                         AND F2.F2_FILIAL  = D1.D1_FILIAL 
		                         AND F2.F2_DOC     = D1.D1_NFORI 
		                         AND F2.F2_SERIE   = D1.D1_SERIORI 
		                         AND F2.F2_CLIENTE = D1.D1_FORNECE 
		                         AND F2.F2_LOJA    = D1.D1_LOJA 
		                         AND F2.F2_VEND1   <> F2.F2_VEND2 
		                         AND F2.F2_VEND2   <> ' ' 
		                         %Exp:_cWhere01% 
		                ) COORDENAD 
		         WHERE 
		            E3.D_E_L_E_T_ = ' ' 
		            AND A3.D_E_L_E_T_ = ' ' 
		            AND E3.E3_FILIAL  = COORDENAD.D1_FILIAL 
		            AND E3.E3_NUM     = COORDENAD.D1_DOC 
		            AND E3.E3_SERIE   = COORDENAD.D1_SERIE 
		            AND E3.E3_CODCLI  = COORDENAD.D1_FORNECE 
		            AND E3.E3_LOJA    = COORDENAD.D1_LOJA 
		            AND E3.E3_VEND    = COORDENAD.F2_VEND1 
		            AND A3.A3_COD     = E3.E3_VEND 
		            AND E3.E3_TIPO    = 'NCC' 
		            AND E3.E3_I_FECH  = 'S' 
		            %Exp:_cWhere02% 
		         GROUP BY E3.E3_VEND , SubStr(E3_EMISSAO,1,6) 
		         
		         UNION ALL 
		
		         SELECT 
		             E3.E3_VEND             AS CODGER, 
		             SubStr(E3_EMISSAO,1,6) AS ANOMES, 
		             SUM(E3.E3_COMIS)       AS COMISSAO 
		         FROM %Table:SE3% E3  
		         JOIN %Table:SA3% A3  
		         ON E3.E3_VEND = A3.A3_COD 
		         WHERE 
		            E3.D_E_L_E_T_ = ' ' 
		            AND A3.D_E_L_E_T_ = ' ' 
		            AND E3.E3_TIPO    = 'NCC' 
		            AND A3.A3_COD     <> A3.A3_SUPER 
		            AND A3.A3_SUPER   <> ' ' 
		            %Exp:_cWhere03% 
	            	AND E3.E3_I_FECH  = 'S' 
		            %Exp:_cWhere02% 
		            AND E3.E3_NUM NOT IN ( SELECT D1.D1_DOC 
		                                   FROM %Table:SD1% D1, %Table:SF2% F2 
		                                   WHERE  
		                                      D1.D_E_L_E_T_ = ' ' 
		                                      AND F2.D_E_L_E_T_ = ' ' 
		                                      AND E3.E3_FILIAL  = D1.D1_FILIAL 
		                                      AND E3.E3_NUM     = D1.D1_DOC 
		                                      AND E3.E3_SERIE   = D1.D1_SERIE 
		                                      AND E3.E3_CODCLI  = D1.D1_FORNECE 
		                                      AND E3.E3_LOJA    = D1.D1_LOJA 
		                                      AND F2.F2_FILIAL  = D1.D1_FILIAL 
		                                      AND F2.F2_DOC     = D1.D1_NFORI 
		                                      AND F2.F2_SERIE   = D1.D1_SERIORI 
		                                      AND F2.F2_CLIENTE = D1.D1_FORNECE 
		                                      AND F2.F2_LOJA    = D1.D1_LOJA 
		                                       %Exp:_cWhere01% ) 
		            GROUP BY E3.E3_VEND, SubStr(E3_EMISSAO,1,6)
		
		            UNION ALL 
		
		            SELECT 
		                E3.E3_VEND             AS CODGER, 
		                SubStr(E3_EMISSAO,1,6) AS ANOMES, 
		                SUM(E3.E3_COMIS)       AS COMISSAO 
		            FROM  %Table:SE3% E3 
		   		          JOIN %Table:SA3% A3 
		                  ON  A3.A3_COD = E3.E3_VEND 
				    WHERE  
		                E3.D_E_L_E_T_ = ' ' 
		                AND A3.D_E_L_E_T_ = ' ' 
		                AND E3.E3_I_FECH  = 'S' 
		                %Exp:_cWhere03% 
		                AND E3.E3_I_ORIGE = 'MOMS015' 
		                %Exp:_cWhere02% 
		   
		            GROUP BY E3.E3_VEND , SubStr(E3.E3_EMISSAO,1,6) 
		
		            ORDER BY CODGER , ANOMES 
	            
           EndSql
           
		EndIf 
					    			
	//====================================================================================================
	// Query para selecionar os dados cadastrais do Gerente no cadastro de fornecedor.
	//====================================================================================================
	Case _nOpcao == 4
	
		If MV_PAR10 == 'Interno CLT' // 1 // 'Interno CLT','Externo PJ' ,'Ambos'
		   _cWhere01 := "% AND A3.A3_COD = '" + _cCodRepSA3 + "' AND A3.A3_I_TIPV = '" + _cTipoRepSA3 + "' AND A3_TIPO = 'I' %"
        ElseIf MV_PAR10 == 'Externo PJ' // 2 // 'Interno CLT','Externo PJ' ,'Ambos' 
           _cWhere01 := "% AND A3.A3_COD = '" + _cCodRepSA3 + "' AND A3.A3_I_TIPV = '" + _cTipoRepSA3 + "' AND A3_TIPO = 'E' %"
		Else
		   _cWhere01 := "% AND A3.A3_COD = '" + _cCodRepSA3 + "' AND A3.A3_I_TIPV = '" + _cTipoRepSA3 + "' %"
        EndIf 
				
		BeginSql alias _cAlias
		
			SELECT
			    A3.A3_NOME,
			    A2.A2_EMAIL,
			    A2.A2_CGC,
			    A2.A2_BANCO,
			    A2.A2_AGENCIA,
			    A2.A2_NUMCON,
			    A2_I_CGCFD,
			    A2_I_NOMFD,
			    A2.A2_I_CODOP,
			    A3.A3_I_NOMEF,
			    A3.A3_I_REGIS
			    
			FROM %Table:SA3% A3
			INNER JOIN %Table:SA2% A2
			ON
			    A3.A3_FORNECE = A2.A2_COD
			AND A3.A3_LOJA    = A2.A2_LOJA
			WHERE
			    A3.%NotDel%
			AND A2.%NotDel%
			%Exp:_cWhere01%
			
		EndSql

    //====================================================================================================
	// Seleciona o historico de vendas dos Coordenadores
	//====================================================================================================
	Case _nOpcao == 5
         
		If MV_PAR09 == 'Analitico' // 1 // 'Analitico'  ,'Previa-Sintetic','Excel', 'Impresso Novo' 	
           _nMesAtual:= Val(SubStr(_cMvMesAno,1,2))
		   _nAnoAtual:= Val(SubStr(_cMvMesAno,3,4))			                                            			  
        Else 
		   _nMesAtual:= Val(SubStr(MV_PAR01,1,2))
		   _nAnoAtual:= Val(SubStr(MV_PAR01,3,4))			                                            			
		EndIf 
		//====================================================================================================
		// Seleciona os ultimos tres meses de acordo com a data atual do servidor.
		//====================================================================================================
		_a3MesesAn:= ROMS030S3M( _nMesAtual , _nAnoAtual , 1 )
		
		_cAnoMesIn:= Str(_a3MesesAn[5],4) + _a3MesesAn[2] + '01'

		If MV_PAR09 == 'Analitico' // 1 // 'Analitico'  ,'Previa-Sintetic','Excel', 'Impresso Novo' 
           _cAnoMesFi:= DToS(LastDay(SToD(SubStr(_cMvMesAno,3,4) + SubStr(_cMvMesAno,1,2) + '01')))                                          
		Else 
		   _cAnoMesFi:= DToS(LastDay(SToD(SubStr(MV_PAR01,3,4) + SubStr(MV_PAR01,1,2) + '01')))                                          
		EndIf 

		_cFilV4   += " AND F2_EMISSAO BETWEEN '" + _cAnoMesIn + "' AND '" + _cAnoMesFi + "'" 	                 					
		
		If _cTipoRepSA3 == 'G' 
		   _cFilV4 += " AND F2.F2_VEND3 = '" + _cCodRepSA3 + "' "
		   
           _cFilV4 += " AND F2.F2_VEND3 = A3.A3_COD "
		   
		ElseIf _cTipoRepSA3 == 'C'
		   _cFilV4 += " AND F2.F2_VEND2 = '" + _cCodRepSA3 + "' "
		   
           _cFilV4 += " AND F2.F2_VEND2 = A3.A3_COD "
		   
		ElseIf _cTipoRepSA3 == 'S'
		   _cFilV4 += " AND F2.F2_VEND4 = '" + _cCodRepSA3 + "' "
		   
           _cFilV4 += " AND F2.F2_VEND4 = A3.A3_COD "
		   
		ElseIf _cTipoRepSA3 == 'V'
		   _cFilV4 += " AND F2.F2_VEND1 = '" + _cCodRepSA3 + "' "
		   
           _cFilV4 += " AND F2.F2_VEND1 = A3.A3_COD "
		   
		ElseIf _cTipoRepSA3 == 'N'
		   _cFilV4 += " AND F2.F2_VEND5 = '" + _cCodRepSA3 + "' " 
		   
           _cFilV4 += " AND F2.F2_VEND5 = A3.A3_COD "
		   
		EndIf
        
		If MV_PAR10 == 'Interno CLT' // 1 // 'Interno CLT','Externo PJ' ,'Ambos' 
		   _cFilV4 += " AND A3.A3_TIPO = 'I' "
		ElseIf MV_PAR10 == 'Externo PJ' // 2 // 'Interno CLT','Externo PJ' ,'Ambos' 
		   _cFilV4 += " AND A3.A3_TIPO = 'E' "
        EndIf

		_cFilV4   += "%"
		
		BeginSql alias _cAlias
		
		SELECT
			D2.D2_FILIAL,
			D2.D2_DOC,
			D2.D2_SERIE,
			D2.D2_CLIENTE,
			D2.D2_LOJA,   
			D2.D2_COD,
			F2.F2_VEND3,
            F2.F2_VEND2,
		    F2.F2_VEND4,
			F2.F2_VEND5,
		    F2.F2_VEND1,
			SubStr(F2_EMISSAO,1,6) ANOMES,
			( SUM( D2.D2_VALBRUT ) - (	SELECT COALESCE(SUM(D1.D1_TOTAL + D1.D1_ICMSRET),0)
										FROM %Table:SD1% D1
										WHERE
											D1.D_E_L_E_T_ = ' '
										AND D1.D1_TIPO    = 'D'
										AND D1.D1_FILIAL  = D2.D2_FILIAL
										AND D1.D1_NFORI   = D2.D2_DOC
										AND D1.D1_SERIORI = D2.D2_SERIE
										AND D1.D1_FORNECE = D2.D2_CLIENTE
										AND D1.D1_LOJA    = D2.D2_LOJA
										AND D1.D1_COD     = D2.D2_COD ) ) VLRBRUT

		FROM %Table:SF2% F2, %Table:SD2% D2, %Table:SA1% A1, %Table:SA3% A3

		WHERE
		    F2.D_E_L_E_T_  = ' '
		AND D2.D_E_L_E_T_  = ' '
		AND A1.D_E_L_E_T_  = ' '
		AND A3.D_E_L_E_T_  = ' '
		AND F2.F2_DUPL    <> ' '
        AND F2.F2_VEND3   <> ' '
        AND F2.F2_FILIAL  = D2.D2_FILIAL
		AND F2.F2_DOC     = D2.D2_DOC
		AND F2.F2_SERIE   = D2.D2_SERIE
		AND F2.F2_CLIENTE = D2.D2_CLIENTE
		AND F2.F2_LOJA    = D2.D2_LOJA
		AND A1.A1_COD     = D2.D2_CLIENTE
		AND A1.A1_LOJA    = D2.D2_LOJA
        %exp:_cFilV4%
        
		GROUP BY D2.D2_FILIAL, D2.D2_DOC, D2.D2_SERIE, D2.D2_CLIENTE, D2.D2_LOJA, D2.D2_COD, F2.F2_VEND3, F2.F2_VEND2, F2.F2_VEND4, F2.F2_VEND5, F2.F2_VEND1, SubStr( F2_EMISSAO , 1 , 6 )
		
		EndSql

	//====================================================================================================
	// Query para selecionar dentro dos tres meses adicionais ao que o usuario informar para retirar o 
	// relatorio os titulos com data a vencer quebrando por mes.
	//====================================================================================================
	Case _nOpcao == 6
		
		//====================================================================================================
		// Seleciona os proximos tres meses de acordo com a data fornecida pelo usuario.
		//====================================================================================================
		If MV_PAR09 == 'Analitico' // 1 // 'Analitico'  ,'Previa-Sintetic','Excel', 'Impresso Novo' 
           _nMesAtual	:= Val( SubStr( _cMvMesAno , 1 , 2 ) )
		   _nAnoAtual	:= Val( SubStr( _cMvMesAno , 3 , 4 ) )
		Else 
		   _nMesAtual	:= Val( SubStr( MV_PAR01 , 1 , 2 ) )
		   _nAnoAtual	:= Val( SubStr( MV_PAR01 , 3 , 4 ) )
		EndIf 

		_aMesesDup	:= ROMS030S3M( _nMesAtual , _nAnoAtual , 2 )
		
		_cMes01		:= AllTrim( Str( _aMesesDup[6] ) ) + _aMesesDup[2] 
		_cMes02		:= AllTrim( Str( _aMesesDup[7] ) ) + _aMesesDup[3] 
		_cMes03		:= AllTrim( Str( _aMesesDup[8] ) ) + _aMesesDup[4]				
		_dDtAcima	:= SToD( AllTrim( Str( _aMesesDup[9] ) ) + _aMesesDup[5] + '01' )
		
      If _cTipoRepSA3 == 'G' 
		   _cFilVend += " AND F2.F2_VEND3 = '" + _cCodRepSA3 + "' "
		   _cFilVend += " AND F2.F2_VEND3 = A3.A3_COD "
		   _cFilSE1	 += " AND E1.E1_VEND3 = '" + _cCodRepSA3 + "' " 
		   _cFilSE1	 += " AND E1.E1_VEND3 = A3.A3_COD "   
		ElseIf _cTipoRepSA3 == 'C'
		   _cFilVend += " AND F2.F2_VEND2 = '" + _cCodRepSA3 + "' "
		   _cFilVend += " AND F2.F2_VEND2 = A3.A3_COD "
		   _cFilSE1	 += " AND E1.E1_VEND2 = '" + _cCodRepSA3 + "' " 
		   _cFilSE1	 += " AND E1.E1_VEND2 = A3.A3_COD "
		ElseIf _cTipoRepSA3 == 'S'
		   _cFilVend += " AND F2.F2_VEND4 = '" + _cCodRepSA3 + "' "
		   _cFilVend += " AND F2.F2_VEND4 = A3.A3_COD "
		   _cFilSE1	 += " AND E1.E1_VEND4 = '" + _cCodRepSA3 + "' " 
		   _cFilSE1	 += " AND E1.E1_VEND4 = A3.A3_COD "
		ElseIf _cTipoRepSA3 == 'V'
		   _cFilVend += " AND F2.F2_VEND1 = '" + _cCodRepSA3 + "' "
		   _cFilVend += " AND F2.F2_VEND1 = A3.A3_COD "
		   _cFilSE1	 += " AND E1.E1_VEND1 = '" + _cCodRepSA3 + "' " 
		   _cFilSE1	 += " AND E1.E1_VEND1 = A3.A3_COD "
		ElseIf _cTipoRepSA3 == 'N'  
		   _cFilVend += " AND F2.F2_VEND5 = '" + _cCodRepSA3 + "' "
		   _cFilVend += " AND F2.F2_VEND5 = A3.A3_COD "
		   _cFilSE1	 += " AND E1.E1_VEND5 = '" + _cCodRepSA3 + "' " 
           _cFilSE1	 += " AND E1.E1_VEND5 = A3.A3_COD "  
		EndIf

        If MV_PAR10 == 'Interno CLT' // 1 // 'Interno CLT','Externo PJ' ,'Ambos' 
		   _cFilVend += " AND A3.A3_TIPO = 'I' "
		   _cFilSE1  += " AND A3.A3_TIPO = 'I' "
		ElseIf MV_PAR10 == 'Externo PJ' // 2 // 'Interno CLT','Externo PJ' ,'Ambos' 
		   _cFilVend += " AND A3.A3_TIPO = 'E' "
		   _cFilSE1  += " AND A3.A3_TIPO = 'E' "
        EndIf

		_cFilVend	+= "%"   
		_cFilSE1	+= "%"   
		
		BeginSql alias _cAlias
		
		SELECT
			SUM( DADOS.NUMDUP01		) NUMDUP01  ,
			SUM( DADOS.VENCTO01		) VENCTO01  ,
		    SUM( DADOS.NUMDUP02		) NUMDUP02  ,
			SUM( DADOS.VENCTO02		) VENCTO02  ,
			SUM( DADOS.NUMDUP03		) NUMDUP03  ,
			SUM( DADOS.VENCTO03		) VENCTO03  ,
			SUM( DADOS.NUMDUPACI	) NUMDUPACI ,
			SUM( DADOS.VENCTOACIMA	) VENCTOACIMA
		FROM (	SELECT
					COUNT(	Case
							WHEN %Exp:_cMes01% = SubStr(E1.E1_VENCREA,1,6)
							THEN E1.E1_SALDO
							END ) NUMDUP01,
					COALESCE( SUM(	Case
									WHEN %Exp:_cMes01% = SubStr(E1.E1_VENCREA,1,6)
									THEN ( ( E1.E1_SALDO + E1.E1_SDACRES ) - E1_SDDECRE )
									END ) , 0 ) VENCTO01,
					COUNT(	Case
							WHEN %Exp:_cMes02% = SubStr(E1.E1_VENCREA,1,6)
							THEN E1.E1_SALDO
							END ) NUMDUP02,
					COALESCE( SUM(	Case
									WHEN %Exp:_cMes02% = SubStr(E1.E1_VENCREA,1,6)
									THEN ( ( E1.E1_SALDO + E1.E1_SDACRES ) - E1_SDDECRE )
									END ) , 0 ) VENCTO02,
					COUNT(	Case
							WHEN %Exp:_cMes03% = SubStr(E1.E1_VENCREA,1,6)
							THEN E1.E1_SALDO
							END ) NUMDUP03,
					COALESCE( SUM(	Case
									WHEN %Exp:_cMes03% = SubStr(E1.E1_VENCREA,1,6)
									THEN ( (E1.E1_SALDO + E1.E1_SDACRES) - E1_SDDECRE )
									END ) , 0 ) VENCTO03,
					COUNT(	Case
							WHEN TO_DATE( E1.E1_VENCREA , 'YYYY/MM/DD' ) >= TO_DATE( %Exp:_dDtAcima% , 'YYYY/MM/DD' )
							THEN E1.E1_SALDO
							END ) NUMDUPACI,
					COALESCE( SUM(	Case
									WHEN TO_DATE( E1.E1_VENCREA , 'YYYY/MM/DD' ) >= TO_DATE( %Exp:_dDtAcima% , 'YYYY/MM/DD' )
									THEN ( ( E1.E1_SALDO + E1.E1_SDACRES ) - E1_SDDECRE )
									END ) , 0 ) VENCTOACIMA
				FROM %Table:SE1% E1, %Table:SF2% F2, %Table:SA3% A3
				WHERE
					E1.D_E_L_E_T_ = ' '
				AND F2.D_E_L_E_T_ = ' '
				AND A3.D_E_L_E_T_ = ' '
				AND ( ( E1.E1_SALDO + E1.E1_SDACRES ) - E1_SDDECRE ) > 0
				AND TO_DATE( E1.E1_VENCREA , 'YYYY/MM/DD' ) - TO_DATE( %Exp:DToS( Date() )% , 'YYYY/MM/DD' ) >= 0
				AND E1.E1_ORIGEM NOT IN ( 'FINA460' , 'FINA280' )
                AND F2.F2_FILIAL   = E1.E1_FILIAL
				AND F2.F2_DOC      = E1.E1_NUM
				AND (F2.F2_SERIE   = E1.E1_PREFIXO OR E1.E1_PREFIXO = 'R')
				AND F2.F2_CLIENTE  = E1.E1_CLIENTE
				AND F2.F2_LOJA     = E1.E1_LOJA
				
				%exp:_cFilVend% 
				
				AND F2.F2_VEND3   <> ' '

				UNION ALL
				
				SELECT
					COUNT(	Case
							WHEN %Exp:_cMes01% = SubStr( E1.E1_VENCREA , 1 , 6 )
							THEN E1.E1_SALDO
							END ) NUMDUP01,
					COALESCE( SUM(	Case
									WHEN %Exp:_cMes01% = SubStr( E1.E1_VENCREA , 1 , 6 )
									THEN ( ( E1.E1_SALDO + E1.E1_SDACRES ) - E1_SDDECRE )
									END ) , 0 ) VENCTO01,
					COUNT(	Case
							WHEN %Exp:_cMes02% = SubStr(E1.E1_VENCREA,1,6)
							THEN E1.E1_SALDO
							END ) NUMDUP02,
					COALESCE( SUM(	Case
									WHEN %Exp:_cMes02% = SubStr(E1.E1_VENCREA,1,6)
									THEN ( ( E1.E1_SALDO + E1.E1_SDACRES ) - E1_SDDECRE )
									END ) , 0 ) VENCTO02,
					COUNT(	Case
							WHEN %Exp:_cMes03% = SubStr(E1.E1_VENCREA,1,6)
							THEN E1.E1_SALDO
							END ) NUMDUP03,
					COALESCE( SUM(	Case
									WHEN %Exp:_cMes03% = SubStr(E1.E1_VENCREA,1,6)
									THEN ( ( E1.E1_SALDO + E1.E1_SDACRES ) - E1_SDDECRE )
									END ) , 0 ) VENCTO03,
					COUNT(	Case
							WHEN TO_DATE(E1.E1_VENCREA,'YYYY/MM/DD') >= TO_DATE(%Exp:_dDtAcima%,'YYYY/MM/DD')
							THEN E1.E1_SALDO
							END ) NUMDUPACI,
					COALESCE( SUM(	Case
									WHEN TO_DATE(E1.E1_VENCREA,'YYYY/MM/DD') >= TO_DATE(%Exp:_dDtAcima%,'YYYY/MM/DD')
									THEN ( ( E1.E1_SALDO + E1.E1_SDACRES ) - E1_SDDECRE )
									END ) , 0 ) VENCTOACIMA
				FROM %Table:SE1% E1

				WHERE
					E1.D_E_L_E_T_ = ' '
				AND E1.E1_ORIGEM  = 'FINA280'
				AND ( ( E1.E1_SALDO + E1.E1_SDACRES ) - E1_SDDECRE ) > 0
				AND TO_DATE( E1.E1_VENCREA , 'YYYY/MM/DD' ) - TO_DATE( %Exp:DToS(date())% , 'YYYY/MM/DD' ) >= 0
				AND E1.E1_NUM    IN (	SELECT SE1.E1_FATURA
										FROM %Table:SE1% SE1, %Table:SF2% F2, %Table:SA3% A3
										WHERE
											SE1.D_E_L_E_T_ = ' '
										AND F2.D_E_L_E_T_  = ' '
										AND A3.D_E_L_E_T_  = ' '
										AND F2.F2_FILIAL   = SE1.E1_FILIAL
										AND F2.F2_DOC      = SE1.E1_NUM
										AND (F2.F2_SERIE   = SE1.E1_PREFIXO OR SE1.E1_PREFIXO = 'R')
										AND F2.F2_CLIENTE  = SE1.E1_CLIENTE
										AND F2.F2_LOJA     = SE1.E1_LOJA
										
										%exp:_cFilVend% 
										
										AND F2.F2_VEND3   <> ' '
										AND SE1.E1_FATPREF = E1.E1_PREFIXO
										AND SE1.E1_FATURA  = E1.E1_NUM
										AND SE1.E1_FILIAL  = E1.E1_FILIAL
										AND F2.F2_FILIAL   = E1.E1_FILIAL
										AND SE1.E1_FATURA <> ' ' )
				
				UNION ALL
				
				SELECT
					COUNT(	Case
							WHEN %Exp:_cMes01% = SubStr(E1.E1_VENCREA,1,6)
							THEN E1.E1_SALDO
							END) NUMDUP01,
					COALESCE( SUM(	Case
									WHEN %Exp:_cMes01% = SubStr(E1.E1_VENCREA,1,6)
									THEN ( ( E1.E1_SALDO + E1.E1_SDACRES ) - E1_SDDECRE )
									END ) , 0 ) VENCTO01,
					COUNT(	Case
							WHEN %Exp:_cMes02% = SubStr(E1.E1_VENCREA,1,6)
							THEN E1.E1_SALDO
							END ) NUMDUP02,
					COALESCE( SUM(	Case
									WHEN %Exp:_cMes02% = SubStr(E1.E1_VENCREA,1,6)
									THEN ( ( E1.E1_SALDO + E1.E1_SDACRES ) - E1_SDDECRE )
									END ) , 0 ) VENCTO02,
					COUNT(	Case
							WHEN %Exp:_cMes03% = SubStr(E1.E1_VENCREA,1,6)
							THEN E1.E1_SALDO
							END ) NUMDUP03,
					COALESCE( SUM(	Case
									WHEN %Exp:_cMes03% = SubStr(E1.E1_VENCREA,1,6)
									THEN ( ( E1.E1_SALDO + E1.E1_SDACRES ) - E1_SDDECRE )
									END ) , 0 ) VENCTO03,
					COUNT(	Case
							WHEN TO_DATE(E1.E1_VENCREA,'YYYY/MM/DD') >= TO_DATE(%Exp:_dDtAcima%,'YYYY/MM/DD')
							THEN E1.E1_SALDO
							END ) NUMDUPACI,
					COALESCE( SUM(	Case
									WHEN TO_DATE(E1.E1_VENCREA,'YYYY/MM/DD') >= TO_DATE(%Exp:_dDtAcima%,'YYYY/MM/DD')
									THEN ( ( E1.E1_SALDO + E1.E1_SDACRES ) - E1_SDDECRE )
									END ) , 0 ) VENCTOACIMA
				FROM %Table:SE1% E1   
				WHERE
					E1.D_E_L_E_T_ = ' '
				AND E1.E1_ORIGEM  = 'FINA460'
				AND ( ( E1.E1_SALDO + E1.E1_SDACRES ) - E1_SDDECRE ) > 0
				AND TO_DATE( E1.E1_VENCREA , 'YYYY/MM/DD' ) - TO_DATE( %Exp:DToS(date())% , 'YYYY/MM/DD' ) >= 0
				AND E1.E1_NUMLIQ IN (	SELECT SE5.E5_DOCUMEN
										FROM %Table:SE5% SE5, %Table:SF2% F2, %Table:SA3% A3
										WHERE
											SE5.D_E_L_E_T_   = ' '
										AND F2.D_E_L_E_T_    = ' '
										AND A3.D_E_L_E_T_    = ' '
                                        AND F2.F2_FILIAL     = SE5.E5_FILIAL
										AND F2.F2_DOC        = SE5.E5_NUMERO
										AND (F2.F2_SERIE     = SE5.E5_PREFIXO OR SE5.E5_PREFIXO = 'R')
										AND F2.F2_CLIENTE    = SE5.E5_CLIFOR
										AND F2.F2_LOJA       = SE5.E5_LOJA
										%exp:_cFilVend% 
										AND F2.F2_VEND3      <> ' '
										AND SE5.E5_DOCUMEN   = E1.E1_NUMLIQ
										AND SE5.E5_FILIAL    = E1.E1_FILIAL
										AND F2.F2_FILIAL     = E1.E1_FILIAL
										AND SE5.E5_DOCUMEN   <> ' ' )
				
				UNION ALL
				
				SELECT
					COUNT(	Case
							WHEN %Exp:_cMes01% = SubStr(E1.E1_VENCREA,1,6)
							THEN E1.E1_SALDO
							END ) NUMDUP01,
					COALESCE( SUM(	Case
									WHEN %Exp:_cMes01% = SubStr(E1.E1_VENCREA,1,6)
									THEN ( ( E1.E1_SALDO + E1.E1_SDACRES ) - E1_SDDECRE )
									END ) , 0 ) VENCTO01,
					COUNT(	Case
							WHEN %Exp:_cMes02% = SubStr(E1.E1_VENCREA,1,6)
							THEN E1.E1_SALDO
							END ) NUMDUP02,
					COALESCE( SUM(	Case
									WHEN %Exp:_cMes02% = SubStr(E1.E1_VENCREA,1,6)
									THEN ( ( E1.E1_SALDO + E1.E1_SDACRES ) - E1_SDDECRE )
									END ) , 0 ) VENCTO02,
					COUNT(	Case
							WHEN %Exp:_cMes03% = SubStr(E1.E1_VENCREA,1,6)
							THEN E1.E1_SALDO
							END ) NUMDUP03,
					COALESCE( SUM(	Case
									WHEN %Exp:_cMes03% = SubStr(E1.E1_VENCREA,1,6)
									THEN ( ( E1.E1_SALDO + E1.E1_SDACRES ) - E1_SDDECRE )
									END ) , 0 ) VENCTO03,
					COUNT(	Case
							WHEN TO_DATE(E1.E1_VENCREA,'YYYY/MM/DD') >= TO_DATE(%Exp:_dDtAcima%,'YYYY/MM/DD')
							THEN E1.E1_SALDO
							END ) NUMDUPACI,
					COALESCE( SUM(	Case
									WHEN TO_DATE(E1.E1_VENCREA,'YYYY/MM/DD') >= TO_DATE(%Exp:_dDtAcima%,'YYYY/MM/DD')
									THEN ( ( E1.E1_SALDO + E1.E1_SDACRES ) - E1_SDDECRE )
									END ) , 0 ) VENCTOACIMA
				FROM %Table:SE1% E1, %Table:SA3% A3
				WHERE
					E1.D_E_L_E_T_   = ' '
				AND A3.D_E_L_E_T_   = ' '	
				AND E1.E1_TIPO  IN ( 'NF ' , 'ICM' )
				AND E1.E1_VEND1 <> ' '
				AND E1.E1_ORIGEM = 'FINA040'
				AND ( ( E1.E1_SALDO + E1.E1_SDACRES ) - E1_SDDECRE ) > 0
				AND TO_DATE( E1.E1_VENCREA , 'YYYY/MM/DD' ) - TO_DATE( %Exp:DToS(date())% , 'YYYY/MM/DD' ) >= 0
				%exp:_cFilSE1%  
		
		) DADOS
		
		EndSql

	//====================================================================================================
	// Query utilizada para filtrar os dados de vendas do mes de todos os vendedores que geraram comissao 
	// no periodo indicado para fechamento
	//====================================================================================================
	Case _nOpcao == 7
	    If MV_PAR09 == 'Analitico' // 1 // 'Analitico'  ,'Previa-Sintetic','Excel', 'Impresso Novo' 
           _cAnoMesIn	:= SubStr( _cMvMesAno , 3 , 4 ) + SubStr( _cMvMesAno , 1 , 2 ) + '01'
		   _cAnoMesFi	:= DToS( LastDay( SToD( SubStr( _cMvMesAno , 3 , 4 ) + SubStr( _cMvMesAno , 1 , 2 ) + '01' ) ) ) 
		Else 
		   If AllTrim(MV_PAR01) == AllTrim(MV_PAR02)
		      _cAnoMesIn	:= SubStr( MV_PAR01 , 3 , 4 ) + SubStr( MV_PAR01 , 1 , 2 ) + '01'
		      _cAnoMesFi	:= DToS( LastDay( SToD( SubStr( MV_PAR01 , 3 , 4 ) + SubStr( MV_PAR01 , 1 , 2 ) + '01' ) ) ) 
		   Else 
		      _cAnoMesIn	:= SubStr( MV_PAR01 , 3 , 4 ) + SubStr( MV_PAR01 , 1 , 2 ) + '01'
		      _cAnoMesFi	:= DToS( LastDay( SToD( SubStr( MV_PAR02 , 3 , 4 ) + SubStr( MV_PAR02 , 1 , 2 ) + '01' ) ) )     
		   EndIf 
        EndIf 

		_cFilV5		+= " AND F2_EMISSAO >= '"+ _cAnoMesIn +"' AND F2_EMISSAO <= '"+ _cAnoMesFi +"' "
		
        If _cTipoRepSA3 == 'G' 
		   _cFilV5 += " AND F2.F2_VEND3 = '" + _cCodRepSA3 + "' "
		   _cFilV5 += " AND F2.F2_VEND3 = A3.A3_COD " 
		ElseIf _cTipoRepSA3 == 'C'
		   _cFilV5 += " AND F2.F2_VEND2 = '" + _cCodRepSA3 + "' "
		   _cFilV5 += " AND F2.F2_VEND2 = A3.A3_COD " 
		ElseIf _cTipoRepSA3 == 'S'
		   _cFilV5 += " AND F2.F2_VEND4 = '" + _cCodRepSA3 + "' "
		   _cFilV5 += " AND F2.F2_VEND4 = A3.A3_COD " 
		ElseIf _cTipoRepSA3 == 'V'
		   _cFilV5 += " AND F2.F2_VEND1 = '" + _cCodRepSA3 + "' "
		   _cFilV5 += " AND F2.F2_VEND1 = A3.A3_COD " 
		ElseIf _cTipoRepSA3 == 'N'   
		   _cFilV5 += " AND F2.F2_VEND5 = '" + _cCodRepSA3 + "' "
		   _cFilV5 += " AND F2.F2_VEND5 = A3.A3_COD " 
		EndIf

 		If MV_PAR10 == 'Interno CLT' // 1  // 'Interno CLT','Externo PJ' ,'Ambos' 
		   _cFilV5 += " AND A3.A3_TIPO = 'I' "
		ElseIf MV_PAR10 == 'Externo PJ' // 2  // 'Interno CLT','Externo PJ' ,'Ambos' 
		   _cFilV5 += " AND A3.A3_TIPO = 'E' "
        EndIf

		_cFilV5		+= "%"
		
		BeginSql alias _cAlias
		
		SELECT
			DADOS.B1_I_SUBGR,
			(	SELECT ZB9.ZB9_DESSUB
				FROM %Table:ZB9% ZB9
				WHERE
					ZB9.D_E_L_E_T_ = ' '
				AND ZB9.ZB9_SUBGRU = DADOS.B1_I_SUBGR ) DESCSUB,
			DADOS.D2_UM       AS UM1    ,
			DADOS.D2_SEGUM    AS UM2    ,
			SUM(DADOS.QTD1)   AS QTD1   ,
			SUM(DADOS.QTD2)   AS QTD2   ,
			SUM(DADOS.VLBRUT) AS VLBRUT ,
			( SUM( DADOS.MEDIACOM ) / SUM( DADOS.CONTADOR ) ) AS MEDIA
		FROM (	SELECT
					B1.B1_I_SUBGR	                                         ,
					D2.D2_UM                                                 ,
					D2.D2_SEGUM                                              ,
					COALESCE(SUM(D2.D2_QUANT   - RESULTD1.QUANT1UM),0) QTD1  ,
					COALESCE(SUM(D2.D2_QTSEGUM - RESULTD1.QUANT2UM),0) QTD2  ,
					COALESCE(SUM(D2.D2_VALBRUT - RESULTD1.VLRBRUT ),0) VLBRUT,
					SUM(D2.D2_COMIS1) MEDIACOM                               ,
					COUNT(*) CONTADOR
				FROM %Table:SF2% F2
				
				JOIN %Table:SD2% D2
				ON  F2.F2_FILIAL  = D2.D2_FILIAL
				AND F2.F2_DOC     = D2.D2_DOC
				AND F2.F2_SERIE   = D2.D2_SERIE
				AND F2.F2_CLIENTE = D2.D2_CLIENTE
				AND F2.F2_LOJA    = D2.D2_LOJA
				
				JOIN %Table:SB1% B1
				ON  B1.B1_COD = D2.D2_COD
				
				,
				
    			(	SELECT
						D1.D1_FILIAL		                    ,
						D1.D1_NFORI                             ,
						D1.D1_SERIORI                           ,
						D1.D1_FORNECE                           ,
						D1.D1_LOJA                              ,
						D1.D1_COD                               ,
						COALESCE(SUM(D1.D1_QUANT  ),0) QUANT1UM ,
						COALESCE(SUM(D1.D1_QTSEGUM),0) QUANT2UM ,
						COALESCE(SUM(D1.D1_TOTAL+D1.D1_ICMSRET),0) VLRBRUT
					FROM %Table:SD1% D1
					
					WHERE
						D1.D_E_L_E_T_ = ' '
					AND D1.D1_TIPO    = 'D'
					
					GROUP BY D1.D1_FILIAL, D1.D1_NFORI, D1.D1_SERIORI, D1.D1_FORNECE, D1.D1_LOJA, D1.D1_COD ) RESULTD1
				
				, %Table:SA3% A3	

				WHERE
					F2.D_E_L_E_T_       = ' '
				AND D2.D_E_L_E_T_       = ' '
				AND A3.D_E_L_E_T_       = ' '
				AND B1.D_E_L_E_T_       = ' '
				AND F2.F2_DUPL         <> ' '
				AND F2.F2_VEND3        <> ' '
				AND RESULTD1.D1_FILIAL  = D2.D2_FILIAL
				AND RESULTD1.D1_NFORI   = D2.D2_DOC
				AND RESULTD1.D1_SERIORI = D2.D2_SERIE
				AND RESULTD1.D1_FORNECE = D2.D2_CLIENTE
				AND RESULTD1.D1_LOJA    = D2.D2_LOJA
				AND RESULTD1.D1_COD     = D2.D2_COD   
				AND ( D2.D2_QUANT - RESULTD1.QUANT1UM > 0 OR D2.D2_QTSEGUM - RESULTD1.QUANT2UM > 0 )
				
				%Exp:_cFilV5%  
				
				GROUP BY B1.B1_I_SUBGR, D2.D2_UM, D2.D2_SEGUM
				
				HAVING ( SUM( D2.D2_QUANT - RESULTD1.QUANT1UM ) > 0 OR SUM( D2.D2_QTSEGUM - RESULTD1.QUANT2UM ) > 0 )
				
				UNION ALL
				
				SELECT
					B1.B1_I_SUBGR      		  ,
					D2.D2_UM                  ,
					D2.D2_SEGUM               ,
					SUM(D2.D2_QUANT) QTD1     ,
					SUM(D2.D2_QTSEGUM) QTD2   ,
					SUM(D2.D2_VALBRUT) VLBRUT ,
					SUM(D2.D2_COMIS1) MEDIACOM,
					COUNT(*) CONTADOR
				FROM %Table:SF2% F2, %Table:SD2% D2, %Table:SB1% B1, %Table:SA3% A3

				WHERE
					F2.D_E_L_E_T_ = ' '
				AND D2.D_E_L_E_T_ = ' '
				AND A3.D_E_L_E_T_ = ' '
				AND B1.D_E_L_E_T_ = ' '
				AND F2.F2_DUPL   <> ' '
				AND F2.F2_VEND3  <> ' '
                AND F2.F2_FILIAL  = D2.D2_FILIAL
				AND F2.F2_DOC     = D2.D2_DOC
				AND F2.F2_SERIE   = D2.D2_SERIE
				AND F2.F2_CLIENTE = D2.D2_CLIENTE
				AND F2.F2_LOJA    = D2.D2_LOJA
				AND B1.B1_COD     = D2.D2_COD
				
				%Exp:_cFilV5% 
				
				AND NOT EXISTS (	SELECT 1
									FROM %Table:SD1% D1
									WHERE
										D1.D_E_L_E_T_ = ' '
									AND D1.D1_TIPO    = 'D'
									AND D1.D1_FILIAL  = D2.D2_FILIAL
									AND D1.D1_NFORI   = D2.D2_DOC
									AND D1.D1_SERIORI = D2.D2_SERIE
									AND D1.D1_FORNECE = D2.D2_CLIENTE
									AND D1.D1_LOJA    = D2.D2_LOJA
									AND D1.D1_COD     = D2.D2_COD )
				
				GROUP BY B1.B1_I_SUBGR, D2.D2_UM, D2.D2_SEGUM ) DADOS
		
		GROUP BY DADOS.B1_I_SUBGR, DADOS.D2_UM, DADOS.D2_SEGUM
		ORDER BY DADOS.D2_UM
		
		EndSql

   	//====================================================================================================
	// Query utilizada para filtrar os representantes, supervisores, coordenadores, gerentes que serão 
	// impressos no relatório. 
	//====================================================================================================
	Case _nOpcao == 8

		_cWhere03 := " "

        If MV_PAR10 == 'Interno CLT' // 1 // 'Interno CLT','Externo PJ' ,'Ambos' 
		   _cWhere03 += " AND A3_TIPO = 'I' "
		ElseIf MV_PAR10 == 'Externo PJ' // 2  // 'Interno CLT','Externo PJ' ,'Ambos' 
           _cWhere03 += " AND A3_TIPO = 'E' "
	    EndIf

		If ! Empty(MV_PAR03) //Gerente Nacional
		
		   _cWhere03 += " AND ( SA3.A3_COD IN " + FormatIn(MV_PAR03,";") + " ) "

		EndIf

		If ! Empty(MV_PAR04) //Gerente
										  
		   _cWhere03 += " AND ( SA3.A3_GEREN IN "+ FormatIn(MV_PAR04,";") + " OR SA3.A3_COD IN " + FormatIn(MV_PAR04,";") + " ) "
		   		
		EndIf
		
		If ! Empty(MV_PAR05) //Coordenador
	
		   _cWhere03 += " AND ( SA3.A3_SUPER IN "+ FormatIn(MV_PAR05,";")  + " OR SA3.A3_COD IN " + FormatIn(MV_PAR05,";")+ " ) "
		
	    EndIf
		
		If ! Empty(MV_PAR06) //Supervisor
		
		   _cWhere03 += " AND ( SA3.A3_I_SUPE IN "+ FormatIn(MV_PAR06,";")  + " OR SA3.A3_COD IN " + FormatIn(MV_PAR06,";")+ " ) "
		
	    EndIf
		
		If ! Empty(MV_PAR07) //Representante
		
		   _cWhere03 += " AND ( SA3.A3_COD IN "+ FormatIn(MV_PAR07,";")  + " OR SA3.A3_COD IN " + FormatIn(MV_PAR07,";")+ " ) "
		
	    EndIf
		
		If !Empty(_cWhere03)
		
		   _cWhere03 := "%" + _cWhere03 + "%"   
		Else 
		   _cWhere03 := "% %"	
		EndIf
			
		//================================================================= 
		// Se a pergunta Mostra Hierarquiva of igual a Simm a ordenação 
		// do relatório deve ser:
		// GERENTE
        // -- CORDENADOR
        // ----SUPERVISOR
        // ------VENDEDOR 1
        // ------VENDEDOR 2
        // ------VENDEDOR 3
        // -----SUPERVISOR2
        // ------VENDEDOR1
        // ------VENDEDOR2
        // ----VENDEDOR1(NOS CASOS QUE NÃO TEM SUPERVISOR)
        // ----VENDEDOR2
        // GERENTE2.... ETC
		//
		// Se a pergunta Mostra Hierarquia For Não, a ordenação do 
		// relatório deve ser:
		// GERENTE1
        // GERENTE2
        // GERENTE3
        // COORDENADOR1
        // COORDENADOR2
        // COORDENADOR 3
        // SUPERVISOR1
        // SUPERVISOR2
        // SUPERVISOR3
        // REPRESENTANTE1
        // REPRESENTANTE2
        // REPRESENTANTE3
		//=================================================================
        
        BeginSql alias _cAlias
		
		    SELECT
		            A3_COD, A3_I_TIPV, A3_GEREN, A3_SUPER, A3_I_SUPE, A3_I_GERNC, A3_NOME     
		    FROM %Table:SA3% SA3
		    WHERE SA3.D_E_L_E_T_ = ' ' 
    		        %Exp:_cWhere03%
		    ORDER BY A3_COD 
		
		EndSql
           
   	//====================================================================================================
	// Seleciona comissao de hierarquia para relacional
	//====================================================================================================
	Case _nOpcao == 9
	    If MV_PAR09 == 'Analitico' // 1 // 'Analitico'  ,'Previa-Sintetic','Excel', 'Impresso Novo' 
           _cWhere02 := "% AND SubStr(E3_EMISSAO,1,6) = '" + SubStr(_cMvMesAno,3,4) + SubStr(_cMvMesAno,1,2) + "' %" 
		Else 
	       If AllTrim(MV_PAR01) == AllTrim(MV_PAR02) 
		      _cWhere02 := "% AND SubStr(E3_EMISSAO,1,6) = '" + SubStr(MV_PAR01,3,4) + SubStr(MV_PAR01,1,2) + "' %"
		   Else 
		      _cWhere02 := "% AND SubStr(E3_EMISSAO,1,6) >= '" + SubStr(MV_PAR01,3,4) + SubStr(MV_PAR01,1,2) + "' AND SubStr(E3_EMISSAO,1,6) <= '"+ SubStr(MV_PAR02,3,4) + SubStr(MV_PAR02,1,2) + "' %"
		   EndIf
	    EndIf 

		//====================================================================================================
		// Gerente
		//====================================================================================================
		If MV_PAR10 == 'Interno CLT' // 1  // 'Interno CLT','Externo PJ' ,'Ambos' 
		   _cWhere01 := "% AND E3.E3_VEND = '" + _cCodRepSA3 + "' AND A3.A3_I_TIPV = '" + _cTipoRepSA3 + "' AND A3_TIPO = 'I' %"
		ElseIf MV_PAR10 == 'Externo PJ' // 2 // 'Interno CLT','Externo PJ' ,'Ambos' 
		   _cWhere01 := "% AND E3.E3_VEND = '" + _cCodRepSA3 + "' AND A3.A3_I_TIPV = '" + _cTipoRepSA3 + "' AND A3_TIPO = 'E' %"
		Else
		   _cWhere01 := "% AND E3.E3_VEND = '" + _cCodRepSA3 + "' AND A3.A3_I_TIPV = '" + _cTipoRepSA3 + "' %"
		EndIf

		If _cTipoRepSA3 = "V" // Extrato Vendedor
		   _cWhere04 := "% AND F2.F2_VEND1 = E3.E3_VEND %"
		EndIf
		
		If _cTipoRepSA3 = "S" // Extrato Supervisor
		   _cWhere04 := "% AND F2.F2_VEND4 = E3.E3_VEND %"
		EndIf
		
		If _cTipoRepSA3 = "C" // Extrato Coordenador
		   _cWhere04 := "% AND F2.F2_VEND2 = E3.E3_VEND %"
		EndIf
		
		If _cTipoRepSA3 = "G" // Extrato Gerente
		   _cWhere04 := "% AND F2.F2_VEND3 = E3.E3_VEND %"
		EndIf

		If _cTipoRepSA3 = "N" // Extrato Gerente Nacional 
		   _cWhere04 := "% AND F2.F2_VEND5 = E3.E3_VEND %"
		EndIf
		
		BeginSql alias _cAlias
		
			SELECT CODGER,NOME,DEDUCAO,ORIGEM,SUM(COMISSAO) as COMISSAO ,SUM(VLRRECEB) AS VLRRECEB FROM (
			SELECT                                   
			    F2.F2_VEND1       AS CODGER	,
			    A32.A3_NOME       AS NOME,
			    A3.A3_I_DEDUC    AS DEDUCAO ,
			    E3.E3_I_ORIGE    AS ORIGEM  ,
			    SUM(E3.E3_COMIS) AS COMISSAO,
			    SUM(E3.E3_BASE)  AS VLRRECEB
				    
			FROM %Table:SE3% E3
			
			JOIN %Table:SA3% A3
			ON
			    A3.A3_COD = E3.E3_VEND
			    
			JOIN %Table:SA3% A3
			ON
			    A3.A3_COD = E3.E3_VEND
			
			
			JOIN %Table:SE1% E1
			ON
			    E1_FILIAL  = E3_FILIAL
			AND E1_NUM     = E3_NUM
			AND E1_PREFIXO = E3_PREFIXO
			AND E1_PARCELA = E3_PARCELA
			AND E1_TIPO    = E3_TIPO
			AND E1_CLIENTE = E3_CODCLI
			AND E1_LOJA    = E3_LOJA
			
			JOIN %Table:SF2% F2
			ON
			    F2.F2_FILIAL  = E1.E1_FILIAL
			AND F2.F2_DOC     = E1.E1_NUM
			AND F2.F2_SERIE   = E1.E1_PREFIXO
			AND F2.F2_CLIENTE = E1.E1_CLIENTE
			AND F2.F2_LOJA    = E1.E1_LOJA
			%Exp:_cWhere04%   
			
			JOIN  %Table:SA3%  A32
			ON   A32.A3_COD = F2.F2_VEND1
  			 
			WHERE
			    E3.%NotDel%
			AND A3.%NotDel%
			AND A32.%NotDel%
			AND E1.%NotDel%
			AND F2.%NotDel%
			%Exp:_cWhere01%
			AND E3.E3_COMIS  > 0
			%Exp:_cWhere02%
			
			GROUP BY
			    F2.F2_VEND1   ,
			    A32.A3_NOME ,
			    A3.A3_I_DEDUC,
			    E3.E3_I_ORIGE
				
			UNION ALL
			
			SELECT
			    F2.F2_VEND1      AS CODGER	,
			    A32.A3_NOME       AS NOME,
			    A3.A3_I_DEDUC    AS DEDUCAO ,
			    E3.E3_I_ORIGE    AS ORIGEM  ,
			    SUM(E3.E3_COMIS) AS COMISSAO,
			    SUM(E3.E3_BASE)  AS VLRRECEB

			FROM %Table:SE3% E3
			
			INNER JOIN %Table:SE1% E1
			ON  E1.E1_FILIAL  = E3.E3_FILIAL
			AND E1.E1_TIPO    = E3.E3_TIPO
			AND E1.E1_PREFIXO = E3.E3_PREFIXO
			AND E1.E1_NUM     = E3.E3_NUM
			AND E1.E1_SERIE   = E3.E3_SERIE
			AND E1.E1_PARCELA = E3.E3_PARCELA
			AND E1.E1_CLIENTE = E3.E3_CODCLI
			AND E1.E1_LOJA    = E3.E3_LOJA
			
			INNER JOIN %Table:SA3% A3
			ON  A3.A3_COD     = E3.E3_VEND
			
			INNER JOIN %Table:SF2% F2
			ON  F2.F2_FILIAL  = E1.E1_FILIAL
			AND F2.F2_DOC     = E1.E1_NUM
			AND (F2.F2_SERIE   = E1.E1_PREFIXO OR E1.E1_PREFIXO = 'R')
			AND F2.F2_CLIENTE = E1.E1_CLIENTE
			AND F2.F2_LOJA    = E1.E1_LOJA
			%Exp:_cWhere04%    
			
			JOIN  %Table:SA3%  A32
			ON   A32.A3_COD = F2.F2_VEND1
			
			INNER JOIN %Table:SE5% E5
			ON  F2.F2_FILIAL  = E5.E5_FILIAL
			AND F2.F2_DOC     = E5.E5_NUMERO
			AND (F2.F2_SERIE   = E5.E5_PREFIXO OR E5.E5_PREFIXO = 'R')
			AND F2.F2_CLIENTE = E5.E5_CLIFOR
			AND F2.F2_LOJA    = E5.E5_LOJA
			AND E1.E1_NUMLIQ  = E5.E5_DOCUMEN
			AND E1.E1_FILIAL  = E5.E5_FILIAL
			AND E5.E5_SITUACA <> 'C'
			AND E5.E5_DOCUMEN <> ' '
			
			WHERE
			    E3.%NotDel%
			AND E1.%NotDel%
			AND A3.%NotDel%
			AND A32.%NotDel%
			AND F2.%NotDel%
			AND E5.%NotDel%
			AND E3.E3_COMIS  > 0  
			%Exp:_cWhere01%
			AND E1.E1_ORIGEM = 'FINA460'
			%Exp:_cWhere02%
			
			GROUP BY
			    F2.F2_VEND1  ,
			    A32.A3_NOME ,
			    A3.A3_I_DEDUC,
			    E3.E3_I_ORIGE
			)
			GROUP BY NOME,CODGER,DEDUCAO,ORIGEM				
			ORDER BY NOME,CODGER 
			
		EndSql


	//====================================================================================================
	// Seleciona comissao a pagar do mes de fechamento indicado pelo pelo usuario para os Gerentes
	//====================================================================================================
	Case _nOpcao == 10

		If MV_PAR09 == 'Analitico' // 1 // 'Analitico'  ,'Previa-Sintetic','Excel', 'Impresso Novo' 
           _cWhere02 := "% AND SubStr(E3_EMISSAO,1,6) = '" + SubStr(_cMvMesAno,3,4) + SubStr(_cMvMesAno,1,2) + "' %"
		Else     
	       If AllTrim(MV_PAR01) == AllTrim(MV_PAR02) 
		      _cWhere02 := "% AND SubStr(E3_EMISSAO,1,6) = '" + SubStr(MV_PAR01,3,4) + SubStr(MV_PAR01,1,2) + "' %"
           Else 
		      _cWhere02 := "% AND SubStr(E3_EMISSAO,1,6) >= '" + SubStr(MV_PAR01,3,4) + SubStr(MV_PAR01,1,2) + "' AND SubStr(E3_EMISSAO,1,6) <= '"+ SubStr(MV_PAR02,3,4) + SubStr(MV_PAR02,1,2) + "' %"
		   EndIf
	    EndIf 
		//====================================================================================================
		// Gerente
		//====================================================================================================
        If MV_PAR10 == 'Interno CLT' // 1 // 'Interno CLT','Externo PJ' ,'Ambos' 
		   _cWhere01 := "% AND E3.E3_VEND = '" + _cCodRepSA3 + "' AND A3.A3_I_TIPV = '" + _cTipoRepSA3 + "' AND A3_TIPO = 'I' "
		ElseIf MV_PAR10 == 'Externo PJ' //  2 // 'Interno CLT','Externo PJ' ,'Ambos' 
		   _cWhere01 := "% AND E3.E3_VEND = '" + _cCodRepSA3 + "' AND A3.A3_I_TIPV = '" + _cTipoRepSA3 + "' AND A3_TIPO = 'E' "
		Else
		   _cWhere01 := "% AND E3.E3_VEND = '" + _cCodRepSA3 + "' AND A3.A3_I_TIPV = '" + _cTipoRepSA3 + "' "
		EndIf

		If _cTipoRepSA3 = "V" // Extrato Vendedor
		   _cWhere04 := "% AND F2.F2_VEND1 = E3.E3_VEND %"
		EndIf
		
		If _cTipoRepSA3 = "S" // Extrato Supervisor
		   _cWhere04 := "% AND F2.F2_VEND4 = E3.E3_VEND %"
		   _cWhere01 += " AND (E1.E1_VEND4 = '" + _cCodRepSA3 + "' OR (E3.E3_VEND = '" + _cCodRepSA3 + "' AND E1.E1_VEND4 = '      ')) "
		EndIf
		
		If _cTipoRepSA3 = "C" // Extrato Coordenador
		   _cWhere04 := "% AND F2.F2_VEND2 = E3.E3_VEND %"
		   _cWhere01 += " AND (E1.E1_VEND2 = '" + _cCodRepSA3 + "' OR (E3.E3_VEND = '" + _cCodRepSA3 + "' AND E1.E1_VEND2 = '      ')) "
		EndIf
		
		If _cTipoRepSA3 = "G" // Extrato Gerente
		   _cWhere04 := "% AND F2.F2_VEND3 = E3.E3_VEND %"
		   _cWhere01 += " AND (E1.E1_VEND3 = '" + _cCodRepSA3 + "' OR (E3.E3_VEND = '" + _cCodRepSA3 + "' AND E1.E1_VEND3 = '      ')) "
		EndIf

		If _cTipoRepSA3 = "N" // Extrato Gerente Nacional
		   _cWhere04 := "% AND F2.F2_VEND5 = E3.E3_VEND %"
		   _cWhere01 += " AND (E1.E1_VEND5 = '" + _cCodRepSA3 + "' OR (E3.E3_VEND = '" + _cCodRepSA3 + "' AND E1.E1_VEND5 = '      ')) "
		EndIf
		
		_cWhere01 += " %"

		BeginSql alias _cAlias
		
			SELECT                                   
			    E3.E3_FILIAL     AS FILIAL  ,
			    E3.E3_VEND       AS CODGER	,
			    A3.A3_I_DEDUC    AS DEDUCAO ,
			    E3.E3_I_ORIGE    AS ORIGEM  ,
                E1.e1_vend1      AS VEND1, 
                E1.e1_vend2      AS VEND2, 
                E1.e1_vend3      AS VEND3, 
                E1.e1_vend4      AS VEND4, 
                E1.e1_comis1     AS COMIS1, 
                E1.e1_comis2     AS COMIS2, 
                E1.e1_comis3     AS COMIS3, 
                E1.e1_comis4     AS COMIS4, 
			    SUM(E3.E3_COMIS) AS COMISSAO,
			    SUM(E3.E3_BASE)  AS VLRRECEB
		    
			FROM %Table:SE3% E3
			
			JOIN %Table:SA3% A3
			ON
			    A3.A3_COD = E3.E3_VEND
			
			JOIN %Table:SE1% E1
			ON
			    E1_FILIAL  = E3_FILIAL
			AND E1_NUM     = E3_NUM
			AND E1_PREFIXO = E3_PREFIXO
			AND E1_PARCELA = E3_PARCELA
			AND E1_TIPO    = E3_TIPO
			AND E1_CLIENTE = E3_CODCLI
			AND E1_LOJA    = E3_LOJA
			
			JOIN %Table:SF2% F2
			ON
			    F2.F2_FILIAL  = E1.E1_FILIAL
			AND F2.F2_DOC     = E1.E1_NUM
			AND (F2.F2_SERIE   = E1.E1_PREFIXO)
			AND F2.F2_CLIENTE = E1.E1_CLIENTE
			AND F2.F2_LOJA    = E1.E1_LOJA
			%Exp:_cWhere04%    
			WHERE
			    E3.%NotDel%
			AND A3.%NotDel%
			AND E1.%NotDel%
			AND F2.%NotDel%
			%Exp:_cWhere01%
			AND E3.E3_COMIS  > 0
			%Exp:_cWhere02%
			
			GROUP BY
			    E3.E3_FILIAL ,
			    E3.E3_VEND   ,
			    A3.A3_I_DEDUC,
			    E3.E3_I_ORIGE,
			    E1.e1_vend1, 
                E1.e1_vend2, 
                E1.e1_vend3, 
                E1.e1_vend4, 
                E1.e1_comis1, 
                E1.e1_comis2, 
                E1.e1_comis3, 
                E1.e1_comis4 
			
			UNION ALL
			
			SELECT
			    E3.E3_FILIAL     AS FILIAL  ,
			    E3.E3_VEND       AS CODGER	,
			    A3.A3_I_DEDUC    AS DEDUCAO ,
			    E3.E3_I_ORIGE    AS ORIGEM  ,
                E1.e1_vend1      AS VEND1, 
                E1.e1_vend2      AS VEND2, 
                E1.e1_vend3      AS VEND3, 
                E1.e1_vend4      AS VEND4, 
                E1.e1_comis1     AS COMIS1, 
                E1.e1_comis2     AS COMIS2, 
                E1.e1_comis3     AS COMIS3, 
                E1.e1_comis4     AS COMIS4, 
			    SUM(E3.E3_COMIS) AS COMISSAO,
			    SUM(E3.E3_BASE)  AS VLRRECEB

			FROM %Table:SE3% E3
			
			INNER JOIN %Table:SE1% E1
			ON  E1.E1_FILIAL  = E3.E3_FILIAL
			AND E1.E1_TIPO    = E3.E3_TIPO
			AND E1.E1_PREFIXO = E3.E3_PREFIXO
			AND E1.E1_NUM     = E3.E3_NUM
			AND E1.E1_SERIE   = E3.E3_SERIE
			AND E1.E1_PARCELA = E3.E3_PARCELA
			AND E1.E1_CLIENTE = E3.E3_CODCLI
			AND E1.E1_LOJA    = E3.E3_LOJA
			
			INNER JOIN %Table:SA3% A3
			ON  A3.A3_COD     = E3.E3_VEND
			
			INNER JOIN %Table:SF2% F2
			ON  F2.F2_FILIAL  = E1.E1_FILIAL
			AND F2.F2_DOC     = E1.E1_NUM
			AND (F2.F2_SERIE   = E1.E1_PREFIXO OR E1.E1_PREFIXO = 'R')
			AND F2.F2_CLIENTE = E1.E1_CLIENTE
			AND F2.F2_LOJA    = E1.E1_LOJA
			%Exp:_cWhere04%    
					
			WHERE
			    E3.%NotDel%
			AND E1.%NotDel%
			AND A3.%NotDel%
			AND F2.%NotDel%
			AND E3.E3_COMIS  > 0  
			%Exp:_cWhere01%
			AND E1.E1_ORIGEM = 'FINA460'
			AND EXISTS(	SELECT E5.E5_DATA FROM %Table:SE5% E5
			  				WHERE  E5.%NotDel%
			  						AND F2.F2_FILIAL  = E5.E5_FILIAL
			  						AND F2.F2_DOC     = E5.E5_NUMERO
			  						AND (F2.F2_SERIE   = E5.E5_PREFIXO OR E5.E5_PREFIXO = 'R')
			  						AND F2.F2_CLIENTE = E5.E5_CLIFOR
			  						AND F2.F2_LOJA    = E5.E5_LOJA
			  						AND E1.E1_NUMLIQ  = E5.E5_DOCUMEN
			  						AND E1.E1_FILIAL  = E5.E5_FILIAL
			  						AND E5.E5_SITUACA <> 'C'
				  					AND E5.E5_DOCUMEN <> ' ')
			  						
			%Exp:_cWhere02%
			
			GROUP BY
			    E3.E3_FILIAL ,
			    E3.E3_VEND   ,
			    A3.A3_I_DEDUC,
			    E3.E3_I_ORIGE,
			    E1.e1_vend1, 
                E1.e1_vend2, 
                E1.e1_vend3, 
                E1.e1_vend4, 
                E1.e1_comis1, 
                E1.e1_comis2, 
                E1.e1_comis3, 
                E1.e1_comis4
			
			UNION ALL
			
			SELECT
			    E3.E3_FILIAL     AS FILIAL  ,
			    E3.E3_VEND       AS CODGER	,
			    A3.A3_I_DEDUC    AS DEDUCAO ,
			    E3.E3_I_ORIGE    AS ORIGEM  ,
                E1.e1_vend1      AS VEND1, 
                E1.e1_vend2      AS VEND2, 
                E1.e1_vend3      AS VEND3, 
                E1.e1_vend4      AS VEND4, 
                E1.e1_comis1     AS COMIS1, 
                E1.e1_comis2     AS COMIS2, 
                E1.e1_comis3     AS COMIS3, 
                E1.e1_comis4     AS COMIS4, 
			    SUM(E3.E3_COMIS) AS COMISSAO,
			    SUM(E3.E3_BASE)  AS VLRRECEB
			
			FROM %Table:SE3% E3
			
			INNER JOIN %Table:SA3% A3
			ON  E3.E3_VEND    = A3.A3_COD

			INNER JOIN %Table:SE1% E1
			ON  E1.E1_FILIAL  = E3.E3_FILIAL
			AND E1.E1_TIPO    = E3.E3_TIPO
			AND E1.E1_PREFIXO = E3.E3_PREFIXO
			AND E1.E1_NUM     = E3.E3_NUM
			AND E1.E1_SERIE   = E3.E3_SERIE
			AND E1.E1_PARCELA = E3.E3_PARCELA
			AND E1.E1_CLIENTE = E3.E3_CODCLI
			AND E1.E1_LOJA    = E3.E3_LOJA
			
			INNER JOIN %Table:SA1% A1
			ON  A1.A1_COD     = E3.E3_CODCLI
			AND A1.A1_LOJA    = E3.E3_LOJA
			
			WHERE
			    E3.%NotDel%
			AND A3.%NotDel%
			AND A1.%NotDel%
			AND E3.E3_TIPO   = 'NCC'
			%Exp:_cWhere01%
			AND E3.E3_NUM    IN (  SELECT D1.D1_DOC
			                       FROM %Table:SD1% D1 , %Table:SF2% F2
			                       WHERE
			                           D1.%NotDel%
			                       AND F2.%NotDel%
			                       AND E3.E3_FILIAL  = D1.D1_FILIAL
			                       AND E3.E3_NUM     = D1.D1_DOC
			                       AND E3.E3_SERIE   = D1.D1_SERIE
			                       AND E3.E3_CODCLI  = D1.D1_FORNECE
			                       AND E3.E3_LOJA    = D1.D1_LOJA
			                       AND F2.F2_FILIAL  = D1.D1_FILIAL
			                       AND F2.F2_DOC     = D1.D1_NFORI
			                       AND F2.F2_SERIE   = D1.D1_SERIORI
			                       AND F2.F2_CLIENTE = D1.D1_FORNECE
			                       AND F2.F2_LOJA    = D1.D1_LOJA
			                       %Exp:_cWhere04%    
			                    )
			%Exp:_cWhere02%
			GROUP BY
			    E3.E3_FILIAL ,
			    E3.E3_VEND   ,
			    A3.A3_I_DEDUC,
			    E3.E3_I_ORIGE,
			    E1.e1_vend1, 
                E1.e1_vend2, 
                E1.e1_vend3, 
                E1.e1_vend4, 
                E1.e1_comis1, 
                E1.e1_comis2, 
                E1.e1_comis3, 
                E1.e1_comis4 
			
			UNION ALL
			
			SELECT
			    E3.E3_FILIAL     AS FILIAL  ,
			    E3.E3_VEND       AS CODGER	,
			    A3.A3_I_DEDUC    AS DEDUCAO ,
			    E3.E3_I_ORIGE    AS ORIGEM  ,
                E1.e1_vend1      AS VEND1, 
                E1.e1_vend2      AS VEND2, 
                E1.e1_vend3      AS VEND3, 
                E1.e1_vend4      AS VEND4, 
                E1.e1_comis1     AS COMIS1, 
                E1.e1_comis2     AS COMIS2, 
                E1.e1_comis3     AS COMIS3, 
                E1.e1_comis4     AS COMIS4, 
			    SUM(E3.E3_COMIS) AS COMISSAO,
			    SUM(E3.E3_BASE)  AS VLRRECEB
			FROM %Table:SE3% E3
			
			JOIN %Table:SA3% A3
			ON
			    E3.E3_VEND    = A3.A3_COD

            INNER JOIN %Table:SE1% E1
			ON  E1.E1_FILIAL  = E3.E3_FILIAL
			AND E1.E1_TIPO    = E3.E3_TIPO
			AND E1.E1_PREFIXO = E3.E3_PREFIXO
			AND E1.E1_NUM     = E3.E3_NUM
			AND E1.E1_SERIE   = E3.E3_SERIE
			AND E1.E1_PARCELA = E3.E3_PARCELA
			AND E1.E1_CLIENTE = E3.E3_CODCLI
			AND E1.E1_LOJA    = E3.E3_LOJA
			
			JOIN %Table:SA1% A1
			ON
			    A1.A1_COD     = E3.E3_CODCLI
			AND A1.A1_LOJA    = E3.E3_LOJA
			
			WHERE
			    E3.%NotDel%
			AND A3.%NotDel%
			AND A1.%NotDel%
			%Exp:_cWhere01%
			AND E3.E3_TIPO   = 'NCC'
			AND A3.A3_SUPER  = ' '
			
			AND E3.E3_NUM    NOT IN (  SELECT D1.D1_DOC
			                           FROM %Table:SD1% D1, %Table:SF2% F2
			                           WHERE
			                               D1.D_E_L_E_T_ = ' '
			                           AND F2.D_E_L_E_T_ = ' '
			                           AND E3.E3_FILIAL  = D1.D1_FILIAL
			                           AND E3.E3_NUM     = D1.D1_DOC
			                           AND E3.E3_SERIE   = D1.D1_SERIE
			                           AND E3.E3_CODCLI  = D1.D1_FORNECE
			                           AND E3.E3_LOJA    = D1.D1_LOJA
			                           AND F2.F2_FILIAL  = D1.D1_FILIAL
			                           AND F2.F2_DOC     = D1.D1_NFORI
			                           AND F2.F2_SERIE   = D1.D1_SERIORI
			                           AND F2.F2_CLIENTE = D1.D1_FORNECE
			                           AND F2.F2_LOJA    = D1.D1_LOJA )
			%Exp:_cWhere02%
			GROUP BY E3.E3_FILIAL, 
			           E3.E3_VEND, 
				    A3.A3_I_DEDUC, 
					E3.E3_I_ORIGE, 
					  E1.e1_vend1, 
                      E1.e1_vend2, 
                      E1.e1_vend3, 
                      E1.e1_vend4, 
                      E1.e1_comis1, 
                      E1.e1_comis2, 
                      E1.e1_comis3, 
                      E1.e1_comis4 
			ORDER BY VEND1, FILIAL , CODGER 
			
		EndSql

	EndCase

Return  

/*
===============================================================================================================================
Programa--------: ROMS030RUN
Autor-----------: Fabiano Dias
Data da Criacao-: 31/03/2011
Descrição-------: Função que imprime os dados do relatório
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS030RUN()

Local _aComissao	:= {}     
Local _aGerente		:= {} //Armazena os Gerentes que geraram comissao de acordo com os parametros fornecidos pelo usuario
Local _cFilGer		:= ""
Local _cAliasPg		:= "" 
Local _nPosicao		:= 0
Local _cAliasDup	:= "" 
Local _aDupVenc		:= {} 
Local _aComisPg		:= {}
Local _aDadosCom	:= {}  
Local _cAliasAve    := ""                                          
Local _cAliasVHi    := "" 
Local x
Local _cTituloRep                                          

_cCodRepSA3  := _ccodi    
_cTipoRepSA3 := _cctipvi               

_cTituloRep  := ""
If _cTipoRepSA3 == 'G'  	
   _cTituloRep := "Gerente"  
ElseIf _cTipoRepSA3 == 'C'
   _cTituloRep := "Coordenador"
ElseIf _cTipoRepSA3 == 'S'
   _cTituloRep := "Supervisor"
ElseIf _cTipoRepSA3 == 'V'
   _cTituloRep := "Representante"
EndIf

FWMsgRun( ,{|| _aComissao := ROMS030SEL() } , 'Aguarde!' ,  'Filtrando comissao para '+ _cTituloRep+ '-' +  _cCodRepSA3 + "..." )

//==========================================================================================
// Preenche o array _aComissao com valores zerados, para Gerente, Coordenador e Supervisor
//========================================================================================== 
If Empty(_aComissao) .And. AllTrim(_cTipoRepSA3) $ "G/C/S"   // V=VENDEDOR;C=COORDENADOR;G=GERENTE;S=SUPERVISOR 
   _aComissao := U_ROMS030D(_cCodRepSA3)
   
EndIf
//================================================================================
// Verifica se existe comissao gerada para os vendedores.
//================================================================================
If Len(_aComissao) > 0

	//================================================================================
	// Efetua o grupamento dos Gerentes que possuem comissao gerada, para posterior
	// uso durante toda a impressao da comissao dos Gerentes.
	//================================================================================
    For x:=1 to Len(_aComissao)
    
		_nPosicao:= aScan( _aGerente , {|Y| Y[1] == _aComissao[x,1] } )
		
		If _nPosicao == 0
			aAdd( _aGerente , { _aComissao[x,1] } )
		EndIf
	
	Next x
	                      
	//================================================================================
	// A variavel _cFilGer eh utilizada para agilizar o processo de consulta nas 
	// ROMS030QRY, fazendo somente uma consulta para todos os Gerentes e depois 
	// filtrando o Gerente corrente dentro do alias criado na consulta.
	//================================================================================
	aEval( _aGerente , {|K| _cFilGer += ";" + AllTrim(K[1]) } )
	
	//================================================================================
	// Filtrando o historico de comissoes pagas de todos os Gerentes.
	//================================================================================
	If ! Empty(_cAliasPg)
       If Select(_cAliasPg) > 0  
          (_cAliasPg)->( DBCloseArea() )
       EndIf 
	EndIf 

	_cAliasPg := GetNextAlias()  

	FWMsgRun( , {|| ROMS030QRY(_cAliasPg,3,"","","",_cFilGer) } , 'Aguarde!', 'Filtrando historico de comissoes pagas para ' + _cTituloRep+ '-' +  _cCodRepSA3 + "..."  )
	
	//================================================================================
	// Percorre todos os vendedores para realizar a impressao de seus dados.
	//================================================================================
	For x:=1 To Len( _aGerente )
	
		//================================================================================
		// Para cada Gerente começar em uma nova pagina força a quebra de pagina.
		//================================================================================
		ROMS030QBR()
		
		//================================================================================
		// Imprime o cabecalho de dados das INFORMACOES CADASTRAIS
		//================================================================================
		ROMS030CIC( _aGerente[x,1] )
		
		//======================================================================================================================
		// Chama rotina para selecao de todas as duplicatas vencidas do vendedor corrente
		//======================================================================================================================
		If ! Empty(_cAliasDup)
           If Select(_cAliasDup) > 0  
              (_cAliasDup)->( DBCloseArea() )
           EndIf
		EndIf 

		_cAliasDup := GetNextAlias() 
		
		FWMsgRun( , {||  ROMS030QRY( _cAliasDup , 2 , "", _aGerente[x,1] )  }, 'Aguarde!',"Filtrando duplicatas vencidas para " + _cTituloRep+ '-' +  _cCodRepSA3 + "..."    )
	
		//======================================================================================================================
		// Verifica as duplicatas vencidas do vendedor
		//======================================================================================================================
		_aDupVenc := ROMS030VDP( _cAliasDup )
	
        //======================================================================================================================
		// Chama rotina para selecao de todas as duplicatas a vencer do vendedor corrente
		//======================================================================================================================
		If ! Empty(_cAliasAve)
           If Select(_cAliasAve) > 0  
              (_cAliasAve)->( DBCloseArea() )
           EndIf
        EndIf 

		_cAliasAve := GetNextAlias() 
		
		FWMsgRun( , {||  ROMS030QRY( _cAliasAve , 6 , "" ,  _aGerente[x,1] )  }, 'Aguarde!',"Filtrando duplicatas a vencer para " + _cTituloRep+ '-' +  _cCodRepSA3 + "..."    )
		
		//================================================================================
		// Verifica as comissoes pagas do vendedor corrente.
		//================================================================================
		_aComisPg := ROM030COM( _aGerente[x,1] , _cAliasPg )
		
		
		//=======================================================================================================================
		// Cabecalho de dados HISTORICO FINANCEIRO - DUPLICATAS A VENCER
		//=======================================================================================================================
		ROMS030CB2(_aDupVenc[1,1],_aDupVenc[1,3],_aDupVenc[1,5],_aDupVenc[1,7],_aDupVenc[1,2],_aDupVenc[1,4],_aDupVenc[1,6],_aDupVenc[1,8],_aComisPg[1,1],_aComisPg[2,1],_aComisPg[3,1],_aComisPg[1,2],_aComisPg[2,2],_aComisPg[3,2],_cAliasAve)
		
        //======================================================================================================================
	    // Filtrando o historico de vendas de vendedores.
	    //======================================================================================================================
        If ! Empty(_cAliasVHi)
           If Select(_cAliasVHi) > 0  
              (_cAliasVHi)->( DBCloseArea() )
           EndIf 
		EndIf 

	    _cAliasVHi := GetNextAlias()
	
	    FWMsgRun( , {||  ROMS030QRY( _cAliasVHi , 5 , "" ,  _aGerente[x,1] , _cFilGer, "" )  }, 'Aguarde!', "Filtrando historico de vendas para " + _cTituloRep+ '-' +  _cCodRepSA3 + "..."  )
	    
	    //======================================================================================================================
		// Verifica o historico de vendas do vendedor corrente
		//======================================================================================================================
		_aHistVend := ROMS030HVD(  _aGerente[x,1] , _cAliasVHi )  
	
		//======================================================================================================================
		// Verifica as vendas do vendedor corrente no mes de fechamento indicado agrupando os dados por 
		// sub-grupo de produto
		//======================================================================================================================
		_aVendaHis := {}
        If _cTipoRepSA3 == 'V'
		   _aVendaHis := ROMS030VNM(  _aGerente[x,1])  
		EndIf
				
		//=======================================================================================================================
		// Cabecalho de dados do HISTORICO DE VENDAS com vendas do mês ou dados relacionais conforme tipo vendedor
		//=======================================================================================================================
		ROMS030CB3(_aHistVend[1,1],_aHistVend[2,1],_aHistVend[3,1],_aHistVend[4,1],_aHistVend[1,2],_aHistVend[2,2],_aHistVend[3,2],_aHistVend[4,2],_aVendaHis,2)
		
		//================================================================================
		// Seleciona os dados da COMISSAO A PAGAR do mes de fechamento do Gerente
		//================================================================================
		_aDadosCom := ROMS030CPA( _aGerente[x,1] , _aComissao )
		
		//================================================================================
		// Imprime os dados da COMISSAO A PAGAR do mes de fechamento do vendedor corrente
		//================================================================================
		ROMS030COM( _aDadosCom , 2 , _aGerente[x,1] )
		
		//================================================================================
		// Imprime as assinaturas.
		//================================================================================
		ROMS030ASI()
	  
	Next x
	  	      
EndIf

//================================================================================
// Finaliza as area criadas anteriormente
//================================================================================
If ! Empty(_cAliasPg)
   If Select(_cAliasPg) > 0  
      (_cAliasPg)->( DBCloseArea() )
   EndIf 
EndIf 

If ! Empty(_cAliasDup)
   If Select(_cAliasDup) > 0  
      (_cAliasDup)->( DBCloseArea() )
   EndIf
EndIf 

If ! Empty(_cAliasAve)
   If Select(_cAliasAve) > 0  
      (_cAliasAve)->( DBCloseArea() )
   EndIf
EndIf 

If ! Empty(_cAliasVHi)
   If Select(_cAliasVHi) > 0  
      (_cAliasVHi)->( DBCloseArea() )
   EndIf 
EndIf	

Return

/*
===============================================================================================================================
Programa--------: ROMS030SEL
Autor-----------: Fabiano Dias
Data da Criacao-: 31/03/2011
Descrição-------: Função para apurar deduções de débitos das comissões por Gerente e por Filial
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS030SEL() 

Local _cAlias   := GetNextAlias()  
Local _nNumReg  := 0      
Local _aComissao:= {}
Local _cTituloRep  

    _cTituloRep  := ""
    If _cTipoRepSA3 == 'G'  	
       _cTituloRep := "Gerente"  
    ElseIf _cTipoRepSA3 == 'C'
       _cTituloRep := "Coordenador"
    ElseIf _cTipoRepSA3 == 'S'
       _cTituloRep := "Supervisor"
    ElseIf _cTipoRepSA3 == 'V'
       _cTituloRep := "Representante"
	ElseIf _cTipoRepSA3 == 'N'
       _cTituloRep := "Gerente Nacional"
    EndIf

	//====================================================================================================
	// Chama a rotina para selecao dos registros da comissao dos vendedores
	//====================================================================================================
	FWMsgRun(  , {|| ROMS030QRY( _cAlias , 1 )  }, 'Aguarde!','Filtrando comissao para ' + _cTituloRep + '-' +  _cCodRepSA3 + "..."  )
		
	DBSelectArea( _cAlias )
	(_cAlias)->( DBGoTop() )
	
	COUNT TO _nNumReg
	
	ProcRegua(_nNumReg)      
	
	DBSelectArea(_cAlias)
	(_cAlias)->(DBGoTop()) 
    
	While (_cAlias)->(!Eof())       
                
		_nPosicao := aScan( _aComissao , {|k| k[1] + k[2] + k[6] == (_cAlias)->CODGER + (_cAlias)->FILIAL + (_cAlias)->TIPOVENDA } )

		If _nPosicao == 0
		
			If Upper( AllTrim( (_cAlias)->ORIGEM ) ) == 'SACI008'
				aAdd( _aComissao , { (_cAlias)->CODGER , (_cAlias)->FILIAL , (_cAlias)->DEDUCAO , 0                   , (_cAlias)->VLRRECEB , (_cAlias)->TIPOVENDA , (_cAlias)->COMISSAO } )
			Else             //    {"Codigo"           ,"Filial"           ,"DEDUCAO"            ,"Comissao"           ,"Valor Recebido"    ,"Tipo de Venda"       ,"Comissão"}
				aAdd( _aComissao , { (_cAlias)->CODGER , (_cAlias)->FILIAL , (_cAlias)->DEDUCAO , (_cAlias)->COMISSAO , (_cAlias)->VLRRECEB , (_cAlias)->TIPOVENDA , 0                   } )
			EndIf
			
		Else
		
			//====================================================================================================
			// Efetua o somatorio das comissões e dos debito do Gerente
			//====================================================================================================
			If Upper( AllTrim( (_cAlias)->ORIGEM ) ) == 'SACI008'
				_aComissao[_nPosicao,5] += (_cAlias)->VLRRECEB
				_aComissao[_nPosicao,7] += (_cAlias)->COMISSAO
			Else
				_aComissao[_nPosicao,4] += (_cAlias)->COMISSAO
				_aComissao[_nPosicao,5] += (_cAlias)->VLRRECEB
			EndIf
			
        EndIf

	   (_cAlias)->( DBSkip() )
	EndDo
	               
	DBSelectArea(_cAlias)
	(_cAlias)->( DBCloseArea() )
	
Return( _aComissao )

/*
===============================================================================================================================
Programa--------: ROM030COM
Autor-----------: Fabiano Dias
Data da Criacao-: 31/03/2011
Descrição-------: Funcao que verifica os valores de comissões pagas nos três meses anteriores ao fechamento
Parametros------: _cGerente - Código do Gerente que está sendo apurado
----------------: _cAliasPg - Alias ta tabela temporária com os dados de pagamentos
Retorno---------: _aMesesPg - Array com os dados de pagamentos dos últimos três meses
===============================================================================================================================
*/
Static Function ROM030COM( _cGerente , _cAliasPg )

Local _cMesPar	:= SubStr( MV_PAR01 , 1 , 2 )
Local _cAnoPar	:= SubStr( MV_PAR01 , 3 , 4 )
Local _aMesesPg	:= {}

If MV_PAR09 == 'Analitico' //'1 // 'Analitico'  ,'Previa-Sintetic','Excel', 'Impresso Novo' 
   _cMesPar	:= SubStr( _cMvMesAno , 1 , 2 )
   _cAnoPar	:= SubStr( _cMvMesAno , 3 , 4 )
EndIf 

//====================================================================================================
// Seleciona os ultimos tres meses de acordo com a data de referência parametrizada
//====================================================================================================
aAdd( _aMesesPg , { StrZero( Month( MonthSub( SToD( _cAnoPar + _cMesPar + '01' ) , 3 ) ) , 2 ) , 0 } )
aAdd( _aMesesPg , { StrZero( Month( MonthSub( SToD( _cAnoPar + _cMesPar + '01' ) , 2 ) ) , 2 ) , 0 } )
aAdd( _aMesesPg , { StrZero( Month( MonthSub( SToD( _cAnoPar + _cMesPar + '01' ) , 1 ) ) , 2 ) , 0 } )

DBSelectArea(_cAliasPg)
(_cAliasPg)->( DBGoTop() )
While (_cAliasPg)->( !Eof() )

	//====================================================================================================
	// Verifica se eh o Gerente corrente
	//====================================================================================================
	If _cGerente == (_cAliasPg)->CODGER
	
		_nPosicao := aScan( _aMesesPg , {|K| K[1] == SubStr( (_cAliasPg)->ANOMES , 5 , 2 ) } )
		
		If _nPosicao > 0
		
			_aMesesPg[_nPosicao,2] += (_cAliasPg)->COMISSAO
		
		EndIf
		
	EndIf

(_cAliasPg)->( DBSkip() )
EndDo

Return( _aMesesPg )

/*
===============================================================================================================================
Programa--------: ROMS030CPA
Autor-----------: Fabiano Dias
Data da Criacao-: 31/03/2011
Descrição-------: Funcao que verifica os valores de comissão à pagar para o Gerente atual
Parametros------: _cGerente  - Código do Gerente que está sendo apurado
----------------: _aComissao - dados de comissão à pagar
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS030CPA( _cGerente , _aComissao )
 
Local _aDadCom	:= {}
Local _nI		:= 0

For _nI := 1 to Len( _aComissao )

	If _aComissao[_nI][01] == _cGerente
	
		aAdd( _aDadCom , {	_aComissao[_nI][02] ,;
							_aComissao[_nI][05] ,;
							_aComissao[_nI][04] ,;
							_aComissao[_nI][03] ,;
							_aComissao[_nI][06] ,;
							_aComissao[_nI][07] })
	
	EndIf 
	
Next _nI

_aDadCom := aSort( _aDadCom ,,, { |x,y| x[5] + x[1] < y[5] + y[1] } ) // Ordena os dados do retorno

Return( _aDadCom )

/*
===============================================================================================================================
Programa--------: ROMS030ASI
Autor-----------: Fabiano Dias
Data da Criacao-: 31/03/2011
Descrição-------: Funcao que imprime a área de assinaturas do relatório
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS030ASI()

_nPosLin += ( _nSpcLin * 3 )  //( _nSpcLin * 6 ) 
            

//ROMS030QPG( 0 , .F. , .F. , "" , "" , _TitAssinatura) 

_oPrint:Line( _nPosLin , _nColIni        , _nPosLin , _nColIni + 1080 )
_oPrint:Line( _nPosLin , _nColIni + 1280 , _nPosLin , _nColFim        )

_oPrint:Say( _nPosLin + _nAjsLin , (_nColIni + 1080) / 2            , "CONFERENTE"        , _oFont11b , _nColIni + 1080 ,,, 2 )
//_oPrint:Say( _nPosLin + _nAjsLin , (_nColIni + 1280 + _nColFim) / 2 , "DIRETOR COMERCIAL" , _oFont11b , _nColFim        ,,, 2 )
_oPrint:Say( _nPosLin + _nAjsLin , (_nColIni + 1280 + _nColFim) / 2 , AllTrim(MV_PAR13) , _oFont11b , _nColFim        ,,, 2 )
_nPosLin += _nSpcLin
_oPrint:Say( _nPosLin + _nAjsLin , (_nColIni + 1280 + _nColFim) / 2 , AllTrim(MV_PAR14) , _oFont11b , _nColFim        ,,, 2 )
_nPosLin += _nSpcLin
_oPrint:Say( _nPosLin + _nAjsLin , (_nColIni + 1280 + _nColFim) / 2 , AllTrim(MV_PAR15) , _oFont11b , _nColFim        ,,, 2 )
_nPosLin += _nSpcLin
_oPrint:Say( _nPosLin + _nAjsLin , (_nColIni + 1280 + _nColFim) / 2 , AllTrim(MV_PAR16)  , _oFont11b , _nColFim        ,,, 2 )
_nPosLin += _nSpcLin

Return

/*
===============================================================================================================================
Programa--------: ROMS030CAD
Autor-----------: Alexandre Villar
Data da Criacao-: 2014
Descrição-------: Funcao que retorna os dados de cálculos adicionais de comissão
Parametros------: _cCodGer - Código do Gerente que está sendo apurado
Retorno---------: _aRet    - Array com os dados adicionais
===============================================================================================================================
*/
Static Function ROMS030CAD( _cCodGer )

Local _cDtRef		:= SubStr( MV_PAR01 , 3 , 4 ) + SubStr( MV_PAR01 , 1 , 2 )
Local _aRet			:= { 0 , 0 , 0 , 0 }
Local _nI , _cDtInic, _cDtFim
Local _dDtInic, _dDtFim, _nNrMeses
Local _nMes , _nAno
Default _cCodGer	:= ''

_cDtInic := "01/" + SubStr( MV_PAR01 , 1 , 2 ) + "/"+ SubStr( MV_PAR01 , 3 , 4 )
_cDtFim  := "01/" + SubStr( MV_PAR02 , 1 , 2 ) + "/"+ SubStr( MV_PAR02 , 3 , 4 )

If MV_PAR09 == 'Analitico' // 1 // 'Analitico'  ,'Previa-Sintetic','Excel', 'Impresso Novo' 
   _cDtRef	:= SubStr( _cMvMesAno , 3 , 4 ) + SubStr( _cMvMesAno , 1 , 2 )
   _cDtInic := "01/" + SubStr( _cMvMesAno , 1 , 2 ) + "/"+ SubStr( _cMvMesAno , 3 , 4 )
   _cDtFim  := "01/" + SubStr( _cMvMesAno , 1 , 2 ) + "/"+ SubStr( _cMvMesAno , 3 , 4 )
EndIf 

_dDtInic := Ctod(_cDtInic)
_dDtFim  := Ctod(_cDtFim)

_nNrMeses := DateDiffMonth(_dDtInic, _dDtFim)

DBSelectArea('ZC1')
ZC1->( DBSetOrder(1) )

_aRet[01] := 0
_aRet[02] := 0
_aRet[03] := 0
_aRet[04] := 0

If (AllTrim(MV_PAR01) == AllTrim(MV_PAR02)) .Or. (MV_PAR09 == 1) // (MV_PAR09 == 'Analitico')  // 'Analitico'  ,'Previa-Sintetic','Excel', 'Impresso Novo' 
   If ZC1->( DBSeek( xFilial('ZC1') + _cCodGer + _cDtRef ) )
      _aRet[01] := ZC1->ZC1_VALLMG
	  _aRet[02] := ZC1->ZC1_PERLMG
	  _aRet[03] := Round( ( ZC1->ZC1_VALCAD / ZC1->ZC1_VALLMG ) * 100 , 2 )
	  _aRet[04] := ZC1->ZC1_VALCAD
   EndIf
Else 
   _nMes := Val(SubStr( MV_PAR01 , 1 ,2)) 
   _nAno := Val(SubStr( MV_PAR01 , 3 ,4))

   For _nI := 1 To _nNrMeses
       _cDtRef := StrZero(_nAno, 4) + StrZero(_nMes,2)
       
	   If ZC1->( DBSeek( xFilial('ZC1') + _cCodGer + _cDtRef ) )
          _aRet[01] += ZC1->ZC1_VALLMG
	      _aRet[02] += ZC1->ZC1_PERLMG
	      _aRet[03] += Round( ( ZC1->ZC1_VALCAD / ZC1->ZC1_VALLMG ) * 100 , 2 )
	      _aRet[04] += ZC1->ZC1_VALCAD
       EndIf

       _nMes += 1
	   If _nMes > 12
          _nMes := 1
		  _nAno += 1 
       EndIf 
   Next 
EndIf 

Return( _aRet )

/*
===============================================================================================================================
Programa--------: ROMS030BNF
Autor-----------: Alexandre Villar
Data da Criacao-: 2014
Descrição-------: Funcao que retorna os dados de cálculos de bonificações
Parametros------: _cCodGer - Código do Gerente que está sendo apurado
Retorno---------: _aRet    - Array com dados das bonificações
===============================================================================================================================
*/
Static Function ROMS030BNF( _cCodGer )

Local _cAlias		:= GetNextAlias() 
Local _cQuery		:= ""
Local _aRet			:= {}
Local _cfiltrobon   := ""
Default _cCodGer	:= ''

Begin Sequence
   If MV_PAR09 == 'Analitico' // 1  // 'Analitico'  ,'Previa-Sintetic','Excel', 'Impresso Novo' 
      _cFiltrobon	+= " AND SubStr( F2_EMISSAO , 1 , 6 ) = '"+ SubStr( _cMvMesAno , 3 , 4 ) + SubStr( _cMvMesAno , 1 , 2 ) +"'" 
   Else 
      If AllTrim(MV_PAR01) == AllTrim(MV_PAR02)
         _cFiltrobon	+= " AND SubStr( F2_EMISSAO , 1 , 6 ) = '"+ SubStr( MV_PAR01 , 3 , 4 ) + SubStr( MV_PAR01 , 1 , 2 ) +"'" 
      Else 
	     _cFiltrobon	+= " AND SubStr( F2_EMISSAO , 1 , 6 ) >= '" + SubStr(MV_PAR01,3,4) + SubStr(MV_PAR01,1,2) + "' AND SubStr( F2_EMISSAO , 1 , 6 ) <= '"+ SubStr(MV_PAR02,3,4) + SubStr(MV_PAR02,1,2) + "' " 
      EndIf
   EndIf  

   SA3->(DBSetOrder(1))
   If !(SA3->(DBSeek(xFilial("SA3")+_cCodGer)))
	  _aRet := {"N/C",0,0,0}
  	  Break 
   EndIf	

   _cQuery := " SELECT "
   _cQuery += "    SF2.F2_FILIAL       AS F2_FILIAL   		, "
   _cQuery += "    SF2.F2_DOC          AS F2_DOC 		  	, "
   _cQuery += "    SF2.F2_SERIE        AS F2_SERIE   		, "
   _cQuery += "    SF2.F2_EMISSAO      AS F2_EMISSAO  		, "
   _cQuery += "    SF2.F2_CLIENTE      AS F2_CLIENTE   	, "
   _cQuery += "    SF2.F2_LOJA         AS F2_LOJA   		, "
   _cQuery += "    SF2.F2_VEND1        AS F2_VEND1   		, "
   _cQuery += "    SF2.F2_VEND2        AS F2_VEND2   		, "
   _cQuery += "    SF2.F2_VEND3        AS F2_VEND3   		, "
   _cQuery += "    SF2.F2_VEND4        AS F2_VEND4   		, "
   _cQuery += "    SF2.F2_VEND5        AS F2_VEND5   		, "
   _cQuery += "    SUM(SD2.D2_VALBRUT-SD2.D2_VALDEV) AS VALTOT           , "

   //====================================================================================================
   // Gerente Nacional
   //====================================================================================================
   If SA3->A3_I_TIPV == "N"
      _cFiltroBON	+= " AND F2_VEND5 = '" + _cCodGer + "'"
	  _cQuery += "    SUM(SD2.D2_COMIS5*(SD2.D2_VALBRUT-SD2.D2_VALDEV))  AS COMIS           "
   EndIf

   //====================================================================================================
   // Gerente
   //====================================================================================================
   If SA3->A3_I_TIPV == "G"
      _cFiltroBON	+= " AND F2_VEND3 = '" + _cCodGer + "'"
	  _cQuery += "    SUM(SD2.D2_COMIS3*(SD2.D2_VALBRUT-SD2.D2_VALDEV))  AS COMIS           "
   EndIf
	
   //====================================================================================================
   // Coordenador
   //====================================================================================================
   If SA3->A3_I_TIPV == "C"
	  _cFiltroBON	+= " AND F2_VEND2 = '" + _cCodGer + "'"
	  _cQuery += "    SUM(SD2.D2_COMIS2*(SD2.D2_VALBRUT-SD2.D2_VALDEV))  AS COMIS            "
   EndIf
	
   //====================================================================================================
   // Supervisor
   //====================================================================================================
   If SA3->A3_I_TIPV == "S"
	  _cFiltroBON	+= " AND F2_VEND4 = '" + _cCodGer + "'"
	  _cQuery += "    SUM(SD2.D2_COMIS4*(SD2.D2_VALBRUT-SD2.D2_VALDEV))  AS COMIS            "
   EndIf

   //====================================================================================================
   // Representante
   //====================================================================================================
   If SA3->A3_I_TIPV == "V"
	  _cFiltroBON	+= " AND F2_VEND1 = '" + _cCodGer + "'"
	  _cQuery += "    SUM(SD2.D2_COMIS1*(SD2.D2_VALBRUT-SD2.D2_VALDEV))  AS COMIS            "
   EndIf

   _cQuery += " FROM "+ RetSqlName('SF2') +" SF2 "
   _cQuery += " JOIN "+ RetSqlName('SD2') +" SD2 ON SD2.D2_DOC		= SF2.F2_DOC	AND SD2.D2_SERIE	= SF2.F2_SERIE AND SD2.D2_FILIAL = SF2.F2_FILIAL "
   _cQuery += " JOIN "+ RetSqlName('SB1') +" SB1 ON SD2.D2_COD		= SB1.B1_COD AND SB1.B1_FILIAL = '  '"
   _cQuery += " JOIN "+ RetSqlName('SF4') +" SF4 ON SD2.D2_FILIAL	= SF4.F4_FILIAL	AND SD2.D2_TES		= SF4.F4_CODIGO "
   _cQuery += " JOIN "+ RetSqlName('ZAY') +" ZAY ON ZAY.ZAY_CF     = SD2.D2_CF "
   _cQuery += " WHERE "
   _cQuery += "     SF2.D_E_L_E_T_ = ' ' "
   _cQuery += " AND SD2.D_E_L_E_T_ = ' ' "
   _cQuery += " AND SB1.D_E_L_E_T_ = ' ' "
   _cQuery += " AND SF4.D_E_L_E_T_ = ' ' "
   _cQuery += " AND ZAY.D_E_L_E_T_ = ' ' "
   _cQuery += " AND SB1.B1_TIPO    = 'PA' "
   _cQuery += " AND ZAY.ZAY_TPOPER	= 'B' "
   _cQuery +=   _cfiltrobon
   _cQuery += " GROUP BY SF2.F2_FILIAL, SF2.F2_DOC, SF2.F2_SERIE,SF2.F2_EMISSAO, SF2.F2_CLIENTE,SF2.F2_LOJA,SF2.F2_VEND1, SF2.F2_VEND2, SF2.F2_VEND3, SF2.F2_VEND4, SF2.F2_VEND5 "
   _cQuery += " ORDER BY SF2.F2_FILIAL,SF2.F2_DOC,SF2.F2_SERIE "

   MPSysOpenQuery( _cQuery , _cAlias)

   DBSelectArea(_cAlias)
   (_cAlias)->( DBGoTop() )

   While (_cAlias)->(!Eof())
	  aAdd( _aRet , {	"N/C"	,;
					(_cAlias)->VALTOT												,;
					( (_cAlias)->COMIS * -1 )/100										,;
					Round( ( ((_cAlias)->COMIS/100) / (_cAlias)->VALTOT ) * 100 , 2 )	})

      (_cAlias)->( DBSkip() )
   EndDo

End Sequence 

If Select(_cAlias) > 0 
   (_cAlias)->( DBCloseArea() )
EndIf

Return( _aRet )

/*
===============================================================================================================================
Programa----------: ROMS030VNM
Autor-------------: Fabiano Dias
Data da Criacao---: 01/04/2011
Descrição---------: Funcao que verifica as vendas do vendedor no mes do fechamento indicado pelo usuário
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS030VNM( _cCoorden )

Local _aDadoVend	:= {}
Local _cAliasMes	:= GetNextAlias()                                                       
Local _cTituloRep 

_cTituloRep  := ""
If _cTipoRepSA3 == 'G'  	
   _cTituloRep := "Gerente"  
ElseIf _cTipoRepSA3 == 'C'
   _cTituloRep := "Coordenador"
ElseIf _cTipoRepSA3 == 'S'
   _cTituloRep := "Supervisor"
ElseIf _cTipoRepSA3 == 'V'
   _cTituloRep := "Representante"
ElseIf _cTipoRepSA3 == 'N'
   _cTituloRep := "Gerente Nacional"
EndIf

FWMsgRun( , {||  ROMS030QRY( _cAliasMes , 7 , "" , _cCoorden , "" , "" )  } , 'Aguarde!' ,"Filtrando historico vendas mes corrente: " + _cTituloRep + '-' +  _cCodRepSA3 + "..."  ) 
DBSelectArea( _cAliasMes )
(_cAliasMes)->( DBGoTop() )
While (_cAliasMes)->( !Eof() )

	aAdd(_aDadoVend , {	(_cAliasMes)->DESCSUB ,; // Descricao do sub-Grupo de Produtos
						(_cAliasMes)->QTD1    ,; // Quantidade na primeira unidade de medida
						(_cAliasMes)->UM1     ,; // 1 Unidade de Medida
						(_cAliasMes)->QTD2    ,; // Quantidade na segunda unidade de medida
						(_cAliasMes)->UM2     ,; // 2 Unidade de Medida
						(_cAliasMes)->VLBRUT  ,; // Valor Bruto
						(_cAliasMes)->MEDIA   }) // Media da % paga ao vendedor

(_cAliasMes)->( DBSkip() )
EndDo

(_cAliasMes)->( DBCloseArea() )

Return( _aDadoVend )

/*
===============================================================================================================================
Programa----------: ROMS030HVD
Autor-------------: Julio de Paula Paz
Data da Criacao---: 25/04/2018
Descrição---------: Funcao que verifica o histórico de vendas do vendedor nos últimos 4 meses incluindo o do fechamento
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS030HVD( _cCoorder , _cAliasVHi )

Local _nMesAtual	:= Val( SubStr( MV_PAR01 , 1 , 2 ) )
Local _nAnoAtual	:= Val( SubStr( MV_PAR01 , 3 , 4 ) )

Local _a3MesesVe	:= {}
Local _aHistVend	:= {}

Local _nPosicao := 0
Local _cCodVend := ""

If MV_PAR09 == 'Analitico' // 1  // 'Analitico'  ,'Previa-Sintetic','Excel', 'Impresso Novo' 
   _nMesAtual	:= Val( SubStr( _cMvMesAno , 1 , 2 ) )
   _nAnoAtual	:= Val( SubStr( _cMvMesAno , 3 , 4 ) )
EndIf 

//====================================================================================================
// Seleciona os ultimos tres meses de acordo com a data fornecida para o fechamento da comissao.
//====================================================================================================
_a3MesesVe := ROMS030S3M( _nMesAtual , _nAnoAtual , 1 )

aAdd( _aHistVend , { _a3MesesVe[2]		   , 0 } )
aAdd( _aHistVend , { _a3MesesVe[3]		   , 0 } )
aAdd( _aHistVend , { _a3MesesVe[4]		   , 0 } )
aAdd( _aHistVend , { StrZero(_nMesAtual,2) , 0 } )

DBSelectArea(_cAliasVHi)
(_cAliasVHi)->( DBGoTop() )
While (_cAliasVHi)->( !Eof() )
   _cCodVend := ""
   If _cTipoRepSA3 == 'G' 
      _cCodVend := (_cAliasVHi)->F2_VEND3 
   ElseIf _cTipoRepSA3 == 'C'
      _cCodVend := (_cAliasVHi)->F2_VEND2 
   ElseIf _cTipoRepSA3 == 'S'
      _cCodVend := (_cAliasVHi)->F2_VEND4 
   ElseIf _cTipoRepSA3 == 'V'
      _cCodVend := (_cAliasVHi)->F2_VEND1
   ElseIf _cTipoRepSA3 == 'N' 
      _cCodVend := (_cAliasVHi)->F2_VEND5
   EndIf
   
   If AllTrim(_cCoorder) == _cCodVend 
	
		_nPosicao := aScan( _aHistVend , {|K| K[1] == SubStr( (_cAliasVHi)->ANOMES , 5 , 2 ) } )
		
		If _nPosicao > 0
			_aHistVend[_nPosicao][2] += (_cAliasVHi)->VLRBRUT
		EndIf
	
	EndIf

(_cAliasVHi)->( DBSkip() )
EndDo

Return( _aHistVend )

/*
===============================================================================================================================
Programa----------: ROMS030CB3
Autor-------------: Julio de Paula Paz
Data da Criacao---: 25/04/2018
Descrição---------: Função para imprimir o quadro do histórico de vendas
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS030CB3( _cMes1 , _cMes2 , _cMes3 , _cMes4 , _nVlrFat1 , _nVlrFat2 , _nVlrFat3 , _nVlrFat4 , _aVendas , cTipo )
Local nLinInBox2
Local _nTotVlrBr	:= 0 
Local _cDescric		:= _cTitCargo
Local _aMes			:= {"Janeiro","Fevereiro","Março","Abril","Maio","Junho","Julho","Agosto","Setembro","Outubro","Novembro","Dezembro"}
Local _nI, _nValRec, _nValCom, _nPerc, _cNome
Local _aDadosRepres
Local _cPeriodo 

nLinInBox2	:= _nPosLin
nLinInBox	:= _nPosLin

_nPosLin += _nSpcLin 

_oPrint:Say( _nPosLin				, _nColFim / 2		, 'Histórico de Vendas'				, _oFont16b , _nColFim ,,, 2 )

_nPosLin += _nSpcLin
_nPosLin += _nSpcLin  

_oPrint:Say( _nPosLin + _nSpcLin	, _nColIni + 10		, "Mês"								, _oFont11b )
_oPrint:Say( _nPosLin + _nSpcLin	, 0920				, PadL(_aMes[Val(_cMes1)],10," ")	, _oFont11b , 0970      ,,, 2 )
_oPrint:Say( _nPosLin + _nSpcLin	, 1310				, PadL(_aMes[Val(_cMes2)],10," ")	, _oFont11b , 1360      ,,, 2 )
_oPrint:Say( _nPosLin + _nSpcLin	, 1700				, PadL(_aMes[Val(_cMes3)],10," ")	, _oFont11b , 1710      ,,, 2 )
_oPrint:Say( _nPosLin + _nSpcLin	, 2050				, PadL(_aMes[Val(_cMes4)],10," ")	, _oFont11b , _nColFim ,,, 2 )

_nPosLin += _nSpcLin

_oPrint:Say( _nPosLin + _nSpcLin	, _nColIni + 0010  	, "Valor Faturado"								, _oFont11b )
_oPrint:Say( _nPosLin + _nSpcLin	, _nColIni + 0580 	, Transform(_nVlrFat1,"@E 999,999,999,999.99")	, _oFont11  )
_oPrint:Say( _nPosLin + _nSpcLin	, _nColIni + 0970	, Transform(_nVlrFat2,"@E 999,999,999,999.99")	, _oFont11  )
_oPrint:Say( _nPosLin + _nSpcLin	, _nColIni + 1360	, Transform(_nVlrFat3,"@E 999,999,999,999.99")	, _oFont11  )
_oPrint:Say( _nPosLin + _nSpcLin	, _nColIni + 1710	, Transform(_nVlrFat4,"@E 999,999,999,999.99")	, _oFont11  )

_nPosLin += _nSpcLin
_nPosLin += _nSpcLin

_oPrint:Box( nLinInBox , _nColIni , _nPosLin , _nColFim )

//=============================================================================================
// Incluir aqui o detalhamento de vendas do mes do representante.  
//=============================================================================================
If _cTipoRepSA3 == 'V'
   _nPosLin += _nSpcLin
   _nPosLin += _nSpcLin

   If MV_PAR09 == 'Analitico' // 1 // 'Analitico'  ,'Previa-Sintetic','Excel', 'Impresso Novo'
      _oPrint:Say( _nPosLin	, _nColFim / 2	, 'VENDAS DO MÊS - '+ IIF( !Empty(_cMvMesAno) , _aMes[Val(SubStr(_cMvMesAno,1,2))] +'/'+ SubStr(_cMvMesAno,3,4),"") , _oFont16b , _nColFim  ,,, 2 )
   Else 
      If MV_PAR01 == MV_PAR02
         _oPrint:Say( _nPosLin	, _nColFim / 2	, 'VENDAS DO MÊS - '+ IIF( !Empty(MV_PAR01) , _aMes[Val(SubStr(MV_PAR01,1,2))] +'/'+ SubStr(MV_PAR01,3,4),"") , _oFont16b , _nColFim  ,,, 2 )
	  Else 
         _cPeriodo := 'VENDAS DO MÊS - '+ IIF( !Empty(MV_PAR01) , _aMes[Val(SubStr(MV_PAR01,1,2))] +'/'+ SubStr(MV_PAR01,3,4),"") + " Até "
		 _cPeriodo += IIf( !Empty(MV_PAR02) , _aMes[Val(SubStr(MV_PAR02,1,2))] +'/'+ SubStr(MV_PAR02,3,4),"")
         _oPrint:Say( _nPosLin	, _nColFim / 2	, _cPeriodo , _oFont16b , _nColFim  ,,, 2 )
	  EndIf 
   EndIf 

   _nPosLin += _nSpcLin
   _nPosLin += _nSpcLin

   _oPrint:Say( _nPosLin + _nSpcLin	, _nColIni + 0010	, "Grupo de Produtos"	, _oFont11b )
   _oPrint:Say( _nPosLin + _nSpcLin	, _nColIni + 0680	, "%"					, _oFont11b )
   _oPrint:Say( _nPosLin + _nSpcLin	, _nColIni + 0810	, "1a.Qtde"				, _oFont11b )
   _oPrint:Say( _nPosLin + _nSpcLin	, _nColIni + 0990	, "1a.U.M"				, _oFont11b )
   _oPrint:Say( _nPosLin + _nSpcLin	, _nColIni + 1240	, "2a. Qtde"			, _oFont11b )
   _oPrint:Say( _nPosLin + _nSpcLin	, _nColIni + 1430	, "2a.U.M"				, _oFont11b )
   _oPrint:Say( _nPosLin + _nSpcLin	, _nColIni + 1620	, "Vlr.Medio"			, _oFont11b )
   _oPrint:Say( _nPosLin + _nSpcLin	, _nColIni + 1920	, "Vlr.Total"			, _oFont11b )

   For _nI := 1 To Len(_aVendas)
	   _nPosLin += _nSpcLin
	   
	    If (_nPosLin + _nSpcLin) > _nLimPag 
           
           _nPosLin += _nSpcLin
           
           ROMS030QPG( 0 , .T. , .F. , "ROMS0304()" , "" , _cDescric )
          
           _nLinBox := _nPosLin
           
           _nPosLin += _nSpcLin
           
           _oPrint:Say( _nPosLin + _nSpcLin	, _nColIni + 0010	, "Grupo de Produtos"	, _oFont11b )
           _oPrint:Say( _nPosLin + _nSpcLin	, _nColIni + 0680	, "%"					, _oFont11b )
           _oPrint:Say( _nPosLin + _nSpcLin	, _nColIni + 0810	, "1a.Qtde"				, _oFont11b )
           _oPrint:Say( _nPosLin + _nSpcLin	, _nColIni + 0990	, "1a.U.M"				, _oFont11b )
           _oPrint:Say( _nPosLin + _nSpcLin	, _nColIni + 1240	, "2a. Qtde"			, _oFont11b )
           _oPrint:Say( _nPosLin + _nSpcLin	, _nColIni + 1430	, "2a.U.M"				, _oFont11b )
           _oPrint:Say( _nPosLin + _nSpcLin	, _nColIni + 1620	, "Vlr.Medio"			, _oFont11b )
           _oPrint:Say( _nPosLin + _nSpcLin	, _nColIni + 1920	, "Vlr.Total"			, _oFont11b )
           
           _nPosLin += _nSpcLin

        EndIf
	
	   _oPrint:Say( _nPosLin + _nSpcLin , _nColIni + 0010 , SubStr(IIf(Len(AllTrim(_aVendas[_nI,1])) == 0,'SEM GRUPO DE PRODUTOS',_aVendas[_nI,1]),1,29)									   , _oFont11 )
	   _oPrint:Say( _nPosLin + _nSpcLin , _nColIni + 0600 , Transform(_aVendas[_nI,7],"@E 999.999") 							  			  													   , _oFont11 )
	   _oPrint:Say( _nPosLin + _nSpcLin , _nColIni + 0600 , Transform(_aVendas[_nI,2],"@E 999,999,999,999.99")				  			  													   , _oFont11 )
	   _oPrint:Say( _nPosLin + _nSpcLin , _nColIni + 0990 , _aVendas[_nI,3]													  			  													   , _oFont11 )
	   _oPrint:Say( _nPosLin + _nSpcLin , _nColIni + 1040 , Transform(_aVendas[_nI,4],"@E 999,999,999,999.99")				              													   , _oFont11 )
	   _oPrint:Say( _nPosLin + _nSpcLin , _nColIni + 1430 , _aVendas[_nI,5]       											  			  													   , _oFont11 )
	   _oPrint:Say( _nPosLin + _nSpcLin , _nColIni + 1450 , IIf(_aVendas[_nI,2] > 0,Transform(_aVendas[_nI,6] / _aVendas[_nI,2],"@E 999,999,999,999.99"),TransForm(0,"@E 999,999,999,999.99")) , _oFont11 )
	   _oPrint:Say( _nPosLin + _nSpcLin , _nColIni + 1750 , Transform(_aVendas[_nI,6],"@E 999,999,999,999.99")			      			  													   , _oFont11 )
    
	   _nTotVlrBr += _aVendas[_nI,6]

   Next _nI

   //====================================================================================================
   // Imprime o totalizador valor total das vendas do Mes.
   //====================================================================================================
   _nPosLin += _nSpcLin
   _nPosLin += _nSpcLin
     
   _oPrint:Box( _nLinBox , _nColIni , _nPosLin , _nColFim )
      
   _nLinBox := _nPosLin
   
   _oPrint:Say( _nPosLin , _nColIni + 0010 , "TOTAL"									    , _oFont11b)
   _oPrint:Say( _nPosLin , _nColIni + 1750 , Transform(_nTotVlrBr,"@E 999,999,999,999.99")	, _oFont11b )

   _nPosLin += _nSpcLin

   _oPrint:Box( _nLinBox , _nColIni , _nPosLin , _nColFim )

Else //Se não é vendedor imprime quadro relacional

	//================================================================================
	//Monta dados relacionais
	//================================================================================
	
	_nPosLin += _nSpcLin
	
	nLinInBox := _nPosLin
	
   _nPosLin += _nSpcLin

   If MV_PAR09 == 'Analitico' //1 // 'Analitico'  ,'Previa-Sintetic','Excel', 'Impresso Novo'
	  _oPrint:Say( _nPosLin	, _nColFim / 2	, 'Relação de ' + _cTitCargo + ' - '+ IIF( !Empty(_cMvMesAno) , _aMes[Val(SubStr(_cMvMesAno,1,2))] +'/'+ SubStr(_cMvMesAno,3,4),"") , _oFont16b , _nColFim  ,,, 2 )
   Else    
      If MV_PAR01 == MV_PAR02
         _oPrint:Say( _nPosLin	, _nColFim / 2	, 'Relação de ' + _cTitCargo + ' - '+ IIF( !Empty(MV_PAR01) , _aMes[Val(SubStr(MV_PAR01,1,2))] +'/'+ SubStr(MV_PAR01,3,4),"") , _oFont16b , _nColFim  ,,, 2 )
	  Else 
         _cPeriodo := 'Relação de ' + _cTitCargo + ' - '+ IIF( !Empty(MV_PAR01) , _aMes[Val(SubStr(MV_PAR01,1,2))] +'/'+ SubStr(MV_PAR01,3,4),"") 
		 _cPeriodo += " Ate " + IIf( !Empty(MV_PAR02) , _aMes[Val(SubStr(MV_PAR02,1,2))] +'/'+ SubStr(MV_PAR02,3,4),"") 
         _oPrint:Say( _nPosLin	, _nColFim / 2	, _cPeriodo , _oFont16b , _nColFim  ,,, 2 )
	  EndIf 
   EndIf 

   _nPosLin += _nSpcLin
   _nPosLin += _nSpcLin

   _oPrint:Say( _nPosLin + _nSpcLin	, _nColIni + 0010	, "Representante"		, _oFont11b )
   _oPrint:Say( _nPosLin + _nSpcLin	, _nColIni + 1110	, "Valor Recebido"		, _oFont11b )
   _oPrint:Say( _nPosLin + _nSpcLin	, _nColIni + 1540	, "Valor Comissão"		, _oFont11b )
   _oPrint:Say( _nPosLin + _nSpcLin	, _nColIni + 1920	, "% Com."			, _oFont11b )
 
   _ntotv := 0
   _ntotc := 0
 
    _aComGerenc := {}

    _aDadosRepres := {0,0,0}

	FWMsgRun( , {||  _aDadosRepres := U_ROMS030J(_ccodi, _cctipvi /*, _aDadosRelac[_nI,1], _aDadosRelac[_nI,2] */)  }, 'Aguarde...', 'Lendo dados rede representante vinculados ao ' + _cTitCargo +  "..."  ) 	   
    If Len(_aDadosRepres) > 0
	  
	   For _nI := 1 To Len(_aDadosRepres)
           _nValCom := _aDadosRepres[_nI,2] 
		   _nValRec := _aDadosRepres[_nI,3] 
	       _nPerc   :=  ( _nValCom / _nValRec ) * 100
	       
		   If _nValRec <> 0 .Or. _nValCom <> 0 
		      If Empty(_aDadosRepres[_nI,1])
                 _cNome := " " 
				 If  _nValCom < 0 .And. _nValRec > 0
				     Loop 
                 EndIf
			  Else
		         _cNome := Posicione("SA3",1,xFilial("SA3")+_aDadosRepres[_nI,1],"A3_NOME")
			  EndIf
		   
		      aAdd(_aComGerenc,{_aDadosRepres[_nI,1], _cNome, _nValRec, _nValCom, _nPerc})
		   EndIf
       Next

	EndIf

    For _nI := 1 To Len(_aComGerenc)  
 		_nPosLin += _nSpcLin
	   
	    If (_nPosLin + _nSpcLin) > _nLimPag 
           
           _nPosLin += _nSpcLin
           
           ROMS030QPG( 0 , .T. , .F. , "ROMS0304()" , "" , _cDescric )
          
           _nLinBox := _nPosLin
           
           _nPosLin += _nSpcLin
           
           _oPrint:Say( _nPosLin + _nSpcLin	, _nColIni + 0010	, "Representante"		, _oFont11b )
           _oPrint:Say( _nPosLin + _nSpcLin	, _nColIni + 1110	, "Valor Recebido"		, _oFont11b )
           _oPrint:Say( _nPosLin + _nSpcLin	, _nColIni + 1540	, "Valor Comissão"		, _oFont11b )
           _oPrint:Say( _nPosLin + _nSpcLin	, _nColIni + 1920	, "% Comissão"			, _oFont11b )
           
           _nPosLin += _nSpcLin

        EndIf

       _oPrint:Say( _nPosLin + _nSpcLin , _nColIni + 0010 , _aComGerenc[_nI,1] + " - " + _aComGerenc[_nI,2]	     , _oFont11 )
	   _oPrint:Say( _nPosLin + _nSpcLin , _nColIni + 1050 , Transform(_aComGerenc[_nI,3],"@E 999,999,999.99")  , _oFont11 )
	   _oPrint:Say( _nPosLin + _nSpcLin , _nColIni + 1440 , Transform(_aComGerenc[_nI,4] ,"@E 999,999,999.99") , _oFont11 )
	   _oPrint:Say( _nPosLin + _nSpcLin , _nColIni + 1900 , Transform(_aComGerenc[_nI,5],"@E 999.999") , _oFont11 ) 
    Next   				

	_nPosLin += _nSpcLin
	_nPosLin += _nSpcLin
	
	/*
	_oPrint:Say( _nPosLin + _nSpcLin , _nColIni + 0010 , "Totais"		   , _oFont11b )
	_oPrint:Say( _nPosLin + _nSpcLin , _nColIni + 1050 , Transform(_ntotv,"@E 999,999,999.99") , _oFont11b )
	_oPrint:Say( _nPosLin + _nSpcLin , _nColIni + 1440 , Transform(_ntotc,"@E 999,999,999.99") , _oFont11b )
	_oPrint:Say( _nPosLin + _nSpcLin , _nColIni + 1900 , Transform((_ntotc/_ntotv)*100,"@E 999.99") , _oFont11b )
	
 
	 _nPosLin += _nSpcLin
	 _nPosLin += _nSpcLin
	 
	 */
	 
	 _oPrint:Box( nLinInBox , _nColIni , _nPosLin , _nColFim )
 
EndIf

Return

/*
===============================================================================================================================
Programa----------: ROMS030CB2
Autor-------------: Fabiano Dias
Data da Criacao---: 31/03/2011
Descrição---------: Função para imprimir o cabeçalho do histórico financeiro
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS030CB2( _nqtdeDup1 , _nqtdeDup2 , _nqtdeDup3 , _nqtdeDup4 , _nVlrVenc1 , _nVlrVenc2 , _nVlrVenc3 , _nVlrVenc4 , _cMes1 , _cMes2 , _cMes3 , _nVlrComi1 , _nVlrComi2 , _nVlrComi3 , _cAliasAve )

Local nLinInBox2
Local nLinBoxAux
Local _aMesesDup
Local _aMes			:= {"Janeiro","Fevereiro","Março","Abril","Maio","Junho","Julho","Agosto","Setembro","Outubro","Novembro","Dezembro"}

nLinInBox := _nPosLin

_oPrint:Say( _nPosLin , _nColFim / 2 , 'Histórico Financeiro - Duplicatas Vencidas' , _oFont16b , _nColFim ,,, 2 )

_nPosLin += _nSpcLin
_nPosLin += _nSpcLin	 

nLinBoxAux := _nPosLin

_oPrint:Say( _nPosLin  , _nColIni + 0010 , "Período"          , _oFont11b )
_oPrint:Say( _nPosLin  , _nColIni + 0760 , "Até 15 dias"      , _oFont11b )
_oPrint:Say( _nPosLin  , _nColIni + 1070 , "De 16 a 30 dias"  , _oFont11b )
_oPrint:Say( _nPosLin  , _nColIni + 1460 , "De 31 a 60 dias"  , _oFont11b )
_oPrint:Say( _nPosLin  , _nColIni + 1800 , "Acima de 60 dias" , _oFont11b )

_nPosLin += _nSpcLin

_oPrint:Say( _nPosLin  , _nColIni + 0010 , "Quantidade de duplicatas"					, _oFont11b )
_oPrint:Say( _nPosLin  , _nColIni + 0780 , Transform(_nqtdeDup1,"@E 999999999")		, _oFont11b  )
_oPrint:Say( _nPosLin  , _nColIni + 1170 , Transform(_nqtdeDup2,"@E 999999999")		, _oFont11b  )
_oPrint:Say( _nPosLin  , _nColIni + 1550 , Transform(_nqtdeDup3,"@E 999999999")		, _oFont11b  )
_oPrint:Say( _nPosLin  , _nColIni + 1910 , Transform(_nqtdeDup4,"@E 999999999")		, _oFont11b  )

_nPosLin += _nSpcLin

_oPrint:Say( _nPosLin  , _nColIni + 0010 , "Valores vencidos"							, _oFont11b )
_oPrint:Say( _nPosLin  , _nColIni + 0700 , Transform(_nVlrVenc1,"@E 999,999,999.99")	, _oFont11b  )
_oPrint:Say( _nPosLin  , _nColIni + 1100 , Transform(_nVlrVenc2,"@E 999,999,999.99")	, _oFont11b  )
_oPrint:Say( _nPosLin  , _nColIni + 1480 , Transform(_nVlrVenc3,"@E 999,999,999.99")	, _oFont11b  )
_oPrint:Say( _nPosLin  , _nColIni + 1840 , Transform(_nVlrVenc4,"@E 999,999,999.99")	, _oFont11b  )

_nPosLin += _nSpcLin
_nPosLin += _nSpcLin

_oPrint:Say( _nPosLin , _nColFim / 2 , 'Histórico Financeiro - Duplicatas a Vencer' , _oFont16b , _nColFim ,,, 2 )

_nPosLin += _nSpcLin
_nPosLin += _nSpcLin

//====================================================================================================
// Seleciona os proximos tres meses de acordo com a data fornecida pelo usuario.
//====================================================================================================
If MV_PAR09 == 'Analitico' // 1 // 'Analitico'  ,'Previa-Sintetic','Excel', 'Impresso Novo'
   _aMesesDup := ROMS030S3M( Val( SubStr(_cMvMesAno , 1 , 2 ) ) , Val( SubStr( _cMvMesAno, 3 , 4 ) ) , 2 )
Else 
   _aMesesDup := ROMS030S3M( Val( SubStr( MV_PAR01 , 1 , 2 ) ) , Val( SubStr( MV_PAR01 , 3 , 4 ) ) , 2 )
EndIf 

DBSelectArea(_cAliasAve)
(_cAliasAve)->( DBGoTop() )

_oPrint:Say( _nPosLin  , _nColIni + 10	, "Período"									, _oFont11b						)
_oPrint:Say( _nPosLin  , 0930			, PadL(_aMes[Val(_aMesesDup[2])],10," ")	, _oFont11b , 1200      ,,, 2	)
_oPrint:Say( _nPosLin  , 1330			, PadL(_aMes[Val(_aMesesDup[3])],10," ")	, _oFont11b , 1590      ,,, 2	)
_oPrint:Say( _nPosLin  , 1740			, PadL(_aMes[Val(_aMesesDup[4])],10," ")	, _oFont11b , 1980      ,,, 2	)
_oPrint:Say( _nPosLin  , 2070			, PadL("Demais Meses",12," ")				, _oFont11b , _nColFim ,,, 2	)

_nPosLin += _nSpcLin

_oPrint:Say( _nPosLin  , _nColIni + 0010 , "Quantidade de duplicatas"							, _oFont11b )
_oPrint:Say( _nPosLin  , _nColIni + 0760 , Transform((_cAliasAve)->NUMDUP01 ,"@E 999999999")	, _oFont11b  )
_oPrint:Say( _nPosLin  , _nColIni + 1180 , Transform((_cAliasAve)->NUMDUP02 ,"@E 999999999")	, _oFont11b  )
_oPrint:Say( _nPosLin  , _nColIni + 1510 , Transform((_cAliasAve)->NUMDUP03 ,"@E 999999999")	, _oFont11b  )
_oPrint:Say( _nPosLin  , _nColIni + 1870 , Transform((_cAliasAve)->NUMDUPACI,"@E 999999999")	, _oFont11b  )

_nPosLin += _nSpcLin

_oPrint:Say( _nPosLin  , _nColIni + 0010 , "Valores a vencer"											, _oFont11b )
_oPrint:Say( _nPosLin  , _nColIni + 0670 , Transform((_cAliasAve)->VENCTO01   ,"@E 999,999,999.99")	, _oFont11b  )
_oPrint:Say( _nPosLin  , _nColIni + 1080 , Transform((_cAliasAve)->VENCTO02   ,"@E 999,999,999.99")	, _oFont11b  )
_oPrint:Say( _nPosLin  , _nColIni + 1460 , Transform((_cAliasAve)->VENCTO03   ,"@E 999,999,999.99")	, _oFont11b  )
_oPrint:Say( _nPosLin  , _nColIni + 1800 , Transform((_cAliasAve)->VENCTOACIMA,"@E 999,999,999.99")	, _oFont11b  )

_nPosLin += _nSpcLin
_nPosLin += _nSpcLin

(_cAliasAve)->( DBCloseArea() )

_oPrint:Say( _nPosLin , _nColFim / 2 , 'Histórico de comissões pagas' , _oFont16b , _nColFim ,,, 2 )

_nPosLin += _nSpcLin
_nPosLin += _nSpcLin

nLinInBox2 := _nPosLin

_oPrint:Say( _nPosLin  , _nColIni + 10	, "Mês"								, _oFont11b	)
_oPrint:Say( _nPosLin  , 0790			, PadL(_aMes[Val(_cMes1)],10," ")	, _oFont11b	)
_oPrint:Say( _nPosLin  , 1320			, PadL(_aMes[Val(_cMes2)],10," ")	, _oFont11b	)
_oPrint:Say( _nPosLin  , 1790			, PadL(_aMes[Val(_cMes3)],10," ")	, _oFont11b	)

_nPosLin += _nSpcLin

_oPrint:Say( _nPosLin ,_nColIni + 0010 , "Valor da Comissão"							, _oFont11b )
_oPrint:Say( _nPosLin ,_nColIni + 0550 , Transform(_nVlrComi1,"@E 999,999,999,999.99")	, _oFont11b  )
_oPrint:Say( _nPosLin ,_nColIni + 1080 , Transform(_nVlrComi2,"@E 999,999,999,999.99")	, _oFont11b  )
_oPrint:Say( _nPosLin ,_nColIni + 1550 , Transform(_nVlrComi3,"@E 999,999,999,999.99")	, _oFont11b  )

_nPosLin += _nSpcLin

_oPrint:Box( nLinInBox , _nColIni , _nPosLin , _nColFim )

_nPosLin += _nSpcLin

Return

/*
===============================================================================================================================
Programa----------: ROMS030S3M
Autor-------------: Fabiano Dias
Data da Criacao---: 01/04/2011
Descrição---------: Funcao que retorna os 3 meses (anteriores/posteriores) de acordo com o mês e ano informados
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS030S3M( _nMesAtual , _nAno , _nOpc )
      
Local _aMeses	:= {}
Local _dMesAtu	:= SToD( StrZero( _nAno , 4 ) + StrZero( _nMesAtual , 2 ) + '01' )

If _nOpc == 1

	//====================================================================================================
	// 1 - Mes corrente
	// 2 - Primeiro mes da subtracao de menos 3 meses
	// 3 - Segundo mes da subtracao de menos 3 meses
	// 4 - Terceiro mes da subtracao de menos 3 meses
	// 5 - Ano que o primeiro mes da subtracao pertence
	// 6 - Ano que o segundo mes da subtracao pertence
	// 7 - Ano que o terceiro mes da subtracao pertence
	//====================================================================================================
	_aMeses := {	_nMesAtual											,;
					StrZero( Month( MonthSub( _dMesAtu , 3 ) ) , 2 )	,;
					StrZero( Month( MonthSub( _dMesAtu , 2 ) ) , 2 )	,;
					StrZero( Month( MonthSub( _dMesAtu , 1 ) ) , 2 )	,;
					Year(  MonthSub( _dMesAtu , 3 ) )					,;
					Year(  MonthSub( _dMesAtu , 2 ) )					,;
					Year(  MonthSub( _dMesAtu , 1 ) )					 }

ElseIf _nOpc == 2

	//====================================================================================================
	// 1 - Mes corrente
	// 2 - Primeiro mes da adição de 3 meses
	// 3 - Segundo mes da adição de 3 meses
	// 4 - Terceiro mes da adição de 3 meses
	// 5 - Ano que o primeiro mes da adição de 3 meses pertence
	// 6 - Ano que o segundo mes da adição de 3 meses pertence
	// 7 - Ano que o terceiro mes da adição de 3 meses pertence
	//====================================================================================================
	_aMeses := {	_nMesAtual											,;
					StrZero( Month( MonthSum( _dMesAtu , 1 ) ) , 2 )	,;
					StrZero( Month( MonthSum( _dMesAtu , 2 ) ) , 2 )	,;
					StrZero( Month( MonthSum( _dMesAtu , 3 ) ) , 2 )	,;
					StrZero( Month( MonthSum( _dMesAtu , 4 ) ) , 2 )	,;
					Year(  MonthSum( _dMesAtu , 1 ) )					,;
					Year(  MonthSum( _dMesAtu , 2 ) )					,;
					Year(  MonthSum( _dMesAtu , 3 ) )					,;
					Year(  MonthSum( _dMesAtu , 4 ) )					 }

EndIf

Return( _aMeses )

/*
===============================================================================================================================
Programa----------: ROMS030VDP
Autor-------------: Fabiano Dias
Data da Criacao---: 01/04/2011
Descrição---------: Funcao para realizar o somatorio entre os intervalos de vencimento dos titulos do tipo NF, LIQ(Liquidacao),
------------------: FAT(Fatura)
Parametros--------: _cAliasDup - alias com dados de vencidos
Retorno-----------: _aDupVenc - array com intervalos processados
===============================================================================================================================
*/
Static Function ROMS030VDP(_cAliasDup)

Local _aDupVenc := {}

DBSelectArea( _cAliasDup )
(_cAliasDup)->( DBGoTop() )
While (_cAliasDup)->( !Eof() )

	If Len(_aDupVenc) == 0		                         		     

		//====================================================================================================
		// 1 - Numero de duplicatas vencidas ate 15 dias.
		// 2 - Somatorio das duplicatas vencidas ate 15 dias.
		// 3 - Numero de duplicatas vencidas de 16 dias a 30 dias.
		// 4 - Somatorio das duplicatas vencidas de 16 dias a 30 dias.
		// 5 - Numero de duplicatas vencidas de 31 dias a 60 dias.
		// 6 - Somatorio de duplicatas vencidas de 31 dias a 60 dias.
		// 7 - Numero de duplicatas vencidas acima de 60 dias.
		// 8 - Somatorio de duplicatas vencidas acima de 60 dias.
		//====================================================================================================
		// A data a ser considerada para verificacao do vencimento do titulo eh a data atual do servidor
		//====================================================================================================
		aAdd( _aDupVenc , {	(_cAliasDup)->NUMDUP15	, (_cAliasDup)->VENCTO15	,;
	                    	(_cAliasDup)->NUMDUP30	, (_cAliasDup)->VENCTO30	,;
	                    	(_cAliasDup)->NUMDUP60	, (_cAliasDup)->VENCTO60	,;
	                    	(_cAliasDup)->NUMDUPACI	, (_cAliasDup)->VENCTOACIMA	})
	
	Else
	
		_aDupVenc[1][1] += (_cAliasDup)->NUMDUP15
		_aDupVenc[1][2] += (_cAliasDup)->VENCTO15
		_aDupVenc[1][3] += (_cAliasDup)->NUMDUP30
		_aDupVenc[1][4] += (_cAliasDup)->VENCTO30
		_aDupVenc[1][5] += (_cAliasDup)->NUMDUP60
		_aDupVenc[1][6] += (_cAliasDup)->VENCTO60
		_aDupVenc[1][7] += (_cAliasDup)->NUMDUPACI
		_aDupVenc[1][8] += (_cAliasDup)->VENCTOACIMA
	
	EndIf

(_cAliasDup)->( DBSkip() )
EndDo

(_cAliasDup)->( DBCloseArea() )

Return( _aDupVenc )

/*
===============================================================================================================================
Programa----------: ROMS030D
Autor-------------: Julio de Paula Paz
Data da Criacao---: 05/02/2019
Descrição---------: Preencher o array _aComissoes com código e tipo de representante e valores zerados quando o array a 
                    aComissões estiver vazio, para que os vendedores que sejam subordinados saiam no relatório.
Parametros--------: _cCodColabor  = Codigo do Colaborador.
                    _cTipoColabor = Tipo de colaborador.
Retorno-----------: _aComiss = Array com os dados dos colaboradores sem comissão.
===============================================================================================================================
*/
User Function ROMS030D(_cCodColabor)
Local _aComisColab := {}
Local _aCodFiliais := FwLoadSM0()
Local _nI

Begin Sequence
   For _nI := 1 To Len(_aCodFiliais)
       aAdd(_aComisColab , { _cCodColabor , _aCodFiliais[_nI,5] , "0" , 0 , 0 , "A" , 0 } )
       aAdd(_aComisColab , { _cCodColabor , _aCodFiliais[_nI,5] , "0" , 0 , 0 , "B" , 0 } )
       aAdd(_aComisColab , { _cCodColabor , _aCodFiliais[_nI,5] , "0" , 0 , 0 , "C" , 0 } )
       aAdd(_aComisColab , { _cCodColabor , _aCodFiliais[_nI,5] , "0" , 0 , 0 , "D" , 0 } )
   Next

End Sequence

Return _aComisColab

/*
===============================================================================================================================
Programa----------: ROMS030E
Autor-------------: Julio de Paula Paz
Data da Criacao---: 13/05/2019
Descrição---------: Faz a montagem de dados para a seção Relação Gerente/Coordenador/Supervisor.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ROMS030E()
Local _nI 
Local _cCodRep   := _cCodRepSA3 
Local _cTipoRep  := _cTipoRepSA3
Local _aComissao 
Local _aValBonDev 

Begin Sequence
 
   For _nI := 1 To Len(_aDadosRelac)
       _cCodRepSA3  := _aDadosRelac[_nI,1]
       _cTipoRepSA3 := _aDadosRelac[_nI,2]

	   FWMsgRun( ,{|| _aComissao := ROMS030SEL() } , 'Aguarde!' ,  'Filtrando a comissao: '+StrZero(_nI,5)+"/"+StrZero(Len(_aDadosRelac),5) )

       //_aComissao := ROMS030SEL()

	   //================================================================================
       // Seleciona os dados da COMISSAO A PAGAR do mes de fechamento do Gerente
       //================================================================================
       _aDadosCom := ROMS030CPA( _cCodRepSA3 , _aComissao )
       
	   //================================================================================
	   // Calcula os valores de bonificações e os valores de devolução sobre pagamentos.
	   //================================================================================
	   _aValBonDev := U_ROMS030F(_aDadosCom,_cCodRepSA3)
       //      Código 1                  Tipo 2              Codigo Gerente 3         Codigo Coordenador 4    Código Supervisor 5    "Valor total recebido" 6 , "Valor total Comissão" 7 , "Valor total Bruto" 8 , "Valor recebido bonificação" 9 , "Valor comissão bonificação" 10

	   _aDadosRelac[_nI,6]  := _aValBonDev[1] // Valor total recebido 
	   _aDadosRelac[_nI,7]  := _aValBonDev[2] // Valor total Comissão 
	   _aDadosRelac[_nI,8]  := _aValBonDev[3] // Valor total Devolvido
	   _aDadosRelac[_nI,9]  := _aValBonDev[4] // Valor total devolvido comissão 
	   _aDadosRelac[_nI,10] := _aValBonDev[5] // Valor total bonificação.
	   _aDadosRelac[_nI,11] := _aValBonDev[6] // Valor total comissão bonificação.
   Next

End Sequence

_cCodRepSA3  := _cCodRep 
_cTipoRepSA3 := _cTipoRep

Return

/*
===============================================================================================================================
Programa----------: ROMS030F
Autor-------------: Julio de Paula Paz
Data da Criacao---: 13/05/2019
Descrição---------: Calcular os dados de Bonificações e devolução de pagamentos para o Quador Relação Gerente/Coordenador e
                    Supervisor.
Parametros--------: _aComissão = Array com os dados da comissão.
                    _cCodRepr  = Código do representante.
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ROMS030F(_aComissao,_cCodGer)
Local _nI
Local _nTotReceb  := 0  // Valor total recebido
Local _nTotComis := 0  // Valor total Comissão
Local _nTotCmBnf := 0  // Valor recebido bonificação
Local _nTotBonif := 0  // Valor comissão bonificação.
Local _aTotBNF   := {}
Local _nVlrDebCo := 0
Local _nTotDevol := 0 
Local _nJ 
Local _cTituloRep 

Begin Sequence
   _cTituloRep  := ""
   If _cTipoRepSA3 == 'G'  	
      _cTituloRep := "Gerente"  
   ElseIf _cTipoRepSA3 == 'C'
      _cTituloRep := "Coordenador"
   ElseIf _cTipoRepSA3 == 'S'
      _cTituloRep := "Supervisor"
   ElseIf _cTipoRepSA3 == 'V'
      _cTituloRep := "Representante"
   ElseIf _cTipoRepSA3 == 'N' 
      _cTituloRep := "Gerente Nacional"
   EndIf  
   
   For _nI:=1 to Len(_aComissao)
       //================================================================================
       // Soma os valores recebidos e os valores de comissão.
       //================================================================================
       If _aComissao[_nI,5] <> 'D'
          _nTotReceb	+= Round(_aComissao[_nI,2],2)
	      _nTotComis	+= Round(_aComissao[_nI,3],2)
	   Else
	      _nTotDevol += Round(_aComissao[_nI,2],2)
	      _nVlrDebCo += Round(_aComissao[_nI,6],2)
       EndIf
   Next

   //================================================================================
   // Calcula o desconto de comissão por bonificação
   //================================================================================
   FWMsgRun(, {|| _aTotBNF := ROMS030BNF( _cCodGer ) }, "Aguarde... ", 'Filtrando bonificações para ' + _cTituloRep + '-' +  _cCodRepSA3 + "..." )

   If !Empty( _aTotBNF )
 	  For _nJ := 1 To Len(_aTotBNF)
          _nTotCmBnf	+= Round(_aTotBNF[_nJ][03],2) // Valor recebido bonificação
	      _nTotBonif	+= Round(_aTotBNF[_nJ][02],2) // Valor comissão bonificação.
	  Next _nJ
   EndIf

End Sequence

_aRet := { _nTotReceb,;  // Valor total recebido
           _nTotComis,;  // Valor total Comissão
           _nTotDevol,;  // Valor total Devolvido
           _nVlrDebCo,;  // Valor total devolvido comissão
           _nTotBonif,;  // Valor total bonificação.
           _nTotCmBnf}   // Valor total comissão bonificação.

Return _aRet  

/*
===============================================================================================================================
Programa----------: ROMS030J
Autor-------------: Julio de Paula Paz
Data da Criacao---: 25/07/2019
Descrição---------: Retornar os valores de comissões que os Gerentes / Coordenadores / Supervisores receberam sobre os 
                    representantes.
Parametros--------: _cCodGerenc    =  Codigo do Gerente / Coordenador / Supervisor
                    _cTipoGerenc   =  Tipo do Gerente / Coordenador / Supervisor
					_cCodRepresen  =  Codigo do representante vinculado ao Gerente / Coordenador / Supervisor
					_cTipoRepresen =  Tipos de Representante
Retorno-----------: _aRet = {Valor Total Base Comissão, Valor Total de comissao, Percentual de Comissão}
===============================================================================================================================
*/
User Function ROMS030J(_cCodGerenc, _cTipGer, _cCodRepresen, _cTipoRepresen) 
Local _cAliasGer	:= GetNextAlias() 
Local _nBaseComiss, _nPercComiss  
Local _cCodSa3  
Local _cTipoSA3 
Local _aDadosRepr := {}, _nI

Begin Sequence
   _cCodSa3  := _cCodRepSA3 
   _cTipoSA3 := _cTipoRepSA3

   _cCodRepSA3  := _cCodGerenc
   _cTipoRepSA3 := _cTipGer

   _nBaseComiss := 0 
   _nValComiss  := 0
   _nPercComiss	:= 0

   FWMsgRun( , {||  ROMS030QRY( _cAliasGer , 10 , "" , _cCodGerenc , " " , " ",/* _cCodRepresen*/, /*_cTipoRepresen*/ ) }, 'Aguarde...', 'Calculando comissao represent. vinculados ao ' + _cCodRepSA3 /*_cCodRepresen*/ +  "..."  ) 	   

   While ! (_cAliasGer)->(Eof())
      _nValComiss := 0
      _nValComiss += (_cAliasGer)->COMISSAO

	  _nI := aScan(_aDadosRepr,{|x| x[1] == (_cAliasGer)->VEND1 })

	  If _nI == 0
         aAdd(_aDadosRepr,{(_cAliasGer)->VEND1, _nValComiss, (_cAliasGer)->VLRRECEB})
	  Else
         _aDadosRepr[_nI,2] += _nValComiss
		 _aDadosRepr[_nI,3] += (_cAliasGer)->VLRRECEB
	  EndIf
      
      (_cAliasGer)->(DBSkip())
   EndDo
   
End Sequence

_cCodRepSA3  := _cCodSa3  
_cTipoRepSA3 := _cTipoSA3  

If Select(_cAliasGer) > 0  
   (_cAliasGer)->( DBCloseArea() )
EndIf

Return _aDadosRepr

/*
===============================================================================================================================
Programa--------: ROMS030T
Autor-----------: Julio de Paula Paz
Data da Criacao-: 02/10/2018
Descrição-------: Versão sintética do relatório Unificado Extrato Comissão.  // ROMS030RUN
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function ROMS030T()

Private _oFont10	:= TFont():New( "Courier New"	,, 08 ,, .F. ,,,, .F. , .F. )
Private _oFont10b	:= TFont():New( "Courier New"	,, 08 ,, .T. ,,,, .F. , .F. )
Private _oFont11b	:= TFont():New( "Courier New"	,, 09 ,, .T. ,,,, .F. , .F. )
Private _oFont12	:= TFont():New( "Courier New"	,, 10 ,, .F. ,,,, .F. , .F. )
Private _oFont12b	:= TFont():New( "Courier New"	,, 10 ,, .T. ,,,, .F. , .F. )
Private _oFont14b	:= TFont():New( "Helvetica"		,, 14 ,, .T. ,,,, .F. , .F. )
Private _oPrint		:= Nil

Private _nPagina	:= 0
Private _nLinha		:= 0100 
Private _nColIni	:= 0030
Private _nColFim	:= 2360 
Private _nQbrPag	:= 3300 
Private _nIniBox	:= 0
Private _nSpcLin	:= 50 
Private _nAjsLin	:= 10 //ajusta a altura de impressao dos dados do relatorio
Private _aDados := {} 

_oPrint := TMSPrinter():New( "Fechamento da Comissão : Resumido" )
_oPrint:SetPortrait() 	// Retrato
_oPrint:SetPaperSize(9)	// Papel A4
_oPrint:StartPage()

ROMS030TCAB( .F. ) // ROMS029CAB       

ROMS030IPP( _oPrint, 60) 

Processa( {|| ROMS030TRUN() } , 'Aguarde!' , 'Processando o relatorio...' ) // ROMS029RUN

//================================================================================
// Finaliza a Pagina e Visualiza antes de Imprimir.
//================================================================================
_oPrint:EndPage()
_oPrint:Preview()

Return
           
/*
===============================================================================================================================
Programa----------: ROMS030TCAB // ROMS029CAB
Autor-------------: Fabiano Dias
Data da Criacao---: 30/03/2011
Descrição---------: Funcao criada para imprimir o cabeçalho das pagina em modo grafico
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS030TCAB( _lImpPag ) // ROMS029CAB

Local _cPath	:= If( IsSrvUnix() , "/" , "\" )
Local _cTitulo	:= "Fechamento da comissão - Resumido - "+ IIF( !Empty(MV_PAR01) , MesExtenso( Val( SubStr( MV_PAR01 , 1 , 2 ) ) ) + ' de ' + SubStr( MV_PAR01 , 3 , 4 ) , "" )

_nLinha := 0100

_oPrint:SayBitmap( _nLinha , _nColIni , _cPath + "system/lgrl01.bmp" , 250 , 100 )

If _lImpPag

_oPrint:Say( _nLinha		, _nColFim - 550 , "PÁGINA: " + AllTrim( Str( _nPagina ) )								, _oFont12b )

Else

_oPrint:Say( _nLinha		, _nColFim - 550 , "SIGA/ROMS030T"														, _oFont12b )
_oPrint:Say( _nLinha + 100	, _nColFim - 550 , "EMPRESA: " + AllTrim(SM0->M0_NOME) + '/' + AllTrim(SM0->M0_FILIAL)	, _oFont12b )

EndIf

_oPrint:Say( _nLinha + 050	, _nColFim - 550 , "DATA DE EMISSÃO: "+ DToC( Date() )									, _oFont12b )

_nLinha += 050

_oPrint:Say( _nLinha , _nColFim / 002 , _cTitulo , _oFont14b , _nColFim ,,, 2 )

_nLinha += _nSpcLin
_nLinha += _nSpcLin

_oPrint:Line( _nLinha , _nColIni , _nLinha , _nColFim )

Return

/*
===============================================================================================================================
Programa----------: ROMS030TCDR // ROMS029CDR
Autor-------------: Fabiano Dias
Data da Criacao---: 30/03/2011
===============================================================================================================================
Descrição---------: Funcao criada para imprimir o cabeçalho dos dados do relatório
===============================================================================================================================
Uso---------------: Italac
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
Setor-------------: TI
===============================================================================================================================
*/
Static Function ROMS030TCDR( _cTipo ) // ROMS029CDR

_oPrint:Box( _nLinha , _nColIni , _nLinha + _nSpcLin , _nColFim )

_oPrint:Say( _nLinha , _nColFim / 2 , _cTipo , _oFont14b , _nColFim ,,, 2 )

_nLinha		+= _nSpcLin
_nIniBox	:= _nLinha

_oPrint:Say( _nLinha + _nAjsLin , _nColIni + 0010 , "Nome"				, _oFont11b )
_oPrint:Say( _nLinha + _nAjsLin , _nColIni + 1020 , "Vlr.Comis.Bruto"	, _oFont11b )
_oPrint:Say( _nLinha + _nAjsLin , _nColIni + 1430 , "INSS"				, _oFont11b )
_oPrint:Say( _nLinha + _nAjsLin , _nColIni + 1590 , "IRRF"				, _oFont11b )
_oPrint:Say( _nLinha + _nAjsLin , _nColIni + 1700 , "Vlr.Comis.Liquida"	, _oFont11b )
_oPrint:Say( _nLinha + _nAjsLin , _nColIni + 2050 , "% Vlr.Recebido"	, _oFont11b )

Return
            
/*
===============================================================================================================================
Programa----------: ROMS030TPRD // ROMS029PRD
Autor-------------: Fabiano Dias
Data da Criacao---: 30/03/2011
Descrição---------: Funcao criada para imprimir os dados do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/

Static Function ROMS030TPRD( _cNome , _nVlrComis , _nINSS , _nIRRF , _nVlrBase , _nVlrBonif ) // ROMS029PRD

Local _nPorcCom		:= 0
Local _nVlrLiq		:= 0

Default _nVlrBonif	:= 0

_nPorcCom			:= ( ( _nVlrComis - _nVlrBonif ) / _nVlrBase ) * 100
_nVlrComis			-= _nVlrBonif
_nVlrLiq			:= _nVlrComis - ( _nINSS + _nIRRF )

_oPrint:Say( _nLinha + _nAjsLin , _nColIni + 0010 , SubStr( _cNome , 1 , 57 )		  				, _oFont10 )
_oPrint:Say( _nLinha + _nAjsLin , _nColIni + 1080 , Transform( _nVlrComis	, "@E 999,999,999.99" )	, _oFont10 )
_oPrint:Say( _nLinha + _nAjsLin , _nColIni + 1350 , Transform( _nINSS		, "@E 999,999.99" )		, _oFont10 )
_oPrint:Say( _nLinha + _nAjsLin , _nColIni + 1500 , Transform( _nIRRF		, "@E 999,999.99" )		, _oFont10 )
_oPrint:Say( _nLinha + _nAjsLin , _nColIni + 1800 , Transform( _nVlrLiq		, "@E 999,999,999.99" )	, _oFont10 )
_oPrint:Say( _nLinha + _nAjsLin , _nColIni + 2200 , Transform( _nPorcCom	, "@E 999.999" ) + '%'	, _oFont10 )

Return

/*
===============================================================================================================================
Programa----------: ROMS030TTOT // ROMS029TOT
Autor-------------: Fabiano Dias
Data da Criacao---: 30/03/2011
Descrição---------: Funcao criada para imprimir os Totalizadores do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS030TTOT( _cNome , _nVlrComis , _nINSS , _nIRRF , _nVlrBase , _nVlrBonif ) // ROMS029TOT 

Local _nPorcCom		:= 0
Local _nVlrLiq		:= 0

Default _nVlrBonif	:= 0

//_nPorcCom	:= ( ( _nVlrComis - _nVlrBonif ) / _nVlrBase ) * 100 
//_nVlrLiq	:= _nVlrComis - _nVlrBonif - ( _nINSS + _nIRRF )     

_nVlrComis  := _nVlrComis - _nVlrBonif
_nPorcCom	:= ( _nVlrComis  / _nVlrBase ) * 100 
_nVlrLiq	:= _nVlrComis - ( _nINSS + _nIRRF )   

_oPrint:Say( _nLinha + _nAjsLin , _nColIni + 0010 , SubStr( _cNome , 1 , 40 )						, _oFont10b )
_oPrint:Say( _nLinha + _nAjsLin , _nColIni + 1080 , Transform( _nVlrComis	, "@E 999,999,999.99" )	, _oFont10b )
_oPrint:Say( _nLinha + _nAjsLin , _nColIni + 1350 , Transform( _nINSS		, "@E 999,999.99" )		, _oFont10b )
_oPrint:Say( _nLinha + _nAjsLin , _nColIni + 1500 , Transform( _nIRRF		, "@E 999,999.99" )		, _oFont10b )
_oPrint:Say( _nLinha + _nAjsLin , _nColIni + 1800 , Transform( _nVlrLiq		, "@E 999,999,999.99" )	, _oFont10b )
_oPrint:Say( _nLinha + _nAjsLin , _nColIni + 2200 , Transform( _nPorcCom	, "@E 999.999" ) + '%'	, _oFont10b )

Return
           
/*
===============================================================================================================================
Programa----------: ROMS030TBOX // ROMS029BOX
Autor-------------: Fabiano Dias
Data da Criacao---: 30/03/2011
Descrição---------: Funcao criada para imprimir uma BOX no relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS030TBOX() // ROMS029BOX

_oPrint:Box( _nIniBox , _nColIni , _nLinha , _nColFim )

Return

/*
===============================================================================================================================
Programa----------: ROMS030TQPG // ROMS029QPG
Autor-------------: Fabiano Dias
Data da Criacao---: 30/03/2011
Descrição---------: Funcao criada para efetuar a quebra de páginas do relatório
Parametros--------: _nLinhas  - Numero de linhas que sera reduzido do tamanho do box do relatorio.
------------------: _lImpBox  - .T. - indica que imprime box
------------------: _lImpCab  - .T. - indica que imprime cabecalho de dados
------------------: _bImpBox  - Nome da funcao para impressao do box e suas divisorias
------------------: _bImpCab  - Nome da funcao para impressao do cabecalho de dados
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS030TQPG( _nLinhas , _lImpBox , _lImpCab , _bImpBox , _bImpCab ) // ROMS029QPG

//================================================================================
// Quebra de pagina
//================================================================================
If _nLinha > _nQbrPag

	_nLinha := _nLinha - (_nSpcLin * _nLinhas)
	
	//================================================================================
	// Verifica se imprime o box e divisorias do relatorio
	//================================================================================
	If _lImpBox
		&_bImpBox
	EndIf
	
	//================================================================================
	// Finaliza a página atual e inicializa uma nova
	//================================================================================
	_oPrint:EndPage()
	_oPrint:StartPage()
	
	_nPagina++
	
	//================================================================================
	// Chama a impressão do cabeçalho do relatório
	//================================================================================
	ROMS030TCAB( .T. ) // ROMS029CAB
	
	_nLinha += _nSpcLin
	_nLinha += _nSpcLin
	
	//================================================================================
	// Verifica se imprime o cabecalho dos dados
	//================================================================================
	If _lImpCab
	
		&_bImpCab
		
		_nLinha += _nSpcLin
		_oPrint:Line( _nLinha , _nColIni , _nLinha , _nColFim )
		
	EndIf

EndIf

Return

/*
===============================================================================================================================
Programa----------: ROMS030TPPG // ROMS029PPG
Autor-------------: Fabiano Dias
Data da Criacao---: 30/03/2011
Descrição---------: Funcao criada para endereçar o cabeçalho dos dados do relatório
Parametros--------: _cTipo  - Descrição do cabeçalho
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS030TPPG( _cTipo ) // ROMS029PPG
						
_nLinha += _nSpcLin
_nLinha += _nSpcLin

ROMS030TCDR(_cTipo) // ROMS029CDR

Return

/*
===============================================================================================================================
Programa----------: ROMS030TQRY
Autor-------------: Fabiano Dias
Data da Criacao---: 30/03/2011
Descrição---------: Funcao criada para endereçar o cabeçalho dos dados do relatório
Parametros--------: _cAlias : Define o Alias da área de trabalho temporária que será criada
------------------: _nOpcao : Informa a opção de consulta a realizar
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS030TQRY( _cAlias , _nOpcao ) // ROMS029QRY

Local _cWhere01 

Local _cWhere02, _cWhere03, _cParam

Local _cWhere04 

	If AllTrim(MV_PAR01) == AllTrim(MV_PAR02)
       _cWhere01 := "% AND SubStr(E3_EMISSAO,1,6) = '" + SubStr(MV_PAR01,3,4) + SubStr(MV_PAR01,1,2) + "' %"  
	Else    
	   _cWhere01 := "% AND SubStr(E3_EMISSAO,1,6) >= '" + SubStr(MV_PAR01,3,4) + SubStr(MV_PAR01,1,2) + "' AND SubStr(E3_EMISSAO,1,6) <= '"+ SubStr(MV_PAR02,3,4) + SubStr(MV_PAR02,1,2) + "' %" 
	EndIf

    _cParam   := ""
    _cWhere02 := ""
    _cWhere03 := ""
    
    If ! Empty(MV_PAR03) // Gerente Nacional      
       If Right(AllTrim(MV_PAR03),1) <> ";"
          _cParam += AllTrim(MV_PAR03) + ";"
       Else
          _cParam += AllTrim(MV_PAR03)        
       EndIf
       
       _cWhere02 += " AND F2.F2_VEND5 IN " + FormatIn(MV_PAR03,";")
       
    EndIf

    If ! Empty(MV_PAR04) // Gerente      
       If Right(AllTrim(MV_PAR04),1) <> ";"
          _cParam += AllTrim(MV_PAR04) + ";"
       Else
          _cParam += AllTrim(MV_PAR04)        
       EndIf
       
       _cWhere02 += " AND F2.F2_VEND3 IN " + FormatIn(MV_PAR04,";")
       
    EndIf
    
    If ! Empty(MV_PAR05) // Coordenador    
       If Right(AllTrim(MV_PAR05),1) <> ";"
          _cParam += AllTrim(MV_PAR05) + ";"
       Else
          _cParam += AllTrim(MV_PAR05)        
       EndIf                            
       
       _cWhere02 += " AND F2.F2_VEND2 IN " + FormatIn(MV_PAR05,";")
    EndIf
    
    If ! Empty(MV_PAR06) // Supervisor      
       If Right(AllTrim(MV_PAR06),1) <> ";"
          _cParam += AllTrim(MV_PAR06) + ";"
       Else
          _cParam += AllTrim(MV_PAR06)        
       EndIf                                       
       
       _cWhere02 += " AND F2.F2_VEND4 IN " + FormatIn(MV_PAR06,";")
    EndIf

    If ! Empty(MV_PAR07) // Representantes  
       If Right(AllTrim(MV_PAR07),1) <> ";"
          _cParam += AllTrim(MV_PAR07) + ";"
       Else
          _cParam += AllTrim(MV_PAR07)        
       EndIf
       
       _cWhere02 += " AND F2.F2_VEND1 IN " + FormatIn(MV_PAR07,";")
    EndIf        
    
    If ! Empty(_cParam)
       _cWhere03 := " AND A3.A3_COD IN " + FormatIn(_cParam,";")   
    EndIf

    If MV_PAR10 == 'Interno CLT' // 1 // 'Interno CLT','Externo PJ' ,'Ambos'
	   _cWhere03 += " AND A3_TIPO = 'I' "
	ElseIf MV_PAR10 == 'Externo PJ' //2 // 'Interno CLT','Externo PJ' ,'Ambos'
       _cWhere03 += " AND A3_TIPO = 'E' "
	EndIf
            
    _cWhere02 := "% " + _cWhere02 + " %"
    
    _cWhere03 := "% " + _cWhere03 + " %"

	If _nOpcao == 1 //_cTipoRepSA3 = "V" // Extrato Vendedor
	   _cWhere04 := "% AND F2.F2_VEND1 = E3.E3_VEND %"
	EndIf
		
	If _nOpcao == 3 // _cTipoRepSA3 = "S" // Extrato Supervisor
	   _cWhere04 := "% AND F2.F2_VEND4 = E3.E3_VEND %"
	EndIf
		
	If _nOpcao == 2 // _cTipoRepSA3 = "C" // Extrato Coordenador
	   _cWhere04 := "% AND F2.F2_VEND2 = E3.E3_VEND %"
	EndIf
		
	If _nOpcao == 4 // _cTipoRepSA3 = "G" // Extrato Gerente
	   _cWhere04 := "% AND F2.F2_VEND3 = E3.E3_VEND %"
	EndIf
		
    If _nOpcao == 5 // _cTipoRepSA3 = "N" // Extrato Gerente Nacional 
	   _cWhere04 := "% AND F2.F2_VEND5 = E3.E3_VEND %"
	EndIf

If Select(_cAlias) > 0
   (_cAlias)->( DBCloseArea() )
EndIf

Do Case
	//================================================================================
	// Seleciona dados para o relatorio do tipo analitico, para as comissoes de 
	// credito e debito dos vendedores.
	//================================================================================
	Case _nOpcao == 1
	
		BeginSql alias _cAlias

			SELECT                                   
			    E3.E3_FILIAL     AS FILIAL  ,
			    E3.E3_VEND       AS CODVEND	,
				A3.A3_NOME       AS NOMEVEND, 
			    A3.A3_I_DEDUC    AS DEDUCAO ,
			    E3.E3_I_ORIGE    AS ORIGEM  ,
			    SUM(E3.E3_COMIS) AS COMISSAO,
			    SUM(E3.E3_BASE)  AS VLRRECEB,
			    Case
			        WHEN F2.F2_VEND2 = ' '          THEN 'A'
			        WHEN F2.F2_VEND1 <> F2.F2_VEND2 THEN 'B'
			        WHEN F2.F2_VEND3 <> ' '         THEN 'B'
			    END AS TIPOVENDA
			    
			FROM %Table:SE3% E3
			
			JOIN %Table:SA3% A3
			ON
			    A3.A3_COD = E3.E3_VEND
			
			JOIN %Table:SE1% E1
			ON
			    E1_FILIAL  = E3_FILIAL
			AND E1_NUM     = E3_NUM
			AND E1_PREFIXO = E3_PREFIXO
			AND E1_PARCELA = E3_PARCELA
			AND E1_TIPO    = E3_TIPO
			AND E1_CLIENTE = E3_CODCLI
			AND E1_LOJA    = E3_LOJA
			
			JOIN %Table:SF2% F2
			ON
			    F2.F2_FILIAL  = E1.E1_FILIAL
			AND F2.F2_DOC     = E1.E1_NUM
			AND (F2.F2_SERIE   = E1.E1_PREFIXO)
			AND F2.F2_CLIENTE = E1.E1_CLIENTE
			AND F2.F2_LOJA    = E1.E1_LOJA
			%Exp:_cWhere04%    
			WHERE
			    E3.%NotDel%
			AND A3.%NotDel%
			%Exp:_cWhere03%
			AND E1.%NotDel%
			%Exp:_cWhere01% 
			AND F2.%NotDel%
			%Exp:_cWhere02%
			
			GROUP BY
			    E3.E3_FILIAL ,
			    E3.E3_VEND   ,  
				A3.A3_NOME   , 
			    A3.A3_I_DEDUC,
			    E3.E3_I_ORIGE,
			    Case
			        WHEN F2.F2_VEND2 = ' '          THEN 'A'
			        WHEN F2.F2_VEND1 <> F2.F2_VEND2 THEN 'B'
			        WHEN F2.F2_VEND3 <> ' '         THEN 'B'
			    END
		
			UNION ALL
			
			SELECT
			    E3.E3_FILIAL     AS FILIAL  ,
			    E3.E3_VEND       AS CODVEND	,
				A3.A3_NOME       AS NOMEVEND,
			    A3.A3_I_DEDUC    AS DEDUCAO ,
			    E3.E3_I_ORIGE    AS ORIGEM  ,
			    SUM(E3.E3_COMIS) AS COMISSAO,
			    SUM(E3.E3_BASE)  AS VLRRECEB,
			    MIN( Case
			            WHEN F2.F2_VEND2 = ' '          THEN 'A'
			            WHEN F2.F2_VEND1 <> F2.F2_VEND2 THEN 'B'
			            WHEN F2.F2_VEND3 <> ' '         THEN 'B'
			    END ) AS TIPOVENDA
			FROM %Table:SE3% E3
			
			INNER JOIN %Table:SE1% E1
			ON  E1.E1_FILIAL  = E3.E3_FILIAL
			AND E1.E1_TIPO    = E3.E3_TIPO
			AND E1.E1_PREFIXO = E3.E3_PREFIXO
			AND E1.E1_NUM     = E3.E3_NUM
			AND E1.E1_SERIE   = E3.E3_SERIE
			AND E1.E1_PARCELA = E3.E3_PARCELA
			AND E1.E1_CLIENTE = E3.E3_CODCLI
			AND E1.E1_LOJA    = E3.E3_LOJA
			
			INNER JOIN %Table:SA3% A3
			ON  A3.A3_COD     = E3.E3_VEND
			
			INNER JOIN %Table:SF2% F2
			ON  F2.F2_FILIAL  = E1.E1_FILIAL
			AND F2.F2_DOC     = E1.E1_NUM
			AND (F2.F2_SERIE   = E1.E1_PREFIXO OR E1.E1_PREFIXO = 'R')
			AND F2.F2_CLIENTE = E1.E1_CLIENTE
			AND F2.F2_LOJA    = E1.E1_LOJA
			%Exp:_cWhere04%    
					
			WHERE
			    E3.%NotDel%
			AND E1.%NotDel%
			%Exp:_cWhere03%
			AND A3.%NotDel%
			%Exp:_cWhere02%
			AND F2.%NotDel% 
			%Exp:_cWhere01%
			AND E1.E1_ORIGEM = 'FINA460'
			AND EXISTS(	SELECT E5.E5_DATA FROM %Table:SE5% E5
			  				WHERE  E5.%NotDel%
			  						AND F2.F2_FILIAL  = E5.E5_FILIAL
			  						AND F2.F2_DOC     = E5.E5_NUMERO
			  						AND (F2.F2_SERIE   = E5.E5_PREFIXO OR E5.E5_PREFIXO = 'R')
			  						AND F2.F2_CLIENTE = E5.E5_CLIFOR
			  						AND F2.F2_LOJA    = E5.E5_LOJA
			  						AND E1.E1_NUMLIQ  = E5.E5_DOCUMEN
			  						AND E1.E1_FILIAL  = E5.E5_FILIAL
			  						AND E5.E5_SITUACA <> 'C'
				  					AND E5.E5_DOCUMEN <> ' ')
			  						
			%Exp:_cWhere02%
			
			GROUP BY
			    E3.E3_FILIAL ,
			    E3.E3_VEND   ,
				A3.A3_NOME   ,
			    A3.A3_I_DEDUC,
			    E3.E3_I_ORIGE,
			    Case
			        WHEN F2.F2_VEND2 = ' '          THEN 'A'
			        WHEN F2.F2_VEND1 <> F2.F2_VEND2 THEN 'B'
			        WHEN F2.F2_VEND3 <> ' '         THEN 'B'
			    END
			
			UNION ALL
			
			SELECT
			    E3.E3_FILIAL     AS FILIAL  ,
			    E3.E3_VEND       AS CODVEND	,
				A3.A3_NOME       AS NOMEVEND,
			    A3.A3_I_DEDUC    AS DEDUCAO ,
			    E3.E3_I_ORIGE    AS ORIGEM  ,
			    SUM(E3.E3_COMIS) AS COMISSAO,
			    SUM(E3.E3_BASE)  AS VLRRECEB,
			    'D'              AS TIPOVENDA
			FROM %Table:SE3% E3
			
			INNER JOIN %Table:SA3% A3
			ON  E3.E3_VEND    = A3.A3_COD
			
			INNER JOIN %Table:SA1% A1
			ON  A1.A1_COD     = E3.E3_CODCLI
			AND A1.A1_LOJA    = E3.E3_LOJA
			
			WHERE
			    E3.%NotDel%
			AND A3.%NotDel%
			AND A1.%NotDel%
			%Exp:_cWhere03%
			AND E3.E3_TIPO   = 'NCC'
			%Exp:_cWhere01%
			AND E3.E3_NUM    IN (  SELECT D1.D1_DOC
			                       FROM %Table:SD1% D1 , %Table:SF2% F2
			                       WHERE
			                           D1.%NotDel%
			                       AND F2.%NotDel%
			                       AND E3.E3_FILIAL  = D1.D1_FILIAL // AND F2.F2_VEND1   = E3.E3_VEND    
			                       AND E3.E3_NUM     = D1.D1_DOC
			                       AND E3.E3_SERIE   = D1.D1_SERIE
			                       AND E3.E3_CODCLI  = D1.D1_FORNECE
			                       AND E3.E3_LOJA    = D1.D1_LOJA
			                       AND F2.F2_FILIAL  = D1.D1_FILIAL
			                       AND F2.F2_DOC     = D1.D1_NFORI
			                       AND F2.F2_SERIE   = D1.D1_SERIORI
			                       AND F2.F2_CLIENTE = D1.D1_FORNECE
			                       AND F2.F2_LOJA    = D1.D1_LOJA  
								   %Exp:_cWhere04%    
			                    ) // %Exp:_cWhere02%			
			GROUP BY
			    E3.E3_FILIAL ,
			    E3.E3_VEND   ,
				A3.A3_NOME   ,
			    A3.A3_I_DEDUC,
			    E3.E3_I_ORIGE,
			    'D'
			
			UNION ALL
			
			SELECT
			    E3.E3_FILIAL     AS FILIAL  ,
			    E3.E3_VEND       AS CODVEND	,
				A3.A3_NOME       AS NOMEVEND,
			    A3.A3_I_DEDUC    AS DEDUCAO ,
			    E3.E3_I_ORIGE    AS ORIGEM  ,
			    SUM(E3.E3_COMIS) AS COMISSAO,
			    SUM(E3.E3_BASE)  AS VLRRECEB,
			    'D'              AS TIPOVENDA
			FROM %Table:SE3% E3
			
			JOIN %Table:SA3% A3
			ON
			    E3.E3_VEND    = A3.A3_COD
			
			JOIN %Table:SA1% A1
			ON
			    A1.A1_COD     = E3.E3_CODCLI
			AND A1.A1_LOJA    = E3.E3_LOJA
			
			WHERE
			    E3.%NotDel%
			AND A3.%NotDel%
			%Exp:_cWhere03%
			AND A1.%NotDel%
			%Exp:_cWhere01%
			AND E3.E3_TIPO   = 'NCC'
			AND A3.A3_SUPER  = ' '
			
			AND E3.E3_NUM    NOT IN (  SELECT D1.D1_DOC
			                           FROM %Table:SD1% D1, %Table:SF2% F2
			                           WHERE
			                               D1.D_E_L_E_T_ = ' '
			                           AND F2.D_E_L_E_T_ = ' '
			                           AND E3.E3_FILIAL  = D1.D1_FILIAL
			                           AND E3.E3_NUM     = D1.D1_DOC
			                           AND E3.E3_SERIE   = D1.D1_SERIE
			                           AND E3.E3_CODCLI  = D1.D1_FORNECE
			                           AND E3.E3_LOJA    = D1.D1_LOJA
			                           AND F2.F2_FILIAL  = D1.D1_FILIAL
			                           AND F2.F2_DOC     = D1.D1_NFORI
			                           AND F2.F2_SERIE   = D1.D1_SERIORI
			                           AND F2.F2_CLIENTE = D1.D1_FORNECE
			                           AND F2.F2_LOJA    = D1.D1_LOJA ) // %Exp:_cWhere02%			
			GROUP BY E3.E3_FILIAL , 
			         E3.E3_VEND , 
					 A3.A3_NOME ,
			         A3.A3_I_DEDUC , 
			         E3.E3_I_ORIGE , 'D'
			ORDER BY FILIAL , CODVEND , TIPOVENDA

		EndSql
	
	//================================================================================
	// Seleciona dados para o relatorio do tipo analitico, para as comissoes de
	// credito e debito dos coordenadores.
	//================================================================================
	Case _nOpcao == 2

		BeginSql alias _cAlias

			SELECT                                   
			    E3.E3_FILIAL     AS FILIAL  ,
			    E3.E3_VEND       AS CODCOORD	,
				A3.A3_NOME       AS NOMECOORD, 
			    A3.A3_I_DEDUC    AS DEDUCAO ,
			    E3.E3_I_ORIGE    AS ORIGEM  ,
			    SUM(E3.E3_COMIS) AS COMISSAO,
			    SUM(E3.E3_BASE)  AS VLRRECEB,
			    Case
			        WHEN F2.F2_VEND2 = ' '          THEN 'A'
			        WHEN F2.F2_VEND1 <> F2.F2_VEND2 THEN 'B'
			        WHEN F2.F2_VEND3 <> ' '         THEN 'B'
			    END AS TIPOVENDA
			    
			FROM %Table:SE3% E3
			
			JOIN %Table:SA3% A3
			ON
			    A3.A3_COD = E3.E3_VEND
			
			JOIN %Table:SE1% E1
			ON
			    E1_FILIAL  = E3_FILIAL
			AND E1_NUM     = E3_NUM
			AND E1_PREFIXO = E3_PREFIXO
			AND E1_PARCELA = E3_PARCELA
			AND E1_TIPO    = E3_TIPO
			AND E1_CLIENTE = E3_CODCLI
			AND E1_LOJA    = E3_LOJA
			
			JOIN %Table:SF2% F2
			ON
			    F2.F2_FILIAL  = E1.E1_FILIAL
			AND F2.F2_DOC     = E1.E1_NUM
			AND (F2.F2_SERIE   = E1.E1_PREFIXO)
			AND F2.F2_CLIENTE = E1.E1_CLIENTE
			AND F2.F2_LOJA    = E1.E1_LOJA
			%Exp:_cWhere04%    
			WHERE
			    E3.%NotDel%
			AND A3.%NotDel%
			%Exp:_cWhere03%
			AND E1.%NotDel%
			%Exp:_cWhere01% 
			AND F2.%NotDel%
			%Exp:_cWhere02%
			
			GROUP BY
			    E3.E3_FILIAL ,
			    E3.E3_VEND   ,  
				A3.A3_NOME   , 
			    A3.A3_I_DEDUC,
			    E3.E3_I_ORIGE,
			    Case
			        WHEN F2.F2_VEND2 = ' '          THEN 'A'
			        WHEN F2.F2_VEND1 <> F2.F2_VEND2 THEN 'B'
			        WHEN F2.F2_VEND3 <> ' '         THEN 'B'
			    END
		
			UNION ALL
			
			SELECT
			    E3.E3_FILIAL     AS FILIAL  ,
			    E3.E3_VEND       AS CODCOORD	,
				A3.A3_NOME       AS NOMECOORD,
			    A3.A3_I_DEDUC    AS DEDUCAO ,
			    E3.E3_I_ORIGE    AS ORIGEM  ,
			    SUM(E3.E3_COMIS) AS COMISSAO,
			    SUM(E3.E3_BASE)  AS VLRRECEB,
			    MIN( Case
			            WHEN F2.F2_VEND2 = ' '          THEN 'A'
			            WHEN F2.F2_VEND1 <> F2.F2_VEND2 THEN 'B'
			            WHEN F2.F2_VEND3 <> ' '         THEN 'B'
			    END ) AS TIPOVENDA
			FROM %Table:SE3% E3
			
			INNER JOIN %Table:SE1% E1
			ON  E1.E1_FILIAL  = E3.E3_FILIAL
			AND E1.E1_TIPO    = E3.E3_TIPO
			AND E1.E1_PREFIXO = E3.E3_PREFIXO
			AND E1.E1_NUM     = E3.E3_NUM
			AND E1.E1_SERIE   = E3.E3_SERIE
			AND E1.E1_PARCELA = E3.E3_PARCELA
			AND E1.E1_CLIENTE = E3.E3_CODCLI
			AND E1.E1_LOJA    = E3.E3_LOJA
			
			INNER JOIN %Table:SA3% A3
			ON  A3.A3_COD     = E3.E3_VEND
			
			INNER JOIN %Table:SF2% F2
			ON  F2.F2_FILIAL  = E1.E1_FILIAL
			AND F2.F2_DOC     = E1.E1_NUM
			AND (F2.F2_SERIE   = E1.E1_PREFIXO OR E1.E1_PREFIXO = 'R')
			AND F2.F2_CLIENTE = E1.E1_CLIENTE
			AND F2.F2_LOJA    = E1.E1_LOJA
			%Exp:_cWhere04%    
					
			WHERE
			    E3.%NotDel%
			AND E1.%NotDel%
			%Exp:_cWhere03%
			AND A3.%NotDel%
			%Exp:_cWhere02%
			AND F2.%NotDel% 
			%Exp:_cWhere01%
			AND E1.E1_ORIGEM = 'FINA460'
			AND EXISTS(	SELECT E5.E5_DATA FROM %Table:SE5% E5
			  				WHERE  E5.%NotDel%
			  						AND F2.F2_FILIAL  = E5.E5_FILIAL
			  						AND F2.F2_DOC     = E5.E5_NUMERO
			  						AND (F2.F2_SERIE   = E5.E5_PREFIXO OR E5.E5_PREFIXO = 'R')
			  						AND F2.F2_CLIENTE = E5.E5_CLIFOR
			  						AND F2.F2_LOJA    = E5.E5_LOJA
			  						AND E1.E1_NUMLIQ  = E5.E5_DOCUMEN
			  						AND E1.E1_FILIAL  = E5.E5_FILIAL
			  						AND E5.E5_SITUACA <> 'C'
				  					AND E5.E5_DOCUMEN <> ' ')
			  						
			%Exp:_cWhere02%
			
			GROUP BY
			    E3.E3_FILIAL ,
			    E3.E3_VEND   ,
				A3.A3_NOME   ,
			    A3.A3_I_DEDUC,
			    E3.E3_I_ORIGE,
			    Case
			        WHEN F2.F2_VEND2 = ' '          THEN 'A'
			        WHEN F2.F2_VEND1 <> F2.F2_VEND2 THEN 'B'
			        WHEN F2.F2_VEND3 <> ' '         THEN 'B'
			    END
			
			UNION ALL
			
			SELECT
			    E3.E3_FILIAL     AS FILIAL  ,
			    E3.E3_VEND       AS CODCOORD	,
				A3.A3_NOME       AS NOMECOORD,
			    A3.A3_I_DEDUC    AS DEDUCAO ,
			    E3.E3_I_ORIGE    AS ORIGEM  ,
			    SUM(E3.E3_COMIS) AS COMISSAO,
			    SUM(E3.E3_BASE)  AS VLRRECEB,
			    'D'              AS TIPOVENDA
			FROM %Table:SE3% E3
			
			INNER JOIN %Table:SA3% A3
			ON  E3.E3_VEND    = A3.A3_COD
			
			INNER JOIN %Table:SA1% A1
			ON  A1.A1_COD     = E3.E3_CODCLI
			AND A1.A1_LOJA    = E3.E3_LOJA
			
			WHERE
			    E3.%NotDel%
			AND A3.%NotDel%
			AND A1.%NotDel%
			%Exp:_cWhere03%
			AND E3.E3_TIPO   = 'NCC'
			%Exp:_cWhere01%
			AND E3.E3_NUM    IN (  SELECT D1.D1_DOC
			                       FROM %Table:SD1% D1 , %Table:SF2% F2
			                       WHERE
			                           D1.%NotDel%
			                       AND F2.%NotDel%
			                       AND E3.E3_FILIAL  = D1.D1_FILIAL // AND F2.F2_VEND1   = E3.E3_VEND    
			                       AND E3.E3_NUM     = D1.D1_DOC
			                       AND E3.E3_SERIE   = D1.D1_SERIE
			                       AND E3.E3_CODCLI  = D1.D1_FORNECE
			                       AND E3.E3_LOJA    = D1.D1_LOJA
			                       AND F2.F2_FILIAL  = D1.D1_FILIAL
			                       AND F2.F2_DOC     = D1.D1_NFORI
			                       AND F2.F2_SERIE   = D1.D1_SERIORI
			                       AND F2.F2_CLIENTE = D1.D1_FORNECE
			                       AND F2.F2_LOJA    = D1.D1_LOJA  
								   %Exp:_cWhere04%    
			                    ) // %Exp:_cWhere02%			
			GROUP BY
			    E3.E3_FILIAL ,
			    E3.E3_VEND   ,
				A3.A3_NOME   ,
			    A3.A3_I_DEDUC,
			    E3.E3_I_ORIGE,
			    'D'
			
			UNION ALL
			
			SELECT
			    E3.E3_FILIAL     AS FILIAL  ,
			    E3.E3_VEND       AS CODCOORD	,
				A3.A3_NOME       AS NOMECOORD,
			    A3.A3_I_DEDUC    AS DEDUCAO ,
			    E3.E3_I_ORIGE    AS ORIGEM  ,
			    SUM(E3.E3_COMIS) AS COMISSAO,
			    SUM(E3.E3_BASE)  AS VLRRECEB,
			    'D'              AS TIPOVENDA
			FROM %Table:SE3% E3
			
			JOIN %Table:SA3% A3
			ON
			    E3.E3_VEND    = A3.A3_COD
			
			JOIN %Table:SA1% A1
			ON
			    A1.A1_COD     = E3.E3_CODCLI
			AND A1.A1_LOJA    = E3.E3_LOJA
			
			WHERE
			    E3.%NotDel%
			AND A3.%NotDel%
			%Exp:_cWhere03%
			AND A1.%NotDel%
			%Exp:_cWhere01%
			AND E3.E3_TIPO   = 'NCC'
			AND A3.A3_SUPER  = ' '
			
			AND E3.E3_NUM    NOT IN (  SELECT D1.D1_DOC
			                           FROM %Table:SD1% D1, %Table:SF2% F2
			                           WHERE
			                               D1.D_E_L_E_T_ = ' '
			                           AND F2.D_E_L_E_T_ = ' '
			                           AND E3.E3_FILIAL  = D1.D1_FILIAL
			                           AND E3.E3_NUM     = D1.D1_DOC
			                           AND E3.E3_SERIE   = D1.D1_SERIE
			                           AND E3.E3_CODCLI  = D1.D1_FORNECE
			                           AND E3.E3_LOJA    = D1.D1_LOJA
			                           AND F2.F2_FILIAL  = D1.D1_FILIAL
			                           AND F2.F2_DOC     = D1.D1_NFORI
			                           AND F2.F2_SERIE   = D1.D1_SERIORI
			                           AND F2.F2_CLIENTE = D1.D1_FORNECE
			                           AND F2.F2_LOJA    = D1.D1_LOJA ) // %Exp:_cWhere02%			
			GROUP BY E3.E3_FILIAL , 
			         E3.E3_VEND , 
					 A3.A3_NOME ,
			         A3.A3_I_DEDUC , 
			         E3.E3_I_ORIGE , 'D'
			ORDER BY FILIAL , CODCOORD , TIPOVENDA

		EndSql

    //================================================================================
	// Seleciona dados para o relatorio do tipo analitico, para as comissoes de
	// credito e debito dos supervisores.
	//================================================================================
	Case _nOpcao == 3
	
		BeginSql alias _cAlias

			SELECT                                   
			    E3.E3_FILIAL     AS FILIAL  ,
			    E3.E3_VEND       AS CODSUPERV	,
				A3.A3_NOME       AS NOMESUPERV, 
			    A3.A3_I_DEDUC    AS DEDUCAO ,
			    E3.E3_I_ORIGE    AS ORIGEM  ,
			    SUM(E3.E3_COMIS) AS COMISSAO,
			    SUM(E3.E3_BASE)  AS VLRRECEB,
			    Case
			        WHEN F2.F2_VEND2 = ' '          THEN 'A'
			        WHEN F2.F2_VEND1 <> F2.F2_VEND2 THEN 'B'
			        WHEN F2.F2_VEND3 <> ' '         THEN 'B'
			    END AS TIPOVENDA
			    
			FROM %Table:SE3% E3
			
			JOIN %Table:SA3% A3
			ON
			    A3.A3_COD = E3.E3_VEND
			
			JOIN %Table:SE1% E1
			ON
			    E1_FILIAL  = E3_FILIAL
			AND E1_NUM     = E3_NUM
			AND E1_PREFIXO = E3_PREFIXO
			AND E1_PARCELA = E3_PARCELA
			AND E1_TIPO    = E3_TIPO
			AND E1_CLIENTE = E3_CODCLI
			AND E1_LOJA    = E3_LOJA
			
			JOIN %Table:SF2% F2
			ON
			    F2.F2_FILIAL  = E1.E1_FILIAL
			AND F2.F2_DOC     = E1.E1_NUM
			AND (F2.F2_SERIE   = E1.E1_PREFIXO)
			AND F2.F2_CLIENTE = E1.E1_CLIENTE
			AND F2.F2_LOJA    = E1.E1_LOJA
			%Exp:_cWhere04%    
			WHERE
			    E3.%NotDel%
			AND A3.%NotDel%
			%Exp:_cWhere03%
			AND E1.%NotDel%
			%Exp:_cWhere01% 
			AND F2.%NotDel%
			%Exp:_cWhere02%
			
			GROUP BY
			    E3.E3_FILIAL ,
			    E3.E3_VEND   ,  
				A3.A3_NOME   , 
			    A3.A3_I_DEDUC,
			    E3.E3_I_ORIGE,
			    Case
			        WHEN F2.F2_VEND2 = ' '          THEN 'A'
			        WHEN F2.F2_VEND1 <> F2.F2_VEND2 THEN 'B'
			        WHEN F2.F2_VEND3 <> ' '         THEN 'B'
			    END
		
			UNION ALL
			
			SELECT
			    E3.E3_FILIAL     AS FILIAL  ,
			    E3.E3_VEND       AS CODSUPERV	,
				A3.A3_NOME       AS NOMESUPERV,
			    A3.A3_I_DEDUC    AS DEDUCAO ,
			    E3.E3_I_ORIGE    AS ORIGEM  ,
			    SUM(E3.E3_COMIS) AS COMISSAO,
			    SUM(E3.E3_BASE)  AS VLRRECEB,
			    MIN( Case
			            WHEN F2.F2_VEND2 = ' '          THEN 'A'
			            WHEN F2.F2_VEND1 <> F2.F2_VEND2 THEN 'B'
			            WHEN F2.F2_VEND3 <> ' '         THEN 'B'
			    END ) AS TIPOVENDA
			FROM %Table:SE3% E3
			
			INNER JOIN %Table:SE1% E1
			ON  E1.E1_FILIAL  = E3.E3_FILIAL
			AND E1.E1_TIPO    = E3.E3_TIPO
			AND E1.E1_PREFIXO = E3.E3_PREFIXO
			AND E1.E1_NUM     = E3.E3_NUM
			AND E1.E1_SERIE   = E3.E3_SERIE
			AND E1.E1_PARCELA = E3.E3_PARCELA
			AND E1.E1_CLIENTE = E3.E3_CODCLI
			AND E1.E1_LOJA    = E3.E3_LOJA
			
			INNER JOIN %Table:SA3% A3
			ON  A3.A3_COD     = E3.E3_VEND
			
			INNER JOIN %Table:SF2% F2
			ON  F2.F2_FILIAL  = E1.E1_FILIAL
			AND F2.F2_DOC     = E1.E1_NUM
			AND (F2.F2_SERIE   = E1.E1_PREFIXO OR E1.E1_PREFIXO = 'R')
			AND F2.F2_CLIENTE = E1.E1_CLIENTE
			AND F2.F2_LOJA    = E1.E1_LOJA
			%Exp:_cWhere04%    
					
			WHERE
			    E3.%NotDel%
			AND E1.%NotDel%
			%Exp:_cWhere03%
			AND A3.%NotDel%
			%Exp:_cWhere02%
			AND F2.%NotDel% 
			%Exp:_cWhere01%
			AND E1.E1_ORIGEM = 'FINA460'
			AND EXISTS(	SELECT E5.E5_DATA FROM %Table:SE5% E5
			  				WHERE  E5.%NotDel%
			  						AND F2.F2_FILIAL  = E5.E5_FILIAL
			  						AND F2.F2_DOC     = E5.E5_NUMERO
			  						AND (F2.F2_SERIE   = E5.E5_PREFIXO OR E5.E5_PREFIXO = 'R')
			  						AND F2.F2_CLIENTE = E5.E5_CLIFOR
			  						AND F2.F2_LOJA    = E5.E5_LOJA
			  						AND E1.E1_NUMLIQ  = E5.E5_DOCUMEN
			  						AND E1.E1_FILIAL  = E5.E5_FILIAL
			  						AND E5.E5_SITUACA <> 'C'
				  					AND E5.E5_DOCUMEN <> ' ')
			  						
			%Exp:_cWhere02%
			
			GROUP BY
			    E3.E3_FILIAL ,
			    E3.E3_VEND   ,
				A3.A3_NOME   ,
			    A3.A3_I_DEDUC,
			    E3.E3_I_ORIGE,
			    Case
			        WHEN F2.F2_VEND2 = ' '          THEN 'A'
			        WHEN F2.F2_VEND1 <> F2.F2_VEND2 THEN 'B'
			        WHEN F2.F2_VEND3 <> ' '         THEN 'B'
			    END
			
			UNION ALL
			
			SELECT
			    E3.E3_FILIAL     AS FILIAL  ,
			    E3.E3_VEND       AS CODSUPERV	,
				A3.A3_NOME       AS NOMESUPERV,
			    A3.A3_I_DEDUC    AS DEDUCAO ,
			    E3.E3_I_ORIGE    AS ORIGEM  ,
			    SUM(E3.E3_COMIS) AS COMISSAO,
			    SUM(E3.E3_BASE)  AS VLRRECEB,
			    'D'              AS TIPOVENDA
			FROM %Table:SE3% E3
			
			INNER JOIN %Table:SA3% A3
			ON  E3.E3_VEND    = A3.A3_COD
			
			INNER JOIN %Table:SA1% A1
			ON  A1.A1_COD     = E3.E3_CODCLI
			AND A1.A1_LOJA    = E3.E3_LOJA
			
			WHERE
			    E3.%NotDel%
			AND A3.%NotDel%
			AND A1.%NotDel%
			%Exp:_cWhere03%
			AND E3.E3_TIPO   = 'NCC'
			%Exp:_cWhere01%
			AND E3.E3_NUM    IN (  SELECT D1.D1_DOC
			                       FROM %Table:SD1% D1 , %Table:SF2% F2
			                       WHERE
			                           D1.%NotDel%
			                       AND F2.%NotDel%
			                       AND E3.E3_FILIAL  = D1.D1_FILIAL // AND F2.F2_VEND1   = E3.E3_VEND    
			                       AND E3.E3_NUM     = D1.D1_DOC
			                       AND E3.E3_SERIE   = D1.D1_SERIE
			                       AND E3.E3_CODCLI  = D1.D1_FORNECE
			                       AND E3.E3_LOJA    = D1.D1_LOJA
			                       AND F2.F2_FILIAL  = D1.D1_FILIAL
			                       AND F2.F2_DOC     = D1.D1_NFORI
			                       AND F2.F2_SERIE   = D1.D1_SERIORI
			                       AND F2.F2_CLIENTE = D1.D1_FORNECE
			                       AND F2.F2_LOJA    = D1.D1_LOJA  
								   %Exp:_cWhere04%    
			                    ) // %Exp:_cWhere02%			
			GROUP BY
			    E3.E3_FILIAL ,
			    E3.E3_VEND   ,
				A3.A3_NOME   ,
			    A3.A3_I_DEDUC,
			    E3.E3_I_ORIGE,
			    'D'
			
			UNION ALL
			
			SELECT
			    E3.E3_FILIAL     AS FILIAL  ,
			    E3.E3_VEND       AS CODSUPERV	,
				A3.A3_NOME       AS NOMESUPERV,
			    A3.A3_I_DEDUC    AS DEDUCAO ,
			    E3.E3_I_ORIGE    AS ORIGEM  ,
			    SUM(E3.E3_COMIS) AS COMISSAO,
			    SUM(E3.E3_BASE)  AS VLRRECEB,
			    'D'              AS TIPOVENDA
			FROM %Table:SE3% E3
			
			JOIN %Table:SA3% A3
			ON
			    E3.E3_VEND    = A3.A3_COD
			
			JOIN %Table:SA1% A1
			ON
			    A1.A1_COD     = E3.E3_CODCLI
			AND A1.A1_LOJA    = E3.E3_LOJA
			
			WHERE
			    E3.%NotDel%
			AND A3.%NotDel%
			%Exp:_cWhere03%
			AND A1.%NotDel%
			%Exp:_cWhere01%
			AND E3.E3_TIPO   = 'NCC'
			AND A3.A3_SUPER  = ' '
			
			AND E3.E3_NUM    NOT IN (  SELECT D1.D1_DOC
			                           FROM %Table:SD1% D1, %Table:SF2% F2
			                           WHERE
			                               D1.D_E_L_E_T_ = ' '
			                           AND F2.D_E_L_E_T_ = ' '
			                           AND E3.E3_FILIAL  = D1.D1_FILIAL
			                           AND E3.E3_NUM     = D1.D1_DOC
			                           AND E3.E3_SERIE   = D1.D1_SERIE
			                           AND E3.E3_CODCLI  = D1.D1_FORNECE
			                           AND E3.E3_LOJA    = D1.D1_LOJA
			                           AND F2.F2_FILIAL  = D1.D1_FILIAL
			                           AND F2.F2_DOC     = D1.D1_NFORI
			                           AND F2.F2_SERIE   = D1.D1_SERIORI
			                           AND F2.F2_CLIENTE = D1.D1_FORNECE
			                           AND F2.F2_LOJA    = D1.D1_LOJA ) // %Exp:_cWhere02%			
			GROUP BY E3.E3_FILIAL , 
			         E3.E3_VEND , 
					 A3.A3_NOME ,
			         A3.A3_I_DEDUC , 
			         E3.E3_I_ORIGE , 'D'
			ORDER BY FILIAL , CODSUPERV , TIPOVENDA

		EndSql
    //================================================================================
	// Seleciona dados para o relatorio do tipo analitico, para as comissoes de
	// credito e debito dos Gerentes.
	//================================================================================
	Case _nOpcao == 4

		BeginSql alias _cAlias

			SELECT                                   
			    E3.E3_FILIAL     AS FILIAL  ,
			    E3.E3_VEND       AS CODGEREN	,
				A3.A3_NOME       AS NOMEGEREN, 
			    A3.A3_I_DEDUC    AS DEDUCAO ,
			    E3.E3_I_ORIGE    AS ORIGEM  ,
			    SUM(E3.E3_COMIS) AS COMISSAO,
			    SUM(E3.E3_BASE)  AS VLRRECEB,
			    Case
			        WHEN F2.F2_VEND2 = ' '          THEN 'A'
			        WHEN F2.F2_VEND1 <> F2.F2_VEND2 THEN 'B'
			        WHEN F2.F2_VEND3 <> ' '         THEN 'B'
			    END AS TIPOVENDA
			    
			FROM %Table:SE3% E3
			
			JOIN %Table:SA3% A3
			ON
			    A3.A3_COD = E3.E3_VEND
			
			JOIN %Table:SE1% E1
			ON
			    E1_FILIAL  = E3_FILIAL
			AND E1_NUM     = E3_NUM
			AND E1_PREFIXO = E3_PREFIXO
			AND E1_PARCELA = E3_PARCELA
			AND E1_TIPO    = E3_TIPO
			AND E1_CLIENTE = E3_CODCLI
			AND E1_LOJA    = E3_LOJA
			
			JOIN %Table:SF2% F2
			ON
			    F2.F2_FILIAL  = E1.E1_FILIAL
			AND F2.F2_DOC     = E1.E1_NUM
			AND (F2.F2_SERIE   = E1.E1_PREFIXO)
			AND F2.F2_CLIENTE = E1.E1_CLIENTE
			AND F2.F2_LOJA    = E1.E1_LOJA
			%Exp:_cWhere04%    
			WHERE
			    E3.%NotDel%
			AND A3.%NotDel%
			%Exp:_cWhere03%
			AND E1.%NotDel%
			%Exp:_cWhere01% 
			AND F2.%NotDel%
			%Exp:_cWhere02%
			
			GROUP BY
			    E3.E3_FILIAL ,
			    E3.E3_VEND   ,  
				A3.A3_NOME   , 
			    A3.A3_I_DEDUC,
			    E3.E3_I_ORIGE,
			    Case
			        WHEN F2.F2_VEND2 = ' '          THEN 'A'
			        WHEN F2.F2_VEND1 <> F2.F2_VEND2 THEN 'B'
			        WHEN F2.F2_VEND3 <> ' '         THEN 'B'
			    END
		
			UNION ALL
			
			SELECT
			    E3.E3_FILIAL     AS FILIAL  ,
			    E3.E3_VEND       AS CODGEREN	,
				A3.A3_NOME       AS NOMEGEREN,
			    A3.A3_I_DEDUC    AS DEDUCAO ,
			    E3.E3_I_ORIGE    AS ORIGEM  ,
			    SUM(E3.E3_COMIS) AS COMISSAO,
			    SUM(E3.E3_BASE)  AS VLRRECEB,
			    MIN( Case
			            WHEN F2.F2_VEND2 = ' '          THEN 'A'
			            WHEN F2.F2_VEND1 <> F2.F2_VEND2 THEN 'B'
			            WHEN F2.F2_VEND3 <> ' '         THEN 'B'
			    END ) AS TIPOVENDA
			FROM %Table:SE3% E3
			
			INNER JOIN %Table:SE1% E1
			ON  E1.E1_FILIAL  = E3.E3_FILIAL
			AND E1.E1_TIPO    = E3.E3_TIPO
			AND E1.E1_PREFIXO = E3.E3_PREFIXO
			AND E1.E1_NUM     = E3.E3_NUM
			AND E1.E1_SERIE   = E3.E3_SERIE
			AND E1.E1_PARCELA = E3.E3_PARCELA
			AND E1.E1_CLIENTE = E3.E3_CODCLI
			AND E1.E1_LOJA    = E3.E3_LOJA
			
			INNER JOIN %Table:SA3% A3
			ON  A3.A3_COD     = E3.E3_VEND
			
			INNER JOIN %Table:SF2% F2
			ON  F2.F2_FILIAL  = E1.E1_FILIAL
			AND F2.F2_DOC     = E1.E1_NUM
			AND (F2.F2_SERIE   = E1.E1_PREFIXO OR E1.E1_PREFIXO = 'R')
			AND F2.F2_CLIENTE = E1.E1_CLIENTE
			AND F2.F2_LOJA    = E1.E1_LOJA
			%Exp:_cWhere04%    
					
			WHERE
			    E3.%NotDel%
			AND E1.%NotDel%
			%Exp:_cWhere03%
			AND A3.%NotDel%
			%Exp:_cWhere02%
			AND F2.%NotDel% 
			%Exp:_cWhere01%
			AND E1.E1_ORIGEM = 'FINA460'
			AND EXISTS(	SELECT E5.E5_DATA FROM %Table:SE5% E5
			  				WHERE  E5.%NotDel%
			  						AND F2.F2_FILIAL  = E5.E5_FILIAL
			  						AND F2.F2_DOC     = E5.E5_NUMERO
			  						AND (F2.F2_SERIE   = E5.E5_PREFIXO OR E5.E5_PREFIXO = 'R')
			  						AND F2.F2_CLIENTE = E5.E5_CLIFOR
			  						AND F2.F2_LOJA    = E5.E5_LOJA
			  						AND E1.E1_NUMLIQ  = E5.E5_DOCUMEN
			  						AND E1.E1_FILIAL  = E5.E5_FILIAL
			  						AND E5.E5_SITUACA <> 'C'
				  					AND E5.E5_DOCUMEN <> ' ')
			  						
			%Exp:_cWhere02%
			
			GROUP BY
			    E3.E3_FILIAL ,
			    E3.E3_VEND   ,
				A3.A3_NOME   ,
			    A3.A3_I_DEDUC,
			    E3.E3_I_ORIGE,
			    Case
			        WHEN F2.F2_VEND2 = ' '          THEN 'A'
			        WHEN F2.F2_VEND1 <> F2.F2_VEND2 THEN 'B'
			        WHEN F2.F2_VEND3 <> ' '         THEN 'B'
			    END
			
			UNION ALL
			
			SELECT
			    E3.E3_FILIAL     AS FILIAL  ,
			    E3.E3_VEND       AS CODGEREN	,
				A3.A3_NOME       AS NOMEGEREN,
			    A3.A3_I_DEDUC    AS DEDUCAO ,
			    E3.E3_I_ORIGE    AS ORIGEM  ,
			    SUM(E3.E3_COMIS) AS COMISSAO,
			    SUM(E3.E3_BASE)  AS VLRRECEB,
			    'D'              AS TIPOVENDA
			FROM %Table:SE3% E3
			
			INNER JOIN %Table:SA3% A3
			ON  E3.E3_VEND    = A3.A3_COD
			
			INNER JOIN %Table:SA1% A1
			ON  A1.A1_COD     = E3.E3_CODCLI
			AND A1.A1_LOJA    = E3.E3_LOJA
			
			WHERE
			    E3.%NotDel%
			AND A3.%NotDel%
			AND A1.%NotDel%
			%Exp:_cWhere03%
			AND E3.E3_TIPO   = 'NCC'
			%Exp:_cWhere01%
			AND E3.E3_NUM    IN (  SELECT D1.D1_DOC
			                       FROM %Table:SD1% D1 , %Table:SF2% F2
			                       WHERE
			                           D1.%NotDel%
			                       AND F2.%NotDel%
			                       AND E3.E3_FILIAL  = D1.D1_FILIAL // AND F2.F2_VEND1   = E3.E3_VEND    
			                       AND E3.E3_NUM     = D1.D1_DOC
			                       AND E3.E3_SERIE   = D1.D1_SERIE
			                       AND E3.E3_CODCLI  = D1.D1_FORNECE
			                       AND E3.E3_LOJA    = D1.D1_LOJA
			                       AND F2.F2_FILIAL  = D1.D1_FILIAL
			                       AND F2.F2_DOC     = D1.D1_NFORI
			                       AND F2.F2_SERIE   = D1.D1_SERIORI
			                       AND F2.F2_CLIENTE = D1.D1_FORNECE
			                       AND F2.F2_LOJA    = D1.D1_LOJA  
								   %Exp:_cWhere04%    
			                    ) // %Exp:_cWhere02%			
			GROUP BY
			    E3.E3_FILIAL ,
			    E3.E3_VEND   ,
				A3.A3_NOME   ,
			    A3.A3_I_DEDUC,
			    E3.E3_I_ORIGE,
			    'D'
			
			UNION ALL
			
			SELECT
			    E3.E3_FILIAL     AS FILIAL  ,
			    E3.E3_VEND       AS CODGEREN	,
				A3.A3_NOME       AS NOMEGEREN,
			    A3.A3_I_DEDUC    AS DEDUCAO ,
			    E3.E3_I_ORIGE    AS ORIGEM  ,
			    SUM(E3.E3_COMIS) AS COMISSAO,
			    SUM(E3.E3_BASE)  AS VLRRECEB,
			    'D'              AS TIPOVENDA
			FROM %Table:SE3% E3
			
			JOIN %Table:SA3% A3
			ON
			    E3.E3_VEND    = A3.A3_COD
			
			JOIN %Table:SA1% A1
			ON
			    A1.A1_COD     = E3.E3_CODCLI
			AND A1.A1_LOJA    = E3.E3_LOJA
			
			WHERE
			    E3.%NotDel%
			AND A3.%NotDel%
			%Exp:_cWhere03%
			AND A1.%NotDel%
			%Exp:_cWhere01%
			AND E3.E3_TIPO   = 'NCC'
			AND A3.A3_SUPER  = ' '
			
			AND E3.E3_NUM    NOT IN (  SELECT D1.D1_DOC
			                           FROM %Table:SD1% D1, %Table:SF2% F2
			                           WHERE
			                               D1.D_E_L_E_T_ = ' '
			                           AND F2.D_E_L_E_T_ = ' '
			                           AND E3.E3_FILIAL  = D1.D1_FILIAL
			                           AND E3.E3_NUM     = D1.D1_DOC
			                           AND E3.E3_SERIE   = D1.D1_SERIE
			                           AND E3.E3_CODCLI  = D1.D1_FORNECE
			                           AND E3.E3_LOJA    = D1.D1_LOJA
			                           AND F2.F2_FILIAL  = D1.D1_FILIAL
			                           AND F2.F2_DOC     = D1.D1_NFORI
			                           AND F2.F2_SERIE   = D1.D1_SERIORI
			                           AND F2.F2_CLIENTE = D1.D1_FORNECE
			                           AND F2.F2_LOJA    = D1.D1_LOJA ) // %Exp:_cWhere02%			
			GROUP BY E3.E3_FILIAL , 
			         E3.E3_VEND , 
					 A3.A3_NOME ,
			         A3.A3_I_DEDUC , 
			         E3.E3_I_ORIGE , 'D'
			ORDER BY FILIAL , CODGEREN , TIPOVENDA

		EndSql

    //================================================================================
	// Seleciona dados para o relatorio do tipo analitico, para as comissoes de
	// credito e debito dos coordenadores.
	//================================================================================
	Case _nOpcao == 5

		BeginSql alias _cAlias

			SELECT                                   
			    E3.E3_FILIAL     AS FILIAL  ,
			    E3.E3_VEND       AS CODGERNAC	,
				A3.A3_NOME       AS NOMEGERNAC, 
			    A3.A3_I_DEDUC    AS DEDUCAO ,
			    E3.E3_I_ORIGE    AS ORIGEM  ,
			    SUM(E3.E3_COMIS) AS COMISSAO,
			    SUM(E3.E3_BASE)  AS VLRRECEB,
			    Case
			        WHEN F2.F2_VEND2 = ' '          THEN 'A'
			        WHEN F2.F2_VEND1 <> F2.F2_VEND2 THEN 'B'
			        WHEN F2.F2_VEND3 <> ' '         THEN 'B'
			    END AS TIPOVENDA
			    
			FROM %Table:SE3% E3
			
			JOIN %Table:SA3% A3
			ON
			    A3.A3_COD = E3.E3_VEND
			
			JOIN %Table:SE1% E1
			ON
			    E1_FILIAL  = E3_FILIAL
			AND E1_NUM     = E3_NUM
			AND E1_PREFIXO = E3_PREFIXO
			AND E1_PARCELA = E3_PARCELA
			AND E1_TIPO    = E3_TIPO
			AND E1_CLIENTE = E3_CODCLI
			AND E1_LOJA    = E3_LOJA
			
			JOIN %Table:SF2% F2
			ON
			    F2.F2_FILIAL  = E1.E1_FILIAL
			AND F2.F2_DOC     = E1.E1_NUM
			AND (F2.F2_SERIE   = E1.E1_PREFIXO)
			AND F2.F2_CLIENTE = E1.E1_CLIENTE
			AND F2.F2_LOJA    = E1.E1_LOJA
			%Exp:_cWhere04%    
			WHERE
			    E3.%NotDel%
			AND A3.%NotDel%
			%Exp:_cWhere03%
			AND E1.%NotDel%
			%Exp:_cWhere01% 
			AND F2.%NotDel%
			%Exp:_cWhere02%
			
			GROUP BY
			    E3.E3_FILIAL ,
			    E3.E3_VEND   ,  
				A3.A3_NOME   , 
			    A3.A3_I_DEDUC,
			    E3.E3_I_ORIGE,
			    Case
			        WHEN F2.F2_VEND2 = ' '          THEN 'A'
			        WHEN F2.F2_VEND1 <> F2.F2_VEND2 THEN 'B'
			        WHEN F2.F2_VEND3 <> ' '         THEN 'B'
			    END
		
			UNION ALL
			
			SELECT
			    E3.E3_FILIAL     AS FILIAL  ,
			    E3.E3_VEND       AS CODGERNAC	,
				A3.A3_NOME       AS NOMEGERNAC,
			    A3.A3_I_DEDUC    AS DEDUCAO ,
			    E3.E3_I_ORIGE    AS ORIGEM  ,
			    SUM(E3.E3_COMIS) AS COMISSAO,
			    SUM(E3.E3_BASE)  AS VLRRECEB,
			    MIN( Case
			            WHEN F2.F2_VEND2 = ' '          THEN 'A'
			            WHEN F2.F2_VEND1 <> F2.F2_VEND2 THEN 'B'
			            WHEN F2.F2_VEND3 <> ' '         THEN 'B'
			    END ) AS TIPOVENDA
			FROM %Table:SE3% E3
			
			INNER JOIN %Table:SE1% E1
			ON  E1.E1_FILIAL  = E3.E3_FILIAL
			AND E1.E1_TIPO    = E3.E3_TIPO
			AND E1.E1_PREFIXO = E3.E3_PREFIXO
			AND E1.E1_NUM     = E3.E3_NUM
			AND E1.E1_SERIE   = E3.E3_SERIE
			AND E1.E1_PARCELA = E3.E3_PARCELA
			AND E1.E1_CLIENTE = E3.E3_CODCLI
			AND E1.E1_LOJA    = E3.E3_LOJA
			
			INNER JOIN %Table:SA3% A3
			ON  A3.A3_COD     = E3.E3_VEND
			
			INNER JOIN %Table:SF2% F2
			ON  F2.F2_FILIAL  = E1.E1_FILIAL
			AND F2.F2_DOC     = E1.E1_NUM
			AND (F2.F2_SERIE   = E1.E1_PREFIXO OR E1.E1_PREFIXO = 'R')
			AND F2.F2_CLIENTE = E1.E1_CLIENTE
			AND F2.F2_LOJA    = E1.E1_LOJA
			%Exp:_cWhere04%    
					
			WHERE
			    E3.%NotDel%
			AND E1.%NotDel%
			%Exp:_cWhere03%
			AND A3.%NotDel%
			%Exp:_cWhere02%
			AND F2.%NotDel% 
			%Exp:_cWhere01%
			AND E1.E1_ORIGEM = 'FINA460'
			AND EXISTS(	SELECT E5.E5_DATA FROM %Table:SE5% E5
			  				WHERE  E5.%NotDel%
			  						AND F2.F2_FILIAL  = E5.E5_FILIAL
			  						AND F2.F2_DOC     = E5.E5_NUMERO
			  						AND (F2.F2_SERIE   = E5.E5_PREFIXO OR E5.E5_PREFIXO = 'R')
			  						AND F2.F2_CLIENTE = E5.E5_CLIFOR
			  						AND F2.F2_LOJA    = E5.E5_LOJA
			  						AND E1.E1_NUMLIQ  = E5.E5_DOCUMEN
			  						AND E1.E1_FILIAL  = E5.E5_FILIAL
			  						AND E5.E5_SITUACA <> 'C'
				  					AND E5.E5_DOCUMEN <> ' ')
			  						
			%Exp:_cWhere02%
			
			GROUP BY
			    E3.E3_FILIAL ,
			    E3.E3_VEND   ,
				A3.A3_NOME   ,
			    A3.A3_I_DEDUC,
			    E3.E3_I_ORIGE,
			    Case
			        WHEN F2.F2_VEND2 = ' '          THEN 'A'
			        WHEN F2.F2_VEND1 <> F2.F2_VEND2 THEN 'B'
			        WHEN F2.F2_VEND3 <> ' '         THEN 'B'
			    END
			
			UNION ALL
			
			SELECT
			    E3.E3_FILIAL     AS FILIAL  ,
			    E3.E3_VEND       AS CODGERNAC	,
				A3.A3_NOME       AS NOMEGERNAC,
			    A3.A3_I_DEDUC    AS DEDUCAO ,
			    E3.E3_I_ORIGE    AS ORIGEM  ,
			    SUM(E3.E3_COMIS) AS COMISSAO,
			    SUM(E3.E3_BASE)  AS VLRRECEB,
			    'D'              AS TIPOVENDA
			FROM %Table:SE3% E3
			
			INNER JOIN %Table:SA3% A3
			ON  E3.E3_VEND    = A3.A3_COD
			
			INNER JOIN %Table:SA1% A1
			ON  A1.A1_COD     = E3.E3_CODCLI
			AND A1.A1_LOJA    = E3.E3_LOJA
			
			WHERE
			    E3.%NotDel%
			AND A3.%NotDel%
			AND A1.%NotDel%
			%Exp:_cWhere03%
			AND E3.E3_TIPO   = 'NCC'
			%Exp:_cWhere01%
			AND E3.E3_NUM    IN (  SELECT D1.D1_DOC
			                       FROM %Table:SD1% D1 , %Table:SF2% F2
			                       WHERE
			                           D1.%NotDel%
			                       AND F2.%NotDel%
			                       AND E3.E3_FILIAL  = D1.D1_FILIAL // AND F2.F2_VEND1   = E3.E3_VEND    
			                       AND E3.E3_NUM     = D1.D1_DOC
			                       AND E3.E3_SERIE   = D1.D1_SERIE
			                       AND E3.E3_CODCLI  = D1.D1_FORNECE
			                       AND E3.E3_LOJA    = D1.D1_LOJA
			                       AND F2.F2_FILIAL  = D1.D1_FILIAL
			                       AND F2.F2_DOC     = D1.D1_NFORI
			                       AND F2.F2_SERIE   = D1.D1_SERIORI
			                       AND F2.F2_CLIENTE = D1.D1_FORNECE
			                       AND F2.F2_LOJA    = D1.D1_LOJA  
								   %Exp:_cWhere04%    
			                    ) // %Exp:_cWhere02%			
			GROUP BY
			    E3.E3_FILIAL ,
			    E3.E3_VEND   ,
				A3.A3_NOME   ,
			    A3.A3_I_DEDUC,
			    E3.E3_I_ORIGE,
			    'D'
			
			UNION ALL
			
			SELECT
			    E3.E3_FILIAL     AS FILIAL  ,
			    E3.E3_VEND       AS CODGERNAC	,
				A3.A3_NOME       AS NOMEGERNAC,
			    A3.A3_I_DEDUC    AS DEDUCAO ,
			    E3.E3_I_ORIGE    AS ORIGEM  ,
			    SUM(E3.E3_COMIS) AS COMISSAO,
			    SUM(E3.E3_BASE)  AS VLRRECEB,
			    'D'              AS TIPOVENDA
			FROM %Table:SE3% E3
			
			JOIN %Table:SA3% A3
			ON
			    E3.E3_VEND    = A3.A3_COD
			
			JOIN %Table:SA1% A1
			ON
			    A1.A1_COD     = E3.E3_CODCLI
			AND A1.A1_LOJA    = E3.E3_LOJA
			
			WHERE
			    E3.%NotDel%
			AND A3.%NotDel%
			%Exp:_cWhere03%
			AND A1.%NotDel%
			%Exp:_cWhere01%
			AND E3.E3_TIPO   = 'NCC'
			AND A3.A3_SUPER  = ' '
			
			AND E3.E3_NUM    NOT IN (  SELECT D1.D1_DOC
			                           FROM %Table:SD1% D1, %Table:SF2% F2
			                           WHERE
			                               D1.D_E_L_E_T_ = ' '
			                           AND F2.D_E_L_E_T_ = ' '
			                           AND E3.E3_FILIAL  = D1.D1_FILIAL
			                           AND E3.E3_NUM     = D1.D1_DOC
			                           AND E3.E3_SERIE   = D1.D1_SERIE
			                           AND E3.E3_CODCLI  = D1.D1_FORNECE
			                           AND E3.E3_LOJA    = D1.D1_LOJA
			                           AND F2.F2_FILIAL  = D1.D1_FILIAL
			                           AND F2.F2_DOC     = D1.D1_NFORI
			                           AND F2.F2_SERIE   = D1.D1_SERIORI
			                           AND F2.F2_CLIENTE = D1.D1_FORNECE
			                           AND F2.F2_LOJA    = D1.D1_LOJA ) // %Exp:_cWhere02%			
			GROUP BY E3.E3_FILIAL , 
			         E3.E3_VEND , 
					 A3.A3_NOME ,
			         A3.A3_I_DEDUC , 
			         E3.E3_I_ORIGE , 'D'
			ORDER BY FILIAL , CODGERNAC , TIPOVENDA

		EndSql
EndCase

Return

/*
===============================================================================================================================
Programa--------: ROMS030TRUN // ROMS029RUN
Autor-----------: Fabiano Dias
Data da Criacao-: 30/03/2011
Descrição-------: Função que Processa a impressão dos dados do relatório
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/ 

Static Function ROMS030TRUN() 

Local _cAlias    := GetNextAlias() 
Local _cAliasVend:= GetNextAlias() 
Local _aVendedor:= {}
Local _aCoordena:= {}
Local _aSupervis:= {}
Local _aGerente := {}
Local _aGerNaci := {}

Local _aValALM	:= {}  

Local _aImpostos:= {} 

Local _nPosicao := 0   

//=========================================================================
// Variaveis de controle dos totalizadores dos vendedores.
//=========================================================================
Local _nTotVComi:= 0
Local _nTotVINSS:= 0
Local _nTotVIRRF:= 0
Local _nTotVBase:= 0
Local _nTotVBoni:= 0

//=========================================================================
// Variaveis de controle dos totalizadores dos coordenadores.
//=========================================================================
Local _nTotCComi:= 0
Local _nTotCINSS:= 0
Local _nTotCIRRF:= 0
Local _nTotCBase:= 0
Local _nTotCBoni:= 0

//=========================================================================
// Variaveis de controle dos totalizadores dos Supervisores
//=========================================================================
Local _nTotSComi:= 0
Local _nTotSINSS:= 0
Local _nTotSIRRF:= 0
Local _nTotSBase:= 0
Local _nTotSBoni:= 0
              
//=========================================================================
// Variaveis de controle dos totalizadores dos Gerentes
//=========================================================================
Local _nTotGComi:= 0
Local _nTotGINSS:= 0
Local _nTotGIRRF:= 0
Local _nTotGBase:= 0
Local _nTotGBoni:= 0

//=========================================================================
// Variaveis de controle dos totalizadores dos Gerente Nacional
//=========================================================================
Local _nTotNComi:= 0
Local _nTotNINSS:= 0
Local _nTotNIRRF:= 0
Local _nTotNBase:= 0
Local _nTotNBoni:= 0

//=========================================================================
// Variaveis de controle do total geral.
//=========================================================================
Local _nVlrComis:= 0
Local _nINSS	:= 0
Local _nIRRF    := 0   
Local _nVlrBase := 0
Local _nVlrBoni	:= 0

Local _nValBnf  := 0 , x

If Empty(MV_PAR01) .Or. Empty(MV_PAR02)
	MsgInfo("Favor preencher os parâmetros: Mes/Ano Inicial e Mes/Ano Final antes de imprimir este relatório.")
	Return
EndIf
      
	//=================================================================================================
	// Chama a rotina para selecao dos registros da comissao gerada para os vendedores				
	//=================================================================================================
	MsgRun("Aguarde....Filrando comissao dos vendedores.",,{||CursorWait(),ROMS030TQRY(_cAlias,1),CursorArrow()})  // ROMS029QRY      
	
	DBSelectArea(_cAlias)
	(_cAlias)->(DBGoTop())        
	             	
	//=========================================================================
	// Armazena o numero de registros encontrados. 
	//=========================================================================
	COUNT TO _nCountRec 
	
	ProcRegua(_nCountRec)
	
	DBSelectArea(_cAlias)
	(_cAlias)->( DBGoTop() )
	
	//=========================================================================
	// Efetua o grupamento dos dados dos vendedores. 
	//=========================================================================
	While (_cAlias)->( !Eof() )
	
		IncProc("Processando dados das comissoes do vendedor, favor aguardar...")
		
		_nPosicao := aScan( _aVendedor , {|k| k[1] == (_cAlias)->CODVEND } )
		
		If _nPosicao == 0
		
			aAdd( _aVendedor , {	(_cAlias)->CODVEND		,;
									(_cAlias)->NOMEVEND		,;
									(_cAlias)->DEDUCAO		,;
									(_cAlias)->COMISSAO		,;
									(_cAlias)->VLRRECEB		})
			
		Else
		
			_aVendedor[_nPosicao,4] += (_cAlias)->COMISSAO
			_aVendedor[_nPosicao,5] += (_cAlias)->VLRRECEB
		
		EndIf
		
	(_cAlias)->( DBSkip() )
    EndDo

DBSelectArea(_cAlias)
(_cAlias)->( DBCloseArea() )

//=========================================================================
// Imprime os dados das comissoes dos vendedores.
//=========================================================================
If Len(_aVendedor) > 0                                                                       	

	//=========================================================================
	// Ordena os dados por descricao dos vendedores.
	//=========================================================================
	aSort( _aVendedor ,,, {|x, y| x[2] < y[2] } )

	//=========================================================================================
	// Imprime o cabecalho da primeira pagina, forca a quebra de pagina para esta impressao 
	//=========================================================================================
    _oPrint:EndPage()					// Finaliza a Pagina.
	_oPrint:StartPage()					// Inicia uma nova Pagina
	
	_nPagina++
	ROMS030TCAB( .T. )//Chama cabecalho // ROMS029CAB   
    
    ROMS030TPPG('Representantes') // ROMS029PPG

	For x := 1 To Len( _aVendedor )
	
		_nLinha += _nSpcLin
		_oPrint:Line(_nLinha,_nColIni,_nLinha,_nColFim)
		
		ROMS030TQPG(0,.T.,.T.,"ROMS030TBOX()","ROMS030TCDR('Representantes')") // ROMS029QPG // ROMS029CDR
	  	
		_aValALM		:= ROMS30TCAD( _aVendedor[x,1] ) // ROMS029RUN()
	  	
		IIf( _aValALM[04] > 0 , _aVendedor[x,4] += _aValALM[04] , Nil )
	  	
		_aImpostos	:= U_C_IRRF_INSS(_aVendedor[x,3],_aVendedor[x,4])
		_nValBnf	:= ROMS030TCBN( _aVendedor[x,1] ) // ROMS029CBN
	  	
		ROMS030TPRD( _aVendedor[x,2] , _aVendedor[x,4] , _aImpostos[1,1] , _aImpostos[1,2] , _aVendedor[x,5] , _nValBnf ) // ROMS029PRD
		
		//=========================================================================
		// Seta variaveis de controle dos totalizadores.
		//=========================================================================
		_nTotVComi += _aVendedor[x,4] // (_aVendedor[x,4] - _nValBnf) 
		_nTotVINSS += _aImpostos[1,1]
		_nTotVIRRF += _aImpostos[1,2]
		_nTotVBase += _aVendedor[x,5]
		_nTotVBoni += _nValBnf
	
	Next x
	
	_nLinha += _nSpcLin
	
	_oPrint:Line( _nLinha , _nColIni , _nLinha , _nColFim )  
	
	ROMS030TQPG( 0 , .T. , .T. , "ROMS030TBOX()" , "ROMS030TCDR('Representantes')" ) // ROMS029QPG // ROMS029BOX // ROMS029CDR
		
	//=========================================================================
	// Imprime o totalizador dos vendedores.
	//=========================================================================
	ROMS030TTOT( 'Total' , _nTotVComi , _nTotVINSS , _nTotVIRRF , _nTotVBase , _nTotVBoni ) // ROMS029TOT
	
	_nLinha+=_nSpcLin
	ROMS030TBOX() // ROMS029BOX  

EndIf            


	//========================================================================================
	// Chama a rotina para selecao dos registros da comissao gerada para os vendedores						
	//========================================================================================
	MsgRun("Aguarde....Filrando comissão dos coordenadores.",,{||CursorWait(),ROMS030TQRY(_cAliasVend,2),CursorArrow()})  // ROMS029QRY      
	
	DBSelectArea(_cAliasVend)
	(_cAliasVend)->(DBGoTop())        
	             	
	//=========================================================================
	// Armazena o numero de registros encontrados.
	//=========================================================================
	
	COUNT TO _nCountRec 
	
	ProcRegua(_nCountRec)
	
	DBSelectArea(_cAliasVend)
	(_cAliasVend)->(DBGoTop())       
	               	
	//=========================================================================
	// Efetua o grupamento dos dados dos vendedores.
	//=========================================================================
	While (_cAliasVend)->(!Eof()) 
		
			IncProc("Processando dados das comissoes do coordenador, favor aguardar...")
			
			_nPosicao:= aScan(_aCoordena,{|k| k[1] == (_cAliasVend)->CODCOORD})  
			
			If _nPosicao == 0
			      
				aAdd(_aCoordena,{(_cAliasVend)->CODCOORD,(_cAliasVend)->NOMECOORD,(_cAliasVend)->DEDUCAO,(_cAliasVend)->COMISSAO,(_cAliasVend)->VLRRECEB})
				
					Else
					
						_aCoordena[_nPosicao,4] += (_cAliasVend)->COMISSAO 
						_aCoordena[_nPosicao,5] += (_cAliasVend)->VLRRECEB
			
			EndIf 
					
	(_cAliasVend)->(DBSkip())	
    EndDo                          

DBSelectArea(_cAliasVend)
(_cAliasVend)->(DBCloseArea())     

//=========================================================================
// Verifica a necessidade de quebra de pagina.
//=========================================================================

_nLinha+=_nSpcLin	

ROMS030TQPG(0,.F.,.F.,"","") // ROMS029QPG   

//=========================================================================
// Imprime os dados das comissoes dos vendedores.
//=========================================================================

If Len(_aCoordena) > 0  

	//=========================================================================
	// Ordena os dados por descricao dos vendedores.
	//=========================================================================
	aSort(_aCoordena,,,{|x, y| x[2] < y[2]})
    //=======================================================================================
    // Imprime o cabecalho da primeira pagina, forca a quebra de pagina para esta impressao 
    //=======================================================================================
    
    ROMS030TPPG('Coordenadores') // ROMS029PPG

	For x:=1 to Len(_aCoordena)
	   	  			   	  
		_nLinha += _nSpcLin
		_oPrint:Line( _nLinha , _nColIni , _nLinha , _nColFim )
		
		ROMS030TQPG(0,.T.,.T.,"ROMS030TBOX()","ROMS030TCDR('Coordenadores')")   // ROMS029QPG // ROMS029BOX // ROMS029CDR
		
		_aValALM	:= ROMS30TCAD( _aCoordena[x,1] ) // ROMS029CAD
		
		IIf( _aValALM[04] > 0 , _aCoordena[x,4] += _aValALM[04] , Nil )
		
		_aImpostos	:= U_C_IRRF_INSS( _aCoordena[x,3] , _aCoordena[x,4] )
		_nValBnf	:= ROMS030TBNF( _aCoordena[x,1] ) // ROMS029BNF
	  	
		ROMS030TPRD( _aCoordena[x,2] , _aCoordena[x,4] , _aImpostos[1,1] , _aImpostos[1,2] , _aCoordena[x,5] , _nValBnf ) // ROMS029PRD
	  	
		//=========================================================================
		// Seta variaveis de controle dos totalizadores.
		//=========================================================================
		_nTotCComi += _aCoordena[x,4] // (_aCoordena[x,4] - _nValBnf) 
		_nTotCINSS += _aImpostos[1,1]
		_nTotCIRRF += _aImpostos[1,2]
		_nTotCBase += _aCoordena[x,5]
		_nTotCBoni += _nValBnf
	
	Next x
	
	_nLinha+=_nSpcLin	     
	_oPrint:Line(_nLinha,_nColIni,_nLinha,_nColFim)  
	  
	ROMS030TQPG(0,.T.,.T.,"ROMS030TBOX()","ROMS030TCDR('Coordenadores')")   // ROMS029QPG  // ROMS029BOX // ROMS029CDR
		
	//=========================================================================
	// Imprime o totalizador dos vendedores.
	//=========================================================================
	ROMS030TTOT('Total',_nTotCComi,_nTotCINSS,_nTotCIRRF,_nTotCBase,_nTotCBoni) // ROMS029TOT
	
	_nLinha+=_nSpcLin
	ROMS030TBOX() // ROMS029BOX

EndIf

	//========================================================================================
	// Chama a rotina para selecao dos registros da comissao gerada para os vendedores						
	//========================================================================================
	MsgRun("Aguarde....Filrando comissão dos supervisores.",,{||CursorWait(),ROMS030TQRY(_cAliasVend,3),CursorArrow()}) 
	
	DBSelectArea(_cAliasVend)
	(_cAliasVend)->(DBGoTop())        
	             	
	//=========================================================================
	// Armazena o numero de registros encontrados.
	//=========================================================================
	
	COUNT TO _nCountRec 
	
	ProcRegua(_nCountRec)
	
	DBSelectArea(_cAliasVend)
	(_cAliasVend)->(DBGoTop())       
	               	
	//=========================================================================
	// Efetua o grupamento dos dados dos supervisores.
	//=========================================================================
	While (_cAliasVend)->(!Eof()) 
		
			IncProc("Processando dados das comissoes do supervisor, favor aguardar...")
			
			_nPosicao:= aScan(_aSupervis,{|k| k[1] == (_cAliasVend)->CODSUPERV})  
			
			If _nPosicao == 0
			      
			   aAdd(_aSupervis,{(_cAliasVend)->CODSUPERV,(_cAliasVend)->NOMESUPERV,(_cAliasVend)->DEDUCAO,(_cAliasVend)->COMISSAO,(_cAliasVend)->VLRRECEB})
				
			Else
					
				_aSupervis[_nPosicao,4] += (_cAliasVend)->COMISSAO 
				_aSupervis[_nPosicao,5] += (_cAliasVend)->VLRRECEB
			
			EndIf 
					
	   (_cAliasVend)->(DBSkip())	
    EndDo                          

DBSelectArea(_cAliasVend)
(_cAliasVend)->(DBCloseArea())     

//=========================================================================
// Verifica a necessidade de quebra de pagina.
//=========================================================================

_nLinha+=_nSpcLin	

ROMS030TQPG(0,.F.,.F.,"","")    

//=========================================================================
// Imprime os dados das comissoes dos supervisores.
//=========================================================================

If Len(_aSupervis) > 0  

	//=========================================================================
	// Ordena os dados por descricao dos supervisores.
	//=========================================================================
	aSort(_aSupervis,,,{|x, y| x[2] < y[2]})

    //=======================================================================================
    // Imprime o cabecalho da primeira pagina, forca a quebra de pagina para esta impressao 
    //=======================================================================================
    
    ROMS030TPPG('Supervisores') 

	For x:=1 to Len(_aSupervis)
	   	  			   	  
		_nLinha += _nSpcLin
		_oPrint:Line( _nLinha , _nColIni , _nLinha , _nColFim )
		
		ROMS030TQPG(0,.T.,.T.,"ROMS030TBOX()","ROMS030TCDR('Supervisores')")  
		
		_aValALM	:= ROMS30TCAD( _aSupervis[x,1] ) 
		
		IIf( _aValALM[04] > 0 , _aSupervis[x,4] += _aValALM[04] , Nil )
		
		_aImpostos	:= U_C_IRRF_INSS( _aSupervis[x,3] , _aSupervis[x,4] )
		_nValBnf	:= ROMS030TBNF( _aSupervis[x,1] ) 
	  	
		ROMS030TPRD( _aSupervis[x,2] , _aSupervis[x,4] , _aImpostos[1,1] , _aImpostos[1,2] , _aSupervis[x,5] , _nValBnf ) 
	  	
		//=========================================================================
		// Seta variaveis de controle dos totalizadores.
		//=========================================================================
		_nTotSComi += _aSupervis[x,4] // (_aSupervis[x,4] - _nValBnf) 
		_nTotSINSS += _aImpostos[1,1]
		_nTotSIRRF += _aImpostos[1,2]
		_nTotSBase += _aSupervis[x,5]
		_nTotSBoni += _nValBnf
	
	Next x
	
	_nLinha+=_nSpcLin	     
	_oPrint:Line(_nLinha,_nColIni,_nLinha,_nColFim)  
	  
	ROMS030TQPG(0,.T.,.T.,"ROMS030TBOX()","ROMS030TCDR('Coordenadores')")  
		
	//=========================================================================
	// Imprime o totalizador dos vendedores.
	//=========================================================================
	ROMS030TTOT('Total',_nTotSComi,_nTotSINSS,_nTotSIRRF,_nTotSBase,_nTotSBoni) 
	
	_nLinha+=_nSpcLin
	ROMS030TBOX() 

EndIf

	//========================================================================================
	// Chama a rotina para selecao dos registros da comissao gerada para os gerentes					
	//========================================================================================
	MsgRun("Aguarde....Filrando comissão dos gerentes.",,{||CursorWait(),ROMS030TQRY(_cAliasVend,4),CursorArrow()})  
	
	DBSelectArea(_cAliasVend)
	(_cAliasVend)->(DBGoTop())        
	             	
	//=========================================================================
	// Armazena o numero de registros encontrados.
	//=========================================================================
	
	COUNT TO _nCountRec 
	
	ProcRegua(_nCountRec)
	
	DBSelectArea(_cAliasVend)
	(_cAliasVend)->(DBGoTop())       
	               	
	//=========================================================================
	// Efetua o grupamento dos dados dos vendedores.
	//=========================================================================
	While (_cAliasVend)->(!Eof()) 
		
			IncProc("Processando dados das comissoes do gerente, favor aguardar...")
			
			_nPosicao:= aScan(_aGerente,{|k| k[1] == (_cAliasVend)->CODGEREN})  
			
			If _nPosicao == 0
			      
				aAdd(_aGerente,{(_cAliasVend)->CODGEREN,(_cAliasVend)->NOMEGEREN,(_cAliasVend)->DEDUCAO,(_cAliasVend)->COMISSAO,(_cAliasVend)->VLRRECEB})
				
					Else
					
						_aGerente[_nPosicao,4] += (_cAliasVend)->COMISSAO 
						_aGerente[_nPosicao,5] += (_cAliasVend)->VLRRECEB
			
			EndIf 
					
	(_cAliasVend)->(DBSkip())	
    EndDo                          

DBSelectArea(_cAliasVend)
(_cAliasVend)->(DBCloseArea())     

//=========================================================================
// Verifica a necessidade de quebra de pagina.
//=========================================================================

_nLinha+=_nSpcLin	

ROMS030TQPG(0,.F.,.F.,"","") 

//=========================================================================
// Imprime os dados das comissoes dos gerentes
//=========================================================================

If Len(_aGerente) > 0  

	//=========================================================================
	// Ordena os dados por descricao dos gerentes
	//=========================================================================
	aSort(_aGerente,,,{|x, y| x[2] < y[2]})
    //=======================================================================================
    // Imprime o cabecalho da primeira pagina, forca a quebra de pagina para esta impressao 
    //=======================================================================================
    
    ROMS030TPPG('Gerentes') 

	For x:=1 to Len(_aGerente)
	   	  			   	  
		_nLinha += _nSpcLin
		_oPrint:Line( _nLinha , _nColIni , _nLinha , _nColFim )
		
		ROMS030TQPG(0,.T.,.T.,"ROMS030TBOX()","ROMS030TCDR('Gerentes')")   
		
		_aValALM	:= ROMS30TCAD( _aGerente[x,1] ) 
		
		IIf( _aValALM[04] > 0 , _aGerente[x,4] += _aValALM[04] , Nil )
		
		_aImpostos	:= U_C_IRRF_INSS( _aGerente[x,3] , _aGerente[x,4] )
		_nValBnf	:= ROMS030TBNF( _aGerente[x,1] ) 
	  	
		ROMS030TPRD( _aGerente[x,2] , _aGerente[x,4] , _aImpostos[1,1] , _aImpostos[1,2] , _aGerente[x,5] , _nValBnf ) 
	  	
		//=========================================================================
		// Seta variaveis de controle dos totalizadores.
		//=========================================================================
		_nTotGComi += _aGerente[x,4] // (_aGerente[x,4] - _nValBnf) 
		_nTotGINSS += _aImpostos[1,1]
		_nTotGIRRF += _aImpostos[1,2]
		_nTotGBase += _aGerente[x,5]
		_nTotGBoni += _nValBnf
	
	Next x
	
	_nLinha+=_nSpcLin	     
	_oPrint:Line(_nLinha,_nColIni,_nLinha,_nColFim)  
	  
	ROMS030TQPG(0,.T.,.T.,"ROMS030TBOX()","ROMS030TCDR('Gerentes')")   
		
	//=========================================================================
	// Imprime o totalizador dos gerentes.
	//=========================================================================
	ROMS030TTOT('Total',_nTotGComi,_nTotGINSS,_nTotGIRRF,_nTotGBase,_nTotGBoni) 
	
	_nLinha+=_nSpcLin
	ROMS030TBOX() 

EndIf

	//========================================================================================
	// Chama a rotina para selecao dos registros da comissao gerada para os Gerente Nacional						
	//========================================================================================
	MsgRun("Aguarde....Filrando comissão do Gerente Nacional.",,{||CursorWait(),ROMS030TQRY(_cAliasVend,5),CursorArrow()})  
	
	DBSelectArea(_cAliasVend)
	(_cAliasVend)->(DBGoTop())        
	             	
	//=========================================================================
	// Armazena o numero de registros encontrados.
	//=========================================================================
	
	COUNT TO _nCountRec 
	
	ProcRegua(_nCountRec)
	
	DBSelectArea(_cAliasVend)
	(_cAliasVend)->(DBGoTop())       
	               	
	//=========================================================================
	// Efetua o grupamento dos dados dos gerentes nacionais.
	//=========================================================================
	While (_cAliasVend)->(!Eof()) 
		
			IncProc("Processando dados das comissoes do gerente nacional, favor aguardar...")
			
			_nPosicao:= aScan(_aGerNaci,{|k| k[1] == (_cAliasVend)->CODGERNAC})  
			
			If _nPosicao == 0
			      
				aAdd(_aGerNaci,{(_cAliasVend)->CODGERNAC,(_cAliasVend)->NOMEGERNAC,(_cAliasVend)->DEDUCAO,(_cAliasVend)->COMISSAO,(_cAliasVend)->VLRRECEB})
				
					Else
					
						_aGerNaci[_nPosicao,4] += (_cAliasVend)->COMISSAO 
						_aGerNaci[_nPosicao,5] += (_cAliasVend)->VLRRECEB
			
			EndIf 
					
	   (_cAliasVend)->(DBSkip())	
    EndDo                          

DBSelectArea(_cAliasVend)
(_cAliasVend)->(DBCloseArea())     

//=========================================================================
// Verifica a necessidade de quebra de pagina.
//=========================================================================

_nLinha+=_nSpcLin	

ROMS030TQPG(0,.F.,.F.,"","") 

//=========================================================================
// Imprime os dados das comissoes dos vendedores.
//=========================================================================

If Len(_aGerNaci) > 0  

	//=========================================================================
	// Ordena os dados por descricao dos vendedores.
	//=========================================================================
	aSort(_aGerNaci,,,{|x, y| x[2] < y[2]})
    //=======================================================================================
    // Imprime o cabecalho da primeira pagina, forca a quebra de pagina para esta impressao 
    //=======================================================================================
    
    ROMS030TPPG('Gerente Nacional') 

	For x:=1 to Len(_aGerNaci)
	   	  			   	  
		_nLinha += _nSpcLin
		_oPrint:Line( _nLinha , _nColIni , _nLinha , _nColFim )
		
		ROMS030TQPG(0,.T.,.T.,"ROMS030TBOX()","ROMS030TCDR('Gerente Nacional')")   
		
		_aValALM	:= ROMS30TCAD( _aGerNaci[x,1] ) 
		
		IIf( _aValALM[04] > 0 , _aGerNaci[x,4] += _aValALM[04] , Nil )
		
		_aImpostos	:= U_C_IRRF_INSS( _aGerNaci[x,3] , _aGerNaci[x,4] )
		_nValBnf	:= ROMS030TBNF( _aGerNaci[x,1] ) 
	  	
		ROMS030TPRD( _aGerNaci[x,2] , _aGerNaci[x,4] , _aImpostos[1,1] , _aImpostos[1,2] , _aGerNaci[x,5] , _nValBnf ) 
	  	
		//=========================================================================
		// Seta variaveis de controle dos totalizadores.
		//=========================================================================
		_nTotNComi += _aGerNaci[x,4] // (_aGerNaci[x,4] - _nValBnf) 
		_nTotNINSS += _aImpostos[1,1]
		_nTotNIRRF += _aImpostos[1,2]
		_nTotNBase += _aGerNaci[x,5]
		_nTotNBoni += _nValBnf
	
	Next x
	
	_nLinha+=_nSpcLin	     
	_oPrint:Line(_nLinha,_nColIni,_nLinha,_nColFim)  
	  
	ROMS030TQPG(0,.T.,.T.,"ROMS030TBOX()","ROMS030TCDR('Gerente Nacional')")   
		
	//=========================================================================
	// Imprime o totalizador do Gerente Nacional
	//=========================================================================
	ROMS030TTOT('Total',_nTotNComi,_nTotNINSS,_nTotNIRRF,_nTotNBase,_nTotNBoni) 
	
	_nLinha+=_nSpcLin
	ROMS030TBOX() 

EndIf

//=========================================================================
// Realiza a impressao do total gera do relatorio.
//=========================================================================
If Len(_aVendedor) > 0 .Or. Len(_aCoordena) > 0 .Or. Len(_aSupervis) > 0 .Or. Len(_aGerente) > 0 .Or. Len(_aGerNaci) > 0

	_nLinha+=_nSpcLin
	ROMS030TQPG(0,.F.,.F.,"","")  
	
	ROMS030TPPG('Somatório geral da comissão')     
	
	_nLinha+=_nSpcLin	     
	_oPrint:Line(_nLinha,_nColIni,_nLinha,_nColFim)  
		  
	ROMS030TQPG(0,.T.,.T.,"ROMS030TBOX()","ROMS030TCDR('Somatório geral da comissão')")   
	
	_nVlrComis	:= _nTotVComi + _nTotCComi + _nTotSComi + _nTotGComi + _nTotNComi
	_nINSS		:= _nTotVINSS + _nTotCINSS + _nTotSINSS + _nTotGINSS + _nTotNINSS    
	_nIRRF		:= _nTotVIRRF + _nTotCIRRF + _nTotSIRRF + _nTotGIRRF + _nTotNIRRF   
	_nVlrBase	:= _nTotVBase + _nTotCBase + _nTotSBase + _nTotGBase + _nTotNBase
	_nVlrBoni	:= _nTotVBoni + _nTotCBoni + _nTotSBoni + _nTotGBoni + _nTotNBoni
	
	ROMS030TPRD('Total Geral',_nVlrComis,_nINSS,_nIRRF,_nVlrBase,_nVlrBoni) 
	
	_nLinha+=_nSpcLin
	ROMS030TBOX() 

EndIf

If Select(_cAlias) > 0  
   (_cAlias)->( DBCloseArea() )
EndIf

If Select(_cAliasVend) > 0  
   (_cAliasVend)->( DBCloseArea() )
EndIf


Return 

/*
===============================================================================================================================
Programa--------: ROMS30TCAD // ROMS029CAD
Autor-----------: Fabiano Dias
Data da Criacao-: 30/03/2011
Descrição-------: Rotina que retorna os valores de matéria gorda para os cálculos adicionais
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS30TCAD( _cCodVen ) // ROMS029CAD
Local _cDtRef		:= SubStr( MV_PAR01 , 3 , 4 ) + SubStr( MV_PAR01 , 1 , 2 )
Local _aRet			:= { 0 , 0 , 0 , 0 }
Local _nI , _cDtInic, _cDtFim
Local _dDtInic, _dDtFim, _nNrMeses
Local _nMes , _nAno
Default _cCodVen	:= ''

_cDtInic := "01/" + SubStr( MV_PAR01 , 1 , 2 ) + "/"+ SubStr( MV_PAR01 , 3 , 4 )
_cDtFim  := "01/" + SubStr( MV_PAR02 , 1 , 2 ) + "/"+ SubStr( MV_PAR02 , 3 , 4 )
_dDtInic := Ctod(_cDtInic)
_dDtFim  := Ctod(_cDtFim)

_nNrMeses := DateDiffMonth(_dDtInic, _dDtFim)

DBSelectArea('ZC1')
ZC1->( DBSetOrder(1) )

_aRet[01] := 0
_aRet[02] := 0
_aRet[03] := 0
_aRet[04] := 0

If AllTrim(MV_PAR01) == AllTrim(MV_PAR02)
   If ZC1->( DBSeek( xFilial('ZC1') + _cCodVen + _cDtRef ) )
      _aRet[01] := ZC1->ZC1_VALLMG
	  _aRet[02] := ZC1->ZC1_PERLMG
	  _aRet[03] := Round( ( ZC1->ZC1_VALCAD / ZC1->ZC1_VALLMG ) * 100 , 2 )
	  _aRet[04] := ZC1->ZC1_VALCAD
   EndIf
Else 
   _nMes := Val(SubStr( MV_PAR01 , 1 ,2)) 
   _nAno := Val(SubStr( MV_PAR01 , 3 ,4))

   For _nI := 1 To _nNrMeses
       _cDtRef := StrZero(_nAno, 4) + StrZero(_nMes,2)
       
	   If ZC1->( DBSeek( xFilial('ZC1') + _cCodVen + _cDtRef ) )
          _aRet[01] += ZC1->ZC1_VALLMG
	      _aRet[02] += ZC1->ZC1_PERLMG
	      _aRet[03] += Round( ( ZC1->ZC1_VALCAD / ZC1->ZC1_VALLMG ) * 100 , 2 )
	      _aRet[04] += ZC1->ZC1_VALCAD
       EndIf

       _nMes += 1
	   If _nMes > 12
          _nMes := 1
		  _nAno += 1 
       EndIf 
   Next 
EndIf 

Return( _aRet )

/*
===============================================================================================================================
Programa----------: ROMS030TCBN
Autor-------------: Fabiano Dias
Data da Criacao---: 01/04/2011
Descrição---------: Funcao usada para verificar os valores de comissão sobre bonificação
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS030TCBN( _cCodVen ) // ROMS029CBN
Local _cDtRef		:= SubStr( MV_PAR01 , 3 , 4 ) + SubStr( MV_PAR01 , 1 , 2 )
Local _nRet    := 0
Local _nI , _cDtInic, _cDtFim
Local _dDtInic, _dDtFim, _nNrMeses
Local _nMes , _nAno
Default _cCodVen	:= ''

_cDtInic := "01/" + SubStr( MV_PAR01 , 1 , 2 ) + "/"+ SubStr( MV_PAR01 , 3 , 4 )
_cDtFim  := "01/" + SubStr( MV_PAR02 , 1 , 2 ) + "/"+ SubStr( MV_PAR02 , 3 , 4 )
_dDtInic := Ctod(_cDtInic)
_dDtFim  := Ctod(_cDtFim)

_nNrMeses := DateDiffMonth(_dDtInic, _dDtFim)

DBSelectArea('ZC6')
ZC6->( DBSetOrder(1) )

_nRet    := 0

If _nNrMeses == 1 .Or. _nNrMeses == 0
   If ZC6->( DBSeek( xFilial('ZC6') + _cCodVen + _cDtRef ) )
	
	  _nRet := Round( ZC6->ZC6_VALLIQ * ( ZC6->ZC6_PERCOM / 100 ) , 2 )
	
   EndIf
Else 
   _nMes := Val(SubStr( MV_PAR01 , 1 ,2)) 
   _nAno := Val(SubStr( MV_PAR01 , 3 ,4))

   For _nI := 1 To _nNrMeses
       _cDtRef := StrZero(_nAno, 4) + StrZero(_nMes,2)
       
	   If ZC6->( DBSeek( xFilial('ZC6') + _cCodVen + _cDtRef ) )
	
	      _nRet += Round( ZC6->ZC6_VALLIQ * ( ZC6->ZC6_PERCOM / 100 ) , 2 )
	
       EndIf

       _nMes += 1
	   If _nMes > 12
          _nMes := 1
		  _nAno += 1 
       EndIf 
   Next 
EndIf 

Return( _nRet )

/*
===============================================================================================================================
Programa--------: ROMS030TBNF // ROMS029BNF
Autor-----------: Alexandre Villar
Data da Criacao-: 2014
Descrição-------: Funcao que retorna os dados de cálculos de bonificações
Parametros------: _cCodCor - Código do coordenador que está sendo apurado
Retorno---------: _aRet    - Array com dados das bonificações
===============================================================================================================================
*/
Static Function ROMS030TBNF( _cCodCor ) 

Local _cAlias		:= GetNextAlias() 
Local _cQuery		:= ""
Local _cDtRef		:= SubStr( MV_PAR01 , 3 , 4 ) + SubStr( MV_PAR01 , 1 , 2 )
Local _nRet			:= 0

Default _cCodCor	:= ' '

_cQuery := " SELECT "
_cQuery += "     Round( SUM( ZC7.ZC7_VALLIQ * ( ZAE.ZAE_COMIS1 / 100 ) ) , 2 ) AS VALCMS "
_cQuery += " FROM "+ RetSqlName('ZC7') +" ZC7 "
_cQuery += " INNER JOIN "+ RetSqlName('SA3') +" SA3 "
_cQuery += " ON "
_cQuery += "     SA3.A3_COD     = SubStr( ZC7.ZC7_CHAVE , 1 , 6 ) "
_cQuery += " INNER JOIN "+ RetSqlName('ZAE') +" ZAE "
_cQuery += " ON "
_cQuery += "     ZAE.ZAE_VEND   = SA3.A3_COD "
_cQuery += " AND ZAE.ZAE_COMIS1 > 0 "
_cQuery += " AND ZAE.ZAE_PROD   = ZC7.ZC7_CODPRD "
_cQuery += " WHERE "
_cQuery += "     ZC7.D_E_L_E_T_ = ' ' "
_cQuery += " AND SA3.D_E_L_E_T_ = ' ' "
_cQuery += " AND ZAE.D_E_L_E_T_ = ' ' "
_cQuery += " AND ZAE.ZAE_GRPVEN = ' ' "
_cQuery += " AND ZAE.ZAE_CLI    = ' ' "
_cQuery += " AND ZAE.ZAE_LOJA   = ' ' "
_cQuery += " AND ZC7.ZC7_ITEM   = '01' "
_cQuery += " AND SubStr(ZC7.ZC7_CHAVE,1,6) = '"+ _cCodCor +"' "

If AllTrim(MV_PAR01) == AllTrim(MV_PAR02)
   _cQuery += " AND SubStr(ZC7.ZC7_CHAVE,7,6) = '"+ _cDtRef  +"' "
Else 
   _cQuery += " AND SubStr(ZC7.ZC7_CHAVE,7,6) >= '" + SubStr(MV_PAR01,3,4) + SubStr(MV_PAR01,1,2) + "' AND SubStr(ZC7.ZC7_CHAVE,7,6) <= '"+ SubStr(MV_PAR02,3,4) + SubStr(MV_PAR02,1,2) + "' "
EndIf 

_cQuery += " UNION ALL "

_cQuery += " SELECT "
_cQuery += "     Round( SUM( ZC7.ZC7_VALLIQ * ( ZAE.ZAE_COMIS2 / 100 ) ) , 2 ) AS VALCMS "
_cQuery += " FROM "+ RetSqlName('ZC7') +" ZC7 "
_cQuery += " INNER JOIN "+ RetSqlName('SA3') +" SA3 "
_cQuery += " ON "
_cQuery += "     SA3.A3_COD     = SubStr( ZC7.ZC7_CHAVE , 1 , 6 ) "
_cQuery += " INNER JOIN "+ RetSqlName('ZAE') +" ZAE "
_cQuery += " ON "
_cQuery += "     ZAE.ZAE_VEND   = SA3.A3_COD "
_cQuery += " AND ZAE.ZAE_COMIS2 > 0 "
_cQuery += " AND ZAE.ZAE_PROD   = ZC7.ZC7_CODPRD "
_cQuery += " WHERE "
_cQuery += "     ZC7.D_E_L_E_T_ = ' ' "
_cQuery += " AND SA3.D_E_L_E_T_ = ' ' "
_cQuery += " AND ZAE.D_E_L_E_T_ = ' ' "
_cQuery += " AND ZAE.ZAE_GRPVEN = ' ' "
_cQuery += " AND ZAE.ZAE_CLI    = ' ' "
_cQuery += " AND ZAE.ZAE_LOJA   = ' ' "
_cQuery += " AND ZAE.ZAE_CODSUP = '"+ _cCodCor +"' "

If AllTrim(MV_PAR01) == AllTrim(MV_PAR02)
   _cQuery += " AND SubStr(ZC7.ZC7_CHAVE,7,6) = '"+ _cDtRef +"' "
Else 
   _cQuery += " AND SubStr(ZC7.ZC7_CHAVE,7,6) >= '" + SubStr(MV_PAR01,3,4) + SubStr(MV_PAR01,1,2) + "' AND SubStr(ZC7.ZC7_CHAVE,7,6) <= '"+ SubStr(MV_PAR02,3,4) + SubStr(MV_PAR02,1,2) + "' "
EndIf 

If Select(_cAlias) > 0
   (_cAlias)->( DBCloseArea() )
EndIf     

DBUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQuery) , _cAlias , .T. , .F. )

DBSelectArea(_cAlias)
(_cAlias)->( DBGoTop() )

While (_cAlias)->(!Eof())

   _nRet += IIf( ValType( (_cAlias)->VALCMS ) == 'N' , (_cAlias)->VALCMS , 0 )

   (_cAlias)->( DBSkip() )
EndDo

If Select(_cAlias) > 0  
   (_cAlias)->( DBCloseArea() )
EndIf

Return( _nRet )

/*
===============================================================================================================================
Programa--------: ROMS030EXCEL 
Autor-----------: Julio de Paula Paz
Data da Criacao-: 31/08/2021
Descrição-------: Gera o relatório Prévia-Sintético em Excel.
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/ 
Static Function ROMS030EXCEL()

Local _cAlias    := GetNextAlias()  
Local _cAliasVend:= GetNextAlias()  
Local _aVendedor:= {}
Local _aCoordena:= {}
Local _aSupervis:= {}
Local _aGerente := {}
Local _aGerNaci := {}
Local _aValALM	:= {}  
Local _aImpostos:= {} 
Local _nPosicao := 0   
Local _nVlrComis:= 0
Local _nINSS	:= 0
Local _nIRRF    := 0   
Local _nVlrBase := 0
//Local _nVlrBoni	:= 0
Local _nPorcCom		:= 0
Local _nVlrLiq		:= 0
//Local _nValBnf  := 0 , x
Local x

Private _aDados := {}, _aTitulos := {}

Begin Sequence 

   If Empty(MV_PAR01) .Or. Empty(MV_PAR02)
	  MsgInfo("Favor preencher os parâmetros: Mes/Ano Inicial e Mes/Ano Final antes de imprimir este relatório.")
	  Break
   EndIf
      
   //=================================================================================================
   // Chama a rotina para selecao dos registros da comissao gerada para os vendedores				
   //=================================================================================================
   MsgRun("Aguarde....Filrando comissao dos vendedores.",,{||CursorWait(),ROMS030TQRY(_cAlias,1),CursorArrow()})
	
   DBSelectArea(_cAlias)
   (_cAlias)->(DBGoTop())        
	             	
   //=========================================================================
   // Armazena o numero de registros encontrados. 
   //=========================================================================
   COUNT TO _nCountRec 
	
   ProcRegua(_nCountRec)
	
   DBSelectArea(_cAlias)
   (_cAlias)->( DBGoTop() )
	
   //=========================================================================
   // Efetua o grupamento dos dados dos vendedores. 
   //=========================================================================
   While (_cAlias)->( !Eof() )
	
      IncProc("Processando dados das comissoes do vendedor, favor aguardar...")
		
      _nPosicao := aScan( _aVendedor , {|k| k[1] == (_cAlias)->CODVEND } )
		
      If _nPosicao == 0
		
         aAdd( _aVendedor , {	(_cAlias)->CODVEND		,;
								(_cAlias)->NOMEVEND		,;
								(_cAlias)->DEDUCAO		,;
								(_cAlias)->COMISSAO		,;
								(_cAlias)->VLRRECEB		})
			
	  Else
		
		 _aVendedor[_nPosicao,4] += (_cAlias)->COMISSAO
		 _aVendedor[_nPosicao,5] += (_cAlias)->VLRRECEB
		
	  EndIf
		
	  (_cAlias)->( DBSkip() )
   EndDo

   DBSelectArea(_cAlias)
   (_cAlias)->( DBCloseArea() )

   //=========================================================================
   // Imprime os dados das comissoes dos vendedores.
   //=========================================================================
   If Len(_aVendedor) > 0                                                                       	
	  //=========================================================================
	  // Ordena os dados por descricao dos vendedores.
	  //=========================================================================
	  aSort( _aVendedor ,,, {|x, y| x[2] < y[2] } )

	  For x := 1 To Len( _aVendedor )	
		  
		  _aValALM := ROMS30TCAD( _aVendedor[x,1] )
	  	
		  IIf( _aValALM[04] > 0 , _aVendedor[x,4] += _aValALM[04] , Nil )
	  	
		  _aImpostos	:= U_C_IRRF_INSS(_aVendedor[x,3],_aVendedor[x,4])
		  _nVlrBonif	:= ROMS030TCBN( _aVendedor[x,1] ) 
	
		  _cNome := _aVendedor[x,2]
		  _nVlrComis := _aVendedor[x,4] 
		  _nINSS := _aImpostos[1,1]
		  _nIRRF := _aImpostos[1,2]
		  _nVlrBase := _aVendedor[x,5]
	
		  _nPorcCom			:= ( ( _nVlrComis - _nVlrBonif ) / _nVlrBase ) * 100
          _nVlrComis		-= _nVlrBonif
          _nVlrLiq			:= _nVlrComis - ( _nINSS + _nIRRF )

          aAdd(_aDados,{"VENDEDOR",;
		                SubStr( _cNome , 1 , 57 ),;
                        _nVlrComis,;
                        _nINSS,;
                        _nIRRF,;
                        _nVlrLiq,;
                        _nPorcCom})
	
      Next x
   EndIf            

   //========================================================================================
   // Chama a rotina para selecao dos registros da comissao gerada para os Supervisores						
   //========================================================================================
   MsgRun("Aguarde....Filrando comissão dos supervisores.",,{||CursorWait(),ROMS030TQRY(_cAliasVend,3),CursorArrow()}) 
	
   DBSelectArea(_cAliasVend)
   (_cAliasVend)->(DBGoTop())        
	             	
   //=========================================================================
   // Armazena o numero de registros encontrados.
   //=========================================================================
	
   COUNT TO _nCountRec 
	
   ProcRegua(_nCountRec)
	
   DBSelectArea(_cAliasVend)
   (_cAliasVend)->(DBGoTop())       
	               	
   //=========================================================================
   // Efetua o grupamento dos dados dos supervisores.
   //=========================================================================
   While (_cAliasVend)->(!Eof()) 
		
      IncProc("Processando dados das comissoes do supervisor, favor aguardar...")
			
      _nPosicao:= aScan(_aSupervis,{|k| k[1] == (_cAliasVend)->CODSUPERV})  
			
      If _nPosicao == 0
			      
         aAdd(_aSupervis,{(_cAliasVend)->CODSUPERV,(_cAliasVend)->NOMESUPERV,(_cAliasVend)->DEDUCAO,(_cAliasVend)->COMISSAO,(_cAliasVend)->VLRRECEB})
				
      Else
					
         _aSupervis[_nPosicao,4] += (_cAliasVend)->COMISSAO 
		 _aSupervis[_nPosicao,5] += (_cAliasVend)->VLRRECEB
			
	  EndIf 
					
      (_cAliasVend)->(DBSkip())	
   EndDo                          

   DBSelectArea(_cAliasVend)
   (_cAliasVend)->(DBCloseArea())     
   
   //=========================================================================
   // Imprime os dados das comissoes dos supervisores.
   //=========================================================================
   If Len(_aSupervis) > 0  

      //=========================================================================
	  // Ordena os dados por descricao dos supervisores.
	  //=========================================================================
	  aSort(_aSupervis,,,{|x, y| x[2] < y[2]})

      For x:=1 to Len(_aSupervis)
	   	  			   	  
		  _aValALM	:= ROMS30TCAD( _aSupervis[x,1] ) 
		
		  IIf( _aValALM[04] > 0 , _aSupervis[x,4] += _aValALM[04] , Nil )
		
		  _aImpostos := U_C_IRRF_INSS( _aSupervis[x,3] , _aSupervis[x,4] )
		  //_nValBnf	 := ROMS030TBNF( _aSupervis[x,1] ) 
		  _nVlrBonif	 := ROMS030TBNF( _aSupervis[x,1] ) 
	  	
	  	  _cNome    := _aSupervis[x,2]
		  _nVlrComis := _aSupervis[x,4] 
		  _nINSS     := _aImpostos[1,1]
		  _nIRRF     := _aImpostos[1,2]
		  _nVlrBase  := _aSupervis[x,5]
		  _nPorcCom	 := ( ( _nVlrComis - _nVlrBonif ) / _nVlrBase ) * 100
          _nVlrComis -= _nVlrBonif
          _nVlrLiq	 := _nVlrComis - ( _nINSS + _nIRRF )
          aAdd(_aDados,{"SUPERVISOR",;
		                SubStr( _cNome , 1 , 57 ),;
                        _nVlrComis,;
                        _nINSS,;
                        _nIRRF,;
                        _nVlrLiq,;
                        _nPorcCom})
	
      Next x
   EndIf

   //========================================================================================
   // Chama a rotina para selecao dos registros da comissao gerada para os Coordenadores						
   //========================================================================================
   MsgRun("Aguarde....Filrando comissão dos coordenadores.",,{||CursorWait(),ROMS030TQRY(_cAliasVend,2),CursorArrow()}) 
	
   DBSelectArea(_cAliasVend)
   (_cAliasVend)->(DBGoTop())        
	             	
   //=========================================================================
   // Armazena o numero de registros encontrados.
   //=========================================================================
	
   COUNT TO _nCountRec 
	
   ProcRegua(_nCountRec)
	
   DBSelectArea(_cAliasVend)
   (_cAliasVend)->(DBGoTop())       
	               	
   //=========================================================================
   // Efetua o grupamento dos dados dos coordenadores
   //=========================================================================
   While (_cAliasVend)->(!Eof()) 
		
      IncProc("Processando dados das comissoes do coordenador, favor aguardar...")
			
      _nPosicao:= aScan(_aCoordena,{|k| k[1] == (_cAliasVend)->CODCOORD})  
			
      If _nPosicao == 0
		 
		 aAdd(_aCoordena,{(_cAliasVend)->CODCOORD,(_cAliasVend)->NOMECOORD,(_cAliasVend)->DEDUCAO,(_cAliasVend)->COMISSAO,(_cAliasVend)->VLRRECEB})
				
      Else
         _aCoordena[_nPosicao,4] += (_cAliasVend)->COMISSAO 
         _aCoordena[_nPosicao,5] += (_cAliasVend)->VLRRECEB
			
      EndIf 
					
      (_cAliasVend)->(DBSkip())	
   EndDo                          

   DBSelectArea(_cAliasVend)
   (_cAliasVend)->(DBCloseArea())     

   //=========================================================================
   // Imprime os dados das comissoes dos Coordenadores
   //=========================================================================
   If Len(_aCoordena) > 0  

      //=========================================================================
	  // Ordena os dados por descricao dos vendedores.
	  //=========================================================================
	  aSort(_aCoordena,,,{|x, y| x[2] < y[2]})
      
	  For x:=1 to Len(_aCoordena)
		
		  _aValALM	:= ROMS30TCAD( _aCoordena[x,1] ) // ROMS029CAD
		
		  IIf( _aValALM[04] > 0 , _aCoordena[x,4] += _aValALM[04] , Nil )
		
		  _aImpostos	:= U_C_IRRF_INSS( _aCoordena[x,3] , _aCoordena[x,4] )
		  //_nValBnf	
		  _nVlrBonif := ROMS030TBNF( _aCoordena[x,1] ) // ROMS029BNF
	  	
		  //ROMS030TPRD( _aCoordena[x,2] , _aCoordena[x,4] , _aImpostos[1,1] , _aImpostos[1,2] , _aCoordena[x,5] , _nValBnf ) // ROMS029PRD
           _cNome    := _aCoordena[x,2]
		  _nVlrComis := _aCoordena[x,4] 
		  _nINSS     := _aImpostos[1,1]
		  _nIRRF     := _aImpostos[1,2]
		  _nVlrBase  := _aCoordena[x,5]
		  //_nVlrBonif
		  _nPorcCom	 := ( ( _nVlrComis - _nVlrBonif ) / _nVlrBase ) * 100
          _nVlrComis -= _nVlrBonif
          _nVlrLiq	 := _nVlrComis - ( _nINSS + _nIRRF )
//------------------------------------------------------------------------
          aAdd(_aDados,{"COORDENADOR",;
		                SubStr( _cNome , 1 , 57 ),;
                        _nVlrComis,;
                        _nINSS,;
                        _nIRRF,;
                        _nVlrLiq,;
                        _nPorcCom})
      Next x
   EndIf

   //========================================================================================
   // Chama a rotina para selecao dos registros da comissao gerada para os gerentes					
   //========================================================================================
   MsgRun("Aguarde....Filrando comissão dos gerentes.",,{||CursorWait(),ROMS030TQRY(_cAliasVend,4),CursorArrow()})  
	
   DBSelectArea(_cAliasVend)
   (_cAliasVend)->(DBGoTop())        
	             	
   //=========================================================================
   // Armazena o numero de registros encontrados.
   //=========================================================================
	
   COUNT TO _nCountRec 
	
   ProcRegua(_nCountRec)
	
   DBSelectArea(_cAliasVend)
   (_cAliasVend)->(DBGoTop())       
	               	
   //=========================================================================
   // Efetua o grupamento dos dados dos vendedores.
   //=========================================================================
   While (_cAliasVend)->(!Eof()) 
		
      IncProc("Processando dados das comissoes do gerente, favor aguardar...")
			
      _nPosicao:= aScan(_aGerente,{|k| k[1] == (_cAliasVend)->CODGEREN})  
			
      If _nPosicao == 0
			      
         aAdd(_aGerente,{(_cAliasVend)->CODGEREN,(_cAliasVend)->NOMEGEREN,(_cAliasVend)->DEDUCAO,(_cAliasVend)->COMISSAO,(_cAliasVend)->VLRRECEB})
				
      Else
					
         _aGerente[_nPosicao,4] += (_cAliasVend)->COMISSAO 
         _aGerente[_nPosicao,5] += (_cAliasVend)->VLRRECEB
      EndIf 
					
      (_cAliasVend)->(DBSkip())	
   EndDo                          

   DBSelectArea(_cAliasVend)
   (_cAliasVend)->(DBCloseArea())     

   //=========================================================================
   // Imprime os dados das comissoes dos gerentes
   //=========================================================================

   If Len(_aGerente) > 0  
	  //=========================================================================
	  // Ordena os dados por descricao dos gerentes
	  //=========================================================================
	  aSort(_aGerente,,,{|x, y| x[2] < y[2]})

	  For x:=1 to Len(_aGerente)
	   	  			   	  
		  _aValALM	:= ROMS30TCAD( _aGerente[x,1] ) 
		
		  IIf( _aValALM[04] > 0 , _aGerente[x,4] += _aValALM[04] , Nil )
		
		  _aImpostos	:= U_C_IRRF_INSS( _aGerente[x,3] , _aGerente[x,4] )
		  //_nValBnf	:= ROMS030TBNF( _aGerente[x,1] ) 
		  _nVlrBonif	:= ROMS030TBNF( _aGerente[x,1] ) 
	  	
		//ROMS030TPRD( _aGerente[x,2] , _aGerente[x,4] , _aImpostos[1,1] , _aImpostos[1,2] , _aGerente[x,5] , _nValBnf ) 
	   	  _cNome    := _aGerente[x,2]
		  _nVlrComis := _aGerente[x,4] 
		  _nINSS     := _aImpostos[1,1]
		  _nIRRF     := _aImpostos[1,2]
		  _nVlrBase  := _aGerente[x,5]
		  //_nVlrBonif
		  _nPorcCom	 := ( ( _nVlrComis - _nVlrBonif ) / _nVlrBase ) * 100
          _nVlrComis -= _nVlrBonif
          _nVlrLiq	 := _nVlrComis - ( _nINSS + _nIRRF )
//------------------------------------------------------------------------
          aAdd(_aDados,{"GERENTE",;
		                SubStr( _cNome , 1 , 57 ),;
                        _nVlrComis,;
                        _nINSS,;
                        _nIRRF,;
                        _nVlrLiq,;
                        _nPorcCom})
     	
      Next x
	
   EndIf

   //========================================================================================
   // Chama a rotina para selecao dos registros da comissao gerada para os Gerente Nacional						
   //========================================================================================
   MsgRun("Aguarde....Filrando comissão do Gerente Nacional.",,{||CursorWait(),ROMS030TQRY(_cAliasVend,5),CursorArrow()})  
	
   DBSelectArea(_cAliasVend)
   (_cAliasVend)->(DBGoTop())        
	             	
   //=========================================================================
   // Armazena o numero de registros encontrados.
   //=========================================================================
	
   COUNT TO _nCountRec 
	
   ProcRegua(_nCountRec)
	
   DBSelectArea(_cAliasVend)
   (_cAliasVend)->(DBGoTop())       
	               	
   //=========================================================================
   // Efetua o grupamento dos dados dos gerentes nacionais.
   //=========================================================================
   While (_cAliasVend)->(!Eof()) 

      IncProc("Processando dados das comissoes do gerente nacional, favor aguardar...")
			
      _nPosicao:= aScan(_aGerNaci,{|k| k[1] == (_cAliasVend)->CODGERNAC})  
			
      If _nPosicao == 0
			      
         aAdd(_aGerNaci,{(_cAliasVend)->CODGERNAC,(_cAliasVend)->NOMEGERNAC,(_cAliasVend)->DEDUCAO,(_cAliasVend)->COMISSAO,(_cAliasVend)->VLRRECEB})
				
      Else
					
         _aGerNaci[_nPosicao,4] += (_cAliasVend)->COMISSAO 
		 _aGerNaci[_nPosicao,5] += (_cAliasVend)->VLRRECEB
			
      EndIf 
					
      (_cAliasVend)->(DBSkip())	
   EndDo                          

   DBSelectArea(_cAliasVend)
   (_cAliasVend)->(DBCloseArea())     
 
   //=========================================================================
   // Imprime os dados das comissoes dos Gerentes Nacionais
   //=========================================================================

   If Len(_aGerNaci) > 0  

      //=========================================================================
      // Ordena os dados por descricao dos vendedores.
      //=========================================================================
      aSort(_aGerNaci,,,{|x, y| x[2] < y[2]})
      
	  For x:=1 to Len(_aGerNaci)
	   	  			   	  
		  _aValALM	:= ROMS30TCAD( _aGerNaci[x,1] ) 
		
		  IIf( _aValALM[04] > 0 , _aGerNaci[x,4] += _aValALM[04] , Nil )
		
		  _aImpostos	:= U_C_IRRF_INSS( _aGerNaci[x,3] , _aGerNaci[x,4] )
		  //_nValBnf	:= ROMS030TBNF( _aGerNaci[x,1] ) 
		  _nVlrBonif	:= ROMS030TBNF( _aGerNaci[x,1] ) 
	  	
		//ROMS030TPRD( _aGerNaci[x,2] , _aGerNaci[x,4] , _aImpostos[1,1] , _aImpostos[1,2] , _aGerNaci[x,5] , _nValBnf ) 

		  _cNome    := _aGerNaci[x,2]
		  _nVlrComis := _aGerNaci[x,4] 
		  _nINSS     := _aImpostos[1,1]
		  _nIRRF     := _aImpostos[1,2]
		  _nVlrBase  := _aGerNaci[x,5]
		  //_nVlrBonif
		  _nPorcCom	 := ( ( _nVlrComis - _nVlrBonif ) / _nVlrBase ) * 100
          _nVlrComis -= _nVlrBonif
          _nVlrLiq	 := _nVlrComis - ( _nINSS + _nIRRF )
//------------------------------------------------------------------------
          aAdd(_aDados,{"GERENTE NACIONAL",;
		                SubStr( _cNome , 1 , 57 ),;
                        _nVlrComis,;
                        _nINSS,;
                        _nIRRF,;
                        _nVlrLiq,;
                        _nPorcCom})
	  	
      Next x	
   EndIf

   If Len(_aDados) == 0
      U_ITMsg( 'Não há dados para a emissão do relatório.' , 'Atenção!' , , 1)
	  
	  Break 
   EndIf 

   _aTitulos := {"Tipo Representante",;
                 "Nome",;
				 "Valor Comissão Bruto",;
				 "INSS",;
				 "IRRF",;
				 "Valor Comissão Líquido",;
				 "% Valor Recebido"}
	
   U_ITListBox("Relatório Comissão Extrato Vendedor - Prévia Sintético" , _aTitulos , _aDados , .T. , 1 , "Exportação excel/arquivo") 

End Sequence 
   
If Select(_cAlias) > 0  
   (_cAlias)->( DBCloseArea() )
EndIf

If Select(_cAliasVend) > 0  
   (_cAliasVend)->( DBCloseArea() )
EndIf

Return

/*
===============================================================================================================================
Programa--------: ROMS030RNI
Autor-----------: Julio de Paula Paz
Data da Criacao-: 04/11/2022
Descrição-------: Função que imprime os dados do relatório. Utilizando a nova Ferramenta de impressão FWMSPRINTER() em 
                  substituição da ferramenta TMSPRINTER() que foi descontinuada pela Totvs.
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/

Static Function ROMS030RNI()

Local _aComissao	:= {}     
Local _aGerente		:= {} //Armazena os Gerentes que geraram comissao de acordo com os parametros fornecidos pelo usuario
Local _cFilGer		:= ""
Local _cAliasPg		:= "" 
Local _nPosicao		:= 0
Local _cAliasDup	:= "" 
Local _aDupVenc		:= {} 
Local _aComisPg		:= {}
Local _aDadosCom	:= {}  
Local _cOpcFiltr    := ""
Local _cAliasAve    := ""
Local _cAliasVHi    := "" 
Local x
Local _cTituloRep                                          

_cCodRepSA3  := _ccodi    
_cTipoRepSA3 := _cctipvi               

_cTituloRep  := ""
If _cTipoRepSA3 == 'G'  	
   _cTituloRep := "Gerente"  
ElseIf _cTipoRepSA3 == 'C'
   _cTituloRep := "Coordenador"
ElseIf _cTipoRepSA3 == 'S'
   _cTituloRep := "Supervisor"
ElseIf _cTipoRepSA3 == 'V'
   _cTituloRep := "Representante"
EndIf

FWMsgRun( ,{|| _aComissao := ROMS030SEL() } , 'Aguarde!' ,  'Filtrando comissao para '+ _cTituloRep+ '-' +  _cCodRepSA3 + "..." )

//==========================================================================================
// Preenche o array _aComissao com valores zerados, para Gerente, Coordenador e Supervisor
//========================================================================================== 
If Empty(_aComissao) .And. AllTrim(_cTipoRepSA3) $ "G/C/S"   // V=VENDEDOR;C=COORDENADOR;G=GERENTE;S=SUPERVISOR 
   _aComissao := U_ROMS030D(_cCodRepSA3)
   
EndIf
//================================================================================
// Verifica se existe comissao gerada para os vendedores.
//================================================================================
If Len(_aComissao) > 0
 
	//================================================================================
	// Efetua o grupamento dos Gerentes que possuem comissao gerada, para posterior
	// uso durante toda a impressao da comissao dos Gerentes.
	//================================================================================
    For x:=1 to Len(_aComissao)
    
		_nPosicao:= aScan( _aGerente , {|Y| Y[1] == _aComissao[x,1] } )
		
		If _nPosicao == 0
			aAdd( _aGerente , { _aComissao[x,1] } )
		EndIf
	
	Next x
	                      
	//================================================================================
	// A variavel _cFilGer eh utilizada para agilizar o processo de consulta nas 
	// ROMS030QRY, fazendo somente uma consulta para todos os Gerentes e depois 
	// filtrando o Gerente corrente dentro do alias criado na consulta.
	//================================================================================
	aEval( _aGerente , {|K| _cFilGer += ";" + AllTrim(K[1]) } )
	
	//================================================================================
	// Filtrando o historico de comissoes pagas de todos os Gerentes.
	//================================================================================
	If ! Empty(_cAliasPg) 
       If Select(_cAliasPg) > 0  
          (_cAliasPg)->( DBCloseArea() )
       EndIf
	EndIf   
	_cAliasPg := GetNextAlias()   

	FWMsgRun( , {|| ROMS030QRY(_cAliasPg,3,"","","",_cFilGer) } , 'Aguarde!', 'Filtrando historico de comissoes pagas para ' + _cTituloRep+ '-' +  _cCodRepSA3 + "..."  )
	//_lHistFiltro := .T.

    //================================================================================
	// Codigo de Gerente Nacional, Gerentes, Coordenadores, Supervisores e Venderos 
	// informados na tela de filtro Concatenados.
	//================================================================================
    _cOpcFiltr := AllTrim(MV_PAR03) + If(!Empty(MV_PAR03),";","") +; // - Gerente Nac.
                  AllTrim(MV_PAR04) + If(!Empty(MV_PAR04),";","") +; // - Gerente
                  AllTrim(MV_PAR05) + If(!Empty(MV_PAR05),";","") +; // - Coordenador
                  AllTrim(MV_PAR06) + If(!Empty(MV_PAR06),";","") +; // - Supervisor
                  AllTrim(MV_PAR07) + If(!Empty(MV_PAR07),";","")    // - Vendedor

	//================================================================================
	// Percorre todos os vendedores para realizar a impressao de seus dados.
	//================================================================================
	For x:=1 To Len( _aGerente )

        //================================================================================
        // Verifica se imprime ou não a hierarquia dos Ger Nac, Ger, Coord, Super, Repres
		// informados na tela de filtro.
		//================================================================================
		If MV_PAR12 == 'Nao' // 2 // Imprime hierarquia igual a Não.
           If ! Empty(_cOpcFiltr) .And. ! (_aGerente[x,1] $ _cOpcFiltr)
              Loop
           EndIf 
		EndIf 

        //================================================================================
		// Seleciona os dados da COMISSAO A PAGAR do mes de fechamento do Gerente
		//================================================================================
		_aDadosCom := ROMS030CPA( _aGerente[x,1] , _aComissao )
        
		If MV_PAR11 == 'Nao' // 2 // Verifica se as comissões estão zeradas e não exibe documento para impressão.
		   If ROMS30RCNI(_aDadosCom , 2 , _aGerente[x,1]) == 0  
		      Loop 
		   EndIf 
        EndIf 
		
		//================================================================================
	    // Filtrando o historico de comissoes pagas de todos os Gerentes.
	    //================================================================================
/*	    If _lHistFiltro 
		   _lHistFiltro := .F.
		   _cAliasPg := GetNextAlias()

	       FWMsgRun( , {|| ROMS030QRY(_cAliasPg,3,"","","",_cFilGer) } , 'Aguarde!', 'Filtrando historico de comissoes pagas para ' + _cTituloRep+ '-' +  _cCodRepSA3 + "..."  )
	    EndIf  
*/

		//================================================================================
		// Para cada Gerente começar em uma nova pagina força a quebra de pagina.
		//================================================================================
		ROMS30RQBR()
		
		//================================================================================
		// Imprime o cabecalho de dados das INFORMACOES CADASTRAIS
		//================================================================================
		ROMS30RCIC( _aGerente[x,1] )
		
		//======================================================================================================================
		// Chama rotina para selecao de todas as duplicatas vencidas do vendedor corrente
		//======================================================================================================================
		If ! Empty(_cAliasDup)
           If Select(_cAliasDup) > 0  
              (_cAliasDup)->( DBCloseArea() )
           EndIf
		EndIf 

		_cAliasDup := GetNextAlias() 
		
		FWMsgRun( , {||  ROMS030QRY( _cAliasDup , 2 , "", _aGerente[x,1] )  }, 'Aguarde!',"Filtrando duplicatas vencidas para " + _cTituloRep+ '-' +  _cCodRepSA3 + "..."    )
	
		//======================================================================================================================
		// Verifica as duplicatas vencidas do vendedor
		//======================================================================================================================
		_aDupVenc := ROMS030VDP( _cAliasDup )
	
        //======================================================================================================================
		// Chama rotina para selecao de todas as duplicatas a vencer do vendedor corrente
		//======================================================================================================================
        If ! Empty(_cAliasAve)
           If Select(_cAliasAve) > 0  
              (_cAliasAve)->( DBCloseArea() )
           EndIf
		EndIf 

		_cAliasAve := GetNextAlias()  
		
		FWMsgRun( , {||  ROMS030QRY( _cAliasAve , 6 , "" ,  _aGerente[x,1] )  }, 'Aguarde!',"Filtrando duplicatas a vencer para " + _cTituloRep+ '-' +  _cCodRepSA3 + "..."    )
		
		//================================================================================
		// Verifica as comissoes pagas do vendedor corrente.
		//================================================================================
		_aComisPg := ROM030COM( _aGerente[x,1] , _cAliasPg )
		
		//=======================================================================================================================
		// Cabecalho de dados HISTORICO FINANCEIRO - DUPLICATAS A VENCER
		//=======================================================================================================================
		ROMS30RCB2(_aDupVenc[1,1],_aDupVenc[1,3],_aDupVenc[1,5],_aDupVenc[1,7],_aDupVenc[1,2],_aDupVenc[1,4],_aDupVenc[1,6],_aDupVenc[1,8],_aComisPg[1,1],_aComisPg[2,1],_aComisPg[3,1],_aComisPg[1,2],_aComisPg[2,2],_aComisPg[3,2],_cAliasAve)
		
        //======================================================================================================================
	    // Filtrando o historico de vendas de vendedores.
	    //======================================================================================================================
        If ! Empty(_cAliasVHi)
           If Select(_cAliasVHi) > 0  
              (_cAliasVHi)->( DBCloseArea() )
           EndIf
		EndIf 

	    _cAliasVHi := GetNextAlias()   
	
	    FWMsgRun( , {||  ROMS030QRY( _cAliasVHi , 5 , "" ,  _aGerente[x,1] , _cFilGer, "" )  }, 'Aguarde!', "Filtrando historico de vendas para " + _cTituloRep+ '-' +  _cCodRepSA3 + "..."  )
	    
	    //======================================================================================================================
		// Verifica o historico de vendas do vendedor corrente
		//======================================================================================================================
		_aHistVend := ROMS030HVD(  _aGerente[x,1] , _cAliasVHi )  
	
		//======================================================================================================================
		// Verifica as vendas do vendedor corrente no mes de fechamento indicado agrupando os dados por 
		// sub-grupo de produto
		//======================================================================================================================
		_aVendaHis := {}
        If _cTipoRepSA3 == 'V'
		   _aVendaHis := ROMS030VNM(  _aGerente[x,1])  
		EndIf
				
		//=======================================================================================================================
		// Cabecalho de dados do HISTORICO DE VENDAS com vendas do mês ou dados relacionais conforme tipo vendedor
		//=======================================================================================================================
		ROMS30RCB3(_aHistVend[1,1],_aHistVend[2,1],_aHistVend[3,1],_aHistVend[4,1],_aHistVend[1,2],_aHistVend[2,2],_aHistVend[3,2],_aHistVend[4,2],_aVendaHis,2)
		
		//================================================================================
		// Seleciona os dados da COMISSAO A PAGAR do mes de fechamento do Gerente
		//================================================================================
		//_aDadosCom := ROMS030CPA( _aGerente[x,1] , _aComissao )
		
		//================================================================================
		// Imprime os dados da COMISSAO A PAGAR do mes de fechamento do vendedor corrente
		//================================================================================
		ROMS30RCOM( _aDadosCom , 2 , _aGerente[x,1] )
		
		//================================================================================
		// Imprime as assinaturas.
		//================================================================================
		ROMS30RASI() 
	  
	Next x
	  	      
	//================================================================================
	// Finaliza as area criadas anteriormente
	//================================================================================
	(_cAliasPg)->(DBCloseArea())
	
EndIf

If ! Empty(_cAliasPg) 
   If Select(_cAliasPg) > 0  
      (_cAliasPg)->( DBCloseArea() )
   EndIf
EndIf   

If ! Empty(_cAliasDup)
   If Select(_cAliasDup) > 0  
      (_cAliasDup)->( DBCloseArea() )
   EndIf
EndIf 

If ! Empty(_cAliasAve)
   If Select(_cAliasAve) > 0  
      (_cAliasAve)->( DBCloseArea() )
   EndIf
EndIf 

If ! Empty(_cAliasVHi)
   If Select(_cAliasVHi) > 0  
      (_cAliasVHi)->( DBCloseArea() )
   EndIf
EndIf 

Return

/*
===============================================================================================================================
Programa----------: ROMS30RCNI
Autor-------------: Julio de Paula Paz
Data da Criacao---: 04/11/2022
Descrição---------: Rotina para impressão dos dados das vendas e do fechamento do mês atual
                    Nova versão de impressão utilizando a ferramenta FWMSPRINTER() e substituição da ferramenta TMSPRINTER(),
					Descontinuada pela Totvs.
Parametros--------: _aHisPag : Array contendo os dados de pagamento dos três ultímos meses
Retorno-----------: _nRet = O valor total liquido de comissão a pagar.
===============================================================================================================================
*/
Static Function ROMS30RCNI( _aComissao , _cTipo , _cCodGer ) 
Local _nRet := 0
Local _aImpostos	:= {}

Local _nTotBruto	:= 0
Local _nINSS		:= 0
Local _nIRRF		:= 0
Local _nTotLiqui	:= 0

Local _cTpComis		:= "" 
Local _nVlrDebCo	:= 0   
Local _nVlrDevol	:= 0
Local _nTotDevol    := 0

Local _nTotReceb	:= 0
Local _nTotComis	:= 0
Local _nTotBonif	:= 0
Local _nTotCmBnf	:= 0
Local y , _nI

Local _aTotBNF := {}


Begin Sequence 
   //================================================================================
   // Verifica a necessidade de quebra de pagina
   //================================================================================
   For y:=1 to Len(_aComissao)

	   //================================================================================
	   // Verifica se o tipo da comissao gerado eh diferente de debito
	   //================================================================================
	   If _aComissao[y,5] <> 'D'
 	
		  If _cTpComis <> _aComissao[y,5]
		     
			 //================================================================================
			 // Fecha o box criado anteriormente e imprime totalizador
			 //================================================================================
			 If !Empty(_cTpComis)
			
				//================================================================================
				// Imprime a comissão adicional por venda de leite Magro
				//================================================================================
				If _cTpComis == 'A'
				
				   _aTotCAD := ROMS030CAD( _cCodGer )
					
				   If _aTotCAD[04] > 0
					
					  _nTotComis	+= _aTotCAD[04]
					  _nTotBruto	+= _aTotCAD[04]
					
				   EndIf
				
				EndIf
			    
				//================================================================================
				// Seta variaves do totalizador por tipo de comissao do Gerente
				//================================================================================
				_nTotReceb := 0
				_nTotComis := 0
			
			 EndIf
			
			
		  EndIf
		
		  _nTotReceb	+= Round(_aComissao[y,2],2)
		  _nTotComis	+= Round(_aComissao[y,3],2)
		  _nTotBruto  += Round(_aComissao[y,3],2)
		
		  _cTpComis	:= _aComissao[y,5]
	
	      //================================================================================
	      // Calcula o valor de debito da comissão
	      //================================================================================
	   Else
	
		  _nVlrDebCo += Round(_aComissao[y,3],2)
		  _nVlrDevol += Round(_aComissao[y,6],2)
		  _nTotDevol += Round(_aComissao[y,2],2)
	
	   EndIf

   Next y

   //================================================================================
   //Calcula o desconto de comissão por bonificação
   //================================================================================
   FWMsgRun(, {|| _aTotBNF := ROMS030BNF( _cCodGer ) }, "Aguarde... ", 'Filtrando bonificações para ' + _cTitCargo + ' ' + StrZero(_nni,6) + " de " + StrZero(_ntoti,6) + "..." )

   If !Empty( _aTotBNF )
  	
	  For _nI := 1 To Len(_aTotBNF)
    	  _nTotComis	+= Round(_aTotBNF[_nI][03],2)
		  _nTotCmBnf	+= Round(_aTotBNF[_nI][03],2)
		  _nTotBonif	+= Round(_aTotBNF[_nI][02],2)
	
	  Next _nI

   EndIf

   If !Empty( _aTotBNF ) 
 	
	  _nVlrDebCo	+= _nTotCmBnf

   EndIf

   If _nVlrDevol <> 0  
 	
	  _nVlrDebCo	+= _nVlrDevol

   EndIf

   //================================================================================
   // Verifica quebra de pagina
   //================================================================================

   _nTotLiqui := Round(_nTotBruto,2) + Round(_nVlrDebCo,2) 

   _nTotComis := _nTotLiqui
   _nTotReceb := _nTotReceb - _nTotBonif - _nTotDevol

   //================================================================================
   // Efetua o calculo dos Impostos do vendedor como: INSS e IRRF.
   //================================================================================
   _aImpostos := {} 
   If Val(_aComissao[1,4]) > 0 .Or. _nTotLiqui > 0  
      _aImpostos := U_C_IRRF_INSS( _aComissao[1,4] , _nTotLiqui )
   Else
      aAdd(_aImpostos, {0,0})  
   EndIf

   _nINSS := Round(_aImpostos[1,1],2)
   _nIRRF := Round(_aImpostos[1,2],2)

   _nTotLiqui -= ( _nINSS + _nIRRF )

   _nRet := _nTotLiqui

End Sequence 

Return _nRet

/*
===============================================================================================================================
Programa----------: ROMS30RCAB
Autor-------------: Julio de Paula Paz
Data da Criacao---: 08/11/2022
Descrição---------: Rotina para impressão dos cabeçalhos do relatório
Parametros--------: _lImpNPG : define se deve imprimir o número da página (.T./.F.)
------------------: _cTipo   : descrição do Tipo de Extrato que está sendo impresso
Retorno-----------: Nenhum
===============================================================================================================================
*/

Static Function ROMS30RCAB( _lImpNPG )

Local _cPath	:= If( IsSrvUnix() , "/" , "\" )
Local _cTitulo	:= "Pagamento de Comissão - "+ IIF( !Empty(MV_PAR01) , MesExtenso( Val( SubStr( MV_PAR01 , 1 , 2 ) ) ) + '/' + SubStr( MV_PAR01 , 3 , 4 ) , "" )
Local _cTitulo2	:= ""
Local _nLetras  := 0

If MV_PAR09 == 'Analitico'  // 1  // 'Analitico'  ,'Previa-Sintetic','Excel', 'Impresso Novo'
   _cTitulo	:= "Pagamento de Comissão - "+ IIF( !Empty(_cMvMesAno) , MesExtenso( Val( SubStr( _cMvMesAno , 1 , 2 ) ) ) + '/' + SubStr( _cMvMesAno , 3 , 4 ) , "" )
Else
   If MV_PAR01 == MV_PAR02
      _cTitulo	:= "Pagamento de Comissão - "+ IIF( !Empty(MV_PAR01) , MesExtenso( Val( SubStr( MV_PAR01 , 1 , 2 ) ) ) + '/' + SubStr( MV_PAR01 , 3 , 4 ) , "" )
   Else
      _cTitulo	:= "Pagamento de Comissão - "+ IIF( !Empty(MV_PAR01) , MesExtenso( Val( SubStr( MV_PAR01 , 1 , 2 ) ) ) + '/' + SubStr( MV_PAR01 , 3 , 4 ) , "" )
	  _cTitulo  += " Até " +IIF( !Empty(MV_PAR02) , MesExtenso( Val( SubStr( MV_PAR02 , 1 , 2 ) ) ) + '/' + SubStr( MV_PAR02 , 3 , 4 ) , "" )
   EndIf 	
EndIf 

If _cTitCargo == "Repres/Superv/Coord/Geren/Geren Nac" // "Representante/Supervisor/Coordenador/Gerente" 

	_cTitulo2 := "Extrato dos " + _cTitCargo "

Else

	_cTitulo2 := "Extrato do " + _cTitCargo + " - " + _ccodi + " - " + Posicione("SA3",1,xFilial("SA3")+_ccodi,"A3_NOME")
	
EndIf

_nPosLin := 0100

_oPrint:SayBitmap( _nPosLin , _nColIni , _cPath +'system/lgrl01.bmp' , 250 , 100 )

If _lImpNPG
	_oPrint:Say( _nPosLin		, _nColFim - 600 , "ROMS030 - PÁGINA: " + cValToChar( _nNumPag )										, _oFont12b )
Else
	_oPrint:Say( _nPosLin		, _nColFim - 600 , "ROMS030"					   										, _oFont12b )
EndIf

_oPrint:Say( _nPosLin + 050		, _nColFim - 600 , "DATA DE EMISSÃO: "+ DToC( Date() )										, _oFont12b )

_nPosLin += 050

_nLetras := Len(_cTitulo) / 2
_nLetras *= 14 //10

_oPrint:Say( _nPosLin , _nColFim / 2 - 200 - _nLetras , _cTitulo		, _oFont15b , _nColFim ,,, 2 )
_nPosLin += _nSpcLin

_nLetras := Len(_cTitulo2) / 2
_nLetras *= 14 //10

_oPrint:Say( _nPosLin , _nColFim / 2 - 200 -_nLetras , _cTitulo2	, _oFont15b , _nColFim ,,, 2 )

_nPosLin+=_nSpcLin 
_nPosLin+=_nSpcLin        

_oPrint:Line(_nPosLin,_nColIni,_nPosLin,_nColFim) 

Return

/*
===============================================================================================================================
Programa----------: ROMS030RIPP
Autor-------------: Julio de Paula Paz
Data da Criacao---: 08/11/2022
Descrição---------: Rotina para impressão da página de parâmetros do relatório
Parametros--------: _oPrint - Objeto do Relatório.
                    _nLinAdic = Numero de linhas adicionais.
Retorno-----------: Nenhum
===============================================================================================================================
*/

Static Function ROMS030RIPP( _oPrint, _nLinAdic)
Local _cTipoRepres
Local _cTipoRel := ""

Default _nLinAdic := 0

//================================================================================
// Inicia uma nova página
//================================================================================   
//_oPrint:StartPage()  

_nPosLin	+= 080  + _nLinAdic
_oPrint:Line( _nPosLin , _nColIni , _nPosLin , _nColFim )
_nPosLin	+= 060
		
//================================================================================
// Imprime o parametro e a resposta
//================================================================================
_oPrint:Say( _nPosLin , _nColIni + 010 , "Mes/Ano Inicial?" , _oFont14b )
_oPrint:Say( _nPosLin , _nColIni + 900 , MV_PAR01			, _oFont14b )
_nPosLin += 80
_oPrint:Say( _nPosLin , _nColIni + 010 , "Mes/Ano Final?"	, _oFont14b )
_oPrint:Say( _nPosLin , _nColIni + 900 , MV_PAR02			, _oFont14b )
_nPosLin += 80
_oPrint:Say( _nPosLin , _nColIni + 010 , "Gerente Nacional?", _oFont14b )
_oPrint:Say( _nPosLin , _nColIni + 900 , MV_PAR03			, _oFont14b )
_nPosLin += 80
_oPrint:Say( _nPosLin , _nColIni + 010 , "Gerente ?"	    , _oFont14b )
_oPrint:Say( _nPosLin , _nColIni + 900 , MV_PAR04			, _oFont14b )
_nPosLin += 80
_oPrint:Say( _nPosLin , _nColIni + 010 , "Coordenador ?"	, _oFont14b )
_oPrint:Say( _nPosLin , _nColIni + 900 , MV_PAR05			, _oFont14b )
_nPosLin += 80
_oPrint:Say( _nPosLin , _nColIni + 010 , "Supervisor ?"	, _oFont14b )
_oPrint:Say( _nPosLin , _nColIni + 900 , MV_PAR06			, _oFont14b )
_nPosLin += 80
_oPrint:Say( _nPosLin , _nColIni + 010 , "Representantes ?"	, _oFont14b )
_oPrint:Say( _nPosLin , _nColIni + 900 , MV_PAR07			, _oFont14b )
_nPosLin += 80
_oPrint:Say( _nPosLin , _nColIni + 010 , "Traz Hierarquia?"	, _oFont14b )
_oPrint:Say( _nPosLin , _nColIni + 900 , IIf(MV_PAR08=="Sim","SIM","NÃO"), _oFont14b )
_nPosLin += 80
If MV_PAR09 == 'Analitico' //1 // 'Analitico'  ,'Previa-Sintetic','Excel', 'Impresso Novo'
   _cTipoRel := "ANALITICO"
ElseIf MV_PAR09 == 'Previa-Sintetic' // 2 // 'Analitico'  ,'Previa-Sintetic','Excel', 'Impresso Novo'
   _cTipoRel := "SINTETICO"
Else
   _cTipoRel := "ANALITICO-IMPRESSO NOVO"
EndIf 

_oPrint:Say( _nPosLin , _nColIni + 010 , "Tipo de Relatorio?"	, _oFont14b )
_oPrint:Say( _nPosLin , _nColIni + 900 , _cTipoRel, _oFont14b )

If MV_PAR10 == 'Interno CLT' // 1
   _cTipoRepres := "Interno CLT
ElseIf MV_PAR10 == 'Externo PJ' // 2
   _cTipoRepres := "Externo PJ"
Else 
   _cTipoRepres := "Ambos"
EndIf

_nPosLin += 80
_oPrint:Say( _nPosLin , _nColIni + 010 , "Tipo Representante?"	, _oFont14b )
_oPrint:Say( _nPosLin , _nColIni + 900 , _cTipoRepres, _oFont14b ) 
_nPosLin += 80

//================================================================================
// Finaliza a Página
//================================================================================
_oPrint:Line( _nPosLin , _nColIni , _nPosLin , _nColFim )
_oPrint:EndPage()

Return

/*
===============================================================================================================================
Programa----------: ROMS030QBR
Autor-------------: Julio de Paula Paz
Data da Criacao---: 08/11/2022
Descrição---------: Função para quebras de página do relatório
Parametros--------: _cTipoExtr - Configurção de cabeçalho da nova página
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS30RQBR()

_oPrint:EndPage()		// Finaliza a Pagina.
_oPrint:StartPage()		//Inicia uma nova Pagina

_nNumPag++

ROMS30RCAB( .T. ) //Chama impressão do cabecalho

_nPosLin += _nSpcLin
_nPosLin += _nSpcLin

Return

/*
===============================================================================================================================
Programa----------: ROMS30RCIC
Autor-------------: Julio de Paula Paz
Data da Criacao---: 08/11/2022
Descrição---------: Rotina para impressão do cabeçalhos de informações cadastrais
Parametros--------: _cCodigo : Código do Vendedor
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS30RCIC( _cCodigo )

Local _cAlias		:= GetNextAlias() 
Local _cNome		:= ""
Local _cEmail		:= ""
Local _cGerente		:= ""
Local _cCGC			:= ""
Local _cBanco		:= ""
Local _cAgencia		:= ""
Local _cConta		:= ""
Local _cCodOper		:= "" 
Local _cNomeFav		:= ""  
Local _cCPFCNPJF	:= ""

Local _cNomeF		:= "" 
Local _cRegis		:= "" 
Local _cGerNac      := ""
Local _nLetras      := 0
Local _cTitulo      := ""
//================================================================================
// Chama a rotina que monta a área temporária com os dados referentes ao Vendedor
//================================================================================
FWMsgRun( , {||  ROMS030QRY( _cAlias , 4 , "" , _cCodigo , "" , "" )  }, 'Aguarde...', 'Filtrando dados do ' + _cTitCargo + ' ' +  StrZero(_nni,6) + " de " + StrZero(_ntoti,6) + "..." )

DBSelectArea( _cAlias )
(_cAlias)->( DBGoTop() )

If (_cAlias)->( !Eof() )
	_cNome		:= (_cAlias)->A3_NOME
	_cEmail		:= (_cAlias)->A2_EMAIL
	_cCGC		:= (_cAlias)->A2_CGC
	_cBanco		:= (_cAlias)->A2_BANCO
	_cAgencia	:= (_cAlias)->A2_AGENCIA
	_cConta		:= (_cAlias)->A2_NUMCON
	_cCodOper	:= (_cAlias)->A2_I_CODOP 
	_cNomeFav	:= (_cAlias)->A2_I_NOMFD
	_cCPFCNPJF	:= (_cAlias)->A2_I_CGCFD
	_cNomeF		:= (_cAlias)->A3_I_NOMEF
	_cRegis		:= (_cAlias)->A3_I_REGIS

EndIf

_cCGC		:= IIf( Len( AllTrim( _cCGC			) ) == 11 , Transform( _cCGC		, "@R 999.999.999-99" ) , Transform( _cCGC		, "@R! NN.NNN.NNN/NNNN-99" ) )
_cCPFCNPJ	:= IIf( Len( AllTrim( _cCPFCNPJF	) ) == 11 , Transform( _cCPFCNPJF	, "@R 999.999.999-99" ) , Transform( _cCPFCNPJF	, "@R! NN.NNN.NNN/NNNN-99" ) )

(_cAlias)->( DBCloseArea() )

//_nLinBox := _nPosLin
_nLinBoxIni := _nPosLin
_nLinBoxFin := _nPosLin
//-----------------------------
If _cTitCargo == "Gerente" .Or. _cTitCargo == "Coordenador"
   	
	
	//_nPosLin += _nSpcLin 9
	//_nPosLin += _nSpcLin 10
_nLinBoxFin += ( _nPosLin * 10)
ElseIf _cTitCargo == "Supervisor"

    
	//_nPosLin += _nSpcLin 9
	//_nPosLin += _nSpcLin 10 
	//_nPosLin += _nSpcLin 11
	_nLinBoxFin += ( _nPosLin * 11)

ElseIf _cTitCargo == "Representante"
	
	//_nPosLin += _nSpcLin 9
	//_nPosLin += _nSpcLin 10
	//_nPosLin += _nSpcLin 11
	//_nPosLin += _nSpcLin 12
	_nLinBoxFin += ( _nPosLin * 12)
	
EndIf

//_nLinBoxFin -= ( _nPosLin * 2)

If _nLinBoxFin > _nLimPag
   _nLinBoxFin := _nLimPag
EndIf

_oPrint:Box( _nLinBoxIni , _nColIni , _nLinBoxFin , _nColFim ) 

_cTitulo := 'Informações Cadastrais'
_nLetras := Len(_cTitulo) / 2 
_nLetras *= 10

//-----------------------------
_oPrint:Say( _nPosLin + 30, _nColFim / 2 - 200 - _nLetras, _cTitulo , _oFont16b , _nColFim ,,, 2 )

_nPosLin += _nSpcLin
_nPosLin += _nSpcLin

_oPrint:Say( _nPosLin + _nAjsLin	, _nColIni + 0020 , "Nome.......:"			, _oFont11b )
_oPrint:Say( _nPosLin				, _nColIni + 0260 , SubStr(_cNome,1,44)		, _oFont14b )

_oPrint:Say( _nPosLin + _nAjsLin	, _nColIni + 1300 , "Banco.....:"			, _oFont11b )
_oPrint:Say( _nPosLin + _nAjsLin	, _nColIni + 1550 , _cBanco					, _oFont11  )

_nPosLin += _nSpcLin

_oPrint:Say( _nPosLin + _nAjsLin	, _nColIni + 0020 , "CPF/CNPJ...:"			, _oFont11b )
_oPrint:Say( _nPosLin + _nAjsLin	, _nColIni + 0260 , _cCGC					, _oFont11  )

_oPrint:Say( _nPosLin + _nAjsLin	, _nColIni + 1300 , "Agencia...:"			, _oFont11b )
_oPrint:Say( _nPosLin + _nAjsLin	, _nColIni + 1550 , _cAgencia				, _oFont11  )

_nPosLin += _nSpcLin

_oPrint:Say( _nPosLin + _nAjsLin	, _nColIni + 0020 , "E-mail.....:"			, _oFont11b )
_oPrint:Say( _nPosLin + _nAjsLin	, _nColIni + 0260 , _cEmail					, _oFont11  )


_oPrint:Say( _nPosLin + _nAjsLin	, _nColIni + 1300 , "Conta.....:"			, _oFont11b )
_oPrint:Say( _nPosLin + _nAjsLin	, _nColIni + 1550 , _cConta					, _oFont11  )

If !Empty(_cCodOper) 

_oPrint:Say( _nPosLin + _nAjsLin	, _nColIni + 1730 , "Cod. Operação:"		, _oFont11b )
_oPrint:Say( _nPosLin + _nAjsLin	, _nColIni + 2060 , _cCodOper				, _oFont11  )

EndIf

_nPosLin += _nSpcLin

_oPrint:Say( _nPosLin + _nAjsLin	, _nColIni + 0020 , "Nome Fant.:"			, _oFont11b )
_oPrint:Say( _nPosLin				, _nColIni + 0260 , SubStr(_cnomeF,1,44)		, _oFont11 )

_oPrint:Say( _nPosLin + _nAjsLin	, _nColIni + 1300 , "Favorecido:"			, _oFont11b )
_oPrint:Say( _nPosLin + _nAjsLin	, _nColIni + 1550 , SubStr(_cNomeFav,1,29)	, _oFont11  )

_nPosLin+=_nSpcLin
                              
_oPrint:Say( _nPosLin + _nAjsLin	, _nColIni + 1300 , "CPF/CNPJ..:"			, _oFont11b )
_oPrint:Say( _nPosLin + _nAjsLin	, _nColIni + 1550 , _cCPFCNPJ				, _oFont11  )

_oPrint:Say( _nPosLin + _nAjsLin	, _nColIni + 0020 , "Regiões...:"			, _oFont11b )
_oPrint:Say( _nPosLin				, _nColIni + 0260 , SubStr(_cRegis,1,44)		, _oFont11 )

_nPosLin+=_nSpcLin

_oPrint:Say( _nPosLin				, _nColIni + 0260 , SubStr(_cRegis,45,44)		, _oFont11 )

_nPosLin += _nSpcLin


_cgerente := ""
_ccoord := ""
_csuper := ""
_cGerNac := ""

SA3->(DBSetOrder(1))
If SA3->(DBSeek(xFilial("SA3")+_cCodigo))

_cgerente := SA3->A3_GEREN 
_ccoord   := SA3->A3_SUPER
_csuper   := SA3->A3_I_SUPE
_cGerNac  := SA3->A3_I_GERNC 

    If SA3->(DBSeek(xFilial("SA3")+_cGerNac))
	
	   _cGerNac := _cGerNac +  " - " + SA3->A3_NOME
		
	EndIf

	If SA3->(DBSeek(xFilial("SA3")+_cgerente))
	
		_cgerente := _cgerente +  " - " + SA3->A3_NOME
		
	EndIf
	
	If SA3->(DBSeek(xFilial("SA3")+_ccoord))
	
		_ccoord := _ccoord +  " - " + SA3->A3_NOME
		
	EndIf
	
	If SA3->(DBSeek(xFilial("SA3")+_csuper))
	
		_csuper := _csuper +  " - " + SA3->A3_NOME
		
	EndIf

EndIf	

If _cTitCargo == "Gerente"
   	_oPrint:Say( _nPosLin + _nAjsLin	, _nColIni + 0020 , "Gerente Nacional...:"			, _oFont11b )
	_oPrint:Say( _nPosLin + _nAjsLin	, _nColIni + 0340 , _cGerNac					, _oFont11  )
	
	_nPosLin += _nSpcLin
	_nPosLin += _nSpcLin

ElseIf _cTitCargo == "Coordenador"
    
	_oPrint:Say( _nPosLin + _nAjsLin	, _nColIni + 0020 , "Gerente Nacional...:"			, _oFont11b )
	_oPrint:Say( _nPosLin + _nAjsLin	, _nColIni + 0340 , _cGerNac					, _oFont11  )


	_oPrint:Say( _nPosLin + _nAjsLin +_nSpcLin	, _nColIni + 0020 , "Gerente...:"			, _oFont11b )
	_oPrint:Say( _nPosLin + _nAjsLin + _nSpcLin	, _nColIni + 0260 , _cgerente					, _oFont11  )
	
	_nPosLin += _nSpcLin
	_nPosLin += _nSpcLin

ElseIf _cTitCargo == "Supervisor"

    _oPrint:Say( _nPosLin + _nAjsLin	, _nColIni + 0020 , "Gerente Nacional...:"			, _oFont11b )
	_oPrint:Say( _nPosLin + _nAjsLin	, _nColIni + 0340 , _cGerNac					, _oFont11  )

	_oPrint:Say( _nPosLin + _nAjsLin + _nSpcLin	, _nColIni + 0020 , "Gerente...:"			, _oFont11b )
	_oPrint:Say( _nPosLin + _nAjsLin + _nSpcLin	, _nColIni + 0260 , _cgerente					, _oFont11  )

	_oPrint:Say( _nPosLin + _nAjsLin + _nSpcLin + _nSpcLin	, _nColIni + 0020 , "Coord....:"			, _oFont11b )
	_oPrint:Say( _nPosLin + _nAjsLin + _nSpcLin	+ _nSpcLin  , _nColIni + 0260 , _ccoord					, _oFont11  )
	
	_nPosLin += _nSpcLin
	_nPosLin += _nSpcLin
	_nPosLin += _nSpcLin

ElseIf _cTitCargo == "Representante"

    _oPrint:Say( _nPosLin + _nAjsLin	, _nColIni + 0020 , "Gerente Nacional...:"			, _oFont11b )
	_oPrint:Say( _nPosLin + _nAjsLin	, _nColIni + 0340 , _cGerNac					, _oFont11  )

	_oPrint:Say( _nPosLin + _nAjsLin + _nSpcLin	, _nColIni + 0020 , "Gerente...:"			, _oFont11b )
	_oPrint:Say( _nPosLin + _nAjsLin + _nSpcLin	, _nColIni + 0260 , _cgerente					, _oFont11  )

	_oPrint:Say( _nPosLin + _nAjsLin + _nSpcLin + _nSpcLin	, _nColIni + 0020 , "Coord.....:"			, _oFont11b )
	_oPrint:Say( _nPosLin + _nAjsLin + _nSpcLin + _nSpcLin	, _nColIni + 0260 , _ccoord					, _oFont11  )

	_oPrint:Say( _nPosLin + _nAjsLin + _nSpcLin	+ _nSpcLin + _nSpcLin , _nColIni + 0020 , "Superv...:"			, _oFont11b )
	_oPrint:Say( _nPosLin + _nAjsLin + _nSpcLin	+ _nSpcLin + _nSpcLin , _nColIni + 0260 , _csuper					, _oFont11  )
	
	_nPosLin += _nSpcLin
	_nPosLin += _nSpcLin
	_nPosLin += _nSpcLin
	_nPosLin += _nSpcLin
	
EndIf

//_oPrint:Box( _nLinBox , _nColIni , _nPosLin + _nSpcLin , _nColFim ) 

_nPosLin += _nSpcLin
//_nPosLin += _nSpcLin 

Return

/*
===============================================================================================================================
Programa----------: ROMS30RCB2
Autor-------------: Fabiano Dias
Data da Criacao---: 31/03/2011
Descrição---------: Função para imprimir o cabeçalho do histórico financeiro
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS30RCB2( _nqtdeDup1 , _nqtdeDup2 , _nqtdeDup3 , _nqtdeDup4 , _nVlrVenc1 , _nVlrVenc2 , _nVlrVenc3 , _nVlrVenc4 , _cMes1 , _cMes2 , _cMes3 , _nVlrComi1 , _nVlrComi2 , _nVlrComi3 , _cAliasAve )

Local nLinInBox2
Local nLinBoxAux
Local _aMesesDup
Local _aMes			:= {"Janeiro","Fevereiro","Março","Abril","Maio","Junho","Julho","Agosto","Setembro","Outubro","Novembro","Dezembro"}
Local _cTitulo := ""
Local _nLetras := 0
Local _nLinBoxIni := 0
Local _nLinBoxFin := 0

//nLinInBox := _nPosLin
_nLinBoxIni := _nPosLin
_nLinBoxFin := _nPosLin
_nLinBoxFin += (_nPosLin * 17)

If _nLinBoxFin > _nLimPag
   _nLinBoxFin := _nLimPag
EndIf

_oPrint:Box( _nLinBoxIni , _nColIni , _nLinBoxFin , _nColFim )

_cTitulo := 'Histórico Financeiro - Duplicatas Vencidas'
_nLetras := Len(_cTitulo) / 2
_nLetras *= 10

_oPrint:Say( _nPosLin + 30 , _nColFim / 2 - 200 - _nLetras , _cTitulo , _oFont16b , _nColFim ,,, 2 )

_nPosLin += _nSpcLin
_nPosLin += _nSpcLin	 

nLinBoxAux := _nPosLin

_oPrint:Say( _nPosLin  , _nColIni + 0010 , "Período"          , _oFont11b )
_oPrint:Say( _nPosLin  , _nColIni + 0760 , "Até 15 dias"      , _oFont11b )
_oPrint:Say( _nPosLin  , _nColIni + 1070 , "De 16 a 30 dias"  , _oFont11b )
_oPrint:Say( _nPosLin  , _nColIni + 1460 , "De 31 a 60 dias"  , _oFont11b )
_oPrint:Say( _nPosLin  , _nColIni + 1800 , "Acima de 60 dias" , _oFont11b )

_nPosLin += _nSpcLin

_oPrint:Say( _nPosLin  , _nColIni + 0010 , "Quantidade de duplicatas"					, _oFont11b )
_oPrint:Say( _nPosLin  , _nColIni + 0780 , Transform(_nqtdeDup1,"@E 999999999")		, _oFont11b  )
_oPrint:Say( _nPosLin  , _nColIni + 1170 , Transform(_nqtdeDup2,"@E 999999999")		, _oFont11b  )
_oPrint:Say( _nPosLin  , _nColIni + 1550 , Transform(_nqtdeDup3,"@E 999999999")		, _oFont11b  )
_oPrint:Say( _nPosLin  , _nColIni + 1910 , Transform(_nqtdeDup4,"@E 999999999")		, _oFont11b  )

_nPosLin += _nSpcLin

_oPrint:Say( _nPosLin  , _nColIni + 0010 , "Valores vencidos"							, _oFont11b )
_oPrint:Say( _nPosLin  , _nColIni + 0700 , Transform(_nVlrVenc1,"@E 999,999,999.99")	, _oFont11b  )
_oPrint:Say( _nPosLin  , _nColIni + 1100 , Transform(_nVlrVenc2,"@E 999,999,999.99")	, _oFont11b  )
_oPrint:Say( _nPosLin  , _nColIni + 1480 , Transform(_nVlrVenc3,"@E 999,999,999.99")	, _oFont11b  )
_oPrint:Say( _nPosLin  , _nColIni + 1840 , Transform(_nVlrVenc4,"@E 999,999,999.99")	, _oFont11b  )

_nPosLin += _nSpcLin
//_nPosLin += _nSpcLin 

_cTitulo := 'Histórico Financeiro - Duplicatas a Vencer'
_nLetras := Len(_cTitulo) / 2
_nLetras *= 10

_oPrint:Say( _nPosLin + 30  , _nColFim / 2 - 200 - _nLetras , _cTitulo , _oFont16b , _nColFim ,,, 2 )
_oPrint:Line( _nPosLin , _nColIni , _nPosLin , _nColFim )

_nPosLin += _nSpcLin
_nPosLin += _nSpcLin

//====================================================================================================
// Seleciona os proximos tres meses de acordo com a data fornecida pelo usuario.
//====================================================================================================
If MV_PAR09 ==  'Analitico' // 1 // 'Analitico'  ,'Previa-Sintetic','Excel', 'Impresso Novo'
   _aMesesDup := ROMS030S3M( Val( SubStr(_cMvMesAno , 1 , 2 ) ) , Val( SubStr( _cMvMesAno, 3 , 4 ) ) , 2 )
Else 
   _aMesesDup := ROMS030S3M( Val( SubStr( MV_PAR01 , 1 , 2 ) ) , Val( SubStr( MV_PAR01 , 3 , 4 ) ) , 2 )
EndIf 

DBSelectArea(_cAliasAve)
(_cAliasAve)->( DBGoTop() )

/*
_oPrint:Say( _nPosLin  , _nColIni + 10	, "Período"									, _oFont11b						)
_oPrint:Say( _nPosLin  , 0930			, PadL(_aMes[Val(_aMesesDup[2])],10," ")	, _oFont11b , 1200      ,,, 2	)
_oPrint:Say( _nPosLin  , 1330			, PadL(_aMes[Val(_aMesesDup[3])],10," ")	, _oFont11b , 1590      ,,, 2	)
_oPrint:Say( _nPosLin  , 1740			, PadL(_aMes[Val(_aMesesDup[4])],10," ")	, _oFont11b , 1980      ,,, 2	)
_oPrint:Say( _nPosLin  , 2070			, PadL("Demais Meses",12," ")				, _oFont11b , _nColFim ,,, 2	)
*/

_oPrint:Say( _nPosLin  , _nColIni + 10	  , "Período"									, _oFont11b						)
_oPrint:Say( _nPosLin  , _nColIni + 0750  , PadL(_aMes[Val(_aMesesDup[2])],10," ")	, _oFont11b , 1200      ,,, 2	)
_oPrint:Say( _nPosLin  , _nColIni + 1170  , PadL(_aMes[Val(_aMesesDup[3])],10," ")	, _oFont11b , 1590      ,,, 2	)
_oPrint:Say( _nPosLin  , _nColIni + 1500  , PadL(_aMes[Val(_aMesesDup[4])],10," ")	, _oFont11b , 1980      ,,, 2	)
_oPrint:Say( _nPosLin  , _nColIni + 1850  , PadL("Demais Meses",12," ")				, _oFont11b , _nColFim ,,, 2	)
_nPosLin += _nSpcLin

_oPrint:Say( _nPosLin  , _nColIni + 0010 , "Quantidade de duplicatas"							, _oFont11b )
_oPrint:Say( _nPosLin  , _nColIni + 0760 , Transform((_cAliasAve)->NUMDUP01 ,"@E 999999999")	, _oFont11b  )
_oPrint:Say( _nPosLin  , _nColIni + 1180 , Transform((_cAliasAve)->NUMDUP02 ,"@E 999999999")	, _oFont11b  )
_oPrint:Say( _nPosLin  , _nColIni + 1510 , Transform((_cAliasAve)->NUMDUP03 ,"@E 999999999")	, _oFont11b  )
_oPrint:Say( _nPosLin  , _nColIni + 1880 , Transform((_cAliasAve)->NUMDUPACI,"@E 999999999")	, _oFont11b  )

_nPosLin += _nSpcLin

_oPrint:Say( _nPosLin  , _nColIni + 0010 , "Valores a vencer"										, _oFont11b )
_oPrint:Say( _nPosLin  , _nColIni + 0680 , Transform((_cAliasAve)->VENCTO01   ,"@E 999,999,999.99")	, _oFont11b  )
_oPrint:Say( _nPosLin  , _nColIni + 1100 , Transform((_cAliasAve)->VENCTO02   ,"@E 999,999,999.99")	, _oFont11b  )
_oPrint:Say( _nPosLin  , _nColIni + 1450 , Transform((_cAliasAve)->VENCTO03   ,"@E 999,999,999.99")	, _oFont11b  )
_oPrint:Say( _nPosLin  , _nColIni + 1810 , Transform((_cAliasAve)->VENCTOACIMA,"@E 999,999,999.99")	, _oFont11b  )

_nPosLin += _nSpcLin
//_nPosLin += _nSpcLin 

(_cAliasAve)->( DBCloseArea() )

_cTitulo := 'Histórico de comissões pagas'
_nLetras := Len(_cTitulo) / 2
_nLetras *= 10

_oPrint:Say( _nPosLin + 30 , _nColFim / 2 - 200 - _nLetras , _cTitulo , _oFont16b , _nColFim ,,, 2 )
_oPrint:Line( _nPosLin , _nColIni , _nPosLin , _nColFim )

_nPosLin += _nSpcLin
_nPosLin += _nSpcLin

nLinInBox2 := _nPosLin

_oPrint:Say( _nPosLin  , _nColIni + 10	, "Mês"								, _oFont11b	)
_oPrint:Say( _nPosLin  , 0790			, PadL(_aMes[Val(_cMes1)],10," ")	, _oFont11b	)
_oPrint:Say( _nPosLin  , 1320			, PadL(_aMes[Val(_cMes2)],10," ")	, _oFont11b	)
_oPrint:Say( _nPosLin  , 1790			, PadL(_aMes[Val(_cMes3)],10," ")	, _oFont11b	)

_nPosLin += _nSpcLin

_oPrint:Say( _nPosLin ,_nColIni + 0010 , "Valor da Comissão"							, _oFont11b )
_oPrint:Say( _nPosLin ,_nColIni + 0580 , Transform(_nVlrComi1,"@E 999,999,999,999.99")	, _oFont11b  )
_oPrint:Say( _nPosLin ,_nColIni + 1110 , Transform(_nVlrComi2,"@E 999,999,999,999.99")	, _oFont11b  )
_oPrint:Say( _nPosLin ,_nColIni + 1580 , Transform(_nVlrComi3,"@E 999,999,999,999.99")	, _oFont11b  )

_nPosLin += _nSpcLin

//_oPrint:Box( nLinInBox , _nColIni , _nPosLin , _nColFim )

//_nPosLin += _nSpcLin 

Return

/*
===============================================================================================================================
Programa----------: ROMS30RCB3
Autor-------------: Julio de Paula Paz
Data da Criacao---: 25/04/2018
Descrição---------: Função para imprimir o quadro do histórico de vendas
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS30RCB3( _cMes1 , _cMes2 , _cMes3 , _cMes4 , _nVlrFat1 , _nVlrFat2 , _nVlrFat3 , _nVlrFat4 , _aVendas , cTipo )
Local nLinInBox2
Local _nTotVlrBr	:= 0 
Local _cDescric		:= _cTitCargo
Local _aMes			:= {"Janeiro","Fevereiro","Março","Abril","Maio","Junho","Julho","Agosto","Setembro","Outubro","Novembro","Dezembro"}
Local _nI, _nValRec, _nValCom, _nPerc, _cNome
Local _aDadosRepres
//Local _cPeriodo 
Local _nLinBoxIni := 0
Local _nLinBoxFin := 0

nLinInBox2	:= _nPosLin
nLinInBox	:= _nPosLin

_nLinBoxIni := _nPosLin
_nLinBoxFin := _nPosLin
_nLinBoxFin += (_nPosLin * 6)

If _nLinBoxFin > _nLimPag
   _nLinBoxFin := _nLimPag
EndIf

_oPrint:Box( _nLinBoxIni , _nColIni , _nLinBoxFin , _nColFim )

//_nPosLin += _nSpcLin 
//_nLinBoxFin -= _nSpcLin 
//_nPosLin := _nLinBoxFin

_cTitulo := 'Histórico de Vendas'
_nLetras := Len(_cTitulo) / 2
_nLetras *= 10

_oPrint:Say( _nPosLin + 30	, _nColFim / 2 - 200 - _nLetras		, _cTitulo				, _oFont16b , _nColFim ,,, 2 )

_nPosLin += _nSpcLin 
_nPosLin += _nSpcLin  

_oPrint:Say( _nPosLin + _nSpcLin	, _nColIni + 10		, "Mês"								, _oFont11b )
_oPrint:Say( _nPosLin + _nSpcLin	, 0820				, PadL(_aMes[Val(_cMes1)],10," ")	, _oFont11b , 0970      ,,, 2 )
_oPrint:Say( _nPosLin + _nSpcLin	, 1210				, PadL(_aMes[Val(_cMes2)],10," ")	, _oFont11b , 1360      ,,, 2 )
_oPrint:Say( _nPosLin + _nSpcLin	, 1600				, PadL(_aMes[Val(_cMes3)],10," ")	, _oFont11b , 1710      ,,, 2 )
_oPrint:Say( _nPosLin + _nSpcLin	, 1950				, PadL(_aMes[Val(_cMes4)],10," ")	, _oFont11b , _nColFim ,,, 2 )

/*
_oPrint:Say( _nPosLin + _nSpcLin	, _nColIni + 10		, "Mês"								, _oFont11b )
_oPrint:Say( _nPosLin + _nSpcLin	, 0920				, PadL(_aMes[Val(_cMes1)],10," ")	, _oFont11b , 0970      ,,, 2 )
_oPrint:Say( _nPosLin + _nSpcLin	, 1310				, PadL(_aMes[Val(_cMes2)],10," ")	, _oFont11b , 1360      ,,, 2 )
_oPrint:Say( _nPosLin + _nSpcLin	, 1700				, PadL(_aMes[Val(_cMes3)],10," ")	, _oFont11b , 1710      ,,, 2 )
_oPrint:Say( _nPosLin + _nSpcLin	, 2050				, PadL(_aMes[Val(_cMes4)],10," ")	, _oFont11b , _nColFim ,,, 2 )
*/

_nPosLin += _nSpcLin 

_oPrint:Say( _nPosLin + _nSpcLin	, _nColIni + 0010  	, "Valor Faturado"								, _oFont11b )
_oPrint:Say( _nPosLin + _nSpcLin	, _nColIni + 0610	, Transform(_nVlrFat1,"@E 999,999,999,999.99")	, _oFont11  )
_oPrint:Say( _nPosLin + _nSpcLin	, _nColIni + 1000	, Transform(_nVlrFat2,"@E 999,999,999,999.99")	, _oFont11  )
_oPrint:Say( _nPosLin + _nSpcLin	, _nColIni + 1390	, Transform(_nVlrFat3,"@E 999,999,999,999.99")	, _oFont11  )
_oPrint:Say( _nPosLin + _nSpcLin	, _nColIni + 1740	, Transform(_nVlrFat4,"@E 999,999,999,999.99")	, _oFont11  )

_nPosLin += _nSpcLin
//_nPosLin += _nSpcLin  

//_oPrint:Box( nLinInBox , _nColIni , _nPosLin , _nColFim )

//=============================================================================================
// Incluir aqui o detalhamento de vendas do mes do representante.  
//=============================================================================================
If _cTipoRepSA3 == 'V'
   _nPosLin += _nSpcLin 
   _nPosLin += _nSpcLin 

   _nLinBoxIni := _nPosLin
   _nLinBoxFin := _nPosLin
   _nLinBoxFin += (_nPosLin * (12 + Len(_aVendas)))

   If _nLinBoxFin > _nLimPag
      _nLinBoxFin := _nLimPag + 20
   EndIf 

   _oPrint:Box( _nLinBoxIni , _nColIni , _nLinBoxFin , _nColFim )

   If MV_PAR01 == MV_PAR02
      _cTitulo := 'VENDAS DO MÊS - '+ IIF( !Empty(MV_PAR01) , _aMes[Val(SubStr(MV_PAR01,1,2))] +'/'+ SubStr(MV_PAR01,3,4),"") 
   Else 
      _cTitulo := 'VENDAS DO MÊS - '+ IIF( !Empty(MV_PAR01) , _aMes[Val(SubStr(MV_PAR01,1,2))] +'/'+ SubStr(MV_PAR01,3,4),"") + " Até "
	  _cTitulo += IIF( !Empty(MV_PAR02) , _aMes[Val(SubStr(MV_PAR02,1,2))] +'/'+ SubStr(MV_PAR02,3,4),"")
   EndIf 
   
   _nLetras := Len(_cTitulo) / 2
   _nLetras *= 10
   
   _oPrint:Say( _nPosLin + 30  , _nColFim / 2 - 200 - _nLetras , _cTitulo , _oFont16b , _nColFim ,,, 2 )
   _oPrint:Line( _nPosLin , _nColIni , _nPosLin , _nColFim )

   _nPosLin += _nSpcLin 
   _nPosLin += _nSpcLin 
   _nPosLin += _nSpcLin 

   _oPrint:Say( _nPosLin + _nSpcLin	, _nColIni + 0010	, "Grupo de Produtos"	, _oFont11b )
   _oPrint:Say( _nPosLin + _nSpcLin	, _nColIni + 0680	, "%"					, _oFont11b )
   _oPrint:Say( _nPosLin + _nSpcLin	, _nColIni + 0810	, "1a.Qtde"				, _oFont11b )
   _oPrint:Say( _nPosLin + _nSpcLin	, _nColIni + 0990	, "1a.U.M"				, _oFont11b )
   _oPrint:Say( _nPosLin + _nSpcLin	, _nColIni + 1240	, "2a. Qtde"			, _oFont11b )
   _oPrint:Say( _nPosLin + _nSpcLin	, _nColIni + 1430	, "2a.U.M"				, _oFont11b )
   _oPrint:Say( _nPosLin + _nSpcLin	, _nColIni + 1620	, "Vlr.Medio"			, _oFont11b )
   _oPrint:Say( _nPosLin + _nSpcLin	, _nColIni + 1920	, "Vlr.Total"			, _oFont11b )

   For _nI := 1 To Len(_aVendas)  
	   _nPosLin += _nSpcLin
	   
	    If (_nPosLin + _nSpcLin) > _nLimPag 
           
           _nPosLin += _nSpcLin
           
           ROMS30RQPG( 0 , .T. , .F. , "ROMS304R()" , "" , _cDescric )
          
           _nLinBox := _nPosLin
           
           _nPosLin += _nSpcLin
		   _nPosLin += _nSpcLin 
           
           _oPrint:Say( _nPosLin + _nSpcLin	, _nColIni + 0010	, "Grupo de Produtos"	, _oFont11b )
           _oPrint:Say( _nPosLin + _nSpcLin	, _nColIni + 0680	, "%"					, _oFont11b )
           _oPrint:Say( _nPosLin + _nSpcLin	, _nColIni + 0810	, "1a.Qtde"				, _oFont11b )
           _oPrint:Say( _nPosLin + _nSpcLin	, _nColIni + 0990	, "1a.U.M"				, _oFont11b )
           _oPrint:Say( _nPosLin + _nSpcLin	, _nColIni + 1240	, "2a. Qtde"			, _oFont11b )
           _oPrint:Say( _nPosLin + _nSpcLin	, _nColIni + 1430	, "2a.U.M"				, _oFont11b )
           _oPrint:Say( _nPosLin + _nSpcLin	, _nColIni + 1620	, "Vlr.Medio"			, _oFont11b )
           _oPrint:Say( _nPosLin + _nSpcLin	, _nColIni + 1920	, "Vlr.Total"			, _oFont11b )
           
           _nPosLin += _nSpcLin

        EndIf
	
	   _oPrint:Say( _nPosLin + _nSpcLin , _nColIni + 0010 , SubStr(IIf(Len(AllTrim(_aVendas[_nI,1])) == 0,'SEM GRUPO DE PRODUTOS',_aVendas[_nI,1]),1,29)									   , _oFont11 )
	   _oPrint:Say( _nPosLin + _nSpcLin , _nColIni + 0600 , Transform(_aVendas[_nI,7],"@E 999.999") 							  			  													   , _oFont11 )
	   _oPrint:Say( _nPosLin + _nSpcLin , _nColIni + 0600 , Transform(_aVendas[_nI,2],"@E 999,999,999,999.99")				  			  													   , _oFont11 )
	   _oPrint:Say( _nPosLin + _nSpcLin , _nColIni + 0990 , _aVendas[_nI,3]													  			  													   , _oFont11 )
	   _oPrint:Say( _nPosLin + _nSpcLin , _nColIni + 1040 , Transform(_aVendas[_nI,4],"@E 999,999,999,999.99")				              													   , _oFont11 )
	   _oPrint:Say( _nPosLin + _nSpcLin , _nColIni + 1430 , _aVendas[_nI,5]       											  			  													   , _oFont11 )
	   _oPrint:Say( _nPosLin + _nSpcLin , _nColIni + 1450 , IIf(_aVendas[_nI,2] > 0,Transform(_aVendas[_nI,6] / _aVendas[_nI,2],"@E 999,999,999,999.99"),TransForm(0,"@E 999,999,999,999.99")) , _oFont11 )
	   _oPrint:Say( _nPosLin + _nSpcLin , _nColIni + 1750 , Transform(_aVendas[_nI,6],"@E 999,999,999,999.99")			      			  													   , _oFont11 )
    
	   _nTotVlrBr += _aVendas[_nI,6]

   Next _nI

   //====================================================================================================
   // Imprime o totalizador valor total das vendas do Mes.
   //====================================================================================================
   _nPosLin += _nSpcLin 
   _nPosLin += _nSpcLin
     
   //_oPrint:Box( _nLinBox , _nColIni , _nPosLin , _nColFim )
      
   _nLinBox := _nPosLin
   
   _nLinBoxIni := _nPosLin
   _nLinBoxFin := _nPosLin
   _nLinBoxFin += (_nPosLin * 2 )

   If _nLinBoxFin > _nLimPag
      _nLinBoxFin := _nLimPag
   EndIf

   //_oPrint:Box( _nLinBoxIni , _nColIni , _nLinBoxFin , _nColFim )


   _oPrint:Say( _nPosLin , _nColIni + 0010 , "TOTAL"									    , _oFont11b)
   _oPrint:Say( _nPosLin , _nColIni + 1750 , Transform(_nTotVlrBr,"@E 999,999,999,999.99")	, _oFont11b )

   _nPosLin += _nSpcLin + 1

   //_oPrint:Box( _nLinBox , _nColIni , _nPosLin , _nColFim )

Else //Se não é vendedor imprime quadro relacional

	//================================================================================
	//Monta dados relacionais
	//================================================================================
	
	_nPosLin += _nSpcLin  
	
	nLinInBox := _nPosLin
	
   _nPosLin += _nSpcLin 

   _nLinBoxIni := _nPosLin
   _nLinBoxFin := _nPosLin
   _nLinBoxFin += (_nPosLin * (6 + Len(_aComGerenc)) )

   If _nLinBoxFin > _nLimPag
      _nLinBoxFin := _nLimPag //+ 20  
   EndIf 

   _oPrint:Box( _nLinBoxIni , _nColIni , _nLinBoxFin , _nColFim )

   If MV_PAR01 == MV_PAR02
	  _cTitulo := 'VENDAS DO MÊS - '+ IIF( !Empty(MV_PAR01) , _aMes[Val(SubStr(MV_PAR01,1,2))] +'/'+ SubStr(MV_PAR01,3,4),"") 
   Else 
	  _cTitulo := 'VENDAS DO MÊS - '+ IIF( !Empty(MV_PAR01) , _aMes[Val(SubStr(MV_PAR01,1,2))] +'/'+ SubStr(MV_PAR01,3,4),"") + " Até "
	  _cTitulo += IIf( !Empty(MV_PAR02) , _aMes[Val(SubStr(MV_PAR02,1,2))] +'/'+ SubStr(MV_PAR02,3,4),"")
   EndIf 
   
   _nLetras := Len(_cTitulo) / 2
   _nLetras *= 10
   
   _oPrint:Say( _nPosLin + 30 , _nColFim / 2 - 200 - _nLetras , _cTitulo , _oFont16b , _nColFim ,,, 2 )
   _oPrint:Line( _nPosLin , _nColIni , _nPosLin , _nColFim )

   _nPosLin += _nSpcLin 
   _nPosLin += _nSpcLin 

   _oPrint:Say( _nPosLin + _nSpcLin	, _nColIni + 0010	, "Representante"		, _oFont11b )
   _oPrint:Say( _nPosLin + _nSpcLin	, _nColIni + 1110	, "Valor Recebido"		, _oFont11b )
   _oPrint:Say( _nPosLin + _nSpcLin	, _nColIni + 1540	, "Valor Comissão"		, _oFont11b )
   _oPrint:Say( _nPosLin + _nSpcLin	, _nColIni + 1920	, "% Com."			, _oFont11b )
 
   _ntotv := 0
   _ntotc := 0
 
    _aComGerenc := {}

    _aDadosRepres := {0,0,0}

	FWMsgRun( , {||  _aDadosRepres := U_ROMS030J(_ccodi, _cctipvi /*, _aDadosRelac[_nI,1], _aDadosRelac[_nI,2] */)  }, 'Aguarde...', 'Lendo dados rede representante vinculados ao ' + _cTitCargo +  "..."  ) 	   
    If Len(_aDadosRepres) > 0
	  
	   For _nI := 1 To Len(_aDadosRepres)
           _nValCom := _aDadosRepres[_nI,2] 
		   _nValRec := _aDadosRepres[_nI,3] 
	       _nPerc   :=  ( _nValCom / _nValRec ) * 100
	       
		   If _nValRec <> 0 .Or. _nValCom <> 0 
		      If Empty(_aDadosRepres[_nI,1])
                 _cNome := " " 
				 If  _nValCom < 0 .And. _nValRec > 0
				     Loop 
                 EndIf
			  Else
		         _cNome := Posicione("SA3",1,xFilial("SA3")+_aDadosRepres[_nI,1],"A3_NOME")
			  EndIf
		   
		      aAdd(_aComGerenc,{_aDadosRepres[_nI,1], _cNome, _nValRec, _nValCom, _nPerc})
		   EndIf
       Next

	EndIf

    For _nI := 1 To Len(_aComGerenc)      
 		_nPosLin += _nSpcLin
	   
	    If (_nPosLin + _nSpcLin) > _nLimPag 
           
           _nPosLin += _nSpcLin
           //ROMS30RQBR
		   _nLinBox += _nSpcLin 
		   _nLinBox += _nSpcLin 

           ROMS30RQPG( 0 , .T. , .F. , "ROMS304R()" , "" , _cDescric )
          
           _nLinBox := _nPosLin
        
		   _nPosLin += _nSpcLin 
		   _nPosLin += _nSpcLin 

           _nPosLin += _nSpcLin 

		   _oPrint:Say( _nPosLin + 30 , _nColFim / 2 - 200 - _nLetras , _cTitulo + " - Continuação" , _oFont16b , _nColFim ,,, 2 )
           //_oPrint:Line( _nPosLin , _nColIni , _nPosLin , _nColFim ) 

           _nPosLin += _nSpcLin 
           _nPosLin += _nSpcLin 

           ROMS30RQPG( 0 , .T. , .F. , "ROMS304R()" , "" , _cDescric )
		   
           _oPrint:Say( _nPosLin + _nSpcLin	, _nColIni + 0010	, "Representante"		, _oFont11b )
           _oPrint:Say( _nPosLin + _nSpcLin	, _nColIni + 1110	, "Valor Recebido"		, _oFont11b )
           _oPrint:Say( _nPosLin + _nSpcLin	, _nColIni + 1540	, "Valor Comissão"		, _oFont11b )
           _oPrint:Say( _nPosLin + _nSpcLin	, _nColIni + 1920	, "% Com."			, _oFont11b )
           /*
           _oPrint:Say( _nPosLin + _nSpcLin	, _nColIni + 0010	, "Representante"		, _oFont11b )
           _oPrint:Say( _nPosLin + _nSpcLin	, _nColIni + 1110	, "Valor Recebido"		, _oFont11b )
           _oPrint:Say( _nPosLin + _nSpcLin	, _nColIni + 1540	, "Valor Comissão"		, _oFont11b )
           _oPrint:Say( _nPosLin + _nSpcLin	, _nColIni + 1920	, "% Comissão"			, _oFont11b )
           */
           _nPosLin += _nSpcLin

        EndIf

       _oPrint:Say( _nPosLin + _nSpcLin , _nColIni + 0010 , _aComGerenc[_nI,1] + " - " + _aComGerenc[_nI,2]	     , _oFont11 )
	   _oPrint:Say( _nPosLin + _nSpcLin , _nColIni + 1100 , Transform(_aComGerenc[_nI,3],"@E 999,999,999.99")  , _oFont11 )
	   _oPrint:Say( _nPosLin + _nSpcLin , _nColIni + 1540 , Transform(_aComGerenc[_nI,4],"@E 999,999,999.99") , _oFont11 )
	   _oPrint:Say( _nPosLin + _nSpcLin , _nColIni + 1900 , Transform(_aComGerenc[_nI,5],"@E 999.999") , _oFont11 ) 
    Next   				

	_nPosLin += _nSpcLin 
//	_nPosLin += _nSpcLin  

	 //_oPrint:Box( nLinInBox , _nColIni , _nPosLin , _nColFim )
 
EndIf

Return


/*
===============================================================================================================================
Programa----------: ROMS30RQPG
Autor-------------: Julio de Paula Paz
Data da Criacao---: 08/11/2022
Descrição---------: Função para controlar as quebras de página do relatório
Parametros--------: _nPosLins - numero de linhas que sera reduzido do tamanho do box do relatorio.
------------------: impBox    - .T. - indica que imprime box
------------------: impCabec  - .T. - indica que imprime cabecalho de dados
------------------: boxImp    - Nome da funcao para impressao do box e suas divisorias
------------------: cabecImp  - Nome da funcao para impressao do cabecalho de dados
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS30RQPG(_nPosLins,limpBox,limpCabec,boxImp,cabecImp,_cTipoExtr)   

//====================================================================================================
// Verifica se deve quebrar a pagina
//====================================================================================================
If (_nPosLin + _nSpcLin) > _nLimPag

	//_nPosLin:= _nPosLin - (_nSpcLin * _nPosLins)
	_nPosLin := _nLimPag

    _oPrint:EndPage()	// Finaliza a Pagina.
	_oPrint:StartPage()	//Inicia uma nova Pagina

	//====================================================================================================
	// Verifica se imprime o box e divisorias do relatorio
	//====================================================================================================
	If limpBox
	    _nLinBox := 400 

		&boxImp
	EndIf
	
	_nNumPag++
	
	ROMS30RCAB( .T. ) //Chama impressão do cabecalho
	
	_nPosLin += _nSpcLin
	_nPosLin += _nSpcLin
	_nLinBox := _nPosLin
	
	//====================================================================================================
	// Verifica se imprime o cabecalho dos dados
	//====================================================================================================
	If limpCabec
	
		&cabecImp
		
		_nPosLin += _nSpcLin
		_oPrint:Line( _nPosLin , _nColIni , _nPosLin , _nColFim )
		
	EndIf

EndIf

Return

/*
===============================================================================================================================
Programa----------: ROMS304R()
Autor-------------: Julio de Paula Paz
Data da Criacao---: 09/11/2022
Descrição---------: Imprime Box fixo
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS304R()

_oPrint:Box( _nLinBox , _nColIni , _nPosLin , _nColFim )

Return

/*
===============================================================================================================================
Programa----------: ROMS30RCOM
Autor-------------: Julio de Paula Paz
Data da Criacao---: 10/11/2022
Descrição---------: Rotina para impressão dos dados das vendas e do fechamento do mês atual
Parametros--------: _aHisPag : Array contendo os dados de pagamento dos três ultímos meses
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS30RCOM( _aComissao , _cTipo , _cCodGer )

Local _aImpostos	:= {}
Local _cDescric		:= _cTitCargo 

Local _nTotBruto	:= 0
Local _nINSS		:= 0
Local _nIRRF		:= 0
Local _nTotLiqui	:= 0

Local _nLinBox2		:= _nPosLin                                

Local _cTpComis		:= "" 
Local _nVlrDebCo	:= 0   
Local _nVlrDevol	:= 0
Local _nTotDevol    := 0

Local _nTotReceb	:= 0
Local _nTotComis	:= 0
Local _nTotBonif	:= 0
Local _nTotCmBnf	:= 0

Local _cTituloPg , y , _nI
Local _lQbrPag := .F.

Private _aTotBNF := {}

//================================================================================
// Verifica a necessidade de quebra de pagina
//================================================================================
ROMS30RQPG( 0 , .F. , .F. , "" , "" , _cDescric )

_nPosLin += _nSpcLin 

If _nPosLin < _nLimPag 
   _oPrint:Line( _nPosLin , _nColIni , _nPosLin , _nColFim )
EndIf 
 
For y:=1 to Len(_aComissao)

	//================================================================================
	// Verifica se o tipo da comissao gerado eh diferente de debito
	//================================================================================
	If _aComissao[y,5] <> 'D'
 	
		If _cTpComis <> _aComissao[y,5]
		     
			_nPosLin += _nSpcLin
		 	
			//================================================================================
			// Fecha o box criado anteriormente e imprime totalizador
			//================================================================================
			If !Empty(_cTpComis)
			
				//================================================================================
				// Imprime a comissão adicional por venda de leite Magro
				//================================================================================
				If _cTpComis == 'A'
				
					_aTotCAD := ROMS030CAD( _cCodGer )
					
					If _aTotCAD[04] > 0
					
						_oPrint:Say( _nPosLin + _nAjsLin , _nColIni + 0010 , "Adicional Leite Magro"								, _oFont11b )
						_oPrint:Say( _nPosLin + _nAjsLin , _nColIni + 0750 , Transform( 0            , "@E 999,999,999,999.99" )	, _oFont11b )
						_oPrint:Say( _nPosLin + _nAjsLin , _nColIni + 1380 , Transform( _aTotCAD[04] , "@E 999,999,999,999.99" )	, _oFont11b )
						_oPrint:Say( _nPosLin + _nAjsLin , _nColIni + 1980 , Transform( _aTotCAD[03] , "@E 999.999" )				, _oFont11b ) // 2100
						
						_nPosLin	+= _nSpcLin
						_nTotComis	+= _aTotCAD[04]
						_nTotBruto	+= _aTotCAD[04]
					
					EndIf
				
				EndIf
			    
				_oPrint:Line( _nPosLin , _nColIni + 05 , _nPosLin , _nColFim - 05 )
			    
				_nPosLin += _nSpcLin 

			    _oPrint:Say( _nPosLin + _nAjsLin , _nColIni + 0010 , "TOTAL"												, _oFont11b )
			    _oPrint:Say( _nPosLin + _nAjsLin , _nColIni + 0750 , Transform(_nTotReceb,"@E 999,999,999,999.99")			, _oFont11b )
				_oPrint:Say( _nPosLin + _nAjsLin , _nColIni + 1380 , Transform(_nTotComis,"@E 999,999,999,999.99")			, _oFont11b )
				_oPrint:Say( _nPosLin + _nAjsLin , _nColIni + 1980 , Transform((_nTotComis/_nTotReceb) * 100,"@E 999.999")	, _oFont11b ) // 2100
				
			    _nPosLin += _nSpcLin
				_nPosLin += _nSpcLin 

//				ROMS304R() 
				
				//================================================================================
				// Seta variaves do totalizador por tipo de comissao do Gerente
				//================================================================================
				_nTotReceb := 0
				_nTotComis := 0
			
			EndIf
			
			_nLinBox := _nPosLin	
			
			_cTituloPg := ""
			If _cTipoRepSA3 == 'G'  	
               _cTituloPg := "Gerência"  
            ElseIf _cTipoRepSA3 == 'C'
               _cTituloPg := "Coordenação"
            ElseIf _cTipoRepSA3 == 'S'
               _cTituloPg := "Supervisão"
            ElseIf _cTipoRepSA3 == 'V'
               _cTituloPg := "Representante"
			ElseIf _cTipoRepSA3 == 'N'
               _cTituloPg := "Gerente Geral"
            EndIf

            If (_nPosLin + _nSpcLin + _nSpcLin ) > _nLimPag  
			   _nPosLin += _nSpcLin
			   _nPosLin += _nSpcLin
			EndIf 

            ROMS30RQPG( 0 , .T. , .F. , "ROMS304R()" , "" , _cDescric )

			_cTitulo := 'Comissão a pagar sobre ' + _cTituloPg
            _nLetras := Len(_cTitulo) / 2
            _nLetras *= 10
   
            _oPrint:Say( _nPosLin + 30  , _nColFim / 2 - 200 - _nLetras , _cTitulo , _oFont16b , _nColFim ,,, 2 )
            //_oPrint:Line( _nPosLin , _nColIni , _nPosLin , _nColFim )

			//_oPrint:Say( _nPosLin , _nColFim / 2 , 'Comissão a pagar sobre ' + _cTituloPg , _oFont16b , _nColFim ,,, 2 )
			
			_nPosLin += _nSpcLin
			//_nPosLin += _nSpcLin
			
			_oPrint:Line( _nPosLin , _nColIni , _nPosLin , _nColFim ) 
			_nPosLin += _nSpcLin

            If (_nPosLin + _nSpcLin + _nSpcLin ) > _nLimPag  
			   _nPosLin += _nSpcLin
			   _nPosLin += _nSpcLin
			EndIf 

            ROMS30RQPG( 0 , .T. , .F. , "ROMS304R()" , "" , _cDescric )
            
			_nPosLin += _nSpcLin
			_oPrint:Say( _nPosLin + _nAjsLin , _nColIni + 0010 , "Unidade"      , _oFont11b )
			_oPrint:Say( _nPosLin + _nAjsLin , _nColIni + 0870 , "Vlr.Recebido" , _oFont11b )
			_oPrint:Say( _nPosLin + _nAjsLin , _nColIni + 1500 , "Vlr.Comissão" , _oFont11b )
			_oPrint:Say( _nPosLin + _nAjsLin , _nColIni + 2050 , "%"            , _oFont11b )
			
		EndIf
		
		nLinInBox := _nPosLin
		_nPosLin += _nSpcLin
		//_nPosLin += _nSpcLin
		
		_oPrint:Line( _nPosLin , _nColIni , _nPosLin , _nColFim ) 
		
		_nPosLin += _nSpcLin


		 //_oPrint:Box( nLinInBox , _nColIni , _nPosLin , _nColFim ) 
		 
		//================================================================================
		// Verifica quebra de pagina
		//================================================================================
		_lQbrPag := .F.

		If (_nPosLin + _nSpcLin ) > _nLimPag  
		   _nPosLin += _nSpcLin
		   _lQbrPag := .T.
		EndIf

		ROMS30RQPG( 0 , .T. , .F. , "ROMS304R()" , "" , _cDescric )
		
		If _lQbrPag
		   _nPosLin += _nSpcLin
		EndIf 

		_oPrint:Say( _nPosLin + _nAjsLin , _nColIni + 0010 , SubStr(FWFilialName(,_aComissao[y,1]),1,30)						, _oFont11 )
		_oPrint:Say( _nPosLin + _nAjsLin , _nColIni + 0750 , Transform(Round(_aComissao[y,2],2),"@E 999,999,999,999.99")				, _oFont11 )
		_oPrint:Say( _nPosLin + _nAjsLin , _nColIni + 1380 , Transform(Round(_aComissao[y,3],2),"@E 999,999,999,999.99")				, _oFont11 )
		_oPrint:Say( _nPosLin + _nAjsLin , _nColIni + 1980 , Transform((_aComissao[y,3]/_aComissao[y,2]) * 100,"@E 999.999")	, _oFont11 )
		
		_nTotReceb	+= Round(_aComissao[y,2],2)
		_nTotComis	+= Round(_aComissao[y,3],2)
		_nTotBruto  += Round(_aComissao[y,3],2)
		
		_cTpComis	:= _aComissao[y,5]
	
	//================================================================================
	// Calcula o valor de debito da comissão
	//================================================================================
	Else
	
		_nVlrDebCo += Round(_aComissao[y,3],2)
		_nVlrDevol += Round(_aComissao[y,6],2)
		_nTotDevol += Round(_aComissao[y,2],2)
	
	EndIf

Next y

nLinInBox := _nPosLin
_nPosLin += _nSpcLin
//_oPrint:Box( nLinInBox , _nColIni , _nPosLin , _nColFim ) 
_oPrint:Line( _nPosLin , _nColIni , _nPosLin , _nColFim ) 
_nPosLin += _nSpcLin

//================================================================================
//Calcula o desconto de comissão por bonificação
//================================================================================
FWMsgRun(, {|| _aTotBNF := ROMS030BNF( _cCodGer ) }, "Aguarde... ", 'Filtrando bonificações para ' + _cTitCargo + ' ' + StrZero(_nni,6) + " de " + StrZero(_ntoti,6) + "..." )

If !Empty( _aTotBNF )
  	
  	
	For _nI := 1 To Len(_aTotBNF)
    
    	_nTotComis	+= Round(_aTotBNF[_nI][03],2)
		_nTotCmBnf	+= Round(_aTotBNF[_nI][03],2)
		_nTotBonif	+= Round(_aTotBNF[_nI][02],2)
	
	Next _nI
	
EndIf

If !Empty( _aTotBNF ) 
 	_lQbrPag := .F.
    
	If (_nPosLin + _nSpcLin ) > _nLimPag  
	   _nPosLin += _nSpcLin
	   _lQbrPag := .T.
	EndIf

	ROMS30RQPG( 0 , .T. , .F. , "ROMS304R()" , "" , _cDescric )
	
	If _lQbrPag
	   _nPosLin += _nSpcLin
	EndIf 

	_nLinBox2 := _nPosLin
	
	_oPrint:Say( _nPosLin + _nAjsLin , _nColIni + 0010 , "Débito: Comissão x Bonificações"							, _oFont11b )
	_oPrint:Say( _nPosLin + _nAjsLin , _nColIni + 0750 , Transform(-1*_nTotBonif,"@E 999,999,999,999.99")				, _oFont11b )
	_oPrint:Say( _nPosLin + _nAjsLin , _nColIni + 1380 , Transform(_nTotCmBnf,"@E 999,999,999,999.99")				, _oFont11b )
	_oPrint:Say( _nPosLin + _nAjsLin , _nColIni + 1980 , Transform(Abs((_nTotCmBnf/_nTotBonif) * 100),"@E 999.999")	, _oFont11b )
	
	_nVlrDebCo	+= _nTotCmBnf
	_nPosLin	+= _nSpcLin
	
	//_oPrint:Box(_nLinBox2,_nColIni,_nPosLin,_nColFim)  
	_oPrint:Line( _nPosLin , _nColIni , _nPosLin , _nColFim ) 
    _nPosLin += _nSpcLin

EndIf

If _nVlrDevol <> 0  
 	
    _lQbrPag := .F.
    
	If (_nPosLin + _nSpcLin ) > _nLimPag  
	   _nPosLin += _nSpcLin
	   _lQbrPag := .T.
	EndIf

	ROMS30RQPG( 0 , .T. , .F. , "ROMS304R()" , "" , _cDescric )
	
	If _lQbrPag
	   _nPosLin += _nSpcLin
	EndIf 

	_oPrint:Say( _nPosLin + _nAjsLin , _nColIni + 0010 , "Débito: Pagamento de devoluções"							, _oFont11b )
	_oPrint:Say( _nPosLin + _nAjsLin , _nColIni + 0750 , Transform( -1*_nTotDevol ,"@E 999,999,999,999.99")				, _oFont11b )
	_oPrint:Say( _nPosLin + _nAjsLin , _nColIni + 1380 , Transform( _nVlrDevol    ,"@E 999,999,999,999.99")				, _oFont11b )
	_oPrint:Say( _nPosLin + _nAjsLin , _nColIni + 1980 , Transform(Abs((_nVlrDevol/_nTotDevol) * 100),"@E 999.999")	, _oFont11b )
	
	_nVlrDebCo	+= _nVlrDevol
	_nPosLin	+= _nSpcLin
	
	//_oPrint:Box(_nLinBox2,_nColIni,_nPosLin,_nColFim)  
	_oPrint:Line( _nPosLin , _nColIni , _nPosLin , _nColFim ) 
	_nPosLin += _nSpcLin

EndIf

_lQbrPag := .F.
    
If (_nPosLin + _nSpcLin ) > _nLimPag  
   _nPosLin += _nSpcLin
   _lQbrPag := .T.
EndIf

//================================================================================
// Verifica quebra de pagina
//================================================================================
ROMS30RQPG( 0 , .T. , .F. , "ROMS304R()" , "" , _cDescric )

If _lQbrPag
   _nPosLin += _nSpcLin
EndIf 

_nLinBox2 := _nPosLin
//_oPrint:Line( _nPosLin , _nColIni + 05 , _nPosLin , _nColFim - 05 )

_nTotLiqui := Round(_nTotBruto,2) + Round(_nVlrDebCo,2) 

_nTotComis := _nTotLiqui
_nTotReceb := _nTotReceb - _nTotBonif - _nTotDevol

//_nPosLin+=_nSpcLin 

_oPrint:Say( _nPosLin + _nAjsLin , _nColIni + 0010 , "Total Bruto"												, _oFont11b )
_oPrint:Say( _nPosLin + _nAjsLin , _nColIni + 0750 , Transform(_nTotReceb,"@E 999,999,999,999.99")			, _oFont11b )
_oPrint:Say( _nPosLin + _nAjsLin , _nColIni + 1380 , Transform(_nTotComis,"@E 999,999,999,999.99")			, _oFont11b )
_oPrint:Say( _nPosLin + _nAjsLin , _nColIni + 1980 , Transform((_nTotComis/_nTotReceb) * 100,"@E 999.999")	, _oFont11b )

//================================================================================
// Efetua o calculo dos Impostos do vendedor como: INSS e IRRF.
//================================================================================
_aImpostos := {} 
If Val(_aComissao[1,4]) > 0 .Or. _nTotLiqui > 0  
   _aImpostos := U_C_IRRF_INSS( _aComissao[1,4] , _nTotLiqui )
Else
   aAdd(_aImpostos, {0,0})  
EndIf

_nINSS := Round(_aImpostos[1,1],2)
_nIRRF := Round(_aImpostos[1,2],2)

_nTotLiqui -= ( _nINSS + _nIRRF )

//_nPosLin += _nSpcLin
_lQbrPag := .F.
    
If (_nPosLin + _nSpcLin ) > _nLimPag  
   _nPosLin += _nSpcLin
   _lQbrPag := .T.
EndIf

//================================================================================
// Verifica quebra de pagina
//================================================================================
ROMS30RQPG( 0 , .T. , .F. , "ROMS304R()" , "" , _cDescric )

If _lQbrPag
   _nPosLin += _nSpcLin
EndIf 

_nPosLin+=_nSpcLin

_oPrint:Line( _nPosLin , _nColIni + 05 , _nPosLin , _nColFim - 05 )

_nPosLin+=_nSpcLin 

_oPrint:Say( _nPosLin + _nAjsLin , _nColIni + 0010 , "INSS"													, _oFont11b )
_oPrint:Say( _nPosLin + _nAjsLin , _nColIni + 1380 , Transform(_nINSS,"@E 999,999,999,999.99")			, _oFont11b )

_nPosLin+=_nSpcLin      

_lQbrPag := .F.
    
If (_nPosLin + _nSpcLin ) > _nLimPag  
   _nPosLin += _nSpcLin
   _lQbrPag := .T.
EndIf

//================================================================================
// Verifica quebra de pagina
//================================================================================
ROMS30RQPG( 0 , .T. , .F. , "ROMS304R()" , "" , _cDescric )

If _lQbrPag
   _nPosLin += _nSpcLin
EndIf 

//_oPrint:Line( _nPosLin , _nColIni + 05 , _nPosLin , _nColFim - 05 )
_oPrint:Line( _nPosLin , _nColIni , _nPosLin , _nColFim )

_nPosLin+=_nSpcLin 

_oPrint:Say( _nPosLin + _nAjsLin , _nColIni + 0010 , "IRRF"													, _oFont11b )
_oPrint:Say( _nPosLin + _nAjsLin , _nColIni + 1380 , Transform(_nIRRF,"@E 999,999,999,999.99")			, _oFont11b )

_nPosLin += _nSpcLin
//_oPrint:Box(_nLinBox2,_nColIni,_nPosLin,_nColFim) 
_oPrint:Line( _nPosLin , _nColIni , _nPosLin , _nColFim )

_nPosLin += _nSpcLin

_lQbrPag := .F.
    
If (_nPosLin + _nSpcLin + 200) > _nLimPag   
   _nPosLin += _nSpcLin + 200  
   _lQbrPag := .T.
EndIf

//================================================================================
// Verifica quebra de pagina
//================================================================================
ROMS30RQPG( 0 , .T. , .F. , "ROMS304R()" , "" , _cDescric )

If _lQbrPag
   _nPosLin += _nSpcLin
   _nPosLin += _nSpcLin 
   _nPosLin += _nSpcLin 
EndIf 

_oPrint:Say( _nPosLin            , _nColIni + 0010 , "Total Líquido a Pagar"							, _oFont15b )
_oPrint:Say( _nPosLin            , _nColIni + 1300 , Transform( _nTotLiqui ,"@E 999,999,999,999.99")	, _oFont15b ) // 1450

_nPosLin+=_nSpcLin 

Return

/*
===============================================================================================================================
Programa--------: ROMS30RASI
Autor-----------: Julio de Paula Paz
Data da Criacao-: 10/11/2022
Descrição-------: Funcao que imprime a área de assinaturas do relatório
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS30RASI()
Local _nPosCent := 0

_nPosLin += ( _nSpcLin * 3 ) // ( _nSpcLin * 6 )


_oPrint:Line( _nPosLin , _nColIni        , _nPosLin , _nColIni + 1080 )
_oPrint:Line( _nPosLin , _nColIni + 1280 , _nPosLin , _nColFim        )

_nPosLin += _nSpcLin 

_oPrint:Say( _nPosLin + _nAjsLin , (_nColIni + 1080) / 2            , "CONFERENTE"        , _oFont11b , _nColIni + 1080 ,,, 2 )
//_oPrint:Say( _nPosLin + _nAjsLin , (_nColIni + 1280 + _nColFim) / 2 , "DIRETOR COMERCIAL" , _oFont11b , _nColFim        ,,, 2 )
_nPosCent := Len(AllTrim(MV_PAR13)) / 2  * 10 
_oPrint:Say( _nPosLin + _nAjsLin , ((_nColIni + 900 + _nColFim) / 2) - _nPosCent , AllTrim(MV_PAR13) , _oFont11b , _nColFim        ,,, 2 )  // 1280
_nPosLin += _nSpcLin 
_nPosCent := Len(AllTrim(MV_PAR14)) / 2 * 10
_oPrint:Say( _nPosLin + _nAjsLin , ((_nColIni + 1040 + _nColFim) / 2) - _nPosCent , AllTrim(MV_PAR14) , _oFont11b , _nColFim        ,,, 2 )
_nPosLin += _nSpcLin 
_nPosCent := Len(AllTrim(MV_PAR15)) / 2 * 10
_oPrint:Say( _nPosLin + _nAjsLin , ((_nColIni + 1010 + _nColFim) / 2 ) - _nPosCent , AllTrim(MV_PAR15) , _oFont11b , _nColFim        ,,, 2 )
_nPosLin += _nSpcLin 
_nPosCent := Len(AllTrim(MV_PAR16)) / 2 * 10 
_oPrint:Say( _nPosLin + _nAjsLin , ((_nColIni + 930 + _nColFim) / 2 ) - _nPosCent , AllTrim(MV_PAR16)  , _oFont11b , _nColFim        ,,, 2 )
_nPosLin += _nSpcLin 

Return
