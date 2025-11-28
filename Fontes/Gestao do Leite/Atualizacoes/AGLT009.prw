/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |04/07/2019| Chamado 29866. Correção na origem do título.
Lucas Borges  |27/09/2019| Chamado 28346. Revisão de fontes.
Lucas Borges  |12/12/2021| Chamado 38596. Retirada função proibída para controle de transação.
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "FWMVCDef.ch"

/*
===============================================================================================================================
Programa----------: AGLT009
Autor-------------: Alexandre Villar
Data da Criacao---: 19/12/2014
Descrição---------: Lançamentos avulsos para pagamento de produtores. Chamado 8374
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT009()

Local _oBrowse := Nil

//====================================================================================================
// Configura e inicializa a Classe do Browse
//====================================================================================================
_oBrowse := FWMBrowse():New()

_oBrowse:SetAlias( 'Z08' )
_oBrowse:SetMenuDef( 'AGLT009' )
_oBrowse:SetDescription( 'Lançamentos avulsos para pagamento de Produtores' )
_oBrowse:DisableDetails()

_oBrowse:AddLegend( "Z08_STSJUR=='A'" , "GREEN"		, "Aprovado" )
_oBrowse:AddLegend( "Z08_STSJUR<>'A'" , "RED"		, "Pendente" )

_oBrowse:Activate()

Return

/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Alexandre Villar
Data da Criacao---: 19/12/2014
Descrição---------: Rotina de definição automática do menu via MVC
Parametros--------: Nenhum
Retorno-----------: aRotina - Definições do menu principal da Rotina.
===============================================================================================================================
*/
Static Function MenuDef()

Local _aRotina	:= {}

ADD OPTION _aRotina Title 'Visualizar'		Action 'VIEWDEF.AGLT009'	OPERATION 2 ACCESS 0
ADD OPTION _aRotina Title 'Importar'		Action 'U_AGLT009I()'		OPERATION 3 ACCESS 0
ADD OPTION _aRotina Title 'Gerar Termo'		Action 'U_AGLT009J()'		OPERATION 2 ACCESS 0
ADD OPTION _aRotina Title 'Gerar FIN'		Action 'U_AGLT009G()'		OPERATION 2 ACCESS 0
ADD OPTION _aRotina Title 'Rel. Jurídico'	Action 'U_AGLT009R()'		OPERATION 2 ACCESS 0
ADD OPTION _aRotina Title 'Avaliar'			Action 'U_AGLT009A()'		OPERATION 2 ACCESS 0

Return( _aRotina )

/*
===============================================================================================================================
Programa----------: ModelDef
Autor-------------: Alexandre Villar
Data da Criacao---: 19/12/2014
Descrição---------: Rotina de definição do Modelo de Dados do MVC
Parametros--------: Nenhum
Retorno-----------: oModel - Objeto do modelo de dados do MVC
===============================================================================================================================
*/
Static Function ModelDef()

//===========================================================================
//| Inicializa a estrutura do modelo de dados                               |
//===========================================================================
Local _oStruZ08 	:= FWFormStruct( 1 , "Z08" )
Local _oModel		:= Nil

//===========================================================================
//| Inicializa e configura o modelo de dados                                |
//===========================================================================
_oModel := MPFormModel():New( "AGLT009M" )

_oModel:SetDescription( 'Lançamentos avulsos para pagamentos de Produtores' )
_oModel:AddFields( 'Z08MASTER' ,, _oStruZ08 )
_oModel:GetModel( 'Z08MASTER' ):SetDescription( 'Lançamentos Avulsos' )

Return( _oModel )

/*
===============================================================================================================================
Programa----------: ViewDef
Autor-------------: Alexandre Villar
Data da Criacao---: 19/12/2014
Descrição---------: Rotina de definição da View do MVC
Parametros--------: Nenhum
Retorno-----------: oView - Objeto de exibição do MVC
===============================================================================================================================
*/
Static Function ViewDef()

Local _oModel   	:= FWLoadModel( "AGLT009" )
Local _oStruZ08 	:= FWFormStruct( 2 , "Z08" )
Local _oView		:= Nil

//===========================================================================
//| Inicializa o Objeto da View                                             |
//===========================================================================
_oView := FWFormView():New()

_oView:SetModel( _oModel )
_oView:AddField( "VIEW_Z08" , _oStruZ08 , "Z08MASTER" )
_oView:CreateHorizontalBox( 'BOX0101' , 100 )
_oView:SetOwnerView( "VIEW_Z08", "BOX0101" )

Return( _oView )

/*
===============================================================================================================================
Programa----------: AGLT009I
Autor-------------: Alexandre Villar
Data da Criacao---: 19/12/2014
Descrição---------: Validação da inclusão de registros
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT009I()

Local _oDlg		:= Nil
Local _oLbx		:= Nil
Local _cTit		:= 'Selecione o arquivo a importar:'
Local _bOk 		:= {|| LjMsgRun( 'Importando os registros...' , 'Aguarde!' , {|| AGLT009GRV(_cAlias) } )	, _oDlg:End() }
Local _bCan		:= {|| Aviso('Atenção!' , 'Operação cancelada pelo usuário!' , {'Fechar'} )					, _oDlg:End() }
Local _oArq		:= Nil
Local _cArq		:= Nil
Local _cTip		:= 'Arquivos de Texto (*.TXT) | *.TXT |'
Local _aSize	:= MsAdvSize()
Local _aInfo	:= {}
Local _aObj		:= {}
Local _aPosObj	:= {}
Local _cAlias	:= GetNextAlias()
Local aArqTmp	:= {}
Local _nI		:= 0
Local _aHeader	:= {	{ "PRODUTOR" 	, "Cód. Produtor"	,"C","@!"					,10,0} ,;
						{ "NOME" 		, "Nome Produtor"	,"C","@!"					,40,0} ,;
						{ "NOTA"	 	, "Número NF"		,"C","@!"					,09,0} ,;
						{ "SERIE"	 	, "Série NF"		,"C","@!"					,03,0} ,;
						{ "EMISSAO"		, "Dt. Baixa" 		,"D","@!"					,08,0} ,;
						{ "VALORNF"		, "Valor Nota"		,"N","@E 999,999,999.99"	,15,2} ,;
						{ "VALORAD"		, "Adiantamento"	,"N","@E 999,999,999.99"	,15,2} ,;
						{ "SALDO"		, "Saldo Pagar"		,"N","@E 999,999,999.99"	,15,2}  }

aAdd( _aObj , { 100 , 100 , .T. , .T. } )

_aInfo		:= { _aSize[1] , _aSize[2] , _aSize[3] , _aSize[4] , 3 , 3 }
_aPosObj	:= MsObjSize( _aInfo , _aObj )

aAdd(aArqTmp,{ "LINHA"	, "C" , 6 , 0 } )
For _nI := 1 To Len(_aHeader)
	aAdd(aArqTmp,{ _aHeader[_nI][01] , _aHeader[_nI][03] , _aHeader[_nI][05] , _aHeader[_nI][06] } )
Next _nI

//----------------------------------------------------------------------
// Cria arquivo de dados temporário
//----------------------------------------------------------------------
_oTempTable := FWTemporaryTable():New( _cAlias, aArqTmp )
_oTempTable:Create()

DBSelectArea(_cAlias)

DEFINE MSDIALOG _oDlg TITLE _cTit From 000,000 To 055, 240			OF _oDlg

	@ 002 , 002 TO 018,300 LABEL ''		   							OF _oDlg PIXEL
	@ 006 , 005	Say 'Arquivo de importação: '						OF _oDlg PIXEL SIZE 060,009
	@ 004 , 065	MSGET _oArq VAR _cArq	 							OF _oDlg PIXEL SIZE 205,010 PICTURE "@!"
	
	DEFINE SBUTTON FROM 004 , 270 Type 14							OF _oDlg ENABLE ;
	ACTION ( _cArq := cGetFile(_cTip,'Informe o arquivo a Importar:',0,'SERVIDOR\',.T.,GETF_LOCALHARD+GETF_NETWORKDRIVE) , LjMsgRun('Verificando o arquivo...','Aguarde!',{|| AGLT009INI( _cArq , @_oLbx , _aHeader , _cAlias ) } ) , _oLbx:Refresh() )
	
	@ 020 , 002 TO _aPosObj[01][03] , _aPosObj[01][04] LABEL ""		OF _oDlg PIXEL

	_oLbx := TCBrowse():New(022,005,_aPosObj[01][04]-007,_aPosObj[01][03]-024,,,,,,,,,,,,,,,,.T.,,.T.,,.F.)

	_oLbx:AddColumn( TCColumn():New( Trim("Linha") , FieldWBlock( "LINHA",Select(_cAlias)),"@!",,, "LEFT",06, .F., .F.,,,, .F., ) )
	
	For _nI := 1 To Len(_aHeader)
		_oLbx:AddColumn( TCColumn():New( Trim(_aHeader[_nI][02]), FieldWBlock( _aHeader[_nI][01],Select(_cAlias)),_aHeader[_nI][04],,, IIf(_aHeader[_nI][03]=="N","RIGHT","LEFT"),CalcFieldSize(_aHeader[_nI][03],_aHeader[_nI][05],_aHeader[_nI][06],_aHeader[_nI][04],_aHeader[_nI][02]), .F., .F.,,,, .F., ) )
	Next _nI
	
	_oDlg:lMaximized := .T.
	
ACTIVATE MSDIALOG _oDlg CENTER ON INIT EnchoiceBar( _oDlg , _bOk , _bCan )

(_cAlias)->( DBCloseArea() )
_oTempTable:Delete()

Return

/*
===============================================================================================================================
Programa----------: AGLT009INI
Autor-------------: Alexandre Villar
Data da Criacao---: 19/12/2014
Descrição---------: Validação da inclusão de registros
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT009INI( _cArq , _oLbx , _aHeader , _cAlias )

Local nHandler		:= 0
Local cBuffer 		:= ""
Local aLinha		:= {}
Local nLinha		:= 0
Local nI			:= 0

Private	_cCpoAux	:= ""

_cArq := Lower(AllTrim(_cArq))

If !File( _cArq )
	MsgStop("Arquivo informado é invalido!","AGLT00901")
	Return
EndIf

//====================================================================================================
// Abre o arquivo para Leitura
//====================================================================================================
nHandler := FOpen( _cArq , 0 )

//====================================================================================================
// Leitura dos dados do Arquivo
//====================================================================================================
FT_FUSE( _cArq )
FT_FGOTOP()

While !FT_FEOF()

	cBuffer	:= FT_FReadLn()
	aLinha	:= ITLeLin( cBuffer )

	If Len(aLinha) <= 0
		FT_FSKIP()
		Loop
	EndIf
	
	nLinha++
	
	For nI := Len(aLinha)+1 To Len(_aHeader)
		aAdd(aLinha,"")
	Next nI
	
	(_cAlias)->( RecLock( _cAlias , .T. ) )
	
		(_cAlias)->LINHA := StrZero( nLinha , 6 )
		
		For	nI := 1 To 8
		
			Do	Case
				Case _aHeader[nI][03] == "D" .And. ValType(aLinha[nI]) == "C"
					uDadoCpo := CtoD( aLinha[nI] )
				Case _aHeader[nI][03] == "N" .And. ValType(aLinha[nI]) == "C"
					uDadoCpo 	:= AllTrim( StrTran( aLinha[nI]	,".","" ) )
					uDadoCpo 	:= AllTrim( StrTran( uDadoCpo	,",",".") )
					uDadoCpo 	:= Val(uDadoCpo)
				OtherWise
					uDadoCpo := aLinha[nI]
			EndCase
			
			_cCpoAux 	:= _cAlias+"->"+AllTrim( _aHeader[nI][01] )
			&_cCpoAux	:= uDadoCpo
			
		Next nI
	
	(_cAlias)->( MSUnLock() )
	   
FT_FSKIP()
EndDo

FT_FUSE()

FClose(nHandler)

(_cAlias)->( DBGoTop() )

Return

/*
===============================================================================================================================
Programa----------: ITLeLin
Autor-------------: Alexandre Villar
Data da Criacao---: 19/12/2014
Descrição---------: Função para leitura das linhas do arquivo
Parametros--------: Nenhum
Retorno-----------: oView - Objeto de exibição do MVC
===============================================================================================================================
*/
Static Function ITLeLin( cBuffer )

Local aString	:= {}
Local cString 	:= ""       
Local cCaracter	:= ""
Local nI		:= 0
Local cDelimita	:= ";"

If SubStr(cBuffer,Len(cBuffer),1) <> cDelimita
	cBuffer += cDelimita
EndIf

For nI := 1 To Len(cBuffer)
    
	cCaracter := SubStr( cBuffer , nI , 1 )
	
	If	cCaracter == cDelimita
		aAdd( aString , cString )
		cString := ""
	Else
		cString += cCaracter
	EndIf

Next nI

Return( aString )

/*
===============================================================================================================================
Programa----------: AGLT009GRV
Autor-------------: Alexandre Villar
Data da Criacao---: 19/12/2014
Descrição---------: Rotina de gravação da importação dos dados de arquivos
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT009GRV(_cAlias)

Local _nRegSA2	:= 0
Local _aLog		:= {}
Local _nReg		:= 0

DBSelectArea(_cAlias)
(_cAlias)->( DBGoTop() )
While (_cAlias)->(!Eof())
	
	_nRegSA2 := AGLT009FOR( (_cAlias)->PRODUTOR )
	
	If !Empty(_nRegSA2) .And. _nRegSA2 > 0
		
		DBSelectArea('SA2')
		SA2->( DBGoTo( _nRegSA2 ) )
		
		DBSelectArea('Z08')
		Z08->( DBSetOrder(2) )
		If Z08->( DBSeek(	xFilial('Z08')											+;
							PadR( (_cAlias)->NOTA	, TamSX3('Z08_NF')[01]		)	+;
							PadR( (_cAlias)->SERIE	, TamSX3('Z08_SERIE')[01]	)	+;
							SA2->A2_COD												+;
							SA2->A2_LOJA											))
			
			aAdd( _aLog , { (_cAlias)->PRODUTOR , (_cAlias)->NOME , (_cAlias)->NOTA , (_cAlias)->SERIE , (_cAlias)->EMISSAO , (_cAlias)->VALORNF , 'Registro já importado anteriormente!' } )
			
		Else
		
			Z08->( RecLock('Z08',.T.) )
			
			Z08->Z08_FILIAL	:= xFilial('Z08')
			Z08->Z08_CODIGO	:= GetSXENum( 'Z08' , 'Z08_CODIGO' )
			Z08->Z08_CODORI	:= (_cAlias)->PRODUTOR
			Z08->Z08_CODFOR	:= SA2->A2_COD
			Z08->Z08_LOJFOR	:= SA2->A2_LOJA
			Z08->Z08_NF		:= (_cAlias)->NOTA
			Z08->Z08_SERIE	:= (_cAlias)->SERIE
			Z08->Z08_EMISSA	:= (_cAlias)->EMISSAO
			Z08->Z08_VALOR	:= (_cAlias)->VALORNF
			Z08->Z08_VALPAG	:= (_cAlias)->VALORAD
			Z08->Z08_SALDO	:= (_cAlias)->SALDO
			
			Z08->( MSUnLock() )
			
			_nReg++
			
			If __lSX8
				ConfirmSX8()
			EndIf
		
		EndIf
		
	Else
		aAdd( _aLog , { (_cAlias)->PRODUTOR , (_cAlias)->NOME , (_cAlias)->NOTA , (_cAlias)->SERIE , (_cAlias)->EMISSAO , (_cAlias)->VALORNF , 'Não encontrado no cadastro do Sistema!' } )
	EndIf
	
(_cAlias)->( DBSkip() )
EndDo

If Empty( _aLog )
	
	If _nReg > 0
		Aviso( "AGLT00902" , 'Todos os registros foram importados com sucesso!' , {'Ok'} )
	Else
		Aviso( "AGLT00903" , 'Nenhum registro válido foi importado! Verifique o arquivo informado e tente novamente.' , {'Fechar'} )
	EndIf
	
Else
	
	Aviso("AGLT00904",'Foram encontrados registros com inconsistências no arquivo importado! Os registros que não estiverem na relação de falha foram importados normalmente.',{'Detalhes'})
	U_ITListBox('Registros não importados:',{'Cód. Produtor','Nome','NF','Série','Emissão','Valor','Motivo'},_aLog,.F.,1,'Verifique os registros abaixo que não foram importados:')
	
EndIf

Return

/*
===============================================================================================================================
Programa----------: AGLT009FOR
Autor-------------: Alexandre Villar
Data da Criacao---: 19/12/2014
Descrição---------: Função para procurar e retornar o Recno da Tabela SA2 se o fornecedor já For cadastrado.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT009FOR( _cCodPrd )

Local _cAlias 		:= GetNextAlias()
Local _nRegSA2		:= 0

Default _cCodPrd	:= ''

//====================================================================================================
// Monta e executa a consulta no cadastro de Fornecedores
//====================================================================================================
BeginSql Alias _cAlias
	SELECT R_E_C_N_O_ REGSA2
	FROM %Table:SA2% SA2
	WHERE SA2.D_E_L_E_T_ =' '
	AND A2_L_ANTIG = %exp:_cCodPrd%
EndSql

If (_cAlias)->( !Eof() ) .And. !Empty( (_cAlias)->REGSA2 )
	_nRegSA2 := (_cAlias)->REGSA2
EndIf

(_cAlias)->( DBCloseArea() )

Return( _nRegSA2 )

/*
===============================================================================================================================
Programa----------: AGLT009J
Autor-------------: Alexandre Villar
Data da Criacao---: 19/12/2014
Descrição---------: Rotina para imprimir os documentos jurídicos de aceite das condições de pagamento.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT009J()

Local _cFiltro1	:= "%"
Local _cFiltro2	:= "%"
Local _cFiltro3	:= "%"
Local _cAlias	:= GetNextAlias()
Local _cPergJ	:= 'AGLT009J'
Local _oPrint	:= Nil
Local _nCopias	:= 2
Local _aNotas	:= {}
Local _nValNot	:= 0
Local _nAdiant	:= 0
Local _nSaldo	:= 0
Local _nCntNF	:= 0
Local _nX, _nI	:= 0
Local _oFont10	:= TFont():New( "Courier New" ,, 12 ,, .F. ,,,, .T. , .F. )
Local _oFont12	:= TFont():New( "Courier New" ,, 12 ,, .F. ,,,, .T. , .F. )
Local _oFont14	:= TFont():New( "Courier New" ,, 14 ,, .F. ,,,, .T. , .F. )
Local _oFont14b	:= TFont():New( "Courier New" ,, 14 ,, .T. ,,,, .T. , .F. )

If !Pergunte( _cPergJ )
	Aviso("AGLT00905", 'Processamento cancelado pelo usuário!' , {'Fechar'} )
	Return
EndIf

If MV_PAR09 == 2
	_nCopias := 1
EndIf

If !Empty(MV_PAR07)
	_cFiltro1 += " AND ZL3.ZL3_SETOR  = '"+ MV_PAR07 +"' "
EndIf
If !Empty(MV_PAR08)
	_cFiltro2 += " AND SA2.A2_L_LI_RO = '"+ MV_PAR08 +"' "
	_cFiltro3 += " AND ZL3.ZL3_COD    = '"+ MV_PAR08 +"' "
EndIf
_cFiltro1 += "%"
_cFiltro2 += "%"
_cFiltro3 += "%"
//====================================================================================================
// Monta a consulta dos dados a imprimir
//====================================================================================================
BeginSql alias _cAlias
	SELECT DISTINCT Z08.Z08_TERMO, Z08.Z08_CODFOR, Z08.Z08_LOJFOR, Z08.Z08_NF, Z08.Z08_SERIE, Z08.Z08_EMISSA,
	                Z08.Z08_VALOR, Z08.Z08_VALPAG, SA2.R_E_C_N_O_ REGSA2
	  FROM %Table:Z08% Z08, %Table:SA2% SA2
	 WHERE Z08.D_E_L_E_T_ = ' '
	   AND SA2.D_E_L_E_T_ = ' '
	   AND Z08.Z08_FILIAL = %xFilial:Z08% 
	   AND SA2.A2_FILIAL = %xFilial:SA2%
	   AND SA2.A2_COD = Z08.Z08_CODFOR
	   AND SA2.A2_LOJA = Z08.Z08_LOJFOR
       %exp:_cFiltro2%
	   AND Z08.Z08_CODFOR BETWEEN %exp:MV_PAR01% AND %exp:MV_PAR03%
	   AND Z08.Z08_LOJFOR BETWEEN %exp:MV_PAR02% AND %exp:MV_PAR04%
	   AND Z08.Z08_EMISSA BETWEEN %exp:MV_PAR05% AND %exp:MV_PAR06%
	   AND EXISTS (SELECT ZL3.ZL3_COD
	          FROM %Table:ZL3% ZL3
	         WHERE ZL3.ZL3_FILIAL = Z08.Z08_FILIAL
	           AND ZL3.ZL3_COD = SA2.A2_L_LI_RO
   	           %exp:_cFiltro1%
	           AND ZL3.D_E_L_E_T_ = ' ') 
	UNION ALL
	SELECT DISTINCT Z08.Z08_TERMO, Z08.Z08_CODFOR, Z08.Z08_LOJFOR, Z08.Z08_NF, Z08.Z08_SERIE, Z08.Z08_EMISSA,
	                Z08.Z08_VALOR, Z08.Z08_VALPAG, SA2.R_E_C_N_O_ REGSA2
	  FROM %Table:Z08% Z08, %Table:SA2% SA2
	 WHERE Z08.D_E_L_E_T_ = ' '
	   AND SA2.D_E_L_E_T_ = ' '
	   AND Z08.Z08_FILIAL = %xFilial:Z08% 
	   AND SA2.A2_FILIAL = %xFilial:SA2%
	   AND SA2.A2_COD = Z08.Z08_CODFOR
	   AND SA2.A2_LOJA = Z08.Z08_LOJFOR
	   AND Z08.Z08_CODFOR BETWEEN %exp:MV_PAR01% AND %exp:MV_PAR03%
	   AND Z08.Z08_LOJFOR BETWEEN %exp:MV_PAR02% AND %exp:MV_PAR04%
	   AND Z08.Z08_EMISSA BETWEEN %exp:MV_PAR05% AND %exp:MV_PAR06%
	   AND SA2.A2_I_CLASS = 'G'
	   AND EXISTS
	 (SELECT ZL3.ZL3_COD
	          FROM %Table:ZL3% ZL3
	         WHERE ZL3.ZL3_FILIAL = Z08.Z08_FILIAL
	           %exp:_cFiltro1%
	           AND ZL3.ZL3_FRETIS = SA2.A2_COD
	           %exp:_cFiltro3%
	           AND ZL3.ZL3_FRETLJ = SA2.A2_LOJA
	           AND ZL3.D_E_L_E_T_ = ' ')
	 ORDER BY SA2.R_E_C_N_O_
EndSql
If (_cAlias)->(!Eof())
	
	//====================================================================================================
	// Configura e Inicia a Impressao.
	//====================================================================================================
	_oPrint := TMSPrinter():New( 'AGLT009J' )
	_oPrint:SetPortrait()
	_oPrint:SetPaperSize(9)
	
	While (_cAlias)->(!Eof())
		
		_nREGSA2	:= (_cAlias)->REGSA2
		_aNotas		:= {}
		_nValNot	:= 0
		_nSaldo		:= 0
		_nAdiant	:= 0
		
		While (_cAlias)->REGSA2 == _nREGSA2
			
			aAdd( _aNotas , { AllTrim( (_cAlias)->Z08_NF ) +'-'+ (_cAlias)->Z08_SERIE , (_cAlias)->Z08_EMISSA , (_cAlias)->Z08_VALOR, (_cAlias)->Z08_TERMO } )
			_nValNot += (_cAlias)->Z08_VALOR
			
			If _nAdiant == 0 .And. (_cAlias)->Z08_VALPAG > 0
				_nAdiant := (_cAlias)->Z08_VALPAG
			EndIf
			
		(_cAlias)->( DBSkip() )
		EndDo
		
		_nSaldo := Round( ( _nValNot - _nAdiant ) / 2 , 2 )
		
		LjMsgRun( "Montando a página, aguarde..." , "Termo de Cessão de Crédito" )
		
		For _nI := 1 To _nCopias
			
			//====================================================================================================
			// Impressão da primeira página do termo
			//====================================================================================================
			_oPrint:Startpage()
			
			If File('lgrl01.bmp')
				_oPrint:SayBitmap( 060 , 950 , 'lgrl02.bmp' , 660 , 300 )
			EndIf
			
			DBSelectArea('SA2')
			SA2->( DBGoTo( _nREGSA2 ) )
			
			_nLinha := 450
			_oPrint:Line( _nLinha , 350 , _nLinha , 2200 )
			_nLinha += 030

			_oPrint:Say( _nLinha , 550 , 'TERMO DE CESSÃO DE CRÉDITO, DIREITOS E OBRIGAÇÕES' , _oFont14b )
						
			_nLinha += 150

			_oPrint:Say( _nLinha , 350 , 'TERMO nº: '+ _aNotas[01][04] +'/2014' , _oFont14b )
			_nLinha += 150
			
			_oPrint:Say( _nLinha , 350 , 'IDENTIFICAÇÃO DAS PARTES' , _oFont14b )
			_nLinha += 100
			
			_cTxtAux := 'CEDENTE: '+ SA2->A2_NOME +', brasileiro, produtor rural, residente e domiciliado à '+ SA2->A2_END +', '
			
			If !Empty(SA2->A2_NR_END)
			_cTxtAux += SA2->A2_NR_END +', '
			EndIf
			
			_cTxtAux += 'Bairro: '+ SA2->A2_BAIRRO +', '
			_cTxtAux += 'Município de '+ SA2->A2_MUN +', no Estado do Rio Grande do Sul, devidamente inscrito no CPF sob o nº '+ AllTrim( SA2->A2_CGC ) +'.''
			
			ImpTexto( _cTxtAux , @_nLinha , @_oPrint )
			
			_nLinha += 030
			
			_cTxtAux := 'CESSIONÁRIA: GOIASMINAS INDÚSTRIA DE LATICÍNIOS LTDA, pessoa jurídica de direito privado, devidamente inscrita no CNPJ sob n.º 01.257.995/0001-33, sediada na Rod. GO 139, Km 01, s/n, setor industrial, na cidade e comarca de Corumbaíba – GO, neste ato representada, na forma do seu contrato social, pelo seu representante legal.'
			
			ImpTexto( _cTxtAux , @_nLinha , @_oPrint )
			
			_nLinha += 030
			
			_cTxtAux := 'As partes acima identificadas têm, entre si, justo e acertado o presente Termo de Cessão de Crédito, Direitos e Obrigações, que se regerá pelas cláusulas seguintes e pelas condições de preço, forma e termo de pagamento descritas no presente.'
			
			ImpTexto( _cTxtAux , @_nLinha , @_oPrint )
			
			_nLinha += 100
			_oPrint:Say( _nLinha , 350 , 'DO OBJETO DO CONTRATO' , _oFont14b )
			_nLinha += 100
			
			_cTxtAux := 'Cláusula 1ª. O presente termo tem como OBJETO o crédito e a obrigação decorrente deste, oriundo da transação comercial havida com a empresa Devedora Laticínios Bom Gosto S/A, devidamente cadastrada no CNPJ sob n.º 94.679.479/0001-88, estabelecida na Av. 7 de setembro, n.º 3384, Bairro São Paulo, na cidade de Tapejara - RS, bem como, a filial desta, cadastrada no CNPJ sob n.º 94.679.479/0007-76, sediada na Rod. RS 344, Km 62, s/n, Bairro Moura, na cidade de Giruá – RS, e por último a empresa Líder Alimentos do Brasil S/A, devidamente cadastrada no CNPJ sob n.º 80.823.396/0040-12, estabelecida na Rua Industrial 10, Distrito Industrial, na cidade de Crissiumal – RS, junto ao CEDENTE, referente a venda e compra de leite "in natura" para industrialização realizada, devendo para tanto, ser abatido crédito já quitado e mencionado na cláusula 2º, nos termos abaixo descritos:'
			
			ImpTexto( _cTxtAux , @_nLinha , @_oPrint )
			
			_nLinha += 070
			
			_oPrint:Line( _nLinha		, 0350 , _nLinha		, 2000 )
			_oPrint:Line( _nLinha+070	, 0350 , _nLinha+070	, 2000 )
			_oPrint:Line( _nLinha		, 0350 , _nLinha+070	, 0350 )
			_oPrint:Line( _nLinha		, 1000 , _nLinha+070	, 1000 )
			_oPrint:Line( _nLinha		, 1500 , _nLinha+070	, 1500 )
			_oPrint:Line( _nLinha		, 2000 , _nLinha+070	, 2000 )
			
			_nLinha += 010
			
			_oPrint:Say( _nLinha , 0370 , 'NOTA FISCAL'	, _oFont14b )
			_oPrint:Say( _nLinha , 1020 , 'DATA'		, _oFont14b )
			_oPrint:Say( _nLinha , 1520 , 'VALOR'		, _oFont14b )
			
			_nLinha	+= 060
			_nCntNF	:= 0
			
			For _nX := 1 To Len( _aNotas )
				
				_nCntNF++
				
				If _nCntNF > 10 .And. _nCntNF < 100
					
					_nLinha := 3200
					_oPrint:Line( _nLinha , 350 , _nLinha , 2200 )
					_nLinha += 010
					
					_oPrint:Say( _nLinha , 0550 , 'Av. Antônio Marinho Albuquerque, 1138, Bairro Valinhos'	, _oFont10 ) ; _nLinha += 035
					_oPrint:Say( _nLinha , 0550 , '                    Passo Fundo - RS'					, _oFont10 ) ; _nLinha += 035
					_oPrint:Say( _nLinha , 0550 , '                  Fone:(54) 3317-8900'					, _oFont10 )
					_oPrint:Say( _nLinha , 2200 , '01/04'													, _oFont10 ,,,, 1 )
					
					_oPrint:Endpage()
					_oPrint:Startpage()
					
					If File('lgrl01.bmp')
						_oPrint:SayBitmap( 060 , 950 , 'lgrl02.bmp' , 660 , 300 )
					EndIf
					
					_nLinha := 450
					_oPrint:Line( _nLinha , 0350 , _nLinha , 2200 )
					_nLinha += 050
					_oPrint:Line( _nLinha , 0350 , _nLinha , 2000 )
					
					_nCntNF := 101
					
				EndIf
				
				If _nCntNF > 138
					
					_nLinha := 3200
					_oPrint:Line( _nLinha , 350 , _nLinha , 2200 )
					_nLinha += 010
					
					_oPrint:Say( _nLinha , 0550 , 'Av. Antônio Marinho Albuquerque, 1138, Bairro Valinhos'	, _oFont10 ) ; _nLinha += 035
					_oPrint:Say( _nLinha , 0550 , '                    Passo Fundo - RS'					, _oFont10 ) ; _nLinha += 035
					_oPrint:Say( _nLinha , 0550 , '                  Fone:(54) 3317-8900'					, _oFont10 )
					_oPrint:Say( _nLinha , 2200 , '01/04'													, _oFont10 ,,,, 1 )
					
					_oPrint:Endpage()
					_oPrint:Startpage()
					
					If File('lgrl01.bmp')
						_oPrint:SayBitmap( 060 , 950 , 'lgrl02.bmp' , 660 , 300 )
					EndIf
					
					_nLinha := 450
					_oPrint:Line( _nLinha , 0350 , _nLinha , 2200 )
					_nLinha += 050
					_oPrint:Line( _nLinha , 0350 , _nLinha , 2000 )
					
					_nCntNF := 101
					
				EndIf
				
				_oPrint:Line( _nLinha+070	, 0350 , _nLinha+070	, 2000 )
				_oPrint:Line( _nLinha		, 0350 , _nLinha+070	, 0350 )
				_oPrint:Line( _nLinha		, 1000 , _nLinha+070	, 1000 )
				_oPrint:Line( _nLinha		, 1500 , _nLinha+070	, 1500 )
				_oPrint:Line( _nLinha		, 2000 , _nLinha+070	, 2000 )
				
				_nLinha += 010
				
				_oPrint:Say( _nLinha , 0370 , _aNotas[_nX][01]										, _oFont14 )
				_oPrint:Say( _nLinha , 1020 , DToC( SToD( _aNotas[_nX][02] ) )						, _oFont14 )
				_oPrint:Say( _nLinha , 1980 , Transform( _aNotas[_nX][03] , '@E 999,999,999.99' )	, _oFont14 ,,,, 1 )
				
				_nLinha += 060
				
			Next _nX
			
			If _nAdiant > 0
				
				_oPrint:Line( _nLinha+070	, 0350 , _nLinha+070	, 2000 )
				_oPrint:Line( _nLinha		, 0350 , _nLinha+070	, 0350 )
				_oPrint:Line( _nLinha		, 1000 , _nLinha+070	, 1000 )
				_oPrint:Line( _nLinha		, 1500 , _nLinha+070	, 1500 )
				_oPrint:Line( _nLinha		, 2000 , _nLinha+070	, 2000 )
				
				_nLinha += 010
				
				_oPrint:Say( _nLinha , 0370 , 'Adiantamento'										, _oFont14 )
				_oPrint:Say( _nLinha , 1020 , DToC( SToD( '20141205' ) )							, _oFont14 )
				_oPrint:Say( _nLinha , 1980 , Transform( _nAdiant , '@E 999,999,999.99' )			, _oFont14 ,,,, 1 )
				
				_nLinha += 060
				
			EndIf
			
			_nLinha += 020
			
			_oPrint:Line( _nLinha		, 0350 , _nLinha		, 2000 )
			_oPrint:Line( _nLinha+070	, 0350 , _nLinha+070	, 2000 )
			_oPrint:Line( _nLinha		, 0350 , _nLinha+070	, 0350 )
			_oPrint:Line( _nLinha		, 1000 , _nLinha+070	, 1000 )
			_oPrint:Line( _nLinha		, 1500 , _nLinha+070	, 1500 )
			_oPrint:Line( _nLinha		, 2000 , _nLinha+070	, 2000 )
			
			_nLinha += 010
			
			_oPrint:Say( _nLinha , 0370 , 'Saldo'													, _oFont14b )
			_oPrint:Say( _nLinha , 1020 , ''														, _oFont14b )
			_oPrint:Say( _nLinha , 1980 , Transform( _nValNot - _nAdiant , '@E 999,999,999.99' )	, _oFont14b ,,,, 1 )			
			
			_nLinha := 3200
			_oPrint:Line( _nLinha , 350 , _nLinha , 2200 )
			_nLinha += 010
			
			_oPrint:Say( _nLinha , 0550 , 'Av. Antônio Marinho Albuquerque, 1138, Bairro Valinhos'	, _oFont10 ) ; _nLinha += 035
			_oPrint:Say( _nLinha , 0550 , '                    Passo Fundo - RS'					, _oFont10 ) ; _nLinha += 035
			_oPrint:Say( _nLinha , 0550 , '                  Fone:(54) 3317-8900'					, _oFont10 )
			_oPrint:Say( _nLinha , 2200 , '01/04'													, _oFont10 ,,,, 1 )
			
			_oPrint:Endpage()
		
		Next _nI
		
		For _nI := 1 To _nCopias
			
			//====================================================================================================
			// Impressão da segunda página do termo
			//====================================================================================================
			_oPrint:Startpage()
			
			If File('lgrl01.bmp')
				_oPrint:SayBitmap( 060 , 950 , 'lgrl02.bmp' , 660 , 300 )
			EndIf
			
			_nLinha := 450
			_oPrint:Line( _nLinha , 350 , _nLinha , 2200 )
			_nLinha += 050
			
			_oPrint:Say( _nLinha , 350 , 'DO CRÉDITO' , _oFont14b )
			_nLinha += 100

			_cTxtAux := 'Cláusula 2ª. Primeiramente, importante destacar que, em relação ao valor das notas fiscais mencionadas, o CEDENTE teve quitada parte da referida importância, através de pagamento realizado pelo grupo LBR – Lácteos Brasil, detentora da empresa DEVEDORA acima descrita pela cláusula 1º, sendo referida importância no importe de R$ ' + AllTrim(Transform(_nAdiant,"@E 999,999,999,999.99")) + ' (' + AllTrim(Extenso(_nAdiant,.F.)) + '), incluindo a CEDENTE no presente termo a quitação integral referente ao mencionado adiantamento citado nesta cláusula.'			
			ImpTexto( _cTxtAux , @_nLinha , @_oPrint )
			
			_nLinha += 030
			
			_cTxtAux := 'Cláusula 2.1ª. Assim, em conformidade com o acordo firmado previamente pelas partes, a CESSIONÁRIA, para aquisição da integralidade dos créditos descritos e originários das notas fiscais acima, descontado o adiantamento citado pela cláusula 2ª, pagará ao CEDENTE 50% (cinquenta por cento) do saldo líquido descrito na cláusula 1ª, restando assim o valor líquido a ser quitado no importe de R$ ' + AllTrim(Transform(_nSaldo,"@E 999,999,999,999.99")) + ' (' + AllTrim(Extenso(_nSaldo,.F.)) + '), em 5 (cinco) parcelas iguais, mensais e consecutivas, nas datas e valores abaixo descritas, a ser pago na conta corrente de titularidade do CEDENTE, conforme cadastro pré-existente junto a empresa DEVEDORA, conforme segue:'			
			ImpTexto( _cTxtAux , @_nLinha , @_oPrint )
			
			_nLinha += 030
			
			_nLinha += 070
			
			_oPrint:Line( _nLinha		, 0350 , _nLinha		, 1500 )
			_oPrint:Line( _nLinha+070	, 0350 , _nLinha+070	, 1500 )
			_oPrint:Line( _nLinha		, 0350 , _nLinha+070	, 0350 )
			_oPrint:Line( _nLinha		, 1000 , _nLinha+070	, 1000 )
			_oPrint:Line( _nLinha		, 1500 , _nLinha+070	, 1500 )
			
			_nLinha += 010
			
			_oPrint:Say( _nLinha , 0370 , 'Vencimento'	, _oFont14b )
			_oPrint:Say( _nLinha , 1020 , 'Valor'		, _oFont14b )
			
			_nLinha += 060
			
			_nValPar := Round( _nSaldo / 5 , 2 )
			
			For _nX := 1 To 5
			
				_oPrint:Line( _nLinha+070	, 0350 , _nLinha+070	, 1500 )
				_oPrint:Line( _nLinha		, 0350 , _nLinha+070	, 0350 )
				_oPrint:Line( _nLinha		, 1000 , _nLinha+070	, 1000 )
				_oPrint:Line( _nLinha		, 1500 , _nLinha+070	, 1500 )
				
				_nLinha += 010
				
				If _nX == 5
					
					If ( _nValPar * 5 ) <> _nSaldo
						
						_nValPar := _nSaldo - ( _nValPar * 4 )
						
					EndIf
					
				EndIf
				
				_oPrint:Say( _nLinha , 0370 , '10/'+ StrZero(_nX,2) +'/2015'				, _oFont14 )
				_oPrint:Say( _nLinha , 1020 , Transform( _nValPar , '@E 999,999,999.99' )	, _oFont14 )
				
				_nLinha += 060
			
			Next _nX
			
			_nLinha += 050
			
			_cTxtAux := 'Cláusula 3ª. A transferência do crédito envolve tanto o principal, quanto a eventuais acessórios, multas e juros moratórios, sendo que o CEDENTE dá neste ato integral, total e geral quitação do valor devido pelo DEVEDOR, correspondente às notas fiscais citadas, e adquirido pela CESSIONÁRIA, para nada mais cobrar a este título e a qualquer tempo, seja administrativo, judicial, extrajudicialmente ou qualquer outra forma em direito admitidos, estando assim quitado de pleno direito os títulos descritos, após devidamente quitados os valores descritos acima e na forma estabelecida.'
			
			ImpTexto( _cTxtAux , @_nLinha , @_oPrint )
			
			_nLinha += 030
			
			_cTxtAux := 'Cláusula 3.1ª. Fica assegurado ao CEDENTE que em caso de não quitação das parcelas acima descrita, o presente termo servirá de título executivo, sendo mantida a presente cessão em sua integralidade de valores e obrigações assumidos pelas partes.'
			
			ImpTexto( _cTxtAux , @_nLinha , @_oPrint )
			
			_nLinha += 030
			
			_nLinha := 3200
			_oPrint:Line( _nLinha , 350 , _nLinha , 2200 )
			_nLinha += 010
			
			_oPrint:Say( _nLinha , 0550 , 'Av. Antônio Marinho Albuquerque, 1138, Bairro Valinhos'	, _oFont10 ) ; _nLinha += 035
			_oPrint:Say( _nLinha , 0550 , '                    Passo Fundo - RS'					, _oFont10 ) ; _nLinha += 035
			_oPrint:Say( _nLinha , 0550 , '                  Fone:(54) 3317-8900'					, _oFont10 )
			_oPrint:Say( _nLinha , 2200 , '02/04'													, _oFont10 ,,,, 1 )
			
			_oPrint:Endpage()
		
		Next _nI
		
		For _nI := 1 To _nCopias
			
			//====================================================================================================
			// Impressão da Terceira página do Termo
			//====================================================================================================
			_oPrint:Startpage()
			
			If File('lgrl01.bmp')
				_oPrint:SayBitmap( 060 , 950 , 'lgrl02.bmp' , 660 , 300 )
			EndIf
			
			_nLinha := 450
			_oPrint:Line( _nLinha , 350 , _nLinha , 2200 )
			_nLinha += 050
			
			_cTxtAux := 'Cláusula 3.2ª. Resta acordado ainda que para a validade e obrigatoriedade do presente pagamento descrito alhures por parte da CESSIONÁRIA, o ora CEDENTE se compromete a fornecer regularmente o leite in natura a CESSIONÁRIO, por todo o período de vigência deste termo, sendo no mínimo até o mês de maio de 2015, incluindo este.'
			
			ImpTexto( _cTxtAux , @_nLinha , @_oPrint )
			
			_nLinha += 030
			
			_cTxtAux := 'Cláusula 3.2.1ª. Fica acordado ainda que, durante a integralidade de vigência do presente termo, ou seja, até a quitação integral dos valores aqui acordados, caso seja interrompido o fornecimento de leite in natura pelo CEDENTE, o pagamento ora acordado e estipulado neste termo de cessão, será automaticamente suspenso de pleno direito e em sua equivalente proporção, sendo os vencimentos aqui firmados, automaticamente prorrogados até a efetiva retomada de fornecimento de leite in natura pelo CEDENTE a CESSIONÁRIA. Ainda, o fornecimento de leite mencionado nesta cláusula não deverá ter seu volume inferior ao habitualmente entregue, utilizando-se como base a quantidade aproximada dos meses de outubro e novembro de 2014 fornecidos pelo CEDENTE.'
			
			ImpTexto( _cTxtAux , @_nLinha , @_oPrint )
			
			_nLinha += 100
			_oPrint:Say( _nLinha , 350 , 'DA CESSÃO' , _oFont14b )
			_nLinha += 100
			
			_cTxtAux := 'Cláusula 4ª. A CEDENTE neste ato declara expressamente que com o recebimento da importância descrita, a ser quitada pela CESSIONÁRIA na forma acima pactuada, dá a mais ampla, total, plena, irrevogável e irretratável quitação, para nada mais reclamar, a qualquer tempo, quanto a presente cessão, respondendo seus herdeiros e/ou sucessores, restando obrigados a cumprir todas as cláusulas e condições constantes no presente.'
			
			ImpTexto( _cTxtAux , @_nLinha , @_oPrint )
			
			_nLinha += 030
			
			_cTxtAux := 'Cláusula 5ª.  Este documento representa o desejo e o entendimento total entre as partes quanto ao seu objeto, declarando possuir integral conhecimento de seu conteúdo, e sobrepõe-se, em todos os aspectos, a quaisquer contratos ou entendimentos, sejam verbais ou escritos, relativos a essas matérias e obrigará às partes, bem como a seus respectivos herdeiros, sucessores e cessionários, a qualquer título.'
			
			ImpTexto( _cTxtAux , @_nLinha , @_oPrint )
			
			_nLinha += 030
			
			_cTxtAux := 'Cláusula 6ª.  Fica preservado a qualquer tempo o dereito desta CESSIONÁRIA e formalizar a cessão dos créditos ora adquiridos, a terceiros de sua livre escolha.'
			
			ImpTexto( _cTxtAux , @_nLinha , @_oPrint )
			
			_nLinha += 030
			
			_cTxtAux := 'Cláusula 7ª.  As partes declaram terem recebido o presente instrumento com antecedência necessária para correta e atenta leitura e compreensão de todos os seus termos, direitos e obrigações, bem como foram prestados mutuamente todos os esclarecimentos necessários e obrigatórios, e ainda que entendem, reconhecem e concordam com os termos e condições aqui ajustadas, ficando assim caracterizada a probidade e boa-fé de todas as partes.'
			
			ImpTexto( _cTxtAux , @_nLinha , @_oPrint )
			
			_nLinha += 030
			
			_nLinha := 3200
			_oPrint:Line( _nLinha , 350 , _nLinha , 2200 )
			_nLinha += 010
			
			_oPrint:Say( _nLinha , 0550 , 'Av. Antônio Marinho Albuquerque, 1138, Bairro Valinhos'	, _oFont10 ) ; _nLinha += 035
			_oPrint:Say( _nLinha , 0550 , '                    Passo Fundo - RS'					, _oFont10 ) ; _nLinha += 035
			_oPrint:Say( _nLinha , 0550 , '                  Fone:(54) 3317-8900'					, _oFont10 )
			_oPrint:Say( _nLinha , 2200 , '03/04'													, _oFont10 ,,,, 1 )
			
			_oPrint:Endpage()
		
		Next _nI
		
		For _nI := 1 To _nCopias
		
			//====================================================================================================
			// Impressão da quarta página do termo
			//====================================================================================================
			_oPrint:Startpage()
			
			If File('lgrl01.bmp')
				_oPrint:SayBitmap( 060 , 950 , 'lgrl02.bmp' , 660 , 300 )
			EndIf
			
			_nLinha := 450
			_oPrint:Line( _nLinha , 350 , _nLinha , 2200 )
			_nLinha += 050
			
			_nLinha += 100
			_oPrint:Say( _nLinha , 350 , 'CONDIÇÕES GERAIS' , _oFont14b )
			_nLinha += 100
			
			_cTxtAux := 'Cláusula 8ª. O presente contrato passa a vigorar a partir da assinatura do mesmo.'
			
			ImpTexto( _cTxtAux , @_nLinha , @_oPrint )
			
			_nLinha += 030
			
			_cTxtAux := 'Cláusula 9ª. Seguem anexas as notas fiscais emitidas pela compra e venda realizada pelo DEVEDOR e CEDENTE.'
			
			ImpTexto( _cTxtAux , @_nLinha , @_oPrint )
			
			_nLinha += 100
			_oPrint:Say( _nLinha , 350 , 'DO FORO' , _oFont14b )
			_nLinha += 100
			
			_cTxtAux := 'Cláusula 10ª. Para dirimir quaisquer controvérsias oriundas do presente TERMO, as partes elegem o foro da comarca de Passo Fundo - RS.'
			
			ImpTexto( _cTxtAux , @_nLinha , @_oPrint )
			
			_nLinha += 030
			
			_cTxtAux := 'Para todos os fins e efeitos de direito, as partes declaram aceitar o presente nos expressos termos em que foi lavrado, obrigando-se a si, seus herdeiros e sucessores a bem e fielmente cumpri-lo.'
			
			ImpTexto( _cTxtAux , @_nLinha , @_oPrint )
			
			_nLinha += 030
			
			_cTxtAux := 'Por estarem assim justos e contratados, firmam o presente instrumento, em duas vias de igual teor, juntamente com 2 (duas) testemunhas.'
			
			ImpTexto( _cTxtAux , @_nLinha , @_oPrint )
			
			_nLinha += 200
			
			_oPrint:Say( _nLinha , 350 , 'Passo Fundo – RS, '+ StrZero( Day( dDatabase ) , 2 ) +' de '+ MesExtenso( Month( dDatabase ) ) +' de '+ StrZero( Year( dDatabase ) , 4 ) , _oFont14 )
			
			_nLinha += 400
			
			_oPrint:Line( _nLinha , 0350 , _nLinha , 1075 )
			_oPrint:Line( _nLinha , 1475 , _nLinha , 2200 )
			
			_nLinha += 010
			
			_oPrint:Say( _nLinha , 0350 , AllTrim( SA2->A2_NOME )			, _oFont12 )
			_oPrint:Say( _nLinha , 1475 , 'GOIASMINAS IND. DE LAT. LTDA.'	, _oFont12 )
			
			_nLinha += 040
			_oPrint:Say( _nLinha , 0350 , 'CEDENTE'			, _oFont14 )
			_oPrint:Say( _nLinha , 1475 , 'CESSIONÁRIA'		, _oFont14 )
			
			_nLinha += 300
			_oPrint:Say( _nLinha , 0350 , 'Testemunhas:'	, _oFont14 )
			
			_nLinha += 400
			
			_oPrint:Line( _nLinha , 0350 , _nLinha , 1075 )
			_oPrint:Line( _nLinha , 1475 , _nLinha , 2200 )
			
			_nLinha += 010
			
			_oPrint:Say( _nLinha , 0350 , 'Nome:'	, _oFont12 )
			_oPrint:Say( _nLinha , 1475 , 'Nome:'	, _oFont12 )
			
			_nLinha += 040
			_oPrint:Say( _nLinha , 0350 , 'CPF:'	, _oFont12 )
			_oPrint:Say( _nLinha , 1475 , 'CPF:'	, _oFont12 )
			
			_nLinha := 3200
			_oPrint:Line( _nLinha , 350 , _nLinha , 2200 )
			_nLinha += 010
			
			_oPrint:Say( _nLinha , 0550 , 'Av. Antônio Marinho Albuquerque, 1138, Bairro Valinhos'	, _oFont10 ) ; _nLinha += 035
			_oPrint:Say( _nLinha , 0550 , '                    Passo Fundo - RS'					, _oFont10 ) ; _nLinha += 035
			_oPrint:Say( _nLinha , 0550 , '                  Fone:(54) 3317-8900'					, _oFont10 )
			_oPrint:Say( _nLinha , 2200 , '04/04'													, _oFont10 ,,,, 1 )

			_oPrint:EndPage()
			
		Next _nI
		
	EndDo
	
	(_cAlias)->( DBCloseArea() )
	_oPrint:Preview()
	
EndIf

Return

/*
===============================================================================================================================
Programa----------: ImpTexto
Autor-------------: Fabiano Dias
Data da Criacao---: 06/09/2012
Descrição---------: Função para imprimir o texto no documento com a formatação Justificada
Parametros--------: _cTexto , _nLinha , _oPrint
Retorno-----------: Nehum
===============================================================================================================================
*/
Static Function ImpTexto( _cTexto , _nLinha , _oPrint )

Local _aTexto   	:= Separa( _cTexto , " " , .F. )	//Quebro o texto em palavras
Local _nNumCarac	:= 062								//Numero maximo de caracteres por linha
Local _cLinImpr 	:= ""								//Texto de impressao inicial do array
Local _nPosInic 	:= 1								//Posicao inicial do array que comecou uma linha
Local _nNumEspac	:= 0								//Numero de espacos vazios necessario para justificar o texto
Local _nNumPalav	:= 0
Local _lEntrou  	:= .F.
Local _nVlrDiv  	:= 0
Local _nEspacame	:= 0
Local _nEspcAdic	:= 0
Local _nVlrEspac	:= 0
Local _nX, _nI		:= 0
Local _oFont12		:= TFont():New( "Courier New" ,, 14 ,, .F. ,,,, .T. , .F. )

For _nX := 1 to Len(_aTexto)

	_lEntrou  := .F.
	_nNumPalav++
	
	If Empty(_cLinImpr)
		_cLinImpr := _aTexto[_nX]
 	Else
	  	If Len(_cLinImpr + " " + _aTexto[_nX]) <= _nNumCarac
			_cLinImpr += " " + _aTexto[_nX]
		ElseIf Len(_cLinImpr) < _nNumCarac
		
			_nNumEspac	:= _nNumCarac - Len(_cLinImpr) //Numero de espacos em branco a complementar
			_cLinImpr	:= ""
			
			//====================================================================================================
			// Se For possivel distribuir os espacos em branco entre os numero de palavras
			//====================================================================================================
			If _nNumEspac < _nNumPalav - 2
			
				For _nI := _nPosInic To _nX-1
					If Len(_cLinImpr) == 0
						_cLinImpr := _aTexto[_nI]
					Else
					    If _nNumEspac > 0
							_cLinImpr += "  " + _aTexto[_nI]
							_nNumEspac-= 1
						Else
							_cLinImpr += " " +_aTexto[_nI]
						EndIf
					EndIf
				Next _nI
				
			//====================================================================================================
			// Caso o numero de espacos em branco a complementar a linha atual seja maior que o numero de palavras
			// da linha atual.
			//====================================================================================================
			Else
			
				_nEspcAdic	:= 0
				_nNumPalav	:= _nNumPalav - 2				//Numero de palavras a serem consideradas para insercao dos espacos em branco
				_nVlrDiv	:= Mod(_nNumEspac,_nNumPalav)	//Divisao para constatar se o numero de espacos em branco dividido pelo numero de palavras eh multiplo
				_nEspacame	:= Int(_nNumEspac / _nNumPalav)
				
				//====================================================================================================
			    //Contabiliza o numero de caracteres restantes entre o multiplo da divisao para ser valores adicionais
			    //====================================================================================================
			    If _nVlrDiv != 0 
			         _nEspcAdic := _nNumEspac - ( _nNumPalav * _nEspacame )
			    EndIf
    			
				For _nI := _nPosInic To _nX-1
					If Len(_cLinImpr) == 0
						_cLinImpr := _aTexto[_nI]
					Else
						If _nEspcAdic > 0
							_nEspcAdic--
							_nVlrEspac := _nEspacame + 2
						Else
							_nVlrEspac := _nEspacame + 1
						EndIf
						_cLinImpr += Space( _nVlrEspac ) + _aTexto[_nI]
					EndIf
				Next _nI
			EndIf    	                 	                	                	                
                         							                   
            _nPosInic:= _nX
            
            _nX			:= _nX-1 //Para que a palavra que nao foi impressa neste Loop seja impressa na proxima execucao
            _lEntrou	:= .T.
            
	  	EndIf
	  	
	EndIf

	//====================================================================================================
	// Imprime de acordo com o numero maximo de caracteres montados a linha formatada anteriormente.
	//====================================================================================================
	If Len(_cLinImpr) == _nNumCarac
	
		_oPrint:Say( _nLinha , 350 , _cLinImpr , _oFont12 )
		_nLinha += 040
		
		_cLinImpr  := ""
		_nNumPalav := 0
		
		If !_lEntrou
			_nPosInic := _nX + 1
		EndIf
	
	EndIf

Next _nX

If Len(_cLinImpr) < _nNumCarac

	_oPrint:Say( _nLinha , 350 , _cLinImpr , _oFont12 )
	_nLinha += 50

EndIf

Return

/*
===============================================================================================================================
Programa----------: AGLT009G
Autor-------------: Alexandre Villar
Data da Criacao---: 19/12/2014
Descrição---------: Rotina para geração de títulos no módulo Financeiro de acordo com os lançamentos selecionados
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT009G()

Local _aDados	:= {}
Local _cAlias	:= GetNextAlias()
Local _cPerg	:= 'AGLT009F'

If !Pergunte( _cPerg )
	Aviso( "AGLT00906" , 'Operação cancelada pelo usuário!' , {'Fechar'} )
	Return
EndIf

BeginSql Alias _cAlias
	SELECT Z08.Z08_TERMO TERMO, Z08.Z08_CODFOR FORN, Z08.Z08_LOJFOR LOJA, SA2.A2_NOME NOME, Z08.Z08_EMISSA EMI_NF, 
			Z08.Z08_VALOR VAL_NF, Z08.Z08_VALPAG VAL_AD, Z08.R_E_C_N_O_ REGZ08
	FROM %Table:Z08% Z08, %Table:SA2% SA2
	WHERE Z08.D_E_L_E_T_ =' '
	AND SA2..D_E_L_E_T_ =' '
	AND Z08.Z08_FILIAL = %xFilial:Z08%
	AND SA2.A2_COD = Z08.Z08_CODFOR 
	AND SA2.A2_LOJA = Z08.Z08_LOJFOR
	AND Z08.Z08_CODFOR BETWEEN %exp:MV_PAR01% AND %exp:MV_PAR03%
	AND Z08.Z08_LOJFOR BETWEEN %exp:MV_PAR02% AND %exp:MV_PAR04%
	AND Z08.Z08_EMISSA BETWEEN %exp:MV_PAR05% AND %exp:MV_PAR06%
	AND NOT EXISTS ( 
		SELECT SE2.E2_NUM FROM %Table:SE2% SE2 
		WHERE SE2.D_E_L_E_T_ =' '
		AND SE2.E2_FILIAL = Z08.Z08_FILIAL
		AND SE2.E2_PREFIXO = Z08.Z08_PREFIX
		AND SE2.E2_NUM = Z08.Z08_NUM 
		AND SE2.E2_TIPO = Z08.Z08_TIPO)
	ORDER BY SA2.A2_NOME, Z08.Z08_TERMO, Z08.Z08_CODFOR, Z08.Z08_LOJFOR
EndSql

While (_cAlias)->( !Eof() )
	If !Empty( (_cAlias)->REGZ08 )
		aAdd( _aDados , { .F. , (_cAlias)->FORN , (_cAlias)->LOJA , (_cAlias)->EMI_NF , (_cAlias)->VAL_NF , (_cAlias)->VAL_AD , (_cAlias)->REGZ08 , (_cAlias)->TERMO } )
	EndIf
	(_cAlias)->( DBSkip() )
EndDo

(_cAlias)->( DBCloseArea() )

If Empty( _aDados )
	Aviso( "AGLT00907" , 'Não foram encontrados registros com a parametrização informada! Verifique os parâmetros e tente novamente.' , {'Fechar'} )
Else
	AGLT009DFN( _aDados )
EndIf

Return

/*
===============================================================================================================================
Programa----------: AGLT009FIN
Autor-------------: Alexandre Villar
Data da Criacao---: 19/12/2014
Descrição---------: Rotina que gera os títulos de acordo com os parâmetros informados e os registros selecionados
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT009FIN( _aResumo , _aDados )

Local _aTitSE2		:= {}
Local _aLogPrc		:= {}
Local _cErro		:= ''
Local _nX, _nI		:= 0
Local _cPerg		:= 'AGLT009G'
Local _dDtVenc		:= SToD('')
Local _dDtVenR		:= SToD('')
Local _cCodUsr		:= RetCodUsr()

Private lMsErroAuto	:= .F.

If !Pergunte( _cPerg )
	Aviso( "AGLT00908" , 'Operação cancelada pelo usuário!' , {'Fechar'} )
	Return
EndIf

If MessageBox(	'Confirma a configuração do Financeiro para a geração dos títulos ?'+ CRLF +;
					'Prefixo: '+	MV_PAR01											+ CRLF +;
					'Tipo: '+		MV_PAR02											+ CRLF +;
					'Natureza: '+	MV_PAR03												   ,;
					"AGLT00909" , 4 ) <> 6
	
	If !Pergunte( _cPerg )
		Aviso( "AGLT00910" , 'Operação cancelada pelo usuário!' , {'Fechar'} )
		Return
	EndIf
	
EndIf

ProcRegua( Len(_aResumo) )

For _nI := 1 To Len(_aResumo)
	
	IncProc( 'Processando ['+ StrZero( _nI , 9 ) +'] de ['+ StrZero( Len(_aResumo) , 9 ) +']...' )
	
	If !_aResumo[_nI][01]
		Loop
	EndIf
	
	_nValTit	:= Round( _aResumo[_nI][07] / 5 , 2 )
	_lErroAut	:= .F.
	
	BEGIN TRANSACTION
	
	For _nX := 1 To _aResumo[_nI][08]
		
		If _nX == _aResumo[_nI][08]
			_nValTit += IIf( ( _aResumo[_nI][07] - Round( _nValTit * _nX , 2 ) ) > 0 , ( _aResumo[_nI][07] - Round( _nValTit * _nX , 2 ) ) , 0 )
		EndIf
		
		_dDtVenc	:= &( 'MV_PAR'+ StrZero( _nX + 8 , 2 ) )
		_dDtVenR	:= DataValida(_dDtVenc)
		
		lMsErroAuto := .F.
		
		_aTitSE2	:= {	{ "E2_PREFIXO"    , MV_PAR01					, Nil } ,; //01
							{ "E2_NUM"        , _aResumo[_nI][09]			, Nil } ,; //02
							{ "E2_PARCELA"    , StrZero(_nX,2)				, Nil } ,; //03
							{ "E2_TIPO"       , 'NF'						, Nil } ,; //04
							{ "E2_NATUREZ"    , MV_PAR03					, Nil } ,; //05
							{ "E2_FORNECE"    , _aResumo[_nI][02]			, Nil } ,; //06
							{ "E2_LOJA"       , _aResumo[_nI][03]			, Nil } ,; //07
							{ "E2_EMISSAO"    , dDataBase					, Nil } ,; //08
							{ "E2_VENCTO"     , _dDtVenc					, Nil } ,; //09
							{ "E2_VENCREA"    , _dDtVenR					, Nil } ,; //10
							{ "E2_VALOR"      , _nValTit					, Nil } ,; //11
							{ "E2_HIST"       , 'Título Avulso Produtor'	, Nil } ,; //12
							{ "E2_ORIGEM"     , "AGLT009"					, Nil }  } //13
							
		
		_nModAux	:= nModulo
		_cModAux	:= cModulo
		
		nModulo		:= 6
		cModulo 	:= "FIN"
		
		MsExecAuto( { |x,y,z| FINA050(x,y,z) } , _aTitSE2 ,, 3 )
		
		If lMsErroAuto
			_cErro := AllTrim( MostraErro('C:') )
			aAdd(	_aLogPrc , {	_aTitSE2[01][02]																			,; //Prefixo
									_aTitSE2[02][02]																			,; //Número
									_aTitSE2[03][02]																			,; //Parcela
									_aTitSE2[04][02]																			,; //Tipo
									_aTitSE2[05][02]																			,; //Natureza
									_aTitSE2[06][02]																			,; //Fornecedor
									_aTitSE2[07][02]																			,; //Loja
									AllTrim( Posicione('SA2',1,xFilial('SA2')+_aTitSE2[06][02]+_aTitSE2[07][02],'A2_NOME') )	,; //Nome
									_aTitSE2[08][02]																			,; //Emissão
									_aTitSE2[09][02]																			,; //Vencimento
									_aTitSE2[11][02]																			,; //Valor
									_aResumo[_nI][08]																			,; //Parcelas
									_cErro																						}) //Mensagem
			_lErroAut := .T.
		Else
			aAdd(	_aLogPrc , {	_aTitSE2[01][02]																			,; //Prefixo
									_aTitSE2[02][02]																			,; //Número
									_aTitSE2[03][02]																			,; //Parcela
									_aTitSE2[04][02]																			,; //Tipo
									_aTitSE2[05][02]																			,; //Natureza
									_aTitSE2[06][02]																			,; //Fornecedor
									_aTitSE2[07][02]																			,; //Loja
									AllTrim( Posicione('SA2',1,xFilial('SA2')+_aTitSE2[06][02]+_aTitSE2[07][02],'A2_NOME') )	,; //Nome
									_aTitSE2[08][02]																			,; //Emissão
									_aTitSE2[09][02]																			,; //Vencimento
									_aTitSE2[11][02]																			,; //Valor
									_aResumo[_nI][08]																			,; //Parcelas
									'Título gerado com sucesso!'																}) //Mensagem
		EndIf
		
		nModulo := _nModAux
		cModulo := _cModAux
		
	Next _nX
	
	If _lErroAut
		DisarmTransaction()
		Break
	EndIf
	END TRANSACTION
	
	MSUnLockAll()
	
	_nPosIni := aScan( _aDados , {|x| x[02]+x[03] == _aTitSE2[06][02]+_aTitSE2[07][02] } )
	
	If _nPosIni > 0 .And. !_lErroAut
		
		While _nPosIni <= Len(_aDados) .And. _aDados[_nPosIni][02]+_aDados[_nPosIni][03] == _aTitSE2[06][02]+_aTitSE2[07][02]
		
			DBSelectArea('Z08')
			Z08->( DBGoTo( _aDados[_nPosIni][07] ) )
			Z08->( RecLock('Z08',.F.) )
				Z08->Z08_EMIFIN := dDataBase
				Z08->Z08_HORFIN := Time()
				Z08->Z08_USRFIN := _cCodUsr
				Z08->Z08_CONPAG	:= StrZero( _aResumo[_nI][08] , 3 )
				Z08->Z08_PREFIX	:= _aTitSE2[01][02]
				Z08->Z08_NUM	:= _aTitSE2[02][02]
				Z08->Z08_TIPO	:= _aTitSE2[04][02]
				Z08->Z08_NATURE	:= _aTitSE2[05][02]
			Z08->( MSUnLock() )
			
		_nPosIni++
		EndDo
		
	EndIf

Next _nI

If !Empty( _aLogPrc )
	Aviso( "AGLT00911" , 'O processamento foi concluído, verifique o LOG para identificar se todos os registros foram gravados com sucesso!' , {'Exibir'} )
	U_ITListBox(	'Log de Processamento'																												,;
					{'Prefixo','Número','Parcela','Tipo','Natureza','Fornecedor','Loja','Nome','Emissão','Vencimento','Valor','Parcelas','Mensagem'}	,;
					_aLogPrc , .F. , 1 , 'Verifique o processamento dos registros...'																	 )
EndIf

Return

/*
===============================================================================================================================
Programa----------: AGLT009DFN
Autor-------------: Alexandre Villar
Data da Criacao---: 19/12/2014
Descrição---------: Rotina que Monta a tela de processamento da integração
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT009DFN( _aDados )

Local _oOk			:= "[x]"
Local _oNo			:= "[  ]"
Local _nI			:= 0
Local oDlg			:= Nil
Local oLbxPM7		:= Nil
Local oLbxPM8		:= Nil
Local aPosObj   	:= {}
Local aObjects  	:= {}
Local aSize     	:= MsAdvSize()
Local bMontaPM8		:= { || fMontaPM8( @oLbxPM8 , oLbxPM7:aArray[oLbxPM7:nAt][02] + oLbxPM7:aArray[oLbxPM7:nAt][03] , _aDados ) }
Local oBar			:= Nil
Local aBtn 	    	:= Array(03)
Local oBold			:= Nil
Local oScrPanel		:= Nil
Local _lGera		:= .F.
Local _nQtdProd		:= 0
Local _cChvFor		:= ''
Local _nValAd		:= 0
Local _nValNF		:= 0
Local _nQtdNF		:= 0
Local _nValTot		:= 0
Local _aResumo		:= {}

Local aCabLbxPM7	:= {	"[]"				,; // 01
							"Fornecedor"		,; // 02
							"Loja"				,; // 03
							"Nome"				,; // 04
							"Valor NF"			,; // 05
							"Valor Adt."		,; // 06
							"Valor a Pagar"		,; // 07
							"Parcelas"			 } // 08

Local aCabLbxPM8	:= { "Número NF"		,; // 01
                         "Série"			,; // 02
                         "Emissão"			,; // 03
                         "Valor"			 } // 04

Private	cCadastro	:= "Integração com o Financeiro - Geração de Títulos"

aAdd( aObjects, { 100, 025, .T., .F. , .T.	} )
aAdd( aObjects, { 100, 100, .T., .F.		} )
aAdd( aObjects, { 100, 100, .T., .T. 		} )

aInfo   := { aSize[1] , aSize[2] , aSize[3] , aSize[4] , 3 , 2 }
aPosObj := MsObjSize( aInfo , aObjects )

DEFINE FONT oBold NAME "Arial" SIZE 0, -12 BOLD

DEFINE MSDIALOG oDlg TITLE cCadastro From aSize[7],00 to aSize[6],aSize[5] Of oMainWnd Pixel

	aPosObj[01][01] += 12
	aPosObj[02][01] += 10
	aPosObj[02][03] += 10
	aPosObj[03][01] += 10
	aPosObj[03][03] += 10
	//====================================================================================================
	// Parte 01 - Painel do resumo
	//====================================================================================================
	@ aPosObj[01][01],aPosObj[01][02] MSPANEL oScrPanel PROMPT "" SIZE aPosObj[01][03],aPosObj[01][04] OF oDlg LOWERED

	//====================================================================================================
	// Parte 02 - Lista com os fechamentos por fornecedor
	//====================================================================================================
	@aPosObj[02][01],aPosObj[02][02] To aPosObj[02][03],aPosObj[02][04] LABEL "Fornecedores Processados" COLOR CLR_HBLUE OF oDlg PIXEL

	//====================================================================================================
	// ListBox com os fechamentos por fornecedor
	//====================================================================================================
	@aPosObj[02][01]+7,aPosObj[02][02]+4 	Listbox oLbxPM7 Fields;
											HEADER 	""		 		;
											On DbLCLICK ( oLbxPM7:aArray[oLbxPM7:nAt][01] := !oLbxPM7:aArray[oLbxPM7:nAt][01] , _aResumo[oLbxPM7:nAt][01] := oLbxPM7:aArray[oLbxPM7:nAt][01] , oLbxPM7:Refresh() ) ;
											Size aPosObj[02][04]-10,( aPosObj[02][03] - aPosObj[02][01] ) - 10 Of oDlg Pixel
	
	oLbxPM7:AHeaders		:= aClone(aCabLbxPM7)
	oLbxPM7:AColSizes		:= { 10,40,20,250,50,50,50,30 }
	oLbxPM7:bChange			:= {|| Eval(bMontaPM8) }
	oLbxPM7:bHeaderClick	:= {|oObj,nCol| AGLT009MRK( oObj , nCol , @oLbxPM7 , @_aResumo ) }
	
	For _nI := 1 To Len( _aDados ) //aAdd( _aDados , { (_cAlias)->FORN , (_cAlias)->LOJA , (_cAlias)->EMI_NF , (_cAlias)->VAL_NF , (_cAlias)->VAL_AD , (_cAlias)->REGZ08 } )
		
		_cChvFor	:= _aDados[_nI][02] + _aDados[_nI][03]
		_nValAd		:= _aDados[_nI][06]
		_nValNF		:= 0
		_nQtdProd++
		
		While _nI <= Len( _aDados ) .And. _cChvFor == _aDados[_nI][02] + _aDados[_nI][03]
			
			_nValNF += _aDados[_nI][05]
			_nQtdNF++
			
		_nI++
		EndDo
		
		_nI--
		
		aAdd( _aResumo , {	.F.																							,;
							_aDados[_nI][02]																			,;
							_aDados[_nI][03]																			,;
							AllTrim( Posicione('SA2',1,xFilial('SA2')+_aDados[_nI][02]+_aDados[_nI][03],'A2_NOME') )	,;
							_nValNF																						,;
							_nValAd																						,;
							Round( ( _nValNF - _nValAd ) / 2 , 2 )														,;
							5																							,;
							StrZero( Val( _aDados[_nI][08] ) , TamSX3('E2_NUM')[01] )									})
		
		_nValTot += Round( ( _nValNF - _nValAd ) / 2 , 2 )
		
	Next _nI
	
	If !Empty( _aResumo )
		
		oLbxPM7:SetArray( _aResumo )
		
		oLbxPM7:bLine:={||{		IIf(	_aResumo[oLbxPM7:nAt][01] , _oOk , _oNo )			,; // 01
										_aResumo[oLbxPM7:nAt][02]							,; // 02
										_aResumo[oLbxPM7:nAt][03] 							,; // 03
										_aResumo[oLbxPM7:nAt][04] 							,; // 04
							Transform(	_aResumo[oLbxPM7:nAt][05] , '@E 999,999,999.99' )	,; // 05
							Transform(	_aResumo[oLbxPM7:nAt][06] , '@E 999,999,999.99' )	,; // 06
							Transform(	_aResumo[oLbxPM7:nAt][07] , '@E 999,999,999.99' )	,; // 07
										05													,; // 08
										_aResumo[oLbxPM7:nAt][08]							}} // 09
		
		oLbxPM7:Refresh()
	
	EndIf
	
	//====================================================================================================
	// Parte 03 - Detalhes do fechamento do fornecedor
	//====================================================================================================
	@aPosObj[03][01],aPosObj[03][02] To aPosObj[03][03],aPosObj[03][04] LABEL "Notas processadas do fornecedor" COLOR CLR_HBLUE OF oDlg PIXEL
	
	//====================================================================================================
	// ListBox com dados das Notas do fornecedor
	//====================================================================================================
	@aPosObj[03][01]+7,aPosObj[03][02]+4 	Listbox oLbxPM8 Fields;
											HEADER 	""		 		;
											On DbLCLICK ( Nil )		;
											Size aPosObj[03][04]-10,( aPosObj[03][03] - aPosObj[03][01] ) - 10 Of oDlg Pixel
					
	oLbxPM8:AHeaders	:= aClone(aCabLbxPM8)
	oLbxPM8:AColSizes	:= { 50 , 20 , 50 , 50 }
	
	Eval(bMontaPM8)
	
	//====================================================================================================
	// Inclui os dados dos totalizadores da tela
	//====================================================================================================
	@ 004 , 004 Say "Valor Total a Pagar:"							SIZE 100,07 OF oScrPanel PIXEL
	@ 012 , 004 Say Transform( _nValTot  , '@E 999,999,999.99' )	SIZE 100,09 OF oScrPanel PIXEL FONT oBold COLOR CLR_BLUE
	
	@ 004 , 108 Say "Qtde. NF:"								 		SIZE 100,07 OF oScrPanel PIXEL
	@ 012 , 108 Say Transform( _nQtdNF   , '@E 999,999,999' )		SIZE 100,09	OF oScrPanel PIXEL FONT oBold COLOR CLR_BLUE
	
	@ 004 , 212 Say "Qtde. Produtores:"						 		SIZE 100,07 OF oScrPanel PIXEL
	@ 012 , 212 Say Transform( _nQtdProd , '@E 999,999,999' )	 	SIZE 100,09 OF oScrPanel PIXEL FONT oBold COLOR CLR_BLUE
	
	@ 004 , 316 Say "Primeiro Vencimento:"					 		SIZE 100,07 OF oScrPanel PIXEL
	@ 012 , 316 Say DToC( MV_PAR09 )							 	SIZE 100,09 OF oScrPanel PIXEL FONT oBold COLOR CLR_BLUE
	
	//====================================================================================================
	// Monta os Botoes da Barra Superior
	//====================================================================================================
	DEFINE BUTTONBAR oBar 3D OF oDlg SIZE 50,50
	
	DEFINE BUTTON aBtn[01] RESOURCE 'rpmsave_ocean'		OF oBar GROUP ACTION DlgToExcel( { { "ARRAY" , "" , oLbxPM7:AHeaders,oLbxPM7:aArray } } )	TOOLTIP "Exportar para Planilha..."
	aBtn[01]:cTitle := ""
	
	DEFINE BUTTON aBtn[02] RESOURCE "comptitl_ocean"	OF oBar GROUP ACTION ( _lGera := .T. , oDlg:End() )	  										TOOLTIP "Gerar Financeiro..."
	aBtn[02]:cTitle := ""
	
	DEFINE BUTTON aBtn[03] RESOURCE "upderror_ocean"	OF oBar GROUP ACTION ( _lGera := .F. , oDlg:End() )	  										TOOLTIP "Sair da Tela..."
	aBtn[03]:cTitle := ""
	
	oDlg:lMaximized := .T.

ACTIVATE MSDIALOG oDlg CENTERED

If _lGera
	Processa( {|| AGLT009FIN( _aResumo , _aDados ) } , 'Aguarde!' , 'Iniciando o processamento...' )
EndIf

Return

/*
===============================================================================================================================
Programa----------: fMontaPM8
Autor-------------: Alexandre Villar
Data da Criacao---: 19/12/2014
Descrição---------: Rotina que realiza a consulta dos dados
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function fMontaPM8( oLbxAux , cChaveTit , _aDados )

Local aLbxAux	:= {}
Local nPosChv   := 0

nPosChv := aScan( _aDados , {|x| x[02]+x[03] == cChaveTit } )

If nPosChv > 0

	While nPosChv <= Len(_aDados) .And. _aDados[nPosChv][02] + _aDados[nPosChv][03] == cChaveTit
		DBSelectArea('Z08')
		Z08->( DBGoTo( _aDados[nPosChv][07] ) )
		
		aAdd( aLbxAux , {	Z08->Z08_NF		,;
							Z08->Z08_SERIE	,;
							Z08->Z08_EMISSA	,;
							Z08->Z08_VALOR	})
		nPosChv++
	EndDo

EndIf

If Empty(aLbxAux)
	aAdd( aLbxAux , { 'Não encontrada' , '' , SToD('') , 0 } )
EndIf

If	Len(aLbxAux) > 0 .And. ValType(oLbxAux) == "O"
	oLbxAux:SetArray(aLbxAux)
	oLbxAux:bLine:={||{	aLbxAux[oLbxAux:nAt][01]									,; // 01
						aLbxAux[oLbxAux:nAt][02]									,; // 02
						DToC( aLbxAux[oLbxAux:nAt][03] ) 							,; // 03
						Transform( aLbxAux[oLbxAux:nAt][04] , '@E 999,999,999.99' )	}} // 04
	oLbxAux:Refresh()
EndIf

Return

/*
===============================================================================================================================
Programa----------: AGLT009MRK
Autor-------------: Alexandre Villar
Data da Criacao---: 19/12/2014
Descrição---------: Função para auxiliar no controle de marcação do Browse
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT009MRK( oX , nCol , oLbxAux , _aResumo )

Local _nI := 0

If	nCol == 1
	For _nI := 1 To Len( oLbxAux:aArray )
		oLbxAux:aArray[_nI][01]		:= !oLbxAux:aArray[_nI][01]
		_aResumo[oLbxAux:nAt][01]	:= oLbxAux:aArray[oLbxAux:nAt][01]
		oLbxAux:Refresh()
	Next _nI
EndIf

Return

/*
===============================================================================================================================
Programa----------: AGLT009R
Autor-------------: Alexandre Villar
Data da Criacao---: 19/12/2014
Descrição---------: Relatório para conferência Jurídica dos Termos e Valores
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT009R()

Local _cPerg	:= 'AGLT009R'

If Pergunte( _cPerg )
	Processa( {|| AGLT009MRJ() } , 'Aguarde!' , 'Iniciando o relatório...' )
Else
	Aviso( "AGLT00912" , 'Operação cancelada pelo usuário!' , {'Fechar'} )
	Return
EndIf

Return

/*
===============================================================================================================================
Programa----------: AGLT009MRJ
Autor-------------: Alexandre Villar
Data da Criacao---: 19/12/2014
Descrição---------: Função para processamento do relatório jurídico
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT009MRJ()

Local _cFiltro	:= "%"
Local _cAlias	:= GetNextAlias()
Local _aHeader	:= { 'Cód.Fornec.' , 'Fornecedor' , 'Qtde.Notas' , 'Valor Notas' , 'Valor Adiant.' , 'Valor Pagar' }
Local _aDados	:= {}
Local _nTotReg	:= 0
Local _nRegAtu	:= 0
Local _nOpc		:= 0
Local _nTotNot	:= 0
Local _nValTot	:= 0
Local _nTotAdt	:= 0
Local _nTotLiq	:= 0
Local _nI		:= 0
Private _oPrint	:= Nil
Private _nLinha	:= 0

If MV_PAR07 == 1
	_cFiltro += " AND Z08.Z08_STSJUR = 'A' "
	_cFiltro += " AND Z08.Z08_DATAVA BETWEEN '"+ DToS( MV_PAR08 ) +"' AND '"+ DToS( MV_PAR09 ) +"' "
Else
	_cFiltro += " AND Z08.Z08_STSJUR <> 'A'
EndIf
_cFiltro += "%"

BeginSql alias _cAlias
	SELECT Z08.Z08_CODFOR CODFOR, Z08.Z08_LOJFOR LOJFOR, SA2.A2_NOME NOMFOR, COUNT(1) QTD_NOTAS,
	       SUM(Z08.Z08_VALOR) VAL_NOTAS, MAX(Z08.Z08_VALPAG) VAL_ADIAN
	  FROM %Table:Z08% Z08, %Table:SA2% SA2
	 WHERE Z08.D_E_L_E_T_ = ' '
	   AND SA2.D_E_L_E_T_ = ' '
	   AND Z08.Z08_FILIAL = %xFilial:Z08%
	   AND SA2.A2_FILIAL = %xFilial:SA2%
	   AND SA2.A2_COD = Z08.Z08_CODFOR
	   AND SA2.A2_LOJA = Z08.Z08_LOJFOR
	   %exp:_cFiltro%
	   AND Z08.Z08_CODFOR BETWEEN %exp:MV_PAR01% AND %exp:MV_PAR03%
	   AND Z08.Z08_LOJFOR BETWEEN %exp:MV_PAR02% AND %exp:MV_PAR04%
	   AND Z08.Z08_EMISSA BETWEEN %exp:MV_PAR05% AND %exp:MV_PAR06%
	 GROUP BY Z08.Z08_CODFOR, Z08.Z08_LOJFOR, SA2.A2_NOME
	 ORDER BY SA2.A2_NOME
EndSql

ProcRegua(0)
IncProc( 'Iniciando...' )
IncProc( 'Aguarde! Pesquisando os dados...' )

Count To _nTotReg
(_cAlias)->( DBGoTop() )

If _nTotReg > 0	
	
	ProcRegua( _nTotReg )
	While (_cAlias)->( !Eof() )
		
		_nRegAtu++
		IncProc( 'Gravando dados... ['+ StrZero( _nRegAtu , 6 ) +'] de ['+ StrZero( _nTotReg , 6 ) +']' )
		
		aAdd( _aDados , {	(_cAlias)->CODFOR +'/'+ (_cAlias)->LOJFOR												,;
							(_cAlias)->NOMFOR																		,;
							Transform( (_cAlias)->QTD_NOTAS , "@E 999,999,999"    )									,;
							Transform( (_cAlias)->VAL_NOTAS , "@E 999,999,999.99" )									,;
							Transform( (_cAlias)->VAL_ADIAN , "@E 999,999,999.99" )									,;
							Transform( ( (_cAlias)->VAL_NOTAS - (_cAlias)->VAL_ADIAN ) / 2 , "@E 999,999,999.99" )	})
		
		(_cAlias)->( DBSkip() )
	EndDo
	(_cAlias)->( DBCloseArea() )
	
	_nOpc := Aviso( "AGLT00913" , 'O relatório atual pode ser impresso ou exportado para arquivos. Qual processamento deseja realizar?' , { 'Imprimir' , 'Exportar' , 'Cancelar' } )
	
	If _nOpc == 1
	
		ProcRegua(0)
		IncProc( 'Aguarde! Montando o relatório...' )
		
		_oPrint := TMSPrinter():New( 'AGLT009R' )
		_oPrint:SetPortrait()
		_oPrint:SetPaperSize(9)
		
		AGLT009CAB( _aHeader )
		_nRegAtu := 0
		
		For _nI := 1 To Len(_aDados)
			
			_nRegAtu++
			If _nRegAtu > 88
				_nRegAtu := 0
				_nLinha  += 030
				_oPrint:Line( _nLinha , 050 , _nLinha , 2400 )
				_oPrint:EndPage()
				AGLT009CAB( _aHeader )
			EndIf
			
			_nTotNot += Val( StrTran( StrTran( _aDados[_nI][03] , '.' , '' ) , ',' , '.' ) )
			_nValTot += Val( StrTran( StrTran( _aDados[_nI][04] , '.' , '' ) , ',' , '.' ) )
			_nTotAdt += Val( StrTran( StrTran( _aDados[_nI][05] , '.' , '' ) , ',' , '.' ) )
			_nTotLiq += Val( StrTran( StrTran( _aDados[_nI][06] , '.' , '' ) , ',' , '.' ) )
			AGLT009DAD( _aDados[_nI] )
			
		Next _nI
		
		_nRegAtu++
		If _nRegAtu > 88
			_nRegAtu := 0
			_nLinha  += 030
			_oPrint:Line( _nLinha , 050 , _nLinha , 2400 )
			_oPrint:EndPage()
			AGLT009CAB( _aHeader )
		Else
			_nLinha += 030
			_oPrint:Line( _nLinha , 050 , _nLinha , 2400 )
		EndIf
		
		AGLT009DAD({'Total de Todos os Produtores: '+AllTrim(Transform(Len(_aDados),'@E 999,999,999')),'',Transform(_nTotNot,'@E 999,999,999'),Transform(_nValTot,'@E 999,999,999.99'),Transform(_nTotAdt,'@E 999,999,999.99'),Transform(_nTotLiq,'@E 999,999,999.99')})
		_nLinha += 030
		_oPrint:Line( _nLinha , 050 , _nLinha , 2400 )
		
		_oPrint:Preview()
		
	ElseIf _nOpc == 2
		U_ITListBox( 'Relação de Produtores x Termos' , _aHeader , _aDados , .T. , 1 )
	Else
		Aviso( "AGLT00914" , 'Operação cancelada pelo usuário!' , {'Fechar'} )
	EndIf

Else
	Aviso( "AGLT00915" , 'O relatório não retornou nenhum registro com os filtos informados! Verifique a parametrização e tente novamente.' , {'Fechar'} )
EndIf

Return

/*
===============================================================================================================================
Programa----------: AGLT009CAB
Autor-------------: Alexandre Villar
Data da Criacao---: 19/12/2014
Descrição---------: Rotina que Processa a impressão do cabeçalho
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT009CAB( _aHeader )

Local _aPosCol	:= { 050 , 500 , 1200 , 1500 , 1800 , 2150 }
Local _oFont10b	:= TFont():New( "Courier New" ,, 10 ,, .T. ,,,, .T. , .F. )
Local _oFont22b	:= TFont():New( "Courier New" ,, 22 ,, .T. ,,,, .T. , .F. )

//====================================================================================================
// Impressão da primeira página do relatório
//====================================================================================================
_oPrint:Startpage()

If File('lgrl01.bmp')
	_oPrint:SayBitmap( 050 , 050 , 'lgrl02.bmp' , 300 , 100 )
EndIf

_nLinha := 075
_oPrint:Say( _nLinha , 550 , 'Relação de Produtores x Termos' , _oFont22b )
_nLinha += 100
_oPrint:Line( _nLinha , 050 , _nLinha , 2400 )
_nLinha += 010

_oPrint:Say( _nLinha , _aPosCol[01] , _aHeader[01] , _oFont10b )
_oPrint:Say( _nLinha , _aPosCol[02] , _aHeader[02] , _oFont10b )
_oPrint:Say( _nLinha , _aPosCol[03] , _aHeader[03] , _oFont10b )
_oPrint:Say( _nLinha , _aPosCol[04] , _aHeader[04] , _oFont10b )
_oPrint:Say( _nLinha , _aPosCol[05] , _aHeader[05] , _oFont10b )
_oPrint:Say( _nLinha , _aPosCol[06] , _aHeader[06] , _oFont10b )

_nLinha += 050
_oPrint:Line( _nLinha , 050 , _nLinha , 2400 )
_nLinha += 050

Return

/*
===============================================================================================================================
Programa----------: AGLT009DAD
Autor-------------: Alexandre Villar
Data da Criacao---: 19/12/2014
Descrição---------: Rotina que Processa a impressão dos dados
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT009DAD( _aDadAux )

Local _aPosCol	:= { 050 , 310 , 1100 , 1750 , 2070 , 2400 }
Local _oFont10	:= TFont():New( "Courier New" ,, 10 ,, .F. ,,,, .T. , .F. )

_oPrint:Say( _nLinha , _aPosCol[01] , _aDadAux[01] , _oFont10 )
_oPrint:Say( _nLinha , _aPosCol[02] , _aDadAux[02] , _oFont10 )
_oPrint:Say( _nLinha , _aPosCol[03] , _aDadAux[03] , _oFont10 )
_oPrint:Say( _nLinha , _aPosCol[04] , _aDadAux[04] , _oFont10 ,,,, 1 )
_oPrint:Say( _nLinha , _aPosCol[05] , _aDadAux[05] , _oFont10 ,,,, 1 )
_oPrint:Say( _nLinha , _aPosCol[06] , _aDadAux[06] , _oFont10 ,,,, 1 )

_nLinha += 035

Return

/*
===============================================================================================================================
Programa----------: AGLT009A
Autor-------------: Alexandre Villar
Data da Criacao---: 19/12/2014
Descrição---------: Rotina de avaliação dos termos dos produtores
Parametros--------: Nenhum
Retorno-----------: aRotina - Definições do menu principal da Rotina.
===============================================================================================================================
*/
User Function AGLT009A()

Local _aArea	:= FWGetArea()
Local _aNotas	:= {}
Local _aHeader	:= {'Nota','Série','Emissão','Val.Nota'}
Local _cCodFor	:= Z08->Z08_CODFOR
Local _cLojFor	:= Z08->Z08_LOJFOR
Local _cNomFor	:= AllTrim( Posicione('SA2',1,xFilial('SA2')+_cCodFor+_cLojFor,'A2_NOME') )
Local _cAlias	:= GetNextAlias()
Local _nValTot	:= 0
Local _nValAdt	:= 0
Local _nValLiq	:= 0
Local _oDlg		:= Nil
Local _oLbxAux	:= Nil
Local _oCombo	:= Nil
Local _cCombo	:= ''
Local _aCombo	:= {'Aprovado','Pendente'}
Local _lRet		:= .F.
Local _aCoors	:= { 000 , 000 , 340 , 590 }
Local _aPosAux	:= { { 002 , 002 , 157 , 293 } }
Local _bOk		:= {|x| _lRet := .T. , _oDlg:End() }
Local _bCancel	:= {|x| _lRet := .F. , _oDlg:End() }

BeginSql Alias _cAlias
	SELECT Z08.Z08_NF, Z08.Z08_SERIE, Z08.Z08_EMISSA, Z08.Z08_VALOR, Z08.Z08_VALPAG, Z08.Z08_STSJUR
	FROM %Table:Z08% Z08
	WHERE Z08.D_E_L_E_T_ =' '
	AND Z08.Z08_FILIAL = %xFilial:Z08%
	AND Z08.Z08_CODFOR = %exp:_cCodFor%
	AND Z08.Z08_LOJFOR = %exp:_cLojFor%
	ORDER BY Z08.Z08_EMISSA
EndSql

Count To _nTotReg
(_cAlias)->( DBGoTop() )

If _nTotReg > 0
	While (_cAlias)->( !Eof() )
		
		_nValTot += (_cAlias)->Z08_VALOR
		_cStatus := (_cAlias)->Z08_STSJUR
		
		If _nValAdt == 0 .And. (_cAlias)->Z08_VALPAG > 0
			_nValAdt := (_cAlias)->Z08_VALPAG
		EndIf
		
		aAdd( _aNotas , {	(_cAlias)->Z08_NF										,;
							(_cAlias)->Z08_SERIE									,;
							SToD( (_cAlias)->Z08_EMISSA )							,;
							Transform( (_cAlias)->Z08_VALOR , '@E 999,999,999.99' )	})
		
	(_cAlias)->( DBSkip() )
	EndDo
	
	(_cAlias)->( DBCloseArea() )
	
	If _cStatus == 'A'
		_cCombo := 'Aprovado'
	Else
		_cCombo := 'Pendente'
	EndIf
	
	_cStatus := _cCombo
	
	_nValLiq := ( _nValTot - _nValAdt ) / 2
	
	DEFINE MSDIALOG _oDlg TITLE 'Avaliação do Termo do Produtor' FROM _aCoors[1],_aCoors[2] TO _aCoors[3],_aCoors[4] PIXEL
	
		@_aPosAux[01][01] , 010 Say 'Código/Nome: '+ _cCodFor +'/'+ _cLojFor +' - '+ _cNomFor +'(Status Atual: '+ _cStatus +')'	OF _oDlg PIXEL ; _aPosAux[01][01] += 010
		@_aPosAux[01][01] , 010 Say 'Qtde. Notas: '+ Transform( Len(_aNotas)	, '@E 999,999,999'    )							OF _oDlg PIXEL
		@_aPosAux[01][01] , 200 Say 'Valor Total: '+ Transform( _nValTot		, '@E 999,999,999.99' )							OF _oDlg PIXEL ; _aPosAux[01][01] += 010
		@_aPosAux[01][01] , 010 Say 'Val.Adiant.: '+ Transform( _nValAdt		, '@E 999,999,999.99' )							OF _oDlg PIXEL
		@_aPosAux[01][01] , 200 Say 'Val.  Pagar: '+ Transform( _nValLiq		, '@E 999,999,999.99' )							OF _oDlg PIXEL ; _aPosAux[01][01] += 010
		
		@_aPosAux[01][01] , _aPosAux[01][02]	LISTBOX	_oLbxAux	;
												FIELDS	HEADER ""	;
												ON		DblClick()	;
												SIZE	_aPosAux[01][04] , ( _aPosAux[01][03] - _aPosAux[01][01] - 015 ) OF _oDlg PIXEL
		
		_oLbxAux:AHeaders		:= aClone( _aHeader )
		_oLbxAux:bHeaderClick	:= { |oObj,nCol| ITOrdLbx( oObj , nCol , oLbxAux , ,  ) }
		_oLbxAux:SetArray( _aNotas )
		_oLbxAux:AColSizes		:= { 25 , 25 , 35 , 50 }
		
		//===========================================================================
		//| Atribui os dados ao ListBox                                             |
		//===========================================================================
		_oLbxAux:bLine	:= {|| {	_aNotas[_oLbxAux:nAt,01] ,;
									_aNotas[_oLbxAux:nAt,02] ,;
									_aNotas[_oLbxAux:nAt,03] ,;
									_aNotas[_oLbxAux:nAt,04] }}
	    
		@_aPosAux[01][03] - 010 , 010 Say 'Avaliação: '								OF _oDlg PIXEL
		@_aPosAux[01][03] - 012 , 040 COMBOBOX _oCombo VAR _cCombo ITEMS _aCombo	OF _oDlg PIXEL SIZE 180,10
	
	ACTIVATE MSDIALOG _oDlg ON INIT EnchoiceBar(_oDlg,_bOk,_bCancel) CENTERED
	
	If _lRet
		
		_cRet := SubStr( _cCombo , 1 , 1 )
		LjMsgRun( 'Gravando o Status...' , 'Aguarde!' , {|| AGLT009STS( _cCodFor , _cLojFor , _cRet ) } )
		
	EndIf
	
EndIf

FWRestArea( _aArea )

Return

/*
===============================================================================================================================
Programa----------: AGLT009STS
Autor-------------: Alexandre Villar
Data da Criacao---: 19/12/2014
Descrição---------: Rotina que Processa a atualização de Status dos registros
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT009STS( _cCodFor , _cLojFor , _cStatus )

Local _aArea	:= FWGetArea()
Local _cAlias	:= GetNextAlias()

BeginSql Alias _cAlias
	SELECT Z08.R_E_C_N_O_ REGZ08
	FROM %Table:Z08% Z08
	WHERE Z08.D_E_L_E_T_ =' '
	AND Z08.Z08_FILIAL = %xFilial:Z08%
	AND Z08.Z08_CODFOR = %exp:_cCodFor%
	AND Z08.Z08_LOJFOR = %exp:_cLojFor%
EndSql

If (_cAlias)->( !Eof() )
	
	While (_cAlias)->( !Eof() )
	
		DBSelectArea('Z08')
		Z08->( DBGoTo( (_cAlias)->REGZ08 ) )
		Z08->( RecLock( 'Z08' , .F. ) )
		Z08->Z08_STSJUR := _cStatus
		Z08->Z08_DATAVA := IIf( _cStatus == 'A' , Date() , SToD('') )
		Z08->( MSUnLock() )
		
	(_cAlias)->( DBSkip() )
	EndDo
	
	Aviso( "AGLT00916" , 'Registros atualizados com sucesso!' , {'Ok'} )
	
Else
	Aviso( "AGLT00917" , 'Falha ao localizar os registros do Produtor! Informe a área de IT/ERP.' , {'Fechar'} )
EndIf

FWRestArea( _aArea )

Return
