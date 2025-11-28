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
Programa----------: MC030PRD
Autor-------------: Andre Lisboa
Data da Criacao---: 29/06/2015
Descricao---------: Tela de consulta ao kardex. Este ponto de entrada retorna linhas a serem incluidas no cabeÃ§alho da consulta (MAXIMO DE 5 LINHAS) - Chamado 10758
===============================================================================================================================
*/

User Function MC030PRD()

Local aRetCabec 	:= {}    
Local cLocal		:= Posicione("SBZ",1,xFilial("SBZ")+SB2->B2_COD,"BZ_I_LOCAL") // endereco do produto

aAdd(aRetCabec,'Endereco: '+cLocal)

Return aRetCabec
