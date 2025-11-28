/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |02/10/2025| Chamado 51526. Modificada forma para recuperar a matrícula do usuário.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: AFIN024
Autor-------------: Josué Danich Prestes
Data da Criacao---: 20/08/2015
Descrição---------: Função criada para fazer a confirmação do desbloqueio - Chamado 16924
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AFIN024()
Local _aArea	:= FWGetArea()
Local _lok := .T.
Local cMatUsr			:= FWSFAllUsers({__cUserID},{"USR_FILIAL"})[1][3]+FWSFAllUsers({__cUserID},{"USR_CODFUNC"})[1][3]
Local cAutoriz		:= GetAdvFVal( "ZZL" , "ZZL_DCNAB" , xFilial("ZZL") + cMatUsr , 1 , "N" )


//-- Controle de acesso por usuario conforme parametrizacao no Gerenciador (Gestao de Usuarios) --//
If !( cAutoriz == "S" )
	U_ITMsg("Usuário sem acesso à rotina de liberação de cnab.","Atenção!",,1)
	Return
EndIf

//Verifica se é título bloqueado por cnab
If !(Empty(AllTrim(SE1->E1_NUMBCO)))
	U_ITMsg("Este título não está bloqueado por cnab!","Atenção",,1)
	Return
ElseIf (Empty(AllTrim(SE1->E1_IDCNAB)) .And. Empty(AllTrim(SE1->E1_I_NUMBC)))
	U_ITMsg("Este título não está bloqueado por cnab!","Atenção",,1)
	Return		
EndIf


If U_ITMsg('Deseja realmente desbloquear este título?',"Atenção",,3,2,2)
	FWMsgRun(,{||AFIN024E(@_lok)},,"Aguarde... Desbloqueando título selecionado...")
	If _lok
		U_ITMsg('Processo concluído com sucesso!',"Atenção",,2)
	EndIf
Else
	U_ITMsg('Processo cancelado pelo usuário.',"Atenção",,1)	
EndIf

FWRestArea(_aArea)
Return

/*
===============================================================================================================================
Programa----------: AFIN024E
Autor-------------: Josué Danich Prestes
Data da Criacao---: 09/11/2016
Descrição---------: Função para efetivar o Desbloqueio do Título
Parametros--------: _lok - retorno se deu certo
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AFIN024E(_lok)

Local _lContinua	:= .T.
Default _lok := .F.


If !Empty(SE1->E1_I_NUMBC) 
	If U_ITMsg("Para este título, existe um Nosso Número de backup [" + AllTrim(SE1->E1_I_NUMBC) + "]. Deseja utilizar o mesmo número?","Atenção",,3,2,2)
		_lContinua := .F.
	EndIf
EndIf

Begin Transaction
	If _lContinua
		//============================================================
		//apaga backup do nosso numero 
		//============================================================
		RecLock("SE1",.F.)
			SE1->E1_IDCNAB  := " "
			SE1->E1_NUMBCO	:= " "
			SE1->E1_I_NUMBC	:= " "
		MSUnLock()
	Else
		//Gravo o desbloqueio do título
		RecLock("SE1",.F.)
			SE1->E1_NUMBCO	:= SE1->E1_I_NUMBC	//Gravo o nosso número do backup
			SE1->E1_IDCNAB  := " "
		MSUnLock()
	EndIf
End Transaction

_lok := .T.

Return

