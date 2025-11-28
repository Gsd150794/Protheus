/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer | 29/01/2019| Chamado 27377. Ajuste para aceitar usuarios bloqueados.
Alex Wallauer | 29/05/2019| Chamado 29428. Tratamento do novo gatilho do ZZY_UNCCP na função UCFG007G().
Lucas Borges  | 17/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25.
Alex Wallauer | 07/11/2019| Chamado 31122. Ajuste do limite de seleção do F3 da função ITLSTURH().
Alex Wallauer | 26/04/2023| Chamado 43649. Novo campo de vendedor + nome valido na SA3 e opção de pesquisar.
Alex Wallauer | 11/09/2025| Chamado 52033. Tratamento para o campo novo ZZY_FILEMB.
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "FWMVCDEF.CH"

/*
===============================================================================================================================
Programa--------: UCFG007
Autor-----------: Alexandre Villar
Data da Criacao-: 07/05/2015
Descrição-------: Rotina para manutenção do cadastro de controle de acesso ao QlikView
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function UCFG007

Local _oBrowse	:= Nil

_cSelectZLE:="SELECT ZEL_CODIGO, ZEL_DESCRI FROM "+RETSQLNAME("ZEL")+" ZEL WHERE D_E_L_E_T_ = ' ' ORDER BY ZEL_CODIGO "

_aItalac_F3:={}//       1             2          3                          4                                                  5          6                    7         8          9         10         11        12
//AD(_aItalac_F3,{"1CPO_CAMPO1"  ,_cTabela   ,_nCpoChave              , _nCpoDesc                       ,_bCondTab, _cTitAux            , _nTamChv, _aDados , _nMaxSel    , _lFilAtual,_cMVRET,_bValida})
aAdd(_aItalac_F3,{"M->ZZY_FILEMB",_cSelectZLE,{|Tab|(Tab)->ZEL_CODIGO},{|Tab|AllTrim((Tab)->ZEL_DESCRI)},         ,"Local de Embarque"  ,         ,         ,             ,.F.        ,       , } )

// Configura e inicializa a Classe do Browse
_oBrowse := FWMBrowse():New()
_oBrowse:SetAlias('ZZY')
_oBrowse:SetDescription( 'QlikView - Controle de acessos' )
_oBrowse:DisableDetails()
_oBrowse:Activate()

Return

/*
===============================================================================================================================
Programa--------: MenuDef
Autor-----------: Alexandre Villar
Data da Criacao-: 07/05/2015
Descrição-------: Rotina para criação do menu na tela inicial
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function MenuDef()
Return( FWMVCMenu("UCFG007") )

/*
===============================================================================================================================
Programa--------: ModelDef
Autor-----------: Alexandre Villar
Data da Criacao-: 07/05/2015
Descrição-------: Rotina para criação do modelo de dados para o processamento
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ModelDef()

Local _oCabec	:= FWFormStruct( 1 , 'ZZY' , {|_cCampo| UCFG007CPO( _cCampo , 1 ) } )
Local _oItens	:= FWFormStruct( 1 , 'ZZY' , {|_cCampo| UCFG007CPO( _cCampo , 2 ) } )
Local _oModel	:= MpFormModel():New( "UCFG007M" ,, { || U_UCFG007U() } )

// Monta a estrutura dos campos
_oModel:AddFields(	'ZZYMASTER'	,				, _oCabec )
_oModel:AddGrid(	'ZZYDETAIL'	, 'ZZYMASTER'	, _oItens )

_oModel:SetRelation( 'ZZYDETAIL' , {	{ 'ZZY_FILIAL' , 'xFilial("ZZY")'	}	,;
										{ 'ZZY_IDUSUA' , 'ZZY_IDUSUA'		} }	,;
										ZZY->( IndexKey(1) ) )

_oModel:SetDescription( 'QlikView - Controle de acessos' )

_oModel:GetModel( 'ZZYMASTER' ):SetDescription( 'Configuração do usuário' )
_oModel:GetModel( 'ZZYDETAIL' ):SetDescription( 'Configurações do acesso' )

_oModel:GetModel( 'ZZYDETAIL' ):SetUniqueLine( { 'ZZY_COORDE' , 'ZZY_GEREN' , 'ZZY_APLIC' } )
_oModel:GetModel( 'ZZYDETAIL' ):SetOptional( .T. )
_oModel:GetModel( 'ZZYDETAIL' ):SetUseOldGrid(.T.)

_oModel:SetPrimaryKey( { 'ZZY_FILIAL' , 'ZZY_IDUSUA' } )

Return( _oModel )

/*
===============================================================================================================================
Programa--------: ViewDef
Autor-----------: Alexandre Villar
Data da Criacao-: 07/05/2015
Descrição-------: Rotina para criação da view de dados para exibição na tela
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ViewDef()

Local _oModel	:= FWLoadModel( 'UCFG007' )
Local _oCabec	:= FWFormStruct( 2 , 'ZZY' , {|_cCampo| UCFG007CPO( _cCampo , 1 ) } )
Local _oItens	:= FWFormStruct( 2 , 'ZZY' , {|_cCampo| UCFG007CPO( _cCampo , 2 ) } )
Local _oView	:= FWFormView():New()

_oView:SetModel( _oModel )
_oView:AddField(	'VIEW_CAB' , _oCabec , 'ZZYMASTER' )
_oView:AddGrid(		'VIEW_DET' , _oItens , 'ZZYDETAIL' )

_oView:CreateHorizontalBox( 'SUPERIOR' , 25 )
_oView:CreateHorizontalBox( 'INFERIOR' , 75 )

_oView:SetOwnerView( 'VIEW_CAB' , 'SUPERIOR' )
_oView:SetOwnerView( 'VIEW_DET' , 'INFERIOR' )

_oView:EnableTitleView( 'VIEW_CAB' , 'Configuração do usuário' )
_oView:EnableTitleView( 'VIEW_DET' , 'Configuração de acessos' )

Return( _oView )

/*
===============================================================================================================================
Programa--------: UCFG007CPO
Autor-----------: Alexandre Villar
Data da Criacao-: 07/05/2015
Descrição-------: Rotina para definição da exibição dos campos na tela
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function UCFG007CPO( _cCampo , _nOpc )

Local _lRet := ( Upper(AllTrim(_cCampo)) $ 'ZZY_FILIAL;ZZY_IDUSUA' )

If _nOpc == 2
	_lRet := !_lRet
EndIf

Return( _lRet )

/*
===============================================================================================================================
Programa--------: UCFG007F
Autor-----------: Alexandre Villar
Data da Criacao-: 07/05/2015
Descrição-------: Rotina para configuração da tela incial
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/

User Function UCFG007F()

Local _aArea	:= FWGetArea()
Local _cAlias	:= GetNextAlias()
Local _lRet		:= .F.

BeginSql alias _cAlias
	SELECT ZZY.R_E_C_N_O_ AS REGZZY 
	FROM  %Table:ZZY% ZZY
	WHERE D_E_L_E_T_ = ' '
	AND ZLY_FILIAL =  %xFilial:ZZY%
	AND ZZY.ZZY_IDUSUA = %exp:ZZY->ZZY_IDUSUA%
	AND ROWNUM = 1
	ORDER BY REGZZY 
EndSql

_lRet := ( (_cAlias)->REGZZY == ZZY->( Recno() ) )
(_cAlias)->( DBCloseArea() )

FWRestArea(_aArea)

Return( _lRet )

/*
===============================================================================================================================
Programa--------: ITLSTMOD
Autor-----------: Alexandre Villar
Data da Criacao-: 07/05/2015
Descrição-------: Rotina para seleção dos módulos do QlikView
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function ITLSTMOD()

Local _nI			:= 0
Local _oModel       := FwModelActivete()
Local acols := _omodel:aallsubmodels[2]:getolddata()[2]
Local aHeader := _omodel:aallsubmodels[2]:getolddata()[1]
Local n:= _omodel:aallsubmodels[2]:getline()

Private nTam		:= TamSX3( "ZZW_CODIGO" )[01]
Private nMaxSelect	:= 0
Private aResAux		:= {}
Private MvRet		:= AllTrim(ReadVar())
Private MvPar		:= ''
Private cTitulo		:= 'Módulos QlikView'
Private MvParDef	:= ''

#IFDEF WINDOWS
	oWnd := GetWndDefault()
#EndIf

DBSelectArea("ZZW")
ZZW->( DBSetOrder(1) )
ZZW->( DBGoTop() )
While ZZW->( !Eof() )
	If AllTrim(ZZW->ZZW_CODAPL) == AllTrim(acols[n][aScan(aHeader, {|X| AllTrim(Upper(X[2])) == "ZZY_APLIC" })])
		MvParDef += ZZW->ZZW_CODIGO
		aAdd( aResAux , AllTrim( ZZW->ZZW_NOME ) )
	EndIf
ZZW->( DBSkip() )
EndDo

nMaxSelect := Len(aResAux)

// Mantém a marcação anterior
If Len( AllTrim(&MvRet) ) == 0
	MvPar	:= PadR( AllTrim( StrTran( &MvRet , ";" , "" ) ) , Len(aResAux) )
	&MvRet	:= PadR( AllTrim( StrTran( &MvRet , ";" , "" ) ) , Len(aResAux) )
Else
	MvPar	:= AllTrim( StrTran( &MvRet , ";" , "" ) )
EndIf

// Monta a tela de Opções genérica do Sistema
If F_Opcoes( @MvPar , cTitulo , aResAux , MvParDef , 12 , 49 , .F. , nTam , nMaxSelect )
	// Tratamento do retorno para separação por ";"
	&MvRet := ""
	If !Empty(MvPar)
		For	_nI := 1 to Len(MvPar) Step nTam
			If !( SubStr( MvPar , _nI , 1 ) $ "|*" ) .And. !( SubStr(MvPar,_nI,nTam) $ &MvRet )
				&MvRet += SubStr(MvPar,_nI,nTam) + ";"
			EndIf
		Next
		&MvRet := SubStr(&MvRet,1,Len(&MvRet)-1)
	EndIf
EndIf

Return( .T. )

/*
===============================================================================================================================
Programa--------: UCFG007G
Autor-----------: Alexandre Villar
Data da Criacao-: 07/05/2015
Descrição-------: Rotina para atualizar os códigos de Coordenador/Gerente e não permitir informar ambos ao mesmo tempo
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function UCFG007G()

Local _lRet		:= .T.
Local _cVarAtu	:= ReadVar()
Local _oModel       := FwModelActivete()
Local acols := _omodel:aallsubmodels[2]:getolddata()[2]
Local aHeader := _omodel:aallsubmodels[2]:getolddata()[1]
Local n := _omodel:aallsubmodels[2]:getline()
Local _nPosGer	:= aScan(aHeader, {|x| AllTrim(x[2]) == "ZZY_GEREN"	})
Local _nPosCoo	:= aScan(aHeader, {|x| AllTrim(x[2]) == "ZZY_COORDE"})
Local _nPosSup	:= aScan(aHeader, {|x| AllTrim(x[2]) == "ZZY_SUPERV"})
Local _nPosVed	:= aScan(aHeader, {|x| AllTrim(x[2]) == "ZZY_VENDED"})
Local _nPosCCP	:= aScan(aHeader, {|x| AllTrim(x[2]) == "ZZY_UNCCP"	})
Local I			:= 0

If 'ZZY_UNCCP' $ Upper( _cVarAtu ) //CHAMADO DO GATILHO DO ZZY_UNCCP

    If !Empty( aCols[n][_nPosCCP] )
	   _aRet:=Strtokarr2( AllTrim(aCols[n][_nPosCCP]), ";")
	   _cRet:=""
	   For I := 1 TO Len(_aRet)
           _cRet+=AllTrim(Posicione('ZZC',1,xFilial('ZZC')+_aRet[I],'ZZC_CODFIL'))+";"
	   Next   
       _cRet:=_cRet+Space(Len(ZZY->ZZY_UNIDAD)-Len(_cRet))
    Else
       _cRet:=Space(Len(ZZY->ZZY_UNIDAD))
    EndIf

    Return _cRet

ElseIf 'ZZY_COORD' $ Upper( _cVarAtu ) .And. !Empty( aCols[n][_nPosCoo] )

	DBSelectArea('SA3')
	SA3->( DBSetOrder(1) )
	If SA3->( DBSeek( xFilial('SA3') + aCols[n][_nPosCoo] ) )
		
		If  SA3->A3_I_TIPV <> 'C'//SA3->A3_MSBLQL == '1' .Or.
			
			_lRet := .F.
			
			_aInfHlp := {}
			aAdd( _aInfHlp , 'O código informado não é de coordenador [ '+SA3->A3_I_TIPV+" ].")
			aAdd( _aInfHlp , 'O cadastro não foi classificado como coordenador. ')
			
            U_ITMsg(_aInfHlp[1],'Atenção!',_aInfHlp[2],1,,,.T.)
			
		ElseIf !Empty( aCols[n][_nPosGer] ) .Or. !Empty( aCols[n][_nPosSup] ).OR. !Empty( aCols[n][_nPosVed] )
			
			_aInfHlp := {}
			aAdd( _aInfHlp , 'O cadastro somente pode ser configurado com um: Gerente ou Coordenador ou Supervisor ou Vendedor por Linha!')
			aAdd( _aInfHlp , 'Os outros dados devem ser apagados!' )

            U_ITMsg(_aInfHlp[1],'Atenção!',_aInfHlp[2],1,,,.T.)

			_lRet := .F.
		
		EndIf

	Else 

		_lRet := ExistCpo("SA3",aCols[n][_nPosCoo])
	
	EndIf
		
ElseIf 'ZZY_GEREN' $ Upper( _cVarAtu ) .And. !Empty( aCols[n][_nPosGer] )

	DBSelectArea('SA3')
	SA3->( DBSetOrder(1) )
	If SA3->( DBSeek( xFilial('SA3') + aCols[n][_nPosGer] ) )
		
		If SA3->A3_I_TIPV <> 'G'//SA3->A3_MSBLQL == '1' .Or. 
			
			_lRet := .F.
			
			_aInfHlp := {}
			aAdd( _aInfHlp ,'O código  informado não é de gerente [ '+SA3->A3_I_TIPV+" ].")
			aAdd( _aInfHlp ,'O cadastro não foi classificado como gerente. ')
			
            U_ITMsg(_aInfHlp[1],'Atenção!',_aInfHlp[2],1,,,.T.)
			
		ElseIf !Empty(aCols[n][_nPosCoo]) .Or. !Empty( aCols[n][_nPosSup] ).OR. !Empty( aCols[n][_nPosVed] )
		
			_aInfHlp := {}
			aAdd( _aInfHlp , 'O cadastro somente pode ser configurado com um: Gerente ou Coordenador ou Supervisor ou Vendedor por Linha!')
			aAdd( _aInfHlp , 'Os outros dados devem ser apagados!' )
										
            U_ITMsg(_aInfHlp[1],'Atenção!',_aInfHlp[2],1,,,.T.)
	      										
			_lRet := .F.
		
		EndIf

	Else 

		_lRet := ExistCpo("SA3",aCols[n][_nPosGer])
		
	EndIf

ElseIf 'ZZY_SUPERV' $ Upper( _cVarAtu ) .And. !Empty( aCols[n][_nPosSup] )

	DBSelectArea('SA3')
	SA3->( DBSetOrder(1) )
	If SA3->( DBSeek( xFilial('SA3') + aCols[n][_nPosSup] ) )
		
		If SA3->A3_I_TIPV <> 'S'
			
			_lRet := .F.
			
			_aInfHlp := {}
			aAdd( _aInfHlp ,'O código  informado não é de Supervisor [ '+SA3->A3_I_TIPV+" ].")
			aAdd( _aInfHlp ,'O cadastro não foi classificado como Supervisor. ')
			
            U_ITMsg(_aInfHlp[1],'Atenção!',_aInfHlp[2],1,,,.T.)
			
		ElseIf !Empty(aCols[n][_nPosCoo]) .Or. !Empty( aCols[n][_nPosGer] ).OR. !Empty( aCols[n][_nPosVed] )
		
			_aInfHlp := {}
			aAdd( _aInfHlp , 'O cadastro somente pode ser configurado com um: Gerente ou Coordenador ou Supervisor ou Vendedor por Linha!')
			aAdd( _aInfHlp , 'Os outros dados devem ser apagados!' )
										
            U_ITMsg(_aInfHlp[1],'Atenção!',_aInfHlp[2],1,,,.T.)
	      										
			_lRet := .F.
		
		EndIf

	Else 

		_lRet := ExistCpo("SA3",aCols[n][_nPosSup])
		
	EndIf

ElseIf 'ZZY_VENDED' $ Upper( _cVarAtu ) .And. !Empty( aCols[n][_nPosVed] )

	DBSelectArea('SA3')
	SA3->( DBSetOrder(1) )
	If SA3->( DBSeek( xFilial('SA3') + aCols[n][_nPosVed] ) )
		
		If SA3->A3_I_TIPV <> 'V'
			
			_lRet := .F.
			
			_aInfHlp := {}
			aAdd( _aInfHlp ,'O código  informado não é de Vendedor [ '+SA3->A3_I_TIPV+" ].")
			aAdd( _aInfHlp ,'O cadastro não foi classificado como Vendedor. ')
			
            U_ITMsg(_aInfHlp[1],'Atenção!',_aInfHlp[2],1,,,.T.)
			
		ElseIf !Empty(aCols[n][_nPosCoo]) .Or. !Empty( aCols[n][_nPosGer] ).OR. !Empty( aCols[n][_nPosSup] )
		
			_aInfHlp := {}
			aAdd( _aInfHlp , 'O cadastro somente pode ser configurado com um: Gerente ou Coordenador ou Supervisor ou Vendedor por Linha!')
			aAdd( _aInfHlp , 'Os outros dados devem ser apagados!' )
										
            U_ITMsg(_aInfHlp[1],'Atenção!',_aInfHlp[2],1,,,.T.)
	      										
			_lRet := .F.
		
		EndIf

	Else 

		_lRet := ExistCpo("SA3",aCols[n][_nPosVed])
		
	EndIf


EndIf

Return( _lRet )

/*
===============================================================================================================================
Programa--------: UCFG007U
Autor-----------: Alexandre Villar
Data da Criacao-: 07/05/2015
Descrição-------: Rotina para validar se o ID informado já existe no cadastro
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function UCFG007U()

Local _aArea	:= FWGetArea()
Local _aInfHlp	:= {}
Local _lRet		:= .T.
Local _lInclui	:= .F.
Local _oModel	:= FWModelActive()
	
_lInclui	:= _oModel:GetOperation() == 3
_cIdUser	:= _oModel:GetValue( 'ZZYMASTER' , 'ZZY_IDUSUA' )

If _lInclui

	DBSelectArea('ZZY')
	ZZY->( DBSetOrder(1) )
	If ZZY->( DBSeek( xFilial('ZZY') + _cIdUser ) )
		
	    _lRet := .F.
		_aInfHlp := {}
		aAdd( _aInfHlp ,'O ID informado já existe no cadastro de controle de acessos do QlikView com essa configuração de Usuário+Coord.+Gerente!')
		aAdd( _aInfHlp ,'Verifique os dados informados e caso necessário utilize o cadastro que já existe para configurar o acesso.')
				
        U_ITMsg(_aInfHlp[1],'Atenção!',_aInfHlp[2],1,,,.T.)
		
	EndIf

EndIf

FWRestArea( _aArea )

Return( _lRet )

/*
===============================================================================================================================
Programa--------: ITLSTUNC
Autor-----------: Alexandre Villar
Data da Criacao-: 07/05/2015
Descrição-------: Rotina para selecionar unidades centralizadoras
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function ITLSTUNC

Local _nI := 0

Private nTam		:= 2
Private nMaxSelect	:= 10
Private aCat		:= {}
Private MvRet		:= AllTrim( ReadVar() )
Private MvPar		:= ''
Private cTitulo		:= 'Unidades Centralizadoras'
Private MvParDef	:= ''
Private cMarca		:= GetMark()

#IFDEF WINDOWS
	oWnd := GetWndDefault()
#EndIf

//====================================================================================================
// Inicializa as variáveis e verifica registros já selecionados
//====================================================================================================
DBSelectArea('ZZC')
ZZC->( DBSetOrder(1) )
If ZZC->( DBSeek( xFilial("ZZC") ) )

	While ZZC->( !Eof() ) .And. ZZC->ZZC_FILIAL == xFilial("ZZC")
	
	  	MvParDef += AllTrim( ZZC->ZZC_CODIGO )
		aAdd( aCat , AllTrim( ZZC->ZZC_DESCUN )+" ["+AllTrim(ZZC->ZZC_CODFIL)+"]" )
		
	ZZC->( DBSkip() )
	EndDo
	
EndIf

If Empty(&MvRet)

	MvPar	:= PadR( AllTrim( StrTran( &MvRet , ";" , "" ) ) , Len(aCat) )
	&MvRet	:= PadR( AllTrim( StrTran( &MvRet , ";" , "" ) ) , Len(aCat) )
	
Else

	MvPar	:= AllTrim( StrTran( &MvRet , ";" , "/" ) )

EndIf

//====================================================================================================
// Chama a função que exibe a tela de seleção
//====================================================================================================
If F_Opcoes( @MvPar , cTitulo , aCat , MvParDef , 12 , 49 , .F. , nTam , nMaxSelect )
	
	//====================================================================================================
	// Tratamento para separar retorno com ";"
	//====================================================================================================
	&MvRet := ""
	
	For _nI := 1 To Len(MvPar) Step nTam
	
		If !( SubStr( MvPar , _nI , 1 ) $ " |*" )
			&MvRet += SubStr( MvPar , _nI , nTam ) + ";"
		EndIf
		
	Next _nI
	
	&MvRet := SubStr( &MvRet , 1 , Len(&MvRet) - 1 )

EndIf

Return( .T. )

/*
===============================================================================================================================
Programa--------: ITLSTURH
Autor-----------: Alexandre Villar
Data da Criacao-: 07/05/2015
Descrição-------: Rotina para selecionar unidades do RH
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function ITLSTURH()

Local _nI := 0

Private nTam		:= 2
Private nMaxSelect	:= 15
Private aCat		:= {}
Private MvRet		:= AllTrim( ReadVar() )
Private MvPar		:= ''
Private cTitulo		:= 'Unidades do RH'
Private MvParDef	:= ''
Private cMarca		:= GetMark()

#IFDEF WINDOWS
	oWnd := GetWndDefault()
#EndIf

//====================================================================================================
// Inicializa as variáveis e verifica registros já selecionados
//====================================================================================================
DBSelectArea('ZBA')
ZBA->( DBSetOrder(1) )
If ZBA->( DBSeek( xFilial("ZBA") ) )

	While ZBA->(!Eof()) .And. ZBA->ZBA_FILIAL == xFilial("ZBA")
	
	  	MvParDef += AllTrim( ZBA->ZBA_CODIGO )
		aAdd( aCat , AllTrim( ZBA->ZBA_DESCRI ) )
		
	ZBA->( DBSkip() )
	EndDo
	
EndIf

nMaxSelect	:= Len(aCat)

If Empty( &MvRet )

	MvPar	:= PadR( AllTrim( StrTran( &MvRet , ';' , '' ) ) , Len(aCat) )
	&MvRet	:= PadR( AllTrim( StrTran( &MvRet , ';' , '' ) ) , Len(aCat) )
	
Else

	MvPar	:= AllTrim( StrTran( &MvRet , ";" , "/" ) )

EndIf

//====================================================================================================
// Chama a função que exibe a tela de seleção
//====================================================================================================
If F_Opcoes( @MvPar , cTitulo , aCat , MvParDef , 12 , 49 , .F. , nTam , nMaxSelect )

	//====================================================================================================
	// Tratamento para separar retorno com ";"
	//====================================================================================================
	&MvRet := ''
	
	For _nI := 1 To Len(MvPar) Step nTam
	
		If !(SubStr( MvPar , _nI , 1 ) $ ' |*' )
			&MvRet += SubStr( MvPar , _nI , nTam ) +';'
		EndIf
		
	Next _nI
	
	&MvRet := SubStr( &MvRet , 1 , Len(&MvRet) - 1 )

EndIf

Return( .T. )

/*
===============================================================================================================================
Programa--------: ITLSTFAB
Autor-----------: Alexandre Villar
Data da Criacao-: 07/05/2015
Descrição-------: Rotina para selecionar fábricas
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function ITLSTFAB()

Local _nI := 0

Private nTam		:= 2
Private nMaxSelect	:= 10
Private aCat		:= {}
Private MvRet		:= AllTrim( ReadVar() )
Private MvPar		:= ''
Private cTitulo		:= 'Fábricas'
Private MvParDef	:= ''
Private cMarca		:= GetMark()

#IFDEF WINDOWS
	oWnd := GetWndDefault()
#EndIf

//====================================================================================================
// Inicializa as variáveis e verifica registros já selecionados
//====================================================================================================
DBSelectArea('ZLS')
ZLS->( DBSetOrder(1) )
If ZLS->( DBSeek( xFilial("ZLS") ) )

	While ZLS->(!Eof()) .And. ZLS->ZLS_FILIAL == xFilial("ZLS")
	
	  	MvParDef += AllTrim( ZLS->ZLS_CODIGO )
		aAdd( aCat , AllTrim( ZLS->ZLS_DESCRI ) )
	
	ZLS->( DBSkip() )
	EndDo

EndIf

If Empty( &MvRet )

	MvPar	:= PadR( AllTrim( StrTran( &MvRet , ";" , "" ) ) , Len(aCat) )
	&MvRet	:= PadR( AllTrim( StrTran( &MvRet , ";" , "" ) ) , Len(aCat) )
	
Else

	MvPar	:= AllTrim( StrTran( &MvRet , ";" , "/" ) )

EndIf

//====================================================================================================
// Chama a função que exibe a tela de seleção
//====================================================================================================
If F_Opcoes( @MvPar , cTitulo , aCat , MvParDef , 12 , 49 , .F. , nTam , nMaxSelect )

	//====================================================================================================
	// Tratamento para separar retorno com ";"
	//====================================================================================================
	&MvRet := ""
	
	For _nI := 1 To Len(MvPar) Step nTam
	
		If !( SubStr( MvPar , _nI , 1 ) $ " |*" )
			&MvRet += SubStr( MvPar , _nI , nTam ) +";"
		EndIf
		
	Next _nI
	
	&MvRet := SubStr( &MvRet , 1 , Len(&MvRet) - 1 )

EndIf

Return(.T.)
