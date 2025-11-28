/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |25/10/2017| Chamado 22184. Compatibilização do fonte nas normas da P12 e correção nos totalizadores
Lucas Borges  |21/06/2019| Chamado 28346. Revisão de fontes.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RGLT040
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 16/01/2010
Descrição---------: Gera relatorio para que o fretista responsavel por coletar o leite efetue a insercao dos dados da coleta de
					leite a granel.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RGLT040()

Private nLinhaInic  := 0100
Private nLinha      := 0100
Private nColInic    := 0030
Private nColFinal   := 2360  
Private nSaltoLinha := 75       
Private nPagina     := 1
Private oFont10
Private oFont11
Private oFont12b   
Private oFont13b
Private oFont15b
Private oFont16b
Private oPrint         
Private nLiInDados  := 0
Private cPerg		:="RGLT040"                                              
Private oBrush      := TBrush():New( ,CLR_LIGHTGRAY)

Define Font oFont10    Name "Courier New"       Size 0,-08       // Tamanho 10 Negrito
Define Font oFont11    Name "Arial"             Size 0,-09       // Tamanho 11 
Define Font oFont12b   Name "Courier New"       Size 0,-10 Bold  // Tamanho 12 Negrito
Define Font oFont13b   Name "Courier New"       Size 0,-11 Bold  // Tamanho 13 Negrito  
Define Font oFont15b   Name "Courier New"       Size 0,-13 Bold  // Tamanho 15 Negrito
Define Font oFont16b   Name "Courier New"       Size 0,-14 Bold  // Tamanho 16 Negrito     

If !Pergunte(cPerg,.T.) 
	Return
EndIf


oPrint:= TMSPrinter():New("CONTROLE DE COLETA DE LEITE")
oPrint:SetPortrait() 	// Retrato
oPrint:SetPaperSize(9)	// Seta para papel A4 
	
// startando a impressora
oPrint:Say(0, 0, " ",oFont10,100)

Processa({|| DadosColLt() })

oPrint:Preview()	// Visualiza antes de Imprimir.
                            
Return                      

/*
===============================================================================================================================
Programa----------: Cabecalho
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 16/01/2010
Descrição---------: Imprime parte superior do relatório com as instruções para coleta
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function Cabecalho()      

Local cTexto   := ""   
Local cRaizServer := If(issrvunix(), "/", "\")    
Local _cRegistro  := IIf(cFilAnt == "20",":REG-PROC SCPL - 01","")

oPrint:SayBitmap(nLinha,0100,cRaizServer + "system/lgrl01.bmp",250,100)   
	
nLinha:= nLinhaInic	

cTexto:= "CONTROLE DE COLETA DE LEITE A GRANEL" + _cRegistro
oPrint:Say (nlinha,nColFinal / 2,cTexto,oFont16b,nColFinal,,,2)              
   
nlinha+=nSaltoLinha * 2                            
oPrint:Line(nLinha - 50,nColInic - 5,nLinha - 50,nColFinal)

oPrint:Say (nLinha,nColInic,"Procedimento para coleta de leite em tanque de Expansão:",oFont12b)
nlinha+=nSaltoLinha

oPrint:Say (nLinha,nColInic + 100,"1 - Ligar o agitador para que possa ser homogenizado o leite.",oFont10)
nlinha+=nSaltoLinha
oPrint:Say (nLinha,nColInic + 100,"2 - Verificar a temperatura do leite e conferir com o termômetro do leite.",oFont10)
nlinha+=nSaltoLinha
oPrint:Say (nLinha,nColInic + 100,"3 - Fazer alizarol do leite.",oFont10)
nlinha+=nSaltoLinha
oPrint:Say (nLinha,nColInic + 100,"4 - Coletar amostra para ser analisado na filial de recpção do leite.",oFont10)
nlinha+=nSaltoLinha
oPrint:Say (nLinha,nColInic + 100,"5 - Desligar o agitador e esperar o leite parar.",oFont10)
nlinha+=nSaltoLinha
oPrint:Say (nLinha,nColInic + 100,"6 - Fazer a medição do leite.",oFont10)
nlinha+=nSaltoLinha
oPrint:Say (nLinha,nColInic + 100,"7 - Efetuar a coleta do leite.",oFont10)
nlinha+=nSaltoLinha
oPrint:Say (nLinha,nColInic + 100,"8 - Desmontar o registro de saída de leite do tanque e dexa-lo ao lado do tanque.",oFont10)
nlinha+=nSaltoLinha
oPrint:Say (nLinha,nColInic + 100,"9 - Se caso o tanque ficar vazio desliga-lo.",oFont10)
nlinha+=nSaltoLinha * 2
                                                               
DBSelectArea("ZL3")
ZL3->(DBSetOrder(1))
ZL3->(DBSeek(xFilial("ZL3") + MV_PAR01))                                          

oPrint:Say (nLinha,nColInic,"Rota: " + ZL3->ZL3_COD + AllTrim(ZL3->ZL3_DESCRI),oFont12b)
nlinha+=nSaltoLinha

oPrint:Say (nLinha,nColInic,"Km base: " + AllTrim(Transform(ZL3->ZL3_KM,"@E 99,999,999,999.99")),oFont12b)
oPrint:Say (nLinha,nColInic + 1500,"Km Rodado: ______________________",oFont12b)
nlinha+=nSaltoLinha

oPrint:Say (nLinha,nColInic,SubStr("Transportadora: " + ZL3->ZL3_FRETIS + "/" + ZL3->ZL3_FRETLJ + '-' + AllTrim(Posicione("SA2",1,xFilial("SA2") + ZL3->ZL3_FRETIS + ZL3->ZL3_FRETLJ,"A2_NOME")),1,67),oFont12b)
oPrint:Say (nLinha,nColInic + 1500,"Socorro:_____________________________ ",oFont12b)
nlinha+=nSaltoLinha

oPrint:Say (nLinha,nColInic,SubStr("Unidade: " + AllTrim(SM0->M0_NOMECOM) + '-' + AllTrim(SM0->M0_ESTCOB),1,67) ,oFont12b)
oPrint:Say (nLinha,nColInic + 1500,"Data da Coleta:_____/_____/_____",oFont12b)
nlinha+=nSaltoLinha * 2
                                                      
nLiInDados:=nLinha//Armazena o numero da linha inicial que se inicia o cabacalho dos dados da coleta                                                      
oPrint:Line(nLinha,nColInic - 5,nLinha,nColFinal)

CabecSecund()

Return      

/*
===============================================================================================================================
Programa----------: Cabecalho
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 16/01/2010
Descrição---------: Imprime parte superior do relatório com as instruções para coleta
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function DadosColLt()

Local nCountRec	:= 0
Local _nX		:= 1
Local _cAlias	:= GetNextAlias()

BeginSql alias _cAlias
	SELECT A2_COD, A2_LOJA, A2_NOME, A2_L_CAPTQ
	FROM %Table:SA2%
	WHERE D_E_L_E_T_ = ' '
	AND A2_FILIAL = %xFilial:SA2%
	AND A2_COD LIKE 'P%'
	AND A2_L_ATIVO = 'S'
	AND A2_L_LI_RO = %exp:MV_PAR01%
EndSql

COUNT TO nCountRec
(_cAlias)->(DBGoTop())

ProcRegua(nCountRec)

If nCountRec > 0

	oPrint:StartPage() //Inicia uma nova pagina a cada novo produtor
	oPrint:Say (nLinha - 40,nColInic + 2100,"PÁGINA " + Str(nPagina,2),oFont12b)//Imprime o numero da pagina
	Cabecalho()//Imprime cabecalho

	While (_cAlias)->(!Eof())
		IncProc("Os dados do relatorio estão sendo processados")
		//quebra de pagina
		If nLinha >= 3300
			divisBox()
			oPrint:EndPage()	// Finaliza a Pagina.
			oPrint:StartPage()	// Inicia uma nova pagina
			nLinha:=0100
			nLiInDados:=nLinha//Armazena o numero da linha inicial que se inicia o cabacalho dos dados da coleta
			nPagina++
			oPrint:Say (nLinha - 40,nColInic + 2100,"PÁGINA " + Str(nPagina,2),oFont12b)
			CabecSecund()
		EndIf

		oPrint:Say (nLinha + 35,nColInic       ,(_cAlias)->A2_COD,oFont12b)//Codigo
		oPrint:Say (nLinha + 35,nColInic + 141 ,(_cAlias)->A2_LOJA,oFont12b)//loja
		oPrint:Say (nLinha + 35,nColInic + 236 ,SubStr(AllTrim((_cAlias)->A2_NOME),1,27),oFont12b)//Nome do Produtor
		oPrint:Say (nLinha + 35,nColInic + 860 ,Transform((_cAlias)->A2_L_CAPTQ,"@E 999,999,999"),oFont12b)//Capacidade do Tanque
		nlinha+=nSaltoLinha
		oPrint:Line(nLinha,nColInic - 5,nLinha,nColFinal)
		     
		(_cAlias)->(DBSkip())
	EndDo
	(_cAlias)->(DBCloseArea())
	
		//Imprime cinco linhas em branco para posterior insercao manual caso seja necessario
		For _nX:=1 to 5
		    
		    //quebra de pagina
			If nLinha >= 3300                           
				divisBox()
				oPrint:EndPage()	// Finaliza a Pagina.
				oPrint:StartPage()	// Inicia uma nova pagina
				nLinha:=0100
				nLiInDados:=nLinha//Armazena o numero da linha inicial que se inicia o cabacalho dos dados da coleta
				nPagina++
				oPrint:Say (nLinha - 40,nColInic + 2100,"PÁGINA " + Str(nPagina,2),oFont12b)
				CabecSecund()
			EndIf
			nlinha+=nSaltoLinha
			oPrint:Line(nLinha,nColInic - 5,nLinha,nColFinal)
		Next _nX

		divisBox()

	    //quebra de pagina
		If nLinha + (3 * nSaltoLinha) >= 3300
			oPrint:EndPage()	// Finaliza a Pagina.
			oPrint:StartPage()	// Inicia uma nova pagina
			nLinha:=0100
			nLiInDados:=nLinha//Armazena o numero da linha inicial que se inicia o cabacalho dos dados da coleta
			nPagina++
			oPrint:Say (nLinha - 40,nColInic + 2100,"PÁGINA " + Str(nPagina,2),oFont12b)
			oPrint:Line(nLinha,nColInic + 1561,nLinha,nColFinal)
		EndIf
		                            
		//Desenha totalizadores
		nLiInDivis:=nLinha
		oPrint:Say (nLinha + 35,nColInic + 1566,"TOTAL DA COLETA",oFont12b)
		nlinha+=nSaltoLinha
		oPrint:Line(nLinha,nColInic + 1561,nLinha,nColFinal)

		oPrint:Say (nLinha + 35,nColInic + 1566,"VOLUME FISICO",oFont12b)
		nlinha+=nSaltoLinha
		oPrint:Line(nLinha,nColInic + 1561,nLinha,nColFinal)

		oPrint:Say (nLinha + 35,nColInic + 1566,"PRO/CONTRA",oFont12b)

		nlinha+=nSaltoLinha
		oPrint:Line(nLinha,nColInic + 1561,nLinha,nColFinal)

		//Divisorias
		oPrint:Line(nLiInDivis,nColInic + 1561,nLinha,nColInic + 1561)
		oPrint:Line(nLiInDivis,nColInic + 2045,nLinha,nColInic + 2045)
		oPrint:Line(nLiInDivis,nColFinal,nLinha,nColFinal)

		//quebra de pagina
		If nLinha + (5 * nSaltoLinha) >= 3300
			oPrint:EndPage()	// Finaliza a Pagina.
			oPrint:StartPage()	// Inicia uma nova pagina
			nLinha:=0100
			nLiInDados:=nLinha//Armazena o numero da linha inicial que se inicia o cabacalho dos dados da coleta
			nPagina++
			oPrint:Say (nLinha - 40,nColInic + 2100,"PÁGINA " + Str(nPagina,2),oFont12b)
		EndIf

		//Desenha assinatura do Diretor Comercial e do Analista Comercial
		nlinha+=(nSaltoLinha  * 5)  
		oPrint:Line(nLinha,nColInic + 100,nLinha,nColInic + 0900)//ASSINTARUA DO MOTORISTA
					
		cTitulo:="Assinatura Motorista"
		//Calculo para que o nome fica alinhado no centro coluna INSS   
		//O valor 29.10 eh o valor que cada caractere ocupa
		nColuna:= 130 + Int(((930-130) - (Len(cTitulo)* 29.10))/2)
		oPrint:Say (nlinha,nColuna,cTitulo,oFont16b)
					
		oPrint:Line(nLinha,nColInic + 1430,nLinha,nColInic + 1430 + 800)//ASSINATURA FUNCIONARIO ITALAC 
		cTitulo:="Assintaura Funcionario ITALAC"
		//Calculo para que o nome fica alinhado no centro coluna INSS   
		//O valor 29.10 eh o valor que cada caractere ocupa
		nColuna:= 1460 + Int(((2260-1460) - (Len(cTitulo)* 29.10))/2)
		oPrint:Say (nlinha,nColuna,cTitulo,oFont16b)	      

		oPrint:EndPage()// Finaliza a Pagina.

	EndIf

Return                                                                 

/*
===============================================================================================================================
Programa----------: divisBox
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 16/01/2010
Descrição---------: Desenha o box da pagina e as divisorias das colunas dos dados da coleta de leite
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function divisBox

oPrint:Box(nLinhaInic,nColInic - 5,nLinha,nColFinal)//Box da pagina
oPrint:Line(nLiInDados,nColInic + 141,nLinha,nColInic + 141)//Loja
oPrint:Line(nLiInDados,nColInic + 231,nLinha,nColInic + 231)//Produtor
oPrint:Line(nLiInDados,nColInic + 835,nLinha,nColInic + 835)//Capacidade Tanque

oPrint:Line(nLiInDados,nColInic + 1115,nLinha,nColInic + 1115)//Temperatura
oPrint:Line(nLiInDados,nColInic + 1305,nLinha,nColInic + 1305)//Alizarol
oPrint:Line(nLiInDados,nColInic + 1495,nLinha,nColInic + 1495)//Leitura
oPrint:Line(nLiInDados,nColInic + 1695,nLinha,nColInic + 1695)//Numero boca
oPrint:Line(nLiInDados,nColInic + 1865,nLinha,nColInic + 1865)//Hora coleta
oPrint:Line(nLiInDados,nColInic + 2045,nLinha,nColInic + 2045)//Volume Coletado

Return                                                                            

/*
===============================================================================================================================
Programa----------: CabecSecund
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 16/01/2010
Descrição---------: Funcao utilizada para imprimir o numero da pagina
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function CabecSecund

oPrint:FillRect({(nlinha+3),nColInic,nlinha + nSaltoLinha,nColFinal},oBrush)  
	
oPrint:Say (nLinha,nColInic       ,"Codigo",oFont12b)
oPrint:Say (nLinha,nColInic + 146 ,"Loja",oFont12b)
oPrint:Say (nLinha,nColInic + 236 ,"Produtor",oFont12b)

oPrint:Say (nLinha,nColInic + 0840   ,"Capacidade",oFont12b)
oPrint:Say (nLinha+40,nColInic + 0840,"Tanque",oFont12b)

oPrint:Say (nLinha,nColInic + 1120   ,"Temp.C",oFont12b)
oPrint:Say (nLinha+40,nColInic + 1120,"C",oFont12b)

oPrint:Say (nLinha,nColInic + 1310   ,"Alizarol",oFont12b)
oPrint:Say (nLinha+40,nColInic + 1310,"N/P",oFont12b)

oPrint:Say (nLinha,nColInic + 1500   ,"Leitura",oFont12b)
oPrint:Say (nLinha+40,nColInic + 1500,"Regua",oFont12b)

oPrint:Say (nLinha,nColInic + 1700   ,"No.",oFont12b)
oPrint:Say (nLinha+40,nColInic + 1700,"Boca",oFont12b)

oPrint:Say (nLinha,nColInic + 1870   ,"Hora",oFont12b)
oPrint:Say (nLinha+40,nColInic + 1870,"Coleta",oFont12b)

oPrint:Say (nLinha,nColInic + 2050   ,"Vol.Coletado",oFont12b)

nlinha+=nSaltoLinha
oPrint:Line(nLinha,nColInic - 5,nLinha,nColFinal)

Return
