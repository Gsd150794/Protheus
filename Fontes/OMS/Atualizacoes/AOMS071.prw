/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
       Autor      |    Data    |                                             Motivo                                           
-------------------------------------------------------------------------------------------------------------------------------
Darcio Sporl	  | 12/05/2016 | Foi corrigida a validação quando se tem apenas um registros, e tentar colocá-lo como não ativo,
				  |			   | o sistema não tem mais aprovadores para trazer e selecionar, o sistema está gerando error.log. 
				  |			   | Chamado: 15444
-------------------------------------------------------------------------------------------------------------------------------
 Alex       	  | 13/06/2016 | Retirada a validacao para deixar mais de um ativo - Chamado 15214
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges      | 14/10/2019 | Removidos os Warning na compilação da release 12.1.25. Chamado 28346
===============================================================================================================================
*/

//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================
#Include 'FWMVCDEF.CH'
#Include "TOTVS.ch"

#define	MB_OK				0
/*
===================================================================================e===========================================
Programa----------: AOMS071
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 30/03/2016
===============================================================================================================================
Descrição---------: Cadastro de Aprovadores de Workflow de liberação de Crédito
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS071()

Local oBrowse		:= Nil
Local _cMensagem	:= ""

DBSelectArea("ZZL")
DBSetOrder(3) //ZZL_FILIAL + ZZL_CODUSU
If DBSeek(xFilial("ZZL") + __cUserId)
	If ZZL->ZZL_LIBCRE == "S"
		oBrowse := FWMBrowse():New()

		oBrowse:SetAlias("ZY0")
		oBrowse:SetDescription("Cadastro de Aprovador de Workflow de Liberação de (Crédito - Preço - Bonificação)")
		oBrowse:Activate()
	Else
		_cMensagem := "<html>"
		_cMensagem += "<body>"
		_cMensagem += "<p>"
		_cMensagem += "<strong>"
		_cMensagem += "Usuário Inválido<br><br>"
		_cMensagem += "</strong>
		_cMensagem += "O usuário: " + cUserName + " não possui permissão para utilizar este cadastro.<br>"
		_cMensagem += "</p>
		_cMensagem += "<hr>"
		_cMensagem += "<p>"
		_cMensagem += "Verificar com a área de TI a possibilidade de habilitar o seu usuário."
		_cMensagem += "</p>
		_cMensagem += "</body>"
		_cMensagem += "</html>"
						
		MessageBox(_cMensagem, "Atenção", MB_OK)
	EndIf
Else
	_cMensagem := "<html>"
	_cMensagem += "<body>"
	_cMensagem += "<p>"
	_cMensagem += "<strong>"
	_cMensagem += "Usuário Inválido<br><br>"
	_cMensagem += "</strong>
	_cMensagem += "O usuário: " + cUserName + " não possui permissão para utilizar este cadastro.<br>"
	_cMensagem += "</p>
	_cMensagem += "<hr>"
	_cMensagem += "<p>"
	_cMensagem += "Verificar com a área de TI a possibilidade de habilitar o seu usuário."
	_cMensagem += "</p>
	_cMensagem += "</body>"
	_cMensagem += "</html>"
					
	MessageBox(_cMensagem, "Atenção", MB_OK)
EndIf

Return(Nil)

/*
===============================================================================================================================
Programa----------: ModelDef
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 30/03/2016
===============================================================================================================================
Descrição---------: Rotina para montagem do modelo de dados para o processamento
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ModelDef()

Local oStruZY0	:= FWFormStruct(1,"ZY0")
Local oModel	:= Nil

oModel := MpFormModel():New('AOMS071M')

oModel:AddFields('ZY0MASTER', , oStruZY0)

oModel:SetPrimaryKey( {'ZY0_FILIAL','ZY0_CODUSR','ZY0_TIPO'} )

Return(oModel)

/*
===============================================================================================================================
Programa----------: ViewDef
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 30/03/2016
===============================================================================================================================
Descrição---------: Rotina para montar a View de Dados para exibição
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ViewDef()

Local oModel	:= FWLoadModel('AOMS071')
Local oStruZZI	:= FWFormStruct(2,'ZY0')
Local oView		:= Nil

oView := FWFormView():New()

oView:SetModel(oModel)

oView:AddField('VIEW_ZY0',oStruZZI,'ZY0MASTER')

oView:CreateHorizontalBox('TELA', 100)

oView:SetOwnerView('VIEW_ZY0','TELA')

Return(oView)

/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 30/03/2016
===============================================================================================================================
Descrição---------: Rotina para criação do menu da tela principal
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: _aRotina - Array com as opções de menu
===============================================================================================================================
*/
Static Function MenuDef()

Local _aRotina := {}

ADD OPTION _aRotina Title 'Visualizar'	Action 'VIEWDEF.AOMS071'	OPERATION 2 ACCESS 0
ADD OPTION _aRotina Title 'Incluir'   	Action 'U_AOMS071I()'		OPERATION 3 ACCESS 0
ADD OPTION _aRotina Title 'Alterar'   	Action 'U_AOMS071A()'		OPERATION 4 ACCESS 0
ADD OPTION _aRotina Title 'Excluir'		Action 'VIEWDEF.AOMS071'	OPERATION 5 ACCESS 0
ADD OPTION _aRotina Title 'Imprimir' 	Action 'VIEWDEF.AOMS071'	OPERATION 8 ACCESS 0
ADD OPTION _aRotina Title 'Copiar' 		Action 'VIEWDEF.AOMS071'	OPERATION 9 ACCESS 0

Return(_aRotina)

/*
===============================================================================================================================
Programa----------: AOMS071I
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 31/03/2016
===============================================================================================================================
Descrição---------: Função criada para fazer a inclusão de novos registros com validação.
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Lógico - .T. dados válidas, .F. dados inválidos
===============================================================================================================================
*/
User Function AOMS071I()

Local _aArea	:= FWGetArea()
Local _lRet		:= .T.
Local _cAlias	:= Alias()
Local _nReg		:= Recno()

Private cCadastro	:= "Cadastro de Aprovador de Workflow de Liberação de (Crédito - Preço - Bonificação)"

AxInclui( _cAlias, _nReg, 3, , , , "U_AOMSITOK()", , , , , , , .T.)

FWRestArea(_aArea)
Return(_lRet)

/*
===============================================================================================================================
Programa----------: AOMSITOK
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 31/03/2016
===============================================================================================================================
Descrição---------: Função criada para fazer a validação de inclusão.
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Lógico - .T. dados válidas, .F. dados inválidos
===============================================================================================================================
*/
User Function AOMSITOK()

Local _aArea	:= FWGetArea()
Local _lRet		:= .T.
Local _cQryD	:= ""

_cQryD := "SELECT COUNT(*) DUPLIC "
_cQryD += "FROM " + RetSqlName("ZY0") + " "
_cQryD += "WHERE ZY0_FILIAL = '" + xFilial("ZY0") + "' "
_cQryD += "  AND ZY0_CODUSR = '" + M->ZY0_CODUSR + "' "
_cQryD += "  AND ZY0_TIPO = '" + M->ZY0_TIPO + "' "
_cQryD += "  AND D_E_L_E_T_ = ' ' "

dbUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQryD ) , "TRBDUP" , .T., .F. )
	
DBSelectArea("TRBDUP")
TRBDUP->(DBGoTop())
	
If TRBDUP->DUPLIC > 0
	_lRet := .F.
	_aInfHlp := {}
	//                 |....:....|....:....|....:....|....:....|      |....:....|....:....|....:....|....:....|
	aAdd( _aInfHlp , { "Este registro não pode ser incluído   "	, "Já existe este usuário cadastrado.      "	} )
	aAdd( _aInfHlp , { "Favor tente cadastrar outro usuário.   "	, ""                                    } )
						
	U_ITCADHLP( _aInfHlp , "AOMS07101" )
EndIf

DBSelectArea("TRBDUP")
TRBDUP->(DBCloseArea())

FWRestArea(_aArea)
Return(_lRet)

/*
===============================================================================================================================
Programa----------: AOMS071A
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 31/03/2016
===============================================================================================================================
Descrição---------: Função criada para fazer a alteração dos registros com validação.
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Lógico - .T. dados válidas, .F. dados inválidos
===============================================================================================================================
*/
User Function AOMS071A()

Local _aArea	:= FWGetArea()
Local _lRet		:= .T.
Local _cAlias	:= Alias()
Local _nReg		:= Recno()

Private cCadastro	:= "Cadastro de Aprovador de Workflow de Liberação de (Crédito - Preço - Bonificação)"

AxAltera( _cAlias, _nReg, 4, , , , , "U_AOMSATOK()", , , , , , , .T.)

FWRestArea(_aArea)
Return(_lRet)

/*
===============================================================================================================================
Programa----------: AOMSATOK
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 31/03/2016
===============================================================================================================================
Descrição---------: Função criada para fazer a validação de alteração.
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Lógico - .T. dados válidas, .F. dados inválidos
===============================================================================================================================
*/
User Function AOMSATOK()

Local _aArea	:= FWGetArea()
Local _lRet		:= .T.
Local _cQry		:= ""
Local _cQryA	:= ""
Local _aHeader	:= {}
Local _aCols	:= {}
Local _nI		:= 0

If !M->ZY0_ATIVO == "S"
	_cQry := "SELECT COUNT(*) TOTREG "
	_cQry += "FROM " + RetSqlName("ZY0") + " "
	_cQry += "WHERE ZY0_ATIVO = 'S' "
	_cQry += "  AND ZY0_CODUSR <> '" + M->ZY0_CODUSR + "' "
	_cQry += "  AND ZY0_TIPO = '" + M->ZY0_TIPO + "' "
	_cQry += "  AND D_E_L_E_T_ = ' ' "
	
	dbUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQry ) , "TRBZY0" , .T., .F. )
	
	DBSelectArea("TRBZY0")
	TRBZY0->(DBGoTop())
	
	If TRBZY0->TOTREG == 0
		_cQryA := "SELECT * "
		_cQryA += "FROM " + RetSqlName("ZY0") + " "
		_cQryA += "WHERE ZY0_TIPO = '" + M->ZY0_TIPO + "' "
		_cQryA += "  AND ZY0_CODUSR <> '" + M->ZY0_CODUSR + "' "
		_cQryA += "  AND D_E_L_E_T_ = ' ' "
		
		dbUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQryA ) , "TRBLST" , .T., .F. )
		
		DBSelectArea("TRBLST")
		TRBLST->(DBGoTop())
		
		If !TRBLST->(Eof())
		
			While !TRBLST->(Eof())
				aAdd(_aCols, {	.F. ,;
								TRBLST->ZY0_CODUSR	,;
								TRBLST->ZY0_NOMUSR	,;
								TRBLST->ZY0_TIPO	,;
								TRBLST->ZY0_ATIVO	})

				TRBLST->(DBSkip())
			End

			_aHeader := { ' ' , 'Cód. Usuário' , 'Nome' , 'Tipo' , 'Ativo ?' }
		
			If U_ITListBox( "Seleciona Aprovador Ativo" , _aHeader , @_aCols , .F. , 2 , "Escolha um Aprovador para ficar ativo" , .T. , {50,100,200} , 2 )
		
				For _nI := 1 To Len(_aCols)
					If _aCols[_nI][1]
						DBSelectArea("ZY0")
						DBSetOrder(1)
						DBSeek(xFilial("ZY0") + _aCols[_nI][2] )//+ _aCols[_nI][4])
					    While !ZY0->(Eof()) .And. ZY0->ZY0_FILIAL == xFilial("ZY0") .And. ZY0->ZY0_CODUSR == _aCols[_nI][2]
						   If _aCols[_nI][4] == ZY0->ZY0_TIPO
						      RecLock("ZY0", .F.)
							  ZY0->ZY0_ATIVO := "S"
							  MSUnLock()
							  Exit
						   EndIf  						
						   ZY0->(DBSkip())
						EndDo
					EndIf
				Next _nI

			Else
				_lRet := .F.
				_aInfHlp := {}
				//                 |....:....|....:....|....:....|....:....|      |....:....|....:....|....:....|....:....|
				aAdd( _aInfHlp , { "Um aprovador deve ser selecionado para  "	, "ficar ativo.                          "	} )
				aAdd( _aInfHlp , { "Favor selecionar um aprovador.         "	, ""                                    } )
					
				U_ITCADHLP( _aInfHlp , "AOMS07104" )
			EndIf
		Else
			_lRet := .F.
			_aInfHlp := {}
			//                 |....:....|....:....|....:....|....:....|      |....:....|....:....|....:....|....:....|
			aAdd( _aInfHlp , { "Não há outro aprovador para ser selecio"	, "nado.                                  "} )
			aAdd( _aInfHlp , { "Favor deixar este aprovador ativo.     "	, ""                                    } )
					
			U_ITCADHLP( _aInfHlp , "AOMS07107" )
		EndIf

		DBSelectArea("TRBLST")
		TRBLST->(DBCloseArea())

	EndIf
	
	DBSelectArea("TRBZY0")
	TRBZY0->(DBCloseArea())
EndIf

FWRestArea(_aArea)
Return(_lRet)

/*
===============================================================================================================================
Programa----------: AOMS071VC
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 31/03/2016
===============================================================================================================================
Descrição---------: Função criada para fazer validações de campos.
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Lógico - .T. dados válidas, .F. dados inválidos
===============================================================================================================================
*/
User Function AOMS071VC()

Local _aArea	:= FWGetArea()
Local _lRet		:= .T.
Local _cCampo	:= ReadVar()

If "ZY0_CODUSR" $ _cCampo
	M->ZY0_NOMINT := AllTrim(UsrFullName(M->ZY0_CODUSR))
	M->ZY0_NOMUSR := AllTrim(UsrRetName(M->ZY0_CODUSR))
EndIf

FWRestArea(_aArea)
Return(_lRet)
