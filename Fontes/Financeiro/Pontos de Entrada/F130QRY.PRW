/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |29/12/2020| Chamado 35123. Corrigido erro.log que ninguém quis corrigir.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: F130QRY
Autor-------------: Josué Danich Prestes
Data da Criacao---: 02/12/2015
Descrição---------: Ponto de Entrada que inclui filtros na query do relatório FINR130 - Titulos a receber - Chamado 12333
					Permite a utilização de filtros na consulta principal do relatório FINR130 usando comando sql possíveis 
					dentro da clausula where usando campos do SE1 e do SA1 apenas. 
Parametros--------: Nenhum
Retorno-----------: cQry - String contendo o filtro a ser inserido na consulta. 
===============================================================================================================================
*/
User Function F130QRY()

Local _cQuery := ""

//filtro de rede de cliente
If !Empty(MV_PAR44)
	_cQuery += " AND (SELECT A1_GRPVEN FROM " + RetSqlName("SA1") + " WHERE A1_FILIAL = '" + xFilial("SA1") + "' AND A1_COD = E1_CLIENTE"
	_cQuery += " AND A1_LOJA = E1_LOJA AND ROWNUM = 1) IN " + FormatIn(AllTrim(MV_PAR44),";")	
EndIf
//filtro de data de vencimento original
If !Empty(MV_PAR45) .And. !Empty(MV_PAR46)
	_cQuery += " AND E1_VENCTO BETWEEN '" + DToS(MV_PAR45) + "' AND '" + DToS(MV_PAR46) + "'"
EndIf
// Filtro por natureza de operação que deverão ser excluidas do relatório. 
If !Empty(MV_PAR47)
   _cQuery += " AND E1_NATUREZ NOT IN " + FormatIn(AllTrim(MV_PAR47),";")
EndIf

Return _cQuery
