#Include "rwmake.ch"
#Include "ap5mail.ch"
#Include "tbiconn.ch"
#Include "TOTVS.ch"
#Include "MATR110.CH"

/*
===============================================================================================================================
Programa----------: RCOM018
Autor-------------: Jonathan Torioni
Data da Criacao---: 16/06/2020
Descrição---------: Impressão de pedidos de compra para o Almoxarifado
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RCOM018()
    Private cTitulo   := "Vendas"
    Private cMensagem := OemToAnsi("Teste") + CHR(13)+CHR(10)
    Private lImpInc   := .F.   

    U_ITLOGACS()

    FWMsgRun(,{|| RCOM018M()},"Processando relatorio...","Aguarde")
Return


/*
===============================================================================================================================
Programa----------: RCOM018M
Autor-------------: Jonathan Torioni
Data da Criacao---: 16/06/2020
Descrição---------: Função criada para gerar a impressão do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RCOM018M()
Private nMoeda		:= 1
Private nPagina     := 1//Responsavel por armazenar a numeracao da pagina 

Private oFont10
Private oFont10b
Private oFont10End
Private oFont11
Private oFont11b   
Private oFont11bAr
Private oFont13bAr
Private oFont14bAr    
Private oFontValor
Private oPrint

Private nLinhaInic  := 0100
Private nLinha      := 0100
Private nColInic    := 0030
Private nColFinal   := 2360  
Private nSaltoLinha := 50
Private nLinBoxIn   := 0 //Armazena a linha inicial para gerar as divisorias dos itens dos produtos

Private _cEmailXML  := SuperGetMv("IT_ENDXML" , .F. , "")

If Type("lPedido") != "L"
	lPedido := .F.
EndIf


Define Font oFont10    Name "Helvetica"       Size 0,-08       // Tamanho 10 		                                                                              
Define Font oFont10b   Name "Helvetica"       Size 0,-08 Bold  // Tamanho 10 		                                                                              
Define Font oFont10End Name "Courier New"     Size 0,-07 Bold  // Tamanho 10
Define Font oFont11    Name "Helvetica"       Size 0,-09       // Tamanho 11 
Define Font oFont11b   Name "Helvetica"       Size 0,-10 Bold  // Tamanho 12 Negrito
Define Font oFont11bAr Name "Helvetica"       Size 0,-08 Bold  // Tamanho 10 Negrito  
Define Font oFont13bAr Name "Helvetica"       Size 0,-12 Bold  // Tamanho 14 Negrito
Define Font oFont14bAr Name "Helvetica"       Size 0,-14 Bold  // Tamanho 18 Negrito		
Define Font oFontValor Name "Arial"           Size 0,-16 Bold  // Tamanho 18 Negrito
		

//================================================================
// Variaveis utilizadas para parametros                         
// MV_PAR01               Do Pedido                             
// MV_PAR02               Ate o Pedido                          
// MV_PAR03               A partir da data de emissao           
// MV_PAR04               Ate a data de emissao                 
// MV_PAR05               Somente os Novos                      
// MV_PAR06               Campo Descricao do Produto    	     
// MV_PAR07               Unidade de Medida:Primaria ou Secund. 
// MV_PAR08               Imprime ? Pedido Compra ou Aut. Entreg
// MV_PAR09               Numero de vias                        
// MV_PAR10               Pedidos ? Liberados Bloqueados Ambos  
// MV_PAR11               Impr. SC's Firmes, Previstas ou Ambas 
// MV_PAR12               Qual a Moeda ?                        
// MV_PAR13               Endereco de Entrega                   
// MV_PAR14               todas ou em aberto ou atendidos       
//================================================================

	nMoeda := MAX(SC7->C7_MOEDA,1)
                       
	
	oPrint:= TMSPrinter():New("RELATORIO DE PEDIDO DE COMPRAS")
	oPrint:SetPortrait() 	// Retrato
	oPrint:SetPaperSize(9)	// Seta para papel A4 

	// startando a impressora
	oPrint:Say(0, 0, " ",oFont11b,100)
	
	RCOM018I()//Imprime os dados do Relatorio

	lPedido := .F.   
	  
Return

/*
===============================================================================================================================
Programa----------: RCOM018C
Autor-------------: Fabiano Dias Silva
Data da Criacao---: 01/01/2010
Descrição---------: Função criada para gerar o cabeçalho do relatório
Parametros--------: ncw		- N=mero da Via do relatório
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RCOM018C(ncw)

Local cRaizServer := If(issrvunix(), "/", "\")       
Local nColCentr := 0
Local cTextoSay := ""   
Local cCodFornec:= SC7->C7_FORNECE
Local cCodLjForn:= SC7->C7_LOJA                            
Local cAreaSC7  := SC7->(GetArea())
Local cEmisaoVia:= ""              

//Seta a posicao inicial do cabecalho          
nLinha :=0100                                                                                                             

oPrint:SayBitmap(nlinha + (nSaltoLinha * 2),nColInic + 460,cRaizServer + "system/lgrl01.bmp",200,080) 
nlinha+=nSaltoLinha * 4                      
                                             
SM0->(DBSetOrder(1))   // forca o indice na ordem certa
SM0->(DBSeek(SUBS(cNumEmp,1,2) + cFilAnt))   

//1 QUADRANTE          
//DADOS DA EMPRESA ITALAC                    
//NOME DA EMPRESA                                                           
RCOM018Q(AllTrim(SM0->M0_NOMECOM),35,oFont14bAr,30.67,0597,1165)               

//ENDERECO DA EMPRESA
RCOM018Q(AllTrim(SM0->M0_ENDCOB),41,oFont13bAr,27.68,0597,1165)               

//CEP _ CIDADE + ESTADO   
RCOM018Q(SubStr(("CEP:" + SubStr(AllTrim(SM0->M0_CEPCOB),1,2) + "." + SubStr(AllTrim(SM0->M0_CEPCOB),3,3) + "-" + SubStr(AllTrim(SM0->M0_CEPCOB),6,3) + '-' + SubStr(AllTrim(SM0->M0_CIDCOB),1,50) + '-' + AllTrim(SM0->M0_ESTCOB)),1,70),58,oFont11bAr,19.23,0597,1165)

//TELEFONE + FAX
cTextoSay:='TEL:(' + SubStr(SM0->M0_TEL,4,2) + ')' + SubStr(SM0->M0_TEL,7,4) + '-' +SubStr(SM0->M0_TEL,11,4) + ' - '+'FAX:(' + SubStr(SM0->M0_FAX,4,2) + ')' + SubStr(SM0->M0_FAX,7,4) + '-' +SubStr(SM0->M0_FAX,11,4) 
nColCentr:=RCOM018A(nColInic,1165,cTextoSay,19.23)                                                 
oPrint:Say (nLinha,0597,cTextoSay,oFont11bAr,1165,,,2)                
nlinha+=nSaltoLinha

//CNPJ        
cTextoSay:= "C.N.P.J./C.P.F.:" + RCOM018J(SM0->M0_CGC)
nColCentr:=RCOM018A(nColInic,1165,cTextoSay,27.68)   
oPrint:Say (nlinha,0597,cTextoSay,oFont13bAr,1165,,,2) // Picture "@R! NN.NNN.NNN/NNNN-99"         
nlinha+=nSaltoLinha

//INSRICAO ESTADUAL
cTextoSay:= "I.E.:" + AllTrim(SM0->M0_INSC)
nColCentr:=RCOM018A(nColInic,1165,cTextoSay,27.68)   
oPrint:Say (nlinha,0597,cTextoSay,oFont13bAr,1165,,,2)  
nlinha+=(nSaltoLinha * 3) 

//DADOS DO SEGUNDO QUADRANTE                                         
nlinha:=0100
nlinha+=nSaltoLinha                                                    

oPrint:Say (nlinha - 50,1582,'PEDIDO DE COMPRAS',oFont14bAr,2000,,,2)  
oPrint:Line(nlinha,1165,nlinha,2000) 

oPrint:Say (nlinha,2180,'No.',oFont14bAr,nColFinal,,,2)   
oPrint:Say (nLinha + nSaltoLinha,2180,AllTrim(SC7->C7_NUM),oFont14bAr,nColFinal,,,2) 
nlinha+=(nSaltoLinha * 2)        

//Inicio da validação para que seja preenchido o combo box de acordo com o conte=do do campo C7_I_APLIC - Talita - 05/02/13
oBrush := TBrush():New(,RGB(0,0,0))
cAplic:=SC7->C7_I_APLIC
Do Case

Case cAplic = "C" 
//oPrint:Say (nlinha,1582,'REAL',oFont14bAr,2000,,,2)  
oPrint:Box(nlinha - 78,1190,(nlinha - 78) + 30,1220) 
oPrint:FillRect({nlinha - 78,1190,(nlinha - 78) + 30,1220},oBrush) 
oPrint:Box(nlinha - 18,1190,(nlinha - 18) + 30,1220)   
oPrint:Box(nlinha + 42,1190,nlinha + 72,1220)
oPrint:Box(nlinha - 78,1510,(nlinha - 78) + 30,1540) 

Case cAplic = "I"  

//oPrint:Say (nlinha,1582,'REAL',oFont14bAr,2000,,,2)  
oPrint:Box(nlinha - 78,1190,(nlinha - 78) + 30,1220) 
oPrint:Box(nlinha - 18,1190,(nlinha - 18) + 30,1220) 
oPrint:FillRect({nlinha - 18,1190,(nlinha - 18) + 30,1220},oBrush)   
oPrint:Box(nlinha + 42,1190,nlinha + 72,1220)  
oPrint:Box(nlinha - 78,1510,(nlinha - 78) + 30,1540)

Case cAplic = "M" 

//oPrint:Say (nlinha,1582,'REAL',oFont14bAr,2000,,,2)  
oPrint:Box(nlinha - 78,1190,(nlinha - 78) + 30,1220) 
oPrint:Box(nlinha - 18,1190,(nlinha - 18) + 30,1220)    
oPrint:Box(nlinha + 42,1190,nlinha + 72,1220)
oPrint:Box(nlinha - 78,1510,(nlinha - 78) + 30,1540)
oPrint:FillRect({nlinha + 42,1190,nlinha + 72,1220},oBrush)  

Case cAplic = "S"    //07/03/13 - Talita - Incluida nova opção Serviço conforme chamado 2802

oPrint:Box(nlinha - 78,1190,(nlinha - 78) + 30,1220) 
oPrint:Box(nlinha - 18,1190,(nlinha - 18) + 30,1220)    
oPrint:Box(nlinha + 42,1190,nlinha + 72,1220) 
oPrint:Box(nlinha - 78,1510,(nlinha - 78) + 30,1540)
oPrint:FillRect({nlinha - 78,1510,(nlinha - 78) + 30,1540},oBrush)
 

Case cAplic = ' ' 

oPrint:Box(nlinha - 78,1190,(nlinha - 78) + 30,1220) 
oPrint:Box(nlinha - 18,1190,(nlinha - 18) + 30,1220)    
oPrint:Box(nlinha + 42,1190,nlinha + 72,1220) 
oPrint:Box(nlinha - 78,1510,(nlinha - 78) + 30,1540)

EndCase
//Fim da validação 
oPrint:Say (nlinha - 86,1250,'Consumo'     ,oFont13bAr)  
oPrint:Say (nlinha - 26,1250,'Investimento',oFont13bAr)     
oPrint:Say (nlinha + 34,1250,'Manutenção'  ,oFont13bAr)
oPrint:Say (nlinha - 86,1550,'Serviço'  	,oFont13bAr)
                             
cEmisaoVia:= IIf(SC7->C7_QTDREEM > 0,AllTrim(Str((SC7->C7_QTDREEM+1),2)) + "a.EMISSAO ",Str(1,2) + "a.EMISSAO ") + Str(ncw,2)+"a.VIA"
oPrint:Say (nLinha + nSaltoLinha,2180,cEmisaoVia,oFont11bAr,nColFinal,,,2)

//DADOS DO FORNECEDOR
DBSelectArea("SA2")
SA2->(DBSetOrder(1))
SA2->(DBSeek(xFilial("SA2") + cCodFornec + cCodLjForn))

nlinha+=nSaltoLinha * 2                                               

//NOME DA EMPRESA FORNECEDOR
RCOM018Q("",41,oFont13bAr,27.63,1762,2360)               
   
//ENDERECO DA EMPRESA
RCOM018Q("",58,oFont11bAr,19.23,1762,2360)  
//CEP + CIDADE + ESTADO
RCOM018Q("",58,oFont11bAr,19.23,1762,2360)
//TELEFONE + FAX   

nColCentr:=RCOM018A(1166,2360,"",19.23)                                                 

oPrint:Say (nLinha,1762,"",oFont11bAr,2360,,,2)                
nlinha+=nSaltoLinha

oPrint:Say (nlinha,1762,"",oFont11bAr,2360,,,2) // Picture "@R! NN.NNN.NNN/NNNN-99"         
nlinha+=nSaltoLinha                  

oPrint:Say (nlinha,1762,"",oFont13bAr,2360,,,2)         
nlinha+=nSaltoLinha * 4
                                                   

//Imprime Box e linhas
oPrint:Box(nLinhaInic,nColInic,nLinha,nColFinal)    
oPrint:Line(nLinhaInic + 250,1165,nLinhaInic + 250,nColFinal) 
oPrint:Line(nLinhaInic,2000,nLinhaInic + 250,2000)      
oPrint:Line(nLinhaInic,1165,nLinha,1165)      


//Cabecalho do Produto 
nLinBoxIn:=nLinha	  
oPrint:Say (nlinha,0040,"Item",oFont10)        
oPrint:Say (nlinha,0140,"Produto",oFont10)
oPrint:Say (nlinha,0350,"Descricao",oFont10)
oPrint:Say (nlinha,1145,"UM",oFont10)
oPrint:Say (nlinha,1275,"Quantidade",oFont10)
oPrint:Say (nlinha,1540,"NF.",oFont10)
oPrint:Say (nlinha,1790,"Data receb.",oFont10)
oPrint:Say (nlinha,2100,"Conferido por",oFont10)

nlinha+=nSaltoLinha                                              

//RESTAURA A AREA DA SC7
FWRestArea(cAreaSC7)     

Return                                                                                                                                    

/*
===============================================================================================================================
Programa----------: RCOM018A
Autor-------------: Fabiano Dias Silva
Data da Criacao---: 01/01/2010
Descrição---------: Função criada para gerar o alinhamento centralizado
Parametros--------: nColIni		- N=mero da Coluna Inicial
				  : nColFin		- N=mero da Coluna Final
				  : cTexto		- Texto a ser centralizado
				  : nTamLetra	- Tamanho da fonte
Retorno-----------: nColuna		- N=mero da coluna a ser impresso o texto
===============================================================================================================================
*/
Static Function RCOM018A(nColIni,nColFin,cTexto,nTamLetra)

Local nColuna:= 0
      
	nColuna:=nColIni + Int(((nColFin-nColIni) - (Len(cTexto)* nTamLetra))/2)

Return nColuna

/*
===============================================================================================================================
Programa----------: RCOM018Q
Autor-------------: Jonathan Torioni
Data da Criacao---: 16/06/2020
Descrição---------: Função criada para quebrar o texto
Parametros--------: cTexto		- Texto a ser quebrado
				  : nCaracteres	- N=mero de caracteres para ser quebrado
				  : cFonte		- Tipo de fonte a ser utilizado
				  : nTamCaract	- Tamanho da fonte
				  : nColIn		- N=mero da Coluna Inicial
				  : nColFim		- N=mero da Coluna Final
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RCOM018Q(ctexto,nCaracteres,cFonte,nTamCaract,nColIn,nColFim)

Local cont        := 1         
Local cTextoQbr   := ""
             
While cont <= Len(ctexto)
	
	cTextoQbr:= AllTrim(SubStr(ctexto,cont,nCaracteres))	
	oPrint:Say (nLinha,nColIn,cTextoQbr,cFonte,nColFim,,,2) 
	nlinha+=nSaltoLinha
	cont+= nCaracteres

EndDo

Return

/*
===============================================================================================================================
Programa----------: RCOM018J
Autor-------------: Jonathan Torioni
Data da Criacao---: 16/06/2020
Descrição---------: Função criada para formatar CPF/CNPJ
Parametros--------: cCPFCNPJ	- Texto a ser quebrado
Retorno-----------: cCampFormat	- Retorna o campo formatado conforme CPF/CNPJ
===============================================================================================================================
*/
Static Function RCOM018J(cCPFCNPJ)

Local cCampFormat:=""//Armazena o CPF ou CNPJ formatado
   
   //CPF                            
	If Len(AllTrim(cCPFCNPJ)) == 11
	
		cCampFormat:=SubStr(cCPFCNPJ,1,3) + "." + SubStr(cCPFCNPJ,4,3) + "." + SubStr(cCPFCNPJ,7,3) + "-" + SubStr(cCPFCNPJ,10,2) 
		
	Else//CNPJ       
		
		cCampFormat:=SubStr(cCPFCNPJ,1,2)+"."+SubStr(cCPFCNPJ,3,3)+"."+SubStr(cCPFCNPJ,6,3)+"/"+SubStr(cCPFCNPJ,9,4)+"-"+ SubStr(cCPFCNPJ,13,2)
			
	EndIf
	
Return cCampFormat

/*
===============================================================================================================================
Programa----------: RCOM018I
Autor-------------: Jonathan Torioni
Data da Criacao---: 16/06/2020
Descrição---------: Função criada para imprimir o relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RCOM018I()
Local nReem 
Local nOrder
Local cCondBus
Local nSavRec
Local aPedido 	:= {}
Local aPedMail	:= {}
Local aSavRec 	:= {}
Local i       	:= 0
Local cFiltro 	:= ""
Local lImpri    := .F.
Local cNumPedf	:= SC7->C7_NUM

Private _aPedInter:= {}

Private cCGCPict, cCepPict

Private ncw     := 0

Private cVar         
Private nLinObs := 0       

Private cDescPro:= ""
Private oDlg    := NIL	

Private lShowDlg:=.F.

// Variavel Customizada
Private nOpcoes	 := 1
Private oShowDlg

Private nDescProd:= 0
Private nTotal   := 0
Private nTotMerc := 0

Private contrCor := 1
Private oBrush   := TBrush():New( ,CLR_LIGHTGRAY) 

Private nRecnoSM0:= 0    

Private _cUserDig


//================================================================
//Definir as pictures                                           
//================================================================
cCepPict:=PesqPict("SA2","A2_CEP")
cCGCPict:=PesqPict("SA2","A2_CGC")
                                            
nDescProd:= 0
nTotal   := 0
nTotMerc := 0
NumPed   := Space(6)    


cCondBus := cNumPedf
nOrder	 :=	1 
                                                 
                                    
SB1->(DBSetOrder(1))

DBSelectArea("SC7") 
SC7->(DBSetOrder(nOrder))
SC7->(DBSeek(xFilial("SC7")+cCondBus,.T.))


While SC7->(!Eof()) .And. C7_FILIAL = xFilial("SC7") .And. C7_NUM == cNumPedf

	//================================================================
	// Cria as variaveis para armazenar os valores do pedido        
	//================================================================
//	nOrdem   := 1
	nReem    := 0
	cObs01   := " "
	cObs02   := " "
	cObs03   := " "
	cObs04   := " "
	cObs05   := " "
	
	If	C7_TIPO == 2
		DBSkip()
		Loop
	EndIf


	//================================================================
	// Filtra Tipo de SCs Firmes ou Previstas                       
	//================================================================
	If !MtrAValOP(3, 'SC7')
		DBSkip()
		Loop
	EndIf

	MaFisEnd()
	RCOM0181(SC7->C7_NUM,,,cFiltro)
	        
	oPrint:StartPage()          //Inicia uma nova pagina a cada novo produtor
	nPagina  := 1 				//Variavel que controla o numero da pagina atual
	RCOM018C(ncw)				//Imprime cabecalho
					
	contrCor  := 1	            //Variavel que controla a cor do zebramento do relatorio
	nTotal    := 0
	nTotMerc  := 0
	nDescProd := 0
	nReem     := SC7->C7_QTDREEM + 1
	nSavRec   := SC7->(Recno())
	NumPed    := SC7->C7_NUM
	nLinObs   := 0 
	aPedido   := {SC7->C7_FILIAL,SC7->C7_NUM,SC7->C7_EMISSAO,SC7->C7_FORNECE,SC7->C7_LOJA,SC7->C7_TIPO}
	_aPedInter:= {}
	nTotIpi   := 0 
	nTotIcms  := 0 
	nConta    := 0

	While !Eof() .And. C7_FILIAL = xFilial("SC7") .And. C7_NUM == NumPed

		nConta++       

		If aScan(aSavRec,Recno()) == 0		// Guardo recno p/gravacao
			aAdd(aSavRec,Recno())
		EndIf

		//================================================================
		// Verifica se havera salto de formulario                       
		//================================================================
		
		If nLinha >= 3300   
			oPrint:Box(nLinhaInic,0030,nLinha,nColFinal)    				    
			oPrint:EndPage()	// Finaliza a Pagina.
			oPrint:StartPage()	// Inicia uma nova pagina  
			nPagina++
			RCOM018C(ncw)  
		EndIf

		//================================================================
		// Pesquisa Descricao do Produto                                
		//================================================================			
		RCOM018P()  

		_nVALORIPI := MaFisRet(nConta,"IT_VALIPI")
		_nVALORICMS:= MaFisRet(nConta,"IT_VALICM")
		If SB1->(DBSeek( xFilial("SB1")+SC7->C7_PRODUTO)) 
			If SB1->B1_TIPO = "SV"
				nTotIpi += 0
				nTotIcms+= 0

				MaFisLoad("IT_VALIPI",0,nConta)
				MaFisLoad("IT_VALICM",0,nConta)
			ElseIf !SB1->B1_TIPO $ "IN/EM/PA" .And. _nVALORIPI <> 0
				_nBASEICM  := MaFisRet(nConta,"IT_BASEICM")
				_nALIQICM  := MaFisRet(nConta,"IT_ALIQICM")
				_nVALORICMS:= Round((_nVALORIPI+_nBASEICM)*(_nALIQICM/100),2)

				nTotIpi    += _nVALORIPI 
				nTotIcms   += _nVALORICMS

				MaFisLoad("IT_BASEICM",(_nVALORIPI+_nBASEICM),nConta)
				MaFisLoad("IT_VALICM" ,_nVALORICMS,nConta)
			Else
				nTotIpi    += _nVALORIPI
				nTotIcms   += _nVALORICMS
			EndIf
		EndIf
		
		
		//================================================================
		// Armazena somente os pedidos internos distintos               
		//================================================================ 			
		If Len(AllTrim(SC7->C7_I_PEDIN)) > 0
						
			nPosPedInt:= aScan(_aPedInter,{|v| v[1] == SC7->C7_I_PEDIN})       
			
			If nPosPedInt == 0
				aAdd(_aPedInter,{SC7->C7_I_PEDIN})
			EndIf   
		
		EndIf
		
		//================================================================
		// Armazena o codigo do usuario que digitou o pedido de compras 
		//================================================================
		_cUserDig:= SC7->C7_USER
		
		lImpri  := .T.
		
		DBSkip()
	EndDo

	DBGoTo(nSavRec)
													
	//quando acaba de imprimir os produtos e se chega no final da pagina
	If nLinha >= 3300                           
			oPrint:Box(nLinhaInic,0030,nLinha,nColFinal)
			oPrint:EndPage()	// Finaliza a Pagina.
			oPrint:StartPage()	// Inicia uma nova pagina                  
			nLinha:=0100                              
			nPagina++
			RCOM018S(ncw)
	EndIf

	//Espaco em branco entre os produtos e a parte resumida do relatorio
	nLinha:=IIf(nLinha < 2300,2300,nLinha)
	oPrint:Line(nlinha,0030,nlinha,2360) 
	RCOM018R(nDescProd)		// Imprime os dados complementares do PC passando o desconto dos produtos como parametro

	oPrint:EndPage()	// Finaliza a Pagina.


	MaFisEnd()
	
	If Len(aSavRec)>0
		For i:=1 to Len(aSavRec)
			DBGoTo(aSavRec[i])
			RecLock("SC7",.F.)  //Atualizacao do flag de Impressao
			Replace C7_QTDREEM With (C7_QTDREEM+1)
			Replace C7_EMITIDO With "S"
			MSUnLock()
		Next
		DBGoTo(aSavRec[Len(aSavRec)])		// Posiciona no ultimo elemento e limpa array
	EndIf
      

	aAdd(aPedMail,aPedido)
    
	aSavRec := {}
 
	DBSkip()
EndDo

 
DBSelectArea("SC7")
dbClearFilter()
DBSetOrder(1)

DBSelectArea("SX3")
DBSetOrder(1)

MS_FLUSH()

oPrint:Preview()	// Visualiza antes de Imprimir.

Return

/*
===============================================================================================================================
Programa----------: RCOM018P
Autor-------------: Jonathan Torioni
Data da Criacao---: 16/06/2020
Descrição---------: Função criada para Imprimir as informações do Produto
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RCOM018P()     

Local aAreaSC7    := SC7->(GetArea()) 
Local nTxMoeda 
Local nValTotSC7  := 0 
Local nVlUnitSC7  := 0
Local cUniMedida  := ""
Local cQuantidade := 0
Local cIPI		  := 0	 
Local oRadio	  
Local nLinFinal        

//==============================================================
// Inicializa o descricao do Produto conf. parametro digitado.
//==============================================================
			cDescPro := ""
			
			//=======================================================================
			// Criacao da Interface                                                
			//=======================================================================
			If !lShowDlg

				DEFINE MSDIALOG oDlg TITLE "Descrição do Produto" FROM 000,000 TO 230,450 PIXEL
				@ 001,0002	Say OemToAnsi("Codigo: " + AllTrim(SC7->C7_PRODUTO)) OF oDlg COLOR CLR_BLACK
				@ 002,0002	Say OemToAnsi("Desc. Simples:   " + AllTrim(SC7->C7_DESCRI)) OF oDlg
				@ 003,0002	Say OemToAnsi("Desc. Detalhada: " + AllTrim(Posicione("SB1",1,xFilial("SB1")+SC7->C7_PRODUTO,"B1_I_DESCD"))) OF oDlg
				@ 050,0015	To 095,135 Title OemToAnsi("Selecione qual descrição será utilizada:")
				@ 060,0017	Radio oRadio Var nOpcoes ITEMS OemToAnsi("Descrição Simples"),OemToAnsi("Descrição Detalhada"),OemToAnsi("Descr. Detalhada + Simples") 3D SIZE 100,10 OF oDlg PIXEL
				@ 100,0015	CHECKBOX oShowDlg VAR lShowDlg PROMPT "Repetir Opção" SIZE 60,11 OF oDlg PIXEL
				@ 100,0110	BMPBUTTON Type 01 ACTION Close(oDlg)
				
				Activate MSDialog oDlg Centered
			EndIf
			
			If nOpcoes == 1
				cDescPro := AllTrim(SC7->C7_DESCRI)
			ElseIf nOpcoes == 2
				SB1->(DBSetOrder(1))
				SB1->(DBSeek( xFilial("SB1") + SC7->C7_PRODUTO ))
				cDescPro := AllTrim(SB1->B1_I_DESCD)
			ElseIf nOpcoes == 3
				SB1->(DBSetOrder(1))
				SB1->(DBSeek( xFilial("SB1") + SC7->C7_PRODUTO ))
				cDescPro := AllTrim(SB1->B1_I_DESCD) + " - "
				cDescPro += AllTrim(SC7->C7_DESCRI)
			EndIf
			
			
			If Empty(cDescPro)
				SB1->(DBSetOrder(1))
				SB1->(DBSeek( xFilial("SB1") + SC7->C7_PRODUTO ))
				cDescPro := AllTrim(SB1->B1_DESC)
			EndIf
			
			SA5->(DBSetOrder(1))
			If SA5->(DBSeek(xFilial("SA5")+SC7->C7_FORNECE+SC7->C7_LOJA+SC7->C7_PRODUTO)) .And. !Empty(SA5->A5_CODPRF)
				cDescPro := cDescPro + " ("+AllTrim(SA5->A5_CODPRF)+")"
			EndIf
			
			If SC7->C7_DESC1 != 0 .Or. SC7->C7_DESC2 != 0 .Or. SC7->C7_DESC3 != 0
				nDescProd+= CalcDesc(SC7->C7_TOTAL,SC7->C7_DESC1,SC7->C7_DESC2,SC7->C7_DESC3)
			Else
				nDescProd+=SC7->C7_VLDESC
			EndIf
						
			If !Empty(SC7->C7_OBS) .And. nLinObs < 1
				nLinObs++
				cVar:="cObs"+StrZero(nLinObs,2)
				Eval(MemVarBlock(cVar),SC7->C7_OBS)
			EndIf
			
			nTxMoeda   := IIf(SC7->C7_TXMOEDA > 0,SC7->C7_TXMOEDA,Nil)
			nValTotSC7 := xMoeda(SC7->C7_TOTAL,SC7->C7_MOEDA,nMoeda,SC7->C7_DATPRF,MsDecimais(SC7->C7_MOEDA),nTxMoeda)
			
			nTotal     := nTotal + SC7->C7_TOTAL
  			nTotMerc   := MaFisRet(,"NF_TOTAL")
//          nTotMerc   := nTotIpi+_nVALORICMS+nTotal//AWF - TESTE
                                         
			
			
			cUniMedida := SC7->C7_UM
			cQuantidade:= SC7->C7_QUANT
			nVlUnitSC7 := xMoeda(SC7->C7_PRECO,SC7->C7_MOEDA,nMoeda,SC7->C7_DATPRF,MsDecimais(SC7->C7_MOEDA),nTxMoeda)   
		
			
			
			cIPI:=SC7->C7_IPI
			
	                                          
//Imprime dados dos produtos
nLinFinal:=RCOM018L(cDescPro)                  

oPrint:Say (nlinha,0040,SC7->C7_ITEM,oFont10b)        
oPrint:Say (nlinha,0140,SC7->C7_PRODUTO,oFont10b)
oPrint:Say (nlinha,1145,cUniMedida,oFont10b)
oPrint:Say (nlinha,1425,transform(cQuantidade,PesqPict("SC7","C7_QUANT")),oFont10b,,,,1)
			
RCOM018D(cDescPro)//Descricao do produto

FWRestArea(aAreaSC7)      

Return

/*
===============================================================================================================================
Programa----------: RCOM018D
Autor-------------: Jonathan Torioni
Data da Criacao---: 16/06/2020
Descrição---------: Função criada para quebrar a descrição do produto
Parametros--------: cTexto		- Descrição do Produto
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RCOM018D(ctexto)    

Local cont        := 1        
Local cTextoQbr   := "" 

ctexto:=AllTrim(ctexto)            
             
While cont <= Len(ctexto)
	
	cTextoQbr:= AllTrim(SubStr(ctexto,cont,40))
	
	oPrint:Say (nLinha,0350,cTextoQbr,oFont10b) 
	nlinha+=nSaltoLinha
	
	cont+= 40  

EndDo                    

Return 

/*
===============================================================================================================================
Programa----------: RCOM018L
Autor-------------: Jonathan Torioni
Data da Criacao---: 16/06/2020
Descrição---------: Função criada para criar o grupo de perguntas
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RCOM018L(ctexto)

Local cont        := 0
Local nLinhaFin   := nlinha 

ctexto:=AllTrim(ctexto)
             
While cont <= Len(ctexto)

	cont+= 35              
	nLinhaFin+=nSaltoLinha

EndDo 

Return nLinhaFin

/*
===============================================================================================================================
Programa----------: RCOM018R
Autor-------------: Jonathan Torioni
Data da Criacao---: 16/06/2020
Descrição---------: Função criada para imprimir o resumo do pedido de compras
Parametros--------: nDescProd	- Desconto do produto
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RCOM018R(nDescProd)
Local cUrgen	:= ""
Local aAreaSC7  := SC7->(GetArea())               
Local nLiPosIni    
Local nlinInTran             
Local _cUsrNome           
Local _cPedInter := ""

oPrint:Say (nlinha,0050,"Observações do PC",oFont14bAr)
nlinha+= nSaltoLinha+20
RCOM18D2(cObs01)
nlinha+= nSaltoLinha
oPrint:Line(nlinha,0030,nlinha,2360) 

oPrint:Say (nlinha,0050,"Observações conferente",oFont14bAr)
nlinha+=(nSaltoLinha * 8)
oPrint:Line(nlinha,0030,nlinha,2360) 


cMensagem:= Formula(SC7->C7_MSG)


If Len(_aPedInter) > 0   

	aEval(_aPedInter,{|e| _cPedInter += "," + AllTrim(e[1])})               

	oPrint:Say (nlinha,nColInic,"Pedido(s) Interno(s): " +  SubStr(_cPedInter,2,Len(_cPedInter)),oFont10)
	nlinha+=nSaltoLinha
	oPrint:Line(nlinha,0030,nlinha,2360)   
	
EndIf

If C7_I_CMPDI == "S"
	cUrgen := "SIM"
ElseIf C7_I_CMPDI == "N"
	cUrgen := "NÃO"
Else
	cUrgen := "OUTROS"
EndIf


oPrint:Say (nLinha,nColInic,"URGENTE: " + If(SC7->C7_I_URGEN="S","SIM",If(SC7->C7_I_URGEN="F","NF","NÃO")) + "            COMPRA DIRETA: " + cUrgen ,oFont14bAr)
nlinha+=nSaltoLinha
oPrint:Line(nlinha,0030,nlinha,2360) 

//Local DE ENTREGA E COBRANCA
//================================================================
// Posiciona o Arquivo de Empresa SM0.                          
//================================================================
cAlias := Alias()

SM0->(DBSetOrder(1))   // forca o indice na ordem certa
nRecnoSM0 := SM0->(Recno())
DBSeek(SUBS(cNumEmp,1,2) + SC7->C7_FILENT)         

FWRestArea(aAreaSC7)

//Condicao de pagamento + data de emissao + total das mercadorias + total das mercadorias com impostos
DBSelectArea("SE4")
DBSetOrder(1)
DBSeek(xFilial("SE4") + SC7->C7_COND)          

If !Empty(_cUserDig)
	_cUsrNome := FWSFAllUsers({_cUserDig})[1][3]
Endif	

DBSelectArea("SC7")                 

nLiPosIni:=nlinha
                                                        
nlinInTran:=nLinha 

oPrint:Say (nlinha,0050,STR0021,oFont11b)//Comprador
oPrint:Say (nlinha,0430,STR0022,oFont11b)//Gerencia
oPrint:Say (nlinha,0820,STR0023,oFont11b)//Diretoria
nlinha+=(nSaltoLinha * 6)
						
oPrint:Line(nlinha,0030,nlinha,2360) 
oPrint:Line(nlinInTran,0425,nlinha,0425)    //Coluna divisoria Gerencia
oPrint:Line(nlinInTran,0815,nlinha,0815)    //Coluna divisoria Diretoria
oPrint:Line(nlinInTran,1200,nlinha,1200)    //Coluna divisoria Transportadora
			                                                                  
//Colore a obs no final do relatorio
//oPrint:FillRect({(nlinha+3),0030,nlinha+nSaltoLinha,2360},oBrush)
If SC7->C7_TIPO == 1 .Or. SC7->C7_TIPO == 3
	oPrint:Say (nlinha,0030,STR0081,oFont11b)//"NOTA: So aceitaremos a mercadoria se na sua Nota Fiscal constar o numero do nosso Pedido de Compras."            
Else
	oPrint:Say (nlinha,0030,STR0083,oFont11b)//"NOTA: So aceitaremos a mercadoria se na sua Nota Fiscal constar o numero da Autorizacao de Entrega."
EndIf			
			
nlinha+=nSaltoLinha
		
//Imprime box 
oPrint:Box(nLinhaInic,0030,nLinha,nColFinal)

FWRestArea(aAreaSC7)

Return

/*
===============================================================================================================================
Programa----------: RCOM018S
Autor-------------: Jonathan Torioni
Data da Criacao---: 16/06/2020
Descrição---------: 
Parametros--------: numero		- N=mero de linhas
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RCOM018S(ncw)

Local cRaizServer := If(issrvunix(), "/", "\")    
      
	//Seta a posicao inicial do cabecalho        
	oPrint:SayBitmap(20,nColInic + 20,cRaizServer + "system/lgrl01.bmp",200,080)   
	nLinha :=0100                                                                
	
	//Funcao RCOM018A utilizada para pegar a coluna inicial em que devera comecar o texto
	//para que ele fique alinhado centradalizado de acordo com a coluna inicial e final
	//24.15 eh o tamanho que cada caractere para a fonte de tamanho 14 ocupa
	nColCentr:=RCOM018A(nColInic,nColFinal,'PEDIDO DE COMPRAS No.',29.10)                                                 
	
	oPrint:Say (nLinha + 10,1910,"PAGINA: " + AllTrim(Str(nPagina,2)),oFont11bAr)
	nlinha+=nSaltoLinha                                                    
	oPrint:Say (nLinha,nColCentr,'PEDIDO DE COMPRAS No.' + AllTrim(SC7->C7_NUM),oFont14bAr)                
	
	cEmisaoVia:= IIf(SC7->C7_QTDREEM > 0,AllTrim(Str((SC7->C7_QTDREEM+1),2)) + "a.EMISSAO ",Str(1,2) + "a.EMISSAO ") + Str(ncw,2)+"a.VIA"
	oPrint:Say (nLinha,1910,cEmisaoVia,oFont11bAr)
	
	nlinha+=nSaltoLinha                       
	oPrint:Line(nlinha,nColInic,nlinha,nColFinal)

Return

/*
===============================================================================================================================
Programa----------: RCOM0181
Autor-------------: Jonathan Torioni
Data da Criacao---: 20/05/2000
Descrição---------: Inicializa as funções Fiscais com o Pedido de Compras
Parametros--------: ExpC1	- N=mero do Pedido
				  : ExpC2	- Item do Pedido
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RCOM0181(cPedido,cItem,cSequen,cFiltro)

Local aArea		:= FWGetArea()
Local aAreaSC7	:= SC7->(GetArea())
Local cValid	:= ""
Local nPosRef	:= 0
Local nItem		:= 0
Local cItemDe	:= IIf(cItem==Nil,'',cItem)
Local cItemAte	:= IIf(cItem==Nil,Repl('Z',Len(SC7->C7_ITEM)),cItem)
Local cRefCols	:= '' , D
Default cSequen	:= ""
Default cFiltro	:= ""

DBSelectArea("SC7")
DBSetOrder(1)
If DBSeek(xFilial("SC7")+cPedido+cItemDe+AllTrim(cSequen))
	MaFisEnd()
	MaFisIni(SC7->C7_FORNECE,SC7->C7_LOJA,"F","N","R",{})
	While !Eof() .And. SC7->C7_FILIAL+SC7->C7_NUM == xFilial("SC7")+cPedido .And. ;
			SC7->C7_ITEM <= cItemAte .And. (Empty(cSequen) .Or. cSequen == SC7->C7_SEQUEN)

		// Nao processar os Impostos se o item possuir residuo eliminado  
		If &cFiltro
			DBSelectArea('SC7')
			DBSkip()
			Loop
		EndIf
            
		// Inicia a Carga do item nas funcoes MATXFIS  
		nItem++
		MaFisIniLoad(nItem)

		_aSC7 := SC7->(DBSTRUCT())
		For D := 1 TO Len(_aSC7)
		    _cCampo := _aSC7[D][1]
			cValid	:= StrTran(Upper(Getsx3cache(_cCampo,"X3_VALID") )," ","")
			cValid	:= StrTran(cValid,"'",'"')
			If "MAFISREF" $ cValid
				nPosRef  := AT('MAFISREF("',cValid) + 10
				cRefCols := SubStr(cValid,nPosRef,AT('","MT120",',cValid)-nPosRef )
				// Carrega os valores direto do SC7.           
				MaFisLoad(cRefCols,&("SC7->"+_cCampo),nItem)
			EndIf
		Next

		MaFisEndLoad(nItem,2)
		DBSelectArea('SC7')
		DBSkip()
	End
EndIf

FWRestArea(aAreaSC7)
FWRestArea(aArea)

Return .T.

/*
===============================================================================================================================
Programa----------: RCOM18D2
Autor-------------: Jonathan Torioni
Data da Criacao---: 17/06/2020
Descrição---------: Função criada para quebrar a observação do pc
Parametros--------: cTexto		- Descrição do Produto
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RCOM18D2(ctexto)    

Local cont        := 1        
Local cTextoQbr   := "" 

ctexto:=AllTrim(ctexto)            
             
While cont <= Len(ctexto)
	
	cTextoQbr:= AllTrim(SubStr(ctexto,cont,100))
	
	oPrint:Say (nLinha,0050,cTextoQbr,oFont10b) 
	nlinha+= 30
	
	cont+= 100  
EndDo                    

Return 
