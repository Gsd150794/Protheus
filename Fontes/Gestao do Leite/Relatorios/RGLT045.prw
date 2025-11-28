/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alexandre V.  |11/11/2014| Chamado 8024. Ajuste na rotina de impressão na chamada do BOX para não dar erro por conta do envio 
              |          | de parâmetro desnecessário na última posição. 
Lucas Borges  |25/06/2019| Chamado 28346 e 29752. Revisão de fontes.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RGLT045
Autor-------------: Fabiano Dias
Data da Criacao---: 08/11/2010
Descrição---------: Relatório que demonstra os valores em débito(NDF) do produtor ou fretista no momento da efetivação ou
------------------: aprovação de um empréstimo/antecipação/adiantamento.
Parametros--------: cCodProd	:= Código do Produtor
------------------: cLjProd		:= Loja do Produtor
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function RGLT045( cCodProd , cLjProd )

Local   _aAreaGer   := FWGetArea() 
    
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
Private _cCodProd   := cCodProd
Private _cLjProd    := cLjProd
                                                                             
Define Font oFont10    Name "Courier New"       Size 0,-08       // Tamanho 14
Define Font oFont10b   Name "Courier New"       Size 0,-08 Bold  // Tamanho 14
Define Font oFont12    Name "Courier New"       Size 0,-10       // Tamanho 12
Define Font oFont12b   Name "Courier New"       Size 0,-10 Bold  // Tamanho 12 Negrito
Define Font oFont14    Name "Courier New"       Size 0,-10       // Tamanho 14
Define Font oFont14b   Name "Courier New"       Size 0,-10 Bold  // Tamanho 14
Define Font oFont16b   Name "Helvetica"         Size 0,-14 Bold  // Tamanho 16 Negrito

Processa( {|| DadosRelat() } )

FWRestArea( _aAreaGer )

Return

/*
===============================================================================================================================
Programa----------: Cabecalho
Autor-------------: Fabiano Dias
Data da Criacao---: 08/11/2010
Descrição---------: Função para impressão do cabeçalho do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function Cabecalho()

Local cRaizServer := If(issrvunix(), "/", "\")    
Local cTitulo     := "Relatório de saldo em aberto do Fornecedor"
 
nLinha:=0100

oPrint:SayBitmap( nLinha , nColInic , cRaizServer + "system/lgrl01.bmp" , 250 , 100 )

oPrint:Say( nlinha			, ( nColInic + 2750 ) , "PÁGINA: "+ AllTrim( Str( nPagina ) )									, oFont12b )
oPrint:Say( nlinha + 100	, ( nColInic + 2750 ) , "EMPRESA: "+ AllTrim( SM0->M0_NOME ) +'/'+ AllTrim( SM0->M0_FILIAL )	, oFont12b )
oPrint:Say( nlinha + 050	, ( nColInic + 2750 ) , "DATA DE EMISSÃO:" + DToC( Date() )										, oFont12b )

nlinha += ( nSaltoLinha * 3 )

oPrint:Say( nlinha , nColFinal / 2 , cTitulo , oFont16b , nColFinal ,,, 2 )

nlinha += ( nSaltoLinha * 2 )

oPrint:Line( nLinha , nColInic , nLinha , nColFinal )

nlinha += nSaltoLinha

Return

/*
===============================================================================================================================
Programa----------: cabecDados
Autor-------------: Fabiano Dias
Data da Criacao---: 08/11/2010
Descrição---------: Função para impressão do cabeçalho dos dados do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function cabecDados()        
                                                                                                 
nLinInBox := nlinha

oPrint:FillRect( { (nlinha + 3) , nColInic , nlinha + nSaltoLinha , nColFinal } , oBrush ) // Box cabecalho

oPrint:Say( nlinha + nAjuAltLi1 , nColInic + 0010 , "Fornecedor"	, oFont12b )
oPrint:Say( nlinha + nAjuAltLi1 , nColInic + 1410 , "Titulo/Parc."	, oFont12b )
oPrint:Say( nlinha + nAjuAltLi1 , nColInic + 1687 , "Prefixo"		, oFont12b )
oPrint:Say( nlinha + nAjuAltLi1 , nColInic + 1864 , "Tipo"			, oFont12b )
oPrint:Say( nlinha + nAjuAltLi1 , nColInic + 2000 , "Vencimento"	, oFont12b )
oPrint:Say( nlinha + nAjuAltLi1 , nColInic + 2268 , "Historico"		, oFont12b )
oPrint:Say( nlinha + nAjuAltLi1 , nColInic + 3180 , "Valor"			, oFont12b )

oPrint:Line( nLinha + nSaltoLinha , nColInic , nLinha + nSaltoLinha , nColFinal )

Return

/*
===============================================================================================================================
Programa----------: printTotal
Autor-------------: Fabiano Dias
Data da Criacao---: 08/11/2010
Descrição---------: Função para impressão dos dados Totais do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function printTotal( cDescric , nVltTotal )

oPrint:Say( nlinha + nAjuAltLi1 , nColInic + 0010 , cDescric											, oFont12b )
oPrint:Say( nlinha + nAjuAltLi1 , nColInic + 2900 , Transform( nVltTotal , "@E 999,999,999,999.99" )	, oFont12b )

Return

/*
===============================================================================================================================
Programa----------: boxDivisor
Autor-------------: Fabiano Dias
Data da Criacao---: 08/11/2010
Descrição---------: Função para impressão do Box
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function boxDivisor()

oPrint:Line( nLinInBox , nColInic + 1400 , nLinha , nColInic + 1400 )
oPrint:Line( nLinInBox , nColInic + 1677 , nLinha , nColInic + 1677 )
oPrint:Line( nLinInBox , nColInic + 1854 , nLinha , nColInic + 1854 )
oPrint:Line( nLinInBox , nColInic + 1990 , nLinha , nColInic + 1990 )
oPrint:Line( nLinInBox , nColInic + 2258 , nLinha , nColInic + 2258 )
oPrint:Line( nLinInBox , nColInic + 2800 , nLinha , nColInic + 2800 )

oPrint:Box( nLinInBox , nColInic , nLinha , nColFinal )

Return

/*
===============================================================================================================================
Programa----------: qbrPag
Autor-------------: Fabiano Dias
Data da Criacao---: 08/11/2010
Descrição---------: Função para processar as quebras de página para o relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function qbrPag( nLinhas , impBox , impCabec )

//================================================================================
// Verifica Quebra de pagina
//================================================================================
If nLinha > nqbrPagina

	nlinha := nlinha - ( nSaltoLinha * nLinhas )
	
	If impBox == 1
       	boxDivisor()
	EndIf
	
	oPrint:EndPage()	// Finaliza a Pagina.
	oPrint:StartPage()	// Inicia uma nova Pagina
	
	nPagina++
	cabecalho()			// Chama cabecalho
	
	nlinha += ( nSaltoLinha * 2 )
	
	If impCabec == 1
		cabecDados()
	EndIf
	
	nlinha += nSaltoLinha

EndIf  

Return

/*
===============================================================================================================================
Programa----------: DadosRelat
Autor-------------: Fabiano Dias
Data da Criacao---: 08/11/2010
Descrição---------: Função para processar a estrutura de dados e a impressão do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function DadosRelat()

Local _cAlias	:= GetNextAlias()
Local nCountRec	:= 0    
Local nVlrTotal	:= 0

BeginSql alias _cAlias
	SELECT E2.E2_FORNECE, E2.E2_LOJA, A2.A2_NOME, E2.E2_NUM, E2.E2_PARCELA,	E2.E2_PREFIXO, E2.E2_TIPO, E2.E2_VENCREA, E2.E2_HIST,
	       (E2.E2_SALDO + E2.E2_SDACRES - E2.E2_SDDECRE) E2_SALDO
	  FROM %Table:SE2% E2, %Table:SA2% A2
	 WHERE E2.D_E_L_E_T_ = ' '
	   AND A2.D_E_L_E_T_ = ' '
	   AND A2.A2_COD = E2.E2_FORNECE
	   AND A2.A2_LOJA = E2.E2_LOJA
	   AND E2.E2_FILIAL = %xFilial:SE2%
	   AND E2.E2_TIPO = 'NDF'
	   AND E2.E2_SALDO > 0
	   AND E2.E2_FORNECE = %exp:_cCodProd%
	   AND E2.E2_LOJA = %exp:_cLjProd%
	 ORDER BY E2_VENCREA
EndSql

COUNT TO nCountRec //Contabiliza o numero de registros encontrados pela query 
(_cAlias)->( DBGoTop() )

If nCountRec > 0

	oPrint:= TMSPrinter():New( "AVALIACAO DE EMPRESTIMO" )
	oPrint:SetLandscape() 	// Paisagem
	oPrint:SetPaperSize(9)	// Seta para papel A4
	
	oPrint:StartPage()
	
	cabecalho()
	cabecDados()
	
	nlinha += nSaltoLinha
		
	//================================================================================
	// Imprime os dados do relatório
	//================================================================================
	While (_cAlias)->( !Eof() )
	
		If nlinha > nqbrPagina
			qbrPag(0,1,1)
		EndIf

		oPrint:Say( nlinha + nAjuAltLi1 , nColInic + 0010 , SubStr( (_cAlias)->E2_FORNECE +'/'+ (_cAlias)->E2_LOJA +'-'+ (_cAlias)->A2_NOME , 1 , 60 ), oFont12 )
		oPrint:Say( nlinha + nAjuAltLi1 , nColInic + 1410 , (_cAlias)->E2_NUM +'/'+ (_cAlias)->E2_PARCELA		    	, oFont12 )
		oPrint:Say( nlinha + nAjuAltLi1 , nColInic + 1687 , (_cAlias)->E2_PREFIXO			  						    , oFont12 )
		oPrint:Say( nlinha + nAjuAltLi1 , nColInic + 1864 , (_cAlias)->E2_TIPO  		          						, oFont12 )
		oPrint:Say( nlinha + nAjuAltLi1 , nColInic + 2000 , DToC( SToD( (_cAlias)->E2_VENCREA ) )     				    , oFont12 )
		oPrint:Say( nlinha + nAjuAltLi1 , nColInic + 2268 , SubStr( (_cAlias)->E2_HIST , 1 , 23 )					    , oFont12 )
		oPrint:Say( nlinha + nAjuAltLi1 , nColInic + 2900 , Transform( (_cAlias)->E2_SALDO , "@E 999,999,999,999.99" )	, oFont12 )
		
		nlinha += nSaltoLinha
		
		oPrint:Line( nLinha , nColInic , nLinha , nColFinal )
		
		nVlrTotal += (_cAlias)->E2_SALDO
	
		(_cAlias)->( DBSkip() )
	EndDo
	
	//================================================================================
	// Imprime o totalizador
	//================================================================================
	If nlinha > nqbrPagina
		qbrPag(0,0,0)
	EndIf
	
	nlinha += nSaltoLinha
	
	oPrint:Line( nLinha , nColInic , nLinha , nColFinal )
	
	printTotal( "Total ----->" , nVlrTotal )
	
	nlinha += nSaltoLinha
	
	boxDivisor()
	
	oPrint:EndPage()	// Finaliza a Pagina.
	oPrint:Preview()	// Visualiza antes de Imprimir.

Else
	MsgInfo( "Não foi econtrado saldo em aberto no financeiro para o Fornecedor: "+ _cCodProd +'/'+ _cLjProd,"RGLT04501")
EndIf

(_cAlias)->( DBCloseArea() )
	
Return
