/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Talita        |13/02/2013| Incluída validação para só preencher o campo espécie quanado For formulário próprio.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MT103ESP
Autor-------------: Talita
Data da Criacao---: 08/02/2013
Descrição---------: Validação para inclusão de nota de devolução com preenchimento da espécie de forma automática
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MT103ESP

Local _cRetEsp := NIL

If cFormul == 'S'
	_cRetEsp := 'SPED'
EndIf

Return( _cRetEsp )
