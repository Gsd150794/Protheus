/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |08/02/2024| Chamado 44782. Jerry. Ajustes para a nova opcao de tipo de entrega: O = Agendado pelo Op.Log. 
Lucas Borges  |23/07/2025| Chamado 51340. Ajustar função para validação de ambiente de teste
Lucas Borges  |14/09/2025| Chamado 51799. Implementada função para validar ambiente de teste totvs.framework.environment.Type.get()
=====================================================================================================================================
*/

#Include "TOTVS.ch"

/* 
===============================================================================================================================
Programa--------: PE01NFESEFAZ
Autor-----------: Erich Buttner
Data da Criacao-: 19/02/2013
Descrição-------: Ponto de Entrada executado na Transmissão da Nota Fiscal Eletronica (XML)
Parametros------: Nenhum
Retorno---------: aRetorno[01] - aProd (Produto)
----------------: aRetorno[02] - cMensCli (Mensagem da nota)
----------------: aRetorno[03] - cMensFis (Mensagem Padrão)
----------------: aRetorno[04] - aDest (Destinatario)
----------------: aRetorno[05] - aNota (Numero da Nota Fiscal)
----------------: aRetorno[06] - aInfoItem (Informação Item do Pedido)
----------------: aRetorno[07] - aDupl (Existe Duplicata)
----------------: aRetorno[08] - aTransp (Informações Transportadora)
----------------: aRetorno[09] - aEntrega (Informações da Entrega)
----------------: aRetorno[10] - aRetirada (Informações da retirada)
----------------: aRetorno[11] - aVeiculo (Informações do Veiculo)
----------------: aRetorno[12] - aReboque (Informações do Reboque)
----------------: aRetorno[13] - aNfVincRur (Informações da NFP Vinculada)
----------------: aRetorno[14] - aEspVol (Informações da Especie e Volume)
----------------: aRetorno[15] - aNfVinc (Informações da NF-e Vinculada)
----------------: aRetorno[16] - aDetPag (Informações do grupo Forma de Pagamento)
----------------: aRetorno[17] - aObsCont (Informações do grupo Informações do Contribuinte)
----------------: aRetorno[18] - aProcRef (Informações do grupo Processo Referenciado)
----------------: aRetorno[19] - aMed  (Medicamentos)
----------------: aRetorno[20] - aLote (Rastreabilidade de produto: para permitir a rastreabilidade de qualquer produto sujeito a regulações sanitárias)
===============================================================================================================================
*/
User Function PE01NFESEFAZ()
 
Local aProd		:= ParamIXB[01]
Local cMensCli	:= ParamIXB[02]
Local cMensFis	:= ParamIXB[03]
Local aDest		:= ParamIXB[04]
Local aNota   	:= ParamIXB[05]
Local aInfoItem	:= ParamIXB[06]
Local aDupl		:= ParamIXB[07]
Local aTransp	:= ParamIXB[08]
Local aEntrega	:= ParamIXB[09]
Local aRetirada	:= ParamIXB[10]
Local aVeiculo	:= ParamIXB[11]
Local aReboque	:= ParamIXB[12]
Local aNfVincRur:= ParamIXB[13]
Local aEspVol	:= ParamIXB[14]
Local aNfVinc	:= ParamIXB[15]
Local aDetPag	:= ParamIXB[16]
Local aObsCont	:= ParamIXB[17]
Local aProcRef	:= ParamIXB[18]
Local aRetorno	:= {}
Local _nI		:= 0
Local _lAchou	:= .F.
Local _aArea

//Tipo da NF 
//[0] Entrada
//[1] Saida  

If aNota[4] == '1' //SAIDA
    _cTeste:=""
	_lBloker:=.F.
	If FunName() == "SPEDCTE" .Or. AModNot(SF2->F2_ESPECIE)=="57"
	   //NÃO TEM E-MAIL
	   _nPosEmail:=0
	ElseIf FunName() == "SPEDNFSE"
	   //aAdd(ADEST,SA1->A1_EMAIL)// POSICAO 12
	   _nPosEmail:=12
	Else
       //aAdd(ADEST,SA2->A2_EMAIL)// POSICAO 16
	   _nPosEmail:=16
	EndIf

	If _nPosEmail> 0 .And. Len(ADEST) > 0 .And. Len(ADEST) >= _nPosEmail
	      _cMailSA3:=AllTrim(Posicione("SA3",1,xFilial("SA3")+SF2->F2_VEND1,"A3_I_MAIL2"))
	      _lBloker:= (SA3->A3_I_VBROK = 'B')
	   If !Empty(_cMailSA3) .And. _lBloker
	      If Empty(ADEST[_nPosEmail])
	         ADEST[_nPosEmail] := _cMailSA3
	      Else
	         ADEST[_nPosEmail] := AllTrim(ADEST[_nPosEmail])+";"+_cMailSA3
	      EndIf
	   EndIf
	EndIf

	If !Empty( SF2->F2_CARGA )
		// Posiciona na Carga
		DBSelectArea("DAK")
		DAK->( DBSetOrder(1) )
		If DAK->( DBSeek( xFilial("DAK") + SF2->F2_CARGA ) )
			// Posiciona no Motorista
			DBSelectArea("DA4")
			DA4->( DBSetOrder(1) )
			If DA4->( DBSeek( xFilial("DA4") + DAK->( DAK_MOTORI + DAK_CAMINH ) ) )
				If Left( DA4_FORNEC , 1 ) == "A" // Autonomo
					aTransp := {}
					aAdd( aTransp , AllTrim( DA4->DA4_CGC )	)
					aAdd( aTransp , DA4->DA4_NOME			)
					aAdd( aTransp , ""						)
					aAdd( aTransp , DA4->DA4_END			)
					aAdd( aTransp , DA4->DA4_MUN			)
					aAdd( aTransp , Upper( DA4->DA4_EST )	)

					// O e-mail a ser considerado na transportadora deve ser o do cadastro do fornecedor - SA2
					DBSelectArea("SA2")
					SA2->( DBSetOrder(1) )
					If SA2->( DBSeek( xFilial("SA2") + SF2->( F2_I_CTRA + F2_I_LTRA ) ) )
						aAdd( aTransp , StrTran(SA2->A2_EMAIL," ", ""))
					Else
						aAdd( aTransp , ""				)
					EndIf
				Else
					DBSelectArea("SA2")
					SA2->( DBSetOrder(1) )
					If SA2->( DBSeek( xFilial("SA2") + SF2->( F2_I_CTRA + F2_I_LTRA ) ) )
						aTransp :={}
						aAdd( aTransp , AllTrim( SA2->A2_CGC )	)
						aAdd( aTransp , SA2->A2_NOME			)
						aAdd( aTransp , SA2->A2_INSCR			)
						aAdd( aTransp , SA2->A2_END				)
						aAdd( aTransp , SA2->A2_MUN				)
						aAdd( aTransp , Upper( SA2->A2_EST )	)
						aAdd( aTransp , StrTran(SA2->A2_EMAIL," ", "")	)
					EndIf
				EndIf
			EndIf

			// Se tem operador logistico carga adiciona o email do operador logistico para receber o danfe/xml
			DAI->(DBSetOrder(3))
			If DAI->(DBSeek(SF2->F2_FILIAL+SF2->F2_DOC+SF2->F2_SERIE))
				While SF2->F2_FILIAL == DAI->DAI_FILIAL .And. SF2->F2_DOC == DAI->DAI_NFISCA .And. SF2->F2_SERIE == DAI->DAI_SERIE
					_acnpjs := {}

					If !Empty(DAI->DAI_I_OPLO)
						DBSelectArea("SA2")
						SA2->( DBSetOrder(1) )
						If SA2->( DBSeek( xFilial("SA2") + DAI->DAI_I_OPLO + DAI->DAI_I_LOPL ) ) .And. !Empty(StrTran(SA2->A2_EMAIL," ", ""))  
							If aScan(_acnpjs,SA2->A2_CGC) == 0
								aTransp[7] := aTransp[7] + ";" + StrTran(SA2->A2_EMAIL," ", "")
								aAdd(_acnpjs,SA2->A2_CGC)
							EndIf
						EndIf
					EndIf

					DAI->(DBSkip())
				EndDo
			EndIf

			// Se tem redespacho carga adiciona o email do redespacho para receber o danfe/xml
			DAI->(DBSetOrder(3))
			If DAI->(DBSeek(SF2->F2_FILIAL+SF2->F2_DOC+SF2->F2_SERIE))
				While SF2->F2_FILIAL == DAI->DAI_FILIAL .And. SF2->F2_DOC == DAI->DAI_NFISCA .And. SF2->F2_SERIE == DAI->DAI_SERIE
					_acnpjs := {}

					If !Empty(DAI->DAI_I_TRED)
						DBSelectArea("SA2")
						SA2->( DBSetOrder(1) )
						If SA2->( DBSeek( xFilial("SA2") + DAI->DAI_I_TRED + DAI->DAI_I_LTRE ) ) .And. !Empty(StrTran(SA2->A2_EMAIL," ", ""))  
							If aScan(_acnpjs,SA2->A2_CGC) == 0
								aTransp[7] := aTransp[7] + ";" + StrTran(SA2->A2_EMAIL," ", "")
								aAdd(_acnpjs,SA2->A2_CGC)
							EndIf
						EndIf
					EndIf
					DAI->(DBSkip())
				EndDo
			EndIf

			// Posiciona no Veiculo
			DBSelectArea("DA3")
			DA3->( DBSetOrder(1) )
			If DA3->( DBSeek( xFilial("DA3") + DAK->DAK_CAMINH ) )
				aAdd( aVeiculo , DA3->DA3_PLACA		)
				aAdd( aVeiculo , DA3->DA3_ESTPLA	)
				aAdd( aVeiculo , ""					)
			EndIf
		EndIf

	// Caso nao possua carga montada
	Else
		// Posiciona no Motorista
		DBSelectArea( "DA4" )
		DA4->( DBSetOrder(1) )
		If DA4->( DBSeek( xFilial("DA4") + SF2->( F2_I_MOTOR + F2_I_VEICU ) ) )
			If Left( DA4_FORNEC , 1 ) == "A" // Autonomo
				aTransp := {}
				aAdd( aTransp , AllTrim( DA4->DA4_CGC )	)
				aAdd( aTransp , DA4->DA4_NOME			)
				aAdd( aTransp , ""						)
				aAdd( aTransp , DA4->DA4_END			)
				aAdd( aTransp , DA4->DA4_MUN			)
				aAdd( aTransp , Upper( DA4->DA4_EST )	)

				// O e-mail a ser considerado na transportadora deve ser o do cadastro do fornecedor - SA2
				DBSelectArea("SA2")
				SA2->( DBSetOrder(1) )
				If SA2->( DBSeek( xFilial("SA2") + SF2->( F2_I_CTRA + F2_I_LTRA ) ) )
					aAdd( aTransp , StrTran(SA2->A2_EMAIL," ", "")	)
				Else
					aAdd( aTransp , ""				)
				EndIf
			Else
				DBSelectArea("SA2")
				SA2->( DBSetOrder(1) )
				If SA2->( DBSeek( xFilial("SA2") + SF2->( F2_I_CTRA + F2_I_LTRA ) ) )
					aTransp := {}
					aAdd( aTransp , AllTrim( SA2->A2_CGC )	)
					aAdd( aTransp , SA2->A2_NOME			)
					aAdd( aTransp , SA2->A2_INSCR			)
					aAdd( aTransp , SA2->A2_END				)
					aAdd( aTransp , SA2->A2_MUN				)
					aAdd( aTransp , Upper( SA2->A2_EST )	)
					aAdd( aTransp , StrTran(SA2->A2_EMAIL," ", "")	)
				EndIf
			EndIf
		EndIf

		// Posiciona no Veiculo
		DBSelectArea("DA3")
		DA3->( DBSetOrder(1) )
		If DA3->( DBSeek( xFilial("DA3") + SF2->F2_I_VEICU ) )
			aAdd( aVeiculo , DA3->DA3_PLACA		)
			aAdd( aVeiculo , DA3->DA3_ESTPLA	)
			aAdd( aVeiculo , ""					)
		EndIf
	EndIf
    
	cMensCli := AllTrim(SF2->F2_I_MENSA)+" "+AllTrim(SF2->F2_I_MENOT)//soma o Novo campo da meansagem do Tratamento da Operação Triangular
	
    If !Empty(SF2->F2_I_NTRIA)  //SF2 JÁ ESTA POSICIONADO 
       If Posicione("SA1",1,xFilial("SA1")+SF2->(F2_CLIENTE+F2_LOJA),"A1_I_OBRAD") = "S"
           _nMenRemessa:=AllTrim(SF2->F2_I_NTRIA)//" CONFORME NOTA DE VENDA DO ADQUIRENTE ORIGINARIO "+SF2->F2_I_NTRIA+" SERIE "+SF2->F2_I_STRIA+" EMITIDA DIA "+DToC(SF2->F2_I_DTRIA)
		   cMensCli+=_nMenRemessa
		EndIf
	EndIf
	
	cMensFis += Chr(13) + Chr(10) +" "+ SF2->F2_I_MENFI

	// Adiciona placa do veículo nas informações adicionais pois na versão 4.00 a informação não pode 
	// constar nos campos próprios
	cMensCli += IIf( Len(aVeiculo)>0 , "Placa do Veiculo: "+ SubStr(aVeiculo[1],1,3)+"-"+SubStr(aVeiculo[1],4,4)+"/"+aVeiculo[2]+" " , "" )

	// Apresentar nas msgs adicionais de qual pedido de venda se refere a NFe
	cMensCli += IIf( !Empty( AllTrim( SF2->F2_CARGA ) ) , "Carga: "+ AllTrim( SF2->F2_CARGA ) +" " , "" )

	If At( "Pedido Interno: "+ AllTrim( SD2->D2_PEDIDO ) , cMensCli ) > 0
		cMensCli += ""
	Else
		cMensCli += " Pedido Interno: "+ AllTrim( SD2->D2_PEDIDO )
	EndIf

	DBSelectArea("SC6")
	SC6->( DBSetOrder(1) )
	SC6->( DBSeek( xFilial("SC6") + SD2->D2_PEDIDO ) )

	cPedCli := ""

	While SC6->( !Eof() ) .And. SD2->D2_PEDIDO == SC6->C6_NUM .And. xFilial("SC6") = SD2->D2_FILIAL
		cPedCli += IIf( AllTrim(SC6->C6_PEDCLI) $ cPedCli .Or. Empty( SC6->C6_PEDCLI ) , "" , AllTrim(SC6->C6_PEDCLI) +" , " )
	    SC6->( DBSkip() )
	EndDo

	If !Empty( AllTrim(cPedCli) )
		If At( "Pedido Cliente: "+ AllTrim(cPedCli) , cMensCli ) > 0
			cMensCli += ""
		Else
			cMensCli += " Pedido Cliente: "+ AllTrim(cPedCli)
		EndIf
	EndIf

    SC5->(DBSetOrder(1))
    SC5->(DBSeek(xFilial("SC5")+SD2->D2_PEDIDO))

	//Analisa data de entrega para imprimir a data ou entrega imediata
	ctipEnt		:= SC5->C5_I_AGEND//GetAdvFVal( "SC5" , "C5_I_ AGEND" , xFilial("SC5") + SD2->D2_PEDIDO , 1 , "" )
	dDtEnt		:= SC5->C5_I_DTENT//GetAdvFVal( "SC5" , "C5_I_ DTENT" , xFilial("SC5") + SD2->D2_PEDIDO , 1 , "" )

	If ctipEnt $ 'I/O' .And. dDtEnt <= Date()
		cMensCli	+= " Data de Entrega: ENTREGA IMEDIATA "
	ElseIf ctipEnt $ 'I/O' .And. dDtEnt > Date()
		cMensCli	+= " Data de Entrega: " + DToC(dDtEnt)
	ElseIf !ctipEnt $ 'I/O'
		cMensCli	+= " Data de Entrega: " + DToC(dDtEnt)
	EndIf
 
	//Carrega mensagem de hora de entrega
	chorent		:= SC5->C5_I_HORP //GetAdvFVal( "SC5" , "C5_I_HORP" , xFilial("SC5") + SD2->D2_PEDIDO , 1 , "" )
	If !Empty(chorent)	
		cMensCli += " Cliente recebe: " + chorent		
	EndIf
		
	If !Empty( AllTrim(SC5->C5_I_PEDDW ) )
		cMensCli += " Pedido Broker: "+ AllTrim(SC5->C5_I_PEDDW )
	EndIf
	
	For _nI := 1 To Len( aProd )
		aProd[_nI][4] := GETADVFVAL( "SB1" , "B1_DESC" , xFilial("SB1") + aProd[_nI][2] , 1 , '' )
	Next _nI

	// Se parâmetro IT_ARRPRC For igual a S para a filial atual, não existir desconto para o item por desconto
	// comercial ou de impostos, então irá garantir que o preço x quantidade é igual ao valor total do item
	If  AllTrim(SuperGetMV("IT_ARRPRC",.T.,"N")) == "S"
		_nI := 1
		_aArea := SD2->(GetArea())
		_lAchou := .F.

		While _nI <=  Len(aProd)
			DBSelectArea("SD2")
			SD2->( DBSetOrder(3) ) //D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM
			SD2->( DBGoTop())

			_lAchou :=  SD2->( DBSeek( xFilial("SD2") + SF2->F2_DOC + SF2->F2_SERIE + SF2->F2_CLIENTE + SF2->F2_LOJA + aProd[_nI][02] + aInfoItem[_nI][04] ) )

			If _lAchou .And. SD2->D2_DESCZFP == 0 .And. SD2->D2_DESCZFR == 0 .And. SD2->D2_DESCZFC == 0 .And. SD2->D2_DESCON == 0 .And. SF2->F2_DESCONT == 0
			   aProd[_nI][16] := SD2->D2_PRCVEN
			   If SD2->D2_PRCVEN > 0 .And. aProd[_nI][12] > 0
			   		aProd[_nI][10] := Round(aProd[_nI][12] * SD2->D2_PRCVEN,2)
			   EndIf
			EndIf
			_nI++
		EndDo
		SD2->( FWRestArea(_aArea) )
	EndIf

//Tipo da NF 
//[0] Entrada
//[1] Saida  

//ElseIf aNota[4] == '0' //ENTRADA

Else // NOTA DE ENTRADA
    _cTeste:=""
	_lTemBloker:=.F.
	If FunName() == "SPEDCTE" .Or. AModNot(SF1->F1_ESPECIE)=="57"
	   //NÃO TEM E-MAIL
	   _nPosEmail:=0
	   _cTeste:='Entrou no If FunName() == "SPEDCTE" .Or. AModNot(SF1->F1_ESPECIE)=="57" '+CHR(13)+CHR(10)
	Else
       //aAdd(ADEST,SA2->A2_EMAIL)// POSICAO 16
	   _nPosEmail:=16
	   _cTeste:='Entrou no Else / POSICAO 16 '+CHR(13)+CHR(10)
	EndIf
    If SF1->F1_TIPO = "D" .And. SF1->F1_FORMUL = "S" .And. ;
	   _nPosEmail> 0 .And. Len(ADEST) > 0 .And. Len(ADEST) >= _nPosEmail  

	   _cTeste  +='ENTROU no SF1->F1_TIPO = "D" .And. SF1->F1_FORMUL = "S" .And. Len(ADEST) > 0 .And. Len(ADEST) >= _nPosEmail "'+CHR(13)+CHR(10)

	   SD1->(DBSetOrder(1))
	   SF2->(DBSetOrder(1))
	   _cMailSA3:=""
	   If SD1->(DBSeek(SF1->F1_FILIAL+SF1->F1_DOC+SF1->F1_SERIE+SF1->F1_FORNECE+SF1->F1_LOJA)) 
	      aSD1:={}
		  While  SD1->(!Eof()) .And. SF1->F1_FILIAL+SF1->F1_DOC+SF1->F1_SERIE+SF1->F1_FORNECE+SF1->F1_LOJA = ;
		                                SD1->D1_FILIAL+SD1->D1_DOC+SD1->D1_SERIE+SD1->D1_FORNECE+SD1->D1_LOJA
		  
		     If SF2->(DBSeek(SD1->(D1_FILIAL+D1_NFORI+D1_SERIORI) ))
	            _cMailSA3+=AllTrim(Posicione("SA3",1,xFilial("SA3")+SF2->F2_VEND1,"A3_I_MAIL2"))+";"
		   	    If (SA3->A3_I_VBROK = 'B')
		   	       _lTemBloker:=.T.
		   	    EndIf
                _cTeste  +='_cMailSA3 = '+_cMailSA3+CHR(13)+CHR(10)
                _cTeste  +='SA3->A3_I_VBROK = '+SA3->A3_I_VBROK+CHR(13)+CHR(10)
			 Else	   
	            _cTeste  +='NAÕ ACHOU D1_FILIAL+D1_NFORI+D1_SERIORI+D1_FORNECE+D1_LOJA: '+SD1->D1_FILIAL+"-"+SD1->D1_NFORI+"-"+SD1->D1_SERIORI+"-"+SD1->D1_FORNECE+"-"+SD1->D1_LOJA+CHR(13)+CHR(10)		     
			 EndIf
			 Exit 
		  EndDo

	   Else
	      _cTeste  +='NAÕ ACHOU SF1->F1_FILIAL+SF1->F1_DOC+SF1->F1_SERIE+SF1->F1_FORNECE+SF1->F1_LOJA: '+SF1->F1_FILIAL+"-"+SF1->F1_DOC+"-"+SF1->F1_SERIE+"-"+SF1->F1_FORNECE+"-"+SF1->F1_LOJA+CHR(13)+CHR(10)
	   EndIf
	   _cTeste  +='ADEST[_nPosEmail] ANTES: '+ADEST[_nPosEmail]+CHR(13)+CHR(10)
	   If !Empty(_cMailSA3) .And. _lTemBloker
	      If Empty(ADEST[_nPosEmail])
	         ADEST[_nPosEmail] := _cMailSA3
	      Else
	         ADEST[_nPosEmail] := AllTrim(ADEST[_nPosEmail])+";"+_cMailSA3
	      EndIf
	   EndIf
      _cTeste+='ADEST[_nPosEmail] DEPOIS: '+ADEST[_nPosEmail]+CHR(13)+CHR(10)
	Else
	  _cTeste+='NÃO ENTROU no SF1->F1_TIPO = "'+SF1->F1_TIPO+'"  .And. SF1->F1_FORMUL = "'+SF1->F1_FORMUL+'" '+CHR(13)+CHR(10)
	  _cTeste+=' E  Len(ADEST) > 0 .And. Len(ADEST) >= _nPosEmail "'+CHR(13)+CHR(10)
	EndIf

    If _lTemBloker .Or. !totvs.framework.environment.Type.get() == '1' //1-Produção, 2-Homologação,3-Desenvolvimento
	   _cTeste+='AMBIENTE: '+AllTrim(GETENVSERVER())+CHR(13)+CHR(10)
	   If Type("__cUserId") = "C"
	      _cTeste+='USUARIO: '+UsrFullName(__cUserId)+CHR(13)+CHR(10)
	   EndIf
       _cFileNome:="\temp\pe01nfesefaz_"+AllTrim(SF1->F1_FILIAL)+"_"+AllTrim(SF1->F1_DOC)+"_"+AllTrim(SF1->F1_SERIE)+"_"+AllTrim(+SF1->F1_FORNECE)+"_"+AllTrim(SF1->F1_LOJA)+".TXT"
       MemoWrite(_cFileNome,_cTeste)
	EndIf

	cMensCli	:= SF1->F1_I_MENSA
	cMensFis	+= Chr(13) + Chr(10) +" "+ SF1->F1_I_MENFI

	If !Empty( SF1->F1_L_LINHA )
		DBSelectArea("ZL3")
		ZL3->( DBSetOrder(1) )
		If ZL3->( DBSeek( xFilial("ZL3") + SF1->F1_L_LINHA ) )
			DBSelectArea("SA2")
			SA2->( DBSetOrder(1) )
			If SA2->( DBSeek( xFilial("SA2") + ZL3->( ZL3_FRETIS + ZL3_FRETLJ ) ) )
				aTransp := {}
				aAdd( aTransp , AllTrim( SA2->A2_CGC )	)
				aAdd( aTransp , SA2->A2_NOME			)
				aAdd( aTransp , SA2->A2_INSCR			)
				aAdd( aTransp , SA2->A2_END				)
				aAdd( aTransp , SA2->A2_MUN				)
				aAdd( aTransp , Upper( SA2->A2_EST )	)
				aAdd( aTransp , StrTran(SA2->A2_EMAIL," ", "")	)
			EndIf
		EndIf
	Else
		// Posiciona no Motorista
		DBSelectArea("DA4")
		DA4->( DBSetOrder(1) )
		If DA4->( DBSeek( xFilial("DA4") + SF1->( F1_I_MOTOR + F1_I_VEICU ) ) )
			If Left( DA4_FORNEC , 1 ) == "A" // Autonomo
				aTransp := {}
				aAdd( aTransp , AllTrim( DA4->DA4_CGC )	)
				aAdd( aTransp , DA4->DA4_NOME			)
				aAdd( aTransp , ""						)
				aAdd( aTransp , DA4->DA4_END			)
				aAdd( aTransp , DA4->DA4_MUN			)
				aAdd( aTransp , Upper( DA4->DA4_EST )	)

				// O e-mail a ser considerado na transportadora deve ser o do cadastro do fornecedor - SA2
				DBSelectArea("SA2")
				SA2->( DBSetOrder(1) )
				If SA2->( DBSeek( xFilial("SA2") + DA4->( DA4_FORNEC + DA4_LOJA ) ) )
					aAdd( aTransp , StrTran(SA2->A2_EMAIL," ", "")	)
				Else
					aAdd( aTransp , ""				)
				EndIf
			Else
				DBSelectArea("SA2")
				SA2->( DBSetOrder(1) )
				If SA2->( DBSeek( xFilial("SA2") + DA4->( DA4_FORNEC + DA4_LOJA ) ) )
					aTransp := {}
					aAdd( aTransp , AllTrim( SA2->A2_CGC )	)
					aAdd( aTransp , SA2->A2_NOME			)
					aAdd( aTransp , SA2->A2_INSCR			)
					aAdd( aTransp , SA2->A2_END				)
					aAdd( aTransp , SA2->A2_MUN				)
					aAdd( aTransp , Upper( SA2->A2_EST )	)
					aAdd( aTransp , StrTran(SA2->A2_EMAIL," ", "")	)
				EndIf
			EndIf
		EndIf

		// Posiciona no Veiculo
		DBSelectArea("DA3")
		DA3->( DBSetOrder(1) )
		If DA3->( DBSeek( xFilial("DA3") + SF1->F1_I_VEICU ) )
			aAdd( aVeiculo , DA3->DA3_PLACA		)
			aAdd( aVeiculo , DA3->DA3_ESTPLA	)
			aAdd( aVeiculo , ""					)
		EndIf
	EndIf

	// Adiciona placa do veículo nas informações adicionais pois na versão 4.00 a informação não pode 
	// constar nos campos próprios
	cMensCli += IIf( Len(aVeiculo)>0 , "Placa do Veiculo: "+ SubStr(aVeiculo[1],1,3)+"-"+SubStr(aVeiculo[1],4,4)+"/"+aVeiculo[2]+" " , "" )
EndIf

cMensFis := StrTran( cMensFis , CHAR(10) , ";" )
cMensFis := StrTran( cMensFis , CHAR(13) , ";" )
cMensCli := StrTran( cMensCli , CHAR(10) , ";" )
cMensCli := StrTran( cMensCli , CHAR(13) , ";" )

aAdd( aRetorno , aProd		)
aAdd( aRetorno , cMensCli	)
aAdd( aRetorno , cMensFis	)
aAdd( aRetorno , aDest		)
aAdd( aRetorno , aNota		)
aAdd( aRetorno , aInfoItem	)
aAdd( aRetorno , aDupl		)
aAdd( aRetorno , aTransp	)
aAdd( aRetorno , aEntrega	)
aAdd( aRetorno , aRetirada	)
aAdd( aRetorno , aVeiculo	)
aAdd( aRetorno , aReboque	)
aAdd( aRetorno , aNfVincRur	)
aAdd( aRetorno , aEspVol	)
aAdd( aRetorno , aNfVinc	)
aAdd( aRetorno , aDetPag	)
aAdd( aRetorno , aObsCont	)
aAdd( aRetorno , aProcRef	)

Return( aRetorno )
