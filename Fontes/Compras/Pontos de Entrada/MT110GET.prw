/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz     |17/07/2017| Chamado 20777. Virada de versão da P11 para a versão P12. Ajustes no fonte para a versão P12.
Lucas Borges  |04/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MT110GET
Autor-------------: Julio de Paula Paz
Data da Criacao---: 20/07/2017
Descrição---------: Ponto de entrada de ajuste de coordenadas da tela de Solicitação de Compras.
Parametros--------: ParamIXB[1] - Array das coordenadas do objeto da dialog da Solicitação de Compras
                    ParamIXB[2] - Opção selecionada na Solicitação de Compras (inclusão, alteração, exclusão, etc.)
Retorno-----------: aPosObjPE = Objeto das coordenadas da dialog da Solicitação de Compras
===============================================================================================================================
*/
User Function MT110GET

Local aPosObjPE	:= ParamIXB[1]

aPosObjPE[2,1] := aPosObjPE[2,1] + 29
aPosObjPE[1,3] := aPosObjPE[1,3] + 27

Return aPosObjPE
