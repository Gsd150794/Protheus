/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |03/10/2019| Chamado 28346. Removidos os Warning na compilacao da release 12.1.25. 
Alex Wallauer |28/04/2020| Chamado 32763. Alterar chamada "MsgBox" para "U_ITMsg". 
Alex Wallauer |15/07/2024| Chamado 47732. Ajsute para as mensagens/U_ITMsg de erro aparece com a figura de erro.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MSC1110D
Autor-------------: Tiago Correa Castro
Data da Criacao---: 31/07/2008
Descricao---------: Ponto de Entrada para validar exclusao da Solicitacao de Compra
					Localizacao: Function A110Deleta  - Funcao de exclusao da Solicitacao de Compras
					Em que Ponto: Antes da apresentacao da dialog de exclusao da SC possibilita validar a solicitacao posicionada
					para continuar e executar a exclusao ou nao.
Parametros--------: Nenhum
Retorno-----------: _lDeleta -> L -> .T. Deleta / .F. Aborta delecao.
===============================================================================================================================
*/
User Function MSC1110D

Local _aArea 	:=	FWGetArea()
Local _lDeleta	:= 	.T.
Local _cCodSol 	:= 	__cUserId

If 	_cCodSol <> SC1->C1_I_CDSOL
	_lDeleta := .F. 
	  U_ITMsg("Solicitacao nao podera ser excluida, pois a mesma foi incluida pelo usuario: "+SC1->C1_I_CDSOL + "- "+AllTrim(Posicione("SRA",1,SubStr(SC1->C1_I_CDSOL,1,2)+SubStr(SC1->C1_I_CDSOL,3,6),"RA_NOME")),;
		        "Usuário Inválido",;
		        "Verificar com o usuário que incluiu s SC.",1)  
EndIf

If _lDeleta
	//=====================================================================================================================
	// Valida se o usurio corrente existe na tabela de cadastro de solicitante e aprovadores, e se este no est bloqueado
	//=====================================================================================================================
	DBSelectArea("ZZ7")
	ZZ7->(DBSetOrder(1))
	If !ZZ7->(DBSeek(xFilial("ZZ7") + _cCodSol))
		_lDeleta := .F.
		U_ITMsg("O usuário logado não está cadastrado como Solicitante ou Aprovador, usuario: " + __cUserId + " - " + AllTrim(UsrFullName(__cUserId)),;
		        "Usuário Inválido",;
		        "Verificar com a área de TI a possibilidade de habilitar o seu usuário.",1)  
	Else
		If ZZ7->ZZ7_STATUS == "B"
			_lDeleta := .F.
			U_ITMsg("O usuário logado está Bloqueado no cadastrado de Solicitante / Aprovador, usuario: " + __cUserId + " - " + AllTrim(UsrFullName(__cUserId)),;
		        "Usuário Inválido",;
		        "Verificar com a área de TI a possibilidade de habilitar o seu usuário.",1)  
		EndIf
	EndIf
EndIf

If !Empty(SC1->C1_CODCOMP)
	_lDeleta := .F.
	U_ITMsg("Solicitação não poderá ser excluída, pois a mesma já possui comprador indicado.",;
		        "Não permitido",;
		        "Verificar com o depto. de compras a indicação a sua SC.",1)  
EndIf

FWRestArea(_aArea)
Return(_lDeleta)
