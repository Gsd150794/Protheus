/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |11/04/2022| Chamado 38650. Alterações de Conout() para melhor monitoramento.
Lucas Borges  |24/09/2024| Chamado 48465. Sanado problemas apresentados no Code Analysis
Lucas Borges  |19/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MT120GOK
Autor-------------: Darcio Ribeiro Sporl
Data da Criacao---: 07/12/2015
Descrição---------: Ponto de Entrada executado após a função A120GRAVA e antes da contabilização do pedido de compras
					Localização: Function A120PEDIDO - Função do Pedido de Compras e Autorização de Entrega responsavel pela 
					inclusão, alteração, exclusão e cópia dos PCs.
					Em que Ponto: Após a execução da função de gravação A120GRAVA e antes da contabilização do Pedido de compras
					/ AE, Pode ser utilizado para qualquer tratamento que o usuario necessite realizar no PC antes da 
					contabilização do mesmo.
Parametros--------: ParamIXB[1] -> C -> cA120Num - Numero do Pedido de compras / AE.
					ParamIXB[2] -> L -> l120Inclui - .T. indica se é inclusão
					ParamIXB[3] -> L -> l120Altera - .T. indica se é alteração
					ParamIXB[4] -> L -> l120Deleta - .T. indica se é exclusão
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MT120GOK()

Local _cPedido		:= ParamIXB[1] // Numero do Pedido
Local lAltera		:= ParamIXB[3] // Alteração
Local _aArea		:= FWGetArea()
Local _aAreaSC7		:= SC7->(GetArea())
Local cFilPC		:= SuperGetMV("IT_FILWFPC",.F.,"01")
Local lFilPC		:= IIf(cFilAnt $ cFilPC,.T.,.F.)
Local _lHtml		:= .F.
Local _cHtml		:= ""
Local _nPosWRK		:= 0
Local _aHtml		:= {}
Local _nI			:= 0
Local _cArq			:= ""
Local _cHtmlMode	:= "\Workflow\htm\pc_manutencao.htm"

//Codigo do Usuario para tratamento do Pedido de compras antes da Contabilização.

DBSelectArea("SC7")
SC7->(DBSetOrder(1))
SC7->(DBSeek(xFilial("SC7") + _cPedido))

If lAltera
	If !Empty(SC7->C7_I_HTM)
		_lHtml := .T.
		_cHtml := AllTrim(SC7->C7_I_HTM)
	EndIf
EndIf

While SC7->C7_FILIAL + SC7->C7_NUM == xFilial("SC7") + _cPedido
	RecLock("SC7",.F.)
		If lFilPC
			SC7->C7_APROV	:= "PENLIB"
			SC7->C7_CONAPRO	:= "B"
		Else
			SC7->C7_APROV	:= ""
			SC7->C7_CONAPRO	:= "L"
		EndIf
	MSUnLock()
	SC7->(DBSkip())
End

//========================================================================================
//No caso de alteração do pedido de compras, o sistema trocará o aquivo a ser apresentado,
//caso já tenha sido enviado o e-mail de aprovação.
//========================================================================================
If _lHtml
	_aHtml	:= StrTokArr(_cHtml,"/")
	_nPosWRK:= aScan(_aHtml, {|x| LOWER(x) == "workflow"})
    If _nPosWRK <> 0
	   For _nI := _nPosWRK To Len(_aHtml)
	       _cArq += "\" + _aHtml[_nI]
	   Next _nI
    EndIf
	If File(_cArq)
		If fErase(_cArq) == 0
			If __CopyFile(_cHtmlMode, _cArq)
			   FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MATA120"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MT120GOK01"/*cMsgId*/, "MT120GOK - Cópia de arquivo WFPC de manutenção efetuada com sucesso. DE: "+_cHtmlMode+" PARA: "+_cArq /*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
			Else
			   FWLogMsg("WARN"/*cSeverity*/, /*cTransactionId*/, "MATA120"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MT120GOK02"/*cMsgId*/, "MT120GOK - Problema na cópia de arquivo WFPC de manutenção. DE: "+_cHtmlMode+" PARA: "+_cArq /*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
			EndIf
		Else
			FWLogMsg("WARN"/*cSeverity*/, /*cTransactionId*/, "MATA120"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MT120GOK03"/*cMsgId*/, "MT120GOK - Não foi possível excluir o arquivo " + _cArq + ".htm" /*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		EndIf
	EndIf
EndIf

FWRestArea(_aAreaSC7)
FWRestArea(_aArea)

Return
