/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |17/01/2020| Chamado 31761. Corrigido totalizador do convênio.
Lucas Borges  |06/02/2020| Chamado 31941. Corrigido nome do objeto.
Lucas Borges  |20/10/2020| Chamado 34436. Corrigida a exclusão de títulos.
===============================================================================================================================
*/

#Include "TOTVS.ch" 
#Include "FWMVCDEF.ch"

/*
===============================================================================================================================
Programa----------: AGLT011
Autor-------------: Lucas Borges
Data da Criacao---: 21/03/2019
Descrição---------: Rotina para lançamentos dos convênios de terceiros, cópia do AGLT010 - Chamado 11132
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT011()

Local _oBrowse := Nil

_oBrowse := FWMBrowse():New()
_oBrowse:SetAlias('ZLI')
_oBrowse:SetDescription('Lançamentos dos Convênios Terceiros')

_oBrowse:AddLegend( "ZLI_STATUS == 'A'" , 'GREEN'	, 'Convênio em aberto'	)
_oBrowse:AddLegend( "ZLI_STATUS == 'P'" , 'RED'		, 'Convênio pago'		)
_oBrowse:AddLegend( "ZLI_STATUS == 'S'" , 'BLUE'	, 'Convênio Suspenso'	)

_oBrowse:Activate()

Return

/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Lucas Borges
Data da Criacao---: 21/03/2019
Descrição---------: Retorna o menu funcional para a rotina principal
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MenuDef()

Local _aRotina := {}

ADD OPTION _aRotina Title 'Visualizar'	Action 'VIEWDEF.AGLT011' OPERATION 2 ACCESS 0
ADD OPTION _aRotina Title 'Incluir'		Action 'VIEWDEF.AGLT011' OPERATION 3 ACCESS 0
ADD OPTION _aRotina Title 'Alterar'		Action 'VIEWDEF.AGLT011' OPERATION 4 ACCESS 0
ADD OPTION _aRotina Title 'Excluir'		Action 'VIEWDEF.AGLT011' OPERATION 5 ACCESS 0
ADD OPTION _aRotina Title 'Copiar'		Action 'VIEWDEF.AGLT011' OPERATION 9 ACCESS 0

Return( _aRotina )

/*
===============================================================================================================================
Programa----------: ModelDef
Autor-------------: Lucas Borges
Data da Criacao---: 21/03/2019
Descrição---------: Monta o Modelo de dados
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ModelDef()

Local _oStruCAB	:= FWFormStruct( 1 , 'ZLI' , { |_cCampo| AGLT011CPO( _cCampo , 1 ) } )
Local _oStruITN	:= FWFormStruct( 1 , 'ZLI' , { |_cCampo| AGLT011CPO( _cCampo , 2 ) } )
Local _oModel	:= Nil
Local _aGatAux	:= {}

_aGatAux := FwStruTrigger( 'ZLI_EVENTO'	, 'ZLI_DESEVE'	, 'ZT1->ZT1_DESCRI'	, .T. , 'ZT1' , 1 , 'xFilial("ZT1")+M->ZLI_EVENTO'	)
_oStruCAB:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLI_EVENTO'	, 'ZLI_DESEVE'	, 'U_GL011RET( 4 , M->ZLI_EVENTO  )'	, .F.	)
_oStruCAB:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLI_CONVEN'	, 'ZLI_DESCRI'	, 'SA2->A2_NOME'	, .T. , 'SA2' , 1 , 'xFilial("SA2")+M->ZLI_CONVEN+AllTrim(M->ZLI_LJCONV)' )
_oStruCAB:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLI_CONVEN'	, 'ZLI_LJCONV'	, 'IIf( Empty(M->ZLI_LJCONV) , "0001" , M->ZLI_LJCONV )'	, .F. )
_oStruCAB:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLI_LJCONV'	, 'ZLI_DESCRI'	, 'SA2->A2_NOME'	, .T. , 'SA2' , 1 , 'xFilial("SA2")+M->ZLI_CONVEN+AllTrim(M->ZLI_LJCONV)' )
_oStruCAB:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLI_CONVEN'	, 'ZLI_PERADM'	, 'SA2->A2_L_TXADM'	, .T. , 'SA2' , 1 , 'xFilial("SA2")+M->ZLI_CONVEN+AllTrim(M->ZLI_LJCONV)' )
_oStruCAB:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLI_LJCONV'	, 'ZLI_PERADM'	, 'SA2->A2_L_TXADM'	, .T. , 'SA2' , 1 , 'xFilial("SA2")+M->ZLI_CONVEN+AllTrim(M->ZLI_LJCONV)' )
_oStruCAB:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLI_RETIRO'	, 'ZLI_RETIRO'	, 'U_GL011RET( 1 , M->ZLI_RETIRO )' , .F. )
_oStruITN:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLI_RETIRO'	, 'ZLI_RETILJ'	, 'U_GL011RET( 2 , M->ZLI_RETIRO , M->ZLI_RETILJ )' , .F. )
_oStruITN:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLI_RETIRO'	, 'ZLI_RETILJ'	, 'U_GL011RET( 3 , M->ZLI_RETIRO , M->ZLI_RETILJ )' , .F. )
_oStruITN:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLI_RETIRO'	, 'ZLI_DCRRET'	, 'SA2->A2_NOME'	, .T. , 'SA2' , 1 , 'xFilial("SA2")+M->ZLI_RETIRO+AllTrim(M->ZLI_RETILJ)' )
_oStruITN:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLI_RETILJ'	, 'ZLI_DCRRET'	, 'SA2->A2_NOME'	, .T. , 'SA2' , 1 , 'xFilial("SA2")+M->ZLI_RETIRO+AllTrim(M->ZLI_RETILJ)' )
_oStruITN:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLI_VALOR'	, 'ZLI_VALOR'	, 'U_GL011LOK( M->ZLI_VALOR )' , .F. )
_oStruITN:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_oModel := MPFormModel():New( 'AGLT011M' ,, {|| AGLT011TOK() } )

_oModel:SetDescription( 'Lançamentos dos Convênios' )

_oModel:AddFields(	"ZLIMASTER" , /*cOwner*/  , _oStruCAB )
_oModel:AddGrid(	"ZLIDETAIL" , "ZLIMASTER" , _oStruITN , { | _oModel , _nLine , _cAction , _cField | AGLT011LOK( _nLine , _cAction , _cField ) } )

_oModel:SetRelation( "ZLIDETAIL" , {	{ 'ZLI_FILIAL'	, 'xFilial("ZLI")'	} ,;
										{ 'ZLI_COD'		, 'ZLI_COD'			} }, ZLI->( IndexKey( 1 ) ) )

_oModel:GetModel( 'ZLIDETAIL' ):SetUniqueLine( { 'ZLI_SEQ' } )

_oModel:GetModel( "ZLIMASTER" ):SetDescription( "Dados do Convênio"		)
_oModel:GetModel( "ZLIDETAIL" ):SetDescription( "Itens do Lançamento"	)

_oModel:SetPrimaryKey( { 'ZLI_FILIAL' , 'ZLI_COD' , 'ZLI_SEQ' } )

_oModel:GetModel( 'ZLIMASTER' ):AFLDNOCOPY := {  'ZLI_DATA' , 'ZLI_VENCTO' }
_oModel:GetModel( 'ZLIDETAIL' ):AFLDNOCOPY := { 'ZLI_STATUS' }

//==================================
// Define validação inical do modelo
//==================================
_oModel:SetVldActivate( { |_oModel| AGLT011VLD( _oModel ) } )

Return( _oModel )

/*
===============================================================================================================================
Programa----------: ViewDef
Autor-------------: Lucas Borges
Data da Criacao---: 21/03/2019
Descrição---------: Define a View de dados para a rotina de cadastro
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ViewDef()

Local _oModel  	:= FWLoadModel( 'AGLT011' )
Local _oStruCAB	:= FWFormStruct( 2 , 'ZLI' , { |cCampo| AGLT011CPO( cCampo , 1 ) } )
Local _oStruITN	:= FWFormStruct( 2 , 'ZLI' , { |cCampo| AGLT011CPO( cCampo , 2 ) } )
Local _oView	:= Nil

//=========================================
// Configuração para agrupamento dos campos
//=========================================
_oStruCAB:AddGroup( 'GRUPO01' , 'Convênio'						, '' , 2 )
_oStruCAB:AddGroup( 'GRUPO02' , 'Valores do Convênio'			, '' , 2 )

_oStruCAB:SetProperty( 'ZLI_COD'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO01' )
_oStruCAB:SetProperty( 'ZLI_NATURE'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO01' )
_oStruCAB:SetProperty( 'ZLI_EVENTO'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO01' )
_oStruCAB:SetProperty( 'ZLI_DESEVE'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO01' )
_oStruCAB:SetProperty( 'ZLI_CONVEN'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO01' )
_oStruCAB:SetProperty( 'ZLI_LJCONV'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO01' )
_oStruCAB:SetProperty( 'ZLI_DESCRI'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO01' )
_oStruCAB:SetProperty( 'ZLI_DATA'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO01' )
_oStruCAB:SetProperty( 'ZLI_VENCTO'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO01' )

_oStruCAB:SetProperty( 'ZLI_VALTOT'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO02' )
_oStruCAB:SetProperty( 'ZLI_VLRABR'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO02' )
_oStruCAB:SetProperty( 'ZLI_ACRESC'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO02' )
_oStruCAB:SetProperty( 'ZLI_PERADM'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO02' )
_oStruCAB:SetProperty( 'ZLI_VTXADM'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO02' )

_oView := FWFormView():New()

_oView:SetModel( _oModel )
_oView:AddField( "VIEW_CAB"	, _oStruCAB	, "ZLIMASTER" )
_oView:AddGrid(  "VIEW_ITN"	, _oStruITN	, "ZLIDETAIL" )

_oView:CreateHorizontalBox( 'BOX0101' , 55 )
_oView:CreateHorizontalBox( 'BOX0102' , 45 )
_oView:SetOwnerView( "VIEW_CAB" , "BOX0101" )
_oView:SetOwnerView( "VIEW_ITN" , "BOX0102" )

_oView:AddIncrementField( 'VIEW_ITN' , 'ZLI_SEQ' )

Return( _oView )

/*
===============================================================================================================================
Programa----------: AGLT011CPO
Autor-------------: Lucas Borges
Data da Criacao---: 21/03/2019
Descrição---------: Define a organização dos campos para exibição na tela
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT011CPO( _cCampo , _nOpc )

Local _lRet := Upper( AllTrim(_cCampo) ) $ 'ZLI_FILIAL/ZLI_COD/ZLI_EVENTO/ZLI_DESEVE/ZLI_CONVEN/ZLI_LJCONV/ZLI_DESCRI/ZLI_DATA/ZLI_VENCTO/ZLI_NATURE/ZLI_VALTOT/ZLI_VLRABR/ZLI_ACRESC/ZLI_PERADM/ZLI_VTXADM'

If _nOpc == 2
	_lRet := !_lRet
EndIf

Return( _lRet )

/*
===============================================================================================================================
Programa----------: GL010LOK
Autor-------------: Lucas Borges
Data da Criacao---: 21/03/2019
Descrição---------: Rotina para Atualização dos valores conforme preenchimento dos campos das linhas
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function GL011LOK( _nValRet )

Local _oModel	:= FWModelActive()
Local _aSaveLines := FWSaveRows()
Local _oZLIDET	:= _oModel:GetModel( 'ZLIDETAIL' )
Local _nI		:= 0
Local _nValor	:= 0
Local _nValAbr	:= 0
Local _nValAdm	:= 0
Local _nValTot	:= 0
Local _nTxAdm	:= _oModel:GetValue( 'ZLIMASTER' , 'ZLI_PERADM' )

For _nI := 1 To _oZLIDET:Length()
	
	_oZLIDET:GoLine( _nI )
	If !_oZLIDET:IsDeleted()
		_nValor		:= _oZLIDET:GetValue( 'ZLI_VALOR' )
		_nValTot	+= _nValor
			
		_oModel:SetValue( 'ZLIDETAIL' , 'ZLI_TXADM' , _nValor * ( _nTxAdm / 100 ) )
		_nValAdm	+= _oZLIDET:GetValue( 'ZLI_TXADM' )
			
		If _oZLIDET:GetValue( 'ZLI_STATUS' ) == 'A'
			_nValAbr += _nValor
		EndIf
	EndIf
Next _nI

_oModel:LoadValue( 'ZLIMASTER' , 'ZLI_VALTOT' , _nValTot )
_oModel:LoadValue( 'ZLIMASTER' , 'ZLI_VTXADM' , _nValAdm )
_oModel:LoadValue( 'ZLIMASTER' , 'ZLI_VLRABR' , _nValAbr )
FWRestRows( _aSaveLines )

Return( _nValRet )

/*
===============================================================================================================================
Programa----------: AGLT011LOK
Autor-------------: Lucas Borges
Data da Criacao---: 21/03/2019
Descrição---------: Rotina para validação das operações de alteração/delete das linhas de lançamentos
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT011LOK( _nLine , _cAction , _cField )

Local _lRet		:= .T.
Local _oModel	:= FWModelActive()
Local _nValor	:= 0
Local _nValTX	:= 0
Local _nValTot	:= 0
Local _nValTXA	:= 0

If _oModel:GetValue( 'ZLIDETAIL' , 'ZLI_STATUS' ) == 'A'

	If Upper(AllTrim(_cAction)) $ 'DELETE/UNDELETE'
	
		_nValor		:= _oModel:GetValue( 'ZLIDETAIL' , 'ZLI_VALOR' )
		_nValTX		:= _oModel:GetValue( 'ZLIDETAIL' , 'ZLI_TXADM' )
		_nValTot	:= _oModel:GetValue( 'ZLIMASTER' , 'ZLI_VALTOT' )
		_nValABR	:= _oModel:GetValue( 'ZLIMASTER' , 'ZLI_VLRABR' )
		_nValTXA	:= _oModel:GetValue( 'ZLIMASTER' , 'ZLI_VTXADM' )
	
		If Upper(AllTrim(_cAction)) == 'DELETE'
		
			_oModel:LoadValue( 'ZLIMASTER' , 'ZLI_VTXADM' , _nValTXA - _nValTX )
			_oModel:LoadValue( 'ZLIMASTER' , 'ZLI_VLRABR' , _nValABR - _nValor )
			_oModel:LoadValue( 'ZLIMASTER' , 'ZLI_VALTOT' , _nValTot - _nValor )
			
		Else
		
			_oModel:LoadValue( 'ZLIMASTER' , 'ZLI_VTXADM' , _nValTXA + _nValTX )
			_oModel:LoadValue( 'ZLIMASTER' , 'ZLI_VLRABR' , _nValABR + _nValor )
			_oModel:LoadValue( 'ZLIMASTER' , 'ZLI_VALTOT' , _nValTot + _nValor )
			
		EndIf
	
	EndIf
	
Else
	_oModel:SetErrorMessage('ZLIDETAIL', 'ZLI_STATUS' , 'ZLIDETAIL' , 'ZLI_STATUS' , "AGLT01101", "Não é possível realizar a operação no registro atual!", "Somente registros 'Em Aberto' podem ser alterados, excluídos ou restaurados.")
	_lRet := .F.
EndIf
	
Return( _lRet )

/*
===============================================================================================================================
Programa----------: GL010RET
Autor-------------: Lucas Borges
Data da Criacao---: 21/03/2019
Descrição---------: Rotina auxiliar para processamento dos gatilhos
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function GL011RET( _nOpcao , _cRetiro , _cLoja )

Local _cRet		:= ''
Local _oModel	:= FWModelActive()

If _nOpcao == 1

	DBSelectArea('SA2')
	SA2->( DBSetOrder(1) )
	If SA2->( DBSeek( xFilial('SA2') + _cRetiro ) )
	
		_oModel:LoadValue( 'ZLIDETAIL' , 'ZLI_RETIRO' , SA2->A2_COD )
		_cRet := SA2->A2_COD
		
	Else
		_oModel:SetErrorMessage('ZLIDETAIL', 'ZLI_RETIRO' , 'ZLIDETAIL' , 'ZLI_RETIRO' , "AGLT01102", "O Produtor informado não é válido ou não foi encontrado no Sistema!", "Verifique os dados digitados e tente novamente.")
	    _oModel:LoadValue( 'ZLIDETAIL' , 'ZLI_RETIRO' , '' )
	EndIf

ElseIf _nOpcao == 2
	
	DBSelectArea('SA2')
	SA2->( DBSetOrder(1) )
	If SA2->( DBSeek( xFilial('SA2') + _cRetiro + AllTrim( _cLoja ) ) )
	    
		_oModel:LoadValue( 'ZLIDETAIL' , 'ZLI_RETILJ' , SA2->A2_LOJA )
		_cRet := SA2->A2_LOJA
		
	Else
		_oModel:SetErrorMessage('ZLIDETAIL', 'ZLI_RETILJ' , 'ZLIDETAIL' , 'ZLI_RETILJ' , "AGLT01103", "O Produtor informado não é válido ou não foi encontrado no Sistema!", "Verifique os dados digitados e tente novamente.")
	    _oModel:LoadValue( 'ZLIDETAIL' , 'ZLI_RETILJ' , '' )
	EndIf 
	
ElseIf _nOpcao == 3

	DBSelectArea('ZT1')
	ZT1->( DBSetOrder(1) )
	If ZT1->( DBSeek( xFilial('ZT1') + M->ZLI_EVENTO ) )
		_oModel:LoadValue( 'ZLIMASTER' , 'ZLI_NATURE' , ZT1->ZT1_NATURE )
		_cRet := _cLoja
	EndIf

ElseIf _nOpcao == 4


  _cret := ZT1->ZT1_DESCRI  
  
	If Len(_omodel:AALLSUBMODELS[2]:ACOLS) > 0 .And. Len(AllTrim(_omodel:AALLSUBMODELS[2]:ACOLS[1][2])) == 6
		_oModel:LoadValue( 'ZLIMASTER' , 'ZLI_NATURE' , ZT1->ZT1_NATURE )
	EndIf

EndIf

Return( _cRet )

/*
===============================================================================================================================
Programa----------: AGLT011TOK
Autor-------------: Lucas Borges
Data da Criacao---: 21/03/2019
Descrição---------: Rotina para Validação Total do modelo de dados e gravações auxiliares
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT011TOK()

Local _lRet		:= .T.
Local _aValid	:= {}
Local _aMovPer	:= {}
Local _oModel	:= FWModelActive()
Local _oGrid	:= _oModel:GetModel( 'ZLIDETAIL' )
Local _cCodigo	:= _oModel:GetValue( 'ZLIMASTER' , 'ZLI_COD'    )
Local _cConven	:= _oModel:GetValue( 'ZLIMASTER' , 'ZLI_CONVEN' )
Local _cLjConv	:= _oModel:GetValue( 'ZLIMASTER' , 'ZLI_LJCONV' )
Local _nVlrTot	:= _oModel:GetValue( 'ZLIMASTER' , 'ZLI_VALTOT' )
Local _nAcresc	:= _oModel:GetValue( 'ZLIMASTER' , 'ZLI_ACRESC' )
Local _nTxAdm	:= _oModel:GetValue( 'ZLIMASTER' , 'ZLI_VTXADM' )
Local _cCodPro	:= ''
Local _cLojPro	:= ''
Local _cNatAux	:= _oModel:GetValue( 'ZLIMASTER' , 'ZLI_NATURE' ) //Natureza da NF
Local _cNatNDF	:= _oModel:GetValue( 'ZLIMASTER' , 'ZLI_NATURE' ) //Natureza da NDF
Local _cPrefix	:= ''
Local _dEmissa	:= _oModel:GetValue( 'ZLIMASTER' , 'ZLI_DATA'   )
Local _dVencto	:= _oModel:GetValue( 'ZLIMASTER' , 'ZLI_VENCTO' )
Local _cEvento	:= _oModel:GetValue( 'ZLIMASTER' , 'ZLI_EVENTO' )
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
		_oModel:SetErrorMessage('ZLIMASTER', 'ZLI_CONVEN' , 'ZLIMASTER' , 'ZLI_CONVEN' , "AGLT01104", "O convênio informado está bloqueado no cadastro de Fornecedores do Sistema!", "Verifique o cadastro do convênio ou os dados informados para confirmar.")
		_lRet := .F.
	EndIf
Else
	_oModel:SetErrorMessage('ZLIMASTER', 'ZLI_CONVEN' , 'ZLIMASTER' , 'ZLI_CONVEN' , "AGLT01105", "O convênio informado não foi encontrado no cadastro de Fornecedores do Sistema!", "Verifique o cadastro do convênio ou os dados informados para confirmar.")
	_lRet := .F.
EndIf

If _lRet

	//============================================
	// Validação das datas de Emissão x Vencimento
	//============================================
	If _dEmissa > _dVencto
		_oModel:SetErrorMessage('ZLIMASTER', 'ZLI_VENCTO' , 'ZLIMASTER' , 'ZLI_VENCTO' , "AGLT01106", "A data de vencimento do convênio não é válida!", "O vencimento deve ser maior ou igual à data de emissão do convênio.")
		_lRet := .F.
	EndIf
	
	//===========================================================
	// Validação do preenchimento de todos os campos obrigatórios
	//===========================================================
	If _lRet .And. ( Empty(_cConven) .Or. Empty(_cLjConv) .Or. Empty( _dEmissa ) .Or. Empty( _dVencto ) .Or. Empty( _cEvento ))
		_oModel:SetErrorMessage('ZLIMASTER', 'ZLI_CONVEN' , 'ZLIMASTER' , 'ZLI_CONVEN' , "AGLT01107", "Existem campos do convênio que não foram preenchidos!", "Verifique os dados e informe todos os campos obrigatórios para confirmar.")
		_lRet := .F.
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
		
			_cCodPro	:= _oGrid:GetValue( 'ZLI_RETIRO' )
			_cLojPro	:= _oGrid:GetValue( 'ZLI_RETILJ' )
			_cNomPro	:= Posicione( 'SA2' , 1 , xFilial('SA2') + _cCodPro + _cLojPro , 'A2_NOME' )
			
			If Empty( _cCodPro ) .Or. Empty( _cLojPro ) .Or. Empty( _cNomPro )
				_oModel:SetErrorMessage('ZLIDETAIL', 'ZLI_RETIRO' , 'ZLIDETAIL' , 'ZLI_RETIRO' , "AGLT01108", "É obrigatório informar um produtor para todas os lançamentos do Convênio!", "Verifique os lançamentos e informe produtores válidos para todas as linhas.")
				_lRet := .F.
				Exit
			EndIf
			
			If SA2->A2_MSBLQL == '1'
				aAdd( _aValid , { _cCodPro+'/'+_cLojPro , _cNomPro , 'O fornecedor encontra-se bloqueado no cadastro do Sistema' } )
			EndIf
			
			If _oGrid:GetValue( 'ZLI_VALOR' ) <= 0
				aAdd( _aValid , { _cCodPro+'/'+_cLojPro , _cNomPro , 'Não foi informado um valor válido para o lançamento do convênio' } )
			EndIf
			
		EndIf
			
	Next _nI

EndIf

If _lRet .And. !Empty( _aValid ) .And. _oModel:GetOperation() <> MODEL_OPERATION_DELETE
	
	U_ITListBox( 'Não conformidades nos lançamentos' , { 'Código' , 'Nome' , 'Avaliação' } , _aValid , .F. , 1 , 'Verifique os lançamentos abaixo:' ,, {50,100,200} )
	_oModel:SetErrorMessage('ZLIDETAIL', 'ZLI_RETIRO' , 'ZLIDETAIL' , 'ZLI_RETIRO' , "AGLT01109", "Existem lançamentos que não passaram na validação!", "Verifique os dados do relatório exibido e corrija os lançamentos com problema.")
	_lRet := .F.
	
EndIf

If _lRet .And. !Empty( _aMovPer ) .And. _oModel:GetOperation() <> MODEL_OPERATION_DELETE
	
	_lRet := U_ITListBox( 'Produtores sem movimentação no período' , { 'Código' , 'Nome' , 'Avaliação' } , _aMovPer , .F. , 1 , 'Verifique os lançamentos abaixo:' ,, {50,100,200} )
	
	If !_lRet
		_oModel:SetErrorMessage('ZLIDETAIL', 'ZLI_RETIRO' , 'ZLIDETAIL' , 'ZLI_RETIRO' , "AGLT01110", "Foi cancelada a operação por conta de produtores sem movimentação no período!", "Verifique os dados e caso necessário confirme mesmo com produtores sem movimentação para continuar.")
	EndIf
	
EndIf

//================================================================
// Se passar pelas validações Processa as gravações complementares
//================================================================
If _lRet
	
	_nOper		:= _oModel:GetOperation()
	_cNumTit	:= _oModel:GetValue( 'ZLIMASTER' , 'ZLI_COD'    )
	_cNatNDF	:= _oModel:GetValue( 'ZLIMASTER' , 'ZLI_NATURE' )
	
	_cNatAux	:= Posicione( "ZT1" , 1 , xFilial("ZT1") + _cEvento , "ZT1_NATURE" ) ; IIf( Empty(_cNatAux) , _cNatAux := _cNatNDF , Nil )
	_cPrefix	:= ZT1->ZT1_PREFIX
	
	If _nOper == MODEL_OPERATION_INSERT
		
		If MsgYesNo("Deseja replicar e criar novas parcelas iguais a configuração do convênio atual para meses posteriores?","AGLT01111" )
			
			_lParc := .F.
			
			_aParAux := AGLT011CPA( _dVencto )
			
			If Empty(_aParAux)
				_oModel:SetErrorMessage('ZLIMASTER', 'ZLI_NATURE' , 'ZLIMASTER' , 'ZLI_NATURE' , "AGLT01112", "A geração de parcelas não foi realizada pelo usuário e será gerado apenas o registro do convênio!", "Caso necessário, revise os dados informados.")
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
	    ZT1->(DBSeek(ZLI->(ZLI_FILIAL+ZLI_EVENTO)))
		_lRet := AGLT011DE2( ZT1->ZT1_PREFIX , _cNumTit + '000' , '1 ' , 'NF ' , ZLI->ZLI_CONVEN , ZLI->ZLI_LJCONV , ZLI->ZLI_NATURE, _oModel )
		
		If _lRet
			If _nOper == MODEL_OPERATION_UPDATE
				MsgInfo("O Titulo da NF foi excluido e será gerado novamente com os novos valores!","AGLT01113")
			EndIf
		EndIf
	
	EndIf
	
	If _lRet
	
		//======================
		// Guarda posição do ZLI
		//======================
		_aareaZLI := getarea("ZLI")
		
		//=========================================================
		// Gravação dos títulos de todos os lançamentos do convênio
		//=========================================================
		For _nI := 1 To _nLinhas
		
			_oGrid:GoLine(_nI)
			
			_cSeq		:= _oGrid:GetValue( 'ZLI_SEQ'    )
			_cCodPrd	:= _oGrid:GetValue( 'ZLI_RETIRO' )
			_cLojPrd	:= _oGrid:GetValue( 'ZLI_RETILJ' )
			_nValor		:= _oGrid:GetValue( 'ZLI_VALOR'  )
			_cStatus	:= _oGrid:GetValue( 'ZLI_STATUS' )
			
			//===============================================
			// Posiciona ZLI para saber o que alterou na tela
			//===============================================
			ZLI->(DBSetOrder(1))
			ZLI->(DBSeek(xFilial("ZLI") + _cCodigo + _cSeq))
			
			//================================================
			// Tratativa para os lançamentos deletados no Grid
			//================================================
			If _oGrid:IsDeleted() .And. _nOper == MODEL_OPERATION_UPDATE
				_lRet := AGLT011DE2( ZT1->ZT1_PREFIX , _cNumTit + _cSeq , '1 ' , 'NDF' , ZLI->ZLI_RETIRO , ZLI->ZLI_RETILJ , ZLI->ZLI_NATURE, _oModel )
			ElseIf  !(_oGrid:IsDeleted())
			
				//==========================================
				// Na Inclusão gera os títulos no Financeiro
				//==========================================
				If _nOper == MODEL_OPERATION_INSERT 
					_lRet := AGLT011IE2( _cPrefix , _cNumTit + _cSeq , '1 ' , 'NDF' , _cCodPrd , _cLojPrd , _cNatNDF , _dEmissa , _dVencto , _nValor , 0 , 0 , _oModel )
				EndIf
				
				//=======================================================
				// Tratativa para os lançamentos na operação de alteração
				//=======================================================
				If _nOper == MODEL_OPERATION_UPDATE
					
					//========================================================
					// Se a linha For "Suspensa" deleta o título no Financeiro
					//========================================================
					If _oGrid:GetValue('ZLI_STATUS') == 'S'
					
						_lRet := AGLT011DE2( ZT1->ZT1_PREFIX , _cNumTit + _cSeq , '1 ' , 'NDF' , ZLI->ZLI_RETIRO , ZLI->ZLI_RETILJ , ZLI->ZLI_NATURE, _oModel )
					
					//=================================================================================================
					// Se a linha For "Alterada" e o Status estiver Em Aberto deverá excluir e gerar o Título novamente
					//=================================================================================================
					ElseIf _oGrid:GetValue('ZLI_STATUS') == 'A'
					
						If AGLT011DE2( ZT1->ZT1_PREFIX , _cNumTit + _cSeq , '1 ' , 'NDF' , ZLI->ZLI_RETIRO , ZLI->ZLI_RETILJ , ZLI->ZLI_NATURE, _oModel )
						 	_lRet := AGLT011IE2( _cPrefix , _cNumTit + _cSeq , '1 ' , 'NDF' , _cCodPrd , _cLojPrd , _cNatNDF , _dEmissa , _dVencto , _nValor , 0 , 0 , _oModel )
						Else
							
							DBSelectArea('SE2')
							SE2->( DBSetOrder(1) )
							If SE2->( DBSeek( xFilial('SE2') + ZT1->ZT1_PREFIX + _cNumTit + _cSeq + '1 ' + 'NDF' + ZLI->(ZLI_RETIRO+ZLI_RETILJ) ) )
								_lRet := .F.
							Else
								_lRet := AGLT011IE2( _cPrefix , _cNumTit + _cSeq , '1 ' , 'NDF' , _cCodPrd , _cLojPrd , _cNatNDF , _dEmissa , _dVencto , _nValor , 0 , 0 , _oModel )
							EndIf
						EndIf
						
					EndIf
				
				EndIf
					
				//===============================================================================
				// Para a operação de exclusão do convênio deverão ser excluídos todos os títulos
				//===============================================================================
				If _nOper == MODEL_OPERATION_DELETE
					_lRet := AGLT011DE2( ZT1->ZT1_PREFIX , _cNumTit + _cSeq , '1 ' , 'NDF' , ZLI->ZLI_RETIRO , ZLI->ZLI_RETILJ , ZLI->ZLI_NATURE, _oModel )
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
		// Retorna posição e índice da ZLI
		//================================
		ZLI->(FWRestArea(_aareaZLI))
			
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
					_lRet := AGLT011IE2( _cPrefix , _cNumTit + '000' , '1 ' , 'NF ' , _cConven , _cLjConv , _cNatAux , _dEmissa , _dVencto , _nVlrTot , _nAcresc , _nTxAdm , _oModel )
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
			
				aAdd( _aDados , {	_oModel:GetValue( 'ZLIMASTER' , 'ZLI_NATURE'	) ,;
									_oModel:GetValue( 'ZLIDETAIL' , 'ZLI_SEQ'		) ,;
									_oModel:GetValue( 'ZLIDETAIL' , 'ZLI_RETIRO'	) ,;
									_oModel:GetValue( 'ZLIDETAIL' , 'ZLI_RETILJ'	) ,;
									_oModel:GetValue( 'ZLIDETAIL' , 'ZLI_VALOR'		) ,;
									_oModel:GetValue( 'ZLIDETAIL' , 'ZLI_TXADM'		) ,;
									_oModel:GetValue( 'ZLIDETAIL' , 'ZLI_STATUS'	) ,;
									_oModel:GetValue( 'ZLIDETAIL' , 'ZLI_OBSERV'	) })
			
			EndIf
			
		Next _nI
		
		For _nI := 1 To Len( _aParAux )
			
			_cCodZLI := GetSXENum( 'ZLI' , 'ZLI_COD' )
			
			If __lSX8
				ConfirmSX8()
			EndIf
			
			//==============================================================================================
			// Pega a data de emissão baseada no vencimento: deve ser o último dia do mês anterior ao vencto
			//==============================================================================================
			_dEmissa := LastDay( MonthSub( _aParAux[_nI] , 1 ) )
			
			DBSelectArea('ZLI')
			
			For _nX := 1 To Len( _aDados )
				
				ZLI->( RecLock( 'ZLI' , .T. ) )
				
				ZLI->ZLI_FILIAL		:= xFilial('ZLI')
				ZLI->ZLI_COD		:= _cCodZLI
				ZLI->ZLI_NATURE		:= _aDados[_nX][01]
				ZLI->ZLI_EVENTO		:= _cEvento
				ZLI->ZLI_DATA		:= _dEmissa
				ZLI->ZLI_VENCTO		:= _aParAux[_nI]
				ZLI->ZLI_CONVEN		:= _cConven
				ZLI->ZLI_LJCONV		:= _cLjConv
				ZLI->ZLI_ACRESC		:= _nAcresc
				ZLI->ZLI_SEQ		:= _aDados[_nX][02]
				ZLI->ZLI_RETIRO		:= _aDados[_nX][03]
				ZLI->ZLI_RETILJ		:= _aDados[_nX][04]
				ZLI->ZLI_VALOR		:= _aDados[_nX][05]
				ZLI->ZLI_TXADM		:= _aDados[_nX][06]
				ZLI->ZLI_STATUS		:= _aDados[_nX][07]
				ZLI->ZLI_OBSERV		:= _aDados[_nX][08]
				
				ZLI->( MSUnLock() )
				
				//=====================================
				// Inclui nova NDF para a parcela atual
				//=====================================
				If !AGLT011IE2( _cPrefix , ZLI->( ZLI_COD + ZLI_SEQ ) , '1 ' , 'NDF' , ZLI->ZLI_RETIRO , ZLI->ZLI_RETILJ , ZLI->ZLI_NATURE , ZLI->ZLI_DATA , ZLI->ZLI_VENCTO , ZLI->ZLI_VALOR , 0 , 0 , _oModel )
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
			
				If !AGLT011IE2( _cPrefix , _cCodZLI + '000' , '1 ' , 'NF ' , _cConven , _cLjConv , _cNatAux , _dEmissa , _aParAux[_nI] , _nVlrTot , _nAcresc , _nTxAdm , _oModel )
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
_aAreaZLI := ZLI->(GetArea())
If _lRet .And. _oModel:GetOperation() == MODEL_OPERATION_UPDATE
	DBSelectArea("ZLI")
	DBSetOrder(1)
	If DBSeek(xFilial("ZLI") + _cCodigo)
		While !ZLI->(Eof()) .And. ZLI->ZLI_FILIAL == xFilial("ZLI") .And. ZLI->ZLI_COD == _cCodigo
			RecLock("ZLI", .F.)
				ZLI->ZLI_EVENTO	:= _cEvento
				ZLI->ZLI_CONVEN	:= _cConven
				ZLI->ZLI_LJCONV	:= _cLjConv
				ZLI->ZLI_VENCTO	:= _dVencto
				ZLI->ZLI_ACRESC	:= _nAcresc
			MSUnLock()
			ZLI->(DBSkip())
		End
	EndIf
EndIf
FWRestArea(_aAreaZLI)
Return( _lRet )

/*
===============================================================================================================================
Programa----------: AGLT011DE2
Autor-------------: Lucas Borges
Data da Criacao---: 21/03/2019
Descrição---------: Rotina para exclusão de Títulos do Financeiro
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT011DE2( _cPrefix , _cNumTit , _cParcel , _cTipo , _cForn , _cLoja , _cNature, _oModel )

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
		_oModel:SetErrorMessage('ZLIMASTER', 'ZLI_NATURE' , 'ZLIMASTER' , 'ZLI_NATURE' , "AGLT01114", "Título sofreu baixas e não poderá ser excluído. Título: " + _cPrefix + _cNumTit + _cParcel + _cTipo + _cForn + _cLoja, "Exclua a baixa antes de realizar a operação.")
	    _lOk := .F.
	Else
	
		_aAutSE2 := { { "E2_PREFIXO" , SE2->E2_PREFIXO , NIL },;
	                { "E2_NUM"     , SE2->E2_NUM     , NIL } }

		MSExecAuto( {|x,y,z| Fina050(x,y,z) } , _aAutSE2 ,, 5 )

		If lMsErroAuto
			MostraErro()
			_oModel:SetErrorMessage('ZLIMASTER', 'ZLI_NATURE' , 'ZLIMASTER' , 'ZLI_NATURE' , "AGLT01115", "Falhou ao excluir o título do convênio no Financeiro!", "Informe a área de TI/ERP.")
			_lOk := .F.
		EndIf
		
    EndIf
Else                            

	If _cForn <> 'F00001'
		_oModel:SetErrorMessage('ZLIMASTER', 'ZLI_NATURE' , 'ZLIMASTER' , 'ZLI_NATURE' , "AGLT01116", "Não encontrou o título do convênio no  Financeiro!", "Informe a área de TI/ERP.")
		_lOk := .F.
	EndIf

EndIf

nModulo := _nModAux
cModulo := _cModAux

FWRestArea(aArea)

Return( _lOk )

/*
===============================================================================================================================
Programa----------: AGLT011IE2
Autor-------------: Lucas Borges
Data da Criacao---: 21/03/2019
Descrição---------: Rotina para inclusão de Títulos no Financeiro
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT011IE2( _cPrefix , _cNumTit , _cParcel , _cTipo , _cForn , _cLoja , _cNature , _dEmissa , _dVencto , _nValor , _nAcres , _nDesc , _oModel )

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
aAdd( _aAutSE2 , { "E2_HIST"	, "GLT CONVENIO DE TERCEIROS", nil } )
aAdd( _aAutSE2 , { "E2_DATALIB"	, _dEmissa		, nil } )	
aAdd( _aAutSE2 , { "E2_USUALIB"	, cUserName		, nil } )	
aAdd( _aAutSE2 , { "E2_ORIGEM"	, "AGLT011"		, nil } )

nModulo := 6
cModulo := "FIN"

MSExecAuto( {|x,y| Fina050(x,y) } , _aAutSE2 , 3 )

If lMsErroAuto
	MostraErro()
	_oModel:SetErrorMessage('ZLIMASTER', 'ZLI_NATURE' , 'ZLIMASTER' , 'ZLI_NATURE' , "AGLT01117", "Falhou ao incluir o título do convênio no Financeiro!", "Informe a área de TI/ERP.")
	_lOk := .F.
Else
	DBSelectArea('SE2')
	SE2->( DBSetOrder(1) )
	If !SE2->( DBSeek( xFilial('SE2') + _aAutSE2[01][02] + _aAutSE2[02][02] + _aAutSE2[03][02] + _aAutSE2[04][02] + _aAutSE2[06][02] + _aAutSE2[07][02] ) )
		_oModel:SetErrorMessage('ZLIMASTER', 'ZLI_NATURE' , 'ZLIMASTER' , 'ZLI_NATURE' , "AGLT01118", "Falhou ao incluir o título do convênio no Financeiro!", "Informe a área de TI/ERP.")
		_lOk := .F.
	EndIf

EndIf

nModulo := _nModAux
cModulo := _cModAux

Return( _lOk )

/*
===============================================================================================================================
Programa----------: AGLT011V
Autor-------------: Lucas Borges
Data da Criacao---: 21/03/2019
Descrição---------: Rotina para inicialização de valores para os campos virtuais da tela
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT011V( _nOpc )

Local _aArea	:= FWGetArea()
Local _cAlias	:= ''
Local _nValRet	:= 0

Default _nOpc	:= 0

If !Inclui .And. _nOpc > 0
	
	_cAlias	:= GetNextAlias()
	BeginSql alias _cAlias
	  SELECT SUM(ZLI.ZLI_VALOR) VALOR,
	         SUM(Case
	               WHEN ZLI.ZLI_STATUS = 'A' THEN
	                ZLI.ZLI_VALOR
	               Else
	                0
	             END) VALABR,
	         Round(SUM(ZLI.ZLI_VALOR) * (SA2.A2_L_TXADM/100),2) VALADM,
	         SA2.A2_L_TXADM TXADM
	    FROM %Table:ZLI% ZLI
	    JOIN %Table:SA2% SA2
	      ON SA2.D_E_L_E_T_ = ' '
	     AND SA2.A2_COD = ZLI.ZLI_CONVEN
	     AND SA2.A2_LOJA = ZLI.ZLI_LJCONV
	   WHERE ZLI.D_E_L_E_T_ = ' '
	     AND ZLI_FILIAL = %exp:ZLI->ZLI_FILIAL%
	     AND ZLI_COD = %exp:ZLI->ZLI_COD%
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
Programa----------: AGLT011R
Autor-------------: Lucas Borges
Data da Criacao---: 21/03/2019
Descrição---------: Rotina para inicialização do campo nome do produtor
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT011R()

Local _oModel	:= FWModelActive()
Local _cRet		:= ''

If !Inclui
	If ValType(_oModel) == "O"
		If _oModel:GetModel('ZLIDETAIL'):nLine > 0
			If !_oModel:GetOperation() == MODEL_OPERATION_UPDATE
				_cRet := AllTrim( Posicione('SA2',1,xFilial('SA2')+_oModel:GetValue('ZLIDETAIL','ZLI_RETIRO')+_oModel:GetValue('ZLIDETAIL','ZLI_RETILJ'),'A2_NOME') )
			EndIf
		Else
			_cRet := AllTrim( Posicione('SA2',1,xFilial('SA2')+ZLI->(ZLI_RETIRO+ZLI_RETILJ),'A2_NOME') )
		EndIf
	Else
		_cRet := AllTrim( Posicione('SA2',1,xFilial('SA2')+ZLI->(ZLI_RETIRO+ZLI_RETILJ),'A2_NOME') )
	EndIf
EndIf

Return( _cRet )

/*
===============================================================================================================================
Programa----------: AGLT011CPA
Autor-------------: Lucas Borges
Data da Criacao---: 21/03/2019
Descrição---------: Monta a tela para digitação das datas de parcelas adicionais para o convênio
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT011CPA( _dVencto )

Local _lOk			:= .F.
Local _aRet			:= {}
Local _nI			:= 0
Local aButtons		:= {}
Local cLinOk		:= "AllwaysTrue"
Local cTudoOk		:= "AllwaysTrue"
Local cIniCpos		:= "ZLI_VENCTO"
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
aAdd( aAlterGDa  , 'ZLI_VENCTO' )

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
Programa----------: AGLT011VLD
Autor-------------: Lucas Borges
Data da Criacao---: 21/03/2019
Descrição---------: Validação inicial da DataBase do Sistema para não permitir manutenção de dados em períodos bloqueados pelo
------------------: parâmetro Fiscal ou Financeiro
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT011VLD( _oModel )

Local _lRet		:= .T.

If _oModel:GetOperation() == MODEL_OPERATION_INSERT .Or. _oModel:GetOperation() == MODEL_OPERATION_UPDATE .Or. _oModel:GetOperation() == MODEL_OPERATION_DELETE

	If dDataBase < GetMV('MV_DATAFIN')
		_oModel:SetErrorMessage('ZLIMASTER', 'ZLI_DATA' , 'ZLIMASTER' , 'ZLI_DATA' , "AGLT01119", "A DataBase do Sistema não é válida de acordo com o parâmetro Financeiro.", "Corrija a DataBase ou solicite liberação para a Contabilidade.")
		_lRet := .F.
	EndIf
	
	If _lRet .And. dDataBase <> LastDay( dDataBase )
		_oModel:SetErrorMessage('ZLIMASTER', 'ZLI_DATA' , 'ZLIMASTER' , 'ZLI_DATA' , "AGLT01120", "A DataBase do Sistema não é válida pois não está posicionada no último dia do mês selecionado ("+DToC(LastDay(dDataBase))+")", "Para realizar a manutenção no convênio configure a DataBase no último dia do mês que estiver sendo utilizado.")
		_lRet := .F.
	EndIf
	
EndIf

Return( _lRet )
