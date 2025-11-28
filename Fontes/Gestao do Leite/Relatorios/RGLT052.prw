/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |22/10/2019| Chamado 30961. Alterações nos dizeres para Pessoa Jurídica
Lucas Borges  |25/03/2022| Chamado 39465. Retirado campo A2_L_CTRC que foi descontinuado
Lucas Borges  |22/04/2025| Chamado 50505. Alterada a picture do CNPJ para contemplar campo alfanumérico
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: RGLT052
Autor-----------: Fabiano Dias
Data da Criacao-: 05/09/2011
Descrição-------: Relatorio desenvolvido para realizar a impressao de uma declaracao/autorizacao e as promissorias referente as
				  parcelas do emprestimo/adiantamento/antecipacao, para que a empresa fique resguardada.
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function RGLT052()

Private oPrint
Private nLinha      := 0100
Private nColInic    := 0250
Private nColFinal   := 2360 
Private nLinInBox   := 0100
Private nSaltoLinha := 50               
Private nAjuAltLi1  := 10 //ajusta a altura de impressao dos dados do relatorio 

Define Font oFont12    Name "Courier New"       Size 0,-10       		    // Tamanho 12
Define Font oFont12b   Name "Courier New"       Size 0,-10 Bold             // Tamanho 12 Negrito  
Define Font oFont14    Name "Courier New"       Size 0,-12                  // Tamanho 14
Define Font oFont14b   Name "Times New Roman"   Size 0,-15 Bold Underline   // Tamanho 14         

oPrint:= TMSPrinter():New("DECLARACAO/AUTORIZACAO EMPRESTIMO") 
oPrint:SetPortrait() 	// Retrato  oPrint:SetLandscape() - Paisagem
oPrint:SetPaperSize(9)	// Seta para papel A4
	                 		
/// startando a impressora
oPrint:Say(0,0," ",oFont12,100)        

oPrint:StartPage()           

Processa({||CursorWait(),impDeclar(),CursorArrow()})

oPrint:EndPage()	// Finaliza a Pagina.
oPrint:Preview()	// Visualiza antes de Imprimir.

Return

/*
===============================================================================================================================
Programa--------: impDeclar
Autor-----------: Fabiano Dias
Data da Criacao-: 05/09/2011
Descrição-------: Imprime as declaracoes e promissorias dos tipo de fornecedores: produtores ou Fretistas(Pessoa fisica ou juri
				  dica).
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function impDeclar()           
                                                                                                                                                                                                                                           
Local _cAlias	:= GetNextAlias() 
Local _cFiltro	:= "%"
Local _cCampo	:= "%"
Local _cTabela	:= "%"
Local _cAux		:= IIf(FUNNAME() == "AGLT012","ZLM","ZLN")

//====================================================================================================
// Monta filtro de acordo com a tabela de origem
//====================================================================================================
_cCampo += _cAux +"_COD CODIGO, "+ _cAux +"_TOTAL TOTAL, "+ _cAux +"_TIPO TIPO, "+ _cAux +"_DTLIB DTLIB, "+ _cAux +"_DTCRED DTCRED, "+ _cAux +"_STATUS STATUS, "+ _cAux +"_PARC PARC, "
_cCampo += _cAux +"_JUROS JUROS, "+ _cAux +"_VLRPAR VLRPAR, "+ _cAux +"_DATA DATA "
_cTabela += RetSqlName(_cAux) +" "+ _cAux + " "
_cFiltro += " AND "+ _cAux +".D_E_L_E_T_ = ' '"
_cFiltro += " AND "+ _cAux +"_Filial = '" + xFilial(_cAux) + "'"
_cFiltro += " AND "+ _cAux +"_COD = '" + &(_cAux+"->"+_cAux+"_COD") + "'"
_cFiltro += " AND A2_COD = "+ _cAux +"_SA2COD "
_cFiltro += " AND A2_LOJA = "+ _cAux +"_SA2LJ "
_cFiltro += " AND RA_FILIAL = SubStr("+ _cAux +"_USER,1,2)
_cFiltro += " AND RA_MAT = SubStr("+ _cAux +"_USER,3,6)

_cCampo += "%"
_cTabela += "%"
_cFiltro += "%"

//====================================================================================================
//Query para selecionar os dados do responsavel por assumir a divida juntamente a ITALAC
//====================================================================================================
BeginSql alias _cAlias 		      
	SELECT A2_COD, A2_LOJA, A2_NOME, A2_CGC, A2_TIPO, A2_END, A2_EST, A2_BAIRRO, CC2_MUN, A2_PAIS, RA_NOME, RA_CIC, RA_RG, %exp:_cCampo%
		FROM %Table:SA2% SA2, %Table:CC2% CC2, %Table:SRA% SRA, %exp:_cTabela%
	WHERE SA2.D_E_L_E_T_ = ' '
	AND CC2.D_E_L_E_T_ = ' '
	AND SRA.D_E_L_E_T_ = ' '
	AND CC2.CC2_EST = SA2.A2_EST
	AND CC2.CC2_CODMUN = SA2.A2_COD_MUN 
	%exp:_cFiltro%
EndSql

If !(_cAlias)->(Eof())                   	
	//=====================================================================
	//Verifica se o solicitante do valor em questao eh uma pessoa Juridica
	//=====================================================================
           
	nlinha+=nSaltoLinha
	nlinha+=nSaltoLinha
	nlinha+=nSaltoLinha
	oPrint:Say (nlinha,nColFinal / 2,'DECLARAÇÃO/AUTORIZAÇÃO',oFont14b,nColFinal,,,2) 
	nlinha+=nSaltoLinha
	nlinha+=nSaltoLinha
	nlinha+=nSaltoLinha
	                             	
	//Declaracao de um produtor
	If SubStr((_cAlias)->A2_COD,1,1) == 'P'
		impProdut(_cAlias)
	Else    	           			
		//Declaração de um fretista pessoa Juridica(Transportador Granel)
		If (_cAlias)->A2_TIPO == 'J' 
			impFreJur(_cAlias)
		//Declaracao de um fretista pessoa fisica Latao
		Else 
			impFreLat(_cAlias)    
		EndIf           
	EndIf       
		
	//=========================================
	//Imprime informacoes finais da declaracao
	//=========================================
	nlinha+=nSaltoLinha
	nlinha+=nSaltoLinha
	nlinha+=nSaltoLinha         
	oPrint:Say (nlinha,nColFinal / 2,AllTrim(SM0->M0_CIDCOB) + ", " + cValToChar(Day(SToD((_cAlias)->DATA))) + " de " + AllTrim(MesExtenso(Month(SToD((_cAlias)->DATA)))) + "  de " + cValToChar(Year(SToD((_cAlias)->DATA))) + ".",oFont14,nColFinal,,,2)
	nlinha+=nSaltoLinha
	nlinha+=nSaltoLinha
	nlinha+=nSaltoLinha  
	oPrint:Say (nlinha,nColFinal / 2,'_____________________________________________',oFont14,nColFinal,,,2) 
	nlinha+=nSaltoLinha                                                                                                     
	oPrint:Say (nlinha,nColFinal / 2,(_cAlias)->A2_COD + '/' + (_cAlias)->A2_LOJA + ' - ' + AllTrim((_cAlias)->A2_NOME),oFont14,nColFinal,,,2) 
	nlinha+=nSaltoLinha
	oPrint:Say (nlinha,nColFinal / 2,IIf((_cAlias)->A2_TIPO == 'J','CNPJ: ' + Transform((_cAlias)->A2_CGC,"@R! NN.NNN.NNN/NNNN-99"),'CPF: ' + Transform((_cAlias)->A2_CGC,"@R 999.999.999-99")),oFont14,nColFinal,,,2) 
	nlinha+=nSaltoLinha
	nlinha+=nSaltoLinha
	nlinha+=nSaltoLinha     
	oPrint:Say (nlinha,nColInic,"TESTEMUNHAS",oFont14) 
	nlinha+=nSaltoLinha
	nlinha+=nSaltoLinha
	nlinha+=nSaltoLinha
	nlinha+=nSaltoLinha
	nlinha+=nSaltoLinha
	oPrint:Line(nLinha,nColInic       ,nLinha,nColInic + 900  )  
	oPrint:Line(nLinha,nColInic + 950,nLinha,nColInic  + 1900 )
	oPrint:Say (nlinha + nAjuAltLi1,nColInic       ,"Nome:" + SubStr((_cAlias)->RA_NOME,1,35),oFont12)
	oPrint:Say (nlinha + nAjuAltLi1,nColInic + 950 ,"Nome:",oFont12)
	nlinha+=nSaltoLinha
	oPrint:Say (nlinha + nAjuAltLi1,nColInic       ,"RG:" + (_cAlias)->RA_RG,oFont12)
	oPrint:Say (nlinha + nAjuAltLi1,nColInic + 950 ,"RG:",oFont12)
	nlinha+=nSaltoLinha
	oPrint:Say (nlinha + nAjuAltLi1,nColInic       ,"CPF:" + Transform((_cAlias)->RA_CIC,"@R 999.999.999-99"),oFont12)
	oPrint:Say (nlinha + nAjuAltLi1,nColInic + 950 ,"CPF:",oFont12)

	Processa({||CursorWait(),impPromiss(_cAlias),CursorArrow()})
	(_cAlias)->(DBCloseArea())
EndIf                     

Return

/*
===============================================================================================================================
Programa--------: impProdut
Autor-----------: Fabiano Dias
Data da Criacao-: 05/09/2011
Descrição-------: Imprime a declaracao referente aos fornecedores do tipo Produtor ou seja que comecam com a letra P.
Parametros------: _cAlias -> Alias contendo os registros da query principal
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function impProdut(_cAlias)

Local _cMsgProd := ""  
Local _cTpSolic := "" //Tipo da solicitacao  
Local _cJuros   := ""   
Local _cMsgTpPes:= ""
                     
//Verifica o tipo da solicitacao efetuada 
If  (_cAlias)->TIPO  == 'A'   
	_cTpSolic:= "um adiantamento"   
	_cMsgSolic:= "do adiantamento solicitado"              
ElseIf (_cAlias)->TIPO  == 'E'  		
	_cTpSolic:= "um adiantamento pecuniário"	
	_cMsgSolic:= "do adiantamento pecuniário solicitado"
Else   		
	_cTpSolic:= 'uma antecipação'
	_cMsgSolic:= "da antecipação solicitada"
EndIf          

//Verifica se foi informa um valor de juros   
If (_cAlias)->JUROS > 0    
	_cJuros:= ", já acrescida(s) de juros mensais de " + AllTrim(Transform((_cAlias)->JUROS,"@E 999.99")) + "%"
EndIf                                                                
     
//Produtor Pessoa Juridica
If (_cAlias)->A2_TIPO == 'J'
	_cMsgTpPes:= "A empresa, " + AllTrim((_cAlias)->A2_NOME) + ", inscrita no CNPJ " + Transform(AllTrim((_cAlias)->A2_CGC),"@R! NN.NNN.NNN/NNNN-99") + " "                     
Else 		
	_cMsgTpPes:= "Eu, " + AllTrim((_cAlias)->A2_NOME) + ", inscrito(a) no CPF: " + Transform(AllTrim((_cAlias)->A2_CGC),"@R 999.999.999-99") + " "
EndIf

_cMsgProd:= _cMsgTpPes + " produtor(a) rural "                      
_cMsgProd+= "e fornecedor(a) de leite, com endereço na(o) " + AllTrim((_cAlias)->A2_END) + " município de " + AllTrim((_cAlias)->CC2_MUN) + " - "  
_cMsgProd+= AllTrim((_cAlias)->A2_EST) + ", " 
_cMsgProd+= "declaro(a) para os devidos fins que recebi em " + DToC(SToD((_cAlias)->DTCRED)) + ' da empresa "GoiasMinas Indústria de Laticínios Ltda. - Italac", '
_cMsgProd+= "a quantia de R$ " + AllTrim(Transform((_cAlias)->TOTAL,"@E 999,999,999,999.99")) + " (" + AllTrim(Extenso((_cAlias)->TOTAL,.F.)) + ") referente a " + _cTpSolic + " "
_cMsgProd+= "que deverá ser descontado conforme o(s) vencimento(s) que consta(m) na(s) parcela(s) " 
_cMsgProd+= "em anexo, do meu pagamento referente ao fornecimento de leite à Italac "
_cMsgProd+= "em " + AllTrim(Str((_cAlias)->PARC)) + " (" + AllTrim(Extenso((_cAlias)->PARC,.T.)) + ") parcela(s) igual(is) de R$ " + AllTrim(Transform((_cAlias)->VLRPAR,"@E 999,999,999,999.99")) + " "   
_cMsgProd+= "(" + AllTrim(Extenso((_cAlias)->VLRPAR,.F.)) + ")" + _cJuros + "."

impTexto(_cMsgProd)                                              
nlinha+=nSaltoLinha 

_cMsgProd:= "Mediante ao exposto acima, me comprometo a fornecer o leite à Italac regularmente dentro dos padrões exigidos pela IN 51/2002 e desde de já "                     
_cMsgProd+= "a Italac fica AUTORIZADA também a fazer o desconto de todo o saldo devedor se por qualquer motivo eu deixar de fornecer leite. Caso haja saldo "
_cMsgProd+= "devedor à empresa originado pelo valor " + _cMsgSolic + ", AUTORIZO a sua transferência para ser descontado no mês subsequente."

impTexto(_cMsgProd)
nlinha+=nSaltoLinha

_cMsgProd:= "Vinculam-se a presente declaração a(s) nota(s) promissória(s) em anexo, nº "+ (_cAlias)->CODIGO +", que poderá(ão) ser executada(s) em caso de inadimplência."                     

impTexto(_cMsgProd)  
nlinha+=nSaltoLinha

_cMsgProd:= "Por ser verdade, assino a presente solicitação/autorização, na presença de duas testemunhas."                     

impTexto(_cMsgProd) 

Return

/*
===============================================================================================================================
Programa--------: impFreJur
Autor-----------: Fabiano Dias
Data da Criacao-: 05/09/2011
Descrição-------: Imprime a declaracao referente aos fornecedores do tipo Fretista do tipo pessoa Juridica.
Parametros------: _cAlias -> Alias contendo os registros da query principal
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function impFreJur(_cAlias)

Local _cMsgTrans:= ""   
Local _cTpSolic := ""   
Local _cJuros   := ""     

//Verifica o tipo da solicitacao efetuada 
If  (_cAlias)->TIPO  == 'A'   
	_cTpSolic:= "adiantamento"                
ElseIf (_cAlias)->TIPO  == 'E'  		
	_cTpSolic:= "adiantamento pecuniário"	
Else   		
	_cTpSolic:= "antecipação"
EndIf   

//Verifica se foi informa um valor de juros   
If (_cAlias)->JUROS > 0    
	_cJuros:= ", acrescida(s) de juros mensais de " + AllTrim(Transform((_cAlias)->JUROS,"@E 999.99")) + "%"
EndIf 

_cMsgTrans:= "A empresa, " + AllTrim((_cAlias)->A2_NOME) + ", inscrita no CNPJ " + Transform(AllTrim((_cAlias)->A2_CGC),"@R! NN.NNN.NNN/NNNN-99")                     
_cMsgTrans+= ", localizada na(o) " + AllTrim((_cAlias)->A2_END) + ", bairro " + AllTrim((_cAlias)->A2_BAIRRO) + ", na cidade de " + AllTrim((_cAlias)->CC2_MUN) + " - " 
_cMsgTrans+= AllTrim((_cAlias)->A2_EST) + ", declara para os devidos fins que recebeu em " + DToC(SToD((_cAlias)->DTCRED)) + ' da empresa "GoiasMinas Indústria de Laticínios Ltda. - Italac", '
_cMsgTrans+= "a quantia de R$ " + AllTrim(Transform((_cAlias)->TOTAL,"@E 999,999,999,999.99")) + " (" + AllTrim(Extenso((_cAlias)->TOTAL,.F.)) + ") referente a um(a) " + _cTpSolic + " efetuado(a) "
_cMsgTrans+= "ao fornecedor e/ou transportador de leite, " + _cTpSolic + " que deverá ser descontado do faturamento mensal de entrega do leite à Italac em " 
_cMsgTrans+= AllTrim(Str((_cAlias)->PARC)) + " (" + AllTrim(Extenso((_cAlias)->PARC,.T.)) + ") parcela(s) igual(is) de R$ " + AllTrim(Transform((_cAlias)->VLRPAR,"@E 999,999,999,999.99")) + " "   
_cMsgTrans+= "(" + AllTrim(Extenso((_cAlias)->VLRPAR,.F.)) + ")" + _cJuros + "."

impTexto(_cMsgTrans)                       
nlinha+=nSaltoLinha  

_cMsgTrans:= "Mediante ao exposto acima, a empresa " + AllTrim((_cAlias)->A2_NOME) + ", se compromete a entregar/transportar leite regularmente "
_cMsgTrans+= "e desde de já a Italac fica AUTORIZADA também a fazer o desconto de todo o saldo devedor de uma só vez se por quaisquer motivos o fornecedor e/ou transportador deixar de entregar leite ou prestar serviços de transporte à Italac."

impTexto(_cMsgTrans) 
nlinha+=nSaltoLinha     

_cMsgTrans:= "Vinculam-se a presente declaração a(s) nota(s) promissória(s) em anexo, que poderá(ão) ser executada(s) em caso de inadimplência."

impTexto(_cMsgTrans)  
nlinha+=nSaltoLinha

_cMsgTrans:= "Por ser verdade, assino a presente solicitação/autorização, na presença de duas testemunhas."
impTexto(_cMsgTrans)

Return

/*
===============================================================================================================================
Programa--------: impFreLat
Autor-----------: Fabiano Dias
Data da Criacao-: 05/09/2011
Descrição-------: Imprime a declaracao referente aos fornecedores do tipo Fretista do tipo pessoa Fisica(Transportador Latao).
Parametros------: _cAlias -> Alias contendo os registros da query principal
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function impFreLat(_cAlias)

Local _cMsgTrans:= ""                
Local _cTpSolic := ""   
Local _cJuros   := ""     

//Verifica o tipo da solicitacao efetuada 
If  (_cAlias)->TIPO  == 'A'   
	_cTpSolic:= "adiantamento"                
ElseIf (_cAlias)->TIPO  == 'E'  		
	_cTpSolic:= "adiantamento pecuniário"	
Else   		
	_cTpSolic:= "antecipação"
EndIf   

//Verifica se foi informa um valor de juros   
If (_cAlias)->JUROS > 0    
	_cJuros:= ", acrescida(s) de juros mensais de " + AllTrim(Transform((_cAlias)->JUROS,"@E 999.99")) + "%"
EndIf 

_cMsgTrans:= "Eu, " + AllTrim((_cAlias)->A2_NOME) + ", inscrito(a) no CPF: " + Transform(AllTrim((_cAlias)->A2_CGC),"@R 999.999.999-99") + " transportador "
_cMsgTrans+= "de leite em latões, com endereço na(o) " + AllTrim((_cAlias)->A2_END) + " na cidade de " + AllTrim((_cAlias)->CC2_MUN) + " - "  
_cMsgTrans+= AllTrim((_cAlias)->A2_EST) + ", declaro para os devidos fins que recebi em " + DToC(SToD((_cAlias)->DTCRED)) + ' da empresa "GoiasMinas Indústria de Laticínios Ltda. - Italac", '
_cMsgTrans+= "a quantia de R$ " + AllTrim(Transform((_cAlias)->TOTAL,"@E 999,999,999,999.99")) + " (" + AllTrim(Extenso((_cAlias)->TOTAL,.F.)) + ") referente a um(a) " + _cTpSolic + " efetuado "
_cMsgTrans+= "à transportadora de leite, " + _cTpSolic + " que deverá ser descontado do faturamento mensal de transporte de leite à Italac em " 
_cMsgTrans+= AllTrim(Str((_cAlias)->PARC)) + " (" + AllTrim(Extenso((_cAlias)->PARC,.T.)) + ") parcela(s) igual(is) de R$ " + AllTrim(Transform((_cAlias)->VLRPAR,"@E 999,999,999,999.99")) + " "   
_cMsgTrans+= "(" + AllTrim(Extenso((_cAlias)->VLRPAR,.F.)) + ")" + _cJuros + "."

impTexto(_cMsgTrans)    
nlinha+=nSaltoLinha

_cMsgTrans:= 'Mediante ao exposto acima, me comprometo a transportar leite regularmente conforme descrito nas instruções e procedimentos internos da Italac que '
_cMsgTrans+= "regulamentam o transporte de leite em latões e desde de já a Italac fica AUTORIZADA também a fazer o desconto de todo o saldo devedor, se por qualquer motivo eu deixar de trasnportar leite."

impTexto(_cMsgTrans) 
nlinha+=nSaltoLinha

_cMsgTrans:= "Vinculam-se a presente declaração a(s) nota(s) promissória(s) em anexo, que poderá(ão) ser executada(s) em caso de inadimplência."                     

impTexto(_cMsgTrans)  
nlinha+=nSaltoLinha

_cMsgTrans:= "Por ser verdade, assino a presente solicitação/autorização, na presença de duas testemunhas."
impTexto(_cMsgTrans)

Return

/*
===============================================================================================================================
Programa--------: impTexto
Autor-----------: Fabiano Dias
Data da Criacao-: 05/09/2011
Descrição-------: Funçãoo para realizar a formataçãoo, ou seja, justificar o texto para que o mesmo fique melhor disposto no
				  corpo da página.
Parametros------: _cTexto -> Texto a ser formatado de forma justificada
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function impTexto(_cTexto)

Local _aTexto   := Separa(_cTexto," ",.F.)//Quebro o texto em palavras
Local _nNumCarac:= 073 //Numero maximo de caracteres por linha

Local _cLinImpr := "" //Texto de impressao inicial do array
Local _nPosInic := 1 //Posicao inicial do array que comecou uma linha     
Local _nNumEspac:= 0 //Numero de espacos vazios necessario para justificar o texto
Local _nNumPalav:= 0 

Local _lEntrou  := .F.    
Local _nVlrDiv  := 0
Local _nEspacame:= 0      

Local _nEspcAdic:= 0                
Local _nVlrEspac:= 0
Local _nK		:= 0
Local _nX		:= 0

//Para que todo inicio de nova linha seja impresa como um paragrafo
_aTexto[1]:= "       "  + _aTexto[1]                           

//Percorre todas as palavras quebradas por espaco do texto passado como parametro
For _nX:=1 to Len(_aTexto)

	_lEntrou  := .F. 
	_nNumPalav++                     	  	                     	

	//Verifica se eh a primeira palavra a ser inserida
	If Len(_cLinImpr) == 0
		_cLinImpr := _aTexto[_nX]
 	Else				
	  	If Len(_cLinImpr + " " + _aTexto[_nX]) <= _nNumCarac
			_cLinImpr += " " + _aTexto[_nX]
		ElseIf Len(_cLinImpr) < _nNumCarac 
			//Numero de espacos em branco a complementar					                                                    					
			_nNumEspac:= _nNumCarac - Len(_cLinImpr) 	
			_cLinImpr := ""					 					 					                  					
					
			//Se numero de caracteres For possivel de se distribuir os espacos em branco entre os numero de palavras
			If _nNumEspac < _nNumPalav - 2												
				For _nK:=_nPosInic to _nX-1  
					If Len(_cLinImpr) == 0
						_cLinImpr := _aTexto[_nK]
					Else
						If _nNumEspac > 0   
							_cLinImpr += "  " + _aTexto[_nK]
							_nNumEspac-= 1
						Else
							_cLinImpr += " " +_aTexto[_nK]
						EndIf   
					EndIf					                                						   							
				Next _nK
			                    			                
			//==================================================================
			//Caso o numero de espacos em branco a complementar a linha atual
			//seja maior que o numero de palavras da linha atual
			//==================================================================
			Else          			                	               
				_nEspcAdic:= 0
			    _nNumPalav:= _nNumPalav - 2//Numero de palavras a serem consideradas para insercao dos espacos em branco			                		
			    _nVlrDiv  := Mod(_nNumEspac,_nNumPalav)//Divisao para constatar se o numero de espacos em branco dividido pelo numero de palavras eh multiplo									    
				_nEspacame:= Int(_nNumEspac / _nNumPalav)
				
				//Contabiliza o numero de caracteres restantes entre o multiplo da divisao para ser valores adicionais
				If _nVlrDiv != 0 
					_nEspcAdic:= _nNumEspac - (_nNumPalav * _nEspacame)
				EndIf 
									    
				For _nK:=_nPosInic to _nX-1  
					If Len(_cLinImpr) == 0
						_cLinImpr := _aTexto[_nK]
					Else			  
						If _nEspcAdic > 0
							_nEspcAdic-- 																			
							_nVlrEspac:= _nEspacame + 2
						Else
							_nVlrEspac:= _nEspacame + 1
						EndIf
						_cLinImpr += Space(_nVlrEspac) + _aTexto[_nK]
					EndIf
				Next _nK
		  	EndIf    	                 	                	                	                

		    _nPosInic:= _nX
            //Para que a palavra que nao foi impressa neste Loop seja impressa na proxima execucao
            _nX:= _nX-1
            _lEntrou:= .T.     
		EndIf 	
	EndIf         		

	//Imprime de acordo com o numero maximo de caracteres montados a linha formatada anteriormente
	If Len(_cLinImpr) == _nNumCarac
	  
		oPrint:Say (nlinha + nAjuAltLi1,nColInic + 20,_cLinImpr,oFont14) 
		nlinha+=nSaltoLinha
		
		_cLinImpr:= ""     
		_nNumPalav:= 0
		            
		If !_lEntrou
			_nPosInic:= _nX + 1
		EndIf
	
	EndIf

Next _nX


//Imprime a ultima parte da mensagem que eh menor do que o numero de caracteres estipulado por linha
If Len(_cLinImpr) < _nNumCarac 
	oPrint:Say (nlinha + nAjuAltLi1,nColInic + 20,_cLinImpr,oFont14) 
	nlinha+=nSaltoLinha
EndIf

Return          

/*
===============================================================================================================================
Programa--------: impPromiss
Autor-----------: Fabiano Dias
Data da Criacao-: 05/09/2011
Descrição-------: Funcao para realizar a impressao das notas promissorias das parcelas do emprestimo/adiantamento/antecipacao
Parametros------: _cAlias -> Alias contendo os registros da query principal
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function impPromiss(_cAlias)

Local _cAlias2	:= GetNextAlias()
Local _cFiltro	:= "%"
Local _cCampo	:= "%"
Local _cTabela	:= "%"
Local _cOrder	:= "%"
Local _cAux	:= IIf(FUNNAME() == "AGLT012","ZLO","ZLQ")
Local _nQbrPag	:= 0
Local _nContrBox:= 0

Private cRaizServer := If(issrvunix(), "/", "\")  
Private _nLargAval  := 400
               
//Seta a coluna incial com este valor para melhor aproveitamento de toda a pagina, diferentemente da declaracao      
nColInic:= 0030                     

//====================================================================================================
// Monta filtro de acordo com a tabela de origem
//====================================================================================================
_cCampo += _cAux +"_ITEM ITEM, "+ _cAux +"_VECTO VECTO, "+ _cAux +"_VALOR VALOR "
_cTabela += RetSqlName(_cAux) +" "+ _cAux + " "
_cFiltro += " AND "+ _cAux +"_Filial = '" + xFilial(_cAux) + "'"
_cFiltro += " AND "+ _cAux +"_COD = '"+ (_cAlias)->CODIGO+ "'"
_cOrder += _cAux +"_ITEM"

_cCampo += "%"
_cTabela += "%"
_cFiltro += "%"
_cOrder += "%"

//Query para selecionar os itens do emprestimo para impressao das promissorias
BeginSql alias _cAlias2
	SELECT %exp:_cCampo%
	FROM %exp:_cTabela%
	WHERE D_E_L_E_T_ = ' '
	%exp:_cFiltro%
	ORDER BY %exp:_cOrder%
EndSql

While !(_cAlias2)->(Eof())

	//Indica que a cada tres paginas devera ser criada uma nova pagina para impressao das notas promissorias
	If Mod(_nQbrPag,3) == 0 //.And. _nQbrPag <> 0    
		oPrint:EndPage()	// Finaliza a Pagina.
		oPrint:StartPage() // Inicia uma nova Pagina
		_nContrBox:= 0   			
	EndIf    		
	//Define a posicao inicial do Box
	nLinInBox:=  (_nContrBox * 1000) + 100 + (_nContrBox * 100)
	_nContrBox++
	promissori(_cAlias,_cAlias2)  
	_nQbrPag++	               

	(_cAlias2)->(DBSkip())
EndDo
	
(_cAlias2)->(DBCloseArea())

Return

/*
===============================================================================================================================
Programa--------: promissori
Autor-----------: Fabiano Dias
Data da Criacao-: 05/09/2011
Descrição-------: Função para imprimir a promissoria corrente.
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function promissori(_cAlias,_cAlias2)  
                                         
oPrint:Box(nLinInBox,nColInic,nLinInBox + 1000,nColFinal)   
oPrint:Line(nLinInBox,_nLargAval,nLinInBox + 1000,_nLargAval)
oPrint:SayBitmap(nLinInBox + 20,nColInic + 20,cRaizServer + "system/avalista.bmp",340,970) 
nLinInBox+=nSaltoLinha
oPrint:Say (nLinInBox + nAjuAltLi1,nColFinal / 2,"Vencimento: " + cValToChar(Day(SToD((_cAlias2)->VECTO))) + " de " +AllTrim(MesExtenso(Month(SToD((_cAlias2)->VECTO)))) + " de " + cValToChar(Year(SToD((_cAlias2)->VECTO))) + ".",oFont12) 
nLinInBox+=nSaltoLinha
nLinInBox+=nSaltoLinha
oPrint:Say (nLinInBox + nAjuAltLi1,nColInic  + _nLargAval + 100,"No: " + (_cAlias)->CODIGO + "/" + AllTrim(Str(Val((_cAlias2)->ITEM))),oFont12b) 
oPrint:Say (nLinInBox + nAjuAltLi1,nColFinal - 500,"R$: " + AllTrim(Transform((_cAlias2)->VALOR,"@E 999,999,999,999.99")),oFont12b) 
nLinInBox+=nSaltoLinha   
nLinInBox+=nSaltoLinha

qbrTexto("No dia " + cValToChar(Day(SToD((_cAlias2)->VECTO))) + " de " + AllTrim(MesExtenso(Month(SToD((_cAlias2)->VECTO)))) + " de " + cValToChar(Year(SToD((_cAlias2)->VECTO))) + " pagarei por esta única via de NOTA PROMISSÓRIA") 

qbrTexto("a " + AllTrim(SM0->M0_NOMECOM) + " CPF/CNPJ " + Transform(SM0->M0_CGC,"@R! NN.NNN.NNN/NNNN-99"))

qbrTexto("OU À SUA ORDEM, A QUANTIA DE " + AllTrim(Extenso((_cAlias2)->VALOR,.F.)))

qbrTexto("Local de Pagamento: " + AllTrim(SM0->M0_ENDCOB) + " Data da Emissão: " +  DToC(SToD((_cAlias)->DATA)))

qbrTexto("Nome do Emitente: " + (_cAlias)->A2_COD + "/" + (_cAlias)->A2_LOJA + " - " + AllTrim((_cAlias)->A2_NOME)) 

qbrTexto("CPF/CNPJ: " + IIf((_cAlias)->A2_TIPO == 'J',Transform((_cAlias)->A2_CGC,"@R! NN.NNN.NNN/NNNN-99"),Transform((_cAlias)->A2_CGC,"@R 999,999,999-99")) + " Endereço: " + AllTrim((_cAlias)->A2_END) + " Cidade: " + AllTrim((_cAlias)->CC2_MUN) + "-" + (_cAlias)->A2_EST)
nLinInBox+=nSaltoLinha 
nLinInBox+=nSaltoLinha

oPrint:Line(nLinInBox,_nLargAval + 20,nLinInBox,nColFinal - 20)
nLinInBox+=nSaltoLinha 
oPrint:Say (nLinInBox - 20,(nColFinal + _nLargAval) / 2,'Assinatura do Emitente',oFont12b,nColFinal + _nLargAval,,,2)

Return                   

/*
===============================================================================================================================
Programa--------: qbrTexto
Autor-----------: Fabiano Dias
Data da Criacao-: 05/09/2011
Descrição-------: Quebra o texto passado como parametro para que sejam impressos somente 86 caracteres por linha, nao sera
				  permitida a quebra de uma palavra caso a mesma nao caiba integralmente na linha corrente.
Parametros------: _cTexto -> Texto a ser impresso de forma justificada
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function qbrTexto(_cTexto)

Local _aTexto   := Separa(_cTexto," ",.F.)//Quebro o texto em palavras
Local _nNumCarec:= 86   
Local _cLinImp  := ""
Local _nX		:= 0
Local _lImprime := .F.
                     
For _nX:=1 to Len(_aTexto)

	_lImprime := .F.
     
	//Primeira palavra da Frase              
	If Len(_cLinImp) == 0
		_cLinImp:= _aTexto[_nX]
	Else
		If Len(_cLinImp + _aTexto[_nX])   < _nNumCarec                  
			_cLinImp += " " + _aTexto[_nX]
		Else  
			oPrint:Say (nLinInBox + nAjuAltLi1,nColInic + _nLargAval,_cLinImp,oFont12)
			nLinInBox+=nSaltoLinha   
			//Volta o valor de x pelo fato da palavra corrente nao ter sido impressa
			_nX:= _nX-1     
			//Seta variavel de controle da linha de impressao
			_cLinImp:= ""
			//Seta variavel de controle para constatar se tudo foi impresso
			_lImprime := .T.
		EndIf	
	EndIf
	
Next _nX
    
//Imprime os dados da ultima linha que ainda nao foram impressos
If !_lImprime
	oPrint:Say (nLinInBox + nAjuAltLi1,nColInic + _nLargAval,_cLinImp,oFont12)
	nLinInBox+=nSaltoLinha   
EndIf

Return
