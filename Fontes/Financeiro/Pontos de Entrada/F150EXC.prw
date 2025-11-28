/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Igor Melgaço  |19/06/2024| Chamado 47533. Ajuste de nova regra para clientes que faturam venda Triangular.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: F150EXC
Autor-------------: Fabiano Dias
Data da Criacao---: 09/07/2010
Descrição---------: Ponto de entrada para efetuar filtro nos titulos que vao compor o arquivo CNAB de envio ao banco SP.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function F150EXC

Local _lRet       := .T.

If AllTrim(MV_PAR05) == '001' .And. AllTrim(MV_PAR06) == '33073' .And. AllTrim(MV_PAR07) == '149497'
	
	If AllTrim(MV_PAR08) == '019'
		
		If Len(AllTrim(SE1->E1_NUMBCO)) > 0
			_lRet:= .F.
		EndIf
		
	ElseIf AllTrim(MV_PAR08) == '043'
		
		If Len(AllTrim(SE1->E1_NUMBCO)) == 0
			_lRet:= .F.
		EndIf
		
	EndIf
	
// HEDER - 12/05/11 - Validacao para nova conta 5919-6
ElseIf AllTrim(MV_PAR05) == '001' .And. AllTrim(MV_PAR06) == '33073' .And. AllTrim(MV_PAR07) == '59196'
	
	If AllTrim(MV_PAR08) == '019'
		
		If Len(AllTrim(SE1->E1_NUMBCO)) == 0
			_lRet:= .F.
		EndIf
		
	EndIf
	
EndIf

If _lRet
   _lRet := U_F150EXCCli(SE1->E1_CLIENTE,SE1->E1_FILIAL,SE1->E1_NUM,SE1->E1_PREFIXO)
EndIf

Return _lRet

/*
===============================================================================================================================
Programa--------: F150EXCCli
Autor-----------: Igor Melgaço
Data da Criacao-: 19/06/2024
Descrição-------: Rotina de validação do Título para geração do CNAB ou Impressão do Boleto.
Parametros------: _cFilial,_cNum,_cPrefixo
Retorno---------: _lRet
===============================================================================================================================
*/  
User Function F150EXCCli(_cCliente,_cFilial,_cNum,_cPrefixo)
Local _lRet       := .T.
Local _cNumPedido := ""
Local _cNumOper   := ""
Local _cClientes  := U_ItGetMv("IT_CLICNAB","014124|018171|062970")
Local _cOper      := U_ItGetMv("IT_OPCNAB","05")

If _cCliente $ _cClientes

   _cNumPedido := Posicione("SF2",1,_cFilial+_cNum+_cPrefixo,"F2_I_PEDID")
   _cNumOper   := Posicione("SC5",1,_cFilial+_cNumPedido,"C5_I_OPER")

   If  _cNumOper $ _cOper
      _lRet := .F.
   Else
      _lRet := .T.
   EndIf
   
EndIf

Return _lRet
