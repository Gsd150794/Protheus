/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |09/08/2018| Chamado 25767. Incluído MenuDef para padronização
Lucas Borges  |15/08/2019| Chamado 28346. Modificada validação para deleção de registros.
===============================================================================================================================
*/

#Include "TOTVS.ch" 

/*
===============================================================================================================================
Programa----------: AGLT018
Autor-------------: Abrahao P. Santos
Data da Criacao---: 29/10/2008
Descrição---------: Rotina desenvolvida para possibilitar o cadastramento de Grupos de Eventos
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT018

Private cCadastro	:= "Grupos de Eventos"
Private aRotina		:= MenuDef()
Private cAlias		:= "ZL7"

mBrowse( 6, 1,22,75,cAlias,,,,,,)

Return

/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 09/08/2018
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

Local aRotina := {	{ "Pesquisar"		, "AxPesqui" 		, 0 , 1 } ,;
					{ "Visualizar"		, "AxVisual" 		, 0 , 2 } ,;
					{ "Incluir"			, "AxInclui" 		, 0 , 3 } ,;
					{ "Alterar"			, "AxAltera" 		, 0 , 4 } ,;
					{ "Excluir"			, "U_AGLT018E" 		, 0 , 5 }  }

Return( aRotina )

/*
===============================================================================================================================
Programa----------: AGLT015E
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 09/08/2018
Descrição---------: Funcao usada para apagar todos os registro da ZLB
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT018E(cAlias,nReg,nOpc)

Local bAxParam 	:= {|| .T.}
Local bVldExc	:= {|| U_ChkReg("ZL8","ZL8_GRUPO = '"+ZL7->ZL7_COD+"' AND ZL8_FILIAL = '"+xFilial("ZL8")+"'")}

AxDeleta(cAlias,nReg,nOpc,/*cTransact*/,/*aCpos*/,/*aButtons*/,{bAxParam,bVldExc,bAxParam,bAxParam},/*aAuto*/,/*lMaximized*/)

Return
