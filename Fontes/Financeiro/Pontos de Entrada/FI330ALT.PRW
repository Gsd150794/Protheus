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
Programa----------: FI330ALT
Autor-------------: Josué Danich Prestes
Data da Criacao---: 05/04/2019
Descrição---------: Ponto de entrada de ajuste do  browse da tela de compensação - Chamado 28746
Parametros--------: ParamIXB - http://tdn.totvs.com/display/Public/PROT/DT_FI330ALT_Altera_array_titulos
Retorno-----------: ARRAY com atitulos da função
===============================================================================================================================
*/
User Function FI330ALT()

Local _aArea := FWGetArea()
Local _aTipo := ParamIXB[1]
Local _nx

If u_itgetmv("ITDESMCOMP",.T.)  

	//Garante que todos os títulos virão desmarcados
	For _nx:=1 To Len(_aTipo) 

        If Len(_atipo[_nx]) >= 8  .And. ValType(_atipo[_nx][8]) == "L"

		    _aTipo[_nx][8] := .F.

        EndIf

	Next _nx

EndIf

FWRestArea(_aArea)

Return _aTipo
