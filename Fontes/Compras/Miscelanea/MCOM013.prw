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
Programa----------: MCOM013
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 05/05/2020
Descrição---------: Função para replicar informação de linha para todos os produtores que possuem o Produtor corrente como dono
					de tanque. Chamado 32851
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MCOM013

Local _oModel	:= Nil
Local _cAlias	:= GetNextAlias()
Local _nSaveRec	:= SA2->(RECNO())
Local _cLinha	:= SA2->A2_L_LI_RO
Local _lRet		:= .T.
Local _nCountRec:= 0

If SA2->A2_I_CLASS == 'P'
	BeginSql alias _cAlias
		SELECT R_E_C_N_O_ RECNO 
		FROM %Table:SA2%
		WHERE D_E_L_E_T_ = ' '
		AND A2_FILIAL = %xFilial:SA2%
		AND A2_L_TANQ = %exp:SA2->A2_COD%
		AND A2_L_TANLJ = %exp:SA2->A2_LOJA%
		AND A2_L_LI_RO <> %exp:SA2->A2_L_LI_RO%
	EndSql
	Count To _nCountRec
	(_cAlias)->( DBGoTop() )
	
	If MsgYesNo("Serão alterados "+AllTrim(Str(_nCountRec))+" produtores. Deseja replicar a linha "+_cLinha+" para todos?","MCOM01301")
		BeginTran()

			While !(_cAlias)->(Eof()) .And. _lRet
				SA2->(DBGoTo((_cAlias)->RECNO))
				_oModel := FwLoadModel ("MATA020")
				_oModel:SetOperation(4)
				_oModel:Activate()
				_oModel:SetValue("SA2MASTER","A2_L_LI_RO",_cLinha )
				
				If _oModel:VldData()
					_oModel:CommitData()
				Else
				    AutoGrLog("Id do formulário de origem:"  + ' [' + AllToChar(_oModel:GetErrorMessage()[01]) + ']')
					AutoGrLog("Id do campo de origem: "      + ' [' + AllToChar(_oModel:GetErrorMessage()[02]) + ']')
					AutoGrLog("Id do formulário de erro: "   + ' [' + AllToChar(_oModel:GetErrorMessage()[03]) + ']')
					AutoGrLog("Id do campo de erro: "        + ' [' + AllToChar(_oModel:GetErrorMessage()[04]) + ']')
					AutoGrLog("Id do erro: "                 + ' [' + AllToChar(_oModel:GetErrorMessage()[05]) + ']')
					AutoGrLog("Mensagem do erro: "           + ' [' + AllToChar(_oModel:GetErrorMessage()[06]) + ']')
					AutoGrLog("Mensagem da solução: "        + ' [' + AllToChar(_oModel:GetErrorMessage()[07]) + ']')
					AutoGrLog("Valor atribuído: "            + ' [' + AllToChar(_oModel:GetErrorMessage()[08]) + ']')
					AutoGrLog("Valor anterior: "             + ' [' + AllToChar(_oModel:GetErrorMessage()[09]) + ']')
					MostraErro()
					_lRet := .F.
				EndIf
				
				_oModel:DeActivate()

				(_cAlias)->(DBSkip())
			EndDo
		If !_lRet
			DisarmTransaction()
			MsgStop("Erros impediram a atualização. Acione a TI!","MCOM01302")
		Else
			EndTran()
			MsgInfo("Produtores alterados com sucesso!","MCOM01303")
		EndIf
	EndIf
	SA2->(DBGoTo(_nSaveRec))
Else
	MsgStop("Essa função é exclusiva para Produtores!","MCOM01304")
EndIf

Return
