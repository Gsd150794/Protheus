/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Josué Danich  |19/01/2017| Chamado 26578. Ajustado produto e filial para mudar tipo em parâmetros
Alex Wallauer |10/10/2018| Chamado 26578. Teste da variavel "_cAliSpd" se existe
Alex Wallauer |02/10/2019| Chamado 30726. Teste dos campos 'FT_PRODUTO' e 'FT_FILIAL' se existem
=====================================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: SPDFIS001
Autor-------------: Darcio Ribeiro Sporl
Data da Criacao---: 28/09/2016
Descrição---------: Ponto de Entrada para tratar tipos de produtos
Parametros--------: ParamIXB[1] - Contém os tipos de produtos padrão
Retorno-----------: _aTipo - Contém os tipos de produtos padrão mais os de usuário
===============================================================================================================================
*/
User Function SPDFIS001()

Local _aArea    := FWGetArea()
Local _aAreaSB1	:= SB1->(GetArea())
Local _aAreaSBZ	:= SBZ->(GetArea())
Local _aTipo	:= ParamIXB[1]    
Local _cProdut 	:= ""
Local _cTipFab	:= ""
Local _nPosPrd 	:= 0
Local _nPosFil  := 0
Local _cFilial  := ""  , _nI
  
If !funname() == "MATR241"

	If Type("_cAliSpd") = "C" .And. select(_cAliSpd) > 0 .And. Len(_cAliSpd) > 3 
       _nPosPrd:= (_cAliSpd)->(FieldPos('FT_PRODUTO'))
       _nPosFil:= (_cAliSpd)->(FieldPos('FT_FILIAL'))
	   If _nPosPrd <> 0 .And. _nPosFil <> 0
		   _cProdut := (_cAliSpd)->(FieldGet(_nPosPrd)) 	
		   _cFilial := (_cAliSpd)->(FieldGet(_nPosFil)) 
		   _cTipFab := Posicione("SBZ",1,xFilial("SBZ")+_cProdut,"BZ_I_REVEN")
	   EndIf   
	EndIf

	If Empty(_cProdut)
	   _cProdut := SB1->B1_COD
	   _cFilial := xFilial("SBZ")
	   _cTipFab := Posicione("SBZ",1,xFilial("SBZ")+_cProdut,"BZ_I_REVEN")
	EndIf


	If AllTrim(_cTipFab) == "S" .And. Len(_aTipo) >= 5
		_aTipo[5][2] := "00"
	Else
		aAdd(_aTipo,	{"IN","10"} )
		aAdd(_aTipo,	{"SV","09"} )
		aAdd(_aTipo,	{"MN","07"} )		
	EndIf	
	
	//Ajuste para bloco 0210, k0230, k0235
	If AllTrim(_cProdut) $ u_itgetmv("IT_PK0210","08000000039") .And. AllTrim(_cFilial) $ U_ITGETMV("IT_FK0210","40,04")
	
		For _nI := 1 to Len(_aTipo)
		
			_aTipo[_nI][2] := "03"
			
		Next
			
	EndIf
	
EndIf

FWRestArea(_aAreaSB1)
FWRestArea(_aAreaSBZ)
FWRestArea(_aArea)

Return _aTipo
