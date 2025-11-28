/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Josué Danich  |16/09/2015| Chamado 11890. Incluida validação de usuário da ZZL para manutenção no cadastro
Lucas Borges  |10/09/2024| Chamado 48465. Removendo warning de compilação.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: AEST003
Autor-------------: Tiago Correa Castro
Data da Criacao---: 14/07/2008
Descrição---------: Programa de Criacao de Tela de Cadastro do Nivel 4. As informacoes desse cadastro sera utilizado pelo campo
					SB1->B1_I_NIV4
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AEST003()

Local 	_cAlias		:= "ZA3"
Private cCadastro	:= "Cadastro de Nivel 4"
Private aRotina		:= {}                

aAdd(aRotina,{"Pesquisar"	,"AxPesqui",0,1})
aAdd(aRotina,{"Visualizar"	,"AxVisual",0,2})
aAdd(aRotina,{"Incluir"		,"U_AEST003V",0,3})
aAdd(aRotina,{"Alterar"		,"U_AEST003V",0,4})
aAdd(aRotina,{"Excluir"		,"U_AEST003V",0,5})
	
mBrowse(6,1,22,75,_cAlias)

Return

/*
===============================================================================================================================
Programa----------: AEST003V
Autor-------------: Tiago Correa Castro
Data da Criacao---: 14/07/2008
Descrição---------: Programa de Validacao da Alteracao e Exclusao, chamado pelo programa AEST003(). Valida a alteracao e 
					exclusao dos dados na tabela ZA3010, caso o codigo a ser excluido ja tenha amarracao na tabela SB1010 o 
					programa nao permite a alteracao ou exclusao.
Parametros--------: Nenhum
Retorno-----------: Retorno Logico (.T. ou .F.) para inclusao, exclusao ou alteracao   
===============================================================================================================================
*/
User Function AEST003V(cAlias,nReg,nOpc)

Local _aArea 	:= FWGetArea()
Local _lRet		:= 	.T. 
Local _cAlias	:= 	GetNextAlias()

//==============================================================================
//Valida acesso a manuteção de nível 4
//==============================================================================
If (nOpc == 4 .Or. nOpc == 5 .Or. nOpc == 3)
	If .Not. U_ITVACESS('ZZL',3,'ZZL_ALNV4',"S")
		FWAlertInfo("Usuário sem acesso à manutenção de cadastros de nível 4! Caso necessário solicite a manutenção à um usuário com acesso ou, se necessário, solicite o acesso à área de TI/ERP.","AEST00301")
		Return .F.
	EndIf
EndIf

//==============================================================================
//valida manutenção de registro contra uso do cadastro na B1
//==============================================================================
If (nOpc == 4 .Or. nOpc == 5)
	BeginSql alias _cAlias
		SELECT COUNT(1) QTD FROM %Table:SB1% 
		WHERE D_E_L_E_T_ = ' ' AND B1_I_NIV4 = %exp:ZA3->ZA3_COD%
	EndSql

	If (_cAlias)->QTD > 0
		_lRet	:= .F.
		FWAlertWarning("Cadastro já utilizado em produtos! Caso necessário modifique o grupo 4 utilizado nos produtos antes de alterar esse cadastro.","AEST00302")
	EndIf

	(_cAlias)->(DBCloseArea())
EndIf

//==============================================================================
//Se está tudo certo faz inclusão/alteração/exclusão
//==============================================================================
If _lRet .And. nOpc == 4
	AxAltera(cAlias,nReg,nOpc)
ElseIf _lRet .And. nOpc == 5 
	AxDeleta(cAlias,nReg,nOpc)
ElseIf _lRet .And. nOpc == 3
	AxInclui(cAlias,nreg,nOpc)
EndIf
FWRestArea(_aArea)

Return _lRet 
