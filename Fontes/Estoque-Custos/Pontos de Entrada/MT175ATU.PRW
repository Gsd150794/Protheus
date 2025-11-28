/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |11/10/2018| Chamado 26614. Ajuste na validação do estoque negativo
Josué Danich  |28/03/2019| Chamado 28765. Correção de leitura de aheader dinâmico
Alex Wallauer |15/04/2019| Chamado 28685. Validação p/ não permitir fracionamento de UM que são inteiras.
=====================================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MT175ATU
Autor-------------: Andre Lisboa
Data da Criacao---: 23/03/2017 
Descrição---------: Ponto de entrada para validar Liberação/Rejeição do Material no CQ
Parametros--------: Nenhum
Retorno-----------: .T. ou .F.
===============================================================================================================================
*/
User Function MT175ATU()
Local lRetorno 	:= .T.
Local aSalveArea:= SD7->(GetArea())
Local cProdut	:= SD7->D7_PRODUTO//SB2->B2_COD#
Local nCMAtu	:= 0//SB2->B2_CM1
Local aCMLib	:= U_VldCust(AllTrim(cProdut), aCols[1,aScan(aHeader, {|x| AllTrim(x[2]) == "D7_LOCDEST"})], dDataBase)
Local nCMLib	:= aCMLib[1]
Local nDifCM	:= GETMV("IT_DIFCM",,15)
Local nDifCM2	:= GETMV("IT_DIFCM2",,10)
Local nDifCus	:= 0 , I
Local _cNum     := SD7->D7_NUMERO
Local _cLoca1   := SD7->D7_LOCAL
Local _nQtde , _dData , _cLocal ,  _cSeq
Local _lRet1:= .T.
Local _lRet2:= .T.
Local _lValidFrac1UM:=.T.


ZZL->( DBSetOrder(3) )
If ZZL->( DBSeek( xFilial("ZZL") + RetCodUsr() ) )
   If ZZL->(FIELDPOS("ZZL_PEFRPA")) = 0 .Or. ZZL->ZZL_PEFRPA == "S"
	  _lValidFrac1UM:=.F.
   EndIf
EndIf
ZZL->( DBSetOrder(1) )
SB1->( DBSetOrder(1) )
SB1->(DBSeek(xFilial("SB1") + cProdut ))
SB2->( DBSetOrder(1) )

For I := 1 TO Len(aCols)
	
	If !Empty(aCols[I][aScan(aHeader, {|x| AllTrim(x[2]) == "D7_REC_WT"})] )
		Loop
	EndIf
	
	If _lValidFrac1UM .And. SB1->B1_TIPO == "PA"
		If SB1->B1_UM == "UN"
			_nQtde := aCols[I][aScan(aHeader, {|x| AllTrim(x[2]) == "D7_QTDE"})]
			If _nQtde <> Int(_nQtde)
				_lRet1:= .F.
			EndIf
		EndIf
		
		If  SB1->B1_SEGUM = "PC" .And. LEFT(cProdut,4)=="0006"
			_nQtSeg:= aCols[I][aScan(aHeader, {|x| AllTrim(x[2]) == "D7_QTSEGUM"})]
			If _nQtSeg <> Int(_nQtSeg)
				_lRet2:= .F.
			EndIf
		EndIf
	EndIf

   _cLocal:= aCols[I][aScan(aHeader, {|x| AllTrim(x[2]) == "D7_LOCDEST"})]
   If !SB2->(DBSeek(xFilial()+cProdut+_cLocal))
      Loop
   EndIf
   nCMAtu:= SB2->B2_CM1   

	If nCMLib > 0
		nDifCus:= (nCMAtu - nCMLib) / nCMLib
		If nDifCus < 0 
			nDifCus := (nDifCus * (-1))
		EndIf 
		nDifCus := nDifCus * 100
	
		If nDifCus >= nDifCM2 .And. nDifCus < nDifCM //Diferenca entre 51% e 70%
			If !U_ITMsg("Diferença entre valor de Custo Medio de Origem ["+aCols[1,aScan(aHeader, {|x| AllTrim(x[2]) == "D7_LOCDEST"})]+;
                           "] e Destino ["+_cLocal+"] é "+TRANSFORM(nDifCus, "@E 999.9999")+"%.","ATENÇÃO!","DESEJA PROSSEGUIR?",3,2,2)
		   	   lRetorno := .F.		
			EndIf
	 	ElseIf nDifCus >= nDifCM //Diferenca maior que 70%
			U_ITMsg("Transferência não permitida! Diferença entre valor de Custo Medio de Origem ["+aCols[1,aScan(aHeader, {|x| AllTrim(x[2]) == "D7_LOCDEST"})]+;
                              "] e Destino ["+_cLocal+"] é "+TRANSFORM(nDifCus, "@E 999.9999")+"%",;
	                "Atenção!",;
					"Favor analisar o Kardex! Se necessário, entre em contato com o Depto. de TI.",1)
			lRetorno := .F.	
	 	EndIf
	EndIf

Next

SD7->( DBSetOrder(1) )
_aLancs:={}


For I := 1 TO Len(aCols)

   _cSeq  := aCols[I][aScan(aHeader, {|x| AllTrim(x[2]) == "D7_SEQ"})]   

   If Empty(aCols[I][aScan(aHeader, {|x| AllTrim(x[2]) == "D7_ESTORNO"})] ) .OR.;
      (SD7->(DBSeek(xFilial()+_cNum+cProdut+_cLoca1+_cSeq)) .And. !Empty(SD7->D7_ESTORNO))
      Loop
   EndIf

   _dData := aCols[I][aScan(aHeader, {|x| AllTrim(x[2]) == "D7_DATA"})]
   _cLocal:= aCols[I][aScan(aHeader, {|x| AllTrim(x[2]) == "D7_LOCDEST"})]
   _nQtde := aCols[I][aScan(aHeader, {|x| AllTrim(x[2]) == "D7_QTDE"})]

   If (nPos:=aScan(_aLancs,{|D| D[1] == _dData .And. D[2] == _cLocal })) = 0
      aAdd(_aLancs,{_dData,_cLocal,_nQtde})
   Else   
      _aLancs[nPos,3]+=_nQtde
   EndIf
   
Next

If _lValidFrac1UM
	If !_lRet1
		U_ITMsg("Não é permitido fracionar a quantidade da 1a. UM de produto onde a Unid. Medida For UN.",;//,_ntipo,_nbotao,_nmenbot,_lHelpMvc,_cbt1,_cbt2,_bMaisDetalhes
		        "Validação Fracionado",;
		        "Favor informar apenas quantidades inteiras na Primeira Unidade de Medida.",1)		
		lRetorno := .F.
	EndIf
	If !_lRet2
		U_ITMsg("Não é permitido fracionar a quantidade da 2a. UM de produto do grupo 0006 onde a Unid. Medida For PC.",;//,_ntipo,_nbotao,_nmenbot,_lHelpMvc,_cbt1,_cbt2,_bMaisDetalhes
		        "Validação Fracionado",;
		        "Favor informar apenas quantidades inteiras na Segunda Unidade de Medida.",1)		
		lRetorno := .F.
	EndIf
EndIf

For I := 1 TO Len(_aLancs)

   _dData := _aLancs[I,1]
   _cLocal:= _aLancs[I,2]
   _nQtde := _aLancs[I,3]

   aSldNeg := U_VldEstRetrNeg(SD7->D7_PRODUTO,_cLocal,_nQtde,_dData)

   If Len(aSldNeg) > 0
      lRetorno := .F.
	  U_ITMsg("Não permitido, o saldo SOMADO estornado deixará o produto com saldo negativo: "+SD7->D7_PRODUTO+_cLocal+;
               " na data " +DToC(aSldNeg[1]), "Atenção!",;
   		      "Verificar o saldo através do kardex do produto",1)
   EndIf

Next

FWRestArea(aSalveArea)

Return lRetorno
