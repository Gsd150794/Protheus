/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |10/09/2024| Chamado 48465. Removendo warning de compilação.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: AEST044
Autor-------------: 
Data da Criacao---: 
Descricao---------: Cadastro de Grupos BI
Parametros--------:
Retorno-----------:
===============================================================================================================================
*/
User Function AEST044()

Local cAlias		:= "ZA4"
Private cCadastro	:= "Cadastro de Grupos BI"
Private aRotina		:= {}                

aAdd(aRotina,{"Pesquisar"	,"AxPesqui",0,1})
aAdd(aRotina,{"Visualizar"	,"AxVisual",0,2})
aAdd(aRotina,{"Incluir"		,"AxInclui",0,3})
aAdd(aRotina,{"Alterar"		,"U_ValZA4",0,4})
aAdd(aRotina,{"Excluir"		,"U_ValZA4",0,5})
	
mBrowse(6,1,22,75,cAlias)

Return

/*
===============================================================================================================================
Programa----------: ValZA4
Autor-------------: 
Data da Criacao---: 
Descricao---------: Programa de Validacao da Alteracao e Exclusao
Parametros--------:
Retorno-----------:
===============================================================================================================================
*/	
User Function ValZA4(cAlias,nReg,nOpc)

Local _aArea 	:= FWGetArea()
Local _lRet		:= .T.
Local _cAlias	:= GetNextAlias()

BeginSql alias _cAlias
	SELECT COUNT(1) QTD FROM %Table:SBZ% 
	WHERE D_E_L_E_T_ = ' ' AND BZ_I_GRPBI = %exp:ZA4->ZA4_COD%
EndSql

If (_cAlias)->QTD > 0
	_lRet	:= .F.
EndIf

(_cAlias)->(DBCloseArea())

If _lRet .And. nOpc == 4
	AxAltera(cAlias,nReg,nOpc)
ElseIf _lRet .And. nOpc == 5 
	AxDeleta(cAlias,nReg,nOpc)
EndIf

FWRestArea(_aArea)

Return _lRet
