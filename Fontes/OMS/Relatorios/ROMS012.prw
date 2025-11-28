/*
===============================================================================================================================
               ULTIMAS ATUALIZACOES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
       Autor      |    Data    |                                             Motivo                                           
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  	  | 17/10/2019 | Removidos os Warning na compilação da release 12.1.25. Chamado 28346
===============================================================================================================================
*/
//====================================================================================================
// Definicoes de Includes e Defines da Rotina.
//====================================================================================================
#Include "TOTVS.ch"
#Include "rwmake.ch"
#Include "topconn.ch"      

/*
===============================================================================================================================
Programa--------: ROMS012
Autor-----------: Fabiano Dias
Data da Criacao-: 13/01/2010
===============================================================================================================================
Descricao-------: Imprime os dados do contrato de desconto contratual
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function ROMS012()
                            
Private cPerg  := "ROMS012"  

Private oFont12
Private oFont12b  
Private oFont16b           
Private oFont14
Private oFont14b

Private oPrint

Private nPagina     := 1

Private nLinha      := 0100
Private nColInic    := 0030
Private nColFinal   := 3360  
Private nLinInBox   
Private nSaltoLinha := 50      

Private contrCor    := 1
Private oBrush      := TBrush():New( ,CLR_LIGHTGRAY)
 
Define Font oFont12    Name "Courier New"       Size 0,-10 Bold  // Tamanho 12
Define Font oFont12b   Name "Courier New"       Size 0,-10 Bold  // Tamanho 12 Negrito  
Define Font oFont14    Name "Courier New"       Size 0,-12       // Tamanho 14
Define Font oFont14b   Name "Courier New"       Size 0,-12 Bold  // Tamanho 14 Negrito  
Define Font oFont16b   Name "Courier New"       Size 0,-14 Bold  // Tamanho 16 Negrito 

oPrint:= TMSPrinter():New("DESCONTO CONTRATUAL")
oPrint:SetLandscape() 	// Paisagem
oPrint:SetPaperSize(9)	// Seta para papel A4 

nLinha:=0100       
		
Processa({|| relDadosCon() })			

oPrint:EndPage()	// Finaliza a Pagina.
oPrint:Preview()	// Visualiza antes de Imprimir.

Return

/*
===============================================================================================================================
Programa--------: Cabecalho
Autor-----------: Fabiano Dias
Data da Criacao-: 13/01/2010
===============================================================================================================================
Descricao-------: Imprime os dados do contrato de desconto contratual
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function Cabecalho(codVendedo,descVende,codSuperv,descSuperv)

Local cRaizServer := If(issrvunix(), "/", "\")    
Local nColuna     := 0
Local cTitulo     := ""
Local cRede		  := ""
Local cCliente    := ""

nLinha:=0100

	oPrint:SayBitmap(nLinha,nColInic,cRaizServer + "system/lgrl01.bmp",250,100)        
	oPrint:Say (nlinha,nColInic + 2500,"PÁGINA: " + Str(nPagina,2),oFont12)
	oPrint:Say (nlinha + 50,nColInic + 2500,"DATA DE EMISSÃO: " + DToC(DATE()),oFont12)
	If nPagina == 1   
		oPrint:Say (nlinha - 50 ,nColInic + 2500,"FONTE: ROMS012",oFont12)
		oPrint:Say (nlinha + 100,nColInic + 2500,"EMPRESA: " + AllTrim(SM0->M0_NOME) + '/'+ AllTrim(SM0->M0_FILIAL),oFont12)
	EndIf
	nlinha+=(nSaltoLinha * 3) 
	
	oPrint:Line(nLinha,nColInic,nLinha,nColFinal)    
	
	nlinha+=nSaltoLinha - 30
	          
	cTitulo:="ACORDO COMERCIAL"
	//Calculo para que o nome fica alinhado no centro coluna INSS   
	//O valor 29.10 eh o valor que cada caractere ocupa
	nColuna:=nColInic + Int(((nColFinal-nColInic) - (Len(cTitulo)* 29.10))/2)
	                      
	oPrint:Say (nlinha,nColuna,cTitulo,oFont16b)
	nlinha+=nSaltoLinha
	nlinha+=nSaltoLinha 
	
	oPrint:Say (nlinha,nColInic,"Contrato:",oFont14)
	oPrint:Say (nlinha,0300,ZAZ->ZAZ_COD,oFont14b)
	nlinha+=nSaltoLinha
	                                
	cRede:=AllTrim(ZAZ->ZAZ_GRPVEN) + '-' + AllTrim(Posicione("ACY",1,xFilial("ACY") + ZAZ->ZAZ_GRPVEN,"ACY->ACY_DESCRI"))
	oPrint:Say (nlinha,nColInic,"Rede....:",oFont14)
	oPrint:Say (nlinha,0300,IIf(Len(cRede) > 1,cRede," "),oFont14b)
	
	nlinha+=nSaltoLinha                                         
	If Len(AllTrim(ZAZ->ZAZ_LOJA)) > 1
		cCliente:=AllTrim(ZAZ->ZAZ_CLIENT) + '/' + AllTrim(ZAZ->ZAZ_LOJA) + '-' + AllTrim(Posicione("SA1",1,xFilial("SA1") + ZAZ->ZAZ_CLIENT + ZAZ->ZAZ_LOJA,"A1_NOME")) + '-' + AllTrim(Posicione("SA1",1,xFilial("SA1") + ZAZ->ZAZ_CLIENT + ZAZ->ZAZ_LOJA,"A1_NREDUZ"))
		Else
			cCliente:=AllTrim(ZAZ->ZAZ_CLIENT) + '-' + AllTrim(Posicione("SA1",1,xFilial("SA1") + ZAZ->ZAZ_CLIENT,"A1_NOME"))
	EndIf
	oPrint:Say (nlinha,nColInic,"Cliente.:",oFont14)
	oPrint:Say (nlinha,0300,IIf(Len(cCliente) > 2,cCliente," "),oFont14b)
	
	nlinha+=nSaltoLinha 
	oPrint:Say (nlinha,nColInic,"Vigência:",oFont14)
	oPrint:Say (nlinha,0300,DToC(ZAZ->ZAZ_DTINI) +' À ' + DToC(ZAZ->ZAZ_DTFIM),oFont14b)
		
	nlinha+=nSaltoLinha 
	nlinha+=nSaltoLinha        
	
	nLinInBox:=nlinha
	
	oPrint:Say (nlinha,nColInic,"Item",oFont12b)
	oPrint:Say (nlinha,nColInic + 0120,"Produto",oFont12b)
	oPrint:Say (nlinha,nColInic + 1275,"% Desconto",oFont12b)
	oPrint:Say (nlinha,nColInic + 1500,"Contrato",oFont12b)
	oPrint:Say (nlinha,nColInic + 1771,"Cliente/Loja",oFont12b)
	oPrint:Say (nlinha,nColInic + 2046,"Razão Social",oFont12b)
	oPrint:Say (nlinha,nColInic + 3150,"Estado",oFont12b)
	
	nlinha+=nSaltoLinha 
	oPrint:Line(nLinha,nColInic,nLinha,nColFinal)

Return

/*
===============================================================================================================================
Programa--------: relDadosCon
Autor-----------: Fabiano Dias
Data da Criacao-: 13/01/2010
===============================================================================================================================
Descricao-------: Imprime os dados do contrato de desconto contratual
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function relDadosCon()                 

Local cRaizServer := If(issrvunix(), "/", "\")
Local cCodContr   := ZAZ->ZAZ_COD
Local nCountRec   := 0          
Local cCliLoja    := ""
Local cCliRazSoc  := ""

cQuery := "SELECT"
cQuery += " * "                                                  
cQuery += "FROM "                              
cQuery += RetSqlName("ZB0") + " "         
cQuery += "WHERE"               
cQuery += " D_E_L_E_T_ = ' ' "
cQuery += " AND ZB0_FILIAL = '" + xFilial("ZB0") + "'"          
cQuery += " AND ZB0_COD = '" + cCodContr + "' "    
cQuery += "ORDER BY ZB0_ITEM"

//Para que nao ocorra erro, quando duas pessoas acessarem o relatorio simultaneamente
If Select("TMPCONT") > 0 
 	TMPCONT->(DBCloseArea())
 EndIf                   
    
dbUseArea(.T.,"TOPCONN",TCGenQry(,,AllTrim(Upper(cQuery))),'TMPCONT',.F.,.T.)   
COUNT TO nCountRec
	
TMPCONT->(DBGoTop())     
	
ProcRegua(nCountRec)
	
If nCountRec > 0      
                        
	//Imprime cabecalho
	Cabecalho()        

	While TMPCONT->(!Eof())  
	
		IncProc("Processando Contrato: " + TMPCONT->ZB0_COD)            
	
		//Quebra de pagina
		If nLinha > 2345
				 
				boxDiviso()							//Desenha box e divisorias dos itens 
				oPrint:EndPage()					// Finaliza a Pagina.
				oPrint:StartPage()					//Inicia uma nova Pagina					
				nPagina++
				cabecalho()//Chama cabecalho  

				contrCor:=1			
		EndIf   
		
		//Zebra o relatorio
		contrCor++ 
		If contrCor % 2 == 0
		    
			oPrint:FillRect({(nlinha+3),nColInic,nlinha + nSaltoLinha,nColFinal},oBrush)
		    
		EndIf
		
		oPrint:Say (nlinha,nColInic + 25  ,TMPCONT->ZB0_ITEM,oFont12b)
		oPrint:Say (nlinha,nColInic + 0120,SubStr(AllTrim(TMPCONT->ZB0_SB1COD) + '-' + AllTrim(Posicione("SB1",1,xFilial("SB1") + TMPCONT->ZB0_SB1COD,"SB1->B1_I_DESCD")),1,52),oFont12b)
		oPrint:Say (nlinha,nColInic + 1355,Transform(TMPCONT->ZB0_DESCTO,"@R 99.99") + "%",oFont12b)
		oPrint:Say (nlinha,nColInic + 1500,SubStr(AllTrim(TMPCONT->ZB0_CONTR),1,12),oFont12b)
		cCliLoja  := TMPCONT->ZB0_CLIENT + '/' + TMPCONT->ZB0_LOJA
		oPrint:Say (nlinha,nColInic + 1771,IIf(Len(AllTrim(cCliLoja)) > 1,cCliLoja," "),oFont12b)
		
		If Len(AllTrim(TMPCONT->ZB0_LOJA)) > 1
			cCliRazSoc:= SubStr(AllTrim(Posicione("SA1",1,xFilial("SA1") + TMPCONT->ZB0_CLIENT + TMPCONT->ZB0_LOJA,"A1_NOME")),1,30) + '-'+ SubStr(AllTrim(Posicione("SA1",1,xFilial("SA1") + TMPCONT->ZB0_CLIENT + TMPCONT->ZB0_LOJA,"A1_NREDUZ")),1,18)  
				Else
				cCliRazSoc:= SubStr(AllTrim(Posicione("SA1",1,xFilial("SA1") + TMPCONT->ZB0_CLIENT,"A1_NOME")),1,30)
		EndIf	
		
		oPrint:Say (nlinha,nColInic + 2046,IIf(Len(AllTrim(cCliRazSoc)) > 1,cCliRazSoc," "),oFont12b)
		oPrint:Say (nlinha,nColInic + 3200,TMPCONT->ZB0_EST,oFont12b)

		nlinha+=nSaltoLinha
		oPrint:Line(nLinha,nColInic,nLinha,nColFinal)
         
	TMPCONT->(DBSkip())
	EndDo    

EndIf  
							
		//Desenha box e divisorias dos itens 
		boxDiviso()
		
		//Quebra de Pagina antes de imprimir a assintarura
		If (nLinha + (nSaltoLinha * 5)) > 2345
				 
			oPrint:EndPage()					// Finaliza a Pagina.
			oPrint:StartPage()					//Inicia uma nova Pagina					
			nPagina++
			nLinha:=0100 
						
			oPrint:SayBitmap(nLinha,nColInic,cRaizServer + "system/lgrl01.bmp",250,100)   
			oPrint:Say (nlinha,nColInic + 2700,"PÁGINA: " + Str(nPagina,2),oFont12)
			oPrint:Say (nlinha + 50,nColInic + 2700,"DATA DE EMISSÃO: " + DToC(DATE()),oFont12)
			nlinha+=(nSaltoLinha * 3) 
			oPrint:Line(nLinha,nColInic,nLinha,nColFinal)    
						
			nLinha+= (nSaltoLinha * 5)
		
		EndIf   
		
		//Desenha assinatura do diretor comercial e do analista comercial
		desenAss()
	
TMPCONT->(DBCloseArea())

Return

/*
===============================================================================================================================
Programa--------: boxDiviso
Autor-----------: Fabiano Dias
Data da Criacao-: 13/01/2010
===============================================================================================================================
Descricao-------: Imprime os dados do contrato de desconto contratual
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function boxDiviso()
        
        //Imprime box e divisorias para a ultima pagina do relatorio
		oPrint:Box(nLinInBox,nColInic,nLinha,nColFinal)
		
		//Divisorias
		oPrint:Line(nLinInBox,0145,nLinha,0145)//PRODUTO
		oPrint:Line(nLinInBox,1300,nLinha,1300)//% DESCONTO
		oPrint:Line(nLinInBox,1525,nLinha,1525)//CONTRATO
		oPrint:Line(nLinInBox,1796,nLinha,1796)//CLIENTE/LOJA
		oPrint:Line(nLinInBox,2071,nLinha,2071)//RAZAO SOCIAL
		oPrint:Line(nLinInBox,3145,nLinha,3145)//ESTADO

Return

/*
===============================================================================================================================
Programa--------: desenAss
Autor-----------: Fabiano Dias
Data da Criacao-: 13/01/2010
===============================================================================================================================
Descricao-------: Imprime os dados do contrato de desconto contratual
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function desenAss()

	    //Desenha assinatura do Diretor Comercial e do Analista Comercial
		nlinha+=(nSaltoLinha  * 5)  
		oPrint:Line(nLinha,nColInic + 0400,nLinha,nColInic + 0900 + 0400)//DIRETOR COMERCIAL
					
		cTitulo:="Diretor Comercial"
		//Calculo para que o nome fica alinhado no centro coluna INSS   
		//O valor 29.10 eh o valor que cada caractere ocupa
		nColuna:= 0430 + Int(((1330-0430) - (Len(cTitulo)* 29.10))/2)
		oPrint:Say (nlinha,nColuna,cTitulo,oFont16b)
					
		oPrint:Line(nLinha,nColInic + 0730 + 1330,nLinha,nColInic + 0900 + 0730 + 1330)//ANALISTA COMERCIAL 
		cTitulo:="Analista Comercial"
		//Calculo para que o nome fica alinhado no centro coluna INSS   
		//O valor 29.10 eh o valor que cada caractere ocupa
		nColuna:= 2090 + Int(((2990-2090) - (Len(cTitulo)* 29.10))/2)
		oPrint:Say (nlinha,nColuna,cTitulo,oFont16b)	      

Return
