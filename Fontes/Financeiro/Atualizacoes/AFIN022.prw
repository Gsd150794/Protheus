/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |01/08/2019| Chamado 30151. Alterada chamada do parâmetro LT_NATGLT.
Lucas Borges  |09/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25.
Alex Wallauer |29/10/2020| Chamado 34262. Remoção de bugs apontados pelo Totvs CodeAnalysis.
===============================================================================================================================
*/

#Include "TOTVS.ch"

#Define P_FORNECEDOR	03
#Define P_LOJA			04
#Define P_NOMFOR		05
#Define P_VALOR	 		07
#Define P_SALDO			10

/*
===============================================================================================================================
Programa----------: AFIN022
Autor-------------: Talita Teixeira
Data da Criacao---: 14/01/2013
Descrição---------: Rotina responsavel pela geracao das faturas a pagar de forma automatica. Chamado Help Desk 2152
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AFIN022()

Local cAlias		:= "SE2"  

Private cCadastro	:= "Faturas a Pagar"
Private aRotina		:= {}

aAdd( aRotina , { "Pesquisar"	, "AxPesqui"		, 0 , 1 } ) 
aAdd( aRotina , { "Selecionar"	, "U_AFIN22SL"		, 0 , 3 } )
aAdd( aRotina , { "Legenda"		, "FA040Legenda"	, 0 , 7 ,, .F. } )

DBSelectArea(cAlias)
(cAlias)->( DBSetOrder(1) )

MBrowse( ,,,, "SE2" ,,,,,, Fa040Legenda("SE2") ,,,,,,,, )

Return

/*
===============================================================================================================================
Programa----------: AFIN22SL
Autor-------------: Talita Teixeira
Data da Criacao---: 14/01/2013
Descrição---------: Rotina que controla a incialização do processamento
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AFIN22SL()

Local _oDlg		:= Nil
Local _oPanel	:= Nil
Local _nOpca	:= 2
Local _cMix		:= CRIAVAR( "E2_L_MIX"   , .T. )
Local _cSetor	:= CRIAVAR( "E2_L_SETOR" , .T. )
Local _dDatVen	:= CRIAVAR( "E2_VENCREA" , .T. )
Local _nPosLin	:= 005
Local _nPosCol	:= 005
Local _aRotBkp	:= aClone( aRotina ) //Definir novo aRotina para o Processamento

//================================================================================
// Monta a tela de parametrização inicial do processamento
//================================================================================
DEFINE MSDIALOG _oDlg FROM 000,000 TO 250,400 TITLE OemToAnsi( 'Geração de Faturas a Pagar' ) PIXEL

	_oDlg:lMaximized	:= .F.
	_oPanel		  		:= TPanel():New( 0 , 0 , '' , _oDlg ,, .T. , .T. ,,, 20 , 20 )
	_oPanel:Align 		:= CONTROL_ALIGN_ALLCLIENT
	
	@ _nPosLin       , _nPosCol TO _nPosLin + 035 , _nPosCol + 190										OF _oPanel PIXEL
	@ _nPosLin + 015 , _nPosCol + 014 Say	OemToAnsi( "Digite o número do MIX:" )						OF _oPanel PIXEL SIZE 060,061
	@ _nPosLin + 012 , _nPosCol + 130 MSGET _cMix	F3 'ZLE_01' 										OF _oPanel PIXEL SIZE 010,011
	
	@ _nPosLin + 036 , _nPosCol TO _nPosLin + 070 , _nPosCol + 190										OF _oPanel PIXEL
	@ _nPosLin + 050 , _nPosCol + 014 Say	OemToAnsi( "Digite o Setor:" )								OF _oPanel PIXEL SIZE 060,061
	@ _nPosLin + 047 , _nPosCol + 130 MSGET _cSetor	F3 'ZL2_01'											OF _oPanel PIXEL SIZE 010,011
	
	@ _nPosLin + 071 , _nPosCol TO _nPosLin + 100 , _nPosCol + 190										OF _oPanel PIXEL
	@ _nPosLin + 085 , _nPosCol + 014 Say	OemToAnsi( "Digite a data de Vencimento da Fatura:" )		OF _oPanel PIXEL SIZE 100,110
	@ _nPosLin + 082 , _nPosCol + 130 MSGET	_dDatVen Valid If( _nOpca <> 0 , !Empty( _dDatVen) , .T. )	OF _oPanel PIXEL SIZE 050,011 HASBUTTON
	
	DEFINE SBUTTON FROM _nPosLin + 105 , 144 Type 1 ENABLE OF _oDlg;
		ACTION ( IIf(	AFIN022PAR( _cMix , _cSetor , _dDatVen )									,;
						( AFIN022PRC( _cMix , _cSetor , _dDatVen ) , _oDlg:End() )					,;
						Nil	) )
		
	DEFINE SBUTTON FROM _nPosLin + 105 , 169 Type 2 ENABLE OF _oDlg;
		ACTION ( MsgStop("Operação cancelada pelo usuário!","AFIN02201") , _oDlg:End() )

ACTIVATE MSDIALOG _oDlg CENTERED

aRotina := _aRotBkp

Return

/*
===============================================================================================================================
Programa----------: AFIN022PRC
Autor-------------: Alexandre Villar
Data da Criacao---: 10/09/2014
Descrição---------: Rotina que controla o processamento
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AFIN022PRC( _cMix , _cSetor , _dDatVen )

Local _cTitAux	:= "Seleção de Títulos para a Fatura:"
Local _aHeader	:= {'[ ]','Filial','Fornecedor','Loja','Nome','Títulos','Valor','Acréscimo','Descontos','Saldo','Cód. MIX','Setor'}
Local _lRet		:= .F.
Local _nI		:= 0
Local _nValor	:= 0
Local _nQtde	:= 0
Local _oLbxAux	:= Nil
Local _oValor	:= Nil
Local _oQtde	:= Nil
Local _oDlg		:= Nil
Local _oFont	:= Nil
Local _aColors	:= {}
Local _aColRes	:= {}
Local _aColTit	:= {}
Local _aCoors	:= FWGetDialogSize(oMainWnd)
Local _aSize   	:= MsAdvSize( .T. ) 
Local _aObjAux	:= {}
Local _aPosAux	:= {}
Local _aButtons	:= {}

Local _bOk		:= {|| _aColRes := aClone( _oLbxAux:aArray )	, _lRet := .T. , _oDlg:End() }
Local _bCancel	:= {||											  _lRet := .F. , _oDlg:End() }
Local _bDblClk 	:= {|| ITDblClk( @_oLbxAux , @_oValor , @_nValor , @_oQtde , @_nQtde ) }

Private	_nITPosAnt	:= 0

aRotina := {}

//================================================================================
// Cores da MsSelect
//================================================================================
aAdd( _aColors , { "TRB_SALDO==TRB_VALOR .And. TRB_SALDO>0" , "BR_VERDE"	} ) //Titulo em Aberto
aAdd( _aColors , { "TRB_SALDO<>TRB_VALOR .And. TRB_SALDO>0" , "BR_AZUL"		} ) //Titulo parcialmente baixado

//================================================================================
// Consulta os dados para a montar a tela de seleção
//================================================================================
LjMsgRun( 'Pesquisando os registros...' , 'Aguarde!' , {|| CursorWait() , AFIN022SEL( _cMix , _cSetor , @_aColRes , @_aColTit ) , CursorArrow() } )

If Empty(_aColRes)
	MsgStop("Não foram encontrados dados para exibir. Verifique os parâmetros e tente novamente!","AFIN02202")
	Return
EndIf

//================================================================================
// Recupera o posicionamento da tela
//================================================================================
aAdd( _aObjAux , { 100 , 100 , .T. , .T. } )
_aInfo   := { _aSize[ 1 ] , _aSize[ 2 ] , _aSize[ 3 ] , _aSize[ 4 ] , 3 , 2 }
_aPosAux := MsObjSize( _aInfo , _aObjAux )

DEFINE FONT _oFont NAME "Verdana" SIZE 05,12

//================================================================================
// Inclusão de botões
//================================================================================
aAdd( _aButtons , { "Excel"		, {|| DlgToExcel( { { "ARRAY" , _cTitAux , _aHeader , _aColRes } } ) }	, "Exportação de Dados para Excel" , "Excel"		} )
aAdd( _aButtons , { "Pesquisar"	, {|| AFIN022PSQ( _oLbxAux ) }											, "Exportação de Dados para Excel" , "Pesquisar"	} )

//================================================================================
// Monta a tela de seleção dos Títulos
//================================================================================
DEFINE MSDIALOG _oDlg TITLE _cTitAux FROM _aCoors[1],_aCoors[2] TO _aCoors[3],_aCoors[4] PIXEL
	
	@ _aPosAux[01][01] , 0005 Say OemToAnsi( "Valor Total Selecionado:" )							OF _oDlg PIXEL
	@ _aPosAux[01][01] , 0070 Say _oValor	VAR _nValor		Picture "@E 999,999,999.99"	SIZE 60,8	OF _oDlg PIXEL
	@ _aPosAux[01][01] , 0120 Say OemToAnsi( "Quantidade de Títulos Selecionados:" )				OF _oDlg PIXEL
	@ _aPosAux[01][01] , 0220 Say _oQtde	VAR _nQtde		Picture "@E 99,999"			SIZE 50,8	OF _oDlg PIXEL
	
	_aPosAux[01][01] += 010
	
	@_aPosAux[01][01] , _aPosAux[01][02]	LISTBOX _oLbxAux				;
						 					FIELDS HEADER ""				;
											ON DBLClick( Eval( _bDblClk ) )	;
											SIZE _aPosAux[01][04] , ( _aPosAux[01][03] - _aPosAux[01][01] ) OF _oDlg PIXEL
	
	_oLbxAux:AHeaders		:= aClone( _aHeader )
	_oLbxAux:bHeaderClick	:= { |oObj,nCol| ITOrdLbx( oObj , nCol , _oLbxAux , @_oValor , @_nValor , @_oQtde , @_nQtde ) }
	_oLbxAux:SetArray( _aColRes )
	
	//===========================================================================
	// Monta os dados para o ListBox                                           
	//===========================================================================
	For _nI := 1 To Len( _aHeader )
	
		If _nI == 1
			
			_cColsAux := "{|| {	IIf( _aColRes[_oLbxAux:nAt,"+ cValtoChar(_nI) +"] , LoadBitmap( GetResources() , 'LBOK' ) , LoadBitmap( GetResources() , 'LBNO' ) ) ,"
			
		Else
		
			_cColsAux += "		_aColRes[_oLbxAux:nAt,"+ cValtoChar(_nI) +"] ,"
			
		EndIf
		
	Next _nI
	
	//===========================================================================
	// Atribui os dados ao ListBox                                             
	//===========================================================================
	_cColsAux		:= SubStr( _cColsAux , 1 , Len(_cColsAux)-1 ) + "}}"
	_oLbxAux:bLine	:= &( _cColsAux )

ACTIVATE MSDIALOG _oDlg ON INIT EnchoiceBar( _oDlg , _bOk , _bCancel ,, _aButtons ) CENTERED

If _lRet
	LjMsgRun( 'Processando a geração das Faturas...' , 'Aguarde!' , {|| CursorWait() , AFIN022GRV( _aColRes , _aColTit , _dDatVen , _cMix ) , CursorArrow() } )
EndIf

Return

/*
===============================================================================================================================
Programa----------: AFIN022PSQ
Autor-------------: Alexandre Villar
Data da Criacao---: 10/09/2014
Descrição---------: Rotina que controla o processamento
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AFIN022PSQ( _oLbxAux )

Local _oGet1		:= Nil
Local _oDlg			:= Nil
Local _cGet1		:= Space(100)
Local _cComboBx1	:= ""
Local _aComboBx1	:= { "Fornecedor+Loja" , "Nome do Fornecedor" , "Valor dos Títulos (Casas decimais com ',' vírgula: 999,99)" }
Local _nOpca		:= 0
Local _nI			:= 0
Local _nX			:= 0
Local _lAchou		:= .F.

DEFINE MSDIALOG _oDlg TITLE "Pesquisar" FROM 178,181 TO 259,697 PIXEL

@004,003 ComboBox _cComboBx1 Items _aComboBx1	Size 213,010 PIXEL OF _oDlg
@020,003 MsGet _oGet1 Var _cGet1				Size 212,009 PIXEL OF _oDlg COLOR CLR_BLACK Picture "@!"

DEFINE SBUTTON FROM 004,227 Type 1 ENABLE ACTION ( _nOpca := 1 , _oDlg:End() ) OF _oDlg
DEFINE SBUTTON FROM 021,227 Type 2 ENABLE ACTION ( _nOpca := 0 , _oDlg:End() ) OF _oDlg

ACTIVATE MSDIALOG _oDlg CENTERED

If _nOpca == 1

	For _nX := 1 To Len(_aComboBx1)
	
		If _cComboBx1 == _aComboBx1[_nX]
		
			Do Case
			
				Case _nX == 1
					
					aSort( _oLbxAux:aArray ,,, { |X,Y| ( X[P_FORNECEDOR] + X[P_LOJA] ) < ( Y[P_FORNECEDOR] + Y[P_LOJA] ) } )
					
					_cGet1 := RTrim( _cGet1 )
					
					For _nI := 1 To Len( _oLbxAux:aArray )
					    
						If _cGet1 == SubStr( _oLbxAux:aArray[_nI][P_FORNECEDOR] + _oLbxAux:aArray[_nI][P_LOJA] , 1 , Len( _cGet1 ) )
							
							_oLbxAux:nAt	:= _nI
							_lAchou			:= .T.
							Exit
							
						EndIf
						
					Next _nI
				
				Case _nX == 2
				
					aSort( _oLbxAux:aArray ,,, { |X,Y| X[P_NOMFOR] < Y[P_NOMFOR] } )
					
					_cGet1 := RTrim( _cGet1 )
					
					For _nI := 1 To Len( _oLbxAux:aArray )
					    
						If _cGet1 == SubStr( _oLbxAux:aArray[_nI][P_NOMFOR] , 1 , Len( _cGet1 ) )
							
							_oLbxAux:nAt	:= _nI
							_lAchou			:= .T.
							Exit
							
						EndIf
						
					Next _nI
				
				Case _nX == 3
					
					aSort( _oLbxAux:aArray ,,, { |X,Y| X[P_VALOR] < Y[P_VALOR] } )
					
					_cGet1 := StrTran( _cGet1 , '.' , ''  )
					_cGet1 := StrTran( _cGet1 , ',' , '.' )
					_cGet1 := Val( _cGet1 )
					
					For _nI := 1 To Len( _oLbxAux:aArray )
					    
					    If _cGet1 == _oLbxAux:aArray[_nI][P_VALOR]
							
							_oLbxAux:nAt	:= _nI
							_lAchou			:= .T.
							Exit
							
						EndIf
						
					Next _nI
				
			EndCase
			
		EndIf
		
	Next _nX
	
EndIf

If _lAchou
	_oLbxAux:Refresh()
EndIf

Return
 
/*
===============================================================================================================================
Programa----------: AFIN022SEL
Autor-------------: Alexandre Villar
Data da Criacao---: 10/09/2014
Descrição---------: Rotina que controla o processamento
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AFIN022SEL( _cMix , _cSetor , _aColRes , _aColTit )

Local _cAlias	:= GetNextAlias()
Local _cQuery	:= ''
Local _nValTot	:= 0
Local _nSdAcres	:= 0
Local _nSdDecre	:= 0
Local _nSaldo	:= 0
Local _nQtdTit	:= 0
Local _cCodFor	:= ''
Local _cLojFor	:= ''

_aColRes := {}
_aColTit := {}

//================================================================================
// Query para selecao dos dados
//================================================================================
_cQuery := " SELECT "
_cQuery += " 	SE2.E2_FILIAL  , SE2.E2_PREFIXO , SE2.E2_NUM     , SE2.E2_PARCELA , SE2.E2_TIPO    , SE2.E2_NATUREZ , SE2.E2_FORNECE , SE2.E2_LOJA  , "
_cQuery += " 	SE2.E2_NOMFOR  , SE2.E2_EMISSAO , SE2.E2_VENCTO  , SE2.E2_VENCREA , SE2.E2_VALOR   , SE2.E2_SALDO   , SE2.E2_HIST    , SE2.E2_L_MIX , "
_cQuery += " 	SE2.E2_L_LINRO , SE2.E2_L_SETOR , SE2.E2_L_AGENC , SE2.E2_L_CONTA , SE2.E2_L_BANCO , SE2.E2_SDACRES , SE2.E2_SDDECRE , SE2.R_E_C_N_O_ "
_cQuery += " FROM " + RetSqlName("SE2") + " SE2 "
_cQuery += " WHERE "
_cQuery += "     SE2.D_E_L_E_T_ = ' ' "
_cQuery += " AND SE2.E2_SALDO   > 0 "
_cQuery += " AND SE2.E2_DATALIB <> ' ' "
_cQuery += " AND SE2.E2_TIPO    NOT IN ( 'NDF' , 'PA' ) "
_cQuery += " AND SE2.E2_PORTADO	= ' ' "
_cQuery += " AND SE2.E2_NUMBOR	= ' ' "
_cQuery += " AND SE2.E2_IDCNAB  = ' ' "
_cQuery += " AND SE2.E2_L_MIX   = '"+ _cMix +"' "
_cQuery += " AND SE2.E2_L_SETOR = '"+ _cSetor +"' "
_cQuery += " AND SE2.E2_FILIAL  = '"+ xFilial("SE2") +"' "
_cQuery += " AND EXISTS (	SELECT E2.E2_FILIAL , E2.E2_FORNECE , E2.E2_LOJA , COUNT(E2.R_E_C_N_O_) "
_cQuery += " 				FROM " + RetSqlName("SE2") + " E2 "
_cQuery += " 				WHERE "
_cQuery += " 					E2.D_E_L_E_T_  = ' ' "
_cQuery += " 				AND E2.E2_SALDO    > 0 "
_cQuery += " 				AND E2.E2_L_MIX    = '"+ _cMix	+"' "
_cQuery += " 				AND SE2.E2_L_SETOR = '"+ _cSetor	+"' "
_cQuery += " 				AND E2.E2_DATALIB  <> ' ' "
_cQuery += " 				AND E2.E2_TIPO     NOT IN ( 'NDF' , 'PA' ) "
_cQuery += " 				AND E2.E2_FILIAL   = SE2.E2_FILIAL "
_cQuery += " 				AND E2.E2_FORNECE  = SE2.E2_FORNECE "
_cQuery += " 				AND E2.E2_LOJA     = SE2.E2_LOJA "
_cQuery += " 				GROUP BY E2.E2_FILIAL , E2.E2_FORNECE , E2.E2_LOJA "
_cQuery += " 				HAVING COUNT( SE2.R_E_C_N_O_ ) >= 2  "
_cQuery += " ) "

_cQuery += " ORDER BY SE2.E2_FILIAL , SE2.E2_FORNECE , SE2.E2_LOJA "

If Select(_cAlias) > 0
	(_cAlias)->( DBCloseArea() )
EndIf

DBUseArea( .T. , "TOPCONN" , TcGenQry( ,, _cQuery ) , _cAlias , .T. , .F. )

DBSelectArea(_cAlias)
(_cAlias)->( DBGoTop() )
While (_cAlias)->(!Eof())
	
	If (_cAlias)->( E2_FORNECE + E2_LOJA ) <> _cCodFor + _cLojFor
		
		If !Empty( _cCodFor )
		
			aAdd( _aColRes , {	.F.	   																		,;
								cFilAnt																		,;
								_cCodFor																	,;
								_cLojFor		  															,;
								AllTrim( Posicione('SA2',1,xFilial('SA2')+_cCodFor+_cLojFor,'A2_NOME') )	,;
								Transform( _nQtdTit		, '@E 999,999,999' )								,;
								Transform( _nValTot		, '@E 999,999,999.99' )								,;
								Transform( _nSdAcres	, '@E 999,999,999.99' )								,;
								Transform( _nSdDecre	, '@E 999,999,999.99' )								,;
								Transform( _nSaldo		, '@E 999,999,999.99' )								,;
								_cMix																		,;
								_cSetor																		})
		
		EndIf
		
		_nValTot	:= 0
		_nSdAcres	:= 0
		_nSdDecre	:= 0
		_nSaldo		:= 0
		_nQtdTit	:= 0
		_cCodFor	:= (_cAlias)->( E2_FORNECE	)
		_cLojFor	:= (_cAlias)->( E2_LOJA	)
		
	EndIf
	
	aAdd( _aColTit , {	.F.						,;
						(_cAlias)->E2_FORNECE	,;
						(_cAlias)->E2_LOJA		,;
						(_cAlias)->R_E_C_N_O_	})
	
	_nValTot	+= (_cAlias)->E2_VALOR
	_nSdAcres	+= (_cAlias)->E2_SDACRES
	_nSdDecre	+= (_cAlias)->E2_SDDECRE
	_nSaldo		+= (_cAlias)->E2_SALDO
	_nQtdTit++

(_cAlias)->( DBSkip() )
EndDo

(_cAlias)->( DBCloseArea() )

Return

/*
===============================================================================================================================
Programa----------: AFIN022GRV
Autor-------------: Alexandre Villar
Data da Criacao---: 09/09/2014
Descrição---------: Rotina que Processa a geração da Fatura e a Atualização dos Títulos
Parametros--------: _aColRes = Dados a serem gerados
                    _aColTit = Titulos
                    _dDatVen = Data vencimento
                    _cMix    = Codigo do Mix
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AFIN022GRV( _aColRes , _aColTit , _dDatVen , _cMix )

Local _nI		:= 0
Local _nX		:= 0
Local _nTot		:= Len( _aColRes )
Local _nTit		:= Len( _aColTit )
Local _aResult	:= {}
Local _aArray	:= {}
Local _aTit  	:= {}
Local _cCodNat	:= AllTrim(SuperGetMV("LT_NATGLT",.F.,"222001"))// Natureza dos titulos do Produtor
Local _cNumFat	:= ''
Local _cFatAux	:= ''

Local _nModAtu	:= nModulo
Local _cModAtu	:= cModulo
Local _dDataDe	:= SToD('')
Local _dDataAte	:= SToD('')
Local _bGetMV  	:= {||  GetMV( 'MV_NUMFATP' ,, '0' ) }


Private lMsErroAuto := .F.

If _nTot > 0 .And. !Empty( _aColRes )
	
	Begin Transaction
	
	_aColRes := aSort( _aColRes ,,, { |X,Y| ( X[P_FORNECEDOR] + X[P_LOJA] ) < ( Y[P_FORNECEDOR] + Y[P_LOJA] ) } )
	
	For _nI := 1 To _nTot
		
		_aTit		:= {}
		_dDataDe	:= SToD('')
		_dDataAte	:= SToD('')
		
		If _aColRes[_nI][01] //Verifica se o Fornecedor foi selecionado na lista
		
			DBSelectArea("SA2")
			SA2->( DBSetOrder(1) )
			If SA2->( DBSeek( xFilial("SA2") + _aColRes[_nI][P_FORNECEDOR] + _aColRes[_nI][P_LOJA] ) )
				
				_nX := 1
				
				While _nX <= _nTit
					
					If SA2->( A2_COD + A2_LOJA ) == _aColTit[_nX][02] + _aColTit[_nX][03]
					
						DBSelectArea("SE2")
						SE2->( DBGoTo( _aColTit[_nX][04] ) )
						
						aAdd( _aTit , {	PadR( SE2->E2_PREFIXO	, TamSX3('E2_PREFIXO')[01] )	,;
										PadR( SE2->E2_NUM		, TamSX3('E2_NUM')[01] )		,;
										PadR( SE2->E2_PARCELA	, TamSX3('E2_PARCELA')[01] )	,;
										PadR( SE2->E2_TIPO		, TamSX3('E2_TIPO')[01] )		,;
										.F.														})
						
						If SE2->E2_EMISSAO < _dDataDe
							_dDataDe := SE2->E2_EMISSAO
						ElseIf SE2->E2_EMISSAO > _dDataAte
							_dDataAte := SE2->E2_EMISSAO
						EndIf
						
						If ( !Empty(_dDataDe) .And. Empty(_dDataAte) )
							_dDataAte := _dDataDe
						ElseIf ( Empty(_dDataDe) .And. !Empty(_dDataAte) )
							_dDataDe := _dDataAte
						EndIf
						
					EndIf
					
				_nX++
				EndDo
				
			EndIf
			
		EndIf
		
		If !Empty( _aTit )
			
			//================================================================================
			// Recupera o último número de Fatura gerado na Filial e pega o próximo
			//================================================================================
			_cNumFat := EVAL(_bGetMV)//GetMV( 'MV_NUMFATP' ,, '0' )
			_cNumFat := Soma1( _cNumFat )
			
			While !MayIUseCod( 'AFIN022_'+ _cNumFat )
				_cNumFat := Soma1( _cNumFat )
			EndDo
		    
		    //================================================================================
			// Registra o número utilizado no parâmetro
			//================================================================================
			_cFatAux := EVAL(_bGetMV)//GetMV( 'MV_NUMFATP' ,, '0' )
			
			If _cNumFat > _cFatAux
			   PutMV( 'MV_NUMFATP' , _cNumFat )
			EndIf
		    
			_aArray		:= { 'MAN' , 'FT' , _cNumFat , _cCodNat , _dDataDe , _dDataAte , SA2->A2_COD , SA2->A2_LOJA , SA2->A2_COD , SA2->A2_LOJA , '001' , 01 , _aTit , 0 , 0 }
			nModulo		:= 6
		    cModulo		:= "FIN"
			
			MsExecAuto( {|X,Y| FINA290( X , Y ) } , 3 , _aArray , )
			
			If lMsErroAuto
			    _cLogAut := MostraErro( GetTempPath() )
			    aAdd( _aResult , { SA2->A2_COD +'/'+ SA2->A2_LOJA , 'Falha na geração da Fatura: '+ _cLogAut } )
			Else
				AFIN022VEN( _dDatVen , _cMix )
			    aAdd( _aResult , { SA2->A2_COD +'/'+ SA2->A2_LOJA , 'Fatura gerada com sucesso!' } )
			EndIf
			
			nModulo := _nModAtu
		    cModulo := _cModAtu
			
		EndIf
		
	Next _nI
	
	End Transaction
	
EndIf

If !Empty( _aResult )
	U_ITListBox( 'Status do Processamento:' , { 'Fornecedor' , 'Status' } , _aResult , .F. , 1 )
Else
	MsgAlert("O processamento foi concluído sem gerar Faturas! Verifique os dados e selecione os Fornecedores desejados para tentar novamente.","AFIN022003")
EndIf

Return

/*
===============================================================================================================================
Programa----------: ITDBLCLK
Autor-------------: Alexandre Villar
Data da Criacao---: 14/03/2014
Descrição---------: Processa função do duplo click
Parametros--------: oLbxDados - Objeto de Dados do ListBox
Retorno-----------: lRet	- Caso o usuário saia da tela clicando em "Confirmar" retorna .T.
===============================================================================================================================
*/
Static Function ITDBLCLK( _oLbxDados , _oValor , _nValor , _oQtde , _nQtde )

_oLbxDados:aArray[ _oLbxDados:nAt , 01 ] := !_oLbxDados:aArray[ _oLbxDados:nAt , 01 ]

If _oLbxDados:aArray[ _oLbxDados:nAt , 01 ]
	_nValor += Val( StrTran( StrTran( _oLbxDados:aArray[ _oLbxDados:nAt , P_SALDO ] , '.' , '' ) , ',' , '.' ) )
	_nQtde++
Else
	_nValor -= Val( StrTran( StrTran( _oLbxDados:aArray[ _oLbxDados:nAt , P_SALDO ] , '.' , '' ) , ',' , '.' ) )
	_nQtde--
EndIf

_oValor:Refresh()
_oQtde:Refresh()
_oLbxDados:Refresh()

Return

/*
===============================================================================================================================
Programa----------: ITOrdLbx
Autor-------------: Alexandre Villar
Data da Criacao---: 14/03/2014
Descrição---------: Processa função do duplo click no cabeçalho da coluna
Parametros--------: oLbxDados - Objeto de Dados do ListBox
Retorno-----------: lRet	- Caso o usuário saia da tela clicando em "Confirmar" retorna .T.
===============================================================================================================================
*/
Static Function ITOrdLbx( _oX , _nCol , _oLbxAux , _oValor , _nValor , _oQtde , _nQtde )

Local _nI := 0

If _nCol == 1

	For _nI := 1 To Len( _oLbxAux:aArray )
	
		_oLbxAux:aArray[_nI][01] := !_oLbxAux:aArray[_nI][01]
		
		If _oLbxAux:aArray[_nI][01]
			_nValor += Val( StrTran( StrTran( _oLbxAux:aArray[_nI][P_SALDO] , '.' , '' ) , ',' , '.' ) )
			_nQtde++
		Else
			_nValor -= Val( StrTran( StrTran( _oLbxAux:aArray[_nI][P_SALDO] , '.' , '' ) , ',' , '.' ) )
			_nQtde--
		EndIf
		
		_oValor:Refresh()
		_oQtde:Refresh()
		
	Next _nI

Else

	If	Type("_nITPosAnt") == "U"
		Return
	EndIf
	
	If	_nCol > 0
		
		If _nCol <> _nITPosAnt
			_aSort( _oLbxAux:aArray ,,, { |x,y| x[_nCol] < y[_nCol] } )
			_nITPosAnt := _nCol
		Else
			_aSort( _oLbxAux:aArray ,,, { |x,y| x[nCol] > y[nCol] } )
			_nITPosAnt := 0
		EndIf
		
	EndIf

EndIf

_oLbxAux:Refresh()

Return

/*
===============================================================================================================================
Programa----------: AFIN022
Autor-------------: Alexandre Villar
Data da Criacao---: 14/03/2014
Descrição---------: Valida o preenchimento dos parâmetros na tela inicial do processamento
Parametros--------: oLbxDados - Objeto de Dados do ListBox
Retorno-----------: lRet	- Caso o usuário saia da tela clicando em "Confirmar" retorna .T.
===============================================================================================================================
*/
Static Function AFIN022PAR(_cMix,_cSetor,_dDatVen)

Local _lRet := .T.

If Empty(_cMix)
	MsgStop("É obrigatório informar o MIX para o processamento!","AFIN02204")
	_lRet := .F.
EndIf

If _lRet

	DBSelectArea('ZLF')
	ZLF->( DBSetOrder(1) )
	If !ZLF->( DBSeek( xFilial('ZLF') + _cMix ) )
		MsgStop("O Mix informado não é válido ou não possui movimentações registradas! Verifique os dados e tente novamente.","AFIN02205")
		_lRet := .F.
	EndIf

EndIf

If _lRet .And. Empty(_cSetor)
	 MsgStop("É obrigatório informar o Setor para o processamento!","AFIN02206")
	_lRet := .F.
EndIf

If _lRet

	DBSelectArea('ZLF')
	ZLF->( DBSetOrder(5) ) //Filial + Cód. Mix. + Versão + Setor
	If !ZLF->( DBSeek( xFilial('ZLF') + _cMix + '1' + _cSetor ) )
		MsgStop("O Setor informado não é válido ou não possui movimentações no Mix informado! Verifique os dados e tente novamente.","AFIN02207")
		_lRet := .F.
	EndIf

EndIf

If _lRet .And. Empty(_dDatVen)
	MsgStop("É obrigatório informar a Data de Vencimento da Fatura para o processamento!","AFIN02208")
	_lRet := .F.
EndIf

If _lRet .And._dDatVen < Date()
	MsgStop("A Data de Vencimento da Fatura para o processamento não pode ser menor que a data atual!","AFIN02209")
	_lRet := .F.
EndIf

Return( _lRet )

/*
===============================================================================================================================
Programa----------: AFIN022
Autor-------------: Alexandre Villar
Data da Criacao---: 14/03/2014
Descrição---------: Processa a atualização do vencimento da fatura pois a rotina automática gera com a data do sistema
Parametros--------: oLbxDados - Objeto de Dados do ListBox
Retorno-----------: lRet	- Caso o usuário saia da tela clicando em "Confirmar" retorna .T.
===============================================================================================================================
*/
Static Function AFIN022VEN( _dDatVen , _cMix )

Local _aArea	:= FWGetArea()
Local _cChave	:= SE2->( E2_FILIAL + E2_FATPREF + E2_FATURA + '01' + E2_TIPOFAT + E2_FATFOR + E2_FATLOJ )

DBSelectArea('SE2')
SE2->( DBSetOrder(1) )
If SE2->( DBSeek( _cChave ) )
	
	DBSelectArea("ZL3")
	ZL3->( DBSetOrder(1) )
	ZL3->( DBSeek( xFilial("ZL3") + SA2->A2_L_LI_RO ) )
	
	SE2->( RecLock('SE2',.F.) )
		SE2->E2_VENCTO	:= _dDatVen
		SE2->E2_VENCORI	:= _dDatVen
		SE2->E2_VENCREA	:= DataValida( _dDatVen )
		SE2->E2_L_MIX	:= _cMix
		SE2->E2_L_SETOR	:= ZL3->ZL3_SETOR
		SE2->E2_L_LINRO := SA2->A2_L_LI_RO
	SE2->( MSUnLock() )
	
EndIf

FWRestArea( _aArea )

Return

/*
===============================================================================================================================
Programa----------: F290TIT
Autor-------------: Alexandre Villar
Data da Criacao---: 14/03/2014
Descrição---------: Ponto de Entrada que valida os títulos selecionados na lista
Parametros--------: Nenhum
Retorno-----------: lRet	- Caso o título esteja ok para o processamento retorna .T.
===============================================================================================================================
*/
User Function F290TIT()

Local _lRet := .T.

//================================================================================
// Verifica para não permitir agrupar títulos do mesmo fornecedor porém com Loja
// diferente na rotina de geração Automática de Faturas
//================================================================================
If FunName() == 'AFIN022'
	_lRet := SA2->( A2_COD + SA2->A2_LOJA ) == SE2->( E2_FORNECE + E2_LOJA )
EndIf

Return( _lRet )
