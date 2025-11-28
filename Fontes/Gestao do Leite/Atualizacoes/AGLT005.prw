/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |28/09/2018| Chamado 26404. Trocado campo ZLU_ALLSET para ZLU_SETALL
Lucas Borges  |07/08/2019| Chamado 30185. Modificada validação de acesso aos setores.
Lucas Borges  |15/08/2019| Chamado 28346. Modificada validação para deleção de registros.
===============================================================================================================================
*/

#Include "TOTVS.ch" 

/*
===============================================================================================================================
Programa----------: AGLT005
Autor-------------: Jeovane
Data da Criacao---: 16/09/2008
Descrição---------: Rotina de manutenção do cadastro de Linhas/Rotas
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT005

Local _cFilter		:= ""

Private cCadastro	:= "Cadastro Linha/Rota"
Private aRotina		:= MenuDef()
Private cAlias		:= "ZL3"

//=====================================================================================
//Obtem Setores que podem ser acessados - 114 - "MBrowse - Visualiza outras filiais"
//Se o usuário visualiza toda as filiais no browse, filtro todos os setores. Do contra-
//ário, filtro só a filial corrente
//=====================================================================================
If Posicione("ZLU",1,xFilial("ZLU")+RetCodUsr(),"ZLU_SETALL") <> 'S'
	_cFilter :="ZL3_SETOR IN "+FormatIn(U_LisSetor(IIf(SubStr(cAcesso,114,1)=='S',.F.,.T.)),";")
EndIf

MBrowse(,,,,cAlias,,,,,,,,,,,,,,_cFilter)


Return

/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 02/08/2018
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
					{ "Incluir"			, "AxInclui" 		, 0 , 3 } ,;
					{ "Alterar"			, "AxAltera" 		, 0 , 4 } ,;
					{ "Excluir"			, "U_AGLT003E"		, 0 , 5 }  }

Return( aRotina )

/*
===============================================================================================================================
Programa----------: AGLT003E
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 02/08/2018
Descrição---------: Funcao usada para apagar registro da ZL3
Parametros--------: cAlias,nReg,nOpc
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT003E(cAlias,nReg,nOpc)

Local bAxParam 	:= {|| .T.}
Local bVldExc	:= {|| U_ChkReg("ZLD","ZLD_LINROT = '"+ZL3->ZL3_COD+"' AND ZLD_FILIAL = '"+xFilial("ZLD")+"'")}

AxDeleta(cAlias,nReg,nOpc,/*cTransact*/,/*aCpos*/,/*aButtons*/,{bAxParam,bVldExc,bAxParam,bAxParam},/*aAuto*/,/*lMaximized*/)

Return

/*
===============================================================================================================================
Programa--------: AGLT005V
Autor-----------: Jeovane
Data da Criacao-: 11/09/2008
Descrição-------: Verifica integridade com tabela ZLD - Recepacao de Leite (X3_VLDUSER)
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function AGLT005V()

Local _aArea:= FWGetArea()
Local _lRet	:= .F.
Local _cMot	:= ""

If Empty(M->ZL3_FRETIS) .Or. Empty(M->ZL3_VEICUL)
     lRet := .T.
EndIf

//================================================================================
//| Busca Motorista do Veiculo                                                   |
//================================================================================
_cMot := Posicione( "ZL1" , 1 , xFilial("ZL1") + M->ZL3_VEICUL , "ZL1_MOTORI" )

//================================================================================
//| Busca Fretista do Motorista                                                  |
//================================================================================
DBSelectArea("ZL0")
ZL0->( DBSetOrder(1) )

If ZL0->( DBSeek( xFilial("ZL0") + _cMot ) )
	If ZL0->ZL0_FRETIS == M->ZL3_FRETIS .And. ZL0->ZL0_FRETLJ == M->ZL3_FRETLJ
		_lRet := .T.
	Else
		MsgAlert("O Motorista do Veiculo selecionado nao pertence ao Transportador desta linha. Selecione outro Veiculo ou outro Transportador!" , "AGLT00501" )
	EndIf
EndIf

FWRestArea(_aArea)

Return(_lRet)
