/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |14/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25
Julio Paz     |11/11/2021| Chamado 38207. Criar consulta específica p/listar Geren.,Coordend.,Supervis.,Vended.Vinculados
Lucas Borges  |08/10/2024| Chamado 48465. Retirada manipulação do SX1
===============================================================================================================================
*/

//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================
#Include "TOTVS.ch"
#Include "FWMVCDEF.ch"

#DEFINE _ENTER CHR(13) + CHR(10)
#define MVC_VIEWDEF_NAME "VIEWDEF.AOMS107"

/*
===============================================================================================================================
Programa--------: AOMS107
Autor-----------: Josué Danich Prestes
Data da Criacao-: 10/08/2011
===============================================================================================================================
Descrição-------: Cadastro de regras personalizadas de tabela de preços - Chamado 24295
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function AOMS107()

Local _oBrowse

Private aRotina	 := {}
Private _cMvcRet := Space(6)
Private INCLUI := .F.

//Instanciamento
_oBrowse := FWMBrowse():New()

//tabela que será utilizada
_oBrowse:SetAlias( "ZGQ" )

//Define menus
ADD OPTION aRotina Title 'Visualizar'	Action 'VIEWDEF.AOMS107'	OPERATION 2 ACCESS 0
ADD OPTION aRotina Title 'Incluir'		Action 'VIEWDEF.AOMS107'	OPERATION 3 ACCESS 0
ADD OPTION aRotina Title 'Alterar'		Action 'VIEWDEF.AOMS107'    OPERATION 4 ACCESS 0   
ADD OPTION aRotina Title 'Excluir'		Action 'VIEWDEF.AOMS107'	OPERATION 5 ACCESS 0
ADD OPTION aRotina Title 'Historico'	Action 'U_AOMS107H'	        OPERATION 2 ACCESS 0

//Titulo
_oBrowse:SetDescription( "Regras de tabelas de preços" )

//ativa
_oBrowse:Activate()

Return


/*
===============================================================================================================================
Programa----------: ModelDef
Autor-------------: Josué Danich Prestes
Data da Criacao---: 29/03/2018
===============================================================================================================================
Descrição---------: Define o modelo de dados para a rotina de cadastro
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/

Static Function ModelDef()
Local oStruCAB As Object 

//================================================================================
// Prepara a estrutura a ser usada no Modelo de Dados
//================================================================================
Local oModel As Object	
Local _aGatAux	:= {}

//================================================================================
// Estrutura de campos
//================================================================================
oStruCAB := FWFormStruct( 1 , 'ZGQ')

//================================================================================
// Criação dos gatilhos 
//================================================================================
_aGatAux := FwStruTrigger( 'ZGQ_TABPRE'	, 'ZGQ_DESCTB'	, 'IIf(Empty(AllTrim(M->ZGQ_TABPRE)),"   ",Posicione("DA0",1,xFilial("DA0")+M->ZGQ_TABPRE,"DA0_DESCRI"))'			, .F. )
oStruCAB:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZGQ_FILEMB'	, 'ZGQ_FILDES'	, 'IIf(Empty(AllTrim(M->ZGQ_FILEMB)),"   ",Posicione("ZZM",1,xFilial("ZZM")+M->ZGQ_FILEMB,"ZZM_DESCRI"))'			, .F. )
oStruCAB:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZGQ_GEREN'	, 'ZGQ_GERNOM'	, 'IIf(Empty(AllTrim(M->ZGQ_GEREN)),"   ",Posicione("SA3",1,xFilial("SA3")+M->ZGQ_GEREN,"A3_NOME"))'			, .F. )
oStruCAB:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZGQ_COORDE'	, 'ZGQ_COONOM'	, 'IIf(Empty(AllTrim(M->ZGQ_COORDE)),"   ",Posicione("SA3",1,xFilial("SA3")+M->ZGQ_COORDE,"A3_NOME"))'			, .F. )
oStruCAB:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZGQ_COORDE'	, 'ZGQ_GEREN'	, 'IIf(Empty(AllTrim(M->ZGQ_COORDE)),"   ",Posicione("SA3",1,xFilial("SA3")+M->ZGQ_COORDE,"A3_GEREN"))'			, .F. )
oStruCAB:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZGQ_SUPERV'	, 'ZGQ_GEREN'	, 'IIf(Empty(AllTrim(M->ZGQ_SUPERV)),"   ",Posicione("SA3",1,xFilial("SA3")+M->ZGQ_SUPERV,"A3_GEREN"))'			, .F. )
oStruCAB:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZGQ_SUPERV'	, 'ZGQ_COORDE'	, 'IIf(Empty(AllTrim(M->ZGQ_SUPERV)),"   ",Posicione("SA3",1,xFilial("SA3")+M->ZGQ_SUPERV,"A3_SUPER"))'			, .F. )
oStruCAB:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZGQ_SUPERV'	, 'ZGQ_SUPNOM'	, 'IIf(Empty(AllTrim(M->ZGQ_SUPERV)),"   ",Posicione("SA3",1,xFilial("SA3")+M->ZGQ_SUPERV,"A3_NOME"))'			, .F. )
oStruCAB:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZGQ_VENDED'	, 'ZGQ_VENNOM'	, 'IIf(Empty(AllTrim(M->ZGQ_VENDED)),"   ",Posicione("SA3",1,xFilial("SA3")+M->ZGQ_VENDED,"A3_NOME"))'			, .F. )
oStruCAB:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZGQ_VENDED'	, 'ZGQ_GEREN'	, 'IIf(Empty(AllTrim(M->ZGQ_VENDED)),"   ",Posicione("SA3",1,xFilial("SA3")+M->ZGQ_VENDED,"A3_GEREN"))'			, .F. )
oStruCAB:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZGQ_VENDED'	, 'ZGQ_COORDE'	, 'IIf(Empty(AllTrim(M->ZGQ_VENDED)),"   ",Posicione("SA3",1,xFilial("SA3")+M->ZGQ_VENDED,"A3_SUPER"))'			, .F. )
oStruCAB:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZGQ_VENDED'	, 'ZGQ_SUPERV'	, 'IIf(Empty(AllTrim(M->ZGQ_VENDED)),"   ",Posicione("SA3",1,xFilial("SA3")+M->ZGQ_VENDED,"A3_I_SUPE"))'			, .F. )
oStruCAB:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZGQ_CLIENT'	, 'ZGQ_CLINOM'	, 'IIf(Empty(AllTrim(M->ZGQ_CLIENT+M->ZGQ_LOJA)),"  ",Posicione("SA1",1,xFilial("SA1")+M->ZGQ_CLIENT+M->ZGQ_LOJA,"A1_NOME"))'			, .F. )
oStruCAB:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZGQ_LOJA'	, 'ZGQ_CLINOM'	, 'IIf(Empty(AllTrim(M->ZGQ_CLIENT+M->ZGQ_LOJA)),"  ",Posicione("SA1",1,xFilial("SA1")+M->ZGQ_CLIENT+M->ZGQ_LOJA,"A1_NOME"))'			, .F. )
oStruCAB:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZGQ_CLIENT'	, 'ZGQ_REDE'	, 'IIf(Empty(AllTrim(M->ZGQ_CLIENT+M->ZGQ_LOJA)),"  ",Posicione("SA1",1,xFilial("SA1")+M->ZGQ_CLIENT+M->ZGQ_LOJA,"A1_GRPVEN"))'			, .F. )
oStruCAB:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZGQ_LOJA'	, 'ZGQ_REDE'	, 'IIf(Empty(AllTrim(M->ZGQ_CLIENT+M->ZGQ_LOJA)),"  ",Posicione("SA1",1,xFilial("SA1")+M->ZGQ_CLIENT+M->ZGQ_LOJA,"A1_GRPVEN"))'			, .F. )
oStruCAB:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZGQ_CLIENT'	, 'ZGQ_VENDED'	, 'IIf(Empty(AllTrim(M->ZGQ_CLIENT+M->ZGQ_LOJA)),"  ",Posicione("SA1",1,xFilial("SA1")+M->ZGQ_CLIENT+M->ZGQ_LOJA,"A1_VEND"))'			, .F. )
oStruCAB:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZGQ_LOJA'	, 'ZGQ_VENDED'	, 'IIf(Empty(AllTrim(M->ZGQ_CLIENT+M->ZGQ_LOJA)),"  ",Posicione("SA1",1,xFilial("SA1")+M->ZGQ_CLIENT+M->ZGQ_LOJA,"A1_VEND"))'			, .F. )
oStruCAB:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZGQ_REDE'	, 'ZGQ_REDNOM'	, 'IIf(Empty(AllTrim(M->ZGQ_REDE)),"    ",Posicione("ACY",1,xFilial("ACY")+M->ZGQ_REDE,"ACY_DESCRI"))'			, .F. )
oStruCAB:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

//================================================================================
// Cria e configura o modelo de dados
//================================================================================
oModel := MPFormModel():New( 'AOMS107M' )

oModel:SetDescription( 'Modelo de Dados do Lançamento de Conhecimento de Transporte' )

oModel:AddFields(	"ZGQMASTER" , /*cOwner*/  , oStruCAB , /*bPreValidacao*/ , {|| U_AOMS107W()} /*bPosValidacao*/ , /*bCarga*/ )

oModel:GetModel( "ZGQMASTER" ):SetDescription( "Dados da Regra"	)

oModel:SetPrimaryKey( { 'ZGQ_FILIAL' , 'ZGQ_ITEM', 'ZGQ_CLIENT' , 'ZGQ_LOJA', 'ZGQ_REDE', "ZGQ_FILFAT",'ZGQ_FILEMB'} )

Return( oModel )

/*
===============================================================================================================================
Programa----------: ViewDef
Autor-------------: Josué Danich Prestes
Data da Criacao---: 29/03/2018
===============================================================================================================================
Descrição---------: Define a View de dados para a rotina de cadastro
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ViewDef()

//================================================================================
// Prepara a estrutura do objeto da View
//================================================================================
Local oModel   	:= FWLoadModel( 'AOMS107' )

Local oStruCAB As Object //	:= FWFormStruct( 1 , 'ZGQ' , { |cCampo| AOMS107K( cCampo , 1 ) } )
Local oView		:= Nil

//================================================================================
// Estrutura de Dados
//================================================================================            
oStruCAB := FWFormStruct( 2 , 'ZGQ' )

//================================================================================
// Instancia o Objeto da View
//================================================================================
oView := FWFormView():New()

//================================================================================
// Define o modelo de dados da view
//================================================================================
oView:SetModel( oModel )

//================================================================================
// Instancia os objetos da View com as estruturas de dados
//================================================================================
oView:AddField(	"VIEW_CAB"	, oStruCAB	, "ZGQMASTER"	)

//================================================================================
// Cria os Box horizontais para a View
//================================================================================
oView:CreateHorizontalBox( 'BOX0101' , 100 )

//================================================================================
// Define as estruturas da View para cada Box
//================================================================================
oView:SetOwnerView( "VIEW_CAB" , "BOX0101" )

Return( oView )

/*
===============================================================================================================================
Programa----------: AOMS107K
Autor-------------: Josué Danich Prestes
Data da Criacao---: 29/03/2018
===============================================================================================================================
Descrição---------: Valida os Campos que serão exibidos no Browse
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: lRet - Indica se o código foi validado ou seje já existe
===============================================================================================================================
*/

Static Function AOMS107K( _cCampo , _nLocal )

Local _lRet := AllTrim( _cCampo ) $ "ZGQ_FILIAL,ZGQ_FILEMB,ZGQ_FILDES"

If _nLocal == 2
	_lRet := !_lRet
EndIf

Return( _lRet )

/*
===============================================================================================================================
Programa----------: AOMS107M
Autor-------------: Alexandre Villar
Data da Criacao---: 22/10/2014
===============================================================================================================================
Descrição---------: Rotina de controle e processamento dos pontos de entrada do MVC
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/

User Function AOMS107M()

Local _aParam		:= ParamIXB
Local _xRet			:= .T.
Local _oObj			:= ''
Local _oModel		:= Nil
Local _oModelMAS	:= Nil
Local _cIdPonto		:= ''
Local _cIdModel		:= ''
Local _nOper		:= 0

If _aParam <> NIL

	_oObj		:= _aParam[01]
	_cIdPonto	:= _aParam[02]
	_cIdModel	:= _aParam[03]
	_nOper		:= _oObj:GetOperation()
	
	Begin Sequence
	
	//Validação total do modelo
	If _cIdPonto == 'MODELPOS'
	
		_oModel 		:= FWModelActive()
		_oModelMAS 	:= _oModel:GetModel('ZGQMASTER')
					
	EndIf
		
	//Gravação de log
	If _cIdPonto == 'MODELPOS'
	
		_oModel 	:= FWModelActive()
		_oModelMAS 	:= _oModel:GetModel('ZGQMASTER')
		
		//Inclusão
		If _nOper == 3
		   RecLock("ZGR",.T.)
		   ZGR->ZGR_FILIAL := xFilial("ZGR")
		   ZGR->ZGR_ITEM   := _oModelMAS:GetValue("ZGQ_ITEM")
		   ZGR->ZGR_DATA   := Date()
		   ZGR->ZGR_HORA   := Time()
		   ZGR->ZGR_USER := cUserName
		   ZGR->ZGR_OPLOG  := _oModelMAS:GetValue("ZGQ_OPLOG")
		   ZGR->ZGR_REDE   := _oModelMAS:GetValue("ZGQ_REDE")
		   ZGR->ZGR_CLIENT := _oModelMAS:GetValue("ZGQ_CLIENT")
		   ZGR->ZGR_LOJA   := _oModelMAS:GetValue("ZGQ_LOJA")
		   ZGR->ZGR_TABPRE := _oModelMAS:GetValue("ZGQ_TABPRE")
		   ZGR->ZGR_FILEMB := _oModelMAS:GetValue("ZGQ_FILEMB") 
		   ZGR->ZGR_FILFAT := _oModelMAS:GetValue("ZGQ_FILFAT")
		   ZGR->ZGR_VENDED := _oModelMAS:GetValue("ZGQ_VENDED") 
		   ZGR->ZGR_GEREN  := _oModelMAS:GetValue("ZGQ_GEREN") 
		   ZGR->ZGR_COORDE := _oModelMAS:GetValue("ZGQ_COORDE")
		   ZGR->ZGR_SUPERV := _oModelMAS:GetValue("ZGQ_SUPERV")
		   ZGR->ZGR_RECNO  := ZGQ->(Recno())
						
		   ZGR->(MSUnLock())	
		EndIf
		
		//Alteração
		If _nOper == 4
		   
		   _nposi := ZGQ->(Recno())
		   ZGQ->(DBSetOrder(3)) //ZGQ_CLIENT+ZGQ_LOJA+ZGQ_ITEM
				
		    ZGR->(RecLock("ZGR",.T.))
		   ZGR->ZGR_FILIAL := xFilial("ZGR")
		   ZGR->ZGR_ITEM   := _oModelMAS:GetValue("ZGQ_ITEM")
		   ZGR->ZGR_DATA   := Date()
		   ZGR->ZGR_HORA   := Time()
		   ZGR->ZGR_USER := cUserName
		   ZGR->ZGR_FILIAL := xFilial("ZGR")
		   ZGR->ZGR_ITEM   := _oModelMAS:GetValue("ZGQ_ITEM")
		   ZGR->ZGR_DATA   := Date()
		   ZGR->ZGR_HORA   := Time()
		   ZGR->ZGR_OPLOG  := _oModelMAS:GetValue("ZGQ_OPLOG")
		   ZGR->ZGR_REDE   := _oModelMAS:GetValue("ZGQ_REDE")
		   ZGR->ZGR_CLIENT := _oModelMAS:GetValue("ZGQ_CLIENT")
		   ZGR->ZGR_LOJA   := _oModelMAS:GetValue("ZGQ_LOJA")
		   ZGR->ZGR_TABPRE := _oModelMAS:GetValue("ZGQ_TABPRE")
		   ZGR->ZGR_FILEMB := _oModelMAS:GetValue("ZGQ_FILEMB") //_oModelMAS:GetValue("ZGQ_FILEMB")
		   ZGR->ZGR_FILFAT := _oModelMAS:GetValue("ZGQ_FILFAT")
		   ZGR->ZGR_VENDED := _oModelMAS:GetValue("ZGQ_VENDED") 
		   ZGR->ZGR_GEREN  := _oModelMAS:GetValue("ZGQ_GEREN") 
		   ZGR->ZGR_COORDE := _oModelMAS:GetValue("ZGQ_COORDE")
		   ZGR->ZGR_SUPERV := _oModelMAS:GetValue("ZGQ_SUPERV")
	
		   If ZGQ->(DBSeek(_oModelMAS:GetValue("ZGQ_FILEMB")+_oModelMAS:GetValue("ZGQ_ITEM")))

			  ZGR->ZGR_OREDE  := ZGQ->ZGQ_REDE
			  ZGR->ZGR_OCLIEN := ZGQ->ZGQ_CLIENT
		      ZGR->ZGR_OLOJA  := ZGQ->ZGQ_LOJA
			  ZGR->ZGR_OTABPR := ZGQ->ZGQ_TABPRE
			  ZGR->ZGR_OFILEM := ZGQ->ZGQ_FILEMB
			  ZGR->ZGR_OFILFA := ZGQ->ZGQ_FILFAT
			  ZGR->ZGR_OOPLOG := ZGQ->ZGQ_OPLOG
		      ZGR->ZGR_OVENDE := ZGQ->ZGQ_VENDED
		      ZGR->ZGR_OGEREN := ZGQ->ZGQ_GEREN
		      ZGR->ZGR_OCOORD := ZGQ->ZGQ_COORDE
			  ZGR->ZGR_OSUPER := ZGQ->ZGQ_SUPERV
											
	       EndIf
					
		   ZGR->ZGR_RECNO  := ZGQ->(Recno())
					
		   //mantém posicionamento original do ZGQ
		   ZGQ->(DBGoTo(_nposi))
									
		   ZGR->(MSUnLock())	
		EndIf
		
		//Exclusão
		If _nOper == 5
		
           _nposi := ZGQ->(Recno())
		   ZGQ->(DBSetOrder(3)) //ZGQ_CLIENT+ZGQ_LOJA+ZGQ_ITEM
				
		    ZGR->(RecLock("ZGR",.T.))
		   ZGR->ZGR_FILIAL := xFilial("ZGR")
		   ZGR->ZGR_ITEM   := _oModelMAS:GetValue("ZGQ_ITEM")
		   ZGR->ZGR_TABPRE := _oModelMAS:GetValue("ZGQ_TABPRE")
		   ZGR->ZGR_CLIENT := _oModelMAS:GetValue("ZGQ_CLIENT")
		   ZGR->ZGR_LOJA   := _oModelMAS:GetValue("ZGQ_LOJA")
		   ZGR->ZGR_REDE   := _oModelMAS:GetValue("ZGQ_REDE")
		   ZGR->ZGR_DATA   := Date()
		   ZGR->ZGR_HORA   := Time()
		   ZGR->ZGR_USER := cUserName
		   ZGR->ZGR_OPLOG  := _oModelMAS:GetValue("ZGQ_OPLOG")
		   ZGR->ZGR_REDE   := _oModelMAS:GetValue("ZGQ_REDE")
		   ZGR->ZGR_CLIENT := _oModelMAS:GetValue("ZGQ_CLIENT")
		   ZGR->ZGR_LOJA   := _oModelMAS:GetValue("ZGQ_LOJA")
		   ZGR->ZGR_TABPRE := _oModelMAS:GetValue("ZGQ_TABPRE")
		   ZGR->ZGR_FILEMB := _oModelMAS:GetValue("ZGQ_FILEMB") 
		   ZGR->ZGR_FILFAT := _oModelMAS:GetValue("ZGQ_FILFAT")
		   ZGR->ZGR_VENDED := _oModelMAS:GetValue("ZGQ_VENDED") 
		   ZGR->ZGR_GEREN  := _oModelMAS:GetValue("ZGQ_GEREN") 
		   ZGR->ZGR_COORDE := _oModelMAS:GetValue("ZGQ_COORDE")
		   ZGR->ZGR_SUPERV := _oModelMAS:GetValue("ZGQ_SUPERV")
		   ZGR->ZGR_STATUS := "X"

		   //Se já existe linha no ZGQ grava valores antigos
		   
		   If ZGQ->(DBSeek(_oModelMAS:GetValue("ZGQ_FILEMB")+_oModelMAS:GetValue("ZGQ_ITEM")))

			  ZGR->ZGR_OREDE  := ZGQ->ZGQ_REDE
			  ZGR->ZGR_OCLIEN := ZGQ->ZGQ_CLIENT
		      ZGR->ZGR_OLOJA  := ZGQ->ZGQ_LOJA
			  ZGR->ZGR_OTABPR := ZGQ->ZGQ_TABPRE
			  ZGR->ZGR_OFILEM := ZGQ->ZGQ_FILEMB
		      ZGR->ZGR_OFILFA := ZGQ->ZGQ_FILFAT
		      ZGR->ZGR_OOPLOG := ZGQ->ZGQ_OPLOG
			  ZGR->ZGR_OVENDE := ZGQ->ZGQ_VENDED
	          ZGR->ZGR_OGEREN := ZGQ->ZGQ_GEREN
			  ZGR->ZGR_OCOORD := ZGQ->ZGQ_COORDE
			  ZGR->ZGR_OSUPER := ZGQ->ZGQ_SUPERV
												
	       EndIf
				
		   ZGR->ZGR_RECNO  := ZGQ->(Recno())
					
		   //mantém posicionamento original do ZGQ
		   ZGQ->(DBGoTo(_nposi))
									
		   ZGR->(MSUnLock())
			
		EndIf
	
	EndIf
		
	End Sequence
	
EndIf
	
Return( _xRet )


/*
===============================================================================================================================
Programa----------: AOMS107V
Autor-------------: Josué Danich Prestes
Data da Criacao---: 29/03/2018
===============================================================================================================================
Descrição---------: Valida campo ZGQ_FILEMB
===============================================================================================================================
Parametros--------: _ccampo - Se está validando cliente ou rede
===============================================================================================================================
Retorno-----------: lRet - indica se campo foi validado
===============================================================================================================================
*/

User Function AOMS107V(_ccampo)  

Local _lRet := .T.
Local _cQuery := ""
Local _oModel 		:= FWModelActive()
Local _oModelMAS 	:= _oModel:GetModel('ZGQMASTER')

_cQuery := " SELECT COUNT(ZGQ_TABPRE) CONT"
_cQuery += " FROM "+ RetSqlName("ZGQ") + " WHERE "  

_cQuery += " D_E_L_E_T_ = ' ' AND ZGQ_FILEMB = '" + AllTrim(_oModelMAS:GetValue("ZGQ_FILEMB")) + "'"
		
If Select("ZGQT") > 0
		
	DBSelectArea("ZGQT")
	ZGQT->(DBCloseArea())
			
EndIf
		
DBUseArea( .T. , "TOPCONN" , TCGenQry(,,_cQuery) , "ZGQT" , .T. , .F. )
	
If !(ZGQT->(Eof())) .And. ZGQT->CONT > 0

	Help( ,, 'Atenção!',, "Já existe cadastro para essa filial de embarque!" ,1, 0,, ,,, , {"Utilize a função de alteração"} )

	_lRet := .F.
	
EndIf

Return _lRet

/*
===============================================================================================================================
Programa----------: AOMS107H
Autor-------------: Josué Danich Prestes
Data da Criacao---: 29/03/2018
===============================================================================================================================
Descrição---------: Histórico do cadastro de regras de tabelas de preços
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS107H()
Local _cQuery := ''
Local calias  := GetNextAlias()
Local _alista := {}

If !Pergunte( 'AOMS107' )

	Return

EndIf

//-- Busca histórico na ZGR--//
_cQuery := " SELECT "
_cQuery += "     ZGR_FILIAL,ZGR_DATA,ZGR_HORA,ZGR_USER,ZGR_STATUS,ZGR_ITEM,ZGR_OPLOG,ZGR_REDE,ZGR_CLIENT,ZGR_LOJA,ZGR_OOPLOG,ZGR_OVENDE,ZGR_OGEREN,ZGR_OCOORD,ZGR_OSUPER,"
_cQuery += "     ZGR_TABPRE,ZGR_FILEMB,ZGR_FILFAT,ZGR_VENDED,ZGR_GEREN,ZGR_COORDE,ZGR_SUPERV,ZGR_OREDE,ZGR_OCLIEN,ZGR_OLOJA,ZGR_OTABPR,ZGR_OFILEM,ZGR_OFILFA,ZGR_RECNO"
_cQuery += " FROM "+ RetSqlName("ZGR") +" ZGR "
_cQuery += " WHERE "
_cQuery += " ZGR.D_E_L_E_T_	= ' ' "
_cQuery += " AND	ZGR.ZGR_DATA	>= '"+ DToS(MV_PAR01) +"' "
_cQuery += " AND	ZGR.ZGR_DATA	<= '"+ DToS(MV_PAR02) +"' "

_cQuery += " ORDER BY ZGR_TABPRE,ZGR_ITEM,ZGR_DATA,ZGR_HORA"

If Select(cAlias) > 0
	(cAlias)->( DBCloseArea() )
EndIf

DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQuery) , cAlias , .T. , .F. )

DBSelectArea(cAlias)
(cAlias)->( DBGoTop() )

While  (cAlias)->(!Eof()) 

	aAdd(_alista,{  SToD((cAlias)->ZGR_DATA),;
					AllTrim((cAlias)->ZGR_HORA),;
					AllTrim((cAlias)->ZGR_USER),;
					AllTrim((cAlias)->ZGR_FILEMB),;
					AllTrim((cAlias)->ZGR_ITEM),;
					(cAlias)->ZGR_OCLIEN + "/" + (cAlias)->ZGR_OLOJA,;
					(cAlias)->ZGR_CLIENT + "/" + (cAlias)->ZGR_LOJA,;
					(cAlias)->ZGR_OREDE,;
					(cAlias)->ZGR_REDE,;
					AllTrim((cAlias)->ZGR_OTABPR),;
					AllTrim((cAlias)->ZGR_TABPRE),;
					AllTrim((cAlias)->ZGR_OOPLOG),;
					AllTrim((cAlias)->ZGR_OPLOG),;
					AllTrim((cAlias)->ZGR_OFILFA),;
					AllTrim((cAlias)->ZGR_FILFAT),;
					AllTrim((cAlias)->ZGR_OVENDE),;
					AllTrim((cAlias)->ZGR_VENDED),;
					AllTrim((cAlias)->ZGR_OGEREN),;
					AllTrim((cAlias)->ZGR_GEREN ),;
					AllTrim((cAlias)->ZGR_OCOORDE),;
					AllTrim((cAlias)->ZGR_COORDE ),;
					AllTrim((cAlias)->ZGR_OSUPER),;
					AllTrim((cAlias)->ZGR_SUPERV ),;
					If(!Empty((cAlias)->ZGR_STATUS),"DELETADO","ATIVO") })

	(cAlias)->( DBSkip() )
	
EndDo

If Len(_alista) > 0

   U_ITListBox( "Histórico de Alterações - Data de " + DToC(MV_PAR01) + " até " + DToC(MV_PAR02) + "." ,;
  				{'Data','Hora','Usuário','Filial emb','Item','Cliente ori','Cliente alt', 'Rede ori', 'Rede alt','Tab ori','Tab alt','Op log ori','Op log alt','Fil fat ori','Fil fat alt','Vend ori','Vend alt','Ger ori','Ger alt','Coor ori','Coor alt','Sup ori','Sup alt','Situação'} ,;
  				 _alista , .F. , 1 )

Else

	U_ITMsg("Não foram localizados históricos com os parâmetros indicados","Atenção",,1)
	
EndIf

If Select(cAlias) > 0
   (cAlias)->( DBCloseArea() )
EndIf

Return

/*
===============================================================================================================================
Programa--------: AOMS107R
Autor-----------: Josué Danich Prestes
Data da Criacao-: 29/03/2018
===============================================================================================================================
Descrição-------: Retorna identificação da regra de tabela de preços
===============================================================================================================================
Parametros------: _nrec - recno do registro da regra de tabela de preços
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function AOMS107R(_nrec)

Local _cret := ""
Default _nrec := 0

If _nrec > 0

	ZGQ->(DBGoTo(_nrec))
	
	If !ZGQ->(Eof())
	
		_cret := "Filial embarque: " + ZGQ->ZGQ_FILEMB + " /  Item: " + ZGQ->ZGQ_ITEM
		
	EndIf
	
EndIf

Return _cret

/*
===============================================================================================================================
Programa--------: AOMS107F
Autor-----------: Julio de Paula Paz
Data da Criacao-: 08/11/2021
===============================================================================================================================
Descrição-------: Retorna os códigos: Vendedor, Supervisor, Coordenador e Gerente, da linha posicionada, digitados na tela
                  do MVC.
===============================================================================================================================
Parametros------: Nenhum 
===============================================================================================================================
Retorno---------: aRet = Array com os códigos {"Vendedor",;
                                               "Supervisor",;
											   "Coordenador",;
											   "Gerente"}
===============================================================================================================================
*/
User Function AOMS107F()
Local _oModel, _oModelMAS//, _oModelDET
Local _cCodVend, _cCodSup, _cCodCoord, _cCodGer 

Begin Sequence 

   _oModel    := FWModelActive()
   _oModelMAS := _oModel:GetModel('ZGQMASTER')
      
   _cCodVend  := _oModelMAS:GetValue("ZGQ_VENDED")
   _cCodSup   := _oModelMAS:GetValue("ZGQ_SUPERV")
   _cCodCoord := _oModelMAS:GetValue("ZGQ_COORDE")
   _cCodGer   := _oModelMAS:GetValue("ZGQ_GEREN") 

   _aRet := {_cCodVend, _cCodSup, _cCodCoord, _cCodGer}

End Sequence 

Return _aRet 
/*
===============================================================================================================================
Programa--------: AOMS107
Autor-----------: Julio de Paula Paz
Data da Criacao-: 10/11/2021
===============================================================================================================================
Descrição-------: Consulta genérica de Vendedores/Supervisores/Coordenadores/Gerentes, listando-os uns vinculados com os 
                  Outros
===============================================================================================================================
Parametros------: _cConsulta = Consulta que chamou a rotina.
===============================================================================================================================
Retorno---------: _cRet = Código do representante selecionado.
===============================================================================================================================*/
User Function AOMS107C(_cConsulta)
Local _oDlgSA3
Local _nOpc := 0
Local _cQry 
Local _aEstru := {}

Private aHeader := {}
Private aRotina := {}   
Private _oGetDB    
Private _cOrdPesq := "Codigo", _aOrdPesq := {"Codigo","Nome"}
Private _oDadosPesq, _cDadosPesq := Space(60)

Begin Sequence

   aAdd(aRotina,{"Pesquisar"	,"AxPesqui",0,1})
   aAdd(aRotina,{"Visualizar"	,"AxVisual",0,2})
   aAdd(aRotina,{"Incluir"		,"AxInclui",0,3})
   aAdd(aRotina,{"Alterar"		,"AxAltera",0,4})
   aAdd(aRotina,{"Excluir"		,"AxExclui",0,5})
   Inclui := .F.
   Altera := .T.

   //======================================================
   // Cria a tabela temporária
   //======================================================
   If Select("TRBSA3") > 0
	  TRBSA3->( DBCloseArea() )
   EndIf

   aAdd( _aEstru , { "A3_COD"  , 'C' , 06 , 0 } )
   aAdd( _aEstru , { "A3_NOME" , 'C' , 60 , 0 } )
   aAdd( _aEstru , { "A3_RECNO", 'N' , 10 , 0 } )
      
   _otemp := FWTemporaryTable():New( "TRBSA3", _aEstru )

   _otemp:AddIndex( "01", {"A3_COD"}  )
   _otemp:AddIndex( "02", {"A3_NOME"} )

   _otemp:Create()
      
   //=====================================================
   _aCodigos := U_AOMS107F()
   _cCodVend  := _aCodigos[1]
   _cCodSup   := _aCodigos[2]
   _cCodCoord := _aCodigos[3]
   _cCodGer   := _aCodigos[4]

   _cQry := " SELECT A3_COD, A3_NOME, SA3.R_E_C_N_O_ RECNO"
   _cQry += " FROM "+RETSQLNAME("SA3") + " SA3 "
   _cQry += " WHERE SA3.D_E_L_E_T_ = ' ' AND A3_MSBLQL = '2' "
 
   _cTitulo := "Consulta Representantes"

   If _cConsulta == "MVCVEN"
      _cTitulo := "Consulta Vendedores"

      _cQry += " AND SA3.A3_I_TIPV = 'V' "
      
	  If ! Empty(_cCodSup)
         _cQry += " AND SA3.A3_I_SUPE = '" + _cCodSup + "' "
      EndIf 
	  
	  If ! Empty(_cCodCoord)
         _cQry += " AND SA3.A3_SUPER = '" + _cCodCoord + "' " 
      EndIf 
	  
	  If ! Empty(_cCodGer)
         _cQry += " AND SA3.A3_GEREN = '" + _cCodGer + "' "
      EndIf 

   ElseIf _cConsulta == "MVCSUP"
      _cTitulo := "Consulta Supervisores"

      _cQry += " AND SA3.A3_I_TIPV = 'S' "

	  If ! Empty(_cCodCoord)
         _cQry += " AND SA3.A3_SUPER = '" + _cCodCoord + "' " 
      EndIf 
	  
	  If ! Empty(_cCodGer)
         _cQry += " AND SA3.A3_GEREN = '" + _cCodGer + "' "
      EndIf 

   ElseIf _cConsulta == "MVCCOO"
      _cTitulo := "Consulta Coordenadores"

      _cQry += " AND SA3.A3_I_TIPV = 'C' "

	  If ! Empty(_cCodGer)
         _cQry += " AND SA3.A3_GEREN = '" + _cCodGer + "' "
      EndIf 

   ElseIf _cConsulta == "MVCGER"
      _cTitulo := "Consulta Gerentes"

      _cQry += " AND SA3.A3_I_TIPV = 'G' "
   EndIf 

   If Select("QRYSA3") > 0
	  QRYSA3->( DBCloseArea() )
   EndIf
		
   DBUseArea( .T. , "TOPCONN" , TCGenQry(,,_cQry) , "QRYSA3" , .F. , .T. )
		
   QRYSA3->( DBGoTop() )
   While QRYSA3->(!Eof())
      TRBSA3->(DbAppend())	
      TRBSA3->A3_COD   := QRYSA3->A3_COD 
      TRBSA3->A3_NOME  := QRYSA3->A3_NOME 
	  TRBSA3->A3_RECNO := QRYSA3->RECNO
	  TRBSA3->(MSUnLock())

	  QRYSA3->( DBSkip() )
   EndDo
		
   QRYSA3->( DBCloseArea() )

   //======================================================
   // Monta o AHeader para o MSGETDB.
   //======================================================
   // aAdd(aHeader,{trim(x3_titulo),x3_campo,x3_picture,x3_tamanho,x3_decimal,x3_valid,x3_usado,x3_tipo, x3_f3,x3_context,	x3_cbox,x3_relacao,x3_when,X3_TRIGGER,	X3_PICTVAR,.F.,.F.})
   aAdd(aHeader,{"Codigo"                              ,;   // 1  = X3_TITULO                   
                 "A3_COD"                              ,;   // 2  = X3_CAMPO
                 ""                                    ,;   // 3  = X3_PICTURE                    
                 6                                     ,;   // 4  = X3_TAMANHO            
                 0                                     ,;   // 5  = X3_DECIMAL
                 ""                                    ,;   // 6  = X3_VALID                 
                                                     "",;   // 7  = X3_USADO
                 "C"                                   ,;   // 8  = X3_TIPO                   
                                                     "",;   // 9  = X3_CONTEXT
                 ""})                                       // 10 = X3_CBOX

   aAdd(aHeader,{"Nome"                                ,;   // 1  = X3_TITULO                   
                 "A3_NOME"                             ,;   // 2  = X3_CAMPO
                 ""                                    ,;   // 3  = X3_PICTURE                    
                 60                                     ,;  // 4  = X3_TAMANHO            
                 0                                     ,;   // 5  = X3_DECIMAL
                 ""                                    ,;   // 6  = X3_VALID                 
                                                     "",;   // 7  = X3_USADO
                 "C"                                   ,;   // 8  = X3_TIPO                   
                                                     "",;   // 9  = X3_CONTEXT
                 ""})                                       // 10 = X3_CBOX

    TRBSA3->(DBGoTop())

	DEFINE MSDIALOG _oDlgSA3 TITLE _cTitulo FROM 00,00 To 400, 620 PIXEL                                    
        @ 05, 05  BUTTON _OButtonApr PROMPT "&Ok"	        SIZE 50, 012 OF _oDlgSA3 ACTION (_nOpc := 1 , _oDlgSA3:End()) PIXEL
        @ 05, 60  BUTTON _OButtonRej PROMPT "&Cancelar"     SIZE 50, 012 OF _oDlgSA3 ACTION (_nOpc := 0 , _oDlgSA3:End()) PIXEL
        @ 05, 115 BUTTON _OButtonGrv PROMPT "&Pesquisar"    SIZE 50, 012 OF _oDlgSA3 ACTION ( U_AOMS107P()) PIXEL
		@ 05, 170 ComboBox _cOrdPesq  Items _aOrdPesq       SIZE 40, 012 OF _oDlgSA3 PIXEL
		@ 05, 215 MsGet	   _oDadosPesq	Var _cDadosPesq    	SIZE 90, 012 OF _oDlgSA3 PIXEL Picture "@!"

       //_oGetDB := MsGetDB():New (_aPosObj[1,1], _aPosObj[1,2], _aPosObj[2,3], _aPosObj[2,4], 4    , "Allwaystrue" , "Allwaystrue", ""         , .F.       , {"ZGZ_SITUAC","ZGZ_OBSERV"} , 0         , .F.       ,        , "TRBZGZ", "", , .F., _oDlgSA3, .T., ,"", "")
                //MsGetDB():New ( < nTop>, < nLeft>, < nBottom> , < nRight> ,< nOpc>, [ cLinhaOk]    , [ cTudoOk]     ,[ cIniCpos], [ lDelete], [ aAlter], [ nFreeze], [ lEmpty], [ uPar1], < cTRB>  , [ cFieldOk]    , [ uPar2], [ lAppend], [ oWnd] , [ lDisparos], [ uPar3], [ cDelOk], [ cSuperDel] ) --> oObj
       _oGetDB := MsGetDB():New (20      ,0        , 190        , 270       , 4     , "Eval({||.T.})", "Eval({||.T.})", ""        , .F.       , {}       , 0         , .F.      ,         , "TRBSA3" , "Eval({||.T.})",         , .F.       , _oDlgSA3, .F.        ,          ,""        , "")
       _oGetDB:oBrowse:bAdd := {||.F.} // não inclui novos itens MsGetDb()
       _oGetDB:Enable( ) 

       TRBSA3->(DBGoTop())
       _oGetDB:ForceRefresh ( )

    ACTIVATE MSDIALOG _oDlgSA3 CENTERED

	If _nOpc == 1
	   If TRBSA3->(Eof()) .Or. TRBSA3->(Bof())
          _cMvcRet := Space(6)
	   Else 
          SA3->(DBGoTo(TRBSA3->A3_RECNO))
	      _cMvcRet := SA3->A3_COD 
	   EndIf 
	Else 
	   _cMvcRet := Space(6) 
	EndIf

End Sequence

If Select("TRBSA3") > 0
   TRBSA3->( DBCloseArea() )
EndIf

Return .T. 

/*
===============================================================================================================================
Programa--------: AOMS10P
Autor-----------: Julio de Paula Paz
Data da Criacao-: 10/11/2021
===============================================================================================================================
Descrição-------: Consulta genérica de Vendedores/Supervisores/Coordenadores/Gerentes, listando-os uns vinculados com os 
                  Outros
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum 
===============================================================================================================================*/
User Function AOMS107P()
Local _nRegAtu := TRBSA3->(Recno())

Begin Sequence

   If AllTrim(_cOrdPesq)  == AllTrim(_aOrdPesq[1])
      TRBSA3->(DBSetOrder(1)) 
   Else
	  TRBSA3->(DBSetOrder(2)) 
   EndIf    
   
   If ! Empty(_cDadosPesq)
      If ! TRBSA3->(MsSeek(AllTrim(_cDadosPesq)))
         TRBSA3->(DBGoTo(_nRegAtu))
      EndIf 
   EndIf
   
   _oGetDB:oBrowse:Refresh()

End Sequence 

Return 

/*
===============================================================================================================================
Programa----------: AOMS107W
Autor-------------: Julio de Paula Paz
Data da Criacao---: 18/11/2021
===============================================================================================================================
Descrição---------: Pós validação dos dados.
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: lRet - indica se campo foi validado.
===============================================================================================================================
*/
User Function AOMS107W()  
Local _lRet := .T.
Local _cCodVend, _cCodSup, _cCodCoord, _cCodGer 
Local _oModel, _oModelMAS, _cRede, _cCliente, _cLoja

Begin Sequence
   _oModel    := FWModelActive()
   _oModelMAS := _oModel:GetModel('ZGQMASTER')
      
   _cCodVend  := _oModelMAS:GetValue("ZGQ_VENDED")
   _cCodSup   := _oModelMAS:GetValue("ZGQ_SUPERV")
   _cCodCoord := _oModelMAS:GetValue("ZGQ_COORDE")
   _cCodGer   := _oModelMAS:GetValue("ZGQ_GEREN") 
   _cRede     := _oModelMAS:GetValue("ZGQ_REDE") 
   _cCliente  := _oModelMAS:GetValue("ZGQ_CLIENT") 
   _cLoja     := _oModelMAS:GetValue("ZGQ_LOJA") 

   If Empty(_cCodVend) .And. Empty(_cCodSup) .And. Empty(_cCodCoord) .And. Empty(_cCodGer ) .And. Empty(_cRede) .And. Empty(_cCliente) .And. Empty(_cLoja)
      Help( ,, 'Atenção!',, "Os campos Gerente, Coordenador, Supervisor, Vendedor, Rede, Cliente e Loja estão vazios!" ,1, 0,, ,,, , {"Preencha pelo menos um dos campos."} )
	  _lRet := .F.
   EndIf 

End Sequence

Return _lRet 
