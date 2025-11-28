/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Josué Prestes |31/07/2018| Chamado 25555. Incluido calculo de supervisor
Lucas Borges  |09/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25.
Julio Paz     |21/01/2021| Chamado 35183. Inclusão de tratamento para comissões do novo Gerente Nacional.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: SACI008
Autor-----------: Fabiano Dias da Silva
Data da Criacao-: 07/03/2011
Descrição-------: Ponto de Entrada executado apos a gravacao de todos os dados da baixa de titulo a receber
				O ponto de entrada SACI008 sera executado apos gravar todos os dados da baixa a receber. Neste momento todos os
				registros já foram atualizados e destravados e a contabilizacao efetuada.
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function SACI008()

Local _aArea		:= FWGetArea()
Local _cAliasSD1	:= GetNextAlias()
Local _cAliasSD2	:= GetNextAlias()
Local _cAliasSA1	:= GetNextAlias()
Local _cAliasSE3	:= GetNextAlias()
Local x				:= 0
Local _nVlrBase		:= 0
Local _nCalcComi	:= 0
Local _nPosic		:= 0
Local _cCodVend		:= ""
Local _cGrpVenda	:= ""
Local _sDtComiBx	:= GetMv( "IT_COMISBA" )
Local _sDtComFch	:= GetMv( "IT_COMFECH" )
Local _dDtRegbx		:= SToD('')

Private _aGeraSE3	:= {}
Private _cFilial	:= SE1->E1_FILIAL
Private _cDoc		:= SE1->E1_NUM
Private _cSerie		:= SE1->E1_PREFIXO
Private _cCliente	:= SE1->E1_CLIENTE
Private _cLoja		:= SE1->E1_LOJA
Private _cTipo		:= SE1->E1_TIPO
Private _cParcela	:= SE1->E1_PARCELA
Private _dDtEmis	:= SE1->E1_EMISSAO

//===============================================================================================================================
// Armazena a porcentagem da baixa com relacao ao valor total do titulo pois um mesmo titulo pode sofrer varias baixas diante
// disso tem que haver um calculo na geracao do debito da comissao para encontrar a porcentagem da da proporcao da
// representatividade do valor na geracao da comissao.
//===============================================================================================================================
Private _nPorcent	:= nValRec / SE1->E1_VALOR

If SE5->E5_CNABOC <> ' '

	RecLock( "SE5" , .F. )
	SE5->E5_HISTOR := E5_BENEF
	SE3->( MSUnLock() )

EndIf

// Verifica se o tipo do titulo eh igual a NCC e o motivo da baixa seja igual a Normal
If _cTipo == 'NCC' .And. Upper( AllTrim( cMotBx ) ) == 'NORMAL' .And. _dDtEmis >= SToD( _sDtComiBx )

	//Nao sera gerada o debito da comissao para uma baixa de uma NCC que nao foi gerada a partir de o lancamento de uma nota de
	// devolucao, ou seja uma NCC manual.
	querys( _cAliasSD1 , 1 , _cDoc , _cSerie , _cCliente , _cLoja , _cFilial , "" , "" )
	
	//Percorre todos os itens da nota fiscal de devolucao para encontrar                
	//os dados da nota fiscal de origem,  para realizar o calculo do debito da comissao.
	DBSelectArea( _cAliasSD1 )
	(_cAliasSD1)->( DBGoTop() )
	While (_cAliasSD1)->( !Eof() )
	
		//Verifica se os dados da nota fiscal de origem informada existe na SD2, para pegar 
		//dados para posterior calculo do debito da comissao na baixa.                      
		querys( _cAliasSD2 , 2 , (_cAliasSD1)->d1_nfori , (_cAliasSD1)->d1_seriori , _cCliente , _cLoja , _cFilial , (_cAliasSD1)->d1_cod , "" )

		//Verifica se existe uma nota de venda de acordo com os dados da nota fiscal de origem		
		DBSelectArea( _cAliasSD2 )
		(_cAliasSD2)->( DBGoTop() )
		If (_cAliasSD2)->( !Eof() )
		
			// Verifica se a geracao da nota de venda eh posterior a data de inicio da geracao da comissao na baixa.
			If (_cAliasSD2)->D2_EMISSAO >= _sDtComiBx
			
				//Verifica se foi gerada comissao para o vendedor na venda.
				If (_cAliasSD2)->D2_COMIS1 > 0 .And. Len( AllTrim( (_cAliasSD2)->F2_VEND1 ) ) > 0
				
					_nVlrBase  := (_cAliasSD1)->d1_quant * (_cAliasSD2)->D2_PRCVEN
					_nCalcComi := ( _nVlrBase * ( (_cAliasSD2)->D2_COMIS1 / 100 ) ) * _nPorcent
					
					//O valor base na geracao da comissao eh o valor da baixa do titulo.
					_nVlrBase  := _nPorcent * _nVlrBase 
					
					//Para que calcule os valores dos varios itens da nota fiscal de venda
					//por vendedor,coordenador e gerente, para posterior inserção na SE3. 
					_nPosic := aScan( _aGeraSE3 , {|k| k[1] == (_cAliasSD2)->F2_VEND1 } )
					
					If _nPosic == 0
					
						aAdd( _aGeraSE3 , {	(_cAliasSD2)->F2_VEND1	,; // Vendedor
											_cDoc					,; // Numero da nota fiscal de devolucao
											_cSerie					,; // Serie da nota fiscal de devolucao
											_cCliente				,; // Cliente que foi feita a venda
											_cLoja					,; // Loja do Cliente		
											_nVlrBase				,; // Valor base para calculo da comissao 
											(_cAliasSD2)->D2_COMIS1	,; // Porcentagem de comissao gerada na venda
											_nCalcComi				}) // Valor da comissao gerado
					
					Else
					
						_aGeraSE3[_nPosic,8] += _nCalcComi	// Acrescenta mais este valor de comissao
						_aGeraSE3[_nPosic,6] += _nVlrBase	// Acrescenta mais este valor base
						
					EndIf
					
				EndIf     
				
				// Verifica se foi gerada comissao para o Supervisor.
				If (_cAliasSD2)->D2_COMIS4 > 0 .And. Len( AllTrim( (_cAliasSD2)->F2_VEND4 ) ) > 0
				
					_nVlrBase  := (_cAliasSD1)->d1_quant * (_cAliasSD2)->D2_PRCVEN
					_nCalcComi := (_nVlrBase * ( (_cAliasSD2)->D2_COMIS4 / 100 ) ) * _nPorcent
					
					_nVlrBase  := _nPorcent * _nVlrBase
					
					// Para que calcule os valores dos varios itens da nota fiscal de venda por vendedor,coordenador e gerente, para inserção na SE3
					_nPosic := aScan( _aGeraSE3 , {|k| k[1] == (_cAliasSD2)->F2_VEND4 } )
					
					If _nPosic == 0
					
						aAdd( _aGeraSE3 , {	(_cAliasSD2)->F2_VEND4	,; // Vendedor
											_cDoc					,; // Numero da nota fiscal de devolucao
											_cSerie					,; // Serie da nota fiscal de devolucao
											_cCliente				,; // Cliente que foi feita a venda
											_cLoja					,; // Loja do Cliente		
											_nVlrBase				,; // Valor base para calculo da comissao 
											(_cAliasSD2)->D2_COMIS4	,; // Porcentagem de comissao gerada na venda
											_nCalcComi				}) // Valor da comissao gerado
					
					Else
					
						_aGeraSE3[_nPosic,8] += _nCalcComi	// Acrescenta mais este valor de comissao
						_aGeraSE3[_nPosic,6] += _nVlrBase	// Acrescenta mais este valor base
					
					EndIf
				
				EndIf
	
				// Verifica se foi gerada comissao para o Coordenador.
				If (_cAliasSD2)->D2_COMIS2 > 0 .And. Len( AllTrim( (_cAliasSD2)->F2_VEND2 ) ) > 0
				
					_nVlrBase  := (_cAliasSD1)->d1_quant * (_cAliasSD2)->D2_PRCVEN
					_nCalcComi := (_nVlrBase * ( (_cAliasSD2)->D2_COMIS2 / 100 ) ) * _nPorcent
					
					_nVlrBase  := _nPorcent * _nVlrBase
					
					// Para que calcule os valores dos varios itens da nota fiscal de venda por vendedor,coordenador e gerente, para inserção na SE3
					_nPosic := aScan( _aGeraSE3 , {|k| k[1] == (_cAliasSD2)->F2_VEND2 } )
					
					If _nPosic == 0
					
						aAdd( _aGeraSE3 , {	(_cAliasSD2)->F2_VEND2	,; // Vendedor
											_cDoc					,; // Numero da nota fiscal de devolucao
											_cSerie					,; // Serie da nota fiscal de devolucao
											_cCliente				,; // Cliente que foi feita a venda
											_cLoja					,; // Loja do Cliente		
											_nVlrBase				,; // Valor base para calculo da comissao 
											(_cAliasSD2)->D2_COMIS2	,; // Porcentagem de comissao gerada na venda
											_nCalcComi				}) // Valor da comissao gerado
					
					Else
					
						_aGeraSE3[_nPosic,8] += _nCalcComi	// Acrescenta mais este valor de comissao
						_aGeraSE3[_nPosic,6] += _nVlrBase	// Acrescenta mais este valor base
					
					EndIf
				
				EndIf
				
				// Verifica se foi gerada comissao para o Gerente
				If (_cAliasSD2)->D2_COMIS3 > 0 .And. Len( AllTrim( (_cAliasSD2)->F2_VEND3 ) ) > 0
				
					_nVlrBase	:= (_cAliasSD1)->d1_quant * (_cAliasSD2)->D2_PRCVEN
					_nCalcComi	:= ( _nVlrBase * ( (_cAliasSD2)->D2_COMIS3 / 100 ) ) *_nPorcent
     				_nVlrBase	:= _nPorcent * _nVlrBase
					
					// Para que calcule os valores dos varios itens da nota fiscal de venda por vendedor,coordenador e gerente, para inserção na SE3
					_nPosic		:= aScan( _aGeraSE3 , { |k| k[1] == (_cAliasSD2)->F2_VEND3 } )
					
					If _nPosic == 0
						
						aAdd( _aGeraSE3 , { (_cAliasSD2)->F2_VEND3	,; // Vendedor
											_cDoc					,; // Numero da nota fiscal de devolucao
											_cSerie					,; // Serie da nota fiscal de devolucao
											_cCliente				,; // Cliente que foi feita a venda
											_cLoja					,; // Loja do Cliente
											_nVlrBase				,; // Valor base para calculo da comissao
											(_cAliasSD2)->D2_COMIS3	,; // Porcentagem de comissao gerada na venda
											_nCalcComi				}) // Valor da comissao gerado
					
					Else
					
						_aGeraSE3[_nPosic,8] += _nCalcComi   //Acrescenta mais este valor de comissao
						_aGeraSE3[_nPosic,6] += _nVlrBase    //Acrescenta mais este valor base
						
					EndIf
					
				EndIf

				// Verifica se foi gerada comissao para o Gerente Nacional  
				If (_cAliasSD2)->D2_COMIS5 > 0 .And. Len( AllTrim( (_cAliasSD2)->F2_VEND5 ) ) > 0
				
					_nVlrBase	:= (_cAliasSD1)->d1_quant * (_cAliasSD2)->D2_PRCVEN
					_nCalcComi	:= ( _nVlrBase * ( (_cAliasSD2)->D2_COMIS5 / 100 ) ) * _nPorcent
     				_nVlrBase	:= _nPorcent * _nVlrBase
					
					// Para que calcule os valores dos varios itens da nota fiscal de venda por vendedor,coordenador e gerente, para inserção na SE3
					_nPosic		:= aScan( _aGeraSE3 , { |k| k[1] == (_cAliasSD2)->F2_VEND5 } )
					
					If _nPosic == 0
						
						aAdd( _aGeraSE3 , { (_cAliasSD2)->F2_VEND5	,; // Vendedor
											_cDoc					,; // Numero da nota fiscal de devolucao
											_cSerie					,; // Serie da nota fiscal de devolucao
											_cCliente				,; // Cliente que foi feita a venda
											_cLoja					,; // Loja do Cliente
											_nVlrBase				,; // Valor base para calculo da comissao
											(_cAliasSD2)->D2_COMIS5	,; // Porcentagem de comissao gerada na venda
											_nCalcComi				}) // Valor da comissao gerado
					
					Else
					   _aGeraSE3[_nPosic,8] += _nCalcComi   //Acrescenta mais este valor de comissao
					   _aGeraSE3[_nPosic,6] += _nVlrBase    //Acrescenta mais este valor base
						
					EndIf
				EndIf
			EndIf
			
		//Caso nao exista uma nota amarrada procura calcular os valores  
		//pelo vendedor amarrado e debita atraves das regras de comissao.
		Else	  																					     												
			//Verifica se nao existe um debito gerado pela rotina de inclusao de 
			//documento de entrada, para que nao seja gerado o debito de comissao
			//duplicado.                                                         
			querys( _cAliasSE3 , 5 , _cDoc , _cSerie , _cCliente , _cLoja , _cFilial , "" , "" )
			
			DBSelectArea( _cAliasSE3 )
			(_cAliasSE3)->( DBGoTop() )
			If (_cAliasSE3)->( Eof() )
				//Pega o vendedor que esta amarrado ao cliente da nota fiscal 							
				//de devolucao para averiguar regras de comissao, comparacao abaixo para que se pegue o 
				//vendedor apenas uma vez por nota fiscal de devolucao        							
				If Len( AllTrim( _cCodVend ) ) == 0
				
					querys(_cAliasSA1,3,"","",_cCliente,_cLoja,"","","") 
					
					DBSelectArea( _cAliasSA1 )
					(_cAliasSA1)->( DBGoTop() )
					If (_cAliasSA1)->( !Eof() )
					
						_cCodVend	:= (_cAliasSA1)->A1_VEND
						_cGrpVenda	:= (_cAliasSA1)->A1_GRPVEN
					
					EndIf
					
					(_cAliasSA1)->( DBCloseArea() )
				
				EndIf

				//Caso exista um vendedor informado no cadastro de cliente.
				If Len(AllTrim(_cCodVend)) > 0
					//Funcao responsavel por realizar os calculos da comissao de acordo com as regras de comissao estabelecidas na talbela ZAE.
					calcComReg(_cCodVend,(_cAliasSD1)->d1_cod,(_cAliasSD1)->d1_quant,_cGrpVenda,_cCliente,_cLoja,(_cAliasSD1)->D1_TOTAL,_cDoc,_cSerie,_nPorcent,nValRec)
				
				EndIf
				
			EndIf
			
			(_cAliasSE3)->( DBCloseArea() )
			
		EndIf
		
		(_cAliasSD2)->( DBCloseArea() )
	
	(_cAliasSD1)->( DBSkip() )
	EndDo
	
	(_cAliasSD1)->( DBCloseArea() )
	
	//Verifica se foi gerada alguma comissao na devolucao para insercao na tabela SE3.
	If Len(_aGeraSE3) > 0    
		// Se já tem o fechamento da comissão gera o débito para o próximo período
		_dDtRegbx := dDataBase
		
		If _dDtRegBx <= LastDay( SToD( SubStr( _sDtComFch , 3 , 4 ) + SubStr( _sDtComFch , 1 , 2 ) + '01' ) )
			
			_dDtRegBx := MonthSum( SToD( SubStr( _sDtComFch , 3 , 4 ) + SubStr( _sDtComFch , 1 , 2 ) + '01' ) , 1 )
			
		EndIf
		// Seleciona a sequencia a ser gerada no debito da comissao, um titulo pode ter varias baixas com numeros de sequencia diferentes
		For x := 1 To Len( _aGeraSE3 )
		
			RecLock( "SE3" , .T. )
			
			SE3->E3_FILIAL 	:= xFilial("SE3")
			SE3->E3_VEND	:= _aGeraSE3[x,1]
			SE3->E3_NUM		:= _aGeraSE3[x,2]
			SE3->E3_SERIE	:= _aGeraSE3[x,3]
			SE3->E3_PARCELA := _cParcela
			SE3->E3_EMISSAO	:= _dDtRegBx
			SE3->E3_DATA	:= _dDtRegBx
			SE3->E3_CODCLI	:= _aGeraSE3[x,4]
			SE3->E3_LOJA	:= _aGeraSE3[x,5]
			SE3->E3_BASE	:= _aGeraSE3[x,6]
			SE3->E3_PORC	:= ( _aGeraSE3[x,8] / _aGeraSE3[x,6] ) * 100
			SE3->E3_COMIS	:= _aGeraSE3[x,8] * -1
			SE3->E3_PREFIXO	:= _aGeraSE3[x,3]
			SE3->E3_TIPO	:= 'NCC'
			SE3->E3_BAIEMI	:= 'B'
			SE3->E3_SEQ		:= SE5->E5_SEQ
			SE3->E3_ORIGEM	:= 'D'
			SE3->E3_I_ORIGE := 'SACI008'
			
		    SE3->( MSUnLock() )
			
		Next x
		
	EndIf
	
EndIf

FWRestArea( _aArea )

Return

/*
===============================================================================================================================
Programa--------: calcComReg
Autor-----------: Fabiano Dias da Silva
Data da Criacao-: 07/03/2011
Descrição-------: Calcula os valores de debito da comissao na baixa quando nao encontrar uma nota de venda amarrada a nota de
----------------: devolucao, com base nas regras de comissao cadastradas na tabela ZAE.
Parametros------:
Retorno---------:
===============================================================================================================================
*/

Static Function calcComReg(_cCodiVend,_cProduto,_nQtdeDevo,_cGrpVenda,_cFornece,_cLjForn,_nVlrCalCo,_cNumeroNF,_cSerieNF,_nPorctBx,_nVlrBase)

Local _cAliasZAE	:= GetNextAlias()
Private _lAchou		:= .F.
//Seleciona registros da regra de comissao para gerar comissao.
querys(_cAliasZAE,4,"","","","","",_cProduto,_cCodiVend)  

//Caso exista regras de comissao para o produto em questão.
DBSelectArea(_cAliasZAE)
(_cAliasZAE)->( DBGoTop() )
While (_cAliasZAE)->( !Eof() )
	// 1 - Avalia se o cliente e loja sao iguais. 
	If AllTrim(_cFornece) == AllTrim( (_cAliasZAE)->ZAE_CLI ) .And. AllTrim(_cLjForn) == AllTrim( (_cAliasZAE)->ZAE_LOJA )
	
		ComisDev((_cAliasZAE)->ZAE_VEND,(_cAliasZAE)->ZAE_COMIS1,(_cAliasZAE)->ZAE_CODSUP,(_cAliasZAE)->ZAE_COMIS2,(_cAliasZAE)->ZAE_CODGER,(_cAliasZAE)->ZAE_COMIS3,_nQtdeDevo,_nVlrCalCo,_cNumeroNF,_cSerieNF,_cFornece,_cLjForn,_nPorctBx,_nVlrBase,(_cAliasZAE)->ZAE_COMIS4,(_cAliasZAE)->ZAE_CODSUI, (_cAliasZAE)->ZAE_COMIS5, (_cAliasZAE)->ZAE_CODGNC)
	
	// 2 - Avalia se o cliente eh igual e a loja esta em branco. 
	ElseIf AllTrim(_cFornece) == AllTrim( (_cAliasZAE)->ZAE_CLI ) .And. Empty( AllTrim( (_cAliasZAE)->ZAE_LOJA ) )
	
		ComisDev((_cAliasZAE)->ZAE_VEND,(_cAliasZAE)->ZAE_COMIS1,(_cAliasZAE)->ZAE_CODSUP,(_cAliasZAE)->ZAE_COMIS2,(_cAliasZAE)->ZAE_CODGER,(_cAliasZAE)->ZAE_COMIS3,_nQtdeDevo,_nVlrCalCo,_cNumeroNF,_cSerieNF,_cFornece,_cLjForn,_nPorctBx,_nVlrBase,(_cAliasZAE)->ZAE_COMIS4,(_cAliasZAE)->ZAE_CODSUI, (_cAliasZAE)->ZAE_COMIS5, (_cAliasZAE)->ZAE_CODGNC)

	// 3 - Avalia se a Rede do cliente eh igual a rede informada na regra.
	ElseIf AllTrim(_cGrpVenda) == AllTrim( (_cAliasZAE)->ZAE_GRPVEN )
	
		ComisDev((_cAliasZAE)->ZAE_VEND,(_cAliasZAE)->ZAE_COMIS1,(_cAliasZAE)->ZAE_CODSUP,(_cAliasZAE)->ZAE_COMIS2,(_cAliasZAE)->ZAE_CODGER,(_cAliasZAE)->ZAE_COMIS3,_nQtdeDevo,_nVlrCalCo,_cNumeroNF,_cSerieNF,_cFornece,_cLjForn,_nPorctBx,_nVlrBase,(_cAliasZAE)->ZAE_COMIS4,(_cAliasZAE)->ZAE_CODSUI, (_cAliasZAE)->ZAE_COMIS5, (_cAliasZAE)->ZAE_CODGNC)
	
	// 4 - Avalia se o Contrato, Cliente e Grupo estao em branco.
	ElseIf Empty( AllTrim( (_cAliasZAE)->ZAE_CLI ) ) .And. Empty( AllTrim( (_cAliasZAE)->ZAE_GRPVEN ) )
	
		ComisDev((_cAliasZAE)->ZAE_VEND,(_cAliasZAE)->ZAE_COMIS1,(_cAliasZAE)->ZAE_CODSUP,(_cAliasZAE)->ZAE_COMIS2,(_cAliasZAE)->ZAE_CODGER,(_cAliasZAE)->ZAE_COMIS3,_nQtdeDevo,_nVlrCalCo,_cNumeroNF,_cSerieNF,_cFornece,_cLjForn,_nPorctBx,_nVlrBase,(_cAliasZAE)->ZAE_COMIS4,(_cAliasZAE)->ZAE_CODSUI, (_cAliasZAE)->ZAE_COMIS5, (_cAliasZAE)->ZAE_CODGNC)
	
	EndIf

	// Se ja encontrei a comissao, saio da laco.
	If _lAchou
		Exit
	EndIf

(_cAliasZAE)->( DBSkip() )
EndDo

(_cAliasZAE)->( DBCloseArea() )

Return

/*
===============================================================================================================================
Programa--------: ComisDev
Autor-----------: Fabiano Dias da Silva
Data da Criacao-: 07/03/2011
Descrição-------: Efetua os calculos da comissao quando nao existir uma nota de venda amarrada ou nao encontrada nos dados de
----------------: origem da nota devolucao, com base nas regras de comissao cadastradas na tabela ZAE.
Parametros------:
Retorno---------:
===============================================================================================================================
*/

Static Function ComisDev(_cVend1,_nComis1,_cVend2,_nComis2,_cVend3,_nComis3,_nQtdeDevo,_nVlrBase,_cNumeroNF,_cSerieNF,_cFornece,_cLjForn,_nPorctBx,_nVlrBaixa,_ncomis4,_cvend4,_ncomis5,_cvend5) 

Local _nCalcComi:= 0       
Local _nPosic   := 0

_lAchou:= .T.

//Verifica se foi gerada comissao para o vendedor.		    
If _nComis1 > 0 .And. Len( AllTrim(_cVend1) ) > 0

	_nCalcComi := (_nVlrBase * (_nComis1 / 100)) * _nPorctBx
	
	// Para que calcule os valores dos varios itens da nota fiscal de venda por vendedor,coordenador, gerente
	// e gerente nacional para inserção na SE3
	_nPosic := aScan( _aGeraSE3 , {|k| k[1] == _cVend1} )
	
	If _nPosic == 0
	
		aAdd( _aGeraSE3 , {	_cVend1		,; // Vendedor
							_cNumeroNF	,; // Numero da nota fiscal de devolucao
							_cSerieNF	,; // Serie da nota fiscal de devolucao
							_cFornece	,; // Cliente que foi feita a venda
							_cLjForn	,; // Loja do Cliente
							_nVlrBaixa	,; // Valor base para calculo da comissao
							_nComis1	,; // Porcentagem de comissao gerada na venda
							_nCalcComi	}) // Valor da comissao gerado
	
	Else
	
		_aGeraSE3[_nPosic,8] += _nCalcComi // Acrescenta mais este valor de comissao
		
	EndIf
	
EndIf

//Verifica se foi gerada comissao para o coordenador       
If _nComis2 > 0 .And. Len( AllTrim(_cVend2) ) > 0

	_nCalcComi := ( _nVlrBase * ( _nComis2 / 100 ) ) * _nPorctBx
	
	// Para que calcule os valores dos varios itens da nota fiscal de venda por vendedor,coordenador, gerente 
	// e gerente nacional para inserção na SE3
	_nPosic := aScan( _aGeraSE3 , {|k| k[1] == _cVend2 } )
	
	If _nPosic == 0
	
		aAdd( _aGeraSE3 , {	_cVend2		,; // Vendedor
							_cNumeroNF	,; // Numero da nota fiscal de devolucao
							_cSerieNF	,; // Serie da nota fiscal de devolucao
							_cFornece	,; // Cliente que foi feita a venda
							_cLjForn	,; // Loja do Cliente
							_nVlrBaixa	,; // Valor base para calculo da comissao
							_nComis2	,; // Porcentagem de comissao gerada na venda
							_nCalcComi	}) // Valor da comissao gerado
	
	Else
	
		_aGeraSE3[_nPosic,8] += _nCalcComi // Acrescenta mais este valor de comissao
	
	EndIf
	
EndIf

//Verifica se foi gerada comissao para o gerente.
If _nComis3 > 0 .And. Len( AllTrim( _cVend3 ) ) > 0

	_nCalcComi := ( _nVlrBase * ( _nComis3 / 100 ) ) * _nPorctBx
	
	// Para que calcule os valores dos varios itens da nota fiscal de venda por vendedor,coordenador, gerente
	// e gerente nacional para inserção na SE3
	_nPosic := aScan( _aGeraSE3 , {|k| k[1] == _cVend3 } )
	
	If _nPosic == 0
	
		aAdd( _aGeraSE3 , {	_cVend3		,; // Vendedor
							_cNumeroNF	,; // Numero da nota fiscal de devolucao
							_cSerieNF	,; // Serie da nota fiscal de devolucao
							_cFornece	,; // Cliente que foi feita a venda
							_cLjForn	,; // Loja do Cliente
							_nVlrBaixa	,; // Valor base para calculo da comissao
							_nComis3	,; // Porcentagem de comissao gerada na venda
							_nCalcComi	}) // Valor da comissao gerado
	
	Else
	
		_aGeraSE3[_nPosic,8] += _nCalcComi // Acrescenta mais este valor de comissao
		
	EndIf
	
EndIf

//Verifica se foi gerada comissao para o supervisor.
If _nComis4 > 0 .And. Len( AllTrim( _cVend4 ) ) > 0

	_nCalcComi := ( _nVlrBase * ( _nComis4 / 100 ) ) * _nPorctBx
	
	// Para que calcule os valores dos varios itens da nota fiscal de venda por vendedor,coordenador, gerente
	// e gerente nacional para inserção na SE3
	_nPosic := aScan( _aGeraSE3 , {|k| k[1] == _cVend4 } )
	
	If _nPosic == 0
	
		aAdd( _aGeraSE3 , {	_cVend4		,; // Vendedor
							_cNumeroNF	,; // Numero da nota fiscal de devolucao
							_cSerieNF	,; // Serie da nota fiscal de devolucao
							_cFornece	,; // Cliente que foi feita a venda
							_cLjForn	,; // Loja do Cliente
							_nVlrBaixa	,; // Valor base para calculo da comissao
							_nComis4	,; // Porcentagem de comissao gerada na venda
							_nCalcComi	}) // Valor da comissao gerado
	
	Else
	
		_aGeraSE3[_nPosic,8] += _nCalcComi // Acrescenta mais este valor de comissao
		
	EndIf
	
EndIf

//Verifica se foi gerada comissao para o gerente nacional.
If _nComis5 > 0 .And. Len( AllTrim( _cVend5 ) ) > 0

	_nCalcComi := ( _nVlrBase * ( _nComis5 / 100 ) ) * _nPorctBx
	
	// Para que calcule os valores dos varios itens da nota fiscal de venda por vendedor,coordenador, gerente
	// e gerente nacional, para inserção na SE3
	_nPosic := aScan( _aGeraSE3 , {|k| k[1] == _cVend5 } )
	
	If _nPosic == 0
	
		aAdd( _aGeraSE3 , {	_cVend5		,; // Vendedor
							_cNumeroNF	,; // Numero da nota fiscal de devolucao
							_cSerieNF	,; // Serie da nota fiscal de devolucao
							_cFornece	,; // Cliente que foi feita a venda
							_cLjForn	,; // Loja do Cliente
							_nVlrBaixa	,; // Valor base para calculo da comissao
							_nComis5	,; // Porcentagem de comissao gerada na venda
							_nCalcComi	}) // Valor da comissao gerado
	
	Else
		_aGeraSE3[_nPosic,8] += _nCalcComi // Acrescenta mais este valor de comissao
	EndIf
EndIf

Return

/*
===============================================================================================================================
Programa----------: querys
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 07/03/2011
Descrição---------: Query's utilizadas para o processo de calculo da comissao na baixa de um titulo do tipo NCC. 
------------------:
Parametros--------:
Retorno-----------:
===============================================================================================================================
*/

Static Function querys(_cAlias,_nOpcao,_cNumeroNF,_cSerieNF,_cFornece,_cLjForn,_cFilial,_cProduto,_cCodVend)

Local _cQuery:= ""

	Do Case
		//Verifica se existe uma nota de devolucao lancada para a NCC corrente.
		Case _nOpcao == 1       
		
			_cQuery := "SELECT"
			_cQuery += " D1_NFORI,D1_SERIORI,D1_QUANT,D1_COD,D1_TOTAL "                                                  
			_cQuery += "FROM "                              
			_cQuery += RetSqlName("SD1") + " D1 "         
			_cQuery += "WHERE"               
			_cQuery += " D_E_L_E_T_ = ' ' "   
			_cQuery += " AND D1_TIPO = 'D'"            
			_cQuery += " AND D1_FILIAL = '"  + _cFilial   + "'"
			_cQuery += " AND D1_DOC = '"     + _cNumeroNF + "'"          
			_cQuery += " AND D1_SERIE = '"   + _cSerieNF  + "'"    
			_cQuery += " AND D1_FORNECE = '" + _cFornece  + "'"
			_cQuery += " AND D1_LOJA = '"    + _cLjForn   + "'"
				
			If Select(_cAlias) > 0 
				DBSelectArea(_cAlias)
		 		(_cAlias)->(DBCloseArea())
		 	EndIf                   
		    
			dbUseArea(.T.,"TOPCONN",TCGenQry(,,AllTrim(Upper(_cQuery))),_cAlias,.F.,.T.) 
		//Verifica se os dados da nota fiscal de origem informada existe na SD2, para pegar 
		//dados para posterior calculo do debito da comissao na baixa.                      
		Case _nOpcao == 2
		
			_cQuery := "SELECT"
			_cQuery += " D2.D2_QUANT,D2.D2_PRCVEN,D2.D2_COMIS1,D2.D2_COMIS2,D2.D2_COMIS3,F2.F2_VEND1,F2.F2_VEND2,F2.F2_VEND3,D2.D2_EMISSAO,D2.D2_COMIS4,F2.F2_VEND4,D2.D2_COMIS5,F2.F2_VEND5 " 
			_cQuery += "FROM "                              
			_cQuery += RetSqlName("SD2") + " D2 " 
			_cQuery += "JOIN " + RetSqlName("SF2") + " F2 ON F2.F2_FILIAL = D2.D2_FILIAL AND F2.F2_DOC = D2.D2_DOC AND F2.F2_SERIE = D2.D2_SERIE "         
			_cQuery += "AND F2.F2_CLIENTE = D2.D2_CLIENTE AND F2.F2_LOJA = D2.D2_LOJA "
			_cQuery += "WHERE"               
			_cQuery += " D2.D_E_L_E_T_ = ' '"               
			_cQuery += " AND F2.D_E_L_E_T_ = ' '" 
			_cQuery += " AND D2.D2_FILIAL = '"  + _cFilial   + "'"
			_cQuery += " AND F2.F2_FILIAL = '"  + _cFilial   + "'"
			_cQuery += " AND D2.D2_DOC = '"     + _cNumeroNF + "'"          
			_cQuery += " AND D2.D2_SERIE = '"   + _cSerieNF  + "'"    
			_cQuery += " AND D2.D2_COD = '"     + _cProduto  + "'"
			_cQuery += " AND D2.D2_CLIENTE = '" + _cFornece  + "'"
			_cQuery += " AND D2.D2_LOJA = '"    + _cLjForn   + "'" 	   
			
			If Select(_cAlias) > 0 
				DBSelectArea(_cAlias)
		 		(_cAlias)->(DBCloseArea())
		 	EndIf                   
		    
			dbUseArea(.T.,"TOPCONN",TCGenQry(,,AllTrim(Upper(_cQuery))),_cAlias,.F.,.T.)   
		//Seleciona o vendedor do cliente da nota fiscal de devolucao.
		Case _nOpcao == 3 	
		
			_cQuery := "SELECT"
			_cQuery += " A1_VEND,A1_GRPVEN "                                                  
			_cQuery += "FROM "                              
			_cQuery += RetSqlName("SA1") + " A1 "         
			_cQuery += "WHERE"               
			_cQuery += " D_E_L_E_T_ = ' ' "               
			_cQuery += " AND A1_COD = '"  + _cFornece + "'"
			_cQuery += " AND A1_LOJA = '" + _cLjForn  + "'"          
			_cQuery += " AND A1_FILIAL = '" + xFilial("SA1")  + "'" 
				
			If Select(_cAlias) > 0 
				DBSelectArea(_cAlias)
		 		(_cAlias)->(DBCloseArea())
		 	EndIf                   
		    
			dbUseArea(.T.,"TOPCONN",TCGenQry(,,AllTrim(Upper(_cQuery))),_cAlias,.F.,.T.) 
			             					
		//Seleciona registros da regra de comissao para gerar comissao
		Case _nOpcao == 4  
		
			_cQuery	:= " SELECT "
			_cQuery	+= "     ZAE_VEND   ,"
			_cQuery	+= "     ZAE_CLI    ,"
			_cQuery	+= "     ZAE_LOJA   ,"
			_cQuery	+= "     ZAE_GRPVEN ,"
			_cQuery	+= "     ZAE_COMIS1 ,"
			_cQuery	+= "     ZAE_COMIS2 ,"
			_cQuery	+= "     ZAE_COMIS3 ,"
			_cQuery	+= "     ZAE_COMIS4 ,"
			_cQuery	+= "     ZAE_COMIS5 ," 
			_cQuery	+= "     ZAE_CODSUI ,"
			_cQuery	+= "     ZAE_CODSUP ,"
			_cQuery	+= "     ZAE_CODGER ,"
			_cQuery	+= "     ZAE_CODGNC ," 
			_cQuery	+= "     ZAE_CLI || ZAE_LOJA || ZAE_GRPVEN AS INDZAE "
			_cQuery	+= " FROM  "+ RETSQLNAME("ZAE") +" ZAE "
			_cQuery	+= " WHERE "
			_cQuery	+= " ZAE_FILIAL     = '"+ xFilial("ZAE") +"' "
			_cQuery	+= " AND ZAE_VEND   = '"+ _cCodVend      +"' "
			_cQuery	+= " AND ZAE_PROD   = '"+ _cProduto      +"' "
			_cQuery	+= " AND D_E_L_E_T_ = ' ' "
			_cQuery	+= " ORDER BY INDZAE DESC "
			
			If Select(_cAlias) > 0 
				(_cAlias)->( DBCloseArea() )
		 	EndIf
		    
			DBUseArea( .T. , "TOPCONN" , TCGenQry( ,, _cQuery ) , _cAlias , .F. , .T. )
			
		//Verifica se ja nao existe lancamento de debito na comissao gerado
		//pela rotina de inclusao de um documento de devolucao.            
		Case _nOpcao == 5 
		
			_cQuery	    := "SELECT"
			_cQuery 	+= " E3_NUM "
			_cQuery 	+= "FROM " + RETSQLNAME("SE3") + " SE3 "
			_cQuery 	+= "WHERE"     
			_cQuery 	+= " D_E_L_E_T_ = ' '"
			_cQuery 	+= " AND E3_FILIAL = '" + _cFilial   + "'"
			_cQuery 	+= " AND E3_NUM  = '"   + _cNumeroNF + "'"
			_cQuery 	+= " AND E3_SERIE  = '" + _cSerieNF  + "'"
			_cQuery 	+= " AND E3_CODCLI = '" + _cFornece  + "'" 			
			_cQuery 	+= " AND E3_LOJA = '"   + _cLjForn   + "'"
			_cQuery 	+= " AND E3_TIPO = 'NCC'"     
			_cQuery 	+= " AND E3_I_ORIGE = 'MT100AGR'" 
			
			If Select(_cAlias) > 0 
				DBSelectArea(_cAlias)
		 		(_cAlias)->(DBCloseArea())
		 	EndIf                   
		    
			dbUseArea(.T.,"TOPCONN",TCGenQry(,,AllTrim(Upper(_cQuery))),_cAlias,.F.,.T.)  
						
		//Seleciona o proxima numero de sequencia a ser gerado no debito da comissao.
		Case _nOpcao == 6 
		
			_cQuery	    := "SELECT"
			_cQuery 	+= " COALESCE(MAX(TO_NUMBER(E3_SEQ)),0) SEQUENCIA "
			_cQuery 	+= "FROM " + RETSQLNAME("SE3") + " SE3 "
			_cQuery 	+= "WHERE"     
			_cQuery 	+= " D_E_L_E_T_ = ' '"
			_cQuery 	+= " AND E3_FILIAL = '" + _cFilial   + "'"
			_cQuery 	+= " AND E3_NUM  = '"   + _cNumeroNF + "'"
			_cQuery 	+= " AND E3_SERIE  = '" + _cSerieNF  + "'"
			_cQuery 	+= " AND E3_CODCLI = '" + _cFornece  + "'" 			
			_cQuery 	+= " AND E3_LOJA = '"   + _cLjForn   + "'"
			_cQuery 	+= " AND E3_TIPO = 'NCC'"        
			_cQuery 	+= " AND E3_I_ORIGE = 'SACI008'"
			
			If Select(_cAlias) > 0 
				DBSelectArea(_cAlias)
		 		(_cAlias)->(DBCloseArea())
		 	EndIf                   
		    
			dbUseArea(.T.,"TOPCONN",TCGenQry(,,AllTrim(Upper(_cQuery))),_cAlias,.F.,.T.)  

    EndCase

Return
