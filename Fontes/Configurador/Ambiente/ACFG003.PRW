/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |17/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25. 
Alex Wallauer |06/06/2022| Chamado 40380. Novo botão para buscar a matricula do usuario. 
Lucas Borges  |02/10/2025| Chamado 51526. Modificada forma para recuperar a matrícula do usuário.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: ACFG003
Autor-------------: Fabiano Dias
Data da Criacao---: 01/08/2011
Descrição---------: Rotina desenvolvida para realizar o cadastramento dos usuarios que terao acesso para efetuar a aprovacao
					dos pedidos de venda do tipo bonificacao, neste cadastro constara o e-mail dos aprovadores para onde sera
					enviado um e-mail para que ele possa efetuar a aprovacao via workflow ou em uma rotina manual.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ACFG003

// VARIAVEIS DE VISUALIZACAO DA TELA
Private aObjects    := {} As Array
Private aPosObj     := {} As Array
Private aSize       := MsAdvSize() As Array
Private aInfo       := { aSize[1] , aSize[2] , aSize[3] , aSize[4] , 3 , 3 } As Array
Private lMsErroAuto := .F. As Logical
Private _lCopia := .F. As Logical

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
            { OemToAnsi("Visualizar") ,'U_ACFG003CAD(2)'	, 0 , 2		},; // Visualizar
            { OemToAnsi("Incluir")    ,'U_ACFG003CAD(3)'	, 0 , 3		},; // Incluir
            { OemToAnsi("Alterar")    ,'U_ACFG003CAD(4)'	, 0 , 4 , 2	},; // Alterar
            { OemToAnsi("Excluir")    ,'U_ACFG003CAD(5)'	, 0 , 5 , 1	},; // Excluir
            { OemToAnsi("Copiar")     ,'U_ACFG003CAD(6)'	, 0 , 6 , 3	}}  // Copiar
            

cCadastro := OemToAnsi("GESTÃO DO USUÁRIO ITALAC")
cAlias := "ZZL"

//| Endereca a funcao de BROWSE                                  |
mBrowse(6, 1,22,75,cAlias,,,,,,)

Return

/*
===============================================================================================================================
Programa----------: ACFG003CAD
Autor-------------: Fabiano Dias
Data da Criacao---: 01/08/2011
Descrição---------: Rotina de controle do cadastro e manutenção dos dados.   
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ACFG003CAD(nOpc As Numeric)

Local aButtons  := {} As Array
Local bCampo    := { |nCPO| Field(nCPO) } As CodeBlock
Local _nni		:= 0 As Numeric
Local nReg 		:= 0 As Numeric
Private aTela 	:= {} As Array
Private aGets 	:= {} As Array
Private aHeader := {}, ACOLS := {} As Array

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

If nOpcE == 3 .Or. nOpcE == 4 
   aAdd(aButtons, {"Atualiza Matricula" , {|| ACFG003Mat() } , "Atualiza Matricula"})
EndIf

//| Cria variaveis M->????? da Enchoice                          
aCpoEnchoice  :={}
_astruct := ZZL->(Dbstruct())

For _nni := 1 To Len(_astruct)
	aAdd( aCpoEnchoice , AllTrim(_astruct[_nni][1]) )
	wVar	:= "M->"+ AllTrim(_astruct[_nni][1])
	&wVar	:= CriaVar( AllTrim(_astruct[_nni][1]) ) // executa x3_relacao
Next _nni

If nOpc # 3  //se nao For inclusao 
	DBSelectArea("ZZL")
	For _nni := 1 TO FCount()
		M->&(EVAL(bCampo,_nni)) := FieldGet(_nni)
	Next _nni
EndIf

If nOpc == 6    //se For cópia
	M->ZZL_USER := "                         "
	M->ZZL_NOME := "                              "
	M->ZZL_MATRIC := "        "
	M->ZZL_EMAIL := "                                                            "
	M->ZZL_CODUSU := "      "
EndIf 

//| Executa a Modelo 2                                           |
cTitulo			:= OemToAnsi("Cadastro de Usuarios")
cAliasEnchoice	:= "ZZL"
cTudOk			:= "AllwaysTrue()"
cFieldOk		:= ""

nOpca := 0

DEFINE MSDIALOG oDlg2 TITLE cTitulo From 9,0 to 35,170	of oMainWnd
	oEnCh1:=MsMget():New(cAliasEnchoice,nReg,nOpcE,,,,aCpoEnchoice,{15,aPosObj[2,2],aPosObj[2,3],aPosObj[2,4]},,3,,,,,,.F.)
	oDlg2:lMaximized:=.T.
ACTIVATE MSDIALOG oDlg2 ON INIT (EnchoiceBar(oDlg2,{|| If(obrigatorio(aGets,aTela),ACFG003GRA(),.F.),nOpca := 1},{||oDlg2:End()},,aButtons) , oEnch1:oBox:Align:=CONTROL_ALIGN_ALLCLIENT)

Return

/* 
===============================================================================================================================
Programa----------: ACFG003GRA 
Autor-------------: Enilton
Data da Criacao---: 13/12/2005
Descrição---------: Funcao de Gravacao     
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ACFG003GRA() As Logical

Local _lVldInc 		:= .T. As Logical
Local x				:= 0 As Numeric
Private lMsHelpAuto := .T. As Logical
Private lMsErroAuto := .F. As Logical

//Caso esteja realizando uma inclusao valida se o usuario ja nao possui cadastro
If Inclui
	_lVldInc:= U_ACFG003VLD()	
EndIf

If nOpcG # 2 .And. _lVldInc // nao For consulta
	If Inclui .Or. Altera .Or. _lCopia
		ZZL->(RecLock( "ZZL" , If( Altera , .F. , .T. ) ))
		ZZL->ZZL_FILIAL := xFilial("ZZL")
		
		For x:=1 to Len(aCpoEnchoice)
			wVar := "M->"  + aCpoEnchoice[x]
			ax   :="ZZL->" + aCpoEnchoice[x]
			If (Posicione("SX3",2,aCpoEnchoice[x],"X3_CONTEXT")!="V")
				&ax := &wVar
			EndIf
		Next x
		ZZL->(MSUnLock())

		If Inclui .Or. Altera .Or. _lCopia
			ConfirmSx8()
		EndIf
	Else  // exclusao
		ZZL->(RecLock("ZZL",.F.))
		ZZL->(DBDelete())
		ZZL->(MSUnLock())
		WriteSx2("ZZL")  
	EndIf
	
EndIf

If _lVldInc
	oDlg2:End()
EndIf

Return(.T.)

/*
===============================================================================================================================
Programa----------: ACFG003VLD
Autor-------------: 
Data da Criacao---: 
Descrição---------: Valida dados antes da inclusão do usuário
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ACFG003VLD() As Logical

Local _lRet:= .T.

ZZL->(DBSetOrder(3))
If  ZZL->(DBSeek(xFilial("ZZL") + M->ZZL_CODUSU))
	_lRet:= .F.                                                                                                 
	U_ITMsg("O usuário: " + IIf(PSWSEEK(M->ZZL_CODUSU),PSWRET(1)[1,4]," ")   + " já está cadastrado!","Atenção",,1)
EndIf

Return _lRet

/* 
===============================================================================================================================
Programa----------: ACFG003Mat 
Autor-------------: Alex Wallauer
Data da Criacao---: 06/06/2022
Descrição---------: Busca a matriula do usuario novamente 
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ACFG003Mat()

M->ZZL_MATRIC := FWSFAllUsers({ZZL->ZZL_CODUSU},{"USR_FILIAL"})[1][3]+FWSFAllUsers({ZZL->ZZL_CODUSU},{"USR_CODFUNC"})[1][3]
If Empty(M->ZZL_MATRIC)
	U_ITMsg("Usuário informado não tem a matricula informada no módulo configurador do sistema: "+M->ZZL_CODUSU,'Atenção!',"Verifique o código informado.",3) // ALERT
Else
	U_ITMsg("Matricula atualizada com: "+M->ZZL_MATRIC,'Atenção!',,2) // ALERT
EndIf

Return
