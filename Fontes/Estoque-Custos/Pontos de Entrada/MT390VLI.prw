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
Programa--------: MT390VLI
Autor-----------: Tiago Correa Castro
Data da Criacao-: 27/04/2009
Descrição-------: Ponto de Entrada que valida movimento de manutencao de lotes. Valida a obrigatoriedade do preenchimento da 
					segunda unidade de medida quando os produtos pertence ao grupo de produto 0006(Queijo) para controle de 
					estoque de pecas de queijo.
Parametros------: Nenhum
Retorno---------: .T. = Permite confirmar lancamento - .F. = Nao Permite confirmar lancamento
===============================================================================================================================
*/
User Function MT390VLI()

	Local 	_aArea	:=	FWGetArea()
	Local	n_ret	:=	.T.
	
	If SubStr(M->D5_PRODUTO,1,4) = "0006"
		If M->D5_QTSEGUM == 0
			xMagHelpFis("Segunda Unidade de Medida Vazio","Para esse produto e obrigatorio o preenchimento da segunda unidade de medida (Peças).",;
						"Favor preencher a segunda unidade de medida (Peças)!!")
			n_ret := .F.
		EndIf
	EndIf
	
	FWRestArea(_aArea)
Return n_ret
