/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
 Alexandre V. |01/10/2015| Chamado 12110. Ajuste na validação do acesso dos usuários para tratar corretamente o retorno da 
              |          | função e exibir corretamente as mensagens de ajuda.
Lucas Borges  |12/06/2019| Chamado 28346. Revisão de fontes
===============================================================================================================================
*/

#Include	"Protheus.Ch"
#Include	"FWMVCDef.Ch"

/*
===============================================================================================================================
Programa--------: AGLT017
Autor-----------: Alexandre Villar
Data da Criacao-: 19/02/2014
Descrição-------: Cadastro das menagens a serem impressas no fechamento do leite de terceiros - Chamado 11332
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function AGLT017()

Local _oBrowse := Nil

_oBrowse := FWMBrowse():New()
_oBrowse:SetAlias( "ZLZ" )
_oBrowse:SetDescription( "Cadastro das Mensagens do Fechamento do Leite de Terceiros" )
_oBrowse:Activate()

Return

/*
===============================================================================================================================
Programa--------: MenuDef
Autor-----------: Alexandre Villar
Data da Criacao-: 19/02/2014
Descrição-------: Definição das opções de menu da rotina
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function MenuDef()
Return( FWMVCMenu("AGLT017") )

/*
===============================================================================================================================
Programa--------: ModelDef
Autor-----------: Alexandre Villar
Data da Criacao-: 19/02/2014
Descrição-------: Definição da configuração do modelo de dados da rotina
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ModelDef()

Local _oStrZLZ	:= FWFormStruct( 1 , "ZLZ" )
Local _oModel	:= Nil

_oModel := MPFormModel():New( "AGLT017M" )

_oModel:SetDescription( "Modelo de Dados Cadastro de Mensagens do Fechamento do Leite de Terceiros" )
_oModel:AddFields( "ZLZMASTER" ,, _oStrZLZ )
_oModel:SetPrimaryKey( { "ZLZ_FILIAL" , "ZLZ_CODMSG" } )

Return( _oModel )

/*
===============================================================================================================================
Programa--------: ViewDef
Autor-----------: Alexandre Villar
Data da Criacao-: 19/02/2014
Descrição-------: Definição das opções da View para construção das telas da rotina
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ViewDef()

Local _oModel  	:= FWLoadModel( "AGLT017" )
Local _oStrZLZ	:= FWFormStruct( 2 , "ZLZ" )
Local _oView	:= Nil

_oView := FWFormView():New()

_oView:SetModel( _oModel )

_oStrZLZ:AddGroup( 'GRUPO01' , 'Configuração do Período'									, '' , 2 )
_oStrZLZ:AddGroup( 'GRUPO02' , 'Mensagens ao Produtor no Fechamento do Leite de Terceiros'	, '' , 2 )

_oStrZLZ:SetProperty( 'ZLZ_CODMIX'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO01' )
_oStrZLZ:SetProperty( 'ZLZ_MSG'		, MVC_VIEW_GROUP_NUMBER , 'GRUPO02' )

_oView:AddField( "VIEW_ZLZ" , _oStrZLZ , "ZLZMASTER" )

Return( _oView )
