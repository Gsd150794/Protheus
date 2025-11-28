/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |23/07/2025| Chamado 51340. Ajustar função para validação de ambiente de teste
Lucas Borges  |01/08/2025| Chamado 51453. Substituir função EncodeUtf8 por FWHttpEncode
Lucas Borges  |14/09/2025| Chamado 51799. Implementada função para validar ambiente de teste totvs.framework.environment.Type.get()
===============================================================================================================================
*/

#Include "TOTVS.ch"

Static _cUrl As Character
Static _cKey As Character
Static _cIdent As Character
Static _cCodEstOrg As Character
Static _cId As Character
Static _cFilial As Character
Static lGP010 As Logical
Static aLog As Array
Static aLogERR As Array
Static oJsonFunc As Object
Static _aSM0 As Array

/*
===============================================================================================================================
Programa----------: MPON002
Autor-------------: Igor Melgaço
Data da Criacao---: 22/09/2022
Descrição---------: Rotinas para Registro e Manutenção de Funcionarios atraves da API da DIMEP. Chamado 44767
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MPON002(nOper As Numeric)

Local _aParRet 	:= {} As Array
Local _aParAux	:= {} As Array
Local _bOK 		:= {||.T.} As Block
Local _nI 		:= 0 As Numeric
Local _lRet 	:= .F. As Logical
Local _lScheduler	:= FWGetRunSchedule() As Logical
Local oProc 	:= Nil As Object

_cUrl       := ""
_cKey       := ""
_cIdent     := "" //CNPJ da Filial de integração campo identifier do Header da requisição
_cCodEstOrg := "" //Código da Filial no Sistema da DIMEP. Foi padronizado para ter o mesmo codigo da Filial do Protheus
_cId        := "" //Id da Filial no Sistema da DIMEP.
_cFilial    := ""
lGP010      := .F.
aLog        := {}
aLogERR     := {}
oJsonFunc   := Nil

_aSM0       := FWLoadSM0()

If totvs.framework.environment.Type.get() <> '1'
	_cUrl := ""
	_cKey := ""
Else
	_cUrl := SuperGetMV("IT_MPO2URL",,"https://www.dimepkairos.com.br/RestServiceApi/" )
	_cKey := SuperGetMV("IT_MPO2KEY",,"b5543fd9-f4d5-49d3-bf5d-112188f49bc0")
EndIf

MV_PAR01 := "1"
MV_PAR02 := "1"
MV_PAR03 := Ctod("")
MV_PAR04 := Ctod("")

aLog     := {}
aLogERR  := {}

If _lScheduler
	MPON002INT(oProc)
Else

	lGP010   := FWIsInCallStack("U_GP010AGRV") //Inclusão, Alteração ou Exclusão de Funcionario
	_cFilial := FWCodFil()

	If MPON002VF(_lScheduler) //valida se a Filial Existe no Kairos DIMEP
		If lGP010
			MV_PAR01 := "3"
			MV_PAR02 := AllTrim(Str(nOper))
			nCad := Val(MV_PAR01)
			nModel := nOper
			FWMsgRun( ,{|oProc|  _lRet := MPON002INT(oProc,nCad,nModel) } , "Hora Inicial: "+Time()+" Processando integração Kairos DIMEP... " )
		Else
			aAdd( _aParAux , { 2 , "Cadastros a Executar: "	   , MV_PAR01, {"1=Funcionários","2=Usuários","3=Funcionários e Usuários"}, 090 ,".T.", .T. } )
			aAdd( _aParAux , { 2 , "Modelos a Executar: "	   , MV_PAR02, {"1=Inclusao","2=Alteracao","3=Demissao","4=Todos"}, 090 ,".T.", .T. } )

			For _nI := 1 To Len( _aParAux )
				aAdd( _aParRet , _aParAux[_nI][03] )
			Next _nI

			If !ParamBox( _aParAux , " Integração de Dados com o sistema Kairos DIMEP " , @_aParRet, _bOK )
				_lRet := .F.
			Else
				nCad := Val(MV_PAR01)
				nModel := Val(MV_PAR02)
				FWMsgRun( ,{|oProc|  _lRet := MPON002INT(oProc,nCad,nModel) } , "Hora Inicial: "+Time()+" Processando integração de Funcionarios... " )
			EndIf
		EndIf
	EndIf
EndIf

Return 

//-------------------------------------------------------------------
/*/{Protheus.doc} SchedDef
Parâmetros para execução via Job.

@author Cristina Cintra

@since 16/05/2014
@version 1.0
/*/
//-------------------------------------------------------------------
Static Function SchedDef

Local _aParam 	:= {} As Array
Local _aOrd		:= {} As Array

aAdd(_aParam, "P"        ) // 01 - Tipo R para relatorio P para processo
aAdd(_aParam, "PARAMDEF" ) // 02 - Pergunte do relatorio, caso nao use passar ParamDef
aAdd(_aParam, ""         ) // 03 - Alias
aAdd(_aParam, _aOrd       ) // 04 - Array de ordens
aAdd(_aParam, ""         ) // 05 - Titulo
aAdd(_aParam, ""         ) // 06 - Nome do relatório (parametro 1 do metodo new da classe TReport)
 
Return _aParam

/*
===============================================================================================================================
Programa----------: MPON002VF
Autor-------------: Igor Melgaço
Data da Criacao---: 22/09/2023
Descrição---------: Rotina para Validar se a Filial Posicionada existe na DIMEP. 
Parametros--------: _lScheduler
Retorno-----------: .T./.F.
===============================================================================================================================
*/ 
Static Function MPON002VF(_lScheduler As Logical) As Logical

Local aHeader	:= {} As Array
Local cBodyJson := '' As Character
Local cResult 	:= '' As Character
Local cParms 	:= '' As Character
Local oJsonFil 	:= Nil As Object
Local _nPos 	:= 0 As Numeric
Local _lRet 	:= .F. As Logical

If (_nPos := aScan(_aSM0,{|A|A[2]==_cFilial})) <> 0

	_cIdent     := AllTrim(_aSM0[_nPos][18]) //CNPJ da Filial Posicionada

	aHeader   := MPON002CH() //Carrega o Header
	cParms    := "/OrganizationalStructure/SearchOrganizationalStructure"
	cBodyJson := MPON002JSO("SO")	 //Carrega o Json da Requisição

	//Efetua pesquisa 
	_lRet := MPON002REST(_cUrl,cParms,aHeader,cBodyJson,@cResult)

	If _lRet
		oJsonFil := JsonObject():new()

		If FWJsonDeserialize(cResult,@oJsonFil)
			If Len(oJsonFil) > 1 // Verifico se retornou mais de 1 Funcionario
				cResult := "A Consulta retornou mais de uma filial com o mesmo Código"
				_lRet := .F.
				If !_lScheduler
					FWAlertWarning(cResult,"MPON00201")
				EndIf
			Else
				_cId := AllTrim(Str(oJsonFil[1]:Id))
				_cCodEstOrg := AllTrim(Str(oJsonFil[1]:Codigo))
				_lRet := .T.
			EndIf
		Else
			cResult := "Falha ao popular JsonObject." 
			_lRet := .F.
			If !_lScheduler
				FWAlertWarning(cResult,"MPON00202")
			EndIf
		EndIf
	Else
		_lRet := .F.
		cResult := "Filial "+cFilAnt+ "  não configurada no Kairos DIMEP!"
		If !_lScheduler
			If !lGP010 
				FWAlertWarning(cResult,"MPON00203")
			EndIf
		EndIf
	EndIf
Else
	_lRet := .F.
	cResult := "Não Encontrorou filial na SM0"
	If !_lScheduler
		If !lGP010 
			FWAlertWarning(cResult,"MPON00204")
		EndIf
	EndIf
EndIf

Return _lRet

/*
===============================================================================================================================
Programa----------: MPON002INT
Autor-------------: Igor Melgaço
Data da Criacao---: 22/09/2023
Descrição---------: Rotina para Inclusão e Alteração de funcionários e Usuários na DIMEP. 
Parametros--------: lAut    - Execução por rotina automática
Retorno-----------: .T./.F.
===============================================================================================================================
*/ 
Static Function MPON002INT(oProc As Object,nCad As Numeric,nModel As Numeric) As Logical

Local _lModifica 	:= .F. As Logical
Local _lInclui 		:= .F. As Logical
Local _lDemite 		:= .F. As Logical
Local lMostralog 	:= .F. As Logical
Local aCab 			:= {"Proc.","Filial","Url / Relógio","Param","Operação","Matricula","Nome","Json","Resultado da API"} As Array
Local _cTitAux 		:= '' As Character
Local _cMsgTop 		:= '' As Character
Local _cLinha 		:= '' As Character
Local _nI 			:= 0 As Numeric
Local _cDir 		:= '' As Character
Local _cFileNome 	:= '' As Character

Default oProc    := Nil
Default nCad     := 3 //Ambos Funcionario/Usuario
Default nModel   := 4 //Ambas Inclusao/Alteracao/Exclusao

aLog       := {}
aLogERR    := {}

If nModel = 1
	_lInclui   := .T.
	_lModifica := .F.
	_lDemite   := .F.
ElseIf nModel = 2 
	_lInclui   := .F.
	_lModifica := .T.
	_lDemite   := .F.
ElseIf nModel = 3 
	_lModifica := .F.
	_lInclui   := .F.
	_lDemite   := .T.
ElseIf nModel = 4 
	_lModifica := .T.
	_lInclui   := .T.
	_lDemite   := .T.
EndIf

_lModifica := .T.

If lGP010
	If oProc <> Nil
		oProc:cCaption:=("Sinc. Funcionario: "+SRA->RA_MAT + " " + AllTrim(SRA->RA_NOMECMP))
		ProcessMessages() 
	EndIf
	MPON002SIN(_lInclui,_lModifica,_lDemite,nCad)
Else
	If oProc <> NIL
		MPON002W(oProc,_lInclui,_lModifica,_lDemite,nCad)
	Else
		For _nI := 1 to Len(_aSM0)
			_cFilial := AllTrim(_aSM0[_nI,2])

			If MPON002VF((oProc = NIL)) 
				MPON002W(oProc,_lInclui,_lModifica,_lDemite,nCad)
			EndIf
			SM0->( DBSkip() )
		Next _nI
	EndIf
EndIf

If oProc <> NIL
	If lGP010 .And. Len(aLogERR) > 0
		lMostralog := .T.
	ElseIf !lGP010 .And. Len(aLog) > 0
		lMostralog := .T.
	Else
		lMostralog := .F.            
	EndIf

	If lMostralog
		_cTitAux := "Log de processamento de integrações Kairos DIMEP"
		_cMsgTop := IIf(lGP010,"Verifique as falhas de gravações de acordo com o Log:","Log de processamento")
		//ITListBox( _cTitAux , _aHeader , _aCols , _lMaxSiz , _nTipo , _cMsgTop , _lSelUnc , _aSizes , _nCampo , bOk , bCancel, _abuttons, _aCab , bDblClk , _aColXML , bCondMarca,_bLegenda                      ,_lHasOk,_bHeadClk,_aSX1)
		U_ITListBox( _cTitAux , aCab     , aLog   , .F.      , 2      , _cMsgTop ,          ,         ,         ,     ,        ,          ,       ,         ,          ,           , {|C,L|U_MGPE026L(C,L)}        , .F.   ,         ,     )
	EndIf
Else
	_cLinha := ArrTokStr(aCab,";")+CRLF

	For _nI := 1 To Len(aLog)
		_cLinha += ArrTokStr(aLog[_nI],";")+CRLF
	Next _nI
	
	_cLinha   := StrTran(_cLinha,".",",")
	_cDir     := "\data\Italac\mpon002\"
	_cFileNome:= _cDir + "mpon002_"+DToS(DATE())+"_"+StrTran(TIME(),":","_")+".csv"
	
	_oFWriter:=FWFileWriter():New(_cFileNome , .T.)
	_oFWriter:Write(_cLinha)
	_oFWriter:Close()
EndIf
      
Return .T.

/*
===============================================================================================================================
Programa----------: MPON002SIN
Autor-------------: Igor Melgaço
Data da Criacao---: 02/10/2023
Descrição---------: Sincroniza Usuário com a Dimep
Parametros--------: 
Retorno-----------:    
===============================================================================================================================
*/
Static Function MPON002SIN(_lInclui  As Logical,_lModifica  As Logical,_lDemite As Logical,nCad As Numeric)

Local cBodyJson := '' As Character
Local cResult 	:= '' As Character
Local cParms 	:= '' As Character
Local _lRet  	:= .F. As Logical
Local lGravaLog := .F. As Logical
Local aHeader 	:= {} As Array
Local lContinua := .F. As Logical
Local cTipo 	:= '' As Character

//Carrega o Header
aHeader := MPON002CH()

oJsonFunc := nil

If nCad = 1 .Or. nCad = 3
	//Pesquisa se existe o Funcionario
	cParms    := "/People/SearchPerson"
	cBodyJson := MPON002JSO("SC")	 //Carrega o Json da Requisição conforme SRA posicionado Metodo Search Person
	_lRet     := MPON002REST(_cUrl,cParms,aHeader,cBodyJson,@cResult)
	lGravaLog := .F.

	If _lRet
		lGravaLog := .T.
		If FWJsonDeserialize(DecodeUTF8(cResult),@oJsonFunc)
			If Len(oJsonFunc) > 1 // Verifico se retornou mais de 1 Funcionario
				cResult    := "A Consulta retornou mais de um funcionario com a matricula " + cResult
				lContinua := .F.
			Else
				lContinua := .T.
			EndIf
		Else
			cResult := "Falha ao popular JsonObject." + cResult
			lContinua := .F.
		EndIf
	Else
		lContinua := .T.
	EndIf

	If lContinua
		If _lRet .And. _lModifica .And. SRA->RA_I_DIMEP == "S" .And. SRA->RA_SITFOLH <> "D" 
			cTipo := "Alteração"
			If MPON002VA() //Verifica se Altera ou Não
				cParms    := "/People/ChangePerson"
				cBodyJson := MPON002JSO("CP")	//Carrega o Json da Requisição conforme SRA posicionado
				_lRet     := MPON002REST(_cUrl,cParms,aHeader,cBodyJson,@cResult)
				lGravaLog := .T.
			Else
				lGravaLog := .F.
			EndIf
		ElseIf !_lRet .And. _lInclui .And. SRA->RA_I_DIMEP == "S" .And. SRA->RA_SITFOLH <> "D"
			cTipo     := "Inclusão"
			cBodyJson := MPON002JSO("SP")	//Carrega o Json da Requisição conforme SRA posicionado
			cParms    := "/People/SavePerson" 
			_lRet     := MPON002REST(_cUrl,cParms,aHeader,cBodyJson,@cResult)
			lGravaLog := .T.
		ElseIf _lRet .And. _lDemite .And. SRA->RA_I_DIMEP == "S" .And. SRA->RA_SITFOLH == "D"
			cTipo     := "Demissão"
			cParms    := "/Dismiss/MarkDismiss"
			cBodyJson := MPON002JSO("DM")	//Carrega o Json da Requisição conforme SRA posicionado
			
			_lRet     := MPON002REST(_cUrl,cParms,aHeader,cBodyJson,@cResult)
			
			If _lRet .Or. "Person already dismiss" $ cResult
				SRA->(RecLock("SRA",.F.))
				SRA->RA_I_DIMEP := "N"
				SRA->(MSUnLock())
			EndIf			
			
			lGravaLog := .T.
		ElseIf !_lRet .And. _lDemite .And. SRA->RA_I_DIMEP == "S" .And. SRA->RA_SITFOLH == "D"

			SRA->(RecLock("SRA",.F.))
			SRA->RA_I_DIMEP := "N"
			SRA->(MSUnLock())

			lGravaLog := .F.
		Else
			lGravaLog := .F.
		EndIf
	EndIf

	If lGravaLog 
		If !_lRet
			aAdd(aLogERR,{_lRet,SRA->RA_FILIAL,_cUrl,cParms,cTipo,SRA->RA_MAT,SRA->RA_NOME,cBodyJson,cResult})
		EndIf

		aAdd(aLog,{_lRet,SRA->RA_FILIAL,_cUrl,cParms,cTipo,SRA->RA_MAT,SRA->RA_NOME,cBodyJson,cResult})
	EndIf
EndIf

If nCad = 2 .Or. nCad = 3
	//Pesquisa se existe o Usuario
	cParms    := "User/Search" 
	cBodyJson := MPON002JSO("US")	 //Carrega o Json da Requisição conforme SRA posicionado Metodo Search Person

	_lRet     := MPON002REST(_cUrl,cParms,aHeader,cBodyJson,@cResult)
	lGravaLog := .F.

	If _lRet .And. _lModifica .And. SRA->RA_I_DIMEP == "S" .And. SRA->RA_SITFOLH <> "D" 
		cTipo     := "Alteração"
		cParms    := "User/Update"
		cBodyJson := MPON002JSO("UU")	//Carrega o Json da Requisição conforme SRA posicionado
		
		_lRet     := MPON002REST(_cUrl,cParms,aHeader,cBodyJson,@cResult)
		lGravaLog := .T.
	ElseIf !_lRet .And. _lInclui .And. SRA->RA_I_DIMEP == "S" .And. SRA->RA_SITFOLH <> "D"
		cTipo     := "Inclusão"
		cParms    := "User/Create"
		cBodyJson := MPON002JSO("UC")	//Carrega o Json da Requisição conforme SRA posicionado
			
		_lRet     := MPON002REST(_cUrl,cParms,aHeader,cBodyJson,@cResult)
		lGravaLog := .T.
	Else
		lGravaLog := .F.
	EndIf

	If lGravaLog 
		If !_lRet
			aAdd(aLogERR,{_lRet,SRA->RA_FILIAL,_cUrl,cParms,cTipo,SRA->RA_MAT,SRA->RA_NOME,cBodyJson,cResult})
		EndIf

		aAdd(aLog,{_lRet,SRA->RA_FILIAL,_cUrl,cParms,cTipo,SRA->RA_MAT,SRA->RA_NOME,cBodyJson,cResult})
	EndIf
EndIf

FreeObj(oJsonFunc)
Return

/*
===============================================================================================================================
Programa----------: MPON002VA
Autor-------------: Igor Melgaço
Data da Criacao---: 18/10/2023
Descrição---------: Valida se altera o Funcionario
Parametros--------: 
Retorno-----------: _lRet   
===============================================================================================================================
*/
Static Function MPON002VA() As Logical

Local _cMatricula	:= AllTrim(Str(Val(SRA->RA_MAT)))As Character
Local _cCracha 		:= _cMatricula As Character
Local _cNome 		:= AllTrim(SRA->RA_NOMECMP) As Character
Local _cCPF 		:= AllTrim(SRA->RA_CIC) As Character
Local _cEmail 		:= AllTrim(SRA->RA_EMAIL) As Character
Local _cDtAdmissao	:=Subs(DToS(SRA->RA_ADMISSA),7,2)+"/"+Subs(DToS(SRA->RA_ADMISSA),5,2)+"/"+Subs(DToS(SRA->RA_ADMISSA),1,4)+' 00:00:00' As Character
Local _cBaseHoras 	:= AllTrim(Str(SRA->RA_HRSMES)) As Character
Local _cPis 		:= AllTrim(SRA->RA_PIS) As Character
Local _cSexo 		:= IIf(SRA->RA_SEXO=="M","1","2") As Character
Local lContinua 	:= .F. As Logical

If AttIsMemberOf(oJsonFunc[1], "Matricula") .And. oJsonFunc[1]:Matricula <> Val(_cMatricula)
	lContinua := .T.
ElseIf AttIsMemberOf(oJsonFunc[1], "Cracha") .And. oJsonFunc[1]:Cracha <> Val(_cCracha) 
	lContinua := .T.
ElseIf AttIsMemberOf(oJsonFunc[1], "Nome") .And. oJsonFunc[1]:Nome <> _cNome
	lContinua := .T.
ElseIf AttIsMemberOf(oJsonFunc[1], "Cpf") .And. oJsonFunc[1]:Cpf <> _cCPF 
	lContinua := .T.
ElseIf AttIsMemberOf(oJsonFunc[1], "CpfResponsavel") .And. AllTrim(oJsonFunc[1]:CpfResponsavel) <> AllTrim(_cCPFResp) 
	lContinua := .T.
ElseIf AttIsMemberOf(oJsonFunc[1], "Email") .And. Upper(AllTrim(oJsonFunc[1]:Email)) <> Upper(_cEmail) 
	lContinua := .T.
ElseIf AttIsMemberOf(oJsonFunc[1], "DataAdmissao") .And. oJsonFunc[1]:DataAdmissao <> _cDtAdmissao
	lContinua := .T.
ElseIf AttIsMemberOf(oJsonFunc[1], "BaseHoras") .And. oJsonFunc[1]:BaseHoras <> Val(_cBaseHoras) 
	lContinua := .T.
ElseIf AttIsMemberOf(oJsonFunc[1], "CodigoPis") .And. oJsonFunc[1]:CodigoPis <> _cPis
	lContinua := .T.
ElseIf AttIsMemberOf(oJsonFunc[1], "CodigoPisNumerico") .And. oJsonFunc[1]:CodigoPisNumerico <> Val(_cPis)
	lContinua := .T.
ElseIf AttIsMemberOf(oJsonFunc[1], "Sexo") .And. oJsonFunc[1]:Sexo <> Val(_cSexo)
	lContinua := .T.
EndIf

Return lContinua

/*
===============================================================================================================================
Programa----------: MPON002CH
Autor-------------: Igor Melgaço
Data da Criacao---: 20/09/2023
Descrição---------: Carrega o header da Requsição
Parametros--------:
Retorno-----------: aHeader => Cabeçalho da Requisição
===============================================================================================================================
*/ 
Static Function MPON002CH As Array

Local aHeader := {} As Character

//Cabeçalho de requisição
aAdd(aHeader, "identifier: "+ _cIdent)
aAdd(aHeader, "key: "+ _cKey)
aAdd(aHeader, "Content-Type: application/json")

Return aHeader

/*
===============================================================================================================================
Programa----------: MPON002JSO
Autor-------------: Igor Melgaço
Data da Criacao---: 20/09/2023
Descrição---------: Carrega o Json da Reqisição
Parametros--------: cOper => Tipo da Operação
Retorno-----------: cBodyJson => Body da Requisição
===============================================================================================================================
*/ 
Static Function MPON002JSO(cOper As Character) As Character

Local cBodyJson 	:= '' As Character
Local _cCPFResp 	:= AllTrim(SuperGetMV("IT_CPFDIME",,"21918781800")) As Character
Local _cMatricula 	:= AllTrim(Str(Val(SRA->RA_MAT))) As Character
Local _cCracha 		:= _cMatricula As Character
Local _cNome 		:= AllTrim(SRA->RA_NOMECMP) As Character
Local _cCPF 		:= AllTrim(SRA->RA_CIC) As Character
Local _cEmail 		:= Lower(AllTrim(SRA->RA_EMAIL)) As Character
Local _cDtAdmissao 	:= '' As Character
Local _cDtDemissao 	:= Subs(DToS(SRA->RA_DEMISSA),1,4)+"-"+Subs(DToS(SRA->RA_DEMISSA),5,2)+"-"+Subs(DToS(SRA->RA_DEMISSA),7,2) As Character
Local _cBaseHoras 	:= AllTrim(Str(SRA->RA_HRSMES))As Character
Local _cPis 		:= AllTrim(SRA->RA_PIS) As Character
Local _cSexo 		:= IIf(SRA->RA_SEXO=="M","1","2") As Character
Local _cPasswpord 	:= _cCPF As Character
Local _cMotDemis 	:= '' As Character
Local _aMotRes 		:= {} As Array
Local _cIDRes 		:= '' As Character

//https://www.dimepkairos.com.br/swagger/ui/index#!
If cOper == "SC" //Search Person
	cBodyJson := '{'
	cBodyJson += 		'"Matricula":'+_cMatricula+' '// (Campo obrigatório) Matricula do funcionário. / 
	cBodyJson += '}'
ElseIf cOper == "SP" .Or. cOper == "CP" //Save Person ou Change Person
	cBodyJson := '{'

	If cOper == "CP"
		cBodyJson += 		'"Id":'+AllTrim(Str(oJsonFunc[1]:Id))+','
	EndIf

	cBodyJson += 		'"Matricula":'+_cMatricula// (Campo obrigatório) Matricula do funcionário. / 
	cBodyJson += 		',"Cracha":'+_cCracha // (Campo obrigatório) Cracha do funcionário. / 
	cBodyJson += 		',"Nome":"'+_cNome+'"' // (Campo obrigatório) Nome do funcionário. / 
	cBodyJson += 		',"Cpf":"'+_cCPF+'"' // (Campo obrigatório portaria 671) CPF do funcionário. / 
	cBodyJson += 		',"CpfResponsavel":"'+_cCPFResp+'"' // (Campo obrigatório  671) Cpf do usuário responsável. / 
	cBodyJson += 		',"Email":"'+_cEmail+'"' 
	
	If cOper == "CP"
		//Padrao da data "01-01-1753 00:00:00"
		_cDtAdmissao := Subs(DToS(SRA->RA_ADMISSA),7,2)+"-"+Subs(DToS(SRA->RA_ADMISSA),5,2)+"-"+ Subs(DToS(SRA->RA_ADMISSA),1,4)
		_cDtAdmissao += " 00:00:00"
	Else
		//Padrao da data  "DataNascimento": "20-07-1980" 
		_cDtAdmissao := StrZero(Day(SRA->RA_ADMISSA),2)+"-"+StrZero(Month(SRA->RA_ADMISSA),2)+"-"+StrZero(Year(SRA->RA_ADMISSA),4)
	EndIf

	cBodyJson += 		',"DataAdmissao":"'+_cDtAdmissao+'" ' //*(Campo obrigatório) Data de admissão do funcionário. */ 

	If cOper == "CP" .And. !Empty(AllTrim(DToS(SRA->RA_DEMISSA)))
		cBodyJson += 		',"DataDemissao":"'+_cDtDemissao +'" ' //* (Campo opcional) Data de demissão do funcionário. */
	ElseIf cOper == "CP" .And. Empty(AllTrim(DToS(SRA->RA_DEMISSA)))
		cBodyJson += 		',"DataDemissao":""' //* (Campo opcional) Data de demissão do funcionário. */      
	EndIf
	
	cBodyJson += 		',"BaseHoras":'+_cBaseHoras+'.0 ' //*(Campo obrigatório) Base de horas do funcionário. */  
	cBodyJson += 		',"Estrutura":'//*(Campo obrigatório) Estrutura Organizacional do funcionário. */ 
	cBodyJson += 		'{'
	cBodyJson += 			'"Id": '+_cId//*(Campo obrigatório) Id da Estrutura Organizacional. */
	cBodyJson += 			',"Codigo": ' +_cCodEstOrg // Codigo da Estrutura Organizacional. /
	cBodyJson += 			',"CentroCusto": null'// Centro de custo da Estrutura Organizacional. /
	cBodyJson += 			',"Descricao": null'// Descrição da Estrutura Organizacional. /
	cBodyJson += 			',"DescricaoEstruturaPai": null'// Descrição da Estrutura Pai da Estrutura Organizacional. /
	cBodyJson += 			',"Extra1": null'// Extra 1 da Estrutura Organizacional. /
	cBodyJson += 			',"Extra2": null'// Extra 2 da Estrutura Organizacional. /
	cBodyJson += 		'}'
	
	If cOper == "SP"
		cBodyJson += 		',"Offline": true '	
		cBodyJson += 		',"TipoFuncionario":'// (Campo obrigatório) Tipo de funcionário. / '1'
		cBodyJson += 			'{'
		cBodyJson += 				'"IdTipoFuncionario": 1'// (Campo obrigatório) Id do tipo de funcionário. 1 = Funcionario Normal, 2 = Funcionario Cooperado, 3 = FuncionarioEstagiario, 4 = Funcionario Terceiro /
		cBodyJson += 				',"CarteiraTrabalho": null'// Carteira de trabalho do funcionário. /
		cBodyJson += 			'}'
		cBodyJson += 		',"TipoSalario":'// (Campo obrigatório) Tipo de salário do funcionário / '101'
		cBodyJson += 			'{'
		cBodyJson += 				'"Id": 101'// (Campo obrigatório) Id do tipo de salário do funcionário. 101 = Mensalista, 102 = Horista /
		cBodyJson += 			'}'
	EndIf

	cBodyJson += 		',"MaisDeUmVinculoEmpregaticio":false'// (Campo obrigatório) Multiplos vinculos do funcionário /
	cBodyJson += 		',"CodigoPis": "'+Subs(_cPis,1,3)+"."+Subs(_cPis,4,4)+"."+Subs(_cPis,8,3)+"-"+Subs(_cPis,11,1) +'"'// (Campo obrigatório) Pis do funcionário / 
	cBodyJson += 		',"CodigoPisNumerico": '+_cPis// Pis Numérico do funcionário /
	cBodyJson += 		',"Sexo": '+_cSexo // (Campo obrigatório) Sexo do funcionário. 1 = Masculino, 2 = Feminino  / RA_SEXO - 1="M" / 2="F"
	
	If cOper == "SP"
		cBodyJson += 		',"AmbienteTrabalhoPessoa":'
		cBodyJson += 			'['
		cBodyJson += 				'{'
		cBodyJson += 					'"Id": 0'
		cBodyJson += 					',"Inicio": "0001-01-01T00:00:00"'
		cBodyJson += 					',"Fim": "0001-01-01T00:00:00"'
		cBodyJson += 					',"TipoAmbienteTrabalho": 6 '
		cBodyJson += 				'}'
		cBodyJson += 			']'
	EndIf
	
	cBodyJson += '}'
ElseIf cOper == "DM" //Dismiss/MarkDismiss
	aAdd(_aMotRes,{"01","11-Rescisão sem justa causa por iniciativa do empregador"})
	aAdd(_aMotRes,{"02","11-Rescisão sem justa causa por iniciativa do empregador"})
	aAdd(_aMotRes,{"03","11-Rescisão sem justa causa por iniciativa do empregador"})
	aAdd(_aMotRes,{"04","11-Rescisão sem justa causa por iniciativa do empregador"})
	aAdd(_aMotRes,{"05","12-Extinção do contrato de trabalho por prazo determinado"})
	aAdd(_aMotRes,{"06","21-Rescisão sem justa causa por iniciativa do empregado"})
	aAdd(_aMotRes,{"07","21-Rescisão sem justa causa por iniciativa do empregado"})
	aAdd(_aMotRes,{"08","21-Rescisão sem justa causa por iniciativa do empregado"})
	aAdd(_aMotRes,{"09","21-Rescisão sem justa causa por iniciativa do empregado"})
	aAdd(_aMotRes,{"10","70-Aposentadoria por tempo de serviço, com rescisão contratual"})
	aAdd(_aMotRes,{"11","21-Rescisão sem justa causa por iniciativa do empregado"})
	aAdd(_aMotRes,{"12","11-Rescisão sem justa causa por iniciativa do empregador"})
	aAdd(_aMotRes,{"13","21-Rescisão sem justa causa por iniciativa do empregado"})
	aAdd(_aMotRes,{"14","60-Falecimento"})
	aAdd(_aMotRes,{"15","10-Rescisão com justa causa por iniciativa do empregador"})
	aAdd(_aMotRes,{"21","20-Rescisão com justa causa por iniciativa do empregado"})
	aAdd(_aMotRes,{"23","30-Transf. do empreg. p/outro estab. da mesma empr., ou outra, c/ônus"})

	SRG->( DBSetOrder(1) )
	If SRG->( DBSeek( SRA->( RA_FILIAL + RA_MAT ) ) )
		_cIDRes := AllTrim(SRG->RG_TIPORES)
	EndIf

	_nPos      := aScan(_aMotRes,{|x| x[1] == _cIDRes})

	If _nPos > 0
		_cMotDemis := _aMotRes[_nPos,2]
	Else
		_cMotDemis := "21-Rescisão sem justa causa por iniciativa do empregado"
	EndIf
	
	_cDtDemissao := Subs(DToS(SRA->RA_DEMISSA),1,4)+"-"+Subs(DToS(SRA->RA_DEMISSA),5,2)+"-"+Subs(DToS(SRA->RA_DEMISSA),7,2)

	cBodyJson := '{'
	cBodyJson += 		'"MATRICULA":'+_cMatricula+',' /* (Campo obrigatório) Matrícula do funcionário */
	cBodyJson += 		'"MOTIVO":"'+_cMotDemis+'" ,' /* (Campo obrigatório) Descrição do motivo do desligamento */
	cBodyJson += 		'"DATA":"'+_cDtDemissao+'" ' /* (Campo obrigatório) Data do desligamento do funcionário. Formato aaaa-MM-dd. */
	cBodyJson += '}'
ElseIf cOper == "DU" //Dismiss/UnmarkDismiss
	cBodyJson := '{'
	cBodyJson += 		'"MATRICULA":'+_cMatricula+' ' /* (Campo obrigatório) Email do usuário */
	cBodyJson += '}'
ElseIf cOper == "US" //User Search
	cBodyJson := '{'
	cBodyJson += 		'"Email":"'+_cEmail+'",' /* (Campo obrigatório) Email do usuário */
	cBodyJson += 		'"ResponseType":"'+_cCPFResp+'" ' /*(Campo obrigatório) Possível?valor?"AS400V1",?sempre?será?esse?valor?fixo.?É?o?tipo?da?resposta?esperada */ 
	cBodyJson += '}'
ElseIf cOper == "UC" //User Create 
	cBodyJson := '{'
	cBodyJson += 		'"Nome":"'+_cNome+'",'/* (Campo obrigatório) Nome do usuário */
	cBodyJson += 		'"Email":"'+_cEmail+'",' /* (Campo obrigatório) Email do usuário */
	cBodyJson += 		'"Password":"'+_cPasswpord+'",' /* (Campo obrigatório) Senha do usuário */
	cBodyJson += 		'"CnpjCpfEmpresa":"'+_cIdent+'",' /* (Campo obrigatório) Cnpj da empresa */
	cBodyJson += 		'"PerfilNoSoftware": '+'10000'+','/* (Campo obrigatório) Id do perfil. Este ID é gerado pelo sistema e exibido na url da edição do perfil selecionado */
	cBodyJson += 		'"Cracha":'+_cCracha+','  /* (Campo obrigatório) Crachá do funcionário */
	cBodyJson += 		'"ResponseType":"'+_cCPFResp+'" ' /*(Campo obrigatório) Possível?valor?"AS400V1",?sempre?será?esse?valor?fixo.?É?o?tipo?da?resposta?esperada */ 
	cBodyJson += '}'
ElseIf cOper == "UU" //User Update 
	cBodyJson := '{'
	cBodyJson += 		'"Nome":"'+_cNome+'" ,'/* (Campo obrigatório) Nome do usuário */
	cBodyJson += 		'"Email":"'+_cEmail+'" ,' /* (Campo obrigatório) Email do usuário */
	cBodyJson += 		' "Status": "False" ,'
	cBodyJson += 		'"CnpjCpfEmpresa":"'+_cIdent+'",' /* (Campo obrigatório) Cnpj da empresa */
	cBodyJson += 		'"PerfilNoSoftware": '+'10000'+','/* (Campo obrigatório) Id do perfil. Este ID é gerado pelo sistema e exibido na url da edição do perfil selecionado */
	cBodyJson += 		'"ResponseType":"'+_cCPFResp+'" ' /*(Campo obrigatório) Possível?valor?"AS400V1",?sempre?será?esse?valor?fixo.?É?o?tipo?da?resposta?esperada */ 
	cBodyJson += '}'
ElseIf cOper == "SO" //OrganizationalStructure/SearchOrganizationalStructure
	cBodyJson := '{'
	cBodyJson += 		'"EmpresaCNPJ": "'+TRANSFORM(_cIdent,"@! 99.999.999.9999/99")+'" '
	cBodyJson += '}'
EndIf

Return FWHttpEncode(cBodyJson)

/*
===============================================================================================================================
Programa----------: MPON002REST
Autor-------------: Igor Melgaço
Data da Criacao---: 13/09/2023
Descrição---------: Rotina para envio da requisição
Parametros--------: oRest   - Objeto rest
------------------: _cUrl   - endereço
Retorno-----------: .T./.F. - Registrou ou nao
===============================================================================================================================
*/ 
Static Function MPON002REST(_cUrl As Character,cParms As Character,aHeader As Array,cBodyJson As Character,cResult As Character) As Logical

Local _lRet 	:= .F. As Logical
Local cRegistro := '' As Character
Local cError 	:= '' As Character
Local nStatus 	:= 0 As Numeric
Local oJson 	:= Nil As Object
Local oErro 	:= Nil As Object
Local oRest 	:= Nil As Object

cResult := "" 

oRest := FWRest():New(_cUrl)
oRest:SetPath(cParms )

oRest:SetPostParams(cBodyJson)
oRest:SetChkStatus(.F.)

If oRest:Post(aHeader)
	cError := ""
	nStatus := HTTPGetStatus(@cError)

	If nStatus >= 200 .And. nStatus <= 299
		If Empty(oRest:getResult())
			cResult := "Falha de comunicação no retorno da requisição com sistema DIMEP" + CRLF + "Status " + AllTrim(Str(nStatus))
			_lRet  := .F.
		Else
			cResult := oRest:getResult()
			oJson := JsonObject():new()
			cRegistro := oJson:fromJson(cResult)

			If ValType(cRegistro) == "U"
				If oJson["Sucesso"]
					If cParms == "/People/SearchPerson" .Or. cParms == "/OrganizationalStructure/SearchOrganizationalStructure"
						cResult := oJson["Obj"]
					Else 
						cResult := oJson["Mensagem"]
					EndIf
					_lRet  := .T.
				Else
					cResult := oJson["Mensagem"]
					_lRet  := .F.
				EndIf
			Else
				cResult := "Falha ao popular JsonObject. Erro: " + cRegistro
				_lRet  := .F.
			EndIf 
		EndIf
	Else
		cResult := oRest:getResult() 
		oJson := JsonObject():new()
		cRegistro := oJson:fromJson(cResult)

		If FWJsonDeserialize(cRegistro,@oErro)
			cMensagem := CRLF + "Mensagem: " + oErro:MESSAGE
		Else
			If FWJsonDeserialize(cResult,@oErro)
				cMensagem := CRLF + "Mensagem: " + oErro:MESSAGE
			Else
				cMensagem := ""
			EndIf
		EndIf

		cResult := "Erro:" + oRest:getLastError() + cMensagem
		_lRet  := .F.
	EndIf
Else
	cResult := oRest:getResult() 
	If ValType(cResult) == "U"
		cResult := ""
	EndIf

	cResult := "Falha de comunicação com sistema DIMEP!" + CRLF + oRest:getLastError() + CRLF + cResult
	_lRet  := .F.
EndIf

FreeObj(oJson)
FreeObj(oErro)
FreeObj(oRest)

Return _lRet

/*
===============================================================================================================================
Programa----------: MPON002W
Autor-------------: Igor Melgaço
Data da Criacao---: 26/11/2024
Descrição---------: Rotina para percorrer a SRA 
Parametros--------: oProc,_lInclui,_lModifica,_lDemite,nCad
Retorno-----------: 
===============================================================================================================================
*/ 
Static Function MPON002W(oProc As Object,_lInclui As Logical,_lModifica As Logical,_lDemite As Logical,nCad As Numeric)

Local _cAliasSRA := GetNextAlias() As Character

BeginSql alias _cAliasSRA
	SELECT R_E_C_N_O_ SRA_RECNO FROM %Table:SRA%
	WHERE RA_FILIAL = %exp:_cFilial%
	AND RA_I_DIMEP = 'S' 
	AND D_E_L_E_T_ = ' '
EndSql
		
While (_cAliasSRA)->(!Eof()) 
	SRA->(DBGoTo((_cAliasSRA)->SRA_RECNO))

	If oProc <> Nil 
		oProc:cCaption:=("Sinc. Funcionario: " + SRA->RA_MAT + " " + AllTrim(SRA->RA_NOMECMP))
		ProcessMessages()
	EndIf
	
	MPON002SIN(_lInclui,_lModifica,_lDemite,nCad)

	(_cAliasSRA)->(DBSkip())
EndDo

(_cAliasSRA)->(DBCloseArea())

Return
