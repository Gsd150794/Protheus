#Include "rwmake.ch"
#Include "ap5mail.ch"
#Include "tbiconn.ch"
#Include "TOTVS.ch"
#Include "MATR110.CH"

/*
===============================================================================================================================
Programa----------: RCOM006
Autor-------------: Fabiano Dias Silva
Data da Criacao---: 01/01/2010
Descrição---------: Pedido de compra desenvolvido em modelo grafico 
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RCOM006(cAlias, nReg, nOpcx,_cFil,_cNumPed)               

Local _cPerg:= "MTR110"
             
//Private cData     := DToC(DDATABASE)
Private cTitulo   := "Vendas"
Private cMensagem := OemToAnsi("Teste") + CHR(13)+CHR(10)
Private lImpInc   := .F.   

//==========================================
//Grava log de utilização da rotina
//==========================================
U_ITLOGACS()
                         
Pergunte(_cPerg,.F.)  
               
//Pilha de Chamadas 
If 'MT120FIM' $ Upper(AllTrim(ProcName(1))) 
    
 	lImpInc := .T. //Impressao na inclusao  
	DBSelectArea("SC7")
	SC7->(DBSetOrder(1))
	If SC7->(DBSeek(_cFil + _cNumPed))    
       MV_PAR01:=SC7->C7_NUM
       MV_PAR02:=SC7->C7_NUM
	EndIf     

Else

   If U_ITMsg("Imprimir em formato PDF?" ,'Impressão',"",3,2,3,,"Sim (PDF)","Não (Normal)")
      U_RCOM002()
      Return
   EndIf

	
  If !Pergunte("MTR110",.T.) 
     Return
  EndIf	

EndIf


FWMsgRun(,{|| RCOM006M(cAlias, nReg, nOpcx,_cFil,_cNumPed)},"Processando relatorio...","Aguarde")


Return               

/*
===============================================================================================================================
Programa----------: RCOM006M
Autor-------------: Fabiano Dias Silva
Data da Criacao---: 01/01/2010
Descrição---------: Função criada para gerar a impressão do relatório
Parametros--------: cAlias		- Alias da tabela corrente
				  : nReg		- N=mero do Recno
				  : nOpcx		- Opção selecionada no menu
				  : _cFil		- Filial
				  : _cNumPed	- N=mero do Pedido de Compras
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RCOM006M(cAlias, nReg, nOpcx,_cFil,_cNumPed)

Local cUserId   := RetCodUsr()
Local cCont     := Nil                         

Private nPagina     := 1//Responsavel por armazenar a numeracao da pagina 

Private lAuto		:= (nReg!=Nil)

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

	If lAuto
		MV_PAR08 := Eval({|| cCont:=ChkPergUs(cUserId,"MTR110","08"),If(cCont == Nil,SC7->C7_TIPO,cCont) })
	EndIf
	
	If lPedido
		MV_PAR12 := MAX(SC7->C7_MOEDA,1)
	EndIf                          
	
	oPrint:= TMSPrinter():New("RELATORIO DE PEDIDO DE COMPRAS")
	oPrint:SetPortrait() 	// Retrato
	oPrint:SetPaperSize(9)	// Seta para papel A4 
	//oPrint:Setup()                             
	
	// startando a impressora
	oPrint:Say(0, 0, " ",oFont11b,100)
	
	RCOM006I(cAlias,nReg, nOpcx,_cFil,_cNumPed)//Imprime os dados do Relatorio

	lPedido := .F.   
	  
Return

/*
===============================================================================================================================
Programa----------: RCOM006C
Autor-------------: Fabiano Dias Silva
Data da Criacao---: 01/01/2010
Descrição---------: Função criada para gerar o cabeçalho do relatório
Parametros--------: ncw		- N=mero da Via do relatório
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RCOM006C(ncw)

Local cRaizServer := If(issrvunix(), "/", "\")    
Local nColCentr := 0
Local cTextoSay := ""   
Local cTelFax   := ""
Local cDDD		:= ""
Local cCodFornec:= SC7->C7_FORNECE
Local cCodLjForn:= SC7->C7_LOJA     
Local _cContato := SC7->C7_CONTATO                          
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
RCOM006Q(AllTrim(SM0->M0_NOMECOM),35,oFont14bAr,30.67,0597,1165)               

//ENDERECO DA EMPRESA
RCOM006Q(AllTrim(SM0->M0_ENDCOB),41,oFont13bAr,27.68,0597,1165)               

//CEP _ CIDADE + ESTADO   
RCOM006Q(SubStr(("CEP:" + SubStr(AllTrim(SM0->M0_CEPCOB),1,2) + "." + SubStr(AllTrim(SM0->M0_CEPCOB),3,3) + "-" + SubStr(AllTrim(SM0->M0_CEPCOB),6,3) + '-' + SubStr(AllTrim(SM0->M0_CIDCOB),1,50) + '-' + AllTrim(SM0->M0_ESTCOB)),1,70),58,oFont11bAr,19.23,0597,1165)

//TELEFONE + FAX
cTextoSay:='TEL:(' + SubStr(SM0->M0_TEL,4,2) + ')' + SubStr(SM0->M0_TEL,7,4) + '-' +SubStr(SM0->M0_TEL,11,4) + ' - '+'FAX:(' + SubStr(SM0->M0_FAX,4,2) + ')' + SubStr(SM0->M0_FAX,7,4) + '-' +SubStr(SM0->M0_FAX,11,4) 
nColCentr:=RCOM006A(nColInic,1165,cTextoSay,19.23)                                                 
oPrint:Say (nLinha,0597,cTextoSay,oFont11bAr,1165,,,2)                
nlinha+=nSaltoLinha

//CNPJ        
cTextoSay:= "C.N.P.J./C.P.F.:" + RCOM006J(SM0->M0_CGC)
nColCentr:=RCOM006A(nColInic,1165,cTextoSay,27.68)   
oPrint:Say (nlinha,0597,cTextoSay,oFont13bAr,1165,,,2) // Picture "@R! NN.NNN.NNN/NNNN-99"         
nlinha+=nSaltoLinha

//INSRICAO ESTADUAL
cTextoSay:= "I.E.:" + AllTrim(SM0->M0_INSC)
nColCentr:=RCOM006A(nColInic,1165,cTextoSay,27.68)   
oPrint:Say (nlinha,0597,cTextoSay,oFont13bAr,1165,,,2)  
nlinha+=(nSaltoLinha * 3) 

//DADOS DO SEGUNDO QUADRANTE                                         
nlinha:=0100
nlinha+=nSaltoLinha                                                    

//oPrint:Say (nlinha,1582,'PEDIDO DE COMPRAS',oFont14bAr,2000,,,2)  
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

//oPrint:Say (nlinha,1582,'REAL',oFont14bAr,2000,,,2)  
oPrint:Box(nlinha - 78,1190,(nlinha - 78) + 30,1220) 
oPrint:Box(nlinha - 18,1190,(nlinha - 18) + 30,1220)    
oPrint:Box(nlinha + 42,1190,nlinha + 72,1220) 
oPrint:Box(nlinha - 78,1510,(nlinha - 78) + 30,1540)
oPrint:FillRect({nlinha - 78,1510,(nlinha - 78) + 30,1540},oBrush)
 

Case cAplic = ' ' 

//oPrint:Say (nlinha,1582,'REAL',oFont14bAr,2000,,,2)  
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
RCOM006Q(AllTrim(SA2->A2_NOME) + ' - ' + SA2->A2_COD + "/" + SA2->A2_LOJA,41,oFont13bAr,27.63,1762,2360)               
   
//ENDERECO DA EMPRESA
RCOM006Q(AllTrim(SA2->A2_END),58,oFont11bAr,19.23,1762,2360)  
//CEP + CIDADE + ESTADO
RCOM006Q(SubStr(("CEP:" + SubStr(AllTrim(SA2->A2_CEP),1,2) + "." + SubStr(AllTrim(SA2->A2_CEP),3,3) + "-" + SubStr(AllTrim(SA2->A2_CEP),6,3) + '-' + SubStr(AllTrim(SA2->A2_MUN),1,50) + '-' + AllTrim(SA2->A2_EST)),1,70),58,oFont11bAr,19.23,1762,2360)
//TELEFONE + FAX   

cDDD:=IIf(Len(AllTrim(SA2->A2_DDD))==3,SubStr(SA2->A2_DDD,2,2),SubStr(SA2->A2_DDD,1,2))

If Len(AllTrim(SA2->A2_TEL)) > 2
    
    cTelFax:="TEL:("+cDDD+")"+ SubStr(SA2->A2_TEL,1,4) + '-' +SubStr(SA2->A2_TEL,5,4) + " "  
	
EndIf           

If Len(AllTrim(SA2->A2_FAX)) > 2
    
    cTelFax+="FAX:("+cDDD+")"+ SubStr(SA2->A2_FAX,1,4) + '-' +SubStr(SA2->A2_FAX,5,4) 
	
EndIf            

If Len(AllTrim(cTelFax)) > 1
   
	cTextoSay:= cTelFax
	nColCentr:=RCOM006A(1166,2360,cTextoSay,19.23)                                                 
	
	oPrint:Say (nLinha,1762,cTextoSay,oFont11bAr,2360,,,2)                
	nlinha+=nSaltoLinha

EndIf
//CNPJ               
cTextoSay:= "C.N.P.J./C.P.F.:" + RCOM006J(SA2->A2_CGC) + " I.E.:" + AllTrim(SA2->A2_INSCR)

oPrint:Say (nlinha,1762,cTextoSay,oFont11bAr,2360,,,2) // Picture "@R! NN.NNN.NNN/NNNN-99"         
nlinha+=nSaltoLinha                  

//CONTATO
cTextoSay:= SubStr("CONTATO:" + AllTrim(_cContato),1,35)

oPrint:Say (nlinha,1762,cTextoSay,oFont13bAr,2360,,,2)         
nlinha+=nSaltoLinha * 2 
                                                   

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
oPrint:Say (nlinha,1540,"Vlr.Unitar.",oFont10)
//oPrint:Say (nlinha,1730,"IPI",oFont11b)
oPrint:Say (nlinha,1790,"Valor Total",oFont10)
oPrint:Say (nlinha,1955,"Dt.Entrega",oFont10)

//Verifica se sera impresso o ultimo preco de venda
If MV_PAR16 == 1
	oPrint:Say (nlinha,2140,"Ul.Prc.Compra",oFont10)
EndIf	

nlinha+=nSaltoLinha                                              

//RESTAURA A AREA DA SC7
FWRestArea(cAreaSC7)     

Return                                                                                                                                    

/*
===============================================================================================================================
Programa----------: RCOM006A
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
Static Function RCOM006A(nColIni,nColFin,cTexto,nTamLetra)

Local nColuna:= 0
      
	nColuna:=nColIni + Int(((nColFin-nColIni) - (Len(cTexto)* nTamLetra))/2)

Return nColuna

/*
===============================================================================================================================
Programa----------: RCOM006Q
Autor-------------: Fabiano Dias Silva
Data da Criacao---: 01/01/2010
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
Static Function RCOM006Q(ctexto,nCaracteres,cFonte,nTamCaract,nColIn,nColFim)

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
Programa----------: RCOM006J
Autor-------------: Fabiano Dias Silva
Data da Criacao---: 01/01/2010
Descrição---------: Função criada para formatar CPF/CNPJ
Parametros--------: cCPFCNPJ	- Texto a ser quebrado
Retorno-----------: cCampFormat	- Retorna o campo formatado conforme CPF/CNPJ
===============================================================================================================================
*/
Static Function RCOM006J(cCPFCNPJ)

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
Programa----------: RCOM006I
Autor-------------: Fabiano Dias Silva
Data da Criacao---: 01/01/2010
Descrição---------: Função criada para imprimir o relatório
Parametros--------: cAlias		- Alias da tabela
				  : nReg		- N=mero do registro (RECNO)
				  : nOpcx		- Opção selecionada no menu
				  : _cFil		- Filial
				  : _cNumPed	- N=mero do Pedido de Compras
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RCOM006I(cAlias,nReg,nOpcx,_cFil,_cNumPed)
      
Local nReem , ncw
Local nOrder
Local cCondBus
Local nSavRec
Local aPedido 	:= {}
Local aPedMail	:= {}
Local aSavRec 	:= {}
Local i       	:= 0
Local cFiltro 	:= ""
Local cUserId 	:= RetCodUsr()
Local cCont   	:= Nil
Local lImpri    := .F.    

Private _aPedInter:= {}

Private cCGCPict, cCepPict

//Private ncw     := 0

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

If lAuto
	DBSelectArea("SC7")
	DBGoTo(nReg)
	SetRegua(1)
	MV_PAR01 := C7_NUM
	MV_PAR02 := C7_NUM
	MV_PAR03 := C7_EMISSAO
	MV_PAR04 := C7_EMISSAO
	MV_PAR05 := Eval({|| cCont:=ChkPergUs(cUserId,"MTR110","05"),If(cCont == Nil,2,cCont) })
   	MV_PAR08 := Eval({|| cCont:=ChkPergUs(cUserId,"MTR110","08"),If(cCont == Nil,C7_TIPO,cCont) })
	MV_PAR09 := Eval({|| cCont:=ChkPergUs(cUserId,"MTR110","09"),If(cCont == Nil,1,cCont) })
  	MV_PAR10 := Eval({|| cCont:=ChkPergUs(cUserId,"MTR110","10"),If(cCont == Nil,3,cCont) }) 
	MV_PAR11 := Eval({|| cCont:=ChkPergUs(cUserId,"MTR110","11"),If(cCont == Nil,3,cCont) }) 
  	MV_PAR14 := Eval({|| cCont:=ChkPergUs(cUserId,"MTR110","14"),If(cCont == Nil,1,cCont) }) 
EndIf                  

//If ( cPaisLoc$"ARG|POR|EUA" )
//	cCondBus	:=	"1"+StrZero(Val(MV_PAR01),6)
//	nOrder	:=	10
//	nTipo		:= 1
//Else
	If lImpInc //Tratamento pedidos Automatico/Manual - Guilherme 19/10/2012  
   		MV_PAR01 := _cNumPed
		MV_PAR02 := _cNumPed
		cCondBus := MV_PAR01
	Else
		cCondBus := MV_PAR01
		nOrder	 :=	1 
	EndIf
//EndIf

If MV_PAR14 == 2
	cFiltro := "SC7->C7_QUANT-SC7->C7_QUJE <= 0 .Or. !Empty(SC7->C7_RESIDUO)"
ElseIf MV_PAR14 == 3
	cFiltro := "SC7->C7_QUANT > SC7->C7_QUJE"
EndIf                                                        
                                    
SB1->(DBSetOrder(1))

DBSelectArea("SC7") 
SC7->(DBSetOrder(nOrder))
SC7->(DBSeek(xFilial("SC7")+cCondBus,.T.))


While SC7->(!Eof()) .And. C7_FILIAL = xFilial("SC7") .And. C7_NUM >= MV_PAR01 .And. ;
		C7_NUM <= MV_PAR02

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

	If	C7_EMITIDO == "S" .And. MV_PAR05 == 1
		DBSkip()
		Loop
	EndIf
	
	If	(C7_CONAPRO == "B" .And. MV_PAR10 == 1) .Or.;
		(C7_CONAPRO != "B" .And. MV_PAR10 == 2)
		DBSkip()
		Loop
	EndIf
	
	If	(C7_EMISSAO < MV_PAR03) .Or. (C7_EMISSAO > MV_PAR04)
		DBSkip()
		Loop
	EndIf
	
	If	C7_TIPO == 2
		DBSkip()
		Loop
	EndIf

	//================================================================
	// Consiste este item. EM ABERTO                                
	//================================================================
	If MV_PAR14 == 2
		If SC7->C7_QUANT-SC7->C7_QUJE <= 0 .Or. !Empty(SC7->C7_RESIDUO)
			DBSelectArea("SC7")
			DBSkip()
			Loop
		EndIf
	EndIf

	//================================================================
	// Consiste este item. ATENDIDOS                                
	//================================================================
	If MV_PAR14 == 3
		If SC7->C7_QUANT > SC7->C7_QUJE
			DBSelectArea("SC7")
			DBSkip()
			Loop
		EndIf
	EndIf

	//================================================================
	// Filtra Tipo de SCs Firmes ou Previstas                       
	//================================================================
	If !MtrAValOP(MV_PAR11, 'SC7')
		DBSkip()
		Loop
	EndIf

	MaFisEnd()
	RCOM0061(SC7->C7_NUM,,,cFiltro)
	
	For ncw := 1 To MV_PAR09		// Imprime o numero de vias informadas
        
		oPrint:StartPage()          //Inicia uma nova pagina a cada novo produtor
		nPagina  := 1 				//Variavel que controla o numero da pagina atual
		RCOM006C(ncw)				//Imprime cabecalho
	                 
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
			//================================================================
			// Consiste este item. EM ABERTO                                
			//================================================================
			If MV_PAR14 == 2
				If SC7->C7_QUANT-SC7->C7_QUJE <= 0 .Or. !Empty(SC7->C7_RESIDUO)
					DBSelectArea("SC7")
					DBSkip()
					Loop
				EndIf
			EndIf

			//================================================================
			// Consiste este item. ATENDIDOS                                
			//================================================================
			If MV_PAR14 == 3
				If SC7->C7_QUANT > SC7->C7_QUJE
					DBSelectArea("SC7")
					DBSkip()
					Loop
				EndIf
			EndIf

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
				RCOM006C(ncw)  
			EndIf

			//================================================================
			// Pesquisa Descricao do Produto                                
			//================================================================			
			RCOM006P()  

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
				RCOM006S(ncw)
		EndIf

        //Espaco em branco entre os produtos e a parte resumida do relatorio
		nLinha:=IIf(nLinha < 2150,2150,nLinha)
		oPrint:Line(nlinha,0030,nlinha,2360) 
		RCOM006R(nDescProd)		// Imprime os dados complementares do PC passando o desconto dos produtos como parametro
    
	    oPrint:EndPage()	// Finaliza a Pagina.
	
	Next

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
Programa----------: RCOM006P
Autor-------------: Fabiano Dias Silva
Data da Criacao---: 01/01/2010
Descrição---------: Função criada para Imprimir as informações do Produto
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RCOM006P()     

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
			If Empty(MV_PAR06)
				MV_PAR06 := "B1_DESC"
			EndIf
			
			If AllTrim(MV_PAR06) == "B1_DESC"
				SB1->(DBSetOrder(1))
				SB1->(DBSeek( xFilial("SB1") + SC7->C7_PRODUTO ))
				cDescPro := AllTrim(SB1->B1_DESC)
			ElseIf AllTrim(MV_PAR06) == "B5_CEME"
				SB5->(DBSetOrder(1))
				If SB5->(DBSeek( xFilial("SB5") + SC7->C7_PRODUTO ))
					cDescPro := AllTrim(SB5->B5_CEME)
				EndIf
			ElseIf AllTrim(MV_PAR06) == "C7_DESCRI"
				cDescPro := AllTrim(SC7->C7_DESCRI)

			ElseIf AllTrim(MV_PAR06) == "SELECIONAR"	// Customizacao para selecionar qual descricao sera utilizada

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
			
			If MV_PAR17 = 1
			
			If !Empty(SC7->C7_OBS) .And. nLinObs < 1
				nLinObs++
				cVar:="cObs"+StrZero(nLinObs,2)
				Eval(MemVarBlock(cVar),SC7->C7_OBS)
			EndIf
			EndIf
			
			nTxMoeda   := IIf(SC7->C7_TXMOEDA > 0,SC7->C7_TXMOEDA,Nil)
			nValTotSC7 := xMoeda(SC7->C7_TOTAL,SC7->C7_MOEDA,MV_PAR12,SC7->C7_DATPRF,MsDecimais(SC7->C7_MOEDA),nTxMoeda)
			
			nTotal     := nTotal + SC7->C7_TOTAL
  			nTotMerc   := MaFisRet(,"NF_TOTAL")
//          nTotMerc   := nTotIpi+_nVALORICMS+nTotal//AWF - TESTE
                                         
			
			If MV_PAR07 == 2 .And. !Empty(SC7->C7_QTSEGUM) .And. !Empty(SC7->C7_SEGUM)
				cUniMedida := SC7->C7_SEGUM
				cQuantidade:= SC7->C7_QTSEGUM
				nVlUnitSC7 := xMoeda((SC7->C7_TOTAL/SC7->C7_QTSEGUM),SC7->C7_MOEDA,MV_PAR12,SC7->C7_DATPRF,MsDecimais(SC7->C7_MOEDA),nTxMoeda)
			ElseIf MV_PAR07 <> 2
				cUniMedida := SC7->C7_UM
				cQuantidade:= SC7->C7_QUANT
				nVlUnitSC7 := xMoeda(SC7->C7_PRECO,SC7->C7_MOEDA,MV_PAR12,SC7->C7_DATPRF,MsDecimais(SC7->C7_MOEDA),nTxMoeda)   
			EndIf
			
			If  MV_PAR08 == 2
				cIPI:=0
			Else
				cIPI:=SC7->C7_IPI
			EndIf
	                                          
//Imprime dados dos produtos
nLinFinal:=RCOM006L(cDescPro)                  

oPrint:Say (nlinha,0040,SC7->C7_ITEM,oFont10b)        
oPrint:Say (nlinha,0140,SC7->C7_PRODUTO,oFont10b)
oPrint:Say (nlinha,1145,cUniMedida,oFont10b)
oPrint:Say (nlinha,1425,transform(cQuantidade,PesqPict("SC7","C7_QUANT")),oFont10b,,,,1)
oPrint:Say (nlinha,1680,transform(nVlUnitSC7,"@E 99,999,999.99999"),oFont10b,,,,1)
//oPrint:Say (nlinha,1690,transform(cIPI,PesqPict("SC7","C7_IPI")),oFont10b)
oPrint:Say (nlinha,1930,transform(nValTotSC7,PesqPict("SC7","C7_TOTAL")),oFont10b,,,,1)
oPrint:Say (nlinha,1970,DToC(SC7->C7_DATPRF),oFont10b)					
    
//Verifica se sera impresso o ultimo preco de venda
If MV_PAR16 == 1
	oPrint:Say (nlinha,2345,Transform(Posicione("SB1",1,xFilial("SB1") + SC7->C7_PRODUTO,"SB1->B1_UPRC"),"@E 999,999,999.99"),oFont10b,,,,1)
EndIf

RCOM006D(cDescPro)//Descricao do produto

FWRestArea(aAreaSC7)      

Return

/*
===============================================================================================================================
Programa----------: RCOM006D
Autor-------------: Fabiano Dias Silva
Data da Criacao---: 01/01/2010
Descrição---------: Função criada para quebrar a descrição do produto
Parametros--------: cTexto		- Descrição do Produto
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RCOM006D(ctexto)    

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
Programa----------: RCOM006L
Autor-------------: Fabiano Dias Silva
Data da Criacao---: 01/01/2010
Descrição---------: Função criada para criar o grupo de perguntas
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RCOM006L(ctexto)

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
Programa----------: RCOM006R
Autor-------------: Fabiano Dias Silva
Data da Criacao---: 01/01/2010
Descrição---------: Função criada para imprimir o resumo do pedido de compras
Parametros--------: nDescProd	- Desconto do produto
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RCOM006R(nDescProd)

//Local nG		:= 0
Local nX		:= 0
//Local nQuebra	:= 0
Local nTotDesc	:= nDescProd
//Local lImpLeg	:= .T.
//Local lImpLeg2:= .F.
Local cUrgen	:= ""
//Local nTotIpi	:= MaFisRet(,'NF_VALIPI')
//Local nTotIcms:= MaFisRet(,'NF_VALICM')
Local nTotDesp	:= MaFisRet(,'NF_DESPESA')
Local nTotFrete	:= MaFisRet(,'NF_FRETE')
Local nTotalNF	:= MaFisRet(,'NF_TOTAL')
Local nTotSeguro:= MaFisRet(,'NF_SEGURO')
//Local aValIVA := MaFisRet(,"NF_VALIMP")
//Local nValIVA := 0
//Local aColuna := Array(8), nTotLinhas
Local nTxMoeda  := IIf(SC7->C7_TXMOEDA > 0,SC7->C7_TXMOEDA,Nil)
Local aAreaSC7  := SC7->(GetArea())               
Local nLiPosIni    
Local nLinInReaj
Local nlinInTran             
Local _cUsrNome           
Local _cPedInter := ""

cMensagem:= Formula(SC7->C7_MSG)

//IMPRIME OS NUMERO DOS PEDIDOS INTERNOS PASSADOS VIA BLOCO AO SETOR DE COMPRAS PARA SOLICITAR A COMPRA NO MICROSIGA
//SOMENTE SERA IMPRESSO CASO HAJA ALGUM PEDIDO INTERNO LANCADO 
RCOM006G(3250)

If Len(_aPedInter) > 0   

	aEval(_aPedInter,{|e| _cPedInter += "," + AllTrim(e[1])})               

	oPrint:Say (nlinha,nColInic,"Pedido(s) Interno(s): " +  SubStr(_cPedInter,2,Len(_cPedInter)),oFont10)
	nlinha+=nSaltoLinha
	oPrint:Line(nlinha,0030,nlinha,2360)   
	
EndIf

//DESCONTOS
RCOM006G(3250)

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

RCOM006G(3200)               

//================================================================
// Imprime endereco de entrega do SM0 somente se o MV_PAR13 =" "
//================================================================
If Empty(MV_PAR13)            
	oPrint:Say (nlinha,nColInic,SubStr("Local de Entrega: " + AllTrim(SubStr(SM0->M0_ENDENT,1,50)) + '-' + AllTrim(SubStr(SM0->M0_CIDENT,1,35)) + '-' + SM0->M0_ESTENT + '-' + Trans(AllTrim(SM0->M0_CEPENT),cCepPict),1,75),oFont10End)
	//nlinha+=nSaltoLinha
Else                   
	oPrint:Say (nlinha,nColInic,SubStr("Local de Entrega: " + SubStr(AllTrim(MV_PAR13),1,100),1,75),oFont10End)
	//nlinha+=nSaltoLinha
EndIf   
                                   
If Empty(MV_PAR15)

	SM0->(DBSetOrder(1))   // forca o indice na ordem certa
	SM0->(DBSeek(SUBS(cNumEmp,1,2) + cFilAnt))   

	oPrint:Say (nlinha,1210,SubStr("Local de Cobranca: " + AllTrim(SubStr(SM0->M0_ENDCOB,1,50)) + '-' + AllTrim(SubStr(SM0->M0_CIDCOB,1,35)) + '-' + SM0->M0_ESTCOB + '-' + Trans(AllTrim(SM0->M0_CEPCOB),cCepPict),1,75),oFont10End)
	nlinha+=nSaltoLinha           

Else

	//Local de Cobranca                        
	SM0->(DBSetOrder(1))   // forca o indice na ordem certa
	SM0->(DBSeek(SUBS(cNumEmp,1,2) + MV_PAR15))
	
	oPrint:Say (nlinha,1210,SubStr("Local de Cobranca: " + AllTrim(SubStr(SM0->M0_ENDCOB,1,50)) + '-' + AllTrim(SubStr(SM0->M0_CIDCOB,1,35)) + '-' + SM0->M0_ESTCOB + '-' + Trans(AllTrim(SM0->M0_CEPCOB),cCepPict),1,75),oFont10End)
	nlinha+=nSaltoLinha 
		                    
	SM0->(DBSetOrder(1))   // forca o indice na ordem certa
	SM0->(DBSeek(SUBS(cNumEmp,1,2) + cFilAnt))        

EndIf                    

oPrint:Line(nlinha				,0030,nlinha,2360)
oPrint:Line(nlinha - nSaltoLinha,1200,nlinha,1200)    //Linha divisoria

oPrint:Say (nlinha,nColInic,"E-mail para envio do XML - NF-e: " + _cEmailXML,oFont10b)

oPrint:Line(nlinha + nSaltoLinha,1377,nlinha,1377)    //Linha divisoria

oPrint:Say (nlinha,1382,"Total das Mercadorias:",oFont10)
oPrint:Say (nlinha,2350,Transform(xMoeda(nTotal,SC7->C7_MOEDA,MV_PAR12,SC7->C7_DATPRF,MsDecimais(SC7->C7_MOEDA),nTxMoeda),tm(nTotal,14,MsDecimais(MV_PAR12))),oFont14bAr,,,,1)

nlinha+=nSaltoLinha

oPrint:Line(nlinha,0030,nlinha,2360)   

FWRestArea(aAreaSC7)

//Condicao de pagamento + data de emissao + total das mercadorias + total das mercadorias com impostos
DBSelectArea("SE4")
DBSetOrder(1)
DBSeek(xFilial("SE4") + SC7->C7_COND)          

_cUsrNome := FWSFAllUsers({_cUserDig})[1][3]

DBSelectArea("SC7")                 

RCOM006G(3200)
nLiPosIni:=nlinha

oPrint:Say (nlinha,nColInic,"Condicao de Pagamento",oFont10)  
oPrint:Say (nlinha,0460,"Digitado por",oFont10)
oPrint:Say (nlinha,0806,"Data de Emissao",oFont10)

//Total com Impostos
oPrint:Say (nlinha,1382,"Total com Impostos:" ,oFont10)
oPrint:Say (nlinha,2350,Transform(xMoeda(nTotMerc,SC7->C7_MOEDA,MV_PAR12,SC7->C7_DATPRF,MsDecimais(SC7->C7_MOEDA),nTxMoeda),tm(nTotMerc,14,MsDecimais(MV_PAR12))),oFont14bAr,,,,1)

nlinha+=nSaltoLinha
oPrint:Line(nlinha,1377,nlinha,2360)//Divisoria total com impostos

oPrint:Say (nlinha,nColInic,SubStr(SE4->E4_DESCRI,1,20),oFont14bAr)
oPrint:Say (nlinha+10,0460,AllTrim(_cUsrNome),oFont10b)
oPrint:Say (nlinha,0806,DToC(SC7->C7_EMISSAO),oFont14bAr)

//Total de Descontos
oPrint:Say (nlinha,1382,"Total de Descontos:" ,oFont10)
oPrint:Say (nlinha,2350,Transform(xMoeda(nTotDesc,SC7->C7_MOEDA,MV_PAR12,SC7->C7_DATPRF,MsDecimais(SC7->C7_MOEDA),nTxMoeda),PesqPict("SC7","C7_VLDESC",14, MsDecimais(MV_PAR12))),oFont14bAr,,,,1)

nlinha+=nSaltoLinha

oPrint:Line(nlinha,0030,nlinha,2360) 
  
oPrint:Line(nLiPosIni,0455,nlinha,0455)
oPrint:Line(nLiPosIni,0800,nlinha,0800) 
oPrint:Line(nLiPosIni,1377,nlinha,1377)

//OBSERVACOES + IPI + FRETE + ICMS + DESPESAS + SEGURO  + GRUPO

//================================================================
// Inicializar campos de Observacoes.                           
//================================================================
		If Empty(cObs02)
			If Len(cObs01) > 50
				cObs := cObs01
				cObs01 := SubStr(cObs,1,50)
				For nX := 2 To 5
					cVar  := "cObs"+StrZero(nX,2)
					&cVar := SubStr(cObs,(50*(nX-1))+1,50)
				Next nX
			EndIf
		Else
			cObs01:= SubStr(cObs01,1,IIf(Len(cObs01)<50,Len(cObs01),50))
			cObs02:= SubStr(cObs02,1,IIf(Len(cObs02)<50,Len(cObs01),50))
			cObs03:= SubStr(cObs03,1,IIf(Len(cObs03)<50,Len(cObs01),50))
			cObs04:= SubStr(cObs04,1,IIf(Len(cObs04)<50,Len(cObs01),50))
			cObs05:= SubStr(cObs05,1,IIf(Len(cObs05)<50,Len(cObs01),50))
		EndIf  

RCOM006G(3000)
nLiPosIni:=nlinha                 

oPrint:Say (nlinha,0030,"Observações:",oFont10)
oPrint:Say (nlinha,1210,"IPI:",oFont10)
oPrint:Say (nlinha,1745,"ICMS:",oFont10)

oPrint:Say (nlinha,1735,Transform(xMoeda(nTotIPI,SC7->C7_MOEDA,MV_PAR12,SC7->C7_DATPRF,MsDecimais(SC7->C7_MOEDA),nTxMoeda),tm(nTotIPI,14,MsDecimais(MV_PAR12))),oFont14bAr,,,,1)
oPrint:Say (nlinha,2350,Transform(xMoeda(nTotIcms,SC7->C7_MOEDA,MV_PAR12,SC7->C7_DATPRF,MsDecimais(SC7->C7_MOEDA),nTxMoeda),tm(nTotIcms,14,MsDecimais(MV_PAR12))),oFont14bAr,,,,1)
    
nlinha+=nSaltoLinha                     
oPrint:Line(nlinha,1200,nlinha,2360)    //Linha divisoria

oPrint:Say (nlinha,0030,cObs01,oFont11b)//Obsevacao 1

oPrint:Say (nlinha,1210,"Frete: ",oFont10)
oPrint:Say (nlinha,1745,"Despesas: ",oFont10)

oPrint:Say (nlinha,1735,Transform(xMoeda(nTotFrete,SC7->C7_MOEDA,MV_PAR12,SC7->C7_DATPRF,MsDecimais(SC7->C7_MOEDA),nTxMoeda),tm(nTotFrete,14,MsDecimais(MV_PAR12))),oFont14bAr,,,,1)
oPrint:Say (nlinha,2350,Transform(xMoeda(nTotDesp,SC7->C7_MOEDA,MV_PAR12,SC7->C7_DATPRF,MsDecimais(SC7->C7_MOEDA),nTxMoeda),tm(nTotDesp,14,MsDecimais(MV_PAR12))),oFont14bAr,,,,1)

nlinha+=nSaltoLinha         
oPrint:Line(nlinha,1200,nlinha,2360)

oPrint:Say (nlinha,0030,cObs02,oFont11b)//Obsevacao 2
                                              
oPrint:Say (nlinha,1210,"Grupo: ",oFont10)
oPrint:Say (nlinha,1745,"Seguro: ",oFont10)

oPrint:Say (nlinha,2350,Transform(xMoeda(nTotSeguro,SC7->C7_MOEDA,MV_PAR12,SC7->C7_DATPRF,MsDecimais(SC7->C7_MOEDA),nTxMoeda),tm(nTotSeguro,14,MsDecimais(MV_PAR12))),oFont14bAr,,,,1)
                                    
nlinha+=nSaltoLinha                 
oPrint:Line(nlinha,1200,nlinha,2360)  
oPrint:Line(nLiPosIni,1740,nlinha,1740) //Coluna ICMS     

oPrint:Say (nlinha,0030,cObs03,oFont11b)//Obsevacao 3                                                     

oPrint:Say (nlinha,1210,"Total Geral:  ",oFont14bAr)

oPrint:Say(nlinha,2350,Transform(xMoeda(nTotalNF,SC7->C7_MOEDA,MV_PAR12,SC7->C7_DATPRF,MsDecimais(SC7->C7_MOEDA),nTxMoeda),tm(nTotalNF,14,MsDecimais(MV_PAR12))),oFont14bAr,,,,1)

nlinha+= nSaltoLinha 
oPrint:Line(nlinha,1200,nlinha,2360)              
nLinInReaj:= nLinha

oPrint:Say (nlinha,0030,cObs04,oFont11b)//Obsevacao 4                              

oPrint:Say (nlinha,1210,"Obs. do Frete: ",oFont10)  
oPrint:Say (nlinha,1600,"Reajuste: ",oFont10)  

nlinha+=nSaltoLinha                                                         

oPrint:Say (nlinha,0030,cObs05,oFont11b)//Obsevacao 5

oPrint:Say (nlinha,1210,If( SC7->C7_TPFRETE $ "F","FOB",If(SC7->C7_TPFRETE $ "C","CIF"," " )),oFont14bAr)  

SM4->(DBSetOrder(1))
If SM4->(DBSeek(xFilial("SM4")+SC7->C7_REAJUST))  
	oPrint:Say (nlinha,1600,SC7->C7_REAJUST + "-" + SubStr(SM4->M4_DESCR,1,18),oFont11b)
EndIf

nlinha+=nSaltoLinha                  

oPrint:Line(nlinha,0030,nlinha,2360)     //Linha que finaliza a observacao
oPrint:Line(nLinInReaj,1595,nlinha,1595) //Coluna Reajuste
oPrint:Line(nLiPosIni,1200,nlinha,1200) //Coluna Observacao               

RCOM006G(2750)                                                           
nlinInTran:=nLinha 

oPrint:Say (nlinha,0050,STR0021,oFont11b)//Comprador
oPrint:Say (nlinha,0430,STR0022,oFont11b)//Gerencia
oPrint:Say (nlinha,0820,STR0023,oFont11b)//Diretoria

oPrint:Say (nlinha,1210,"Transportadora" + If( SC7->C7_I_CDTRA <> "      ", " - Código: " + SC7->C7_I_CDTRA + "  Loja: " + SC7->C7_I_LJTRA , " "),oFont11b)		
nlinha+=nSaltoLinha

oPrint:Say (nlinha,1210,If( SC7->C7_I_CDTRA <> "      ", "Razão Social: " + SubStr(Posicione("SA2", 1, xFilial("SA2")+SC7->C7_I_CDTRA+SC7->C7_I_LJTRA,"A2_NOME"),1,30)," "),oFont11b)
nlinha+=nSaltoLinha
oPrint:Say (nlinha,1210,If( SC7->C7_I_CDTRA <> "      ", "CNPJ: " + Transform(Posicione("SA2", 1, xFilial("SA2")+SC7->C7_I_CDTRA+SC7->C7_I_LJTRA, "A2_CGC"), PesqPict("SA2","A2_CGC")), " "),oFont11b)//Gerencia
oPrint:Say (nlinha,1750,If( SC7->C7_I_CDTRA <> "      ", "Ins. Estad.: " + Posicione("SA2", 1, xFilial("SA2")+SC7->C7_I_CDTRA+SC7->C7_I_LJTRA, "A2_INSCR"), " "),oFont11b)
nlinha+=nSaltoLinha
			
oPrint:Say (nlinha,1210,If( SC7->C7_I_CDTRA <> "      ", "Cidade: " + SubStr(Posicione("SA2", 1, xFilial("SA2")+SC7->C7_I_CDTRA+SC7->C7_I_LJTRA, "A2_MUN"),1,30), " "),oFont11b)
nlinha+=nSaltoLinha
oPrint:Say (nlinha,1210,If( SC7->C7_I_CDTRA <> "      ", "Bairro: " + SubStr(Posicione("SA2", 1, xFilial("SA2")+SC7->C7_I_CDTRA+SC7->C7_I_LJTRA, "A2_BAIRRO"),1,25), " "),oFont11b)
oPrint:Say (nlinha,2100,If( SC7->C7_I_CDTRA <> "      ", "Estado: " + Posicione("SA2", 1, xFilial("SA2")+SC7->C7_I_CDTRA+SC7->C7_I_LJTRA, "A2_EST"), " "),oFont11b)
			
nlinha+=nSaltoLinha
			
oPrint:Say (nlinha,1210,If( SC7->C7_I_CDTRA <> "      ", "Nome Fantasia: " + SubStr(Posicione("SA2", 1, xFilial("SA2")+SC7->C7_I_CDTRA+SC7->C7_I_LJTRA, "A2_NREDUZ"),1,30), " "),oFont11b)
			
//Imprime as linhas das Assinaturas do comprador, gerencia e diretoria
oPrint:Line(nLinha,0050,nlinha,0400)    //Linha comprador
oPrint:Line(nLinha,0440,nlinha,0790)    //Linha comprador
oPrint:Line(nLinha,0830,nlinha,1180)    //Linha comprador

nlinha+=nSaltoLinha
			
oPrint:Say (nlinha,1210,If( SC7->C7_I_CDTRA <> "      ", "Telefone: (" + AllTrim(Posicione("SA2", 1, xFilial("SA2")+SC7->C7_I_CDTRA+SC7->C7_I_LJTRA, "A2_DDD")) + ")" + Posicione("SA2", 1, xFilial("SA2")+SC7->C7_I_CDTRA+SC7->C7_I_LJTRA, "A2_TEL"), " "),oFont11b)
nlinha+=nSaltoLinha
		
oPrint:Say (nlinha,1210,If( SC7->C7_I_CDTRA <> "      ", "Contato: " + Posicione("SA2", 1, xFilial("SA2")+SC7->C7_I_CDTRA+SC7->C7_I_LJTRA, "A2_CONTATO"), " "),oFont11b)            
nlinha+=nSaltoLinha
			
oPrint:Say (nlinha,1210,If( SC7->C7_I_CDTRA <> "      ", "Obs. Frete: " + If(SC7->C7_I_TPFRT == "1","Entregar na Transportadora","Solicitar Coleta pela Transportadora" ), " "),oFont11b)            
nlinha+=nSaltoLinha     
			
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
Programa----------: RCOM006G
Autor-------------: Fabiano Dias Silva
Data da Criacao---: 01/01/2010
Descrição---------: Função criada para quebrar página
Parametros--------: numero		- N=mero de linhas
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RCOM006G(numero)
      
	//quando acaba de imprimir os produtos e se chega no final da pagina     
	//final da pagina 3300
	If nLinha > numero                    
		//Imprime box 
		oPrint:Box(nLinhaInic,0030,nLinha,nColFinal)
		oPrint:EndPage()	// Finaliza a Pagina.
		oPrint:StartPage()	// Inicia uma nova pagina                  
		nLinha:=0100        
		nPagina++
	EndIf

Return

/*
===============================================================================================================================
Programa----------: RCOM006S
Autor-------------: Fabiano Dias Silva
Data da Criacao---: 01/01/2010
Descrição---------: 
Parametros--------: numero		- N=mero de linhas
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RCOM006S(ncw)

Local cRaizServer := If(issrvunix(), "/", "\")    
      
	//Seta a posicao inicial do cabecalho        
	oPrint:SayBitmap(20,nColInic + 20,cRaizServer + "system/lgrl01.bmp",200,080)   
	nLinha :=0100                                                                
	
	//Funcao RCOM006A utilizada para pegar a coluna inicial em que devera comecar o texto
	//para que ele fique alinhado centradalizado de acordo com a coluna inicial e final
	//24.15 eh o tamanho que cada caractere para a fonte de tamanho 14 ocupa
	nColCentr:=RCOM006A(nColInic,nColFinal,'PEDIDO DE COMPRAS No.',29.10)                                                 
	
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
Programa----------: RCOM0061
Autor-------------: Edson Maricate
Data da Criacao---: 20/05/2000
Descrição---------: Inicializa as funções Fiscais com o Pedido de Compras
Parametros--------: ExpC1	- N=mero do Pedido
				  : ExpC2	- Item do Pedido
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RCOM0061(cPedido,cItem,cSequen,cFiltro)

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
