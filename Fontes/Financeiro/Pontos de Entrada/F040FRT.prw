/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz     |09/05/2018| Chamado 24726. Padronização dos cabeçalhos dos fontes e funções do módulo financeiro.
Lucas Borges  |09/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: F040FRT
Autor-------------: Guilherme D. Gesualdo
Data da Criacao---: 17/10/2012
Descrição---------: Ponto de Entrada para geração da retenção de PCC na emissão do Contas a Receber. 
					O ponto de entrada F040FRT possibilita a manipulação de filiais no cálculo de impostos na rotina de Contas 
					a Receber. Nesta  rotina o ponto de entrada define quais as filias serão inseridas no cálculo.
Parametros--------: Nenhum
Retorno-----------: aRet -> A -> Retorna por meio de uma array quais as filias irão fazer parte do cálculo de impostos na 
					rotina de contas a receber.
===============================================================================================================================
*/
User Function F040FRT() 

Local aFilial := {} 
Local nRegSM0 := SM0->(RECNO()) 
Local cEmpAtu := SM0->M0_CODIGO 
Local cCnpj   := SubStr(SM0->M0_CGC,1,8) 

DBSelectArea ("SM0") 
DBSeek(cEmpAtu) 

While !Eof() .And. SM0->M0_CODIGO == cEmpAtu 

	If SubStr(SM0->M0_CGC,1,8) == cCnpj 

    	aAdd(aFilial,AllTrim(SM0->M0_CODFIL)) 

    EndIf

DBSkip() 

EndDo

SM0->(DBGoTo(nRegSM0)) 

Return (aFilial)
