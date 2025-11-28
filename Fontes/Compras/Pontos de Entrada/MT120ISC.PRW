/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |08/12/2021| Chamado 38541. Tratamento para o campo virtual NOVO C7_I_OBSSC. 
Alex Wallauer |28/06/2024| Chamado 47732. Andre. Novo WF de Tabela de Preços de Fornecedores.
Alex Wallauer |03/07/2025| Chamado 50990. Gravacao do campo C7_PICM com AIB_I_PICM via SC. 
========================================================================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MT120ISC
Autor-------------: Heder Jose
Data da Criacao---: 13/12/2011
Descrição---------: Ponto de entrada na montagem de acols incluido por SC na inclusão de pedido de compras
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MT120ISC

Local _aArea		:= FWGetArea()
Local _nCols		:= Len(aCols)
Local _nPosDirCr	:= aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C7_I_DIRCR"})
Local _nPosAplic	:= aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C7_I_APLIC"})
Local _nPosUrgen	:= aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C7_I_URGEN"})
Local _nPosCdInv	:= aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C7_I_CDINV"})
Local _nPosSuInv	:= aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C7_I_SUBIN"})//NOVO
Local _nPosDsInv	:= aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C7_I_DSINV"})
Local _nPosDsSub	:= aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C7_I_SUIND"})//NOVO
Local _nPosUsod	:= aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C7_I_USOD" })
Local _nPosNFor	:= aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C7_I_NFORN"})
Local _nPosClaim  := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C7_I_CLAIM"})//CLAIM
Local _nPosObsSC	:= aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C7_I_OBSSC"})//NOVO
Local nPosTabPre  := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C7_CODTAB" })
Local nPosPreco   := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C7_PRECO"  })
Local nPProduto   := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C7_PRODUTO"})

lSolic := .T.

//Gatilho buscando a informacao do cadastro do produto para atualizacao no lancamento.
aCols[_nCols][_nPosDirCr]	:= SB1->B1_I_DIRCR
aCols[_nCols][_nPosNFor]	:= Posicione("SA2",1,xFilial("SA2")+CA120FORN+CA120LOJ,"A2_NOME")  //Nome do fornecedor
aCols[_nCols][_nPosClaim]	:= SC1->C1_I_CLAIM//CLAIM
aCols[_nCols][_nPosAplic]	:= SC1->C1_I_APLIC
aCols[_nCols][_nPosUrgen]	:= SC1->C1_I_URGEN
aCols[_nCols][_nPosCdInv]	:= SC1->C1_I_CDINV
aCols[_nCols][_nPosDsInv]	:= Posicione("ZZI",1,xFilial("ZZI") + SC1->C1_I_CDINV, "ZZI_DESINV")
aCols[_nCols][_nPosSuInv]	:= SC1->C1_I_SUBIN//NOVO
aCols[_nCols][_nPosDsSub]	:= Posicione("ZZI",1,xFilial("ZZI") + SC1->C1_I_SUBIN, "ZZI_DESINV")
aCols[_nCols][_nPosUsod]	:= SC1->C1_I_USOD
aCols[_nCols][_nPosObsSC]  := SC1->C1_I_OBSSC//NOVO

AIB->(DBSetOrder(1))//AIB_FILIAL+AIB_CODFOR+AIB_LOJFOR+AIB_CODTAB+AIB_ITEM
AIA->(DBSetOrder(1))//AIA_FILIAL+AIA_CODFOR+AIA_LOJFOR+AIA_CODTAB
aCols[_nCols][nPosTabPre] := Space(Len(AIB->AIB_CODTAB))

If !Empty(CA120FORN) .And. !Empty(CA120LOJ) .And. AIA->(DBSeek(xFilial("AIA")+CA120FORN+CA120LOJ)) 

   While AIA->(!Eof()) .And. xFilial("AIA")+CA120FORN+CA120LOJ == AIA->(AIA_FILIAL+AIA_CODFOR+AIA_LOJFOR)

      If AIA->AIA_DATDE <= Date() .And.  AIA->AIA_DATATE >= Date() .And. AIA->AIA_I_SITW = "A"//DENTRO DA VIGENCIA E APROVADA
        If AIB->(DBSeek(xFilial("AIB")+CA120FORN+CA120LOJ+AIA->AIA_CODTAB))    
           While AIB->(!Eof()) .And. xFilial("AIB")+CA120FORN+CA120LOJ+AIA->AIA_CODTAB == AIB->(AIB_FILIAL+AIB_CODFOR+AIB_LOJFOR+AIB->AIB_CODTAB)
               If aCols[_nCols][nPProduto ] == AIB->AIB_CODPRO .And. AIB->AIB_MOEDA = nMoedaPed
                  aCols[_nCols][nPosTabPre] := AIB->AIB_CODTAB
                  aCols[_nCols][nPosPreco ] := AIB->AIB_PRCCOM   
                  aCols[_nCols][nPosPICM  ] := AIB->AIB_I_PICM
                  Exit
               EndIf
               AIB->(DBSkip())
           EndDo
           If !Empty(aCols[_nCols][nPosTabPre]) 
               If !Empty(AIA->AIA_CONDPG) .And. AIA->AIA_CONDPG <> cCondicao
                  cCondicao:= AIA->AIA_CONDPG// cCondicao VARIAVEL Private DA TELA PADRÃO DO PC
               EndIf           
               If !Empty(AIA->AIA_I_TPFR) .And. AIA->AIA_I_TPFR <> LEFT(cTpFrete,1)
                  cTpFrete :=RetTipoFrete(AIA->AIA_I_TPFR)// cTpFrete VARIAVEL Private DA TELA PADRÃO DO PC
               EndIf
               Exit
           EndIf           
         EndIf
      EndIf
      AIA->(DBSkip())
   EndDo
EndIf

cClaim := SC1->C1_I_CLAIM//CLAIM
cAplic := SC1->C1_I_APLIC
cUrgen := SC1->C1_I_URGEN
cCInve := SC1->C1_I_CDINV
cDsInv := Posicione("ZZI",1,xFilial("ZZI") + cCInve, "ZZI_DESINV")

FWRestArea(_aArea)

Return
