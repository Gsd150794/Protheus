/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: UCFG005
Autor-------------: Talita Teixeira
Data da Criacao---: 29/04/2013
Descrição---------: Programa de Criacao de Tela de Cadastro de Aplicação QlikView  - Chamado 3210
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function UCFG005

Local cAlias		:= "ZZ1"
Private cCadastro	:= "Cadastro Aplicação QlikView"
Private aRotina		:= {}                

aAdd(aRotina,{"Pesquisar"	,"AxPesqui",0,1})
aAdd(aRotina,{"Visualizar"	,"AxVisual",0,2})
aAdd(aRotina,{"Incluir"		,"AxInclui",0,3})
aAdd(aRotina,{"Alterar"		,"AxAltera",0,4})
aAdd(aRotina,{"Excluir"		,"AxDeleta",0,5})
	
DBSelectArea(cAlias)
DBSetOrder(1)
mBrowse(6,1,22,75,cAlias)

Return
