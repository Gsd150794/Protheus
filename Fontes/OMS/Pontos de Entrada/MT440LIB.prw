/*
=====================================================================================================================================
                                    ATUALIZACOES SOFRIDAS DESDE A CONSTRUÇAO INICIAL
=====================================================================================================================================
       Autor     |    Data    |                                             Motivo                                           
-------------------------------------------------------------------------------------------------------------------------------------
 Josué Danich    | 29/12/2015 | Incluida validação de estoque da exclusão até data atual - Chamado 13403                     
-------------------------------------------------------------------------------------------------------------------------------------
 Josué Danich    | 30/12/2015 | Retirada validação de estoque da exclusão até data atual - Chamado 13446                     
-------------------------------------------------------------------------------------------------------------------------------------
 Alex Wallauer   | 01/02/2021 | Remoção de bugs apontados pelo Totvs CodeAnalysis. Chamado: 34262
=====================================================================================================================================
*/

//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================
#Include "TOTVS.ch"
#Include "RwMake.ch"

/*
===============================================================================================================================
Programa----------: MT440LIB
Autor-------------: Josué Danich Prestes
Data da Criacao---: 16/10/2015
===============================================================================================================================
Descrição---------: Ponto de entrada que valida a liberação automatica de pedidos  - Chamado 12083
===============================================================================================================================
Uso---------------: Liberacao de Pedidos de Vendas Automatica - Function a440Proces() do programa Mata440.PRX	
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: .T. - Permite Liberação .F. - Não permite a Liberação		
===============================================================================================================================
*/
User Function MT440LIB()

Local _aArea		:=FWGetArea()            //Salva area geral
Local _aAreaSC6	:= SC6->(GetArea())
Local _aAreaSC5	:= SC5->(GetArea())
Local _aAreaSA2	:= SA2->(GetArea())
Local _aAreaSA1	:= SA1->(GetArea())
Local _lRet		:= .T.
Local _aRet		:= {}
Local _cmens		:= ""
Local _nqtde		:= ( SC6->C6_QTDVEN - ( SC6->C6_QTDEMP + SC6->C6_QTDENT ) )
Local _nitem		:= Val(SC6->C6_ITEM)
Local _cpedido	:= AllTrim(SC6->C6_NUM)
Local _nmax	   	:= 1 
Local _cCodUsr	:= AllTrim(RetCodUsr())


//posiciona SC5
DBSelectArea("SC5")
SC5->( DBSetOrder(1) )
SC5->( DBSeek(xFilial("SC5")+_cpedido) )


If SC5->C5_TIPO $ "BD"

	DBSelectArea("SA2")
	SA2->( DBSetOrder(1) )
	SA2->( DBSeek(xFilial("SA2")+SC5->C5_CLIENTE+SC5->C5_LOJACLI))

	If SA2->A2_MSBLQL =='1'

		_lRet:= .F.
		_cmens += "O pedido " + SC5->C5_NUM + " não será liberado pois o Fornecedor " + SC5->C5_CLIENTE + "/" + SC5->C5_LOJACLI + ", encontra-se bloqueado." 

	EndIf	

Else

	DBSelectArea("SA1")
	SA1->( DBSetOrder(1) )
	SA1->( DBSeek(xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI) )
	
	If SA1->A1_MSBLQL =='1'

		_lRet:= .F.         
		_cmens += "O pedido " + SC5->C5_NUM + " não será liberado pois o Cliente " + SC5->C5_CLIENTE + "/" + SC5->C5_LOJACLI + ", encontra-se bloqueado." 	

	EndIf	

EndIf

//=======================================================================
//Valida se usuário tem acesso à todos os armazéns usados no pedido
// e se pedido retroativo não gerará saldos negativos
//=======================================================================
If _lRet 

	DBSelectArea("SC6")
	DBSetOrder(1)
	
	If DBSeek(xFilial("SC6")+_cpedido)

		While _cpedido == AllTrim(SC6->C6_NUM) .And. xFilial("SC6") == SC6->C6_FILIAL

	
			//============================================
			//Valida armazémxprodutoxfilialxusuário
			//============================================
			_aRet := U_ACFG004E(_cCodUsr, AllTrim(xFilial("SC6")), AllTrim(SC6->C6_LOCAL),AllTrim(SC6->C6_PRODUTO), .F.)
			
			//se ainda está valido verifica se não teve erro
			If _lRet
		
		  	_lRet:= _aRet[1]
		
			EndIf
		
			// adiciona armazens com problema se ainda não estiver na mensagem
			If Empty(_cmens)
		
				_cmens += "Pedido " + xFilial("SC5") + "/" + _cpedido + "/" + AllTrim(SC6->C6_ITEM) + " - Armazém " + _aRet[2] + CRLF
			
			Else 
		
				_cmens += "Pedido " + xFilial("SC5") + "/" + _cpedido + "/" + AllTrim(SC6->C6_ITEM) + " - Armazém " + _aRet[2] + CRLF
			
			EndIf
			
			//Guarda maior item
			If Val(SC6->C6_ITEM) > _nmax
				_nmax := Val(SC6->C6_ITEM)
			EndIf
			
			SC6->( DBSkip() )
		
		EndDo
		
		//====================================================================================================================================
		//Mostra lista de armazéns com problema somente no ultimo item do pedido para não ficar repetindo erro
		//====================================================================================================================================
		If !(_lRet) .And. !(Empty(_cmens)) .And. _nitem == _nmax

			MessageBox( 'Usuário sem acesso ao(s) armazém(éns) abaixo nessa filial: ' + CRLF + _cmens + CRLF + CRLF+;
					'Caso necessário solicite a manutenção à um usuário com acesso ou, se necessário, solicite o acesso à área de TI/ERP.' , 'Atenção!' , 48 )
	
		EndIf
		
	EndIf

EndIf

// se não validou retorna qtde 0 para liberação e nãos erá executada liberação para esse pedido
If .not. _lRet

	_nqtde := 0
	
EndIf

      
FWRestArea(_aArea) //-- Restaura a posição da tabela corrente  
FWRestArea(_aAreaSC6)
FWRestArea(_aAreaSC5)
FWRestArea(_aAreaSA1)
FWRestArea(_aAreaSA2)

Return _nqtde
