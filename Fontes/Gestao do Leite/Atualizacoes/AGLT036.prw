/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |22/12/2021| Chamado 38695. Incluída validaççao para não permitir a mesma NFP para dois produtores com mesma Inscrição . 
Lucas Borges  |11/02/2025| Chamado 49877. Removido tratamento sobre a versão do Mix
Lucas Borges  |04/07/2025| Chamado 51254. Corrigido error.log na geração do log de erro
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "FWMVCDef.ch"

/*
===============================================================================================================================
Programa----------: AGLT036
Autor-------------: Alexandre Villar
Data da Criacao---: 18/07/2014
Descrição---------: Rotinas de Inclusão de Contra NF de Produtor via Leitura/Digitação do Código de Barras	
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT036

Local _aParAux		:= {} As Array
Local _aParRet		:= {} As Array
Local _cFilter		:= "" As Character
Local oBrowse		:= Nil As Object

DBSelectArea('ZZ4')
DBSelectArea("ZL3")

aAdd( _aParAux , { 02 , "Somente em aberto"	, "Sim"							, { "Sim" , "Não" }		, 50 , "" , .F. } )
aAdd( _aParAux , { 01 , "Mix específico"	, Space(TamSX3('ZLE_COD')[01])	, "" , "" , "ZLE_01" 	, "" , 0  , .F. } )

If ParamBox( _aParAux , "Opções de Inicialização:" , @_aParRet ,,, .T. ,,,,, .F. , .F. )
	If Upper( _aParRet[01] ) == "SIM"
		_cFilter := " ZLE->ZLE_STATUS <> 'F' "
	EndIf
	
	If !Empty( _aParRet[02] )
		IIf( !Empty(_cFilter) , _cFilter += " .And. " , Nil )
		_cFilter += " ZLE->ZLE_COD == '"+ _aParRet[02] +"' "
	EndIf
EndIf


// Inicializa o Objeto do Browse
oBrowse := FWMBrowse():New()
oBrowse:SetAlias("ZLE")
oBrowse:SetDescription("Lançamento de CNF de Produtores")
oBrowse:SetFilterDefault( _cFilter )
oBrowse:SetUseFilter()
oBrowse:Activate()

Return

/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Alexandre Villar
Data da Criacao---: 18/07/2014
Descrição---------: Define as opções do MENU da tela principal
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MenuDef

Local aRotina	:= {} As Array

ADD OPTION aRotina Title 'Visualizar'	Action 'U_AGLT36EX(2)'	OPERATION 2 ACCESS 0
ADD OPTION aRotina Title 'Lançar'		Action 'U_AGLT36EX(4)'	OPERATION 2 ACCESS 0
ADD OPTION aRotina Title 'Validar'		Action 'U_AGLT36VL()'	OPERATION 2 ACCESS 0
ADD OPTION aRotina Title 'Gerar NF'		Action 'U_AGLT36NF()'	OPERATION 2 ACCESS 0

Return(aRotina)

/*
===============================================================================================================================
Programa----------: AGLT36EX
Autor-------------: Alexandre Villar
Data da Criacao---: 18/07/2014
Descrição---------: Rotina de manutenção dos lançamentos de CNF
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT36EX(nOper) As Numeric

Local nI			:= 0 As Numeric
Local aCoors 		:= FWGetDialogSize(oMainWnd) As Array
Local aSize     	:= MsAdvSize( .T. ) As Array
Local aObjects		:= {} As Array
Local aButtons		:= {} As Array
Local bOk			:= {|| IIf( AGLT036GRV( oLbxAux ) , Nil , oDlg:End() ) } As Codeblock
Local bCancel		:= {|| IIf( AGLT036CLS( oLbxAux ) , oDlg:End() , Nil ) } As Codeblock
Local oDlg			:= Nil As Object
Local oFont			:= Nil As Object
Local cColsAux		:= "" As Character
Local oLbxAux		:= Nil As Object
Local bDblClk	 	:= {|| AGLT036EDT( @oLbxAux ) } As Codeblock
Local cTitAux		:= "Lançamento de CNF" As Character
Local aHeader		:= { "Cód. Produtor" , "Loja Produtor" , "Nome" , 'Cód. Linha' , 'Descr. Linha' , "Série CNF" , "Número CNF" , "Qtde" , "Valor Unit." , "Status" }As Array
Local aCols			:= {} As Array

Default nOper		:= 0

If nOper == 0
	Return
EndIf

If nOper <> 2 .And. ZLE->ZLE_STATUS == 'F'
	FWAlertWarning("Não é possível processar um Mix que já esteja Fechado!","AGLT03601")
	Return
EndIf

ZZ4->( DBSetOrder(1) )
If ZZ4->( DBSeek( xFilial('ZZ4') + ZLE->ZLE_COD ) )
	While xFilial('ZZ4') + ZLE->ZLE_COD == ZZ4->(ZZ4_FILIAL + ZZ4_CODMIX)
		cStatus := IIf( AGLT036VNF( { ZZ4->ZZ4_CODPRO , ZZ4->ZZ4_LOJPRO , ZZ4->ZZ4_SERIE , ZZ4->ZZ4_NUMCNF } ) , "2" , "1" )

		If cStatus <> ZZ4->ZZ4_STATUS
			ZZ4->( RecLock( 'ZZ4' , .F. ) )
			ZZ4->ZZ4_STATUS := cStatus
			ZZ4->( MSUnLock() )
		EndIf
		
		aAdd( aCols , {	ZZ4->ZZ4_CODPRO																				,;
						ZZ4->ZZ4_LOJPRO																				,;
						Capital(AllTrim(Posicione("SA2",1,xFilial("SA2")+ZZ4->( ZZ4_CODPRO+ZZ4_LOJPRO),'A2_NOME'))) ,;
						SA2->A2_L_LI_RO																				,;
						AllTrim(Posicione('ZL3',1,xFilial('ZL3')+SA2->A2_L_LI_RO,'ZL3_DESCRI'))						,;
						ZZ4->ZZ4_SERIE																				,;
						ZZ4->ZZ4_NUMCNF																				,;
						ZZ4->ZZ4_QTDE																				,;
						ZZ4->ZZ4_VALOR																				,;
						U_ITRetBox( ZZ4->ZZ4_STATUS , "ZZ4_STATUS" )												})
	
	ZZ4->( DBSkip() )
	EndDo
EndIf

If Empty(aCols)
	If nOper <> 4
        FWAlertWarning("O MIX selecionado não possui registros de lançamentos de CNF. Não é possível processar um MIX sem sem lançamentos.","AGLT03602")
		Return
	EndIf
	aCols := { {'','','','','','','',0,0,'Lançamento de CNF'} }
EndIf

aAdd( aObjects , { 100 , 100 , .T. , .T. } )
aInfo   := { aSize[1] , aSize[2] , aSize[3] , aSize[4] , 3 , 2 }
aPosObj := MsObjSize( aInfo , aObjects )

DEFINE FONT oFont NAME "Verdana" SIZE 05,12

aAdd( aButtons , { "Excel"		, {|| DlgToExcel( { { "ARRAY" , cTitAux , aHeader , aCols } } ) }	, "Exportação de Dados para Excel"	, "Excel"		} )

//====================================================================================================
// Só permite lançar/excluir se não For "visualização"
//====================================================================================================
If nOper <> 2
	aAdd( aButtons , { "Lançamento"	, {|| AGLT036LCB( @oLbxAux ) } , "Lançamento de CNF"	, "Lançar CNF"	} )
	aAdd( aButtons , { "Excluir"	, {|| AGLT036EXC( @oLbxAux ) } , "Exclusão de CNF"		, "Excluir CNF"	} )
EndIf

DEFINE MSDIALOG oDlg TITLE cTitAux FROM aCoors[1],aCoors[2] TO aCoors[3],aCoors[4] PIXEL
	
	@aPosObj[01][01] , 010 Say 'MIX: '+ ZLE->ZLE_COD +' | Emissão: '+ StrZero( Month(Date()) , 2 ) +'/'+ StrZero( Year(Date()) , 4 ) OF oDLg PIXEL
	
	@aPosObj[01][01] + 10 , aPosObj[01][02]	LISTBOX oLbxAux					;
											FIELDS HEADER ""				;
											ON DblClick( Eval(bDblClk) )	;
											WHEN ( nOper <> 2 )				;
											SIZE aPosObj[01][04] , ( aPosObj[01][03] - aPosObj[01][01] ) OF oDlg PIXEL
	
	oLbxAux:AHeaders := aClone(aHeader)
	oLbxAux:SetArray( aCols )
	
	// Monta os dados para o ListBox
	For nI := 1 To Len(aHeader)
		If nI == 1
			cColsAux := "{|| {	aCols[oLbxAux:nAt,"+ cValtoChar(nI) +"] ,"
		Else
			cColsAux += "		aCols[oLbxAux:nAt,"+ cValtoChar(nI) +"] ,"
		EndIf
	Next nI
	
	// Atribui os dados ao ListBox
	cColsAux		:= SubStr( cColsAux , 1 , Len(cColsAux)-1 ) + "}}"
	oLbxAux:bLine	:= &( cColsAux )

ACTIVATE MSDIALOG oDlg	ON INIT ( EnchoiceBar( oDlg , bOk , bCancel ,, aButtons ) ) CENTERED

Return

/*
===============================================================================================================================
Programa----------: AGLT36EDT
Autor-------------: Alexandre Villar
Data da Criacao---: 18/07/2014
Descrição---------: 
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT036EDT(oLbxDados) As Object

Local oDlgAux	:= Nil As Object
Local nQtdMes	:= SuperGetMV("LT_CNFQTMS",.F.,10) As Numeric
Local nQtdAux	:= oLbxDados:aArray[oLbxDados:nAt][08] As Numeric
Local nValAux	:= oLbxDados:aArray[oLbxDados:nAt][09] As Numeric
Local nOpc		:= 0 As Numeric
Local bOk		:= {|| nOpc := 1 , oDlgAux:End() } As Codeblock
Local bCancel	:= {|| nOpc := 0 , oDlgAux:End() } As Codeblock
Local aButtons	:= {} As Array

aAdd( aButtons , { "Recalcular" , {|| LjMsgRun( "Reprocessando valores..." , "Aguarde!" , {|| AGLT036VSA( { SA2->A2_COD , SA2->A2_LOJA , ZL3->ZL3_SETOR , ZL3->ZL3_COD , DToS(MonthSub(ZLE->ZLE_DTFIM,nQtdMes)) , DToS(ZLE->ZLE_DTFIM) } , @nQtdAux , @nValAux ) } ) } , "Recalcular valores" , "Recalcular" } )

SA2->( DBSetOrder(1) )
If SA2->( DBSeek( xFilial("SA2") + oLbxDados:aArray[oLbxDados:nAt][01] + oLbxDados:aArray[oLbxDados:nAt][02] ) )
	
	ZL3->( DBSetOrder(1) )
	If ZL3->( DBSeek( SubStr( SA2->A2_L_LI_RO , 1 , 2 ) + SA2->A2_L_LI_RO ) )

		DEFINE MSDIALOG oDlgAux TITLE "Alteração dos Dados da CNF" FROM 000,000 TO 160,500 PIXEL

			@030,010 Say 'MIX: '+			ZLE->ZLE_COD													OF oDLgAux PIXEL
			@030,180 Say '| Emissão: '+		StrZero( Month(Date()) , 2 ) +'/'+ StrZero( Year(Date()) , 4 )	OF oDLgAux PIXEL
			@040,010 Say 'Código/Loja: '+ 	SA2->A2_COD +'/'+ SA2->A2_LOJA									OF oDLgAux PIXEL
			@040,100 Say '| Nome: '+		Capital( AllTrim( SA2->A2_NOME ) )								OF oDLgAux PIXEL
			@050,010 Say 'Série: '+ 		oLbxDados:aArray[oLbxDados:nAt][06]								OF oDLgAux PIXEL
			@050,050 Say 'Número CNF: '+	oLbxDados:aArray[oLbxDados:nAt][07]								OF oDlgAux PIXEL
			@055,000 Say Replicate('_',500)																	OF oDlgAux PIXEL
			@070,010 Say 'Quantidade:'																		OF oDLgAux PIXEL
			@068,043 MSGET nQtdAux PICTURE "@E 999999.99"	SIZE 050,010									OF oDlgAux PIXEL
			@070,120 Say 'Valor Unit.:'		   																OF oDLgAux PIXEL
			@068,150 MSGET nValAux PICTURE "@E 999999.99"	SIZE 050,010									OF oDlgAux PIXEL
		
		ACTIVATE MSDIALOG oDlgAux ON INIT ( EnchoiceBar( oDlgAux , bOk , bCancel ,, aButtons ) ) CENTERED
		
		If nOpc == 1
			oLbxDados:aArray[oLbxDados:nAt][08] := nQtdAux
			oLbxDados:aArray[oLbxDados:nAt][09] := nValAux
		EndIf
	EndIf
EndIf

oLbxDados:Refresh()

Return

/*
===============================================================================================================================
Programa----------: AGLT36LCB
Autor-------------: Alexandre Villar
Data da Criacao---: 18/07/2014
Descrição---------: 
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/Static Function AGLT036LCB(oLbxDados As Object)

Local nQtdMes	:= SuperGetMV("LT_CNFQTMS",.F.,10) As Numeric
Local nQtdAux	:= 0 As Numeric
Local nValAux	:= 0 As Numeric
Local nConf		:= 0 As Numeric
Local nChars	:= SuperGetMV("LT_CNFTAMC",.F.,20) As Numeric
Local nI		:= 0 As Numeric
Local cCodBar	:= '' As Character
Local cDtIni	:= DToS( MonthSub( ZLE->ZLE_DTFIM , nQtdMes ) ) As Character
Local cDtFim	:= DToS(ZLE->ZLE_DTFIM) As Character
Local aDadosP	:= {} As Array
Local oDlgAux	:= NIL As Object
Local bOk		:= {|| nConf := 1 , oDlgAux:End() } As Codeblock
Local bCancel	:= {|| nConf := 0 , oDlgAux:End() } As Codeblock

If FWAlertYesNo('O processamento atual irá gravar as CNF no: '+ CRLF +;
						'MIX: '+ ZLE->ZLE_COD + CRLF + CRLF +;
						'Deseja continuar?' , "AGLT03603" )

	cCodBar := U_ITLeCod( nChars , .T. )
	
	While !Empty( cCodBar )
		
		aDadosP		:= AGLT036DPR( SubStr( cCodBar , 1 , 11 ) )
		lIncNovo	:= .F.
		
		If Empty(aDadosP)
			FWAlertWarning("Não foi encontrado o Produtor referente à CNF digitada. Verifique os dados e tente novamente.","AGLT03604")
			lIncNovo := .F.
		Else
			SA2->( DBSetOrder(1) )
			If SA2->( DBSeek( xFilial("SA2") + aDadosP[01] + aDadosP[02] ) )
				If SA2->A2_MSBLQL == '1' .Or. SA2->A2_L_ATIVO == 'N'
					FWAlertWarning("O Produtor referente à NFP informada encontra-se Bloqueado ou Inativo no cadastro de Fornecedores!","AGLT03605")
					lIncNovo := .F.
				Else
					ZL3->( DBSetOrder(1) )
					If ZL3->( DBSeek( SubStr( SA2->A2_L_LI_RO , 1 , 2 ) + SA2->A2_L_LI_RO ) )
					
						lIncNovo := .T.
						
						// Verifica se o Setor do Produtor exige o lançamento de CNF
						If Posicione( "ZL2" , 1 , SubStr( ZL3->ZL3_SETOR , 1 , 2 ) + ZL3->ZL3_SETOR , 'ZL2_VLDNFP' ) <> '1'
							lIncNovo := .F.
							FWAlertWarning("O Setor do Produtor não permite o lançamento de CNF! Verifique os dados.","AGLT03606")
						Else
							// Verifica se a nota atual já foi lançada no MIX atual
							For nI := 1 To Len(oLbxDados:aArray)
								If	oLbxDados:aArray[nI][01] == SA2->A2_COD					.And.;
									oLbxDados:aArray[nI][02] == SA2->A2_LOJA				.And.;
									oLbxDados:aArray[nI][06] == SubStr( cCodBar , 12 , 03 )	.And.;
									oLbxDados:aArray[nI][07] == PadL(AllTrim(SubStr( cCodBar , 15 , 06 )),9,"0")
									
									lIncNovo := .F.
									FWAlertWarning("Essa nota já foi incluída no MIX atual! Verifique os dados.","AGLT03607")
									
								ElseIf	oLbxDados:aArray[nI][01] == SA2->A2_COD				.And.;
										oLbxDados:aArray[nI][02] == SA2->A2_LOJA
									
									lIncNovo := .F.
									FWAlertWarning("Já foi incluída uma nota para o Produtor ["+ SA2->A2_COD +"/"+ SA2->A2_LOJA +"] no MIX atual! Verifique os dados.","AGLT03608")
									
								ElseIf !(oLbxDados:aArray[nI][01] == SA2->A2_COD			.And.;
									oLbxDados:aArray[nI][02] == SA2->A2_LOJA)				.And.;
									oLbxDados:aArray[nI][06] == SubStr( cCodBar , 12 , 03 )	.And.;
									oLbxDados:aArray[nI][07] == PadL(AllTrim(SubStr( cCodBar , 15 , 06 )),9,"0")
									
									If !FWAlertYesNo("Já foi incluída a nota "+oLbxDados:aArray[nI][07]+" / "+oLbxDados:aArray[nI][06]+ " para o Produtor ["+ oLbxDados:aArray[nI][01] +"/"+ oLbxDados:aArray[nI][02] +"] no MIX atual! Verifique os dados. Deseja continuar?","AGLT03630")
										lIncNovo := .F.
									EndIf
								EndIf
							Next nI
						EndIf
						
						// Verifica se a nota atual já foi lançada em MIX anterior
						If lIncNovo .And. AGLT036EXT( { SA2->A2_COD , SA2->A2_LOJA , SubStr( cCodBar , 12 , 03 ) , PadL(AllTrim(SubStr( cCodBar , 15 , 06 )),9,"0") } )
							lIncNovo := .F.
							FWAlertWarning("A nota atual do Produtor já foi incluída anteriormente em outro MIX! Verifique os dados.","AGLT03608")
						EndIf
						
						// Verifica se a nota atual já existe nas
						If lIncNovo .And. AGLT036VNF( { SA2->A2_COD , SA2->A2_LOJA , SubStr( cCodBar , 12 , 03 ) , PadL(AllTrim(SubStr( cCodBar , 15 , 06 )),9,"0") } )
							lIncNovo := .F.
							FWAlertWarning("Para essa Nota já exite um lançamento de Nota Fiscal de Entrada no Sistema! Verifique os dados.","AGLT03609")
						EndIf
						
						// Verifica se tem volume de Leite movimentado pelo produtor no período do Mix
						If lIncNovo .And. !( U_VolLeite( xFilial('ZZ4') , ZLE->ZLE_DTINI , ZLE->ZLE_DTFIM , ZL3->ZL3_SETOR , ZL3->ZL3_COD , SA2->A2_COD , SA2->A2_LOJA ) > 0 )
							lIncNovo := .F.
							FWAlertWarning("Não foi encontrado Volume de Leite movimentado pelo Produtor no período.","AGLT03610")
						EndIf
					Else
						lIncNovo := .F.
						FWAlertWarning("Falha ao identificar a Linha/Rota do Fornecedor! Verifique o cadastro e tente novamente.","AGLT03611")
					EndIf
			    EndIf
			Else
				lIncNovo := .F.
				FWAlertWarning("Não foi encontrado o Produtor referente à CNF digitada. Verifique os dados e tente novamente.","AGLT03612")
			EndIf
			
			If lIncNovo
				LjMsgRun( "Verificando dados da nota..." , "Aguarde!" , {|| AGLT036VSA( { SA2->A2_COD , SA2->A2_LOJA , ZL3->ZL3_SETOR , ZL3->ZL3_COD , cDtIni , cDtFim } , @nQtdAux , @nValAux ) } )
				If nQtdAux <= 0
					FWAlertWarning("Não foi possível encontrar movimentação de Leite no período atual! Verifique os dados e tente novamente.","AGLT03613")
					lIncNovo := .F.
				EndIf
				
				nConf := 0
				
				If lIncNovo .And. nValAux == 0
				
					DEFINE MSDIALOG oDlgAux TITLE "Confirmação dos Dados da CNF" FROM 000,000 TO 160,500 PIXEL
						
						@030,010 Say 'MIX: '+			ZLE->ZLE_COD													OF oDLgAux PIXEL
						@030,180 Say '| Emissão: '+		StrZero( Month(Date()) , 2 ) +'/'+ StrZero( Year(Date()) , 4 )	OF oDLgAux PIXEL
						@040,010 Say 'Código/Loja: '+ 	SA2->A2_COD +'/'+ SA2->A2_LOJA									OF oDLgAux PIXEL
						@040,100 Say '| Nome: '+		Capital( AllTrim( SA2->A2_NOME ) )								OF oDLgAux PIXEL
						@050,010 Say 'Série: '+ 		SubStr( cCodBar , 12 , 03 )										OF oDLgAux PIXEL
						@050,050 Say 'Número CNF: '+	PadL(AllTrim(SubStr( cCodBar , 15 , 06 )),9,"0")				OF oDlgAux PIXEL
						@052,000 Say Replicate('_',500)																	OF oDlgAux PIXEL
						@065,010 Say 'Quantidade:'																		OF oDLgAux PIXEL
						@063,040 MSGET nQtdAux PICTURE "@E 999999.99"	SIZE 050,010									OF oDlgAux PIXEL
						@065,120 Say 'Valor:'																			OF oDLgAux PIXEL
						@063,150 MSGET nValAux PICTURE "@E 999999.99"	SIZE 050,010									OF oDlgAux PIXEL
										
					ACTIVATE MSDIALOG oDlgAux ON INIT ( EnchoiceBar( oDlgAux , bOk , bCancel ) ) CENTERED
					
				Else
					nConf := 1
				EndIf
				
				If lIncNovo .And. nConf == 1
					If Len(oLbxDados:aArray) > 0 .And. Empty( oLbxDados:aArray[oLbxDados:nAt][01] )
						oLbxDados:aArray[oLbxDados:nAt][01] := SA2->A2_COD
						oLbxDados:aArray[oLbxDados:nAt][02] := SA2->A2_LOJA
						oLbxDados:aArray[oLbxDados:nAt][03] := AllTrim(SA2->A2_NOME)
					    oLbxDados:aArray[oLbxDados:nAt][04] := SA2->A2_L_LI_RO
						oLbxDados:aArray[oLbxDados:nAt][05] := AllTrim(Posicione('ZL3',1,xFilial('ZL3')+SA2->A2_L_LI_RO,'ZL3_DESCRI'))
						oLbxDados:aArray[oLbxDados:nAt][06] := SubStr( cCodBar , 12 , 03 )
						oLbxDados:aArray[oLbxDados:nAt][07] := PadL(AllTrim(SubStr( cCodBar , 15 , 06 )),9,"0")
						oLbxDados:aArray[oLbxDados:nAt][08] := nQtdAux
						oLbxDados:aArray[oLbxDados:nAt][09] := nValAux
						oLbxDados:aArray[oLbxDados:nAt][10] := U_ITRetBox( "1" , "ZZ4_STATUS" )
					Else
					    aAdd( oLbxDados:aArray , {	SA2->A2_COD																,;
					    							SA2->A2_LOJA															,;
					    							AllTrim(SA2->A2_NOME)													,;
					    							SA2->A2_L_LI_RO															,;
													AllTrim(Posicione('ZL3',1,xFilial('ZL3')+SA2->A2_L_LI_RO,'ZL3_DESCRI'))	,;
					    							SubStr( cCodBar , 12 , 03 )												,;
					    							PadL(AllTrim(SubStr( cCodBar , 15 , 06 )),9,"0")					 	,;
					    							nQtdAux																	,;
					    							nValAux																	,;
					    							U_ITRetBox("1","ZZ4_STATUS")											})
					
					EndIf
				EndIf
			EndIf
		EndIf
		
		nQtdAux	:= 0
		nValAux	:= 0
		oLbxDados:Refresh()
		cCodBar	:= U_ITLeCod( nChars , .T. )
	EndDo
EndIf

oLbxDados:Refresh()

Return

/*
===============================================================================================================================
Programa----------: AGLT036DPR
Autor-------------: Alexandre Villar
Data da Criacao---: 18/07/2014
Descrição---------: 
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT036DPR(_cInsEst As Character) As Array

Local _aRet		:= {} As Array
Local _aOpc		:= {} As Array
Local _oLbx		:= Nil As Object
Local _oDlgAux	:= Nil As Object
Local _cAlias	:= GetNextAlias() As Character

Default _cInsEst	:= ""

If Empty(_cInsEst)
	Return(_aRet)
EndIf

BeginSql Alias _cAlias
	SELECT SA2.A2_COD	AS CODIGO, SA2.A2_LOJA	AS LOJA, SA2.A2_NOME	AS NOME
	FROM  %Table:SA2% SA2
	WHERE SA2.D_E_L_E_T_ = ' '
	AND LENGTH( TRIM( TRANSLATE( SA2.A2_INSCR , '0123456789' , ' ' ) ) ) IS NULL
	AND TRIM(LTRIM(SA2.A2_INSCR,0)) = TRIM(LTRIM(%exp:_cInsEst%,0))
EndSql

While (_cAlias)->(!Eof())
	aAdd( _aOpc	, { (_cAlias)->CODIGO , (_cAlias)->LOJA , AllTrim( (_cAlias)->NOME ) } )
(_cAlias)->( DBSkip() )
EndDo

(_cAlias)->( DBCloseArea() )

If Len( _aOpc ) > 1
	
	FWAlertWarning("Existe mais de um produtor relacionado à essa CNF, na tela a seguir é necessário informar qual o produtor correto para o processamento!","AGLT03614")
	
	DEFINE MSDIALOG _oDlgAux TITLE "Selecione o Produtor relacionado à CNF:" FROM 000,000 TO 200,500 PIXEL
	
		@ 000,000	LISTBOX _oLbx FIELDS HEADER 'Código' , 'Loja' , 'Razão Social' SIZE 254,090 OF _oDlgAux PIXEL;
					ON DBLCLICK ( _aRet := { _oLbx:aArray[_oLbx:nAt][01] , _oLbx:aArray[_oLbx:nAt][02] } , _oDlgAux:End() )
		
		_oLbx:SetArray( _aOpc )
		_oLbx:bLine := {|| { _aOpc[_oLbx:nAt,1] , _aOpc[_oLbx:nAt,2] , _aOpc[_oLbx:nAt,3] } }
		
		@ 090,220 BUTTON "&Ok" SIZE 33,11 PIXEL ACTION ( _aRet := { _oLbx:aArray[_oLbx:nAt][01] , _oLbx:aArray[_oLbx:nAt][02] } , _oDlgAux:End() ) OF _oDlgAux
		
	ACTIVATE MSDIALOG _oDlgAux CENTERED

ElseIf Len( _aOpc ) == 1
	_aRet := { _aOpc[01][01] , _aOpc[01][02] }
EndIf

Return _aRet

/*
===============================================================================================================================
Programa----------: AGLT36GRV
Autor-------------: Alexandre Villar
Data da Criacao---: 18/07/2014
Descrição---------: 
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT036GRV(oLbxAux As Object) As Logical

Local _nI		:= 0 As Numeric
Local _nConta	:= 0 As Numeric
Local _lRet		:= .T. As Logical

For _nI := 1 To Len( oLbxAux:aArray )
	If	!Empty( oLbxAux:aArray[_nI][01] )	.And. !Empty( oLbxAux:aArray[_nI][02] )	.And.;
		!Empty( oLbxAux:aArray[_nI][06] )	.And. !Empty( oLbxAux:aArray[_nI][07] )	.And.;
		!Empty( oLbxAux:aArray[_nI][08] )	.And. !Empty( oLbxAux:aArray[_nI][09] )
		
		_nConta++
		
		// Verifica se já está cadastrado na ZZ4
		If AGLT036EXT( { oLbxAux:aArray[_nI][01] , oLbxAux:aArray[_nI][02] , oLbxAux:aArray[_nI][06] , oLbxAux:aArray[_nI][07] } )
			ZZ4->( DBSetOrder(1) )
			If ZZ4->( DBSeek( xFilial('ZZ4') + ZLE->ZLE_COD + oLbxAux:aArray[_nI][01] + oLbxAux:aArray[_nI][02] + oLbxAux:aArray[_nI][06] + oLbxAux:aArray[_nI][07] ) )
				If AGLT036VNF( { oLbxAux:aArray[_nI][01] , oLbxAux:aArray[_nI][02] , oLbxAux:aArray[_nI][06] , oLbxAux:aArray[_nI][07] } )
					If ZZ4->ZZ4_STATUS == '1'
						ZZ4->( RecLock('ZZ4',.F.) )
						ZZ4->ZZ4_STATUS := '2'
						ZZ4->( MSUnLock() )
					EndIf
				Else
					If ZZ4->ZZ4_STATUS == '2'
						ZZ4->( RecLock('ZZ4',.F.) )
						ZZ4->ZZ4_STATUS := '1'
						ZZ4->( MSUnLock() )
					EndIf
				EndIf
				
				ZZ4->( RecLock('ZZ4',.F.) )
					ZZ4->ZZ4_QTDE	:= oLbxAux:aArray[_nI][08]
					ZZ4->ZZ4_VALOR	:= oLbxAux:aArray[_nI][09]
				ZZ4->( MSUnLock() )
			EndIf
		Else
			ZZ4->( RecLock( "ZZ4" , .T. ) )
				ZZ4->ZZ4_FILIAL	:= xFilial("ZZ4")
				ZZ4->ZZ4_CODMIX	:= ZLE->ZLE_COD
				ZZ4->ZZ4_EMISSA	:= dDataBase
				ZZ4->ZZ4_CODPRO	:= oLbxAux:aArray[_nI][01]
				ZZ4->ZZ4_LOJPRO	:= oLbxAux:aArray[_nI][02]
				ZZ4->ZZ4_SERIE	:= oLbxAux:aArray[_nI][06]
				ZZ4->ZZ4_NUMCNF	:= oLbxAux:aArray[_nI][07]
				ZZ4->ZZ4_QTDE	:= oLbxAux:aArray[_nI][08]
				ZZ4->ZZ4_VALOR	:= oLbxAux:aArray[_nI][09]
				ZZ4->ZZ4_STATUS	:= "1"
			ZZ4->( MSUnLock() )
		EndIf
	EndIf
Next _nI

If _nConta > 0
	If !FWAlertYesNo('Dados gravados com sucesso! Deseja continuar na tela de lançamento?',"AGLT03615")
		_lRet := .F.
	EndIf
Else
	If !FWAlertYesNo('Não foram encontrados registros para salvar! Deseja continuar na tela de lançamento?',"AGLT03616")
		_lRet := .F.
	EndIf
EndIf

Return _lRet

/*
===============================================================================================================================
Programa----------: AGLT36EXT
Autor-------------: Alexandre Villar
Data da Criacao---: 18/07/2014
Descrição---------: 
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT036EXT(_aFiltro As Array) As Logical

Local _lRet			:= .F. As Logical
Local _cAlias		:= GetNextAlias() As Character

Default _aFiltro	:= {}

BeginSql Alias _cAlias
	SELECT ZZ4.R_E_C_N_O_ REGZZ4
	FROM  %Table:ZZ4% ZZ4
	WHERE ZZ4.D_E_L_E_T_ = ' '
	AND ZZ4_CODPRO = %exp:_aFiltro[01]%
	AND ZZ4_LOJPRO = %exp:_aFiltro[02]%
	AND ZZ4_SERIE = %exp:_aFiltro[03]%
	AND ZZ4_NUMCNF = %exp:_aFiltro[04]%
EndSql
	
_lRet := (_cAlias)->(!Eof())
(_cAlias)->(DBCloseArea())

Return _lRet

/*
===============================================================================================================================
Programa----------: AGLT036VNF
Autor-------------: Alexandre Villar
Data da Criacao---: 18/07/2014
Descrição---------: 
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT036VNF(_aFiltro As Array) As Logical

Local _cAlias	:= GetNextAlias() As Character
Local _lRet		:= .F. as Logical

If Empty(_aFiltro) .Or. Empty(_aFiltro[01]) .Or. Empty(_aFiltro[02]) .Or. Empty(_aFiltro[03]) .Or. Empty(_aFiltro[04])
	Return(_lRet)
EndIf

BeginSql Alias _cAlias
	SELECT SF1.R_E_C_N_O_ REGSF1
	FROM  %Table:SF1% SF1
	WHERE SF1.D_E_L_E_T_ = ' '   
	AND SF1.F1_FILIAL = %xFilial:SF1%
	AND SF1.F1_FORNECE = %exp:_aFiltro[01]%
	AND SF1.F1_LOJA = %exp:_aFiltro[02]%
	AND SF1.F1_SERIE = %exp:_aFiltro[03]%
	AND SF1.F1_DOC = %exp:_aFiltro[04]%
EndSql

_lRet := (_cAlias)->(!Eof())
(_cAlias)->(DBCloseArea())

Return _lRet

/*
===============================================================================================================================
Programa----------: AGLT036EXC
Autor-------------: Alexandre Villar
Data da Criacao---: 18/07/2014
Descrição---------: 
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT036EXC(oLbxAux As Object)

Local lTemNF := .F. As Logical

If	Empty( oLbxAux:aArray ) .Or. Empty( oLbxAux:aArray[oLbxAux:nAt][01] ) .Or. Empty( oLbxAux:aArray[oLbxAux:nAt][02] )
	Return
EndIf

lTemNF := AGLT036VNF( { oLbxAux:aArray[oLbxAux:nAt][01] , oLbxAux:aArray[oLbxAux:nAt][02] , oLbxAux:aArray[oLbxAux:nAt][06] , oLbxAux:aArray[oLbxAux:nAt][07] } )

If lTemNF
	FWAlertWarning("Não é possível excluir um lançamento de CNF que tenha gerado uma NF de Entrada no Sistema!","AGLT03617")
ElseIf FWAlertYesNo( "Confirma a exclusão? Essa operação não poderá ser desfeita!","AGLT03618")
	ZZ4->(DBSetOrder(1))
	If ZZ4->(DBSeek(xFilial('ZZ4')+ZLE->ZLE_COD+oLbxAux:aArray[oLbxAux:nAt][01]+oLbxAux:aArray[oLbxAux:nAt][02]+oLbxAux:aArray[oLbxAux:nAt][06]+oLbxAux:aArray[oLbxAux:nAt][07]))
		ZZ4->( RecLock( 'ZZ4' , .F. ) )
		ZZ4->( DBDelete() )
		ZZ4->( MSUnLock() )
	EndIf
	aDel( oLbxAux:aArray	, oLbxAux:nAt				)
	aSize( oLbxAux:aArray	, Len(oLbxAux:aArray) - 1	)
EndIf

Return

/*
===============================================================================================================================
Programa----------: AGLT036VSA
Autor-------------: Alexandre Villar
Data da Criacao---: 18/07/2014
Descrição---------: 
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT036VSA(aDadFor As Array,nQtdAux As Numeric,nValAux As Numeric)

Local _cAlias	:= GetNextAlias() As Character
Local _nCont	:= 0 As Numeric

// Verifica os fechamentos para recuperar a média de Valor
BeginSql Alias _cAlias
	SELECT SUM(ZLF_TOTAL) TOTAL
	FROM  %Table:ZLF% ZLF
	WHERE ZLF.D_E_L_E_T_ = ' '   
	AND ZLF.ZLF_FILIAL = %xFilial:ZLF%
	AND ZLF.ZLF_RETIRO = %exp:aDadFor[01]%
	AND ZLF.ZLF_RETILJ = %exp:aDadFor[02]%
	AND ZLF.ZLF_SETOR = %exp:aDadFor[03]%
	AND ZLF.ZLF_LINROT = %exp:aDadFor[04]%
	AND ZLF.ZLF_DTINI >= %exp:aDadFor[05]%
	AND ZLF.ZLF_DTFIM <= %exp:aDadFor[06]%
	AND ZLF.ZLF_TP_MIX = 'L'
	AND ZLF.ZLF_DEBCRE = 'C'
EndSql

If (_cAlias)->(!Eof())
	nValAux := (_cAlias)->TOTAL
EndIf

(_cAlias)->(DBCloseArea())

nQtdAux := U_VolLeite( xFilial('ZZ4') , SToD(aDadFor[05]) , SToD(aDadFor[06]) , ZL3->ZL3_SETOR , ZL3->ZL3_COD , SA2->A2_COD , SA2->A2_LOJA )
nQtdAux := Round( nQtdAux , 2 )
nValAux := Round( ( nValAux / nQtdAux ) , 2 )

_cAlias	:= GetNextAlias()
BeginSql Alias _cAlias
	SELECT SubStr( ZLD_DTCOLE , 1 , 6 )	DT_REF,
			SUM( ZLD_QTDBOM ) AS QT_REF
	FROM  %Table:ZLD% ZLD
	WHERE ZLD.D_E_L_E_T_ = ' '   
	AND ZLD.ZLD_FILIAL = %xFilial:ZLF%
	AND ZLD.ZLD_RETIRO = %exp:aDadFor[01]%
	AND ZLD.ZLD_RETILJ = %exp:aDadFor[02]%
	AND ZLD.ZLD_SETOR = %exp:aDadFor[03]%
	AND ZLD.ZLD_LINROT = %exp:aDadFor[04]%
	AND ZLD.ZLD_DTCOLE BETWEEN %exp:aDadFor[05]% AND %exp:aDadFor[06]%
	GROUP BY SubStr( ZLD_DTCOLE , 1 , 6 )
	ORDER BY SubStr( ZLD_DTCOLE , 1 , 6 )
EndSql
nQtdAux := 0

While (_cAlias)->(!Eof())
	_nCont++
	nQtdAux += (_cAlias)->QT_REF
	(_cAlias)->(DBSkip())
EndDo

(_cAlias)->(DBCloseArea())

If _nCont > 0
	nQtdAux := Round( ( nQtdAux / _nCont ) , 2 )
EndIf

Return

/*
===============================================================================================================================
Programa----------: AGLT036CLS
Autor-------------: Alexandre Villar
Data da Criacao---: 18/07/2014
Descrição---------: 
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT036CLS(oLbxAux As Object) As Logical

Local _aArea	:= FWGetArea() As Array
Local _cMsg		:= '' As Character
Local _nI		:= 0 As Numeric
Local _lRet		:= .T. As Logical
Local _lDiff	:= .F. As Logical
Local _lSave	:= .F. As Logical

For _nI := 1 To Len( oLbxAux:aArray )
	If	!Empty( oLbxAux:aArray[_nI][01] )	.And. !Empty( oLbxAux:aArray[_nI][02] )	.And.;
		!Empty( oLbxAux:aArray[_nI][06] )	.And. !Empty( oLbxAux:aArray[_nI][07] )	.And.;
		!Empty( oLbxAux:aArray[_nI][08] )	.And. !Empty( oLbxAux:aArray[_nI][09] )
		
		ZZ4->( DBSetOrder(1) )
		If ZZ4->( DBSeek( xFilial('ZZ4') + ZLE->ZLE_COD + oLbxAux:aArray[_nI][01] + oLbxAux:aArray[_nI][02] + oLbxAux:aArray[_nI][06] + oLbxAux:aArray[_nI][07] ) )
			If	ZZ4->ZZ4_QTDE <> oLbxAux:aArray[_nI][08] .Or. ZZ4->ZZ4_VALOR <> oLbxAux:aArray[_nI][09]
				_lDiff := .T.
			EndIf
		Else
			_lSave := .T.
		EndIf
	EndIf
Next _nI

If _lDiff .And. _lSave
	_cMsg := 'Existem registros que foram alterados e incluídos e que ainda não foram salvos!'
ElseIf _lDiff
	_cMsg := 'Existem registros que foram alterados e que ainda não foram salvos!'
ElseIf _lSave
	_cMsg := 'Existem registros que foram incluídos e que ainda não foram salvos!'
EndIf

If !Empty( _cMsg )
	_lRet := ApMsgYesNo( _cMsg + CRLF + CRLF + 'Deseja sair mesmo assim?',"AGLT03619")
EndIf

FWRestArea(_aArea)

Return _lRet 

/*
===============================================================================================================================
Programa----------: AGLT36NF
Autor-------------: Alexandre Villar
Data da Criacao---: 18/07/2014
Descrição---------: 
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT36NF

Local _aParam	:= {} As Array
Local _aParRet	:= {} As Array
Local _bValSet	:= 'cSetor := &(ReadVar()) , ( Vazio() .Or. ExistCpo( "ZL2" , cSetor ) )' As Codeblock
Local _bValLin	:= 'Vazio() .Or. Posicione("ZL3",1,xFilial("ZL3")+&(ReadVar()),"ZL3_SETOR") == cSetor' As Codeblock

Private cSetor	:= '' As Character

aAdd( _aParam , { 01 , "Setor"		, Space(TamSX3('ZL2_COD')[01])	, "" , _bValSet	, "ZL2_01" , "" , 0  , .F. } )
aAdd( _aParam , { 01 , "Linha de"	, Space(TamSX3('ZL3_COD')[01])	, "" , _bValLin , "ZL3_02" , "" , 0  , .F. } )
aAdd( _aParam , { 01 , "Linha até"	, Space(TamSX3('ZL3_COD')[01])	, "" , _bValLin , "ZL3_02" , "" , 0  , .F. } )

_aParRet := { Space(TamSX3('ZL2_COD')[01]) , Space(TamSX3('ZL3_COD')[01]) , Space(TamSX3('ZL3_COD')[01]) }

If ParamBox( _aParam , "Opções de Inicialização:" , @_aParRet ,,, .T. ,,,,, .F. , .F. )
		MessageBox(	'Essa função tem como finalidade gerar as Notas Fiscais de Entrada referentes às Contra Notas '	+;
					'dos Produtores lançadas no MIX: '+ ZLE->ZLE_COD +CRLF +' '				+;
					'Na tela seguinte, selecione as Contra Notas que deseja processar!'								,;
					'Documento de Entrada'																			, 0 )
			
		LjMsgRun( 'Verificando os registros...' , 'Aguarde!' , {|| AGLT036VFT() } )
			
		Processa( {|| AGLT036ENF() } , 'Inicializando o processo...' , 'Emissão de Notas Fiscais de Entrada' )
Else
	FWAlertInfo("Operação cancelada pelo usuário!","AGLT03620")
EndIf

Return

/*
===============================================================================================================================
Programa----------: AGLT036ENF
Autor-------------: Alexandre Villar
Data da Criacao---: 18/07/2014
Descrição---------: 
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT036ENF

Local _aLstCNF	:= {} As Array
Local _aHeader	:= { "Sel" , "Dt. Emissão" , "Cód. Produtor" , "Loja" , "Série NF" , "Núm. Doc." , "Qtde." , "Valor Unit." , "Valor Total" } As Array
Local _aHdrErr	:= { 'Problema' , 'Tabela' , 'Obs.' } As Array
Local _aLogErr	:= {} As Array
Local _nI		:= 0 As Numeric
Local _nConta	:= 0 As Numeric
Local _nTotReg	:= 0 As Numeric
Local _lConf	:= .F. As Logical
Local _lTemSel	:= .F. As Logical

ProcRegua(0)

ZZ4->( DBSetOrder(1) )
If ZZ4->( DBSeek( xFilial("ZZ4") + ZLE->ZLE_COD) )
	While ZZ4->( ZZ4_FILIAL + ZZ4_CODMIX) == xFilial("ZZ4") + ZLE->ZLE_COD
		_nConta++
		IncProc( 'Lendo registros: '+ StrZero( _nConta , 6 ) )
		
		If ZZ4->ZZ4_STATUS == "1"
			SA2->( DBSetOrder(1) )
			If SA2->( DBSeek( xFilial('SA2') + ZZ4->( ZZ4_CODPRO + ZZ4_LOJPRO ) ) )
				If !Empty(MV_PAR02) .And. !Empty(MV_PAR03) .And. ( SA2->A2_L_LI_RO < MV_PAR02 .Or. SA2->A2_L_LI_RO > MV_PAR03 )
					ZZ4->( DBSkip() )
					Loop
				EndIf
				
				If Empty(MV_PAR01)
					aAdd( _aLstCNF , {	.F.			  					,;
										ZZ4->ZZ4_EMISSA					,;
										ZZ4->ZZ4_CODPRO					,;
										ZZ4->ZZ4_LOJPRO					,;
										ZZ4->ZZ4_SERIE					,;
										ZZ4->ZZ4_NUMCNF					,;
										ZZ4->ZZ4_QTDE					,;
										ZZ4->ZZ4_VALOR					,;
										ZZ4->(ZZ4_QTDE * ZZ4_VALOR )	,;
										ZZ4->( Recno() )				})
				Else
					ZL3->( DBSetOrder(1) )
					If ZL3->( DBSeek( xFilial('ZL3') + SA2->A2_L_LI_RO ) ) .And. ZL3->ZL3_SETOR == MV_PAR01
						aAdd( _aLstCNF , {	.F.			  					,;
											ZZ4->ZZ4_EMISSA					,;
											ZZ4->ZZ4_CODPRO					,;
											ZZ4->ZZ4_LOJPRO					,;
											ZZ4->ZZ4_SERIE					,;
											ZZ4->ZZ4_NUMCNF					,;
											ZZ4->ZZ4_QTDE					,;
											ZZ4->ZZ4_VALOR					,;
											ZZ4->(ZZ4_QTDE * ZZ4_VALOR )	,;
											ZZ4->( Recno() )				})
					EndIf
				EndIf
			EndIf
		EndIf
		ZZ4->( DBSkip() )
	EndDo
	
	_nTotReg := Len( _aLstCNF )
	
	If _nTotReg > 0
		_lConf		:= U_ITListBox( "Geração das Notas de Entrada via CNF" , _aHeader , @_aLstCNF , .T. , 2 , 'Selecione as CNF que deseja gerar! | Mix: '+ ZLE->ZLE_COD )
		_lTemSel	:= .F.
		
		If _lConf
			For _nI :=1 To _nTotReg
				If _aLstCNF[_nI][01]
					_lTemSel := .T.
					Exit
				EndIf
			Next _nI
			
			If _lTemSel
				ProcRegua(_nTotReg)
				For _nI := 1 To _nTotReg
					IncProc( 'Gravando registros... ['+ StrZero(_nI,6) +'] de ['+ StrZero(_nTotReg,6) +']' )
					If _aLstCNF[_nI][01]
						AGLT036GNF( _aLstCNF[_nI] , @_aLogErr )
					EndIf
				Next _nI
			Else
				FWAlertWarning("Não foram selecionadas CNF para processamento. Verifique os dados e tente novamente!","AGLT03621")
			EndIf
		Else
			FWAlertInfo("Operação cancelada pelo usuário!","AGLT03622")
		EndIf
	Else
		FWAlertInfo("Não existem registros pendentes para a geração de NF. Verifique o MIX selecionado e os parâmetros informados!","AGLT03623")
	EndIf
Else
	FWAlertInfo("Não foram encontrados registros nessa Filial para o MIX Selecionado.","AGLT03624")
EndIf

If !Empty(_aLogErr)
	FWAlertWarning( "Foram encontrados problemas na inclusão das NF de Entrada! Verifique o Log a seguir.","AGLT03625")
	U_ITListBox( 'Falhas na geração de NF.' , _aHdrErr , _aLogErr , .T. , 1 , '' )
EndIf

Return

/*
===============================================================================================================================
Programa----------: AGLT036GNF
Autor-------------: Alexandre Villar
Data da Criacao---: 18/07/2014
Descrição---------: 
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT036GNF(_aDadCNF As Array,_aLogErr As Array)

Local _aCab		:= {} As Array
Local _aItens	:= {} As Array
Local _aFiltro	:= {} As Array
Local _cCodPrd	:= SuperGetMV("LT_CNFCPRD",.F.,"08000000030") As Character
Local _cCodTES	:= SuperGetMV("LT_CNFCTES",.F.,"013") As Character
Local _cCodCC	:= SuperGetMV("LT_CNFCCC",.F.," ") As Character
Local _aErro	:= {} As Array
Local _cMsg		:= '' As Character
Local _nX		:= 0 As Numeric
Private lMsErroAuto		:= .F. As Logical
Private lMsHelpAuto		:= .T. As Logical
Private lAutoErrNoFile	:= .T. As Logical

Default _aDadCNF	:= {}
_aLogErr			:= {}

If !Empty( _aDadCNF )
	SA2->( DBSetOrder(1) )
	If SA2->( DBSeek( xFilial("SA2") + _aDadCNF[03] + _aDadCNF[04] ) )
		_aFiltro := { _aDadCNF[03] , _aDadCNF[04] , _aDadCNF[05] , _aDadCNF[06] }
		ZZ4->( DBGoTo( _aDadCNF[10] ) )

		If !AGLT036VNF( _aFiltro )
			_aCab := {	{ 'F1_DOC'		, StrZero( Val(_aDadCNF[06]) , TamSX3("F1_DOC")[01] )	, NIL },; // Numero do Documento.
						{ 'F1_SERIE'	, AllTrim( _aDadCNF[05] )								, NIL },; // Serie do Documento.
						{ 'F1_PREFIXO'	, AllTrim( _aDadCNF[05] )								, NIL },; // Serie do Documento.
						{ 'F1_DTDIGIT'	, dDataBase												, NIL },; // Data de Digitação
						{ 'F1_EMISSAO'	, dDataBase												, NIL },; // Data de Emissao.
						{ 'F1_DESPESA'	, 0														, NIL },; // Despesa.
						{ 'F1_FORNECE'	, SA2->A2_COD											, NIL },; // Codigo do Fornecedor.
						{ 'F1_LOJA'	  	, SA2->A2_LOJA											, NIL },; // Loja do Fornecedor.
						{ 'F1_ESPECIE'	, 'NFP'													, NIL },; // Especie do Documento.
						{ 'F1_TIPO'		, 'N'													, NIL },; // Tipo da Nota.
						{ 'F1_FORMUL'	, 'N'													, NIL },; // TP Frete
						{ 'F1_L_MIX'	, ZZ4->ZZ4_CODMIX										, NIL } } // Codigo do Mix
			
			SB1->( DBSetOrder(1) )
			If SB1->( DBSeek( xFilial("SB1") + _cCodPrd ) )
				aAdd( _aItens , {	{ "D1_ITEM"		, '0001'									, NIL },; // Sequencia Item Pedido
									{ "D1_COD"		, SB1->B1_COD								, NIL },; // Codigo do Produto
									{ "D1_QUANT"	, _aDadCNF[07]								, NIL },; // Quantidade
									{ "D1_VUNIT"	, _aDadCNF[08]								, NIL },; // Valor Unitario
									{ "D1_TOTAL"	, _aDadCNF[09]								, NIL },; // Valor Total
									{ "D1_TES"		, _cCodTES									, NIL },; // Tipo de Entrada - TES
									{ "D1_LOCAL"	, SB1->B1_LOCPAD							, NIL },; // Armazem Padrao do Produto
									{ "D1_SEGURO"	, 0											, NIL },; // Seguro
									{ "D1_VALFRE"	, 0											, NIL },; // Frete
									{ "D1_DESPESA"	, 0											, NIL },; // Despesa
									{ 'D1_CC'		, _cCodCC									, NIL },; // Centro de Custo
									{ 'D1_DFABRIC'	, SToD('')									, NIL },; // Data de Fabricação
									{ "D1_L_SEEK"	, ''										, NIL }}) // Chave de pesquisa da SD1 na ZLF
			EndIf
		Else
			ZZ4->( DBGoTo( _aDadCNF[10] ) )
			ZZ4->( RecLock( 'ZZ4' , .F. ) )
			ZZ4->ZZ4_STATUS := '2'
			ZZ4->( MSUnLock() )
			aAdd( _aLogErr , { 'VLD_GER: Já existe uma NF para o Produtor com o código atual!' , 'SF1: '+ DToC(Date()) +' Validação.' , 'Registro duplicado!' } )
		EndIf
	EndIf
	
	If !Empty(_aCab) .And. !Empty(_aItens)
		LjMsgRun( 'Gerando NF de Entrada...' , 'Aguarde!' , {|| MSExecAuto( {|x,y,z| Mata103(x,y,z) } , _aCab , _aItens , 3 ) } )
	EndIf
	
	If lMsErroAuto
		_aErro := GetAutoGrLog()
		_cMsg := ""

		For _nX := 1 To Len(_aErro)
			_cMsg += _aErro[_nX] + '; '
		Next _nX
		aAdd( _aLogErr , {_cMsg,"SF1","Erro no Execauto MATA103"} )
	Else
		ZZ4->( RecLock( 'ZZ4' , .F. ) )
		ZZ4->ZZ4_STATUS := '2'
		ZZ4->( MSUnLock() )
	EndIf
	
EndIf

Return

/*
===============================================================================================================================
Programa----------: AGLT36VL
Autor-------------: Alexandre Villar
Data da Criacao---: 18/07/2014
Descrição---------: Validação dos Produtores com movimentação e que não possuem CNF Lançada
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT36VL

Local _aResult	:= {} As Array
Local _aParAux	:= {} As Array
Local _aParRet	:= {} As Array
Local _aCabec	:= { 'Produtor' , 'Loja' , 'Nome' , 'Linha' , 'Descrição' , 'MIX' , 'Período' , 'Volume Mov.' , 'Status CNF' , 'NF Entrada' } As Array
Local _aParOpc	:= { 'Pendentes' , 'Concluídos' , 'Todos' } As Array
Local _cAlias	:= GetNextAlias() As Character
Local _cQuery	:= '%' As Character
Local _cTitJan	:= 'Análise de Lançamentos de CNF' As Character
Local _nOpcFil	:= 0 As Numeric

Private _cFiltro	:= '' As Character
Private _cCodUsr	:= Space( TamSX3('ZLU_CODUSU')[01] ) As Character

// Verifica o tipo de análise a realizar
aAdd( _aParAux , { 3 , 'Tipo de Registro'	, 1			, _aParOpc , 80            , ''     , .T. } ) ; aAdd( _aParRet , _aParAux[01][03] )
aAdd( _aParAux , { 1 , 'Código do Técnico'	, _cCodUsr	, ''       , '' , 'ZLU_01' , '' , 0 , .F. } ) ; aAdd( _aParRet , _aParAux[02][03] )

If ParamBox( _aParAux , 'Configuração Inicial:' , @_aParRet ,,, .T. ,,,,, .F. , .F. )
	_nOpcFil := _aParRet[01]
Else
	FWAlertInfo("Operação cancelada pelo usuário!","AGLT03626")
	Return
EndIf

If !Empty( _cFiltro )
	_cQuery += "AND SA2.A2_L_LI_RO IN "+ FormatIn( _cFiltro , ';' )
EndIf
_cQuery +="%"

LjMsgRun( "Verificando dados do Mix..." , "Aguarde!" )

BeginSql Alias _cAlias
SELECT ZLD.ZLD_RETIRO,
       ZLD.ZLD_RETILJ,
       SA2.A2_NOME,
       ZL3.ZL3_COD,
       ZL3.ZL3_DESCRI,
       (SELECT ZZ4.R_E_C_N_O_
          FROM %Table:ZZ4% ZZ4
         WHERE ZZ4.D_E_L_E_T_ = ' '
           AND ZZ4.ZZ4_FILIAL = ZLD.ZLD_FILIAL
           AND ZZ4.ZZ4_CODPRO = ZLD.ZLD_RETIRO
           AND ZZ4.ZZ4_LOJPRO = ZLD.ZLD_RETILJ
           AND ZZ4.ZZ4_CODMIX = %exp:ZLE->ZLE_COD%) REGZZ4,
       (SELECT SF1.R_E_C_N_O_
          FROM %Table:SF1% SF1
         WHERE SF1.D_E_L_E_T_ = ' '
           AND SF1.F1_FILIAL = ZLD.ZLD_FILIAL
           AND SF1.F1_FORNECE = ZLD.ZLD_RETIRO
           AND SF1.F1_LOJA = ZLD.ZLD_RETILJ
           AND SF1.F1_FORMUL <> 'S'
           AND SF1.F1_L_MIX = %exp:ZLE->ZLE_COD%) REGSF1,
       SUM(ZLD.ZLD_QTDBOM) AS VOL_LEITE
  FROM %Table:SA2% SA2, %Table:ZLD% ZLD, %Table:ZL3% ZL3
 WHERE SA2.D_E_L_E_T_ = ' '
   AND ZLD.D_E_L_E_T_ = ' '
   AND ZL3.D_E_L_E_T_ = ' '
   AND ZLD.ZLD_FILIAL = %xFilial:ZLD%
   AND SA2.A2_FILIAL = %xFilial:SA2%
   AND ZL3.ZL3_FILIAL = %xFilial:ZL3%
   AND SA2.A2_COD = ZLD.ZLD_RETIRO
   AND SA2.A2_LOJA = ZLD.ZLD_RETILJ
   AND ZL3.ZL3_COD = SA2.A2_L_LI_RO
   AND ZLD.ZLD_RETIRO <> ' '
   AND ZLD.ZLD_RETILJ <> ' '
   %exp:_cQuery%
   AND ZLD.ZLD_DTCOLE BETWEEN %exp:ZLE->ZLE_DTINI% AND %exp:ZLE->ZLE_DTFIM%
 GROUP BY ZLD.ZLD_FILIAL, ZLD.ZLD_RETIRO, ZLD.ZLD_RETILJ, SA2.A2_NOME, ZL3.ZL3_COD, ZL3.ZL3_DESCRI
 ORDER BY ZLD.ZLD_RETIRO
EndSql

If (_cAlias)->( !Eof() )
	While (_cAlias)->( !Eof() )
		// Verifica o Filtro caso deva exibir somente os pendentes
		If _nOpcFil == 1 .And. !Empty( (_cAlias)->REGSF1 )
			(_cAlias)->( DBSkip() )
			Loop
		EndIf
		
		// Verifica o Filtro caso deva exibir somente os concluídos
		If _nOpcFil == 2 .And. Empty( (_cAlias)->REGSF1 )
			(_cAlias)->( DBSkip() )
			Loop
		EndIf
		
		aAdd( _aResult , {	(_cAlias)->ZLD_RETIRO									,; //Código do Produtor
							(_cAlias)->ZLD_RETILJ									,; //Loja do Produtor
							Capital( AllTrim( (_cAlias)->A2_NOME ) )				,; //Nome do Produtor
							(_cAlias)->ZL3_COD										,; //Código da Linha
							AllTrim((_cAlias)->ZL3_DESCRI)							,; //Descrição da Linha
							ZLE->ZLE_COD											,; //Código do MIX
							DToC(ZLE->ZLE_DTINI) +' - '+ DToC(ZLE->ZLE_DTFIM)		,; //Período do MIX
							(_cAlias)->VOL_LEITE								  	,; //Volume Movimentado
							IIf( Empty((_cAlias)->REGZZ4) , 'Pendente' , 'Lançada'	),; //Status CNF
							IIf( Empty((_cAlias)->REGSF1) , 'Pendente' , 'Gerada'	)}) //Status SF1
	
		
		(_cAlias)->( DBSkip() )
	EndDo
    
	If Empty(_aResult)
		FWAlertInfo("Não foram encontrados registros "+ IIf( _nOpcFil == 1 , "Pendentes" , IIf( _nOpcFil == 2 , "Concluídos" , "" ) ) +" para exibir!", "AGLT03627")
	Else
		If _nOpcFil == 1
			_cMsgAux	:= '['+ StrZero( Len(_aResult) , 6 )+'] Produtores não possuem lançamentos de CNF no período do MIX analisado.'
		ElseIf _nOpcFil == 2
			_cMsgAux	:= '['+ StrZero( Len(_aResult) , 6 )+'] Produtores já foram regularizados no período do MIX analisado.'
		Else
			_cMsgAux	:= '['+ StrZero( Len(_aResult) , 6 )+'] Produtores com movimentação no MIX analisado. Verifique os Status.'
		EndIf
		
		U_ITListBox( _cTitJan , _aCabec , _aResult , .T. , 1 , _cMsgAux )
	EndIf
Else
	FWAlertInfo("Não foram encontrados movimentos para o MIX selecionado!","AGLT03628")
EndIf

(_cAlias)->(DBCloseArea())

Return

/*
===============================================================================================================================
Programa----------: AGLT036VFT
Autor-------------: Alexandre Villar
Data da Criacao---: 18/07/2014
Descrição---------: Validação dos Produtores com movimentação e que não possuem CNF Lançada
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT036VFT

ZZ4->( DBSetOrder(1) )
If ZZ4->( DBSeek( xFilial('ZZ4') + ZLE->ZLE_COD ) )
	While xFilial('ZZ4') + ZLE->ZLE_COD == ZZ4->( ZZ4_FILIAL + ZZ4_CODMIX)
		cStatus := IIf( AGLT036VNF( { ZZ4->ZZ4_CODPRO , ZZ4->ZZ4_LOJPRO , ZZ4->ZZ4_SERIE , ZZ4->ZZ4_NUMCNF } ) , "2" , "1" )
		If cStatus <> ZZ4->ZZ4_STATUS
			ZZ4->( RecLock( 'ZZ4' , .F. ) )
			ZZ4->ZZ4_STATUS := cStatus
			ZZ4->( MSUnLock() )
		EndIf
	ZZ4->( DBSkip() )
	EndDo
EndIf

Return

/*
===============================================================================================================================
Programa--------: AGLT036C
Autor-----------: Alexandre Villar
Data da Criacao-: 06/01/2015
Descrição-------: Consulta genérica para F3 dos usuários do Leite
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT036C As Logical

Local lRet 	   		:= .F. As Logical
Local nRetorno 		:= 0 As Numeric
Local cQuery   		:= "" As Character

_cFiltro := ''

//-- Monta Query da Consulta --//
cQuery := " SELECT DISTINCT ZLU.ZLU_CODUSU, ZLU.ZLU_NOME, ZLU.R_E_C_N_O_ ZLURECNO FROM "+ RETSQLNAME('ZLU') +" ZLU "
cQuery += " INNER JOIN "+ RETSQLNAME('ZLR') +" ZLR ON ZLU_CODUSU = ZLR_CODUSU
cQuery += " WHERE "+ RETSQLCOND('ZLU,ZLR')
cQuery += " AND ZLU.ZLU_MATRIC LIKE '"+ cFilAnt +"%' "
cQuery := ChangeQuery(cQuery)
//-- Tela de F3 padrao --//
If Tk510F3Qry( cQuery , "ZLU_CODUSU, ZLU_NOME" , "ZLURECNO" , @nRetorno ,, { "ZLU_CODUSU" , "ZLU_NOME" } , "ZLU" )
	If nRetorno == 0
		_cFiltro := ""
	Else
		DBSelectArea('ZLU')
		ZLU->( DBGoTo( nRetorno ) )
		DBSelectArea("ZLR")
		ZLR->( DBSetOrder(1) )
		If ZLR->( DBSeek( xFilial('ZLR') + ZLU->ZLU_CODUSU ) )
			While ZLR->(!Eof()) .And. ZLR->ZLR_CODUSU == ZLU->ZLU_CODUSU
				_cFiltro += ZLR->ZLR_LINHA + ";"
			ZLR->( DBSkip() )
			EndDo
		EndIf
	EndIf
	
	lRet		:= .T.
	_cFiltro	:= SubStr( _cFiltro , 1 , Len(_cFiltro) - 1 )
EndIf

Return( .T. )
