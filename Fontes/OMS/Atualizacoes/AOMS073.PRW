/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |18/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: AOMS073
Autor-----------: Josué Danich Prestes
Data da Criacao-: 15/08/2016
Descrição-------: Validação de campos de segunda unidade - Chamado 16569
Parametros------: _ccampo - Campo sendo validado
Retorno---------: .T. ou .F. se campo pode ser editado ou não
===============================================================================================================================
*/
User Function AOMS073(_ccampo)

Local _lRet := .T.
Local _cproduto := ""
Local _nproduto := 0 
Local _cgrupo := ""
Local _nquant := 0

If _ccampo == "D1_COD" 
	_nproduto := aScan( aHeader , {|X| Upper( AllTrim( X[2] ) )	== "D1_COD"	}) 
	_cproduto := acols[n][_nproduto] 
	_nquant := M->D1_QTSEGUM		
EndIf

If _ccampo == "C7_PRODUTO" 
	_nproduto := aScan( aHeader , {|X| Upper( AllTrim( X[2] ) )	== "C7_PRODUTO"	}) 
	_cproduto := acols[n][_nproduto] 
	_nquant := M->C7_QTSEGUM
EndIf

If _ccampo == "C1_PRODUTO" 
	_nproduto := aScan( aHeader , {|X| Upper( AllTrim( X[2] ) )	== "C1_PRODUTO"	}) 
	_cproduto := acols[n][_nproduto] 
	_nquant := M->C1_QTSEGUM
EndIf

If _ccampo == "C2_PRODUTO" 
	_cproduto := M->C2_PRODUTO
	_nquant := M->C2_QTSEGUM
EndIf

If _ccampo == "BC_PRODUTO" 
	_nproduto := aScan( aHeader , {|X| Upper( AllTrim( X[2] ) )	== "BC_PRODUTO"	}) 
	_cproduto := acols[n][_nproduto] 
	_nquant := M->BC_QTSEGUM
EndIf

If _ccampo == "C6_PRODUTO" 
	_nproduto := aScan( aHeader , {|X| Upper( AllTrim( X[2] ) )	== "C6_PRODUTO"	})  
	_cproduto := acols[n][_nproduto] 
	_nquant := M->C6_UNSVEN
EndIf

If _ccampo == "D3_COD" 
	If AllTrim(funname()) == "MATA241" 
		_nproduto := aScan( aHeader , {|X| Upper( AllTrim( X[2] ) )	== "D3_COD"	}) 
		_cproduto := AllTrim(acols[n][_nproduto]) 
		_nquant := M->D3_QTSEGUM
	ElseIf funname() == "MATA240"
		_cproduto := AllTrim(M->D3_COD)
		_nquant := M->D3_QTSEGUM
	EndIf
EndIf

_cgrupo := Posicione("SB1",1,xFilial("SB1")+AllTrim(_cproduto),"B1_GRUPO")

If _nquant > 0 .And. Posicione("SB1",1,xFilial("SB1")+AllTrim(_cproduto),"B1_CONV") == 0 .And. !(AllTrim(Posicione("SB1",1,xFilial("SB1")+AllTrim(_cproduto),"B1_GRUPO ")) $ AllTrim(SuperGetMV("IT_GRP2U",.T.,"0006")))
	MessageBox("Produto " + _cproduto + " não tem fator de conversão cadastrado, impossível usar segunda medida!", "Atenção", 16)
	_lRet := .F.
EndIf

Return _lRet
