/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Darcio Sporl  |31/01/2017| Cadastro de Tipo de Produto X Conta Contábil. Chamado 4058.												|
=====================================================================================================================================
*/

#Include "TOTVS.ch"
#Include 'FWMVCDEF.CH'

/*
===============================================================================================================================
Programa----------: AFIS007
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 31/01/2017
Descrição---------: Cadastro de Tipo de Produto x Conta Contábil
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AFIS007()

Local oBrowse := Nil

oBrowse := FWMBrowse():New()

oBrowse:SetAlias("ZG3")
oBrowse:SetDescription("Cadastro de Tipo de Produto x Conta Contábil")
oBrowse:Activate()

Return(Nil)

/*
===============================================================================================================================
Programa----------: ModelDef
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 31/01/2017
Descrição---------: Rotina para montagem do modelo de dados para o processamento
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ModelDef()

Local oStruZG3	:= FWFormStruct(1,"ZG3")
Local oModel	:= Nil

oModel := MpFormModel():New('AFIS007M')

oModel:AddFields('ZG3MASTER', , oStruZG3)

oModel:SetPrimaryKey( {'ZG3_FILIAL','ZG3_TIPO' } )

Return(oModel)

/*
===============================================================================================================================
Programa----------: ViewDef
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 31/01/2017
Descrição---------: Rotina para montar a View de Dados para exibição
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ViewDef()

Local oModel	:= FWLoadModel('AFIS007')
Local oStruZG3	:= FWFormStruct(2,'ZG3')
Local oView		:= Nil

oView := FWFormView():New()

oView:SetModel(oModel)

oView:AddField('VIEW_ZG3',oStruZG3,'ZG3MASTER')

oView:CreateHorizontalBox('TELA', 100)

oView:SetOwnerView('VIEW_ZG3','TELA')

Return(oView)

/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 31/01/2017
Descrição---------: Rotina para criação do menu da tela principal
Parametros--------: Nenhum
Retorno-----------: _aRotina - Array com as opções de menu
===============================================================================================================================
*/
Static Function MenuDef()

Local _aRotina := {}

ADD OPTION _aRotina Title 'Visualizar'	Action 'VIEWDEF.AFIS007'	OPERATION 2 ACCESS 0
ADD OPTION _aRotina Title 'Incluir'   	Action 'VIEWDEF.AFIS007'	OPERATION 3 ACCESS 0
ADD OPTION _aRotina Title 'Alterar'   	Action 'VIEWDEF.AFIS007'	OPERATION 4 ACCESS 0
ADD OPTION _aRotina Title 'Excluir'		Action 'VIEWDEF.AFIS007'	OPERATION 5 ACCESS 0
ADD OPTION _aRotina Title 'Imprimir' 	Action 'VIEWDEF.AFIS007'	OPERATION 8 ACCESS 0
ADD OPTION _aRotina Title 'Copiar' 		Action 'VIEWDEF.AFIS007'	OPERATION 9 ACCESS 0

Return(_aRotina)
