/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |18/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
Alex Wallauer |25/09/2025| Chamado 51698. Nova Validacao do campo C1_I_USOD contra C7_I_USOD.
Alex Wallauer |01/10/2025| Chamado 52300. Andre. Ajuste na Validacao do campo C1_I_USOD contra C7_I_USOD.
=====================================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MT120OK
Autor-------------: Darcio Ribeiro Sporl
Data da Criacao---: 07/10/2015
Descrição---------: Rotina responsavel pelas validações dos campos que estão no cabeçalho do pedido de compras.
                    Localização: Function A120TudOk() responsável pela validação de todos os itens da GetDados do Pedido de
                    Compras / Autorização de Entrega.
                    Em que Ponto: O ponto se encontra no final da função e é disparado após a confirmação dos itens da getdados
                    e antes do rodapé da dialog do PC, deve ser utilizado para validações especificas do usuario onde será
                    controlada pelo retorno do ponto de entrada oqual se For .F. o processo será interrompido e se .T. será validado.
Parametros--------: Nenhum
Retorno-----------: lRet -> Se .T. linha validada segue o processo, Se .F. interrompe o processo
===============================================================================================================================
*/
User Function MT120OK() As Logical

Local aArea       := FWGetArea() As Array
Local lRet        := .T. As Logic
Local _lRet2      := .T. As Logic
Local aMensagem   := {} As Array
Local aProbl      := {} As Array
Local aSoluc      := {} As Array
Local aProblList  := {} As Array
Local nX          := 0 As Numeric
Local nI          := 0 As Numeric
Local x           := 0 As Numeric
Local nPosCLA     := aScan(aHeader, {|x| AllTrim(x[2]) == "C7_I_CLAIM"}) As Numeric
Local nPosApl     := aScan(aHeader, {|x| AllTrim(x[2]) == "C7_I_APLIC"}) As Numeric
Local nPosInv     := aScan(aHeader, {|x| AllTrim(x[2]) == "C7_I_CDINV"}) As Numeric
Local nPosUrg     := aScan(aHeader, {|x| AllTrim(x[2]) == "C7_I_URGEN"}) As Numeric
Local nPosNsc     := aScan(aHeader, {|x| AllTrim(x[2]) == "C7_NUMSC"}) As Numeric
Local nPosISC     := aScan(aHeader, {|x| AllTrim(x[2]) == "C7_ITEMSC"}) As Numeric
Local nPosDTPRF   := aScan(aHeader, {|x| AllTrim(x[2]) == "C7_DATPRF"}) As Numeric
Local nPosObs     := aScan(aHeader, {|x| AllTrim(x[2]) == "C7_OBS"}) As Numeric
Local _nPosNomFo  := aScan(aHeader, {|x| AllTrim(x[2]) == "C7_I_NFORN"}) As Numeric
Local _nC7QUANT   := aScan(aHeader, {|x| AllTrim(x[2]) == "C7_QUANT"}) As Numeric
Local _nC7SEGUM   := aScan(aHeader, {|x| AllTrim(x[2]) == "C7_QTSEGUM"}) As Numeric
Local _nC7ITEM    := aScan(aHeader, {|x| AllTrim(x[2]) == "C7_ITEM"}) As Numeric
Local _nPa        := aScan(aHeader, {|x| AllTrim(x[2]) == "C7_PRODUTO"}) As Numeric
Local _nPosdescd  := aScan(aHeader, {|x| AllTrim(x[2]) == "C7_I_DESCD"}) As Numeric
Local _nPosUsod   := aScan(aHeader, {|x| AllTrim(x[2]) == "C7_I_USOD"}) As Numeric
Local _nPosCDINV  := aScan(aHeader, {|x| AllTrim(x[2]) == "C7_I_CDINV"}) As Numeric
Local _nPosDSINV  := aScan(aHeader, {|x| AllTrim(x[2]) == "C7_I_DSINV"}) As Numeric
Local _nPosSUBIN  := aScan(aHeader, {|x| AllTrim(x[2]) == "C7_I_SUBIN"}) As Numeric
Local _nPosSUIND  := aScan(aHeader, {|x| AllTrim(x[2]) == "C7_I_SUIND"}) As Numeric
Local _nPosDtFat  := aScan(aHeader, {|x| AllTrim(x[2]) == "C7_I_DTFAT"}) As Numeric
Local _nPosTabPre := aScan(aHeader, {|x| AllTrim(x[2]) == "C7_CODTAB"}) As Numeric
Local _nPosPreco  := aScan(aHeader, {|x| AllTrim(x[2]) == "C7_PRECO"}) As Numeric
Local _nSegu      := aScan(aHeader, {|x| AllTrim(x[2]) == "C7_SEGUM"}) As Numeric
Local _nPosC7PICM := aScan(aHeader, {|x| AllTrim(x[2]) == "C7_PICM"}) As Numeric
Local _nPosC7IPI  := aScan(aHeader, {|x| AllTrim(x[2]) == "C7_IPI"}) As Numeric
Local _nPosQtd    := aScan(aHeader, {|x| AllTrim(x[2]) == "C7_QUANT"}) As Numeric
Local _nI         := 0 As Numeric
Local _cProds     := "" As Character
Local _cGrpLeite  := SuperGetMV("IT_GRPFLEI",.F.,"000008,000009,000010,000011") As Character
Local _cPCGERAL   := SuperGetMV("IT_PCGERAL",.F.," ") As Character
Local _cUM_NO_Fracionada := SuperGetMV("IT_UMNOFRAC",.F.,"PC,UN") As Character
Local _lValidFrac1UM := .T. As Logic
Local _cTipos     := SuperGetMV("IT_TPPRDPC",.F.,"MP;PP;PI;SP") As Character
Local _cIT_PRDSVOK := SUPERGETMV("IT_PRDSVOK",.F.,"") As Character
Local _aAreaSc7   := {} As Array
Local aDifItens   := {} As Array

//Força atualização de campos C7_I_DESCD

For _nI := 1 To Len(acols)
   aCols[_nI,_nPosdescd] := Posicione("SB1",1,xFilial("SB1")+AllTrim(acols[_nI,_nPa]),"B1_I_DESCD")
Next
 
If Empty(cAplic)
   aProbl := {}
   aAdd(aProbl, "O campo Aplicação deve ser informado.")
   aSoluc := {}
   aAdd(aSoluc, "Favor informar uma Aplicação válida.")
   aMensagem := {"Aplicação Obrigatória", aProbl, aSoluc}
   U_ITMsHTML(aMensagem)
   lRet := .F.
EndIf

If cAplic == "I" .And. Empty(cCInve)
   aProbl := {}
   aAdd(aProbl, "O campo Investimento deve ser informado.")
   aSoluc := {}
   aAdd(aSoluc, "Para Aplicação do tipo Investimento, o campo Código do Investimento deve ser preenchido.")
   aMensagem := {"Investimento Obrigatório", aProbl, aSoluc}
   U_ITMsHTML(aMensagem)
   lRet := .F.
EndIf

If Empty(cTpFrete)
   aProbl := {}
   aAdd(aProbl, "O campo Tipo de Frete deve ser informado.")
   aSoluc := {}
   aAdd(aSoluc, "Favor preencher o campo de Tipo de Frete na Pasta Frete/Despesas.")
   aMensagem := {"Tipo de Frete Obrigatório", aProbl, aSoluc}
   U_ITMsHTML(aMensagem)
   lRet := .F.
EndIf

If Empty(cUrgen)
   aProbl := {}
   aAdd(aProbl, "O campo Urgência deve ser informado.")
   aSoluc := {}
   aAdd(aSoluc, "Favor informar uma opção válida.")
   aMensagem := {"Urgência Obrigatória", aProbl, aSoluc}
   U_ITMsHTML(aMensagem)
   lRet := .F.
EndIf

If Empty(cCompD)
   aProbl := {}
   aAdd(aProbl, "O campo Compra Direta deve ser informado.")
   aSoluc := {}
   aAdd(aSoluc, "Favor informar uma opção válida.")
   aMensagem := {"Compra Direta Obrigatório", aProbl, aSoluc}
   U_ITMsHTML(aMensagem)
   lRet := .F.
Else
   If cCompD = "S" .And. cUrgen <> "S"
      U_ITMsg("Campo urgente dever esta igual a SIM quando For compra direta igual a SIM",'Atenção!',,1)
      lRet := .F.
   EndIf
EndIf

If !Empty(cContato)
   cContato:=LimpaString(cContato)
   If Empty(cContato)
      cContato:="."
   EndIf
EndIf

ZZL->( DBSetOrder(3) )
If ZZL->( DBSeek( xFilial("ZZL") + RetCodUsr() ) )
   If ZZL->ZZL_PEFRPA == "S"  .Or. ZZL->ZZL_PEFROU == "S"
      _lValidFrac1UM:=.F.
   EndIf
EndIf
ZZL->(DBSetOrder(1))
AIA->(DBSetOrder(1))//AIA_FILIAL+AIA_CODFOR+AIA_LOJFOR+AIA_CODTAB
AIB->(DBSetOrder(2))//AIB_FILIAL+AIB_CODFOR+AIB_LOJFOR+AIB_CODTAB+AIB_CODPRO
SBZ->(DBSetOrder(1))//BZ_FILIAL+BZ_COD

_lValTabPreco:=.T.
_lDifTabPreco:=.F.
_lMenTabPreco:=.F.
For nX := 1 To Len(aCols)
   If !aCols[nX][Len(aHeader)+1]//NÃO DELETADOS
      If !Empty(aCols[nX][nPosObs])
         aCols[nX][nPosObs]:=LimpaString(aCols[nX][nPosObs])
      EndIf

      //**************** AIA ****************************//
      If Empty(aCols[nX][_nPosTabPre])
         _lValTabPreco:=.F.
      ElseIf AIA->(DBSeek(xFilial("AIA")+CA120FORN+CA120LOJ+aCols[nX][_nPosTabPre]))
         If SubStr(cTpFrete,1,1) <> AIA->AIA_I_TPFR
            aAdd(aProblList,{ aCols[nX,_nC7ITEM] , aCols[nX,_nPa] , "Tipo de Frete do PC : "+cTpFrete+", difere do Tipo de Frete: "+RetTipoFrete(AIA->AIA_I_TPFR)+" + da Tabela de Preços: "+aCols[nX][_nPosTabPre] , "Redigite o Item para recarregar o Tipo de Frete da tabela de preços." })
            _lDifTabPreco:=.T.
         ElseIf U_ACOM36Cond(.F.)//Se alterou a condição de pagamanto/Tipo de Frete  do gatilho do produto(ACOM036.PRW)
            _lMenTabPreco:=.T.
         EndIf

         If cCondicao <> AIA->AIA_CONDPG
            aAdd(aProblList,{ aCols[nX,_nC7ITEM] , aCols[nX,_nPa] , "Condição de Pagamento  do PC : "+cCondicao+", difere da Cond. Pagtp.: "+AIA->AIA_CONDPG+" + da Tabela de Preços: "+aCols[nX][_nPosTabPre] , "Redigite o Item para recarregar a condicao de Pagamento da tabela de preços." })
            _lDifTabPreco:=.T.
         ElseIf U_ACOM36Cond(.F.)//Se alterou a condição de pagamanto/Tipo de Frete do gatilho do produto(ACOM036.PRW)
            _lMenTabPreco:=.T.
         EndIf

         If !(AIA->AIA_DATDE <= Date() .And.  AIA->AIA_DATATE >= Date() .And. AIA->AIA_I_SITW = "A")// NÃO TIVER DENTRO DA VIGENCIA E APROVADA
            aAdd(aProblList,{ aCols[nX,_nC7ITEM] , aCols[nX,_nPa] , "Tabela de Preços: "+aCols[nX][_nPosTabPre]+" do item invalida: Vigencia de "+AIA->AIA_DATDE+" ate "+AIA->AIA_DATATE+", Status: "+AIA->AIA_I_SITW, "Redigite o Item para recarregar uma tabela de preços valida." })
            lRet := .F.
         EndIf
                           //AIB_FILIAL+AIB_CODFOR+AIB_LOJFOR+AIB_CODTAB+AIB_CODPRO
         If AIB->(DBSeek(AIA->(AIA_FILIAL+AIA_CODFOR+AIA_LOJFOR+AIA_CODTAB+AllTrim(aCols[nX,_nPa]))))
            If aCols[nX][_nPosPreco] <> AIB->AIB_PRCCOM
               aAdd(aProblList,{ aCols[nX,_nC7ITEM] , aCols[nX,_nPa] , "Preço do item invalido: O preço diverge da tabela de preços que esta com "+AllTrim(Transform(AIB->AIB_PRCCOM, PesqPict("AIB","AIB_PRCCOM"))), "Redigite o Item para recarregar o preço da tabela de preços: "+AIA->AIA_CODTAB })
               lRet := .F.
            EndIf
            If aCols[nX][_nPosC7PICM] <> AIB->AIB_I_PICM
               aAdd(aProblList,{ aCols[nX,_nC7ITEM] , aCols[nX,_nPa] , "Aliquota de ICMS do item invalido: a aliquota diverge da tabela de preços que esta com "+AllTrim(Transform(AIB->AIB_I_PICM, PesqPict("AIB","AIB_I_PICM")))+"%", "Redigite o Item para recarregar a aliquota da tabela de preços: "+AIA->AIA_CODTAB })
               lRet := .F.
            EndIf
         EndIf
      Else//If AIA->(DBSeek(xFilial("AIA")+CA120FORN+CA120LOJ+aCols[nX][_nPosTabPre]))
         aAdd(aProblList,{ aCols[nX,_nC7ITEM] , aCols[nX,_nPa] , "Não existe a Tabela de preço "+aCols[nX][_nPosTabPre]+" correspondente ao fornecedor digitado.", "Redigite os Itens para recarregar a tabela de preços correspondente ao fornecedor digitado."})
         lRet := .F.
      EndIf
      //**************** AIA ****************************//

      //***************** C7_NUMSC VALIDACAO DE DADOS DA CAPA DA SC *********************//
      If !Empty(aCols[nX][nPosNsc])//C7_NUMSC
         For nI := 1 To Len(aCols)
               If !aCols[nI][Len(aHeader)+1]
                  If !Empty(aCols[nI][nPosNsc])//C7_NUMSC
                     //Valida Aplicação
                     If aCols[nI][nPosApl] <> aCols[nX][nPosApl]
                           aAdd(aProblList,{ aCols[nI,_nC7ITEM] , aCols[nI,_nPa] , "Foram selecionadas Solicitações com Aplicações divergentes." , "Somente serão aceitas Solicitações com o mesmo tipo de Aplicação." })
                           lRet := .F.
                     EndIf
                     //Valida Investimento
                     If aCols[nI][nPosInv] <> aCols[nX][nPosInv]
                           aAdd(aProblList,{ aCols[nI,_nC7ITEM] , aCols[nI,_nPa]  , "Foram selecionadas Solicitações com Investimentos divergentes." , "Somente serão aceitas Solicitações com o mesmo tipo de Investimento." })
                           lRet := .F.
                     EndIf
                     //Valida Urgência
                     If aCols[nI][nPosUrg] <> aCols[nX][nPosUrg]
                           aAdd(aProblList,{ aCols[nI,_nC7ITEM] , aCols[nI,_nPa]  , "Foram selecionadas Solicitações com Urgências divergentes." , "Somente serão aceitas Solicitações com a mesma Urgência." })
                           lRet := .F.
                     EndIf

                     //Valida CLAIM
                     If aCols[nI][nPosCLA] <> aCols[nX][nPosCLA]
                           aAdd(aProblList,{ aCols[nI,_nC7ITEM] , aCols[nI,_nPa]  , "Foram selecionadas Solicitações com CLAIM divergentes." , "Somente serão aceitas Solicitações com a mesmo CLAIM." })
                           lRet := .F.
                     EndIf
                  EndIf
               EndIf
         Next nI

         If !Empty(aCols[nX][nPosCLA]) .And. aCols[nX][nPosCLA] <> cClaim
               aAdd(aProblList,{ aCols[nX,_nC7ITEM] , aCols[nX,_nPa] , "CLAIM selecionada no cabeçalho, diverge da Aplicação do Item." , "Somente serão aceitas Solicitações com o mesmo tipo de CLAIM." })
               lRet := .F.
         EndIf

         If !Empty(aCols[nX][nPosApl]) .And. aCols[nX][nPosApl] <> cAplic
               aAdd(aProblList,{ aCols[nX,_nC7ITEM] , aCols[nX,_nPa] , "A Aplicação selecionada no cabeçalho, diverge da Aplicação do Item." , "Somente serão aceitas Solicitações com o mesmo tipo de Aplicação." })
               lRet := .F.
         EndIf
         If !Empty(aCols[nX][nPosInv]) .And. aCols[nX][nPosInv] <> cCInve
               aAdd(aProblList,{ aCols[nX,_nC7ITEM] , aCols[nX,_nPa] , "O Investimento informado no cabeçalho, diverge do Investimento do Item." ,  "Somente serão aceitas Solicitações com o mesmo tipo de Investimento." })
               lRet := .F.
         EndIf
         If !Empty(aCols[nX][nPosUrg]) .And. aCols[nX][nPosUrg] <> cUrgen
               aAdd(aProblList,{ aCols[nX,_nC7ITEM] , aCols[nX,_nPa] , "A Urgência informada no cabeçalho, diverge da Urgência do Item." , "Somente serão aceitas Solicitações com a mesma Urgência." })
               lRet := .F.
         EndIf
         If lRet .And. !Empty(aCols[nX][_nPosNomFo])
            aCols[nX,_nPosNomFo]:= AllTrim(Posicione("SA2",1,xFilial("SA2") + cA120Forn + cA120Loj,"SA2->A2_NOME") )
         EndIf
      EndIf//!Empty(aCols[nX][nPosNsc]) - C7_NUMSC
      //***************** C7_NUMSC VALIDACAO DE DADOS DA CAPA DA SC *********************//

      SBZ->(DBSeek(xFilial("SBZ")+AllTrim(aCols[nX,_nPa])))
      If  SBZ->BZ_I_VLDTP = "S" .And. Empty(aCols[nX][_nPosTabPre])
         aAdd(aProblList,{ aCols[nX,_nC7ITEM] , aCols[nX,_nPa] , "Produto sem tabela de preços preenchida.", "Para esse produto é obrigatorio ter tabela de preço." })
         lRet := .F.
      EndIf

      If _lValidFrac1UM
         SB1->(DBSeek(xFilial("SB1") + AllTrim(aCols[nX,_nPa])))
         If  SB1->B1_UM $ _cUM_NO_Fracionada
               If aCols[nX,_nC7QUANT] <> Int(aCols[nX,_nC7QUANT])
                  _lRet2 := .F.
                  _cProds+="Item: " + aCols[nX,_nC7ITEM]+" Prod.: " + AllTrim(aCols[nX,_nPa])+" - 1aUM: "+SB1->B1_UM+" - 2aUM: "+SB1->B1_SEGUM + CHR(13)+CHR(10)
               EndIf
         EndIf

         If  SB1->B1_SEGUM $ _cUM_NO_Fracionada
               If aCols[nX,_nC7SEGUM] <> Int(aCols[nX,_nC7SEGUM])
                  _lRet2 := .F.
                  _cProds+="Item: " + aCols[nX,_nC7ITEM] +" Prod.: " + AllTrim(aCols[nX,_nPa])+" - 1aUM: "+SB1->B1_UM+" - 2aUM: "+SB1->B1_SEGUM + CHR(13)+CHR(10)
               EndIf
         EndIf
      EndIf

      If Altera
         _aAreaSC7 := SC7->(GetArea())
         SC7->( DBSetOrder(1) )
         If SC7->( DBSeek( xFilial("SC7") + SC7->C7_NUM + aCols[nX,_nC7ITEM] ) )
            SC1->( DBSetOrder(1) )
            If SC1->( DBSeek( xFilial("SC1") + aCols[nX,nPosNsc] + aCols[nX,nPosIsc] ) )
               //VALIDAÇÃO DA APLICAÇÃO DIRETA DOS ITENS CONTRA OS ITENS SC
               If SC1->C1_I_USOD <> aCols[nX][_nPosUsod] 
                  aAdd(aProblList,{ aCols[nX,_nC7ITEM] , aCols[nX,_nPa] , "O conteudo do campo Ap Direta informado no Item, diverge do conteudo da Ap Direta na SC que esta com ("+SC1->C1_I_USOD+").","Redigite o Item para recarregar o Ap Direta da SC correto." })
                  lRet:=.F.
               EndIf//VALIDAÇÃO DA APLICAÇÃO DIRETA DOS ITENS CONTRA OS ITENS SC
               
               If SC1->C1_DATPRF <> aCols[nX,nPosDTPRF] .And. aCols[nX,nPosDTPRF] <> SC7->C7_DATPRF
                  aAdd(aDifItens,{"DATA",aCols[nX,_nC7ITEM],SC1->C1_QTDORIG,SC1->C1_DATPRF,SC7->C7_DATPRF})//PARA O E-MAIL , NÃO É VALIDACAO
               EndIf
               If SC1->C1_QTDORIG <> aCols[nX,_nPosQtd] .And. aCols[nX,_nPosQtd] <> SC7->C7_QUANT
                  aAdd(aDifItens,{"QTD",aCols[nX,_nC7ITEM],SC1->C1_QTDORIG,SC1->C1_DATPRF,SC7->C7_QUANT})//PARA O E-MAIL , NÃO É VALIDACAO
               EndIf
            EndIf
         EndIf
         RestArea(_aAreaSC7)

      ElseIf Inclui
         SC1->( DBSetOrder(1) )
         If SC1->( DBSeek( xFilial("SC1") + aCols[nX,nPosNsc] + aCols[nX,nPosIsc] ) )
               If SC1->C1_DATPRF <> aCols[nX,nPosDTPRF]
                  aAdd(aDifItens,{"DATA",aCols[nX,_nC7ITEM],SC1->C1_QTDORIG,SC1->C1_DATPRF,CTOD("")})//PARA O E-MAIL , NÃO É VALIDACAO
               EndIf
               If SC1->C1_QTDORIG <> aCols[nX,_nPosQtd]
                  aAdd(aDifItens,{"QTD",aCols[nX,_nC7ITEM],SC1->C1_QTDORIG,SC1->C1_DATPRF,0})//PARA O E-MAIL , NÃO É VALIDACAO
               EndIf
               //VALIDAÇÃO APLICAÇÃO DIRETA DOS ITENS CONTRA OS ITENS SC
               If SC1->C1_I_USOD <> aCols[nX][_nPosUsod]
                  aAdd(aProblList,{ aCols[nX,_nC7ITEM] , aCols[nX,_nPa] , "O conteudo do campo Ap Direta informado no Item, diverge do conteudo da Ap Direta na SC que esta com ("+SC1->C1_I_USOD+").","Redigite o Item para recarregar o Ap Direta da SC correto." })
                  lRet:=.F.
               EndIf
               //VALIDAÇÃO APLICAÇÃO DIRETA DOS ITENS CONTRA OS ITENS SC
         EndIf
      Else
         aDifItens := {}
      EndIf
   EndIf//!aCols[nX][Len(aHeader)+1] - IF DOS NÃO DELETADOS
Next nX

If _lValidFrac1UM .And. !_lRet2
   U_ITMsg("Não é permitido fracionar a quantidade da 1a. ou 2a. UM de produto onde a UM For "+_cUM_NO_Fracionada+". Clique em mais detalhes",;//,_ntipo,_nbotao,_nmenbot,_lHelpMvc,_cbt1,_cbt2,_bMaisDetalhes
            "Validação Fracionado","Favor informar apenas quantidades inteiras onde a UM For "+_cUM_NO_Fracionada+".",1     ,       ,        ,         ,     ,     ,;
            {|| Aviso("Validação Fracionado",_cProds,{"Fechar"}) } )
   lRet:=.F.
EndIf

If _lValTabPreco .And. _lDifTabPreco//Se tem que validar e tem condições diferentes não deixa grava o Pedido
   lRet:=.F.
EndIf

SY1->(DBSetOrder(3))//Y1_USER
For X := 1 To Len(aCols)
   If aCols[X][Len(aHeader)+1]//DELETADOS
      Loop
   EndIf

   _cSegu	    := acols[x][_nSegu]
   _cproduto	:= acols[x][_nPa]
   _nquant		:= acols[x][_nC7SEGUM]	//M->C7_QTSEGUM
   _cGrupo     := Posicione("SB1",1,xFilial("SB1")+AllTrim(_cproduto),"B1_GRUPO")
   _nConv      := SB1->B1_CONV

   If !Empty(aCols[X,_nPosC7PICM]) .And. SB1->B1_TIPO = "SV" .And. !AllTrim(SB1->B1_COD) $ _cIT_PRDSVOK
      aAdd(aProblList,{ aCols[X,_nC7ITEM] , aCols[X,_nPa] , "Aliquota de ICMS não pode ser preenchida para o produto de tipo 'SV'", "Zere Aliquota de ICMS desse produto."})
      lRet := .F.
   EndIf
   If !Empty(aCols[X,_nPosC7IPI]) .And. SB1->B1_TIPO = "SV" .And. !AllTrim(SB1->B1_COD) $ _cIT_PRDSVOK
      aAdd(aProblList,{ aCols[X,_nC7ITEM] , aCols[X,_nPa] , "Aliquota de IPI não pode ser preenchida para o produto de tipo 'SV'", "Zere Aliquota de IPI desse produto."})
      lRet := .F.
   EndIf

   If !SB1->B1_TIPO $ _cTipos
      SY1->(DBSeek(xFilial("SY1") + AllTrim(__cUserId)))
      If !SY1->Y1_COD $ _cPCGERAL .And. SY1->Y1_GRUPCOM $ _cGrpLeite
         aAdd(aProblList,{ aCols[X,_nC7ITEM] , aCols[X,_nPa] ,'Comprador habilitado somente para comprar tipos de produto "'+_cTipos+'"','Remova os produto com tipo diferente de "'+_cTipos+'" da lista.'})
         lRet := .F.
      EndIf
   Else//If SB1->B1_TIPO $ "MP,PP,PI"
      SY1->(DBSeek(xFilial("SY1") + AllTrim(__cUserId)))
      If !SY1->Y1_COD $ _cPCGERAL .And. !SY1->Y1_GRUPCOM $ _cGrpLeite
         aAdd(aProblList,{ aCols[X,_nC7ITEM] , aCols[X,_nPa] ,'Comprador não habilitado para comprar tipos de produto "'+_cTipos+'"','Remova os produto com tipo igual a "'+_cTipos+'" da lista.'})
         lRet := .F.
      EndIf
   EndIf

   If Empty(aCols[X,_nPosDtFat]) .And. !SY1->Y1_GRUPCOM $ _cGrpLeite
      aAdd(aProblList,{ aCols[X,_nC7ITEM] , aCols[X,_nPa] ,'Data de fataturamento não preenchida.','Preencha a data de Faturamento desse item e dos outros.'})
      lRet := .F.
   EndIf

   If (!Empty(_cSegu) .Or. _nquant > 0) .And. _nConv == 0 .And. !(AllTrim(_cGrupo) $ AllTrim(SuperGetMV("IT_GRP2U",.T.,"0006")))
      aAdd(aProblList,{ aCols[X,_nC7ITEM] , aCols[X,_nPa] ,"Item não tem fator de conversão cadastrado.","Impossível usar segunda unidade medida."})
      lRet := .F.
   EndIf

   If (Empty(_cSegu) .Or. _nquant = 0) .And. _nConv <> 0
      aAdd(aProblList,{ aCols[X,_nC7ITEM] , aCols[X,_nPa] ,"Item tem fator de conversão cadastrado.","Obrigatorio usar segunda unidade medida."})
      lRet := .F.
   EndIf

   If  aCols[X][_nPosUsod] <> "S" .And. cCompD = "S" .And. cAplic != "S"
      aAdd(aProblList,{ aCols[X,_nC7ITEM] , aCols[X,_nPa] , "Campo Ap Direta do Item dever esta igual a SIM quando For compra direta igual a SIM." , "Somente serão aceitas Solicitações com Ap Direta igual a SIM." })
      lRet := .F.
   EndIf
Next X

For nX := 1 To Len(aCols)
   If aCols[nX][Len(aHeader)+1]//DELETADOS
      Loop
   EndIf
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
               aAdd(aProblList,{ aCols[nX,_nC7ITEM] , aCols[nX,_nPa] ,'Campo de Subinvestimento não Preenchido!',''})
               lRet := .F.
         EndIf
      Else
         ZZI->(DBSetOrder(1))//ZZI_FILIAL+ZZI_INVPAI+ZZI_TIPO
         If ZZI->(DBSeek(xFilial("ZZI")+aCols[nX,_nPosSUBIN ]))
               If ZZI->ZZI_INVPAI <> cCInve
                  aAdd(aProblList,{ aCols[nX,_nC7ITEM] , aCols[nX,_nPa] ,'Campo de Subinvestimento da linha '+AllTrim(Str(nX))+' não corresponde ao projeto!','Mofifique o campo selecionando um os dos itens da consulta.'})
                  lRet := .F.
               Else
                  If ZZI->ZZI_TIPO == "2"
                     ZZI->(DBSetOrder(3))//ZZI_FILIAL+ZZI_INVPAI+ZZI_TIPO
                     If ZZI->(DBSeek(xFilial("ZZI")+cCInve+"3"))
                           aAdd(aProblList,{ aCols[nX,_nC7ITEM] , aCols[nX,_nPa] ,'No Campo de Subinvestimento da linha '+AllTrim(Str(nX))+' é obrigatório um Investimento de nivel 3 !','Mofifique o campo selecionando um Investimento de nivel 3 da consulta.'})
                           lRet := .F.
                     EndIf
                  EndIf
               EndIf
         EndIf
      EndIf
   Next nX
EndIf

If !lRet .And. Len(aProblList) > 0
//                                                                                      , _aCols     ,_lMaxSiz,_nTipo,_cMsgTop, _lSelUnc ,_aSizes , _nCampo , bOk , bCancel, _abuttons )
   U_ITListBox( 'Relação de Itens com problemas', {'Item','Produto','Problema',"Solucao"} , aProblList , .T.    , 1    ,        ,          ,;
                                                {10,   ,100      ,200       ,200      }  )
ElseIf _lMenTabPreco
   U_ACOM36Cond(.T.)//volta a variavel _lAlterou para .F. do gatilho do produto (ACOM036.PRW)
EndIf

//Função esta no MT120FIM.PRW
U_MT120VA(aDifItens)//aDifItens Array usada na função U_MCOM004Z(_cFilial,_cNumPc,aDifItens,_lInclui,_lWF) - Envio e email na inclusão ou alteração do pedido de compra

FWRestArea(aArea)

Return(lRet)

/*
===============================================================================================================================
Programa--------: LimpaString()
Autor-----------: Alex Walaluer
Data da Criacao-: 20/10/2017
Descrição-------: Tira os caracteres "estranos"
Parametros------: cString: String
Retorno---------: cString: String
===============================================================================================================================
*/
Static Function LimpaString(cString As Character) As Character

cString:=StrTran(cString,'¨'," ")
cString:=StrTran(cString,'?'," ")
cString:=StrTran(cString,'^'," ")
cString:=StrTran(cString,'~'," ")
cString:=StrTran(cString,'"'," ")
cString:=StrTran(cString,"’"," ")
cString:=StrTran(cString,"´"," ")
cString:=StrTran(cString,"'"," ")
cString:=StrTran(cString,"`"," ")
cString:=StrTran(cString,"–"," ")
cString:=StrTran(cString,"!"," ")
cString:=StrTran(cString,"Ã?","E")
cString:=StrTran(cString,"Ã^","E")
cString:=StrTran(cString,"á","a")
cString:=StrTran(cString,"Á","A")
cString:=StrTran(cString,"à","a")
cString:=StrTran(cString,"À","A")
cString:=StrTran(cString,"ã","a")
cString:=StrTran(cString,"Ã","A")
cString:=StrTran(cString,"â","a")
cString:=StrTran(cString,"Â","A")
cString:=StrTran(cString,"ä","a")
cString:=StrTran(cString,"Ä","A")
cString:=StrTran(cString,"é","e")
cString:=StrTran(cString,"É","E")
cString:=StrTran(cString,"ë","e")
cString:=StrTran(cString,"Ë","E")
cString:=StrTran(cString,"ê","e")
cString:=StrTran(cString,"Ê","E")
cString:=StrTran(cString,"í","i")
cString:=StrTran(cString,"Í","I")
cString:=StrTran(cString,"ï","i")
cString:=StrTran(cString,"Ï","I")
cString:=StrTran(cString,"î","i")
cString:=StrTran(cString,"Î","I")
cString:=StrTran(cString,"ý","y")
cString:=StrTran(cString,"Ý","y")
cString:=StrTran(cString,"ÿ","y")
cString:=StrTran(cString,"ó","o")
cString:=StrTran(cString,"Ó","O")
cString:=StrTran(cString,"õ","o")
cString:=StrTran(cString,"Õ","O")
cString:=StrTran(cString,"ö","o")
cString:=StrTran(cString,"Ö","O")
cString:=StrTran(cString,"ô","o")
cString:=StrTran(cString,"Ô","O")
cString:=StrTran(cString,"ò","o")
cString:=StrTran(cString,"Ò","O")
cString:=StrTran(cString,"ú","u")
cString:=StrTran(cString,"Ú","U")
cString:=StrTran(cString,"ù","u")
cString:=StrTran(cString,"Ù","U")
cString:=StrTran(cString,"ü","u")
cString:=StrTran(cString,"Ü","U")
cString:=StrTran(cString,"ç","c")
cString:=StrTran(cString,"Ç","C")
cString:=StrTran(cString,"º","o")
cString:=StrTran(cString,"°","o")
cString:=StrTran(cString,"ª","a")
cString:=StrTran(cString,"ñ","n")
cString:=StrTran(cString,"Ñ","N")
cString:=StrTran(cString,"²","2")
cString:=StrTran(cString,"³","3")
cString:=StrTran(cString,"§","S")
cString:=StrTran(cString,"±","+")
cString:=StrTran(cString,"­","-")
cString:=StrTran(cString,"o","o")
cString:=StrTran(cString,"µ","u")
cString:=StrTran(cString,"¼","1/4")
cString:=StrTran(cString,"½","1/2")
cString:=StrTran(cString,"¾","3/4")
cString:=StrTran(cString,"&","e")
cString:=StrTran(cString,";",",")
cString:=StrTran(cString,"¡","i")
cString:=StrTran(cString,"©","c.")
cString:=StrTran(cString,"®","r.")
cString:=StrTran(cString,"£","L")
cString:=StrTran(cString,"‡","t")
cString:=StrTran(cString,"ƒ","f")
cString:=StrTran(cString,"×","x")

Return cString
