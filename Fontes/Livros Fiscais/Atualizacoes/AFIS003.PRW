/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |03/04/2019| Chamado 28346. Revisão de fontes.
===============================================================================================================================
*/

#Include "rwmake.ch"
#Include "FWMVCDef.Ch"

/*
===============================================================================================================================
Programa----------: AFIS003
Autor-------------: Lucas Crevilari
Data da Criacao---: 31/07/2014
Descrição---------: Rotina para realizar as operacoes de inclusao, alteracao e exclusao dos dados de Tipo de Operacao (TES)
Parametros--------:
Retorno-----------:
===============================================================================================================================
*/
User Function AFIS003()

Local oBrowse := Nil

//===========================================================================
//| Configuração da Classe do Browse                                        |
//===========================================================================
oBrowse := FWMBrowse():New()

//===========================================================================
//| Definição do Alias a ser utilizado                                      |
//===========================================================================
oBrowse:SetAlias( "ZB4" )

//===========================================================================
//| Descrição da Janela                                                     |
//===========================================================================
oBrowse:SetDescription( "Tipo Operacao" )

//===========================================================================
//| Desabilita a exibição de detalhes - Selecao dos campos ativos na        |
//| exibicao do browse  													|
//===========================================================================
//oBrowse:DisableDetails()
oBrowse:SetOnlyFields( {'ZB4_COD','ZB4_DESCRI'} )

//===========================================================================
//| Ativa a Classe do Browse                                                |
//===========================================================================
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

//FWMVCMenu - Gera o menu padrão para o Modelo Informado (Inc/Alt/Vis/Exc)
Return( FWMVCMenu("AFIS003") )

/*
===============================================================================================================================
Programa----------: ModelDef
Autor-------------: Lucas Crevilari
Data da Criacao---: 31/07/2014
Descrição---------: Rotina de definição do Modelo de Dados do MVC
Parametros--------: Nenhum
Retorno-----------: oModel - Objeto do modelo de dados do MVC
===============================================================================================================================
*/
Static Function ModelDef()

//Inicializa a estrutura do modelo de dados
Local oStruZB4 	:= FWFormStruct( 1 , "ZB4" )
Local oModel	:= Nil

//Inicializa e configura o modelo de dados
oModel := MPFormModel():New( "AFIS003M" ,  /*bPreValidacao*/ , /*bPosValidacao*/ , /*bCommit*/ , /*bCancel*/ )

//Define a descrição do modelo de dados
oModel:SetDescription( "Tp Operacao" )

//Define a estrutura de dados do modelo
oModel:AddFields( "ZB4MASTER", /*cOwner*/ , oStruZB4 , /*bPreValidacao*/ , /*bPosValidacao*/ , /*bCarga*/ )

//Titulo da estrutura de dados
oModel:GetModel( "ZB4MASTER" ):SetDescription( "Tp Operacao" )

//Define validação inical do modelo
oModel:SetVldActivate( { |oModel| AFIS003VLD( oModel ) } )

Return( oModel )

/*
===============================================================================================================================
Programa----------: ViewDef
Autor-------------: Lucas Crevilari
Data da Criacao---: 31/07/2014
Descrição---------: Rotina de definição da View do MVC
Parametros--------: Nenhum
Retorno-----------: oView - Objeto de exibição do MVC
===============================================================================================================================
*/
Static Function ViewDef()

// Carrega o modelo de dados
Local oModel   	:= FWLoadModel( "AFIS003" )

// Define a estrutura de dados para a View
Local oStruZB4 	:= FWFormStruct( 2 , "ZB4" )
Local oView		:= Nil

// Inicializa o Objeto da View
oView := FWFormView():New()

// Define o modelo que será utilizado
oView:SetModel( oModel )

//Define o modelo de dados da View
oView:AddField( "VIEW_ZB4" , oStruZB4 , "ZB4MASTER" )

Return(oView)

/*
===============================================================================================================================
Programa----------: AFIS003VLD
Autor-------------: Lucas Crevilari
Data da Criacao---: 01/08/2014
Descrição---------: Verifica se o Tp de Operacao a excluir já está vinculado a alguma TES Inteligente.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AFIS003VLD( oModel )

Local _lRet		:= .T.
Local _nOper	:= oModel:GetOperation()
Local _cAlias	:= GetNextAlias()

If _nOper == 5 .And. !Empty( ZB4->ZB4_COD )

	BeginSql alias _cAlias
		SELECT COUNT(1) QTD
		FROM %Table:ZZP%
		WHERE D_E_L_E_T_ = ' '
		AND ZZP_FILIAL = %xFilial:ZZP%
		AND ZZP_TIPO = %exp:ZB4->ZB4_COD%
	EndSql

	If (_cAlias)->QTD > 0
		Help(NIL, NIL, "AFIS00301", NIL, "Não é possível realizar exclusao de Tipo de Operacao que esteja em uso no cadastro de TES Inteligente.",;
			 1, 0, NIL, NIL, NIL, NIL, NIL, {"Favor excluir a amarração no cadastro de TES que está vinculado a este Tipo de Operação."})
		_lRet := .F.
	EndIf
	(_cAlias)->(DBCloseArea())
EndIf

Return( _lRet )
