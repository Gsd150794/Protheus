/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz     |17/01/2025| Chamado 48539. Recalcular e alterar as quantidades dos itens de pedidos de compras do tipo serviço
=============================================================================================================================== 
*/

#Include "TOTVS.ch" 

Static _bOpcao 

/*
===============================================================================================================================
Função-------------: MT120ABU
Autor--------------: Julio de Paula Paz
Data da Criacao----: 29/08/2024 
Descrição----------: Ponto de entrada para alteração do Abuttons do Pedido de compras. 
Parametros---------: ParamIXB = aButtons atual.
Retorno------------: _aButonAlt = aButtons alterado.
===============================================================================================================================
*/  
User Function MT120ABU

Local _aParam := ParamIXB[1]
Local _aBotoes := {} 
Local _nI 

If AllTrim(_aParam[2][1]) == "SOLICITA"
   //_aParam[2][2] := {|| a120PID(oGetDados,oCond,oDescCond,@aHeadSCH,@aColsSCH) , U_ACOM041P() }
   _bOpcao := _aParam[2][2]
   _aParam[2][2] := {|| Eval(_bOpcao) , U_ACOM041P() }
EndIf 

For _nI := 1 To Len(_aParam)
      aAdd(_aBotoes, {_aParam[_nI][1],_aParam[_nI][2] , _aParam[_nI][3], _aParam[_nI][4]})
Next _nI

Return AClone(_aBotoes)
