/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Vanderson     |10/04/2017| Chamados 21905/21857/21793. Alteração do ponto-de-entrada para retornar .T. e considerar apenas a 
              |          | filial corrente.
Julio Paz     |13/10/2017| Chamado 21905. Padronização do fonte (Cabeçalhos, gravação de log de acesso).
Lucas Borges  |09/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: F470ALLF
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 08/06/2016
Descrição---------: Ponto de Entrada que defini se o sistema filtrará todas as filiais ou apenas a filial corrente.
                    Este ponto de entrada permite a sinalização de que deve ser feito o  tratamento do extrato utilizando o 
                    filtro da filial corrente. A rotina de Extrato Bancario dispõe de tratamentos para que a filial do SE5 não 
                    seja filtrada caso quando 'SA6 exclusivo' e 'SE5 compartilhado' Esse controle é feito garantir a 
                    integridade do Extrato Bancário. No entanto,  o cliente pode utilizar suas tabelas nessa configuração e  
                    ainda assim ter somente 1 filial ou todos os movimentos bancários na mesma filial. Para tal,foi 
                    disponibilizado um Ponto de Entrada para que possa ser sinalizado que quer o tratamento do extrato 
                    utilizando o filtro da filial corrente. 
Parametros--------: ParamIXB[1] lAllFil (L) - informa se o sistema não vai filtrar por filial - considerando todas as filiais 
					(.T.) ou vai filtrar por filial - considerando somente os registros da filial corrente(.F.)
Retorno-----------: lRet -> .F. Considera todas as filiais / .T. Considera apenas filial corrente.
===============================================================================================================================
*/
User Function F470ALLF()
Local _aArea	:= FWGetArea()
Local _lRet		:= .T. 

U_ITLOGACS() //Grava log de utilização

FWRestArea(_aArea)
Return(_lRet)
