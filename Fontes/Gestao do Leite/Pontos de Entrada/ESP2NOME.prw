/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: ESP2NOME
Autor-------------: TOTVS
Data da Criacao---: 22/12/2009
Descrição---------: Ponto de Entrada, para acesso ao ambiente personalizado Gestão do Leite, da mesma forma que ocorre
                    para os modulos do protheus.
                    Criar um arquivo de menu dentro do system chamado SIGAGLT.XNU e outro SIGAESP2.XNU.
                    SIGAESP2.XNU fica para acesso do Administrador.
                    SIGAGLT.XNU fica para acesso dos usuarios do ambiente Gestao do Leite.
                    Pode-se usar ESPNome() tambem, porem no Protheus10, esta tendo modulo com este nome no padrao.
Parametros--------: Nenhum
Retorno-----------: Nome do Modulo
===============================================================================================================================
*/
User Function ESP2NOME
Return("Gestão do Leite")
