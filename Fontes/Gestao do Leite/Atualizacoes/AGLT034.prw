/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alexandre V.  |29/07/2015| Chamado 11121. Atualização dos gatilhos para substituir o A2_NOME por A2_NREDUZ
Josué Danich  |14/08/2017| Chamado 21101. Ajuste de validação de linha duplicada para ZZU
Lucas Borges  |12/06/2019| Chamado 28346. Revisão de fontes
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "FWMVCDEF.CH"

/*
===============================================================================================================================
Programa----------: AGLT034
Autor-------------: Alexandre Villar
Data da Criacao---: 19/11/2014
Descrição---------: Rotina para Cadastro da Tabela de Frete do Leite de Terceiros
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT034()

Local _oBrowse := Nil

//====================================================================================================
// Configura e inicializa a Classe do Browse
//====================================================================================================
_oBrowse := FWMBrowse():New()

_oBrowse:SetAlias( 'ZZT' )
_oBrowse:SetMenuDef( 'AGLT034' )
_oBrowse:SetDescription( 'Tabela de Frete - Leite de Terceiros' )
_oBrowse:DisableDetails()

_oBrowse:Activate()

Return
  
/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Alexandre Villar
Data da Criacao---: 19/11/2014
Descrição---------: Rotina para criação do menu na tela inicial
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MenuDef()
Return( FWMVCMenu("AGLT034") )

/*
===============================================================================================================================
Programa----------: ModelDef
Autor-------------: Alexandre Villar
Data da Criacao---: 19/11/2014
Descrição---------: Rotina para criação do modelo de dados para o processamento
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ModelDef()

Local _aGatAux	:= {}

Local _oStruZZT	:= FWFormStruct( 1 , 'ZZT' )
Local _oStruZZU	:= FWFormStruct( 1 , 'ZZU' )

Local _oModel	:= MpFormModel():New( "AGLT034M" ,, {|| VALIDCOMIT() } )

//====================================================================================================
// Define Gatilhos para a Estrutura de Dados
//====================================================================================================
_aGatAux := FwStruTrigger( 'ZZT_TRANSP' , 'ZZT_NOMTRA'	, 'SA2->A2_NREDUZ'	, .T. , 'SA2' , 1 , 'xFilial("SA2")+M->ZZT_TRANSP'		 					)
_oStruZZT:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZZT_LJTRAN' , 'ZZT_NOMTRA'	, 'SA2->A2_NREDUZ'	, .T. , 'SA2' , 1 , 'xFilial("SA2")+M->(ZZT_TRANSP+ZZT_LJTRAN)'				)
_oStruZZT:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZZT_TRANSP' , 'ZZT_LJTRAN'	, 'SA2->A2_LOJA'	, .T. , 'SA2' , 1 , 'xFilial("SA2")+M->ZZT_TRANSP+AllTrim(M->ZZT_LJTRAN)'	)
_oStruZZT:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZZU_FORNEC' , 'ZZU_NOMFOR'	, 'SA2->A2_NREDUZ'	, .T. , 'SA2' , 1 , 'xFilial("SA2")+M->ZZU_FORNEC'							)
_oStruZZU:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZZU_FORNEC' , 'ZZU_KMFORN'	, 'SA2->A2_L_KMLE'	, .T. , 'SA2' , 1 , 'xFilial("SA2")+M->ZZU_FORNEC'							)
_oStruZZU:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZZU_FORNEC' , 'ZZU_LJFORN'	, 'SA2->A2_LOJA'	, .T. , 'SA2' , 1 , 'xFilial("SA2")+M->ZZU_FORNEC+AllTrim(M->ZZU_LJFORN)'	)
_oStruZZU:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZZU_LJFORN' , 'ZZU_KMFORN'	, 'SA2->A2_L_KMLE'	, .T. , 'SA2' , 1 , 'xFilial("SA2")+M->(ZZU_FORNEC+ZZU_LJFORN)'				)
_oStruZZU:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZZU_LJFORN' , 'ZZU_NOMFOR'	, 'SA2->A2_NREDUZ'	, .T. , 'SA2' , 1 , 'xFilial("SA2")+M->(ZZU_FORNEC+ZZU_LJFORN)'				)
_oStruZZU:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

//====================================================================================================
// Monta a estrutura dos campos
//====================================================================================================
_oModel:AddFields(	'CABEC'		,			, _oStruZZT )
_oModel:AddGrid(	'DETALHE'	, 'CABEC'	, _oStruZZU ,, { || AGLT034LOK() } )

_oModel:SetRelation( 'DETALHE', { {'ZZU_FILIAL','xFilial( "ZZU" )'} , {'ZZU_TRANSP','ZZT_TRANSP'} , {'ZZU_LJTRAN','ZZT_LJTRAN'} , {'ZZU_CAPACI','ZZT_CAPACI'} } , ZZU->( IndexKey(1) ) )

_oModel:SetDescription( 'Tabela de Frete' )

_oModel:GetModel( 'CABEC'	):SetDescription( 'Tranportador' )
_oModel:GetModel( 'DETALHE'	):SetDescription( 'Fornecedores' )
_oModel:GetModel( 'DETALHE'	):SetUniqueLine( { 'ZZU_FORNEC','ZZU_LJFORN'} )
                                                                                                                                                                                                                           
_oModel:SetPrimaryKey( { 'ZZT_FILIAL' , 'ZZT_TRANSP' , 'ZZT_LJTRAN' , 'ZZT_CAPACI' } )

_oModel:SetVldActivate( { |_oModel| AGLT034INI(_oModel) } )

Return( _oModel )

/*
===============================================================================================================================
Programa----------: ViewDef
Autor-------------: Alexandre Villar
Data da Criacao---: 19/11/2014
Descrição---------: Rotina para criação da view de dados para exibição na tela
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ViewDef()

Local _oModel	:= FWLoadModel( 'AGLT034'	)
Local _oStruZZT	:= FWFormStruct( 2 , 'ZZT'	)
Local _oStruZZU	:= FWFormStruct( 2 , 'ZZU'	)

Local _oView	:= FWFormView():New()

//====================================================================================================
// Remove campos não utilizados da tela
//====================================================================================================
_oStruZZU:RemoveField( 'ZZU_TRANSP' )   
_oStruZZU:RemoveField( 'ZZU_LJTRAN' )
_oStruZZU:RemoveField( 'ZZU_CAPACI' )     

//====================================================================================================
// Monta a estrutura da view de dados
//====================================================================================================
_oView:SetModel( _oModel )
_oView:AddField(	'VIEW_CABEC'	, _oStruZZT , 'CABEC'	)
_oView:AddGrid(		'VIEW_DET'		, _oStruZZU , 'DETALHE'	)

_oView:CreateHorizontalBox( 'SUPERIOR' , 25 )
_oView:CreateHorizontalBox( 'INFERIOR' , 75 )

_oView:SetOwnerView( 'VIEW_CABEC'	, 'SUPERIOR' )
_oView:SetOwnerView( 'VIEW_DET'		, 'INFERIOR' )

Return( _oView )

/*
===============================================================================================================================
Programa----------: ViewDef
Autor-------------: Alexandre Villar
Data da Criacao---: 19/11/2014
Descrição---------: Rotina para criação da view de dados para exibição na tela
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/

Static Function AGLT034LOK()

Local _aArea	:= FWGetArea()
Local _lRet		:= .T.

Local _oModel	:= FWModelActive()
Local _oModZZU	:= _oModel:GetModel( 'DETALHE' )
Local _cCodFor 	:= _oModZZU:GetValue( 'ZZU_FORNEC' )
Local _cLojFor	:= _oModZZU:GetValue( 'ZZU_LJFORN' )

If !_oModZZU:IsDeleted()
    
    DBSelectArea('SA2')
    SA2->( DBSetOrder(1) )
    If SA2->( DBSeek( xFilial('SA2') + _cCodFor + _cLojFor ) )
    	
    	If SA2->A2_MSBLQL == '1'
			Help(NIL, NIL, "AGLT03401", NIL, "O Fornecedor informado encontra-se Bloqueado ou Inativo no cadastro do Sistema!", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Verifique o cadastro do Fornecedor no Sistema ou os dados informados."})
			_lRet := .F.
    	Else
	    	_lRet := .T.
    	EndIf
    	
    Else
		Help(NIL, NIL, "AGLT03402", NIL, "Não foi encontrado o código de Fornecedor informado para o cadastro da Tabela de Frete!", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Verifique os dados informados."})
		_lRet := .F.
    EndIf
    
	If Empty( _oModZZU:GetValue( 'ZZU_KMFORN') )
		Help(NIL, NIL, "AGLT03403", NIL, "O Fornecedor informado é inválido para a Tabela de Frete!";
			, 1, 0, NIL, NIL, NIL, NIL, NIL, {"O Fornecedor deve ter o valor de KM atualizado em seu cadasto para poder ser utilizado na Tabela de Frete."})
		_lRet := .F.
	EndIf
	
	If _lRet
	
		If !Empty( _oModZZU:GetValue( 'ZZU_VLRKM') ) .And. !Empty( _oModZZU:GetValue( 'ZZU_VLRCOM') )
			Help(NIL, NIL, "AGLT03404", NIL, "Foram informados valores de KM e Preço Fixo Combinado ao mesmo tempo!", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Para cada item da tabela de Frete é obrigatório informar apenas uma regra de cobrança."})
			_lRet := .F.
		EndIf
		
		If Empty( _oModZZU:GetValue( 'ZZU_VLRKM') ) .And. Empty( _oModZZU:GetValue( 'ZZU_VLRCOM') )
			Help(NIL, NIL, "AGLT03405", NIL, "Não foram informados os valores de KM e Preço Fixo Combinado!", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Para cada item da tabela de Frete é obrigatório informar ao menos uma regra de cobrança."})
			_lRet := .F.
		EndIf
	
	EndIf
	
EndIf

FWRestArea( _aArea )

Return( _lRet )

/*
===============================================================================================================================
Programa----------: VALIDCOMIT
Autor-------------: Alexandre Villar
Data da Criacao---: 19/11/2014
Descrição---------: Rotina para validação de Tabela de Frete duplicada: Trasnportador + Loja + Capacidade
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function VALIDCOMIT()

Local _aArea	:= FWGetArea()
Local _cAlias	:= ''
Local _oModel	:= FWModelActive()
Local _nOper	:= _oModel:GetOperation()
Local _cTrans	:= _oModel:GetValue( 'CABEC' , 'ZZT_TRANSP' )
Local _cLjTra	:= _oModel:GetValue( 'CABEC' , 'ZZT_LJTRAN' )
Local _cCapac	:= _oModel:GetValue( 'CABEC' , 'ZZT_CAPACI' )
Local _lRet		:= .T.

If _nOper == MODEL_OPERATION_INSERT
	
	If !Empty( _cTrans ) .And. !Empty( _cLjTra )
	
		DBSelectArea('SA2')
		SA2->( DBSetOrder(1) )
		If SA2->( DBSeek( xFilial('SA2') + _cTrans + _cLjTra ) )
			
			If SA2->A2_MSBLQL == '1'
				Help(NIL, NIL, "AGLT03406", NIL, "O Fornecedor informado encontra-se Bloqueado ou Inativo no cadastro do Sistema!", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Verifique o cadastro do Fornecedor no Sistema ou os dados informados."})
				_lRet := .F.
			Else
				_cAlias := GetNextAlias()
	
				BeginSql alias _cAlias
					SELECT ZZT_TRANSP
					FROM  %Table:ZZT%
					WHERE D_E_L_E_T_ = ' '
					AND ZZT_FILIAL = %xFilial:ZZT%
					AND ZZT_TRANSP = %exp:_cTrans%
					AND ZZT_LJTRAN = %exp:_cLjTra%
					AND ZZT_CAPACI = %exp:_cCapac%
				EndSql
				
				If (_cAlias)->( !Eof() )
					Help(NIL, NIL, "AGLT03406", NIL, "Já existe uma tabela de Frete cadastrada para essa configuração de Fornecedor + Loja + Capacidade!";
						, 1, 0, NIL, NIL, NIL, NIL, NIL, {"Verifique os dados informados e caso necessário utilize a opção 'Alterar' no cadastro anterior."})
					_lRet := .F.
				EndIf      
				
				(_cAlias)->( DBCloseArea() )
		
			EndIf
		
		Else
			Help(NIL, NIL, "AGLT03407", NIL, "Não foi encontrado o código de Fornecedor informado para o cadastro da Tabela de Frete!";
				, 1, 0, NIL, NIL, NIL, NIL, NIL, {"Verifique os dados informados."})
			_lRet := .F.
		EndIf
	
	EndIf

EndIf

FWRestArea( _aArea )

Return( _lRet )

/*
===============================================================================================================================
Programa----------: AGLT034V
Autor-------------: Alexandre Villar
Data da Criacao---: 19/11/2014
Descrição---------: Rotina para validação de Tabela de Frete duplicada: Trasnportador + Loja + Capacidade
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT034V()

Local _cAlias	:= GetNextAlias()
Local _lRet		:= .T.
Local _oModel	:= FWModelActive()
Local _oModZZT	:= _oModel:GetModel('CABEC')
Local _cCodTra	:= _oModZZT:GetValue( 'ZZT_TRANSP' )
Local _cLojTra	:= _oModZZT:GetValue( 'ZZT_LJTRAN' )
Local _cCapaci	:= _oModZZT:GetValue( 'ZZT_CAPACI' )

If !Empty(_cCodTra) .And. !Empty(_cLojTra) .And. !Empty(_cCapaci)
	BeginSql alias _cAlias
		SELECT ZZT_TRANSP
		FROM  %Table:ZZT%
		WHERE D_E_L_E_T_ = ' '
		AND ZZT_FILIAL = %xFilial:ZZT%
		AND ZZT_TRANSP = %exp:_cCodTra%
		AND ZZT_LJTRAN = %exp:_cLojTra%
		AND ZZT_CAPACI = %exp:_cCapaci%
	EndSql		
	If (_cAlias)->( !Eof() )
		Help(NIL, NIL, "AGLT03408", NIL, "Já existe uma tabela de Frete cadastrada para essa configuração de Fornecedor + Loja + Capacidade!", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Verifique os dados informados e caso necessário utilize a opção 'Alterar' no cadastro anterior."})	
		_lRet := .F.
	EndIf

EndIf

Return( _lRet )

/*
===============================================================================================================================
Programa----------: AGLT034F
Autor-------------: Alexandre Villar
Data da Criacao---: 19/11/2014
Descrição---------: Rotina para validação do código de Fornecedor digitado na tela
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT034F( _nCampo )

Local _aArea	:= FWGetArea()
Local _lRet		:= .T.
Local _oModel	:= FWModelActive()
Local _cCodFor	:= ''
Local _cLojFor	:= ''

If _nCampo == 1
	
	_cCodFor	:= _oModel:GetValue( 'CABEC' , 'ZZT_TRANSP' )
	_cLojFor	:= _oModel:GetValue( 'CABEC' , 'ZZT_LJTRAN' )

Else
	
	_cCodFor	:= _oModel:GetValue( 'DETALHE' , 'ZZU_FORNEC' )
	_cLojFor	:= _oModel:GetValue( 'DETALHE' , 'ZZU_LJFORN' )
	
	If !Empty(_cCodFor) .And. ISDIGIT(_cCodFor)
		_cCodFor := 'P' + PadL( AllTrim(_cCodFor) , 5 , '0' )
	EndIf
	
EndIf

If !Empty( _cCodFor )

	DBSelectArea('SA2')
	SA2->( DBSetOrder(1) )
	If SA2->( DBSeek( xFilial('SA2') + _cCodFor + AllTrim( _cLojFor ) ) )
		_lRet := .T.
		If _nCampo == 2
			_oModel:LoadValue( 'DETALHE' , 'ZZU_FORNEC' , SA2->A2_COD  )
			_oModel:LoadValue( 'DETALHE' , 'ZZU_LJFORN' , SA2->A2_LOJA )
		EndIf
		
	Else
		Help(NIL, NIL, "AGLT03409", NIL, "Não foi encontrado o código de Fornecedor informado para o cadastro da Tabela de Frete!", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Verifique os dados informados."})
		_lRet := .F.
	EndIf

EndIf

FWRestArea( _aArea )

Return( _lRet )

/*
===============================================================================================================================
Programa----------: AGLT034INI
Autor-------------: Alexandre Villar
Data da Criacao---: 20/11/2014
Descrição---------: Rotina para validação inicial do modelo de dados
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT034INI( _oModel )

Local _lRet		:= .T.

//====================================================================================================
// Tratativa para não preencher campos na opção 'COPIAR'
//====================================================================================================
_oModel:GetModel( 'CABEC' ):AFLDNOCOPY := { 'ZZT_TRANSP' , 'ZZT_LJTRAN' , 'ZZT_NOMTRA' }

Return( _lRet )
