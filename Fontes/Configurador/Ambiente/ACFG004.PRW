#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: ACFG004
Autor-------------: Josué Danich Prestes
Data da Criacao---: 24/09/2015
Descrição---------: Cadastro de usuários x filiais x armazéns - Chamado 12079
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ACFG004()

// VARIAVEIS DE VISUALIZACAO DA TELA
Private aObjects    := {}
Private aPosObj     := {}
Private aSize       := MsAdvSize()
Private aInfo       := { aSize[1] , aSize[2] , aSize[3] , aSize[4] , 3 , 3 }
Private lMsErroAuto := .F. 
Private _lCopia := .F.

//VERIFICA PERMISSÃO DE ACESSO
_lAcesso := U_ITVACESS( 'ZZL' , 3 , 'ZZL_USRFIL' , "S" )

If !_lAcesso

//									|....:....|....:....|....:....|....:....|
	ShowHelpDlg( 'Atenção!' ,	{	'Usuário sem acesso à rotina de usuários '	,;
									'xfiliaisxarmazéns Italac!'						} , 2 ,;
								{	'Caso necessário solicite a manutenção à '		,;
									'um usuário com acesso ou, se necessário, '		,;
									'solicite o acesso à área de TI/ERP.'			} , 3  )
	
	Return
	
EndIf

// pega tamanhos das telas
aAdd( aObjects , { 100 , 050 , .T. , .F. , .F. } )
aAdd( aObjects , { 100 , 100 , .T. , .T. , .F. } )
aPosObj := MsObjSize( aInfo , aObjects )

//Variaveis privadas usadas no modelo 3
SetPrvt("aRotina,CCADASTRO,CALIAS")
SetPrvt("NOPCE,NOPCG,NUSADO")
SetPrvt("CTITULO,CALIASENCHOICE,CLINOK,CTUDOK,CFIELDOK")
SetPrvt("NREG,NOPC")

nOpc:=0

aRotina := {{ OemToAnsi("Pesquisar")  ,"axPesqui"		, 0 , 1		},; // Pesquisar
            { OemToAnsi("Visualizar") ,'U_ACFG004CAD(2)'	, 0 , 2		},; // Visualizar
            { OemToAnsi("Incluir")    ,'U_ACFG004CAD(3)'	, 0 , 3		},; // Incluir
            { OemToAnsi("Alterar")    ,'U_ACFG004CAD(4)'	, 0 , 4 , 2	},; // Alterar
            { OemToAnsi("Excluir")    ,'U_ACFG004CAD(5)'	, 0 , 5 , 1	},; // Excluir
            { OemToAnsi("Copiar")     ,'U_ACFG004CAD(6)'	, 0 , 6 , 3	}}  // Copiar
            
//Define o cabecalho da tela de atualizacoes
cCadastro := OemToAnsi("Gestão de usuários x filiais x armazéns")
cAlias := "Z14"

//Endereca a funcao de BROWSE
mBrowse(6, 1,22,75,cAlias,,,,,,)

Return

/*
===============================================================================================================================
Programa----------: ACFG004CAD
Autor-------------: Josué Danich Prestes
Data da Criacao---: 24/09/2015
Descrição---------: Rotina de controle do cadastro e manutenção dos dados.   
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ACFG004CAD( nOpc )

Local aButtons  := {} , _nni
Local bCampo    := { |nCPO| Field(nCPO) }

Private aTELA[0][0],aGETS[0]
Private AHEADER := {}, ACOLS := {}

nReg := 0
aGets := {}
aTela := {}
SetPrvt("wVar")                   

_lcopia := .F.

If  nOpc == 3	  // Incluir
	nOpcE := 3
	nOpcG := 3 
ElseIf nOpc == 4 	// Alterar
	nOpcE := 4
	nOpcG := 4
ElseIf nOpc == 2 	// Visualizar
	nOpcE := 2
	nOpcG := 2
ElseIf nOpc == 6   // Copiar
	nOpcE := 3
	nOpcG := 3 
	_lcopia := .T.
Else                // Excluir
	nOpcE := 5
	nOpcG := 5
EndIf

//| Cria variaveis M->????? da Enchoice                          |
aCpoEnchoice  :={}
_astruct := Z14->(Dbstruct())

For _nni := 1 to Len(_astruct)
	
	aAdd( aCpoEnchoice , AllTrim(_astruct[_nni][1]) )
	
	wVar	:= "M->"+ AllTrim(_astruct[_nni][1])
	&wVar	:= CriaVar( AllTrim(_astruct[_nni][1]) ) // executa x3_relacao

Next _nni

If nOpc # 3  //se nao For inclusao 

	DBSelectArea("Z14")
	
	For _nni := 1 TO FCount()
		M->&(EVAL(bCampo,_nni)) := FieldGet(_nni)
	Next _nni
	
EndIf

If nOpc == 6    //se For cópia

  M->Z14_USER := "                         "
  M->Z14_NOME := "                              "
  M->Z14_CODUSU := "      "
 
EndIf 

//Log de utilização
U_ITLOGACS()

//| Executa a Modelo 2                                           |
cTitulo			:= OemToAnsi("Cadastro de Usuarios")
cAliasEnchoice	:= "Z14"
cTudOk			:= "AllwaysTrue()"
cFieldOk		:= ""

nOpca := 0

DEFINE MSDIALOG oDlg2 TITLE cTitulo From 9,0 to 35,170	of oMainWnd

	oMsMGet:=MsMGet():New(cAliasEnchoice,nReg,nOpcE,,,,aCpoEnchoice,{15,aPosObj[2,2],aPosObj[2,3],aPosObj[2,4]},,3,,,,,,.F.)

	oDlg2:lMaximized:=.T.
	
ACTIVATE MSDIALOG oDlg2 ON INIT (EnchoiceBar(oDlg2,{|| If(obrigatorio(aGets,aTela),ACFG004GRA(),.F.),nOpca := 1},{||oDlg2:End()},,aButtons) , oMsMGet:oBox:Align:=CONTROL_ALIGN_ALLCLIENT )

Return

/* 
===============================================================================================================================
Programa----------: ACFG004GRA 
Autor-------------: Josué Danich Prestes
Data da Criacao---: 24/09/2015
Descrição---------: Funcao de Gravacao     
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ACFG004GRA()

Local x				:= 0
Local _lVldInc 		:= .T.

Private lMsHelpAuto := .T.
Private lMsErroAuto := .F.

//Caso esteja realizando uma inclusao valida se o usuario ja nao possui cadastro
If Inclui
	
	_lVldInc:= U_ACFG004VLD()	

EndIf

If nOpcG # 2 .And. _lVldInc // nao For consulta
    

	If Inclui .Or. Altera .Or. _lCopia
	
		RecLock( "Z14" , If( Altera , .F. , .T. ) )
		
		Z14->Z14_FILIAL := xFilial("Z14")
		
		For x:=1 to Len(aCpoEnchoice)
		
			wVar := "M->"  + aCpoEnchoice[x]
			ax   :="Z14->" + aCpoEnchoice[x]
			
			If (Posicione("SX3",2,aCpoEnchoice[x],"X3_CONTEXT")!="V")
	
				&ax := &wVar
	
			EndIf
			
		Next x

		MSUnLock()

		If Inclui .Or. Altera .Or. _lCopia
	
			ConfirmSx8()
	
		EndIf
		
	Else  // exclusao

			RecLock("Z14",.F.)
			dbdelete()
			MSUnLock()
			WriteSx2("Z14")  
		
	EndIf
	
EndIf

If _lVldInc

	oDlg2:End()

EndIf

Return(.T.)

/*
===============================================================================================================================
Programa----------: ACFG004VLD
Autor-------------:Josué Danich Prestes 
Data da Criacao---: 24/09/2015
Descrição---------: Valida dados antes da inclusão do usuário
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ACFG004VLD() 

Local _lRet:= .T.
Local _npos := Z14->( Recno() )

DBSelectArea("Z14") 
Z14->(DBSetOrder(1))

If  Z14->(DBSeek(xFilial("Z14") + M->Z14_CODUSU +M->Z14_FILACE))

	_lRet:= .F.                                                                                                 
	
	Alert("O usuário: " + IIf(PSWSEEK(M->Z14_CODUSU),PSWRET(1)[1,4]," ")   + " já está cadastrado para essa filial de acesso!")

EndIf

Z14-> ( DBGoTo( _npos ) )

Return _lRet

/*
===============================================================================================================================
Programa----------: ACFG004R
Autor-------------: Josué Danich Prestes
Data da Criacao---: 24/09/2015
Descrição---------: Retorna nome completo do usuário
Parametros--------: _ccodusu - código do usuário no configurador padrão
Retorno-----------: _cNome - nome completo do usuário
===============================================================================================================================
*/
User Function ACFG004R(_ccodusu)

Local _cNome := ""

_cNome := FWSFAllUsers({_ccodusu},{"USR_NOME"})[1][3]

Return _cNome

/*
===============================================================================================================================
Programa----------: ACFG004E
Autor-------------: Josué Danich Prestes
Data da Criacao---: 24/09/2015
Descrição---------: Valida filial x usuário x armazém
Parametros--------: _ccodusu - código do usuário no configurador padrão
					_cfilace - filial sendo acessada
					_carma - armazém em uso
					_cproduto - produto em uso
					_lmens - apresenta mensagem de erro ou não
					_cmens - string com armazéns que já apresentaram mensagem de bloqueio
Retorno-----------: _aRet[1] - Lógico liberando ou não o uso do armazém
				    _aRet[2] - String com armazéns bloqueados
===============================================================================================================================
*/
User Function ACFG004E(_ccodusu, _cfilace, _carma,_cproduto,_lmen)

Local _lRet 		:= .T.
Local _nI 			:= 1
Local _aarmaz		:= {}
Local _aRet 		:= {}
Local _cmens		:= ""
Local _cTipos       := ""
Default _lmen		:= .F.

DBSelectArea("Z14")
Z14->( DBSetOrder(1) )
	
If Z14->( DBSeek( xFilial("Z14") + AllTrim(_ccodusu)+ _cfilace ) ) 

   If Z14->(FIELDPOS("Z14_TIPO")) <> 0 .And. !Empty(Z14->Z14_TIPO)
	  _cTipos:= AllTrim(Z14->Z14_TIPO)
   EndIf	
   _cTpProd:=Posicione("SB1",1,xFilial("SB1")+_cproduto,"B1_TIPO")

	//se achou usuário e filial de acesso pesquisa para ver se armazém está liberado
	If Empty(_cTipos)
	   If !(_carma $ AllTrim(Z14->Z14_LOCAL)) //Armazens dos produtos acabados
		
		    //Se For PA marca o produto x armazém como acesso restrito
		    If _cTpProd = "PA"
		    	If aScan(_aarmaz, _carma ) == 0
		    		aAdd(_aarmaz, _carma+" e "+_cTpProd )
		    	EndIf
		    	_lRet := .F.
		    EndIf
		EndIf
	Else
	   If !(_carma $ AllTrim(Z14->Z14_LOCAL)) //Armazens dos produtos acados
			
			If aScan(_aarmaz, _carma ) == 0
				aAdd(_aarmaz, _carma+" e / ou "+_cTpProd  )
			EndIf
			_lRet := .F.
		Else
		   If !_cTpProd $ _cTipos
			   If aScan(_aarmaz, _carma ) == 0
				  aAdd(_aarmaz, _carma+" e / ou "+_cTpProd)
			   EndIf
			   _lRet := .F.
		   EndIf

		EndIf

	EndIf
EndIf
 
//apresenta mensagem se teve problemas
If !(_lRet) .And. Len(_aarmaz) > 0 

	_nI := 1
	
	For _nI := 1 to Len(_aarmaz)
	
		If Len(AllTrim(_cmens)) > 0
		
			_cmens += " ,"
			
		EndIf
		
		_cmens += _aarmaz[_nI]
		
	Next
	
	If _lmen
	
		MessageBox( 'Usuário sem acesso ao(s) Armazém / Tipo abaixo nessa filial: ' + CRLF + _cmens + CRLF + CRLF+;
					'Caso necessário solicite a manutenção à um usuário com acesso ou, se necessário, solicite o acesso à área de TI/ERP.' , 'Atenção!' , 48 )
					
	EndIf
			
EndIf

_aRet := { _lRet, _cmens } 
	
Return _aRet
