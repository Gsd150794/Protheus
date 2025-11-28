/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |09/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25
Julio Paz     |08/03/2021| Chamado 35771. Incluir recurso para copiar arquivo gerado para o browse do usuário em acesso Web
Lucas Borges  |04/06/2025| Chamado 50899, 50901. Corrgida a exportação do arquivo usando ProtheusWeb
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: AFIN017
Autor-------------: Fabiano Dias
Data da Criacao---: 13/08/2009
Descrição---------: Gera XML (Excel) de Titulos em Aberto no Contas a Pagar 
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AFIN017

Local _cPerg	:="AFIN017" As Character

//Cria interface principal
tNewProcess():New(	_cPerg						,; // cFunction. Nome da função que está chamando o objeto
					"Exporta Contas a Pagar"		,; // cTitle. Título da árvore de opções
					{|_oSelf| AFIN017P(_oSelf) },; // bProcess. Bloco de execução que será executado ao confirmar a tela
					"Gera XML (Excel) de Titulos em Aberto no Contas a Pagar  ",; // cDescription. Descrição da rotina
					_cPerg						,; // cPerg. Nome do Pergunte (SX1) a ser utilizado na rotina
					{}							,; // aInfoCustom. Informações adicionais carregada na árvore de opções. Estrutura:[1] - Nome da opção[2] - Bloco de execução[3] - Nome do bitmap[4] - Informações do painel auxiliar.
					.F.							,; // lPanelAux. Se .T. cria um novo painel auxiliar ao executar a rotina
					0							,; // nSizePanelAux. Tamanho do painel auxiliar, utilizado quando lPanelAux = .T.
					''							,; // cDescriAux. Descrição a ser exibida no painel auxiliar
					.T.							,; // lViewExecute. Se .T. exibe o painel de execução. Se falso, apenas executa a função sem exibir a régua de processamento
					.T.							,; // lOneMeter. Se .T. cria apenas uma régua de processamento
					.T.							)  // lSchedAuto. Se .T. habilita o botão de processamento em segundo plano (execução ocorre pelo Scheduler)

Return

/*
===============================================================================================================================
Função------------: AFIN017P
Autor-------------: Abrahao/Fabiano
Data da Criacao---: 10/08/2009
Descrição---------: Localiza Titulos e gera XML. 
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AFIN017P(_oSelf As Object)

Local _cDrive 		:= "" As Character
Local _cDir 		:= "" As Character
Local _cNome 		:= "" As Character
Local _cExt 		:= "" As Character
Local cNome		  	:="" As Character
Local aDados	  	:={} As Array
Local nSubTotal   	:=0 As Numeric
Local cUltDay	  	:="" As Character
Local nTotal	  	:=0 As Numeric
Local cNatureza   	:= "" As Character
Local cFiltro     	:= "" As Character
Local dOldData    	:= CToD('//') As Date
Local nMoeda	  	:= 1 As Numeric
Local x			  	:= 0 As Numeric
Local _cAliasSE2	:= GetNextAlias()
Local _nSaldoTit	:= 0 As Numeric
Local aDadosExp 	:= {} As Array
Local _oFile		:= Nil As Object

SplitPath(AllTrim(MV_PAR05), @_cDrive, @_cDir, @_cNome, @_cExt )
_oFile:= FWFileWriter():New(__RelDir+_cNome+_cExt)

If Empty(MV_PAR05)
	FWAlertWarning('Nome do arquivo não informado!','AFIN01701')
	Return
ElseIf !_oFile:Create()
	MsgStop("Erro ao criar aqruivo. A rotina não será executada!", "AFIN01702")
	Return
Else
	//Verifica se o usuario forneceu um tipo de titulo que seja igual 
	If !Empty(MV_PAR10)
		cFiltro   += " AND E2_TIPO IN " + FormatIn(MV_PAR10,";")
	EndIf   

	//Verifica se o usuario forneceu um tipo de titulo que seja diferente
	If !Empty(MV_PAR11)
		cFiltro   += " AND E2_TIPO NOT IN " + FormatIn(MV_PAR11,";")
	EndIf        

	//Tipo do Fornecedor
	If !Empty(MV_PAR14)
		cFiltro   += " AND A2_I_CLASS IN " + FormatIn(MV_PAR14 ,";")
	EndIf  
		
	cQuery := "SELECT"  
	cQuery += " E2.E2_FILIAL,E2.E2_PREFIXO,E2.E2_TIPO,E2.E2_NUM,E2.E2_PARCELA,E2.E2_FORNECE,E2.E2_LOJA,E2.E2_TXMOEDA,"
	cQuery += " E2.E2_BAIXA,E2.E2_NATUREZ,E2.E2_VENCREA,E2.E2_SALDO,E2.E2_SDACRES,E2.E2_SDDECRE,E2_NOMFOR A2_NOME,E2.R_E_C_N_O_ RECNOSE2,"    
	cQuery += " E2.E2_VALOR,E2.E2_DECRESC,E2_ACRESC,E2_HIST,"
	cQuery += " (SELECT ED.ED_DESCRIC FROM " + RetSqlName("SED") + " ED WHERE ED.ED_CODIGO = E2.E2_NATUREZ AND ED.D_E_L_E_T_= ' ') ED_DESCRIC "	 	
	cQuery += "FROM " +RETSQLNAME("SE2")+" E2 "   
	cQuery += " JOIN "+RETSQLNAME("SA2")+" SA2 ON E2.E2_FORNECE = SA2.A2_COD AND E2.E2_LOJA = SA2.A2_LOJA "   
	cQuery += "WHERE E2.D_E_L_E_T_ = ' ' "
	cQuery += " AND SA2.D_E_L_E_T_ = ' ' "
	cQuery += " AND E2.E2_FILIAL BETWEEN '"  + MV_PAR06    + "' AND '" + MV_PAR07    + "' "
	cQuery += " AND E2.E2_EMISSAO BETWEEN '" + DToS(MV_PAR01)   + "' AND '" + DToS(MV_PAR02)   + "' "
	cQuery += " AND E2.E2_VENCREA BETWEEN '" + DToS(MV_PAR08)  + "' AND '" + DToS(MV_PAR09)  + "' "
	cQuery += " AND E2.E2_NATUREZ BETWEEN '" + MV_PAR12  + "' AND '" + MV_PAR13  + "' " 
	cQuery += cFiltro   
	//================================================================================================================================================     
	// Compoe saldo do titulo For iguar a Nao, ou seja, nao calcula saldo do titulo de acordo com a data informada pelo usuario e sim pelo saldo atual
	//================================================================================================================================================     
	If !MV_PAR03 == 1
		cQuery += " AND E2.E2_SALDO > 0"
	EndIf 
		
	//========================	
	// Relatorio Analitico
	//========================
	If MV_PAR15 == 1	
		cQuery+=" ORDER BY E2_VENCREA,E2_NOMFOR,E2_PREFIXO,E2_NUM,E2_PARCELA,E2_TIPO" 	
	Else
		cQuery+=" ORDER BY E2_VENCREA,E2_NOMFOR,E2_PREFIXO,E2_NUM,E2_PARCELA,E2_TIPO"
	EndIf	      

	cQuery := ChangeQuery(cQuery)
	MPSysOpenQuery(cQuery,_cAliasSE2)
	DBSelectArea(_cAliasSE2)

	Count to nreg
	_oSelf:SetRegua1(nreg)

	(_cAliasSE2)->(DBGoTop())  
	While (_cAliasSE2)->(!Eof()) 
		_oSelf:IncRegua1("Processando dados do Titulo: " + AllTrim((_cAliasSE2)->E2_NUM) + '/' + (_cAliasSE2)->E2_PARCELA)
		
		_nSaldoTit:= 0              
		//======================================
		// Calcula saldo a partir da data base 
		//======================================
		If MV_PAR03 == 1     
			//====================================================================================     			 		          
			// Para que essa funcao funcione eh necessario que antes esteja posicionado no titulo
			//====================================================================================     
			SE2->(DBGoTo((_cAliasSE2)->RECNOSE2))
			
			_nSaldoTit:= SaldoTit((_cAliasSE2)->E2_PREFIXO,;             			//PREFIXO DO TITULO
								(_cAliasSE2)->E2_NUM,;                 			//NUMERO DO TITULO
								(_cAliasSE2)->E2_PARCELA,;             			//PARCELA DO TITULO
								(_cAliasSE2)->E2_TIPO,;                			//TIPO DO TITULO
								(_cAliasSE2)->E2_NATUREZ,;            			//NATUREZA DO TITULO
								"P",;                                  			//TIPO DA CARTEIRA A PAGAR OU RECEBER - P == PAGAR - R == RECEBER
								(_cAliasSE2)->E2_FORNECE,;            			//CODIGO DO FORNECEDOR
								nMoeda,; 								 			//CODIGO DA MOEDA CORRENTE 
								SToD((_cAliasSE2)->E2_VENCREA),;        			//DATA DE CONVERSAO 
								MV_PAR04,;                            			//DATA DA BAIXA A SER CONSIDERADA (RETROATIVA) - SER For IGUAL OU MAIOR CONSIDERA A BAIXA
								(_cAliasSE2)->E2_LOJA,;              				//CODIGO DA LOJA DO FORNECEDOR DO TITULO CORRENTE
								(_cAliasSE2)->E2_FILIAL,;   						//FILIAL DO TITULO
								If(cPaisLoc=="BRA",(_cAliasSE2)->E2_TXMOEDA,0)) //TAXA DA MOEDA   
					//==================================================================     				  
					// Subtrai decrescimo para recompor o saldo na data escolhida.
					//==================================================================     
					If Str((_cAliasSE2)->E2_VALOR,17,2) == Str(_nSaldoTit,17,2) .And. (_cAliasSE2)->E2_DECRESC > 0 .And. (_cAliasSE2)->E2_SDDECRE == 0
						_nSaldoTit -= SE2->E2_DECRESC
					EndIf
					//==================================================================     
					// Soma Acrescimo para recompor o saldo na data escolhida.
					//==================================================================     
					If Str((_cAliasSE2)->E2_VALOR,17,2) == Str(_nSaldoTit,17,2) .And. (_cAliasSE2)->E2_ACRESC > 0 .And. (_cAliasSE2)->E2_SDACRES == 0
						_nSaldoTit += SE2->E2_ACRESC
					EndIf		
					//=========================              
					// MVPAGANT == PA
					// MV_CPNEG == NDF
					//=========================
					If ! ((_cAliasSE2)->E2_TIPO $ MVPAGANT+"/"+MV_CPNEG) .And. ;
					! (_nSaldoTit == 0 ) // nao deve olhar abatimento pois e zerado o saldo na liquidacao final do titulo
					//==================================================================      
					// Quando considerar Titulos com emissao futura, eh necessario
					// colocar-se a database para o futuro de forma que a Somaabat()
					// considere os titulos de abatimento
					//==================================================================     
						dOldData  := dDataBase
						dDataBase := CTOD("31/12/40")

						_nSaldoTit -= SomaAbat((_cAliasSE2)->E2_PREFIXO,(_cAliasSE2)->E2_NUM,(_cAliasSE2)->E2_PARCELA,"P",nMoeda,SToD((_cAliasSE2)->E2_VENCREA),(_cAliasSE2)->E2_FORNECE,(_cAliasSE2)->E2_LOJA)

						dDataBase := dOldData
					EndIf
				//========================================================================     
				// Nao calcula saldo a partir da data base e sim o saldo atual do titulo
				//========================================================================     
			Else
				_nSaldoTit:= ( (_cAliasSE2)->E2_SALDO + (_cAliasSE2)->E2_SDACRES ) - (_cAliasSE2)->E2_SDDECRE
			EndIf
			//===============================================================================================================================                     
			// Somente se houver saldo no Titulo corrente para ser considerado, efetua a aglutinacao dos dados para posterior geracao de XML
			//===============================================================================================================================     
			If Abs(_nSaldoTit) > 0.0001    
				If (_cAliasSE2)->E2_TIPO == 'NDF' .Or. (_cAliasSE2)->E2_TIPO == 'PA ' 	
					_nSaldoTit:= _nSaldoTit * -1
				EndIf		     
				DadosExpor(_cAliasSE2,_nSaldoTit, @aDadosExp)
			EndIf

		(_cAliasSE2)->(DBSkip())
	EndDo               
		
	DBSelectArea(_cAliasSE2)
	(_cAliasSE2)->(DBCloseArea())                                             
	//============================                                                                   
	// Relatorio Analitico
	//============================
	If MV_PAR15 == 1	
		aAdd( aDados , { "Vencto","Codigo Fornecedor","Desc. Fornecedor","Tipo","Nota","Parcela","Codigo Natureza","Desc. Natureza","Saldo","Historico" } )   
		aAdd( aDados , { "","","","","","","","","",""})//Imprime Linhas em branco     
		//=============================
		// Relatorio Sintetico
		//=============================
		Else
			aAdd( aDados , { "Vencto","Codigo Fornecedor","Desc. Fornecedor","Tipo","Codigo Natureza","Desc. Natureza","Saldo" } )   
			aAdd( aDados , { "","","","","","",""})//Imprime Linhas em branco     
	EndIf                    
	//========================
	// Relatorio Analitico
	//========================
	If MV_PAR15 == 1
		For x:=1 To Len(aDadosExp)                                     
			IncProc("Gerando XML do Titulo: " + aDadosExp[x,6] + '/' + aDadosExp[x,7])
			//==============================
			// Mostra SubTotal por Dia
			//==============================
			If aDadosExp[x,3] != cUltDay .And. nSubTotal <> 0
				aAdd( aDados , { "" ,"Subtotal","","","","","","",nSubTotal,""  })	
				aAdd( aDados , { "",""         ,"","","","","","","",""         })//Imprime Linhas em branco
				nSubTotal:=0
			EndIf
			cUltDay := aDadosExp[x,3]
		
			//==================================
			// Adiciona Dados no array
			//==================================
			cNome	 := Posicione("SA2",1,xFilial("SA2") + aDadosExp[x,4] + aDadosExp[x,5],"A2_NOME") 
			cNome	 := RemovCar(AllTrim(cNome))//Funcao que remove caracteres especiais para nao ocorrer erro na geracao do xml	      
			cNatureza:= RemovCar(AllTrim(aDadosExp[x,9])) 
			aAdd( aDados , { DToC(SToD(aDadosExp[x,3])) , ;
									AllTrim(aDadosExp[x,4]) + '/' + AllTrim(aDadosExp[x,5]),;
									AllTrim(cNome),;
									aDadosExp[x,10],;
									aDadosExp[x,6],;
									aDadosExp[x,7],;
									aDadosExp[x,8],;
									cNatureza,;
									aDadosExp[x,2],;
									aDadosExp[x,11]})	
			
			nSubTotal+= aDadosExp[x,2] 
			nTotal   += aDadosExp[x,2] 
		Next x			                        
		
		//==================================
		// SubTotal e Total Geral
		//==================================
		aAdd( aDados , { "" ,"Subtotal","","","","","","",nSubTotal  })		
		aAdd( aDados , { "" ,""        ,"","","","","","",""         })//Imprime Linhas em branco
		aAdd( aDados , { "" ,"Total"   ,"","","","","","",nTotal     })
		//======================        
		// Relatorio Sintetico
		//======================
	Else         
		For x:=1 To Len(aDadosExp)                                    
			IncProc("Gerando XML do Vencimento: " + DToC(SToD(aDadosExp[x,3])))
		
			// Mostra SubTotal por Dia
			If aDadosExp[x,3] != cUltDay .And. nSubTotal <> 0
				aAdd( aDados , { "" ,"Subtotal","","","","",nSubTotal  })	
				aAdd( aDados , { "",""         ,"","","","",""         })//Imprime Linhas em branco
				nSubTotal:=0
			EndIf                    
			
			cUltDay := aDadosExp[x,3]

			// Adiciona Dados no array
			cNome	 := Posicione("SA2",1,xFilial("SA2")+aDadosExp[x,4]+aDadosExp[x,5],"A2_NOME") 
			cNome	 := RemovCar(AllTrim(cNome))//Funcao que remove caracteres especiais para nao ocorrer erro na geracao do xml	      
			cNatureza:= RemovCar(AllTrim(aDadosExp[x,7])) 
			aAdd( aDados , { DToC(SToD(aDadosExp[x,3])), AllTrim(aDadosExp[x,4]) + '/' + AllTrim(aDadosExp[x,5]),AllTrim(cNome),;
							aDadosExp[x,8],aDadosExp[x,6],cNatureza,aDadosExp[x,2]})	

				nSubTotal+= aDadosExp[x,2]
				nTotal   += aDadosExp[x,2] 
			Next x

		// SubTotal e Total Geral
		aAdd( aDados , { "" ,"Subtotal","","","","",nSubTotal  })		
		aAdd( aDados , { "" ,""        ,"","","","",""         })//Imprime Linhas em branco
		aAdd( aDados , { "" ,"Total"   ,"","","","",nTotal     })

	EndIf
	
	RayToXml(aDados,_oFile)

	If GetRemoteType() == 5 //SmartClient HTML sem WebAgent
		CpyS2TW(__RelDir+_cNome+_cExt)  // Copia o arquivo para o Browse de navegação Web do usuário
	Else	
		CpyS2T(__RelDir+_cNome+_cExt,_cDrive+_cDir)
	EndIf
	_oFile:Erase()
	_oFile:= Nil
EndIf 

Return

/*
===============================================================================================================================
Programa----------: RayToXml
Autor-------------: Abrahao P. Santos
Data da Criacao---: 22/12/2008 
Descrição---------: Cria um arquivo XML de um Array.                                                                            
                    Converte array para XLM.
Parametros--------: aTabela = Array de dados.
                    _oFile = Objeto do arquivo
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RayToXml(aTabela As Array,_oFile As Object)
                                    
Local aVenciment:= {} As Array
Local y,i		:= 0 As Numeric
Local _cBuffer := '' As Character


//==================================
// Cabecalho do XML
//==================================
_cBuffer := '<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?> '
_cBuffer += '<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet" '
_cBuffer += ' xmlns:o="urn:schemas-microsoft-com:office:office" '
_cBuffer += ' xmlns:x="urn:schemas-microsoft-com:office:excel" '
_cBuffer += ' xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet" '
_cBuffer += ' xmlns:html="http://www.w3.org/TR/REC-html40"> '
_cBuffer += ' <Styles><Style ss:ID="Default" ss:Name="Normal"></Style><Style ss:ID="s21"><NumberFormat ss:Format="Short Date"/></Style></Styles> '
_cBuffer += ' <Worksheet ss:Name="Planilha"><Table> '

//==================================
// Convertendo Array
//==================================
For i:=1 to Len(aTabela)        
	If ValType(aTabela[i,1]) == "C"    
		If aScan(aVenciment,{|x| x[1] == aTabela[i,1] }) == 0
			_cBuffer+="<Row>"      
			_cBuffer+='<Cell><Data ss:Type="String">'+aTabela[i,1]+'</Data></Cell>'   
			_cBuffer += "</Row>"   
			aAdd(aVenciment,{aTabela[i,1]})
		EndIf
	EndIf	
	// inicia linha
	_cBuffer+="<Row>"
	
	For y:=2 to Len(aTabela[i])
		If ValType(aTabela[i,y]) == "N"
			_cBuffer+='<Cell><Data ss:Type="Number">'+AllTrim(Str(aTabela[i,y]))+'</Data></Cell>'
		ElseIf ValType(aTabela[i,y]) == "D"
		ElseIf ValType(aTabela[i,y]) == "C"
			_cBuffer+='<Cell><Data ss:Type="String">'+aTabela[i,y]+'</Data></Cell>'  
		Else
			_cBuffer+='<Cell><Data ss:Type="String"></Data></Cell>'	
		EndIf
	Next y
	//===================
	// finaliza linha
	//===================
	_cBuffer+="</Row>"
Next i

//==================================
// Rodape do XML
//==================================
_cBuffer += '</Table></Worksheet></Workbook>'
_oFile:Write(_cBuffer)
_oFile:Close()

Return

/*
===============================================================================================================================
Programa----------: RemovCar
Autor-------------: Fabiano Dias
Data da Criacao---: 18/06/2010
Descrição---------: Remove caractres especias para que nao gere erro ao gerar o xml                                                                            
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RemovCar(cString As Character)

cString:= StrTran(cString,'&',"")
cString:= StrTran(cString,'<',"")
cString:= StrTran(cString,'>',"")
cString:= StrTran(cString,'%',"")
cString:= StrTran(cString,'~',"")
cString:= StrTran(cString,'^',"") 
cString:= StrTran(cString,'´',"")
cString:= StrTran(cString,'`',"")

Return cString                

/*
===============================================================================================================================
Programa----------: FiltrTpTit
Autor-------------: Fabiano Dias
Data da Criacao---: 21/06/2010
Descrição---------: Monta Tela para consulta dos tipos de Titulos do financeiro. 
                    Tem por objetivo auxiliar na escolha dos tipos de titulos                                                      
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function FiltrTpTit()

Local i := 0 As Logical
Local _cAlias := GetNextAlias() As Character

Local nTam      := 0 As Numeric
Local nMaxSelect:= 0 As Numeric
Local aCat      := {} As Array
Local MvRet     := AllTrim(ReadVar()) As Variant
Local MvPar     := "" As Character
Local cTitulo   := "" As Character
Local MvParDef  := "" As Character

#IFDEF WINDOWS
	oWnd := GetWndDefault()
#EndIf

//==========================================================
// Tratamento para carregar variaveis da lista de opcoes
//==========================================================
nTam:= 3
nMaxSelect := 18 //75 / 4
cTitulo := "Tipos de Titulos"
BeginSql alias _cAlias
	SELECT X5_CHAVE CHAVE,X5_DESCRI DESCRI
	FROM %Table:SX5%
	WHERE D_E_L_E_T_ = ' ' 
	AND X5_TABELA  = '05'
	AND X5_CHAVE >= '0'
	AND X5_FILIAL = %xFilial:SX5%
	ORDER BY X5_CHAVE
EndSql

While (_cAlias)->(!Eof()) 
	MvParDef += SubStr((_cAlias)->CHAVE,1,nTam)
	aAdd(aCat,AllTrim((_cAlias)->DESCRI)) 
	(_cAlias)->(DBSkip())
EndDo
(_cAlias)->(DBCloseArea())
//======================================================================
// Trativa abaixo para no caso de uma alteracao do campo trazer todos
// os dados que foram selecionados anteriormente.                    
//======================================================================
If Len(AllTrim(&MvRet)) == 0                              
	MvPar:= PadR(AllTrim(StrTran(&MvRet,";","")),Len(aCat))
	&MvRet:= PadR(AllTrim(StrTran(&MvRet,";","")),Len(aCat))
Else
	MvPar:= AllTrim(StrTran(&MvRet,";","/"))
EndIf

// Somente altera o conteudo caso o usuario clique no botao ok
// Executa funcao que monta tela de opcoes
If f_Opcoes(@MvPar,cTitulo,aCat,MvParDef,12,49,.F.,nTam,nMaxSelect)        
	// Tratamento para separar retorno com barra ";"
	&MvRet := ""
	For i:=1 to Len(MvPar) step nTam
		If !(SubStr(MvPar,i,1) $ " |*")
			&MvRet  += SubStr(MvPar,i,nTam) + ";"
		EndIf
	Next i
	// Trata para tirar o ultimo caracter
	&MvRet := SubStr(&MvRet,1,Len(&MvRet)-1) 

EndIf     

Return(.T.)
      
/*
===============================================================================================================================
Programa----------: DadosExpor
Autor-------------: Fabiano Dias
Data da Criacao---: 21/06/2010
Descrição---------: Monta array com dados a exportar.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function DadosExpor(_cAliasSE2 As Character, _nSaldoTit As Numeric, aDadosExp As Array)

Local _cChave  := "" As Character
Local _nPosicao:= 0 As Numeric

// Relatorio Analitico
If MV_PAR15 == 1
	_cChave:= "(_cAliasSE2)->E2_VENCREA + (_cAliasSE2)->E2_FORNECE + (_cAliasSE2)->E2_LOJA + (_cAliasSE2)->E2_NUM + (_cAliasSE2)->E2_PARCELA + (_cAliasSE2)->E2_NATUREZ + (_cAliasSE2)->E2_TIPO"
Else
	_cChave:= "(_cAliasSE2)->E2_VENCREA + (_cAliasSE2)->E2_FORNECE + (_cAliasSE2)->E2_LOJA + (_cAliasSE2)->E2_NATUREZ + (_cAliasSE2)->E2_TIPO"
EndIf

_nPosicao:= aScan(aDadosExp,{|x| x[1] == &(_cChave)})

If MV_PAR15 == 1
	If _nPosicao == 0
		aAdd(aDadosExp,{&(_cChave),;
						_nSaldoTit,;
						(_cAliasSE2)->E2_VENCREA,;
						(_cAliasSE2)->E2_FORNECE,;
						(_cAliasSE2)->E2_LOJA,;
		                (_cAliasSE2)->E2_NUM,;
		                (_cAliasSE2)->E2_PARCELA,;
		                (_cAliasSE2)->E2_NATUREZ,;
		                (_cAliasSE2)->ED_DESCRIC,;
		                (_cAliasSE2)->E2_TIPO,;
		                (_cAliasSE2)->E2_HIST})
	Else
		aDadosExp[_nPosicao,2]+= _nSaldoTit
	EndIf
Else
	If _nPosicao == 0
		aAdd(aDadosExp,{&(_cChave),;
						_nSaldoTit,;
						(_cAliasSE2)->E2_VENCREA,;
						(_cAliasSE2)->E2_FORNECE,;
						(_cAliasSE2)->E2_LOJA,;
                		(_cAliasSE2)->E2_NATUREZ,;
                		(_cAliasSE2)->ED_DESCRIC,;
                		(_cAliasSE2)->E2_TIPO})
	Else
		aDadosExp[_nPosicao,2]+= _nSaldoTit
	EndIf
EndIf

Return
