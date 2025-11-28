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
Programa----------: CM010COR
Autor-------------: Alex Wallauer Ferreira
Data da Criacao---: 29/07/2024
Descrição---------: PE para criar legenda do Cadastro de tabela de preço dentro da 
                    função CM010COR()/COMA010.PRX. Andre. Chamado: 47732
Parametros--------: ParamIXB[1]
Retorno-----------: aCoreNew
===============================================================================================================================
*/
User Function CM010COR

Local aCoreNew:={}

aAdd(aCoreNew,{"AIA_I_SITW $ 'E,Q'","BR_AZUL"})//Tem que ser em primeiro lugar DA LSITA DE CORES
aAdd(aCoreNew,{ "DToS(AIA_DATATE) <  DToS(DATE()) .And. !Empty(DToS(AIA_DATATE))" ,"DISABLE"}) //INATIVA
aAdd(aCoreNew,{"(DToS(AIA_DATATE) >= DToS(DATE()) .Or.   Empty(DToS(AIA_DATATE)))","ENABLE"})  //ATIVA

Return aCoreNew
