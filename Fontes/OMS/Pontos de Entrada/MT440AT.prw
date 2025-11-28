/*
=====================================================================================================================================
                                    ATUALIZACOES SOFRIDAS DESDE A CONSTRUÇAO INICIAL
=====================================================================================================================================
       Autor      |    Data    |                                             Motivo                                           
-------------------------------------------------------------------------------------------------------------------------------------
 Josué Danich     | 30/09/2015 | Incluída validação de filialxusuárioxarmazém - Chamado 12083                                 
-------------------------------------------------------------------------------------------------------------------------------------
 Alexandre Villar | 27/11/2015 | Incluída validação para verificar a configuração do pedido com relação ao vencimento e frete 
                  |            | para informar ao usuário para que este confirme se quer continuar. Chamado 10369             
-------------------------------------------------------------------------------------------------------------------------------------
 Josué Danich     | 29/12/2015 | Incluida validação de estoque da exclusão até data atual - Chamado 13403                     
-------------------------------------------------------------------------------------------------------------------------------------
 Josué Danich     | 30/12/2015 | Retirada validação de estoque da exclusão até data atual - Chamado 13446                     
-------------------------------------------------------------------------------------------------------------------------------------
 Josué Danich     | 10/03/2016 | Bloqueio de liberação de pedido com C5_LIBEROK = "S"  - Chamado 14690                        
-------------------------------------------------------------------------------------------------------------------------------------
 Alex Wallauer    | 01/02/2021 | Remoção de bugs apontados pelo Totvs CodeAnalysis. Chamado: 34262
=====================================================================================================================================
*/

//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================
#Include "TOTVS.ch"
#Include "RwMake.ch"

/*
===============================================================================================================================
Programa----------: MT440AT
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 10/04/2012
===============================================================================================================================
Descrição---------: Ponto de entrada que valida a liberação de pedidos
===============================================================================================================================
Uso---------------: Liberacao de Pedidos de Vendas - Liberação Manual			
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: .T. - Permite Liberação .F. - Não permite a Liberação		
===============================================================================================================================
*/
User Function MT440AT()

Local _aArea	:= FWGetArea()            //Salva area geral
Local _lRet		:= .T.
Local _aRet		:= {}
Local _cmens	:= ""
Local _cCodUsr	:= AllTrim(RetCodUsr())

//====================================================================================================
// Verifica se o Pedido é uma Devolução/Utiliz.Fornec. para validar o Fornecedor
//====================================================================================================
If SC5->C5_TIPO $ "BD"

	DBSelectArea("SA2")
	SA2->( DBSetOrder(1) )
	If SA2->( DBSeek(xFilial("SA2") + SC5->( C5_CLIENTE + C5_LOJACLI ) ) )
	
		If SA2->A2_MSBLQL == '1'
		
			_lRet := .F.
			MsgStop( "O pedido ["+ SC5->C5_NUM +"] não será liberado pois o Fornecedor "+ SC5->C5_CLIENTE + "/" + SC5->C5_LOJACLI +" encontra-se bloqueado!" , "ATENCAO" )
			
		EndIf
		
	Else
		
		_lRet := .F.
		MsgStop( "O pedido ["+ SC5->C5_NUM +"] é do tipo 'Devolução/Utiliz.Fornec.' e não foi possível posicionar no Fornecedor ["+ SC5->C5_CLIENTE + "/" + SC5->C5_LOJACLI +"]!" , "ATENCAO" )
		
	EndIf

//====================================================================================================
// Caso seja Pedido de Venda valida o Cliente
//====================================================================================================
Else

	DBSelectArea("SA1")
	SA1->( DBSetOrder(1) )
	If SA1->( DBSeek(xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI) )
	
		If SA1->A1_MSBLQL =='1'
		
			_lRet := .F.
			MsgStop( "O pedido ["+ SC5->C5_NUM +"] não será liberado pois o Cliente ["+ SC5->C5_CLIENTE +"/"+ SC5->C5_LOJACLI +"] encontra-se bloqueado!" , "ATENCAO" )
			
		EndIf
	
	Else
	
		_lRet := .F.
		MsgStop( "Não será possível liberar o pedido ["+ SC5->C5_NUM +"] pois o Cliente ["+ SC5->C5_CLIENTE +"/"+ SC5->C5_LOJACLI +" não foi encontrado no Sistema!" , "ATENCAO" )
		
	EndIf
	
	//====================================================================================================
	// Verifica se o Pedido é do Tipo "Normal" e suas amarrações de Frete x Condição de Pagto.
	//====================================================================================================
	If SC5->C5_TIPO == 'N'
		
		If SC5->C5_CONDPAG == '001'
			
			If ITVERTES( SC5->C5_FILIAL , SC5->C5_NUM )
				
				_lRet := MsgYesNo(	'A condição de pagamento do pedido ['+ SC5->C5_NUM +'] foi configurada como [001 - à Vista] e foi utilizada uma TES que gera financeiro, '	+;
									'é recomendado verificar o recebimento ou a antecipação do pagamento!'+ CRLF +'Deseja prosseguir com a liberação do Pedido de Venda?'		 , 'Atenção!' )
				
			EndIf
			
		EndIf
		
		If SC5->C5_TPFRETE == 'F'
			
			_lRet := MsgYesNo(	'O frete do pedido ['+ SC5->C5_NUM +'] foi configurado como [FOB] é recomendado verificar as questões de embarque/descontos do frete!'+ CRLF +;
					 			'Deseja prosseguir com a liberação do Pedido de Venda?' , 'Atenção!' )
			
		EndIf
		
	EndIf

EndIf

//=======================================================================
//Valida se o pedido já foi liberado
//=======================================================================
If _lRet .And. SC5->C5_LIBEROK == 'S' .And. Empty(SC5->C5_NOTA)

		_lRet:= .F.
		MsgStop( "O pedido ["+ SC5->C5_NUM +"] já foi liberado!" , "ATENCAO" )

EndIf


//=======================================================================
//Valida se usuário tem acesso à todos os armazéns usados no pedido
// e se pedido retroativo não gerará saldos negativos
//=======================================================================
If _lRet 

	DBSelectArea("SC6")
	DBSetOrder(1)
	
	If DBSeek(xFilial("SC6")+SC5->C5_NUM)

		While AllTrim(SC5->C5_NUM) == AllTrim(SC6->C6_NUM)

	
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
		
				_cmens += _aRet[2]
			
			ElseIf !(_aRet[2]$_cmens) .And. !(Empty(_aRet[2])) 
		
				_cmens += ", " + _aRet[2]
			
			EndIf		
			
			SC6->( DBSkip() )
		
		EndDo
		
		//============================================
		//Mostra lista de armazéns com problema
		//============================================
		If !(_lRet)

			MessageBox( 'Usuário sem acesso ao(s) armazém(éns) abaixo nessa filial: ' + CRLF + _cmens + CRLF + CRLF+;
					'Caso necessário solicite a manutenção à um usuário com acesso ou, se necessário, solicite o acesso à área de TI/ERP.' , 'Atenção!' , 48 )
	
		EndIf
		
	EndIf

EndIf

FWRestArea(_aArea)

Return (_lRet)

/*
===============================================================================================================================
Programa--------: ITVERTES
Autor-----------: Alexandre Villar
Data da Criacao-: 27/11/2015
===============================================================================================================================
Descrição-------: Função para verificar se o pedido está configurado com uma TES que gera Financeiro
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: _lRet - Valor lógico que determina se o processo de liberação deve continuar
===============================================================================================================================
*/

Static Function ITVERTES( _cFilPed , _cNumPed )

Local _lRet		:= .F.
Local _cQuery	:= ''
Local _cAlias	:= GetNextAlias()

_cQuery := " SELECT COUNT( 1 ) AS GERFIN "
_cQuery += " FROM  "+ RetSqlName('SC6') +" SC6, "+ RetSqlName('SF4') +" SF4 "
_cQuery += " WHERE "+ RetSqlDel('SC6,SF4')
_cQuery += " AND SF4.F4_FILIAL  = SC6.C6_FILIAL "
_cQuery += " AND SF4.F4_CODIGO  = SC6.C6_TES "
_cQuery += " AND SC6.C6_FILIAL  = '"+ _cFilPed +"' "
_cQuery += " AND SC6.C6_NUM     = '"+ _cNumPed +"' "
_cQuery += " AND SF4.F4_DUPLIC  = 'S' "

If Select(_cAlias) > 0
	(_cAlias)->( DBCloseArea() )
EndIf

DBUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQuery ) , _cAlias , .T., .F. )

DBSelectArea(_cAlias)
(_cAlias)->( DBGoTop() )
If (_cAlias)->( !Eof() )
	_lRet := ( (_cAlias)->GERFIN > 0 )
EndIf

(_cAlias)->( DBCloseArea() )

Return( _lRet )
