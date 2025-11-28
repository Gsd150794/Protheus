/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |15/04/2019| Chamado 28346. Revisão de fontes
Lucas Borges  |15/08/2019| Chamado 28346. Modificada validação para deleção de registros.
Lucas Borges  |29/06/2021| Chamado 37004. Criada função para replicar cadastro para outras filiais.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: AGLT006
Autor-------------: Abrahao P. Santos
Data da Criacao---: 29/10/2008
Descrição---------: Rotina desenvolvida para possibilitar o cadastramento de Eventos
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT006

Private cCadastro	:= "Cadastro de Eventos"
Private aRotina		:= MenuDef()
Private cAlias 		:= "ZL8"

mBrowse( 6, 1,22,75,cAlias,,,,,,)

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
					{ "Incluir"			, "U_AGLT006I" 		, 0 , 3 } ,;
					{ "Alterar"			, "U_AGLT006A" 		, 0 , 4 } ,;
					{ "Excluir"			, "U_AGLT006E"		, 0 , 5 } ,;
					{ "Replicar Filiais", "U_AGLT006R"		, 0 , 4 }  }

Return( aRotina )

/*
===============================================================================================================================
Programa----------: AGLT006I
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 02/08/2018
Descrição---------: Funcao usada para incluir registro da ZL8
Parametros--------: cAlias,nReg,nOpc
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT006I(cAlias,nReg,nOpc)

AxInclui(cAlias,nReg,nOpc,/*aAcho*/,/*cFunc*/,/*aCpos*/,"U_AGLT006V()"/*cTudoOk*/,/*lF3*/,/*cTransact*/,/*aButtons*/,/*aParam*/,/*aAuto*/,/*lVirtual*/,/*lMaximized*/)
 
Return

/*
===============================================================================================================================
Programa----------: AGLT006A
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 02/08/2018
Descrição---------: Funcao usada para incluir registro da ZL8
Parametros--------: cAlias,nReg,nOpc
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT006A(cAlias,nReg,nOpc)

AxAltera(cAlias,nReg,nOpc,/*aAcho*/,/*aCpos*/,/*nColMens*/,/*cMensagem*/,"U_AGLT006V()"/*cTudoOk*/,/*cTransact*/,/*cFunc*/,/*aButtons*/,/*aParam*/,/*aAuto*/,/*lVirtual*/,/*lMaximized*/)
 
Return

/*
===============================================================================================================================
Programa----------: AGLT006V
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 02/08/2018
Descrição---------: Funcao usada para validar a inclusãod e registros
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT006V()

Local lRet := .T.

If M->ZL8_TPEVEN == "F" //Financeiro
	If Empty(M->ZL8_PREFIX)
			MsgStop("Para eventos do tipo Financeiro, é obrigatório o preenchimento do Prefixo.","AGLT00603")
			lRet := .F.
	ElseIf !Empty(M->ZL8_SB1COD)
			MsgStop("Para eventos do tipo Financeiro, o campo Cod. Produto deve ficar em branco.",;
			"Deixe o conteudo do campo Cod. Produto vazio no cadastro de Eventos.","AGLT00604")
			lRet := .F.
	ElseIf Empty(M->ZL8_PRIORI)
			MsgStop("Para eventos do tipo Financeiro, é obrigatório o preenchimento da Sequencia de Prioridade de Acerto do Leite.","AGLT00605")
			lRet := .F.
	ElseIf M->ZL8_DEBCRE == "C"
			MsgStop("Para eventos do tipo Financeiro, é obrigatório o preenchimento do campo Debit/Credit como Débito. ","AGLT00606")
			lRet := .F.
	ElseIf Empty(M->ZL8_SITUAC)
			MsgStop("Para eventos do tipo Financeiro, é obrigatório o preenchimento do campo Situação B/D. "+;
			"Preencha o campo Situação com B para o sistema baixar o titulo no financeiro e com D para deletá-lo quando não houver saldo suficiente.","AGLT00607")
			lRet := .F.
	EndIf
ElseIf M->ZL8_TPEVEN == "A" //Avulsos
	If Empty(M->ZL8_PREFIX) .And. M->ZL8_DEBCRE == "D"
			MsgStop("Para eventos do tipo Avulso de Débito, é obrigatório o preenchimento do Prefixo.","AGLT00608")
			lRet := .F.
	ElseIf Empty(M->ZL8_SB1COD) .And. M->ZL8_DEBCRE == "C"
			MsgStop("Para eventos do tipo Avulso de Crédito, é obrigatório o preenchimento do campo Cod. Produto.","AGLT00609")
			lRet := .F.
	EndIf
EndIf

Return(lRet)
/*
===============================================================================================================================
Programa----------: AGLT006E
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 02/08/2018
Descrição---------: Funcao usada para apagar registro da ZL8
Parametros--------: cAlias,nReg,nOpc
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT006E(cAlias,nReg,nOpc)

Local bAxParam 	:= {|| .T.}
Local bVldExc	:= {|| U_ChkReg("ZLL","ZLL_EVENTO = '"+ZL8->ZL8_COD+"' AND ZLL_FILIAL = '"+xFilial("ZLL")+"'");
						.And. U_ChkReg("ZLF","ZLF_EVENTO = '"+ZL8->ZL8_COD+"' AND ZLF_FILIAL = '"+xFilial(cAlias)+"'")}

AxDeleta(cAlias,nReg,nOpc,/*cTransact*/,/*aCpos*/,/*aButtons*/,{bAxParam,bVldExc,bAxParam,bAxParam},/*aAuto*/,/*lMaximized*/)

Return

/*
===============================================================================================================================
Programa----------: AGLT006R
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 29/06/2021
Descrição---------: Função usada para replicar o evento para todas as filiais
Parametros--------: cAlias,nReg,nOpc
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT006R(cAlias,nReg,nOpc)

Local _aArea	:= FWGetArea()
Local _aSelFil	:= AdmGetFil(.F.,.F.,cAlias)
Local _nX, _nI	:= 0
Local _aFields	:= FWSX3Util():GetAllFields( cAlias , .F. )
Local _aOrig	:= {}
Local _lRet		:= .F.

If Len(_aSelFil) > 0
	//Adiciono todos os campos no array
	For _nX	:= 1 To Len(_aFields)
		aAdd(_aOrig,&(_aFields[_nX]))
	Next _nX

	(cAlias)->(DBSetOrder(1))
	For _nX := 1 To Len(_aSelFil)
		If !(cAlias)->(DBSeek(_aSelFil[_nX] + &(cAlias+"->"+cAlias+"_COD")))
			(cAlias)->(RecLock(cAlias, .T.))
				For _nI := 1 To Len(_aFields)
					If "FILIAL" $ _aFields[_nI]
						(cAlias)->&(_aFields[_nI]) := _aSelFil[_nX]
					Else
						(cAlias)->&(_aFields[_nI]) := _aOrig[_nI]
					EndIf
				Next _nI
			(cAlias)->(MSUnLock())
			_lRet := .T.
		EndIf
	Next _nX
EndIf

If _lRet
	MsgInfo("Registro replicado para as filiais selecionadas que não possuiam o registro.","AGLT00601")
Else
	MsgAlert("Não foram identificadas filiais aptas para a réplica do registro.","AGLT00602")
EndIf

FWRestArea(_aArea)

Return
