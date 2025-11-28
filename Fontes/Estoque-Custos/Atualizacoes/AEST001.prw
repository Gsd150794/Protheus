/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |11/09/2024| Chamado 48465. Removendo warning de compilação.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: AEST001
Autor-------------: Tiago Correa Castro
Data da Criacao---: 14/07/2008
Descrição---------: Programa de Criacao de Tela de Cadastro do Nivel 2. As informacoes desse cadastro sera utilizado pelo campo
					SB1->B1_I_NIV2
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AEST001()

Local cAlias		:= "ZA1"
Private cCadastro	:= "Cadastro de nivel 2"
Private aRotina		:= {}                

aAdd(aRotina,{"Pesquisar"	,"AxPesqui",0,1})
aAdd(aRotina,{"Visualizar"	,"AxVisual",0,2})
aAdd(aRotina,{"Incluir"		,"AxInclui",0,3})
aAdd(aRotina,{"Alterar"		,"U_ValZA1",0,4})
aAdd(aRotina,{"Excluir"		,"U_ValZA1",0,5})
	
mBrowse(6,1,22,75,cAlias)

Return
/*
===============================================================================================================================
Programa----------: ValZA1
Autor-------------: Tiago Correa Castro
Data da Criacao---: 14/07/2008
Descrição---------: Programa de Validacao da Alteracao e Exclusao, chamado pelo programa AEST001(). Valida a alteracao e 
					exclusao dos dados na tabela ZA1010, caso o codigo a ser excluido ja tenha amarracao na tabela SB1010 o 
					programa nao permite a alteracao ou exclusao.
Parametros--------: Nenhum
Retorno-----------: Retorno Logico (.T. ou .F.) para inclusao, exclusao ou alteracao   
===============================================================================================================================
*/
User Function ValZA1(cAlias,nReg,nOpc)

Local _aArea 	:= FWGetArea()
Local _lRet		:= 	.T. 
Local _cAlias	:= 	GetNextAlias()

BeginSql alias _cAlias
	SELECT COUNT(1) QTD FROM %Table:SB1% 
	WHERE D_E_L_E_T_ = ' ' AND B1_I_NIV2 = %exp:ZA1->ZA1_COD% AND B1_GRUPO = %exp:ZA1->ZA1_CDGRUP%
EndSql

If (_cAlias)->QTD > 0
	_lRet	:= .F.
	FWAlertWarning("Cadastro já utilizado em produtos! Caso necessário modifique o grupo 2 utilizado nos produtos antes de alterar esse cadastro.","AEST00101")
EndIf

(_cAlias)->(DBCloseArea())

If _lRet .And. nOpc == 4
	AxAltera(cAlias,nReg,nOpc)
ElseIf _lRet .And. nOpc == 5 
	AxDeleta(cAlias,nReg,nOpc)
EndIf
FWRestArea(_aArea)

Return _lRet 
