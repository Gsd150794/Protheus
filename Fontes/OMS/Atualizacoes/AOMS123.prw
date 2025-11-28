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
Descrição---------: Cadastro de Mesoregião. Chamado: 36780
===============================================================================================================================
Parametros--------: 
===============================================================================================================================
Retorno-----------:  
===============================================================================================================================
*/ 
User Function AOMS123()
Local _oBrowse := Nil

_oBrowse := FWMBrowse():New()
_oBrowse:SetAlias("Z21")
_oBrowse:SetMenuDef( 'AOMS123' )
_oBrowse:SetDescription("Cadastro de Mesoregião")
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

Return( FWMVCMenu("AOMS123") )

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
Local _oStruZ21 := FWFormStruct(1,"Z21")
Local _oModel
Local _bPosValidacao := {||U_AOMS123V()}

_aGatAux := FwStruTrigger( 'Z21_EST', 'Z21_REGIAO', 'U_AOMS123E(M->Z21_EST)', .F. )
_oStruZ21:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_oModel := MPFormModel():New('AOMS123M' ,  /*bPreValidacao*/ , _bPosValidacao , /*bCommit*/ , /*bCancel*/)
_oModel:AddFields('Z21MASTER', /*cOwner*/ , _oStruZ21 , /*bPreValidacao*/ , /*_bPosValidacao*/ , /*bCarga*/)
_oModel:SetDescription("Modelo de Dados Mesoregião")
_oModel:GetModel('Z21MASTER'):SetDescription("Dados Mesoregião")
_oModel:SetPrimaryKey( {'Z21_FILIAL','Z21_COD' } )

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
Local _oStruZ21 := FWFormStruct(2,"Z21")
Local _oModel := FWLoadModel("AOMS123")
Local _oView := Nil

_oView := FWFormView():New()
_oView:SetModel(_oModel)
_oView:AddField("VIEW_Z21", _oStruZ21 , "Z21MASTER")

_oView:CreateHorizontalBox("TELA",100)
_oView:SetOwnerView("VIEW_Z21","TELA")

Return _oView

/*
===============================================================================================================================
Programa----------: AOMS123V
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
User Function AOMS123V()
Local _lReturn      := .T.
Local _aOrd         := SaveOrd({"Z21"})
Local _oModel       := FwModelActivete()
Local _oModelMaster := _oModel:GetModel("Z21MASTER")
Local _cCod         := _oModelMaster:GetValue('Z21_COD' ) 
Local _nOperation   := _oModel:GetOperation() 
Local _lValida      := .F.

If _nOperation == MODEL_OPERATION_INSERT 
    _lValida      := .T.
ElseIf _nOperation == MODEL_OPERATION_UPDATE
    If _cCod <> Z21->Z21_COD
        _lValida      := .T.
    EndIf
EndIf

If _lValida
    Z21->(DBSetOrder(1))
    If Z21->( DBSeek(xFilial("Z21")+_cCod) )
        _lReturn := .F.
        U_ITMsg("Código da Mesoregião informado já consta no cadastro. ",;
              "Atenção",;
              "Modifique o código digitado.  ",3 , , , .T.)

        _lRet := .F.
                                           
    EndIf
EndIf

RestOrd(_aOrd)

Return _lReturn

/*
===============================================================================================================================
Programa----------: AOMS123E
Autor-------------: Igor Melgaço
Data da Criacao---: 08/06/2021
===============================================================================================================================
Descrição---------: Gatilho do campo Estado
===============================================================================================================================
Parametros--------: _cEst = Estado
===============================================================================================================================
Retorno-----------: _cRegiao = Região referente ao Estado  
===============================================================================================================================
*/ 
User Function AOMS123E(_cEst)
Local _cRegiao := ""

Do Case
    Case AllTrim(_cEst) $ "SP/RJ/MG/ES"
       _cRegiao := "3"
    Case AllTrim(_cEst) $ "SC/PR/RS"
       _cRegiao := "4"
    Case AllTrim(_cEst) $ "MT/MS/GO/DF"
       _cRegiao := "5"
    Case AllTrim(_cEst) $ "AC/RO/AM/RR/PA/AP/TO"
       _cRegiao := "1"
    Case AllTrim(_cEst) $ "BA/SE/AL/PE/PB/CE/RN/PI/MA"
       _cRegiao := "2"
EndCase

Return _cRegiao
