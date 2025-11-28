/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |20/08/2021| Chamado 37531. Usuário já conseguiu mudar de ideia sobre os campos a serem obrigatórios.
Lucas Borges  |10/12/2021| Chamado 38586. Corrigida validação para não ser chamada na exclusão.
Lucas Borges  |13/05/2022| Chamado 40106. Ajustado para validar se os dados não foram alterados.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MTCHKNFE
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 19/08/2021
Descrição---------: Ponto de Entrada para validações adicionais dos campos contidos na Pasta "Nota Fiscal Eletrônica".Será 
						sempre executado na confirmação da nota fiscal. Chamado 37521
Parametros--------: aNfetr -> A -> Array com os campos da Pasta "Nota Fiscal Eletrônica".
					ParamIXB[1][1] -> C -> F1_NFELETR
					ParamIXB[1][2] -> C -> F1_CODNFE
					ParamIXB[1][3] -> D -> F1_EMINFE
					ParamIXB[1][4] -> C -> F1_HORNFE
					ParamIXB[1][5] -> N -> F1_CREDNFE
					ParamIXB[1][6] -> C -> F1_NUMRPS
					ParamIXB[1][7] -> C -> F1_MENNOTA
					ParamIXB[1][8] -> C -> F1_MENPAD

Retorno-----------: _lRet -> L -> .T. - Passou pela validação / .F. - Não passou pela validação
===============================================================================================================================
*/
User Function MTCHKNFE

Local _lITVNFDS := .F.
Local _lRet	:= .T.

If AllTrim(cEspecie) == "NFDS" .And. (Inclui .Or. Altera)
	_lITVNFDS := SuperGetMV("IT_VALNFDS",.F.,.F.)
	If _lITVNFDS .And. ((Empty(ParamIXB[1][1]) .Or. Empty(ParamIXB[1][2]) .Or. Empty(ParamIXB[1][3]));
		.Or. !(ParamIXB[1][1]==cNFiscal .And. ParamIXB[1][3]==dDEmissao))
		_lRet := .F.
		If l103Auto
			AutoGRLog("MTCHKNFE001"+CRLF+"Verifique os campos obrigatórios para documentos cuja espécie é NFDS na aba Nota Fiscal Eletrônica,Dúvidas, acionar o Departamento Fiscal.")
		Else
			MsgAlert("Verifique os campos obrigatórios para documentos cuja espécie é NFDS na aba Nota Fiscal Eletrônica. Dúvidas, acionar o Departamento Fiscal.","MTCHKNFE001")
		EndIf
	EndIf
EndIf

Return (_lRet)
