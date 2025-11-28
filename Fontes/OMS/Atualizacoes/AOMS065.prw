/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
 Autor            |    Data    |                              Motivo                      										 
-------------------------------------------------------------------------------------------------------------------------------
 Alexandre Villar | 22/12/2015 | Tratativa na cláusula "ORDER BY" para remover a referência numérica. Chamado 13062           
-------------------------------------------------------------------------------------------------------------------------------
 Julio Paz        | 24/06/2019 | Ajustes de fontes para o novo servidor Totvs Lobo Guará. Chamado 28886
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges      | 14/10/2019 | Removidos os Warning na compilação da release 12.1.25. Chamado 28346
===============================================================================================================================
*/

//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================
#Include "TOTVS.ch"
#Include 'ApWizard.Ch'
#Include 'FWMVCDEF.ch'

/*
===============================================================================================================================
Programa--------: AOMS065
Autor-----------: Alexandre Villar
Data da Criacao-: 15/09/2014
===============================================================================================================================
Descrição-------: Rotina pra cálculo e cadastro de estimativas de produção
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function AOMS065()


Private cTitulo	:= 'Estimativa de Produção'
Private aRotina	:= MenuDef()

//================================================================================
// Instancia a classe do Browse
//================================================================================
oBrowse := FWMBrowse():New()

//================================================================================
// Definicao da tabela do Browse
//================================================================================
oBrowse:SetAlias("ZC3")

//================================================================================
// Definicao do titulo do Browse
//================================================================================
oBrowse:SetDescription( 'Estimativa de Produção' )
oBrowse:DisableDetails()

oBrowse:Activate()

Return

/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Alexandre Villar
Data da Criacao---: 15/09/2014
===============================================================================================================================
Descrição---------: Rotina de verificação do SX2 para não dar Erro no MVC
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/

Static Function MenuDef()

Local _aRotina := {}

ADD OPTION _aRotina Title 'Visualizar'	Action 'VIEWDEF.AOMS065'	OPERATION 2 ACCESS 0
ADD OPTION _aRotina Title 'Incluir'		Action 'U_AOMS65I'			OPERATION 3 ACCESS 0
ADD OPTION _aRotina Title 'Alterar'		Action 'VIEWDEF.AOMS065'	OPERATION 4 ACCESS 0
ADD OPTION _aRotina Title 'Excluir'		Action 'VIEWDEF.AOMS065'	OPERATION 5 ACCESS 0

Return( _aRotina )

/*
===============================================================================================================================
Programa----------: AOMS65I
Autor-------------: Alexandre Villar
Data da Criacao---: 15/09/2014
===============================================================================================================================
Descrição---------: Rotina de inclusão de novas estimativas
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS65I()

Local _oWizard	:= Nil
Local _aCpsZC3	:= { 'ZC3_UNIPRD' , 'ZC3_DESCRI' , 'ZC3_PERIOD' , 'NOUSER' }
Local _cAlias	:= 'ZC3'
Local _nReg		:= 0
Local _nOpc		:= 3
Local _lGravaOK	:= .F.
Local _bNext	:= {|nPanel| AOMS065NXT( nPanel ) }
Local _bFinish	:= {|| _lGravaOK := .T. }
Local _aRetPar	:= {}
Local _aParAux	:= {}
Local nI		:= 0

If !AOMS065VUS()
	Return
EndIf

//================================================================================
// Desativa a Flag de Cópia quando não For Replicação de Propostas
//================================================================================
_lOpcCopy := .F.

//================================================================================
// Montagem do Wizard
//================================================================================
DEFINE	WIZARD 	_oWizard TITLE "Italac"																							;
       	HEADER 	"Estimativas de Produção" 																						;
       	MESSAGE	"Inclusão de Estimativas"			 																			;
       	TEXT 	"Esta rotina tem o objetivo de iniciar o processo de cadastramento de estimativas para a produção das"	+CRLF+	;
       			"Unidades. Nessa etapa é necessário informar o período e a forma de cadastro para prosseguir"			+CRLF	;
       	Next	{||.T.} 																										;
       	Finish 	{||.F.} 																										;
       	PANEL

	//================================================================================
	// Wizard 02: Tela para Preenchimento dos Parâmetros Iniciais
	//================================================================================
	CREATE	PANEL 	_oWizard									 			;
          	HEADER 	"Informações"											;
          	MESSAGE "Informe os campos para início do processamento..."		;
          	BACK 	{|| .T. }												;
          	Next 	{|| Eval( _bNext , 2 ) }								;
          	Finish 	{|| .F. }												;
          	PANEL
	
	DBSelectArea('ZC3')
	RegToMemory( _cAlias , _nOpc == 3 )
	
	oEncPSP	:= MsMGet():New( _cAlias , _nReg , _nOpc ,,,, _aCpsZC3 ,,,,,,, _oWizard:GetPanel(2) ,, .T. ,,, .T. )
	oEncPSP:oBox:Align := CONTROL_ALIGN_ALLCLIENT
   
	//================================================================================
	// Wizard 03: Tela de confirmação
	//================================================================================
	CREATE	PANEL 	_oWizard												;
	        HEADER 	'Confirmar o processamento'								;
	        MESSAGE ''														;
	        BACK 	{|| .T. } 												;
	        Finish 	{|| Eval( _bFinish ) } 									;
	        PANEL
	
	//================================================================================
	// Selecao da opcao de continuidade
	//================================================================================
	aAdd( _aParAux , { 3 , 'Selecione uma opção para concluir' , 1 , { 'Processamento automático' , 'Inclusão manual'} , 160 , "" , .F. } )
	
	_aRetPar := {}
	
	For nI := 1 To Len( _aParAux )
		aAdd( _aRetPar , _aParAux[nI][3] )
	Next nI
	
	ParamBox( _aParAux , 'Parâmetros' , @_aRetPar ,,, .T. ,,, _oWizard:GetPanel(3) )

_oWizard:Activate()

If	_lGravaOK
	
	LjMsgRun( 'Iniciando o processamento...' , 'Aguarde!' , {|| AOMS065PRC( _aRetPar , M->ZC3_UNIPRD , M->ZC3_PERIOD ) } , .T. )
	
EndIf

Return

/*
===============================================================================================================================
Programa----------: AOMS065PRC
Autor-------------: Alexandre Villar
Data da Criacao---: 15/09/2014
===============================================================================================================================
Descrição---------: Rotina de processamento de inclusão de novas estimativas
===============================================================================================================================
Parametros--------: _aRetPar 
                    _cCodUni 
					_cPeriod
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS065PRC( _aRetPar , _cCodUni , _cPeriod )

Local _lExeAut	:= .T.
Local _lAtual	:= .F.
Local _lPriReg	:= .T.
Local _cQuery	:= ''
Local _cAlias	:= GetNextAlias()
Local _cDtRef	:= ''
Local _nTotReg	:= 0

If Empty( _cPeriod )
	_cPeriod := SubStr( DToS( Date() ) , 1 , 6 )
EndIf

_cDtRef := SubStr( DToS( MonthSub( SToD( _cPeriod + '01' ) , 1 ) ) , 1 , 6 )

If _aRetPar[01] == 1

	_cQuery := " SELECT "
	_cQuery += "     D3.D3_FILIAL 		AS FILIAL, "
	_cQuery += "     D3.D3_COD	 		AS PRODUTO, "
	_cQuery += "     B1.B1_I_DESCD		AS DESCPRODUT, "
	_cQuery += "     SUM(D3.D3_QUANT)	AS QUANT, "
	_cQuery += "     D3.D3_UM			AS UM, "
	_cQuery += "     SUM(D3.D3_QTSEGUM)	AS QTSEGUM, "
	_cQuery += "     D3.D3_SEGUM		AS SEGUM "
	_cQuery += " FROM "+ RetSqlName("SD3") +" D3 "
	_cQuery += " JOIN "+ RetSqlName("SB1") +" B1 "
	_cQuery += " ON  B1.B1_COD = D3.D3_COD "
	_cQuery += " WHERE "
	_cQuery += "     D3.D_E_L_E_T_ = ' ' "
	_cQuery += " AND B1.D_E_L_E_T_ = ' ' "
	_cQuery += " AND D3.D3_TIPO    = 'PA' "
	_cQuery += " AND B1.B1_I_WFUM  <> ' ' " 
	_cQuery += " AND D3.D3_TM      IN ( '001' , '003' ) "
	_cQuery += " AND D3.D3_ESTORNO <> 'S' "
	_cQuery += " AND SubStr( D3.D3_EMISSAO , 1 , 6 ) = '"+ _cDtRef +"' "
	
	If !Empty( _cCodUni )
	_cQuery += " AND D3.D3_FILIAL  = '"+ _cCodUni +"' "
	EndIf
	
	_cQuery += " GROUP BY D3.D3_FILIAL , D3.D3_COD , B1.B1_I_DESCD , D3.D3_UM , D3.D3_SEGUM "
	_cQuery += " ORDER BY D3.D3_FILIAL, D3.D3_COD "
	
	If Select(_cAlias) > 0
		(_cAlias)->( DBCloseArea() )
	EndIf
	
	DBUseArea( .T. , "TOPCONN" , TcGenQry( ,, _cQuery) , _cAlias , .T. , .F. )
	
	DBSelectArea(_cAlias)
	(_cAlias)->( DBGoTop() )
	(_cAlias)->( DBEval( {|| _nTotReg++ } ) )
	(_cAlias)->( DBGoTop() )
	
	If _nTotReg > 0
		
		While (_cAlias)->( !Eof() )
			
			DBSelectArea('ZC3')
			ZC3->( DBSetOrder(1) )
			If ZC3->( DBSeek( xFilial('ZC3') + (_cAlias)->FILIAL + _cPeriod + (_cAlias)->PRODUTO ) )
				
				If !_lAtual
					
					If _lExeAut .And. _lPriReg
						
						If Aviso( 'Atenção!' ,	'Já existem dados para o período informado, deseja atualizar os dados existentes?' , {'Sim','Não'} , 2 ) == 1
							
							_lAtual := .T.
							
						EndIf
						
						_lExeAut	:= .F.
						_lPriReg	:= .F.
						
					EndIf
					
				EndIf
				
				If _lAtual
					
					ZC3->( RecLock( 'ZC3' , .F. ) )
					ZC3->ZC3_QTDEST	:= (_cAlias)->QUANT
					ZC3->ZC3_QTDSUM	:= (_cAlias)->QTSEGUM
					ZC3->( MSUnLock() )
					
				EndIf
				
			Else
				
				ZC3->( RecLock( 'ZC3' , .T. ) )
					
					ZC3->ZC3_FILIAL	:= xFilial('ZC3')
					ZC3->ZC3_UNIPRD	:= (_cAlias)->FILIAL
					ZC3->ZC3_PERIOD	:= _cPeriod
					ZC3->ZC3_CODPRO	:= (_cAlias)->PRODUTO
					ZC3->ZC3_QTDEST	:= (_cAlias)->QUANT
					ZC3->ZC3_QTDSUM	:= (_cAlias)->QTSEGUM
					
				ZC3->( MSUnLock() )
				
			EndIf
			
			_lPriReg := .F.
			
		(_cAlias)->( DBSkip() )
		EndDo
		
	Else
		
		Aviso( 'Atenção' ,	'Não foram encontrados históricos de produção para gerar a estimativa automaticamente! '	+;
							'Para a configuração atual será necessário realizar o cadastro manualmente.'		, {'Ok'} )
	
	EndIf
    
	(_cAlias)->( DBCloseArea() )

Else
	
	FWExecView( 'Inclusão Manual' , 'AOMS065' , MODEL_OPERATION_INSERT ,, { || .T. } , { || .T. } ) 
	
EndIf

Return

Static Function AOMS065NXT( nPanel )

Local _lRet := .T.

Return( _lRet )

/*
===============================================================================================================================
Programa----------: ModelDef
Autor-------------: Alexandre Villar
Data da Criacao---: 15/09/2014
===============================================================================================================================
Descrição---------: Define o modelo de dados
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ModelDef()

//================================================================================
// Cria a estrutura a ser usada no Modelo de Dados
//================================================================================
Local oStruZC3P	:= FWFormStruct( 1 , 'ZC3' , { |cCampo| AOMS065CPO( "P" , cCampo ) } /*bAvalCampo*/,/*lViewUsado*/ )
Local oStruZC3F	:= FWFormStruct( 1 , 'ZC3' , { |cCampo| AOMS065CPO( "F" , cCampo ) } /*bAvalCampo*/,/*lViewUsado*/ )
Local oModel	:= Nil

//================================================================================
// Cria o objeto do Modelo de Dados
//================================================================================
oModel := MPFormModel():New( 'AOMS065M' )

//================================================================================
// Configura o Modelo para exibição
//================================================================================
oModel:SetDescription( 'Estimativa de Produção' )
oModel:AddFields( 'ZC3MASTER' ,, oStruZC3P )
oModel:AddGrid( 'ZC3DETAIL' , 'ZC3MASTER' , oStruZC3F )
oModel:SetPrimaryKey( { "ZC3_FILIAL" , "ZC3_UNIPRD" , "ZC3_PERIOD" , "ZC3_CODPRO" } )
oModel:SetRelation( "ZC3DETAIL" , { { "ZC3_FILIAL" , "xFilial('ZC3')" } , { "ZC3_UNIPRD" , "ZC3_UNIPRD" } , { "ZC3_PERIOD" , "ZC3_PERIOD" } } , ZC3->( IndexKey( 1 ) ) )
oModel:GetModel( "ZC3DETAIL" ):SetUniqueLine( { "ZC3_CODPRO" } )

//================================================================================
// Adiciona a descricao do Componente do Modelo de Dados
//================================================================================
oModel:GetModel( "ZC3MASTER" ):SetDescription( "Unidade" )
oModel:GetModel( "ZC3DETAIL" ):SetDescription( "Estimativas de Produção" )

//================================================================================
// Adiciona a validação inicial para as ações do modelo
//================================================================================
oModel:SetVldActivate( { |oModel| AOMS065VUS() } )

Return( oModel )

/*
===============================================================================================================================
Programa----------: ModelDef
Autor-------------: Alexandre Villar
Data da Criacao---: 15/09/2014
===============================================================================================================================
Descrição---------: Define o View de dados
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ViewDef()

Local oModel   	:= FWLoadModel( "AOMS065" )
Local oStruZC3P	:= FWFormStruct( 2 , "ZC3" , { |cCampo| AOMS065CPO( "P" , cCampo ) } )
Local oStruZC3F	:= FWFormStruct( 2 , "ZC3" , { |cCampo| AOMS065CPO( "F" , cCampo ) } )
Local oView		:= Nil

//================================================================================
// Cria o objeto de View
//================================================================================
oView := FWFormView():New()

//================================================================================
// Configura o Objeto da View para utilização
//================================================================================
oView:SetModel( oModel )

oView:AddField( "VIEW_ZC3P" , oStruZC3P , "ZC3MASTER" )
oView:AddGrid(  "VIEW_ZC3F" , oStruZC3F , "ZC3DETAIL" )

oView:CreateHorizontalBox( 'BOX0101' 	, 20 )
oView:CreateHorizontalBox( 'BOX0102' 	, 80 )

oView:SetOwnerView( "VIEW_ZC3P", "BOX0101" )
oView:SetOwnerView( "VIEW_ZC3F", "BOX0102" )

Return(oView)

/*
===============================================================================================================================
Programa----------: ModelDef
Autor-------------: Alexandre Villar
Data da Criacao---: 15/09/2014
===============================================================================================================================
Descrição---------: Define os campos de capa da tela de dados.
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS065CPO( cOrigem , cCampo )

Local lRet := AllTrim(cCampo) $ "ZC3_UNIPRD/ZC3_DESCRI/ZC3_PERIOD"

If	cOrigem == "F"
	lRet := !lRet
EndIf

Return(lRet)

/*
===============================================================================================================================
Programa----------: AOMS65GQ
Autor-------------: Alexandre Villar
Data da Criacao---: 15/09/2014
===============================================================================================================================
Descrição---------: Calcula as quantidades de acordo com o fator de conversão dos produtos.
===============================================================================================================================
Parametros--------: _nOpc    = Opção 
                    _cCodPro = Código do produto 
					_nQtdUM  = Quantidade a ser convertida
					_nQtdAt  = Quantidade a ser retornada caso a conversão seja zero.
===============================================================================================================================
Retorno-----------: _nRet = Quantidade convertida com base no fator de conversão.
===============================================================================================================================
*/
User Function AOMS65GQ( _nOpc , _cCodPro , _nQtdUM , _nQtdAt )

Local _nRet	:= 0

DBSelectArea('SB1')
SB1->( DBSetOrder(1) )
If SB1->( DBSeek( xFilial('SB1') + _cCodPro ) )
	
	If SB1->B1_TIPCONV == 'D'
		
		If _nOpc == 1
			_nRet := Round( _nQtdUM / SB1->B1_CONV , 2 )
		Else
			_nRet := Round( _nQtdUM * SB1->B1_CONV , 2 )
		EndIf
		
	Else
	    
	    If _nOpc == 1
			_nRet := Round( _nQtdUM * SB1->B1_CONV , 2 )
		Else
			_nRet := Round( _nQtdUM / SB1->B1_CONV , 2 )
		EndIf
	
	EndIf
	
EndIf

If _nRet == 0 .And. _nQtdAt <> 0
	_nRet := _nQtdAt
EndIf

Return( _nRet )

/*
===============================================================================================================================
Programa----------: AOMS065VUS
Autor-------------: Alexandre Villar
Data da Criacao---: 15/09/2014
===============================================================================================================================
Descrição---------: Valida se o usuário tem acesso a rotina.
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: _lRet = .T. acesso liberado
                            .F. Acesso bloqueado
===============================================================================================================================
*/
Static Function AOMS065VUS()

Local _lRet := U_ITVLDUSR( 6 )

If !_lRet
	Help( ,, "AOMS065" ,, "Usuário sem acesso às rotinas de 'Definição de Metas'." , 1 , 0 )
EndIf

Return( _lRet )

/*
===============================================================================================================================
Programa----------: AOMS65VP
Autor-------------: Alexandre Villar
Data da Criacao---: 15/09/2014
===============================================================================================================================
Descrição---------: Valida se já existe estimativa cadastrada para o período informado.
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: _lRet = .T. inclusão do novo período liberado
                            .F. inclusão do novo período bloqueado
===============================================================================================================================
*/
User Function AOMS65VP()

Local _oModel	:= FWModelActive()
Local _nOper	:= 0
Local _lRet		:= .T.

If ValType( _oModel ) == "O"
	_nOper := _oModel:GetOperation()
EndIf

If _nOper == MODEL_OPERATION_INSERT

	DBSelectArea('ZC3')
	ZC3->( DBSetOrder(1) )
	If ZC3->( DBSeek( xFilial('ZC3') + _oModel:GetValue('ZC3MASTER','ZC3_UNIPRD') + _oModel:GetValue('ZC3MASTER','ZC3_PERIOD') ) )
		
		Help( ,, "AOMS065" ,, "Já existem registros nesse período para a Unidade Atual!" , 1 , 0 )
		_lRet := .F.
		
	EndIf

EndIf

Return( _lRet )
