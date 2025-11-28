/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz     |10/05/2018| Chamado 24726. Padronização dos cabeçalhos dos fontes e funções do módulo financeiro.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: F070ACRE 
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 11/08/2011	
Descrição---------: Ponto de Entrada com o objetivo alterar o historico padrão informado na baixa de titulos a receber seja 
                    manual ou automatica.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function F070ACRE()

cHist070:=SE1->E1_NOMCLI+Space(Len(cHist070)-Len(SE1->E1_NOMCLI))

Return
