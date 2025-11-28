/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include 'FWMVCDEF.CH'

/*
===============================================================================================================================
Programa--------: AGLT059
Autor-----------: Lucas Borges Ferreira
Data da Criacao-: 24/03/2025
Descrição-------: Manutenção Integração API Qualidade Tetra Pak. Chamado 48203
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function AGLT059

Local oBrowse as Object

oBrowse := FWMBrowse():New()
oBrowse:SetAlias('ZBQ')
oBrowse:SetDescription('Manutenção Integração API Qualidade Tetra Pak')
oBrowse:Activate()

Return

//-------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} MenuDef

Definição de Menu - MVC

@author  Lucas Borges Ferreira
@since  24/03/2025
@Return array, opções do menu
/*/
//-------------------------------------------------------------------------------------------------------------
Static Function MenuDef() As Array

Local aRotina := {}

ADD OPTION aRotina Title 'Visualizar'	Action 'VIEWDEF.AGLT059' OPERATION 2 ACCESS 0
ADD OPTION aRotina Title 'Excluir'     Action 'VIEWDEF.AGLT059' OPERATION 5 ACCESS 0
ADD OPTION aRotina Title 'Sincronizar' Action 'U_MGLT031'       OPERATION 3 ACCESS 0

Return aRotina

//-------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} ModelDef

Define o model padrão para o cadastro

@author  Lucas Borges Ferreira
@since  24/03/2025
@Return object, objeto do modelo de dados
/*/
//-------------------------------------------------------------------------------------------------------------
Static Function ModelDef() as Object
// Cria a estrutura a ser usada no Modelo de Dados
Local oStrCAB	:= FWFormStruct(1,'ZBQ',{|cCampo|AGLT059CPO(cCampo,1)}/*bAvalCampo*/,/*lViewUsado*/) as Object
Local oStrITN	:= FWFormStruct(1,'ZBQ',{|cCampo|AGLT059CPO(cCampo,2)}/*bAvalCampo*/,/*lViewUsado*/) as Object
Local oModel	:= Nil as Object

// Cria o objeto do Modelo de Dados
oModel :=MPFormModel():New('AGLT059M',/*bPreValidacao*/,{|oModel|AGLT59POS(oModel)}/*bPosValidacao*/,{|oModel|AGLT59COM(oModel)}/*FbCommit*/,/*bCancel*/)

// Adiciona ao modelo uma estrutura de formulário de edição por campo
oModel:AddFields('ZBQMASTER',/*cOwner*/,oStrCAB,/*bPreValidacao*/,/*bPosValidacao*/,/*bCarga*/)
// Adiciona ao modelo uma estrutura de formulário de edição por grid
oModel:AddGrid('ZBQDETAIL','ZBQMASTER'/*cOwner*/,oStrITN,/*bLinePre*/, /*bLinePost*/, /*bPreVal*/, /*bPosVal*/, /*BLoad*/ )

// Faz relaciomaneto entre os compomentes do model
oModel:SetRelation('ZBQDETAIL',{{'ZBQ_FILIAL','xFilial("ZBQ")'},{'ZBQ_FLOGID','ZBQ_FLOGID'}},ZBQ->(IndexKey(1)))
// Liga o controle de nao repeticao de linha
oModel:GetModel('ZBQDETAIL'):SetUniqueLine({'ZBQ_GRUPO'})

oModel:SetPrimaryKey({'ZBQ_FILIAL','ZBQ_FLOGID','ZBQ_GRUPO'})

// Adiciona a descricao do Modelo de Dados
oModel:SetDescription('Manutenção Integração API Qualidade Tetra Pak')
// Adiciona a descricao do Componente do Modelo de Dados
oModel:GetModel('ZBQMASTER'):SetDescription('Cabeçalho da viagem')
oModel:GetModel('ZBQDETAIL'):SetDescription('Itens da viagem')

Return( oModel )

//-------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} ViewDef

Definição de View para o cadastro

@author  Lucas Borges Ferreira
@since  24/03/2025
@Return object, objeto da view
/*/
//-------------------------------------------------------------------------------------------------------------
Static Function ViewDef()
// Cria um objeto de Modelo de Dados baseado no ModelDef do fonte informado
Local oStrCAB	:= FWFormStruct(2,'ZBQ',{|cCampo|AGLT059CPO(cCampo,1)}/*bAvalCampo*/,/*lViewUsado*/) as Object
Local oStrITN	:= FWFormStruct(2,'ZBQ',{|cCampo|AGLT059CPO(cCampo,2)}/*bAvalCampo*/,/*lViewUsado*/) as Object
// Cria a estrutura a ser usada na View
Local oModel	:= FWLoadModel( "AGLT059" ) as Object
Local oView	   := Nil as Object

// Cria o objeto de View
oView := FWFormView():New()

// Define qual o Modelo de dados será utilizado
oView:SetModel(oModel)

//Adiciona no nosso View um controle do tipo FormFields(antiga enchoice)
oView:AddField('VIEW_CAB',oStrCAB,'ZBQMASTER')

//Adiciona no nosso View um controle do tipo FormGrid(antiga newgetdados)
oView:AddGrid('VIEW_ITN',oStrITN,'ZBQDETAIL')

// Criar um "box" horizontal para receber algum elemento da view
oView:CreateHorizontalBox('SUPERIOR',065)
oView:CreateHorizontalBox('INFERIOR',035)

// Relaciona o ID da View com o "box" para exibicao
oView:SetOwnerView('VIEW_CAB','SUPERIOR')
oView:SetOwnerView('VIEW_ITN','INFERIOR')

Return oView

//-------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} AGLT059CPO

Verifica se campo pode ser incluído na estrutura do Model/Grid

@author  Lucas Borges Ferreira
@since  24/03/2025
@param cCampo, cacarcter, Campo que está sendo analisado
@Return logical, indica se o campo pode ser incluído na estrutura
/*/
//-------------------------------------------------------------------------------------------------------------
Static Function AGLT059CPO(cCampo as String,nOpc as Number)

Local lRet := Upper( AllTrim(cCampo) ) $ 'ZBQ_FILIAL/ZBQ_FLOGID/ZBQ_TIPPRD/ZBQ_PRODUT/ZBQ_DTINTE/ZBQ_HRINTE/ZBQ_MAXDAT/ZBQ_CNPJTR/ZBQ_PLACA/ZBQ_CNPJOR/ZBQ_ORIGEM/ZBQ_DTENTR/ZBQ_DTCOLE/ZBQ_DTCHEG/ZBQ_DTLIBE/ZBQ_DTINIC/ZBQ_DTFIM/' as Logical

If nOpc == 2
	lRet := !lRet
EndIf

Return lRet

//-------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} AGLT59POS

Pós-Validação do Modelo

@author  Lucas Borges Ferreira
@since  24/03/2025
@param oModel, object, objeto do modelo de dados
@Return logical, indica o status das validações
/*/
//-------------------------------------------------------------------------------------------------------------
Static Function AGLT59POS(oModel as Object)

Local lRet     := .T. as Logical
Local aArea    := FWGetArea() as Array
Local _cFLogId := oModel:GetValue("ZBQMASTER",'ZBQ_FLOGID') as String
Local _cAlias  := GetNextAlias() as String

If oModel:GetOperation() == MODEL_OPERATION_DELETE
   BeginSql alias _cAlias
      SELECT COUNT(1) QTD FROM %Table:ZZX%
      WHERE D_E_L_E_T_ = ' '
      AND ZZX_FILIAL = %xFilial:ZZX%
      AND ZZX_FLOGID = %exp:_cFLogId%
      AND EXISTS (SELECT 1 FROM %Table:ZLX%
      WHERE D_E_L_E_T_ = ' '
      AND ZLX_FILIAL = ZZX_FILIAL
      AND ZLX_CODANA = ZZX_CODIGO)
   EndSql
   If (_cAlias)->QTD > 0
         lRet := .F.
      Help(,,"AGLT05901",,"Esse registro possui uma análise vinculada.",1,0,,,,,,{"Exclua a análise antes."})
   EndIf
   (_cAlias)->(DBCloseArea())
EndIf

FwRestArea(aArea)

Return lRet

//-------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} AGLT59COM

Commit do Modelo

@author  Lucas Borges Ferreira
@since  24/03/2025
@param oModel, object, objeto do modelo de dados
@Return logical, indica o status das validações
/*/
//-------------------------------------------------------------------------------------------------------------
Static Function AGLT59COM(oModel as Object)

Local oModelZZX as Object
Local lRet := .T.  as Logical

ZZX->(DBSetOrder(4))

If oModel:GetOperation() == MODEL_OPERATION_DELETE
   BEGIN TRANSACTION
   If ZZX->(DBSeek(xFilial("ZZX")+oModel:GetValue("ZBQMASTER", "ZBQ_FLOGID")))
      oModelZZX := FWLoadModel('AGLT029')
      oModelZZX:SetOperation(MODEL_OPERATION_DELETE)
      oModelZZX:Activate()
      //-- Realiza a gravação do Modelo
      lRet := FWFormCommit(oModelZZX)
      oModelZZX:Deactivate()
      oModelZZX := NIL
   EndIf
   // Se excluiu no AGLT029, então pode excluir no ZBQ
   If lRet
      //-- Realiza a gravação do Modelo
      lRet := FWFormCommit(oModel)
   Else
      DisarmTransaction()
   EndIf
   END TRANSACTION

EndIf

Return lRet
