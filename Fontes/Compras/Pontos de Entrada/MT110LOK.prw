/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Jonathan      |04/05/2020| Chamado 32763. Alterar chamada "MsgBox" para "U_ITMsg".
Alex Wallauer |24/10/2022| Chamado 41652. Permitir fracionar produtos <> "PA" quando o campo ZZL_PEFROU For = "S". 
Lucas Borges  |18/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MT110LOK
Autor-------------: Tiago Correa Castro
Data da Criacao---: 01/08/2008
Descrição---------: Ponto de Entrada para verificar a linha digitada na Solicitacao de Compra
------------------:Validacao1: Valida se o codigo do Usuario que esta tentando alterar a Solicitacao de Compra e o mesmo codigo
------------------:do usuario que incluiu a solicitacao de compra.      	                                        		
------------------:Validacao2: Valida se o usuario tentou alterar a data de emissao da solicitacao de compra, e em caso de      
------------------:alteracao da solicitacao o campo de emissao recebe a data atual.                                            
------------------:Validacao3: Valida se o produto existe na tabela SBZ(Indicador de Produto) para a filial em questao.        
------------------:Validacao4: Validacao que nao permiti escolher aprovador que somente aprova solicitacoes por ponto de pedido.
Parametros--------: Nenhum
Retorno-----------: Lógico (.T./.F.) permitindo ou nao gravacao da alteracao.
===============================================================================================================================
*/
User Function MT110LOK

Local _aArea 	:=	FWGetArea()
Local _lOk		:= 	.T.  
Local _cUM_NO_Fracionada:=SuperGetMV("IT_UMNOFRAC",.F.,"PC,UN")
Local _lValidFrac1UM:=.T.
Local _nC1QUANT     := aScan(aHeader, {|x| AllTrim(x[2]) == "C1_QUANT"  })
Local _nC1SEGUM     := aScan(aHeader, {|x| AllTrim(x[2]) == "C1_QTSEGUM"})
Local _nPa	        := aScan(aHeader, {|x| AllTrim(x[2]) == "C1_PRODUTO"})  
Local _nItem		:= aScan(aHeader, {|X| AllTrim(X[2]) == "C1_ITEM"	})

If inclui
	//Valida se o usuario mudou a data de emissao da solicitacao no momento da inclusao
	If DA110DATA <> Date()//Nao permite a inclusao de uma solicitacao com data diferente do que a data atual do servidor
		U_ITMsg("A data de emissao tem que ser igual a data atual.","ATENCAO","A data de emissao tem que ser igual a data atual.",3)
		_lOk	:= .F.
	EndIf
 	ZZL->( DBSetOrder(3) )
	If ZZL->( DBSeek( xFilial("ZZL") + RetCodUsr() ) )
   		If ZZL->ZZL_PEFRPA == "S"  .Or. ZZL->ZZL_PEFROU == "S"
	  		_lValidFrac1UM:=.F.
   		EndIf
	EndIf
	
	If _lValidFrac1UM
		SB1->(DBSeek(xFilial("SB1") + AllTrim(aCols[n,_nPa])))

		If  SB1->B1_UM $ _cUM_NO_Fracionada
			If aCols[n,_nC1QUANT] <> Int(aCols[n,_nC1QUANT]) .And. !GDDeleted(n) 
				_lOk := .F.
				U_ITMsg("O produto / linha " + acols[n][_nPa] + " / " + acols[n][_nItem] + " não pode ter quantidade 1um fracionada.",;
		        "Quantidade inválida",;
		        "Favor ajustar a quantidade para uma quantidade inteira.",1) 
			EndIf
		EndIf

		If  SB1->B1_SEGUM $ _cUM_NO_Fracionada
			If aCols[n,_nC1SEGUM] <> Int(aCols[n,_nC1SEGUM]) .And. !GDDeleted(n)
				_lOk := .F.
				U_ITMsg("O produto / linha " + acols[n][_nPa] + " / " + acols[n][_nItem] + " não pode ter quantidade 2um fracionada.",;
		        "Quantidade inválida",;
		        "Favor ajustar a quantidade para uma quantidade inteira.",1) 
			EndIf
		EndIf

	EndIf

ElseIf altera .And. _lOk
	DA110DATA	:=	Date()
EndIf            

FWRestArea(_aArea)

Return(_lOk)
