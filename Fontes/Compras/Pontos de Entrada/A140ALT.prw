/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alexandre V.  |28/08/2015| Chamados 11497/11578. Ajuste para não bloquear o estorno da classificação de documentos.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: A140ALT
Autor-------------: Alexandre Villar
Data da Criacao---: 03/12/2014
Descrição---------: Ponto de entrada para validar a alteração dos documentos de entrada
Parametros--------: cTabAux := Código da Tabela no SX5
------------------: nTamAux := Tamanho da Chave para o Retorno
Retorno-----------: .T. - Compatibilidade com a utilização em F3
===============================================================================================================================
*/

User Function A140ALT()

Local _lRet		:= .T.
Local _aInfHlp	:= {}

DBSelectArea('ZLX')
ZLX->( DBSetOrder(2) )
If ZLX->( DBSeek( xFilial('ZLX') + SF1->( F1_DOC + F1_SERIE + F1_FORNECE + F1_LOJA ) ) )
	
	If ZLX->ZLX_STATUS <> '1' .Or. !Empty( ZLX->ZLX_CODANA )
		
		_aInfHlp := {}
		//                  |....:....|....:....|....:....|....:....|     |....:....|....:....|....:....|....:....|       |....:....|....:....|....:....|....:....|
		aAdd( _aInfHlp	, { "Não é possível alterar uma pré-nota que "	, " possui Recebimento de Leite com Status "	, " já processado."								} )
		aAdd( _aInfHlp	, { "Verifique o Recebimento no módulo do    "	, " Leite e exclua o registro caso seja    "	, " necessário alterar a pré-nota."				} )
		
		U_ITCADHLP( _aInfHlp , "A140ALT01" )

		_lRet := .F.
		
	EndIf
	
EndIf

Return( _lRet )
