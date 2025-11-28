/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Vanderson     |10/04/2017| Chamado 16924. Criação do ponto-de-entrada de limpeza do campo E1_NUMBCO.
Julio Paz     |13/10/2017| Chamado 16924. Padronização do fonte (Cabeçalhos, gravação de log de acesso).
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: F060POR2
Autor-------------: Vanderson Vasconcelos
Data da Criacao---: 10/04/2017                                  
Descrição---------: Limpeza do campo E1_NUMBCO no momento da transferência entre carteiras (FINA060).
Parametros--------: Nenhum
Retorno-----------: .T. = faz com que o sistema não limpe o campo E1_NUMBCO na transferencia.
                    .F. = faz com que o sistema limpe o campo E1_NUMBCO na transferencia.
===============================================================================================================================
*/
User Function F060POR2()
Local _lRet := .T.

U_ITLOGACS() //Grava log de utilização

Return _lRet
