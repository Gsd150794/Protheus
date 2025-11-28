/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
 Autor            |    Data    |                              Motivo                      										 
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges      | 14/10/2019 | Removidos os Warning na compilação da release 12.1.25. Chamado 28346
===============================================================================================================================
*/

//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================
#Include "TOTVS.ch"
#Include "FWMVCDEF.ch"

#DEFINE _ENTER CHR(13) + CHR(10)

/*
===============================================================================================================================
Programa--------: AOMS106
Autor-----------: Josué Danich Prestes
Data da Criacao-: 10/08/2011
===============================================================================================================================
Descrição-------: Cadastro de regras personalizadas de condição de pagamento - Chamado 24175
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function AOMS106()

Local _oBrowse
Local _lAcesso := U_ITVACESS( 'ZZL' , 3 , 'ZZL_CPPERS' , "S" )

Private aRotina	:= {}

//Verifica permissão de acesso a rotina
If !_lAcesso

	U_ITMsg("Usuário sem acesso a rotina","Atenção","Solicite liberação de acesso ao seu gestor",1)
	
	Return
	
EndIf

//Log de acesso
u_itlogacs()


//Instaciamento
_oBrowse := FWMBrowse():New()

//tabela que será utilizada
_oBrowse:SetAlias( "ZGO" )

//Define menus
ADD OPTION aRotina Title 'Visualizar'	Action 'VIEWDEF.AOMS106'	OPERATION 2 ACCESS 0
ADD OPTION aRotina Title 'Incluir'		Action 'VIEWDEF.AOMS106'	OPERATION 3 ACCESS 0
ADD OPTION aRotina Title 'Alterar'		Action 'VIEWDEF.AOMS106'	OPERATION 4 ACCESS 0
ADD OPTION aRotina Title 'Excluir'		Action 'VIEWDEF.AOMS106'	OPERATION 5 ACCESS 0
ADD OPTION aRotina Title 'Historico'	Action 'U_AOMS106H'	OPERATION 2 ACCESS 0

//Titulo
_oBrowse:SetDescription( "Regras de condições de pagamento" )

//ativa
_oBrowse:Activate()

Return


/*
===============================================================================================================================
Programa----------: ModelDef
Autor-------------: Josué Danich Prestes
Data da Criacao---: 29/03/2018
===============================================================================================================================
Descrição---------: Define o modelo de dados para a rotina de cadastro
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/

Static Function ModelDef()

//================================================================================
// Prepara a estrutura a ser usada no Modelo de Dados
//================================================================================
Local oStruCAB	:= FWFormStruct( 1 , 'ZGO' , { |cCampo| AOMS106K( cCampo , 1 ) } )
Local oStruITN	:= FWFormStruct( 1 , 'ZGO' , { |cCampo| AOMS106K( cCampo , 2 ) } )
Local oModel	:= Nil
Local _aGatAux	:= {}


//================================================================================
// Criação dos gatilhos para o cabeçalho da rotina
//================================================================================
_aGatAux := FwStruTrigger( 'ZGO_CLIENT'	, 'ZGO_CLINOM'	, 'IIf(Empty(AllTrim(M->ZGO_CLIENT+M->ZGO_LOJA)),"  ",Posicione("SA1",1,xFilial("SA1")+M->ZGO_CLIENT+M->ZGO_LOJA,"A1_NOME"))'			, .F. )
oStruCAB:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZGO_LOJA'	, 'ZGO_CLINOM'	, 'IIf(Empty(AllTrim(M->ZGO_CLIENT+M->ZGO_LOJA)),"  ",Posicione("SA1",1,xFilial("SA1")+M->ZGO_CLIENT+M->ZGO_LOJA,"A1_NOME"))'			, .F. )
oStruCAB:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZGO_REDE'	, 'ZGO_REDNOM'	, 'IIf(Empty(AllTrim(M->ZGO_REDE)),"    ",Posicione("ACY",1,xFilial("ACY")+M->ZGO_REDE,"ACY_DESCRI"))'			, .F. )
oStruCAB:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )


//================================================================================
// Criação dos gatilhos para o grid da rotina
//================================================================================

_aGatAux := FwStruTrigger( 'ZGO_PRODUT'	, 'ZGO_PRONOM'	, 'IIf(Empty(AllTrim(M->ZGO_PRODUT)),"   ",Posicione("SB1",1,xFilial("SB1")+M->ZGO_PRODUT,"B1_DESC"))'			, .F. )
oStruITN:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZGO_CONDPA'	, 'ZGO_CONDNI'	, 'Posicione("SE4",1,xFilial("SE4")+M->ZGO_CONDPA,"E4_DESCRI")'		, .F. )
oStruITN:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )




//================================================================================
// Cria e configura o modelo de dados
//================================================================================
oModel := MPFormModel():New( 'AOMS106M' )

oModel:SetDescription( 'Modelo de Dados do Lançamento de Conhecimento de Transporte' )

oModel:AddFields(	"ZGOMASTER" , /*cOwner*/  , oStruCAB , /*bPreValidacao*/ , /*bPosValidacao*/ , /*bCarga*/ )
oModel:AddGrid(		"ZGODETAIL" , "ZGOMASTER" , oStruITN , /*bPreValidacao*/ , /*bPosValidacao*/ , /*bCarga*/ )

oModel:SetRelation( "ZGODETAIL" , {	{ "ZGO_CLIENT" , "ZGO_CLIENT"		},;
 									{ "ZGO_LOJA"    , "ZGO_LOJA"	    },;
 									{ "ZGO_REDE"    , "ZGO_REDE"	    } } , ZGO->( IndexKey( 8 ) ) )

oModel:GetModel( 'ZGODETAIL' ):SetUniqueLine( { 'ZGO_ITEM' } )

oModel:GetModel( 'ZGODETAIL' ):SetUniqueLine( { "ZGO_FILCD" , 'ZGO_PRODUT' } )

oModel:GetModel( "ZGOMASTER" ):SetDescription( "Dados da Regra"	)
oModel:GetModel( "ZGODETAIL" ):SetDescription( "Itens da Regra"	)

oModel:SetPrimaryKey( { 'ZGO_FILIAL' , 'ZGO_ITEM', 'ZGO_CLIENT' , 'ZGO_LOJA', 'ZGO_REDE', "ZGO_FILCD",'ZGO_PRODUT'} )

Return( oModel )

/*
===============================================================================================================================
Programa----------: ViewDef
Autor-------------: Josué Danich Prestes
Data da Criacao---: 29/03/2018
===============================================================================================================================
Descrição---------: Define a View de dados para a rotina de cadastro
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/

Static Function ViewDef()

//================================================================================
// Prepara a estrutura do objeto da View
//================================================================================
Local oModel   	:= FWLoadModel( 'AOMS106' )

Local oStruCAB	:= FWFormStruct( 2 , 'ZGO' , { |cCampo| AOMS106K( cCampo , 1 ) } )
Local oStruITN	:= FWFormStruct( 2 , 'ZGO' , { |cCampo| AOMS106K( cCampo , 2 ) } )
Local oView		:= Nil

//================================================================================
// Instancia o Objeto da View
//================================================================================
oView := FWFormView():New()

//================================================================================
// Define o modelo de dados da view
//================================================================================
oView:SetModel( oModel )

//================================================================================
// Instancia os objetos da View com as estruturas de dados
//================================================================================
oView:AddField(	"VIEW_CAB"	, oStruCAB	, "ZGOMASTER"	)
oView:AddGrid(	"VIEW_ITN"	, oStruITN	, "ZGODETAIL"	)

//================================================================================
// Cria os Box horizontais para a View
//================================================================================
oView:CreateHorizontalBox( 'BOX0101' , 25 )
oView:CreateHorizontalBox( 'BOX0102' , 75 )

//================================================================================
// Define as estruturas da View para cada Box
//================================================================================
oView:SetOwnerView( "VIEW_CAB" , "BOX0101" )
oView:SetOwnerView( "VIEW_ITN" , "BOX0102" )

//================================================================================
// Define campo incremental para o GRID
//================================================================================
oView:AddIncrementField( 'VIEW_ITN' , 'ZGO_ITEM' )


Return( oView )

/*
===============================================================================================================================
Programa----------: AOMS106K
Autor-------------: Josué Danich Prestes
Data da Criacao---: 29/03/2018
===============================================================================================================================
Descrição---------: Valida os Campos que serão exibidos no Browse
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: lRet - Indica se o código foi validado ou seje já existe
===============================================================================================================================
*/

Static Function AOMS106K( _cCampo , _nLocal )

Local _lRet := AllTrim( _cCampo ) $ "ZGO_FILIAL,ZGO_CLIENT,ZGO_LOJA,ZGO_REDE,ZGO_CLINOM,ZGO_REDNOM,ZGO_ESPACO"

If _nLocal == 2
	_lRet := !_lRet
EndIf

Return( _lRet )

/*
===============================================================================================================================
Programa----------: AOMS106M
Autor-------------: Alexandre Villar
Data da Criacao---: 22/10/2014
===============================================================================================================================
Descrição---------: Rotina de controle e processamento dos pontos de entrada do MVC
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/

User Function AOMS106M()

Local _aParam		:= ParamIXB
Local _xRet			:= .T.
Local _oObj			:= ''
Local _oModel		:= Nil
Local _oModelMAS	:= Nil
Local _oModelDET	:= Nil
Local _cIdPonto		:= ''
Local _cIdModel		:= ''
Local _lIsGrid		:= .F.
Local _nLinhas		:= 0
Local _nOper		:= 0
Local _nni			:= 0

If _aParam <> NIL

	_oObj		:= _aParam[01]
	_cIdPonto	:= _aParam[02]
	_cIdModel	:= _aParam[03]
	_lIsGrid	:= ( Len( _aParam ) > 3 ) .And. ValType( _aParam[04] ) == 'N'
	_nOper		:= _oObj:GetOperation()
	
	Begin Sequence
	
	//Validação total do modelo
	If _cIdPonto == 'MODELPOS'
	
		_oModel 		:= FWModelActive()
		_oModelMAS 	:= _oModel:GetModel('ZGOMASTER')
		_oModelDET 	:= _oModel:GetModel('ZGODETAIL')
		_nlinhas    := _oModelDET:GetQtdLine()
	
		If _nlinhas < 1
		
				Help( ,, 'Atenção!',, "Incluir pelo menos uma linha de regra !",1, 0,, ,,, , {"Inclua pelo menos uma linha de regra"} )

			_xret := .F.
			Break
		
		EndIf
			
		//Validação de campos obrigatórios
		If Empty(_oModelMAS:GetValue("ZGO_CLIENT")) .And. Empty(_oModelMAS:GetValue("ZGO_REDE"))
		
			Help( ,, 'Atenção!',, "Cliente ou rede obrigatório !",1, 0,, ,,, , {"Preencha o campo cliente ou o campo rede"} )

			_xret := .F.
			Break
		
		EndIf
		
		//Validação de campos duplicados
		If !Empty(_oModelMAS:GetValue("ZGO_CLIENT")) .And. !Empty(_oModelMAS:GetValue("ZGO_REDE"))
		
			Help( ,, 'Atenção!',, "Cliente e rede não podem ser preenchidos ao mesmo tempo !",1, 0,, ,,, , {"Preencha o campo cliente ou o campo rede"} )

			_xret := .F.
			Break
		
		EndIf
		
		
	
	
	EndIf
	
	
	//Gravação de log
	If _cIdPonto == 'MODELPOS'
	
		_oModel 		:= FWModelActive()
		_oModelMAS 	:= _oModel:GetModel('ZGOMASTER')
		_oModelDET 	:= _oModel:GetModel('ZGODETAIL')
		_nlinhas    := _oModelDET:GetQtdLine()
		
		//Inclusão
		If _nOper == 3
		
			//Varre linhas criando uma linha de log para cada linha do modelo
			For _nni := 1 to _nlinhas
			
				If !_oModelDET:IsDeleted(_nni)
				
					_oModelDET::SetLine(_nni)
					RecLock("ZGP",.T.)
					ZGP->ZGP_FILIAL := xFilial("ZGP")
					ZGP->ZGP_ITEM   := _oModelDET:GetValue("ZGO_ITEM")
					ZGP->ZGP_CONDPA := _oModelDET:GetValue("ZGO_CONDPA")
					ZGP->ZGP_CLIENT := _oModelMAS:GetValue("ZGO_CLIENT")
					ZGP->ZGP_LOJA   := _oModelMAS:GetValue("ZGO_LOJA")
					ZGP->ZGP_PRODUT := _oModelDET:GetValue("ZGO_PRODUT")
					ZGP->ZGP_REDE   := _oModelMAS:GetValue("ZGO_REDE")
					ZGP->ZGP_DATA   := Date()
					ZGP->ZGP_HORA   := Time()
					ZGP->ZGP_USUARI := cUserName
					ZGP->ZGP_FILCS  := _oModelDET:GetValue("ZGO_FILCD")
					ZGP->(MSUnLock())
					
				EndIf
				
			Next
			
		EndIf
		
		//Alteração
		If _nOper == 4
		
			//Varre linhas criando uma linha de log para cada linha do modelo
			For _nni := 1 to _nlinhas
			
				_oModelDET::SetLine(_nni)
				_nposi := ZGO->(Recno())
				ZGO->(DBSetOrder(8)) //ZGO_CLIENT+ZGO_LOJA+ZGO_ITEM
				
				If .not. (_oModelDET:IsDeleted(_nni) .And. _oModelDET:IsInserted(_nni))
				
					RecLock("ZGP",.T.)
					ZGP->ZGP_FILIAL := xFilial("ZGP")
					ZGP->ZGP_ITEM   := _oModelDET:GetValue("ZGO_ITEM")
					ZGP->ZGP_CONDPA := _oModelDET:GetValue("ZGO_CONDPA")
					ZGP->ZGP_CLIENT := _oModelMAS:GetValue("ZGO_CLIENT")
					ZGP->ZGP_LOJA   := _oModelMAS:GetValue("ZGO_LOJA")
					ZGP->ZGP_PRODUT := _oModelDET:GetValue("ZGO_PRODUT")
					ZGP->ZGP_REDE   := _oModelMAS:GetValue("ZGO_REDE")
					ZGP->ZGP_DATA   := Date()
					ZGP->ZGP_HORA   := Time()
					ZGP->ZGP_USUARI := cUserName
					ZGP->ZGP_FILCS  := _oModelDET:GetValue("ZGO_FILCD")

					//Se já existe linha no zgo grava valores antigos
					If ZGO->(DBSeek(_oModelMAS:GetValue("ZGO_CLIENT")+_oModelMAS:GetValue("ZGO_LOJA")+_oModelDET:GetValue("ZGO_ITEM")))

						ZGP->ZGP_OCLI   := ZGO->ZGO_CLIENT
						ZGP->ZGP_OLOJ   := ZGO->ZGO_LOJA
						ZGP->ZGP_OPRO   := ZGO->ZGO_PRODUT
						ZGP->ZGP_ORED   := ZGO->ZGO_REDE
						ZGP->ZGP_FILO   := ZGO->ZGO_FILCD
						ZGP->ZGP_OCON   := ZGO->ZGO_CONDPA
												
					EndIf
					
					//Se apagou a linha grava que foi deletada
					If _oModelDET:IsDeleted(_nni)
				
						ZGP->ZGP_DELETA := "X"
					
					EndIf
					
					//mantém posicionamento original do ZGO
					ZGO->(DBGoTo(_nposi))
									
					ZGP->(MSUnLock())
					
				EndIf
				
			Next
			
		EndIf
		
		//Exclusão
		If _nOper == 5
		
			//Varre linhas criando uma linha de log para cada linha do modelo
			For _nni := 1 to _nlinhas
			
				_oModelDET::SetLine(_nni)
				_nposi := ZGO->(Recno())
				ZGO->(DBSetOrder(8)) //ZGO_CLIENT+ZGO_LOJA+ZGO_ITEM
				
				RecLock("ZGP",.T.)
				ZGP->ZGP_FILIAL := xFilial("ZGP")
				ZGP->ZGP_ITEM   := _oModelDET:GetValue("ZGO_ITEM")
				ZGP->ZGP_CONDPA := _oModelDET:GetValue("ZGO_CONDPA")
				ZGP->ZGP_CLIENT := _oModelMAS:GetValue("ZGO_CLIENT")
				ZGP->ZGP_LOJA   := _oModelMAS:GetValue("ZGO_LOJA")
				ZGP->ZGP_PRODUT := _oModelDET:GetValue("ZGO_PRODUT")
				ZGP->ZGP_REDE   := _oModelMAS:GetValue("ZGO_REDE")
				ZGP->ZGP_DATA   := Date()
				ZGP->ZGP_HORA   := Time()
				ZGP->ZGP_USUARI := cUserName
				ZGP->ZGP_FILCS  := _oModelDET:GetValue("ZGO_FILCD")
				ZGP->ZGP_DELETA := "X"

				//Se já existe linha no zgo grava valores antigos
				If ZGO->(DBSeek(_oModelMAS:GetValue("ZGO_CLIENT")+_oModelMAS:GetValue("ZGO_LOJA")+_oModelDET:GetValue("ZGO_ITEM")))

						ZGP->ZGP_OCLI   := ZGO->ZGO_CLIENT
						ZGP->ZGP_OLOJ   := ZGO->ZGO_LOJA
						ZGP->ZGP_OPRO   := ZGO->ZGO_PRODUT
						ZGP->ZGP_ORED   := ZGO->ZGO_REDE
						ZGP->ZGP_FILO   := ZGO->ZGO_FILCD
						ZGP->ZGP_OCON   := ZGO->ZGO_CONDPA
												
				EndIf
					
				//mantém posicionamento original do ZGO
				ZGO->(DBGoTo(_nposi))
									
				ZGP->(MSUnLock())
				
			Next
			
		EndIf
	
	EndIf
	
	//Validação de linha 
	If _cIdPonto == 'FORMLINEPOS'
	
		_oModel 		:= FWModelActive()
		_oModelMAS 	:= _oModel:GetModel('ZGOMASTER')
		_oModelDET 	:= _oModel:GetModel('ZGODETAIL')
		
	
		//Validação de campos obrigatórios
		If Empty(_oModelDET:GetValue("ZGO_CONDPA")) 
		
			Help( ,, 'Atenção!',, "Campo condição de pagamento precisa ser preenchido !",1, 0,, ,,, , {"Preencha o campo condição de pagamento"} )

			_xret := .F.
			Break
		
		EndIf
					
	EndIf
		
	End Sequence
	
EndIf
	
Return( _xRet )


/*
===============================================================================================================================
Programa----------: AOMS106V
Autor-------------: Josué Danich Prestes
Data da Criacao---: 29/03/2018
===============================================================================================================================
Descrição---------: Valida campo ZGO_CLIENT e ZGO_REDE
===============================================================================================================================
Parametros--------: _ccampo - Se está validando cliente ou rede
===============================================================================================================================
Retorno-----------: lRet - indica se campo foi validado
===============================================================================================================================
*/

User Function AOMS106V(_ccampo)  

Local _lRet := .T.
Local _cQuery := ""
Local _oModel 		:= FWModelActive()
Local _oModelMAS 	:= _oModel:GetModel('ZGOMASTER')
Local _cmsg := ""


_cQuery := " SELECT COUNT(ZGO_CONDPA) CONT"
_cQuery += " FROM "+ RetSqlName("ZGO") + " WHERE "  

If _ccampo == "ZGO_CLIENT"

	_cQuery += " D_E_L_E_T_ = ' ' AND ZGO_CLIENT = '" + AllTrim(_oModelMAS:GetValue("ZGO_CLIENT")) + "' AND ZGO_LOJA = '" + AllTrim(_oModelMAS:GetValue("ZGO_LOJA")) + "'"
	_cmsg := "Já existe cadastro para esse cliente!"
	

ElseIf _ccampo == "ZGO_REDE"

	_cQuery += " D_E_L_E_T_ = ' ' AND ZGO_REDE = '" + AllTrim(_oModelMAS:GetValue("ZGO_REDE")) + "'"
	_cmsg := "Já existe cadastro para essa rede!"

EndIf	

		
If Select("ZGOT") > 0
		
	DBSelectArea("ZGOT")
	ZGOT->(DBCloseArea())
			
EndIf
		
DBUseArea( .T. , "TOPCONN" , TCGenQry(,,_cQuery) , "ZGOT" , .T. , .F. )
	
If !(ZGOT->(Eof())) .And. ZGOT->CONT > 0

	Help( ,, 'Atenção!',, _cmsg ,1, 0,, ,,, , {"Utilize a função de alteração"} )

	_lRet := .F.
	
EndIf


Return _lRet



/*
===============================================================================================================================
Programa----------: AOMS106G
Autor-------------: Josué Danich Prestes
Data da Criacao---: 29/03/2018
===============================================================================================================================
Descrição---------: Inicialização de campos
===============================================================================================================================
Parametros--------: _ccampo - Campo a ser inicializado
					_par01 - parâmetro 01
					_par02 - parâmetro 02
===============================================================================================================================
Retorno-----------: _cret - string de inicialização do campo
===============================================================================================================================
*/

User Function AOMS106G(_ccampo,_par01,_par02)

Local _cret := "  "

If _ccampo == "ZGO_CONDNI" .And. !Empty(AllTrim(_par01))  

	_cret := Posicione("SE4",1,xFilial("SE4")+_par01,"E4_DESCRI")
	
EndIf   


If _ccampo == "ZGO_PRONOM" .And. !Empty(AllTrim(_par01)) 

	_cret := Posicione("SB1",1,xFilial("SB1")+_par01,"B1_DESC")
	
EndIf   

Return _cret  

/*
===============================================================================================================================
Programa----------: AOMS106D
Autor-------------: Josué Danich Prestes
Data da Criacao---: 29/03/2018
===============================================================================================================================
Descrição---------: Validação do campo C5_CONDPAG
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: _lRet - Validação do campo
===============================================================================================================================
*/
User Function AOMS106D()

Local _lRet := .T.
Local _ccondr := U_IT_conpv() //carrega condição de pagamento personalizada do pedido aberto

If M->C5_CONDPAG != _ccondr

	M->C5_I_CPMAN := "1"  //Marca como alteração manual somente se condição de pgto escolhida manualmente é diferente da regra automática

EndIf


Return _lRet

/*
===============================================================================================================================
Programa----------: AOMS106H
Autor-------------: Josué Danich Prestes
Data da Criacao---: 29/03/2018
===============================================================================================================================
Descrição---------: Histórico do cadastro de condições de pagamento
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS106H()
Local _cQuery := ''
Local calias  := GetNextAlias()
Local _alista := {}


If !Pergunte( 'AOMS106' )

	Return

EndIf

//-- Busca histórico na ZGP--//
_cQuery := " SELECT "
_cQuery += "     ZGP_CONDPA,ZGP_ITEM,ZGP_CLIENT,ZGP_LOJA,ZGP_PRODUT,ZGP_REDE,ZGP_OCON, "
_cQuery += "     ZGP_DATA,ZGP_HORA,ZGP_USUARI,ZGP_FILCS,ZGP_OCLI,ZGP_OLOJ,ZGP_OPRO,ZGP_ORED,ZGP_FILO,ZGP_DELETA
_cQuery += " FROM "+ RetSqlName("ZGP") +" ZGP "
_cQuery += " WHERE "
_cQuery += "     ZGP.ZGP_CLIENT	>= '"+ MV_PAR01 +"' "
_cQuery += " AND    ZGP.ZGP_CLIENT	<= '"+ MV_PAR03 +"' "
_cQuery += " AND    ZGP.ZGP_LOJA	>= '"+ MV_PAR02 +"' "
_cQuery += " AND    ZGP.ZGP_LOJA	<= '"+ MV_PAR04 +"' "
_cQuery += " AND    ZGP.ZGP_REDE	>= '"+ MV_PAR05 +"' "
_cQuery += " AND    ZGP.ZGP_REDE	<= '"+ MV_PAR06 +"' "
_cQuery += " AND	ZGP.ZGP_DATA	>= '"+ DToS(MV_PAR07) +"' "
_cQuery += " AND	ZGP.ZGP_DATA	<= '"+ DToS(MV_PAR08) +"' "
_cQuery += " AND ZGP.D_E_L_E_T_	= ' ' "
_cQuery += " ORDER BY ZGP_CONDPA,ZGP_ITEM,ZGP_DATA,ZGP_HORA"

If Select(cAlias) > 0
	(cAlias)->( DBCloseArea() )
EndIf

DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQuery) , cAlias , .T. , .F. )

DBSelectArea(cAlias)
(cAlias)->( DBGoTop() )

While  (cAlias)->(!Eof()) 

	aAdd(_alista,{  SToD((cAlias)->ZGP_DATA),;
					AllTrim((cAlias)->ZGP_HORA),;
					AllTrim((cAlias)->ZGP_USUARI),;
					(cAlias)->ZGP_CLIENT + "/" + (cAlias)->ZGP_LOJA,;
					(cAlias)->ZGP_REDE,;
					AllTrim((cAlias)->ZGP_ITEM),;
					AllTrim((cAlias)->ZGP_OCON),;
					AllTrim((cAlias)->ZGP_CONDPA),;
					(cAlias)->ZGP_OPRO,;
					(cAlias)->ZGP_PRODUT,;
					(cAlias)->ZGP_FILO,;
					(cAlias)->ZGP_FILCS,;
					If(!Empty((cAlias)->ZGP_DELETA),"DELETADO","ATIVO") })

	(cAlias)->( DBSkip() )
	
EndDo

If Len(_alista) > 0

 U_ITListBox( "Histórico para clientes/loja/rede de " + AllTrim(MV_PAR01)+"/"+ AllTrim(MV_PAR02)+"/"+ AllTrim(MV_PAR05) + " até " + AllTrim(MV_PAR04) +"/"+ AllTrim(MV_PAR03)+"/"+ AllTrim(MV_PAR06) + " da data " + DToC(MV_PAR07) + " até " + DToC(MV_PAR08) + ":" ,;
  				{'Data','Hora','Usuário','Cliente', 'Rede','Item','Cond ori','Cond alt','Produto ori','Produto alt','Filial ori','Filial alt','Situação'} ,;
  				 _alista , .F. , 1 )

Else

	U_ITMsg("Não foram localizados históricos com os parâmetros indicados","Atenção",,1)
	
EndIf


Return
