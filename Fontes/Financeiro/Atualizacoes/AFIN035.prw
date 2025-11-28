/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Antonio Neves |05/03/2024| Correção do Retorno do Numero da NF para o campo virtual
===============================================================================================================================
*/

#Include "Totvs.ch"

/*
===============================================================================================================================
Programa.........: AFIN035
Autor............: ANTONIO NEVES
Data da Criacao..: 28/02/2024
Descricao........: Rotina Para Retornar o Número da Nota Fiscal de Remessa para os títulos de Faturamento da Op. Triangular
Parametros.......: Nenhum
Retorno..........: Nenhum
===============================================================================================================================
*/
User Function AFIN035(__cFilial,__cNum,__cPref)

	Local _aAreaSE1 := FWGetArea()
	Local __cPedVen := ""
	Local __cPedRem := ""
	Local __cDocRem := ""
	Local __IndPed  := "IT_I_PEDID"


	__cPedVen   := Posicione("SF2",1,__cFilial+__cNum+__cPref,"F2_I_PEDID")
	__cPedRem   := Posicione("SC5",1,__cFilial+__cPedVen,"C5_I_PVREM")

	If !Empty(__cPedRem)
		DBSelectArea("SF2")
		dbOrderNickName(__IndPed)
		If DBSeek(__cFilial+__cPedRem)
			__cDocRem := SF2->F2_DOC+" - "+SF2->F2_SERIE
		EndIf
	EndIf
	FWRestArea(_aAreaSE1)

Return(__cDocRem)
