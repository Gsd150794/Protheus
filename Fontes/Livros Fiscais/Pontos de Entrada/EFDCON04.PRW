/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |02/10/2019| Chamado 30727. Não estava encontrado a conta de outras filiais
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: EFDCON04
Autor-------------: Alex Wallauer
Data da Criacao---: 10/09/2019
Descrição---------: PE no fonte FISX001.prw, para possibilitar a manipulação da descrição do ajuste, da informação 
                    complementar, do numero do processo e da conta contábil que tratam do detalhamento de ajuste do valor ou 
                    ajuste da base de calculo do Crédito de PIS/COFINS apurado - Chamado 27587 
Parametros--------: 
ParamIXB[1]		Carácter	Chave EFD
ParamIXB[2]		Carácter	Tipo de Ajuste
ParamIXB[3]		Carácter	Descrição do ajuste
ParamIXB[4]		Carácter	Código Conta Contábil
ParamIXB[5]		Carácter	CST
ParamIXB[6]		Número		Alíquota
ParamIXB[7]		Número		Valor do Ajuste
ParamIXB[8]		Carácter	Período Atual
ParamIXB[9]		Data		Data Referência
ParamIXB[10]	Lógico		Ajuste de Base de calculo ou de valor do tributo. Se .T. ajuste de base. Se .F. Ajuste de valor.
ParamIXB[11]	Carácter	Tributo que está sendo ajustado. PIS = "1"; COFINS = "2"
ParamIXB[12]	Carácter	Número do documento ou Processo
ParamIXB[13]	Carácter	Informação complementar
Retorno-----------: 
aRet[1]	Carácter	Descrição do ajuste
aRet[2]	Carácter	Informação complementar do ajuste
aRet[3]	Carácter	Número do documento ou processo
aRet[4]	Carácter	Código da conta contábil
===============================================================================================================================
*/
User Function EFDCON04()

Local _aRet   := {"","","",""} 
Local _cContAju:=""

ZGH->(DBSetOrder(5))//ZGH_FILIAL+ZGH_IMPOST+ZGH_ALIQ
If ZGH->(DBSeek(cFilAnt+ParamIXB[11]+Str(ParamIXB[6],7,4) )) .Or. ZGH->(DBSeek("01"+ParamIXB[11]+Str(ParamIXB[6],7,4) ))//Tenta da Filial atual senão achar tenta da 01
   _cContAju:=ZGH->ZGH_CONTA
   _aRet:= {"","","",_cContAju} 
EndIf

If Empty(_cContAju)
	_cFileNome:="\DATA\ITALAC\CONTROLE\EFDCON04.CSV"
	nHandle:=0
	_cCab:='Nossa.ContaContabil;PIS="1"/COFINS="2";Alíquota;Chav.EFD;xFilial("ZGH");cFilAnt'+CRLF
	If FILE(_cFileNome)
		nHandle:=FOpen(_cFileNome,2)
	EndIf
	
	If nHandle > 0
		FSEEK(nHandle,0,0)
		cString:=Space(10)
		FReadLn(nHandle,@cString, 10, .F.)
		If Empty(cString)
			_cLinha:=_cCab
			FWrite(nHandle,_cLinha)
		EndIf
		_cLinha:=_cContAju+";"+ParamIXB[11]+";"+Str(ParamIXB[6],15,5)+";"+ParamIXB[1]+";"+xFilial("ZGH")+";"+cFilAnt+CRLF
		_cLinha:=StrTran(_cLinha,".",",")
		FSEEK(nHandle,0,2)
		FWrite(nHandle,_cLinha)
		FClose(nHandle)
		U_ITCONOUT(_cLinha)
	Else
		U_ITCONOUT("Nao abriu: "+_cFileNome)
	EndIf
EndIf


Return _aRet
