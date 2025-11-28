/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
       Autor      |    Data    |                                             Motivo                                           
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges      | 14/10/2019 | Removidos os Warning na compilação da release 12.1.25. Chamado 28346
===============================================================================================================================
*/

//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================
#Include "TOTVS.ch"
#Include 'FWMVCDef.ch'

/*
===============================================================================================================================
Programa----------: AOMS033
Autor-------------: Alexandre Villar
Data da Criacao---: 16/09/2015
===============================================================================================================================
Descrição---------: Rotina para cadastro das tabelas de Frete da Logística - Chamado 15505
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS033()

Local _oBrowse	:= Nil
Local _xAces01	:= U_ITAcsUsr( 'ZZL_CADFRT' , '1' )
Local _xAces02	:= U_ITAcsUsr( 'ZZL_CADFRT' , '2' )

//====================================================================================================
// Verifica acesso do usuário
//====================================================================================================
If ValType( _xAces01 ) == 'N' .And. _xAces01 == 0

	MessageBox( 'Usuário não está cadastrado na Gestão de Usuários do Configurador Italac!' , 'Atenção!' , 16 )
	Return

ElseIf !_xAces01 .And. !_xAces02

	MessageBox( 'Usuário sem acesso às rotinas de cadastros da tabela de Frete!'			, 'Atenção!' , 16 )
	Return

EndIf

//====================================================================================================
// Configura e inicializa a Classe do Browse
//====================================================================================================
_oBrowse := FWMBrowse():New()

_oBrowse:SetAlias('ZF0')
_oBrowse:SetMenuDef('AOMS033')
_oBrowse:SetDescription( 'Controle Logístico - Tabelas de Frete' )
_oBrowse:SetFilterDefault( ' ZF0->ZF0_STATUS <> "I" ' )

_oBrowse:AddLegend( "ZF0_STATUS == 'A'" , 'GREEN'	, 'Tabela Ativa'					)
_oBrowse:AddLegend( "ZF0_STATUS == 'P'" , 'YELLOW'	, 'Tabela Pendente'					)
_oBrowse:AddLegend( "ZF0_STATUS == 'B'" , 'BLACK'	, 'Tabela Bloqueada'				)
_oBrowse:AddLegend( "ZF0_STATUS == 'E'" , 'ORANGE'	, 'Tabela Em Processo de Aprovação'	)

_oBrowse:Activate()

Return

/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Alexandre Villar
Data da Criacao---: 16/09/2015
===============================================================================================================================
Descrição---------: Rotina para configuração do menu de acesso da rotina
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MenuDef()

Local _aRotina	:= {}

ADD OPTION _aRotina Title 'Visualizar'		Action 'VIEWDEF.AOMS033'	OPERATION 2 ACCESS 0
ADD OPTION _aRotina Title 'Incluir'			Action 'VIEWDEF.AOMS033'	OPERATION 3 ACCESS 0
ADD OPTION _aRotina Title 'Alterar'			Action 'VIEWDEF.AOMS033'	OPERATION 4 ACCESS 0
ADD OPTION _aRotina Title 'Excluir'			Action 'VIEWDEF.AOMS033'	OPERATION 5 ACCESS 0

ADD OPTION _aRotina Title 'Ativar'			Action 'U_AOMS033A'			OPERATION 2 ACCESS 0
ADD OPTION _aRotina Title 'Bloqueio'		Action 'U_AOMS033B'			OPERATION 2 ACCESS 0
ADD OPTION _aRotina Title 'Criar Versão'	Action 'U_AOMS033V(1)'		OPERATION 2 ACCESS 0
ADD OPTION _aRotina Title 'Copiar Tabela'	Action 'U_AOMS033V(2)'		OPERATION 2 ACCESS 0

Return( _aRotina )

/*
===============================================================================================================================
Programa----------: ModelDef
Autor-------------: Alexandre Villar
Data da Criacao---: 16/09/2015
===============================================================================================================================
Descrição---------: Rotina para configuração do modelo de dados da rotina de manutenção do cadastro
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ModelDef()

Local _aGatAux	:= {}

Local _oTabZF0	:= FWFormStruct( 1 , 'ZF0' )
Local _oTabZF6	:= FWFormStruct( 1 , 'ZF6' , {|_cCampo| AOMS033CPO( _cCampo , 2 ) } )
Local _oTabZF3	:= FWFormStruct( 1 , 'ZF3' , {|_cCampo| AOMS033CPO( _cCampo , 4 ) } )
Local _oTabZF4	:= FWFormStruct( 1 , 'ZF4' , {|_cCampo| AOMS033CPO( _cCampo , 5 ) } )

Local _oModel	:= MpFormModel():New( "AOMS033M" )

//====================================================================================================
// Monta a estrutura dos campos
//====================================================================================================
_aGatAux := FwStruTrigger( 'ZF0_CODFOR' , 'ZF0_NOMFOR'	, 'SA2->A2_NOME'	, .T. , 'SA2' , 1 , 'xFilial("SA2")+M->ZF0_CODFOR+AllTrim(M->ZF0_LOJFOR)'	)
_oTabZF0:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZF0_LOJFOR' , 'ZF0_NOMFOR'	, 'SA2->A2_NOME'	, .T. , 'SA2' , 1 , 'xFilial("SA2")+M->(ZF0_CODFOR+ZF0_LOJFOR)'				)
_oTabZF0:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZF4_CODADC' , 'ZF4_DESADC'	, 'ZFC->ZFC_DESC'	, .T. , 'ZFC' , 1 , 'xFilial("ZFC")+M->ZF4_CODADC'							)
_oTabZF4:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZF6_CODREG' , 'ZF6_DESREG'	, 'ZF1->ZF1_DESREG'	, .T. , 'ZF1' , 1 , 'xFilial("ZF1")+M->ZF6_CODREG'							)
_oTabZF6:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_oModel:AddFields(	'ZF0MASTER'	,				, _oTabZF0 )
_oModel:AddGrid(	'ZF6DETAIL'	, 'ZF0MASTER'	, _oTabZF6 )
_oModel:AddGrid(	'ZF3DETAIL'	, 'ZF6DETAIL'	, _oTabZF3 )
_oModel:AddGrid(	'ZF4DETAIL'	, 'ZF3DETAIL'	, _oTabZF4 )

//====================================================================================================
// Configura as relações entre os browses
//====================================================================================================
_oModel:SetRelation( 'ZF6DETAIL' , {	{ 'ZF6_FILIAL' , 'xFilial("ZF6")'	} , ;
										{ 'ZF6_CODTAB' , 'ZF0_CODIGO'		} , ;
										{ 'ZF6_VERTAB' , 'ZF0_VERSAO'		} } , ZF6->( IndexKey(1) ) )

_oModel:SetRelation( 'ZF3DETAIL' , {	{ 'ZF3_FILIAL' , 'xFilial("ZF3")'	} , ;
										{ 'ZF3_CODTAB' , 'ZF0_CODIGO'		} , ;
										{ 'ZF3_VERTAB' , 'ZF0_VERSAO'		} , ;
										{ 'ZF3_CODREG' , 'ZF6_CODREG'		} } , ZF3->( IndexKey(1) ) )

_oModel:SetRelation( 'ZF4DETAIL' , {	{ 'ZF4_FILIAL' , 'xFilial("ZF4")'	} , ;
										{ 'ZF4_CODTAB' , 'ZF0_CODIGO'		} , ;
										{ 'ZF4_VERTAB' , 'ZF0_VERSAO'		} , ;
										{ 'ZF4_CODREG' , 'ZF6_CODREG'		} , ;
										{ 'ZF4_CODFAI' , 'ZF3_FAIXA'		} } , ZF4->( IndexKey(1) ) )

//====================================================================================================
// Configura as opções de exibição e validação dos browses
//====================================================================================================
_oModel:SetDescription( 'Cadastro das Tabelas de Frete' )

_oModel:GetModel( 'ZF6DETAIL' ):SetOptional( .T. )
_oModel:GetModel( 'ZF3DETAIL' ):SetOptional( .T. )
_oModel:GetModel( 'ZF4DETAIL' ):SetOptional( .T. )

_oModel:GetModel( 'ZF0MASTER' ):SetDescription( 'Tabela de Frete'				)
_oModel:GetModel( 'ZF6DETAIL' ):SetDescription( 'Configuração das Regiões'		)
_oModel:GetModel( 'ZF3DETAIL' ):SetDescription( 'Configuração das Faixas'		)
_oModel:GetModel( 'ZF4DETAIL' ):SetDescription( 'Configuração dos Adicionais'	)

_oModel:GetModel( 'ZF6DETAIL' ):SetUniqueLine( { 'ZF6_CODREG' } )

_oModel:SetPrimaryKey( { 'ZF0_FILIAL' , 'ZF0_CODIGO' } )

_oModel:GetModel( 'ZF0MASTER' ):AFLDNOCOPY := { 'ZF0_CODIGO' , 'ZF0_VERSAO' , 'ZF0_CODFOR' , 'ZF0_LOJFOR' }
_oModel:GetModel( 'ZF6DETAIL' ):AFLDNOCOPY := { 'ZF6_CODTAB' , 'ZF6_VERTAB' }
_oModel:GetModel( 'ZF3DETAIL' ):AFLDNOCOPY := { 'ZF3_CODTAB' , 'ZF3_VERTAB' }
_oModel:GetModel( 'ZF4DETAIL' ):AFLDNOCOPY := { 'ZF4_CODTAB' , 'ZF4_VERTAB' }

Return( _oModel )

/*
===============================================================================================================================
Programa----------: ViewDef
Autor-------------: Alexandre Villar
Data da Criacao---: 16/09/2015
===============================================================================================================================
Descrição---------: Rotina para configuração da interface de dados da rotina de manutenção do cadastro
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ViewDef()

Local _oModel	:= FWLoadModel( 'AOMS033' )
Local _oTabZF0	:= FWFormStruct( 2 , 'ZF0' , {|_cCampo| AOMS033CPO( _cCampo , 0 ) } )
Local _oTabCFG	:= FWFormStruct( 2 , 'ZF0' , {|_cCampo| AOMS033CPO( _cCampo , 1 ) } )
Local _oTabZF6	:= FWFormStruct( 2 , 'ZF6' , {|_cCampo| AOMS033CPO( _cCampo , 2 ) } )
Local _oTabZF3	:= FWFormStruct( 2 , 'ZF3' , {|_cCampo| AOMS033CPO( _cCampo , 4 ) } )
Local _oTabZF4	:= FWFormStruct( 2 , 'ZF4' , {|_cCampo| AOMS033CPO( _cCampo , 5 ) } )
Local _oView	:= FWFormView():New()

//====================================================================================================
// Configura as estruturas de modelo de dados
//====================================================================================================
_oView:SetModel( _oModel )

_oView:AddField( 'VIEW_ZF0' , _oTabZF0 , 'ZF0MASTER' )
_oView:AddField( 'VIEW_CFG' , _oTabCFG , 'ZF0MASTER' )
_oView:AddGrid(  'VIEW_ZF6' , _oTabZF6 , 'ZF6DETAIL' )
_oView:AddGrid(  'VIEW_ZF3' , _oTabZF3 , 'ZF3DETAIL' )
_oView:AddGrid(  'VIEW_ZF4' , _oTabZF4 , 'ZF4DETAIL' )

//====================================================================================================
// Configura as estruturas da interface
//====================================================================================================
_oView:CreateHorizontalBox( 'MAINBOX' , 100 )

_oView:CreateFolder( 'FOLDER' , 'MAINBOX' )

_oView:AddSheet( 'FOLDER' , 'FOLDER01' , 'Tabela de Frete' )
_oView:AddSheet( 'FOLDER' , 'FOLDER02' , 'Configurações'   )

_oView:CreateHorizontalBox( 'CABEC' , 030 ,,, 'FOLDER' , 'FOLDER01' )
_oView:CreateHorizontalBox( 'ITENS' , 040 ,,, 'FOLDER' , 'FOLDER01' )
_oView:CreateHorizontalBox( 'FAIXA' , 030 ,,, 'FOLDER' , 'FOLDER01' )
_oView:CreateHorizontalBox( 'CONFI' , 030 ,,, 'FOLDER' , 'FOLDER02' )
_oView:CreateHorizontalBox( 'ADICI' , 070 ,,, 'FOLDER' , 'FOLDER02' )

_oView:CreateVerticalBox( 'ITN001' , 035 , 'ITENS' ,, 'FOLDER' , 'FOLDER01' )
_oView:CreateVerticalBox( 'ITN002' , 065 , 'ITENS' ,, 'FOLDER' , 'FOLDER01' )

_oView:SetOwnerView( 'VIEW_ZF0' , 'CABEC'  )
_oView:SetOwnerView( 'VIEW_CFG' , 'CONFI'  )
_oView:SetOwnerView( 'VIEW_ZF6' , 'ITN001' )
_oView:SetOwnerView( 'VIEW_ZF4' , 'FAIXA'  )
_oView:SetOwnerView( 'VIEW_ZF3' , 'ITN002' )

//====================================================================================================
// Configurações de campos e títulos
//====================================================================================================
_oView:AddIncrementField( 'VIEW_ZF3' , 'ZF3_FAIXA'	)

_oView:EnableTitleView( 'VIEW_ZF0' , 'Tabela de Frete'			)
_oView:EnableTitleView( 'VIEW_CFG' , 'Dados da Tabela'			)
_oView:EnableTitleView( 'VIEW_ZF6' , 'Cadastro das Regiões'		)
_oView:EnableTitleView( 'VIEW_ZF3' , 'Cadastro das Faixas'		)
_oView:EnableTitleView( 'VIEW_ZF4' , 'Complementos do Frete'	)

Return( _oView )

/*
===============================================================================================================================
Programa----------: AOMS033CPO
Autor-------------: Alexandre Villar
Data da Criacao---: 16/09/2015
===============================================================================================================================
Descrição---------: Rotina para configuração de exibição dos campos na tela de manutenção do cadastro
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS033CPO( _cCampo , _nOpc )

Local _lRet := .T.

Do Case

	Case _nOpc <= 1
	
		_lRet := ( Upper( AllTrim( _cCampo ) ) $ 'ZF0_CODIGO,ZF0_VERSAO,ZF0_DATA,ZF0_CODFOR,ZF0_LOJFOR,ZF0_NOMFOR,ZF0_STATUS' )
		
		If _nOpc == 1
			_lRet := !_lRet
		EndIf
	
	Case _nOpc == 2
	
		_lRet := !( Upper( AllTrim( _cCampo ) ) $ 'ZF6_CODTAB,ZF6_VERTAB' )
	
	Case _nOpc == 4
		
		_lRet := !( Upper( AllTrim( _cCampo ) ) $ 'ZF3_CODTAB,ZF3_VERTAB,ZF3_CODREG' )
	
	Case _nOpc == 5
		
		_lRet := !( Upper( AllTrim( _cCampo ) ) $ 'ZF4_CODTAB,ZF4_VERTAB,ZF4_CODREG,ZF4_CODFAI' )

EndCase

Return( _lRet )

/*
===============================================================================================================================
Programa----------: AOMS033I
Autor-------------: Alexandre Villar
Data da Criacao---: 16/09/2015
===============================================================================================================================
Descrição---------: Rotina para configuração de inicializador padrão de campos
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS033I( _nOpc )

Local _xRet		:= NIL
Local _cQuery	:= ''
Local _cAlias	:= ''

//====================================================================================================
// (1) - Inicializador do campo Código da Tabela
//====================================================================================================
If _nOpc == 1
	
	_cQuery := " SELECT "
	_cQuery += "     NVL( MAX( ZF0.ZF0_CODIGO ) , '0' ) AS CODIGO "
	_cQuery += " FROM  "+ RETSQLNAME('ZF0') +" ZF0 "
	_cQuery += " WHERE "+ RETSQLCOND('ZF0')
	
	_cAlias := GetNextAlias()
	
	If Select(_cAlias) > 0
		(_cAlias)->( DBCloseArea() )
	EndIf
	
	DBUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQuery ) , _cAlias , .T. , .F. )
	
	DBSelectArea(_cAlias)
	(_cAlias)->( DBGoTop() )
	If (_cAlias)->( !Eof() )
		_xRet := StrZero( Val( (_cAlias)->CODIGO ) , TamSX3('ZF0_CODIGO')[01] )
	Else
		_xRet := StrZero( 0 , TamSX3('ZF0_CODIGO')[01] )
	EndIf
	
	(_cAlias)->( DBCloseArea() )
	
	_xRet := Soma1( _xRet )
	
	While !MayIUseCod( 'AOMS033COD'+ _xRet )
		_xRet := Soma1( _xRet )
	EndDo
	
EndIf

Return( _xRet )

/*
===============================================================================================================================
Programa----------: AOMS033M
Autor-------------: Alexandre Villar
Data da Criacao---: 16/09/2015
===============================================================================================================================
Descrição---------: Rotina para configuração dos pontos de entrada
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS033M()

Local _aInfHlp	:= {}
Local _aParam	:= ParamIXB
Local _oObj		:= NIL
Local _cIdPonto	:= ''
Local _cIdModel	:= ''
Local _lIsGrid	:= .F.
Local _lRet		:= .T.
Local _nOper	:= 0

If _aParam <> NIL

	_oObj		:= _aParam[01]
	_cIdPonto	:= _aParam[02]
	_cIdModel	:= _aParam[03]
	_lIsGrid	:= ( Len( _aParam ) > 3 ) .And. ValType( _aParam[04] ) == 'N'
	_nOper		:= _oObj:GetOperation()
	
	If _cIdPonto == 'MODELVLDACTIVE' .And. ( _nOper == MODEL_OPERATION_UPDATE )
		
		If ZF0->ZF0_STATUS == "A"
			
			_aInfHlp := {}
			//                 |....:....|....:....|....:....|....:....|      |....:....|....:....|....:....|....:....|
			aAdd( _aInfHlp , { "Não é permitido alterar uma tabela ativa!"												} )
			aAdd( _aInfHlp , { "Caso necessário crie uma nova verão da "	, " tabela."								} )
			
			U_ITCADHLP( _aInfHlp , "AOMS03301" )
			
			_lRet := .F.
			
		EndIf
		
	EndIf

EndIf

Return( _lRet )

/*
===============================================================================================================================
Programa----------: AOMS033A
Autor-------------: Alexandre Villar
Data da Criacao---: 16/09/2015
===============================================================================================================================
Descrição---------: Rotina para ativação das tabelas de Frete
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS033A()

Local _cQuery	:= ''
Local _cAlias	:= ''
Local _nRegAtu	:= ZF0->( Recno() )
Local _xAcesso	:= U_ITAcsUsr( 'ZZL_CADFRT' )

If ZF0->ZF0_STATUS $ 'P/E'
	
	If ValType( _xAcesso ) == 'C'
	
		If _xAcesso == '1'
			
			If ZF0->ZF0_STATUS == 'P'
				
				If MsgYesNo( 'Confirma o envio da tabela atual para aprovação?' , 'Atenção!' )
					
					RecLock( 'ZF0' , .F. )
					ZF0->ZF0_DATA	:= Date()
					ZF0->ZF0_USRALT	:= RetCodUsr()
					ZF0->ZF0_STATUS := "E"
					ZF0->( MSUnLock() )
					
				Else
				
					MessageBox( 'Operação cancelada pelo usuário!' , 'Atenção!' , 16 )
					
				EndIf
				
			ElseIf ZF0->ZF0_STATUS == 'E'
				
			//									|....:....|....:....|....:....|....:....|
				ShowHelpDlg( 'Atenção!' ,	{	'A tabela atual já está em processo de '	,;
												' aprovação!'								} , 2 ,;
											{	'Aguarde o retorno do aprovador.'			} , 1 )
				
			EndIf
			
		ElseIf _xAcesso == '2'
		
			_cQuery := " SELECT "
			_cQuery += "     ZF0.R_E_C_N_O_ AS REGZF0 "
			_cQuery += " FROM  "+ RetSqlName('ZF0') +" ZF0 "
			_cQuery += " WHERE "+ RetSqlCond('ZF0')
			_cQuery += " AND ZF0.ZF0_CODIGO = '"+ ZF0->ZF0_CODIGO +"' "
			_cQuery += " AND ZF0.ZF0_STATUS = 'A' "
			
			_cAlias := GetNextAlias()
			
			If Select(_cAlias) > 0
				(_cAlias)->( DBCloseArea() )
			EndIf
			
			DBUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQuery ) , _cAlias , .T. , .F. )
			
			DBSelectArea(_cAlias)
			(_cAlias)->( DBGoTop() )
			If (_cAlias)->( !Eof() ) .And. !Empty( (_cAlias)->REGZF0 )
				
				If MsgYesNo( 'A ativação da tabela atual vai desativar a tabela que está sendo usada nesse momento para esse mesmo transportador! Deseja confirmar a ativação da nova versão da tabela?' , 'Atenção!' )
					
					_lOk := .T.
					
					DBSelectArea('ZF0')
					ZF0->( DBGoTo( (_cAlias)->REGZF0 ) )
					RecLock( 'ZF0' , .F. )
					ZF0->ZF0_DATA	:= Date()
					ZF0->ZF0_USRALT	:= RetCodUsr()
					ZF0->ZF0_STATUS := "I"
					ZF0->( MSUnLock() )
					
				Else
				
					_lOk := .F.
					MessageBox( 'Operação cancelada pelo usuário!' , 'Atenção!' , 16 )
					
				EndIf
			
			Else
			
				If MsgYesNo( 'Deseja confirmar a ativação da nova tabela?' , 'Atenção!' )
				
					_lOk := .T.
					
				Else
				
					_lOk := .F.
					MessageBox( 'Operação cancelada pelo usuário!' , 'Atenção!' , 16 )
					
				EndIf
				
			EndIf
			
			(_cAlias)->( DBCloseArea() )
			
			DBSelectArea('ZF0')
			ZF0->( DBGoTo( _nRegAtu ) )
			
			If _lOk
				
				RecLock( 'ZF0' , .F. )
				ZF0->ZF0_DATA	:= Date()
				ZF0->ZF0_USRALT	:= RetCodUsr()
				ZF0->ZF0_STATUS := "A"
				ZF0->( MSUnLock() )
				
				MessageBox( 'Tabela ativada com sucesso!' , 'Atenção!' , 64 )
				
			EndIf
		
		EndIf
	
	Else
	
		MessageBox( 'Usuário sem acesso à rotina de aprovação/ativação da tabela de preços!' , 'Atenção!' , 16 )
	
	EndIf

Else

//									|....:....|....:....|....:....|....:....|
	ShowHelpDlg( 'Atenção!' ,	{	'Não é possível ativar uma tabela que '		,;
									' está com status: '+ U_ITRETBOX(ZF0->ZF0_STATUS,'ZF0_STATUS') +'!' } , 2 ,;
								{	'Somente tabelas pendentes podem ser '		,;
									' ativadas para uso, se For o caso crie '	,;
									' uma nova versão ou desbloqueie a tabela '	,;
									' selecionada.'								} , 4 )

EndIf

Return

/*
===============================================================================================================================
Programa----------: AOMS033B
Autor-------------: Alexandre Villar
Data da Criacao---: 16/09/2015
===============================================================================================================================
Descrição---------: Rotina para o controle de bloqueio das tabelas de Frete
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS033B()

If ZF0->ZF0_STATUS == 'B'
	
	If MsgYesNo( 'Deseja desbloquear a tabela selecionada?' , 'Atenção!' )
		
		RecLock( 'ZF0' , .F. )
		ZF0->ZF0_DATA	:= Date()
		ZF0->ZF0_USRALT	:= RetCodUsr()
		ZF0->ZF0_STATUS := "P"
		ZF0->( MSUnLock() )
		
		MessageBox( 'Tabela desbloqueada com sucesso!' , 'Concluído!' , 64 )
	
	Else
		
		MessageBox( 'Operação cancelada pelo usuário!' , 'Atenção!' , 16 )
		
	EndIf
	
Else
	
	If MsgYesNo( 'Confirma o bloqueio da tabela selecionada?' , 'Atenção!' )
	
		RecLock( 'ZF0' , .F. )
		ZF0->ZF0_DATA	:= Date()
		ZF0->ZF0_USRALT	:= RetCodUsr()
		ZF0->ZF0_STATUS := "B"
		ZF0->( MSUnLock() )
		
		MessageBox( 'Tabela bloqueada com sucesso!' , 'Concluído!' , 64 )
	
	Else
		
		MessageBox( 'Operação cancelada pelo usuário!' , 'Atenção!' , 16 )
		
	EndIf

EndIf

Return

/*
===============================================================================================================================
Programa----------: AOMS033V
Autor-------------: Alexandre Villar
Data da Criacao---: 16/09/2015
===============================================================================================================================
Descrição---------: Rotina para chamar o versionamento de tabelas
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS033V( _nOpc )

If MsgYesNo( 'Confirma a criação de uma nova versão de acordo com os dados da tabela selecionada?' , 'Atenção!' )
	
	Processa( {|| AOMS033CNV( _nOpc ) } , 'Gerando nova '+ IIf( _nOpc == 1 , 'versão da tabela...' , 'cópia da tabela...' ) , 'Aguarde!' )
	
EndIf

Return

/*
===============================================================================================================================
Programa----------: AOMS033CNV
Autor-------------: Alexandre Villar
Data da Criacao---: 16/09/2015
===============================================================================================================================
Descrição---------: Rotina para criar uma nova versão da tabela posicionada
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS033CNV( _nOpc )

Local _aDadZF0	:= {}
Local _aDadZF6	:= {}
Local _aDadZF3	:= {}
Local _nI		:= 0
Local _cCodTab	:= ZF0->ZF0_CODIGO
Local _cVerTab	:= ZF0->ZF0_VERSAO
Local _cNewVer	:= '0'

Local _cQuery	:= ''
Local _cAlias	:= ''

ProcRegua( 0 )

IncProc( 'Iniciando o processamento...' )

_aDadZF0 := {	ZF0->ZF0_FILIAL	,;
				ZF0->ZF0_CODIGO	,;
				ZF0->ZF0_CODFOR	,;
				ZF0->ZF0_LOJFOR	,;
				ZF0->ZF0_DESSEG	,;
				ZF0->ZF0_TIPSEG	,;
				ZF0->ZF0_BASSEG	,;
				ZF0->ZF0_ICMS	 }

IncProc( 'Verificando a configuração da tabela atual...' )

DBSelectArea( 'ZF6' )
ZF6->( DBSetOrder(1) )
If ZF6->( DBSeek( xFilial('ZF6') + _cCodTab + _cVerTab ) )
	
	While ZF6->( !Eof() ) .And. ZF6->( ZF6_FILIAL + ZF6_CODTAB + ZF6_VERTAB ) == xFilial('ZF6') + _cCodTab + _cVerTab
		
		aAdd( _aDadZF6 , {	ZF6->ZF6_FILIAL		,;
							ZF6->ZF6_CODTAB		,;
							ZF6->ZF6_CODREG		,;
							ZF6->ZF6_BASEKM		})
		
	ZF6->( DBSkip() )
	EndDo
	
EndIf

DBSelectArea( 'ZF3' )
ZF3->( DBSetOrder(1) )
If ZF3->( DBSeek( xFilial('ZF3') + _cCodTab + _cVerTab ) )
	
	While ZF3->( !Eof() ) .And. ZF3->( ZF3_FILIAL + ZF3_CODTAB + ZF3_VERTAB ) == xFilial('ZF3') + _cCodTab + _cVerTab
		
		aAdd( _aDadZF3 , {	ZF3->ZF3_FILIAL		,;
							ZF3->ZF3_CODTAB		,;
							ZF3->ZF3_CODREG		,;
							ZF3->ZF3_FAIXA		,;
							ZF3->ZF3_DESCRI		,;
							ZF3->ZF3_TIPCAR		,;
							ZF3->ZF3_CAPINI		,;
							ZF3->ZF3_CAPFIN		,;
							ZF3->ZF3_VLRBAS		,;
							ZF3->ZF3_TIPCAL		})
		
	ZF3->( DBSkip() )
	EndDo
	
EndIf

If _nOpc == 1

	IncProc( 'Verificando a versão para a nova tabela...' )
	
	_cQuery := " SELECT "
	_cQuery += "     MAX( ZF0.ZF0_VERSAO ) AS MAXVER "
	_cQuery += " FROM  "+ RetSqlName('ZF0') +" ZF0 "
	_cQuery += " WHERE "+ RetSqlCond('ZF0')
	_cQuery += " AND ZF0.ZF0_CODIGO = '"+ _cCodTab +"' "
	
	_cAlias := GetNextAlias()
	
	If Select(_cAlias) > 0
		(_cAlias)->( DBCloseArea() )
	EndIf
	
	DBUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQuery ) , _cAlias , .T. , .F. )
	
	DBSelectArea(_cAlias)
	(_cAlias)->( DBGoTop() )
	If (_cAlias)->( !Eof() )
		_cNewVer := StrZero( Val( (_cAlias)->MAXVER ) , TamSX3('ZF0_VERSAO')[01] )
	Else
		_cNewVer := StrZero( 0 , TamSX3('ZF0_VERSAO')[01] )
	EndIf
	
	(_cAlias)->( DBCloseArea() )
	
	_cNewVer := Soma1( _cNewVer )
	
	While !MayIUseCod( 'AOMS033VER'+ ZF0->ZF0_CODIGO + _cNewVer )
		_cNewVer := Soma1( _cNewVer )
	EndDo
	
	IncProc( 'Gravando a nova versão da tabela...' )
	
ElseIf _nOpc == 2
	
	_cCodTab := U_AOMS033I( 1 )
	_cNewVer := '001'
	
	IncProc( 'Gravando a nova tabela...' )
	
EndIf

DBSelectArea('ZF0')
RecLock( 'ZF0' , .T. )
	
	ZF0->ZF0_FILIAL	:= _aDadZF0[01]
	ZF0->ZF0_CODIGO	:= _cCodTab
	ZF0->ZF0_VERSAO	:= _cNewVer
	ZF0->ZF0_DESSEG	:= _aDadZF0[05]
	ZF0->ZF0_TIPSEG	:= _aDadZF0[06]
	ZF0->ZF0_BASSEG	:= _aDadZF0[07]
	ZF0->ZF0_ICMS	:= _aDadZF0[08]
	ZF0->ZF0_DATA	:= Date()
	ZF0->ZF0_USRALT	:= RetCodUsr()
	ZF0->ZF0_STATUS	:= 'P'
	
ZF0->( MSUnLock() )

For _nI := 1 To Len( _aDadZF6 )
	
	DBSelectArea('ZF6')
	RecLock( 'ZF6' , .T. )
		
		ZF6->ZF6_FILIAL	:= _aDadZF6[_nI][01]
		ZF6->ZF6_CODTAB	:= _cCodTab
		ZF6->ZF6_VERTAB	:= _cNewVer
		ZF6->ZF6_CODREG	:= _aDadZF6[_nI][03]
		ZF6->ZF6_BASEKM	:= _aDadZF6[_nI][04]
	
	ZF6->( MSUnLock() )
	
Next _nI

For _nI := 1 To Len( _aDadZF3 )
	
	DBSelectArea('ZF3')
	RecLock( 'ZF3' , .T. )
	
		ZF3->ZF3_FILIAL	:= _aDadZF3[_nI][01]
		ZF3->ZF3_CODTAB	:= _cCodTab
		ZF3->ZF3_VERTAB	:= _cNewVer
		ZF3->ZF3_CODREG	:= _aDadZF3[_nI][03]
		ZF3->ZF3_FAIXA	:= _aDadZF3[_nI][04]
		ZF3->ZF3_DESCRI	:= _aDadZF3[_nI][05]
		ZF3->ZF3_TIPCAR	:= _aDadZF3[_nI][06]
		ZF3->ZF3_CAPINI	:= _aDadZF3[_nI][07]
		ZF3->ZF3_CAPFIN	:= _aDadZF3[_nI][08]
		ZF3->ZF3_VLRBAS	:= _aDadZF3[_nI][09]
		ZF3->ZF3_TIPCAL	:= _aDadZF3[_nI][10]
	
	ZF3->( MSUnLock() )
	
Next _nI

MessageBox( 'Gerada a tabela: '+ _cCodTab +'/'+ _cNewVer +' com sucesso!' , 'Concluído!' , 64 )

Return

/*
===============================================================================================================================
Programa----------: AOMS033F
Autor-------------: Alexandre Villar
Data da Criacao---: 16/09/2015
===============================================================================================================================
Descrição---------: Rotina para validar o código de fornecedor informado na tabela de frete.
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS033F()

Local _lRet		:= .T.
Local _oModel	:= FWModelActive()
Local _nAction	:= _oModel:GetOperation()

Local _aInfHlp	:= {}

Local _cAux		:= ''
Local _cQuery	:= ''
Local _cAlias	:= ''

Local _cCodTab	:= _oModel:GetValue( 'ZF0MASTER' , 'ZF0_CODIGO' )
Local _cVerTab	:= _oModel:GetValue( 'ZF0MASTER' , 'ZF0_VERSAO' )
Local _cCodFor	:= _oModel:GetValue( 'ZF0MASTER' , 'ZF0_CODFOR' )
Local _cLojFor	:= _oModel:GetValue( 'ZF0MASTER' , 'ZF0_LOJFOR' )

If _nAction <> MODEL_OPERATION_DELETE

	If Empty( _cCodTab ) .Or. Empty( _cVerTab )
		
		_aInfHlp := {}
		//                  |....:....|....:....|....:....|....:....|     |....:....|....:....|....:....|....:....|       |....:....|....:....|....:....|....:....|
		aAdd( _aInfHlp	, { "Não foi possível validar o código e a "	, " versão da tabela atual! "																	} )
		aAdd( _aInfHlp	, { "Verifique os dados informado e/ou saia "	, " da tela e tente realizar a operação "		, " novamente."									} )
		
		U_ITCADHLP( _aInfHlp , "AOMS03301" )
		
		_lRet := .F.
		
	EndIf
	
	If Empty( _cCodFor ) .And. Empty( _cLojFor )
	
		_aInfHlp := {}
		//                  |....:....|....:....|....:....|....:....|     |....:....|....:....|....:....|....:....|       |....:....|....:....|....:....|....:....|
		aAdd( _aInfHlp	, { "É obrigatório informar um código e loja "	, " válidos de transportador para incluir! "													} )
		aAdd( _aInfHlp	, { "Verifique os dados informados."																											} )
		
		U_ITCADHLP( _aInfHlp , "AOMS03302" )
		
		_lRet := .F.
		
	ElseIf Empty( _cLojFor )
	
		_cAux := AllTrim( Posicione( 'SA2' , 1 , xFilial('SA2') + _cCodFor , 'A2_NOME' ) )
		
		If Empty( _cAux )
		
			_aInfHlp := {}
			//                  |....:....|....:....|....:....|....:....|     |....:....|....:....|....:....|....:....|       |....:....|....:....|....:....|....:....|
			aAdd( _aInfHlp	, { "É obrigatório informar um código e loja "	, " válidos de transportador para incluir! "													} )
			aAdd( _aInfHlp	, { "Verifique os dados informados."																											} )
			
			U_ITCADHLP( _aInfHlp , "AOMS03302" )
			
			_lRet := .F.
			
		EndIf
	
	Else
	
		_cQuery := " SELECT ZF0.ZF0_CODIGO, ZF0.ZF0_VERSAO FROM "+ RetSqlName('ZF0') +" ZF0 "
		_cQuery += " WHERE "+ RetSqlCond('ZF0') +" AND ZF0.ZF0_CODIGO <> '"+ _cCodTab +"' "
		_cQuery += " AND ZF0.ZF0_CODFOR = '"+ _cCodFor +"' AND ZF0.ZF0_LOJFOR = '"+ _cLojFor +"' "
		
		_cAlias := GetNextAlias()
		
		If Select(_cAlias) > 0
			(_cAlias)->( DBCloseArea() )
		EndIf
		
		DBUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQuery ) , _cAlias , .T. , .F. )
		
		DBSelectArea(_cAlias)
		(_cAlias)->( DBGoTop() )
		If (_cAlias)->( !Eof() ) .And. !Empty( (_cAlias)->ZF0_CODIGO )
			
			_aInfHlp := {}
			//                  |....:....|....:....|....:....|....:....|     |....:....|....:....|....:....|....:....|       |....:....|....:....|....:....|....:....|
			aAdd( _aInfHlp	, { "Já existe uma tabela de frete cadastrada "	, " para o transportador informado! "															} )
			aAdd( _aInfHlp	, { "Verifique os dados informados e/ou a "		, " tabela existente ["+ (_cAlias)->ZF0_CODIGO +"/"+ (_cAlias)->ZF0_VERSAO +"]!"				} )
			
			U_ITCADHLP( _aInfHlp , "AOMS03303" )
			
			_lRet := .F.
		
		Else
			
			_cAux := AllTrim( Posicione( 'SA2' , 1 , xFilial('SA2') + _cCodFor + _cLojFor , 'A2_NOME' ) )
			
			If Empty(_cAux)
			
				_aInfHlp := {}
				//                  |....:....|....:....|....:....|....:....|     |....:....|....:....|....:....|....:....|       |....:....|....:....|....:....|....:....|
				aAdd( _aInfHlp	, { "É obrigatório informar um código e loja "	, " válidos de transportador para incluir! "													} )
				aAdd( _aInfHlp	, { "Verifique os dados informados."																											} )
				
				U_ITCADHLP( _aInfHlp , "AOMS03302" )
				
				_lRet := .F.
				
			EndIf
			
		EndIf
		
		(_cAlias)->( DBCloseArea() )
	
	EndIf

EndIf

Return( _lRet )
