/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Guilherme D.  |10/12/2012| Ajustada as queries para que o arredondamento dos valores calculados das parcelas nao 
              |          | interferissem no resultado do relatorio. 
Julio Paz     |09/10/2017| Chamado 21846. Realização de ajustes a alinhamentos na tela de parâmetros iniciais do relório de 
              |          | Prestação de Contas.
Lucas Borges  |11/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RFIN009
Autor-------------: Fabiano Dias 
Data da Criacao---: 23/08/2010                                     .
Descrição---------: Relatorio financeiro que demonstra as vendas: a vista, a prazo, as NCC, as notas fiscais canceladas, as 
                    saidas que não geraram financeiro e as devolucoes(Prestacao de contas Manaus).	
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RFIN009()
Local oGet1
Local oObs 
Local oSay1
Local oSay2
       
Local aButtons := {}  
Local nOpca    := 0  
Local _nLin := 10
                       
Private oDlg                       
Private dDtBase:= Date()
Private cObs   := ""

  DEFINE MSDIALOG oDlg TITLE "RELATÓRIO DE PRESTAÇÃO DE CONTAS" FROM 000, 000  TO 250, 500 COLORS 0, 16777215 PIXEL

    @ 030+_nLin, 008 Say oSay1 PROMPT "Data Base:" SIZE 030, 008 OF oDlg COLORS 0, 16777215 PIXEL
    @ 025+_nLin, 040 MSGET oGet1 VAR dDtBase SIZE 077, 010 OF oDlg COLORS 0, 16777215 PIXEL
    @ 042+_nLin, 008 Say oSay2 PROMPT "Observação:" SIZE 038, 007 OF oDlg COLORS 0, 16777215 PIXEL
    @ 050+_nLin, 039 GET oObs VAR cObs OF oDlg MULTILINE SIZE 197, 058 COLORS 0, 16777215 HSCROLL PIXEL
     
  ACTIVATE MSDIALOG oDlg CENTERED ON INIT EnchoiceBar(oDlg,{|| If(obrigator(),geraRel(),.F.),nOpca := 1},{||oDlg:End()},,aButtons)

Return     

/*
===============================================================================================================================
Programa----------: obrigator
Autor-------------: Fabiano Dias 
Data da Criacao---: 05/08/2010                                     .
Descrição---------: Validação
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function obrigator()  

Local lRet:= .T.

	If DToC(dDtBase) == '  /  /  '
	
			xMagHelpFis("Campo Obrigatório","Favor informar a Data-Base para geração dos dados do Relatório.",;
					    "É necessário para que seja executado este relatório que se forneça a Data-Base.")  
							       
	    	lRet:= .F.
	EndIf

Return lRet                        

/*
===============================================================================================================================
Programa----------: geraRel
Autor-------------: Fabiano Dias 
Data da Criacao---: 05/08/2010                                     .
Descrição---------: Gera relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function geraRel()
           
Private oFont08
Private oFont09     
Private oFont09b
Private oFont10
Private oFont10b
Private oFont12
Private oFont12b  
Private oFont16b           
Private oFont14
Private oFont14b

Private oPrint

Private nPagina     := 1

Private nLinha      := 0100
Private nColInic    := 0030
Private nColFinal   := 2360 
Private nqbrPagina  := 3300 
Private nLinInBox   
Private nSaltoLinha := 50               
Private nAjuAltLi1  := 10 //ajusta a altura de impressao dos dados do relatorio

Private oBrush      := TBrush():New( ,CLR_LIGHTGRAY)   
   
Private horaImp     := Time()

Define Font oFont08    Name "Courier New"       Size 0,-06       // Tamanho 14 
Define Font oFont09    Name "Courier New"       Size 0,-07       // Tamanho 14                                                                              
Define Font oFont09b   Name "Courier New"       Size 0,-07 Bold  // Tamanho 14                                                                              
Define Font oFont10    Name "Courier New"       Size 0,-08       // Tamanho 14    
Define Font oFont10b   Name "Courier New"       Size 0,-08 Bold   // Tamanho 14 
Define Font oFont12    Name "Courier New"       Size 0,-10       // Tamanho 12
Define Font oFont12b   Name "Courier New"       Size 0,-10 Bold  // Tamanho 12 Negrito  
Define Font oFont14    Name "Courier New"       Size 0,-10       // Tamanho 14
Define Font oFont14b   Name "Courier New"       Size 0,-10 Bold  // Tamanho 14         

oPrint:= TMSPrinter():New("PRESTACAO DE CONTAS") 
oPrint:SetPortrait() 	// Retrato  oPrint:SetLandscape() - Paisagem
oPrint:SetPaperSize(9)	// Seta para papel A4
	                 		
/// startando a impressora
oPrint:Say(0,0," ",oFont12,100)        

oPrint:StartPage()
           		 	     		
Processa({|| DadosRelat() })  
	
oPrint:EndPage()	// Finaliza a Pagina.
oPrint:Preview()	// Visualiza antes de Imprimir.

Return        

/*
===============================================================================================================================
Programa----------: Cabecalho
Autor-------------: Fabiano Dias 
Data da Criacao---: 05/08/2010                                     .
Descrição---------: Imprime cabeçalho
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function Cabecalho(impNrPag)    

Local cRaizServer := If(issrvunix(), "/", "\")    
Local cTitulo     := "PRESTAÇÃO DE CONTAS DATA-BASE " + DToC(dDtBase)

nLinha      := 0100
 
	oPrint:SayBitmap(nLinha,nColInic,cRaizServer + "system/lgrl01.bmp",250,100)      
	  
	If impNrPag <> 0
		oPrint:Say (nlinha,nColFinal - 550,"PÁGINA: " + AllTrim(Str(nPagina)),oFont12b)
		Else
			oPrint:Say (nlinha,nColFinal - 550,"SIGA/RFIN009",oFont12b)
	EndIf
	oPrint:Say (nlinha + 50 ,nColFinal - 550,"DATA DE EMISSÃO: " + DToC(DATE()),oFont12b)   
	oPrint:Say (nlinha + 100,nColFinal - 550,"HORA: " + horaImp                ,oFont12b)
	oPrint:Say (nlinha + 100,nColInic + 10,AllTrim(SM0->M0_NOME) + '/' + AllTrim(SM0->M0_FILIAL) + '-' + AllTrim(SM0->M0_ESTCOB)        ,oFont12b)  
	nlinha+=(nSaltoLinha * 3)           
	                                                   
	oPrint:Say (nlinha,nColFinal / 2,cTitulo,oFont16b,nColFinal,,,2)
	
	nlinha+=nSaltoLinha 
	nlinha+=nSaltoLinha        
	
	oPrint:Line(nLinha,nColInic,nLinha,nColFinal) 

Return              

/*
===============================================================================================================================
Programa----------: cabecDados
Autor-------------: Fabiano Dias 
Data da Criacao---: 05/08/2010                                     .
Descrição---------: Imprime cabeçalho
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function cabecDados(impCol,cDescCol,cTipCabec)

nLinInBox:= nlinha        

oPrint:FillRect({(nlinha+3),nColInic  ,nlinha + nSaltoLinha,nColFinal},oBrush)//Box Faturamento 

oPrint:Say (nlinha + nAjuAltLi1,nColInic + 10	    ,"Emissão"       ,oFont12b) 

If cTipCabec == 1  

oPrint:Say (nlinha + nAjuAltLi1,nColInic + 183	    ,"Vencimento"    ,oFont12b)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 426	    ,"Titulo/Parcela",oFont12b)
	Else
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 183	    ,"NF Entrada"    ,oFont12b)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 426	    ,"NF Referente"  ,oFont12b)	 

EndIf

oPrint:Say (nlinha + nAjuAltLi1,nColInic + 800	    ,"Cliente"       ,oFont12b)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 1042    ,"Razão Social"  ,oFont12b)     

If impCol == 1 
	oPrint:Say (nlinha + nAjuAltLi1,nColInic + 1950    ,"Valor"     ,oFont12b)
	oPrint:Say (nlinha + nAjuAltLi1,nColInic + 2075	    ,cDescCol    ,oFont12b)   
		Else
			 oPrint:Say (nlinha + nAjuAltLi1,nColInic + 2200        ,"Valor" ,oFont12b)
EndIf               

Return  

/*
===============================================================================================================================
Programa----------: cabecDad02
Autor-------------: Fabiano Dias 
Data da Criacao---: 05/08/2010                                     .
Descrição---------: Imprime cabeçalho
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function cabecDad02()

nLinInBox:= nlinha        

oPrint:FillRect({(nlinha+3),nColInic  ,nlinha + nSaltoLinha,nColFinal},oBrush)//Box Faturamento 

oPrint:Say (nlinha + nAjuAltLi1,nColInic + 10	    ,"Emissão"       ,oFont12b) 
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 183	    ,"NF"            ,oFont12b)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 426	    ,"Cliente"       ,oFont12b)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 800	    ,"Razão Social"  ,oFont12b)    
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 2200    ,"Valor"         ,oFont12b)              

Return    

/*
===============================================================================================================================
Programa----------: cabecDad03
Autor-------------: Fabiano Dias 
Data da Criacao---: 05/08/2010                                     .
Descrição---------: Imprime cabeçalho
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function cabDad03()

nLinInBox:= nlinha        

oPrint:FillRect({(nlinha+3),nColInic  ,nlinha + nSaltoLinha,nColInic + 710},oBrush)//Box Faturamento 

oPrint:Say (nlinha + nAjuAltLi1,nColInic + 10	    ,"Nota Fiscal"   ,oFont12b) 
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 360	    ,"Tipo"          ,oFont12b)         

Return    

/*
===============================================================================================================================
Programa----------: printDados
Autor-------------: Fabiano Dias 
Data da Criacao---: 05/08/2010                                     .
Descrição---------: Imprime dados
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function printDados(cEmissao,cVencto,cTitulo,cTitParcel,cCodCli,cLojaCli,cRazaoSoc,nValor,impCol,cDescCol,cTipCabec,cNfEntrada,cNfRefer)

oPrint:Say (nlinha + nAjuAltLi1,nColInic + 10	    ,IIf(Len(AllTrim(cEmissao)) > 0,DToC(SToD(cEmissao)) ,"")     ,oFont10)     

If cTipCabec == 1       

oPrint:Say (nlinha + nAjuAltLi1,nColInic + 183	    ,IIf(Len(AllTrim(cEmissao)) > 0,DToC(SToD(cVencto)) ,"")      ,oFont10)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 426	    ,IIf(Len(AllTrim(cTitulo)) > 0,cTitulo + "/" + cTitParcel,"") ,oFont10)   
	Else
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 183	    ,cNfEntrada             				 			            ,oFont10)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 426	    ,cNfRefer               				 			            ,oFont10)   

EndIf               

oPrint:Say (nlinha + nAjuAltLi1,nColInic + 800	    ,IIf(Len(AllTrim(cCodCli)) > 0,cCodCli + "-" + cLojaCli,"")   ,oFont10)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 1042	    ,SubStr(cRazaoSoc,1,40)    				 			            ,oFont10)    

If impCol == 1                                                                                           
	oPrint:Say (nlinha + nAjuAltLi1,nColInic + 1780	    ,IIf(nValor > 0,Transform(nValor,"@E 9,999,999,999.99"),""),oFont10)   
	If Len(AllTrim(cDescCol)) > 14
		oPrint:Say (nlinha + nAjuAltLi1,nColInic + 2075	,cDescCol    							                    ,oFont08) 
			Else
				oPrint:Say (nlinha + nAjuAltLi1,nColInic + 2075	,cDescCol    							            ,oFont10)    
	EndIf
		Else
			oPrint:Say (nlinha + nAjuAltLi1,nColInic + 2015	    ,IIf(nValor > 0,Transform(nValor,"@E 9,999,999,999.99"),""),oFont10)  
EndIf

Return       

/*
===============================================================================================================================
Programa----------: printDad02
Autor-------------: Fabiano Dias 
Data da Criacao---: 05/08/2010                                     .
Descrição---------: Imprime dados
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function printDad02(cEmissao,cNotaFisc,cSerieNF,cCodCli,cLojaCli,cRazaoSoc,nValor)

oPrint:Say (nlinha + nAjuAltLi1,nColInic + 10	    ,DToC(SToD(cEmissao))      				 			,oFont10)         
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 183	    ,cNotaFisc +'-'+cSerieNF      				 		,oFont10)       
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 426	    ,cCodCli + "-" + cLojaCli  				 			,oFont10)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 800	    ,SubStr(cRazaoSoc,1,51)    				 			,oFont10)    
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 2015	    ,Transform(nValor,"@E 9,999,999,999.99")           ,oFont10)  

Return    

/*
===============================================================================================================================
Programa----------: printDad03
Autor-------------: Fabiano Dias 
Data da Criacao---: 05/08/2010                                     .
Descrição---------: Imprime dados
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function prtDad03(_cNotaFis,_cSerieNF,_cTipoNF)

If AllTrim(_cTipoNF) == 'E'                                                        

	_cTipoNF:='Entrada'  
	
		ElseIf AllTrim(_cTipoNF) == 'S'
		
			_cTipoNF:='Saida'           

EndIf

oPrint:Say (nlinha + nAjuAltLi1,nColInic + 10	    ,AllTrim(_cNotaFis) + '-' + AllTrim(_cSerieNF),oFont12b) 
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 360	    ,_cTipoNF                                      ,oFont12b)         

Return 

/*
===============================================================================================================================
Programa----------: printTotal
Autor-------------: Fabiano Dias 
Data da Criacao---: 05/08/2010                                     .
Descrição---------: Imprime dados
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function printTotal(impCol,cDescric,nTotal)  

oPrint:Say (nlinha + nAjuAltLi1,nColInic + 10	    ,cDescric       ,oFont12b)                       
                                                  
If impCol == 1                                                                                           
	oPrint:Say (nlinha + nAjuAltLi1,nColInic + 1780	    ,Transform(nTotal,"@E 9,999,999,999.99")        ,oFont10b)   							             
		Else
			oPrint:Say (nlinha + nAjuAltLi1,nColInic + 2015	    ,Transform(nTotal,"@E 9,999,999,999.99") ,oFont10b)  
EndIf

Return  

/*
===============================================================================================================================
Programa----------: printTot02
Autor-------------: Fabiano Dias 
Data da Criacao---: 05/08/2010                                     .
Descrição---------: Imprime dados
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function printTot02(cDescric,nTotal)  

oPrint:Say (nlinha + nAjuAltLi1,nColInic + 10	    ,cDescric       ,oFont12b)                                                                         
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 2015	    ,Transform(nTotal,"@E 9,999,999,999.99") ,oFont10b)  

Return

/*
===============================================================================================================================
Programa----------: boxDivisor
Autor-------------: Fabiano Dias 
Data da Criacao---: 05/08/2010                                     .
Descrição---------: Imprime dados
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function boxDivisor(impCol)
                                  
If impCol == 2    
	oPrint:Line(nLinInBox,nColInic + 178 ,nLinha,nColInic + 178 )                                                         
	Else
		oPrint:Line(nLinInBox,nColInic + 178 ,nLinha+nSaltoLinha,nColInic + 178 )  
EndIf
oPrint:Line(nLinInBox,nColInic + 421 ,nLinha+nSaltoLinha,nColInic + 421 )  
oPrint:Line(nLinInBox,nColInic + 795 ,nLinha+nSaltoLinha,nColInic + 795 )  
oPrint:Line(nLinInBox,nColInic + 1037,nLinha+nSaltoLinha,nColInic + 1037)  
oPrint:Line(nLinInBox,nColInic + 1797,nLinha+nSaltoLinha,nColInic + 1797)

If impCol == 1 .Or. impCol == 2 
oPrint:Line(nLinInBox,nColInic + 2070,nLinha+nSaltoLinha,nColInic + 2070)  
EndIf       

oPrint:Box(nLinInBox ,nColInic           ,nLinha+nSaltoLinha,nColFinal) //Box Totalizador Descontos

Return       

/*
===============================================================================================================================
Programa----------: boxDiv02
Autor-------------: Fabiano Dias 
Data da Criacao---: 05/08/2010                                     .
Descrição---------: Imprime dados
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function boxDiv02()
      
oPrint:Line(nLinInBox,nColInic + 178 ,nLinha+nSaltoLinha,nColInic + 178 )  
oPrint:Line(nLinInBox,nColInic + 421 ,nLinha+nSaltoLinha,nColInic + 421 )  
oPrint:Line(nLinInBox,nColInic + 795 ,nLinha+nSaltoLinha,nColInic + 795 )  
oPrint:Line(nLinInBox,nColInic + 1797,nLinha+nSaltoLinha,nColInic + 1797)

oPrint:Box(nLinInBox ,nColInic           ,nLinha+nSaltoLinha,nColFinal) //Box Totalizador Descontos

Return       

/*
===============================================================================================================================
Programa----------: boxDiv03
Autor-------------: Fabiano Dias 
Data da Criacao---: 05/08/2010                                     .
Descrição---------: Imprime dados
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function boxDiv03()
      
oPrint:Line(nLinInBox,nColInic + 355 ,nLinha+nSaltoLinha,nColInic + 355 )  

oPrint:Box(nLinInBox ,nColInic,nLinha+nSaltoLinha,nColInic + 710) //Box Totalizador Descontos

Return    

/*
===============================================================================================================================
Programa----------: qbrPag
Autor-------------: Fabiano Dias 
Data da Criacao---: 05/08/2010                                     .
Descrição---------: Imprime dados
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function qbrPag(nLinhas,impBox,impCol,cDescCol,cTipCabec,nTipBoxDiv)   

	//Quebra de pagina
	If nLinha > nqbrPagina
				
		nlinha:= nlinha - (nSaltoLinha * nLinhas)
		
		If impBox == 1  
		        
		       //Para o tipo de relatorio resumido por dia de pagamento	
			   If nTipBoxDiv == 1	
		   	   		boxDivisor(impCol)
		   	   			Else 
		   	   				boxDiv02()
		   	   EndIf     
		   	   
		EndIf	 
		
		oPrint:EndPage()					// Finaliza a Pagina.
		oPrint:StartPage()					//Inicia uma nova Pagina					
		nPagina++		
		
		Cabecalho(1)
		nlinha+=nSaltoLinha                   
		nlinha+=nSaltoLinha  
		
		//Para o tipo de relatorio resumido por dia de pagamento	
		If nTipBoxDiv == 1	    		
			cabecDados(impCol,cDescCol,cTipCabec) 
				Else
					cabecDad02()      
		EndIf	

		nlinha+=nSaltoLinha   
		oPrint:Line(nLinha,nColInic,nLinha,nColFinal) 
		nlinha+=nSaltoLinha                           
		oPrint:Line(nLinha,nColInic,nLinha,nColFinal) 
		
	EndIf  
	
Return	

/*
===============================================================================================================================
Programa----------: quebraPag
Autor-------------: Fabiano Dias 
Data da Criacao---: 05/08/2010                                     .
Descrição---------: Imprime dados
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function quebraPag(nLinhaAtu)   

	//Quebra de pagina
	If nLinhaAtu > nqbrPagina				
		
		oPrint:EndPage()					// Finaliza a Pagina.
		oPrint:StartPage()					//Inicia uma nova Pagina					
		nPagina++		
		
		Cabecalho(1)
		nlinha+=nSaltoLinha                   
		nlinha+=nSaltoLinha  		
		
	EndIf  
	
Return	

/*
===============================================================================================================================
Programa----------: qbraPagin
Autor-------------: Fabiano Dias 
Data da Criacao---: 05/08/2010                                     .
Descrição---------: Imprime dados
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function qbraPagin(nLinhas,impBox)   

	//Quebra de pagina
	If nLinha > nqbrPagina
				
		nlinha:= nlinha - (nSaltoLinha * nLinhas)
		
		If impBox == 1  
			boxDiv03()		   	   
		EndIf	 
		
		oPrint:EndPage()					// Finaliza a Pagina.
		oPrint:StartPage()					//Inicia uma nova Pagina					
		nPagina++		
		
		Cabecalho(1)
		nlinha+=nSaltoLinha                   
		nlinha+=nSaltoLinha  
		
		//Para o tipo de relatorio resumido por dia de pagamento	
		cabDad03()

		nlinha+=nSaltoLinha   
		oPrint:Line(nLinha,nColInic,nLinha,nColInic + 710)  
		nlinha+=nSaltoLinha                           
		oPrint:Line(nLinha,nColInic,nLinha,nColInic + 710)  
		
	EndIf  
	
Return	

/*
===============================================================================================================================
Programa----------: Assinatura
Autor-------------: Fabiano Dias 
Data da Criacao---: 05/08/2010                                     .
Descrição---------: Pesquisa os dados do usuario corrente para imprimir a assinatura.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function DadosRelat()         

Local _cQuery   := ""
Local _cAliasVis:= GetNextAlias() // Alias Vencimento a Vista  
Local _cAliasPrz:= GetNextAlias() // Alias Vencimento a Prazo que gerou numero de boleto   
Local _cAliasBol:= GetNextAlias() // Alias Vencimento a Prazo que nao gerou numero de boleto
Local _cAliasSai:= GetNextAlias() // Alias das Saidas que nao geraram financeiro
Local _cAliasNCC:= GetNextAlias() // Alias que contem as NCC geradas a vista
Local _cAliasDv1:= GetNextAlias() // Alias que contem as notas de devolucao que possuam formulario proprio igual a sim
Local _cAliasDv2:= GetNextAlias() // Alias que contem as notas de devolucao que possuam formulario proprio diferente de sim      
Local _cAliasCan:= GetNextAlias() // Alias notas fiscais canceladas
Local x			:= 0
Local nCountRec := 0			   //Armazena o numero de registros de uma query	
Local lPriCabec := .F.             //Gerou primeiro cabecalho     
Local _nTotaliz := 0  			   //Armazena o total de cada secao a vista a prazo...

Local _aNccs    := {}     

Local _aTxtDet  := {}   

Local lCabecNcc := .F.

//Totalizadores             
Local _nTotVend := 0
                       
	//Query para buscar dados do vencimento a vista	
	_cQuery := "SELECT"  
	_cQuery += " E1.E1_EMISSAO,E1.E1_VENCTO,E1.E1_NUM,E1.E1_PARCELA,E1.E1_CLIENTE,E1.E1_LOJA,A1.A1_NOME,(E1.E1_VALOR  -"          
	//_cQuery += " (SELECT COALESCE(SUM(D1.D1_TOTAL),0) FROM SD1010 D1 WHERE D1.D_E_L_E_T_ = ' ' AND D1_FILIAL = E1_FILIAL AND D1_TIPO = 'D'" 
	_cQuery += " (SELECT COALESCE(SUM(D1.D1_TOTAL+D1.D1_ICMSRET),0) FROM SD1010 D1 WHERE D1.D_E_L_E_T_ = ' ' AND D1_FILIAL = E1_FILIAL AND D1_TIPO = 'D'"  //HEDER - 05/10/12 - HELP 1482 - Consideracao valor ST
	_cQuery += " AND D1_NFORI = E1_NUM AND D1_SERIORI = E1_PREFIXO AND D1_FORNECE = E1_CLIENTE AND D1_LOJA = E1_LOJA)) E1_VALOR " 
	_cQuery += "FROM " + RetSqlName("SE1") + " E1 "  
	_cQuery += "JOIN " + RetSqlName("SA1") + " A1 ON E1.E1_CLIENTE = A1.A1_COD AND E1.E1_LOJA = A1.A1_LOJA "
	_cQuery += "WHERE"  
	_cQuery += " E1.D_E_L_E_T_ = ' '"
	_cQuery += " AND A1.D_E_L_E_T_ = ' '"
	_cQuery += " AND E1.E1_FILIAL = '" + xFilial("SE1") + "'"   
	_cQuery += " AND E1.E1_TIPO = 'NF '"
	_cQuery += " AND E1.E1_ORIGEM = 'MATA460'"  
	_cQuery += " AND E1.E1_EMISSAO = '" + DToS(dDtBase) + "'" 
	_cQuery += " AND E1.E1_EMISSAO = E1.E1_VENCTO " 
	_cQuery += " AND E1.E1_VALOR >" 
	//_cQuery += " (SELECT COALESCE(SUM(D1.D1_TOTAL),0) FROM SD1010 D1 WHERE D1.D_E_L_E_T_ = ' ' AND D1_FILIAL = E1_FILIAL AND D1_TIPO = 'D'"         
	_cQuery += " (SELECT COALESCE(SUM(D1.D1_TOTAL+D1.D1_ICMSRET),0) FROM SD1010 D1 WHERE D1.D_E_L_E_T_ = ' ' AND D1_FILIAL = E1_FILIAL AND D1_TIPO = 'D'"  //HEDER - 05/10/12 - HELP 1482 - Consideracao valor ST
	_cQuery += " AND D1_NFORI = E1_NUM AND D1_SERIORI = E1_PREFIXO AND D1_FORNECE = E1_CLIENTE AND D1_LOJA = E1_LOJA) " 
	_cQuery += "ORDER BY"
	_cQuery += " E1.E1_NUM,E1.E1_PARCELA"       

	If Select(_cAliasVis) > 0
		(_cAliasVis)->(DBCloseArea())
	EndIf                                                     
	
	dbUseArea( .T., "TOPCONN",TcGenQry(,,_cQuery),_cAliasVis,.T.,.T.)
	COUNT TO nCountRec //Contabiliza o numero de registros encontrados pela query
	
	ProcRegua(nCountRec) 
	 
	DBSelectArea(_cAliasVis)
	(_cAliasVis)->(DBGoTop())    
	
	//Verifica a existencia de pelo menos um registro para criar o cabecalho da pagina e de dados
	If nCountRec > 0 
	         
		lPriCabec:= .T.
	
		Cabecalho(1)	 
		nlinha+=nSaltoLinha 
		nlinha+=nSaltoLinha    
		
		oPrint:Say (nlinha + nAjuAltLi1,nColInic + 10,"A seguir, informações detalhadas do faturamento da data acima referenciada. Emitir cobrança a todas as",oFont12) 
		nlinha+=nSaltoLinha
		oPrint:Say (nlinha + nAjuAltLi1,nColInic + 10,"duplicatas abaixo relacionadas na situação de venda A PRAZO. As vendas A VISTA CARTEIRA são clientes",oFont12) 
		nlinha+=nSaltoLinha 
		oPrint:Say (nlinha + nAjuAltLi1,nColInic + 10,"com depósito em conta corrente em São Paulo na data do vencimento.",oFont12) 
		
		nlinha+=nSaltoLinha 
		nlinha+=nSaltoLinha  		
		quebraPag(nlinha)
		
		oPrint:Say (nlinha + nAjuAltLi1,nColInic + 10,"Vendas à vista: Dep. em conta corrente no dia do vencimento:",oFont12b) 
		
		nlinha+=nSaltoLinha 
		nlinha+=nSaltoLinha 
		
		cabecDados(0,"",1)
		nlinha+=nSaltoLinha                           
		oPrint:Line(nLinha,nColInic,nLinha,nColFinal)
	                   
		//Imprime dados	
		While (_cAliasVis)->(!Eof())          
		
			_nTotaliz+= (_cAliasVis)->E1_VALOR     
			//Totalizador Geral de Vendas                              
			_nTotVend+= (_cAliasVis)->E1_VALOR
			
		
			IncProc("Processamento a visto do título: " + AllTrim((_cAliasVis)->E1_NUM) + "/" + AllTrim((_cAliasVis)->E1_PARCELA) )
		
			nlinha+=nSaltoLinha
			oPrint:Line(nLinha,nColInic,nLinha,nColFinal) 
			qbrPag(1,1,0,"",1,1) 	     
			
			printDados((_cAliasVis)->E1_EMISSAO,(_cAliasVis)->E1_VENCTO,(_cAliasVis)->E1_NUM,(_cAliasVis)->E1_PARCELA,;
			           (_cAliasVis)->E1_CLIENTE,(_cAliasVis)->E1_LOJA,(_cAliasVis)->A1_NOME,(_cAliasVis)->E1_VALOR,0,"",1,"","")
		     
		(_cAliasVis)->(DBSkip())
	    EndDo         
	    
	    nlinha+=nSaltoLinha   
	    oPrint:Line(nLinha,nColInic,nLinha,nColFinal)
	    nlinha+=nSaltoLinha                          
	    oPrint:Line(nLinha,nColInic,nLinha,nColFinal)
	    qbrPag(1,1,0,"",1,1)
	    printTotal(0,"TOTAL",_nTotaliz)          
	    
	    //Fecha o box da ultima pagina
	    boxDivisor(0)
    
    EndIf
    
    DBSelectArea(_cAliasVis)  
    (_cAliasVis)->(DBCloseArea())        
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    //Impressao dos dados do campo Memo
    
    /*          
	Q_MemoArray(mMemo, aTxtDet, nTamQuebra)
	mMemo = Variavel que contem o conteudo do campo memo
	aTxtDet = Array que gostaria que tivesse o conteudo do campo memo
	nTamQuebra = Posição para quebra da linha
    */             
	Q_MemoArray(cObs,_aTxtDet,104)	  
	
	If Len(_aTxtDet) > 0     
	    
		nlinha+=nSaltoLinha
		nlinha+=nSaltoLinha                     
		nlinha+=nSaltoLinha
		
		U_ImpMemo(_aTxtDet,oFont12b) //Funcao utilzada para imprimir campo Memo     
		
		nlinha+=nSaltoLinha
	
	EndIf
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////  
              
    //Seta variavel responsavel por realizar o totalizador 
    _nTotaliz:= 0
    
     //Query para buscar dados dos titulos com vencimento a prazo que gerou boleto
     
	_cQuery := "SELECT"  
	_cQuery += " E1.E1_EMISSAO,E1.E1_VENCTO,E1.E1_NUM,E1.E1_PARCELA,E1.E1_CLIENTE,E1.E1_LOJA,A1.A1_NOME,E1.E1_NUMBCO,(E1.E1_VALOR -" 
	_cQuery += " ((SELECT COALESCE(SUM(D1.D1_TOTAL+D1.D1_ICMSRET),0) FROM SD1010 D1 WHERE D1.D_E_L_E_T_ = ' ' AND D1_FILIAL = E1_FILIAL AND D1_TIPO = 'D' AND D1_NFORI = E1_NUM AND D1_SERIORI = E1_PREFIXO AND D1_FORNECE = E1_CLIENTE AND D1_LOJA = E1_LOJA ) " //HEDER - 05/10/12 - HELP 1482 - Consideracao valor ST
	_cQuery += " /(SELECT MAX(TO_NUMBER(REPLACE(E1_PARCELA,'  ','1'))) FROM SE1010 E1G WHERE E1G.D_E_L_E_T_ = ' ' AND E1G.E1_FILIAL  = E1.E1_FILIAL AND E1G.E1_NUM     = E1.E1_NUM        AND E1G.E1_EMISSAO = E1.E1_EMISSAO        AND E1G.E1_CLIENTE = E1.E1_CLIENTE        AND E1G.E1_LOJA    = E1.E1_LOJA GROUP BY E1G.E1_FILIAL, E1G.E1_NUM, E1G.E1_EMISSAO, E1G.E1_CLIENTE, E1G.E1_LOJA))) E1_VALOR " 
	_cQuery += "FROM " + RetSqlName("SE1") + " E1 "  
	_cQuery += "JOIN " + RetSqlName("SA1") + " A1 ON E1.E1_CLIENTE = A1.A1_COD AND E1.E1_LOJA = A1.A1_LOJA "
	_cQuery += "WHERE"  
	_cQuery += " E1.D_E_L_E_T_ = ' '"
	_cQuery += " AND A1.D_E_L_E_T_ = ' '"
	_cQuery += " AND E1.E1_FILIAL = '" + xFilial("SE1") + "'"   
	_cQuery += " AND E1.E1_TIPO = 'NF '"
	_cQuery += " AND E1.E1_ORIGEM = 'MATA460'"  
	_cQuery += " AND E1.E1_EMISSAO = '" + DToS(dDtBase) + "'" 
	_cQuery += " AND E1.E1_EMISSAO <> E1.E1_VENCTO"           
	_cQuery += " AND E1.E1_NUMBCO <> ' ' "
	_cQuery += " AND E1.E1_VALOR >"
	_cQuery += " (Case WHEN(E1.E1_VALOR - (SELECT COALESCE(SUM(D1.D1_TOTAL+D1.D1_ICMSRET),0) FROM " + RetSqlName("SD1") + " D1 WHERE D1.D_E_L_E_T_ = ' ' AND D1_FILIAL = E1_FILIAL AND D1_TIPO = 'D' AND D1_NFORI = E1_NUM AND D1_SERIORI = E1_PREFIXO AND D1_FORNECE = E1_CLIENTE AND D1_LOJA = E1_LOJA) " //GUILHERME - 07/12/2012
	_cQuery += " / (SELECT MAX(TO_NUMBER(REPLACE(E1_PARCELA,'  ','1'))) FROM " + RetSqlName("SE1") + " E1G WHERE E1G.D_E_L_E_T_ = ' ' AND E1G.E1_FILIAL  = E1.E1_FILIAL AND E1G.E1_NUM = E1.E1_NUM AND E1G.E1_EMISSAO = E1.E1_EMISSAO AND E1G.E1_CLIENTE = E1.E1_CLIENTE AND E1G.E1_LOJA = E1.E1_LOJA GROUP BY E1G.E1_FILIAL, E1G.E1_NUM, E1G.E1_EMISSAO, E1G.E1_CLIENTE, E1G.E1_LOJA)) <= 0.05 THEN E1.E1_VALOR Else 0 END) " 
	_cQuery += "ORDER BY"
	_cQuery += " E1.E1_NUM,E1.E1_PARCELA"       	

	If Select(_cAliasPrz) > 0
		(_cAliasPrz)->(DBCloseArea())
	EndIf                                                     
	
	dbUseArea( .T., "TOPCONN",TcGenQry(,,_cQuery),_cAliasPrz,.T.,.T.)
	COUNT TO nCountRec //Contabiliza o numero de registros encontrados pela query
	
	ProcRegua(nCountRec) 
	 
	DBSelectArea(_cAliasPrz)
	(_cAliasPrz)->(DBGoTop())    
	
	//Verifica a existencia de pelo menos um registro para criar o cabecalho da pagina e de dados
	If nCountRec > 0 	                     
	         
		If !lPriCabec
	                    
			Cabecalho(1)	 
			nlinha+=nSaltoLinha 
			nlinha+=nSaltoLinha  
		
		EndIf  	
		
	    lPriCabec:= .T.  			
		  
		nlinha+=nSaltoLinha 
		nlinha+=nSaltoLinha
		quebraPag(nlinha)
		
		oPrint:Say (nlinha + nAjuAltLi1,nColInic + 10,"Vendas a prazo que geraram boleto bancário:",oFont12b) 
		
		nlinha+=nSaltoLinha 
		nlinha+=nSaltoLinha 
		
		cabecDados(1,"Boleto",1)
		nlinha+=nSaltoLinha                           
		oPrint:Line(nLinha,nColInic,nLinha,nColFinal)
	                   
		//Imprime dados	
		While (_cAliasPrz)->(!Eof())       
		
			_nTotaliz+= (_cAliasPrz)->E1_VALOR    
			//Totalizador geral de Vendas
			_nTotVend+= (_cAliasPrz)->E1_VALOR 
		
			IncProc("Processamento a prazo do título: " + AllTrim((_cAliasPrz)->E1_NUM) + "/" + AllTrim((_cAliasPrz)->E1_PARCELA) )
		
			nlinha+=nSaltoLinha
			oPrint:Line(nLinha,nColInic,nLinha,nColFinal) 
			qbrPag(1,1,1,"Boleto",1,1) 	     
			
			printDados((_cAliasPrz)->E1_EMISSAO,(_cAliasPrz)->E1_VENCTO,(_cAliasPrz)->E1_NUM,(_cAliasPrz)->E1_PARCELA,;
			           (_cAliasPrz)->E1_CLIENTE,(_cAliasPrz)->E1_LOJA,(_cAliasPrz)->A1_NOME,(_cAliasPrz)->E1_VALOR,1,(_cAliasPrz)->E1_NUMBCO,1,"","")
		     
		(_cAliasPrz)->(DBSkip())
	    EndDo         
	    
	    nlinha+=nSaltoLinha   
	    oPrint:Line(nLinha,nColInic,nLinha,nColFinal)
	    nlinha+=nSaltoLinha                          
	    oPrint:Line(nLinha,nColInic,nLinha,nColFinal)   
	    qbrPag(1,1,1,"Boleto",1,1)
	    printTotal(1,"TOTAL",_nTotaliz)                 
	    
	    //Fecha o box da ultima pagina
	    boxDivisor(1)
		
	EndIf	 
	
	DBSelectArea(_cAliasPrz)    
	(_cAliasPrz)->(DBCloseArea())  
	
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////  
                
    //Seta variavel responsavel por realizar o totalizador 
    _nTotaliz:= 0
    
    //Query para buscar dados dos titulos com vencimento a prazo que nao gerou boleto	
	_cQuery := "SELECT"  
	_cQuery += " E1.E1_EMISSAO,E1.E1_VENCTO,E1.E1_NUM,E1.E1_PARCELA,E1.E1_CLIENTE,E1.E1_LOJA,A1.A1_NOME,E1.E1_NUMBCO,(E1.E1_VALOR -" 
	//_cQuery += " (SELECT COALESCE(SUM(D1.D1_TOTAL),0) FROM SD1010 D1 WHERE D1.D_E_L_E_T_ = ' ' AND D1_FILIAL = E1_FILIAL AND D1_TIPO = 'D'"         
	_cQuery += " (SELECT COALESCE(SUM(D1.D1_TOTAL+D1.D1_ICMSRET),0) FROM SD1010 D1 WHERE D1.D_E_L_E_T_ = ' ' AND D1_FILIAL = E1_FILIAL AND D1_TIPO = 'D'"  //HEDER - 05/10/12 - HELP 1482 - Consideracao valor ST
	_cQuery += " AND D1_NFORI = E1_NUM AND D1_SERIORI = E1_PREFIXO AND D1_FORNECE = E1_CLIENTE AND D1_LOJA = E1_LOJA)) E1_VALOR " 
	_cQuery += "FROM " + RetSqlName("SE1") + " E1 "  
	_cQuery += "JOIN " + RetSqlName("SA1") + " A1 ON E1.E1_CLIENTE = A1.A1_COD AND E1.E1_LOJA = A1.A1_LOJA "
	_cQuery += "WHERE"  
	_cQuery += " E1.D_E_L_E_T_ = ' '"
	_cQuery += " AND A1.D_E_L_E_T_ = ' '"
	_cQuery += " AND E1.E1_FILIAL = '" + xFilial("SE1") + "'"   
	_cQuery += " AND E1.E1_TIPO = 'NF '"
	_cQuery += " AND E1.E1_ORIGEM = 'MATA460'"  
	_cQuery += " AND E1.E1_EMISSAO = '" + DToS(dDtBase) + "'" 
	_cQuery += " AND E1.E1_EMISSAO <> E1.E1_VENCTO"           
	_cQuery += " AND E1.E1_NUMBCO = ' ' "
	_cQuery += " AND E1.E1_VALOR >"
	_cQuery += " (Case WHEN(E1.E1_VALOR - (SELECT COALESCE(SUM(D1.D1_TOTAL+D1.D1_ICMSRET),0) FROM " + RetSqlName("SD1") + " D1 WHERE D1.D_E_L_E_T_ = ' ' AND D1_FILIAL = E1_FILIAL AND D1_TIPO = 'D' AND D1_NFORI = E1_NUM AND D1_SERIORI = E1_PREFIXO AND D1_FORNECE = E1_CLIENTE AND D1_LOJA = E1_LOJA) " //GUILHERME - 07/12/2012
	_cQuery += " / (SELECT MAX(TO_NUMBER(REPLACE(E1_PARCELA,'  ','1'))) FROM " + RetSqlName("SE1") + " E1G WHERE E1G.D_E_L_E_T_ = ' ' AND E1G.E1_FILIAL  = E1.E1_FILIAL AND E1G.E1_NUM = E1.E1_NUM AND E1G.E1_EMISSAO = E1.E1_EMISSAO AND E1G.E1_CLIENTE = E1.E1_CLIENTE AND E1G.E1_LOJA = E1.E1_LOJA GROUP BY E1G.E1_FILIAL, E1G.E1_NUM, E1G.E1_EMISSAO, E1G.E1_CLIENTE, E1G.E1_LOJA)) <= 0.05 THEN E1.E1_VALOR Else 0 END) "
	//_cQuery += " (SELECT COALESCE(SUM(D1.D1_TOTAL),0) FROM SD1010 D1 WHERE D1.D_E_L_E_T_ = ' ' AND D1_FILIAL = E1_FILIAL AND D1_TIPO = 'D'"         
	//_cQuery += " (SELECT COALESCE(SUM(D1.D1_TOTAL+D1.D1_ICMSRET),0) FROM SD1010 D1 WHERE D1.D_E_L_E_T_ = ' ' AND D1_FILIAL = E1_FILIAL AND D1_TIPO = 'D'"  //HEDER - 05/10/12 - HELP 1482 - Consideracao valor ST
	//_cQuery += " AND D1_NFORI = E1_NUM AND D1_SERIORI = E1_PREFIXO AND D1_FORNECE = E1_CLIENTE AND D1_LOJA = E1_LOJA) " 
	_cQuery += "ORDER BY"
	_cQuery += " E1.E1_NUM,E1.E1_PARCELA"       

	If Select(_cAliasBol) > 0
		(_cAliasBol)->(DBCloseArea())
	EndIf                                                     
	
	dbUseArea( .T., "TOPCONN",TcGenQry(,,_cQuery),_cAliasBol,.T.,.T.)
	COUNT TO nCountRec //Contabiliza o numero de registros encontrados pela query
	
	ProcRegua(nCountRec) 
	 
	DBSelectArea(_cAliasBol)
	(_cAliasBol)->(DBGoTop())    
	
	//Verifica a existencia de pelo menos um registro para criar o cabecalho da pagina e de dados
	If nCountRec > 0   
		         
		If !lPriCabec
	
			Cabecalho(1)	 
			nlinha+=nSaltoLinha 
			nlinha+=nSaltoLinha  
		
		EndIf  	 
		
		lPriCabec:= .T.			
		  
		nlinha+=nSaltoLinha 
		nlinha+=nSaltoLinha
		quebraPag(nlinha)
		
		oPrint:Say (nlinha + nAjuAltLi1,nColInic + 10,"Vendas a prazo que nao gerou boleto bancário:",oFont12b) 
		
		nlinha+=nSaltoLinha 
		nlinha+=nSaltoLinha 
		
		cabecDados(0,"",1)
		nlinha+=nSaltoLinha                           
		oPrint:Line(nLinha,nColInic,nLinha,nColFinal)
	                   
		//Imprime dados	
		While (_cAliasBol)->(!Eof())       
		
			_nTotaliz+= (_cAliasBol)->E1_VALOR  
			//Totalizador Geral de Vendas
			_nTotVend+= (_cAliasBol)->E1_VALOR  
		
			IncProc("Processamento a prazo do título: " + AllTrim((_cAliasBol)->E1_NUM) + "/" + AllTrim((_cAliasBol)->E1_PARCELA) )
		
			nlinha+=nSaltoLinha
			oPrint:Line(nLinha,nColInic,nLinha,nColFinal) 
			qbrPag(1,1,0,"",1,1) 	     
			
			printDados((_cAliasBol)->E1_EMISSAO,(_cAliasBol)->E1_VENCTO,(_cAliasBol)->E1_NUM ,(_cAliasBol)->E1_PARCELA,;
			           (_cAliasBol)->E1_CLIENTE,(_cAliasBol)->E1_LOJA  ,(_cAliasBol)->A1_NOME,(_cAliasBol)->E1_VALOR,0,"",1,"","")
		     
		(_cAliasBol)->(DBSkip())
	    EndDo         
	    
	    nlinha+=nSaltoLinha   
	    oPrint:Line(nLinha,nColInic,nLinha,nColFinal)
	    nlinha+=nSaltoLinha                          
	    oPrint:Line(nLinha,nColInic,nLinha,nColFinal)   
	    qbrPag(1,1,0,"",1,1)
	    printTotal(0,"TOTAL",_nTotaliz)                 
	    
	    //Fecha o box da ultima pagina
	    boxDivisor(0)
		
	EndIf	 
	
	DBSelectArea(_cAliasBol)    
	(_cAliasBol)->(DBCloseArea())	       
	
		/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////  
		             
		//Imprime totalizador geral de vendas  
		
		If _nTotVend > 0    
		
			nlinha+=nSaltoLinha 
			nlinha+=nSaltoLinha
			quebraPag(nlinha)
			
			printTotal(0,'TOTAL GERAL DAS VENDAS -->',_nTotVend)  
			
			nlinha+=nSaltoLinha       
		
		EndIf
				
		/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////  	
                
    //Seta variavel responsavel por realizar o totalizador 
    _nTotaliz:= 0
    
    //Query para buscar dados das saidas que nao geraram financeiro	
	_cQuery := "SELECT"  
	_cQuery += " D2.D2_EMISSAO,D2.D2_DOC,D2.D2_SERIE,A1.A1_COD,A1.A1_LOJA,A1.A1_NOME,F4.F4_CODIGO,F4.F4_TEXTO,SUM(D2.D2_VALBRUT) VLRNOTA " 
	_cQuery += "FROM " + RetSqlName("SD2") + " D2 "  
	_cQuery += "JOIN " + RetSqlName("SF4") + " F4 ON F4.F4_FILIAL = D2.D2_FILIAL AND F4.F4_CODIGO = D2.D2_TES "
	_cQuery += "JOIN " + RetSqlName("SA1") + " A1 ON A1.A1_COD = D2.D2_CLIENTE AND A1.A1_LOJA = D2.D2_LOJA "
	_cQuery += "WHERE"  
	_cQuery += " D2.D_E_L_E_T_ = ' '"
	_cQuery += " AND F4.D_E_L_E_T_ = ' '"	
	_cQuery += " AND A1.D_E_L_E_T_ = ' '"
	_cQuery += " AND D2.D2_FILIAL = '" + xFilial("SD2") + "'"   
	_cQuery += " AND F4.F4_FILIAL = '" + xFilial("SF4") + "'" 	
	_cQuery += " AND D2.D2_TIPO NOT IN ('D','B')" 
	_cQuery += " AND F4.F4_DUPLIC = 'N' "   
	_cQuery += " AND D2.D2_EMISSAO = '" + DToS(dDtBase) + "' " 
	_cQuery += "GROUP BY"         
	_cQuery += " D2.D2_EMISSAO, D2.D2_DOC, D2.D2_SERIE, A1.A1_COD, A1.A1_LOJA, A1.A1_NOME,F4.F4_CODIGO,F4.F4_TEXTO "       
	_cQuery += "UNION ALL " 	
	_cQuery += "SELECT"  
	_cQuery += " D2.D2_EMISSAO,D2.D2_DOC,D2.D2_SERIE,A2.A2_COD A1_COD,A2.A2_LOJA A1_LOJA,A2.A2_NOME A1_NOME,F4.F4_CODIGO,F4.F4_TEXTO,SUM(D2.D2_VALBRUT) VLRNOTA " 
	_cQuery += "FROM " + RetSqlName("SD2") + " D2 "  
	_cQuery += "JOIN " + RetSqlName("SF4") + " F4 ON F4.F4_FILIAL = D2.D2_FILIAL AND F4.F4_CODIGO = D2.D2_TES "
	_cQuery += "JOIN " + RetSqlName("SA2") + " A2 ON A2.A2_COD = D2.D2_CLIENTE AND A2.A2_LOJA = D2.D2_LOJA "
	_cQuery += "WHERE"  
	_cQuery += " D2.D_E_L_E_T_ = ' '"
	_cQuery += " AND F4.D_E_L_E_T_ = ' '"	
	_cQuery += " AND A2.D_E_L_E_T_ = ' '"
	_cQuery += " AND D2.D2_FILIAL = '" + xFilial("SD2") + "'"   
	_cQuery += " AND F4.F4_FILIAL = '" + xFilial("SF4") + "'" 	
	_cQuery += " AND D2.D2_TIPO IN ('D','B')" 
	_cQuery += " AND D2.D2_EMISSAO = '" + DToS(dDtBase) + "' " 
	_cQuery += "GROUP BY"         
	_cQuery += " D2.D2_EMISSAO, D2.D2_DOC, D2.D2_SERIE, A2.A2_COD, A2.A2_LOJA, A2.A2_NOME,F4.F4_CODIGO,F4.F4_TEXTO " 
	_cQuery += "ORDER BY"
	_cQuery += " 2,3"       
	
	If Select(_cAliasSai) > 0
		(_cAliasSai)->(DBCloseArea())
	EndIf                                                     
	
	dbUseArea( .T., "TOPCONN",TcGenQry(,,_cQuery),_cAliasSai,.T.,.T.)
	COUNT TO nCountRec //Contabiliza o numero de registros encontrados pela query
	
	ProcRegua(nCountRec) 
	 
	DBSelectArea(_cAliasSai)
	(_cAliasSai)->(DBGoTop())    
	
	//Verifica a existencia de pelo menos um registro para criar o cabecalho da pagina e de dados
	If nCountRec > 0   
		         
		If !lPriCabec
	
			Cabecalho(1)	 
			nlinha+=nSaltoLinha 
			nlinha+=nSaltoLinha  
		
		EndIf  	 
		
		lPriCabec:= .T.			
		  
		nlinha+=nSaltoLinha 
		nlinha+=nSaltoLinha
		quebraPag(nlinha)
		
		oPrint:Say (nlinha + nAjuAltLi1,nColInic + 10,"Saídas sem receita financeira baixa perdas/bonificação:",oFont12b) 
		
		nlinha+=nSaltoLinha 
		nlinha+=nSaltoLinha 
		
		cabecDad02()
		nlinha+=nSaltoLinha                           
		oPrint:Line(nLinha,nColInic,nLinha,nColFinal)
	                   
		//Imprime dados	
		While (_cAliasSai)->(!Eof())       
		
			_nTotaliz+= (_cAliasSai)->VLRNOTA    
		
			IncProc("Processando a nota de saida: " + AllTrim((_cAliasSai)->D2_DOC) + "/" + AllTrim((_cAliasSai)->D2_SERIE) )
		
			nlinha+=nSaltoLinha
			oPrint:Line(nLinha,nColInic,nLinha,nColFinal) 
			qbrPag(1,1,0,"",2,2) 	     
			
			printDad02((_cAliasSai)->D2_EMISSAO,(_cAliasSai)->D2_DOC,(_cAliasSai)->D2_SERIE,;
			           (_cAliasSai)->A1_COD,(_cAliasSai)->A1_LOJA,AllTrim(SubStr((_cAliasSai)->A1_NOME,1,30)) +'('+ AllTrim(SubStr((_cAliasSai)->F4_TEXTO,1,20))+')',(_cAliasSai)->VLRNOTA)
		     
		(_cAliasSai)->(DBSkip())
	    EndDo         
	    
	    nlinha+=nSaltoLinha   
	    oPrint:Line(nLinha,nColInic,nLinha,nColFinal)
	    nlinha+=nSaltoLinha                          
	    oPrint:Line(nLinha,nColInic,nLinha,nColFinal)   
	    qbrPag(1,1,0,"",2,2)
	    printTot02("TOTAL",_nTotaliz)                 
	    
	    //Fecha o box da ultima pagina
	    boxDiv02()
		
	EndIf	 
	
	DBSelectArea(_cAliasSai)    
	(_cAliasSai)->(DBCloseArea())	
      
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////  
              
    //Seta variavel responsavel por realizar o totalizador 
    _nTotaliz:= 0
    
     //Query para buscar dados dos titulos de NCC com vencimento a vista  	
	_cQuery := "SELECT"  
	_cQuery += " E1.E1_FILIAL,E1.E1_EMISSAO,E1.E1_VENCTO,E1.E1_NUM,E1.E1_PREFIXO,E1.E1_PARCELA,E1.E1_CLIENTE,E1.E1_LOJA,A1.A1_NOME,E1.E1_NUMBCO," 
	//_cQuery += " (SELECT COALESCE(SUM(D1.D1_TOTAL),0) FROM SD1010 D1 WHERE D1.D_E_L_E_T_ = ' ' AND D1_FILIAL = E1_FILIAL AND D1_TIPO = 'D'"         
	_cQuery += " (SELECT COALESCE(SUM(D1.D1_TOTAL+D1.D1_ICMSRET),0) FROM SD1010 D1 WHERE D1.D_E_L_E_T_ = ' ' AND D1_FILIAL = E1_FILIAL AND D1_TIPO = 'D'" //HEDER - 05/10/12 - HELP 1482 - Consideracao valor ST
	_cQuery += " AND D1_NFORI = E1_NUM AND D1_SERIORI = E1_PREFIXO AND D1_FORNECE = E1_CLIENTE AND D1_LOJA = E1_LOJA) E1_VALOR " 
	_cQuery += "FROM " + RetSqlName("SE1") + " E1 "  
	_cQuery += "JOIN " + RetSqlName("SA1") + " A1 ON E1.E1_CLIENTE = A1.A1_COD AND E1.E1_LOJA = A1.A1_LOJA "
	_cQuery += "WHERE"  
	_cQuery += " E1.D_E_L_E_T_ = ' '"
	_cQuery += " AND A1.D_E_L_E_T_ = ' '"
	_cQuery += " AND E1.E1_FILIAL = '" + xFilial("SE1") + "'"   
	_cQuery += " AND E1.E1_TIPO = 'NF '"
	_cQuery += " AND E1.E1_ORIGEM = 'MATA460'"  
	_cQuery += " AND E1.E1_EMISSAO = '" + DToS(dDtBase) + "'" 
	_cQuery += " AND E1.E1_EMISSAO = E1.E1_VENCTO"           
	_cQuery += " AND " 
	//_cQuery += " (SELECT COALESCE(SUM(D1.D1_TOTAL),0) FROM SD1010 D1 WHERE D1.D_E_L_E_T_ = ' ' AND D1_FILIAL = E1_FILIAL AND D1_TIPO = 'D'"         
	_cQuery += " (SELECT COALESCE(SUM(D1.D1_TOTAL+D1.D1_ICMSRET),0) FROM SD1010 D1 WHERE D1.D_E_L_E_T_ = ' ' AND D1_FILIAL = E1_FILIAL AND D1_TIPO = 'D'"  //HEDER - 05/10/12 - HELP 1482 - Consideracao valor ST
	_cQuery += " AND D1_NFORI = E1_NUM AND D1_SERIORI = E1_PREFIXO AND D1_FORNECE = E1_CLIENTE AND D1_LOJA = E1_LOJA) > 0 " 
	_cQuery += "ORDER BY"
	_cQuery += " E1.E1_VENCTO,E1.E1_NUM,E1.E1_PARCELA"                     
    
	If Select(_cAliasNCC) > 0
		(_cAliasNCC)->(DBCloseArea())
	EndIf                                                     
	
	dbUseArea( .T., "TOPCONN",TcGenQry(,,_cQuery),_cAliasNCC,.T.,.T.)
	COUNT TO nCountRec //Contabiliza o numero de registros encontrados pela query
	
	ProcRegua(nCountRec) 
	 
	DBSelectArea(_cAliasNCC)
	(_cAliasNCC)->(DBGoTop())    
	
	//Verifica a existencia de pelo menos um registro para criar o cabecalho da pagina e de dados
	If nCountRec > 0 	                     
	         
		If !lPriCabec
	                    
			Cabecalho(1)	 
			nlinha+=nSaltoLinha 
			nlinha+=nSaltoLinha  
		
		EndIf  	
		
	    lPriCabec:= .T.  			
		  
		nlinha+=nSaltoLinha 
		nlinha+=nSaltoLinha
		quebraPag(nlinha)
		
		oPrint:Say (nlinha + nAjuAltLi1,nColInic + 10,"Notas fiscais faturadas dia: " + DToC(dDtBase) + " porem canceladas por entrada de NCC(Devolução):",oFont12b) 
		
		lCabecNcc:= .T.
		
		nlinha+=nSaltoLinha 
		nlinha+=nSaltoLinha 
		
		cabecDados(1,"NCC",1)
		nlinha+=nSaltoLinha                           
		oPrint:Line(nLinha,nColInic,nLinha,nColFinal)
	                   
		//Imprime dados	
		While (_cAliasNCC)->(!Eof())       
		
			_nTotaliz+= (_cAliasNCC)->E1_VALOR    
		
			IncProc("Processando Titulo de NCC a vista: " + AllTrim((_cAliasNCC)->E1_NUM) + "/" + AllTrim((_cAliasNCC)->E1_PARCELA) )					    
			
			//Seleciona as notas de saida referenciadas pela NCC - Pois uma NCC pode ter mais de uma nota de saida como refencia
			//diante disto abaixo segue um tratamento para controlar esta situacao
			_aNccs:= getNccs((_cAliasNCC)->E1_FILIAL,(_cAliasNCC)->E1_NUM,(_cAliasNCC)->E1_PREFIXO,(_cAliasNCC)->E1_CLIENTE,(_cAliasNCC)->E1_LOJA)  
			
					               
				For x:=1 to Len(_aNccs)
			                             
			 		//Para imprimir os dados do titulo somente uma vez e as demais linhas as NF's de origem
			   		If x == 1  
			               			
			     		nlinha+=nSaltoLinha
						oPrint:Line(nLinha,nColInic,nLinha,nColFinal) 
						qbrPag(1,1,1,"NCC",1,1)        
			               			
			   			printDados((_cAliasNCC)->E1_EMISSAO,(_cAliasNCC)->E1_VENCTO,(_cAliasNCC)->E1_NUM ,(_cAliasNCC)->E1_PARCELA,;
			                       (_cAliasNCC)->E1_CLIENTE,(_cAliasNCC)->E1_LOJA  ,(_cAliasNCC)->A1_NOME,(_cAliasNCC)->E1_VALOR,1,;
			                        AllTrim(_aNccs[x,1]) + '-' + AllTrim(_aNccs[x,2]),1,"","")   
			               			
			      		Else  
			        			nlinha+=nSaltoLinha
								qbrPag(1,1,1,"NCC",1,1)  		
			        			printDados("","","","",;
			           					   "","","",0,1,;
			               				   AllTrim(_aNccs[x,1]) + '-' + AllTrim(_aNccs[x,2]),1,"","")   
			               			
			          EndIf		
			               
			     Next x 			               
		     
		(_cAliasNCC)->(DBSkip())
	    EndDo         
	    
	    nlinha+=nSaltoLinha   
	    oPrint:Line(nLinha,nColInic,nLinha,nColFinal)
	    nlinha+=nSaltoLinha                          
	    oPrint:Line(nLinha,nColInic,nLinha,nColFinal)   
	    qbrPag(1,1,1,"NCC",1,1)
	    printTotal(1,"TOTAL A VISTA",_nTotaliz)                 
	    
	    //Fecha o box da ultima pagina  
	    boxDivisor(2)
		
	EndIf	 
	
	DBSelectArea(_cAliasNCC)    
	(_cAliasNCC)->(DBCloseArea()) 
	

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////  
              
    //Seta variavel responsavel por realizar o totalizador 
    _nTotaliz:= 0
    
     //Query para buscar dados dos titulos de NCC com vencimento a Prazo    	                                                                   
	_cQuery := "SELECT"  
	_cQuery += " E1.E1_FILIAL,E1.E1_EMISSAO,E1.E1_NUM,E1.E1_PREFIXO,E1.E1_CLIENTE,E1.E1_LOJA,A1.A1_NOME," 
	//_cQuery += " (SELECT COALESCE(SUM(D1.D1_TOTAL),0) FROM SD1010 D1 WHERE D1.D_E_L_E_T_ = ' ' AND D1_FILIAL = E1_FILIAL AND D1_TIPO = 'D'"         
	_cQuery += " (SELECT COALESCE(SUM(D1.D1_TOTAL+D1.D1_ICMSRET),0) FROM SD1010 D1 WHERE D1.D_E_L_E_T_ = ' ' AND D1_FILIAL = E1_FILIAL AND D1_TIPO = 'D'"  //HEDER - 05/10/12 - HELP 1482 - Consideracao valor ST
	_cQuery += " AND D1_NFORI = E1_NUM AND D1_SERIORI = E1_PREFIXO AND D1_FORNECE = E1_CLIENTE AND D1_LOJA = E1_LOJA) E1_VALOR " 
	_cQuery += "FROM " + RetSqlName("SE1") + " E1 "  
	_cQuery += "JOIN " + RetSqlName("SA1") + " A1 ON E1.E1_CLIENTE = A1.A1_COD AND E1.E1_LOJA = A1.A1_LOJA "
	_cQuery += "WHERE"  
	_cQuery += " E1.D_E_L_E_T_ = ' '"
	_cQuery += " AND A1.D_E_L_E_T_ = ' '"
	_cQuery += " AND E1.E1_FILIAL = '" + xFilial("SE1") + "'"   
	_cQuery += " AND E1.E1_TIPO = 'NF '"
	_cQuery += " AND E1.E1_ORIGEM = 'MATA460'"  
	_cQuery += " AND E1.E1_EMISSAO = '" + DToS(dDtBase) + "'" 
	_cQuery += " AND E1.E1_EMISSAO <> E1.E1_VENCTO"           
	_cQuery += " AND " 
	//_cQuery += " (SELECT COALESCE(SUM(D1.D1_TOTAL),0) FROM SD1010 D1 WHERE D1.D_E_L_E_T_ = ' ' AND D1_FILIAL = E1_FILIAL AND D1_TIPO = 'D'"         
	_cQuery += " (SELECT COALESCE(SUM(D1.D1_TOTAL+D1.D1_ICMSRET),0) FROM SD1010 D1 WHERE D1.D_E_L_E_T_ = ' ' AND D1_FILIAL = E1_FILIAL AND D1_TIPO = 'D'"  //HEDER - 05/10/12 - HELP 1482 - Consideracao valor ST
	_cQuery += " AND D1_NFORI = E1_NUM AND D1_SERIORI = E1_PREFIXO AND D1_FORNECE = E1_CLIENTE AND D1_LOJA = E1_LOJA) > 0 "  
	_cQuery += "GROUP BY" 
	_cQuery += " E1.E1_FILIAL,E1.E1_EMISSAO,E1.E1_NUM,E1.E1_PREFIXO,E1.E1_CLIENTE,E1.E1_LOJA,A1.A1_NOME "  
	_cQuery += "ORDER BY"
	_cQuery += " E1.E1_NUM"

	If Select(_cAliasNCC) > 0
		(_cAliasNCC)->(DBCloseArea())
	EndIf                                                     
	
	dbUseArea( .T., "TOPCONN",TcGenQry(,,_cQuery),_cAliasNCC,.T.,.T.)
	COUNT TO nCountRec //Contabiliza o numero de registros encontrados pela query
	
	ProcRegua(nCountRec) 
	 
	DBSelectArea(_cAliasNCC)
	(_cAliasNCC)->(DBGoTop())    
	
	//Verifica a existencia de pelo menos um registro para criar o cabecalho da pagina e de dados
	If nCountRec > 0 	                     
	         
		If !lPriCabec
	                    
			Cabecalho(1)	 
			nlinha+=nSaltoLinha 
			nlinha+=nSaltoLinha  
		
		EndIf  	
		
	    lPriCabec:= .T.  	  
	    
	    If !lCabecNcc     
	                           
	    	nlinha+=nSaltoLinha 
			nlinha+=nSaltoLinha
			quebraPag(nlinha)
	    	oPrint:Say (nlinha + nAjuAltLi1,nColInic + 10,"Notas fiscais faturadas dia: " + DToC(dDtBase) + " porem canceladas por entrada de NCC(Devolução):",oFont12b) 								  		
	    
	    EndIf
		
		nlinha+=nSaltoLinha 
		nlinha+=nSaltoLinha 
		
		cabecDados(1,"NCC",1)
		nlinha+=nSaltoLinha                           
		oPrint:Line(nLinha,nColInic,nLinha,nColFinal)
	                   
		//Imprime dados	
		While (_cAliasNCC)->(!Eof())       
		
			_nTotaliz+= (_cAliasNCC)->E1_VALOR    
		
			IncProc("Processando Titulo de NCC a prazo: " + AllTrim((_cAliasNCC)->E1_NUM) )					    
			
			//Seleciona as notas de saida referenciadas pela NCC - Pois uma NCC pode ter mais de uma nota de saida como refencia
			//diante disto abaixo segue um tratamento para controlar esta situacao
			_aNccs:= getNccs((_cAliasNCC)->E1_FILIAL,(_cAliasNCC)->E1_NUM,(_cAliasNCC)->E1_PREFIXO,(_cAliasNCC)->E1_CLIENTE,(_cAliasNCC)->E1_LOJA)  
			               
			For x:=1 to Len(_aNccs)
			                             
				//Para imprimir os dados do titulo somente uma vez e as demais linhas as NF's de origem
			 	If x == 1  
			               			
			  		nlinha+=nSaltoLinha
					oPrint:Line(nLinha,nColInic,nLinha,nColFinal) 
					qbrPag(1,1,1,"NCC",1,1)        
			               			
			        printDados((_cAliasNCC)->E1_EMISSAO,"",(_cAliasNCC)->E1_NUM ,"",;
			                   (_cAliasNCC)->E1_CLIENTE,(_cAliasNCC)->E1_LOJA  ,(_cAliasNCC)->A1_NOME,(_cAliasNCC)->E1_VALOR,1,;
			                    AllTrim(_aNccs[x,1]) + '-' + AllTrim(_aNccs[x,2]),1,"","")   
			               			
			        Else  
			               
			            nlinha+=nSaltoLinha
						qbrPag(1,1,1,"NCC",1,1)    				
			      		printDados("","","","",;
			               		   "","","",0,1,;
			               		   AllTrim(_aNccs[x,1]) + '-' + AllTrim(_aNccs[x,2]),1,"","")   
			               			
			        EndIf		
			               
			  Next x 			                
		     
		(_cAliasNCC)->(DBSkip())
	    EndDo         
	    
	    nlinha+=nSaltoLinha   
	    oPrint:Line(nLinha,nColInic,nLinha,nColFinal)
	    nlinha+=nSaltoLinha                          
	    oPrint:Line(nLinha,nColInic,nLinha,nColFinal)   
	    qbrPag(1,1,1,"NCC",1,1)
	    printTotal(1,"TOTAL A PRAZO",_nTotaliz)                 
	    
	    //Fecha o box da ultima pagina  
	    boxDivisor(2)
		
	EndIf	 
	
	DBSelectArea(_cAliasNCC)    
	(_cAliasNCC)->(DBCloseArea()) 	
	
	
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////  
              
    //Seta variavel responsavel por realizar o totalizador 
    _nTotaliz:= 0
    
     //Query para buscar dados das notas de entradas do tipo devolucao e formulario proprio igual a sim
	_cQuery := "SELECT"  
	//_cQuery += " D1.D1_DTDIGIT D1_EMISSAO,D1.D1_DOC,D1.D1_SERIE,D1.D1_NFORI,D1.D1_SERIORI,D1.D1_FORNECE,D1.D1_LOJA,A1.A1_NOME,SUM(D1.D1_TOTAL) VLRTOTAL " 
	_cQuery += " D1.D1_DTDIGIT D1_EMISSAO,D1.D1_DOC,D1.D1_SERIE,D1.D1_NFORI,D1.D1_SERIORI,D1.D1_FORNECE,D1.D1_LOJA,A1.A1_NOME,SUM(D1.D1_TOTAL+D1.D1_ICMSRET) VLRTOTAL " //HEDER - 05/10/12 - HELP 1482 - Consideracao valor ST
	_cQuery += "FROM " + RetSqlName("SD1") + " D1 "  
	_cQuery += "JOIN " + RetSqlName("SA1") + " A1 ON A1.A1_COD = D1.D1_FORNECE AND A1.A1_LOJA = D1.D1_LOJA "
	_cQuery += "WHERE"  
	_cQuery += " D1.D_E_L_E_T_ = ' '"
	_cQuery += " AND A1.D_E_L_E_T_ = ' '"
	_cQuery += " AND D1.D1_FILIAL = '" + xFilial("SD1") + "'"   
	_cQuery += " AND D1.D1_TIPO = 'D'" 
	_cQuery += " AND D1.D1_DTDIGIT = '" + DToS(dDtBase) + "'" 
	_cQuery += " AND D1_FORMUL = 'S' "           
	_cQuery += "GROUP BY"
	_cQuery += " D1.D1_DTDIGIT, D1.D1_DOC, D1.D1_SERIE, D1.D1_NFORI, D1.D1_SERIORI, D1.D1_FORNECE, D1.D1_LOJA, A1.A1_NOME " 
	_cQuery += "ORDER BY"
	_cQuery += " D1.D1_DOC, D1.D1_SERIE"       

	If Select(_cAliasDv1) > 0
		(_cAliasDv1)->(DBCloseArea())
	EndIf                                                     
	
	dbUseArea( .T., "TOPCONN",TcGenQry(,,_cQuery),_cAliasDv1,.T.,.T.)
	COUNT TO nCountRec //Contabiliza o numero de registros encontrados pela query
	
	ProcRegua(nCountRec) 
	 
	DBSelectArea(_cAliasDv1)
	(_cAliasDv1)->(DBGoTop())    
	
	//Verifica a existencia de pelo menos um registro para criar o cabecalho da pagina e de dados
	If nCountRec > 0 	                     
	         
		If !lPriCabec
	                    
			Cabecalho(1)	 
			nlinha+=nSaltoLinha 
			nlinha+=nSaltoLinha  
		
		EndIf  	
		
	    lPriCabec:= .T.  			
		  
		nlinha+=nSaltoLinha 
		nlinha+=nSaltoLinha
		quebraPag(nlinha)
		
		oPrint:Say (nlinha + nAjuAltLi1,nColInic + 10,"Devolução de nota por motivos diversos(NOTA PRÓPRIA):",oFont12b) 
		
		nlinha+=nSaltoLinha 
		nlinha+=nSaltoLinha 
		
		cabecDados(0,"",2)
		nlinha+=nSaltoLinha                           
		oPrint:Line(nLinha,nColInic,nLinha,nColFinal)
	                   
		//Imprime dados	
		While (_cAliasDv1)->(!Eof())       
		
			_nTotaliz+= (_cAliasDv1)->VLRTOTAL    
		
			IncProc("Processando a nota de devolução: " + AllTrim((_cAliasDv1)->D1_DOC) + "/" + AllTrim((_cAliasDv1)->D1_SERIE) )
		
			nlinha+=nSaltoLinha
			oPrint:Line(nLinha,nColInic,nLinha,nColFinal) 
			qbrPag(1,1,0,"",2,1) 	     
			
			printDados((_cAliasDv1)->D1_EMISSAO,"","","",(_cAliasDv1)->D1_FORNECE,(_cAliasDv1)->D1_LOJA,(_cAliasDv1)->A1_NOME,;
			           (_cAliasDv1)->VLRTOTAL,0,"",2,(_cAliasDv1)->D1_DOC + '-' + (_cAliasDv1)->D1_SERIE,(_cAliasDv1)->D1_NFORI + '-' + (_cAliasDv1)->D1_SERIORI)
		     
		(_cAliasDv1)->(DBSkip())
	    EndDo         
	    
	    nlinha+=nSaltoLinha   
	    oPrint:Line(nLinha,nColInic,nLinha,nColFinal)
	    nlinha+=nSaltoLinha                          
	    oPrint:Line(nLinha,nColInic,nLinha,nColFinal)   
	    qbrPag(1,1,0,"",2,1)
	    printTotal(0,"TOTAL",_nTotaliz)                 
	    
	    //Fecha o box da ultima pagina
	    boxDivisor(0)
		
	EndIf	 
	
	DBSelectArea(_cAliasDv1)    
	(_cAliasDv1)->(DBCloseArea())  	
		
	
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////  
              
    //Seta variavel responsavel por realizar o totalizador 
    _nTotaliz:= 0
    
     //Query para buscar dados das notas de entradas do tipo devolucao e formulario proprio diferente de sim
	_cQuery := "SELECT"  
	//_cQuery += " D1.D1_DTDIGIT D1_EMISSAO,D1.D1_DOC,D1.D1_SERIE,D1.D1_NFORI,D1.D1_SERIORI,D1.D1_FORNECE,D1.D1_LOJA,A1.A1_NOME,SUM(D1.D1_TOTAL) VLRTOTAL " 
	_cQuery += " D1.D1_DTDIGIT D1_EMISSAO,D1.D1_DOC,D1.D1_SERIE,D1.D1_NFORI,D1.D1_SERIORI,D1.D1_FORNECE,D1.D1_LOJA,A1.A1_NOME,SUM(D1.D1_TOTAL+D1.D1_ICMSRET) VLRTOTAL " //HEDER - 05/10/12 - HELP 1482 - Consideracao valor ST
	_cQuery += "FROM " + RetSqlName("SD1") + " D1 "  
	_cQuery += "JOIN " + RetSqlName("SA1") + " A1 ON A1.A1_COD = D1.D1_FORNECE AND A1.A1_LOJA = D1.D1_LOJA "
	_cQuery += "WHERE"  
	_cQuery += " D1.D_E_L_E_T_ = ' '"
	_cQuery += " AND A1.D_E_L_E_T_ = ' '"
	_cQuery += " AND D1.D1_FILIAL = '" + xFilial("SD1") + "'"   
	_cQuery += " AND D1.D1_TIPO = 'D'" 
	_cQuery += " AND D1.D1_DTDIGIT = '" + DToS(dDtBase) + "'" 
	_cQuery += " AND D1_FORMUL <> 'S' "           
	_cQuery += "GROUP BY"
	_cQuery += " D1.D1_DTDIGIT, D1.D1_DOC, D1.D1_SERIE, D1.D1_NFORI, D1.D1_SERIORI, D1.D1_FORNECE, D1.D1_LOJA, A1.A1_NOME " 
	_cQuery += "ORDER BY"
	_cQuery += " D1.D1_DOC, D1.D1_SERIE"       

	If Select(_cAliasDv2) > 0
		(_cAliasDv2)->(DBCloseArea())
	EndIf                                                     
	
	dbUseArea( .T., "TOPCONN",TcGenQry(,,_cQuery),_cAliasDv2,.T.,.T.)
	COUNT TO nCountRec //Contabiliza o numero de registros encontrados pela query
	
	ProcRegua(nCountRec) 
	 
	DBSelectArea(_cAliasDv2)
	(_cAliasDv2)->(DBGoTop())    
	
	//Verifica a existencia de pelo menos um registro para criar o cabecalho da pagina e de dados
	If nCountRec > 0 	                     
	         
		If !lPriCabec
	                    
			Cabecalho(1)	 
			nlinha+=nSaltoLinha 
			nlinha+=nSaltoLinha  
		
		EndIf  	
		
	    lPriCabec:= .T.  			
		  
		nlinha+=nSaltoLinha 
		nlinha+=nSaltoLinha
		quebraPag(nlinha)
		
		oPrint:Say (nlinha + nAjuAltLi1,nColInic + 10,"Devolução de nota por motivos diversos(NOTA CLIENTE):",oFont12b) 
		
		nlinha+=nSaltoLinha 
		nlinha+=nSaltoLinha 
		
		cabecDados(0,"",2)
		nlinha+=nSaltoLinha                           
		oPrint:Line(nLinha,nColInic,nLinha,nColFinal)
	                   
		//Imprime dados	
		While (_cAliasDv2)->(!Eof())       
		
			_nTotaliz+= (_cAliasDv2)->VLRTOTAL    
		
			IncProc("Processando a nota de devolução: " + AllTrim((_cAliasDv2)->D1_DOC) + "/" + AllTrim((_cAliasDv2)->D1_SERIE) )
		
			nlinha+=nSaltoLinha
			oPrint:Line(nLinha,nColInic,nLinha,nColFinal) 
			qbrPag(1,1,0,"",2,1) 	     
			
			printDados((_cAliasDv2)->D1_EMISSAO,"","","",(_cAliasDv2)->D1_FORNECE,(_cAliasDv2)->D1_LOJA,(_cAliasDv2)->A1_NOME,;
			           (_cAliasDv2)->VLRTOTAL,0,"",2,(_cAliasDv2)->D1_DOC + '-' + (_cAliasDv2)->D1_SERIE,(_cAliasDv2)->D1_NFORI + '-' + (_cAliasDv2)->D1_SERIORI)
		     
		(_cAliasDv2)->(DBSkip())
	    EndDo         
	    
	    nlinha+=nSaltoLinha   
	    oPrint:Line(nLinha,nColInic,nLinha,nColFinal)
	    nlinha+=nSaltoLinha                          
	    oPrint:Line(nLinha,nColInic,nLinha,nColFinal)   
	    qbrPag(1,1,0,"",2,1)
	    printTotal(0,"TOTAL",_nTotaliz)                 
	    
	    //Fecha o box da ultima pagina
	    boxDivisor(0)
		
	EndIf	 
	
	DBSelectArea(_cAliasDv2)    
	(_cAliasDv2)->(DBCloseArea())  	
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	 //Query para buscar dados das notas canceladas no dia informado pelo usuario
	_cQuery := "SELECT"  
	_cQuery += " FT_NFISCAL,FT_SERIE,FT_TIPOMOV " 
	_cQuery += "FROM " + RetSqlName("SFT") + " FT "  
	_cQuery += "WHERE"  
	_cQuery += " FT.D_E_L_E_T_ = ' '" 
	_cQuery += " AND FT.FT_FILIAL = '" + xFilial("SFT") + "'"   
	_cQuery += " AND FT.FT_DTCANC = '" + DToS(dDtBase)  + "'" 
	_cQuery += " AND FT.FT_OBSERV LIKE '%CANCELADA%'"     
	_cQuery += "GROUP BY"
	_cQuery += " FT_NFISCAL,FT_SERIE,FT_TIPOMOV "        
	_cQuery += "ORDER BY"
	_cQuery += " FT_TIPOMOV,FT_NFISCAL,FT_SERIE"       

	If Select(_cAliasCan) > 0
		(_cAliasCan)->(DBCloseArea())
	EndIf                                                     
	
	dbUseArea( .T., "TOPCONN",TcGenQry(,,_cQuery),_cAliasCan,.T.,.T.)
	COUNT TO nCountRec //Contabiliza o numero de registros encontrados pela query
	
	ProcRegua(nCountRec) 
	 
	DBSelectArea(_cAliasCan)
	(_cAliasCan)->(DBGoTop())    
	
	//Verifica a existencia de pelo menos um registro para criar o cabecalho da pagina e de dados
	If nCountRec > 0 	                     
	         
		If !lPriCabec
	                    
			Cabecalho(1)	 
			nlinha+=nSaltoLinha 
			nlinha+=nSaltoLinha  
		
		EndIf  	
		
	    lPriCabec:= .T.  			
		  
		nlinha+=nSaltoLinha 
		nlinha+=nSaltoLinha
		quebraPag(nlinha)                                                                                         
		
		oPrint:Say (nlinha + nAjuAltLi1,nColInic + 10,"Notas Fiscais canceladas no dia:",oFont12b) 
		
		nlinha+=nSaltoLinha 
		nlinha+=nSaltoLinha 
		quebraPag(nlinha) 
		
		cabDad03()
		nlinha+=nSaltoLinha
		oPrint:Line(nLinha,nColInic,nLinha,nColInic + 710) 
		                   
		//Imprime dados	
		While (_cAliasCan)->(!Eof())       
	    
	    	nlinha+=nSaltoLinha
			oPrint:Line(nLinha,nColInic,nLinha,nColInic + 710) 
			qbraPagin(1,1)      
			
			prtDad03((_cAliasCan)->FT_NFISCAL,(_cAliasCan)->FT_SERIE,(_cAliasCan)->FT_TIPOMOV)
	
		(_cAliasCan)->(DBSkip())
	    EndDo        
	    
	    boxDiv03()
	                            
	    DBSelectArea(_cAliasCan)
	    (_cAliasCan)->(DBCloseArea()) 

	EndIf     
	   
	//Só imprime a assinatura caso haja algum dado a ser impresso
	If lPriCabec
	
		Assinatura()
		
	EndIf	    
	
	//Fecha a janela depois de executar o relatorio 
	oDlg:End()

Return

/*
===============================================================================================================================
Programa----------: getNccs
Autor-------------: Fabiano Dias 
Data da Criacao---: 05/08/2010                                     .
Descrição---------: Imprime dados
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function getNccs(_cFil,_cDoc,_cSerie,_cFornec,_cLjForn)     

Local _cQuery  := ""
Local _cAliasNF:= GetNextAlias() //Armazena o alias da query das NF'S de origem das NCC   
Local _aNfori  := {}

	_cQuery := "SELECT"  
	_cQuery += " D1_DOC,D1_SERIE " 
	_cQuery += "FROM " + RetSqlName("SD1") + " D1 "  
	_cQuery += "WHERE"  
	_cQuery += " D1.D_E_L_E_T_ = ' '"    
	_cQuery += " AND D1.D1_TIPO = 'D'" 
	_cQuery += " AND D1.D1_FILIAL = '"  + _cFil    + "'"   
	_cQuery += " AND D1.D1_NFORI = '"   + _cDoc    + "'" 
	_cQuery += " AND D1.D1_SERIORI = '" + _cSerie  + "'" 
	_cQuery += " AND D1.D1_FORNECE = '" + _cFornec + "'"           
	_cQuery += " AND D1.D1_LOJA = '"    + _cLjForn + "' "    
	_cQuery += "GROUP BY"
	_cQuery += " D1_DOC,D1_SERIE "   
	_cQuery += "ORDER BY"
	_cQuery += " D1_DOC,D1_SERIE "        

	If Select(_cAliasNF) > 0
		(_cAliasNF)->(DBCloseArea())
	EndIf                                                     
	
	dbUseArea( .T., "TOPCONN",TcGenQry(,,_cQuery),_cAliasNF,.T.,.T.) 
	 
	DBSelectArea(_cAliasNF)
	(_cAliasNF)->(DBGoTop())    
	
	While (_cAliasNF)->(!Eof())         
	
	
			aAdd(_aNfori,{(_cAliasNF)->D1_DOC,(_cAliasNF)->D1_SERIE})
		
	
	(_cAliasNF)->(DBSkip())
	EndDo                   
	
	DBSelectArea(_cAliasNF)
	(_cAliasNF)->(DBCloseArea())	

Return _aNfori

/*
===============================================================================================================================
Programa----------: ImpMemo
Autor-------------: Fabiano Dias 
Data da Criacao---: 05/08/2010                                     .
Descrição---------: Imprime dados
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ImpMemo(msgValor,oFont)      
     
Local nAux  :=1
      
	nAux := 1
	While nAux <= Len(msgValor)                                           
	
		nlinha+=nSaltoLinha     
		quebraPag(nLinha)
		oPrint:Say (nLinha,nColInic + 10,AllTrim(msgValor[nAux]),oFont)
		nAux++
		 
	EndDo

Return 

/*
===============================================================================================================================
Programa----------: Assinatura
Autor-------------: Fabiano Dias 
Data da Criacao---: 05/08/2010                                     .
Descrição---------: Pesquisa os dados do usuario corrente para imprimir a assinatura.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function Assinatura()  

Local _aDadUsuaio:= {}

PswOrder(2) //Ordem de Nome de Usuario
If PswSeek( AllTrim(cUserName), .T. )

	_aDadUsuaio := PswRet(1)                   
	
	
	quebraPag(nlinha + (nSaltoLinha * 6))
	nlinha+=nSaltoLinha  
	nlinha+=nSaltoLinha
	nlinha+=nSaltoLinha
	nlinha+=nSaltoLinha
	        
	oPrint:Say (nlinha,nColFinal / 2,'_____________________________________________________'    ,oFont12b,nColFinal,,,2)
	nlinha+=nSaltoLinha
	oPrint:Say (nlinha,nColFinal / 2 ,Upper(AllTrim(_aDadUsuaio[1,4]))                         ,oFont12b,nColFinal,,,2)
	nlinha+=nSaltoLinha
	oPrint:Say (nlinha,nColFinal / 2 ,Upper(AllTrim(_aDadUsuaio[1,12]))                        ,oFont12b,nColFinal,,,2)

EndIf

Return
