/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Antonio Neves |09/04/2024| Chamado 46242. Inclusão da Rotina FINA740 (Funções CR) para também gerar CNAB Abatimento
Igor Melgaço  |08/11/2024| Chamado 49091. Tratativa de Instrução Bancária e Cobrança, de modo a atender aos novos leiautes do Itaú e Bradesco
===============================================================================================================================
*/

#Include "Totvs.ch"

/*
===============================================================================================================================
Programa.........: AFIN036
Autor............: ANTONIO NEVES
Data da Criacao..: 07/03/2024
Descricao........: Rotina para modificar as informações de envio quando houver Instrução Bancária de Abatimento
Parametros.......: Nenhum
Retorno..........: Nenhum
===============================================================================================================================
*/
User Function AFIN036(Opc)

	Local _aAreaFI2	:= FWGetArea()
	Local _cValRet	:= 0

	If FUNNAME() =="FINA150" .Or. FUNNAME() =="FINA740"
		If Opc == 1
			If SE1->E1_PORTADO == "237" .And. MV_PAR09==1
				_cValRet := StrZero((Round(SE1->E1_SALDO,2)*100),13)
			Else
				_cValRet := StrZero(Round(SE1->E1_SALDO,2)*100,15)
			EndIf
		Else
			If SE1->E1_PORTADO == "237" .And. MV_PAR09==1
				_cValRet := StrZero(SE1->E1_DECRESC,13)
			Else
				_cValRet := StrZero(INT((SE1->E1_DESCONT+SE1->E1_I_DESCO+SE1->E1_DESCFIN)*100),15)
			EndIf
		EndIf
	ElseIf FUNNAME() == "FINA151"
		If Opc == 1
			If SE1->E1_PORTADO == "237" .And. MV_PAR09==1
				If FI2->FI2_OCORR <>'04'
					_cValRet := StrZero((Round(SE1->E1_SALDO,2)*100),13)
				Else
					_cValRet := StrZero((Val(StrTran(FI2->FI2_VALANT,",","."))*100),13)
				EndIf

			Else
				If FI2->FI2_OCORR <>'04'
					_cValRet := StrZero(Round(SE1->E1_SALDO,2)*100,15)
				Else
					_cValRet := StrZero((Val(StrTran(FI2->FI2_VALANT,",","."))*100),15)
				EndIf
			EndIf
		Else
			If SE1->E1_PORTADO == "237" .And. MV_PAR09==1
				If FI2->FI2_OCORR <>'04'
					_cValRet := StrZero(SE1->E1_DECRESC,13)
				Else
					_cValRet := StrZero((Val(StrTran(FI2->FI2_VALNOV,",","."))*100),13)
				EndIf
			Else
				If FI2->FI2_OCORR <>'04'
					_cValRet := StrZero(INT((SE1->E1_DESCONT+SE1->E1_I_DESCO+SE1->E1_DESCFIN)*100),15)
				Else
					_cValRet := StrZero((Val(StrTran(FI2->FI2_VALNOV,",","."))*100),15)
				EndIf
			EndIf
		EndIf
	EndIf

	FWRestArea(_aAreaFI2)

Return(_cValRet)

