/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz     |07/05/2018| Chamado 24726. Padronização dos cabeçalhos dos fontes e funções do módulo financeiro.
Lucas Borges  |09/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: AFIN012
Autor-------------: Flavio Novaes / Emerson Dias
Data da Criacao---: 23/04/2009
Descrição---------: Funções Genéricas do CNAB.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/

/*
===============================================================================================================================
Função------------: Pagide()
Autor-------------: Emerson Dias
Data da Criacao---: 23/04/2009
Descrição---------: Funcao chamada no CNAB a Pagar Banco Bradesco para ajustar os campos 3 a 17 dos detalhes para CPF ou CNPJ.  
Parametros--------: Nenhum
Retorno-----------: _cCgc = Retorna o CPF ou CNPJ do Banco do CNAB a pagar.
===============================================================================================================================
*/
User Function Pagide()

_cCgc := "0"+Left(SA2->A2_CGC,8)+SubStr(SA2->A2_CGC,9,4)+Right(SA2->A2_CGC,2)

If SA2->A2_TIPO <> "J"
	_cCgc := Left(SA2->A2_CGC,9)+"0000"+SubStr(SA2->A2_CGC,10,2)
EndIf

Return(_cCgc)

/*
===============================================================================================================================
Função------------: Pagval
Autor-------------: Emerson Dias
Data da Criacao---: 21/01/2009
Descrição---------: Funcao chamada nos CNAB a Pagar Banco Bradesco Valor do Documento. 
Parametros--------: Nenhum
Retorno-----------: _VALOR  = Valor a pagar do documento.
===============================================================================================================================
*/
User Function Pagval()

SetPrvt("_VALOR,")

/// VALOR DO DOCUMENTO  DO CODIGO DE BARRA DA POSICAO 06 - 19, NO ARQUIVO E
/// DA POSICAO 190 - 204, QUANDO NAO For CODIGO DE BARRA VAI O VALOR DO SE2

_VALOR :=Replicate("0",15)

If SubStr(SE2->E2_CODBAR,1,3) == "   "
	
	_VALOR   :=  StrZero((SE2->E2_SALDO*100),15,0)
	
Else
	
	_VALOR  :=  "0" + SubStr(SE2->E2_CODBAR,6,14)
	
EndIf

Return(_VALOR)

/*
===============================================================================================================================
Função------------: Pagmod
Autor-------------: Emerson Dias
Data da Criacao---: 21/01/2009
Descrição---------: Funcao chamada nos CNAB a Pagar Banco Bradesco PROGRAMA PARA INDICAR A MODALIDADE DO PAGAMENTO.
Parametros--------: Nenhum
Retorno-----------: _aModel = Modalidade de pagamento.
===============================================================================================================================
*/
User Function Pagmod()

SetPrvt("_AMODEL,")

/////  PROGRAMA PARA INDICAR A MODALIDADE DO PAGAMENTO
/////  CNAB BRADESCO A PAGAR (PAGFOR) - POSICOES (264-265)

_aModel := SubStr(SEA->EA_MODELO,1,2)

If _aModel == "  "
	If SubStr(SE2->E2_CODBAR,1,3) == "237"
		_aModel := "30"
	Else
		_aModel := "31"
	EndIf
EndIf

Return(_aModel)

/*
===============================================================================================================================
Função------------: Pagdoc
Autor-------------: Emerson Dias
Data da Criacao---: 21/01/2009
Descrição---------: Funcao chamada nos CNAB a Pagar Banco Bradesco PROGRAMA GRAVAR AS INFORMACOES COMPLEMENTARES.
Parametros--------: Nenhum
Retorno-----------: _Doc = Informações complementares para o CNAB.
===============================================================================================================================
*/
User Function Pagdoc()

SetPrvt("_Doc,_Mod,")

/////  PROGRAMA GRAVAR AS INFORMACOES COMPLEMENTARES
/////  CNAB BRADESCO A PAGAR (PAGFOR) - POSICOES (374-413)

_Mod := SubStr(SEA->EA_MODELO,1,2)

Do Case
	Case _Mod == "03" .Or. _Mod == "07" .Or. _Mod == "08"
		_Doc := IIf(SA2->A2_CGC==SM0->M0_CGC,"D","C")+"000000"+"01"+"01"+Space(29)
	Case _Mod == "31"
		_Doc := SubStr(SE2->E2_CODBAR,20,25)+SubStr(SE2->E2_CODBAR,5,1)+SubStr(SE2->E2_CODBAR,4,1)+Space(13)
	OtherWise
		_Doc := Space(40)
EndCase

Return(_Doc)

/*
===============================================================================================================================
Função------------: Pagcodbar
Autor-------------: Emerson Dias
Data da Criacao---: 21/01/2009
Descrição---------: Funcao chamada nos CNAB a Pagar Banco Bradesco PROGRAMA PARA SEPARAR COM BASE NO CODIGO DE BARRA OS CAMPOS
                    BCO DO CEDENTE, AG DO CEDENTE, C.C DO CEDENTE, DG DA C.C CEDENTE, DG DA AG. CEDENTE DE VARIOS BANCOS. 
Parametros--------: _Ccodbar  = Código de Barras
                    _Ctiporet = Tipo de retorno
Retorno-----------: _cret = Tipo de retorno, tendo como base a leitura do código de barras, podendo ser: Agencia do cedente, 
                    digito da agencia, conta corrente do cedente, digito da conta corrente. 
===============================================================================================================================
*/
User Function Pagcodbar(_Ccodbar,_Ctiporet)

SetPrvt("_CTACED,_RETDIG,_DIG1,_DIG2,_DIG3,_DIG4")
SetPrvt("_DIG5,_DIG6,_DIG7,_MULT,_RESUL,_RESTO")
SetPrvt("_DIGITO,_CAGCED,_CDIGCTA,_CDIGAG,_CRET")

_cret   := Space(10)
_Cagced := Space(4)
_Cdigag := Space(3)
_Ctaced := Space(12)
_Cdigcta:= Space(4)
_cBanco := SubStr(_Ccodbar,1,3)
Do Case
	Case _cBanco == "237" 	// BRADESCO
		// Agencia-Digito do cedente
		_Cagced  := SubStr(_Ccodbar,20,4)
		
		_RETDIG := " "
		_DIG1   := SubStr(_Ccodbar,20,1)
		_DIG2   := SubStr(_Ccodbar,21,1)
		_DIG3   := SubStr(_Ccodbar,22,1)
		_DIG4   := SubStr(_Ccodbar,23,1)
		
		_MULT   := (Val(_DIG1)*5) +  (Val(_DIG2)*4) +  (Val(_DIG3)*3) +   (Val(_DIG4)*2)
		_RESUL  := INT(_MULT /11 )
		_RESTO  := INT(_MULT % 11)
		_DIGITO := StrZero((11 - _RESTO),1,0)
		
		_RETDIG := If( _resto == 0,"0",If(_resto == 1,"P",_DIGITO))
		_Cdigag := _RETDIG
		
		// Conta-Digito do cedente
		_Ctaced  := SubStr(_Ccodbar,37,7)
		
		_RETDIG := " "
		_DIG1   := SubStr(_Ccodbar,37,1)
		_DIG2   := SubStr(_Ccodbar,38,1)
		_DIG3   := SubStr(_Ccodbar,39,1)
		_DIG4   := SubStr(_Ccodbar,40,1)
		_DIG5   := SubStr(_Ccodbar,41,1)
		_DIG6   := SubStr(_Ccodbar,42,1)
		_DIG7   := SubStr(_Ccodbar,43,1)
		
		_MULT   := (Val(_DIG1)*2) +  (Val(_DIG2)*7) +  (Val(_DIG3)*6) +   (Val(_DIG4)*5) +  (Val(_DIG5)*4) +  (Val(_DIG6)*3)  + (Val(_DIG7)*2)
		_RESUL  := INT(_MULT /11 )
		_RESTO  := INT(_MULT % 11)
		_DIGITO := StrZero((11 - _RESTO),1,0)
		
		_RETDIG := If( _resto == 0,"0",If(_resto == 1,"P",_DIGITO))
		_Cdigcta:= _RETDIG
		
	Case _cBanco == "341"		// ITAU
		// Agencia do cedente
		_Cagced  := SubStr(_Ccodbar,32,4)
		
		// Conta-Digito do cedente
		_Ctaced  :=  SubStr(_Ccodbar,36,5)
		_Cdigcta :=  SubStr(_Ccodbar,41,1)
		
	Case _cBanco == "356"		// REAL
		// Agencia do cedente
		_Cagced  := SubStr(_Ccodbar,20,4)
		
		// Conta-Digito do cedente
		_Ctaced  :=  SubStr(_Ccodbar,24,7)
		_Cdigcta :=  SubStr(_Ccodbar,31,1)
		
	Case _cBanco == "641"		// BBVA
		// Agencia do cedente
		_Cagced  := SubStr(_Ccodbar,35,4)
		
		// Conta do cedente
		_Ctaced  := SubStr(_Ccodbar,39,5)
		
	Case _cBanco == "409"		// UNIBANCO
		// Agencia-Digito do cedente
		_Cagced  := SubStr(_Ccodbar,28,4)
		_Cdigag  := SubStr(_Ccodbar,32,1)
		
	Case _cBanco == "001"		// BRASIL
		// Agencia do cedente
		_Cagced  := SubStr(_Ccodbar,31,4)
		
		// Conta do cedente
		_Ctaced  :=  SubStr(_Ccodbar,38,5)
		
	Case _cBanco == "392"		// FINASA ?
		// Conta-Digito do cedente
		_Ctaced  :=  SubStr(_Ccodbar,20,7)
		_Cdigcta :=  SubStr(_Ccodbar,27,1)
		
	Case _cBanco == "399"		// HSBC
		// Agencia do cedente
		_Cagced  := SubStr(_Ccodbar,31,4)
		
		// Conta do cedente
		_Ctaced  := SubStr(_Ccodbar,31,11)
		
	Case _cBanco == "320"		// BICBANCO
		// Agencia do cedente
		_Cagced  := SubStr(_Ccodbar,20,3)
		
		// Conta-Digito do cedente
		_Ctaced  := SubStr(_Ccodbar,23,8)
		_Cdigcta := SubStr(_Ccodbar,31,1)
		
	Case _cBanco == "291"		// BCN
		// Agencia do cedente
		_Cagced  := SubStr(_Ccodbar,19,4)
		
		// Conta-Digito do cedente
		_Ctaced  := SubStr(_Ccodbar,23,6)
		_Cdigcta := SubStr(_Ccodbar,29,1)
		
	Case _cBanco == "347"		// SUDAMERIS
		// Agencia do cedente
		_Cagced  := SubStr(_Ccodbar,20,3)
		
		// Conta-Digito do cedente
		_Ctaced  := SubStr(_Ccodbar,23,7)
		_Cdigcta := SubStr(_Ccodbar,30,1)
		
	Case _cBanco == "422"		// SAFRA
		// Agencia do cedente
		_Cagced  := SubStr(_Ccodbar,21,5)
		
		// Conta-Digito do cedente
		_Ctaced  := SubStr(_Ccodbar,26,8)
		_Cdigcta := SubStr(_Ccodbar,34,1)
		
	Case _cBanco == "453"		// BANCO RURAL ?
		// Agencia-Digito do cedente
		_Cagced  := SubStr(_Ccodbar,20,4)
		_Cdigag  := SubStr(_Ccodbar,24,2)
		
		// Conta-Digito do cedente
		_Ctaced  :=  SubStr(_Ccodbar,26,7)
		_Cdigcta :=  SubStr(_Ccodbar,33,1)
		
	Case _cBanco == "244"		// BANCO CIDADE
		// Agencia do cedente
		_Cagced  := SubStr(_Ccodbar,20,3)
		
		// Conta-Digito do cedente
		_Ctaced  := SubStr(_Ccodbar,23,6)
		_Cdigcta := SubStr(_Ccodbar,29,1)
		
	Case _cBanco == "151"		// NOSSA CAIXA NOSSO BANCO
		// Agencia-Digito do cedente
		_Cagced  := SubStr(_Ccodbar,29,4)
		_Cdigag  := SubStr(_Ccodbar,33,1)
		
		// Conta do cedente
		_Ctaced  :=  SubStr(_Ccodbar,34,6)
		
	Case _cBanco == "033"		// BANESPA
		// Agencia-Digito do cedente
		_Cagced  := SubStr(_Ccodbar,20,3)
		_Cdigag  := SubStr(_Ccodbar,23,2)
		
		// Conta-Digito do cedente
		_Ctaced  :=  SubStr(_Ccodbar,25,5)
		_Cdigcta :=  SubStr(_Ccodbar,30,1)
		
	Case _cBanco == "104"		// CAIXA ECONOMICA FEDERAL
		// Agencia-Digito do cedente
		_Cagced  := SubStr(_Ccodbar,30,4)
		_Cdigag  := SubStr(_Ccodbar,34,3)
		
		// Conta do cedente
		_Ctaced  :=  SubStr(_Ccodbar,37,8)
		
	Case _cBanco == "611"		// BANCO PAULISTA
		// Agencia do cedente
		_Cagced  := SubStr(_Ccodbar,20,4)
		
		// Conta-Digito do cedente
		_Ctaced  :=  SubStr(_Ccodbar,24,9)
		_Cdigcta :=  SubStr(_Ccodbar,33,1)
		
	Case _cBanco == "389"		// MERCANTIL DO BRASIL
		// Agencia do cedente
		_Cagced  := SubStr(_Ccodbar,20,4)
		
		// Conta do cedente
		_Ctaced  := SubStr(_Ccodbar,35,9)
		
	Case _cBanco == "041"		// BANRISUL
		// Agencia do cedente
		_Cagced  := SubStr(_Ccodbar,22,3)
		
		// Conta do cedente
		_Ctaced  := SubStr(_Ccodbar,25,7)
		
	Case _cBanco == "353"		// BANCO SANTANDER
		// Conta-Digito do cedente
		_Ctaced  := SubStr(_Ccodbar,22,5)
		_Cdigcta := SubStr(_Ccodbar,27,1)
		
	Case _cBanco == "231"		// BANCO BOAVISTA
		// Agencia do cedente
		_Cagced  := SubStr(_Ccodbar,21,4)
		
		// Conta do cedente
		_Ctaced  := SubStr(_Ccodbar,25,8)
		
	Case _cBanco == "230"		// BANCO BANDEIRANTES
		// Agencia do cedente
		_Cagced  := SubStr(_Ccodbar,23,3)
		
		// Conta-Digito do cedente
		_Ctaced  :=  SubStr(_Ccodbar,26,4)
		_Cdigcta :=  SubStr(_Ccodbar,30,1)
		
EndCase
If _ctiporet == "AGE"			// agencia do cedente
	_cret := _Cagced
ElseIf _ctiporet == "DAG"       // digito da agencia
	_cret := _Cdigag
ElseIf _ctiporet == "CTA"       // conta corrente do cedente
	_cret := _Ctaced
ElseIf _ctiporet == "DCT"       // digito da conta corrente
	_cret := _Cdigcta
EndIf


Return(_cret)

/*
===============================================================================================================================
Função------------: Pagcar
Autor-------------: Emerson Dias
Data da Criacao---: 21/01/2009
Descrição---------: Funcao chamada nos CNAB a Pagar Banco Bradesco PROGRAMA PARA SELECIONAR A CARTEIRA NO CODIGO DE BARRAS.	
                    QUANDO NAO TIVER TEM QUE SER COLOCADO "00".	
Parametros--------: Nenhum
Retorno-----------: _Retcar = Carteira lida a partir do código de barras.
===============================================================================================================================
*/
User Function Pagcar()

SetPrvt("_RETCAR,")

If SUBS(SE2->E2_CODBAR,01,3) != "237"
	_Retcar := "000"
Else
	_Retcar := "0" + SUBS(SE2->E2_CODBAR,24,2)
EndIf

Return(_Retcar)

/*
===============================================================================================================================
Função------------: Pagagen 
Autor-------------: Emerson Dias
Data da Criacao---: 21/01/2009 
Descrição---------: Funcao chamada nos CNAB a Pagar Banco Bradesco para trazer a Agencia do Fornecedor.	
                    BRADESCO A PAGAR (PAGFOR)POSICOES (99-103).
Parametros--------: Nenhum
Retorno-----------: _BANCO = Código da agencia do fornecedor bancário.
===============================================================================================================================
*/
User Function Pagagen()

Local _BANCO

_BANCO	:=	StrZero(Val(LEFT(AllTrim(SA2->A2_AGENCIA),Len(AllTrim(SA2->A2_AGENCIA))-1)),5)

Return(_BANCO)


/*
===============================================================================================================================
Função------------: Agen 
Autor-------------: Emerson Dias
Data da Criacao---: 21/01/2009 
Descrição---------: Retornar o numero da conta bancárica a partir da leitura da tabela SEE.
Parametros--------: Nenhum
Retorno-----------: _BANCO = Numero da conta bancária.
===============================================================================================================================
*/
User Function Agen()

Local _BANCO

_BANCO  := StrZero(Val(SubStr(SEE->EE_CONTA,1,Len(AllTrim(SEE->EE_CONTA))-1)),7)

Return(_BANCO)

/*
===============================================================================================================================
Função------------: Pagacta
Autor-------------: Emerson Dias
Data da Criacao---: 21/01/2009
Descrição---------: Funcao chamada nos CNAB a Pagar Banco Bradesco PROGRAMA PARA SEPARAR A C/C DO CODIGO DE BARRA 		
                    CNAB BRADESCO A PAGAR (PAGFOR) - POSICOES (105-119).	
Parametros--------: Nenhum
Retorno-----------: _CtaCed = Retorna a conta corrente a partir da leitura do código de barras.
===============================================================================================================================
*/
User Function Pagacta()

If SEA->EA_MODELO=="01" .Or. SEA->EA_MODELO=="03" .Or. SEA->EA_MODELO=="08"
	_CtaCed := StrZero(Val(SubStr(SA2->A2_NUMCON,1,Len(AllTrim(SA2->A2_NUMCON))-1)),13)
Else
	
	SetPrvt("_CTACED,_RETDIG,_DIG1,_DIG2,_DIG3,_DIG4,_NPOSDV")
	SetPrvt("_DIG5,_DIG6,_DIG7,_MULT,_RESUL,_RESTO")
	SetPrvt("_DIGITO,")
	
	_CtaCed := "000000000000000"
	_cBanco := SubStr(SE2->E2_CODBAR,1,3)
	Do Case
		Case _cBanco == "237"	// BRADESCO
			
			_CtaCed  :=  StrZero(Val(SubStr(SE2->E2_CODBAR,37,7)),13,0)
			
			_RETDIG := " "
			_DIG1   := SubStr(SE2->E2_CODBAR,37,1)
			_DIG2   := SubStr(SE2->E2_CODBAR,38,1)
			_DIG3   := SubStr(SE2->E2_CODBAR,39,1)
			_DIG4   := SubStr(SE2->E2_CODBAR,40,1)
			_DIG5   := SubStr(SE2->E2_CODBAR,41,1)
			_DIG6   := SubStr(SE2->E2_CODBAR,42,1)
			_DIG7   := SubStr(SE2->E2_CODBAR,43,1)
			
			_MULT   := (Val(_DIG1)*2) +  (Val(_DIG2)*7) +  (Val(_DIG3)*6) +   (Val(_DIG4)*5) +  (Val(_DIG5)*4) +  (Val(_DIG6)*3)  + (Val(_DIG7)*2)
			_RESUL  := INT(_MULT /11 )
			_RESTO  := INT(_MULT % 11)
			_DIGITO := StrZero((11 - _RESTO),1,0)
			
			_RETDIG := If( _resto == 0,"0",If(_resto == 1,"P",_DIGITO))
			
			_CtaCed := _CtaCed + _RETDIG
			
		OtherWise
			_nPosDV := AT("-",SA2->A2_NUMCON)
			If _nPosDV == 0
				_CtaCed := REPL("0",13-Len(LTRIM(RTRIM(SA2->A2_NUMCON))))+LTRIM(RTRIM(SA2->A2_NUMCON))
			Else
				_CtaCed := SubStr(SA2->A2_NUMCON,1,_nPosDV-1)
				_CtaCed := REPL("0",13-Len(_CtaCed))+_CtaCed
				_CtaCed := _CtaCed+SubStr(SA2->A2_NUMCON,_nPosDV+1,2)
			EndIf
	EndCase
EndIf

Return(_CtaCed)

/*
===============================================================================================================================
Função------------: CONVLD
Autor-------------: Flavio Novaes / Emerson Dias
Data da Criacao---: 19/10/2007 | 21/01/09
Descrição---------: Funcao para Conversao da Representacao Numerica do Codigo de Barras - Linha Digitavel (LD) em Codigo de 
                    Barras (CB).       
                    Para utilizacao dessa Funcao, deve-se criar um Gatilho para o campo E2_CODBAR, Conta Dominio: E2_CODBAR, 
                    Tipo: Primario, Regra: EXECBLOCK("CONVLD",.T.), Posiciona: Nao.               
                    Utilize tambem a Validacao do Usuario para o Campo E2_CODBAR EXECBLOCK("CODBAR",.T.) para Validar a LD 
                    ou o CB.     
Parametros--------: Nenhum
Retorno-----------: cStr = Codigo de barrras no formato CB.
===============================================================================================================================
*/
User Function ConvLD()
SETPRVT("cStr")

cStr := LTRIM(RTRIM(M->E2_CODBAR))

If ValType(M->E2_CODBAR) == NIL .Or. Empty(M->E2_CODBAR)
	// Se o Campo esta em Branco nao Converte nada.
	cStr := ""
Else
	// Se o Tamanho do String For menor que 44, completa com zeros ate 47 digitos. Isso eh
	// necessario para Bloquetos que NAO tem o vencimento e/ou o valor informados na LD.
	cStr := If(Len(cStr)<44,cStr+REPL("0",47-Len(cStr)),cStr)
EndIf

Do Case
	Case Len(cStr) == 47
		cStr := SubStr(cStr,1,4)+SubStr(cStr,33,15)+SubStr(cStr,5,5)+SubStr(cStr,11,10)+SubStr(cStr,22,10)
	Case Len(cStr) == 48
		cStr := SubStr(cStr,1,11)+SubStr(cStr,13,11)+SubStr(cStr,25,11)+SubStr(cStr,37,11)
	OtherWise
		cStr := cStr+Space(48-Len(cStr))
EndCase

Return(cStr)

/*
===============================================================================================================================
Função------------: CodBar
Autor-------------: Flavio Novaes / Emerson Dias 
Data da Criacao---: 19/10/2007 | 21/01/2009
Descrição---------: - Funcao para Validacao de Codigo de Barras (CB) e Representacao Numerica do Codigo de Barras - Linha 
                    Digitavel (LD).			
                    - A LD de Bloquetos possui tres Digitos Verificadores (DV) que sao consistidos pelo Modulo 10, alem do 
                    Digito Verificador Geral (DVG) que e consistido pelo Modulo 11. Essa LD tem 47 Digitos.                                                      
                    - A LD de Titulos de Concessinarias do Serviço Publico e IPTU possui quatro Digitos Verificadores (DV) que 
                    sao consistidos pelo Modulo 10, alem do Digito Verificador Geral (DVG) que tambem e consistido pelo 
                    Modulo 10. Essa LD tem 48 Digitos.   
                    - O CB de Bloquetos e de Titulos de Concessionarias do Serviço Publico e IPTU possui apenas o Digito 
                    Verificador Geral (DVG) sendo que a unica diferença e que o CB de Bloquetos e consistido pelo Modulo 11 
                    enquanto que o CB de Titulos de Concessionarias e consistido pelo Modulo 10. Todos os CBs tem 44 Digitos.
                    - Para utilização dessa Funcao, deve-se criar o campo E2_CODBAR, Tipo Caracter, Tamanho 48 e colocar na 
                    Validacao do Usuario: EXECBLOCK("CODBAR",.T.).
                    - Utilize tambem o gatilho com a Funcao CONVLD() para converter a LD em CB.		
                    - Essa Funcao foi desenvolvida com base no Manual do Bco. Itaú e no RDMAKE: CODBARVL - Autor: Vicente 
                    Sementilli - Data: 26/02/2007.   
Parametros--------: Nenhum
Retorno-----------: lRet = .T. = Código de barras válido.
                         = .F. = Código de barras não válido.
===============================================================================================================================
*/
User Function CodBar()

Local _nX	:= 0

SETPRVT("cStr,lRet,cTipo,nConta,nMult,nVal,nDV,cCampo,i,nMod,nDVCalc")

// Retorna .T. se o Campo estiver em Branco.
If ValType(M->E2_CODBAR) == NIL .Or. Empty(M->E2_CODBAR)
	Return(.T.)
EndIf

cStr := LTRIM(RTRIM(M->E2_CODBAR))

// Se o Tamanho do String For 45 ou 46 esta errado! Retornara .F.
lRet := If(Len(cStr)==45 .Or. Len(cStr)==46,.F.,.T.)

// Se o Tamanho do String For menor que 44, completa com zeros ate 47 digitos. Isso e
// necessario para Bloquetos que NAO tem o vencimento e/ou o valor informados na LD.
cStr := If(Len(cStr)<44,cStr+REPL("0",47-Len(cStr)),cStr)

// Verifica se a LD e de (B)loquetos ou (C)oncessionarias/IPTU. Se For CB retorna (I)ndefinido.
cTipo := If(Len(cStr)==47,"B",If(Len(cStr)==48,"C","I"))

// Verifica se todos os digitos sao numericos.
For _nX := Len(cStr) TO 1 STEP -1
	lRet := If(SubStr(cStr,_nX,1) $ "0123456789",lRet,.F.)
Next _nX

If Len(cStr) == 47 .And. lRet
	// Consiste os tres DV de Bloquetos pelo Modulo 10.
	nConta  := 1
	While nConta <= 3
		nMult  := 2
		nVal   := 0
		nDV    := Val(SubStr(cStr,If(nConta==1,10,If(nConta==2,21,32)),1))
		cCampo := SubStr(cStr,If(nConta==1,1,If(nConta==2,11,22)),If(nConta==1,9,10))
		For _nX := Len(cCampo) TO 1 STEP -1
			nMod  := Val(SubStr(cCampo,_nX,1)) * nMult
			nVal  := nVal + If(nMod>9,1,0) + (nMod-If(nMod>9,10,0))
			nMult := If(nMult==2,1,2)
		Next _nX
		nDVCalc := 10-MOD(nVal,10)
		// Se o DV Calculado For 10 eh assumido 0 (Zero).
		nDVCalc := If(nDVCalc==10,0,nDVCalc)
		lRet    := If(lRet,(nDVCalc==nDV),.F.)
		nConta  := nConta + 1
	EndDo
	// Se os DV foram consistidos com sucesso (lRet=.T.), converte o numero para CB para consistir o DVG.
	cStr := If(lRet,SubStr(cStr,1,4)+SubStr(cStr,33,15)+SubStr(cStr,5,5)+SubStr(cStr,11,10)+SubStr(cStr,22,10),cStr)
EndIf

If Len(cStr) == 48 .And. lRet
	// Consiste os quatro DV de Titulos de Concessionarias de Serviço Publico e IPTU pelo Modulo 10.
	nConta  := 1
	While nConta <= 4
		nMult  := 2
		nVal   := 0
		nDV    := Val(SubStr(cStr,If(nConta==1,12,If(nConta==2,24,If(nConta==3,36,48))),1))
		cCampo := SubStr(cStr,If(nConta==1,1,If(nConta==2,13,If(nConta==3,25,37))),11)
		For _nX := 11 TO 1 STEP -1
			nMod  := Val(SubStr(cCampo,_nX,1)) * nMult
			nVal  := nVal + If(nMod>9,1,0) + (nMod-If(nMod>9,10,0))
			nMult := If(nMult==2,1,2)
		Next _nX
		nDVCalc := 10-MOD(nVal,10)
		// Se o DV Calculado For 10 eh assumido 0 (Zero).
		nDVCalc := If(nDVCalc==10,0,nDVCalc)
		lRet    := If(lRet,(nDVCalc==nDV),.F.)
		nConta  := nConta + 1
	EndDo
	// Se os DV foram consistidos com sucesso (lRet=.T.), converte o numero para CB para consistir o DVG.
	cStr := If(lRet,SubStr(cStr,1,11)+SubStr(cStr,13,11)+SubStr(cStr,25,11)+SubStr(cStr,37,11),cStr)
EndIf

If Len(cStr) == 44 .And. lRet
	If cTipo $ "BI"
		// Consiste o DVG do CB de Bloquetos pelo Modulo 11.
		nMult  := 2
		nVal   := 0
		nDV    := Val(SubStr(cStr,5,1))
		cCampo := SubStr(cStr,1,4)+SubStr(cStr,6,39)
		For _nX := 43 TO 1 STEP -1
			nMod  := Val(SubStr(cCampo,_nX,1)) * nMult
			nVal  := nVal + nMod
			nMult := If(nMult==9,2,nMult+1)
		Next _nX
		nDVCalc := 11-MOD(nVal,11)
		// Se o DV Calculado For 0,10 ou 11 eh assumido 1 (Um).
		nDVCalc := If(nDVCalc==0 .Or. nDVCalc==10 .Or. nDVCalc==11,1,nDVCalc)
		lRet    := If(lRet,(nDVCalc==nDV),.F.)
		// Se o Tipo eh (I)ndefinido E o DVG NAO foi consistido com sucesso (lRet=.F.), tentara
		// consistir como CB de Titulo de Concessionarias/IPTU no If abaixo.
	EndIf
	If cTipo == "C" .Or. (cTipo == "I" .And. !lRet)
		// Consiste o DVG do CB de Titulos de Concessionarias pelo Modulo 10.
		lRet   := .T.
		nMult  := 2
		nVal   := 0
		nDV    := Val(SubStr(cStr,4,1))
		cCampo := SubStr(cStr,1,3)+SubStr(cStr,5,40)
		For _nX := 43 TO 1 STEP -1
			nMod  := Val(SubStr(cCampo,_nX,1)) * nMult
			nVal  := nVal + If(nMod>9,1,0) + (nMod-If(nMod>9,10,0))
			nMult := If(nMult==2,1,2)
		Next _nX
		nDVCalc := 10-MOD(nVal,10)
		// Se o DV Calculado For 10 eh assumido 0 (Zero).
		nDVCalc := If(nDVCalc==10,0,nDVCalc)
		lRet    := If(lRet,(nDVCalc==nDV),.F.)
	EndIf
EndIf

If !lRet
	HELP(" ",1,"ONLYNUM")
EndIf

Return(lRet)

/*
===============================================================================================================================
Função------------: Pagban
Autor-------------: Emerson Dias
Data da Criacao---: 21/01/2009 
Descrição---------: Funcao chamada nos CNAB a Pagar Banco Bradesco. Funcao para trazer o cod do banco.
Parametros--------: Nenhum
Retorno-----------: _BANCO = Código do banco lido do código de barras.
===============================================================================================================================
*/
User Function Pagban()

SetPrvt("_BANCO,")

//  PROGRAMA PARA SEPARAR O BANCO DO CODIGO DE BARRAS
//  CNAB BRADESCO A PAGAR (PAGFOR) - POSICOES (96-98)

If SubStr(SE2->E2_CODBAR,1,3) == "   "
	_BANCO := SubStr(SA2->A2_BANCO,1,3)
Else
	_BANCO := SubStr(SE2->E2_CODBAR,1,3)
EndIf

Return(_BANCO)
