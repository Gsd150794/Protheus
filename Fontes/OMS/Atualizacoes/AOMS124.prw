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
Data da Criacao---: 08/06/2021
===============================================================================================================================
Descrição---------: Cadastro de MicroRegião. Chamado: 36780
===============================================================================================================================
Parametros--------: 
===============================================================================================================================
Retorno-----------:  
===============================================================================================================================
*/ 
User Function AOMS124()
Local _oBrowse := Nil

_oBrowse := FWMBrowse():New()
_oBrowse:SetAlias("Z22")
_oBrowse:SetMenuDef( 'AOMS124' )
_oBrowse:SetDescription("Cadastro de Microregião")
_oBrowse:Activate()

Return

/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Igor Melgaço
Data da Criacao---: 08/06/2021
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

Return( FWMVCMenu("AOMS124") )

/*
===============================================================================================================================
Programa----------: ModelDef
Autor-------------: Igor Melgaço
Data da Criacao---: 08/06/2021
===============================================================================================================================
Descrição---------: Rotina de definição do Modelo de Dados do MVC
===============================================================================================================================
Parametros--------: 
===============================================================================================================================
Retorno-----------: _oModel - Objeto do modelo de dados do MVC 
===============================================================================================================================
*/ 
Static Function ModelDef()
Local _oStruZ22 := FWFormStruct(1,"Z22")
Local _oModel
Local _bPosValidacao := {||U_AOMS124V()}
Local _aGatAux	:= {}

_aGatAux := FwStruTrigger( 'Z22_EST', 'Z22_REGIAO', 'U_AOMS123E(M->Z22_EST)', .F. )
_oStruZ22:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_oModel := MPFormModel():New("AOMS124M" ,  /*bPreValidacao*/ , _bPosValidacao , /*bCommit*/ , /*bCancel*/)
_oModel:AddFields("Z22MASTER", /*cOwner*/ , _oStruZ22 , /*bPreValidacao*/ , /*_bPosValidacao*/ , /*bCarga*/)
_oModel:SetDescription("Modelo de Dados Microregião")
_oModel:GetModel('Z22MASTER'):SetDescription("Dados Microregião")
_oModel:SetPrimaryKey( {'Z22_FILIAL','Z22_COD' } )

Return _oModel

/*
===============================================================================================================================
Programa----------: ViewDef
Autor-------------: Igor Melgaço
Data da Criacao---: 08/06/2021
===============================================================================================================================
Descrição---------: Rotina de definição da View do MVC
===============================================================================================================================
Parametros--------: 
===============================================================================================================================
Retorno-----------: _oView - Objeto de exibição do MVC  
===============================================================================================================================
*/ 
Static Function ViewDef()
Local _oStruZ22 := FWFormStruct(2,"Z22")
Local _oModel := FWLoadModel("AOMS124")
Local _oView := Nil

_oView := FWFormView():New()
_oView:SetModel(_oModel)
_oView:AddField("VIEW_Z22", _oStruZ22 , "Z22MASTER")

_oView:CreateHorizontalBox("TELA",100)
_oView:SetOwnerView("VIEW_Z22","TELA")

Return _oView


/*
===============================================================================================================================
Programa----------: AOMS124V
Autor-------------: Igor Melgaço
Data da Criacao---: 08/06/2021
===============================================================================================================================
Descrição---------: Rotina de validação
===============================================================================================================================
Parametros--------: 
===============================================================================================================================
Retorno-----------: _lReturn  
===============================================================================================================================
*/ 
User Function AOMS124V()
Local _lReturn      := .T.
Local _aOrd         := SaveOrd({"Z22"})
Local _oModel       := FwModelActivete()
Local _oModelMaster := _oModel:GetModel("Z22MASTER")
Local _cCod         := _oModelMaster:GetValue('Z22_COD' ) 
Local _nOperation   := _oModel:GetOperation() 
Local _lValida      := .F.

If _nOperation == MODEL_OPERATION_INSERT 
    _lValida      := .T.
ElseIf _nOperation == MODEL_OPERATION_UPDATE
    If _cCod <> Z22->Z22_COD
        _lValida      := .T.
    EndIf
EndIf

If _lValida
    Z22->(DBSetOrder(1))
    If Z22->( DBSeek(xFilial("Z22")+_cCod) )
        _lReturn := .F.
        U_ITMsg("Código da Microregião informado já consta no cadastro. ",;
              "Atenção",;
              "Modifique o código digitado.  ",3 , , , .T.)

        _lRet := .F.
          
    EndIf
EndIf

RestOrd(_aOrd)

Return _lReturn
