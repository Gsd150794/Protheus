/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz     |07/05/2018| Chamado 24726. Padronização dos cabeçalhos dos fontes e funções do módulo financeiro.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: AFIN007
Autor-------------: Emerson Dias
Data da Criacao---: 02/12/2008
Descrição---------: Funcao para retornar o digito verificador do codigo de barras.
                    Funcao chamada nos CNAB a Pagar.
Parametros--------: Nenhum
Retorno-----------: cDigVer	:=	Retorna digito verificador do codigo de barras
===============================================================================================================================
*/
User Function AFIN007()

SetPrvt("cDigVer")

If Len(AllTrim(SE2->E2_CODBAR)) == 44
	cDigVer := SubStr(SE2->E2_CODBAR,5,1)
Else
	If Len(AllTrim(SE2->E2_CODBAR)) <> 44  
		cDigVer := SubStr(SE2->E2_CODBAR,33,1)
	EndIf
EndIf	

Return(cDigVer)
