/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |11/04/2019| Chamado 28346. Revisão de fontes
Lucas Borges  |27/09/2019| Chamado 28346. Revisão de fontes.
Lucas Borges  |22/05/2020| Chamado 33020. Tratamento de error.log e geração de janelas na navegação.
===============================================================================================================================
*/

#Include "FWMVCDef.ch"
#Include "TOTVS.ch"
#Include "MsGraphi.Ch"

/*
===============================================================================================================================
Programa----------: MGLT013
Autor-------------: Alexandre Villar
Data da Criacao---: 08/12/2014
Descrição---------: Rotina para processar o fechamento da Recepção de Leite de Terceiros
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MGLT013()

Local _oBrowse	:= Nil

Private _cUsrID	:= RetCodUsr()
Private aRotina	:= MenuDef()

//====================================================================================================
// Configura e inicializa a Classe do Browse
//====================================================================================================
_oBrowse := FWMBrowse():New()

_oBrowse:SetAlias( 'ZLY' )
_oBrowse:SetDescription( 'Recepção Leite de Terceiros - Fechamento' )
_oBrowse:DisableDetails()

_oBrowse:AddLegend( ' Empty(ZLY->ZLY_DFECHA)' , 'YELLOW' , 'Período de Recepção Pendente' )
_oBrowse:AddLegend( '!Empty(ZLY->ZLY_DFECHA)' , 'RED'    , 'Período de Recepção Fechado'  )

_oBrowse:Activate()

Return

/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Alexandre Villar
Data da Criacao---: 08/12/2014
Descrição---------: Rotina para montar o menu da tela principal com as funcionalidades da rotina
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MenuDef()

Local _aRet			:= {}

ADD OPTION _aRet Title 'Analisar'		Action 'U_MGLT013C()'	OPERATION 4 ACCESS 0 
ADD OPTION _aRet Title 'Fechar Período'	Action 'U_MGLT013B()'	OPERATION 2 ACCESS 0
ADD OPTION _aRet Title 'Incluir'		Action 'U_MGLT013A()'	OPERATION 3 ACCESS 0
ADD OPTION _aRet Title 'Excluir' 		Action 'U_MGLT013A()'	OPERATION 5 ACCESS 0

Return( _aRet )

/*
===============================================================================================================================
Programa----------: MGLT013A
Autor-------------: Alexandre Villar
Data da Criacao---: 08/12/2014
Descrição---------: Rotina para montar a View de Dados da Rotina
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MGLT013A()

Local _aFilZLX	:= {}
Local _nOper	:= IIf( Inclui , MODEL_OPERATION_INSERT , MODEL_OPERATION_DELETE )
Local _cDtIni	:= SubStr( DToS( dDataBase ) , 1 , 6 ) + IIf( Day( dDataBase ) <= 15 , '01' , '16' )
Local _cAlias	:= ''
Local _aRotBkp	:= aClone( aRotina )

If _nOper == MODEL_OPERATION_INSERT
	_cAlias	:= GetNextAlias()
	BeginSql alias _cAlias
		SELECT ZLY_CODIGO
		FROM %Table:ZLY%
		WHERE D_E_L_E_T_ = ' '
		AND ZLY_FILIAL = %xFilial:ZLY%
		AND ZLY_REFINI = %exp:_cDtIni%
	EndSql
	
	If !Empty( (_cAlias)->ZLY_CODIGO )
		MsgStop("Já existe o Fechamento ["+ (_cAlias)->ZLY_CODIGO +"] para o período atual! Não é possível criar dois fechamentos com o mesmo período.","MGLT01301")
	Else
		
		Begin Transaction
		
			ZLY->( RecLock('ZLY',.T.) )
			
			ZLY->ZLY_FILIAL	:= xFilial('ZLY')
			ZLY->ZLY_CODIGO := GETSXENUM('ZLY','ZLY_CODIGO')
			ZLY->ZLY_REFINI	:= SToD( _cDtIni )
			ZLY->ZLY_REFFIM	:= IIf( Day( dDataBase ) <= 15 , SToD( SubStr(_cDtIni,1,6) + '15' ) , LastDay( dDataBase , 0 ) )
			
			ZLY->( MSUnLock() )
			
			If __lSX8
				ConfirmSX8()
			EndIf
		
		End Transaction
		
		MsgInfo("Criado o Fechamento ["+ ZLY->ZLY_CODIGO +"] para o período atual!","MGLT01302")
		
	EndIf
	(_cAlias)->(DBCloseArea())
Else

	_cAlias	:= GetNextAlias()
	BeginSql alias _cAlias
		SELECT DISTINCT ZLX_FILIAL
		FROM %Table:ZLX%
		WHERE D_E_L_E_T_ = ' '
		AND ZLX_DTENTR BETWEEN %exp:ZLY->ZLY_REFINI% AND %exp:ZLY->ZLY_REFFIM%
	EndSql

	While (_cAlias)->( !Eof() )
		
		If !Empty( (_cAlias)->ZLX_FILIAL )
			aAdd( _aFilZLX , { (_cAlias)->ZLX_FILIAL +' - '+ FWFilialName( cEmpAnt , (_cAlias)->ZLX_FILIAL , 2 ) } )
		EndIf
	
	(_cAlias)->( DBSkip() )
	EndDo
	
	(_cAlias)->( DBCloseArea() )
	
	If Empty( _aFilZLX )
		ZLY->( RecLock('ZLY',.F.) )
		ZLY->( DBDelete() )
		ZLY->( MSUnLock() )
	Else
		MsgStop("Não será possível excluir o Período pois existem lançamentos de Recepção de Leite de Terceiros!","MGLT001304")
		U_ITListBox( 'Registro de Recepção no período - Leite de Terceiros' , {'Filiais'} , _aFilZLX , .F. , 1 , 'Lista de Filiais que contém lançamentos de Recepção no período: '+ DToC( ZLY->ZLY_REFINI ) +' - '+ DToC( ZLY->ZLY_REFFIM ) )
	EndIf

EndIf

aRotina := aClone( _aRotBkp )

Return

/*
===============================================================================================================================
Programa----------: MGLT013B
Autor-------------: Alexandre Villar
Data da Criacao---: 08/12/2014
Descrição---------: Rotina para verificar e processar o Encerramento do período selecionado
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MGLT013B()

Local _aResumo	:= {}
Local _cAlias	:= GetNextAlias()
Local _cFilAux	:= ''
Local _lFecha	:= .F.
Local _aRotBkp	:= aClone( aRotina )

If Empty(ZLY->ZLY_DFECHA)
	BeginSql alias _cAlias
		SELECT ZLX_FILIAL, COUNT(1) QTREG
		FROM %Table:ZLX%
		WHERE D_E_L_E_T_ = ' '
		AND ZLX_STATUS = '1'
		AND ZLX_DTENTR BETWEEN %exp:ZLY->ZLY_REFINI% AND %exp:ZLY->ZLY_REFFIM%
		GROUP BY ZLX_FILIAL
		ORDER BY ZLX_FILIAL
	EndSql
	
	While (_cAlias)->( !Eof() )
		If !Empty( (_cAlias)->ZLX_FILIAL )
			_cFilAux := (_cAlias)->ZLX_FILIAL
			While (_cAlias)->( !Eof() ) .And. _cFilAux == (_cAlias)->ZLX_FILIAL
				If (_cAlias)->QTREG > 0
					aAdd( _aResumo , { (_cAlias)->ZLX_FILIAL +' - '+ FWFilialName( cEmpAnt , (_cAlias)->ZLX_FILIAL , 2 ) , (_cAlias)->QTREG } )
				EndIf
			(_cAlias)->( DBSkip() )
			EndDo
		EndIf
	(_cAlias)->( DBSkip() )
	EndDo
	
	If Empty(_aResumo)
		Processa( {|| MGLT013FFL( ZLY->ZLY_REFINI , ZLY->ZLY_REFFIM ,, .F.)}/*bAction*/, "Aguarde..."/*cTitle */, "Processando os fechamentos internos..."/*cMsg */,.F./*lAbort */)
		Processa( {|| _lFecha := MGLT013VRP( ZLY->ZLY_REFINI , ZLY->ZLY_REFFIM )}/*bAction*/, "Aguarde..."/*cTitle */, "Verificando registros ainda pendentes..."/*cMsg */,.F./*lAbort */)
	
		If _lFecha
			ZLY->( RecLock( 'ZLY' , .F. ) )
			ZLY->ZLY_DFECHA	:= Date()
			ZLY->ZLY_USRFEC	:= _cUsrID
			ZLY->( MSUnLock() )
			
			MsgInfo("Período e registros do período fechados com sucesso!","MGLT01303")
			
		EndIf
		
	Else
	
		MsgAlert("Existem recepções que ainda estão pendentes e que não podem ser fechadas! Verifique as Filiais que ainda tiverem registros nessa situação para " +;
					"conseguir Fechar o período.","MGLT01304")
		
		U_ITListBox("Recepção de Leite de Terceiros - Registros Pendentes", {"Filiais","Qtde. Registros"} , _aResumo , .F. , 1 , "Lançamentos pendentes no período: "+ DToC( ZLY->ZLY_REFINI ) +" - "+ DToC( ZLY->ZLY_REFFIM ) )
	
	EndIf
	
	aRotina := aClone( _aRotBkp )
Else
	MsgInfo("O período informado já se encontra fechado e não será processado.","MGLT01305")
EndIf

Return

/*
===============================================================================================================================
Programa----------: MGLT013C
Autor-------------: Alexandre Villar
Data da Criacao---: 08/12/2014
Descrição---------: Rotina para verificar o Status de todas as Recepções do Período e processar o Encerramento de Registros
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MGLT013C()

Local _aArea	:= FWGetArea()
Local _aRotBkp	:= aClone( aRotina )
Local _aInfo	:= {}
Local _aObjects	:= {}
Local _aSize 	:= MSADVSIZE()
Local _aHeader	:= {'Filial','1ª Recepção','Últ. Recepção','Pendentes','Classificadas','Fechadas'}

Local _oDlg		:= Nil
Local _oLbxAux	:= Nil
Local _oGraph	:= Nil

Local _cDtIni	:= DToC( ZLY->ZLY_REFINI )
Local _cDtFim	:= DToC( ZLY->ZLY_REFFIM )

Local _bDados	:= {|| MGLT013SEL( @_oLbxAux	, ZLY->ZLY_REFINI , ZLY->ZLY_REFFIM ) }
Local _bGraph	:= {|| MGLT013GRP( @_oGraph		, ZLY->ZLY_REFINI , ZLY->ZLY_REFFIM , _oLbxAux ) }
Local _bEncFil	:= {|| MGLT013FFL( ZLY->ZLY_REFINI , ZLY->ZLY_REFFIM , SubStr( _oLbxAux:aArray[_oLbxAux:nAt][01] , 1 , 2 ) ) , Processa( {|| Eval(_bDados)}/*bAction*/, "Aguarde..."/*cTitle */, "Verificando dados..."/*cMsg */,.F./*lAbort */) }
Local _bVisFil	:= {|| MGLT013DFL( SubStr( _oLbxAux:aArray[_oLbxAux:nAt][01] , 1 , 2 ) ) , Eval( _bDados ) }
Local _bFinal	:= {|| _oDlg:End() }

Local _oFont	:= TFont():New( "Arial" ,, 14 ,, .T. ,,,, .T. , .F. ) //Negrito

aAdd( _aObjects , { 100 , 050 , .T. , .T. } )
aAdd( _aObjects , { 100 , 050 , .T. , .T. } )

_aInfo   := { _aSize[ 1 ] , _aSize[ 2 ] , _aSize[ 3 ] , _aSize[ 4 ] , 3 , 2 }
_aPosObj := MsObjSize( _aInfo , _aObjects )

DEFINE MSDIALOG _oDlg FROM _aSize[7],0 TO _aSize[6],_aSize[5] PIXEL TITLE "Fechamento - Recepção de Leite de Terceiros"

	_oDlg:lMaximized := .T.

	DEFINE FONT oBold NAME "Arial" SIZE 0, -13 BOLD
    
	//====================================================================================================
	// Construção inicial do GRID
	//====================================================================================================
	@_aPosObj[01][01],_aPosObj[01][02]	LISTBOX	_oLbxAux					;
										FIELDS	HEADER ""					;
										ON		DblClick( Eval(bDblClk) )	;
										SIZE	_aPosObj[01][04] , ( _aPosObj[01][03] - _aPosObj[01][01] - 12 ) OF _oDlg PIXEL
	
	_oLbxAux:AHeaders	:= aClone( _aHeader )
	_oLbxAux:bChange	:= {|| MGLT013GRF( @_oGraph , _aPosObj , _oLbxAux , _oDlg ) }
	
	Eval( _bDados )
	
	If Empty( _oLbxAux:aArray )
	
		MsgStop("Não foram encontrados dados para exibir!","MGLT01306")
		aRotina := aClone( _aRotBkp )
		Return(.F.)
		
	EndIf
	_nPosAux := ( _aPosObj[01][01] -20 )
	
	@_nPosAux,_aPosObj[01][04]-137 BUTTON _oButton PROMPT "Fechar Filial"	SIZE 045,12 ACTION Eval(_bEncFil) OF _oDlg PIXEL
	@_nPosAux,_aPosObj[01][04]-091 BUTTON _oButton PROMPT "Detalhes"		SIZE 045,12 ACTION Eval(_bVisFil) OF _oDlg PIXEL
	@_nPosAux,_aPosObj[01][04]-045 BUTTON _oButton PROMPT "Sair"			SIZE 045,12 ACTION Eval(_bFinal ) OF _oDlg PIXEL
	
	//====================================================================================================
	// Construção inicial do gráfico
	//====================================================================================================
	@_aPosObj[02][01]+05 , _aPosObj[02][02] Say "Movimentação no Período: "+ _cDtIni +" até "+ _cDtFim	OF _oDlg PIXEL FONT oBold
	@_aPosObj[02][01]+14 , _aPosObj[02][02] TO _aPosObj[02][03]+16,_aPosObj[02][04]						OF _oDlg PIXEL LABEL ''
	
	@_aPosObj[02][01]+17 , _aPosObj[02][02]+10 BITMAP RESOURCE 'BR_AZUL' NO BORDER SIZE 010,010			OF _oDlg PIXEL
	_oSay	:= TSay():Create( _oDlg , {|| "Recepções" } , _aPosObj[02][01] + 17 , _aPosObj[02][02] + 18 ,, _oFont ,,,, .T. , CLR_BLUE , CLR_WHITE , 200 , 20 )
	
	@_aPosObj[02][01]+17 , _aPosObj[02][02]+70 BITMAP RESOURCE 'BR_VERMELHO' NO BORDER SIZE 010,010		OF _oDlg PIXEL
	_oSay	:= TSay():Create( _oDlg , {|| "Classificações" } , _aPosObj[02][01] + 17 , _aPosObj[02][02] + 78 ,, _oFont ,,,, .T. , CLR_RED , CLR_WHITE , 200 , 20 )
	
	_oGraph := TMSGraphic():New( _aPosObj[02][01] + 22 , _aPosObj[02][02] , _oDlg ,,,, _aPosObj[02][04] , _aPosObj[02][03] - ( _aPosObj[02][01] + 10 ) )
	
	Eval( _bGraph )

ACTIVATE MSDIALOG _oDlg CENTER 

FWRestArea(_aArea)

aRotina := aClone( _aRotBkp )

Return

/*
===============================================================================================================================
Programa----------: MGLT013SEL
Autor-------------: Alexandre Villar
Data da Criacao---: 08/12/2014
Descrição---------: Rotina para realizar a busca dos dados e montar o objeto do Grid
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGLT013SEL( _oLbxAux , _dDtIni , _dDtFim )

Local _aDados	:= {}
Local _cAlias	:= GetNextAlias()

BeginSql alias _cAlias
	SELECT ZLX_FILIAL, MIN(ZLX_DTENTR) PRI_REC, MAX(ZLX_DTENTR) ULT_REC, COUNT(ZLX_CODIGO),
	SUM(Case WHEN ZLX_STATUS = '1' THEN 1 Else 0 END) PENDENTES,
	SUM(Case WHEN ZLX_STATUS = '2' THEN 1 Else 0 END) CLASSIF,
	SUM(Case WHEN ZLX_STATUS = '3' THEN 1 Else 0 END) FECHADOS
	FROM %Table:ZLX%
	WHERE D_E_L_E_T_ = ' '
	AND ZLX_DTENTR BETWEEN %exp:ZLY->ZLY_REFINI% AND %exp:ZLY->ZLY_REFFIM%
	GROUP BY ZLX_FILIAL
	ORDER BY ZLX_FILIAL
EndSql

While (_cAlias)->(!Eof())
	
	aAdd( _aDados , {	(_cAlias)->ZLX_FILIAL +" - "+ AllTrim( FWFilialName( cEmpAnt , (_cAlias)->ZLX_FILIAL ) )	,;
						DToC( SToD( (_cAlias)->PRI_REC ) )											,;
						DToC( SToD( (_cAlias)->ULT_REC ) )											,;
						(_cAlias)->PENDENTES														,;
						(_cAlias)->CLASSIF															,;
						(_cAlias)->FECHADOS															})

(_cAlias)->( DBSkip() )
EndDo

(_cAlias)->( DBCloseArea() )

If !Empty(_aDados)

	_oLbxAux:SetArray( _aDados )
	_oLbxAux:bLine := {|| {	_aDados[_oLbxAux:nAt][01] ,;
							_aDados[_oLbxAux:nAt][02] ,;
							_aDados[_oLbxAux:nAt][03] ,;
							_aDados[_oLbxAux:nAt][04] ,;
							_aDados[_oLbxAux:nAt][05] ,;
							_aDados[_oLbxAux:nAt][06] }}

EndIf

Return

/*
===============================================================================================================================
Programa----------: MGLT013GRP
Autor-------------: Alexandre Villar
Data da Criacao---: 08/12/2014
Descrição---------: Rotina para consultar os dados e montar o Gráfico referente à linha do GRID que estiver selecionada
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGLT013GRP( _oGraph , _dDtIni , _dDtFim , _oLbxAux )

Local _aDados	:= {}
Local _cAlias	:= GetNextAlias()
Local _nI		:= 0
Local _nPos		:= 0
Local _nMax		:= 0

//_oGraph:SetLegenProp( 0 , CLR_LIGHTGRAY , GRP_SERIES , .F. )

BeginSql alias _cAlias
	SELECT DATAREF, SUM(RECEP) RECEP, SUM(CLASSIF) CLASSIF
	  FROM (SELECT ZLX_DTENTR DATAREF, Count(1) RECEP, 0 CLASSIF
	          FROM %Table:ZLX% ZLX
	         WHERE ZLX.D_E_L_E_T_ = ' '
	           AND ZLX.ZLX_FILIAL = %exp:SubStr(_oLbxAux :aArray [ _oLbxAux :nAt ] [ 01 ], 1, 2)%
	           AND ZLX.ZLX_DTENTR BETWEEN %exp:_dDtIni% AND %exp:_dDtFim%
	         GROUP BY ZLX_DTENTR
	        UNION ALL
	        SELECT ZLX_DTCLAS DATAREF, 0 RECEP, Count(1) CLASSIF
	          FROM %Table:ZLX% ZLX
	         WHERE ZLX.D_E_L_E_T_ = ' '
	           AND ZLX.ZLX_FILIAL = %exp:SubStr(_oLbxAux :aArray [ _oLbxAux :nAt ] [ 01 ], 1, 2)%
	           AND ZLX.ZLX_DTCLAS BETWEEN %exp:_dDtIni% AND %exp:_dDtFim%
	         GROUP BY ZLX_DTCLAS) TRB
	 GROUP BY DATAREF
	 ORDER BY DATAREF
EndSql

While (_cAlias)->(!Eof())
	
	aAdd( _aDados , {	StrZero( Day( SToD( (_cAlias)->DATAREF ) ) , 2 )	,;
						(_cAlias)->RECEP									,;
						(_cAlias)->CLASSIF									})

(_cAlias)->( DBSkip() )
EndDo

(_cAlias)->( DBCloseArea() )

If !Empty(_aDados)

	_oGraph:CreateSerie( GRP_BAR , 'Recebimentos'   , 0 , .F. )
	_oGraph:CreateSerie( GRP_BAR , 'Classificações' , 0 , .F. )
	
	For _nI := Day(_dDtIni) To Day(_dDtFim)
		
		If ( _nPos := aScan( _aDados , {|x| Val(x[01]) == _nI } ) ) > 0// _nI == Val( _aDados[_nI][01] )
		
			_oGraph:Add( 01 , _aDados[_nPos][02] , _aDados[_nPos][01] , RGB(000,000,200) )
			_oGraph:Add( 02 , _aDados[_nPos][03] , _aDados[_nPos][01] , RGB(200,000,000) )
			
			If _nMax < _aDados[_nPos][02]
				_nMax := _aDados[_nPos][02]
			EndIf
			
			If _nMax < _aDados[_nPos][03]
				_nMax := _aDados[_nPos][03]
			EndIf
			
		Else
			
			_oGraph:Add( 01 , 0 , StrZero(_nI,2) , RGB(000,000,200) )
			_oGraph:Add( 02 , 0 , StrZero(_nI,2) , RGB(200,000,000) )
			
		EndIf
		
	Next _nI
	
	_oGraph:SetGradient( GDBOTTOMTOP , CLR_HGRAY , CLR_WHITE )
	_oGraph:bRClicked := {|o,x,y| oMenu:Activate(x,y,oGraph01) } // Posição x,y em relação a Dialog 
	_oGraph:SetMargins(30,05,10,10)
	_oGraph:SetRangeY( 0 , _nMax + 10 )
	_oGraph:L3D := .F.

EndIf

Return

/*
===============================================================================================================================
Programa----------: MGLT013GRF
Autor-------------: Alexandre Villar
Data da Criacao---: 08/12/2014
Descrição---------: Rotina para atualizar o gráfico quando mudar a seleção da linha do GRID
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGLT013GRF( _oGraph , _aPosObj , _oLbxAux , _oDlg )

FreeObj( _oGraph )

_oGraph := TMSGraphic():New( _aPosObj[02][01] + 22 , _aPosObj[02][02] , _oDlg ,,,, _aPosObj[02][04] , _aPosObj[02][03] - ( _aPosObj[02][01] + 10 ) )

MGLT013GRP( @_oGraph , ZLY->ZLY_REFINI , ZLY->ZLY_REFFIM , _oLbxAux )

Return

/*
===============================================================================================================================
Programa----------: MGLT013DFL
Autor-------------: Alexandre Villar
Data da Criacao---: 08/12/2014
Descrição---------: Rotina para detalhar os dados da Filial selecionada no GRID
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGLT013DFL( _cFilial )

Local _cAlias	:= GetNextAlias()
Local _aHeader	:= {'Sel.','Cód. Forn.','Loja Forn.','Fornecedor','Cód. Produto','Descrição Produto','Análise','Classificado','Fechado','Qtd. Recebimentos'}
Local _aDados	:= {}
Local _lReProc	:= .F.

BeginSql alias _cAlias
	SELECT ZLX.ZLX_FORNEC, ZLX.ZLX_LJFORN, SA2.A2_NREDUZ, ZLX.ZLX_PRODLT,
	       Case  WHEN ZLX.ZLX_CODANA <> ' ' THEN 'S' Else 'N' END ANALISE,
	       Case WHEN ZLX.ZLX_STATUS >= '2' THEN 'S' Else 'N' END CLASSIF,
	       Case WHEN ZLX.ZLX_STATUS = '3' THEN 'S' Else 'N' END FECHADO,
	       COUNT(ZLX.R_E_C_N_O_) QTD_REC
	  FROM %Table:ZLX% ZLX
	  LEFT OUTER JOIN %Table:SA2% SA2
	    ON SA2.A2_COD = ZLX.ZLX_FORNEC
	   AND SA2.A2_LOJA = ZLX.ZLX_LJFORN
	   AND SA2.D_E_L_E_T_ = ' '
	 WHERE ZLX.D_E_L_E_T_ = ' '
	   AND ZLX.ZLX_FILIAL = %exp:_cFilial%
	   AND ZLX.ZLX_DTENTR BETWEEN %exp:ZLY->ZLY_REFINI% AND %exp:ZLY->ZLY_REFFIM%
	 GROUP BY ZLX.ZLX_FORNEC, ZLX.ZLX_LJFORN, SA2.A2_NREDUZ, ZLX.ZLX_PRODLT,
	          Case WHEN ZLX.ZLX_CODANA <> ' ' THEN 'S' Else 'N' END,
	          Case WHEN ZLX.ZLX_STATUS >= '2' THEN 'S' Else 'N' END,
	          Case WHEN ZLX.ZLX_STATUS = '3' THEN 'S' Else 'N' END
	 ORDER BY ZLX.ZLX_FORNEC, ZLX.ZLX_LJFORN, ANALISE, CLASSIF
EndSql

While (_cAlias)->( !Eof() )
	
	aAdd( _aDados , {	.F.																						,;
						(_cAlias)->ZLX_FORNEC																	,;
						(_cAlias)->ZLX_LJFORN														   			,;
						AllTrim( (_cAlias)->A2_NREDUZ )															,;
						AllTrim( (_cAlias)->ZLX_PRODLT )														,;
						AllTrim( Posicione( 'SB1' , 1 , xFilial('SB1') + (_cAlias)->ZLX_PRODLT , 'B1_DESC' ) )	,;
						(_cAlias)->ANALISE																		,;
						(_cAlias)->CLASSIF																		,;
						(_cAlias)->FECHADO																		,;
						Transform( QTD_REC , '@E 999,999,999' )													})
	
(_cAlias)->( DBSkip() )
EndDo

(_cAlias)->( DBCloseArea() )

If Empty( _aDados )
	MsgStop("Não foram encontrados dados para exibir!","MGLT01307")
Else
	_lReproc := MGLT013FTR( _aHeader , _aDados , _cFilial )
EndIf

Return( IIf( _lReproc , MGLT013DFL(_cFilial) , Nil ) )

/*
===============================================================================================================================
Programa----------: MGLT013FTR
Autor-------------: Alexandre Villar
Data da Criacao---: 08/12/2014
Descrição---------: Rotina para montar a Tela de Detalhes da Filial Selecionada
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/

Static Function MGLT013FTR( _aHeader , _aDados , _cFilial )

Local aCoors 		:= FWGetDialogSize(oMainWnd)
Local aSize     	:= MsAdvSize( .T. ) 
Local aObjAux		:= {}
Local aPosAux		:= {}
Local aButtons		:= {}
Local _lRet			:= .F.
Local _bFecTrn		:= {|| LjMsgRun( 'Fechando as Recepções dos Fornecedores selecionados...' , 'Aguarde!' , {|| MGLT013ETR( @oLbxAux , _cFilial ) } ) , _lRet := .T. , oDlg:End() }
Local _bFinal		:= {|| oDlg:End() }
Local oDlg			:= Nil
Local oFont			:= Nil
Local cColsAux		:= ""
Local nI			:= 0
Local oLbxAux		:= Nil
Local bDblClk	 	:= Nil
Local cTitAux		:= 'Fechamento dos Transportadores - Filial: '+ AllTrim( FWFilialName( cEmpAnt , _cFilial , 2 ) )
Local cMsgTop		:= 'Selecione os Transportadores que deseja Fechar:'
Local aSizes		:= { 10 , 40 , 40 , 120 , 40 , 120 , 50 , 50 , 50 , 50 }

Default _aHeader	:= { "Falha" }
Default _aDados		:= { { "Sem conteúdo para exibir." } }

bDblClk := {|| MGLT013DBC( @oLbxAux ) }

aAdd( aObjAux, { 100, 100, .T., .T. } )
aInfo   := { aSize[ 1 ], aSize[ 2 ], aSize[ 3 ], aSize[ 4 ], 3, 2 }
aPosAux := MsObjSize( aInfo , aObjAux )

DEFINE FONT oFont NAME "Verdana" SIZE 05,12

aAdd( aButtons , { "Excel" , {|| DlgToExcel( { { "ARRAY" , cTitAux , aHeader , aCols } } ) } , "Exportação de Dados para Excel" , "Excel" } )

DEFINE MSDIALOG oDlg TITLE cTitAux FROM aCoors[1],aCoors[2] TO aCoors[3],aCoors[4] PIXEL
	
	@aPosAux[01][01] , aPosAux[01][02] Say cMsgTop OF oDlg PIXEL
	aPosAux[01][01] += 010
	
	@aPosAux[01][01] , aPosAux[01][02]	LISTBOX	oLbxAux						;
										FIELDS	HEADER ""					;
										ON		DblClick( Eval(bDblClk) )	;
										SIZE	aPosAux[01][04] , ( aPosAux[01][03] - aPosAux[01][01] ) OF oDlg PIXEL
	
	oLbxAux:AHeaders	:= aClone( _aHeader )
	oLbxAux:AColSizes	:= aClone( aSizes   )
	oLbxAux:SetArray( _aDados )
	
	//===========================================================================
	//| Monta os dados para o ListBox                                           |
	//===========================================================================
	For nI := 1 To Len(_aHeader)
	
		If nI == 1
			cColsAux := "{|| {	IIf( _aDados[oLbxAux:nAt,"+ cValtoChar(nI) +"] , LoadBitmap( GetResources() , 'LBOK' ) , LoadBitmap( GetResources() , 'LBNO' ) ) ,"
		Else
			cColsAux += "            _aDados[oLbxAux:nAt,"+ cValtoChar(nI) +"] ,"
		EndIf
		
	Next nI
	
	//===========================================================================
	//| Atribui os dados ao ListBox                                             |
	//===========================================================================
	cColsAux		:= SubStr( cColsAux , 1 , Len(cColsAux)-1 ) + "}}"
	oLbxAux:bLine	:= &( cColsAux )
	
	@aPosAux[01][03]-aPosAux[01][01]+13,_aPosObj[01][04]-081 BUTTON _oButton PROMPT "Fechar Rec."	SIZE 040,12 ACTION Eval(_bFecTrn) OF oDlg PIXEL
	@aPosAux[01][03]-aPosAux[01][01]+13,_aPosObj[01][04]-040 BUTTON _oButton PROMPT "Sair"			SIZE 040,12 ACTION Eval(_bFinal ) OF oDlg PIXEL

ACTIVATE MSDIALOG oDlg

Return( _lRet )

/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Alexandre Villar
Data da Criacao---: 08/12/2014
Descrição---------: Rotina para validar a seleção de ítens na tela de detalhe para não permitir fechar registros pendentes
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGLT013DBC( oLbxDados )

Local _lSel := oLbxDados:aArray[ oLbxDados:nAt , 01 ]

If _lSel
	oLbxDados:aArray[ oLbxDados:nAt , 01 ] := !oLbxDados:aArray[ oLbxDados:nAt , 01 ]
	oLbxDados:Refresh()
Else
	If oLbxDados:aArray[ oLbxDados:nAt][07] == 'S' .And. oLbxDados:aArray[ oLbxDados:nAt][08] == 'S' .And. oLbxDados:aArray[ oLbxDados:nAt][09] == 'N'
		oLbxDados:aArray[ oLbxDados:nAt , 01 ] := !oLbxDados:aArray[ oLbxDados:nAt , 01 ]
		oLbxDados:Refresh()
	EndIf
EndIf

Return

/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Alexandre Villar
Data da Criacao---: 08/12/2014
Descrição---------: Rotina para processar o fechamento dos registros das Transportadoras selecionados
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGLT013ETR( oLbxAux , _cFilial )

Local _cAlias	:= ""
Local _nI		:= 0

Begin Transaction

For _nI := 1 To Len( oLbxAux:aArray )
	
	If oLbxAux:aArray[_nI][01]
		_cAlias	:= GetNextAlias()
		BeginSql alias _cAlias
			SELECT R_E_C_N_O_ REGZLX
			FROM %Table:ZLX%
			WHERE D_E_L_E_T_ = ' '
			AND ZLX_FILIAL = %exp:_cFilial%
			AND ZLX_FORNEC = %exp:oLbxAux:aArray[_nI][02]%
			AND ZLX_LJFORN = %exp:oLbxAux:aArray[_nI][03]%
			AND ZLX_STATUS = '2'
			AND ZLX_DTENTR BETWEEN %exp:ZLY->ZLY_REFINI% AND %exp:ZLY->ZLY_REFFIM%
		EndSql

		While (_cAlias)->( !Eof() ) .And. !Empty( (_cAlias)->REGZLX )
			
			DBSelectArea('ZLX')
			ZLX->( DBGoTo( (_cAlias)->REGZLX ) )
			ZLX->( RecLock( 'ZLX' , .F. ) )
			ZLX->ZLX_STATUS	:= '3'
			ZLX->ZLX_USRFEC	:= _cUsrID
			ZLX->ZLX_DTFECH	:= Date()
			ZLX->ZLX_HRFECH	:= Time()
			ZLX->( MSUnLock() )

			(_cAlias)->( DBSkip() )
		EndDo
		     
		(_cAlias)->( DBCloseArea() )
		
	EndIf
	
Next _nI

End Transaction

Return

/*
===============================================================================================================================
Programa----------: MGLT013B
Autor-------------: Alexandre Villar
Data da Criacao---: 08/12/2014
Descrição---------: Rotina para verificar e processar o Encerramento do período selecionado
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGLT013FFL( _dDtIni , _dDtFim , _cFilial , _lShowMsg )

Local _aResumo	:= {}
Local _cFiltro	:= "%"
Local _cAlias	:= GetNextAlias()
Local _lRet		:= .T.

Default _cFilial	:= ''
Default _lShowMsg	:= .T.

If !Empty(_cFilial)
	_cFiltro += " AND ZLX.ZLX_FILIAL = '"+ _cFilial +"'"
EndIf
_cFiltro += " %"

BeginSql alias _cAlias
	SELECT ZLX.R_E_C_N_O_ REGZLX, TRANS.A2_NREDUZ TRANS_NOME, FORN.A2_NREDUZ FORN_NOME
	FROM %Table:ZLX% ZLX, %Table:SA2% TRANS, %Table:SA2% FORN
	WHERE ZLX.D_E_L_E_T_ = ' '
	AND TRANS.D_E_L_E_T_ (+) = ' '
	AND FORN.D_E_L_E_T_ = ' '
	AND ZLX_FORNEC = FORN.A2_COD
	AND ZLX_LJFORN = FORN.A2_LOJA
	AND ZLX_TRANSP (+) = TRANS.A2_COD
	AND ZLX_LJTRAN (+) = TRANS.A2_LOJA
	AND ZLX_FILIAL = %exp:_cFilial%
	AND ZLX_STATUS = '2'
	%exp:_cFiltro%
	AND ZLX_DTENTR BETWEEN %exp:ZLY->ZLY_REFINI% AND %exp:ZLY->ZLY_REFFIM%
EndSql

While (_cAlias)->( !Eof() )
	
	ZLX->( DBGoTo( (_cAlias)->REGZLX ) )
	ZLX->( RecLock( 'ZLX' , .F. ) )
	ZLX->ZLX_STATUS	:= '3'
	ZLX->ZLX_USRFEC	:= _cUsrID
	ZLX->ZLX_DTFECH	:= Date()
	ZLX->ZLX_HRFECH	:= Time()
	ZLX->( MSUnLock() )
	
	aAdd( _aResumo , {	ZLX->ZLX_FILIAL,;
						ZLX->ZLX_CODIGO,;
						ZLX->ZLX_FORNEC +'/'+ ZLX->ZLX_LJFORN +' - '+ AllTrim((_cAlias)->FORN_NOME),;
						ZLX->ZLX_TRANSP +'/'+ ZLX->ZLX_LJTRAN +' - '+ AllTrim((_cAlias)->TRANS_NOME),;
						ZLX->ZLX_TIPOLT,;
						U_ITRetBox( ZLX->ZLX_TIPOLT , 'ZLX_TIPOLT' ),;
						ZLX->ZLX_DTSAID})
	
	(_cAlias)->( DBSkip() )
EndDo

(_cAlias)->(DBCloseArea())

If !Empty(_aResumo)
	If _lShowMsg
		MsgInfo("Foram encerradas "+ cValToChar(Len(_aResumo)) +" Recepções no período atual.","MGLT01308")
		U_ITListBox('Resumo do Processamento',{'Filial','Recepção','Fornecedor','Transportador','Tipo','Produto','Data Saída'},_aResumo,.F.,1,'Registros fechados:')
	EndIf
	_lRet := .T.
Else
	If _lShowMsg
		MsgStop("Não foram encontradas Recepções CLASSIFICADAS para o Fechamento! Verifique os dados e tente novamente.","MGLT01309")
	EndIf
	_lRet := .F.
EndIf

Return( _lRet )

/*
===============================================================================================================================
Programa----------: MGLT013VRP
Autor-------------: Alexandre Villar
Data da Criacao---: 08/12/2014
Descrição---------: Rotina para verificar resgistros pendentes
Parametros--------: _dDtIni , _dDtFim
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGLT013VRP( _dDtIni , _dDtFim )

Local _aResumo	:= {}
Local _cAlias	:= GetNextAlias()
Local _lRet		:= .T.

BeginSql alias _cAlias
	SELECT ZLX_FILIAL, ZLX_CODIGO, ZLX_TIPOLT, ZLX_TRANSP, ZLX_LJTRAN, ZLX_FORNEC, ZLX_LJFORN, ZLX_PRODLT, ZLX_DTSAID,
			TRANS.A2_NREDUZ TRANS_NOME, FORN.A2_NREDUZ FORN_NOME, B1_DESC
	FROM %Table:ZLX% ZLX, %Table:SA2% TRANS, %Table:SA2% FORN, %Table:SB1% SB1
	WHERE ZLX.D_E_L_E_T_ = ' '
	AND TRANS.D_E_L_E_T_ (+) = ' '
	AND FORN.D_E_L_E_T_ = ' '
	AND SB1.D_E_L_E_T_ = ' '
	AND ZLX_FORNEC = FORN.A2_COD
	AND ZLX_LJFORN = FORN.A2_LOJA
	AND ZLX_TRANSP (+) = TRANS.A2_COD
	AND ZLX_LJTRAN (+) = TRANS.A2_LOJA
	AND ZLX_PRODLT = B1_COD
	AND ZLX_STATUS <> '3'
	AND ZLX.ZLX_DTENTR BETWEEN %exp:ZLY->ZLY_REFINI% AND %exp:ZLY->ZLY_REFFIM%
EndSql

While (_cAlias)->( !Eof() ) .And. !Empty((_cAlias)->ZLX_CODIGO)
	aAdd( _aResumo , {	(_cAlias)->ZLX_FILIAL,;
						(_cAlias)->ZLX_CODIGO,;
						(_cAlias)->ZLX_FORNEC +'/'+ (_cAlias)->ZLX_LJFORN +' - '+ AllTrim((_cAlias)->FORN_NOME),;
						(_cAlias)->ZLX_TRANSP +'/'+ (_cAlias)->ZLX_LJTRAN +' - '+ AllTrim((_cAlias)->TRANS_NOME),;
						(_cAlias)->ZLX_TIPOLT,;
						AllTrim((_cAlias)->B1_DESC),;
						(_cAlias)->ZLX_DTSAID})

	(_cAlias)->( DBSkip() )
EndDo

(_cAlias)->( DBCloseArea() )

If !Empty(_aResumo)
	MsgStop("Existem registros que não puderam ser fechados nesse período! Para fechar o período é necessário fechar todos os registros do mesmo.","MGLT01310")
	U_ITListBox('Resumo do Processamento',{'Filial','Recepção','Tipo','Transportador','Fornecedor','Produto','Data Saída'},_aResumo,.F.,1,'Registros fechados:')
	_lRet := .F.
EndIf

Return( _lRet )
