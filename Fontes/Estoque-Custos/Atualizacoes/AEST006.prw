/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |25/09/2019| Chamado 30673. Ajustes para o novo nivel 5 dos produtos
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: AEST006
Autor-------------: Cleiton Campos
Data da Criacao---: 16/07/2008 
Descrição---------: Rotina de composicao de descricao de produtos acabados.
Parametros--------: Gatilho B1_I_NIV4 e B1_I_NIV5
Retorno-----------: Descricao de produtos conforme niveis.
===============================================================================================================================
/*/  
User Function AEST006()

Local _cRetorno := ""

_cRetorno :=     AllTrim(Posicione("ZA1",1,xFilial("ZA1")+M->B1_GRUPO+M->B1_I_NIV2,"ZA1_DESCRI"))
_cRetorno += " "+AllTrim(Posicione("ZA2",1,xFilial("ZA2")+M->B1_I_NIV3,"ZA2_DESCRI"))
_cRetorno += " "+AllTrim(Posicione("ZA3",1,xFilial("ZA3")+M->B1_I_NIV4,"ZA3_DESCRI"))
_cRetorno += " "+AllTrim(Posicione("ZA0",1,xFilial("ZA0")+M->B1_I_NIV5,"ZA0_DESCRI"))

Return(_cRetorno)
