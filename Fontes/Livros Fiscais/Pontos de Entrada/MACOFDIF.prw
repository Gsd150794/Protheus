/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alexandre V.  |14/05/2015| Chamado 10102. Ajuste na validação da espécie e tipo quando a chamada For feita via MATA103.
Lucas Borges  |09/11/2023| Chamado 45494. Retirada validações diferenciando as funções. 
Lucas Borges  |15/06/2025| Chamado 50998. Revisões diversas visando padronizar os fontes
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MACOFDIF
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 04/09/2013
Descrição---------: Ponto de entrada para tratamento do COFINS com Alíquota Diferenciada.
Parametros--------: ParamIXB[1] -> C -> Item atual do processo
                    ParamIXB[2] -> N -> Alíquota do PIS de Apuração
Retorno-----------: _cUsaAlq, _nAliq -> A -> Utiliza (S/N), o Valor do PIS Retornado pela Função. Alíquota do COFINS de Apuração.
===============================================================================================================================
*/
User Function MACOFDIF

Local _nAliq  := ParamIXB[2] As Numeric
Local _cUsaAlq:= "N" As Character

If FWIsInCallStack("MATA116")
       _cUsaAlq := 'S'
ElseIf FWIsInCallStack("MATA103")
       If AllTrim(cEspecie) == 'CTE' .And. cTipo == 'C'
              _cUsaAlq := 'S'
       EndIf
ElseIf FWIsInCallStack("COMXCOL")
       If Type("cEspecie") == "C" .And. AllTrim(cEspecie) == 'CTE' .And. cTipo == 'C'
              _cUsaAlq := 'S'
       EndIf
EndIf
If _cUsaAlq == 'S'
       _nAliq := SuperGetMv("MV_TXCOF")
EndIf

Return({_cUsaAlq,_nAliq})
