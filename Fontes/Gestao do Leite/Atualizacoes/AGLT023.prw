/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |09/08/2018| Chamado 25767. Incluído MenuDef para padronização
Lucas Borges  |13/06/2019| Chamado 28346. Revisão de fontes
Lucas Borges  |27/09/2019| Chamado 28346. Revisão de fontes
===============================================================================================================================
*/

#Include	"Protheus.Ch"
#Include	"FWMVCDef.Ch"

/*
===============================================================================================================================
Programa----------: AGLT023
Autor-------------: Alexandre Villar
Data da Criacao---: 04/06/2014
Descrição---------: Rotina de manutenção do cadastro de usuários do módulo Gestão do Leite ( Acesso à Setores e Linhas )
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT023

Local _oBrowse := Nil

//================================================================================
//| Instancia o objeto do Browse                                                 |
//================================================================================
_oBrowse := FWMBrowse():New()
_oBrowse:SetAlias("ZLU")
_oBrowse:SetDescription("Controle de Acessos - Gestão do Leite")
_oBrowse:DisableDetails()
_oBrowse:Activate()

Return

/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Alexandre Villar
Data da Criacao---: 04/06/2014
Descrição---------: Constrói o Menu da Rotina principal
Parametros--------: Nenhum
Retorno-----------: aRotina - Definições do menu da rotina principal
===============================================================================================================================
*/
Static Function MenuDef()
Return( FWMVCMenu("AGLT023") ) //Retorna o conceito padrão para o aRotina

/*
===============================================================================================================================
Programa----------: ModelDef
Autor-------------: Alexandre Villar
Data da Criacao---: 04/06/2014
Descrição---------: Constrói o Modelo de Dados da Rotina
Parametros--------: Nenhum
Retorno-----------: oModel - Objeto do Modelo de Dados
===============================================================================================================================
*/
Static Function ModelDef()

//================================================================================
//| Monta as estruturas de dados.                                                |
//================================================================================
Local oStruZLU 	:= FWFormStruct( 1 , "ZLU" )
Local oStruZLV 	:= FWFormStruct( 1 , "ZLV" , { |cCampo| AGLT023CPO( cCampo ) } )
Local oStruZLR 	:= FWFormStruct( 1 , "ZLR" , { |cCampo| AGLT023CPO( cCampo ) } )
Local oModel	:= Nil

//================================================================================
//| Monta as estruturas de Gatilhos.                                             |
//================================================================================
Local aGatilho	:= FwStruTrigger( 'ZLV_SETOR' , 'ZLV_DESCRI' , "U_GLTSETD()" , .F. )

oStruZLV:AddTrigger( aGatilho[1] , aGatilho[2] , aGatilho[3] , aGatilho[4] )

//================================================================================
//| Instancia o modelo de dados e definições das propriedades                    |
//================================================================================
oModel := MPFormModel():New( "AGLT023M" , /*bPreValidacao*/ , /*bPosValidacao*/ , /*bCommit*/ , /*bCancel*/ )
oModel:SetDescription( "Manutenção do Controle de Acessos ao Módulo GLT" )

//================================================================================
//| Monta a estrutura de dados no modelo                                         |
//================================================================================
oModel:AddFields(	"ZLUMASTER" , /*cOwner*/	, oStruZLU , /*bPreValidacao*/ , /*bPosValidacao*/ , /*bCarga*/ )
oModel:AddGrid(		"ZLVDETAIL" , "ZLUMASTER"	, oStruZLV , /*bPreValidacao*/ , /*bPosValidacao*/ , /*bCarga*/ )
oModel:AddGrid(		"ZLRDETAIL" , "ZLVDETAIL"	, oStruZLR , /*bPreValidacao*/ , /*bPosValidacao*/ , /*bCarga*/ )

//================================================================================
//| Relaciona as estruturas de dados do modelo                                   |
//================================================================================
oModel:SetRelation( "ZLVDETAIL" , { { "ZLV_FILIAL" , "ZLU_FILIAL" } , { "ZLV_CODUSU" , "ZLU_CODUSU" } } , ZLV->( IndexKey( 1 ) ) )
oModel:SetRelation( "ZLRDETAIL" , { { "ZLR_FILIAL" , "ZLU_FILIAL" } , { "ZLR_CODUSU" , "ZLU_CODUSU" } , { "ZLR_SETOR" , "ZLV_SETOR" } } , ZLR->( IndexKey( 1 ) ) )

//================================================================================
//| Definições das propriedades do Modelo                                        |
//================================================================================
oModel:GetModel( 'ZLVDETAIL' ):SetUniqueLine( { 'ZLV_SETOR' } )
oModel:GetModel( 'ZLRDETAIL' ):SetUniqueLine( { 'ZLR_LINHA' } )

oModel:GetModel( 'ZLRDETAIL' ):SetOptional( .T. )

oModel:GetModel( "ZLUMASTER" ):SetDescription( "Acessos do Usuário ao Módulo GLT"				)
oModel:GetModel( "ZLVDETAIL" ):SetDescription( "Setores liberados pro Usuário no Módulo GLT"	)
oModel:GetModel( "ZLRDETAIL" ):SetDescription( "Linhas liberadas pro Usuário no Módulo GLT"		)

//================================================================================
//| Validação Inicial do Modelo                                                  |
//================================================================================
oModel:SetVldActivate( { |oModel| AGLT023VLD( oModel ) } )

Return(oModel)

/*
===============================================================================================================================
Programa----------: ViewDef
Autor-------------: Alexandre Villar
Data da Criacao---: 04/06/2014
Descrição---------: Constrói a View da Rotina
Parametros--------: Nenhum
Retorno-----------: oView - Objeto da View de Dados
===============================================================================================================================
*/
Static Function ViewDef()

//================================================================================
//| Instancia o Modelo de dados                                                  |
//================================================================================
Local oModel   	:= FWLoadModel( "AGLT023" )

//================================================================================
//| Monta as estruturas para o Modelo de dados                                   |
//================================================================================
Local oStruZLU 	:= FWFormStruct( 2, "ZLU" )
Local oStruZLV 	:= FWFormStruct( 2, "ZLV" , { |cCampo| AGLT023CPO( cCampo ) } )
Local oStruZLR 	:= FWFormStruct( 2, "ZLR" , { |cCampo| AGLT023CPO( cCampo ) } )
Local oView		:= Nil

//================================================================================
//| Instancia o Objeto da View                                                   |
//================================================================================
oView := FWFormView():New()

//================================================================================
//| Define o modelo de dados da view                                             |
//================================================================================
oView:SetModel( oModel )

//================================================================================
//| Instancia os objetos da View com as estruturas de dados                      |
//================================================================================
oView:AddField(	"VIEW_ZLU" , oStruZLU , "ZLUMASTER" )
oView:AddGrid(	"VIEW_ZLV" , oStruZLV , "ZLVDETAIL" )
oView:AddGrid(	"VIEW_ZLR" , oStruZLR , "ZLRDETAIL" )

//================================================================================
//| Cria os Box horizontais para a View                                          |
//================================================================================
oView:CreateHorizontalBox( 'BOX0101' 	, 40 , , , , ) //% da tela ativa
oView:CreateHorizontalBox( 'BOX0102' 	, 30 , , , , ) //% da tela ativa
oView:CreateHorizontalBox( 'BOX0103' 	, 30 , , , , ) //% da tela ativa

//================================================================================
//| Define as estruturas da View para cada Box                                   |
//================================================================================
oView:SetOwnerView( "VIEW_ZLU" , "BOX0101" )
oView:SetOwnerView( "VIEW_ZLV" , "BOX0102" )
oView:SetOwnerView( "VIEW_ZLR" , "BOX0103" )

Return( oView )

/*
===============================================================================================================================
Programa----------: AGLT023VLD
Autor-------------: Alexandre Villar
Data da Criacao---: 04/06/2014
Descrição---------: Validação inicial do modelo de dados
Parametros--------: Nenhum
Retorno-----------: lRet - Indica a validação foi concluída com sucesso ou aborta a execução.
===============================================================================================================================
*/
Static Function AGLT023VLD( oModel )

Local lRet      := .T.

Return(lRet)

/*
===============================================================================================================================
Programa----------: AGLT023S
Autor-------------: Alexandre Villar
Data da Criacao---: 04/06/2014
Descrição---------: Gatilho para o código do Setor e Rotina de gravação da seleção de vários setores ao mesmo tempo
Parametros--------: Nenhum
Retorno-----------: lRet - Indica se o código foi validado ou seje já existe
===============================================================================================================================
*/
User Function AGLT23S( nOpc )

Local aArea		:= FWGetArea()
Local aDados	:= {}
Local oModAux	:= FWModelActive()
Local oModZLV	:= oModAux:GetModel( "ZLVDETAIL" )
Local lGrvSet	:= .T.
Local cChave	:= SubStr( oModZLV:GetValue( "ZLV_SETOR" ) , 1 , 2 ) + oModZLV:GetValue( "ZLV_SETOR" )
Local cRet		:= ""
Local nI		:= 0
Local nPos		:= 0
Local nLinhas	:= 0

Default nOpc	:= 0

If nOpc == 0
	
	DBSelectArea("ZL2")
	ZL2->( DBSetOrder(1) )
	If ZL2->( DBSeek( cChave ) )
		cRet := AllTrim( ZL2->ZL2_DESCRI )
	Else
		cRet := "Chave não encontrada: "+ cChave
	EndIf

ElseIf nOpc == 1
	
	aDados := U_ITGENSEL( "Selecione os setores" , TamSX3("ZL2_COD")[01] , "ZL2" , 1 , "ZL2_COD" , "ZL2_DESCRI" )
	
	If !Empty( aDados )
	
		For nI := 1 To Len( aDados )
			
			nLinhas := oModZLV:Length()
			lGrvSet	:= .T.
			
			For nPos := 1 To nLinhas
				
				oModZLV:GoLine( nPos )
				
				If oModZLV:GetValue( "ZLV_SETOR" ) == aDados[nI]
					If oModZLV:IsDeleted()
						oModZLV:UnDeleteLine()
					EndIf
					lGrvSet := .F.
					Exit
				EndIf
				
			Next nPos
			
			If lGrvSet
				If nLinhas > 1 .Or. !Empty( oModZLV:GetValue( "ZLV_SETOR" ) )
					If oModZLV:AddLine() > nLinhas
						oModZLV:SetValue( "ZLV_SETOR" , aDados[nI] )
					EndIf
				Else
					oModZLV:SetValue( "ZLV_SETOR" , aDados[nI] )
				EndIf
			EndIf
			
		Next nI
		
		oModZLV:GoLine( 1 )
	
	EndIf
	
EndIf

FWRestArea( aArea )

Return( cRet )

/*
===============================================================================================================================
Programa----------: AGLT023M
Autor-------------: Alexandre Villar
Data da Criacao---: 04/06/2014
Descrição---------: Ponto de entrada do MVC
Parametros--------: Nenhum
Retorno-----------: xRet - Retorno esperado para o ponto de entrada
===============================================================================================================================
*/
User Function AGLT023M()

Local aParam	:= ParamIXB
Local xRet		:= .T.
Local oObj		:= ''
Local cIdPonto	:= ''
Local cIdModel	:= ''
Local lIsGrid	:= .F.
Local nLinha	:= 0
Local nQtdLinhas:= 0

If aParam <> NIL

	oObj		:= aParam[1]
	cIdPonto	:= aParam[2]
	cIdModel	:= aParam[3]
	lIsGrid		:= ( Len(aParam) > 3 .And. ValType(aParam[04]) == "N" )
	
	If lIsGrid
		nQtdLinhas	:= oObj:GetQtdLine()
		nLinha		:= oObj:nLine
	EndIf
	
	If cIdPonto == "BUTTONBAR"
		xRet := {}
		aAdd( xRet , { "Setores" , "autom_ocean" , {|| U_AGLT23S( 1 ) } , "Seleção de Setores" } )
	EndIf
	
EndIf

Return( xRet )

/*
===============================================================================================================================
Programa----------: AGLT023V
Autor-------------: Alexandre Villar
Data da Criacao---: 04/06/2014
Descrição---------: Valida se o código de usuário já existe no cadastro
Parametros--------: Nenhum
Retorno-----------: lRet - Indica se o código foi validado ou seje já existe
===============================================================================================================================
*/
User Function AGLT023V( cCodUsu )

Local _lRet := .T.
Local _cAlias	:= GetNextAlias()

BeginSql Alias _cAlias
	SELECT COUNT(1) QTD
	FROM %Table:ZLU%
	WHERE D_E_L_E_T_ =' '
	AND ZLU_FILIAL = %xFilial:ZLU%
	AND ZLU_CODUSU = %exp:cCodUsu%
EndSql

If (_cAlias)->QTD > 0
	_lRet := .F.
	MsgStop("O código informado já encontra-se no cadastro de gestão de usuários.","AGLT02303")
EndIf

(_cAlias)->( DBCloseArea() )

Return( lRet )

/*
===============================================================================================================================
Programa----------: AGLT023CPO
Autor-------------: Alexandre Villar
Data da Criacao---: 04/06/2014
Descrição---------: Valida os Campos que serão exibidos no Browse
Parametros--------: Nenhum
Retorno-----------: lRet - Indica se o código foi validado ou seje já existe
===============================================================================================================================
*/

Static Function AGLT023CPO( cCampo )

Local lRet := AllTrim(cCampo) $ "ZLV_SETOR,ZLV_DESCRI,ZLR_LINHA,ZLR_DESLIN"

Return(lRet)

/*
===============================================================================================================================
Programa----------: GLTSETD
Autor-------------: Alexandre Villar
Data da Criacao---: 04/06/2014
Descrição---------: Função de Gatilho para o campo "ZLV_SETOR"
Parametros--------: Nenhum
Retorno-----------: cRet - Descrição do Setor que será retornado para o gatilho
===============================================================================================================================
*/
User Function GLTSETD()

Local cRet		:= ""
Local cChave	:= ""
Local oModAux	:= FWModelActive()
Local oModZLV	:= oModAux:GetModel( "ZLVDETAIL" )

cChave := SubStr( oModZLV:GetValue( "ZLV_SETOR" ) , 1 , 2 ) + oModZLV:GetValue( "ZLV_SETOR" )

DBSelectArea("ZL2")
ZL2->( DBSetOrder(1) )
If ZL2->( DBSeek( cChave ) )
	cRet := AllTrim( ZL2->ZL2_DESCRI )
EndIf

Return( cRet )

/*
===============================================================================================================================
Programa----------: GLTLIND
Autor-------------: Alexandre Villar
Data da Criacao---: 04/06/2014
Descrição---------: Função de Gatilho para o campo "ZLR_LINHA"
Parametros--------: Nenhum
Retorno-----------: cRet - Descrição do Setor que será retornado para o gatilho
===============================================================================================================================
*/
User Function GLTLIND()

Local cRet		:= ""
Local cChave	:= ""
Local oModAux	:= FWModelActive()
Local oModZLR	:= oModAux:GetModel( "ZLRDETAIL" )

cChave := SubStr( oModZLR:GetValue( "ZLR_LINHA" ) , 1 , 2 ) + oModZLR:GetValue( "ZLR_LINHA" )

DBSelectArea("ZL3")
ZL3->( DBSetOrder(1) )
If ZL3->( DBSeek( cChave ) )
	cRet := PadR( ZL3->ZL3_DESCRI , TamSX3("ZLR_DESLIN")[01] )
EndIf

oModZLR:LoadValue( "ZLR_DESLIN" , cRet )

Return( cRet )

/*
===============================================================================================================================
Programa----------: GLTF3LIN
Autor-------------: Alexandre Villar
Data da Criacao---: 04/06/2014
Descrição---------: Função de Consulta Padrão para o campo "ZLR_LINHA"
Parametros--------: Nenhum
Retorno-----------: cRet - Descrição do Setor que será retornado para o gatilho
===============================================================================================================================
*/
User Function GLTF3LIN()

Local lRet 	   	:= .F.
Local nRetorno 	:= 0
Local cQuery   	:= ""
Local oModAux	:= FWModelActive()
Local oModZLV	:= oModAux:GetModel( "ZLVDETAIL" )

cQuery := " SELECT "
cQuery += " 	ZL3.ZL3_COD, "
cQuery += " 	ZL3.ZL3_DESCRI, "
cQuery += " 	R_E_C_N_O_ AS REGZL3 "
cQuery += " FROM "+ RetSqlName("ZL3") +" ZL3 "
cQuery += " WHERE "
cQuery += "     ZL3.D_E_L_E_T_  = ' ' "
cQuery += " AND ZL3.ZL3_SETOR   = '"+ oModZLV:GetValue("ZLV_SETOR") +"' "

//================================================================================
//| Monta nova janela de consulta padrão utilizando a query para listar os dados |
//================================================================================
If 	Tk510F3Qry( cQuery /*cQuery*/, "GLTLIN"/*cCodCon*/, "REGZL3"/*cCpoRecno*/,@nRetorno/*nRetorno*/,/*aCoord*/,{"ZL3_COD","ZL3_DESCRI"}/*aSearch*/,"ZL3"/*cAlias*/)
	ZL3->( DBGoTo(nRetorno) )
	lRet := .T.
EndIf

Return(lRet)
