/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz     |10/04/2018| Chamado 23960. Ajustes nas entrega e devolução de EPI, para impressão correta dos comprovantes.
Alex Wallauer |11/06/2018| Chamado 29619. Nova validação de saldo do Produto do aramzem digitado e do 05.
=====================================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: AMDT002
Autor-------------: Josué Danich Prestes
Data da Criacao---: 01/09/2015
Descrição---------: Preenche armazém de EPI e valida quantidade selecionada com saldo de armazém padrão de EPI
Parametros--------: Nenhum
Retorno-----------: _lRet - lógico validando ou não o campo de quantidade
===============================================================================================================================
*/
User Function AMDT002

Local _aArea 		:= FWGetArea()
Local _cprod 		:= ""
Local _lRet 		:= .T.
Local _nsaldo 	:= 0
Local _cArmaz 	:= U_ITGETMV( "IT_ESTEPI" , "00" )

//verifica se já não tem SA
If .not. Empty(AllTrim(acols[n][aScan(aHEADER, {|x| AllTrim(Upper(X[2])) == "TNF_NUMSA" })]))

	alert("Entrega já possui SA!")
	_lRet := .F.
	
EndIf

//Se For a função Funcionário x EPI
If AllTrim(funname()) == "MDTA695" .And. _lRet
	
	//grava código de produto a partir do campo TNF_CODEPI que contém o produto selecionado
	_cprod	:= AllTrim(acols[n][aScan(aHEADER, {|x| AllTrim(Upper(X[2])) == "TNF_CODEPI" })])

	If Type("M->TNF_LOCAL") <> "U"
		_cArmaz := M->TNF_LOCAL
	Else
		_cArmaz	:= AllTrim(acols[n][aScan(aHEADER, {|x| AllTrim(Upper(X[2])) == "TNF_LOCAL" })])
	EndIf

EndIf

//se For a função EPI x funcionário
If AllTrim(funname()) == "MDTA630" .And. _lRet

	//grava código de produto a partir da sb1 posicionada
	_cprod := SB1->B1_COD
	
	//preenche campo de armazém
	acols[n][aScan(aHEADER, {|x| AllTrim(Upper(X[2])) == "TNF_LOCAL" })] :=  _cArmaz 	

EndIf

//busca saldo disponível
DBSelectArea("SB2")

If DBSeek(xFilial("SB2") + PadR(_cprod,15) + _cArmaz)

	_nsaldo := SaldoSb2()
	
EndIf

If Type("M->TNF_QTDENT") <> "U"
	_cQtdEnt := M->TNF_QTDENT
Else
	_cQtdEnt := acols[n][aScan(aHEADER, {|x| AllTrim(Upper(X[2])) == "TNF_QTDENT" })]
EndIf

//faz validação
If _nsaldo < _cQtdEnt .And. _lRet

   _aSaldo  := {}     	
   _nSaldo05:= 0 
   If _cArmaz <> "05"
      If SB2->(DBSeek(xFilial("SB2")+PadR(_cProd,15)+"05"))
   	     FWMsgRun(, {|| _aSaldo := CalcEst(_cProd,"05",date()+1)}, "Aguarde...", "Validando estoque....")
   	     _nSaldo05 := _aSaldo[1] - SB2->B2_RESERVA - SB2->B2_QACLASS - SB2->B2_QEMPSA - SB2->B2_QEMP
   	     If _nSaldo05 < 0
   	  	    _nSaldo05 := 0
   	     EndIf
      EndIf 
   EndIf 

	U_ITMsg("Somente é possível entregar até o saldo disponível: " + AllTrim(Transform(_nsaldo,"@E 9,999,999.99")),"Saldo Indisponível",;
			If(_nSaldo05>0,"Existe saldo no armazem de reuso 05: "+CRLF+CRLF+"Saldo do Armazem de reuso 05: "+AllTrim(Transform(_nSaldo05,'@E 999,999,999.99')),;
			               "Dúvidas, consulte o Almoxarifado."),1)
	
	_lRet := .F.
	
EndIf

If _lRet
   _aSaldo := {}
   _nSaldo := 0
   If SB2->(DBSeek(xFilial("SB2")+PadR(_cProd,15)+_cArmaz))
   	  FWMsgRun(, {|| _aSaldo := CalcEst(_cProd,_cArmaz,date()+1)}, "Aguarde...", "Validando estoque....")
   	  _nsaldo := _aSaldo[1] - SB2->B2_RESERVA - SB2->B2_QACLASS - SB2->B2_QEMPSA - SB2->B2_QEMP
   	  If _nsaldo < 0
   	  	 _nsaldo := 0
   	  EndIf
   EndIf 
   _nSolic := CalcSolic(_cProd,_cArmaz)
   
   If _nSaldo - _nSolic - _cQtdEnt < 0 .And. _lRet

       _nSaldo05 := 0      	
       If _cArmaz <> "05"
          If SB2->(DBSeek(xFilial("SB2")+PadR(_cProd,15)+"05"))
       	     FWMsgRun(, {|| _aSaldo := CalcEst(_cProd,"05",date()+1)}, "Aguarde...", "Validando estoque....")
       	     _nSaldo05 := _aSaldo[1] - SB2->B2_RESERVA - SB2->B2_QACLASS - SB2->B2_QEMPSA - SB2->B2_QEMP
       	     If _nSaldo05 < 0
       	  	    _nSaldo05 := 0
       	     EndIf
          EndIf 
       EndIf 

   	   U_ITMsg("Já existem solicitações a serem atendidas para esse produto:" + CRLF + CRLF + ;
   	   			" Saldo atual: "+Transform(_nSaldo,'@E 999,999,999.99') + CRLF + CRLF + ;
   	   			" Total solicitações incluindo esta: "+Transform(_nSolic+_cQtdEnt,'@E 999,999,999.99');
   	   			,"Saldo Indisponível",;
			    If(_nSaldo05>0,"Existe saldo no armazem de reuso 05: "+CRLF+CRLF+"Saldo do Armazem de reuso 05: "+AllTrim(Transform(_nSaldo05,'@E 999,999,999.99')),;
				               "Dúvidas, consulte o Almoxarifado."),1)
   	   _lRet := .F.
   EndIf

EndIf

FWRestArea(_aArea)

Return _lRet

/*
===============================================================================================================================
Programa----------: CalcSolic
Autor-------------: Guilherme Diogo 
Data da Criacao---: 07/01/2013 
Descrição---------: Calcula solicitacoes nao atendidas.
Parametros--------: 	_cProd - Produto
						_cArmz - Armazém
Retorno-----------:  _nQtd - Quantidade não atendida
===============================================================================================================================
*/
Static Function CalcSolic(_cProd,_cArmz)

Local _nQtd      := 0
Local _cQuery    := ""
Local _cAliasSCP := GetNextAlias()

_cQuery := " SELECT  SUM(CP.CP_QUANT - CP.CP_QUJE) QUANT "
_cQuery += " FROM " + RetSqlName("SCP") + " CP "
_cQuery += " WHERE CP.D_E_L_E_T_ = ' ' "
_cQuery += " AND CP.CP_STATUS = ' ' "
_cQuery += " AND CP.CP_FILIAL = '"+xFilial("SCP")+"' " 
_cQuery += " AND CP.CP_PRODUTO = '"+_cProd+"' "
_cQuery += " AND CP.CP_LOCAL = '"+_cArmz+"' "
_cQuery += " AND CP.CP_PREREQU = ' ' " 

dbUseArea( .T., "TOPCONN", TcGenQry(,,_cQuery), _cAliasSCP, .T., .F. )

If (_cAliasSCP)->(!Eof())

	_nQtd := (_cAliasSCP)->QUANT	

EndIf

DBSelectArea(_cAliasSCP)
(_cAliasSCP)->(DBCloseArea())

Return _nQtd
