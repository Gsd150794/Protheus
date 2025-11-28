/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Igor Melgaço  |22/08/2025| Chamado 51757. Cadastro de Usuarios do Portal
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "FWMVCDEF.CH"

/*
===============================================================================================================================
Programa----------: AFIN039
Autor-------------: Igor Melgaço
Data da Criacao---: 15/09/2025
Descrição---------: Usuarios do Portal
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AFIN039(nOpcAuto As Numeric,aAutoCab As Array)
Local _oBrowse	:= Nil As Object

	_oBrowse := FWMBrowse():New()
	_oBrowse:SetAlias("AI3")
	_oBrowse:SetMenuDef( 'AFIN039' )
	_oBrowse:SetDescription("Usuarios do Portal")
	_oBrowse:SetFilterDefault( "AI3_I_PORT == '1'" )		

	_oBrowse:Activate()

Return

/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Igor Melgaço
Data da Criacao---: 15/09/2025
Descrição---------: Função utilizada para criação do menu
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MenuDef() As Array
Private aRotina := {} As Array

ADD OPTION aRotina Title "Visualizar" Action 'VIEWDEF.AFIN039' OPERATION 2 ACCESS 0 //
ADD OPTION aRotina Title "Incluir"    Action 'VIEWDEF.AFIN039' OPERATION 3 ACCESS 0 //
ADD OPTION aRotina Title "Alterar"    Action 'VIEWDEF.AFIN039' OPERATION 4 ACCESS 0 //
ADD OPTION aRotina Title "Excluir"    Action 'VIEWDEF.AFIN039' OPERATION 5 ACCESS 0 //	

Return(aRotina)	


/*
===============================================================================================================================
Programa----------: ModelDef
Autor-------------: Igor Melgaço
Data da Criacao---: 15/09/2025
Descrição---------: Rotina para montagem do modelo de dados para o processamento
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ModelDef() As Object

// Cria as estruturas a serem usadas no Modelo de Dados
Local oStruAI3 	:= FWFormStruct( 1, 'AI3') As Object
Local oStruAI4 	:= FWFormStruct( 1, 'AI4',{|x| (AllTrim(x) $ "|AI4_CODCLI|AI4_LOJCLI|AI4_NOMCLI|")}  ) As Object // Cria as estruturas a serem usadas na View
Local oModel As Object // Modelo de dados construído
Local _nI := 0 As Numeric
Local _cCposObr := "" As Character
Local aStructAI3 := FWSX3Util():GetListFieldsStruct("AI3", .F.) As Array

_cCposObr := "AI3_FILIAL|AI3_CODUSU|AI3_LOGIN|AI3_PSW|AI3_NOME|AI3_ADMIN|AI3_EMAIL|AI3_EMAIL|AI3_I_PORT|"

For _nI := 1 To Len(aStructAI3)

	If !(aStructAI3[_nI][1] $ _cCposObr) 
		oStruAI3:SetProperty( aStructAI3[_nI][1]	, MODEL_FIELD_OBRIGAT , .F. )
	EndIf

Next 

oStruAI3:SetProperty('AI3_ADMIN' , MODEL_FIELD_INIT ,{||'2'} )
oStruAI3:SetProperty("AI3_ADMIN" , MODEL_FIELD_WHEN ,{||.F.} )
oStruAI3:SetProperty("AI3_I_PORT", MODEL_FIELD_INIT ,{||'1'} )
oStruAI3:SetProperty("AI3_I_PORT" , MODEL_FIELD_WHEN ,{||.F.} )

//oStruAI6:SetProperty("AI6_WEBSRV" , MODEL_FIELD_INIT ,{||'PORTALCLIENTEMINGLE                     '} )

// Cria o objeto do Modelo de Dados
oModel := MPFormModel():New( 'AFIN039M' , /*{|oMdl| Ft220Pre(oMdl) }*/, {|oModel| U_AFIN39Pos(oModel)}, {|oModel| U_AFIN39Com(oModel)})

// Adiciona ao modelo um componente de formulário
oModel:AddFields( 'AI3MASTER', /*cOwner*/, oStruAI3 )

// Adiciona ao modelo componentes de grid
oModel:AddGrid( 'AI4DETAIL', 'AI3MASTER', oStruAI4 )

oModel:GetModel( "AI4DETAIL" ):SetUseOldGrid( .T. )

//Linhas unicas dos grids
oModel:GetModel( 'AI4DETAIL' ):SetUniqueLine( { 'AI4_CODCLI','AI4_LOJCLI'} )

//Deixa opcional adicionar itens
oModel:GetModel( 'AI4DETAIL'):SetOptional( .T. )

// Faz relacionamento entre os componentes do model
oModel:SetRelation( 'AI4DETAIL', { { 'AI4_FILIAL', 'xFilial( "AI4" )' }, { 'AI4_CODUSU', 'AI3_CODUSU' } }, AI4->( IndexKey( 1 ) ) )

// Adiciona a descrição do Modelo de Dados
oModel:SetDescription( "Usuarios do Portal" ) //"Usuarios do Portal"

// Adiciona a descrição dos Componentes do Modelo de Dados
oModel:GetModel( 'AI3MASTER' ):SetDescription( "Usuarios do Portal" ) //
oModel:GetModel( 'AI4DETAIL' ):SetDescription( "Clientes" ) //

oModel:SetPrimaryKey( {'AI3_FILIAL','AI3_CODUSU'} )

// Retorna o Modelo de dados
Return oModel

/*
===============================================================================================================================
Programa----------: ViewDef
Autor-------------: Igor Melgaço
Data da Criacao---: 15/09/2025
Descrição---------: Rotina para montar a View de Dados para exibição.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ViewDef() As Object

Local oModel	:= FWLoadModel( 'AFIN039' ) As Object	// Cria um objeto de Modelo de dados baseado no ModelDef do fonte informado
Local oStruAI3	:= FWFormStruct( 2, 'AI3') As Object 
Local oStruAI4	:= FWFormStruct( 2, 'AI4',{|x| (AllTrim(x) $ "|AI4_CODCLI|AI4_LOJCLI|AI4_NOMCLI|")} )  As Object
Local oView	 As Object // Interface de v// Cria as estruturas a serem usadas na View
Local _nI := 0 As Numeric
Local aStructAI3 := FWSX3Util():GetListFieldsStruct("AI3", .F.) As Array
Local _cCposObr := "" As Character

oView := FWFormView():New()								// Cria o objeto de View
oView:SetModel( oModel )									// Define qual Modelo de dados será utilizado				

_cCposObr := "AI3_FILIAL|AI3_CODUSU|AI3_LOGIN|AI3_PSW|AI3_NOME|AI3_ADMIN|AI3_EMAIL|AI3_EMAIL|AI3_I_PORT|"

For _nI := 1 To Len(aStructAI3)

	If !(aStructAI3[_nI][1] $ _cCposObr) 
		oStruAI3:RemoveField( aStructAI3[_nI][1] )
	EndIf

Next 

oView:AddField( 'VIEW_AI3', oStruAI3, 'AI3MASTER' )	// Adiciona no nosso View um controle do tipo formulário (antiga Enchoice)
oView:AddGrid( 'VIEW_AI4' , oStruAI4, 'AI4DETAIL' )	// Adiciona no nosso View um controle do tipo Grid (antiga Getdados)

oView:CreateHorizontalBox( 'SUPERIOR'  , 30 )
oView:CreateHorizontalBox( 'INFERIOR'  , 70 )

// Relaciona o identificador (ID) da View com o "box" para exibição
oView:SetOwnerView( 'VIEW_AI3', 'SUPERIOR' )		
oView:SetOwnerView( 'VIEW_AI4', 'INFERIOR' )

Return oView

/*
===============================================================================================================================
Programa----------: AFIN39Pos
Autor-------------: Igor Melgaço
Data da Criacao---: 15/09/2025
Descrição---------: Rotina de validação pós gravação do modelo de dados.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AFIN39Pos(oMdl As Object) As Logical

Local oMdlAI3	:= oMdl:GetModel('AI3MASTER') As Object
Local lRet		:= .T. As Logical

If oMdl:GetOperation() == MODEL_OPERATION_DELETE
	// Valida se o usuario esta sendo utlizado no Cad. Participantes (SIGAAPD)
	If lRet .And. TcCanOpen(RetSqlName("RD0"))
		lRet := Ft220CkRD0(oMdlAI3:GetValue("AI3_CODUSU"))
	EndIf

	/**
	   DEMAIS VALIDACOES PARA CONSIDERAR CADASTROS DE OUTROS MODULOS DEVEM SER COLOCADAS AQUI
	**/

	// Ponto de entrada para validar a exclusão do usuario.
	If lRet .And. ExistBlock("FT220Exc")
		lRet := ExecBlock("FT220Exc",.F.,.F.,{__cUserId,cUserName,oMdlAI3:GetValue("AI3_CODUSU"),oMdlAI3:GetValue("AI3_LOGIN"),oMdlAI3:GetValue("AI3_NOME")})
	EndIf

EndIf

Return lRet

/*
===============================================================================================================================
Programa----------: AFIN39Com
Autor-------------: Igor Melgaço
Data da Criacao---: 15/09/2025
Descrição---------: Commit de dados
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AFIN39Com(oMdl As Object) As Logical

Local cUsrForm	:= '' As Character 
Local nOper		:= oMdl:GetOperation() As Numeric
Local aArea		:= {} As Array
Local aAreaAA1	:= {} As Array
Local aAreaSA3	:= {} As Array
Local cUsrAI3	:= "" As Character
Local cFilAA1	:= "" As Character
Local cFilSA3	:= "" As Character

DBSelectArea("AI3")
DBSetOrder(1)
If MsSeek(xFilial("AI3")+oMdl:GetValue('AI3MASTER',"AI3_CODUSU"))
	cUsrAI3 := AI3->AI3_USRSIS
EndIf

If FWFormCommit( oMdl )

	If oMdl:GetOperation() == MODEL_OPERATION_INSERT
		DBSelectArea("AI6")
		DBSetOrder(1)
		RecLock("AI6",.T.)
		AI6->AI6_FILIAL := xFilial("AI6")
		AI6->AI6_CODUSU := oMdl:GetValue('AI3MASTER',"AI3_CODUSU")
		AI6->AI6_WEBSRV := 'PORTALCLIENTEMINGLE                     '
		AI6->(MSUnLock())
	EndIf

	If cUsrAI3 <> "" .And. cUsrAI3 <> cUsrForm .And. (nOper == MODEL_OPERATION_INSERT .Or. nOper == MODEL_OPERATION_UPDATE)
		// Realiza a substituição do código do usuário do sistema p/o Vendedor e/ou Técnico
		aArea		:= (Alias())->(GetArea())
		aAreaSA3	:= SA3->(GetArea())
   		aAreaAA1	:= AA1->(GetArea())
		cFilSA3		:= xFilial("SA3")
 		cFilAA1		:= xFilial("AA1")

		SA3->(DBSetOrder(7))	//A3_FILIAL+A3_CODUSR
		SA3->(MsSeek(cFilSA3+cUsrAI3))
		While SA3->(! Eof()) .And. SA3->A3_FILIAL == cFilSA3 .And. SA3->A3_CODUSR == cUsrAI3
			SA3->(RecLock("SA3",.F.))
			SA3->A3_CODUSR := cUsrForm
			SA3->(MSUnLock())
			SA3->(DBSkip())
		EndDo

		AA1->(DBSetOrder(4))	//AA1_FILIAL+AA1_CODUSR
		AA1->(MsSeek(cFilAA1+cUsrAI3))
		While AA1->(! Eof()) .And. AA1->AA1_FILIAL == cFilAA1 .And. AA1->AA1_CODUSR == cUsrAI3
			AA1->(RecLock("AA1",.F.))
			AA1->AA1_CODUSR := cUsrForm
			AA1->(MSUnLock())
			AA1->(DBSkip())
		EndDo

		FWRestArea(aAreaSA3)
		FWRestArea(aAreaAA1)
		FWRestArea(aArea)
		aAreaSA3	:= {}
		aAreaAA1	:= {}
		aArea		:= {}
	EndIf
EndIf

Return .T.


/*
===============================================================================================================================
Programa----------: Ft220CarrD
Autor-------------: Igor Melgaço
Data da Criacao---: 15/09/2025
Descrição---------: Commit de dados
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function Ft220CarrD(oView As Object) As Logical

Local oModel	:= FWModelActive() As Object
Local oMdlAI6	:= oModel:GetModel('AI6DETAIL') As Object
Local nOper		:= oModel:GetOperation() As Numeric
Local nLinha	:= oMdlAI6:Length() As Numeric
Local nI		:= 1 As Numeric
Local nQtdAI7	:= 0 As Numeric
Local aArea		:= {} As Array
Local aAreaAI7	:= {} As Array
Local aWebSrv	:= {} As Array
Local cFilAI7	:= "" As Character
Local cTitHelp	:= "" As Character
Local cSolHelp	:= "" As Character
Local lRet		:= .T. As Logical

If ( nOper == MODEL_OPERATION_UPDATE .Or. nOper == MODEL_OPERATION_INSERT) .AND.;
   ( lRet := ((IsBlind())            .Or. MsgYesNo("Confirma sobreposicao de todos os direitos?")) ) //

	aArea		:= FWGetArea()
	If nLinha > 0 .And. (! oMdlAI6:IsEmpty())
		For nI := 1 To nLinha
			oMdlAI6:GoLine(nI)
			oMdlAI6:DeleteLine()
		Next nI
	EndIf

	cFilAI7		:= xFilial("AI7")
	AI7->(DBSetOrder(1))
	AI7->(MsSeek(cFilAI7))	//AI7_FILIAL+AI7_WEBSRV
	While AI7->(! Eof()) .And. AI7->AI7_FILIAL == cFilAI7
		aAdd(aWebSrv, AI7->AI7_WEBSRV)
		AI7->(DBSkip())
	EndDo

	nQtdAI7	:= Len(aWebSrv)
	For nI := 1 To nQtdAI7
		If ! Empty(oMdlAI6:GetValue("AI6_WEBSRV"))
			nLinha		:= oMdlAI6:AddLine()
		EndIf
		If nLinha > 0
			oMdlAI6:GoLine(nLinha)
		EndIf	
		If !( lRet := oMdlAI6:SetValue("AI6_WEBSRV", aWebSrv[nI]) )
			aError		:= oModel:GetErrorMessage()
			cTitHelp	:= If(! Empty(aError[5]), aError[5], "Ft220CarrD")
			cSolHelp	:= ""
			Help("", 1, cTitHelp, , aError[6], 1, 0, , , , , , {cSolHelp})
			Exit
		EndIf
	Next nI

	oMdlAI6:GoLine(1)		
	FWRestArea(aArea)
	aWebSrv		:= {}
	aAreaAI7	:= {}
	aArea		:= {}

EndIf

Return lRet

/*
===============================================================================================================================
Programa----------: Ft220CkRD0
Autor-------------: Igor Melgaço
Data da Criacao---: 15/09/2025
Descrição---------: Commit de dados
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function Ft220CkRD0(cCodUsu As Character) As Logical

Local aArea		:= FWGetArea() As Array
Local cAliasQry	:= GetNextAlias() As Character
Local lRet		:= .T. As Logical

BeginSql Alias cAliasQry
	SELECT COUNT(*) TOTAL
	  FROM %Table:RD0% RD0
	 WHERE RD0.RD0_FILIAL = %xFilial:RD0%
	   AND RD0.RD0_PORTAL =	%Exp:cCodUsu%
	   AND RD0.%NotDel%
EndSql
If (cAliasQry)->TOTAL > 0
	Help("", 1, "Ft220CkRD0", , "Impossível Excluir"+CRLF+"Este usuário esta associado a um registro do Cdastro de Participantes do SIGAAPD", 1, 0)	//##
	lRet	:= .F.
EndIf
(cAliasQry)->(DBCloseArea())
FWRestArea(aArea)
aArea := {}

Return lRet
