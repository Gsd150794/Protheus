/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
       Autor      |    Data    |                                             Motivo                                           
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges      | 15/10/2019 | Removidos os Warning na compilação da release 12.1.25. Chamado 28346
===============================================================================================================================
*/

//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================
#Include "TOTVS.ch"
#Include "topconn.ch"
#Include "rwmake.ch"

/*
===============================================================================================================================
Programa--------: AOMS019
Autor-----------: Frederico O. C. Jr
Data da Criacao-: 27/10/2008
===============================================================================================================================
Descrição-------: Funcao chamada em gatilho para validar se Placa ja existe cadastrada no cadastro de veiculos
					Funcao chamada por gatilho nos campos de cadastro de placa
					DA3_PLACA  - 001
					DA3_I_PLCV - 001
					DA3_I_PLVG - 001
===============================================================================================================================
Parametros------: cPlaca -> placa a ser validada
					nCampo -> campo que chamou a rotina
					DA3_PLACA -> 1  /  DA3_I_PLCV -> 2  /  DA3_I_PLVG -> 3
===============================================================================================================================
Retorno---------: Se placa pode ser cadastrada ou nao
===============================================================================================================================
*/
User Function AOMS019(cPlaca, nCampo)

	Local aArea 	:= FWGetArea()
	Local cQuery	:= ""
	Local lRet		:= .F.
	Local cVeiculo	:= ""
	
	cQuery := "SELECT DA3_PLACA as PLACA, DA3_COD"
	cQuery += " FROM " + RetSqlName("DA3")
	cQuery += " WHERE D_E_L_E_T_ = ' ' AND DA3_PLACA = '" + cPlaca + "'"
	
	cQuery += " UNION ALL"
	
	cQuery += " SELECT DA3_I_PLCV as PLACA, DA3_COD"
	cQuery += " FROM " + RetSqlName("DA3")
	cQuery += " WHERE D_E_L_E_T_ = ' ' AND DA3_I_PLCV = '" + cPlaca + "'"
	
	cQuery += " UNION ALL"
	
	cQuery += " SELECT DA3_I_PLVG as PLACA, DA3_COD"
	cQuery += " FROM " + RetSqlName("DA3")
	cQuery += " WHERE D_E_L_E_T_ = ' ' AND DA3_I_PLVG = '" + cPlaca + "'"

	dbUseArea( .T., "TOPCONN", TcGenQry(,,cQuery), "TEMP", .T., .F. )
	DBSelectArea("TEMP")

	If ( !Eof() )
		lRet		:= .T.
		cVeiculo	:= TEMP->DA3_COD
	end

	TEMP->(DBCloseArea())
		
	If ((nCampo == 1) .And. (!lRet))
	
		If ((cPlaca == M->DA3_I_PLCV) .Or. (cPlaca == M->DA3_I_PLVG))
			MsgAlert("A placa  " + cPlaca + " já foi utilizada neste mesmo veículo.","Alerta")
			cPlaca	:= Space(8)
			lRet	:= .T.
		EndIf
		
	ElseIf ((nCampo == 2) .And. (!lRet))

		If ((cPlaca == M->DA3_PLACA) .Or. (cPlaca == M->DA3_I_PLVG))
			MsgAlert("A placa  " + cPlaca + " já foi utilizada neste mesmo veículo.","Alerta")
			cPlaca := Space(8)
			lRet	:= .T.
		EndIf
	
	ElseIf ((nCampo == 3) .And. (!lRet))

		If ((cPlaca == M->DA3_PLACA) .Or. (cPlaca == M->DA3_I_PLCV))
			MsgAlert("A placa  " + cPlaca + " já foi utilizada neste mesmo veículo.","Alerta")
			cPlaca := Space(8)
			lRet	:= .T.
		EndIf

	EndIf
	
	If (lRet)
		If !MsgYesNo("A placa  " + cPlaca + " esta cadastrada no veículo " + cVeiculo + "." + Chr(13) + Chr(10) + "Deseja continuar o cadastro desta placa?","Atencao")
			cPlaca := Space(8)
		EndIf
	EndIf
	
	FWRestArea(aArea)
	
Return cPlaca
