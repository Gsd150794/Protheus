/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Igor Melgaço  |13/07/2022| Chamado 43230. Ajuste para inclusão de parametro para comparação com B1_TIPO
Lucas Borges  |07/05/2025| Chamado 50617. Corrigir chamada estática no nome das tabelas do sistema
Lucas Borges  |18/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MT120QRY
Autor-------------: Alex Wallauer
Data da Criacao---: 21/03/2022
Descrição---------: P.E. para filtrar o browse dos pedidos de compras, MATA120.PRW. Chamado 38650
Parametros--------: Nenhum
Retorno-----------: lRet -> cFilQuery
===============================================================================================================================
*/
User Function MT120QRY() 

Local cFilQuery  := ""
Local _cGrpLeite := SuperGetMV("IT_GRPFLEI",.F.,"000008,000009,000010,000011")   
Local _cPCGERAL  := SuperGetMV("IT_PCGERAL",.F.," ")
Local _cTipos    := SuperGetMV("IT_TPPRDPC",.F.,"MP;PP;PI;SP") 

SY1->(DBSetOrder(3))
SY1->(DBSeek(xFilial("SY1") + AllTrim(__cUserId)))
If !SY1->Y1_COD $ _cPCGERAL
   If SY1->Y1_GRUPCOM $ _cGrpLeite
      cFilQuery+=" C7_PRODUTO IN (SELECT B1_COD FROM " + RetSqlName("SB1") + " WHERE D_E_L_E_T_ = ' ' AND B1_TIPO IN "+ FormatIn(_cTipos,";") + ")"
   Else
      cFilQuery+=" C7_PRODUTO IN (SELECT B1_COD FROM " + RetSqlName("SB1") + " WHERE D_E_L_E_T_ = ' ' AND B1_TIPO NOT IN "+ FormatIn(_cTipos,";") + ")"
   EndIf
EndIf
SY1->(DBSetOrder(1))

Return cFilQuery
