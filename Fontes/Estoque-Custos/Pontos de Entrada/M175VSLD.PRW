/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |11/10/2018| Chamado 26614. Ajuste na validação do estoque negativo
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: M175VSLD
Autor-------------: Andre Lisboa
Data da Criacao---: 05/10/2016  
Descrição---------: Ponto de entrada para validar o estorno das liberacoes/rejeicoes do CQ.	
Parametros--------: Nenhum
ARetorno-----------: .T. ou .F.
===============================================================================================================================
*/
User Function M175VSLD

Local _URet		:= .T.
Local aSldNeg   := {}
Local _nQtde := aCols[N][aScan(aHeader, {|x| AllTrim(x[2]) == "D7_QTDE"})]
Local _dData := aCols[N][aScan(aHeader, {|x| AllTrim(x[2]) == "D7_DATA"})]
Local _cLocal:= aCols[N][aScan(aHeader, {|x| AllTrim(x[2]) == "D7_LOCDEST"})]

aSldNeg := U_VldEstRetrNeg(SD7->D7_PRODUTO,_cLocal,_nQtde,_dData)

If Len(aSldNeg) > 0
	_URet := .F.
	U_ITMsg("Não permitido, o estorno deixará o produto com saldo negativo: " +SD7->D7_PRODUTO+" "+_cLocal+" na data " +DToC(aSldNeg[1]),;
	        "Atenção!",;
   			"Verificar o saldo através do kardex do produto",1)
EndIf

Return _URet
