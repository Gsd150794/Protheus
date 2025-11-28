/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Darcio Spörl  |31/01/2017| Chamado 14542. Criada uma função para exclusão do registro, devido a função padrão estar gerando erro
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: AFIS005
Autor-----------: Josué Danich Prestes
Data da Criacao-: 04/11/2016
Descrição-------: Cadastro de amarracao natureza x codigo de retencao - Chamado 14542
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function AFIS005()
Local cAlias		:= "ZFS"
Private cCadastro	:= "Cadastro de amarracao de natureza x codigo de retencao"
Private aRotina		:= MenuDef()                
	
DBSelectArea(cAlias)
DBSetOrder(1)
mBrowse(6,1,22,75,cAlias)

Return

/*
===============================================================================================================================
Programa--------: MenuDef
Autor-----------: Darcio Ribeiro Spörl
Data da Criacao-: 09/01/2017
Descrição-------: Menu Funcional
Parametros------: Nenhum
Retorno---------: _aRot -> Array com as opções de menu
===============================================================================================================================
*/
Static Function MenuDef()
Local _aRot :=	{	{OemToAnsi("Pesquisar")		,"AxPesqui"		, 0 , 1 , 0 , .F.},;
					{OemToAnsi("Visualizar")	,"AxVisual"		, 0 , 2 , 0 , nil},;
					{OemToAnsi("Incluir")		,"AxInclui"		, 0 , 3 , 0 , nil},;
					{OemToAnsi("Alterar")		,"AxAltera"		, 0 , 4 , 0 , .F.},;
					{OemToAnsi("Excluir")		,'U_AFIS005D'	, 0 , 5 , 0 , .F.} }

Return(_aRot)

/*
===============================================================================================================================
Programa--------: AFIS005D
Autor-----------: Darcio Ribeiro Spörl
Data da Criacao-: 09/01/2017
Descrição-------: Função criada para tratar a exclusão do registro, pois a AxDeleta está gerando error.log.
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function AFIS005D()

Local _aArea := FWGetArea()

RecLock("ZFS", .F.)
	DBDelete()
MSUnLock()

FWRestArea(_aArea)

Return
