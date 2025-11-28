/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |20/03/2023| Chamado 42203. Ajustes no Cadastro de Gerente Filiais de Troca NF X Itens.
Igor Melgaço  |27/09/2024| Chamado 48088. Ajustes para validações de registros na inclusão e alteração.
Lucas Borges  |17/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
===============================================================================================================================
*/

#Include "TOTVS.ch"
/*
===============================================================================================================================
Programa----------: AOMS134
Autor-------------: Alex Wallauer
Data da Criacao---: 02/01/2023
Descrição---------: Rotina de manutenção do cadastro de Gerente X Filiais de Troca NF X Itens. Chamado 42203.
Parametros--------: Nenhum
Retorno-----------: Nenhum 
===============================================================================================================================
*/  
User Function AOMS134

Local aSM0 := FwLoadSM0() , nFilial
Private _cTitulo := "Cadastro de Gerente X Filiais de Troca NF X Itens."

_aDadosF := {}
_aDadosC := {}

 _cFilSalva:= cFilAnt
For nFilial := 1 To Len(aSM0)
   cFilAnt  := LEFT(aSM0[nFilial][SM0_CODFIL],2)
   If AllTrim(SuperGetMV("IT_PRONF",.T.,"N")) == "S" 
  	   aAdd(_aDadosC, cFilAnt+"-"+aSM0[nFilial][SM0_NOMRED] )
   EndIf
   If AllTrim(SuperGetMV("IT_FATNF",.F.,"N")) == "S" 
  	   aAdd(_aDadosF, cFilAnt+"-"+aSM0[nFilial][SM0_NOMRED] )
   EndIf	
Next 
cFilAnt := _cFilSalva

_aItalac_F3:={}//       1            2         3            4        5        6                         7         8          9             10        11        12
//AD(_aItalac_F3,{"1CPO_CAMPO1   ,_cTabel,_nCpoChave, _nCpoDesc,_bCondTab, _cTitAux                , _nTamChv, _aDados , _nMaxSel    , _lFilAtual,_cMVRET,_bValida})
aAdd(_aItalac_F3,{"M->ZPE_FILCAR",       ,          ,          ,         ,"Filiais de Carregamento",2        ,_aDadosC ,Len(_aDadosC)  })
aAdd(_aItalac_F3,{"M->ZPE_FILFAT",       ,          ,          ,         ,"Filiais de Faturamento" ,2        ,_aDadosF ,Len(_aDadosF)  })
aAdd(_aItalac_F3,{"M->ZPE_OPERAC","ZB4"  ,          ,          ,         ,"Tipo de Operacao"       ,2} )

DBSelectArea( "ZPE" )
Private cCadastro	:= _cTitulo
Private aRotina	:= MenuDef()
mBrowse(,,,,"ZPE" ,,,,,, U_AOMS134L() ) 

Return       

/*
===============================================================================================================================
Programa----------: AOMS134L
Autor-------------: Alex Wallauer
Data da Criacao---: 02/01/2023
Descrição---------: Definição da legenda da tela principal - Bloqueio de Regras
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS134L( nReg )

Local uRetorno	:= .T.
Local aLegenda  := 	{ 	{ "BR_VERDE"  	, "Desbloqueio"	} ,;
                        { "BR_VERMELHO"	, "Bloqueio"	}  }

//===========================================================================
// Chamada direta da funcao, via menu Recno eh passado
//===========================================================================
If	nReg == Nil

	uRetorno := {}
	
	aAdd( uRetorno , { 'ZPE->ZPE_MSBLQL <> "1" '	, aLegenda[1][1] } )//BR_VERDE
	aAdd( uRetorno , { 'ZPE->ZPE_MSBLQL == "1" '	, aLegenda[2][1] } )//BR_VERMELHO

Else
	BrwLegenda(cCadastro, "Legenda",aLegenda)
EndIf

Return( uRetorno )

/*
===============================================================================================================================
Programa----------: AOMS134V
Autor-------------: Alex Wallauer
Data da Criacao---: 02/01/2023
Descrição---------: Validacao dos campos dos cadastros DO ZPE (AOMS134) , ZPF (AOMS135)  E ZPG (AOMS136)
Parametros--------: _cCampo := Nome do campo ou botao
Retorno-----------: .T. ou .F.
===============================================================================================================================
*/  
User Function AOMS134V(_cCampo)

Local _lRet := .T.   , F
Default _cCampo:=SubStr(ReadVar(),4)

Begin Sequence


///////////////////    ZPE  //////////////////////////////////  Cadastro de Gerente x Coordenador x Vendedor x Filiais de Troca NF.
   If _cCampo == "ZPE_GERCOD" 
      
      If !Empty(M->ZPE_GERCOD) .And. (_lRet:=ExistCpo("SA3",M->ZPE_GERCOD))
         If SA3->(DBSeek(xFilial("SA3")+M->ZPE_GERCOD)) .And. SA3->A3_I_TIPV <> 'G'
            U_ITMsg("Esse codigo não e de Gerente.",'Atencao!',;
		   	        "Digite um codigo cujo tipo é G ",1)         
            _lRet := .F.
         EndIf
      EndIf

   ElseIf _cCampo == "ZPE_ADQUIR" 

      If !Empty(M->ZPE_ADQUIR) 
         _lRet:=ExistCpo("SA1",M->ZPE_ADQUIR)
      Else
         M->ZPE_ADQLOJ:=Space(Len(ZPE->ZPE_ADQUIR))
         M->ZPE_ADQDES:=Space(Len(SA1->A1_NREDUZ))
      EndIf

   ElseIf _cCampo == "ZPE_ADQLOJ" 

      If !Empty(M->ZPE_ADQUIR) 
         _lRet:=ExistCpo("SA1",M->ZPE_ADQUIR+M->ZPE_ADQLOJ)
      EndIf

   ElseIf _cCampo == "OKZPE"

         If !Obrigatorio(aGets,aTela)
            Return .F.
         EndIf
         If Inclui
            DBSelectArea("ZPE")
            //ZPE_FILIAL+ZPE_GERCOD+ZPE_ESTADO+ZPE_OPERAC+ZPE_ADQUIR+ZPE_ADQLOJ+ZPE_FILCAR+ZPE_FILFAT => CHAVE UNICA
            _lRet :=ExistChav("ZPE",M->ZPE_FILIAL+M->ZPE_GERCOD+M->ZPE_ESTADO+M->ZPE_OPERAC+M->ZPE_ADQUIR+M->ZPE_ADQLOJ+M->ZPE_FILCAR+M->ZPE_FILFAT,3)
         EndIf

   ElseIf _cCampo == "ZPE_FILCAR" //FILIAL DE CARREGAMENTO

         _aFilial := StrTokArr(AllTrim(M->ZPE_FILCAR), ';')

         _cFilSalva:= cFilAnt
         For F := 1 To Len(_aFilial)
             cFilAnt   := _aFilial[F]
             If AllTrim(SuperGetMV("IT_PRONF",.T.,"N")) == "N" //Testa a Filial atual se pode ser troca nota
	             U_ITMsg("Filial: "+cFilAnt+" não é troca nota de carregamento. ",'Atencao!',;
			    		       "Verifique o Parametro: IT_PRONF",1)
                _lRet := .F.
             EndIf
         Next
         cFilAnt := _cFilSalva

   ElseIf _cCampo == "ZPE_FILFAT" 

         _aFilial := StrTokArr(AllTrim(M->ZPE_FILFAT), ';')

         _cFilSalva:= cFilAnt
         For F := 1 To Len(_aFilial)
             cFilAnt   := _aFilial[F]
             If AllTrim(SuperGetMV("IT_FATNF",.F.,"N")) == "N" //Testa a filial de Faturamento
	             U_ITMsg("Filial: "+cFilAnt+" não é troca nota de Faturamento. ",'Atencao!',;
					        "Verifique o Parametro: IT_FATNF",1)
                _lRet := .F.
             EndIf
         Next
         cFilAnt := _cFilSalva   
   
   //ZPG - Cadastro de Assistente x Gerente x Coord x Sup. x Vend.
   ElseIf _cCampo == "ZPG_ASSCOD" 

      ZZL->(DBSetOrder(1))
      If !Empty(M->ZPG_ASSCOD) .And. !ZZL->(DBSeek(xFilial("ZZL")+M->ZPG_ASSCOD))   
         U_ITMsg("Essa Filial + Matricula não esta cadastrada (ZZL).",'Atencao!',;
			        "Digite uma Filial + Matricula cadastrada (ZZL).",1)         
         _lRet := .F.
      EndIf

   ElseIf _cCampo == "ZPG_REDCOD" 

      ACY->(DBSetOrder(1))
      If !Empty(M->ZPG_REDCOD) .And. !ACY->(DBSeek(xFilial("ACY")+M->ZPG_REDCOD))   
         U_ITMsg("Esse codigo de Rede não esta cadastrado (ACY).",'Atencao!',;
			        "Digite um codigo de Rede cadastrado (ACY).",1)         
         _lRet := .F.
      EndIf

   ElseIf _cCampo == "ZPG_VENCOD" 

      If !Empty(M->ZPG_VENCOD) .And. (_lRet :=ExistCpo("SA3",M->ZPG_VENCOD))
         If SA3->(DBSeek(xFilial("SA3")+M->ZPG_VENCOD)) .And. SA3->A3_I_TIPV <> 'V'
            U_ITMsg("Esse codigo não e de Vendedor: "+M->ZPG_VENCOD,'Atencao!',;
		   	        'Digite um codigo cujo tipo é "V" ',1)         
            _lRet := .F.
         EndIf
      EndIf

   ElseIf _cCampo == "ZPG_SUPCOD"
      If !Empty(M->ZPG_SUPCOD) .And. (_lRet :=ExistCpo("SA3",M->ZPG_SUPCOD))
         If SA3->(DBSeek(xFilial("SA3")+M->ZPG_SUPCOD)) .And. SA3->A3_I_TIPV <> 'S'
            U_ITMsg("Esse codigo não e de Supervisor: "+M->ZPG_SUPCOD,'Atencao!',;
			           'Digite um codigo cujo tipo é "S" ',1)         
            _lRet := .F.
         EndIf
      EndIf

   ElseIf _cCampo == "ZPG_COOCOD"
      If !Empty(M->ZPG_COOCOD) .And. (_lRet :=ExistCpo("SA3",M->ZPG_COOCOD))
         If SA3->(DBSeek(xFilial("SA3")+M->ZPG_COOCOD)) .And. SA3->A3_I_TIPV <> 'C'
            U_ITMsg("Esse codigo não e de Coordenador: "+M->ZPG_COOCOD,'Atencao!',;
			           'Digite um codigo cujo tipo é "C" ',1)         
            _lRet := .F.
         EndIf
      EndIf

   ElseIf _cCampo == "ZPG_GERCOD" 
      
      If !Empty(M->ZPG_GERCOD) .And. (_lRet:=ExistCpo("SA3",M->ZPG_GERCOD)) 
         If SA3->(DBSeek(xFilial("SA3")+M->ZPG_GERCOD)) .And. SA3->A3_I_TIPV <> 'G'
            U_ITMsg("Esse codigo não e de Gerente: "+M->ZPG_GERCOD,'Atencao!',;
			           'Digite um codigo cujo tipo é "G" ',1)         
            _lRet := .F.
         EndIf
      EndIf

      If _lRet .And. Inclui //ZPG_FILIAL+ZPG_REDCOD+ZPG_VENCOD+ZPG_SUPCOD+ZPG_COOCOD+ZPG_GERCOD+ZPG_ASSCOD
         _lRet :=ExistChav("ZPG",M->ZPG_REDCOD+M->ZPG_VENCOD+M->ZPG_SUPCOD+M->ZPG_COOCOD+M->ZPG_GERCOD+M->ZPG_ASSCOD,7)
      EndIf

   EndIf
   
End Sequence

Return _lRet

/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Alex Wallauer
Data da Criacao---: 23/02/2023
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

Local aRotina:={{ "Pesquisar"	, "AxPesqui" 		, 0 , 1 } ,;//1
					 { "Visualizar", "U_AOM134Manut" , 0 , 2 } ,;//2
					 { "Incluir"	, "U_AOM134Manut" , 0 , 3 } ,;//3
					 { "Alterar"	, "U_AOM134Manut"	, 0 , 4 } ,;//4
					 { "Excluir"	, "U_AOM134Manut" , 0 , 5 } ,;//5
					 { "Copiar"		, "U_AOM134Manut" , 0 , 3 } ,;//6
                { "Legenda"	, "U_AOMS134L"    , 0 , 0 }  }//7
Return( aRotina )

/*
===============================================================================================================================
Programa----------: AOM134Manut
Autor-------------: Alex Wallauer
Data da Criacao---: 23/02/2023
Descricao---------: MANUTENCAO dos cadastros do ZPE (AOMS134) , ZPF (AOMS135)
Parametros--------: cAlias,nReg,nOpc
Retorno-----------: .T.
======================================================================= ========================================================
*/
User Function AOM134Manut(cAlias,nReg,_nOpc)

Local aPosObj   := {}  , nInc
Local aObjects  := {}
Local aSize     := {}
Local aInfo     := {}
Local aButtons  := {}
Local aCpos	    := NIL
Local aAcho     := NIL
Local cSeek     := ""
Local cWhile    := ""
Local bCond     := {|| .T. } // Se bCond .T. executa bAction1, senao executa bAction2
Local bAction1  := {|| .T. } // Retornar .T. para considerar o registro e .F. para desconsiderar
Local bAction2  := {|| .F. } // Retornar .T. para considerar o registro e .F. para desconsiderar
Local aYesFields:= {"ZPF_PROCOD","ZPF_GRUPO","ZPF_DESCRI","ZPF_MSBLQL"} //Lista todos os campos para o grid de inclusão

Private aTela[0][0],aGets[0]

//Cria variaveis M->????? da Enchoice
For nInc := 1 To ZPE->(FCount())
    If _nOpc = 3
       M->&(ZPE->(FieldName(nInc))) := CriaVar(ZPE->(FieldName(nInc)))
    Else
       M->&(ZPE->(FieldName(nInc))) := ZPE->(FieldGet(nInc))
    EndIf
Next nInc

//Cria aHeader e aCols da GetDados
aHeader := {}
aCols   := {}

DBSelectArea("ZPF")//ITENS
If _nOpc = 3 
 //FillGetDados(  nOpc ,cAlias>, nOrder,cSeekKey,bSeekWhile,uSeekFor,aNoFields,aYesFields,lOnlyYes,cQuery,bMontCols,lEmpty, aHeaderAux, aColsAux, bAfterCols, bBeforeCols,bAfterHeader, cAliasQry, bCriaVar, lUserFields, aYesUsado] )
	FillGetDados( _nOpc , "ZPF" , 1     ,        ,          ,        ,         ,aYesFields,.T.     ,      ,         ,.T.   ,,,,,, )
Else
   cSeek  := xFilial("ZPF")+ZPE->ZPE_CODIGO//SEEK COM O CAMPO DA CAPA
   cWhile := "ZPF_FILIAL+ZPF_CODIGO"//While COM OS CAMPOS DOS ITENS
   FillGetDados( _nOpc ,"ZPF",1,cSeek,{|| &cWhile },{{bCond,bAction1,bAction2}},/*aNoFields*/,aYesFields,.T.,/*cQuery*/,/*bMontCols*/,/*Inclui*/,/*aHeaderAux*/,/*aColsAux*/,/*bAfterCols*/,/*bBeforeCols*/)
EndIf

If _nOpc = 6//COPIA
   _nOpc = 3
EndIf

If _nOpc = 3  .Or. _nOpc = 4
   aAdd(aButtons,{,{|| FWMsgRun( ,{|| U_AMO134Bot("PRO")                     },"Pesquisando..","Aguarde..." ) },"","Inclui PRODUTOS"  })
   aAdd(aButtons,{,{|| FWMsgRun( ,{|| U_AMO134Bot("GRU")                     },"Pesquisando..","Aguarde..." ) },"","Inclui GRUPOS"    })
   aAdd(aButtons,{,{|| FWMsgRun( ,{|| U_AMO134Bot("PES",oGetD,1,"Produto ",1)},"Pesquisando..","Aguarde..." ) },"","PESQUISAR Produto"})
   aAdd(aButtons,{,{|| FWMsgRun( ,{|| U_AMO134Bot("PES",oGetD,2,"Grupo "  ,2)},"Pesquisando..","Aguarde..." ) },"","PESQUISAR Grupo"  })
EndIf

aSize := MsAdvSize()
aAdd( aObjects, { 100, 100, .T., .T. } )
aAdd( aObjects, { 200, 200, .T., .T. } )
aInfo := { aSize[ 1 ], aSize[ 2 ], aSize[ 3 ], aSize[ 4 ], 5, 5 }
aPosObj := MsObjSize( aInfo, aObjects,.T.)
While .T.

   _lGrava:=.F.
   DEFINE MSDIALOG oDlg1 TITLE cCadastro From aSize[7],0 To aSize[6],aSize[5] OF oMainWnd PIXEL
   
     DBSelectArea("ZPE")
     EnChoice("ZPE", nReg, _nOpc, , , , aAcho,aPosObj[1], aCpos, 3, , , , , , .F.)
     
     DBSelectArea("ZPF")
     //       MsGetDados():New(05          , 05         , 145        , 195        ,  4  , "U_LINHAOK"   , "U_TUDOOK"    , "+A1_COD",.T., {"A1_NOME"},   , .F., 200      , "U_FIELDOK"   , "U_SUPERDEL", , "U_DELOK", oDlg)
     oGetD := MsGetDados():New(aPosObj[2,1],aPosObj[2,2],aPosObj[2,3],aPosObj[2,4],_nOpc,"AllWaysTrue()","AllWaysTrue()",          ,.T., Nil        ,   ,    ,99999)
   
   ACTIVATE MSDIALOG oDlg1 ON INIT EnchoiceBar(oDlg1,{|| _lGrava:=.T.,If(U_AOMS134V("OKZPE"),oDlg1:End(),_lGrava:=.F.) },{|| oDlg1:End(),_lGrava:=.F. },,aButtons)
   
   If _lGrava .And. _nOpc <> 2
      FWMsgRun( ,{|oProc| _lGrava:=AMO134Grv(_nOpc,oProc) },"Gravando..","Aguarde..." )   
      If !_lGrava
         Loop
      EndIf
   ElseIf _nOpc == 3 .Or. _nOpc == 6
   	RollBackSX8()
   EndIf
   Exit
EndDo

Return .T.

/*
===============================================================================================================================
Programa----------: AMO134Grv
Autor-------------: Alex Wallauer
Data da Criacao---: 23/02/2023
Descricao---------: Funcoes dos botoes 
Parametros--------: _nOpc,oProc
Retorno-----------: .T.
===============================================================================================================================*/
Static Function AMO134Grv(_nOpc,oProc)

Local  Z ; lRetorno:=.T.
Local nConta:=0
Local _cTot:=AllTrim(Str(Len(aCols)))

ZPE->(DBSetOrder(1))//ZPE_FILIAL+ZPE_CODIGO
ZPF->(DBSetOrder(1))//ZPF_FILIAL+ZPF_CODIGO+ZPF_PROCOD+ZPF_GRUPO

Begin Sequence
BEGIN TRANSACTION 

If (_nOpc = 3 .Or. _nOpc = 4 .Or. _nOpc = 6) // Inclusão ou Alteracao ou Copia
  For Z := 1 To Len(aCols)
      
      nConta++
	   oProc:cCaption := ("Gravando linha: "+StrZero(nConta,5) +" de "+ _cTot )

		If !aTail( aCols[Z] )//NÃO DELETADOS
			    
         If !Empty(aCols[Z][1]+aCols[Z][2]) 
         
            If !ZPF->(DBSeek(xFilial("ZPF")+M->ZPE_CODIGO+aCols[Z][1]+aCols[Z][2] ))//INCLUIDOS
	            ZPF->(RecLock("ZPF",.T.))
               ZPF->ZPF_FILIAL:=xFilial("ZPF")
               ZPF->ZPF_CODIGO:=M->ZPE_CODIGO
               ZPF->ZPF_PROCOD:=aCols[Z][1]
               ZPF->ZPF_GRUPO :=aCols[Z][2]
               ZPF->ZPF_DESCRI:=aCols[Z][3]
               ZPF->ZPF_MSBLQL:=aCols[Z][4]
            Else//ALTERADOS
	            ZPF->(RecLock("ZPF",.F.))
               ZPF->ZPF_MSBLQL:=aCols[Z][4]
            EndIf
			   ZPF->(MSUnLock())
         
         EndIf
		
      Else// DELETADOS
         
         If ZPF->(DBSeek(xFilial("ZPF")+M->ZPE_CODIGO+aCols[Z][1]+aCols[Z][2] ))
	         ZPF->(RecLock( "ZPF" , .F. ) )
            ZPF->(DBDelete())
			   ZPF->(MSUnLock())
         EndIf

		EndIf

	Next Z

   If !ZPF->(DBSeek(xFilial("ZPF")+ M->ZPE_CODIGO ))
       DisarmTransaction()
       lRetorno:=.F.
       U_ITMsg("A regra esta sem itens ou grupos.",'Atenção!',"Cadastre pelo meno um item ou grupo.",3) 
       Break
   EndIf

   If ZPE->(DBSeek(xFilial("ZPE")+M->ZPE_CODIGO))
	   ZPE->( RecLock( "ZPE" , .F. ) )
   Else
	   ZPE->( RecLock( "ZPE" , .T. ) )
      ZPE->ZPE_FILIAL  := xFilial("ZPE")
   EndIf
   AVREPLACE("M","ZPE")
   ZPE->( MSUnLock() )
	
	If _nOpc = 3
		ConfirmSx8()
	EndIf


ElseIf (_nOpc == 5 ) // Exclusão
	
	For Z := 1 To Len(aCols)

      nConta++
	   oProc:cCaption := ("Excluindo linha: "+StrZero(nConta,5) +" de "+ _cTot )
	
      If ZPF->(DBSeek(xFilial("ZPF")+ZPE->ZPE_CODIGO+aCols[Z][1]+aCols[Z][2] ))
	      ZPF->(RecLock( "ZPF" , .F. ) )
         ZPF->(DBDelete())
      EndIf

	Next

   ZPE->(RecLock("ZPE" , .F. ) )
   ZPE->(DBDelete())
EndIf

END TRANSACTION
End Sequence

Return lRetorno

/*
===============================================================================================================================
Programa----------: AMO134Bot
Autor-------------: Alex Wallauer
Data da Criacao---: 23/02/2023
Descricao---------: Funcoes dos botoes 
Parametros--------: _cBotao,oMsMGet,nCol,cTit,_nMaxSel
Retorno-----------: .T.
======================================================================= ========================================================
*/
User Function AMO134Bot(_cBotao,oMsMGet,nCol,cTit,_nMaxSel)

Local _oGet1		:= Nil
Local _oDlg			:= Nil
Local _cGet1		:= Space(15)
Local _nOpca		:= 0
Local nPos			:= 0
Local _lAchou		:= .F.
Local P , _cSelect , _cTitAux
Static _cCodigo:=""
Static _cProds :=Space(500)
Static _cGrupos:=Space(500)

If _cBotao = "PRO"

   _cSelect:="SELECT B1_COD , B1_DESC FROM "+RETSQLNAME("SB1")+" SB1 WHERE D_E_L_E_T_ = ' ' AND B1_MSBLQL <> '1' AND B1_TIPO = 'PA'  ORDER BY B1_COD "
   _cTitAux:="CADASTRO DE PRODUTOS (TIPO = PA)"
   If _nMaxSel = 1
      _cProdsAux:=Space( Len(SB1->B1_COD) )
   Else
      _cProdsAux:=_cProds+";"//_cProdsAux Somente para o READERVAR DA U_ITF3GEN() não dar erro
   EndIf
   If Empty(_cCodigo) .Or. _cCodigo <> M->ZPE_CODIGO
      _cCodigo:=M->ZPE_CODIGO
      _cProds :=Space(500)
   EndIf
   //               1           2       3                        4                                      5       6         7                 8          9         10           11        12        13       14
   //   ITF3GEN(_cNomeSXB , _cTabela,_nCpoChave            , _nCpoDesc                            , _bCondTab,_cTitAux, _nTamChv       , _aDados , _nMaxSel , _lFilAtual , _cMVRET , _bValida , _oProc , _aParam )
   If U_ITF3GEN('F3_GENER',_cSelect ,{|Tab| (Tab)->B1_COD },{|Tab| StrTran((Tab)->B1_DESC,"-","")},          ,_cTitAux,Len(SB1->B1_COD),         , _nMaxSel ,.F.         ,"_cProdsAux",  )
      _cProds:=_cRetorno//Variavel _cRetorno é publica criada dentro da U_ITF3GEN()
      _aProds:= StrTokArr2(_cProds,";",.T.)
      If Len(aCols) = 1 .And. Empty(aCols[1,1]+aCols[1,2])
         aCols:={}
      EndIf
      For P := 1 To Len(_aProds) 
         If (Len(aCols) = 0 .Or. aScan(aCols, { |C| C[1] == _aProds[P] }) = 0) .And. !Empty( _aProds[P] )
            //          ZPF_PROCOD,ZPF_GRUPO,ZPF_DESCRI                                                                      ,ZPF_MSBLQL,Alias,RECNO WT    ,Deletado?
			   aAdd(aCols,{_aProds[P],Space(Len(ZPF->ZPF_GRUPO)),AllTrim(Posicione('SB1',1,xFilial('SB1')+_aProds[P],'B1_DESC')),"2"       ,'ZPF',Len(aCols)+1,.F.      })      
         EndIf
      Next
   
   EndIf

ElseIf _cBotao = "GRU"

   _cSelect:="SELECT BM_GRUPO , BM_DESC FROM "+RETSQLNAME("SBM")+" SBM WHERE D_E_L_E_T_ = ' ' ORDER BY BM_GRUPO "
   If _nMaxSel = 1
      _cGrupsAux:=Space( Len(SBM->BM_GRUPO) )
   Else
      _cGrupsAux:=_cGrupos+";"//_cGrupsAux Somente para o ReadVar DA U_ITF3GEN() não dar erro
   EndIf
   _cTitAux:="CADASTRO DE GRUPOS DE PRODUTOS"
   If Empty(_cCodigo) .And. _cCodigo <> M->ZPE_CODIGO
      _cCodigo:=M->ZPE_CODIGO
      _cGrupos:=Space(500)
   EndIf
   //               1           2         3                         4                                      5       6         7                    8          9         10           11           12        13       14
   //   ITF3GEN(_cNomeSXB , _cTabela  ,_nCpoChave              , _nCpoDesc                            , _bCondTab,_cTitAux, _nTamChv         , _aDados , _nMaxSel , _lFilAtual , _cMVRET    , _bValida , _oProc , _aParam )
   If U_ITF3GEN('F3_GENER',_cSelect   ,{|Tab| (Tab)->BM_GRUPO },{|Tab| StrTran((Tab)->BM_DESC,"-","")},          ,_cTitAux,Len(SBM->BM_GRUPO),         , _nMaxSel ,.F.         ,"_cGrupsAux",  )
      _cGrupos:=_cRetorno//Variavel _cRetorno é pulica criada dentro da U_ITF3GEN
      _aGrupos:= StrTokArr2(_cGrupos,";",.T.)
      If Len(aCols) = 1 .And. Empty(aCols[1,1]+aCols[1,2])
         aCols:={}
      EndIf
      For P := 1 To Len(_aGrupos) 
         If (Len(aCols) = 0 .Or. aScan(aCols, { |C| C[2] == _aGrupos[P] }) = 0) .And. !Empty( _aGrupos[P] )
            //          ZPF_PROCOD                 ,ZPF_GRUPO  ,ZPF_DESCRI                                                      ,ZPF_MSBLQL,Alias,RECNO WT    ,Deletado?
			   aAdd(aCols,{Space(Len(ZPF->ZPF_PROCOD)),_aGrupos[P],AllTrim(Posicione('SBM',1,xFilial('SBM')+_aGrupos[P],'BM_DESC')),"2"       ,'ZPF',Len(aCols)+1,.F.      })      
         EndIf
      Next
   
   EndIf

ElseIf _cBotao = "PES"

   If Len(aCols) = 1 .And. Empty(aCols[1,1]+aCols[1,2])
      Return .F.
   EndIf

   If oMsMGet <> NIL
      N:=oMsMGet:oBrowse:nAt
      C:=oMsMGet:oBrowse:nColPos
      aColsAux:=aCols//oMsMGet:oBrowse:aArray
   Else
      Return .F.
   EndIf
   
   DEFINE MSDIALOG _oDlg TITLE "Pesquisar" FROM 178,181 To 259,697 PIXEL 
   
	@003,030 Button "Consulta "+cTit	Size 070,012 PIXEL OF _oDlg Action(FWMsgRun( ,{|| _cGet1:=U_AMO134Bot(If(nCol=1,"PRO","GRU"),,,,1 )},"Pesquisando..","Aguarde..." ))

   @005,003 Say cTit+" :" Size 213,010 PIXEL OF _oDlg
   @020,003 MsGet _oGet1 Var _cGet1				Size 212,009 PIXEL OF _oDlg COLOR CLR_BLACK Picture "@!" //F3 If(nCol=1,"","")
   
   DEFINE SBUTTON FROM 004,227 Type 1 ENABLE ACTION ( _nOpca := 1 , _oDlg:End() ) OF _oDlg
   DEFINE SBUTTON FROM 021,227 Type 2 ENABLE ACTION ( _nOpca := 0 , _oDlg:End() ) OF _oDlg
   
   ACTIVATE MSDIALOG _oDlg CENTERED
   
   If _nOpca == 1
   
      _cGet1 := AllTrim( _cGet1 )
   	  
   	If (nPos := aScan(aColsAux,{|P| AllTrim(P[nCol]) == _cGet1 }) ) <> 0 
   	   oMsMGet:oBrowse:nAt:= N :=nPos//oMsMGet:oBrowse:Goposition()//oMsMGet:Goto(ngo)
   	   _lAchou:= .T.
   	EndIf	  	
   				
   Else
      Return .F.
   EndIf
   
   If _lAchou
      oMsMGet:Refresh()
      //oMsMGet:SetFocus()
      U_ITMsg(cTit+_cGet1+" esta no Recno WT: "+AllTrim(Str(aColsAux[nPos,Len(aColsAux[1])-1])),'Atenção!',,2) 
   Else
      U_ITMsg("Numero não encontrado nesta lista.",'Atenção!',"Tente outro codigo",3) 
   EndIf

   Return .T.

EndIf

Return _cRetorno
