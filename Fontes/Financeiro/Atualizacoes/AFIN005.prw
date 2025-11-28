/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz     |07/05/2018| Chamado 24726. Padronização dos cabeçalhos dos fontes e funções do módulo financeiro.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: AFIN005
Autor-----------: Alexandre Villar
Data da Criacao-: 14/01/2016
Descrição-------: Rotina para cadastrar o histórico de alteração nos títulos de contas a receber
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function AFIN005()

Local _oBrowse	:= Nil
Local _aRotAux	:= aRotina

aRotina := {}

aAdd( aRotina , { "Pesquisar"	, "AxPesqui" , 0 , 1 } )
aAdd( aRotina , { "Visualizar"	, "AxVisual" , 0 , 2 } )

If Type( 'Altera' ) == 'L' .And. Altera

	aAdd( aRotina , { "Incluir"		, "AxInclui" , 0 , 3 } )
	aAdd( aRotina , { "Alterar"		, "AxAltera" , 0 , 4 } )
	aAdd( aRotina , { "Excluir"		, "AxDeleta" , 0 , 5 } )

EndIf

_oBrowse := FWMBrowse():New()

_oBrowse:SetAlias( "Z15" )
_oBrowse:SetDescription( "Histórico de alterações do título: "+ SE1->(E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO+E1_CLIENTE+E1_LOJA) )
_oBrowse:DisableDetails()
_oBrowse:SetFilterDefault( ' Z15->Z15_CHAVE == SE1->(E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO+E1_CLIENTE+E1_LOJA) ' )
_oBrowse:Activate()

aRotina := _aRotAux

Return

/*
===============================================================================================================================
Programa--------: AFIN005S
Autor-----------: Alexandre Villar
Data da Criacao-: 14/01/2016
Descrição-------: Rotina de inicializador padrão para o campo sequencia
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function AFIN005S()

Local _cRet := ''

DBSelectArea('Z15')
Z15->( DBSetOrder(1) )
If Z15->( DBSeek( xFilial('Z15') + SE1->(E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO+E1_CLIENTE+E1_LOJA) ) )
	
	While Z15->( !Eof() ) .And. Z15->( Z15_FILIAL + Z15_CHAVE ) == xFilial('Z15') + SE1->(E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO+E1_CLIENTE+E1_LOJA)
		
		_cRet := Z15->Z15_SEQ
		
	Z15->( DBSkip() )
	EndDo
	
	_cRet := Soma1( _cRet )
	
Else

	_cRet := '001'
	
EndIf

Return( _cRet )
