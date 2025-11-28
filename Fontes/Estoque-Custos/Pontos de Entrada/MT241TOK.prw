/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz     |26/08/2024| Chamado 48278. Alterar validação usuário p/não validar usuários: alteração unid.medida/fator Conv.
Lucas Borges  |19/09/2024| Chamado 48569. Incluir a rotina de Desconto Tetra Pak nas exceções para validação de acesso
Lucas Borges  |19/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: MT241TOK
Autor-----------: Heder Jose Andrade 
Data da Criacao-: 11/08/2010 
Descrição-------: Ponto de Entrada que valida movimento interno modelo II
                  Valida a obrigatoriedade do preenchimento da segunda unidade de medida quando os produtos pertence ao
                  grupo de produto 0006(Queijo) para controle de estoque de pecas de queijo.
Parametros------: Nenhum
Retorno---------: .T. = Permite confirmar lancamento / .F. = Nao Permite confirmar lancamento
===============================================================================================================================
*/
User Function MT241TOK

Local _aArea      := FWGetArea()
Local _aAreaZZL   := ZZL->(FWGetArea())
Local _aAreaSB1   := SB1->(FWGetArea())
Local _aAreaSCP   := SCP->(FWGetArea())
Local _nPosQtSeg  := aScan(aHeader,{|x| AllTrim(x[2])=="D3_QTSEGUM"})
Local _nPosQtd  	:= aScan(aHeader,{|x| AllTrim(x[2])=="D3_QUANT"})
Local _nPosCod  	:= aScan(aHeader,{|x| AllTrim(x[2])=="D3_COD"})
Local _nPosLocal  := aScan(aHeader,{|x| AllTrim(x[2])=="D3_LOCAL"})
Local _nPosNumSa	:= aScan(aHeader,{|x| AllTrim(x[2])=='D3_NUMSA'})
Local _nPosItem	:= aScan(aHeader,{|x| AllTrim(x[2])=='D3_ITEMSA'})
Local _nPosMotiv	:= aScan(aHeader,{|x| AllTrim(x[2])=='D3_I_MOTIV'})
Local _nPosObs    := aScan(aHeader,{|x| AllTrim(x[2])=='D3_I_OBS'})
Local _cUMNoFrac  := SuperGetMV("IT_UMNOFRAC",.F.,"PC,UN")
Local _cArmazens  := SuperGetMV('IT_ARMCPR',.F.,"02,04")
Local  cTipo  	   := SuperGetMV("IT_TPMOV",.F., "")
Local _lRet 	   := 	.T.
Local _cDados	   := {}
Local _cMensagem	:= ""
Local _aSldNeg  	:= {}
Local _nI         := 0
Local _nX         := 0
Local _lVldFr1UM  := .T.
Local _cProd1s    := ""
Local _cProd2s    := ""

//================================================================ 
// Quando as validações forem alterações do fator de conversão
// ou mudança de unidade de medida do cadastro de produtos,
// e esta rotina For chamada via execauto. Não validar as
// permissões de acesso.
//================================================================
If SuperGetMV("IT_BLQMOV",.F., "") .And. dA241Data > Date()
   FWAlertWarning("Os movimentos com data maior que a data atual estão bloqueados. Entre em contato com o departamento de TI para maiores informações.","MT241TOK01")
   _lRet := .F.
ElseIf !(FWIsInCallStack("DESCTETRAE") .Or. FWIsInCallStack("DESCTETRAE") .Or. FWIsInCallStack("U_AGLT003G") .Or. FWIsInCallStack("MATA103");
   .Or. ((cTm == "997" .Or. cTm == "998") .And. (ISINCALLSTACK("U_A010TOK") .Or. ISINCALLSTACK("A010CadSB1"))))
   ZZL->(DBSetOrder(3))
   If ZZL->ZZL_PEFRPA == "S"  .Or. ZZL->ZZL_PEFROU == "S"
      _lVldFr1UM:=.F.
   EndIf

   If ZZL->(DBSeek(xFilial("ZZL")+RetCodUsr()))
      If ZZL->ZZL_AUMMUL <> 'S'
         FWAlertWarning("Usuário sem permissão para realizar movimentação multipla. Não será possível realizar a movimentação. Entre em contato com o suporte do TI.","MT241TOK02")
         _lRet := .F.
      ElseIf !(cTm $ ZZL->ZZL_TIPMOV)
         FWAlertWarning("Usuário sem permissão para utilizar este tipo de movimento. Não será possível realizar a movimentação. Tipos de Movimentos permitidos ao usuário: '"+AllTrim(ZZL->ZZL_TIPMOV)+"'.",;
                  "Entre em contato com o suporte do TI.","MT241TOK03")
         _lRet := .F.
      EndIf
   
      For _nI := 1 To Len(aCols)
         If aTail(aCols[_nI]) // Se Linha Deletada
            Loop
         EndIf
         If cTm >= "500" .And. (aCols[_nI,_nPosLocal] $ _cArmazens) .And. ZZL->ZZL_PERTRA <> "S"          //Se movimento de saída
            FWAlertWarning("Para o "+aCols[_nI,_nPosLocal]+" não é permitido a movimentação interna, somente tranferencia entre armazens. Armazens não permitidos: '"+AllTrim(_cArmazens)+"'.",;
                  "Realize a transferencia entre armazens ou entre em contato com o departamento de Custo.","MT241TOK04")
            _lRet := .F.
         ElseIf !(aCols[_nI,_nPosLocal] $ ZZL->ZZL_ARMAZE)
            FWAlertWarning("Usuário sem permissão para utilizar este armazem. Não será possível realizar a movimentação multipla. Armazens permitidos ao usuário: '"+AllTrim(ZZL->ZZL_ARMAZE)+"'.",;
                  "Entre em contato com o suporte do TI.","MT241TOK05")
            _lRet := .F.
         EndIf

         SB1->(DBSeek(xFilial("SB1") + AllTrim(aCols[_nI,_nPosCod])))
         If !(SB1->B1_TIPO $ ZZL->ZZL_TIPROD)
            FWAlertWarning("Usuário sem permissão para utilizar este Tipo de Produto ["+SB1->B1_TIPO+"]. Não será possível realizar a movimentação multipla. Tipos permitidos ao usuário: '"+AllTrim(ZZL->ZZL_TIPROD)+"'.",;
                  "Entre em contato com o suporte do TI.","MT241TOK06")
            _lRet := .F.
         EndIf

         If _lVldFr1UM 
            If SB1->B1_UM $ _cUMNoFrac
               If aCols[_nI,_nPosQtd] <> Int(aCols[_nI,_nPosQtd])
                  _cProd1s+="Prod.: " + AllTrim(aCols[_nI,_nPosCod])+" - 1aUM: "+SB1->B1_UM+" - 2aUM: "+SB1->B1_SEGUM+ " - " + Left(SB1->B1_DESC,25) + CHR(13)+CHR(10)
               EndIf
            EndIf
            If SB1->B1_SEGUM $ _cUMNoFrac
               If aCols[_nI,_nPosQtSeg] <> Int(aCols[_nI,_nPosQtSeg])
                  _cProd2s+="Prod.: " + AllTrim(aCols[_nI,_nPosCod])+" - 1aUM: "+SB1->B1_UM+" - 2aUM: "+SB1->B1_SEGUM+ " - " + Left(SB1->B1_DESC,25) + CHR(13)+CHR(10)
               EndIf
            EndIf
         EndIf
      Next _nI

      If _lVldFr1UM
         If !Empty(_cProd1s)
            FWAlertWarning("Não é permitido fracionar a quantidade da 1a. UM de produto onde a Unid. Medida For UN. Clique em mais detalhes",;
                     "Favor informar apenas quantidades inteiras na Primeira Unidade de Medida."+_cProd1s,"MT241TOK07")
            _lRet := .F.
         EndIf
         If !Empty(_cProd2s)
            FWAlertWarning("Não é permitido fracionar a quantidade da 2a. UM de produto do grupo 0006 onde a Unid. Medida For PC. Clique em mais detalhes",;
                     "Validação Fracionado","Favor informar apenas quantidades inteiras na Primeira Unidade de Medida."+_cProd1s,"MT241TOK08")
            _lRet := .F.
         EndIf
      EndIf
   Else
      FWAlertWarning("Usuário sem cadastro na ZZL. Entre em contato com o suporte do TI.","MT241TOK09")
      _lRet := .F.
   EndIf
EndIf

If aCols[n][Len(aHeader)+1] == .F. //Linha nao Deletada
   If SubStr(aCols[n,_nPosCod],1,4) == "0006" .And. aCols[n,_nPosQtSeg] == 0 .And.;
      !FWAlertYesNo("Segunda Unidade de Medida Vazia!"+Chr(13)+Chr(10)+Chr(13)+Chr(10)+"Produto: "+AllTrim(acols[n,_nPosCod])+Chr(13)+Chr(10)+Chr(13)+Chr(10)+"Deseja Continuar?","MT241TOK10")
      _lRet := .F.
   EndIf
EndIf

//Criado para impedir que seja feito lançamento de saída retroativo deixando o saldo negativo em alguma data posterior.
If _lRet .And. cTm >= "500"
   For _nI := 1 To Len(aCols)
      If aTail(aCols[_nI]) // Se Linha Deletada
         Loop
      EndIf
      _aSldNeg := U_VldEstRetrNeg(aCols[_nI,_nPosCod], aCols[_nI,_nPosLocal], aCols[_nI,_nPosQtd], dA241Data)//Varre os saldos de cada dia atá a data de hoje buscando por saldo insuficiente
      If Len(_aSldNeg) > 0
         _cMensagem += CRLF + "O produto " + aCols[_nI,_nPosCod] + "-" + aCols[_nI,_nPosLocal] + " não tem saldo suficiente em " + DToC(_aSldNeg[1]) + ". Saldo na data:" + TRANSFORM(_aSldNeg[2],"@E 999,999.99")
         _lRet:=.F.
         Exit
      EndIf
   Next _nI    
   If !_lRet
      FWAlertWarning("Não permitido. Verifique motivo abaixo: " + CRLF + _cMensagem,"MT241TOK11")
   EndIf
EndIf

If _lRet .And. ! IsInCallStack("MATA241")
   _cDados:= StrTokArr(cTipo,"/")
   DBSelectArea("SCP")
   SCP->(DBSetOrder(1))
   For _nX:=1 To Len(_cDados)
      If cTm == _cDados[_nX] .And. Empty(CCC)
         FWAlertWarning("Não é possivel fazer movimento com o centro de custo em branco. Favor preencher o campo centro de custo.","MT241TOK12")
         _lRet := .F.
      ElseIf !Empty(M->D3_CC)
         For _nI:=1 To Len(aCols)
            If aTail(aCols[_nI]) // Se Linha Deletada
               Loop
            EndIf
            If scp->(DBSeek(xFilial("SCP")+aCols[_nI][_nPosNumSa]+aCols[_nI][_nPosItem]))
               SCP->(RecLock("SCP",.F.))
               SCP->CP_CC     := CCC
               SCP->CP_I_MOTIV:= aCols[_nI][_nPosMotiv]
               SCP->CP_OBS    := aCols[_nI][_nPosObs]
               SCP->(MSUnLock())
            EndIf
         Next _nI
      EndIf
   Next _nX
EndIf

SCP->(FwRestArea(_aAreaSCP))
SB1->(FwRestArea(_aAreaSB1))
ZZL->(FwRestArea(_aAreaZZL))
FwRestArea(_aArea)

Return _lRet
