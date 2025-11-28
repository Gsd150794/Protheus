/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Josué Danich  |17/01/2019| Chamado 27727. Revisão de código para servidor lobo-guara
Lucas Borges  |27/09/2019| Chamado 28346. Revisão de fontes.
Lucas Borges  |03/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25.
==============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: AGLT053
Autor-----------: Alex Wallauer
Data da Criacao-: 22/12/2010
Descrição-------: CADASTRO DA Tabela de Frete T1 (1º Percurso)- CHAMADO 22197
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function AGLT053()

Private aSize		:= MsAdvSize()
Private aInfo		:= { aSize[1] , aSize[2] , aSize[3] , aSize[4] , 3 , 3 }
Private aRotina		:= MenuDef()
Private cCadastro	:= "Tabela de Frete T1 (1º Percurso)"

DBSelectArea("ZFF")
ZFF->( DBSetOrder(1) )
MBrowse( ,,,, "ZFF" )

Return

/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 02/08/2018
Descrição---------: Utilizacao de Menu Funcional
Parametros--------: aRotina
					1. Nome a aparecer no cabecalho
					2. Nome da Rotina associada
					3. Reservado
					4. Tipo de Transa‡„o a ser efetuada:
						1 - Pesquisa e Posiciona em um Banco de Dados
						2 - Simplesmente Mostra os Campos
						3 - Inclui registros no Bancos de Dados
						4 - Altera o registro corrente
						5 - Remove o registro corrente do Banco de Dados
					5. Nivel de acesso
					6. Habilita Menu Funcional
Retorno-----------: Array com opcoes da rotina
===============================================================================================================================
*/
Static Function MenuDef()

Local aRotina := {	{ "Pesquisar"		, "AxPesqui" 		, 0 , 1 } ,;
					{ "Visualizar"		, "U_AGLT053R" 		, 0 , 2 } ,;
					{ "Incluir"			, "U_AGLT053R" 		, 0 , 3 } ,;
					{ "Alterar"			, "U_AGLT053R" 		, 0 , 4 } ,;
					{ "Excluir"			, "U_AGLT053R"		, 0 , 5 }  }

Return( aRotina )

/*
===============================================================================================================================
Programa----------: AGLT053R
Autor-------------: Alex Wallauer
Data da Criacao---: 23/05/2018  
Descrição---------: Monta tela com os dados do RPA Avulso
Parametros--------: nOpc: opcao
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT053R(cAlias,nReg,nOpc)

Local bCampo			:= {|nCPO| Field(nCPO) }
Local vCampos			:= {} // campos de visuzaliacao
Local _cOpcao			:= ""
Local _nI				:= 0
Local nUsado			:= 0
Local cAliasEnchoice	:= "ZFF"
Local cLinOk        	:= "AllwaysTrue()"
Local cTudOk        	:= "AllwaysTrue()"

Private oDlg			:= ""
Private xVarAux	 		:= Nil

Private aHeader	 		:= {}
Private aCols	 		:= {}
Private aGets	 		:= {}
Private aTela	 		:= {}

nOpcG:=nOpc

If nOpc == 3 // Incluir
	_cOpcao	:= "Inserção"
ElseIf nOpc == 2 // Visualizar
	_cOpcao	:= "Visualização"
ElseIf nOpc == 4 // Alteração
	_cOpcao	:= "Alteração"
Else // Excluir
	_cOpcao	:= "Exclusão"
EndIf

//================================================================================
//| Cria variaveis M->????? da Enchoice                                          |
//================================================================================
aCpoEnchoice := {}

_aZFF := ZFF->(Dbstruct())

For _nI := 1 To Len(_aZFF)

	_cx3_relacao := getsx3cache(_aZFF[_nI][1],"X3_RELACAO")
	_cx3_context := getsx3cache(_aZFF[_nI][1],"X3_CONTEXT")

	aAdd( aCpoEnchoice , _aZFF[_nI][1] )

	xVarAux	:= "M->"+ _aZFF[_nI][1]
	&xVarAux	:= CriaVar( _aZFF[_nI][1] )
	
	If AllTrim(_cx3_context ) == "V"
		aAdd( vCampos , { _aZFF[_nI][1] , _cx3_relacao } )
	EndIf
	
Next _nI


If nOpc <> 3 // se nao For inclusao preenche os campos do cabecalho

	DBSelectArea("ZFF")
	
	For _nI := 1 TO FCount()
		M->&( EVAL( bCampo , _nI ) ) := FieldGet( _nI )
	Next _nI
	
	For _nI := 1 To Len( vCampos ) // CAMPOS DE VISUALIZACAO
		xVarAux	:= "M->"+ vCampos[_nI,1]
		&xVarAux	:= &( vCampos[_nI,2] )
	Next _nI
	
EndIf

//================================================================================
//| Cria aHeader e aCols da GetDados                                             |
//================================================================================
_aZFG := ZFG->(Dbstruct())

For nUsado := 1 to Len(_aZFG)

	If _aZFG[nUsado][1] != "ZFG_FILIAL" .And. _aZFG[nUsado][1] != "ZFG_CODIGO"

		aAdd( aHeader , {	trim(getsx3cache(_aZFG[nUsado][1],"X3_TITULO") )	,;
							getsx3cache(_aZFG[nUsado][1],"X3_CAMPO")		,;
							getsx3cache(_aZFG[nUsado][1],"X3_PICTURE")		,;
							getsx3cache(_aZFG[nUsado][1],"X3_TAMANHO")		,;
							getsx3cache(_aZFG[nUsado][1],"X3_DECIMAL")		,;
							getsx3cache(_aZFG[nUsado][1],"X3_VALID")		,;
							getsx3cache(_aZFG[nUsado][1],"X3_USADO")		,;
							getsx3cache(_aZFG[nUsado][1],"X3_TIPO")			,;
							getsx3cache(_aZFG[nUsado][1],"X3_ARQUIVO")		,;
							getsx3cache(_aZFG[nUsado][1],"X3_CONTEXT")	})
							
	EndIf

Next

nUsado := Len(_aZFG)-2

DBSelectArea("ZFF")

//================================================================================
//| Preenche o aCols da GetDados                                                 |
//================================================================================
If nOpc == 3 // Incluir

	aCols	:= { Array( nUsado + 1) }
  	aCols[01][nUsado+1]	:= .F.
	aCols[01][01] := "001"
	
	For _nI := 2 to nUsado
		aCols[01][_nI]	:= 0//CriaVar( aHeader[_nI][02] )
	Next _nI
	
	
Else

	aCols	:= {}
	
	ZFG->( DBSetOrder(1) )
	If ZFG->( DBSeek( ZFF->ZFF_FILIAL + ZFF->ZFF_CODIGO ) )
	
		While ZFG->(!Eof()) .And. ZFG->( ZFG_FILIAL + ZFG_CODIGO ) == xFilial("ZFG") + ZFF->ZFF_CODIGO
		
			aAdd( aCols , Array( nUsado + 1 ) )
			
			For _nI := 1 To nUsado
				aCols[Len(aCols)][_nI] := IIf( aHeader[_nI][10] # "V" , ZFG->( FieldGet( FieldPos( aHeader[_nI][02] )) ) , CriaVar( aHeader[_nI][02] ) )
			Next _nI
			
  			aCols[Len(aCols)][nUsado+1] := .F.
			
		ZFG->( DBSkip() )
		EndDo
		
	Else
	
		aCols:= { Array( nUsado + 1 ) }
  		aCols[01][nUsado+1]	:= .F.
		aCols[1,1] := "001"
		
		For _nI := 2 To nUsado
			aCols[1,_nI] := 0
		Next _nI
		
	EndIf 
	
EndIf

//================================================================================
//| Monta a tela para exibição                                                   |
//================================================================================
While .T.

	aSize    := MsAdvSize()
	aObjects := {}
	aAdd( aObjects, { 100, 100, .T., .T. } )
	aAdd( aObjects, { 100, 100, .T., .T. } )
	
	aInfo   := { aSize[ 1 ],aSize[ 2 ],aSize[ 3 ],aSize[ 4 ],03,03 }
	aPosObj := MsObjSize( aInfo, aObjects )
	
	DEFINE MSDIALOG oDlg TITLE cCadastro From aSize[7],0 to aSize[6],aSize[5] PIXEL
	
		EnChoice( cAliasEnchoice , nReg , nOpcG ,,,, aCpoEnchoice , aPosObj[1] ,, 3 ,,,,,, .F. )
		
		MsGetDados():New(aPosObj[2,1],aPosObj[2,2],aPosObj[2,3],aPosObj[2,4],nOpcG,cLinOk,cTudOk,"+ZFG_SEQ",.T.,,,,)
		
	ACTIVATE MSDIALOG oDlg CENTERED ON INIT EnchoiceBar( oDlg , {|| IIf( Obrigatorio(aGets,aTela) .And. AGLT053V(nOpcG) ,;
	                                                                     AGLT053G(oDlg) , ) } , {|| oDlg:End() , RollBackSX8() } ,,  )
    
    Exit
    
EndDo

Return

/*
===============================================================================================================================
Programa----------: AGLT053V
Autor-------------: Alex Wallauer
Data da Criacao---: 23/05/2018
Descrição---------: Validação dos dados preenchidos
Parametros--------: iopc: opcao
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT053V( iopc )

Local _lRet		:= .T. , I

If iopc == 3 .Or. iopc = 4
	                                                              //DELETADO
	If _lRet .And. ( Len(aCols) = 0 .Or. ( Len(aCols) == 1 .And. ( aCols[1,Len(aCols[1])]  .Or. (aCols[1,2] = 0 .Or. aCols[1,3] = 0) )  ))
          
		MsgStop("Favor informar pelo uma faixa de frete com valores.","AGLT05301")
  		_lRet := .F.
		
	EndIf
	
    _nFaixa:=0
	For I := 1 To Len( aCols )
	    If !aCols[I,Len(aCols[I])]//Se não é DELETADO
           If aCols[I,2] <= 0 .Or. aCols[I,3]  <= 0
		      MsgStop("KM e Preço da sequencia "+aCols[I,1]+" deve ser informado","AGLT05302")
  		      _lRet := .F.
           EndIf
           If _nFaixa <> 0 .And. aCols[I,2] <= _nFaixa
		      MsgStop("Faixa da sequencia "+aCols[I,1]+" menor ou igual a anterior As faixas 'KM Ate' tem que ir aumentando da primeira sequencia ate a ultima","AGLT05303")
  		      _lRet := .F.
           EndIf
           _nFaixa:=aCols[I,2]
        EndIf
    Next
EndIf

Return( _lRet )

/*
===============================================================================================================================
Programa----------: AGLT053G
Autor-------------: Alex Wallauer
Data da Criacao---: 23/05/2018   
Descrição---------: Grava dados do cabecalho e itens do RPA AVULSO
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT053G(oDlg)

Local _nX := 0

//================================================================================
//| Quando não For consulta                                                      |
//================================================================================
If nOpcG # 2

	Begin Transaction
	
	DBSelectArea("ZFF")
	ZFF->( DBSetOrder(1) )
	
	lProcura := ZFF->( DBSeek( xFilial("ZFF") + M->ZFF_CODIGO ) )
	
	If nOpcG # 5
	
		ZFF->( RecLock( "ZFF" , If( lProcura , .F. , .T. ) ) )
		
		ZFF->ZFF_FILIAL  := xFilial("ZFF")
		AVREPLACE("M","ZFF")
		ZFF->( MSUnLock() )
		
		If Inclui
			ConfirmSx8()
		EndIf
		
	Else
	
		ZFF->( RecLock( "ZFF" , .F. ) )
		ZFF->( DBDelete() )
		ZFF->( MSUnLock() )
	
	//================================================================================
	//| Deleta todos os itens                                                        |
	//================================================================================
		ZFG->( DBSetOrder(1) )
		
		lProcura := ZFG->( DBSeek( xFilial("ZFG") + M->ZFF_CODIGO ) )
		
		While ( ZFG->(!Eof()) .And. ( xFilial("ZFG") + ZFG->ZFG_CODIGO == xFilial("ZFG") + M->ZFF_CODIGO ) )
			
			ZFG->( RecLock("ZFG",.F.,.T.) )
			ZFG->( DBDelete() )
			ZFG->( MSUnLock() )
			ZFG->( DBSkip() )
			
		EndDo
		
	EndIf
	
	//================================================================================	
	//| Grava os itens                                                               |
	//================================================================================
	For _nX := 1 To Len( aCols )
	
		ZFG->( DBSetOrder(1) )
		
		lProcura := ZFG->( DBSeek( xFilial("ZFG") + M->ZFF_CODIGO + aCols[_nX][01] ) )
		
		If nOpcG # 5
		
			If aCols[_nX,Len(aCols[_nX])] .And. lProcura // exclusao
			
				ZFG->(RecLock("ZFG",.F.,.T.))
				ZFG->(dbdelete())
				ZFG->(MSUnLock())
				
			Else
			
				If !aCols[_nX,Len(aCols[_nX])]  
				
					ZFG->( RecLock( "ZFG" , IIf( lProcura , .F. , .T. ) ) )
					ZFG->ZFG_FILIAL   := xFilial("ZFG")
					ZFG->ZFG_CODIGO   := M->ZFF_CODIGO
					ZFG->ZFG_SEQ      := aCols[_nX][01]
					ZFG->ZFG_KM_ATE   := aCols[_nX][02]
					ZFG->ZFG_KMPREC   := aCols[_nX][03]
					ZFG->( MSUnLock() )
					
					If Inclui
						ConfirmSx8()
					EndIf
					
				EndIf
				
			EndIf
			
		EndIf
		
	Next _nX
	
	//================================================================================
	//| Finaliza a transacao                                                         |
	//================================================================================
	End Transaction

    MsgInfo("Dados gravados com sucesso!","AGLT05304")

EndIf

oDlg:End()

Return( .T. )
