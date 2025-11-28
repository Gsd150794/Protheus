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
Programa--------: F580MNBR
Autor-----------: Julio de Paula Paz
Data da Criacao-: 06/08/2019
Descrição-------: Ponto de entrada permite alterar os campos do MSSELECT da tela de liberação de títulos  
                  automáticas. Chamado 29963.
Parametros------: cChave = Chave de ordenação padrão.
Retorno---------: _cRet  = Nova chave de ordenação.
===============================================================================================================================
*/
User Function F580MNBR()
Local _aParam := ParamIXB
Local _aRet 
Local _nI, _aDadosMS := {}

Begin Sequence
   _aRet := _aParam 
   For _nI := 1 To Len(_aParam)
       If AllTrim(_aParam[_nI,1]) == "E2_NOMFOR" .And. MV_PAR14 == 1 
          aAdd(_aDadosMS, {{|| Posicione("SA2",1,xFilial("SA2")+QRYSE2->(E2_FORNECE+E2_LOJA),"A2_NOME")}, "", "Nome Fornecedor", "@!"})
          Loop
       EndIf

       If AllTrim(_aParam[_nI,1]) == "E2_VENCREA" .And. MV_PAR15 == 2 
          aAdd(_aDadosMS, _aParam[_nI])
          aAdd(_aDadosMS, {"E2_BASEIRF", "", "Base IRPF"      , "@E 9,999,999,999,999.99"})      
          aAdd(_aDadosMS, {"E2_IRRF"   , "", "IRRF"           , "@E 999,999,999.99"})
          aAdd(_aDadosMS, {"E2_ISS"    , "", "ISS"            , "@E 999,999,999.99"})
          aAdd(_aDadosMS, {"E2_VALOR"  , "", "Valor do título", "@E 99,999,999,999,999.99"})
       EndIf

       If AllTrim(_aParam[_nI,1]) $ "E2_BASEIRF/E2_IRRF/E2_ISS/E2_VALOR/E2_VENCREA" .And. MV_PAR15 == 2 
          Loop
       EndIf

       aAdd(_aDadosMS, _aParam[_nI])
   Next
   
   _aRet := Aclone(_aDadosMS)

End Sequence

Return _aRet 
