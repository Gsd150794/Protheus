
#Include "TOTVS.ch"
#Include "FWPRINTSETUP.CH"
#Include "RPTDEF.CH"
#Include "TBICONN.CH"
#Include "RWMAKE.CH"

Static _lJob  := IsBlind()

/*
=================================================================================================================================
Programa----------: AOMS116
Autor-------------: Alex Wallauer
Data da Criacao---: 07/11/2019
Descrição---------: Cadastro de Reposição automática de estoque CHAMADO 31089
Parametros--------: Nenhum
==================================================================================================================================
*/
User Function AOMS116

Local _cAlias := "Z19"
Local _aCores := {	{ "Z19_MSBLQL <> '1' ", "BR_VERDE"	 },;//
					{ "Z19_MSBLQL == '1'" , "BR_VERMELHO"}}  //Bloqueado

Private cCadastro:= "Cadastro de Reposição automatica de estoque"
Private aRotina		:= {}                

aAdd(aRotina,{"Pesquisar"	  ,"AxPesqui"  ,0,1})
aAdd(aRotina,{"Visualizar"	  ,"U_AOMS116M",0,2})
aAdd(aRotina,{"Incluir"		  ,"U_AOMS116M",0,3})
aAdd(aRotina,{"Alterar"		  ,"U_AOMS116M",0,4})
aAdd(aRotina,{"Excluir"		  ,"U_AOMS116M",0,5})
aAdd(aRotina,{"Executar Regra","U_AOMS116M",0,2})
aAdd(aRotina,{"Legenda"       ,"U_AOMS_LEGE(.F.)",0,7})

DBSelectArea(_cAlias)
DBSetOrder(1)


// owse(,,,,cAli>  ,<aFixe, <cCpo>, <nPar>, <cCorFun>, <nClickDef>, <aColors>, <cTopFun>, <cBotFun>, <nPar14>, <bInitBloc>, <lNoMnuFilter>, <lSeeAll>, <lChgAll>, <cExprFilTop>, <nInterval>, <uPar22>, <uPar23> )
mBrowse(,,,,_cAlias,      ,       ,       ,          ,            , _aCores)

Return

/*
=================================================================================================================================
Programa----------: U_AOMS_LEGE
Autor-------------: Alex Wallauer
Data da Criacao---: 07/11/2019
Descrição---------: Cadastro de Reposição automática de estoque LEGENDA
Parametros--------: lBotao
==================================================================================================================================
*/
User Function AOMS_LEGE(lBotao)
   
Local _aLegenda := {{ "BR_VERMELHO","Bloqueado" },;
                 	{ "BR_VERDE"   ,"Liberado"  } }
If lBotao             
   _aLegenda := {{ "BR_VERMELHO" ,"Tem Reposicao Critica e vai Gerar Pedido"},;//BOLINHA VERMELHO
               	 { "BR_AZUL"     ,"Tem Reposicao e vai Gerar Pedido"        },;//BOLINHA AZUL
               	 { "BR_AMARELO"  ,"Já Repos, Falta Confirmar"               },;//BOLINHA AMARELO
               	 { "BR_VERDE"    ,"Tudo OK, nao tem Reposicao"              } }//BOLINHA VERDE

   aAdd(_aLegenda,{ "PMSTASK1"      ,"Lista Tem Reposicao Critica e vai Gerar Pedido"})//QUADRADO VERMELHO
   aAdd(_aLegenda,{ "PMSTASK6"      ,"Lista Tem Reposicao e vai Gerar Pedidor"       })//QUADRADO AZUL    
   aAdd(_aLegenda,{ "PMSTASK2"      ,"Lista Já Repos, Falta Confirmar"               })//QUADRADO AMARELO 
   aAdd(_aLegenda,{ "PMSTASK4"      ,"Lista Tudo OK, nao tem Reposicao"              })//QUADRADO VERDE    
EndIf

BRWLEGENDA(cCadastro, "Legenda", _aLegenda )
   
Return 

/*
===============================================================================================================================
Programa--------: AOMS116M
Autor-----------: Alex Wallauer
Data da Criacao-: 07/11/2019
Descrição-------: Cadastro de Reposição automática de estoque MANUTENÇÃO
Parametros------: cAlias,nReg,_nOpcx
==================================================================================================================================
*/
User Function AOMS116M(cAlias,nReg,_nOpcx)

Local _aObjects, _aPosObj, _aInfo, _oDlgEnch ,_nni//, _nnj
Local _aSizeAut := MsAdvSize(.T.)
Local _cTitulo  :=cCadastro
Local _bOk      := {|| If(AOMS116Grv(_nOpcx),(_lRet := .T., _oDlgEnch:End()),)} 
Local _bCancel  := {|| _lRet := .F., _oDlgEnch:End()}
Local bCampo    := {|nCPO| Field(nCPO) }

If _nOpcx = 6 // EXECUTA AS REGRAS
   U_AOMS116S()
   Return .T.
EndIf   

Private aHeader:= {}
Private aCols  := {}       
Private aTELA  := {} // Variáveis que serão atualizadas pela Enchoice
Private aGETS  := {} // e utilizadas pela função OBRIGATORIO()

DBSelectArea("Z19")//INICIA VARIAVIES DA CAPA
Z20->(DBSetOrder(1))

If _nOpcx # 3  //se nao For inclusao
	For _nni := 1 To FCount()
		M->&(EVAL(bCampo,_nni)) := FieldGet(_nni)
	Next 
Else	
	For _nni := 1 To FCount()
		M->&(EVAL(bCampo,_nni)) := CriaVar(EVAL(bCampo,_nni),.F.)
	Next 
EndIf

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
M->Z20_COD:=""//Inicia Branco por causa do X3_RELACAO
_lCntrlDescIni:=.T.//Controla de qual campo pega a descrição do item se data tabela Z20 (.T.) ou memoria (.F.)
cSeek  := xFilial("Z19")+Z19->Z19_REGRA
lTemItens:=_nOpcx # 3 .And. Z20->(DBSeek(cSeek))
If !lTemItens
    nOpc:=3
    FillGetDados(_nOpcx,"Z20",1,/*cSeek*/,/*bWhile*/,,/*aNoFields*/,/*aYesFields*/,/*lOnlyYes*/,/*cQuery*/,/*bMontCols*/,.T.,/*aHeaderAux*/,/*aColsAux*/,,/*bBeforeCols*/,/*bAfterHeader*/,)
Else
    bWhile := {|| Z20_FILIAL+Z20_REGRA }
    nOpc:=_nOpcx
    FillGetDados(_nOpcx,"Z20",1,cSeek   ,bWhile    ,,/*aNoFields*/,/*aYesFields*/,/*lOnlyYes*/,/*cQuery*/,/*bMontCols*/,.F.,/*aHeaderAux*/,/*aColsAux*/,,/*bBeforeCols*/,/*bAfterHeader*/,)
EndIf    
_lCntrlDescIni:=.F.//Controla de qual campo pega a descrição do item se data tabela Z20 (.T.) ou memoria (.F.)

// Tela de Manutenção
_aObjects:= {}
aAdd( _aObjects, { 100, 050, .T., .T. } )
aAdd( _aObjects, { 100, 100, .T., .T. } )
_aInfo   := { _aSizeAut[ 1 ], _aSizeAut[ 2 ], _aSizeAut[ 3 ], _aSizeAut[ 4 ], 3, 3 }
_aPosObj := MsObjSize( _aInfo, _aObjects, .T. )
_lDeleta :=((nOpc = 3) .Or. (nOpc = 4))

Define MsDialog _oDlgEnch Title _cTitulo From _aSizeAut[7],00 To _aSizeAut[6], _aSizeAut[5] Of oMainWnd Pixel
      
   EnChoice( "Z19" ,nReg, _nOpcx, , , , , _aPosObj[1], , 3 )
            
	//        MsGetDados(): New( < nTop>        , < nLeft>    , < nBottom>     , < nRight>,< nOpc>,[ cLinhaOk]     , [ cTudoOk],[ cIniCpos],[ lDeleta],[ aAlter]  , [ nFreeze], [ lEmpty], [ nMax], [ cFieldOk], [ cSuperDel], [ uPar], [ cDelOk], [ oWnd], [ lUseFreeze], [ cTela] )
   _oGetDados := MsGetDados():New(_aPosObj[2,1], _aPosObj[2,2], _aPosObj[2,3], _aPosObj[2,4], nOpc, /*"U_LINHAOK"*/,           ,           ,  _lDeleta, /*aAlter*/,           , .F.      , 999   , /*FIELDOK*/, /*SUPERDEL*/,        , /*DELOK*/, _oDlgEnch)
   
Activate MsDialog _oDlgEnch On Init EnchoiceBar(_oDlgEnch,_bOk,_bCancel) 
   
Return 

/*
===============================================================================================================================
Programa--------: U_AOMS116G()
Autor-----------: Alex Wallauer
Data da Criacao-: 07/11/2019
Descrição-------: Função chamada do X3_VALID do campo Z20_COD //ExistCpo("SB1") .And. U_AOMS116G()
Parametros------: Nenhum
==================================================================================================================================
*/
User Function AOMS116G(_lValid,cGruCpo)

Local _nPos1:= aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "Z20_COD"	 } )
Local _nPos2:= aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "Z20_DESCPR"} )
Local _nPos4:= aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "Z20_ESTIDE"} )
Local _cCrtl3Um := "N" // Produtos a validar quantidade fracionada na terceira unidade de medida.

Default cGruCpo :="1"

If cGruCpo="1" .And. _lValid

   If aCols[n][_nPos1] <> M->Z20_COD .And. Z20->(DBSeek(xFilial("Z20")+M->Z19_REGRA+aCols[n][_nPos1] ))
      U_ITMsg("Codigo do produto não pode ser alterado por que é chave de pesquisa.","Atenção",;
	           "Delete essa linha e insira uma com o novo codigo de produto",1)
      Return .F.
   Else
      aCols[n,_nPos2] := AllTrim(Posicione("SB1",1,xFilial("SB1")+M->Z20_COD,"B1_DESC"))+" ["+SB1->B1_SEGUM+"]"
   EndIf

ElseIf cGruCpo="1" 

  If _lCntrlDescIni //Controla de qual campo pega a descrição do item se data tabela Z20 (.T.) ou memoria (.F.)
     If !Inclui
        Return AllTrim(Posicione("SB1",1,xFilial("SB1")+Z20->Z20_COD,"B1_DESC"))+" ["+SB1->B1_SEGUM+"]"
     EndIf
  EndIf   
  Return " "

ElseIf cGruCpo="2" .And. _lValid
       _nQtde := aCols[n][_nPos4] // _nQtde :=ConvUM(aCols[n][_nPos1],0,@_n2Qtde)
       _cCrtl3Um := Posicione("SBZ",1,xFilial("SBZ")+AllTrim(aCols[n][_nPos1]),"BZ_I_PR3UM")
       If _cCrtl3Um == "S"
          If Mod(_nQtde,2) <> 0
             U_ITMsg("O Calculo da terceira unidade não pode ser Fracionada  [ "+CVALTOCHAR(_nQtde)+" "+SB1->B1_I_3UM+" ] ","Atenção",;
	                 "Digite valores inteiros.",1)
             Return .F.
          EndIf                 
	    Else
          _nQtde := aCols[n][_nPos4] // ConvUM(aCols[n][_nPos1],0,M->Z20_ESTIDE,.F.)
          If _nQtde <> Int(_nQtde)  
             U_ITMsg("O Calculo da primeira unidade não pode ser Fracionada  [ "+CVALTOCHAR(_nQtde)+" "+SB1->B1_UM+" ] ","Atenção",;
	                  "Digite a Segunda Unidade inteira, sem decimais",1)
             Return .F.
          EndIf 
	    EndIf	             

ElseIf cGruCpo="2" 

  If _lCntrlDescIni //Controla de qual campo pega a descrição do item se data tabela Z20 (.T.) ou memoria (.F.)
     If !Inclui
        _nQtde:=ConvUM(Z20->Z20_COD,0,Z20->Z20_ESTIDE,.F.)
        Return TRANSF(_nQtde,"@E 999,999,999.99")+" "+SB1->B1_UM
     EndIf
  EndIf   
  Return " "

EndIf   

Return .T.

/*
===============================================================================================================================
Programa--------: AOMS116Grv()
Autor-----------: Alex Wallauer
Data da Criacao-: 07/11/2019
Descrição-------: Cadastro de Reposição automática de estoque GRAVAÇÃO
Parametros------: cAlias,nReg,_nOpcx
==================================================================================================================================
*/
Static Function AOMS116Grv(_nOpcx)

Local nConIten  ,nConCmp
Local cAliasItm:="Z20"
Local _nPos := aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "Z20_COD"	 } )
Local _nPos1:= aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "Z20_ESTIDE"} )
Local _nPos2:= aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "Z20_MINREP"} )
Local _nPos3:= aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "Z20_MSBLQL"} )
Local lTudoOK:=.F.
Local aProd  :={}

Z19->(DBSetOrder(1))
Z20->(DBSetOrder(1))

If _nOpcx = 2
   Return .T.
ElseIf _nOpcx = 5
   BEGIN TRANSACTION
   Z19->(RecLock("Z19",.F.))
   Z19->(DBDelete())
   For nConIten := 1 To Len(aCols)
       If Z20->(DBSeek(xFilial("Z20")+M->Z19_REGRA+aCols[nConIten][_nPos] ))
	      Z20->(RecLock("Z20",.F.))
	      Z20->(DBDelete())
	   EndIf   
   Next 
   END TRANSACTION
   U_ITMsg("DADOS EXCUIDOS COM SUCESSO","Atenção",,2)
   Return .T.
EndIf

If !Obrigatorio(aGets,aTela)
   Return .F.
EndIf

For nConIten := 1 To Len(aCols)
	If aCols[nConIten][Len(aCols[nConIten])]//DELETADOS
       Loop
    EndIf	    
	If  !Empty(aCols[nConIten][_nPos ]) .AND.;
	    !Empty(aCols[nConIten][_nPos1]) .AND.;
	    !Empty(aCols[nConIten][_nPos2]) .AND.;
	    !Empty(aCols[nConIten][_nPos3])
        
        If aScan(aProd,aCols[nConIten][_nPos]) = 0
	       aAdd(aProd,aCols[nConIten][_nPos])
	    Else
           lTudoOK:=.F.
	       U_ITMsg("Produto: "+aCols[nConIten][_nPos]+" Repetido.","Atenção",;
	               "Apague ou Altere o codigo do produto da linha: "+AllTrim(Str(nConIten)),1)
	       Return .F.
	    EndIf   
        
        lTudoOK:=.T.  
        
    Else
        lTudoOK:=.F.
        Exit
    EndIf    
Next

If !lTudoOK
	U_ITMsg("É necessário informar Produtos antes da gravação.","Atenção",;
	        "Insira produtos validos, não repetidos e preencha todos os campos obrigatorios da linha",1)
	Return .F.
EndIf

BEGIN TRANSACTION
Z19->(RecLock("Z19", !DBSeek(xFilial("Z19")+M->Z19_REGRA) ))
AVREPLACE("M","Z19")
M->Z19_FILIAL:= xFilial("Z19")
Z19->(MSUnLock())

// Gravacao dos Itens
DBSelectArea("Z20")
For nConIten := 1 To Len(aCols)
	
	// Valida se o registro nao esta deletado
	If !aCols[nConIten][Len(aCols[nConIten])]//DELETADOS

        If Z20->(DBSeek(xFilial("Z20")+M->Z19_REGRA+aCols[nConIten][_nPos] ))
		   Z20->(RecLock("Z20",.F.))
		Else
		   Z20->(RecLock("Z20",.T.))
		EndIf   
		For nConCmp := 1 To Len(aHeader)
			If (aHeader[nConCmp,10] <> "V")
				FieldPut(FieldPos(aHeader[nConCmp,2]), aCols[nConIten, nConCmp])
			EndIf
		Next 
		(cAliasItm)->Z20_FILIAL := xFilial("Z20")
		(cAliasItm)->Z20_REGRA  := M->Z19_REGRA	
	    (cAliasItm)->(MSUnLock())
    Else
       If Z20->(DBSeek(xFilial("Z20")+M->Z19_REGRA+aCols[nConIten][_nPos] ))
	      Z20->(RecLock("Z20",.F.))
	      Z20->(DBDelete())
	   EndIf   
	EndIf

Next 

END TRANSACTION

U_ITMsg("DADOS GRAVADOS COM SUCESSO","Atenção",,2)

Return .T.

/*
===============================================================================================================================
Programa--------: AOMS116S
Autor-----------: Alex Wallauer
Data da Criacao-: 07/11/2019
Descrição-------: Cadastro de Reposição automática de estoque EXECUTA AS REGRAS
Parametros------: _lSchedule
==================================================================================================================================
*/
User Function AOMS116S(aParam)

Local nPos
Local _lSchedule := FWGetRunSchedule()
Default aParam	:= {"01","40"}
Private _cTimeIni:=Time()

If _lSchedule 

   If Select("SX3") = 0 .Or. SELECT("SM0") = 0

      U_ITCONOUT('INCIANDO AOMS116: '+aParam[01]+' FILIAL '+aParam[02]+" H.I.:"+_cTimeIni)
   
      RpcSetType(3)
      PREPARE ENVIRONMENT EMPRESA aParam[01] FILIAL aParam[02] MODULO "OMS" TABLES "Z19","Z20","SC5","SC6","ZZM","SD2","SA1"
   
      Sleep( 5000 ) //Aguarda 5 segundos para subam as configurações do ambiente.
      U_ITCONOUT('INCIADO AOMS116: '+aParam[01]+' FILIAL '+aParam[02]+" H.F.: "+TIME())
      cFilAnt := aParam[02]
   
   Else

      U_ITCONOUT('INCIADO AOMS116: FILIAL '+cFilAnt+" H.I.:"+_cTimeIni)
      DBSelectArea("Z19")
      DBSelectArea("Z20")      

   EndIf                   

Else

   If !U_ITMsg("Cofirma Execução da Regra "+Z19->Z19_REGRA+" ?",'Atenção!',,2,2,2)//ALERT
      Return .F.
   EndIf
   _lSchedule:=.F.

EndIf

Z19->(DBSetOrder(1))
Z20->(DBSetOrder(1))

Private _aLinhas:={}
Private _aPts:={}
Private _aCab:={}
Private _aSize:={}

//MONTA _aCab PARA QUANDO NÃO É lRepoeArmazens
aAdd(_aCab,"")//01
aAdd(_aSize,1)
aAdd(_aCab,"Filial")//02
aAdd(_aSize,05)
aAdd(_aCab,"Produto")//03
_nPosColProd:=Len(_aCab)
aAdd(_aSize,15)
aAdd(_aCab,"Descrição")//04
aAdd(_aSize,100)
aAdd(_aCab,"Reposição")//05
_nPosColRepo:=Len(_aCab)
aAdd(_aSize,40)
aAdd(_aCab,"Fil.Ped.")//06
_nPosColFil:=Len(_aCab)
aAdd(_aSize,40)
aAdd(_aCab,"Carteira")//07
_nPosColCar:=Len(_aCab)
aAdd(_aSize,40)
aAdd(_aCab,"Estoque")//08
_nPosColEst:=Len(_aCab)
aAdd(_aSize,40)
aAdd(_aCab,"Transito")//09
aAdd(_aSize,40)
aAdd(_aCab,"PV.Transf.")//10
aAdd(_aSize,40)
aAdd(_aCab,"Disponivel")//11
aAdd(_aSize,40)
aAdd(_aCab,"Est.Ideal")//12
aAdd(_aSize,40)
aAdd(_aCab,"Ped.Minimo")//13
aAdd(_aSize,40)
aAdd(_aCab,"Qtde.Repor")//14
aAdd(_aSize,40)
aAdd(_aCab,"Qtde.Poder3o")//15 - NOVO
_nColPoder3o:=Len(_aCab)
aAdd(_aSize,45)
aAdd(_aCab,"Multiplicador") //16
aAdd(_aSize,40)
aAdd(_aCab,"Peso Reposicao")//17 - NOVO
aAdd(_aSize,45)
aAdd(_aCab,"Seg.UM")        //18 - NOVO
aAdd(_aSize,20)
aAdd(_aCab,"Acao")          //19 - NOVO
_nPosColAcao:=Len(_aCab)
aAdd(_aSize,10)
_aCabPT:={"Produto","Descricao","Filial","Pedido","Emissao","Seg.UM","Quantidade"}//USA NA FUNCAO AOMS13PT() E AOMS116EML() por Schedule

Private _cTRB:=GetNextAlias()

If _lSchedule

   aAdd(_aCab,"Ped. Gerado")// 20 // antigo 16
   _nPosPedGer:=Len(_aCab)
   aAdd(_aSize,50)
   aAdd(_aCab,"Observação") // 21 // antigo 17
   _nPosObs:=Len(_aCab)
   aAdd(_aSize,200)
   aAdd(_aCab,"Cod.Item")   // 22 // antigo 18
   _nPosCodItem:=Len(_aCab)
   aAdd(_aSize,50)

   Z19->(DBGoTop())

   While Z19->(!Eof())

      If Z19->Z19_MSBLQL="1" .Or. cFilAnt <> Z19->Z19_FILIAL
         Z19->(DBSkip())
         Loop      
      EndIf
      cFilAnt:=Z19->Z19_FILIAL
      _aLinhas:={}

	  U_ITConOut('Executando regra: '+Z19->Z19_FILIAL+" "+Z19->Z19_REGRA)

      lRepoeArmazens:= (Z19->Z19_TIPO = "3" .Or. (Empty(Z19->Z19_TIPO) .And. ("70;72" $ AllTrim(Z19->Z19_LOCAL) .Or. "72;70" $ AllTrim(Z19->Z19_LOCAL) ) ) )

      If  !lRepoeArmazens
          AOMS116L(,Z19->Z19_TIPO)//EXECUTAS AS SELECTS CONFORME AS REGRAS
          AOMSGerPed(,.T.) //GERA OS PVS E ENVIA E-MAIL
      EndIf    

      Z19->(DBSkip())

   EndDo   
	
Else

    lRepoeArmazens:= (Z19->Z19_TIPO = "3" .Or. (Empty(Z19->Z19_TIPO) .And. ("70;72" $ AllTrim(Z19->Z19_LOCAL) .Or. "72;70" $ AllTrim(Z19->Z19_LOCAL) ) ) )

    If lRepoeArmazens
       Private _cProdutos:=""
       FWMsgRun(,{|oProc| Ver_Est_AM(oProc,.F.) },"Executando Regra "+Z19->Z19_REGRA,'Lendo dados dos Produtos...')
    Else
       FWMsgRun(,{|oProc| AOMS116L(oProc,Z19->Z19_TIPO) },"Executando Regra "+Z19->Z19_REGRA,'Lendo dados dos Produtos...')
	EndIf
    
	aBotoes:={}
    bDblClk:=NIL
    bCondMarca:=NIL
    If lRepoeArmazens/// *******************  ARMAZENS ***************************
       _cMsgTop:='Regra: '+Z19->Z19_REGRA+' - Tempo de execução: Hr. Inicial: '+_cTimeIni+", Hr. Final: "+Time()

       _aCab:={" "," ","Produto","Descricao","1aUM / 2aUM","Est.Ideal 2UM","Ped.Minimo","Qtde.Repor 2UM","Atual 70 2UM","Atual 72 2UM","Arm 20 2UM","Arm 22 2UM","Repor. 70 1UM","Repor. 70 2UM","Qtde 70 3UM","Repor. 72 1UM","Repor. 72 2UM","Qtde 72 3UM","Acao","Observacao"}
       _aSize:={ 1, 1 ,       15,         60,             05,             40,        40,              45,            40,            40,          40,          40,             40,            40 ,           40,            40 ,            40 ,          40 ,    20,         200}
       _nTipo:=2

       _nPosColProd:=3//PARA lRepoeArmazens
	   aAdd( aBotoes , { "" , {|| CADSB1(oLbxAux) } , "" , "Visualisar Prod."  } )
   	   bCondMarca:={|oLbxAux,nAt| oLbxAux:aArray[nAt][2] }
	   _bLegenda:=NIL
       _aColXML:={}
       For nPos:= 1 To Len(_aLinhas)
           aAdd(_aColXML,aClone(_aLinhas[nPos]))
           _aColXML[nPos,1]:=If(_aColXML[nPos,1],"X","")
           _aColXML[nPos,2]:=If(_aColXML[nPos,2],"OK","NO")
       Next
       _cTitAux:="TRANSFERENCIAS DE ARMAZENS"
    Else/// *******************  GERA PEDIDOS ***************************
	   _aLinhas := aSort(_aLinhas,,,{|x,y| x[_nPosColFil]+x[_nPosColProd] < y[_nPosColFil]+y[_nPosColProd]})
       _cTitAux:="GERACAO DE PEDIDOS"
       _cMsgTop:='Regra: '+Z19->Z19_REGRA+' - [ 2 cliques na colua de "Reposição" ou "Fil.Ped." para editar ] - Tempo de execução: Hr. Inicial: '+_cTimeIni+", Hr. Final: "+Time()
	   If Len(_aPts) > 0
	      aAdd( aBotoes , { "" , {|| AOMS13PT(_aPts) } , "" , "Visualisar os P.T."  } )
	   EndIf
	   aAdd( aBotoes , { "" , {|| FWMsgRun(,{|oProc|  AOMS116EML(.T., _aLinhas,oProc,{},_aPts) },"Enviando E-MAIL...") }, "" , "Envia E-MAIL"  } )
       aAdd( aBotoes , { "" , {|| U_AOMS_LEGE(.T.) } , "" , "LEGENDA"  } )
	   bDblClk:={|| AOMS116GET(@oLbxAux)}
	   _bLegenda:={|C,L| U_AOMS13Leg(C,L) }
       _aColXML:={}
       For nPos:= 1 To Len(_aLinhas)
           aAdd(_aColXML,aClone(_aLinhas[nPos]))
           _aColXML[nPos,1]:=If(_aColXML[nPos,1],"X","")
       Next
       _nTipo:=4
    EndIf
    
	While Len(_aLinhas) > 0		
	//         ITListBox(_cTitAux , _aHeader , _aCols    , _lMaxSiz ,  nTipo , _cMsgTop , _lSelUnc , _aSizes , _nCampo , bOk , bCancel, _abuttons, _aCab ,bDblClk , _aColXML , bCondMarca,_bLegenda)
	   lRet:=U_ITLISTBOX(cCadastro, _aCab    , _aLinhas  , .T.      , _nTipo , _cMsgTop ,          , _aSize  ,         ,     ,        , aBotoes  ,       ,bDblClk , _aColXML , bCondMarca,_bLegenda)

       If lRet
          If lRepoeArmazens
             FWMsgRun(,{|oProc| Ver_Est_AM(oProc,.T.) },'Aguarde processamento...',"Gerando Transferencias...")
          Else
             FWMsgRun(,{|oProc| AOMSGerPed(oProc,.F.) },'Aguarde processamento...',"Gerando Pedidos...") //GERA OS PEDIDOS E MOSTRA A TELA DE LOG E ENVIA E-MAIL
          EndIf   
       ElseIf !U_ITMsg("Cofirma SAIR ?",'Atenção!',,3,2,2)
          Loop
       EndIf

       Exit

	EndDo

	If Len(_aLinhas) = 0

		U_ITMsg("Nenhum registro localizado","Atenção",,1)

	EndIf
	
EndIf 

Return .T.

/*
===============================================================================================================================
Programa--------: AOMSGerPed()
Autor-----------: Alex Wallauer
Data da Criacao-: 07/11/2019
Descrição-------: GERA OS PEDIDOS E MOSTRA A TELA DE LOG E ENVIA E-MAIL
Parametros------: oProc,_lSchedule
==================================================================================================================================
*/
Static Function AOMSGerPed(oProc,_lSchedule)

Local _aLog:={} , _nI ,L , _nPos
Local _cTimeIni:=Time()
Local _aLog2:={}
Private _nQtdePV:=0

 If _lSchedule
    If Len(_aLinhas) > 0
       AOMS116EML(.F., _aLinhas,,{} ,_aPts)//ENVIA E-MAIL ANTES DE GERAR SEMPRE NO SCHEDULE
    EndIf
Else

    aAdd(_aCab,"Ped. Gerado")// 20 // antigo 16
    _nPosPedGer:=Len(_aCab)
    aAdd(_aSize,50)
    aAdd(_aCab,"Observação") // 21 // antigo 17
    _nPosObs:=Len(_aCab)
    aAdd(_aSize,200)
    aAdd(_aCab,"Cod.Item")   // 22 // antigo 18
    _nPosCodItem:=Len(_aCab)
    aAdd(_aSize,50)

EndIf

If !_lSchedule
   _nConta:= Len( _aLinhas )
   _cTot  :=AllTrim(Str(_nConta))
   _nTam  :=Len(_cTot)
   _nConta:=0
   oProc:cCaption := ("Gerando Pedidos de "+_cTot+" Produtos ")
   ProcessMessages()
   SLEEP(1000)
EndIf

Z09->(DBSetOrder(3)) // Z09_FILIAL+Z09_FILORI+Z09_FILDES+Z09_CODOPE+Z09_CODPRO 
_cCnrtlFilRepo:="XX"
aItensGeraFil:={}
_lEnviaEnailLog:=.F.
For _nI := 1 To Len( _aLinhas )

    aItens:=_aLinhas[_nI]
    If !_lSchedule
       _nConta++
	   oProc:cCaption := ("Gerando PV Prod: "+aItens[_nPosColFil]+" "+aItens[_nPosColProd]+" / "+AllTrim(StrZero(_nConta,_nTam)) +" de "+ _cTot)
	   ProcessMessages()
    EndIf
	If aItens[_nPosColAcao] = "1"//Broqueados e listados
	   Loop
	EndIf
    If _cCnrtlFilRepo = "XX"//PRIMIERA VEZ
       _cCnrtlFilRepo:=aItens[_nPosColFil]
    EndIf

    If _cCnrtlFilRepo <> aItens[_nPosColFil]//GERA  O PV DOS ITENS DA MESMA FILIAL DE REPOSICAO
       
       If !Empty(_cCnrtlFilRepo) .And. Len(aItensGeraFil) > 0
//***************  CRIA O PEDIDO ************************************************************************//
          _aRet  :=AOMSCriaPed(_cCnrtlFilRepo, aItensGeraFil,_lSchedule )
//***************  CRIA O PEDIDO ************************************************************************//
          _cPV   :=_aRet[1]
          _cErro :=_aRet[2]       

          If !Empty(_cPV) .And. aScan(_aLog,{|P| P[_nPosPedGer]==_cPV}) = 0
            _nQtdePV++
          EndIf  

          For L := 1 To Len(aItensGeraFil)
              If (_nPos:=aScan(_aLog2,{|P| P[7] == aItensGeraFil[L,_nPosColProd]} )) <> 0
                 _aLog2[_nPos,01]:=Empty(_cErro)//.T. ou .F.
                 _aLog2[_nPos,03]:=_cPV
                 _aLog2[_nPos,06]:=_cErro
              EndIf
              If (_nPos:=aScan(_aLog,{|P| P[_nPosCodItem] == aItensGeraFil[L,_nPosColProd]} )) <> 0
                 _aLog[_nPos,01]:=Empty(_cErro)//.T. ou .F.
                 _aLog[_nPos,_nPosPedGer]:=_cPV
                 _aLog[_nPos,_nPosObs]:=_cErro
              EndIf
          Next

       EndIf   
       //REINICIA
       _cCnrtlFilRepo:=aItens[_nPosColFil]
       aItensGeraFil:={}

    EndIf

    _nQtde2UM :=StrTran(aItens[_nPosColRepo],"." ,"" )  //Tira o ponto dos milhar
    _nQtde2UM :=Val(StrTran(_nQtde2UM       ,"," ,".") )//Tira a virgula e poe o ponto para o Val não comer a decimal

    _cPV:="  "
    _cErro:="  "
    If _nQtde2UM = 0//QUANTIDADE DE REPOSICAO

       aItens[1]:=.F.
       aAdd(aItens," ")//Ped. Gerado
       aAdd(aItens,"Não tem necessidade de repor ainda")//

	ElseIf !Empty( aItens[_nPosColFil] ) .And. aItens[_nPosColAcao] = "3"//listados

       aItens[1]:=.F.
       aAdd(aItens," ")//Ped. Gerado
       aAdd(aItens,"A acao desse item é so listar")//Observação

    ElseIf !Empty( aItens[_nPosColFil] )//FILIAL DE REPOSICAO

        _cMensagem:=""
	    If (Z09->(DBSeek(xFilial()+         aItens[_nPosColFil]+cFilAnt  +"20"+aItens[_nPosColProd] ))   .OR.;
		    Z09->(DBSeek(xFilial()+Space(Len(aItens[_nPosColFil]+cFilAnt))+"20"+aItens[_nPosColProd] )) ) .AND.;
		   (Date() >= Z09->Z09_INIVIG .And. Date() <= Z09->Z09_FIMVIG) 
		Else
     		_cMensagem+="Prod.: "+aItens[_nPosColProd]+" sem Preco na tabela de tranferencia"
         If !Empty(Z09->Z09_INIVIG)
		       _cMensagem+=" ou fora da data de vigencia: de "+DToC(Z09->Z09_INIVIG)+" ate "+DToC(Z09->Z09_FIMVIG)
         EndIf
	      _cMensagem+=CHR(13)+CHR(10)
	    EndIf
        
	    If _nQtde2UM > 99999 // não pode ser maior que (99.999) noventa e nove mil e novecentos e noventa e nove pq estora o campo 
   		   _cMensagem+="Prod.: "+aItens[_nPosColProd]+" com quantidade na 2a U.M. maior que 99.999 "+CHR(13)+CHR(10)
	    EndIf

	    SB1->(DBSeek(xFilial()+aItens[_nPosColProd]))
	    If SB1->B1_I_CXPAL <> 0
		   If mod(_nQtde2UM,SB1->B1_I_CXPAL) > 0
		      _nqtv := int(_nQtde2UM /SB1->B1_I_CXPAL) + 1
		   Else
			   _nqtv := int(_nQtde2UM /SB1->B1_I_CXPAL)
		   EndIf
	    EndIf

	    If _nqtv > 999 // não pode ser maior que (999) novecentos e noventa e nove pq estora o campo 
   		   _cMensagem+="Prod.: "+aItens[_nPosColProd]+"  com quantidade de Pallet maior que 999 "
	    EndIf

        If Empty(_cMensagem)
           aAdd(aItensGeraFil,_aLinhas[_nI])
        EndIf
        aAdd(aItens," ")//Ped. Gerado
        aAdd(aItens,_cMensagem)//Observação
        _lEnviaEnailLog:=.T.
       
    Else//SEM FILIAL DE REPOSICAO MAS COM QUANTIDADE
       aItens[1]:=.F.
       aAdd(aItens," ")//Ped. Gerado
       aAdd(aItens,"GERAR MANUAL, pois não foi indicada a Filial de reposição")//Observação
       
    EndIf

//PEDIDOS DOS PRODUTOS NO E-MAIL
    aItens2:={}
    aAdd(aItens2, aItens[1] )              //1-Gerado
    aAdd(aItens2, aItens[_nPosColFil] )    //2-Filial
    aAdd(aItens2, " " )                    //3-Pedido
    aAdd(aItens2, aItens[3]+"-"+aItens[4] )//4-Produto
    aAdd(aItens2, aItens[_nPosColRepo] )   //5-Quantidade
    aAdd(aItens2, aItens[_nPosObs] )       //6-Erro
    aAdd(aItens2, aItens[03] )             //7-Para pesquisar no aScan()

    aAdd(_aLog2,aItens2)
//PEDIDOS DOS PRODUTOS NO E-MAIL

//DETALHAMENTO DOS PRODUTOS NO E-MAIL
    aItens[4]:=LEFT(aItens[4],32)
    aAdd(aItens, aItens[03] ) //21 - para pesquisar no aScan()

    aAdd(_aLog,aItens)
//DETALHAMENTO DOS PRODUTOS NO E-MAIL
Next

If !Empty(_cCnrtlFilRepo) .And. Len(aItensGeraFil) > 0
	_aRet :=AOMSCriaPed(_cCnrtlFilRepo, aItensGeraFil,_lSchedule )
	_cPV  :=_aRet[1]
	_cErro:=_aRet[2]
	
	If !Empty(_cPV) .And. aScan(_aLog,{|P| P[_nPosPedGer]==_cPV}) = 0
		_nQtdePV++
	EndIf
	
	For L := 1 To Len(aItensGeraFil)
		If (nPos:=aScan(_aLog2,{|P| P[7] == aItensGeraFil[L,_nPosColProd]} )) <> 0
			_aLog2[nPos,01]:=Empty(_cErro)//SE EM BRANCO .T. GEROU
			_aLog2[nPos,03]:=_cPV
			_aLog2[nPos,06]:=_cErro
		EndIf
		If (_nPos:=aScan(_aLog,{|P| P[_nPosCodItem] == aItensGeraFil[L,_nPosColProd]} )) <> 0
			_aLog[_nPos,01]:=Empty(_cErro)//SE EM BRANCO .T. GEROU
			_aLog[_nPos,_nPosPedGer]:=_cPV
			_aLog[_nPos,_nPosObs]:=_cErro
		EndIf
	Next
EndIf

If !_lSchedule .And. Len(_aLog) > 0
   _cTitAux:="GERACAO DOS PEDIDOS"
   _cMsgTop:="Tempo de execução: Hr. Inicial: "+_cTimeIni+", Hr. Final: "+Time()
	aBotoes:={}
	aAdd( aBotoes , { "" , {|| FWMsgRun(,{|oProc|  AOMS116EML(.T., _aLog,oProc,_aLog2,_aPts) },"Enviando E-MAIL...") }, "" , "Envia E-MAIL"  } )
   aAdd( aBotoes , { "" , {|| AVISO("ATENCAO",oLbxAux:aArray[oLbxAux:nAt][ Len(_aLog[1])-1 ],{"Fechar"},3) }	, "" , "Ver Erro"		  } )

//   ITListBox(_cTitAux , _aHeader , _aCols , _lMaxSiz ,  nTipo , _cMsgTop , _lSelUnc , _aSizes , _nCampo , bOk , bCancel, _abuttons, _aCab ,bDblClk , _aColXML , bCondMarca)
   U_ITLISTBOX(_cTitAux , _aCab    , _aLog  , .T.      , 4      , _cMsgTop ,          , _aSize  ,         ,     ,        , aBotoes  ,       , )

ElseIf _lSchedule .And. Len(_aLog) > 0

   If _lEnviaEnailLog//SÓ SE GEROU OU TENTOU GERAR
      AOMS116EML(.F., _aLog,,_aLog2,_aPts)//ENVIA E-MAIL DEPOIS DE GERAR 
   EndIf

EndIf   

Z09->(DBSetOrder(1))

Return .T.

/*
===============================================================================================================================
Programa--------: AOMS116L
Autor-----------: Alex Wallauer
Data da Criacao-: 07/11/2019
Descrição-------: EXECUTAS AS SELECTS CONFORME AS REGRAS
Parametros------: oProc , _cTipo
==================================================================================================================================
*/
Static Function AOMS116L(oProc,_cTipo)

Local cQuery1:=""
Local cQuery2:=""
Local cQuery3:=""
Local cQuery4:=""
Local nDias  :=Z19->Z19_DIAS
Local _aStru :={}

If oProc <> nil
   oProc:cCaption:="Criando Temporario..."
   ProcessMessages()
EndIf

aAdd(_aStru,{"FILIAL"	,"C",GetSX3Cache("B1_FILIAL","X3_TAMANHO"),0})
aAdd(_aStru,{"PRODUTO"	,"C",Len(SB1->B1_COD),00})
aAdd(_aStru,{"DESCRI"	,"C",Len(SB1->B1_DESC),0})
aAdd(_aStru,{"QTDE_C"	,"N",17,2})
aAdd(_aStru,{"QTDE_E"	,"N",17,2})
aAdd(_aStru,{"QTDE_T"	,"N",17,2})
aAdd(_aStru,{"QTDE_PT"	,"N",17,2})
aAdd(_aStru,{"QTDE_RE"	,"N",17,2})
aAdd(_aStru,{"QTDE_P3"	,"N",17,2})
aAdd(_aStru,{"FILREPO"	,"C",GetSX3Cache("B1_FILIAL","X3_TAMANHO"),0})

_oTempTable:=FWTemporaryTable():New( _cTRB, _aStru )
_oTempTable:AddIndex( "01", {"FILIAL","FILREPO","PRODUTO"} )
_oTempTable:Create()

If oProc <> nil
   oProc:cCaption:="1/4-Lendo CARTEIRA..."
   ProcessMessages()
EndIf

If _cTipo = "1" //1=Reposicao entre Filiais
   cQuery1+="  SELECT C6_FILIAL FILIAL,C6_PRODUTO PRODUTO,C6_DESCRI DESCRI,SUM (C6_UNSVEN) QTDE_C , 0 QTDE_E , 0 QTDE_T , 0 QTDE_PT , 0 QTDE_P3"
   cQuery1+="    FROM " + RetSqlName("SC6")+" SC6, " + RetSqlName("SC5")+" SC5, "+RetSqlName("SF4")+" SF4, "+RetSqlName("SB1")+" SB1 "
   cQuery1+="   WHERE     C6_FILIAL = '"+Z19->Z19_FILIAL+"' "
   cQuery1+="         AND C6_NOTA = ' '      "
   cQuery1+="         AND C5_FILIAL = C6_FILIAL "
   cQuery1+="         AND C5_NUM = C6_NUM "
   cQuery1+="         AND C5_EMISSAO >= '"+DToS(Date()-nDias)+"'"
   cQuery1+="         AND F4_FILIAL = C6_FILIAL"
   cQuery1+="         AND F4_CODIGO = C6_TES    "
   cQuery1+="         AND F4_ESTOQUE = 'S'      "
   cQuery1+="         AND B1_COD = C6_PRODUTO   "
   cQuery1+="         AND B1_TIPO = 'PA'        "
   cQuery1+="         AND SC5.D_E_L_E_T_ = ' '"
   cQuery1+="         AND SF4.D_E_L_E_T_ = ' '  "
   cQuery1+="         AND SC6.D_E_L_E_T_ = ' '"
   cQuery1+="         AND SB1.D_E_L_E_T_ = ' '  "
   cQuery1+="         AND C6_LOCAL IN " + FormatIn(AllTrim(Z19->Z19_LOCAL),";")
   cQuery1+="         AND EXISTS (SELECT 'x' FROM "+RetSqlName("Z20")+" Z20 "
   cQuery1+="                     WHERE Z20_FILIAL = '"+Z19->Z19_FILIAL+"' "
   cQuery1+="                       AND Z20_REGRA  = '"+Z19->Z19_REGRA+"' "
   cQuery1+="                       AND Z20_COD    = SC6.C6_PRODUTO "
   cQuery1+="                       AND Z20_MSBLQL <> '1' "
   cQuery1+="                       AND Z20.D_E_L_E_T_ = ' ') "
   cQuery1+=" GROUP BY C6_FILIAL, C6_PRODUTO, C6_DESCRI "
   cQuery1+=" ORDER BY 2"

ElseIf _cTipo = "2" //2=Operador Logistico

   cQuery1+="  SELECT C6_FILIAL FILIAL,C6_PRODUTO PRODUTO,C6_DESCRI DESCRI,SUM (C6_UNSVEN) QTDE_C , 0 QTDE_E , 0 QTDE_T , 0 QTDE_PT , 0 QTDE_P3 "
   cQuery1+="    FROM " + RetSqlName("SC6")+" SC6, " + RetSqlName("SC5")+" SC5, "+RetSqlName("SF4")+" SF4, "+RetSqlName("SB1")+" SB1, "+RetSqlName("CC2")+" CC2 "
   cQuery1+="   WHERE      C6_FILIAL = '"+Z19->Z19_FILIAL+"' "
   cQuery1+="          AND C6_NOTA = ' '"
   cQuery1+="          AND C5_FILIAL = C6_FILIAL"
   cQuery1+="          AND C5_NUM = C6_NUM"
   cQuery1+="          AND C5_EMISSAO >= '"+DToS(Date()-nDias)+"'"
   If Z19->(FIELDPOS("Z19_OPERAC")) <> 0 .And. !Empty(Z19->Z19_OPERAC)
      cQuery1+="       AND C5_I_OPER  IN " + FormatIn(AllTrim(Z19->Z19_OPERAC),";")
   Else
      cQuery1+="       AND C5_I_OPER = '12' "
   EndIf
   cQuery1+="          AND F4_FILIAL = C6_FILIAL"
   cQuery1+="          AND F4_CODIGO = C6_TES"
   cQuery1+="          AND F4_ESTOQUE = 'S'"
   cQuery1+="          AND B1_COD = C6_PRODUTO"
   cQuery1+="          AND B1_TIPO = 'PA'"
   cQuery1+="          AND CC2_FILIAL = ' '"
   cQuery1+="          AND CC2_EST = C5_I_EST"
   cQuery1+="          AND CC2_CODMUN = C5_I_CMUN"
   cQuery1+="          AND SC5.D_E_L_E_T_ = ' '"
   cQuery1+="          AND SF4.D_E_L_E_T_ = ' '"
   cQuery1+="          AND SC6.D_E_L_E_T_ = ' '"
   cQuery1+="          AND SB1.D_E_L_E_T_ = ' '"
   cQuery1+="          AND CC2.D_E_L_E_T_ = ' '"
   cQuery1+="          AND C6_LOCAL IN " + FormatIn(AllTrim(Z19->Z19_LOCAL),";")
   If !Empty(Z19->Z19_OPERAD)
      cQuery1+="       AND CC2_I_OPCO = '"+Z19->Z19_OPERAD+"' "
      cQuery1+="       AND CC2_I_OPLO = '"+Z19->Z19_OPELOJ+"' "
   EndIf
   cQuery1+="          AND EXISTS"
   cQuery1+="                 (SELECT 'x'"
   cQuery1+="                    FROM Z20010 Z20"
   cQuery1+="                     WHERE Z20_FILIAL = '"+Z19->Z19_FILIAL+"' "
   cQuery1+="                       AND Z20_REGRA  = '"+Z19->Z19_REGRA+"' "
   cQuery1+="                         AND Z20_COD = SC6.C6_PRODUTO"
   cQuery1+="                         AND Z20_MSBLQL <> '1'"
   cQuery1+="                         AND Z20.D_E_L_E_T_ = ' ')"
   cQuery1+=" GROUP BY C6_FILIAL, C6_PRODUTO, C6_DESCRI"
   cQuery1+=" ORDER BY 2"

EndIf
_cAlias:=GetNextAlias()
MPSysOpenQuery( cQuery1 , _cAlias ) 
AOMS116A(oProc,_cAlias,_cTRB)//GRAVA O SELECT (_cAlias) NA TABELA (_cTRB)
(_cAlias)->(DBCloseArea())

If oProc <> nil
   oProc:cCaption:="2/4-Lendo ESTOQUE 1/2 ..."
   ProcessMessages()
EndIf

If _cTipo = "1" //1=Reposicao entre Filiais
   cQuery2+=" SELECT B2_FILIAL FILIAL, B2_COD PRODUTO, B1_DESC DESCRI, 0 QTDE_C , SUM(B2_QATU) QTDE_E , 0 QTDE_T , 0 QTDE_PT , 0 QTDE_P3  "
   cQuery2+=" FROM "+RetSqlName("SB2")+" SB2, "+RetSqlName("SB1")+" SB1 "
   cQuery2+=" WHERE B2_FILIAL = '"+Z19->Z19_FILIAL+"' "
   cQuery2+="   AND SB2.D_E_L_E_T_ = ' ' "
   cQuery2+="   AND B1_COD    = B2_COD "
   cQuery2+="   AND B1_TIPO   = 'PA' "
   cQuery2+="   AND SB1.D_E_L_E_T_ = ' ' "
   cQuery2+="   AND B2_LOCAL IN " + FormatIn(AllTrim(Z19->Z19_LOCAL),";")
   cQuery2+="   AND EXISTS (SELECT 'x' FROM "+RetSqlName("Z20")+" Z20 "
   cQuery2+="                     WHERE Z20_FILIAL = '"+Z19->Z19_FILIAL+"' "
   cQuery2+="                       AND Z20_REGRA  = '"+Z19->Z19_REGRA+"' "
   cQuery2+="                       AND Z20_COD    = SB2.B2_COD "
   cQuery2+="                       AND Z20_MSBLQL <> '1'  "
   cQuery2+="                       AND Z20.D_E_L_E_T_ = ' ') "
   cQuery2+=" GROUP BY B2_FILIAL, B2_COD, B1_DESC  HAVING SUM(B2_QATU) <> 0 "
   cQuery2+=" ORDER BY B2_COD "

ElseIf _cTipo = "2" //2=Operador Logistico
   cQuery2+=" SELECT B6_FILIAL FILIAL, B6_PRODUTO PRODUTO, B1_DESC DESCRI, 0 QTDE_C , SUM(B6_SALDO) QTDE_E , 0 QTDE_T , 0 QTDE_PT , 0 QTDE_P3  "
   cQuery2+=" FROM "+RetSqlName("SB6")+" SB6, "+RetSqlName("SB1")+" SB1 "
   cQuery2+=" WHERE B6_FILIAL = '"+Z19->Z19_FILIAL+"' "
   cQuery2+="          AND B6_TIPO = 'E'
   cQuery2+="          AND B6_PODER3 = 'R'
   cQuery2+="          AND B6_SALDO <> 0
   cQuery2+="          AND SB6.D_E_L_E_T_ = ' '
   cQuery2+="          AND B1_COD = B6_PRODUTO
   cQuery2+="          AND B1_TIPO = 'PA'
   cQuery2+="          AND SB1.D_E_L_E_T_ = ' '
   cQuery2+="          AND B6_LOCAL IN " + FormatIn(AllTrim(Z19->Z19_LOCAL),";")
   If !Empty(Z19->Z19_OPERAD)
      cQuery2+="          AND B6_CLIFOR = '"+Z19->Z19_OPERAD+"' "
      cQuery2+="          AND B6_LOJA = '"+Z19->Z19_OPELOJ+"' "
   EndIf
   cQuery2+="          AND EXISTS
   cQuery2+="                 (SELECT 'x'
   cQuery2+="                    FROM Z20010 Z20
   cQuery2+="                     WHERE Z20_FILIAL = '"+Z19->Z19_FILIAL+"' "
   cQuery2+="                       AND Z20_REGRA  = '"+Z19->Z19_REGRA+"' "
   cQuery2+="                         AND Z20_COD = SB6.B6_PRODUTO
   cQuery2+="                         AND Z20_MSBLQL <> '1'
   cQuery2+="                         AND Z20.D_E_L_E_T_ = ' ')
   cQuery2+=" GROUP BY B6_FILIAL, B6_PRODUTO, B1_DESC
   cQuery2+="   HAVING SUM (B6_SALDO) <> 0
   cQuery2+=" ORDER BY B6_PRODUTO

EndIf
cQueryP2:=cQuery2

_cAlias:=GetNextAlias()
MPSysOpenQuery( cQuery2 , _cAlias) 
AOMS116A(oProc,_cAlias ,_cTRB)//GRAVA O SELECT (_cAlias) NA TABELA (_cTRB)
(_cAlias)->(DBCloseArea())


If _cTipo = "1" //1=Reposicao entre Filiais

   If oProc <> nil
      oProc:cCaption:="2/4-Lendo ESTOQUE PODER 3o 2/2..."
      ProcessMessages()
   EndIf

   cQuery2:=" SELECT B6_FILIAL FILIAL, B6_PRODUTO PRODUTO, B1_DESC DESCRI, 0 QTDE_C , 0 QTDE_E , 0 QTDE_T , 0 QTDE_PT , SUM(B6_SALDO) QTDE_P3  "
   cQuery2+=" FROM "+RetSqlName("SB6")+" SB6, "+RetSqlName("SB1")+" SB1 "
   cQuery2+=" WHERE B6_FILIAL = '"+Z19->Z19_FILIAL+"' "
   cQuery2+="          AND B6_TIPO = 'E'
   cQuery2+="          AND B6_PODER3 = 'R'
   cQuery2+="          AND B6_SALDO <> 0
   cQuery2+="          AND SB6.D_E_L_E_T_ = ' '
   cQuery2+="          AND B1_COD = B6_PRODUTO
   cQuery2+="          AND B1_TIPO = 'PA'
   cQuery2+="          AND SB1.D_E_L_E_T_ = ' '
   cQuery2+="          AND EXISTS
   cQuery2+="                 (SELECT 'x'
   cQuery2+="                    FROM Z20010 Z20
   cQuery2+="                     WHERE Z20_FILIAL   = '"+Z19->Z19_FILIAL+"' "
   cQuery2+="                       AND Z20_REGRA    = '"+Z19->Z19_REGRA+"' "
   cQuery2+="                         AND Z20_COD    = SB6.B6_PRODUTO "
   cQuery2+="                         AND Z20_FORN3O = SB6.B6_CLIFOR "
   cQuery2+="                         AND Z20_FO3OLJ = SB6.B6_LOJA "
   cQuery2+="                         AND Z20_PODER3 = '1' "
   cQuery2+="                         AND Z20_MSBLQL <> '1' "
   cQuery2+="                         AND Z20.D_E_L_E_T_ = ' ')
   cQuery2+=" GROUP BY B6_FILIAL, B6_PRODUTO, B1_DESC
   cQuery2+="   HAVING SUM (B6_SALDO) <> 0
   cQuery2+=" ORDER BY B6_PRODUTO
   cQueryP3:=cQuery2
    _cAlias:=GetNextAlias()
    MPSysOpenQuery( cQuery2 , _cAlias) 
    AOMS116A(oProc,_cAlias ,_cTRB)//GRAVA O SELECT (_cAlias) NA TABELA (_cTRB)
    (_cAlias)->(DBCloseArea())

ElseIf _cTipo = "2" //2=Operador Logistico
    cQueryP3:=""
EndIf

If _cTipo = "1" //1=Reposicao entre Filiais

   If oProc <> nil
      oProc:cCaption:="3/4-Lendo TRANSITO..."
      ProcessMessages()
   EndIf


   cQuery3+=" SELECT D2_COD PRODUTO, '"+Z19->Z19_FILIAL+"' FILIAL,  ' ' DESCRI, 0 QTDE_C , 0 QTDE_E , SUM(D2_QTSEGUM) QTDE_T , 0 QTDE_PT , 0 QTDE_P3  "
   cQuery3+="    FROM "+RetSqlName("SD2")+" SD2, "
   cQuery3+="         "+RetSqlName("SC5")+" SC5, "
   cQuery3+="         "+RetSqlName("ZZM")+" ZZMO,"
   cQuery3+="         "+RetSqlName("ZZM")+" ZZMD,"
   cQuery3+="         "+RetSqlName("SA1")+" SA1, "
   cQuery3+="         "+RetSqlName("SF4")+" SF4  "
   cQuery3+="   WHERE     ZZMO.ZZM_FILIAL = ' '  "
   cQuery3+="         AND ZZMO.ZZM_CODIGO = D2_FILIAL "
   cQuery3+="         AND ZZMO.D_E_L_E_T_ = ' '  "
   cQuery3+="         AND ZZMD.ZZM_FILIAL = ' ' "
   cQuery3+="         AND ZZMD.ZZM_CODIGO = '"+Z19->Z19_FILIAL+"' "
   cQuery3+="         AND ZZMD.D_E_L_E_T_ = ' ' "
   cQuery3+="         AND A1_FILIAL = ' ' "
   cQuery3+="         AND A1_CGC = ZZMD.ZZM_CGC "
   cQuery3+="         AND ZZMO.ZZM_CODIGO <> ZZMD.ZZM_CODIGO "
   cQuery3+="         AND SA1.D_E_L_E_T_ = ' ' "
   cQuery3+="         AND D2_EMISSAO >= '"+DToS(Date()-nDias)+"'"
   cQuery3+="         AND D2_CLIENTE = A1_COD "
   cQuery3+="         AND D2_LOJA = A1_LOJA "
   cQuery3+="         AND SD2.D_E_L_E_T_ = ' ' "
   cQuery3+="         AND C5_FILIAL = D2_FILIAL "
   cQuery3+="         AND C5_NUM = D2_PEDIDO "
   cQuery3+="         AND C5_I_OPER = '20' "
   cQuery3+="         AND C5_I_TRCNF <> 'S' "
   cQuery3+="         AND SC5.D_E_L_E_T_ = ' ' "
   cQuery3+="         AND F4_FILIAL = D2_FILIAL "
   cQuery3+="         AND F4_CODIGO = D2_TES "
   cQuery3+="         AND F4_ESTOQUE = 'S' "
   cQuery3+="         AND SF4.D_E_L_E_T_ = ' '"
   cQuery3+="         AND EXISTS "
   cQuery3+="                (SELECT 'x' "
   cQuery3+="                   FROM  "+RetSqlName("Z20")+" Z20 "
   cQuery3+="                  WHERE     Z20_FILIAL = '"+Z19->Z19_FILIAL+"' "
   cQuery3+="                        AND Z20_REGRA  = '"+Z19->Z19_REGRA+"' "
   cQuery3+="                        AND Z20_COD = SD2.D2_COD "
   cQuery3+="                        AND Z20_MSBLQL <> '1' "
   cQuery3+="                        AND Z20.D_E_L_E_T_ = ' ')"
   cQuery3+="         AND NOT EXISTS "
   cQuery3+="                    (SELECT 'x' FROM "+RetSqlName("SD1")+" SD1A,  "+RetSqlName("SF4")+" SF4 " 
   cQuery3+="                      WHERE     SD1A.D1_FILIAL = D2_FILIAL "
   cQuery3+="                            AND SD1A.D1_TIPO = 'D' "
   cQuery3+="                            AND SD1A.D1_FORNECE = D2_CLIENTE "
   cQuery3+="                            AND SD1A.D1_LOJA = D2_LOJA "
   cQuery3+="                            AND SD1A.D1_COD = D2_COD "
   cQuery3+="                            AND SD1A.D1_NFORI = D2_DOC "
   cQuery3+="                            AND SD1A.D1_SERIORI = D2_SERIE "
   cQuery3+="                            AND SD1A.D1_TES <> ' ' "
   cQuery3+="                            AND SD1A.D1_FORMUL = 'S' "
   cQuery3+="                            AND SD1A.D_E_L_E_T_ = ' ' "
   cQuery3+="                            AND F4_FILIAL = SD1A.D1_FILIAL "
   cQuery3+="                            AND F4_CODIGO = D1_TES "
   cQuery3+="                            AND F4_ESTOQUE = 'S' "
   cQuery3+="                            AND SF4.D_E_L_E_T_ = ' ')  "
   cQuery3+="         AND NOT EXISTS "
   cQuery3+="                    (SELECT 'x' FROM "+RetSqlName("SD1")+" SD1R,  "+RetSqlName("SF4")+" SF4 " 
   cQuery3+="                      WHERE     SD1R.D1_FILIAL = ZZMD.ZZM_CODIGO "
   cQuery3+="                            AND SD1R.D1_FORNECE = "
   cQuery3+="                                   (SELECT A2_COD FROM  "+RetSqlName("SA2")+" SA2 "
   cQuery3+="                                     WHERE     A2_FILIAL = ' ' "
   cQuery3+="                                           AND A2_CGC = ZZMO.ZZM_CGC
   cQuery3+="                                           AND A2_I_CLASS = 'F' "
   cQuery3+="                                           AND SA2.D_E_L_E_T_ = ' ') "
   cQuery3+="                            AND SD1R.D1_LOJA = "
   cQuery3+="                                   (SELECT A2_LOJA FROM "+RetSqlName("SA2")+" SA2 " 
   cQuery3+="                                     WHERE     A2_FILIAL = ' ' "
   cQuery3+="                                           AND A2_CGC = ZZMO.ZZM_CGC "
   cQuery3+="                                           AND A2_I_CLASS = 'F' "
   cQuery3+="                                           AND SA2.D_E_L_E_T_ = ' ') "
   cQuery3+="                            AND SD1R.D1_DOC = D2_DOC "
   cQuery3+="                            AND SD1R.D1_SERIE = D2_SERIE "
   cQuery3+="                            AND SD1R.D1_COD = D2_COD "
   cQuery3+="                            AND SD1R.D1_TES <> ' ' "
   cQuery3+="                            AND SD1R.D_E_L_E_T_ = ' ' "
   cQuery3+="                            AND F4_FILIAL = SD1R.D1_FILIAL "
   cQuery3+="                            AND F4_CODIGO = SD1R.D1_TES "
   cQuery3+="                            AND F4_ESTOQUE = 'S' "
   cQuery3+="                            AND SF4.D_E_L_E_T_ = ' ') "
   cQuery3+=" GROUP BY D2_COD "
   cQuery3+=" ORDER BY 1 "
   
   _cAlias:=GetNextAlias()
   MPSysOpenQuery( cQuery3 , _cAlias) 
   AOMS116A(oProc,_cAlias ,_cTRB)//GRAVA O SELECT (_cAlias) NA TABELA (_cTRB)
   (_cAlias)->(DBCloseArea())
EndIf

If oProc <> nil
   oProc:cCaption:="4/4-Lendo PED. TRANSFERENCIA 1/2..."
   ProcessMessages()
EndIf

If _cTipo = "1" //1=Reposicao entre Filiais
   cQuery4+=" SELECT C6_PRODUTO PRODUTO, '"+Z19->Z19_FILIAL+"' FILIAL,  C6_DESCRI DESCRI, 0 QTDE_C , 0 QTDE_E , 0 QTDE_T , SUM(C6_UNSVEN) QTDE_PT , 0 QTDE_P3  "
   cQuery4+="    FROM "+RetSqlName("SC6")+" SC6, "
   cQuery4+="         "+RetSqlName("SC5")+" SC5, "
   cQuery4+="         "+RetSqlName("ZZM")+" ZZMO,"
   cQuery4+="         "+RetSqlName("ZZM")+" ZZMD,"
   cQuery4+="         "+RetSqlName("SA1")+" SA1, "
   cQuery4+="         "+RetSqlName("SF4")+" SF4  "
   cQuery4+="   WHERE     ZZMO.ZZM_FILIAL = ' ' "
   cQuery4+="         AND ZZMO.ZZM_CODIGO = C6_FILIAL
   cQuery4+="         AND ZZMO.D_E_L_E_T_ = ' ' "
   cQuery4+="         AND ZZMD.ZZM_FILIAL = ' ' "
   cQuery4+="         AND ZZMD.ZZM_CODIGO = '"+Z19->Z19_FILIAL+"' "
   cQuery4+="         AND ZZMD.D_E_L_E_T_ = ' ' "
   cQuery4+="         AND A1_FILIAL = ' ' "
   cQuery4+="         AND A1_CGC = ZZMD.ZZM_CGC "
   cQuery4+="         AND ZZMO.ZZM_CODIGO <> ZZMD.ZZM_CODIGO "
   cQuery4+="         AND SA1.D_E_L_E_T_ = ' ' "
   cQuery4+="         AND C6_CLI = A1_COD "
   cQuery4+="         AND C6_LOJA = A1_LOJA "
   cQuery4+="         AND C6_NOTA = ' ' "
   cQuery4+="         AND SC6.D_E_L_E_T_ = ' ' "
   cQuery4+="         AND C5_FILIAL = C6_FILIAL "
   cQuery4+="         AND C5_NUM = C6_NUM "
   cQuery4+="         AND C5_I_OPER = '20' "
   cQuery4+="         AND C5_I_TRCNF <> 'S' "
   cQuery4+="         AND C5_EMISSAO >= '"+DToS(Date()-nDias)+"'"
   cQuery4+="         AND SC5.D_E_L_E_T_ = ' ' "
   cQuery4+="         AND F4_FILIAL = C6_FILIAL "
   cQuery4+="         AND F4_CODIGO = C6_TES "
   cQuery4+="         AND F4_ESTOQUE = 'S' "
   cQuery4+="         AND SF4.D_E_L_E_T_ = ' ' "
   cQuery4+="         AND EXISTS "
   cQuery4+="                (SELECT 'x' "
   cQuery4+="                   FROM  "+RetSqlName("Z20")+" Z20 "
   cQuery4+="                  WHERE     Z20_FILIAL = '"+Z19->Z19_FILIAL+"' "
   cQuery4+="                        AND Z20_REGRA  = '"+Z19->Z19_REGRA+"' "
   cQuery4+="                        AND Z20_COD = SC6.C6_PRODUTO "
   cQuery4+="                        AND Z20_MSBLQL <> '1' "
   cQuery4+="                        AND Z20.D_E_L_E_T_ = ' ')"
   cQuery4+="GROUP BY C6_PRODUTO, C6_DESCRI "
   cQuery4+="ORDER BY 1 "
   cQueryPT:=cQuery4

   _cAlias:=GetNextAlias()
   MPSysOpenQuery( cQuery4 , _cAlias) 
   AOMS116A(oProc,_cAlias ,_cTRB)//GRAVA O SELECT (_cAlias) NA TABELA (_cTRB)
   (_cAlias)->(DBCloseArea())

ElseIf _cTipo = "2" //2=Operador Logistico
  
   cQuery4+=" SELECT C6_PRODUTO PRODUTO, '"+Z19->Z19_FILIAL+"' FILIAL,  C6_DESCRI DESCRI, 0 QTDE_C , 0 QTDE_E , 0 QTDE_T , SUM(C6_UNSVEN) QTDE_PT , 0 QTDE_P3  "
   cQuery4+="    FROM "+RetSqlName("SC6")+" SC6, "
   cQuery4+="         "+RetSqlName("SC5")+" SC5, "
   cQuery4+="         "+RetSqlName("SF4")+" SF4  "
   cQuery4+="       WHERE C6_FILIAL   = '"+Z19->Z19_FILIAL+"' "
   If !Empty(Z19->Z19_OPERAD)
      cQuery4+="      AND C6_CLI = '"+Z19->Z19_OPERAD+"' "
      cQuery4+="      AND C6_LOJA = '"+Z19->Z19_OPELOJ+"' "
   EndIf
   cQuery4+="         AND SC6.C6_NOTA = ' ' "
   cQuery4+="         AND SC6.D_E_L_E_T_ = ' ' "
   cQuery4+="         AND SC5.C5_FILIAL = C6_FILIAL "
   cQuery4+="         AND SC5.C5_NUM = C6_NUM "
   cQuery4+="         AND SC5.C5_I_OPER = ' ' "
   cQuery4+="         AND SC5.C5_TIPO = 'B' "   
   cQuery4+="         AND C5_EMISSAO >= '"+DToS(Date()-nDias)+"'"
   cQuery4+="         AND SC5.D_E_L_E_T_ = ' ' "
   cQuery4+="         AND F4_FILIAL = C6_FILIAL "
   cQuery4+="         AND F4_CODIGO = C6_TES "
   cQuery4+="         AND F4_ESTOQUE = 'S' "
   cQuery4+="         AND SF4.D_E_L_E_T_ = ' ' "
   cQuery4+="         AND EXISTS "
   cQuery4+="                (SELECT 'x' "
   cQuery4+="                   FROM  "+RetSqlName("Z20")+" Z20 "
   cQuery4+="                  WHERE     Z20_FILIAL = '"+Z19->Z19_FILIAL+"' "
   cQuery4+="                        AND Z20_REGRA  = '"+Z19->Z19_REGRA+"' "
   cQuery4+="                        AND Z20_COD = SC6.C6_PRODUTO "
   cQuery4+="                        AND Z20_MSBLQL <> '1' "
   cQuery4+="                        AND Z20.D_E_L_E_T_ = ' ')"
   cQuery4+="GROUP BY C6_PRODUTO, C6_DESCRI "
   cQuery4+="ORDER BY 1 "
   cQueryPT:=cQuery4

   _cAlias:=GetNextAlias()
   MPSysOpenQuery( cQuery4 , _cAlias) 
   AOMS116A(oProc,_cAlias ,_cTRB)//GRAVA O SELECT (_cAlias) NA TABELA (_cTRB)
   (_cAlias)->(DBCloseArea())

EndIf

If oProc <> nil
   oProc:cCaption:="4/4-Lendo PED. TRANSFERENCIA 2/2..."
   ProcessMessages()
EndIf

If _cTipo = "1" //1=Reposicao entre Filiais
   cQuery4:=""
   cQuery4+=" SELECT C6_NUM , C6_PRODUTO PRODUTO, C6_FILIAL FILIAL, C5_EMISSAO ,  C6_DESCRI DESCRI, SUM(C6_UNSVEN) QTDE_PT , 0 QTDE_P3  "
   cQuery4+="    FROM "+RetSqlName("SC6")+" SC6, "
   cQuery4+="         "+RetSqlName("SC5")+" SC5, "
   cQuery4+="         "+RetSqlName("ZZM")+" ZZMO,"
   cQuery4+="         "+RetSqlName("ZZM")+" ZZMD,"
   cQuery4+="         "+RetSqlName("SA1")+" SA1, "
   cQuery4+="         "+RetSqlName("SF4")+" SF4  "
   cQuery4+="   WHERE     ZZMO.ZZM_FILIAL = ' ' "
   cQuery4+="         AND ZZMO.ZZM_CODIGO = C6_FILIAL
   cQuery4+="         AND ZZMO.D_E_L_E_T_ = ' ' "
   cQuery4+="         AND ZZMD.ZZM_FILIAL = ' ' "
   cQuery4+="         AND ZZMD.ZZM_CODIGO = '"+Z19->Z19_FILIAL+"' "
   cQuery4+="         AND ZZMD.D_E_L_E_T_ = ' ' "
   cQuery4+="         AND A1_FILIAL = ' ' "
   cQuery4+="         AND A1_CGC = ZZMD.ZZM_CGC "
   cQuery4+="         AND ZZMO.ZZM_CODIGO <> ZZMD.ZZM_CODIGO "
   cQuery4+="         AND SA1.D_E_L_E_T_ = ' ' "
   cQuery4+="         AND C6_CLI = A1_COD "
   cQuery4+="         AND C6_LOJA = A1_LOJA "
   cQuery4+="         AND C6_NOTA = ' ' "
   cQuery4+="         AND SC6.D_E_L_E_T_ = ' ' "
   cQuery4+="         AND C5_FILIAL = C6_FILIAL "
   cQuery4+="         AND C5_NUM = C6_NUM "
   cQuery4+="         AND C5_I_OPER = '20' "
   cQuery4+="         AND C5_I_TRCNF <> 'S' "
   cQuery4+="         AND C5_EMISSAO >= '"+DToS(Date()-nDias)+"'"
   cQuery4+="         AND SC5.D_E_L_E_T_ = ' ' "
   cQuery4+="         AND F4_FILIAL = C6_FILIAL "
   cQuery4+="         AND F4_CODIGO = C6_TES "
   cQuery4+="         AND F4_ESTOQUE = 'S' "
   cQuery4+="         AND SF4.D_E_L_E_T_ = ' ' "
   cQuery4+="         AND EXISTS "
   cQuery4+="                (SELECT 'x' "
   cQuery4+="                   FROM  "+RetSqlName("Z20")+" Z20 "
   cQuery4+="                  WHERE     Z20_FILIAL = '"+Z19->Z19_FILIAL+"' "
   cQuery4+="                        AND Z20_REGRA  = '"+Z19->Z19_REGRA+"' "
   cQuery4+="                        AND Z20_COD = SC6.C6_PRODUTO "
   cQuery4+="                        AND Z20_MSBLQL <> '1' "
   cQuery4+="                        AND Z20.D_E_L_E_T_ = ' ')"
   cQuery4+="GROUP BY C6_FILIAL , C6_NUM ,C5_EMISSAO, C6_PRODUTO, C6_DESCRI "
   cQuery4+="ORDER BY C6_PRODUTO ,  C6_FILIAL , C6_NUM "

   _cAlias2:=GetNextAlias()
   MPSysOpenQuery( cQuery4 , _cAlias2) 

ElseIf _cTipo = "2" //2=Operador Logistico

   cQuery4:=""
   cQuery4+=" SELECT C6_NUM , C6_PRODUTO PRODUTO, C6_FILIAL FILIAL, C5_EMISSAO ,  C6_DESCRI DESCRI, SUM(C6_UNSVEN) QTDE_PT , 0 QTDE_P3  "
   cQuery4+="    FROM "+RetSqlName("SC6")+" SC6, "
   cQuery4+="         "+RetSqlName("SC5")+" SC5, "
   cQuery4+="         "+RetSqlName("SF4")+" SF4  "
   cQuery4+="       WHERE C6_FILIAL   = '"+Z19->Z19_FILIAL+"' "
   If !Empty(Z19->Z19_OPERAD)
      cQuery4+="      AND C6_CLI = '"+Z19->Z19_OPERAD+"' "
      cQuery4+="      AND C6_LOJA = '"+Z19->Z19_OPELOJ+"' "
   EndIf
   cQuery4+="         AND SC6.C6_NOTA = ' ' "
   cQuery4+="         AND SC6.D_E_L_E_T_ = ' ' "
   cQuery4+="         AND SC5.C5_FILIAL = C6_FILIAL "
   cQuery4+="         AND SC5.C5_NUM = C6_NUM "
   cQuery4+="         AND SC5.C5_I_OPER = ' ' "
   cQuery4+="         AND SC5.C5_TIPO = 'B' "   
   cQuery4+="         AND SC5.C5_EMISSAO >= '"+DToS(Date()-nDias)+"'"
   cQuery4+="         AND SC5.D_E_L_E_T_ = ' ' "
   cQuery4+="         AND F4_FILIAL = C6_FILIAL "
   cQuery4+="         AND F4_CODIGO = C6_TES "
   cQuery4+="         AND F4_ESTOQUE = 'S' "
   cQuery4+="         AND SF4.D_E_L_E_T_ = ' ' "
   cQuery4+="         AND EXISTS "
   cQuery4+="                (SELECT 'x' "
   cQuery4+="                   FROM  "+RetSqlName("Z20")+" Z20 "
   cQuery4+="                  WHERE     Z20_FILIAL = '"+Z19->Z19_FILIAL+"' "
   cQuery4+="                        AND Z20_REGRA  = '"+Z19->Z19_REGRA+"' "
   cQuery4+="                        AND Z20_COD = SC6.C6_PRODUTO "
   cQuery4+="                        AND Z20_MSBLQL <> '1' "
   cQuery4+="                        AND Z20.D_E_L_E_T_ = ' ')"
   cQuery4+="GROUP BY C6_FILIAL , C6_NUM ,C5_EMISSAO, C6_PRODUTO, C6_DESCRI "
   cQuery4+="ORDER BY C6_PRODUTO ,  C6_FILIAL , C6_NUM "

   _cAlias2:=GetNextAlias()
   MPSysOpenQuery( cQuery4 , _cAlias2) 

EndIf


If oProc <> nil
   oProc:cCaption:="GRAVANDO TEMPORARIO..."
   ProcessMessages()
EndIf

AOMS116TRB(oProc,_cTRB,_cAlias2)//GRAVA O TRB (_cAlias) NA ARRAY (_aLinhas) e _cAlias2 na array _aPts

If _cAlias2 <> NIL
   (_cAlias2)->(DBCloseArea())
EndIf

(_cTRB)->(DBCloseArea())
_oTempTable:Delete()

_cTeste:="Tempo de execução: Hr. Inicial: "+_cTimeIni+", Hr. Final: "+TIME()+CRLF+CRLF
_cTeste+="CARTEIRA:  "+CRLF+cQuery1 +CRLF+CRLF
_cTeste+="ESTOQUE:   "+CRLF+cQueryP2+CRLF+CRLF
_cTeste+="ESTOQUE P3:"+CRLF+cQueryP3+CRLF+CRLF
_cTeste+="TRANSITO:  "+CRLF+cQuery3 +CRLF+CRLF
_cTeste+="PV TRANS:  "+CRLF+cQueryPT+CRLF+CRLF
_cTeste+="PV TRANS LISTA:"+CRLF+cQuery4+CRLF+CRLF
_cFileNome:="\DATA\ITALAC\CONTROLE\AOMS116_"+cFilAnt+"_"+StrTran(TIME(),":","_")+".TXT"
MemoWrite(_cFileNome,_cTeste)

Return .T.

/*
===============================================================================================================================
Programa--------: AOMS116A()
Autor-----------: Alex Wallauer
Data da Criacao-: 07/11/2019
Descrição-------: GRAVA O SELECT (_cAlias) NA TABELA (_cTRB)
Parametros------: oProc,_cAlias,_cTRB
==================================================================================================================================
*/
Static Function AOMS116A(oProc,_cAlias,_cTRB)

Local _nConta := 0
Local _cTot   :=""
Local _nTam   :=5

DBSelectArea(_cAlias)
COUNT To _nConta
_cTot  :=AllTrim(Str(_nConta))
_nTam  :=Len(_cTot)
_nConta:=0

(_cAlias)->(DBGoTop())
While (_cAlias)->(!Eof())
	
	_nConta++
	_aItens:={}
	
	If oProc <> nil
		oProc:cCaption := ("1/2-Gravando Temporario: "+AllTrim(StrZero(_nConta,_nTam)) +" de "+ _cTot)
		ProcessMessages()
	EndIf
    Z20->(DBSeek((_cAlias)->FILIAL+Z19->Z19_REGRA+(_cAlias)->PRODUTO))
    If  !(_cTRB)->(DBSeek((_cAlias)->FILIAL+Z20->Z20_FILREP+(_cAlias)->PRODUTO))
         (_cTRB)->(DBAPPEND())
	     (_cTRB)->FILIAL :=(_cAlias)->FILIAL //02
	     (_cTRB)->PRODUTO:=(_cAlias)->PRODUTO//03
	     (_cTRB)->DESCRI :=AllTrim(Posicione("SB1",1,xFilial("SB1")+(_cAlias)->PRODUTO,"B1_DESC")) //04
	     (_cTRB)->FILREPO:=Z20->Z20_FILREP   //15
    EndIf    
	(_cTRB)->QTDE_C +=(_cAlias)->QTDE_C  //05
	(_cTRB)->QTDE_E +=(_cAlias)->QTDE_E  //06
	(_cTRB)->QTDE_T +=(_cAlias)->QTDE_T  //07
	(_cTRB)->QTDE_PT+=(_cAlias)->QTDE_PT //08
	(_cTRB)->QTDE_P3+=(_cAlias)->QTDE_P3 //09
    (_cAlias)->(DBSkip())

EndDo  

Return .T.

/*
===============================================================================================================================
Programa--------: AOMS116TRB
Autor-----------: Alex Wallauer
Data da Criacao-: 07/11/2019
Descrição-------: GRAVA O TRB (_cAlias) NA ARRAY (_aLinhas)
Parametros------: oProc,_cAlias
==================================================================================================================================
*/
Static Function AOMS116TRB(oProc,_cAlias,_cPTAlias)

Local _nConta := 0
Local _cTot   :=""
Local _nTam   :=5
Local _cPict  :="@E 999,999,999,999.99"

If oProc <> nil
   oProc:cCaption:="Contando os dados lidos..."
   ProcessMessages()
EndIf

DBSelectArea(_cAlias)
_nConta := 0
COUNT To _nConta
_cTot:=AllTrim(Str(_nConta))
_nTam:=Len(_cTot)
_nConta:=0

(_cAlias)->(DBGoTop())
While (_cAlias)->(!Eof())
	
	_nConta++
	_aItens:={}

    If oProc <> nil
       oProc:cCaption := ("1/2-Gravando Temporario: "+AllTrim(StrZero(_nConta,_nTam)) +" de "+ _cTot)
       ProcessMessages()
    EndIf   

    Z20->(DBSeek((_cAlias)->FILIAL+Z19->Z19_REGRA+(_cAlias)->PRODUTO))
    SB1->(DBSeek(xFilial()+(_cAlias)->PRODUTO))
    
	If SB1->B1_CONV == 0
    	If SB1->B1_I_FATCO > 0	//SB1->B1_I_QQUEI == 'S' .And. 
    		_nfator := If(SB1->B1_TIPCONV=="M" , SB1->B1_I_FATCO , 1/SB1->B1_I_FATCO )	
    	Else	
    		_nfator := 0		
    	EndIf	
    Else
    	_nfator := If(SB1->B1_TIPCONV=="M" , SB1->B1_CONV , 1/SB1->B1_CONV )	
    EndIf
	(_cAlias)->QTDE_P3:= ( (_cAlias)->QTDE_P3*_nfator )//CONVERTO PARA A SEGUNDA UNIDADE DE MEDIDA
	(_cAlias)->QTDE_E := ( (_cAlias)->QTDE_E *_nfator )//CONVERTO PARA A SEGUNDA UNIDADE DE MEDIDA
    
    _nEstDisp:=(_cAlias)->QTDE_E+(_cAlias)->QTDE_P3+(_cAlias)->QTDE_T+(_cAlias)->QTDE_PT-(_cAlias)->QTDE_C
    _nQtdeaRepor:=nFator:=0
    If Z20->Z20_ESTIDE >_nEstDisp
       _nQtdeaRepor:=Z20->Z20_ESTIDE-_nEstDisp
       nFator:=_nQtdeaRepor/Z20->Z20_MINREP
       If nFator > INT(nFator)
          nFator:= INT(nFator)+1
       EndIf
       (_cAlias)->QTDE_RE:=nFator*Z20->Z20_MINREP
    EndIf  
    _nPeso := ( ((_cAlias)->QTDE_RE/_nfator) * SB1->B1_PESBRU )//CONVERTO PARA A PRIMEIRA UNIDADE E FAÇO X O PESO BRUTO
	aAdd(_aItens, Empty((_cAlias)->QTDE_RE) )          //01// .T. NAÕ GERA .F. GERA
	aAdd(_aItens,(_cAlias)->FILIAL)                    //02
	aAdd(_aItens,AllTrim((_cAlias)->PRODUTO))          //03
	aAdd(_aItens,(_cAlias)->DESCRI)                    //04
	aAdd(_aItens,TRANSFORM((_cAlias)->QTDE_RE,_cPict)) //05 //CALCULADO
	aAdd(_aItens,(_cAlias)->FILREPO)                   //06
	aAdd(_aItens,TRANSFORM((_cAlias)->QTDE_C ,_cPict)) //07
	aAdd(_aItens,TRANSFORM((_cAlias)->QTDE_E ,_cPict)) //08
	aAdd(_aItens,TRANSFORM((_cAlias)->QTDE_T ,_cPict)) //09
	aAdd(_aItens,TRANSFORM((_cAlias)->QTDE_PT,_cPict)) //10
	aAdd(_aItens,TRANSFORM(_nEstDisp         ,_cPict)) //11 //CALCULADO
	aAdd(_aItens,TRANSFORM(Z20->Z20_ESTIDE   ,_cPict)) //12
	aAdd(_aItens,TRANSFORM(Z20->Z20_MINREP   ,_cPict)) //13
	aAdd(_aItens,TRANSFORM(_nQtdeaRepor      ,_cPict)) //14 //CALCULADO
	aAdd(_aItens,TRANSFORM((_cAlias)->QTDE_P3,_cPict)) //15 // poder de terceiro novo
	aAdd(_aItens,TRANSFORM(nFator            ,_cPict)) //16 //CALCULADO
	aAdd(_aItens,TRANSFORM(_nPeso            ,_cPict)) //17 //CALCULADO - NOVO
	aAdd(_aItens,SB1->B1_SEGUM                       ) //18 - NOVO
	aAdd(_aItens,Z20->Z20_MSBLQL                     ) //19 - NOVO

    aAdd(_aLinhas,_aItens)

	(_cAlias)->(DBSkip())

EndDo  

If _cPTAlias <> NIL
   _cAlias:=_cPTAlias
   DBSelectArea(_cAlias)
   _nConta := 0
   COUNT To _nConta
   _cTot:=AllTrim(Str(_nConta))
   _nTam:=Len(_cTot)
   _nConta:=0
   _aPts:={}

    (_cAlias)->(DBGoTop())
	_cProd:=""
    While (_cAlias)->(!Eof())
    	
    	_nConta++
    	_aItens:={}
    
        If oProc <> nil
           oProc:cCaption := ("2/2-Gravando Temporario: "+AllTrim(StrZero(_nConta,_nTam)) +" de "+ _cTot)
           ProcessMessages()
        EndIf   
//    	aAdd(_aItens,AllTrim((_cAlias)->PRODUTO))       //01
        If _cProd = (_cAlias)->PRODUTO
    	   aAdd(_aItens," ")          //01
    	   aAdd(_aItens," ")          //02
		Else
    	   aAdd(_aItens,AllTrim((_cAlias)->PRODUTO))       //01
    	   aAdd(_aItens,(_cAlias)->DESCRI)                 //02
		   _cProd:= (_cAlias)->PRODUTO
        EndIf   
    	
		aAdd(_aItens,(_cAlias)->FILIAL)                    //03
    	aAdd(_aItens,(_cAlias)->C6_NUM)                    //04
		aAdd(_aItens,DToC(SToD((_cAlias)->C5_EMISSAO)))    //05
    	aAdd(_aItens,Posicione("SB1",1,xFilial("SB1")+(_cAlias)->PRODUTO,"B1_SEGUM"))//06
    	aAdd(_aItens,TRANSFORM((_cAlias)->QTDE_PT,_cPict)) //07
    
        aAdd(_aPts,_aItens)
    
    	(_cAlias)->(DBSkip())
    
    EndDo  

EndIf

Return .T.

/*
===============================================================================================================================
Programa----------: AOMS116EML()
Autor-------------: Alex Wallauer
Data da Criacao---: 11/11/2019
Descrição---------: Rotina para enviar e-mail de notificação 
Parametros--------: 
Retorno-----------: .T.
===============================================================================================================================
*/
Static Function AOMS116EML(_lProcessa,_aLog,oProc,_aLog2,_aPts)

Local _aConfig	:= U_ITCFGEML('')
Local _cMsgEml	:= '',_nI , E
Local _cData	:= DToC(Date())
Local _cHoraT   := _cTimeIni
Local _cNomeFil := cFilant+" - "+AllTrim( Posicione('SM0',1,"01"+cFilant,'M0_FILIAL') )
Local _cAssunto := "Workflow - Execução das Regras de Reposição automatica de estoque, Regra: "+Z19->Z19_REGRA//1=Reposicao entre Filiais;2=Operador Logistico;3=Reposicao entre Armazens
Local _aEmail   := {}
Local _cEmail	:= AllTrim(Z19->Z19_EMAIL)
Local _cEmailCo := ""

If _lProcessa
   If Type('__cUserId') == 'C'
      _cEmailCo := FWSFAllUsers({__cUserID},{'USR_EMAIL'})[1][3]
   EndIf
Else
   If Empty(_cEmail)
	  U_ITConOut('Sem e-mail cadastrado, verifique o campo de de E-Mmail [Z19_EMAIL] da regra: '+Z19->Z19_REGRA)
      Return .F.
   EndIf
EndIf

_cMsgEml := '<html>'
_cMsgEml += '<head><title>'+(_cAssunto+" - "+Z19->Z19_DESC)+'</title></head>'
_cMsgEml += '<body>'
_cMsgEml += '<style Type="text/css"><!--'
_cMsgEml += 'table.bordasimples { border-collapse: collapse; }'
_cMsgEml += 'table.bordasimples tr td { border:1px solid #777777; }'
_cMsgEml += 'td.titulos	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #C6E2FF; }'
_cMsgEml += 'td.grupos	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #E5E5E5; }'
_cMsgEml += 'td.itens	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #FFFFFF; }'
_cMsgEml += 'td.aceito	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #00CC00; }'
_cMsgEml += 'td.recusa  { font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #FF0000; }'
_cMsgEml += 'td.AZUL    { font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #0000FF; }'
_cMsgEml += 'td.amarelo { font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #FFFF00; }'
_cMsgEml += '--></style>'
_cMsgEml += '<center>'
_cMsgEml += '<img src="http://www.italac.com.br/wf/italac-wf.jpg" width="700" height="50"><br>'
_cMsgEml += '<table class="bordasimples" width="700">'
_cMsgEml += '    <tr>'
_cMsgEml += '	<td class="titulos"><center>Log de Processamento</center></td>'
_cMsgEml += '	</tr>'
_cMsgEml += '</table>'
_cMsgEml += '<br>'
_cMsgEml += '<table class="bordasimples" width="700">'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td align="center" colspan="2" class="grupos">'+(_cAssunto+" - "+Z19->Z19_DESC)+'</b></td>'
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="center" width="20%"><b>Data:</b></td>'
_cMsgEml += '      <td class="itens" align="left" >'+ _cData +'</td>'
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="center" width="20%"><b>Hora inicial:</b></td>'
_cMsgEml += '      <td class="itens" align="left" >'+ _cHoraT +'</td>'
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="center" width="20%"><b>Hora final:</b></td>'
_cMsgEml += '      <td class="itens" align="left" >'+ Time() +'</td>'
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="center" width="30%"><b>Filial:</b></td>'
_cMsgEml += '      <td class="itens" >'+ _cNomeFil +'</td>'
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="center" width="20%"><b>Observação:</b></td>'
_cMsgEml += '      <td class="itens" align="left" >#OBS#</td>'
_cMsgEml += '    </tr>'
If !_lProcessa
    _cAssunto += " - "+_cNomeFil
    _cAssunto += ' - Processamento agendado (Schedule)'
   _cMsgEml += ' <tr>'
   _cMsgEml += '   <td class="titulos" align="center" colspan="2"><font color="red">Esta é uma mensagem automática. Por favor não responder!</font></td>'
   _cMsgEml += ' </tr>'
EndIf
_cMsgEml += '</table>'

If _aLog2 # NIL .And. !Empty(_aLog2)  .And. Len( _aLog2 ) > 0
	
	_cMsgEml += '<br>'
	_cMsgEml += '<table class="bordasimples" width="1300">'
	_cMsgEml += '    <tr>'
	_cMsgEml += '      <td align="center" colspan="'+AllTrim(Str(Len( _aLog2[1])))+'" class="grupos"><b>PEDIDOS DOS PRODUTOS</b></td>'
	_cMsgEml += '    </tr>'

	_aSizes:={"01","05","05","36","10","43"}

	_cMsgEml += '    <tr>'
	_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[01]+'%"><b>Gerado</b></td>'
  	_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[02]+'%"><b>Filial</b></td>'
	_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[03]+'%"><b>Pedido</b></td>'
  	_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[04]+'%"><b>Produto</b></td>'
	_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[05]+'%"><b>Quantidade</b></td>'
	_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[06]+'%"><b>Erro</b></td>'
	_cMsgEml += '    </tr>'

	If _lProcessa
       _nConta:= Len( _aLog2 )
       _cTot  :=AllTrim(Str(_nConta))
       _nTam  :=Len(_cTot)
       _nConta:=0
	EndIf

	For _nI := 1 To Len( _aLog2 )
	    If _lProcessa
		   oProc:cCaption := ("1/1-Enviando Produto: "+AllTrim(StrZero(_nConta,_nTam)) +" de "+ _cTot)
		   ProcessMessages()
	    EndIf
	    _nQtde2UM :=StrTran(_aLog2[_nI,5] ,"." ,"" )  //Tira o ponto dos milhar
        _nQtde2UM :=Val(StrTran(_nQtde2UM            ,"," ,".") )//Tira a virgula e poe o ponto para o Val não comer a decimal

		If _nQtde2UM = 0 .Or. _aLog[_nI][_nPosColAcao] = "3"
		  //-RETIRA OS:
          //-Não tem necessidade de repor ainda
          //-A acao desse item é so listar
		  Loop
		EndIf

		_cMsgEml += '    <tr>'
		If _aLog2[_nI][01] 
		   _cMsgEml += '    <td class="aceito"  align="center" width="'+_aSizes[01]+'%"><b>Sim</b></td>'
		Else
		   _cMsgEml += '    <td class="recusa"  align="center" width="'+_aSizes[01]+'%"><b>Não</b></td>'
		EndIf
        _cMsgEml += '     <td class="itens" align="center" width="'+_aSizes[02]+'%">'+_aLog2[_nI][02]+'</td>'
        _cMsgEml += '     <td class="itens" align="center" width="'+_aSizes[03]+'%">'+_aLog2[_nI][03]+'</td>'
  	    _cMsgEml += '      <td class="itens" align="left"   width="'+_aSizes[04]+'%">'+_aLog2[_nI][04]+'</td>'
	    _cMsgEml += '      <td class="itens" align="right"  width="'+_aSizes[05]+'%">'+_aLog2[_nI][05]+'</td>'
	    _cMsgEml += '      <td class="itens" align="left"   width="'+_aSizes[06]+'%">'+_aLog2[_nI][06]+'</td>'
		_cMsgEml += '    </tr>'
    	
	Next _nI
	
	_cMsgEml += '</table>'

    _aCab[01]:="Gerado"
Else
    _aCab[01]:="Repor"
EndIf
_cObsT:=""
////////////////////////    DETALHAMENTO DOS PRODUTOS   /////////////////////////////////////////////
If _aLog # NIL .And. !Empty(_aLog)  .And. Len( _aLog ) > 0
	//         01   02   03   04   05   06   07   08   09   10   11   12   13   14   15   16   17
	_aSizes:={"01","xx","50","xx","12","05","05","04","05","05","05","05","xx","05","05","05","05"}
	_aCab[16]:="Peso"

	_cMsgEml += '<br>'
	_cMsgEml += '<table class="bordasimples" width="1900">'
	_cMsgEml += '    <tr>'
	_cMsgEml += '      <td align="center" colspan="'+AllTrim(Str(Len(_aSizes)-3))+'" class="grupos"><b>DETALHAMENTO DOS PRODUTOS</b></td>'
	_cMsgEml += '    </tr>'
	_cMsgEml += '    <tr>'
	_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[01]+'%"><b>'+_aCab[01]+'</b></td>'
	_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[03]+'%"><b>'+_aCab[03]+'</b></td>'
	_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[17]+'%"><b>'+_aCab[17]+'</b></td>'
	_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[05]+'%"><b>'+_aCab[05]+'</b></td>'
	_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[16]+'%"><b>'+_aCab[16]+'</b></td>'
	_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[06]+'%"><b>'+_aCab[06]+'</b></td>'
	_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[07]+'%"><b>'+_aCab[07]+'</b></td>'
	_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[08]+'%"><b>'+_aCab[08]+'</b></td>'
	_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[09]+'%"><b>'+_aCab[09]+'</b></td>'
	_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[10]+'%"><b>'+_aCab[10]+'</b></td>'
	_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[11]+'%"><b>'+_aCab[11]+'</b></td>'
	_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[12]+'%"><b>'+_aCab[12]+'</b></td>'
	_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[14]+'%"><b>'+_aCab[14]+'</b></td>'
	_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[15]+'%"><b>'+_aCab[_nColPoder3o]+'</b></td>'
	_cMsgEml += '    </tr>'
	
	If _lProcessa
       _nConta:= Len( _aLog )
       _cTot  :=AllTrim(Str(_nConta))
       _nTam  :=Len(_cTot)
       _nConta:=0
	EndIf

    _nCriado:=0
    _nNCriado:=0

	For _nI := 1 To Len( _aLog )
	    If _lProcessa
		   oProc:cCaption := ("1/1-Enviando Produto: "+AllTrim(StrZero(_nConta,_nTam)) +" de "+ _cTot)
		   ProcessMessages()
	    EndIf

		_cMsgEml += '    <tr>'
        
		_cListar:=""
		If _aLog[_nI][_nPosColAcao]  = "3"
		   _cListar:="(*)"
		EndIf

	    _nEstoque :=StrTran(_aLog[_nI,_nPosColEst],"." , "" )  //Tira o ponto dos milhar
	    _nEstoque :=Val(StrTran(_nEstoque         ,"," , ".") )//Tira a virgula e poe o ponto para o Val não comer a decimal
    
	    _nCarteir :=StrTran(_aLog[_nI,_nPosColCar],"." , "" )  //Tira o ponto dos milhar
	    _nCarteir :=Val(StrTran(_nCarteir         ,"," , ".") )//Tira a virgula e poe o ponto para o Val não comer a decimal

		If _aCab[01] = "Repor"// TELA ANTES DE GERAR
		   If _aLog[_nI][01] 
              _nNCriado++
		      If _nEstoque < _nCarteir//ESTOQUE < CARTEIRA
		   	     _cMsgEml += '      <td class="amarelo" align="center" width="'+_aSizes[01]+'%"><b>Não'+_cListar+'</b></td>'
			  Else//ESTOQUE >= CARTEIRA
		         _cMsgEml += '      <td class="aceito" align="center" width="'+_aSizes[01]+'%"><b>Não'+_cListar+'</b></td>'
			  EndIf
		   Else
		      _nCriado++
		      If _nEstoque < _nCarteir//ESTOQUE < CARTEIRA
		   	     _cMsgEml += '      <td class="recusa" align="center" width="'+_aSizes[01]+'%"><b>Sim'+_cListar+'</b></td>'
			  Else//ESTOQUE >= CARTEIRA
		         _cMsgEml += '      <td class="AZUL" align="center" width="'+_aSizes[01]+'%"><b>Sim'+_cListar+'</b></td>'
			  EndIf
		   EndIf
        Else//"Gerado" Tela depois de gerar e schedule // A LOGICA AQUI É INVERTIDA: O .T. GEROU E É VERDE, NA TELA ERA VERMELHO 
		   If _aLog[_nI][01] //O .T. GEROU PEDIDO É VERDE, NA TELA ERA VERMELHO
              _nCriado++
		      If _nEstoque < _nCarteir//ESTOQUE < CARTEIRA
		   	     _cMsgEml += '      <td class="aceito" align="center" width="'+_aSizes[01]+'%"><b>Sim'+_cListar+'</b></td>'
			  Else//ESTOQUE > CARTEIRA
		         _cMsgEml += '      <td class="AZUL" align="center" width="'+_aSizes[01]+'%"><b>Sim'+_cListar+'</b></td>'
			  EndIf
		   Else//E O .F. NÃO GEROU E É VERMELHO, NA TELA ERA VERDE 
              _nNCriado++
		      If _nEstoque < _nCarteir//ESTOQUE < CARTEIRA
		         _cMsgEml += '      <td class="amarelo" align="center" width="'+_aSizes[01]+'%"><b>Não'+_cListar+'</b></td>'
			  Else//ESTOQUE > CARTEIRA
		         _cMsgEml += '      <td class="recusa" align="center" width="'+_aSizes[01]+'%"><b>Não'+_cListar+'</b></td>'
			  EndIf
		   EndIf
		EndIf
       _cMsgEml += '      <td class="itens" align="left"   width="'+_aSizes[03]+'%">'+_aLog[_nI][03]+"-"+_aLog[_nI][04]+'</td>'
	    _cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[17]+'%">'+_aLog[_nI][17]+'</td>'
	    _cMsgEml += '      <td class="itens" align="right"  width="'+_aSizes[05]+'%">'+_aLog[_nI][05]+'</td>'
       _cMsgEml += '      <td class="itens" align="right"  width="'+_aSizes[16]+'%">'+_aLog[_nI][16]+'</td>'
	    _cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[06]+'%">'+_aLog[_nI][06]+'</td>'
	    _cMsgEml += '      <td class="itens" align="right"  width="'+_aSizes[07]+'%">'+_aLog[_nI][07]+'</td>'
    	 _cMsgEml += '      <td class="itens" align="right"  width="'+_aSizes[08]+'%">'+_aLog[_nI][08]+'</td>'
	    _cMsgEml += '      <td class="itens" align="right"  width="'+_aSizes[09]+'%">'+_aLog[_nI][09]+'</td>'
    	 _cMsgEml += '      <td class="itens" align="right"  width="'+_aSizes[10]+'%">'+_aLog[_nI][10]+'</td>'
	    _cMsgEml += '      <td class="itens" align="right"  width="'+_aSizes[11]+'%">'+_aLog[_nI][11]+'</td>'
    	 _cMsgEml += '      <td class="itens" align="right"  width="'+_aSizes[12]+'%">'+_aLog[_nI][12]+'</td>'
//     _cMsgEml += '      <td class="itens" align="right"  width="'+_aSizes[13]+'%">'+_aLog[_nI][13]+'</td>'
    	 _cMsgEml += '      <td class="itens" align="right"  width="'+_aSizes[14]+'%">'+_aLog[_nI][14]+'</td>'
   	 _cMsgEml += '      <td class="itens" align="right"  width="'+_aSizes[15]+'%">'+_aLog[_nI][_nColPoder3o]+'</td>'
		 _cMsgEml += '    </tr>'
        
    	
	Next _nI
////////////////////////    DETALHAMENTO DOS PRODUTOS   /////////////////////////////////////////////
	
	_cMsgEml += '</table>'

	If _aCab[01] = "Repor"
       _cObsT:=StrZero(_nCriado ,4)+' Produtos que precisam de reposição  = "Sim" (vermelho) '+CHR(13)+CHR(10)
       _cObsT+=StrZero(_nNCriado,4)+' Produtos que NÃO precisam de reposição = "Não" (verde) '+CHR(13)+CHR(10)
    Else
       _cObsT:=StrZero(_nCriado ,4)+' Produtos que geraram Pedidos ('+TRIM(Str(_nQtdePV))+') = "Sim" (verde) '+CHR(13)+CHR(10)
       _cObsT+=StrZero(_nNCriado,4)+' Produtos que NÃO geraram Pedidos = "Não" (vermelho) '+CHR(13)+CHR(10)
    EndIf   
    _cObsT+='(*) Produtos somente Listados e não processados'+CHR(13)+CHR(10)
	
EndIf

If _aPts # NIL .And. !Empty(_aPts)  .And. Len( _aPts ) > 0
	_aSizes:={"10","40","10","10","10","10","10"}

	_cMsgEml += '<br>'
	_cMsgEml += '<table class="bordasimples" width="1300">'
	_cMsgEml += '    <tr>'
	_cMsgEml += '      <td align="center" colspan="'+AllTrim(Str(Len(_aSizes)))+'" class="grupos"><b>DETALHAMENTO DOS PEDIDOS DE TRANSFERENCIA</b></td>'
	_cMsgEml += '    </tr>'
	_cMsgEml += '    <tr>'
	_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[01]+'%"><b>'+_aCabPT[01]+'</b></td>'
  	_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[02]+'%"><b>'+_aCabPT[02]+'</b></td>'
	_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[03]+'%"><b>'+_aCabPT[03]+'</b></td>'
  	_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[04]+'%"><b>'+_aCabPT[04]+'</b></td>'
	_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[05]+'%"><b>'+_aCabPT[05]+'</b></td>'
	_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[06]+'%"><b>'+_aCabPT[06]+'</b></td>'
	_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[07]+'%"><b>'+_aCabPT[07]+'</b></td>'
	_cMsgEml += '    </tr>'
	
	If _lProcessa
       _nConta:= Len( _aPts )
       _cTot  :=AllTrim(Str(_nConta))
       _nTam  :=Len(_cTot)
       _nConta:=0
	EndIf

	For _nI := 1 To Len( _aPts )
	    If _lProcessa
		   oProc:cCaption := ("1/1-Enviando Produto: "+AllTrim(StrZero(_nConta,_nTam)) +" de "+ _cTot)
		   ProcessMessages()
	    EndIf

		_cMsgEml += '    <tr>'
        _cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[01]+'%">'+_aPts[_nI][01]+'</td>'
        _cMsgEml += '      <td class="itens" align="left"   width="'+_aSizes[02]+'%">'+_aPts[_nI][02]+'</td>'
  	    _cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[03]+'%">'+_aPts[_nI][03]+'</td>'
	    _cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[04]+'%">'+_aPts[_nI][04]+'</td>'
	    _cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[05]+'%">'+_aPts[_nI][05]+'</td>'
	    _cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[06]+'%">'+_aPts[_nI][06]+'</td>'
	    _cMsgEml += '      <td class="itens" align="right"  width="'+_aSizes[07]+'%">'+_aPts[_nI][07]+'</td>'
		_cMsgEml += '    </tr>'        
    	
	Next _nI
	
	_cMsgEml += '</table>'

EndIf

_cMsgEml += '</center>'
_cMsgEml += '    <br>'
_cMsgEml += '    <br>'
_cMsgEml += '    <br>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="center" ><b>Ambiente:</b></td>'
_cMsgEml += '      <td class="itens" align="left" > ['+ GETENVSERVER() +'] / <b>Fonte:</b> [AOMS116]</td>'
_cMsgEml += '    </tr>'

_cMsgEml += '</body>'
_cMsgEml += '</html>'
_cEmlLog := ''

_cEmail:=StrTran(_cEmail,";",",")
_aEmail:=StrTokArr(_cEmail,",")// Lista de email

_cMsgEml:=StrTran(_cMsgEml,"#OBS#",_cObsT)

_cFileNome:="\DATA\ITALAC\CONTROLE\AOMS116_"+cFilAnt+"_"+DToS(Date())+"_"+StrTran(TIME(),":","_")+".HTM"
MemoWrite(_cFileNome,_cMsgEml)

For E := 1 To Len(_aEmail)

    
    _cEmail:=_aEmail[E]
    U_ITConOut('Enviando E-mail(s) para: '+_cEmail+ " - Log de Processamento - "+TIME()+" - [ Enviando E-mail para Filial: "+cFilAnt+" ]")

    //    ITEnvMail(cFrom     ,cEmailTo ,_cEmailCo,cEmailBcc,cAssunto ,cMensagem,cAttach   ,cAccount    ,cPassword   ,cServer      ,cPortCon    ,lRelauth     ,cUserAut     ,cPassAut     ,cLogErro)
    U_ITENVMAIL( _aConfig[01] , _cEmail ,_cEmailCo,         ,_cAssunto, _cMsgEml ,         ,_aConfig[01],_aConfig[02], _aConfig[03],_aConfig[04], _aConfig[05], _aConfig[06], _aConfig[07], @_cEmlLog )

    If !Empty( _cEmlLog )
       If _lProcessa
          U_ITMsg(Upper(_cEmlLog)+CHR(13)+CHR(10)+"E-mail para: "+_cEmail+CHR(13)+CHR(10)+"Com Copia: "+_cEmailCo,"Envio do E-MAIL",,2)
       Else
          U_ITConOut(_cEmlLog+CHR(13)+CHR(10)+" E-mails: "+_cEmail)
       EndIf
    EndIf

Next

Return .T.

/*
===============================================================================================================================
Programa----------: AOMS115INV
Autor-------------: Alex Wallauer
Data da Criacao---: 20/07/2019
Descrição---------: Rotina de duplo clique na linha do browse
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS116GET(oLbxAux)

Local _nLinPos  := oLbxAux:nAt
Local _bOK
Local _cPict  :="@E 999,999,999.99"

If oLbxAux:nColPos == _nPosColRepo
	
    _bOK:={|| If(_nQtde >= 0,.T.,(U_ITMsg("Quantidade INVALIDO",'Atenção!',"Tente novamente com valor maior que zero",3),.F.) ) }
	_nQtde :=StrTran(_aLinhas[_nLinPos,_nPosColRepo],".","") //Tira o ponto dos milhar
	_nQtde :=Val(StrTran(_nQtde,",",".") )//Tira a virgula e poe o ponto para o Val não comer a decimal
	lOK:=.F.
	@ 00,00 To 100,280 Dialog oDlgDes Title "Quantidade de Reposição"
	@ 11,10 Say "Quantidade:" Pixel of oDlgDes
	@ 10,50 MsGet _nQtde Picture "@E 999,999,999.99"  Pixel Of oDlgDes
	@ 30,50 BMPBUTTON Type 1 ACTION (If(EVAL(_bOK),(lOK:=.T.,Close(oDlgDes)),))
	@ 30,82 BMPBUTTON Type 2 ACTION Close(oDlgDes)
	Activate Dialog oDlgDes Center

   If lOK
       _aLinhas[_nLinPos,_nPosColRepo]:=TRANSFORM(_nQtde,_cPict)
       oLbxAux:aArray[ _nLinPos , _nPosColRepo ] := TRANSFORM(_nQtde,_cPict)
       oLbxAux:aArray[ _nLinPos , 1 ] := (_nQtde = 0)       
   EndIf

ElseIf oLbxAux:nColPos == _nPosColFil
	
    _bOK:={|| Empty(_cFilRep) .Or. ExistCpo("SM0",cEmpAnt+_cFilRep,1) }
	_cFilRep:=_aLinhas[_nLinPos,_nPosColFil]
	lOK:=.F.
	@ 00,00 To 100,300 Dialog oDlgDes Title "Filial de Transferencia"
	@ 12,10 Say "Filial:" Pixel of oDlgDes
	@ 10,48 MsGet _cFilRep Picture "!!"  Pixel Of oDlgDes SIZE 25, 10 F3 "SM0" //SM0001
	@ 30,50 BMPBUTTON Type 1 ACTION (If(EVAL(_bOK),(lOK:=.T.,Close(oDlgDes)),))
	@ 30,82 BMPBUTTON Type 2 ACTION Close(oDlgDes)
	Activate Dialog oDlgDes Center

   If lOK
       _aLinhas[_nLinPos,_nPosColFil]:=_cFilRep
       oLbxAux:aArray[ _nLinPos , _nPosColFil ] := _cFilRep
   EndIf
   
EndIf

oLbxAux:Refresh()
ProcessMessages()

Return

/*
===============================================================================================================================
Programa----------: AOMSCriaPed()
Autor-------------: Alex Wallauer
Data da Criacao---: 20/07/2019
Descrição---------: Rotina de duplo clique na linha do browse
Parametros--------: _cFilRepo,_aItens,_lSchedule
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMSCriaPed(_cFilRepo,_aItens,_lSchedule)

Local _cMensagem:=""  , P  , L
Local cPV       :=""
Local _aCabPV   :={}
Local _aItensPV :={}
Local _aItemPV  :={}
Local nRecSM0   :=SM0->(RECNO())
Local _nDias    :=0,_dDtEnt
Local _cSalveFil:=cFilAnt//90 - Filial de Destino
Local _cCodUsu  := "" As Character

//====================================================================================================
// BUSCA O TRANSATE TIME DA FILIAL ORIGEM
//====================================================================================================
cFilAnt:=_cFilRepo       //01 - Filial de Origem
SM0->(DBSetOrder(1) )
SM0->(DBSeek(cEmpAnt + cFilAnt))//01 - Filial de Origem
SA1->(DBSetOrder(3))
SA1->(DBSeek(xFilial("SA1")+SM0->M0_CGC))//01 - Filial de Origem
aHeader:={}
aAdd(aHeader,{,"C6_ITEM"   })
aAdd(aHeader,{,"C6_PRODUTO"})
aAdd(aHeader,{,"C6_LOCAL"  })
acols:={{" "," "," "}}
_nDias := U_OMSVLDENT(Date(),SA1->A1_COD,SA1->A1_LOJA,cFilAnt,"",1,.F.)//01 - Filial de Origem
_dDtEnt := (Date() + _ndias + 1)

//====================================================================================================
// BUSCA O CLIENTE DA FILIAL DE DESTINO
//====================================================================================================
SM0->(DBSeek(cEmpAnt + _cSalveFil))      //90 - Filial de Destino
SA1->(DBSeek(xFilial("SA1")+SM0->M0_CGC))//90 - Filial de Destino CLIENTE

//====================================================================================================
// Monta o cabeçalho do pedido 
//====================================================================================================
SM0->(DBSeek(cEmpAnt + cFilAnt))//VOLTA PARA 01 - Filial de Origem

aAdd( _aCabPV, { "C5_FILIAL "	,cFilAnt     , Nil})//FILIAL

If !_lJob
   _cCodUsu	:= FWSFAllUsers({__cUserID},{"USR_FILIAL"})[1][3]+FWSFAllUsers({__cUserID},{"USR_CODFUNC"})[1][3]
Else
   _cCodUsu	:= "SISTEMA"
EndIf

If Z19->Z19_TIPO = "2"//2=Operador Logistico

   SA2->(DBSetOrder(1))
   SA2->(DBSeek(xFilial()+Z19->Z19_OPERAD+Z19->Z19_OPELOJ))
   aAdd( _aCabPV, { "C5_TIPO   "   ,"B"         , Nil})//Tipo de pedido
   aAdd( _aCabPV, { "C5_CLIENTE"	,SA2->A2_COD , NiL})//Codigo do cliente
   aAdd( _aCabPV, { "C5_LOJAENT"	,SA2->A2_LOJA, NiL})//Loja para entrada
   aAdd( _aCabPV, { "C5_LOJACLI"	,SA2->A2_LOJA, NiL})//Loja do cliente
   aAdd( _aCabPV, { "C5_TIPOCLI"	,"R", NiL})//Tipo do Cliente

ElseIf Z19->Z19_TIPO = "1"//1=Reposicao entre Filiais
   
   aAdd( _aCabPV, { "C5_TIPO   "   ,"N"         , Nil})//Tipo de pedido
   aAdd( _aCabPV, { "C5_I_OPER "   ,"20"        , Nil})//Tipo da operacao
   aAdd( _aCabPV, { "C5_CLIENTE"	,SA1->A1_COD , NiL})//Codigo do cliente
   aAdd( _aCabPV, { "C5_LOJAENT"	,SA1->A1_LOJA, NiL})//Loja para entrada
   aAdd( _aCabPV, { "C5_LOJACLI"	,SA1->A1_LOJA, NiL})//Loja do cliente
   aAdd( _aCabPV, { "C5_TIPOCLI"	,SA1->A1_TIPO, NiL})//Tipo do Cliente

EndIf

aAdd( _aCabPV, { "C5_EMISSAO"	,Date()      , NiL})//Data de emissao
aAdd( _aCabPV, { "C5_CONDPAG"	,"001"       , NiL})//Codigo da condicao de pagamanto*
aAdd( _aCabPV, { "C5_VEND1  "   , SA1->A1_VEND												, Nil })
aAdd( _aCabPV, { "C5_VEND2  "   , Posicione('SA3',1,xFilial('SA3')+SA1->A1_VEND,'A3_SUPER')	, Nil })
aAdd( _aCabPV, { "C5_VEND3  "   , SA3->A3_GEREN												, Nil })
aAdd( _aCabPV, { "C5_I_DTENT"	,_dDtEnt     								                , Nil})//Dt de Entrega
aAdd( _aCabPV, { "C5_I_AGEND"	,"I"         								                , Nil})
aAdd( _aCabPV, { "C5_I_OBPED" 	,'Pedido de reposicao automatica de estoque - AOMS116'		, Nil })
aAdd( _aCabPV, { "C5_I_CDUSU" 	,_cCodUsu		                                             , Nil })

_cLogCpos:="DATA: "+DToC(Date())+ " HORA: "+TIME()+CRLF+CRLF
_cLogCpos+="DADOS DA CAPA:"+CRLF
For P := 1 To Len(_aCabPV) 
    If ValType(_aCabPV[P,2]) = "D"
       _cLogCpos+=_aCabPV[P,1]+" = "+DToC(_aCabPV[P,2])+CRLF
    Else
       _cLogCpos+=_aCabPV[P,1]+" = "+_aCabPV[P,2]+CRLF
    EndIf   
Next
_cLogCpos+=CRLF

//====================================================================================================
// Monta o item do pedido
//====================================================================================================
cPV:=""
_cMensagem:=""

Begin Sequence

SB1->(DBSetOrder(1))
SBZ->(DBSetOrder(1))
Z09->(DBSetOrder(3)) // Z09_FILIAL+Z09_FILORI+Z09_FILDES+Z09_CODOPE+Z09_CODPRO 
For P := 1 To Len(_aItens)
	
	_nQtde2UM :=StrTran(_aItens[P,_nPosColRepo],".","") //Tira o ponto dos milhar
	_nQtde2UM :=Val(StrTran(_nQtde2UM,",",".") )//Tira a virgula e poe o ponto para o Val não comer a decimal
	_nPreco:=0
	SB1->(DBSeek(xFilial()+_aItens[P,_nPosColProd]))
	SBZ->(DBSeek(cFilAnt+SB1->B1_COD))
	
	If SB1->B1_CONV = 0 //SB1->B1_I_QQUEI == 'S'//QUEIJOS
		nFator:=SB1->B1_I_FATCO
	Else
		nFator:=SB1->B1_CONV
	EndIf
	
	If SB1->B1_TIPCONV == "D" // TIPO DE CONVERSAO INVERTIDA PQ É PARA VOLTAR PARA PRIMIERA
		_nQtd1UM := _nQtde2UM * nFator
	Else
		_nQtd1UM := _nQtde2UM / nFator
	EndIf
	
	If SB1->B1_I_CXPAL <> 0
		If mod(_nQtde2UM,SB1->B1_I_CXPAL) > 0
			_nqtv := int(_nQtde2UM /SB1->B1_I_CXPAL) + 1
		Else
			_nqtv := int(_nQtde2UM /SB1->B1_I_CXPAL)
		EndIf
	EndIf
	
	If (Z09->(DBSeek(xFilial()+         cFilAnt+_cSalveFil  +"20"+SB1->B1_COD )) .OR.;
		Z09->(DBSeek(xFilial()+Space(Len(cFilAnt+_cSalveFil))+"20"+SB1->B1_COD )) ) .AND.;
		(Date() >= Z09->Z09_INIVIG .And. Date() <= Z09->Z09_FIMVIG)
		_nPreco:=Z09->Z09_PRECO
	Else
		_cMensagem+="Prod.: "+SB1->B1_COD+" sem Preco na tabela de tranferencia"
      If !Empty(Z09->Z09_INIVIG)
		   _cMensagem+=" ou fora da data de vigencia: de "+DToC(Z09->Z09_INIVIG)+" ate "+DToC(Z09->Z09_FIMVIG)
      EndIf
	   _cMensagem+=CHR(13)+CHR(10)
	EndIf
    
    If _nqtv > 999 // não pode ser maior que (999) novecentos e noventa e nove pq estora o campo 
 	   _cMensagem+="Prod.: "+SB1->B1_COD+" com quantidade de Pallet maior que 999 "+CHR(13)+CHR(10)
    EndIf
	
	_aItemPV:={}
	aAdd( _aItemPV , { "C6_ITEM   "  ,StrZero(P,2)      , Nil }) // Numero do Item no Pedido
	aAdd( _aItemPV , { "C6_FILIAL "  ,cFilAnt           , Nil }) // FILIAL
	aAdd( _aItemPV , { "C6_PRODUTO"  ,SB1->B1_COD       , Nil }) // Codigo do Produto
	aAdd( _aItemPV , { "C6_QTDVEN "  ,_nQtd1UM          , Nil }) // Quantidade Vendida 1a U.M.
	aAdd( _aItemPV , { "C6_UNSVEN "  ,_nQtde2UM         , Nil }) // Quantidade Vendida 2a U.M.
	aAdd( _aItemPV , { "C6_PRCVEN "  ,_nPreco           , Nil }) // Preco Unitario Liquido
	aAdd( _aItemPV , { "C6_PRUNIT "  ,_nPreco           , Nil }) // Preco Unitario Liquido
	aAdd( _aItemPV , { "C6_ENTREG "  ,_dDtEnt           , Nil }) // Data da Entrega
	aAdd( _aItemPV , { "C6_VALOR  "  ,(_nPreco*_nQtd1UM), Nil }) // valor total do item
	aAdd( _aItemPV , { "C6_UM     "  ,SB1->B1_UM        , Nil }) // Unidade de Medida Primar.
   If Z19->Z19_TIPO = "2"//2=Operador Logistico
	   aAdd( _aItemPV , { "C6_OPER"  ,"06"    , Nil }) // Tipo da operacao para gatilhar a TES
	   aAdd( _aItemPV , { "C6_LOCAL" ,"52"    , Nil }) // Almoxarifado
   ElseIf Z19->Z19_TIPO = "1"//1=Reposicao entre Filiais
	   aAdd( _aItemPV , { "C6_LOCAL  "  ,SBZ->BZ_LOCPAD    , Nil }) // Almoxarifado
   EndIf
	aAdd( _aItemPV , { "C6_I_QPALT"  ,_nqtv             , Nil }) // Almoxarifado
	
	_cLogCpos+="DADOS DO ITEM "+AllTrim(Str(P))+" :"+CRLF
	For L := 1 To Len(_aItemPV)
		If ValType(_aItemPV[L,2]) = "N"
			_cLogCpos+=_aItemPV[L,1]+" = "+Str(_aItemPV[L,2],20,5)+CRLF
        ElseIf ValType(_aItemPV[L,2]) = "D"
            _cLogCpos+=_aItemPV[L,1]+" = "+DToC(_aItemPV[L,2])+CRLF
		Else
			_cLogCpos+=_aItemPV[L,1]+" = "+_aItemPV[L,2]+CRLF
		EndIf
	Next
	_cLogCpos+="MESAGEM: ["+_cMensagem+"]"
	_cLogCpos+=CRLF	
	
	aAdd( _aItensPV ,_aItemPV )
	
Next

_cFileNome:="\DATA\ITALAC\CONTROLE\AOMS116_"+cFilAnt+"_"+AllTrim(_aItensPV[1,3,2])+".LOG"
MemoWrite(_cFileNome,_cLogCpos)
   
lMsErroAuto:=.F.
//====================================================================================================
// Geração do pedido de Carregamento NOVO
//====================================================================================================
If Empty(_cMensagem)

   _cAOMS074   :="AOMS116"//DesAtiva o _lMsgEmTela := .F. no MT410TOK.PRW
   _cAOMS074Vld:=""//Pega as mensagens de erro
   If _lSchedule
      MSExecAuto( {|x,y,z| Mata410(x,y,z) } , _aCabPV , _aItensPV , 3 )
   Else
      FWMsgRun(, { || MSExecAuto( {|x,y,z| Mata410(x,y,z) } , _aCabPV , _aItensPV , 3 ) },"Aguarde...","Criando PEDIDO...")
   EndIf  

Else

   Break

EndIf   

If lMsErroAuto 
	
	If (__lSx8 )
	   RollBackSx8()
	EndIf
	
	If Empty(_cMensagem)
	   _cMensagem:=_cAOMS074Vld+" ["+MostraErro( GETTEMPPATH() )+"] "
	EndIf
	
Else
	
	cPV:=SC5->C5_NUM
	
EndIf

If Empty(_cMensagem)
   _cMensagem:=_cAOMS074Vld
EndIf

End Sequence

SM0->(DBGoTo(nRecSM0))
cFilAnt:=_cSalveFil

Return {cPV,_cMensagem,_aItensPV}


/*
===============================================================================================================================
Programa--------: Ver_Lib_AM
Autor-----------: Alex Wallauer
Data da Criacao-: 30/01/2020
Descrição-------: Verefica se no SC9 esta tudo OK ou tenta liberar o Pedido
Parametros------: oProc
Retorno---------: (.T.) ou (.F.)
===============================================================================================================================
*/
Static Function Ver_Est_AM(oProc,lEfetiva)

Local _cQuery:=""
Local _cAlias:= GetNextAlias()
Local nPos:=0
Local _aResulAux:={}

Z20->(DBSeek(Z19->Z19_FILIAL+Z19->Z19_REGRA))
cFil:=Z20->Z20_FILIAL

If Empty(_aLinhas)

   _cProdutos:=""
	
	While Z20->( !Eof() ) .And. Z20->Z20_FILIAL+Z20->Z20_REGRA == Z19->Z19_FILIAL+Z19->Z19_REGRA
		
		If oProc <> nil
			oProc:cCaption := "Lendo Regra do Produto: "+Z20->Z20_COD
			ProcessMessages()
		EndIf
		
		If Z20->Z20_MSBLQL = "1" 
			Z20->(DBSkip())
			Loop
		EndIf
		
		_cProdutos+=Z20->Z20_COD +";"
		
		_aResulAux:={}
		aAdd(_aResulAux, .F. )                //01
		aAdd(_aResulAux, .F. )                //02
		aAdd(_aResulAux,Z20->Z20_COD)         //03
		aAdd(_aResulAux,Posicione("SB1",1,xFilial("SB1")+Z20->Z20_COD,"B1_DESC"))//04
		aAdd(_aResulAux,SB1->B1_UM+" / "+SB1->B1_SEGUM)//05
		aAdd(_aResulAux,Z20->Z20_ESTIDE)      //06,"Est.Ideal 2 UM"
		aAdd(_aResulAux,Z20->Z20_MINREP)      //07,"Ped.Minimo"
		aAdd(_aResulAux,0)                    //08,"Qtde.Repor 2 RM "
		aAdd(_aResulAux,0)                    //09,"Atual 70 2 UM"
		aAdd(_aResulAux,0)                    //10,"Atual 72 2 UM"
		aAdd(_aResulAux,0)                    //11,"Arm 20 2 UM"
		aAdd(_aResulAux,0)                    //12,"Arm 22 2 UM"
		aAdd(_aResulAux,0)                    //13,"Acerto 70 1 UM"
		aAdd(_aResulAux,0)                    //14,"Acerto 70 2 UM"
		aAdd(_aResulAux,"")                   //15,"Acerto 70 3 UM"
		aAdd(_aResulAux,0)                    //16,"Acerto 72 1 UM"
		aAdd(_aResulAux,0)                    //17,"Acerto 72 2 UM"
		aAdd(_aResulAux,"")                   //18,"Acerto 72 3 UM"
		aAdd(_aResulAux,If(Z20->Z20_MSBLQL="2","2-Repoe","3-Lista"))//19,ACAO
		aAdd(_aResulAux,"")                   //20,"Observação"
		
		aAdd(_aLinhas,_aResulAux)
		
		Z20->( DBSkip() )
		
	EndDo
	
	If Empty(_aLinhas)
		aAdd(_aResulAux,.F.)//01
		aAdd(_aResulAux,.F.)//02
		aAdd(_aResulAux,"" )//03
		aAdd(_aResulAux,"" )//04
		aAdd(_aResulAux,"" )//05
		aAdd(_aResulAux,0)  //06,"Est.Ideal"
		aAdd(_aResulAux,0)  //07,"Ped.Minimo"
		aAdd(_aResulAux,0)  //08,"Qtde.Repor"
		aAdd(_aResulAux,0)  //09,"Atual 70"
		aAdd(_aResulAux,0)  //10,"Atual 72"å
		aAdd(_aResulAux,0)  //11,"Arm 20 2 UM"
		aAdd(_aResulAux,0)  //12,"Arm 22 2 UM"
		aAdd(_aResulAux,0)  //13,"Acerto 70 1 UM"
		aAdd(_aResulAux,0)  //14,"Acerto 70 2 UM"
		aAdd(_aResulAux,0)  //15,"Acerto 70 3 UM"
		aAdd(_aResulAux,0)  //16,"Acerto 72 1 UM"
		aAdd(_aResulAux,0)  //17,"Acerto 72 2 UM"
		aAdd(_aResulAux,0)  //18,"Acerto 72 3 UM"
		aAdd(_aResulAux,"") //19,ACAO
		aAdd(_aResulAux,"SEM REGRAS HABILITADAS PARA EXECUTAR")//20,"Observação"
		aAdd(_aLinhas,_aResulAux)
		Return .F. /// ******************** RETORNA *******************************
	EndIf

    _cProdutos:=LEFT(_cProdutos,Len(_cProdutos)-1)

EndIf

_cQuery += " SELECT DISTINCT B2_COD,"
_cQuery += "        NVL ((SELECT (B2_QATU - (B2_QEMP + B2_RESERVA + B2_QACLASS))"
_cQuery += "             FROM " + RetSqlName("SB2")+ " SB270"
_cQuery += "            WHERE     SB270.B2_FILIAL = SB2.B2_FILIAL"
_cQuery += "                  AND SB270.B2_COD = SB2.B2_COD"
_cQuery += "                  AND SB270.B2_LOCAL = '70' "
_cQuery += "                  AND SB270.D_E_L_E_T_ = ' '),0)  SALDO70,"
_cQuery += "       NVL ((SELECT (B2_QATU - (B2_QEMP + B2_RESERVA + B2_QACLASS))"
_cQuery += "             FROM " + RetSqlName("SB2")+ " SB272"
_cQuery += "            WHERE     SB272.B2_FILIAL = SB2.B2_FILIAL"
_cQuery += "                  AND SB272.B2_COD = SB2.B2_COD"
_cQuery += "                  AND SB272.B2_LOCAL = '72' "
_cQuery += "                  AND SB272.D_E_L_E_T_ = ' '),0)  SALDO72, "
_cQuery += "        NVL ((SELECT (B2_QATU - (B2_QEMP + B2_RESERVA + B2_QACLASS))"
_cQuery += "             FROM " + RetSqlName("SB2")+ " SB220"
_cQuery += "            WHERE     SB220.B2_FILIAL = SB2.B2_FILIAL"
_cQuery += "                  AND SB220.B2_COD = SB2.B2_COD"
_cQuery += "                  AND SB220.B2_LOCAL = '20' "
_cQuery += "                  AND SB220.D_E_L_E_T_ = ' '),0)  SALDO20,"
_cQuery += "       NVL ((SELECT (B2_QATU - (B2_QEMP + B2_RESERVA + B2_QACLASS))"
_cQuery += "             FROM " + RetSqlName("SB2")+ " SB222"
_cQuery += "            WHERE     SB222.B2_FILIAL = SB2.B2_FILIAL"
_cQuery += "                  AND SB222.B2_COD = SB2.B2_COD"
_cQuery += "                  AND SB222.B2_LOCAL = '22' "
_cQuery += "                  AND SB222.D_E_L_E_T_ = ' '),0)  SALDO22 "
_cQuery += "  FROM " + RetSqlName("SB2")+ " SB2 "
_cQuery += " WHERE     B2_FILIAL = '"+cFil+"' "
_cQuery += "       AND B2_COD IN "+FormatIn(_cProdutos,";")
_cQuery += "       AND B2_LOCAL IN ('70', '72','20', '22') "
_cQuery += "       AND SB2.D_E_L_E_T_ = ' ' "
_cQuery += "       ORDER BY B2_COD "

_cQuery := ChangeQuery(_cQuery)
MPSysOpenQuery(_cQuery,_cAlias)
DBSelectArea(_cAlias)
If oProc <> nil
   oProc:cCaption := "Calculando reposicao"
   ProcessMessages()
   COUNT To _nConta
   _cTot  :=AllTrim(Str(_nConta))
   _nTam  :=Len(_cTot)
   _nConta:=0
EndIf

DBSelectArea(_cAlias)
DBGoTop()
While (_cAlias)->(!Eof())

    If oProc <> nil
       _nConta++
	   oProc:cCaption := ("Calculando reposicao Prod: "+AllTrim((_cAlias)->B2_COD)+" / "+AllTrim(StrZero(_nConta,_nTam)) +" de "+ _cTot)
	   ProcessMessages()
    EndIf

	If (nPos:=aScan(_aLinhas, {|P| AllTrim(P[3]) == AllTrim((_cAlias)->B2_COD) } )) <> 0

       If lEfetiva .And. (!_aLinhas[nPos,1] .Or. !_aLinhas[nPos,2])//SE O USUARIO MARCOU PARA GERAR E SE É E VERDE
          _aLinhas[nPos,1]:=.F.//LEGENDA VERMELHO
          (_cAlias)->(DBSkip())
          Loop
       EndIf	
		
		nSaldo70:=ConvUM(_aLinhas[nPos,3],(_cAlias)->SALDO70,0,.F.)//2 UM
		nSaldo72:=ConvUM(_aLinhas[nPos,3],(_cAlias)->SALDO72,0,.F.)//2 UM
		nSaldo20:=ConvUM(_aLinhas[nPos,3],(_cAlias)->SALDO20,0,.F.)//2 UM
		nSaldo22:=ConvUM(_aLinhas[nPos,3],(_cAlias)->SALDO22,0,.F.)//2 UM
		
		_n2EstDisp:=(nSaldo70+nSaldo72)//2 UM
		
		_nQtdeRepor:=nFator:=0
		_nEstIdeal :=_aLinhas[nPos,6]//Z20->Z20_ESTIDE//07,"Est.Ideal"
		_nPedMinimo:=_aLinhas[nPos,7]//Z20->Z20_MINREP//08,"Ped.Minimo"

		If _nEstIdeal > _n2EstDisp
			
		   _nQtdeRepor:=(_nEstIdeal-_n2EstDisp)//2 UM
			nFator:=_nQtdeRepor/_nPedMinimo
			If nFator > INT(nFator)
			   nFator:=INT(nFator)+1
			EndIf
			_nQtdeRepor:=(nFator*_nPedMinimo)//"Qtde.Repor" inteiro// 2 um
			
		EndIf

		_aLinhas[nPos,08]:=_nQtdeRepor //08,"Qtde.Repor" 
		_aLinhas[nPos,09]:=nSaldo70    //09,"Arm 70 2 UM"
		_aLinhas[nPos,10]:=nSaldo72    //10,"Arm 72 2 UM"
		_aLinhas[nPos,11]:=nSaldo20    //11,"Arm 20 2 UM"
		_aLinhas[nPos,12]:=nSaldo22    //12,"Arm 22 2 UM"

		nAcerto70:=0
		nAcerto72:=0
		_aLinhas[nPos,Len(_aLinhas[nPos])]:=""//LIMPA PARA NAO ACUMULAR NA EFETIVACAO

        If nSaldo20 > 0.And. _nQtdeRepor > 0
           If nSaldo20 > _nQtdeRepor
              nAcerto70:=_nQtdeRepor
              _nQtdeRepor:=0
           Else
              nAcerto70:=nSaldo20
              _nQtdeRepor:=(_nQtdeRepor-nSaldo20)
           EndIf
	       _aLinhas[nPos,Len(_aLinhas[nPos])]:="[ Pegou do 20 ]"
        EndIf
        
        If nSaldo22 > 0 .And. _nQtdeRepor > 0
           If nSaldo22 > _nQtdeRepor
              nAcerto72:=_nQtdeRepor
           Else
              nAcerto72:=nSaldo22
           EndIf
	       _aLinhas[nPos,Len(_aLinhas[nPos])]+="[ Pegou do 22 ]"
        EndIf
        
		_n3Qtde:=0//Pega o valor dentro da ConvUM() se For usado
		_aLinhas[nPos,13]:=ConvUM(_aLinhas[nPos,3],0,@nAcerto70)    //"Acerto 70"--> 1UM
		_aLinhas[nPos,14]:=nAcerto70                                //"Acerto 70"--> 2UM
        If _n3Qtde <> 0
		   _aLinhas[nPos,15]:=CVALTOCHAR(_n3Qtde)+" "+SB1->B1_I_3UM //"Acerto 70"--> 3UM
		EndIf  

		_n3Qtde:=0//Pega o valor dentro da ConvUM() se For usado
		_aLinhas[nPos,16]:=ConvUM(_aLinhas[nPos,3],0,@nAcerto72)    //"Acerto 72"--> 1UM
		_aLinhas[nPos,17]:=nAcerto72                                //"Acerto 72"--> 2UM
        If _n3Qtde <> 0
		   _aLinhas[nPos,18]:=CVALTOCHAR(_n3Qtde)+" "+SB1->B1_I_3UM //"Acerto 72"--> 3UM
		EndIf  

        If lEfetiva
           cRet:=""
           If nAcerto70 > 0 
              cRet:=AOMS116Trans(_aLinhas[nPos,3],"20","70",_aLinhas[nPos,13],nAcerto70)//70
           EndIf

           If nAcerto72 > 0 
              cRet+=AOMS116Trans(_aLinhas[nPos,3],"22","72",_aLinhas[nPos,16],nAcerto72)//72
           EndIf

           If nAcerto70+nAcerto72 = 0            
              cRet:="Sem saldos para repor"
           EndIf   

           _aLinhas[nPos,Len(_aLinhas[nPos])]:=cRet

           If "sucesso" $ cRet
              _aLinhas[nPos,1]:=.T.//LEGENDA VERDE
           Else
              _aLinhas[nPos,1]:=.F.//LEGENDA VERMELHO
           EndIf

        ElseIf nAcerto70+nAcerto72 > 0

           _aLinhas[nPos,1]:=.T.//MARCA LINHA
           _aLinhas[nPos,2]:=.T.//LEGENDA VERDE
           If LEFT(_aLinhas[nPos,19],1) = "3"//SÓ LISTA
              _aLinhas[nPos,1]:=.F.//MARCA LINHA
              _aLinhas[nPos,2]:=.F.//LEGENDA VERMELHA
		   EndIf

        ElseIf nAcerto70+nAcerto72 = 0

		   _aLinhas[nPos,Len(_aLinhas[nPos])]:=""//LIMPA PQ PODE SER QUE O SALDO DOS ARMAGENS NÃO SEJA O SUFUCIENTE

        EndIf
		
	EndIf
	(_cAlias)->(DBSkip())
EndDo

(_cAlias)->(DBCloseArea())

If lEfetiva

	If Len(_aLinhas) > 0
	
	   _aCab[2]:="Filial"//A LEGENDA VIRA A FILIAL E O MARCA VIRA LEGENDA
	   _aColXML:={}
       For nPos:= 1 To Len(_aLinhas)
           _aLinhas[nPos,2]:=cFil//A LEGENDA VIRA A FILIAL E O MARCA VIRA LEGENDA
           aAdd(_aColXML,aClone(_aLinhas[nPos]))
           _aColXML[nPos,1]:=If(_aColXML[nPos,1],"ALTERADO","")
       Next
       _cTitAux:="TRANSFERENCIA DE ARMAZENS"
	   nPosResu:=Len(_aLinhas[1])
	   aBotoes:={}
	   aAdd( aBotoes , { "" , {|| AVISO("ATENCAO",oLbxAux:aArray[oLbxAux:nAt][ nPosResu ],{"Fechar"},3) }	, "" , "Ver Resultado"		  } )
		
	//         ITListBox(_cTitAux , _aHeader , _aCols    , _lMaxSiz , _nTipo , _cMsgTop , _lSelUnc , _aSizes , _nCampo , bOk , bCancel, _abuttons, _aCab ,bDblClk , _aColXML , bCondMarca)
	   lRet:=U_ITLISTBOX(_cTitAux , _aCab    , _aLinhas  , .T.      , 4      , _cMsgTop ,          , _aSize  ,         ,     ,        , aBotoes  ,       ,        , _aColXML )

    EndIf

EndIf

Return .T.

/*
===============================================================================================================================
Programa--------: ConvUM()
Autor-----------: Alex Wallauer
Data da Criacao-: 04/02/2020
Descrição-------: Devolve a 2UM
Parametros------: cProd,_nQtde,_n2Qtde,lInteira
Retorno---------: _n2Qtde
===============================================================================================================================
*/
Static Function ConvUM(cProd,_nQtde,_n2Qtde,lInteira)

Local nFator := 0
Local nNewFat:= 0
Local _cCrtl3Um := "N"

Default lInteira := .T.

SB1->(DBSeek(xFilial("SB1")+AllTrim(cProd)))
nFator := SB1->B1_CONV
nNewFat:= SB1->B1_I_FATCO
nFator := (If(nFator = 0, nNewFat, nFator))
	
If _n2Qtde = 0 .And. _nQtde <> 0//DEVOLVE A SEGNDA UNIDADE    **************************************
	
   _cCrtl3Um := Posicione("SBZ",1,xFilial("SBZ")+cProd,"BZ_I_PR3UM")
      
	If lInteira .And. _cCrtl3Um == "S" //(AllTrim(cProd) $ _cPrd3Um)
		
		_n3Qtde:=(_nQtde / SB1->B1_I_QT3UM)//CALCULA A 3UM
		
		If _n3Qtde <> Int(_n3Qtde)
			
			_n3Qtde:=Int(_n3Qtde)//PEGA SÓ O INTEIRO DA 3UM
			
			_nQtde:=(_n3Qtde*SB1->B1_I_QT3UM)//RECACULA A 1UM COM A 3UM INTEIRA
			
		EndIf
		
	EndIf
	
	If SB1->B1_TIPCONV = 'D'
		_n2Qtde:=(_nQtde/nFator)//CALCULA A 2UM
	Else
		_n2Qtde:=(_nQtde*nFator)//CALCULA A 2UM
	EndIf
	
	Return _n2Qtde
	
ElseIf _nQtde = 0 .And. _n2Qtde <> 0//DEVOLVE A PRIMEIRA UNIDADE    **************************************
	_cCrtl3Um := Posicione("SBZ",1,xFilial("SBZ")+cProd,"BZ_I_PR3UM")

	If _cCrtl3Um == "S" //(AllTrim(cProd) $ _cPrd3Um) //Calcula a 1um
		
	   If SB1->B1_TIPCONV = 'D'
		  _nQtde:=(_n2Qtde*nFator)//CACULA A 1UM COM A 2UM INTEIRA
	   	  nFatorUM:=SB1->B1_I_QT3UM / nFator
	   Else
	   	  _nQtde:=(_n2Qtde/nFator)//CACULA A 1UM COM A 2UM INTEIRA
	   	  nFatorUM:=SB1->B1_I_QT3UM * nFator
	   EndIf

	   _n3Qtde:=(_nQtde / SB1->B1_I_QT3UM)//CALCULA A 3UM

	   If !lInteira 
	      Return _nQtde
	   EndIf
	
	   If _n3Qtde <> Int(_n3Qtde)
		  _n3Qtde:=Int(_n3Qtde)//PEGA SÓ O INTEIRO DA 3UM			
	   EndIf

	   _nQtde:=(_n3Qtde*SB1->B1_I_QT3UM)//**RECACULA** A 1UM COM A 3UM INTEIRA

	   If SB1->B1_TIPCONV = 'D'
	      _n2Qtde:=(_nQtde/nFator)//RECALCULA A 2UM
	   Else
	      _n2Qtde:=(_nQtde*nFator)//RECALCULA A 2UM
	   EndIf
		
	Else
		
		If lInteira .And. _n2Qtde <> Int(_n2Qtde)
		   _n2Qtde:=Int(_n2Qtde)
		EndIf

		If SB1->B1_TIPCONV = 'D'
			_nQtde:=(_n2Qtde*nFator)//CACULA A 1UM COM A 2UM INTEIRA
		Else
			_nQtde:=(_n2Qtde/nFator)//CACULA A 1UM COM A 2UM INTEIRA
		EndIf
		
	EndIf
	
	Return _nQtde
	
EndIf

Return 0

/*
===============================================================================================================================
Programa--------: AOMS116Trans()
Autor-----------: Alex Wallauer
Data da Criacao-: 30/01/2020
Descrição-------: Verefica se no SC9 esta tudo OK ou tenta liberar o Pedido
Parametros------: cProduto,cArmOri,cArmDest,nQtde,n2UMQtde
Retorno---------: (.T.) ou (.F.)
===============================================================================================================================
*/
Static Function AOMS116Trans(cProduto,cArmOri,cArmDest,nQtde,n2UMQtde)

Local _cFilVld34:= SuperGetMV('IT_FILVLD3',.F.,'')

//****** Cabecalho a Incluir ***
cDoc:=GetSxENum("SD3","D3_DOC",1)
aAuto:={}
aAdd(aAuto,{cDoc,dDataBase})  //Cabecalho

//****** Cabecalho a Incluir ***

//****** Itens a Incluir  ******
SB1->(DBSetOrder(1))
SB1->(DBSeek(xFilial()+cProduto)) 
aItem:={}
// ORIGEM
aAdd(aItem,cProduto)    //D3_COD
aAdd(aItem,SB1->B1_DESC)//D3_DESCRI
aAdd(aItem,SB1->B1_UM)  //D3_UM
aAdd(aItem,cArmOri)     //D3_LOCAL
aAdd(aItem,"")		    //D3_LOCALIZ //Endereço Orig
// DESTINO
aAdd(aItem,cProduto)    //D3_COD
aAdd(aItem,SB1->B1_DESC)//D3_DESCRI
aAdd(aItem,SB1->B1_UM)  //D3_UM
aAdd(aItem,cArmDest)    //D3_LOCAL
aAdd(aItem,"")		    //D3_LOCALIZ //Endereço Dest
aAdd(aItem,"")          //D3_NUMSERI
aAdd(aItem,"")  	    //D3_LOTECTL
aAdd(aItem,"")         	//D3_NUMLOTE
aAdd(aItem,CTOD(""))	//D3_DTVALID
aAdd(aItem,0)		    //D3_POTENCI
aAdd(aItem,nQtde)       //D3_QUANT
aAdd(aItem,n2UMQtde)	//D3_QTSEGUM
aAdd(aItem,"")          //D3_ESTORNO
aAdd(aItem,"")      	//D3_NUMSEQ
aAdd(aItem,"")  	    //D3_LOTECTL
aAdd(aItem,CTOD(""))	//D3_DTVALID
aAdd(aItem,"")	 	    //D3_ITEMGRD
aAdd(aItem,"")	 	    //D3_OBSERVA  //Observação C        30
//Campos Customizados:
aAdd(aItem,"")	 	    //D3_I_OBS    // Observação C       254 		
  If ! cFilant $ _cFilVld34 // Este campo não deve estar disponível para filiais de validação do armazém 34 (Descarte).
   aAdd(aItem,"")	 	              //D3_I_TPTRS  // Mot.Tran.R C  1
   aAdd(aItem,"")	 	              //D3_I_DSCTM  // Des.Mot.Tr C  1
  EndIf 
  If cFilant $ _cFilVld34 // Este campo não deve estar disponível para filiais de validação do armazém 34 (Descarte).
   aAdd(aItem,"")	 	          //D3_I_MOTTR  // Mot.Tran.R C         8 
   aAdd(aItem,"")	 	          //D3_I_DSCMT  // Des.Mot.Tr C        40 
   aAdd(aItem,"")	 	          //D3_I_SETOR  // Origem Trf C        40 
   aAdd(aItem,"")	 	          //D3_I_DESTI  // Destino    C        40 
EndIf 
//****** Itens a Incluir  ******

aAdd(aAuto,aItem)

lMsErroAuto := .F.

MSExecAuto({|x,y| MATA261(x,y)},aAuto,3)

If lMsErroAuto   //Para recepção automatica esta dentro de transacao
	If __lSx8
		RollBackSX8()
	EndIf
   _cMensagem:="Erro ao transferir da "+cArmOri+" p/ "+cArmDest
   _cMensagem+=" [ "+AllTrim(MostraErro(GETTEMPPATH()))+" ]"
Else
	ConfirmSX8()
	_cMensagem:="[ Transferido com sucesso da "+cArmOri+" p/ "+cArmDest+" ]"
EndIf

Return _cMensagem

/*
===============================================================================================================================
Programa--------: CADSB1()
Autor-----------: Alex Wallauer
Data da Criacao-: 06/02/2020
Descrição-------: VERSB1
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function CADSB1(oLbxAux)

Local _nLinPos  := oLbxAux:nAt
Local _aArea:= FWGetArea()
Private cCadastro:= OemToAnsi( "Visualizar" )

DBSelectArea("SB1")
SB1->(DBSetOrder(1))

If SB1->(DBSeek(  xFilial("SB1") + _aLinhas[_nLinPos,_nPosColProd] ))
   AxVisual( "SB1", SB1->( Recno() ), 2 )
EndIf

FWRestArea( _aArea )        

Return

/*
===============================================================================================================================
Programa--------: AOMS13PT()
Autor-----------: Alex Wallauer
Data da Criacao-: 28/04/2021
Descrição-------: LISTA DOS PEDIDOS DE TRANSFERICIA 
Parametros------: _aPts
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function AOMS13PT(_aPts)

Local _aSize:={"15","40","10","10","10","15"}
Local _cMsgTop:=NIL
Local _cTitAux:="PEDIDOS DE TRANSFERNCIA DOS PRODUTOS"

	//         ITListBox(_cTitAux, _aHeader , _aCols , _lMaxSiz ,  nTipo , _cMsgTop , _lSelUnc , _aSizes , _nCampo , bOk , bCancel, _abuttons, _aCab ,bDblClk , _aColXML , bCondMarca)
	   lRet:=U_ITLISTBOX(_cTitAux, _aCabPT  , _aPts  , .F.      , 1      , _cMsgTop ,          , _aSize  ,         ,     ,        ,          ,       ,        ,          ,           )

Return .T.
/*
===============================================================================================================================
Programa--------: AOMS13PT()
Autor-----------: Alex Wallauer
Data da Criacao-: 29/04/2021
Descrição-------: DEVOLVE AS CORES PARA A LEGENDA
Parametros------: _aCol,_nLinha
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function AOMS13Leg(_aCol,_nLinha)

Local oGeraCri := LoadBitmap( , "BR_VERMELHO")// VERMELHO TEM QUE GERA REPOSICAO .F. CRITICO
Local oGerar   := LoadBitmap( , "BR_AZUL"    )// AZUL TEM QUE GERA REPOSICAO .F. MAS TEM AINDA
Local oGerado  := LoadBitmap( , "BR_AMARELO" )// AMARELO ESTOQUE TUDO OK .T. SQN
Local oNaoGera := LoadBitmap( , "BR_VERDE"   )// VERDE ESTOQUE TUDO OK .T.

Local o3GeraCri:= LoadBitmap( , "PMSTASK1"   )// VERMELHO TEM QUE GERA REPOSICAO .F. CRITICO (SO MOSTRA)
Local o3Gerar  := LoadBitmap( , "PMSTASK6"   )// AZUL TEM QUE GERA REPOSICAO .F. MAS TEM AINDA (SO MOSTRA)
Local o3Gerado := LoadBitmap( , "PMSTASK2"   )// AMARELO ESTOQUE TUDO OK .T. SQN (SO MOSTRA)
Local o3NaoGera:= LoadBitmap( , "PMSTASK4"   )// VERDE ESTOQUE TUDO OK .T. (SO MOSTRA)

Local oBloquead:= LoadBitmap( GetResources() , "BR_PRETO"   )// BLOQUEADO INDEPENDENTE DE .T. OU .F.
Local _nCol    := _nPosColAcao

Local _nEstoque :=StrTran(_aLinhas[_nLinha,_nPosColEst],"." , "") //Tira o ponto dos milhar
Local _nCarteir :=StrTran(_aLinhas[_nLinha,_nPosColCar],"." , "") //Tira o ponto dos milhar
_nEstoque :=Val(StrTran(_nEstoque,"," , ".") )//Tira a virgula e poe o ponto para o Val não comer a decimal
_nCarteir :=Val(StrTran(_nCarteir,"," , ".") )//Tira a virgula e poe o ponto para o Val não comer a decimal

If _aCol[_nLinha,_nCol] = "1"//BLOQUEADO NAO GERA E TEORICAMENTE NÃO TEM LINHA DELE PQ JÁ IGNORA NA SELECT
   Return oBloquead //BLOQUEADO INDEPENDENTE DE .T. OU .F.

ElseIf _aCol[_nLinha,_nCol] <> "3" //"2" E BRANCO E QQ OUTRA COISA
   If _aCol[_nLinha,1] // SE .T. ****************  NAO GERA *********************
      If _nEstoque < _nCarteir//ESTOQUE < CARTEIRA
         Return oGerado  // AMARELO TUDO OK .T. SQN
	  Else//estoque > carteira
         Return oNaoGera // VERDE TUDO OK .T.
	  EndIf
   Else//SE .F.  **************** GERA ****************
      If _nEstoque < _nCarteir//ESTOQUE < CARTEIRA
         Return oGeraCri// VERMELHO TEM QUE GERA REPOSICAO .F. CRITICO
	  Else//ESTOQUE > CARTEIRA
         Return oGerar  // AZUL TEM QUE GERA REPOSICAO .F. MAS TEM AINDA
	  EndIf
   EndIf

ElseIf _aCol[_nLinha,_nCol] = "3"//SO MOSTRA  MAS NÃO GERA SE TIVER
   If _aCol[_nLinha,1] //SE .T. **************** NAO GERA ****************
      If _nEstoque < _nCarteir//ESTOQUE < CARTEIRA
         Return o3Gerado //AMARELO TUDO OK .T. SQN
	  Else//ESTOQUE > CARTEIRA
         Return o3NaoGera //VERDE TUDO OK .T.
	  EndIf
   Else//SE .F. **************** GERA ***************
      If _nEstoque < _nCarteir//ESTOQUE < CARTEIRA
         Return o3GeraCri// VERMELHO TEM QUE GERA REPOSICAO .F. CRITICO
	  Else//ESTOQUE > CARTEIRA
         Return o3Gerar  // AZUL TEM QUE GERA REPOSICAO .F. MAS TEM AINDA (SO MOSTRA)
	  EndIf
   EndIf
EndIf

Return oBloquead

/*
===============================================================================================================================
Programa----------: SchedDef
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 25/05/2017
Descrição---------: DefiniçStaticStatic Function SchedDef para o novo Schedule
					No novo Schedule existe uma forma para a definição dos Perguntes para o botão Parâmetros, além do cadastro 
					das funções no SXD. Ao definir em sua rotinStaticatic Function SchedDef(), no cadastro da rotina no Agenda-
					mento do Schedule será verificado se existe estStaticic Function e irá executá-la habilitando o botão Parâ-
					metros com as informações do retorno da SchedDef(), deixando de verificar assim as informações na SXD. O 
					retorno da SchedDef deverá ser um array.
					Válido para Function e User Function, lembrando que uma vez definido a SchedDef, ao chamar a rotina o ambi-
					ente já está inicializado.
					Uma vez definido a Static Function SchedDef(), a rotina deixa de ser uma execução como processo especial, 
					ou seja, não se deve cadastrá-la no Agendamento passando parâmetros de linha. Ex: Funcao("A","B") ou 
					U_Funcao("A","B").
Parametros--------: aReturn[1] - Tipo: "P" - para Processo, "R" -  para Relatórios
					aReturn[2] - Nome do Pergunte, caso nao use passar PARAMDEF
					aReturn[3] - Alias  (para Relatório)
					aReturn[4] - Array de ordem  (para Relatório)
					aReturn[5] - Título (para Relatório)
Retorno-----------: aParam
===============================================================================================================================
*/
Static Function SchedDef()

Local aParam  := {}
Local aOrd := {}

aParam := { "P",;
            "PARAMDEFF",;
            "",;
            aOrd,;
            }

Return aParam
