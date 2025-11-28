/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |14/11/2019| Chamado 31192. Corrigida transferência de empréstimos.
Lucas Borges  |10/02/2020| Chamado 31974. Corrigida efetivação de empréstimos.
Lucas Borges  |29/12/2020| Chamado 35123. Retirada função UCFG001.
===============================================================================================================================
*/

#Include "TOTVS.ch" 
#Include "FWMVCDEF.CH"

/*
===============================================================================================================================
Programa----------: AGLT016
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 22/03/2019
Descrição---------: Rotina para lançamentos dos empréstimos de terceiros, cópia do AGLT012 - Chamado 11132
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT016

Local _oBrowse := Nil

Private	_cNUseAp	:= SubStr(UsrFullName(RetCodUsr()),1,GetSX3Cache("ZLN_NUSEAP","X3_TAMANHO"))
Private _cMatUsr	:= FWSFAllUsers({RetCodUsr()},{"USR_FILIAL","USR_CODFUNC"})[1][3]+FWSFAllUsers({RetCodUsr()},{"USR_FILIAL","USR_CODFUNC"})[1][4]
Private	_cTipo01	:= SuperGetMV("LT_3EMPTP1",.F.,"NDF")
Private	_cTipo02	:= SuperGetMV("LT_3EMPTP2",.F.,"NF")
Private	_cNaturez	:= SuperGetMV("LT_3EMPNAT",.F.,"222009")
Private _cPrefixo	:= ""

If dDataBase <> LastDate(dDataBase)
	MsgStop("Operações permitidas somente com ultimo dia do mês!",'AGLT01601')
	Return
EndIf

//====================================================================================================
// Configura e inicializa a Classe do Browse
//====================================================================================================
_oBrowse := FWMBrowse():New()

_oBrowse:SetAlias( 'ZLN' )
_oBrowse:SetMenuDef( 'AGLT016' )
_oBrowse:SetDescription( 'Administração do Leite - Empréstimos Terceiros' )

_oBrowse:AddLegend( "ZLN_STATUS == '2'" , 'GREEN'	, 'Aprovada'		)
_oBrowse:AddLegend( "ZLN_STATUS == '3'" , 'RED'		, 'Reprovada'		)
_oBrowse:AddLegend( "ZLN_STATUS == '4'" , 'BLUE'	, 'Efetivado'		)
_oBrowse:AddLegend( "ZLN_STATUS == '1'" , 'WHITE'	, 'Em Aberto'		)
_oBrowse:AddLegend( "ZLN_STATUS == '5'" , 'BLACK'	, 'Transferido'		)
_oBrowse:AddLegend( "ZLN_STATUS == '6'" , 'GRAY'	, 'Transferência'	)

_oBrowse:Activate()

Return

/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 22/03/2019
Descrição---------: Rotina para criação do menu da tela principal
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MenuDef()

Local _aRotina := {}

ADD OPTION _aRotina Title 'Visualizar'		   		Action 'VIEWDEF.AGLT016'			OPERATION 2 ACCESS 0
ADD OPTION _aRotina Title 'Incluir'   		   		Action 'VIEWDEF.AGLT016'			OPERATION 3 ACCESS 0
ADD OPTION _aRotina Title 'Alterar'   		   		Action 'VIEWDEF.AGLT016'			OPERATION 4 ACCESS 0
ADD OPTION _aRotina Title 'Excluir'	   	   	  		Action 'VIEWDEF.AGLT016'			OPERATION 5 ACCESS 0
ADD OPTION _aRotina Title 'Avaliar'   		   		Action 'U_AGLT016A()'				OPERATION 4 ACCESS 0
ADD OPTION _aRotina Title 'Avaliação Múltipla'		Action 'U_AGLT016T(1)'				OPERATION 4 ACCESS 0
ADD OPTION _aRotina Title 'Efetivacao Multipla'		Action 'U_AGLT016T(2)'				OPERATION 3 ACCESS 0
ADD OPTION _aRotina Title 'Estorna'					Action 'U_AGLT016E()'				OPERATION 4 ACCESS 0
ADD OPTION _aRotina Title 'Transferencia'			Action 'U_AGLT016B()'				OPERATION 3 ACCESS 0
ADD OPTION _aRotina Title 'Estorno Transf.'			Action 'U_AGLT016C()'				OPERATION 3 ACCESS 0
ADD OPTION _aRotina Title 'Recibo Pagamento'		Action 'U_RGLT049()'				OPERATION 8 ACCESS 0
ADD OPTION _aRotina Title 'Declaração'				Action 'U_RGLT052()'				OPERATION 8 ACCESS 0

Return( _aRotina )

/*
===============================================================================================================================
Programa----------: ModelDef
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 22/03/2019
Descrição---------: Rotina para montagem do modelo de dados para o processamento
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ModelDef()

Local _oStruZLN	:= FWFormStruct( 1 , 'ZLN' )
Local _oStruZLQ	:= FWFormStruct( 1 , 'ZLQ' )
Local _oModel	:= MpFormModel():New( "AGLT016M" ,, {|_oModel| VALIDCOMIT(_oModel) } )
Local _aGatAux	:= {}

//====================================================================================================
// Monta a estrutura de gatilhos
//====================================================================================================
_aGatAux := FwStruTrigger( 'ZLN_SA2COD' , 'ZLN_SA2LJ' , 'SA2->A2_LOJA' , .T. , 'SA2' , 1 , 'xFilial("SA2")+M->ZLN_SA2COD+If(SA2->A2_COD==M->ZLN_SA2COD,SA2->A2_LOJA,"")' )
_oStruZLN:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLN_SA2COD' , 'ZLN_SA2NOM' , 'SA2->A2_NOME' , .T. , 'SA2' , 1 , 'xFilial("SA2")+M->(ZLN_SA2COD)' )
_oStruZLN:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLN_SA2LJ' , 'ZLN_SA2NOM' , 'SA2->A2_NOME' , .T. , 'SA2' , 1 , 'xFilial("SA2")+M->(ZLN_SA2COD+ZLN_SA2LJ)' )
_oStruZLN:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLN_TOTAL'	, 'ZLN_PAGTO' , 'U_AGLT016JUR()' , .F. )
_oStruZLN:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLN_JUROS'	, 'ZLN_PAGTO' , 'U_AGLT016JUR()' , .F. )
_oStruZLN:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLN_PARC'	, 'ZLN_PAGTO' , 'U_AGLT016JUR()' , .F. )
_oStruZLN:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLN_VENCTO'	, 'ZLN_PAGTO' , 'U_AGLT016JUR()' , .F. )
_oStruZLN:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLN_TOTAL'	, 'ZLN_DATA'  , 'dDataBase' , .F. )
_oStruZLN:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_oModel:AddFields(	'ZLNMASTER'	,				, _oStruZLN )
_oModel:AddGrid(	'ZLQDETAIL'	, 'ZLNMASTER'	, _oStruZLQ )

_oModel:SetRelation( 'ZLQDETAIL', { { 'ZLQ_FILIAL' , 'xFilial( "ZLQ" )' } , { 'ZLQ_COD' , 'ZLN_COD' } } , ZLQ->( IndexKey(1) ) )

_oModel:SetDescription( 'Administração do Leite - Solicitação de Empréstimos' )

_oModel:GetModel( 'ZLNMASTER' ):SetDescription( 'Dados do Produtor'		)
_oModel:GetModel( 'ZLQDETAIL' ):SetDescription( 'Dados do Empréstimo'	)

_oModel:GetModel( 'ZLQDETAIL' ):SetUniqueLine( { 'ZLQ_ITEM' } )
_oModel:GetModel( 'ZLQDETAIL' ):SetOptional( .T. )

_oModel:SetPrimaryKey( { 'ZLN_FILIAL' , 'ZLN_COD' } )

_oModel:SetVldActivate( {|_oModel| AGLT016L(_oModel) } )

Return( _oModel )

/*
===============================================================================================================================
Programa----------: ViewDef
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 22/03/2019
Descrição---------: Rotina para montar a View de Dados para exibição
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ViewDef()

Local _oModel	:= FWLoadModel( 'AGLT016' )
Local _oStruZLN	:= FWFormStruct( 2 , 'ZLN' )
Local _oStruZLQ	:= FWFormStruct( 2 , 'ZLQ' )
Local _oView	:= FWFormView():New()

_oStruZLQ:RemoveField( "ZLQ_FILIAL"	)
_oStruZLQ:RemoveField( "ZLQ_COD"	)

_oView:SetModel( _oModel )

_oView:AddField(	'VIEW_CAB' , _oStruZLN	, 'ZLNMASTER' )
_oView:AddGrid(		'VIEW_DET' , _oStruZLQ	, 'ZLQDETAIL' )

_oView:CreateHorizontalBox( 'SUPERIOR'	, 60 )
_oView:CreateHorizontalBox( 'INFERIOR'	, 40 )

_oView:SetOwnerView( 'VIEW_CAB'	, 'SUPERIOR'	)
_oView:SetOwnerView( 'VIEW_DET'	, 'INFERIOR'	)

_oView:EnableTitleView( 'VIEW_DET' , 'InFormações dos Vencimentos:' )

_oView:AddIncrementField( 'VIEW_DET' , 'ZLQ_ITEM' )

Return( _oView )

/*
===============================================================================================================================
Programa----------: AGLT016L
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 22/03/2019
Descrição---------: Rotina para processamento da validação inicial das operações
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT016L( _oModel )

Local _nOper		:= _oModel:GetOperation()
Local _lRet			:= .T.
Local _aArea		:= FWGetArea()

If _nOper == MODEL_OPERATION_DELETE .Or. _nOper == MODEL_OPERATION_UPDATE
	If ZLN->ZLN_STATUS <> '1'
		Help(NIL, NIL, "AGLT01602", NIL, "Não é possível alterar um registro que não esteja com status: 'Em Aberto'!", 1, 0, NIL, NIL, NIL, NIL, NIL, ;
		{"Verique o Status da solicitacao! Uma vez aprovada ou efetivada não poderá mais sofrer alterações."})
		_lRet := .F.
	EndIf
EndIf

FWRestArea( _aArea )

Return( _lRet )

/*
===============================================================================================================================
Programa----------: VALIDCOMIT
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 22/03/2019
Descrição---------: Rotina para processamento da validação final das operações ao confirmar o modelo de dados
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function VALIDCOMIT( _oModel )

Local _aArea	:= FWGetArea()
Local _lRet		:= .T.
Local _cCODSA2	:= ''
Local _cLOJSA2	:= ''
Local _dDtVenc	:= _oModel:GetValue( 'ZLNMASTER' , 'ZLN_VENCTO' )
Local _dDtCred	:= _oModel:GetValue( 'ZLNMASTER' , 'ZLN_DTCRED' )
Local _nOper	:= _oModel:GetOperation()

If dDataBase <> LastDate(dDataBase)
	Help(NIL, NIL, "AGLT01603", NIL, "Operações permitidas somente com ultimo dia do mês!", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Verique as datas informadas!"})
	_lRet := .F.
EndIf

If _lRet .And. _dDtCred < dDataBase
	Help(NIL, NIL, "AGLT01604", NIL, "Não é permitido informar uma data de Crédito menor que a data atual!", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Verique as datas informadas!"})
	_lRet := .F.
EndIf

If _lRet .And. _dDtVenc < _dDtCred
	Help(NIL, NIL, "AGLT01605", NIL, "Não é permitido informar uma data de 1º vencimento menor que a data do Crédito!", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Verique as datas informadas!"})
	_lRet := .F.
EndIf

If _lRet .And. _nOper == MODEL_OPERATION_INSERT
	
	_cCODSA2 := _oModel:GetValue( 'ZLNMASTER' , 'ZLN_SA2COD' )
	_cLOJSA2 := _oModel:GetValue( 'ZLNMASTER' , 'ZLN_SA2LJ'  )
	
	If !Empty( _cCODSA2 ) .And. !Empty( _cLOJSA2 )
	
		DBSelectArea('SA2')
		SA2->( DBSetOrder(1) )
		If SA2->( DBSeek( xFilial('SA2') + _cCODSA2 + _cLOJSA2 ) )
			If SA2->A2_MSBLQL == '1'
				MsgStop("Produtor/Fretista informado encontra-se Bloqueado no cadastro de Fornecedores do Sistema! Verifique o Fornecedor selecionado ou o cadastro do mesmo no Sistema!","AGLT01606")
				_lRet := .F.
			Else
				_oModel:LoadValue( 'ZLNMASTER' , 'ZLN_USER'  , _cMatUsr )
				_oModel:LoadValue( 'ZLNMASTER' , 'ZLN_NUSER' , _cNUseAp	)
			EndIf
		Else
			MsgStop("Produtor/Fretista informado não foi encontrado no cadastro de Fornecedores do Sistema! Verifique o Fornecedor selecionado ou o cadastro do mesmo no Sistema!","AGLT01607")
			_lRet := .F.
		EndIf
	
	EndIf
	If _oModel:GetValue( 'ZLNMASTER' , 'ZLN_VLRPAR' ) == 0
		MsgStop("O valor da parcela deve ser maior que 0! Verifique os dados informados!","AGLT01608")
		_lRet := .F.
	EndIf
EndIf

FWRestArea(_aArea)

Return( _lRet )

/*
===============================================================================================================================
Programa----------: AGLT016JUR
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 22/03/2019
Descrição---------: Gatilho que calcula juros e cria os itens com vencimento e valores das prestações
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT016JUR()

Local _oModel		:= FWModelActive()
Local _oView		:= FWViewActive()
Local _oModZLQ		:= _oModel:GetModel('ZLQDETAIL')

Local _nValTot		:= _oModel:GetValue( 'ZLNMASTER' , 'ZLN_TOTAL' )
Local _nParc		:= _oModel:GetValue( 'ZLNMASTER' , 'ZLN_PARC'  )
Local _nJuros		:= _oModel:GetValue( 'ZLNMASTER' , 'ZLN_JUROS' )
Local _nLenZLQ		:= 0
Local _nValPag		:= 0

Local _nI			:= 0
Local _nRest		:= 0
Local _aVenctos		:= {}
Local _dDtAux		:= SToD('')

Local _nTxJuro		:= 0
Local _nTemp		:= 0
Local _nTemp2		:= 0
Local _nTemp3		:= 0

If ( _nValTot <> 0 ) .And. ( _nParc <> 0 )

	//====================================================================================================
	// Novo Calculo dos juros e valor das parcelas
	//====================================================================================================
	_nValPag := Round( _nValTot , 2 )
	
	//====================================================================================================
	// Calculo do Juro Composto estava fazendo o cálculo achando o montante total de juros e dividindo 
	// pela qde de parcelas. Foi feito a implementação para o cálculo do PMT seguindo a Formula correta.
	//====================================================================================================
	If _nJuros == 0
		
		_nValPar := Round( _nValPag / _nParc	, 2 )
		
		
		_oModel:LoadValue( 'ZLNMASTER' , 'ZLN_VLRPAR' , _nValPar )
		_oModel:LoadValue( 'ZLNMASTER' , 'ZLN_PAGTO'  , _nValPag )
	
	Else
		
		For _nI := 1 To _nParc
			_nValPag *= ( ( _nJuros / 100 ) + 1 )
		Next _nI
		
		_nTxJuro	:= Round( ( _nJuros / 100 ) , 3 )
		_nTemp		:= ( 1 + _nTxJuro )
		
		For _nI:=1 To int(_nParc) - 1
        	_nTemp *= ( 1 + _nTxJuro )
        Next _nI
        
        _nTemp2			:= _nTemp - 1
        _nTemp3			:= ( _nTxJuro / _nTemp2 )
        _nValPar		:= Round( _nValPag * _nTemp3	, 2 )
        _nValPag		:= Round( _nValPar * _nParc		, 2 )
        
        _oModel:LoadValue( 'ZLNMASTER' , 'ZLN_VLRPAR' , _nValPar )
        _oModel:LoadValue( 'ZLNMASTER' , 'ZLN_PAGTO'  , _nValPag )
        
	EndIf
	
	//====================================================================================================
	// Preenche os itens                          
	//====================================================================================================
	_aVenctos	:= {}
	_dDtAux		:= _oModel:GetValue( 'ZLNMASTER' , 'ZLN_VENCTO' )
	_nRest		:= _nValPag
	
	For _nI := 1 To _nParc
	
		aAdd( _aVenctos , _dDtAux )
		_dDtAux := MonthSum( _dDtAux , 1 )
	
	Next _nI
	
	_nLenZLQ := _oModZLQ:Length()
	
	For _nI := 1 To _nLenZLQ
	
		_oModZLQ:GoLine( _nI )
		
		If !_oModZLQ:IsDeleted()
			_oModZLQ:DeleteLine()
		EndIf
		
	Next
	
	For _nI := 1 to Len( _aVenctos )
	
		If _nI <= _nLenZLQ
		    
			_oModZLQ:GoLine( _nI )
			
			If _oModZLQ:IsDeleted()
				_oModZLQ:UnDeleteLine()
			EndIf
			
			_oView:Refresh()
			
		Else
		
			_nLenZLQ := _oModZLQ:AddLine()
			_oView:Refresh()
			_oModZLQ:GoLine(_nI)
			
		EndIf
		
		_oModZLQ:LoadValue( 'ZLQ_VECTO' , _aVenctos[_nI] )
		
		If _nI < Len( _aVenctos )
		    
			_oModZLQ:LoadValue( 'ZLQ_VALOR' , Round( _nValPar , 2 ) )
			_nRest := _nRest - Round( _nValPar , 2 )
			
		Else
			
			_oModZLQ:LoadValue('ZLQ_VALOR' , _nRest )
			
		EndIf
		
	Next _nI
	
EndIf

_oModZLQ:GoLine(01)
_oView:Refresh()

Return( _nValPag )

/*
===============================================================================================================================
Programa----------: AGLT016A
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 22/03/2019
Descrição---------: Rotina para processamento da Avaliação de solicitações (Aprovar/Reprovar)
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT016A()

FWExecView( '[ Avaliação da Solicitação ]' , 'AGLT016' , 4 ,, {|| .T. } , {|| AGLT016ATU() } , 010 )

Return

/*
===============================================================================================================================
Programa----------: AGLT016ATU
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 22/03/2019
Descrição---------: Rotina para atualizar a solicitação com os dados da avaliação (Aprovar/Reprovar)
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT016ATU()

Local _oModel	:= FWModelActive()
Local _oView	:= FWViewActive()
Local _lRet		:= .T.
Local _aParAux	:= {}
Local _aParRet	:= {}
Local _aOpcoes	:= { 'Aprovar' , 'Reprovar' }

aAdd( _aParAux , { 2 , "Avaliação do registro:" , "Aprovar" , _aOpcoes , 65 ,, .T. } ) ; aAdd( _aParRet , '1' )
	
If ParamBox( _aParAux , "InFormar o Status da Avaliação:" , @_aParRet ,,, .F. ,,,,, .F. )

	If Upper( AllTrim( _aParRet[01] ) ) == 'APROVAR'
	
	   	_oModel:LoadValue( 'ZLNMASTER' , 'ZLN_STATUS' , "2" )
		_oModel:LoadValue( 'ZLNMASTER' , 'ZLN_DTAPRO' , ddatabase)
		_oModel:LoadValue( 'ZLNMASTER' , 'ZLN_USERAP' , _cMatUsr )
		_oModel:LoadValue( 'ZLNMASTER' , 'ZLN_NUSEAP' , _cNUseAp )
		
		_oView:Refresh()
	
	Else
		
		_oModel:LoadValue( 'ZLNMASTER' , 'ZLN_STATUS' , "3" )
		_oModel:LoadValue( 'ZLNMASTER' , 'ZLN_DTAPRO' , ddatabase)
		_oModel:LoadValue( 'ZLNMASTER' , 'ZLN_USERAP' , _cMatUsr )
		_oModel:LoadValue( 'ZLNMASTER' , 'ZLN_NUSEAP' , _cNUseAp )
		
		_oView:Refresh()
		
	EndIf
	
Else
	_lRet := .F.
EndIf

Return( _lRet )

/*
===============================================================================================================================
Programa----------: AGLT016T
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 22/03/2019
Descrição---------: Rotina de processamento de Avaliação/Efetivação múltipla de solicitações
Parametros--------: _cTpAplic : 1= Avaliação / 2= Efetivação
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT016T( _cTpAplic )

Local cLabel	:= ""
Local cVarQ		:= "  "
Local nOpcA		:= 0
Local x			:= 0
Local oDlg		:= Nil
Local oGet01	:= Nil

Private cPerg		:= "AGLT016" 
Private oF3			:= Nil
Private aDados		:= {}
Private oVlrTotal	:= Nil
Private _nVlrTot	:= 0
Private oOk			:= LoadBitmap( GetResources(), "LBOK" )
Private oNo			:= LoadBitmap( GetResources(), "LBNO" )

If !Pergunte(cPerg)
	Return
EndIf

ZLN->( DBSetOrder(1) )
ZLN->( DBGoTop() )

Processa({|| AGLT016GET( _cTpAplic ) })

If Len( aDados ) == 0

	MsgStop('Nao Foram encontrados registros de solicitações para o processamento! É preciso que existam solicitações '	+;
				IIf( _cTpAplic == 1 , '"em aberto"' , '"aprovadas"' )											+;
				' para processar a '+ IIf( _cTpAplic == 1 , '"Avaliação Múltipla"' , '"Efetivação Múltipla"' ) +'!.' ,"AGLT01609" )
	Return
	
EndIf

aSort( aDados ,,, {|x,y| x[3] < y[3] } )

//====================================================================================================
// Montando o listbox
//====================================================================================================
DEFINE MSDIALOG oDlg TITLE "Emprestimos - "+ IIf( _cTpAplic == 1 , "Aprovar" , "Efetivar" ) From 000,000 To 025,095 OF oMainWnd

	@ 005,005 TO 150,365 LABEL cLabel Pixel OF oDlg
	
	@ 010,010 LISTBOX oF3	VAR cVarQ ;
							Fields HEADER "",OemToAnsi("Solicitacao"),OemToAnsi("Nome"),OemToAnsi("Valor Total"),OemToAnsi("Parcelas"),OemToAnsi("Juros"),OemToAnsi("Vlr. Parcela"),OemToAnsi("Data 1o. Vencto"),OemToAnsi("Data Credito"),OemToAnsi("Obs.") ;
							COLSIZES 12,25,25,40,25,25,25,25,25,25,25,25,40 ;
							SIZE 350,135 ;
							ON DBLCLICK ( aDados := AGLT016MRK( oF3:nAt , aDados , oGet01 , 1 , 1 ) , oF3:Refresh() , AGLT016RCL( aDados , 5 ) , oVlrTotal:Refresh() ) ;
							PIXEL OF oDlg
	
	oF3:SetArray( aDados )
	oF3:bLine := {|| {	IIf(	aDados[oF3:nAt][01] , oOk , oNo )										,;
								aDados[oF3:nAt][02]														,;
								aDados[oF3:nAt][08] +'/'+ aDados[oF3:nAt,09] +' - '+ aDados[oF3:nAt,03]	,;
								aDados[oF3:nAt][04]														,;
								aDados[oF3:nAt][05]														,;
								aDados[oF3:nAt][06]														,;
								aDados[oF3:nAt][07]														,;
					DToC( SToD(	aDados[oF3:nAt][10] ) )													,;
					DToC( SToD(	aDados[oF3:nAt][11] ) )													,;
								aDados[oF3:nAt][12]														}}
	
	oF3:bHeaderClick := {|| AGLT016MTD() , oF3:Refresh() }
	
	DEFINE SBUTTON FROM 160,010 Type 01 ACTION Processa( {|| nOpcA := 1 , AGLT016APR( aDados , _cTpAplic ) , oDlg:End() } )	ENABLE OF oDlg
	DEFINE SBUTTON FROM 160,050 Type 02 ACTION ( nOpcA := 0 , oDlg:End() )													ENABLE OF oDlg
	
	@160,090 Button	OemToAnsi( "Visualizar"			) Size 50,11 OF oDlg PIXEL Action {|| ZLN->(DBSeek(xFilial("ZLN")+aDados[oF3:nAt][02])), FWExecView( '[ Avaliação da Solicitação ]' , 'AGLT016' , 1 ,, {|| .T. } ,, 010 ) }
	@160,150 Button	OemToAnsi( "Imprimir"			) Size 50,11 OF oDlg PIXEL Action {|| U_RGLT030( aDados ) }
	@160,210 Button	OemToAnsi( "Análise Financeira"	) Size 50,11 OF oDlg PIXEL Action {|| U_RGLT045( aDados[oF3:nAt][08] , aDados[oF3:nAt][09] ) }
	
	@162,280 Say	"Valor Total:"															OF oDlg PIXEL
	@160,310 MSGET	oVlrTotal VAR _nVlrTot PICTURE "@E 99,999,999.99" WHEN .F. SIZE 50,10	OF oDlg PIXEL
	
	//====================================================================================================
	// Calcula total dos selecionados
	//====================================================================================================
	AGLT016RCL( aDados , 5 )
	oVlrTotal:Refresh()

ACTIVATE MSDIALOG oDlg CENTERED

Return

/*
===============================================================================================================================
Programa----------: AGLT016E
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 22/03/2019
Descrição---------: Rotina de processamento do Estorno de processamentos das solicitações
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT016E()

Local nParcelas	:= 0
Local _lOk		:= .T.

If ZLN->ZLN_STATUS <> "4" .And. ZLN->ZLN_STATUS <> "2"

	MsgStop("Essa solicitacao nao pode ser Estornada por nao ter sido Efetivada/Aprovada!","AGLT01610")
	Return
	
EndIf

//====================================================================================================
// Status Efetivado
//====================================================================================================
If ZLN->ZLN_STATUS == '4'
	//====================================================================================================
	// Obtendo Parametos dos EMPRESTIMOS
	//====================================================================================================
	If ZLN->ZLN_TIPO == 'E'
		_cPrefixo:= SuperGetMV("LT_3EMPPRE",.F.,"G3E")
	EndIf
	
	//====================================================================================================
	// Obtendo Parametos dos ADIANTAMENTOS
	//====================================================================================================
	If ZLN->ZLN_TIPO == 'A'
		_cPrefixo := SuperGetMV("LT_3ADTPRE",.F.,"G3A")
	EndIf
	
	//====================================================================================================
	// Obtendo Parametos das ANTECIPACOES  
	//====================================================================================================
	If ZLN->ZLN_TIPO == "N"
		_cPrefixo := SuperGetMV("LT_3ANTPRE",.F.,"G3N")
	EndIf
	
	If !MsgYesNo( "Essa rotina irá cancelar a efetivacao dessa solicitacao. Deseja continuar?" )
		Return
	EndIf
	
	Begin Transaction
    	
    	//====================================================================================================
	    // Deleta o Título no Financeiro
	    //====================================================================================================
	   	If AGLT016DE2( _cPrefixo , ZLN->ZLN_COD , PadR("1",TamSX3("E2_PARCELA")[1]) , "NF " , ZLN->ZLN_SA2COD , ZLN->ZLN_SA2LJ , _cNaturez )
	   	    
	   		// Deleta as Parcelas
			For nParcelas := 1 To Int( ZLN->ZLN_PARC )
			
		    	If !AGLT016DE2( _cPrefixo , ZLN->ZLN_COD , PadR(AllTrim(Str(nParcelas)) , TamSX3("E2_PARCELA")[1]) , "NDF" , ZLN->ZLN_SA2COD , ZLN->ZLN_SA2LJ , _cNaturez )
		    		_lOk := .F.
		    	EndIf
		    	
			Next nParcelas
	   	
	   	Else
	   	
		   	_lOk := .F.
		   	
	   	EndIf
		
		If _lOk
		
	   		ZLN->( RecLock( 'ZLN' , .F. ) )
		    ZLN->ZLN_STATUS := '2'
		    ZLN->( MSUnLock() )
		    
		Else
		
			MsgStop("Falha ao processar a exclusão dos Títulos no Financeiro! InForme a área de TI/ERP.","AGLT01611")
		    DisarmTransaction()
		    
		EndIf
	
	End Transaction

//====================================================================================================
// Status Aprovado
//====================================================================================================
ElseIf ZLN->ZLN_STATUS == '2'

	If !MsgYesNo( "Essa rotina irá cancelar a aprovação dessa solicitacao. Deseja continuar?" )
		Return
	EndIf

	ZLN->( RecLock( 'ZLN' , .F. ) )
	
	    ZLN->ZLN_STATUS := '1'
	    ZLN->ZLN_DTAPRO := SToD('')
	    ZLN->ZLN_USERAP	:= ''
	    ZLN->ZLN_NUSEAP	:= ''
	    
    ZLN->( MSUnLock() )

EndIf

Return

/*
===============================================================================================================================
Programa----------: AGLT016DE2
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 22/03/2019
Descrição---------: Rotina para processar a exclusão de títulos no Financeiro
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT016DE2( _cPrefixo , _cNum , _cParcela , _cTipo , _cForn , _cLoja , _cNaturez )

Local _aAutoSE2	:= {}
Local _lOk		:= .T.
Local _nModAux	:= nModulo
Local _cModAux	:= cModulo

Private lMsErroAuto := .F.

aAdd( _aAutoSE2 , { "E2_PREFIXO"	, _cPrefixo		, Nil } )
aAdd( _aAutoSE2 , { "E2_NUM"		, _cNum			, nil } )
aAdd( _aAutoSE2 , { "E2_PARCELA"	, _cParcela		, nil } )
aAdd( _aAutoSE2 , { "E2_TIPO"		, _cTipo		, nil } )
aAdd( _aAutoSE2 , { "E2_NATUREZ"	, _cNaturez		, nil } )
aAdd( _aAutoSE2 , { "E2_FORNECE"	, _cForn		, nil } )
aAdd( _aAutoSE2 , { "E2_LOJA"		, _cLoja		, nil } )

nModulo := 6
cModulo := "FIN"

DBSelectArea("SE2")
SE2->( DBSetOrder(1) )
SE2->( DBGoTop() )
If SE2->( DBSeek( xFilial("SE2") + _cPrefixo + _cNum + _cParcela + _cTipo + _cForn + _cLoja ) )

	MSExecAuto( {|x,y,z| Fina050(x,y,z) } , _aAutoSE2 ,, 5 )
	
	If lMsErroAuto
		
		MsgStop("Falha ao processar a exclusão do Título: ("+ _cPrefixo +"-"+ _cNum +"-"+ _cForn +")! InForme a área de TI/ERP.","AGLT01612")
		mostraerro()
		_lOk := .F.
		
	EndIf
	
Else

	MsgStop("Título não encontrado: ("+_cPrefixo+_cNum+_cParcela+_cTipo+_cForn+_cLoja+")! InForme a área de TI/ERP.","AGLT01613")
	_lOk := .F.
	
EndIf

nModulo := _nModAux
cModulo := _cModAux

Return( _lOk )

/*
===============================================================================================================================
Programa----------: AGLT016GET
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 22/03/2019
Descrição---------: Rotina que verIfica e monta a estrutura de dados para o processamento
Parametros--------: _cTpAplic = 1-Em aberto 2-Aprovada
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT016GET( _cTpAplic )

Local _nQtdReg	:= 0
Local _cXtipo	:= ''
Local _cAlias	:= GetNextAlias()
Local _nFatura	:= 0

Do Case
	Case MV_PAR05 == 1 // Emprestimo
		_cXtipo := "E"
	Case MV_PAR05 == 2 // Antecipacao
		_cXtipo := "N"
	OtherWise
		_cXtipo := "A"
EndCase

BeginSql alias _cAlias
	SELECT ZLN_COD, ZLN_SA2COD, ZLN_SA2LJ, A2_NOME, ZLN_TOTAL, ZLN_JUROS, ZLN_JUROS, ZLN_VLRPAR, ZLN_VENCTO, ZLN_DTCRED, ZLN_OBS, ZLN_PARC
	FROM %Table:ZLN% ZLN, %Table:SA2% SA2
	WHERE ZLN.D_E_L_E_T_ = ' '
	AND SA2.D_E_L_E_T_ = ' '
	AND A2_COD = ZLN_SA2COD
	AND A2_LOJA = ZLN_SA2LJ
	AND ZLN_FILIAL = %xFilial:ZLN%
	AND ZLN_STATUS = %exp:cValToChar(_cTpAplic)%
	AND ZLN_DATA   BETWEEN %exp:MV_PAR01% AND %exp:MV_PAR02%
	AND ZLN_COD	BETWEEN %exp:MV_PAR03% AND %exp:MV_PAR04%
	AND ZLN_TIPO = %exp:_cXtipo%
EndSql

Count to _nQtdReg

ProcRegua( _nQtdReg )

(_cAlias)->( DBGoTop() )
While (_cAlias)->( !Eof() )

	IncProc()
	
	aAdd( aDados , {	IIf( ( _nFatura * 0.5 ) > (_cAlias)->ZLN_VLRPAR , .T. , .F. )				   								,; //01
						(_cAlias)->ZLN_COD											   				   								,; //02
						(_cAlias)->A2_NOME											   				   								,; //03
						(_cAlias)->ZLN_TOTAL																						,; //04
						(_cAlias)->ZLN_PARC																							,; //05
						(_cAlias)->ZLN_JUROS																						,; //06
						(_cAlias)->ZLN_VLRPAR																						,; //07
						(_cAlias)->ZLN_SA2COD																						,; //08
						(_cAlias)->ZLN_SA2LJ																						,; //09
						(_cAlias)->ZLN_VENCTO																						,; //10
						(_cAlias)->ZLN_DTCRED																						,; //11
						(_cAlias)->ZLN_OBS																							}) //12
	
	(_cAlias)->( DBSkip() )
EndDo

(_cAlias)->( DBCloseArea() )

Return

/*
===============================================================================================================================
Programa----------: AGLT016RCL
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 22/03/2019
Descrição---------: Rotina que recalcula o totalizador de acordo com os registros selecionados
Parametros--------: _aLista    - Lista de dados
------------------: _nPosTotal - Posição do valor que deve ser totalizado
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT016RCL( _aLista , _nPosTotal )

Local _nI	:= 0

_nVlrTot := 0

For _nI := 1 To Len( _aLista )

	If _aLista[_nI][01]
		_nVlrTot += _aLista[_nI][_nPosTotal]
	EndIf
	
Next _nI

Return

/*
===============================================================================================================================
Programa----------: AGLT016APR
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 22/03/2019
Descrição---------: Rotina que Processa a gravação das Avaliações/Efetivações
Parametros--------: _aGrava	- Dados para a gravação
------------------: _cTipo	- Tipo de Processamento ( 1 - Aprovação / 2 - Efetivação )
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT016APR( _aGrava , _cTipo )

Local aTCab		:= {}
Local aTItens	:= {}
Local lOk		:= .T.
Local _lValid	:= .T.
Local _nI		:= 0
Local _dMV_DATAFIN:= GetMV( 'MV_DATAFIN' )

ProcRegua( Len( _aGrava ) )

For _nI := 1 to Len(_aGrava)

	IncProc( "Gerando Titulo "+ _aGrava[_nI][02] )
	_lValid := .T.
	
	Begin Transaction
	
	//====================================================================================================
	// Processa os registros selecionados - Aprovar/Efetivar
	//====================================================================================================
	If _aGrava[_nI][01] == .T.
	
		ZLN->( DBSetOrder(1) )
		If ZLN->( DBSeek( xFilial("ZLN") + _aGrava[_nI][02] ) )
			
			//====================================================================================================
			// Valida a data de liberação para não dar erro no ExecAuto
			//====================================================================================================
			If _cTipo == 2
			
				If dDataBase < _dMV_DATAFIN
					MsgStop("Não é possível efetivar a solicitação ["+ ZLN->ZLN_COD +"]!"+ CRLF			 																		+;
								"A data de Efetivação ["+ DToC( dDataBase ) +"] é anterior à data Limite Contábil para lançamentos Financeiros ["+ DToC(_dMV_DATAFIN) +"]."	,;
								"AGLT01614")
					_lValid := .F.
				EndIf
				
				If _lValid .And. dDataBase > ZLN->ZLN_VENCTO
					MsgStop("Não é possível efetivar a solicitação ["+ ZLN->ZLN_COD +"]!"+ CRLF+;
								"A data de Efetivação ["+ DToC( dDataBase ) +"] é posterior à data do 1º Vencimento configurada ["+ DToC( ZLN->ZLN_VENCTO ) +"]."	,;
								"AGLT01615")
					_lValid := .F.
				EndIf
				
			EndIf
			
			If _lValid
			
				ZLN->( RecLock( "ZLN" , .F. ) )
				
		          	If _cTipo == 1 // aprovar
	   				
				     	ZLN->ZLN_STATUS := "2"
				     	ZLN->ZLN_DTAPRO := ddatabase
				  		ZLN->ZLN_USERAP := _cMatUsr
	  					ZLN->ZLN_NUSEAP := _cNUseAp
	  					
	  				ElseIf _cTipo == 2 // efetivar
	  					
	  					ZLN->ZLN_DTLIB	:= dDataBase
	  					
	   					aTCab	:= { ZLN->ZLN_COD , ZLN->ZLN_SA2COD , ZLN->ZLN_SA2LJ , ZLN->ZLN_TOTAL , ZLN->ZLN_DTLIB , ZLN->ZLN_TIPO , ZLN->ZLN_DATA , ZLN->ZLN_DTCRED }
	  					aTItens	:= {}
	  					
	  					ZLQ->( DBSetOrder(1) )
	  					ZLQ->( DBSeek( xFilial("ZLN") + ZLN->ZLN_COD ) )
	  					While ZLQ->( !Eof() ) .And. xFilial("ZLN") + ZLN->ZLN_COD == ZLQ->(ZLQ_FILIAL+ZLQ_COD)
	  					
	  					    aAdd( aTItens , { ZLQ->ZLQ_VECTO , ZLQ->ZLQ_VALOR } )
	  					    
	  					ZLQ->( DBSkip() )
	  					EndDo
						
	  					lOk := .T.
	  					lOk := AGLT016IE2(aTCab,aTItens)
					
	  				EndIf
	  				
				ZLN->( MSUnLock() )
			
			EndIf
			
	    EndIf
	
	//====================================================================================================
	// Processa os registros não selecionados - Reprovar
	//====================================================================================================
	Else

		ZLN->( DBSetOrder(1) )
		If ZLN->( DBSeek( xFilial("ZLN") + _aGrava[_nI][02] ) )
		
			ZLN->( RecLock( "ZLN" , .F. ) )
			
				ZLN->ZLN_DTAPRO := ddatabase
				ZLN->ZLN_STATUS := "3"
				ZLN->ZLN_USERAP := _cMatUsr
				ZLN->ZLN_NUSEAP := _cNUseAp
				
			ZLN->( MSUnLock() )
		
		EndIf	
 		 
	EndIf

	If !lOk
	     DisarmTransaction()
	EndIf
	
	End Transaction
	
Next _nI

Return

/*
===============================================================================================================================
Programa----------: AGLT016MTD
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 22/03/2019
Descrição---------: Rotina que Processa a inversão da seleção ao clicar no cabeçalho do ListBox
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT016MTD()

Local _nI := 0

For _nI := 1 To Len( aDados )

	aDados[_nI][01] := !aDados[_nI][01]

Next _nI

oF3:Refresh()

AGLT016RCL( aDados , 5 )

oVlrTotal:Refresh()

Return

/*
===============================================================================================================================
Programa----------: AGLT016IE2
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 22/03/2019
Descrição---------: Cria titulos no contas a receber referentes ao emprestimo
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT016IE2( aCab , aItens )

Local lok1		:= .T.
Local lok2		:= .T.
Local nRest		:= 0
Local _nI		:= 0
Local _nModAux	:= 0
Local _cModAux	:= ''
Local _cAlias	:= GetNextAlias()
Local _DescHist	:= ""

Private _aAutoSE2	:= {}
Private lMsErroAuto	:= .F.

ProcRegua(2)
IncProc()

//====================================================================================================
// Obtendo Parametos dos EMPRESTIMOS
//====================================================================================================
If aCab[6] == 'E'
	_cPrefixo := SuperGetMV("LT_3EMPPRE",.F.,"G3E")
	_DescHist := "EMPRESTIMO"
EndIf

//====================================================================================================
// Obtendo Parametos dos ADIANTAMENTOS
//====================================================================================================
If aCab[6] == "A"
	_cPrefixo := SuperGetMV("LT_3ADTPRE",.F.,"G3A")
	_DescHist := "ADIANTAMENTO"
EndIf

//====================================================================================================
// Obtendo Parametos das ANTECIPACOES  
//====================================================================================================
If aCab[6] == "N"
	_cPrefixo := SuperGetMV("LT_3ANTPRE",.F.,"G3N")
	_DescHist := "ANTECIPACAO"
EndIf

Begin Transaction

BeginSql alias _cAlias
	SELECT COUNT(1) QTD
	FROM %Table:SE2%
	WHERE D_E_L_E_T_ = ' '
	AND E2_FILIAL = %xFilial:SE2%
	AND E2_PREFIXO = %exp:_cPrefixo%
	AND E2_NUM = %exp:aCab[1]%
	AND E2_TIPO IN( %exp:_cTipo01% , %exp:_cTipo02%)
	AND E2_FORNECE = %exp:aCab[2]%
	AND E2_LOJA = %exp:aCab[3]%
EndSql
If (_cAlias)->QTD == 0
	For _nI := 1 To Len( aItens )
		
		//====================================================================================================
		// Gravando título à pagar
		//====================================================================================================
		If _nI < Len( aItens )
			nValor	:= Round( aCab[4] / Len(aItens) , 2 )
			nRest	+= nValor
		Else
			nValor	:= aCab[4] - nRest
		EndIf
		
		_aAutoSE2 := {}
		
		aAdd( _aAutoSE2 , { "E2_PREFIXO"	, _cPrefixo			, nil } )		
		aAdd( _aAutoSE2 , { "E2_NUM"		, aCab[1]			, nil } )
		aAdd( _aAutoSE2 , { "E2_PARCELA"	, AllTrim(Str(_nI))	, nil } )	
		aAdd( _aAutoSE2 , { "E2_TIPO"		, _cTipo01			, nil } )
		aAdd( _aAutoSE2 , { "E2_NATUREZ"	, _cNaturez			, nil } ) 
		aAdd( _aAutoSE2 , { "E2_FORNECE"	, aCab[2]			, nil } )	
		aAdd( _aAutoSE2 , { "E2_LOJA"		, aCab[3]			, nil } )	
		aAdd( _aAutoSE2 , { "E2_EMISSAO"	, aCab[5]			, nil } )
		aAdd( _aAutoSE2 , { "E2_EMIS1"		, aCab[5]			, nil } )
		aAdd( _aAutoSE2 , { "E2_VENCTO"		, aItens[_nI,1]		, nil } )
		aAdd( _aAutoSE2 , { "E2_VALOR"		, nValor			, nil } )
		aAdd( _aAutoSE2 , { "E2_HIST"		, "GLT "+_DescHist+" TERCEIROS " + AllTrim( Str( _nI ) ) +"/"+ AllTrim( Str( Len( aItens ) ) ) , Nil } )
		aAdd( _aAutoSE2 , { "E2_DATALIB"	, aCab[7]			, nil } )
		aAdd( _aAutoSE2 , { "E2_USUALIB"	, cUserName			, nil } )
		aAdd( _aAutoSE2 , { "E2_ACRESC"		, Round( aItens[_nI][02] - nValor , 2 )			, nil } )
		aAdd( _aAutoSE2 , { "E2_ORIGEM"		, "AGLT016"			, nil } )
				
		lMsErroAuto := .F.
		
		_nModAux	:= nModulo
		_cModAux	:= cModulo
		
		nModulo		:= 6
		cModulo		:= "FIN"
		
		MSExecAuto({|x,y| Fina050(x,y)},_aAutoSE2,3) //Inclusao
		
		If lMsErroAuto
			lok1 := .F.
			MsgStop("Erro ao gravar o Titulo: ("+ _cPrefixo +"-"+ aCab[1] +")! Comunique a área de TI/ERP.","AGLT01616")
			mostraerro()
		EndIf
		
		nModulo := _nModAux
		cModulo := _cModAux
		
	Next _nI
		
	//====================================================================================================
	// Gravando título usado para fazer pagamento ao fornecedor
	//====================================================================================================
	_aAutoSE2 := {}
	
	aAdd( _aAutoSE2 , { "E2_PREFIXO"	, _cPrefixo						, nil } )
	aAdd( _aAutoSE2 , { "E2_NUM"		, aCab[1]						, nil } )
	aAdd( _aAutoSE2 , { "E2_PARCELA"	, "1"							, nil } )
	aAdd( _aAutoSE2 , { "E2_TIPO"		, _cTipo02						, nil } )
	aAdd( _aAutoSE2 , { "E2_NATUREZ"	, _cNaturez						, nil } )
	aAdd( _aAutoSE2 , { "E2_FORNECE"	, aCab[2]						, nil } )
	aAdd( _aAutoSE2 , { "E2_LOJA"		, aCab[3]						, nil } )
	aAdd( _aAutoSE2 , { "E2_EMISSAO"	, aCab[7]						, nil } )
	aAdd( _aAutoSE2 , { "E2_EMIS1"		, aCab[7]						, nil } )
	aAdd( _aAutoSE2 , { "E2_VENCTO"		, aCab[8]						, nil } )
	aAdd( _aAutoSE2 , { "E2_VALOR"		, aCab[4]						, nil } )
	aAdd( _aAutoSE2 , { "E2_HIST"		,"GLT "+_DescHist+" TERCEIROS"	, nil } )
	aAdd( _aAutoSE2 , { "E2_ORIGEM"		,"AGLT016"						, nil } )
	
	lMsErroAuto	:= .F.
	
	_nModAux	:= nModulo
	_cModAux	:= cModulo
	
	nModulo		:= 6
	cModulo		:= "FIN"
	
	MSExecAuto({|x,y| Fina050(x,y)},_aAutoSE2,3) //Inclusao
	
	If lMsErroAuto
	
		lok2 := .F.
		MsgStop("Erro ao gravar o Titulo: ("+ _cPrefixo +"-"+ aCab[1] +")! Comunique a área de TI/ERP.","AGLT01617")
 	   	mostraerro()
	EndIf  		
	
	nModulo := _nModAux
	cModulo := _cModAux
Else
	MsgStop("Já foram encontrados títulos para esse fornecedor e o processo será abortado. Acione a TI/Sistemas.","AGLT01618")
	lok1 := .F.
EndIf
(_cAlias)->(DBCloseArea())

If lok1 .And. lok2
	
	//====================================================================================================
	// Grava solicitação como efetivada
	//====================================================================================================
	ZLN->( DBSetOrder(1) )
	If ZLN->( DBSeek( xFilial('ZLN') + aCab[1] ) )
	
		ZLN->( RecLock( 'ZLN' , .F. ) )
	   	ZLN->ZLN_STATUS := "4"
		ZLN->( MSUnLock() )
	
	Else
			
		MsgStop("Erro ao gravar o Status na Solicitação: ("+ aCab[1] +")! Comunique a área de TI/ERP.","AGLT01619")
		DisarmTransaction()
		lok1:=.F.
	
	EndIf
	
Else
    
	DisarmTransaction()
	
EndIf

End Transaction

Return( lok1 .And. lok2 )

/*
===============================================================================================================================
Programa----------: AGLT016MRK
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 22/03/2019
Descrição---------: Rotina que realiza a marcação dos registros
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT016MRK( nIt , aArray , oGet , nOpc , nPos )

Local _nI      := 0
Local lMarca := If( !aArray[nIt][nPos] , .T. , .F. )

If nOpc == 1 // Marca/Desmarca
	aArray[nIt][nPos] := !aArray[nIt][nPos]
Else // Marca Todos/Desmarca Todos
	For _nI := 1 To Len(aArray)
		aArray[_nI,nPos] := lMarca
	Next _nI
EndIf

If oGet != Nil
	oGet:Refresh()
EndIf

Return( aArray )

/*
===============================================================================================================================
Programa----------: AGLT016V
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 22/03/2019
Descrição---------: Rotina que realiza datas
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT016V()

Local _lRet		:= .T.
Local _cCampo	:= ReadVar()
Local _dDtAux	:= &( _cCampo )

If Upper( AllTrim( _cCampo ) ) == "M->ZLN_DTCRED"
	If _dDtAux < dDataBase
		MsgStop("Não é permitido informar uma data de crédito menor que a data atual! Verique as datas informadas!","AGLT01620")
		_lRet := .F.
	ElseIf !Empty(M->ZLN_VENCTO) .And. _dDtAux > M->ZLN_VENCTO
		MsgStop("Não é permitido informar uma data de Crédito maior que a data de vencimento! Verique as datas informadas!","AGLT01621")
		_lRet := .F.
	EndIf
EndIf

If Upper( AllTrim( _cCampo ) ) == "M->ZLN_VENCTO"
	If _dDtAux < M->ZLN_DTCRED
		MsgStop("Não é permitido informar uma data de 1º vencimento menor que a data do Crédito! Verique as datas informadas!","AGLT01622")	
		_lRet := .F.
	EndIf
EndIf

Return( _lRet )

/*
===============================================================================================================================
Programa----------: AGLT016B
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 22/03/2019
Descrição---------: Rotina que possibilita realizar a transferencia do emprestimo para determinado produtor informado.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT016B()

Local oDlg		:= Nil
Local oGDescri	:= Nil
Local oGEmprest	:= Nil
Local oGFornec	:= Nil
Local oGLjForn	:= Nil
Local oMObs		:= Nil
Local oPriVenct	:= Nil
Local oSay1		:= Nil
Local oSay2		:= Nil
Local oSay3		:= Nil
Local oSay5		:= Nil
Local oSay6		:= Nil
Local oSay7		:= Nil
Local oFont12b	:= Nil
Local nopc		:= 0  
Local _aArea	:= FWGetArea()       
Local lVldTrans	:= .F.   
Local cGDescri	:= Space(70)
Private cGEmprest	:= Space(09)
Private cGFornec	:= Space(06)
Private cGLjForn	:= Space(04)  
Private cMObs		:= ""    
Private dDtPriVen	:= dDataBase
Private _cCodOrig	:= ""	// Armazena o codigo do fornecedor do emprestimo de origem
Private _cljOrig	:= ""	// Armazena o codigo da loja do fornecedor do emprestimo de origem  
Private _nJuros		:= 0	// Armazena o % de juros para replicar para o emprestimo de destino 
Private _aTitulos	:= {}	// Armazena os títulos e suas parcelas com os respectivos valores    
Private lDeuErro	:= .F.	// Controla se deu erro em algum ponto do sistema
Private _cTipo		:= ""
Private _cZLNTipo	:= ""
Define Font oFont12b   Name "Courier New"       Size 0,-12 Bold  // Tamanho 12 Negrito

// Monta tela para configuração da transferência
DEFINE MSDIALOG oDlg TITLE "Transferência de Empréstimos" FROM 000,000 TO 350,425 COLORS 0,16777215 PIXEL

    @ 039, 012 Say oSay1     PROMPT "Empréstimo:"			SIZE 031,007 OF oDlg COLORS 0,16777215 PIXEL
    @ 059, 012 Say oSay2     PROMPT "Fornecedor:"			SIZE 031,007 OF oDlg COLORS 0,16777215 PIXEL
    @ 059, 120 Say oSay3     PROMPT "Loja:"       			SIZE 025,007 OF oDlg COLORS 0,16777215 PIXEL
    @ 079, 012 Say oSay5     PROMPT "Descrição:"  			SIZE 025,007 OF oDlg COLORS 0,16777215 PIXEL
    @ 099, 012 Say oSay6     PROMPT "1 Vencto: "  			SIZE 030,007 OF oDlg COLORS 0,16777215 PIXEL
    @ 119, 012 Say oSay7     PROMPT "Observação:"			SIZE 030,007 OF oDlg COLORS 0,16777215 PIXEL
    
    @ 035, 044 MSGET oGEmprest VAR cGEmprest	SIZE 060,010 OF oDlg COLORS 0, 16777215 PIXEL F3 "ZLN" Valid !Empty(cGEmprest) .And. ExistCPO("ZLN", cGEmprest, 1) 
    @ 055, 044 MSGET oGFornec  VAR cGFornec		SIZE 060,010 OF oDlg COLORS 0, 16777215 PIXEL F3 "SA2" Valid !Empty(cGFornec) .And. AGLT016VLF(cGFornec, @cGLjForn, @cGDescri)
    @ 055, 145 MSGET oGLjForn  VAR cGLjForn		SIZE 060,010 OF oDlg COLORS 0, 16777215 PIXEL Valid !Empty(cGLjForn) .And. AGLT016VLF(cGFornec, @cGLjForn, @cGDescri)
    @ 075, 044 MSGET oGDescri  VAR cGDescri		SIZE 160,010 OF oDlg COLORS 0, 16777215 PIXEL WHEN .F.
    @ 095, 044 MSGET oPriVenct VAR dDtPriVen	SIZE 060,010 OF oDlg COLORS 0, 16777215 PIXEL Valid !Empty(dDtPriVen)
    @ 115, 044 GET	 oMObs     VAR cMObs		SIZE 160,033 OF oDlg MULTILINE COLORS 0, 16777215 HSCROLL PIXEL Valid !Empty(cMObs)

ACTIVATE MSDIALOG oDlg CENTERED ON INIT EnchoiceBar(oDlg,{|| MsgRun("Realizando a validação da transferência...",,{||CursorWait(),lVldTrans:=VldTransf(cGEmprest,cGFornec,cGLjForn,cMObs,dDtPriVen),CursorArroIIf}),IIf(lVldTrans,Eval({|| nopc:=1,oDlg:End()}),)}, {||oDlg:End()},,)    

// Caso confirmado, Processa a transferência
If nopc == 1
 	MsgRun( "Processando a transferência..." , 'Aguarde!' , {|| CursorWait() , ProcTransf() , CursorArrow() } )
EndIf

FWRestArea(_aArea)

Return

/*
===============================================================================================================================
Programa----------: VldTransf
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 22/03/2019
Descrição---------: Rotina que valida os dados informados pelo usuário
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function VldTransf( cCodEmpres , cCodForn , cLjForn , cObs , dt1Vencto)
      
Local _lRet		:= .T.
Local _cAlias	:= GetNextAlias()

If dt1Vencto < dDataBase
	MsgStop("A data do primeiro vencimento não pode ser menor que a data atual!","AGLT01623")
	_lRet := .F.
EndIf
			
ZLN->( DBSetOrder(1) )
ZLN->(DBSeek( xFilial("ZLN") + cCodEmpres ))
	_cCodOrig	:= ZLN->ZLN_SA2COD 
	_cljOrig	:= ZLN->ZLN_SA2LJ
	_nJuros		:= ZLN->ZLN_JUROS
	_cZLNTipo	:= ZLN->ZLN_TIPO
	//====================================================================================================
	// Obtendo Parametos dos EMPRESTIMOS
	//====================================================================================================
	If ZLN->ZLN_TIPO == 'E'
		_cPrefixo := SuperGetMV("LT_3EMPPRE",.F.,"G3E")
		_cTipo	:= "Empréstimo"
	//====================================================================================================
	// Obtendo Parametos dos ADIANTAMENTOS
	//====================================================================================================
	ElseIf ZLN->ZLN_TIPO == 'A'
		_cPrefixo := SuperGetMV("LT_3ADTPRE",.F.,"G3A")
		_cTipo	:= "Adiantamento"
	//====================================================================================================
	// Obtendo Parametos das ANTECIPACOES  
	//====================================================================================================
	ElseIf ZLN->ZLN_TIPO == "N"
		_cPrefixo := SuperGetMV("LT_3ANTPRE",.F.,"G3N")
		_cTipo	:= "Antecipação"
	EndIf
//================================================
// Valida se está efetivado
//================================================
If _lRet .And. !(ZLN->ZLN_STATUS == '4')
	MsgStop("Somente " + _cTipo + " efetivado(a) pode ser transferido(a)!","AGLT01624")
	_lRet := .F.
EndIf	

//======================================================================================
// Verifica se foi informado o mesmo Fornecedor no emprestimo de origem com o de destino
//======================================================================================
If _lRet .And. cCodForn + cLjForn == ZLN->( ZLN_SA2COD + ZLN_SA2LJ )
	MsgStop("Não é possível transferir um(a) " + _cTipo + "  para o mesmo Fornecedor já registrado!","AGLT01625")
	_lRet := .F.	
EndIf
	
If _lRet
	//======================================================================================
	// Verifica se o emprestimo gerou baixas, se não terá que ser excluído e não transferido
	//======================================================================================
	BeginSql Alias _cAlias
	 SELECT COUNT(1) NREG
	   FROM %Table:SE2% SE2
	  WHERE SE2.D_E_L_E_T_ = ' '
	    AND SE2.E2_FILIAL = %xFilial:SE2%
	    AND ((SE2.E2_PREFIXO = %exp:_cPrefixo%
	    	AND SE2.E2_TIPO = %exp:_cTipo01%)
	    	OR (SE2.E2_PREFIXO = %exp:_cPrefixo%
	    	AND SE2.E2_TIPO = %exp:_cTipo02%))
	    AND SE2.E2_NUM = %exp:cCodEmpres%
	    AND SE2.E2_FORNECE = %exp:_cCodOrig%
	    AND SE2.E2_LOJA = %exp:_cljOrig%
	    AND SE2.E2_BAIXA <> ' '
	EndSql
	
	If (_cAlias)->NREG == 0
		MsgStop("Não é permitido transferir " + _cTipo + "  sem baixas Financeiras! Para esse caso deverá ser excluído "+;
				"o(a) " + _cTipo + "  atual e incluído um novo manualmente para o fornecedor desejado.","AGLT01626")
		_lRet := .F.
	EndIf
	
	(_cAlias)->( DBCloseArea() )

EndIf
	
Return( _lRet )

/*
===============================================================================================================================
Programa----------: ProcTransf
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 22/03/2019
Descrição---------: Rotina que Processa a transferência do empréstimo
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ProcTransf()

Local _cAlias		:= GetNextAlias()
Local _nSaldoTit	:= 0
Local _nY			:= 0

Private nTotSaldo	:= 0
Private _nTotAcDc	:= 0
Private _nCodEmp	:= 0

//========================================================
// Verifica as NDF dos titulos do emprestimo no financeiro
//========================================================
BeginSql Alias _cAlias

SELECT SE2.E2_FILIAL,
       SE2.E2_PREFIXO,
       SE2.E2_TIPO,
       SE2.E2_NUM,
       SE2.E2_PARCELA,
       SE2.E2_FORNECE,
       SE2.E2_LOJA,
       SA2.A2_NOME,
       SE2.E2_TXMOEDA,
       SE2.E2_BAIXA,
       SE2.E2_NATUREZ,
       SE2.E2_VENCREA,
       SE2.E2_SALDO,
       SE2.E2_SDACRES,
       SE2.E2_SDDECRE,
       SE2.E2_VALOR,
       SE2.E2_DECRESC,
       SE2.E2_ACRESC,
       SE2.E2_VALJUR,
       SE2.E2_PORCJUR,
       SE2.E2_EMISSAO,
       SE2.E2_VENCTO,
       SE2.E2_DATALIB,
       SE2.R_E_C_N_O_ RECNOSE2
  FROM %Table:SE2% SE2, %Table:SA2% SA2
 WHERE SE2.D_E_L_E_T_ = ' '
   AND SA2.D_E_L_E_T_ = ' '
   AND SA2.A2_COD = SE2.E2_FORNECE
   AND SA2.A2_LOJA = SE2.E2_LOJA
   AND SE2.E2_FILIAL = %xFilial:SE2%
   AND SE2.E2_PREFIXO = %exp:_cPrefixo%
   AND SE2.E2_TIPO = %exp:_cTipo01%
   AND SE2.E2_NUM = %exp:cGEmprest%
   AND SE2.E2_FORNECE = %exp:_cCodOrig%
   AND SE2.E2_LOJA = %exp:_cljOrig%
 ORDER BY SE2.E2_VENCTO
EndSql

While (_cAlias)->( !Eof() )

	_nSaldoTit := (_cAlias)->(E2_SALDO + E2_SDACRES - E2_SDDECRE)
	
	//================================================================
	// Somente se houver saldo no Titulo corrente para ser considerado
	//================================================================
	If Abs(_nSaldoTit) > 0.0001
		
		nTotSaldo += _nSaldoTit
		_nTotAcDc += (_cAlias)->(E2_SDACRES - E2_SDDECRE)
		
		aAdd( _aTitulos , {	(_cAlias)->E2_PREFIXO																	,; //01 - Prefixo
							(_cAlias)->E2_TIPO																		,; //02 - Tipo
							(_cAlias)->E2_NUM																		,; //03 - Numero do Titulo
							(_cAlias)->E2_PARCELA																	,; //04 - Parcela do Titulo
							(_cAlias)->E2_FORNECE																	,; //05 - Código do Fornecedor
							(_cAlias)->E2_LOJA																		,; //06 - Loja do Fornecedor
							(_cAlias)->E2_VENCREA																	,; //07 - Vencimento Real
							(_cAlias)->E2_VENCTO																	,; //08 - Vencimento
							(_cAlias)->E2_SALDO																		,; //09 - Saldo
							(_cAlias)->A2_NOME																		,; //10 - Nome do Fornecedor
							(_cAlias)->E2_EMISSAO																	,; //11 - Data de Emissão
							(_cAlias)->E2_DATALIB																	,; //12 - Data de Liberação
							(_cAlias)->E2_SDACRES																	,; //13 - Acrescimo (no acrescimo uso apenas o saldo)
							(_cAlias)->E2_SDDECRE																	}) //14 - Decrescimo (no decrescimo uso apenas o saldo)
							
	EndIf

	(_cAlias)->( DBSkip() )
EndDo

(_cAlias)->( DBCloseArea() )

//=================================================
// Não podem ser transferidos empréstimos sem saldo
//=================================================
If nTotSaldo == 0
	MsgStop("Não é permitido transferir " + _cTipo + "  que não possui mais saldo em aberto!",;
			"Para esse caso deverá ser excluído o(a) " + _cTipo + "  atual e incluído um novo manualmente para o fornecedor desejado.","AGLT01627")
Else
	
	//===========================================================================================
	// Alteracao na data de vencimento de acordo com o primeiro vencimento fornecido pelo usuario
	//===========================================================================================
	
	For _nY := 1 To Len(_aTitulos)
	
		_aTitulos[_nY][8] := DToS(IIf(_nY==1,dDtPriVen, MonthSum(dDtPriVen,_nY-1)))

	Next _nY
	
	Begin Transaction
	
		//=====================================================
		// Realiza as baixas dos titulos do emprestimo original
		//=====================================================
		For _nY := 1 To Len(_aTitulos)
		    
			MsgRun( "Processando baixas no(a) " + _cTipo + "  de origem..." , 'Aguarde!' , {|| CursorWait() , BaixaSE2(_aTitulos[_nY][9]+_aTitulos[_nY][13]-_aTitulos[_nY][14],_aTitulos[_nY][1],_aTitulos[_nY][3],_aTitulos[_nY][4],_aTitulos[_nY][2],_aTitulos[_nY][5],_aTitulos[_nY][6],_aTitulos[_nY][10]) , CursorArrow() } )
			
			// Verifica se ocorreu erro durante a baixa
			If lDeuErro
				DisarmTransaction()
				Exit
			EndIf
		
		Next _nY
		
		//============================================================================
		//Caso nao ocorra nenhum erro nas baixas realiza a inclusao do novo emprestimo
		//============================================================================
        If !lDeuErro
        
			//===================================================
			// Seleciona o codigo do novo emprestimo a ser gerado
			//===================================================
        	_nCodEmp := GetSx8Num("ZLN","ZLN_COD")
        	
        	//==============================
        	// Insere os dados do emprestimo
        	//==============================
        	MsgRun( "Processando a inclusão do novo(a) " + _cTipo + " ..." , 'Aguarde!' , {|| CursorWait() , incEmprest() , CursorArrow() } )
        	
			//=============================================================
			// Se nao ocorrer erro abre para visualizacao o novo emprestimo
			//=============================================================
        	If !lDeuErro
        		
				//=============================================
        		// Seta o emprestimo de origem como transferido
				//=============================================
        		ZLN->( DBSetOrder(1) )
        		If ZLN->( DBSeek( xFilial("ZLN") + cGEmprest ) )
        			
        			RecLock( "ZLN" , .F. )
					
					ZLN->ZLN_STATUS := "5"
					ZLN->ZLN_CODTRA := _nCodEmp
					ZLN->ZLN_USRTRA := _cMatUsr
					ZLN->ZLN_DATTRA := Date()
					ZLN->ZLN_HORTRA := Time()
					ZLN->ZLN_OBSTRA := cMObs
					
        			ZLN->( MSUnLock() )
        			
        		EndIf
        		
       			MsgRun( "Processando inclusões no Financeiro..." , 'Aguarde!' , {|| CursorWait() , IncSE2() , CursorArrow() } )
        		
        		//===========================================================
       			// Se nao ocorrer erro na inclusao das NDF do novo emprestimo
       			//===========================================================
	        	If !lDeuErro
	        		ConfirmSX8()
	        		MsgInfo("A transferência do(a) " + _cTipo + "  foi realizada com sucesso!","AGLT01628")
	        	Else
	        		RollBackSX8()
	        		DisarmTransaction()
	        	EndIf
		        
		    Else
			    RollBackSX8()
		    	DisarmTransaction()
        	EndIf
        	
        EndIf
	
	End Transaction

EndIf

Return

/*
===============================================================================================================================
Programa----------: BaixaSE2
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 22/03/2019
Descrição---------: Rotina que Processa as baixas de Títulos via ExecAuto
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function BaixaSE2( nVlrBx , cPrefixo , cNroTit , cParcela , cTipo , cFornec , cLjForn , cA2Nome )

Local nModAnt      := nModulo
Local cModAnt      := cModulo
Local cMotBaixa    := GetMv("IT_MOTBXTR")
Local cHist        := "Transferencia " + _cTipo

Private lMsErroAuto:= .F.
Private lMsHelpAuto:= .T.

//==========================================================
// Tratamento para liberar o titulo para baixa no financeiro
//==========================================================
DBSelectArea("SE2")
SE2->( DBSetOrder(1) )
If SE2->( DBSeek( xFilial("SE2") + cPrefixo + cNroTit + cParcela + cTipo + cFornec + cLjForn ) )

	If Empty(SE2->E2_DATALIB) //Se nao foi liberado ainda
	
		RecLock("SE2",.F.)
		SE2->E2_DATALIB := dDataBase
		SE2->E2_USUALIB := cUserName
	
	EndIf
	
EndIf

aTitulo := {	{ "E2_PREFIXO"		, cPrefixo							, Nil },;
				{ "E2_NUM"			, cNroTit							, Nil },;
				{ "E2_PARCELA"		, cParcela							, Nil },;
				{ "E2_TIPO"			, cTipo								, Nil },;
				{ "E2_FORNECE"		, cFornec							, Nil },;
				{ "E2_LOJA"			, cLjForn							, Nil },;
				{ "AUTBANCO"		, ""								, Nil },;
				{ "AUTAGENCIA"		, ""								, Nil },;
				{ "AUTCONTA"		, ""								, Nil },;
				{ "AUTCHEQUE"		, ""								, Nil },;
				{ "AUTMOTBX"		, cMotBaixa							, Nil },;
				{ "AUTDTBAIXA"		, dDataBase							, Nil },;
				{ "AUTDTCREDITO"	, dDataBase							, Nil },;
				{ "AUTBENEF"		, cFornec +" - "+ AllTrim(cA2Nome)	, Nil },;
				{ "AUTHIST"			, cHist								, Nil },;
				{ "AUTVLRPG"		, nVlrBx							, Nil } }

//==============================================================
// Altera o modulo para Financeiro, senao o SigaAuto nao executa
//==============================================================
nModulo := 6
cModulo := "FIN"

// SigaAuto de Baixa de Contas a Pagar
MSExecAuto( {|x,y| Fina080(x,y) } , aTitulo , 3 )

SE2->( MSUnLock() )

// Restaura o modulo em uso
nModulo := nModAnt
cModulo := cModAnt

// Verifica se houve erro no SigaAuto, caso haja mostra o erro
If lMsErroAuto
	lDeuErro := .T.
	MsgStop("Existe uma não conformidade no SigaAuto de Baixa de Contas a Pagar. Chave "+	xFilial("SE2")+cPrefixo+cNroTit+cParcela+cTipo+cFornec+cLjForn +;
			" Após confirmar esta tela, sera apresentada a tela de Não Conformidade do SigaAuto.","AGLT01629")
	MostraErro()
EndIf

Return

/*
===============================================================================================================================
Programa----------: incEmprest
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 22/03/2019
Descrição---------: Rotina que Processa a inclusão de empréstimos
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function incEmprest() 

Local _nX := 0

DBSelectArea("SA2")
SA2->( DBSetOrder(1) )
If SA2->( DBSeek( xFilial("SA2") + cGFornec + cGLjForn ) )

	ZLN->( RecLock( "ZLN" , .T. ) )
	
		ZLN->ZLN_FILIAL	:= xFilial("ZLN")
		ZLN->ZLN_COD	:= _nCodEmp
		ZLN->ZLN_SA2COD	:= SA2->A2_COD
		ZLN->ZLN_SA2LJ	:= SA2->A2_LOJA
		ZLN->ZLN_SA2NOM	:= SA2->A2_NOME
		ZLN->ZLN_DATA	:= dDataBase
		ZLN->ZLN_OBS	:= "Transferência: "+ cGEmprest
		ZLN->ZLN_VENCTO	:= SToD( _aTitulos[1][8] ) // Passa o menor vencimento
		ZLN->ZLN_TOTAL	:= nTotSaldo-_nTotAcDc
		ZLN->ZLN_PARC	:= Len( _aTitulos )
		ZLN->ZLN_JUROS	:= _nJuros
		ZLN->ZLN_VLRPAR	:= 0 // O valor da parcela pode variar neste caso diante disto eh passado o valor 0
		ZLN->ZLN_STATUS	:= "6"
		ZLN->ZLN_USER	:= _cMatUsr
		ZLN->ZLN_NUSER	:= _cNUseAp
		ZLN->ZLN_PAGTO	:= nTotSaldo    // Valor total a pagar pelo fornecedor
		ZLN->ZLN_DTLIB	:= dDataBase
		ZLN->ZLN_TIPO	:= _cZLNTipo
		ZLN->ZLN_DTCRED	:= CtoD("")
		ZLN->ZLN_CODTRA	:= cGEmprest
		ZLN->ZLN_USRTRA	:= _cMatUsr
		ZLN->ZLN_DATTRA	:= Date()
		ZLN->ZLN_HORTRA	:= Time()
		ZLN->ZLN_OBSTRA	:= cMObs
	
	ZLN->( MSUnLock() )
	
	//=======================================
	// Gera as NDF que o fornecedor ira pagar
	//=======================================
	For _nX := 1 to Len( _aTitulos )
	
		RecLock( "ZLQ" , .T. )
			
		    ZLQ->ZLQ_FILIAL	:= xFilial("ZLQ")
			ZLQ->ZLQ_COD	:= _nCodEmp
			ZLQ->ZLQ_ITEM	:= StrZero( _nX , 3 )
			ZLQ->ZLQ_VECTO	:= SToD( _aTitulos[_nX][8] )
			ZLQ->ZLQ_VALOR	:= _aTitulos[_nX][9]+_aTitulos[_nX][13]+_aTitulos[_nX][14]
		    ZLQ->ZLQ_CHAVET	:= xFilial("ZLQ") + _aTitulos[_nX][1] + _aTitulos[_nX][3] + _aTitulos[_nX][4] + _aTitulos[_nX][2] + _aTitulos[_nX][5] + _aTitulos[_nX][6]
		
		ZLQ->( MSUnLock() )
	
	Next _nX
		
	ConfirmSx8()
	
//=========================================================
// Nao foi encontrado o fornecedor do emprestimo de destino
//=========================================================
Else    
	lDeuErro := .T.
	MsgStop("Nao foi encontrado os dados do cadastro do fornecedor indicado para gerar o(a) " + _cTipo + "  de transferência. Favor checar se os dados foram corretamente inseridos.","AGLT01630")
EndIf

Return

/*
===============================================================================================================================
Programa--------: incSE2
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 22/03/2019
Descrição-------: Cria titulos no contas a pagar referentes a NDF'S do novo emprestimo
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function IncSE2()

Local _nX 		:= 0
Local _cAlias   := GetNextAlias()

Private _aAutoSE2   := {}
Private lMsErroAuto := .F.

BeginSql alias _cAlias
	SELECT COUNT(1) NREG
	FROM %Table:SE2%
	WHERE D_E_L_E_T_ = ' '
	AND E2_FILIAL = %xFilial:SE2%
	AND E2_PREFIXO = %exp:_cPrefixo%
	AND E2_NUM = %exp:_nCodEmp%
	AND E2_FORNECE = %exp:cGFornec%
	AND E2_LOJA = %exp:cGLjForn%
	AND E2_TIPO = %exp:_cTipo01%
EndSql

If(_cAlias)->NREG == 0

	For _nX := 1 to Len( _aTitulos )
	
		_aAutoSE2 := {}
		
		aAdd( _aAutoSE2 , { "E2_PREFIXO"	, _cPrefixo									, Nil } )
		aAdd( _aAutoSE2 , { "E2_NUM"		, _nCodEmp									, Nil } )
		aAdd( _aAutoSE2 , { "E2_PARCELA"	, AllTrim( Str(_nX) )						, Nil } )
		aAdd( _aAutoSE2 , { "E2_TIPO"		, _cTipo01									, Nil } )
		aAdd( _aAutoSE2 , { "E2_NATUREZ"	, _cNaturez									, Nil } )
		aAdd( _aAutoSE2 , { "E2_FORNECE"	, cGFornec									, Nil } )
		aAdd( _aAutoSE2 , { "E2_LOJA"		, cGLjForn									, Nil } )
		aAdd( _aAutoSE2 , { "E2_EMISSAO"	, dDataBase									, Nil } )
		aAdd( _aAutoSE2 , { "E2_EMIS1"		, dDataBase									, Nil } )
		aAdd( _aAutoSE2 , { "E2_VENCTO"		, DataValida(SToD( _aTitulos[_nX][8] ))		, Nil } )
		aAdd( _aAutoSE2 , { "E2_VALOR"		, _aTitulos[_nX][9]							, Nil } )
		aAdd( _aAutoSE2 , { "E2_HIST"		, "TRANSFERENCIA " + Upper(_cTipo) + ":" + cGEmprest	, Nil } )
		aAdd( _aAutoSE2 , { "E2_DATALIB"	, SToD(_aTitulos[_nX][12])					, Nil } )
		aAdd( _aAutoSE2 , { "E2_USUALIB"	, cUserName									, Nil } )
		aAdd( _aAutoSE2 , { "E2_ACRESC"		, _aTitulos[_nX][13]						, Nil } )
		aAdd( _aAutoSE2 , { "E2_DECRESC"	, _aTitulos[_nX][14]						, Nil } )
		aAdd( _aAutoSE2 , { "E2_ORIGEM"		, "AGLT016"									, Nil } )
		
		lMsErroAuto := .F.
		
		nModulo := 6
		cModulo := "FIN"
		
		MSExecAuto( {|x,y| Fina050( x , y ) } , _aAutoSE2 , 3 ) //Inclusao
		
		If lMsErroAuto 
			lDeuErro := .T.
	 	   	MsgStop("Não foi possivel gravar os dados! Erro ao gravar Título: "+ _cPrefixo +"-"+ _nCodEmp + " Comunique ao Suporte!!!","AGLT01631")
	 	   	Mostraerro()
	 	   	Exit
		EndIf
		
		nModulo := 2
		cModulo := "COM"
		
	Next _nX
	
Else
	lDeuErro := .T.
   	MsgStop("Já existe no financeiro um título com os dados: "+ _cPrefixo +"-"+ _nCodEmp + "Comunique ao Suporte!!!","AGLT01632")
EndIf

(_cAlias)->( DBCloseArea() )

Return( .T. )

/*
===============================================================================================================================
Programa--------: AGLT016VLF
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 22/03/2019
Descrição-------: Valida o fornecedor
Parametros------: cGFornec , cGLjForn , cGDescri
Retorno---------: _lRet
===============================================================================================================================
*/
Static Function AGLT016VLF( cGFornec , cGLjForn , cGDescri )

Local _lRet := .T.
Local _cChave := IIf(Empty(cGLjForn),cGFornec,cGFornec+cGLjForn)

DBSelectArea("SA2")
SA2->( DBSetOrder(1) )
If SA2->( DBSeek( xFilial("SA2") + _cChave ) )
	If !Empty(cGLjForn)
		If SA2->A2_MSBLQL == '1'
			MsgStop( "Não é possível transferir um(a) " + _cTipo + "  para um fornecedor inativo no Leite!"+; 
					" Para processar a transferência informe um fornecedor ativo na Gestão do Leite.","AGLT01633")
			_lRet := .F.
		EndIf
	EndIf
	cGLjForn:= SA2->A2_LOJA
	cGDescri := SA2->A2_NOME		
Else
	MsgStop("Código de Fornecedor/Loja inválido! Informe um código de fornecedor que seja válido e esteja ativo.","AGLT01634")
	_lRet := .F.
EndIf

Return( _lRet )

/*
===============================================================================================================================
Programa----------: AGLT016C
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 22/03/2019
Descrição---------: Rotina desenvolvida para realizar o estorno de uma transferencia de emprestimo
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT016C()
                               
Local lProcEstor	:= .F.
Private cPerg		:= "AGLT016C"   
Private lDeuErro	:= .F.     
Private _cCodEmp	:= ""
Private _cCodForn	:= ""
Private _cLjForn	:= ""     
Private _cCodEmpOr	:= ""
Private _cTipo		:= ""

If !Pergunte(cPerg,.T.) 
     Return
EndIf      

DBSetOrder(1)

Processa( {||lProcEstor:=vldEstorno()}/*bAction*/, "Aguarde..."/*cTitle */, "Processando validações para realizar o estorno!"/*cMsg */,.F./*lAbort */)
     
//Verifica se eh possivel processar o estorno da transferencia do emprestimo
If lProcEstor
	Processa( {||ProcEstor()}/*bAction*/, "Aguarde..."/*cTitle */, "Processando o estorno da transferência!"/*cMsg */,.F./*lAbort */)
EndIf

Return       

/*
===============================================================================================================================
Programa----------: vldEstorno
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 22/03/2019
Descrição---------: Valida se pode ser reaizado o estorno da transferência
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function vldEstorno()   

Local _lRet		:= .T.
Local _cAlias	:= GetNextAlias()

If ZLN->(DBSeek(xFilial('ZLN')+MV_PAR01)) .And. ZLN->ZLN_STATUS == "6"
	_cCodEmp	:= ZLN->ZLN_COD   //Armazena o codigo do emprestimo transferido a ser estornado
	_cCodForn	:= ZLN->ZLN_SA2COD
	_cLjForn	:= ZLN->ZLN_SA2LJ      
	_cCodEmpOr	:= ZLN->ZLN_CODTRA //Armazena o codigo do emprestimo de origem
	//====================================================================================================
	// Obtendo Parametos dos EMPRESTIMOS
	//====================================================================================================
	If ZLN->ZLN_TIPO == 'E'
		_cPrefixo := SuperGetMV("LT_3EMPPRE",.F.,"G3E")
		_cTipo	:= "Empréstimo"
	//====================================================================================================
	// Obtendo Parametos dos ADIANTAMENTOS
	//====================================================================================================
	ElseIf ZLN->ZLN_TIPO == 'A'
		_cPrefixo := SuperGetMV("LT_3ADTPRE",.F.,"G3A")
		_cTipo	:= "Adiantamento"
	//====================================================================================================
	// Obtendo Parametos das ANTECIPACOES  
	//====================================================================================================
	ElseIf ZLN->ZLN_TIPO == "N"
		_cPrefixo := SuperGetMV("LT_3ANTPRE",.F.,"G3N")
		_cTipo	:= "Antecipação"
	EndIf
	
	//Verifica se o mvimento a ser estornado sofre alguma baixa, pois somente podera ser realizado o estorno de um movimento que não sofreu nenhuma baixa
	BeginSql alias _cAlias
		SELECT COUNT(1) QTD
		FROM %Table:SE2%
		WHERE D_E_L_E_T_ = ' '
		AND E2_FILIAL = %xFilial:SE2%
		AND E2_PREFIXO = %exp:_cPrefixo%
		AND E2_NUM = %exp:_cCodEmp%
		AND E2_FORNECE = %exp:_cCodForn%
		AND E2_LOJA = %exp:_cLjForn%
		AND E2_VALOR <> E2_SALDO
	EndSql
	
	If (_cAlias)->QTD > 0
		MsgStop("Não poderá ser realizado o estorno do(a) " + _cTipo + " informado! " + _cTipo + " " + MV_PAR01 + " encontra-se com baixa(s) realizada(s) no financeiro.","AGLT01635")
		_lRet:= .F.
	EndIf	 
Else
	MsgStop("Esta rotina somente poderá ser executada para movimentos que foram inseridos através da rotina de transferência." +;
			"Favor verificar o status do movimento que esteja tentando efetivar o seu estorno, ou se o codigo fornecido do movimento a realizar o estorno esteja corretamente preenchido.","AGLT01636")
	_lRet:= .F.
EndIf

(_cAlias)->(DBCloseArea())

Return _lRet     

/*
===============================================================================================================================
Programa----------: ProcEstor
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 22/03/2019
Descrição---------: Processa o estorno
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ProcEstor

	Begin Transaction

		Processa( {||ExcluiSE2()}/*bAction*/, "Aguarde..."/*cTitle */, "Processando a exclusão dos dados financeiro do(a) " + _cTipo/*cMsg */,.F./*lAbort */)

		//=============================================================================================================
		//Caso encontre problemas na exclusao dos titulos no financeiro dos emprestimo transferido desarma a transacao
		//=============================================================================================================
		If lDeuErro
			DisarmTransaction()
			//===========================================================================================================================================
	   		//Caso nao encontre problema na exclusao dos titulos no financeiro realiza o cancelamento das baixas do emprestimo de origem da transferencia
			//===========================================================================================================================================
		Else
			Processa( {||CancBxSE2()}/*bAction*/, "Aguarde..."/*cTitle */, "Processando o cancelamento das baixas do financeiro..."/*cMsg */,.F./*lAbort */)
			If lDeuErro
				DisarmTransaction()  
			Else    
				//Efetua o delete do emprestimo transferido e ajusta algumas informacoes no emprestimo de origem
				Processa( {||ProcZLN()}/*bAction*/, "Aguarde..."/*cTitle */, "Processando atualização da tabela de " + _cTipo/*cMsg */,.F./*lAbort */)
				If lDeuErro
					DisarmTransaction()
				Else
					MsgInfo("O estorno da transferencia do(a) " + _cTipo + " foi realizado com sucesso!")
				EndIf	
			EndIf	
		EndIf	
	
	End Transaction  

Return

/*
===============================================================================================================================
Programa----------: ExcluiSE2
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 22/03/2019
Descrição---------: Exlcui titulo no contas a pagar via SigaAuto
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ExcluiSE2()     

Local nModAnt	:= nModulo
Local cModAnt	:= cModulo
Local _aArea	:= FWGetArea()
Local _aAutoSE2	:= {}
Local _nContReg	:= 0
Local _cAlias	:= GetNextAlias()
Private lMsErroAuto:= .F.
Private lMsHelpAuto:= .T. 

BeginSql alias _cAlias
	SELECT E2_PREFIXO, E2_NUM, E2_PARCELA, E2_TIPO, E2_FORNECE, E2_LOJA
	FROM %Table:SE2%
	WHERE D_E_L_E_T_ = ' '
	AND E2_FILIAL = %xFilial:SE2%
	AND E2_PREFIXO = %exp:_cPrefixo%
	AND E2_NUM = %exp:_cCodEmp%
	AND E2_FORNECE = %exp:_cCodForn%
	AND E2_LOJA = %exp:_cLjForn%
EndSql
	
COUNT TO _nContReg //Contabiliza o numero de registros encontrados pela query  
(_cAlias)->(DBGoTop())

//=============================================
//Econtrou registros para realizar a exclusao
//=============================================
If _nContReg > 0
	While (_cAlias)->(!Eof()) .And. !lDeuErro
		DBSelectArea("SE2")
		SE2->(DBSetOrder(1))
		If SE2->(DBSeek(xFilial("SE2")+(_cAlias)->(E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO+E2_FORNECE+E2_LOJA)))
			
			//=============================================
			//Array com os dados a serem passados para o SigaAuto
			//=============================================
			_aAutoSE2:={{"E2_PREFIXO",SE2->E2_PREFIXO,Nil},;
			{"E2_NUM"    ,SE2->E2_NUM     ,Nil},;
			{"E2_TIPO"   ,SE2->E2_TIPO    ,Nil},;
			{"E2_PARCELA",SE2->E2_PARCELA ,Nil},;
			{"E2_NATUREZ",SE2->E2_NATUREZ ,Nil},;
			{"E2_FORNECE",SE2->E2_FORNECE ,Nil},;
			{"E2_LOJA"   ,SE2->E2_LOJA    ,Nil}}
	
			//=============================================================
			//Altera o modulo para Financeiro, senao o SigaAuto nao executa
			//=============================================================
			nModulo := 6
			cModulo := "FIN"
			
			//=============================================
			//Roda SigaAuto de Exclusao de Titulos a Pagar
			//=============================================
			MSExecAuto({|x,y,z| Fina050(x,y,z)},_aAutoSE2,.T.,5)
			
			If lMsErroAuto
				lDeuErro := .T.
				MsgStop("O titulo "+SE2->(E2_FILIAL+E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO)+" não foi excluido! Fornecedor: "+SE2->E2_FORNECE+"/"+SE2->E2_LOJA+"-"+SE2->E2_NOMFOR;
						+ "Verifique no financeiro se este titulo ja foi baixado ou o motivo pelo qual não pode ser excluído."+;
						" Ao confimar esta tela, sera apresentada a tela do SigaAuto, que possui informações mais detalhadas.", "AGLT01637")
			   		Mostraerro()
			EndIf
			
			//=============================================
			//Restaura o modulo em uso.
			//=============================================
			nModulo := nModAnt
			cModulo := cModAnt           
		EndIf	
	
		(_cAlias)->(DBSkip())
	EndDo  
(_cAlias)->(DBCloseArea())

Else
	lDeuErro := .T.
	MsgStop("Não foi(ram) econtrado(s) título(s) no financeiro para realizar a exclusão. Favor acionar a área de TI/Sistemas.","AGLT01638")
EndIf   

FWRestArea(_aArea)

Return  

/*
===============================================================================================================================
Programa----------: CancBxSE2
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 22/03/2019
Descrição---------: Cancela Baixa de titulo no contas a pagar via SigaAuto
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function CancBxSE2()

Local nModAnt		:= nModulo
Local cModAnt		:= cModulo
Local _aArea		:= FWGetArea()
Local _nContReg		:= 0      
Local _cMotBaixa	:= GetMv("IT_MOTBXTR") 
Local _aTitulo		:= {}
Local _cAliasZLQ	:= GetNextAlias() 
Local _cAliasSE5	:= GetNextAlias()
Local _cFilial		:= ""
Local _cNumero		:= ""
Local _cParcela		:= ""
Local _cTp			:= ""
Local _cFornece		:= ""
Local _cLoja		:= ""

Private lMsErroAuto	:= .F.
Private lMsHelpAuto	:= .T.

BeginSql alias _cAliasZLQ
	SELECT ZLQ_VALOR,ZLQ_CHAVET
	FROM %Table:ZLQ%
	WHERE D_E_L_E_T_ = ' '
	AND ZLQ_FILIAL = %xFilial:ZLQ%
	AND ZLQ_COD = %exp:_cCodEmp%
EndSql
	
COUNT TO _nContReg //Contabiliza o numero de registros encontrados pela query  
(_cAliasZLQ)->(DBGoTop())

If _nContReg > 0
	While !(_cAliasZLQ)->(Eof()) .And. !lDeuErro
		_cFilial	:= SubStr((_cAliasZLQ)->ZLQ_CHAVET,1,2)
		_cPrefixo	:= SubStr((_cAliasZLQ)->ZLQ_CHAVET,3,3)
		_cNumero	:= SubStr((_cAliasZLQ)->ZLQ_CHAVET,6,9)
		_cParcela	:= SubStr((_cAliasZLQ)->ZLQ_CHAVET,15,2)
		_cTp		:= SubStr((_cAliasZLQ)->ZLQ_CHAVET,17,3)
		_cFornece	:= SubStr((_cAliasZLQ)->ZLQ_CHAVET,20,6)
		_cLoja		:= SubStr((_cAliasZLQ)->ZLQ_CHAVET,26,4)
		
		If !Empty(_cNumero)
		
			//============================================================================================
			//Chama funcao para criar tabela Temporaria contendo os dados das baixas a serem canceladas
			//============================================================================================
			BeginSql alias _cAliasSE5
				SELECT E5_FILIAL,E5_PREFIXO,E5_NUMERO,E5_PARCELA,E5_TIPO,E5_VALOR,E5_SEQ,E5_MOTBX,E5_DATA,E5_CLIFOR,E5_LOJA
				FROM %Table:SE5%
				WHERE D_E_L_E_T_ = ' '
				AND E5_TIPODOC = 'BA'
				AND E5_SITUACA <> 'C'
				AND E5_MOTBX = %exp:_cMotBaixa%
				AND E5_VALOR = %exp:Str((_cAliasZLQ)->ZLQ_VALOR )%
				AND E5_FILIAL = %exp:_cFilial%
				AND E5_PREFIXO = %exp:_cPrefixo%
				AND E5_NUMERO = %exp:_cNumero%
				AND E5_PARCELA = %exp:_cParcela%
				AND E5_TIPO = %exp:_cTp%
				AND E5_CLIFOR = %exp:_cFornece%
				AND E5_LOJA = %exp:_cLoja%
			EndSql

			COUNT TO _cContReg //Contabiliza o numero de registros encontrados pela query  
			(_cAliasSE5)->(DBGoTop())
			If _cContReg > 0        
				While !(_cAliasSE5)->(Eof()) .And. !lDeuErro
					DBSelectArea("SE2")
					SE2->(DBSetOrder(1))
					
					_aTitulo := {{"E2_PREFIXO",(_cAliasSE5)->E5_PREFIXO						,Nil},;
					{"E2_NUM"	    ,(_cAliasSE5)->E5_NUMERO          						,Nil},;
					{"E2_PARCELA"   ,(_cAliasSE5)->E5_PARCELA         						,Nil},;
					{"E2_TIPO"	    ,(_cAliasSE5)->E5_TIPO            						,Nil},;
					{"E2_FORNECE"   ,(_cAliasSE5)->E5_CLIFOR          						,Nil},;
					{"E2_LOJA"	    ,(_cAliasSE5)->E5_LOJA            						,Nil},;
					{"AUTJUROS"		,0				        		   						,Nil},;
					{"AUTDESCONT"	,0		 		                   						,Nil},;
					{"AUTMOTBX"		,(_cAliasSE5)->E5_MOTBX           						,Nil},;
					{"AUTDTBAIXA"	,(_cAliasSE5)->E5_DATA	           						,Nil},;
					{"AUTDTCREDITO"	,(_cAliasSE5)->E5_DATA           						,Nil},;
					{"AUTHIST"		,"Cancto Bx Tr - " + (_cAliasSE5)->(E5_CLIFOR+E5_LOJA)	,Nil},;
					{"AUTVLRPG"		,(_cAliasSE5)->E5_VALOR									,Nil},;
					{"AUTVALREC"	,(_cAliasSE5)->E5_VALOR									,Nil}}
					
					//=============================================================
					//Altera o modulo para Financeiro, senao o SigaAuto nao executa
					//=============================================================
					nModulo := 6
					cModulo := "FIN"
		
					//=========================
					//Busca o numero da Baixa
					//=========================
					_nBaixa := NroSeq((_cAliasSE5)->E5_PREFIXO,(_cAliasSE5)->E5_NUMERO,(_cAliasSE5)->E5_PARCELA,(_cAliasSE5)->E5_TIPO,(_cAliasSE5)->E5_CLIFOR,(_cAliasSE5)->E5_LOJA,(_cAliasSE5)->E5_SEQ)
		
					//=============================================================
					//SigaAuto de Cancelamento de Baixa de Contas a Pagar
					//=============================================================
					MSExecAuto( {|x,y,z,k| Fina080(x,y,z,k)},_aTitulo,5,,_nBaixa)
					
					//Restaura o modulo em uso
					nModulo := nModAnt
					cModulo := cModAnt 
					
				    If lMsErroAuto
						lDeuErro:=.T.
						MsgStop("Erro ao excluir a baixa no Contas a Pagar, título " + (_cAliasSE5)->(E5_FILIAL+E5_PREFIXO+E5_NUMERO+E5_PARCELA+E5_TIPO+E5_CLIFOR+E5_LOJA) + "Favor acionar a equipe de TI/Sistemas.","AGLT01639")
					  	Mostraerro()
				    EndIf       				    		
													
					(_cAliasSE5)->(DBSkip())			
				EndDo
				(_cAliasSE5)->(DBCloseArea())
			Else
				lDeuErro := .T.
				MsgStop("Não foram econtrados dados para a realização do cancelamento das baixas no financeiro do(a) " + _cTipo + " de origem. Favor acionar a equipe de TI/Sistemas.","AGLT01640")
			EndIf
		Else 
			lDeuErro := .T.
			MsgStop("A chave de estorno do(a) " + _cTipo +" " + _cCodEmp + " esta vazia. Favor acionar a equipe de TI/Sistemas.", "AGLT01641")
		EndIf	
		
		(_cAliasZLQ)->(DBSkip())
	EndDo
	(_cAliasZLQ)->(DBCloseArea())	  
//=============================================================
//Nao encontrou dados do emprestimo de origem
//=============================================================
Else
	lDeuErro := .T.
	MsgStop("Não foram encontrados os dados do(a)" + _cTipo +" " + _cCodEmp + " Favor acionar a equipe de TI/Sistemas.", "AGLT01642")
EndIf

FWRestArea(_aArea)

Return

/*
===============================================================================================================================
Programa----------: ProcZLN
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 22/03/2019
Descrição---------: Atualiza registros na ZLN
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ProcZLN()

Local _aArea:= FWGetArea()
                   
//Efetua exclusao do cabecalho do emprestimo transferido bem como de seus itens
If ZLN->(DBSeek(xFilial("ZLN") + _cCodEmp))  
	ZLN->(RecLock("ZLN",.F.)) 
		ZLN->(dbDelete())
	ZLN->(MSUnLock())    
	
	ZLQ->(DBSetOrder(1))
	If ZLQ->(DBSeek(xFilial("ZLQ") + _cCodEmp))  
		While !ZLQ->(Eof()) .And. xFilial("ZLQ") == ZLQ->ZLQ_FILIAL .And. _cCodEmp == ZLQ->ZLQ_COD
			ZLQ->(RecLock("ZLQ",.F.))    
				ZLQ->(dbDelete())  
			ZLQ->(MSUnLock()) 
		ZLQ->(DBSkip())
		EndDo  
	//Nao foram encontrados os dados dos itens do emprestimo para realizar a sua exclusao
	Else  
		lDeuErro := .T.
		MsgStop("Não foram encontrados os dados dos itens do(A)" + _cTipo +" " + _cCodEmp + " para realizar a sua exclusão na tabela ZLQ. Favor acionar a equipe de TI/Sistemas.", "AGLT01643")
	EndIf 
	     
//Nao foi encontrado o registro dos dados do cabecalho de origem 
Else  
	lDeuErro := .T.
	MsgStop("Não foram encontrados os dados do cabecalho do(A)" + _cTipo +" " + _cCodEmp + " para realizar a sua exclusão na tabela ZLN. Favor acionar a equipe de TI/Sistemas.","AGLT01644")
EndIf     
     
//Caso nao ocorra erro na exclusao dos dados do emprestimo de transferencia atualiza os dados do emprestimo de origem para que ele volte o 
//seu status como antes da realizacao da transferencia
If !lDeuErro  

	ZLN->(dbCommit()) 
	ZLQ->(dbCommit()) 

	If ZLN->(DBSeek(xFilial("ZLN") + _cCodEmpOr))   
		ZLN->(RecLock("ZLN",.F.))    
	 		ZLN->ZLN_STATUS:= "4" //Efetivado     
        	ZLN->ZLN_CODTRA:= ""
			ZLN->ZLN_USRTRA:= ""
			ZLN->ZLN_DATTRA:= CtoD("")
			ZLN->ZLN_HORTRA:= ""
			ZLN->ZLN_OBSTRA:= ""    			
		ZLN->(MSUnLock()) 
	Else
		lDeuErro := .T.
		Help(NIL, NIL, "AGLT01645", NIL, "Não foram encontrados os dados do cabecalho do(A)" + _cTipo +" " + _cCodEmp + " para realizar a sua alteração na tabela ZLN.";
			, 1, 0, NIL, NIL, NIL, NIL, NIL, {"Favor acionar a equipe de TI/Sistemas."})
	EndIf
EndIf

FWRestArea(_aArea)

Return

/*
===============================================================================================================================
Programa----------: NroSeq
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 22/03/2019
Descrição---------: Busca numero de sequencia da baixa no array de baixas do titulo
Parametros--------: cPrefixo   = Prefixo do titulo a ser cancelado a baixa
					cNum       = Numero do titulo a ser cancelado a baixa
					cParc      = Parcela do titulo a ser cancelado a baixa
					cTipo      = Tipo do titulo a ser cancelado a baixa
					cFor       = Fornecedor do titulo a ser cancelado a baixa
					cLoja      = Loja do Fornecedor do titulo a ser cancelado a baixa
					cSeq       = Sequencia da baixa
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function NroSeq(cPrefixo,cNum,cParcela,cTipo,cFor,cLoja,cSeq)

Local nRet := 0
Local nPos := 0

Private lBaixaAbat:= .F.
Private lNotBax   := .F.
Private lAglImp   := .F.
Private lBxCec    := .F.
Private nTotImpost:= 0
Private nTotAdto  := 0
Private aBaixaSE5 := {}

DBSelectArea("SE2")
SE2->(DBSetOrder(1))
SE2->(DBSeek(xFilial("SE2")+cPrefixo+cNum+cParcela+cTipo+cFor+cLoja))

//Funcao Padrao do Sistema que retorna um array com as baixas a serem canceladas
aBaixaSE5 := Sel080Baixa("VL /V2 /BA /RA /CP /LJ /NCC/",cPrefixo,cNum,cParcela,cTipo,@nTotAdto,@lBaixaAbat,cFor,cLoja,@lBxCec,.T.,@lNotBax,@nTotImpost,@lAglImp)
For nPos := 1 to Len(aBaixaSE5)
	If SubStr(aBaixaSE5[nPos],Len(aBaixaSE5[nPos])-1,2) == cSeq
		nRet := nPos
		Exit
	EndIf
Next nPos

Return nRet
