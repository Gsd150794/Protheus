/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |23/01/2024| Chamado 46153. Fernando. Gravação do campo RD0_FVIAJ com "2" na inclusão do funcionario.
Lucas Borges  |14/08/2025| Chamado 51811. Corrigida a gravação na RD0 quando o usuário possui mais de uma matrícula
Lucas Borges  |04/09/2025| Chamado 51643. Incluída nova exceção para não processar o PE - AGPE003
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: GP010AGRV
Autor-------------: Josué Danich Prestes
Data da Criacao---: 21/08/2018
Descrição---------: Ponto de Entrada após gravação da SRA - Chamado 25620
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function GP010AGRV

Local _aArea := FWGetArea() As Array
Local _aAreaRD0 := RD0->(FWGetArea()) As Array

If !IsInCallStack("GPEA180") .Or. IsInCallStack('U_AGPE003')
	If Inclui
		RD0->(DBSetOrder(6))
		If RD0->(DBSeek(xFilial('RD0')+SRA->RA_CIC))
			While RD0->(!Eof()) .And. RD0->RD0_CIC == SRA->RA_CIC
				If RD0->RD0_DTADMI == SRA->RA_ADMISSA
					RD0->(RecLock("RD0",.F.))
					RD0->RD0_PORTAL := "000001" //000001-Usuário Padrão / 000004 - Gestores
					RD0->RD0_FVIAJ  := "2"
					RD0->(MSUnLock())
				EndIf
				RD0->(DBSkip())
			EndDo
		Else
			FWAlertWarning("CPF/CNPJ [ "+SRA->RA_CIC+" ] não cadastrado na tabela Pessoas / Participantes ( RD0 ). Cadastre manualmente.","GP010AGRV01")
		EndIf 
	RD0->(FWRestArea(_aAreaRD0))

	EndIf
	//Integração COONTROLID
	U_MGPE026(IIf(Exclui,3,IIf(Inclui,1,2)))

	//Integração DIMEP
	U_MPON002(4)
EndIf
FWRestArea(_aArea)

Return
