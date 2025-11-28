/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Andre Lisboa  |20/04/2016| Chamado 15194. Correção do posicionamento na tabela SB2, buscando cod+armazem
Lucas Borges  |10/09/2024| Chamado 48465. Removendo warning de compilação.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: AEST041
Autor-------------: Andre Lisboa
Data da Criacao---: 25/02/2015
Descricao---------: Rotina para calcular valor da perda conforme quantidade informada, multiplicando pelo CM do produto
                    Gatilho SB6->B6_QUANT, SBC->BC_I_CUSTO
Parametros--------:
Retorno-----------:
===============================================================================================================================
*/
User Function AEST041()

Local _aArea     	:= FWGetArea()
Local _nQtdOriP   := aScan(aHeader,{|X| Upper(AllTrim(X[2]))=="BC_QUANT"})    
Local _nQtdOri 	:= aCols[N][_nQtdOriP]
Local _cPdOriP		:= aScan(aHeader,{|X| Upper(AllTrim(X[2]))=="BC_PRODUTO"})    
Local _cPrdOri		:= aCols[N][_cPdOriP]
Local _cAzOriP		:= aScan(aHeader,{|X| Upper(AllTrim(X[2]))=="BC_LOCORIG"})    
Local _cAmzOri		:= aCols[N][_cAzOriP]
Local _nCM			:= 0
Local _nCT			:= 0

_nCM := Posicione("SB2",1,xFilial("SB2")+_cPrdOri+_cAmzOri,"B2_CM1")
If _nQtdOri > 0
   _nCT:= _nQtdOri * _nCM
EndIf
FWRestArea(_aArea)

Return(_nCT)   
