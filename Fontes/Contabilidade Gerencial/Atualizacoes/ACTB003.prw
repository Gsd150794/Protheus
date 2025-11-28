/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |03/09/2019| Chamado 28346. Incluído MenuDef para padronização.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: ACTB003
Autor-------------: Luciana Ribeiro
Data da Criacao---: 13/08/2008
Descrição---------: Cadastro de Grupo de TES. Utilizado nas regras dos LPs para contabilização
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ACTB003

Private cCadastro	:= "Cadastro de Grupo de TES"
Private aRotina		:= MenuDef()
Private cAlias		:= "ZZ5"

mBrowse( 6, 1,22,75,cAlias,,,,,,)

Return

/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 03/09/2019
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
					{ "Excluir"			, "AxDeleta"		, 0 , 5 }  }

Return( aRotina )
