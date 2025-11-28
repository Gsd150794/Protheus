/*
===============================================================================================================================
               ULTIMAS ATUALIZACOES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor     |    Data    |                                             Motivo                                           
===============================================================================================================================
Julio Paz    | 05/10/2017 | Chamado 21340. Inclusão de campo que informa o Local de retirada das mercadorias.
Lucas Borges | 17/10/2019 | Chamado 28346. Removidos os Warning na compilação da release 12.1.25.
Igor Melgaço | 18/06/2024 | Chamado 47474. Inclusão de Campo de VR. do IPI.
==================================================================================================================================================================================================================
Analista     - Programador   - Inicio   - Envio    - Chamado - Motivo da Alteração
==================================================================================================================================================================================================================
Jerry        - Alex Wallauer - 14/10/20 - 14/10/24 - 48807   - Alteração das decimais da quantidade para 3 
==================================================================================================================================================================================================================
*/
//====================================================================================================
// Definicoes de Includes e Defines da Rotina.
//====================================================================================================
#Include "TOTVS.ch"
#Include "Fileio.Ch"

#Define TITULO	"Solicitação de Vendas - Funcionários"
#Define CRLF	Chr(13)+Chr(10)

/*
===============================================================================================================================
Programa--------: ROMS011
Autor-----------: Alexandre Villar
Data da Criacao-: 31/08/2015
===============================================================================================================================
Descrição-------: Relatório dos registros das solicitações de vendas para funcionários
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function ROMS011()

Private _oReport	:= Nil
Private _aGrupos	:= {}

SET DATE FORMAT TO "DD/MM/YYYY"

If Z12->Z12_STATUS == "C"
	
	MessageBox( 'Não é possível imprimir solicitações canceladas!' , 'Atenção!' , 48 )
	
Else

	Processa( {|| ROMS011PRT() } , 'Aguarde!' , 'Imprimindo solicitação...' )

EndIf

Return

/*
===============================================================================================================================
Programa--------: ROMS011PRT
Autor-----------: Alexandre Villar
Data da Criacao-: 13/07/2015
===============================================================================================================================
Descrição-------: Função para controlar e imprimir os dados do relatório
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS011PRT()

Local _nLinha	:= 300
Local _oPrint	:= Nil

Private _oFont01 := TFont():New( "Tahoma" ,, 14 , .F. , .T. ,, .T. ,, .T. , .F. )
Private _oFont02 := TFont():New( "Tahoma" ,, 08 , .F. , .T. ,, .T. ,, .T. , .F. )
Private _oFont03 := TFont():New( "Tahoma" ,, 08 , .F. , .F. ,, .T. ,, .T. , .F. )
Private _oFont04 := TFont():New( "Tahoma" ,, 10 , .F. , .T. ,, .T. ,, .T. , .F. )

ProcRegua(0)
IncProc( 'Iniciando...' )

//====================================================================================================
// Inicializa o objeto do relatório
//====================================================================================================
_oPrint := TMSPrinter():New( TITULO )
_oPrint:Setup()
_oPrint:SetLandscape()
_oPrint:SetPaperSize(9)

IncProc( 'Imprimindo...' )

//====================================================================================================
// Inicializa a primeira página do relatório
//====================================================================================================
_nLinha		:= 50000
		
ROMS011VPG( @_oPrint , @_nLinha , .F. )

_nLinha += 030
_oPrint:Say( _nLinha , 0100 , 'Detalhes da solicitação de compra: '+ Z12->Z12_CODIGO +' - Total da solicitação: '+ Transform( Z12->Z12_VALOR , '@E 999,999,999,999.99' ) , _oFont02 )
_nLinha += 035

_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++

_nLinha += 060

_oPrint:Line( _nLinha       , 0050 , _nLinha       , 3350 )
_oPrint:Line( _nLinha + 035 , 0050 , _nLinha + 035 , 3350 )
_oPrint:Line( _nLinha       , 0050 , _nLinha + 035 , 0050 )
_oPrint:Line( _nLinha       , 3350 , _nLinha + 035 , 3350 )

_oPrint:Say( _nLinha , 0120 , 'Item'            , _oFont02 )
_oPrint:Say( _nLinha , 0300 , 'Produto'         , _oFont02 )
_oPrint:Say( _nLinha , 0500 , 'Descrição'  		, _oFont02 )
_oPrint:Say( _nLinha , 1500 , 'UM'              , _oFont02 )
_oPrint:Say( _nLinha , 1750 , 'Valor Unit.'     , _oFont02 )
_oPrint:Say( _nLinha , 2000 , 'Qtd. Solic.'     , _oFont02 )
_oPrint:Say( _nLinha , 2250 , '2ª UM'           , _oFont02 )
_oPrint:Say( _nLinha , 2500 , 'Qtd. 2ª UM'      , _oFont02 )
_oPrint:Say( _nLinha , 2750 , '% IPI'           , _oFont02 )
_oPrint:Say( _nLinha , 3000 , 'Valor IPI'       , _oFont02 )
_oPrint:Say( _nLinha , 3200 , 'Valor Total'     , _oFont02 )

_nLinha += 040

DBSelectArea('Z13')
Z13->( DBSetOrder(1) )
If Z13->( DBSeek( xFilial('Z13') + Z12->Z12_CODIGO ) )
	
	While Z13->(!Eof()) .And. Z13->( Z13_FILIAL + Z13_CODPED ) == xFilial('Z13') + Z12->Z12_CODIGO
		
		DBSelectArea('SB1')
		SB1->( DBSetOrder(1) )
		If SB1->( DBSeek( xFilial('SB1') + Z13->Z13_CODPRD ) )
		
			If SB1->B1_TIPCONV == "D"
				_nQtdSeg := Z13->Z13_QTD / SB1->B1_CONV
			Else
				_nQtdSeg := Z13->Z13_QTD * SB1->B1_CONV
			EndIf
			
			_oPrint:Say( _nLinha , 0125 , Z13->Z13_ITEM																, _oFont03 )
			_oPrint:Say( _nLinha , 0290 , Z13->Z13_CODPRD															, _oFont03 )
			_oPrint:Say( _nLinha , 0500 , AllTrim( SB1->B1_DESC )													, _oFont03 )
			_oPrint:Say( _nLinha , 1500 , SB1->B1_UM																, _oFont03 )
			_oPrint:Say( _nLinha , 1750 , Transform( Z13->Z13_VUNIT					, '@E 999,999,999,999.99' )		, _oFont03 ,,,, 2 )
			_oPrint:Say( _nLinha , 2000 , Transform( Z13->Z13_QTD					, '@E 999,999,999,999.99' )		, _oFont03 ,,,, 2 )
			_oPrint:Say( _nLinha , 2270 , SB1->B1_SEGUM																, _oFont03 )
			_oPrint:Say( _nLinha , 2520 , Transform( _nQtdSeg						, '@E 999,999,999,999.99' )		, _oFont03 ,,,, 2 )
			_oPrint:Say( _nLinha , 2750 , Transform( Z13->Z13_PIPI	         , '@E 999.99' )		, _oFont03 ,,,, 2 )
			_oPrint:Say( _nLinha , 3000 , Transform( Z13->Z13_VRIPI        	, '@E 999,999,999,999.99' )		, _oFont03 ,,,, 2 )
			_oPrint:Say( _nLinha , 3240 , Transform( (Z13->Z13_QTD*Z13->Z13_VUNIT) + Z13->Z13_VRIPI       	, '@E 999,999,999,999.99' )		, _oFont03 ,,,, 2 )
		
		EndIf
		
		_nLinha += 30
		ROMS011VPG( @_oPrint , @_nLinha , .T. )
		
	Z13->( DBSkip() )
	EndDo
	
	_nLinha += 15
	
	_oPrint:Line( _nLinha       , 0050 , _nLinha       , 3350 )
	_oPrint:Line( _nLinha + 035 , 0050 , _nLinha + 035 , 3350 )
	_oPrint:Line( _nLinha       , 0050 , _nLinha + 035 , 0050 )
	_oPrint:Line( _nLinha       , 3350 , _nLinha + 035 , 3350 )
	
	_oPrint:Say( _nLinha , 0120 , 'Total da solicitação ------------------------------------------------------------------------------'	, _oFont02 )
	_oPrint:Say( _nLinha , 3250 , Transform( Z12->Z12_VALOR	, '@E 999,999,999,999.99' )				 									, _oFont02 ,,,, 2 )

Else

	_oPrint:Say( _nLinha , 0125 , 'Falha ao identificar os itens do pedido.' , _oFont03 )
	
EndIf

_nLinha += 100

ROMS011VPG( @_oPrint , @_nLinha , .T. )

_oPrint:Line( _nLinha       , 0050 , _nLinha       , 3350 )
_oPrint:Line( _nLinha + 035 , 0050 , _nLinha + 035 , 3350 )
_oPrint:Line( _nLinha       , 0050 , _nLinha + 035 , 0050 )
_oPrint:Line( _nLinha       , 3350 , _nLinha + 035 , 3350 )

_oPrint:Say( _nLinha , 0120 , 'Status da Solicitação: '												, _oFont02 )
_oPrint:Say( _nLinha , 0450 , U_ITRetBox( Z12->Z12_STATUS , 'Z12_STATUS' )							, _oFont02 )

_oPrint:Say( _nLinha , 1750 , 'Pedido de Venda: '													, _oFont02 )

If !Empty( Z12->Z12_PEDSC5 )

	_oPrint:Say( _nLinha , 2000 , AllTrim( Z12->Z12_PEDSC5 )										, _oFont02 )
	_oPrint:Say( _nLinha , 2400 , 'Emissão: '														, _oFont02 )
	_oPrint:Say( _nLinha , 2600 , DToC( Posicione( 'SC5' , 1 , Z12->Z12_PEDSC5 , 'C5_EMISSAO' ) )	, _oFont02 )

EndIf

//=================================================================================================
// Starta o objeto de impressão
//=================================================================================================
_oPrint:Preview()

Return

/*
===============================================================================================================================
Programa--------: ROMS011VPG
Autor-----------: Alexandre Villar
Data da Criacao-: 29/04/2014
===============================================================================================================================
Descrição-------: Validação do pocicionamento da página atual para quebras
===============================================================================================================================
Parametros------: oPrint	- Objeto de Impressão do Relatório
----------------: nLinha	- Variável de controle do posicionamento
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS011VPG( _oPrint , _nLinha , _lFinPag )

Local _nLimPag		:= 2300 //3400

Default _lFinPag	:= .T.

If _nLinha > _nLimPag

	//====================================================================================================
	// Verifica se encerra a página atual
	//====================================================================================================
	If _lFinPag
		_oPrint:EndPage()
	EndIf
	
	//====================================================================================================
	// Inicializa a nova página e o posicionamento
	//====================================================================================================
	_oPrint:StartPage()
	_nLinha	:= 280
	
	//====================================================================================================
	// Insere logo no cabecalho
	//====================================================================================================
	If File( "LGRL01.BMP" )
		_oPrint:SayBitmap( 050 , 020 , "LGRL01.BMP" , 410 , 170 )
	EndIf
	
	//====================================================================================================
	// Imprime quadro do Título
	//====================================================================================================
	_oPrint:Line( 050 , 0400 , 050 , 3350 )
	_oPrint:Line( 290 , 0400 , 290 , 3350 )
	_oPrint:Line( 050 , 0400 , 290 , 0400 )
	_oPrint:Line( 050 , 3350 , 290 , 3350 )
	
	
	_oPrint:Say( 060 , 420 , TITULO +" [ "+ DToC( Z12->Z12_DATA ) +" - "+ Z12->Z12_HORA +"]"																		, _oFont01 )
	_oPrint:Say( 120 , 420 ,	"> Funcionário: "+ AllTrim( Posicione( 'SRA' , 1 , xFilial('SRA') + Z12->Z12_MATRIC , 'RA_NOME' ) )	+" - Filial: "+ SRA->RA_FILIAL	, _oFont04 )
	_oPrint:Say( 160 , 420 ,	"> CPF: "+ SRA->RA_CIC																												, _oFont04 )
	_oPrint:Say( 200 , 420 ,	"> Matrícula: "+ Z12->Z12_MATRIC																									, _oFont04 )
	_oPrint:Say( 240 , 420 ,	"> Local de Entrega: "+ AllTrim(Upper(U_ITRetBox( Z12->Z12_LOCENT,"Z12_LOCENT")))													, _oFont04 )
	
	//====================================================================================================
	// Adiciona cabecalho de conteúdo
	//====================================================================================================
	_nLinha := 295
	
EndIf

Return
