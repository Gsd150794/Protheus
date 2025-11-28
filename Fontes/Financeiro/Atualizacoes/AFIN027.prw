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
Programa----------: AFIN027
Autor-------------: Alex Wallauer
Data da Criacao---: 26/02/2019
Descrição---------: Funcao chamada no CNAB modulo 1 a REceber pelo Banco Bradesco para a montagem do campo de data Vencimento
Parametros--------: Nenhum
Retorno-----------: Data de vencimento no formato DDMMAA
===============================================================================================================================
*/
User Function AFIN027()

Return If(!Empty(SE1->E1_I_DTPRO),SubStr(DToS(SE1->E1_I_DTPRO),7,2)+SubStr(DToS(SE1->E1_I_DTPRO),5,2)+SubStr(DToS(SE1->E1_I_DTPRO),3,2),SubStr(DToS(SE1->E1_VENCTO),7,2)+SubStr(DToS(SE1->E1_VENCTO),5,2)+SubStr(DToS(SE1->E1_VENCTO),3,2))

