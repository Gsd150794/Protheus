/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
André Lisboa  |23/08/2017| Chamado 20782. Incluida chamada a rotina de logs e correções para a V12
Alex Wallauer |22/03/2019| Chamado 28571. Ajustes/Adaptações para versão Lobo Guara.
Lucas Borges  |18/09/2019| Chamado 28346. Revisão do fonte
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: AGPE006
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 13/12/2016
Descrição---------: Rotina desenvolvida para atualizar os campos da pasta Contabilização do cadastro de Verbas.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGPE006()


Private cCadastro	:= "Cadastro de Verbas"
Private aRotina		:= MenuDef()
Private cAlias		:= "SRV"

mBrowse( 6, 1,22,75,cAlias,,,,,,)

Return

/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 18/09/2019
Descrição---------: Utilizacao de Menu Funcional
Parametros--------: aRotina
					1. Nome a aparecer no cabecalho
					2. Nome da Rotina associada
					3. Reservado
					4. Tipo de Transa‡„o a ser efetuada:
						1 - Pesquisa e Posiciona em um Banco de Dados
						2 - Simplesmente Mostra os Campos
						3 - Inclui registros no Bancos de Dados
						4 - Altera o registro corrente
						5 - Remove o registro corrente do Banco de Dados
					5. Nivel de acesso
					6. Habilita Menu Funcional
Retorno-----------: Array com opcoes da rotina
===============================================================================================================================
*/
Static Function MenuDef()

Local aRotina := {	{ "Pesquisar"		, "AxPesqui" 		, 0 , 1 } ,;
					{ "Visualizar"		, "AxVisual" 		, 0 , 2 } ,;
					{ "Alterar"			, "U_AGPE006L" 		, 0 , 4 } }

Return( aRotina )

/*
===============================================================================================================================
Programa----------: AGPE006L
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 13/06/2017
Descrição---------: Função para abertura do registro de verba, para informar os campos contidos na pasta Contabilização
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGPE006L()

Local _aArea		:= FWGetArea()
Local _nRecno		:= SRV->(Recno())
Local _aButtons		:= {}
Local _aFields		:= {}
Local _aAlterFields	:= {}
Local _nOpc			:= 0
Local _nX			:= 0
Local aPosObj   	:= {}
Local aObjects  	:= {}
Local aSize     	:= MsAdvSize()
Local _aRotBkp		:= aClone(aRotina)
Local nUsado        := 0

Private _oEnchoic1
Private _oDlg

_aSRV := SRV->(DBSTRUCT())
// Populo o array com os campos para alteração
For nUsado := 1 To Len(_aSRV)
    _cCampo:=_aSRV[nUsado][1]
    If GetSX3Cache(_cCampo,"X3_FOLDER") = "2"   
	   aAdd( _aAlterFields , _cCampo )
	EndIf
Next nUsado

_aFields := nil//Não precisa de vai mostrar todos é só passar nil

DBSelectArea("SRV")
SRV->(DBGoTo(_nRecno))

// aRotina padrão
aRotina :=	{	{ "Pesquisar"	, "PesqBrw"	  		, 0 , 1,,.F. } ,;	//"Pesquisar"
				{ "Visualizar"	, "AxVisual"		, 0 , 2 } ,;		//"Visualizar"
				{ "Incluir"		, "GP040Inc"		, 0 , 3 } ,;		//"Incluir"
				{ "Alterar"		, "GP040Alt"		, 0 , 4 } ,;		//"Alterar"
				{ "Excluir"		, "Gpea040ChkDel"	, 0 , 5 }  ;		//"Excluir"
			}

aAdd( aObjects, { 100, 052, .T., .T. } )
aAdd( aObjects, { 100, 048, .T., .F. } )

aInfo   := { aSize[ 1 ] , aSize[ 2 ] , aSize[ 3 ] , aSize[ 4 ] , 3 , 2 }
aPosObj := MsObjSize( aInfo , aObjects )

DEFINE MSDIALOG _oDlg TITLE "Cadastro de Verbas" FROM aSize[7],00 to aSize[6],aSize[5] COLORS 0, 16777215 PIXEL

	RegToMemory("SRV", .F., .F.)
	_oEnchoic1 := MsMGet():New("SRV",0,4,,,,_aFields,{,,,},_aAlterFields,,,,,_oDlg,,.T.)
	_oEnchoic1:oBox:align := CONTROL_ALIGN_ALLCLIENT

ACTIVATE MSDIALOG _oDlg CENTERED ON INIT EnchoiceBar(_oDlg, {|| (_nOpc := 1, _oDlg:End()) }, {|| _oDlg:End() },,_aButtons)

If _nOpc == 1
	
	For _nX := 1 To Len(_aAlterFields)
		RecLock("SRV", .F.)
			&("SRV->" + _aAlterFields[_nX]) := &("M->" + _aAlterFields[_nX])
		MSUnLock()
	Next _nX

EndIf

U_ITLOGACS('AGPE006')
aRotina := aClone(_aRotBkp)

FWRestArea(_aArea)
Return
