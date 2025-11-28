/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
 Autor        |    Data    |                              Motivo                      										 
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  | 11/10/2019 | Chamado 28346. Removidos os Warning na compilação da release 12.1.25
Julio Paz     | 02/10/2023 | Chamado 44502. Ajustar rotina para fixar valor de limite de crédito para clientes inativados
Lucas Borges  | 22/04/2025 | Chamado 50505. Alterada a picture do CNPJ para contemplar campo alfanumérico
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "FWMVCDef.Ch"

#Define		TITULO	"Análise de Clientes Bloqueados"

/*
===============================================================================================================================
Programa----------: MOMS026
Autor-------------: Alexandre Villar
Data da Criacao---: 19/03/2014
Descrição---------: Rotina de Análise do Cadastro de Clientes Inativos
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS026()

Local _aInfHelp	:= {}

//===========================================================================
//| Define formato de data para exibição nas telas da rotina                |
//===========================================================================
SET DATE FORMAT TO "DD/MM/YYYY"

//===========================================================================
//| Verifica o acesso do usuário atual                                      |
//===========================================================================
If U_ITVLDUSR(3)

	Processa( {|| MOMS026INI() } , "Processando..." , "Iniciando o processamento..." )
	
Else

	aAdd( _aInfHelp	, { "Usuário sem acesso à rotina de Bloqueio"	, " de Clientes Inativos."	, ""	} )
	aAdd( _aInfHelp	, { "Verifique com a área de TI/ERP."			, ""						, ""	} )
	
	U_ITCADHLP( _aInfHelp , "OMS26U" )
	lRet := .F.

EndIf

Return

/*
===============================================================================================================================
Programa----------: MOMS026INI
Autor-------------: Alexandre Villar
Data da Criacao---: 19/03/2014
Descrição---------: Rotina de montagem da tela de processamento
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS026INI()

Local _aParAux		:= {}
Local _aParRet		:= {}
Local _aDados		:= {}
Local _aCpos		:= MOMS026CPS()
Local _aFields		:= {}
Local _cQuery		:= ""
Local cTpPes		:= ''
Local _cCGC			:= ''
Local _cAliasQry	:= GetNextAlias()
Local _nAtuReg		:= 0
Local _nI			:= 0
Local nI			:= 0
Local _lInc			:= .F.
Local _lDtCad		:= .F.
Local _lDtRea		:= .F.

Private oMarkBRW	:= Nil
Private cAliasAux	:= GetNextAlias()
Private _nTotReg	:= 0
Private cDtIni		:= ""
Private _aRegMrk	:= {}

aAdd( _aParAux , { 1 , "Inativo desde"		, Ctod( Space(8) )	, "@!"		, ""				, ""					, "" , 050	, .F. } ) //| 01 |
aAdd( _aParAux , { 1 , "Não listar redes"	, Space(150)		, "@!"		, ""				, "ACYLST"				, "" , 050	, .F. } ) //| 02 |
aAdd( _aParAux , { 3 , "Tipo de Cliente"	, 1					, { "Pessoa Jurídica" , "Pessoa Física" , "Todos" }		, 50 , ""	, .F. } ) //| 03 |
aAdd( _aParAux , { 3 , "Cliente/Rede"		, 1					, { "Sem Rede" , "Com Rede" , "Todos" }					, 50 , ""	, .F. } ) //| 04 |

For nI := 1 To Len( _aParAux )
	aAdd( _aParRet , _aParAux[nI][03] )
Next nI

If !ParamBox( _aParAux , "Parametrização do Relatório:" , @_aParRet )

	U_ITMsg(  "Operação cancelada pelo usuário!" , "Atenção!" , , 1 )
	Return
	
EndIf

cDtIni	:= DToS( MV_PAR01 )
cTpPes	:= IIf( MV_PAR03 == 1 , "J" , IIf( MV_PAR03 == 2 , "F" , "" ) )
_credes := AllTrim(MV_PAR02)

_cQuery := " SELECT "
_cQuery += "     SA1.A1_COD				AS CLIENTE,"
_cQuery += "     SA1.A1_LOJA			AS LOJA   ,"
_cQuery += "     SA1.A1_NOME			AS NOME   ,"
_cQuery += "     SA1.A1_GRPVEN			AS REDE   ,"
_cQuery += "	 SA1.A1_CGC				AS CGC    ,"
_cQuery += "	 SA1.A1_I_DTCAD			AS DAT_CAD,"
_cQuery += "     SA1.A1_PESSOA			AS TIP_PES,"
_cQuery += "     MAX( SF2.F2_EMISSAO )	AS ULT_FAT,"
_cQuery += "	 SA1.R_E_C_N_O_			AS REGSA1, "
_cQuery += "	 SA1.A1_I_DTREA			AS DT_REAV "	// Data da Reavaliação
_cQuery += " FROM  "+ RetSqlName("SA1") +" SA1 "
_cQuery += " LEFT JOIN "+ RetSqlName('SF2') +" SF2 ON SF2.F2_CLIENTE = SA1.A1_COD AND SF2.F2_LOJA = SA1.A1_LOJA AND SF2.D_E_L_E_T_ = ' ' "
_cQuery += " WHERE "
_cQuery += "     SA1.D_E_L_E_T_  = ' ' "
_cQuery += " AND SA1.A1_COD      > '000001' "
_cQuery += " AND SA1.A1_MSBLQL   <> '1' "

_cQuery += IIf(!Empty(cTpPes) , " AND SA1.A1_PESSOA = '"+ cTpPes +"' ","")								//Filtro de pessoa juridica/fisica

If MV_PAR04 == 2 //Para opção com rede filtra redes e não traz os sem rede

	_cQuery += " AND ( SA1.A1_GRPVEN <> '999999' AND SA1.A1_GRPVEN > '000000' ) " 						//Filtro de sem redes
	_cQuery += IIf( !Empty( _credes ) , " AND SA1.A1_GRPVEN NOT IN "+ FormatIn( _credes , ";" ) , "" ) 	//Filtro de rede de cliente
	
ElseIf MV_PAR04 == 1 //Para opção sem rede filtra todos que tenham alguma rede válida

	_cQuery += " AND ( SA1.A1_GRPVEN = '999999' OR SA1.A1_GRPVEN < '000000' ) " 						//filtro de clientes com rede
	_cQuery += IIf( !Empty( _credes ) , " AND SA1.A1_GRPVEN NOT IN "+ FormatIn( _credes , ";" ) , "" )	//Filtro de rede de cliente
	
ElseIf MV_PAR04 == 3 //Para opção todos só faz o filtro de redes

	_cQuery += IIf( !Empty( _credes ) , " AND SA1.A1_GRPVEN NOT IN "+ FormatIn( _credes , ";" ) , "" ) 	//Filtro de rede de cliente
	
EndIf

_cQuery += " GROUP BY SA1.A1_COD, SA1.A1_LOJA, SA1.A1_NOME, SA1.A1_GRPVEN, SA1.A1_CGC, SA1.A1_I_DTCAD, SA1.A1_PESSOA, SA1.R_E_C_N_O_, SA1.A1_I_DTREA "

_cQuery += " ORDER BY 1,2 "

If Select(_cAliasQry) > 0
	(_cAliasQry)->( DBCloseArea() )
EndIf

ProcRegua(0)
IncProc( "Lendo registros..." )
DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQuery) , _cAliasQry , .T. , .F. )

DBSelectArea(_cAliasQry)
(_cAliasQry)->( DBGoTop() )
COUNT TO _nTotReg

If _nTotReg <= 0

	(_cAliasQry)->( DBCloseArea() )
	U_ITMsg(  "Não foram encontrados Clientes Inativos no período de acordo com os parâmetros informados!" ,"Atenção!" ,,1 )
	Return
	
EndIf

If Select(cAliasAux) > 0
	(cAliasAux)->(DBCloseArea())
EndIf

_otemp := FWTemporaryTable():New( cAliasAux, _aCpos )

_otemp:Create()

DBSelectArea( cAliasAux )
ProcRegua(_nTotReg)

(_cAliasQry)->( DBGoTop() )
While (_cAliasQry)->( !Eof() )

	_lDtRea := .F.

	If (_cAliasQry)->TIP_PES == 'J'
	
		_cCGC	:= SubStr( (_cAliasQry)->CGC , 1 , 8 )
		_lInc	:= .T.
		_lDtCad	:= .F.
		_aDados	:= {}
		
		While (_cAliasQry)->(!Eof()) .And. _cCGC == SubStr( (_cAliasQry)->CGC , 1 , 8 )
			
			_nAtuReg++
			IncProc( "Analisando registros... ["+ StrZero( _nAtuReg , 6 ) +"]" )
			
			aAdd( _aDados , {	(_cAliasQry)->CLIENTE						,;
								(_cAliasQry)->LOJA							,;
								Capital( AllTrim( (_cAliasQry)->NOME ) )	,;
								Capital( AllTrim( Posicione( "ACY" , 1 , xFilial("ACY") + (_cAliasQry)->REDE , "ACY_DESCRI" ) ) )	,;
								MOMS026CGC( (_cAliasQry)->CGC )				,;
								SToD( (_cAliasQry)->DAT_CAD )				,;
								SToD( (_cAliasQry)->ULT_FAT )				,;
								SToD( (_cAliasQry)->DT_REAV )				,;	// Data da Reavaliação
								(_cAliasQry)->REGSA1						})
			
			If SToD( (_cAliasQry)->DAT_CAD ) < MV_PAR01
				_lDtCad	:= .T.
			EndIf
			
			If SToD( (_cAliasQry)->ULT_FAT ) > MV_PAR01
				_lInc	:= .F.
			EndIf
			// Faz validação da data de reavaliação
			If !Empty( (_cAliasQry)->DT_REAV )
				If SToD( (_cAliasQry)->DT_REAV ) > MV_PAR01
					_lDtRea := .T.
				EndIf
			EndIf

		(_cAliasQry)->( DBSkip() )
		EndDo
		
		If _lInc .And. _lDtCad .And. !_lDtRea
			
			For _nI := 1 To Len( _aDados )
				
				(cAliasAux)->( RecLock( cAliasAux , .T. ) )
				
				(cAliasAux)->CLIENTE	:= _aDados[_nI][01]
				(cAliasAux)->LOJA		:= _aDados[_nI][02]
				(cAliasAux)->NOME 		:= _aDados[_nI][03]
				(cAliasAux)->REDE		:= _aDados[_nI][04]
				(cAliasAux)->CGC		:= _aDados[_nI][05]
				(cAliasAux)->DAT_CAD	:= _aDados[_nI][06]
				(cAliasAux)->ULT_FAT	:= _aDados[_nI][07]
				(cAliasAux)->DT_REAV	:= _aDados[_nI][08]		// Data da Reavaliação
				(cAliasAux)->REGSA1		:= _aDados[_nI][09]
				
				(cAliasAux)->( MSUnLock() )
				
			Next _nI
			
		EndIf
	
	Else
		
		_nAtuReg++
		IncProc( "Analisando... ["+ StrZero( _nAtuReg , 6 ) +"] de ["+ StrZero( _nTotReg , 6 ) +"]" )

		// Faz validação da data de reavaliação
		If !Empty( (_cAliasQry)->DT_REAV )
			If SToD( (_cAliasQry)->DT_REAV ) > MV_PAR01
				_lDtRea := .T.
			EndIf
		EndIf

		If SToD( (_cAliasQry)->ULT_FAT ) < MV_PAR01 .And. SToD( (_cAliasQry)->DAT_CAD ) < MV_PAR01 .And. ! _lDtRea // _DtRea
			
			(cAliasAux)->( RecLock( cAliasAux , .T. ) )
			
			(cAliasAux)->CLIENTE	:= (_cAliasQry)->CLIENTE
			(cAliasAux)->LOJA		:= (_cAliasQry)->LOJA
			(cAliasAux)->NOME 		:= Capital( AllTrim( (_cAliasQry)->NOME ) )
			(cAliasAux)->REDE		:= Capital( AllTrim( Posicione( "ACY" , 1 , xFilial("ACY") + (_cAliasQry)->REDE , "ACY_DESCRI" ) ) )
			(cAliasAux)->CGC		:= MOMS026CGC( (_cAliasQry)->CGC )
			(cAliasAux)->DAT_CAD	:= SToD( (_cAliasQry)->DAT_CAD )
			(cAliasAux)->ULT_FAT	:= SToD( (_cAliasQry)->ULT_FAT )
			(cAliasAux)->DT_REAV	:= SToD( (_cAliasQry)->DT_REAV )	// Data da Reavaliação
			(cAliasAux)->REGSA1		:= (_cAliasQry)->REGSA1
			
			(cAliasAux)->( MSUnLock() )
		
		EndIf
		
		(_cAliasQry)->( DBSkip() )
		
	EndIf
	
EndDo

(_cAliasQry)->( DBCloseArea() )

aAdd( _aFields , { "Cliente"			, {|| (cAliasAux)->CLIENTE }  		, "C" , "@!" , 0 , TamSX3("A1_COD")[01]		, 0 } )
aAdd( _aFields , { "Loja"				, {|| (cAliasAux)->LOJA }			, "C" , "@!" , 0 , TamSX3("A1_LOJA")[01]	, 0 } )
aAdd( _aFields , { "Nome"				, {|| (cAliasAux)->NOME }			, "C" , "@!" , 0 , TamSX3("A1_NOME")[01]-20	, 0 } )
aAdd( _aFields , { "Rede"				, {|| (cAliasAux)->REDE }			, "C" , "@!" , 0 , TamSX3("ACY_DESCRI")[01]	, 0 } )
aAdd( _aFields , { "CPF/CNPJ"			, {|| (cAliasAux)->CGC }  			, "C" , "@!" , 0 , TamSX3("A1_CGC")[01]		, 0 } )
aAdd( _aFields , { "Dt. Cadastro"		, {|| DToC((cAliasAux)->DAT_CAD) }	, "C" , "@!" , 0 , 10						, 0 } )
aAdd( _aFields , { "Ult. Compra"		, {|| DToC((cAliasAux)->ULT_FAT) }	, "C" , "@!" , 0 , 10						, 0 } )
aAdd( _aFields , { "Dt. Reavaliação"	, {|| DToC((cAliasAux)->DT_REAV) }	, "C" , "@!" , 0 , 10						, 0 } )	// Data da Reavaliação

oMarkBRW := FWMarkBrowse():New()		   												// Inicializa o Browse

oMarkBRW:SetAlias( cAliasAux )			   												// Define Alias que será a Base do Browse
oMarkBRW:SetDescription( "Clientes Inativos a partir de: "+ DToC( SToD( cDtIni ) ) +" (Clientes sem faturamento após a data)" )	// Define o titulo do browse de marcacao
oMarkBRW:SetFieldMark( "MARCA" )														// Define o campo que sera utilizado para a marcação
oMarkBRW:SetMenuDef( 'MOMS026' )														// Força a utilização do menu da rotina atual
oMarkBRW:SetAllMark( {|| oMarkBRW:AllMark() , MOMS026MRK(.T.) } )						// Ação do Clique no Header da Coluna de Marcação
oMarkBRW:SetAfterMark( {|| MOMS026MRK(.F.) } )											// Ação na marcação/desmarcação do registro
oMarkBRW:SetFields( _aFields )													 		// Campos para exibição
oMarkBRW:AddButton( "Confirmar" , {|| Processa( {|| U_MOMS026B() } , "Bloqueando Clientes..." , "Aguarde!" ) } ,, 4 )
oMarkBRW:DisableConfig()

oMarkBRW:Activate()																		// Ativacao da classe

(cAliasAux)->( DBCloseArea() )

Return

/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Alexandre Villar
Data da Criacao---: 19/03/2014
Descrição---------: Rotina de construção do menu
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MenuDef()

Local aRotina	:= {}

ADD OPTION aRotina Title 'Consultar' Action 'U_MOMS026R( (cAliasAux)->REGSA1 )' OPERATION 2 ACCESS 0

Return( aRotina )

/*
===============================================================================================================================
Programa----------: MOMS026CNS
Autor-------------: Alexandre Villar
Data da Criacao---: 19/03/2014
Descrição---------: Rotina de consulta do cadastro completo do Cliente
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS026R( nRegSA1 )

Private cCadastro := "Cadastro do Cliente"

DBSelectArea("SA1")
SA1->( DBGoTo(nRegSA1) )
AxVisual( "SA1" , nRegSA1 , 2 )

Return

/*
===============================================================================================================================
Programa----------: MOMS026CPS
Autor-------------: Alexandre Villar
Data da Criacao---: 19/03/2014
Descrição---------: Define a criação de campos para exibição da análise
Parametros--------: Nenhum
Retorno-----------: aRet - Campos que serão criados e exibidos na tela
===============================================================================================================================
*/
Static Function MOMS026CPS( _nTotReg )

Local _aCpos := {}

aAdd( _aCpos , { "MARCA"		, "C" , 1							, 0 } )
aAdd( _aCpos , { "CLIENTE"		, "C" , TamSX3("A1_COD")[01]		, 0 } )
aAdd( _aCpos , { "LOJA"			, "C" , TamSX3("A1_LOJA")[01]		, 0 } )
aAdd( _aCpos , { "NOME"			, "C" , TamSX3("A1_NOME")[01]		, 0 } )
aAdd( _aCpos , { "REDE"			, "C" , TamSX3("ACY_DESCRI")[01]	, 0 } )
aAdd( _aCpos , { "CGC"			, "C" , 18							, 0 } )
aAdd( _aCpos , { "DAT_CAD"		, "D" , 8							, 0 } )
aAdd( _aCpos , { "ULT_FAT"		, "D" , 8							, 0 } )
aAdd( _aCpos , { "DT_REAV"		, "D" , 8							, 0 } )	// Data da Reavaliação
aAdd( _aCpos , { "REGSA1"		, "N" , 9							, 0 } )

Return( _aCpos )

/*
===============================================================================================================================
Programa----------: MOMS026B
Autor-------------: Alexandre Villar
Data da Criacao---: 19/03/2014
Descrição---------: Processa o Bloqueio dos Clientes Selecionados
Parametros--------: Nenhum
Retorno-----------: aRet - Campos que serão criados e exibidos na tela
===============================================================================================================================
*/
User Function MOMS026B()

Local _nI		:= 0
Local _nTotReg	:= Len(_aRegMrk)
Local _cCodUsr	:= RetCodUsr()
Local _cNumLote	:= ""
Local _cMsgBlq	:= ""
Local _nValCbLq := U_ITGETMV( 'IT_VALCBLQ',20.00 ) // Valor de limite de crédito de bloqueio.

_cMsgBlq := "Bloqueio Automático: "+ CRLF
_cMsgBlq += "Cliente inativo entre "+ DToC( SToD( cDtIni ) ) +" e "+ DToC( Date() ) +"]"+ CRLF
_cMsgBlq += "Usuário: "+ Capital( AllTrim( UsrFullName(_cCodUsr) ) ) +" / "+ DToC( Date() ) +" "+ Time()

ProcRegua( _nTotReg )

Begin Transaction

_cNumLote := U_ITInLote( "Z00" , "001" )

If _nTotReg > 0

	For _nI := 1 To _nTotReg
		
		IncProc( "Processando... ["+ StrZero( _nI , 6 ) +"] de ["+ StrZero( _nTotReg , 6 ) +"]" )
		
		DBSelectArea("SA1")
		SA1->( DBGoTo( _aRegMrk[_nI][01] ) )
		
		SA1->( RecLock( "SA1" , .F. ) )
        SA1->A1_MSBLQL	:= "1"
        SA1->A1_I_ACRED	:= _cMsgBlq
        SA1->A1_LC      := _nValCbLq // Valor de limite de crédito de bloqueio.
		SA1->( MSUnLock() )
	
		//===========================================================================
		//| Grava o Item processado no Lote                                         |
		//===========================================================================
		U_ITGrLote( "Z03" , _cNumLote , { { SA1->A1_FILIAL + SA1->A1_COD + SA1->A1_LOJA , SToD( cDtIni ) , Date() , "1" } } , "1" )
		
		If SA1->A1_PESSOA == 'J'
			
			_cQuery := " UPDATE "+ RetSqlName('SA1') +" SA1 "
			_cQuery += " SET SA1.A1_MSBLQL = '1', " 
			_cQuery += "     SA1.A1_LC = " + AllTrim(Str(_nValCbLq,16,2)) + " "
			_cQuery += " WHERE SA1.D_E_L_E_T_ = ' ' AND SA1.A1_PESSOA = 'J' AND SubStr( SA1.A1_CGC , 1 , 8 ) = '"+ SubStr( SA1->A1_CGC , 1 , 8 ) +"' "
			
			If TCSqlExec( _cQuery ) < 0
			    //								|....:....|....:....|....:....|....:....|
				ShowHelpDlg( 'Atenção!' ,	{	'Falhou ao processar o bloqueio de todas '			,;
												' as Lojas do Cliente sem movimentação!'			}, 2 ,;
											{	'Verifique o cadastro do Cliente: '+ SA1->A1_COD	,;
												' Loja: '+ SA1->A1_LOJA +' e demais lojas.'			}, 2  )
				
			EndIf
			
		EndIf
			
	Next _nI
	
	U_ITFnLote( "Z00" , _cNumLote )
	
	U_ITMsg(  '['+ cValToChar( Len( _aRegMrk ) ) +'] clientes processados com sucesso!' , 'Concluído!' ,,2 )
	
Else
	
	//===========================================================================
	//| Exclui o Lote que não teve registros processados.                       |
	//===========================================================================
	DBSelectArea("Z00")
	If Z00->( DBSeek( xFilial("Z00") + _cNumLote ) )
		
		Z00->( RecLock( "Z00" , .F. ) )
		Z00->( DBDelete() )
		Z00->( MSUnLock() )
		
	EndIf
	
	U_ITMsg(  'Não foram selecionados registros para processar!' , 'Atenção!' ,,1 )
	
EndIf

End Transaction

CloseBrowse()

Return

/*
===============================================================================================================================
Programa----------: MOMS026CGC
Autor-------------: Alexandre Villar
Data da Criacao---: 02/06/2014
Descrição---------: Formatação da Máscara para CPF/CNPJ
Parametros--------: Nenhum
Retorno-----------: aRet - Campos que serão criados e exibidos na tela
===============================================================================================================================
*/
Static Function MOMS026CGC( cCGCAux )

Local cRet	:= ""
Local cAux	:= AllTrim( cCGCAux )

If Len( cAux ) > 11

	cAux := PadL( cAux , 14 , "0" )
	cRet := Transform( cAux , "@R! NN.NNN.NNN/NNNN-99" )
	
Else

	cAux := PadL( cAux , 11 , "0" )
	cRet := Transform( cAux , "@R 999.999.999-99" )
	
EndIf

Return( cRet )

/*
===============================================================================================================================
Programa----------: MOMS026C
Autor-------------: Josué Danich Prestes
Data da Criacao---: 21/10/2015
Descrição---------: Rotina para montar consulta de redes de cliente
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS026C()

Local _cRet		:= ''
Local _cQuery	:= ''
Local _cAlias	:= GetNextAlias()
Local _cTitAux	:= 'Redes de clientes'
Local _aDados	:= {}
Local _nI		:= 0

_cQuery := " SELECT ACY_GRPVEN, 
_cQuery += " ACY_DESCRI FROM "
_cQuery += RETSQLNAME('ACY') +" ACY 
_cQuery += " WHERE " + RETSQLCOND('ACY') 
_cQuery += " AND ACY.ACY_FILIAL = '" + xFilial("SF5") + "'"
_cQuery += " ORDER BY ACY.ACY_GRPVEN"

If Select(_cAlias) > 0
	(_cAlias)->( DBCloseArea() )
EndIf

DBUseArea( .T. , "TOPCONN" , TCGenQry(,,_cQuery) , _cAlias , .F. , .T. )

DBSelectArea(_cAlias)
(_cAlias)->( DBGoTop() )

//carrega documentos válidos na matriz
While (_cAlias)->( !Eof() )

	aAdd( _aDados , { .F. , (_cAlias)->ACY_GRPVEN, (_cAlias)->ACY_DESCRI  } )
	
	(_cAlias)->( DBSkip() )
	
EndDo

(_cAlias)->( DBCloseArea() )

//Se tiver documentos válidos cria a consulta
If Len(_aDados) > 0

	If U_ITListBox( _cTitAux , { '__' , 'Código', 'Descrição' } , @_aDados , .F. , 2 , 'Selecione as redes para não listar: ' )
		
		For _nI := 1 To Len( _aDados )
		
			If _aDados[_nI][01]
	
				_cRet += AllTrim( _aDados[_nI][02] ) +';'
	
			EndIf
			
			If Len(_cret) > 70
		
				alert("Máximo de redes a selecionar ultrapassado, selecione 10 ou menos redes")
			
				_cRet := ""
				
				_nI := Len( _aDados ) + 1
				
			EndIf		
	
		Next _nI
	
		&( ReadVar() ) := SubStr( _cRet , 1 , Len(_cRet) - 1 )
		
	EndIf

//se não tiver redes cadastradas alerta e sai
Else
	
	U_ITMsg("Não há redes cadastradas!","Atenção",,1)
	
EndIf

Return( .T. )

/*
===============================================================================================================================
Programa----------: MOMS026MRK
Autor-------------: Alexandre Villar
Data da Criacao---: 01/03/2016
Descrição---------: Rotina que controla a marcação dos registros
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS026MRK( _lSetAll )

Local _nPosAux := 0

If _lSetAll
	
	If oMarkBRW:IsMark()
		
		_aRegMrk := {}
		
		(cAliasAux)->( DBGoTop() )
		While (cAliasAux)->( !Eof() )
		
			aAdd( _aRegMrk , { (cAliasAux)->REGSA1 } )
		
		(cAliasAux)->( DBSkip() )
		EndDo
		
		(cAliasAux)->( DBGoTop() )
		
	Else
		_aRegMrk := {}
	EndIf
	
Else
	
	If oMarkBRW:IsMark()
		
		If aScan( _aRegMrk , {|x| x[1] == (cAliasAux)->REGSA1 } ) == 0
			aAdd( _aRegMrk , { (cAliasAux)->REGSA1 } )
		EndIf
		
	Else
		
		If ( _nPosAux := aScan( _aRegMrk , {|x| x[1] == (cAliasAux)->REGSA1 } ) ) <> 0
		
			aDel( _aRegMrk , _nPosAux )
			aSize( _aRegMrk , Len( _aRegMrk ) -1 )
			
		EndIf
		
	EndIf
	
EndIf

Return
