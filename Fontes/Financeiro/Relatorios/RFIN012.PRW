/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Josué Prestes |16/07/2015| Mudança de função de ROMS011 para RFIN012 para concentrar no módulo financeiro
Josué Danich  |27/07/2018| Chamado 25555. Inclusão de cálculo por supervisor
Lucas Borges  |11/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25.
===============================================================================================================================
*/ 

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RFIN012
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 12/01/2010
Descrição---------: Imprime a relação de regra de comissão por vendedor.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/

User Function RFIN012()
                            
Private cPerg  := "RFIN012"  
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

If !Pergunte(cPerg,.T.)
  Return
EndIf

oPrint:= TMSPrinter():New("REGRAS DE COMISSAO")
oPrint:Setup()
oPrint:SetPaperSize(9)	// Seta para papel A4  
oPrint:SetLandscape() 	// Paisagem

nLinha:=0100       
	
//Grava log de execução
u_itlogacs()
		
Processa({|| RFIN012DAD() })			

oPrint:EndPage()	// Finaliza a Pagina.
oPrint:Preview()	// Visualiza antes de Imprimir.

Return

/*
===============================================================================================================================
Programa----------: RFIN012CAB
Autor-------------: Josué Danich Prestes
Data da Criacao---: 01/08/2018
Descrição---------: Prepara o cabeçalho do relatório para cada divisão vendedorxsupervisorxcoordenador
Parametros--------: codVendedo - código do vendedor
					descVende - nome do vendedor
					codCoord - código do coordenador
					descCoord - nome do coordenador
					codsui - código do supervisor
					descsui - nome do supervisor
Retorno-----------: Nenhum
===============================================================================================================================
*/

Static Function RFIN012CAB(codVendedo,descVende,codCoord,descCoord,codsui,descsui)

Local cRaizServer := If(issrvunix(), "/", "\")    
Local nColuna     := 0
Local cTitulo     := ""

nLinha:=0100

oPrint:SayBitmap(nLinha,nColInic,cRaizServer + "system/lgrl01.bmp",250,100)   
oPrint:Say (nlinha,nColInic + 2500,"PÁGINA: " + Str(nPagina,2),oFont12)
oPrint:Say (nlinha + 50,nColInic + 2500,"DATA DE EMISSÃO: " + DToC(DATE()),oFont12)      

If nPagina == 1                                                         
  oPrint:Say (nlinha - 50 ,nColInic + 2500,"FONTE: RFIN012",oFont12)
  oPrint:Say (nlinha + 100,nColInic + 2500,"EMPRESA: " + AllTrim(SM0->M0_NOME) + '/' + AllTrim(SM0->M0_FILIAL),oFont12) 
EndIf

nlinha+=(nSaltoLinha * 3) 
oPrint:Line(nLinha,nColInic,nLinha,nColFinal)    
nlinha+=nSaltoLinha - 30                                                
cTitulo:="TABELA DE REGRA DE COMISSÃO"

//Calculo para que o nome fica alinhado no centro coluna  
//O valor 29.10 eh o valor que cada caractere ocupa
nColuna:=nColInic + Int(((nColFinal-nColInic) - (Len(cTitulo)* 29.10))/2)
	                      
oPrint:Say (nlinha,nColuna,cTitulo,oFont16b)

nlinha+=nSaltoLinha
nlinha+=nSaltoLinha 

oPrint:Say (nlinha,nColInic,"Vendedor...:",oFont14)
oPrint:Say (nlinha,0350,codVendedo + "-" + AllTrim(Posicione("SA3",1,xFilial("SA3") + codVendedo,"A3_NOME")),oFont14b)

nlinha+=nSaltoLinha 

oPrint:Say (nlinha,nColInic,"Supervisor.:",oFont14)
oPrint:Say (nlinha,0350,codsui + "-" + AllTrim(descsui),oFont14b)

nlinha+=nSaltoLinha 

oPrint:Say (nlinha,nColInic,"Coordenador:",oFont14)
oPrint:Say (nlinha,0350,codCoord + "-" + AllTrim(descCoord),oFont14b)

nlinha+=nSaltoLinha 
nlinha+=nSaltoLinha        
nLinInBox:=nlinha

oPrint:Say (nlinha,nColInic,"Item",oFont12b)
oPrint:Say (nlinha,nColInic + 0120,"Produto",oFont12b)
oPrint:Say (nlinha,nColInic + 0728,"% Vend.",oFont12b)
oPrint:Say (nlinha,nColInic + 0940,"Rede",oFont12b)
oPrint:Say (nlinha,nColInic + 1340,"Cliente",oFont12b)
oPrint:Say (nlinha,nColInic + 1755,"Razão Social",oFont12b)
oPrint:Say (nlinha,nColInic + 2430,"% Sup.",oFont12b)
oPrint:Say (nlinha,nColInic + 2610,"% Crd.",oFont12b)
oPrint:Say (nlinha,nColInic + 2890,"Gerente",oFont12b)
oPrint:Say (nlinha,nColInic + 3185,"% Ger.",oFont12b)


nlinha+=nSaltoLinha 

oPrint:Line(nLinha,nColInic,nLinha,nColFinal)

Return

/*
===============================================================================================================================
Programa----------: RFIN012DAD
Autor-------------: Josué Danich Prestes
Data da Criacao---: 01/08/2018
Descrição---------: Prepara e imprime corpo do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/ 
Static Function RFIN012DAD()                 

Local nCountRec   := 0
Local cQuery      := ""
Local aVendedor   := {}                      
Local cRaizServer := If(issrvunix(), "/", "\")
Local cFiltro     := "" 
Local nLinFinal   
Local nLinInici
Local nLinFinRz   
Local cCodCli     := ""

//Filtros   

//Vendedor
If !Empty(MV_PAR01)
	cFiltro += " AND zae_vend IN " + FormatIn(AllTrim(MV_PAR01),";")
EndIf

//Supervisor
If !Empty(MV_PAR02)
	cFiltro += " AND zae_codsui IN " + FormatIn(AllTrim(MV_PAR02),";")
EndIf
                   
//Coordenador                             
If !Empty(MV_PAR03)
	cFiltro += " AND zae_codsup IN " + FormatIn(AllTrim(MV_PAR03),";")
EndIf

//Gerente                             
If !Empty(MV_PAR04)
	cFiltro += " AND zae_codger IN " + FormatIn(AllTrim(MV_PAR04),";")
EndIf
                                                     
cQuery := "SELECT"
cQuery += " zae_vend,zae_item,zae_prod,zae_comis1,zae_grpven,zae_cli,zae_loja,"                                                  
cQuery += " zae_codsup,zae_comis2,zae_codger,zae_comis3,zae_codsui,zae_comis4 "
cQuery += "FROM "                              
cQuery += RetSqlName("ZAE") + " "         
cQuery += "WHERE"               
cQuery += " D_E_L_E_T_ = ' ' "
cQuery += " AND ZAE_FILIAL = '" + xFilial("ZAE") + "'" 
cQuery += cFiltro
cQuery += " ORDER BY zae_vend,zae_item"
		
If Select("TMPCOMI") > 0 
  DBSelectArea("TMPCOMI")
  DBCloseArea()
EndIf                   
    
dbUseArea(.T.,"TOPCONN",TCGenQry(,,AllTrim(Upper(cQuery))),'TMPCOMI',.F.,.T.)   
COUNT TO nCountRec
	
DBSelectArea("TMPCOMI")  
TMPCOMI->(DBGoTop())     
	
ProcRegua(nCountRec)
	
If nCountRec > 0           

  While TMPCOMI->(!Eof()) 
	                            
    IncProc("Processando Vendedor: " + TMPCOMI->zae_vend)   
	nPos := aScan(aVendedor, { |x| x[1] == TMPCOMI->zae_vend })
	If nPos == 0    
		
	  If Len(aVendedor) > 0
					           
	    //Desenha box e divisorias dos itens 
		RFIN012BOX()
		
		//Quebra de Pagina antes de imprimir a assintarura
		If (nLinha + (nSaltoLinha * 5)) > 2245
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
		RFIN012ASI()
					
		contrCor:=1
					
	  EndIf
				                                     
 	  oPrint:EndPage()	    // Finaliza a Pagina.
	  oPrint:StartPage()	//Inicia uma nova Pagina					
	  nPagina:=1
	  _cdescvend := Posicione("SA3",1,xFilial("SA3") + TMPCOMI->zae_vend,"A3_NOME")
	  _cdescsup := Posicione("SA3",1,xFilial("SA3") + TMPCOMI->zae_codsup,"A3_NOME")
	  _cdescsui := Posicione("SA3",1,xFilial("SA3") + TMPCOMI->zae_codsui,"A3_NOME" )
	  RFIN012CAB( TMPCOMI->zae_vend , _cdescvend , TMPCOMI->zae_codsup , _cdescsup, TMPCOMI->zae_codsui, _cdescsui ) //Chama cabecalho
	  aAdd(aVendedor,{TMPCOMI->zae_vend})     
				       
	EndIf                                           
						
	//Quebra de Pagina
	If nLinha > 2245
				 
	  RFIN012BOX()			//Desenha box e divisorias dos itens 
	  oPrint:EndPage()		// Finaliza a Pagina.
	  oPrint:StartPage()	//Inicia uma nova Pagina					
	  nPagina++
	  _cdescvend := Posicione("SA3",1,xFilial("SA3") + TMPCOMI->zae_vend,"A3_NOME")
	  _cdescsup := Posicione("SA3",1,xFilial("SA3") + TMPCOMI->zae_codsup,"A3_NOME")
	  _cdescsui := Posicione("SA3",1,xFilial("SA3") + TMPCOMI->zae_codsui,"A3_NOME" )
	  RFIN012CAB( TMPCOMI->zae_vend , _cdescvend , TMPCOMI->zae_codsup , _cdescsup, TMPCOMI->zae_codsui, _cdescsui ) //Chama cabecalho
  	  contrCor:=1			
	  
	EndIf   
			
	//Imprime dados dos produtos 
			                                                      
	If Len(AllTrim(TMPCOMI->zae_loja)) > 1
	  cCodCli := SubStr(AllTrim(Posicione("SA1",1,xFilial("SA1") + TMPCOMI->zae_cli + TMPCOMI->zae_loja,"A1_NOME")),1,30) + '-' 
	  cCodCli += SubStr(Posicione("SA1",1,xFilial("SA1") + TMPCOMI->zae_cli + TMPCOMI->zae_loja,"A1_NREDUZ"),1,25)
	Else
	  cCodCli:=SubStr(AllTrim(Posicione("SA1",1,xFilial("SA1") + TMPCOMI->zae_cli,"A1_NOME")),1,30)
	EndIf	   
			
	nLinInici:=nLinha
	nLinFinal:=RFIN012CAL(SubStr(AllTrim(TMPCOMI->zae_prod) + '-' + Posicione("SB1",1,xFilial("SB1") + TMPCOMI->zae_prod,"SB1->B1_I_DESCD"),1,64))                  
	nLinFinRz:=RFIN012CAL(SubStr(cCodCli,1,64))                  
	nLinFinal:=IIf(nLinFinal >= nLinFinRz,nLinFinal,nLinFinRz)
			
	//Zebra o relatorio
	contrCor++ 
	If contrCor % 2 == 0
	  oPrint:FillRect({(nlinha+3),nColInic,nLinFinal,nColFinal},oBrush)
	EndIf
	
	_crazao := " "
	If Len(AllTrim(TMPCOMI->zae_cli + '/' + TMPCOMI->zae_loja)) > 1
		_crazao := Posicione("SA1",1,xFilial("SA1")+TMPCOMI->zae_cli+TMPCOMI->zae_loja,"A1_NOME") 
	EndIf
			
	oPrint:Say (nlinha,nColInic + 25,TMPCOMI->zae_item,oFont12b)
	oPrint:Say (nlinha,nColInic + 0758,Transform(TMPCOMI->zae_comis1,"@R 99.99") + "%",oFont12b)
	oPrint:Say (nlinha,nColInic + 0930,SubStr(Posicione("ACY",1,xFilial("ACY") + TMPCOMI->zae_grpven,"ACY->ACY_DESCRI"),1,19),oFont12b)
	oPrint:Say (nlinha,nColInic + 1340,IIf(Len(AllTrim(TMPCOMI->zae_cli + '/' + TMPCOMI->zae_loja)) > 1,TMPCOMI->zae_cli + '/' + TMPCOMI->zae_loja,""),oFont12b)
	oPrint:Say (nlinha,nColInic + 1620,_crazao,oFont12b)
	oPrint:Say (nlinha,nColInic + 2430,Transform(TMPCOMI->zae_comis4,"@R 99.99") + "%",oFont12b)
	oPrint:Say (nlinha,nColInic + 2590,Transform(TMPCOMI->zae_comis2,"@R 99.99") + "%",oFont12b)
	oPrint:Say (nlinha,nColInic + 2770,AllTrim(SubStr(Posicione("SA3",1,xFilial("SA3") + TMPCOMI->zae_codger,"A3_NOME"),1,13)),oFont12b)
	oPrint:Say (nlinha,nColInic + 3195,Transform(TMPCOMI->zae_comis3,"@R 99.99") + "%",oFont12b)
			
	If Len(AllTrim(TMPCOMI->zae_cli)) == 6 			                                                                           
	  RFIN012CAL(SubStr(cCodCli,1,64))
	EndIf                                             
            
	nLinha:= nLinInici
	RFIN012QUE(SubStr(AllTrim(TMPCOMI->zae_prod) + '-' + Posicione("SB1",1,xFilial("SB1") + TMPCOMI->zae_prod,"SB1->B1_I_DESCD"),1,50))
	oPrint:Line(nLinha,nColInic,nLinha,nColFinal)
		     
	TMPCOMI->( DBSkip() )
		
  EndDo       
							
  //Desenha box e divisorias dos itens 
  RFIN012BOX()
		
  //Quebra de Pagina antes de imprimir a assintarura
  If (nLinha + (nSaltoLinha * 5)) > 2245
				 
    oPrint:EndPage()		// Finaliza a Pagina.
	oPrint:StartPage()		//Inicia uma nova Pagina					
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
  RFIN012ASI()
		
EndIf
	
TMPCOMI-> ( DBCloseArea( ) )			

Return

/*
===============================================================================================================================
Programa----------: RFIN012BOX
Autor-------------: Josué Danich Prestes
Data da Criacao---: 01/08/2018
Descrição---------: Imprime box e divisorias para a ultima pagina do relatorio
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RFIN012BOX()
        
//Imprime box e divisorias para a ultima pagina do relatorio
oPrint:Box(nLinInBox,nColInic,nLinha,nColFinal)
		
//Divisorias
oPrint:Line(nLinInBox,0145,nLinha,0145)		//PRODUTO
oPrint:Line(nLinInBox,0723,nLinha,0723)		//COMISSAO VENDEDOR
oPrint:Line(nLinInBox,0935,nLinha,0935)		//GRUPO DE VENDA
oPrint:Line(nLinInBox,1355,nLinha,1355)		//CODIGO CLIENTE
oPrint:Line(nLinInBox,1630,nLinha,1630)		//DESCRICAO CLIENTE
oPrint:Line(nLinInBox,2455,nLinha,2455)		//COMISSAO COORDENADOR
oPrint:Line(nLinInBox,2605,nLinha,2605)		//COMISSAO COORDENADOR
oPrint:Line(nLinInBox,2765,nLinha,2765)		//DESCRICAO GERENTE
oPrint:Line(nLinInBox,3195,nLinha,3195)		//COMISSAO GERENTE 

Return

/*
===============================================================================================================================
Programa----------: RFIN012ASI
Autor-------------: Josué Danich Prestes
Data da Criacao---: 01/08/2018
escrição---------: Desenha assinatura do Diretor Comercial e do Analista Comercial
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RFIN012ASI()

Local nColuna
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

/*
===============================================================================================================================
Programa----------: RFIN012QUE
Autor-------------: Josué Danich Prestes
Data da Criacao---: 01/08/2018
Descrição---------: Quebra descrição do produto em várias linhas
Parametros--------: ctexto - Descrição do produto a ser trabalhada
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RFIN012QUE(ctexto)

Local cont        := 1
Local cTextoQbr   := ""

ctexto:=AllTrim(ctexto) 
             
While cont < Len(ctexto)              
  cTextoQbr:= AllTrim(SubStr(ctexto,cont,25))
  oPrint:Say (nlinha,nColInic + 0120,cTextoQbr,oFont12b) 
  nlinha+=nSaltoLinha
  cont+= 25	
EndDo                    

Return

/*
===============================================================================================================================
Programa----------: RFIN012CAL
Autor-------------: Josué Danich Prestes
Data da Criacao---: 01/08/2018
Descrição---------: Retorna linha que estará disponível após impressão de um string em linhas de 32 caracteres
Parametros--------: ctexto - texto a ser trabalhado
Retorno-----------: nlinhafin - linha após o texto
===============================================================================================================================
*/
Static Function RFIN012CAL(ctexto)

Local cont        := 0
Local nLinhaFin   := nlinha 

ctexto:=AllTrim(ctexto)
             
While cont <= Len(ctexto)
  cont+= 32              
  nLinhaFin+=nSaltoLinha
EndDo 

Return nLinhaFin
