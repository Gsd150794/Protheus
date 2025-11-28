/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: F580CHAV
Autor-----------: Julio de Paula Paz
Data da Criacao-: 06/08/2019
Descrição-------: Ponto de entrada permite alterar a chave de ordenação dos dados do MSSelect, quando a opção liberação
                  automática For acionada. Chamado 29963.
Parametros------: cChave = Chave de ordenação padrão.
Retorno---------: _cRet  = Nova chave de ordenação.
===============================================================================================================================
*/
User Function F580CHAV()
Local _aParam := ParamIXB
Local _cRet 
Local _cParam

Begin Sequence
   _cParam := If(ValType(_aParam) == "A", _aParam[1] , _aParam)
   _cRet := _cParam
   
   If Empty(MV_PAR13) .Or. MV_PAR13 == 1  // Padrão
      Break // "E2_FILIAL+DToS(E2_VENCREA)+E2_NOMFOR+E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO"
   ElseIf MV_PAR13 == 2 // Valor do Titulo
      _cRet := "E2_FILIAL+E2_VALOR"
   ElseIf MV_PAR13 == 3 // Codigo/Loja Fornecedor
      _cRet := "E2_FILIAL+E2_FORNECE+E2_LOJA"   
   ElseIf MV_PAR13 == 4 // Numero Titulo
      _cRet := "E2_FILIAL+E2_NUM"
   ElseIf MV_PAR13 == 5 // Vencimento
      _cRet := "E2_FILIAL+E2_VENCTO"
   EndIf

End Sequence

Return _cRet
