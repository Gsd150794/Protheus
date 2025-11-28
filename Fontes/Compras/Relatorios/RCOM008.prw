/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |08/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25.
Alex Walluer  |18/08/2022| Chamado 41063. Criar filtro novo: Grupo (multipla escolha) --> campo para filtragem D2_GRUPO.
Lucas Borges  |09/10/2024| Chamado 48465. Retirada manipulação do SX1
===============================================================================================================================
*/

#Include "Report.ch"
#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: RCOM008
Autor-----------: Fabiano Dias
Data da Criacao-: 29/06/2014
Descrição-------: Relatório para demonstrar as notas fiscais de devolução de compras.
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function RCOM008()
    
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
Private nqbrPagina  := 2250  
Private nLinInBox
Private nLinInDado   
Private nSaltoLinha := 50               

Private _cPerg      := "RCOM008"                                                                              

Define Font oFont10    Name "Courier New"       Size 0,-08       // Tamanho 14    
Define Font oFont10b   Name "Courier New"       Size 0,-08 Bold   // Tamanho 14 
Define Font oFont12    Name "Courier New"       Size 0,-10       // Tamanho 12
Define Font oFont12b   Name "Courier New"       Size 0,-10 Bold  // Tamanho 12 Negrito  
Define Font oFont14    Name "Courier New"       Size 0,-10       // Tamanho 14
Define Font oFont14b   Name "Courier New"       Size 0,-10 Bold  // Tamanho 14         
Define Font oFont14Prb Name "Courier New"       Size 0,-12 Bold  // Tamanho 14 Negrito
Define Font oFont16b   Name "Helvetica"         Size 0,-14 Bold  // Tamanho 16 Negrito   

oPrint:= TMSPrinter():New("DEVOLUCAO DE COMPRAS")  
oPrint:SetLandscape() 	// Paisagem
oPrint:SetPaperSize(9)	// Seta para papel A4

oPrint:StartPage() 

If !Pergunte(_cPerg,.T.) 
     Return
EndIf
//0 - para nao imprimir a numeracao de pagina na emissao da pagina de parametros
RCOM008ICP(0)   
RCOM008IPP()
		     		            		
Processa({|| RCOM008DDR() })  
			
oPrint:EndPage()	// Finaliza a Pagina.
oPrint:Preview()	// Visualiza antes de Imprimir.

Return       
   
/*
===============================================================================================================================
Programa--------: RCOM008IPP
Autor-----------: Fabiano Dias
Data da Criacao-: 29/06/2014
Descrição-------: Funcao criada para impressao da pagina de parametros do relatorio
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function RCOM008IPP()      

Local nAux		:= 1   
Local nqtdeCar	:= 0
Local _aDadosPegunte := {}
Local _nI
Local _cTexto

//Quantidade de caracteres para quebra de Linha
nqtdeCar:= 84	

oPrint:StartPage()   // Inicia uma nova página     
nLinha+= 080                                    
oPrint:Line(nLinha,nColInic,nLinha,nColFinal)
nLinha+= 60

aAdd(_aDadosPegunte,{"01", "Da Filial ?"             , "MV_PAR01"})       
aAdd(_aDadosPegunte,{"02", "Da Dt.Saida ?"           , "MV_PAR02"})           
aAdd(_aDadosPegunte,{"03", "Ate Dt.Saida ?"          , "MV_PAR03"})
aAdd(_aDadosPegunte,{"04", "Do Fornecedor ?"         , "MV_PAR04"})           
aAdd(_aDadosPegunte,{"05", "Da Loja ?"               , "MV_PAR05"})          
aAdd(_aDadosPegunte,{"06", "Ate Fornecedor ?"        , "MV_PAR06"})
aAdd(_aDadosPegunte,{"07", "Ate Loja ?"              , "MV_PAR07"})
aAdd(_aDadosPegunte,{"08", "Tipo devolucao ?"        , "MV_PAR08"})  //-->"Gerou financeiro" ## "Não gerou" ## "Ambas"
aAdd(_aDadosPegunte,{"09", "NDF Compensadas ?"       , "MV_PAR09"})  //-->"Sim"              ## "Não"       ## "Ambas"
aAdd(_aDadosPegunte,{"10", "Ordem ?"                 , "MV_PAR10"})  //-->"Emissão"          ##       
aAdd(_aDadosPegunte,{"11", "Considera Desc Suframa ?", "MV_PAR11"})  //-->"Sim"              ## "Não"
aAdd(_aDadosPegunte,{"12", "Grupo Produto ?"         , "MV_PAR12"})

For _nI := 1 To Len(_aDadosPegunte)          
	nAux:= 1      
	
	oPrint:Say (nLinha,nColInic + 10,"Pergunta " + _aDadosPegunte[_nI,1] + ':' +  _aDadosPegunte[_nI,2] , oFont14Prb)    
		
	If _aDadosPegunte[_nI,3] == "MV_PAR08"
	   If MV_PAR08 ==  1
	      _cTexto := "Gerou financeiro"
	   ElseIf MV_PAR08 == 2
	      _cTexto := "Não gerou financ."
	   ElseIf MV_PAR08 == 3
	      _cTexto := "Ambos"
	   Else
	      _cTexto := ""
	   EndIf
	ElseIf _aDadosPegunte[_nI,3] == "MV_PAR09"
       If MV_PAR09 ==  1
	      _cTexto := "Sim"
	   ElseIf MV_PAR09 == 2
	      _cTexto := "Não"
	   ElseIf MV_PAR09 == 3
	      _cTexto := "Ambos"
	   Else
	      _cTexto := ""
	   EndIf
	ElseIf _aDadosPegunte[_nI,3] == "MV_PAR11"
       If MV_PAR11 ==  1
	      _cTexto := "Sim"
	   ElseIf MV_PAR11 == 2
	      _cTexto := "Não"
	   Else
	      _cTexto := ""
	   EndIf
	ElseIf _aDadosPegunte[_nI,3] == "MV_PAR10"  
	   _cTexto := "Emissão"
    Else
       _cTexto := &(_aDadosPegunte[_nI,3])
       If ValType(_cTexto) == "D"
          _cTexto := DToC(_cTexto)
       EndIf   
    EndIf	
    oPrint:Say (nLinha,1200,_cTexto,oFont14Prb)  		
	    
	nLinha+= 60
Next
  
nLinha+= 60
oPrint:Line(nLinha,nColInic,nLinha,nColFinal)
	
oPrint:EndPage()     // Finaliza a página

Return
            
/*
===============================================================================================================================
Programa--------: RCOM008ICP
Autor-----------: Fabiano Dias
Data da Criacao-: 29/06/2014
Descrição-------: Funcao criada para impressao do cabeçalho da pagina
Parametros------: impNrPag - Define se imprime o número da página
Retorno---------: Nenhum
===============================================================================================================================
*/

Static Function RCOM008ICP( impNrPag )

Local cRaizServer := IIf( issrvunix() , "/" , "\" )
Local cTitulo     := "DEVOLUÇÕES DE COMPRAS - DE " +  DToC(MV_PAR02) + " À " + DToC(MV_PAR03)
 
 
nLinha:=0100

	oPrint:SayBitmap(nLinha,nColInic,cRaizServer + "system/lgrl01.bmp",250,100)        
	If impNrPag <> 0
		oPrint:Say (nlinha,(nColInic + 2750),"PÁGINA: " + AllTrim(Str(nPagina)),oFont12b)
		Else
			oPrint:Say (nlinha,(nColInic + 2750),"SIGA/RCOM008",oFont12b)
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
Programa--------: RCOM008CDF
Autor-----------: Fabiano Dias
Data da Criacao-: 29/06/2014
Descrição-------: Funcao criada para impressao do cabeçalho da pagina
Parametros------: impNrPag - Define se imprime o número da página
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function RCOM008CDF(_cCodFil)       

//Armazena a linha inicial do box geral do relatorio
nLinInBox := nlinha                                

//====================================================================================================
//Verifica a necessidade de quebra de pagina para o cabecalho.
//====================================================================================================
RCOM008QBP(0,.F.,.F.,"","",2) 

oPrint:Say (nlinha,nColInic + 20 ,"CÓDIGO",oFont12b)
oPrint:Say (nlinha,nColInic + 220,"FILIAL",oFont12b) 
nlinha+=nSaltoLinha

oPrint:Say (nlinha,nColInic + 20 ,_cCodFil					,oFont12)    
oPrint:Say (nlinha,nColInic + 220,FWFilialName(, _cCodFil )	,oFont12)  
nlinha+=nSaltoLinha 
oPrint:Line(nLinha,nColInic,nLinha,nColFinal)

Return      

/*
===============================================================================================================================
Programa--------: RCOM008CNF
Autor-----------: Fabiano Dias
Data da Criacao-: 29/06/2014
Descrição-------: Funcao criada para impressao do cabeçalho da pagina
Parametros------: Dados da NF
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function RCOM008CNF( _sDtEmis , _cDoc , _cSerie , _cDocOri , _cSerieOri , _cCodForn , _cLjForn , _cDesForn , _cMunic , _cEst )

//====================================================================================================
//Verifica a necessidade de quebra de pagina para o cabecalho.
//====================================================================================================
RCOM008QBP(1,.T.,.F.,"RCOM008IBR()","",3) 

oPrint:Say (nlinha,nColInic + 20  ,"DT.SAÍDA"	  ,oFont12b)
oPrint:Say (nlinha,nColInic + 416 ,"NDF-SÉRIE"   ,oFont12b) 
oPrint:Say (nlinha,nColInic + 812 ,"NF REF-SÉRIE",oFont12b)
oPrint:Say (nlinha,nColInic + 1208,"For-LOJA"    ,oFont12b) 
oPrint:Say (nlinha,nColInic + 1604,"NOME"		  ,oFont12b)
oPrint:Say (nlinha,nColInic + 2404,"MUNICÍPIO"   ,oFont12b) 
oPrint:Say (nlinha,nColInic + 3204,"ESTADO"      ,oFont12b)          

nlinha+=nSaltoLinha

oPrint:Say (nlinha,nColInic + 20  ,DToC(SToD(_sDtEmis))							 	,oFont12)
oPrint:Say (nlinha,nColInic + 416 ,AllTrim(_cDoc) + '-' + AllTrim(_cSerie)   	 	,oFont12) 
oPrint:Say (nlinha,nColInic + 812 ,AllTrim(_cDocOri) + '-' + AllTrim(_cSerieOri)	,oFont12)
oPrint:Say (nlinha,nColInic + 1208,_cCodForn + '-' + _cLjForn    				  	,oFont12) 
oPrint:Say (nlinha,nColInic + 1604,SubStr(_cDesForn,1,35)						  	,oFont12)
oPrint:Say (nlinha,nColInic + 2404,SubStr(_cMunic,1,34)						  		,oFont12) 
oPrint:Say (nlinha,nColInic + 3204,_cEst      									  	,oFont12)

Return

/*
===============================================================================================================================
Programa--------: RCOM008ICD
Autor-----------: Fabiano Dias
Data da Criacao-: 29/06/2014
Descrição-------: Funcao criada para impressao do cabeçalho de dados
Parametros------: Dados da NF
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function RCOM008ICD()

nLinInDado:= nlinha 

oPrint:Say (nlinha,nColInic + 20  ,"ITEM"	  		,oFont12b)
oPrint:Say (nlinha,nColInic + 220 ,"COD - PRODUTO"	,oFont12b)
oPrint:Say (nlinha,nColInic + 1500,"QTDE"	  		,oFont12b)
oPrint:Say (nlinha,nColInic + 1616,"1A.UM"	  		,oFont12b)
oPrint:Say (nlinha,nColInic + 2020,"QTDE 2A.UM"	  	,oFont12b)
oPrint:Say (nlinha,nColInic + 2262,"2A.UM"	  		,oFont12b)
oPrint:Say (nlinha,nColInic + 2732,"VLR.UNIT."	  	,oFont12b)
oPrint:Say (nlinha,nColInic + 3130,"VLR.TOTAL"	  	,oFont12b)

Return         

/*
===============================================================================================================================
Programa--------: RCOM008IDR
Autor-----------: Fabiano Dias
Data da Criacao-: 29/06/2014
Descrição-------: Funcao criada para impressao dos dados do relatório
Parametros------: Dados da NF
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function RCOM008IDR(_cItem,_cCodProd,_cDescProd,_nQtde1,_c1UM,_nQtde2,_c2UM,_nVlrUnit,_nVlrTotal)

oPrint:Say (nlinha,nColInic + 20  ,_cItem	  													,oFont12)
oPrint:Say (nlinha,nColInic + 220 ,SubStr(AllTrim(_cCodProd) + '-' +  AllTrim(_cDescProd),1,43)	,oFont12)
oPrint:Say (nlinha,nColInic + 1240,Transform(_nQtde1,"@E 9,999,999,999.99")	  				 	,oFont12)
oPrint:Say (nlinha,nColInic + 1616,_c1UM	  													,oFont12)
oPrint:Say (nlinha,nColInic + 1886,Transform(_nQtde2,"@E 9,999,999,999.99")					 	,oFont12)
oPrint:Say (nlinha,nColInic + 2262,_c2UM	  													,oFont12)
oPrint:Say (nlinha,nColInic + 2572,Transform(_nVlrUnit,"@E 9,999,999,999.99")	  				,oFont12)
oPrint:Say (nlinha,nColInic + 2988,Transform(_nVlrTotal,"@E 9,999,999,999.99")					,oFont12)

Return    

/*
===============================================================================================================================
Programa--------: RCOM008IBD
Autor-----------: Fabiano Dias
Data da Criacao-: 29/06/2014
Descrição-------: Funcao criada para impressao dos dados do relatório
Parametros------: Dados da NF
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function RCOM008IBD()

oPrint:Line(nLinInDado,nColInic + 210 ,nLinha + nSaltoLinha,nColInic  + 0210) 
oPrint:Line(nLinInDado,nColInic + 1210,nLinha + nSaltoLinha,nColInic  + 1210) 
oPrint:Line(nLinInDado,nColInic + 1606,nLinha + nSaltoLinha,nColInic  + 1606)    
oPrint:Line(nLinInDado,nColInic + 1856,nLinha + nSaltoLinha,nColInic  + 1856) 
oPrint:Line(nLinInDado,nColInic + 2252,nLinha + nSaltoLinha,nColInic  + 2252) 
oPrint:Line(nLinInDado,nColInic + 2502,nLinha + nSaltoLinha,nColInic  + 2502)    
oPrint:Line(nLinInDado,nColInic + 2938,nLinha + nSaltoLinha,nColInic  + 2938) 

oPrint:Box(nLinInDado,nColInic,nLinha + nSaltoLinha,nColFinal)

Return

/*
===============================================================================================================================
Programa--------: RCOM008IBG
Autor-----------: Fabiano Dias
Data da Criacao-: 29/06/2014
Descrição-------: Funcao criada para impressao dos dados do relatório
Parametros------: Dados da NF
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function RCOM008IBG()

RCOM008IBD()
RCOM008IBR()

Return

/*
===============================================================================================================================
Programa--------: RCOM008ITG
Autor-----------: Fabiano Dias
Data da Criacao-: 29/06/2014
Descrição-------: Funcao criada para impressao dos totalizadores
Parametros------: Dados da NF
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function RCOM008ITG(_cDescri,_nVlrTotal)

oPrint:Say( nlinha , nColInic + 0020 , _cDescri	  									, oFont12b )
oPrint:Say( nlinha , nColInic + 2988 , Transform(_nVlrTotal,"@E 9,999,999,999.99")	, oFont12b )

Return
                 
/*
===============================================================================================================================
Programa--------: RCOM008IBR
Autor-----------: Fabiano Dias
Data da Criacao-: 29/06/2014
Descrição-------: Funcao criada para impressao do box geral do relatório
Parametros------: Dados da NF
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function RCOM008IBR()

oPrint:Box( nLinInBox , nColInic , nLinha , nColFinal )

Return

/*
===============================================================================================================================
Programa--------: RCOM008QBP
Autor-----------: Fabiano Dias
Data da Criacao-: 29/06/2014
Descrição-------: Funcao criada para processar a quebra de páginas do relatório
Parametros------: nLinhas  - numero de linhas que sera reduzido do tamanho do box do relatorio.
----------------: impBox   - .T. - indica que imprime box
----------------: impCabec - .T. - indica que imprime cabecalho de dados
----------------: boxImp   - Nome da funcao para impressao do box e suas divisorias
----------------: cabecImp - Nome da funcao para impressao do cabecalho de dados
----------------: nlinQuebr- numero de linhas acrescidas a linha corrente para verificar se eh necessaria a quebra de pagina
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function RCOM008QBP(nLinBox,limpBox,limpCabec,boxImp,cabecImp,nlinQuebr) 

Local _nLinhaQbr:= nLinha + (nSaltoLinha * nlinQuebr)   

//Verifica se com o numero de linas passados a mais sera necessario a realizacao da quebra da pagina de acordo com a linha corrente
If  _nLinhaQbr > nqbrPagina                 
			
	nlinha:= nlinha - (nSaltoLinha * nLinBox)
	 
	//Verifica se imprime o box e divisorias do relatorio
	If limpBox 
		&boxImp				  
	EndIf	 
	
	oPrint:EndPage()					// Finaliza a Pagina.
	oPrint:StartPage()					//Inicia uma nova Pagina					
	nPagina++
	RCOM008ICP(1)//Chama cabecalho    
	
	nlinha+=nSaltoLinha
	nlinha+=nSaltoLinha                      
	     
	//Armazena a linha inicial do box geral do relatorio
	nLinInBox := nlinha 	                            
	
	//Armazena a linha inicial do box e divisorias dos itens da nota fiscal de devolucao 
	nLinInDado:= nlinha
	  
	//Verifica se imprime o cabecalho dos dados
	If limpCabec 
	
		&cabecImp			
		
		nlinha+=nSaltoLinha	     
		oPrint:Line(nLinha,nColInic,nLinha,nColFinal)
		
	EndIf                
					
EndIf  

Return

/*
===============================================================================================================================
Programa--------: RCOM008QRY
Autor-----------: Fabiano Dias
Data da Criacao-: 29/06/2014
Descrição-------: Funcao criada para processar a quebra de páginas do relatório
Parametros------: _nOcao  - Indica qual query será processada
----------------: _cAlias - Alias para a criação da área de trabalho
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function RCOM008QRY( _nOpcao , _cAlias )

Local _cQuery := ""

Do Case               	

	//====================================================================================================
	//Query para selecao dos dados das notas de devolucao de compras
	//trazendo os dados de forma detalhada.                         
	//====================================================================================================
	Case _nOpcao == 1                                               
	
		_cQuery:= "SELECT"
		_cQuery+= " D2.D2_FILIAL,D2.D2_EMISSAO,D2.D2_DOC,D2.D2_SERIE,D2.D2_NFORI,D2.D2_SERIORI,D2.D2_CLIENTE,D2.D2_LOJA,D2.D2_PRCVEN,"
		_cQuery+= " A2.A2_NOME,A2.A2_EST,C2.CC2_MUN,"
		//_cQuery+= " D2.D2_ITEM,D2.D2_COD,B1.B1_I_DESCD,D2.D2_QUANT,D2.D2_UM,D2.D2_QTSEGUM,D2.D2_SEGUM,D2.D2_VALBRUT " // JPP TESTE
		_cQuery+= " D2.D2_ITEM,D2.D2_COD,B1.B1_I_DESCD,D2.D2_QUANT,D2.D2_UM,D2.D2_QTSEGUM,D2.D2_SEGUM,D2.D2_VALBRUT,D2.D2_DESCON " // JPP TESTE
		_cQuery+= "FROM "
		_cQuery+= RetSqlName("SD2") + " D2"
		_cQuery+= " JOIN " + RetSqlName("SF2") + " F2 ON F2.F2_FILIAL = D2.D2_FILIAL AND F2.F2_DOC = D2.D2_DOC AND F2.F2_SERIE = D2.D2_SERIE AND F2.F2_CLIENTE = D2.D2_CLIENTE AND F2.F2_LOJA = D2.D2_LOJA"
		_cQuery+= " JOIN " + RetSqlName("SA2") + " A2 ON A2.A2_COD = F2.F2_CLIENTE AND A2.A2_LOJA = F2.F2_LOJA"
		_cQuery+= " JOIN " + RetSqlName("SB1") + " B1 ON B1.B1_COD = D2.D2_COD"
		_cQuery+= " JOIN " + RetSqlName("CC2") + " C2 ON C2.CC2_EST = A2.A2_EST AND C2.CC2_CODMUN = A2.A2_COD_MUN "		     		
		
		//====================================================================================================
		//Caso o usuario deseja checar no financeiro se a NDF geradas						      
		//foram compensadas ou nao, para tanto deve ter sido escolhida a opcao gerou financeiro  
		//====================================================================================================
		
		If MV_PAR09 <> 3 .And. MV_PAR08 <> 2
		   _cQuery+= " JOIN " + RetSqlName("SE2") + " E2 ON F2.F2_FILIAL = E2.E2_FILIAL AND F2.F2_DOC = E2.E2_NUM AND F2.F2_SERIE = E2.E2_PREFIXO AND F2.F2_CLIENTE = E2.E2_FORNECE AND F2.F2_LOJA = E2.E2_LOJA "
		EndIf
		
		_cQuery+= "WHERE"  
		_cQuery+= " D2.D_E_L_E_T_ = ' '"
        _cQuery+= " AND F2.D_E_L_E_T_ = ' '"
        _cQuery+= " AND A2.D_E_L_E_T_ = ' '"
      	_cQuery+= " AND B1.D_E_L_E_T_ = ' '"
      	_cQuery+= " AND C2.D_E_L_E_T_ = ' '"
      	 
      	If MV_PAR09 <> 3 .And. MV_PAR08 <> 2
      	
	      	_cQuery+= " AND E2.D_E_L_E_T_ = ' '" 
	      	_cQuery+= " AND E2.E2_TIPO = 'NDF'"
	      	
      		//Lista somente as NDF que foram totalmente compensadas
      		If MV_PAR09 == 1
      		 	_cQuery+= " AND E2.E2_SALDO = 0"
      		//Lista as NDF que ainda possuem saldo
      		Else                                  
      			_cQuery+= " AND E2.E2_SALDO > 0"
      		EndIf
      		
      	EndIf                           
      			//Filial                          
		If Len(AllTrim(MV_PAR01)) > 0
			_cQuery += " AND F2.F2_FILIAL IN " + FormatIn(MV_PAR01,";")
		EndIf	       

        If !Empty(MV_PAR12)
            _cQuery += " AND D2.D2_GRUPO IN " + FormatIn(AllTrim(MV_PAR12),";")
        EndIf   

		//Da data de emissao inicial ate a data de emissao final
		_cQuery += " AND D2.D2_EMISSAO BETWEEN '" + DToS(MV_PAR02) + "' AND '" + DToS(MV_PAR03) + "'"
		
		//Do Fornecedor inicial ate o fornecedor final
		_cQuery += " AND F2.F2_CLIENTE BETWEEN '" + MV_PAR04 + "' AND '" + MV_PAR06 + "'"
		
		//Da Loja inicial do Fornecedor ate a loja final
		_cQuery += " AND F2.F2_LOJA BETWEEN '" + MV_PAR05 + "' AND '" + MV_PAR07 + "'"
		     
		//Notas fiscais de devolucao que geraram financeiro(NDF)
		If MV_PAR08 == 1
			_cQuery += " AND F2.f2_dupl <> '         '"   
				//Notas que nao geraram financeiro
				ElseIf MV_PAR08 == 2 
					_cQuery += " AND F2.f2_dupl = '         '" 
		EndIf  
      	_cQuery+= " AND D2.D2_TIPO = 'D' " 
		_cQuery+= "ORDER BY"  
		_cQuery+= " D2.D2_FILIAL,D2.D2_EMISSAO,D2.D2_DOC,D2.D2_ITEM" 
		
		dbUseArea(.T., "TOPCONN", TCGenQry(,,_cQuery), _cAlias, .T., .F.)

EndCase

Return

/*
===============================================================================================================================
Programa--------: RCOM008DDR
Autor-----------: Fabiano Dias
Data da Criacao-: 29/06/2014
Descrição-------: Funcao criada para impressão das ordens do relatório de acordo com a parametrização inicial
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/      
Static Function RCOM008DDR()
     
//====================================================================================================
//Verifica se o usuario selecionou a ordem Emissao de impressao.
//====================================================================================================
If MV_PAR10 == 1
	RCOM008IOR()
EndIf

Return

/*
===============================================================================================================================
Programa--------: RCOM008IOR
Autor-----------: Fabiano Dias
Data da Criacao-: 29/06/2014
Descrição-------: Funcao criada para impressão das ordens do relatório de acordo com a parametrização inicial
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function RCOM008IOR()   

Local _cAlias   := GetNextAlias()
Local _nContReg := 0       

Local _cQbrFil  := ""
Local _cQbrNF   := ""    

Local _nTotalNF  := 0
Local _nTotalFil := 0         
Local _nTotGeral := 0
Local _nValBruto := 0
                                            
//====================================================================================================
//Chama query para selecao dos dados.
//====================================================================================================
MsgRun( "Selecionando os dados favor aguardar..." ,, {||  RCOM008QRY(1,_cAlias)  } )

DBSelectArea(_cAlias)
(_cAlias)->( DBGoTop() )

COUNT TO _nContReg

ProcRegua(_nContReg)

//====================================================================================================
//Caso existam dados a serem exebidos imprime o cabecalho da primeira pagina de dados.
//====================================================================================================
DBSelectArea(_cAlias)
(_cAlias)->( DBGoTop() )
If (_cAlias)->(!Eof())         

	oPrint:StartPage()					//Inicia uma nova Pagina					
	
	RCOM008ICP(1)//Chama cabecalho    		               

	While (_cAlias)->(!Eof())
	                      
		IncProc("Processando os dados do relatoio...")
		
		//====================================================================================================
		//Verifica a necessidade de quebra por Filial.
		//====================================================================================================
		If _cQbrFil <> (_cAlias)->D2_FILIAL   
								
			//====================================================================================================
			//Verifica se ja foi impressa alguma outra filial, caso tenha sera impresso
			//o totalizador da filial anterior e o box de fechamento dos dados.        
			//====================================================================================================
			If Len(AllTrim(_cQbrFil)) > 0
			
				//====================================================================================================
				//Fecha o box dos dados da ultima nf da filial anterior.
				//====================================================================================================
				RCOM008IBD()	  
				
				nlinha+=nSaltoLinha
				
				//====================================================================================================
				//Verifica a necessidade de quebra antes da impressao do totalizador.
				//====================================================================================================
				RCOM008QBP(0,.T.,.F.,"RCOM008IBG()","",0)
				
				//====================================================================================================
				//Imprime o totalizador da ultima NF da filial anterior.
				//====================================================================================================
				RCOM008ITG("TOTAL DA NDF: " + SubStr(_cQbrNF,1,9) + ' - ' + SubStr(_cQbrNF,10,3),_nTotalNF)   
				
				nlinha+=nSaltoLinha
				oPrint:Line(nLinha,nColInic,nLinha,nColFinal) 
				
				//====================================================================================================
				//Verifica a necessidade de quebra antes da impressao do totalizador.
				//====================================================================================================
				RCOM008QBP(0,.T.,.F.,"RCOM008IBR()","",0)	
				
				RCOM008ITG( "TOTAL DA FILIAL: " + _cQbrFil + ' - ' + FWFilialName(, _cQbrFil ) , _nTotalFil )
								
				//====================================================================================================
				//Fecha o Box geral dos dados da filial anterior.
				//====================================================================================================
				nlinha+=nSaltoLinha
				RCOM008IBR()
			
			EndIf
			
			nlinha += ( nSaltoLinha * 2 )
			
			RCOM008QBP(0,.F.,.F.,"","",0)	
					    					
			//====================================================================================================
			//Imprime o cabecalho da Filial Corrente.
			//====================================================================================================
			RCOM008CDF( (_cAlias)->D2_FILIAL )
			
			nlinha += nSaltoLinha 			                                                 
			
			//====================================================================================================
			//Imprime o cabecalho e dados de cabecalho da NF corrente
			//====================================================================================================
			RCOM008CNF((_cAlias)->D2_EMISSAO,(_cAlias)->D2_DOC,(_cAlias)->D2_SERIE,(_cAlias)->D2_NFORI,(_cAlias)->D2_SERIORI,;
		          (_cAlias)->D2_CLIENTE,(_cAlias)->D2_LOJA,(_cAlias)->A2_NOME,(_cAlias)->CC2_MUN,(_cAlias)->A2_EST)
		    
		    nlinha+=nSaltoLinha 	 
			
			RCOM008QBP(0,.T.,.F.,"RCOM008IBR()","",0) 					      
			
			//====================================================================================================
			//Imprime o cabecalho dos Itens da Nota fiscal corrente.
			//====================================================================================================
			RCOM008ICD()  
							          			
			//====================================================================================================
			//Seta variavel de controle de quebra da Filial
			//====================================================================================================
			_cQbrFil:= (_cAlias)->D2_FILIAL    						
			
			//====================================================================================================
			//Seta variaveis responsaveis pelo totalizadores do relatorio.
			//====================================================================================================
			_nTotalNF := 0
			_nTotalFil:= 0   
			_cQbrNF   := ""
		
		EndIf		                              				                                                 		
		
		//====================================================================================================
		//Verifica a necessidade de quebra da NF corrente.
		//====================================================================================================
		If _cQbrNF <> (_cAlias)->D2_DOC + (_cAlias)->D2_SERIE + (_cAlias)->D2_CLIENTE + (_cAlias)->D2_LOJA .And. Len(AllTrim(_cQbrNF)) > 0     

			//====================================================================================================
			//Fecha o box dos dados da ultima nf da filial anterior.
			//====================================================================================================
			RCOM008IBD()	  
				
			nlinha+=nSaltoLinha				
			
			//====================================================================================================
			//Verifica a necessidade de quebra antes da impressao do totalizador.
			//====================================================================================================
			RCOM008QBP(1,.T.,.F.,"RCOM008IBG()","",0) 							
			
			//====================================================================================================
			//Imprime o totalizador da ultima NF da filial anterior.
			//====================================================================================================
			RCOM008ITG("TOTAL DA NDF: " + SubStr(_cQbrNF,1,9) + ' - ' + SubStr(_cQbrNF,10,3),_nTotalNF)
		
			nlinha+=nSaltoLinha 			 			                                                 
			
			oPrint:Line(nLinha,nColInic,nLinha,nColFinal)
			
			nlinha+=nSaltoLinha   
			
			oPrint:Line(nLinha,nColInic,nLinha,nColFinal)
			
			//====================================================================================================
			//Imprime o cabecalho e dados de cabecalho da NF corrente
			//====================================================================================================
			RCOM008CNF((_cAlias)->D2_EMISSAO,(_cAlias)->D2_DOC,(_cAlias)->D2_SERIE,(_cAlias)->D2_NFORI,(_cAlias)->D2_SERIORI,;
		          (_cAlias)->D2_CLIENTE,(_cAlias)->D2_LOJA,(_cAlias)->A2_NOME,(_cAlias)->CC2_MUN,(_cAlias)->A2_EST)
		    
		    nlinha+=nSaltoLinha
		    
			RCOM008QBP(0,.T.,.F.,"RCOM008IBR()","",0) 					      
			
			//====================================================================================================
			//Imprime o cabecalho dos Itens da Nota fiscal corrente.
			//====================================================================================================
			RCOM008ICD()        
			
			_nTotalNF:= 0 
		
		EndIf                                     
		
		nlinha+=nSaltoLinha
		
		oPrint:Line(nLinha,nColInic,nLinha,nColFinal)    
		
		RCOM008QBP(1,.T.,.F.,"RCOM008IBG()","",0) 
		
		If MV_PAR11 == 1
           _nValBruto := (_cAlias)->D2_VALBRUT - (_cAlias)->D2_DESCON  // JPP TESTE
		Else
           _nValBruto := (_cAlias)->D2_VALBRUT  // JPP TESTE
		EndIf

		RCOM008IDR((_cAlias)->D2_ITEM,(_cAlias)->D2_COD,(_cAlias)->B1_I_DESCD,(_cAlias)->D2_QUANT,;
		         (_cAlias)->D2_UM,(_cAlias)->D2_QTSEGUM,(_cAlias)->D2_SEGUM,(_cAlias)->D2_PRCVEN, _nValBruto) // (_cAlias)->D2_UM,(_cAlias)->D2_QTSEGUM,(_cAlias)->D2_SEGUM,(_cAlias)->D2_PRCVEN,(_cAlias)->D2_VALBRUT)
		
		//====================================================================================================
		//Variavel para controle de quebra das NF impressas.
		//====================================================================================================
		_cQbrNF:= (_cAlias)->D2_DOC + (_cAlias)->D2_SERIE + (_cAlias)->D2_CLIENTE + (_cAlias)->D2_LOJA					       
		
		//====================================================================================================
		//Incrementa variaveis responsaveis pelo totalizadores do relatorio.
		//====================================================================================================
		_nTotalNF += _nValBruto // (_cAlias)->D2_VALBRUT
		_nTotalFil+= _nValBruto // (_cAlias)->D2_VALBRUT
		_nTotGeral+= _nValBruto // (_cAlias)->D2_VALBRUT
	
	(_cAlias)->( DBSkip() ) 
    EndDo              
	
	//====================================================================================================
	//Finaliza a impressao da ultima pagina do relatorio.
	//Fecha o box dos dados da ultima nf da filial anterior.
	//====================================================================================================
	RCOM008IBD()	  
				
	nlinha += nSaltoLinha				
	
	//====================================================================================================
	//Verifica a necessidade de quebra antes da impressao do totalizador.
	//====================================================================================================
	RCOM008QBP(0,.T.,.F.,"RCOM008IBG()","",0) 							
	
	//====================================================================================================
	//Imprime o totalizador da ultima NF da filial anterior.
	//====================================================================================================
	RCOM008ITG("TOTAL DA NDF: " + SubStr(_cQbrNF,1,9) + ' - ' + SubStr(_cQbrNF,10,3),_nTotalNF)   
				
	nlinha+=nSaltoLinha
	oPrint:Line(nLinha,nColInic,nLinha,nColFinal) 
				
	//====================================================================================================
	//Verifica a necessidade de quebra antes da impressao do totalizador.
	//====================================================================================================
	RCOM008QBP(0,.T.,.F.,"RCOM008IBR()","",0)	
				
	RCOM008ITG("TOTAL DA FILIAL: " + _cQbrFil + ' - ' + FWFilialName(,_cQbrFil) , _nTotalFil )
	
	nlinha+=nSaltoLinha
	oPrint:Line(nLinha,nColInic,nLinha,nColFinal) 
				
	//====================================================================================================
	//Verifica a necessidade de quebra antes da impressao do totalizador.
	//====================================================================================================
	RCOM008QBP(0,.T.,.F.,"RCOM008IBR()","",0)	
				
	RCOM008ITG("TOTAL GERAL:",_nTotGeral)		
								
	//====================================================================================================
	//Fecha o Box geral dos dados da filial anterior.
	//====================================================================================================
	nlinha+=nSaltoLinha
	RCOM008IBR()

EndIf                  

//====================================================================================================
//Finaliza a area criada anteriormente.
//====================================================================================================
DBSelectArea(_cAlias)
(_cAlias)->(DBCloseArea())

Return
