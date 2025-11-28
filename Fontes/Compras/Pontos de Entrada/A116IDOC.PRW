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
Programa----------: A116IDOC
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 19/12/2017
Descrição---------: O Ponto de Entrada A116IDOC é utilizado para manipular o número e a série do CTe importada por meio do 
					TOTVS Colaboração
Parametros--------: ParamIXB[1]: String, contendo o número do documento. 
					ParamIXB[2]: String, contendo a série do documento.
					ParamIXB[3]: String, contendo o fornecedor do documento.
					ParamIXB[4]: String, contendo a loja do codumento.
Retorno-----------: Array "aRet" de 2 posições, no seguinte formato: 
					aRet[1] - String - Numero do documento - Obrigatório
					aRet[2] - String - Serie do documento - Obrigatório
===============================================================================================================================
*/
User Function A116IDOC

Local _aRet	 := ParamIXB
Local _aArea := FWGetArea()

DBSelectArea('SF1')
SF1->( DBSetOrder(1) )
If SF1->( DBSeek( xFilial('SF1') + _aRet[01] + _aRet[02] + _aRet[03] + _aRet[04] ) ) 
	While !SF1->(Eof()) .And. SF1->(F1_FILIAL+F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA)==(xFilial('SF1') + _aRet[01] + _aRet[02] + _aRet[03] + _aRet[04]);
		.And. SF1->F1_FORMUL == ' ' .And. !AllTrim(SF1->F1_ESPECIE)=='CTE'
		_aRet[02]:=PadL(AllTrim(_aRet[02]),3,'0')
		SF1->(DBSkip())
	EndDo
EndIf

FWRestArea(_aArea)

Return _aRet
