/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  | 09/07/2021 | Incluído novo produto na regra do MIX. Chamado 37089
Lucas Borges  | 13/03/2023 | Incluído novo produto na regra do MIX. Chamado 43290
Lucas Borges  | 04/04/2024 |Incluída validação para não permitir vincular mix fechado. Chamado 46841
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MCOM008
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 22/08/2017
Descrição---------: Rotina para informar código do MIX que está relacionado à NF-e emitida pelo Produtor Rural
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MCOM008

Local _cMix:= Space(6)
DBSelectArea("ZLE")

	DEFINE MSDIALOG oDlgKey TITLE "Amarração NF-e X Mix" FROM 0,0 TO 150,305 PIXEL OF GetWndDefault()
			
	@ 12,008 Say "Informe o MIX do Leite que deve ser vinculado às NF-e" +CRLF+;
				 "selecioandas. Informar Vazio apagará o Mix associado." PIXEL OF oDlgKey
	@ 39,050 MSGET _cMix SIZE 045,10 PIXEL OF oDlgKey F3 "ZLE_01" Valid (Empty(_cMix).Or.ExistCpo('ZLE',_cMix,1))
	@ 58,015 BUTTON oBtnCon PROMPT "&Confirma" SIZE 38,11 PIXEL ACTION (MCOM008P(_cMix), oDlgKey:End())
	@ 58,095 BUTTON oBtnOut PROMPT "&Cancela" SIZE 38,11 PIXEL ACTION oDlgKey:End()

	ACTIVATE DIALOG oDlgKey CENTERED
	
Return

Static Function MCOM008P(_cMix)

Local _aArea	:= FWGetArea()
Local _cQuery 	:= ""
Local _lRet 	:= .T.

If ZLE->(DBSeek(xFilial("ZLE")+_cMix)) .And. ZLE->ZLE_STATUS == 'F'
	MsgStop("O mix informado está fechado. A operação será abortada!","MCOM00803")
	_lRet := .F.
Else
	//====================================================================================================
	// Grava o código do Mix para posteriormente alimentar a ZZ4 na geração da documento de entrada
	//====================================================================================================	
	_cQuery:=" UPDATE "+RETSQLNAME('SDS')+" SDS SET SDS.DS_L_MIX = '"+ _cMix +"'"
	_cQuery+="   WHERE D_E_L_E_T_ = ' '"
	_cQuery+="   AND SDS.DS_FILIAL = '"+xFilial("SDS")+"'"
	_cQuery+="   AND SDS.DS_OK = '"+cMarca+"'"
	_cQuery+="   AND SDS.DS_STATUS != 'P'"
	_cQuery+="   AND SDS.DS_FORNEC LIKE 'P%'"
	_cQuery+="   AND EXISTS (SELECT 1"
	_cQuery+="   FROM "+RETSQLNAME('SDT')+" SDT"
	_cQuery+="   WHERE SDT.D_E_L_E_T_ = ' '"
	_cQuery+="   AND SDT.DT_FILIAL = SDS.DS_FILIAL"
	_cQuery+="   AND SDT.DT_DOC = SDS.DS_DOC"
	_cQuery+="   AND SDT.DT_SERIE = SDS.DS_SERIE"
	_cQuery+="   AND SDT.DT_FORNEC = SDS.DS_FORNEC"
	_cQuery+="   AND SDT.DT_LOJA = SDS.DS_LOJA"
	_cQuery+="   AND SDT.DT_COD IN ('08000000030','08000000065','08000000004','08000000062'))"

	If TCSqlExec( _cQuery ) < 0
		_lRet := .F.
		MsgStop("Erro ao atualizar Código do Mix: "+AllTrim(TCSQLError()),"MCOM00801")
	Else
		MsgInfo("Registros atualizados com sucesso!","MCOM00802")
	EndIf
EndIf
ZLE->(DBCloseArea())
FWRestArea(_aArea)

Return _lRet
