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
Programa----------: FA080OWN
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 01/12/2010
Descrição---------: Ponto de Entrada no cancelamento/exclusao de uma baixa manual.
					Usado para validar se a baixa a ser cancelada/excluida foi gerada a partir da rotina de transferencia de
					emprestimo, caso tenha sido somente podera sofrer um cancelamento ou exclusao por esta rotina.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function FA080OWN

Local _lRetorno:= .T.
Local _cMotBxTr:= GetMv("IT_MOTBXTR") //Aramazena o motivo da baixa quando realizada atraves da rotina de transferencia de emprestimo

If Type('lF080Auto') =='U' .Or. ! lF080Auto  

	If AllTrim(SE5->E5_MOTBX) == AllTrim(_cMotBxTr)
	
		_lRetorno:= .F.  
		
		xMagHelpFis("Informação","Não será possível cancelar/excluir a baixa solicitada.",;
					"Pelo fato deste título ter sido baixado pela rotina de transferencia de emprestimo, diante disso somente podera ser cancelado/excluido por esta rorina.")
	
	EndIf      	

EndIf

Return _lRetorno
