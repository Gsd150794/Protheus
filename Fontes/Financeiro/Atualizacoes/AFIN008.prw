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
Programa----------: AFIN008 
Autor-------------: Emerson Dias
Data da Criacao---: 02/12/2008
Descrição---------: Funcao para retornar o campo livre do codigo de barras.
                    Funcao chamada nos CNAB a Pagar. 
Parametros--------: Nenhum
Retorno-----------: cCF = Retorna o campo livre do codigo de barras.
===============================================================================================================================
*/
User Function AFIN008()

SetPrvt("cCF")

If Len(AllTrim(SE2->E2_CODBAR)) == 44
	cCF := SubStr(SE2->E2_CODBAR,20,25)
Else
	If Len(AllTrim(SE2->E2_CODBAR)) <> 44
		cCF := SubStr(SE2->E2_CODBAR,5,5)
		cCF += SubStr(SE2->E2_CODBAR,11,10)
		cCF += SubStr(SE2->E2_CODBAR,22,10)
	EndIf	
EndIf	
           
Return(cCF)
