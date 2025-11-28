/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Igor Melgaço  |19/06/2024| Chamado 47584. Ajuste para impressão na Ordem de CFOP. 
Lucas Borges  |22/04/2025| Chamado 50505. Alterada a picture do CNPJ para contemplar campo alfanumérico
Jose Gavetti  |11/11/2025| Chamado 52021. Inclusão das colunas de Centro de custo e descrição
===============================================================================================================================
*/

#Include "report.ch"
#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RCOM007
Autor-------------: Fabiano Dias Silva
Data da Criacao---: 05/03/2010
Descrição---------: Relatorio utilizado para exibir os dados das entradas.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RCOM007

	Private oReport		:= Nil
	Private oSecEntr_1	:= Nil
	Private oSecDado_1	:= Nil
	Private oSecEntr_2	:= Nil
	Private oSecDado_2	:= Nil
	Private oSecEntr_3	:= Nil
	Private oSecDado_3	:= Nil
	Private oSecCabe_4	:= Nil
	Private oSecEntr_4	:= Nil
	Private oSecDado_4	:= Nil
	Private oSecEntr_5	:= Nil
	Private oSecDado_6	:= Nil
	Private oSecEntr_6	:= Nil
	Private oSecForn_7	:= Nil
	Private oSecProd_7	:= Nil
	Private oSecDado_7	:= Nil
	Private oBrkEntr_1	:= Nil
	Private oBrkEntr_2	:= Nil
	Private oBrkEnt2_2	:= Nil
	Private oBrkEntr_3	:= Nil
	Private oBrkEnt1_4	:= Nil
	Private oBrkEntr_4	:= Nil
	Private oBrkEntr_6	:= Nil
	Private oBrkForn_7	:= Nil

	Private _aOrd        := { "Por Fornecedor" , "Por Data de Entrada" , "Por Produto Sintetico" , "Por CFOP" , "Fornecedor x Produto" }
	Private _cNomeForn   := "" //Armazena o nome e o codigo do fornecedor para ser utilizado na impressao da quebra
	Private _cNumNF      := "" //Armazena o numero da nota fiscal para ser utilizado na impressao da quebra  
	Private _cDataEnt    := "" //Armazena a data a ser utilizado na impressao da quebra  
	Private _cCFOP       := "" //Armazena a CFOP a ser utilizada na impressao da quebra     
	Private _cNomeProd   := "" //Armazena o nome do produto a ser utilizado na impressao da quebra da ordem 5
	Private _cPerg       := "RCOM007"

	Pergunte( _cPerg , .F. )

	DEFINE REPORT oReport	NAME		_cPerg ;
							TITLE		"Relacao de Notas Fiscais de Entrada" ;
							PARAMETER	_cPerg ;
							ACTION		{|oReport| RCOM007PR( oReport ) } ;
							Description	"Este relatório emitirá a relação de notas fiscais de entrada de acordo com a ordem e parâmetros informados pelo usuário."

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
	// Secao dados da Rede
	//====================================================================================================
	DEFINE Section oSecEntr_1 OF oReport TITLE "Entrada_ordem_1" TABLES "SA2" ORDERS _aOrd

	DEFINE CELL NAME "FORNECEDOR"   OF oSecEntr_1 ALIAS "SA2"  TITLE "Fornecedor"		SIZE 20 BLOCK{|| QRY1->a2_cod + '-' + QRY1->a2_loja}    
	DEFINE CELL NAME "A2_NOME"      OF oSecEntr_1 ALIAS "SA2"  TITLE "Razao Social"		SIZE 40
	DEFINE CELL NAME "A2_NREDUZ"    OF oSecEntr_1 ALIAS "SA2"  TITLE "Nome Fantasia"	SIZE 30
	DEFINE CELL NAME "A2_CGC"       OF oSecEntr_1 ALIAS "SA2"  TITLE "CNPJ"				SIZE 20 PICTURE "@R! NN.NNN.NNN/NNNN-99"
	DEFINE CELL NAME "A2_EST"       OF oSecEntr_1 ALIAS "SA2"  TITLE "Estado" 
	DEFINE CELL NAME "A2_MUN"       OF oSecEntr_1 ALIAS "SA2"  TITLE "Municipio"		SIZE 30

	oSecEntr_1:Disable()       

	DEFINE Section oSecDado_1 OF oSecEntr_1 TITLE "1-Fornecedor Sintetico" TABLES "SD1"

	DEFINE CELL NAME "D1_DTDIGIT"   OF oSecDado_1 ALIAS "SD1" TITLE "Data Entrada"         
	DEFINE CELL NAME "NOTAFISCAL"   OF oSecDado_1 ALIAS "SD1" TITLE "Nota Fiscal"       SIZE 23 BLOCK{|| QRY1->D1_doc + '-' + QRY1->D1_serie} //08/03/13 - Talita - Alterado o tamanho do campo para atender a solicitação do chamado 2817   
	DEFINE CELL NAME "D1_TIPO"      OF oSecDado_1 ALIAS "SD1" TITLE "Tipo"                
	DEFINE CELL NAME "D1_TOTAL"     OF oSecDado_1 ALIAS "SD1" TITLE "Vlr.Mercadoria"    SIZE 25 PICTURE "@E 99,999,999,999.99"
	DEFINE CELL NAME "D1_BASEICM"   OF oSecDado_1 ALIAS "SD1" TITLE "Base ICMS"			SIZE 25 PICTURE "@E 99,999,999,999.99"
	DEFINE CELL NAME "D1_VALICM"    OF oSecDado_1 ALIAS "SD1" TITLE "Valor ICMS"        SIZE 25 PICTURE "@E 99,999,999,999.99"
	DEFINE CELL NAME "D1_BASEIRR"   OF oSecDado_1 ALIAS "SD1" TITLE "Base IRR"          SIZE 25 PICTURE "@E 99,999,999,999.99" //Talita - 08/02/13 - Incluido os campos D1_BASEIRR, D1_ALIQIRR e D1_VALIRR conforme Help: 1774  
	DEFINE CELL NAME "D1_ALIQIRR"   OF oSecDado_1 ALIAS "SD1" TITLE "Aliq. IRR"         SIZE 25 PICTURE "@E 99,999,999,999.99"
	DEFINE CELL NAME "D1_VALIRR"    OF oSecDado_1 ALIAS "SD1" TITLE "Valor IRR"         SIZE 25 PICTURE "@E 99,999,999,999.99"

	//====================================================================================================
	// Desabilita Secao e configura salto em numero de linhas para a proxima secao
	//====================================================================================================
	oSecDado_1:Disable()
	oSecEntr_1:SetLinesBefore(5)

	//====================================================================================================
	// Alinhamento de cabecalho
	//====================================================================================================
	oSecDado_1:Cell( "D1_TOTAL"   ):SetHeaderAlign("RIGHT")
	oSecDado_1:Cell( "D1_BASEICM" ):SetHeaderAlign("RIGHT")
	oSecDado_1:Cell( "D1_VALICM"  ):SetHeaderAlign("RIGHT")
	oSecDado_1:Cell( "D1_BASEIRR" ):SetHeaderAlign("RIGHT") //Talita - 08/02/13 - Incluido os campos D1_BASEIRR, D1_ALIQIRR e D1_VALIRR conforme Help: 1774  
	oSecDado_1:Cell( "D1_ALIQIRR" ):SetHeaderAlign("RIGHT")
	oSecDado_1:Cell( "D1_VALIRR"  ):SetHeaderAlign("RIGHT")

	oSecDado_1:SetTotalInLine(.F.)
	oSecDado_1:OnPrintLine( {|| _cNomeForn := QRY1->A2_COD + '-' + QRY1->A2_LOJA + ' - ' + AllTrim(QRY1->A2_NREDUZ) + ' - ' + QRY1->A2_EST } )

	//====================================================================================================
	// Define secoes para primeira ordem - Por Fornecedor - Analistico
	//====================================================================================================
	DEFINE Section oSecEntr_2 OF oReport TITLE "Entrada_ordem_2" TABLES "SA2","SD1" ORDERS _aOrd

	DEFINE CELL NAME "D1_DTDIGIT"	OF oSecEntr_2 ALIAS "SD1"  TITLE "Data Entrada"         
	DEFINE CELL NAME "NOTAFISCAL"   OF oSecEntr_2 ALIAS "SD1"  TITLE "Nota Fiscal"   SIZE 23 BLOCK{|| QRY2->D1_doc + '-' + QRY2->D1_serie} //08/03/13 - Talita - Alterado o tamanho do campo para atender a solicitação do chamado 2817    
	DEFINE CELL NAME "D1_TIPO"      OF oSecEntr_2 ALIAS "SD1"  TITLE "Tipo"       // Vladimir - 05/01/15 - Incluído coluna           
	DEFINE CELL NAME "FORNECEDOR"   OF oSecEntr_2 ALIAS "SA2"  TITLE "Fornecedor"    SIZE 20 BLOCK{|| QRY2->a2_cod + '-' + QRY2->a2_loja}    
	DEFINE CELL NAME "A2_NOME"      OF oSecEntr_2 ALIAS "SA2"  TITLE "Razao Social"  SIZE 40
	DEFINE CELL NAME "A2_NREDUZ"    OF oSecEntr_2 ALIAS "SA2"  TITLE "Nome Fantasia" SIZE 30
	DEFINE CELL NAME "A2_CGC"       OF oSecEntr_2 ALIAS "SA2"  TITLE "CNPJ"          SIZE 20 PICTURE "@R! NN.NNN.NNN/NNNN-99"
	DEFINE CELL NAME "A2_EST"       OF oSecEntr_2 ALIAS "SA2"  TITLE "Estado" 
	DEFINE CELL NAME "A2_MUN"       OF oSecEntr_2 ALIAS "SA2"  TITLE "Municipio"     SIZE 30

	oSecEntr_2:Disable()

	DEFINE Section oSecDado_2 OF oSecEntr_2 TITLE "1-Fornecedor Analitico" TABLES "SD1","SB1"

	DEFINE CELL NAME "D1_ITEM"      OF oSecDado_2 ALIAS "SD1" TITLE "Item"                 SIZE 08 //19/02/13 - Talita - Aumentado o tamanho de separação entre o item e o cod do produto
	DEFINE CELL NAME "B1_COD"       OF oSecDado_2 ALIAS "SB1" TITLE "Produto"              SIZE 20
	DEFINE CELL NAME "B1_DESC"	    OF oSecDado_2 ALIAS "SB1" TITLE "Descricao"            SIZE 40
	DEFINE CELL NAME "D1_QUANT"     OF oSecDado_2 ALIAS "SD1" TITLE "Quantidade"           SIZE 25 PICTURE "@E 99,999,999,999.99"
	DEFINE CELL NAME "D1_UM"        OF oSecDado_2 ALIAS "SD1" TITLE "UM"                   SIZE 07
	DEFINE CELL NAME "D1_VUNIT"     OF oSecDado_2 ALIAS "SD1" TITLE "Vlr.Unit."            SIZE 25 PICTURE "@E 99,999,999,999.99"
	DEFINE CELL NAME "D1_TOTAL"     OF oSecDado_2 ALIAS "SD1" TITLE "Vlr.Total"            SIZE 25 PICTURE "@E 99,999,999,999.99"  
	DEFINE CELL NAME "D1_PICM"      OF oSecDado_2 ALIAS "SD1" TITLE "Aliq.ICMS"            SIZE 25 PICTURE "@E 99,999,999,999.99"
	DEFINE CELL NAME "D1_VALICM"    OF oSecDado_2 ALIAS "SD1" TITLE "Valor ICMS"           SIZE 25 PICTURE "@E 99,999,999,999.99"
	DEFINE CELL NAME "D1_BASEIRR"   OF oSecDado_2 ALIAS "SD1" TITLE "Base IRR"             SIZE 25 PICTURE "@E 99,999,999,999.99"//Talita - 08/02/13 - Incluido os campos D1_BASEIRR, D1_ALIQIRR e D1_VALIRR conforme Help: 1774
	DEFINE CELL NAME "D1_ALIQIRR"   OF oSecDado_2 ALIAS "SD1" TITLE "Aliq. IRR"            SIZE 25 PICTURE "@E 99,999,999,999.99"
	DEFINE CELL NAME "D1_VALIRR"    OF oSecDado_2 ALIAS "SD1" TITLE "Valor IRR"            SIZE 25 PICTURE "@E 99,999,999,999.99"

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
	oSecDado_2:Cell( "D1_BASEIRR" ):SetHeaderAlign("RIGHT") //Talita - 08/02/13 - Incluido os campos D1_BASEIRR, D1_ALIQIRR e D1_VALIRR conforme Help: 1774
	oSecDado_2:Cell( "D1_ALIQIRR" ):SetHeaderAlign("RIGHT")
	oSecDado_2:Cell( "D1_VALIRR"  ):SetHeaderAlign("RIGHT")

	oSecDado_2:SetTotalInLine(.F.)
	oSecDado_2:OnPrintLine({|| _cNumNF :=QRY2->D1_doc + '-' + QRY2->D1_serie, _cNomeForn:=QRY2->a2_nreduz })             

	//====================================================================================================
	// Define secoes Por Data de Entrada - Sintetico
	//====================================================================================================
	DEFINE Section oSecEntr_3		OF oReport					TITLE "Entrada_ordem_3" TABLES "SD1" ORDERS _aOrd
	DEFINE CELL NAME "D1_DTDIGIT"	OF oSecEntr_3 ALIAS "SD1"	TITLE "Data Entrada"  

	oSecEntr_3:Disable()

	DEFINE Section oSecDado_3 OF oSecEntr_3 TITLE "2-Data Entrada Sintetico" TABLES "SD1","SA2"

	DEFINE CELL NAME "NOTAFISCAL"   OF oSecDado_3 ALIAS "SD1" TITLE "Nota Fiscal"      	   SIZE 23 BLOCK{|| QRY3->D1_doc + '-' + QRY3->D1_serie}  //08/03/13 - Talita - Alterado o tamanho do campo para atender a solicitação do chamado 2817   
	DEFINE CELL NAME "D1_TIPO"      OF oSecDado_3 ALIAS "SD1" TITLE "Tipo"                 SIZE 07
	DEFINE CELL NAME "FORNECEDOR"   OF oSecDado_3 ALIAS "SA2" TITLE "Fornecedor"           SIZE 20 BLOCK{|| QRY3->a2_cod + '-' + QRY3->a2_loja}    
	DEFINE CELL NAME "A2_NOME"      OF oSecDado_3 ALIAS "SA2" TITLE "Razao Social"         SIZE 40
	DEFINE CELL NAME "A2_EST"       OF oSecDado_3 ALIAS "SA2" TITLE "Estado"               SIZE 05
	DEFINE CELL NAME "D1_TOTAL"     OF oSecDado_3 ALIAS "SD1" TITLE "Vlr.Mercadoria"       SIZE 25 PICTURE "@E 99,999,999,999.99"
	DEFINE CELL NAME "D1_BASEICM"   OF oSecDado_3 ALIAS "SD1" TITLE "Base ICMS"            SIZE 25 PICTURE "@E 99,999,999,999.99"
	DEFINE CELL NAME "D1_VALICM"    OF oSecDado_3 ALIAS "SD1" TITLE "Valor ICMS"           SIZE 25 PICTURE "@E 99,999,999,999.99" 
	DEFINE CELL NAME "D1_BASEIRR"   OF oSecDado_3 ALIAS "SD1" TITLE "Base IRR"             SIZE 25 PICTURE "@E 99,999,999,999.99"//Talita - 08/02/13 - Incluido os campos D1_BASEIRR, D1_ALIQIRR e D1_VALIRR conforme Help: 1774
	DEFINE CELL NAME "D1_ALIQIRR"   OF oSecDado_3 ALIAS "SD1" TITLE "Aliq. IRR"            SIZE 25 PICTURE "@E 99,999,999,999.99"
	DEFINE CELL NAME "D1_VALIRR"    OF oSecDado_3 ALIAS "SD1" TITLE "Valor IRR"            SIZE 25 PICTURE "@E 99,999,999,999.99"

	//====================================================================================================
	// Desabilita Secao e configura salto em numero de linhas para a proxima secao
	//====================================================================================================
	oSecDado_3:Disable()
	oSecEntr_3:SetLinesBefore(5)

	//====================================================================================================
	// Alinhamento de cabecalho
	//====================================================================================================
	oSecDado_3:Cell( "D1_TOTAL"   ):SetHeaderAlign("RIGHT")
	oSecDado_3:Cell( "D1_BASEICM" ):SetHeaderAlign("RIGHT")
	oSecDado_3:Cell( "D1_VALICM"  ):SetHeaderAlign("RIGHT")
	oSecDado_3:Cell( "D1_BASEIRR" ):SetHeaderAlign("RIGHT") //Talita - 08/02/13 - Incluido os campos D1_BASEIRR, D1_ALIQIRR e D1_VALIRR conforme Help: 1774
	oSecDado_3:Cell( "D1_ALIQIRR" ):SetHeaderAlign("RIGHT")
	oSecDado_3:Cell( "D1_VALIRR"  ):SetHeaderAlign("RIGHT")

	oSecDado_3:SetTotalInLine(.F.)
	oSecDado_3:OnPrintLine( {|| _cDataEnt := QRY3->D1_DTDIGIT } )

	//====================================================================================================
	// Define secoes para segunda ordem - Por Data de Entrada - Analitico
	//====================================================================================================
	DEFINE Section oSecCabe_4		OF oReport					TITLE "Entrada_ordem_4" TABLES "SD1" ORDERS _aOrd
	DEFINE CELL NAME "D1_DTDIGIT"	OF oSecCabe_4 ALIAS "SD1"	TITLE "Data de Entrada"

	oSecCabe_4:Disable()

	//====================================================================================================
	// Secao dados da Rede
	//====================================================================================================
	DEFINE Section oSecEntr_4		OF oSecCabe_4				TITLE "Entrada_ordem_4" TABLES "SA2","SF1","SD1" ORDERS _aOrd
		
	DEFINE CELL NAME "NOTAFISCAL"	OF oSecEntr_4 ALIAS "SD1"	TITLE "Nota Fiscal"		SIZE 23 BLOCK{|| AllTrim(QRY4->D1_doc) +'-'+ AllTrim(QRY4->D1_serie) }  //08/03/13 - Talita - Alterado o tamanho do campo para atender a solicitação do chamado 2817
	DEFINE CELL NAME "D1_EMISSAO"	OF oSecEntr_4 ALIAS "SD1"	TITLE "Emissao"			SIZE 14
	DEFINE CELL NAME "F1_TIPO"		OF oSecEntr_4 ALIAS "SF1"	TITLE "Tipo"			SIZE 08
	DEFINE CELL NAME "FORNECEDOR"	OF oSecEntr_4 ALIAS "SA2"	TITLE "Fornecedor"		SIZE 20 BLOCK{|| QRY4->a2_cod + '-' + QRY4->a2_loja }
	DEFINE CELL NAME "A2_NOME"		OF oSecEntr_4 ALIAS "SA2"	TITLE "Razao Social"	SIZE 40
	DEFINE CELL NAME "A2_EST"       OF oSecEntr_4 ALIAS "SA2"	TITLE "Estado"			SIZE 10
	DEFINE CELL NAME "F1_VALMERC"   OF oSecEntr_4 ALIAS "SF1"	TITLE "Vlr.Mercadoria"	SIZE 25 PICTURE "@E 99,999,999,999.99"
	DEFINE CELL NAME "F1_VALBRUT"   OF oSecEntr_4 ALIAS "SF1"	TITLE "Vlr.Bruto"		SIZE 25 PICTURE "@E 99,999,999,999.99"
	DEFINE CELL NAME "F1_BASEICM"   OF oSecEntr_4 ALIAS "SF1"	TITLE "Base ICMS"		SIZE 25 PICTURE "@E 99,999,999,999.99"
	DEFINE CELL NAME "F1_VALICM"    OF oSecEntr_4 ALIAS "SF1"	TITLE "Vlr.ICMS"		SIZE 25 PICTURE "@E 99,999,999,999.99"

	oSecEntr_4:Disable()
	oSecEntr_4:OnPrintLine( {|| _cDataEnt := QRY4->D1_DTDIGIT } ) 

	//====================================================================================================
	// Alinhamento de cabecalho
	//====================================================================================================
	oSecEntr_4:Cell( "F1_VALMERC" ):SetHeaderAlign("RIGHT")
	oSecEntr_4:Cell( "F1_VALBRUT" ):SetHeaderAlign("RIGHT")
	oSecEntr_4:Cell( "F1_BASEICM" ):SetHeaderAlign("RIGHT")
	oSecEntr_4:Cell( "F1_VALICM"  ):SetHeaderAlign("RIGHT")

	DEFINE Section oSecDado_4		OF oSecEntr_4				TITLE "2-Data Entrada Analitico"	TABLES "SD1","SB1"

	DEFINE CELL NAME "D1_ITEM"      OF oSecDado_4 ALIAS "SD1"	TITLE "Item"			SIZE 08
	DEFINE CELL NAME "B1_COD"       OF oSecDado_4 ALIAS "SB1"	TITLE "Produto"			SIZE 20
	DEFINE CELL NAME "B1_DESC"	    OF oSecDado_4 ALIAS "SB1"	TITLE "Descricao"		SIZE 40
	DEFINE CELL NAME "D1_QUANT"     OF oSecDado_4 ALIAS "SD1"	TITLE "Quantidade"		SIZE 25 PICTURE "@E 99,999,999,999.99"
	DEFINE CELL NAME "D1_UM"        OF oSecDado_4 ALIAS "SD1"	TITLE "UM"				SIZE 07
	DEFINE CELL NAME "D1_VUNIT"     OF oSecDado_4 ALIAS "SD1"	TITLE "Vlr.Unit."		SIZE 25 PICTURE "@E 99,999,999,999.99"
	DEFINE CELL NAME "D1_TOTAL"     OF oSecDado_4 ALIAS "SD1"	TITLE "Vlr.Total"		SIZE 25 PICTURE "@E 99,999,999,999.99"
	DEFINE CELL NAME "D1_PICM"      OF oSecDado_4 ALIAS "SD1"	TITLE "Aliq.ICMS"		SIZE 25 PICTURE "@E 99,999,999,999.99"
	DEFINE CELL NAME "D1_VALICM"    OF oSecDado_4 ALIAS "SD1"	TITLE "Valor ICMS"		SIZE 25 PICTURE "@E 99,999,999,999.99"
	DEFINE CELL NAME "D1_BASEIRR"   OF oSecDado_4 ALIAS "SD1"	TITLE "Base IRR"		SIZE 25 PICTURE "@E 99,999,999,999.99" //Talita - 08/02/13 - Incluido os campos D1_BASEIRR, D1_ALIQIRR e D1_VALIRR conforme Help: 1774
	DEFINE CELL NAME "D1_ALIQIRR"   OF oSecDado_4 ALIAS "SD1"	TITLE "Aliq. IRR"		SIZE 25 PICTURE "@E 99,999,999,999.99"
	DEFINE CELL NAME "D1_VALIRR"    OF oSecDado_4 ALIAS "SD1"	TITLE "Valor IRR"		SIZE 25 PICTURE "@E 99,999,999,999.99"

	//====================================================================================================
	// Desabilita Secao e Salta numero de linhas para a proxima secao
	//====================================================================================================
	oSecDado_4:Disable()          
	oSecCabe_4:SetLinesBefore(5)
	oSecEntr_4:SetLinesBefore(3)

	//====================================================================================================
	// Alinhamento de cabecalho
	//====================================================================================================
	oSecDado_4:Cell( "D1_QUANT"   ):SetHeaderAlign("RIGHT")
	oSecDado_4:Cell( "D1_VUNIT"   ):SetHeaderAlign("RIGHT")
	oSecDado_4:Cell( "D1_TOTAL"   ):SetHeaderAlign("RIGHT")
	oSecDado_4:Cell( "D1_PICM"    ):SetHeaderAlign("RIGHT")
	oSecDado_4:Cell( "D1_VALICM"  ):SetHeaderAlign("RIGHT")
	oSecDado_4:Cell( "D1_BASEIRR" ):SetHeaderAlign("RIGHT") //Talita - 08/02/13 - Incluido os campos D1_BASEIRR, D1_ALIQIRR e D1_VALIRR conforme Help: 1774
	oSecDado_4:Cell( "D1_ALIQIRR" ):SetHeaderAlign("RIGHT")
	oSecDado_4:Cell( "D1_VALIRR"  ):SetHeaderAlign("RIGHT")

	oSecDado_4:SetTotalInLine(.F.)
	oSecDado_4:OnPrintLine( {|| _cNumNF := QRY4->D1_doc + '-' + QRY4->D1_serie + '-' + QRY4->D1_filial + '-' + QRY4->a2_cod + '-' + QRY4->a2_loja } )

	//====================================================================================================
	// Define secoes Por Produto - Sintetico
	//====================================================================================================
	DEFINE Section oSecEntr_5		OF oReport TITLE "3-Produto Sintetico" TABLES "SD1","SB1"

	DEFINE CELL NAME "B1_COD"		OF oSecEntr_5 ALIAS "SB1" TITLE "Codigo" 			 SIZE 20
	DEFINE CELL NAME "B1_DESC"		OF oSecEntr_5 ALIAS "SB1" TITLE "Descricao"          SIZE 40
	DEFINE CELL NAME "D1_QUANT"		OF oSecEntr_5 ALIAS "SD1" TITLE "Quant. 1a.U.M."     SIZE 25 PICTURE "@E 99,999,999,999.99"
	DEFINE CELL NAME "D1_UM"        OF oSecEntr_5 ALIAS "SD1" TITLE "1a.U.M."            SIZE 10                                   
	DEFINE CELL NAME "D1_QTSEGUM"   OF oSecEntr_5 ALIAS "SD1" TITLE "Quant. 2a.U.M."     SIZE 25 PICTURE "@E 99,999,999,999.99"
	DEFINE CELL NAME "D1_SEGUM"     OF oSecEntr_5 ALIAS "SD1" TITLE "2a.U.M."            SIZE 10
	DEFINE CELL NAME "D1_TOTAL"     OF oSecEntr_5 ALIAS "SD1" TITLE "Vlr.Mercadoria"     SIZE 25 PICTURE "@E 99,999,999,999.99"
	DEFINE CELL NAME "D1_BASEICM"   OF oSecEntr_5 ALIAS "SD1" TITLE "Base ICMS"          SIZE 25 PICTURE "@E 99,999,999,999.99"
	DEFINE CELL NAME "D1_VALICM"    OF oSecEntr_5 ALIAS "SD1" TITLE "Valor ICMS"         SIZE 25 PICTURE "@E 99,999,999,999.99"
	DEFINE CELL NAME "D1_BASEIRR"   OF oSecEntr_5 ALIAS "SD1" TITLE "Base IRR"           SIZE 25 PICTURE "@E 99,999,999,999.99" //Talita - 08/02/13 - Incluido os campos D1_BASEIRR, D1_ALIQIRR e D1_VALIRR conforme Help: 1774
	DEFINE CELL NAME "D1_ALIQIRR"   OF oSecEntr_5 ALIAS "SD1" TITLE "Aliq. IRR"          SIZE 25 PICTURE "@E 99,999,999,999.99"
	DEFINE CELL NAME "D1_VALIRR"    OF oSecEntr_5 ALIAS "SD1" TITLE "Valor IRR"          SIZE 25 PICTURE "@E 99,999,999,999.99"

	//====================================================================================================
	// Desabilita Secao e Salta numero de linhas para a proxima secao
	//====================================================================================================
	oSecEntr_5:Disable()
	oSecEntr_5:SetLinesBefore(5)

	//====================================================================================================
	// Alinhamento de cabecalho
	//====================================================================================================
	oSecEntr_5:Cell( "D1_QUANT"   ):SetHeaderAlign("RIGHT")
	oSecEntr_5:Cell( "D1_QTSEGUM" ):SetHeaderAlign("RIGHT")
	oSecEntr_5:Cell( "D1_TOTAL"   ):SetHeaderAlign("RIGHT")
	oSecEntr_5:Cell( "D1_BASEICM" ):SetHeaderAlign("RIGHT")
	oSecEntr_5:Cell( "D1_VALICM"  ):SetHeaderAlign("RIGHT")
	oSecEntr_5:Cell( "D1_BASEIRR" ):SetHeaderAlign("RIGHT") //Talita - 08/02/13 - Incluido os campos D1_BASEIRR, D1_ALIQIRR e D1_VALIRR conforme Help: 1774
	oSecEntr_5:Cell( "D1_ALIQIRR" ):SetHeaderAlign("RIGHT")
	oSecEntr_5:Cell( "D1_VALIRR"  ):SetHeaderAlign("RIGHT")

	oSecEntr_5:SetTotalInLine(.F.)

	//====================================================================================================
	// Define secoes Por CFOp
	//====================================================================================================
	DEFINE Section oSecEntr_6		OF oReport					TITLE "Entrada_ordem_6" TABLES "SD1" ORDERS _aOrd

	DEFINE CELL NAME "D1_FILIAL"   OF oSecEntr_6 ALIAS "SD1"	TITLE "FILIAL"  BLOCK{|| QRY6->D1_FILIAL } 
	DEFINE CELL NAME "CFOP"        OF oSecEntr_6 ALIAS "SD1"	TITLE "CFOP"    SIZE 50 BLOCK{|| AllTrim(QRY6->D1_cf) + '-' + ROMS007D(QRY6->D1_cf)} 

	oSecEntr_6:Disable()

	//====================================================================================================
	// Secao dados CFOP
	//====================================================================================================
	DEFINE Section oSecDado_6		OF oSecEntr_6				TITLE "4-CFOP Analitico" TABLES "SF1","SD1","SA2","SC7","ZZI","SB1","CTT","QRY6"
		
	DEFINE CELL NAME "F1_DTDIGIT"   OF oSecDado_6 ALIAS "SF1"	TITLE "Data Digit"           SIZE 12     
	DEFINE CELL NAME "NOTAFISCAL"   OF oSecDado_6 ALIAS "SF1"	TITLE "Nota Fiscal"          SIZE 23 BLOCK{|| QRY6->f1_doc + '-' + QRY6->f1_serie} //08/03/13 - Talita - Alterado o tamanho do campo para atender a solicitação do chamado 2817
	DEFINE CELL NAME "F1_TIPO"      OF oSecDado_6 ALIAS "SF1"	TITLE "Tipo"                 SIZE 07
	DEFINE CELL NAME "FORNECEDOR"   OF oSecDado_6 ALIAS "SF1"	TITLE "Fornecedor"           SIZE 20 BLOCK{|| QRY6->f1_fornece + '-' + QRY6->f1_loja}    
	DEFINE CELL NAME "A2_NOME"      OF oSecDado_6 ALIAS "SA2"	TITLE "Razao Social"         SIZE 40
	DEFINE CELL NAME "A2_EST"       OF oSecDado_6 ALIAS "SA2"	TITLE "Estado"               SIZE 05
	DEFINE CELL NAME "D1_TOTAL"     OF oSecDado_6 ALIAS "SD1"	TITLE "Valor"                SIZE 25 PICTURE "@E 99,999,999,999.99"
	DEFINE CELL NAME "F1_BASEICM"   OF oSecDado_6 ALIAS "SF1"	TITLE "Base ICMS"            SIZE 25 PICTURE "@E 99,999,999,999.99"
	DEFINE CELL NAME "F1_VALICM"    OF oSecDado_6 ALIAS "SF1"	TITLE "Valor ICMS"           SIZE 25 PICTURE "@E 99,999,999,999.99"
	DEFINE CELL NAME "D1_BASEIRR"   OF oSecDado_6 ALIAS "SD1"	TITLE "Base IRR"             SIZE 25 PICTURE "@E 99,999,999,999.99"//Talita - 08/02/13 - Incluido os campos D1_BASEIRR, D1_ALIQIRR e D1_VALIRR conforme Help: 1774
	DEFINE CELL NAME "D1_ALIQIRR"   OF oSecDado_6 ALIAS "SD1"	TITLE "Aliq. IRR"            SIZE 25 PICTURE "@E 99,999,999,999.99"
	DEFINE CELL NAME "D1_VALIRR"    OF oSecDado_6 ALIAS "SD1"	TITLE "Valor IRR"            SIZE 25 PICTURE "@E 99,999,999,999.99"
	DEFINE CELL NAME "C7_NUM"       OF oSecDado_6 ALIAS "SC7"	TITLE "PEDIDO"               SIZE 7
	DEFINE CELL NAME "C7_I_APLIC"   OF oSecDado_6 ALIAS "SC7"	TITLE "Aplc."                SIZE 6
	DEFINE CELL NAME "D1_ITEMPC"    OF oSecDado_6 ALIAS "SC7"	TITLE "ItemPC."              SIZE 6
	DEFINE CELL NAME "C7_I_CDINV"   OF oSecDado_6 ALIAS "SC7"	TITLE "Projeto"              SIZE 6            
	DEFINE CELL NAME "ZZI_DESENV"   OF oSecDado_6 ALIAS "ZZI"	TITLE "Descr.Prj"            SIZE 40 BLOCK{|| QRY6->ZZI_DESINV }     
	DEFINE CELL NAME "B1_COD"		OF oSecDado_6 ALIAS "SB1"   TITLE "Codigo" 			 	 SIZE 20
	DEFINE CELL NAME "B1_DESC"		OF oSecDado_6 ALIAS "SB1"   TITLE "Descricao"          	 SIZE 40
	DEFINE CELL NAME "D1_QUANT"	    OF oSecDado_6 ALIAS "SD1"   TITLE "Quant. 1a.U.M."     	 SIZE 25 PICTURE "@E 99,999,999,999.99"
	DEFINE CELL NAME "D1_UM"        OF oSecDado_6 ALIAS "SD1"   TITLE "1a.U.M."            	 SIZE 10                                   
	DEFINE CELL NAME "D1_QTSEGUM"   OF oSecDado_6 ALIAS "SD1"   TITLE "Quant. 2a.U.M."     	 SIZE 25 PICTURE "@E 99,999,999,999.99"
	DEFINE CELL NAME "D1_SEGUM"     OF oSecDado_6 ALIAS "SD1"   TITLE "2a.U.M."            	 SIZE 10
	DEFINE CELL NAME "C7_OBS"       OF oSecDado_6 ALIAS "SC7"   TITLE "Obs Pedido"     		 SIZE 40
	DEFINE CELL NAME "D1_CC"      	OF oSecDado_6 ALIAS "QRY6" 	TITLE "C.Custo"    			 SIZE 10 BLOCK {|| QRY6->D1_CC }
	DEFINE CELL NAME "CTT_DESC01" 	OF oSecDado_6 ALIAS "QRY6" 	TITLE "Desc. C.C."			 SIZE 40 BLOCK {|| QRY6->CTT_DESC01 }   

	//====================================================================================================
	// Desabilita Secao e Salta numero de linhas para a proxima secao
	//====================================================================================================
	oSecDado_6:Disable()
	oSecEntr_6:SetLinesBefore(5)

	//====================================================================================================
	// Alinhamento de cabecalho
	//====================================================================================================
	oSecDado_6:Cell( "D1_TOTAL" ):SetHeaderAlign("RIGHT")
	oSecDado_6:Cell( "F1_BASEICM" ):SetHeaderAlign("RIGHT")
	oSecDado_6:Cell( "F1_VALICM"  ):SetHeaderAlign("RIGHT")
	oSecDado_6:Cell( "D1_BASEIRR" ):SetHeaderAlign("RIGHT")
	oSecDado_6:Cell( "D1_ALIQIRR" ):SetHeaderAlign("RIGHT")
	oSecDado_6:Cell( "D1_VALIRR"  ):SetHeaderAlign("RIGHT")

	oSecDado_6:SetTotalInLine(.F.)
	oSecDado_6:OnPrintLine( {|| _cCFOP := QRY6->D1_FILIAL + " " + QRY6->D1_CF } )

	//====================================================================================================
	// Define secoes Por Fornecedor x Produto
	//====================================================================================================
	DEFINE Section oSecForn_7		OF oReport					TITLE "Fornecedor" TABLES "SA2" ORDERS _aOrd

	DEFINE CELL NAME "FORNECEDOR"   OF oSecForn_7 ALIAS "SA2"	TITLE "Fornecedor"    SIZE 20 BLOCK{|| QRY7->a2_cod + '-' + QRY7->a2_loja}    
	DEFINE CELL NAME "A2_NOME"      OF oSecForn_7 ALIAS "SA2"	TITLE "Razao Social"  SIZE 40
	DEFINE CELL NAME "A2_NREDUZ"    OF oSecForn_7 ALIAS "SA2"	TITLE "Nome Fantasia" SIZE 30
	DEFINE CELL NAME "A2_CGC"       OF oSecForn_7 ALIAS "SA2"	TITLE "CNPJ"          SIZE 20 PICTURE "@R! NN.NNN.NNN/NNNN-99"
	DEFINE CELL NAME "A2_EST"       OF oSecForn_7 ALIAS "SA2"	TITLE "Estado" 
	DEFINE CELL NAME "A2_MUN"       OF oSecForn_7 ALIAS "SA2"	TITLE "Municipio"     SIZE 30

	//====================================================================================================
	// Desabilita seção e Salta numero de linhas para a proxima secao
	//====================================================================================================
	oSecForn_7:Disable()
	oSecForn_7:SetLinesBefore(5)

	DEFINE Section oSecProd_7		OF oSecForn_7				TITLE "Produto" TABLES "SB1"
	DEFINE CELL NAME "PRODUTO"		OF oSecProd_7 ALIAS "SB1"	TITLE "Produto"       SIZE 50 BLOCK{|| AllTrim(QRY7->B1_COD) + '-' + AllTrim(QRY7->B1_DESC) } 

	oSecProd_7:Disable()
	oSecProd_7:SetLinesBefore(3) 

	DEFINE Section oSecDado_7		OF oSecProd_7				TITLE "5-Forn. x Prod. Analitico" TABLES "SD1"

	DEFINE CELL NAME "D1_DTDIGIT"	OF oSecDado_7 ALIAS "SD1"	TITLE "Data Entrada"         
	DEFINE CELL NAME "NOTAFISCAL"   OF oSecDado_7 ALIAS "SD1"	TITLE "Nota Fiscal"        SIZE 23 BLOCK{|| QRY7->D1_doc + '-' + QRY7->D1_serie}  //08/03/13 - Talita - Alterado o tamanho do campo para atender a solicitação do chamado 2817  
	DEFINE CELL NAME "D1_TIPO"      OF oSecDado_7 ALIAS "SD1"	TITLE "Tipo"     
	DEFINE CELL NAME "D1_QUANT"     OF oSecDado_7 ALIAS "SD1"	TITLE "Quantidade"         SIZE 25 PICTURE "@E 99,999,999,999.99"
	DEFINE CELL NAME "D1_UM"        OF oSecDado_7 ALIAS "SD1"	TITLE "1a.U.M."            SIZE 10                     
	DEFINE CELL NAME "D1_TOTAL"     OF oSecDado_7 ALIAS "SD1"	TITLE "Vlr.Mercadoria"     SIZE 25 PICTURE "@E 99,999,999,999.99"
	DEFINE CELL NAME "D1_BASEICM"   OF oSecDado_7 ALIAS "SD1"	TITLE "Base ICMS"          SIZE 25 PICTURE "@E 99,999,999,999.99"
	DEFINE CELL NAME "D1_VALICM"    OF oSecDado_7 ALIAS "SD1"	TITLE "Valor ICMS"         SIZE 25 PICTURE "@E 99,999,999,999.99"
	DEFINE CELL NAME "D1_BASEIRR"   OF oSecDado_7 ALIAS "SD1"	TITLE "Base IRR"           SIZE 25 PICTURE "@E 99,999,999,999.99" //Talita - 08/02/13 - Incluido os campos D1_BASEIRR, D1_ALIQIRR e D1_VALIRR conforme Help: 1774
	DEFINE CELL NAME "D1_ALIQIRR"   OF oSecDado_7 ALIAS "SD1"	TITLE "Aliq. IRR"          SIZE 25 PICTURE "@E 99,999,999,999.99"
	DEFINE CELL NAME "D1_VALIRR"    OF oSecDado_7 ALIAS "SD1"	TITLE "Valor IRR"          SIZE 25 PICTURE "@E 99,999,999,999.99"

	//====================================================================================================
	// Desabilita Secao
	//====================================================================================================
	oSecDado_7:Disable()          

	//====================================================================================================
	// Alinhamento de cabecalho
	//====================================================================================================
	oSecDado_7:Cell( "D1_QUANT"   ):SetHeaderAlign("RIGHT")
	oSecDado_7:Cell( "D1_TOTAL"   ):SetHeaderAlign("RIGHT")
	oSecDado_7:Cell( "D1_BASEICM" ):SetHeaderAlign("RIGHT")
	oSecDado_7:Cell( "D1_VALICM"  ):SetHeaderAlign("RIGHT")
	oSecDado_7:Cell( "D1_BASEIRR" ):SetHeaderAlign("RIGHT") //Talita - 08/02/13 - Incluido os campos D1_BASEIRR, D1_ALIQIRR e D1_VALIRR conforme Help: 1774
	oSecDado_7:Cell( "D1_ALIQIRR" ):SetHeaderAlign("RIGHT")
	oSecDado_7:Cell( "D1_VALIRR"  ):SetHeaderAlign("RIGHT")

	oSecDado_7:SetTotalInLine(.F.)
	oSecDado_7:OnPrintLine( {|| _cNomeForn := QRY7->A2_COD +'-'+ QRY7->A2_LOJA +' - '+ AllTrim(QRY7->A2_NREDUZ) +' - '+ QRY7->A2_EST , _cNomeProd := AllTrim(QRY7->B1_COD) +'-'+ AllTrim(QRY7->B1_DESC) } )

	oReport:PrintDialog()

Return

/*
===============================================================================================================================
Programa----------: RCOM007PR
Autor-------------: Fabiano Dias Silva
Data da Criacao---: 05/03/2010
Descrição---------: Executa relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RCOM007PR( oReport )

	Local 	_cFiltro  	:= "% "
	Local 	_cFiltro2	:= "% "    
	Private _nOrdem  	:= oSecEntr_1:GetOrder() //Busca ordem selecionada pelo usuario   

	oReport:SetTitle( "Relação - N.F's de Entrada - Orderm "+ _aOrd[_nOrdem] + IIf(_nOrdem == 1 .Or. _nOrdem == 2 , " (" + IIf(MV_PAR18 == 1,"ANALITICO","SINTETICO") + ")","") + " - Entrada de " + DToC(MV_PAR02) + " até "  + DToC(MV_PAR03) )

	//====================================================================================================
	// Define o filtro de acordo com os parametros digitados
	//====================================================================================================
	If !Empty( MV_PAR01 )
		_cFiltro  += " AND D1.D1_FILIAL IN "+ FormatIn( MV_PAR01 , ";" )
	EndIf

	//====================================================================================================
	// Define o filtro de filial para A2 de acordo com boas práticas
	//====================================================================================================
	_cFiltro  += " AND A2.A2_FILIAL = '" + xFilial("SA2") + "' "

	//====================================================================================================
	// Filtra data de entrada
	//====================================================================================================
	If !Empty( MV_PAR02 ) .And. !Empty( MV_PAR03 )
		_cFiltro  += " AND D1.D1_DTDIGIT BETWEEN '"+ DToS( MV_PAR02 ) +"' AND '"+ DToS( MV_PAR03 ) +"' "
	EndIf

	//====================================================================================================
	// Filtra Produto
	//====================================================================================================
	If !Empty( MV_PAR04 ) .And. !Empty( MV_PAR05 )
		_cFiltro  += " AND D1.D1_COD BETWEEN '"+ MV_PAR04 +"' AND '"+ MV_PAR05 +"' "
	EndIf

	//====================================================================================================
	// Filtra Grupo do Produto
	//====================================================================================================
	If !Empty( MV_PAR13 )
		_cFiltro   += " AND D1.D1_GRUPO IN "+ FormatIn( MV_PAR13 , ";" )
	EndIf

	//====================================================================================================
	// Filtra Armazem
	//====================================================================================================
	If !Empty( MV_PAR14 )
		_cFiltro   += " AND D1.D1_Local IN "+ FormatIn( MV_PAR14 , ";" )
	EndIf

	//====================================================================================================
	// Filtra TES
	//====================================================================================================
	If !Empty( MV_PAR15 )
		_cFiltro   += " AND D1.D1_TES IN "+ FormatIn( MV_PAR15 , ";" )
	EndIf

	//====================================================================================================
	// Busca CFOPS de acordo com parametro definido por usuario
	//====================================================================================================
	If !Empty( MV_PAR16 )
		_cFiltro   += " AND D1.D1_CF IN "+ FormatIn( MV_PAR16 , ";" )
	EndIf

	//====================================================================================================
	// Gera Financeiro
	//====================================================================================================
	If MV_PAR17 == 1
		_cFiltro += " AND F4.F4_DUPLIC = 'S' "
	ElseIf MV_PAR17 == 2
		_cFiltro += " AND F4.F4_DUPLIC = 'N' "
	EndIf

	_cFiltro2 += SubStr( _cFiltro , 2 )

	//====================================================================================================
	// Filtra tipo do Fornecedor
	//====================================================================================================
	If !Empty( MV_PAR06 )
		_cFiltro  += " AND A2.A2_I_CLASS IN "+ FormatIn( MV_PAR06 , ";" )
	EndIf

	//====================================================================================================
	// Filtra Fornecedor
	//====================================================================================================
	If !Empty( MV_PAR07 ) .And. !Empty( MV_PAR09 )
		_cFiltro  += " AND A2.A2_COD BETWEEN '"+ MV_PAR07 +"' AND '"+ MV_PAR09 +"' "
		_cFiltro2 += " AND A1.A1_COD BETWEEN '"+ MV_PAR07 +"' AND '"+ MV_PAR09 +"' "
	EndIf

	//====================================================================================================
	// Filtra Loja do Fornecedor
	//====================================================================================================
	If !Empty( MV_PAR08 ) .And. !Empty( MV_PAR10 )
		_cFiltro  += " AND A2.A2_LOJA BETWEEN '"+ MV_PAR08 +"' AND '"+ MV_PAR10 +"' "
		_cFiltro2 += " AND A1.A1_LOJA BETWEEN '"+ MV_PAR08 +"' AND '"+ MV_PAR10 +"' "
	EndIf

	//====================================================================================================
	// Filtra Estado Fornecedor
	//====================================================================================================
	If !Empty( MV_PAR11 )
		_cFiltro  += " AND A2.A2_EST IN "+ FormatIn( MV_PAR11 , ";" )
		_cFiltro2 += " AND A1.A1_EST IN "+ FormatIn( MV_PAR11 , ";" )
	EndIf

	//====================================================================================================
	// Filtra Cod Municipio Fornecedor
	//====================================================================================================
	If !Empty( MV_PAR12 )
		_cFiltro  += " AND A2.A2_COD_MUN IN "+ FormatIn( MV_PAR12 , ";" )
		_cFiltro2 += " AND A1.A1_CODMUN  IN "+ FormatIn( MV_PAR12 , ";" )
	EndIf

	//====================================================================================================
	// Filtra Tipo de produto
	//====================================================================================================
	If !Empty( MV_PAR19 )
		_cFiltro  += " AND D1.D1_TP IN "+ FormatIn( MV_PAR19 , ";" )
	EndIf

	_cFiltro  += " %"
	_cFiltro2 += " %"

	//====================================================================================================
	// Primeira Ordem - Por Fornecedor
	//====================================================================================================
	If _nOrdem == 1                  
		
		//====================================================================================================
		// Sintetico
		//====================================================================================================
		If MV_PAR18 == 2
			
			oSecEntr_1:Enable()
			oSecDado_1:Enable()
			
			//====================================================================================================
			// Quebra por Rede
			//====================================================================================================
			oBrkEntr_1:= TRBreak():New(oSecDado_1,oSecEntr_1:CELL("fornecedor"),"Totais - Fornecedor: " + _cNomeForn,.F.)          
			oBrkEntr_1:SetTotalText( {|| "Totais - Fornecedor: " + _cNomeForn } )
			
			TRFunction():New( oSecDado_1:Cell( "D1_TOTAL"   ),NIL,"SUM",oBrkEntr_1,NIL,NIL,NIL,.F.,.T.)
			TRFunction():New( oSecDado_1:Cell( "D1_BASEICM" ),NIL,"SUM",oBrkEntr_1,NIL,NIL,NIL,.F.,.T.)
			TRFunction():New( oSecDado_1:Cell( "D1_VALICM"  ),NIL,"SUM",oBrkEntr_1,NIL,NIL,NIL,.F.,.T.)
			TRFunction():New( oSecDado_1:Cell( "D1_BASEIRR" ),NIL,"SUM",oBrkEntr_1,NIL,NIL,NIL,.F.,.T.) //Talita - 08/02/13 - Incluido os campos D1_BASEIRR, D1_ALIQIRR e D1_VALIRR conforme Help: 1774
			TRFunction():New( oSecDado_1:Cell( "D1_ALIQIRR" ),NIL,"SUM",oBrkEntr_1,NIL,NIL,NIL,.F.,.T.)
			TRFunction():New( oSecDado_1:Cell( "D1_VALIRR"  ),NIL,"SUM",oBrkEntr_1,NIL,NIL,NIL,.F.,.T.)
			
			//====================================================================================================
			// Executa query para consultar Dados
			//====================================================================================================
			BEGIN REPORT QUERY oSecEntr_1
			
				BeginSql alias "QRY1"
				
					SELECT 
						A2.A2_COD						, A2.A2_LOJA		, A2.A2_NOME		, A2.A2_NREDUZ		, A2.A2_CGC			, A2.A2_EST						,
						A2.A2_MUN						, D1.D1_DTDIGIT		, D1.D1_DOC			, D1.D1_SERIE		, D1.D1_TIPO		, SUM(D1.D1_TOTAL) D1_TOTAL		,
						SUM(D1.D1_BASEICM) D1_BASEICM	, SUM(D1.D1_VALICM) D1_VALICM			, SUM(D1_BASEIRR) D1_BASEIRR			, AVG(D1_ALIQIRR) D1_ALIQIRR	,
						SUM(D1_VALIRR) D1_VALIRR
					FROM %Table:SD1% D1
					JOIN %Table:SA2% A2 ON D1.D1_FORNECE = A2.A2_COD    AND D1.D1_LOJA = A2.A2_LOJA
					JOIN %Table:SF4% F4 ON D1.D1_FILIAL  = F4.F4_FILIAL AND D1.D1_TES  = F4.F4_CODIGO
					WHERE
						D1.%notDel%
					AND A2.%notDel%
					AND F4.%notDel%
					AND D1.D1_TIPO <> 'D'
					%exp:_cFiltro%
					GROUP BY A2.A2_COD,A2.A2_LOJA,A2.A2_NOME,A2.A2_NREDUZ,A2.A2_CGC,A2.A2_EST,A2.A2_MUN,D1.D1_DTDIGIT,D1.D1_DOC,D1.D1_SERIE,D1.D1_TIPO
					ORDER BY A2.A2_COD,A2.A2_LOJA,D1.D1_DTDIGIT,D1.D1_DOC
				
				EndSql
				
			END REPORT QUERY oSecEntr_1
			
			oSecDado_1:SetParentQuery()
			oSecDado_1:SetParentFilter( {|cParam| QRY1->A2_COD +  QRY1->A2_LOJA == cParam} , {|| QRY1->A2_COD +  QRY1->A2_LOJA } )
			oSecEntr_1:Print(.T.)
		
		//====================================================================================================
		// Analitico
		//====================================================================================================
		Else		                 
		
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
			TRFunction():New( oSecDado_2:Cell( "D1_VALIRR" ) , NIL , "SUM" , oBrkEntr_2 ,NIL,NIL,NIL,.F.,.F. )
			
			//====================================================================================================
			// Quebra por Fornecedor
			//====================================================================================================
			oBrkEnt2_2 := TRBreak():New( oReport , oSecEntr_2:CELL( "FORNECEDOR" ) , "Total Fornecedor: " + _cNomeForn , .F. )
			oBrkEnt2_2:SetTotalText( {|| "Total Fornecedor: " + _cNomeForn } )
			
			TRFunction():New( oSecDado_2:Cell( "D1_QUANT"  ) , NIL , "SUM" , oBrkEnt2_2 ,NIL,NIL,NIL,.F.,.T. )
			TRFunction():New( oSecDado_2:Cell( "D1_TOTAL"  ) , NIL , "SUM" , oBrkEnt2_2 ,NIL,NIL,NIL,.F.,.T. )
			TRFunction():New( oSecDado_2:Cell( "D1_VALICM" ) , NIL , "SUM" , oBrkEnt2_2 ,NIL,NIL,NIL,.F.,.T. )
			TRFunction():New( oSecDado_2:Cell( "D1_VALIRR" ) , NIL , "SUM" , oBrkEnt2_2 ,NIL,NIL,NIL,.F.,.T. )
			
			//====================================================================================================
			// Executa query para consultar Dados
			//====================================================================================================
			BEGIN REPORT QUERY oSecEntr_2
			
				BeginSql alias "QRY2"
				
					SELECT 
						A2.A2_COD		, A2.A2_LOJA		, A2.A2_NOME		, A2.A2_NREDUZ		, A2.A2_CGC		, A2.A2_EST		, A2.A2_MUN		, B1.B1_COD		,
						B1.B1_DESC		, D1.D1_DOC			, D1.D1_SERIE		, D1.D1_TIPO		, D1.D1_DTDIGIT	, D1.D1_ITEM	, D1.D1_QUANT	, D1.D1_UM		,
						D1.D1_VUNIT		, D1.D1_TOTAL		, D1.D1_PICM		, D1.D1_VALICM		, D1.D1_BASEIRR	, D1.D1_ALIQIRR	, D1.D1_VALIRR
					FROM %Table:SD1% D1
					JOIN %Table:SA2% A2 ON D1.D1_FORNECE = A2.A2_COD    AND D1.D1_LOJA = A2.A2_LOJA
					JOIN %Table:SF4% F4 ON D1.D1_FILIAL  = F4.F4_FILIAL AND D1.D1_TES  = F4.F4_CODIGO
					JOIN %Table:SB1% B1 ON D1.D1_COD     = B1.B1_COD
					WHERE
						D1.%notDel%    
					AND A2.%notDel%  
					AND F4.%notDel% 
					AND B1.%notDel%
					AND D1.D1_TIPO <> 'D'
					%exp:_cFiltro%       
					ORDER BY A2.A2_COD , A2.A2_LOJA , D1.D1_DTDIGIT , D1.D1_DOC , D1.D1_ITEM
					
				EndSql
				
			END REPORT QUERY oSecEntr_2
			
			oSecDado_2:SetParentQuery()
			oSecDado_2:SetParentFilter( {|cParam| QRY2->a2_cod +  QRY2->a2_loja + DToS(QRY2->D1_dtdigit) + QRY2->D1_doc + QRY2->D1_serie == cParam},{|| QRY2->a2_cod +  QRY2->a2_loja + DToS(QRY2->D1_dtdigit) + QRY2->D1_doc + QRY2->D1_serie } )
			oSecEntr_2:Print(.T.)
		
		EndIf

	//====================================================================================================	
	// Ordem por Data de Entrada
	//====================================================================================================
	ElseIf _nOrdem == 2        

		//====================================================================================================
		// Sintético
		//====================================================================================================
		If MV_PAR18 == 2   
			
			oSecEntr_3:Enable()
			oSecDado_3:Enable()      
			
			//====================================================================================================
			// Quebra por Rede
			//====================================================================================================
			oBrkEntr_3 := TRBreak():New( oSecDado_3 , oSecEntr_3:CELL("D1_DTDIGIT") , "TOTAL: "+ IIf( Type("_cDataEnt") == 'D', DToC(_cDataEnt) , "" ) , .F. )
			oBrkEntr_3:SetTotalText( {|| "TOTAL: "+ IIf( Type("_cDataEnt") == 'D' , DToC(_cDataEnt) , "" ) } )
			
			TRFunction():New( oSecDado_3:Cell( "D1_TOTAL"   ) , NIL , "SUM" , oBrkEntr_3 ,NIL,NIL,NIL,.F.,.T. )
			TRFunction():New( oSecDado_3:Cell( "D1_BASEICM" ) , NIL , "SUM" , oBrkEntr_3 ,NIL,NIL,NIL,.F.,.T. )
			TRFunction():New( oSecDado_3:Cell( "D1_VALICM"  ) , NIL , "SUM" , oBrkEntr_3 ,NIL,NIL,NIL,.F.,.T. )
			TRFunction():New( oSecDado_3:Cell( "D1_BASEIRR" ) , NIL , "SUM" , oBrkEntr_3 ,NIL,NIL,NIL,.F.,.T. ) //Talita - 08/02/13 - Incluido os campos D1_BASEIRR, D1_ALIQIRR e D1_VALIRR conforme Help: 1774
			TRFunction():New( oSecDado_3:Cell( "D1_ALIQIRR" ) , NIL , "SUM" , oBrkEntr_3 ,NIL,NIL,NIL,.F.,.T. )
			TRFunction():New( oSecDado_3:Cell( "D1_VALIRR"  ) , NIL , "SUM" , oBrkEntr_3 ,NIL,NIL,NIL,.F.,.T. )
			
			//====================================================================================================
			// Executa query para consultar Dados
			//====================================================================================================
			BEGIN REPORT QUERY oSecEntr_3
			
				BeginSql alias "QRY3"
				
					SELECT 
						A2.A2_COD		, A2.A2_LOJA		, A2.A2_NOME		, A2.A2_EST			, D1.D1_DTDIGIT		, D1.D1_DOC			, D1.D1_SERIE		, D1.D1_TIPO		,
						SUM(D1.D1_TOTAL) D1_TOTAL			, SUM(D1.D1_BASEICM) D1_BASEICM			, SUM(D1.D1_VALICM) D1_VALICM			, SUM(D1_BASEIRR) D1_BASEIRR			,
						AVG(D1.D1_ALIQIRR) D1_ALIQIRR		, SUM(D1.D1_VALIRR) D1_valirr
					FROM %Table:SD1% D1
					JOIN %Table:SA2% A2 ON D1.D1_FORNECE = A2.A2_COD    AND D1.D1_LOJA = A2.A2_LOJA
					JOIN %Table:SF4% F4 ON D1.D1_FILIAL  = F4.F4_FILIAL AND D1.D1_TES  = F4.F4_CODIGO
					WHERE 
						D1.%notDel%    
					AND A2.%notDel%  
					AND F4.%notDel% 
					AND D1.D1_TIPO <> 'D'
					%exp:_cFiltro%       
					GROUP BY A2.A2_COD , A2.A2_LOJA , A2.A2_NOME , A2.A2_EST , D1.D1_DTDIGIT , D1.D1_DOC , D1.D1_SERIE , D1.D1_TIPO
					ORDER BY D1.D1_DTDIGIT , A2.A2_COD , A2.A2_LOJA , D1.D1_DOC
					
				EndSql
				
			END REPORT QUERY oSecEntr_3
			
			oSecDado_3:SetParentQuery()
			oSecDado_3:SetParentFilter( {|cParam| QRY3->D1_DTDIGIT == cParam } , {|| QRY3->D1_DTDIGIT } )
			oSecEntr_3:Print(.T.)
		
		//====================================================================================================
		// Analitico
		//====================================================================================================
		Else
			
			oSecCabe_4:Enable()
			oSecEntr_4:Enable()      
			oSecDado_4:Enable()  
			
			//====================================================================================================
			// Quebra por Data de entrada
			//====================================================================================================
			oBrkEnt1_4 := TRBreak():New( oReport , oSecCabe_4:CELL("D1_DTDIGIT") , "TOTAL: "+ IIf(Type("_cDataEnt") == 'D' , DToC(_cDataEnt) , "" ) , .F. )
			oBrkEnt1_4:SetTotalText( {|| "TOTAL: "+ IIf( Type("_cDataEnt") == 'D' , DToC(_cDataEnt) , "" ) } )
			
			TRFunction():New( oSecEntr_4:Cell( "F1_VALMERC" ) , NIL , "SUM" , oBrkEnt1_4 ,NIL,NIL,NIL,.F.,.F. )
			TRFunction():New( oSecEntr_4:Cell( "F1_VALBRUT" ) , NIL , "SUM" , oBrkEnt1_4 ,NIL,NIL,NIL,.F.,.F. )
			TRFunction():New( oSecEntr_4:Cell( "F1_BASEICM" ) , NIL , "SUM" , oBrkEnt1_4 ,NIL,NIL,NIL,.F.,.F. )
			TRFunction():New( oSecEntr_4:Cell( "F1_VALICM"  ) , NIL , "SUM" , oBrkEnt1_4 ,NIL,NIL,NIL,.F.,.F. )
			
			//====================================================================================================
			// Quebra por Nota Fiscal
			//====================================================================================================
			oBrkEntr_4 := TRBreak():New( oSecDado_4 , oSecEntr_4:CELL("NOTAFISCAL") , "Total N.F.: "+ SubStr( _cNumNF , 1 , 13 ) , .F. )
			oBrkEntr_4:SetTotalText( {|| RCOM007IO(_cNumNF) , "Total N.F.: "+ SubStr( _cNumNF , 1 , 13 ) } )
			
			TRFunction():New( oSecDado_4:Cell( "D1_QUANT"  ) , NIL , "SUM" , oBrkEntr_4 ,NIL,NIL,NIL,.F.,.T. )
			TRFunction():New( oSecDado_4:Cell( "D1_TOTAL"  ) , NIL , "SUM" , oBrkEntr_4 ,NIL,NIL,NIL,.F.,.T. )
			TRFunction():New( oSecDado_4:Cell( "D1_VALICM" ) , NIL , "SUM" , oBrkEntr_4 ,NIL,NIL,NIL,.F.,.T. )
			TRFunction():New( oSecDado_4:Cell( "D1_VALIRR" ) , NIL , "SUM" , oBrkEntr_4 ,NIL,NIL,NIL,.F.,.T. )
			
			//====================================================================================================
			// Executa query para consultar Dados
			//====================================================================================================
			BEGIN REPORT QUERY oSecCabe_4
			
				BeginSql alias "QRY4"
				
					SELECT 
						A2.A2_COD		, A2.A2_LOJA		, A2.A2_NOME		, A2.A2_NREDUZ		, A2.A2_CGC			, A2.A2_EST			, A2.A2_MUN			, B1.B1_COD			,
						B1.B1_DESC		, D1.D1_DOC			, D1.D1_SERIE		, D1.D1_DTDIGIT		, D1.D1_ITEM		, D1.D1_QUANT		, D1.D1_UM			, D1.D1_VUNIT		,
						D1.D1_TOTAL		, D1.D1_PICM		, D1.D1_VALICM		, F1.F1_VALMERC		, F1.F1_VALBRUT		, F1.F1_BASEICM		, F1.F1_VALICM		, F1.F1_TIPO		,
						D1.D1_EMISSAO	, D1.D1_FILIAL		, D1.D1_BASEIRR		, D1.D1_ALIQIRR		, D1.D1_VALIRR
					FROM %Table:SD1% D1
					JOIN %Table:SF1% F1 ON D1.D1_DOC     = F1.F1_DOC    AND D1.D1_SERIE = F1.F1_SERIE  AND D1.D1_FORNECE = F1.F1_FORNECE AND D1.D1_LOJA = F1.F1_LOJA AND D1.D1_FILIAL = F1.F1_FILIAL
					JOIN %Table:SA2% A2 ON D1.D1_FORNECE = A2.A2_COD    AND D1.D1_LOJA  = A2.A2_LOJA
					JOIN %Table:SF4% F4 ON D1.D1_FILIAL  = F4.F4_FILIAL AND D1.D1_TES   = F4.F4_CODIGO
					JOIN %Table:SB1% B1 ON D1.D1_COD     = B1.B1_COD
					WHERE
						D1.%notDel%
					AND F1.%notDel%
					AND A2.%notDel%
					AND F4.%notDel%
					AND B1.%notDel%
					AND D1.D1_TIPO <> 'D'
					%exp:_cFiltro%
					ORDER BY D1.D1_DTDIGIT , A2.A2_COD , A2.A2_LOJA , D1.D1_DOC , D1.D1_SERIE , D1.D1_ITEM
					
				EndSql
				
			END REPORT QUERY oSecCabe_4
			
			oSecEntr_4:SetParentQuery()
			oSecEntr_4:SetParentFilter( {|cParam| DToS(QRY4->D1_DTDIGIT) == cParam } , {|| DToS( QRY4->D1_DTDIGIT ) } )
			
			oSecDado_4:SetParentQuery()
			oSecDado_4:SetParentFilter( {|cParam| QRY4->D1_DOC + QRY4->D1_SERIE == cParam } , {|| QRY4->D1_DOC + QRY4->D1_SERIE } )
			oSecCabe_4:Print(.T.)
			
		EndIf  

	//====================================================================================================
	// Ordem 3 Produto sintetico
	//====================================================================================================
	ElseIf _nOrdem == 3

		oSecEntr_5:Enable()      
		
		TRFunction():New( oSecEntr_5:Cell( "D1_QUANT"   ) , NIL , "SUM" ,NIL,NIL,NIL,NIL,.F.,.T. )
		TRFunction():New( oSecEntr_5:Cell( "D1_QTSEGUM" ) , NIL , "SUM" ,NIL,NIL,NIL,NIL,.F.,.T. )
		TRFunction():New( oSecEntr_5:Cell( "D1_TOTAL"   ) , NIL , "SUM" ,NIL,NIL,NIL,NIL,.F.,.T. )
		TRFunction():New( oSecEntr_5:Cell( "D1_BASEICM" ) , NIL , "SUM" ,NIL,NIL,NIL,NIL,.F.,.T. )
		TRFunction():New( oSecEntr_5:Cell( "D1_VALICM"  ) , NIL , "SUM" ,NIL,NIL,NIL,NIL,.F.,.T. )
		TRFunction():New( oSecEntr_5:Cell( "D1_BASEIRR" ) , NIL , "SUM" ,NIL,NIL,NIL,NIL,.F.,.T. ) 
		TRFunction():New( oSecEntr_5:Cell( "D1_ALIQIRR" ) , NIL , "SUM" ,NIL,NIL,NIL,NIL,.F.,.T. )
		TRFunction():New( oSecEntr_5:Cell( "D1_VALIRR"  ) , NIL , "SUM" ,NIL,NIL,NIL,NIL,.F.,.T. )
		
		//====================================================================================================
		// Executa query para consultar Dados
		//====================================================================================================
		BEGIN REPORT QUERY oSecEntr_5
		
			BeginSql alias "QRY5"
			
				SELECT 
					B1.B1_COD		, B1.B1_DESC	, D1.D1_UM		, D1.D1_SEGUM		, SUM(D1.D1_QTSEGUM) D1_QTSEGUM	, SUM(D1.D1_QUANT) D1_QUANT	, SUM(D1.D1_TOTAL) D1_TOTAL	,
					SUM(D1.D1_BASEICM) D1_BASEICM	, SUM(D1.D1_VALICM) D1_VALICM		, SUM(D1_BASEIRR) D1_BASEIRR	, AVG(D1_ALIQIRR) D1_ALIQIRR, SUM(D1_VALIRR) D1_VALIRR
				FROM %Table:SD1% D1
				JOIN %Table:SA2% A2 ON D1.D1_FORNECE = A2.A2_COD    AND D1.D1_LOJA = A2.A2_LOJA
				JOIN %Table:SF4% F4 ON D1.D1_FILIAL  = F4.F4_FILIAL AND D1.D1_TES  = F4.F4_CODIGO
				JOIN %Table:SB1% B1 ON D1.D1_COD     = B1.B1_COD
				WHERE 
					D1.%notDel%
				AND A2.%notDel%  
				AND F4.%notDel% 
				AND B1.%notDel% 
				AND D1.D1_TIPO <> 'D'
				%exp:_cFiltro%       
				GROUP BY B1.B1_COD , B1.B1_DESC , D1.D1_UM , D1.D1_SEGUM
				ORDER BY B1.B1_COD
				
			EndSql
			
		END REPORT QUERY oSecEntr_5
		
		oSecEntr_5:Print(.T.)

	//====================================================================================================
	// Ordem 4 POR CFOP
	//====================================================================================================
	ElseIf _nOrdem == 4

		oSecEntr_6:Enable()
		oSecDado_6:Enable()

		//====================================================================================================
		// Quebra por CFOP
		//====================================================================================================
		oBrkEntr_6 := TRBreak():New( oSecDado_6 , {||QRY6->D1_FILIAL+QRY6->D1_CF}, "TOTAL Filial - CFOP: "+ _cCFOP , .F. )
		oBrkEntr_6:SetTotalText( {|| "TOTAL Filial - CFOP: "+ _cCFOP } )
		
		TRFunction():New( oSecDado_6:Cell( "D1_TOTAL" ) , NIL , "SUM" , oBrkEntr_6 ,NIL,NIL,NIL,.F.,.T. )
		TRFunction():New( oSecDado_6:Cell( "D1_TOTAL" ) , NIL , "SUM" , oBrkEntr_6 ,NIL,NIL,NIL,.F.,.T. )
		TRFunction():New( oSecDado_6:Cell( "F1_BASEICM" ) , NIL , "SUM" , oBrkEntr_6 ,NIL,NIL,NIL,.F.,.T. )
		TRFunction():New( oSecDado_6:Cell( "F1_VALICM"  ) , NIL , "SUM" , oBrkEntr_6 ,NIL,NIL,NIL,.F.,.T. )
		TRFunction():New( oSecDado_6:Cell( "D1_BASEIRR" ) , NIL , "SUM" , oBrkEntr_6 ,NIL,NIL,NIL,.F.,.T. )
		TRFunction():New( oSecDado_6:Cell( "D1_ALIQIRR" ) , NIL , "SUM" , oBrkEntr_6 ,NIL,NIL,NIL,.F.,.T. )
		TRFunction():New( oSecDado_6:Cell( "D1_VALIRR"  ) , NIL , "SUM" , oBrkEntr_6 ,NIL,NIL,NIL,.F.,.T. )
		
		//====================================================================================================
		// Executa query para consultar Dados
		//====================================================================================================
		BEGIN REPORT QUERY oSecEntr_6
		
			BeginSql alias "QRY6"
			
				SELECT 
					D1.D1_FILIAL, D1.D1_CF		, F1.F1_DTDIGIT		, F1.F1_DOC	  		, F1.F1_SERIE	, F1.F1_TIPO	, F1.F1_FORNECE , F1.F1_LOJA, 
					A2.A2_NOME, A2.A2_EST,
					C7.C7_NUM, D1.D1_ITEMPC, C7.C7_I_APLIC, C7.C7_I_CDINV,ZZI.ZZI_DESINV, C7.C7_OBS,
					B1.B1_COD		, B1.B1_DESC	, D1.D1_UM		, D1.D1_SEGUM , 				
					D1.D1_QTSEGUM	, D1_QUANT	, 				
					D1.D1_TOTAL,D1.D1_BASEICM,D1.D1_VALICM,D1_BASEIRR,D1_ALIQIRR,D1_VALIRR,D1_CC,CTT_DESC01
				FROM %Table:SD1% D1                
				JOIN %Table:SF1% F1 ON D1.D1_DOC     = F1.F1_DOC    AND D1.D1_SERIE = F1.F1_SERIE  AND D1.D1_FORNECE = F1.F1_FORNECE AND D1.D1_LOJA = F1.F1_LOJA AND D1.D1_FILIAL = F1.F1_FILIAL
				JOIN %Table:SA2% A2 ON D1.D1_FORNECE = A2.A2_COD    AND D1.D1_LOJA  = A2.A2_LOJA
				JOIN %Table:SF4% F4 ON D1.D1_FILIAL  = F4.F4_FILIAL AND D1.D1_TES   = F4.F4_CODIGO
				JOIN %Table:SB1% B1 ON D1.D1_COD     = B1.B1_COD	AND B1.%notDel%		
				LEFT JOIN %Table:SC7% C7  ON D1.D1_FILIAL  = C7.C7_FILIAL AND D1.D1_PEDIDO   = C7.C7_NUM      AND C7.C7_ITEM = D1.D1_ITEMPC AND C7.%notDel%
				LEFT JOIN %Table:ZZI% ZZI ON ZZI_FILIAL    = C7.C7_FILIAL AND ZZI.ZZI_CODINV = C7.C7_I_CDINV AND ZZI.%notDel%
				LEFT JOIN %Table:CTT% CTT ON D1.D1_CC = CTT.CTT_CUSTO AND CTT.%notDel%
				WHERE 
					D1.%notDel%
				AND F1.%notDel%
				AND A2.%notDel%
				AND F4.%notDel%
				AND D1.D1_TIPO <> 'D'
				%exp:_cFiltro%
				ORDER BY D1.D1_FILIAL,D1.D1_CF,F1.F1_DTDIGIT,F1.F1_FORNECE,F1.F1_LOJA,F1.F1_DOC,F1.F1_SERIE
				
			EndSql
			
		END REPORT QUERY oSecEntr_6
		
		oSecDado_6:SetParentQuery()
		oSecDado_6:SetParentFilter( {|cParam| QRY6->D1_FILIAL+QRY6->D1_CF == cParam } , {|| QRY6->D1_FILIAL+QRY6->D1_CF } )
		oSecEntr_6:Print(.T.)
		
		DBSelectArea("SF1")
		
		DBSelectArea("SD1")
		SD1->( DBSetOrder(1) )
		SD1->( DBSeek( xFilial("SD1") + SF1->F1_DOC ) )

	//====================================================================================================	
	// Fornecedor x Produto
	//====================================================================================================
	ElseIf _nOrdem == 5

		oSecForn_7:Enable()
		oSecProd_7:Enable()      
		oSecDado_7:Enable()
					
		oSecDado_7:SetTotalText( {|| "TOTAIS PRODUTO: " + _cNomeProd } )
		
		TRFunction():New( oSecDado_7:Cell( "D1_QUANT"   ) , NIL , "SUM" ,NIL,NIL,NIL,NIL,.T.,.T. )
		TRFunction():New( oSecDado_7:Cell( "D1_TOTAL"   ) , NIL , "SUM" ,NIL,NIL,NIL,NIL,.T.,.T. )
		TRFunction():New( oSecDado_7:Cell( "D1_BASEICM" ) , NIL , "SUM" ,NIL,NIL,NIL,NIL,.T.,.T. )
		TRFunction():New( oSecDado_7:Cell( "D1_VALICM"  ) , NIL , "SUM" ,NIL,NIL,NIL,NIL,.T.,.T. )
		TRFunction():New( oSecDado_7:Cell( "D1_BASEIRR" ) , NIL , "SUM" ,NIL,NIL,NIL,NIL,.T.,.T. ) //Talita - 08/02/13 - Incluido os campos D1_BASEIRR, D1_ALIQIRR e D1_VALIRR conforme Help: 1774
		TRFunction():New( oSecDado_7:Cell( "D1_ALIQIRR" ) , NIL , "SUM" ,NIL,NIL,NIL,NIL,.T.,.T. )
		TRFunction():New( oSecDado_7:Cell( "D1_VALIRR"  ) , NIL , "SUM" ,NIL,NIL,NIL,NIL,.T.,.T. )
		
		//====================================================================================================
		// Quebra por Fornecedor
		//====================================================================================================
		oBrkForn_7 := TRBreak():New( oReport , oSecForn_7:CELL("FORNECEDOR") , "TOTAIS FORNECEDOR: "+ _cNomeForn , .F. )
		oBrkForn_7:SetTotalText( {|| "TOTAIS FORNECEDOR: "+ _cNomeForn } )
		
		TRFunction():New( oSecDado_7:Cell( "D1_QUANT"   ) , NIL , "SUM" , oBrkForn_7 ,NIL,NIL,NIL,.F.,.F. )
		TRFunction():New( oSecDado_7:Cell( "D1_TOTAL"   ) , NIL , "SUM" , oBrkForn_7 ,NIL,NIL,NIL,.F.,.F. )
		TRFunction():New( oSecDado_7:Cell( "D1_BASEICM" ) , NIL , "SUM" , oBrkForn_7 ,NIL,NIL,NIL,.F.,.F. )
		TRFunction():New( oSecDado_7:Cell( "D1_VALICM"  ) , NIL , "SUM" , oBrkForn_7 ,NIL,NIL,NIL,.F.,.F. )
		TRFunction():New( oSecDado_7:Cell( "D1_BASEIRR" ) , NIL , "SUM" , oBrkForn_7 ,NIL,NIL,NIL,.F.,.F. ) //Talita - 08/02/13 - Incluido os campos D1_BASEIRR, D1_ALIQIRR e D1_VALIRR conforme Help: 1774
		TRFunction():New( oSecDado_7:Cell( "D1_ALIQIRR" ) , NIL , "SUM" , oBrkForn_7 ,NIL,NIL,NIL,.F.,.F. )
		TRFunction():New( oSecDado_7:Cell( "D1_VALIRR"  ) , NIL , "SUM" , oBrkForn_7 ,NIL,NIL,NIL,.F.,.F. )
		
		//====================================================================================================
		// Executa query para consultar Dados
		//====================================================================================================
		BEGIN REPORT QUERY oSecForn_7
		
			BeginSql alias "QRY7"
			
				SELECT
					A2.A2_COD		, A2.A2_LOJA		, A2.A2_NOME		, A2.A2_NREDUZ		, A2.A2_CGC		, A2.A2_EST		, A2.A2_MUN						,
					B1.B1_COD		, B1.B1_DESC		, D1.D1_UM			, D1.D1_DTDIGIT		, D1.D1_DOC		, D1.D1_SERIE	, D1.D1_TIPO					,
					SUM(D1.D1_QUANT) D1_QUANT			, SUM(D1.D1_TOTAL) D1_TOTAL				, SUM(D1.D1_BASEICM) D1_BASEICM	, SUM(D1.D1_VALICM) D1_VALICM	,
					SUM(D1_BASEIRR) D1_BASEIRR			, AVG(D1_ALIQIRR) D1_ALIQIRR			, SUM(D1_VALIRR) D1_VALIRR
				FROM %Table:SD1% D1
				JOIN %Table:SA2% A2 ON D1.D1_FORNECE = A2.A2_COD    AND D1.D1_LOJA = A2.A2_LOJA
				JOIN %Table:SF4% F4 ON D1.D1_FILIAL  = F4.F4_FILIAL AND D1.D1_TES  = F4.F4_CODIGO
				JOIN %Table:SB1% B1 ON D1.D1_COD     = B1.B1_COD
				WHERE
					D1.%notDel%
				AND A2.%notDel%
				AND F4.%notDel%
				AND B1.%notDel%
				AND D1.D1_TIPO <> 'D'
				%exp:_cFiltro%
				GROUP BY A2.A2_COD,A2.A2_LOJA,A2.A2_NOME,A2.A2_NREDUZ,A2.A2_CGC,A2.A2_EST,A2.A2_MUN,B1.B1_COD,B1.B1_DESC,D1.D1_UM,D1.D1_DTDIGIT,D1.D1_DOC,D1.D1_SERIE,D1.D1_TIPO
				ORDER BY A2.A2_COD,A2.A2_LOJA,B1.B1_COD,D1.D1_DTDIGIT,D1.D1_DOC,D1.D1_SERIE
				
			EndSql
			
		END REPORT QUERY oSecForn_7
		
		oSecProd_7:SetParentQuery()
		oSecProd_7:SetParentFilter( {|cParam| QRY7->A2_COD + QRY7->A2_LOJA == cParam } , {|| QRY7->A2_COD + QRY7->A2_LOJA } )
		
		oSecDado_7:SetParentQuery()
		oSecDado_7:SetParentFilter( {|cParam| QRY7->A2_COD + QRY7->A2_LOJA + QRY7->B1_COD == cParam } , {|| QRY7->A2_COD + QRY7->A2_LOJA + QRY7->B1_COD } )
		
		oSecForn_7:Print(.T.)

	EndIf

Return

/*
===============================================================================================================================
Programa----------: lstTpForn
Autor-------------: Fabiano Dias Silva
Data da Criacao---: 05/03/2010
Descrição---------: Monta Tela para consulta dos tipos de Fornecedor
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function lstTpForn()

	Local i 		  := 0 
	Local aOpcoes	  := {}	
	Local cCombo      := ""

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
	nTam	:= 1
	cTitulo := "Tipos de Fornecedores"

	DBSelectArea("SX3")
	DBSetOrder(2)
	If DBSeek("A2_I_CLASS")
		cCombo := X3Cbox()
	EndIf

	//A funcao StrTokArr() tem o objetivo de retornar um array, de acordo com os dados passados como parametro para a funcao
	aOpcoes := StrTokArr(cCombo, ';')

	nMaxSelect := Len(aOpcoes)        

	For i := 1 to Len (aOpcoes)
		If AllTrim(Upper(FunName())) == 'ROMS005'
			If SubStr(aOpcoes[i],1,1) $ 'A/G/T'
				MvParDef += SubStr(aOpcoes[i],1,1)
				aAdd(aCat,SubStr(aOpcoes[i],3,Len(aOpcoes[i])))
			EndIf     
		Else
			MvParDef += SubStr(aOpcoes[i],1,1)
			aAdd(aCat,SubStr(aOpcoes[i],3,Len(aOpcoes[i])))
		EndIf
	Next i

	If Len(AllTrim(&MvRet)) == 0
		MvPar	:= PadR(AllTrim(StrTran(&MvRet,";","")),Len(aCat))
		&MvRet	:= PadR(AllTrim(StrTran(&MvRet,";","")),Len(aCat))
	Else
		MvPar	:= AllTrim(StrTran(&MvRet,";","/"))
	EndIf

	//Executa funcao que monta tela de opcoes
	If f_Opcoes(@MvPar,cTitulo,aCat,MvParDef,12,49,.F.,nTam,nMaxSelect)        

		//Tratamento para separar retorno com barra ";"
		&MvRet := ""
		For i:=1 to Len(MvPar) step nTam
			If !(SubStr(MvPar,i,1) $ " |*")
				&MvRet  += SubStr(MvPar,i,nTam) + ";"
			EndIf
		Next i
		
		//Trata para tirar o ultimo caracter
		&MvRet := SubStr(&MvRet,1,Len(&MvRet)-1) 

	EndIf     

Return(.T.)

/*
===============================================================================================================================
Programa----------: lstTES
Autor-------------: Fabiano Dias Silva
Data da Criacao---: 05/03/2010
Descrição---------: Monta Tela para consulta das TES de entrada
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function lstTES()

	Local i				:= 0

	Private nTam		:= 0
	Private nMaxSelect	:= 0
	Private aCat		:= {}
	Private MvRet		:= AllTrim(ReadVar())
	Private MvPar		:= ""
	Private cTitulo		:= ""
	Private MvParDef	:= ""

	#IFDEF WINDOWS
		oWnd := GetWndDefault()
	#EndIf

	//Tratamento para carregar variaveis da lista de opcoes
	nTam		:= 3
	nMaxSelect	:= 24 //14 * 7 = 98 (cod(6) +";") = 7
	cTitulo		:= "TES - FILIAL - FIN - ICM - CF - DESC "      

	DBSelectArea("SF4")
	SF4->(DBSetOrder(1))
	SF4->(DBGoTop()) 

	While SF4->(!Eof())
		If FunName() == "RFIS003" .Or. FunName() == "ROMS009" 
			If SF4->F4_FILIAL == xFilial("SF4") .And. Val(SF4->F4_CODIGO) <= 999
				MvParDef += AllTrim(SF4->F4_CODIGO)
				aAdd(aCat," " + PadR(SF4->F4_FILIAL,6," ") + '-' + PadR(SF4->F4_DUPLIC,3," ") + '-' + SF4->F4_ICM + '-' + SF4->F4_CF  + '-' + SF4->F4_TEXTO) 
			EndIf    
		Else   
			If SF4->F4_FILIAL == xFilial("SF4") .And. Val(SF4->F4_CODIGO) <= 500
				MvParDef += AllTrim(SF4->F4_CODIGO)
				aAdd(aCat," " + PadR(SF4->F4_FILIAL,6," ") + '-' + PadR(SF4->F4_DUPLIC,3," ") + '-' + SF4->F4_ICM + '-' + SF4->F4_CF  + '-' + SF4->F4_TEXTO) 
			EndIf  	
		EndIf
		
		SF4->(DBSkip())
	EndDo                                    

	//===============================================================================================================================
	//Trativa abaixo para no caso de uma alteracao do campo trazer todos
	//os dados que foram selecionados anteriormente.                    
	//===============================================================================================================================

	If Len(AllTrim(&MvRet)) == 0                              
		MvPar:= PadR(AllTrim(StrTran(&MvRet,";","")),Len(aCat))
		&MvRet:= PadR(AllTrim(StrTran(&MvRet,";","")),Len(aCat))
	Else
		MvPar:= AllTrim(StrTran(&MvRet,";","/"))
	EndIf

	//Executa funcao que monta tela de opcoes
	If f_Opcoes(@MvPar,cTitulo,aCat,MvParDef,12,49,.F.,nTam,nMaxSelect)        

		//Tratamento para separar retorno com barra ";"
		&MvRet := ""
		For i:=1 to Len(MvPar) step nTam
			If !(SubStr(MvPar,i,1) $ " |*")
				&MvRet  += SubStr(MvPar,i,nTam) + ";"
			EndIf
		Next i
		
		//Trata para tirar o ultimo caracter
		&MvRet := SubStr(&MvRet,1,Len(&MvRet)-1) 

	EndIf     

Return(.T.)

/*
===============================================================================================================================
Programa----------: ROMS007D
Autor-------------: Fabiano Dias Silva
Data da Criacao---: 05/03/2010
Descrição---------: Rotina que retorna a descrição do CFOP
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS007D(cfop)
      
	Local cDescriCFOP	:= ""     
	Local cQuery     	:= ""

	cQuery := " SELECT "
	cQuery += "     X5_DESCRI DESCRI"
	cQuery += " FROM "+ RetSqlName("SX5") +" X5 "
	cQuery += " WHERE "
	cQuery += "     D_E_L_E_T_ = ' ' "
	cQuery += " AND X5_TABELA  = '13' "
	cQuery += " AND X5_CHAVE   = '"+ AllTrim(cfop) +"' "

	//Para que nao ocorra erro, quando duas pessoas acessarem o relatorio simultaneamente
	If Select("TMPCFOP") > 0 
		TMPCFOP->( DBCloseArea() )
	EndIf

	DBUseArea( .T. , "TOPCONN" , TCGenQry( ,, cQuery ) , 'TMPCFOP' , .F. , .T. )

	DBSelectArea("TMPCFOP")
	TMPCFOP->( DBGoTop() )
	If TMPCFOP->( !Eof() ) .And. !Empty( TMPCFOP->DESCRI )
		cDescriCFOP := AllTrim( TMPCFOP->DESCRI )
	EndIf

	TMPCFOP->( DBCloseArea() )

Return( cDescriCFOP )

/*
===============================================================================================================================
Programa----------: RCOM007IO
Autor-------------: Fabiano Dias Silva
Data da Criacao---: 05/03/2010
Descrição---------: Rotina que imprime os registros de observação
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RCOM007IO( _cNumNF )
                    
	Local _cNf      := SubStr( _cNumNF , 01 , 9 )
	Local _cSerieNf := SubStr( _cNumNF , 11 , 3 )
	Local _cFilial  := SubStr( _cNumNF , 15 , 2 )
	Local _cFornec  := SubStr( _cNumNF , 18 , 6 )
	Local _cLjForn  := SubStr( _cNumNF , 25 , 4 )
	Local _cAliasSD1:= GetNextAlias()
	Local _cQuery   := ""
	Local _aAreaGer := FWGetArea()

	_cQuery := " SELECT "
	_cQuery += "     D1_I_OBS "
	_cQuery += " FROM "+ RetSqlName("SD1") +" D1 "
	_cQuery += " WHERE "
	_cQuery += "     D_E_L_E_T_ = ' ' "
	_cQuery += " AND D1_FILIAL  = '"+ _cFilial  +"' "
	_cQuery += " AND D1_DOC     = '"+ _cNf      +"' "
	_cQuery += " AND D1_SERIE   = '"+ _cSerieNf +"' "
	_cQuery += " AND D1_FORNECE = '"+ _cFornec  +"' "
	_cQuery += " AND D1_LOJA    = '"+ _cLjForn  +"' "
	_cQuery += " ORDER BY D1_ITEM "

	If Select(_cAliasSD1) > 0
		(_cAliasSD1)->( DBCloseArea() )
	EndIf

	DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQuery) , _cAliasSD1 , .T. , .F. )

	DBSelectArea(_cAliasSD1)
	(_cAliasSD1)->( DBGoTop() )

	//So pega o primeiro item da nota fiscal - caso exita um registro de observacao preenchido
	If (_cAliasSD1)->( !Eof() )
		If Len(AllTrim((_cAliasSD1)->D1_I_OBS)) > 0
			oReport:SkipLine()
			oReport:PrintText('OBS.: ' + AllTrim( (_cAliasSD1)->D1_I_OBS ) ,, 050 )	
		EndIf
	EndIf

	(_cAliasSD1)->( DBCloseArea() )

	FWRestArea(_aAreaGer)

Return
