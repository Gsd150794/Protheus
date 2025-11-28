/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Jerry         |11/02/2020| Chamado 31881. Alterado Avaliação de Crédito tratando PV com produto Queijo e Cond. de Pagto A Vista
Lucas Borges  |19/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MTA450I
Autor-------------: Josué Danich Prestes
Data da Criacao---: 16/02/2016
Descrição---------: PE para gravar lib completa na tela de liberação de crédito (MATA450) - Chamado 14099
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MTA450I

Local _ntotal := 0
Local _aarea 	:= FWGetArea()     
Local _ntolporc := SuperGetMV("IT_TOLPC",.F.,10) //Percentual Tolerância para Produto PA do Tipo Queijo.

SC5->( DBSetOrder(1))
SC5->( DBSeek(SC9->C9_FILIAL+SC9->C9_PEDIDO) )

If SC5->C5_I_LIBC == 1 //Se teve liberação completa inicial

	RecLock("SC5",.F.)

	//Marca C5_I_LIBC com liberação completa para que ao PE na avaliação de crédito sempre aprove esse pedido
	SC5->C5_I_LIBC := 2

	//Grava aprovador, data e hora da liberação completa
	SC5->C5_I_LIBCA 	:= cUserName
	SC5->C5_I_LIBCD	 	:= Date()
	SC5->C5_I_LIBCT 	:= Time()
	SC5->C5_I_LIBL	:=  Date() + 7

	//Grava valor do pedido no momento da liberação
	SC6->( DBSetOrder(1))
	SC6->( DBSeek(SC5->C5_FILIAL+SC5->C5_NUM) )

	While SC6->C6_FILIAL == SC5->C5_FILIAL .And. SC6->C6_NUM == SC5->C5_NUM

		If (Posicione("SB1",1,xFilial("SB1")+AllTrim(SC6->C6_PRODUTO),"B1_I_QQUEI") == 'S')
			_ntotal +=  (SC6->C6_VALOR + ( (SC6->C6_VALOR*_ntolporc)/100) )
		Else
			_ntotal +=  SC6->C6_VALOR
		EndIf

 		SC6->( DBSkip() )
	
	EndDo

	SC5->C5_I_LIBCV	:= _ntotal 

	SC5->( MSUnLock() )

	FWRestArea(_aarea)
	
EndIf
						
Return
