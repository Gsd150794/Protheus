/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Igor Melgaço  |22/09/2025| Chamado 49967. Ponto de Entrada criado para Alterar Atualização de Estoque da TES.
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include  "FWMVCDEF.CH"

/*
===============================================================================================================================
Programa----------: MA080MNU
Autor-------------: Igor Melgaço
Data da Criacao---: 17/09/2025
Descrição---------: PE - MA080MNU - Habilitação ou desabilitação incluir novas rotinas no menu do cadastro de TES Chamado 49967
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/ 
User Function MA080MNU()
 
Local aRotina := ParamIXB[1]
     
    ADD OPTION aRotina TITLE "Alterar Atualização de Estoque da TES"  ACTION 'U_A080Est'    OPERATION 4 ACCESS 0 

Return aRotina

User Function A080Est()

Local oDlg
Local lOk := .F.
Local _cAtuEst := SF4->F4_ESTOQUE
Local _aCombo := {"S - Sim","N - Não"}
Local _cOrig := ""

	_cAtuEst := IIf(_cAtuEst == "N","N - Não","S - Sim")

	DEFINE DIALOG oDlg TITLE OemToAnsi("Alteração da TES "+SF4->F4_CODIGO) FROM 0,0 TO 10,50

	@ 001  ,002 Say OemToAnsi("Atualiza Estoque?") OF oDlg
	@ 01.5 ,002 ComboBox oEmail VAR _cAtuEst ITEMS _aCombo SIZE 60,6 OF oDlg

	@ 050,100 BUTTON oBtnOk     PROMPT "&Ok"       SIZE 43,12 PIXEL ACTION ((lOk := .T.),oDlg:End()) of oDlg
	@ 050,150 BUTTON oBtnCancel PROMPT "&Cancelar" SIZE 43,12 PIXEL ACTION ((lOk := .F.),oDlg:End()) of oDlg

	ACTIVATE DIALOG oDlg CENTERED

	If lOk
		_cOrig := SF4->F4_ESTOQUE
		RecLock("SF4",.F.)
		SF4->F4_ESTOQUE := _cAtuEst
		SF4->(MSUnLock())

		U_FA040L("SF4",1,"F4_ESTOQUE",_cOrig,_cAtuEst,SF4->F4_FILIAL+SF4->F4_CODIGO,SF4->F4_FILIAL,SF4->F4_CODIGO,"U_A080EST")
	EndIf
Return
