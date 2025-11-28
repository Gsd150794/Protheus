/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |18/09/2024| Chamado 48569. Incluir a rotina de Desconto Tetra Pak nas exceções para validação de acesso
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MA260EST
Autor-------------: Julio de Paula Paz
Data da Criacao---: 29/08/2016
Descrição---------: Ponto de entrada para validar estorno o estorno da transferência simples.
Parametros--------: Nenhum
Retorno-----------: _lRet == Define se a transferência pode ser estornada
===============================================================================================================================
*/
User Function MA260EST

Local _aArea      := FWGetArea()
Local _aAreaZZL   := ZZL->(FWGetArea())
Local _lRet	      := .T.

//================================================================================
// Valida o estorno de acordo com o cadastro de usuários Italac.
//================================================================================
ZZL->(DBSetOrder(3))
If ZZL->(DBSeek(xFilial("ZZL")+RetCodUsr()))
   If ZZL->ZZL_AUTSIM <> 'S' .And. !FWIsInCallStack("DESCTETRAE") .And. !FWIsInCallStack("DESCTETRAE")
      FWAlertWarning("Usuário sem permissão para realizar estorno de transferência simples. Não será possível realizar o estorno da transferência. Entre em contato com o suporte do TI.", "MA260EST01")
      _lRet := .F.
   ElseIf !(cLocOrig $ ZZL->ZZL_ARMAZE)
      FWAlertWarning("Usuário sem permissão para utilizar este armazem de origem. Não será possível realizar o estorno da transferência. Armazens permitidos ao usuário: '"+AllTrim(ZZL->ZZL_ARMAZE)+"'. Entre em contato com o suporte do TI.", "MA260EST02")
      _lRet := .F.
   EndIf
Else
   FWAlertWarning("Usuário sem cadastro na ZZL. Entre em contato com o suporte do TI.","MA260EST03")
   _lRet := .F.
EndIf
ZZL->(FwRestArea(_aAreaZZL))
FwRestArea(_aArea)

Return _lRet
