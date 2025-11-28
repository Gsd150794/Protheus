/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |10/03/2021| Chamado 35875. Corrigido usuário da última alteração,
Lucas Borges  |26/01/2022| Chamado 42706. Parâmetros globais devem ser alterados apenas por que acessa todas as filiais.
Lucas Borges  |10/10/2025| Chamado 52181. Alterada gravação na SX6 para não gravar via RecLock
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: ACFG006
Autor-------------: Lucas Borges
Data da Criacao---: 30/07/2018
Descrição---------: Permite manipular o conteúdo de qualquer parâmetro informado previamente no cadastro de usuários Italac
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ACFG006

Private _cPerg	:= "ACFG006"
Private _oSelf	:= nil
Private _aButtons	:={}

//============================================
//Cria interface principal
//============================================
tNewProcess():New(	"ACFG006"										,; // Função inicial
					"Alteração de Parâmetros"						,; // Descrição da Rotina
					{|_oSelf| ACFG06P() }						,; // Função do processamento
					"Rotina para permitir alterar parâmetros sem precisar acessar o Configurador",; // Descrição da Funcionalidade
					_cPerg											,; // Configuração dos Parâmetros
					{}												,; // Opções adicionais para o painel lateral
					.F.												,; // Define criação do Painel auxiliar
					0												,; // Tamanho do Painel Auxiliar
					''												,; // Descrição do Painel Auxiliar
					.T.												 ) // Opção para criação de apenas uma régua de processamento


Return

/*
===============================================================================================================================
Programa----------: ACFG06P
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 25/07/2018
Descrição---------: Monta rotina para alteração dos parâmetros
Parametros--------: _oSelf
Retorno-----------: 
===============================================================================================================================
*/
Static Function ACFG06P

Local _aArea	:= FWGetArea()
Local _aFilUsr	:= FWLoadSM0(.F.,.T.) 
Local _aParam	:= {}
Local _cDetalhes:= ''
Local _oDlg		:= Nil
Local _nI		:= 0
Local _nOpca	:= 0
Local _cDesc	:= ''
Local _cCont	:= ''
Local _cFilOri	:= cFilAnt
Local _cAlias	:= ''
Local _cFilial	:= ''
Local _cFiltro	:= "%'%"+MV_PAR01+"%'%"
Local _lTodas	:= .T.

DBSelectArea('ZZL')
ZZL->( DBSetOrder(3) )
If !Empty(MV_PAR01) .And. (FwIsAdmin() .Or. (ZZL->( DBSeek(xFilial("ZZL")+RetCodUsr()) ) .And. AllTrim(MV_PAR01) $ AllTrim(ZZL->ZZL_PARAME)))
	For _nI := 1 To Len( _aFilUsr )
		If _aFilUsr[1][11] == .F.
			_lTodas := .F.
			Exit
		EndIf
	Next _nI

	SX6->( DBSetOrder(1) )
	
	If _lTodas
		If SX6->( DBSeek( '  ' + MV_PAR01 ) )
			aAdd( _aParam , { '  ' , 'Todas' ,SX6->(FieldGet(FieldPos("X6_TIPO"))), '', X6Conteud(), ACFG006A(SX6->(FieldGet(FieldPos("X6_TIPO"))),1,X6Conteud()) } )
			_cDesc:= X6Descric()
		EndIf
	EndIf		
	For _nI := 1 To Len( _aFilUsr )
		If SX6->( DBSeek( _aFilUsr[_nI][5] + MV_PAR01 ) )
			aAdd( _aParam , { _aFilUsr[_nI][5] , _aFilUsr[_nI][7] , SX6->(FieldGet(FieldPos("X6_TIPO"))), '', X6Conteud() , ACFG006A(SX6->(FieldGet(FieldPos("X6_TIPO"))),1,X6Conteud()) } )
			_cDesc:= X6Descric()
		EndIf
	Next _nI

	For _nI:=1 To Len (_aParam)
		_cAlias	:= GetNextAlias()
		_cFilial:= IIf(Empty(_aParam[_nI][01]),'01',_aParam[_nI][01])
		
		BeginSql Alias _cAlias
			SELECT CV8_USER FROM %Table:CV8%
			WHERE D_E_L_E_T_ = ' '
			AND CV8_FILIAL = %Exp:_cFilial%
			AND CV8_PROC = %Exp:_cPerg%
			AND CV8_MSG LIKE %Exp:_cFiltro%
			ORDER BY CV8_DATA DESC, CV8_HORA DESC
			FETCH FIRST 1 ROWS ONLY
		EndSql		
			_aParam[_nI][04]:= (_cAlias)->CV8_USER
		(_cAlias)->(DBCloseArea())
	Next
	
	If Len(_aParam) > 0
		DEFINE MSDIALOG _oDlg TITLE _cDesc FROM 000,000 TO 540,650 PIXEL// alturaXlargura
		
			_oBrowse := TCBrowse():New( 001 , 001 , 325/*largura*/ , 250/*altura*/ ,, {'Filial','Descrição','Tipo','Ult. Alteração','Conteúdo Atual','Novo Conteúdo'} ,, _oDlg ,,,,,{||},,,,,,,.F.,,.T.,,.F.,,, )
			
			_oBrowse:SetArray( _aParam )
			_oBrowse:AddColumn( TCColumn():New( 'Filial'		, {|| _aParam[_oBrowse:nAt][01] } ,,,, "LEFT" ,,	.F. , .T. ,,,, .F. ) )
			_oBrowse:AddColumn( TCColumn():New( 'Descrição'		, {|| _aParam[_oBrowse:nAt][02] } ,,,, "LEFT" ,,	.F. , .T. ,,,, .F. ) )
			_oBrowse:AddColumn( TCColumn():New( 'Tipo'			, {|| _aParam[_oBrowse:nAt][03] } ,,,, "LEFT" ,,	.F. , .T. ,,,, .F. ) )
			_oBrowse:AddColumn( TCColumn():New( 'Ult. Alteração', {|| _aParam[_oBrowse:nAt][04] } ,,,, "LEFT" ,40,	.F. , .T. ,,,, .F. ) )
			_oBrowse:AddColumn( TCColumn():New( 'Conteúdo Atual', {|| _aParam[_oBrowse:nAt][05] } ,,,, "LEFT" ,50,	.F. , .T. ,,,, .F. ) )
			_oBrowse:AddColumn( TCColumn():New( 'Novo Conteúdo'	, {|| _aParam[_oBrowse:nAt][06] } ,,,, "LEFT" ,50,	.F. , .F.,,{ || ACFG006V(ReadVar())},, .F., ) )
			
			_oBrowse:aColSizes		:= { 010 , 150 , 0050 , 0050 }
			_oBrowse:bLDblClick		:= {|z,x| IIf( x == 06 , ( lEditCell( _aParam , _oBrowse ,  , x ) , .T. ) , .F. ) , _oBrowse:Refresh() }
			_oBrowse:lAdjustColSize	:= .F.
			
			@255,120 BUTTON _oBtn01 PROMPT "Confirmar" SIZE 040,010 OF _oDlg PIXEL ACTION IIf( ACFG006V(_aParam) , ( _nOpca := 1 , _oDlg:End() ) , MsgAlert("Verifique o conteúdo informado no parâmetro!","ACFG00601") )
			@255,162 BUTTON _oBtn02 PROMPT "Cancelar"  SIZE 040,010 OF _oDlg PIXEL ACTION ( _oDlg:End() , _nOpca := 2 )
			
		ACTIVATE MSDIALOG _oDlg CENTERED
	Else
		MsgStop("Para alterar parâmetros globais o usuário deve ter acesso à todas as filiais. Tentativa de alteração do parâmetro " + MV_PAR01, "ACFG00602")
	EndIf
	If _nOpca == 1
		For _nI := 1 To Len( _aParam )
			If SX6->( DBSeek( _aParam[_nI][01] + MV_PAR01 ) ) 
				_cCont:= ACFG006A(_aParam[_nI][03],2,_aParam[_nI][06],_aParam[_nI][05])
				If !_cCont == AllTrim(X6Conteud())
					_cDetalhes:='Conteúdo anterior: ' + AllTrim(X6Conteud()) + 'Conteúdo atual: ' + _cCont + CRLF
					//=========================================================================================
					//Troco a filial corrente para poder gravar o log setando o CV8_FILIAL corretamente, assim 
					//a consulta do logfica correta e consigo exibir ele no browse
					//=========================================================================================
					cFilAnt := IIf(Empty(_aParam[_nI][01]),_cFilOri,_aParam[_nI][01] )
					PutMV(MV_PAR01,_cCont)

					ProcLogIni( _aButtons )
					ProcLogAtu("MENSAGEM","Alteracao parametro "+MV_PAR01,_cDetalhes,_cPerg)
				EndIf
			EndIf
		Next _nI
	EndIf
    cFilAnt:= _cFilOri
Else
	MsgStop("Usuário sem acesso para alterar o parâmetro informado: " + AllTrim(MV_PAR01), "ACFG00601" )
EndIf
ZZL->(DBCloseArea())
FWRestArea( _aArea )

Return

/*
===============================================================================================================================
Programa----------: ACFG006A
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 30/07/2018
Descrição---------: Altera tipagem da variável para poder montar o Browse com o tipo correto. Evita que tenha que fazer algumas
					validaçõs básicas de formato, mas não funcionou para o Lógico.
Parametros--------: _aParam[_nI][03] - Tipo do parâmetro (L-Lógico, C-Caracter, D-Data, N-Numérico)
					_nOpc - 1-Converte de texto para o tipo correto para exibir no Browse. 2- Converte de volta para texto para
					poder gravar na SX6.
					_aParam[_nI][05] - Conteúdo do parâmetro/browse atualizado
					_aParam[_nI][04] - Conteúdo do parâmetro/browse antes da atualização
Retorno-----------: _xRet - Conteúdo do parâmetro/browse já tratado
===============================================================================================================================
*/
Static Function ACFG006A(_cTipo,_nOpc,_xRet,_xRetOri)

If ValType(_xRet)=='L' .And. _nOpc == 1
	_xRet:=SubStr(_xRet,1,3)
ElseIf _cTipo == 'N' .And. _nOpc == 2
	_xRet:= cValToChar(_xRet)
ElseIf _cTipo == 'D' .And. _nOpc == 1
	If At('/',_xRet) > 0
		_xRet:= CToD(_xRet)
	Else
		_xRet:= CToD(SubStr(_xRet,7,2)+'/'+SubStr(_xRet,5,2)+'/'+SubStr(_xRet,1,4))
	EndIf
ElseIf _cTipo == 'D' .And. _nOpc == 2
	If At('/',_xRetOri) > 0
		_xRet:= DToC(_xRet)
	Else
		_xRet:= DToS(_xRet)
	EndIf
EndIf

If _nOpc==2
	_xRet:=AllTrim(_xRet)
EndIf

Return (_xRet)

/*
===============================================================================================================================
Programa----------: ACFG006V
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 30/07/2018
Descrição---------: Valida conteúdo informado no browse
Parametros--------: _aParam - Conteúdo do parâmetro/browse informado pelo usuário
Retorno-----------: _lRet - .T./.F. - permite ou não prosseguir com a alteração
===============================================================================================================================
*/
Static Function ACFG006V(_aParam)

Local _lRet		:= .T.
Local _nI, _nX	:= 0
Local _cChar	:= ''

For _nI:= 1 To Len( _aParam )
	If _lRet .And. _aParam[_nI][03]=='L' .And. !(AllTrim(_aParam[_nI][06]) == '.T.' .Or. AllTrim(_aParam[_nI][06]) == '.F.')
		_lRet := .F.
	ElseIf _lRet .And. _aParam[_nI][03]=='N'
		For _nX:= 1 To Len (AllTrim(_aParam[_nI][06]))
			_cChar:=SubStr(AllTrim(_aParam[_nI][06]), _nX, 1)
			If !_cChar $ '0123456789.'
				_lRet := .F.
				Exit
			EndIf
		Next _nX
	EndIf
Next _nI

Return(_lRet)
