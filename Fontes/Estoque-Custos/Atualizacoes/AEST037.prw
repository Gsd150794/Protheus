/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Josué Danich  |11/06/2019| Chamado 29593. Ajustes para loboguara
Lucas Borges  |10/09/2024| Chamado 48465. Removendo warning de compilação.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: AEST037
Autor-------------: Lucas Crevilari
Data da Criacao---: 24/07/2014
Descrição---------: Rotina para realizar as operacoes de inclusao, alteracao e exclusao dos dados de Familias de Produto
Parametros--------: 
Retorno-----------: 
===============================================================================================================================
*/
User Function AEST037
Local oBrowse := Nil

oBrowse := FWMBrowse():New()
oBrowse:SetAlias( "ZB3" )
oBrowse:SetDescription( "Cadastro de Familia" )
oBrowse:SetOnlyFields( {'ZB3_CODFAM','ZB3_DESFAM'} )
oBrowse:Activate()

Return

/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Lucas Crevilari
Data da Criacao---: 24/07/2014
Descrição---------: Rotina de definição automática do menu via MVC
Parametros--------: Nenhum
Retorno-----------: aRotina - Definições do menu principal da Rotina.
===============================================================================================================================
*/
Static Function MenuDef()

//===========================================================================
//FWMVCMenu - Gera o menu padrão para o Modelo Informado (Inc/Alt/Vis/Exc)
//===========================================================================

Return( FWMVCMenu("AEST037") )

/*
===============================================================================================================================
Programa----------: ModelDef
Autor-------------: Lucas Crevilari
Data da Criacao---: 24/07/2014
Descrição---------: Rotina de definição do Modelo de Dados do MVC
Parametros--------: Nenhum
Retorno-----------: oModel - Objeto do modelo de dados do MVC
===============================================================================================================================
*/
Static Function ModelDef

Local oStruZB3 	:= FWFormStruct( 1 , "ZB3" )
Local oModel	:= Nil

oModel := MPFormModel():New( "AEST037M" ,  /*bPreValidacao*/ , /*bPosValidacao*/ , /*bCommit*/ , /*bCancel*/ )
oModel:SetDescription( "Familias" )
oModel:AddFields( "ZB3MASTER", /*cOwner*/ , oStruZB3 , /*bPreValidacao*/ , /*bPosValidacao*/ , /*bCarga*/ )
oModel:GetModel( "ZB3MASTER" ):SetDescription( "Familias" )
oModel:SetVldActivate( { |oModel| AEST037VLD( oModel ) } )

Return( oModel )

/*
===============================================================================================================================
Programa----------: ViewDef
Autor-------------: Lucas Crevilari
Data da Criacao---: 24/07/2014
Descrição---------: Rotina de definição da View do MVC
Parametros--------: Nenhum
Retorno-----------: oView - Objeto de exibição do MVC
===============================================================================================================================
*/
Static Function ViewDef

Local oModel   	:= FWLoadModel( "AEST037" )
Local oStruZB3 	:= FWFormStruct( 2 , "ZB3" )
Local oView		:= Nil

oView := FWFormView():New()
oView:SetModel( oModel )
oView:AddField( "VIEW_ZB3" , oStruZB3 , "ZB3MASTER" )

Return(oView)
  
/*
===============================================================================================================================
Programa----------: VldZB3
Autor-------------: Lucas Crevilari
Data da Criacao---: 24/07/2014
Descrição---------: Pontos de Entrada do MVC
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AEST037VLD( oModel )

Local _lRet		:= .T. 
Local _cAlias	:= GetNextAlias()
Local _nOper	:= oModel:GetOperation()

If (_nOper == 4 .Or. _nOper == 5) .And. !Empty(ZB3->ZB3_CODFAM)
	BeginSql alias _cAlias
		SELECT COUNT(1) QTD FROM %Table:ZB9% 
		WHERE D_E_L_E_T_ = ' ' AND ZB9_CODFAM = %exp:ZB3->ZB3_CODFAM%
	EndSql

	If (_cAlias)->QTD > 0
		_lRet	:= .F.
		FWAlertWarning("Não é possível realizar a alteração ou exclusao de Familias amarradas ao cadastro de algum sub grupo."+;
						"Favor excluir as amarrações de sub grupo da familia que deseja realizar a alteração ou exclusão.","AEST03701")
	EndIf
	
	(_cAlias)->(DBCloseArea())
EndIf

Return _lRet
