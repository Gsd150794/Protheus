/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
       Autor      |    Data    |                              Motivo                                                          
================================================================================================================================
*/
//==============================================================================================================================
// Definicoes de Includes da Rotina.
//==============================================================================================================================
#Include "FWPRINTSETUP.CH"
#Include "TOTVS.ch"
#Include "RPTDEF.CH"
#Include 'TOPCONN.CH'
#Include "TBICONN.CH"
#Include "RWMAKE.CH"

#DEFINE ENTER CHR(13)+CHR(10)
/*
=================================================================================================================================
Programa----------: U_AOMS120()
Autor-------------: Alex Wallauer
Data da Criacao---: 10/12/2020
==================================================================================================================================
Descrição---------: Tabela de Precos para exibicao no portal. CHAMADO 34937
==================================================================================================================================
Parametros--------: Nenhum
==================================================================================================================================
*/
*====================================================*
User Function AOMS120()
*====================================================*
Local _cAlias := "DA0"
Local _aCores := {{ "DA0_ATIVO <> '1' ", "BR_VERMELHO" },;
					   { "DA0_ATIVO == '1'" , "BR_VERDE"   }}  

Private cCadastro:= "Tabela de Precos para exibicao no portal"
Private aRotina		:= {}                

aAdd(aRotina,{"Pesquisar"	       ,"AxPesqui"   ,0,1}) // 1
aAdd(aRotina,{"Visualizar"        ,"U_AOMS120M" ,0,2}) // 2
//aAdd(aRotina,{"Incluir"         ,"U_AOMS120M" ,0,3})
aAdd(aRotina,{"Inclui / Altera"   ,"U_AOMS120M" ,0,4}) // 3
aAdd(aRotina,{"Excluir"           ,"U_AOMS120M" ,0,5}) // 4
//aAdd(aRotina,{"Alteracao em Massa","U_AOMSMASSA",0,4})
aAdd(aRotina,{"Legenda"           ,"U_AOMSLEGE" ,0,7}) 

DBSelectArea(_cAlias)
DBSetOrder(1)


// owse(,,,,cAli>  ,<aFixe, <cCpo>, <nPar>, <cCorFun>, <nClickDef>, <aColors>, <cTopFun>, <cBotFun>, <nPar14>, <bInitBloc>, <lNoMnuFilter>, <lSeeAll>, <lChgAll>, <cExprFilTop>, <nInterval>, <uPar22>, <uPar23> )
mBrowse(,,,,_cAlias,      ,       ,       ,          ,            , _aCores )

Return


/*
===============================================================================================================================
Programa--------: AOMS120M
Autor-----------: Alex Wallauer
Data da Criacao-: 10/12/2020
==================================================================================================================================
Descrição-------: Tabela de Precos para exibicao no portal. MANUTENÇÃO
==================================================================================================================================
Parametros------: cAlias,nReg,_nOpcx
==================================================================================================================================
*/
User Function AOMS120M(cAlias,nReg,_nOpcx)
Local _aObjects, _aPosObj, _aInfo, _oDlgEnch ,_nni, _nnj
Local _aSizeAut := MsAdvSize(.T.)
Local _cTitulo  :=cCadastro
Local _bOk      := {|| If(AOMS120Grv(_nOpcx),(_lRet := .T., _oDlgEnch:End()),)}
Local _bCancel  := {|| _lRet := .F., _oDlgEnch:End()}
Local bCampo    := {|nCPO| Field(nCPO) }

ZZL->(DBSetOrder(3)) //ZZL_FILIAL + ZZL_CODUSU

If !ZZL->(DBSeek(xFilial("ZZL") + __cUserId)) 

	U_ITMsg("O usuário: " + cUserName + " não possui permissão para executar esta ação neste cadastro.",;
		    "Usuário Sem Acesso",;
		    "Verificar com a área responsavel a possibilidade de habilitar o seu usuário.",1)

	Return .F.	    

ElseIf (ZZL->(FIELDPOS("ZZL_TABPRD")) <> 0 .And. !DA0->DA0_CODTAB $ ZZL->ZZL_TABPRD) .And. AllTrim(ZZL->ZZL_TABPRD) <> "*"

	U_ITMsg("O usuário: " + cUserName + " não possui permissão para executar esta ação nessa tabela.",;
		    "Usuário Sem Acesso",;
		    "Verificar com a área responsavel a possibilidade de habilitar o seu usuário a mais tabelas alem dessas: "+ ZZL->ZZL_TABPRD,1)

	Return .F.	    

ElseIf (ZZL->(FIELDPOS("ZZL_TABPRD")) = 0 .And. !DA0->DA0_CODTAB $ '100/101/102/103/104/105')

	U_ITMsg("O usuário: " + cUserName + " não possui permissão para executar esta ação nessa tabela.",;
		    "Usuário Sem Acesso",;
		    "Verificar com a área responsavel a possibilidade de habilitar o seu usuário a mais tabelas alem dessas: '100/101/102/103/104/105'",1)

	Return .F.   

EndIf

Private aHeader:= {}
Private aCols  := {}       
Private aTELA  := {} // Variáveis que serão atualizadas pela Enchoice
Private aGETS  := {} // e utilizadas pela função OBRIGATORIO()
Private _lRet  := .F.

DBSelectArea("DA0")//INICIA VARIAVIES DA CAPA
For _nni := 1 TO FCount()
	M->&(EVAL(bCampo,_nni)) := FieldGet(_nni)
Next 


DBSelectArea("ZDA")//INICIA VARIAVIES DOS ITENS
For _nni := 1 TO FCount()
	M->&(EVAL(bCampo,_nni)) := CriaVar(EVAL(bCampo,_nni),.F.)
Next 


//==============================================================================================================
// Montagem do aCols
//==============================================================================================================
//FillGetDados( nOpcx, cAlias, nOrder, cSeekKey, bSeekWhile, uSeekFor, aNoFields, aYesFields, lOnlyYes,cQuery, bMountFile, lInclui )
//nOpcx			- Opcao (inclusao, exclusao, etc).
//cAlias		- Alias da tabela referente aos itens
//nOrder		- Ordem do SINDEX
//cSeekKey		- Chave de pesquisa
//bSeekWhile	- Loop na tabela cAlias
//uSeekFor		- Valida cada registro da tabela cAlias (retornar .T. para considerar e .F. para desconsiderar o registro)
//aNoFields	    - Array com nome dos campos que serao excluidos na montagem do aHeader
//aYesFields	- Array com nome dos campos que serao incluidos na montagem do aHeader
//lOnlyYes		- Flag indicando se considera somente os campos declarados no aYesFields + campos do usuario
//cQuery		- Query para filtro da tabela cAlias (se For TOP e cQuery estiver preenchido, desconsidera parametros cSeekKey e bSeekWhiele)
//bMountFile	- Preenchimento do aCols pelo usuario (aHeader e aCols ja estarao criados)
//lInclui		- Se inclusao passar .T. para qua aCols seja incializada com 1 linha em branco
//aHeaderAux	-
//aColsAux		-
//bAfterCols	- Bloco executado apos inclusao de cada linha no aCols
//bBeforeCols	- Bloco executado antes da inclusao de cada linha no aCols
//bAfterHeader  -
//cAliasQry   	- Alias para a Query
//==============================================================================================================
M->ZDA_CODTAB:=DA0->DA0_CODTAB//Inicia Branco por causa do X3_RELACAO
_lCntrlDescIni:=.T.//Controla de qual campo pega a descrição do item se data tabela ZDA (.T.) ou memoria (.F.)
cSeek  := xFilial("ZDA")+DA0->DA0_CODTAB
lTemItens:=ZDA->(DBSeek(cSeek))
If !lTemItens
   
   If _nOpcx # 3//Imclui/Altera
      U_ITMsg("SEM DADOS. CLIQUE NO BOTAO INCLUI/ALTERA","ATENCAO",,3)
      Return .F.
   EndIf

    nOpc:=3
    FillGetDados(nOpc,"ZDA",1,/*cSeek*/,/*bWhile*/,,/*aNoFields*/,/*aYesFields*/,/*lOnlyYes*/,/*cQuery*/,/*bMontCols*/,.T.,/*aHeaderAux*/,/*aColsAux*/,,/*bBeforeCols*/,/*bAfterHeader*/,)
    
    If U_ITMsg("Nao há dados do Portal para essa tabela, deseja carregar todos os Produtos?",'ATENCAO!',"",3,2,2)
       aCols:={}
       DBSelectArea("ZDA")
       DA1->(DBSetOrder(1))
	    DA1->(DBSeek(DA0->DA0_FILIAL+DA0->DA0_CODTAB))
	    While DA1->(!Eof()) .And. DA1->DA1_FILIAL+DA1->DA1_CODTAB == DA0->DA0_FILIAL+DA0->DA0_CODTAB
       //DA1 TIRA INATIVO OS PRECO ZERADOS
          If DA1->DA1_ATIVO <> "2" 
           
             _lDel := DA1->DA1_PRCVEN = 0 .OR.;
                      DA1->DA1_I_PMFE = 0 .OR.;
                      DA1->DA1_I_PRCA = 0 .OR.;
                      DA1->DA1_I_PRFE = 0 .OR.;
                      DA1->DA1_I_PMFR = 0 

	    	    aAdd(aCols,{ DA1->DA1_CODPRO,;
                          Posicione("SB1",1,xFilial("SB1")+DA1->DA1_CODPRO,"B1_DESC"),;
                          DA1->DA1_PRCVEN,;
                          DA1->DA1_I_PMFE,;
                          DA1->DA1_I_PRCA,;
                          DA1->DA1_I_PRFE,;
                          DA1->DA1_I_PMFR,;
                          DA1->DA1_I_PRCA,;
                          "2",_lDel})
          EndIf

	    	 DA1->(DBSkip())
	    EndDo
    EndIf
Else    
    DBSelectArea("ZDA")//INICIA VARIAVIES DOS ITENS
    bWhile := {|| ZDA_FILIAL+ZDA_CODTAB }
    nOpc:=4
    FillGetDados(nOpc,"ZDA",1,cSeek,bWhile)
EndIf    
_lCntrlDescIni:=.F.//Controla de qual campo pega a descrição do item se data tabela ZDA (.T.) ou memoria (.F.)
nOpc:=_nOpcx

//==============================================================================================================
// Montagem do aHeader na mão para Nao aparecer os campos extras criados pela função FillGetDados
aHeader:= {}                   // cAlias , lVirtual 
_aZDA := FWSX3Util():GetAllFields( "ZDA" , .T.     )
For _NNJ := 1 TO Len(_aZDA)
    _cUsado:=Getsx3cache(_aZDA[_NNJ],"X3_USADO")
    If X3USO(_cUsado)
	    aAdd( aHeader, {  Getsx3cache(_aZDA[_NNJ],"X3_TITULO")  ,;
	                      Getsx3cache(_aZDA[_NNJ],"X3_CAMPO")   ,;
                      	 Getsx3cache(_aZDA[_NNJ],"X3_PICTURE") ,;
	                      Getsx3cache(_aZDA[_NNJ],"X3_TAMANHO") ,;
	                      Getsx3cache(_aZDA[_NNJ],"X3_DECIMAL") ,;
	                      Getsx3cache(_aZDA[_NNJ],"X3_VALID")   ,;
	                      Getsx3cache(_aZDA[_NNJ],"X3_USADO")   ,;
	                      Getsx3cache(_aZDA[_NNJ],"X3_TIPO")	   ,;
	                      Getsx3cache(_aZDA[_NNJ],"X3_ARQUIVO") ,;
                         Getsx3cache(_aZDA[_NNJ],"X3_CONTEXT") })
    EndIf                      
Next
//==============================================================================================================

// Tela de Manutenção
  _aObjects:= {}
aAdd( _aObjects, { 100, 050, .T., .T. } )
aAdd( _aObjects, { 100, 100, .T., .T. } )
_aInfo   := { _aSizeAut[ 1 ], _aSizeAut[ 2 ], _aSizeAut[ 3 ], _aSizeAut[ 4 ], 3, 3 }
_aPosObj := MsObjSize( _aInfo, _aObjects, .T. )
_lDeleta :=(nOpc = 3) //.or. (nOpc = 4))
_aCamposCapa:={}

While .T.
   
   Define MsDialog _oDlgEnch Title _cTitulo From _aSizeAut[7],00 To _aSizeAut[6], _aSizeAut[5] Of oMainWnd Pixel
      
   EnChoice( "DA0" ,nReg, 2, , , ,_aCamposCapa , _aPosObj[1], , 3 )
            
	//        MsGetDados(): New( < nTop>        , < nLeft>    , < nBottom>     , < nRight>,< nOpc>,[ cLinhaOk]     , [ cTudoOk],[ cIniCpos],[ lDeleta],[ aAlter]  , [ nFreeze], [ lEmpty], [ nMax], [ cFieldOk], [ cSuperDel], [ uPar], [ cDelOk], [ oWnd], [ lUseFreeze], [ cTela] )
   _oGetDados := MsGetDados():New(_aPosObj[2,1], _aPosObj[2,2], _aPosObj[2,3], _aPosObj[2,4], nOpc, /*"U_LINHAOK"*/,           ,           ,  _lDeleta, /*aAlter*/,           , .F.      ,        , /*FIELDOK*/, /*SUPERDEL*/,        , /*DELOK*/, _oDlgEnch)
   
   Activate MsDialog _oDlgEnch On Init EnchoiceBar(_oDlgEnch,_bOk,_bCancel) 

   If _lRet .Or. !_lDeleta .Or. U_ITMsg("CONFIRMA SAIR?",'ATENCAO!',"TODAS AS ALTERACOES SERAO PERDIDAS",3,2,2)
      Exit
   EndIf

EndDo

Return 

/*
===============================================================================================================================
Programa--------: AOMS120Grv()
Autor-----------: Alex Wallauer
Data da Criacao-: 10/12/2020
==================================================================================================================================
Descrição-------:  Tabela de Precos para exibicao no portal. GRAVAÇÃO
==================================================================================================================================
Parametros------: cAlias,nReg,_nOpcx
==================================================================================================================================
*/
Static Function AOMS120Grv(_nOpcx)
Local nConIten  ,nConCmp
Local cAliasItm:="ZDA"
Local _nPos1:= aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "ZDA_CODPRO"} )
Local _nPos2:= aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "ZDA_PRCVEN"} )
Local _nPos3:= aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "ZDA_PMINFE"} )
Local _nPos4:= aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "ZDA_PMAXFE"} )
Local _nPos5:= aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "ZDA_PRCFRA"} )
Local _nPos6:= aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "ZDA_PMINFR"} )
Local _nPos7:= aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "ZDA_PMAXFR"} )
Local _nPos8:= aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "ZDA_MSBLQL"} )
Local lTudoOK:=.F.
Local aProd  :={}

ZDA->(DBSetOrder(1))

If _nOpcx = 2//VISUALIZAR
   Return .T.
ElseIf _nOpcx = 4 //EXCLUIR
   If !U_ITMsg("CONFIRMA A EXCLUSAO DE TODOS OS PRODUTOS?",'ATENCAO!',"",3,2,2)
      Return .F.
   EndIf
   BEGIN TRANSACTION
   For nConIten := 1 to Len(aCols)
       If ZDA->(DBSeek(xFilial("ZDA")+M->DA0_CODTAB+aCols[nConIten][_nPos1] ))
	      ZDA->(RecLock("ZDA",.F.))
	      ZDA->(DBDELETE())
	   EndIf   
   Next 
   END TRANSACTION
   U_ITMsg("DADOS EXCUIDOS COM SUCESSO","ATENCAO",,2)
   Return .T.
EndIf

If !U_ITMsg("CONFIRMA  A GRAVAÇÃO?",'ATENCAO!',"",3,2,2)
   Return .F.
EndIf

For nConIten := 1 to Len(aCols)
	If aCols[nConIten][Len(aCols[nConIten])]//DELETADOS
      Loop
   EndIf	    
	If  !Empty(aCols[nConIten][_nPos1]) .AND.;
	    !Empty(aCols[nConIten][_nPos2]) .AND.;
	    !Empty(aCols[nConIten][_nPos3]) .AND.;
	    !Empty(aCols[nConIten][_nPos4]) .AND.;
	    !Empty(aCols[nConIten][_nPos5]) .AND.;
	    !Empty(aCols[nConIten][_nPos6]) .AND.;
	    !Empty(aCols[nConIten][_nPos7]) .AND.;
	    !Empty(aCols[nConIten][_nPos8])
        
       If aScan(aProd,aCols[nConIten][_nPos1]) = 0
	       aAdd(aProd,aCols[nConIten][_nPos1])
	    Else   
          lTudoOK:=.F.
	       U_ITMsg("Produto: "+aCols[nConIten][_nPos1]+" Repetido.","ATENCAO",;
	               "Apague ou Altere o codigo do produto da linha: "+AllTrim(Str(nConIten)),1)
	       Exit
	    EndIf   
        
        lTudoOK:=.T.  
        
    Else
        lTudoOK:=.F.
	     U_ITMsg("Produto: "+aCols[nConIten][_nPos1]+" com Preco zerado.","ATENCAO",;
	             "Apague ou Altere o codigo do produto da linha: "+AllTrim(Str(nConIten)),1)
        Exit
    EndIf    
Next

If !lTudoOK
   n:=nConIten
	//U_ITMsg("É necessário informar Produtos antes da gravação.","ATENCAO",;
	//        "Insira produtos validos, Nao repetidos e preencha todos os campos obrigatorios da linha",1)
	Return .F.
EndIf

BEGIN TRANSACTION

// Gravacao dos Itens
DBSelectArea("ZDA")
For nConIten := 1 to Len(aCols)
	
	// Valida se o registro nao esta deletado
	If !aCols[nConIten][Len(aCols[nConIten])]//DELETADOS

      If ZDA->(DBSeek(xFilial("ZDA")+M->DA0_CODTAB+aCols[nConIten][_nPos1] ))
		   ZDA->(RecLock("ZDA",.F.))
		Else
		   ZDA->(RecLock("ZDA",.T.))
		EndIf   
		For nConCmp := 1 to Len(aHeader)
			If (aHeader[nConCmp,10] <> "V")
				FieldPut(FieldPos(aHeader[nConCmp,2]), aCols[nConIten, nConCmp])
			EndIf
		Next 
		(cAliasItm)->ZDA_FILIAL := xFilial("ZDA")
		(cAliasItm)->ZDA_CODTAB := M->DA0_CODTAB	
	   (cAliasItm)->(MSUnLock())
    Else
      If ZDA->(DBSeek(xFilial("ZDA")+M->ZDA_CODTAB+aCols[nConIten][_nPos1] ))
	      ZDA->(RecLock("ZDA",.F.))
	      ZDA->(DBDELETE())
	   EndIf   
	EndIf

Next 

END TRANSACTION

U_ITMsg("DADOS GRAVADOS COM SUCESSO","ATENCAO",,2)

Return .T.
/*
=================================================================================================================================
Programa----------: U_AOMSMASSA()
Autor-------------: Alex Wallauer
Data da Criacao---: 10/12/2020
==================================================================================================================================
Descrição---------: Alteraçao em massa
==================================================================================================================================
Parametros--------: Nenhum
==================================================================================================================================

User Function AOMSMASSA()

U_ITMsg("EM ANALISE PARA DESENVOLVIMENTO",'ATENCAO!',"ME PASSA OS FILTROS CERTINHO QUE JÁ TENHO UMA IDEIA",1)

Return .T.
/*
=================================================================================================================================
Programa----------: AOMSLEGE
Autor-------------: Alex Wallauer
Data da Criacao---: 10/12/2020
==================================================================================================================================
Descrição---------: Cadastro de Reposição automática de estoque LEGENDA
==================================================================================================================================
Parametros--------: Nenhum
==================================================================================================================================
*/
User Function AOMSLEGE()
   
Local _aLegenda := {{ "BR_VERMELHO","Bloqueado" },;
                 	  { "BR_VERDE"   ,"Ativo"  } }
                 
BRWLEGENDA(cCadastro, "Legenda", _aLegenda )
   
Return 
/*
=================================================================================================================================
Programa----------: U_AOMS120Val()
Autor-------------: Alex Wallauer
Data da Criacao---: 10/12/2020
==================================================================================================================================
Descrição---------: Validação de todos os campos
==================================================================================================================================
Parametros--------: Nenhum
==================================================================================================================================
*/
User Function AOMS120Val(_lValid)//U_AOMS120Val()
Local _cCampo	:= Upper(AllTrim(ReadVar()))
Local _nPos1:= aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "ZDA_CODPRO"} )
Local _nPos2:= aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "ZDA_PRCVEN"} )//
Local _nPos3:= aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "ZDA_PMINFE"} )
Local _nPos4:= aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "ZDA_PMAXFE"} )
Local _nPos5:= aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "ZDA_PRCFRA"} )//
Local _nPos6:= aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "ZDA_PMINFR"} )
Local _nPos7:= aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "ZDA_PMAXFR"} )

DEFAULT _lValid := .T.

If !_lValid
   If _lCntrlDescIni //Controla de qual campo pega a descrição do item se data tabela Z20 (.T.) ou memoria (.F.)
      If !Inclui
         Return AllTrim(Posicione("SB1",1,xFilial("SB1")+ZDA->ZDA_CODPRO,"B1_DESC"))
      EndIf
   EndIf   
   Return " "
EndIf   
/*
If "ZDA_CODTAB" $ _cCampo

   If !DA1->(DBSeek(xFilial("DA1")+M->ZDA_CODTAB)) .Or. !DA0->(DBSeek(xFilial("DA0")+M->ZDA_CODTAB)) .Or. DA0->DA0_ATIVO <>'1'
      U_ITMsg("A tabela deve existir na tabela de Precos oficial e ATIVA",'ATENCAO!',"",1)
      Return .F.
   EndIf*/
If "ZDA_CODPRO" $ _cCampo .And. !Empty(M->ZDA_CODPRO)

   If !DA1->(DBSeek(xFilial("DA1")+M->DA0_CODTAB+M->ZDA_CODPRO)) .Or. DA1->DA1_ATIVO <> '1'
      U_ITMsg("O produto inserido na tabela deve existir na tabela de Precos oficial e ATIVO",'ATENCAO!',"",1)
      Return .F.
   EndIf
// If ZDA->(DBSeek(xFilial()+M->DA0_CODTAB+M->ZDA_CODPRO)) 
//    U_ITMsg("Tabela + Produto já cadastrados",'ATENCAO!',"",1)
//    Return .F.
// EndIf

   DA1->(DBSetOrder(1))
   DA1->(DBSeek(xFilial("DA1")+M->DA0_CODTAB+M->ZDA_CODPRO))

   M->ZDA_PRCVEN   := DA1->DA1_PRCVEN
   M->ZDA_PMINFE   := DA1->DA1_I_PMFE
   M->ZDA_PMAXFE   := DA1->DA1_I_PRCA
   M->ZDA_PRCFRA   := DA1->DA1_I_PRFE
   M->ZDA_PMINFR   := DA1->DA1_I_PMFR
   M->ZDA_PMAXFR   := DA1->DA1_I_PRCA
	aCols[n][_nPos2]:= M->ZDA_PRCVEN 
	aCols[n][_nPos3]:= M->ZDA_PMINFE 
	aCols[n][_nPos4]:= M->ZDA_PMAXFE 
	aCols[n][_nPos5]:= M->ZDA_PRCFRA 
	aCols[n][_nPos6]:= M->ZDA_PMINFR 
	aCols[n][_nPos7]:= M->ZDA_PMAXFR 
   Return .T.
EndIf

DA1->(DBSetOrder(1))
DA1->(DBSeek(xFilial("DA1")+M->DA0_CODTAB+aCols[n][_nPos1]))

If "ZDA_PRCVEN" $ _cCampo//ZDA_PRCVEN: Deve ser maior que zero e Nao pode ser menor que o campo DA1_PRCVEN

   If M->ZDA_PRCVEN <= 0 .Or. M->ZDA_PRCVEN < DA1->DA1_PRCVEN .Or. M->ZDA_PRCVEN > DA1->DA1_I_PRCA 
      U_ITMsg("Valor invalido. Deve ser maior que zero",'ATENCAO!',"Nao pode ser menor que o campo (DA1_PRCVEN) "+AllTrim(Str(DA1->DA1_PRCVEN,11,2))+ENTER+;
                                                                   "Nao pode ser maior que o campo (DA1_I_PRCA) "+AllTrim(Str(DA1->DA1_I_PRCA,11,2)),1)
      Return .F.
   Else
      If M->ZDA_PRCVEN < aCols[n][_nPos3]//minimo
   	   aCols[n][_nPos3]:= M->ZDA_PRCVEN 
      EndIf
      If M->ZDA_PRCVEN > aCols[n][_nPos4]//maximo
	      aCols[n][_nPos4]:= M->ZDA_PRCVEN
      EndIf
   EndIf

ElseIf "ZDA_PMINFE" $ _cCampo//ZDA_PMINFE: Deve ser maior que zero e Nao pode ser menor que o campo DA1_I_PMFE

   If M->ZDA_PMINFE <= 0 .Or. M->ZDA_PMINFE < DA1->DA1_I_PMFE .Or. M->ZDA_PMINFE > aCols[n][_nPos2]
      U_ITMsg("Valor invalido. Deve ser maior que zero.",'ATENCAO!',"Nao pode ser menor que o campo (DA1_I_PMFE) "+AllTrim(Str(DA1->DA1_I_PMFE,11,2))+ENTER+;
                                                                    "Nao pode ser maior que o Preco carga fechada (ZDA_PRCVEN) "+AllTrim(Str(aCols[n][_nPos2],11,2)),1)
      Return .F.
   EndIf

ElseIf "ZDA_PMAXFE" $ _cCampo//ZDA_PMAXFE: Deve ser maior que zero e Nao pode ser maior que o campo DA1_I_PRCA

   If M->ZDA_PMAXFE <= 0 .Or. M->ZDA_PMAXFE > DA1->DA1_I_PRCA .Or. M->ZDA_PMAXFE < aCols[n][_nPos2]
      U_ITMsg("Valor invalido. Deve ser maior que zero.",'ATENCAO!',"Nao pode ser maior que o campo (DA1_I_PRCA) "+AllTrim(Str(DA1->DA1_I_PRCA,11,2))+ENTER+;
                                                                    "Nao pode ser menor que o Preco carga fechada (ZDA_PRCVEN) "+AllTrim(Str(aCols[n][_nPos2],11,2)),1)
      Return .F.
   EndIf

ElseIf "ZDA_PRCFRA" $ _cCampo//ZDA_PRCFRA: Deve ser maior que zero e Nao pode ser menor que o campo DA1_I_PRFE (gatilhar o conteúdo do campo XXX_PRCVEN na inclusão)

   If M->ZDA_PRCFRA <= 0 .Or. M->ZDA_PRCFRA < DA1->DA1_I_PRFE .Or. M->ZDA_PRCFRA > DA1->DA1_I_PRCA  
      U_ITMsg("Valor invalido. Deve ser maior que zero.",'ATENCAO!',"Nao pode ser menor que o campo (DA1_I_PRFE) "+AllTrim(Str(DA1->DA1_I_PRFE,11,2))+ENTER+;
                                                                    "Nao pode ser maior que o campo (DA1_I_PRCA) "+AllTrim(Str(DA1->DA1_I_PRCA,11,2)),1)
      Return .F.
   Else
      If M->ZDA_PRCFRA < aCols[n][_nPos6]//minimo
   	   aCols[n][_nPos6]:= M->ZDA_PRCFRA 
      EndIf
      If M->ZDA_PRCFRA > aCols[n][_nPos7]//maximo
	      aCols[n][_nPos7]:= M->ZDA_PRCFRA
      EndIf
   EndIf

ElseIf "ZDA_PMINFR" $ _cCampo//ZDA_PMINFR: Deve ser maior que zero e Nao pode ser menor que o campo DA1_I_PMFR (gatilhar o conteúdo do campo XXX_PMINFE na inclusão)

   If M->ZDA_PMINFR <= 0 .Or. M->ZDA_PMINFR < DA1->DA1_I_PMFR .Or. M->ZDA_PMINFR > aCols[n][_nPos5]
      U_ITMsg("Valor invalido. Deve ser maior que zero.",'ATENCAO!',"Nao pode ser menor que o campo (DA1_I_PMFR) "+AllTrim(Str(DA1->DA1_I_PMFR,11,2))+ENTER+;
                                                                    "Nao pode ser maior que o Preco carga fechada (ZDA_PRCFRA) "+AllTrim(Str(aCols[n][_nPos5],11,2)),1)
      Return .F.
   EndIf

ElseIf "ZDA_PMAXFR" $ _cCampo//ZDA_PMAXFR: Deve ser maior que zero e Nao pode ser maior que o campo DA1_I_PRCA (gatilhar o conteúdo do campo XXX_PMAXFE na inclusão)

   If M->ZDA_PMAXFR <= 0 .Or. M->ZDA_PMAXFR > DA1->DA1_I_PRCA .Or. M->ZDA_PMAXFR < aCols[n][_nPos5]
      U_ITMsg("Valor invalido. Deve ser maior que zero.",'ATENCAO!',"Nao pode ser maior que o campo (DA1_I_PRCA) "+AllTrim(Str(DA1->DA1_I_PRCA,11,2))+ENTER+;
                                                                    "Nao pode ser menor que o Preco carga fechada (ZDA_PRCFRA) "+AllTrim(Str(aCols[n][_nPos5],11,2)),1)
      Return .F.
   EndIf

EndIf
/*   
Validações:
XXX_CODPRO: O produto inserido na tabela deve existir na tabela de Precos oficial 
(verificar se existe um registro na tabela DA1 com DA1_FILIAL = ‘01’, 
DA1_CODPRO = XXX_CODPRO e verificar também se o registro correspondente na tabela 
DA0 está válido (ativo e dentro da data de validade)).

ZDA_PRCVEN: Deve ser maior que zero e Nao pode ser menor que o campo DA1_PRCVEN
ZDA_PMINFE: Deve ser maior que zero e Nao pode ser menor que o campo DA1_I_PMFE
ZDA_PMAXFE: Deve ser maior que zero e Nao pode ser maior que o campo DA1_I_PRCA
ZDA_PRCFRA: Deve ser maior que zero e Nao pode ser menor que o campo DA1_I_PRFE (gatilhar o conteúdo do campo XXX_PRCVEN na inclusão)
ZDA_PMINFR: Deve ser maior que zero e Nao pode ser menor que o campo DA1_I_PMFR (gatilhar o conteúdo do campo XXX_PMINFE na inclusão)
ZDA_PMAXFR: Deve ser maior que zero e Nao pode ser maior que o campo DA1_I_PRCA (gatilhar o conteúdo do campo XXX_PMAXFE na inclusão)
*/

Return .T.
