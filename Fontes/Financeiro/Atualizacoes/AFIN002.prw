/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz     |04/05/2018| Chamado 24726. Padronização dos cabeçalhos dos fontes e funções do módulo financeiro.
Lucas Borges  |04/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: AFIN002
Autor-------------: Frederico O. C. Jr
Data da Criacao---: 28/08/2008 
Descrição---------: Rotina para a criacao de uma tela de cadastro de prefixos a serem utilizadas no Contas a Pagar e Receber.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AFIN002()

Private cAlias		:= "ZAB"
Private cCadastro	:= "Cadastro de Prefixo"
Private aRotina		:= MenuDef()

mBrowse(6,1,22,75,cAlias)

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
					{ "Excluir"			, "U_ValZAB"		, 0 , 5 }  }

Return( aRotina )

/*
===============================================================================================================================
Função------------: ValZAB
Autor-------------: Frederico O. C. Jr
Data da Criacao---: 28/08/2008 
Descrição---------: Validacao da exclusao de prefixos na tela para cadastro de prefixos.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ValZAB (cAlias,nReg,nOpc)

Local bAxParam 	:= {|| .T.}
Local bVldExc	:= {|| U_ChkReg("SE1","E1_PREFIXO = '"+ZAB->ZAB_PREFIX+"' ") .Or. U_ChkReg("SE2","E2_PREFIXO = '"+ZAB->ZAB_PREFIX+"' ")}

AxDeleta(cAlias,nReg,nOpc,/*cTransact*/,/*aCpos*/,/*aButtons*/,{bAxParam,bVldExc,bAxParam,bAxParam},/*aAuto*/,/*lMaximized*/)

Return
