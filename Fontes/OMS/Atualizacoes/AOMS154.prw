/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
       Autor      |    Data    |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------

===============================================================================================================================
*/

#Include "FWMBROWSE.CH"
#Include "FWMVCDEF.CH"
#Include "TOTVS.ch"
#Include "TOPCONN.CH"
#Include "RWMAKE.CH"

/*
===============================================================================================================================
Programa----------: AOMS154
Autor-------------: Igor Melgaço
Data da Criacao---: 28/12/2021
===============================================================================================================================
Descrição---------: Premissa Vs Produtos. Chamado: 50568 
===============================================================================================================================
Parametros--------: 
===============================================================================================================================
Retorno-----------:  
===============================================================================================================================
*/ 
User Function AOMS154()
Local _oBrowse := Nil

_oBrowse := FWMBrowse():New()
_oBrowse:SetAlias("Z39")
_oBrowse:SetMenuDef( 'AOMS154' )
_oBrowse:SetDescription("Premissa Vs Produtos")
_oBrowse:Activate()

Return

/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Igor Melgaço
Data da Criacao---: 08/05/2025
===============================================================================================================================
Descrição---------: Rotina de definição automática do menu via MVC
===============================================================================================================================
Parametros--------: 
===============================================================================================================================
Retorno-----------: aRotina - Definições do menu principal da Rotina.
===============================================================================================================================
*/
Static Function MenuDef()
Local _aRotina	:= {}

ADD OPTION _aRotina Title 'Visualizar'	Action 'VIEWDEF.AOMS154'	OPERATION 2 ACCESS 0
ADD OPTION _aRotina Title 'Incluir'   	Action 'VIEWDEF.AOMS154'	OPERATION 3 ACCESS 0
ADD OPTION _aRotina Title 'Alterar'   	Action 'VIEWDEF.AOMS154'	OPERATION 4 ACCESS 0
ADD OPTION _aRotina Title 'Excluir'		Action 'VIEWDEF.AOMS154'	OPERATION 5 ACCESS 0
ADD OPTION _aRotina Title 'Copiar'     Action 'VIEWDEF.AOMS154'   OPERATION 9 ACCESS 0

Return( _aRotina )

/*
===============================================================================================================================
Programa----------: ModelDef
Autor-------------: Igor Melgaço
Data da Criacao---: 08/05/2025
===============================================================================================================================
Descrição---------: Rotina de definição do Modelo de Dados do MVC
===============================================================================================================================
Parametros--------: 
===============================================================================================================================
Retorno-----------: _oModel - Objeto do modelo de dados do MVC 
===============================================================================================================================
*/ 
Static Function ModelDef()
Local _oModel := Nil
Local _oStZ39CAB := FWFormStruct(1,"Z39",{ |x| AllTrim(x) $ 'Z39_COD, Z39_DESC, Z39_PERIOD' } )
Local _oStZ39DET := FWFormStruct(1,"Z39",{ |x| AllTrim(x) $ 'Z39_PRODUT,Z39_DESCP,Z39_TIPO, Z39_UM, Z39_FATOR, Z39_TPCONV' } )

_oModel := MPFormModel():New("AOMS154M",/*bPreValidacao*/ ,/*_bPosValidacao*/ ,/*bCommit*/,/*bCancel*/) 

_oModel:AddFields("Z39MASTER",/*cOwner*/,_oStZ39CAB)
_oModel:AddGrid("Z39DETAIL" , "Z39MASTER" , _oStZ39DET , )
_oModel:SetRelation( "Z39DETAIL" , {	{ 'Z39_FILIAL'	, 'xFilial("Z39")'	} ,;
                                       { 'Z39_COD'	   , 'Z39_COD'	         } ,;
                                       { 'Z39_PERIOD'	, 'Z39_PERIOD'	      } }, Z39->( IndexKey( 1 ) ) )

_oModel:GetModel( 'Z39DETAIL' ):SetUniqueLine( { 'Z39_PRODUT' } )   

_oModel:SetPrimaryKey({'Z39_FILIAL','Z39_COD','Z39_PERIOD'})
     
_oModel:SetDescription("Premissa Vs Produtos")

_oModel:SetVldActivate( { |_oModel| .T. } )

Return _oModel

/*
===============================================================================================================================
Programa----------: ViewDef
Autor-------------: Igor Melgaço
Data da Criacao---: 08/05/2025
===============================================================================================================================
Descrição---------: Rotina de definição da View do MVC
===============================================================================================================================
Parametros--------: 
===============================================================================================================================
Retorno-----------: _oView - Objeto de exibição do MVC  
===============================================================================================================================
*/ 
Static Function ViewDef()
Local _oModel := FWLoadModel("AOMS154")
Local _oStZ39CAB := FWFormStruct(2,"Z39",{ |x| AllTrim(x) $ 'Z39_COD, Z39_DESC, Z39_PERIOD' } )
Local _oStZ39DET := FWFormStruct(2,"Z39",{ |x| AllTrim(x) $ 'Z39_PRODUT,Z39_DESCP,Z39_TIPO, Z39_UM, Z39_FATOR, Z39_TPCONV' } )
Local _oView := Nil

_oStZ39DET:RemoveField('Z39_DESC')

_oView := FWFormView():New()
_oView:SetModel(_oModel)

_oView:AddField( "VIEW_MASTER", _oStZ39CAB	, "Z39MASTER" )
_oView:AddGrid(  "VIEW_DETAIL", _oStZ39DET	, "Z39DETAIL" )
     
_oView:CreateHorizontalBox( 'BOX0101' , 20 )
_oView:CreateHorizontalBox( 'BOX0102' , 80 )
_oView:SetOwnerView( "VIEW_MASTER" , "BOX0101" )
_oView:SetOwnerView( "VIEW_DETAIL" , "BOX0102" )

//_oView:EnableTitleView('VIEW_Z39', ' ' )  
     
//Força o fechamento da janela na confirmação
_oView:SetCloseOnOk({||.T.})

//_oView:SetOwnerView("VIEW_Z39","TELA")

Return _oView


/*
===============================================================================================================================
Programa----------: AOMS154J
Autor-------------: Igor Melgaço
Data da Criacao---: 13/05/2025
===============================================================================================================================
Descrição---------: Inicializa o campo Z39_COD
===============================================================================================================================
Parametros--------: 
===============================================================================================================================
Retorno-----------: _cCod
===============================================================================================================================
*/ 
User Function AOMS154J()

   If INCLUI  
     _cCod := Space(Len(Z39->Z39_COD))
   Else
      _cCod := Z39->Z39_COD
   EndIf
   
Return _cCod


/*
===============================================================================================================================
Programa----------: AOMS154L
Autor-------------: Igor Melgaço
Data da Criacao---: 13/05/2025
===============================================================================================================================
Descrição---------: Inicializa o campo Z39_PERIOD
===============================================================================================================================
Parametros--------: 
===============================================================================================================================
Retorno-----------: _cCod
===============================================================================================================================
*/ 
User Function AOMS154L()

   If INCLUI  
      _cCod := Space(Len(Z39->Z39_PERIOD))
   Else
      _cCod := Z39->Z39_PERIOD
   EndIf
   
Return _cCod

