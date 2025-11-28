/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alexandre V.  |24/12/2014| Chamado 5453. Ajuste para inclusão do novo campo documentos fiscais nos boletos
Julio Paz     |08/05/2018| Chamado 24726. Padronização dos cabeçalhos dos fontes e funções do módulo financeiro.
Josué Danich  |26/06/2019| Chamado 28886. Revisão para loboguara
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: AFIN023
Autor-------------: Alexandre Villar
Data da Criacao---: 19/02/2014
Descrição---------: Cadastro das menagens a serem impressas nas Instrucoes do Boleto.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/

User Function AFIN023()
Local oBrowse		:= Nil
Private _cCodBco	:= ""

//====================================================================
// Instancia a classe do Browse 
//====================================================================
oBrowse := FWMBrowse():New()

//====================================================================
// Definicao da tabela do Browse 
//====================================================================
oBrowse:SetAlias("ZB2")

//====================================================================
// Definicao do titulo do Browse 
//====================================================================
oBrowse:SetDescription("Cadastro das Mensagens dos Boletos Bancários")

oBrowse:Activate()

Return

/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Alexandre Villar
Data da Criacao---: 19/02/2014
Descrição---------: Definição das opções de menu da rotina
Parametros--------: Nenhum
Retorno-----------: Retorna Menu definido no fonte "AFIN023"
===============================================================================================================================
*/

Static Function MenuDef()
Return( FWMVCMenu("AFIN023") )

/*
===============================================================================================================================
Programa----------: ModelDef
Autor-------------: Alexandre Villar
Data da Criacao---: 19/02/2014
Descrição---------: Definição da configuração do modelo de dados da rotina
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ModelDef()

//================================================================
// Cria a estrutura a ser usada no Modelo de Dados 
//================================================================
Local oStruZB2	:= FWFormStruct( 1 , "ZB2" )
Local oModel	:= Nil

//================================================================
// Tratamento para Campos Memos no Modelo de Dados 
//================================================================
FWMemoVirtual( oStruZB2 , { { 'ZB2_CDMSG1' , 'ZB2_MMMSG1' } , { 'ZB2_CDMSG2' , 'ZB2_MMMSG2' } , { 'ZB2_CDMSG3' , 'ZB2_MMMSG3' } } )

//================================================================
// Cria o objeto do Modelo de Dados
//================================================================
oModel := MPFormModel():New( "AFIN023M" )

//================================================================
// Adiciona a descricao do Modelo de Dados 
//================================================================
oModel:SetDescription( "Modelo de Dados Cadastro de Mensagens do Boleto Bancário" )

//======================================================================
// Adiciona ao modelo uma estrutura de formulário de edição por campo 
//======================================================================
oModel:AddFields( "ZB2MASTER" ,, oStruZB2 )

//================================================================
// Chave primaria do modelo
//================================================================
oModel:SetPrimaryKey( { "ZB2_FILIAL" , "ZB2_CODBCO" } )

Return(oModel)

/*
===============================================================================================================================
Programa----------: ViewDef
Autor-------------: Alexandre Villar
Data da Criacao---: 19/02/2014
Descrição---------: Definição das opções da View para construção das telas da rotina
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ViewDef()

Local oModel   	:= FWLoadModel( "AFIN023" )
Local oStruZB2	:= FWFormStruct( 2 , "ZB2" )
Local oView		:= Nil

oView := FWFormView():New()

//================================================================
// Define qual o Modelo de dados será utilizado 
//================================================================
oView:SetModel( oModel )

//================================================================
// Agrupamento dos Campos 
//================================================================
oStruZB2:AddGroup( 'GRUPO01' , 'Configurações do Banco'				, '' , 2 )
oStruZB2:AddGroup( 'GRUPO02' , 'Mensagens de Instrução do Boleto'	, '' , 2 )

//================================================================
// Definicao dos Campos para o Grupo 
//================================================================
oStruZB2:SetProperty( 'ZB2_CODBCO'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO01' )
oStruZB2:SetProperty( 'ZB2_NOMBCO'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO01' )
oStruZB2:SetProperty( 'ZB2_IMPDNF'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO01' )

oStruZB2:SetProperty( 'ZB2_MMMSG1'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO02' )
oStruZB2:SetProperty( 'ZB2_MMMSG2'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO02' )
oStruZB2:SetProperty( 'ZB2_MMMSG3'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO02' )

//================================================================
// Remove da tela os Campos de Id. do Memo 
//================================================================
oStruZB2:RemoveField( 'ZB2_CDMSG1' )
oStruZB2:RemoveField( 'ZB2_CDMSG2' )
oStruZB2:RemoveField( 'ZB2_CDMSG3' )

//=====================================================================
// Adiciona no View um controle do tipo FormFields(antiga enchoice) 
//=====================================================================
oView:AddField( "VIEW_ZB2" , oStruZB2 , "ZB2MASTER" )

Return( oView )

/*
===============================================================================================================================
Programa----------: AFINF3BC
Autor-------------: Alexandre Villar
Data da Criacao---: 19/02/2014
Descrição---------: Consulta genérica para F3 do ID do Banco
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AFINF3BC()

Local lRet 	   		:= .F.
Local nRetorno 		:= 0
Local cQuery   		:= ""

//=================================================
// Monta Query da Consulta 
//=================================================
cQuery := " SELECT DISTINCT "
cQuery += " 	'000' AS A6_COD, 'Cadastro Padrao' AS A6_NOME, 0 AS R_E_C_N_O_ "
cQuery += " FROM "+RetSQLName("SA6")+" SA6 "
cQuery += " UNION ALL "
cQuery += " SELECT DISTINCT "
cQuery += "   A6_COD, "
cQuery += "   A6_NOME, "
cQuery += "   R_E_C_N_O_ "
cQuery += " FROM "+RetSQLName("SA6")+" SA6 "
cQuery += " WHERE D_E_L_E_T_ = ' ' "
cQuery += " AND A6_COD NOT LIKE 'C%' "
cQuery += " AND A6_BLOCKED != '1' "

//=================================================
// Tela de F3 padrao
//=================================================
If Tk510F3Qry( cQuery , "A6_COD , A6_NOME" , "R_E_C_N_O_" , @nRetorno ,, { "A6_COD" , "A6_NOME" } , "SA6" )

	If nRetorno == 0
		_cCodBco := "000"
	Else
		DBSelectArea("SA6")
		SA6->( DBGoTo(nRetorno) )
		_cCodBco	:= A6_COD
	EndIf
	
	lRet := .T.
	
EndIf

Return(lRet)

/*
===============================================================================================================================
Programa----------: AFININIB
Autor-------------: Alexandre Villar
Data da Criacao---: 19/02/2014
Descrição---------: Inicializador padrão para o ID do Banco
Parametros--------: cCodBco := SA6->A6_COD de referencia.
Retorno-----------: cRet	:= Retorno com a descrição do banco.
===============================================================================================================================
*/
User Function AFININIB( cCodBco )

Local cRet		:= ""
Local nI		:= ""
Local nPosAux	:= 0
Default cCodBco	:= ""

If cCodBco == "000"

	cRet := "Cadastro Padrão"
	
Else

	DBSelectArea("SA6")
	SA6->( DBSetOrder(1) )
	If SA6->( DBSeek(xFilial("SA6")+cCodBco) )
		cRet := AllTrim(SA6->A6_NOME)
	Else
		cRet := "Não identificado"
	EndIf
	
EndIf

For nI := 1 To Len(cRet)
	
	If SubStr( cRet , nI , 1 ) == "-"
		nPosAux := nI - 1
		Exit
	EndIf
	
Next nI

If nPosAux > 0
	cRet := AllTrim( SubStr( cRet , 1 , nPosAux ) )
EndIf

Return(cRet)
