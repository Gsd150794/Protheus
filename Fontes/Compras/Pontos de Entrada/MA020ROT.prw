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
Programa----------: MA020ROT
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 05/05/2020
Descrição---------: Ponto de Entrada para inclusão de botões do usuário na barra de ferramentas do cadastro de Fornecedores.
Localização: Função principal do programa de inclusão, alteração e exclusão de fornecedores.
Em que Ponto: No início da Função, antes da execução da Mbrowse dos Fornecedores, utilizado para adicionar mais opções de menu 
(no aRotina). Chamado 32851.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MA020ROT

Local _aRotina := {} 
aAdd(_aRotina,{"Replicar Linha","U_MCOM013()",0,4,0,nil})

Return (_aRotina)
