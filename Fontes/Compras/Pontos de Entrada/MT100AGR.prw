/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Josué Prestes |31/07/2018| Chamado 25555. Inclusão de cálculo de supervisor.
Lucas Borges  |03/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25.
Julio Paz     |21/01/2021| Chamado 35183. Inclusão de tratamento para comissões do novo Gerente Nacional.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MT100AGR
Autor-------------: Fabiano Dias
Data da Criacao---: 08/03/2010
Descrição---------: Ponto de entrada após commit do documento de entrada
					Localização: Function A103NFiscal() responsável pelas funcionalidades de inclusão, alteração, exclusão de 
					notas fiscais de entrada. 
					Em que Ponto: O ponto de entrada é chamado após a confirmação da NF, porém fora da transação. Isto foi feito
					pois clientes que utilizavam TTS e tinham interface com o usuario no ponto MATA100 "travavam" os registros 
					utilizados, causando parada para outros usuarios que estavam acessando a base.
					Para verificar em que opção o programa está, deverá ser testado o conteúdo das variáveis INCLUI e ALTERA.** 
					Quando estiver em modo de EXCLUSÃO, ambas as variáveis ficam com conteúdo = .F. **
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MT100AGR
     
Local _aArea		:= FWGetArea()
Local _cTipoNF		:= SF1->F1_TIPO
Local _cNumeroNF	:= SF1->F1_DOC
Local _cSerieNF		:= SF1->F1_SERIE
Local _cFornece		:= SF1->F1_FORNECE
Local _cLjForn		:= SF1->F1_LOJA
Local _cFilial		:= SF1->F1_FILIAL
Local _dDtDigit		:= SF1->F1_DTDIGIT

Local _cNForiSD1	:= ""
Local _cSeoriSD1	:= ""
Local _cItoriSD1	:= ""
Local _cProdtSD1	:= ""
Local _cQtdeSD1		:= "" 
Local _cItemSD1		:= ""

Local _cSomatDC		:= 0

Private _cParcela	:= SE1->E1_PARCELA

//====================================================================================================
// Esta rotina somente sera executada para as notas fiscais de devolucao
//====================================================================================================
If _cTipoNF == 'D'
	
	//====================================================================================================
	// Funcao responsavel por realizar um debito na comissao realizada na baixa do titulo
	//====================================================================================================
	DevolComis( _cNumeroNF , _cSerieNF , _cFornece , _cLjForn , _cFilial , _dDtDigit )
	
	cQuery := " SELECT "
	cQuery += "     SD1.D1_NFORI   , "
	cQuery += "     SD1.D1_SERIORI , "
	cQuery += "     SD1.D1_ITEMORI , "
	cQuery += "     SD1.D1_COD     , "
	cQuery += "     SD1.D1_QUANT   , "
	cQuery += "     SD1.D1_ITEM      "
	cQuery += " FROM  "+ RetSqlName("SD1") +" SD1 "
	cQuery += " WHERE "
	cQuery += "     SD1.D_E_L_E_T_ = ' ' "               
	cQuery += " AND SD1.D1_FILIAL  = '"+ _cFilial   +"' "
	cQuery += " AND SD1.D1_DOC     = '"+ _cNumeroNF +"' "          
	cQuery += " AND SD1.D1_SERIE   = '"+ _cSerieNF  +"' "    
	cQuery += " AND SD1.D1_FORNECE = '"+ _cFornece  +"' "
	cQuery += " AND SD1.D1_LOJA    = '"+ _cLjForn   +"' "
    
	If Select("TMPSD1") > 0
		TMPSD1->( DBCloseArea() )
 	EndIf
    
	DBUseArea( .T. , "TOPCONN" , TCGenQry(,, cQuery ) , "TMPSD1" , .F. , .T. )
	
	DBSelectArea("TMPSD1")
	TMPSD1->( DBGoTop() )
	While TMPSD1->( !Eof() )
	
		_cNForiSD1	:= TMPSD1->D1_NFORI
		_cSeoriSD1	:= TMPSD1->D1_SERIORI
		_cItoriSD1	:= TMPSD1->D1_ITEMORI
		_cProdtSD1	:= TMPSD1->D1_COD
		_cQtdeSD1	:= TMPSD1->D1_QUANT
		_cItemSD1	:= TMPSD1->D1_ITEM
	    
		//====================================================================================================
		// Busca na tabela SD2 referente a nota fiscal de origem o produto da devolucao para gerar um valor
		// proporcional de desconto contratual de acordo com a quantidade vendida e a quantidade da devolucao
		//====================================================================================================
		cQuery := " SELECT "
		cQuery += "     SD2.D2_QUANT   , "
		cQuery += "     SD2.D2_I_VLRDC   "
		cQuery += " FROM "+ RetSqlName("SD2") +" SD2 "
		cQuery += " WHERE "
		cQuery += "     SD2.D_E_L_E_T_ = ' ' "               
		cQuery += " AND SD2.D2_FILIAL  = '"+ _cFilial   +"' "
		cQuery += " AND SD2.D2_DOC     = '"+ _cNForiSD1 +"' "
		cQuery += " AND SD2.D2_SERIE   = '"+ _cSeoriSD1 +"' "
		cQuery += " AND SD2.D2_ITEM    = '"+ _cItoriSD1 +"' "
		cQuery += " AND SD2.D2_CLIENTE = '"+ _cFornece  +"' "
		cQuery += " AND SD2.D2_LOJA    = '"+ _cLjForn   +"' "
		
		If Select("TMPSD2") > 0 
			TMPSD2->( DBCloseArea() )
 		EndIf
		
		DBUseArea( .T. , "TOPCONN" , TCGenQry( ,, cQuery ) , "TMPSD2" , .F. , .T. )
		
		DBSelectArea("TMPSD2")
		TMPSD2->( DBGoTop() )
		
		//====================================================================================================
		// Caso tenha sido gerado um valor de desconto contratual eh efetuado uma proporcao para armazenar
		// o valor de desconto contratual referente a essa devolucao para ser usado no relatorio de comissao
		// da Jeane Para ser deduzido do valor da comissao gerado na venda
		//====================================================================================================
		If TMPSD2->D2_I_VLRDC > 0
		
			cVlrDesc := ( _cQtdeSD1 / TMPSD2->D2_QUANT ) * TMPSD2->D2_I_VLRDC
			
			//====================================================================================================
			// Posiciona na tabela SD1 para armazenar o valor do desconto contratual
			//====================================================================================================
			DBSelectArea("SD1")
			SD1->( DBSetOrder(1) ) 
			SD1->( DBSeek( _cFilial + _cNumeroNF + _cSerieNF + _cFornece + _cLjForn + _cProdtSD1 + _cItemSD1 ) )
			SD1->( RecLock( "SD1" , .F. ) )
			SD1->D1_I_VLRDC := cVlrDesc
			SD1->( MSUnLock() )
			
			_cSomatDC += cVlrDesc
		
		EndIf
		
	TMPSD1->( DBSkip() )
	EndDo

	//Armazena o valor total do desconto referente aos itens da nota fiscal de devolucao     
	If _cSomatDC > 0      
	
		SF1->( RecLock( "SF1" , .F. ) )
		SF1->F1_I_VLRDC := Round( _cSomatDC , 2 )
		SF1->( MSUnLock() )
	
	EndIf

EndIf

FWRestArea( _aArea )

Return

/*
===============================================================================================================================
Programa----------: DevolComis
Autor-------------: Fabiano Dias
Data da Criacao---: 17/02/2011
Descrição---------: Funcao utilizada para gerar o debito na comissao na baixa na tabela SE3 para as notas de devolucao
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function DevolComis( _cNumeroNF , _cSerieNF , _cFornece , _cLjForn , _cFilial , _dDtDigit )

Local _aAreaAux		:= FWGetArea()
Local _nX			:= 0
Local _cAliasSD1	:= GetNextAlias()
Local _cAliasSE1	:= GetNextAlias()
Local _cAliasSD2	:= GetNextAlias()
Local _cAliasSA1	:= GetNextAlias()
Local _nVlrBase		:= 0
Local _nCalcComi	:= 0
Local _nPosic		:= 0
Local _cCodVend		:= ""
Local _cGrpVenda	:= ""
Local _sDtComiBx	:= GetMv("IT_COMISBA")

Private _aGeraSE3	:= {} 
		
//====================================================================================================
// Verifica se esta sendo efetuada uma Inclusao da nota fiscal de devolucao
//====================================================================================================
If INCLUI

	//====================================================================================================
	// Seleciona todos os itens da Nota Fiscal de Devolucao SD1
	//====================================================================================================
	Querys( _cAliasSD1 , 1 , _cNumeroNF , _cSerieNF , _cFornece , _cLjForn , _cFilial , "" , "" )
	
	//====================================================================================================
	// Verifica para cada item da nota fiscal de devolucao se a nota informada como devolucao gerou 
	// financeiro, pois somente sera considerada propria para calculo na geracao da comissao as notas de
	// vendas que geraram financiero
	//====================================================================================================
	DBSelectArea( _cAliasSD1 )
	(_cAliasSD1)->( DBGoTop() )
	While (_cAliasSD1)->( !Eof() )
	
		//====================================================================================================
		// Verifica se os dados da nota fiscal de origem informada existe na SD2, para pegar dados para 
		// posterior calculo do debito da comissao na baixa
		//====================================================================================================
		Querys( _cAliasSD2 , 3 , (_cAliasSD1)->D1_NFORI , (_cAliasSD1)->D1_SERIORI , _cFornece , _cLjForn , _cFilial , (_cAliasSD1)->D1_COD , "" )
		
		DBSelectArea(_cAliasSD2)
		(_cAliasSD2)->( DBGoTop() )
		
		//====================================================================================================
		// Verifica se existe uma nota de venda de acordo com os dados da nota fiscal de origem
		//====================================================================================================
		If (_cAliasSD2)->( !Eof() )
		
			//====================================================================================================
			// Verifica se a nota de venda amarrada nos itens da nota de devolucao gerou financeiro
			//====================================================================================================
			Querys( _cAliasSE1 , 2 , (_cAliasSD1)->D1_NFORI , (_cAliasSD1)->D1_SERIORI , _cFornece , _cLjForn , _cFilial , "" , "" )
			
			DBSelectArea(_cAliasSE1)
			(_cAliasSE1)->( DBGoTop() )
			
			//====================================================================================================
			// Verifica se existe um financeiro gerado para nota indicada na devolucao, nao foi pego atraves da
			// TES de venda pois esta podera ter sofrido alteracao
			//====================================================================================================
			If (_cAliasSE1)->( !Eof() )
			
				//====================================================================================================
				// Se a NFD lançada esta amarrada com uma NF (Emissão anterior IT_COMISBA) gera o debito, pois eh
				// necessário descontar uma comissao que ja foi gerada na emissao
				//====================================================================================================
				If (_cAliasSD2)->D2_EMISSAO < _sDtComiBx
				
					//====================================================================================================
					// Verifica se foi gerada comissao para o vendedor na venda
					//====================================================================================================
					If (_cAliasSD2)->D2_COMIS1 > 0 .And. Len(AllTrim((_cAliasSD2)->F2_VEND1)) > 0
					
						_nVlrBase  := (_cAliasSD1)->D1_QUANT * (_cAliasSD2)->D2_PRCVEN
						_nCalcComi := _nVlrBase * ( (_cAliasSD2)->D2_COMIS1 / 100 )
						
				   		//====================================================================================================
						// Para que calcule os valores dos varios itens da nota fiscal de venda por vendedor,coordenador e
						// gerente para posterior inserção na SE3
						//====================================================================================================
						_nPosic := aScan( _aGeraSE3 , {|k| k[1] == (_cAliasSD2)->F2_VEND1} )
						
						If _nPosic == 0
						     
							aAdd( _aGeraSE3 , {	(_cAliasSD2)->F2_VEND1	,; // Vendedor
												_cNumeroNF				,; // Numero da nota fiscal de devolucao
												_cSerieNF				,; // Serie da nota fiscal de devolucao
												_cFornece				,; // Cliente que foi feita a venda
												_cLjForn				,; // Loja do Cliente
												_nVlrBase				,; // Valor base para calculo da comissao
												(_cAliasSD2)->D2_COMIS1	,; // Porcentagem de comissao gerada na venda
												_nCalcComi				}) // Valor da comissao gerado
							
						Else
							
							_aGeraSE3[_nPosic][08] += _nCalcComi // Acrescenta mais este valor de comissao
							_aGeraSE3[_nPosic][06] += _nVlrBase  // Acrescenta o valor base para posterior calculo
						
						EndIf
					
					EndIf
					
					//====================================================================================================
					// Verifica se foi gerada comissao para o Coordenador
					//====================================================================================================
					If (_cAliasSD2)->D2_COMIS2 > 0 .And. Len( AllTrim( (_cAliasSD2)->F2_VEND2) ) > 0
					
						_nVlrBase	:= (_cAliasSD1)->d1_quant * (_cAliasSD2)->D2_PRCVEN
						_nCalcComi	:= _nVlrBase * ( (_cAliasSD2)->D2_COMIS2 / 100 )
						
				   		//====================================================================================================
						// Para que calcule os valores dos varios itens da nota fiscal de venda por vendedor,coordenador e 
						// gerente, para posterior inserção na SE3
						//====================================================================================================
						_nPosic := aScan( _aGeraSE3 , {|k| k[1] == (_cAliasSD2)->F2_VEND2} )
						
						If _nPosic == 0
						
							aAdd( _aGeraSE3 , {	(_cAliasSD2)->F2_VEND2	,; // Vendedor
												_cNumeroNF				,; // Numero da nota fiscal de devolucao
												_cSerieNF				,; // Serie da nota fiscal de devolucao
												_cFornece				,; // Cliente que foi feita a venda
												_cLjForn				,; // Loja do Cliente
												_nVlrBase				,; // Valor base para calculo da comissao
												(_cAliasSD2)->D2_COMIS2	,; // Porcentagem de comissao gerada na venda
												_nCalcComi				}) // Valor da comissao gerado
							
						Else
						
							_aGeraSE3[_nPosic,8] += _nCalcComi			// Acrescenta mais este valor de comissao
							_aGeraSE3[_nPosic,6] += _nVlrBase			// Acrescenta o valor base para posterior calculo
						
						EndIf
					
					EndIf
					
					//====================================================================================================
					// Verifica se foi gerada comissao para o Gerente
					//====================================================================================================
					If (_cAliasSD2)->D2_COMIS3 > 0 .And. Len( AllTrim( (_cAliasSD2)->F2_VEND3 ) ) > 0
					
						_nVlrBase	:= (_cAliasSD1)->d1_quant * (_cAliasSD2)->D2_PRCVEN
						_nCalcComi	:= _nVlrBase * ( (_cAliasSD2)->D2_COMIS3 / 100 )
						
						//====================================================================================================
						// Para que calcule os valores dos varios itens da nota fiscal de venda por vendedor,coordenador e 
						// gerente, para posterior inserção na SE3
						//====================================================================================================
						_nPosic := aScan( _aGeraSE3 , {|k| k[1] == (_cAliasSD2)->F2_VEND3 } )
						
						If _nPosic == 0
							
							aAdd( _aGeraSE3 , {	(_cAliasSD2)->F2_VEND3	,; // Vendedor
												_cNumeroNF				,; // Numero da nota fiscal de devolucao
												_cSerieNF				,; // Serie da nota fiscal de devolucao
												_cFornece				,; // Cliente que foi feita a venda
												_cLjForn				,; // Loja do Cliente
												_nVlrBase				,; // Valor base para calculo da comissao
												(_cAliasSD2)->D2_COMIS3	,; // Porcentagem de comissao gerada na venda
												_nCalcComi				}) // Valor da comissao gerado
						
						Else
						
							_aGeraSE3[_nPosic,8] += _nCalcComi   //Acrescenta mais este valor de comissao
							_aGeraSE3[_nPosic,6] += _nVlrBase    //Acrescenta o valor base para posterior calculo
						
						EndIf
						
					EndIf
					
					//====================================================================================================
					// Verifica se foi gerada comissao para o Supervisor
					//====================================================================================================
					If (_cAliasSD2)->D2_COMIS4 > 0 .And. Len( AllTrim( (_cAliasSD2)->F2_VEND4 ) ) > 0
					
						_nVlrBase	:= (_cAliasSD1)->d1_quant * (_cAliasSD2)->D2_PRCVEN
						_nCalcComi	:= _nVlrBase * ( (_cAliasSD2)->D2_COMIS4 / 100 )
						
						//====================================================================================================
						// Para que calcule os valores dos varios itens da nota fiscal de venda por vendedor,coordenador e 
						// gerente, para posterior inserção na SE3
						//====================================================================================================
						_nPosic := aScan( _aGeraSE3 , {|k| k[1] == (_cAliasSD2)->F2_VEND4 } )
						
						If _nPosic == 0
							
							aAdd( _aGeraSE3 , {	(_cAliasSD2)->F2_VEND4	,; // Vendedor
												_cNumeroNF				,; // Numero da nota fiscal de devolucao
												_cSerieNF				,; // Serie da nota fiscal de devolucao
												_cFornece				,; // Cliente que foi feita a venda
												_cLjForn				,; // Loja do Cliente
												_nVlrBase				,; // Valor base para calculo da comissao
												(_cAliasSD2)->D2_COMIS4	,; // Porcentagem de comissao gerada na venda
												_nCalcComi				}) // Valor da comissao gerado
						
						Else
						
							_aGeraSE3[_nPosic,8] += _nCalcComi   //Acrescenta mais este valor de comissao
							_aGeraSE3[_nPosic,6] += _nVlrBase    //Acrescenta o valor base para posterior calculo
						
						EndIf
						
					EndIf

                    //====================================================================================================
					// Verifica se foi gerada comissao para o Gerente Nacional
					//====================================================================================================
					If (_cAliasSD2)->D2_COMIS5 > 0 .And. Len( AllTrim( (_cAliasSD2)->F2_VEND5 ) ) > 0
					
						_nVlrBase	:= (_cAliasSD1)->d1_quant * (_cAliasSD2)->D2_PRCVEN
						_nCalcComi	:= _nVlrBase * ( (_cAliasSD2)->D2_COMIS5 / 100 )
						
						//====================================================================================================
						// Para que calcule os valores dos varios itens da nota fiscal de venda por vendedor,coordenador e 
						// gerente, para posterior inserção na SE3
						//====================================================================================================
						_nPosic := aScan( _aGeraSE3 , {|k| k[1] == (_cAliasSD2)->F2_VEND5 } )
						
						If _nPosic == 0
							
							aAdd( _aGeraSE3 , {	(_cAliasSD2)->F2_VEND5	,; // Vendedor
												_cNumeroNF				,; // Numero da nota fiscal de devolucao
												_cSerieNF				,; // Serie da nota fiscal de devolucao
												_cFornece				,; // Cliente que foi feita a venda
												_cLjForn				,; // Loja do Cliente
												_nVlrBase				,; // Valor base para calculo da comissao
												(_cAliasSD2)->D2_COMIS5	,; // Porcentagem de comissao gerada na venda
												_nCalcComi				}) // Valor da comissao gerado
						
						Else
						
							_aGeraSE3[_nPosic,8] += _nCalcComi   //Acrescenta mais este valor de comissao
							_aGeraSE3[_nPosic,6] += _nVlrBase    //Acrescenta o valor base para posterior calculo
						
						EndIf
						
					EndIf
				
				EndIf
				
			EndIf
			
			//====================================================================================================
			// Finaliza a area da consulta na SE1
			//====================================================================================================
			(_cAliasSE1)->( DBCloseArea() )
		
		//====================================================================================================
		// Caso nao exista uma nota amarrada procura calcula os valores pelo vendedor amarrado e debita
		// atraves das regras de comissao
		//====================================================================================================
		Else	 					   						
		
			//====================================================================================================
			// Verifica se a TES utilizada gerou financeiro, pois somente diante de uma TES que gera financeiro
			// eh que sera gerado o debito da comissao na SE3
			//====================================================================================================
			DBSelectArea("SF4")
			SF4->( DBSetOrder(1) )
			If SF4->( DBSeek( xFilial("SF4") + (_cAliasSD1)->D1_TES ) )
			
				If SF4->F4_DUPLIC == 'S'
				
					//====================================================================================================
					// Pega o vendedor amarrado ao cliente da nota fiscal de devolucao para averiguar regras de comissao,
					// comparacao abaixo para que se pegue o vendedor apenas uma vez por nota fiscal de devolucao
					//====================================================================================================
					If Len( AllTrim(_cCodVend) ) == 0
					
						Querys( _cAliasSA1 , 4 , "" , "" , _cFornece , _cLjForn , "" , "" , "" )
						
						DBSelectArea(_cAliasSA1)
						(_cAliasSA1)->( DBGoTop() )
						If (_cAliasSA1)->( !Eof() )
						
							_cCodVend	:= (_cAliasSA1)->A1_VEND
							_cGrpVenda	:= (_cAliasSA1)->A1_GRPVEN
						
						EndIf
						
						(_cAliasSA1)->( DBCloseArea() )
					
					EndIf
						           						
					//====================================================================================================
					// Caso exista um vendedor informado no cadastro de cliente
					//====================================================================================================
					If Len( AllTrim( _cCodVend ) ) > 0
					
						//====================================================================================================
						// Funcao responsavel por realizar os calculos da comissao de acordo com as regras de comissao
						// estabelecidas na talbela ZAE
						//====================================================================================================
						calcComReg( _cCodVend , (_cAliasSD1)->D1_COD , (_cAliasSD1)->D1_QUANT , _cGrpVenda , _cFornece , _cLjForn , (_cAliasSD1)->D1_TOTAL , _cNumeroNF , _cSerieNF )
						
					EndIf
					
				EndIf
				
			EndIf
			
		EndIf    
	
		(_cAliasSD2)->( DBCloseArea() )
	
	(_cAliasSD1)->( DBSkip() )
	EndDo
	
	//====================================================================================================
	// Finaliza o arquivo temporario da consulta dos itens da nota fiscal de devolucao
	//====================================================================================================
	(_cAliasSD1)->( DBCloseArea() )
	
	//====================================================================================================
	// Verifica se foi gerada alguma comissao na devolucao para insercao na tabela SE3
	//====================================================================================================
	If Len(_aGeraSE3) > 0
	    
		DBSelectArea('SE3')
		
		For _nX := 1 To Len(_aGeraSE3)
		
			SE3->( RecLock( "SE3" , .T. ) )
			
			SE3->E3_FILIAL 	:= xFilial("SE3")
			SE3->E3_VEND	:= _aGeraSE3[_nX][01]
			SE3->E3_NUM		:= _aGeraSE3[_nX][02]
			SE3->E3_SERIE	:= _aGeraSE3[_nX][03]
			SE3->E3_PARCELA := _cParcela
			SE3->E3_EMISSAO	:= _dDtDigit
			SE3->E3_CODCLI	:= _aGeraSE3[_nX][04]
			SE3->E3_LOJA	:= _aGeraSE3[_nX][05]
			SE3->E3_BASE	:= _aGeraSE3[_nX][06]
			SE3->E3_PORC	:= ( _aGeraSE3[_nX][08] / _aGeraSE3[_nX][06] ) * 100
			SE3->E3_COMIS	:= _aGeraSE3[_nX][08] * -1
			SE3->E3_PREFIXO	:= _aGeraSE3[_nX][03]
			SE3->E3_TIPO	:= 'NCC'
			SE3->E3_BAIEMI	:= 'B'
			SE3->E3_SEQ		:= StrZero(_nX,2)
			SE3->E3_ORIGEM	:= 'D'
			SE3->E3_I_ORIGE	:= 'MT100AGR'
			
		    SE3->( MSUnLock() )
		
		Next _nX
	
	EndIf
	
//====================================================================================================
// Deleta comissao quando excluir uma nota de devolucao
//====================================================================================================
ElseIf !(INCLUI .And. ALTERA)
	
	DBSelectArea("SE3")    
	SE3->( DBOrderNickName( "IT_COMISS" ) ) //E3_FILIAL+E3_NUM+E3_SERIE+E3_CODCLI+E3_LOJA 
	If ( SE3->( DBSeek( _cFilial + _cNumeroNF + _cSerieNF + _cFornece + _cLjForn ) ) )
	
		While	SE3->(!Eof())					.And.;
				SE3->E3_FILIAL == _cFilial		.And.;
				SE3->E3_NUM    == _cNumeroNF	.And.;
				SE3->E3_SERIE  == _cSerieNF		.And.;
				SE3->E3_CODCLI == _cFornece		.And.;
				SE3->E3_LOJA   == _cLjForn
			
			//====================================================================================================
			// Verifica se a nota a comissao a ser excluida foi oriunda de uma nota de devolucao
			//====================================================================================================
			If AllTrim(SE3->E3_TIPO) == 'NCC' .And. AllTrim(SE3->E3_ORIGEM) == 'D'
			
				RecLock("SE3",.F.)						
				dbDelete()		       		 			       		 
				SE3->(MSUnLock())    
			
			EndIf
		
		SE3->( DBSkip() )
		EndDo
		
	EndIf

EndIf

FWRestArea( _aAreaAux )

Return

/*
===============================================================================================================================
Programa----------: CalcComReg
Autor-------------: Fabiano Dias
Data da Criacao---: 17/02/2011
Descrição---------: Funcao que Calcula os valores de debito da comissao na baixa quando nao encontrar uma nota de venda
------------------: amarrada a nota de devolucao, com base nas regras de comissao cadastradas na tabela ZAE.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function CalcComReg( _cCodiVend , _cProduto , _nQtdeDevo , _cGrpVenda , _cFornece , _cLjForn , _nVlrCalCo , _cNumeroNF , _cSerieNF )

Local _cAliasZAE	:= GetNextAlias()
Private _lAchou		:= .F.

//====================================================================================================
// Seleciona registros da regra de comissao para gerar comissao
//====================================================================================================
Querys( _cAliasZAE , 5 , "" , "" , "" , "" , "" , _cProduto , _cCodiVend )

//====================================================================================================
// Caso existam regras de comissao para o produto em questão
//====================================================================================================
DBSelectArea(_cAliasZAE)
(_cAliasZAE)->( DBGoTop() )
While (_cAliasZAE)->( !Eof() )

	//====================================================================================================
	// 1 - Avalia se o cliente e loja sao iguais
	//====================================================================================================
	If AllTrim(_cFornece) == AllTrim( (_cAliasZAE)->ZAE_CLI ) .And. AllTrim(_cLjForn) == AllTrim( (_cAliasZAE)->ZAE_LOJA )
		
		ComisDev(	(_cAliasZAE)->ZAE_VEND , (_cAliasZAE)->ZAE_COMIS1 , (_cAliasZAE)->ZAE_CODSUP , (_cAliasZAE)->ZAE_COMIS2 , (_cAliasZAE)->ZAE_CODGER , (_cAliasZAE)->ZAE_COMIS3 ,;
					_nQtdeDevo , _nVlrCalCo , _cNumeroNF , _cSerieNF , _cFornece , _cLjForn,(_cAliasZAE)->ZAE_COMIS4,(_cAliasZAE)->ZAE_CODSUI, (_cAliasZAE)->ZAE_COMIS5 ,(_cAliasZAE)->ZAE_CODGNC )
		
	//====================================================================================================
	// 2 - Avalia se o cliente eh igual e a loja esta em branco.
	//====================================================================================================
	ElseIf AllTrim(_cFornece) == AllTrim( (_cAliasZAE)->ZAE_CLI ) .And. Empty( (_cAliasZAE)->ZAE_LOJA )
	
		ComisDev(	(_cAliasZAE)->ZAE_VEND , (_cAliasZAE)->ZAE_COMIS1 , (_cAliasZAE)->ZAE_CODSUP , (_cAliasZAE)->ZAE_COMIS2 , (_cAliasZAE)->ZAE_CODGER , (_cAliasZAE)->ZAE_COMIS3 ,;
					_nQtdeDevo , _nVlrCalCo , _cNumeroNF , _cSerieNF , _cFornece , _cLjForn,(_cAliasZAE)->ZAE_COMIS4,(_cAliasZAE)->ZAE_CODSUI, (_cAliasZAE)->ZAE_COMIS5 ,(_cAliasZAE)->ZAE_CODGNC )
		
	//====================================================================================================
	// 3 - Avalia se a Rede do cliente eh igual a rede informada na regra
	//====================================================================================================
	ElseIf AllTrim(_cGrpVenda) == AllTrim( (_cAliasZAE)->ZAE_GRPVEN )
	
		ComisDev(	(_cAliasZAE)->ZAE_VEND , (_cAliasZAE)->ZAE_COMIS1 , (_cAliasZAE)->ZAE_CODSUP , (_cAliasZAE)->ZAE_COMIS2 , (_cAliasZAE)->ZAE_CODGER , (_cAliasZAE)->ZAE_COMIS3 ,;
					_nQtdeDevo , _nVlrCalCo , _cNumeroNF , _cSerieNF , _cFornece , _cLjForn,(_cAliasZAE)->ZAE_COMIS4,(_cAliasZAE)->ZAE_CODSUI, (_cAliasZAE)->ZAE_COMIS5 ,(_cAliasZAE)->ZAE_CODGNC )
	
	//====================================================================================================
	// 4 - Avalia se o Contrato, Cliente e Grupo estao em branco
	//====================================================================================================
	ElseIf Empty( (_cAliasZAE)->ZAE_CLI ) .And. Empty( (_cAliasZAE)->ZAE_GRPVEN )
	
		ComisDev(	(_cAliasZAE)->ZAE_VEND , (_cAliasZAE)->ZAE_COMIS1 , (_cAliasZAE)->ZAE_CODSUP , (_cAliasZAE)->ZAE_COMIS2 , (_cAliasZAE)->ZAE_CODGER , (_cAliasZAE)->ZAE_COMIS3 ,;
					_nQtdeDevo , _nVlrCalCo , _cNumeroNF , _cSerieNF , _cFornece , _cLjForn,(_cAliasZAE)->ZAE_COMIS4,(_cAliasZAE)->ZAE_CODSUI, (_cAliasZAE)->ZAE_COMIS5 ,(_cAliasZAE)->ZAE_CODGNC )
	
	EndIf
	
	//====================================================================================================
	// Se encontrar a comissao sai do laço
	//====================================================================================================
	If _lAchou
		Exit
	EndIf
	
(_cAliasZAE)->( DBSkip() )
EndDo

(_cAliasZAE)->( DBCloseArea() )

Return

/*
===============================================================================================================================
Programa----------: ComisDev
Autor-------------: Fabiano Dias
Data da Criacao---: 17/02/2011
Descrição---------: Efetua os calculos da comissao quando nao existir uma nota de venda amarrada ou nao encontrada nos dados de
------------------: origem da nota devolucao, com base nas regras de comissao cadastradas na tabela ZAE
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ComisDev( _cVend1 , _nComis1 , _cVend2 , _nComis2 , _cVend3 , _nComis3 , _nQtdeDevo , _nVlrBase , _cNumeroNF , _cSerieNF , _cFornece , _cLjForn,_ncomis4,_cvend4, _ncomis5, _cvend5 )

Local _nCalcComi	:= 0
Local _nPosic		:= 0

_lAchou := .T.

//====================================================================================================
// Verifica se foi gerada comissao para o vendedor
//====================================================================================================
If _nComis1 > 0 .And. !Empty( _cVend1 )

	_nCalcComi := _nVlrBase * ( _nComis1 / 100 )
	
	//====================================================================================================
	// Para que calcule os valores dos varios itens da nota fiscal de venda por vendedor,coordenador e 
	// gerente, para posterior inserção na SE3
	//====================================================================================================
	_nPosic := aScan( _aGeraSE3 , {|k| k[1] == _cVend1 } )
	
	If _nPosic == 0
	
		aAdd( _aGeraSE3 , {	_cVend1			,; // Vendedor
							_cNumeroNF		,; // Numero da nota fiscal de devolucao
							_cSerieNF		,; // Serie da nota fiscal de devolucao
							_cFornece		,; // Cliente que foi feita a venda
							_cLjForn		,; // Loja do Cliente		
							_nVlrBase		,; // Valor base para calculo da comissao 
							_nComis1		,; // Porcentagem de comissao gerada na venda
							_nCalcComi		}) // Valor da comissao gerado
	
	Else
	
		_aGeraSE3[_nPosic][8] += _nCalcComi		// Acrescenta mais este valor de comissao
		_aGeraSE3[_nPosic][6] += _nVlrBase		// Acrescenta o valor base para posterior calculo
	
	EndIf

EndIf

//====================================================================================================
// Verifica se foi gerada comissao para o coordenador
//====================================================================================================
If _nComis2 > 0 .And. !Empty( _cVend2 )

	_nCalcComi := _nVlrBase * ( _nComis2 / 100 )
												
	//====================================================================================================
	// Para que calcule os valores dos varios itens da nota fiscal de venda por vendedor,coordenador e
	// gerente, para posterior inserção na SE3
	//====================================================================================================
	_nPosic := aScan( _aGeraSE3 , {|k| k[1] == _cVend2 } )
	
	If _nPosic == 0
	
		aAdd( _aGeraSE3 , {	_cVend2			,; // Vendedor
							_cNumeroNF		,; // Numero da nota fiscal de devolucao
							_cSerieNF		,; // Serie da nota fiscal de devolucao
							_cFornece		,; // Cliente que foi feita a venda
							_cLjForn		,; // Loja do Cliente
							_nVlrBase		,; // Valor base para calculo da comissao
							_nComis2		,; // Porcentagem de comissao gerada na venda
							_nCalcComi		}) // Valor da comissao gerado
		
	Else
	
		_aGeraSE3[_nPosic,8] += _nCalcComi   // Acrescenta mais este valor de comissao
		_aGeraSE3[_nPosic,6] += _nVlrBase    // Acrescenta o valor base para posterior calculo
	
	EndIf
	
EndIf
	
//====================================================================================================
// Verifica se foi gerada comissao para o gerente
//====================================================================================================
If _nComis3 > 0 .And. Len( AllTrim(_cVend3) ) > 0

	_nCalcComi := _nVlrBase * (_nComis3 / 100)
	
	//====================================================================================================
	//³Para que calcule os valores dos varios itens da nota fiscal de venda³
	//³por vendedor,coordenador e gerente, para posterior inserção na SE3.
	//====================================================================================================
	_nPosic := aScan(_aGeraSE3,{|k| k[1] == _cVend3})  
					
	If _nPosic == 0
					     
		aAdd( _aGeraSE3 , {	_cVend3		,; // Vendedor
							_cNumeroNF	,; // Numero da nota fiscal de devolucao
							_cSerieNF	,; // Serie da nota fiscal de devolucao
							_cFornece	,; // Cliente que foi feita a venda
							_cLjForn	,; // Loja do Cliente		
							_nVlrBase	,; // Valor base para calculo da comissao 
							_nComis3	,; // Porcentagem de comissao gerada na venda
							_nCalcComi	}) // Valor da comissao gerado
					                
	Else
	
		_aGeraSE3[_nPosic,8] += _nCalcComi	// Acrescenta mais este valor de comissao
		_aGeraSE3[_nPosic,6] += _nVlrBase	// Acrescenta o valor base para posterior calculo
		
	EndIf

EndIf

//====================================================================================================
// Verifica se foi gerada comissao para o supervisor
//====================================================================================================
If _nComis4 > 0 .And. Len( AllTrim(_cVend4) ) > 0

	_nCalcComi := _nVlrBase * (_nComis4 / 100)
	
	//====================================================================================================
	//³Para que calcule os valores dos varios itens da nota fiscal de venda³
	//³por vendedor,coordenador e gerente, para posterior inserção na SE3.
	//====================================================================================================
	_nPosic := aScan(_aGeraSE3,{|k| k[1] == _cVend4})  
					
	If _nPosic == 0
					     
		aAdd( _aGeraSE3 , {	_cVend4		,; // Vendedor
							_cNumeroNF	,; // Numero da nota fiscal de devolucao
							_cSerieNF	,; // Serie da nota fiscal de devolucao
							_cFornece	,; // Cliente que foi feita a venda
							_cLjForn	,; // Loja do Cliente		
							_nVlrBase	,; // Valor base para calculo da comissao 
							_nComis4	,; // Porcentagem de comissao gerada na venda
							_nCalcComi	}) // Valor da comissao gerado
					                
	Else
	
		_aGeraSE3[_nPosic,8] += _nCalcComi	// Acrescenta mais este valor de comissao
		_aGeraSE3[_nPosic,6] += _nVlrBase	// Acrescenta o valor base para posterior calculo
		
	EndIf

EndIf


Return

/*
===============================================================================================================================
Programa----------: Querys
Autor-------------: Fabiano Dias
Data da Criacao---: 17/02/2011
Descrição---------: Rotina que Processa as consultas necessárias ao processamento e monta as áreas de trabalho temporárias
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function Querys( _cAlias , _nOpcao , _cNumeroNF , _cSerieNF , _cFornece , _cLjForn , _cFilial , _cProduto , _cCodVend )

Local cQuery := ""

Do Case

	//====================================================================================================
	// Seleciona todos os itens da Nota Fiscal de Devolucao SD1
	//====================================================================================================
	Case _nOpcao == 1
	
		cQuery := " SELECT "
		cQuery += "     SD1.D1_NFORI   , "
		cQuery += "     SD1.D1_SERIORI , "
		cQuery += "     SD1.D1_ITEMORI , "
		cQuery += "     SD1.D1_COD     , "
		cQuery += "     SD1.D1_QUANT   , "
		cQuery += "     SD1.D1_ITEM    , "
		cQuery += "     SD1.D1_TOTAL   , "
		cQuery += "     SD1.D1_TES       "
		cQuery += " FROM "+ RetSqlName("SD1") +" SD1 "
		cQuery += " WHERE "
		cQuery += "     SD1.D_E_L_E_T_ = ' ' "
		cQuery += " AND SD1.D1_FILIAL  = '"+ _cFilial   +"' "
		cQuery += " AND SD1.D1_DOC     = '"+ _cNumeroNF +"' "
		cQuery += " AND SD1.D1_SERIE   = '"+ _cSerieNF  +"' "
		cQuery += " AND SD1.D1_FORNECE = '"+ _cFornece  +"' "
		cQuery += " AND SD1.D1_LOJA    = '"+ _cLjForn   +"' "
		
		If Select(_cAlias) > 0
			(_cAlias)->( DBCloseArea() )
	 	EndIf
	    
		DBUseArea( .T. , "TOPCONN" , TCGenQry( ,, cQuery ) , _cAlias , .F. , .T. )
		
	//====================================================================================================
	// Verifica se a nota de venda amarrada nos itens da nota de devolucao gerou financeiro
	//====================================================================================================
	Case _nOpcao == 2
			
		cQuery := " SELECT "
		cQuery += "     E1_NUM     , "
		cQuery += "     E1_PREFIXO , "
		cQuery += "     E1_TIPO    , "
		cQuery += "     E1_VALOR     "
		cQuery += " FROM "+ RetSqlName("SE1") +" SE1 "
		cQuery += " WHERE "
		cQuery += "     SE1.D_E_L_E_T_ = ' ' "
		cQuery += " AND SE1.E1_FILIAL  = '"+ _cFilial   +"' "
		cQuery += " AND SE1.E1_NUM     = '"+ _cNumeroNF +"' "
		cQuery += " AND SE1.E1_PREFIXO = '"+ _cSerieNF  +"' "
		cQuery += " AND SE1.E1_CLIENTE = '"+ _cFornece  +"' "
		cQuery += " AND SE1.E1_LOJA    = '"+ _cLjForn   +"' "
		
		If Select(_cAlias) > 0
			(_cAlias)->( DBCloseArea() )
	 	EndIf
	    
		DBUseArea( .T. , "TOPCONN" , TCGenQry( ,, cQuery ) , _cAlias , .F. , .T. )
		
	//====================================================================================================
	// Verifica se os dados da nota fiscal de origem informada existe na SD2, para pegar dados para
	// posterior calculo do debito da comissao na baixa
	//====================================================================================================
	Case _nOpcao == 3
		
		cQuery := " SELECT "
		cQuery += "     SD2.D2_QUANT  , "
		cQuery += "     SD2.D2_PRCVEN , "
		cQuery += "     SD2.D2_COMIS1 , "
		cQuery += "     SD2.D2_COMIS2 , "
		cQuery += "     SD2.D2_COMIS3 , "
		cQuery += "     SD2.D2_COMIS4 , " 
		cQuery += "     SD2.D2_COMIS5 , " 
		cQuery += "     SF2.F2_VEND1  , "
		cQuery += "     SF2.F2_VEND2  , "
		cQuery += "     SF2.F2_VEND3  , "
		cQuery += "     SF2.F2_VEND4  , "
		cQuery += "     SF2.F2_VEND5  , " 
		cQuery += "     SD2.D2_EMISSAO  "
		cQuery += " FROM "+ RetSqlName("SD2") +" SD2 "
		cQuery += " JOIN "+ RetSqlName("SF2") +" SF2 ON "
		cQuery += "     SF2.F2_FILIAL  = SD2.D2_FILIAL "
		cQuery += " AND SF2.F2_DOC     = SD2.D2_DOC "
		cQuery += " AND SF2.F2_SERIE   = SD2.D2_SERIE "
		cQuery += " AND SF2.F2_CLIENTE = SD2.D2_CLIENTE "
		cQuery += " AND SF2.F2_LOJA    = SD2.D2_LOJA "
		cQuery += " WHERE "
		cQuery += "     SD2.D_E_L_E_T_ = ' ' "
		cQuery += " AND SF2.D_E_L_E_T_ = ' ' "
		cQuery += " AND SD2.D2_FILIAL  = '"+ _cFilial   +"' "
		cQuery += " AND SF2.F2_FILIAL  = '"+ _cFilial   +"' "
		cQuery += " AND SD2.D2_DOC     = '"+ _cNumeroNF +"' "
		cQuery += " AND SD2.D2_SERIE   = '"+ _cSerieNF  +"' "
		cQuery += " AND SD2.D2_COD     = '"+ _cProduto  +"' "
		cQuery += " AND SD2.D2_CLIENTE = '"+ _cFornece  +"' "
		cQuery += " AND SD2.D2_LOJA    = '"+ _cLjForn   +"' "
		
		If Select(_cAlias) > 0 
			(_cAlias)->( DBCloseArea() )
	 	EndIf
	    
		DBUseArea( .T. , "TOPCONN" , TCGenQry( ,, cQuery ) , _cAlias , .F. , .T. )
		
	//====================================================================================================
	// Seleciona o vendedor do cliente da nota fiscal de devolucao
	//====================================================================================================
	Case _nOpcao == 4 	
	
		cQuery := " SELECT "
		cQuery += "     SA1.A1_VEND  ,"
		cQuery += "     SA1.A1_GRPVEN "
		cQuery += " FROM "+ RetSqlName("SA1") +" SA1 "
		cQuery += " WHERE "
		cQuery += "     SA1.D_E_L_E_T_ = ' ' "
		cQuery += " AND SA1.A1_COD     = '"+ _cFornece +"' "
		cQuery += " AND SA1.A1_LOJA    = '"+ _cLjForn  +"' "
		
		If Select(_cAlias) > 0 
			(_cAlias)->( DBCloseArea() )
	 	EndIf
	    
		DBUseArea( .T. , "TOPCONN" , TCGenQry( ,, cQuery ) , _cAlias , .F. , .T. )
		
	//====================================================================================================
	// Seleciona registros da regra de comissao para gerar comissao
	//====================================================================================================
	Case _nOpcao == 5
	
		cQuery	:= " SELECT "
		cQuery 	+= "     ZAE.ZAE_VEND   ,"
		cQuery 	+= "     ZAE.ZAE_CLI    ,"
		cQuery 	+= "     ZAE.ZAE_LOJA   ,"
		cQuery 	+= "     ZAE.ZAE_GRPVEN ,"
		cQuery 	+= "     ZAE.ZAE_COMIS1 ,"
		cQuery 	+= "     ZAE.ZAE_COMIS2 ,"
		cQuery 	+= "     ZAE.ZAE_COMIS3 ,"
		cQuery 	+= "     ZAE.ZAE_COMIS4 ,"
		cQuery 	+= "     ZAE.ZAE_COMIS5 ," 
		cQuery 	+= "     ZAE.ZAE_CODSUP ,"
		cQuery 	+= "     ZAE.ZAE_CODSUI ,"
		cQuery 	+= "     ZAE.ZAE_CODGER ,"
		cQuery 	+= "     ZAE.ZAE_CODGNC ," 
		cQuery 	+= "     ZAE.ZAE_CLI || ZAE.ZAE_LOJA || ZAE.ZAE_GRPVEN AS INDZAE "
		cQuery 	+= " FROM "+ RETSQLNAME("ZAE") + " ZAE "
		cQuery 	+= " WHERE "
		cQuery 	+= "     ZAE.ZAE_FILIAL  = '"+ xFilial("ZAE") +"' "
		cQuery 	+= " AND ZAE.ZAE_VEND    = '"+ _cCodVend      +"' "
		cQuery 	+= " AND ZAE.ZAE_PROD    = '"+ _cProduto      +"' "
		cQuery 	+= " AND ZAE.D_E_L_E_T_  = ' ' "
		cQuery 	+= " ORDER BY INDZAE DESC "
		
		If Select(_cAlias) > 0
			(_cAlias)->( DBCloseArea() )
	 	EndIf
	    
		DBUseArea( .T. , "TOPCONN" , TCGenQry( ,, cQuery ) , _cAlias , .F. , .T. )

EndCase

Return
