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
Programa----------: MT103MEM
Autor-------------: Erich Buttner
Data da Criacao---: 20/02/2013
Descrição---------: P.E. para tratar campos MEMO VIRTUAL da SDE. Cria variáveis que serão utilizadas no ponto 'MT103DCF'
Parametros--------: Nenhum
Retorno-----------: aUsMemo - Array vazio para não ativar a tratativa do P.E.
===============================================================================================================================
*/
User Function MT103MEM

Local aUsMemo := {}

Public cMens1		:= ""
Public cMens2		:= ""
Public _cMotorista	:= Space(06)
Public _cPlaca	:= Space(08)
Public _cDescMotor	:= Space(60)
Public _cDescVeic	:= Space(30)
Public _cVeiculo	:= Space(08)

Return( aUsMemo )
