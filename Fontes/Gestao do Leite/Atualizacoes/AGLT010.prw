/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |17/01/2020| Chamado 31761. Corrigido totalizador do convênio.
Lucas Borges  |20/10/2020| Chamado 34436. Corrigida a exclusão de títulos.
Lucas Borges  |24/05/2022| Chamado 40201. Criada função para polular o grid de acordo com evento gerado no Mix.
===============================================================================================================================
*/

#Include "TOTVS.ch" 
#Include "FWMVCDEF.ch"

/*
===============================================================================================================================
Programa----------: AGLT010
Autor-------------: Alexandre Villar
Data da Criacao---: 13/03/2015
Descrição---------: Rotina para lançamentos dos convênios - Chamado 9296
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT010()

Local _oBrowse := Nil

_oBrowse := FWMBrowse():New()
_oBrowse:SetAlias('ZLL')
_oBrowse:SetDescription('Lançamentos dos Convênios')

_oBrowse:AddLegend( "ZLL_STATUS == 'A'" , 'GREEN'	, 'Convênio em aberto'	)
_oBrowse:AddLegend( "ZLL_STATUS == 'P'" , 'RED'		, 'Convênio pago'		)
_oBrowse:AddLegend( "ZLL_STATUS == 'S'" , 'BLUE'	, 'Convênio Suspenso'	)

_oBrowse:Activate()

Return

/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Alexandre Villar
Data da Criacao---: 13/03/2015
Descrição---------: Retorna o menu funcional para a rotina principal
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MenuDef()

Local _aRotina := {}

ADD OPTION _aRotina Title 'Visualizar'	Action 'VIEWDEF.AGLT010' OPERATION 2 ACCESS 0
ADD OPTION _aRotina Title 'Incluir'		Action 'VIEWDEF.AGLT010' OPERATION 3 ACCESS 0
ADD OPTION _aRotina Title 'Alterar'		Action 'VIEWDEF.AGLT010' OPERATION 4 ACCESS 0
ADD OPTION _aRotina Title 'Excluir'		Action 'VIEWDEF.AGLT010' OPERATION 5 ACCESS 0
ADD OPTION _aRotina Title 'Copiar'		Action 'VIEWDEF.AGLT010' OPERATION 9 ACCESS 0

Return( _aRotina )

/*
===============================================================================================================================
Programa----------: ModelDef
Autor-------------: Alexandre Villar
Data da Criacao---: 13/03/2015
Descrição---------: Monta o Modelo de dados
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ModelDef()

Local _oStruCAB	:= FWFormStruct( 1 , 'ZLL' , { |_cCampo| AGLT010CPO( _cCampo , 1 ) } )
Local _oStruITN	:= FWFormStruct( 1 , 'ZLL' , { |_cCampo| AGLT010CPO( _cCampo , 2 ) } )
Local _oModel	:= Nil
Local _aGatAux	:= {}

_aGatAux := FwStruTrigger( 'ZLL_SETOR'	, 'ZLL_COD'		, 'M->ZLL_COD'	, .F. )
_oStruCAB:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLL_SETOR'	, 'ZLL_VENCTO'	, 'SToD( SubStr( DToS( MonthSum( Date() , 1 ) ) , 1 , 6 ) + StrZero( SuperGetMV("LT_VENCONV",.F.,20), 2 ) )' , .F. )
_oStruCAB:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLL_SETOR'	, 'ZLL_DESSET'	, 'ZL2->ZL2_DESCRI'	, .T. , 'ZL2' , 1 , 'xFilial("ZL2")+M->ZLL_SETOR'	)
_oStruCAB:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLL_EVENTO'	, 'ZLL_DESEVE'	, 'ZL8->ZL8_DESCRI'	, .T. , 'ZL8' , 1 , 'xFilial("ZL8")+M->ZLL_EVENTO'	)
_oStruCAB:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLL_EVENTO'	, 'ZLL_DESEVE'	, 'U_GL010RET( 4 , M->ZLL_EVENTO  )'	, .F.	)
_oStruCAB:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLL_CONVEN'	, 'ZLL_DESCRI'	, 'SA2->A2_NOME'	, .T. , 'SA2' , 1 , 'xFilial("SA2")+M->ZLL_CONVEN+AllTrim(M->ZLL_LJCONV)' )
_oStruCAB:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLL_CONVEN'	, 'ZLL_LJCONV'	, 'IIf( Empty(M->ZLL_LJCONV) , "0001" , M->ZLL_LJCONV )'	, .F. )
_oStruCAB:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLL_LJCONV'	, 'ZLL_DESCRI'	, 'SA2->A2_NOME'	, .T. , 'SA2' , 1 , 'xFilial("SA2")+M->ZLL_CONVEN+AllTrim(M->ZLL_LJCONV)' )
_oStruCAB:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLL_CONVEN'	, 'ZLL_PERADM'	, 'SA2->A2_L_TXADM'	, .T. , 'SA2' , 1 , 'xFilial("SA2")+M->ZLL_CONVEN+AllTrim(M->ZLL_LJCONV)' )
_oStruCAB:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLL_LJCONV'	, 'ZLL_PERADM'	, 'SA2->A2_L_TXADM'	, .T. , 'SA2' , 1 , 'xFilial("SA2")+M->ZLL_CONVEN+AllTrim(M->ZLL_LJCONV)' )
_oStruCAB:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLL_RETIRO'	, 'ZLL_RETIRO'	, 'U_GL010RET( 1 , M->ZLL_RETIRO )' , .F. )
_oStruITN:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLL_RETIRO'	, 'ZLL_RETILJ'	, 'U_GL010RET( 2 , M->ZLL_RETIRO , M->ZLL_RETILJ )' , .F. )
_oStruITN:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLL_RETIRO'	, 'ZLL_RETILJ'	, 'U_GL010RET( 3 , M->ZLL_RETIRO , M->ZLL_RETILJ )' , .F. )
_oStruITN:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLL_RETIRO'	, 'ZLL_DCRRET'	, 'SA2->A2_NOME'	, .T. , 'SA2' , 1 , 'xFilial("SA2")+M->ZLL_RETIRO+AllTrim(M->ZLL_RETILJ)' )
_oStruITN:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLL_RETILJ'	, 'ZLL_DCRRET'	, 'SA2->A2_NOME'	, .T. , 'SA2' , 1 , 'xFilial("SA2")+M->ZLL_RETIRO+AllTrim(M->ZLL_RETILJ)' )
_oStruITN:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLL_VALOR'	, 'ZLL_VALOR'	, 'U_GL010LOK( M->ZLL_VALOR )' , .F. )
_oStruITN:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_oModel := MPFormModel():New( 'AGLT010M' ,, {|| AGLT010TOK() } )

_oModel:SetDescription( 'Lançamentos dos Convênios' )

_oModel:AddFields(	"ZLLMASTER" , /*cOwner*/  , _oStruCAB )
_oModel:AddGrid(	"ZLLDETAIL" , "ZLLMASTER" , _oStruITN , { | _oModel , _nLine , _cAction , _cField | AGLT010LOK( _nLine , _cAction , _cField ) } )

_oModel:SetRelation( "ZLLDETAIL" , {	{ 'ZLL_FILIAL'	, 'xFilial("ZLL")'	} ,;
										{ 'ZLL_COD'		, 'ZLL_COD'			} }, ZLL->( IndexKey( 1 ) ) )

_oModel:GetModel( 'ZLLDETAIL' ):SetUniqueLine( { 'ZLL_SEQ' } )

_oModel:GetModel( "ZLLMASTER" ):SetDescription( "Dados do Convênio"		)
_oModel:GetModel( "ZLLDETAIL" ):SetDescription( "Itens do Lançamento"	)

_oModel:SetPrimaryKey( { 'ZLL_FILIAL' , 'ZLL_COD' , 'ZLL_SEQ' } )

_oModel:GetModel( 'ZLLMASTER' ):AFLDNOCOPY := { 'ZLL_SETOR' , 'ZLL_DESSET' , 'ZLL_DATA' , 'ZLL_VENCTO' }
_oModel:GetModel( 'ZLLDETAIL' ):AFLDNOCOPY := { 'ZLL_STATUS' }

//==================================
// Define validação inical do modelo
//==================================
_oModel:SetVldActivate( { |_oModel| AGLT010VLD( _oModel ) } )

Return( _oModel )

/*
===============================================================================================================================
Programa----------: ViewDef
Autor-------------: Alexandre Villar
Data da Criacao---: 13/03/2015
Descrição---------: Define a View de dados para a rotina de cadastro
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ViewDef()

Local _oModel  	:= FWLoadModel( 'AGLT010' )
Local _oStruCAB	:= FWFormStruct( 2 , 'ZLL' , { |cCampo| AGLT010CPO( cCampo , 1 ) } )
Local _oStruITN	:= FWFormStruct( 2 , 'ZLL' , { |cCampo| AGLT010CPO( cCampo , 2 ) } )
Local _oView	:= Nil

//=========================================
// Configuração para agrupamento dos campos
//=========================================
_oStruCAB:AddGroup( 'GRUPO01' , 'Convênio'						, '' , 2 )
_oStruCAB:AddGroup( 'GRUPO02' , 'Valores do Convênio'			, '' , 2 )

_oStruCAB:SetProperty( 'ZLL_COD'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO01' )
_oStruCAB:SetProperty( 'ZLL_SETOR'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO01' )
_oStruCAB:SetProperty( 'ZLL_DESSET'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO01' )
_oStruCAB:SetProperty( 'ZLL_NATURE'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO01' )
_oStruCAB:SetProperty( 'ZLL_EVENTO'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO01' )
_oStruCAB:SetProperty( 'ZLL_DESEVE'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO01' )
_oStruCAB:SetProperty( 'ZLL_CONVEN'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO01' )
_oStruCAB:SetProperty( 'ZLL_LJCONV'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO01' )
_oStruCAB:SetProperty( 'ZLL_DESCRI'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO01' )
_oStruCAB:SetProperty( 'ZLL_DATA'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO01' )
_oStruCAB:SetProperty( 'ZLL_VENCTO'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO01' )

_oStruCAB:SetProperty( 'ZLL_VALTOT'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO02' )
_oStruCAB:SetProperty( 'ZLL_VLRABR'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO02' )
_oStruCAB:SetProperty( 'ZLL_ACRESC'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO02' )
_oStruCAB:SetProperty( 'ZLL_PERADM'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO02' )
_oStruCAB:SetProperty( 'ZLL_VTXADM'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO02' )

_oView := FWFormView():New()

_oView:SetModel( _oModel )
_oView:AddField( "VIEW_CAB"	, _oStruCAB	, "ZLLMASTER" )
_oView:AddGrid(  "VIEW_ITN"	, _oStruITN	, "ZLLDETAIL" )

_oView:CreateHorizontalBox( 'BOX0101' , 55 )
_oView:CreateHorizontalBox( 'BOX0102' , 45 )
_oView:SetOwnerView( "VIEW_CAB" , "BOX0101" )
_oView:SetOwnerView( "VIEW_ITN" , "BOX0102" )

_oView:AddIncrementField( 'VIEW_ITN' , 'ZLL_SEQ' )

_oView:addUserButton('Vinc. Prod.', 'CONTAINER', {|| AGLT010P() } )

Return( _oView )

/*
===============================================================================================================================
Programa----------: AGLT010CPO
Autor-------------: Alexandre Villar
Data da Criacao---: 13/03/2015
Descrição---------: Define a organização dos campos para exibição na tela
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT010CPO( _cCampo , _nOpc )

Local _lRet := Upper( AllTrim(_cCampo) ) $ 'ZLL_FILIAL/ZLL_COD/ZLL_SETOR/ZLL_DESSET/ZLL_EVENTO/ZLL_DESEVE/ZLL_CONVEN/ZLL_LJCONV/ZLL_DESCRI/ZLL_DATA/ZLL_VENCTO/ZLL_NATURE/ZLL_VALTOT/ZLL_VLRABR/ZLL_ACRESC/ZLL_PERADM/ZLL_VTXADM'

If _nOpc == 2
	_lRet := !_lRet
EndIf

Return( _lRet )

/*
===============================================================================================================================
Programa----------: GL010LOK
Autor-------------: Alexandre Villar
Data da Criacao---: 13/03/2015
Descrição---------: Rotina para Atualização dos valores conforme preenchimento dos campos das linhas
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function GL010LOK( _nValRet )

Local _oModel	:= FWModelActive()
Local _aSaveLines := FWSaveRows()
Local _oZLLDET	:= _oModel:GetModel( 'ZLLDETAIL' )
Local _nI		:= 0
Local _nValor	:= 0
Local _nValAbr	:= 0
Local _nValAdm	:= 0
Local _nValTot	:= 0
Local _nTxAdm	:= _oModel:GetValue( 'ZLLMASTER' , 'ZLL_PERADM' )

For _nI := 1 To _oZLLDET:Length()
	
	_oZLLDET:GoLine( _nI )
	If !_oZLLDET:IsDeleted()
		_nValor		:= _oZLLDET:GetValue( 'ZLL_VALOR' )
		_nValTot	+= _nValor
			
		_oModel:SetValue( 'ZLLDETAIL' , 'ZLL_TXADM' , _nValor * ( _nTxAdm / 100 ) )
		_nValAdm	+= _oZLLDET:GetValue( 'ZLL_TXADM' )
			
		If _oZLLDET:GetValue( 'ZLL_STATUS' ) == 'A'
			_nValAbr += _nValor
		EndIf
	EndIf	
Next _nI

_oModel:LoadValue( 'ZLLMASTER' , 'ZLL_VALTOT' , _nValTot )
_oModel:LoadValue( 'ZLLMASTER' , 'ZLL_VTXADM' , _nValAdm )
_oModel:LoadValue( 'ZLLMASTER' , 'ZLL_VLRABR' , _nValAbr )
FWRestRows( _aSaveLines )

Return( _nValRet )

/*
===============================================================================================================================
Programa----------: AGLT010LOK
Autor-------------: Alexandre Villar
Data da Criacao---: 13/03/2015
Descrição---------: Rotina para validação das operações de alteração/delete das linhas de lançamentos
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT010LOK(_nLine , _cAction , _cField )

Local _lRet		:= .T.
Local _oModel	:= FWModelActive()
Local _nValor	:= 0
Local _nValTX	:= 0
Local _nValTot	:= 0
Local _nValTXA	:= 0

If _oModel:GetValue( 'ZLLDETAIL' , 'ZLL_STATUS' ) == 'A'

	If Upper(AllTrim(_cAction)) $ 'DELETE/UNDELETE'
	
		_nValor		:= _oModel:GetValue( 'ZLLDETAIL' , 'ZLL_VALOR' )
		_nValTX		:= _oModel:GetValue( 'ZLLDETAIL' , 'ZLL_TXADM' )
		_nValTot	:= _oModel:GetValue( 'ZLLMASTER' , 'ZLL_VALTOT' )
		_nValABR	:= _oModel:GetValue( 'ZLLMASTER' , 'ZLL_VLRABR' )
		_nValTXA	:= _oModel:GetValue( 'ZLLMASTER' , 'ZLL_VTXADM' )
	
		If Upper(AllTrim(_cAction)) == 'DELETE'
		
			_oModel:LoadValue( 'ZLLMASTER' , 'ZLL_VTXADM' , _nValTXA - _nValTX )
			_oModel:LoadValue( 'ZLLMASTER' , 'ZLL_VLRABR' , _nValABR - _nValor )
			_oModel:LoadValue( 'ZLLMASTER' , 'ZLL_VALTOT' , _nValTot - _nValor )
			
		Else
		
			_oModel:LoadValue( 'ZLLMASTER' , 'ZLL_VTXADM' , _nValTXA + _nValTX )
			_oModel:LoadValue( 'ZLLMASTER' , 'ZLL_VLRABR' , _nValABR + _nValor )
			_oModel:LoadValue( 'ZLLMASTER' , 'ZLL_VALTOT' , _nValTot + _nValor )
			
		EndIf
	
	EndIf
	
Else
	_oModel:SetErrorMessage('ZLLDETAIL', 'ZLL_STATUS' , 'ZLLDETAIL' , 'ZLL_STATUS' , "AGLT01001", "Não é possível realizar a operação no registro atual!", "Somente registros 'Em Aberto' podem ser alterados, excluídos ou restaurados.")
	_lRet := .F.
EndIf
	
Return( _lRet )

/*
===============================================================================================================================
Programa----------: GL010RET
Autor-------------: Alexandre Villar
Data da Criacao---: 13/03/2015
Descrição---------: Rotina auxiliar para processamento dos gatilhos
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function GL010RET( _nOpcao , _cRetiro , _cLoja )

Local _cRet		:= ''
Local _oModel	:= FWModelActive()

If _nOpcao == 1

	If Val( AllTrim( _cRetiro ) ) > 0 .And. Len( AllTrim( _cRetiro ) ) < 6
		_cRetiro := 'P' + PadL( AllTrim( _cRetiro ) , 5 , '0' )
	EndIf

	DBSelectArea('SA2')
	SA2->( DBSetOrder(1) )
	If SA2->( DBSeek( xFilial('SA2') + _cRetiro ) )
	
		_oModel:LoadValue( 'ZLLDETAIL' , 'ZLL_RETIRO' , SA2->A2_COD )
		_cRet := SA2->A2_COD
		
	Else
		_oModel:SetErrorMessage('ZLLDETAIL', 'ZLL_RETIRO' , 'ZLLDETAIL' , 'ZLL_RETIRO' , "AGLT01002", "O Produtor informado não é válido ou não foi encontrado no Sistema!", "Verifique os dados digitados e tente novamente.")
	    _oModel:LoadValue( 'ZLLDETAIL' , 'ZLL_RETIRO' , '' )
	EndIf

ElseIf _nOpcao == 2
	
	DBSelectArea('SA2')
	SA2->( DBSetOrder(1) )
	If SA2->( DBSeek( xFilial('SA2') + _cRetiro + AllTrim( _cLoja ) ) )
	    
		_oModel:LoadValue( 'ZLLDETAIL' , 'ZLL_RETILJ' , SA2->A2_LOJA )
		_cRet := SA2->A2_LOJA
		
	Else
		_oModel:SetErrorMessage('ZLLDETAIL', 'ZLL_RETILJ' , 'ZLLDETAIL' , 'ZLL_RETILJ' , "AGLT01003", "O Produtor informado não é válido ou não foi encontrado no Sistema!", "Verifique os dados digitados e tente novamente.")
	    _oModel:LoadValue( 'ZLLDETAIL' , 'ZLL_RETILJ' , '' )
	EndIf 
	
ElseIf _nOpcao == 3


	DBSelectArea('ZL8')
	ZL8->( DBSetOrder(1) )
	If ZL8->( DBSeek( xFilial('ZL8') + M->ZLL_EVENTO ) )
	    
		If SubStr(_cRetiro,1,1) = 'G' //Natureza para fretista
			_oModel:LoadValue( 'ZLLMASTER' , 'ZLL_NATURE' , ZL8->ZL8_NATFRT )
			_cRet := _cLoja
		Else
			_oModel:LoadValue( 'ZLLMASTER' , 'ZLL_NATURE' , ZL8->ZL8_NATPRD )
			_cRet := _cLoja
		EndIf
		
	EndIf

ElseIf _nOpcao == 4


  _cret := ZL8->ZL8_DESCRI  
  
  If Len(_omodel:AALLSUBMODELS[2]:ACOLS) > 0 .And. Len(AllTrim(_omodel:AALLSUBMODELS[2]:ACOLS[1][2])) == 6

  		If SubStr(AllTrim(_omodel:AALLSUBMODELS[2]:ACOLS[1][2]),1,1) = 'G' //Natureza para fretista
			_oModel:LoadValue( 'ZLLMASTER' , 'ZLL_NATURE' , ZL8->ZL8_NATFRT )
		Else
			_oModel:LoadValue( 'ZLLMASTER' , 'ZLL_NATURE' , ZL8->ZL8_NATPRD )
		EndIf

	EndIf

EndIf

Return( _cRet )

/*
===============================================================================================================================
Programa----------: AGLT010TOK
Autor-------------: Alexandre Villar
Data da Criacao---: 13/03/2015
Descrição---------: Rotina para Validação Total do modelo de dados e gravações auxiliares
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT010TOK()

Local _lRet		:= .T.
Local _aValid	:= {}
Local _aMovPer	:= {}
Local _oModel	:= FWModelActive()
Local _oGrid	:= _oModel:GetModel( 'ZLLDETAIL' )
Local _cCodigo	:= _oModel:GetValue( 'ZLLMASTER' , 'ZLL_COD'    )
Local _cConven	:= _oModel:GetValue( 'ZLLMASTER' , 'ZLL_CONVEN' )
Local _cLjConv	:= _oModel:GetValue( 'ZLLMASTER' , 'ZLL_LJCONV' )
Local _nVlrTot	:= _oModel:GetValue( 'ZLLMASTER' , 'ZLL_VALTOT' )
Local _nAcresc	:= _oModel:GetValue( 'ZLLMASTER' , 'ZLL_ACRESC' )
Local _nTxAdm	:= _oModel:GetValue( 'ZLLMASTER' , 'ZLL_VTXADM' )
Local _cLinha	:= ''
Local _cSetor	:= _oModel:GetValue( 'ZLLMASTER' , 'ZLL_SETOR'  )
Local _cCodPro	:= ''
Local _cLojPro	:= ''
Local _cNatAux	:= ''
Local _cPrefix	:= ''
Local _dEmissa	:= _oModel:GetValue( 'ZLLMASTER' , 'ZLL_DATA'   )
Local _dVencto	:= _oModel:GetValue( 'ZLLMASTER' , 'ZLL_VENCTO' )
Local _cEvento	:= _oModel:GetValue( 'ZLLMASTER' , 'ZLL_EVENTO' )
Local _dDatIni	:= SToD( SubStr( DToS( MonthSub( _dVencto , 1 ) ) , 1 , 6 ) + '01' )
Local _dDatFim	:= LastDay( MonthSub( _dVencto , 1 ) )
Local _nLinhas	:= 0
Local _nI, _nX	:= 0
Local _cSeq		:= ''
Local _nValor	:= 0
Local _cStatus	:= ''

Local _lParc	:= .F.
Local _aParAux	:= {}
Local _aDados	:= {}

//=============================================
// Validação do convênio no cadastro do Sistema
//=============================================
DBSelectArea("SA2")
SA2->( DBSetOrder(1) )
If SA2->( DBSeek(xFilial("SA2") + _cConven + _cLjConv ) )
	
	If SA2->A2_MSBLQL == '1'
		_oModel:SetErrorMessage('ZLLMASTER', 'ZLL_CONVEN' , 'ZLLMASTER' , 'ZLL_CONVEN' , "AGLT01004", "O convênio informado está bloqueado no cadastro de Fornecedores do Sistema!", "Verifique o cadastro do convênio ou os dados informados para confirmar.")
		_lRet := .F.
	EndIf
	
	If _lRet .And. SA2->A2_L_ATIVO == 'N'
		_oModel:SetErrorMessage('ZLLMASTER', 'ZLL_CONVEN' , 'ZLLMASTER' , 'ZLL_CONVEN' , "AGLT01005", "O convênio informado está inativo no cadastro de Fornecedores do Sistema!", "Verifique o cadastro do convênio ou os dados informados para confirmar.")
		_lRet := .F.
	EndIf

Else
	_oModel:SetErrorMessage('ZLLMASTER', 'ZLL_CONVEN' , 'ZLLMASTER' , 'ZLL_CONVEN' , "AGLT01006", "O convênio informado não foi encontrado no cadastro de Fornecedores do Sistema!", "Verifique o cadastro do convênio ou os dados informados para confirmar.")
	_lRet := .F.
EndIf

//==========================================================
// Validação do cadastro de Setor na Filial de processamento
//==========================================================
If _lRet
	
	DBSelectArea('ZL2')
	ZL2->( DBSetOrder(1) )
	_lRet := ZL2->( DBSeek( xFilial('ZL2') + _cSetor ) )
	ZL2->(DBCloseArea())
	
	If !_lRet
		_oModel:SetErrorMessage('ZLLMASTER', 'ZLL_SETOR' , 'ZLLMASTER' , 'ZLL_SETOR' , "AGLT01007", "O Setor informado não é válido para a Filial atual do Sistema!", "Verifique o cadastro do Setor ou informe um Setor válido para confirmar.")
	EndIf

EndIf

If _lRet

	//============================================
	// Validação das datas de Emissão x Vencimento
	//============================================
	If _dEmissa > _dVencto
		_oModel:SetErrorMessage('ZLLMASTER', 'ZLL_VENCTO' , 'ZLLMASTER' , 'ZLL_VENCTO' , "AGLT01008", "A data de vencimento do convênio não é válida!", "O vencimento deve ser maior ou igual à data de emissão do convênio.")
		_lRet := .F.
	EndIf
	
	//===========================================================
	// Validação do preenchimento de todos os campos obrigatórios
	//===========================================================
	If _lRet .And. ( Empty(_cSetor) .Or. Empty(_cConven) .Or. Empty(_cLjConv) .Or. Empty( _dEmissa ) .Or. Empty( _dVencto ) .Or. Empty( _cEvento ) )
		_oModel:SetErrorMessage('ZLLMASTER', 'ZLL_SETOR' , 'ZLLMASTER' , 'ZLL_SETOR' , "AGLT01009", "Existem campos do convênio que não foram preenchidos!", "Verifique os dados e informe todos os campos obrigatórios para confirmar.")
		_lRet := .F.
	EndIf
	
	If _lRet
		
		//==========================================
		// Validação do Evento informado no Convênio
		//==========================================
		DBSelectArea("ZL8")
		ZL8->( DBSetOrder(1) )
		If ZL8->( DBSeek( xFilial("ZL8") + _cEvento ) )
			
			If _oModel:GetValue( 'ZLLMASTER' , 'ZLL_CONVEN' ) == ZL8->ZL8_FORCON .And. _oModel:GetValue( 'ZLLMASTER' , 'ZLL_LJCONV' ) == ZL8->ZL8_LOJCON
				If Empty(ZL8->ZL8_NATPRD) .Or. Empty(ZL8->ZL8_NATFRT)
					_oModel:SetErrorMessage('ZLLMASTER', 'ZLL_EVENTO' , 'ZLLMASTER' , 'ZLL_EVENTO' , "AGLT01010", "O evento informado não possui naturezas cadastradas!", "Verifique o cadastro do evento e informe um evento válido para o convênio.")
					_lRet := .F.
				EndIf
		
				If ZL8->ZL8_MSBLQL == '1' .And. _lRet
					_oModel:SetErrorMessage('ZLLMASTER', 'ZLL_EVENTO' , 'ZLLMASTER' , 'ZLL_EVENTO' , "AGLT01011", "O evento informado encontra-se bloqueado no cadastro do Sistema!", "Verifique o cadastro do evento e informe um evento válido para o convênio.")
					_lRet := .F.
				Else
					If ZL8->ZL8_TPEVEN <> "F" .Or. Empty( ZL8->ZL8_PREFIX ) .Or. ZL8->ZL8_DEBCRE <> "D"
						_oModel:SetErrorMessage('ZLLMASTER', 'ZLL_EVENTO' , 'ZLLMASTER' , 'ZLL_EVENTO' , "AGLT01012", "O evento informado é inválido para o lançamento de Convênios!", "O evento deve ser Financeiro, de Débito e possuir Prefixo.")
						_lRet := .F.
					EndIf
				EndIf
			Else
				_oModel:SetErrorMessage('ZLLMASTER', 'ZLL_EVENTO' , 'ZLLMASTER' , 'ZLL_EVENTO' , "AGLT01036", "Evento vinculado não pertence ao forncedor informado.")
				_lRet := .F.
			EndIf
		Else
			_oModel:SetErrorMessage('ZLLMASTER', 'ZLL_EVENTO' , 'ZLLMASTER' , 'ZLL_EVENTO' , "AGLT01013", "O evento informado não foi encontrado no cadastro do Sistema!", "Verifique o código informado.")
			_lRet := .F.
		EndIf

	EndIf
	
EndIf

If _lRet
	
	_nLinhas := _oGrid:Length()
	
	//========================================================
	// Validação das linhas do Grid de lançamentos do convênio
	//========================================================
	For _nI := 1 To _nLinhas
		
		_oGrid:GoLine(_nI)
		
		//==========================================
		// Validação apenas nas linhas não deletadas
		//==========================================
		If !( _oGrid:IsDeleted() )
		
			_cCodPro	:= _oGrid:GetValue( 'ZLL_RETIRO' )
			_cLojPro	:= _oGrid:GetValue( 'ZLL_RETILJ' )
			_cNomPro	:= Posicione( 'SA2' , 1 , xFilial('SA2') + _cCodPro + _cLojPro , 'A2_NOME' )
			_cLinha		:= SA2->A2_L_LI_RO
			
			If Empty( _cCodPro ) .Or. Empty( _cLojPro ) .Or. Empty( _cNomPro )
				_oModel:SetErrorMessage('ZLLDETAIL', 'ZLL_RETIRO' , 'ZLLDETAIL' , 'ZLL_RETIRO' , "AGLT01014", "É obrigatório informar um produtor para todas os lançamentos do Convênio!", "Verifique os lançamentos e informe produtores válidos para todas as linhas.")
				_lRet := .F.
				Exit
			EndIf
			
			If SA2->A2_MSBLQL == '1'
				aAdd( _aValid , { _cCodPro+'/'+_cLojPro , _cNomPro , 'O fornecedor encontra-se bloqueado no cadastro do Sistema' } )
			EndIf
			
			If SA2->A2_L_ATIVO == 'N'
				aAdd( _aValid , { _cCodPro+'/'+_cLojPro , _cNomPro , 'O fornecedor encontra-se inativo no cadastro do Sistema' } )
			EndIf

			If _oGrid:GetValue( 'ZLL_VALOR' ) <= 0
				aAdd( _aValid , { _cCodPro+'/'+_cLojPro , _cNomPro , 'Não foi informado um valor válido para o lançamento do convênio' } )
			EndIf
			
			If Left( _cCodPro , 1 ) == 'P'
			
				If Empty(_cLinha)
					aAdd( _aValid , { _cCodPro+'/'+_cLojPro , _cNomPro , 'O fornecedor é um Produtor e não possui uma Linha/Rota no cadastro do Sistema' } )
				EndIf
				
				DBSelectArea('ZL3')
				ZL3->( DBSetOrder(1) )
				If ZL3->( DBSeek( xFilial('ZL3') + _cLinha ) )
				
					If ZL3->ZL3_SETOR <> _cSetor
						aAdd( _aValid , { _cCodPro+'/'+_cLojPro , _cNomPro , 'O Setor do Produtor é diferente do informado para o convênio' } )
					EndIf
					
				Else
					aAdd( _aValid , { _cCodPro+'/'+_cLojPro , _cNomPro , 'A Linha/Rota do Produtor no cadastro do Sistema é inválida' } )
				EndIf
				
				If U_VolLeite( xFilial("ZLL") , _dDatIni , _dDatFim , _cSetor ,, _cCodPro , _cLojPro , "" ) <= 0
					aAdd( _aMovPer , { _cCodPro+'/'+_cLojPro , _cNomPro , 'O produtor não possui movimentação de Leite no período' } )
				EndIf
				
			Else
			
				If U_VolFret( xFilial("ZLL") , _cSetor ,, _cCodPro , _cLojPro , _dDatIni , _dDatFim , 1 ) <= 0
					aAdd( _aMovPer , { _cCodPro+'/'+_cLojPro , _cNomPro , 'O Fretista não possui movimentação de Leite no período' } )
				EndIf
			
			EndIf
			
		EndIf
			
	Next _nI

EndIf

If _lRet .And. !Empty( _aValid ) .And. _oModel:GetOperation() <> MODEL_OPERATION_DELETE
	
	U_ITListBox( 'Não conformidades nos lançamentos' , { 'Código' , 'Nome' , 'Avaliação' } , _aValid , .F. , 1 , 'Verifique os lançamentos abaixo:' ,, {50,100,200} )
	_oModel:SetErrorMessage('ZLLDETAIL', 'ZLL_RETIRO' , 'ZLLDETAIL' , 'ZLL_RETIRO' , "AGLT01015", "Existem lançamentos que não passaram na validação!", "Verifique os dados do relatório exibido e corrija os lançamentos com problema.")
	_lRet := .F.
	
EndIf

If _lRet .And. !Empty( _aMovPer ) .And. _oModel:GetOperation() <> MODEL_OPERATION_DELETE
	
	_lRet := U_ITListBox( 'Produtores sem movimentação no período' , { 'Código' , 'Nome' , 'Avaliação' } , _aMovPer , .F. , 1 , 'Verifique os lançamentos abaixo:' ,, {50,100,200} )
	
	If !_lRet
		_oModel:SetErrorMessage('ZLLDETAIL', 'ZLL_RETIRO' , 'ZLLDETAIL' , 'ZLL_RETIRO' , "AGLT01016", "Foi cancelada a operação por conta de produtores sem movimentação no período!", "Verifique os dados e caso necessário confirme mesmo com produtores sem movimentação para continuar.")
	EndIf
	
EndIf

//================================================================
// Se passar pelas validações Processa as gravações complementares
//================================================================
If _lRet
	
	_nOper		:= _oModel:GetOperation()
	_cNumTit	:= _oModel:GetValue( 'ZLLMASTER' , 'ZLL_COD'    )
	_cNatNDF	:= _oModel:GetValue( 'ZLLMASTER' , 'ZLL_NATURE' )
	
	_cNatAux	:= Posicione( "ZL8" , 1 , xFilial("ZL8") + _cEvento , "ZL8_NATPRD" ) ; IIf( Empty(_cNatAux) , _cNatAux := _cNatNDF , Nil )
	_cPrefix	:= ZL8->ZL8_PREFIX
	
	If _nOper == MODEL_OPERATION_INSERT
		
		If MsgYesNo("Deseja replicar e criar novas parcelas iguais a configuração do convênio atual para meses posteriores?","AGLT01017" )
			
			_lParc := .F.
			
			_aParAux := AGLT010CPA( _dVencto )
			
			If Empty(_aParAux)
				_oModel:SetErrorMessage('ZLLMASTER', 'ZLL_NATURE' , 'ZLLMASTER' , 'ZLL_NATURE' , "AGLT01018", "A geração de parcelas não foi realizada pelo usuário e será gerado apenas o registro do convênio!", "Caso necessário, revise os dados informados.")
			Else
				_lParc := .T.
			EndIf
		
		EndIf
		
	EndIf
	
	_lsai := .F.
	Begin Sequence
	Begin Transaction
	
	//==============================================================
	// Se For Alteração ou Exclusão exclui o título Financeiro da NF
	//==============================================================
	If _nOper == MODEL_OPERATION_UPDATE .Or. _nOper == MODEL_OPERATION_DELETE
		//Faço a exclusão com base no dados gravados na tabela e não nos novos
	    ZL8->(DBSeek(ZLL->(ZLL_FILIAL+ZLL_EVENTO)))
	    _lRet := AGLT010DE2( ZL8->ZL8_PREFIX , _cNumTit + '000' , '1 ' , 'NF ' , ZLL->ZLL_CONVEN , ZLL->ZLL_LJCONV , ZLL->ZLL_NATURE, _oModel )
		
		If _lRet
			If _nOper == MODEL_OPERATION_UPDATE
				MsgInfo("O Titulo da NF foi excluido e será gerado novamente com os novos valores!","AGLT01019")
			EndIf
		EndIf
	
	EndIf
	
	If _lRet
	
		//======================
		// Guarda posição do ZLL
		//======================
		_aareaZLL := getarea("ZLL")
		
		//=========================================================
		// Gravação dos títulos de todos os lançamentos do convênio
		//=========================================================
		For _nI := 1 To _nLinhas
		
			_oGrid:GoLine(_nI)
			
			_cSeq		:= _oGrid:GetValue( 'ZLL_SEQ'    )
			_cCodPrd	:= _oGrid:GetValue( 'ZLL_RETIRO' )
			_cLojPrd	:= _oGrid:GetValue( 'ZLL_RETILJ' )
			_nValor		:= _oGrid:GetValue( 'ZLL_VALOR'  )
			_cStatus	:= _oGrid:GetValue( 'ZLL_STATUS' )
			
			//===============================================
			// Posiciona ZLL para saber o que alterou na tela
			//===============================================
			ZLL->(DBSetOrder(1))
			ZLL->(DBSeek(xFilial("ZLL") + _cCodigo + _cSeq))
			
			//================================================
			// Tratativa para os lançamentos deletados no Grid
			//================================================
			If _oGrid:IsDeleted() .And. _nOper == MODEL_OPERATION_UPDATE
				_lRet := AGLT010DE2( ZL8->ZL8_PREFIX , _cNumTit + _cSeq , '1 ' , 'NDF' , ZLL->ZLL_RETIRO , ZLL->ZLL_RETILJ , ZLL->ZLL_NATURE, _oModel )
			ElseIf  !(_oGrid:IsDeleted())
			
				//==========================================
				// Na Inclusão gera os títulos no Financeiro
				//==========================================
				If _nOper == MODEL_OPERATION_INSERT 
					_lRet := AGLT010IE2( _cPrefix , _cNumTit + _cSeq , '1 ' , 'NDF' , _cCodPrd , _cLojPrd , _cNatNDF , _dEmissa , _dVencto , _nValor , 0 , 0 , _cSetor, _oModel )
				EndIf
				
				//=======================================================
				// Tratativa para os lançamentos na operação de alteração
				//=======================================================
				If _nOper == MODEL_OPERATION_UPDATE
					
					//========================================================
					// Se a linha For "Suspensa" deleta o título no Financeiro
					//========================================================
					If _oGrid:GetValue('ZLL_STATUS') == 'S'
					
						_lRet := AGLT010DE2( ZL8->ZL8_PREFIX , _cNumTit + _cSeq , '1 ' , 'NDF' , ZLL->ZLL_RETIRO , ZLL->ZLL_RETILJ , ZLL->ZLL_NATURE, _oModel )
					
					//=================================================================================================
					// Se a linha For "Alterada" e o Status estiver Em Aberto deverá excluir e gerar o Título novamente
					//=================================================================================================
					ElseIf _oGrid:GetValue('ZLL_STATUS') == 'A'
					
						If AGLT010DE2( ZL8->ZL8_PREFIX , _cNumTit + _cSeq , '1 ' , 'NDF' , ZLL->ZLL_RETIRO , ZLL->ZLL_RETILJ , ZLL->ZLL_NATURE, _oModel )
						 	_lRet := AGLT010IE2( _cPrefix , _cNumTit + _cSeq , '1 ' , 'NDF' , _cCodPrd , _cLojPrd , _cNatNDF , _dEmissa , _dVencto , _nValor , 0 , 0 , _cSetor, _oModel )
						Else
							
							DBSelectArea('SE2')
							SE2->( DBSetOrder(1) )
							If SE2->( DBSeek( xFilial('SE2') + ZL8->ZL8_PREFIX + _cNumTit + _cSeq + '1 ' + 'NDF' + ZLL->(ZLL_RETIRO+ZLL_RETILJ) ) )
								_lRet := .F.
							Else
								_lRet := AGLT010IE2( _cPrefix , _cNumTit + _cSeq , '1 ' , 'NDF' , _cCodPrd , _cLojPrd , _cNatNDF , _dEmissa , _dVencto , _nValor , 0 , 0 , _cSetor, _oModel )
							EndIf
						EndIf
						
					EndIf
				
				EndIf
					
				//===============================================================================
				// Para a operação de exclusão do convênio deverão ser excluídos todos os títulos
				//===============================================================================
				If _nOper == MODEL_OPERATION_DELETE
					_lRet := AGLT010DE2( ZL8->ZL8_PREFIX , _cNumTit + _cSeq , '1 ' , 'NDF' , ZLL->ZLL_RETIRO , ZLL->ZLL_RETILJ , ZLL->ZLL_NATURE, _oModel )
				EndIf
				
			EndIf
			
			//============================================================
			// Aborta caso encontre algum problema durante o processamento
			//============================================================
			If !_lRet
				DisarmTransaction()
				_lsai := .T.
				Break
			EndIf
		
		Next nx
		
		//================================
		// Retorna posição e índice da ZLL
		//================================
		ZLL->(FWRestArea(_aareaZLL))
			
		If _lRet
			
			//==================================================================================
			// Para a inclusão ou alteração deverá ser incluído o Título para a NF no Financeiro
			//==================================================================================
			If _nOper == MODEL_OPERATION_INSERT .Or. _nOper == MODEL_OPERATION_UPDATE
				
				//==================================================================================================
				// Adicionado por Fabiano Dias da Silva no dia 29/04/10, solicitacao feita por Monis ao Tiago Correa
				// para que quando a Loja conveniada For a F00001 nao sera gerado o titulo de NF somente as NDF dos 
				// produtores os valores das NDF serao abatidos de suas movimentacoes Financeiras na ITALAC
				//==================================================================================================
				If _cConven <> 'F00001'
					_lRet := AGLT010IE2( _cPrefix , _cNumTit + '000' , '1 ' , 'NF ' , _cConven , _cLjConv , _cNatAux , _dEmissa , _dVencto , _nVlrTot , _nAcresc , _nTxAdm , _cSetor, _oModel )
				EndIf
			
			EndIf
			
			If !_lRet
				DisarmTransaction()
				_lsai := .T.
				Break
			EndIf
			
		Else
			DisarmTransaction()
			_lsai := .T.
			Break
		EndIf
	
	EndIf
	
	If _lRet .And. _nOper == MODEL_OPERATION_INSERT .And. !Empty( _aParAux )
		
		For _nI := 1 To _nLinhas
			
			_oGrid:GoLine(_nI)
			
			If !_oGrid:IsDeleted()
			
				aAdd( _aDados , {	_oModel:GetValue( 'ZLLMASTER' , 'ZLL_NATURE'	) ,;
									_oModel:GetValue( 'ZLLDETAIL' , 'ZLL_SEQ'		) ,;
									_oModel:GetValue( 'ZLLDETAIL' , 'ZLL_RETIRO'	) ,;
									_oModel:GetValue( 'ZLLDETAIL' , 'ZLL_RETILJ'	) ,;
									_oModel:GetValue( 'ZLLDETAIL' , 'ZLL_VALOR'		) ,;
									_oModel:GetValue( 'ZLLDETAIL' , 'ZLL_TXADM'		) ,;
									_oModel:GetValue( 'ZLLDETAIL' , 'ZLL_STATUS'	) ,;
									_oModel:GetValue( 'ZLLDETAIL' , 'ZLL_OBSERV'	) })
			
			EndIf
			
		Next _nI
		
		For _nI := 1 To Len( _aParAux )
			
			_cCodZLL := GetSXENum( 'ZLL' , 'ZLL_COD' )
			
			If __lSX8
				ConfirmSX8()
			EndIf
			
			//==============================================================================================
			// Pega a data de emissão baseada no vencimento: deve ser o último dia do mês anterior ao vencto
			//==============================================================================================
			_dEmissa := LastDay( MonthSub( _aParAux[_nI] , 1 ) )
			
			DBSelectArea('ZLL')
			
			For _nX := 1 To Len( _aDados )
				
				ZLL->( RecLock( 'ZLL' , .T. ) )
				
				ZLL->ZLL_FILIAL		:= xFilial('ZLL')
				ZLL->ZLL_COD		:= _cCodZLL
				ZLL->ZLL_SETOR		:= _cSetor
				ZLL->ZLL_NATURE		:= _aDados[_nX][01]
				ZLL->ZLL_EVENTO		:= _cEvento
				ZLL->ZLL_DATA		:= _dEmissa
				ZLL->ZLL_VENCTO		:= _aParAux[_nI]
				ZLL->ZLL_CONVEN		:= _cConven
				ZLL->ZLL_LJCONV		:= _cLjConv
				ZLL->ZLL_ACRESC		:= _nAcresc
				ZLL->ZLL_SEQ		:= _aDados[_nX][02]
				ZLL->ZLL_RETIRO		:= _aDados[_nX][03]
				ZLL->ZLL_RETILJ		:= _aDados[_nX][04]
				ZLL->ZLL_VALOR		:= _aDados[_nX][05]
				ZLL->ZLL_TXADM		:= _aDados[_nX][06]
				ZLL->ZLL_STATUS		:= _aDados[_nX][07]
				ZLL->ZLL_OBSERV		:= _aDados[_nX][08]
				
				ZLL->( MSUnLock() )
				
				//=====================================
				// Inclui nova NDF para a parcela atual
				//=====================================
				If !AGLT010IE2( _cPrefix , ZLL->( ZLL_COD + ZLL_SEQ ) , '1 ' , 'NDF' , ZLL->ZLL_RETIRO , ZLL->ZLL_RETILJ , ZLL->ZLL_NATURE , ZLL->ZLL_DATA , ZLL->ZLL_VENCTO , ZLL->ZLL_VALOR , 0 , 0 , _cSetor, _oModel )
					DisarmTransaction()
					_lRet := .F.
					_lsai := .T.
					Break
				EndIf
				
			Next
			
			//====================================
			// Inclui nova NF para a parcela atual
			//====================================
			//==================================================================================================
			// Adicionado por Fabiano Dias da Silva no dia 29/04/10, solicitacao feita por Monis ao Tiago Correa
			// para que quando a Loja conveniada For a F00001 nao sera gerado o titulo de NF somente as NDF dos
			// produtores os valores das NDF serao abatidos de suas movimentacoes Financeiras na ITALAC
			//==================================================================================================
			If _cConven <> 'F00001'
			
				If !AGLT010IE2( _cPrefix , _cCodZLL + '000' , '1 ' , 'NF ' , _cConven , _cLjConv , _cNatAux , _dEmissa , _aParAux[_nI] , _nVlrTot , _nAcresc , _nTxAdm , _cSetor, _oModel )
					DisarmTransaction()
					_lRet := .F.
					_lsai := .T.
					Break
				EndIf
				
			EndIf
			
		Next _nI
		
	EndIf
	
	End Transaction
	
	End Sequence
	
	If _lsai
	
		Return(_lRet)
		
	EndIf

EndIf

//===========================================================================================
// Para corrigir um problema do MVC em salvar telas modelo 2, posiciono no primeiro registro,
// e regravo todas as informações do cabeçalho em todas as linhas
//===========================================================================================
_aAreaZLL := ZLL->(GetArea())
If _lRet .And. _oModel:GetOperation() == MODEL_OPERATION_UPDATE
	DBSelectArea("ZLL")
	DBSetOrder(1)
	If DBSeek(xFilial("ZLL") + _cCodigo)
		While !ZLL->(Eof()) .And. ZLL->ZLL_FILIAL == xFilial("ZLL") .And. ZLL->ZLL_COD == _cCodigo
			RecLock("ZLL", .F.)
				ZLL->ZLL_SETOR	:= _cSetor
				ZLL->ZLL_EVENTO	:= _cEvento
				ZLL->ZLL_CONVEN	:= _cConven
				ZLL->ZLL_LJCONV	:= _cLjConv
				ZLL->ZLL_VENCTO	:= _dVencto
				ZLL->ZLL_ACRESC	:= _nAcresc
			MSUnLock()
			ZLL->(DBSkip())
		End
	EndIf
EndIf
FWRestArea(_aAreaZLL)
Return( _lRet )

/*
===============================================================================================================================
Programa----------: AGLT010DE2
Autor-------------: Alexandre Villar
Data da Criacao---: 13/03/2015
Descrição---------: Rotina para exclusão de Títulos do Financeiro
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT010DE2( _cPrefix , _cNumTit , _cParcel , _cTipo , _cForn , _cLoja , _cNature, _oModel )

Local aArea := FWGetArea()
Local _aAutSE2	:= {}
Local _lOk		:= .T.
Local _nModAux	:= nModulo
Local _cModAux	:= cModulo

Private lMsErroAuto := .F.

nModulo := 6
cModulo := "FIN"

DBSelectArea("SE2")
SE2->( DBSetOrder(1) )
If SE2->( DBSeek( xFilial("SE2") + _cPrefix + _cNumTit + _cParcel + _cTipo + _cForn + _cLoja ) )
	If !Empty(SE2->E2_BAIXA)
		_oModel:SetErrorMessage('ZLLMASTER', 'ZLL_NATURE' , 'ZLLMASTER' , 'ZLL_NATURE' , "AGLT01020", "Título sofreu baixas e não poderá ser excluído. Título: " + _cPrefix + _cNumTit + _cParcel + _cTipo + _cForn + _cLoja, "Exclua a baixa antes de realizar a operação.")
	    _lOk := .F.
	Else
	
		_aAutSE2 := { { "E2_PREFIXO" , SE2->E2_PREFIXO , NIL },;
	                { "E2_NUM"     , SE2->E2_NUM     , NIL } }

		MSExecAuto( {|x,y,z| Fina050(x,y,z) } , _aAutSE2 ,, 5 )

		If lMsErroAuto
			MostraErro()
			_oModel:SetErrorMessage('ZLLMASTER', 'ZLL_NATURE' , 'ZLLMASTER' , 'ZLL_NATURE' , "AGLT01021", "Falhou ao excluir o título do convênio no Financeiro!", "Informe a área de TI/ERP.")
			_lOk := .F.
		EndIf
		
    EndIf
Else                            

	If _cForn <> 'F00001'
		_oModel:SetErrorMessage('ZLLMASTER', 'ZLL_NATURE' , 'ZLLMASTER' , 'ZLL_NATURE' , "AGLT01022", "Não encontrou o título do convênio no  Financeiro!", "Informe a área de TI/ERP.")
		_lOk := .F.
	EndIf

EndIf

nModulo := _nModAux
cModulo := _cModAux

FWRestArea(aArea)

Return( _lOk )

/*
===============================================================================================================================
Programa----------: AGLT010IE2
Autor-------------: Alexandre Villar
Data da Criacao---: 13/03/2015
Descrição---------: Rotina para inclusão de Títulos no Financeiro
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT010IE2( _cPrefix , _cNumTit , _cParcel , _cTipo , _cForn , _cLoja , _cNature , _dEmissa , _dVencto , _nValor , _nAcres , _nDesc , _cSetor, _oModel )

Local _aAutSE2	:= {}
Local _lOk		:= .T.
Local _nModAux	:= nModulo
Local _cModAux	:= cModulo

Private lMsErroAuto := .F.

aAdd( _aAutSE2 , { "E2_PREFIXO"	, _cPrefix		, Nil } )
aAdd( _aAutSE2 , { "E2_NUM"		, _cNumTit		, nil } )
aAdd( _aAutSE2 , { "E2_PARCELA"	, _cParcel		, nil } )
aAdd( _aAutSE2 , { "E2_TIPO"	, _cTipo		, nil } )
aAdd( _aAutSE2 , { "E2_NATUREZ"	, _cNature		, nil } )
aAdd( _aAutSE2 , { "E2_FORNECE"	, _cForn		, nil } )
aAdd( _aAutSE2 , { "E2_LOJA"	, _cLoja		, nil } )
aAdd( _aAutSE2 , { "E2_EMISSAO"	, _dEmissa		, nil } )
aAdd( _aAutSE2 , { "E2_EMIS1"	, _dEmissa		, nil } )
aAdd( _aAutSE2 , { "E2_VENCTO"	, DataValida(_dVencto), nil } )
aAdd( _aAutSE2 , { "E2_VALOR"	, _nValor		, nil } )
aAdd( _aAutSE2 , { "E2_ACRESC"	, _nAcres		, nil } )
aAdd( _aAutSE2 , { "E2_DECRESC"	, _nDesc		, nil } )
aAdd( _aAutSE2 , { "E2_HIST"	, "GLT-CONVENIO", nil } )
aAdd( _aAutSE2 , { "E2_DATALIB"	, _dEmissa		, nil } )	
aAdd( _aAutSE2 , { "E2_USUALIB"	, cUserName		, nil } )	
aAdd( _aAutSE2 , { "E2_ORIGEM"	, "AGLT010"		, nil } )
aAdd( _aAutSE2 , { "E2_L_SETOR"	, _cSetor		, nil } )

nModulo := 6
cModulo := "FIN"

MSExecAuto( {|x,y| Fina050(x,y) } , _aAutSE2 , 3 )

If lMsErroAuto
	MostraErro()
	_oModel:SetErrorMessage('ZLLMASTER', 'ZLL_NATURE' , 'ZLLMASTER' , 'ZLL_NATURE' , "AGLT01023", "Falhou ao incluir o título do convênio no Financeiro!", "Informe a área de TI/ERP.")
	_lOk := .F.
Else
	DBSelectArea('SE2')
	SE2->( DBSetOrder(1) )
	If !SE2->( DBSeek( xFilial('SE2') + _aAutSE2[01][02] + _aAutSE2[02][02] + _aAutSE2[03][02] + _aAutSE2[04][02] + _aAutSE2[06][02] + _aAutSE2[07][02] ) )
		_oModel:SetErrorMessage('ZLLMASTER', 'ZLL_NATURE' , 'ZLLMASTER' , 'ZLL_NATURE' , "AGLT01024", "Falhou ao incluir o título do convênio no Financeiro!", "Informe a área de TI/ERP.")
		_lOk := .F.
	EndIf

EndIf

nModulo := _nModAux
cModulo := _cModAux

Return( _lOk )

/*
===============================================================================================================================
Programa----------: AGLT010V
Autor-------------: Alexandre Villar
Data da Criacao---: 13/03/2015
Descrição---------: Rotina para inicialização de valores para os campos virtuais da tela
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT010V( _nOpc )

Local _aArea	:= FWGetArea()
Local _cAlias	:= ''
Local _nValRet	:= 0

Default _nOpc	:= 0

If !Inclui .And. _nOpc > 0
	
	_cAlias	:= GetNextAlias()
	BeginSql alias _cAlias
	  SELECT SUM(ZLL.ZLL_VALOR) VALOR,
	         SUM(Case
	               WHEN ZLL.ZLL_STATUS = 'A' THEN
	                ZLL.ZLL_VALOR
	               Else
	                0
	             END) VALABR,
	         Round(SUM(ZLL.ZLL_VALOR) * (SA2.A2_L_TXADM/100),2) VALADM,
	         SA2.A2_L_TXADM TXADM
	    FROM %Table:ZLL% ZLL
	    JOIN %Table:SA2% SA2
	      ON SA2.D_E_L_E_T_ = ' '
	     AND SA2.A2_COD = ZLL.ZLL_CONVEN
	     AND SA2.A2_LOJA = ZLL.ZLL_LJCONV
	   WHERE ZLL.D_E_L_E_T_ = ' '
	     AND ZLL_FILIAL = %exp:ZLL->ZLL_FILIAL%
	     AND ZLL_COD = %exp:ZLL->ZLL_COD%
	   GROUP BY SA2.A2_L_TXADM
	EndSql

	If (_cAlias)->( !Eof() )
		Do Case
			Case _nOpc == 1
				_nValRet := (_cAlias)->VALOR
			Case _nOpc == 2
				_nValRet := (_cAlias)->VALABR
			Case _nOpc == 3
				_nValRet := (_cAlias)->TXADM
			Case _nOpc == 4
				_nValRet := (_cAlias)->VALADM
		EndCase
	EndIf

	(_cAlias)->(DBCloseArea())
EndIf

FWRestArea( _aArea )

Return( _nValRet )

/*
===============================================================================================================================
Programa----------: AGLT010R
Autor-------------: Alexandre Villar
Data da Criacao---: 13/03/2015
Descrição---------: Rotina para inicialização do campo nome do produtor
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT010R()

Local _oModel	:= FWModelActive()
Local _cRet		:= ''

If !Inclui
	If ValType(_oModel) == "O"
		If _oModel:GetModel('ZLLDETAIL'):nLine > 0
			If !_oModel:GetOperation() == MODEL_OPERATION_UPDATE
				_cRet := AllTrim( Posicione('SA2',1,xFilial('SA2')+_oModel:GetValue('ZLLDETAIL','ZLL_RETIRO')+_oModel:GetValue('ZLLDETAIL','ZLL_RETILJ'),'A2_NOME') )
			EndIf
		Else
			_cRet := AllTrim( Posicione('SA2',1,xFilial('SA2')+ZLL->(ZLL_RETIRO+ZLL_RETILJ),'A2_NOME') )
		EndIf
	Else
		_cRet := AllTrim( Posicione('SA2',1,xFilial('SA2')+ZLL->(ZLL_RETIRO+ZLL_RETILJ),'A2_NOME') )
	EndIf
EndIf

Return( _cRet )

/*
===============================================================================================================================
Programa----------: AGLT010CPA
Autor-------------: Alexandre Villar
Data da Criacao---: 13/03/2015
Descrição---------: Monta a tela para digitação das datas de parcelas adicionais para o convênio
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT010CPA( _dVencto )

Local _lOk			:= .F.
Local _aRet			:= {}
Local _nI			:= 0
Local aButtons		:= {}
Local cLinOk		:= "AllwaysTrue"
Local cTudoOk		:= "AllwaysTrue"
Local cIniCpos		:= "ZLL_VENCTO"
Local nFreeze		:= 000
Local nMax			:= 999
Local cFieldOk		:= "AllwaysTrue"
Local cSuperDel		:= ""
Local cDelOk		:= "AllwaysFalse"
Local aHeader		:= {}
Local aCols			:= {}
Local aAlterGDa		:= {}

Private _oDlg		:= NIL
Private _oGetD		:= NIL

// Busca a estrutura de campos para montagem da GetDados
aAdd( aAlterGDa  , 'ZLL_VENCTO' )

// Monta a estrutura do cabeçalho
aAdd( aHeader , { trim(getsx3cache(aAlterGDa[1],"X3_TITULO") ),;
							getsx3cache(aAlterGDa[1],"X3_CAMPO")		,;
							getsx3cache(aAlterGDa[1],"X3_PICTURE")		,;
							getsx3cache(aAlterGDa[1],"X3_TAMANHO")		,;
							getsx3cache(aAlterGDa[1],"X3_DECIMAL")		,;
							"AllwaysTrue()"									,;
							getsx3cache(aAlterGDa[1],"X3_USADO")		,;
							getsx3cache(aAlterGDa[1],"X3_TIPO")			,;
							getsx3cache(aAlterGDa[1],"X3_ARQUIVO")		,;
							getsx3cache(aAlterGDa[1],"X3_CONTEXT")	})
aCols := { Array( 2 ) }
aCols[ 1 ][ 2 ] := .F.
aCols[ 1 ][ 1 ] := SToD('')

_oDlg := MSDIALOG():New( 000 , 000 , 400 , 300 , 'Parcelamento de convênio:' ,,,,,,,,, .T. )

// Constrói a tela e exibe
_oGetD			:= MsNewGetDados():New(035,001,188,152,3,cLinOk,cTudoOk,cIniCpos,aAlterGDa,nFreeze,nMax,cFieldOk,cSuperDel,cDelOk,_oDLG,aHeader,aCols)
_oGetD:bLinhaOk	:= {|| IIf( _oGetD:aCols[_oGetD:nAt][01] < _dVencto , ( Aviso('Atenção!','A data das parcelas devem ser maiores que o primeiro vencimento do convênio ('+DToC(_dVencto)+")",{'Voltar'}) , .F. ) , .T. ) }

_oDlg:bInit := {|| EnchoiceBar(_oDlg, {|| _lOk := .T. , _oDlg:End() } , {|| _lOk := .F. , _oDlg:End() } ,, aButtons ) , _oGetD:oBrowse:Align:=CONTROL_ALIGN_ALLCLIENT }
_oDlg:lCentered := .T.
_oDlg:Activate()

If _lOk
	
	For _nI := 1 To Len( _oGetD:aCols )
		If !_oGetD:aCols[_nI][02] .And. !Empty( _oGetD:aCols[_nI][01] ) .And. aScan( _aRet , {|x| x == _oGetD:aCols[_nI][01] } ) == 0
			aAdd( _aRet , _oGetD:aCols[_nI][01] )
		EndIf
	Next _nI
	
EndIf

Return( _aRet )

/*
===============================================================================================================================
Programa----------: AGLT010VLD
Autor-------------: Alexandre Villar
Data da Criacao---: 13/03/2015
Descrição---------: Validação inicial da DataBase do Sistema para não permitir manutenção de dados em períodos bloqueados pelo
------------------: parâmetro Fiscal ou Financeiro
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT010VLD( _oModel )

Local _lRet		:= .T.

If _oModel:GetOperation() == MODEL_OPERATION_INSERT .Or. _oModel:GetOperation() == MODEL_OPERATION_UPDATE .Or. _oModel:GetOperation() == MODEL_OPERATION_DELETE

	If dDataBase < GetMV('MV_DATAFIN')
		_oModel:SetErrorMessage('ZLLMASTER', 'ZLL_DATA' , 'ZLLMASTER' , 'ZLL_DATA' , "AGLT01034", "A DataBase do Sistema não é válida de acordo com o parâmetro Financeiro.", "Corrija a DataBase ou solicite liberação para a Contabilidade.")
		//_lRet := .F.//lucas
	EndIf
	
	If _lRet .And. dDataBase <> LastDay( dDataBase )
		_oModel:SetErrorMessage('ZLLMASTER', 'ZLL_DATA' , 'ZLLMASTER' , 'ZLL_DATA' , "AGLT01035", "A DataBase do Sistema não é válida pois não está posicionada no último dia do mês selecionado ("+DToC(LastDay(dDataBase))+")", "Para realizar a manutenção no convênio configure a DataBase no último dia do mês que estiver sendo utilizado.")
		//_lRet := .F.//lucas
	EndIf
	
EndIf

Return( _lRet )

/*
===============================================================================================================================
Programa----------: AGLT010P
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 23/05/2022
Descrição---------: Carrega os produtores que tiveram o evento informado no grid para geração do Convênio
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT010P()

Local _oModel	:= FWModelActive()
Local _oView	:= FWViewActive()
Local _oGrid	:= _oModel:GetModel('ZLLDETAIL')
Local _cAlias	:= GetNextAlias()
Local _lRet		:= .F.
Local _nI		:= 0
Local _cEvento	:= Space(GetSX3Cache("ZLL_EVENTO","X3_TAMANHO"))
Local _cDescri	:= Space(GetSX3Cache("ZL8_DESCRI","X3_TAMANHO"))
Local _cSetor	:= _oModel:GetValue( 'ZLLMASTER' , 'ZLL_SETOR'  )
Local _nTamGrid	:= 0
Local _nProc	:= 0
Local oDlgKey, oBtnOut, oBtnCon

If Empty(_cSetor)
	MsgAlert("O campo "+AllTrim(GetSX3Cache("ZLL_SETOR","X3_TITULO"))+" não foi preenchido.","AGLT01025" )	
ElseIf _oModel:GetOperation() == MODEL_OPERATION_INSERT
	DEFINE MSDIALOG oDlgKey TITLE "Evento Mix" FROM 0,0 TO 150,450 PIXEL OF GetWndDefault()

	@ 12,008 Say "Informe o código do evendo gerado no Mix. Será buscado os produtores do Setor que " PIXEL OF oDlgKey
	@ 25,008 Say "tiveram o evento calculado no MIX. " PIXEL OF oDlgKey
	@ 40,008 MSGET _cEvento SIZE 50,10 PIXEL OF oDlgKey VALID {||IIf(ExistCpo("ZL8",_cEvento), _cDescri:= Posicione('ZL8',1,xFilial('ZL8')+_cEvento,'ZL8_DESCRI'),.F.)} Pixel F3 "ZL8_01"
	@ 40,060 MSGET _cDescri SIZE 160,10 PIXEL OF oDlgKey WHEN .F.

	@ 60,060 BUTTON oBtnCon PROMPT "&Confirma" SIZE 38,11 PIXEL ACTION (IIf(!Empty(_cEvento),_lRet := .T.,;
			MsgStop("Evento não informado.","AGLT01026" )) , oDlgKey:End())
	@ 60,100 BUTTON oBtnOut PROMPT "&Sair" SIZE 38,11 PIXEL ACTION oDlgKey:End()

	ACTIVATE DIALOG oDlgKey CENTERED

	If _lRet
		BeginSql alias _cAlias
			SELECT ZLF_A2COD, ZLF_A2LOJA, SUM(ZLF_TOTAL) ZLF_TOTAL
			FROM %Table:ZLF%
			WHERE D_E_L_E_T_ = ' '
			AND ZLF_FILIAL = %xFilial:ZLF%
			AND ZLF_SETOR = %Exp:_cSetor%
			AND ZLF_DTFIM = %Exp:dDataBase%
			AND ZLF_EVENTO = %Exp:_cEvento%
			GROUP BY ZLF_A2COD, ZLF_A2LOJA
			ORDER BY ZLF_A2COD, ZLF_A2LOJA
		EndSql

		_nTamGrid := _oGrid:Length()
		//Apaga grid atual
		For _nI := 1 To _oGrid:Length()
			_oGrid:GoLine( _nI )
			If !_oGrid:IsDeleted()
				_oGrid:DeleteLine()
			EndIf
		Next _nI

		While (_cAlias)->(!Eof())
			_nProc ++
			If _nProc <= _nTamGrid
				_oGrid:GoLine(_nProc)
				If _oGrid:IsDeleted()
					_oGrid:UnDeleteLine()
				EndIf
				_oView:Refresh()
			Else
				_nTamGrid := _oGrid:AddLine()
				_oView:Refresh()
				_oGrid:GoLine(_nProc)
			EndIf
			_oModel:SetValue( 'ZLLDETAIL','ZLL_RETIRO',(_cAlias)->ZLF_A2COD)
			_oModel:SetValue( 'ZLLDETAIL','ZLL_RETILJ',(_cAlias)->ZLF_A2LOJA)
			_oModel:SetValue( 'ZLLDETAIL','ZLL_VALOR',(_cAlias)->ZLF_TOTAL)
			_oView:Refresh()
			(_cAlias)->(DBSkip())
		EndDo
		(_cAlias)->(DBCloseArea())
	EndIf
Else
	MsgAlert("Função disponível apenas na Inclusão.","AGLT01027" )
EndIf
Return
