/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Walaluer |24/10/2018| Chamado 26743. Inclusão da pergunta (parâmetro) de grupo de compras
Lucas Borges  |08/10/2024| Chamado 48465. Retirada manipulação do SX1
Lucas Borges  |22/04/2025| Chamado 50505. Alterada a picture do CNPJ para contemplar campo alfanumérico
===============================================================================================================================
*/

#Include "report.ch"
#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RCOM012
Autor-------------: Alex Wallauer Ferreira / Josue Danich
Data da Criacao---: 19/07/2017
Descrição---------: Relatorio de Analise de Fornecedor x Produto - Chamado 20207
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RCOM012()

Private oReport		:= Nil
Private oBrkEntr_1	:= Nil
Private oBrkEntr_2	:= Nil
Private oBrkEnt2_2	:= Nil

Private _aOrd		:= { "Por Fornecedor" }//, "Por Data de Entrada" , "Por Produto Sintetico" , "Por CFOP" , "Fornecedor x Produto" }
Private _cNomeForn	:= "" //Armazena o nome e o codigo do fornecedor para ser utilizado na impressao da quebra
Private _cNumNF		:= "" //Armazena o numero da nota fiscal para ser utilizado na impressao da quebra  
Private _cPerg		:= "RCOM012"

Pergunte( _cPerg , .F. )

DEFINE REPORT oReport	NAME		_cPerg ;
						TITLE		"Relatorio de Analise de Fornecedor x Produto" ;
						PARAMETER	_cPerg ;
						ACTION		{|oReport| RCOM012PR( oReport ) } ;
						Description	"Este relatório emitirá a Analise de Fornecedor x Produto de acordo com os parâmetros informados pelo usuário."

//====================================================================================================
// Seta Padrao de impressao como Paisagem
//====================================================================================================
oReport:SetLandscape()
oReport:SetTotalInLine(.F.)

oReport:nFontBody	:= 08
oReport:cFontBody	:= "Courier New"
oReport:nLineHeight	:= 45 // Define a altura da linha.

//====================================================================================================
// Define secoes para as ordens
//====================================================================================================

//====================================================================================================
// Define secoes para primeira ordem - Por Fornecedor - SINTETICO
//====================================================================================================
DEFINE Section oSecEntr_1 OF oReport TITLE "Entrada_ordem_1" TABLES "SA2" ORDERS _aOrd

DEFINE CELL NAME "FORNECEDOR"   OF oSecEntr_1 ALIAS "SA2"  TITLE "Fornecedor"		SIZE 20 BLOCK{|| QRY1->A2_COD + '-' + QRY1->A2_LOJA}    
DEFINE CELL NAME "A2_NOME"      OF oSecEntr_1 ALIAS "SA2"  TITLE "Razao Social"		SIZE 40
DEFINE CELL NAME "A2_CGC"       OF oSecEntr_1 ALIAS "SA2"  TITLE "CNPJ"				SIZE 20 PICTURE "@R! NN.NNN.NNN/NNNN-99"

oSecEntr_1:Disable()       

DEFINE Section oSecDado_1 OF oSecEntr_1 TITLE "SINTETICO" TABLES "SD1"

DEFINE CELL NAME "D1_QUANT"     OF oSecDado_1 ALIAS "SD1" TITLE "VOLUME TOTAL NF"	        SIZE 25 PICTURE "@E 99,999,999.99999"
DEFINE CELL NAME "D1_TOTAL"     OF oSecDado_1 ALIAS "SD1" TITLE "VALOR TOTAL PAGO PROD"	    SIZE 25 PICTURE "@E 99,999,999,999.99"
DEFINE CELL NAME "VTFRETE"      OF oSecDado_1 ALIAS "SD1" TITLE "FRETE"	                    SIZE 25 PICTURE "@E 99,999,999,999.99"
DEFINE CELL NAME "VTPP_FRET"    OF oSecDado_1 ALIAS "SD1" TITLE "VLR TOT PAGO PROD + FRETE" SIZE 25 PICTURE "@E 99,999,999,999.99" BLOCK{|| QRY1->D1_TOTAL+QRY1-> VTFRETE }

//====================================================================================================
// Desabilita Secao e configura salto em numero de linhas para a proxima secao
//====================================================================================================
oSecDado_1:Disable()
oSecEntr_1:SetLinesBefore(5)

//====================================================================================================
// Alinhamento de cabecalho
//====================================================================================================
oSecDado_1:Cell( "D1_TOTAL"  ):SetHeaderAlign("RIGHT")
oSecDado_1:Cell( "D1_QUANT"  ):SetHeaderAlign("RIGHT")
oSecDado_1:Cell( "VTFRETE"  ):SetHeaderAlign("RIGHT")
oSecDado_1:Cell( "VTPP_FRET" ):SetHeaderAlign("RIGHT")

oSecDado_1:SetTotalInLine(.F.)

//====================================================================================================
// Define secoes para primeira ordem - Por Fornecedor - Analitico
//====================================================================================================
DEFINE Section oSecEntr_2 OF oReport TITLE "Entrada_ordem_2" TABLES "SA2","SD1" ORDERS _aOrd

DEFINE CELL NAME "D1_DTDIGIT"	OF oSecEntr_2 ALIAS "SD1"  TITLE "Data Entrada"         
DEFINE CELL NAME "NOTAFISCAL"   OF oSecEntr_2 ALIAS "SD1"  TITLE "Nota Fiscal"   SIZE 23 BLOCK{|| QRY2->D1_doc + '-' + QRY2->D1_serie}
DEFINE CELL NAME "FORNECEDOR"   OF oSecEntr_2 ALIAS "SA2"  TITLE "Fornecedor"    SIZE 20 BLOCK{|| QRY2->a2_cod + '-' + QRY2->a2_loja}    
DEFINE CELL NAME "A2_NOME"      OF oSecEntr_2 ALIAS "SA2"  TITLE "Razao Social"  SIZE 40
DEFINE CELL NAME "A2_CGC"       OF oSecEntr_2 ALIAS "SA2"  TITLE "CNPJ"          SIZE 20 PICTURE "@R! NN.NNN.NNN/NNNN-99"

oSecEntr_2:Disable()
DEFINE Section oSecDado_2 OF oSecEntr_2 TITLE "ANALITICO" TABLES "SD1","SB1"

DEFINE CELL NAME "B1_COD"       OF oSecDado_2 ALIAS "SB1" TITLE "Produto" 			   SIZE 20
DEFINE CELL NAME "B1_DESC"	    OF oSecDado_2 ALIAS "SB1" TITLE "Descricao"            SIZE 40
DEFINE CELL NAME "D1_QUANT"     OF oSecDado_2 ALIAS "SD1" TITLE "Quantidade"           SIZE 25 PICTURE "@E 99,999,999,999.99"
DEFINE CELL NAME "D1_UM"        OF oSecDado_2 ALIAS "SD1" TITLE "UM"                   SIZE 07
DEFINE CELL NAME "D1_VUNIT"     OF oSecDado_2 ALIAS "SD1" TITLE "Vlr.Unit."            SIZE 25 PICTURE "@E 99,999,999,999.99"
DEFINE CELL NAME "D1_TOTAL"     OF oSecDado_2 ALIAS "SD1" TITLE "Vlr.Total"            SIZE 25 PICTURE "@E 99,999,999,999.99"  
DEFINE CELL NAME "D1_PICM"      OF oSecDado_2 ALIAS "SD1" TITLE "Aliq.ICMS"            SIZE 25 PICTURE "@E 99,999,999,999.99"
DEFINE CELL NAME "D1_VALICM"    OF oSecDado_2 ALIAS "SD1" TITLE "Valor ICMS"           SIZE 25 PICTURE "@E 99,999,999,999.99"
DEFINE CELL NAME "VTFRETE"      OF oSecDado_2 ALIAS "SD1" TITLE "Valor Frete"          SIZE 25 PICTURE "@E 99,999,999,999.99"
DEFINE CELL NAME "TOTAPGTO"     OF oSecDado_2 ALIAS "SD1" TITLE "Total+Frete"          SIZE 25 PICTURE "@E 99,999,999,999.99"
DEFINE CELL NAME "TOTAPGTOU"    OF oSecDado_2 ALIAS "SD1" TITLE "Mix Pg/Frete"         SIZE 25 PICTURE "@E 99,999,999,999.99"


//====================================================================================================
// Desabilita Secao e configura salto em numero de linhas para a proxima secao
//====================================================================================================
oSecDado_2:Disable()
oSecEntr_2:SetLinesBefore(5)

//====================================================================================================
// Alinhamento de cabecalho
//====================================================================================================
oSecDado_2:Cell( "D1_QUANT"   ):SetHeaderAlign("RIGHT")
oSecDado_2:Cell( "D1_VUNIT"   ):SetHeaderAlign("RIGHT")
oSecDado_2:Cell( "D1_TOTAL"   ):SetHeaderAlign("RIGHT")
oSecDado_2:Cell( "D1_PICM"    ):SetHeaderAlign("RIGHT")
oSecDado_2:Cell( "D1_VALICM"  ):SetHeaderAlign("RIGHT")
oSecDado_2:Cell( "VTFRETE"    ):SetHeaderAlign("RIGHT") 
oSecDado_2:Cell( "TOTAPGTO"   ):SetHeaderAlign("RIGHT")
oSecDado_2:Cell( "TOTAPGTOU"  ):SetHeaderAlign("RIGHT")


oSecDado_2:SetTotalInLine(.F.)
oSecDado_2:OnPrintLine({|| _cNumNF :=QRY2->D1_DOC + '-' + QRY2->D1_SERIE, _cNomeForn:=QRY2->A2_NOME })             

oReport:PrintDialog()

Return

/*
===============================================================================================================================
Programa----------: RCOM012PR
Autor-------------: Alex Wallauer Ferreira
Data da Criacao---: 19/07/2017
Descrição---------: Executa relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RCOM012PR( oReport )

Local 	_cFiltro  	:= "% "
Local   _cFiltro2   := "% "
//Local 	_cCFOPs   	:= ""
Private _nOrdem  	:= oSecEntr_1:GetOrder() //Busca ordem selecionada pelo usuario   

If Empty( MV_PAR04 ) .And. MV_PAR07 == 1
   U_ITMsg( "Codigo do Produto dever ser informado, quando selecionado tipo Analítico","Atenção",,1 )
   Return .F.
EndIf

If !Empty( MV_PAR09 ) .And. MV_PAR07 == 1
   U_ITMsg( "Codigo do Grupo de Comprador NÃO dever ser informado, quando selecionado tipo Analítico","Atenção",,1 )
   Return .F.
EndIf

oReport:SetTitle( "Relatorio de Analise de Fornecedor x Produto (" + IIf(MV_PAR07 == 1,"ANALITICO","SINTETICO") + ")" )

//====================================================================================================
// Define o filtro de acordo com os parametros digitados
//====================================================================================================
If !Empty( MV_PAR01 )
	_cFiltro  += " AND D1.D1_FILIAL IN "+ FormatIn( AllTrim(MV_PAR01) , ";" )
	_cFiltro2  += " AND D1T.D1_FILIAL IN "+ FormatIn( AllTrim(MV_PAR01) , ";" )
EndIf

//====================================================================================================
// Define o filtro de filial para A2 de acordo com boas práticas
//====================================================================================================
_cFiltro  += " AND A2.A2_FILIAL = '" + xFilial("SA2") + "' "

//====================================================================================================
// Filtra data de Recebimento
//====================================================================================================
If !Empty( MV_PAR02 ) .And. !Empty( MV_PAR03 )
	_cFiltro  += " AND D1.D1_DTDIGIT BETWEEN '"+ DToS( MV_PAR02 ) +"' AND '"+ DToS( MV_PAR03 ) +"' "
EndIf

//====================================================================================================
// Filtra Produto
//====================================================================================================
If !Empty( MV_PAR04 ) 
	_cFiltro  += " AND D1.D1_COD = '"+ MV_PAR04+"' "
EndIf

//====================================================================================================
// Filtra data de Emissao
//====================================================================================================
If !Empty( MV_PAR05 ) .And. !Empty( MV_PAR06 )
	_cFiltro  += " AND D1.D1_EMISSAO BETWEEN '"+ DToS( MV_PAR05 ) +"' AND '"+ DToS( MV_PAR06) +"' "
EndIf

//====================================================================================================
// Filtra Fornecedor
//====================================================================================================
If !Empty( MV_PAR08 ) 
	_cFiltro  += " AND D1.D1_FORNECE = '" + MV_PAR08 + "' "
EndIf

//====================================================================================================
//Filtra grupo de compras
//====================================================================================================
If !Empty(MV_PAR09)
	_cFiltro += " AND D1.D1_FILIAL||D1.D1_PEDIDO IN (SELECT C7.C7_FILIAL||C7.C7_NUM FROM "+RetSqlName("SC7")+" C7 WHERE C7.D_E_L_E_T_ = ' ' AND  C7_GRUPCOM = '" + MV_PAR09 + "') "
EndIf

_cFiltro  += " %"
_cFiltro2  += " %"



//====================================================================================================
// Primeira Ordem - Por Fornecedor
//====================================================================================================
If _nOrdem == 1                  
	
	//====================================================================================================
	// Sintetico
	//====================================================================================================
	If MV_PAR07 == 2
		
		oSecEntr_1:Enable()
		oSecDado_1:Enable()
				
		TRFunction():New( oSecDado_1:Cell( "D1_TOTAL"   ),NIL,"SUM",oBrkEntr_1,NIL,NIL,NIL,.F.,.T.)
		TRFunction():New( oSecDado_1:Cell( "D1_QUANT"   ),NIL,"SUM",oBrkEntr_1,NIL,NIL,NIL,.F.,.T.)
		TRFunction():New( oSecDado_1:Cell( "VTFRETE"   ),NIL,"SUM",oBrkEntr_1,NIL,NIL,NIL,.F.,.T.)
		
		BEGIN REPORT QUERY oSecEntr_1
		
			BeginSql alias "QRY1"
			
			   	SELECT 
			   	
 					NVL((SELECT SUM(D1T.D1_TOTAL) FROM %Table:SD1% D1T JOIN %Table:SF8% SF8 ON SF8.F8_FILIAL = D1T.D1_FILIAL AND SF8.F8_NFDIFRE = D1T.D1_DOC
                                          AND SF8.F8_SEDIFRE = D1T.D1_SERIE AND SF8.F8_TRANSP = D1T.D1_FORNECE AND SF8.F8_LOJTRAN = D1T.D1_LOJA AND SF8.F8_NFORIG = D1T.D1_NFORI
                         WHERE SF8.D_E_L_E_T_ = ' ' AND D1T.D_E_L_E_T_ = ' ' %exp:_cFiltro2% AND SF8.F8_FORNECE = A2.A2_COD AND SF8.F8_LOJA = A2.A2_LOJA),SUM(D1.D1_VALFRE)) VTFRETE,
               
								NVL((SELECT SUM(D1T.D1_TOTAL) FROM %Table:SD1% D1T JOIN %Table:SF8% SF8 ON SF8.F8_FILIAL = D1T.D1_FILIAL AND SF8.F8_NFDIFRE = D1T.D1_DOC
                                          AND SF8.F8_SEDIFRE = D1T.D1_SERIE AND SF8.F8_TRANSP = D1T.D1_FORNECE AND SF8.F8_LOJTRAN = D1T.D1_LOJA AND SF8.F8_NFORIG = D1T.D1_NFORI
                                          WHERE SF8.D_E_L_E_T_ = ' ' AND D1T.D_E_L_E_T_ = ' ' 	AND SF8.F8_FORNECE = A2.A2_COD %exp:_cFiltro2% AND SF8.F8_LOJA = A2.A2_LOJA)
                                          															+SUM(D1.D1_TOTAL),SUM(D1.D1_VALFRE)+SUM(D1.D1_TOTAL))  TOTAPGTO,   
                
							NVL(((SELECT SUM(D1T.D1_TOTAL) FROM %Table:SD1% D1T JOIN %Table:SF8% SF8 ON SF8.F8_FILIAL = D1T.D1_FILIAL AND SF8.F8_NFDIFRE = D1T.D1_DOC
                                          AND SF8.F8_SEDIFRE = D1T.D1_SERIE AND SF8.F8_TRANSP = D1T.D1_FORNECE AND SF8.F8_LOJTRAN = D1T.D1_LOJA AND SF8.F8_NFORIG = D1T.D1_NFORI
                                          WHERE SF8.D_E_L_E_T_ = ' ' AND D1T.D_E_L_E_T_ = ' ' 	%exp:_cFiltro2% AND SF8.F8_FORNECE = A2.A2_COD AND SF8.F8_LOJA = A2.A2_LOJA)
                                          	+SUM(D1.D1_TOTAL))/(Case SUM(D1.D1_QUANT) WHEN 0 THEN 1 Else SUM(D1.D1_QUANT) END),
                                          	(SUM(D1.D1_VALFRE)+SUM(D1.D1_TOTAL))/(Case SUM(D1.D1_QUANT) WHEN 0 THEN 1 Else SUM(D1.D1_QUANT) END)) TOTAPGTOU,                
			   	
			   	
			   	
				 	A2.A2_COD, A2.A2_LOJA, A2.A2_NOME, A2.A2_CGC , sum(D1.D1_QUANT) D1_QUANT , sum(D1.D1_TOTAL) D1_TOTAL
				FROM %Table:SD1% D1
				JOIN %Table:SA2% A2 ON D1.D1_FORNECE = A2.A2_COD  AND D1.D1_LOJA = A2.A2_LOJA    
				JOIN %Table:SF4% F4 ON F4.F4_FILIAL  = D1.D1_FILIAL AND F4.F4_CODIGO = D1.D1_TES 				
				WHERE
					D1.%notDel%
				AND A2.%notDel%      
				AND F4.%notDel%				
				AND F4.F4_DUPLIC = 'S'				
				AND D1.D1_TIPO <> 'D' 
 
				%exp:_cFiltro%
				GROUP BY A2.A2_COD,A2.A2_LOJA,A2.A2_NOME,A2.A2_CGC,A2_FILIAL
				ORDER BY A2.A2_COD,A2.A2_LOJA
			
			EndSql
			
		END REPORT QUERY oSecEntr_1
		
		oSecDado_1:SetParentQuery()
		oSecDado_1:SetParentFilter( {|cParam| QRY1->A2_COD +  QRY1->A2_LOJA == cParam} , {|| QRY1->A2_COD +  QRY1->A2_LOJA } )
		oSecEntr_1:Print(.T.)
	
	Else		                 
	//====================================================================================================
	// Analitico
	//====================================================================================================
		oSecEntr_2:Enable()
		oSecDado_2:Enable()
		
		//====================================================================================================
		// Quebra por Rede
		//====================================================================================================
		oBrkEntr_2 := TRBreak():New( oSecDado_2 , oSecEntr_2:CELL("NOTAFISCAL") , "Total N.F.: " + _cNumNF , .F. )
		oBrkEntr_2:SetTotalText( {|| "Total N.F.: " + _cNumNF } )
		
		TRFunction():New( oSecDado_2:Cell( "D1_QUANT"  ) , NIL , "SUM" , oBrkEntr_2 ,NIL,NIL,NIL,.F.,.F. )
		TRFunction():New( oSecDado_2:Cell( "D1_TOTAL"  ) , NIL , "SUM" , oBrkEntr_2 ,NIL,NIL,NIL,.F.,.F. )
		TRFunction():New( oSecDado_2:Cell( "D1_VALICM" ) , NIL , "SUM" , oBrkEntr_2 ,NIL,NIL,NIL,.F.,.F. )    
		
		//====================================================================================================
		// Quebra por Fornecedor
		//====================================================================================================
		oBrkEnt2_2 := TRBreak():New( oReport , oSecEntr_2:CELL( "FORNECEDOR" ) , "Total Fornecedor: " + _cNomeForn , .F. )
		oBrkEnt2_2:SetTotalText( {|| "Total Fornecedor: " + _cNomeForn } )
		
		TRFunction():New( oSecDado_2:Cell( "D1_QUANT"  ) , NIL , "SUM" , oBrkEnt2_2 ,NIL,NIL,NIL,.F.,.T. )
		TRFunction():New( oSecDado_2:Cell( "D1_TOTAL"  ) , NIL , "SUM" , oBrkEnt2_2 ,NIL,NIL,NIL,.F.,.T. )
		TRFunction():New( oSecDado_2:Cell( "D1_VALICM" ) , NIL , "SUM" , oBrkEnt2_2 ,NIL,NIL,NIL,.F.,.T. )
		
		//====================================================================================================
		// Executa query para consultar Dados
		//====================================================================================================
		BEGIN REPORT QUERY oSecEntr_2
		
			BeginSql alias "QRY2"
			
			
			SELECT 

					NVL((SELECT D1T.D1_TOTAL FROM %Table:SD1% D1T JOIN %Table:SF8% SF8 ON SF8.F8_FILIAL = D1T.D1_FILIAL AND SF8.F8_NFDIFRE = D1T.D1_DOC
                                          AND SF8.F8_SEDIFRE = D1T.D1_SERIE AND SF8.F8_TRANSP = D1T.D1_FORNECE AND SF8.F8_LOJTRAN = D1T.D1_LOJA
                         WHERE SF8.D_E_L_E_T_ = ' ' AND D1T.D_E_L_E_T_ = ' ' AND SF8.F8_FILIAL = D1.D1_FILIAL AND SF8.F8_NFORIG = D1.D1_DOC 
                         			AND SF8.F8_FORNECE = D1.D1_FORNECE AND SF8.F8_LOJA = D1.D1_LOJA AND D1T.D1_NFORI = D1.D1_DOC
                         			 AND D1T.D1_ITEMORI = D1.D1_ITEM),D1.D1_VALFRE) VTFRETE,
                
								NVL((SELECT D1T.D1_TOTAL FROM %Table:SD1% D1T JOIN %Table:SF8% SF8 ON SF8.F8_FILIAL = D1T.D1_FILIAL AND SF8.F8_NFDIFRE = D1T.D1_DOC
                                          AND SF8.F8_SEDIFRE = D1T.D1_SERIE AND SF8.F8_TRANSP = D1T.D1_FORNECE AND SF8.F8_LOJTRAN = D1T.D1_LOJA
                         WHERE SF8.D_E_L_E_T_ = ' ' AND D1T.D_E_L_E_T_ = ' ' AND SF8.F8_FILIAL = D1.D1_FILIAL AND SF8.F8_NFORIG = D1.D1_DOC 
                         			AND SF8.F8_FORNECE = D1.D1_FORNECE AND SF8.F8_LOJA = D1.D1_LOJA AND D1T.D1_NFORI = D1.D1_DOC
                         			 AND D1T.D1_ITEMORI = D1.D1_ITEM)+D1.D1_TOTAL,D1.D1_VALFRE)  TOTAPGTO,   
                
							NVL(((SELECT D1T.D1_TOTAL FROM %Table:SD1% D1T JOIN %Table:SF8% SF8 ON SF8.F8_FILIAL = D1T.D1_FILIAL AND SF8.F8_NFDIFRE = D1T.D1_DOC
                                          AND SF8.F8_SEDIFRE = D1T.D1_SERIE AND SF8.F8_TRANSP = D1T.D1_FORNECE AND SF8.F8_LOJTRAN = D1T.D1_LOJA
                         WHERE SF8.D_E_L_E_T_ = ' ' AND D1T.D_E_L_E_T_  ' ' AND SF8.F8_FILIAL = D1.D1_FILIAL AND SF8.F8_NFORIG = D1.D1_DOC 
                         			AND SF8.F8_FORNECE = D1.D1_FORNECE AND SF8.F8_LOJA = D1.D1_LOJA AND D1T.D1_NFORI = D1.D1_DOC
                         			 AND D1T.D1_ITEMORI = D1.D1_ITEM)+D1.D1_TOTAL)/(Case D1.D1_QUANT WHEN 0 THEN 1 Else D1.D1_QUANT END),
                         			 (D1.D1_VALFRE+D1.D1_TOTAL)/(Case D1.D1_QUANT WHEN 0 THEN 1 Else D1.D1_QUANT END)) TOTAPGTOU,                

				A2.A2_COD,A2.A2_LOJA,A2.A2_NOME,A2.A2_CGC,B1.B1_COD,B1.B1_DESC,D1.D1_DOC,D1.D1_SERIE,D1.D1_TIPO,D1.D1_DTDIGIT,D1.D1_ITEM,D1.D1_QUANT,
				D1.D1_UM,D1.D1_VUNIT,D1.D1_TOTAL,D1.D1_PICM,D1.D1_VALICM,D1.D1_BASEIRR,D1.D1_ALIQIRR,D1.D1_VALIRR
           
  			FROM %Table:SD1% D1
				JOIN %Table:SA2% A2 ON D1.D1_FORNECE = A2.A2_COD    AND D1.D1_LOJA = A2.A2_LOJA
				JOIN %Table:SB1% B1 ON D1.D1_COD     = B1.B1_COD
				JOIN %Table:SF4% F4 ON F4.F4_FILIAL  = D1.D1_FILIAL AND F4.F4_CODIGO = D1.D1_TES 
				WHERE
					D1.%notDel%    
				AND A2.%notDel%  
				AND B1.%notDel%
				AND F4.%notDel%				
				AND F4.F4_DUPLIC = 'S'
				AND D1.D1_TIPO <> 'D'     
				%exp:_cFiltro%       
			ORDER BY A2.A2_COD , A2.A2_LOJA , D1.D1_DTDIGIT , D1.D1_DOC , D1.D1_ITEM, D1.D1_FILIAL
				
			EndSql
			
		END REPORT QUERY oSecEntr_2
	 	
		oSecDado_2:SetParentQuery()
		oSecDado_2:SetParentFilter( {|cParam| QRY2->a2_cod +  QRY2->a2_loja + DToS(QRY2->D1_dtdigit) + QRY2->D1_doc + QRY2->D1_serie == cParam},{|| QRY2->a2_cod +  QRY2->a2_loja + DToS(QRY2->D1_dtdigit) + QRY2->D1_doc + QRY2->D1_serie } )
		oSecEntr_2:Print(.T.)
	
	EndIf

EndIf

Return .T.
