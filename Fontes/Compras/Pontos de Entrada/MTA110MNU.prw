/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Jerry         |18/02/2019| Chamado 28103. Substituir MT110ROT, pq a rotina de privilégio não valida opções do MT110ROT
===============================================================================================================================
*/

#Include "TOTVS.ch"             

/*
===============================================================================================================================
Programa----------: MTA110MNU
Autor-------------: Darcio Ribeiro Sporl
Data da Criacao---: 09/09/2015
Descrição---------: Ponto de Entrada para adição de novas rotinas no menu Ações Relacionadas
Parametros--------: Nenhum
Retorno-----------: Retorno aRotina - Array contendo as novas opções de menu
===============================================================================================================================
*/
User Function MTA110MNU
     

aAdd( aRotina, { 'Transf. Aprovador'      , 'U_ACOM001T()', 0, 4 } )
aAdd( aRotina, { 'Reenvio WF'	       , 'U_MCOM003E()', 0, 4 } )
aAdd( aRotina, { 'Alter.Cod.Invest.'      , 'U_ACOM019()' , 0, 4 } )

Return aRotina
