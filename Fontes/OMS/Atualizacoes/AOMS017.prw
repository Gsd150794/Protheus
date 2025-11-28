/* 
================================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
================================================================================================================================
 Autor        |    Data    |                              Motivo
--------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer | 17/09/2019 | Chamado 30543. Ajuste para ignorar a funcao M520_Valida.
Jerry         | 03/11/2020 | Chamado 34566. Validação do Preço de Vendas conforme o Peso do Pedido.
Jerry         | 01/12/2020 | Chamado 34860. Ajuste de validações de origem Efetivação Portal/RDC/Troca Nota e Regras de Preço.
Jerry         | 19/02/2021 | Chamado 35610. Corrigido Função de Busca de Tabela de Preço.
Jerry         | 29/04/2022 | Chamado 38883. Ajuste na Efetivação Automatica Pedido Portal retirando paradas em tela.
===================================================================================================================================================================
Analista         - Programador     - Inicio     - Envio    - Chamado - Motivo da Alteração
===================================================================================================================================================================
Vanderlei Alves  - Alex Wallauer   - 09/06/25   - 10/06/25 - 45229   - Tratamento para validar FWIsInCallStack("U_AOMS085B") junto com FWIsInCallStack("U_ALTERAP")
===================================================================================================================================================================
*/ 

#Include "TOTVS.ch"  
#Include "topconn.ch"
#Include "rwmake.ch"

#DEFINE _ENTER CHR(13) + CHR(10)
 
/*
===============================================================================================================================
Programa--------: AOMS017
Autor-----------: Frederico O. C. Jr
Data da Criacao-: 02/10/2008
===============================================================================================================================
Descrição-------: Preenchimentos dos campos de endereco de entrega e condição de pagto do Pedido de Venda
===============================================================================================================================
Parametros------: _ntipo - 1 muda retorno para .T.
===============================================================================================================================
Retorno---------: cret - estado do cliente ou fornecedor do pedido de vendas
===============================================================================================================================
*/
User Function AOMS017(_ntipo)
 
Local aArea    := FWGetArea() 
Local aAreaSA1 := SA1->(GetArea())
Local aAreaSA3 := SA3->(GetArea())
Local aAreaSC5 := SC5->(GetArea())
Local aAreaACY := ACY->(GetArea())
Local cRet	   := ""
Local _ccond   := ""
Local _cproduto := ""
Local nPosPro:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_PRODUTO"	})
Local _nhi := 0
Local _cGrupoP  := ""
Local _cTipoProd:= ""
Local _laoms074 := .F.
Local _l108     := .F.
Local _lAoms112 := .F.

Default _ntipo := 0


//Se veio do webservice já retorna .T.
If FWIsInCallStack("U_ALTERAP") .Or. FWIsInCallStack("U_INCLUIC") .Or. FWIsInCallStack("U_AOMS085B")
	_laoms074 := .T.
EndIf

//Se veio da rotina de exclusão automática de pedidos de venda já retorna .T.
If FWIsInCallStack("U_AOMS108")
	_l108 := .T.
EndIf 

//Se esta sendo chamado via AOMS112/MOMS050 (Central Pedido Portal / Efetivaççao Automatica)
If FWIsInCallStack("U_AOMS112") .Or. FWIsInCallStack("U_MOMS050")
	_lAoms112 := .T.
EndIf
 
If !FWIsInCallStack("U_AOMS032")

	//=========================================================
	//Se o tipo do pedido de venda For
	//Utiliza Fornecedor  ou   Devolucao de compras            
	//=========================================================                
	If M->C5_TIPO == 'B' .Or. M->C5_TIPO == 'D' 

		
		DBSelectArea("SA2")
		SA2->(DBSetOrder(1))
		If ( SA2->(DBSeek(xFilial("SA2")+M->C5_CLIENT+M->C5_LOJAENT)))
			
			cRet 			:= SA2->A2_EST
			M->C5_I_NOME	:= SA2->A2_NOME
			M->C5_I_FANTA	:= SA2->A2_NREDUZ
			M->C5_I_CMUN	:= SA2->A2_COD_MUN
			M->C5_I_MUN		:= SA2->A2_MUN
			M->C5_I_CEP		:= SA2->A2_CEP
			M->C5_I_END		:= SA2->A2_END
			M->C5_I_BAIRR	:= SA2->A2_BAIRRO
			M->C5_I_DDD		:= SA2->A2_DDD
			M->C5_I_TEL		:= SA2->A2_TEL
			M->C5_I_GRPVE   := ""
			M->C5_I_NOMRD   := ""    
		
		EndIf	
			
	Else

		DBSelectArea("SA1")
		SA1->(DBSetOrder(1))
		If ( SA1->(DBSeek(xFilial("SA1")+M->C5_CLIENT+M->C5_LOJAENT)))
			
			cRet 			:= SA1->A1_EST
			M->C5_I_NOME	:= SA1->A1_NOME
			M->C5_I_FANTA	:= SA1->A1_NREDUZ
			M->C5_I_CMUN	:= SA1->A1_COD_MUN
			M->C5_I_MUN		:= SA1->A1_MUN
			M->C5_I_CEP		:= SA1->A1_CEP 
			M->C5_I_END		:= SA1->A1_END
			M->C5_I_BAIRR	:= SA1->A1_BAIRRO
			M->C5_I_DDD		:= SA1->A1_DDD
			M->C5_I_TEL		:= SA1->A1_TEL
			M->C5_I_GRPVE   := SA1->A1_GRPVEN
			M->C5_I_NOMRD   := Posicione("ACY",1,xFilial("ACY")+SA1->A1_GRPVEN,"ACY_DESCRI")
			M->C5_I_V1NOM   := Posicione("SA3",1,xFilial("SA3")+M->C5_VEND1,"A3_NOME")
			M->C5_I_V2NOM   := Posicione("SA3",1,xFilial("SA3")+M->C5_VEND2,"A3_NOME")
			M->C5_I_V3NOM   := Posicione("SA3",1,xFilial("SA3")+M->C5_VEND3,"A3_NOME")
			M->C5_I_HORP	:= SA1->A1_I_HORP
			
			If Empty(M->C5_I_AGEND) .And. !Empty(AllTrim(SA1->A1_I_AGEND))
			
				M->C5_I_AGEND	:= SA1->A1_I_AGEND
				
			EndIf
			
			M->C5_I_TIPCA	:= SA1->A1_I_TIPCA
			M->C5_I_CHPCL	:= SA1->A1_I_CHAPA
		
			//===============================================================================
			//Localiza se existe condição de pagamento personalizada e preenche C5_CONDPAG 
			//===============================================================================
			
			//=============================================================================================================
			//Verifica condição personalizada para ultimo produto do acols não deletado
			//Como tem validação para só permitir uma condição de pagto no pedido todo verificando a cada entrada de linha
			// não há risco de ter condição de pagamento diferente da condição indicada pelo último produto do pedido
			//==============================================================================================================
			 
			_cproduto := ""  
			For _nhi := 1 to  Len(acols)
			
				If acols[_nhi][Len(acols[_nhi])]
				
					_cproduto := AllTrim(acols[_nhi][npospro])
					
				EndIf
				
			Next
			If M->C5_TIPO = "N" .And. M->C5_I_OPER $ u_itgetmv("IT_TPOPER","01") .And. !FWIsInCallStack("U_AOMS032") .And. ;
   				!(FunName() $ "MATA140,MATA521B,MATA460B,MATA103")  .And. !_lAoms112 .And. !(FWIsInCallStack("U_AOMS099")) .And. !_l108 .And. !_laoms074

				_ccond := u_IT_conpg(AllTrim(M->C5_CLIENT),AllTrim(M->C5_LOJAENT),_cproduto)
				If !Empty(_ccond)

					M->C5_CONDPAG := _ccond 
			
				EndIf
				_cTipoProd := Posicione("SB1",1,xFilial("SB1")+_cproduto,"B1_TIPO")

				If _cTipoProd == "PA"
					_cGrupoP   := Posicione("SB1",1,xFilial("SB1")+_cproduto,"B1_GRUPO")				
					_atab := {}
					_atab := u_ittabprc(cfilant,cfilant,M->C5_VEND3,M->C5_VEND2,M->C5_VEND1,M->C5_CLIENTE,M->C5_LOJACLI,.T.,,M->C5_VEND4,M->C5_I_GRPVE , _cGrupoP)
					_ctab := _atab[1]
					M->C5_I_TAB := _ctab
					M->C5_I_ORTBP := _atab[2]
					M->C5_I_DTAB  := Posicione("DA0",1,cfilant+M->C5_I_TAB,'DA0_DESCRI')                                                          
				EndIf
			EndIf				
		EndIf
	EndIf	 
EndIf

FWRestArea(aAreaSA1)
FWRestArea(aAreaSA3)
FWRestArea(aAreaSC5)
FWRestArea(aAreaACY)
FWRestArea(aArea)

//Retorno de validação sempre true
If _ntipo == 1

	cRet := .T.
	ProcessMessages()

EndIf

Return(cRet) 
