/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Xavier        |12/05/2015| Chamado 9551. Exclusão de linha ou todos registros da filial.
Jonathan      |04/05/2020| Chamado 32763. Alterar chamada "MsgBox" para "U_ITMsg".
Lucas Borges  |10/09/2024| Chamado 48465. Removendo warning de compilação.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: AEST028
Autor-------------: Talita Teixeira
Data da Criacao---: 28/05/2013
Descrição---------: Programa de Criacao de Tela para o Cadastro de Motivo da baixa da pre-requisição - Chamado 3291
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AEST028

Local cAlias		:= "ZZ0"
Private cCadastro	:= "Cadastro de Motivo"
Private aRotina		:= {}                

aAdd(aRotina,{"Pesquisar"	,"AxPesqui",0,1})
aAdd(aRotina,{"Visualizar"	,"AxVisual",0,2})
aAdd(aRotina,{"Incluir"		,"AxInclui",0,3})
aAdd(aRotina,{"Alterar"		,"AxAltera",0,4})
aAdd(aRotina,{"Excluir"		,"U_ValExc",0,5})
	
mBrowse(6,1,22,75,cAlias)

Return

/*
===============================================================================================================================
Programa----------: AEST028
Autor-------------: Talita Teixeira
Data da Criacao---: 04/06/2013
Descrição---------: Validacao Exclusao na tabela ZZ0
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ValExc(cAlias,nReg,nOpc)

Local _aArea 	:= FWGetArea()
Local _lRet		:= .F.
Local _cAlias	:= GetNextAlias()

BeginSql alias _cAlias
	SELECT COUNT(1) QTD FROM %Table:SCP% 
	WHERE D_E_L_E_T_ = ' ' AND CP_I_MOTIV = %exp:ZZ0->ZZ0_COD%
EndSql

If (_cAlias)->QTD > 0
	_lRet	:= .F.
EndIf

(_cAlias)->(DBCloseArea())

If _lRet .And. nOpc == 5 
	AxDeleta(cAlias,nReg,nOpc)
ElseIf !_lRet .And. nOpc == 5 
	FWAlertWarning("Exclusao não permitida, o código já foi utilizado nas movimentacoes de estoque - Informe ao Administrador"+;
				"Exclusao não permitida, o código já foi utilizado nas movimentacoes de estoque - Informe ao Administrador","AEST02801")
EndIf
FWRestArea(_aArea)

Return _lRet
