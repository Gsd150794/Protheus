/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |06/11/2019| Chamado 30984. Não valida fracionamento de UM quando vem do IsInCallStack("U_A010TOK")
Lucas Borges  |19/09/2024| Chamado 48569. Incluir a rotina de Desconto Tetra Pak nas exceções para validação de acesso
Lucas Borges  |19/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: MT240TOK
Autor-----------: Tiago Correa Castro
Data da Criacao-: 25/04/2009
Descrição-------: Ponto de Entrada que valida movimento interno modelo I
Parametros------: Nenhum
Retorno---------: Lógico, permitindo ou não a gravação o movimento
===============================================================================================================================
*/
User Function MT240TOK

Local _aArea      := FWGetArea() As Array
Local _aAreaZZL   := ZZL->(FWGetArea()) As Array
Local _aAreaSB1   := SB1->(FWGetArea()) As Array
Local _lRet		   :=	.T. As Logical
Local cTipo  	   := SuperGetMV("IT_TPMOV",.F., "") As Character
Local _cDados	   := {} As Array
Local _aSldNeg  	:= {} As Array
Local _cArmazens  := SuperGetMV('IT_ARMCPR',.F.,"02,04") As Character
Local _cUMNoFrac  := SuperGetMV("IT_UMNOFRAC",.F.,"PC,UN") As Character
Local _lVldFr1UM  :=.T. As Logical
Local _nX         := 0 As Numeric

If SubStr(M->D3_COD,1,4) == "0006" .And. !IsInCallStack("U_MEST015") .And. M->D3_QTSEGUM == 0
   FWAlertWarning("Para esse produto e obrigatorio o preenchimento da segunda unidade de medida (Peças).",;
                  "Favor preencher a segunda unidade de medida (Peças).","MT240TOK01")
   _lRet := .F.
ElseIf SuperGetMV("IT_BLQMOV",.F., "") .And. M->D3_EMISSAO > Date()
   FWAlertWarning("Os movimentos com data maior que a data atual estão bloqueados.",;
                  "Entre em contato com o departamento de TI para maiores informações.","MT240TOK02")
   _lRet := .F.
ElseIf !FWIsInCallStack("DESCTETRAE") .And. !FWIsInCallStack("DESCTETRAE") .And. !FWIsInCallStack("AGLT003G") .And. !FWIsInCallStack("MATA103")
   ZZL->(DBSetOrder(3))
   If ZZL->(DBSeek(xFilial("ZZL")+RetCodUsr()))
      If ZZL->ZZL_AUTSIM <> 'S'
         FWAlertWarning("Usuário sem permissão para realizar movimentação simples. Não será possível realizar a movimentação. Entre em contato com o suporte do TI.", "MT240TOK03")
         _lRet := .F.
      ElseIf M->D3_TM >= "500" .And. (M->D3_LOCAL $ _cArmazens) .And. ZZL->ZZL_PERTRA <> "S"
         FWAlertWarning("Para o "+M->D3_LOCAL+" não é permitido a movimentação interna, somente tranferencia entre armazens. Armazens não permitidos: '"+AllTrim(_cArmazens)+"'.",;
                        "Realize a transferencia entre armazens ou entre em contato com o departamento de Custo.","MT240TOK04")
         _lRet := .F.
      ElseIf !(M->D3_TM $ ZZL->ZZL_TIPMOV)
         FWAlertWarning("Usuário sem permissão para utilizar este tipo de movimento. Não será possível realizar a movimentação. Tipos de Movimentos permitidos ao usuário: '"+AllTrim(ZZL->ZZL_TIPMOV)+"'.",;
                        "Entre em contato com o suporte do TI.","MT240TOK05")
         _lRet := .F.
      ElseIf !(M->D3_LOCAL $ ZZL->ZZL_ARMAZE)
         FWAlertWarning("Usuário sem permissão para utilizar este armazem. Não será possível realizar a movimentação simples. Armazens permitidos ao usuário: '"+AllTrim(ZZL->ZZL_ARMAZE)+"'.",;
                        "Entre em contato com o suporte do TI.","MT240TOK06")
         _lRet := .F.
      Else
         _cTipoProd:=Posicione("SB1",1,xFilial("SB1")+M->D3_COD,"B1_TIPO")
         If !(_cTipoProd $ ZZL->ZZL_TIPROD)
            FWAlertWarning("Usuário sem permissão para utilizar este Tipo de Produto ["+_cTipoProd+"]. Não será possível realizar a movimentação multipla. Tipos permitidos ao usuário: '"+AllTrim(ZZL->ZZL_TIPROD)+"'.",;
                           "Entre em contato com o suporte do TI.",,"MT240TOK07")
            _lRet := .F.
         EndIf
      EndIf
   Else
      FWAlertWarning("Usuário sem cadastro na ZZL. Entre em contato com o suporte do TI.","MT240TOK08")
      _lRet := .F.
      EndIf
EndIf

//Só roda validações abaixo se não For execução automática de entrada de recepção de leite	
If !FWIsInCallStack("AGLT003") .And. !FWIsInCallStack("MGLT002") .And. !FWIsInCallStack("AGLT021") 
   //Criado para impedir que seja feito lançamento de saída retroativo deixando o saldo negativo em alguma data posterior.
   If M->D3_TM >= "500"          //Se movimento de saída
      _aSldNeg := U_VldEstRetrNeg(M->D3_COD, M->D3_LOCAL, M->D3_QUANT, M->D3_EMISSAO)    //Varre os saldos de cada dia atá a data de hoje buscando por saldo insuficiente
      If Len(_aSldNeg) > 0
         FWAlertWarning("Não permitido, pois o produto " + M->D3_COD + "-" + M->D3_LOCAL + " não tem saldo suficiente em " + DToC(_aSldNeg[1]) + ;
                        ". Saldo na data:" + Transform(_aSldNeg[2],"@E 999,999.99"),"MT240TOK09")
         _lRet  := .F.
      EndIf
   EndIf
   
   If _lRet
      If ZZL->ZZL_PEFRPA == "S"
         _lVldFr1UM:=.F.
      EndIf

      If IsInCallStack("U_A010TOK")//Quando vem do cadastro de produtos apos trocar de UM zera o estoque
         _lVldFr1UM:=.F.
      EndIf

      SB1->(DBSetOrder(1))
      If _lVldFr1UM .And. SB1->(DBSeek(xFilial("SB1") + M->D3_COD))
         If (SB1->B1_UM $ _cUMNoFrac .And. M->D3_QUANT <> Int(M->D3_QUANT))
            FWAlertWarning("Não é permitido fracionar a quantidade da 1a. UM de produto onde a Unid. Medida For "+_cUMNoFrac+".",;
                     "Favor informar apenas quantidades inteiras na Primeira Unidade de Medida.","MT240TOK10")
            _lRet := .F.
         ElseIf (SB1->B1_SEGUM $ _cUMNoFrac .And. M->D3_QTSEGUM <> Int(M->D3_QTSEGUM))//= "PC" .And. LEFT(M->D3_COD,4)=="0006" .And. M->D3_QTSEGUM <> Int(M->D3_QTSEGUM) )
            FWAlertWarning("Não é permitido fracionar a quantidade da 2a. UM de produto onde a Unid. Medida For "+_cUMNoFrac+".",;//,_ntipo,_nbotao,_nmenbot,_lHelpMvc,_cbt1,_cbt2,_bMaisDetalhes
                     "Favor informar apenas quantidades inteiras na Segunda Unidade de Medida.","MT240TOK11")
            _lRet := .F.
         EndIf
      EndIf
   EndIf
EndIf

If _lRet
   _cDados:= StrTokArr(cTipo,"/")//  validação do centro de custo para que não deixe baixar se o mesmo estiver em branco de acordo com o tipo de movimentação do parametro IT_TPMOV. Chamado 3360.
   For _nX:=1 To Len(_cDados)
      If M->D3_TM == _cDados[_nX] .And. Empty(M->D3_CC)
         FWAlertWarning("Não é possivel fazer movimento com o centro de custo em branco. Favor preencher o campo centro de custo.","MT240TOK12")
         _lRet := .F.
      ElseIf !Empty(M->D3_CC) // validação para preenchimento do centro de custo na tabela SCP conforme o que For baixado na tabela SD3. Chamado: 3409.
         SCP->(RecLock("SCP",.F.))
         SCP->CP_CC     := M->D3_CC
         SCP->CP_I_MOTIV:= M->D3_I_MOTIV   //  validação para gravação do conteudo do campo CP_I_MOTIV para o campo D3_I_MOTIV.
         SCP->CP_OBS	   := M->D3_I_OBS
         SCP->(MSUnLock())
      EndIf
   Next _nX
EndIf

SB1->(FwRestArea(_aAreaSB1))
ZZL->(FwRestArea(_aAreaZZL))
FwRestArea(_aArea)

Return _lRet
