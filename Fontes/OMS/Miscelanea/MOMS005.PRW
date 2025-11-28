/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
       Autor      |    Data    |                                             Motivo                                           
-------------------------------------------------------------------------------------------------------------------------------
 Josué Danich     | 17/12/2015 | Validacao e gravacao e log para Gestao de Fechamento de Comissao - Chamado 11158  
-------------------------------------------------------------------------------------------------------------------------------
 Josué Danich     | 26/06/2019 | Ajuste para loboguara - Chamado 28886
-------------------------------------------------------------------------------------------------------------------------------
 Lucas Borges     | 11/10/2019 | Removidos os Warning na compilação da release 12.1.25. Chamado 28346
 -------------------------------------------------------------------------------------------------------------------------------
 Jonathan         | 04/03/2020 | Foi solicitado que os programas desconsiderassem as origens 'R' e 'F'. Chamado 31910
===============================================================================================================================
*/
//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================

#Include "TOTVS.ch"
#Include 'FWMVCDef.Ch'
#Include 'ApWizard.Ch'
#Include "TOPCONN.CH"

#Define MB_OK	0
#Define CRLF	Chr(13)+Chr(10)

/*
===============================================================================================================================
Programa----------: MOMS005
Autor-------------: Alexandre Villar
Data da Criacao---: 19/08/2014
===============================================================================================================================
Descrição---------: Rotina de cálculo da comissão para Leite Magro para validação do adicional
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS005()

Local _aParam	:= {}
Local _aParRet	:= {}
Local _oBrowse	:= Nil

Private aRotina	:= MenuDef()

aAdd( _aParam , { 2 , 'Tipo Proc.: '	, 1				, {'1 - Leite Magro','2 - Bonificações'} , 60 , '.T.' , .T. } )
_aParRet := { _aParam[01][03] }

If ParamBox( _aParam , 'Configuração do Processamento!' , @_aParRet ,,,,,,,, .F. , .F. )
	
	If ValType(_aParRet[01]) == 'C'
		_aParRet[01] := Val( SubStr(_aParRet[01],1,1) )
	EndIf	
	
	If _aParRet[01] == 1
			
		//================================================================================
		// Instancia a Classe do Browse Principal
		//================================================================================
		_oBrowse := FWMBrowse():New()
		_oBrowse:SetAlias( 'ZC1' )
		_oBrowse:SetDescription( 'Comissão - Vendas Leite Magro' )
		_oBrowse:Activate()
	
	ElseIf _aParRet[01] == 2
		
		U_MOMS015()
		
	EndIf		

EndIf

Return

/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Alexandre Villar
Data da Criacao---: 13/08/2014
===============================================================================================================================
Descrição---------: Rotina de definição do menu da tela principal
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MenuDef()

Local _aRotina	:= {}

ADD OPTION _aRotina Title 'Visualizar'	Action 'VIEWDEF.MOMS005'	OPERATION 2 ACCESS 0 //Visualizar
ADD OPTION _aRotina Title 'Relatório'	Action 'U_ROMS037()'		OPERATION 2 ACCESS 0 //Visualizar
ADD OPTION _aRotina Title 'Calcular'	Action 'U_MOMS005C()'		OPERATION 3 ACCESS 0 //Incluir

Return( _aRotina )

/*
===============================================================================================================================
Programa----------: ModelDef
Autor-------------: Alexandre Villar
Data da Criacao---: 13/08/2014
===============================================================================================================================
Descrição---------: Define o modelo de dados para a rotina de cadastro
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ModelDef()

//-- Cria a estrutura a ser usada no Modelo de Dados --//
Local oStruZC1	:= FWFormStruct( 1 , 'ZC1' )
Local oModel	:= Nil

//-- Cria o objeto do Modelo de Dados --//
oModel := MPFormModel():New( 'MOMS005M' )

//-- Adiciona a descricao do Modelo de Dados --//
oModel:SetDescription( 'Modelo de Dados do cálculo de comissão adicional - Leite Magro' )

//-- Adiciona ao modelo uma estrutura de formulário de edição por campo --//
oModel:AddFields( 'ZC1MASTER' ,, oStruZC1 )

//-- Chave primaria do modelo --//
oModel:SetPrimaryKey( { 'ZC1_FILIAL' , 'ZC1_CODVEN' , 'ZC1_ANOMES' } )

Return( oModel )

/*
===============================================================================================================================
Programa----------: ViewDef
Autor-------------: Alexandre Villar
Data da Criacao---: 13/08/2014
===============================================================================================================================
Descrição---------: Define a View de dados para a rotina de cadastro
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ViewDef()

Local oModel   	:= FWLoadModel( 'MOMS005' )
Local oStruZC1	:= FWFormStruct( 2 , 'ZC1' )
Local oView		:= Nil

oView := FWFormView():New()

oView:SetModel( oModel )

oStruZC1:RemoveField( 'ZC1_FILIAL' )

oView:AddField( "VIEW_ZC1" , oStruZC1 , "ZC1MASTER" )

oView:CreateHorizontalBox( "TELA" , 100 )

oView:SetOwnerView( "VIEW_ZC1" , "TELA" )

Return( oView )

/*
===============================================================================================================================
Programa----------: MOMS005C
Autor-------------: Alexandre Villar
Data da Criacao---: 18/08/2014
===============================================================================================================================
Descrição---------: Pontos de entrada do MODELO em MVC
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS005C()

Local _aParam	:= {}
Local _aParRet	:= {}
Local _cDtRef	:= SubStr( DToS( MonthSub( dDataBase , 1 ) ) , 1 , 6 )
Local _cAnoMes	:= SubStr( _cDtRef , 5 , 2 ) +'/'+ SubStr( _cDtRef , 1 , 4 )

If !U_ITACSUSR( 'ZZL_ADMCMS' , 'S' )
	U_ITMsg( 'Usuário sem acesso ao processamento de cálculo de Comissões! Verifique com a área de TI/ERP' , 'Atenção!' , , 1 )
	Return
EndIf


If MOMS005VLF()

	U_ITMsg('Não é possível recalcular as comissões para um período que já foi fechado. '										+;
			'O período atual ['+ SubStr( _cDtRef , 5 , 2 ) +'/'+ SubStr( _cDtRef , 1 , 4 ) +'] não pode mais ser processado. '	+;
			'Em caso de dúvidas ou problemas procure a área de TI/ERP.'															,;
			'Atenção!'																											,;
			,1																											 )
	
	Return
	
EndIf


//================================================================================
// Monta a parametrização das perguntas iniciais
//================================================================================
aAdd( _aParam , { 1 , 'Mes/Ano: '		, _cAnoMes		, "@!" , '.T.' ,          , '.F.'	, 40 , .T. } )

_aParRet := { _aParam[01][03] }

//================================================================================
// Verifica se pode rodar rotina
//================================================================================
If .not. u_MOMS005VD(_aParRet[01])
	  
  Return
	  
EndIf

If ParamBox( _aParam , 'Confirmação do Processamento!' , @_aParRet ,,,,,,,, .F. , .F. )
	
	//================================================================================
	// Verifica se existe regra cadastrada para o período
	//================================================================================
	If MOMS005GPM( 0 , _cDtRef )
	
		Processa( {|| MOMS005EXE( _cDtRef ) } , 'Aguarde!' , 'Iniciando o processamento...' )
		
		//================================================================================
		//GRAVA LOG DE EXECUÇÃO
		//================================================================================
	
		RecLock("ZC8",.T.)
 
 		ZC8->ZC8_FILIAL     := xFilial("ZC8")   
		ZC8->ZC8_SEQ        := U_MOMS009C()  //Gera nova sequência do ZC8
		ZC8->ZC8_ROTINA     := "Adicionais de Comissao"
		ZC8->ZC8_DATA       := Date()
		ZC8->ZC8_HORA       := Time()
		ZC8->ZC8_USER       := cUserName
		ZC8->ZC8_CODUSU     := __cUserId
		ZC8->ZC8_OBS        := IIf(_aParRet[01] == 1,'1 - Leite Magro','2 - Bonificações')
		ZC8->ZC8_COMP       := _cAnoMes
 
		MSUnLock()
		
	
	Else
		
		U_ITMsg( 'Não existe meta cadastrada para a comissão adicional de Leite Magro para o período atual: '+ MV_PAR01 , 'Atenção!' ,,1 )
		
	EndIf

Else

	U_ITMsg(  'Operação cancelada pelo usuário!' , 'Atenção!' ,,1 )

EndIf

Return

/*
===============================================================================================================================
Programa----------: MOMS005EXE
Autor-------------: Alexandre Villar
Data da Criacao---: 18/08/2014
===============================================================================================================================
Descrição---------: Processamento do Cálculo das Comissões
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS005EXE( _cDtRef )

Local _aDados	:= {}
Local _aResTot	:= {}
Local _aHdrAux	:= {	'Cód. Vendedor'			,; //01
						'Nome Vendedor'			,; //02
						'Cód. Produto'			,; //03
						'Desc. Produto'			,; //04
						'Tipo de Leite'			,; //05
						'Qt. UM'				,; //06
						'UM'					,; //07
						'Qt. Seg. UM'			,; //08
						'Seg. UM'				,; //09
						'Valor Total'			,; //10
						'Preço Médio UM'		,; //11
						'Comissão'				,; //12
						'% Comissão'			,; //13
						'Devoluções UM'			,; //14
						'Devoluções Seg. UM'	,; //15
						'Valor Devoluções'		,; //16
						'Qtd. Líq. UM'			,; //17
						'Qtd. Líq. Seg. UM'		,; //18
						'Valor Líq.'			 } //19

Local _cAlias	:= GetNextAlias()
Local _cQuery	:= ''
Local _cDtIni	:= DToS( CtoD( '01/' + MV_PAR01  ) )
Local _cDtFim	:= SubStr( _cDtIni , 1 , 6 ) + '31'
Local _cCodVen	:= ''
Local _cPriUM   := ''
Local _cSegUM   := ''

Local _nI       := 0
Local _nTotReg	:= 0
Local _nQtdDev1 := 0
Local _nQtdDev2 := 0
Local _nValDev  := 0
Local _nQtdInt1 := 0
Local _nQtdInt2 := 0
Local _nValInt  := 0
Local _nComInt  := 0
Local _nQtdMgr1 := 0
Local _nQtdMgr2 := 0
Local _nValMgr  := 0
Local _nComMgr  := 0
Local _nConAux	:= 0

Local _nPerMin	:= MOMS005GPM( 1 , _cDtRef )

If Empty(_nPerMin) .Or. _nPerMin == 0

	U_ITMsg( 	'Não foi possível encontrar a % referente à Meta de Leite Magro para o período atual ou a mesma foi cadastrada com valor zerado (0.00). '+;
						'Verifique o cadastro de Metas e tente novamente!' ,'Atenção!' ,,1 )
	
	Return
	
EndIf

ProcRegua( 0 )
IncProc( 'Processando a consulta dos dados...' )

Begin Transaction

//================================================================================
// Verifica e apaga os registros anteriores
//================================================================================
LjMsgRun( 'Excluindo cálculos anteriores...' , 'Aguarde!' , {|| MOMS005DEL( _cDtIni , _cDtRef ) } , .T. )

//================================================================================
// Consulta os dados conforme os parâmetros para calcular as comissões
//================================================================================
_cQuery := " SELECT "
_cQuery += "    SF2.F2_VEND1        AS CODVEN   , "
_cQuery += "    SA3.A3_NOME			AS NOMVEN   , "
_cQuery += "    SB1.B1_COD          AS CODPRD   , "
_cQuery += "    SB1.B1_DESC         AS DESPRD   , "
_cQuery += "    SB1.B1_I_TIPLT      AS TIPLT    , "
_cQuery += "    SUM(SD2.D2_QUANT)   AS QTDPUM   , "
_cQuery += "    SD2.D2_UM           AS PRIUM    , "
_cQuery += "    SUM(SD2.D2_QTSEGUM) AS QTDSUM   , "
_cQuery += "    SD2.D2_SEGUM        AS SEGUM    , "
_cQuery += "    SUM(SD2.D2_TOTAL)   AS VALTOT   , "
_cQuery += "    Round( SUM(SD2.D2_TOTAL) / SUM(SD2.D2_QUANT) , 2 )            AS PRCVEN , "
_cQuery += "    Round( ( AVG(SD2.D2_COMIS1) / 100 ) * SUM(SD2.D2_TOTAL) , 2 ) AS COMVEN1  "
_cQuery += " FROM "+ RetSqlName('SF2') +" SF2 "
_cQuery += " JOIN "+ RetSqlName('SD2') +" SD2 ON SD2.D2_DOC		= SF2.F2_DOC	AND SD2.D2_SERIE	= SF2.F2_SERIE AND SD2.D2_FILIAL = SF2.F2_FILIAL "
_cQuery += " JOIN "+ RetSqlName('SA1') +" SA1 ON SD2.D2_CLIENTE	= SA1.A1_COD	AND SD2.D2_LOJA		= SA1.A1_LOJA "
_cQuery += " JOIN "+ RetSqlName('SB1') +" SB1 ON SD2.D2_COD		= SB1.B1_COD "
_cQuery += " JOIN "+ RetSqlName('SBM') +" SBM ON SB1.B1_GRUPO	= SBM.BM_GRUPO "
_cQuery += " JOIN "+ RetSqlName('SA3') +" SA3 ON SF2.F2_VEND1	= SA3.A3_COD "
_cQuery += " JOIN "+ RetSqlName('SF4') +" SF4 ON SD2.D2_FILIAL	= SF4.F4_FILIAL	AND SD2.D2_TES		= SF4.F4_CODIGO "
_cQuery += " JOIN "+ RetSqlName('ZAY') +" ZAY ON ZAY.ZAY_CF     = SD2.D2_CF "
_cQuery += " WHERE "
_cQuery += "     SF2.D_E_L_E_T_ = ' ' "
_cQuery += " AND SD2.D_E_L_E_T_ = ' ' "
_cQuery += " AND SA1.D_E_L_E_T_ = ' ' "
_cQuery += " AND SB1.D_E_L_E_T_ = ' ' "
_cQuery += " AND SBM.D_E_L_E_T_ = ' ' "
_cQuery += " AND SA3.D_E_L_E_T_ = ' ' "
_cQuery += " AND SF4.D_E_L_E_T_ = ' ' "
_cQuery += " AND ZAY.D_E_L_E_T_ = ' ' "

_cQuery += " AND SF2.F2_EMISSAO BETWEEN '"+ _cDtIni +"' AND '"+ _cDtFim +"' "	//Filtra data de Emissão de acordo com o Mês de Referência
_cQuery += " AND SB1.B1_I_TIPLT <> ' ' "										//Somente os produtos classificados como Leite Integral ou Magro
_cQuery += " AND SD2.D2_COMIS1	> 0 "											//Somente os produtos que tenham gerado comissão para o Vendedor
_cQuery += " AND ZAY.ZAY_TPOPER	= 'V' "

_cQuery += " GROUP BY SF2.F2_VEND1 , SA3.A3_NOME , SB1.B1_COD , SB1.B1_DESC , SB1.B1_I_TIPLT , SD2.D2_UM , SD2.D2_SEGUM "
_cQuery += " ORDER BY 1 , 5 , 3 "

IncProc( 'Processando o cálculo das comissões...' )

DBUseArea( .T. , "TOPCONN" , TcGenQry( ,, _cQuery ) , _cAlias , .T. , .F. )

DBSelectArea(_cAlias)
(_cAlias)->( DBGoTop() )
(_cAlias)->( DBEval( {|| _nTotReg++ } ) )
(_cAlias)->( DBGoTop() )

If _nTotReg > 0
	
	ProcRegua( _nTotReg )
	
	While (_cAlias)->( !Eof() )
		
		_nConAux++
		IncProc( 'Processando... ['+ StrZero(_nConAux,9) +'] de ['+ StrZero(_nTotReg,9) +'].' )
		
		//================================================================================
		// Verifica e Inclui Linhas de Totalizador
		//================================================================================
		If !Empty( _cCodVen ) .And. _cCodVen <> (_cAlias)->CODVEN
			
			//================================================================================
			// Chama rotina que inclui dados de Totalizadores e Gera os Registros de Comissão
			//================================================================================
			MOMS005TOT( @_aDados , _cDtRef , _nPerMin , _cCodVen , _nQtdInt1 , _nQtdInt2 , _nValInt , _nComInt , _nQtdMgr1 , _nQtdMgr2 , _nValMgr , _nComMgr , _cPriUM , _cSegUM )
			
			_nQtdInt1 := _nQtdInt2 := _nValInt := _nComInt := 0
			_nQtdMgr1 := _nQtdMgr2 := _nValMgr := _nComInt := 0
			
			For _nI := 1 To Len(_aDados)
				aAdd( _aResTot , _aDados[_nI] )
			Next _nI
			
			_aDados := {}
			
		EndIf
		
		//================================================================================
		// Inicializa as variáveis e verifica se deve abater devoluções
		//================================================================================
	    _nQtdDev1 := 0
	    _nQtdDev2 := 0
	    _nValDev  := 0
	    _cCodVen  := (_cAlias)->CODVEN
		
		MOMS005DEV( (_cAlias)->CODVEN , (_cAlias)->CODPRD , _cDtIni , _cDtFim , @_nQtdDev1 , @_nQtdDev2 , @_nValDev )
		
		//================================================================================
		// Grava os dados para exibição e monta a base de cálculo
		//================================================================================
		aAdd( _aDados , {	(_cAlias)->CODVEN																			,; //01 - Cód. Vendedor
							(_cAlias)->NOMVEN																			,; //02 - Nome Vendedor
							(_cAlias)->CODPRD																			,; //03 - Cód. Produto
							(_cAlias)->DESPRD									 										,; //04 - Desc. Produto
							IIf( (_cAlias)->TIPLT == 'I' , 'Integral' , 'Magro' )										,; //05 - Tipo de Leite
							Transform( Round( (_cAlias)->QTDPUM , 0 )				, '@E 999,999,999' )				,; //06 - Qtd. Primeira UM
							(_cAlias)->PRIUM																			,; //07 - Primeira UM
							Transform( Round( (_cAlias)->QTDSUM , 0 )				, '@E 999,999,999' )				,; //08 - Qtd. Segunda UM
							(_cAlias)->SEGUM																   			,; //09 - Segunda UM
							Transform( (_cAlias)->VALTOT							, '@E 999,999,999.99' )				,; //10 - Valor Total
							Transform( (_cAlias)->PRCVEN							, '@E 999,999.99' )	   				,; //11 - Preço Médio UM
							Transform( (_cAlias)->COMVEN1							, '@E 999,999,999.99' )				,; //12 - Comissão
							Transform( Round( ( (_cAlias)->COMVEN1 / (_cAlias)->VALTOT ) * 100 , 2 ) , '@E 9,999.99' )	,; //13 - % Comissão
							Transform( Round( _nQtdDev1 , 0 )						, '@E 999,999,999' )				,; //14 - Dev. Primeira UM
							Transform( Round( _nQtdDev2 , 0 )						, '@E 999,999,999' )				,; //15 - Dev. Primeira UM
							Transform( _nValDev										, '@E 999,999,999.99' )				,; //16 - Valor Total da Devolução
							Transform( Round( (_cAlias)->QTDPUM - _nQtdDev1 , 0 )	, '@E 999,999,999' )				,; //17 - Qtd. Líq. UM
							Transform( Round( (_cAlias)->QTDSUM - _nQtdDev2 , 0 )	, '@E 999,999,999' )				,; //18 - Qtd. Líq. Seg. UM
							Transform( (_cAlias)->VALTOT - _nValDev					, '@E 999,999,999.99' )				}) //19 - Valor Líq.
		
		If (_cAlias)->TIPLT == 'I'
			_nQtdInt1 += Round( (_cAlias)->QTDPUM - _nQtdDev1 , 0 )
			_nQtdInt2 += Round( (_cAlias)->QTDSUM - _nQtdDev2 , 0 )
			_nValInt  += (_cAlias)->VALTOT - _nValDev
			_nComInt  += (_cAlias)->COMVEN1
		Else
			_nQtdMgr1 += Round( (_cAlias)->QTDPUM - _nQtdDev1 , 0 )
			_nQtdMgr2 += Round( (_cAlias)->QTDSUM - _nQtdDev2 , 0 )
			_nValMgr  += (_cAlias)->VALTOT - _nValDev
			_nComMgr  += (_cAlias)->COMVEN1
		EndIf
		
		_cPriUM := (_cAlias)->PRIUM
		_cSegUM := (_cAlias)->SEGUM
		
	(_cAlias)->( DBSkip() )
	EndDo
	
	//================================================================================
	// Chama rotina que inclui dados de Totalizadores e Gera os Registros de Comissão
	//================================================================================
	MOMS005TOT( @_aDados , _cDtRef , _nPerMin , _cCodVen , _nQtdInt1 , _nQtdInt2 , _nValInt , _nComInt , _nQtdMgr1 , _nQtdMgr2 , _nValMgr , _nComMgr , _cPriUM , _cSegUM )
	
	For _nI := 1 To Len(_aDados)
		aAdd( _aResTot , _aDados[_nI] )
	Next _nI
	
EndIf

(_cAlias)->( DBCloseArea() )

End Transaction

//Montar saída como relatório para conferência do usuário
U_ITListBox( 'Cálculo de Comissão' , _aHdrAux , _aResTot , .T. , 1 , 'Validação da Rotina (Desenvolvimento)' )

Return

/*
===============================================================================================================================
Programa----------: MOMS005GPM
Autor-------------: Alexandre Villar
Data da Criacao---: 18/08/2014
===============================================================================================================================
Descrição---------: Processamento do Cálculo das Comissões
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS005GPM( _nOpc , _cDtRef )

Local _xRet   := NIL
Local _cAlias := GetNextAlias()
Local _cQuery := ''

If _nOpc == 1
	_xRet := 0
Else
	_xRet := .F.
EndIf

_cQuery := " SELECT ZC0.ZC0_META "
_cQuery += " FROM "+ RetSqlName('ZC0') +" ZC0 "
_cQuery += " WHERE "
_cQuery += "     ZC0.D_E_L_E_T_ = ' ' "
_cQuery += " AND ZC0.ZC0_ANOMES = '"+ _cDtRef +"' "

If Select(_cAlias) > 0
	(_cAlias)->( DBCloseArea() )
EndIf

DBUseArea( .T. , "TOPCONN" , TcGenQry( ,, _cQuery ) , _cAlias , .T. , .F. )

DBSelectArea(_cAlias)
(_cAlias)->( DBGoTop() )
If (_cAlias)->( !Eof() )
	
	If _nOpc == 1
		_xRet := (_cAlias)->ZC0_META
	Else
		_xRet := .T.
	EndIf
	
EndIf

(_cAlias)->( DBCloseArea() )

Return( _xRet )

/*
===============================================================================================================================
Programa----------: MOMS005TOT
Autor-------------: Alexandre Villar
Data da Criacao---: 19/08/2014
===============================================================================================================================
Descrição---------: Finaliza totalizadores
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS005TOT( _aDados , _cDtRef , _nPerMin , _cCodVen , _nQtdInt1 , _nQtdInt2 , _nValInt , _nComInt , _nQtdMgr1 , _nQtdMgr2 , _nValMgr , _nComMgr , _cPriUM , _cSegUM )

Local _aDadZC2    := {}
Local _nI		:= 0
Local _nPerCAD    := GetMV( 'IT_CMSPRAD' ,, 0.75 )
Local _nPerMgr    := 0
Local _nValAdc    := 0

Default _cCodVen  := ''
Default _nPerMin  := 0
Default _nQtdInt1 := 0
Default _nQtdInt2 := 0
Default _nValInt  := 0
Default _nComInt  := 0
Default _nQtdMgr1 := 0
Default _nQtdMgr2 := 0
Default _nValMgr  := 0
Default _nComInt  := 0
Default _cPriUM   := ''
Default _cSegUM   := ''

For _nI := 1 To Len( _aDados )
	
	aAdd( _aDadZC2 , {	_cCodVen + _cDtRef	,; //ZC2_CHAVE
						StrZero( _nI , 3 )	,; //ZC2_ITEM
						_aDados[_nI][05]	,; //ZC2_TIPLT
						_aDados[_nI][03]	,; //ZC2_CODPRD
						_aDados[_nI][06]	,; //ZC2_QTDTUM
						_aDados[_nI][08]	,; //ZC2_QTDTSU
						_aDados[_nI][10]	,; //ZC2_VALTOT
						_aDados[_nI][13]	,; //ZC2_PERCOM
						_aDados[_nI][12]	,; //ZC2_VALCOM
						_aDados[_nI][14]	,; //ZC2_DEVTUM
						_aDados[_nI][15]	,; //ZC2_DEVTSU
						_aDados[_nI][16]	,; //ZC2_VALDEV
						_aDados[_nI][17]	,; //ZC2_QTDLUM
						_aDados[_nI][18]	,; //ZC2_QTDLSU
						_aDados[_nI][19]	,; //ZC2_VALLIQ
						'1'					}) //ZC2_STATUS
	
Next _nI

aAdd( _aDados , {	_cCodVen																,; // 01 - Cód. Vendedor
					Posicione('SA3',1,xFilial('SA3')+_cCodVen,'A3_NOME')					,; // 02 - Nome Vendedor
					'---'																	,; // 03 - Cód. Produto
					'Total Leite Integral'													,; // 04 - Desc. Produto
					'Integral'																,; // 05 - Tipo de Leite
					Transform( _nQtdInt1	, '@E 999,999,999' )							,; // 06 - Qtd. Primeira UM
					_cPriUM																	,; // 07 - Primeira UM
					Transform( _nQtdInt2	, '@E 999,999,999' )							,; // 08 - Qtd. Segunda UM
					_cSegUM								   									,; // 09 - Segunda UM
					Transform( _nValInt		, '@E 999,999,999.99' )							,; // 10 - Valor Total
					'---'																	,; // 11 - Preço Médio UM
					Transform( _nComInt		, '@E 999,999,999.99' )							,; // 12 - Comissão
					Transform( Round( ( _nComInt / _nValInt ) * 100 , 2 ) , '@E 9,999.99' )	,; // 13 - % Comissão
					'---'																	,; // 14 - Dev. Primeira UM
					'---'																	,; // 15 - Dev. Segunda UM
					'---'																	,; // 16 - Valor Total da Devolução
					'---'																	,; // 17 - Qtd. Líq. UM
					'---'																	,; // 18 - Qtd. Líq. Seg. UM
					'---'																	}) // 19 - Valor Líq.

aAdd( _aDados , {	_cCodVen																,; //Cód. Vendedor
					Posicione('SA3',1,xFilial('SA3')+_cCodVen,'A3_NOME')					,; //Nome Vendedor
					'---'																	,; //Cód. Produto
					'Total Leite Magro'							   							,; //Desc. Produto
					'Magro'										   							,; //Tipo de Leite
					Transform( _nQtdMgr1	, '@E 999,999,999' )   							,; //Qtd. Primeira UM
					_cPriUM										   							,; //Primeira UM
					Transform( _nQtdMgr2	, '@E 999,999,999' )   							,; //Qtd. Segunda UM
					_cSegUM								   		   							,; //Segunda UM
					Transform( _nValMgr		, '@E 999,999,999.99' )							,; //Valor Total
					'---'	  																,; //Preço Médio UM
					Transform( _nComMgr		, '@E 999,999,999.99' )							,; //Comissão
					Transform( Round( ( _nComMgr / _nValMgr ) * 100 , 2 ) , '@E 9,999.99' )	,; //% Comissão
					'---'																	,; //Dev. Primeira UM
					'---'																	,; //Dev. Primeira UM
					'---'																	,; //Valor Total da Devolução
					'---'																	,; //Qtd. Líq. UM
					'---'																	,; //Qtd. Líq. Seg. UM
					'---'																	}) //Valor Líq.

aAdd( _aDados , {	_cCodVen																								,; //Cód. Vendedor
					Posicione('SA3',1,xFilial('SA3')+_cCodVen,'A3_NOME')													,; //Nome Vendedor
					'---'																									,; //Cód. Produto
					'Total do Vendedor'																						,; //Desc. Produto
					'Ambos'																									,; //Tipo de Leite
					Transform( _nQtdInt1 + _nQtdMgr1	, '@E 999,999,999' )												,; //Qtd. Primeira UM
					_cPriUM	   										 	 													,; //Primeira UM
					Transform( _nQtdInt2 + _nQtdMgr2	, '@E 999,999,999' )												,; //Qtd. Segunda UM
					_cSegUM		 																			   		 		,; //Segunda UM
					Transform( _nValInt + _nValMgr		, '@E 999,999,999.99' )												,; //Valor Total
					'---'										 															,; //Preço Médio UM
					Transform( _nComInt + _nComMgr		, '@E 999,999,999.99' )												,; //Comissão
					Transform( Round( ( ( _nComInt + _nComMgr ) / ( _nValInt + _nValMgr ) ) * 100 , 2 ) , '@E 9,999.99' )	,; //% Comissão
					'---'																									,; //Dev. Primeira UM
					'---'																									,; //Dev. Primeira UM
					'---'																									,; //Valor Total da Devolução
					'---'																									,; //Qtd. Líq. UM
					'---'																									,; //Qtd. Líq. Seg. UM
					'---'																									}) //Valor Líq.

//================================================================================
// Verifica o Valor do Percentual de Leite Magro
//================================================================================
_nPerMgr := NoRound( Round( ( _nQtdMgr1 / ( _nQtdInt1 + _nQtdMgr1 ) ) * 100 , 2 ) , 2 )

If _nPerMgr < 0 .Or. _nQtdInt1 == 0
	_nPerMgr := 0
EndIf

If _nPerMgr > _nPerMin
	_nValAdc := _nValMgr * ( _nPerCAD / 100 )
EndIf

aAdd( _aDados , {	_cCodVen													,; //Cód. Vendedor
					Posicione('SA3',1,xFilial('SA3')+_cCodVen,'A3_NOME')		,; //Nome Vendedor
					'---'														,; //Cód. Produto
					'Comissão Adicional'										,; //Desc. Produto
					'% Magro ->'												,; //Tipo de Leite
					Transform( _nPerMgr , '@E 999,999,999.99' )					,; //Qtd. Primeira UM
					'---'	   										 			,; //Primeira UM
					'---'														,; //Qtd. Segunda UM
					'---'		 								   		 		,; //Segunda UM
					'---'														,; //Valor Total
					'---'														,; //Preço Médio UM
					Transform( _nValAdc , '@E 999,999,999.99' )					,; //Comissão
					Transform( _nPerCAD , '@E 999,999,999.99' )                 ,; //% Comissão
					'---'														,; //Dev. Primeira UM
					'---'														,; //Dev. Primeira UM
					'---'														,; //Valor Total da Devolução
					'---'														,; //Qtd. Líq. UM
					'---'														,; //Qtd. Líq. Seg. UM
					'---'														}) //Valor Líq.

//================================================================================
// Guarda os dados do cálculo e gera SE3 apenas para as Comissões Adicionais
//================================================================================
DBSelectArea('ZC1')
ZC1->( DBSetOrder(1) )
If ZC1->( DBSeek( xFilial('ZC1') + _cCodVen + _cDtRef ) )

	ZC1->( RecLock( 'ZC1' , .F. ) )
	
Else

	ZC1->( RecLock( 'ZC1' , .T. ) )
	
	ZC1->ZC1_FILIAL := xFilial('ZC1')
	ZC1->ZC1_CODVEN := _cCodVen
	ZC1->ZC1_ANOMES := _cDtRef
	
EndIf

ZC1->ZC1_VALTOT := _nValInt + _nValMgr
ZC1->ZC1_VALLMG := _nValMgr
ZC1->ZC1_PERLMG := _nPerMgr
ZC1->ZC1_VALCAD := _nValAdc
ZC1->ZC1_PERMIN := _nPerMin
ZC1->ZC1_STATUS := '1'

ZC1->( MSUnLock() )

For _nI := 1 To Len( _aDadZC2 )
	
	ZC2->( RecLock( 'ZC2' , .T. ) )

	ZC2->ZC2_FILIAL := xFilial('ZC2')
	ZC2->ZC2_CHAVE  := ZC1->( ZC1_CODVEN + ZC1_ANOMES )
	ZC2->ZC2_ITEM   := _aDadZC2[_nI][02]
	ZC2->ZC2_TIPLT  := _aDadZC2[_nI][03]
	ZC2->ZC2_CODPRD := _aDadZC2[_nI][04]
	ZC2->ZC2_QTDTUM := Val( StrTran( StrTran( _aDadZC2[_nI][05] , '.' , '' ) , ',' , '.' ) )
	ZC2->ZC2_QTDTSU := Val( StrTran( StrTran( _aDadZC2[_nI][06] , '.' , '' ) , ',' , '.' ) )
	ZC2->ZC2_VALTOT := Val( StrTran( StrTran( _aDadZC2[_nI][07] , '.' , '' ) , ',' , '.' ) )
	ZC2->ZC2_PERCOM := Val( StrTran( StrTran( _aDadZC2[_nI][08] , '.' , '' ) , ',' , '.' ) )
	ZC2->ZC2_VALCOM := Val( StrTran( StrTran( _aDadZC2[_nI][09] , '.' , '' ) , ',' , '.' ) )
	ZC2->ZC2_DEVTUM := Val( StrTran( StrTran( _aDadZC2[_nI][10] , '.' , '' ) , ',' , '.' ) )
	ZC2->ZC2_DEVTSU := Val( StrTran( StrTran( _aDadZC2[_nI][11] , '.' , '' ) , ',' , '.' ) )
	ZC2->ZC2_VALDEV := Val( StrTran( StrTran( _aDadZC2[_nI][12] , '.' , '' ) , ',' , '.' ) )
	ZC2->ZC2_QTDLUM := Val( StrTran( StrTran( _aDadZC2[_nI][13] , '.' , '' ) , ',' , '.' ) )
	ZC2->ZC2_QTDLSU := Val( StrTran( StrTran( _aDadZC2[_nI][14] , '.' , '' ) , ',' , '.' ) )
	ZC2->ZC2_VALLIQ := Val( StrTran( StrTran( _aDadZC2[_nI][15] , '.' , '' ) , ',' , '.' ) )
	ZC2->ZC2_STATUS := _aDadZC2[_nI][16]
	
	ZC2->( MSUnLock() )
	
Next _nI
	
If _nValAdc > 0
	
	SE3->( RecLock( 'SE3' , .T. ) )
	
	SE3->E3_FILIAL 	:= '01'
	SE3->E3_VEND   	:= _cCodVen
	SE3->E3_EMISSAO := LastDay( SToD( _cDtRef + '01' ) )
	SE3->E3_DATA    := LastDay( SToD( _cDtRef + '01' ) )
	SE3->E3_BASE    := _nValMgr
	SE3->E3_PORC    := _nPerCAD
	SE3->E3_COMIS   := _nValAdc
	SE3->E3_I_ORIGE := 'MOMS005'
	
	SE3->( MSUnLock() )
	
EndIf

Return

/*
===============================================================================================================================
Programa----------: MOMS005DEV
Autor-------------: Alexandre Villar
Data da Criacao---: 19/08/2014
===============================================================================================================================
Descrição---------: Totaliza devoluções
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS005DEV( _cCodVen , _cCodPrd , _cDtIni , _cDtFim , _nQtdDev1 , _nQtdDev2 , _nValDev )

Local _cQuery := ''
Local _cAlias := GetNextAlias()

_cQuery := " SELECT "
_cQuery += "     SD1.D1_COD						, "
_cQuery += "     SUM( SD1.D1_QUANT ) AS QTDPUM	, "
_cQuery += "     SD1.D1_UM						, "
_cQuery += "     SUM( SD1.D1_QTSEGUM ) AS QTDSUM, "
_cQuery += "     SD1.D1_SEGUM					, "
_cQuery += "     SUM( SD1.D1_TOTAL ) AS VALTOT	  "
_cQuery += " FROM "+ RetSqlName('SF1') +" SF1 "
_cQuery += " INNER JOIN "+ RetSqlName('SD1') +" SD1 "
_cQuery += " ON "
_cQuery += "     SD1.D1_FILIAL      = SF1.F1_FILIAL "
_cQuery += " AND SD1.D1_DOC         = SF1.F1_DOC "
_cQuery += " AND SD1.D1_SERIE       = SF1.F1_SERIE "
_cQuery += " INNER JOIN "+ RetSqlName('SF2') +" SF2 "
_cQuery += " ON "
_cQuery += "     SF2.F2_FILIAL		= SD1.D1_FILIAL "
_cQuery += " AND SF2.F2_DOC			= SD1.D1_NFORI "
_cQuery += " AND SF2.F2_SERIE		= SD1.D1_SERIORI "
_cQuery += " AND SF2.F2_CLIENTE     = SF1.F1_FORNECE "
_cQuery += " AND SF2.F2_LOJA        = SF1.F1_LOJA "
_cQuery += " WHERE "
_cQuery += "     SF1.D_E_L_E_T_     = ' ' "
_cQuery += " AND SD1.D_E_L_E_T_     = ' ' "
_cQuery += " AND SF2.D_E_L_E_T_     = ' ' "
_cQuery += " AND SF2.F2_EMISSAO     BETWEEN '"+ _cDtIni	+"' AND '"+ _cDtFim +"' "
_cQuery += " AND SD1.D1_DTDIGIT		>= '"+ _cDtIni +"' "
_cQuery += " AND SF2.F2_VEND1       = '"+ _cCodVen +"' "
_cQuery += " AND SD1.D1_COD         = '"+ _cCodPrd +"' "
_cQuery += " GROUP BY SD1.D1_COD , SD1.D1_UM , SD1.D1_SEGUM "

If Select(_cAlias) > 0
	(_cAlias)->( DBCloseArea() )
EndIf

DBUseArea( .T. , "TOPCONN" , TcGenQry( ,, _cQuery ) , _cAlias , .T. , .F. )

DBSelectArea(_cAlias)
(_cAlias)->( DBGoTop() )
If (_cAlias)->( !Eof() )

    _nQtdDev1 := (_cAlias)->QTDPUM
    _nQtdDev2 := (_cAlias)->QTDSUM
    _nValDev  := (_cAlias)->VALTOT

Else

    _nQtdDev1 := 0
    _nQtdDev2 := 0
    _nValDev  := 0
	
EndIf

(_cAlias)->( DBCloseArea() )

Return

/*
===============================================================================================================================
Programa----------: MOMS005VE3
Autor-------------: Alexandre Villar
Data da Criacao---: 19/08/2014
===============================================================================================================================
Descrição---------: Carrega SE3
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS005VE3( _cCodVen , _cDtRef )

Local _aRet   := {}
Local _cQuery := ''
Local _cAlias := GetNextAlias()

_cQuery := " SELECT "
_cQuery += "     SE3.R_E_C_N_O_ "
_cQuery += " FROM "+ RetSqlName('SE3') +" SE3 "
_cQuery += " WHERE "
_cQuery += "     SE3.D_E_L_E_T_ = ' ' "
_cQuery += " AND SE3.E3_FILIAL  = '01' "
_cQuery += " AND SE3.E3_VEND    = '"+ _cCodVen +"' "
_cQuery += " AND SE3.E3_EMISSAO LIKE '"+ _cDtRef +"%' "
_cQuery += " AND SE3.E3_I_ORIGE = 'MOMS005' "

If Select(_cAlias) > 0
	(_cAlias)->( DBCloseArea() )
EndIf

DBUseArea( .T. , "TOPCONN" , TcGenQry( ,, _cQuery ) , _cAlias , .T. , .F. )

DBSelectArea(_cAlias)
(_cAlias)->( DBGoTop() )
While (_cAlias)->( !Eof() )

	aAdd( _aRet , (_cAlias)->R_E_C_N_O_ )
	
(_cAlias)->( DBSkip() )
EndDo

(_cAlias)->( DBCloseArea() )

Return( _aRet )

/*
===============================================================================================================================
Programa----------: MOMS005VLF
Autor-------------: Alexandre Villar
Data da Criacao---: 19/08/2014
===============================================================================================================================
Descrição---------: Conta SE3
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS005VLF()

Local _lRet		:= .F.
Local _cQuery	:= ''
Local _cAlias	:= GetNextAlias()

_cQuery := " SELECT COUNT(*) AS CONTADOR "
_cQuery += " FROM "+ RetSqlName('SE3') +" SE3 "
_cQuery += " WHERE "
_cQuery += "     D_E_L_E_T_ = ' ' "
_cQuery += " AND E3_EMISSAO BETWEEN '"+ SubStr( DToS( MonthSub( dDatabase , 1 ) ) , 1 , 6 ) +"01' AND '"+ SubStr( DToS( MonthSub( dDatabase , 1 ) ) , 1 , 6 ) +"31' "
_cQuery += " AND E3_I_FECH  = 'S' "

If Select(_cAlias) > 0
	(_cAlias)->( DBCloseArea() )
EndIf

DBUseArea( .T. , "TOPCONN" , TcGenQry( ,, _cQuery ) , _cAlias , .T. , .F. )

DBSelectArea(_cAlias)
(_cAlias)->( DBGoTop() )
If (_cAlias)->( !Eof() )
	_lRet := ( (_cAlias)->CONTADOR > 0 )
EndIf

(_cAlias)->( DBCloseArea() )

Return( _lRet )

/*
===============================================================================================================================
Programa----------: MOMS005DEL
Autor-------------: Alexandre Villar
Data da Criacao---: 19/08/2014
===============================================================================================================================
Descrição---------: Exclui SE3
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS005DEL( _cDtIni , _cDtRef )

Local _cAlias1	:= GetNextAlias()
Local _cQuery	:= ''
Local _aRegSE3	:= {}
Local _nI		:= 0

//================================================================================
// Processa a exclusão de todos os registros do período
//================================================================================
_cQuery := " SELECT ZC1.R_E_C_N_O_ AS REGZC1 FROM "+ RetSqlName('ZC1') +" ZC1 WHERE ZC1.D_E_L_E_T_ = ' ' AND ZC1.ZC1_ANOMES = '"+ SubStr( _cDtIni , 1 , 6 ) +"' ORDER BY 1 "

If Select(_cAlias1) > 0
	(_cAlias1)->( DBCloseArea() )
EndIf

DBUseArea( .T. , "TOPCONN" , TcGenQry( ,, _cQuery ) , _cAlias1 , .T. , .F. )

DBSelectArea(_cAlias1)
(_cAlias1)->( DBGoTop() )
While (_cAlias1)->( !Eof() )
	
	DBSelectArea('ZC1')
	ZC1->( DBGoTo( (_cAlias1)->REGZC1 ) )
	
	//================================================================================
	// Apaga os registros de Comissão se existirem para gerar novamente
	//================================================================================
	_aRegSE3 := MOMS005VE3( ZC1->ZC1_CODVEN , _cDtRef )
	
	DBSelectArea('SE3')
	If !Empty( _aRegSE3 )
		
		For _nI := 1 To Len( _aRegSE3 )
		
			SE3->( DBGoTo( _aRegSE3[_nI] ) )
			SE3->( RecLock( 'SE3' , .F. ) )
			SE3->( DBDelete() )
			SE3->( MSUnLock() )
		
		Next _nI
		
	EndIf
	
	//================================================================================
	// Apaga os registros de Histórico se existirem para gerar novamente
	//================================================================================
	DBSelectArea('ZC2')
	ZC2->( DBSetOrder(1) )
	If ZC2->( DBSeek( xFilial('ZC2') + ZC1->( ZC1_CODVEN + ZC1_ANOMES ) ) )
		
		While ZC2->(!Eof()) .And. ZC2->( ZC2_FILIAL + ZC2_CHAVE ) == xFilial('ZC2') + ZC1->( ZC1_CODVEN + ZC1_ANOMES )
			
			ZC2->( RecLock( 'ZC2' , .F. ) )
			ZC2->( DBDelete() )
			ZC2->( MSUnLock() )
			
		ZC2->( DBSkip() )
		EndDo
		
	EndIf
	
	ZC1->( RecLock( 'ZC1' , .F. ) )
	ZC1->( DBDelete() )
	ZC1->( MSUnLock() )

(_cAlias1)->( DBSkip() )
EndDo

(_cAlias1)->( DBCloseArea() )
	
Return

/*
===============================================================================================================================
Programa----------: MOMS005VD
Autor-------------: Josué Danich 
Data da Criacao---: 09/12/2015
===============================================================================================================================
Descrição---------: Valida execução do adicionais de comissão
===============================================================================================================================
Parametros--------: _ntipo - 	1 Leite Magro
									2 Bonificações
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS005VD(_ntipo)

Local _aalertas  := {}
Local _cDataF    := GetMv("IT_COMFECH")  // Data do fechamento
Local _nmes      := month(SToD(SubStr(_cDataf,4,4)+SubStr(_cDataf,1,2)+'01'))
Local _nano      := year(SToD(SubStr(_cDataf,4,4)+SubStr(_cDataf,1,2)+'01'))
Local _cAlias	   := GetNextAlias()
Local _cseq      := ""
Local _nI		:= 0
Default _ntipo   := 2

//================================================================================
//verifica parametro de fechamento de comissao
//================================================================================

_aalertas := U_MOMS009VS()

//================================================================================
//Verifica se usuário pode rodar a rotina
//================================================================================

DBSelectArea('ZZL')
ZZL->( DBSetOrder(3) )

If !(ZZL->( DBSeek( xFilial('ZZL') + RetCodUsr() ) ) .And. ZZL->ZZL_ADMCMS == 'S')

    aAdd(_aalertas,"Usuário " + AllTrim(SubStr(cUsuario,7,15)) + " sem permissão para cálculo de comissões!") 
 
End If


_cDataf := StrZero(_nano,4)+StrZero(_nmes,2)+"01"

//================================================================================
//verifica se não está fazendo fechamento o mês atual ou futuro
//================================================================================

If AllTrim(Str(_nano))+AllTrim(StrZero(_nmes,2)) >= AllTrim(Str(year(date())))+AllTrim(StrZero(month(date()),2))

  aAdd(_aalertas,"Mês " + StrZero(_nmes,2) + "/" + StrZero(_nano,4) + " não terminou ainda!") 
  
EndIf

//================================================================================
//verifica se já foi liberado pelo financeiro
//================================================================================

_cQuery := " SELECT ZC8_SEQ FROM "+ RETSQLNAME('ZC8') +" ZC8 WHERE ZC8_ROTINA = 'Fechamento Financeiro' "
_cQuery += " and ZC8_COMP = '" + StrZero(_nmes,2) + "/" + StrZero(_nano,4) + "' and  D_E_L_E_T_ <> '*'"

DBUseArea( .T. , "TOPCONN" , TCGenQry( ,, _cQuery ) , _cAlias , .F. , .T. )
DBSelectArea(_cAlias)

If (_cAlias)->( Eof() )

  aAdd(_aalertas,"Não existe um fechamento financeiro para o período de comissões em aberto!(" + StrZero(_nmes,2) + "/" + StrZero(_nano,4) + ")")
  (_cAlias)->( DBCloseArea() )  
  
Else

	_cseq := AllTrim((_cAlias)->ZC8_SEQ)
	(_cAlias)->( DBCloseArea() )

	//================================================================================
	//verifica se já rodou recálculo de comissão após a liberação do financeiro
	//================================================================================

	_cAlias	:= GetNextAlias()

	_cQuery := " SELECT ZC8_SEQ FROM "+ RETSQLNAME('ZC8') +" ZC8 WHERE ZC8_ROTINA LIKE 'Recalculo de Comissao%' "
	_cQuery += " and ZC8_COMP = '" + StrZero(_nmes,2) + "/" + StrZero(_nano,4) + "' and  D_E_L_E_T_ <> '*'"

	DBUseArea( .T. , "TOPCONN" , TCGenQry( ,, _cQuery ) , _cAlias , .F. , .T. )
	DBSelectArea(_cAlias)

	If (_cAlias)->( Eof() )

  		aAdd(_aalertas,"Não existe um recálculo de comissão após a liberação do financeiro para o período de comissões em aberto!(" + StrZero(_nmes,2) + "/" + StrZero(_nano,4) + ")")
  		(_cAlias)->( DBCloseArea() )
  
	Else
	
		//================================================================================
		//verifica se já não tem cálculo de adicionais para o período
		//================================================================================
		
		(_cAlias)->( DBCloseArea() )
		
		_cAlias	:= GetNextAlias()

		_cQuery := " SELECT ZC8_SEQ FROM "+ RETSQLNAME('ZC8') +" ZC8 WHERE ZC8_ROTINA = 'Adicionais de Comissao' "
		_cQuery += " and ZC8_COMP = '" + StrZero(_nmes,2) + "/" + StrZero(_nano,4) + "' and ZC8_SEQ > '" + _cseq + "' and ZC8_OBS = '" 
		_cQuery += "2 - Bonificações' and D_E_L_E_T_ <> '*'"

		DBUseArea( .T. , "TOPCONN" , TCGenQry( ,, _cQuery ) , _cAlias , .F. , .T. )
		DBSelectArea(_cAlias)

		If !(_cAlias)->( Eof() )

			aadd(_aalertas,"Já existe um cálculo de adicionais de " + IIf(_ntipo == 1,'leite magro','bonificações') + " após a liberação do financeiro para o período de comissões em aberto!(" + StrZero(_nmes,2) + "/" + StrZero(_nano,4) + ")")
				
		EndIf
		
		(_cAlias)->( DBCloseArea() )
	
	EndIf

EndIf

//=======================================================================================
//Se não teve problemas verifica se todos os títulos de comissão estão reprocessados
//=======================================================================================
If Len(_aalertas) == 0

		_cAlias	:= GetNextAlias()

		_cQuery := " SELECT E3_FILIAL FROM "+ RETSQLNAME('SE3') +" SE3 WHERE E3_I_ORIGE = '       ' "
		_cQuery += " AND E3_EMISSAO >= '" + StrZero(_nano,4) + StrZero(_nmes,2) + "01' AND E3_EMISSAO <= '" + StrZero(_nano,4) + StrZero(_nmes,2) + "31'"
		_cQuery += " AND D_E_L_E_T_ = ' ' AND E3_ORIGEM <> 'R' AND E3_ORIGEM <> 'F'"
		_cQuery += " GROUP BY E3_FILIAL ORDER BY E3_FILIAL"

		DBUseArea( .T. , "TOPCONN" , TCGenQry( ,, _cQuery ) , _cAlias , .F. , .T. )
		DBSelectArea(_cAlias)

		While !((_cAlias)->( Eof() ))

  			aAdd(_aalertas,"A filial " + (_cAlias)->E3_FILIAL + " possui registros  não recalculados para o período - (" + StrZero(_nmes,2) + "/" + StrZero(_nano,4) + ")")
  			(_cAlias)->( DBSkip() )
			
		
		EndDo
		
		(_cAlias)->( DBCloseArea() )

EndIf


//================================================================================
//se teve qualquer alerta na verificação monta mensagem e impede o processamento
//================================================================================

If Len(_aalertas) > 0
  
    _cMensagem := "<html>"
	_cMensagem += "<body>"
	_cMensagem += "<strong>"
	_cMensagem += "<p>"
	_cMensagem += "Foram encontrados problemas com o processo!<br>"
	_cMensagem += "Cálculo não será efetuado, corrija o processo e execute novamente.<br>"
	_cMensagem += "</p>
	_cMensagem += "</strong>
	_cMensagem += "<hr>"
		
   For _nI = 1 to Len(_aalertas)
  
  		_cMensagem += "<p>"
		_cMensagem += _aalertas[_nI] 
		_cMensagem += "</p>
		If _nI < Len(_aalertas) 
		  _cMensagem += "<hr>"
		EndIf
		
	Next
	
	_cMensagem += "</body>"
	_cMensagem += "</html>"
				
	MessageBox(_cMensagem, "Problema no processo", MB_OK)
  
  	Return .F.
		
EndIf 

Return .T.
