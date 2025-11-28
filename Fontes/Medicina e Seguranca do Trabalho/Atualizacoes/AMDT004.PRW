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
Programa----------: AMDT004
Autor-------------: Alex Wallauer Ferreira 
Data da Criacao---: 27/07/2016
Descrição---------: Funcao chamada do X3_VALID do campo TLW_QTDEVO
Parametros--------: 
Retorno-----------: 
===============================================================================================================================
*/
User Function AMDT004()//Positivo() .And. U_AMDT004() no X3_VALID do campo TLW_QTDEVO

Local _aArea := FWGetArea()
Local _nPos := aScan(aHEADER, {|x| AllTrim(Upper(X[2])) == "TLW_TIPODV" })

If AVISO("Reposicao do Estoque", "O EPI Será?", { "TROCA", "DESCARTE" }, 1) = 1
   aCols[n,_nPos]:="1"
Else
   aCols[n,_nPos]:="2"
EndIf

FWRestArea(_aArea)

Return .T.
