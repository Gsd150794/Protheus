/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |15/08/2019| Chamado 28346. Modificada validação para deleção de registros.
Lucas Borges  |27/09/2019| Chamado 28346. Revisão de fontes.
Lucas Borges  |19/05/2023| Chamado 43886. Corrigido posicionamento na ZZL.
===============================================================================================================================
*/                    

#Include "TOTVS.ch" 

/*
===============================================================================================================================
Programa----------: AGLT004
Autor-------------: Jeovane
Data da Criacao---: 11/02/2009 
Descrição---------: Cadastro de Setor
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT004

Local _cFilter		:= ""

Private cCadastro	:= "Cadastro Setor"
Private aRotina		:= MenuDef()
Private cAlias 		:= "ZL2"

//=====================================================================================
//Obtem Setores que podem ser acessados - 114 - "MBrowse - Visualiza outras filiais"
//Se o usuário visualiza toda as filiais no browse, filtro todos os setores. Do contra-
//ário, filtro só a filial corrente
//=====================================================================================
If Posicione("ZLU",1,xFilial("ZLU")+RetCodUsr(),"ZLU_SETALL") <> 'S'
	_cFilter :="ZL2_COD IN "+FormatIn(U_LisSetor(IIf(SubStr(cAcesso,114,1)=='S',.F.,.T.)),";")
EndIf

MBrowse(,,,,cAlias,,,,,,,,,,,,,,_cFilter)

Return

/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 02/08/2018
Descrição---------: Utilizacao de Menu Funcional
Parametros--------: aRotina
					1. Nome a aparecer no cabecalho
					2. Nome da Rotina associada
					3. Reservado
					4. Tipo de Transa‡„o a ser efetuada:
						1 - Pesquisa e Posiciona em um Banco de Dados
						2 - Simplesmente Mostra os Campos
						3 - Inclui registros no Bancos de Dados
						4 - Altera o registro corrente
						5 - Remove o registro corrente do Banco de Dados
					5. Nivel de acesso
					6. Habilita Menu Funcional
Retorno-----------: Array com opcoes da rotina
===============================================================================================================================
*/
Static Function MenuDef()

Local aRotina := {	{ "Pesquisar"		, "AxPesqui" 		, 0 , 1 } ,;
					{ "Visualizar"		, "AxVisual" 		, 0 , 2 } ,;
					{ "Incluir"			, "AxInclui" 		, 0 , 3 } ,;
					{ "Alterar"			, "AxAltera" 		, 0 , 4 } ,;
					{ "Excluir"			, "U_AGLT004E"		, 0 , 5 }  }

Return( aRotina )

/*
===============================================================================================================================
Programa----------: AGLT004E
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 02/08/2018
Descrição---------: Funcao usada para apagar registro da ZL2
Parametros--------: cAlias,nReg,nOpc
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT004E(cAlias,nReg,nOpc)
Local bAxParam 	:= {|| .T.}
Local bVldExc	:= {|| U_ChkReg("ZLD","ZLD_SETOR = '"+ZL2->ZL2_COD+"' AND ZLD_FILIAL = '"+xFilial("ZLD")+"'") .And. ;
						U_ChkReg("ZL3","ZL3_SETOR = '"+ZL2->ZL2_COD+"' AND ZL3_FILIAL = '"+xFilial("ZL3")+"'")}

AxDeleta(cAlias,nReg,nOpc,/*cTransact*/,/*aCpos*/,/*aButtons*/,{bAxParam,bVldExc,bAxParam,bAxParam},/*aAuto*/,/*lMaximized*/)

Return

/*
===============================================================================================================================
Programa----------: AGLT004Mix
Autor-------------: Darcio Ribeiro Sporl
Data dsa Criacao---: 23/09/2016
Descrição---------: Função criada para habilitar ou não a alteração do campo último valor mix
Parametros--------: Nenhum
Retorno-----------: _lRet - .T. Habilita a digitação do campos, .F. - caso contrário
===============================================================================================================================
*/
User Function AGLT004Mix()
Local _aArea	:= FWGetArea()
Local _lRet		:= .F.

DBSelectArea("ZZL")
ZZL->(DBSetOrder(3))
If ZZL->(DBSeek(xFilial("ZZL") + RetCodUsr()))
	If ZZL->ZZL_ALTMIX == "S"
		_lRet := .T.
	EndIf
EndIf

FWRestArea(_aArea)
Return(_lRet)
