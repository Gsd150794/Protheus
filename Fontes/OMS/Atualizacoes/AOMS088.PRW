/*
===============================================================================================================================
                          ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
       Autor      |    Data    |                                             Motivo                                          
-------------------------------------------------------------------------------------------------------------------------------
 Josué Danich     | 29/10/2018 | Revisão para novos padrões de fonte Totvs - Chamado 26728
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges      | 14/10/2019 | Removidos os Warning na compilação da release 12.1.25. Chamado 28346
===============================================================================================================================
*/

//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================
#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: AOMS088
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 13/12/2016
===============================================================================================================================
Descrição---------: Rotina desenvolvida para atualizar os campos da pasta logística do cadastro de clientes. Chamado 17985
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS088()

Private cCadastro	:= "Cadastro de Clientes - Logística"
Private aRotina		:= MenuDef()   
Private aObjects    := {} 
Private ainfo       := {}
Private aPosObj     := {}   
Private aSize       := MsAdvSize()         

aAdd( aObjects, { 100, 052, .T., .T. } )
aAdd( aObjects, { 100, 048, .T., .F. } )

aInfo   := { aSize[ 1 ] , aSize[ 2 ] , aSize[ 3 ] , aSize[ 4 ] , 3 , 2 }
aPosObj := MsObjSize( aInfo , aObjects )

SA1->(DBSetOrder(1))
mBrowse(6,1,22,75,"SA1")

Return

/*
===============================================================================================================================
Programa----------: AOMS088L
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 13/12/2016
===============================================================================================================================
Descrição---------: Função para abertura do registro de cliente, para informar os campos Zona de Restrição TRT, Chapa do 
------------------: Cliente, Shelf Life do Produto e Quarentena Mínima. Chamado 17985
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS088L()

Local _aButtons		:= {}
Local _aFields		:= {}
Local _aAlterFields	:= {}
Local _nOpc			:= 0
Local _aRotBkp		:= aClone(aRotina)
Local _ccampos := u_itgetmv("IT_CMPLG","A1_I_CCHEP;A1_I_PALET;A1_I_CHEP;A1_I_AGEND;A1_I_HORP;A1_I_TIPCA;A1_I_CHAPA;A1_I_GERMU;A1_I_DESCA;A1_I_TPEQP;A1_I_TXDIF;A1_I_DNRDC;A1_I_ZRTRT;A1_I_SHLFP;A1_I_QUAMI")

Private _oEnchoic1
Private _oDlg

// Populo o array com os campos para alteração
FillGetDados(1,"SA1",1,,,{||.T.},,,,,,.T.)

_nni := 1

While _nni <= Len (aheader)
	
	aAdd( _aFields , AllTrim(aheader[_nni][2]) )
	
	If AllTrim(aheader[_nni][2]) $ _ccampos
	
		aAdd( _aAlterFields , AllTrim(aheader[_nni][2]) )
		
	EndIf
	
	_nni++

EndDo


aRotina := { {"Pesquisar"		,"PesqBrw"		, 0 , 1,0	,.F.}}	// "Pesquisar"
aAdd(aRotina,{"Visualizar"		,"A030Visual"	, 0 , 2,0	,NIL})	// "Visualizar"
aAdd(aRotina,{"Incluir"			,"A030Inclui"	, 0 , 3,0	,NIL})	// "Incluir"
aAdd(aRotina,{"Alterar"			,"A030Altera"	, 0 , 4,143	,NIL})	// "Alterar"
aAdd(aRotina,{"Excluir"			,"A030Deleta"	, 0 , 5,144	,NIL})	// "Excluir"
aAdd(aRotina,{"Contatos"		,"FtContato"	, 0 , 4,0	,NIL})	// "Contatos"
aAdd(aRotina,{"Conhecimento"	,"MsDocument"	, 0 , 4,0	,NIL})	// "Conhecimento"
aAdd(aRotina,{"Referencias"		,"Mata030Ref"	, 0 , 3,0	,NIL})	// "Referencias"

DEFINE MSDIALOG _oDlg TITLE "Cadastro de Clientes - Logística" FROM aSize[7],00 to aSize[6],aSize[5] COLORS 0, 16777215 Of oMainWnd PIXEL

	RegToMemory("SA1", .F., .F.)
	_oEnchoic1 := MsMGet():New("SA1",0,4,,,,_aFields,{,,,},_aAlterFields,,,,,_oDlg,,.T.)
	_oEnchoic1:oBox:align := CONTROL_ALIGN_ALLCLIENT

ACTIVATE MSDIALOG _oDlg CENTERED ON INIT EnchoiceBar(_oDlg, {|| (_nOpc := 1, _oDlg:End()) }, {|| _oDlg:End() },,_aButtons)

If _nOpc == 1
	
	FWMsgRun(,{ || U_AOMS088S(_aAlterFields)},"Aguarde...","Gravando registro...")

EndIf

aRotina := aClone(_aRotBkp)

Return

/*
===============================================================================================================================
Programa----------: AOMS088L
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 13/12/2016
===============================================================================================================================
Descrição---------: Função de criação do menu. Chamado 17985
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MenuDef()
Local aRotina := {}

aAdd(aRotina,{"Pesquisar"	,"AxPesqui"		,0,1})
aAdd(aRotina,{"Visualizar"	,"AxVisual"		,0,2})
aAdd(aRotina,{"Logística"	,"FWMsgRun(,{ || U_AOMS088L()},'Aguarde...','Carregando cadastro...')"	,0,4})

Return(aRotina)


/*
===============================================================================================================================
Programa----------: AOMS088S
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 13/12/2016
===============================================================================================================================
Descrição---------: Salva registro da tela
===============================================================================================================================
Parametros--------: _aAlterFields - arry com campos a serem salvos
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS088S(_aAlterFields)

Local _nX := 0

	For _nX := 1 To Len(_aAlterFields)
		RecLock("SA1", .F.)
			&("SA1->" + _aAlterFields[_nX]) := &("M->" + _aAlterFields[_nX])
		MSUnLock()
	Next _nX

Return
