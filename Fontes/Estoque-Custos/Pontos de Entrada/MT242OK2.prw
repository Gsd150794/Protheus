/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Josué Danich  |22/08/2016| Chamado 17785. Inclusão de validação de saldos retroativos para desmontagem
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: MT242OK2
Autor-----------: Josué Danich Prestes
Data da Criacao-: 22/08/2016
Descrição-------: Ponto de Entrada que valida lancamento no cabecalho da desmontagem 
Parametros------: Nenhum
Retorno---------: Lógico, permitindo ou não a gravação o movimento
===============================================================================================================================
*/
User Function MT242OK2()

Local 	_aArea	:=	FWGetArea()
Local	_lRet	:=	.T.

Private aSldNeg := {}
	
If SubStr(cproduto,1,4) = "0006"

	If nqtdorigse = 0

			xMagHelpFis("Segunda Unidade de Medida Vazio","Para esse produto e obrigatorio o preenchimento da segunda unidade de medida (Peças).",;
						"Favor preencher a segunda unidade de medida (Peças)!!")
			_lRet := .F.

	EndIf

EndIf

//Varre os saldos de cada dia atá a data de hoje buscando por saldo insuficiente
MsAguarde({|| aSldNeg := U_VldEstRetrNeg(cProduto, cLocorig, nQtdorig, dEmis260) },"Verificando saldos...")   
  

If Len(aSldNeg) > 0
   
	xMagHelpFis("Atenção!", "Não permitido, pois o produto " + AllTrim(cProduto) + " no armazém " + cLocorig + " não tem saldo suficiente em " + DToC(aSldNeg[1]) + ". Saldo na data:" + TRANSFORM(aSldNeg[2],"@E 999,999.99"),;
   						"Selecionar quantidade ou data de produto que não gere saldos negativos.")
    _lRet  := .F.
   
EndIf      
	
	
FWRestArea(_aArea)
	
Return _lRet
