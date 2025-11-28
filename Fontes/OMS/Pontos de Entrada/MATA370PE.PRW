/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
 Autor        |    Data    |                              Motivo                      										 
-------------------------------------------------------------------------------------------------------------------------------
===============================================================================================================================
*/

//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: MATA370PE
Autor-----------: Lucas Borges Ferreira
Data da Criacao-: 03/05/2022
===============================================================================================================================
Descrição-------: Ponto de entrada em MVC no cadastro Produto X Cliente
===============================================================================================================================
Parametros------: ParamIXB
===============================================================================================================================
Retorno---------: lRet -> L -> Se Verdadeiro (.T.), valida a inclusao / alteracao dos dados no SA5.
								Se Falso (.F.), nao valida a inclusao / alteracao dos dados no SA5.
===============================================================================================================================
*/
User Function MATA370()

Local _aParam	:= ParamIXB
Local _lRet		:= .T.
Local _oObj		:= ""
Local _cIdPonto	:= ""
Local _cIdModel	:= ""
Local _lIsGrid	:= .F.

If _aParam <> NIL
	_oObj := _aParam[1]
	_cIdPonto := _aParam[2]
	_cIdModel := _aParam[3]
	_lIsGrid := (Len(_aParam) > 3)
	
	If _cIdPonto == "MODELPOS" //Chamada na validação total do modelo.
	ElseIf _cIdPonto == "FORMPOS"//Chamada na validação total do formulário.
		If Empty(_oObj:GetValue("A7_CODCLI")) .And. !Empty(_oObj:GetValue("A7_I_CDPRX"))
			_lRet := .F.
			Help(" ",1,"MATA370PE01",,"Deve ser informado no campo "+AllTrim(GetSX3Cache("A7_I_CDPRX","X3_TITULO"))+" apenas quando não For possível informar o código no campo padrão: "+AllTrim(GetSX3Cache("A7_CODCLI","X3_TITULO"));
				,1,4, NIL, NIL, NIL, NIL, NIL, {"Verifique Cliente "+_oObj:GetValue("A7_CLIENTE")+"/"+_oObj:GetValue("A7_LOJA")+"."})
		EndIf
	ElseIf _cIdPonto == "FORMLINEPRE"//Chamada na pré validação da linha do formulário
	ElseIf _cIdPonto == "FORMLINEPOS"//Chamada na validação da linha do formulário
	ElseIf _cIdPonto == "MODELCOMMITTTS"//Chamada após a gravação total do modelo e dentro da transação.
	ElseIf _cIdPonto == "MODELCOMMITNTTS"//Chamada após a gravação total do modelo e fora da transação.
	ElseIf _cIdPonto == "FORMCOMMITTTSPRE"//Chamada após a gravação da tabela do formulário.
	ElseIf _cIdPonto == "FORMCOMMITTTSPOS"//Chamada após a gravação da tabela do formulário.
	ElseIf _cIdPonto == "MODELCANCEL"
	ElseIf _cIdPonto == "BUTTONBAR"
	EndIf
EndIf

Return _lRet
