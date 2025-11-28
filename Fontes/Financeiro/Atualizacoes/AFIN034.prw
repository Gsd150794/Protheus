/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Igor Melgaço  |08/01/2024| Chamado 46017. Ajustes para execução em MVC
Igor Melgaço  |25/04/2024| Chamado 46017. Ajustes para acesso atraves do FINA040 e FINA740
Igor Melgaço  |02/05/2024| Chamado 46017. Ajustes para acesso atraves do FINA740
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "TOPCONN.CH"

/*
===============================================================================================================================
Programa----------: AFIN034
Autor-------------: Igor Melgaço
Data da Criacao---: 08/11/2023
Descrição---------: Follow Up de Contas a Receber. Chamado: 45403 
Parametros--------: 
Retorno-----------:  
===============================================================================================================================
*/ 
User Function AFIN034()
    Local aArea   := FWGetArea()
    Local cTabela := "ZAC"
    Local _lFI04  := IsInCallStack("FINA040") .Or. IsInCallStack("FINA740")
    Local oBrowse := Nil

    Private cCadastro := "Follow-Ups de Contas a Receber"
    Private aRotina 	:= MenuDef() 

    If _lFI04
        cCadastro := " Follow-Ups de Cob. do Tit. " + SE1->E1_NUM + "  "+ SE1->E1_CLIENTE + " - " + SE1->E1_LOJA + "  " + AllTrim(Posicione("SA1",1,xFilial("SA1")+SE1->E1_CLIENTE+SE1->E1_LOJA,"A1_NREDUZ")) + " Fone: "+ Posicione("SA1",1,xFilial("SA1")+SE1->E1_CLIENTE+SE1->E1_LOJA,"A1_DDD") + " " + Posicione("SA1",1,xFilial("SA1")+SE1->E1_CLIENTE+SE1->E1_LOJA,"A1_TEL")
    EndIf

    oBrowse := FWMBrowse():New()
    oBrowse:SetAlias( cTabela )
    //oBrowse:SetMenuDef( "XXXXXX" )
    oBrowse:SetDescription( cCadastro )

    If _lFI04
        oBrowse:SetFilterDefault( "ZAC->ZAC_PREFIX == SE1->E1_PREFIXO .And. ZAC->ZAC_NUM == SE1->E1_NUM .And. ZAC->ZAC_TIPO == SE1->E1_TIPO " )
    EndIf

    oBrowse:Activate()

    FWRestArea(aArea)
Return

/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Igor Fricks
Data da Criacao---: 08/01/2024
Descrição---------: Rotina para criação do menu da tela principal
Parametros--------: Nenhum
Retorno-----------: _aRotina - Array com as opções de menu
===============================================================================================================================
*/
Static Function MenuDef()

Local aRotina2 := {}

aAdd( aRotina2, { 'Visualizar' , 'AxVisual', 0, 2, 0, NIL } )
aAdd( aRotina2, { 'Incluir' , 'AxInclui', 0, 3, 0, NIL } )
aAdd( aRotina2, { 'Alterar' , 'AxAltera', 0, 4, 0, NIL } )
aAdd( aRotina2, { 'Excluir' , 'AxDeleta', 0, 5, 0, NIL } )

Return( aRotina2 )


/*
===============================================================================================================================
Programa----------: ModelDef
Autor-------------: Igor Fricks
Data da Criacao---: 08/01/2024
Descrição---------: Rotina para montagem do modelo de dados para o processamento
Parametros--------: Nenhum
Retorno-----------: oModel
===============================================================================================================================
*/
Static Function ModelDef()
Local oStruZAC 	:= FWFormStruct( 1 , "ZAC" )
Local oModel	:= Nil

oModel := MPFormModel():New( "AFIN034M" , /*bPreValidacao*/ , /*bPosValidacao*/ , /*bCommit*/ , /*bCancel*/ )

oModel:AddFields('ZACMASTER', , oStruZAC)

oModel:SetPrimaryKey( {'ZAC_FILIAL','ZAC_PREFIX','ZAC_NUM','ZAC_TIPO','ZAC_SEQ'} )

Return( oModel )

/*
===============================================================================================================================
Programa----------: ViewDef
Autor-------------: Igor Fricks
Data da Criacao---: 08/01/2024
Descrição---------: Rotina de definição da View do MVC
Parametros--------: Nenhum
Retorno-----------: oView - Objeto de exibição do MVC
===============================================================================================================================
*/
Static Function ViewDef()
Local oModel   	:= FWLoadModel( "AFIN034" )
Local oStruZAC 	:= FWFormStruct( 2 , "ZAC" )
Local oView		:= Nil

oView := FWFormView():New()

oView:SetModel( oModel )

oView:AddField( "VIEW_ZAC" , oStruZAC , "ZACMASTER" )

oView:CreateHorizontalBox( 'BOX0101' , 100 )

oView:SetOwnerView( "VIEW_ZAC", "BOX0101" )

Return( oView )

/*
===============================================================================================================================
Programa----------: AFIN034GNU
Autor-------------: Igor Melgaço
Data da Criacao---: 08/11/2023
Descrição---------: Retorna proximo numero de integração
Parametros--------: 
Retorno-----------: _cRetorno   
===============================================================================================================================
*/
User Function AFIN034GNU()
	Local _cRetorno := ""
	Local _cQuery   := ""

	//////////////////////////////////////////////////////
	//Resgata ID de integração
	//////////////////////////////////////////////////////		
	_cQuery := " SELECT MAX(ZAC_SEQ) AS ID "
	_cQuery += " FROM " + RetSqlName("ZAC")
	_cQuery += " WHERE D_E_L_E_T_ <> '*'"
    _cQuery += " AND ZAC_FILIAL = '"+ SE1->E1_FILIAL + "' "
    _cQuery += " AND ZAC_PREFIX = '"+ SE1->E1_PREFIXO + "' "
    _cQuery += " AND ZAC_NUM = '"+ SE1->E1_NUM + "' "
    _cQuery += " AND ZAC_TIPO = '"+ SE1->E1_TIPO + "' "

	TcQuery _cQuery New Alias "QRY"

	DBSelectArea("QRY")
	DBGoTop()

	_cRetorno := StrZero(Val(Right(AllTrim(QRY->ID),3))+1,3)

	While !MayIUseCode( "ZAC_SEQ"+xFilial("Z26")+_cRetorno)  //verifica se esta na memoria, sendo usado
		_cRetorno := Soma1(_cRetorno)						 // busca o proximo numero disponivel
	EndDo

	DBSelectArea("QRY")
	DBCloseArea()

    If _cRetorno = "000"
        _cRetorno := "001"
    EndIf 

Return _cRetorno
