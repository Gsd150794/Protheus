/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |17/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25
Lucas Borges  |19/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: ACOM037
Autor-------------: Josué Danich Prestes
Data da Criacao---: 10/04/2019
Descrição---------: Função chamada dos gatilhos do campo D1_TES - Chamado 28865
Parametros--------: _ncampo - gatilho que está sendo chamado
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ACOM037(_ncampo)

Local _nPosPROD := aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "D1_COD"     } ) // Código do produto
Local _cgrupo := Posicione("SB1",1,xFilial("SB1")+acols[n][_nPosPROD],"B1_GRUPO")
Local _npostotal	:= aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "D1_TOTAL" } )
Local _nposvalicm	:= aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "D1_VALICM" } )
Local _xret

//Correção de bases para  PORTARIA CAT 42/2018 - Chamado 28559
If M->D1_TES $ SuperGetMV("IT_TESCAT4",.F.,"491")
	_nbasest := Posicione("SBM",1,xFilial("SBM")+_cgrupo,"BM_I_BASEN")
	_naliqn  := SuperGetMV("IT_ALICAT4",.F.,18)

	If _nbasest > 0
        If _ncampo == 1
	        _xret := acols[n][_npostotal] * _nbasest
        ElseIf _ncampo == 2
	        _xret := (acols[n][_npostotal] * _nbasest * (_naliqn/100)) - acols[n][_nposvalicm]
        ElseIf _ncampo == 3
            _xret := _naliqn
        Else
            _xret := " "
        EndIf
	EndIf
EndIf

Return _xret
