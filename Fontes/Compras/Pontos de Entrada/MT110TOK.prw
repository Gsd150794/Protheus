/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |29/05/2025| Chamado 50512. Replicação do motivo da primeira linha para as demais linhas dos produtos.
Lucas Borges  |18/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
Alex Wallauer |25/09/2025| Chamado 51698. Nova Validacao do campo C1_I_USOD para gravar todos os produtos iguais.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MT110TOK
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 31/08/2015
Descrição---------: Ponto de Entrada no A110TudOk(). Localização: Rotina de Solicitação de Compras MATA110.PRX
Parametros--------: Nenhum
Retorno-----------: _lRet ( .T. - Valida e continua o processo / .F. - Invalida e interrompe o processo )
===============================================================================================================================
*/
User Function MT110TOK() As Logical

Local _aArea      := FWGetArea()
Local _aAreaSC1   := SC1->(GetArea())
Local x           := 0 As Numeric
Local nX          := 0 As Numeric
Local _lRet       := .T. As Logical
Local _lRet2      := .T. As Logical
Local aMensagem   := {} As Array
Local aProbl      := {} As Array
Local aSoluc      := {} As Array
Local _nPosCDINV  := aScan(aHeader, {|x| AllTrim(x[2]) == "C1_I_CDINV"}) As Numeric
Local _nPosDSINV  := aScan(aHeader, {|x| AllTrim(x[2]) == "C1_I_DSINV"}) As Numeric
Local _nPosSUBIN  := aScan(aHeader, {|x| AllTrim(x[2]) == "C1_I_SUBIN"}) As Numeric
Local _nPosSUIND  := aScan(aHeader, {|x| AllTrim(x[2]) == "C1_I_SUIND"}) As Numeric
Local _cUM_NO_Fracionada:= SuperGetMV("IT_UMNOFRAC",.F.,"PC,UN") As Character
Local _lValidFrac1UM    := .T. As Logical
Local _cGrupo     As Char
Local _cITEXCODSC As Char
Local _cITEXGRUSC As Char
Local _cITEXTIPSC As Char
Local _cProds   := "" As Char
Private _cItens := "" As Char
Private _aItens := {} As Array
Private _aTotais:= {} As Array 
Private _nTotSC := 0  As Numeric
Private _nTotPC := 0  As Numeric

If Empty(cCCust)
   aProbl := {}
   aAdd(aProbl, "O campo Centro de Custo tem seu preenchimento obrigatório.")

   aSoluc := {}
   aAdd(aSoluc, "Favor informar um Centro de Custo válido, ou acessar a consulta via [F3].")

   aMensagem := {"Centro de Custo Obrigatório", aProbl, aSoluc}

   U_ITMsHTML(aMensagem)

   _lRet := .F.
EndIf
cAprov:=cAprov
If Empty(cAprov)

   aProbl := {}
   aAdd(aProbl, "O campo Código do Aprovador tem seu preenchimento obrigatório.")

   aSoluc := {}
   aAdd(aSoluc, "Favor informar um Código de Aprovador válido, ou acessar a consulta via [F3].")

   aMensagem := {"Código do Aprovador Obrigatório", aProbl, aSoluc}

   U_ITMsHTML(aMensagem)

   _lRet := .F.
EndIf
cUrgen:=cUrgen
If Empty(cUrgen)
   aProbl := {}
   aAdd(aProbl, "O campo Urgente é obrigatório.")

   aSoluc := {}
   aAdd(aSoluc, "Favor informar se a solicitação é urgente ou não..")

   aMensagem := {"Campo Urgente Obrigatório", aProbl, aSoluc}

   U_ITMsHTML(aMensagem)

   _lRet := .F.
EndIf

If _lRet
   _lRet := U_VldInf("I")
EndIf

If _lRet

   ZZL->( DBSetOrder(3) )
   If ZZL->( DBSeek( xFilial("ZZL") + RetCodUsr() ) )
      If ZZL->ZZL_PEFRPA == "S"  .Or. ZZL->ZZL_PEFROU == "S"
         _lValidFrac1UM:=.F.
      EndIf
   EndIf
   ZZL->( DBSetOrder(1) )

   _nproduto := aScan( aHeader , {|X| Upper( AllTrim( X[2] ) )  == "C1_PRODUTO"})
   _nqtd     := aScan( aHeader , {|X| Upper( AllTrim( X[2] ) )  == "C1_QUANT"  })
   _n2UM     := aScan( aHeader , {|X| Upper( AllTrim( X[2] ) )  == "C1_SEGUM"  })
   _nqtdsegu := aScan( aHeader , {|X| Upper( AllTrim( X[2] ) )  == "C1_QTSEGUM"})
   _nItem    := aScan( aHeader , {|X| Upper( AllTrim( X[2] ) )  == "C1_ITEM"   })
   _nPosUsod := aScan( aHeader , {|x| Upper( AllTrim( x[2] ) )  == "C1_I_USOD" })
   _nPosDTNE := aScan( aHeader , {|x| Upper( AllTrim( x[2] ) )  == "C1_DATPRF" })

   _cGrupo    := AllTrim(SuperGetMV("IT_GRP2U",.T.,"0006"))
   _cITEXCODSC:= AllTrim(SuperGetMV("IT_EXCODSC",.F.,""))
   _cITEXGRUSC:= AllTrim(SuperGetMV("IT_EXGRUSC",.F.,""))
   _cITEXTIPSC:= AllTrim(SuperGetMV("IT_EXTIPSC",.F.,"SV"))
   _cProds   := ""
   _cItens   := ""
   _aItens   := {}

   For x := 1 To Len(aCols)
      If aTail(aCols[x]) // Se Linha Deletada
         Loop
      EndIf

      _cProduto:= aCols[x][_nproduto]
      _nquant  := aCols[x][_nqtdsegu]	//M->C1_QTSEGUM
      _c2UM    := aCols[x][_n2UM]	    //M->C1_SEGUM
      _dDTNE   := aCols[x][_nPosDTNE]	//M->C1_DATPRF

      SB1->(DBSeek(xFilial("SB1") + AllTrim(_cProduto)))

      If aScan(_aItens,_cProduto) = 0 .AND.;
         (Empty(_cITEXCODSC) .Or. !_cProduto     $ _cITEXCODSC) .AND.;
         (Empty(_cITEXGRUSC) .Or. !SB1->B1_GRUPO $ _cITEXGRUSC) .AND.;
         (Empty(_cITEXTIPSC) .Or. !SB1->B1_TIPO  $ _cITEXTIPSC)

         aAdd(_aItens,_cProduto)
         _cItens  += _cProduto+";"

      EndIf


      If (_nquant > 0  .Or. !Empty(_c2UM)) .And. SB1->B1_CONV == 0 .And. !(SB1->B1_GRUPO $ _cGrupo)

         U_ITMsg("Produto " + _cProduto + " não tem fator de conversão cadastrado, impossível usar segunda medida!", "Atenção",,1)

         _lRet := .F.
         Exit
      EndIf

      If  SB1->B1_TIPO = "SV"
         If aCols[X][_nPosUsod] <> "N"
            U_ITMsg("Produto " + _cProduto + ' esta com tipo de serviço ("SV") portanto o campo Aplicação direta deve estar preenchido com "Nao"', "Atenção",,1)
            _lRet := .F.
            Exit
         EndIf
      EndIf

      If Empty(_dDTNE)
         U_ITMsg("Produto " + _cProduto + ' com data de necessidade não preenchida', "Atenção","Favor preencher a data de necessidade",1)
         _lRet := .F.
         Exit
      EndIf

      If _lValidFrac1UM

         If  SB1->B1_UM $ _cUM_NO_Fracionada
               If aCols[x,_nqtd] <> Int(aCols[x,_nqtd])
                  _lRet2 := .F.
                  _cProds+="Item: " + aCols[x,_nItem]+" Prod.: " + AllTrim(aCols[x,_nproduto])+" - 1aUM: "+SB1->B1_UM+" - 2aUM: "+SB1->B1_SEGUM + CHR(13)+CHR(10)
               EndIf
         EndIf

         If  SB1->B1_SEGUM $ _cUM_NO_Fracionada
               If aCols[x,_nqtdsegu] <> Int(aCols[x,_nqtdsegu])
                  _lRet2 := .F.
                  _cProds+="Item: " + aCols[x,_nItem]+" Prod.: " + AllTrim(aCols[x,_nproduto])+" - 1aUM: "+SB1->B1_UM+" - 2aUM: "+SB1->B1_SEGUM + CHR(13)+CHR(10)
               EndIf
         EndIf

      EndIf

   Next x

   If _lValidFrac1UM .And. !_lRet2
      U_ITMsg("Não é permitido fracionar a quantidade da 1a. ou 2a. UM de produto onde a UM For "+_cUM_NO_Fracionada+". Clique em mais detalhes",;//,_ntipo,_nbotao,_nmenbot,_lHelpMvc,_cbt1,_cbt2,_bMaisDetalhes
               "Validação Fracionado","Favor informar apenas quantidades inteiras onde a UM For "+_cUM_NO_Fracionada+".",1     ,       ,        ,         ,     ,     ,;
               {|| Aviso("Validação Fracionado",_cProds,{"Fechar"}) } )
      _lRet:=.F.
   EndIf

   If _lRet .And. _lRet2
      aLog    :={}
      aLog2   :={}
      aMotivos:={}
      FWMsgRun( ,{|oProc|  MTLista("SELECT",oProc) } , "Verificando Produtos, Aguarde..." )
      If Len(aLog) > 0 .Or. Len(aLog2) > 0
         _lRet:=MTLista("LISTA")
      EndIf
   EndIf

EndIf

For nX := 1 To Len(aCols)
   If cCInve <> aCols[nX][_nPosCDINV]
      aCols[nX,_nPosCDINV ] := cCInve
      aCols[nX,_nPosDsInv ] := cDsInv
      aCols[nX,_nPosSUBIN ] := Space(Len(cCInve))
      aCols[nX,_nPosSUIND ] := Space(Len(cDsInv))
   EndIf
Next nX

If cAplic == "I"
   For nX := 1 To Len(aCols)
      If aCols[nX][Len(aHeader)+1]//DELETADOS
         Loop
      EndIf
      If Empty(AllTrim(aCols[nX,_nPosSUBIN]))
         ZZI->(DBSetOrder(3))//ZZI_FILIAL+ZZI_INVPAI+ZZI_TIPO
         If ZZI->(DBSeek(xFilial("ZZI")+cCInve+"2"))
               U_ITMsg('Campo de Subinvestimento não Preenchido!', "Atenção",'',1)
               _lRet := .F.
         EndIf
      Else
         ZZI->(DBSetOrder(1))//ZZI_FILIAL+ZZI_INVPAI+ZZI_TIPO
         If ZZI->(DBSeek(xFilial("ZZI")+aCols[nX,_nPosSUBIN ]))
               If ZZI->ZZI_INVPAI <> cCInve
                  U_ITMsg('Campo de Subinvestimento da linha '+AllTrim(Str(nX))+' não corresponde ao projeto!', "Atenção",'Mofifique o campo selecionando um os dos itens da consulta.',1)
                  _lRet := .F.
               Else
                  If ZZI->ZZI_TIPO == "2"
                     ZZI->(DBSetOrder(3))//ZZI_FILIAL+ZZI_INVPAI+ZZI_TIPO
                     If ZZI->(DBSeek(xFilial("ZZI")+cCInve+"3"))
                           U_ITMsg('No Campo de Subinvestimento da linha '+AllTrim(Str(nX))+' é obrigatório um Investimento de nivel 3 !', "Atenção",'Mofifique o campo selecionando um Investimento de nivel 3 da consulta.',1)
                           _lRet := .F.
                     EndIf
                  EndIf
               EndIf
         EndIf
      EndIf
   Next nX
EndIf

//*****************  VALIDAÇÕES COLQOUE ACIMMA DAQUI SOMENTE ************************
cAplicDir:=aCols[1,_nPosUsod]
lPergunta:=.F.
For nX := 1 To Len(aCols)
	If aCols[nX,_nPosUsod] <> cAplicDir
		lPergunta:=.T.
		Exit
	EndIf
Next nX
 
If lPergunta 
	lRet := U_ITMSG("O campo aplicação direta está diferente nos itens da SC, confirma?",'Atenção!',,3,2,4,,"CORRIGIR","GRAVAR",,,.T.)
	If lRet = Nil//Quando aperta o x da dialog
	   lRet := .F.
	EndIf
	If lRet
	   lRet := U_ITMsg("Alterar Aplicação Direta para?",'Atenção!',,3,2,4,,"Sim p/ todos","Não p/ todos",,,.T.)
	   If lRet <> Nil//Quando aperta o x da dialog
		  If lRet
			 cAplicDir:="S"
		  Else
			 cAplicDir:="N"
		  EndIf     
		  For nX := 1 To Len(aCols)
			  aCols[nX,_nPosUsod] := cAplicDir
		  Next nX
	   EndIf
	EndIf
EndIf

RestArea(_aArea)
RestArea(_aAreaSC1)

Return(_lRet)

/*
===============================================================================================================================
Programa----------: MTLista
Autor-------------: Alex Wallauer Ferreira
Data da Criacao---: 05/07/2019
Descrição---------: Seleciona e lista itens em aberto
Parametros--------: _cAcao As Character ,oProc As Object
Retorno-----------: As Logical
===============================================================================================================================
*/
Static Function  MTLista(_cAcao As Character ,oProc As Object) As Logical

Local _cAlias     As Character
Local _cQuery     As Character
Local I           As Numeric
Local _nPosMotivo As Numeric
Local _nPosProdut As Numeric
Local nTamMOT     As Numeric
Local _nTot       As Numeric
Local _lOK        As Logical
Local cTit1       As Character
Local _aSize      As Array
Local _aInfo      As Array
Local aObjects    As Array
Local nSaldo      As Numeric
Local lTemSol     As Logical
Local aLogAux     As Array
Local aMotAux     As Array
Local _cTotReg    As Character
Local _nConta     As Numeric
Local _cObsSC     As Character
Local _cObsPC     As Character
Local aHeader1    As Array
Local aHeader2    As Array
Local aHeader3    As Array
Local oDlg2       As Numeric
Local oPnlTopTop  As Numeric
Local nLin01      As Numeric
Local nCol01      As Numeric
Local aTotAux := {} As Array

_nPosMotivo:= aScan(aHeader, {|x| AllTrim(x[2]) == "C1_I_MOTSC"})
_nPosProdut:= aScan(aHeader, {|x| AllTrim(x[2]) == "C1_PRODUTO"})
_aSize     := MsAdvSize()
_aInfo     := { _aSize[1] , _aSize[2] , _aSize[3] , _aSize[4] , 3 , 3 }
aObjects   := {}
If SC1->(FIELDPOS("C1_I_MOTSC")) > 0
   nTamMOT:=Len(SC1->C1_I_MOTSC)
Else
   nTamMOT:=100
EndIf

If _cAcao = "SELECT"

   _cAlias := GetNextAlias()
   _cItens := LEFT(_cItens,Len(_cItens)-1)

   _cQuery := " SELECT C1_EMISSAO, C1_SOLICIT, C1_NUM, C1_PRODUTO , C1_PEDIDO , C1_QUANT , 0 C7_QUANT , C1_ITEM , ' ' C7_ITEM  "
   _cQuery += "        FROM " + RETSQLNAME("SC1") + " C1 "
   _cQuery += "        WHERE C1_FILIAL= '"+cFilAnt+"' AND  C1_PEDIDO = ' ' AND D_E_L_E_T_ = ' ' AND C1_RESIDUO <> 'S' AND C1_QUANT > C1_QUJE AND C1_NUM <> '"+cA110Num+"' AND "
   _cQuery += "              C1_PRODUTO IN "+FormatIn(_cItens,";")
   _cQuery += " UNION "
   _cQuery += " SELECT C1_EMISSAO, C1_SOLICIT, C1_NUM, C1_PRODUTO , C1_PEDIDO , C1_QUANT , C7_QUANT  , C1_ITEM  , C7_ITEM "
   _cQuery += "        FROM " + RETSQLNAME("SC1") + " C1 "
   _cQuery += "        JOIN " + RETSQLNAME("SC7") + " C7 ON C1_FILIAL = C7_FILIAL AND C1_NUM = C7_NUMSC AND C1_ITEM = C7_ITEMSC  "
   _cQuery += "        WHERE  C1_FILIAL= '"+cFilAnt+"' AND  C1_PEDIDO <> ' ' AND  C1.D_E_L_E_T_ = ' ' AND C1_RESIDUO <> 'S' AND C7_RESIDUO <> 'S' AND  "
   _cQuery += "               C7_ENCER = ' ' AND C7.D_E_L_E_T_ = ' ' AND C7_QUANT > C7_QUJE AND C1_PRODUTO IN "+FormatIn(_cItens,";")
   _cQuery += " ORDER BY C1_PRODUTO , C1_NUM , C1_ITEM  "

   MPSysOpenQuery( _cQuery ,_cAlias )
   DBSelectArea(_cAlias)
   _nTot:=0
   COUNT To _nTot

   _cTotReg:=AllTrim(Str( _nTot ))
   _nConta :=0
   _cObsSC :="[Tem SC em Aberto] "
   _cObsPC :="[Tem PC em Aberto] "
   _aTotais:={}//Declarada Private NA FUNÇÃO MT110TOK()
   _nTotSC :=0 //Declarada Private NA FUNÇÃO MT110TOK()
   _nTotPC :=0 //Declarada Private NA FUNÇÃO MT110TOK()

   (_cAlias)->(DBGoTop())

   While !((_cAlias)->(Eof()))

      _nConta++
      If oproc <> nil
            oproc:cCaption := "Lendo "+(_cAlias)->C1_PRODUTO+" - "+ AllTrim(Str(_nConta)) + " de " + _cTotReg
            ProcessMessages()
      EndIf

      aLogAux:={}
      aAdd(aLogAux,(_cAlias)->C1_NUM    )// 01
      aAdd(aLogAux,(_cAlias)->C1_PRODUTO)// 02
      aAdd(aLogAux,(_cAlias)->C1_ITEM   )// 03
      aAdd(aLogAux,(_cAlias)->C1_EMISSAO)// 04
      aAdd(aLogAux,(_cAlias)->C1_SOLICIT)// 05
      aAdd(aLogAux,(_cAlias)->C1_QUANT  )// 06

      aAdd(aLogAux,(_cAlias)->C1_PEDIDO )// 07
      aAdd(aLogAux,(_cAlias)->C7_ITEM   )// 08
      aAdd(aLogAux,(_cAlias)->C7_QUANT  )// 09
      aAdd(aLogAux,.F.                  )// 10
      aAdd(aLog,aLogAux)

      If (_nPos:=aScan(aMotivos,{|C| C[1] == (_cAlias)->C1_PRODUTO })) = 0
         aMotAux:={}
         aAdd(aMotAux,(_cAlias)->C1_PRODUTO )// 01
         aAdd(aMotAux,""    )                // 02
         aAdd(aMotAux,Space(nTamMOT))        // 03
         aAdd(aMotAux,.F.  )                 // 04
         aAdd(aMotivos,aMotAux)
         _nPos:=Len(aMotivos)
      EndIf
      If _nPos > 0 .And. aLogAux[6] > 0 .And. !_cObsSC $ aMotivos[_nPos,2]
         aMotivos[_nPos,2]:= aMotivos[_nPos,2] + _cObsSC
      EndIf
      If _nPos > 0 .And. aLogAux[9] > 0 .And. !_cObsPC $ aMotivos[_nPos,2]
         aMotivos[_nPos,2]:= aMotivos[_nPos,2] + _cObsPC
      EndIf

      _nTotSC:= ((_cAlias)->C1_QUANT-(_cAlias)->C7_QUANT)
      _nTotPC:= (_cAlias)->C7_QUANT
      If (_nPos:=aScan(_aTotais,{|C| C[1] == (_cAlias)->C1_PRODUTO })) = 0

         aTotAux:={}
         aAdd(aTotAux,(_cAlias)->C1_PRODUTO )// 01
         aAdd(aTotAux,_nTotSC)               // 02
         aAdd(aTotAux,_nTotPC)               // 03

         aAdd(_aTotais,aTotAux)
      Else
         _aTotais[_nPos,2]+=_nTotSC 
         _aTotais[_nPos,3]+=_nTotPC 
      EndIf

      (_cAlias)->(DBSkip())

   EndDo

   lTemSol:=Len(aLog) > 0
   aLog2:={}
   _cObs:="[Tem saldo em estoque]"
   SB2->(DBSetOrder(1))
   SBZ->(DBSetOrder(1))
   For I := 1 To Len(_aItens)
      If SB2->(DBSeek(xFilial()+_aItens[I]))
            While SB2->(!Eof()) .And. xFilial("SB2")+_aItens[I] == SB2->B2_FILIAL+SB2->B2_COD

            nSaldo := SB2->(SaldoSB2())//AVALIAR O ESTOQUE DO PRODUTO EM TODOS OS ARMAZENS

            If nSaldo > 0 .Or. lTemSol
                  SBZ->(DBSeek(xFilial()+_aItens[I]))

                  aLogAux:={}
                  aAdd(aLogAux,_aItens[I] )  //01
                  aAdd(aLogAux,SB2->B2_LOCAL)//02
                  aAdd(aLogAux,SBZ->BZ_EMIN) //03
                  aAdd(aLogAux,nSaldo)       //04
                  aAdd(aLogAux,.F.)          //05
                  aAdd(aLog2,aLogAux)

                  If nSaldo > 0
                     If (_nPos:=aScan(aMotivos,{|C| C[1] == _aItens[I] })) = 0
                        aLogAux:={}
                        aAdd(aLogAux,_aItens[I]    )//01
                        aAdd(aLogAux,_cObs )        //02
                        aAdd(aLogAux,Space(nTamMOT))//03
                        aAdd(aLogAux,.F.)           //04
                        aAdd(aMotivos,aLogAux)
                     ElseIf _nPos > 0 .And. !_cObs $ aMotivos[_nPos,2]
                        aMotivos[_nPos,2]:= aMotivos[_nPos,2] + _cObs
                     EndIf
                  EndIf

               EndIf
               SB2->(DBSkip())
            EndDo
      EndIf
   Next I

ElseIf  _cAcao = "LISTA" .And. (Len(aLog) > 0 .Or. Len(aLog2) > 0)

   If Len(aLog) = 0
      aLogAux:={}
      aAdd(aLogAux,"" )// 01
      aAdd(aLogAux,"" )// 02
      aAdd(aLogAux,"" )// 03
      aAdd(aLogAux,"" )// 04
      aAdd(aLogAux,"" )// 05
      aAdd(aLogAux,0  )// 06
      aAdd(aLogAux,"" )// 07
      aAdd(aLogAux,"" )// 08
      aAdd(aLogAux,0  )// 09
      aAdd(aLogAux,.F.)// 10
      aAdd(aLog,aLogAux)
   Else//COLOCA OS TOTAIS NO FINAL DA LISTA
      For I := 1 To Len(_aTotais)
            aLogAux:={}
            aAdd(aLogAux,"")           // 01
            aAdd(aLogAux,_aTotais[I,1])// 02
            aAdd(aLogAux,"")           // 03
            aAdd(aLogAux,"")           // 04
            aAdd(aLogAux,"Total SCs" ) // 05
            aAdd(aLogAux,_aTotais[I,2])// 06
            aAdd(aLogAux,"" )          // 07
            aAdd(aLogAux,"Total PVs" ) // 08
            aAdd(aLogAux,_aTotais[I,3])// 09
            aAdd(aLogAux,.F.)// 10
            aAdd(aLog,aLogAux)
      Next I
   EndIf
   //-------------------------------------------|
   //Estrutura do aHeader do MsNewGetDados      |
   //-------------------------------------------|
   //aHeader[01] - X3_TITULO  | Título          |
   //aHeader[02] - X3_CAMPO   | Campo           |
   //aHeader[03] - X3_PICTURE | Picture         |
   //aHeader[04] - X3_TAMANHO | Tamanho         |
   //aHeader[05] - X3_DECIMAL | Decimal         |
   //aHeader[06] - X3_VALID   | Validação       |
   //aHeader[07] - X3_USADO   | Usado           |
   //aHeader[08] - X3_TIPO    | Tipo            |
   //aHeader[09] - X3_F3      | F3              |
   //aHeader[10] - X3_CONTEXT | Contexto (R,V)  |
   //aHeader[11] - X3_CBOX    | Combobox        |
   //aHeader[12] - X3_RELACAO | Inicial. Padrao |
   //aHeader[13] - X3_WHEN    | Habilita edicao |
   //aHeader[14] - X3_VISUAL  | Alteravel (A,V) |
   //aHeader[15] - X3_VLDUSER | Valid de User   |
   //aHeader[16] - X3_PICTVAR | Picture         |
   //aHeader[17] - X3_OBRIGAT | Obrigatorio     |

   aHeader1:={}
   ////aHeader,{X3_TITULO)     , X3_CAMPO   , PICT                  ,Tamanho             ,D,Val,USADO,X3_TIPO,ARQUIVO,X3_CONTEXT,X3_CBOX,X3_RELACAO,X3_WHEN   ,X3_VISUAL ,X3_VLDUSER,X3_PICTVAR,X3_OBRIGAT
   aAdd(aHeader1,{"SC"         ,"C1_NUM"    ,"@!"                   ,Len(SC1->C1_NUM)    ,0,""  ,""  ,"C"    ,""     ,""        ,""     ,""        ,".F."})// 01
   aAdd(aHeader1,{"Produto"    ,"C1_PRODUTO","@!"                   ,Len(SC1->C1_PRODUTO),0,""  ,""  ,"C"    ,""     ,""        ,""     ,""        ,".F."})// 02
   aAdd(aHeader1,{"Item SC"    ,"C1_ITEM"   ,"@!"                   ,Len(SC1->C1_ITEM)   ,0,""  ,""  ,"C"    ,""     ,""        ,""     ,""        ,".F."})// 03
   aAdd(aHeader1,{"Dt emissao" ,"C1_EMISSAO","@D"                   ,08                  ,0,""  ,""  ,"D"    ,""     ,""        ,""     ,""        ,".F."})// 04
   aAdd(aHeader1,{"Solicitante","C1_SOLICIT","@!"                   ,Len(SC1->C1_SOLICIT),0,""  ,""  ,"C"    ,""     ,""        ,""     ,""        ,".F."})// 05
   aAdd(aHeader1,{"Qtde SC"    ,"C1_QUANT"  ,"@E 999,999,999.999"   ,13                  ,3,""  ,""  ,"N"    ,""     ,""        ,""     ,""        ,".F."})// 06
   aAdd(aHeader1,{"Pedido"     ,"C1_PEDIDO" ,"@!"                   ,Len(SC1->C1_PEDIDO ),0,""  ,""  ,"C"    ,""     ,""        ,""     ,""        ,".F."})// 07
   aAdd(aHeader1,{"Item PC"    ,"C7_ITEM"   ,"@!"                   ,Len(SC7->C7_ITEM   ),0,""  ,""  ,"C"    ,""     ,""        ,""     ,""        ,".F."})// 08
   aAdd(aHeader1,{"Qtde PC"    ,"C7_QUANT"  ,"@E 999,999,999.999"   ,13                  ,3,""  ,""  ,"N"    ,""     ,""        ,""     ,""        ,".F."})// 09

   aHeader2:={}
   aAdd(aHeader2,{"Produto"    ,"C1_PRODUTO","@!"                   ,Len(SC1->C1_PRODUTO),0,""  ,""  ,"C"    ,""     ,""        ,""     ,""        ,".F."})
   aAdd(aHeader2,{"Armazem"    ,"B2_LOCAL"  ,"@!"                   ,Len(SB2->B2_LOCAL)  ,0,""  ,""  ,"C"    ,""     ,""        ,""     ,""        ,".F."})
   aAdd(aHeader2,{"Estoque Min","B2_LOCAL"  ,"@E 99,999,999,999.999",15                  ,3,""  ,""  ,"N"    ,""     ,""        ,""     ,""        ,".F."})
   aAdd(aHeader2,{"Saldo"      ,"C1_QUANT"  ,"@E 99,999,999,999.999",15                  ,3,""  ,""  ,"N"    ,""     ,""        ,""     ,""        ,".F."})

   cVal:="U_MT110TVal()"
   aHeader3:={}
   aAdd(aHeader3,{"Produto"                 ,"C1_PRODUTO","@!"      ,Len(SC1->C1_PRODUTO),0,""  ,""  ,"C"    ,""     ,""        ,""     ,""        ,".F."})
   aAdd(aHeader3,{"Observação"              ,"OBS"       ,"@!"      ,100                 ,0,""  ,""  ,"C"    ,""     ,""        ,""     ,""        ,".F."})
   aAdd(aHeader3,{"Digite o motivo p/ item" ,"MOTIVO"    ,"@!"      ,Len(SC1->C1_I_MOTSC),0,cVal,""  ,"C"    ,""     ,""        ,""     ,""        ,".T."})

   cTit1  :="LISTA DOS ITENS COM SOLICITACOES EM ABERTA OU COM SALDO EM ESTOQUE (MT110TOK)"
   _aSize := MsAdvSize()
   _aInfo := { _aSize[1] , _aSize[2] , _aSize[3] , _aSize[4] , 3 , 3 }
   // PEGA TAMANHOS DAS TELAS
   aObjects := {}
   aAdd( aObjects , { 100 , 050 , .T. , .F. , .F. } )
   aAdd( aObjects , { 100 , 100 , .T. , .T. , .F. } )
   aPosObj  := MsObjSize( _aInfo , aObjects )

   aFoders1:={}
   aAdd(aFoders1,"Solicitações / Pedidos")        //Se mudar os nomes tem que mudar em todo o programa pq eles são chave de Pesquisa
   aAdd(aFoders1,"Saldo em Armazens")             //Se mudar os nomes tem que mudar em todo o programa pq eles são chave de Pesquisa
   aAdd(aFoders1,"Motivo")

   _lOK  :=.F.
   nLin01:=05
   nLin02:=08
   nLin03:=25
   nCol01:=02

   _bOK:={|| aMotivos:=oBrwMOTI:aCols , If( Len(aMotivos) = 0 .Or. Len(AllTrim(aMotivos[1,3])) > 10 , (_lOK:=.T. ,oDlg2:End() ), ;
               U_ITMsg("Preencha o campo motivo de cada produto na aba motivo.","ATENCAO","Com mais de 10 caracteres.",1) ) }

   U_ITMsg("Já existe SC(s) / PC(s) em aberto ou saldo em estoque para esse(s) produto(s).","ATENCAO",;//,_ntipo,_nbotao,_nmenbot,_lHelpMvc,_cbt1,_cbt2,_bMaisDetalhes
               "Caso queria incluir assim mesmo clique em CONFIRMA na proxima tela, caso contrário favor contatar o solicitante da S.C. em aberto para maiores detalhes.",1)

   While .T.

      DEFINE MSDIALOG oDlg2 TITLE cTit1 OF oMainWnd PIXEL FROM _aSize[7],0 To _aSize[6],_aSize[5]

      oPnlTopTop := TPanel():New( 1 , 0 , , oDlg2 , , , , , , 80 , 20 , .F. , .F. )

         @ nLin01, nCol01 BUTTON  "CONFIRMA"  SIZE 035, 14 OF oPnlTopTop ACTION (EVAL(_bOK)) PIXEL

         @ nLin01, nCol01+40 BUTTON  "VOLTAR"    SIZE 035, 14 OF oPnlTopTop ACTION (_lOK:=.F.,oDlg2:End()) PIXEL

         //FOLDER PRINCIPAL COM 3 PASTAS **************************************************************************
         _nColFolder:=aPosObj[2,4]
         _nLinFolder:=aPosObj[2,3]-10

         oTFolder01:= TFolder():New( nLin03,1,aFoders1,,oDlg2,,,,.T., , _nColFolder,_nLinFolder )

         oPastaSCPC:=oTFolder01:aDialogs[1]

         oBrwSCPC:=MT110TBrw(aHeader1,aLog,oPastaSCPC)

         oPastaESTO:=oTFolder01:aDialogs[2]

         oBrwESTO:=MT110TBrw(aHeader2,aLog2,oPastaESTO)

         oPastaMOTI:=oTFolder01:aDialogs[3]

         oBrwMOTI:=MT110TBrw(aHeader3,aMotivos,oPastaMOTI)

      ACTIVATE MSDIALOG oDlg2 ON INIT (oPnlTopTop:Align:= CONTROL_ALIGN_TOP      ,;
                                          oTFolder01:Align:= CONTROL_ALIGN_ALLCLIENT,;
                                          oBrwMOTI:oBrowse:Align:= CONTROL_ALIGN_ALLCLIENT,;
                                          oBrwESTO:oBrowse:Align:= CONTROL_ALIGN_ALLCLIENT,;
                                          oBrwSCPC:oBrowse:Align:= CONTROL_ALIGN_ALLCLIENT )
      _lLoop:=.F.
      If _lOK
         aMotivos:=oBrwMOTI:aCols
         For I := 1 To Len(aMotivos)
            If Len(AllTrim(aMotivos[I,3])) < 10
               U_ITMsg("Preencha o campo motivo do produto "+aMotivos[I,1]+" na aba motivo.","ATENCAO","Com mais de 10 caracteres.",1)
               _lLoop:=.T.
               Exit
            EndIf
            If (_nPos:=aScan(aCols,{|C| C[_nPosProdut] == aMotivos[I,1] })) > 0 .And. _nPosMotivo > 0
                  aCols[_nPos,_nPosMotivo ] := aMotivos[I,3]
            EndIf
         Next I
      EndIf
      If _lLoop
         Loop
      EndIf
      Exit
   EndDo

EndIf

Return _lOK

/*
===============================================================================================================================
Programa--------: MT110TBrw
Autor-----------: Alex Wallauer
Data da Criacao-: 14/03/2024
Descrição-------: Cria os blowses
Parametros------: aHeaderP,_aColsP,oPasta
Retorno---------: oMsMGet
===============================================================================================================================*/
Static Function MT110TBrw(aHeaderP,_aColsP,oPasta) As Object
 
Local oMsMGet

If Len(_aColsP) > 0
   nGDAction:= GD_UPDATE
Else
   Return .F.
EndIf
                           //[ nTop]          , [ nLeft]   , [ nBottom] , [ nRight ] , [ nStyle],cLinhaOk,cTudoOk,cIniCpos, [ aAlter], [ nFreeze], [ nMax], [ cFieldOk], [ cSuperDel], [ cDelOk], [ oWnd], [ aPartHeader], [ aParCols], [ uChange], [ cTela], [ aColsSize]
oMsMGet := MsNewGetDados():New((aPosObj[2,1]+12),aPosObj[2,2],aPosObj[2,3],aPosObj[2,4],nGDAction ,        ,       ,        ,          ,           ,        ,            ,             ,          ,oPasta  ,aHeaderP        , _aColsP   ,)
oMsMGet:SetEditLine(.F.)

Return oMsMGet

/*
===============================================================================================================================
Programa--------: MT110TVal
Autor-----------: Alex Wallauer
Data da Criacao-: 14/03/2024
Descrição-------: Valida a coluna Motivo
Parametros------: Nenhum 
Retorno---------: .T. se tudo ok, .F. se tiver algum erro
===============================================================================================================================
*/
User Function MT110TVal() As Logical

Local aMotivos:=oBrwMOTI:aCols
Local _nLin   :=oBrwMOTI:oBrowse:nat As Numeric
Local _cSalvaMot As Character
Local nX As Numeric

If Len(aMotivos) = 0 .Or. Len(AllTrim(M->MOTIVO)) > 10 
   If _nLin = 1 .And. U_ITMsg("Replicar esse motivo para as linhas abaixo? "+CRLF+" Os motivos abaixo preenchidos serão sobrescritos.","Atenção",,3,2,2)
      _cSalvaMot:=M->MOTIVO
      For nX := 2 To Len(aMotivos)
         aMotivos[nX,3] := _cSalvaMot
      Next nX
      oBrwMOTI:aCols := aMotivos
      oBrwMOTI:oBrowse:Refresh()
   EndIf   
Else
   U_ITMsg("Preenchimento do campo motivo INVALIDO!","ATENCAO","Preencha esse campo com mais de 10 caracteres.",1)
   Return .F. 
EndIf

Return .T.
