/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |03/05/2022| Chamado 39942. Inclusão de novas regras.
Lucas Borges  |05/07/2022| Chamado 40666. Alterada condição de pagamento para filial 10, trasportador C.
Lucas Borges  |23/03/2023| Chamado 43372. Incluída filial 94
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: A140ICOND
Autor-----------: Lucas Borges Ferreira
Data da Criacao-: 03/06/2020
Descrição-------: Permite alterar e validar a condição de pagamento utilizada no monitor do totvs colaboração
				 LOCALIZAÇÃO: No monitor Totvs Colaboração
Parametros--------: ParamIXB[01] -> C -> Fornecedor
                    ParamIXB[02] -> C -> Loja
                    ParamIXB[03] -> C -> Condição de Pagamento
Retorno---------: cCondPgto -> C -> Condição de Pagamento
===============================================================================================================================
*/
User Function A140ICOND

Local _cCondPgto    := ParamIXB[3]

If AllTrim(SDS->DS_ESPECI) == 'CTE'
    If SubStr(ParamIXB[1],1,1) =='G'
        If cFilAnt $ '10/11/1A/1B'
            _cCondPgto := '079'//16 mês subsequente
        ElseIf cFilAnt $ '20/23/24/25'
            _cCondPgto := '078'//15 mês subsequente
        ElseIf cFilAnt == '40'
            _cCondPgto := '083'//20 mês subsequente
        Else 
            _cCondPgto := '088'//25 mês subsequente
        EndIf
    ElseIf SubStr(ParamIXB[1],1,1) $'T/C'
        If cFilAnt $ '10/11/1A/1B' .And. SubStr(ParamIXB[1],1,1) $'T'
            _cCondPgto := '091'//28 mês subsequente
        ElseIf cFilAnt $ '10/11/1A/1B' .And. SubStr(ParamIXB[1],1,1) $'C'
            _cCondPgto := '073'//10 mês subsequente
        ElseIf cFilAnt $ '20/23/24/25/93' .And. SubStr(ParamIXB[1],1,1) $'C'
            _cCondPgto := '99H'//15 mês subsequente
        Else
            If Day(SDS->DS_EMISSA) >= 1 .And. Day(SDS->DS_EMISSA) <= 15
                _cCondPgto := '071'//08 mês subsequente
            Else
                _cCondPgto := '086'//23 mês subsequente
            EndIf
        EndIf
    EndIf
EndIf

Return _cCondPgto
