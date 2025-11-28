/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |28/09/2018| Chamado 26404. Revisão do fonte para padronização
Lucas Borges  |23/01/2019| Chamado 27807. Padronização dos campos de placa
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "FWMVCDef.ch"

/*
===============================================================================================================================
Programa----------: AGLT028
Autor-------------: Alexandre Villar
Data da Criacao---: 18/11/2014
Descrição---------: Cadastro de Veículos referentes ao transporte de Leite de Terceiros
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT028

Local _oBrowse	:= Nil

//====================================================================================================
// Configura e inicializa a Classe do Browse
//====================================================================================================
_oBrowse := FWMBrowse():New()

_oBrowse:SetAlias( "ZZV" )
_oBrowse:SetMenuDef( 'AGLT028' )
_oBrowse:SetDescription( "Cadastro de Veículos para Transporte de Leite de Terceiros" )
_oBrowse:DisableDetails()
_oBrowse:Activate()

Return

/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Alexandre Villar
Data da Criacao---: 18/11/2014
Descrição---------: Rotina de definição automática do menu via MVC
Parametros--------: Nenhum
Retorno-----------: aRotina - Definições do menu principal da Rotina.
===============================================================================================================================
*/
Static Function MenuDef()
Return( FWMVCMenu("AGLT028") )

/*
===============================================================================================================================
Programa----------: ModelDef
Autor-------------: Alexandre Villar
Data da Criacao---: 19/11/2014
Descrição---------: Rotina de definição do Modelo de Dados do MVC
Parametros--------: Nenhum
Retorno-----------: oModel - Objeto do modelo de dados do MVC
===============================================================================================================================
*/
Static Function ModelDef()

//===========================================================================
//| Inicializa a estrutura do modelo de dados                               |
//===========================================================================
Local _oStruZZV	:= FWFormStruct( 1 , "ZZV" )
Local _oModel	:= Nil
Local _bValid	:= {|_oModel| AGLT028INC(_oModel) }

//===========================================================================
//| Inicializa e configura o modelo de dados                                |
//===========================================================================
_oModel := MPFormModel():New( "AGLT028M" ,, _bValid )

_oModel:SetDescription( 'Transporte Leite Terceiros' )
_oModel:AddFields( 'ZZVMASTER' ,, _oStruZZV )
_oModel:GetModel( 'ZZVMASTER' ):SetDescription( 'Cadastro de Veículos' )
_oModel:SetVldActivate( {|_oModel| AGLT028VLI(_oModel) } )

Return( _oModel )

/*
===============================================================================================================================
Programa----------: ViewDef
Autor-------------: Alexandre Villar
Data da Criacao---: 19/11/2014
Descrição---------: Rotina de definição da View do MVC
Parametros--------: Nenhum
Retorno-----------: oView - Objeto de exibição do MVC
===============================================================================================================================
*/
Static Function ViewDef()

Local _oModel	:= FWLoadModel( "AGLT028" )
Local _oStruZZV	:= FWFormStruct( 2 , "ZZV" )
Local _oView	:= Nil

//===========================================================================
//| Inicializa o Objeto da View                                             |
//===========================================================================
_oView := FWFormView():New()

_oView:SetModel( _oModel )
_oView:AddField( "VIEW_ZZV" , _oStruZZV , "ZZVMASTER" )
_oView:CreateHorizontalBox( 'BOX0101' , 100 )
_oView:SetOwnerView( "VIEW_ZZV", "BOX0101" )

Return( _oView )

/*
===============================================================================================================================
Programa----------: AGLT028VLI
Autor-------------: Alexandre Villar
Data da Criacao---: 19/11/2014
Descrição---------: Validação inicial do modelo de dados
Parametros--------: Nenhum
Retorno-----------: oView - Objeto de exibição do MVC
===============================================================================================================================
*/
Static Function AGLT028VLI( _oModel )

Local _cAlias	:= GetNextAlias()   
Local _lRet		:= .T.

If _oModel:GetOperation() == MODEL_OPERATION_DELETE

	BeginSql Alias _cAlias
		SELECT COUNT(1) QTD
		FROM %Table:ZZX% ZZX
		WHERE ZZX.D_E_L_E_T_ =' '
		AND ZZX.ZZX_FILIAL = %xFilial:ZZX%
		AND ZZX_PLACA  = %exp:ZZV->ZZV_PLACA%
		AND ZZX_TRANSP = %exp:ZZV->ZZV_TRANSP%
		AND ZZX_LJTRAN = %exp:ZZV->ZZV_LJTRAN%
	EndSql

	If (_cAlias)->QTD > 0
		_lRet := .F.
		_oModel:SetErrorMessage('ZZVMASTER', 'ZZV_PLACA' , 'ZZVMASTER' , 'ZZV_PLACA' , "AGLT02801", "O veículo atual está vinculado a uma análise de Qualidade", "Não será possível excluir o veículo sem efetuar o cancelamento das análises de Qualidade existentes!")
	EndIf
	
	(_cAlias)->( DBCloseArea() )

EndIf

Return( _lRet )

/*
===============================================================================================================================
Programa----------: AGLT028INC
Autor-------------: Alexandre Villar
Data da Criacao---: 19/11/2014
Descrição---------: Validação da inclusão de registros
Parametros--------: Nenhum
Retorno-----------: oView - Objeto de exibição do MVC
===============================================================================================================================
*/
Static Function AGLT028INC(_oModel)

Local _lRet		:= .T.
Local _aArea	:= FWGetArea()

If _oModel:GetOperation() == MODEL_OPERATION_INSERT

	If Len( AllTrim( StrTran(_oModel:GetValue('ZZVMASTER','ZZV_PLACA'),'-',"") ) ) < GetSx3Cache("ZZV_PLACA","X3_TAMANHO")
		_lRet := .F.
		_oModel:SetErrorMessage('ZZVMASTER', 'ZZV_PLACA' , 'ZZVMASTER' , 'ZZV_PLACA' , "AGLT02802", "A placa informada não é válida.", "Verifique os dados informados")
	EndIf
	
	If _lRet
	
		DBSelectArea("ZZV")
		ZZV->( DBSetOrder(3) )
		If ZZV->( DBSeek( xFilial("ZZV") + _oModel:GetValue('ZZVMASTER','ZZV_PLACA') + _oModel:GetValue('ZZVMASTER','ZZV_TRANSP') + _oModel:GetValue('ZZVMASTER','ZZV_LJTRAN') ) )
			_lRet := .F.		
			_oModel:SetErrorMessage('ZZVMASTER', 'ZZV_PLACA' , 'ZZVMASTER' , 'ZZV_PLACA' , "AGLT02803", "A placa informada já foi cadastrada para o Transportador atual.", "Verifique os dados informados")
		EndIf
	
	EndIf

EndIf

FWRestArea( _aArea )

Return( _lRet )
