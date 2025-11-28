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
Programa----------: AOMS156
Autor-------------: Igor Melgaço
Data da Criacao---: 04/06/2025
===============================================================================================================================
Descrição---------: Cadastro de Subtipo de Contrato. Chamado: 50805 
===============================================================================================================================
Parametros--------: 
===============================================================================================================================
Retorno-----------:  
===============================================================================================================================
*/ 
User Function AOMS156()
Local _oBrowse := Nil
Private __cCod := "" As Character
Private __cPeriod := "" As Character

_oBrowse := FWMBrowse():New()
_oBrowse:SetAlias("SX5")
_oBrowse:SetMenuDef( 'AOMS156' )
_oBrowse:SetDescription("Subtipos de Contrato")
_oBrowse:SetFilterDefault(' SX5->X5_TABELA = "ZL" ')
_oBrowse:SetOnlyFields({"X5_CHAVE","X5_DESCRI"})
_oBrowse:Activate()

Return

/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Igor Melgaço
Data da Criacao---: 04/06/2025
===============================================================================================================================
Descrição---------: Rotina de definição automática do menu via MVC
===============================================================================================================================
Parametros--------: 
===============================================================================================================================
Retorno-----------: aRotina - Definições do menu principal da Rotina.
===============================================================================================================================
*/
Static Function MenuDef() As Array
Local _aRotina	:= {} As Array

ADD OPTION _aRotina Title 'Visualizar'	Action 'VIEWDEF.AOMS156'	OPERATION 2 ACCESS 0
ADD OPTION _aRotina Title 'Incluir'   	Action 'VIEWDEF.AOMS156'	OPERATION 3 ACCESS 0
ADD OPTION _aRotina Title 'Alterar'   	Action 'VIEWDEF.AOMS156'	OPERATION 4 ACCESS 0
ADD OPTION _aRotina Title 'Excluir'		Action 'VIEWDEF.AOMS156'	OPERATION 5 ACCESS 0
ADD OPTION _aRotina Title 'Copiar'     Action 'VIEWDEF.AOMS156'   OPERATION 9 ACCESS 0

Return( _aRotina )

/*
===============================================================================================================================
Programa----------: ModelDef
Autor-------------: Igor Melgaço
Data da Criacao---: 04/06/2025
===============================================================================================================================
Descrição---------: Rotina de definição do Modelo de Dados do MVC
===============================================================================================================================
Parametros--------: 
===============================================================================================================================
Retorno-----------: _oModel - Objeto do modelo de dados do MVC 
===============================================================================================================================
*/ 
Static Function ModelDef() As Object
Local _oStruSX5 := FWFormStruct(1,"SX5") As Object
Local _oModel As Object
Local _bPosValidacao := {|| U_AOMS156H(_oModel) } As Block
Local _bCommit := {|| U_AOMS156K(_oModel) } As Block

_oStruSX5:SetProperty( "X5_CHAVE"  	, MODEL_FIELD_INIT, {|_oModel| U_AOMS156J(_oModel) }  )
_oStruSX5:SetProperty( "X5_CHAVE"   , MODEL_FIELD_WHEN , {|| .F. } )

// MPFORMMODEL():AddFields(< cId >, < cOwner >, < oModelStruct >, < bPre >, < bPost >, < bLoad >)-
_oModel := MPFormModel():New('AOMS156M' , /*bPreValidacao*/ ,  _bPosValidacao/*_bPosValidacao*/ ,  _bCommit/*bCommit*/ , /*bCancel*/)

_oModel:AddFields("SX5MASTER",/*cOwner*/,_oStruSX5)

_oModel:SetPrimaryKey( {'X5_FILIAL','X5_TABELA','X5_CHAVE' } )
_oModel:SetDescription("Subtipos de Contrato")

_oModel:SetVldActivate( { |_oModel| .T. } )

Return _oModel

/*
===============================================================================================================================
Programa----------: ViewDef
Autor-------------: Igor Melgaço
Data da Criacao---: 04/06/2025
===============================================================================================================================
Descrição---------: Rotina de definição da View do MVC
===============================================================================================================================
Parametros--------: 
===============================================================================================================================
Retorno-----------: _oView - Objeto de exibição do MVC  
===============================================================================================================================
*/ 
Static Function ViewDef() As Object
Local _oStruSX5 := FWFormStruct(2,"SX5") As Object
Local _oModel := FWLoadModel("AOMS156") As Object
Local _oView := Nil As Object

_oStruSX5:RemoveField('X5_TABELA')
_oStruSX5:RemoveField('X5_DESCSPA')
_oStruSX5:RemoveField('X5_DESCENG')

_oView := FWFormView():New()
_oView:SetModel(_oModel)

_oView:AddField( "VIEW_MASTER", _oStruSX5	, "SX5MASTER" )

_oView:CreateHorizontalBox( 'BOX0101' , 100 )

     
//Força o fechamento da janela na confirmação
_oView:SetCloseOnOk({||.T.})

//_oView:SetOwnerView("VIEW_Z39","TELA")

Return _oView


/*
===============================================================================================================================
Programa----------: AOMS156H
Autor-------------: Igor Melgaço
Data da Criacao---: 04/06/2025
===============================================================================================================================
Descrição---------: Pos Validação
===============================================================================================================================
Parametros--------: _oModel
===============================================================================================================================
Retorno-----------: lRet
===============================================================================================================================
*/ 
User Function AOMS156H(_oModel As Object) As Logical
Local _lRet := .T. As Logical
Local _nOper := _oModel:GetOperation() As Numeric
Local _cDesc := _oModel:GetValue("SX5MASTER","X5_DESCRI") As Character
Local _cChave := _oModel:GetValue("SX5MASTER","X5_CHAVE") As Character
Local _cQry := "" As Character
Local _cAliasQry := "" As Character
Local _cMenPro:= "" As Character
Local _cMenRes:= "" As Character

If _nOper == MODEL_OPERATION_INSERT .Or. _nOper == MODEL_OPERATION_UPDATE

   _cAliasQry := GetNextAlias()

   _cQry := " SELECT X5_CHAVE "
   _cQry += " FROM " + RetSqlName("SX5") + " SX5 " 
   _cQry += " WHERE X5_FILIAL = '"+xFilial("SX5")+"' "
   _cQry += " AND X5_TABELA = 'ZL' "
   _cQry += " AND X5_DESCRI = '"+_cDesc+"' "
   If _nOper == MODEL_OPERATION_UPDATE
      _cQry += " AND SX5.R_E_C_N_O_ <> '"+AllTrim(Str(SX5->(Recno())))+"' "
   EndIf
   _cQry += " AND SX5.D_E_L_E_T_ = ' ' "

   _cQry := ChangeQuery( _cQry )

   MPSysOpenQuery( _cQry , _cAliasQry)

   If (_cAliasQry)->(!Eof())
      _lRet := .F.
      _cMenPro:= "Já existe um Subtipo de Contrato com a mesma descrição."
      _cMenRes:= "Prencha o campo com uma descrição diferente."
      Help(NIL, NIL, "AOMS156DES", NIL, _cMenPro,1, 0, NIL, NIL, NIL, NIL, NIL, {_cMenRes})
   EndIf

ElseIf _nOper == MODEL_OPERATION_DELETE 

   _cAliasQry := GetNextAlias()

   _cQry := " SELECT ZK1_SUBITE "
   _cQry += " FROM " + RetSqlName("ZK1") + " ZK1 " 
   _cQry += " WHERE ZK1_SUBITE = '"+_cChave+"' "
   _cQry += " AND ZK1.D_E_L_E_T_ = ' ' "

   _cQry := ChangeQuery( _cQry )

   MPSysOpenQuery( _cQry , _cAliasQry)

   If (_cAliasQry)->(!Eof())
      _lRet := .F.
      _cMenPro:= "Não é possivel excluir esse registro pois existem registros relacionados a esse Subtipo no cadastro de Contratos/Acordo Comercial."
      _cMenRes:= "Exclua os registros de contratos ou altere esses registros para outro subtipo. Caso isso nâo seja possivel a Exclusão desse subtipo não poderá ser efetuada."
      Help(NIL, NIL, "AOMS156EXC", NIL, _cMenPro,1, 0, NIL, NIL, NIL, NIL, NIL, {_cMenRes})
   EndIf

EndIf

Return _lRet

/*
===============================================================================================================================
Programa----------: AOMS156G
Autor-------------: Igor Melgaço
Data da Criacao---: 04/06/2025
===============================================================================================================================
Descrição---------: Pos Validação
===============================================================================================================================
Parametros--------: _cFilial,_cCod
===============================================================================================================================
Retorno-----------: _cRetorno
===============================================================================================================================
*/ 
User Function AOMS156G(_cFilial As Character,_cCod As Character) As Character
   Local _cRetorno := "" As Character
   Local _aAreaSX5 := {} As Array

   _aAreaSX5 := GetArea("SX5")

   DBSelectArea("SX5")
   DBSetOrder(1)
   DBSeek(_cFilial+_cCod)
   _cRetorno := SX5->SX5_DESC
   
   FWRestArea(_aAreaSX5)

Return _cRetorno



/*
===============================================================================================================================
Programa----------: AOMS156J
Autor-------------: Igor Melgaço
Data da Criacao---: 04/06/2025
===============================================================================================================================
Descrição---------: Inicializa o campo SX5_COD
===============================================================================================================================
Parametros--------: 
===============================================================================================================================
Retorno-----------: _cCod
===============================================================================================================================
*/ 
User Function AOMS156J(_oModel As Object) As Character
Local _nOperation := _oModel:GetOperation() As Numeric
Local cRetorno := "" As Character

   If _nOperation == 3 //Inclusão
      cRetorno := AOMS156X()
   Else
      cRetorno := SX5->X5_CHAVE
   EndIf
   _oModel:SetValue("X5_TABELA","ZL")  
Return cRetorno

/*
===============================================================================================================================
Programa----------: AOMS156X
Autor-------------: Igor Melgaço
Data da Criacao---: 03/06/2025
===============================================================================================================================
Descrição---------: Retorno o proximo X5_CHAVE da Tabela ZL
===============================================================================================================================
Parametros--------: 
===============================================================================================================================
Retorno-----------: _cRet
===============================================================================================================================
*/ 
Static Function AOMS156X() As Character
Local _cRet := "" As Character
Local _cQry := "" As Character
Local _cAliasQry := "" As Character

_cAliasQry := GetNextAlias()

_cQry := " SELECT MAX(X5_CHAVE) X5_CHAVE "
_cQry += " FROM " + RetSqlName("SX5") + " SX5 " 
_cQry += " WHERE SX5.D_E_L_E_T_ = ' ' "
_cQry += " AND X5_TABELA = 'ZL' "

_cQry := ChangeQuery( _cQry )

MPSysOpenQuery( _cQry , _cAliasQry)

_cRet := StrZero(Val((_cAliasQry)->X5_CHAVE)+1,2)

While !MayIUseCode( "SX5"+xFilial("SX5")+"ZL"+_cRet)  //verifica se esta na memoria, sendo usado
	_cRet := StrZero(Val(_cRet)+1,2)					 // busca o proximo numero disponivel
EndDo

Return _cRet

/*
===============================================================================================================================
Programa----------: AOMS156K
Autor-------------: Igor Melgaço
Data da Criacao---: 03/06/2025
===============================================================================================================================
Descrição---------: Commit
===============================================================================================================================
Parametros--------: 
===============================================================================================================================
Retorno-----------: .T.
===============================================================================================================================
*/
User Function AOMS156K(_oModel As Object) As Logical
Local _cDesc := _oModel:GetValue("SX5MASTER","X5_DESCRI") 
Local _nOper := _oModel:GetOperation() As Numeric

Begin Transaction

   If _nOper == MODEL_OPERATION_INSERT .Or. _nOper == MODEL_OPERATION_UPDATE
      _oModel:SetValue("SX5MASTER","X5_DESCSPA",_cDesc) 
      _oModel:SetValue("SX5MASTER","X5_DESCENG",_cDesc)  
   EndIf
   FWFormCommit( _oModel )

End Transaction

Return .T.

