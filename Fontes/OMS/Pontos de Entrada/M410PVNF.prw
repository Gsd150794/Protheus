/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |11/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25
Alex Wallauer |01/02/2021| Chamado 34262. Remoção de bugs apontados pelo Totvs CodeAnalysis.
Lucas Borges  |17/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: M410PVNF
Autor-----------: Tiago Correa Castro
Data da Criacao-: 17/01/2012
Descrição-------: P.E. para validar o Pedido de Vendas na chamada de Prep. Doc. de Saída na tela de Pedidos de Vendas.
Parametros------: Nenhum
Retorno---------: _lRet	:= define se o faturamento pode prosseguir
===============================================================================================================================
*/
User Function M410PVNF

Local _lRet		:= .T.
Local _lVldPes	:= SuperGetMV('IT_VALPESF',.F.,.F.)
Local _cFilEst3	:= SuperGetMV('IT_EST3FIL',.F.,'')

// Funcao responsavel por validar se a DataBase e igual a data atual(Servidor) para nao permitir o
// faturamento com data retroativa ou posterior a data atual.
If SC5->C5_I_BLPRC == "B" .Or. SC5->C5_I_BLPRC == "R"
	_lRet	:=	.F.

	If SC5->C5_I_BLPRC == "B"
		xMagHelpFis("PROBLEMA",;
					"Pedido de Venda com Bloqueio de Preço Solicite a Liberação do Mesmo Antes de Fatura-lo") 
	Else
		xMagHelpFis("PROBLEMA",;
					"Pedido de Venda com Rejeição de Preço Solicite a Liberação do Mesmo Antes de Fatura-lo") 
	EndIf
EndIf

If dDataBase <> Date()
	_lRet	:=	.F.
	xMagHelpFis("PROBLEMA",;
				"Para o Faturamento a Data Base do sistema tem que ser igual a Data Atual do servidor. Não e permitido faturamento anterior ou posterior a data atual",;
				"Mudar a data base do sistema") 	    	
EndIf  

// Validação do estoque para verificar se o pedido pode ser faturado
If _lRet .And. SC5->C5_FILIAL $ _cFilEst3
	LjMsgRun( "Verificando estoque dos itens do pedido selecionado..." , "Aguarde!" , {|| _lRet := U_ITVLDEST( 1 , SC5->C5_FILIAL , SC5->C5_NUM ) } )
	If !_lRet
		ShowHelpDlg( 'Atenção!' ,	{	'Não existe saldo em estoque para faturar '	,;
										'o pedido atual!'							} , 2 ,;
									{	'Verifique os saldos dos itens do pedido '	,;
										'pois devem constar "em estoque" para o '	,;
										'faturamento. Para a liberação do pedido '	,;
										'utilize a rotina de liberação!'			} , 4 )
	EndIf
EndIf

If _lRet
	LjMsgRun( "Verificando se existem itens de pedidos com o armazém incorreto..." , "Aguarde!" , {|| _lRet := VLDARM() } )
EndIf

If _lRet
	LjMsgRun( "Verificando se existem itens de pedidos com o armazém restrito..." , "Aguarde!" , {|| _lRet := VLDRES() } )
EndIf

// Verifica se o Pedido é do Tipo "Normal" e suas amarrações de Frete x Condição de Pagto.
If _lRet .And. SC5->C5_TIPO == 'N'
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

// Validação da TES x Configuração de peso dos produtos
If _lRet .And. _lVldPes
	LjMsgRun( "Verificando os dados do cadastro de produtos..." , "Aguarde!" , {|| _lRet := IT_VLDPES() } )
EndIf

Return(_lRet)

/*
===============================================================================================================================
Programa--------: VLDARM
Autor-----------: Talita
Data da Criacao-: 27/02/2013
Descrição-------: Valida se os pedidos estão sendo gerados com o armazém correto e se precisa da montagem de carga.
Parametros------: Nenhum
Retorno---------: _lRet	:= define se o faturamento pode prosseguir
===============================================================================================================================
*/
Static Function VLDARM()

Local _lRet		:= .T.
Local _cPedido	:= SC5->C5_NUM
Local _cLocal	:= AllTrim( GetMv("IT_ARMCARG") )
Local _nPed		:= 0
Local _nCont	:= 0
Local _cQuery	:= ""
Local _cAlias	:= GetNextAlias()
Local _nI		:= 0
Local _aParam	:= {}
Local _cTemp	:= ""

For _nI := 1 To Len( _cLocal )
	If ( SubStr( _cLocal , _nI , 1 ) == "/" )
		aAdd( _aParam , _cTemp )
		_cTemp := ""
	Else
		_cTemp += SubStr( _cLocal , _nI , 1 )
		If ( _nI == Len( _cLocal ) )
			aAdd( _aParam , _cTemp )
			_cTemp := ""
		EndIf
	EndIf
Next _nI

_cQuery := " SELECT "
_cQuery += "     DAI_COD   ,"
_cQuery += "     DAI_PEDIDO "
_cQuery += " FROM  "+ RetSqlName("DAI") +" DAI "
_cQuery += " WHERE "+ RetSqlCond("DAI")
_cQuery += " AND DAI_PEDIDO = '"+ AllTrim( _cPedido ) +"' " 

_cQuery := ChangeQuery(_cQuery)
MPSysOpenQuery(_cQuery,_cAlias)

(_cAlias)->( DBGoTop() )
While (_cAlias)->( !Eof() )
	If (_cAlias)->DAI_PEDIDO <> ' '
		_nPed++
	EndIf
	(_cAlias)->( DBSkip() )
EndDo
	
DBSelectArea("SC6")
SC6->( DBSetOrder(1) )
If SC6->( DBSeek( xFilial("SC6") + _cPedido ) )
	While SC6->( !Eof() ) .And. SC6->C6_NUM = _cPedido
	   	For _nI := 1 To Len( _aParam )
		   	_cTes := GetAdvFVal( "SF4" , "F4_ESTOQUE" , xFilial("SF4") + SC6->C6_TES , 1 , "" )
		   	
			If _aParam[_nI] == SC6->C6_LOCAL .And. _nPed == 0 .And. _cTes == "S"
	            _nCont++
		    EndIf
	    Next _nI
		SC6->( DBSkip() )
	EndDo

	If _nCont > 0
		ShowHelpDlg( 'Atenção!' ,	{	'Não é possível faturar itens que estão '	,;
										'configurados no armazém '+ _cLocal +'!'	} , 2 ,;
									{	'Neste armazém só podem ser faturados os '	,;
										'pedidos que possuírem montagem de carga '	,;
										'realizada. Verifique se o pedido está '	,;
										'configurado no armazém correto.'			} , 4 )
		_lRet = .F.
	Else
		_lRet = .T.
	EndIf
EndIf
	
(_cAlias)->( DBCloseArea() )

Return( _lRet )

/*
===============================================================================================================================
Programa--------: VLDRES
Autor-----------: Josué Danich Prestes
Data da Criacao-: 16/10/2015
Descrição-------: Valida se o pedido usam armazéns restritos quanto a usr x filial x armazém
Parametros------: Nenhum
Retorno---------: _lRet	:= define se o faturamento pode prosseguir
===============================================================================================================================
*/
Static Function VLDRES

Local _lRet 	:= .T.
Local _aRet 	:= {}
Local _cmens	:= ""
Local _cCodUsr	:=AllTrim(RetCodUsr())

DBSelectArea("SC6")
SC6->( DBSetOrder(1) )
	
If DBSeek(xFilial("SC6")+SC5->C5_NUM)
	While AllTrim(SC5->C5_NUM) == AllTrim(SC6->C6_NUM)
		//Valida armazémxprodutoxFilialxusuário
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
		
	//Mostra lista de armazéns com problema
	If !(_lRet)
		MessageBox( 'Usuário sem acesso ao(s) armazém(éns) abaixo nessa filial: ' + CRLF + _cmens + CRLF + CRLF+;
					'Caso necessário solicite a manutenção à um usuário com acesso ou, se necessário, solicite o acesso à área de TI/ERP.' , 'Atenção!' , 48 )
	EndIf
EndIf

Return( _lRet )

/*
===============================================================================================================================
Programa--------: ITVERTES
Autor-----------: Alexandre Villar
Data da Criacao-: 27/11/2015
Descrição-------: Função para verificar se o pedido está configurado com uma TES que gera Financeiro
Parametros------: Nenhum
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

_cQuery := ChangeQuery(_cQuery)
MPSysOpenQuery(_cQuery,_cAlias)

(_cAlias)->( DBGoTop() )
If (_cAlias)->( !Eof() )
	_lRet := ( (_cAlias)->GERFIN > 0 )
EndIf

(_cAlias)->( DBCloseArea() )

Return( _lRet )

/*
===============================================================================================================================
Programa--------: IT_VLDPES
Autor-----------: Alexandre Villar
Data da Criacao-: 12/02/2016
Descrição-------: Função para verificar se o produto possui os dados de peso cadastrados quando a TES exige
Parametros------: Nenhum
Retorno---------: _lRet - Valor lógico que determina se o processo de liberação deve continuar
===============================================================================================================================
*/
Static Function IT_VLDPES()

Local _lRet	:= .T.

DBSelectArea("SC6")
SC6->( DBSetOrder(1) )
If SC6->( DBSeek( SC5->( C5_FILIAL + C5_NUM ) ) )
	While SC6->( C6_FILIAL + C6_NUM ) == SC5->( C5_FILIAL + C5_NUM )
		DBSelectArea('SF4')
		SF4->( DBSetOrder(1) )
		If SF4->( DBSeek( xFilial('SF4') + SC6->C6_TES ) )
			If SF4->F4_ATUATF == 'S' .Or. SF4->F4_ESTOQUE == 'S'
				DBSelectArea('SB1')
				SB1->( DBSetOrder(1) )
				If SB1->( DBSeek( xFilial('SB1') + SC6->C6_PRODUTO ) )
					If ( SB1->B1_PESO == 0 ) .Or. ( SB1->B1_PESBRU == 0 )
						ShowHelpDlg( 'Atenção!' ,	{	'O produto utilizado nos pedidos não tem '		,;
														' informação de Peso (B1_PESO) nem Peso '		,;
														' Bruto (B1_PESBRU)!'							}, 3 ,;
													{	'Para a TES utilizada o produto deve ter '		,;
														' as informações de Peso cadastradas.'			,;
														' Pedido: '+ SC6->C6_FILIAL +'-'+ SC6->C6_NUM	+;
														' Item: '+ SC6->C6_ITEM							,;
														' Produto: '+ SC6->C6_PRODUTO					}, 4  )
						
						_lRet := .F.
						Exit
					EndIf
				EndIf
			EndIf
		EndIf
		SC6->( DBSkip() )
	EndDo
EndIf

Return( _lRet )
