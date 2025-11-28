/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
André Lisboa  |21/03/2014| Chamado 5643. Bloquear acesso à edição do número do documento.
Alexandre V.  |12/01/2015| Atualização da rotina para remoção de código que não está em uso.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MTA261DOC
Autor-------------: Wodson Reis Silva
Data da Criacao---: 05/03/2009
Descrição---------: Ponto de entrada para validar se o Núm. do Documento pode ser editado
Parametros--------: Nenhum
Retorno-----------: Lógico - Define se o usuário tem acesso a editar o campo.
===============================================================================================================================
*/
User Function MTA261DOC

Local _lRet := .F. //Variavel logica para retorno - Andre 21/03/2014 - Help 5643

Return( _lRet ) //alterado para atender chamado 5643
