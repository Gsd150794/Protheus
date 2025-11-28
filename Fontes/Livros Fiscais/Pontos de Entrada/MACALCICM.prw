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
Programa----------: MACALCICMS
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 15/06/2025
Descrição---------: Ponto de entrada na MATXFIS reprocessamento executado após o processamento do calculo da Base do ICMS e 
                    após o calculo do Valor do ICMS. Chamado 50998
Parametros--------: ParamIXB[1]	-C-	Tipo de operação da Nota Fiscal
                    ParamIXB[2]	-N-	Numero do item processado
                    ParamIXB[3]	-N-	Base do ICMS
                    ParamIXB[4]	-N-	Alíquota do ICMS 
                    ParamIXB[5]	-N-	Valor do ICMS calculado
Retorno-----------: aRet -A- Retorna um array com os dados Base, Alíquota, Valor
===============================================================================================================================
*/  
User Function MACALCICMS
 
Local _nBsICM   := ParamIXB[3] As Numeric
Local _nAliqICM := ParamIXB[4] As Numeric
Local _nVlrICM  := ParamIXB[5] As Numeric
Local _aRet     := {}          As Array

_aRet := {_nBsICM,_nAliqICM,_nVlrICM}

If FWIsInCallStack("MATA120")//Pedido de Compras
    If SA2->A2_SIMPNAC == '1'
        _aRet := {0,0,0}
    EndIf
EndIf
 
Return _aRet
