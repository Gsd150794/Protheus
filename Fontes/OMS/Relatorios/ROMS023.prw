/*
===============================================================================================================================
               ULTIMAS ATUALIZACOES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
       Autor      |    Data    |                                             Motivo                                           
-------------------------------------------------------------------------------------------------------------------------------
Alexandre Villar  | 23/03/2016 | Ajuste para padronizar a utilizacao de rotinas de consultas customizadas. Chamado 14774      
-------------------------------------------------------------------------------------------------------------------------------
Josue Danich      | 08/03/2019 | Revisao para loboguara - Chamado 28356
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  	  | 17/10/2019 | Removidos os Warning na compilação da release 12.1.25. Chamado 28346
===============================================================================================================================
*/
//====================================================================================================
// Definicoes de Includes e Defines da Rotina.
//====================================================================================================
#Include "report.ch"
#Include "TOTVS.ch"      
#Include "rwmake.ch"

/*
===============================================================================================================================
Programa--------: ROMS023
Autor-----------: Fabiano Dias
Data da Criacao-: 24/02/2011
===============================================================================================================================
Descricao-------: Relatorio por Coordenador que infica vendedores e valor bruto mensal vendido
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function ROMS023()

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

Private nPagina     := 0

Private nLinha      := 0050
Private nColInic    := 0030
Private nColFinal   := 2360 
Private nqbrPagina  := 3300 
Private nLinInBox   
Private nSaltoLinha := 50               
Private nAjuAltLi1  := 10 //ajusta a altura de impressao dos dados do relatorio

Private oBrush      := TBrush():New( ,CLR_LIGHTGRAY)   

Private cPerg       := "ROMS023"      

Private horaImp     := Time()         

Private aMes:={"Janeiro","Fevereiro","Marco","Abril","Maio","Junho","Julho","Agosto","Setembro","Outubro","Novembro","Dezembro"}

Define Font oFont09    Name "Courier New"       Size 0,-07       // Tamanho 14                                                                              
Define Font oFont09b   Name "Courier New"       Size 0,-07 Bold  // Tamanho 14                                                                              
Define Font oFont10    Name "Courier New"       Size 0,-08       // Tamanho 14    
Define Font oFont10b   Name "Courier New"       Size 0,-08 Bold   // Tamanho 14 
Define Font oFont12    Name "Courier New"       Size 0,-10       // Tamanho 12
Define Font oFont12b   Name "Courier New"       Size 0,-10 Bold  // Tamanho 12 Negrito  
Define Font oFont14    Name "Courier New"       Size 0,-10       // Tamanho 14
Define Font oFont14b   Name "Courier New"       Size 0,-10 Bold  // Tamanho 14         
Define Font oFont14Pr  Name "Courier New"       Size 0,-12       // Tamanho 14
Define Font oFont14Prb Name "Courier New"       Size 0,-12 Bold  // Tamanho 14 Negrito  

oPrint:= TMSPrinter():New("FATURAMENTO GERENCIAL")   
oPrint:SetPaperSize(9)	// Seta para papel A4  
	                 		
If !Pergunte(cPerg,.T.) 
     Return
EndIf       

//Para efetuar o redimensionamento da pagina de acordo com o tipo de relatorio escolhido
If MV_PAR20 == '1' .Or. MV_PAR20 == '3'    

	oPrint:SetPortrait() 	// Retrato  
  	
	Else 
	
		oPrint:SetLandscape() 	// Paisagem    
	
		nColFinal   := 3385 
		nqbrPagina  := 2200 
	
EndIf      

/// startando a impressora
oPrint:Say(0,0," ",oFont12,100)        

oPrint:StartPage() 

//0 - para nao imprimir a numeracao de pagina na emissao da pagina de parametros
ROMS023C(0)
		     		 	     		
Processa({|| ROMS023D9() })  
	

oPrint:EndPage()	// Finaliza a Pagina.
oPrint:Preview()	// Visualiza antes de Imprimir.


Return        

/*
===============================================================================================================================
Programa--------: ROMS023C
Autor-----------: Fabiano Dias
Data da Criacao-: 24/02/2011
===============================================================================================================================
Descricao-------: Cabecalho do relatorio
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS023C(impNrPag,cDescFil)    

Local cRaizServer := If(issrvunix(), "/", "\")    
Local cTitulo     := ""  
Local cTipoRel    := ""

//Tipo do relatorio - vendedor  x Mensal
If MV_PAR20 == '1'        
	
	cTipoRel:= "EVOLUCAO DE VENDAS - (VENDEDOR X MENSAL) - "
        
//Tipo do relatorio - vendedor x sub-Grupo x Mensal
ElseIf MV_PAR20 == '2'    
	
	cTipoRel:= "EVOLUCAO DE VENDAS - (VENDEDOR X SUB-GRUPO X MENSAL) - " 
		
ElseIf MV_PAR20 == '3'
			
	cTipoRel:= "EVOLUCAO DE VENDAS - (COORDENADOR X MENSAL) - "   
				
ElseIf MV_PAR20 == '4' 
					
	cTipoRel:= "EVOLUCAO DE VENDAS - (COORDENADOR X SUB-GRUPO X MENSAL) - " 

EndIf      

cTitulo     := cTipoRel + DToC(MV_PAR02) + ' a ' + DToC(MV_PAR03) 

nLinha      := 0100
 
oPrint:SayBitmap(nLinha,nColInic,cRaizServer + "system/lgrl01.bmp",250,100)      
	  
If impNrPag <> 0
	oPrint:Say (nlinha,nColFinal - 550,"PAGINA: " + AllTrim(Str(nPagina)),oFont12b)
Else
	oPrint:Say (nlinha,nColFinal - 550,"SIGA/ROMS023",oFont12b)
	oPrint:Say (nlinha + 150,nColFinal - 550,"EMPRESA: " + AllTrim(SM0->M0_NOME) + '/' + AllTrim(SM0->M0_FILIAL),oFont12b)
EndIf

oPrint:Say (nlinha + 50 ,nColFinal - 550,"DATA DE EMISSAO: " + DToC(DATE()),oFont12b)   
oPrint:Say (nlinha + 100,nColFinal - 550,"HORA: " + horaImp                ,oFont12b)
nlinha+=(nSaltoLinha * 3)           
	                                                   
oPrint:Say (nlinha,nColFinal / 2,cTitulo,oFont14b,nColFinal,,,2)
	
nlinha+=nSaltoLinha 
nlinha+=nSaltoLinha        
	
oPrint:Line(nLinha,nColInic,nLinha,nColFinal) 

Return      

/*
===============================================================================================================================
Programa--------: ROMS023CC
Autor-----------: Fabiano Dias
Data da Criacao-: 24/02/2011
===============================================================================================================================
Descricao-------: Cabecalho do centro de custo
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/

Static Function ROMS023CC(cDescric,cCodigo,cDescCod,cTipo)

Local cDescCoord:= ""    
                  
oPrint:FillRect({(nlinha+3),nColInic,nlinha + nSaltoLinha,nColFinal},oBrush)                    
oPrint:Box(nlinha,nColInic,nLinha + nSaltoLinha,nColFinal)
 
//Indica que se trata de um vendedor desta nao sera necessario buscar a sua descricao
If cTipo == 1 

	oPrint:Say (nlinha,nColInic + 25 ,cDescric + SubStr(AllTrim(cCodigo) + '-' + AllTrim(cDescCod),1,60),oFont14Prb) 
	
Else   

	If Len(AllTrim(cCodigo)) > 0
		cDescCoord:= Posicione("SA3",1,xFilial("SA3") + cCodigo,"SA3->A3_NOME")
	Else
		cDescCoord:= 'SEM COORDENADOR' 
	EndIf      
	aAdd(_aCoord,{cCodigo,cDescCoord})
    //Se trata de Coordenador 
	oPrint:Say (nlinha,nColInic + 25 ,cDescric + SubStr(AllTrim(cCodigo) + '-' + AllTrim(cDescCoord),1,60),oFont14Prb) 

EndIf       

Return

/*
===============================================================================================================================
Programa--------: ROMS023CD
Autor-----------: Fabiano Dias
Data da Criacao-: 24/02/2011
===============================================================================================================================
Descricao-------: Cabecalho de dados
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS023CD()    
                  
nLinInBox:= nlinha        

oPrint:Say (nlinha + nAjuAltLi1,nColInic + 20	    ,"Mes/Ano"                 ,oFont12b)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 1230    ,"Valor Liquido de Vendas"  ,oFont12b)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 2030    ,"% Sobre total"           ,oFont12b)   

nlinha+=nSaltoLinha   
oPrint:Line(nLinha,nColInic,nLinha,nColFinal) 

Return   

/*
===============================================================================================================================
Programa--------: ROMS023PD
Autor-----------: Fabiano Dias
Data da Criacao-: 24/02/2011
===============================================================================================================================
Descricao-------: Imprime os dados
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS023PD(cMesAno,nVlrBruto,nTotVend)   

Local cData:= aMes[Val(SubStr(cMesAno,5,2))] + '/'+ SubStr(cMesAno,1,4)                       

oPrint:Say (nlinha + nAjuAltLi1,nColInic + 20	     ,cData                                        ,oFont12)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 1330     ,Transform(nVlrBruto,"@E 999,999,999,999.99") ,oFont12)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 2160     ,Transform((nVlrBruto/nTotVend)*100 ,"@E 999.99") + '%'       ,oFont12)   

Return            

/*
===============================================================================================================================
Programa--------: ROMS023PT
Autor-----------: Fabiano Dias
Data da Criacao-: 24/02/2011
===============================================================================================================================
Descricao-------: Imprime os totais
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS023PT(cDescric,cCodigo,cDesc,nVlrTotal)                      

oPrint:Say (nlinha + nAjuAltLi1,nColInic + 20	     ,SubStr(cDescric + ' ' + cCodigo + ' - '+ cDesc,1,60) ,oFont12b)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 1330     ,Transform(nVlrTotal,"@E 999,999,999,999.99")          ,oFont12b)  

Return      

/*
===============================================================================================================================
Programa--------: ROMS023BD
Autor-----------: Fabiano Dias
Data da Criacao-: 24/02/2011
===============================================================================================================================
Descricao-------: Box de divisao
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS023BD() 
      
oPrint:Line(nLinInBox,nColInic + 580 ,nLinha + nSaltoLinha,nColInic + 580) //Mes/Ano               | Valor Bruto de Vendas 
oPrint:Line(nLinInBox,nColInic + 1760,nLinha + nSaltoLinha,nColInic + 1760)//Valor Bruto de Vendas | % Sobre Total  

oPrint:Box(nLinInBox,nColInic,nLinha + nSaltoLinha,nColFinal) //Box Faturamento

Return 

/*
===============================================================================================================================
Programa--------: ROMS023CS
Autor-----------: Fabiano Dias
Data da Criacao-: 24/02/2011
===============================================================================================================================
Descricao-------: Cabecalho de subgrupo
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS023CS(cCodigo,cDescric)
                  
oPrint:FillRect({(nlinha+3),nColInic + 200,nlinha + nSaltoLinha,nColFinal},oBrush)                    
oPrint:Box(nlinha,nColInic + 200,nLinha + nSaltoLinha,nColFinal)
 
oPrint:Say (nlinha,nColInic + 225,'Sub-Grupo:' + SubStr(AllTrim(cCodigo) + '-' + AllTrim(cDescric),1,60),oFont14Prb) 

Return  

/*
===============================================================================================================================
Programa--------: ROMS023DS
Autor-----------: Fabiano Dias
Data da Criacao-: 24/02/2011
===============================================================================================================================
Descricao-------: Cabecalho de de dados do subgrupo
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS023DS()

nLinInBox:= nlinha        

oPrint:Say (nlinha + nAjuAltLi1,nColInic + 225	    ,"Mes/Ano"                ,oFont12b)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 879     ,"Qtde 1a.U.M."           ,oFont12b)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 1153    ,"1a.U.M."                ,oFont12b) 
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 1543    ,"Qtde 2a.U.M."           ,oFont12b)  
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 1817    ,"2a.U.M."                ,oFont12b)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 2267    ,"Vlr.Unit."              ,oFont12b)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 2751    ,"Vlr.Bruto"              ,oFont12b)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 2981    ,"%Qtde sobre Total"      ,oFont12b)

nlinha+=nSaltoLinha   
oPrint:Line(nLinha,nColInic + 200,nLinha,nColFinal) 

Return            

/*
===============================================================================================================================
Programa--------: ROMS023P2
Autor-----------: Fabiano Dias
Data da Criacao-: 24/02/2011
===============================================================================================================================
Descricao-------: Imprime dados do subgrupo
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS023P2(cMesAno,nqtde1,um1,nqtde2,um2,vlrBruto,nqtdeTot)     

Local cData:= aMes[Val(SubStr(cMesAno,5,2))] + '/'+ SubStr(cMesAno,1,4)   

oPrint:Say (nlinha + nAjuAltLi1,nColInic + 225	    ,cData                                                  ,oFont12b)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 739     ,Transform(nqtde1,"@E 999,999,999,999.99")              ,oFont12b)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 1153    ,um1                                                    ,oFont12b) 
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 1403    ,Transform(nqtde2,"@E 999,999,999,999.99")              ,oFont12b)  
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 1817    ,um2                                                     ,oFont12b)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 2067    ,Transform(vlrBruto/nqtde1,"@E 999,999,999,999.99")      ,oFont12b)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 2561    ,Transform(vlrBruto,"@E 999,999,999,999.99")             ,oFont12b)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 3141    ,Transform((vlrBruto/nqtdeTot) * 100,"@E 999.99") + ' %' ,oFont12b)

Return          

/*
===============================================================================================================================
Programa--------: ROMS023T2
Autor-----------: Fabiano Dias
Data da Criacao-: 24/02/2011
===============================================================================================================================
Descricao-------: Imprime totais do subgrupo
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS023T2(cDesc,nqtde1,nqtde2,vlrBruto)

oPrint:Say (nlinha + nAjuAltLi1,nColInic + 225	    ,cDesc                                              ,oFont12b)
nlinha+=nSaltoLinha   
oPrint:Line(nLinha,nColInic + 200,nLinha,nColFinal)                                                              

oPrint:Say (nlinha + nAjuAltLi1,nColInic + 739     ,Transform(nqtde1,"@E 999,999,999,999.99")          ,oFont12b)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 1403    ,Transform(nqtde2,"@E 999,999,999,999.99")          ,oFont12b)  
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 2067    ,Transform(vlrBruto/nqtde1,"@E 999,999,999,999.99") ,oFont12b)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 2561    ,Transform(vlrBruto,"@E 999,999,999,999.99")        ,oFont12b)

Return             

/*
===============================================================================================================================
Programa--------: ROMS023T3
Autor-----------: Fabiano Dias
Data da Criacao-: 24/02/2011
===============================================================================================================================
Descricao-------: Imprime valores brutos
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS023T3(cDesc,vlrBruto)
 
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 225	    ,cDesc                                              ,oFont12b)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 2561    ,Transform(vlrBruto,"@E 999,999,999,999.99")        ,oFont12b)

Return

/*
===============================================================================================================================
Programa--------: ROMS023D3
Autor-----------: Fabiano Dias
Data da Criacao-: 24/02/2011
===============================================================================================================================
Descricao-------: Box divisao de subgrupo
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS023D3() 
      
oPrint:Line(nLinInBox,nColInic + 679 ,nLinha + nSaltoLinha,nColInic + 679) 
oPrint:Line(nLinInBox,nColInic + 1143,nLinha + nSaltoLinha,nColInic + 1143) 
oPrint:Line(nLinInBox,nColInic + 1343,nLinha + nSaltoLinha,nColInic + 1343) 
oPrint:Line(nLinInBox,nColInic + 1807,nLinha + nSaltoLinha,nColInic + 1807) 
oPrint:Line(nLinInBox,nColInic + 2007,nLinha + nSaltoLinha,nColInic + 2007) 
oPrint:Line(nLinInBox,nColInic + 2471,nLinha + nSaltoLinha,nColInic + 2471) 
oPrint:Line(nLinInBox,nColInic + 2971,nLinha + nSaltoLinha,nColInic + 2971) 

oPrint:Box(nLinInBox,nColInic + 200,nLinha + nSaltoLinha,nColFinal) //Box Faturamento

Return 

/*
===============================================================================================================================
Programa--------: ROMS023QP
Autor-----------: Fabiano Dias
Data da Criacao-: 24/02/2011
===============================================================================================================================
Descricao-------: Quebra de paginas
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS023QP()

	oPrint:EndPage()					// Finaliza a Pagina.
	oPrint:StartPage()					//Inicia uma nova Pagina
							
	nPagina++
	ROMS023C(1)//Chama cabecalho  	 

Return       

/*
===============================================================================================================================
Programa--------: ROMS023QP
Autor-----------: Fabiano Dias
Data da Criacao-: 24/02/2011
===============================================================================================================================
Descricao-------: Quebra de pagina
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS023Q2(nLinhas,impBox,impCabec)   

	//Quebra de pagina
	If nLinha > nqbrPagina
				
		nlinha:= nlinha - (nSaltoLinha * nLinhas)
		
		If impBox == 1 
		    //Relatorio do Tipo Evolucao Mensal x Vendedor
			If MV_PAR20 == '1' .Or. MV_PAR20 == '3'
				ROMS023BD() 
			//Relatorio do Evolucao Mensal x Vendedor x Sub-Grupo de Produto
			ElseIf MV_PAR20 == '2' .Or. MV_PAR20 == '4'   					
				ROMS023D3()			
			EndIf		

		EndIf	 
		
		oPrint:EndPage()					// Finaliza a Pagina.
		oPrint:StartPage()					//Inicia uma nova Pagina
							
		nPagina++
		ROMS023C(1)//Chama cabecalho  	   
		
		nlinha+=nSaltoLinha 
		nlinha+=nSaltoLinha 	  
		 
		If impCabec == 1
		        
				If MV_PAR20 == '1' .Or. MV_PAR20 == '3'     
				
					ROMS023CD() 
					
					nlinha+=nSaltoLinha    
					oPrint:Line(nLinha,nColInic,nLinha,nColFinal)   
					   
				ElseIf MV_PAR20 == '2' .Or. MV_PAR20 == '4' 
						
					ROMS023DS()   
							
					nlinha+=nSaltoLinha    
					oPrint:Line(nLinha,nColInic+200,nLinha,nColFinal) 
		
				EndIf              				

		EndIf			
		
	EndIf  
	
Return  

/*
===============================================================================================================================
Programa--------: ROMS023D9
Autor-----------: Fabiano Dias
Data da Criacao-: 24/02/2011
===============================================================================================================================
Descricao-------: Carga de dados do relatorio
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS023D9()   

Local _cAlias   := GetNextAlias()
Local nCountRec := 0 
Local nPosDados := 0  
Local _cCoord   := ""
Local _cVended  := ""  
Local _cSubGrp  := ""
Local _cDescv   := "" 
Local _cDescSub := ""  
Local cCfops    := ""
Local k			:= 0
//Totalizadores
Local _nTotVend := 0
Local _nTotCoord:= 0     
Local nTotalVend:= 0      
Local _nTotSb1Qt:= 0
Local _nTotSb2Qt:= 0
Local _nTotSbVBr:= 0

Local   cFiltro := "%"

Private _aDados:= {} //Armazena os dados aglutinados por coordenador + vendedor + mes/ano   
Private _aCoord:= {} //Aramazena os coordenadores impressos ate momento para nao ficar buscando dados na tabela SA3 para impressao    
Private _aPorce:= {} //Armazena os totais de cadas vendedor para ser usado pelo calculo de % e agilizar o processo de consulta 

//Filtros
//Filtra Filial da SF2,SD2,SA1,SB1,SBM,SA3,ACY
If !Empty(AllTrim(MV_PAR01))	
	If !Empty(xFilial("SF2"))
		cFiltro += " AND F2.F2_FILIAL IN " + FormatIn(MV_PAR01,";")
	EndIf	  
	If !Empty(xFilial("SF4"))
		cFiltro += " AND F4.F4_FILIAL IN " + FormatIn(MV_PAR01,";")
	EndIf	                       
	If !Empty(xFilial("SD2"))
		cFiltro += " AND D2.D2_FILIAL IN " + FormatIn(MV_PAR01,";")
	EndIf                 	
	If !Empty(xFilial("SA1"))
		cFiltro += " AND A1.A1_FILIAL IN " + FormatIn(MV_PAR01,";")
	EndIf
	If !Empty(xFilial("SB1"))	
		cFiltro += " AND B1.B1_FILIAL IN " + FormatIn(MV_PAR01,";")
	EndIf
	If !Empty(xFilial("SA3"))
		cFiltro += " AND A3.A3_FILIAL IN " + FormatIn(MV_PAR01,";")
	EndIf
EndIf 

//Filtra Emissao da SF2
If !Empty(MV_PAR02) .And. !Empty(MV_PAR03)
	cFiltro += " AND F2.F2_EMISSAO BETWEEN '" + DToS(MV_PAR02) + "' AND '" + DToS(MV_PAR03) + "'"
EndIf

//Filtra Produto
If !Empty(MV_PAR04) .And. !Empty(MV_PAR05)
	cFiltro += " AND D2.D2_COD BETWEEN '" + MV_PAR04 + "' AND '" + MV_PAR05 + "'"
EndIf

//Filtra Cliente
If !Empty(MV_PAR06) .And. !Empty(MV_PAR08)
	cFiltro += " AND D2.D2_CLIENTE BETWEEN '" + MV_PAR06 + "' AND '" + MV_PAR08 + "'"
EndIf

//Filtra Loja Cliente
If !Empty(MV_PAR07) .And. !Empty(MV_PAR09)
	cFiltro += " AND D2.D2_LOJA BETWEEN '" + MV_PAR07 + "' AND '" + MV_PAR09 + "'"
EndIf

//Filtra Rede Cliente
If !Empty(MV_PAR10)
	cFiltro += " AND A1.A1_GRPVEN IN " + FormatIn(MV_PAR10,";")
EndIf
     
//Filtra Estado Cliente
If !Empty(MV_PAR11) 
	cFiltro += " AND A1.A1_EST IN " + FormatIn(MV_PAR11,";")
EndIf

//Filtra Cod Municipio Cliente
If !Empty(MV_PAR12) 
	cFiltro += " AND A1.A1_COD_MUN IN " + FormatIn(MV_PAR12,";")
EndIf

//Filtra Vendedor
If !Empty(MV_PAR13) 
	cFiltro += " AND F2.F2_VEND1 IN " + FormatIn(MV_PAR13,";")
EndIf

//Filtra Supervisor
If !Empty(MV_PAR14)
	cFiltro += " AND F2.F2_VEND2 IN " + FormatIn(MV_PAR14,";")
EndIf 

//Filtra Grupo de Produtos
If !Empty(MV_PAR15)
	cFiltro += " AND B1.B1_GRUPO IN " + FormatIn(MV_PAR15,";")
EndIf      

//Filtra Sub Grupo de Produto
If !Empty(MV_PAR16)
	cFiltro += " AND B1.B1_I_SUBGR IN " + FormatIn(MV_PAR16,";")
EndIf

//Filtra Produto Nivel 2
If !Empty(MV_PAR17)
	cFiltro += " AND B1.B1_I_NIV2 IN " + FormatIn(MV_PAR17,";")
EndIf

//Filtra Produto Nivel 3
If !Empty(MV_PAR18)
	cFiltro += " AND B1.B1_I_NIV3 IN " + FormatIn(MV_PAR18,";")
EndIf

//Filtra Produto Nivel 4
If !Empty(MV_PAR19)
	cFiltro += " AND B1.B1_I_NIV4 IN " + FormatIn(MV_PAR19,";")
EndIf        

//Somente considera CFOP de vendas
cCfops  := U_ITCFOPS(AllTrim(Upper('V')))
cFiltro += " AND D2.D2_CF IN " + FormatIn(cCfops,";")	

cFiltro += "%"      
//Relatorio de Evolucao Mensal  - Coordenador x Vendedor
If MV_PAR20 == '1'

	BeginSql alias _cAlias 
	
		SELECT 
			  F2.F2_VEND2,
			  F2.F2_VEND1,
			  A3.A3_NOME VENDEDOR,
			  F2.F2_EMISSAO,
			  D2.D2_FILIAL,
			  D2.D2_DOC,
			  D2.D2_SERIE,
			  D2.D2_CLIENTE,
			  D2.D2_LOJA, 
			  D2.D2_COD,
			  (SUM(D2.D2_VALBRUT)  -
			  (SELECT COALESCE(SUM(D1.D1_TOTAL + D1.D1_ICMSRET),0)
			  FROM SD1010 D1
			  WHERE D1.D_E_L_E_T_ = ' '
			  AND D1.D1_TIPO = 'D'
			  AND D1.D1_FILIAL = D2.D2_FILIAL 
			  AND D1.D1_NFORI = D2.D2_DOC
			  AND D1.D1_SERIORI = D2.D2_SERIE
			  AND D1.D1_FORNECE = D2.D2_CLIENTE
			  AND D1.D1_LOJA = D2.D2_LOJA    
			  AND D1.D1_COD = D2.D2_COD
		      )) VLRBRUT
		FROM 
			  SF2010 F2
			  JOIN SD2010 D2 ON F2.F2_FILIAL = D2.D2_FILIAL AND F2.F2_DOC = D2.D2_DOC AND F2.F2_SERIE = D2.D2_SERIE AND F2.F2_CLIENTE = D2.D2_CLIENTE AND F2.F2_LOJA = D2.D2_LOJA
			  JOIN SA1010 A1 ON A1.A1_COD = D2.D2_CLIENTE AND A1.A1_LOJA = D2.D2_LOJA
			  JOIN SB1010 B1 ON B1.B1_COD = D2.D2_COD
			  JOIN SF4010 F4 ON F4.F4_FILIAL = D2.D2_FILIAL AND F4.F4_CODIGO = D2.D2_TES
			  JOIN SA3010 A3 ON F2.F2_VEND1 = A3.A3_COD
		WHERE 
			  F2.D_E_L_E_T_ = ' '
			  AND D2.D_E_L_E_T_   = ' '
			  AND A1.D_E_L_E_T_   = ' '
		      AND B1.D_E_L_E_T_   = ' '
			  AND F4.D_E_L_E_T_   = ' '
			  AND A3.D_E_L_E_T_   = ' '
			  AND F4.F4_DUPLIC    = 'S'  
			  %exp:cFiltro%
		GROUP BY 
		      F2.F2_VEND2, F2.F2_VEND1, A3.A3_NOME, F2.F2_EMISSAO, D2.D2_FILIAL, D2.D2_DOC, D2.D2_SERIE, D2.D2_CLIENTE, D2.D2_LOJA,D2.D2_COD
	
	EndSql 
	
	DBSelectArea(_cAlias)	      
	(_cAlias)->(DBGoTop()) 
	    
	COUNT TO nCountRec //Contabiliza o numero de registros encontrados pela query            
	    
	ProcRegua(nCountRec)
	
	If nCountRec > 0
	  
	     DBSelectArea(_cAlias)	      
		(_cAlias)->(DBGoTop())     
		//Efetua a aglutinacao dos dados	
		While (_cAlias)->(!Eof())                         
		
			IncProc("Processando a aglutinacao dos dados!")
		  
			nPosDados := aScan(_aDados,{|x| x[1] + x[2] + x[4] == (_cAlias)->F2_VEND2 + (_cAlias)->F2_VEND1 + SubStr((_cAlias)->F2_EMISSAO,1,6) })
			
			If nPosDados > 0      
			
				_aDados[nPosDados,5] += (_cAlias)->VLRBRUT
			
			Else
				//1 - Codigo do Coordenador
				//2 - Codigo do Vendedor
				//3 - Descricao do Vendedor
				//4 - Ano e mes da realizacao da venda
				//5 - Valor Bruto da venda      		
				aAdd(_aDados,{(_cAlias)->F2_VEND2,(_cAlias)->F2_VEND1,(_cAlias)->VENDEDOR,SubStr((_cAlias)->F2_EMISSAO,1,6),(_cAlias)->VLRBRUT})		
			
			EndIf
		
		(_cAlias)->(DBSkip())
		EndDo                   
		
		//Inicia uma nova pagina para impressao
		oPrint:StartPage()   
	    	
	    nPagina++
		ROMS023C(1)//Chama cabecalho  	     	    	    	
		
		//Ordena os Dados do relatorio por Coordenador + Supervisor + ano / mes
		_aDados:= aSort(_aDados,,,{|x, y| x[1] + x[2] + x[4] < y[1] + y[2] + y[4]})		// Ordenar    
		
		ProcRegua(Len(_aDados))
		                 
		//Efetua a impressao dos dados do Relatorio
		For k:=1 To Len(_aDados)     
		
			IncProc("Realizando a impressao dos dados do relatorio")
		
			//Verifica a necessidade de quebra por Coordenador    
			If _cCoord <> _aDados[k,1]    
			
				//Verifica a necessidade de impressao do totalizador do Cliente e Coordenador Anterior ao novo Coordenador e imprime box dele
				If k > 1                  
				
					//Fecha Box
					ROMS023BD()
				
					//Imprime totalizador do ultimo cliente 
					nlinha+=nSaltoLinha 
					nlinha+=nSaltoLinha    
					
					ROMS023Q2(0,0,0)  
					ROMS023PT('TOTAL VENDEDOR:',_cVended,_cDescv,_nTotVend) 
					
					//Imprime totalizador do ultimo coordenador                
					nlinha+=nSaltoLinha 
					nlinha+=nSaltoLinha    
					
					ROMS023Q2(0,0,0)  
					ROMS023PT('TOTAL COORDENADOR:',_cCoord,_aCoord[aScan(_aCoord,{|x| x[1] == _cCoord}),2],_nTotCoord)  
					
					//Forca a quebra de pagina a cada novo coordenador
					ROMS023QP()
				
				EndIf
			    
				nlinha+=nSaltoLinha 
				nlinha+=nSaltoLinha    
				
				ROMS023Q2(0,0,0)			  
				
				ROMS023CC('Coordenador:',_aDados[k,1],'',0)			     		
				
				//A cada novo Coordenador deve existir um novo vendedor
				nlinha+=nSaltoLinha 
				nlinha+=nSaltoLinha    
				
				ROMS023Q2(0,0,0)   
				
				ROMS023CC('Vendedor:',_aDados[k,2],_aDados[k,3],1) 
				
				//Imprime o cabecalho de Dados 
				nlinha+=nSaltoLinha 
				nlinha+=nSaltoLinha    
				
				ROMS023Q2(0,0,0)   
				
				ROMS023CD()
				
				//Seta totalizador por vendedor e coordenador
				_nTotCoord:= 0
				_nTotVend := 0 
				
				_cVended:= _aDados[k,2]	   										
			
			EndIf
					
			//Verifica a necessidade de quebra por Vendedor 
			If _cVended <> _aDados[k,2]
			
				//Verifica a necessidade de impressao do totalizador do vendedor anterior  e box do vendedor anterior
				If Len(AllTrim(_cVended)) > 0      
				
					//Fecha Box
					ROMS023BD()
				
					//Imprime totalizador do ultimo cliente 
					nlinha+=nSaltoLinha 
					nlinha+=nSaltoLinha    
					
					ROMS023Q2(0,0,0)  
					ROMS023PT('TOTAL VENDEDOR:',_cVended,_cDescv,_nTotVend) 
				
				EndIf     
				
				nlinha+=nSaltoLinha 
				nlinha+=nSaltoLinha    
				
				ROMS023Q2(0,0,0)   
				
				ROMS023CC('Vendedor:',_aDados[k,2],_aDados[k,3],1) 
				
				//Imprime o cabecalho de Dados 
				nlinha+=nSaltoLinha 
				nlinha+=nSaltoLinha    
				
				ROMS023Q2(0,0,0)   
				
				ROMS023CD()
				
				//Seta totalizador por vendedor
				_nTotVend := 0
			
			EndIf 
		            
		   	nlinha+=nSaltoLinha 
		   	oPrint:Line(nLinha,nColInic,nLinha,nColFinal)  
				
			ROMS023Q2(1,1,1)             
			
			//Funcao para calcular o valor total do Coordenador + vendedor para ser utilizado no calculo da % sobre total
			nTotalVend:=ROMS023CT(_aDados[k,1],_aDados[k,2])
								
			//Imprime os dados do relatorio  
			ROMS023PD(_aDados[k,4],_aDados[k,5],nTotalVend)
			
			//Seta a variavel de controle da quebra por coordenador e Vendedor
			_cCoord := _aDados[k,1]   
			_cVended:= _aDados[k,2]	  
			_cDescv := _aDados[k,3]     
			
			//Incrementa variaveis de totalizador
			_nTotCoord += _aDados[k,5]
			_nTotVend  += _aDados[k,5]	
		
		Next k  
		
		//Imprime os ultimos totalizadores  
	
		//Fecha Box
		ROMS023BD()
					
		//Imprime totalizador do ultimo cliente 
		nlinha+=nSaltoLinha 
		nlinha+=nSaltoLinha    
						
		ROMS023Q2(0,0,0)  
		ROMS023PT('TOTAL VENDEDOR:',_cVended,_cDescv,_nTotVend) 
						
		//Imprime totalizador do ultimo coordenador                
		nlinha+=nSaltoLinha 
		nlinha+=nSaltoLinha    
						
		ROMS023Q2(0,0,0)  
		ROMS023PT('TOTAL COORDENADOR:',_cCoord,_aCoord[aScan(_aCoord,{|x| x[1] == _cCoord}),2],_nTotCoord) 
		
		//Fecha o alias criado
		DBSelectArea(_cAlias)
		(_cAlias)->(DBCloseArea())
		
	EndIf       
	
	
		 
//Ordem de Evolucao Mensal - Coordenador x Vendedor x Sub-Grupo	
ElseIf MV_PAR20 == '2'
	
		BeginSql alias _cAlias  
		
			SELECT 
			      F2.F2_VEND2,
				  F2.F2_VEND1,
				  A3.A3_NOME VENDEDOR,
				  F2.F2_EMISSAO,
				  D2.D2_FILIAL,
				  D2.D2_DOC,
				  D2.D2_SERIE,
				  D2.D2_CLIENTE,
				  D2.D2_LOJA,
				  D2.D2_UM,
				  D2.D2_SEGUM, 
				  D2.D2_COD,
				  B1.B1_I_SUBGR,
				  (SELECT ZB9.ZB9_DESSUB FROM ZB9010 ZB9 WHERE ZB9.D_E_L_E_T_ = ' ' AND ZB9.ZB9_SUBGRU = B1.B1_I_SUBGR AND B1.B1_I_SUBGR <> '   ') DESCSUBGR,
					  (
					  SUM(D2.D2_QUANT) -
					   (SELECT COALESCE(SUM(D1.D1_QUANT),0)
					  FROM SD1010 D1
					  WHERE D1.D_E_L_E_T_ = ' '
					  AND D1.D1_TIPO = 'D'
					  AND D1.D1_FILIAL = D2.D2_FILIAL 
					  AND D1.D1_NFORI = D2.D2_DOC
					  AND D1.D1_SERIORI = D2.D2_SERIE
					  AND D1.D1_FORNECE = D2.D2_CLIENTE
					  AND D1.D1_LOJA = D2.D2_LOJA  
					  AND D1.D1_COD = D2.D2_COD
					  )  
					  ) QUANT1UM,
					  (
					  SUM(D2.D2_QTSEGUM) -
					   (SELECT COALESCE(SUM(D1.D1_QTSEGUM),0)
					  FROM SD1010 D1
					  WHERE D1.D_E_L_E_T_ = ' '
					  AND D1.D1_TIPO = 'D'
					  AND D1.D1_FILIAL = D2.D2_FILIAL 
					  AND D1.D1_NFORI = D2.D2_DOC
					  AND D1.D1_SERIORI = D2.D2_SERIE
					  AND D1.D1_FORNECE = D2.D2_CLIENTE
					  AND D1.D1_LOJA = D2.D2_LOJA   
					  AND D1.D1_COD = D2.D2_COD
					  )  
					  ) QUANT2UM,
					  (
					  SUM(D2.D2_VALBRUT)  -
					  (SELECT COALESCE(SUM(D1.D1_TOTAL + D1.D1_ICMSRET),0)
					  FROM SD1010 D1
					  WHERE D1.D_E_L_E_T_ = ' '
					  AND D1.D1_TIPO = 'D'
					  AND D1.D1_FILIAL = D2.D2_FILIAL 
					  AND D1.D1_NFORI = D2.D2_DOC
					  AND D1.D1_SERIORI = D2.D2_SERIE
					  AND D1.D1_FORNECE = D2.D2_CLIENTE
					  AND D1.D1_LOJA = D2.D2_LOJA 
					  AND D1.D1_COD = D2.D2_COD
					  )) VLRBRUT
			FROM 
				SF2010 F2 
				JOIN SD2010 D2 ON F2.F2_FILIAL = D2.D2_FILIAL AND F2.F2_DOC = D2.D2_DOC AND F2.F2_SERIE = D2.D2_SERIE AND F2.F2_CLIENTE = D2.D2_CLIENTE AND F2.F2_LOJA    = D2.D2_LOJA
				JOIN SA1010 A1 ON A1.A1_COD = D2.D2_CLIENTE AND A1.A1_LOJA = D2.D2_LOJA
				JOIN SB1010 B1 ON B1.B1_COD = D2.D2_COD
				JOIN SF4010 F4 ON F4.F4_FILIAL = D2.D2_FILIAL AND F4.F4_CODIGO = D2.D2_TES
				JOIN SA3010 A3 ON F2.F2_VEND1 = A3.A3_COD
			WHERE 
				F2.D_E_L_E_T_ = ' '
				AND D2.D_E_L_E_T_   = ' '
				AND A1.D_E_L_E_T_   = ' '
				AND B1.D_E_L_E_T_   = ' '
				AND F4.D_E_L_E_T_   = ' '
				AND A3.D_E_L_E_T_   = ' '
				AND F4.F4_DUPLIC    = 'S'
				AND B1.B1_I_SUBGR   <> ' '  
				%exp:cFiltro%
			GROUP BY 
				F2.F2_VEND2, F2.F2_VEND1, A3.A3_NOME, F2.F2_EMISSAO, D2.D2_FILIAL, D2.D2_DOC, D2.D2_SERIE, D2.D2_CLIENTE, D2.D2_LOJA, D2.D2_UM, D2.D2_SEGUM, B1.B1_I_SUBGR, D2.D2_COD		
		EndSql   
		
		DBSelectArea(_cAlias)	      
	(_cAlias)->(DBGoTop()) 
	    
	COUNT TO nCountRec //Contabiliza o numero de registros encontrados pela query            
	    
	ProcRegua(nCountRec)
	
	If nCountRec > 0
	  
	     DBSelectArea(_cAlias)	      
		(_cAlias)->(DBGoTop())     
		//Efetua a aglutinacao dos dados	
		While (_cAlias)->(!Eof())                         
		
			IncProc("Processando a aglutinacao dos dados!")
		  
			nPosDados := aScan(_aDados,{|x| x[1] + x[2] + x[3] + x[9] == ;
		   (_cAlias)->F2_VEND2 + (_cAlias)->F2_VEND1 + (_cAlias)->B1_I_SUBGR + SubStr((_cAlias)->F2_EMISSAO,1,6) })
			
			If nPosDados > 0      
			                                               
			    _aDados[nPosDados,6]  += (_cAlias)->QUANT1UM
				_aDados[nPosDados,8]  += (_cAlias)->QUANT2UM
				_aDados[nPosDados,10] += (_cAlias)->VLRBRUT
			
			Else
				//1 - Codigo do Coordenador
				//2 - Codigo do Vendedor
				//3 - Codigo do SubGrupo
				//4 - Descricao do SubGrupo
				//5 - 1 U.M
				//6 - Quantidade na 1 U.M
				//7 - 2 U.M
				//8 - Quantidade na 2 U.M
				//9 - Mes/Ano
				//10 - Valor Bruto     
				//11 - Descricao do Vendedor		
				aAdd(_aDados,{(_cAlias)->F2_VEND2,(_cAlias)->F2_VEND1,(_cAlias)->B1_I_SUBGR,(_cAlias)->DESCSUBGR,(_cAlias)->D2_UM,;
				(_cAlias)->QUANT1UM,(_cAlias)->D2_SEGUM,(_cAlias)->QUANT2UM,SubStr((_cAlias)->F2_EMISSAO,1,6),(_cAlias)->VLRBRUT,(_cAlias)->VENDEDOR })		
			
			EndIf
		
		(_cAlias)->(DBSkip())
		EndDo                   
		
		//Inicia uma nova pagina para impressao
		oPrint:StartPage()   
	    	
	    nPagina++
		ROMS023C(1)//Chama cabecalho  	     	    	    	
		
		//Ordena os Dados do relatorio por Coordenador + Supervisor + ano / mes
		_aDados:= aSort(_aDados,,,{|x, y| x[1] + x[2] + x[3] + x[9] < y[1] + y[2] + y[3] + y[9]})		// Ordenar    
		
		ProcRegua(Len(_aDados))
		                 
		//Efetua a impressao dos dados do Relatorio
		For k:=1 To Len(_aDados) 
		
		    IncProc("Realizando a impressao dos dados do relatorio")
		
			//Verifica a necessidade de quebra por Coordenador    
			If _cCoord <> _aDados[k,1]    
			
				//Verifica a necessidade de impressao do totalizador do Cliente e Coordenador Anterior ao novo Coordenador e imprime box dele
				If k > 1                  
				
					//Fecha Box
					ROMS023D3()       
					
					//Totalizador por Sub-Grupo do Produto    
					nlinha+=nSaltoLinha 
					nlinha+=nSaltoLinha    
					
					ROMS023Q2(0,0,0)  
					ROMS023T2('TOTAL SUB-GRUPO:' + _cSubGrp + ' - ' + _cDescSub,_nTotSb1Qt,_nTotSb2Qt,_nTotSbVBr)					
				
					//Imprime totalizador do ultimo cliente 
					nlinha+=nSaltoLinha 
					nlinha+=nSaltoLinha    
					
					ROMS023Q2(0,0,0)  
					ROMS023T3('TOTAL VENDEDOR: '    + _cVended + '-' + _cDescv,_nTotVend) 
					
					//Imprime totalizador do ultimo coordenador                
					nlinha+=nSaltoLinha 
					nlinha+=nSaltoLinha    
					
					ROMS023Q2(0,0,0)  
					ROMS023T3('TOTAL COORDENADOR: ' + _cCoord  + '-' + _aCoord[aScan(_aCoord,{|x| x[1] == _cCoord}),2],_nTotCoord)  
					
					//Forca a quebra de pagina a cada novo coordenador
					ROMS023QP()
				
				EndIf
			    
				nlinha+=nSaltoLinha 
				nlinha+=nSaltoLinha    
				
				ROMS023Q2(0,0,0)			  
				
				ROMS023CC('Coordenador:',_aDados[k,1],'',0)			     		
				
				//A cada novo Coordenador deve existir um novo vendedor
				nlinha+=nSaltoLinha 
				nlinha+=nSaltoLinha    
				
				ROMS023Q2(0,0,0)   
				
				ROMS023CC('Vendedor:',_aDados[k,2],_aDados[k,11],1) 
				
				//Imprime o cabecalho do Sub-Grupo
				nlinha+=nSaltoLinha 
				nlinha+=nSaltoLinha    
				
				ROMS023Q2(0,0,0)   
				
				ROMS023CS(_aDados[k,3],_aDados[k,4])     
				 
				//Imprime o cabecalho de Dados
				
				nlinha+=nSaltoLinha 
				nlinha+=nSaltoLinha    
				
				ROMS023Q2(0,0,0)   
				
				ROMS023DS() 
				
				//Seta totalizador por vendedor e coordenador
				_nTotCoord:= 0
				_nTotVend := 0    
				
				//Seta totalizador por Sub-Grupo de Produto
				_nTotSb1Qt:= 0
				_nTotSb2Qt:= 0
				_nTotSbVBr:= 0
				
				_cVended:= _aDados[k,2]	  
				_cSubGrp:= _aDados[k,3] 										
			
			EndIf
					
			//Verifica a necessidade de quebra por Vendedor 
			If _cVended <> _aDados[k,2]
			
				//Verifica a necessidade de impressao do totalizador do vendedor anterior  e box do vendedor anterior
				If Len(AllTrim(_cVended)) > 0      
				
					//Fecha Box
					ROMS023D3()     
					
					//Totalizador por Sub-Grupo do Produto    
					nlinha+=nSaltoLinha 
					nlinha+=nSaltoLinha    
					
					ROMS023Q2(0,0,0)  
					ROMS023T2('TOTAL SUB-GRUPO:' + _cSubGrp + ' - ' + _cDescSub,_nTotSb1Qt,_nTotSb2Qt,_nTotSbVBr)	
				
					//Imprime totalizador do ultimo cliente 
					nlinha+=nSaltoLinha 
					nlinha+=nSaltoLinha    
					
					ROMS023Q2(0,0,0)  
					ROMS023T3('TOTAL VENDEDOR: '    + _cVended + '-' + _cDescv,_nTotVend)
					
					ROMS023QP() 
				
				EndIf     
				
				nlinha+=nSaltoLinha 
				nlinha+=nSaltoLinha    
				
				ROMS023Q2(0,0,0)   
				
				ROMS023CC('Vendedor:',_aDados[k,2],_aDados[k,11],1) 
				
				//Imprime o cabecalho do Subgrupo
				nlinha+=nSaltoLinha 
				nlinha+=nSaltoLinha    
				
				ROMS023Q2(0,0,0)   
				
				ROMS023CS(_aDados[k,3],_aDados[k,4])
				
				//Imprime o cabecalho de Dados 
				nlinha+=nSaltoLinha 
				nlinha+=nSaltoLinha    
				
				ROMS023Q2(0,0,0) 
				
				ROMS023DS()
				
				//Seta totalizador por vendedor
				_nTotVend := 0        
				
				//Seta totalizador por Sub-Grupo
				_nTotSb1Qt:= 0
				_nTotSb2Qt:= 0
				_nTotSbVBr:= 0
				
				_cSubGrp:= _aDados[k,3]
			
			EndIf       
			
			
			//Verifica se existe a necessidade de quebra por Sub-Grupo de Produto
			If _cSubGrp <> _aDados[k,3]    
			
				//Verifia a necessidade de impressao do totalizador
				If Len(AllTrim(_cSubGrp)) > 0
				
					//Fecha Box
					ROMS023D3()     
					
					//Totalizador por Sub-Grupo do Produto    
					nlinha+=nSaltoLinha 
					nlinha+=nSaltoLinha    
					
					ROMS023Q2(0,0,0)  
					ROMS023T2('TOTAL SUB-GRUPO:' + _cSubGrp + ' - ' + _cDescSub,_nTotSb1Qt,_nTotSb2Qt,_nTotSbVBr)	
			
			    EndIf    
			    
			    //Imprime o cabecalho do Subgrupo
				nlinha+=nSaltoLinha 
				nlinha+=nSaltoLinha    
				
				ROMS023Q2(0,0,0)   
				
				ROMS023CS(_aDados[k,3],_aDados[k,4])
				
				//Imprime o cabecalho de Dados 
				nlinha+=nSaltoLinha 
				nlinha+=nSaltoLinha    
				
				ROMS023Q2(0,0,0) 
				
				ROMS023DS()      
				
				//Seta totalizador por Sub-Grupo de Produto
				_nTotSb1Qt:= 0
				_nTotSb2Qt:= 0
				_nTotSbVBr:= 0
			
			EndIf
			
		            
		   	nlinha+=nSaltoLinha 
		   	oPrint:Line(nLinha,nColInic + 200,nLinha,nColFinal)  
				
			ROMS023Q2(1,1,1)             
			
			//Funcao para calcular o valor total do Coordenador + vendedor para ser utilizado no calculo da % sobre total
			nTotalVend:=ROMS023C8(_aDados[k,1],_aDados[k,2],_aDados[k,3])
								
			//Imprime os dados do relatorio  
			ROMS023P2(_aDados[k,9],_aDados[k,6],_aDados[k,5],_aDados[k,8],_aDados[k,7],_aDados[k,10],nTotalVend)
			
			//Seta a variavel de controle da quebra por coordenador e Vendedor
			_cCoord  := _aDados[k,1]   
			_cVended := _aDados[k,2]	  
			_cDescv  := _aDados[k,11] 
			_cSubGrp := _aDados[k,3]
			_cDescSub:= _aDados[k,4]	     
			
			//Incrementa variaveis de totalizador
			_nTotCoord += _aDados[k,10]
			_nTotVend  += _aDados[k,10]	        
			
			_nTotSb1Qt += _aDados[k,6]
			_nTotSb2Qt += _aDados[k,8]
			_nTotSbVBr += _aDados[k,10]
		
		Next k  
		
		//Imprime os ultimos totalizadores  
	
		//Fecha Box
		ROMS023D3()   
		
		//Totalizador por Sub-Grupo do Produto    
		nlinha+=nSaltoLinha 
		nlinha+=nSaltoLinha    
					
		ROMS023Q2(0,0,0)  
		ROMS023T2('TOTAL SUB-GRUPO:' + _cSubGrp + ' - ' + _cDescSub,_nTotSb1Qt,_nTotSb2Qt,_nTotSbVBr)	
					
		//Imprime totalizador do ultimo cliente 
		nlinha+=nSaltoLinha 
		nlinha+=nSaltoLinha    
						
		ROMS023Q2(0,0,0)  
		ROMS023T3('TOTAL VENDEDOR: '    + _cVended + '-' + _cDescv,_nTotVend)
						
		//Imprime totalizador do ultimo coordenador                
		nlinha+=nSaltoLinha 
		nlinha+=nSaltoLinha    
						
		ROMS023Q2(0,0,0)  
		ROMS023T3('TOTAL COORDENADOR: ' + _cCoord  + '-' + _aCoord[aScan(_aCoord,{|x| x[1] == _cCoord}),2],_nTotCoord)
		
		//Fecha o alias criado
		DBSelectArea(_cAlias)
		(_cAlias)->(DBCloseArea())
		
		
	EndIf 	
	
//Ordem Evolucao Mensal x Coordenador
ElseIf MV_PAR20 == '3'
	
	BeginSql alias _cAlias 
	
		SELECT 
			  F2.F2_VEND2,
			  F2.F2_VEND1,
			  A3.A3_NOME VENDEDOR,
			  F2.F2_EMISSAO,
			  D2.D2_FILIAL,
			  D2.D2_DOC,
			  D2.D2_SERIE,
			  D2.D2_CLIENTE,
			  D2.D2_LOJA, 
			  D2.D2_COD,
			  (SUM(D2.D2_VALBRUT)  -
			  (SELECT COALESCE(SUM(D1.D1_TOTAL + D1.D1_ICMSRET),0)
			  FROM SD1010 D1
			  WHERE D1.D_E_L_E_T_ = ' '
			  AND D1.D1_TIPO = 'D'
			  AND D1.D1_FILIAL = D2.D2_FILIAL 
			  AND D1.D1_NFORI = D2.D2_DOC
			  AND D1.D1_SERIORI = D2.D2_SERIE
			  AND D1.D1_FORNECE = D2.D2_CLIENTE
			  AND D1.D1_LOJA = D2.D2_LOJA    
			  AND D1.D1_COD = D2.D2_COD
		      )) VLRBRUT
		FROM 
			  SF2010 F2
			  JOIN SD2010 D2 ON F2.F2_FILIAL = D2.D2_FILIAL AND F2.F2_DOC = D2.D2_DOC AND F2.F2_SERIE = D2.D2_SERIE AND F2.F2_CLIENTE = D2.D2_CLIENTE AND F2.F2_LOJA = D2.D2_LOJA
			  JOIN SA1010 A1 ON A1.A1_COD = D2.D2_CLIENTE AND A1.A1_LOJA = D2.D2_LOJA
			  JOIN SB1010 B1 ON B1.B1_COD = D2.D2_COD
			  JOIN SF4010 F4 ON F4.F4_FILIAL = D2.D2_FILIAL AND F4.F4_CODIGO = D2.D2_TES
			  JOIN SA3010 A3 ON F2.F2_VEND1 = A3.A3_COD
		WHERE 
			  F2.D_E_L_E_T_ = ' '
			  AND D2.D_E_L_E_T_   = ' '
			  AND A1.D_E_L_E_T_   = ' '
		      AND B1.D_E_L_E_T_   = ' '
			  AND F4.D_E_L_E_T_   = ' '
			  AND A3.D_E_L_E_T_   = ' '
			  AND F4.F4_DUPLIC    = 'S'  
			  %exp:cFiltro%
		GROUP BY 
		      F2.F2_VEND2, F2.F2_VEND1, A3.A3_NOME, F2.F2_EMISSAO, D2.D2_FILIAL, D2.D2_DOC, D2.D2_SERIE, D2.D2_CLIENTE, D2.D2_LOJA,D2.D2_COD
	
	EndSql 
	
	DBSelectArea(_cAlias)	      
	(_cAlias)->(DBGoTop()) 
	    
	COUNT TO nCountRec //Contabiliza o numero de registros encontrados pela query            
	    
	ProcRegua(nCountRec)
	
	If nCountRec > 0
	  
	     DBSelectArea(_cAlias)	      
		(_cAlias)->(DBGoTop())     
		//Efetua a aglutinacao dos dados	
		While (_cAlias)->(!Eof())                         
		
			IncProc("Processando a aglutinacao dos dados!")
		  
			nPosDados := aScan(_aDados,{|x| x[1] + x[2] == (_cAlias)->F2_VEND2 + SubStr((_cAlias)->F2_EMISSAO,1,6) })
			
			If nPosDados > 0      
			
				_aDados[nPosDados,3] += (_cAlias)->VLRBRUT
			
			Else
				//1 - Codigo do Coordenador
				//2 - Ano e mes da realizacao da venda
				//3 - Valor Bruto da venda      		
				aAdd(_aDados,{(_cAlias)->F2_VEND2,SubStr((_cAlias)->F2_EMISSAO,1,6),(_cAlias)->VLRBRUT})		
			
			EndIf
		
		(_cAlias)->(DBSkip())
		EndDo                   
		
		//Inicia uma nova pagina para impressao
		oPrint:StartPage()   
	    	
	    nPagina++
		ROMS023C(1)//Chama cabecalho  	     	    	    	
		
		//Ordena os Dados do relatorio por Coordenador + Supervisor + ano / mes
		_aDados:= aSort(_aDados,,,{|x, y| x[1] + x[2] < y[1] + y[2] })		// Ordenar    
		
		ProcRegua(Len(_aDados))
		                 
		//Efetua a impressao dos dados do Relatorio
		For k:=1 To Len(_aDados)     
		
			IncProc("Realizando a impressao dos dados do relatorio")
		
			//Verifica a necessidade de quebra por Coordenador    
			If _cCoord <> _aDados[k,1]    
			
				//Verifica a necessidade de impressao do totalizador do Cliente e Coordenador Anterior ao novo Coordenador e imprime box dele
				If k > 1                  
				
					//Fecha Box
					ROMS023BD()				
					
					//Imprime totalizador do ultimo coordenador                
					nlinha+=nSaltoLinha 
					nlinha+=nSaltoLinha    
					
					ROMS023Q2(0,0,0)  
					ROMS023PT('TOTAL COORDENADOR:',_cCoord,_aCoord[aScan(_aCoord,{|x| x[1] == _cCoord}),2],_nTotCoord)  
					
					//Forca a quebra de pagina a cada novo coordenador
					ROMS023QP()
				
				EndIf
			    
				nlinha+=nSaltoLinha 
				nlinha+=nSaltoLinha    
				
				ROMS023Q2(0,0,0)			  
				
				ROMS023CC('Coordenador:',_aDados[k,1],'',0)			     						
				
				//Imprime o cabecalho de Dados 
				nlinha+=nSaltoLinha 
				nlinha+=nSaltoLinha    
				
				ROMS023Q2(0,0,0)   
				
				ROMS023CD()
				
				//Seta totalizador por vendedor e coordenador
				_nTotCoord:= 0													
			
			EndIf							
		            
		   	nlinha+=nSaltoLinha 
		   	oPrint:Line(nLinha,nColInic,nLinha,nColFinal)  
				
			ROMS023Q2(1,1,1)             
			
			//Funcao para calcular o valor total do Coordenador + vendedor para ser utilizado no calculo da % sobre total
			nTotalVend:=ROMS023CO(_aDados[k,1])
								
			//Imprime os dados do relatorio  
			ROMS023PD(_aDados[k,2],_aDados[k,3],nTotalVend)
			
			//Seta a variavel de controle da quebra por coordenador 
			_cCoord := _aDados[k,1]    
			
			//Incrementa variaveis de totalizador
			_nTotCoord += _aDados[k,3]
		
		Next k  
		
		//Imprime os ultimos totalizadores  
	
		//Fecha Box
		ROMS023BD()					
						
		//Imprime totalizador do ultimo coordenador                
		nlinha+=nSaltoLinha 
		nlinha+=nSaltoLinha    
						
		ROMS023Q2(0,0,0)  
		ROMS023PT('TOTAL COORDENADOR:',_cCoord,_aCoord[aScan(_aCoord,{|x| x[1] == _cCoord}),2],_nTotCoord) 
		
		//Fecha o alias criado
		DBSelectArea(_cAlias)
		(_cAlias)->(DBCloseArea())
		
	EndIf       

//ORDEM EVOLUCAO MENSAL - COORDENADOR X SUB-GRUPO      	
ElseIf MV_PAR20 == '4'
	
		BeginSql alias _cAlias  
		
			SELECT 
			      F2.F2_VEND2,
				  F2.F2_VEND1,
				  A3.A3_NOME VENDEDOR,
				  F2.F2_EMISSAO,
				  D2.D2_FILIAL,
				  D2.D2_DOC,
				  D2.D2_SERIE,
				  D2.D2_CLIENTE,
				  D2.D2_LOJA,
				  D2.D2_UM,
				  D2.D2_SEGUM, 
				  D2.D2_COD,
				  B1.B1_I_SUBGR,
				  (SELECT ZB9.ZB9_DESSUB FROM ZB9010 ZB9 WHERE ZB9.D_E_L_E_T_ = ' ' AND ZB9.ZB9_SUBGRU = B1.B1_I_SUBGR AND B1.B1_I_SUBGR <> '   ') DESCSUBGR,
					  (
					  SUM(D2.D2_QUANT) -
					   (SELECT COALESCE(SUM(D1.D1_QUANT),0)
					  FROM SD1010 D1
					  WHERE D1.D_E_L_E_T_ = ' '
					  AND D1.D1_TIPO = 'D'
					  AND D1.D1_FILIAL = D2.D2_FILIAL 
					  AND D1.D1_NFORI = D2.D2_DOC
					  AND D1.D1_SERIORI = D2.D2_SERIE
					  AND D1.D1_FORNECE = D2.D2_CLIENTE
					  AND D1.D1_LOJA = D2.D2_LOJA  
					  AND D1.D1_COD = D2.D2_COD
					  )  
					  ) QUANT1UM,
					  (
					  SUM(D2.D2_QTSEGUM) -
					   (SELECT COALESCE(SUM(D1.D1_QTSEGUM),0)
					  FROM SD1010 D1
					  WHERE D1.D_E_L_E_T_ = ' '
					  AND D1.D1_TIPO = 'D'
					  AND D1.D1_FILIAL = D2.D2_FILIAL 
					  AND D1.D1_NFORI = D2.D2_DOC
					  AND D1.D1_SERIORI = D2.D2_SERIE
					  AND D1.D1_FORNECE = D2.D2_CLIENTE
					  AND D1.D1_LOJA = D2.D2_LOJA   
					  AND D1.D1_COD = D2.D2_COD
					  )  
					  ) QUANT2UM,
					  (
					  SUM(D2.D2_VALBRUT)  -
					  (SELECT COALESCE(SUM(D1.D1_TOTAL + D1.D1_ICMSRET),0)
					  FROM SD1010 D1
					  WHERE D1.D_E_L_E_T_ = ' '
					  AND D1.D1_TIPO = 'D'
					  AND D1.D1_FILIAL = D2.D2_FILIAL 
					  AND D1.D1_NFORI = D2.D2_DOC
					  AND D1.D1_SERIORI = D2.D2_SERIE
					  AND D1.D1_FORNECE = D2.D2_CLIENTE
					  AND D1.D1_LOJA = D2.D2_LOJA 
					  AND D1.D1_COD = D2.D2_COD
					  )) VLRBRUT
			FROM 
				SF2010 F2 
				JOIN SD2010 D2 ON F2.F2_FILIAL = D2.D2_FILIAL AND F2.F2_DOC = D2.D2_DOC AND F2.F2_SERIE = D2.D2_SERIE AND F2.F2_CLIENTE = D2.D2_CLIENTE AND F2.F2_LOJA    = D2.D2_LOJA
				JOIN SA1010 A1 ON A1.A1_COD = D2.D2_CLIENTE AND A1.A1_LOJA = D2.D2_LOJA
				JOIN SB1010 B1 ON B1.B1_COD = D2.D2_COD
				JOIN SF4010 F4 ON F4.F4_FILIAL = D2.D2_FILIAL AND F4.F4_CODIGO = D2.D2_TES
				JOIN SA3010 A3 ON F2.F2_VEND1 = A3.A3_COD
			WHERE 
				F2.D_E_L_E_T_ = ' '
				AND D2.D_E_L_E_T_   = ' '
				AND A1.D_E_L_E_T_   = ' '
				AND B1.D_E_L_E_T_   = ' '
				AND F4.D_E_L_E_T_   = ' '
				AND A3.D_E_L_E_T_   = ' '
				AND F4.F4_DUPLIC    = 'S'
				AND B1.B1_I_SUBGR   <> ' '  
				%exp:cFiltro%
			GROUP BY 
				F2.F2_VEND2, F2.F2_VEND1, A3.A3_NOME, F2.F2_EMISSAO, D2.D2_FILIAL, D2.D2_DOC, D2.D2_SERIE, D2.D2_CLIENTE, D2.D2_LOJA, D2.D2_UM, D2.D2_SEGUM, B1.B1_I_SUBGR, D2.D2_COD		
		EndSql   
		
		DBSelectArea(_cAlias)	      
	(_cAlias)->(DBGoTop()) 
	    
	COUNT TO nCountRec //Contabiliza o numero de registros encontrados pela query            
	    
	ProcRegua(nCountRec)
	
	If nCountRec > 0
	  
	     DBSelectArea(_cAlias)	      
		(_cAlias)->(DBGoTop())     
		//Efetua a aglutinacao dos dados	
		While (_cAlias)->(!Eof())                         
		
			IncProc("Processando a aglutinacao dos dados!")
		  
			nPosDados := aScan(_aDados,{|x| x[1] + x[3] + x[9] == ;
		   (_cAlias)->F2_VEND2 + (_cAlias)->B1_I_SUBGR + SubStr((_cAlias)->F2_EMISSAO,1,6) })
			
			If nPosDados > 0      
			                                               
			    _aDados[nPosDados,6]  += (_cAlias)->QUANT1UM
				_aDados[nPosDados,8]  += (_cAlias)->QUANT2UM
				_aDados[nPosDados,10] += (_cAlias)->VLRBRUT
			
			Else
				//1 - Codigo do Coordenador
				//2 - Codigo do Vendedor
				//3 - Codigo do SubGrupo
				//4 - Descricao do SubGrupo
				//5 - 1 U.M
				//6 - Quantidade na 1 U.M
				//7 - 2 U.M
				//8 - Quantidade na 2 U.M
				//9 - Mes/Ano
				//10 - Valor Bruto     
				//11 - Descricao do Vendedor		
				aAdd(_aDados,{(_cAlias)->F2_VEND2,(_cAlias)->F2_VEND1,(_cAlias)->B1_I_SUBGR,(_cAlias)->DESCSUBGR,(_cAlias)->D2_UM,;
				(_cAlias)->QUANT1UM,(_cAlias)->D2_SEGUM,(_cAlias)->QUANT2UM,SubStr((_cAlias)->F2_EMISSAO,1,6),(_cAlias)->VLRBRUT,(_cAlias)->VENDEDOR })		
			
			EndIf
		
		(_cAlias)->(DBSkip())
		EndDo                   
		
		//Inicia uma nova pagina para impressao
		oPrint:StartPage()   
	    	
	    nPagina++
		ROMS023C(1)//Chama cabecalho  	     	    	    	
		
		//Ordena os Dados do relatorio por Coordenador + Supervisor + ano / mes
		_aDados:= aSort(_aDados,,,{|x, y| x[1] + x[3] + x[9] < y[1] + y[3] + y[9]})		// Ordenar    
		
		ProcRegua(Len(_aDados))
		                 
		//Efetua a impressao dos dados do Relatorio
		For k:=1 To Len(_aDados) 
		
		    IncProc("Realizando a impressao dos dados do relatorio")
		
			//Verifica a necessidade de quebra por Coordenador    
			If _cCoord <> _aDados[k,1]    
			
				//Verifica a necessidade de impressao do totalizador do Cliente e Coordenador Anterior ao novo Coordenador e imprime box dele
				If k > 1                  
				
					//Fecha Box
					ROMS023D3()       
					
					//Totalizador por Sub-Grupo do Produto    
					nlinha+=nSaltoLinha 
					nlinha+=nSaltoLinha    
					
					ROMS023Q2(0,0,0)  
					ROMS023T2('TOTAL SUB-GRUPO:' + _cSubGrp + ' - ' + _cDescSub,_nTotSb1Qt,_nTotSb2Qt,_nTotSbVBr)											
					
					//Imprime totalizador do ultimo coordenador                
					nlinha+=nSaltoLinha 
					nlinha+=nSaltoLinha    
					
					ROMS023Q2(0,0,0)  
					ROMS023T3('TOTAL COORDENADOR: ' + _cCoord  + '-' + _aCoord[aScan(_aCoord,{|x| x[1] == _cCoord}),2],_nTotCoord)  
					
					//Forca a quebra de pagina a cada novo coordenador
					ROMS023QP()
				
				EndIf
			    
				nlinha+=nSaltoLinha 
				nlinha+=nSaltoLinha    
				
				ROMS023Q2(0,0,0)			  
				
				ROMS023CC('Coordenador:',_aDados[k,1],'',0)			     							
				
				//Imprime o cabecalho do Sub-Grupo
				nlinha+=nSaltoLinha 
				nlinha+=nSaltoLinha    
				
				ROMS023Q2(0,0,0)   
				
				ROMS023CS(_aDados[k,3],_aDados[k,4])     
				 
				//Imprime o cabecalho de Dados
				
				nlinha+=nSaltoLinha 
				nlinha+=nSaltoLinha    
				
				ROMS023Q2(0,0,0)   
				
				ROMS023DS() 
				
				//Seta totalizador por vendedor e coordenador
				_nTotCoord:= 0   
				
				//Seta totalizador por Sub-Grupo de Produto
				_nTotSb1Qt:= 0
				_nTotSb2Qt:= 0
				_nTotSbVBr:= 0
				
				_cSubGrp:= _aDados[k,3] 										
			
			EndIf											
			
			//Verifica se existe a necessidade de quebra por Sub-Grupo de Produto
			If _cSubGrp <> _aDados[k,3]    
			
				//Verifia a necessidade de impressao do totalizador
				If Len(AllTrim(_cSubGrp)) > 0
				
					//Fecha Box
					ROMS023D3()     
					
					//Totalizador por Sub-Grupo do Produto    
					nlinha+=nSaltoLinha 
					nlinha+=nSaltoLinha    
					
					ROMS023Q2(0,0,0)  
					ROMS023T2('TOTAL SUB-GRUPO:' + _cSubGrp + ' - ' + _cDescSub,_nTotSb1Qt,_nTotSb2Qt,_nTotSbVBr)	
			
			    EndIf    
			    
			    //Imprime o cabecalho do Subgrupo
				nlinha+=nSaltoLinha 
				nlinha+=nSaltoLinha    
				
				ROMS023Q2(0,0,0)   
				
				ROMS023CS(_aDados[k,3],_aDados[k,4])
				
				//Imprime o cabecalho de Dados 
				nlinha+=nSaltoLinha 
				nlinha+=nSaltoLinha    
				
				ROMS023Q2(0,0,0) 
				
				ROMS023DS()      
				
				//Seta totalizador por Sub-Grupo de Produto
				_nTotSb1Qt:= 0
				_nTotSb2Qt:= 0
				_nTotSbVBr:= 0
			
			EndIf
			
		            
		   	nlinha+=nSaltoLinha 
		   	oPrint:Line(nLinha,nColInic + 200,nLinha,nColFinal)  
				
			ROMS023Q2(1,1,1)             
			
			//Funcao para calcular o valor total do Coordenador + vendedor para ser utilizado no calculo da % sobre total
			nTotalVend:=ROMS023C7(_aDados[k,1],_aDados[k,3])
								
			//Imprime os dados do relatorio  
			ROMS023P2(_aDados[k,9],_aDados[k,6],_aDados[k,5],_aDados[k,8],_aDados[k,7],_aDados[k,10],nTotalVend)
			
			//Seta a variavel de controle da quebra por coordenador e Vendedor
			_cCoord  := _aDados[k,1]   
			_cSubGrp := _aDados[k,3]
			_cDescSub:= _aDados[k,4]	     
			
			//Incrementa variaveis de totalizador
			_nTotCoord += _aDados[k,10]	        
			
			_nTotSb1Qt += _aDados[k,6]
			_nTotSb2Qt += _aDados[k,8]
			_nTotSbVBr += _aDados[k,10]
		
		Next k  
		
		//Imprime os ultimos totalizadores  
	
		//Fecha Box
		ROMS023D3()   
		
		//Totalizador por Sub-Grupo do Produto    
		nlinha+=nSaltoLinha 
		nlinha+=nSaltoLinha    
					
		ROMS023Q2(0,0,0)  
		ROMS023T2('TOTAL SUB-GRUPO:' + _cSubGrp + ' - ' + _cDescSub,_nTotSb1Qt,_nTotSb2Qt,_nTotSbVBr)						
						
		//Imprime totalizador do ultimo coordenador                
		nlinha+=nSaltoLinha 
		nlinha+=nSaltoLinha    
						
		ROMS023Q2(0,0,0)  
		ROMS023T3('TOTAL COORDENADOR: ' + _cCoord  + '-' + _aCoord[aScan(_aCoord,{|x| x[1] == _cCoord}),2],_nTotCoord)
		
		//Fecha o alias criado
		DBSelectArea(_cAlias)
		(_cAlias)->(DBCloseArea())
		
	EndIf 
		 
EndIf 
      
Return     

/*
===============================================================================================================================
Programa--------: ROMS023CT
Autor-----------: Fabiano Dias
Data da Criacao-: 24/02/2011
===============================================================================================================================
Descricao-------: Calcula total por representante
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS023CT(cCodCoord,cCodVend)  

Local nPosTot:= 0 
Local nTotal := 0
Local y		:= 0

nPosTot := aScan(_aPorce,{|x| x[1] == cCodCoord + cCodVend }) 

If nPosTot > 0

	nTotal:= _aPorce[nPosTot,2]

Else
		
	For y:=1 to Len(_aDados)    
		
		If _aDados[y,1] + _aDados[y,2] == cCodCoord + cCodVend 
		
			nTotal += _aDados[y,5]      
		
		EndIf
					
	Next y	 
		
	//Insere no array totalizador o valor total calculado para o coordenador + vendedor
	aAdd(_aPorce,{cCodCoord + cCodVend,nTotal})
	
EndIf 

Return nTotal  

/*
===============================================================================================================================
Programa--------: ROMS023CO
Autor-----------: Fabiano Dias
Data da Criacao-: 24/02/2011
===============================================================================================================================
Descricao-------: Calcula total por coordenador
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS023CO(cCodCoord)  

Local nPosTot:= 0 
Local nTotal := 0
Local y		:= 0
nPosTot := aScan(_aPorce,{|x| x[1] == cCodCoord }) 

If nPosTot > 0

	nTotal:= _aPorce[nPosTot,2]

Else
		
	For y:=1 to Len(_aDados)    
		
		If _aDados[y,1] == cCodCoord  
		
			nTotal += _aDados[y,3]      
		
		EndIf
					
	Next y	 
		
	//Insere no array totalizador o valor total calculado para o coordenador + vendedor
	aAdd(_aPorce,{cCodCoord,nTotal})
	
EndIf 

Return nTotal   

/*
===============================================================================================================================
Programa--------: ROMS023C8
Autor-----------: Fabiano Dias
Data da Criacao-: 24/02/2011
===============================================================================================================================
Descricao-------: Calcula total por subgrupo
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS023C8(cCodCoord,cCodVend,cSubGrupo)  

Local nTotal := 0
Local y		:= 0
For y:=1 to Len(_aDados)    
		
			If _aDados[y,1] + _aDados[y,2] + _aDados[y,3] == cCodCoord + cCodVend + cSubGrupo
		
				nTotal += _aDados[y,10]      
		
			EndIf
					
Next y	 		
	
Return nTotal              

/*
===============================================================================================================================
Programa--------: ROMS023C7
Autor-----------: Fabiano Dias
Data da Criacao-: 24/02/2011
===============================================================================================================================
Descricao-------: Calcula total por subgrupo
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS023C7(cCodCoord,cSubGrupo)  

Local nTotal := 0
Local y		:= 0

For y:=1 to Len(_aDados)    
		
			If _aDados[y,1] + _aDados[y,3] == cCodCoord + cSubGrupo
		
				nTotal += _aDados[y,10]      
		
			EndIf					
Next y	 		
	
Return nTotal

/*
===============================================================================================================================
Programa--------: lstTpRelat
Autor-----------: Fabiano Dias
Data da Criacao-: 24/02/2011
===============================================================================================================================
Descricao-------: Monta Tela para consulta dos tipos de relatorios na LSTREL da SXB
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function lstTpRelat()

Local i 		  := 0 
Local aOpcoes	  := {}	

Private nTam      := 0
Private nMaxSelect:= 0
Private aCat      := {}
Private MvRet     := AllTrim(ReadVar())
Private MvPar     := ""
Private cTitulo   := ""
Private MvParDef  := ""

#IFDEF WINDOWS
	oWnd := GetWndDefault()
#EndIf

//Tratamento para carregar variaveis da lista de opcoes
nTam:= 1
cTitulo :="TIPOS DE RELATORIOS"

aAdd(aOpcoes,{'1','Evolucao de Vendas Mes a Mes - Vendedor'})
aAdd(aOpcoes,{'2','Evolucao de Vendas Mes a Mes - Vendedor x Sub-Grupo'}) 
aAdd(aOpcoes,{'3','Evolucao de Vendas Mes a Mes - Coordenador'}) 
aAdd(aOpcoes,{'4','Evolucao de Vendas Mes a Mes - Coordenador x Sub-Grupo'}) 

nMaxSelect := 1        

For i := 1 to Len (aOpcoes)

	MvParDef += aOpcoes[i,1]
	aAdd(aCat,aOpcoes[i,2])	
		
Next i 			 

MvPar:= PadR(AllTrim(StrTran(&MvRet,";","")),Len(aCat))
&MvRet:= PadR(AllTrim(StrTran(&MvRet,";","")),Len(aCat))


//Executa funcao que monta tela de opcoes
f_Opcoes(@MvPar,cTitulo,aCat,MvParDef,12,49,.F.,nTam,nMaxSelect)


//Tratamento para separar retorno com barra ";"
&MvRet := ""
For i:=1 to Len(MvPar) step 1
	If !(SubStr(MvPar,i,1) $ " |*")
		&MvRet  += SubStr(MvPar,i,1) + ";"
	EndIf
Next i


//Trata para tirar o ultimo caracter
&MvRet := SubStr(&MvRet,1,Len(&MvRet)-1)

Return(.T.)
