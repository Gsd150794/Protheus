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
Programa----------: MCOM018
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 17/05/2022
Descrição---------: Rotina para informar a chave do CT-e para geração do 610110-Prestação de Serviço em Desacordo. Esses docu-
					mentos geralmente tem algum problema e não é possível gerar sua classificação por vias normais. Para que 
					não seja necessário liberar a inclusão desse documento pelo IT_FISBXML, o documento é incluído como pre-nota
					e sua chave informada aqui, possibilitando a manifestação sem classficação. Chamado 40131 e 40132
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MCOM018

Local _cChave:= Space(44)
Local _nOpc	:= 2
Local _oDlgKey as Object
Local _oBtnCon as Object
Local _oBtnOut as Object

If Empty(SF1->F1_STATUS) .And. AllTrim(SF1->F1_ESPECIE) = 'CTE' .And. Empty(SF1->F1_CHVNFE)
	DEFINE MSDIALOG _oDlgKey TITLE "Informa chave CT-e" FROM 0,0 TO 150,380 PIXEL OF GetWndDefault()
			
	@ 12,008 Say "Informa a chave a ser gravada no CT-e para casos de recusa da operação." PIXEL OF _oDlgKey
	@ 33,008 MSGET _cChave SIZE 160,10 PIXEL OF _oDlgKey Valid (!Empty(_cChave))
	@ 50,055 BUTTON _oBtnCon PROMPT "&Confirma" SIZE 38,11 PIXEL ACTION (_nOpc := 1, _oDlgKey:End())
	@ 50,095 BUTTON _oBtnOut PROMPT "&Cancela" SIZE 38,11 PIXEL ACTION _oDlgKey:End()

	ACTIVATE DIALOG _oDlgKey CENTERED
	
	If _nOpc == 1
		SA2->(DBSeek(xFilial("SA2")+SF1->(F1_FORNECE+F1_LOJA)))
		If SubStr(_cChave,7,14) <> SA2->A2_CGC // CNPJ Emitente conforme manual Nota Fiscal Eletrônica
			MsgStop("A chave informada não pertence à esse fornecedor.", "MCOM01801")
			// Número e série da nota conforme manual Nota Fiscal Eletrônica
		ElseIf Val(SubStr(_cChave,26,9)) <> Val(SF1->F1_DOC) .Or. Val(SubStr(_cChave,23,3)) <> Val(SF1->F1_SERIE)
			MsgStop("A chave informada não pertence à esse Documento.", "MCOM01802")
		ElseIf Len(_cChave) <> 44
			MsgStop("A chave informada não possui 44 caracteres.", "MCOM01803")
		Else
			RecLock("SF1", .F.)
				SF1->F1_CHVNFE := _cChave
			MSUnLock()
		EndIf
	EndIf
Else
	MsgStop("Opção disponível apenas para CT-e sem chave informada e que não foi classificado.", "MCOM01804")
EndIf

Return
