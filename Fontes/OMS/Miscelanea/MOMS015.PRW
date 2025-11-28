/*
===============================================================================================================================
                          ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
       Autor      |    Data    |                                             Motivo                                          
-------------------------------------------------------------------------------------------------------------------------------
  Josué Danich    | 31/07/2018 | Inclusão de cálculo de supervisor - Chamado 25555
-------------------------------------------------------------------------------------------------------------------------------
  Josué Danich    | 09/01/2018 | Ajuste de bug na chamada de rotina de log e padrões de codificação - Chamado 27619
-------------------------------------------------------------------------------------------------------------------------------
 Lucas Borges     | 11/10/2019 | Removidos os Warning na compilação da release 12.1.25. Chamado 28346
===============================================================================================================================
*/

//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================
#Include "TOTVS.ch"
#Include 'FWMVCDef.Ch'

#Define CRLF Chr(13)+Chr(10)

/*
===============================================================================================================================
Programa----------: MOMS015
Autor-------------: Alexandre Villar
Data da Criacao---: 06/10/2014
===============================================================================================================================
Descrição---------: Rotina de cálculo da comissão adicional a descontar referente à bonificações
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS015()

Local _oBrowse	:= Nil

Private aRotina	:= MenuDef()

//================================================================================
// Instancia a Classe do Browse Principal
//================================================================================
_oBrowse := FWMBrowse():New()
_oBrowse:SetAlias( 'ZC6' )
_oBrowse:SetDescription( 'Comissão - Cálculo de Bonificações' )
_oBrowse:Activate()

Return

/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Alexandre Villar
Data da Criacao---: 13/08/2014
===============================================================================================================================
Descrição---------: Rotina de definição do menu da tela principal
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MenuDef()

Local _aRotina	:= {}

ADD OPTION _aRotina Title 'Visualizar'	Action 'VIEWDEF.MOMS015'	OPERATION 2 ACCESS 0 //Visualizar
ADD OPTION _aRotina Title 'Detalhar'	Action 'U_MOMS015D()'		OPERATION 2 ACCESS 0 //Detalhar
ADD OPTION _aRotina Title 'Calcular'	Action 'U_MOMS015C()'		OPERATION 3 ACCESS 0 //Calcular

Return( _aRotina )

/*
===============================================================================================================================
Programa----------: ModelDef
Autor-------------: Alexandre Villar
Data da Criacao---: 13/08/2014
===============================================================================================================================
Descrição---------: Define o modelo de dados para a rotina de cadastro
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ModelDef()

//================================================================================
// Prepara a estrutura a ser usada no Modelo de Dados
//================================================================================
Local oStruZC6	:= FWFormStruct( 1 , 'ZC6' )
Local oModel	:= Nil

//================================================================================
// Cria e configura o modelo de dados
//================================================================================
oModel := MPFormModel():New( 'MOMS015M' )

oModel:SetDescription( 'Modelo de Dados do cálculo de comissão de bonificação' )
oModel:AddFields( 'ZC6MASTER' ,, oStruZC6 )
oModel:SetPrimaryKey( { 'ZC6_FILIAL' , 'ZC6_CODVEN' , 'ZC6_ANOMES' } )

Return( oModel )

/*
===============================================================================================================================
Programa----------: ViewDef
Autor-------------: Alexandre Villar
Data da Criacao---: 13/08/2014
===============================================================================================================================
Descrição---------: Define a View de dados para a rotina de cadastro
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ViewDef()

//================================================================================
// Prepara a estrutura do objeto da View
//================================================================================
Local oModel   	:= FWLoadModel( 'MOMS015' )
Local oStruZC6	:= FWFormStruct( 2 , 'ZC6' )
Local oView		:= Nil

oStruZC6:RemoveField( 'ZC6_FILIAL' )

//================================================================================
// Cria e configura o objeto da View
//================================================================================
oView := FWFormView():New()

oView:SetModel( oModel )
oView:AddField( "VIEW_ZC6" , oStruZC6 , "ZC6MASTER" )
oView:CreateHorizontalBox( "TELA" , 100 )
oView:SetOwnerView( "VIEW_ZC6" , "TELA" )

Return( oView )

/*
===============================================================================================================================
Programa----------: MOMS015C
Autor-------------: Alexandre Villar
Data da Criacao---: 18/08/2014
===============================================================================================================================
Descrição---------: Pontos de entrada do MODELO em MVC
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS015C()

Local _aParam	:= {}
Local _aParRet	:= {}
Local _cDtRef	:= SubStr( DToS( MonthSub( dDataBase , 1 ) ) , 1 , 6 )
Local _cAnoMes	:= SubStr( _cDtRef , 5 , 2 ) +'/'+ SubStr( _cDtRef , 1 , 4 )
Private _aRet := {}

If !U_ITACSUSR( 'ZZL_ADMCMS' , 'S' )
	U_ITMsg( 'Usuário sem acesso ao processamento de cálculo de Comissões!','Atenção!',' Verifique com a área de TI/ERP' , 1 )
	Return
EndIf


If MOMS015VLF()

	U_ITMsg('Não é possível recalcular as comissões para um período que já foi fechado. '										+;
				'O período atual ['+ SubStr( _cDtRef , 5 , 2 ) +'/'+ SubStr( _cDtRef , 1 , 4 ) +'] não pode mais ser processado. '	,;
				'Atenção!' ,, 1 )	
	Return
	
EndIf

//================================================================================
// Verifica se pode rodar rotina quanto a sequencia de fechamento de comissões
//================================================================================
If .not. u_MOMS005VD(2)
	  
  Return
	  
EndIf

//================================================================================
// Monta a parametrização das perguntas iniciais
//================================================================================
aAdd( _aParam , { 1 , "Mes/Ano: "		, _cAnoMes		, "@!" , '.T.' ,          , '.F.' , 40 , .T. } )

_aParRet := { _aParam[01][03] }

If ParamBox( _aParam , 'Configuração do Processamento!' , @_aParRet ,,,,,,, .F. , .F. )
	
	_aRet := {}
	FWMsgRun( ,{|oproc| _aRet := MOMS015EXE( _cDtRef,oproc ) } , 'Aguarde!' , 'Iniciando o processamento...' )
	
	_ahdrAux := _aRet[1]
	_arestot := _aRet[2]
	
	U_ITListBox( 'Cálculo de Comissão' , _aHdrAux , _aResTot , .T. , 1 , 'Detalhes do processamento:' )
	
	//================================================================================
	//GRAVA LOG DE EXECUÇÃO
	//================================================================================
	
	RecLock("ZC8",.T.)
 
 	ZC8->ZC8_FILIAL     := xFilial("ZC8")   
	ZC8->ZC8_SEQ        := U_MOMS009C()  //Gera nova sequência do ZC8
	ZC8->ZC8_ROTINA     := "Adicionais de Comissao"
	ZC8->ZC8_DATA       := Date()
	ZC8->ZC8_HORA       := Time()
	ZC8->ZC8_USER       := cUserName
	ZC8->ZC8_CODUSU     := __cUserId
	ZC8->ZC8_OBS        := '2 - Bonificações'
	ZC8->ZC8_COMP       := _cAnoMes
 
	MSUnLock()
	
	
Else

	U_ITMsg( 'Operação cancelada pelo usuário!' , 'Atenção!',,1 )

EndIf
	
Return

/*
===============================================================================================================================
Programa----------: MOMS015EXE
Autor-------------: Alexandre Villar
Data da Criacao---: 18/08/2014
===============================================================================================================================
Descrição---------: Processamento do Cálculo das Comissões
===============================================================================================================================
Parametros--------: _cDtRef - Data de referência
					oproc - objeto da barra de processamento
===============================================================================================================================
Retorno-----------: _aRet - array com header e acols do itlist de resultado do processamento
===============================================================================================================================
*/

Static Function MOMS015EXE( _cDtRef, oproc )

Local _aDados	:= {}
Local _aResTot	:= {}
Local _aHdrAux	:= {	'Cód. Vendedor'			,; //01
						'Nome Vendedor'			,; //02
						'Cód. Produto'			,; //03
						'Desc. Produto'			,; //04
						'Qt. 1ª UM'				,; //05
						'1ª UM'					,; //06
						'Qt. 2ª UM'				,; //07
						'2ª UM'					,; //08
						'Valor Total'			,; //09
						'Devoluç. 1ª UM'		,; //10
						'Devoluç. 2ª UM'		,; //11
						'Valor Devoluç.'		,; //12
						'Qt. Líq. 1ª UM'		,; //13
						'Qt. Líq. 2ª UM'		,; //14
						'Valor Líquido'			,; //15
						'% Comissão'			,; //16
						'Val. Comissão'			 } //17

Local _cAlias	:= GetNextAlias()
Local _cAliCms	:= GetNextAlias()
Local _cQuery	:= ''
Local _cDtIni	:= DToS( CtoD( '01/' + MV_PAR01  ) )
Local _cDtFim	:= SubStr( _cDtIni , 1 , 6 ) + '31'
Local _cCodVen	:= ''
Local _nI       := 0
Local _nTotReg	:= 0
Local _nQtdDev1 := 0
Local _nQtdDev2 := 0
Local _nValDev  := 0
Local _nConAux	:= 0

oproc:cCaption := 'Processando a consulta dos dados...'
ProcessMessages()

Begin Transaction

//================================================================================
// Verifica e apaga os registros anteriores
//================================================================================
FWMsgRun(, {|oproc| MOMS015DEL( _cDtIni , _cDtRef) } ,'Excluindo cálculos anteriores...' , 'Aguarde!'  )

//================================================================================
// Consulta os dados conforme os parâmetros para calcular as comissões
//================================================================================
_cQuery := " SELECT "
_cQuery += "    SF2.F2_VEND1        AS CODVEN   , "
_cQuery += "    SA3.A3_NOME			AS NOMVEN   , "
_cQuery += "    SB1.B1_COD          AS CODPRD   , "
_cQuery += "    SB1.B1_DESC         AS DESPRD   , "
_cQuery += "    SUM(SD2.D2_QUANT)   AS QTDPUM   , "
_cQuery += "    SD2.D2_UM           AS PRIUM    , "
_cQuery += "    SUM(SD2.D2_QTSEGUM) AS QTDSUM   , "
_cQuery += "    SD2.D2_SEGUM        AS SEGUM    , "
_cQuery += "    SUM(SD2.D2_VALBRUT) AS VALTOT     "
_cQuery += " FROM "+ RetSqlName('SF2') +" SF2 "
_cQuery += " JOIN "+ RetSqlName('SD2') +" SD2 ON SD2.D2_DOC		= SF2.F2_DOC	AND SD2.D2_SERIE	= SF2.F2_SERIE AND SD2.D2_FILIAL = SF2.F2_FILIAL "
_cQuery += " JOIN "+ RetSqlName('SA1') +" SA1 ON SD2.D2_CLIENTE	= SA1.A1_COD	AND SD2.D2_LOJA		= SA1.A1_LOJA "
_cQuery += " JOIN "+ RetSqlName('SB1') +" SB1 ON SD2.D2_COD		= SB1.B1_COD "
_cQuery += " JOIN "+ RetSqlName('SBM') +" SBM ON SB1.B1_GRUPO	= SBM.BM_GRUPO "
_cQuery += " JOIN "+ RetSqlName('SA3') +" SA3 ON SF2.F2_VEND1	= SA3.A3_COD "
_cQuery += " JOIN "+ RetSqlName('SF4') +" SF4 ON SD2.D2_FILIAL	= SF4.F4_FILIAL	AND SD2.D2_TES		= SF4.F4_CODIGO "
_cQuery += " JOIN "+ RetSqlName('ZAY') +" ZAY ON ZAY.ZAY_CF     = SD2.D2_CF "
_cQuery += " WHERE "
_cQuery += "     SF2.D_E_L_E_T_ = ' ' "
_cQuery += " AND SD2.D_E_L_E_T_ = ' ' "
_cQuery += " AND SA1.D_E_L_E_T_ = ' ' "
_cQuery += " AND SB1.D_E_L_E_T_ = ' ' "
_cQuery += " AND SBM.D_E_L_E_T_ = ' ' "
_cQuery += " AND SA3.D_E_L_E_T_ = ' ' "
_cQuery += " AND SF4.D_E_L_E_T_ = ' ' "
_cQuery += " AND ZAY.D_E_L_E_T_ = ' ' "
_cQuery += " AND SF2.F2_EMISSAO BETWEEN '"+ _cDtIni +"' AND '"+ _cDtFim +"' "	//Filtra data de Emissão de acordo com o Mês de Referência
_cQuery += " AND SB1.B1_TIPO    = 'PA' "
_cQuery += " AND ZAY.ZAY_TPOPER	= 'B' "

_cQuery += " GROUP BY SF2.F2_VEND1 , SA3.A3_NOME , SB1.B1_COD , SB1.B1_DESC , SB1.B1_I_TIPLT , SD2.D2_UM , SD2.D2_SEGUM "
_cQuery += " ORDER BY 1 , 5 , 3 "

oproc:cCaption := 'Processando o cálculo das comissões...'
ProcessMessages()

DBUseArea( .T. , "TOPCONN" , TcGenQry( ,, _cQuery ) , _cAlias , .T. , .F. )

DBSelectArea(_cAlias)
(_cAlias)->( DBGoTop() )
(_cAlias)->( DBEval( {|| _nTotReg++ } ) )
(_cAlias)->( DBGoTop() )

If _nTotReg > 0
	
	ProcRegua( _nTotReg )
	
	While (_cAlias)->( !Eof() )
		
		_nConAux++
		oproc:cCaption := 'Processando... ['+ StrZero(_nConAux,9) +'] de ['+ StrZero(_nTotReg,9) +'].'
		ProcessMessages()
		
		//================================================================================
		// Verifica e Inclui Linhas de Totalizador
		//================================================================================
		If !Empty( _cCodVen ) .And. _cCodVen <> (_cAlias)->CODVEN
			
			//================================================================================
			// Chama rotina que inclui dados de Totalizadores e Gera os Registros de Comissão
			//================================================================================
			MOMS015TOT( @_aDados , _cDtRef , _cCodVen )
			
			For _nI := 1 To Len(_aDados)
				aAdd( _aResTot , _aDados[_nI] )
			Next _nI
			
			_aDados  := {}
					
		EndIf
		
		//================================================================================
		// Inicializa as variáveis e verifica se deve abater devoluções
		//================================================================================
	    _nQtdDev1 := 0
	    _nQtdDev2 := 0
	    _nValDev2 := 0
	    _cCodVen  := (_cAlias)->CODVEN
	    _nPerCom  := 0
	    
		//================================================================================
		// Verifica a % de comissão para o vendedor para o produto atual
		//================================================================================
		_cQuery := " SELECT "
		_cQuery += "     ZAE.ZAE_COMIS1 "
		_cQuery += " FROM "+ RetSqlName('ZAE') +" ZAE "
		_cQuery += " WHERE "
		_cQuery += "     ZAE.D_E_L_E_T_ = ' ' "
		_cQuery += " AND ZAE.ZAE_VEND   = '"+ (_cAlias)->CODVEN +"' "
		_cQuery += " AND ZAE.ZAE_PROD   = '"+ (_cAlias)->CODPRD +"' "
		_cQuery += " AND ZAE.ZAE_GRPVEN = ' ' "
		_cQuery += " AND ZAE.ZAE_CLI    = ' ' "
		_cQuery += " AND ZAE.ZAE_LOJA   = ' ' "
		
		If Select(_cAliCms) > 0
			(_cAliCms)->( DBCloseArea() )
		EndIf
		
		DBUseArea( .T. , "TOPCONN" , TcGenQry( ,, _cQuery ) , _cAliCms , .T. , .F. )	
		
		DBSelectArea(_cAliCms)
		(_cAliCms)->( DBGoTop() )
		If (_cAliCms)->( !Eof() )
    		_nPerCom  := (_cAliCms)->ZAE_COMIS1
		EndIf
		
		(_cAliCms)->( DBCloseArea() )
		
		MOMS015DEV( (_cAlias)->CODVEN , (_cAlias)->CODPRD , _cDtIni , _cDtFim , @_nQtdDev1 , @_nQtdDev2 , @_nValDev2 )
		
		_nValDev += _nValDev2
		
		//================================================================================
		// Grava os dados para exibição e monta a base de cálculo
		//================================================================================
		aAdd( _aDados , {	(_cAlias)->CODVEN										,; //01 - Cód. Vendedor
							(_cAlias)->NOMVEN										,; //02 - Nome Vendedor
							(_cAlias)->CODPRD										,; //03 - Cód. Produto
							(_cAlias)->DESPRD										,; //04 - Desc. Produto
							(_cAlias)->QTDPUM										,; //05 - Qtd. Primeira UM
							(_cAlias)->PRIUM										,; //06 - Primeira UM
							(_cAlias)->QTDSUM										,; //07 - Qtd. Segunda UM
							(_cAlias)->SEGUM 										,; //08 - Segunda UM
							(_cAlias)->VALTOT										,; //09 - Valor Total
							Round( _nQtdDev1 , 2 )									,; //10 - Dev. Primeira UM
							Round( _nQtdDev2 , 2 )									,; //11 - Dev. Primeira UM
							_nValDev2												,; //12 - Valor Total da Devolução
							Round( (_cAlias)->QTDPUM - _nQtdDev1 , 2 )				,; //13 - Qtd. Líq. UM
							Round( (_cAlias)->QTDSUM - _nQtdDev2 , 2 )				,; //14 - Qtd. Líq. Seg. UM
							(_cAlias)->VALTOT - _nValDev2							,; //15 - Valor Líq.
							_nPerCom												,; //16 - % Comissão
							( (_cAlias)->VALTOT - _nValDev2 ) * ( _nPerCom / 100 )	}) //17 - Val. Comissão
		
	(_cAlias)->( DBSkip() )
	EndDo
	
	//================================================================================
	// Chama rotina que inclui dados de Totalizadores e Gera os Registros de Comissão
	//================================================================================
	MOMS015TOT( @_aDados , _cDtRef , _cCodVen )
	
	//================================================================================
	// Chama rotina que verifica e registra os Totalizadores e Títulos de Comissão
	//================================================================================
	FWMsgRun( ,{|oproc| MOMS015SUP( _cDtRef,oproc ) } , 'Verificando dados das bonificações...' , 'Aguarde!'  )
	
	For _nI := 1 To Len(_aDados)
		aAdd( _aResTot , _aDados[_nI] )
	Next _nI
	
EndIf

(_cAlias)->( DBCloseArea() )

End Transaction

_aRet := {_aHdrAux, _aResTot}

Return _aRet

/*
===============================================================================================================================
Programa----------: MOMS015TOT
Autor-------------: Alexandre Villar
Data da Criacao---: 06/10/2014
===============================================================================================================================
Descrição---------: Rotina de cálculo dos totalizadores e gravação dos dados
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/

Static Function MOMS015TOT( _aDados , _cDtRef , _cCodVen )

Local _aDadZC7		:= {}
Local _cCodSup		:= ''
Local _nPerCom		:= 0
Local _cQuery		:= ''
Local _cAlias		:= GetNextAlias()
Local _nI			:= 0
Local _nVal			:= 0
Local _nValDev		:= 0
Local _nValLiq		:= 0
Local _nValCms		:= 0

Default _aDados		:= {}
Default _cDtRef		:= SubStr( DToS( MonthSub( dDataBase , 1 ) ) , 1 , 6 )
Default _cCodVen	:= ''

//================================================================================
// Guarda os dados para gravação dos itens do vendedor atual
//================================================================================
For _nI := 1 To Len( _aDados )

	aAdd( _aDadZC7 , {	_cCodVen		 	,;
						_cDtRef				,;
						'01'				,; //ZC7_ITEM -- 01 = Vendedor, 02 = Supervisor
						_aDados[_nI][03]	,; //ZC7_CODPRD
						_aDados[_nI][05]	,; //ZC7_QTDTUM
						_aDados[_nI][06]	,; //ZC7_UM
						_aDados[_nI][07]	,; //ZC7_QTDTSU
						_aDados[_nI][08]	,; //ZC7_SUM
						_aDados[_nI][09]	,; //ZC7_VALTOT
						_aDados[_nI][10]	,; //ZC7_DEVUM
						_aDados[_nI][11]	,; //ZC7_DEVSUM
						_aDados[_nI][12]	,; //ZC7_VALDEV
						_aDados[_nI][13]	,; //ZC7_QTDLUM
						_aDados[_nI][14]	,; //ZC7_QTDLSU
						_aDados[_nI][15]	,; //ZC7_VALLIQ
						_aDados[_nI][16]	,; //ZC7_PERCMS
						_aDados[_nI][17]	}) //ZC7_VALCMS
	
	_nVal    += _aDados[_nI][09]
	_nValDev += _aDados[_nI][12]
	_nValLiq += _aDados[_nI][15]
	_nValCms += _aDados[_nI][17]
	
Next _nI

//================================================================================
// Inclui o totalizador do vendedor atual
//================================================================================
aAdd( _aDados , {	_cCodVen												,; //Cód. Vendedor
					Posicione('SA3',1,xFilial('SA3')+_cCodVen,'A3_NOME')	,; //Nome Vendedor
					'---'													,; //Cód. Produto
					'Total do Vendedor'										,; //Desc. Produto
					'---'													,; //Qtd. Primeira UM
					'---'	   										 		,; //Primeira UM
					'---'													,; //Qtd. Segunda UM
					'---'		 											,; //Segunda UM
					Transform( _nVal	, '@E 999,999,999.99' )				,; //Valor Total
					'---'													,; //Dev. Primeira UM
					'---'													,; //Dev. Segunda UM
					Transform( _nValDev	, '@E 999,999,999.99' )				,; //Valor Total da Devolução
					'---'													,; //Qtd. Líq. UM
					'---'													,; //Qtd. Líq. Seg. UM
					Transform( _nValLiq	, '@E 999,999,999.99' )				,; //Valor Líquido
					Transform((_nValCms/_nValLiq)*100,'@E 9,999.9999')		,; //% Comissão
					Transform( _nValCms	, '@E 999,999,999.99' )				}) //Valor Comissão

//================================================================================
// Gravação dos ítens do vendedor atual
//================================================================================
For _nI := 1 To Len( _aDadZC7 )
	
	DBSelectArea('ZC7')
	ZC7->( RecLock( 'ZC7' , .T. ) )
	
	ZC7->ZC7_FILIAL := xFilial('ZC7')
	ZC7->ZC7_CHAVE  := _aDadZC7[_nI][01] + _aDadZC7[_nI][02]
	ZC7->ZC7_ITEM   := _aDadZC7[_nI][03]
	ZC7->ZC7_CODPRD := _aDadZC7[_nI][04]
	ZC7->ZC7_QTDUM  := _aDadZC7[_nI][05]
	ZC7->ZC7_UM		:= _aDadZC7[_nI][06]
	ZC7->ZC7_QTDSUM := _aDadZC7[_nI][07]
	ZC7->ZC7_SUM	:= _aDadZC7[_nI][08]
	ZC7->ZC7_VALTOT := _aDadZC7[_nI][09]
	ZC7->ZC7_DEVUM  := _aDadZC7[_nI][10]
	ZC7->ZC7_DEVSUM := _aDadZC7[_nI][11]
	ZC7->ZC7_VALDEV := _aDadZC7[_nI][12]
	ZC7->ZC7_QTDLUM := _aDadZC7[_nI][13]
	ZC7->ZC7_QTDLSU := _aDadZC7[_nI][14]
	ZC7->ZC7_VALLIQ := _aDadZC7[_nI][15]
	ZC7->ZC7_PERCMS := _aDadZC7[_nI][16]
	ZC7->ZC7_VALCMS := _aDadZC7[_nI][17]
	
	ZC7->( MSUnLock() )
	
	//================================================================================
	// Verifica se o produto atual gera comissão para o coordenador
	//================================================================================
	_nPerCom := 0
	_cCodSup := ''
	
	_cQuery := " SELECT "
	_cQuery += "     ZAE.ZAE_CODSUP, "
	_cQuery += "     ZAE.ZAE_COMIS2 "
	_cQuery += " FROM "+ RetSqlName('ZAE') +" ZAE "
	_cQuery += " WHERE "
	_cQuery += "     ZAE.D_E_L_E_T_ = ' ' "
	_cQuery += " AND ZAE.ZAE_VEND   = '"+ _aDadZC7[_nI][01] +"' "
	_cQuery += " AND ZAE.ZAE_PROD   = '"+ _aDadZC7[_nI][04] +"' "
	_cQuery += " AND ZAE.ZAE_GRPVEN = ' ' "
	_cQuery += " AND ZAE.ZAE_CLI    = ' ' "
	_cQuery += " AND ZAE.ZAE_LOJA   = ' ' "
	
	If Select(_cAlias) > 0
		(_cAlias)->( DBCloseArea() )
	EndIf
	
	DBUseArea( .T. , "TOPCONN" , TcGenQry( ,, _cQuery ) , _cAlias , .T. , .F. )
	
	DBSelectArea(_cAlias)
	(_cAlias)->( DBGoTop() )
	If (_cAlias)->( !Eof() )
		_cCodSup	:= (_cAlias)->ZAE_CODSUP
		_nPerCom	:= (_cAlias)->ZAE_COMIS2
	EndIf
	
	(_cAlias)->( DBCloseArea() )
	
	//================================================================================
	// Processa os descontos para o coordenador referente ao vendedor atual
	//================================================================================
	If _nPerCom > 0 .And. !Empty( _cCodSup )
		
		DBSelectArea('ZC7')
		ZC7->( RecLock( 'ZC7' , .T. ) )
		
		ZC7->ZC7_FILIAL := xFilial('ZC7')
		ZC7->ZC7_CHAVE  := _cCodSup + _cDtRef
		ZC7->ZC7_ITEM   := '02'
		ZC7->ZC7_CODPRD := _aDadZC7[_nI][04]
		ZC7->ZC7_QTDUM  := _aDadZC7[_nI][05]
		ZC7->ZC7_UM		:= _aDadZC7[_nI][06]
		ZC7->ZC7_QTDSUM := _aDadZC7[_nI][07]
		ZC7->ZC7_SUM	:= _aDadZC7[_nI][08]
		ZC7->ZC7_VALTOT := _aDadZC7[_nI][09]
		ZC7->ZC7_DEVUM  := _aDadZC7[_nI][10]
		ZC7->ZC7_DEVSUM := _aDadZC7[_nI][11]
		ZC7->ZC7_VALDEV := _aDadZC7[_nI][12]
		ZC7->ZC7_QTDLUM := _aDadZC7[_nI][13]
		ZC7->ZC7_QTDLSU := _aDadZC7[_nI][14]
		ZC7->ZC7_VALLIQ := _aDadZC7[_nI][15]
		ZC7->ZC7_PERCMS := _nPerCom
		ZC7->ZC7_VALCMS := Round( _aDadZC7[_nI][15] * ( _nPerCom / 100 ) , 2 )
		
		ZC7->( MSUnLock() )
		
	EndIf
	
	//================================================================================
	// Verifica se o produto atual gera comissão para o gerente
	//================================================================================
	_nPerCom := 0
	_cCodSup := ''
	
	_cQuery := " SELECT "
	_cQuery += "     ZAE.ZAE_CODGER, "
	_cQuery += "     ZAE.ZAE_COMIS3 "
	_cQuery += " FROM "+ RetSqlName('ZAE') +" ZAE "
	_cQuery += " WHERE "
	_cQuery += "     ZAE.D_E_L_E_T_ = ' ' "
	_cQuery += " AND ZAE.ZAE_VEND   = '"+ _aDadZC7[_nI][01] +"' "
	_cQuery += " AND ZAE.ZAE_PROD   = '"+ _aDadZC7[_nI][04] +"' "
	_cQuery += " AND ZAE.ZAE_GRPVEN = ' ' "
	_cQuery += " AND ZAE.ZAE_CLI    = ' ' "
	_cQuery += " AND ZAE.ZAE_LOJA   = ' ' "
	
	If Select(_cAlias) > 0
		(_cAlias)->( DBCloseArea() )
	EndIf
	
	DBUseArea( .T. , "TOPCONN" , TcGenQry( ,, _cQuery ) , _cAlias , .T. , .F. )
	
	DBSelectArea(_cAlias)
	(_cAlias)->( DBGoTop() )
	If (_cAlias)->( !Eof() )
		_cCodSup	:= (_cAlias)->ZAE_CODGER
		_nPerCom	:= (_cAlias)->ZAE_COMIS3
	EndIf
	
	(_cAlias)->( DBCloseArea() )
	
	//================================================================================
	// Processa os descontos para o gerente referente ao vendedor atual
	//================================================================================
	If _nPerCom > 0 .And. !Empty( _cCodSup )
		
		DBSelectArea('ZC7')
		ZC7->( RecLock( 'ZC7' , .T. ) )
		
		ZC7->ZC7_FILIAL := xFilial('ZC7')
		ZC7->ZC7_CHAVE  := _cCodSup + _cDtRef
		ZC7->ZC7_ITEM   := '03'
		ZC7->ZC7_CODPRD := _aDadZC7[_nI][04]
		ZC7->ZC7_QTDUM  := _aDadZC7[_nI][05]
		ZC7->ZC7_UM		:= _aDadZC7[_nI][06]
		ZC7->ZC7_QTDSUM := _aDadZC7[_nI][07]
		ZC7->ZC7_SUM	:= _aDadZC7[_nI][08]
		ZC7->ZC7_VALTOT := _aDadZC7[_nI][09]
		ZC7->ZC7_DEVUM  := _aDadZC7[_nI][10]
		ZC7->ZC7_DEVSUM := _aDadZC7[_nI][11]
		ZC7->ZC7_VALDEV := _aDadZC7[_nI][12]
		ZC7->ZC7_QTDLUM := _aDadZC7[_nI][13]
		ZC7->ZC7_QTDLSU := _aDadZC7[_nI][14]
		ZC7->ZC7_VALLIQ := _aDadZC7[_nI][15]
		ZC7->ZC7_PERCMS := _nPerCom
		ZC7->ZC7_VALCMS := Round( _aDadZC7[_nI][15] * ( _nPerCom / 100 ) , 2 )
		
		ZC7->( MSUnLock() )
		
	EndIf
	
	//================================================================================
	// Verifica se o produto atual gera comissão para o supervisor
	//================================================================================
	_nPerCom := 0
	_cCodSup := ''
	
	_cQuery := " SELECT "
	_cQuery += "     ZAE.ZAE_CODSUI, "
	_cQuery += "     ZAE.ZAE_COMIS4 "
	_cQuery += " FROM "+ RetSqlName('ZAE') +" ZAE "
	_cQuery += " WHERE "
	_cQuery += "     ZAE.D_E_L_E_T_ = ' ' "
	_cQuery += " AND ZAE.ZAE_VEND   = '"+ _aDadZC7[_nI][01] +"' "
	_cQuery += " AND ZAE.ZAE_PROD   = '"+ _aDadZC7[_nI][04] +"' "
	_cQuery += " AND ZAE.ZAE_GRPVEN = ' ' "
	_cQuery += " AND ZAE.ZAE_CLI    = ' ' "
	_cQuery += " AND ZAE.ZAE_LOJA   = ' ' "
	
	If Select(_cAlias) > 0
		(_cAlias)->( DBCloseArea() )
	EndIf
	
	DBUseArea( .T. , "TOPCONN" , TcGenQry( ,, _cQuery ) , _cAlias , .T. , .F. )
	
	DBSelectArea(_cAlias)
	(_cAlias)->( DBGoTop() )
	If (_cAlias)->( !Eof() )
		_cCodSup	:= (_cAlias)->ZAE_CODSUI
		_nPerCom	:= (_cAlias)->ZAE_COMIS4
	EndIf
	
	(_cAlias)->( DBCloseArea() )
	
	//================================================================================
	// Processa os descontos para o supervisor referente ao vendedor atual
	//================================================================================
	If _nPerCom > 0 .And. !Empty( _cCodSup )
		
		DBSelectArea('ZC7')
		ZC7->( RecLock( 'ZC7' , .T. ) )
		
		ZC7->ZC7_FILIAL := xFilial('ZC7')
		ZC7->ZC7_CHAVE  := _cCodSup + _cDtRef
		ZC7->ZC7_ITEM   := '03'
		ZC7->ZC7_CODPRD := _aDadZC7[_nI][04]
		ZC7->ZC7_QTDUM  := _aDadZC7[_nI][05]
		ZC7->ZC7_UM		:= _aDadZC7[_nI][06]
		ZC7->ZC7_QTDSUM := _aDadZC7[_nI][07]
		ZC7->ZC7_SUM	:= _aDadZC7[_nI][08]
		ZC7->ZC7_VALTOT := _aDadZC7[_nI][09]
		ZC7->ZC7_DEVUM  := _aDadZC7[_nI][10]
		ZC7->ZC7_DEVSUM := _aDadZC7[_nI][11]
		ZC7->ZC7_VALDEV := _aDadZC7[_nI][12]
		ZC7->ZC7_QTDLUM := _aDadZC7[_nI][13]
		ZC7->ZC7_QTDLSU := _aDadZC7[_nI][14]
		ZC7->ZC7_VALLIQ := _aDadZC7[_nI][15]
		ZC7->ZC7_PERCMS := _nPerCom
		ZC7->ZC7_VALCMS := Round( _aDadZC7[_nI][15] * ( _nPerCom / 100 ) , 2 )
		
		ZC7->( MSUnLock() )
		
	EndIf
	

Next _nI

Return

/*
===============================================================================================================================
Programa----------: MOMS015DEV
Autor-------------: Alexandre Villar
Data da Criacao---: 06/10/2014
===============================================================================================================================
Descrição---------: Rotina de identificação e cálculo das devoluções
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/

Static Function MOMS015DEV( _cCodVen , _cCodPrd , _cDtIni , _cDtFim , _nQtdDev1 , _nQtdDev2 , _nValDev )

Local _cQuery := ''
Local _cAlias := GetNextAlias()

_cQuery := " SELECT "
_cQuery += "     SD1.D1_COD						, "
_cQuery += "     SUM( SD1.D1_QUANT ) AS QTDPUM	, "
_cQuery += "     SD1.D1_UM						, "
_cQuery += "     SUM( SD1.D1_QTSEGUM ) AS QTDSUM, "
_cQuery += "     SD1.D1_SEGUM					, "
_cQuery += "     SUM( SD1.D1_TOTAL + SD1.D1_ICMSRET ) AS VALTOT	  "
_cQuery += " FROM "+ RetSqlName('SF1') +" SF1 "
_cQuery += " INNER JOIN "+ RetSqlName('SD1') +" SD1 ON SD1.D1_FILIAL = SF1.F1_FILIAL AND SD1.D1_DOC = SF1.F1_DOC AND SD1.D1_SERIE = SF1.F1_SERIE "
_cQuery += " INNER JOIN "+ RetSqlName('SB1') +" SB1 ON SD1.D1_COD = SB1.B1_COD "
_cQuery += " INNER JOIN "+ RetSqlName('SF2') +" SF2 ON SF2.F2_FILIAL = SD1.D1_FILIAL AND SF2.F2_DOC = SD1.D1_NFORI AND SF2.F2_SERIE	= SD1.D1_SERIORI AND SF2.F2_CLIENTE = SF1.F1_FORNECE AND SF2.F2_LOJA = SF1.F1_LOJA "
_cQuery += " INNER JOIN "+ RetSqlName('SD2') +" SD2 ON SD2.D2_DOC = SF2.F2_DOC AND SD2.D2_SERIE = SF2.F2_SERIE AND SD2.D2_FILIAL = SF2.F2_FILIAL AND SD2.D2_ITEM = SD1.D1_ITEMORI "
_cQuery += " INNER JOIN "+ RetSqlName('ZAY') +" ZAY ON ZAY.ZAY_CF = SD2.D2_CF "
_cQuery += " WHERE "
_cQuery += "     SF1.D_E_L_E_T_     = ' ' "
_cQuery += " AND SD1.D_E_L_E_T_     = ' ' "
_cQuery += " AND SB1.D_E_L_E_T_     = ' ' "
_cQuery += " AND SF2.D_E_L_E_T_     = ' ' "
_cQuery += " AND SD2.D_E_L_E_T_     = ' ' "
_cQuery += " AND ZAY.D_E_L_E_T_     = ' ' "
_cQuery += " AND SF2.F2_EMISSAO     BETWEEN '"+ _cDtIni	+"' AND '"+ _cDtFim +"' "
_cQuery += " AND SB1.B1_TIPO		= 'PA' "
_cQuery += " AND ZAY.ZAY_TPOPER		= 'B' "
_cQuery += " AND SD1.D1_DTDIGIT		>= '"+ _cDtIni +"' "
_cQuery += " AND SF2.F2_VEND1       = '"+ _cCodVen +"' "
_cQuery += " AND SD1.D1_COD         = '"+ _cCodPrd +"' "
_cQuery += " GROUP BY SD1.D1_COD , SD1.D1_UM , SD1.D1_SEGUM "

If Select(_cAlias) > 0
	(_cAlias)->( DBCloseArea() )
EndIf

DBUseArea( .T. , "TOPCONN" , TcGenQry( ,, _cQuery ) , _cAlias , .T. , .F. )

DBSelectArea(_cAlias)
(_cAlias)->( DBGoTop() )
If (_cAlias)->( !Eof() )

    _nQtdDev1 := (_cAlias)->QTDPUM
    _nQtdDev2 := (_cAlias)->QTDSUM
    _nValDev  := (_cAlias)->VALTOT

Else

    _nQtdDev1 := 0
    _nQtdDev2 := 0
    _nValDev  := 0
	
EndIf

(_cAlias)->( DBCloseArea() )

Return

/*
===============================================================================================================================
Programa----------: MOMS015VE3
Autor-------------: Alexandre Villar
Data da Criacao---: 06/10/2014
===============================================================================================================================
Descrição---------: Rotina que retorna os títulos de Comissão x Bonificação da SE3 para o vendedor atual
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/

Static Function MOMS015VE3( _cCodVen , _cDtRef )

Local _aRet   := {}
Local _cQuery := ''
Local _cAlias := GetNextAlias()

_cQuery := " SELECT "
_cQuery += "     SE3.R_E_C_N_O_ "
_cQuery += " FROM "+ RetSqlName('SE3') +" SE3 "
_cQuery += " WHERE "
_cQuery += "     SE3.D_E_L_E_T_ = ' ' "
_cQuery += " AND SE3.E3_FILIAL  = '01' "
_cQuery += " AND SE3.E3_VEND    = '"+ _cCodVen +"' "
_cQuery += " AND SE3.E3_EMISSAO LIKE '"+ _cDtRef +"%' "
_cQuery += " AND SE3.E3_I_ORIGE = 'MOMS015' "

If Select(_cAlias) > 0
	(_cAlias)->( DBCloseArea() )
EndIf

DBUseArea( .T. , "TOPCONN" , TcGenQry( ,, _cQuery ) , _cAlias , .T. , .F. )

DBSelectArea(_cAlias)
(_cAlias)->( DBGoTop() )
While (_cAlias)->( !Eof() )

	aAdd( _aRet , (_cAlias)->R_E_C_N_O_ )
	
(_cAlias)->( DBSkip() )
EndDo

(_cAlias)->( DBCloseArea() )

Return( _aRet )

/*
===============================================================================================================================
Programa----------: MOMS015VLF
Autor-------------: Alexandre Villar
Data da Criacao---: 06/10/2014
===============================================================================================================================
Descrição---------: Rotina que verifica se já foi feito o fechamento para o período atual
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS015VLF()

Local _lRet		:= .F.
Local _cQuery	:= ''
Local _cAlias	:= GetNextAlias()

_cQuery := " SELECT COUNT(*) AS CONTADOR "
_cQuery += " FROM "+ RetSqlName('SE3') +" SE3 "
_cQuery += " WHERE "
_cQuery += "     D_E_L_E_T_ = ' ' "
_cQuery += " AND E3_EMISSAO BETWEEN '"+ SubStr( DToS( MonthSub( dDatabase , 1 ) ) , 1 , 6 ) +"01' AND '"+ SubStr( DToS( MonthSub( dDatabase , 1 ) ) , 1 , 6 ) +"31' "
_cQuery += " AND E3_I_FECH  = 'S' "

If Select(_cAlias) > 0

	(_cAlias)->( DBCloseArea() )

EndIf

DBUseArea( .T. , "TOPCONN" , TcGenQry( ,, _cQuery ) , _cAlias , .T. , .F. )

DBSelectArea(_cAlias)
(_cAlias)->( DBGoTop() )

If (_cAlias)->( !Eof() )

	_lRet := ( (_cAlias)->CONTADOR > 0 )

EndIf

(_cAlias)->( DBCloseArea() )

Return( _lRet )

/*
===============================================================================================================================
Programa----------: MOMS015DEL
Autor-------------: Alexandre Villar
Data da Criacao---: 06/10/2014
===============================================================================================================================
Descrição---------: Rotina que Processa a exclusão dos registros do período atual.
===============================================================================================================================
Parametros--------: _cDTini - data inicial do processamento
					_cDTref - data de referência do processamento
					oproc - objeto da barra de processamento
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS015DEL( _cDtIni , _cDtRef )

Local _cAlias1	:= GetNextAlias()
Local _cQuery	:= ''
Local _aRegSE3	:= {}
Local _nI		:= 0

//================================================================================
// Processa a exclusão de todos os registros do período
//================================================================================
_cQuery := " SELECT ZC6.R_E_C_N_O_ AS REGZC6 FROM "+ RetSqlName('ZC6') +" ZC6 WHERE ZC6.D_E_L_E_T_ = ' ' AND ZC6.ZC6_ANOMES = '"+ _cDtRef +"' ORDER BY 1 "

If Select(_cAlias1) > 0
	(_cAlias1)->( DBCloseArea() )
EndIf

DBUseArea( .T. , "TOPCONN" , TcGenQry( ,, _cQuery ) , _cAlias1 , .T. , .F. )

DBSelectArea(_cAlias1)
(_cAlias1)->( DBGoTop() )
While (_cAlias1)->( !Eof() )
	
	DBSelectArea('ZC6')
	ZC6->( DBGoTo( (_cAlias1)->REGZC6 ) )
	
	//================================================================================
	// Apaga os registros de Comissão se existirem para gerar novamente
	//================================================================================
	_aRegSE3 := MOMS015VE3( ZC6->ZC6_CODVEN , _cDtRef )
	
	If !Empty( _aRegSE3 )
		
		For _nI := 1 To Len( _aRegSE3 )
			
			DBSelectArea('SE3')
			SE3->( DBGoTo( _aRegSE3[_nI] ) )
			SE3->( RecLock( 'SE3' , .F. ) )
			SE3->( DBDelete() )
			SE3->( MSUnLock() )
		
		Next _nI
		
	EndIf
	
	//================================================================================
	// Apaga os registros de Histórico se existirem para gerar novamente
	//================================================================================
	DBSelectArea('ZC7')
	ZC7->( DBSetOrder(1) )
	If ZC7->( DBSeek( xFilial('ZC7') + ZC6->( ZC6_CODVEN + ZC6_ANOMES ) ) )
		
		While ZC7->(!Eof()) .And. ZC7->( ZC7_FILIAL + ZC7_CHAVE ) == xFilial('ZC7') + ZC6->( ZC6_CODVEN + ZC6_ANOMES )
			
			ZC7->( RecLock( 'ZC7' , .F. ) )
			ZC7->( DBDelete() )
			ZC7->( MSUnLock() )
			
		ZC7->( DBSkip() )
		EndDo
		
	EndIf
	
	ZC6->( RecLock( 'ZC6' , .F. ) )
	ZC6->( DBDelete() )
	ZC6->( MSUnLock() )

(_cAlias1)->( DBSkip() )
EndDo

(_cAlias1)->( DBCloseArea() )
	
Return

/*
===============================================================================================================================
Programa----------: MOMS015SUP
Autor-------------: Alexandre Villar
Data da Criacao---: 14/10/2014
===============================================================================================================================
Descrição---------: Rotina que Processa a identificação e contabilização dos registros para geração do SE3
===============================================================================================================================
Parametros--------: _cDtref - Data de referência
					oproc - objeto da barra de processamento
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS015SUP( _cDtRef, oproc )

Local _cAlias	:= GetNextAlias()
Local _cQuery	:= ''
Local _cChave	:= ''
Local _cCodVen	:= ''
Local _nTotReg	:= 0
Local _nRegAtu	:= 0
Local _nValTot	:= 0
Local _nValDev	:= 0
Local _nValLiq	:= 0
Local _nValCms	:= 0
Local _nPerCms	:= 0

_cQuery := " SELECT * "
_cQuery += " FROM "+ RetSqlName('ZC7') +" ZC7 "
_cQuery += " WHERE "
_cQuery += "     ZC7.D_E_L_E_T_ = ' ' "
_cQuery += " AND SubStr( ZC7_CHAVE , 7 , 6 ) = '"+ _cDtRef +"' "
_cQuery += " AND NOT EXISTS ( SELECT * FROM "+ RetSqlName('ZC6') +" ZC6 "
_cQuery +=                  " WHERE "
_cQuery +=                  "     ZC6.D_E_L_E_T_ = ' ' "
_cQuery +=                  " AND ZC6.ZC6_CODVEN = SubStr( ZC7.ZC7_CHAVE , 1 , 6 ) "
_cQuery +=                  " AND ZC6.ZC6_ANOMES = SubStr( ZC7.ZC7_CHAVE , 7 , 6 ) ) "
_cQuery += " ORDER BY ZC7.ZC7_CHAVE , ZC7_ITEM , ZC7.ZC7_CODPRD "

If Select(_cAlias) > 0
	(_cAlias)->( DBCloseArea() )
EndIf

DBUseArea( .T. , "TOPCONN" , TcGenQry( ,, _cQuery ) , _cAlias , .T. , .F. )

DBSelectArea(_cAlias)
(_cAlias)->( DBGoTop() )
(_cAlias)->( DBEval( {|| _nTotReg++ } ) )
(_cAlias)->( DBGoTop() )

If _nTotReg > 0

	While (_cAlias)->( !Eof() )
		
		_cChave		:= (_cAlias)->( ZC7_FILIAL + ZC7_CHAVE )
		_cCodVen	:= SubStr( (_cAlias)->ZC7_CHAVE , 1 , 6 )
		_nValTot	:= 0
		_nValDev	:= 0
		_nValLiq	:= 0
		_nValCms	:= 0
		_nPerCms	:= 0
		
		While (_cAlias)->( ZC7_FILIAL + ZC7_CHAVE ) == _cChave
			
			_nRegAtu++
			
			oproc:cCaption := 'Verificando registros ['+ StrZero(_nRegAtu,9) +'] de ['+ StrZero(_nTotReg,9) +']'
			ProcessMessages()
			
			_nValTot += (_cAlias)->ZC7_VALTOT
			_nValDev += (_cAlias)->ZC7_VALDEV
			_nValLiq += (_cAlias)->ZC7_VALLIQ
			_nValCms += (_cAlias)->ZC7_VALCMS
			
		(_cAlias)->( DBSkip() )
		EndDo
		
		_nPerCms := Round( ( _nValCms / _nValLiq ) * 100 , 4 )
		
		DBSelectArea('ZC6')
		ZC6->( RecLock( 'ZC6' , .T. ) )
		
		ZC6->ZC6_FILIAL	:= xFilial('ZC6')
		ZC6->ZC6_ANOMES	:= _cDtRef
		ZC6->ZC6_CODVEN	:= _cCodVen
		ZC6->ZC6_VALOR	:= _nValTot
		ZC6->ZC6_VALDEV	:= _nValDev
		ZC6->ZC6_VALLIQ	:= _nValLiq
		ZC6->ZC6_PERCOM	:= _nPerCms
		
		ZC6->( MSUnLock() )
		
		If _nValCms > 0
			
			SE3->( RecLock( 'SE3' , .T. ) )
			
			SE3->E3_FILIAL 	:= '01'
			SE3->E3_VEND   	:= _cCodVen
			SE3->E3_EMISSAO := LastDay( SToD( _cDtRef + '01' ) )
			SE3->E3_DATA    := LastDay( SToD( _cDtRef + '01' ) )
			SE3->E3_BASE    := _nValLiq
			SE3->E3_PORC    := _nPerCms
			SE3->E3_COMIS   := ( _nValCms * -1 )
			SE3->E3_I_ORIGE := 'MOMS015'
			
			SE3->( MSUnLock() )
			
		EndIf
		
	EndDo
	
EndIf

Return

/*
===============================================================================================================================
Programa----------: MOMS015D
Autor-------------: Alexandre Villar
Data da Criacao---: 14/10/2014
===============================================================================================================================
Descrição---------: Rotina que detalha a composição de cada linha de cálculo gerada.
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS015D()

//================================================================================
// A tela terá 3 níveis, o primeiro estático com os dados do vendedor, o segundo
// com os dados sintéticos de cada período e o terceiro com o detalhamento da
// composição
//================================================================================
Local oDlg			:= Nil
Local oLbxCAB		:= Nil
Local oLbxHIS		:= Nil
Local aPosObj   	:= {}
Local aObjects  	:= {}
Local aSize     	:= MsAdvSize()
Local bSelDados		:= {|| FWMsgRun(,{|lEnd| MOMS015I( @oLbxCAB ) }, "Aguarde...", "Selecionando dados..." ) }
Local bMontaHIS		:= {|| IIf( !Empty(oLbxCAB:aArray) , MOMS015H( @oLbxHIS , oLbxCAB:aArray[oLbxCAB:nAt][07] ) , ) }

Local oBar			:= Nil
Local aBtn 	    	:= Array(02)
Local oBold			:= Nil
Local oScrPanel		:= Nil
Local aCabLbxCAB	:= {	"Período"				,; //01
							"Valor Total"			,; //02
							"Valor Dev."			,; //03
							"Valor Líq."			,; //04
							"% Comissão"			,; //05
							'Valor Comiss.'			 } //06

Private	nDvPosAnt	:= 0
Private	cCadastro	:= 'Consulta detalhada dos cálculos: Comissão x Bonificação'

aAdd( aObjects, { 100, 025, .T. , .F. , .T. } )
aAdd( aObjects, { 100, 100, .T. , .F. } )
aAdd( aObjects, { 100, 050, .T. , .T. } )

aInfo   := { aSize[ 1 ], aSize[ 2 ], aSize[ 3 ], aSize[ 4 ], 3, 2 }
aPosObj := MsObjSize( aInfo, aObjects )

DEFINE FONT oBold NAME "Arial" SIZE 0, -12 BOLD

DEFINE MSDIALOG oDlg TITLE cCadastro From aSize[7],00 to aSize[6],aSize[5] Of oMainWnd Pixel

	aPosObj[01][01] += 12
	aPosObj[02][01] += 10
	aPosObj[02][03] += 10
	aPosObj[03][01] += 10
	aPosObj[03][03] += 10
	
	//================================================================================
	// Parte 01 - Vendedor
	//================================================================================
	@ aPosObj[01][01],aPosObj[01][02] MSPANEL oScrPanel PROMPT "" SIZE aPosObj[01][03],aPosObj[01][04] OF oDlg LOWERED

	@ 004 , 004 Say "Vendedor:"	  													SIZE 025,07 OF oScrPanel PIXEL
	@ 012 , 004 Say ZC6->ZC6_CODVEN												 	SIZE 060,09 OF oScrPanel PIXEL FONT oBold COLOR CLR_BLUE
    
	_cNomVen := Capital( AllTrim( Posicione('SA3',1,xFilial('SA3')+ZC6->ZC6_CODVEN,'A3_NOME') ) )
	
	@ 004 , 055 Say "Nome:"															SIZE 165,07 OF oScrPanel PIXEL
	@ 012 , 055 Say _cNomVen														SIZE 165,09 OF oScrPanel PIXEL FONT oBold COLOR CLR_BLUE
	
	//================================================================================
	// Parte 02 - Resumo dos períodos calculados
	//================================================================================
	@aPosObj[02][01],aPosObj[02][02] To aPosObj[02][03],aPosObj[02][04] LABEL "Períodos processados:" COLOR CLR_HBLUE OF oDlg PIXEL
	
	//================================================================================
	// ListBox dos dados dos períodos calculados
	//================================================================================
	@aPosObj[02][01]+7,aPosObj[02][02]+4 	Listbox oLbxCAB Fields	;
											HEADER 	""		 		;
											On DbLCLICK ( Nil )		;
											Size aPosObj[02][04]-10,( aPosObj[02][03] - aPosObj[02][01] ) - 10 Of oDlg Pixel
	
	oLbxCAB:AHeaders	:= aClone(aCabLbxCAB)
	oLbxCAB:bChange		:= { || Eval(bMontaHIS) }
	
	Eval(bSelDados)
	
	//================================================================================
	// Parte 03 - Dados da composição dos cálculos
	//================================================================================
	@aPosObj[03][01],aPosObj[03][02] To aPosObj[03][03],aPosObj[03][04] LABEL "Histórico das alterações:" COLOR CLR_HBLUE OF oDlg PIXEL
      
	//================================================================================
	// ListBox com Itens da composição dos cálculos
	//================================================================================
	@aPosObj[03][01]+7,aPosObj[03][02]+4 	Listbox oLbxHIS Fields	;
											HEADER 	""		 		;
											On DbLCLICK ( Nil )		;
											Size aPosObj[03][04]-10,( aPosObj[03][03] - aPosObj[03][01] ) - 10 Of oDlg Pixel
	
	oLbxHIS:AHeaders := aClone(aCabLbxHIS)
	
	//================================================================================
	// Monta os Botoes da Barra Superior
	//================================================================================
	DEFINE BUTTONBAR oBar SIZE 25,25 3D OF oDlg
	
	DEFINE BUTTON aBtn[01] RESOURCE PmsBExcel()[1] OF oBar GROUP ACTION DlgToExcel({{"ARRAY","",oLbxCAB:AHeaders,oLbxCAB:aArray}})	TOOLTIP "Exportar para Planilha..."
	aBtn[01]:cTitle := ""
	
	DEFINE BUTTON aBtn[02] RESOURCE "FINAL" 		OF oBar GROUP ACTION oDlg:End() 												TOOLTIP "Sair da Tela..."
	aBtn[02]:cTitle := ""
	
	oDlg:lMaximized := .T.
	
ACTIVATE MSDIALOG oDlg CENTERED ON INIT IIf( Empty(oLbxCAB:aArray) , ( Aviso( 'Atenção!' , "O Pedido ["+ SC5->C5_FILIAL +"/"+ SC5->C5_NUM +"] não possui histórico de alterações." , {'Fechar'} , 2 ) , oDlg:End() ) , )

Return

/*
===============================================================================================================================
Programa----------: MOMS015I
Autor-------------: Alexandre Villar
Data da Criacao---: 23/04/2014
===============================================================================================================================
Descrição---------: Monta a estrutura de dados da consulta detalhada do histórico
===============================================================================================================================
Parametros--------: olbxaux - objeto de dados da tela
					oproc - objeto da barra de processamento
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS015I( oLbxAux, oproc )

Local _aLbxAux	:= {}

Local _cQuery 	:= ""
Local _cAliAux	:= GetNextAlias()

Local nTotReg   := 0

_cQuery := " SELECT * "
_cQuery += " FROM "+ RetSqlName('ZC6') +" ZC6 "
_cQuery += " WHERE "
_cQuery += "     ZC6.D_E_L_E_T_	= ' ' "
_cQuery += " AND ZC6.ZC6_CODVEN	= '"+ ZC6->ZC6_CODVEN +"' "
_cQuery += " ORDER BY ZC6.ZC6_ANOMES "

_cQuery	:= ChangeQuery(_cQuery)

If Select(_cAliAux) > 0
	(_cAliAux)->( DBCloseArea() )
EndIf

DBUseArea( .T. , "TOPCONN" , TCGenQry(,,_cQuery) , _cAliAux , .F. , .T. )

DBSelectArea(_cAliAux)
(_cAliAux)->( DBGoTop() )
(_cAliAux)->( DBEval( { || nTotReg++ } ) )
(_cAliAux)->( DBGoTop() )

While (_cAliAux)->( !Eof() )

	aAdd( _aLbxAux , {	SubStr((_cAliAux)->ZC6_ANOMES,5,2)+'/'+SubStr((_cAliAux)->ZC6_ANOMES,1,4)	 						,; //01
						Transform( (_cAliAux)->ZC6_VALOR										, '@E 999,999,999.99'	)	,; //02
						Transform( (_cAliAux)->ZC6_VALDEV										, '@E 999,999,999.99'	)	,; //03
						Transform( (_cAliAux)->ZC6_VALLIQ										, '@E 999,999,999.99'	)	,; //04
						Transform( (_cAliAux)->ZC6_PERCOM										, '@E 9,999.9999'		)	,; //05
						Transform( ( (_cAliAux)->ZC6_VALLIQ * ((_cAliAux)->ZC6_PERCOM/100) )	, '@E 999,999,999.99'	)	,; //06
						ZC6->ZC6_CODVEN + ZC6->ZC6_ANOMES																	}) //07

(_cAliAux)->( DBSkip() )
EndDo

(_cAliAux)->( DBCloseArea() )

If Len(_aLbxAux) > 0 .And. ValType(oLbxAux) == "O"

	oLbxAux:SetArray(_aLbxAux)
	
	oLbxAux:bLine := {|| {	_aLbxAux[oLbxAux:nAt][01]	,; // 01
							_aLbxAux[oLbxAux:nAt][02]	,; // 02
							_aLbxAux[oLbxAux:nAt][03]	,; // 03
							_aLbxAux[oLbxAux:nAt][04]	,; // 04
							_aLbxAux[oLbxAux:nAt][05]	,; // 05
							_aLbxAux[oLbxAux:nAt][06]	,; // 06
							_aLbxAux[oLbxAux:nAt][07]	}} // 07
	
	oLbxAux:Refresh()

EndIf

Return

/*
===============================================================================================================================
Programa----------: MOMS015H
Autor-------------: Alexandre Villar
Data da Criacao---: 23/04/2014
===============================================================================================================================
Descrição---------: Recupera os dados dos itens do histórico
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/

Static Function MOMS015H( oLbxAux , _cChave )

Local _cQuery	:= ""
Local _cAliAux	:= GetNextAlias()
Local _aLbxAux	:= {}
Local _nTotReg	:= 0
Local _nCont	:= 0

_cQuery	:= " SELECT * "
_cQuery	+= " FROM "+ RetSqlName('ZC7') +" ZC7 "
_cQuery	+= " WHERE "
_cQuery	+= "     ZC7.D_E_L_E_T_	= ' ' "
_cQuery	+= " AND ZC7.ZC7_CHAVE	= '"+ _cChave +"' "
_cQuery	+= " ORDER BY ZC7.ZC7_CHAVE , ZC7.ZC7_CODPRD "

_cQuery	:= ChangeQuery(_cQuery)

If Select(_cAliAux) > 0
	(_cAliAux)->( DBCloseArea() )
EndIf

DBUseArea( .T. , "TOPCONN" , TCGenQry(,,_cQuery) , _cAliAux , .F. , .T. )

DBSelectArea(_cAliAux)
(_cAliAux)->( DBGoTop() )
(_cAliAux)->( DBEval( {|| _nTotReg++ } ) )
(_cAliAux)->( DBGoTop() )

While !(_cAliAux)->( Eof() )
		
		aAdd( _aLbxAux , {	(_cAliAux)->ZC7_CODPRD							 								,; //01
							AllTrim( Posicione('SB1',1,xFilial('SB1')+(_cAliAux)->ZC7_CODPRD,'B1_DESC') )	,; //02
							(_cAliAux)->ZC7_QTDUM															,; //03
							(_cAliAux)->ZC7_UM																,; //04
							(_cAliAux)->ZC7_QTDSUM															,; //05
							(_cAliAux)->ZC7_SUM																,; //06
							Transform( (_cAliAux)->ZC7_VALTOT , '@E 999,999,999.99'	)						,; //07
							(_cAliAux)->ZC7_DEVUM															,; //08
							(_cAliAux)->ZC7_DEVSUM															,; //09
							Transform( (_cAliAux)->ZC7_VALDEV , '@E 999,999,999.99'	)						,; //10
							(_cAliAux)->ZC7_QTDLUM															,; //11
							(_cAliAux)->ZC7_QTDLSU															,; //12
							Transform( (_cAliAux)->ZC7_VALLIQ , '@E 999,999,999.99'	)						,; //13
							Transform( (_cAliAux)->ZC7_PERCMS , '@E 9,999.9999'		)						,; //14
							Transform( (_cAliAux)->ZC7_VALCMS , '@E 999,999,999.99'	)						}) //15

	_nCont++
	oproc:cCaption := ("Montando estrutura "+StrZero(_nCont,6)+" de "+StrZero(_nTotReg,6) )
	ProcessMessages()
	(_cAliAux)->(DBSkip())

EndDo

(_cAliAux)->(DBCloseArea())

If	Len(_aLbxAux) > 0 .And. ValType(oLbxAux) == "O"
                     
	oLbxAux:SetArray(_aLbxAux)
	oLbxAux:bLine:={||{	_aLbxAux[oLbxAux:nAt][01] ,; //01
						_aLbxAux[oLbxAux:nAt][02] ,; //02
						_aLbxAux[oLbxAux:nAt][03] ,; //03
						_aLbxAux[oLbxAux:nAt][04] ,; //04
						_aLbxAux[oLbxAux:nAt][05] ,; //05
						_aLbxAux[oLbxAux:nAt][06] ,; //06
						_aLbxAux[oLbxAux:nAt][07] ,; //07
						_aLbxAux[oLbxAux:nAt][08] ,; //08
						_aLbxAux[oLbxAux:nAt][09] ,; //09
						_aLbxAux[oLbxAux:nAt][10] ,; //10
						_aLbxAux[oLbxAux:nAt][11] ,; //11
						_aLbxAux[oLbxAux:nAt][12] ,; //12
						_aLbxAux[oLbxAux:nAt][13] ,; //13
						_aLbxAux[oLbxAux:nAt][14] ,; //14
						_aLbxAux[oLbxAux:nAt][15] }} //15

	oLbxAux:Refresh()

EndIf

Return
