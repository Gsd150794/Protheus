/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |26/02/2023| Chamado AEST050. Gatilho alterado para ser chamado para o Local de origem tambem.
=============================================================================================================================== 
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: AEST050
Autor-------------: Alex Wallauer
Data da Criacao---: 17/02/2023
Descrição---------: Chamada do gatilho 007 do campo NNT_PROD - CHAMADO 43029 
Parametros--------: U_AEST050("ORIGEM") // U_AEST050("DESTINO")
Retorno-----------: _cLocRet: Armazem da linha de cima 
===============================================================================================================================
*/  
User Function AEST050(_cChamado)
Local _oModel  := FwModelActive()
Local _N       := _oModel:aAllSubModels[2]:Getline()
Local _cLocRet := "  "
DEFAULT _cChamado:="DESTINO"
If _cChamado = "ORIGEM"
   If _N > 1 
      _cLocRet:=FWFldGet("NNT_LOCAL",_N-1) 
   Else
      _cLocRet:=FWFldGet("NNT_LOCAL",_N) 
   EndIf
ElseIf _cChamado = "DESTINO"
   If _N > 1 
      _cLocRet:=FWFldGet("NNT_LOCLD",_N-1) 
   Else
      _cLocRet:=FWFldGet("NNT_LOCLD",_N) 
   EndIf
EndIf
Return _cLocRet
