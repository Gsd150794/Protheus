/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
       Autor      |    Data    |                                             Motivo                                           
-------------------------------------------------------------------------------------------------------------------------------
Alexandre Villar  | 03/11/2014 | Ajuste para substituir as referências ao cadastro customizado de armazéns  Chamado 7484     
-------------------------------------------------------------------------------------------------------------------------------
Josué Danich      | 08/03/2019 | Revisão para loboguara - Chamado 28356
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  	  | 17/10/2019 | Removidos os Warning na compilação da release 12.1.25. Chamado 28346
===============================================================================================================================
*/
//====================================================================================================
// Definicoes de Includes e Defines da Rotina.
//====================================================================================================
#Include "Report.ch"
#Include "TOTVS.ch"      
#Include "RWMake.ch"

/*
===============================================================================================================================
Programa----------: ROMS020
Autor-------------: Fabiano Dias
Data da Criacao---: 15/07/2010
===============================================================================================================================
Descrição---------: Relatorio de faturamento para demonstrar o saldo anterior, as entradas, as saidas e o saldo do produto.
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/

User Function ROMS020()

Private oFont09		:= TFont():New( "Courier New"	,, 07 ,, .F. ,,,, .F. , .F. )
Private oFont09b	:= TFont():New( "Courier New"	,, 07 ,, .T. ,,,, .F. , .F. )
Private oFont10b	:= TFont():New( "Courier New"	,, 08 ,, .T. ,,,, .F. , .F. )
Private oFont12		:= TFont():New( "Courier New"	,, 10 ,, .F. ,,,, .F. , .F. )
Private oFont12b	:= TFont():New( "Courier New"	,, 10 ,, .T. ,,,, .F. , .F. )
Private oFont14b	:= TFont():New( "Courier New"	,, 12 ,, .T. ,,,, .F. , .F. )
Private oFont16b	:= TFont():New( "Helvetica"		,, 14 ,, .T. ,,,, .F. , .F. )

Private nPagina     := 1
Private nLinha      := 0100
Private nLinhaInic  := 0100
Private nColInic    := 0030
Private nColFinal   := 3390
Private nqbrPagina  := 2200
Private nLinInBox   := 0
Private nSaltoLinha := 50
Private nAjuAltLi1  := 11 //ajusta a altura de impressao dos dados do relatorio

Private oBrush      := TBrush():New( ,CLR_LIGHTGRAY)
Private oPrint		:= Nil

Private cPerg       := "ROMS020"

oPrint:= TMSPrinter():New( "Movimentação de Entradas/Saídas" )
oPrint:SetLandscape() 	// Paisagem
oPrint:SetPaperSize(9)	// Seta para papel A4

oPrint:StartPage()

If !Pergunte( cPerg )
	U_ITMsg(  'Processamento cancelado pelo usuário!' , 'Atenção!' ,,1 )
	Return
EndIf

//================================================================================
// Imprime o Cabeçalho 
//================================================================================
ROMS020CAB(0)
		     		 	     		
Processa( {|| ROMS020REL() } )

oPrint:EndPage() //Finaliza a Pagina.
oPrint:Preview() //Visualiza antes de Imprimir.

Return
           
/*
===============================================================================================================================
Programa----------: ROMS020CAB
Autor-------------: Fabiano Dias
Data da Criacao---: 15/07/2010
===============================================================================================================================
Descrição---------: Função para impressão do cabeçalho das páginas do relatório
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/

Static Function ROMS020CAB(impNrPag)

Local cRaizServer	:= IIf( issrvunix() , "/" , "\" )
Local cTitulo		:= "Relatório de movimentacao de Entradas e Saidas - Período de "+ DToC( MV_PAR01 ) +" até "+ DToC( MV_PAR02 )

nLinha := 0100

oPrint:SayBitmap( nLinha , nColInic , cRaizServer +"system/lgrl01.bmp" , 250 , 100 )

If impNrPag <> 0
	oPrint:Say( nlinha			, ( nColInic + 2750 )	, "PÁGINA: "+ AllTrim(Str(nPagina))									, oFont12b )
Else
	oPrint:Say( nlinha			, ( nColInic + 2450 )	, "SIGA/ROMS020"													, oFont12b )
	oPrint:Say( nlinha + 100	, ( nColInic + 2750 )	, "EMPRESA: "+ AllTrim(SM0->M0_NOME) +'/'+ AllTrim(SM0->M0_FILIAL)	, oFont12b )
EndIf

oPrint:Say( nlinha + 50			, ( nColInic + 2750 )	, "DATA DE EMISSÃO: "+ DToC( Date() )								, oFont12b )

nlinha += ( nSaltoLinha * 3 )

oPrint:Say( nlinha				, nColFinal / 2			, cTitulo															, oFont16b , nColFinal ,,, 2 )

nlinha += ( nSaltoLinha * 2 )

oPrint:Line( nLinha , nColInic , nLinha , nColFinal )

Return

/*
===============================================================================================================================
Programa----------: ROMS020CPR
Autor-------------: Fabiano Dias
Data da Criacao---: 15/07/2010
===============================================================================================================================
Descrição---------: Função para impressão do cabeçalho dos dados do Relatório
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/

Static Function ROMS020CPR()

oPrint:Say( nlinha + nAjuAltLi1 , ( nColInic + 0760 ) + ( ( (nColInic + 1420)	- (nColInic + 0760) ) / 2 ) , "SALDO ANTERIOR"	, oFont12b , nColInic + 1420	,,, 2 )
oPrint:Say( nlinha + nAjuAltLi1 , ( nColInic + 1430 ) + ( ( (nColInic + 2080)	- (nColInic + 1430) ) / 2 ) , "ENTRADAS"		, oFont12b , nColInic + 2080	,,, 2 )
oPrint:Say( nlinha + nAjuAltLi1 , ( nColInic + 2090 ) + ( ( (nColInic + 2740)	- (nColInic + 2090) ) / 2 ) , "SAIDAS"			, oFont12b , nColInic + 2740	,,, 2 )
oPrint:Say( nlinha + nAjuAltLi1 , ( nColInic + 2750 ) + ( ( (nColFinal)			- (nColInic + 2750) ) / 2 ) , "SALDO"			, oFont12b , nColFinal			,,, 2 )

oPrint:Box( nlinha , nColInic + 0760 , nLinha + nSaltoLinha , nColInic + 1420	) //Saldo Anterior 
oPrint:Box( nlinha , nColInic + 1430 , nLinha + nSaltoLinha , nColInic + 2080	) //Entradas
oPrint:Box( nlinha , nColInic + 2090 , nLinha + nSaltoLinha , nColInic + 2740	) //Saidas
oPrint:Box( nlinha , nColInic + 2750 , nLinha + nSaltoLinha , nColFinal			) //Saldo

nlinha += nSaltoLinha

oPrint:Box( nlinha , nColInic        , nLinha + nSaltoLinha , nColInic + 0750 ) //Produtos
oPrint:Box( nlinha , nColInic + 0760 , nLinha + nSaltoLinha , nColInic + 1420 ) //Saldo Anterior 
oPrint:Box( nlinha , nColInic + 1430 , nLinha + nSaltoLinha , nColInic + 2080 ) //Entradas 
oPrint:Box( nlinha , nColInic + 2090 , nLinha + nSaltoLinha , nColInic + 2740 ) //Saidas
oPrint:Box( nlinha , nColInic + 2750 , nLinha + nSaltoLinha , nColFinal       ) //Saldo

oPrint:FillRect( { (nlinha+3) , nColInic + 0003 , nlinha + nSaltoLinha , nColInic + 0750	} , oBrush ) //Produtos
oPrint:FillRect( { (nlinha+3) , nColInic + 0763 , nlinha + nSaltoLinha , nColInic + 1420	} , oBrush ) //Saldo Anterior
oPrint:FillRect( { (nlinha+3) , nColInic + 1431 , nlinha + nSaltoLinha , nColInic + 2080	} , oBrush ) //Entradas
oPrint:FillRect( { (nlinha+3) , nColInic + 2093 , nlinha + nSaltoLinha , nColInic + 2740	} , oBrush ) //Saidas
oPrint:FillRect( { (nlinha+3) , nColInic + 2753 , nlinha + nSaltoLinha , nColFinal			} , oBrush ) //Saldo

oPrint:Line( nlinha , nColInic + 1035 , nLinha + nSaltoLinha , nColInic + 1035 )
oPrint:Line( nlinha , nColInic + 1085 , nLinha + nSaltoLinha , nColInic + 1085 )
oPrint:Line( nlinha , nColInic + 1365 , nLinha + nSaltoLinha , nColInic + 1365 )

oPrint:Line( nlinha , nColInic + 1700 , nLinha + nSaltoLinha , nColInic + 1700 )
oPrint:Line( nlinha , nColInic + 1750 , nLinha + nSaltoLinha , nColInic + 1750 )
oPrint:Line( nlinha , nColInic + 2030 , nLinha + nSaltoLinha , nColInic + 2030 )

oPrint:Line( nlinha , nColInic + 2360 , nLinha + nSaltoLinha , nColInic + 2360 )
oPrint:Line( nlinha , nColInic + 2410 , nLinha + nSaltoLinha , nColInic + 2410 )
oPrint:Line( nlinha , nColInic + 2690 , nLinha + nSaltoLinha , nColInic + 2690 )

oPrint:Line( nlinha , nColInic + 3020 , nLinha + nSaltoLinha , nColInic + 3020 )
oPrint:Line( nlinha , nColInic + 3070 , nLinha + nSaltoLinha , nColInic + 3070 )
oPrint:Line( nlinha , nColInic + 3310 , nLinha + nSaltoLinha , nColInic + 3310 )

oPrint:Say( nlinha + nAjuAltLi1 , nColInic + 0010 , "Produtos"		, oFont12b )

oPrint:Say( nlinha + nAjuAltLi1 , nColInic + 0805 , "Quantidade"	, oFont12b )
oPrint:Say( nlinha + nAjuAltLi1 , nColInic + 1040 , "UM"			, oFont10b )
oPrint:Say( nlinha + nAjuAltLi1 , nColInic + 1135 , "Quantidade"	, oFont12b )
oPrint:Say( nlinha + nAjuAltLi1 , nColInic + 1375 , "UM"			, oFont10b )

oPrint:Say( nlinha + nAjuAltLi1 , nColInic + 1475 , "Quantidade"	, oFont12b )
oPrint:Say( nlinha + nAjuAltLi1 , nColInic + 1705 , "UM"			, oFont10b )
oPrint:Say( nlinha + nAjuAltLi1 , nColInic + 1805 , "Quantidade"	, oFont12b )
oPrint:Say( nlinha + nAjuAltLi1 , nColInic + 2035 , "UM"			, oFont10b )

oPrint:Say( nlinha + nAjuAltLi1 , nColInic + 2135 , "Quantidade"	, oFont12b )
oPrint:Say( nlinha + nAjuAltLi1 , nColInic + 2365 , "UM"			, oFont10b )
oPrint:Say( nlinha + nAjuAltLi1 , nColInic + 2465 , "Quantidade"	, oFont12b )
oPrint:Say( nlinha + nAjuAltLi1 , nColInic + 2695 , "UM"			, oFont10b )

oPrint:Say( nlinha + nAjuAltLi1 , nColInic + 2795 , "Quantidade"	, oFont12b )
oPrint:Say( nlinha + nAjuAltLi1 , nColInic + 3025 , "UM"			, oFont10b )
oPrint:Say( nlinha + nAjuAltLi1 , nColInic + 3080 , "Quantidade"	, oFont12b )
oPrint:Say( nlinha + nAjuAltLi1 , nColInic + 3315 , "UM"			, oFont10b )

nlinha += nSaltoLinha

nLinInBox := nlinha + nSaltoLinha

Return

/*
===============================================================================================================================
Programa----------: ROMS020BOX
Autor-------------: Fabiano Dias
Data da Criacao---: 15/07/2010
===============================================================================================================================
Descrição---------: Função para impressão do Box para os dados
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
Usuario-----------: 
===============================================================================================================================
*/

Static Function ROMS020BOX()
      
oPrint:Line( nLinInBox , nColInic + 1035 , nLinha , nColInic + 1035 )
oPrint:Line( nLinInBox , nColInic + 1085 , nLinha , nColInic + 1085 )
oPrint:Line( nLinInBox , nColInic + 1365 , nLinha , nColInic + 1365 )

oPrint:Line( nLinInBox , nColInic + 1700 , nLinha , nColInic + 1700 )
oPrint:Line( nLinInBox , nColInic + 1750 , nLinha , nColInic + 1750 )
oPrint:Line( nLinInBox , nColInic + 2030 , nLinha , nColInic + 2030 )

oPrint:Line( nLinInBox , nColInic + 2360 , nLinha , nColInic + 2360 )
oPrint:Line( nLinInBox , nColInic + 2410 , nLinha , nColInic + 2410 )
oPrint:Line( nLinInBox , nColInic + 2690 , nLinha , nColInic + 2690 )

oPrint:Line( nLinInBox , nColInic + 3020 , nLinha , nColInic + 3020 )
oPrint:Line( nLinInBox , nColInic + 3070 , nLinha , nColInic + 3070 )
oPrint:Line( nLinInBox , nColInic + 3310 , nLinha , nColInic + 3310 )

oPrint:Box( nLinInBox , nColInic        , nLinha , nColInic + 0750 ) //Produtos
oPrint:Box( nLinInBox , nColInic + 0760 , nLinha , nColInic + 1420 ) //Saldo Anterior
oPrint:Box( nLinInBox , nColInic + 1430 , nLinha , nColInic + 2080 ) //Entradas
oPrint:Box( nLinInBox , nColInic + 2090 , nLinha , nColInic + 2740 ) //Saidas
oPrint:Box( nLinInBox , nColInic + 2750 , nLinha , nColFinal       ) //Saldo

Return

/*
===============================================================================================================================
Programa----------: ROMS020PRT
Autor-------------: Fabiano Dias
Data da Criacao---: 15/07/2010
===============================================================================================================================
Descrição---------: Função para impressão dos dados
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/

Static Function ROMS020PRT( cDescProd , nqtdeSld1 , nqtdeSld2 , nqtdeEnt1 , nqtdeEnt2 , nqtdeSai1 , nqtdeSai2 , um1 , um2 )

Local nSaldo1 := (nqtdeSld1 + nqtdeEnt1) - nqtdeSai1
Local nSaldo2 := (nqtdeSld2 + nqtdeEnt2) - nqtdeSai2

oPrint:Say( nlinha + nAjuAltLi1 , nColInic + 0010 , SubStr( AllTrim( cDescProd ) , 1 , 45 )			, oFont09 )

oPrint:Say( nlinha + nAjuAltLi1 , nColInic + 0750 , Transform( nqtdeSld1 , "@E 99,999,999,999.99" )	, oFont09 )
oPrint:Say( nlinha + nAjuAltLi1 , nColInic + 1040 , um1												, oFont09 )
oPrint:Say( nlinha + nAjuAltLi1 , nColInic + 1080 , Transform( nqtdeSld2 , "@E 99,999,999,999.99" )	, oFont09 )
oPrint:Say( nlinha + nAjuAltLi1 , nColInic + 1375 , um2												, oFont09 )

oPrint:Say( nlinha + nAjuAltLi1 , nColInic + 1420 , Transform( nqtdeEnt1 , "@E 99,999,999,999.99" )	, oFont09 )
oPrint:Say( nlinha + nAjuAltLi1 , nColInic + 1705 , um1												, oFont09 )
oPrint:Say( nlinha + nAjuAltLi1 , nColInic + 1750 , Transform( nqtdeEnt2 , "@E 99,999,999,999.99" )	, oFont09 )
oPrint:Say( nlinha + nAjuAltLi1 , nColInic + 2035 , um2												, oFont09 )

oPrint:Say( nlinha + nAjuAltLi1 , nColInic + 2080 , Transform( nqtdeSai1 , "@E 99,999,999,999.99" )	, oFont09 )
oPrint:Say( nlinha + nAjuAltLi1 , nColInic + 2365 , um1												, oFont09 )
oPrint:Say( nlinha + nAjuAltLi1 , nColInic + 2410 , Transform( nqtdeSai2 , "@E 99,999,999,999.99" )	, oFont09 )
oPrint:Say( nlinha + nAjuAltLi1 , nColInic + 2695 , um2												, oFont09 )

oPrint:Say( nlinha + nAjuAltLi1 , nColInic + 2740 , Transform( nSaldo1 , "@E 99,999,999,999.99" )	, oFont09 )
oPrint:Say( nlinha + nAjuAltLi1 , nColInic + 3025 , um1												, oFont09 )
oPrint:Say( nlinha + nAjuAltLi1 , nColInic + 3025 , Transform( nSaldo2 , "@E 99,999,999,999.99" )	, oFont09 )
oPrint:Say( nlinha + nAjuAltLi1 , nColInic + 3315 , um2												, oFont09 )

Return

/*
===============================================================================================================================
Programa----------: ROMS020TOT
Autor-------------: Fabiano Dias
Data da Criacao---: 15/07/2010
===============================================================================================================================
Descrição---------: Função para impressão dos dados de totalizadores
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/

Static Function ROMS020TOT( cDescricao , nqtdeSld1 , nqtdeSld2 , nqtdeEnt1 , nqtdeEnt2 , nqtdeSai1 , nqtdeSai2 , nqtdeSal1 , nqtdeSal2 )

oPrint:Say( nlinha + nAjuAltLi1 , nColInic + 0010 , SubStr( AllTrim( cDescricao ) , 1 , 45 )		, oFont09b )
oPrint:Say( nlinha + nAjuAltLi1 , nColInic + 0750 , Transform( nqtdeSld1 , "@E 99,999,999,999.99" )	, oFont09b )
oPrint:Say( nlinha + nAjuAltLi1 , nColInic + 1080 , Transform( nqtdeSld2 , "@E 99,999,999,999.99" )	, oFont09b )
oPrint:Say( nlinha + nAjuAltLi1 , nColInic + 1420 , Transform( nqtdeEnt1 , "@E 99,999,999,999.99" )	, oFont09b )
oPrint:Say( nlinha + nAjuAltLi1 , nColInic + 1750 , Transform( nqtdeEnt2 , "@E 99,999,999,999.99" )	, oFont09b )
oPrint:Say( nlinha + nAjuAltLi1 , nColInic + 2080 , Transform( nqtdeSai1 , "@E 99,999,999,999.99" )	, oFont09b )
oPrint:Say( nlinha + nAjuAltLi1 , nColInic + 2410 , Transform( nqtdeSai2 , "@E 99,999,999,999.99" )	, oFont09b )
oPrint:Say( nlinha + nAjuAltLi1 , nColInic + 2740 , Transform( nqtdeSal1 , "@E 99,999,999,999.99" )	, oFont09b )
oPrint:Say( nlinha + nAjuAltLi1 , nColInic + 3025 , Transform( nqtdeSal2 , "@E 99,999,999,999.99" )	, oFont09b )

Return

/*
===============================================================================================================================
Programa----------: ROMS020PAG
Autor-------------: Fabiano Dias
Data da Criacao---: 15/07/2010
===============================================================================================================================
Descrição---------: Função para tratativa da quebra de páginas
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/

Static Function ROMS020PAG( nLinhas , nImpBox )

//================================================================================
// Verifica Quebra de pagina
//================================================================================
If nLinha > nqbrPagina
			
	nlinha := nlinha - ( nSaltoLinha * nLinhas )
	
	If nImpBox == 0
		ROMS020BOX()
	EndIf
	
	oPrint:EndPage()	// Finaliza a Pagina
	oPrint:StartPage()	// Inicia uma nova Pagina
	
	nPagina++
	
	ROMS020CAB(1)		//Chama cabecalho
	
	nlinha += ( nSaltoLinha * 2 )
	
	ROMS020CPR()
	
	nlinha += nSaltoLinha
	
EndIf  
	
Return

/*
===============================================================================================================================
Programa----------: ROMS020REL
Autor-------------: Fabiano Dias
Data da Criacao---: 15/07/2010
===============================================================================================================================
Descrição---------: Função para impressão do relatório
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
Usuario-----------: 
===============================================================================================================================
*/

Static Function ROMS020REL()

Local cQuery		:= ""                
Local cAliasEntr	:= GetNextAlias()        
Local cAliasSaid	:= GetNextAlias()    
Local cAliasProd	:= GetNextAlias()     
Local aDados		:= {}
Local aEntrada		:= {}       
Local aSaida		:= {}       
Local aGrupoProd	:= {}
Local nPosProEnt	:= 0
Local nPosProSai	:= 0
Local _nI			:= 0
Local cFiltroSai	:= ""
Local cFiltroEnt	:= ""
Local cFiltroInt	:= ""
Local cFiltProd		:= ""

Local nTotSld1		:= 0
Local nTotSld2		:= 0
Local nTotEnt1		:= 0
Local nTotEnt2		:= 0
Local nTotSai1		:= 0
Local nTotSai2		:= 0
Local nTotSal1		:= 0
Local nTotSal2		:= 0

Local nTotGrSld1	:= 0
Local nTotGrSld2	:= 0
Local nTotGrEnt1	:= 0
Local nTotGrEnt2	:= 0
Local nTotGrSai1	:= 0
Local nTotGrSai2	:= 0
Local nTotGrSal1	:= 0
Local nTotGrSal2	:= 0

Local cProdMovi		:= ""

//================================================================================
// Filtro do Periodo ate o periodo
//================================================================================
If !Empty(MV_PAR01) .And. !Empty(MV_PAR02)

	cFiltroSai += " AND D2.D2_EMISSAO BETWEEN '"+ DToS( MV_PAR01 ) +"' AND '"+ DToS( MV_PAR02 ) +"' "
	cFiltroEnt += " AND D1.D1_DTDIGIT BETWEEN '"+ DToS( MV_PAR01 ) +"' AND '"+ DToS( MV_PAR02 ) +"' "
	cFiltroInt += " AND D3.D3_EMISSAO BETWEEN '"+ DToS( MV_PAR01 ) +"' AND '"+ DToS( MV_PAR02 ) +"' "

EndIf

//================================================================================
// Filtro de Armazém
//================================================================================
If !Empty(MV_PAR03)

	cFiltroSai += " AND D2.d2_LOCAL IN "+ FormatIn( MV_PAR03 , ";" )
	cFiltroEnt += " AND D1.d1_LOCAL IN "+ FormatIn( MV_PAR03 , ";" )
	cFiltroInt += " AND D3.d3_LOCAL IN "+ FormatIn( MV_PAR03 , ";" )
	
EndIf

//================================================================================
// Filtro De/ate para o Tipo de Produto
//================================================================================
If !Empty(MV_PAR04) .And. !Empty(MV_PAR05)

	cFiltroSai += " AND B1.b1_tipo BETWEEN '"+ MV_PAR04 +"' AND '"+ MV_PAR05 +"' "
	cFiltroEnt += " AND B1.b1_tipo BETWEEN '"+ MV_PAR04 +"' AND '"+ MV_PAR05 +"' "
	cFiltroInt += " AND B1.b1_tipo BETWEEN '"+ MV_PAR04 +"' AND '"+ MV_PAR05 +"' "
	cFiltProd  += " AND B1.b1_tipo BETWEEN '"+ MV_PAR04 +"' AND '"+ MV_PAR05 +"' "
	
EndIf

//================================================================================
// Filtro de produto De/Ate
//================================================================================
If !Empty(MV_PAR06) .And. !Empty(MV_PAR07)

	cFiltroSai += " AND B1.b1_cod BETWEEN '"+ MV_PAR06 +"' AND '"+ MV_PAR07 +"' "
	cFiltroEnt += " AND B1.b1_cod BETWEEN '"+ MV_PAR06 +"' AND '"+ MV_PAR07 +"' "
	cFiltroInt += " AND B1.b1_cod BETWEEN '"+ MV_PAR06 +"' AND '"+ MV_PAR07 +"' "
	cFiltProd  += " AND B1.b1_cod BETWEEN '"+ MV_PAR06 +"' AND '"+ MV_PAR07 +"' "

EndIf

//================================================================================
// Filtra Grupo de Produtos
//================================================================================
If !Empty(MV_PAR08)                                                    

	cFiltroSai   += " AND B1.b1_grupo IN "+ FormatIn( MV_PAR08 , ";" )
	cFiltroEnt   += " AND B1.b1_grupo IN "+ FormatIn( MV_PAR08 , ";" )
	cFiltroInt   += " AND B1.b1_grupo IN "+ FormatIn( MV_PAR08 , ";" )
	cFiltProd    += " AND B1.b1_grupo IN "+ FormatIn( MV_PAR08 , ";" )

EndIf

//================================================================================
// Filtra Produto Nivel 2
//================================================================================
If !Empty(MV_PAR09)

    cFiltroSai   += " AND B1.B1_I_NIV2 IN "+ FormatIn( MV_PAR09 , ";" )
    cFiltroEnt   += " AND B1.B1_I_NIV2 IN "+ FormatIn( MV_PAR09 , ";" )
	cFiltroInt   += " AND B1.B1_I_NIV2 IN "+ FormatIn( MV_PAR09 , ";" )
	cFiltProd    += " AND B1.B1_I_NIV2 IN "+ FormatIn( MV_PAR09 , ";" )

EndIf

//================================================================================
// Filtra Produto Nivel 3
//================================================================================
If !Empty(MV_PAR10)

	cFiltroSai   += " AND B1.B1_I_NIV3 IN "+ FormatIn( MV_PAR10 , ";" )
	cFiltroEnt   += " AND B1.B1_I_NIV3 IN "+ FormatIn( MV_PAR10 , ";" )
	cFiltroInt   += " AND B1.B1_I_NIV3 IN "+ FormatIn( MV_PAR10 , ";" )
	cFiltProd    += " AND B1.B1_I_NIV3 IN "+ FormatIn( MV_PAR10 , ";" )

EndIf

//================================================================================
// Filtra Produto Nivel 4
//================================================================================
If !Empty(MV_PAR11)

	cFiltroSai   += " AND B1.B1_I_NIV4 IN "+ FormatIn( MV_PAR11 , ";" )
	cFiltroEnt   += " AND B1.B1_I_NIV4 IN "+ FormatIn( MV_PAR11 , ";" )
	cFiltroInt   += " AND B1.B1_I_NIV4 IN "+ FormatIn( MV_PAR11 , ";" )
	cFiltProd    += " AND B1.B1_I_NIV4 IN "+ FormatIn( MV_PAR11 , ";" )

EndIf

//================================================================================
// Consulta para buscar os dados das entradas normais
//================================================================================
cQuery := " SELECT "
cQuery += " 	BM.BM_GRUPO			GRUPO		,"
cQuery += " 	BM.BM_DESC			DESCGRUPO	,"
cQuery += " 	D1.D1_COD			PRODUTO		,"
cQuery += " 	B1.B1_I_DESCD		DESCPRODUT	,"
cQuery += " 	D1.D1_UM			UM			,"
cQuery += " 	D1.D1_SEGUM			SEGUM		,"
cQuery += " 	D1.D1_LOCAL			LOTEPADRAO	,"
cQuery += " 	Sum(D1.D1_QUANT)	QUANT		,"
cQuery += " 	Sum(D1.D1_QTSEGUM)	QTSEGUM		 "
cQuery += " FROM "+ RetSqlName("SD1") +" D1 "
cQuery += " JOIN "+ RetSqlName("SF4") +" F4 ON D1.D1_FILIAL	= F4.F4_FILIAL AND D1.D1_TES = F4.F4_CODIGO "
cQuery += " JOIN "+ RetSqlName("SB1") +" B1 ON D1.D1_COD	= B1.B1_COD "
cQuery += " JOIN "+ RetSqlName("SBM") +" BM ON B1.B1_GRUPO	= BM.BM_GRUPO "
cQuery += " WHERE "
cQuery += "     D1.D_E_L_E_T_ = ' ' "
cQuery += " AND F4.D_E_L_E_T_ = ' ' "   
cQuery += " AND B1.D_E_L_E_T_ = ' ' "
cQuery += " AND BM.D_E_L_E_T_ = ' ' "
cQuery += " AND D1.D1_FILIAL  = '"+ xFilial("SD1") +"' "
cQuery += " AND F4.F4_FILIAL  = '"+ xFilial("SF4") +"' "
cQuery += " AND F4.f4_estoque = 'S' "

cQuery += cFiltroEnt

cQuery += " GROUP BY BM.BM_GRUPO , BM.BM_DESC , D1.D1_COD , B1.B1_I_DESCD , D1.D1_UM , D1.D1_SEGUM , D1.D1_LOCAL "

cQuery += " UNION ALL "
	
cQuery += " SELECT " 
cQuery += " 	BM.BM_GRUPO			GRUPO		,"
cQuery += " 	BM.BM_DESC			DESCGRUPO	,"
cQuery += " 	D3.D3_COD			PRODUTO		,"
cQuery += " 	B1.B1_I_DESCD		DESCPRODUT	,"
cQuery += " 	D3.D3_UM			UM			,"
cQuery += " 	D3.D3_SEGUM			SEGUM		,"
cQuery += " 	D3.D3_LOCAL			LOTEPADRAO	,"
cQuery += " 	SUM(D3.D3_QUANT)	QUANT		,"
cQuery += " 	SUM(D3.D3_QTSEGUM)	QTSEGUM		 "
cQuery += " FROM "+ RetSqlName("SD3") +" D3 "
cQuery += " JOIN "+ RetSqlName("SB1") +" B1 ON D3.D3_COD   = B1.B1_COD "
cQuery += " JOIN "+ RetSqlName("SBM") +" BM ON B1.B1_GRUPO = BM.BM_GRUPO "
cQuery += " WHERE "
cQuery += "     D3.D_E_L_E_T_ = ' ' "
cQuery += " AND B1.D_E_L_E_T_ = ' ' "
cQuery += " AND BM.D_E_L_E_T_ = ' ' "
cQuery += " AND D3.D3_FILIAL  = '"+ xFilial("SD3") +"' "
cQuery += " AND D3.D3_TM      <= '500' "
cQuery += " AND D3.D3_ESTORNO <> 'S' "

cQuery += cFiltroInt

cQuery += " GROUP BY BM.BM_GRUPO , BM.BM_DESC , D3.D3_COD , B1.B1_I_DESCD , D3.D3_UM , D3.D3_SEGUM , D3.D3_LOCAL "

If Select(cAliasEntr) > 0
	(cAliasEntr)->( DBCloseArea() )
EndIf

DBUseArea( .T. , "TOPCONN" , TcGenQry(,,cQuery) , cAliasEntr , .T. , .F. )
COUNT TO nCountRec //Contabiliza o numero de registros encontrados pela query
  
ProcRegua(nCountRec)     

DBSelectArea(cAliasEntr)
(cAliasEntr)->( DBGoTop() )
While (cAliasEntr)->( !Eof() )

	IncProc( "Processando a entrada do produto: " + AllTrim( (cAliasEntr)->PRODUTO ) )
	
	nPosProEnt := aScan( aEntrada , {|x| AllTrim(x[3]) == AllTrim( (cAliasEntr)->PRODUTO ) } )
	
	If nPosProEnt > 0
	    
	    If (cAliasEntr)->SEGUM <> "KG"
	    
	    	aEntrada[nPosProEnt][5] += (cAliasEntr)->QUANT
	    	aEntrada[nPosProEnt][7] += (cAliasEntr)->QTSEGUM
	    
	    ElseIf (cAliasEntr)->segum = "KG"
	    
	        aEntrada[nPosProEnt][5] += (cAliasEntr)->QTSEGUM
	    	aEntrada[nPosProEnt][7] += (cAliasEntr)->QUANT
	    	
	    EndIf
	    
	
	Else
		
		If (cAliasEntr)->SEGUM <> "KG"
		
			aAdd( aEntrada , {	(cAliasEntr)->GRUPO			,;
								(cAliasEntr)->DESCGRUPO		,;
								(cAliasEntr)->PRODUTO		,;
								(cAliasEntr)->DESCPRODUT	,;
								(cAliasEntr)->QUANT			,;
								(cAliasEntr)->UM			,;
								(cAliasEntr)->QTSEGUM		,;
								(cAliasEntr)->SEGUM			,;
								(cAliasEntr)->LOTEPADRAO	,;
								"N"							})
			
	 	ElseIf (cAliasEntr)->segum = "KG"
	 		
	 		aAdd( aEntrada , {	(cAliasEntr)->GRUPO			,;
	 							(cAliasEntr)->DESCGRUPO		,;
	 							(cAliasEntr)->PRODUTO		,;
	 							(cAliasEntr)->DESCPRODUT	,;
	                          	(cAliasEntr)->QTSEGUM		,;
	                          	(cAliasEntr)->SEGUM			,;
	                          	(cAliasEntr)->QUANT			,;
	                          	(cAliasEntr)->UM			,;
	                          	(cAliasEntr)->LOTEPADRAO	,;
	                          	"S"							})
		
	  	EndIf
	  	
	EndIf

(cAliasEntr)->( DBSkip() )
EndDo

(cAliasEntr)->( DBCloseArea() )

nCountRec := 0

//================================================================================
// Efetua busca das saidas normais
//================================================================================
cQuery := " SELECT "       
cQuery += " 	BM.BM_GRUPO			GRUPO		,"
cQuery += " 	BM.BM_DESC			DESCGRUPO	,"
cQuery += " 	D2.D2_COD			PRODUTO		,"
cQuery += " 	B1.B1_I_DESCD		DESCPRODUT	,"
cQuery += " 	D2.D2_UM			UM			,"
cQuery += " 	D2.D2_SEGUM			SEGUM		,"
cQuery += " 	D2.D2_LOCAL			LOTEPADRAO	,"
cQuery += " 	SUM(D2.D2_QUANT)	QUANT		,"
cQuery += " 	SUM(D2.D2_QTSEGUM)	QTSEGUM		 "
cQuery += " FROM "+ RetSqlName("SD2") +" D2 "
cQuery += " JOIN "+ RetSqlName("SF4") +" F4 ON D2.D2_FILIAL = F4.F4_FILIAL AND D2.D2_TES = F4.F4_CODIGO "
cQuery += " JOIN "+ RetSqlName("SB1") +" B1 ON D2.D2_COD    = B1.B1_COD "
cQuery += " JOIN "+ RetSqlName("SBM") +" BM ON B1.B1_GRUPO  = BM.BM_GRUPO "
cQuery += " WHERE "
cQuery += "     D2.D_E_L_E_T_ = ' ' "
cQuery += " AND F4.D_E_L_E_T_ = ' ' "
cQuery += " AND B1.D_E_L_E_T_ = ' ' "
cQuery += " AND BM.D_E_L_E_T_ = ' ' "
cQuery += " AND D2.D2_FILIAL  = '"+ xFilial("SD2") +"' "
cQuery += " AND F4.F4_FILIAL  = '"+ xFilial("SF4") +"' "
cQuery += " AND F4.f4_estoque = 'S' "

cQuery += cFiltroSai

cQuery += " GROUP BY BM.BM_GRUPO , BM.BM_DESC , D2.D2_COD , B1.B1_I_DESCD , D2.D2_UM , D2.D2_SEGUM , D2.D2_LOCAL "

cQuery += " UNION ALL "

cQuery += " SELECT "
cQuery += " 	BM.BM_GRUPO			GRUPO		,"
cQuery += " 	BM.BM_DESC			DESCGRUPO	,"
cQuery += " 	D3.D3_COD			PRODUTO		,"
cQuery += " 	B1.B1_I_DESCD		DESCPRODUT	,"
cQuery += " 	D3.D3_UM			UM			,"
cQuery += " 	D3.D3_SEGUM			SEGUM		,"
cQuery += " 	D3.D3_LOCAL			LOTEPADRAO	,"
cQuery += " 	SUM(D3.D3_QUANT)	QUANT		,"
cQuery += " 	SUM(D3.D3_QTSEGUM)	QTSEGUM		 "
cQuery += " FROM "+ RetSqlName("SD3") + " D3 "
cQuery += " JOIN "+ RetSqlName("SB1") + " B1 ON D3.D3_COD   = B1.B1_COD   "
cQuery += " JOIN "+ RetSqlName("SBM") + " BM ON B1.B1_GRUPO = BM.BM_GRUPO "
cQuery += " WHERE "
cQuery += "     D3.D_E_L_E_T_ = ' ' "
cQuery += " AND B1.D_E_L_E_T_ = ' ' "
cQuery += " AND BM.D_E_L_E_T_ = ' ' "
cQuery += " AND D3.D3_TM      > '500'"
cQuery += " AND D3.D3_ESTORNO <> 'S'"  
cQuery += " AND D3.D3_FILIAL  = '"+ xFilial("SD3") +"' "

cQuery += cFiltroInt

cQuery += " GROUP BY BM.BM_GRUPO , BM.BM_DESC , D3.D3_COD , B1.B1_I_DESCD , D3.D3_UM , D3.D3_SEGUM , D3.D3_LOCAL "

If Select(cAliasSaid) > 0
	(cAliasSaid)->( DBCloseArea() )
EndIf

DBUseArea( .T. , "TOPCONN" , TcGenQry(,,cQuery) , cAliasSaid , .T. , .F. )
COUNT TO nCountRec //Contabiliza o numero de registros encontrados pela query
  
ProcRegua(nCountRec)                                    

DBSelectArea(cAliasSaid)
(cAliasSaid)->( DBGoTop() )
While (cAliasSaid)->(!Eof())

	IncProc( "Processando a saida do produto: "+ AllTrim( (cAliasSaid)->PRODUTO ) )
    
	nPosProSai := aScan( aSaida , {|x| AllTrim(x[3]) == AllTrim( (cAliasSaid)->PRODUTO ) } )
	
	If nPosProSai > 0
        
		If (cAliasSaid)->SEGUM <> "KG"
		
    		aSaida[nPosProSai][5] += (cAliasSaid)->QUANT
    		aSaida[nPosProSai][7] += (cAliasSaid)->QTSEGUM
    		
    	ElseIf (cAliasSaid)->segum = "KG"
    	
    	    aSaida[nPosProSai][5] += (cAliasSaid)->QTSEGUM
    		aSaida[nPosProSai][7] += (cAliasSaid)->QUANT
    		
    	EndIf
        
	Else
		
		If (cAliasSaid)->SEGUM <> "KG"
		
			aAdd( aSaida , {	(cAliasSaid)->GRUPO			,;
								(cAliasSaid)->DESCGRUPO		,;
								(cAliasSaid)->PRODUTO		,;
								(cAliasSaid)->DESCPRODUT	,;
								(cAliasSaid)->QUANT			,;
								(cAliasSaid)->UM			,;
								(cAliasSaid)->QTSEGUM		,;
								(cAliasSaid)->SEGUM			,;
								(cAliasSaid)->LOTEPADRAO	,;
								"N"							})
   		
   		ElseIf (cAliasSaid)->SEGUM == "KG"
   		
   			aAdd( aSaida , {	(cAliasSaid)->GRUPO			,;
   								(cAliasSaid)->DESCGRUPO		,;
   								(cAliasSaid)->PRODUTO		,;
   								(cAliasSaid)->DESCPRODUT	,;
								(cAliasSaid)->QTSEGUM		,;
								(cAliasSaid)->SEGUM			,;
								(cAliasSaid)->QUANT			,;
								(cAliasSaid)->UM			,;
								(cAliasSaid)->LOTEPADRAO	,;
								"S"							})
      	
     	EndIf
     	
	EndIf

(cAliasSaid)->( DBSkip() )
EndDo

(cAliasSaid)->( DBCloseArea() )

nPosProEnt := 0

//================================================================================
// Pega todas as Entradas e suas respectivas saidas e joga no array Dados
//================================================================================
For _nI := 1 To Len(aEntrada)

	nPosProEnt := aScan( aSaida , {|x| AllTrim(x[3]) == AllTrim( aEntrada[_nI][03] ) } )
	
	If nPosProEnt > 0
		
		If aEntrada[_nI,10] = "N"
		
 			aAdd( aDados , {	aEntrada[_nI][01]		,;
 								aEntrada[_nI][02]		,;
 								aEntrada[_nI][03]		,;
 								aEntrada[_nI][04]		,;
 								aEntrada[_nI][05]		,;
 								aEntrada[_nI][06]		,;
 								aEntrada[_nI][07]		,;
 								aEntrada[_nI][08]		,;
 								aSaida[nPosProEnt][05]	,;
 								aSaida[nPosProEnt][07]	,;
 								aEntrada[_nI][09]		,;
 								0						,;
 								0						,;
 								"N"						})
 		
    	ElseIf aEntrada[_nI,10] = "S"
    	
            aAdd( aDados , {	aEntrada[_nI][01]		,;
            					aEntrada[_nI][02]		,;
            					aEntrada[_nI][03]		,;
            					aEntrada[_nI][04]		,;
            					aEntrada[_nI][05]		,;
            					aEntrada[_nI][06]		,;
								aEntrada[_nI][07]		,;
								aEntrada[_nI][08]		,;
								aSaida[nPosProEnt][05]	,;
								aSaida[nPosProEnt][07]	,;
								aEntrada[_nI][09]		,;
								0						,;
								0						,;
								"S"						})
		
    	EndIf
    
	Else
 	
 		If aEntrada[_nI][10] = "N"
 		
 			aAdd( aDados , {	aEntrada[_nI][01]	,;
 								aEntrada[_nI][02]	,;
 								aEntrada[_nI][03]	,;
 								aEntrada[_nI][04]	,;
 								aEntrada[_nI][05]	,;
 								aEntrada[_nI][06]	,;
								aEntrada[_nI][07]	,;
								aEntrada[_nI][08]	,;
								0					,;
								0					,;
								aEntrada[_nI][09]	,;
								0					,;
								0					,;
								"N"					})
		
    	ElseIf aEntrada[_nI][10] = "S"
    	
    		aAdd( aDados , {	aEntrada[_nI][01]	,;
    							aEntrada[_nI][02]	,;
    							aEntrada[_nI][03]	,;
    							aEntrada[_nI][04]	,;
    							aEntrada[_nI][05]	,;
    							aEntrada[_nI][06]	,;
								aEntrada[_nI][07]	,;
								aEntrada[_nI][08]	,;
								0					,;
								0					,;
								aEntrada[_nI][09]	,;
								0					,;
								0					,;
								"S"					})
		
    	EndIf
    	
	EndIf

Next _nI

//================================================================================
// Pega todas as Saidas que nao houve entrada e joga no array Dados
//================================================================================
nPosProEnt := 0

For _nI := 1 to Len(aSaida)

	nPosProEnt := aScan( aDados , {|x| AllTrim(x[3]) == AllTrim( aSaida[_nI][03] ) } )
	
	If nPosProEnt == 0
	
		If aSaida[_nI][10] = "N"
		
 			aAdd( aDados , {	aSaida[_nI][01]		,;
 								aSaida[_nI][02]		,;
 								aSaida[_nI][03]		,;
 								aSaida[_nI][04]		,;
 								0					,;
 								aSaida[_nI][06]		,;
								0					,;
								aSaida[_nI][08]		,;
								aSaida[_nI][05]		,;
								aSaida[_nI][07]		,;
								aSaida[_nI][09]		,;
								0					,;
								0					,;
								"N"					})
		
    	ElseIf aSaida[_nI][10] = "S"
    	
 			aAdd( aDados , {	aSaida[_nI][01]		,;
 								aSaida[_nI][02]		,;
 								aSaida[_nI][03]		,;
 								aSaida[_nI][04]		,;
 								0					,;
 								aSaida[_nI][06]		,;
								0					,;
								aSaida[_nI][08]		,;
								aSaida[_nI][05]		,;
								aSaida[_nI][07]		,;
								aSaida[_nI][09]		,;
								0					,;
								0					,;
								"S"					})
		
    	EndIf
    	
	EndIf

Next _nI

//================================================================================
// Considera Produtos sem movimentacao de estoque no periodo indicado
//================================================================================
If MV_PAR12 == 1
          
	For _nI := 1 To Len( aDados )
	     cProdMovi += aDados[_nI][03] +';'
	Next _nI
	
	cProdMovi := SubStr( cProdMovi , 1 , Len(cProdMovi) - 1 )
	
	cQuery := " SELECT "
	cQuery += " 	BM.BM_GRUPO		,"
	cQuery += " 	BM.BM_DESC		,"
	cQuery += " 	B1.B1_COD		,"
	cQuery += " 	B1.B1_I_DESCD	,"
	cQuery += " 	B1.B1_UM		,"
	cQuery += " 	B1.B1_SEGUM		,"
	cQuery += " 	B2.B2_LOCAL		 "
	cQuery += " FROM "+ RetSqlName("SB2") +" B2 "
	cQuery += " JOIN "+ RetSqlName("SB1") +" B1 ON B1.B1_COD   = B2.B2_COD   "
	cQuery += " JOIN "+ RetSqlName("SBM") +" BM ON B1.B1_GRUPO = BM.BM_GRUPO "
	cQuery += " WHERE "
	cQuery += "     B1.D_E_L_E_T_ = ' ' "
	cQuery += " AND BM.D_E_L_E_T_ = ' ' "
	cQuery += " AND B2.D_E_L_E_T_ = ' ' "
	cQuery += " AND B2.B2_FILIAL  = '"+ xFilial("SB2") +"' "
	cQuery += " AND B2.B2_LOCAL   IN "+ FormatIn( MV_PAR03 , ";" )
	
	If !Empty(cProdMovi)
	cQuery += " AND B1.B1_COD     NOT IN "+ FormatIn( cProdMovi , ";" )
	EndIf
	
	cQuery += cFiltProd
	
	If Select(cAliasProd) > 0
		(cAliasProd)->( DBCloseArea() )
	EndIf
	
	DBUseArea( .T. , "TOPCONN" , TcGenQry(,,cQuery) , cAliasProd , .T. , .F. )
	COUNT TO nCountRec //Contabiliza o numero de registros encontrados pela query
	
	ProcRegua(nCountRec)
	
	DBSelectArea(cAliasProd)
	(cAliasProd)->( DBGoTop() )
	While (cAliasProd)->( !Eof() )
	
		IncProc("Selecionando Produtos sem movmentacao de estoque")
		
		If (cAliasProd)->B1_SEGUM <> "KG"
		
			aAdd( aDados , {	(cAliasProd)->BM_GRUPO		,;
								(cAliasProd)->BM_DESC		,;
								(cAliasProd)->B1_COD		,;
								(cAliasProd)->B1_I_DESCD	,;
								0							,;
								(cAliasProd)->B1_UM			,;
								0							,;
								(cAliasProd)->B1_SEGUM		,;
								0							,;
								0							,;
								(cAliasProd)->B2_LOCAL		,;
								0							,;
								0							,;
								"N"							})
		
		ElseIf (cAliasProd)->B1_SEGUM = "KG"
		
			aAdd( aDados , {	(cAliasProd)->BM_GRUPO		,;
								(cAliasProd)->BM_DESC		,;
								(cAliasProd)->B1_COD		,;
								(cAliasProd)->B1_I_DESCD	,;
								0							,;
								(cAliasProd)->B1_SEGUM		,;
								0							,;
								(cAliasProd)->B1_UM			,;
								0							,;
								0							,;
								(cAliasProd)->B2_LOCAL		,;
								0							,;
								0							,;
								"S"							})
		
		EndIf
	
	(cAliasProd)->( DBSkip() )
	EndDo	              
	
	DBSelectArea(cAliasProd)
	(cAliasProd)->( DBCloseArea() )
	
EndIf

If Len(aDados) > 0

	oPrint:StartPage()					//Inicia uma nova Pagina
	
	ROMS020CAB(1) 
	
	nlinha += ( nSaltoLinha * 2 )

	ROMS020CPR()

	aDados := aSort( aDados ,,, {|x, y| x[01]+x[03] < y[01]+y[03] } ) // Ordena os dados por grupo de Produto + Produto

	ProcRegua(Len(aDados))
	
	//================================================================================
	// Calcula o saldo anterior do Produtos e imprime os dados dos Produtos
	//================================================================================
	For _nI := 1 to Len(aDados)
	                          
		IncProc("Os dados estão sendo processados, favor aguardar...")                              
	                          
		aSaldo := CalcEst( aDados[_nI][03],aDados[_nI][11],MV_PAR01)
	    
		If aDados[_nI][14] = "N"
		
			aDados[_nI][12] := aSaldo[01]
			aDados[_nI][13] := aSaldo[07]
						
		ElseIf aDados[_nI][14] = "S"
		
			aDados[_nI][12]:= aSaldo[07]
			aDados[_nI][13]:= aSaldo[01]
			
		EndIf
		
		//================================================================================
		// Verifica se eh necessaria a impressao do Item sem movimentacao de estoque pois
		// podem nao ter saldo anterior, devido a isso eles nao devem ser impressos
		//================================================================================
		If (aDados[_nI][05] + aDados[_nI][07] + aDados[_nI][09] + aDados[_nI][10] + aDados[_nI][12] + aDados[_nI][13]) == 0
		     Loop
		EndIf
		
		//================================================================================
		// Saldo Anterior
		//================================================================================
		nTotGrSld1 += aDados[_nI][12]
		nTotGrSld2 += aDados[_nI][13]
		
		//================================================================================
		// Entradas
		//================================================================================
		nTotGrEnt1 += aDados[_nI][05]
		nTotGrEnt2 += aDados[_nI][07]
		
		//================================================================================
		// Saidas
		//================================================================================
		nTotGrSai1 += aDados[_nI][09]
		nTotGrSai2 += aDados[_nI][10]
		
		//================================================================================
		// Saldo
		//================================================================================
		nTotGrSal1 += ( aDados[_nI][12] + aDados[_nI][05]) - aDados[_nI][09]
		nTotGrSal2 += ( aDados[_nI][13] + aDados[_nI][07]) - aDados[_nI][10]
		
		//================================================================================
		// Verfica quebra por Grupo de Produto
		//================================================================================
		If aScan( aGrupoProd , {|z| AllTrim(z[01]) == AllTrim(aDados[_nI][01]) } ) == 0
			
			//================================================================================
			// Verifica se Imprime Totalizador
			//================================================================================
			If Len(aGrupoProd) > 0
			
				nlinha += nSaltoLinha
				
				ROMS020BOX()       
				
				nlinha += nSaltoLinha
				
				ROMS020PAG(0,1)
				
				ROMS020TOT( "TOTAL GRUPO: "+ AllTrim( aGrupoProd[ Len(aGrupoProd) ][ 01 ] ) +'-'+ AllTrim( aGrupoProd[ Len(aGrupoProd) ][ 02 ] ) ,;
						   nTotSld1 , nTotSld2 , nTotEnt1 , nTotEnt2 , nTotSai1 , nTotSai2 , nTotSal1 , nTotSal2 )
				
				nlinha += nSaltoLinha
				
			EndIf
			
			nlinha += nSaltoLinha
			
			ROMS020PAG(0,1)
			
		    oPrint:Say( nlinha + nAjuAltLi1 , nColInic + 10 , SubStr( "GRUPO: "+ AllTrim(aDados[_nI][1]) +'-'+ AllTrim( aDados[_nI][2] ) , 1 , 35 ) , oFont10b )
		    
		    nLinInBox := nlinha + nSaltoLinha
		    
		    //================================================================================
		    // Saldo Anterior
		    //================================================================================
			nTotSld1 := aDados[_nI][12]
			nTotSld2 := aDados[_nI][13]
			
			//================================================================================
			// Entradas
			//================================================================================
			nTotEnt1 := aDados[_nI][05]
			nTotEnt2 := aDados[_nI][07]
			
			//================================================================================
			// Saidas
			//================================================================================
			nTotSai1 := aDados[_nI][09]
			nTotSai2 := aDados[_nI][10]
			
			//================================================================================
			// Saldo
			//================================================================================
			nTotSal1 := (aDados[_nI][12] + aDados[_nI][05]) - aDados[_nI][09]
			nTotSal2 := (aDados[_nI][13] + aDados[_nI][07]) - aDados[_nI][10]
			
		Else          
				
			//================================================================================
			// Saldo Anterior
			//================================================================================
			nTotSld1 += aDados[_nI][12]
			nTotSld2 += aDados[_nI][13] 
			
			//================================================================================
			// Entradas
			//================================================================================
			nTotEnt1 += aDados[_nI][05]
			nTotEnt2 += aDados[_nI][07]
			
			//================================================================================
			// Saidas
			//================================================================================
			nTotSai1 += aDados[_nI][09]
			nTotSai2 += aDados[_nI][10]
			
			//================================================================================
			// Saldo
			//================================================================================
			nTotSal1 += ( aDados[_nI][12] + aDados[_nI][05] ) - aDados[_nI][09]
			nTotSal2 += ( aDados[_nI][13] + aDados[_nI][07] ) - aDados[_nI][10]
		
		EndIf
		
		//================================================================================
		// Alimenta o vetor Grupo de Produto
		//================================================================================
		aAdd( aGrupoProd , { aDados[_nI][01] , aDados[_nI][02] } )
		
		nlinha += nSaltoLinha
		
		ROMS020PAG(0,0)
		
		ROMS020PRT(	AllTrim(aDados[_nI][03])+'-'+AllTrim(aDados[_nI][04])	,;
					aDados[_nI][12]											,;
					aDados[_nI][13]											,;
					aDados[_nI][05]											,;
					aDados[_nI][07]											,;
					aDados[_nI][09]											,;
					aDados[_nI][10]											,;
					aDados[_nI][06]											,;
					aDados[_nI][08]											 )
		
		//================================================================================
		// Imprime Linhas
		//================================================================================
		oPrint:Line( nLinha , nColInic        , nLinha , nColInic + 0750 )
		oPrint:Line( nLinha , nColInic + 0760 , nLinha , nColInic + 1420 )
		oPrint:Line( nLinha , nColInic + 1430 , nLinha , nColInic + 2080 )
		oPrint:Line( nLinha , nColInic + 2090 , nLinha , nColInic + 2740 )
		oPrint:Line( nLinha , nColInic + 2750 , nLinha , nColFinal       )
	
	Next _nI

	nlinha += nSaltoLinha
	
	ROMS020BOX()
                         
	If Len(aGrupoProd) > 0
	
		nlinha += nSaltoLinha
		
		ROMS020PAG(0,1)
		
		ROMS020TOT(	"TOTAL GRUPO: "+ AllTrim( aGrupoProd[Len(aGrupoProd)][01] ) +'-'+ AllTrim( aGrupoProd[Len(aGrupoProd)][02] )	,;
					nTotSld1 , nTotSld2 , nTotEnt1 , nTotEnt2 , nTotSai1 , nTotSai2 , nTotSal1 , nTotSal2 )
		
		nlinha += nSaltoLinha
	
	EndIf
	
	nlinha += nSaltoLinha
	
	ROMS020PAG(0,1)
	
	ROMS020TOT( "TOTAL GERAL" , nTotGrSld1 , nTotGrSld2 , nTotGrEnt1 , nTotGrEnt2 , nTotGrSai1 , nTotGrSai2 , nTotGrSal1 , nTotGrSal2 )

EndIf

Return
