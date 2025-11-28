/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Antonio Neves |07/05/2025| Chamado 50535. PE Ajustar a conta bancária na Importação do Extrato Bancário
===============================================================================================================================
*/

#Include "TOTVS.ch"
  
/*
===============================================================================================================================
Programa----------: F474CTA
Autor-------------: Antonio Neves
Data da Criacao---: 07/05/2025
Descrição---------: PE Tratar os Dados Bancários na Importação do Extrato Bancário
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function F474CTA()

Local cBanco := ParamIXB[1]
Local cAgencia := ParamIXB[2]
Local cConta := StrTran(ParamIXB[3],' ','')
Local aRet := {}

aRet := {cBanco,cAgencia,cConta}
 
Return aRet
