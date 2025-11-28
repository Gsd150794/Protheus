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
Programa----------: AOMS112
Autor-------------: Igor Melgaço
Data da Criacao---: 25/06/2021
===============================================================================================================================
Descrição---------: Cadastro de Operador Logístico. Chamado: 36841
===============================================================================================================================
Parametros--------: 
===============================================================================================================================
Retorno-----------:  
===============================================================================================================================
*/ 
User Function AOMS125()
Local _oBrowse := Nil

_oBrowse := FWMBrowse():New()
_oBrowse:SetAlias("Z23")
_oBrowse:SetMenuDef( 'AOMS125' )
_oBrowse:SetDescription("Cadastro de Operador Logístico")
_oBrowse:Activate()

Return

/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Igor Melgaço
Data da Criacao---: 25/06/2021
===============================================================================================================================
Descrição---------: Rotina de definição automática do menu via MVC
===============================================================================================================================
Parametros--------: 
===============================================================================================================================
Retorno-----------: aRotina - Definições do menu principal da Rotina.
===============================================================================================================================
*/
Static Function MenuDef()

//===========================================================================
//| FWMVCMenu - Gera o menu padrão para o Modelo Informado (Inc/Alt/Vis/Exc) |
//===========================================================================

Return( FWMVCMenu("AOMS125") )

/*
===============================================================================================================================
Programa----------: ModelDef
Autor-------------: Igor Melgaço
Data da Criacao---: 25/06/2021
===============================================================================================================================
Descrição---------: Rotina de definição do Modelo de Dados do MVC
===============================================================================================================================
Parametros--------: 
===============================================================================================================================
Retorno-----------: _oModel - Objeto do modelo de dados do MVC 
===============================================================================================================================
*/ 
Static Function ModelDef()
Local _oStruZ23 := FWFormStruct(1,"Z23")
Local _oModel
Local _bPosValidacao := {||U_AOMS125V()}
Local _aGatAux	:= {}

//Z23_ZONAEN
_aGatAux := FwStruTrigger( 'Z23_ZONAEN', 'Z23_NZONA', 'Posicione("Z25",1,xFilial("Z25")+M->Z23_ZONAEN,"Z25_NOME")', .F. )
_oStruZ23:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

//Z23_TRANS
_aGatAux := FwStruTrigger( 'Z23_TRANS', 'Z23_LOJA', 'Posicione("SA2",1,xFilial("SA2")+M->Z23_TRANS+AllTrim(M->Z23_LOJA),"A2_LOJA")', .F. )
_oStruZ23:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'Z23_TRANS', 'Z23_NOME', 'Posicione("SA2",1,xFilial("SA2")+M->Z23_TRANS+M->Z23_LOJA,"A2_NOME")', .F. )
_oStruZ23:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'Z23_TRANS', 'Z23_FANTAS', 'Posicione("SA2",1,xFilial("SA2")+M->Z23_TRANS+M->Z23_LOJA,"A2_NREDUZ")', .F. )
_oStruZ23:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

//Z23_LOJA
_aGatAux := FwStruTrigger( 'Z23_LOJA', 'Z23_NOME', 'Posicione("SA2",1,xFilial("SA2")+M->Z23_TRANS+M->Z23_LOJA,"A2_NOME")', .F. )
_oStruZ23:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'Z23_LOJA', 'Z23_FANTAS', 'Posicione("SA2",1,xFilial("SA2")+M->Z23_TRANS+M->Z23_LOJA,"A2_NREDUZ")', .F. )
_oStruZ23:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )


_oModel := MPFormModel():New("AOMS125M" ,  /*bPreValidacao*/ , _bPosValidacao , /*bCommit*/ , /*bCancel*/)
_oModel:AddFields("Z23MASTER", /*cOwner*/ , _oStruZ23 , /*bPreValidacao*/ , /*_bPosValidacao*/ , /*bCarga*/)
_oModel:SetDescription("Operador Logístico")
_oModel:GetModel('Z23MASTER'):SetDescription("Operador Logístico")
_oModel:SetPrimaryKey( {'Z23_FILIAL','Z23_TRANS','Z23_LOJA','Z23_ZONAEN'} )

Return _oModel

/*
===============================================================================================================================
Programa----------: ViewDef
Autor-------------: Igor Melgaço
Data da Criacao---: 25/06/2021
===============================================================================================================================
Descrição---------: Rotina de definição da View do MVC
===============================================================================================================================
Parametros--------: 
===============================================================================================================================
Retorno-----------: _oView - Objeto de exibição do MVC  
===============================================================================================================================
*/ 
Static Function ViewDef()
Local _oStruZ23 := FWFormStruct(2,"Z23")
Local _oModel := FWLoadModel("AOMS125")
Local _oView := Nil

_oView := FWFormView():New()
_oView:SetModel(_oModel)
_oView:AddField("VIEW_Z23", _oStruZ23 , "Z23MASTER")

_oView:CreateHorizontalBox("TELA",100)
_oView:SetOwnerView("VIEW_Z23","TELA")

Return _oView


/*
===============================================================================================================================
Programa----------: AOMS125V
Autor-------------: Igor Melgaço
Data da Criacao---: 25/06/2021
===============================================================================================================================
Descrição---------: Rotina de validação
===============================================================================================================================
Parametros--------: 
===============================================================================================================================
Retorno-----------: _lReturn  
===============================================================================================================================
*/ 
User Function AOMS125V()
Local _lReturn      := .T.
Local _aOrd         := SaveOrd({"Z23"})
Local _oModel       := FwModelActivete()
Local _oModelMaster := _oModel:GetModel("Z23MASTER")
Local _cTransp      := _oModelMaster:GetValue('Z23_TRANS' ) 
Local _cLoja        := _oModelMaster:GetValue('Z23_LOJA' ) 
Local _cZona         := _oModelMaster:GetValue('Z23_ZONAEN' ) 
Local _nOperation   := _oModel:GetOperation() 
Local _lValida      := .F.

If _nOperation == MODEL_OPERATION_INSERT 
    _lValida      := .T.
ElseIf _nOperation == MODEL_OPERATION_UPDATE
    If (_cTransp+_cLoja+_cZona) <> (Z23->Z23_TRANS+Z23->Z23_LOJA+Z23->Z23_ZONAEN)
        _lValida      := .T.
    EndIf
EndIf

If _lValida
    Z23->(DBSetOrder(1))
    If Z23->( DBSeek(xFilial("Z23")+_cTransp+_cLoja+_cZona) )
        _lReturn := .F.

		U_ITMsg("Chave (Transportadora + Loja + Zona de Entrega) informada já consta no cadastro. ",;
                "Atenção",;
                "Verifique e modifique o chave digitada.  ",3 , , , .T.)	
          
    EndIf
EndIf

RestOrd(_aOrd)

Return _lReturn
