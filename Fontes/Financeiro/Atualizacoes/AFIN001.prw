/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz     |04/05/2018| Chamado 24726. Padronização dos cabeçalhos dos fontes e funções do módulo financeiro.
Lucas Borges  |04/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: AFIN001
Autor-------------: Frederico O. C. Jr
Data da Criacao---: 28/08/2009
Descrição---------: Funcao chamada no CNAB a Pagar pelo Banco Itau - para a montagem da conta do favorecido 
Parametros--------: Nenhum
Retorno-----------: Conta do favorecido.
===============================================================================================================================
*/
User Function AFIN001

Local cRet := ""
Local cAux := ""
Local nAux := 0
	
If SA2->A2_BANCO <> "399"	// Bancos exceto o HSBC
	cAux := AllTrim(SA2->A2_NUMCON)
	nAux := Len(AllTrim(SA2->A2_NUMCON))
	cRet := StrZero(Val( SubStr(cAux,1,nAux-1) ),12) + " "
	cRet += SubStr(cAux,nAux,1)
Else						// Banco HSBC
	cAux := AllTrim(SA2->A2_NUMCON)
	nAux := Len(AllTrim(SA2->A2_NUMCON))
	cRet := StrZero(Val( SubStr(cAux,1,nAux-2) ),12)
	cRet += SubStr(cAux,nAux-1,2)
EndIf

Return(cRet)
