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
Programa----------: MTA242V
Autor-------------: Josué Danich Prestes
Data da Criacao---: 04/09/2015
Descrição---------: Ponto de entrada executado antes de gravação da MATA242, verifica se precisa atualizar doc - Chamado 11725
Parametros--------: 
Retorno-----------: 
===============================================================================================================================
*/
User Function MTA242V()

Local _cnovodoc := U_PEST001()
Local _cret := .T.

//verifica se precisa ajustar número do documento
If cdocumento != _cnovodoc 
	
	alert("Número de documento " + AllTrim(cdocumento) + " já foi utilizado. Será gravado como " + _cnovodoc)
	cdocumento := _cnovodoc	

EndIf 

Return _cret
