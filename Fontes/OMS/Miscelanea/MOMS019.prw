/*
===============================================================================================================================
                                    ATUALIZACOES SOFRIDAS DESDE A CONSTRUÇAO INICIAL
===============================================================================================================================
       Autor      |    Data    |                                             Motivo                                           |
------------------:------------:----------------------------------------------------------------------------------------------:
Alexandre Villar  | 22/01/2016 | Chamado 13062. Ajuste nas claúsulas ORDER BY.                                                 |
------------------:------------:----------------------------------------------------------------------------------------------:
Alexandre Villar  | 23/03/2016 | Chamado 14774. Ajuste para padronizar a utilização de rotinas de consultas customizadas.      |
-------------------------------------------------------------------------------------------------------------------------------
Igor Melgaço      | 12/03/2024 | Chamado 45575. Ajuste para conversão de texto do Assunto do email em padrao UTF8.
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges      | 01/08/2025 | Chamado 51453. Substituir função U_ITEncode por FWHttpEncode
===============================================================================================================================
*/

#Include "TOTVS.ch"  

/*
===============================================================================================================================
Programa--------: MOMS019
Autor-----------: Fabiano Dias da Silva
Data da Criacao-: 13/09/2011
===============================================================================================================================
Descrição-------: Funcao desenvolvida para realizar o envio do Resumo Faturamento liquido anual desconsiderando as devolucoes,
----------------: este resumo sera demonstrado por unidade geral e outro por unidade x sub-grupo de produtos, este resumo em
----------------: HTML somente sera enviado para pessoas que possuam cadastro de envio de e-mail na tabela(ZZL)
===============================================================================================================================
Uso-------------: Italac
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
Setor-----------: TI
===============================================================================================================================
*/

User Function MOMS019(_cDtInic,_cDtFinal)

Local aTables    := { "SF2" , "SD2" , "SD1" , "SB1" , "ZB9" , "ZZL" }
Local _cAlias    := ""
Local _cEmails   := ""

Local _lCriaAmb  := .F.

//====================================================================================================
// Verifica a necessidade de abrir um ambiente
//====================================================================================================
If Select("SX3") <= 0
	_lCriaAmb := .T.
EndIf

If _lCriaAmb

	RPCSetType(3) // Nao consome licensas
	
	RpcSetEnv( "01" , "01" ,,,, "SCHEDULE_EMAIL_RESUMO" , aTables ) // Seta o ambiente com a empresa 01 filial 01
	
	Sleep( 5000 ) // aguarda 5 segundos para que as jobs IPC subam.
	
    u_itconout( 'Gerando enviou do arquivo HTML de Resumo de vendas desconsiderando devolucoes na data: '+ DToC( Date() ) +' - '+ Time() )

EndIf

//====================================================================================================
// Verifica inicialmente para quais usuarios o resumo sera enviado
//====================================================================================================
_cAlias := GetNextAlias()
querys( 4 , _cAlias , _cDtInic , _cDtFinal )

DBSelectArea( _cAlias )
(_cAlias)->( DBGoTop() )

//====================================================================================================
// Deve existir no minimo um e-mail para a rotina processar a montagem e envio do arquivo
//====================================================================================================
If (_cAlias)->( !Eof() )

	While (_cAlias)->( !Eof() )
	 
		_cEmails += ";"+ AllTrim( (_cAlias)->ZZL_EMAIL )
	 
	(_cAlias)->(DBSkip() )
	EndDo
	
	_cEmails := SubStr( _cEmails , 2 , Len( _cEmails ) )
	
	//====================================================================================================
	// Funcao responsavel por montar o HTML para envio
	//====================================================================================================
	mntHTMLRes( _cEmails , _cDtInic , _cDtFinal )

EndIf

(_cAlias)->( DBCloseArea() )

If _lCriaAmb
    
	RpcClearEnv() //Limpa o ambiente, liberando a licença e fechando as conexões
	
	u_itconout( 'Término de execução normal do envio do HTML de Resumo de vendas na data:'+ DToC( Date() ) +' - '+ Time() )

EndIf

Return

/*
===============================================================================================================================
Programa--------: mntHTMLRes
Autor-----------: Fabiano Dias da Silva
Data da Criacao-: 13/09/2011
===============================================================================================================================
Descrição-------: Funcao desenvolvida para realizar a geracao do arquivo HTML para posterior envio aos usuarios
===============================================================================================================================
Uso-------------: Italac
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
Setor-----------: TI
===============================================================================================================================
*/

Static Function mntHTMLRes( _cEmailDes , _cDtInic , _cDtFinal )

Local _horario    := StrTran( Time() , ":" , "'" ) // Nao se pode gerar um arquivo com o nome que contenha o caracter ":"
Local _cArqAnexo  := "\spool\resumo_vendas" + _horario +".HTM" // Nome do arquivo anexo a ser enviado ao usuario

Local _aDadosUni  := {}

Local _cArqHtml   := ''
Local _nHdl       := 0
Local _cTextHTML  := ""              
Local _lRet       := .T.

Local _x		  := 1

Local _cAliasGer  := ""
Local _cAliasUni  := ""

Local _cDescSub   := ""
Local _nQtde1     := 0
Local _nQtde2     := 0
Local _cUm1       := ""
Local _cUm2       := ""
Local _nVlrUnit   := 0
Local _nPorcent   := 0

Local _cDescFil   := ""
Local _nVlLiqFil  := 0
Local _cFilial    := ""
Local _cMsgEmail  := ""

Local _sDtInic 	  := _cDtInic
Local _dDtFinal   := _cDtFinal

Local _cGeracao   := DToC( Date() )

//====================================================================================================
// Funcao para trabalhar os dados da secao valor liquido por unidade para montagem do aquivo
//====================================================================================================
_aDadosUni := DadosUni( _cDtInic , _cDtFinal )

//====================================================================================================
// Define o cabecalho do HTML
//====================================================================================================
_cTextHTML += '<!DOCTYPE HTML Public "-//W3C//DTD HTML 4.0 Transitional//EN">'
_cTextHTML += '<HTML><HEAD><TITLE>VENDAS GRUPO ITALAC</TITLE>'
_cTextHTML += '<META content="text/html; charset=windows-1252" http-equiv=Content-Type>'
_cTextHTML += '<META name=GENERATOR content="MSHTML 8.00.6001.19120"></HEAD>' 

//====================================================================================================
// Define o corpo do HTML
//====================================================================================================
_cTextHTML += '<BODY>'
_cTextHTML += '<P align=center><FONT color=#388e8e size=5><STRONG>VENDAS GRUPO ITALAC - RELATÓRIO ANUAL<BR></STRONG></FONT></P>'  
_cTextHTML += '<P align=center><FONT color=#388e8e size=5><STRONG>PERÍODO ANUAL DE: ' + DToC(SToD(_sDtInic)) + ' À ' + DToC(SToD(_dDtFinal)) + ' (GERADO EM: ' + _cGeracao + ' AS ' + Transform(Time(),"@R 99:99") + ')<BR></STRONG></FONT></P>' 

//====================================================================================================
// Define estrutura da primeira secao RESUMO POR FILIAL
//====================================================================================================
_cTextHTML += '<P align=center><FONT color=#388e8e size=5><STRONG><U>RESUMO POR UNIDADE</U><BR></STRONG></FONT></P>'
_cTextHTML += '<P align=center>'
_cTextHTML += '<TABLE border=1 cellSpacing=0 borderColor=#000000 cellPadding=0 width="100%">'
_cTextHTML += '<TBODY>'
_cTextHTML += '<TR>'
_cTextHTML += '<TD width="50%"><STRONG>UNIDADE</STRONG></TD>'
_cTextHTML += '<TD width="25%"> <P align=right><STRONG>VALOR LIQUIDO(R$)</STRONG></P></TD>'
_cTextHTML += '<TD width="25%"><P align=right><STRONG>PARTICIPAÇÃO(%)</STRONG></P></TD>
_cTextHTML += '</TR>'

//====================================================================================================
// Verifica se existe no minimo uma linha de dados
//====================================================================================================
If Len(_aDadosUni) > 0

	//====================================================================================================
	// Imprime totalizador
	//====================================================================================================
	_cTextHTML += '<TR>'
	_cTextHTML += '<TD width="50%"><FONT COLOR="#ff0000">TOTAL</FONT></TD>'
	_cTextHTML += '<TD width="25%"><P align=right><FONT COLOR="#ff0000">'+ Transform( _aDadosUni[1,5]	, "@E 999,999,999,999.99"	) +'</FONT></P></TD>'
	_cTextHTML += '<TD width="25%"><P align=right><FONT COLOR="#ff0000">'+ Transform( 100				, "@E 999.99"				) +'</FONT></P></TD>
	_cTextHTML += '</TR>'
	
	//====================================================================================================
	// Insere os dados de todas as filiais encontradas na consulta
	//====================================================================================================
	For _x := 1 to Len( _aDadosUni )
	
		_cTextHTML += '<TR>'
		_cTextHTML += '<TD width="50%">'+ _aDadosUni[_x][1] +' - '+ AllTrim( _aDadosUni[_x][2] ) +'</TD>'
		_cTextHTML += '<TD width="25%"><P align=right>'+ Transform( _aDadosUni[_x][3] , "@E 999,999,999,999.99"	) +'</P></TD>'
		_cTextHTML += '<TD width="25%"><P align=right>'+ Transform( _aDadosUni[_x][4] , "@E 999.99"				) +'</P></TD>'
		_cTextHTML += '</TR>'
	
	Next x

Else

	_lRet := .F.
	u_itconout( 'Nao foram encontrados registros da primeira secao RESUMO FILIAL.' )

EndIf

//====================================================================================================
// Finaliza a tabela da secao RESUMO POR FILIAL
//====================================================================================================
_cTextHTML += '</TBODY>'
_cTextHTML += '</TABLE>'
_cTextHTML += '</P>'

//====================================================================================================
// Define a estrutura da segunda secao RESUMO GERAL POR SUBGRUPO DE PRODUTO
//====================================================================================================
_cTextHTML += '<P align=center>&nbsp;</P>'
_cTextHTML += '<P align=center><FONT color=#388e8e size=5><STRONG><U>RESUMO GERAL POR GRUPO DE PRODUTOS</U><BR></STRONG></P>'
_cTextHTML += '<P align=center>'
_cTextHTML += '<TABLE border=1 cellSpacing=0 borderColor=#000000 cellPadding=0 width="100%">'
_cTextHTML += '<TBODY>'
_cTextHTML += '<TR>'
_cTextHTML += '<TD width="34%"><STRONG>SUB-GRUPO</STRONG></TD>'
_cTextHTML += '<TD width="11%"><P align=right><STRONG>QTDE 1a. U.M.</STRONG></P></TD>'
_cTextHTML += '<TD width="6%"><P align=center><STRONG>1a. U.M.</STRONG></P></TD>'
_cTextHTML += '<TD width="11%"><P align=right><STRONG>QTDE 2a. U.M.</STRONG></P></TD>'
_cTextHTML += '<TD width="6%"><P align=center><STRONG>2a. U.M.</STRONG></P></TD>'
_cTextHTML += '<TD width="12%"><P align=right><STRONG>VALOR UNITÁRIO</STRONG></P></TD>'
_cTextHTML += '<TD width="11%"><P align=right><STRONG>VALOR LIQUIDO</STRONG></P></TD>'
_cTextHTML += '<TD width="9%"><P align=right><STRONG>PORCEN(%)</STRONG></P></TD>'
_cTextHTML += '</TR>'

//====================================================================================================
// Verifica se existe no minimo uma linha de dados
//====================================================================================================
If Len(_aDadosUni) > 0

	//====================================================================================================
	// Consulta do faturamento liquido por unidade x sub-grupo de produtos sem considerar devolucoes
	//====================================================================================================
	_cAliasGer := GetNextAlias()
	
	querys( 2 , _cAliasGer , _cDtInic , _cDtFinal )
	
	_cTextHTML += '<TR>'
	_cTextHTML += '<TD width="34%"><FONT COLOR="#ff0000">TOTAL</FONT></TD>'
	_cTextHTML += '<TD width="11%"><P align=right><FONT COLOR="#ff0000">'+ Transform( 0					, "@E 999,999,999,999.99" )		+'</FONT></P></TD>'
	_cTextHTML += '<TD width="06%"> </TD>'
	_cTextHTML += '<TD width="11%"><P align=right><FONT COLOR="#ff0000">'+ Transform( 0					, "@E 999,999,999,999.99" )		+'</FONT></P></TD>'
	_cTextHTML += '<TD width="06%"> </TD>'
	_cTextHTML += '<TD width="12%"><P align=right><FONT COLOR="#ff0000">'+ Transform( 0					, "@E 999,999,999,999.9999" )	+'</FONT></P></TD>'
	_cTextHTML += '<TD width="11%"><P align=right><FONT COLOR="#ff0000">'+ Transform( _aDadosUni[1,5]	, "@E 999,999,999,999.99" )		+'</FONT></P></TD>'
	_cTextHTML += '<TD width="09%"><P align=right><FONT COLOR="#ff0000">'+ Transform( 100				, "@E 999.99" )					+'</FONT></P></TD>'
	_cTextHTML += '</TR>'
	
	DBSelectArea(_cAliasGer)
	(_cAliasGer)->( DBGoTop() )
	
	//====================================================================================================
	// Insere na tabela todos os sub-grupos de produtos encontrados
	//====================================================================================================
	While (_cAliasGer)->( !Eof() )
	    
		_nPorcent := ( (_cAliasGer)->VLRLIQ / _aDadosUni[1][5] ) * 100
		
		//====================================================================================================
		// Caso nao exista um sub-grupo de tributação
		//====================================================================================================
		If Len( AllTrim( (_cAliasGer)->CODSUB ) ) == 0
		
			_cDescSub := "000 - SEM SUB-GRUPO"
			_nQtde1   := 0
			_nQtde2   := 0
			_cUm1     := " "
			_cUm2     := " "
			_nVlrUnit := 0
			
		Else
		
			_cDescSub	:= AllTrim( (_cAliasGer)->CODSUB ) +' - '+ AllTrim( (_cAliasGer)->DESCSUB )
			_nQtde1		:= (_cAliasGer)->QTD1
			_nQtde2		:= (_cAliasGer)->QTD2
			_cUm1		:= (_cAliasGer)->UM1
			_cUm2		:= (_cAliasGer)->UM2
			
			If (_cAliasGer)->QTD1 > 0
				
				_nVlrUnit := (_cAliasGer)->VLRLIQ / (_cAliasGer)->QTD1
				
			ElseIf (_cAliasGer)->QTD2 > 0
			
				_nVlrUnit := (_cAliasGer)->VLRLIQ / (_cAliasGer)->QTD2
				
			EndIf
			
		EndIf
		
		_cTextHTML += '<TR>'
		_cTextHTML += '<TD width="34%">'+ _cDescSub +'</TD>'
		_cTextHTML += '<TD width="11%"><P align=right >'+ Transform( _nQtde1				,"@E 999,999,999,999.99" )		+'</P></TD>'
		_cTextHTML += '<TD width="60%"><P align=center>'+ _cUm1																+'</P></TD>'
		_cTextHTML += '<TD width="11%"><P align=right >'+ Transform( _nQtde2				,"@E 999,999,999,999.99" )		+'</P></TD>'
		_cTextHTML += '<TD width="06%"><P align=center>'+ _cUm2																+'</P></TD>'
		_cTextHTML += '<TD width="12%"><P align=right >'+ Transform( _nVlrUnit				,"@E 999,999,999,999.9999" )	+'</P></TD>'
		_cTextHTML += '<TD width="11%"><P align=right >'+ Transform( (_cAliasGer)->VLRLIQ	,"@E 999,999,999,999.99" )		+'</P></TD>'
		_cTextHTML += '<TD width="09%"><P align=right >'+ Transform( _nPorcent				,"@E 999.99" )					+'</P></TD>'
		_cTextHTML += '</TR>'
	
	(_cAliasGer)->( DBSkip() )
	EndDo
	
	//====================================================================================================
	// Finaliza a area criada anteriormente
	//====================================================================================================
	(_cAliasGer)->( DBCloseArea() )

EndIf

//====================================================================================================
// Finaliza a tabela da secao RESUMO GERAL POR SUB-GRUPO DE PRODUTOS
//====================================================================================================
_cTextHTML += '</TBODY>'
_cTextHTML += '</TABLE>'
_cTextHTML += '</P>'

//====================================================================================================
// Define a estrutura da terceira secao RESUMO GERAL POR SUBGRUPO DE PRODUTO X UNIDADE
//====================================================================================================

//====================================================================================================
// Consulta do faturamento liquido por unidade x sub-grupo de produtos desconsiderando as devolucoes
//====================================================================================================
_cAliasUni := GetNextAlias()

querys( 3 , _cAliasUni , _cDtInic , _cDtFinal )

DBSelectArea( _cAliasUni )
(_cAliasUni)->( DBGoTop() )
If (_cAliasUni)->( !Eof() )

	_cTextHTML += '<P align=center>&nbsp;</P>'
	
	//====================================================================================================
	// Pega a descricao e valor liquido total da primeira filial conforme dados da secao RESUMO POR FILIAL
	//====================================================================================================
	_nPosFil := aScan( _aDadosUni , {|W| W[1] == (_cAliasUni)->FILIAL } )
	
	If _nPosFil > 0
	    
	    _cDescFil	:= _aDadosUni[_nPosFil][2]	// Descricao da Filial
	    _nVlLiqFil	:= _aDadosUni[_nPosFil][3]	// Valor total liquido da Filial
	    _cFilial	:= (_cAliasUni)->FILIAL		// Seta a variavel de controle da Filial
		
		_cTextHTML += '<P align=center>&nbsp;</P>'
		_cTextHTML += '<P align=center><FONT color=#388e8e size=5><STRONG><U>UNIDADE: ' + AllTrim(_cDescFil) + '</U></STRONG></P>'
		_cTextHTML += '<P align=center>'
		_cTextHTML += '<TABLE border=1 cellSpacing=0 borderColor=#000000 cellPadding=0 width="100%">'
		_cTextHTML += '<TBODY>'
		_cTextHTML += '<TR>'
		_cTextHTML += '<TD width="34%"><STRONG>SUB-GRUPO</STRONG></TD>'
		_cTextHTML += '<TD width="11%"><P align=right><STRONG>QTDE 1a. U.M.</STRONG></P></TD>'
		_cTextHTML += '<TD width="6%"><P align=center><STRONG>1a. U.M.</STRONG></P></TD>'
		_cTextHTML += '<TD width="11%"><P align=right><STRONG>QTDE 2a. U.M.</STRONG></P></TD>'
		_cTextHTML += '<TD width="6%"><P align=center><STRONG>2a. U.M.</STRONG></P></TD>'
		_cTextHTML += '<TD width="12%"><P align=right><STRONG>VALOR UNITÁRIO</STRONG></P></TD>'
		_cTextHTML += '<TD width="11%"><P align=right><STRONG>VALOR LIQUIDO</STRONG></P></TD>'
		_cTextHTML += '<TD width="9%"><P align=right><STRONG>PORCEN(%)</STRONG></P></TD>'
		_cTextHTML += '</TR>'
		
		//====================================================================================================
		// Imprime o totalizador da Filial corrente
		//====================================================================================================
		_cTextHTML += '<TR>'
		_cTextHTML += '<TD width="34%"><FONT COLOR="#ff0000">TOTAL</FONT></TD>'
		_cTextHTML += '<TD width="11%"><P align=right><FONT COLOR="#ff0000">'+ Transform( 0				, "@E 999,999,999,999.99" )		+'</FONT></P></TD>'
		_cTextHTML += '<TD width="06%"> </TD>'
		_cTextHTML += '<TD width="11%"><P align=right><FONT COLOR="#ff0000">'+ Transform( 0				, "@E 999,999,999,999.99" )		+'</FONT></P></TD>'
		_cTextHTML += '<TD width="06%"> </TD>'
		_cTextHTML += '<TD width="12%"><P align=right><FONT COLOR="#ff0000">'+ Transform( 0				, "@E 999,999,999,999.9999" )	+'</FONT></P></TD>'
		_cTextHTML += '<TD width="11%"><P align=right><FONT COLOR="#ff0000">'+ Transform( _nVlLiqFil	, "@E 999,999,999,999.99" )		+'</FONT></P></TD>'
		_cTextHTML += '<TD width="09%"><P align=right><FONT COLOR="#ff0000">'+ Transform( 100			, "@E 999.99" )					+'</FONT></P></TD>'
		_cTextHTML += '</TR>'
		
		//====================================================================================================
		// Insere na tabela todos os sub-grupos de produtos encontrados, gerando cada filial em uma tabela
		//====================================================================================================
		While (_cAliasUni)->( !Eof() )
		
			If _cFilial <> (_cAliasUni)->FILIAL
				
				//====================================================================================================
				// Seta variavel de controle
				//====================================================================================================
				_cFilial := (_cAliasUni)->FILIAL
				
			    //====================================================================================================
				// Finaliza a tabela anterior da secao RESUMO GERAL POR SUB-GRUPO DE PRODUTOS X UNIDADE
				//====================================================================================================
				_cTextHTML += '</TBODY>'
				_cTextHTML += '</TABLE>'
				_cTextHTML += '</P>'
		  		
				//====================================================================================================
				// Pega a descricao e valor liquido total da primeira filial conforme dados da secao RESUMO POR FILIAL
				//====================================================================================================
				_nPosFil := aScan( _aDadosUni , {|W| W[1] == (_cAliasUni)->FILIAL } )
				
				If _nPosFil > 0
				
				   	_cDescFil	:= _aDadosUni[_nPosFil][2] // Descricao da Filial
				   	_nVlLiqFil	:= _aDadosUni[_nPosFil][3] // Valor total liquido da Filial
				   	_cFilial	:= (_cAliasUni)->FILIAL    // Seta a variavel de controle da Filial
				
				Else
				
					_lRet := .F.
					
					u_itconout( 'Filial: '+ (_cAliasUni)->FILIAL +' nao encontrado para pegar a descricao e valor total da Filial' )
					Exit
					
				EndIf
				
				_cTextHTML += '<P align=center>&nbsp;</P>'
				_cTextHTML += '<P align=center><FONT color=#388e8e size=5><STRONG><U>UNIDADE: ' +  AllTrim(_cDescFil) + '</U></STRONG></P>'	
				_cTextHTML += '<P align=center>'
				_cTextHTML += '<TABLE border=1 cellSpacing=0 borderColor=#000000 cellPadding=0 width="100%">'
				_cTextHTML += '<TBODY>'
				_cTextHTML += '<TR>'
				_cTextHTML += '<TD width="34%"><STRONG>SUB-GRUPO</STRONG></TD>'
				_cTextHTML += '<TD width="11%"><P align=right><STRONG>QTDE 1a. U.M.</STRONG></P></TD>'
				_cTextHTML += '<TD width="6%"><P align=center><STRONG>1a. U.M.</STRONG></P></TD>'
				_cTextHTML += '<TD width="11%"><P align=right><STRONG>QTDE 2a. U.M.</STRONG></P></TD>'
				_cTextHTML += '<TD width="6%"><P align=center><STRONG>2a. U.M.</STRONG></P></TD>'
				_cTextHTML += '<TD width="12%"><P align=right><STRONG>VALOR UNITÁRIO</STRONG></P></TD>'
				_cTextHTML += '<TD width="11%"><P align=right><STRONG>VALOR LIQUIDO</STRONG></P></TD>'
				_cTextHTML += '<TD width="9%"><P align=right><STRONG>PORCEN(%)</STRONG></P></TD>
				_cTextHTML += '</TR>'
				
				//====================================================================================================
				// Imprime o totalizador da Filial corrente
				//====================================================================================================
				_cTextHTML += '<TR>'
				_cTextHTML += '<TD width="34%"><FONT COLOR="#ff0000">TOTAL</FONT></TD>'
				_cTextHTML += '<TD width="11%"><P align=right><FONT COLOR="#ff0000">'+ Transform( 0				, "@E 999,999,999,999.99" )		+'</FONT></P></TD>'
				_cTextHTML += '<TD width="06%"> </TD>'
				_cTextHTML += '<TD width="11%"><P align=right><FONT COLOR="#ff0000">'+ Transform( 0				, "@E 999,999,999,999.99" )		+'</FONT></P></TD>'
				_cTextHTML += '<TD width="06%"> </TD>'
				_cTextHTML += '<TD width="12%"><P align=right><FONT COLOR="#ff0000">'+ Transform( 0				, "@E 999,999,999,999.9999" )	+'</FONT></P></TD>'
				_cTextHTML += '<TD width="11%"><P align=right><FONT COLOR="#ff0000">'+ Transform( _nVlLiqFil	, "@E 999,999,999,999.99" )		+'</FONT></P></TD>'
				_cTextHTML += '<TD width="09%"><P align=right><FONT COLOR="#ff0000">'+ Transform( 100			, "@E 999.99" )					+'</FONT></P></TD>'
				_cTextHTML += '</TR>'
				
			EndIf
			
	    	//====================================================================================================
			// Imprime os itens da tabela
			//====================================================================================================
			_nPorcent := ( (_cAliasUni)->VLRLIQ / _aDadosUni[1][5] ) * 100
			
			//====================================================================================================
			// Caso nao exista um sub-grupo de tributacao
			//====================================================================================================
			If Len(AllTrim((_cAliasUni)->CODSUB)) == 0
				
				_cDescSub	:= "000 - SEM SUB-GRUPO"
				_nQtde1		:= 0
				_nQtde2		:= 0
				_cUm1		:= " "
				_cUm2		:= " "
				_nVlrUnit	:= 0
				
			Else
			
				_cDescSub	:= AllTrim( (_cAliasUni)->CODSUB ) +' - '+ AllTrim( (_cAliasUni)->DESCSUB )
				_nQtde1		:= (_cAliasUni)->QTD1
				_nQtde2		:= (_cAliasUni)->QTD2
				_cUm1		:= (_cAliasUni)->UM1
				_cUm2		:= (_cAliasUni)->UM2
				
				If (_cAliasUni)->QTD1 > 0
				
					_nVlrUnit := (_cAliasUni)->VLRLIQ / (_cAliasUni)->QTD1
					
				ElseIf (_cAliasUni)->QTD2 > 0
				
					_nVlrUnit := (_cAliasUni)->VLRLIQ / (_cAliasUni)->QTD2
					
				EndIf
				
			EndIf
			
			_cTextHTML += '<TR>'
			_cTextHTML += '<TD width="34%">'+ _cDescSub																			+'</TD>'
			_cTextHTML += '<TD width="11%"><P align=right >'+ Transform( _nQtde1				, "@E 999,999,999,999.99" )		+'</P></TD>'
			_cTextHTML += '<TD width="06%"><P align=center>'+ _cUm1																+'</P></TD>'
			_cTextHTML += '<TD width="11%"><P align=right >'+ Transform( _nQtde2				, "@E 999,999,999,999.99" )		+'</P></TD>'
			_cTextHTML += '<TD width="06%"><P align=center>'+ _cUm2																+'</P></TD>'
			_cTextHTML += '<TD width="12%"><P align=right >'+ Transform( _nVlrUnit				, "@E 999,999,999,999.9999" )	+'</P></TD>'
			_cTextHTML += '<TD width="11%"><P align=right >'+ Transform( (_cAliasUni)->VLRLIQ	, "@E 999,999,999,999.99" )		+'</P></TD>'
			_cTextHTML += '<TD width="09%"><P align=right >'+ Transform( _nPorcent				, "@E 999.99" )					+'</P></TD>'
			_cTextHTML += '</TR>'
		
		(_cAliasUni)->( DBSkip() )
		EndDo
		
		//====================================================================================================
		// Finaliza a ultima tabela da secao RESUMO GERAL POR SUB-GRUPO DE PRODUTOS X UNIDADE
		//====================================================================================================
		_cTextHTML += '</TBODY>'
		_cTextHTML += '</TABLE>'
		_cTextHTML += '</P>'
	
	Else
	
		_lRet := .F.
		u_itconout( 'Filial: '+ (_cAliasUni)->FILIAL +' não encontrado para pegar a descricao e valor total da Filial' )
		
	EndIf

EndIf
         
//====================================================================================================
// Finaliza a area criada anteriormente
//====================================================================================================
(_cAliasUni)->( DBCloseArea() )

//====================================================================================================
// Finaliza o HTML
//====================================================================================================
_cTextHTML += '</BODY>'
_cTextHTML += '</HTML>'   

//====================================================================================================
// Caso nao tenha gerado erra na montagem do arquivo gera o arquivo para posterior envio via e-mail
//====================================================================================================
If _lRet

	//====================================================================================================
	// Cria o arquivo HTML na pasta spool da raiz do server
	//====================================================================================================
	_cArqHtml	:= _cArqAnexo
	_nHdl		:= FCreate( _cArqHtml )
	
	If _nHdl == -1
	
		u_itconout( "O arquivo de resumo de vendas nome "+ _cArqHtml +" nao pode ser criado!" , "Atencao!" )
		
		_lRet := .F.
		
	EndIf
	
	FWrite( _nHdl , _cTextHTML , Len( _cTextHTML ) )
	FClose( _nHdl )
	
	//====================================================================================================
	// Caso nao tenho ocorrido erro na geracao do arquivo, envia o e-mail contendo o reusmo em HTML
	//====================================================================================================
	If _lRet
	
		_cMsgEmail := "<B>Senhor Diretor<BR><BR>" 
		_cMsgEmail += "Segue em anexo relatório com a Relação de Vendas Anual do Grupo ITALAC para acompanhamento.<BR><BR>"
		_cMsgEmail += "Favor não responder a este e-mail.</B><BR><BR>"+ _cTextHTML
		
		SendMail( _cEmailDes , "RESUMO DE VENDAS ITALAC - PERÍODO: "+ DToC( SToD( _sDtInic ) ) +' À '+ DToC( SToD( _dDtFinal ) ) +' (GERADO EM: '+ _cGeracao +')' , _cArqAnexo , _cMsgEmail )
		
		//====================================================================================================
		// Remove o arquivo HTML criado posteriormente a finalizacao da tarefa de envio de e-mail
		//====================================================================================================
		If FERASE(_cArqAnexo) == -1
			u_itconout( 'Falha na deleção do Arquivo HTML do FONTE MOMS019' )
		EndIf
	
	EndIf

EndIf

Return

/*
===============================================================================================================================
Programa--------: DadosUni
Autor-----------: Fabiano Dias da Silva
Data da Criacao-: 13/09/2011
===============================================================================================================================
Descrição-------: Funcao responsavel por trabalhar os dados da secao valor liquido por unidade.
===============================================================================================================================
Uso-------------: Italac
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
Setor-----------: TI
===============================================================================================================================
*/

Static Function DadosUni( _cDtInic , _cDtFinal )

Local _cAlias		:= GetNextAlias()
Local _nTotalLiq	:= 0
Local _nPorcent		:= 0                
Local _aDados		:= {}

//====================================================================================================
// Consulta o faturamento liquido por unidade desconsiderando as devolucoes
//====================================================================================================
querys( 1 , _cAlias , _cDtInic , _cDtFinal )

//====================================================================================================
// Efetua inicialmente o somatorio geral do valor liquido para posterior averiguacao da porcentagem
// de participacao de cada filial com relacao ao valo total liquido
//====================================================================================================
DBSelectArea(_cAlias)
(_cAlias)->( DBGoTop() )
While (_cAlias)->( !Eof() )

	_nTotalLiq += (_cAlias)->VLRBRUT

(_cAlias)->( DBSkip() )
EndDo

//====================================================================================================
// Efetua o calculo de porcentagem de cada filial de acordo com o somatorio do valor liquido total
//====================================================================================================
DBSelectArea(_cAlias)
(_cAlias)->( DBGoTop() )
While (_cAlias)->( !Eof() )

	_nPorcent := ( (_cAlias)->VLRBRUT / _nTotalLiq ) * 100
	
	aAdd( _aDados , {	(_cAlias)->F2_FILIAL	,; // Codigo da Filial
						(_cAlias)->DESCFIL		,; // Descricao da Filial
						(_cAlias)->VLRBRUT		,; // Valor bruto da Filial corrente
						_nPorcent				,; // Porcentagem de participacao da filial corrente com relacao ao valor total liquido calculo anteriormente
						_nTotalLiq				}) // Valor total liquido geral, armazenado para uso posterior em outras secoes do HTML

(_cAlias)->( DBSkip() )
EndDo

//====================================================================================================
// Finaliza o alias criado anteriormente
//====================================================================================================
(_cAlias)->( DBCloseArea() )

Return( _aDados )

/*
===============================================================================================================================
Programa--------: SendMail
Autor-----------: Fabiano Dias da Silva
Data da Criacao-: 13/09/2011
===============================================================================================================================
Descrição-------: Funcao responsavel por processar o envio do arquivo via e-mail
===============================================================================================================================
Uso-------------: Italac
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
Setor-----------: TI
===============================================================================================================================
*/ 

Static Function SendMail( _cDestinat , _cAssunto , _cArqAnexo , _cCorpo )

Local oServer	:= Nil
Local oMessage	:= Nil
Local nErr		:= 1
Local nErrSend	:= 1

Local _lRet		:= .T.
Local _nEnvio	:= 1

Local cPopAddr	:= "pop.italac.com.br"      // Endereco do servidor POP3
Local cSMTPAddr	:= "smtp.italac.com.br"     // Endereco do servidor SMTP
Local cPOPPort	:= 110                      // Porta do servidor POP
Local cSMTPPort	:= 587                      // Porta do servidor SMTP
Local cUser		:= "workflow@italac.com.br" // Usuario que ira realizar a autenticacao
Local cPass		:= "italac2000"             // Senha do usuario
Local nSMTPTime	:= 60                       // Timeout SMTP

// Instancia um novo TMailManager
oServer := tMailManager():New()

// Usa SSL na conexao
oServer:setUseSSL( .F. )

// Inicializa
oServer:init( cPopAddr , cSMTPAddr , cUser , cPass , cPOPPort , cSMTPPort )

// Define o Timeout SMTP
If oServer:SetSMTPTimeout(nSMTPTime) != 0

	u_itconout("[ERROR]Falha ao definir timeout do FONTE: MOMS019")
	
	Return( .F. )
	
EndIf

// Conecta ao servidor
nErr := oServer:smtpConnect()

If nErr <> 0

	u_itconout( "[ERROR]Falha ao conectar: "+ oServer:getErrorString(nErr) +" do FONTE: MOMS019" )
	oServer:smtpDisconnect()
	Return( .F. )
	
EndIf

// Realiza autenticacao no servidor
nErr := oServer:smtpAuth( cUser , cPass )

If nErr <> 0

	u_itconout( "[ERROR]Falha ao autenticar: "+ oServer:getErrorString(nErr) +" do FONTE: MOMS019" )
	oServer:smtpDisconnect()
	Return( .F. )
	
EndIf

oMessage := tMailMessage():new() // Cria uma nova mensagem (TMailMessage)

oMessage:clear()
oMessage:cFrom    := "workflow@italac.com.br"
oMessage:cTo      := _cDestinat
oMessage:cCC      := ""
oMessage:cBCC     := ""
oMessage:cSubject := FWHttpEncode(_cAssunto)
oMessage:cBody    := _cCorpo

oMessage:MsgBodyType( "text/html" )

//====================================================================================================
// Verifica a adição do anexo
//====================================================================================================
If oMessage:AttachFile( _cArqAnexo ) < 0

	u_itconout( "[ERROR]Ao atachar o arquivo do FONTE: MOMS019" )
	Return( .F. )
	
Else

	// Adiciona uma tag informando que é um attach e o nome do arq
	oMessage:AddAtthTag( "Content-Disposition: attachment; filename="+ _cArqAnexo )
	
EndIf 

// Processa o envio da mensagem
While _nEnvio <= 3 .And. nErrSend <> 0

	nErrSend := oMessage:send( oServer )
	
	If nErrSend <> 0
	
		u_itconout( "[ERRO] - Falha ao enviar: "+ oServer:getErrorString(nErrSend) )
		u_itconout( "E-mail destino: "+ AllTrim(_cDestinat) )
		u_itconout( "do FONTE: MOMS019" )
		u_itconout( "Tentativa: " + AllTrim( Str(_nEnvio) ) )
		u_itconout( "Verifique o e-mail dos destinatarios." )
		
		_lRet := .F.
		
	Else
	
		_lRet := .T.
		
	EndIf

_nEnvio++
EndDo

//====================================================================================================
// Disconecta do Servidor
//====================================================================================================
oServer:smtpDisconnect()

Return( _lRet )

/*
===============================================================================================================================
Programa--------: Querys
Autor-----------: Fabiano Dias da Silva
Data da Criacao-: 13/09/2011
===============================================================================================================================
Descrição-------: Funcao que consulta e monta as áreas temporárias de dados
===============================================================================================================================
Uso-------------: Italac
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
Setor-----------: TI
===============================================================================================================================
*/

Static Function Querys( _nOpcao , _cAlias , _cDtInic , _cDtFinal )

Local _cCfops	:= U_ITCFOPS('V') // Somente considera CFOP de venda
Local _cFiltro	:= "% "
Local _sDtInic	:= _cDtInic
Local _sDtFinal	:= _cDtFinal

_cFiltro += " AND F2.F2_EMISSAO BETWEEN '"+ _sDtInic +"' AND '"+ _sDtFinal +"' "
_cFiltro += " AND D2.D2_CF IN "+ FormatIn( _cCfops , ";" )
_cFiltro += " %"

Do Case

//====================================================================================================
// Consulta do faturamento liquido por unidade desconsiderando as devolucoes
//====================================================================================================
Case _nOpcao == 1

	BeginSql alias _cAlias
	
		SELECT
			DADOS.F2_FILIAL AS FILIAL,
			(	SELECT ZZM_DESCRI
				FROM %Table:ZZM%
				WHERE	D_E_L_E_T_ = ' '
				AND		ZZM_CODIGO = DADOS.F2_FILIAL ) AS DESCFIL,
		    SUM(DADOS.VLBRUT) AS VLRBRUT
		FROM (	SELECT
					F2.F2_FILIAL,
					COALESCE( SUM( D2.D2_VALBRUT - RESULTD1.VLRBRUT ) , 0 ) AS VLBRUT
				FROM %Table:SF2% F2
				
				JOIN %Table:SD2% D2
				ON  F2.F2_FILIAL     = D2.D2_FILIAL
				AND F2.F2_DOC        = D2.D2_DOC
				AND F2.F2_SERIE      = D2.D2_SERIE
				AND F2.F2_CLIENTE    = D2.D2_CLIENTE
				AND F2.F2_LOJA       = D2.D2_LOJA
				
				JOIN %Table:SB1% B1 ON B1.B1_COD = D2.D2_COD,
				
				(	SELECT
						D1.D1_FILIAL	,
						D1.D1_NFORI		,
						D1.D1_SERIORI	,
						D1.D1_FORNECE	,
						D1.D1_LOJA		,
						D1.D1_COD		,
						COALESCE( SUM( D1.D1_TOTAL + D1.D1_ICMSRET ) , 0 ) AS VLRBRUT
					FROM %Table:SD1% D1
					WHERE	D1.D_E_L_E_T_ = ' '
					AND		D1.D1_TIPO    = 'D'
					GROUP BY D1.D1_FILIAL , D1.D1_NFORI , D1.D1_SERIORI , D1.D1_FORNECE , D1.D1_LOJA , D1.D1_COD ) RESULTD1
					
			    WHERE	F2.D_E_L_E_T_       = ' '
				AND		D2.D_E_L_E_T_       = ' '
				AND		B1.D_E_L_E_T_       = ' '
				AND		F2.F2_DUPL         <> ' '
				AND		RESULTD1.D1_FILIAL  = D2.D2_FILIAL
				AND		RESULTD1.D1_NFORI   = D2.D2_DOC
				AND		RESULTD1.D1_SERIORI = D2.D2_SERIE
				AND		RESULTD1.D1_FORNECE = D2.D2_CLIENTE
				AND		RESULTD1.D1_LOJA    = D2.D2_LOJA
				AND		RESULTD1.D1_COD     = D2.D2_COD
				
				%Exp:_cFiltro%
				
				GROUP BY F2.F2_FILIAL
				
				UNION ALL
				
				SELECT
					F2.F2_FILIAL,
					SUM( D2.D2_VALBRUT ) AS VLBRUT
				FROM %Table:SF2% F2
				
				JOIN %Table:SD2% D2
				ON  F2.F2_FILIAL     = D2.D2_FILIAL
				AND F2.F2_DOC        = D2.D2_DOC
				AND F2.F2_SERIE      = D2.D2_SERIE
				AND F2.F2_CLIENTE    = D2.D2_CLIENTE
				AND F2.F2_LOJA       = D2.D2_LOJA
				
				JOIN %Table:SB1% B1 ON B1.B1_COD = D2.D2_COD
				
				WHERE	F2.D_E_L_E_T_ = ' '
				AND		D2.D_E_L_E_T_ = ' '
				AND		B1.D_E_L_E_T_ = ' '
				AND		F2.F2_DUPL   <> ' '
				
				%Exp:_cFiltro%
				
				AND NOT EXISTS        (	SELECT 1
										FROM %Table:SD1% D1
										WHERE	D1.D_E_L_E_T_ = ' '
										AND		D1.D1_TIPO    = 'D'
										AND		D1.D1_FILIAL  = D2.D2_FILIAL
										AND		D1.D1_NFORI   = D2.D2_DOC
										AND		D1.D1_SERIORI = D2.D2_SERIE
										AND		D1.D1_FORNECE = D2.D2_CLIENTE
										AND		D1.D1_LOJA    = D2.D2_LOJA
										AND		D1.D1_COD     = D2.D2_COD )
				GROUP BY F2.F2_FILIAL
		) DADOS
			
		GROUP BY DADOS.F2_FILIAL
		HAVING SUM( DADOS.VLBRUT ) > 0
		ORDER BY VLRBRUT DESC
		
	EndSql

//====================================================================================================
// consulta do faturamento liquido por unidade x sub-grupo de produtos desconsiderando as devolucoes
//====================================================================================================
Case _nOpcao == 2

	BeginSql alias _cAlias
	
		SELECT
			DADOS.B1_I_SUBGR	AS CODSUB,
			(	SELECT ZB9.ZB9_DESSUB
				FROM %Table:ZB9% ZB9
				WHERE	ZB9.D_E_L_E_T_ = ' '
				AND		ZB9.ZB9_SUBGRU = DADOS.B1_I_SUBGR ) AS DESCSUB,
			MAX(DADOS.D2_UM)	AS UM1,
			MAX(DADOS.D2_SEGUM)	AS UM2,
			SUM(DADOS.QTD1)		AS QTD1,
			SUM(DADOS.QTD2)		AS QTD2,
			SUM(DADOS.VLBRUT)	AS VLRLIQ
		FROM (	SELECT
					B1.B1_I_SUBGR,
					D2.D2_UM,
					D2.D2_SEGUM,
					COALESCE( SUM( D2.D2_QUANT   - RESULTD1.QUANT1UM ) , 0 ) QTD1,
					COALESCE( SUM( D2.D2_QTSEGUM - RESULTD1.QUANT2UM ) , 0 ) QTD2,
					COALESCE( SUM( D2.D2_VALBRUT - RESULTD1.VLRBRUT  ) , 0 ) VLBRUT
				FROM %Table:SF2% F2
				
				JOIN %Table:SD2% D2
				ON  F2.F2_FILIAL  = D2.D2_FILIAL
				AND F2.F2_DOC     = D2.D2_DOC
				AND F2.F2_SERIE   = D2.D2_SERIE
				AND F2.F2_CLIENTE = D2.D2_CLIENTE
				AND F2.F2_LOJA    = D2.D2_LOJA
				
				JOIN %Table:SB1% B1
				ON B1.B1_COD      = D2.D2_COD,
				
				(	SELECT
						D1.D1_FILIAL,
						D1.D1_NFORI,
						D1.D1_SERIORI,
						D1.D1_FORNECE,
						D1.D1_LOJA,
						D1.D1_COD,
						COALESCE( SUM( D1.D1_QUANT					) , 0 ) QUANT1UM,
						COALESCE( SUM( D1.D1_QTSEGUM				) , 0 ) QUANT2UM,
						COALESCE( SUM( D1.D1_TOTAL + D1.D1_ICMSRET	) , 0 ) VLRBRUT
					FROM %Table:SD1% D1
					WHERE	D1.D_E_L_E_T_ = ' '
					AND		D1.D1_TIPO    = 'D'
					GROUP BY D1.D1_FILIAL, D1.D1_NFORI, D1.D1_SERIORI, D1.D1_FORNECE, D1.D1_LOJA, D1.D1_COD ) RESULTD1
					
				WHERE	F2.D_E_L_E_T_       = ' '
				AND		D2.D_E_L_E_T_       = ' '
				AND		B1.D_E_L_E_T_       = ' '
				AND		F2.F2_DUPL         <> ' '
				AND		RESULTD1.D1_FILIAL  = D2.D2_FILIAL
				AND		RESULTD1.D1_NFORI   = D2.D2_DOC
				AND		RESULTD1.D1_SERIORI = D2.D2_SERIE
				AND		RESULTD1.D1_FORNECE = D2.D2_CLIENTE
				AND		RESULTD1.D1_LOJA    = D2.D2_LOJA
				AND		RESULTD1.D1_COD     = D2.D2_COD
				
				%Exp:_cFiltro%
				
				GROUP BY B1.B1_I_SUBGR, D2.D2_UM, D2.D2_SEGUM
				
				HAVING SUM( D2.D2_QUANT - RESULTD1.QUANT1UM ) > 0 OR SUM( D2.D2_QTSEGUM   - RESULTD1.QUANT2UM ) > 0
				
				UNION ALL
				
				SELECT
				    B1.B1_I_SUBGR            ,
				    D2.D2_UM                 ,
				    D2.D2_SEGUM              ,
				    SUM(D2.D2_QUANT) QTD1    ,
				    SUM(D2.D2_QTSEGUM) QTD2  ,
				    SUM(D2.D2_VALBRUT) VLBRUT
				FROM %Table:SF2% F2
				
				JOIN %Table:SD2% D2
				ON	F2.F2_FILIAL  = D2.D2_FILIAL
				AND F2.F2_DOC     = D2.D2_DOC
				AND F2.F2_SERIE   = D2.D2_SERIE
				AND F2.F2_CLIENTE = D2.D2_CLIENTE
				AND F2.F2_LOJA    = D2.D2_LOJA
				
				JOIN %Table:SB1% B1
				ON B1.B1_COD      = D2.D2_COD
				
				WHERE	F2.D_E_L_E_T_ = ' '
				AND		D2.D_E_L_E_T_ = ' '
				AND		B1.D_E_L_E_T_ = ' '
				AND		F2.F2_DUPL   <> ' '
				
				%Exp:_cFiltro%
				
				AND NOT EXISTS (	SELECT 1
									FROM %Table:SD1% D1
									WHERE	D1.D_E_L_E_T_ = ' '
									AND		D1.D1_TIPO    = 'D'
									AND		D1.D1_FILIAL  = D2.D2_FILIAL
									AND		D1.D1_NFORI   = D2.D2_DOC
									AND		D1.D1_SERIORI = D2.D2_SERIE
									AND		D1.D1_FORNECE = D2.D2_CLIENTE
									AND		D1.D1_LOJA    = D2.D2_LOJA
									AND		D1.D1_COD     = D2.D2_COD )
				GROUP BY B1.B1_I_SUBGR , D2.D2_UM , D2.D2_SEGUM
		) DADOS
		
		GROUP BY CODSUB
		ORDER BY VLRLIQ DESC , CODSUB
		
	EndSql        					

//====================================================================================================
// Consulta do faturamento liquido por unidade x sub-grupo x Filial desconsiderando as devolucoes
//====================================================================================================
Case _nOpcao == 3

	BeginSql alias _cAlias
	
		SELECT
		    DADOS.F2_FILIAL		AS FILIAL,
		    DADOS.B1_I_SUBGR	AS CODSUB,
			(	SELECT ZB9.ZB9_DESSUB
				FROM %Table:ZB9% ZB9
				WHERE	ZB9.D_E_L_E_T_ = ' '
				AND		ZB9.ZB9_SUBGRU = DADOS.B1_I_SUBGR ) AS DESCSUB,
			MAX( DADOS.D2_UM	) AS UM1,
			MAX( DADOS.D2_SEGUM	) AS UM2,
			SUM( DADOS.QTD1		) AS QTD1,
			SUM( DADOS.QTD2		) AS QTD2,
			SUM( DADOS.VLBRUT	) AS VLRLIQ
		FROM (	SELECT 
					F2.F2_FILIAL,
					B1.B1_I_SUBGR,
					D2.D2_UM,
					D2.D2_SEGUM,
					COALESCE( SUM( D2.D2_QUANT   - RESULTD1.QUANT1UM ) , 0 ) AS QTD1 ,
					COALESCE( SUM( D2.D2_QTSEGUM - RESULTD1.QUANT2UM ) , 0 ) AS QTD2 ,
					COALESCE( SUM( D2.D2_VALBRUT - RESULTD1.VLRBRUT  ) , 0 ) AS VLBRUT
				FROM %Table:SF2% F2
				
				JOIN %Table:SD2% D2
				ON  F2.F2_FILIAL  = D2.D2_FILIAL
				AND F2.F2_DOC     = D2.D2_DOC
				AND F2.F2_SERIE   = D2.D2_SERIE
				AND F2.F2_CLIENTE = D2.D2_CLIENTE
				AND F2.F2_LOJA    = D2.D2_LOJA
				
				JOIN %Table:SB1% B1 ON B1.B1_COD = D2.D2_COD,
				
				(	SELECT
						D1.D1_FILIAL,
						D1.D1_NFORI,
						D1.D1_SERIORI,
						D1.D1_FORNECE,
						D1.D1_LOJA,
						D1.D1_COD,
						COALESCE( SUM( D1.D1_QUANT					) , 0 ) QUANT1UM,
						COALESCE( SUM( D1.D1_QTSEGUM				) , 0 ) QUANT2UM,
						COALESCE( SUM( D1.D1_TOTAL + D1.D1_ICMSRET	) , 0 ) VLRBRUT
					FROM %Table:SD1% D1
					WHERE	D1.D_E_L_E_T_ = ' '
				    AND		D1.D1_TIPO        = 'D'
					GROUP BY D1.D1_FILIAL, D1.D1_NFORI, D1.D1_SERIORI, D1.D1_FORNECE, D1.D1_LOJA, D1.D1_COD ) RESULTD1
					
			    WHERE
					F2.D_E_L_E_T_       = ' '
				AND D2.D_E_L_E_T_       = ' '
				AND B1.D_E_L_E_T_       = ' '
				AND F2.F2_DUPL         <> ' '
				AND RESULTD1.D1_FILIAL  = D2.D2_FILIAL
				AND RESULTD1.D1_NFORI   = D2.D2_DOC
				AND RESULTD1.D1_SERIORI = D2.D2_SERIE
				AND RESULTD1.D1_FORNECE = D2.D2_CLIENTE
				AND RESULTD1.D1_LOJA    = D2.D2_LOJA
				AND RESULTD1.D1_COD     = D2.D2_COD
				
				%Exp:_cFiltro%
				
				GROUP BY F2.F2_FILIAL, B1.B1_I_SUBGR, D2.D2_UM, D2.D2_SEGUM
				HAVING SUM( D2.D2_QUANT - RESULTD1.QUANT1UM ) > 0 OR SUM( D2.D2_QTSEGUM - RESULTD1.QUANT2UM ) > 0
				
				UNION ALL
				
				SELECT 
					F2.F2_FILIAL,
					B1.B1_I_SUBGR,
					D2.D2_UM,
					D2.D2_SEGUM,
					SUM( D2.D2_QUANT	) QTD1 ,
					SUM( D2.D2_QTSEGUM	) QTD2 ,
					SUM( D2.D2_VALBRUT	) VLBRUT
				FROM %Table:SF2% F2
				
				JOIN %Table:SD2% D2
				ON	F2.F2_FILIAL  = D2.D2_FILIAL
				AND F2.F2_DOC     = D2.D2_DOC
				AND F2.F2_SERIE   = D2.D2_SERIE
				AND F2.F2_CLIENTE = D2.D2_CLIENTE
				AND F2.F2_LOJA    = D2.D2_LOJA
				
				JOIN %Table:SB1% B1
				ON	B1.B1_COD     = D2.D2_COD
				
				WHERE
					F2.D_E_L_E_T_ = ' '
				AND	D2.D_E_L_E_T_ = ' '
				AND	B1.D_E_L_E_T_ = ' '
				AND	F2.F2_DUPL   <> ' '
				
				%Exp:_cFiltro%
				
				AND NOT EXISTS    (	SELECT 1
									FROM %Table:SD1% D1
									WHERE	D1.D_E_L_E_T_ = ' '
									AND		D1.D1_TIPO    = 'D'
									AND		D1.D1_FILIAL  = D2.D2_FILIAL
									AND		D1.D1_NFORI   = D2.D2_DOC
									AND		D1.D1_SERIORI = D2.D2_SERIE
									AND		D1.D1_FORNECE = D2.D2_CLIENTE
									AND		D1.D1_LOJA    = D2.D2_LOJA
									AND		D1.D1_COD     = D2.D2_COD )
				GROUP BY F2.F2_FILIAL, B1.B1_I_SUBGR, D2.D2_UM, D2.D2_SEGUM
		) DADOS
		
		GROUP BY FILIAL , CODSUB
		ORDER BY FILIAL , VLRLIQ DESC
		
	EndSql

//====================================================================================================
// Selecionar os e-mail's dos usuarios que sera enviado o resumo do HTML
//====================================================================================================
Case _nOpcao == 4

	BeginSql alias _cAlias
	
		SELECT ZZL_EMAIL
		FROM %Table:ZZL%
		WHERE	D_E_L_E_T_ = ' '
		AND		ZZL_ENVRES = 'S'
		
	EndSql
					
EndCase

Return
