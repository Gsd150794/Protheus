/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |09/09/2024| Chamado 48465. Removendo warning de compilação e corrigida chamada para schedule.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MT103CWH
Autor-------------: Igor Melgaço
Data da Criacao---: 28/10/2021
Descrição---------: Ponto de entrada que Permite alterar o WHEN dos campos da Pré-Nota e NFE. Chamado 38037
Parametros--------: Nenhum
Retorno-----------: lRet - Habilita ou não a edição do campo
===============================================================================================================================
*/
User Function MT103CWH

Local lRet := .T.
Public _lClassif := ParamIXB[3] // .T.-Selecionado opção de classificação    

Return lRet
