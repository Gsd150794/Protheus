#Include "FWMBROWSE.CH"
#Include "FWMVCDEF.CH"
#Include "TOTVS.ch"

#define	MB_OK				0

/*
===============================================================================================================================
Programa----------: ACOM001
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 31/07/2015                                    .
Descrição---------: Cadastro de Aprovadores e Solicitantes de solicitações de compras.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ACOM001()
Local _oBrowse		:= Nil

DBSelectArea("ZZL")
ZZL->(DBSetOrder(3)) //ZZL_FILIAL + ZZL_CODUSU
If ZZL->(DBSeek(xFilial("ZZL") + __cUserId))
	If ZZL->ZZL_ADMCAS == "S"

		//====================================================================================================
		// Configura e inicializa a Classe do Browse
		//====================================================================================================
		_oBrowse := FWMBrowse():New()
		
		_oBrowse:SetAlias( 'ZZ7' )
		_oBrowse:SetMenuDef( 'ACOM001' )
		_oBrowse:SetDescription( 'Cadastro de Aprovadores de Solicitacao de Compra' )
		_oBrowse:DisableDetails()
		
		_oBrowse:AddLegend( 'ZZ7->ZZ7_TIPO == "A" .And. ZZ7->ZZ7_STATUS == "N"' , 'GREEN'	, 'Aprovador Normal'		)
		_oBrowse:AddLegend( 'ZZ7->ZZ7_TIPO == "A" .And. ZZ7->ZZ7_STATUS == "A"' , 'YELLOW'	, 'Aprovador Ausente'		)
		_oBrowse:AddLegend( 'ZZ7->ZZ7_TIPO == "A" .And. ZZ7->ZZ7_STATUS == "B"' , 'BLACK'	, 'Aprovador Bloqueado'		)
		_oBrowse:AddLegend( 'ZZ7->ZZ7_TIPO == "S" .And. ZZ7->ZZ7_STATUS == "N"' , 'BLUE'	, 'Solicitante Normal'		)
		_oBrowse:AddLegend( 'ZZ7->ZZ7_TIPO == "S" .And. ZZ7->ZZ7_STATUS == "B"' , 'GRAY'	, 'Solicitante Bloqueado'	)
		
		_oBrowse:Activate()
	Else
		U_ITMsg("O usuário: " + cUserName + " não possui permissão para utilizar este cadastro.",;
		        "Usuário Inválido",;
		        "Verificar com a área de TI a possibilidade de habilitar o seu usuário.",2) 
	EndIf
Else
	U_ITMsg("O usuário: " + cUserName + " não possui permissão para utilizar este cadastro.",;
            "Usuário Inválido",;
            "Verificar com a área de TI a possibilidade de habilitar o seu usuário.",2) 
EndIf

Return

/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 31/07/2015                                    .
Descrição---------: Rotina para criação do menu da tela principal
Parametros--------: Nenhum
Retorno-----------: _aRotina - Array com as opções de menu.
===============================================================================================================================
*/
Static Function MenuDef()
Local _aRotina := {}

ADD OPTION _aRotina Title 'Visualizar'	Action 'VIEWDEF.ACOM001'	OPERATION 2 ACCESS 0
ADD OPTION _aRotina Title 'Incluir'   	Action 'VIEWDEF.ACOM001'	OPERATION 3 ACCESS 0
ADD OPTION _aRotina Title 'Alterar'   	Action 'VIEWDEF.ACOM001'	OPERATION 4 ACCESS 0
ADD OPTION _aRotina Title 'Excluir'		Action 'VIEWDEF.ACOM001'	OPERATION 5 ACCESS 0
ADD OPTION _aRotina Title 'Imprimir' 	Action 'VIEWDEF.ACOM001'	OPERATION 8 ACCESS 0
ADD OPTION _aRotina Title 'Copiar' 		Action 'U_ACOM001C()'		OPERATION 9 ACCESS 0

Return( _aRotina ) 

/*
===============================================================================================================================
Programa----------: ModelDef
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 31/07/2015                                    .
Descrição---------: Rotina para montagem do modelo de dados para o processamento
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ModelDef()

Local _oStruZZ7	:= FWFormStruct( 1 , 'ZZ7' )
Local _oStruZZ8	:= FWFormStruct( 1 , 'ZZ8' )
Local _oModel	:= Nil

_oModel := MpFormModel():New( 'ACOM001M' ,, {|_oModel| VALIDCOMIT(_oModel) } )

_oModel:AddFields(	'ZZ7MASTER'	,				, _oStruZZ7 )
_oModel:AddGrid(	'ZZ8DETAIL'	, 'ZZ7MASTER'	, _oStruZZ8 )

_oModel:SetRelation( 'ZZ8DETAIL', { { 'ZZ8_FILIAL' , 'xFilial( "ZZ8" )' } , { 'ZZ8_CODUSR' , 'ZZ7_CODUSR' } } , ZZ8->( IndexKey(1) ) )

_oModel:SetDescription( 'Cadastro de Aprovadores de Solicitacao de Compra' )

_oModel:GetModel( 'ZZ7MASTER' ):SetDescription( 'Dados Aprovador'	)
_oModel:GetModel( 'ZZ8DETAIL' ):SetDescription( 'Centro de Custo'	)

_oModel:GetModel( 'ZZ8DETAIL' ):SetUniqueLine( { 'ZZ8_CC' } )
_oModel:GetModel( 'ZZ8DETAIL' ):SetOptional( .T. )

_oModel:SetPrimaryKey( {'ZZ7_FILIAL','ZZ7_CODUSR' } )

Return( _oModel )

/*
===============================================================================================================================
Programa----------: ViewDef
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 31/07/2015                                    .
Descrição---------: Rotina para montar a View de Dados para exibição.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ViewDef()
Local _oModel	:= FWLoadModel( 'ACOM001' )
Local _oStruZZ7	:= FWFormStruct( 2 , 'ZZ7' )
Local _oStruZZ8	:= FWFormStruct( 2 , 'ZZ8' )
Local _oView	:= FWFormView():New()

_oStruZZ8:RemoveField( "ZZ8_CODUSR" )

_oStruZZ7:AddGroup( 'GRUPO01' , 'Dados do Aprovador:', " " , 2 )

_oStruZZ7:SetProperty( 'ZZ7_CODUSR'	, MVC_VIEW_GROUP_NUMBER , "GRUPO01" )
_oStruZZ7:SetProperty( 'ZZ7_USER'	, MVC_VIEW_GROUP_NUMBER , "GRUPO01" )
_oStruZZ7:SetProperty( 'ZZ7_NOME'	, MVC_VIEW_GROUP_NUMBER , "GRUPO01" )
_oStruZZ7:SetProperty( 'ZZ7_TIPO' 	, MVC_VIEW_GROUP_NUMBER , "GRUPO01" )
_oStruZZ7:SetProperty( 'ZZ7_STATUS'	, MVC_VIEW_GROUP_NUMBER , "GRUPO01" )
_oStruZZ7:SetProperty( 'ZZ7_APRSUB'	, MVC_VIEW_GROUP_NUMBER , "GRUPO01" )
_oStruZZ7:SetProperty( 'ZZ7_USRSUB'	, MVC_VIEW_GROUP_NUMBER , "GRUPO01" )
_oStruZZ7:SetProperty( 'ZZ7_NOMESU'	, MVC_VIEW_GROUP_NUMBER , "GRUPO01" )
_oStruZZ7:SetProperty( 'ZZ7_DTSUBI'	, MVC_VIEW_GROUP_NUMBER , "GRUPO01" )
_oStruZZ7:SetProperty( 'ZZ7_DTSUBF'	, MVC_VIEW_GROUP_NUMBER , "GRUPO01" )

_oView:SetModel( _oModel )

_oView:AddField(	'VIEW_CAB'	, _oStruZZ7	, 'ZZ7MASTER'	)
_oView:AddGrid(		'VIEW_DET'	, _oStruZZ8	, 'ZZ8DETAIL'	)

_oView:CreateHorizontalBox( 'SUPERIOR'	, 50 )
_oView:CreateHorizontalBox( 'INFERIOR'	, 50 )

_oView:SetOwnerView( 'VIEW_CAB'	, 'SUPERIOR'	)
_oView:SetOwnerView( 'VIEW_DET'	, 'INFERIOR'	)

_oView:EnableTitleView( 'VIEW_DET' , 'Centro de Custo:' )

Return( _oView )

/*
===============================================================================================================================
Programa----------: ACOM001VLD
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 31/07/2015                                    .
Descrição---------: Rotina para validação dos campos SX3
Parametros--------: Nenhum
Retorno-----------: _lRet -> .T. - Continua processo / .F. - não permite continuação do processo
===============================================================================================================================
*/
User Function ACOM001VLD()
Local _aArea		:= FWGetArea()
Local _aSave		:= FwSaveRows()
Local _cCampo		:= ReadVar()
Local _lRet			:= .T.
Local _cQry			:= ""
Local _cQryC		:= ""
Local _cAlias		:= GetNextAlias()
Local _nI			:= 0
Local _oModel		:= FWModelActive()
Local _oModelZZ8	:= _oModel:GetModel('ZZ8DETAIL')
Local _aInfHlp		:= {}

If 'ZZ7_TIPO' $ _cCampo
	If M->ZZ7_TIPO == 'S'
		M->ZZ7_APRSUB	:= Space(TamSX3("ZZ7_APRSUB")[1])
		M->ZZ7_USRSUB	:= Space(TamSX3("ZZ7_USRSUB")[1])
		M->ZZ7_NOMESU	:= Space(TamSX3("ZZ7_NOMESU")[1])
		M->ZZ7_DTSUBI	:= CtoD('//')
		M->ZZ7_DTSUBF	:= CtoD('//')
		M->ZZ7_STATUS	:= "N"
		
		_cQry := "SELECT COUNT(*) AS USADO "
		_cQry += "FROM " + RetSqlName("SC1") + " "
		_cQry += "WHERE C1_FILIAL = '" + xFilial("SC1") + "' "
		_cQry += "  AND C1_I_CODAP = '" + M->ZZ7_CODUSR + "' "
		_cQry += "  AND C1_APROV = 'B' "
		_cQry += "  AND D_E_L_E_T_ = ' ' "
		_cQry := ChangeQuery(_cQry)
		MPSysOpenQuery(_cQry,_cAlias)
		
		(_cAlias)->( DBGoTop() )
		If (_cAlias)->( !Eof() )
			If (_cAlias)->USADO > 0
				_aInfHlp := {}
				//                 |....:....|....:....|....:....|....:....|      |....:....|....:....|....:....|....:....|
				aAdd( _aInfHlp , { "Alteração de Tipo não permitido Aprov"		, "ador possui SC pendente.               "	} )
				aAdd( _aInfHlp , { "Por favor verificar SC's.            "		, "                                       "	} )
			
				U_ITCADHLP( _aInfHlp , "ACOM00107",.F. )
				
				U_ITMsg("Alteração de Tipo não permitido Aprovador possui SC pendente.",;
		                "Atenção",;
		                "Por favor verificar SC's.",3, , , .T.)
			
				_lRet := .F.
			Else
				For _nI := 1 To _oModelZZ8:Length()
					_oModelZZ8:GoLine(_nI)
					_oModelZZ8:DeleteLine()
				Next _nI
			EndIf
		Else
			For _nI := 1 To _oModelZZ8:Length()
				_oModelZZ8:GoLine(_nI)
				_oModelZZ8:DeleteLine()
			Next _nI
		EndIf
		
	EndIf
ElseIf 'ZZ7_STATUS' $ _cCampo
	If M->ZZ7_TIPO == 'S' .And. M->ZZ7_STATUS == 'A'
	
		_aInfHlp := {}
		//                 |....:....|....:....|....:....|....:....|      |....:....|....:....|....:....|....:....|
		aAdd( _aInfHlp , { "Para o tipo Solicitante, somente poderão"	, " ser selecionado as situações N ou B."	} )
		aAdd( _aInfHlp , { "Favor selecionar uma opção válida.  "		, ""										} )
				
		U_ITCADHLP( _aInfHlp , "ACOM00101",.F. )
		
		U_ITMsg("Para o tipo Solicitante, somente poderão ser selecionado as situações N ou B.",;
		        "Atenção",;
		        "Por favor verificar SC's.",3, , , .T.)

		_lRet := .F.
	EndIf
	If M->ZZ7_TIPO == 'A' .And. M->ZZ7_STATUS == 'N'
		M->ZZ7_APRSUB	:= Space(TamSX3("ZZ7_APRSUB")[1])
		M->ZZ7_USRSUB	:= Space(TamSX3("ZZ7_USRSUB")[1])
		M->ZZ7_NOMESU	:= Space(TamSX3("ZZ7_NOMESU")[1])
		M->ZZ7_DTSUBI	:= CtoD('//')
		M->ZZ7_DTSUBF	:= CtoD('//')
	EndIf
	If M->ZZ7_TIPO == 'A' .And. M->ZZ7_STATUS == 'B'
		For _nI := 1 To _oModelZZ8:Length()
			_oModelZZ8:GoLine(_nI)
			_oModelZZ8:LoadValue( 'ZZ8_MSBLQL' , '1' )
		Next _nI
	EndIf
ElseIf 'ZZ7_DTSUBI' $ _cCampo
	If !(Empty(M->ZZ7_DTSUBF))
		If M->ZZ7_DTSUBI > M->ZZ7_DTSUBF

			_aInfHlp := {}
			//                 |....:....|....:....|....:....|....:....|      |....:....|....:....|....:....|....:....|
			aAdd( _aInfHlp , { "A data início não pode ser maior que a "	, "data final.                          "	} )
			aAdd( _aInfHlp , { "Favor selecionar uma data válida.      "	, ""                                        } )
				
			U_ITCADHLP( _aInfHlp , "ACOM00102",.F. )
			
			U_ITMsg("A data início não pode ser maior que a data final. ",;
		            "Atenção",;
		            "Favor selecionar uma data válida.",3, , , .T.)

			_lRet := .F.
		EndIf
	EndIf
ElseIf 'ZZ7_DTSUBF' $ _cCampo
	If !(Empty(M->ZZ7_DTSUBF))
		If M->ZZ7_DTSUBF < M->ZZ7_DTSUBI

			_aInfHlp := {}
			//                 |....:....|....:....|....:....|....:....|      |....:....|....:....|....:....|....:....|
			aAdd( _aInfHlp , { "A data final não pode ser menor que a "	, "data inicio.                          "	} )
			aAdd( _aInfHlp , { "Favor selecionar uma data válida.      "	, ""                                    } )
				
			U_ITCADHLP( _aInfHlp , "ACOM00103",.F. )
			
			U_ITMsg("A data final não pode ser menor que a data inicio. ",;
		            "Atenção",;
		            "Favor selecionar uma data válida. ",3, , , .T.)
			

			_lRet := .F.
		EndIf
	EndIf
ElseIf 'ZZ7_CODUSR' $ _cCampo
	If !Empty(M->ZZ7_CODUSR)
		_lRet := UsrExist(M->ZZ7_CODUSR)
		If _lRet
			M->ZZ7_USER := UsrRetName(M->ZZ7_CODUSR)
			M->ZZ7_NOME := UsrFullName(M->ZZ7_CODUSR)
		EndIf
	EndIf
ElseIf 'ZZ7_APRSUB' $ _cCampo
	If !Empty(M->ZZ7_APRSUB)
		_lRet := UsrExist(M->ZZ7_APRSUB)
		If _lRet
			M->ZZ7_USRSUB := UsrRetName(M->ZZ7_APRSUB)
			M->ZZ7_NOMESU := UsrFullName(M->ZZ7_APRSUB)
		EndIf
	EndIf
ElseIf 'ZZ8_CC' $ _cCampo
	DBSelectArea("CTT") 
	CTT->(DBSetOrder(1))
	If CTT->(DBSeek(xFilial("CTT") + _oModelZZ8:GetValue("ZZ8_CC")))
		_oModelZZ8:LoadValue( 'ZZ8_DESCCC', CTT->CTT_DESC01 )
	Else
		aInfHlp := {}
		//                 |....:....|....:....|....:....|....:....|      |....:....|....:....|....:....|....:....|
		aAdd( _aInfHlp , { "O Centro de custo digitado não existe."	, "                                      "	} )
		aAdd( _aInfHlp , { "Favor digitar um CC correto, ou acessar"	, " a consulta via [F3]"                } )
				
		U_ITCADHLP( _aInfHlp , "ACOM00110",.F. )
		
		U_ITMsg("O Centro de custo digitado não existe.",;
		        "Atenção",;
		        "Favor digitar um CC correto, ou acessar a consulta via [F3]",3, , , .T.)

		_lRet := .F.
	EndIf
ElseIf 'ZZ8_MSBLQL' $ _cCampo
	If M->ZZ8_MSBLQL == '2'
		_cQry := "SELECT COUNT(*) AS USADO "
		_cQry += "FROM " + RetSqlName("ZZ8") + " "
		_cQry += "WHERE ZZ8_FILIAL = '" + xFilial("ZZ8") + "' "
		_cQry += "  AND ZZ8_CODUSR <> '" + ZZ7_CODUSR + "' "
		_cQry += "  AND ZZ8_CC = '" + _oModelZZ8:GetValue("ZZ8_CC")  + "' "   
		_cQry += "  AND ZZ8_MSBLQL = '2' "
		_cQry += "  AND D_E_L_E_T_ = ' ' "
		_cQry := ChangeQuery(_cQry)
		MPSysOpenQuery(_cQry,_cAlias)
		
		(_cAlias)->( DBGoTop() )

		If (_cAlias)->( !Eof() )
			If (_cAlias)->USADO > 0
				_cQryC := "SELECT ZZ8_CODUSR AS APROV "
				_cQryC += "FROM " + RetSqlName("ZZ8") + " "
				_cQryC += "WHERE ZZ8_FILIAL = '" + xFilial("ZZ8") + "' "
				_cQryC += "  AND ZZ8_CODUSR <> '" + ZZ7_CODUSR + "' "
				_cQryC += "  AND ZZ8_CC = '" +  _oModelZZ8:GetValue("ZZ8_CC") + "' "  
				_cQryC += "  AND ZZ8_MSBLQL = '2' "
				_cQryC += "  AND D_E_L_E_T_ = ' ' "
				_cQryC := ChangeQuery(_cQryC)
				MPSysOpenQuery(_cQryC,"TRBCAD")
				
				TRBCAD->( DBGoTop() )
		
				If TRBCAD->( !Eof() )
					_aInfHlp := {}
					//                 |....:....|....:....|....:....|....:....|      |....:....|....:....|....:....|....:....|
					aAdd( _aInfHlp , { "Centro de Custo já informado em outro "		, "cadastro. Aprov: " + TRBCAD->APROV + ".   "		} )
					aAdd( _aInfHlp , { "Favor verificar Centro de Custo infor-"		, "mado.                            "				} )
	
					U_ITCADHLP( _aInfHlp , "ACOM00108",.F. )
					
					U_ITMsg("Centro de Custo já informado em outro cadastro. Aprov: " + TRBCAD->APROV + ".",;
		                    "Atenção",;
		                    "Favor verificar Centro de Custo informado.",3, , , .T.)
	
					_lRet := .F.
				EndIf

				TRBCAD->( DBCloseArea() )
			EndIf
		EndIf

		(_cAlias)->( DBCloseArea() )

		If M->ZZ7_STATUS == "B"
			_aInfHlp := {}
			//                 |....:....|....:....|....:....|....:....|      |....:....|....:....|....:....|....:....|
			aAdd( _aInfHlp , { "Centro de Custo não pode ser desbloque"		, "ado, pois Aprovador está bloqueado.    "	} )
			aAdd( _aInfHlp , { "Favor verificar Centro de Custo infor-"		, "mado.                                  "	} )
	
			U_ITCADHLP( _aInfHlp , "ACOM00112",.F. )
			
			U_ITMsg("Centro de Custo não pode ser desbloqueado, pois Aprovador está bloqueado. ",;
		            "Atenção",;
		            "Favor verificar Centro de Custo informado.  ",3, , , .T.)
	
			_lRet := .F.
		EndIf

	EndIf
	
EndIf

FwRestRows(_aSave)
FWRestArea(_aArea)

Return(_lRet)

/*
===============================================================================================================================
Programa----------: VALIDCOMIT
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 31/07/2015                                    .
Descrição---------: Rotina para validação de validação TudoOk, valida as informações da tela antes de salvar o registro.
Parametros--------: _oModel -> Modelo de Dados
Retorno-----------: _lRet -> .T. - Continua processo / .F. - não permite continuação do processo
===============================================================================================================================
*/
Static Function VALIDCOMIT(_oModel)

Local _aArea		:= FWGetArea()
Local _aSave		:= FwSaveRows()
Local _aInfHlp		:= {}
Local _lRet			:= .T.
Local _cCodUsr		:= _oModel:GetValue( 'ZZ7MASTER' , 'ZZ7_CODUSR' )
Local _cTipo		:= _oModel:GetValue( 'ZZ7MASTER' , 'ZZ7_TIPO' 	)
Local _cStatus		:= _oModel:GetValue( 'ZZ7MASTER' , 'ZZ7_STATUS' )
Local _cAprSub		:= _oModel:GetValue( 'ZZ7MASTER' , 'ZZ7_APRSUB'	)
Local _dDtSubI		:= _oModel:GetValue( 'ZZ7MASTER' , 'ZZ7_DTSUBI' )
Local _dDtSubF		:= _oModel:GetValue( 'ZZ7MASTER' , 'ZZ7_DTSUBF'	)
Local _nOper		:= _oModel:GetOperation()
Local _oModelZZ8	:= _oModel:GetModel('ZZ8DETAIL')
Local _cQry			:= ""
Local _cAlias		:= GetNextAlias()
Local _cQryC		:= ""
Local _nI			:= 0
Local _nJ			:= 0
Local _nTam			:= 0

If _nOper == MODEL_OPERATION_INSERT
	DBSelectArea("ZZ7")
	DBSetOrder(1)
	If DBSeek(xFilial("ZZ7") + _cCodUsr)
		_aInfHlp := {}
		//                 |....:....|....:....|....:....|....:....|      |....:....|....:....|....:....|....:....|
		aAdd( _aInfHlp , { "Código do Aprovador/Solicitante infor"		, "mado já consta no cadastro.      "		} )
		aAdd( _aInfHlp , { "Verique o código digitado ou acesse o"		, " cadastro via [F3].              "		} )
	
		U_ITCADHLP( _aInfHlp , "ACOM00114",.F. )
		
		U_ITMsg("Código do Aprovador/Solicitante informado já consta no cadastro. ",;
		        "Atenção",;
		        "Verique o código digitado ou acesse o cadastro via [F3].  ",3 , , , .T.)
	
		_lRet := .F.
	EndIf

	If !UsrExist(_cCodUsr)
	
		_aInfHlp := {}
		//                 |....:....|....:....|....:....|....:....|      |....:....|....:....|....:....|....:....|
		aAdd( _aInfHlp , { "Código do Aprovador/Solicitante infor"		, "mado está incorreto.             "		} )
		aAdd( _aInfHlp , { "Verique o código digitado ou acesse o"		, " cadastro via [F3].              "		} )
	
		U_ITCADHLP( _aInfHlp , "ACOM00104",.F. )
		
		U_ITMsg("Código do Aprovador/Solicitante informado está incorreto. ",;
		        "Atenção",;
		        "Verique o código digitado ou acesse o cadastro via [F3].",3 , , , .T.)
	
		_lRet := .F.
	
	EndIf
	
	If _cTipo == "A" .And. _cStatus == "A" .And. (Empty(_cAprSub) .Or. Empty(_dDtSubI) .Or. Empty(_dDtSubF))
	
		_aInfHlp := {}
		//                 |....:....|....:....|....:....|....:....|      |....:....|....:....|....:....|....:....|
		aAdd( _aInfHlp , { "Para Aprovador com status ausente,   "		, "informar substituto.             "		} )
		aAdd( _aInfHlp , { "Digite todas as informações do apro- "		, "vador subistituto.               "		} )
	
		U_ITCADHLP( _aInfHlp , "ACOM00105",.F. )
		
		U_ITMsg("Para Aprovador com status ausente, informar substituto. ",;
		        "Atenção",;
		        "Digite todas as informações do aprovador subistituto.",3, , , .T.)
	
		_lRet := .F.
	
	EndIf
	For _nI := 1 To _oModelZZ8:Length()
		_oModelZZ8:Goline(_nI)
		If !_oModelZZ8:IsDeleted()
			DBSelectArea("CTT")
			CTT->(DBSetOrder(1))
			If CTT->(DBSeek(xFilial("CTT") + _oModelZZ8:GetValue("ZZ8_CC")))
				If CTT->CTT_BLOQ <> "2"
					_aInfHlp := {}
					//                 |....:....|....:....|....:....|....:....|      |....:....|....:....|....:....|....:....|
					aAdd( _aInfHlp , { "Centro de Custo informado está bloqueado"	, ". Linha: " + AllTrim(Str(_nI)) + "              "		} )
					aAdd( _aInfHlp , { "Favor selecione um Centro de Custo   "		, "válido.                          "		} )
	
					U_ITCADHLP( _aInfHlp , "ACOM00106",.F. )
					
					U_ITMsg("Centro de Custo informado está bloqueado. Linha: " + AllTrim(Str(_nI)) + ". ",; 
		                    "Atenção",; 
		                    "Favor selecione um Centro de Custo válido. ", 3, , ,.T.) 
	
					_lRet := .F.
				EndIf
			EndIf
			_cQryC := "SELECT COUNT(*) AS CONTADOR "
			_cQryC += "FROM " + RetSqlName("ZZ8") + " "
			_cQryC += "WHERE ZZ8_CC = '" + _oModelZZ8:GetValue("ZZ8_CC") + "' "  
			_cQryC += "  AND ZZ8_CODUSR <> '" + _cCodUsr + "' "
			_cQryC += "  AND ZZ8_MSBLQL = '2' "
			_cQryC += "  AND D_E_L_E_T_ = ' ' "
			_cQryC := ChangeQuery(_cQryC)
			MPSysOpenQuery(_cQryC,"TRBCC")

			TRBCC->(DBGoTop())
			
			If TRBCC->CONTADOR > 0
				
				_aInfHlp := {}
				//                 |....:....|....:....|....:....|....:....|      |....:....|....:....|....:....|....:....|
				aAdd( _aInfHlp , { "Centro de Custo já informado em outro "		, "cadastro.                        "		} )
				aAdd( _aInfHlp , { "Favor verificar Centro de Custo in-  "		, "formado.                         "		} )
	
				U_ITCADHLP( _aInfHlp , "ACOM00108", .F. )

				U_ITMsg("Centro de Custo já informado em outro cadastro. ",;
		                "Atenção",;
		                "Favor verificar Centro de Custo informado. ",3, , , .T.)
	
				_lRet := .F.
				
			EndIf
	
			TRBCC->(DBCloseArea())
		EndIf
	Next _nI

ElseIf _nOper == MODEL_OPERATION_UPDATE
	If !UsrExist(_cCodUsr)
	
		_aInfHlp := {}
		//                 |....:....|....:....|....:....|....:....|      |....:....|....:....|....:....|....:....|
		aAdd( _aInfHlp , { "Código do Aprovador/Solicitante infor"		, "mado está incorreto.             "		} )
		aAdd( _aInfHlp , { "Verique o código digitado ou acesse o"		, " cadastro via [F3].              "		} )
	
		U_ITCADHLP( _aInfHlp , "ACOM00104", .F. )
		
		U_ITMsg("Código do Aprovador/Solicitante informado está incorreto. ",;
		        "Atenção",;
		        "Verique o código digitado ou acesse o cadastro via [F3]. ",3, , , .T.)
	
		_lRet := .F.
	
	EndIf

	If _cTipo == "A" .And. _cStatus == "A" .And. (Empty(_cAprSub) .Or. Empty(_dDtSubI) .Or. Empty(_dDtSubF))
	
		_aInfHlp := {}
		//                 |....:....|....:....|....:....|....:....|      |....:....|....:....|....:....|....:....|
		aAdd( _aInfHlp , { "Para Aprovador com status ausente,   "		, "informar substituto.             "		} )
		aAdd( _aInfHlp , { "Digite todas as informações do apro- "		, "vador subistituto.               "		} )
	
		U_ITCADHLP( _aInfHlp , "ACOM00105", .F. )
		
		U_ITMsg("Para Aprovador com status ausente, informar substituto. ",;
		        "Atenção",;
		        "Digite todas as informações do aprovador subistituto. ",3, , , .T.)
	
		_lRet := .F.
	
	EndIf

	For _nI := 1 To _oModelZZ8:Length()
		_oModelZZ8:Goline(_nI)
		If !_oModelZZ8:IsDeleted()
			CTT->(DBSetOrder(1))
			If CTT->(DBSeek(xFilial("CTT") + _oModelZZ8:GetValue("ZZ8_CC")))
				If CTT->CTT_BLOQ <> "2"
					_aInfHlp := {}
					//                 |....:....|....:....|....:....|....:....|      |....:....|....:....|....:....|....:....|
					aAdd( _aInfHlp , { "Centro de Custo informado está bloqueado"	, ". Linha: " + AllTrim(Str(_nI)) + "              "		} )
					aAdd( _aInfHlp , { "Favor selecione um Centro de Custo   "		, "válido.                          "		} )
	
					U_ITCADHLP( _aInfHlp , "ACOM00106", .F. )
					
					U_ITMsg("Centro de Custo informado está bloqueado. Linha: " + AllTrim(Str(_nI)) + ". ",;
		                    "Atenção",;
		                    "Favor selecione um Centro de Custo válido. ",3, , , .T.)
	
					_lRet := .F.
				EndIf
			EndIf
			_cQryC := "SELECT COUNT(*) AS CONTADOR "
			_cQryC += "FROM " + RetSqlName("ZZ8") + " "
			_cQryC += "WHERE ZZ8_CC = '" + _oModelZZ8:GetValue("ZZ8_CC") + "' " 
			_cQryC += "  AND ZZ8_CODUSR <> '" + _cCodUsr + "' "
			_cQryC += "  AND ZZ8_MSBLQL = '2' "
			_cQryC += "  AND D_E_L_E_T_ = ' '
			_cQryC := ChangeQuery(_cQryC)
			MPSysOpenQuery(_cQryC,"TRBCC")

			TRBCC->(DBGoTop())
			
			If TRBCC->CONTADOR > 0
				If _cStatus <> "B" .And. _oModelZZ8:GetValue("ZZ8_MSBLQL") <> '1'
					_aInfHlp := {}
					//                 |....:....|....:....|....:....|....:....|      |....:....|....:....|....:....|....:....|
					aAdd( _aInfHlp , { "Centro de Custo já informado em outro "		, "cadastro.                        "		} )
					aAdd( _aInfHlp , { "Favor verificar Centro de Custo in-  "		, "formado.                         "		} )
	
					U_ITCADHLP( _aInfHlp , "ACOM00109", .F. )
					
					U_ITMsg("Centro de Custo já informado em outro cadastro. ",;
		                    "Atenção",;
		                    "Favor verificar Centro de Custo informado. ",3, , , .T.)
	
					_lRet := .F.
				EndIf
				
			EndIf
	
			TRBCC->(DBCloseArea())
		EndIf
	Next _nI

	For _nJ := 1 To _oModelZZ8:Length()
		_oModelZZ8:Goline(_nJ)
		If _oModelZZ8:IsUpdated()
			DBSelectArea("ZZ8")
			ZZ8->(DBSetOrder(1))
			If !ZZ8->(DBSeek(_oModelZZ8:GetValue("ZZ8_FILIAL") + _oModelZZ8:GetValue("ZZ8_CODUSR") + _oModelZZ8:GetValue("ZZ8_CC"))) .And. !Empty(_oModelZZ8:GetValue("ZZ8_FILIAL")) .And. !Empty(_oModelZZ8:GetValue("ZZ8_CODUSR"))
				_aInfHlp := {}
				//                 |....:....|....:....|....:....|....:....|      |....:....|....:....|....:....|....:....|
				aAdd( _aInfHlp , { "Alteração não permitida. Centro de Cu-"		, "sto " + _oModelZZ8:GetValue("ZZ8_CC") + "                              "	} )
				aAdd( _aInfHlp , { "Bloqueie ou delete o registro.       "		, "                                       "	} )
			
				U_ITCADHLP( _aInfHlp , "ACOM00111", .F. )
				
				U_ITMsg("Alteração não permitida. Centro de Custo " + _oModelZZ8:GetValue("ZZ8_CC") + ". ",;
		                "Atenção",;
		                "Bloqueie ou delete o registro.",3, , , .T.)
			
				_lRet := .F.
			EndIf
		EndIf
		If _oModelZZ8:IsDeleted()
			_nTam := Len(AllTrim(_oModelZZ8:GetValue("ZZ8_CC")))
			_cQry := "SELECT COUNT(*) AS USADO "
			_cQry += "FROM " + RetSqlName("SC1") + " "
			_cQry += "WHERE C1_FILIAL = '" + xFilial("SC1") + "' "
			_cQry += "  AND C1_I_CODAP = '" + ZZ7_CODUSR + "' "
			_cQry += "  AND SubStr(C1_CC,1," + AllTrim(Str(_nTam)) + ") = '" + AllTrim(_oModelZZ8:GetValue("ZZ8_CC")) + "' "
			_cQry += "  AND D_E_L_E_T_ = ' ' "
			_cQry := ChangeQuery(_cQry)
			MPSysOpenQuery(_cQry,"TRBCC")
			
			TRBCC->( DBGoTop() )
			If TRBCC->( !Eof() )
				If TRBCC->USADO > 0
					_aInfHlp := {}
					//                 |....:....|....:....|....:....|....:....|      |....:....|....:....|....:....|....:....|
					aAdd( _aInfHlp , { "Exclusão não permitida C. Custo já   "		, "utilizado em solicitação.              "	} )
					aAdd( _aInfHlp , { "Se necessário alterar o campo Bloquei-"		, "o para SIM.                      "		} )
				
					U_ITCADHLP( _aInfHlp , "ACOM00113",.F. )
					
					U_ITMsg("Exclusão não permitida C. Custo já utilizado em solicitação. ",;
		                    "Atenção",;
		                    "Se necessário alterar o campo Bloqueio para SIM.",3, , , .T.)
				
					_lRet := .F.
				EndIf
			EndIf
			TRBCC->( DBCloseArea() )
		EndIf
	Next _nJ
ElseIf _nOper == MODEL_OPERATION_DELETE
	_cQry := "SELECT COUNT(*) AS USADO "
	_cQry += "FROM " + RetSqlName("SC1") + " "
	_cQry += "WHERE C1_FILIAL = '" + xFilial("SC1") + "' "
	_cQry += "  AND C1_I_CODAP = '" + ZZ7_CODUSR + "' "
	_cQry += "  AND D_E_L_E_T_ = ' ' "
	_cQry := ChangeQuery(_cQry)
	MPSysOpenQuery(_cQry,_cAlias)
	
	(_cAlias)->( DBGoTop() )
	If (_cAlias)->( !Eof() )
		If (_cAlias)->USADO > 0
			_aInfHlp := {}
			//                 |....:....|....:....|....:....|....:....|      |....:....|....:....|....:....|....:....|
			aAdd( _aInfHlp , { "Exclusão não permitida Aprovador/Soli-"		, "citante já utilizado em Sol. de Compra."	} )
			aAdd( _aInfHlp , { "Se necessário alterar o campo Bloquei-"		, "o para SIM.                      "		} )
		
			U_ITCADHLP( _aInfHlp , "ACOM00104", .F. )
			
			U_ITMsg("Exclusão não permitida Aprovador/Solicitante já utilizado em Sol. de Compra.",;
		            "Atenção",;
		            "Se necessário alterar o campo Bloqueio para SIM. ",3, , , .T.)
		
			_lRet := .F.
		EndIf
	EndIf
EndIf

FWRestArea(_aArea)

FwRestRows(_aSave)

//======================================================================
// Grava log de Inclusão/Alteração/Exclusão do Cadastro de Aprovadores 
// e Solicitantes de solicitações de compras.
//====================================================================== 
U_ITLOGACS('VALIDCOMIT')

Return(_lRet)

/*
===============================================================================================================================
Programa----------: ACOM001C
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 31/07/2015                                    .
Descrição---------: Rotina escrita para fazer a cópia dos diretiros de um registro para o outro.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ACOM001C

Local _aArea	:= FWGetArea()
Local _cGetApo	:= Space(TamSX3("ZZ7_CODUSR")[1])
Local _cGetDst	:= Space(TamSX3("ZZ7_CODUSR")[1])
Local _cGetNao	:= Space(TamSX3("ZZ7_NOME")[1])
Local _cGetNds	:= Space(TamSX3("ZZ7_NOME")[1])
Local _cGetSao	:= Space(TamSX3("ZZ7_STATUS")[1])
Local _cGetSds	:= Space(TamSX3("ZZ7_STATUS")[1])
Local _nOpca	:= 0
Local _cQry		:= ""
Local _cQryC	:= ""
Local _cMsg		:= ""
Local _cAlias	:= GetNextAlias()

Local _oGetApo
Local _oGetDst
Local _oGetNao
Local _oGetNds
Local _oGetSao
Local _oGetSds

Local _oSayDst
Local _oSayApo
Local _oSayNao
Local _oSayNds
Local _oSaySao
Local _oSaySds
Local _oSButtonCn
Local _oSButtonOk

Private _oDlg

DEFINE MSDIALOG _oDlg TITLE "Cópia de direitos" FROM 000, 000  TO 170, 475 COLORS 0, 16777215 PIXEL

	@ 005, 006 Say _oSayApo	PROMPT "Aprovador Origem:"	SIZE 046, 007 OF _oDlg COLORS 16711680, 16777215	PIXEL
	@ 017, 006 MSGET _oGetApo VAR _cGetApo SIZE 050, 010 OF _oDlg VALID VldInf(@_cGetApo,@_cGetNao,@_cGetSao,1) COLORS 0, 16777215 F3 "ZZ7APO"	PIXEL

	@ 005, 066 Say _oSayNao	PROMPT "Nome:"				SIZE 025, 007 OF _oDlg COLORS 0, 16777215	PIXEL
	@ 017, 066 MSGET _oGetNao VAR _cGetNao SIZE 128, 010 OF _oDlg COLORS 0, 16777215 READONLY	PIXEL

	@ 005, 206 Say _oSaySao	PROMPT "Situação:"			SIZE 025, 007 OF _oDlg COLORS 0, 16777215	PIXEL
	@ 017, 206 MSGET _oGetSao VAR _cGetSao SIZE 020, 010 OF _oDlg COLORS 0, 16777215 READONLY	PIXEL

	@ 033, 006 Say _oSayDst	PROMPT "Aprovador Destino:"	SIZE 048, 007 OF _oDlg COLORS 16711680, 16777215	PIXEL
	@ 045, 006 MSGET _oGetDst VAR _cGetDst SIZE 050, 010 OF _oDlg VALID VldInf(@_cGetDst,@_cGetNds,@_cGetSds,2) COLORS 0, 16777215 F3 "ZZ7DST"	PIXEL

	@ 033, 066 Say _oSayNds	PROMPT "Nome:"				SIZE 025, 007 OF _oDlg COLORS 0, 16777215	PIXEL
	@ 045, 066 MSGET _oGetNds VAR _cGetNds SIZE 128, 010 OF _oDlg COLORS 0, 16777215 READONLY	PIXEL

	@ 033, 206 Say _oSaySds	PROMPT "Situação:"			SIZE 025, 007 OF _oDlg COLORS 0, 16777215	PIXEL
	@ 045, 206 MSGET _oGetSds VAR _cGetSds SIZE 020, 010 OF _oDlg COLORS 0, 16777215 READONLY	PIXEL
	
	DEFINE SBUTTON _oSButtonOk FROM 065, 085 Type 01 OF _oDlg ENABLE ACTION (_nOpca := 1, _oDlg:End())
	DEFINE SBUTTON _oSButtonCn FROM 065, 118 Type 02 OF _oDlg ENABLE ACTION _oDlg:End()

ACTIVATE MSDIALOG _oDlg CENTERED

If _nOpca == 1
	_cQry := "SELECT ZZ8_CC,ZZ8_CODUSR,ZZ8_MSBLQL "
	_cQry += "FROM " + RetSqlName("ZZ8") + " "
	_cQry += "WHERE ZZ8_FILIAL = '" + xFilial("ZZ8") + "' "
	_cQry += "  AND ZZ8_CODUSR = '" + _cGetApo + "' "
	_cQry += "  AND D_E_L_E_T_ = ' '
	_cQry := ChangeQuery(_cQry)
	MPSysOpenQuery(_cQry,_cAlias)

	(_cAlias)->( DBGoTop() )
	If (_cAlias)->( !Eof() )
		While (_cAlias)->( !Eof() )
			DBSelectArea("ZZ8")
			ZZ8->(DBSetOrder(1))
			ZZ8->(DBSeek(xFilial("ZZ8") + _cGetDst))
			
			_cQryC := "SELECT COUNT(*) AS CONTADOR "
			_cQryC += "FROM " + RetSqlName("ZZ8") + " "
			_cQryC += "WHERE ZZ8_CC = '" + (_cAlias)->ZZ8_CC + "' "
			_cQryC += "  AND ZZ8_CODUSR <> '" + _cGetApo + "' "
			_cQryC += "  AND D_E_L_E_T_ = ' '
			_cQryC := ChangeQuery(_cQryC)
			MPSysOpenQuery(_cQryC,"TRBCC")
			
			TRBCC->(DBGoTop())
			
			If TRBCC->CONTADOR > 0
				_cMsg += "O Centro de custo " + AllTrim((_cAlias)->ZZ8_CC) + ", já está sendo utilizado em outro cadastro."
			Else
				RecLock("ZZ8", .T.)
					ZZ8->ZZ8_FILIAL	:= xFilial("ZZ8")
					ZZ8->ZZ8_CODUSR	:= _cGetDst
					ZZ8->ZZ8_CC		:= (_cAlias)->ZZ8_CC
					ZZ8->ZZ8_MSBLQL	:= "2"
				ZZ8->(MSUnLock())
			EndIf
			
			TRBCC->(DBCloseArea())
			
			(_cAlias)->( DBSkip() )
		End
		If !Empty(_cMsg)
			U_ITMsg(_cMsg,;
            "Atenção", ,3, , , .T.)
		EndIf
	EndIf

	(_cAlias)->( DBCloseArea() )
	
   //===============================================================
   // Grava log da cópia dos diretiros de um registro para o outro.
   //=============================================================== 
   U_ITLOGACS('ACOM001C')
Else
   U_ITMsg('Operação cancelada pelo usuário.',;
           "Atenção", ,3, , , .T.)
EndIf

FWRestArea(_aArea)

Return

/*
===============================================================================================================================
Programa----------: VldInf
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 31/07/2015                                    .
Descrição---------: Rotina de validação das informações digitas na tela de cópia, e preenchimento dos campos virtuais
Parametros--------: _cCodUsr = Código do usuário aprovador.
                    _cNomeAp = Nome do aprovador
                    _cSituac = Situação / Status
                    _nCampo  = 1 = Aprovador de Origem / 2 = Aprovador de destino.
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function VldInf(_cCodUsr,_cNomeAp,_cSituac,_nCampo)

Local _aArea		:= FWGetArea()
Local _lRet			:= .T.
Local _cAprov		:= ""

If !Empty(_cCodUsr)
	DBSelectArea("ZZ7")
	ZZ7->(DBSetOrder(1))
	If ZZ7->(DBSeek(xFilial("ZZ7") + _cCodUsr))
		If _nCampo == 1
			If !(ZZ7->ZZ7_TIPO == "A" .And. ZZ7->ZZ7_STATUS == "B")
			   U_ITMsg("O usuário informado não está apto a ser copiado.",;
                       "Aprovador Inválido",;
                       "Verificar no cadastro se o usuário informado é Aprovador e se está como Bloqueado.",2, , , .T.) 
				
				_cCodUsr	:= Space(TamSX3("ZZ7_CODUSR")[1])
				_lRet		:= .F.
			Else
				_cNomeAp := ZZ7->ZZ7_NOME
				_cSituac := ZZ7->ZZ7_STATUS
			EndIf
		ElseIf _nCampo == 2
			If !(ZZ7->ZZ7_TIPO == "A" .And. ZZ7->ZZ7_STATUS <> "B")
			   U_ITMsg("O usuário informado não está apto a ser copiado.",;
                       "Aprovador Inválido",;
                       "Verificar no cadastro se o usuário informado é Aprovador e sua situação está diferente de Bloqueado.",2, , , .T.)
				
				_cCodUsr	:= Space(TamSX3("ZZ7_CODUSR")[1])
				_lRet		:= .F.
			Else
				_cNomeAp := ZZ7->ZZ7_NOME
				_cSituac := ZZ7->ZZ7_STATUS
			EndIf
		EndIf
	Else
	   U_ITMsg("Código digitado não existe no cadastro.",;
               "Aprovador não cadastrado",;
               "Favor digitar um código válido ou acionar a consulta via tecla [F3].",2, , , .T.)
            
		_lRet := .F.
	EndIf
Else
	If _nCampo == 1
		_cAprov := "Aprovador Origem"
	ElseIf _nCampo == 2
		_cAprov := "Aprovador Destino"
	EndIf

	U_ITMsg("Código do " + _cAprov + " não preenchido.",;
            "Aprovador Obrigatório",;
            "Favor preencher o código do " + _cAprov + ".",2, , , .T.) 
	
	_lRet := .F.
EndIf

FWRestArea(_aArea)

Return(_lRet)

/*
===============================================================================================================================
Programa----------: ACOM001T
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 08/09/2015
Descrição---------: Rotina escrita para fazer a transferência de aprovadores
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ACOM001T()

Local aArea		:= FWGetArea()
//==========================
// Dados do aprovador origem
//==========================
Local oGpAprO
Local oGAprO
Local cGAprO	:= Space(TamSX3("C1_I_CODAP")[1])
Local oGNomO
Local cGNomO	:= Space(TamSX3("ZZ7_NOME")[1])
Local oGSitO
Local cGSitO	:= Space(TamSX3("ZZ7_STATUS")[1])
Local oSAprO
Local oSNomO
Local oSSitO
//===========================
// Dados do aprovador destino
//===========================
Local oGpAprD
Local oGAprD
Local cGAprD	:= Space(TamSX3("C1_I_CODAP")[1])
Local oGNomD
Local cGNomD	:= Space(TamSX3("ZZ7_NOME")[1])
Local oGSitD
Local cGSitD	:= Space(TamSX3("ZZ7_STATUS")[1])
Local oSAprD
Local oSNomD
Local oSSitD

Local oSay1
Local nOpc		:= 0
Local nI		:= 0
Local nPosNum	:= 0
Local nPosIte	:= 0

Local oSButtonCa
Local oSButtonOk

Private aHeader		:= {}
Private aCols		:= {}

Private oMSNewGD
Private oDlg

//==================================================================
// Valida se o usuário corrente está configurado como adm de compras
//==================================================================
DBSelectArea("ZZL")
ZZL->(DBSetOrder(3)) //ZZL_FILIAL + ZZL_CODUSU
If ZZL->(DBSeek(xFilial("ZZL") + __cUserId))
	If ZZL->ZZL_ADMCAS == "N"
       U_ITMsg(__cUserId + " - " + AllTrim(UsrFullName(__cUserId)) + " sem permissão para utilizar esta funcionalidade.",;
               "Transferência de Aprovador",;
               "Favor comunicar a área de Compras, que é responsável por solicitar para TI a liberação desta funcionalidade.",2, , , .T.)
		
		FWRestArea(aArea)
		Return
	EndIf
Else
   U_ITMsg(__cUserId + " - " + AllTrim(UsrFullName(__cUserId)) + " sem permissão para utilizar esta funcionalidade.",;
           "Transferência de Aprovador",;
           "Favor comunicar a área de Compras, que é responsável por solicitar para TI a liberação desta funcionalidade.",2, , , .T.)
               
	FWRestArea(aArea)
	Return
EndIf

// Define field properties
//                     1            2         3           4          5        6        7       8       9       10          11      12        13       14         15        16   17
// aAdd(aHeader,{trim(x3_titulo),x3_campo,x3_picture,x3_tamanho,x3_decimal,x3_valid,x3_usado,x3_tipo, x3_f3,x3_context,	x3_cbox,x3_relacao,x3_when,X3_TRIGGER,	X3_PICTVAR,.F.,.F.})

aCols   := {}  
aHeader := {}
FillGetDados(1,"SC1",1,,,{||.T.},,,,,,.T.)
nUsado := Len(aHeader)

DEFINE MSDIALOG oDlg TITLE "Transferência Aprovador" FROM 000, 000  TO 600, 1000 COLORS 0, 16777215 PIXEL

	@ 001, 003 GROUP oGpAprO TO 066, 232 PROMPT "Aprovador Origem" OF oDlg COLOR 0, 16777215 PIXEL
    @ 001, 268 GROUP oGpAprD TO 066, 497 PROMPT "Aprovador Destino" OF oDlg COLOR 0, 16777215 PIXEL
	//============================
	//Informações Aprovador Origem
	//============================
	@ 014, 006 Say oSAprO PROMPT "Aprovador Origem?" SIZE 049, 007 OF oDlg COLORS 16711680, 16777215 PIXEL
	@ 023, 006 MSGET oGAprO VAR cGAprO SIZE 045, 010 OF oDlg PICTURE "@!" VALID {||AtuDados("O",cGAprO,@cGSitO,@cGNomO), TransfVld(cGAprO, cGAprD)} COLORS 0, 16777215 F3 "ZZ7TRF" PIXEL
	@ 014, 080 Say oSSitO PROMPT "Situação" SIZE 025, 007 OF oDlg COLORS 0, 16777215 PIXEL
	@ 023, 080 MSGET oGSitO VAR cGSitO SIZE 018, 010 OF oDlg COLORS 0, 16777215 READONLY PIXEL
	@ 037, 006 Say oSNomO PROMPT "Nome" SIZE 025, 007 OF oDlg COLORS 0, 16777215 PIXEL
	@ 045, 006 MSGET oGNomO VAR cGNomO SIZE 180, 010 OF oDlg COLORS 0, 16777215 READONLY PIXEL
	//=============================
	//Informações Aprovador Destino
	//=============================
	@ 015, 271 Say oSAprD PROMPT "Aprovador Destino?" SIZE 049, 007 OF oDlg COLORS 16711680, 16777215 PIXEL
	@ 025, 271 MSGET oGAprD VAR cGAprD SIZE 045, 010 OF oDlg PICTURE "@!" VALID {||AtuDados("D",cGAprD,@cGSitD,@cGNomD), TransfVld(cGAprO, cGAprD)} COLORS 0, 16777215 F3 "ZZ7TRF" PIXEL
	@ 015, 352 Say oSSitD PROMPT "Situação" SIZE 025, 007 OF oDlg COLORS 0, 16777215 PIXEL
	@ 025, 352 MSGET oGSitD VAR cGSitD SIZE 018, 010 OF oDlg COLORS 0, 16777215 READONLY PIXEL
	@ 038, 271 Say oSNomD PROMPT "Nome" SIZE 025, 007 OF oDlg COLORS 0, 16777215 PIXEL
	@ 045, 271 MSGET oGNomD VAR cGNomD SIZE 180, 010 OF oDlg COLORS 0, 16777215 READONLY PIXEL

	@ 074, 175 Say oSay1 PROMPT "Solicitações de Compras Pendentes para o Aprovador Origem" SIZE 150, 013 OF oDlg COLORS 0, 16777088 PIXEL

	oMSNewGD := MsNewGetDados():New( 095, 002, 295, 494, 0, "AllwaysTrue", "AllwaysTrue", "",,, 999, "AllwaysTrue", "", "AllwaysTrue", oDlg, aHeader, aCols)
	
	DEFINE SBUTTON oSButtonOk FROM 021, 237 Type 01 OF oDlg ENABLE ACTION (IIf(TransVldT(cGAprO, cGAprD),(nOpc := 1, oDlg:End()),nOpc := 2))
    DEFINE SBUTTON oSButtonCa FROM 037, 237 Type 02 OF oDlg ENABLE ACTION (nOpc := 2, oDlg:End())

ACTIVATE MSDIALOG oDlg CENTERED

If nOpc == 1
	nPosNum    := aScan(aHeader,{|x| AllTrim(x[2]) == "C1_NUM"	  })
	nPosIte	   := aScan(aHeader,{|x| AllTrim(x[2]) == "C1_ITEM"	  })
	nPosRecSC1 := aScan(aHeader,{|x| AllTrim(x[2]) == "C1_REC_WT" }) 
	
	DBSelectArea("SC1")
	SC1->(DBSetOrder(1))
	For nI := 1 To Len(oMSNewGD:aCols)
	    If nPosNum > 0 .And. nPosIte > 0
		   SC1->(DBSeek(xFilial("SC1") + oMSNewGD:aCols[nI,nPosNum] + oMSNewGD:aCols[nI,nPosIte])) // oMSNewGD:aCols[nI,nPosFil]
		   SC1->(RecLock("SC1", .F.))
		   SC1->C1_I_CODAP :=  cGAprD
		   SC1->(MSUnLock())
		Else
		   If nPosRecSC1 > 0
		      SC1->(DBGoTo(nPosRecSC1))
		      SC1->(RecLock("SC1", .F.))
			  SC1->C1_I_CODAP := cGAprD
		      SC1->(MSUnLock())
		   EndIf 
		EndIf
	Next
	
	U_ITMsg("Transferência concluída com sucesso.",;
            "Transferência de Aprovador", ,2, , , .T.)
   
   //===============================================================
   // Grava log da transferência de aprovadores
   //=============================================================== 
   U_ITLOGACS('ACOM001T')        
             
Else
   U_ITMsg("Transferência não foi concluída. Favor refazer o processo.",;
           "Transferência de Aprovador", ,2, , , .T.)
EndIf
	
FWRestArea(aArea)
Return

/*
===============================================================================================================================
Programa----------: AtuDados
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 08/09/2015                                    .
Descrição---------: Função escrita para fazer a atualização dos dados dos Aprovadores Origem/Destino
Parametros--------: cTipo - O = Aprovador Origem / D = Aprovador Destino
                  : cGApr - Código do Aprovador
                  : cGSit - Status do Aprovador
                  : cGNom - Nome do Aprovador
Retorno-----------: lRet - Retorno sempre .T., pois a função faz somente a atualização dos dados na tela
===============================================================================================================================
*/
Static Function AtuDados(cTipo,cGApr,cGSit,cGNom)

Local aArea		:= FWGetArea()
Local lRet		:= .T.
Local cQry		:= ""
Local cAlias	:= GetNextAlias()
Local nX		:= 0
Local aColsAux	:= {}
Local _cInicPadrao

DBSelectArea("ZZ7")
ZZ7->(DBSetOrder(1))
If ZZ7->(DBSeek(xFilial("ZZ7") + cGApr))
	cGSit := ZZ7->ZZ7_STATUS
	cGNom := ZZ7->ZZ7_NOME
EndIf

If cTipo == "O"
	If ZZ7->ZZ7_TIPO <> "A"
	   lRet := .F.

       U_ITMsg("Código de Origem informado não é um aprovador.",;
               "Transferência de Aprovador",;
               "Favor verificar o código informado.",2, , , .T.)
	EndIf
ElseIf cTipo == "D"
	If ZZ7->ZZ7_TIPO <> "A" .Or. ZZ7->ZZ7_STATUS == "B"
		lRet := .F.
		
		U_ITMsg("Código de Destino informado não é um Aprovador ou esta Bloqueado.",;
               "Transferência de Aprovador",;
               "Favor verificar o código informado.",2, , , .T.)
	EndIf
EndIf

If cTipo == "O" .And. lRet
	cQry := " SELECT "
	
	For nX := 1 To Len(aHeader)
	    If ! (AllTrim(aHeader[nX,2]) $ "C1_ALI_WT/C1_REC_WT") .And. AllTrim(aHeader[nX,10]) <> "V"
		   If nX > 1 
			  cQry += ", " + aHeader[nX,2] + " " 
		   Else
			  cQry += aHeader[nX,2] + " "
		   EndIf
		EndIf
	Next nX
	
	cQry += ", R_E_C_N_O_ NRRECNO "
	
	oMSNewGD:aCols := {}
	
	cQry += "FROM " + RetSqlName("SC1") + " "
	cQry += "WHERE C1_FILIAL = '" + xFilial("SC1") + "' "
	cQry += "  AND C1_I_CODAP = '" + cGApr + "' "
	cQry += "  AND C1_APROV = 'B' "
	cQry += "  AND D_E_L_E_T_ = ' ' "
	
	cQry += "ORDER BY C1_FILIAL, C1_NUM, C1_ITEM "
	cQry := ChangeQuery(cQry)
	MPSysOpenQuery(cQry,cAlias)
	
//                     1            2         3           4          5        6        7       8       9       10          11      12        13       14         15        16   17
// aAdd(aHeader,{trim(x3_titulo),x3_campo,x3_picture,x3_tamanho,x3_decimal,x3_valid,x3_usado,x3_tipo, x3_f3,x3_context,	x3_cbox,x3_relacao,x3_when,X3_TRIGGER,	X3_PICTVAR,.F.,.F.})

    DBSelectArea(cAlias)
	(cAlias)->( DBGoTop() )
	If (cAlias)->( !Eof() )
		While (cAlias)->( !Eof() )
			aColsAux := {}
			
			SC1->(DBGoTo((cAlias)->NRRECNO)) 
			
			For nX := 1 To Len(aHeader)
			    If AllTrim(aHeader[nX,10]) == "V" 
			       If AllTrim(aHeader[nX,2]) == "C1_ALI_WT"
			          aAdd(aColsAux, "SC1") 
			       ElseIf AllTrim(aHeader[nX,2]) == "C1_REC_WT" 
    			      aAdd(aColsAux,  (cAlias)->NRRECNO)
    			   Else
			          _cInicPadrao := GetSX3Cache(aHeader[nX,2],"X3_RELACAO")
			          If !Empty(_cInicPadrao)
			             aAdd(aColsAux, &(_cInicPadrao))
			          Else
			             aAdd(aColsAux, " ")
			          EndIf
			       EndIf
    			ElseIf aHeader[nX,8] == "D"  
				   aAdd(aColsAux, SToD((cAlias)->&(aHeader[nX,2])))
				Else
				   aAdd(aColsAux, (cAlias)->&(aHeader[nX,2]))
				EndIf
				
			Next nX

			(cAlias)->( DBSkip() )
			aAdd(aColsAux, .F.)
			aAdd(oMSNewGD:aCols, aColsAux)
		EndDo
	EndIf
	(cAlias)->( DBCloseArea() )	

	oMSNewGD:oBrowse:Refresh()
	oMSNewGD:Refresh()
EndIf

//====================================================================
// Grava log da atualização dos dados dos Aprovadores Origem/Destino
//==================================================================== 
U_ITLOGACS('AtuDados')

FWRestArea(aArea)
Return(lRet)

/*
===============================================================================================================================
Programa----------: TransfVld
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 08/09/2015
Descrição---------: Função escrita para validar dos códigos de Aprovador Origem e Aprovador Destino, que não podem ser iguais
Parametros--------: cGAprO - Código do Aprovador Origem
                  : cGAprD - Código do Aprovador Destino
Retorno-----------: lRet - .T. caso os códigos forem diferente, .F. caso contrário, e o sistema não deixa salvar a solicitação
===============================================================================================================================
*/
Static Function TransfVld(cGAprO, cGAprD)

Local aArea		:= FWGetArea()
Local lRet		:= .T.
Default cGAprO := ""
Default cGAprD := ""

If !Empty(cGAprO) .And. !Empty(cGAprD)
	If cGAprO == cGAprD
		lRet := .F.
		
		U_ITMsg("Código de Origem não pode ser o mesmo que o Código de Destino.",;
               "Transferência de Aprovador",;
               "Favor verificar os códigos informados.",2, , , .T.)
		
	EndIf
EndIf

FWRestArea(aArea)
Return(lRet)

/*
===============================================================================================================================
Programa----------: TransVldT
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 08/09/2015
Descrição---------: Função escrita para validar dos códigos de Aprovador Origem e Aprovador Destino
Parametros--------: cGAprO - Código do Aprovador Origem
                  : cGAprD - Código do Aprovador Destino
Retorno-----------: lRet - .T. caso os códigos forem diferente, .F. caso contrário, e o sistema não deixa salvar a solicitação
===============================================================================================================================
*/
Static Function TransVldT(cGAprO, cGAprD)

Local aArea		:= FWGetArea()
Local lRet		:= .T.

DBSelectArea("ZZ7")
ZZ7->(DBSetOrder(1))
If !ZZ7->(DBSeek(xFilial("ZZ7") + cGAprO))
	lRet := .F.
		
	U_ITMsg("Código de Origem informado não é valído.",;
           "Transferência de Aprovador",;
           "Favor verificar o código informado.",2, , , .T.)
EndIf

If !ZZ7->(DBSeek(xFilial("ZZ7") + cGAprD))
	lRet := .F.

	U_ITMsg("Código de Destino informado não é válido.",;
           "Transferência de Aprovador",;
           "Favor verificar o código informado.",2, , , .T.)
EndIf

FWRestArea(aArea)
Return(lRet)

/*
===============================================================================================================================
Programa----------: ACOM001G
Autor-------------: Julio de Paula Paz
Data da Criacao---: 25/07/2017
Descrição---------: Retorna o nome do usuário Protheus com base no código de usuário informado.
Parametros--------: Nenhum
Retorno-----------: _cRet = Nome do usuário Protheus.
===============================================================================================================================
*/
User Function ACOM001G()

Local _cRet   := Space(20)
Local _oModel := FWModelActive()
Local _cCodUsrP

_cCodUsrP := _oModel:GetValue( 'ZZ7MASTER' , 'ZZ7_CODUSR' )

If !Empty(_cCodUsrP)
	_cRet := FWSFAllUsers({_cCodUsrP},{"USR_NOME"})[1][3]
EndIf

Return _cRet
