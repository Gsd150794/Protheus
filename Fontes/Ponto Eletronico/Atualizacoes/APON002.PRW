/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |26/06/2025| Chamado 50617. Revisões diversas visando padronizar os fontes
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: APON002
Autor-------------: Josué Danich Prestes
Data da Criacao---: 15/12/2017
Descrição---------: Cadastro de controle de crachas - Chamado 22907
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function APON002

Local cAlias		:= "ZGI" As Character
Private cCadastro	:= "Cadastro de Crachas" As Character
Private aRotina 	:=	{{ "Pesquisar"	, "PesqBrw"		, 0 , 1,,.F. } ,;	//"Pesquisar"
						{ "Visualizar"	, "AxVisual"	, 0 , 2 } ,;		//"Visualizar"
						{ "Incluir"		, "AxInclui"	, 0 , 3 } ,;		//"Incluir"
						{ "Alterar"		, "Axaltera"	, 0 , 4 } ,;		//"Alterar"
						{ "Excluir"		, "Axdeleta"	, 0 , 5 }  ;		//"Excluir"
						} As Character

mBrowse(6,1,22,75,cAlias)

Return
