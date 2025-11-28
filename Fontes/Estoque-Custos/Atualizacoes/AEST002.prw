/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |09/09/2024| Chamado 48465. Removendo warning de compilação.
===============================================================================================================================
*/

#Include "TOTVS.ch" 

/*
===============================================================================================================================
Programa----------: AEST002
Autor-------------: Tiago Correa Castro
Data da Criacao---: 14/07/2008
Descrição---------: Programa de Criacao de Tela de Cadastro do Nivel 3
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AEST002()

Local cAlias		:= "ZA2"
Private cCadastro	:= "Cadastro de nivel 3"
Private aRotina		:= {}                

aAdd(aRotina,{"Pesquisar"	,"AxPesqui",0,1})
aAdd(aRotina,{"Visualizar"	,"AxVisual",0,2})
aAdd(aRotina,{"Incluir"		,"AxInclui",0,3})
aAdd(aRotina,{"Alterar"		,"U_ValZA2",0,4})
aAdd(aRotina,{"Excluir"		,"U_ValZA2",0,5})
	
mBrowse(6,1,22,75,cAlias)

Return
/*
===============================================================================================================================
Programa----------: ValZA2
Autor-------------: Tiago Correa Castro
Data da Criacao---: 14/07/2008
Descrição---------: Programa de Validacao da Alteracao e Exclusao, chamado pelo programa AEST002()
Parametros--------: cAlias,nReg,nOpc
Retorno-----------: Retorno Logico (.T. ou .F.) para exclusao ou alteracao
===============================================================================================================================
*/
User Function ValZA2(cAlias,nReg,nOpc)

Local lRet		:= 	.T. 
Local _cAlias	:= GetNextAlias()

BeginSql alias _cAlias
	SELECT COUNT(1) QTD FROM %Table:SB1% 
	WHERE D_E_L_E_T_ = ' ' AND B1_I_NIV3 = %exp:ZA2->ZA2_COD%
EndSql

If (_cAlias)->QTD > 0
	lRet	:= .F.
EndIf

(_cAlias)->(DBCloseArea())

If lRet .And. nOpc == 4
	AxAltera(cAlias,nReg,nOpc)
ElseIf lRet .And. nOpc == 5 
	AxDeleta(cAlias,nReg,nOpc)
EndIf

Return lRet
