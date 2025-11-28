/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Igor Melgaço  |20/06/2023| Chamado 44223 - Ajustes para inclusão de opções no campo Z10_TIPO.
Igor Melgaço  |04/08/2023| Chamado 44597 - Ajuste para apontamento correto da hora inicial qdo lançado hora extra
Lucas Borges  |26/06/2025| Chamado 50617. Revisões diversas visando padronizar os fontes
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "FWMVCDEF.CH"
#Include "PONCALEN.CH"

/*
===============================================================================================================================
Programa----------: APON001
Autor-------------: Xavier
Data da Criacao---: 20/05/2015
Descrição---------: Fazer manutenção na tabela de ocorrencias de horarios no ponto
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function APON001

Local _oBrowse := Nil As Object

_oBrowse := FWMBrowse():New()
_oBrowse:SetAlias( 'Z10' )
_oBrowse:SetDescription( 'Ocorrencias de horarios' )
_oBrowse:DisableDetails()

//define legendas
_oBrowse:AddLegend( "AllTrim(Z10_IMPRES)=='S'" ,   "GREEN"    , "Impresso"  )
_oBrowse:AddLegend( "AllTrim(Z10_IMPRES)!='S'" ,   "RED"   , "Não Impresso"  )

_oBrowse:Activate()

Return

/*
===============================================================================================================================
Programa----------: MENUDEF
Autor-------------: Xavier
Data da Criacao---: 20/05/2015
Descrição---------: Opçções do menu
Parametros--------: Nenhum
Retorno-----------: Vetor com as opções
===============================================================================================================================
*/
Static Function MenuDef

Local _aRotina := {} As Array

ADD OPTION _aRotina TITLE 'Visualizar' 		ACTION 'VIEWDEF.APON001'  	OPERATION 2 ACCESS 0
ADD OPTION _aRotina TITLE 'Incluir'    		ACTION 'VIEWDEF.APON001'  	OPERATION 3 ACCESS 0
ADD OPTION _aRotina TITLE 'Alterar'    		ACTION 'VIEWDEF.APON001'  	OPERATION 4 ACCESS 0
ADD OPTION _aRotina TITLE 'Excluir'    		ACTION 'U_APON001D'	     	OPERATION 5 ACCESS 0
ADD OPTION _aRotina TITLE 'Emitir modelo' 	ACTION "U_RPON007(.T.)" 	OPERATION 2 ACCESS 1

Return _aRotina

/*
===============================================================================================================================
Programa----------: MODELDEF
Autor-------------: Xavier
Data da Criacao---: 20/05/2015
Descrição---------: Modelo de dados
Parametros--------: Nenhum
Retorno-----------: Objeto modelo de dados
===============================================================================================================================
*/
Static Function ModelDef

// Cria a estrutura a ser usada no Modelo de Dados
Local _oStruPAI := FWFormStruct( 1, 'Z10', /*bAvalCampo*/, /*lViewUsado*/ ) As Object
Local _oStruFIL := FWFormStruct( 1, 'Z10', /*bAvalCampo*/, /*lViewUsado*/ ) As Object
Local aGatAux	:= {} As Array
Local _oModel	:= Nil As Object

//Define Gatilhos para a Estrutura de Dados
aGatAux := FwStruTrigger( 'Z10_MATRIC' , 'Z10_TIPO' , 'U_APON001A( M->Z10_MATRIC, M->Z10_DATA )' , .F.)
_oStruFIL:AddTrigger( aGatAux[01] , aGatAux[02] , aGatAux[03] , aGatAux[04] )

_aGatAux := FwStruTrigger( 'Z10_TIPO'	, 'Z10_MOTIVO'	, 'U_APON001G1()' , .F. )
_oStruFIL:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

//Define edição de campo
_oStruFil:SetProperty('Z10_TIPO' , MODEL_FIELD_WHEN,{|| .T. })
_oStruFil:SetProperty('Z10_MATRIC' , MODEL_FIELD_WHEN,{|| .T. })

// remover campos
_oStruPAI:RemoveField( 'Z10_MATRIC' )
_oStruPAI:RemoveField( 'Z10_FUNCIO' )
_oStruPAI:RemoveField( 'Z10_TIPO' )
_oStruPAI:RemoveField( 'Z10_MOTIVO' )
_oStruPAI:RemoveField( 'Z10_IMPRES' )
_oStruPAI:RemoveField( 'Z10_ORIGEM' )
_oStruFIL:RemoveField( 'Z10_DATA' )
_oStruPAI:RemoveField( 'Z10_HORAIN' )
_oStruPAI:RemoveField( 'Z10_HORAFI' )
_oStruPAI:RemoveField( 'Z10_TEMPOD' )

// Cria o objeto do Modelo de Dados
_oModel := MPFormModel():New( 'MAPON001' ,  { |_oModel| U_APON001R( _oModel ) }  , { |_oModel| U_APON001Z( _oModel, M->Z10_DATA ) } , /*commit*/ , /*bCancel*/ )

// Adiciona a descricao do Modelo de Dados
_oModel:SetDescription( 'Ocorrencias de horarios' )

// Adiciona ao modelo uma estrutura de formulário de edição por campo
_oModel:AddFields( 'Z10PAI', NIL, _oStruPAI,/*bPre-Validacao*/,/*bPos-Validacao*/,/*bCarga*/ )

// Adiciona ao modelo uma estrutura de formulário de edição por grid       
_oModel:AddGrid( 'Z10FIL', 'Z10PAI', _oStruFIL , /*bLinePre*/ /*prelinha*/, {|_oModelGrid, nLine, cAction, cField| U_APON001V(_oModelGrid, nLine, cAction, cField)} /*bLinePost*/ , /*bPreVal*/ , /*bPosVal*/ , /*BLoad*/  )

//define a chave primaria
_oModel:SetPrimaryKey( { "Z10_FILIAL", "Z10_DATA", "Z10_MATRIC", "Z10_ORIGEM"} )

// Faz relaciomaneto entre os compomentes do model
_oModel:SetRelation( 'Z10FIL', { { 'Z10_FILIAL', 'xFilial( "Z10" ) ' } , { 'Z10_DATA', 'Z10_DATA' }} , Z10->( IndexKey( 1 ) ) )

// Liga o controle de nao repeticao de linha
_oModel:GetModel( 'Z10FIL' ):SetUniqueLine( { 'Z10_MATRIC', 'Z10_ORIGEM' } )

// Adiciona a descricao do Componente do Modelo de Dados
_oModel:GetModel( 'Z10PAI' ):SetDescription( 'Dados da Ocorrencia' )
_oModel:GetModel( 'Z10FIL' ):SetDescription( 'Dados do Funcionario'  )

_oModel:GetModel( 'Z10FIL' ):SetNoDeleteLine( .T. )

//define obrigatoriedade de linha digiada no grid
_oModel:GetModel( 'Z10FIL' ):SetOptional( .F. )

Return _oModel

/*
===============================================================================================================================
Programa----------: ViewDef
Autor-------------: Xavier
Data da Criacao---: 20/05/2015
Descrição---------: Visão de dados
Parametros--------: Nenhum
Retorno-----------: Objeto visão de dados
===============================================================================================================================
*/
Static Function ViewDef

// Cria a estrutura a ser usada na View
Local _oStruPAI := FWFormStruct( 2, 'Z10',/*{ |cCampo, nLocal| Campo(cCampo,1) }*/ )
Local _oStruFIL := FWFormStruct( 2, 'Z10',/*{ |cCampo, nLocal| Campo(cCampo,2) }*/ )

// Cria um objeto de Modelo de Dados baseado no ModelDef do fonte informado
Local _oModel   := FWLoadModel( 'APON001' )
Local _oView

// remover campos
_oStruPAI:RemoveField( 'Z10_MATRIC' )
_oStruPAI:RemoveField( 'Z10_FUNCIO' )
_oStruPAI:RemoveField( 'Z10_TIPO' )
_oStruPAI:RemoveField( 'Z10_MOTIVO' )
_oStruPAI:RemoveField( 'Z10_IMPRES' )
_oStruPAI:RemoveField( 'Z10_ORIGEM' )
_oStruFIL:RemoveField( 'Z10_DATA' )
_oStruPAI:RemoveField( 'Z10_HORAIN' )
_oStruPAI:RemoveField( 'Z10_HORAFI' )
_oStruPAI:RemoveField( 'Z10_TEMPOD' )

// Cria o objeto de View
_oView := FWFormView():New()

// Define qual o Modelo de dados será utilizado
_oView:SetModel( _oModel )

//Adiciona no nosso View um controle do tipo FormFields(antiga enchoice)
_oView:AddField( 'VIEW_PAI' , _oStruPAI, 'Z10PAI'  )

//Adiciona no nosso View um controle do tipo FormGrid(antiga newgetdados)
_oView:AddGrid(  'VIEW_FIL' , _oStruFIL, 'Z10FIL'  )

// Criar "box" horizontal para receber algum elemento da view
_oView:CreateHorizontalBox( 'BOXPAI'  , 20)
_oView:CreateHorizontalBox( 'BOXFIL'  , 80)

// Relaciona o ID da View com o "box" para exibicao
_oView:SetOwnerView( 'VIEW_PAI' , 'BOXPAI'  )
_oView:SetOwnerView( 'VIEW_FIL' , 'BOXFIL'  )

// Liga apresentação dos titulos dos componentes
_oView:EnableTitleView( 'VIEW_PAI' )
_oView:EnableTitleView( 'VIEW_FIL' )

//fechamento da view
_oView:SetCloseOnOk({|_oModel| If(_oModel:GetOperation()=MODEL_OPERATION_UPDATE,.T.,.F.)})

Return _oView

/*
===============================================================================================================================
Programa----------: APON001A
Autor-------------: Xavier
Data da Criacao---: 20/05/2015
Descrição---------: Gatilho de preenchimento do tipo de ocorrencia.
Parametros--------: _cMatric = codigo da matricula do funcionario
Retorno-----------: _cTipo = tipo de ocorrencia
===============================================================================================================================
*/
User Function APON001A(_cMatric As Character, _dDataFim As Date)

Local _aArea		:= FWGetArea() As Array
Local _nPeriodo		:= SuperGetMV("IT_PONPERI",.T.,90) As Numeric
Local _nOcorr		:= SuperGetMV("IT_PONOCOR",.T.,3) As Numeric
Local _nNotif		:= SuperGetMV("IT_PONNOTI",.T.,2) As Numeric
Local _nAdver		:= SuperGetMV("IT_PONADVE",.T.,3) As Numeric
Local _nSusp		:= SuperGetMV("IT_PONSUSP",.T.,1) As Numeric
Local _cAlias		:= GetNextAlias() As Character
Local _cTipo		:= ' ' As Character//notificacao
Local _dDataIni     := _dDataFim - _nPeriodo As Date

//procura total de notificações no periodo
BeginSql alias _cAlias
	SELECT COUNT(1) TOT
	FROM %Table:Z10%
	WHERE D_E_L_E_T_ = ' '
	AND Z10_FILIAL = %Table:Z10%
	AND Z10_DATA BETWEEN %exp:_dDataIni% AND %exp:_dDataFim%
	AND Z10_MATRIC = %exp:cMatric%
EndSql

Do Case 
	Case (_cAlias)->TOT < _nOcorr
		_cTipo := 'O'  //Ocorrencia
	Case (_cAlias)->TOT < (_nOcorr+_nNotif)
		_cTipo := 'N'  //Notificação	
	Case (_cAlias)->TOT < (_nOcorr+_nNotif+_nAdver)
		_cTipo := 'A'  //advertencia
	Case (_cAlias)->TOT < (_nOcorr+_nNotif+_nAdver+_nSusp)
		_cTipo := 'S'  //Suspensão
EndCase

(_cAlias)->(DBCloseArea())
FWRestArea(_aArea)

Return _cTipo

/*
===============================================================================================================================
Programa----------: APON001B
Autor-------------: Xavier
Data da Criacao---: 20-05-2015
Descrição---------: Validação da data dentro do periodo do ponto em aberto. Executado no dicionario
Parametros--------: _dData = Data da ocorrencia
Retorno-----------: Logico
===============================================================================================================================
*/
User Function APON001B(_dData As Date)

Local _lRet		:= .T. As Logical
Local _cData1	:= AllTrim(SubStr(SuperGetMV("MV_PONMES",.T.,DToS(dDataBase)),1,8)) As Character

If Z10->(DBSeek(xFilial("Z10")+DToS(_dData)))
	_lRet := .F.
    Help(Nil,Nil,"APON00101",,"Data já existe na base de dados.",1,0, NIL, NIL, NIL, NIL, NIL, {"Utilize a opção de alterar ou informe outra data."})
EndIf

//analise do periodo do ponto
If _lRet .And. (DToS(_dData) < _cData1)
	_lRet := .F.
	Help(Nil,Nil,"APON00102",,"Data da ocorrência anterior ao período  de vigência do ponto eletrônico.",1,0, NIL, NIL, NIL, NIL, NIL, {"Informe uma data correta após o ínicio do período válido."})
EndIf

Return _lRet

/*
===============================================================================================================================
Programa----------: APON001C
Autor-------------: Xavier
Data da Criacao---: 20-05-2015
Descrição---------: Validação da data e matricula existente na tabela apontamento SP8. Executado do dicionario.
Parametros--------: _dData   = Data da ocorrencia
                    _cMatric = Matricula do funcionario
Retorno-----------: Logico
===============================================================================================================================
*/
User Function APON001C(_dData As Date,_cMatric As Character)

Local _lRet	:= .T. As Logical
Local _cData:= DToS(_dData) As Character
Local _aArea:= FWGetArea()

SP8->(DBSetOrder(3)) // P8_FILIAL+P8_MAT+DToS(P8_DATAAPO)+DToS(P8_DATA)+Str(P8_HORA,5,2) // MAT+DATAAPO+DATA+P8_HORA
SPG->(DBSetOrder(3)) // PG_FILIAL+PG_MAT+DToS(PG_DATAAPO)+DToS(PG_DATA)+Str(PG_HORA,5,2)

If ! SP8->(DBSeek(xFilial("SP8")+_cMatric+_cData)) .And. ! SPG->(DBSeek(xFilial("SPG")+_cMatric+_cData))
	_lRet := .F.
	Help(Nil,Nil,"APON00103",Nil,"Funcionario "+_cMatric+" não realizou apontamento nesse dia "+DToC(_dData),1,0, NIL, NIL, NIL, NIL, NIL, {"Analise o apontamento desse funcionário."})
EndIf

FWRestArea(_aArea)

Return _lRet

/*
===============================================================================================================================
Programa----------: APON001D
Autor-------------: Darcio
Data da Criacao---: 18-06-2015
Descrição---------: Funcao para exclusao do registro posicionado no browse.
Parametros--------: 
Retorno-----------: 
===============================================================================================================================
*/
User Function APON001D

Local _aArea	:= FWGetArea()
Local _aAreaZ10	:= Z10->(GetArea())
Local _cData1 	:= AllTrim(SubStr(SuperGetMV("MV_PONMES",.T.,DToS(dDataBase)),1,8))

If ( DToS(Z10->Z10_DATA) < _cData1  )
	Help(NIL, NIL, "APON00104", NIL, "Data da ocorrência anterior ao período  de vigência do ponto eletrônico.", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Data da ocorrência anterior ao período  de vigência do ponto eletrônico."})
	FWRestArea(_aAreaZ10)
	FWRestArea(_aArea)
	Return
EndIf

If Z10->Z10_TIPO == 'A'
	DBSelectArea("ZZL")
	ZZL->(DBSetOrder(3)) //ZZL_FILIAL + ZZL_CODUSU

	If ZZL->(DBSeek(xFilial("ZZL") + __cUserId))
		If ZZL->ZZL_EXCADV == "S"
			If FWAlertYesNo("Deseja realmente excluir o registro posicionado?","APON00105")
				//exclui fato relevante
				DBSelectArea("RAE")
				DBSetOrder(1) //RAE_FILIAL + RAE_MAT + DToS(RAE_DATA) + RAE_COD
				If DBSeek(Z10->Z10_FILIAL + Z10->Z10_MATRIC + DToS(Z10->Z10_DATA) + IIf(Z10->Z10_TIPO=='A','99','98'))   
					RAE->(RecLock("RAE", .F.))
					RAE->(DBDelete())
					RAE->(MSUnLock())
				EndIf
		
				//exclui ocorrência		
				Z10->(RecLock("Z10",.F.))
				Z10->(DBDelete())
				Z10->(MSUnLock())
			EndIf
		Else
	        Help(NIL, NIL, "APON00106", NIL, "Regra de processo da ITALAC. Não permite operação de exclusão de advertência.", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Informe ao gerente do Depto. de RH."})
		EndIf
	Else
		Help(NIL, NIL, "APON00107", NIL, "Regra de processo da ITALAC. Usuário não possui regra configurada.", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Informe ao gerente do Depto. de RH."})
	EndIf
Else
	If FWAlertYesNo("Deseja realmente excluir o registro posicionado?","APON00108")
		//exclui fato relevante
		DBSelectArea("RAE")
		RAE->(DBSetOrder(1)) //RAE_FILIAL + RAE_MAT + DToS(RAE_DATA) + RAE_COD

		If RAE->(DBSeek(Z10->Z10_FILIAL + Z10->Z10_MATRIC + DToS(Z10->Z10_DATA) + IIf(Z10->Z10_TIPO=='A','99','98')))
			RAE->(RecLock("RAE", .F.))
			RAE->(DBDelete())
			RAE->(MSUnLock())
		EndIf
		
		//exclui ocorrência
		Z10->(RecLock("Z10", .F.))
		Z10->(DBDelete())
		Z10->(MSUnLock())
	EndIf
EndIf

FWRestArea(_aAreaZ10)
FWRestArea(_aArea)

Return

/*
===============================================================================================================================
Programa----------: APON001Z
Autor-------------: Josué Danich
Data da Criacao---: 18-08-2015
Descrição---------: Funcao para atualizar fatos relevantes
Parametros--------: 
Retorno-----------: 
===============================================================================================================================
*/
User Function APON001Z(_oModel As Object,_ddata As Date)

Local _aArea	:= FWGetArea() As Array
Local _aAreaZ10	:= Z10->(GetArea()) As Array
Local _lRet 	:= .T. As Logical
Local _nOper 	:= _oModel:GetOperation() As Numeric
Local _cAlias	:= GetNextAlias() As Character
Local _nI 		:= 1 As Numeric
Local _ncont    := 1 As Numeric
Local _cdesc   	:= "" As Character
Local _cMat		:= '' As Character
//faz atualizações na tabela de fatos relevantes
//inclusão e alteração

If _lRet .And. (_noper == 3 .Or. _noper == 4)
	For _nI := 1 To Len(_oModel:aModelStruct[1][4][1][3]:aCols)
		_ctipo := U_APON001Y(_oModel:aModelStruct[1][4][1][3]:aCols[_nI][4])
	
		//verifica se já tem o registro para incluir ou alterar
		DBSelectArea("RAE")
		RAE->(DBSetOrder(1)) //RAE_FILIAL + RAE_MAT + DToS(RAE_DATA) + RAE_COD
		
		If DBSeek(xFilial("RAE") + AllTrim(_oModel:aModelStruct[1][4][1][3]:aCols[_nI][2]) + DToS(_ddata);
										 + IIf(_oModel:aModelStruct[1][4][1][3]:aCols[_nI][5]=='A','99','98'))   
			_cdesc := ""
			
			//monta descrição de todas as ocorrências do registro
			For _ncont := 1 To Len(_oModel:aModelStruct[1][4][1][3]:aCols)
				If _oModel:aModelStruct[1][4][1][3]:aCols[_nI][2] == _oModel:aModelStruct[1][4][1][3]:aCols[_ncont][2];
					.And. _oModel:aModelStruct[1][4][1][3]:aCols[_nI][5] == _oModel:aModelStruct[1][4][1][3]:aCols[_ncont][5]
					_ctipo := U_APON001Y(_oModel:aModelStruct[1][4][1][3]:aCols[_ncont][4])
					_cdesc += 	"Ocorrência de ponto - " + _ctipo + CHR(10) + CHR(13)
				EndIf
			Next _ncont
			
			//já existe, então só altera
			RAE->(RecLock("RAE", .F.))
			RAE->RAE_FILIAL	:= xFilial("RAE")
			RAE->RAE_MAT		:= _oModel:aModelStruct[1][4][1][3]:aCols[_nI][2]
			RAE->RAE_DATA		:= _ddata
			RAE->RAE_COD		:= IIf(_oModel:aModelStruct[1][4][1][3]:aCols[_nI][5]=='A','99','98')
			RAE->RAE_DESC		:=	_cdesc
			RAE->(MSUnLock())
		Else
			_cMat := AllTrim(_oModel:aModelStruct[1][4][1][3]:aCols[_nI][2])
			//novo registro
			//identifica próxima sequência do RAE
			BeginSql alias _cAlias
				SELECT MAX(RAE_SEQ) MAXIMO
				FROM %Table:RAE%
				WHERE D_E_L_E_T_ = ' '
				AND RAE_FILIAL = %xFilial:RAE%
				AND RAE_MAT = %exp:_cMat%
			EndSql
	
			RAE->(RecLock("RAE", .T.))
			RAE->RAE_FILIAL	:= xFilial("RAE")
			RAE->RAE_MAT	:= _oModel:aModelStruct[1][4][1][3]:aCols[_nI][2]
			RAE->RAE_SEQ	:= StrZero(Val((_cAlias)->MAXIMO)+1,2)
			RAE->RAE_DATA	:= _ddata
			RAE->RAE_COD	:= IIf(_oModel:aModelStruct[1][4][1][3]:aCols[_nI][5]=='A','99','98')
			RAE->RAE_DESC	:=	"Ocorrência de ponto - " + _ctipo
			RAE->(MSUnLock())

			(_cAlias)->(DBCloseArea())
		EndIf	
	Next _nI
EndIf

FWRestArea(_aAreaZ10)
FWRestArea(_aArea)

Return _lRet

/*
===============================================================================================================================
Programa----------: APON001R
Autor-------------: Josué Danich
Data da Criacao---: 18-08-2015
Descrição---------: Funcao para pré validar alteracao do registro posicionado no browse.
Parametros--------: 
Retorno-----------: 
===============================================================================================================================
*/
User Function APON001R(_oModel As Object)

Local _aArea	:= FWGetArea() As Array
Local _aAreaZ10	:= Z10->(GetArea()) As Array
Local _cData1 	:= AllTrim(SubStr(SuperGetMV("MV_PONMES",.T.,DToS(dDataBase)),1,8)) As Character
Local _lRet 	:= .T. As Logical
Local _nOper 	:= _oModel:GetOperation() As Numeric

//verifica se a ocorrência está em período do ponto já fechado
If (DToS(Z10->Z10_DATA) < _cData1 ) .And. _noper == 4
	_lRet := .F.
	Help(NIL, NIL, "APON00109", NIL, "Data da ocorrência anterior ao período de vigência do ponto eletrônico.", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Informe uma data correta após o ínicio do período válido."})
EndIf

//verifica se usuário tem permissão
If Z10->Z10_TIPO == 'A' .And. _lRet .And. _noper == 4
	DBSelectArea("ZZL")
	ZZL->(DBSetOrder(3)) //ZZL_FILIAL + ZZL_CODUSU
	
	If ZZL->(DBSeek(xFilial("ZZL") + __cUserId))
		If !(ZZL->ZZL_EXCADV == "S")
			Help(NIL, NIL, "APON00110", NIL, "Regra de processo da ITALAC. Não permite operação de alteração de advertência.", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Informe ao gerente do Depto. de RH."})
			_lRet := .F.
		EndIf
	Else
		Help(NIL, NIL, "APON00111", NIL, "Regra de processo da ITALAC. Usuário não possui regra configurada.", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Informe ao gerente do Depto. de RH."})
		_lRet := .F.
	EndIf
EndIf

FWRestArea(_aAreaZ10)
FWRestArea(_aArea)

Return _lRet

/*
===============================================================================================================================
Programa----------: APON001W
Autor-------------: Josué Danich
Data da Criacao---: 18-08-2015
Descrição---------: Funcao para popular fatos relevantes
Parametros--------: 
Retorno-----------: 
===============================================================================================================================
*/
User Function APON001W

Local _cAlias	:= GetNextAlias() As Character
Local _cAlias2	:= GetNextAlias() As Character

BeginSql alias _cAlias2
	SELECT Z10_FILIAL, Z10_DATA, Z10_MATRIC, Z10_TIPO, Z10_MOTIVO, Z10_IMPRES, Z10_ORIGEM
	FROM %Table:Z10%
	WHERE D_E_L_E_T_ = ' '
EndSql

DBSelectArea("RAE")
RAE->(DBSetOrder(1)) //RAE_FILIAL + RAE_MAT + DToS(RAE_DATA) + RAE_COD

While !(_cAlias2)->(Eof())
	//faz atualizações na tabela de fatos relevantes
	//identificação do tipo de ocorrência
	_cTipo := APON001Y((_cAlias2)->Z10_ORIGEM)
	//identifica próxima sequência do RAE
	BeginSql alias _cAlias		
		SELECT MAX(RAE_SEQ) MAXIMO
		FROM %Table:RAE%
		WHERE D_E_L_E_T_ = ' '
		AND RAE_FILIAL = %exp:AllTrim((_cAlias2)->Z10_FILIAL)%
		AND RAE_MAT = %exp:AllTrim((_cAlias2)->Z10_MATRIC)%
	EndSql

	//só inclui se não tiver registro ainda
	If !RAE->(DBSeek((_cAlias2)->Z10_FILIAL + AllTrim((_cAlias2)->Z10_MATRIC) + (_cAlias2)->Z10_DATA + IIf((_cAlias2)->Z10_TIPO=='A','99','98')))
		RAE->(RecLock("RAE", .T.))
		RAE->RAE_FILIAL	:= (_cAlias2)->Z10_FILIAL
		RAE->RAE_MAT		:= (_cAlias2)->Z10_MATRIC
		RAE->RAE_SEQ		:= StrZero(Val((_cAlias)->MAXIMO)+1,2)
		RAE->RAE_DATA		:= SToD((_cAlias2)->Z10_DATA)
		RAE->RAE_COD		:= IIf((_cAlias2)->Z10_TIPO=='A','99','98')
		RAE->RAE_DESC		:=	"Ocorrência de ponto - " + _ctipo
		RAE->(MSUnLock())
	EndIf
	
	(_cAlias)->(DBCloseArea())
	(_cAlias2)->(DBSkip())
EndDo
(_cAlias2)->(DBCloseArea())

Return _lRet

/*
===============================================================================================================================
Programa----------: APON001Y
Autor-------------: Josué Danich Prestes
Data da Criacao---: 26/08/2015
Descrição---------: Retorna descrição do tipo de ocorrência
Parametros--------: _ctipo - Código da ocorrência
Retorno-----------: _cret - Descrição da ocorrência
===============================================================================================================================
*/
User Function APON001Y(_cTipo As Character)

Local _cret 	:= "Outros" As Character
Default _ctipo	:= 'H' 

//identificação do tipo de ocorrência
If _ctipo == 'H'
	_cret := "Mais que 2 horas extras diária"
ElseIf _ctipo == 'E'
	_cret := "Intervalo interjornada menor que 11 horas"
ElseIf _ctipo == 'A'
	_cret := "Intervalo intrajornada menor que 1 hora"
ElseIf _ctipo == 'D'
	_cret := "Marcação em dia de DSR"
ElseIf _ctipo == 'O'
	_cret := "Ausência de marcação"
ElseIf _ctipo == 'S'
	_cret := "Suspenção"
EndIf

If _ctipo == 'HA'
	_cret := "Hora Extra"
ElseIf _ctipo == 'EA'
	_cret := "Interjornada"
ElseIf _ctipo == 'AA'
	_cret := "Intrajornada"
ElseIf _ctipo == 'DA'
	_cret := "DSR"
ElseIf _ctipo == 'OA'
	_cret := "Marcação"
EndIf

Return _cret

/*
===============================================================================================================================
Programa----------: APON001N
Autor-------------: Josué Danich Prestes
Data da Criacao---: 26-08-2015
Descrição---------: Validação da alteração de tipo de ocorrência
Parametros--------: 
Retorno-----------: Logico
===============================================================================================================================
*/
User Function APON001N(_dData As Date)

Local _lRet	:= .T. As Logical
Local _aArea:= FWGetArea() As Array
Local _cMat	:= aCols[n][aScan(aHeader,{|x|AllTrim(x[2])=="Z10_MATRIC"})] As Character
Local _ctipo:= U_APON001A( _cMat, _dData ) As Character

If _ctipo == "A" .And. M->Z10_TIPO != 'A'
	Help(NIL, NIL, "APON00112", NIL, "Advertência obrigatória!", 1, 0, NIL, NIL, NIL, NIL, NIL, {""})
	_lRet := .F. 
EndIf

FWRestArea(_aArea)

Return _lRet

/*
===============================================================================================================================
Programa----------: APON001H
Autor-------------: Julio de Paula Paz
Data da Criacao---: 30/05/2019
Descrição---------: Valida a digitação da hora.
Parametros--------: _cHora = Hora a ser validada.
Retorno-----------: .T. = Hora informada correta.
                    .F. = Hora informada inválida.
===============================================================================================================================
*/
User Function APON001H(_cHora As Character)

Local _lRet 		:= .T. As Logical
Local _nHH			:= 0 As Numeric
Local _nMM			:= 0 As Numeric
Local _nI			:= 0 As Numeric
Local _oModel		:= FWModelActive() As Object
Local _oModelCab	:= _oModel:GetModel( 'Z10PAI' ) As Object
Local _oModelDet	:= _oModel:GetModel( 'Z10FIL' ) As Object
Local _dDataOcorr	:= SToD('//') As Date
Local _cMatricula  	:= '' As Character
Local _cRetorno  	:= '' As Character
Local _cOrigem  	:= '' As Character
Local _nNrMsg 		:= 1 As Numeric

Begin Sequence                    //12345678
	If Empty(_cHora) .Or. _cHora = "00:00"
		Break
	EndIf

	_nHH := Val(AllTrim(SubStr(_cHora,1,2)))
	_nMM := Val(AllTrim(SubStr(_cHora,4,2)))

	// Valida a hora.
	If _nHH > 23
		_lRet := .F.
	EndIf

	// Valida os minutos.
	If _nHH > 59
		_lRet := .F.
	EndIf

	// Valida se a hora digitada é diferente dos apontamentos realizados.
	If _lRet
		_dDataOcorr := _oModelCab:GetValue('Z10_DATA')
		_cMatricula := _oModelDet:GetValue('Z10_MATRIC')
		_cOrigem    := _oModelDet:GetValue('Z10_ORIGEM')
		_cRetorno   := "A" 

		_aHorarios  := {}
		MsgRun("Lendo apontamentos da data "+DToC(_dDataOcorr)+" da Matricula: "+_cMatricula, "Aguarde...",;
				{|| _aHorarios := U_APON001J(_dDataOcorr,_cMatricula,_cRetorno,_cOrigem)  } )
		
		_lRet := .F.
		For _nI := 1 To Len(_aHorarios)
			If AllTrim(_cHora) == AllTrim(_aHorarios[_nI,1])
				_lRet := .T.
			EndIf
		Next _nI
		
		If ! _lRet
			_nNrMsg := 2
		EndIf
	EndIf

	If ! _lRet
		If _nNrMsg == 1 // Primeiro tipo de mensagem de validação.
			Help(NIL, NIL, "APON00113", NIL, "A hora informada está inválida: (" + _cHora + ").", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Deve-se informar os valores de 0 a 23 para a hora, de 0 a 59 para os minutos."})
		Else // Segundo tipo de mensagem de validação.
			Help(NIL, NIL, "APON00114", NIL, "A hora informada está inválida: (" + _cHora + "). ", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Não existe a hora informada nos apontamentos realizados no dia: " + DToC(_dDataOcorr) + "."})
		EndIf
	EndIf

End Sequence

Return _lRet

/*
===============================================================================================================================
Programa--------: LstPto
Autor-----------: Julio de Paula Paz
Data da Criacao-: 30/05/2019 
Descrição-------: Consulta específica que retorna os horários das batidas de ponto.
Parametros------: _cCampo = Campo que chamou a consulta específica.
Retorno---------: _lRet - Compatibilidade com o F3
===============================================================================================================================
*/
User Function LstPto(_cCampo As Character)

Local _aHorarios	:= {} As Array
Local _nI			:= 0 As Numeric
Local _cHorario		:= '' As Character
Local _cListaHoras 	:= '' As Character
Local _oModel		:= FWModelActive() As Object
Local _oModelCab	:= _oModel:GetModel( 'Z10PAI' ) As Object
Local _oModelDet	:= _oModel:GetModel( 'Z10FIL' ) As Object
Local _dDataOcorr  	:= SToD('//') As Date
Local _cMatricula	:= '' As Character
Local _cRetorno		:= '' As Character
Local _cOrigem		:= '' As Character

Private nTam       := 5 As Numeric
Private nMaxSelect := 1 As Numeric
Private aDescr     := {} As Array
Private MvRet      := AllTrim(ReadVar()) As Character
Private MvPar      := '' As Character
Private cTitulo    := '' As Character
Private MvParDef   := '' As Character

Begin Sequence
	If AllTrim(_cCampo) == "Z10_HORAIN"
		MvRet := "M->Z10_HORAIN"
	ElseIf AllTrim(_cCampo) == "Z10_HORAFI"	
		MvRet := "M->Z10_HORAFI"
	EndIf

	_dDataOcorr := _oModelCab:GetValue('Z10_DATA')
	_cMatricula := _oModelDet:GetValue('Z10_MATRIC')
	_cOrigem    := _oModelDet:GetValue('Z10_ORIGEM')
	_cRetorno   := "A" 

	_aHorarios  := {}
	MsgRun("Lendo apontamentos da data "+DToC(_dDataOcorr)+" da Matricula: "+_cMatricula, "Aguarde...",;
			{|| _aHorarios := U_APON001J(_dDataOcorr,_cMatricula,_cRetorno,_cOrigem)  } )

	_cListaHoras := ""

	For _nI := 1 To Len(_aHorarios)
		_cHorario := _aHorarios[_nI,1]
		If Len(AllTrim(_cHorario)) < 5
			_cHorario := Space(5) 
		EndIf
				
		_cListaHoras += _cHorario + "/"
		MvParDef += _cHorario
		aAdd( aDescr , "Data_" + _aHorarios[_nI,2])
	Next _nI

	//====================================================================
	//Trativa abaixo para no caso de uma alteracao do campo trazer todos
	//os dados que foram selecionados anteriormente.                    
	//====================================================================
	If Len(AllTrim(&(MvRet))) == 0                              
		MvPar:= PadR(AllTrim(StrTran(&MvRet,";","")),Len(aDescr))
		&(MvRet):= PadR(AllTrim(StrTran(&(MvRet),";","")),Len(aDescr))
	Else
		MvPar:= AllTrim(StrTran(&(MvRet),";","/"))
	EndIf

	//=============================================================
	//Somente altera o conteudo caso o usuario clique no botao ok
	//=============================================================
	If f_Opcoes(@MvPar,cTitulo,aDescr,MvParDef,12,49,.F.,nTam,nMaxSelect)        
		//Tratamento para separar retorno com barra ";"
		&(MvRet) := ""
		For _nI:=1 to Len(MvPar) step nTam
			If !(SubStr(MvPar,_nI,1) $ " |*")
				&(MvRet)  += SubStr(MvPar,_nI,nTam) + ";"
			EndIf
		Next _nI

		//Trata para tirar o ultimo caracter
		&(MvRet)   := SubStr(&(MvRet),1,Len(&(MvRet))-1) 
	EndIf     
End Sequence

Return .T.

/*
===============================================================================================================================
Programa----------: APON001I(_dDataOcorr)
Autor-------------: Julio de Paula Paz
Data da Criacao---: 20/05/2019
Descrição---------: Retorna Retorna a Data inicia e final do perído de apontamento.
Parametros--------: _dDataOcorr := Data da Ocorrencia 
Retorno-----------: aRet
===============================================================================================================================
*/
User Function APON001I(_dDataOcorr As Date)

Local _aRet 	:= {Ctod("//"),Ctod("//")} As Array
Local _cDtIni	:= '' As Character
Local _cDtFin	:= '' As Character
Local _lLerSPG 	:= .F. As Logical
Local _cAlias	:= GetNextAlias() As Character

Begin Sequence
   _cDtIni := DToS(_dDataOcorr)
   _cDtFin := DToS(_dDataOcorr)

   //===============================================================
   // Pesquisa datas na tabela SP8
   //===============================================================
	BeginSql alias _cAlias
		SELECT DISTINCT P8_FILIAL,P8_PAPONTA FROM %Table:SP8% SP8
		WHERE SP8.D_E_L_E_T_ = ' '
		AND P8_FILIAL = %exp:cFilAnt% 
		AND P8_DATAAPO >= %exp:_dDataOcorr% 
		AND P8_DATAAPO <= %exp:_dDataOcorr% 
	EndSql
   
	If !(_cAlias)->(Eof())
		_cDtIni := SubStr((_cAlias)->P8_PAPONTA,1,8) // 2015102620151125
		_cDtFin := SubStr((_cAlias)->P8_PAPONTA,9,8)
	Else
		_lLerSPG := .T.
	EndIf

	(_cAlias)->(DBCloseArea())

	//===============================================================
	// Pesquisa datas na tabela SPG
	//===============================================================
	_cAlias	:= GetNextAlias()
	BeginSql alias _cAlias
		SELECT DISTINCT PG_FILIAL,PG_PAPONTA 
		FROM %Table:SPG% SPG
		WHERE SPG.D_E_L_E_T_ = ' ' 
		AND PG_FILIAL = %exp:cFilAnt%
		AND PG_DATAAPO >= %exp:_dDataOcorr% 
		AND PG_DATAAPO <= %exp:_dDataOcorr%
	EndSql
   
	If !(_cAlias)->(Eof())
		_cDtIni := SubStr((_cAlias)->PG_PAPONTA,1,8) // 2015102620151125
		_cDtFin := SubStr((_cAlias)->PG_PAPONTA,9,8)
	EndIf
   
	(_cAlias)->(DBCloseArea())
	_aRet := {SToD(_cDtIni), SToD(_cDtFin)}
End Sequence

Return _aRet

/*
===============================================================================================================================
Programa----------: APON001J(_dDataOcorr,_cMatricula,_cRetorno)
Autor-------------: Julio de Paula Paz
Data da Criacao---: 20/05/2019
Descrição---------: Retorna Retorna o horário inicial e final do perído de apontamento, ou os horários de apontamentos.
Parametros--------: _dDataOcorr = Data da Ocorrencia. 
                    _cMatricula = Matrícula do funcionário.
					_cRetorno   = A = Apontamentos
					            = H = Horario inicial e final do apontamento

					_cOrigem    = "H" = HE - Horas Extras
                                  "D" = DSR 
                                  "A" = Intrajornada
                                  "E" = Interjornada
Retorno-----------: aRet = Array contendo os horários de retorno podendo ser:  
                       H = {"horario inicia","horario final"} 
					   A = {"apontamento1", "apontamento2","apontamento3","apontamento4","apontamento5",...}
===============================================================================================================================
*/
User Function APON001J(_dDataOcorr As Date,_cMatricula As Character,_cRetorno As Character,_cOrigem As Character)

Local _aRet 		:= {} As Array
Local _cHoraApon	:= '' As Character
Local _nPosIni		:= 0 As Numeric
Local _nPosFim		:= 0 As Numeric
Local _aDadosMkDia 	:= {} As Array
Local _nI			:= 0 As Numeric
Local nX			:= 0 As Numeric
Private dPerIni		:= SToD('//') As Date
Private dPerFim		:= SToD('//') As Date
Private dIniPonMes	:= SToD('//') As Date
Private dFimPonMes	:= SToD('//') As Date
Private aTabPadrao	:= {} As Array
Private lSP9Exclu	:= .F. AS Logical
Private aId			:= {} As array
Private aFuncFunc  := {Space(1), Space(1), Space(1), Space(1), Space(1), Space(1)} As Array

If Empty(_cMatricula) .Or. Empty(_dDataOcorr) .Or. Empty(_cOrigem)
	Return {"","",""}
EndIf

Begin Sequence
	SRA->(DBSetOrder(1) )

	//Posiciona no funcionário atual
	If !SRA->(DBSeek(xFilial("SRA") + _cMatricula)) 
		Return  {"","",""}
	EndIf
	//====================================================================
	// Atualiza a Filial Corrente           						  
	//====================================================================
	cLastFil := SRA->RA_FILIAL
	cTurno 	:= SRA->RA_TNOTRAB
	cSeq	 	:= SRA->RA_SEQTURN  
	lMvAbosEve  := APON001MV("MV_ABOSEVE", cLastFil)
	lMvSubAbAp  := APON001MV("MV_SUBABAP", cLastFil)
		
	//====================================================================
	// Carrega periodo de Apontamento Aberto						  
	//====================================================================
	If !CheckPonMes( @dPerIni , @dPerFim , .F. , .T. , .F. , cLastFil )
		Break
	EndIf

	//====================================================================
	// Obtem datas do Periodo em Aberto							  
	//====================================================================
	GetPonMesDat( @dIniPonMes , @dFimPonMes , cLastFil )
		
	//====================================================================
	// Atualiza o Array de Informa‡”es sobre a Empresa.			  
	//====================================================================
	aInfo := {}
	fInfo( @aInfo , cLastFil )

	//====================================================================
	// Carrega as Tabelas de Horario Padrao						  
	//====================================================================
	If Empty( aTabPadrao ) 
		aTabPadrao := {}
		fTabTurno( @aTabPadrao , cLastFil )
	EndIf

	//====================================================================
	// Carrega TODOS os Eventos da Filial						  
	//====================================================================
	If ( Empty( aId ) .Or. ( lSP9Exclu ) )
		aId := {}
		CarId( fFilFunc("SP9") , @aId , "*" )
	EndIf

	//====================================================================
	// Retorna Periodos de Apontamentos Selecionados				  
	//====================================================================
	dPerIni := _dDataOcorr // SToD(_dDataOcorr)
	dPerFim := _dDataOcorr // SToD(_dDataOcorr)

	_aDtCalend := U_APON001I(_dDataOcorr)    

	dIniCale := _aDtCalend[1]
	dFimCale := _aDtCalend[2]
		
	aPeriodos := Monta_per(dPerIni, dPerFim, cLastFil , SRA->RA_MAT , dIniCale , dFimCale)

	//====================================================================
	// Corre Todos os Periodos 									  
	//====================================================================
	naPeriodos := Len( aPeriodos )
	For nX := 1 To naPeriodos
		//====================================================================
		// Reinicializa as Datas Inicial e Final a cada Periodo Lido.	  
		// Os Valores de dPerIni e dPerFim foram preservados nas   varia
		// veis: dCaleIni e dCaleFim.									  
		//====================================================================
		dPerIni		:= aPeriodos[ nX , 1 ]
		dPerFim		:= aPeriodos[ nX , 2 ] 

		//====================================================================
		// Obtem as Datas para Recuperacao das Marcacoes				  
		//====================================================================
		dMarcIni	:= aPeriodos[ nX , 3 ]
		dMarcFim	:= aPeriodos[ nX , 4 ]

		//====================================================================
		// Verifica se Impressao eh de Acumulado						  
		//====================================================================
		lImpAcum := ( dPerFim < dIniPonMes )
			
		//====================================================================
		// Retorna Turno/Sequencia das Marca‡”es Acumuladas			 
		//====================================================================
		If ( lImpAcum )
			If SPF->( DBSeek( SRA->( RA_FILIAL + RA_MAT ) + DToS( dPerIni) ) ) .And. !Empty(SPF->PF_SEQUEPA)
				cTurno	:= SPF->PF_TURNOPA
				cSeq	:= SPF->PF_SEQUEPA
			Else
				//====================================================================
				// Tenta Achar a Sequencia Inicial utilizando RetSeq()
				//====================================================================
				If !RetSeq(cSeq,@cTurno,dPerIni,dPerFim,dDataBase,aTabPadrao,@cSeq) .Or. Empty( cSeq )
					//====================================================================
					// Tenta Achar a Sequencia Inicial utilizando fQualSeq()		  
					//====================================================================
					cSeq := fQualSeq( NIL , aTabPadrao , dPerIni , @cTurno )
				EndIf
			EndIf
			If ( Empty(cTurno) )
				SPF->( DBSeek( SRA->( RA_FILIAL + RA_MAT ) ) )
				While SPF->(!Eof()) .AND.;
					( SRA->RA_FILIAL + SRA->RA_MAT == SPF->PF_FILIAL + SPF->PF_MAT )
					If ( SPF->PF_DATA >= dPerIni .And. SPF->PF_DATA <= dPerFim )						
						cTurno	:= SPF->PF_TURNOPA
						cSeq	    := SPF->PF_SEQUEPA
						Exit
					Else
						SPF->(DBSkip())
					EndIf
				EndDo
			EndIf
		Else
			//====================================================================
			// Considera a Sequencia e Turno do Cadastro            		  
			//====================================================================
			cTurno := SRA->RA_TNOTRAB
			cSeq	 := SRA->RA_SEQTURN  
		EndIf
		
		//====================================================================
		// Obtem Codigo e Descricao da Funcao do Trabalhador na Epoca   
		//====================================================================
		fBuscaCC(dMarcFim, @aFuncFunc[1], @aFuncFunc[2], Nil, .F. , .T.  ) 
		aFuncFunc[2]:= SubStr(aFuncFunc[2], 1, 25)
		fBuscaFunc(dMarcFim, @aFuncFunc[3], @aFuncFunc[4],@aFuncFunc[6],.T. )

		If Empty(aFuncFunc[6])
			aFuncFunc[6] := DescCateg(SRA->RA_CATFUNC , 25)
		EndIf	

		//====================================================================
		// Carrega Arrays com as Marca‡”es do Periodo (aMarcacoes), com³
		// o Calendario de Marca‡”es do Periodo (aTabCalend) e com    as³	
		// Trocas de Turno do Funcionario (aTurnos)					  ³	
		//====================================================================
		( aMarcacoes := {} , aTabCalend := {} , aTurnos := {} )
			
		//====================================================================
		// Importante: 												  
		// O periodo fornecido abaixo para recuperar as marcacoes   cor
		// respondente ao periodo de apontamentoo Calendario de 	 Marca	
		// ‡”es do Periodo ( aTabCalend ) e com  as Trocas de Turno  do	
		// Funcionario ( aTurnos ) integral afim de criar o  calendario	
		// com as ordens correspondentes as gravadas nas marcacoes.	  	
		// Pesquisa as marcações na tabela SP8.
		//====================================================================
		If !GetMarcacoes(@aMarcacoes		,;	//Marcacoes dos Funcionarios
			@aTabCalend					,;	//Calendario de Marcacoes
			@aTabPadrao					,;	//Tabela Padrao
			@aTurnos					    ,;	//Turnos de Trabalho
			dPerIni 					    ,;	//Periodo Inicial
			dPerFim	    			    ,;	//Periodo Final    
			SRA->RA_FILIAL				,;	//Filial
			SRA->RA_MAT					,;	//Matricula
			cTurno						,;	//Turno
			cSeq						    ,;	//Sequencia de Turno
			SRA->RA_CC					,;	//Centro de Custo
			"SP8"                    	    ,;	//Alias para Carga das Marcacoes
			NIL							,;	//Se carrega Recno em aMarcacoes
			.T.							,;	//Se considera Apenas Ordenadas
			.T.    						,;	//Se Verifica as Folgas Automaticas
			.F.    			 			 ;	//Se Grava Evento de Folga Automatica Periodo Anterior
			)
		EndIf

		//======================================================================
		// Se não For encontrado marcações na tabela SP8 pesquisar marcações na
		// tabela SPG.
		//======================================================================
		If Len(aMarcacoes) == 0
			If !GetMarcacoes(@aMarcacoes		,;	//Marcacoes dos Funcionarios
				@aTabCalend					,;	//Calendario de Marcacoes
				@aTabPadrao					,;	//Tabela Padrao
				@aTurnos					    ,;	//Turnos de Trabalho
				dPerIni 					    ,;	//Periodo Inicial
				dPerFim	    			    ,;	//Periodo Final    
				SRA->RA_FILIAL				    ,;	//Filial
				SRA->RA_MAT					,;	//Matricula
				cTurno						    ,;	//Turno
				cSeq						    ,;	//Sequencia de Turno
				SRA->RA_CC					    ,;	//Centro de Custo
				"SPG"                    	    ,;	//Alias para Carga das Marcacoes
				NIL							,;	//Se carrega Recno em aMarcacoes
				.T.							,;	//Se considera Apenas Ordenadas
				.T.    						,;	//Se Verifica as Folgas Automaticas
				.F.    			 			 ;	//Se Grava Evento de Folga Automatica Periodo Anterior
				)
			EndIf
		EndIf

		_aRet := {}

		_cHoraIni := "00:00"
		_cHoraFin := "00:00"
		_cTempoD  := "00:00"

		_nJ := 0 
		
		//===============================================================
		// Neste trecho, calcula-se o intervalo de almoço, dentre as 
		// diversas marcações de horários do funcionário.
		//===============================================================
		_aDadosMkDia := {}
		
		For _nI := 1 To Len(aMarcacoes)   
			If (DToS(aMarcacoes[_nI,25]) == DToS(_dDataOcorr)) .Or. ;  
				((DToS(aMarcacoes[_nI,25]) == DToS(_dDataOcorr - 1) .And. DToS(aMarcacoes[_nI,1]) == DToS(aMarcacoes[_nI,25])) .And. (AllTrim(_cOrigem) == "E" .Or. _cRetorno == "A"))
				_nJ += 1
				aAdd(_aDadosMkDia, aClone(aMarcacoes[_nI]))
			EndIf
			If DToS(aMarcacoes[_nI,25]) > DToS(_dDataOcorr) .And. (AllTrim(_cOrigem) == "E" .Or. _cRetorno == "A") // Interjornada 
				_nJ += 1
				aAdd(_aDadosMkDia, aClone(aMarcacoes[_nI]))
				Exit
			EndIf
		Next _nI

		If _nJ == 1
			_nPosIni := 1 
			_nPosFim := 1 
		ElseIf _nJ == 2
			_nPosIni := 1 
			_nPosFim := 2 
		ElseIf _nJ == 3
			_nPosIni := 2 
			_nPosFim := 3 			
		ElseIf _nJ == 4
			_nPosIni := 2 
			_nPosFim := 3 
		ElseIf _nJ == 6
			_nPosIni := 3 
			_nPosFim := 4 
		ElseIf _nJ == 8
			If AllTrim(_cOrigem) == "A"  // Intrajornada
				_nPosIni := 6 
				_nPosFim := 7 
			Else
				_nPosIni := 4 
				_nPosFim := 5 
			EndIf
		ElseIf _nJ == 10
			_nPosIni := 5 
			_nPosFim := 6 
		ElseIf _nJ == 12
			_nPosIni := 6 
			_nPosFim := 7 
		Else 
			_nPosIni := Int(Len(_aDadosMkDia) / 2) 
			_nPosFim := _nPosIni + 1
		EndIf
		
		If _cRetorno   == "H" // Horario inicial e final do apontamento
			If AllTrim(_cOrigem) == "H" // HE - Horas Extras
				_cHoraIni := StrZero(_aDadosMkDia[1,2],5,2)
				_cHoraFin := StrZero(_aDadosMkDia[_nJ,2],5,2)
			ElseIf AllTrim(_cOrigem) == "D" // DSR 
				_cHoraIni := StrZero(_aDadosMkDia[1,2],5,2)
				_cHoraFin := StrZero(_aDadosMkDia[_nJ,2],5,2)
			ElseIf AllTrim(_cOrigem) == "A"  // Intrajornada
				_cHoraIni := StrZero(_aDadosMkDia[_nPosIni,2],5,2)
				_cHoraFin := StrZero(_aDadosMkDia[_nPosFim,2],5,2)
			ElseIf AllTrim(_cOrigem) == "E"  // Interjornada
				_cHoraIni := StrZero(_aDadosMkDia[_nJ-1,2],5,2)//StrZero(_aDadosMkDia[_nPosIni,2],5,2)//
				_cHoraFin := StrZero(_aDadosMkDia[_nJ  ,2],5,2)//StrZero(_aDadosMkDia[_nPosFim,2],5,2)//
			EndIf
		Else // "A" = Apontamentos
			For _nI := 1 To Len(_aDadosMkDia)
				_cHoraApon := StrZero(_aDadosMkDia[_nI,2],5,2)
				_cHoraApon := StrTran(_cHoraApon,".",":")
				aAdd(_aRet,{_cHoraApon, DToC(_aDadosMkDia[_nI,1])})
			Next 
			Break
		EndIf	

		If _cRetorno == "H" // Horario inicial e final do apontamento    
			If _cHoraIni <> "00:00"
				_cHoraIni := StrTran(_cHoraIni,".",":")
				_cHoraIni := _cHoraIni 
			EndIf
			If _cHoraFin <> "00:00"
				_cHoraFin := StrTran(_cHoraFin,".",":")
				_cHoraFin := _cHoraFin 
			EndIf   
			_cHoraIni := _cHoraIni + ":00"
			_cHoraFin := _cHoraFin + ":00"
			If AllTrim(_cOrigem) == "H" // HE - Horas Extras
				_cTempoD  := fGetApo(_dDataOcorr,_dDataOcorr)
			Else
				_cTempoD  := ELAPTIME(_cHoraIni,_cHoraFin) 
			EndIf
		
			_cHoraIni := SubStr(_cHoraIni,1,5) 
			_cHoraFin := SubStr(_cHoraFin,1,5) 
			_cTempoD  := SubStr(_cTempoD ,1,5) 
			_aRet := {_cHoraIni, _cHoraFin, _cTempoD}
		EndIf
	Next nX

End Sequence

If Empty(_aRet)
   _aRet := {"","",""}
EndIf

Return _aRet

/*
===============================================================================================================================
Programa----------: APON001MV
Autor-------------: Julio de Paula Paz
Data da Criacao---: 14/12/2018
Descrição---------: Função criada para retornar parêmentros, de forma que possa ser utilizados dentro loopings e ao mesmo 
                    tempo, seguir os padrões de desenvolvimento do no bo servidor lobo guará.
Parametros--------: _cParam = Parametro a ser lido
                    _cVarFil = filial passada para a função.
Retorno-----------: _cRet = conteúdo do parâmetro obtido pela função.
===============================================================================================================================
*/
Static Function APON001MV(_cParam As Character,_cVarFil As Character)

Local _cRet := "" As Character

Begin Sequence
	//====================================================================
	// Alimenta as variaveis com o conteudo dos MV_'S correspondetes³
	//====================================================================
	If _cParam == "MV_ABOSEVE"
		_cRet	:= ( Upper(AllTrim(SuperGetMv("MV_ABOSEVE",NIL,"N",_cVarFil))) == "S" )	//--Verifica se Deduz as horas abonadas das horas do evento Sem a necessidade de informa o Codigo do Evento no motivo de abono que abona horas
	ElseIf _cParam == "MV_SUBABAP"
		_cRet	:= ( Upper(AllTrim(SuperGetMv("MV_SUBABAP",NIL,"N",_cVarFil))) == "S" )	//--Verifica se Quando Abono nao Abonar Horas e Possuir codigo de Evento, se devera Gera-lo em outro evento e abater suas horas das Horas Calculadas
	EndIf

End Sequence

Return _cRet

/*
===============================================================================================================================
Programa----------: CarId
Autor-------------: Mauricio MR  
Data da Criacao---: 24/05/2002
Descrição---------: Retorna Relacao de Eventos da Filial	
Parametros--------: cFil       --> Codigo da Filial desejada	
                    aId    	   --> Array com a Relacao	                      
                    cAutoriza  --> "*" Horas Autorizadas/Nao Autorizadas        
                                   "A" Horas Autorizadas                       
                                   "N" Horas Nao Autorizadas
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function CarId(cFil As Character,aId As Array,cAutoriza As Character)

Local nPos	:= 0.00 As Numeric

//-- Preenche o Array aCodAut com os Eventos (Menos DSR Mes Ant.)
SP9->( DBSeek( cFil , .T. ) )
While SP9->( !Eof() .And. cFil == P9_FILIAL ) 
	If ( ( Right(SP9->P9_IDPON,1) == cAutoriza ) .Or. ( cAutoriza == "*" ) )
		aAdd( aId , Array( 04 ) )
		nPos := Len( aId )
		aId[ nPos , 01 ] := SP9->P9_CODIGO	//-- Codigo do Evento 
		aId[ nPos , 02 ] := SP9->P9_IDPON 	//-- Identificador do Ponto 
		aId[ nPos , 03 ] := SP9->P9_CODFOL	//-- Codigo do da Verba Folha
		aId[ nPos , 04 ] := SP9->P9_BHORAS	//-- Evento para B.Horas
	EndIf
	SP9->( DBSkip() )
EndDo

Return

/*
===============================================================================================================================
Programa----------: Monta_Per
Autor-------------: Totvs 
Data da Criacao---: 10/12/2001
Descrição---------: Retorna períodos de apontamentos. 
Parametros--------: dDataIni 
                    dDataFim 
                    cFil 
                    cMat 
                    dIniAtu 
                    dFimAtu   
Retorno-----------: aPeriodos
===============================================================================================================================
*/
Static Function Monta_Per(dDataIni As Date,dDataFim As Date,cFil As Character,cMat As Character,dIniAtu As Date,dFimAtu As Date)

Local aPeriodos := {} As Array
Local cFilSPO	:= xFilial( "SPO" , cFil ) As Character
Local dAdmissa	:= SRA->RA_ADMISSA As Date
Local dPerIni   := Ctod("//") As Date
Local dPerFim   := Ctod("//") As Date

SPO->( DBSetOrder( 1 ) )
SPO->( DBSeek( cFilSPO , .F. ) )
While SPO->( !Eof() .And. PO_FILIAL == cFilSPO )
    dPerIni := SPO->PO_DATAINI
    dPerFim := SPO->PO_DATAFIM  

    //-- Filtra Periodos de Apontamento a Serem considerados em funcao do Periodo Solicitado
    If dPerFim < dDataIni .Or. dPerIni > dDataFim                                                      
		SPO->( DBSkip() )  
		Loop  
    EndIf

    //-- Somente Considera Periodos de Apontamentos com Data Final Superior a Data de Admissao
    If ( dPerFim >= dAdmissa )
       aAdd( aPeriodos , { dPerIni , dPerFim , Max( dPerIni , dDataIni ) , Min( dPerFim , dDataFim ) } )
	Else
		Exit
	EndIf

	SPO->( DBSkip() )
EndDo

If ( aScan( aPeriodos , { |x| x[1] == dIniAtu .And. x[2] == dFimAtu } ) == 0.00 )
	dPerIni := dIniAtu
	dPerFim	:= dFimAtu 
	If !(dPerFim < dDataIni .Or. dPerIni > dDataFim)
		If ( dPerFim >= dAdmissa )
			aAdd(aPeriodos, { dPerIni, dPerFim, Max(dPerIni,dDataIni), Min(dPerFim,dDataFim) } )
		EndIf
    EndIf
EndIf

Return(aPeriodos)

/*
===============================================================================================================================
Programa--------: APON001P
Autor-----------: Julio de Paula Paz
Data da Criacao-: 31/05/2019 
Descrição-------: Gatilha os campos hora inicial e final com os horário marcados para o dia.
Parametros------: _cCampo = Campo que disparou o gatilho.
Retorno---------: _xRet = Conteúdo do campo que disparou o gatilho.
===============================================================================================================================
*/
User Function APON001P(_cCampo As Character)

Local _aHorarios	:= {} As Array
Local _oModel		:= FWModelActive() As Object
Local _oModelCab	:= _oModel:GetModel( 'Z10PAI' ) As Object
Local _oModelDet	:= _oModel:GetModel( 'Z10FIL' ) As Object
Local _dDataOcorr	:= SToD('//') As Date
Local _cMatricula	:= '' As Character
Local _cRetorno  	:= '' As Character
Local _cOrigem  	:= '' As Character
Local _cTempoD		:= '00:00' As Character
Local _cHoraIni		:= '' As Character
Local _cHoraFin 	:= '' As Character
Local _nI			:= 0 As Numeric

Private MvRet	:= AllTrim(ReadVar()) As Character

Begin Sequence
	If AllTrim(_cCampo) == "Z10_HORAIN"
		MvRet := "M->Z10_HORAIN"
	ElseIf AllTrim(_cCampo) == "Z10_HORAFI"	
		MvRet := "M->Z10_HORAFI"
	ElseIf AllTrim(_cCampo) == "Z10_DATA"
		MvRet := "M->Z10_DATA"
	ElseIf AllTrim(_cCampo) == "Z10_MATRIC" 
		MvRet := "M->Z10_MATRIC" 
	ElseIf AllTrim(_cCampo) == "Z10_ORIGEM"
		MvRet := "M->Z10_ORIGEM"
	EndIf

	_cOrigem:= _oModelDet:GetValue('Z10_ORIGEM')

	If AllTrim(_cCampo) == "Z10_DATA" 
		_dDataOcorr:= _oModelCab:GetValue('Z10_DATA')
		_cRetorno  := "H" 

		_nTotal:=_oModelDet:Length()
		For _nI := 1 To _nTotal
			_oModelDet:GoLine( _nI )

			_cMatricula:= _oModelDet:GetValue('Z10_MATRIC')
			_cOrigem   := _oModelDet:GetValue('Z10_ORIGEM')
			_aHorarios := {}
			MsgRun("Lendo apontamentos da data "+DToC(_dDataOcorr)+" da Matricula: "+_cMatricula, "Aguarde...",;
					{|| _aHorarios := U_APON001J(_dDataOcorr,_cMatricula,_cRetorno,_cOrigem)  } )
			If Len(_aHorarios) > 0 
				_oModelDet:LoadValue( 'Z10_HORAIN', _aHorarios[1] )
				_oModelDet:LoadValue( 'Z10_HORAFI', _aHorarios[2] )
				_oModelDet:LoadValue( 'Z10_TEMPOD', _aHorarios[3] )
			Else
				_oModelDet:LoadValue( 'Z10_HORAIN', "00:00" )
				_oModelDet:LoadValue( 'Z10_HORAFI', "00:00" )
				_oModelDet:LoadValue( 'Z10_TEMPOD', "00:00" )
			EndIf
		Next _nI
		
		If _nTotal > 0
			_oModelDet:GoLine( 1 )
		EndIf 

	ElseIf AllTrim(_cCampo) == "Z10_ORIGEM" .Or. AllTrim(_cCampo) == "Z10_MATRIC" 
		_dDataOcorr := _oModelCab:GetValue('Z10_DATA')
		_cMatricula := _oModelDet:GetValue('Z10_MATRIC')
		_cRetorno   := "H"
		_aHorarios  := {}
		MsgRun("Lendo apontamentos da data "+DToC(_dDataOcorr)+" da Matricula: "+_cMatricula, "Aguarde...",;
				{|| _aHorarios := U_APON001J(_dDataOcorr,_cMatricula,_cRetorno,_cOrigem)  } )

		If Len(_aHorarios) > 0 
			_oModelDet:LoadValue( 'Z10_HORAIN', _aHorarios[1] )
			_oModelDet:LoadValue( 'Z10_HORAFI', _aHorarios[2] )
			_oModelDet:LoadValue( 'Z10_TEMPOD', _aHorarios[3] )
		Else
			_oModelDet:LoadValue( 'Z10_HORAIN', "00:00" )
			_oModelDet:LoadValue( 'Z10_HORAFI', "00:00" )
			_oModelDet:LoadValue( 'Z10_TEMPOD', "00:00" )
		EndIf
	ElseIf AllTrim(_cOrigem) <> "H" // HE - Horas Extras // campos: Z10_HORAIN, Z10_HORAFI Recalculo o campo Z10_TEMPOD só se não For hora extra
		M->Z10_HORAIN := _oModelDet:GetValue('Z10_HORAIN')
		M->Z10_HORAFI := _oModelDet:GetValue('Z10_HORAFI')

		_cHoraIni := M->Z10_HORAIN + ":00"
		_cHoraFin := M->Z10_HORAFI + ":00" 
		
		_cTempoD:= ELAPTIME(_cHoraIni,_cHoraFin) 
		M->Z10_TEMPOD := SubStr(_cTempoD,1,5)
		_oModelDet:LoadValue( 'Z10_TEMPOD', M->Z10_TEMPOD)
	EndIf
	_xRet := &(MvRet) 

End Sequence

Return (_xRet)

/*
===============================================================================================================================
Programa--------: APON001V
Autor-----------: Julio de Paula Paz
Data da Criacao-: 31/05/2019 
Descrição-------: Valida as alterações das linhas de grid.
Parametros------: _oModel = o modelo de dados.
                  _nLinha = Numero da linha no grid
				  _cAcao  = Ação ocorrida = INSERT/DELET/UPDATE
				  _cCampo = campo posicionado na validação. 
Retorno---------: _lRet = .T. => Validação Ok.
                          .F. => Alteração não permitida.
===============================================================================================================================
*/
User Function APON001V(_oModel As Object,_nLinha As Numeric,_cAcao As Character,_cCampo As Character)

Local _lRet			:= .T. As Logical
Local _oModelDet	:= _oModel:GetModel("Z10FIL") As Object
Local _cImprimiu	:= '' As Character
Local _cNomeFunc	:= '' As Character
Local _cNrMatric	:= '' As Character

Begin Sequence
	_nOperation := _oModel:GetOperation()
	_cImprimiu  := _oModelDet:GetValue("Z10FIL","Z10_IMPRES") 
	_cNrMatric  := _oModelDet:GetValue("Z10FIL","Z10_MATRIC") 
	_cNomeSocial:= Posicione("SRA",1,xFilial( "SRA" )+_cNrMatric,"RA_NSOCIAL")
	If Empty(_cNomeSocial)
		_cNomeFunc  := _oModelDet:GetValue("Z10FIL","Z10_FUNCIO")   
	Else
		_cNomeFunc  := _cNomeSocial
	EndIf

	If _nOperation == MODEL_OPERATION_UPDATE  
		If (ValType(_oModel:ldeleteline) == "L" .And. _oModel:ldeleteline) .Or. (ValType(_oModel:lupdateline) == "L" .And. _oModel:lupdateline)
			If AllTrim(_cImprimiu) == "S"
				Help(NIL, NIL, "APON00115", NIL, "A ocorrência de horário de ponto do funcionário: '+AllTrim(_cNrMatric)+"-"+AllTrim(_cNomeFunc)  +  ', já foi impressa e não pode ser modificada.", 1, 0, NIL, NIL, NIL, NIL, NIL, {""})
				_lRet := .F.
			EndIf
		EndIf
	EndIf

End Sequence

Return _lRet

/*
===============================================================================================================================
Programa----------: fGetApo
Autor-------------: Alex Wallauer
Data da Criacao---: 26/04/2022
Descrição---------: Retorna horas extras do funcionario.	
Parametros--------: dInicio, dFim                    
Retorno-----------: qtde de horas extras
===============================================================================================================================
*/
Static Function fGetApo(dInicio As Database,dFim As Date)

Local aArea		:= FWGetArea() As Array
Local cAliasQry	:= GetNextAlias() As Character
Local cWhere	:= "" As Character
Local cPrefixo	:= "PC_" As Character
Local cJoinFil	:= "" As Character
Local xExtra    := 0 As Variant

cWhere += "%"
cWhere += cPrefixo + "FILIAL = '" + SRA->RA_FILIAL + "' AND "
cWhere += cPrefixo + "MAT = '" + SRA->RA_MAT + "' AND "
cWhere += cPrefixo + "DATA >= '" + DToS(dInicio) + "' AND "
cWhere += cPrefixo + "DATA <= '" + DToS(dFim) + "' "
cWhere += "%"

cJoinFil:= "%" + FWJoinFilial("SPC", "SP9") + "%"

BeginSql Alias cAliasQry

	SELECT             
		SPC.PC_DATA, SPC.PC_PD, SPC.PC_QUANTC, SPC.PC_QUANTI, SP9.P9_CLASEV, SP9.P9_IDPON
	FROM 
		%Table:SPC% SPC
	INNER JOIN %Table:SP9% SP9
	ON %exp:cJoinFil% AND SP9.%NotDel% AND SPC.PC_PD = SP9.P9_CODIGO			
	WHERE
		%Exp:cWhere%  AND SPC.%NotDel%
	ORDER BY SPC.PC_DATA, SPC.PC_PD	
EndSql 	

While !(cAliasQry)->(Eof())
	If (cAliasQry)->P9_CLASEV == "01" //Hora Extra
		xExtra += (cAliasQry)->PC_QUANTC
	EndIf	
	(cAliasQry)->(DBSkip())
EndDo

(cAliasQry)->(DBCloseArea())

If xExtra >= 1
   nHora:=INT(xExtra) 
   nMin:= (xExtra) - nHora
   _nMinExtra:= ( (nHora * 0.60) + nMin )//Soma 0.60 pq a somatoria dos minutos esta dividida por 100
Else
   _nMinExtra:=xExtra//Soma os minutos divididos por 100
EndIf

nHoraExtra :=Round( (_nMinExtra*100)/60,2)//TOTAL DE HORAS GERAL  //***CENTESIMAL***
nHora2Extra:=INT(nHoraExtra)//INTEIRO DA HORA
nHora2Extra:=(nHora2Extra*60)//TOTAL DE MINUTOS HORA CHEIA
nHora2Extra:=(_nMinExtra*100)-nHora2Extra//TOTAL DE MINUTOS - TOTAL DE MINUTOS DAS HORAS CHEIAS
nHora2Extra:=INT(nHoraExtra)+(nHora2Extra/100)//SOMA OS RESTOS DOS MINUTOS
nHora2Extra:=Round(nHora2Extra,2)//***SEXAGESIMAL***

nHora2Extra:=StrZero(INT(nHora2Extra),2)+":"+StrZero((nHora2Extra-INT(nHora2Extra))*100,2)//TRANSFORMA EM HORA COM ":"

FWRestArea(aArea)

Return nHora2Extra

/*
===============================================================================================================================
Programa----------: APON001G1
Autor-------------: Igor Melgaço
Data da Criacao---: 08/06/2023
Descrição---------: Gatilho do campo Z10_TIPO	
Parametros--------:                  
Retorno-----------: 
===============================================================================================================================
*/
User Function APON001G1

Local _oModelDet := FWModelActive() As Object
Local _cZ10_TIPO := _oModelDet:GetValue("Z10FIL","Z10_TIPO")  As Character
Local _cRet 	 := "" As Character

If _cZ10_TIPO == "O"
	_cRet := U_ITKEY("Ausencia de marcacao do ponto","Z10_MOTIVO") 
ElseIf _cZ10_TIPO == "S"
	_cRet := U_ITKEY("Suspensao","Z10_MOTIVO") 
Else
	_cRet := U_ITKEY("","Z10_MOTIVO")  
EndIf

Return _cRet
