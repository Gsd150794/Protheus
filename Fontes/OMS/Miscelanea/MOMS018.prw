/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
       Autor      |    Data    |                                             Motivo                                           
-------------------------------------------------------------------------------------------------------------------------------
Alexandre Villar  | 26/01/2016 | Chamado 13859 - Correção das tratativas dos nomes dos campos pois após a atualização anterior gerou erro no
                  |            |                 processamento e abortava o envio do WF agendado. 
-------------------------------------------------------------------------------------------------------------------------------
Alexandre Villar  | 23/03/2016 | Chamado 14774 - Ajuste para padronizar a utilização de rotinas de consultas customizadas. 
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges      | 11/10/2019 | Chamado 28346 - Removidos os Warning na compilação da release 12.1.25. 
-------------------------------------------------------------------------------------------------------------------------------
Igor Melgaço      | 30/11/2023 | Chamado 45712 - Ajuste para envio por periodo diário de vendas. 
-------------------------------------------------------------------------------------------------------------------------------
Igor Melgaço      | 05/12/2023 | Chamado 45712 - Ajustes para envio via Schedule. 
-------------------------------------------------------------------------------------------------------------------------------
Igor Melgaço      | 11/12/2023 | Chamado 45712 - Ajustes para envio via aos responsáveis. 
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz         | 19/03/2024 | Chamado 46670 - Ajustes nas descrições dos títulos do workflow.
===============================================================================================================================
*/

//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================
#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MOMS018
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 13/09/2011
===============================================================================================================================
Descrição---------: Funcao desenvolvida para realizar o envio do Resumo do faturamento líquido mensal no mâs corrente sem
------------------: considerar as devoluções. Este resumo sera demonstrado por unidade geral e outro por unidade x sub-grupo 
------------------: de produtos, montado em HTML somente será enviado para pessoas que possuam cadastro na tabela(ZZL).
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS018(_lRDiario)

Local _aTables	:= { "SF2" , "SD2" , "SD1" , "SB1" , "ZB9" , "ZZL" }
Local _cAlias	:= ""
Local _cEmail	:= ''

Local _lOpnAmb	:= Select("SX3") <= 0

Default _lRDiario := .F.

u_itconout( '[MOMS018]['+ DToC(Date()) +" - "+ Time() +'] - Relatório com _lRDiario = ' + ValType( _lRDiario )  )

If ValType( _lRDiario ) # "L"
	_lRDiario := .F.
EndIf

//====================================================================================================
// Verifica a necessidade de criar um ambiente, caso nao esteja criado anteriormente
//====================================================================================================
If _lOpnAmb

	RPCSetType(3)										   		  		//Nao consome licensas
	RpcSetEnv( "01" , "01" ,,,, "SCHEDULE_EMAIL_RESUMO" , _aTables )	//seta o ambiente com a empresa 01 filial 01
	Sleep( 5000 )												 		//Aguarda 5 segundos para que as jobs IPC subam
    u_itconout( '[MOMS018]['+ DToC(Date()) +" - "+ Time() +'] - Gerando envio do arquivo HTML de Resumo de vendas desconsiderando devoluções' )

EndIf

//====================================================================================================
// Verifica inicialmente para quais usuarios o resumo sera enviado
//====================================================================================================
_cAlias := GetNextAlias()
MOMS018QRY( 4 , _cAlias , _lRDiario )

DBSelectArea(_cAlias)
(_cAlias)->( DBGoTop() )

//====================================================================================================
// Devera existir no minimo um e-mail cadastrado para que a rotina processe a montagem dos dados
//====================================================================================================
If (_cAlias)->( !Eof() )

	While (_cAlias)->( !Eof() )
		_cEmail += AllTrim( (_cAlias)->ZZL_EMAIL ) +';'
	(_cAlias)->( DBSkip() )
	EndDo
	
	//====================================================================================================
	// Verifica os e-mails e chama a rotina de processamento
	//====================================================================================================
	If !Empty( _cEmail )
		MOMS018EXE( _cEmail,_lRDiario)
	EndIf

EndIf

//====================================================================================================
// Finaliza a area criada anteriormente
//====================================================================================================
(_cAlias)->( DBCloseArea() )

If _lOpnAmb
	RpcClearEnv() //Limpa o ambiente, liberando a licença e fechando as conexões 
EndIf

u_itconout( '[MOMS018]['+ DToC(Date()) +" - "+ Time() +'] - Termino de execucao normal do envio do HTML de Resumo de vendas' )

Return

/*
===============================================================================================================================
Programa----------: MOMS018EXE
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 13/09/2011
===============================================================================================================================
Descrição---------: Gera o arquivo HTML com o conteúdo do relatório e Processa o envio por e-mail
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS018EXE( _cEmail,_lRDiario )

Local _cArqAnx		:= "\spool\resumo_vendas"+ StrTran( Time() , ":" , "'" ) +".html"
Local _aDadFil		:= {}
Local _cArqHtm		:= ''
Local _nHdl			:= 0
Local _cTxtHTM		:= ""
Local _lRet			:= .T.
Local _nI			:= 1
Local _cAliasG		:= ""
Local _cDesSub		:= ""
Local _nQtde1		:= 0
Local _nQtde2		:= 0
Local _cUm1			:= ""
Local _cUm2			:= ""
Local _nVlrUni		:= 0
Local _nPorcent		:= 0
Local _nVlrNet		:= 0
Local _cDesFil		:= ""
Local _nVlLFil		:= 0
Local _cFilial		:= ""    
Local _cMsgEml		:= ""        
Local _cEmlLog		:= ''

Local _dDtIni		:= FirstDay( Date() )
Local _dDtFim		:= LastDay( Date() )

Local _cDtGera		:= DToC( Date() )  

Local _cConfig		:= GetMV( "IT_CMWFEP" ,, "001" )
Local _aConfig		:= U_ITCFGEML( _cConfig )

Default _lRDiario := .F.

If _lRDiario
	_dDtIni  := Date()-1
	_dDtFim := _dDtIni
EndIf

//====================================================================================================
// Funcao para trabalhar os dados da secao valor liquido por unidade para montagem do aquivo.
//====================================================================================================
_aDadFil := MOMS018FIL(_lRDiario)

//====================================================================================================
// Define o cabecalho do HTML
//====================================================================================================
_cTxtHTM += '<!DOCTYPE HTML Public "-//W3C//DTD HTML 4.0 Transitional//EN">'
_cTxtHTM += '<HTML><HEAD><TITLE>.:: WF de Vendas - ITALAC ::.</TITLE>'
_cTxtHTM += '<META content="text/html; charset=windows-1252" http-equiv=Content-Type></HEAD>'
_cTxtHTM += '<style Type="text/css"><!--'
_cTxtHTM += 'table.bordasimples { border-collapse: collapse; } '
_cTxtHTM += 'table.bordasimples tr td { border:1px solid #777777; } '
_cTxtHTM += 'td.grupos	{ font-family:VERDANA; font-size:18px; V-align:middle; background-color: #000099; color:#FFFFFF; } '
_cTxtHTM += 'td.titulos	{ font-family:VERDANA; font-size:16px; V-align:middle; background-color: #FFCC33; } '
_cTxtHTM += 'td.itens	{ font-family:VERDANA; font-size:12px; V-align:middle; } '
_cTxtHTM += 'td.totais	{ font-family:VERDANA; font-size:12px; V-align:middle; background-color: #AAAAAA; } '
_cTxtHTM += '--></style>'

//====================================================================================================
// Define o corpo do HTML
//====================================================================================================
_cTxtHTM += '<BODY>'
_cTxtHTM += '<table cellSpacing=0 cellPadding=0 width="100%" class="bordasimples">'
_cTxtHTM += '  <tr>'

If _lRDiario
	_cTxtHTM += '     <td class="grupos"><center>Resumo diário de vendas Grupo Italac</td>'
	_cTxtHTM += '     <td class="grupos"><center>Ref. a Data '+ DToC( _dDtIni ) + ' ( Gerado em '+ _cDtGera +' às '+ Transform( Time() , "@R 99:99" ) +')</td>'
	
Else
	_cTxtHTM += '     <td class="grupos"><center>Vendas Grupo Italac</td>'
	_cTxtHTM += '     <td class="grupos"><center>Período de '+ DToC( _dDtIni ) +' ate '+ DToC( _dDtFim ) +' ( Gerado em '+ _cDtGera +' às '+ Transform( Time() , "@R 99:99" ) +')</td>'
	
EndIf
_cTxtHTM += '  </tr>'
_cTxtHTM += '</table>'
_cTxtHTM += '<br>'

//====================================================================================================
// Define estrutura da primeira secao RESUMO POR FILIAL.
//====================================================================================================
_cTxtHTM += '<table cellSpacing=0 cellPadding=0 width="100%" class="bordasimples">'
_cTxtHTM += '  <tr>'
_cTxtHTM += '     <td class="grupos"><center>Resumo por Unidade<br></td>'
_cTxtHTM += '  </tr>'
_cTxtHTM += '</table>'

_cTxtHTM += '<table cellSpacing=0 cellPadding=0 width="100%" class="bordasimples">'
_cTxtHTM += '  <TR>'
_cTxtHTM += '    <TD width="50%" bgcolor="#D8D8D8" align="center" class="itens">Unidades</TD>'
_cTxtHTM += '    <TD width="25%" bgcolor="#D8D8D8" align="center" class="itens">Valor Total(R$)</TD>'
_cTxtHTM += '    <TD width="25%" bgcolor="#D8D8D8" align="center" class="itens">Participação(%)</TD>'
_cTxtHTM += '  </TR>'
                      
//====================================================================================================
// Verifica se existe no minimo uma linha de dados.
//====================================================================================================
If Len(_aDadFil) > 0 
	
	//====================================================================================================
	// Imprime totalizador
	//====================================================================================================
	_cTxtHTM += '<TR>'
	_cTxtHTM += '<TD width="50%" class="totais">Total</TD>'
	_cTxtHTM += '<TD width="25%" class="totais" align="right">'+ Transform( _aDadFil[01][05]	, "@E 999,999,999,999.99"	) +'</TD>'
	_cTxtHTM += '<TD width="25%" class="totais" align="right">'+ Transform( 100			 		, "@E 999.99"				) +'</TD>'
	_cTxtHTM += '</TR>'
	
	//====================================================================================================
	// Insere os dados de todas as filiais encontradas na consulta.
	//====================================================================================================
	For _nI := 1 to Len(_aDadFil)
	
		_cTxtHTM += '<TR>'
		_cTxtHTM += '<TD width="50%" class="itens">'+ _aDadFil[_nI][01] +' - '+ AllTrim(_aDadFil[_nI][02]) +'</TD>'
		_cTxtHTM += '<TD width="25%" class="itens" align="right">'+ Transform( _aDadFil[_nI][03] , "@E 999,999,999,999.99"	) +'</TD>'
		_cTxtHTM += '<TD width="25%" class="itens" align="right">'+ Transform( _aDadFil[_nI][04] , "@E 999.99"				) +'</TD>'
		_cTxtHTM += '</TR>'
	
	Next _nI

Else

	_lRet := .F.
	u_itconout('[MOMS018]['+ DToC(Date()) +" - "+ Time() +'] - Nao foram encontrados registros da primeira secao RESUMO FILIAL.' )

EndIf

//====================================================================================================
// Finaliza a tabela da secao RESUMO POR FILIAL
//====================================================================================================
_cTxtHTM += '</TABLE>'
_cTxtHTM += '<br>'                        

If !_lRDiario
	//====================================================================================================
	// Define a estrutura da segunda secao RESUMO GERAL POR SUBGRUPO DE PRODUTO
	//====================================================================================================
	_cTxtHTM += '<table cellSpacing=0 cellPadding=0 width="100%" class="bordasimples">'
	_cTxtHTM += '  <tr>'
	_cTxtHTM += '     <td class="grupos"><center>Resumo geral por sub-grupo de produtos<br></td>'
	_cTxtHTM += '  </tr>'
	_cTxtHTM += '</table>'

	_cTxtHTM += '<table cellSpacing=0 cellPadding=0 width="100%" class="bordasimples">'
	_cTxtHTM += '  <TR>'
	_cTxtHTM += '    <TD width="33%" bgcolor="#D8D8D8" align="center" class="itens">Sub-Grupos</TD>'
	_cTxtHTM += '    <TD width="12%" bgcolor="#D8D8D8" align="center" class="itens">Qtd. 1ª U.M.</TD>'
	_cTxtHTM += '    <TD width="04%" bgcolor="#D8D8D8" align="center" class="itens">U.M.</TD>'
	_cTxtHTM += '    <TD width="12%" bgcolor="#D8D8D8" align="center" class="itens">Qtd. 2ª U.M.</TD>'
	_cTxtHTM += '    <TD width="04%" bgcolor="#D8D8D8" align="center" class="itens">U.M.</TD>'
	_cTxtHTM += '    <TD width="10%" bgcolor="#D8D8D8" align="center" class="itens">Preço Méd. NET</TD>'
	_cTxtHTM += '    <TD width="10%" bgcolor="#D8D8D8" align="center" class="itens">Preço Méd. Brt</STRONG></P></TD>'
	_cTxtHTM += '    <TD width="10%" bgcolor="#D8D8D8" align="center" class="itens">Valor Total</TD>'
	_cTxtHTM += '    <TD width="05%" bgcolor="#D8D8D8" align="center" class="itens">Perc.(%)</TD>'
	_cTxtHTM += '  </TR>'

	//====================================================================================================
	// Verifica se existe no minimo uma linha de dados
	//====================================================================================================
	If Len(_aDadFil) > 0 

		//====================================================================================================
		// Query para realizar o consulta do faturamento liquido por unidade x sub-grupo de produtos
		//====================================================================================================
		_cAliasG := GetNextAlias()
		MOMS018QRY( 2 , _cAliasG ,_lRDiario)    
									
		DBSelectArea(_cAliasG)
		(_cAliasG)->( DBGoTop() )

		_cTxtHTM += '<TR>'
		_cTxtHTM += '  <TD width="33%" class="totais">Total</TD>'
		_cTxtHTM += '  <TD width="12%" class="totais" align="right">'+ Transform( 0					, "@E 999,999,999,999.99"	) +'</TD>'
		_cTxtHTM += '  <TD width="04%" class="totais">&nbsp;</TD>'
		_cTxtHTM += '  <TD width="12%" class="totais" align="right">'+ Transform( 0					, "@E 999,999,999,999.99"	) +'</TD>'
		_cTxtHTM += '  <TD width="04%" class="totais">&nbsp;</TD>'
		_cTxtHTM += '  <TD width="10%" class="totais" align="right">'+ Transform( 0					, "@E 999,999,999,999.9999"	) +'</TD>'
		_cTxtHTM += '  <TD width="10%" class="totais" align="right">'+ Transform( 0					, "@E 999,999,999,999.9999"	) +'</TD>'
		_cTxtHTM += '  <TD width="10%" class="totais" align="right">'+ Transform( _aDadFil[01][05]	, "@E 999,999,999,999.99"	) +'</TD>'
		_cTxtHTM += '  <TD width="05%" class="totais" align="right">'+ Transform( 100				, "@E 999.99"				) +'</TD>'
		_cTxtHTM += '</TR>'
		
		//====================================================================================================
		// Insere na tabela todos os sub-grupos de produtos encontrados
		//====================================================================================================
		While (_cAliasG)->( !Eof() )

			_nQtde1		:= 0
			_nQtde2		:= 0
			_cUm1		:= " "
			_cUm2		:= " "
			_nVlrUni	:= 0
			_nVlrNet	:= 0
			_nPorcent := ( (_cAliasG)->VLRLIQ / _aDadFil[1,5] ) * 100
			
			//====================================================================================================
			// Caso nao exista um sub-grupo de tributacao
			//====================================================================================================
			If Empty( (_cAliasG)->CODSUB )
			
				_cDesSub	:= "000 - SEM SUB-GRUPO"
			
			Else
				
				_cDesSub	:= AllTrim((_cAliasG)->CODSUB) + ' - ' + AllTrim((_cAliasG)->DESCSUB)
				_nQtde1		:= (_cAliasG)->QTD1
				_nQtde2		:= (_cAliasG)->QTD2
				_cUm1		:= (_cAliasG)->UM1
				_cUm2		:= (_cAliasG)->UM2
				
				If (_cAliasG)->QTD1 > 0
				
					_nVlrUni	:= (_cAliasG)->VLRLIQ / (_cAliasG)->QTD1
					_nVlrNet	:= (_cAliasG)->VLRNET / (_cAliasG)->QTD1
					
				ElseIf (_cAliasG)->QTD2 > 0
				
					_nVlrUni	:= (_cAliasG)->VLRLIQ / (_cAliasG)->QTD2
					_nVlrNet	:= (_cAliasG)->VLRNET / (_cAliasG)->QTD2
					
				EndIf
				
			EndIf
			
			_cTxtHTM += '<TR>'
			_cTxtHTM += '<TD width="33%" class="itens">'+ _cDesSub +'</TD>'
			_cTxtHTM += '<TD width="12%" class="itens" align="right" >'+ Transform( _nQtde1				, "@E 999,999,999,999.99"	) +'</TD>'
			_cTxtHTM += '<TD width="04%" class="itens" align="center">'+ _cUm1 +'</TD>'
			_cTxtHTM += '<TD width="12%" class="itens" align="right" >'+ Transform( _nQtde2				, "@E 999,999,999,999.99"	) +'</TD>'
			_cTxtHTM += '<TD width="04%" class="itens" align="center">'+ _cUm2 +'</TD>'
			_cTxtHTM += '<TD width="10%" class="itens" align="right" >'+ Transform( _nVlrNet			, "@E 999,999,999,999.9999"	) +'</TD>'
			_cTxtHTM += '<TD width="10%" class="itens" align="right" >'+ Transform( _nVlrUni			, "@E 999,999,999,999.9999"	) +'</TD>'
			_cTxtHTM += '<TD width="10%" class="itens" align="right" >'+ Transform( (_cAliasG)->VLRLIQ	, "@E 999,999,999,999.99"	) +'</TD>'
			_cTxtHTM += '<TD width="05%" class="itens" align="right" >'+ Transform( _nPorcent			, "@E 999.99"				) +'</TD>'
			_cTxtHTM += '</TR>'
		
		(_cAliasG)->( DBSkip() )
		EndDo
		
		//====================================================================================================
		// Finaliza a area criada anteriormente.
		//====================================================================================================
		(_cAliasG)->( DBCloseArea() )
		
	EndIf

	//====================================================================================================
	// Finaliza a tabela da secao RESUMO GERAL POR SUB-GRUPO DE PRODUTOS
	//====================================================================================================
	_cTxtHTM += '</TABLE>'
	_cTxtHTM += '<br>'

	//====================================================================================================
	// Define a estrutura da terceira secao RESUMO GERAL POR SUBGRUPO DE PRODUTO X UNIDADE
	//====================================================================================================
	// Query para realizar o consulta do faturamento liquido por unidade x sub-grupo de produtos
	//====================================================================================================
	_cAliasU := GetNextAlias()
	MOMS018QRY( 3 , _cAliasU ,_lRDiario )   

	DBSelectArea(_cAliasU)
	(_cAliasU)->( DBGoTop() )

	If (_cAliasU)->( !Eof() )

		//====================================================================================================
		// Pega a descricao e valor liquido total da primeira filial conforme  dados do RESUMO POR FILIAL
		//====================================================================================================
		_nPosFil := aScan( _aDadFil , {|W| W[1] == (_cAliasU)->FILIAL } )
		
		If _nPosFil > 0
		
			_cDesFil	:= _aDadFil[_nPosFil][02]	//Descricao da Filial
			_nVlLFil	:= _aDadFil[_nPosFil][03]	//Valor total liquido da Filial
			_cFilial	:= (_cAliasU)->FILIAL		//Seta a variavel de controle da Filial
			
			_cTxtHTM += '<table cellSpacing=0 cellPadding=0 width="100%" class="bordasimples">'
			_cTxtHTM += '  <tr>'
			_cTxtHTM += '     <td class="grupos"><center>Unidade: '+ AllTrim( _cDesFil ) +'<br></td>'
			_cTxtHTM += '  </tr>'
			_cTxtHTM += '</table>'
			
			_cTxtHTM += '<table cellSpacing=0 cellPadding=0 width="100%" class="bordasimples">'
			_cTxtHTM += '  <TR>'
			_cTxtHTM += '    <TD width="33%" bgcolor="#D8D8D8" align="center" class="itens">Sub-Grupos</TD>'
			_cTxtHTM += '    <TD width="12%" bgcolor="#D8D8D8" align="center" class="itens">Qtd. 1ª U.M.</TD>'
			_cTxtHTM += '    <TD width="04%" bgcolor="#D8D8D8" align="center" class="itens">U.M.</TD>'
			_cTxtHTM += '    <TD width="12%" bgcolor="#D8D8D8" align="center" class="itens">Qtd. 2ª U.M.</TD>'
			_cTxtHTM += '    <TD width="04%" bgcolor="#D8D8D8" align="center" class="itens">U.M.</TD>'
			_cTxtHTM += '    <TD width="10%" bgcolor="#D8D8D8" align="center" class="itens">Preço Méd. NET</TD>'
			_cTxtHTM += '    <TD width="10%" bgcolor="#D8D8D8" align="center" class="itens">Preço Méd. Brt</STRONG></P></TD>'
			_cTxtHTM += '    <TD width="10%" bgcolor="#D8D8D8" align="center" class="itens">Valor Total</TD>'
			_cTxtHTM += '    <TD width="05%" bgcolor="#D8D8D8" align="center" class="itens">Perc.(%)</TD>'
			_cTxtHTM += '  </TR>'
			
			_cTxtHTM += '  <TR>'
			_cTxtHTM += '    <TD width="33%" class="totais">Total</TD>'
			_cTxtHTM += '    <TD width="12%" class="totais" align="right" >'+ Transform( 0			, "@E 999,999,999,999.99"	) +'</TD>'
			_cTxtHTM += '    <TD width="04%" class="totais" align="center">&nbsp;</TD>'
			_cTxtHTM += '    <TD width="12%" class="totais" align="right" >'+ Transform( 0			, "@E 999,999,999,999.99"	) +'</TD>'
			_cTxtHTM += '    <TD width="04%" class="totais" align="center">&nbsp;</TD>'
			_cTxtHTM += '    <TD width="10%" class="totais" align="right" >'+ Transform( 0			, "@E 999,999,999,999.9999"	) +'</TD>'
			_cTxtHTM += '    <TD width="10%" class="totais" align="right" >'+ Transform( 0			, "@E 999,999,999,999.9999"	) +'</TD>'
			_cTxtHTM += '    <TD width="10%" class="totais" align="right" >'+ Transform( _nVlLFil	, "@E 999,999,999,999.99"	) +'</TD>'
			_cTxtHTM += '    <TD width="05%" class="totais" align="right" >'+ Transform( 100		, "@E 999.99"				) +'</TD>'
			_cTxtHTM += '  </TR>'
			
			//====================================================================================================
			// Insere na tabela todos os sub-grupos de produtos encontrados, gerando cada filial em uma tabela
			//====================================================================================================
			While (_cAliasU)->( !Eof() )
			
				If _cFilial <> (_cAliasU)->FILIAL
					
					//====================================================================================================
					// Seta variavel de controle
					//====================================================================================================
					_cFilial := (_cAliasU)->FILIAL
					
					//====================================================================================================
					// Finaliza a tabela anterior da secao
					//====================================================================================================
					_cTxtHTM += '</TABLE>'
					_cTxtHTM += '<br>'
					
					//====================================================================================================
					// Pega a descricao e valor liquido total da primeira filial conforme dados do RESUMO POR FILIAL.
					//====================================================================================================
					_nPosFil := aScan( _aDadFil , {|W| W[1] == (_cAliasU)->FILIAL} )
					
					If _nPosFil > 0
					
						_cDesFil	:= _aDadFil[_nPosFil][02]	//Descricao da Filial
						_nVlLFil	:= _aDadFil[_nPosFil][03]	//Valor total liquido da Filial
						_cFilial	:= (_cAliasU)->FILIAL		//Seta a variavel de controle da Filial
						
					Else
					
						_lRet := .F.
						u_itconout( '[MOMS018]['+ DToC(Date()) +" - "+ Time() +'] - Filial: ' + (_cAliasU)->FILIAL + ' nao encontrado para pegar a descricao e valor total da Filial' )
						Exit
						
					EndIf 
					
					_cTxtHTM += '<table cellSpacing=0 cellPadding=0 width="100%" class="bordasimples">'
					_cTxtHTM += '  <tr>'
					_cTxtHTM += '     <td class="grupos"><center>Unidade: '+ AllTrim( _cDesFil ) +'<br></td>'
					_cTxtHTM += '  </tr>'
					_cTxtHTM += '</table>'
					
					_cTxtHTM += '<table cellSpacing=0 cellPadding=0 width="100%" class="bordasimples">'
					_cTxtHTM += '  <TR>'
					_cTxtHTM += '    <TD width="33%" bgcolor="#D8D8D8" align="center" class="itens">Sub-Grupos</TD>'
					_cTxtHTM += '    <TD width="12%" bgcolor="#D8D8D8" align="center" class="itens">Qtd. 1ª U.M.</TD>'
					_cTxtHTM += '    <TD width="04%" bgcolor="#D8D8D8" align="center" class="itens">U.M.</TD>'
					_cTxtHTM += '    <TD width="12%" bgcolor="#D8D8D8" align="center" class="itens">Qtd. 2ª U.M.</TD>'
					_cTxtHTM += '    <TD width="04%" bgcolor="#D8D8D8" align="center" class="itens">U.M.</TD>'
					_cTxtHTM += '    <TD width="10%" bgcolor="#D8D8D8" align="center" class="itens">Preço Méd. NET</TD>'
					_cTxtHTM += '    <TD width="10%" bgcolor="#D8D8D8" align="center" class="itens">Preço Méd. Brt</STRONG></P></TD>'
					_cTxtHTM += '    <TD width="10%" bgcolor="#D8D8D8" align="center" class="itens">Valor Total</TD>'
					_cTxtHTM += '    <TD width="05%" bgcolor="#D8D8D8" align="center" class="itens">Perc.(%)</TD>'
					_cTxtHTM += '  </TR>'

					_cTxtHTM += '  <TR>'
					_cTxtHTM += '    <TD width="33%" class="totais">Total</TD>'
					_cTxtHTM += '    <TD width="12%" class="totais" align="right" >'+ Transform( 0			, "@E 999,999,999,999.99"	) +'</TD>'
					_cTxtHTM += '    <TD width="04%" class="totais" align="center">&nbsp;</TD>'
					_cTxtHTM += '    <TD width="12%" class="totais" align="right" >'+ Transform( 0			, "@E 999,999,999,999.99"	) +'</TD>'
					_cTxtHTM += '    <TD width="04%" class="totais" align="center">&nbsp;</TD>'
					_cTxtHTM += '    <TD width="10%" class="totais" align="right" >'+ Transform( 0			, "@E 999,999,999,999.9999"	) +'</TD>'
					_cTxtHTM += '    <TD width="10%" class="totais" align="right" >'+ Transform( 0			, "@E 999,999,999,999.9999"	) +'</TD>'
					_cTxtHTM += '    <TD width="10%" class="totais" align="right" >'+ Transform( _nVlLFil	, "@E 999,999,999,999.99"	) +'</TD>'
					_cTxtHTM += '    <TD width="05%" class="totais" align="right" >'+ Transform( 100		, "@E 999.99"				) +'</TD>'
					_cTxtHTM += '  </TR>'
					
					EndIf
				
				//====================================================================================================
				// Imprime os itens da tabela.
				//====================================================================================================
				_nQtde1		:= 0
				_nQtde2		:= 0
				_cUm1		:= " "
				_cUm2		:= " "
				_nVlrUni	:= 0
				_nVlrNet	:= 0
				_nPorcent := ( (_cAliasU)->VLRLIQ /_nVlLFil ) * 100
				
				//====================================================================================================
				// Caso nao exista um sub-grupo de tributacao.
				//====================================================================================================
				If Empty( (_cAliasU)->CODSUB )
				
					_cDesSub	:= "000 - SEM SUB-GRUPO"
					
				Else
					
					_cDesSub	:= AllTrim( (_cAliasU)->CODSUB ) +' - '+ AllTrim( (_cAliasU)->DESCSUB )
					_nQtde1		:= (_cAliasU)->QTD1
					_nQtde2		:= (_cAliasU)->QTD2
					_cUm1		:= (_cAliasU)->UM1
					_cUm2		:= (_cAliasU)->UM2
					
					If (_cAliasU)->QTD1 > 0
					
						_nVlrUni := (_cAliasU)->VLRLIQ / (_cAliasU)->QTD1
						_nVlrNet := (_cAliasU)->VLRNET / (_cAliasU)->QTD1
						
					ElseIf (_cAliasU)->QTD2 > 0
					
						_nVlrUni := (_cAliasU)->VLRLIQ / (_cAliasU)->QTD2
						_nVlrNet := (_cAliasU)->VLRNET / (_cAliasU)->QTD2
					
					EndIf
					
				EndIf
				
				_cTxtHTM += '  <TR>'
				_cTxtHTM += '    <TD width="33%" class="itens">' + _cDesSub + '</TD>'
				_cTxtHTM += '    <TD width="12%" class="itens" align="right" >'+ Transform( _nQtde1				, "@E 999,999,999,999.99"	) +'</TD>'
				_cTxtHTM += '    <TD width="04%" class="itens" align="center">'+ _cUm1 +'</TD>'
				_cTxtHTM += '    <TD width="12%" class="itens" align="right" >'+ Transform( _nQtde2				, "@E 999,999,999,999.99"	) +'</TD>'
				_cTxtHTM += '    <TD width="04%" class="itens" align="center">'+ _cUm2 +'</TD>'
				_cTxtHTM += '    <TD width="10%" class="itens" align="right" >'+ Transform( _nVlrNet			, "@E 999,999,999,999.9999"	) +'</TD>'
				_cTxtHTM += '    <TD width="10%" class="itens" align="right" >'+ Transform( _nVlrUni			, "@E 999,999,999,999.9999"	) +'</TD>'
				_cTxtHTM += '    <TD width="10%" class="itens" align="right" >'+ Transform( (_cAliasU)->VLRLIQ	, "@E 999,999,999,999.99"	) +'</TD>'
				_cTxtHTM += '    <TD width="05%" class="itens" align="right" >'+ Transform( _nPorcent			, "@E 999.99"				) +'</TD>'
				_cTxtHTM += '  </TR>'
				
			(_cAliasU)->( DBSkip() )
			EndDo
			
			//====================================================================================================
			// Finaliza a tabela anterior da secao
			//====================================================================================================
			_cTxtHTM += '</TABLE>'
			_cTxtHTM += '<br>'

		Else
		
			_lRet := .F.
			u_itconout( '[MOMS018]['+ DToC(Date()) +" - "+ Time() +'] - Filial: '+ (_cAliasU)->FILIAL +' nao encontrado para pegar a descricao e valor total da Filial' )
		
		EndIf
		
	EndIf

	//====================================================================================================
	// Finaliza a area criada anteriormente.
	//====================================================================================================
	(_cAliasU)->( DBCloseArea() )

EndIf

//====================================================================================================
// Finaliza o HTML.
//====================================================================================================
_cTxtHTM += '</BODY>'
_cTxtHTM += '</HTML>'   

//====================================================================================================
// Caso nao tenha gerado erra na montagem do arquivo html gera o arquivo para enviar via e-mail.
//====================================================================================================
If _lRet

	//====================================================================================================
	// Cria o arquivo HTML na pasta spool da raiz do server.
	//====================================================================================================
	_cArqHtm	:= _cArqAnx
	_nHdl		:= FCreate( _cArqHtm )
	
	If _nHdl == -1
	
		u_itconout( '[MOMS018]['+ DToC(Date()) +" - "+ Time() +'] - O arquivo de resumo de vendas nome '+ _cArqHtm +' nao pode ser criado!' )
		_lRet := .F.
		
	EndIf
	
	FWrite( _nHdl , _cTxtHTM )
	FClose( _nHdl )
	
	//====================================================================================================
	// Caso nao tenho ocorrido erro na geracao do arquivo, envia e-mail contendo o resumo em HTML
	//====================================================================================================
	If _lRet
	
       	_cMsgEml := "<B>Senhor Diretor<BR><BR>" 
		//_cMsgEml += "Segue em anexo relatório enviado diariamente as 23:00 hrs com a Relação de Vendas do Grupo ITALAC para acompanhamento.<BR><BR>"
		_cMsgEml += "Segue em anexo relatório enviado diariamente com a Relação de Vendas do Grupo ITALAC para acompanhamento.<BR><BR>"
		_cMsgEml += "Favor não responder a este e-mail.</B><BR><BR>" + _cTxtHTM
		
		If !Empty( _cEmail )

     		_cEmlLog := ''
			
			u_itconout( '[MOMS018]['+ DToC(Date()) +" - "+ Time() +'] - Processando o envio do e-mail: '+ _cEmail )
			U_ITENVMAIL( _aConfig[01] , _cEmail ,,, If(_lRDiario,'Resumo diario','Resumo')+' de vendas - Italac ['+ DToC(Date()) +']' , _cMsgEml , _cArqAnx , _aConfig[01] , _aConfig[02] , _aConfig[03] , _aConfig[04] , _aConfig[05] , _aConfig[06] , _aConfig[07] , @_cEmlLog ) 
			
			If !Empty( _cEmlLog )
				u_itconout( '[MOMS018]['+ DToC(Date()) +" - "+ Time() +'] - Status do envio de e-mail: '+ _cEmlLog )
			EndIf
		
		EndIf
		
		//====================================================================================================
		// Remove o arquivo HTML criado posteriormente a finalizacao da tarefa de envio de e-mail.
		//====================================================================================================
		If FERASE(_cArqAnx) == -1
		   u_itconout( '[MOMS018]['+ DToC(Date()) +" - "+ Time() +'] - Falha na exclusão do Arquivo HTML do FONTE MOMS018' )
		EndIf
	
	EndIf

EndIf

Return

/*
===============================================================================================================================
Programa----------: MOMS018FIL
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 13/09/2011
===============================================================================================================================
Descrição---------: Processa os dados da relação de Valor Líquido por Unidade
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS018FIL(_lRDiario)

Local _cAlias   := GetNextAlias() 

Local _nTotalLiq:= 0
Local _nPorcent := 0                
Local _aDados   := {}

Default _lRDiario := .F.

//====================================================================================================
// Query para realizar o consulta do faturamento liquido por unidade desconsiderando as devolucoes
//====================================================================================================
MOMS018QRY( 1 , _cAlias,_lRDiario )

//====================================================================================================
// Efetua inicialmente o somatorio geral do valor liquido para posterior averiguacao da porcentagem 
// de participacao de cada filial com relacao ao valo total liquido.
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
	
	aAdd( _aDados , {	(_cAlias)->FILIAL	,; //Codigo da Filial
						(_cAlias)->DESCFIL	,; //Descricao da Filial
						(_cAlias)->VLRBRUT	,; //Valor bruto da Filial corrente
						 _nPorcent			,; //Porcentagem de participacao da filial corrente com relacao ao valor total liquido calculo anteriormente	
						 _nTotalLiq			}) //Valor total liquido geral, armazenado para uso posterior em outras secoes do HTML

(_cAlias)->( DBSkip() )
EndDo

//====================================================================================================
// Finaliza o alias criado anteriormente.
//====================================================================================================
(_cAlias)->( DBCloseArea() )

Return( _aDados )

/*
===============================================================================================================================
Programa----------: MOMS018QRY
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 13/09/2011
===============================================================================================================================
Descrição---------: Rotina que busca os dados do relatório e monta as áreas temporárias
===============================================================================================================================
Parametros--------: _nOpcao	- consulta a ser executada
------------------: _cAlias - Alias da área temporária a ser criada
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS018QRY( _nOpcao , _cAlias , _lRDiario )

Local _cCfops	:= U_ITCFOPS( 'V' ) //Somente considera CFOP de vendas
Local _cFiltro	:= "% "

Local _sDtInic	:= DToS( FirstDay( Date() ) )
Local _sDtFinal	:= DToS( LastDay(  Date() ) )

Default _lRDiario := .F.

If ValType( _lRDiario) # "L"
	_lRDiario := .F.
EndIf

If _lRDiario
   _sDtInic  := DToS(Date()-1) 
   _sDtFinal := _sDtInic  
EndIf

_cFiltro += " AND F2.F2_EMISSAO BETWEEN '" + _sDtInic + "' AND '" + _sDtFinal + "'"	
_cFiltro += " AND D2.D2_CF      IN     "+ FormatIn( _cCfops	, ";" )
_cFiltro += " AND D2.D2_TIPO    NOT IN "+ FormatIn( 'I;P'	, ";" )
_cFiltro += " %"

Do Case

	//====================================================================================================
	// Query para realizar o consulta do faturamento liquido por unidade desconsiderando as devolucoes
	//====================================================================================================
	Case _nOpcao == 1
	
		BeginSql alias _cAlias
		
			SELECT
				DADOS.F2_FILIAL AS FILIAL,
				(	SELECT
						ZZM.ZZM_DESCRI
					FROM %Table:ZZM% ZZM
					WHERE
						ZZM.%NotDel%
					AND ZZM.ZZM_CODIGO = DADOS.F2_FILIAL ) AS DESCFIL,
			    SUM(DADOS.VLBRUT) AS VLRBRUT
			FROM
				(	SELECT 
				    	F2.F2_FILIAL,
				    	COALESCE( SUM( D2.D2_VALBRUT - RESULTD1.VLRBRUT ) , 0 ) VLBRUT
					FROM %Table:SF2% F2
					JOIN %Table:SD2% D2
					ON  F2.F2_FILIAL     = D2.D2_FILIAL
					AND F2.F2_DOC        = D2.D2_DOC
					AND F2.F2_SERIE      = D2.D2_SERIE
					AND F2.F2_CLIENTE    = D2.D2_CLIENTE
					AND F2.F2_LOJA       = D2.D2_LOJA
					JOIN %Table:SB1% B1
					ON B1.B1_COD = D2.D2_COD ,
					(	SELECT
							D1.D1_FILIAL                           ,
							D1.D1_NFORI                            ,
							D1.D1_SERIORI                          ,
							D1.D1_FORNECE                          ,
							D1.D1_LOJA                             ,
							D1.D1_COD                              ,
							COALESCE( SUM( D1.D1_TOTAL + D1.D1_ICMSRET ) , 0 ) VLRBRUT
					  	FROM %Table:SD1% D1
						WHERE D1.D_E_L_E_T_ = ' '
						AND D1.D1_TIPO      = 'D'
						AND D1.D1_TES      <> ' '
						GROUP BY D1.D1_FILIAL , D1.D1_NFORI , D1.D1_SERIORI , D1.D1_FORNECE , D1.D1_LOJA , D1.D1_COD ) RESULTD1
				WHERE
					F2.D_E_L_E_T_       = ' '
				AND D2.D_E_L_E_T_       = ' '
				AND B1.D_E_L_E_T_       = ' '
				AND RESULTD1.D1_FILIAL  = D2.D2_FILIAL
				AND RESULTD1.D1_NFORI   = D2.D2_DOC
				AND RESULTD1.D1_SERIORI = D2.D2_SERIE
				AND RESULTD1.D1_FORNECE = D2.D2_CLIENTE
				AND RESULTD1.D1_LOJA    = D2.D2_LOJA
				AND RESULTD1.D1_COD     = D2.D2_COD
				%Exp:_cFiltro%
				GROUP BY F2.F2_FILIAL
				
				UNION ALL
				
				SELECT 
					F2.F2_FILIAL ,
					SUM(D2.D2_VALBRUT) VLBRUT
				FROM %Table:SF2% F2
				JOIN %Table:SD2% D2
				ON  F2.F2_FILIAL     = D2.D2_FILIAL
				AND F2.F2_DOC        = D2.D2_DOC
				AND F2.F2_SERIE      = D2.D2_SERIE
				AND F2.F2_CLIENTE    = D2.D2_CLIENTE
				AND F2.F2_LOJA       = D2.D2_LOJA
				JOIN %Table:SB1% B1
				ON B1.B1_COD     = D2.D2_COD
				WHERE F2.D_E_L_E_T_ = ' '
				AND D2.D_E_L_E_T_     = ' '
				AND B1.D_E_L_E_T_     = ' '
				%Exp:_cFiltro%
				AND NOT EXISTS (	SELECT 1
									FROM %Table:SD1% D1
									WHERE D1.D_E_L_E_T_ = ' '
									AND D1.D1_TIPO      = 'D'
									AND D1.D1_TES      <> ' '
									AND D1.D1_FILIAL    = D2.D2_FILIAL
									AND D1.D1_NFORI     = D2.D2_DOC
									AND D1.D1_SERIORI   = D2.D2_SERIE
									AND D1.D1_FORNECE   = D2.D2_CLIENTE
									AND D1.D1_LOJA      = D2.D2_LOJA
									AND D1.D1_COD       = D2.D2_COD )
				GROUP BY F2.F2_FILIAL ) DADOS
				
			GROUP BY DADOS.F2_FILIAL
			
			HAVING SUM( DADOS.VLBRUT ) > 0
			
			ORDER BY DADOS.F2_FILIAL
				
		EndSql
	        
	//====================================================================================================
	// Query para realizar o consulta do faturamento liquido por unidade x sub-grupo de produtos
	//====================================================================================================
	Case _nOpcao == 2 
	
		BeginSql alias _cAlias
		
			SELECT
				DADOS.B1_I_SUBGR AS CODSUB,
				(	SELECT ZB9.ZB9_DESSUB
					FROM %Table:ZB9% ZB9
					WHERE ZB9.D_E_L_E_T_ = ' '
					AND ZB9.ZB9_SUBGRU = DADOS.B1_I_SUBGR ) AS DESCSUB,
			    MAX( DADOS.D2_UM    ) AS UM1,
			    MAX( DADOS.D2_SEGUM ) AS UM2,
			    SUM( DADOS.QTD1     ) AS QTD1,
			    SUM( DADOS.QTD2     ) AS QTD2,
			    SUM( DADOS.VLBRUT   ) AS VLRLIQ,
				SUM( DADOS.VLNET    ) AS VLRNET
			FROM
				(	SELECT 
						B1.B1_I_SUBGR,
						D2.D2_UM,
						D2.D2_SEGUM,
						COALESCE( SUM( D2.D2_QUANT   - RESULTD1.QUANT1UM ) , 0 ) QTD1,
						COALESCE( SUM( D2.D2_QTSEGUM - RESULTD1.QUANT2UM ) , 0 ) QTD2,
						COALESCE( SUM( D2.D2_VALBRUT - RESULTD1.VLRBRUT  ) , 0 ) VLBRUT,
						COALESCE( SUM( ( D2.D2_TOTAL - RESULTD1.VLRTOT   ) - ( ( D2.D2_VALBRUT - RESULTD1.VLRBRUT ) * ( D2_I_PRCDC / 100 ) ) ) , 0 ) VLNET
					FROM %Table:SF2% F2
					JOIN %Table:SD2% D2
					ON  F2.F2_FILIAL  = D2.D2_FILIAL
					AND F2.F2_DOC     = D2.D2_DOC
					AND F2.F2_SERIE   = D2.D2_SERIE
					AND F2.F2_CLIENTE = D2.D2_CLIENTE
					AND F2.F2_LOJA    = D2.D2_LOJA
					JOIN %Table:SB1% B1
					ON B1.B1_COD = D2.D2_COD ,
					(	SELECT
							D1.D1_FILIAL,
							D1.D1_NFORI,
							D1.D1_SERIORI,
							D1.D1_FORNECE,
							D1.D1_LOJA,
							D1.D1_COD,
							COALESCE(SUM(D1.D1_QUANT),0) QUANT1UM,
							COALESCE(SUM(D1.D1_QTSEGUM),0) QUANT2UM,
							COALESCE(SUM(D1.D1_TOTAL + D1.D1_ICMSRET),0) VLRBRUT,
							COALESCE(SUM(D1.D1_TOTAL),0) VLRTOT
						FROM %Table:SD1% D1
						WHERE
							D1.D_E_L_E_T_ = ' '
						AND D1.D1_TIPO    = 'D'
						AND D1.D1_TES    <> ' '
						GROUP BY D1.D1_FILIAL , D1.D1_NFORI , D1.D1_SERIORI , D1.D1_FORNECE , D1.D1_LOJA , D1.D1_COD ) RESULTD1
			    	WHERE
						F2.D_E_L_E_T_       = ' '
					AND D2.D_E_L_E_T_       = ' '
					AND B1.D_E_L_E_T_       = ' '
					AND RESULTD1.D1_FILIAL  = D2.D2_FILIAL
					AND RESULTD1.D1_NFORI   = D2.D2_DOC
					AND RESULTD1.D1_SERIORI = D2.D2_SERIE
					AND RESULTD1.D1_FORNECE = D2.D2_CLIENTE
					AND RESULTD1.D1_LOJA    = D2.D2_LOJA
					AND RESULTD1.D1_COD     = D2.D2_COD  
					%Exp:_cFiltro%
					GROUP BY B1.B1_I_SUBGR , D2.D2_UM , D2.D2_SEGUM
					HAVING SUM( D2.D2_QUANT - RESULTD1.QUANT1UM ) > 0 OR SUM( D2.D2_QTSEGUM - RESULTD1.QUANT2UM ) > 0
					
					UNION ALL
					
					SELECT 
						B1.B1_I_SUBGR,
						D2.D2_UM,
						D2.D2_SEGUM,
						SUM( D2.D2_QUANT ) QTD1,
						SUM( D2.D2_QTSEGUM ) QTD2,
						SUM( D2.D2_VALBRUT ) VLBRUT,
						SUM( D2.D2_TOTAL - D2.D2_I_VLRDC ) VLNET
					FROM %Table:SF2% F2
					JOIN %Table:SD2% D2
					ON F2.F2_FILIAL     = D2.D2_FILIAL
					AND F2.F2_DOC       = D2.D2_DOC
					AND F2.F2_SERIE     = D2.D2_SERIE
					AND F2.F2_CLIENTE   = D2.D2_CLIENTE
					AND F2.F2_LOJA      = D2.D2_LOJA
					JOIN %Table:SB1% B1
					ON B1.B1_COD        = D2.D2_COD
					WHERE F2.D_E_L_E_T_ = ' '
					AND D2.D_E_L_E_T_   = ' '
					AND B1.D_E_L_E_T_   = ' '
					%Exp:_cFiltro%
					AND NOT EXISTS (	SELECT 1
										FROM %Table:SD1% D1
										WHERE D1.D_E_L_E_T_ = ' '
										AND D1.D1_TIPO      = 'D'
										AND D1.D1_TES      <> ' '
										AND D1.D1_FILIAL    = D2.D2_FILIAL
										AND D1.D1_NFORI     = D2.D2_DOC
										AND D1.D1_SERIORI   = D2.D2_SERIE
										AND D1.D1_FORNECE   = D2.D2_CLIENTE
										AND D1.D1_LOJA      = D2.D2_LOJA
										AND D1.D1_COD       = D2.D2_COD )
					GROUP BY B1.B1_I_SUBGR , D2.D2_UM , D2.D2_SEGUM ) DADOS
					
			GROUP BY DADOS.B1_I_SUBGR
			
			ORDER BY DADOS.B1_I_SUBGR
			
		EndSql
			
	//====================================================================================================
	// Query para realizar o consulta do faturamento liquido por unidade x sub-grupo x Filial de produtos
	//====================================================================================================
	Case _nOpcao == 3
	
		BeginSql alias _cAlias
		
			SELECT
				DADOS.F2_FILIAL		AS FILIAL,
				DADOS.B1_I_SUBGR	AS CODSUB,
				(	SELECT ZB9.ZB9_DESSUB
					FROM %Table:ZB9% ZB9
					WHERE ZB9.D_E_L_E_T_ = ' '
					AND   ZB9.ZB9_SUBGRU = DADOS.B1_I_SUBGR ) AS DESCSUB,
				MAX(DADOS.D2_UM)	AS UM1,
				MAX(DADOS.D2_SEGUM)	AS UM2,
				SUM(DADOS.QTD1)		AS QTD1,
				SUM(DADOS.QTD2)		AS QTD2,
				SUM(DADOS.VLBRUT)	AS VLRLIQ,
				SUM(DADOS.VLNET)	AS VLRNET
			FROM (	SELECT
						F2.F2_FILIAL,
						B1.B1_I_SUBGR,
						D2.D2_UM,
						D2.D2_SEGUM,
						COALESCE( SUM( D2.D2_QUANT   - RESULTD1.QUANT1UM) , 0 ) QTD1,
						COALESCE( SUM( D2.D2_QTSEGUM - RESULTD1.QUANT2UM) , 0 ) QTD2,
						COALESCE( SUM( D2.D2_VALBRUT - RESULTD1.VLRBRUT ) , 0 ) VLBRUT,
						COALESCE( SUM( ( D2.D2_TOTAL - RESULTD1.VLRTOT  ) - ( ( D2.D2_VALBRUT - RESULTD1.VLRBRUT ) * ( D2_I_PRCDC / 100 ) ) ) , 0 ) VLNET
					FROM %Table:SF2% F2
					
					JOIN %Table:SD2% D2
					ON  F2.F2_FILIAL  = D2.D2_FILIAL
					AND F2.F2_DOC     = D2.D2_DOC
					AND F2.F2_SERIE   = D2.D2_SERIE
					AND F2.F2_CLIENTE = D2.D2_CLIENTE
					AND F2.F2_LOJA    = D2.D2_LOJA
					
					JOIN %Table:SB1% B1 ON B1.B1_COD = D2.D2_COD ,
					
					(	SELECT
							D1.D1_FILIAL,
							D1.D1_NFORI,
							D1.D1_SERIORI,
							D1.D1_FORNECE,
							D1.D1_LOJA,
							D1.D1_COD,
							COALESCE( SUM( D1.D1_QUANT ) , 0 ) QUANT1UM,
							COALESCE( SUM( D1.D1_QTSEGUM ) , 0 ) QUANT2UM,
							COALESCE( SUM( D1.D1_TOTAL + D1.D1_ICMSRET ) , 0 ) VLRBRUT,
							COALESCE( SUM( D1.D1_TOTAL ) , 0 ) VLRTOT
						FROM %Table:SD1% D1
						WHERE	D1.D_E_L_E_T_ = ' '
						AND		D1.D1_TIPO    = 'D'
						AND D1.D1_TES        <> ' '
						
						GROUP BY D1.D1_FILIAL , D1.D1_NFORI , D1.D1_SERIORI , D1.D1_FORNECE , D1.D1_LOJA , D1.D1_COD ) RESULTD1
					
					WHERE 
						F2.D_E_L_E_T_       = ' '
					AND D2.D_E_L_E_T_       = ' '
					AND B1.D_E_L_E_T_       = ' '
					AND RESULTD1.D1_FILIAL  = D2.D2_FILIAL
					AND RESULTD1.D1_NFORI   = D2.D2_DOC
					AND RESULTD1.D1_SERIORI = D2.D2_SERIE
					AND RESULTD1.D1_FORNECE = D2.D2_CLIENTE
					AND RESULTD1.D1_LOJA    = D2.D2_LOJA
					AND RESULTD1.D1_COD     = D2.D2_COD  
					
					%Exp:_cFiltro%
					
					GROUP BY F2.F2_FILIAL , B1.B1_I_SUBGR , D2.D2_UM , D2.D2_SEGUM
					
					HAVING SUM( D2.D2_QUANT - RESULTD1.QUANT1UM ) > 0 OR SUM( D2.D2_QTSEGUM - RESULTD1.QUANT2UM ) > 0
					
					UNION ALL
					
					SELECT 
						F2.F2_FILIAL,
						B1.B1_I_SUBGR,
						D2.D2_UM,
						D2.D2_SEGUM,
						SUM(D2.D2_QUANT  ) QTD1,
						SUM(D2.D2_QTSEGUM) QTD2,
						SUM(D2.D2_VALBRUT) VLBRUT,
						SUM(D2.D2_TOTAL - D2.D2_I_VLRDC) VLNET
					FROM %Table:SF2% F2
					
					JOIN %Table:SD2% D2
					ON F2.F2_FILIAL      = D2.D2_FILIAL
					AND F2.F2_DOC        = D2.D2_DOC
					AND F2.F2_SERIE      = D2.D2_SERIE
					AND F2.F2_CLIENTE    = D2.D2_CLIENTE
					AND F2.F2_LOJA       = D2.D2_LOJA
					
					JOIN %Table:SB1% B1 ON B1.B1_COD     = D2.D2_COD
					
				    WHERE
				    	F2.D_E_L_E_T_ = ' '
					AND D2.D_E_L_E_T_ = ' '
					AND B1.D_E_L_E_T_ = ' '
					
					%Exp:_cFiltro%
					
					AND NOT EXISTS (	SELECT 1
										FROM %Table:SD1% D1
										WHERE	D1.D_E_L_E_T_ = ' '
										AND		D1.D1_TIPO    = 'D'
										AND		D1.D1_TES    <> ' '
										AND		D1.D1_FILIAL  = D2.D2_FILIAL
										AND		D1.D1_NFORI   = D2.D2_DOC
										AND		D1.D1_SERIORI = D2.D2_SERIE
										AND		D1.D1_FORNECE = D2.D2_CLIENTE
										AND		D1.D1_LOJA    = D2.D2_LOJA
										AND		D1.D1_COD     = D2.D2_COD )
					
					GROUP BY F2.F2_FILIAL , B1.B1_I_SUBGR , D2.D2_UM , D2.D2_SEGUM ) DADOS
					
			GROUP BY DADOS.F2_FILIAL , DADOS.B1_I_SUBGR
			ORDER BY DADOS.F2_FILIAL , DADOS.B1_I_SUBGR
			
		EndSql					
	                 
	//====================================================================================================
	// Query para selecionar os e-mail's dos usuarios que sera enviado o resumo do HTML
	//====================================================================================================
	Case _nOpcao == 4
	
   		BeginSql alias _cAlias
   		
			SELECT ZZL_EMAIL
			FROM   %Table:ZZL%
			WHERE  D_E_L_E_T_ = ' ' AND ZZL_ENVRES = 'S'
			
		EndSql

EndCase

Return


/*
===============================================================================================================================
Programa----------: MOMS018D
Autor-------------: Igor Melgaço
Data da Criacao---: 30/11/2023
===============================================================================================================================
Descrição---------: Executa o Resumo do faturamento líquido diário
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS018D()
	U_MOMS018(.T.)
Return
