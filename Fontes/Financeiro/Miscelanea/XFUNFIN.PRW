/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallaur  |07/04/2022| Chamado 39709. Variavel cNumSeq altera para _cNumSeq.
Igor Melgaço  |14/02/2025| Chamado 49912. Ajustes para Nova regra de Fator de Vencimento FEBRABAN.
Igor Melgaço  |26/08/2025| Chamado 47930. Ajuste para impressão do QrCode.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: XFUNFIN
Autor-------------: Josué Danich Prestes
Data da Criacao---: 03/10/2017
Descrição---------: Rotinas genéricas para utilização nos desenvolvimentos do módulo FIN
===============================================================================================================================
*/

/*
===============================================================================================================================
Programa----------: Ret_cBarra
Autor-------------: Renato de Morcerf
Data da Criacao---: 08/09/2008
Descrição---------: Retorna os Strings para impressão do Boleto
Parametros--------: CB = String para o cód.barras, RN = String com o número digitável
------------------: Cobrança não identificada, número do boleto = Título + Parcela
Retorno-----------: { cCodBarra , cLinDig , cNossoNum }
===============================================================================================================================
*/

User Function Ret_cBarra(cBanco,cAgencia,cConta,cDacCC,cCarteira,cNroDoc,nValor,dvencimento,cConvenio,cSequencial,_lTemDesc,_cParcela)

Local cCodEmp		:= StrZero(Val(SubStr(cConvenio,1,6)),6)
Local _cNumSeq		:= StrZero(Val(cSequencial),5)
Local blvalorfinal	:= StrZero(Round((Round(nValor,2))*(100*10)/10,0),10)
Local cNNumSDig		:= cCpoLivre := cCBSemDig := cCodBarra := cNNum := cFatVenc := ''
Local cNossoNum		:= ""
Local cNumBco    	:= ""
Local cBcos7dig     :=  AllTrim(SuperGetMv("IT_BCOS7DI",,'001'))

_cParcela := u_NumParcela(_cParcela)

//Fator Vencimento - POSICAO DE 06 A 09
If dvencimento >= CtoD("22/02/2025")
	cFatVenc := StrZero(dvencimento - CtoD("22/02/2025") + 1000,4) 
Else
	cFatVenc := StrZero(dvencimento - CtoD("07/10/1997"),4)
EndIf

//Campo Livre (Definir campo livre com cada banco)
If SubStr(cBanco,1,3) == "001"  // Banco do brasil

	If Len(AllTrim(cConvenio)) == 7
		
		If Empty(AllTrim(TRB->E1_NUMBCO)) .Or. !_lReimprime 
			//Nosso Numero sem digito
			cNNumSDig := AllTrim(cConvenio)+StrZero(Val(cSequencial),10)
			//Nosso Numero com digito
			cNNum := cNNumSDig
			//Nosso Numero para impressao
			cNossoNum := cNNumSDig

			cNumBco  := StrZero(Val(cSequencial),10)

		Else
			nTam := Len(AllTrim(TRB->E1_NUMBCO)) 
			If nTam > 10
				cNossoNum := TRB->E1_NUMBCO
				cNumBco   := Subs(cNossoNum,8,Len(cNossoNum)-7)
			Else
				cNossoNum := AllTrim(cConvenio)+TRB->E1_NUMBCO
				cNumBco  := TRB->E1_NUMBCO
			EndIf

		EndIf
		
		cCpoLivre := "000000"+AllTrim(cNossoNum)+ cCarteira
		
	Else
	
		If Empty(AllTrim(TRB->E1_NUMBCO)) .Or. !_lReimprime 
			//Nosso Numero sem digito
			cNNumSDig := cCodEmp+_cNumSeq
			//Nosso Numero com digito
			cNNum := cNNumSDig + u_modulo11(cNNumSDig,SubStr(cBanco,1,3))
			//Nosso Numero para impressao
			cNossoNum := cNNumSDig +"-"+ u_modulo11(cNNumSDig,SubStr(cBanco,1,3))
		Else
			cNossoNum := Transform(TRB->E1_NUMBCO,"@R 99999999999-9") 
			cNNumSDig := SubStr(AllTrim(TRB->E1_NUMBCO),1,Len(AllTrim(TRB->E1_NUMBCO))-1) 
		EndIf
		
		cCpoLivre := cNNumSDig+cAgencia + StrZero(Val(cConta),8) + cCarteira
		cNumBco := Subs(cNNumSDig,Len(cCodEmp)+1,Len(cNNumSDig)-(Len(cCodEmp)+1))
		
	EndIf
	cNumBco  := IIf("001" $ cBcos7dig,cNumBco,cNossoNum)

ElseIf SubStr(cBanco,1,3) == "389" // Banco mercantil

	//Nosso Numero sem digito
	cNNumSDig := cAgencia+"30"+cCarteira+StrZero(Val(cSequencial),6)
	//Nosso Numero
	cNNum := "30"+cCarteira+ StrZero(Val(cSequencial),6) + u_modulo11(cNNumSDig,SubStr(cBanco,1,3))
	//Nosso Numero para impressao
	cNossoNum := "30"+cCarteira+ StrZero(Val(cSequencial),6) +"-"+ u_modulo11(cNNumSDig,SubStr(cBanco,1,3))
	cCpoLivre := cAgencia + cNNum + StrZero(Val(SubStr(cConvenio,1,9)),9)+IIf(_lTemDesc,"0","2")
	
	cNumBco := StrZero(Val(cSequencial),6)

	cNumBco  := IIf("389" $ cBcos7dig,cNumBco,cNossoNum)
ElseIf SubStr(cBanco,1,3) == "237" // Banco bradesco

	If Empty(AllTrim(TRB->E1_NUMBCO)) .Or. !_lReimprime 
		cNNumSDig := cCarteira + StrZero(Val(cSequencial),11)  
		//Nosso Numero
		cNNum := cCarteira + '/' + StrZero(Val(cSequencial),11) + '-' + AllTrim(  u_modulo11( cNNumSDig,SubStr(cBanco,1,3) ) ) 
		//Nosso Numero para impressao
		cNossoNum := cCarteira + '/' + StrZero(Val(cSequencial),11) + '-' + AllTrim(  u_modulo11( cNNumSDig,SubStr(cBanco,1,3) ) ) 
		cCpoLivre := cAgencia + cNNumSDig + StrZero(Val(cConta),7) + "0" 
	Else
		cNossoNum := Left(TRB->E1_NUMBCO,2)+"/" + SubStr(TRB->E1_NUMBCO,3,11) + "-" + Right(AllTrim(TRB->E1_NUMBCO),1)
		cNNumSDig := Left(AllTrim(TRB->E1_NUMBCO),Len(AllTrim(TRB->E1_NUMBCO))-1) 
	EndIf
	
	cCpoLivre := cAgencia + cNNumSDig + StrZero(Val(cConta),7) + "0"  
	
	cNumBco := StrZero(Val(cSequencial),11)
	
	cNumBco  := IIf("237" $ cBcos7dig,cNumBco,cNossoNum)
ElseIf SubStr(cBanco,1,3) == "453"  // Banco rural

	//Nosso Numero sem digito
	cNNumSDig := StrZero(Val(cSequencial),7)
	//Nosso Numero
	cNNum := cNNumSDig + AllTrim( Str( u_modulo10( cNNumSDig ) ) )
	//Nosso Numero para impressao
	cNossoNum := cNNumSDig +"-"+ AllTrim( Str( u_modulo10( cNNumSDig ) ) )
	cCpoLivre := "0"+StrZero(Val(cAgencia),3) + StrZero(Val(cConta),10)+cNNum+"000"
	
	cNumBco := cNNumSDig 

	cNumBco  := IIf("453" $ cBcos7dig,cNumBco,cNossoNum)
ElseIf SubStr(cBanco,1,3) == "341"  // Banco Itau

	If !(AllTrim(cCarteira) $ "126,131,146,150,168")
		//Nosso Numero sem digito
		cNNumSDig := cCarteira+StrZero(Val(cSequencial),8)
		//Nosso Numero
		cNNum := cCarteira+StrZero(Val(cSequencial),8) + AllTrim( Str( u_modulo10( StrZero(Val(cAgencia),4) + StrZero(Val(cConta),5)+cNNumSDig ) ) )
		//Nosso Numero para impressao
		cNossoNum := cCarteira+"/"+StrZero(Val(cSequencial),8) +'-' + AllTrim( Str( u_modulo10( StrZero(Val(cAgencia),4) + StrZero(Val(cConta),5) + cNNumSDig ) ) )
	Else
		//Nosso Numero sem digito
		cNNumSDig := cCarteira+StrZero(Val(cNroDoc),6)+ _cParcela
		//Nosso Numero
		cNNum := cCarteira+StrZero(Val(cNroDoc),6) + _cParcela + AllTrim( Str( u_modulo10( StrZero(Val(cAgencia),4) + StrZero(Val(cConta),5)+cNNumSDig ) ) )
		//Nosso Numero para impressao
		cNossoNum := cCarteira+"/"+StrZero(Val(cNroDoc),6)+ _cParcela +'-' + AllTrim( Str( u_modulo10( StrZero(Val(cAgencia),4) + StrZero(Val(cConta),5) + cNNumSDig ) ) )
	EndIf
	
	cCpoLivre := cNNumSDig+AllTrim( Str( u_modulo10( StrZero(Val(cAgencia),4) + StrZero(Val(cConta),5)+cNNumSDig ) ) )+StrZero(Val(cAgencia),4) + StrZero(Val(cConta),5)+AllTrim( Str( u_modulo10( StrZero(Val(cAgencia),4) + StrZero(Val(cConta),5) ) ) )+"000"
	
	cNumBco := cNNumSDig 

	cNumBco  := IIf("341" $ cBcos7dig,cNumBco,cNossoNum)
ElseIf SubStr(cBanco,1,3) == "399"  // Banco HSBC

	//Nosso Numero sem digito
	cNNumSDig := StrZero(Val(SubStr(cConvenio,1,5)),5)+StrZero(Val(cSequencial),5)
	//Nosso Numero
	cNNum := cNNumSDig + u_modulo11(cNNumSDig,SubStr(cBanco,1,3))
	//Nosso Numero para impressao
	cNossoNum := cNNumSDig +"-"+ u_modulo11(cNNumSDig,SubStr(cBanco,1,3))
	cCpoLivre := cNNum+StrZero(Val(cAgencia),4) + StrZero(Val(cConta),7)+"001"
	
	cNumBco := cNNumSDig 

	cNumBco  := IIf("399" $ cBcos7dig,cNumBco,cNossoNum)
ElseIf SubStr(cBanco,1,3) == "422"  // Banco Safra

	//Nosso Numero sem digito
	cNNumSDig := StrZero(Val(cSequencial),8)
	//Nosso Numero
	cNNum := cNNumSDig + u_modulo11(cNNumSDig,SubStr(cBanco,1,3))
	//Nosso Numero para impressao
	cNossoNum := cNNumSDig +"-"+ u_modulo11(cNNumSDig,SubStr(cBanco,1,3))
	cCpoLivre := "7"+StrZero(Val(cAgencia),4) + StrZero(Val(cConta),10)+cNNum+"2"
	
	cNumBco := cNNumSDig 

	cNumBco  := IIf("422" $ cBcos7dig,cNumBco,cNossoNum)
ElseIf SubStr(cBanco,1,3) == "479" // Banco Boston

	_cNumSeq := StrZero(Val(cSequencial),8)
	cCodEmp := StrZero(Val(SubStr(cConvenio,1,9)),9)
	//Nosso Numero sem digito
	cNNumSDig := StrZero(Val(cSequencial),8)
	//Nosso Numero
	cNNum := cNNumSDig + u_modulo11(cNNumSDig,SubStr(cBanco,1,3))
	//Nosso Numero para impressao
	cNossoNum := cNNumSDig +"-"+ u_modulo11(cNNumSDig,SubStr(cBanco,1,3))
	cCpoLivre := cCodEmp+"000000"+cNNum+"8"
	
	cNumBco := cNNumSDig

	cNumBco  := IIf("479" $ cBcos7dig,cNumBco,cNossoNum)
EndIf
	
//Dados para Calcular o Dig Verificador Geral
cCBSemDig := cBanco + cFatVenc + blvalorfinal + cCpoLivre

//Codigo de Barras Completo
If Left(cBanco,3) == "237"
	cCodBarra := cBanco + u_Mod11B9(cCBSemDig) + cFatVenc + blvalorfinal + cCpoLivre
Else
	cCodBarra := cBanco + u_modulo11(cCBSemDig) + cFatVenc + blvalorfinal + cCpoLivre
EndIf

If SubStr(cBanco,1,3) == "033" //Santander

	cNossoNum 	:= PadL(AllTrim(cSequencial),13,"0")
	cCodBarra 	:= "0339 " + cFatVenc + blvalorfinal + "94846850" + cNossoNum + "0104"
	cCodBarra 	:= "0339" + u_modulo11(cCodBarra,"033") + cFatVenc + blvalorfinal + "94846850" + cNossoNum + "0104" 

	//Digito Verificador do Primeiro Campo
	cPrCpo		:= cBanco + "9" + SubStr(cCodBarra,21,4)
	cDvPrCpo	:= AllTrim(Str(u_modulo10(cPrCpo)))

	//Digito Verificador do Segundo Campo
	cSgCpo		:= SubStr(cCodBarra,25,10)
	cDvSgCpo	:= AllTrim(Str(u_modulo10(cSgCpo)))

	//Digito Verificador do Terceiro Campo
	cTrCpo		:= SubStr(cCodBarra,35,10)
	cDvTrCpo	:= AllTrim(Str(u_modulo10(cTrCpo)))

Else //Outros

	//Digito Verificador do Primeiro Campo
	cPrCpo		:= cBanco + SubStr(cCodBarra,20,5)
	cDvPrCpo	:= AllTrim(Str(u_modulo10(cPrCpo)))

	//Digito Verificador do Segundo Campo
	cSgCpo		:= SubStr(cCodBarra,25,10)
	cDvSgCpo	:= AllTrim(Str(u_modulo10(cSgCpo)))

	//Digito Verificador do Terceiro Campo
	cTrCpo		:= SubStr(cCodBarra,35,10)
	cDvTrCpo	:= AllTrim(Str(u_modulo10(cTrCpo)))

EndIf

//Digito Verificador Geral
cDvGeral	:= SubStr(cCodBarra,5,1)

//Linha Digitavel
cLindig		:= SubStr(cPrCpo,1,5) + "." + SubStr(cPrCpo,6,4) + cDvPrCpo + " "   //primeiro campo
cLinDig		+= SubStr(cSgCpo,1,5) + "." + SubStr(cSgCpo,6,5) + cDvSgCpo + " "   //segundo campo
cLinDig		+= SubStr(cTrCpo,1,5) + "." + SubStr(cTrCpo,6,5) + cDvTrCpo + " "   //terceiro campo
cLinDig		+= " " + cDvGeral              //dig verificador geral
cLinDig		+= "  " + SubStr(cCodBarra,6,4)+SubStr(cCodBarra,10,10)  // fator de vencimento e valor nominal do titulo

Return( { cCodBarra , cLinDig , cNossoNum, cNumBco} )

/*
===============================================================================================================================
Programa----------: NumParcela
Autor-------------: Renato de Morcerf
Data da Criacao---: 08/09/2008
Descrição---------: Função que retora a informação da parcela
Parametros--------: cParcela - Número da Agencia
Retorno-----------: _cRet  - Dados da Parcela
===============================================================================================================================
*/
User Function NumParcela( _cParcela )

Local _cRet := ""

If ASC( _cParcela ) >= 65 .Or. ASC( _cParcela ) <= 90
	_cRet := StrZero( Val( Chr( ASC( _cParcela ) - 16 ) ) , 2 )
Else
	_cRet := StrZero( Val( _cParcela ) , 2 )
EndIf

Return( _cRet )

/*
===============================================================================================================================
Programa----------: modulo11
Autor-------------: Renato de Morcerf
Data da Criacao---: 08/09/2008
Descrição---------: Cálculo do dígito verificador modulo 11
Parametros--------: cData - Valor de referência
------------------: cBanc - Id do Banco
Retorno-----------: D - Dígito Verificador
===============================================================================================================================
*/
User Function modulo11( cData , cBanc )

Local L		:= 0
Local D		:= 0
Local P		:= 0
Local _cRet	:= ""

If cBanc == "001"  // Banco do brasil

	L := Len(cdata)
	D := 0
	P := 10
	
	While L > 0
		P := P - 1
		D := D + (Val(SubStr(cData, L, 1)) * P)
		If P = 2
			P := 10
		End
		L := L - 1
	End
	
	D := mod(D,11)
	
	If D == 10
		D := "X"
	Else
		_cRet := AllTrim(Str(D))
	End
	
ElseIf cBanc == "237" .Or. cBanc == "341" .Or. cBanc == "389" .Or. cBanc == "453" .Or. cBanc == "399" .Or. cBanc == "422" // Bradesco/Itau/Mercantil/Rural/HSBC/Safra

	L := Len(cdata)
	D := 0
	P := 1
	
	While L > 0
		P := P + 1
		D := D + (Val(SubStr(cData, L, 1)) * P)
		If P = 7
			P := 1
		End
		L := L - 1
	End
	
	D := 11 - (mod(D,11))
	
	If (D == 1 .Or. D == 0 .Or. D == 10 .Or. D == 11) .And. (cBanc == "289" .Or. cBanc == "453" .Or. cBanc == "399")
		D := 0
	End   
	
	If cBanc == "237"
		//_cRet := IIf(D == 10  .Or. D == 11,"P", AllTrim(Str(D)))
		_cRet := IIf(D == 10 ,"P", IIf(D == 11,"0",AllTrim(Str(D))))
	Else
		_cRet := AllTrim(Str(D))
	EndIf
	
ElseIf cBanc == "479"  //BOSTON

	L := Len(cdata)
	D := 0
	P := 1
	
	While L > 0
		P := P + 1
		D := D + (Val(SubStr(cData, L, 1)) * P)
		If P = 9
			P := 1
		End
		L := L - 1
	End
	
	D := Mod(D*10,11)
	
	If D == 10
		D := 0
	End
	
	_cRet := AllTrim(Str(D))
	
ElseIf cBanc == "033"  //SANTANDER

	L := Len(cdata)
	D := 0
	P := 1
	
	While L > 0
		If L >= 1 .And. L <= 44 .And. L <> 5
			P := P + 1
			D := D + (Val(SubStr(cData, L, 1)) * P)
		EndIf
	
		If P = 9
			P := 1
		EndIf
		L := L - 1
	End
	
	D := (mod(D * 10 ,11))
	If D == 0 .Or. D == 10
		D := 1
	EndIf
		
	_cRet := AllTrim(Str(D))

Else

	L := Len(cdata)
	D := 0
	P := 1
	
	While L > 0
		P := P + 1
		D := D + (Val(SubStr(cData, L, 1)) * P)
		If P = 9
			P := 1
		End
		L := L - 1
	End
	
	D := 11 - (mod(D,11))
	
	If (D == 10 .Or. D == 11)
		D := 1
	End
	
	_cRet := AllTrim(Str(D))
	
EndIf

Return(_cRet)

/*
===============================================================================================================================
Programa----------: modulo10
Autor-------------: Renato de Morcerf
Data da Criacao---: 08/09/2008
Descrição---------: Cálculo do dígito verificador modulo 10
Parametros--------: cData - Valor de referência
Retorno-----------: D - Dígito Verificador
===============================================================================================================================
*/
User Function modulo10( cData )

Local L,D,P := 0
Local B     := .F.

L := Len(cData)  //TAMANHO DE BYTES DO CARACTER
B := .T.
D := 0     //DIGITO VERIFICADOR

While L > 0
	P := Val(SubStr(cData, L, 1))
	If (B)
		P := P * 2
		If P > 9
			P := P - 9
		End
	End
	D := D + P
	L := L - 1
	B := !B
End

D := 10 - (Mod(D,10))

If D == 10
	D := 0
End

Return( D )

/*
===============================================================================================================================
Programa----------: mod11b9
Autor-------------: Cleiton Campos
Data da Criacao---: 17/03/2009
Descrição---------: Cálculo do Dígito Verificador Modelo 11 Base 9
Parametros--------: cData - Valor de Referência
Retorno-----------: D - Dígito verificador
===============================================================================================================================
*/ 
User Function mod11b9( cData )

Local L		:= 0
Local D		:= 0
Local P		:= 0
Local _cRet	:= ""

L := Len(cdata)
D := 0
P := 1

While L > 0

	P := P + 1
	D := D + (Val(SubStr(cData, L, 1)) * P)
	
	If P = 9
		P := 1
	End
	
	L := L - 1

EndDo

D := 11 - (mod(D,11))

// Se D For igual a zero, um ou maior que nove, entao D sera igual a um. Caso contrario, nao sera alterado.
D := IIf( D == 0 .Or. D == 1 .Or. D > 9 , 1 , D )

_cRet := cValToChar(D)

Return( _cRet )

/*
===============================================================================================================================
Programa----------: Conta
Autor-------------: Renato de Morcerf
Data da Criacao---: 08/09/2008
Descrição---------: Função que retora os dados da Conta
Parametros--------: cBanco - Id do Banco
------------------: cConta - Número da Agencia
Retorno-----------: _cRet  - Dados da Conta
===============================================================================================================================
*/
User Function Conta( _cBanco , _cConta )

Local _cRet := ""

If _cBanco $ "479/389/033"
	_cRet := AllTrim( SEE->EE_CODEMP )
ElseIf _cBanco == "341"
	_cRet := StrZero( Val( SubStr( AllTrim( _cConta ) , 1 , Len( AllTrim( _cConta ) ) - 1 ) ) , 5 )
Else
	_cRet := SubStr( AllTrim( _cConta ) , 1 , Len( AllTrim( _cConta ) ) - 1 )
EndIf

Return( _cRet )

/*
===============================================================================================================================
Programa----------: Agencia
Autor-------------: Renato de Morcerf
Data da Criacao---: 08/09/2008
Descrição---------: Função que retora os dados do Banco e Agência
Parametros--------: cBanco   - Id do Banco
------------------: nAgencia - Número da Agencia
Retorno-----------: _cRet    - Dados da Agencia
===============================================================================================================================
*/
User Function Agencia( _cBanco , _nAgencia )

Local _cRet := ""

If _cBanco $ "479/389"
	_cRet := AllTrim( SEE->EE_AGBOSTO )
ElseIf _cBanco $ "341/422/033"
	_cRet := StrZero( Val( AllTrim( _nAgencia ) ) , 4 )
Else
	_cRet := SubStr( StrZero( Val( AllTrim( _nAgencia ) ) , 5 ) , 1 , 4 ) +"-"+ SubStr( StrZero( Val( AllTrim( _nAgencia ) ) , 5 ) , 5 , 1 )
EndIf

Return( _cRet )

/*
===============================================================================================================================
Programa----------: validCTR
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 31/08/2011
Descrição---------: Valida se foi efetuado o lançamento do conhecimento de transporte na rotina AOMS054
Parametros--------: _cCodFor	- Código do Fornecedor na NF
------------------: _cLojFor	- Loja do Fornecedor na NF
------------------: _cNumTit	- Número do Documento
------------------: _cPreTit	- Prefixo do Documento
Retorno-----------: Lógico - Indicando se os dados foram validados ou não
===============================================================================================================================
*/
User Function validCTR( _cCodFor , _cLojFor , _cNumTit , _cPreTit )

Local _cAlias	:= GetNextAlias()        
Local _cFiltro	:= ""
Local _lRet		:= .T.

//================================================================================
// Query para constatar se ja foi lancado o numero de CTR para o transportador 
// fornecido no documento de entrada
//================================================================================
_cFiltro := "% "
_cFiltro += "     D_E_L_E_T_ = ' ' "
_cFiltro += " AND ZZN_FILIAL = '"+ xFilial("ZZN")					+"' "
_cFiltro += " AND ZZN_FTRANS = '"+ _cCodFor							+"' "
_cFiltro += " AND ZZN_LOJAFT = '"+ _cLojFor							+"' "
_cFiltro += " AND ZZN_CTRANS = '"+ PadL(AllTrim(_cNumTit),9,"0")	+"' "
_cFiltro += " AND ZZN_SERCTR = '"+ _cPreTit							+"' "
_cFiltro += " %"

BeginSql alias _cAlias
	SELECT	COUNT(1) NUMREG
	FROM	%Table:ZZN%
	WHERE	%Exp:_cFiltro%
EndSql

If (_cAlias)->NUMREG == 0
	
	//================================================================================
	// Somente serao bloqueadas as Filiais que constam no parametro IT_FILCONH
	//================================================================================
	If cFilAnt $ AllTrim( GetMv( "IT_FILCONH" ,, '' ) )
		 MsgStop('Não existe lançamento de CTE x NFe de ' + '['+ PadL(AllTrim(_cNumTit),9,'0') +'/'+ _cPreTit +']'+;
				' Solicitar ao departamento de Logística quanto aos lançamentos necessários.', "XFUNFIN001")
		_lRet := .F.
	EndIf

EndIf

(_cAlias)->( DBCloseArea() )

Return( _lRet )

/*
===============================================================================================================================
Programa----------: NatINSS
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 23/11/2018
Descrição---------: Retorna a Natureza correta para o MV_INSS dependendo se o fornecedor é Físico ou Jurídico no documento de
					entrada
Parametros--------: Nenhum
Retorno-----------: _cNatureza - Natureza a ser utilizada na geração dos títulos de INSS
===============================================================================================================================
*/
User Function NatINSS

Local _cNatureza:= '212017'
Local _aArea	:= FWGetArea()

If FunName() $ 'MATA103/MGLT009' .And. Posicione("SA2",1,xFilial("SA2")+SF1->(F1_FORNECE+F1_LOJA),"A2_TIPO") = 'F'
	_cNatureza := '212033'
EndIf

FWRestArea(_aArea)

Return(_cNatureza)
