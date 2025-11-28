/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |22/10/2018| Chamado 26721. Criada tela para selecionar a Moeda
Alex Wallauer |29/10/2019| Chamado 30987. Ao copiar o PC e se dor em outra moeda atualizar a taxa coma da data do dia
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: MT120CPE
Autor-----------: Alex Wallauer
Data da Criacao-: 22/10/2018
Descrição-------: P.E. antes das telas de manutenção do Pedido de compra. (MATA120)
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function MT120CPE

If ParamIXB[1] == 3 .Or. ParamIXB[2]//INCLUSAO DE PC OU NA COPIA
   nMoedaPed:= U_MT120ALT("RETORNA_OPCAO_AVISO") 
   cDescMoed:= "MV_MOEDA"+AllTrim(Str(nMoedaPed))
   cDescMoed:= SuperGetMv(cDescMoed)
   nTxMoeda := RecMoeda(dDataBase,nMoedaPed)
   If nTxMoeda = 0 .And. SM2->(DBSeek(DToS(dDataBase)))
      nTxMoeda:=SM2->(FIELDGET( FIELDPOS( "M2_MOEDA"+Str(nMoedaPed,1) ) ))
   EndIf
EndIf

Return .T.
