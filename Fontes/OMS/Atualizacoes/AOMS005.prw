/*
===============================================================================================================================
                                    ATUALIZACOES SOFRIDAS DESDE A CONSTRUÇAO INICIAL
===============================================================================================================================
       Autor      |    Data    |                                             Motivo                                           |
------------------:------------:----------------------------------------------------------------------------------------------:
===============================================================================================================================
*/

//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================


#Include "TOTVS.ch"
#Include "FwMVCDef.ch"
#Include "RWMAKE.CH"
#Include "TopConn.ch"
#Include "FWMBROWSE.CH"

/*
===============================================================================================================================
Programa--------: AOMS005
Autor-----------: Josué Danich Prestes
Data da Criacao-: 06/05/2016
===============================================================================================================================
Descrição-------: Cadastro de tipo de ocorrências de frete - Chamado 15345
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function AOMS005()

Local _aArea   := FWGetArea()
Local _oBrowse
     
    //Instânciando FWMBrowse - Somente com dicionário de dados
    _oBrowse := FWMBrowse():New()
     
    //Setando a tabela de cadastro de Autor/Interprete
    _oBrowse:SetAlias("ZFC")
 
    //Setando a descrição da rotina
    _oBrowse:SetDescription("Cadastro de tipos de ocorrência de frete")
        
    //Ativa a Browse
    _oBrowse:Activate()
     
    FWRestArea(_aArea)
    
Return

/*
===============================================================================================================================
Programa--------: AOMS005 - MenuDef
Autor-----------: Josué Danich Prestes
Data da Criacao-: 06/05/2016
===============================================================================================================================
Descrição-------: MenuDef do MVC
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: _aRot
===============================================================================================================================
*/

Static Function MenuDef()
 
Private _aRot := {}
     
//Adicionando opções
ADD OPTION _aRot TITLE 'Visualizar' ACTION 'VIEWDEF.AOMS005' 	OPERATION MODEL_OPERATION_VIEW   ACCESS 0 //OPERATION 1
ADD OPTION _aRot TITLE 'Incluir'    ACTION 'VIEWDEF.AOMS005' 	OPERATION MODEL_OPERATION_INSERT ACCESS 0 //OPERATION 3
ADD OPTION _aRot TITLE 'Alterar'    ACTION 'VIEWDEF.AOMS005' 	OPERATION MODEL_OPERATION_UPDATE ACCESS 0 //OPERATION 4
ADD OPTION _aRot TITLE 'Excluir'    ACTION 'VIEWDEF.AOMS005' 	OPERATION MODEL_OPERATION_DELETE ACCESS 0 //OPERATION 5
 
Return _aRot

/*
===============================================================================================================================
Programa--------: AOMS005 - ModelDef 
Autor-----------: Josué Danich Prestes
Data da Criacao-: 06/05/2016
===============================================================================================================================
Descrição-------: ModelDef  do MVC
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: _oModel
===============================================================================================================================
*/ 
 
Static Function ModelDef()

//Criação do objeto do modelo de dados
Local _oModel := Nil
     
//Criação da estrutura de dados utilizada na interface
Local _oStZFC := FWFormStruct(1, "ZFC")
     
//Instanciando o modelo, não é recomendado colocar nome da User Function (por causa do u_), respeitando 10 caracteres
_oModel := MPFormModel():New("AOMS005M",/*bPre*/, {|| U_ITLOGACS(),.T. }/*bPos*/,/*bCommit*/,/*bCancel*/) 
     
//Atribuindo formulários para o modelo
_oModel:AddFields("FORMZFC",/*cOwner*/,_oStZFC)
     
//Setando a chave primária da rotina
_oModel:SetPrimaryKey({'ZFC_FILIAL','ZFC_CODIGO'})
     
//Adicionando descrição ao modelo
_oModel:SetDescription("Cadastro de Tipos de Ocorrências de Frete")
     
//Setando a descrição do formulário
_oModel:GetModel("FORMZFC"):SetDescription("Cadastro de Tipos de Ocorrências de Frete")

Return _oModel


/*
===============================================================================================================================
Programa--------: AOMS005 - ViewDef 
Autor-----------: Josué Danich Prestes
Data da Criacao-: 06/05/2016
===============================================================================================================================
Descrição-------: ViewDef  do MVC
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: _oView
===============================================================================================================================
*/
Static Function ViewDef()
 
//Criação do objeto do modelo de dados da Interface do Cadastro de Autor/Interprete
Local _oModel := FWLoadModel("AOMS005")
     
//Criação da estrutura de dados utilizada na interface do cadastro de Autor
Local _oStZFC := FWFormStruct(2, "ZFC")  //pode se usar um terceiro parâmetro para filtrar os campos exibidos { |cCampo| cCampo $ 'ZFC_NOME|ZFC_DTAFAL|'}
     
//Criando _oView como nulo
Local _oView := Nil
 
//Criando a view que será o retorno da função e setando o modelo da rotina
_oView := FWFormView():New()
_oView:SetModel(_oModel)
     
//Atribuindo formulários para interface
_oView:AddField("VIEW_ZFC", _oStZFC, "FORMZFC")
     
//Criando um container com nome tela com 100%
_oView:CreateHorizontalBox("TELA",100)
     
//Colocando título do formulário
_oView:EnableTitleView('VIEW_ZFC', 'Dados do Grupo de Produtos' )  
     
//Força o fechamento da janela na confirmação
_oView:SetCloseOnOk({||.T.})
     
//O formulário da interface será colocado dentro do container
_oView:SetOwnerView("VIEW_ZFC","TELA")

Return _oView

/*
===============================================================================================================================
Programa--------: AOMS005I
Autor-----------: Josué Danich Prestes
Data da Criacao-: 06/05/2016
===============================================================================================================================
Descrição-------: Retorna próximo código da ZFD
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: _ccod - próximo código de tipo de ocorrência
===============================================================================================================================
*/  
 
User Function AOMS005I()

Local _ccod := "000001"
Local _cQuery := ""

_cQuery += " SELECT MAX(ZFC_CODIGO) MAXIMO FROM " + Retsqlname("ZFC") 
_cQuery += " WHERE D_E_L_E_T_ = ' ' AND ZFC_FILIAL = '" + xFilial("ZFC") + "'"

TCQUERY _cQuery New Alias "ZFCT"
DBSelectArea("ZFCT")

If  !(ZFCT->( Eof() )) 

 _ccod := StrZero((Val(ZFCT->MAXIMO)+1),6)
	
EndIf

ZFCT->( DBCloseArea() )


Return _ccod


