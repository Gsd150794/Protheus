/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |24/09/2024| Chamado 48465. Sanado problemas apresentados no Code Analysis
Alex Wallauer |10/06/2025| Chamado 50990. Gravacao do campo C7_PICM com AIB_I_PICM via gatilho.
Alex Wallauer |25/09/2025| Chamado 51698. Gatilho para o pegar o campo C1_I_USOD da SC e colocar no C7_I_USOD.
===============================================================================================================================
*/

#Include "TOTVS.ch"

STATIC _lAlterou:=.F.

/*
===============================================================================================================================
Programa----------: ACOM036
Autor-------------: ALEX WALLAUER FERRREIRA
Data da Criacao---: 09/04/2018
Descrição---------: Função chamada do Gatilho 005 do C7_PRODUTO - Chamado: 24422
Parametros--------: _lGatilhoICMS = .T. qaundo chamado pelos gatilhos dos campos: C7_TOTAL/C7_QTSEGUM/C7_QUANT/C7_DESC/C7_VLDESC/C7_BASEIPI/C7_IPI/C7_BASEICM/C7_VALICM/C7_ICMCOMP/C7_ICMSRET
Retorno-----------: Se _lGatilhoICMS = .T. retona C7_PICM senão retorna C7_LOCAL
===============================================================================================================================
*/
User Function ACOM036(_lGatilhoICMS)

Local _aOrd := SaveOrd({"SC1"}) As Array
Local nPProduto  := aScan(aHeader,{|x| AllTrim(x[2]) == "C7_PRODUTO"}) As Numeric
Local nPosLocal  := aScan(aHeader,{|x| AllTrim(x[2]) == "C7_LOCAL"}) As Numeric
Local nPosNumSC  := aScan(aHeader,{|x| AllTrim(x[2]) == "C7_NUMSC"}) As Numeric
Local nPosItSC   := aScan(aHeader,{|x| AllTrim(x[2]) == "C7_ITEMSC"}) As Numeric
Local nPosItDtFa := aScan(aHeader,{|x| AllTrim(x[2]) == "C7_I_DTFAT"}) As Numeric
Local nPosTabPre := aScan(aHeader,{|x| AllTrim(x[2]) == "C7_CODTAB"}) As Numeric
Local nPosPreco  := aScan(aHeader,{|x| AllTrim(x[2]) == "C7_PRECO"}) As Numeric
Local nPosPICM   := aScan(aHeader,{|x| AllTrim(x[2]) == "C7_PICM"}) As Numeric
Local nPosUsod   := aScan(aHeader,{|x| Alltrim(x[2]) == "C7_I_USOD"}) As Numeric

Default _lGatilhoICMS := .F.

If !_lGatilhoICMS 
	If !Empty(aCols[N][nPosNumSC]) .And. !Empty(aCols[N][nPosItSC])
		SC1->(DBSetOrder(2))//C1_FILIAL+C1_PRODUTO+C1_NUM+C1_ITEM+C1_FORNECE+C1_LOJA
		If SC1->(MSSeek(xFilial("SC1")+aCols[N][nPProduto]+aCols[N][nPosNumSC]+aCols[N][nPosItSC]))
			aCols[N][nPosLocal] := SC1->C1_LOCAL
			aCols[N][nPosUsod] := SC1->C1_I_USOD
       EndIf
    Else
       aCols[N][nPosUsod] := If(Left(M->C7_PRODUTO,4) = "1000","N"," ")
   EndIf
EndIf

AIB->(DBSetOrder(1))//AIB_FILIAL+AIB_CODFOR+AIB_LOJFOR+AIB_CODTAB+AIB_ITEM
AIA->(DBSetOrder(1))//AIA_FILIAL+AIA_CODFOR+AIA_LOJFOR+AIA_CODTAB
aCols[N][nPosTabPre] := Space(Len(AIB->AIB_CODTAB))

If AIA->(DBSeek(xFilial("AIA")+CA120FORN+CA120LOJ))

   While AIA->(!Eof()) .And. xFilial("AIA")+CA120FORN+CA120LOJ == AIA->(AIA_FILIAL+AIA_CODFOR+AIA_LOJFOR)

      If AIA->AIA_DATDE <= Date() .And.  AIA->AIA_DATATE >= Date() .And. AIA->AIA_I_SITW = "A"//DENTRO DA VIGENCIA E APROVADA
      If AIB->(DBSeek(xFilial("AIB")+CA120FORN+CA120LOJ+AIA->AIA_CODTAB))
         While AIB->(!Eof()) .And. xFilial("AIB")+CA120FORN+CA120LOJ+AIA->AIA_CODTAB == AIB->(AIB_FILIAL+AIB_CODFOR+AIB_LOJFOR+AIB->AIB_CODTAB)
               If aCols[N][nPProduto ] == AIB->AIB_CODPRO .And. AIB->AIB_MOEDA = nMoedaPed
                  aCols[N][nPosTabPre] := AIB->AIB_CODTAB
                  aCols[N][nPosPreco ] := AIB->AIB_PRCCOM
                  MaFisRef("IT_PRCUNI" ,"MT120",aCols[N][nPosPreco]) 
                  aCols[N][nPosPICM  ] := AIB->AIB_I_PICM
                  MaFisRef("IT_ALIQICM","MT120",aCols[N][nPosPICM ])
                  Exit
               EndIf
               AIB->(DBSkip())
         EndDo
         If !Empty(aCols[N][nPosTabPre])
            If !Empty(AIA->AIA_CONDPG) .And. AIA->AIA_CONDPG <> cCondicao
               cCondicao:= AIA->AIA_CONDPG// cCondicao VARIAVEL Private DA TELA PADRÃO DO PC
               _lAlterou:=.T.
            EndIf
            If !Empty(AIA->AIA_I_TPFR) .And. AIA->AIA_I_TPFR <> LEFT(cTpFrete,1)
               cTpFrete :=RetTipoFrete(AIA->AIA_I_TPFR)
               _lAlterou:=.T.
            EndIf
            If _lAlterou .And. _lRefresh
               Eval(bGDRefresh)
            EndIf
            Exit
         EndIf
         EndIf
      EndIf
      AIA->(DBSkip())
   EndDo
EndIf

If _lGatilhoICMS 
   Return aCols[N][nPosPICM] //******  retorna o valor do PICM para os gatilhos dos campos: C7_TOTAL/C7_QTSEGUM/C7_QUANT/C7_DESC/C7_VLDESC/C7_BASEIPI/C7_IPI/C7_BASEICM/C7_VALICM/C7_ICMCOMP/C7_ICMSRET
EndIf

If N > 1
   dData:=aCols[N-1,GdFieldPos("C7_I_DTFAT",aHeader)]
   aCols[N][nPosItDtFa] := dData
EndIf

RestOrd(_aOrd)

Return aCols[N][nPosLocal]//******  retorna o Local para o gatilho C7_PRODUTO  *****

/*
===============================================================================================================================
Programa----------: ACOM36Cond
Autor-------------: ALEX WALLAUER FERRREIRA
Data da Criacao---: 28/06/2024
Descrição---------: Função usada no MT120OK.PRW: U_ACOM36Cond(.F.) U_ACOM36Cond(.T.)
Parametros--------: lAtualiza
Retorno-----------: _lAlterou
===============================================================================================================================
*/
User Function ACOM36Cond(lAtualiza)

If lAtualiza
   _lAlterou:=.F.
EndIf

Return _lAlterou
