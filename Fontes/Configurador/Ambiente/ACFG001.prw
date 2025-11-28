/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Josué Prestes |10/06/2019| Chamado 29593. Ajuste para loboguara
Lucas Borges  |17/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25.
===============================================================================================================================
*/
#Include "TOTVS.ch"               

/*
===============================================================================================================================
Programa----------: ACFG001
Autor-------------: Lucas Crevilari
Data da Criacao---: 24/10/2014
Descrição---------: Tela para amarrar Filial ao Centro de Custo
Parametros--------:
Retorno-----------:
===============================================================================================================================
*/
User Function ACFG001
      
Local oBrowse := Nil

oBrowse := FWMBrowse():New()
oBrowse:SetAlias( "ZLH" )
oBrowse:SetDescription( "Cadastro Filial X Centro de Custo" )
oBrowse:Activate()

Return

/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Lucas Crevilari
Data da Criacao---: 24/10/2014
Descrição---------: Rotina de definição automática do menu via MVC
Parametros--------: 
Retorno-----------: aRotina - Definições do menu principal da Rotina.
===============================================================================================================================
*/
Static Function MenuDef()

// FWMVCMenu - Gera o menu padrão para o Modelo Informado (Inc/Alt/Vis/Exc)

Return( FWMVCMenu("ACFG001") )

/*
===============================================================================================================================
Programa----------: ModelDef
Autor-------------: Lucas Crevilari
Data da Criacao---: 24/10/2014
Descrição---------: Rotina de definição do Modelo de Dados do MVC
Parametros--------: 
Retorno-----------: oModel - Objeto do modelo de dados do MVC
===============================================================================================================================
*/
Static Function ModelDef()

Local oStruZLH 	:= FWFormStruct( 1 , "ZLH" )
Local oModel	:= Nil

oModel := MPFormModel():New( "ACFG001M" ,  /*bPreValidacao*/ , /*bPosValidacao*/ , /*bCommit*/ , /*bCancel*/ )
oModel:SetDescription( "Filial X Centro de Custo" )

oModel:AddFields( "ZLHMASTER", /*cOwner*/ , oStruZLH , /*bPreValidacao*/ , /*bPosValidacao*/ , /*bCarga*/ )

oModel:GetModel( "ZLHMASTER" ):SetDescription( "Filial X Centro de Custo" )

Return( oModel )

/*
===============================================================================================================================
Programa----------: ViewDef
Autor-------------: Lucas Crevilari
Data da Criacao---: 24/10/2014
Descrição---------: Rotina de definição da View do MVC
Parametros--------: 
Retorno-----------: oView - Objeto de exibição do MVC
===============================================================================================================================
*/
Static Function ViewDef()

Local oModel   	:= FWLoadModel( "ACFG001" )
Local oStruZLH 	:= FWFormStruct( 2 , "ZLH" )
Local oView		:= Nil

oView := FWFormView():New()
oView:SetModel( oModel )
oView:AddField( "VIEW_ZLH" , oStruZLH , "ZLHMASTER" )

Return(oView)

/*
===============================================================================================================================
Programa----------: ITCTT
Autor-------------: Lucas Crevilari
Data da Criacao---: 24/10/2014
Descrição---------: Consulta específica usada no cadastro na ZLH. 
Parametros--------: 
Retorno-----------: .T. - Compatibilidade com a utilização em F3
===============================================================================================================================
*/
User Function ITCTT

Local nI			:= 0
Private nTam		:= 1       
Private nMaxSelect	:= 10
Private aResAux		:= {}
Private MvRet		:= AllTrim(ReadVar())
Private MvPar		:= ""
Private cTitulo		:= "Consulta Centro de Custo"
Private MvParDef	:= ""  

#IFDEF WINDOWS
	oWnd := GetWndDefault()
#EndIf

DBSelectArea("CTT")
CTT->( DBSetOrder(1) )
If CTT->( DBSeek(xFilial("CTT")) )

	While CTT->(!Eof())
		If !(SubStr(CTT->CTT_CUSTO,1,1) $ MvParDef)
			MvParDef += PadR( CTT->CTT_CUSTO , nTam ) 
			aAdd( aResAux , "Centro de Custo iniciado em "+PadR( CTT->CTT_CUSTO , nTam ) )
		EndIf		
		CTT->( DBSkip() )
	EndDo

	// Mantém a marcação anterior
   	If Len( AllTrim(&MvRet) ) == 0
		MvPar	:= PadR( AllTrim( StrTran( &MvRet , ";" , "" ) ) , Len(aResAux) )
		&MvRet	:= PadR( AllTrim( StrTran( &MvRet , ";" , "" ) ) , Len(aResAux) )
	Else
		MvPar	:= AllTrim( StrTran( &MvRet , ";" , "" ) )
	EndIf
	
	// Monta a tela de Opções genérica do Sistema
	f_Opcoes( @MvPar , cTitulo , aResAux , MvParDef , 12 , 49 , .F. , nTam , nMaxSelect )

	// Tratamento do retorno para separação por ";"
	&MvRet := ""

	If !Empty(MvPar)
	
		For	nI:= 1 to Len(MvPar) Step nTam
			If !( SubStr( MvPar , nI , 1 ) $ "|*" )
				&MvRet  += SubStr(MvPar,nI,nTam) + ";"
			EndIf
		Next
	
		// Retira separação do último registro
		&MvRet := SubStr(&MvRet,1,Len(&MvRet)-1)
	
	EndIf
	
Else
	Alert("Não foi encontrado registros na tabela CTT")
EndIf                
           
Return(.T.)

/*
===============================================================================================================================
Programa----------: CFGFil
Autor-------------: Lucas Crevilari
Data da Criacao---: 24/10/2014
Descrição---------: Verifica se não está incluindo filial duplicada na ZLH.
Parametros--------: 
Retorno-----------: .T. - Permite inclusão (Filial ainda não cadastrada)
===============================================================================================================================
*/
User Function CFGFil(_cFil)

Local lRet := .T.
Local aSaveArea := FWGetArea()

cQuery := " SELECT COUNT(ZLH.ZLH_FIL) AS CONT"
cQuery += " FROM " + RetSqlName("ZLH") + " ZLH"
cQuery += " WHERE ZLH.D_E_L_E_T_ = ' ' AND ZLH.ZLH_FIL = '" + _cFil + "'"

If Select("cQuery") > 0
	cQuery->( DBCloseArea() )
EndIf

DBUseArea(.T., "TOPCONN", TcGenQry(,,cQuery), "cQuery", .T., .F. )

DBSelectArea("cQuery")
If cQuery->(!Eof()) .And. cQuery->CONT <> 0
	lRet := .F.
EndIf
cQuery->( DBCloseArea() )                                                     
        
FWRestArea(aSaveArea)

Return(lRet)

/*
===============================================================================================================================
Programa----------: CTTZLH
Autor-------------: Lucas Crevilari
Data da Criacao---: 24/10/2014
Descrição---------: Filtro utilizado na Consulta padrão CTTZLH
Parametros--------: 
Retorno-----------:
===============================================================================================================================
*/
User Function CTTZLH()

Local lOk 		:= .T.
Local cFiltro	:= ""
Local cCustFil	:= ""  
Local cCcusto	:= ""
Local nQtdReg	:= 0
Local lPrim 	:= .T.
Local x			:= 0

DBSelectArea("ZLH")
DBSetOrder(1)
If DBSeek(xFilial("ZLH")+cFilAnt)
	cCcusto := AllTrim(ZLH->ZLH_CCUSTO)
	If !Empty(cCcusto)
		nQtdReg := Len(cCcusto)
	Else
		lOk := .F.
	EndIf
	
	If lOk
		For x := 1 To nQtdReg
			If SubStr(cCcusto,x,1) <> ";"
				cCustFil := SubStr(cCcusto,x,1)
				If lPrim
					cFiltro += "SubStr(CTT->CTT_CUSTO,1,1) == '"+cCustFil+"'"
				Else
					cFiltro += " .Or. SubStr(CTT->CTT_CUSTO,1,1) == '"+cCustFil+"'"
				EndIf
	            lPrim := .F.
			EndIf
		Next x
	EndIf    
EndIf

Return(cFiltro)
