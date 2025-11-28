/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
------------------------------------------------------------------------------------------------------------------------------- 
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "FWMVCDef.ch"

/*
===============================================================================================================================
Programa----------: AFIN032
Autor-------------: Igor Melgaço
Data da Criacao---: 23/12/2022
Descrição---------: Parâmetros de Integração Paytrack. Chamado: 42331
Parametros--------: 
Retorno-----------:  
===============================================================================================================================
*/ 
User Function AFIN032()
Local _oBrowse := Nil

_oBrowse := FWMBrowse():New()
_oBrowse:SetAlias("Z30")
_oBrowse:SetMenuDef( 'AFIN032' )
_oBrowse:SetDescription("Parâmetros de Integração Paytrack")
_oBrowse:Activate()

Return

/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Igor Melgaço
Data da Criacao---: 08/06/2021
Descrição---------: Rotina de definição automática do menu via MVC
Parametros--------: 
Retorno-----------: aRotina - Definições do menu principal da Rotina.
===============================================================================================================================
*/
Static Function MenuDef()

//===========================================================================
//| FWMVCMenu - Gera o menu padrão para o Modelo Informado (Inc/Alt/Vis/Exc) |
//===========================================================================

Return( FWMVCMenu("AFIN032") )

/*
===============================================================================================================================
Programa----------: ModelDef
Autor-------------: Igor Melgaço
Data da Criacao---: 08/06/2021
Descrição---------: Rotina de definição do Modelo de Dados do MVC
Parametros--------: 
Retorno-----------: _oModel - Objeto do modelo de dados do MVC 
===============================================================================================================================
*/ 
Static Function ModelDef()
Local _oStruZ30 := FWFormStruct(1,"Z30")
Local _oModel
Local _bPosValidacao := {||U_AFIN032V()}

_oModel := MPFormModel():New('AFIN032M' ,  /*bPreValidacao*/ , _bPosValidacao , /*bCommit*/ , /*bCancel*/)

_oModel:AddFields('Z30CAB', /*cOwner*/ ,_oStruZ30,/*bPreValidacao*/ , /*_bPosValidacao*/ , /*bCarga*/)
_oModel:SetPrimaryKey( {'Z30_FILIAL' } )
_oModel:SetDescription("Parâmetros de Integração Paytrack")

Return _oModel

/*
===============================================================================================================================
Programa----------: ViewDef
Autor-------------: Igor Melgaço
Data da Criacao---: 08/06/2021
Descrição---------: Rotina de definição da View do MVC
Parametros--------: 
Retorno-----------: _oView - Objeto de exibição do MVC  
===============================================================================================================================
*/ 
Static Function ViewDef()
Local _oStruZ30 := FWFormStruct(2,"Z30")
Local _oModel := FWLoadModel("AFIN032")
Local _oView := Nil

_oView := FWFormView():New()
_oView:SetModel(_oModel)

_oView:AddField("VIEW_Z30",_oStruZ30,"Z30CAB"   ,,)
//Setando o dimensionamento de tamanho
_oView:CreateHorizontalBox('CABEC',100)


//Amarrando a view com as box
_oView:SetOwnerView('VIEW_Z30','CABEC')

//Tratativa padrão para fechar a tela
_oView:SetCloseOnOk({||.T.})

Return _oView

/*
===============================================================================================================================
Programa----------: AFIN032V
Autor-------------: Igor Melgaço
Data da Criacao---: 08/06/2021
Descrição---------: Rotina de Validação
Parametros--------: 
Retorno-----------: _lReturn
===============================================================================================================================
*/ 
User Function AFIN032V()
Local _lReturn      := .T.
Local _aOrd         := SaveOrd({"Z21"})
Local _oModel       := FwModelActivete()
Local _cFilial      := xFilial("Z30")
Local _nOperation   := _oModel:GetOperation() 
Local _lValida      := .F.

If _nOperation == MODEL_OPERATION_INSERT 
    _lValida      := .T.
ElseIf _nOperation == MODEL_OPERATION_UPDATE
    If _cFilial <> Z30->Z30_FILIAL
        _lValida      := .T.
    EndIf
EndIf

If _lValida
    Z30->(DBSetOrder(1))
    If Z30->( DBSeek(_cFilial) )
        _lReturn := .F.
        U_ITMsg("Os Parâmetros para esta filial já foram cadastrados. ",;
              "Atenção",;
              "Clique em alterar ou acesse outra filial para inserção dos parâmetros.  ",3 , , , .T.)
                                           
    EndIf
EndIf

RestOrd(_aOrd)

Return _lReturn
