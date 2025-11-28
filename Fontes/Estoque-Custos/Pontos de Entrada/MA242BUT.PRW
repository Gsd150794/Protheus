/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Josué Danich  |02/03/2016| Chamado 14585. Ajuste de array para evitar errorlog na inclusão
===============================================================================================================================
*/

#Include "TOTVS.ch"
                     
/*
===============================================================================================================================
Programa----------: MTA242BUT
Autor-------------: Josué Danich Prestes
Data da Criacao---: 15/10/2015
Descrição---------: Ponto de entrada para controlar botões da MATA242 - chamado 12268
Parametros--------: 
Retorno-----------: ParamIXB[2] - array com dados de botões a serem apresentados no browse
===============================================================================================================================
*/
User Function MA242BUT()

//Modifica botão de explodir primeiro nivel de estrutura para funcao personalizada
Local nOpcao := ParamIXB[1]
 
If nOpcao = 3
	ParamIXB[2][1][2] := {|| U_AEST004(CPRODUTO,NQTDORIG,OGET)}
Else
	ParamIXB[2] := {|| U_AEST004(CPRODUTO,NQTDORIG,OGET)}
EndIf			


Return ParamIXB[2]
