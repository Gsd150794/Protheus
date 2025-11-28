/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alexandre V.  |21/11/2014| Chamado 8134. Atualização da rotina para a correta inicialização e gravação dos Helps das valida-
              |          | ções para que as mensagens sejam gravadas corretamente para evitar a exibição de mensagens trocadas
              |          | ao usuário durante o processamento.
Lucas Borges  |10/09/2024| Chamado 48465. Removendo warning de compilação.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: AEST032
Autor-------------: Alexandre Villar
Data da Criacao---: 19/03/2014
Descrição---------: Rotina de Cadastro de Prazos de Transferências entre Filiais
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AEST032

Local oBrowse := Nil

//===========================================================================
//Verifica situação do SX2->X2_UNICO
//===========================================================================
U_ITUNQSX2( "ZZZ" , "ZZZ_FILIAL+ZZZ_FILDE+ZZZ_FILATE" )

//===========================================================================
//Configuração da Classe do Browse
//===========================================================================
oBrowse := FWMBrowse():New()

//===========================================================================
//Definição do Alias a ser utilizado
//===========================================================================
oBrowse:SetAlias( "ZZZ" )

//===========================================================================
//Descrição da Janela
//===========================================================================
oBrowse:SetDescription( "Cadastro de Prazos de Transferências entre Filiais" )

//===========================================================================
//Desabilita a exibição de detalhes
//===========================================================================
oBrowse:DisableDetails()

//===========================================================================
//Ativa a Classe do Browse
//===========================================================================
oBrowse:Activate()

Return

/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Alexandre Villar
Data da Criacao---: 19/03/2014
Descrição---------: Rotina de definição automática do menu via MVC
Parametros--------: Nenhum
Retorno-----------: aRotina - Definições do menu principal da Rotina.
===============================================================================================================================
*/
Static Function MenuDef()

//===========================================================================
//FWMVCMenu - Gera o menu padrão para o Modelo Informado
//===========================================================================

Return( FWMVCMenu("AEST032") )

/*
===============================================================================================================================
Programa----------: ModelDef
Autor-------------: Alexandre Villar
Data da Criacao---: 19/03/2014
Descrição---------: Rotina de definição do Modelo de Dados do MVC
Parametros--------: Nenhum
Retorno-----------: oModel - Objeto do modelo de dados do MVC
===============================================================================================================================
*/
Static Function ModelDef

//===========================================================================
//Inicializa a estrutura do modelo de dados
//===========================================================================
Local oStruZZZ 	:= FWFormStruct( 1 , "ZZZ" )
Local oModel	:= Nil

//===========================================================================
//Define Gatilhos para a Estrutura de Dados
//===========================================================================
aGatAux := FwStruTrigger( 'ZZZ_FILDE' , 'ZZZ_FILDED' , 'ZZM->ZZM_DESCRI' , .T. , 'ZZM' , 1 , 'xFilial("ZZM")+M->ZZZ_FILDE' )
oStruZZZ:AddTrigger( aGatAux[01] , aGatAux[02] , aGatAux[03] , aGatAux[04] )                                          

aGatAux := FwStruTrigger( 'ZZZ_FILATE' , 'ZZZ_FILATD' , 'ZZM->ZZM_DESCRI' , .T. , 'ZZM' , 1 , 'xFilial("ZZM")+M->ZZZ_FILATE' )
oStruZZZ:AddTrigger( aGatAux[01] , aGatAux[02] , aGatAux[03] , aGatAux[04] )

//===========================================================================
//Inicializa e configura o modelo de dados
//===========================================================================
oModel := MPFormModel():New( "AEST032M" , /*bPreValidacao*/ , /*bPosValidacao*/ , /*bCommit*/ , /*bCancel*/ )

//===========================================================================
//Define a descrição do modelo de dados
//===========================================================================
oModel:SetDescription( "Prazos de Transferências entre Filiais" )

//===========================================================================
//Define a estrutura de dados do modelo
//===========================================================================
oModel:AddFields( "ZZZMASTER", /*cOwner*/ , oStruZZZ , /*bPreValidacao*/ , /*bPosValidacao*/ , /*bCarga*/ )

//===========================================================================
//Titulo da estrutura de dados
//===========================================================================
oModel:GetModel( "ZZZMASTER" ):SetDescription( "Prazos em Dias" )

//===========================================================================
//Define validação inical do modelo                                       |
//===========================================================================
oModel:SetVldActivate( { |oModel| AEST032VLD( oModel ) } )

Return( oModel )

/*
===============================================================================================================================
Programa----------: ViewDef
Autor-------------: Alexandre Villar
Data da Criacao---: 19/03/2014
Descrição---------: Rotina de definição da View do MVC
Parametros--------: Nenhum
Retorno-----------: oView - Objeto de exibição do MVC
===============================================================================================================================
*/
Static Function ViewDef()

//===========================================================================
//Carrega o modelo de dados
//===========================================================================
Local oModel   	:= FWLoadModel( "AEST032" )

//===========================================================================
//Define a estrutura de dados para a View
//===========================================================================
Local oStruZZZ 	:= FWFormStruct( 2 , "ZZZ" )
Local oView		:= Nil

//===========================================================================
//Inicializa o Objeto da View
//===========================================================================
oView := FWFormView():New()

//===========================================================================
//Define o modelo que será utilizado
//===========================================================================
oView:SetModel( oModel )

//===========================================================================
//Define o modelo de dados da View
//===========================================================================
oView:AddField( "VIEW_ZZZ" , oStruZZZ , "ZZZMASTER" )

//===========================================================================
//Cria o Box Horizontal para a View
//===========================================================================
oView:CreateHorizontalBox( 'BOX0101' , 100 )

//===========================================================================
//Configura a exibição da View no Box
//===========================================================================
oView:SetOwnerView( "VIEW_ZZZ", "BOX0101" )

Return( oView )

/*
===============================================================================================================================
Programa----------: AEST032VLD
Autor-------------: Alexandre Villar
Data da Criacao---: 19/03/2014
Descrição---------: Validação inicial do Modelo de Dados
Retorno-----------: lRet - define se executa as ações do Modelo
===============================================================================================================================
*/

Static Function AEST032VLD( oModel )

Local _aArea := FWGetArea()
Local _lRet	 := .T.

//===========================================================================
//Verifica se usuário tem acesso à dar manutenção no cadastro de e-mail
//===========================================================================
If !U_ITVLDUSR(2)
	FWAlertWarning("O usuário atual não possui acesso para configurar os prazos de transferências.","AEST03201")
	_lRet := .F.
EndIf

FWRestArea(_aArea)

Return(_lRet)

/*
===============================================================================================================================
Programa----------: AEST032M
Autor-------------: Alexandre Villar
Data da Criacao---: 19/03/2014
Descrição---------: Pontos de Entrada do MVC
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AEST032M()

Local _aArea		:= FWGetArea()
Local aParam		:= ParamIXB
Local nOper			:= 0
Local nDias			:= 0
Local _lRet			:= .T.
Local oObj			:= ""
Local cIdPonto		:= ""
Local cIdModel		:= ""
Local cFilDe		:= ""
Local cFilAte		:= ""

If aParam <> NIL

	oObj		:= aParam[1]
	cIdPonto	:= aParam[2]
	cIdModel	:= aParam[3]
	nOper		:= oObj:GetOperation()
	
	If cIdPonto == 'FORMPOS'
	
		cFilDe	:= oObj:GetValue( "ZZZ_FILDE"	)
		cFilAte	:= oObj:GetValue( "ZZZ_FILATE"	)
		nDias	:= Val( oObj:GetValue( "ZZZ_PRAZOD"	) )
		
		//===========================================================================
		//Verifica se as Filiais de Origem/Destino são iguais
		//===========================================================================
		If _lRet .And. cFilDe == cFilAte
			FWAlertWarning("Não é possível configurar o prazo com a Filial de Origem igual à de Destino. Verifique o preenchimento das Filiais!","AEST03202")
			_lRet := .F.
		EndIf
		
		//===========================================================================
		//| Verifica na Inclusao se a Configuração de Origem/Destino já existe      |
		//===========================================================================
		If nOper == 3
			DBSelectArea("ZZZ")
			ZZZ->( DBSetOrder(1) )
			If ZZZ->( DBSeek( xFilial("ZZZ") + cFilDe + cFilAte ) )
				FWAlertWarning("Já existe no cadastro essa configuração de Filial de Origem e Destino."+;
								"Verifique o preenchimento das Filiais,  caso necessário utilize a opção Alterar para o registro já existente.","AEST03203")
				_lRet := .F.
			EndIf
		EndIf
		
		If nDias <= 0
			FWAlertWarning("É obrigatório informar o prazo de transferência e o mesmo deve ser maior que zero. É obrigatório informar o prazo de transferência e o mesmo deve ser maior que zero.","AEST03204")
			_lRet := .F.
		EndIf
	EndIf
EndIf

FWRestArea(_aArea)

Return(_lRet)
