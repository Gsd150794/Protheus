/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |05/04/2022| Chamado 39679. Ajuste para tratar evento temporário do Incentivo à Produção.
Lucas Borges  |24/01/2023| Chamado 42685. Corrigida chamada de SuperGetMV em laço.
Lucas Borges  |11/02/2025| Chamado 49877. Removido tratamento sobre a versão do Mix
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "RWMAKE.CH"
#Include "Colors.ch"

/*
===============================================================================================================================
Programa----------: MGLT027
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 17/01/2011
Descrição---------: Rotina que possibilita gerar o complemento de pagamento a ser pago no Mix Corrente
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MGLT027

Local _aCores     := {}
Local _cAlias     := "ZZE"

Private cCadastro	:= "Complemento de Pagamento - Gera título financeiro"
Private aRotina		:= MenuDef()
Private _nContReg	:= 0
Private _cAliasZL8:= GetNextAlias()
Private _cPrefixo := PadR(SuperGetMv("IT_PREFADI",.F.,"GCO"),TamSX3("E2_PREFIXO")[1])

_aCores := {{"ZZE_STATUS == '1'",'ENABLE'} ,; //INCLUIDO SEM NENHUM REGISTRO TER SIDO EFETIVADO
           {"ZZE_STATUS == '2'",'BR_AZUL'}}   //EFETIVADO POSSUI PELO MENOS UM REGISTRO EFETIVADO, OU SEJA, PASSOU PELA ROTINA DE EFETIVACAO

mBrowse(6,1,22,75,_cAlias,,,,,,_aCores)

Return

/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 08/10/2018
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
						6 - Altera determinados campos sem incluir novos Regs
					5. Nivel de acesso
					6. Habilita Menu Funcional
Retorno-----------: Array com opcoes da rotina
===============================================================================================================================
*/
Static Function MenuDef()

Local aRotina := {	{ "Pesquisar"			, "AxPesqui" 		, 0 , 1 } ,;
					{ "Visualizar"			, "AxVisual" 		, 0 , 2 } ,;
					{ "Incluir"				, "U_MGLT027T(1)" 	, 0 , 3 } ,;
					{ "Alterar"				, "U_MGLT027T(2)" 	, 0 , 4 } ,;
					{ "Excluir"				, "U_MGLT027T(3)"	, 0 , 5 } ,;
					{ "Efetivar"			, "U_MGLT027Z()" 	, 0 , 6 } ,;
					{ "Legenda"				, "U_MGLT027E()" 	, 0 , 7 } ,;
					{ "Dados Complemento"	, "U_AGLT027D()"	, 0 , 8 } }

Return( aRotina )

/*
===============================================================================================================================
Programa----------: MGLT027D
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 17/01/2011
Descrição---------: Possibilita a verificação dos dados por produtor que foram gerados os complementos 
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT027D

//Efetua backup das variaveis aRotina e cCadastro para chamar a nova mbrowse.
Local _aBkRotina    := aRotina
Local _cBkCadast    := cCadastro
Local _cAlias       := "ZZF"
Local _aCores       := {}

Private _cCondicao  := ""
Private cCadastro   := "REGISTROS DO COMPLEMENTO DE PAGAMENTO"
Private aRotina     := {}

_cCondicao  := "ZZF_CODIGO == '" + ZZE->ZZE_CODIGO + "'"

(_cAlias)->(DBSetOrder(1))

set filter to  &(_cCondicao)

aAdd(aRotina,{OemToAnsi("Pesquisar" )        ,'AxPesqui'      ,0,1})
aAdd(aRotina,{OemToAnsi("Visualizar")        ,'AxVisual'      ,0,2})
aAdd(aRotina,{OemToAnsi("Legenda"   )		  ,'U_MGLT027D()'    ,0,3})

_aCores := {	{"ZZF_STATUS == '1'",'ENABLE'} ,;     //INCLUIDO
		   		{"ZZF_STATUS == '2'",'BR_AZUL'},;     //EFETIVADO
	           	{"ZZF_STATUS == '3'",'DISABLE'},;     //CANCELADO
    	       	{"ZZF_STATUS == '4'",'BR_AMARELO'}}   //NAO EFETIVADO DEVIDO A ESTAR EFETIVADO OU FECHADO

mBrowse(6,1,22,75,_cAlias,,,,,,_aCores)

dbClearFilter()

//Restaura as variaveis de controle da mbrowse
aRotina  := _aBkRotina
cCadastro:= _cBkCadast

Return

/*
===============================================================================================================================
Programa----------: MGLT027T
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 17/01/2011
Descrição---------: Tela desenvolvida para possibilitar a realizacoes das operacoes de inclusao,alteracao e exclusao
Parametros--------: _nOperac: 1- Inclusão, 2- Alteração, 3- Exclusão
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MGLT027T(_nOperac)

Local _oCbOperac, _oGLinFin, _oGLinIni
Local _oGLjProdFi, _oGLjProdIn, _oGMixDest
Local _oGMixOrig, _oGProdFin, _oGProdIni
Local _oGProdFora, _oGDtCred, _oGSetor
Local _oGVlrRepor, _oSay1, _oSay10
Local _oSay11, _oSay12, _oSay13, _oSay2
Local _oSay3, _oSay4, _oSay5
Local _oSay6, _oSay7, _oSay8
Local _oSay9, _oSetor, _oGNumero
Local _cDescSet    := IIf(_nOperac == 1,"",Posicione("ZL2",1,xFilial("ZL2") + ZZE->ZZE_SETOR,"ZL2->ZL2_DESCRI"))
Local lInclui      := IIf(_nOperac == 1,.T.,.F.)
Local oFont12b
Private oSDadMixOr, oSDadMixDe
Private _sDtInic,_sDtFin,_sDtDesIni,_sDtDesFin
Private cGSetor    := IIf(_nOperac == 1,Space(GetSX3Cache("ZZE_SETOR","X3_TAMANHO")),ZZE->ZZE_SETOR)
Private cGProdIni  := IIf(_nOperac == 1,Space(GetSX3Cache("ZZE_PROINI","X3_TAMANHO")),ZZE->ZZE_PROINI)
Private cGProdFin  := IIf(_nOperac == 1,Space(GetSX3Cache("ZZE_PROFIN","X3_TAMANHO")),ZZE->ZZE_PROFIN)
Private cGMixOrig  := IIf(_nOperac == 1,Space(GetSX3Cache("ZZE_MIXORI","X3_TAMANHO")),ZZE->ZZE_MIXORI)
Private cGMixDest  := IIf(_nOperac == 1,Space(GetSX3Cache("ZZE_MIXDES","X3_TAMANHO")),ZZE->ZZE_MIXDES)
Private cGLjProdIn := IIf(_nOperac == 1,Space(GetSX3Cache("ZZE_LOJINI","X3_TAMANHO")),ZZE->ZZE_LOJINI)
Private cGLjProdFi := IIf(_nOperac == 1,Space(GetSX3Cache("ZZE_LOJFIN","X3_TAMANHO")),ZZE->ZZE_LOJFIN)
Private cGLinIni   := IIf(_nOperac == 1,Space(GetSX3Cache("ZZE_LININI","X3_TAMANHO")),ZZE->ZZE_LININI)
Private cGLinFin   := IIf(_nOperac == 1,Space(GetSX3Cache("ZZE_LINFIN","X3_TAMANHO")),ZZE->ZZE_LINFIN)
Private cGVlrRepor := IIf(_nOperac == 1,0,ZZE->ZZE_VALOR)
Private cCbOperac  := IIf(_nOperac == 1,'Incluir',IIf(_nOperac == 2,'Alterar','Excluir'))
Private cGNumero   := IIf(_nOperac == 1,GETSXENUM("ZZE","ZZE_CODIGO"),ZZE->ZZE_CODIGO)
Private cGProdFora := IIf(_nOperac == 1,Space(1600),ZZE->ZZE_PROOUT)
Private cGProdFor2 := IIf(_nOperac == 1,Space(1600),ZZE->ZZE_PROOU2)
Private cGDtCred   := IIf(_nOperac == 1,date(),ZZE->ZZE_DTCRED)
Private _cDadMixOr := IIf(_nOperac == 1,"",MGLT027H(ZZE->ZZE_MIXORI,1))
Private _cDadMixDe := IIf(_nOperac == 1,"",MGLT027H(ZZE->ZZE_MIXDES,2))

Static oDlg

Define Font oFont12b   Name "Courier New"       Size 0,-12 Bold  // Tamanho 12 Negrito

DEFINE MSDIALOG oDlg TITLE "COMPLEMENTO DE PAGAMENTO - GERA TÍTULO FINANCEIRO" FROM 000, 000  TO 400, 600 COLORS 0, 16777215 PIXEL

//Comanando para impedir o uso da tecla ESC para fechar a janela
oDlg:LESCCLOSE := .F.

@ 041, 014 Say _oSay11 PROMPT "Numero:" SIZE 040, 008 OF oDlg COLORS 16711680, 16777215 PIXEL
@ 041, 054 MSGET _oGNumero VAR cGNumero SIZE 040, 008 OF oDlg COLORS 0, 16777215 WHEN .F. PIXEL

@ 055, 014 Say _oSay10 PROMPT "Operação:" SIZE 025, 008 OF oDlg COLORS 16711680, 16777215 PIXEL
@ 055, 054 MSCOMBOBOX _oCbOperac VAR cCbOperac ITEMS {"Incluir","Alterar","Excluir"} SIZE 040, 010 OF oDlg COLORS 0, 16777215 PIXEL  WHEN .F.

@ 069, 014 Say _oSay1 PROMPT "Mix de Origem:" SIZE 040, 008 OF oDlg COLORS 16711680, 16777215 PIXEL
@ 069, 054 MSGET _oGMixOrig VAR cGMixOrig SIZE 040, 008 OF oDlg VALID IIf(!Empty(cGMixOrig),MGLT027V(cGMixOrig,1),.T.) COLORS 0, 16777215 F3 "ZLE_01" WHEN lInclui PIXEL
@ 069, 112 Say oSDadMixOr PROMPT _cDadMixOr SIZE 175, 008 OF oDlg COLORS 0, 16777215 FONT oFont12b PIXEL

@ 083, 014 Say _oSay2 PROMPT "Mix de Destino:" SIZE 040, 008 OF oDlg COLORS 16711680, 16777215 PIXEL
@ 083, 054 MSGET _oGMixDest VAR cGMixDest SIZE 040, 008 OF oDlg VALID IIf(!Empty(cGMixDest),MGLT027V(cGMixDest,2),.T.) COLORS 0, 16777215 F3 "ZLE_01" WHEN lInclui PIXEL
@ 083, 112 Say oSDadMixDe PROMPT _cDadMixDe SIZE 175, 008 OF oDlg COLORS 0, 16777215 FONT oFont12b PIXEL

@ 097, 014 Say _oSetor PROMPT "Setor:" SIZE 025, 008 OF oDlg COLORS 16711680, 16777215 PIXEL
@ 097, 054 MSGET _oGSetor VAR cGSetor SIZE 040, 008 OF oDlg VALID IIf(!Empty(cGSetor),IIf(U_VSetor(.T.),Eval({|| _cDescSet:= Posicione("ZL2",1,xFilial("ZL2") + cGSetor,"ZL2->ZL2_DESCRI")},oSDescSet:Refresh()),.F.),.T.) COLORS 0, 16777215 F3 "ZL2_01" WHEN lInclui PIXEL
@ 097, 112 Say oSDescSet PROMPT _cDescSet SIZE 175, 008 OF oDlg COLORS 0, 16777215 FONT oFont12b PIXEL

@ 111, 014 Say _oSay7 PROMPT "Linha Inicial:" SIZE 035, 008 OF oDlg COLORS 0, 16777215 PIXEL
@ 111, 054 MSGET _oGLinIni VAR cGLinIni SIZE 040, 008 OF oDlg VALID IIf(!Empty(cGLinIni) .And. cGLinIni <> 'ZZZZZZ',ExistCpo("ZL3",cGLinIni),.T.) COLORS 0, 16777215 F3 "ZL3_01" WHEN lInclui PIXEL
@ 111, 112 Say _oSay8 PROMPT "Linha Final:" SIZE 029, 008 OF oDlg COLORS 16711680, 16777215 PIXEL
@ 111, 144 MSGET _oGLinFin VAR cGLinFin SIZE 040, 008 OF oDlg VALID IIf(!Empty(cGLinFin) .And. cGLinFin <> 'ZZZZZZ',ExistCpo("ZL3",cGLinFin),.T.) COLORS 0, 16777215 F3 "ZL3_01" WHEN lInclui PIXEL

@ 125, 014 Say _oSay3 PROMPT "Produtor De:" SIZE 034, 008 OF oDlg COLORS 0, 16777215 PIXEL
@ 125, 054 MSGET _oGProdIni VAR cGProdIni SIZE 040, 008 OF oDlg VALID IIf(!Empty(cGProdIni) .And. cGProdIni <> 'ZZZZZZ',ExistCpo("SA2",cGProdIni),.T.) COLORS 0, 16777215 F3 "SA2_L4" WHEN lInclui PIXEL
@ 125, 112 Say _oSay4 PROMPT "Loja De:" SIZE 025, 008 OF oDlg COLORS 0, 16777215 PIXEL
@ 125, 144 MSGET _oGLjProdIn VAR cGLjProdIn SIZE 040, 008 OF oDlg VALID IIf(!Empty(cGProdIni) .And. cGProdIni <> 'ZZZZZZ' .And. !Empty(cGLjProdIn) .And. cGLjProdIn <> 'ZZZZ',ExistCpo("SA2",cGProdIni + cGLjProdIn),.T.) COLORS 0, 16777215 WHEN lInclui PIXEL

@ 139, 014 Say _oSay5 PROMPT "Produtor Ate:" SIZE 034, 008 OF oDlg COLORS 16711680, 16777215 PIXEL
@ 139, 054 MSGET _oGProdFin VAR cGProdFin SIZE 040, 008 OF oDlg VALID IIf(!Empty(cGProdFin) .And. cGProdFin <> 'ZZZZZZ',ExistCpo("SA2",cGProdFin),.T.) COLORS 0, 16777215 F3 "SA2_L4" WHEN lInclui PIXEL
@ 139, 112 Say _oSay6 PROMPT "Loja Ate:" SIZE 034, 008 OF oDlg COLORS 16711680, 16777215 PIXEL
@ 139, 144 MSGET _oGLjProdFi VAR cGLjProdFi SIZE 040, 008 OF oDlg VALID IIf(!Empty(cGProdFin) .And. cGProdFin <> 'ZZZZZZ' .And. !Empty(cGLjProdFi) .And. cGLjProdFi <> 'ZZZZ',ExistCpo("SA2",cGProdFin + cGLjProdFi),.T.) COLORS 0, 16777215 WHEN lInclui PIXEL

@ 153, 014 Say _oSay9 PROMPT "Valor a repor:" SIZE 036, 008 OF oDlg COLORS 16711680, 16777215 PIXEL
@ 153, 054 MSGET _oGVlrRepor VAR cGVlrRepor SIZE 040, 008 OF oDlg PICTURE "@E 99.9999" COLORS 0, 16777215 WHEN IIf(_nOperac == 1 .Or. _nOperac == 2,.T.,.F.) PIXEL
@ 153, 112 Say _oSay12 PROMPT "Data Crédito:" SIZE 036, 008 OF oDlg COLORS 16711680, 16777215 PIXEL
@ 153, 144 MSGET _oGDtCred VAR cGDtCred SIZE 040, 008 OF oDlg COLORS 0, 16777215 WHEN IIf(_nOperac == 1 .Or. _nOperac == 2,.T.,.F.) PIXEL

@ 167, 014 Say _oSay10 PROMPT "Produt.Fora 1:" SIZE 035, 008 OF oDlg COLORS 0, 16777215 PIXEL
@ 167, 054 MSGET _oGProdFora VAR cGProdFora SIZE 231, 008 OF oDlg COLORS 0, 16777215 WHEN lInclui PIXEL

@ 181, 014 Say _oSay13 PROMPT "Produt.Fora 2:" SIZE 035, 008 OF oDlg COLORS 0, 16777215 PIXEL
@ 181, 054 MSGET _oGProdFor2 VAR cGProdFor2 SIZE 231, 008 OF oDlg COLORS 0, 16777215 WHEN lInclui PIXEL

ACTIVATE MSDIALOG oDlg CENTERED ON INIT EnchoiceBar(oDlg,{||nopc:=1,IIf(MGLT027U(),IIf(MGLT027G(),oDlg:End(),),)}, {||nopc:=2,oDlg:End(),RollBackSX8()},,)

Return

/*
===============================================================================================================================
Programa----------: MGLT027V
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 17/01/2011
Descrição---------: Efetua a validacao para verificar o fornecimento correto do Mix de destino e de origem.
Parametros--------: _cCodMIX - Codigo do Mix,
					_cTpMix - 1 == Mix de Origem e 2 == Mix de Destino
Retorno-----------: _lRet - Lógico validando campo de mix
===============================================================================================================================
*/
Static Function MGLT027V(_cCodMIX,_cTpMix)

Local _lRet    	:= .T.
Local _nCountRec:= 0
Private _cAliasZLE := GetNextAlias()

//=========================================
// Chama para funcao filtrar os dado do Mix
//=========================================
MsgRun("Filtrando dados do Mix...",,{||CursorWait(), MGLT027Q(1,_cCodMIX,"","",""), CursorArrow()})
_nCountRec := _nContReg

If _nCountRec > 0

	(_cAliasZLE)->(DBGoTop())

	//Mix de Origem
	If _cTpMix == 1
		_cDadMixOr	:= DToC(SToD((_cAliasZLE)->ZLE_DTINI)) + " = " + DToC(SToD((_cAliasZLE)->ZLE_DTFIM))
		//Armazena a data inicial e final do mix de origem para ser utilizada em query futura
		_sDtInic	:= (_cAliasZLE)->ZLE_DTINI
		_sDtFin		:= (_cAliasZLE)->ZLE_DTFIM
	//Mix de Destino
	Else 
		_cDadMixDe	:= DToC(SToD((_cAliasZLE)->ZLE_DTINI)) + " = " + DToC(SToD((_cAliasZLE)->ZLE_DTFIM))
		_sDtDesIni	:= (_cAliasZLE)->ZLE_DTINI
		_sDtDesFin	:= (_cAliasZLE)->ZLE_DTFIM
	EndIf

//Nao foi encontrado nenhum mix de acordo com o codigo fornecido acima
Else
	MsgStop("Número do mix inexistente.","MGLT02701")
	_lRet:= .F.
EndIf

If _lRet .And. (At('/',cGProdFora) > 0 .Or. At('/',cGProdFor2) > 0)
	MsgStop("Utilize ; para separar os produtores.","MGLT02731")
	_lRet:= .F.	   
EndIf
(_cAliasZLE)->(DBCloseArea())

oSDadMixOr:Refresh()
oSDadMixDe:Refresh()

Return _lRet

/*
===============================================================================================================================
Programa----------: MGLT027W
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 17/01/2011
Descrição---------: Efetua a validacao para verificar o fornecimento correto do Mix de destino e de origem.
Parametros--------: _cCodMIX - Codigo do Mix,
					_cTpMix - 1 == Mix de Origem e 2 == Mix de Destino
					_cCdSetor - Codigo do Setor
Retorno-----------: _lRet - Lógico validando campo de mix
===============================================================================================================================
*/
Static Function MGLT027W(_nTipoMix,_cCdMix,_cCdSetor)

Local _lRet		:= .T.
Local _cAlias	:= GetNextAlias()
Local _cFiltro	:= "%"

_cFiltro += " AND ZLF_FILIAL = '" + xFilial("ZLF") + "'"
_cFiltro += " AND ZLF_CODZLE = '" + _cCdMix + "'"
_cFiltro += " AND ZLF_SETOR = '" + _cCdSetor + "'"

//====================================================================
//Validacao no mix de origem, para este mix deve estar fechado o setor
//====================================================================
If _nTipoMix == 1
	_cFiltro += " AND ZLF_ACERTO <> 'S'"
	_cFiltro += " AND ZLF_STATUS <> 'F'"

//====================================================================
//Validacao no mix de destino, para este mix deve estar aberto o setor
//====================================================================
Else
	_cFiltro += " AND ZLF_ACERTO = 'S'"
	_cFiltro += " AND ZLF_STATUS = 'F'"
EndIf 

_cFiltro += "%"

BeginSql Alias _cAlias
	SELECT COUNT(1) NUMREG
	FROM %Table:ZLF%
	WHERE D_E_L_E_T_ = ' '
	%Exp:_cFiltro%	
EndSql

If _nTipoMix == 1
	If (_cAlias)->NUMREG > 0
		If !MsgYesNo("Mix fornecido incorretamente no campo Mix de Origem. Deseja continuar mesmo com status aberto?.","MGLT02702")
			_lRet:= .F.
		EndIf
	EndIf
Else
	If (_cAlias)->NUMREG > 0
		If !MsgYesNo("Mix fornecido incorretamente no campo Mix de Destino. Deseja continuar mesmo com status fechado?.","MGLT02703")
			_lRet:= .F.
		EndIf
	EndIf
EndIf

//Finaliza a area criada anteriormente
(_cAlias)->(DBCloseArea())

Return _lRet

/*
===============================================================================================================================
Programa----------: MGLT027U
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 17/01/2011
Descrição---------: Efetua a validacao do preenchimento dos dados da tela.
Parametros--------: Nenhum
Retorno-----------: _lRet - Lógico validando dados da tela
===============================================================================================================================
*/
Static Function MGLT027U

Local _lRet:= .T.

If Empty(cGMixOrig) .Or. Empty(cGMixDest) .Or. Empty(cGSetor ) .Or. Empty(cGLinFin) .Or. Empty(cGProdFin) .Or. Empty(cGLjProdFi) .Or. DToC(cGDtCred) == '  /  /  '
	MsgStop("O preenchimento dos campos destacados na cor azul é obrigatório!","MGLT02704")
	_lRet:= .F.
EndIf

//Inclusao de complemento de Pagamento
If (cCbOperac == 'Incluir' .Or. cCbOperac == 'Alterar') .And. cGVlrRepor == 0
	MsgStop("Para realizar a operação de inclusão de um complemento de pagamento é necessário o fornecimento do valor a repor por litro de leite.","MGLT02705")
	_lRet:= .F.
EndIf

If Val(cGMixOrig) > Val(cGMixDest)  
	MsgStop("O mix de destino tem que ser maior que o mix de origem!","MGLT02706")
	_lRet:= .F.
EndIf
 
//Valida mix de origem
If _lRet
	_lRet:= MGLT027W(1,cGMixOrig,cGSetor)
EndIf

//Valida mix de destino
If _lRet
	_lRet:= MGLT027W(2,cGMixDest,cGSetor)
EndIf

Return _lRet

/*
===============================================================================================================================
Programa----------: MGLT027U
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 17/01/2011
Descrição---------: Rotina utilizada para realizar a insercao do complemento de pagamento no Mix para faturo pagamento
Parametros--------: Nenhum
Retorno-----------: _lRet - Lógico indicando sucesso da inserção
===============================================================================================================================
*/
Static Function MGLT027G

Local _nCountRec	:= 0
Local _lRet			:= .T.
Local _aEventos		:= {}
Local _nPosEvent	:= 0

//=====================================================================================
//Seleciona o evento para geracao/exclusao dos complementos de pagamento aos produtores
//=====================================================================================
MsgRun("Filtrando os eventos para geração do complemento...",,{||CursorWait(), MGLT027Q(2,"","","",""), CursorArrow()})
_nCountRec := _nContReg

//=================================================================
//Devera existir dois eventos cadastrados para realizar esta rotina
//um para geracao do credito e para o debito ao produtor
//=================================================================
If _nCountRec == 2
		 
	(_cAliasZL8)->(DBGoTop())

	//=============================================================
	//Verifica se existem dois eventos um de credito e um de debito
	//para geracao do complemento de pagamento no Mix
	//=============================================================
	While (_cAliasZL8)->(!Eof())

		_nPosEvent:= aScan(_aEventos,{|x| x[3] == (_cAliasZL8)->ZL8_DEBCRE})
		
		If _nPosEvent == 0
			aAdd(_aEventos,{(_cAliasZL8)->ZL8_COD,(_cAliasZL8)->ZL8_NREDUZ,(_cAliasZL8)->ZL8_DEBCRE})
		EndIf

		(_cAliasZL8)->(DBSkip())
	EndDo

	(_cAliasZL8)->(DBCloseArea())

	//===========================================================
	//Verifica se foram lancados os dois eventos um de credito e 
	//outro de debito para geracao do complemento
	//===========================================================
	If Len(_aEventos) == 2

		//================================================================
		//Gerando a inclusao de um complemento de pagamento aos Produtores
		//================================================================
		If cCbOperac == 'Incluir'

			Processa({|| _lRet:=MGLT027P() },"Processando a inclusão do complemento...")

		//====================================================================
		//Gerando o cancelamento de um complemento de pagamento aos Produtores
		//====================================================================
		ElseIf cCbOperac == 'Excluir'

			Processa({|| _lRet:=MGLT027C() },"Processando o cancelamento do complemento...")

		//==========================================================
		//Efetua a alteracao do valor do complemento gerado, isto se
		//o complemento nao estiver sido efetivado.
		//==========================================================
		Else
			//Somente complemento que nao foi efetivado
			If ZZE->ZZE_STATUS == '1'
				MsgRun("Processando a alteração do Complemento...",,{||CursorWait(), _lRet:= MGLT027A(), CursorArrow()})
			Else 
				MsgStop("Não será possível realizar a alteração do complemento: " + ZZE->ZZE_CODIGO + " Pois somente será possível realizar a alteração de um determinado complemento que não esteja com o status efetivado.","MGLT02707")
				_lRet:= .F.
			EndIf
		EndIf

	//===========================================================
	//Nao existe um evento de credito e um debito cadastrados nos
	//eventos para geracao dos dados do complemento de pagamento
	//===========================================================
	Else
		MsgStop("Existem dois eventos cadastrados para a geração do complemento de pagamento. No entanto deve existir um evento de crédito e outro de débito para realizar a geração do complemento de pagamento. "+;
				"Favor comunicar ao responsável para realizar a alteração no cadastro de eventos.","MGLT02708")
		_lRet:= .F.
	EndIf

//=================================================================================
//Problema encontrado no evento cadastrado para geracao do complemento de pagamento
//=================================================================================
Else
	MsgStop("Verificar se foi cadastrado algum evento para geração do complemento de pagamento ao Produtor. "+;
			"A de se ressaltar que deverão ser cadastrados dois eventos um de crédito e outro de débito para geração do complemento.","MGLT02709")
	_lRet:= .F.
EndIf

Return _lRet

/*
===============================================================================================================================
Programa----------: MGLT027P
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 17/01/2011
Descrição---------: Funcao utilizada para gravar na tabela ZLF os dados do complemento de pagamento aos Produtores
Parametros--------: Nenhum
Retorno-----------: _lRet - Lógico indicando sucesso da gravação
===============================================================================================================================
*/
Static Function MGLT027P()

Local _nCountRec	:= 0
Local _lRet			:= .T.
Local _nVlrEvent	:= 0
Local _nQtdeVolu	:= 0
Local _cFiltro		:= '%'
Local _cMatUsr		:= FWSFAllUsers({RetCodUsr()},{"USR_FILIAL","USR_CODFUNC"})[1][3]+FWSFAllUsers({RetCodUsr()},{"USR_FILIAL","USR_CODFUNC"})[1][4]

Private _cAliasZLD:= GetNextAlias()

//==========================================================
//Query utilizada para filtrar os dados da recepcao de leite
//dos produtores enquadrados nos parametros fornecidos pelo
//usuario e sua respectiva recepcao de leite
//==========================================================
If Len(AllTrim(cGProdFora)) > 0
	_cFiltro += " AND ZLD.ZLD_RETIRO NOT IN " + FormatIn(AllTrim(cGProdFora),";")
EndIf
If Len(AllTrim(cGProdFor2)) > 0
	_cFiltro += " AND ZLD.ZLD_RETIRO NOT IN " + FormatIn(AllTrim(cGProdFor2),";")
EndIf
_cFiltro += '%'

BeginSql Alias _cAliasZLD
	SELECT ZLD_RETIRO,ZLD_RETILJ,SA2.A2_NOME,ZLD_SETOR,ZL2.ZL2_DESCRI,ZLD_LINROT,ZL3.ZL3_DESCRI,SUM(ZLD_QTDBOM) QTDELEITE
	FROM %Table:ZLD% ZLD, %Table:SA2% SA2, %Table:ZL2% ZL2, %Table:ZL3% ZL3
	WHERE ZLD.D_E_L_E_T_ = ' '
	AND SA2.D_E_L_E_T_ = ' '
	AND ZL2.D_E_L_E_T_ = ' '
	AND ZL3.D_E_L_E_T_ = ' '
	AND ZL2.ZL2_FILIAL = %xFilial:ZL2%
	AND ZL3.ZL3_FILIAL = %xFilial:ZL3%
	AND ZLD.ZLD_FILIAL = %xFilial:ZLD%
	AND SA2.A2_FILIAL = %xFilial:SA2%
	AND SA2.A2_COD = ZLD.ZLD_RETIRO
	AND SA2.A2_LOJA = ZLD.ZLD_RETILJ
	AND ZL2.ZL2_COD = ZLD.ZLD_SETOR
	AND ZL3.ZL3_COD = ZLD.ZLD_LINROT
	AND ZLD.ZLD_DTCOLE BETWEEN %exp:_sDtInic% AND %exp:_sDtFin%
	AND ZLD.ZLD_SETOR = %exp:cGSetor%
	AND ZLD.ZLD_LINROT BETWEEN %exp:cGLinIni% AND %exp:cGLinFin%
	AND ZLD.ZLD_RETIRO BETWEEN %exp:cGProdIni% AND %exp:cGProdFin%
	AND ZLD.ZLD_RETILJ BETWEEN %exp:cGLjProdIn% AND %exp:cGLjProdFi%
	AND ZLD.ZLD_QTDBOM > 0
	%exp:_cFiltro%
	GROUP BY ZLD_RETIRO,ZLD_RETILJ,SA2.A2_NOME,ZLD_SETOR,ZL2.ZL2_DESCRI,ZLD_LINROT,ZL3.ZL3_DESCRI
EndSql

COUNT TO _nCountRec //Contabiliza o numero de registros encontrados pela query
(_cAliasZLD)->(DBGoTop())
ProcRegua(_nCountRec)

If _nCountRec > 0

	Begin Transaction

		//============================================================
		//Inserindo os registros de complemento de pagamento na tabela
		//ZZF (Itens do complemento de pagamento)
		//============================================================
		(_cAliasZLD)->(DBGoTop())

		While (_cAliasZLD)->(!Eof())

			IncProc("Processando o produtor: " + (_cAliasZLD)->ZLD_RETIRO  + "/" + (_cAliasZLD)->ZLD_RETILJ)

			_nVlrEvent := (_cAliasZLD)->QTDELEITE * cGVlrRepor
			_nQtdeVolu += (_cAliasZLD)->QTDELEITE 

			MsgRun("Gerando a inserção dos itens do complemento...",,{||CursorWait(),;
			 MGLP027O(xFilial("ZZF"),cGNumero,(_cAliasZLD)->ZLD_RETIRO,(_cAliasZLD)->ZLD_RETILJ,(_cAliasZLD)->A2_NOME,(_cAliasZLD)->ZLD_LINROT,;
			 (_cAliasZLD)->ZL3_DESCRI,cGVlrRepor,(_cAliasZLD)->QTDELEITE,_nVlrEvent,'1'), CursorArrow()})

			(_cAliasZLD)->(DBSkip())
		EndDo

		//======================================================
		//Efetua a inserção dos dados na tabela ZZE referente ao
		//cabecalho do complemento efetuado
		//======================================================
		MsgRun("Gerando a inserção do cabeçalho do complemento...",,{||CursorWait(), MGLT027I(cGNumero,cGMixOrig,cGMixDest,cGSetor,cGLinIni,cGLinFin,cGProdIni,cGLjProdIn,cGProdFin,cGLjProdFi,cGVlrRepor,_nQtdeVolu,cGProdFora,cGProdFor2,cGDtCred,'1',_cMatUsr), CursorArrow()})

	End Transaction

//=======================================================
//Nao existem registros selecionados na recepcao de Leite
//=======================================================
Else
	MsgStop("Não foram encontrados registros na recepção de leite, para gerar o complemento de pagamento.","MGLT02710")
	_lRet:= .F.
EndIf

(_cAliasZLD)->(DBCloseArea())

Return _lRet

/*
===============================================================================================================================
Programa----------: MGLT027F
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 17/01/2011
Descrição---------: Funcao utilizada para gravar na tabela ZLF os dados do complemento de pagamento aos Produtores, sao gerados 
					dois eventos um de debito e um de credito, para que nao seja efetuado dois pagamentos aos produtores uma vez
					que ao efetivar um registro de complemento eh gerada uma NF ao produtor, os eventos de debito e credito
					gerados na ZLF sao para compor custo.
Parametros--------: _aDadosCom - array com dados a gravar na ZLF
					_aEventos - array com dados de eventos para gravar na ZLF
Retorno-----------: _lRet - Lógico indicando sucesso da gravação
===============================================================================================================================
*/
Static Function MGLT027F(_aDadosCom,_aEventos) 

Local _aArea		:= FWGetArea()
Local _cDesSetor	:= ""    
Local _nX, _nY		:=0
Local _nVlrLitro	:= 0
Local _nFPec	 	:= 0
Local _nImp		 	:= 0
Local _cCodFUND		:= AllTrim(SuperGetMV("LT_EVEFUND",.F.,"000014"))
Local _cAlias		:= ''
Local _nBase		:= 0 //varivável declarada como Private para poder ser lida por macroexecução (ZL8_FORMUL)
Local _nVolIncP		:= SuperGetMV("LT_VOLINCP",.F.,657000)
Local _lCalIncP		:= !Empty(Posicione('F28',1,xFilial('F28')+SuperGetMV("LT_INCINCP",.F.,""),'F28_CODIGO'))
Local _nRecPrd		:= 0
Local _nRecINS		:= 0
Local _nRecGil		:= 0
Local _cEveInc		:= AllTrim(SuperGetMV("LT_EVEIPRO",.F.,""))

//==========================================================
//Como o setor vai ser sempre o mesmo para todos os itens do
//complemento, eh buscada somente uma vez a descricao do
//setor para agilizar o processo
//==========================================================
_cDesSetor:= Posicione("ZL2",1,xFilial("ZL2") + ZZE->ZZE_SETOR,"ZL2->ZL2_DESCRI")

ProcRegua(Len(_aEventos))

For _nX:=1 to Len(_aEventos)

	IncProc()

	For _nY:=1 to Len(_aDadosCom)    

		//===============================================================
		//Somente sera gerado o lancamento dos eventos para os produtores
		//que nao estejam fechados ou efetivados no mix
		//===============================================================
		If _aDadosCom[_nY,11]
			//============================================================
			//Verifica se eh um evento de debito para calculo dos impostos
			//============================================================
			If _aEventos[_nX,3] == 'D' 

				//Posiciona no cadatro de fornecedor para que possa usar o cadastro de fórmula
				DBSelectArea("SA2")
				SA2->( DBSetOrder(1) )
				SA2->( DBSeek(xFilial("SA2")+_aDadosCom[_nY,2]+_aDadosCom[_nY,3]) )
				
				BEGIN TRANSACTION
					//Realiza tratamentos para Incentivo à Produção em MG
					If _lCalIncP
						U_CalcInc(1,_nVolIncP,@_lCalIncP,@_nRecPrd,@_nRecINS,@_nRecGil)
					EndIf
					//Busco todos os eventos de impostos para calculálos
					_cAlias	:= GetNextAlias()
					
					BeginSql alias _cAlias
						SELECT R_E_C_N_O_ RECZL8
						FROM %Table:ZL8% ZL8
						WHERE ZL8.D_E_L_E_T_ = ' '
						AND ZL8.ZL8_FILIAL = %xFilial:ZL8%
						AND ZL8.ZL8_PERTEN = 'P'
						AND ZL8.ZL8_GRUPO = '000007'
						AND ZL8.ZL8_MSBLQL <> '1'
					EndSql
					
					_nImp := 0
					
					While (_cAlias)->( !Eof() )
						ZL8->(DBGoTo((_cAlias)->RECZL8))
						If &( AllTrim( ZL8->ZL8_CONDIC ) ) .And. _cEveInc <> ZL8->ZL8_COD
							//Calcula Fundesa/Fundepec. Evento tratado como exceção até padronização de todos os impostos na NF-e
							If ZL8->ZL8_COD == _cCodFUND
								_nFPec:=_aDadosCom[_nY,9]*ZL8->ZL8_VALOR
							Else
								_nBase := _aDadosCom[_nY,9]
								_nImp += IIf(ZL8->ZL8_DEBCRE == 'C',&( ZL8->ZL8_FORMUL),&( ZL8->ZL8_FORMUL)*-1)
							EndIf
						EndIf
						(_cAlias)->( DBSkip() )
					EndDo
					
					(_cAlias)->( DBCloseArea() )
					SA2->( DBCloseArea( ) )
					ZL8->( DBCloseArea( ) )
					
					//Realiza tratamentos para Incentivo à Produção em MG
					If _lCalIncP
						U_CalcInc(2,_nVolIncP,_lCalIncP,_nRecPrd,_nRecINS,_nRecGil)
					EndIf
				END TRANSACTION
				//Quando houver o Incentivo à produção, somo o valor do incentivo nos créditos para que o cálculo do custo fique simulado corretamente
				If SA2->A2_INCLTMG == '1' .And. _lCalIncP
					_aDadosCom[_nY,9] += (_aDadosCom[_nY,9]*F28->F28_ALIQ)/100
				EndIf
				_aDadosCom[_nY,12]:=  _aDadosCom[_nY,9] - _nFPec +_nImp
				_nVlrLitro:= (_aDadosCom[_nY,12]/_aDadosCom[_nY,8])
			Else
				//Quando houver o Incentivo à produção, somo o valor do incentivo nos créditos para que o cálculo do custo fique simulado corretamente
				If SA2->A2_INCLTMG == '1' .And. _lCalIncP
					_aDadosCom[_nY,9] += (_aDadosCom[_nY,9]*F28->F28_ALIQ)/100
				EndIf
				_aDadosCom[_nY,12]:= _aDadosCom[_nY,9]
				_nVlrLitro:= (_aDadosCom[_nY,9]/_aDadosCom[_nY,8])
			EndIf

			RecLock("ZLF", .T.)

					ZLF->ZLF_FILIAL	:= xFilial("ZLF")
					ZLF->ZLF_CODZLE	:= MV_PAR01
					ZLF->ZLF_VERSAO	:= '1'
					ZLF->ZLF_SETOR	:= _aDadosCom[_nY,13]
					ZLF->ZLF_LINROT	:= _aDadosCom[_nY,5]
					ZLF->ZLF_A2COD	:= _aDadosCom[_nY,2]
					ZLF->ZLF_A2LOJA	:= _aDadosCom[_nY,3]
					ZLF->ZLF_RETIRO	:= _aDadosCom[_nY,2]
					ZLF->ZLF_RETILJ	:= _aDadosCom[_nY,3]
					ZLF->ZLF_EVENTO	:= _aEventos[_nX,1]
					ZLF->ZLF_ENTMIX	:= _aEventos[_nX,5]
					ZLF->ZLF_DEBCRED:= _aEventos[_nX,3]
					ZLF->ZLF_DTINI	:= _dDtIniMix
					ZLF->ZLF_DTFIM	:= _dDtFinMix
					ZLF->ZLF_QTDBOM	:= _aDadosCom[_nY,8]
					ZLF->ZLF_TOTAL	:= _aDadosCom[_nY,12]
					ZLF->ZLF_VLRLTR	:= _nVlrLitro
					ZLF->ZLF_ORIGEM	:= "M"
					ZLF->ZLF_ACERTO	:= "N"
					ZLF->ZLF_TP_MIX	:= "L"
					ZLF->ZLF_TIPO	:= "L"
					ZLF->ZLF_SEQ	:= u_getSeqZLF(MV_PAR01,_aEventos[_nX,1],_aDadosCom[_nY,2],_aDadosCom[_nY,3])
					ZLF->ZLF_STATUS := "A"
					ZLF->ZLF_SEEKCO := _aDadosCom[_nY,1] + "MGLT027"//CAMPO UTILIZADO PARA REALIZAR A BUSCA DO COMPLEMENTO GERADO POSTERIORMENTE

				ZLF->(MSUnLock())

			EndIf

	Next _nY

Next _nX

FWRestArea(_aArea)
Return

/*
===============================================================================================================================
Programa----------: MGLT027Q
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 17/01/2011
Descrição---------: Rotina desenvolvida para possibilitar o armazenamento de todas as query executas no fonte MGLT027
Parametros--------: _nQuery - numero da query a ser executada
					_cCodMIX 	- Codigo do Mix na validacao do GET(origem ou destino).
Retorno-----------: _lRet - Lógico indicando sucesso da gravação
===============================================================================================================================
*/
Static Function MGLT027Q(_nQuery,_cCodMIX,_cCodEvent,_cCodRecno,_cStatus,_cFilLinha)

Do Case

	//============================================================
	//Query utilizada para filtrar os dados do Mix na validacao do
	//campos de mix de origem e destino
	//============================================================
	Case _nQuery == 1
		BeginSql Alias _cAliasZLE
			SELECT ZLE_DTINI,ZLE_DTFIM,ZLE_STATUS
			FROM %Table:ZLE% ZLE
			WHERE D_E_L_E_T_ = ' '
			AND ZLE_FILIAL = %xFilial:ZLE%
			AND ZLE_COD = %exp:_cCodMIX%
		EndSql

	//================================================================
	//Query utilizada para selecionar os eventos de credito e debito a
	//serem gerados para o complemento de pagamento
	//================================================================
	Case _nQuery == 2
		BeginSql Alias _cAliasZL8
			SELECT ZL8.ZL8_COD, ZL8.ZL8_NREDUZ, ZL8.ZL8_DEBCRE, ZL8.ZL8_SB1COD, ZL8.ZL8_MIX
			FROM %Table:ZL8% ZL8
			WHERE D_E_L_E_T_ = ' '
			AND ZL8_FILIAL = %xFilial:ZL8%
			AND ZL8_ADICOM = 'S'
			AND ZL8_PERTEN = 'P'
			AND ZL8_TPEVEN = 'A'
			AND ZL8_FORMUL = '.F.'
			AND ZL8_CONDIC = '.F.'
			AND ZL8_MSBLQL <> '1'
		EndSql
	EndCase

COUNT TO _nContReg //Contabiliza o numero de registros encontrados pela query

Return 

/*
===============================================================================================================================
Programa----------: MGLT027I
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 17/01/2011
Descrição---------: Rotina desenvolvida para possibilitar a insercao dos dados na tabela ZZE
Parametros--------: Dados a gravar na tabela ZZE
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGLT027I(cGNumero,cGMixOrig,cGMixDest,cGSetor,cGLinIni,cGLinFin,cGProdIni,cGLjProdIn,cGProdFin,cGLjProdFi,;
						 cGVlrRepor,_nQtdeVolu,cGProdFora,cGProdFor2,_dDtCredit,_cStatus,_cMatUsr)

Local _aArea:= FWGetArea()

RecLock("ZZE",.T.)

	ZZE->ZZE_FILIAL:= xFilial("ZZE")
	ZZE->ZZE_CODIGO:= cGNumero
	ZZE->ZZE_MIXORI:= cGMixOrig
	ZZE->ZZE_MIXDES:= cGMixDest
	ZZE->ZZE_SETOR := cGSetor
	ZZE->ZZE_LININI:= cGLinIni
	ZZE->ZZE_LINFIN:= cGLinFin
	ZZE->ZZE_PROINI:= cGProdIni
	ZZE->ZZE_PROFIN:= cGProdFin
	ZZE->ZZE_LOJINI:= cGLjProdIn
	ZZE->ZZE_LOJFIN:= cGLjProdFi 
	ZZE->ZZE_PROOUT:= cGProdFora
	ZZE->ZZE_PROOU2:= cGProdFor2
	ZZE->ZZE_VALOR := cGVlrRepor
	ZZE->ZZE_VOLUME:= _nQtdeVolu
	ZZE->ZZE_VLRTOT:= _nQtdeVolu * cGVlrRepor 
	ZZE->ZZE_DATAIN:= Date()   
	ZZE->ZZE_DTCRED:= _dDtCredit
	ZZE->ZZE_USRINC:= _cMatUsr
	ZZE->ZZE_USREFE:= ""      	    
	ZZE->ZZE_STATUS:= _cStatus

ZZE->(MSUnLock())

If ( __lSX8 )
		ConfirmSX8()
EndIf

FWRestArea(_aArea)

Return

/*
===============================================================================================================================
Programa----------: MGLT027H
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 17/01/2011
Descrição---------: Retorna a data inicial e final do mix
Parametros--------: _cCodMIX - Codigo do Mix
					_cTpMix - 1 == Mix de Origem e 2 == Mix de Destino
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGLT027H(_cCodMIX,_cTpMix)   

Local _nCountRec:= 0
Local _cDescri	:= ""

Private _cAliasZLE:= GetNextAlias()

//=========================================
// Chama para funcao filtrar os dado do Mix
//=========================================
MsgRun("Filtrando Dados do Mix...",,{||CursorWait(), MGLT027Q(1,_cCodMIX,"","",""), CursorArrow()})
_nCountRec := _nContReg

If _nCountRec > 0

	(_cAliasZLE)->(DBGoTop())

	//Mix de Origem
	If _cTpMix == 1
		_cDescri:= DToC(SToD((_cAliasZLE)->ZLE_DTINI)) + " = " + DToC(SToD((_cAliasZLE)->ZLE_DTFIM))
		//Armazena a data inicial e final do mix de origem para ser utilizada em query futura
		_sDtInic  := (_cAliasZLE)->ZLE_DTINI
		_sDtFin   := (_cAliasZLE)->ZLE_DTFIM

	//Mix de Destino
	Else
		_cDescri	:= DToC(SToD((_cAliasZLE)->ZLE_DTINI)) + " = " + DToC(SToD((_cAliasZLE)->ZLE_DTFIM)) 
		_sDtDesIni	:= (_cAliasZLE)->ZLE_DTINI
		_sDtDesFin	:= (_cAliasZLE)->ZLE_DTFIM
	EndIf

EndIf

(_cAliasZLE)->(DBCloseArea())

Return _cDescri

/*
===============================================================================================================================
Programa----------: MGLT027E
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 12/01/2011
Descrição---------: Legenda do browse principal (ZZE)
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MGLT027E()

BrwLegenda("Legenda","Status dos Complementos",{{"ENABLE","Complemento incluido"},{"BR_AZUL","Complemento efetivado"}})
														
Return(.T.) 

/*
===============================================================================================================================
Programa----------: MGLT027D
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 12/01/2011
Descrição---------: Legenda do browse auxiliar (ZZG)
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MGLT027D()

BrwLegenda("Legenda","Status dos Complementos",{{"ENABLE","Complemento incluido"},;
				{"BR_AZUL","Complemento efetivado"},{"DISABLE","Complemento cancelado"},;
				{"BR_AMARELO","Complemento não gerado"}})
				
Return(.T.)

/*
===============================================================================================================================
Programa----------: MGLT027C
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 12/01/2011
Descrição---------: Processa o cancelamento dos registros de complemento de pagamento.
Parametros--------: _cCodEvent - codigo do evento
Retorno-----------: _lRet - Lógico indicando sucesso do cancelamento
===============================================================================================================================
*/
Static Function MGLT027C() 

Local _nCountRec:= 0
Local _lRet		:= .T.
Local _cCodCompl:= ZZE->ZZE_CODIGO

Private _cAliasExc:= ""
Private _cAliExMix:= ""

//=============================================================
//Verfica se o complemento a ser excluido foi efetivado, caso
//nao tenha sido efetivado os registros a serem excluidos devem
//ser somente das tabelas: ZZE e ZZF
//=============================================================
If ZZE->ZZE_STATUS == '1'

	Begin Transaction

		//=============================================================
		//Funcao utilizada para realizar a exclusao dos registros de
		//complemento das tabelas: ZZE e ZZF.
		//=============================================================
		_lRet:= MGLT027_5(_cCodCompl)

		If !_lRet

			//========================================================
			//Caso encontre algum problema na exclusao dos complemento
			//de pagamento a transacao eh desarmada
			//========================================================
			DisarmTransaction()

		EndIf

	End Transaction

//=========================================================
//Caso o complemento a ser excluido tenha sido efetivado
//os registros das seguintes tabelas deverao ser excluidos:
//ZZE,ZZF,ZLF e SE2
//=========================================================
Else

	_cAliasExc:= GetNextAlias()
	_cAliExMix:= GetNextAlias()

	//===================================================================
	//Verifica se algum produtor que foi gerado o complemento foi fechado
	//desta forma nao podera ser realizada exclusao do complemento
	//sem antes cancelar os fechamentos que fazem parte do complemento
	//===================================================================
	BeginSql Alias _cAliExMix
		SELECT COUNT(1) QTD
		FROM %Table:ZLF% ZLF
		WHERE D_E_L_E_T_ = ' '
		AND ZLF_FILIAL = %xFilial:ZLF%
		AND ZLF_STATUS IN ('F','E','P')
		AND ZLF_SEEKCO = %exp:ZZE->ZZE_CODIGO + "MGLT027"%
	EndSql

	_nCountRec:= (_cAliExMix)->QTD
	(_cAliExMix)->(DBCloseArea())

	If _nCountRec == 0
		//===============================================================
		//Seleciona os registro de complemento de pagamento da tabela ZLF
		//===============================================================
		BeginSql Alias _cAliasExc
			SELECT ZLF.R_E_C_N_O_ RECNOZLF
			FROM %Table:ZLF% ZLF
			WHERE D_E_L_E_T_ = ' '
			AND ZLF_FILIAL = %xFilial:ZLF%
			AND ZLF_ACERTO = 'N'
			AND ZLF_STATUS = 'A'
			AND ZLF_SEEKCO = %exp:ZZE->ZZE_CODIGO + "MGLT027"%
		EndSql
		            		
		COUNT TO _nCountRec //Contabiliza o numero de registros encontrados pela query
		(_cAliasExc)->(DBGoTop())

		If _nCountRec > 0

			Begin Transaction

			Processa({|| _lRet:= MGLT027_6(_cCodCompl,_nCountRec) },"Deletando os eventos do complemento no Mix")

			//======================================================
			//Efetua o delete dos registro gerados no contas a pagar
			//======================================================
			If _lRet
				Processa({|| _lRet:= MGLT027_7() },"Deletando os titulos gerados no financeiro")
			EndIf

			//==========================================================
			//Funcao utilizada para realizar a exclusao dos registros de 
			//complemento das tabelas: ZZE e ZZF
			//==========================================================
			If _lRet
				_lRet:= MGLT027_5(_cCodCompl)
			EndIf

			If !_lRet

				//============================================================
				//Caso encontre algum problema no cancelamento dos complemento
				//de pagamento a transacao eh desarmada
				//============================================================
				DisarmTransaction()
				
			EndIf
			End Transaction

		//===============================================================
		//Nao foram encontrados registros dos eventos dos complementos de
		//pagamento na tabela ZLF
		//===============================================================
		Else
			MsgStop("Existe(m) complemento(s) de pagamento cujo o fechamento do produtor ja foi fechado, ou se encontra com o status efetivado. "+;
					"Desta forma não será possível realizar a exclusão do complemento de pagamento, pois para realizar esta rotina todos os complementos "+;
					"gerados não podem ter passado pela rotina de fechamento do produtor, ou de efetivação do mix.","MGLT02711")
			_lRet:= .F.
		EndIf

	//============================================================
	//Existem registros dos eventos de complemento fechados no mix
	//============================================================
	Else
		MsgStop("Não poderá ser realizada a exclusão do complemento de pagamento: " + _cCodCompl +" pois foi constatado no mix do leite que existe "+;
				"fechamento do leite, ou o mesmo se encontra com o status efetivado/aprovado, desta forma para realizar esta esclusão deve-se primeiramente "+;
				"cancelar o fechamento de todos os produtores que receberam complemento de pagamento e alterar o seu status para aberto.","MGLT02712")
		_lRet:= .F.
	EndIf

EndIf

Return _lRet

/*
===============================================================================================================================
Programa----------: MGLT027A
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 12/01/2011
Descrição---------: Processa a alteracao do valor do complemento de pagamento gerados na inclusao. 
Parametros--------: _cCodEvent - codigo do evento
Retorno-----------: _lRet - Lógico indicando sucesso do cancelamento
===============================================================================================================================
*/
Static Function MGLT027A() 

Local _aArea	:= FWGetArea()
Local _lRet		:= .T.
Local _cCodCompl:= ZZE->ZZE_CODIGO
Local _nSomtVlr	:= 0

Begin Transaction

	//===========================================================
	//Atualiza os registros dos itens do complemento de pagamento
	//===========================================================
	DBSelectArea("ZZF")
	ZZF->(DBSetOrder(1))
	If ZZF->(DBSeek(xFilial("ZZF") + _cCodCompl))

		While ZZF->ZZF_FILIAL == xFilial("ZZF") .And. ZZF->ZZF_CODIGO == _cCodCompl

			_nSomtVlr += ZZF->ZZF_VOLUME * cGVlrRepor  

			RecLock("ZZF",.F.) 
			ZZF->ZZF_VALOR := cGVlrRepor
			ZZF->ZZF_VLRTOT:= ZZF->ZZF_VOLUME * cGVlrRepor 
			ZZF->(MSUnLock())
			ZZF->(DBSkip())
		EndDo

		//============================================================
		//Atualiza o registro de cabecalho do complemento de pagamento
		//============================================================
		DBSelectArea("ZZE") 
		ZZE->(DBSetOrder(1))
		If ZZE->(DBSeek(xFilial("ZZE") + _cCodCompl))

			RecLock("ZZE",.F.)
			ZZE->ZZE_DTCRED:= cGDtCred
			ZZE->ZZE_VALOR := cGVlrRepor
			ZZE->ZZE_VLRTOT:= _nSomtVlr
			ZZE->(MSUnLock())

		Else
			MsgStop("Não foi encontrado registro referente ao cabecalho do complemento de pagamento: " + _cCodCompl +;
					". Favor comunicar ao departamento de informática do problema encontrado.","MGLT02713")
			_lRet:= .F.
		EndIf
			
	Else
		MsgStop("Não foram encontrados registros referente aos Itens do complemento de pagamento: " + _cCodCompl +;
				". Favor comunicar ao departamento de informática do problema encontrado.","MGLT02714")
		_lRet:= .F.
	EndIf

	//===============================================================================================
	//Caso encontre algum problema na alteração dos complemento de pagamento a transacao eh desarmada
	//===============================================================================================
	If !_lRet
		DisarmTransaction()
	EndIf 

End Transaction

FWRestArea(_aArea)

Return _lRet   

/*
===============================================================================================================================
Programa----------: MGLT027O
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 12/01/2011
Descrição---------: Funcao utilizada para realizar a insercao dos itens do complemento na tabela ZZF.
Parametros--------: Dados a gravar na tabela ZZF:
					ZZF->ZZF_FILIAL:= _cFil
					ZZF->ZZF_CODIGO:= _cCodigo
					ZZF->ZZF_FORNEC:= _cFornec
					ZZF->ZZF_LJFORN:= _cLjFornec
					ZZF->ZZF_A2NOME:= _cDescForn
					ZZF->ZZF_LINHA := _cCodLinha
					ZZF->ZZF_DCLINH:= _cDescLinh
					ZZF->ZZF_VALOR := _nVlrRepor
					ZZF->ZZF_VOLUME:= _nQtdLeite
					ZZF->ZZF_VLRTOT:= _vlrTotal
					ZZF->ZZF_STATUS:= _cStatus
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGLP027O(_cFil,_cCodigo,_cFornec,_cLjFornec,_cDescForn,_cCodLinha,;
						_cDescLinh,_nVlrRepor,_nQtdLeite,_vlrTotal,_cStatus)    

Local _aArea:= FWGetArea()

RecLock("ZZF",.T.)

	ZZF->ZZF_FILIAL:= _cFil
	ZZF->ZZF_CODIGO:= _cCodigo
	ZZF->ZZF_FORNEC:= _cFornec
	ZZF->ZZF_LJFORN:= _cLjFornec
	ZZF->ZZF_A2NOME:= _cDescForn
	ZZF->ZZF_LINHA := _cCodLinha
	ZZF->ZZF_DCLINH:= _cDescLinh
	ZZF->ZZF_VALOR := _nVlrRepor
	ZZF->ZZF_VOLUME:= _nQtdLeite
	ZZF->ZZF_VLRTOT:= _vlrTotal
	ZZF->ZZF_STATUS:= _cStatus

ZZF->(MSUnLock())

FWRestArea(_aArea)

Return

/*
===============================================================================================================================
Programa----------: MGLT027Z
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 12/01/2011
Descrição---------: Funcao utilizada para possibilitar ao usuario atraves  de uma tela selecionar os complementos de pagamento
					que ele deseja gerar o financeiro, e entrar na composicao do mix de destino indicado.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MGLT027Z()

Local _aArea	:= FWGetArea()
Local _nContZZF	:= 0
Local _oPanel
Local _nHeight	:= 0
Local _nWidth	:= 0
Local _aSize	:= {}
Local _aCoors	:= {}
Local _cTab		:= "FFT"
Local oQtdTotVol,oVlrTotal
Local oOK		:= LoadBitmap(GetResources(),'LBOK')
Local oNO		:= LoadBitmap(GetResources(),'LBNO')
Local _nX		:= 0

Private oDlg1
Private oQtdSelVol,oVlrSel
Private aStruct		:= {}
Private aTitulo		:= {}
Private nQtdTit		:= 0
Private nQtdTotVol	:= ZZE->ZZE_VOLUME
Private nVlrTotal	:= ZZE->ZZE_VLRTOT
Private nQtdSelVol	:= 0
Private nVlrSel		:= 0
Private _oTempTable	
Private aObjects	:= {}
Private aPosObj1	:= {}
Private aInfo		:= {}
Private oBrowse
Private oFont12b
Private _cAliasZZF:= GetNextAlias()
Private _aBotoes	:= {} 
Private _dDtIniMix,_dDtFinMix

//======================================
//Define a fonte a ser utilizada no GRID
//======================================
Define Font oFont12b   Name "Courier New"       Size 0,-12 Bold  // Tamanho 12 Negrito

If !Pergunte("MGLT027",.T.)
	Return
EndIf

//================================================================================
//Seleciona os registros dos itens do complemento gerado, que nao foram efetivados
//Validar se a data do servidor eh maior ou igual a data de credito isto devido a 
//data servidor ser a data para a geracao do titulo e a  data de credito ser a data 
//de vencimento
//=================================================================
BeginSql Alias _cAliasZZF
	SELECT ZZF_FILIAL,ZZF_CODIGO,ZZE_SETOR, ZZF_FORNEC,ZZF_LJFORN,ZZF_A2NOME,ZZF_LINHA,ZZF_DCLINH,ZZF_VALOR,ZZF_VOLUME,ZZF_VLRTOT,ZZF_STATUS, ZZF.R_E_C_N_O_ RECNOZZF, ZZE_DTCRED
	FROM %Table:ZZF% ZZF, %Table:ZZE% ZZE
	WHERE ZZF.D_E_L_E_T_ = ' '
	AND ZZE.D_E_L_E_T_ = ' '
	AND ZZF_FILIAL = %xFilial:ZZF%
	AND ZZE_FILIAL = %xFilial:ZZE%
	AND ZZF_CODIGO = ZZE_CODIGO
	AND ZZE_MIXDES = %exp:MV_PAR01%
	AND ZZF_CODIGO BETWEEN %exp:MV_PAR02% AND %exp:MV_PAR03%
	AND ZZE_SETOR BETWEEN %exp:MV_PAR04% AND %exp:MV_PAR05%
	AND ZZF_STATUS <> '2'"
	AND ZZE_DTCRED >= %exp:DToS(dDataBase)%
EndSql

COUNT TO _nContZZF //Contabiliza o numero de registros encontrados pela query
(_cAliasZZF)->(DBGoTop())

//============================================
// Nao existem registros de baixa selecionados
//============================================
If _nContZZF == 0
	MsgStop("Não foi(ram) encontrado(s) registro(s) de complemento de pagamento a ser(em) efetivado(s). "+;
			"Favor verificar se todos os registros deste complemento de pagamento não foram efetivados anteriormente.","MGLT02715")
Else
	// Cria aquivo temporario
	MsgRun("Montando estrutura dos dados...",,{||CursorWait(), MGLT027N(_cTab), CursorArrow()})

	// Insere os dados no arquivo temporario criado
	MsgRun("Inserindo os dados selecionados...",,{||CursorWait(),MGLT027S(_cTab),CursorArrow()})

	// Faz o calculo automatico de dimensoes de objetos
	_aSize := MSADVSIZE()

	// Obtem tamanhos das telas
	aAdd( aObjects, { 0, 0, .T., .T., .T. } )
	aInfo    := { _aSize[ 1 ], _aSize[ 2 ], _aSize[ 3 ], _aSize[ 4 ], 3, 3 } 
	aPosObj1 := MsObjSize( aInfo, aObjects,  , .T. ) 

	// Botoes da tela
	aAdd( _aBotoes, {"PESQUISA" ,{||MGLT0270(_cTab)																		},"Pesquisar...","Pesquisar"				})
	aAdd( _aBotoes, {"S4WB005N" ,{||MGLT0272()																			},"Visualizar Complemento..." ,"Visualizar"	})
	aAdd( _aBotoes, {'RELATORIO',{||MsgRun("Imprimindo relatório...",,{||CursorWait(),MGLT0273(_cTab),CursorArrow()})	},"Imprimir"								})

	// Cria a tela para selecao dos Titulos
	DEFINE MSDIALOG oDlg1 TITLE OemToAnsi("ROTINA DE EFETIVAÇÃO DE COMPLEMENTO DE PAGAMETNO") From 0,0 To _aSize[6],_aSize[5] OF oMainWnd PIXEL

	_oPanel			:= TPanel():New(0,0,'',oDlg1,, .T., .T.,, ,315,30,.T.,.T. )
//	_oPanel:Align	:= CONTROL_ALIGN_TOP // Somente Interface MDI

	@ 0.1 ,0010 Say OemToAnsi("Valor total:")             OF _oPanel FONT oFont12b 
	@ 0.1 ,0015 Say oVlrTotal VAR nVlrTotal Picture "@E 999,999,999.9999"  SIZE 60,8 OF _oPanel FONT oFont12b 

	@ 0.1 ,0025 Say OemToAnsi("Valor selecionado:")      OF _oPanel FONT oFont12b 
	@ 0.1 ,0033 Say oVlrSel VAR nVlrSel Picture "@E 999,999,999.9999" SIZE 60,8 OF _oPanel FONT oFont12b  

	@ 1.1 ,00.8 Say OemToAnsi("Quantidade:")              OF _oPanel FONT oFont12b 
	@ 1.1 ,0005 Say oQtda VAR nQtdTit Picture "@E 999999" SIZE 60,8 OF _oPanel FONT oFont12b 

	@ 1.1 ,0010 Say OemToAnsi("Volume total:")            OF _oPanel FONT oFont12b 
	@ 1.1 ,0016 Say oQtdTotVol VAR nQtdTotVol Picture "@E 999,999,999" SIZE 60,8 OF _oPanel FONT oFont12b   

	@ 1.1 ,0025 Say OemToAnsi("Volume selecionado:")      OF _oPanel FONT oFont12b 
	@ 1.1 ,0033 Say oQtdSelVol VAR nQtdSelVol Picture "@E 999,999,999" SIZE 60,8 OF _oPanel FONT oFont12b 

	If FlatMode()
		_aCoors := GetScreenRes()
		_nHeight:= _aCoors[2]
		_nWidth	:= _aCoors[1]
	Else
		_nHeight:= 143
		_nWidth	:= 315
	EndIf

	(_cTab)->(DBGoTop())

	oBrowse := TCBrowse():New( 35,01,aPosObj1[1,3] + 7,aPosObj1[1,4] - 10,,;
		                     ,{20,20,20,02,09,02,02,10,06,04,54,08,08},;
		                     oDlg1,,,,,{||},,oFont12b,,,,,.F.,_cTab,.T.,,.F.,,.T.,.T.)

	For _nX:=1 to Len(aStruct)

		If aStruct[_nX,1] == _cTab + "_STATUS"
			oBrowse:AddColumn(TCColumn():New("",{|| IIf(&(_cTab + '->' + _cTab + "_STATUS") == Space(2),oNO,oOK)},,,,"CENTER",,.T.,.F.,,,,.F.,))
		Else
			oBrowse:AddColumn(TCColumn():New(OemToAnsi(aTitulo[_nX,2]),&("{ || " + _cTab + '->' + aStruct[_nX,1]+"}"),aTitulo[_nX,3],,,If(aStruct[_nX,2]=="N","RIGHT","LEFT"),,.F.,.F.,,,,.F.,))
		EndIf

	Next _nX

	//Insere imagem em colunas que os dados poderao ser ordenados
	MGLT027L(3)

	// Evento de duplo click na celula
	oBrowse:bLDblClick   := {|| MGLT027J(_cTab,&(_cTab + '->' + _cTab + "_STATUS"))}  

	//Evento quando o usuario clica na coluna desejada
	oBrowse:bHeaderClick := { |oBrowse, nCol| _nColuna:= nCol,MsgRun("Realizando Operação...",,{|| MGLT027K(_cTab,_nColuna) }) }

	ACTIVATE MSDIALOG oDlg1 ON INIT (EnchoiceBar(oDlg1,{|| IIf(MGLT027_1(),Eval({|| _nOpca := 1,oDlg1:End(),MsgRun("Efetivando Complemento...",,{||CursorWait(),MGLT027_2(_cTab),CursorArrow()})}),) },{|| _nOpca := 2,oDlg1:End()},,_aBotoes), _oPanel:Align:=CONTROL_ALIGN_TOP, oBrowse:Align:=CONTROL_ALIGN_ALLCLIENT, oBrowse:Refresh() )

	(_cTab)->(DBCloseArea())
	_oTempTable:Delete()

EndIf

FWRestArea(_aArea)

Return
/*
===============================================================================================================================
Programa----------: MGLT027N
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 12/01/2011
Descrição---------: Cria tabela temporaria para montagem da tela
Parametros--------: _ctab - Alias da tabela temporaria
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGLT027N(_cTab)

aStruct := {}
aTitulo := {}

// Criando estrutura da tabela temporaria das unidades
aAdd(aStruct,{_cTab+"_STATUS"  ,"C",02,0   })
aAdd(aStruct,{_cTab+"_CODIGO"  ,"C",GetSX3Cache("ZZE_CODIGO","X3_TAMANHO"),GetSX3Cache("ZZE_CODIGO","X3_DECIMAL")})
aAdd(aStruct,{_cTab+"_SETOR"  ,"C",GetSX3Cache("ZL2_COD","X3_TAMANHO"),GetSX3Cache("ZL2_COD","X3_DECIMAL")})
aAdd(aStruct,{_cTab+"_FORNEC"  ,"C",GetSX3Cache("A2_COD","X3_TAMANHO"),GetSX3Cache("A2_COD","X3_DECIMAL")})
aAdd(aStruct,{_cTab+"_LOJA"    ,"C",GetSX3Cache("A2_LOJA","X3_TAMANHO"),GetSX3Cache("A2_LOJA","X3_DECIMAL")})
aAdd(aStruct,{_cTab+"_A2NOME"  ,"C",GetSX3Cache("A2_NOME","X3_TAMANHO"),GetSX3Cache("A2_NOME","X3_DECIMAL")})
aAdd(aStruct,{_cTab+"_LINHA"   ,"C",GetSX3Cache("ZL3_COD","X3_TAMANHO"),GetSX3Cache("ZL3_COD","X3_DECIMAL")})
aAdd(aStruct,{_cTab+"_DCLIN"   ,"C",GetSX3Cache("ZL3_DESCRI","X3_TAMANHO"),GetSX3Cache("ZL3_DESCRI","X3_DECIMAL")})
aAdd(aStruct,{_cTab+"_DTCRED"  ,"D",GetSX3Cache("ZZE_DTCRED","X3_TAMANHO"),GetSX3Cache("ZZE_DTCRED","X3_DECIMAL")})
aAdd(aStruct,{_cTab+"_VALOR"   ,"N",GetSX3Cache("ZZE_VALOR","X3_TAMANHO"),GetSX3Cache("ZZE_VALOR","X3_DECIMAL")})
aAdd(aStruct,{_cTab+"_VOLUME"  ,"N",GetSX3Cache("ZZE_VOLUME","X3_TAMANHO"),GetSX3Cache("ZZE_VOLUME","X3_DECIMAL")})
aAdd(aStruct,{_cTab+"_VLRTOT"  ,"N",GetSX3Cache("ZZE_VLRTOT","X3_TAMANHO"),GetSX3Cache("ZZE_VLRTOT","X3_DECIMAL") })
aAdd(aStruct,{_cTab+"_STAT"    ,"C",09,0  })
aAdd(aStruct,{_cTab+"_RECNO"   ,"N",10,0 })

// Armazena no array aCampos o nome, descricao dos campos e picture
aAdd(aTitulo,{_cTab+"_STATUS"  ,"  "                ,"  "})
aAdd(aTitulo,{_cTab+"_CODIGO"  ,GetSX3Cache("ZZE_CODIGO","X3_TITULO"),GetSX3Cache("ZZF_CODIGO","X3_PICTURE")})
aAdd(aTitulo,{_cTab+"_SETOR"   ,GetSX3Cache("ZZE_SETOR","X3_TITULO"),GetSX3Cache("ZL2_COD","X3_PICTURE")})  
aAdd(aTitulo,{_cTab+"_FORNEC"  ,GetSX3Cache("ZZF_FORNEC","X3_TITULO"),GetSX3Cache("ZZF_FORNEC","X3_PICTURE")})  
aAdd(aTitulo,{_cTab+"_LOJA"    ,GetSX3Cache("ZZF_LJFORN","X3_TITULO"),GetSX3Cache("ZZE_STATUS","X3_PICTURE")})
aAdd(aTitulo,{_cTab+"_A2NOME"  ,"DESCRIÇÃO PRODUTOR",GetSX3Cache("A2_NOME","X3_PICTURE")})
aAdd(aTitulo,{_cTab+"_LINHA"   ,GetSX3Cache("ZZF_LINHA","X3_TITULO"),GetSX3Cache("ZL3_COD","X3_PICTURE")})
aAdd(aTitulo,{_cTab+"_DCLIN"   ,GetSX3Cache("ZZF_DCLINH","X3_TITULO"),GetSX3Cache("ZL3_DESCRI","X3_PICTURE")})
aAdd(aTitulo,{_cTab+"_DTCRE"   ,"Dt. Cred"          ,GetSX3Cache("ZZE_DTCRED","X3_PICTURE")})
aAdd(aTitulo,{_cTab+"_VALOR"   ,"VALOR"             ,GetSX3Cache("ZZF_VALOR","X3_PICTURE")})
aAdd(aTitulo,{_cTab+"_VOLUME"  ,"VOLUME"            ,GetSX3Cache("ZZF_VOLUME","X3_PICTURE")})
aAdd(aTitulo,{_cTab+"_VLRTOT"  ,"VALOR TOTAL"       ,GetSX3Cache("ZZF_VLRTOT","X3_PICTURE")})
aAdd(aTitulo,{_cTab+"_STAT"    ,"STATUS"            ,"!!!!!!!!!!"}) 
aAdd(aTitulo,{_cTab+"_RECNO"   ,"R_E_C_N_O"         ,"9999999999"}) 

//----------------------------------------------------------------------
// Cria arquivo de dados temporário
//----------------------------------------------------------------------
_oTempTable := FWTemporaryTable():New( _cTab, aStruct )
//------------------
//Criação da tabela
//------------------
_oTempTable:AddIndex( "01", {_cTab + "_FORNEC", _cTab + "_LOJA"} )//Codigo do Produtor + Loja
_oTempTable:AddIndex( "02", {_cTab + "_A2NOME"} )//Descricao do Produtor
_oTempTable:AddIndex( "03", {_cTab + "_LINHA"} )//Linha
_oTempTable:AddIndex( "04", {_cTab + "_VOLUME"} )//Volume
_oTempTable:Create()

Return

/*
===============================================================================================================================
Programa----------: MGLT027S
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 12/01/2011
Descrição---------: Funcao usada para inserir dados selecionados atraves da pesquisa no arquivo temporario criado anteriormente
Parametros--------: _ctab - Alias da tabela temporaria	
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGLT027S(_cTab)
 
(_cAliasZZF)->(DBGoTop())

While (_cAliasZZF)->(!Eof())

	DBSelectArea(_cTab)
	RecLock(_cTab,.T.)

		&(_cTab+'->'+_cTab+'_STATUS') 	:= Space(2)
		&(_cTab+'->'+_cTab+'_CODIGO') 	:= (_cAliasZZF)->ZZF_CODIGO
		&(_cTab+'->'+_cTab+'_SETOR') 	:= (_cAliasZZF)->ZZE_SETOR
		&(_cTab+'->'+_cTab+'_FORNEC') 	:= (_cAliasZZF)->ZZF_FORNEC
		&(_cTab+'->'+_cTab+'_LOJA')   	:= (_cAliasZZF)->ZZF_LJFORN
		&(_cTab+'->'+_cTab+'_A2NOME') 	:= (_cAliasZZF)->ZZF_A2NOME
		&(_cTab+'->'+_cTab+'_LINHA')  	:= (_cAliasZZF)->ZZF_LINHA
		&(_cTab+'->'+_cTab+'_DCLIN')	:= (_cAliasZZF)->ZZF_DCLINH
		&(_cTab+'->'+_cTab+'_DTCRED')	:= SToD((_cAliasZZF)->ZZE_DTCRED)
		&(_cTab+'->'+_cTab+'_VALOR')  	:= (_cAliasZZF)->ZZF_VALOR
		&(_cTab+'->'+_cTab+'_VOLUME') 	:= (_cAliasZZF)->ZZF_VOLUME
		&(_cTab+'->'+_cTab+'_VLRTOT')	:= (_cAliasZZF)->ZZF_VLRTOT
		&(_cTab+'->'+_cTab+'_STAT')   	:= IIf((_cAliasZZF)->ZZF_STATUS == '1',"Incluido","Cancelado")
		&(_cTab+'->'+_cTab+'_RECNO') 	:= (_cAliasZZF)->RECNOZZF

	(_cTab)->(MSUnLock())

(_cAliasZZF)->(DBSkip())

EndDo

(_cAliasZZF)->(DBCloseArea())

Return

/*
===============================================================================================================================
Programa----------: MGLT027J
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 12/01/2011
Descrição---------: Quando o usuario der um duplo clique na linha verifica o status do registro marcando-o ou desmarcando-o.
Parametros--------: _ctab - Alias da tabela temporaria	
Retorno-----------: Nenhum
===============================================================================================================================
*/  
Static Function MGLT027J(_cTab,_cStatus)

If _cStatus == Space(2) 

	RecLock(_cTab,.F.)
	&(_cTab+'->'+_cTab+'_STATUS'):= 'XX'
	nQtdTit++
	nQtdSelVol+= &(_cTab+'->'+_cTab+'_VOLUME')
	nVlrSel   += &(_cTab+'->'+_cTab+'_VLRTOT' )
	(_cTab)->(MSUnLock())  
		
Else

	RecLock(_cTab,.F.)
	&(_cTab+'->'+_cTab+'_STATUS'):= Space(2)
	nQtdTit--
	nQtdSelVol-= &(_cTab+'->'+_cTab+'_VOLUME')
	nVlrSel   -= &(_cTab+'->'+_cTab+'_VLRTOT' )
	(_cTab)->(MSUnLock())  

EndIf

nQtdTit		:= IIf(nQtdTit<0,0,nQtdTit)
nQtdSelVol	:= IIf(nQtdSelVol<0,0,nQtdSelVol)
nVlrSel		:= IIf(nVlrSel<0,0,nVlrSel)

oQtda:Refresh()
oQtdSelVol:Refresh()
oVlrSel:Refresh()

oBrowse:DrawSelect()
oBrowse:Refresh(.T.)

Return

/*
===============================================================================================================================
Programa----------: MGLT027K
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 12/01/2011
Descrição---------: Funcao para ordenar dados de acordo com a coluna clicada pelo usuario, somente as colunas disponibilizadas
Parametros--------: _ctab - Alias da tabela temporaria
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGLT027K(_cTab,_nColuna)

Local _aArea:= FWGetArea()

Do Case
//Marca ou desmarca todos os titulos selecionados
	Case _nColuna == 1

		DBSelectArea(_cTab)
		(_cTab)->(DBGoTop())

		While (_cTab)->(!Eof())

			//Se o titulo nao estiver selecionado
			If &(_cTab+'->'+_cTab+'_STATUS') == Space(2)
				RecLock(_cTab,.F.)
				&(_cTab+'->'+_cTab+'_STATUS'):= 'XX'
				nQtdTit++
				nQtdSelVol+= &(_cTab+'->'+_cTab+'_VOLUME')
				nVlrSel   += &(_cTab+'->'+_cTab+'_VLRTOT' )
				(_cTab)->(MSUnLock())

				//Titulo selecionado
			Else
				RecLock(_cTab,.F.)
				&(_cTab+'->'+_cTab+'_STATUS'):= Space(2)
				nQtdTit--
				nQtdSelVol-= &(_cTab+'->'+_cTab+'_VOLUME')
				nVlrSel   -= &(_cTab+'->'+_cTab+'_VLRTOT' )
				(_cTab)->(MSUnLock())

			EndIf

			(_cTab)->(DBSkip())
		EndDo

		nQtdTit		:= IIf(nQtdTit<0,0,nQtdTit)
		nQtdSelVol	:= IIf(nQtdSelVol<0,0,nQtdSelVol)
		nVlrSel		:= IIf(nVlrSel<0,0,nVlrSel)

		oQtda:Refresh()
		oQtdSelVol:Refresh()
		oVlrSel:Refresh()

		FWRestArea(_aArea) 

	//Codigo do Produtor + Loja
	Case _nColuna == 3

		DBSelectArea(_cTab)
		(_cTab)->(DBSetOrder(1))
		(_cTab)->(DBGoTop())

	//Descricao do Produtor
	Case _nColuna == 5

		DBSelectArea(_cTab)
		(_cTab)->(DBSetOrder(2))
		(_cTab)->(DBGoTop())

	//Linha
	Case _nColuna == 6 

		DBSelectArea(_cTab)
		(_cTab)->(DBSetOrder(3))
		(_cTab)->(DBGoTop()) 

	Case _nColuna == 9

		DBSelectArea(_cTab)
		(_cTab)->(DBSetOrder(4))
		(_cTab)->(DBGoTop())

	EndCase

MGLT027L(_nColuna)

oBrowse:DrawSelect()
oBrowse:Refresh(.T.)

Return

/*
===============================================================================================================================
Programa----------: MGLT027L
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 12/01/2011
Descrição---------: Funcao para setar a coluna com uma imagem que significa que ela esta ordenada ou nao
Parametros--------: ncol - Coluna a atualizar
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGLT027L(_nCol)  

Local _aColunas	:= {}
Local _nX		:= 0

aAdd(_aColunas,{4})
aAdd(_aColunas,{6})
aAdd(_aColunas,{7})
aAdd(_aColunas,{11})

For _nX:=1 To Len(_aColunas)

	//Seta as demais colunas como nao ordenadas
	If _nCol <> _aColunas[_nX,1]
		oBrowse:SetHeaderImage(_aColunas[_nX,1],"COLRIGHT")
	Else
		//Seta a coluna com a imagem que significa que ela foi ordenada
		oBrowse:SetHeaderImage(_aColunas[_nX,1],"COLDOWN")
	EndIf
Next _nX

Return

/*
===============================================================================================================================
Programa----------: MGLT0270
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 12/01/2011
Descrição---------: Funcao para setar a coluna com uma imagem que significa que ela esta ordenada ou nao
Parametros--------: ncol - Coluna a atualizar
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGLT0270(_cTab)

Local _oDlg
Local _aComboBx1:= {"Produtor+Loja","Descrição do Produtor","Linha","Volume"}
Local _nOpca	:= 0
Local _nI		:= 0

Private cGet1	:= Space(10)
Private oGet1
Private cComboBx1:= ""

@ 178,181 TO 259,697 Dialog _oDlg Title "Pesquisar"

@ 004,003 ComboBox cComboBx1 Items _aComboBx1 Size 213,010 PIXEL OF _oDlg ON CHANGE MGLT0271()
@ 020,003 MsGet oGet1 Var cGet1 Size 212,009 COLOR CLR_BLACK Picture "X999999999" PIXEL OF _oDlg

DEFINE SBUTTON FROM 004,227 Type 1 ENABLE ACTION (_nOpca:=1,_oDlg:End()) OF _oDlg
DEFINE SBUTTON FROM 021,227 Type 2 ENABLE ACTION (_nOpca:=0,_oDlg:End()) OF _oDlg

ACTIVATE MSDIALOG _oDlg CENTERED

If _nOpca == 1

	If (Len(AllTrim(cGet1)) > 0 .And. Type("cGet1") == 'C') .Or. (Type("cGet1") == 'N' .And. cGet1 > 0 ) .Or. (Type("cGet1") == 'D' .And. cGet1 <> CtoD(" ") )

		For _nI := 1 To Len(_aComboBx1)
			If cComboBx1 == _aComboBx1[_nI]
					DBSelectArea(_cTab)
					(_cTab)->(DBSetOrder(_nI))
					MsSeek(cGet1,.T.)
					oBrowse:DrawSelect()
					oBrowse:Refresh(.T.)
			EndIf
		Next _nI
	Else
		MsgAlert("Favor informar um conte=do a ser pesquisado.","MGLT02716")
	EndIf

EndIf

Return

/*
===============================================================================================================================
Programa----------: MGLT0271
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 12/01/2011
Descrição---------: Aletara a mascara do campo de pesquisa de acordo com a pcao selecionada pelo usuario.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
Static Function MGLT0271()

	If cComboBx1 == "Produtor+Loja"
		cGet1	 := Space(10)
		oGet1:Picture:= "X999999999"
	ElseIf cComboBx1 == "Descrição do Produtor"
		cGet1:= Space(40)
		oGet1:Picture:= "@!"
	ElseIf cComboBx1 == "Linha"
		cGet1:= Space(6)  
		oGet1:Picture:= "999999"
	ElseIf cComboBx1 == "Volume"
		cGet1:= Space(12)
		oGet1:Picture:= PesqPict("ZZF","ZZF_VOLUME")  
		cGet1:= 0
	EndIf

	oGet1:SetFocus()

Return

/*
===============================================================================================================================
Programa----------: MGLT0272
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 12/01/2011
Descrição---------: Chama tela para visualizacao dos dados do complemento.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGLT0272()

Local _aArea:= FWGetArea()

Local _aRotBack,_cCadBack

// Caso exista, faz uma copia do aRotina
If Type( "aRotina" ) == "A"
	_aRotBack := AClone( aRotina )
EndIf

// Caso exista, faz uma copia do cCadastro
If Type( "cCadastro" ) == "C"
	_cCadBack := cCadastro
EndIf

AxVisual( "ZZE", ZZE->( Recno() ), 1 )

// Restaura o aRotina
If ValType( _aRotBack ) == "A"
	aRotina := AClone( _aRotBack )
EndIf

// Caso exista, faz uma copia do cCadastro
If Type( "_cCadBack" ) == "C"
	cCadastro := _cCadBack
EndIf

FWRestArea(_aArea)

Return

/*
===============================================================================================================================
Programa----------: MGLT0273
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 12/01/2011
Descrição---------: Funcao usada para realizar a impressao do relatorio de conferencia do complemento de pagamento na tela de
					efetivacao dos registros de complemento de pagamento.
Parametros--------: _cTab - Alias do arquivo temporario criado.
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGLT0273(_cTab)

Local _aArea		:= FWGetArea()
Local   _nSomatVol	:= 0
Local   _nSomatVlr	:= 0

Private oFont10
Private oFont10b
Private oFont12
Private oFont12b
Private oFont16b
Private oFont14
Private oFont14b
Private oPrint
Private nPagina		:= 1
Private nLinha		:= 0100
Private nColInic	:= 0030
Private nColFinal	:= 3360 
Private nqbrPagina	:= 2200 
Private nLinInBox
Private nSaltoLinha	:= 50     
Private oBrush		:= TBrush():New( ,CLR_LIGHTGRAY)

Define Font oFont10    Name "Courier New"       Size 0,-08       // Tamanho 14
Define Font oFont10b   Name "Courier New"       Size 0,-08 Bold   // Tamanho 14
Define Font oFont12    Name "Courier New"       Size 0,-10       // Tamanho 12
Define Font oFont12b   Name "Courier New"       Size 0,-10 Bold  // Tamanho 12 Negrito
Define Font oFont14    Name "Courier New"       Size 0,-10       // Tamanho 14
Define Font oFont14b   Name "Courier New"       Size 0,-10 Bold  // Tamanho 14 
Define Font oFont16b   Name "Helvetica"         Size 0,-14 Bold  // Tamanho 16 Negrito

oPrint:= TMSPrinter():New("COMPLEMENTO DE PAGAMENTO")
oPrint:SetPaperSize(9)	// Seta para papel A4
oPrint:SetLandscape() // Paisagem

/// startando a impressora
oPrint:Say(0,0," ",oFont12,100)

oPrint:StartPage()
//0 - para nao imprimir a numeracao de pagina na emissao da pagina de parametros
MGLT0274(1)
nlinha+=nSaltoLinha
MGLT0275()

DBSelectArea(_cTab)
(_cTab)->(DBGoTop())

While (_cTab)->(!Eof())

	_nSomatVol += &(_cTab+'->'+_cTab+'_VOLUME')
	_nSomatVlr += &(_cTab+'->'+_cTab+'_VLRTOT' )

	nlinha+=nSaltoLinha
	oPrint:Line(nLinha,nColInic,nLinha,nColFinal)

	MGLT0279(0,0,0)

	MGLT0276(&(_cTab+'->'+_cTab+'_CODIGO'),&(_cTab+'->'+_cTab+'_FORNEC'),&(_cTab+'->'+_cTab+'_LOJA'),&(_cTab+'->'+_cTab+'_A2NOME'),;
				&(_cTab+'->'+_cTab+'_LINHA'),&(_cTab+'->'+_cTab+'_DCLIN'  ),&(_cTab+'->'+_cTab+'_VALOR'),&(_cTab+'->'+_cTab+'_VOLUME'),;
				&(_cTab+'->'+_cTab+'_VLRTOT' ),&(_cTab+'->'+_cTab+'_STAT'))

(_cTab)->(DBSkip())
EndDo

nlinha+=nSaltoLinha
MGLT0278()

nlinha+=nSaltoLinha

MGLT0279(0,1,1)
MGLT0277(_nSomatVol,_nSomatVlr)

oPrint:EndPage()	// Finaliza a Pagina.
oPrint:Preview()	// Visualiza antes de Imprimir.

FWRestArea(_aArea)

Return

/*
===============================================================================================================================
Programa----------: MGLT0274
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 12/01/2011
Descrição---------: Funcao utilizada para criar o cabecalho do relatorio de conferencia de complemento.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGLT0274(impNrPag)

Local _cRaizServer	:= If(issrvunix(), "/", "\")    
Local _cTitulo		:= "Relatório para conferência de complemento de pagamento"

nLinha:=0100

oPrint:SayBitmap(nLinha,nColInic,_cRaizServer + "system/lgrl01.bmp",250,100)

If impNrPag <> 0
	oPrint:Say (nlinha,(nColInic + 2750),"PÁGINA: " + AllTrim(Str(nPagina)),oFont12b)
Else
	oPrint:Say (nlinha,(nColInic + 2750),"SIGA/MGLT027",oFont12b)
	oPrint:Say (nlinha + 100,(nColInic + 2750),"EMPRESA: " + AllTrim(SM0->M0_NOME) + '/' + AllTrim(SM0->M0_FILIAL),oFont12b)
EndIf

oPrint:Say (nlinha + 50,(nColInic + 2750),"DATA DE EMISSÃO: " + DToC(DATE()),oFont12b)
nlinha+=(nSaltoLinha * 3)

oPrint:Say (nlinha,nColFinal / 2,_cTitulo,oFont16b,nColFinal,,,2)

nlinha += nSaltoLinha
nlinha += nSaltoLinha

oPrint:Line(nLinha,nColInic,nLinha,nColFinal)

Return

/*
===============================================================================================================================
Programa----------: MGLT0275
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 12/01/2011
Descrição---------: Funcao utilizada para criar o cabecalho dos dados do relatorio de conferencia de complemento.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGLT0275()

nLinInBox:= nlinha

oPrint:FillRect({(nlinha+3),nColInic,nlinha + nSaltoLinha,nColFinal},oBrush)

oPrint:Say (nlinha,nColInic + 10  ,"Codigo"				,oFont12b) 
oPrint:Say (nlinha,nColInic + 295 ,"Produtor"			,oFont12b)
oPrint:Say (nlinha,nColInic + 590 ,"Loja"				,oFont12b)
oPrint:Say (nlinha,nColInic + 735 ,"Descrição Produtor"	,oFont12b)
oPrint:Say (nlinha,nColInic + 1485,"Linha"				,oFont12b)
oPrint:Say (nlinha,nColInic + 1680,"Descrição Linha"	,oFont12b)
oPrint:Say (nlinha,nColInic + 2310,"Valor"				,oFont12b)
oPrint:Say (nlinha,nColInic + 2575,"Volume"				,oFont12b)
oPrint:Say (nlinha,nColInic + 2850,"Valor Total"		,oFont12b)
oPrint:Say (nlinha,nColInic + 3145,"Status"				,oFont12b)

Return

/*
===============================================================================================================================
Programa----------: MGLT0276
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 12/01/2011
Descrição---------: Funcao utilizada para imprimir os dados do relatorio de conferencia de complemento.	
Parametros--------: _cCodigo	Código da recepção	
					_cCodProd	Código do produtor
					_cLjProd	Loja do produtor
					_cDescProd	Nome do produtor
					_cLinha		Linha/Rota
					_cDescLinh	Nome da Linha/Rota
					_nValor		Valor do complemento
					_nVolume	Volume do complemento
					_nVlrTotal	Valor total da recepção
					_cStatus	Status do mix
Retorno-----------: Nenhum
===============================================================================================================================
*/  
Static Function MGLT0276(_cCodigo,_cCodProd,_cLjProd,_cDescProd,_cLinha,_cDescLinh,_nValor,_nVolume,_nVlrTotal,_cStatus)

oPrint:Say (nlinha,nColInic + 10  ,_cCodigo										,oFont12) 
oPrint:Say (nlinha,nColInic + 295 ,_cCodProd									,oFont12)
oPrint:Say (nlinha,nColInic + 590 ,_cLjProd										,oFont12)
oPrint:Say (nlinha,nColInic + 735 ,SubStr(_cDescProd,1,32)  					,oFont12)
oPrint:Say (nlinha,nColInic + 1485,_cLinha										,oFont12)
oPrint:Say (nlinha,nColInic + 1680,SubStr(_cDescLinh,1,27)						,oFont12)
oPrint:Say (nlinha,nColInic + 2290,Transform(_nValor,"@E 99.9999") 				,oFont12)
oPrint:Say (nlinha,nColInic + 2475,Transform(_nVolume,"@E 999,999,999")			,oFont12)
oPrint:Say (nlinha,nColInic + 2730,Transform(_nVlrTotal,"@E 999,999,999.9999")	,oFont12)
oPrint:Say (nlinha,nColInic + 3120,_cStatus										,oFont12)

Return

/*
===============================================================================================================================
Programa----------: MGLT0277
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 12/01/2011
Descrição---------: Funcao utilizada para imprimir o totalizador dos dados do relatorio de conferencia de complemento.
Parametros--------: _nVolume - Volume dos complementos
					  _nValor - Valor dos complementos
Retorno-----------: Nenhum
===============================================================================================================================
*/  
Static Function MGLT0277(_nVolume,_nValor)

oPrint:Say (nlinha,nColInic + 10  ,"TOTAL->"								,oFont12b)
oPrint:Say (nlinha,nColInic + 2475,Transform(_nVolume,"@E 999,999,999")		,oFont12b)
oPrint:Say (nlinha,nColInic + 2730,Transform(_nValor,"@E 999,999,999.9999")	,oFont12b)

Return 

/*
===============================================================================================================================
Programa----------: MGLT0278
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 12/01/2011
Descrição---------: Funcao utilizada para desenhar o box do relatorio de conferencia de complemento.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGLT0278()

oPrint:Line(nLinInBox,290 ,nLinha,290 )
oPrint:Line(nLinInBox,585 ,nLinha,585 )
oPrint:Line(nLinInBox,730 ,nLinha,730 )
oPrint:Line(nLinInBox,1480,nLinha,1480)
oPrint:Line(nLinInBox,1675,nLinha,1675)
oPrint:Line(nLinInBox,2305,nLinha,2305)
oPrint:Line(nLinInBox,2470,nLinha,2470)
oPrint:Line(nLinInBox,2765,nLinha,2765)
oPrint:Line(nLinInBox,3140,nLinha,3140)

oPrint:Box(nLinInBox,nColInic,nLinha,nColFinal)

Return

/*
===============================================================================================================================
Programa----------: MGLT0279
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 12/01/2011
Descrição---------: Funcao utilizada para quebrar de pagina os dados do relatorio de conferencia de complemento.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
Static Function MGLT0279(nLinhas,impBox,impCabec)   

//Quebra de pagina
If nLinha > nqbrPagina

	nlinha:= nlinha - (nSaltoLinha * nLinhas)

	If impBox == 0
		MGLT0278()
	EndIf

	oPrint:EndPage()// Finaliza a Pagina.
	oPrint:StartPage()//Inicia uma nova Pagina
	nPagina++
	MGLT0274(1)//Chama cabecalho
	nlinha+=nSaltoLinha

	If impCabec == 0
		MGLT0275()
		nlinha+=nSaltoLinha
	EndIf
EndIf

Return

/*
===============================================================================================================================
Programa----------: MGLT027_1
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 12/01/2011
Descrição---------: Funcao usada para realizar a validacao da efetivacao do complemento de pagamento.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGLT027_1()

Local _lRet 		:= .T.
Private _cAliasZLE	:= GetNextAlias()

//=========================================================
//Verifica se o usuario selecionou no minimo um registro de
//complemento de pagamento a ser efetivado
//=========================================================
If nQtdTit == 0
	MsgStop("Para realizar a efetivação de um complemento é necessário que se selecione no mínimo um registro.","MGLT02717")
	_lRet:= .F.
EndIf

//=============================================================
//Verifica o status do Mix de destino este deve estar em aberto
//=============================================================
If _lRet

	MsgRun("Verificando Status do MIX de destino...",,{||CursorWait(),MGLT027Q(1,MV_PAR01,"","",""), CursorArrow()}) 

	DBSelectArea(_cAliasZLE)
	(_cAliasZLE)->(DBGoTop())

	If (_cAliasZLE)->ZLE_STATUS == 'F'
		MsgStop("Não será possível realizar a efetivação dos complemento pois o mix de destino: " + MV_PAR01 + " encontra-se fechado.", "MGLT02718")
		_lRet:= .F.
	Else
		_dDtIniMix:= SToD((_cAliasZLE)->ZLE_DTINI)
		_dDtFinMix:= SToD((_cAliasZLE)->ZLE_DTFIM)
	EndIf

	(_cAliasZLE)->(DBCloseArea())

EndIf

Return _lRet

/*
===============================================================================================================================
Programa----------: MGLT027_2
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 12/01/2011
Descrição---------: Funcao utilizada para realizar a efetivacao do complemento, ou seja, realizar a insercao dos eventos de 
					debito	e credito no mix para comporem custo do complemento, insercao financeiro do pagamento do 
					complemento e e atualizacao do status das tabelas de cabecalho e itens do complemento de pagamento.
Parametros--------: _ctab - Alias da tabela temporaria
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGLT027_2(_cTab)

Local _aRegSelec	:= {} // Armazena os dados dos registros selecionados a serem efetivados 
Local _aRegDesma	:= {} // Armazena os dados dos registros a serem cancelados, ou seja, nao seram efetivados
Local _nCountRec	:= 0
Local _nX			:= 0 
Local _lRet			:= .T.
Local _aEventos		:= {}
Local _nPosEvent	:= 0
Local _cRegNSel		:= "" //Armazena os registro de complemento para cancelamento
Local _cFilLinha	:= "" 
Local _lProdInv		:= .F.
Local _cQuery		:= ""

Private _cAliasEfe

//================================================================
//Verifica os registros de complemento que foram selecionados
//e os que nao foram selecionados pelo usuario isto sera usado
//para gerar o financeiro e atualizacao do mix bem como demonstrar
//os registros de complemento que foram cancelados
//================================================================
(_cTab)->(DBGoTop())

While (_cTab)->(!Eof()) 

	//=======================================
	//Verifica se a linha nao foi selecionada
	//=======================================
	If &(_cTab+'->'+_cTab+'_STATUS') == Space(2)
	
		aAdd(_aRegDesma,{&(_cTab+'->'+_cTab+'_CODIGO'),&(_cTab+'->'+_cTab+'_FORNEC'),&(_cTab+'->'+_cTab+'_LOJA'),;
						&(_cTab+'->'+_cTab+'_A2NOME'),&(_cTab+'->'+_cTab+'_LINHA'),&(_cTab+'->'+_cTab+'_DCLIN'  ),;
						&(_cTab+'->'+_cTab+'_VALOR'),&(_cTab+'->'+_cTab+'_VOLUME'),&(_cTab+'->'+_cTab+'_VLRTOT' ),&(_cTab+'->'+_cTab+'_RECNO' ),;
						&(_cTab+'->'+_cTab+'_SETOR'),&(_cTab+'->'+_cTab+'_DTCRED')}) 
	Else  
		aAdd(_aRegSelec,{&(_cTab+'->'+_cTab+'_CODIGO'),&(_cTab+'->'+_cTab+'_FORNEC'),&(_cTab+'->'+_cTab+'_LOJA'),;
						&(_cTab+'->'+_cTab+'_A2NOME'),&(_cTab+'->'+_cTab+'_LINHA'),&(_cTab+'->'+_cTab+'_DCLIN'  ),;
						&(_cTab+'->'+_cTab+'_VALOR'),&(_cTab+'->'+_cTab+'_VOLUME'),&(_cTab+'->'+_cTab+'_VLRTOT' ),&(_cTab+'->'+_cTab+'_RECNO'),;
						.T.,0,&(_cTab+'->'+_cTab+'_SETOR'),&(_cTab+'->'+_cTab+'_DTCRED')}) 

	EndIf

	(_cTab)->(DBSkip())
EndDo

//====================================================================================
//Realiza a insercao dos dados dos complementos selecionados a serem efetivados no Mix
//====================================================================================

//=======================================================================
//Pesquisa os codigo dos eventos: um de credito e outro de debito a serem
//utilizados na geracao dos eventos que fazem parte da composicao
//do custo do complemento de pagamento
//=======================================================================
MsgRun("Filtrando os eventos para geração do complemento...",,{||CursorWait(), MGLT027Q(2,"","","",""), CursorArrow()})
_nCountRec := _nContReg                

//=================================================================
//Devera existir dois eventos cadastrados para realizar esta rotina
//um para geracao do credito e para o debito ao produtor
//=================================================================
If _nCountRec == 2                  
		 

	(_cAliasZL8)->(DBGoTop())
					           			
	//=============================================================
	//Verifica se existem dois eventos um de credito e um de debito
	//para geracao do complemento de pagamento no Mix
	//=============================================================

	While (_cAliasZL8)->(!Eof())

		_nPosEvent:= aScan(_aEventos,{|x| x[3] == (_cAliasZL8)->ZL8_DEBCRE})

		If _nPosEvent == 0

			aAdd(_aEventos,{(_cAliasZL8)->ZL8_COD,(_cAliasZL8)->ZL8_NREDUZ,(_cAliasZL8)->ZL8_DEBCRE,;
							(_cAliasZL8)->ZL8_SB1COD,(_cAliasZL8)->ZL8_MIX})

		EndIf

		(_cAliasZL8)->(DBSkip())
	EndDo

	(_cAliasZL8)->(DBCloseArea())

	//==========================================================
	//Verifica se foram lancados os dois eventos um de credito e
	//outro de debito para geracao do complemento
	//==========================================================
	If Len(_aEventos) == 2

		//===============================================================
		//Verifica quais os produtores poderao passar pelo rotina de efe-
		//tivacao pois podem estar com o status do mix fechado/efetivado,
		//ou seja, podem ter passado pela rotina de fechamento individual,
		//por exemplo fechar somente o produtor P00001 e posteriormente
		//a isso tentar efetuar a efetivacao de um complemento para ele.
		//===============================================================
		aEval(_aRegSelec,{|e| IIf(AllTrim(e[5])$_cFilLinha,,_cFilLinha += ";" + AllTrim(e[5]))}) 
		_cFilLinha:= SubStr(_cFilLinha,2,Len(_cFilLinha))
		_cAliasEfe:= GetNextAlias()

		MsgRun("Verificando status dos produtores selecionados para efetivação...",,{||CursorWait(), , CursorArrow()})

		//===========================================================
		//Verifica os produtores que estao com o status fechado, para 
		//que os mesmos nao possam ser efetivados
		//===========================================================
		_cQuery := "% AND ZLF.ZLF_LINROT IN " + FormatIn(AllTrim(_cFilLinha),";") + "%"
			
		BeginSql Alias _cAliasEfe
			SELECT ZLF.ZLF_LINROT
			FROM %Table:ZLF% ZLF, %Table:ZL8% ZL8
			WHERE ZLF.D_E_L_E_T_ = ' '
			AND ZL8.D_E_L_E_T_ = ' '
			AND ZLF_FILIAL = %xFilial:ZLF%
			AND ZL8_FILIAL = %xFilial:ZL8%
			AND ZL8.ZL8_COD = ZLF.ZLF_EVENTO
			AND ZL8.ZL8_PERTEN = 'P'
			AND ZLF.ZLF_STATUS IN ('F','E')
			%exp:_cQuery%
			AND ZLF.ZLF_CODZLE = %exp:MV_PAR01%
			GROUP BY ZLF.ZLF_LINROT
		EndSql

		COUNT TO _nCountRec //Contabiliza o numero de registros encontrados pela query
		(_cAliasEfe)->(DBGoTop())

		If _nCountRec > 0

			While (_cAliasEfe)->(!Eof())

				//================================================================
				//Verfica as linhas que foram efetivadas para cancelar todas
				//os produtores daquela linha, ou seja, nao gerar a sua efetivacao
				//================================================================
				For _nX:=1 to Len(_aRegSelec)   
					If AllTrim(_aRegSelec[_nX,5]) == AllTrim((_cAliasEfe)->ZLF_LINROT)
						_lProdInv := .T.
						_aRegSelec[_nX,11]:= .F. 
					EndIf 
				Next _nX

				(_cAliasEfe)->(DBSkip())
			EndDo

		EndIf 

		(_cAliasEfe)->(DBCloseArea())

		//==========================================================
		//Emite mensagem dos produtores selecionados que nao poderao
		//ser efetivados devido a estarem efetivados ou fechados
		//==========================================================
		If _lProdInv 
			MsgStop("Existe(m) produtor(es) que não foi(ram) efetivado(s) devido ao seu status estar(em) efetivado ou fechado no mix."+;
					"Favor checar o status dos produtores que deseja realizar a efetivação do complemento de pagamento antes de realiza-lo.","MGLT02719")
		EndIf

		Begin Transaction

			//================================================================
			//Efetua a inserção dos eventos de complemento de pagamento no Mix
			//================================================================
			Processa({|| MGLT027F(_aRegSelec,_aEventos) },"Inclusão dos eventos de complemento no Mix.")

			//===============================================================
			//Efetua a insercao no financeiro dos registros de complemento
			//selecionados, caso nao tenha encontrado erro na inclusao do mix
			//===============================================================
			Processa({|| _lRet:= MGLT027_3(_aRegSelec) },"Inclusão financeira do complemento de pagamento.")

			If _lRet

				aEval(_aRegDesma,{|e| _cRegNSel  += "," + AllTrim(Str(e[10]))})
				_cRegNSel := SubStr(_cRegNSel,2,Len(_cRegNSel))
				// Ajusta status dos registros que não foram selecionados para processamento
				If Len(AllTrim(_cRegNSel)) > 0
					_cQuery := "UPDATE "    
					_cQuery += RetSqlName("ZZF") + " ZZF "    
					_cQuery += "SET ZZF_STATUS = '3' "
					_cQuery += "WHERE"  
					_cQuery += " D_E_L_E_T_ = ' '"
					_cQuery += " AND R_E_C_N_O_ IN ("+ _cRegNSel      + ")"          
					If TCSqlExec( _cQuery ) < 0
						MsgStop( "Erro ao atualizar Registros: "+AllTrim(TCSQLError()),"AGLT01501")
						_lRet := .F.
					EndIf
				EndIf

			EndIf

			//===========================================================
			//Caso encontre algum problema na efetivacao dos complementos
			//de pagamento a transacao eh desarmada
			//===========================================================
			If !_lRet
				DisarmTransaction()
			EndIf  

		End Transaction

		//===========================================================
		//Nao existe um evento de credito e um debito cadastrados nos
		//eventos para geracao dos dados do complemento de pagamento
		//===========================================================
		Else
			MsgStop("Existem dois eventos cadastrados para a geração do complemento de pagamento. Deve existir um evento de crédito e outro de "+;
					"débito para realizar a geração do complemento de pagamento, favor comunicar ao responsável para realizar a alteração no cadastro "+;
					"de eventos.", "MGLT02720")
			_lRet:= .F.	
		EndIf
				
//=====================================================
//Problema encontrado no evento cadastrado para geracao
//do complemento de pagamento
//=====================================================
Else
	MsgStop("Verificar se foi cadastrado algum evento para geração do complemento de pagamento ao Produtor. "+;
			"A de se ressaltar que deverão ser cadastrados dois eventos um de crédito e outro de débito para geração do complemento.","MGLT02721")
	_lRet:= .F.
EndIf

Return

/*
===============================================================================================================================
Programa----------: MGLT027_3
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 12/01/2011
Descrição---------: Inclui titulo no contas a pagar via SigaAuto.
Parametros--------: aRegCompl - array contendo os registro de complemento
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGLT027_3(_aRegCompl)

Local _aArea		:= FWGetArea()
Local _lRet			:= .T.
Local _nX			:= 0
Local _lDeuErro		:= .F.        
Local _nModAnt		:= nModulo
Local _cModAnt		:= cModulo
Local _aAutoSE2		:= {}
Local _lNoExist		:= .T.
Local _cNroTit		:= ''
Local _nTamPar		:= TamSX3("E2_PARCELA")[1]
Local _cParcela		:= ""
Local _cTipo		:= PadR("NF",TamSX3("E2_TIPO")[1])     
Local _cCodMIX		:= MV_PAR01
Local _cVersao		:= "1"
Local _cVencto		:= ''
Local _cNatureza	:= AllTrim(SuperGetMV("LT_ADICOMP",.F.,"222003"))//Chama a natureza para geracao dos titulos do adiantamento de complemento
Local _cHistTit		:= 'COMPLEMENTO PGTO PRODUTOR'
Local _cSeek 		:= ''
Local _cSetor		:= ''
Local _nVlrTit		:= 0
Local _cLinha		:= ''
Local _cMatUsr		:= FWSFAllUsers({RetCodUsr()},{"USR_FILIAL","USR_CODFUNC"})[1][3]+FWSFAllUsers({RetCodUsr()},{"USR_FILIAL","USR_CODFUNC"})[1][4]
Private lMsErroAuto	:= .F.
Private lMsHelpAuto	:= .T.

ProcRegua(Len(_aRegCompl))

For _nX:=1 to Len(_aRegCompl)

//=======================================================================
//Verifica os registros que foram selecionados para serem efetivados que
//podem gerar financeiro, ou seja, que nao estejam efetivados ou fechados
//=======================================================================
	If _aRegCompl[_nX,11]

		IncProc()

		_cNroTit:= _aRegCompl[_nX,1]
		_cParcela:= StrZero(1,_nTamPar)
		_nVlrTit:= _aRegCompl[_nX,12] //Valor do titulo líquido, descontando os impostos
		_cLinha	:= _aRegCompl[_nX,5] //Linha que o produtor pertence
		_cSetor	:= _aRegCompl[_nX,13]
		_cSeek	:= _cNroTit + '-' + _cCodMIX + '-' + _cVersao + '-' + "MGLT027"
		_cVencto:= _aRegCompl[_nX,14]

		DBSelectArea("SA2") 
		SA2->(DBSetOrder(1))
		If SA2->(DBSeek(xFilial("SA2") + _aRegCompl[_nX,2] + _aRegCompl[_nX,3]))

			//==========================================================
			// Verifica se o titulo ja existe na base, para nao duplicar
			//==========================================================
			DBSelectArea("SE2")
			SE2->(DBSetOrder(1))
			If SE2->(DBSeek(xFilial("SE2")+_cPrefixo+_cNroTit+_cParcela+_cTipo+SA2->A2_COD+SA2->A2_LOJA))

				_lDeuErro := .T.
				_lNoExist := .F.

				MsgAlert("O titulo: "+xFilial("SE2")+_cPrefixo+_cNroTit+_cParcela+_cTipo+;
				" ja existe para o produtor: "+SA2->A2_COD+"/"+SA2->A2_LOJA+"-"+SA2->A2_NOME+;
				". Verifique no financeiro porque ja existe um titulo com estas caracteristicas e exclua-o.","MGLT02722")
			
				If MsgYesNo("Deseja gerar o titulo com uma nova parcela?")
				
					_cParcela:= Soma1(_cParcela)
					_lNoExist:= .T.
					_lDeuErro:= .F.

				EndIf
			EndIf

			If _lNoExist

				// Array com os dados a serem passados para o SigaAuto
				_aAutoSE2:={{"E2_PREFIXO",_cPrefixo		,Nil},;
				{"E2_NUM"    ,_cNroTit					,Nil},;
				{"E2_TIPO"   ,_cTipo					,Nil},;
				{"E2_PARCELA",_cParcela					,Nil},;
				{"E2_NATUREZ",_cNatureza				,Nil},;
				{"E2_FORNECE",SA2->A2_COD				,Nil},;
				{"E2_LOJA"   ,SA2->A2_LOJA				,Nil},;
				{"E2_EMISSAO",Date()					,Nil},;
				{"E2_VENCTO" ,_cVencto		 			,Nil},;
				{"E2_VENCREA",DataValida(_cVencto)		,Nil},;
				{"E2_HIST"   ,_cHistTit					,Nil},;
				{"E2_VALOR"  ,_nVlrTit					,Nil},;
				{"E2_PORCJUR",0							,Nil},;
				{"E2_DATALIB",Date()					,Nil},;
				{"E2_USUALIB",cUserName					,Nil},;
				{"E2_L_LINRO",_cLinha					,Nil},;
				{"E2_L_SETOR",_cSetor					,Nil},;
				{"E2_L_MIX"  ,_cCodMIX					,Nil},;
				{"E2_L_SEEK" ,_cSeek					,Nil},;
				{"E2_ORIGEM" ,"MGLT027"					,Nil}}

				// Altera o modulo para Financeiro, senao o SigaAuto nao executa
				nModulo := 6
				cModulo := "FIN"

				//Roda SigaAuto de inclusao de Titulos a Pagar
				MSExecAuto({|x,y| Fina050(x,y)},_aAutoSE2,3)

				// Restaura o modulo em uso
				nModulo := _nModAnt
				cModulo := _cModAnt

				// Verifica se houve erro no SigaAuto, caso haja mostra o erro
				If lMsErroAuto
					_lDeuErro := .T.
					Mostraerro() 
				Else
					DBSelectArea("SE2")
					SE2->(DBSetOrder(1))
					SE2->(DBGoTop()) 
					If SE2->(DBSeek(xFilial("SE2")+_cPrefixo+_cNroTit+_cParcela+_cTipo+SA2->A2_COD+SA2->A2_LOJA))

						RecLock("SE2",.F.)

							If SA2->A2_L_TPPAG == "B"   

								SE2->E2_L_TPPAG	:= SA2->A2_L_TPPAG
								SE2->E2_L_BANCO	:= SA2->A2_BANCO
								SE2->E2_L_AGENC := SA2->A2_AGENCIA
								SE2->E2_L_CONTA	:= SA2->A2_NUMCON   

							EndIf

						SE2->(MSUnLock())

					EndIf
					//Atualiza Item do registro
					ZZF->(DBGoTo(_aRegCompl[_nX,10])) 
					RecLock("ZZF",.F.)
						ZZF->ZZF_STATUS	:= '2'
					ZZF->(MSUnLock())
					//Atualiza Cabeçalho do registro
					If ZZE->(DBSeek(xFilial("ZZE")+_aRegCompl[_nX,1])) .And. ZZE->ZZE_STATUS <> '2'
						RecLock("ZZE",.F.)
							ZZE->ZZE_STATUS	:= '2'
							ZZE->ZZE_USREFE = _cMatUsr
						 ZZE->(MSUnLock())
					EndIf
				EndIf
			EndIf   
			//Produtor nao cadastrado no cadastro de fornecedor
		Else
			_lDeuErro := .T.
			MsgStop("Não foi encontrado o cadastro do Fornecedor: " + _aRegCompl[x,2] + _aRegCompl[x,3]+;
					". Favor contactar o departamento de informática, a operação de efetivação será cancelada.","MGLT02723")
		EndIf
	Else
		ZZF->(DBGoTo(_aRegCompl[_nX,10])) 
		RecLock("ZZF",.F.)
			ZZF->ZZF_STATUS	:= '4'
		ZZF->(MSUnLock())
	EndIf
Next _nX

FWRestArea(_aArea)

_lRet:= !_lDeuErro

Return _lRet

/*
===============================================================================================================================
Programa----------: MGLT027_4
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 12/01/2011
Descrição---------: Deleta os registros do complemento gerados nas tabelas ZZF
Parametros--------: _cCodCompl, _nCountRec
Retorno-----------: _lRet
===============================================================================================================================
*/
Static Function MGLT027_4(_cCodCompl,_nCountRec)     

Local _lRet:= .T.

ProcRegua(_nCountRec)

While (_cAliExZZF)->(!Eof()) 

	IncProc()

	DBSelectArea("ZZF") 
	ZZF->(DBGoTo((_cAliExZZF)->RECNOZZF))

	If ZZF->ZZF_CODIGO == _cCodCompl 

		RecLock("ZZF",.F.)
			DbDelete()
		ZZF->(MSUnLock())

	Else
		MsgStop("Erro ao excluir um determinado registro dos itens do complemento de pagamento: " + _cCodCompl +;
				"Favor comunicar ao departamento de informática do problema encontrado, dados do registro para delete: Codigo: " + ZZF->ZZF_CODIGO + " Produtor: " + ZZF->ZZF_FORNEC + " Loja: " + ZZF->ZZF_LJFORN,"MGLT02724")
		_lRet:= .F.
		Exit
	EndIf

	(_cAliExZZF)->(DBSkip())
EndDo

(_cAliExZZF)->(DBCloseArea())

Return _lRet

/*
===============================================================================================================================
Programa----------: MGLT027_5
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 12/01/2011
Descrição---------: Deleta os registros do complemento gerados nas tabelas: ZZE e ZZF.
Parametros--------: _cCodCompl
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGLT027_5(_cCodCompl) 

Local _lRet    := .T.
Local _nCountRec:= 0

Private _cAliExZZF:= GetNextAlias() 

//==========================================================================
// Chama funcao para selecionar os registros a serem excluidos na tabela ZZF
//==========================================================================
BeginSql Alias _cAliExZZF
	SELECT R_E_C_N_O_ RECNOZZF
	FROM %Table:ZZF% ZZF
	WHERE D_E_L_E_T_ = ' '
	AND ZZF_FILIAL = %xFilial:ZZF%
	AND ZZF_CODIGO = %exp:ZZE->ZZE_CODIGO%
EndSql

COUNT TO _nCountRec //Contabiliza o numero de registros encontrados pela query
(_cAliExZZF)->(DBGoTop())

If _nCountRec > 0

	Processa({|| _lRet:= MGLT027_4(_cCodCompl,_nCountRec) },"Deleta registros dos intes do complemento")

	//========================================================
	//Deleta registro do cabecalho do complemento de pagamento
	//========================================================
	If _lRet

		DBSelectArea("ZZE")
		ZZE->(DBSetOrder(1))
		If ZZE->(DBSeek(xFilial("ZZE") + _cCodCompl))
			RecLock("ZZE",.F.)
				dbDelete()
			ZZE->(MSUnLock())
		Else
			MsgStop("Não foi encontrado o registro do cabeçalho do complemento de pagamento: " + _cCodCompl, "MGLT02725")
			_lRet:= .F.
		EndIf
	EndIf

Else
	MSgStop("Não foram encontrados registros referente aos Itens do complemento de pagamento: " + ZZE->ZZE_CODIGO, "MGLT02726")
	_lRet:= .F.
EndIf

Return _lRet
 
/*
===============================================================================================================================
Programa----------: MGLT027_6
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 12/01/2011
Descrição---------: Deleta os registros do complemento gerados na tabela ZLF.
Parametros--------: _cCodCompl - Codigo do complemento
					_nCountRec - Quantidade de registros
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGLT027_6(_cCodCompl,_nCountRec) 

Local _lRet:= .T.

ProcRegua(_nCountRec)

(_cAliasExc)->(DBGoTop())

While (_cAliasExc)->(!Eof())

	IncProc()

	DBSelectArea("ZLF")
	ZLF->(DBGoTo((_cAliasExc)->RECNOZLF))

	If _cCodCompl+"MGLT027" == AllTrim(ZLF->ZLF_SEEKCO)
		RecLock("ZLF",.F.)
			dbDelete()
		ZLF->(MSUnLock())
	Else
		MsgStop("Não foi encontrado um determinado registro selecionado para ser excluido na tabela ZLF do complemento de pagamento: " + _cCodCompl +;
				"Favor comunicar ao departamento de informática do problema encontrado, o seek para busca é: " + AllTrim(ZLF->ZLF_SEEKCO),"MGLT02727")
		_lRet:= .F.
		Exit
	EndIf

	(_cAliasExc)->(DBSkip())
EndDo

(_cAliasExc)->(DBCloseArea())

Return _lRet

/*
===============================================================================================================================
Programa----------: MGLT027_7
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 12/01/2011
Descrição---------: Exclui titulo no contas a pagar via SigaAuto.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGLT027_7()

Local _nCountRec		:= 0
Local _lDeuErro			:= .F.
Local _nModAnt			:= nModulo
Local _cModAnt			:= cModulo
Local _lRet				:= .T.

Private lMsErroAuto	:= .F.
Private lMsHelpAuto	:= .T.
Private _cAliasSE2 	:= GetNextAlias()

//====================================================================
//Seleciona os registros de titulos que foram gerados pelo complemento
//de pagamente que se deseja excluir
//====================================================================

BeginSql Alias _cAliasSE2
	SELECT E2_PREFIXO,E2_TIPO,E2_NUM,E2_PARCELA,E2_FORNECE,E2_LOJA
	FROM %Table:SE2% SE2
	WHERE D_E_L_E_T_ = ' '
	AND E2_FILIAL = %xFilial:SE2%
	AND E2_PREFIXO = %exp:_cPrefixo%
	AND E2_L_SEEK = %exp:ZZE->ZZE_CODIGO+'-'+ZZE->ZZE_MIXDES+'-'+'1'+'-'+'MGLT027'%
EndSql

COUNT TO _nCountRec //Contabiliza o numero de registros encontrados pela query
(_cAliasSE2)->(DBGoTop())

If _nContReg > 0 

	ProcRegua(_nCountRec)

	While (_cAliasSE2)->(!Eof()) .And. !_lDeuErro  

		IncProc()

		DBSelectArea("SE2")
		SE2->(DBSetOrder(1))
		If SE2->(DBSeek(xFilial("SE2") + (_cAliasSE2)->E2_PREFIXO + (_cAliasSE2)->E2_NUM + (_cAliasSE2)->E2_PARCELA + (_cAliasSE2)->E2_TIPO + (_cAliasSE2)->E2_FORNECE + (_cAliasSE2)->E2_LOJA))

			// Array com os dados a serem passados para o SigaAuto
			_aAutoSE2:={{"E2_PREFIXO",SE2->E2_PREFIXO,Nil},;
			{"E2_NUM"    ,SE2->E2_NUM    ,Nil},;
			{"E2_TIPO"   ,SE2->E2_TIPO   ,Nil},;
			{"E2_PARCELA",SE2->E2_PARCELA,Nil},;
			{"E2_NATUREZ",SE2->E2_NATUREZ,Nil},;
			{"E2_FORNECE",SE2->E2_FORNECE,Nil},;
			{"E2_LOJA"   ,SE2->E2_LOJA   ,Nil}}

			// Altera o modulo para Financeiro, senao o SigaAuto nao executa
			nModulo := 6
			cModulo := "FIN"

			//Roda SigaAuto de Exclusao de Titulos a Pagar
			MSExecAuto({|x,y,z| Fina050(x,y,z)},_aAutoSE2,.T.,5)

			// Verifica se houve erro no SigaAuto, caso haja mostra o erro. 
			If lMsErroAuto 
				_lDeuErro := .T.  
				_lRet	 := .F.
				MsgStop("O titulo " + xFilial("SE2") + (_cAliasSE2)->E2_PREFIXO + (_cAliasSE2)->E2_NUM + (_cAliasSE2)->E2_PARCELA + (_cAliasSE2)->E2_TIPO+;
				" não foi excluido! Produtor: " + (_cAliasSE2)->E2_FORNECE + "/" + (_cAliasSE2)->E2_LOJA+;
				". Verifique no financeiro se este titulo ja foi baixado ou o motivo pelo qual não pode ser excluído."+;
				" Ao confimar esta tela, sera apresentada a tela do SigaAuto, que possui informações mais detalhadas.","MGLT02728")
				Mostraerro()
			EndIf
			
			// Restaura o modulo em uso
			nModulo := _nModAnt
			cModulo := _cModAnt

		Else

			_lDeuErro := .T.
			_lRet	 := .F.
			MsgStop("O titulo " + xFilial("SE2") + (_cAliasSE2)->E2_PREFIXO + (_cAliasSE2)->E2_NUM + (_cAliasSE2)->E2_PARCELA + (_cAliasSE2)->E2_TIPO+;
			" não foi encontrado! Produtor: " + (_cAliasSE2)->E2_FORNECE + "/" + (_cAliasSE2)->E2_LOJA+;
			". Verifique no financeiro se este titulo existe, pois o mesmo não foi encontrado.","MGLT02729")
		EndIf

		(_cAliasSE2)->(DBSkip())

	EndDo

Else   

	_lRet:= .F.
	MsgStop("Não foram encontrados registros no financeiro para realizar a sua exclusão, referente ao complemento: " + ZZE->ZZE_CODIGO+;
	". Favor comunicar ao departamento de informática do problema ocorrido.", "MGLT02730")

EndIf

(_cAliasSE2)->(DBCloseArea())

Return _lRet
