/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |19/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: TITICMST
Autor-----------: Julio de Paula PAz
Data da Criacao-: 19/09/2023
Descrição-------: Ponto de entrada que permite alterar data de vencimento do título e guia de recolhimento do ICMS/ICMS ST/DIFAL
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function TITICMST As Array

Local _cOrigem := ParamIXB[1] As Character
Local cTipoImp := ParamIXB[2] As Character
Local _aRet := {SE2->E2_NUM,SE2->E2_VENCTO} As Array
Local _cTesIcmst := SuperGetMV("IT_TESCCEE",.F.,'088') As Character
Local _cNatIcmst := SuperGetMV("IT_NATCCEE",.F.,'212054') As Character

// Permite alterar a data de vencimento de títulos SE2 e natureza de operação, 
// para nota fiscal de entrada de liquidação de diferenças no mercado de curto prazo,
// de CCEE.
If _cOrigem == "MATA103" .And. SD1->D1_TES == U_ITKEY(_cTesIcmst,"D1_TES") .And. cTipoImp == "1" .And. SF1->F1_FORMUL=="S" 
   SE2->(RecLock("SE2",.F.))
   SE2->E2_VENCTO  := DataValida(FirstDate(MonthSum(dDataBase,1))+9,.T.) 
   SE2->E2_VENCREA := DataValida(FirstDate(MonthSum(dDataBase,1))+9,.T.) 
   SE2->E2_NATUREZ := _cNatIcmst 
   SE2->(MSUnLock())
EndIf

Return _aRet 
