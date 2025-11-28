/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |25/03/2022| Chamado 39465. Migração das informações financeiras para as tabelas FKs no Leite.
Lucas Borges  |08/10/2023| Chamado 45186. Corrigida a gravação das informações do Mix.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: FINM020
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 27/12/2021
Descrição---------: ponto de entrada MVC executado na baixa/cancelamento do Contas a Pagar
Parametros--------: ParamIXB -> C -> Nome da função que esta sendo executada. Ex. FINM
Retorno-----------: lRet -> L -> .T. = Continua executando a rotina/ .F. = Nao executa a rotina.
===============================================================================================================================
*/
User Function FINM020

Local _aParam	:= ParamIXB
Local _lRet		:= .T.
Local _oObj		:= Nil
Local _cIdPonto	:= ''
Local _cIdModel	:= ''
Local _oModelBxP:= ''
Local _cCamposE5:= ''
Local _cCampOrig:=''
Local _nPos		:=0
If _aParam <> NIL
	_oObj := _aParam[1]
	_cIdPonto := _aParam[2]
	_cIdModel := _aParam[3]
	
	If _cIdPonto == "MODELPOS" //Chamada na validação total do modelo.
	ElseIf _cIdPonto == "FORMPOS"//Chamada na validação total do formulário.
		If _cIdModel == 'FK2DETAIL' .And. _oObj:GetOperation() == 3 .And. (FWIsInCallStack("U_MGLT009") .Or.FWIsInCallStack("U_MGLT011") .Or. FWIsInCallStack("FINXSE5")) 
			_oObj:SetValue("FK2_L_MIX", ZLE->ZLE_COD)
			_oObj:SetValue("FK2_L_SETO", ZL2->ZL2_COD)
			If FWIsInCallStack("U_MGLT009")
				_oObj:SetValue("FK2_L_LINR", ZL3->ZL3_COD)
			EndIf
			_oModelBxP := _oObj:GetModel()

			//Grava dados da linha principal do movimento na baixa
			_cCamposE5 := AllTrim(_oModelBxP:GetValue('MASTER','E5_CAMPOS'))
			If !Empty(_cCamposE5)
				_cCamposE5 := Left(_cCamposE5,Len(_cCamposE5)-1)
				_cCamposE5 += ",{ 'E5_L_MIX', ZLE->ZLE_COD}"
				If FWIsInCallStack("U_MGLT009")
                	_cCamposE5 += ",{ 'E5_L_LINR', ZL3->ZL3_COD}"
				EndIf
				_cCamposE5 += ",{ 'E5_L_SETO', ZL2->ZL2_COD}}"
			Else
				_cCamposE5 := "{{ 'E5_L_MIX',ZLE->ZLE_COD }"
                If FWIsInCallStack("U_MGLT009")
					_cCamposE5 += ",{ 'E5_L_LINR', ZL3->ZL3_COD}"
				EndIf
				_cCamposE5 += ",{ 'E5_L_SETO', ZL2->ZL2_COD}}"
			EndIf

			//Caso existam registros auxiliares na baixa (juros/multa/acréscimos), os campos a serem gravados devem ser passados 
			//antes do pipe(|) para a gravação correta no registro principal
			_cCampOrig:=_cCamposE5 //-- Armazena conteúdo original
			_nPos := At("|",_cCamposE5)//-- Localiza o separador do registro da baixa
			If _nPos > 0
				//-- Adiciona os campos customizados no registro da baixa
				_cCamposE5:= SubStr(_cCamposE5,1,_nPos-2)//-- Pega o conteúdo do registro da baixa (1 posição para tirar o | e outra para o })
				_cCamposE5 += ",{ 'E5_L_MIX', ZLE->ZLE_COD}"
				If FWIsInCallStack("U_MGLT009")
                	_cCamposE5 += ",{ 'E5_L_LINR', ZL3->ZL3_COD}"
				EndIf
				_cCamposE5 += ",{ 'E5_L_SETO', ZL2->ZL2_COD}}"
				//-- Aglutina os demais registros 	
				_cCamposE5 += SubStr(_cCampOrig,_nPos,Len(_cCampOrig))
			EndIf
			_oModelBxP:SetValue( "MASTER","E5_CAMPOS",_cCamposE5 ) // Informando o atributo "E5_CAMPOS"
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
