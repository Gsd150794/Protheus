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
Programa----------: MTMODNOT
Autor-------------: Alex Wallauer
Data da Criacao---: 23/03/2018
Descrição---------: Utilizar o retorno da espécie NFDS como " " (Vazio), assim como é feito para as espécies NFS, NFPS e RPS 
                    que são entendidas como nota de serviço no padrão. Chamado 24235
Parametros--------: Recebe a Especie da nota
Retorno-----------: Retorno modelo 
===============================================================================================================================
*/
User Function MTMODNOT

Local cEspecie:=ParamIXB
Local cCodigo :="01" // Default Nota Fiscal ou Nota Fiscal Fatura

If cEspecie = "NFDS"
   cCodigo:="  " // retorno do modelo da espécie NFDS
EndIf

Return cCodigo
