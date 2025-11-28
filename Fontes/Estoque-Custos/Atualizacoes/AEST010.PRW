/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Josué Danich  |26/10/2015| Chamado 12478. Inclusão de rotina de retorno de posição de campos e novas validações
Lucas Borges  |10/09/2024| Chamado 48465. Removendo warning de compilação.
Lucas Borges  |19/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: AEST010
Autor-------------: Josué Danich Prestes
Data da Criacao---: 19/10/2015
Descrição---------: Retorno de uso ou não de campo Local de investimento da SA - Chamado 11509
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AEST010

Local _cRet 	:= .T.
Local _nRet 	:= 0

If !(aCols[n][aScan(aHeader,{|X|Upper(AllTrim(X[2]))=="CP_CC"})]=="S")	 
	_nRet := FWAlertYesNo("Altera item para item de investimento?","AEST01001")
	If _nRet == 6
	 	aCols[n][aScan(aHeader,{|X|Upper(AllTrim(X[2]))=="CP_I_INVES"})]:= "S"
	Else
		_cRet := .F.
	EndIf
EndIf

Return _cRet

/*
===============================================================================================================================
Programa----------: AEST010R
Autor-------------: Josué Danich Prestes
Data da Criacao---: 26/10/2015
Descrição---------: Retorno de posição do campo para SCP no acols 
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AEST010R(_cVar)

Local _nPos := aScan(aHeader,{|X|Upper(AllTrim(X[2]))==_cVar})

Return _nPos

/*
===============================================================================================================================
Programa----------: AEST010B
Autor-------------: Josué Danich Prestes
Data da Criacao---: 26/10/2015
Descrição---------: Validação do when do campo CP_I_INVES
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AEST010B

Local _cMot := SuperGetMV("IT_MOTINV",.F.,"15") //motivos de sa que liberam campo investimento
Local _lRet := IIf(AllTrim(U_Vldcc())==AllTrim(aCols[n][U_AEST010R("CP_CC")]) .Or. AllTrim(aCols[n][U_AEST010R("CP_I_MOTIV")])$_cMot,.T.,.F.)

Return _lRet

/*
===============================================================================================================================
Programa----------: AEST010c
Autor-------------: Josué Danich Prestes
Data da Criacao---: 26/10/2015
Descrição---------: Validação do when do campo CP_I_LOCIN
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AEST010C()

Local _lRet := IIf(aCols[n][U_AEST010R("CP_I_INVES")]=="S",.T.,.F.)          

Return _lRet
