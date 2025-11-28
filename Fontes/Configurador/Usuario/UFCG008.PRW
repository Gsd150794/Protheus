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
Programa--------: UCFG008
Autor-----------: Talita Teixeira
Data da Criacao-: 25/11/2013
Descrição-------: Cadastro de unidade centralizadora - Contas a Pagar
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function UFCG008

Local cAlias		:= "ZZC"
Private cCadastro	:= "Cadastro de Unidade Centralizadora - Contas a Pagar"
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

