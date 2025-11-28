/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz     |30/01/2019| Chamado 27795. Realização de Ajustes no fonte para funcionar com o novo servidor Totvs Loboguará.
Lucas Borges  |11/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25.
================================================================================================================================
*/

#Include "TOTVS.ch"      

/*
===============================================================================================================================
Programa--------: RFIN007
Autor-----------: Fabiano Dias
Data da Criacao-: 15/07/2010 
Descrição-------: Relatorio financeiro que demonstra o que faturei x o que realmente recebi, demonstrando devolucoes,descontos
                  faltas de mercadorias e saldo em aberto.
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function RFIN007()
    
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
Private nColFinal   := 3385 
Private nqbrPagina  := 2200 
Private nLinInBox   
Private nSaltoLinha := 50               
Private nAjuAltLi1  := 11 //ajusta a altura de impressao dos dados do relatorio

Private oBrush      := TBrush():New( ,CLR_LIGHTGRAY)   

Private cPerg       := "RFIN007"


Begin Sequence                                                                              
   
   If !Pergunte(cPerg,.T.) 
      Break
   EndIf
   
   Define Font oFont10    Name "Courier New"       Size 0,-08       // Tamanho 14    
   Define Font oFont10b   Name "Courier New"       Size 0,-08 Bold   // Tamanho 14 
   Define Font oFont12    Name "Courier New"       Size 0,-10       // Tamanho 12
   Define Font oFont12b   Name "Courier New"       Size 0,-10 Bold  // Tamanho 12 Negrito  
   Define Font oFont14    Name "Courier New"       Size 0,-10       // Tamanho 14
   Define Font oFont14b   Name "Courier New"       Size 0,-10 Bold  // Tamanho 14         
   Define Font oFont14Prb Name "Courier New"       Size 0,-12 Bold  // Tamanho 14 Negrito
   Define Font oFont16b   Name "Helvetica"         Size 0,-14 Bold  // Tamanho 16 Negrito   

   oPrint:= TMSPrinter():New("FATURAMENTO X RECEBIDO") 
   oPrint:SetLandscape() 	// Paisagem
   oPrint:SetPaperSize(9)	// Seta para papel A4
	                 		
   /// startando a impressora
   oPrint:Say(0,0," ",oFont12,100)        

   oPrint:StartPage() 

   //0 - para nao imprimir a numeracao de pagina na emissao da pagina de parametros
   RFIN007C(0)   
   RFIN007I(oPrint)
	     		
   Processa({|| RFIN007DR() })  
	
   oPrint:EndPage()	// Finaliza a Pagina.
   oPrint:Preview()	// Visualiza antes de Imprimir.

End Sequence

Return       

/*
===============================================================================================================================
Programa--------: RFIN007I
Autor-----------: Fabiano Dias
Data da Criacao-: 22/03/2010
Descrição-------: Funcao criada para imprimir a pagina de parametros do relatorio em modo grafico.
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function RFIN007I(oPrint)      

Local nAux     := 1   
Local nqtdeCar

Local _aDadosPegunte := {}
Local _nI
Local _cTexto

//Quantidade de caracteres para quebra de Linha
nqtdeCar:= 84	

oPrint:StartPage()   // Inicia uma nova página     
nLinha+= 080                                    
oPrint:Line(nLinha,nColInic,nLinha,nColFinal)
nLinha+= 60

aAdd(_aDadosPegunte,{"01", "Filial ?"      , "MV_PAR01"})       
aAdd(_aDadosPegunte,{"02", "Da Emissao ?"  , "MV_PAR02"})           
aAdd(_aDadosPegunte,{"03", "Ate Emissao ?" , "MV_PAR03"})
aAdd(_aDadosPegunte,{"04", "De Cliente ?"  , "MV_PAR04"})           
aAdd(_aDadosPegunte,{"05", "Loja ? "       , "MV_PAR05"})          
aAdd(_aDadosPegunte,{"06", "Ate Cliente ?" , "MV_PAR06"})
aAdd(_aDadosPegunte,{"07", "Loja ?"        , "MV_PAR07"})
aAdd(_aDadosPegunte,{"08", "Rede ?"        , "MV_PAR08"})  
aAdd(_aDadosPegunte,{"09", "Tipo ?"        , "MV_PAR09"})  // Analítico ## Sintético

For _nI := 1 To Len(_aDadosPegunte)          
	nAux:= 1      
	
	oPrint:Say (nLinha,nColInic + 10,"Pergunta " + _aDadosPegunte[_nI,1] + ':' +  _aDadosPegunte[_nI,2] , oFont14Prb)    
		
	If _aDadosPegunte[_nI,3] == "MV_PAR09"
	   If MV_PAR09 ==  1
	      _cTexto := "Analítico"
	   ElseIf MV_PAR09 == 2
	      _cTexto := "Sintético"
	   Else
	      _cTexto := ""
	   EndIf
	   oPrint:Say (nLinha,1200,_cTexto,oFont14Prb)  
		   
    Else
       _cTexto := &(_aDadosPegunte[_nI,3])
       If ValType(_cTexto) == "D"
          _cTexto := DToC(_cTexto)
       EndIf   
       oPrint:Say (nLinha,1200,_cTexto,oFont14Prb)  		
    EndIf	
	    
	nLinha+= 60
Next

nLinha+= 60
oPrint:Line(nLinha,nColInic,nLinha,nColFinal)
	
oPrint:EndPage()     // Finaliza a página

Return

/*
===============================================================================================================================
Programa--------: RFIN007C
Autor-----------: Fabiano Dias
Data da Criacao-: 22/03/2010
Descrição-------: Funcao criada para imprimir cabeçalho da página.
Parametros------: impNrPag - 
Retorno---------: Nenhum
===============================================================================================================================
*/
//Cabecalho da Pagina
Static Function RFIN007C(impNrPag)

Local cRaizServer := If(issrvunix(), "/", "\")    
Local cTitulo     := "Relatório de valor de Vendas Faturadas x Valor Recebido -  "+IIf(MV_PAR09 == 1,"Analitico","Sintetico") + " - Emissão de " +  DToC(MV_PAR02) + " até " + DToC(MV_PAR03)
  
nLinha:=0100

	oPrint:SayBitmap(nLinha,nColInic,cRaizServer + "system/lgrl01.bmp",250,100)        
	If impNrPag <> 0
		oPrint:Say (nlinha,(nColInic + 2750),"PÁGINA: " + AllTrim(Str(nPagina)),oFont12b)
		Else
			oPrint:Say (nlinha,(nColInic + 2750),"SIGA/RFIN007",oFont12b)
			oPrint:Say (nlinha + 100,(nColInic + 2750),"EMPRESA: " + AllTrim(SM0->M0_NOME) + '/' + AllTrim(SM0->M0_FILIAL),oFont12b)
	EndIf
	oPrint:Say (nlinha + 50,(nColInic + 2750),"DATA DE EMISSÃO: " + DToC(DATE()),oFont12b)
	nlinha+=(nSaltoLinha * 3)           
	                                                   
	oPrint:Say (nlinha,nColFinal / 2,cTitulo,oFont16b,nColFinal,,,2)
	
	nlinha+=nSaltoLinha 
	nlinha+=nSaltoLinha        
	
	oPrint:Line(nLinha,nColInic,nLinha,nColFinal) 

Return

/*
===============================================================================================================================
Programa--------: RFIN007CD
Autor-----------: Fabiano Dias
Data da Criacao-: 22/03/2010
Descrição-------: Funcao criada para imprimir cabeçalho de dados.
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function RFIN007CD()        
                                                                                                 
oPrint:Say (nlinha + nAjuAltLi1,(nColInic + 1755) + (((nColInic + 2735) - (nColInic + 1755))/2),"Descontos",oFont12b,nColInic + 2735,,,2)

oPrint:Box(nlinha,nColInic + 1920,nLinha + nSaltoLinha,nColInic + 2570) //Box Descontos 
nlinha+=nSaltoLinha

nLinInBox:= nlinha

oPrint:FillRect({(nlinha+3),nColInic       ,nlinha + nSaltoLinha,nColInic + 1745},oBrush)//Box Faturamento                     
oPrint:FillRect({(nlinha+3),nColInic + 1920,nlinha + nSaltoLinha,nColInic + 2570},oBrush)//Box Descontos
oPrint:FillRect({(nlinha+3),nColInic + 2745,nlinha + nSaltoLinha,nColFinal}      ,oBrush)//Box Descontos


oPrint:Say (nlinha + nAjuAltLi1,nColInic +10  ,"Rede"	          ,oFont12b) 
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 510,"Faturamento"	  ,oFont12b)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 900,"Recebido"		  ,oFont12b)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 1190,"Devoluções" 	  ,oFont12b)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 1480,"Saldo Aberto"   ,oFont12b)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 2000,"Contratuais"	  ,oFont12b)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 2435,"Outros"		  ,oFont12b)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 2750,"Total Descontos",oFont12b)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 3090,"%Faturamento"	  ,oFont12b)

Return                              

/*
===============================================================================================================================
Programa--------: RFIN007CE()
Autor-----------: Fabiano Dias
Data da Criacao-: 22/03/2010
Descrição-------: Funcao criada para imprimir cabeçalho de dados Entrega.
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function RFIN007CE()        
                                                                                                 
oPrint:Say (nlinha + nAjuAltLi1,(nColInic + 1095) + (((nColInic + 2985) - (nColInic + 1095))/2),"Descontos",oFont12b,nColInic + 2735,,,2)

oPrint:Box(nlinha,nColInic + 1095,nLinha + nSaltoLinha,nColInic + 2985) //Box Descontos 
nlinha+=nSaltoLinha

nLinInBox:= nlinha

oPrint:FillRect({(nlinha+3),nColInic       ,nlinha + nSaltoLinha,nColInic + 1085},oBrush)//Box Faturamento                     
oPrint:FillRect({(nlinha+3),nColInic + 1095,nlinha + nSaltoLinha,nColInic + 2985},oBrush)//Box Descontos
oPrint:FillRect({(nlinha+3),nColInic + 2995,nlinha + nSaltoLinha,nColFinal}      ,oBrush)//Box Descontos


oPrint:Say (nlinha + nAjuAltLi1,nColInic +10  ,"Rede"	            ,oFont12b) 
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 510,"Faturamento"	    ,oFont12b)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 815,"Saldo Aberto"	    ,oFont12b)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 1165,"Contratuais" 	    ,oFont12b)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 1500,"Falta Merc."      ,oFont12b)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 1765,"Atraso Entrega"   ,oFont12b)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 2075,"Diferenca Preço"  ,oFont12b)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 2430,"Diferenca Pes."   ,oFont12b)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 2845,"Outros"			,oFont12b)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 3000,"Total Desc."      ,oFont12b)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 3245,"%Fat."            ,oFont12b)

Return                              

/*
===============================================================================================================================
Programa--------: RFIN007PD
Autor-----------: Fabiano Dias
Data da Criacao-: 22/03/2010
Descrição-------: Funcao criada para imprimir dados do relatório.
Parametros------: cRede
                  nFaturado
                  nRecebido
                  nDevolvido
                  nDescContr
                  nOutros
                  nSldAbert        
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function RFIN007PD(cRede,nFaturado,nRecebido,nDevolvido,nDescContr,nOutros,nSldAbert)        
                                                     
Local nTotalDesc:= 0                                      
Local nPorcFat  := 0

nTotalDesc:= nDescContr + nOutros                        
nSaldo:= nSldAbert                                 
nPorcFat  := (nTotalDesc / nFaturado) * 100
                                                                                               
oPrint:Say (nlinha + nAjuAltLi1,nColInic +10   ,SubStr(AllTrim(cRede),1,23)			      ,oFont10) 
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 420 ,Transform(nFaturado,"@E 999,999,999,999.99") ,oFont10)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 750 ,Transform(nRecebido,"@E 999,999,999,999.99") ,oFont10)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 1080,Transform(nDevolvido,"@E 999,999,999,999.99"),oFont10)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 1410,Transform(nSaldo    ,"@E 999,999,999,999.99"),oFont10)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 1905,Transform(nDescContr,"@E 999,999,999,999.99"),oFont10)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 2235,Transform(nOutros   ,"@E 999,999,999,999.99"),oFont10)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 2750,Transform(nTotalDesc,"@E 999,999,999,999.99"),oFont10)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 3230,Transform(nPorcFat  ,"@E 999.99")	          ,oFont10)

Return    

/*
===============================================================================================================================
Programa--------: RFIN007PA
Autor-----------: Fabiano Dias
Data da Criacao-: 22/03/2010
Descrição-------: Funcao criada para imprimir dados do relatório analítico.
Parametros------: cRede
                  nFaturado
                  nDescContr
                  nFaltMerc
                  nAtraEntr
                  nDifPreco
                  nDifPesag
                  nOutros
                  nSldAbert        
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function RFIN007PA(cRede,nFaturado,nDescContr,nFaltMerc,nAtraEntr,nDifPreco,nDifPesag,nOutros,nSldAbert)        
                                                     
Local nTotalDesc:= 0                                      
Local nPorcFat  := 0

nTotalDesc:= nDescContr + nFaltMerc + nAtraEntr + nDifPreco + nDifPesag + nOutros                        
nSaldo:= nSldAbert                 
nPorcFat  := (nTotalDesc / nFaturado) * 100
                                                                                               
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 10  ,SubStr(AllTrim(cRede),1,23)			        ,oFont10) 
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 420 ,Transform(nFaturado  ,"@E 999,999,999,999.99") ,oFont10)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 750 ,Transform(nSaldo     ,"@E 999,999,999,999.99") ,oFont10)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 1080,Transform(nDescContr ,"@E 999,999,999,999.99") ,oFont10)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 1410,Transform(nFaltMerc  ,"@E 999,999,999,999.99") ,oFont10)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 1740,Transform(nAtraEntr  ,"@E 999,999,999,999.99") ,oFont10)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 2070,Transform(nDifPreco  ,"@E 999,999,999,999.99") ,oFont10)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 2400,Transform(nDifPesag  ,"@E 999,999,999,999.99") ,oFont10)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 2660,Transform(nOutros    ,"@E 999,999,999,999.99") ,oFont10)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 2920,Transform(nTotalDesc ,"@E 999,999,999,999.99") ,oFont10)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 3247,Transform(nPorcFat   ,"@E 999.99")	            ,oFont10)

Return                       

/*
===============================================================================================================================
Programa--------: RFIN007PT
Autor-----------: Fabiano Dias
Data da Criacao-: 22/03/2010
Descrição-------: Funcao criada para imprimir dados do relatório Totais.
Parametros------: cDescTot
                  nFaturado
                  nRecebido
                  nDevolvido
                  nDescContr
                  nOutros
                  nSldAbert
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function RFIN007PT(cDescTot,nFaturado,nRecebido,nDevolvido,nDescContr,nOutros,nSldAbert)        
                                                     
Local nTotalDesc:= 0                                      
Local nSldAberto:= 0
Local nPorcFat  := 0

nTotalDesc:= nDescContr + nOutros                        
nSldAberto:= nSldAbert                 
nPorcFat  := (nTotalDesc / nFaturado) * 100
                                                                                               
oPrint:Say (nlinha + nAjuAltLi1,nColInic +10   ,SubStr(AllTrim(cDescTot),1,23)			      ,oFont10b) 
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 420 ,Transform(nFaturado,"@E 999,999,999,999.99") ,oFont10b)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 750 ,Transform(nRecebido,"@E 999,999,999,999.99") ,oFont10b)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 1080,Transform(nDevolvido,"@E 999,999,999,999.99"),oFont10b)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 1410,Transform(nSldAberto,"@E 999,999,999,999.99"),oFont10b)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 1905,Transform(nDescContr,"@E 999,999,999,999.99"),oFont10b)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 2235,Transform(nOutros   ,"@E 999,999,999,999.99"),oFont10b)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 2750,Transform(nTotalDesc,"@E 999,999,999,999.99"),oFont10b)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 3230,Transform(nPorcFat  ,"@E 999.99")	          ,oFont10b)

Return                                                                                        

/*
===============================================================================================================================
Programa--------: RFIN007PN
Autor-----------: Fabiano Dias
Data da Criacao-: 22/03/2010
Descrição-------: Funcao criada para imprimir dados do relatório totais analítico.
Parametros------: cDescTot
                  nFaturado
                  nDescContr
                  nFaltMerc
                  nAtraEntr
                  nDifPreco
                  nDifPesag
                  nOutros
                  nSldAbert) 
Retorno---------: Nenhum
===============================================================================================================================
*/      
Static Function RFIN007PN(cDescTot,nFaturado,nDescContr,nFaltMerc,nAtraEntr,nDifPreco,nDifPesag,nOutros,nSldAbert) 
                                                     
Local nTotalDesc:= 0                                      
Local nPorcFat  := 0

nTotalDesc:= nDescContr + nFaltMerc + nAtraEntr + nDifPreco + nDifPesag + nOutros    
nPorcFat  := (nTotalDesc / nFaturado) * 100
                                                                                               
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 10  ,SubStr(AllTrim(cDescTot),1,23)			        ,oFont10b) 
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 420 ,Transform(nFaturado  ,"@E 999,999,999,999.99") ,oFont10b)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 750 ,Transform(nSldAbert  ,"@E 999,999,999,999.99") ,oFont10b)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 1080,Transform(nDescContr ,"@E 999,999,999,999.99") ,oFont10b)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 1410,Transform(nFaltMerc  ,"@E 999,999,999,999.99") ,oFont10b)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 1740,Transform(nAtraEntr  ,"@E 999,999,999,999.99") ,oFont10b)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 2070,Transform(nDifPreco  ,"@E 999,999,999,999.99") ,oFont10b)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 2400,Transform(nDifPesag  ,"@E 999,999,999,999.99") ,oFont10b)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 2660,Transform(nOutros    ,"@E 999,999,999,999.99") ,oFont10b)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 2920,Transform(nTotalDesc ,"@E 999,999,999,999.99") ,oFont10b)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 3247,Transform(nPorcFat   ,"@E 999.99")	            ,oFont10b)

Return                           

/*
===============================================================================================================================
Programa--------: RFIN007BD
Autor-----------: Fabiano Dias
Data da Criacao-: 22/03/2010
Descrição-------: Funcao criada para imprimir dados do relatório quadros separadores de dados (Box)
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function RFIN007BD()
      
oPrint:Line(nLinInBox,nColInic + 425,nLinha,nColInic + 425)   
oPrint:Line(nLinInBox,nColInic + 755,nLinha,nColInic + 755)
oPrint:Line(nLinInBox,nColInic + 1085,nLinha,nColInic + 1085)
oPrint:Line(nLinInBox,nColInic + 1415,nLinha,nColInic + 1415)
oPrint:Line(nLinInBox,nColInic + 2245,nLinha,nColInic + 2245)
oPrint:Line(nLinInBox,nColInic + 3085,nLinha,nColInic + 3085)

oPrint:Box(nLinInBox,nColInic,nLinha,nColInic + 1745) //Box Faturamento
oPrint:Box(nLinInBox,nColInic + 1920,nLinha,nColInic + 2570) //Box Descontos 
oPrint:Box(nLinInBox,nColInic + 2745,nLinha,nColFinal) //Box Totalizador Descontos

Return     

/*
===============================================================================================================================
Programa--------: RFIN007B2
Autor-----------: Fabiano Dias
Data da Criacao-: 22/03/2010
Descrição-------: Funcao criada para imprimir dados do relatório quadros separadores de dados (Box)
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function RFIN007B2()
      
oPrint:Line(nLinInBox,nColInic + 425,nLinha,nColInic  + 425)   
oPrint:Line(nLinInBox,nColInic + 755,nLinha,nColInic  + 755)
oPrint:Line(nLinInBox,nColInic + 1415,nLinha,nColInic + 1415)
oPrint:Line(nLinInBox,nColInic + 1745,nLinha,nColInic + 1745)
oPrint:Line(nLinInBox,nColInic + 2075,nLinha,nColInic + 2075)
oPrint:Line(nLinInBox,nColInic + 2405,nLinha,nColInic + 2405)
oPrint:Line(nLinInBox,nColInic + 2735,nLinha,nColInic + 2735)
oPrint:Line(nLinInBox,nColInic + 3250,nLinha,nColInic + 3250)

oPrint:Box(nLinInBox,nColInic,nLinha,nColInic + 1085) 		//Box Faturamento
oPrint:Box(nLinInBox,nColInic + 1095,nLinha,nColInic + 2985)  //Box Descontos 
oPrint:Box(nLinInBox,nColInic + 2995,nLinha,nColFinal) 		//Box Totalizador Descontos

Return 

/*
===============================================================================================================================
Programa--------: RFIN007QP
Autor-----------: Fabiano Dias
Data da Criacao-: 22/03/2010
Descrição-------: Funcao criada para quebra de página e impressão do cabeçalho da página.
Parametros------: nLinhas
                  impBox   
Retorno---------: Nenhum
===============================================================================================================================
*/                                      
Static Function RFIN007QP(nLinhas,impBox)   

	//Quebra de pagina
	If nLinha > nqbrPagina
				
		nlinha:= nlinha - (nSaltoLinha * nLinhas)
		
		If impBox == 0
			If MV_PAR09 == 2
		   		RFIN007BD()	
		   			Else
		   				RFIN007B2()
			EndIf  
		EndIf	 
		
		oPrint:EndPage()					// Finaliza a Pagina.
		oPrint:StartPage()					//Inicia uma nova Pagina					
		nPagina++
		RFIN007C(1)//Chama cabecalho    
		nlinha+=nSaltoLinha                   
		nlinha+=nSaltoLinha   
		If MV_PAR09 == 2
			RFIN007CD()       
				Else  
					RFIN007CE()
		EndIf	
		nlinha+=nSaltoLinha
		
	EndIf  
	
Return

/*
===============================================================================================================================
Programa--------: RFIN007DR()
Autor-----------: Fabiano Dias
Data da Criacao-: 22/03/2010
Descrição-------: Funcao criada para gerar os dados do relatório.
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function RFIN007DR()

Local oAlias:= GetNextAlias() 

Local nTotFatur := 0 
Local nTotReceb := 0 
Local nTotDevol := 0 
Local nTotDesCo := 0 
Local nTotDesOu := 0 
Local nSldAbert := 0 
Local nTotfalMer:= 0
Local nTotAtrEnt:= 0
Local nTotDifPre:= 0
Local nTotDifPes:= 0
Local x			:= 0
Local cFiltro   := "%"
Local cFilBaixa := "%"

Local nPosGrpVen:= 0
Local _aGrpVenda:= {} 

//Filtros                                    

//FILIAL
If !Empty(AllTrim(MV_PAR01))	             

	If !Empty(xFilial("SE1"))
		cFiltro  += " AND E1.E1_FILIAL IN "   + FormatIn(MV_PAR01,";")
	EndIf	                         
	If !Empty(xFilial("ACY"))
		cFiltro  += " AND CY.ACY_FILIAL IN "  + FormatIn(MV_PAR01,";")
	EndIf
	If !Empty(xFilial("SE5"))
		cFilBaixa+= " AND E5.E5_FILIAL IN "   + FormatIn(MV_PAR01,";")
	EndIf
	
EndIf   

//DATA DE EMISSAO
If !Empty(MV_PAR02) .And. !Empty(MV_PAR03)
	cFiltro += " AND E1.E1_EMISSAO BETWEEN '" + DToS(MV_PAR02) + "' AND '" + DToS(MV_PAR03) + "'"
EndIf            
              
       
//DO CLIENTE AO CLIENTE
cFiltro   += " AND E1.E1_CLIENTE BETWEEN '" + MV_PAR04 + "' AND '" + MV_PAR06 + "'"
cFilBaixa += " AND E5.E5_CLIENTE BETWEEN '" + MV_PAR04 + "' AND '" + MV_PAR06 + "'"

//DA LOJA A LOJA DO CLIENTE
cFiltro   += " AND E1.E1_LOJA BETWEEN '" + MV_PAR05 + "' AND '" + MV_PAR07 + "'"
cFilBaixa += " AND E5.E5_LOJA BETWEEN '" + MV_PAR05 + "' AND '" + MV_PAR07 + "'"

//REDE
If !Empty(MV_PAR08)  

	cFiltro   += " AND E1.E1_I_GPRVE IN "   + FormatIn(MV_PAR08,";")

EndIf

cFiltro   += "%"  
cFilBaixa += "%"  
                
//Relatorio Sintetico
If MV_PAR09 == 2

		BeginSql alias oAlias   	   	
	   	
			SELECT 
			  E1.E1_FILIAL,
			  E1.E1_NUM,
			  E1.E1_PARCELA,
			  E1.E1_CLIENTE,
			  E1.E1_LOJA,
			  E1.E1_I_GPRVE,
			  CY.ACY_DESCRI,
			  E1.E1_VALOR faturado,
			  E1.E1_SALDO saldo,
			  (
			  SELECT 
			  COALESCE(SUM(E5.E5_VALOR),0)
			  FROM SE5010 E5
			  WHERE 
			  E1.E1_FILIAL        = E5.E5_FILIAL    
	          AND E1.E1_PREFIXO   = E5.E5_PREFIXO
     	      AND E1.E1_TIPO      = E5.E5_TIPO
			  AND E1.E1_NUM       = E5.E5_NUMERO
			  AND E1.E1_PARCELA   = E5.E5_PARCELA
			  AND E1.E1_CLIENTE   = E5.E5_CLIENTE
			  AND E1.E1_LOJA      = E5.E5_LOJA
			  AND E5.D_E_L_E_T_   = ' '
			  AND E5.E5_TIPO IN ('NF ','ICM')     
			  //AND E5_TIPODOC IN ('VL','DC')   
			  AND E5_TIPODOC NOT IN ('ES','DC','JR')   
			  AND E5_SITUACA <> 'C'
			  AND E5.E5_MOTBX     IN ('NOR','DAC')
			  AND E5.E5_RECPAG    = 'R'
			  %exp:cFilBaixa%
			  ) AS recebido,
			  (
			  SELECT
			  COALESCE(SUM(E5.E5_VALOR),0)
			  FROM SE5010 E5
			  WHERE 
			  E1.E1_FILIAL        = E5.E5_FILIAL   
			  AND E1.E1_PREFIXO   = E5.E5_PREFIXO
     	      AND E1.E1_TIPO      = E5.E5_TIPO
			  AND E1.E1_NUM       = E5.E5_NUMERO
			  AND E1.E1_PARCELA   = E5.E5_PARCELA
			  AND E1.E1_CLIENTE   = E5.E5_CLIENTE
			  AND E1.E1_LOJA      = E5.E5_LOJA
			  AND E5.D_E_L_E_T_   = ' '
			  AND E5.E5_TIPO IN ('NF ','ICM')   
			  AND E5_TIPODOC <> 'ES'   
			  AND E5_SITUACA <> 'C'
			  AND E5.E5_MOTBX     = 'CMP'
			  AND E5.E5_RECPAG    = 'R'
			  %exp:cFilBaixa%
			  ) -  
			  (
			  SELECT
			  COALESCE(SUM(E5.E5_VALOR),0)
			  FROM SE5010 E5
			  WHERE 
			  E1.E1_FILIAL        = E5.E5_FILIAL   
			  AND E1.E1_PREFIXO   = E5.E5_PREFIXO
     	      AND E1.E1_TIPO      = E5.E5_TIPO
			  AND E1.E1_NUM       = E5.E5_NUMERO
			  AND E1.E1_PARCELA   = E5.E5_PARCELA
			  AND E1.E1_CLIENTE   = E5.E5_CLIENTE
			  AND E1.E1_LOJA      = E5.E5_LOJA
			  AND E5.D_E_L_E_T_   = ' '
			  AND E5.E5_TIPO IN ('NF ','ICM')   
			  AND E5_TIPODOC = 'ES'   
			  AND E5_SITUACA <> 'C'
			  AND E5.E5_MOTBX     = 'CMP'
			  AND E5.E5_RECPAG    = 'P'
			  %exp:cFilBaixa%
			  )
			  AS devolvido,
			  (
			  SELECT
			  COALESCE(SUM(E5.E5_VALOR),0)
			  FROM SE5010 E5
			  WHERE 
			  E1.E1_FILIAL        = E5.E5_FILIAL
			  AND E1.E1_PREFIXO   = E5.E5_PREFIXO
     	      AND E1.E1_TIPO      = E5.E5_TIPO
			  AND E1.E1_NUM       = E5.E5_NUMERO
			  AND E1.E1_PARCELA   = E5.E5_PARCELA
			  AND E1.E1_CLIENTE   = E5.E5_CLIENTE
			  AND E1.E1_LOJA      = E5.E5_LOJA
			  AND E5.D_E_L_E_T_   = ' '
			  AND E5.E5_TIPO IN ('NF ','ICM')
			  AND E5_TIPODOC <> 'ES'
			  AND E5_SITUACA <> 'C'
			  AND E5.E5_MOTBX    IN ('DCT','VBC')
			  AND E5.E5_NATUREZ  IN ('231002','231017','231019')
			  AND E5.E5_RECPAG    = 'R'
			  %exp:cFilBaixa%
			  ) AS desccontr,
			  (
			  SELECT
			  COALESCE(SUM(E5.E5_VALOR),0)
			  FROM SE5010 E5
			  WHERE 
			  E1.E1_FILIAL        = E5.E5_FILIAL
              AND E1.E1_PREFIXO   = E5.E5_PREFIXO
     	      AND E1.E1_TIPO      = E5.E5_TIPO
			  AND E1.E1_NUM       = E5.E5_NUMERO
			  AND E1.E1_PARCELA   = E5.E5_PARCELA
			  AND E1.E1_CLIENTE   = E5.E5_CLIENTE
			  AND E1.E1_LOJA      = E5.E5_LOJA
			  AND E5.D_E_L_E_T_   = ' ' 
			  AND E5_SITUACA <> 'C'
			  AND ((E5.E5_TIPO IN ('NF ','ICM')
			  AND E5_TIPODOC <> 'ES'
			  AND E5.E5_MOTBX    IN ('DCT','VBC')
			  AND E5.E5_NATUREZ  IN ('231013','231014','231015','231016','233004','111001')
			  AND E5.E5_RECPAG    = 'R') 
			  OR(E5_TIPODOC = 'DC')) 
			  %exp:cFilBaixa%
			  ) AS outros 
			FROM 
			SE1010 E1  
			JOIN ACY010 CY ON CY.ACY_GRPVEN = E1.E1_I_GPRVE
			WHERE 
			E1.D_E_L_E_T_ = ' '
			AND CY.D_E_L_E_T_ = ' '
			AND E1.E1_TIPO IN ('NF ','ICM') 	   		
			%exp:cFiltro%
	   	
		EndSql    	   
    
	//Faz o Grupamento por Rede dos dados 
	DBSelectArea(oAlias)	      
    (oAlias)->(DBGoTop())             
    
    ProcRegua((oAlias)->(RecCount()))  
    
    While (oAlias)->(!Eof())
    
    	IncProc("Grupando os títulos por Rede, favor aguardar...")
     
     	 nPosGrpVen := aScan(_aGrpVenda,{|x| x[1] == (oAlias)->E1_I_GPRVE })    
     	        
     	 //Caso ja exista a rede
     	 If nPosGrpVen > 0   
     	 
     	 	_aGrpVenda[nPosGrpVen,3] += (oAlias)->faturado
     	 	_aGrpVenda[nPosGrpVen,4] += (oAlias)->saldo 
     	 	_aGrpVenda[nPosGrpVen,5] += (oAlias)->recebido
     	 	_aGrpVenda[nPosGrpVen,6] += (oAlias)->devolvido
     	 	_aGrpVenda[nPosGrpVen,7] += (oAlias)->desccontr
     	 	_aGrpVenda[nPosGrpVen,8] += (oAlias)->outros
     	 
     	 	Else   
     	 	
     	 		aAdd(_aGrpVenda,{(oAlias)->E1_I_GPRVE,(oAlias)->ACY_DESCRI,(oAlias)->faturado,(oAlias)->saldo,;
     	 		(oAlias)->recebido,(oAlias)->devolvido,(oAlias)->desccontr,(oAlias)->outros})  
     	 
     	 EndIf                
    
    (oAlias)->(DBSkip())
    EndDo
    
	DBSelectArea(oAlias)	      
    (oAlias)->(DBCloseArea()) 

If Len(_aGrpVenda) > 0  

	_aGrpVenda:=aSort(_aGrpVenda,,,{|x, y| x[2] < y[2]})		// Ordenar os dados por descricao da rede   

	oPrint:StartPage()					//Inicia uma nova Pagina
	RFIN007C(1) 
	nlinha+=nSaltoLinha                   
	nlinha+=nSaltoLinha   
	RFIN007CD()                          
		
	ProcRegua(Len(_aGrpVenda)) 		
		
	For x:=1 to Len(_aGrpVenda)	

		IncProc("Os dados estão sendo processados, favor aguardar...") 
		 
		nlinha+=nSaltoLinha
		RFIN007QP(0,0)  
		           
		RFIN007PD(_aGrpVenda[x,2],_aGrpVenda[x,3],_aGrpVenda[x,5],;
		           _aGrpVenda[x,6],_aGrpVenda[x,7],_aGrpVenda[x,8],_aGrpVenda[x,4])                
		
		//Imprime Linhas
		oPrint:Line(nLinha,nColInic       ,nLinha,nColInic + 1745)
		//oPrint:Line(nLinha,nColInic + 1755,nLinha,nColInic + 2735)
		oPrint:Line(nLinha,nColInic + 1920,nLinha,nColInic + 2570)
		oPrint:Line(nLinha,nColInic + 2745,nLinha,nColFinal      )  
		
		//Efetua o somatorio Geral
		nTotFatur+= _aGrpVenda[x,3]
		nSldAbert+= _aGrpVenda[x,4]
		nTotReceb+= _aGrpVenda[x,5]
		nTotDevol+= _aGrpVenda[x,6]
		nTotDesCo+= _aGrpVenda[x,7]
		nTotDesOu+= _aGrpVenda[x,8]
          
    
    Next x              
    
//Fecha Box da ultima pagina 
nlinha+=nSaltoLinha
RFIN007BD()    

//Imprime o totalizador Geral do Relatorio
nlinha+=nSaltoLinha
nlinha+=nSaltoLinha
RFIN007QP(0,1)       
RFIN007PT('TOTAL GERAL',nTotFatur,nTotReceb,nTotDevol,nTotDesCo,nTotDesOu,nSldAbert) 

EndIf
    
    //Relatorio Analitico
	Else
	                                    
		BeginSql alias oAlias   	   	
			SELECT 
			  E1.E1_FILIAL,
			  E1.E1_NUM,
			  E1.E1_PARCELA,
			  E1.E1_CLIENTE,
			  E1.E1_LOJA,
			  E1.E1_I_GPRVE,
			  CY.ACY_DESCRI,
			  E1.E1_VALOR faturado,
			  E1.E1_SALDO saldo,
			  (
			  SELECT
			  COALESCE(SUM(E5.E5_VALOR),0)
			  FROM SE5010 E5
			  WHERE 
			  E1.E1_FILIAL        = E5.E5_FILIAL
			  AND E1.E1_PREFIXO   = E5.E5_PREFIXO
     	      AND E1.E1_TIPO      = E5.E5_TIPO
			  AND E1.E1_NUM       = E5.E5_NUMERO
			  AND E1.E1_PARCELA   = E5.E5_PARCELA
			  AND E1.E1_CLIENTE   = E5.E5_CLIENTE
			  AND E1.E1_LOJA      = E5.E5_LOJA
			  AND E5.D_E_L_E_T_   = ' '
			  AND E5.E5_TIPO IN ('NF ','ICM')
			  AND E5_TIPODOC <> 'ES'
			  AND E5_SITUACA <> 'C'
			  AND E5.E5_MOTBX    IN ('DCT','VBC')
			  AND E5.E5_NATUREZ  IN ('231002','231017','231019')
			  AND E5.E5_RECPAG    = 'R'
			  %exp:cFilBaixa%
			  ) AS desccontr,
			  (
			  SELECT
			  COALESCE(SUM(E5.E5_VALOR),0)
			  FROM SE5010 E5
			  WHERE   			  
			  E1.E1_FILIAL        = E5.E5_FILIAL   
	          AND E1.E1_PREFIXO   = E5.E5_PREFIXO
     	      AND E1.E1_TIPO      = E5.E5_TIPO
              AND E1.E1_NUM       = E5.E5_NUMERO
			  AND E1.E1_PARCELA   = E5.E5_PARCELA
			  AND E1.E1_CLIENTE   = E5.E5_CLIENTE
			  AND E1.E1_LOJA      = E5.E5_LOJA  			  
			  AND E5.D_E_L_E_T_   = ' '   
			  AND E5_SITUACA <> 'C'      
			  AND E5_TIPODOC <> 'ES'
			  AND E5.E5_TIPO      IN ('NF ','ICM')        			  
			  AND E5.E5_MOTBX     IN ('DCT','VBC')
			  AND E5.E5_NATUREZ   = '231013'
			  AND E5.E5_RECPAG    = 'R' 
			  %exp:cFilBaixa%
			  ) faltMerc,
			  (
			  SELECT 
			  COALESCE(SUM(E5.E5_VALOR),0)
			  FROM SE5010 E5
			  WHERE 			  			  
			  E1.E1_FILIAL        = E5.E5_FILIAL   
	          AND E1.E1_PREFIXO   = E5.E5_PREFIXO
     	      AND E1.E1_TIPO      = E5.E5_TIPO
              AND E1.E1_NUM       = E5.E5_NUMERO
			  AND E1.E1_PARCELA   = E5.E5_PARCELA
			  AND E1.E1_CLIENTE   = E5.E5_CLIENTE
			  AND E1.E1_LOJA      = E5.E5_LOJA    			  
			  AND E5.D_E_L_E_T_   = ' '   
			  AND E5_SITUACA <> 'C' 
			  AND E5_TIPODOC <> 'ES'
			  AND E5.E5_TIPO      IN ('NF ','ICM')
			  AND E5.E5_MOTBX     IN ('DCT','VBC')
			  AND E5.E5_NATUREZ   = '231014'
			  AND E5.E5_RECPAG    = 'R' 
			  %exp:cFilBaixa%
			  ) atrasoEntr,
			  (
			  SELECT
			  COALESCE(SUM(E5.E5_VALOR),0)
			  FROM SE5010 E5
			  WHERE   			  
			  E1.E1_FILIAL        = E5.E5_FILIAL   
	          AND E1.E1_PREFIXO   = E5.E5_PREFIXO
     	      AND E1.E1_TIPO      = E5.E5_TIPO
              AND E1.E1_NUM       = E5.E5_NUMERO
			  AND E1.E1_PARCELA   = E5.E5_PARCELA
			  AND E1.E1_CLIENTE   = E5.E5_CLIENTE
			  AND E1.E1_LOJA      = E5.E5_LOJA     			  
			  AND E5.D_E_L_E_T_   = ' '   
			  AND E5_SITUACA <> 'C' 
			  AND E5_TIPODOC <> 'ES'
			  AND E5.E5_TIPO      IN ('NF ','ICM') 
			  AND E5.E5_MOTBX     IN ('DCT','VBC')
			  AND E5.E5_NATUREZ   = '231015'
			  AND E5.E5_RECPAG    = 'R' 
			  %exp:cFilBaixa%
			  ) diferPreco,
			  (
			  SELECT
			  COALESCE(SUM(E5.E5_VALOR),0)
			  FROM SE5010 E5
			  WHERE 		    			  
			  E1.E1_FILIAL        = E5.E5_FILIAL   
	          AND E1.E1_PREFIXO   = E5.E5_PREFIXO
     	      AND E1.E1_TIPO      = E5.E5_TIPO
              AND E1.E1_NUM       = E5.E5_NUMERO
			  AND E1.E1_PARCELA   = E5.E5_PARCELA
			  AND E1.E1_CLIENTE   = E5.E5_CLIENTE
			  AND E1.E1_LOJA      = E5.E5_LOJA   			  
			  AND E5.D_E_L_E_T_   = ' '
			  AND E5_SITUACA <> 'C' 
			  AND E5_TIPODOC <> 'ES'
			  AND E5.E5_TIPO      IN ('NF ','ICM') 
			  AND E5.E5_MOTBX     IN ('DCT','VBC')
			  AND E5.E5_NATUREZ   = '231016'
			  AND E5.E5_RECPAG    = 'R' 
			  %exp:cFilBaixa%
			  ) diferPesag,
			  (
			  SELECT
			  COALESCE(SUM(E5.E5_VALOR),0)
			  FROM SE5010 E5
			  WHERE 				  
			  E1.E1_FILIAL        = E5.E5_FILIAL   
	          AND E1.E1_PREFIXO   = E5.E5_PREFIXO
     	      AND E1.E1_TIPO      = E5.E5_TIPO
              AND E1.E1_NUM       = E5.E5_NUMERO
			  AND E1.E1_PARCELA   = E5.E5_PARCELA
			  AND E1.E1_CLIENTE   = E5.E5_CLIENTE
			  AND E1.E1_LOJA      = E5.E5_LOJA    			                                  
			  AND E5.D_E_L_E_T_   = ' '   
			  AND E5_SITUACA <> 'C' 
			  AND ((E5_TIPODOC <> 'ES'
			  AND E5.E5_TIPO      = 'NF ' 
			  AND E5.E5_MOTBX     IN ('DCT','VBC')
			  AND E5.E5_NATUREZ   IN ('233004','111001')
			  AND E5.E5_RECPAG    = 'R')
			  OR(E5_TIPODOC = 'DC')) 
			  %exp:cFilBaixa%
			  ) outros
			FROM SE1010 E1  
			JOIN ACY010 CY ON CY.ACY_GRPVEN = E1.E1_I_GPRVE
			WHERE 
			E1.D_E_L_E_T_ = ' '
			AND CY.D_E_L_E_T_   = ' '
			AND E1.E1_TIPO IN ('NF ','ICM') 	 			
			%exp:cFiltro%
			
		EndSql    	   
	
	//Faz o Grupamento por Rede dos dados 
	DBSelectArea(oAlias)	      
    (oAlias)->(DBGoTop())       
    
    ProcRegua((oAlias)->(RecCount()))        
    
    While (oAlias)->(!Eof())
    
    	IncProc("Grupando os títulos por Rede, favor aguardar...")
     
     	 nPosGrpVen := aScan(_aGrpVenda,{|x| x[1] == (oAlias)->E1_I_GPRVE })    
     	        
     	 //Caso ja exista a rede
     	 If nPosGrpVen > 0   
     	 
     	 	_aGrpVenda[nPosGrpVen,3]  += (oAlias)->faturado
     	 	_aGrpVenda[nPosGrpVen,4]  += (oAlias)->saldo 
     	 	_aGrpVenda[nPosGrpVen,5]  += (oAlias)->desccontr
     	 	_aGrpVenda[nPosGrpVen,6]  += (oAlias)->faltMerc
     	 	_aGrpVenda[nPosGrpVen,7]  += (oAlias)->atrasoEntr
     	 	_aGrpVenda[nPosGrpVen,8]  += (oAlias)->diferPreco
     	 	_aGrpVenda[nPosGrpVen,9]  += (oAlias)->diferPesag 
     	 	_aGrpVenda[nPosGrpVen,10] += (oAlias)->outros
     	 
     	 	Else   
     	 	
     	 		aAdd(_aGrpVenda,{(oAlias)->E1_I_GPRVE,(oAlias)->ACY_DESCRI,(oAlias)->faturado,(oAlias)->saldo,(oAlias)->desccontr,;
     	 		(oAlias)->faltMerc,(oAlias)->atrasoEntr,(oAlias)->diferPreco,(oAlias)->diferPesag,(oAlias)->outros })  
     	 
     	 EndIf                
    
    (oAlias)->(DBSkip())
    EndDo             

	DBSelectArea(oAlias)	      
    (oAlias)->(DBCloseArea()) 

If Len(_aGrpVenda)   > 0          

	_aGrpVenda:=aSort(_aGrpVenda,,,{|x, y| x[2] < y[2]})		// Ordenar os dados por descricao da rede

	oPrint:StartPage()					//Inicia uma nova Pagina
	RFIN007C(1) 
	nlinha+=nSaltoLinha                   
	nlinha+=nSaltoLinha   
	RFIN007CE()                          		
		
	For x:=1 To Len(_aGrpVenda) 	

		IncProc("Os dados estão sendo processados, favor aguardar...") 
		 
		nlinha+=nSaltoLinha
		RFIN007QP(0,0)
		                        
		
		RFIN007PA(_aGrpVenda[x,2],_aGrpVenda[x,3],_aGrpVenda[x,5],_aGrpVenda[x,6],_aGrpVenda[x,7],;
		           _aGrpVenda[x,8],_aGrpVenda[x,9],_aGrpVenda[x,10],_aGrpVenda[x,4])                    
		
		//Imprime Linhas
		oPrint:Line(nLinha,nColInic       ,nLinha,nColInic + 1085)
		oPrint:Line(nLinha,nColInic + 1095,nLinha,nColInic + 2985)
		oPrint:Line(nLinha,nColInic + 2995,nLinha,nColFinal      )
		
		//Efetua o somatorio Geral
		nTotFatur += _aGrpVenda[x,3]      
		nSldAbert += _aGrpVenda[x,4]
		nTotDesCo += _aGrpVenda[x,5]
		nTotfalMer+= _aGrpVenda[x,6]            
		nTotAtrEnt+= _aGrpVenda[x,7]
		nTotDifPre+= _aGrpVenda[x,8]
		nTotDifPes+= _aGrpVenda[x,9] 
		nTotDesOu += _aGrpVenda[x,10]
          
    
    Next x              
    
//Fecha Box da ultima pagina 
nlinha+=nSaltoLinha
RFIN007B2()    

//Imprime o totalizador Geral do Relatorio
nlinha+=nSaltoLinha
nlinha+=nSaltoLinha
RFIN007QP(0,1)       
RFIN007PN('TOTAL GERAL',nTotFatur,nTotDesCo,nTotfalMer,nTotAtrEnt,nTotDifPre,nTotDifPes,nTotDesOu,nSldAbert) 		

EndIf

EndIf

Return
