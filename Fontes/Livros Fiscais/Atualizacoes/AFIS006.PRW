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
Programa--------: AFIS006
Autor-----------: Josué Danich Prestes
Data da Criacao-: 04/11/2016
Descrição-------: Cadastro de código de retenção - Chamado 14542
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function AFIS006()

Local cAlias		:= "ZFT"
Private cCadastro	:= "Cadastro de codigo de retencao"
Private aRotina		:= {}     

aAdd(aRotina,{"Pesquisar"	,"AxPesqui",0,1})
aAdd(aRotina,{"Visualizar"	,"AxVisual",0,2})
aAdd(aRotina,{"Incluir"		,"AxInclui",0,3})
aAdd(aRotina,{"Alterar"		,"AxAltera",0,4})
aAdd(aRotina,{"Excluir"		,"AXExclui",0,5})           
	
DBSelectArea(cAlias)
DBSetOrder(1)
mBrowse(6,1,22,75,cAlias)

Return
