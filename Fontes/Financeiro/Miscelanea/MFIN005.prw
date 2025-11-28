/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |10/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25.
Julio Paz     |06/01/2023| Chamado 42025. Realização de alterações: leitura/exibição dos dados.Ajustar p/ler ultimos 5 anos.
Lucas Borges  |13/10/2024| Chamado 48465. Retirada da função de conout
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: MFIN005
Autor-----------: Tiago Correa
Data da Criacao-: 03/01/2012
Descrição-------: Funcao desenvolvida para o envio do relatorio de Fluxo de Caixa diario apartir do dia corrente do mes.
----------------: Este relatorio em HTML sera enviado para pessoas que possuam cadastro de envio de e-mail Workflow (ZZL).
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function MFIN005()

Local aTables    := { "SE1" , "ZZL" }
Local _cAlias    := ""
Local _cEmails   := ""

Local _lCriaAmb  := .F.

//====================================================================================================
// Verifica a necessidade de criar um ambiente, caso o ambiente não esteja aberto
//====================================================================================================
_lCriaAmb := ( Select("SX3") <= 0 )

If _lCriaAmb

	RPCSetType(3)											//Nao consome licensas
	RpcSetEnv("01","01",,,,"SCHEDULE_EMAIL_RESUMO",aTables)	//seta o ambiente com a empresa 01 filial 01
	sleep( 5000 )											// aguarda 5 segundos para que as jobs IPC subam.
	
	FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MFIN005"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MFIN00501"/*cMsgId*/, "MFIN00502 - Gerando envio do arquivo HTML de Fluxo de Caixa."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

EndIf
	
//====================================================================================================
// Verifica inicialmente para quais usuarios o resumo sera enviado.
//====================================================================================================
_cAlias := GetNextAlias()

MFIN005QRY( 1 , _cAlias )

DBSelectArea(_cAlias)
(_cAlias)->( DBGoTop() )
While (_cAlias)->( !Eof() )

	_cEmails += ";" + AllTrim( (_cAlias)->ZZL_EMAIL )

(_cAlias)->( DBSkip() )
EndDo

(_cAlias)->( DBCloseArea() )

//====================================================================================================
// Devera existir no minimo um e-mail para que a rotina processo a montagem e envio do arquivo
//====================================================================================================
If !Empty(_cEmails)

	_cEmails := SubStr( _cEmails , 2 )
	
	MFIN005RUN(_cEmails)
	
EndIf
//====================================================================================================
// Limpa o ambiente, liberando a licença e fechando as conexões
//====================================================================================================
If _lCriaAmb
    
	RpcClearEnv()
	FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MFIN005"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MFIN00502"/*cMsgId*/, "MFIN00502 - Termino de execucao normal do envio do HTML de Fluxo de Caixa"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

EndIf

Return

/*
===============================================================================================================================
Programa--------: MFIN005RUN
Autor-----------: Tiago Correa
Data da Criacao-: 03/01/2012
Descrição-------: Funcao que gera o relatório em HTML e chama o envio de e-mail para os usuários cadastrados
Parametros------: Nenhum
Retorno---------: _cEmailDes = e-mails de envio da mensagem.
===============================================================================================================================
*/
Static Function MFIN005RUN(_cEmailDes)

Local _horario		:= StrTran(Time(),":","'")				//Nao se pode gerar um arquivo com o nome que contenha o caracter ":"
Local _cArqAnexo	:= "\spool\fluxo" + _horario + ".HTM"	//Nome do arquivo anexo a ser enviado ao usuario
Local _cArqHtml		:= ''
Local _nHdl			:= 0
Local _cTextHTML	:= ""
Local _lRet			:= .T.
Local _cAliasTot	:= ""
Local _cAlias		:= ""
Local _cAliasVenc	:= ""
Local _cMsgEmail	:= ""
Local _cGeracao		:= DToC( Date() )
Local _nTSaldPer	:= 0
Local _nTotSald		:= 0
Local _nVenc15		:= 0
Local _nVencDuv		:= 0
Local _nTC			:= 0
Local _aConfig	  := U_ITCFGEML('')
Local _cDescri      := ""

//====================================================================================================
// Define o cabecalho do HTML.
//====================================================================================================
_cTextHTML += '<!DOCTYPE HTML Public "-//W3C//DTD HTML 4.0 Transitional//EN">'
_cTextHTML += '<HTML><HEAD><TITLE>FLUXO DE CAIXA ITALAC - CONTAS A RECEBER</TITLE>'
_cTextHTML += '<META content="text/html; charset=windows-1252" http-equiv=Content-Type>'
_cTextHTML += '<META name=GENERATOR content="MSHTML 8.00.6001.19120"></HEAD>' 

//====================================================================================================
// Define o corpo do HTML.
//====================================================================================================
_cTextHTML += '<BODY>'
_cTextHTML += '<P align=center><FONT color=#388e8e size=5><STRONG>FLUXO DE CAIXA ITALAC - CONTAS A RECEBER<BR></STRONG></FONT></P>'  
_cTextHTML += '<P align=center><FONT color=#388e8e size=5><STRONG>GERADO EM: ' + _cGeracao + ' AS ' + Transform(Time(),"@R 99:99") + '<BR></STRONG></FONT></P>' 

//====================================================================================================
// Define estrutura da primeira secao CONTAS A RECEBER DIARIO
//====================================================================================================
_cTextHTML += '<P align=center>'
_cTextHTML += '<TABLE border=1 cellSpacing=0 borderColor=#000000 cellPadding=0 width="100%">'
_cTextHTML += '<TBODY>'
_cTextHTML += '<TR>'
_cTextHTML += '<TD align=center><width="5%"><STRONG>DATA</STRONG></TD>'
_cTextHTML += '<TD width="20%"><P align=right><STRONG>VALOR A RECEBER(R$)</STRONG></P></TD>'
_cTextHTML += '<TD width="20%"><P align=right><STRONG>VALOR A PAGAR(R$)  </STRONG></P></TD>'
_cTextHTML += '</TR>'

//====================================================================================================
// Chama funcao para retornar o Total Geral a Vencer - Contas a Receber
//====================================================================================================
_cAliasTot := GetNextAlias()

MFIN005QRY( 2 , _cAliasTot )

DBSelectArea(_cAliasTot)
(_cAliasTot)->( DBGoTop() )

_nTotSald := (_cAliasTot)->TOTALSALDO

(_cAliasTot)->( DBCloseArea() )

MFIN005QRY( 7 , _cAliasTot )

DBSelectArea(_cAliasTot)
(_cAliasTot)->( DBGoTop() )

_nTotSald := _nTotSald - (_cAliasTot)->TOTAL_NCC

(_cAliasTot)->( DBCloseArea() )

//====================================================================================================
// Imprime totalizador.
//====================================================================================================
_cTextHTML += '<TR>'
_cTextHTML += '<TD width="5%"><FONT COLOR="#ff0000"><STRONG>TOTAL GERAL</FONT></TD>'
_cTextHTML += '<TD width="20%"><P align=right><STRONG><FONT COLOR="#ff0000">' + Transform(_nTotSald,"@E 999,999,999,999.99") + '</FONT></STRONG></P></TD>'
_cTextHTML += '<TD width="20%"><P align=right><STRONG><FONT COLOR="#ff0000">' + Transform(000,"@E 999,999,999,999.99") + '</FONT></STRONG></P></TD>'
_cTextHTML += '</TR>' 	                         	

//====================================================================================================
// Chama funcao para retornar o Total a Vencer por Dia - Contas a Receber
//====================================================================================================
_cAlias := GetNextAlias()

MFIN005QRY( 3 , _cAlias )

//====================================================================================================
// Insere os dados de todas as filiais encontradas na consulta
//====================================================================================================
DBSelectArea(_cAlias)
(_cAlias)->( DBGoTop() )
While (_cAlias)->( !Eof() )
    
	_nTSaldPer	:=	0
	_dUltDia	:=	DToS( LastDay( SToD( (_cAlias)->E1_VENCREA ) ) )
	
	While (_cAlias)->( !Eof() ) .And. (_cAlias)->E1_VENCREA <= _dUltDia
	
		_nTSaldPer	:= _nTSaldPer + (_cAlias)->SALDO
		_dData		:= DToC( SToD( (_cAlias)->E1_VENCREA ) )
		
		_cTextHTML += '<TR>'
		_cTextHTML += '<TD width="5%"><P align=right>'+  _dData													+'</P></TD>'
		_cTextHTML += '<TD width="20%"><P align=right>'+ Transform((_cAlias)->SALDO,"@E 999,999,999,999.99")	+'</P></TD>'
		_cTextHTML += '<TD width="20%"><P align=right>'+ Transform(000,"@E 999,999,999,999.99")					+'</P></TD>'
		_cTextHTML += '</TR>'
		
	(_cAlias)->( DBSkip() )
	EndDo
	
	//====================================================================================================
	// Imprime total do mes
	//====================================================================================================
	_cTextHTML += '<TR>'
	_cTextHTML += '<TD width="5%"><FONT COLOR="#ff0000"><STRONG>Total Período</FONT></TD>'
	_cTextHTML += '<TD width="20%"><P align=right><STRONG><FONT COLOR="#ff0000">'+ Transform( _nTSaldPer , "@E 999,999,999,999.99" ) +'</FONT></STRONG></P></TD>'
	_cTextHTML += '<TD width="20%"><P align=right><STRONG><FONT COLOR="#ff0000">'+ Transform( 000        , "@E 999,999,999,999.99" ) +'</FONT></STRONG></P></TD>'
	_cTextHTML += '</TR>'

EndDo
	
(_cAlias)->( DBCloseArea() )

//====================================================================================================
// Finaliza a tabela da secao CONTAS A RECEBER DIARIO
//====================================================================================================
_cTextHTML += '</TBODY>'
_cTextHTML += '</TABLE>'
_cTextHTML += '</P>'

//====================================================================================================
// Define a estrutura da segunda secao Posicao de Estoque
//====================================================================================================
_cTextHTML += '<P align=center>&nbsp;</P>'
_cTextHTML += '<P align=center><FONT color=#388e8e size=5><STRONG><U>POSIÇÃO - CONTAS A RECEBER</U><BR></STRONG></P>'
_cTextHTML += '<P align=center>'
_cTextHTML += '<TABLE border=1 cellSpacing=0 borderColor=#000000 cellPadding=0 width="100%">'
_cTextHTML += '<TBODY>'
_cTextHTML += '<TR>'
_cTextHTML += '<TD align=left><width="30%"><STRONG>TIPO</STRONG></TD>'
_cTextHTML += '<TD width="70%"><P align=right><STRONG>VALOR(R$)</STRONG></P></TD>'
_cTextHTML += '</TR>'

//====================================================================================================
// Chama funcao para retornar as informacoes do quadro Posicao - Contas a Receber Vencidos
//====================================================================================================

_cAliasVenc := GetNextAlias()

MFIN005QRY( 5 , _cAliasVenc )

DBSelectArea(_cAliasVenc)
(_cAliasVenc)->( DBGoTop() )
While (_cAliasVenc)->( !Eof() )

	If (_cAliasVenc)->COD_CART = ' '
	
		_nVenc15	:= (_cAliasVenc)->VENC_15
		_nVencDuv	:= (_cAliasVenc)->VENC_DUV
		
		//====================================================================================================
		// Define a secao titulos vencidos ate 15 dias
		//====================================================================================================
		_cTextHTML += '<TR>'
		_cTextHTML += '<TD width="30%"><P align=left> TITULOS VENCIDOS A RECEBER (VENCIDOS ATÉ 15 DIAS)</P></TD>'
		_cTextHTML += '<TD width="70%"><P align=right><FONT COLOR="#ff0000">'+ Transform( _nVenc15 , "@E 999,999,999,999.99" ) +'</FONT></P></TD>'
		_cTextHTML += '</TR>'
	
	ElseIf (_cAliasVenc)->COD_CART <> ' '
		
		_nTC := _nTC + (_cAliasVenc)->CART_COB
		
        _cDescri :=  (_cAliasVenc)->TIPO_CART

		If AllTrim((_cAliasVenc)->COD_CART) == "17" // Prorrogações 
           _cDescri := "TITULOS VENCIDOS A RECEBER"
		EndIf 

		_cTextHTML += '<TR>'
		_cTextHTML += '<TD width="30%"><P align=left>'+ _cDescri +'</P></TD>' // '<TD width="30%"><P align=left>'+ (_cAliasVenc)->TIPO_CART +'</P></TD>'
		_cTextHTML += '<TD width="70%"><P align=right><FONT COLOR="#ff0000">'+ Transform( (_cAliasVenc)->CART_COB , "@E 999,999,999,999.99" ) +'</FONT></P></TD>'
		_cTextHTML += '</TR>'
		
	EndIf
	
(_cAliasVenc)->( DBSkip() )
EndDo

(_cAliasVenc)->( DBCloseArea() )

/* // Remover do relatório - Chamado 42025
_cTextHTML += '<TR>'
_cTextHTML += '<TD width="30%"><P align=left>DUVIDOSOS (VENCIDOS ACIMA DE 15 DIAS)</P></TD>'
_cTextHTML += '<TD width="70%"><P align=right><FONT COLOR="#ff0000">'+ Transform( _nVencDuv , "@E 999,999,999,999.99" ) +'</FONT></P></TD>'
_cTextHTML += '</TR>'
*/ 


//====================================================================================================
// Imprime totalizador.
//====================================================================================================
_cTextHTML += '<TR>'
_cTextHTML += '<TD width="30%"><STRONG><FONT COLOR="#ff0000">TOTAL</FONT></STRONG></TD>'
_cTextHTML += '<TD width="70%"><P align=right><STRONG><FONT COLOR="#ff0000">'+ Transform( _nVenc15 + _nTC + _nVencDuv , "@E 999,999,999,999.99" ) +'</FONT></STRONG></P></TD>'
_cTextHTML += '</TR>'

//====================================================================================================
// Finaliza a tabela da 2 secao POSICAO CONTAS A RECEBER
//====================================================================================================
_cTextHTML += '</TBODY>'
_cTextHTML += '</TABLE>'
_cTextHTML += '</P>'

//====================================================================================================
// Finaliza o HTML.
//====================================================================================================
_cTextHTML += '</BODY>'
_cTextHTML += '</HTML>'

//====================================================================================================
// Caso nao tenha gerado erro na montagem do arquivo gera o arquivo para posterior envio via e-mail.
//====================================================================================================
If _lRet

	//====================================================================================================
	// Cria o arquivo HTML na pasta spool da raiz do server.
	//====================================================================================================
	_cArqHtml	:= _cArqAnexo
	_nHdl		:= FCreate(_cArqHtml)
	
	If _nHdl == -1
	
		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MFIN005"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MFIN00501"/*cMsgId*/, "MFIN00502 - Falhou ao criar o arquivo de fluxo de caixa: "+ _cArqHtml/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		_lRet := .F.
	
	Else
	
		FWrite( _nHdl , _cTextHTML , Len(_cTextHTML) )
		
		FClose(_nHdl)
	
	EndIf
		
	//====================================================================================================
	// Caso nao tenho ocorrido erro na geracao do arquivo, sera enviado um e-mail com o reusmo em HTML.
	//====================================================================================================
	If _lRet
	
		_cMsgEmail := "<B>Senhor Diretor<BR><BR>"
		_cMsgEmail += "Segue em anexo relatório enviado diariamente gerado às "+ Transform( Time() , "@R 99:99" ) +" hrs com o Fluxo de Caixa ITALAC - Contas a Receber para acompanhamento.<BR><BR>"
		_cMsgEmail += "Favor não responder a este e-mail.</B><BR><BR>"+ _cTextHTML

		_cEmlLog := ""

		 U_ITENVMAIL( _aConfig[01] , _cEmailDes ,       ,        ,"FLUXO DE CAIXA ITALAC (CONTAS A RECEBER) - GERADO EM: "+ _cGeracao,;
		              _cMsgEmail,_cArqAnexo,_aConfig[01],_aConfig[02], _aConfig[03],_aConfig[04], _aConfig[05], _aConfig[06],;
					_aConfig[07], @_cEmlLog )

		//====================================================================================================
		// Remove o arquivo HTML criado posteriormente a finalizacao da tarefa de envio de e-mail.
		//====================================================================================================
		If FERASE(_cArqAnexo) == -1
			FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MFIN005"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MFIN00504"/*cMsgId*/, "MFIN00504 - Falha na deleção do Arquivo HTML do Fluxo de Caixa"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		EndIf
	
	EndIf

EndIf

Return

/*
===============================================================================================================================
Programa--------: MFIN005QRY
Autor-----------: Tiago Correa
Data da Criacao-: 03/01/2012
Descrição-------: Funcao que realiza as consultas e monta as areas temporarias com os resultados
Parametros------: _nOpcao	- Numero da query a ser processada
----------------: _cAlias	- Nome do alias que deverá ser utilizado para criar a area temporaria
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function MFIN005QRY( _nOpcao , _cAlias )
                            
Local _cFiltro 	:= "%"
Local _cFiltro2 := "%"  
Local _cFiltro3 := "%"

Local _sDtInic := DToS( Date() )

_cFiltro+= " AND E1.E1_VENCREA BETWEEN '" + _sDtInic + "' AND '"+ DToS( Date() + GETMV("IT_QDIASFL") ) +"' "  // VENCIMENTO ENTRE DATA DO DIA E MAIS 60 DIAS
_cFiltro+= "%"

_cFiltro2+= " AND E1.E1_VENCREA < '"+ _sDtInic +"' "  // VENCIMENTOS ATRASADOS, MENOR QUE A DATA ATUAL.
_cFiltro2+= "%"

_cFiltro3+=  _sDtInic
_cFiltro3+= "%"

Do Case

	//====================================================================================================
	// Query para selecionar os e-mail's dos usuarios que sera enviado o resumo do HTML.
	//====================================================================================================
	Case _nOpcao == 1
	
   		BeginSql alias _cAlias
   		
			SELECT	ZZL_EMAIL
			FROM	%Table:ZZL%
			WHERE	D_E_L_E_T_	= ' '
			AND		ZZL_ENVFLU	= 'S'
			
		EndSql
		
	//====================================================================================================
	// Query para realizar o consulta do Fluxo Contas a Receber - Totais
	//====================================================================================================
	Case _nOpcao == 2
	
		BeginSql alias _cAlias
		
			SELECT SUM( E1.E1_SALDO ) AS TOTALSALDO
			FROM	%Table:SE1% E1
			WHERE	E1.D_E_L_E_T_	= ' '
			AND		E1.E1_SALDO		> 0
			AND		E1.E1_TIPO		NOT IN ( 'RA' , 'NCC' )
			%Exp:_cFiltro%
			
		EndSql
	
	//====================================================================================================
	// Query para realizar o consulta do Fluxo Contas a Receber
	//====================================================================================================
	Case _nOpcao == 3
	
		BeginSql alias _cAlias
		
			SELECT 
				E1.E1_VENCREA,
				SUM( ( E1.E1_SALDO + E1.E1_SDACRES ) - E1.E1_SDDECRE ) - NVL( (	SELECT	SUM( ( E11.E1_SALDO + E11.E1_SDACRES ) - E11.E1_SDDECRE )
																				FROM	%Table:SE1% E11
																				WHERE	E11.D_E_L_E_T_	= ' '
																				AND		E11.E1_SALDO	> 0
																				AND		E11.E1_TIPO		= 'NCC'
																				AND		E11.E1_VENCREA	= E1.E1_VENCREA ) , 0 ) AS SALDO
			FROM	%Table:SE1% E1
			WHERE	E1.D_E_L_E_T_	= ' '
			AND		E1.E1_SALDO		> 0
			AND		E1.E1_TIPO		NOT IN ( 'RA' , 'NCC' )
			%Exp:_cFiltro%
			
			GROUP BY E1.E1_VENCREA
			ORDER BY E1.E1_VENCREA
		
		EndSql
	
	
	Case _nOpcao == 5
				
		BeginSql alias _cAlias
		
			SELECT  E1.E1_I_CART AS COD_CART,  // Carteira do Titulo
					NVL( (	SELECT	ZAR.ZAR_DESC
							FROM	%Table:ZAR% ZAR
							WHERE	ZAR.D_E_L_E_T_	= ' '
							AND		ZAR.ZAR_COD		= E1.E1_I_CART ) , 'SEM TIPO' ) TIPO_CART,  // Descrição da Carteira
					SUM( ( Case	WHEN ( TO_DATE( %Exp:_cFiltro3% , 'YYYY/MM/DD' ) - TO_DATE( E1.E1_VENCREA , 'YYYY/MM/DD' ) > 0  AND TO_DATE( %Exp:_cFiltro3% , 'YYYY/MM/DD' ) - TO_DATE( E1.E1_VENCREA , 'YYYY/MM/DD' ) <= 1825 AND E1.E1_TIPO <> 'NCC' AND E1.E1_I_CART <> ' ' ) // 365 Dias X 5 Anos = 1825 dias // SUM( ( Case	WHEN ( E1.E1_TIPO <> 'NCC' AND E1.E1_I_CART <> ' ' ) 
 								THEN ( ( E1.E1_SALDO + E1.E1_SDACRES ) - E1.E1_SDDECRE )
								Else 0
							END ) ) AS CART_COB,  
					SUM( ( Case	WHEN ( TO_DATE( %Exp:_cFiltro3% , 'YYYY/MM/DD' ) - TO_DATE( E1.E1_VENCREA , 'YYYY/MM/DD' ) > 0  AND TO_DATE( %Exp:_cFiltro3% , 'YYYY/MM/DD' ) - TO_DATE( E1.E1_VENCREA , 'YYYY/MM/DD' ) <= 15 AND E1.E1_TIPO <> 'NCC' AND E1.E1_I_CART = ' ' )
								THEN ( ( E1.E1_SALDO + E1.E1_SDACRES ) - E1.E1_SDDECRE )
								Else 0
							END ) ) AS VENC_15, // Valores dos títulos diferentes de NCC e vencimento menor igual a 15 dias.
					SUM( ( Case	WHEN ( TO_DATE( %Exp:_cFiltro3% , 'YYYY/MM/DD' ) - TO_DATE( E1.E1_VENCREA , 'YYYY/MM/DD' ) > 15 AND E1.E1_TIPO <> 'NCC' AND E1.E1_I_CART = ' ' )
								THEN ( ( E1.E1_SALDO + E1.E1_SDACRES ) - E1.E1_SDDECRE )
								Else 0
							END ) ) AS VENC_DUV, // Valores dos títulos de vencimento duvidoso acima de 15 dias, diferentes de NCC
					SUM( ( Case	WHEN E1.E1_TIPO = 'NCC'
								THEN E1.E1_SALDO
								Else 0
							END ) ) AS REC_NCC  // Somatória de todos os titulos NCC com saldo.
			FROM	%Table:SE1% E1
			WHERE	E1.D_E_L_E_T_	= ' '
			AND		E1.E1_SALDO		> 0
			AND		E1.E1_TIPO		<> 'RA'
			AND		E1.E1_VENCREA	<> ' '
			
			GROUP BY E1.E1_I_CART
			ORDER BY E1.E1_I_CART
		
		EndSql
		
	//====================================================================================================
	// Query para realizar o consulta de titulos sob cobranca judicial
	//====================================================================================================
	Case _nOpcao == 6
	
		BeginSql alias _cAlias
		
			SELECT	COUNT( 1 )			AS QTDCOB,
					SUM( E1.E1_SALDO )	AS TOTALCOB
			FROM	%Table:SE1% E1
			WHERE	E1.D_E_L_E_T_	= ' '
			AND		E1.E1_SITUACA	= '6'
			AND		E1.E1_TIPO		NOT IN ( 'RA' , 'NCC' )
			
		EndSql
	
	//====================================================================================================
	// Query para diminuir do total dos titulos os titulos de NCC
	//====================================================================================================
	Case _nOpcao == 7
	
		BeginSql alias _cAlias
		
			SELECT	SUM( ( E1.E1_SALDO + E1.E1_SDACRES ) - E1.E1_SDDECRE ) AS TOTAL_NCC
			FROM	%Table:SE1% E1
			WHERE	E1.D_E_L_E_T_	= ' '
			AND		E1.E1_SALDO		> 0
			AND		E1.E1_TIPO		= 'NCC'
			%Exp:_cFiltro%
		
		EndSql

EndCase

Return
