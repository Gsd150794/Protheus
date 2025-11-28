/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz     |07/05/2018| Chamado 24726. Padronização dos cabeçalhos dos fontes e funções do módulo financeiro
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: AFIN009 
Autor-------------: Emerson Dias
Data da Criacao---: 16/01/2009
Descrição---------: Funcao chamada nos CNAB a Receber Banco Bradesco, Banco Mercantil, Brasil. 
                    Monta e Retorna o código do CNAB a partir da leitura da tabela SEE.
Parametros--------: Nenhum
Retorno-----------: cCnab237 = Retorna o código do CNab.
===============================================================================================================================
*/
User Function AFIN009()

cCnab237:= "0"+;
	StrZero(Val(SEE->EE_I_CARTE),3)+;
	StrZero(Val(LEFT(AllTrim(SEE->EE_AGENCIA),Len(AllTrim(SEE->EE_AGENCIA))-1)),5)+;
	StrZero(Val(SUBS(SEE->EE_CONTA,1,Len(AllTrim(SEE->EE_CONTA))-1)),7)+; 
	RIGHT(AllTrim(SEE->EE_CONTA),1)    //CPO = 17 posicoes
	
Return(cCnab237)

/*
===============================================================================================================================
Função------------: IDENTIT 
Autor-------------: Emerson Dias
Data da Criacao---: 16/01/2009
Descrição---------: Monta a chave de pesquisa do título no financeiro, vinculada ao CNAB.
Parametros--------: Nenhum
Retorno-----------: cCnab389 = Chave de pesquisa do título financeiro vinculado ao CNAB.
===============================================================================================================================
*/
User Function IDENTIT()
cCnab389:= SE1->E1_PREFIXO+StrZero(Val(SE1->E1_NUM),17)+StrZero(Val(SE1->E1_PARCELA),2)+SE1->E1_TIPO //CPO = 25 posicoes.

Return(cCnab389) 
