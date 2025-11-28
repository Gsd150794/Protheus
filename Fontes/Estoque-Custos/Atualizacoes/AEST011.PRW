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
Programa----------: AEST011
Autor-------------: Josué Danich Prestes
Data da Criacao---: 14/01/2016
Descrição---------: Cadastro de tabela ZE0 - Dados de custos gerenciais por regra - Chamado 12497
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AEST011()

//==============================================================================
// Declaracao de Variaveis                                             
//==============================================================================
Local 	_cAlias		:= "ZE0"
Private cCadastro	:= "Custos Gerenciais"
Private aRotina		:= {}                

_lRet :=  U_ITVACESS( 'ZZL' , 3 , 'ZZL_WCUSTO' , "S" )

If !_lRet

	ShowHelpDlg( 'Atencao!' ,	{	'Usuario sem acesso à gravacao '	,;
									'de custos gerenciais!'						} , 2 ,;
								{	'Caso necessario solicite a manutencao à '		,;
									'um usuario com acesso ou, se necessario, '		,;
									'solicite o acesso à area de TI/ERP.'			} , 3  )
	
	Return
	
EndIf

aAdd(aRotina,{"Pesquisar"	,"AxPesqui",0,1})
aAdd(aRotina,{"Visualizar"	,"AxVisual",0,2})
aAdd(aRotina,{"Alterar"		,"AxAltera",0,4})
aAdd(aRotina,{"Excluir"		,"AxExclui",0,5})
	
DBSelectArea(_cAlias)
DBSetOrder(1)
mBrowse(6,1,22,75,_cAlias)

Return

