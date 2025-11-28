/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz     |22/08/2024| Chamado 47670. Validar estorno considerando apenas os campos:ZZL_TIPMES,ZZL_ARMAES,ZZL_TIPRES.
Lucas Borges  |19/09/2024| Chamado 48569. Incluir a rotina de Desconto Tetra Pak nas exceções para validação de acesso
Lucas Borges  |20/09/2024| Chamado 48598. Corrigido nome do campo
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MT240EST
Autor-------------: Tiago Correa Castro
Data da Criacao---: 24/12/2008
Descrição---------: Ponto de entrada para validar estorno dos movimentos internos modelo 1
Parametros--------: Nenhum
Retorno-----------: _lRet == Define se o movimento pode ser estornado
===============================================================================================================================
*/
User Function MT240EST

Local _aArea      := FWGetArea()
Local _aAreaZZL   := ZZL->(FWGetArea())
Local _lRet       := .T.
Local _aSldNeg    := {}
Local _cTipoProd  := ""

//================================================================================
// Parametro que guarda a informacao do Tipo de Movimento que sera utilizado para
// gerar movimento interno de entrada no Estoque apos recepcao do Leite
//================================================================================
If FUNNAME() == "MATA241" .And. SD3->D3_TM $ AllTrim(SuperGetMV("LT_ENTTM",.F., ""))
   FWAlertWarning("Nao será possível o estorno desse movimento interno pois o mesmo foi gerado automaticamente por outra rotina!!"+;
            "Favor realizar estorno do movimento via rotina que gerou o mesmo!!","MT240EST01")
   _lRet := .F.
ElseIf !FWIsInCallStack("DESCTETRAE") .And. !FWIsInCallStack("DESCTETRAE")
   ZZL->(DBSetOrder(3))
   If ZZL->(DBSeek(xFilial("ZZL")+RetCodUsr()))
      If ZZL->ZZL_AUMSIM <> 'S'
         FWAlertWarning("Usuário sem permissão para realizar estorno de movimentação simples. Não será possível realizar o estorno. Entre em contato com o suporte do TI.", "MT240EST02")
         _lRet := .F.
      ElseIf !(SD3->D3_TM $ AllTrim(ZZL->ZZL_TIPMES))
         FWAlertWarning("Usuário sem permissão para utilizar este tipo de movimento. Não será possível realizar o estorno. Tipos de Movimentos permitidos ao usuário: '"+;
                        (AllTrim(ZZL->ZZL_TIPMOV)+";"+AllTrim(ZZL->ZZL_TIPMES))+"'. Entre em contato com o suporte do TI.","MT240EST03")
         _lRet := .F.
      ElseIf !(SD3->D3_LOCAL $ AllTrim(ZZL->ZZL_ARMAES))
         FWAlertWarning("Usuário sem permissão para utilizar este armazem. Não será possível realizar o estorno. Armazens permitidos ao usuário: '"+;
                        (AllTrim(ZZL->ZZL_ARMAZE)+";"+AllTrim(ZZL->ZZL_ARMAES))+"'. Entre em contato com o suporte do TI.","MT240EST04")
         _lRet := .F.
      Else
         _cTipoProd:=Posicione("SB1",1,xFilial("SB1")+SD3->D3_COD,"B1_TIPO")
         If !(_cTipoProd $ AllTrim(ZZL->ZZL_TIPRES))
            FWAlertWarning("Usuário sem permissão para utilizar este Tipo de Produto ["+_cTipoProd+"]. Não será possível realizar a movimentação multipla. Tipos permitidos "+;
                           "ao usuário: '"+(AllTrim(ZZL->ZZL_TIPROD)+";"+AllTrim(ZZL->ZZL_TIPRES))+"'. Entre em contato com o suporte do TI.","MT240EST05")
            _lRet := .F.
         EndIf
      EndIf
   Else
      FWAlertWarning("Usuário sem cadastro na ZZL. Entre em contato com o suporte do TI.","MT240EST06")
      _lRet := .F.
   EndIf
EndIf
        
//================================================================================
// Validar o saldo em estoque na data do estorno.
//================================================================================
If SD3->D3_TM < "500" 		
   _aSldNeg := U_VldEstRetrNeg(SD3->D3_COD, SD3->D3_LOCAL, SD3->D3_QUANT, SD3->D3_EMISSAO) //Varre os saldos de cada dia atá a data de hoje buscando por saldo insuficiente
   If Len(_aSldNeg) > 0
      FWAlertWarning( "Não permitido, pois o produto " + SD3->D3_COD + "-" + SD3->D3_LOCAL + " não tem saldo suficiente em " + DToC(_aSldNeg[1]) + ;
                     ". Saldo na data:" + Transform(_aSldNeg[2],"@E 999,999.99"),"MT240EST07")
      _lRet  := .F.
   EndIf
EndIf

ZZL->(FwRestArea(_aAreaZZL))
FwRestArea(_aArea)

Return _lRet
