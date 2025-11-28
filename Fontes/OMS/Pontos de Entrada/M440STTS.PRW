/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
       Autor      |    Data    |                                             Motivo                                           
-------------------------------------------------------------------------------------------------------------------------------
 Josué Danich     | 09/11/2018 | Chamado 25790. Revisão para novas regras de codificação Totvs.
 Lucas Borges     | 11/10/2019 | Chamado 28346. Removidos os Warning na compilação da release 12.1.25. 
===================================================================================================================================================================
Analista         - Programador     - Inicio     - Envio    - Chamado - Motivo da Alteração
===================================================================================================================================================================
Vanderlei Alves  - Alex Wallauer   - 09/06/25   - 10/06/25 - 45229   - Tratamento para validar FWIsInCallStack("U_AOMS085B") junto com FWIsInCallStack("U_ALTERAP")
===================================================================================================================================================================
*/

//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================

#Include "TOTVS.ch"
#Include "RwMake.ch"

/*
===============================================================================================================================
Programa----------: M440STTS
Autor-------------: Josué Danich Prestes
Data da Criacao---: 12/09/2018
===============================================================================================================================
Descrição---------: PE após Liberação do Pedidos de Vendas - Chamado 26257
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/

User Function M440STTS()

Local _aSC5			:= GetArea("SC5") 
Local _aSC6			:= GetArea("SC6") 
Local _aSC9			:= GetArea("SC9") 
Local _lMensagem	:= .F.

//===============================================================================
// Verifica se o pedido teve algum item bloqueado por crédito ou estoque, e		|
// monta a consulta a ser mostrada para o usuário, caso haja algum bloqueio.	|
//===============================================================================

If Type("aCols") == "A" .And. StrZero(Len(aCols),2) == SC9->C9_ITEM

   SC9->( DBSetOrder(1) )
   SC9->( DBSeek( SC5->C5_FILIAL + SC5->C5_NUM ) )
	
   While SC9->(!Eof()) .And. SC9->C9_FILIAL = SC5->C5_FILIAL .And. SC9->C9_PEDIDO = SC5->C5_NUM
		
   	  If !(Empty(SC9->C9_BLCRED)) .Or. !(Empty(SC9->C9_BLEST))
		 _lMensagem := .T.
	     Exit
   	  EndIf
   	  SC9->( DBSkip() )
   EndDo

   If _lMensagem .And. !(FWIsInCallStack("U_ALTERAP") .Or. FWIsInCallStack("U_INCLUIC") .Or. FWIsInCallStack("U_AOMS085B")) 
      MessageLog(SC9->C9_FILIAL, SC9->C9_PEDIDO, SC9->C9_DATALIB, SC9->C9_CLIENTE, SC9->C9_LOJA)
   EndIf

EndIf


FWRestArea(_aSC5)	
FWRestArea(_aSC6)	
FWRestArea(_aSC9)	
						
Return

/*
===============================================================================================================================
Programa----------: MessageLog
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 30/11/2016
===============================================================================================================================
Descrição---------: Função criada para montar a tela de consulta armazéns opcionais
===============================================================================================================================
Parametros--------: _cFililal	- Filial do registro que está sendo liberado
------------------: _cPedido	- Número do pedido que está sendo liberado
------------------: _dDataLib	- Data da liberação do registro que está sendo liberado
------------------: _cCliente	- Código do cliente do pedido que está sendo liberado
------------------: _cLoja		- Código da loja do cliente do pedido que está sendo liberado
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MessageLog(_cFilial, _cPedido, _dDataLib, _cCliente, _cLoja)

Local _cQry			:= ""
Local _nSaldo		:= 0
Local _nY			:= 0
Local _aHeaderIt	:= {}
Local _aColsIt		:= {}
Local _aHeaderEs	:= {}
Local _aColsEs		:= {}
Local _aIn			:= {}

Private _nSldTot	:= 0
Private oMSNewGIt
Private oMSNewGEs
Private oDlgEst

aAdd( _aHeaderIt, { 'Status'			, 'CHECKBOL', '@BMP', 10, 0,,, 'C',, 'V' ,  ,  , 'legenda', 'V', 'S' } )
aAdd( _aHeaderIt, {"Item","C9_ITEM   "," ",2,0," ","€€€€€€€€€€€€€€ ","C"," "," "," "," "})
aAdd( _aHeaderIt,{"Produto","C9_PRODUTO","@!                                           ",15,0," ","€€€€€€€€€€€€€€ ","C"," "," "," "," "})
aAdd( _aHeaderIt,{"Qt Liberada","C9_QTDLIB ","@E 9,999,999.999                             ",11,3," ","€€€€€€€€€€€€€€ ","N"," ","R"," "," "})
aAdd( _aHeaderIt,{"Prc Venda","C9_PRCVEN ","@E 999,999,999.99999999                      ",18,8," ","€€€€€€€€€€€€€€ ","N"," ","R"," "," "})
aAdd( _aHeaderIt,{"Armazem","C9_LOCAL  ","@!                                           ",2,0,'ExistCpo("NNR") ',"€€€€€€€€€€€€€€ ","C","NNR   "," "," "," "})

DBSelectArea("SC9")
SC9->(DBSetOrder(1))
SC9->(DBSeek(_cFilial + _cPedido))

While !SC9->(Eof()) .And. SC9->C9_FILIAL == _cFilial .And. SC9->C9_PEDIDO == _cPedido
	If !Empty(SC9->C9_BLEST) .And. Empty(SC9->C9_BLCRED)
		aAdd(_aColsIt,{LoadBitmap(GetResources(),"BR_PRETO")   , SC9->C9_ITEM, Posicione("SB1",1,xFilial("SB1")+SC9->C9_PRODUTO,"B1_DESC"), SC9->C9_QTDLIB, SC9->C9_PRCVEN, SC9->C9_LOCAL, .F.})
	ElseIf Empty(SC9->C9_BLEST) .And. !Empty(SC9->C9_BLCRED)
		aAdd(_aColsIt,{LoadBitmap(GetResources(),"BR_AZUL")    , SC9->C9_ITEM, Posicione("SB1",1,xFilial("SB1")+SC9->C9_PRODUTO,"B1_DESC"), SC9->C9_QTDLIB, SC9->C9_PRCVEN, SC9->C9_LOCAL, .F.})
	ElseIf !Empty(SC9->C9_BLEST) .And. !Empty(SC9->C9_BLCRED)
		aAdd(_aColsIt,{LoadBitmap(GetResources(),"BR_VERMELHO"), SC9->C9_ITEM, Posicione("SB1",1,xFilial("SB1")+SC9->C9_PRODUTO,"B1_DESC"), SC9->C9_QTDLIB, SC9->C9_PRCVEN, SC9->C9_LOCAL, .F.})
	EndIf
	SC9->(DBSkip())
End

aAdd( _aHeaderEs, { 'Status'			, 'CHECKBOL', '@BMP', 10, 0,,, 'C',, 'V' ,  ,  , 'legenda', 'V', 'S' } )
aAdd( _aHeaderEs, {"Item","C9_ITEM   "," ",2,0," ","€€€€€€€€€€€€€€ ","C"," "," "," "," "})
aAdd( _aHeaderEs,{"Produto","C9_PRODUTO","@!                        ",15,0," ","€€€€€€€€€€€€€€ ","C"," "," "," "," "})
aAdd( _aHeaderEs,{"Codigo","NNR_CODIGO","@!                                           ",2,0,'ExistChav("NNR")      ',"€€€€€€€€€€€€€€°","C"," ","R"," "," "})
aAdd( _aHeaderEs,{"Descricao","NNR_DESCRI","@!                                           ",20,0,"NaoVazio()                ","€€€€€€€€€€€€€€ ","C"," ","R"," "," "})
aAdd( _aHeaderEs,{"Saldo Atual","B2_QATU   ","@E 9,999,999,999.999                         ",14,3," ","€€€€€€€€€€€€€€ ","N"," ","R"," "," "})

_cQry := "SELECT C9_ITEM, C9_PRODUTO, C9_LOCAL, NNR_CODIGO, NNR_DESCRI, NNR_I_OPC "
_cQry += "FROM " + RetSqlName("SC9") + " SC9 "
_cQry += "JOIN " + RetSqlName("NNR") + " NNR ON NNR_FILIAL = '" + xFilial("NNR") + "' AND NNR_CODIGO = C9_LOCAL AND NNR.D_E_L_E_T_ = ' ' "
_cQry += "WHERE C9_FILIAL = '" + _cFilial + "' "
_cQry += "  AND C9_PEDIDO = '" + _cPedido + "' "
_cQry += "  AND (C9_BLEST <> ' ' OR C9_BLCRED <> ' ') "
_cQry += "  AND SC9.D_E_L_E_T_ = ' ' "

dbUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQry ) , "TRBARM" , .T., .F. )

DBSelectArea("TRBARM")
TRBARM->(DBGoTop())

If !TRBARM->(Eof())
	While !TRBARM->(Eof())
		_aIn := StrTokArr(TRBARM->C9_LOCAL+";"+AllTrim(TRBARM->NNR_I_OPC),";")
		For _nY := 1 To Len(_aIn)
			DBSelectArea("SB2")
			DBSetOrder(1)
			If DBSeek(xFilial("SB2") + TRBARM->C9_PRODUTO + _aIn[_nY])
				_nSaldo := SaldoSb2()
				If _nSaldo > 0
					_nSldTot += _nSaldo
					aAdd(_aColsEs, {LoadBitmap(GetResources(),"BR_VERDE"),TRBARM->C9_ITEM,Posicione("SB1",1,xFilial("SB1")+TRBARM->C9_PRODUTO,"B1_DESC"),_aIn[_nY],AllTrim(Posicione("NNR",1,xFilial("NNR") + _aIn[_nY],"NNR_DESCRI")),_nSaldo,.F.})
				EndIf
			EndIf
		Next _nY
		TRBARM->(DBSkip())
	End
EndIf

_aColsEs := aSort(_aColsEs,,,{|x,y| x[2] < y[2]})

DBSelectArea("TRBARM")
TRBARM->(DBCloseArea())

DEFINE MSDIALOG oDlgEst TITLE "Ocorreram restrições na liberação do pedido:" FROM 000, 000  TO 520, 700 COLORS 0, 16777215 PIXEL

	@ 009, 006 Say oSayPd PROMPT "Pedido:" SIZE 022, 007 OF oDlgEst COLORS 0, 16777215 PIXEL
	@ 009, 030 Say oSayPn PROMPT _cPedido SIZE 025, 007 OF oDlgEst COLORS 16711680, 16777215 PIXEL
	@ 009, 062 Say oSayDt PROMPT "Emissão:" SIZE 025, 007 OF oDlgEst COLORS 0, 16777215 PIXEL
	@ 009, 090 Say oSay1 PROMPT _dDataLib SIZE 032, 007 OF oDlgEst COLORS 16711680, 16777215 PIXEL
	@ 009, 130 Say oSayCli PROMPT "Cliente:" SIZE 019, 007 OF oDlgEst COLORS 0, 16777215 PIXEL
	@ 009, 150 Say oSayCln PROMPT _cCliente + "/" + _cLoja + "-" + Posicione("SA1", 1, xFilial("SA1") + _cCliente + _cLoja, "A1_NOME") SIZE 149, 007 OF oDlgEst COLORS 16711680, 16777215 PIXEL
	@ 005, 305 BUTTON oBtSair PROMPT "Sair" SIZE 037, 012 OF oDlgEst ACTION oDlgEst:End() PIXEL

	oMSNewGIt := MsNewGetDados():New( 025, 006, 127, 343, 0, "AllwaysTrue", "AllwaysTrue", "", {},, 999, "AllwaysTrue", "", "AllwaysTrue", oDlgEst, _aHeaderIt, _aColsIt)

	@ 131, 006 BITMAP oBmp RESNAME "BR_PRETO" OF oDlgEst SIZE 20,20 NOBORDER PIXEL
	@ 131, 015 Say "Bloqueio Estoque" OF oDlgEst SIZE 100,10 PIXEL

	@ 131, 106 BITMAP oBmp RESNAME "BR_AZUL" OF oDlgEst SIZE 20,20 NOBORDER PIXEL
	@ 131, 115 Say "Bloqueio Crédito" OF oDlgEst SIZE 100,10 PIXEL

	@ 131, 206 BITMAP oBmp RESNAME "BR_VERMELHO" OF oDlgEst SIZE 20,20 NOBORDER PIXEL
	@ 131, 215 Say "Bloqueio Estoque/Crédito" OF oDlgEst SIZE 100,10 PIXEL

	@ 141, 006 GROUP oGrEst TO 250, 344 PROMPT "Estoques Opcionais" OF oDlgEst COLOR 0, 16777215 PIXEL

	oMSNewGEs := MsNewGetDados():New( 150, 012, 236, 339, 0, "AllwaysTrue", "AllwaysTrue", "", {},, 999, "AllwaysTrue", "", "AllwaysTrue", oDlgEst, _aHeaderEs, _aColsEs)

	@ 240, 009 BITMAP oBmp RESNAME "BR_VERDE" OF oDlgEst SIZE 20,20 NOBORDER PIXEL
	@ 240, 018 Say "Com Estoque" OF oDlgEst SIZE 100,10 PIXEL

	@ 240, 150 Say "Saldo Total:" OF oDlgEst SIZE 100,10 PIXEL
	@ 240, 220 Say AllTrim(Transform(_nSldTot,PesqPict("SC9","C9_QTDLIB"))) OF oDlgEst COLORS 0, 16777215 SIZE 100,10 PIXEL

ACTIVATE MSDIALOG oDlgEst CENTERED

Return
