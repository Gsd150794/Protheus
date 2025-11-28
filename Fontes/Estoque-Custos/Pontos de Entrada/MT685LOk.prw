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
Programa----------: MT685LOk
Autor-------------: Renato de Morcerf
Data da Criacao---: 03/02/2009
Descrição---------: Ponto de Entrada que valida lancamento do apontamento de perda. Valida a obrigatoriedade do preenchimento 
					da segunda unidade de medida quando os produtos pertence ao grupo de produto 0006(Queijo) para controle de
					estoque de pecas de queijo.
Parametros--------: Nenhum
Retorno-----------: .T. = Permite confirmar lancamento - .F. = Nao Permite confirmar lancamento 	   
===============================================================================================================================
*/
User Function MT685LOK()

	Local	aArea	:=	FWGetArea()
	Local 	nPa   	:= 	""
	Local 	_npl  	:= 	""
	Local 	nPa2  	:= 	""
	Local 	_npl2 	:= 	""
	Local 	n_ret	:= 	.T.

	If aCols[n][Len(aHeader)+1] == .F. //Linha nao Deletada

		nPa  :=  aScan( aHeader, { |x| AllTrim(x[2])== "BC_PRODUTO" } )
		_npl := acols[n,nPa]
	
		If SubStr(_npl,1,4) = "0006"
	
			nPa2  :=  aScan( aHeader, { |x| AllTrim(x[2])== "BC_QTSEGUM" } )
			_npl2 := acols[n,nPa2]
			If _npl2 = 0
				xMagHelpFis("Segunda Unidade de Medida Vazio","Para esse produto e obrigatorio o preenchimento da segunda unidade de medida (Peças).",;
							"Favor preencher a segunda unidade de medida (Peças)!!")
				n_ret := .F.
			EndIf
		EndIf
	EndIf
	
	FWRestArea(aArea)

Return n_ret
