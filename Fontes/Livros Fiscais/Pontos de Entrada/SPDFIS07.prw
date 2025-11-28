/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Darcio Sporl  |31/01/2017| Chamado 4058. Foi reajustado o tratamento de retorno da conta contábil.
Lucas Borges  |02/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25.
Julio Paz     |17/12/2019| Chamado 31211. Alterações na forma que a rotina de sped fiscal obtem o numero contábil.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: SPDFIS07
Autor-------------: Darcio Ribeiro Sporl
Data da Criacao---: 17/03/2016
Descrição---------: Ponto de entrada que permite a customização do Código da Conta Contábil no registro H010 do SPED Fiscal.
Parametros--------: ParamIXB[1] - Codigo Produto
------------------: ParamIXB[2] - Tipo
------------------: ParamIXB[3] - Codigo Armazem
Retorno-----------: cRet - Retorna o número da conta contábil
===============================================================================================================================
*/
User Function SPDFIS07()

Local _aArea	:= FWGetArea()
Local _cCodProd	:= ParamIXB[1] //Codigo do Produto
Local _cRet		:= ""

Begin Sequence
   ZGH->(DBSetOrder(6)) // ZGH_FILIAL+ZGH_TIPOPD
   SB1->(DBSetOrder(1))
   
   If SB1->(DBSeek(xFilial("SB1")+_cCodProd)) 
      If ZGH->(DBSeek(xFilial("ZGH")+SB1->B1_TIPO)) 
         _cRet := ZGH->ZGH_CONTA 
      EndIf
   EndIf
   
End Sequence

FWRestArea(_aArea)

Return _cRet
